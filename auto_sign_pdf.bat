@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: AutoFirma PDF Signing Script for Windows
:: ============================================================
:: This script automates PDF signing using AutoFirma (the Spanish government's 
:: electronic signature tool) using a PFX certificate.
:: 
:: Usage: auto_sign_pdf.bat -i <input_dir> -o <output_dir> -c <cert_file> -p <password>
::
:: Author: AI Assistant
:: ============================================================

:: Default values
set "INPUT_DIR="
set "OUTPUT_DIR="
set "CERT_FILE="
set "PASSWORD="
set "LOCATION=Madrid"
set "REASON=Document validation"
set "VISIBLE=false"
set "TIMESTAMP=false"

:: Function to display help message
:show_help
    echo Usage: %0 [OPTIONS]
    echo Automatically sign PDF files using AutoFirma
    echo.
    echo Options:
    echo   -i, --input-dir      Input directory containing PDF files (required)
    echo   -o, --output-dir     Output directory for signed PDFs (required)
    echo   -c, --cert           Path to the PFX certificate file (required)
    echo   -p, --password       Password for the PFX certificate (required)
    echo   -l, --location       Location for signature (default: Madrid)
    echo   -r, --reason         Reason for signature (default: Document validation)
    echo   -v, --visible        Make signature visible (default: false)
    echo   -t, --timestamp      Add timestamp to signature (default: false)
    echo   -h, --help           Display this help message
    echo.
    echo Example:
    echo   %0 -i .\pdfs -o .\signed_pdfs -c .\certificate.pfx -p mypassword -l "Barcelona" -r "Invoice approval" -v
    exit /b 0

:: Function to log messages with colors
:log
    set "level=%~1"
    set "message=%~2"
    
    for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value') do set "dt=%%a"
    set "timestamp=%dt:~0,4%-%dt:~4,2%-%dt:~6,2% %dt:~8,2%:%dt:~10,2%:%dt:~12,2%"
    
    if "%level%"=="INFO" (
        echo [%timestamp%] [%level%] %message%
    ) else if "%level%"=="SUCCESS" (
        echo [%timestamp%] [%level%] %message%
    ) else if "%level%"=="WARNING" (
        echo [%timestamp%] [%level%] %message%
    ) else if "%level%"=="ERROR" (
        echo [%timestamp%] [%level%] %message%
    )
    exit /b 0

:: Parse command line arguments
:parse_args
    if "%~1"=="" goto validate_params
    
    if "%~1"=="-h" goto show_help
    if "%~1"=="--help" goto show_help
    
    if "%~1"=="-i" (
        set "INPUT_DIR=%~2"
        shift
        shift
        goto parse_args
    )
    if "%~1"=="--input-dir" (
        set "INPUT_DIR=%~2"
        shift
        shift
        goto parse_args
    )
    
    if "%~1"=="-o" (
        set "OUTPUT_DIR=%~2"
        shift
        shift
        goto parse_args
    )
    if "%~1"=="--output-dir" (
        set "OUTPUT_DIR=%~2"
        shift
        shift
        goto parse_args
    )
    
    if "%~1"=="-c" (
        set "CERT_FILE=%~2"
        shift
        shift
        goto parse_args
    )
    if "%~1"=="--cert" (
        set "CERT_FILE=%~2"
        shift
        shift
        goto parse_args
    )
    
    if "%~1"=="-p" (
        set "PASSWORD=%~2"
        shift
        shift
        goto parse_args
    )
    if "%~1"=="--password" (
        set "PASSWORD=%~2"
        shift
        shift
        goto parse_args
    )
    
    if "%~1"=="-l" (
        set "LOCATION=%~2"
        shift
        shift
        goto parse_args
    )
    if "%~1"=="--location" (
        set "LOCATION=%~2"
        shift
        shift
        goto parse_args
    )
    
    if "%~1"=="-r" (
        set "REASON=%~2"
        shift
        shift
        goto parse_args
    )
    if "%~1"=="--reason" (
        set "REASON=%~2"
        shift
        shift
        goto parse_args
    )
    
    if "%~1"=="-v" (
        set "VISIBLE=true"
        shift
        goto parse_args
    )
    if "%~1"=="--visible" (
        set "VISIBLE=true"
        shift
        goto parse_args
    )
    
    if "%~1"=="-t" (
        set "TIMESTAMP=true"
        shift
        goto parse_args
    )
    if "%~1"=="--timestamp" (
        set "TIMESTAMP=true"
        shift
        goto parse_args
    )
    
    call :log "ERROR" "Unknown option: %~1"
    goto show_help

