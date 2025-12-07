#!/usr/bin/env python3
import os
import sys
import argparse
import subprocess
import platform
import glob
import tempfile
import logging
import shutil
from pathlib import Path
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

from pypdf import PdfReader

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

def determine_signature_position(pdf_path):
    """
    Analyzes the last page of the PDF to determine the best position for the signature.
    Returns a tuple: (page_number, x, y, width, height)
    Default logic: Bottom right if empty, otherwise bottom left.
    """
    try:
        reader = PdfReader(pdf_path)
        last_page_index = len(reader.pages) - 1
        page = reader.pages[last_page_index]
        
        # Get page dimensions (MediaBox)
        media_box = page.media_box
        page_width =  int(float(media_box.width))
        page_height = int(float(media_box.height))
        
        # Signature dimensions
        sig_width = 200
        sig_height = 100
        margin = 30
        
        # Default positions (origin is bottom-left in PDF coordinates)
        # Bottom-Right
        pos_right_x = page_width - sig_width - margin
        pos_right_y = margin
        
        # Bottom-Left
        pos_left_x = margin
        pos_left_y = margin
        
        # Simple extraction to guess content (heuristic)
        # In a real-world scenario, checking for whitespace is complex without CV or detailed layout analysis.
        # We will extract text and see if the bottom area seems "empty" enough or just default to Right, then Left.
        # For this implementation, we will perform a very simple heuristic: 
        # extract text from the bottom 15% of the page. If heavy text, maybe try left. 
        # However, pypdf extraction isn't always coordinates-aware in a simple way.
        # So we will default to BOTTOM-RIGHT as requested ("derecho o izquierdo"), prefering Right.
        
        # NOTE: To implement "check which side is blank", we would need to inspect text positions. 
        # pypdf's extract_text(visitor_text=...) allows this.
        
        text_on_bottom_right = False
        text_on_bottom_left = False
        
        def visitor_body(text, cm, tm, fontDict, fontSize):
            nonlocal text_on_bottom_right, text_on_bottom_left
            
            x = tm[4]
            y = tm[5]
            
            # Check if text is in the bottom signature strip (approx 100 units high)
            if y < (margin + sig_height):
                # Check horizontal position
                if x > (page_width / 2):
                    text_on_bottom_right = True
                else:
                    text_on_bottom_left = True

        page.extract_text(visitor_text=visitor_body)
        
        logger.info(f"Page Analysis (Page {last_page_index + 1}): Bottom-Left Text: {text_on_bottom_left}, Bottom-Right Text: {text_on_bottom_right}")

        # Logic: Prefer Right. If Right has text and Left is empty, use Left. Else use Right (and hope for the best/overwrite).
        target_x = pos_right_x
        target_y = pos_right_y
        
        if text_on_bottom_right and not text_on_bottom_left:
            logger.info("Bottom-Right appears occupied. Switching to Bottom-Left.")
            target_x = pos_left_x
            target_y = pos_left_y
        else:
            logger.info("Using default Bottom-Right position.")
            
        return (last_page_index + 1, target_x, target_y, sig_width, sig_height)

    except Exception as e:
        logger.error(f"Error analyzing PDF for signature position: {e}")
        # Fallback to last page, bottom right
        return (1, 300, 50, 200, 100) # Fallback values

def get_java_command():
    """Returns the java command (e.g. 'java' or full path)."""
    java_home = os.environ.get("JAVA_HOME")
    if java_home:
        java_path = os.path.join(java_home, "bin", "java")
        if os.path.exists(java_path):
            return java_path
        elif os.path.exists(java_path + ".exe"):
             return java_path + ".exe"
    
    if shutil.which("java"):
        return "java"
        
    return None

