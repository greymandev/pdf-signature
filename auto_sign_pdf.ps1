# ============================================================
# AutoFirma PDF Signing Script for Windows (PowerShell)
# ============================================================
# This script automates PDF signing using AutoFirma (the Spanish government's 
# electronic signature tool) using a PFX certificate.
# 
# Usage: .\auto_sign_pdf.ps1 -InputDir <input_dir> -OutputDir <output_dir> -CertFile <cert_file> -Password <password>
#
# Author: AI Assistant
# ============================================================

[CmdletBinding()]
param (
    [Parameter(Mandatory=$true, Position=0, HelpMessage="Input directory containing PDF files")]
    [string]$InputDir,
    
    [Parameter(Mandatory=$true, Position=1, HelpMessage="Output directory for signed PDFs")]
    [string]$OutputDir,
    
    [Parameter(Mandatory=$true, Position=2, HelpMessage="Path to the PFX certificate file")]
    [string]$CertFile,
    
    [Parameter(Mandatory=$true, Position=3, HelpMessage="Password for the PFX certificate")]
    [string]$Password,
    
    [Parameter(Mandatory=$false, HelpMessage="Location for signature (default: Madrid)")]
    [string]$Location = "Madrid",
    
    [Parameter(Mandatory=$false, HelpMessage="Reason for signature (default: Document validation)")]
    [string]$Reason = "Document validation",
    
    [Parameter(Mandatory=$false, HelpMessage="Make signature visible")]
    [switch]$Visible,
    
    [Parameter(Mandatory=$false, HelpMessage="Add timestamp to signature")]
    [switch]$Timestamp
)

# Function to log messages with colors
function Write-Log {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("INFO", "SUCCESS", "WARNING", "ERROR")]
        [string]$Level,
        
        [Parameter(Mandatory=$true)]
        [string]$Message
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "INFO"    { "Cyan" }
        "SUCCESS" { "Green" }
        "WARNING" { "Yellow" }
        "ERROR"   { "Red" }
        default   { "White" }
    }
    
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# Function to create a temporary configuration file for visible signature
function New-VisibleSignatureConfig {
    $configFile = [System.IO.Path]::GetTempFileName()
    
    @"
signaturePositionOnPageLowerLeftX=50
signaturePositionOnPageLowerLeftY=50
signaturePositionOnPageUpperRightX=250
signaturePositionOnPageUpperRightY=150
signaturePage=1
signatureRenderingMode=1
signatureFontSize=9
signatureFontColor=black
signatureText=Firmado por [NAME] el día [DATE] Certificado [ISSUER]
"@ | Out-File -FilePath $configFile -Encoding UTF8
    
    return $configFile
}

# Function to find AutoFirma executable
function Find-AutoFirma {
    $autofirmaPath = $null
    
    # Check common installation paths
    $commonPaths = @(
        "C:\Program Files\AutoFirma\AutoFirma.exe",
        "C:\Program Files (x86)\AutoFirma\AutoFirma.exe"
    )
    
    foreach ($path in $commonPaths) {
        if (Test-Path $path) {
            $autofirmaPath = $path
            break
        }
    }
    
    # If not found in common locations, try to find it in PATH
    if (-not $autofirmaPath) {
        try {
            $autofirmaPath = (Get-Command "AutoFirma.exe" -ErrorAction SilentlyContinue).Source
        } catch {
            # AutoFirma not in PATH
        }
    }
    
    return $autofirmaPath
}

# Validate parameters
# Check if input directory exists
if (-not (Test-Path $InputDir -PathType Container)) {
    Write-Log -Level "ERROR" -Message "Input directory does not exist: $InputDir"
    exit 1
}

# Check if certificate file exists
if (-not (Test-Path $CertFile -PathType Leaf)) {
    Write-Log -Level "ERROR" -Message "Certificate file does not exist: $CertFile"
    exit 1
}

# Create output directory if it doesn't exist
if (-not (Test-Path $OutputDir -PathType Container)) {
    Write-Log -Level "INFO" -Message "Creating output directory: $OutputDir"
    try {
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    } catch {
        Write-Log -Level "ERROR" -Message "Failed to create output directory: $OutputDir"
        Write-Log -Level "ERROR" -Message $_.Exception.Message
        exit 1
    }
}