:: Validate required parameters
:validate_params
    if "%INPUT_DIR%"=="" (
        call :log "ERROR" "Input directory is required (-i, --input-dir)"
        exit /b 1
    )
    
    if "%OUTPUT_DIR%"=="" (
        call :log "ERROR" "Output directory is required (-o, --output-dir)"
        exit /b 1
    )
    
    if "%CERT_FILE%"=="" (
        call :log "ERROR" "Certificate file is required (-c, --cert)"
        exit /b 1
    )
    
    if "%PASSWORD%"=="" (
        call :log "ERROR" "Certificate password is required (-p, --password)"
        exit /b 1
    )
    
    :: Check if input directory exists
    if not exist "%INPUT_DIR%\" (
        call :log "ERROR" "Input directory does not exist: %INPUT_DIR%"
        exit /b 1
    )
    
    :: Check if certificate file exists
    if not exist "%CERT_FILE%" (
        call :log "ERROR" "Certificate file does not exist: %CERT_FILE%"
        exit /b 1
    )
    
    :: Create output directory if it doesn't exist
    if not exist "%OUTPUT_DIR%\" (
        call :log "INFO" "Creating output directory: %OUTPUT_DIR%"
        mkdir "%OUTPUT_DIR%" 2>nul
        if errorlevel 1 (
            call :log "ERROR" "Failed to create output directory: %OUTPUT_DIR%"
            exit /b 1
        )
    )
    
    goto main

:: Create temporary config file for visible signature if enabled
:create_visible_config
    set "config_file=%TEMP%\autofirma_config_%RANDOM%.txt"
    
    echo signaturePositionOnPageLowerLeftX=50 > "%config_file%"
    echo signaturePositionOnPageLowerLeftY=50 >> "%config_file%"
    echo signaturePositionOnPageUpperRightX=250 >> "%config_file%"
    echo signaturePositionOnPageUpperRightY=150 >> "%config_file%"
    echo signaturePage=1 >> "%config_file%"
    echo signatureRenderingMode=1 >> "%config_file%"
    echo signatureFontSize=9 >> "%config_file%"
    echo signatureFontColor=black >> "%config_file%"
    echo signatureText=Firmado por [NAME] el día [DATE] Certificado [ISSUER] >> "%config_file%"
    
    set "CONFIG_FILE=%config_file%"
    exit /b 0

:: Find AutoFirma executable
:find_autofirma
    set "AUTOFIRMA_PATH="
    
    if exist "C:\Program Files\AutoFirma\AutoFirma.exe" (
        set "AUTOFIRMA_PATH=C:\Program Files\AutoFirma\AutoFirma.exe"
    ) else if exist "C:\Program Files (x86)\AutoFirma\AutoFirma.exe" (
        set "AUTOFIRMA_PATH=C:\Program Files (x86)\AutoFirma\AutoFirma.exe"
    )
    
    :: If not found in common locations, check if it's in the PATH
    if "%AUTOFIRMA_PATH%"=="" (
        for %%i in (AutoFirma.exe autofirma.exe) do (
            set "temp_path="
            for %%j in (%%i) do set "temp_path=%%~$PATH:j"
            if not "!temp_path!"=="" (
                set "AUTOFIRMA_PATH=!temp_path!"
                goto found_autofirma
            )
        )
    )
    
    :found_autofirma
    if "%AUTOFIRMA_PATH%"=="" (
        call :log "ERROR" "AutoFirma executable not found. Please make sure it is installed."
        exit /b 1
    )
    
    call :log "INFO" "Using AutoFirma: %AUTOFIRMA_PATH%"
    exit /b 0