def find_autofirma_command():
    """
    Finds the Autofirma command.
    On macOS, prefers executing the JAR directly with Java to avoid native wrapper issues.
    Returns a list of arguments for subprocess, e.g. ['/usr/bin/autofirma'] or ['java', '-jar', '...']
    """
    system = platform.system()
    java_cmd = get_java_command()

    if system == "Darwin":  # macOS
        # Prefer JAR on macOS
        jar_paths = [
            "/Applications/AutoFirma.app/Contents/Resources/JAR/AutoFirma.jar",
            os.path.expanduser("~/Applications/AutoFirma.app/Contents/Resources/JAR/AutoFirma.jar")
        ]
        
        if java_cmd:
            for jar_path in jar_paths:
                if os.path.exists(jar_path):
                    logger.info(f"Found AutoFirma JAR: {jar_path}")
                    return [java_cmd, "-jar", jar_path]

        # Fallback to native config if Java/Jar not found (though native is known to be problematic on macOS headless)
        possible_paths = [
            "/Applications/AutoFirma.app/Contents/MacOS/AutoFirma",
            os.path.expanduser("~/Applications/AutoFirma.app/Contents/MacOS/AutoFirma")
        ]
        for path in possible_paths:
            if os.path.exists(path):
                return [path]

    elif system == "Windows":
        possible_paths = [
            os.path.join(os.environ.get("ProgramFiles", "C:\\Program Files"), "AutoFirma", "AutoFirma.exe"),
            os.path.join(os.environ.get("ProgramFiles(x86)", "C:\\Program Files (x86)"), "AutoFirma", "AutoFirma.exe")
        ]
        for path in possible_paths:
            if os.path.exists(path):
                return [path]

    elif system == "Linux":
         # First try looking for JAR if we want consistency, but usually /usr/bin/autofirma script works fine
         possible_paths = [
            "/usr/bin/autofirma",
            "/usr/local/bin/autofirma",
            "/opt/autofirma/autofirma"
        ]
         for path in possible_paths:
             if os.path.exists(path):
                 return [path]

    # Generalized fallback
    if shutil.which("autofirma"):
        return ["autofirma"]
        
    if shutil.which("AutoFirma"):
        return ["AutoFirma"]

    return None