# Find AutoFirma executable
$autofirmaPath = Find-AutoFirma
if (-not $autofirmaPath) {
    Write-Log -Level "ERROR" -Message "AutoFirma executable not found. Please make sure it is installed."
    exit 1
}

Write-Log -Level "INFO" -Message "Using AutoFirma: $autofirmaPath"

# Create configuration file for visible signature if requested
$configFile = $null
if ($Visible) {
    $configFile = New-VisibleSignatureConfig
    Write-Log -Level "INFO" -Message "Created visible signature configuration file: $configFile"
}

# Start PDF signing process
Write-Log -Level "INFO" -Message "Starting PDF signing process"
Write-Log -Level "INFO" -Message "Input directory: $InputDir"
Write-Log -Level "INFO" -Message "Output directory: $OutputDir"
Write-Log -Level "INFO" -Message "Certificate file: $CertFile"
Write-Log -Level "INFO" -Message "Location: $Location"
Write-Log -Level "INFO" -Message "Reason: $Reason"
Write-Log -Level "INFO" -Message "Visible signature: $($Visible.IsPresent)"
Write-Log -Level "INFO" -Message "Add timestamp: $($Timestamp.IsPresent)"

# Get list of PDF files
$pdfFiles = Get-ChildItem -Path $InputDir -Filter "*.pdf"
$pdfCount = $pdfFiles.Count

if ($pdfCount -eq 0) {
    Write-Log -Level "WARNING" -Message "No PDF files found in $InputDir"
    exit 0
}

Write-Log -Level "INFO" -Message "Found $pdfCount PDF files to process"

# Process each PDF file
$successCount = 0
$failureCount = 0
$current = 0

foreach ($pdfFile in $pdfFiles) {
    $current++
    $filename = $pdfFile.Name
    $outputFilename = "$($pdfFile.BaseName)-signed.pdf"
    $outputPath = Join-Path -Path $OutputDir -ChildPath $outputFilename
    
    Write-Log -Level "INFO" -Message "[$current/$pdfCount] Processing: $filename"
    
    # Construct AutoFirma command
    $cmd = @(
        "`"$autofirmaPath`"",
        "sign",
        "-i", "`"$($pdfFile.FullName)`"",
        "-o", "`"$outputPath`"",
        "-store", "pkcs12:$CertFile",
        "-password", "$Password",
        "-format", "PAdES"
    )
    
    # Add location if specified
    if ($Location) {
        $cmd += "-location"
        $cmd += "`"$Location`""
    }
    
    # Add reason if specified
    if ($Reason) {
        $cmd += "-reason"
        $cmd += "`"$Reason`""
    }
    
    # Add configuration file if visible signature is enabled
    if ($Visible -and $configFile) {
        $cmd += "-config"
        $cmd += "`"$configFile`""
    }
    
    # Add timestamp if enabled
    if ($Timestamp) {
        $cmd += "-timestamp"
    }
    
    # Execute AutoFirma command
    try {
        $commandString = $cmd -join " "
        $result = Invoke-Expression "& $commandString" 2>&1
        
        if (Test-Path $outputPath) {
            $successCount++
            Write-Log -Level "SUCCESS" -Message "[$current/$pdfCount] Signed: $filename → $outputFilename"
        } else {
            $failureCount++
            Write-Log -Level "ERROR" -Message "[$current/$pdfCount] Failed to sign: $filename"
            Write-Log -Level "ERROR" -Message "Error output: $result"
        }
    } catch {
        $failureCount++
        Write-Log -Level "ERROR" -Message "[$current/$pdfCount] Failed to sign: $filename"
        Write-Log -Level "ERROR" -Message "Error: $($_.Exception.Message)"
    }
}

# Clean up configuration file
if ($configFile -and (Test-Path $configFile)) {
    Remove-Item -Path $configFile -Force
}

# Display summary
Write-Log -Level "INFO" -Message "Signing process completed"
Write-Log -Level "INFO" -Message "Total PDF files: $pdfCount"
Write-Log -Level "SUCCESS" -Message "Successfully signed: $successCount"
if ($failureCount -gt 0) {
    Write-Log -Level "ERROR" -Message "Failed to sign: $failureCount"
} 