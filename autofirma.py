#!/usr/bin/env python3
import os
import sys
import argparse
import subprocess
import platform
import glob
import tempfile
import logging
from pathlib import Path

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

def find_autofirma():
    """Finds the Autofirma executable based on the operating system."""
    system = platform.system()
    
    if system == "Windows":
        possible_paths = [
            os.path.join(os.environ.get("ProgramFiles", "C:\\Program Files"), "AutoFirma", "AutoFirma.exe"),
            os.path.join(os.environ.get("ProgramFiles(x86)", "C:\\Program Files (x86)"), "AutoFirma", "AutoFirma.exe")
        ]
    elif system == "Darwin":  # macOS
        possible_paths = [
            "/Applications/AutoFirma.app/Contents/MacOS/AutoFirma",
            os.path.expanduser("~/Applications/AutoFirma.app/Contents/MacOS/AutoFirma")
        ]
    elif system == "Linux":
        possible_paths = [
            "/usr/bin/autofirma",
            "/usr/local/bin/autofirma",
            "/opt/autofirma/autofirma"
        ]
    else:
        logger.error(f"Unsupported operating system: {system}")
        return None

    for path in possible_paths:
        if os.path.exists(path):
            return path
            
    # Try finding in PATH
    try:
        import shutil
        path = shutil.which("autofirma") or shutil.which("AutoFirma")
        if path:
            return path
    except ImportError:
        pass

    return None

def create_visible_config(x=50, y=50, width=200, height=100, page=1):
    """Creates a temporary configuration file for visible signatures."""
    config_content = f"""
signaturePositionOnPageLowerLeftX={x}
signaturePositionOnPageLowerLeftY={y}
signaturePositionOnPageUpperRightX={x + width}
signaturePositionOnPageUpperRightY={y + height}
signaturePage={page}
signatureRenderingMode=1
signatureFontSize=9
signatureFontColor=black
signatureText=Firmado por [NAME] el día [DATE] Certificado [ISSUER]
"""
    fd, path = tempfile.mkstemp(suffix='.properties', text=True)
    with os.fdopen(fd, 'w') as f:
        f.write(config_content)
    return path

def sign_pdf(autofirma_path, input_file, output_file, cert_path, password, location=None, reason=None, visible_config=None, timestamp=False):
    """Executes the Autofirma command to sign a single PDF."""
    
    cmd = [
        autofirma_path, "sign",
        "-i", input_file,
        "-o", output_file,
        "-store", f"pkcs12:{cert_path}",
        "-password", password,
        "-format", "PAdES"
    ]

    if location:
        cmd.extend(["-location", location])
    
    if reason:
        cmd.extend(["-reason", reason])
        
    if visible_config:
        cmd.extend(["-config", visible_config])
        
    if timestamp:
        cmd.append("-timestamp")

    try:
        # Run command and capture output
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        
        if result.returncode == 0 and os.path.exists(output_file):
            logger.info(f"Successfully signed: {os.path.basename(input_file)}")
            return True
        else:
            logger.error(f"Failed to sign: {os.path.basename(input_file)}")
            logger.error(f"Exit Code: {result.returncode}")
            logger.error(f"Stderr: {result.stderr}")
            logger.error(f"Stdout: {result.stdout}")
            return False
            
    except Exception as e:
        logger.error(f"Exception while signing {os.path.basename(input_file)}: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="AutoFirma PDF Signing Tool")
    
    parser.add_argument("-i", "--input-dir", required=True, help="Input directory containing PDF files")
    parser.add_argument("-o", "--output-dir", required=True, help="Output directory for signed PDFs")
    parser.add_argument("-c", "--cert", required=True, help="Path to the PFX/P12 certificate file")
    parser.add_argument("-p", "--password", help="Password for the certificate (can also use PDF_CERT_PASSWORD env var)")
    parser.add_argument("-l", "--location", default="Madrid", help="Location for signature")
    parser.add_argument("-r", "--reason", default="Document validation", help="Reason for signature")
    parser.add_argument("-v", "--visible", action="store_true", help="Make signature visible")
    parser.add_argument("-t", "--timestamp", action="store_true", help="Add timestamp to signature")
    
    args = parser.parse_args()

    # Password handling
    password = args.password
    if not password:
        password = os.environ.get("PDF_CERT_PASSWORD")
    
    if not password:
        logger.error("Password is required. Provide it via -p or PDF_CERT_PASSWORD environment variable.")
        sys.exit(1)

    # Validation
    if not os.path.isdir(args.input_dir):
        logger.error(f"Input directory does not exist: {args.input_dir}")
        sys.exit(1)
        
    if not os.path.exists(args.cert):
        logger.error(f"Certificate file does not exist: {args.cert}")
        sys.exit(1)

    # Create output dir
    os.makedirs(args.output_dir, exist_ok=True)

    # Find Autofirma
    autofirma_path = find_autofirma()
    if not autofirma_path:
        logger.error("AutoFirma executable not found. Please install AutoFirma.")
        sys.exit(1)
    
    logger.info(f"Using AutoFirma at: {autofirma_path}")

    # Visible signature config
    visible_config_path = None
    if args.visible:
        visible_config_path = create_visible_config()
        logger.info(f"Created temporary config for visible signature: {visible_config_path}")

    # Process files
    pdf_files = glob.glob(os.path.join(args.input_dir, "*.pdf"))
    if not pdf_files:
        logger.warning(f"No PDF files found in {args.input_dir}")
        sys.exit(0)

    logger.info(f"Found {len(pdf_files)} PDF files to process.")

    success_count = 0
    failure_count = 0

    for pdf_file in pdf_files:
        filename = os.path.basename(pdf_file)
        output_filename = os.path.splitext(filename)[0] + "-signed.pdf"
        output_path = os.path.join(args.output_dir, output_filename)
        
        if sign_pdf(autofirma_path, pdf_file, output_path, args.cert, password, 
                   args.location, args.reason, visible_config_path, args.timestamp):
            success_count += 1
        else:
            failure_count += 1

    # Cleanup
    if visible_config_path and os.path.exists(visible_config_path):
        os.remove(visible_config_path)

    logger.info("Signing process completed.")
    logger.info(f"Total: {len(pdf_files)}, Success: {success_count}, Failed: {failure_count}")

    if failure_count > 0:
        sys.exit(1)

if __name__ == "__main__":
    main()