def get_certificate_alias(autofirma_cmd, cert_path, password):
    """
    Retrieves the first available alias from the certificate PFX using AutoFirma listaliases.
    """
    cmd = autofirma_cmd + [
        "listaliases",
        "-store", f"pkcs12:{cert_path}",
        "-password", password
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        if result.returncode == 0:
            lines = result.stdout.strip().split('\n')
            # Filter empty lines
            aliases = [line.strip() for line in lines if line.strip()]
            if aliases:
                return aliases[0]
            else:
                logger.warning("No aliases found in output.")
                return None
        else:
            logger.warning(f"Failed to list aliases. Exit code: {result.returncode}")
            logger.warning(f"Stderr: {result.stderr}")
            return None
    except Exception as e:
        logger.error(f"Error getting aliases: {e}")
        return None

def create_config(visible, x=50, y=50, width=200, height=100, page=1, location=None, reason=None, timestamp=False):
    """Creates a temporary configuration file for the signature operation."""
    config_lines = []
    
    if visible:
        # Clamp values to be safe
        x = max(0, int(x))
        y = max(0, int(y))
        width = max(50, int(width))
        height = max(50, int(height))
        page = max(1, int(page))
        
        config_lines.append(f"signaturePositionOnPageLowerLeftX={x}")
        config_lines.append(f"signaturePositionOnPageLowerLeftY={y}")
        config_lines.append(f"signaturePositionOnPageUpperRightX={x + width}")
        config_lines.append(f"signaturePositionOnPageUpperRightY={y + height}")
        config_lines.append(f"signaturePage={page}")
        
        # Standard visible signature config
        config_lines.append("signatureRenderingMode=1")
        # Ensure default text is present to avoid missing param errors
        config_lines.append("signatureText=Firmado digitalmente")
        # Also set layer2 params for compatibility
        config_lines.append("layer2Text=Firmado digitalmente")
        config_lines.append("layer2FontFamily=1")
        config_lines.append("layer2FontSize=10")
    
    if location:
        config_lines.append(f"signatureProductionCity={location}")
        
    if reason:
        config_lines.append(f"signatureReason={reason}")
        
    # Timestamp handling is complex via CLI without configured TSA. 
    # Some versions support applyTimestamp=true if global config has TSA.
    if timestamp:
         config_lines.append("applyTimestamp=true")

    if not config_lines:
        return None

    fd, path = tempfile.mkstemp(suffix='.properties', text=True)
    with os.fdopen(fd, 'w') as f:
        f.write("\n".join(config_lines))
    return path

def sign_pdf(autofirma_cmd, input_file, output_file, cert_path, password, location=None, reason=None, visible=False, timestamp=False, alias=None):
    """Executes the Autofirma command to sign a single PDF."""
    
    # Calculate position if visible is requested
    page_num = 1
    sig_x = 50
    sig_y = 50
    sig_w = 200
    sig_h = 100

    if visible:
        try:
            page_num, sig_x, sig_y, sig_w, sig_h = determine_signature_position(input_file)
            logger.info(f"Signature Placement -> Page: {page_num}, X: {sig_x}, Y: {sig_y}")
        except Exception as e:
            logger.error(f"Failed to determine position: {e}. Using defaults.")
    
    # If no alias provided, try to fetch it
    if not alias:
        logger.info("No alias provided. Attempting to auto-detect alias...")
        alias = get_certificate_alias(autofirma_cmd, cert_path, password)
        if alias:
            logger.info(f"Using alias: {alias}")
        else:
            logger.error("Could not detect alias. Signing may fail.")

    cmd = autofirma_cmd + [
        "sign",
        "-i", input_file,
        "-o", output_file,
        "-store", f"pkcs12:{cert_path}",
        "-password", password,
        "-format", "pades"
    ]

    if alias:
        cmd.extend(["-alias", alias])
    
    # Generate config file for extra params (visible, location, reason, timestamp)
    config_path = create_config(visible, x=sig_x, y=sig_y, width=sig_w, height=sig_h, page=page_num, location=location, reason=reason, timestamp=timestamp)
    if config_path:
        cmd.extend(["-config", config_path])
        logger.info(f"Using configuration file: {config_path}")
        
        # DEBUG: Print config content
        try:
            with open(config_path, 'r') as f:
                logger.info(f"Config Content:\n{f.read()}")
        except:
            pass

    try:
        # Run command and capture output
        logger.info(f"Executing: {' '.join(cmd)}")
        result = subprocess.run(cmd, capture_output=True, text=True, check=False)
        
        output_exists = os.path.exists(output_file)
        
        if result.returncode == 0 and output_exists:
            logger.info(f"Successfully signed: {os.path.basename(input_file)}")
            # Cleanup config only on success or if we are done with it
            if config_path and os.path.exists(config_path):
                os.remove(config_path)
            return True
        else:
            logger.error(f"Failed to sign: {os.path.basename(input_file)}")
            if not output_exists:
                logger.error(f"Output file was NOT created at: {output_file}")
            
            logger.error(f"Exit Code: {result.returncode}")
            logger.error(f"Stderr: {result.stderr}")
            logger.error(f"Stdout: {result.stdout}")
            
            # Cleanup config
            if config_path and os.path.exists(config_path):
                os.remove(config_path)
            return False
            
    except Exception as e:
        logger.error(f"Exception while signing {os.path.basename(input_file)}: {e}")
        if config_path and os.path.exists(config_path):
            os.remove(config_path)
        return False

def main():
    parser = argparse.ArgumentParser(description="AutoFirma PDF Signing Tool")
    
    parser.add_argument("-i", "--input-dir", required=True, help="Input directory containing PDF files")
    parser.add_argument("-o", "--output-dir", required=True, help="Output directory for signed PDFs")
    parser.add_argument("-c", "--cert", required=True, help="Path to the PFX/P12 certificate file")
    parser.add_argument("-p", "--password", help="Password for the certificate (can also use PDF_CERT_PASSWORD env var)")
    parser.add_argument("-l", "--location", help="Location for signature")
    parser.add_argument("-r", "--reason", help="Reason for signature")
    parser.add_argument("-v", "--visible", action="store_true", help="Make signature visible")
    parser.add_argument("-t", "--timestamp", action="store_true", help="Add timestamp to signature")
    parser.add_argument("-a", "--alias", help="Certificate alias (optional, will auto-detect if omitted)")
    
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
    autofirma_cmd = find_autofirma_command()
    if not autofirma_cmd:
        logger.error("AutoFirma executable not found. Please install AutoFirma.")
        sys.exit(1)
    
    logger.info(f"Using AutoFirma command: {' '.join(autofirma_cmd)}")

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
        
        if sign_pdf(autofirma_cmd, pdf_file, output_path, args.cert, password, 
                   location=args.location, reason=args.reason, visible=args.visible, timestamp=args.timestamp, alias=args.alias):
            success_count += 1
        else:
            failure_count += 1

    logger.info("Signing process completed.")
    logger.info(f"Total: {len(pdf_files)}, Success: {success_count}, Failed: {failure_count}")

    if failure_count > 0:
        sys.exit(1)

if __name__ == "__main__":
    main()
