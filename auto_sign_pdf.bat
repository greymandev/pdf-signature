@echo off
setlocal enabledelayedexpansion

:: ============================================================
:: AutoFirma PDF Signing Script for Windows
:: ============================================================
:: This script automates PDF signing using AutoFirma (the Spanish government's 
:: electronic signature tool) using a PFX certificate.
:: 
:: Usage: auto_sign_pdf.bat -i <input_dir> -o <output_dir> -c <cert_file>
::        auto_sign_pdf.bat -i <input_dir> -o <output_dir> -c <cert_file> -p <password>
::        auto_sign_pdf.bat -i <input_dir> -o <output_dir> -c <cert_file> --password-env PDF_CERT_PASSWORD
::        auto_sign_pdf.bat -i <input_dir> -o <output_dir> -c <cert_file> --password-file <password_file>
::        auto_sign_pdf.bat -i <input_dir> -o <output_dir> -c <cert_file> --prompt-password
::
:: Author: gr3ym4n
:: ============================================================

:: Default values
set "INPUT_DIR="
set "OUTPUT_DIR="
set "CERT_FILE="
set "PASSWORD="
set "PASSWORD_ENV=PDF_CERT_PASSWORD"
set "PASSWORD_FILE="
set "PROMPT_PASSWORD="
set "LOCATION=Madrid"
set "REASON=Document validation"
set "VISIBLE=false"
set "TIMESTAMP=false"

:: Check if PDF_CERT_PASSWORD environment variable is set (default method)
if defined PDF_CERT_PASSWORD (
    set "PASSWORD=%PDF_CERT_PASSWORD%"
)

:: Function to display help message
:show_help
    echo AutoFirma PDF Signing Script for Windows
    echo.
    echo Usage: %~nx0 [options]
    echo.
    echo Options:
    echo   -h, --help           Show this help message
    echo   -i, --input-dir      Input directory containing PDF files (required)
    echo   -o, --output-dir     Output directory for signed PDFs (required)
    echo   -c, --cert           Path to the PFX certificate file (required)
    echo   -p, --password       Password for the PFX certificate (not recommended, use env var instead)
    echo   --password-env       Environment variable containing the password (default: PDF_CERT_PASSWORD)
    echo   --password-file      File containing the password (only first line is read)
    echo   --prompt-password    Prompt for password (more secure)
    echo   -l, --location       Location for signature (default: Madrid)
    echo   -r, --reason         Reason for signature (default: Document validation)
    echo   -v, --visible        Make signature visible
    echo   -t, --timestamp      Add timestamp to signature
    echo.
    echo Environment variables:
    echo   PDF_CERT_PASSWORD    Certificate password (preferred method)
    echo.
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
    
    if "%~1"=="--password-env" (
        set "PASSWORD_ENV=%~2"
        call set "PASSWORD=%%%~2%%"
        if "!PASSWORD!"=="" (
            call :log "ERROR" "Environment variable %~2 not set or empty"
            exit /b 1
        )
        shift
        shift
        goto parse_args
    )
    
    if "%~1"=="--password-file" (
        set "PASSWORD_FILE=%~2"
        if not exist "%~2" (
            call :log "ERROR" "Password file does not exist: %~2"
            exit /b 1
        )
        set /p PASSWORD=<"%~2"
        if "!PASSWORD!"=="" (
            call :log "ERROR" "Password file is empty"
            exit /b 1
        )
        shift
        shift
        goto parse_args
    )
    
    if "%~1"=="--prompt-password" (
        set "PROMPT_PASSWORD=true"
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
        if "%PROMPT_PASSWORD%"=="true" (
            :: PowerShell is used to securely read the password
            for /f "usebackq delims=" %%p in (`powershell -Command "$pwd = Read-Host 'Enter certificate password' -AsSecureString; $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pwd); $plaintext = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR); [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR); $plaintext"`) do set "PASSWORD=%%p"
            
            if "!PASSWORD!"=="" (
                call :log "ERROR" "Password cannot be empty"
                exit /b 1
            )
        ) else (
            call :log "ERROR" "Certificate password is required. Set PDF_CERT_PASSWORD environment variable or use one of the password options."
            exit /b 1
        )
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