:: Main execution
:main
    :: Process command line arguments
    call :parse_args %*
    
    :: Find AutoFirma executable
    call :find_autofirma
    if errorlevel 1 exit /b 1
    
    :: Create configuration file for visible signature if requested
    set "CONFIG_FILE="
    if "%VISIBLE%"=="true" (
        call :create_visible_config
        call :log "INFO" "Created visible signature configuration file: %CONFIG_FILE%"
    )
    
    :: Process PDF files
    call :log "INFO" "Starting PDF signing process"
    call :log "INFO" "Input directory: %INPUT_DIR%"
    call :log "INFO" "Output directory: %OUTPUT_DIR%"
    call :log "INFO" "Certificate file: %CERT_FILE%"
    call :log "INFO" "Location: %LOCATION%"
    call :log "INFO" "Reason: %REASON%"
    call :log "INFO" "Visible signature: %VISIBLE%"
    call :log "INFO" "Add timestamp: %TIMESTAMP%"
    
    :: Get list of PDF files
    set "PDF_COUNT=0"
    for %%F in ("%INPUT_DIR%\*.pdf") do set /a PDF_COUNT+=1
    
    if %PDF_COUNT%==0 (
        call :log "WARNING" "No PDF files found in %INPUT_DIR%"
        exit /b 0
    )
    
    call :log "INFO" "Found %PDF_COUNT% PDF files to process"
    
    :: Process each PDF file
    set "SUCCESS_COUNT=0"
    set "FAILURE_COUNT=0"
    set "CURRENT=0"
    
    for %%F in ("%INPUT_DIR%\*.pdf") do (
        set /a CURRENT+=1
        set "FILENAME=%%~nxF"
        set "OUTPUT_FILENAME=%%~nF-signed.pdf"
        set "OUTPUT_PATH=%OUTPUT_DIR%\!OUTPUT_FILENAME!"
        
        call :log "INFO" "[!CURRENT!/%PDF_COUNT%] Processing: !FILENAME!"
        
        :: Construct AutoFirma command
        set "CMD=%AUTOFIRMA_PATH% sign -i "%%F" -o "!OUTPUT_PATH!" -store pkcs12:%CERT_FILE% -password %PASSWORD% -format PAdES"
        
        :: Add location if specified
        if not "%LOCATION%"=="" (
            set "CMD=!CMD! -location "%LOCATION%""
        )
        
        :: Add reason if specified
        if not "%REASON%"=="" (
            set "CMD=!CMD! -reason "%REASON%""
        )
        
        :: Add configuration file if visible signature is enabled
        if "%VISIBLE%"=="true" if not "%CONFIG_FILE%"=="" (
            set "CMD=!CMD! -config "%CONFIG_FILE%""
        )
        
        :: Add timestamp if enabled
        if "%TIMESTAMP%"=="true" (
            set "CMD=!CMD! -timestamp"
        )
        
        :: Execute AutoFirma command
        %CMD% > "%TEMP%\autofirma_output.txt" 2>&1
        set "EXIT_CODE=%ERRORLEVEL%"
        
        if %EXIT_CODE%==0 if exist "!OUTPUT_PATH!" (
            set /a SUCCESS_COUNT+=1
            call :log "SUCCESS" "[!CURRENT!/%PDF_COUNT%] Signed: !FILENAME! → !OUTPUT_FILENAME!"
        ) else (
            set /a FAILURE_COUNT+=1
            call :log "ERROR" "[!CURRENT!/%PDF_COUNT%] Failed to sign: !FILENAME! (Exit code: %EXIT_CODE%)"
            type "%TEMP%\autofirma_output.txt"
        )
    )
    
    :: Clean up temporary files
    if exist "%TEMP%\autofirma_output.txt" del "%TEMP%\autofirma_output.txt"
    if not "%CONFIG_FILE%"=="" if exist "%CONFIG_FILE%" del "%CONFIG_FILE%"
    
    :: Display summary
    call :log "INFO" "Signing process completed"
    call :log "INFO" "Total PDF files: %PDF_COUNT%"
    call :log "SUCCESS" "Successfully signed: %SUCCESS_COUNT%"
    if %FAILURE_COUNT% GTR 0 (
        call :log "ERROR" "Failed to sign: %FAILURE_COUNT%"
    )
    
    exit /b 0

:: Call the main entry point
call :main %* 