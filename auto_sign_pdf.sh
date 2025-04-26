#!/bin/bash

# ============================================================
# AutoFirma PDF Signing Script
# ============================================================
# This script automates PDF signing using AutoFirma (the Spanish government's 
# electronic signature tool) using a PFX certificate.
# 
# Usage: ./auto_sign_pdf.sh -i <input_dir> -o <output_dir> -c <cert_file>
#        ./auto_sign_pdf.sh -i <input_dir> -o <output_dir> -c <cert_file> -p <password>
#        ./auto_sign_pdf.sh -i <input_dir> -o <output_dir> -c <cert_file> --password-env PDF_CERT_PASSWORD
#
# Author: gr3ym4n
# ============================================================

# Default values
INPUT_DIR=""
OUTPUT_DIR=""
CERT_FILE=""
PASSWORD=""
LOCATION="Madrid"
REASON="Document validation"
VISIBLE=false
TIMESTAMP=false

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display help message
show_help() {
    echo "AutoFirma PDF Signing Script for Unix/Linux"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  -h, --help           Show this help message"
    echo "  -i, --input-dir      Input directory containing PDF files (required)"
    echo "  -o, --output-dir     Output directory for signed PDFs (required)"
    echo "  -c, --cert           Path to the PFX certificate file (required)"
    echo "  -p, --password       Password for the PFX certificate (not recommended, use env var instead)"
    echo "  --password-env       Environment variable containing the password (default: PDF_CERT_PASSWORD)"
    echo "  --password-file      File containing the password (only first line is read)"
    echo "  --prompt-password    Prompt for password (more secure)"
    echo "  -l, --location       Location for signature (default: Madrid)"
    echo "  -r, --reason         Reason for signature (default: Document validation)"
    echo "  -v, --visible        Make signature visible"
    echo "  -t, --timestamp      Add timestamp to signature"
    echo ""
    echo "Environment variables:"
    echo "  PDF_CERT_PASSWORD    Certificate password (preferred method)"
    echo ""
    exit 0
}

# Function to log messages
log() {
    local level=$1
    local message=$2
    local color=$NC
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")
    
    case $level in
        "INFO") color=$BLUE ;;
        "SUCCESS") color=$GREEN ;;
        "WARNING") color=$YELLOW ;;
        "ERROR") color=$RED ;;
    esac
    
    echo -e "${color}[$timestamp] [$level] $message${NC}"
}

# Check if PDF_CERT_PASSWORD environment variable is set (default method)
if [ -n "$PDF_CERT_PASSWORD" ]; then
    PASSWORD="$PDF_CERT_PASSWORD"
fi

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -i|--input-dir)
            INPUT_DIR="$2"
            shift 2
            ;;
        -o|--output-dir)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        -c|--cert)
            CERT_FILE="$2"
            shift 2
            ;;
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        --password-env)
            ENV_VAR="$2"
            PASSWORD="${!ENV_VAR}"
            if [ -z "$PASSWORD" ]; then
                log "ERROR" "Environment variable $ENV_VAR not set or empty"
                exit 1
            fi
            shift 2
            ;;
        --password-file)
            PASSWORD_FILE="$2"
            if [ ! -f "$PASSWORD_FILE" ]; then
                log "ERROR" "Password file does not exist: $PASSWORD_FILE"
                exit 1
            fi
            PASSWORD=$(head -n 1 "$PASSWORD_FILE")
            if [ -z "$PASSWORD" ]; then
                log "ERROR" "Password file is empty"
                exit 1
            fi
            shift 2
            ;;
        --prompt-password)
            # Read password securely
            read -s -p "Enter certificate password: " PASSWORD
            echo # Add newline after password input
            if [ -z "$PASSWORD" ]; then
                log "ERROR" "Password cannot be empty"
                exit 1
            fi
            shift
            ;;
        -l|--location)
            LOCATION="$2"
            shift 2
            ;;
        -r|--reason)
            REASON="$2"
            shift 2
            ;;
        -v|--visible)
            VISIBLE=true
            shift
            ;;
        -t|--timestamp)
            TIMESTAMP=true
            shift
            ;;
        *)
            log "ERROR" "Unknown option: $1"
            show_help
            ;;
    esac
