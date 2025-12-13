# ============================================================================
# PDF Signer - Script de Ejecución Automática para Windows
# ============================================================================
# Este script carga las variables de entorno desde .env y ejecuta autofirma.py
# automáticamente sin requerir parámetros manuales.
#
# Uso: .\run.ps1

# Configuración de errores
$ErrorActionPreference = "Stop"

# Colores para mensajes
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Error-Message { Write-Host $args -ForegroundColor Red }
function Write-Info { Write-Host $args -ForegroundColor Cyan }

Write-Info "============================================"
Write-Info "  PDF Signer - Ejecución Automática"
Write-Info "============================================"
Write-Host ""

# Verificar que existe el archivo .env
if (-not (Test-Path ".env")) {
    Write-Error-Message "ERROR: No se encuentra el archivo .env"
    Write-Host ""
    Write-Host "Por favor, crea el archivo .env basándote en .env.template:"
    Write-Host "  copy .env.template .env"
    Write-Host ""
    Write-Host "Luego edita .env con tus valores personales."
    exit 1
}

# Cargar variables de entorno desde .env
Write-Info "Cargando configuración desde .env..."
Get-Content .env | ForEach-Object {
    $line = $_.Trim()
    
    # Ignorar líneas vacías y comentarios
    if ($line -eq "" -or $line.StartsWith("#")) {
        return
    }
    
    # Parsear variable=valor
    if ($line -match "^([^=]+)=(.*)$") {
        $name = $matches[1].Trim()
        $value = $matches[2].Trim()
        
        # Remover comillas si existen (simples o dobles)
        if ($value -match '^"(.*)"$' -or $value -match "^'(.*)'$") {
            $value = $matches[1]
        }
        
        # Establecer variable de entorno
        [Environment]::SetEnvironmentVariable($name, $value, "Process")
    }
}

# Obtener variables requeridas
$inputDir = $env:PDF_INPUT_DIR
$outputDir = $env:PDF_OUTPUT_DIR
$certPath = $env:PDF_CERT_PATH
$certPassword = $env:PDF_CERT_PASSWORD

# Validar variables requeridas
$missingVars = @()
if (-not $inputDir) { $missingVars += "PDF_INPUT_DIR" }
if (-not $outputDir) { $missingVars += "PDF_OUTPUT_DIR" }
if (-not $certPath) { $missingVars += "PDF_CERT_PATH" }
if (-not $certPassword) { $missingVars += "PDF_CERT_PASSWORD" }

if ($missingVars.Count -gt 0) {
    Write-Error-Message "ERROR: Faltan las siguientes variables requeridas en .env:"
    $missingVars | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
    Write-Host ""
    Write-Host "Por favor, edita .env y configura todos los valores requeridos."
    exit 1
}

# Construir comando de autofirma.py
Write-Info "Construyendo comando de ejecución..."
$cmd = @("python", "autofirma.py", "-i", $inputDir, "-o", $outputDir, "-c", $certPath)

# Agregar parámetros opcionales
if ($env:PDF_LOCATION) {
    $cmd += @("-l", $env:PDF_LOCATION)
}

if ($env:PDF_REASON) {
    $cmd += @("-r", $env:PDF_REASON)
}

if ($env:PDF_VISIBLE -eq "true") {
    $cmd += "-v"
}

if ($env:PDF_TIMESTAMP -eq "true") {
    $cmd += "-t"
}

if ($env:PDF_PROFILE) {
    $cmd += @("-P", $env:PDF_PROFILE)
}

if ($env:PDF_ALIAS) {
    $cmd += @("-a", $env:PDF_ALIAS)
}

# Mostrar configuración
Write-Host ""
Write-Info "Configuración:"
Write-Host "  Input:  $inputDir"
Write-Host "  Output: $outputDir"
Write-Host "  Cert:   $certPath"
Write-Host "  Visible: $($env:PDF_VISIBLE -eq 'true')"
Write-Host "  Profile: $($env:PDF_PROFILE -or 'default')"
Write-Host ""

# Ejecutar autofirma.py
Write-Info "Ejecutando PDF Signer..."
Write-Host ""

try {
    & $cmd[0] $cmd[1..($cmd.Length-1)]
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host ""
        Write-Success "✓ Proceso completado exitosamente"
    } else {
        Write-Host ""
        Write-Error-Message "✗ El proceso finalizó con errores (código: $LASTEXITCODE)"
        exit $LASTEXITCODE
    }
} catch {
    Write-Host ""
    Write-Error-Message "✗ Error al ejecutar autofirma.py:"
    Write-Error-Message $_.Exception.Message
    exit 1
}