done

# Validate required parameters
if [ -z "$INPUT_DIR" ]; then
    log "ERROR" "Input directory is required (-i, --input-dir)"
    exit 1
fi

if [ -z "$OUTPUT_DIR" ]; then
    log "ERROR" "Output directory is required (-o, --output-dir)"
    exit 1
fi

if [ -z "$CERT_FILE" ]; then
    log "ERROR" "Certificate file is required (-c, --cert)"
    exit 1
fi

if [ -z "$PASSWORD" ]; then
    log "ERROR" "Certificate password is required. Set PDF_CERT_PASSWORD environment variable or use one of the password options."
    exit 1
fi

# Check if input directory exists
if [ ! -d "$INPUT_DIR" ]; then
    log "ERROR" "Input directory does not exist: $INPUT_DIR"
    exit 1
fi

# Check if certificate file exists
if [ ! -f "$CERT_FILE" ]; then
    log "ERROR" "Certificate file does not exist: $CERT_FILE"
    exit 1
fi

# Create output directory if it doesn't exist
if [ ! -d "$OUTPUT_DIR" ]; then
    log "INFO" "Creating output directory: $OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
    if [ $? -ne 0 ]; then
        log "ERROR" "Failed to create output directory: $OUTPUT_DIR"
        exit 1
    fi
fi

# Create temporary config file for visible signature if enabled
create_visible_config() {
    local config_file=$(mktemp)
    
    cat > "$config_file" << EOF
signaturePositionOnPageLowerLeftX=50
signaturePositionOnPageLowerLeftY=50
signaturePositionOnPageUpperRightX=250
signaturePositionOnPageUpperRightY=150
signaturePage=1
signatureRenderingMode=1
signatureFontSize=9
signatureFontColor=black
signatureText=Firmado por [NAME] el día [DATE] Certificado [ISSUER]
EOF
    
    echo "$config_file"
}

# Find AutoFirma executable based on OS
find_autofirma() {
    local autofirma_path=""
    
    case "$(uname -s)" in
        Linux*)
            # Try common paths on Linux
            if [ -f "/usr/bin/autofirma" ]; then
                autofirma_path="/usr/bin/autofirma"
            elif [ -f "/usr/local/bin/autofirma" ]; then
                autofirma_path="/usr/local/bin/autofirma"
            elif [ -f "/opt/autofirma/autofirma" ]; then
                autofirma_path="/opt/autofirma/autofirma"
            fi
            ;;
        Darwin*)
            # macOS
            if [ -d "/Applications/AutoFirma.app" ]; then
                autofirma_path="/Applications/AutoFirma.app/Contents/MacOS/AutoFirma"
            elif [ -d "$HOME/Applications/AutoFirma.app" ]; then
                autofirma_path="$HOME/Applications/AutoFirma.app/Contents/MacOS/AutoFirma"
            fi
            ;;
        MINGW*|CYGWIN*|MSYS*)
            # Windows
            if [ -f "C:/Program Files/AutoFirma/AutoFirma.exe" ]; then
                autofirma_path="C:/Program Files/AutoFirma/AutoFirma.exe"
            elif [ -f "C:/Program Files (x86)/AutoFirma/AutoFirma.exe" ]; then
                autofirma_path="C:/Program Files (x86)/AutoFirma/AutoFirma.exe"
            fi
            ;;
    esac
    
    # If not found in common locations, try to find in PATH
    if [ -z "$autofirma_path" ]; then
        autofirma_path=$(which autofirma 2>/dev/null || which AutoFirma 2>/dev/null)
    fi
    
    echo "$autofirma_path"
}

# Get the AutoFirma executable path
AUTOFIRMA_PATH=$(find_autofirma)

if [ -z "$AUTOFIRMA_PATH" ]; then
    log "ERROR" "AutoFirma executable not found. Please make sure it is installed and in your PATH."
    exit 1
fi

log "INFO" "Using AutoFirma: $AUTOFIRMA_PATH"

# Create configuration file for visible signature if requested
CONFIG_FILE=""
if [ "$VISIBLE" = true ]; then
    CONFIG_FILE=$(create_visible_config)
    log "INFO" "Created visible signature configuration file: $CONFIG_FILE"
fi

# Process PDF files
log "INFO" "Starting PDF signing process"
log "INFO" "Input directory: $INPUT_DIR"
log "INFO" "Output directory: $OUTPUT_DIR"
log "INFO" "Certificate file: $CERT_FILE"
log "INFO" "Location: $LOCATION"
log "INFO" "Reason: $REASON"
log "INFO" "Visible signature: $VISIBLE"
log "INFO" "Add timestamp: $TIMESTAMP"

# Get list of PDF files
PDF_FILES=$(find "$INPUT_DIR" -maxdepth 1 -type f -name "*.pdf")
PDF_COUNT=$(echo "$PDF_FILES" | wc -l | tr -d ' ')

if [ -z "$PDF_FILES" ]; then
    log "WARNING" "No PDF files found in $INPUT_DIR"
    exit 0
fi

log "INFO" "Found $PDF_COUNT PDF files to process"

# Process each PDF file
SUCCESS_COUNT=0
FAILURE_COUNT=0
CURRENT=0

for PDF_FILE in $PDF_FILES; do
    CURRENT=$((CURRENT + 1))
    FILENAME=$(basename "$PDF_FILE")
    OUTPUT_FILENAME="${FILENAME%.pdf}-signed.pdf"
    OUTPUT_PATH="$OUTPUT_DIR/$OUTPUT_FILENAME"
    
    log "INFO" "[$CURRENT/$PDF_COUNT] Processing: $FILENAME"
    
    # Construct AutoFirma command
    CMD=("$AUTOFIRMA_PATH" "sign" "-i" "$PDF_FILE" "-o" "$OUTPUT_PATH" "-store" "pkcs12:$CERT_FILE" "-password" "$PASSWORD" "-format" "PAdES")
    
    # Add location if specified
    if [ -n "$LOCATION" ]; then
        CMD+=("-location" "$LOCATION")
    fi
    
    # Add reason if specified
    if [ -n "$REASON" ]; then
        CMD+=("-reason" "$REASON")
    fi
    
    # Add configuration file if visible signature is enabled
    if [ "$VISIBLE" = true ] && [ -n "$CONFIG_FILE" ]; then
        CMD+=("-config" "$CONFIG_FILE")
    fi
    
    # Add timestamp if enabled
    if [ "$TIMESTAMP" = true ]; then
        CMD+=("-timestamp")
    fi
    
    # Execute AutoFirma command
    OUTPUT=$("${CMD[@]}" 2>&1)
    EXIT_CODE=$?
    
    if [ $EXIT_CODE -eq 0 ] && [ -f "$OUTPUT_PATH" ]; then
        SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
        log "SUCCESS" "[$CURRENT/$PDF_COUNT] Signed: $FILENAME → $OUTPUT_FILENAME"
    else
        FAILURE_COUNT=$((FAILURE_COUNT + 1))
        log "ERROR" "[$CURRENT/$PDF_COUNT] Failed to sign: $FILENAME (Exit code: $EXIT_CODE)"
        log "ERROR" "Error output: $OUTPUT"
    fi
done

# Clean up configuration file
if [ -n "$CONFIG_FILE" ] && [ -f "$CONFIG_FILE" ]; then
    rm "$CONFIG_FILE"
fi

# Display summary
log "INFO" "Signing process completed"
log "INFO" "Total PDF files: $PDF_COUNT"
log "SUCCESS" "Successfully signed: $SUCCESS_COUNT"
if [ $FAILURE_COUNT -gt 0 ]; then
    log "ERROR" "Failed to sign: $FAILURE_COUNT"
fi

exit 0 