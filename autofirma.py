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
import base64
import json
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
    Logic: Search vertically on the RIGHT side for the first available blank space.
    """
    try:
        reader = PdfReader(pdf_path)
        last_page_index = len(reader.pages) - 1
        page = reader.pages[last_page_index]
        
        # Get page dimensions (MediaBox)
        # Handle pypdf version differences
        if hasattr(page, 'mediabox'):
            media_box = page.mediabox
        elif hasattr(page, 'mediaBox'):
            media_box = page.mediaBox
        else:
             # Fallback
             media_box = page['/MediaBox']

        page_width =  int(float(media_box.width))
        page_height = int(float(media_box.height))
        
        # Signature dimensions
        sig_width = 200
        sig_height = 100
        margin = 30
        padding = 10
        
        # X position for Right side
        target_x = page_width - sig_width - margin
        
        # Helper to check if a specific rectangle has text
        def is_occupied(rect_x, rect_y, rect_w, rect_h):
            occupied = False
            
            def visitor_body(text, cm, tm, fontDict, fontSize):
                nonlocal occupied
                if occupied: return
                
                # Text position
                tx = tm[4]
                ty = tm[5]
                
                # Check overlap
                # Simple point check: is the text start point inside the rect?
                # For more robustness we could check bounding box, but start point is a good proxy.
                if (rect_x <= tx <= rect_x + rect_w) and (rect_y <= ty <= rect_y + rect_h):
                    occupied = True

            page.extract_text(visitor_text=visitor_body)
            return occupied

        # Search upwards
        # Start from bottom margin
        current_y = margin
        found_y = -1
        
        # Limit search to not go too high (e.g., leave header space)
        # Use 80% of page height as limit
        limit_y = page_height * 0.8
        
        while current_y < limit_y:
            logger.info(f"Checking position X={target_x}, Y={current_y}...")
            if not is_occupied(target_x, current_y, sig_width, sig_height):
                logger.info(f"Found empty space at Y={current_y}")
                found_y = current_y
                break
            else:
                logger.info(f"Position at Y={current_y} is occupied. Moving up.")
                current_y += (sig_height + padding)
                
        if found_y != -1:
            return (last_page_index + 1, target_x, found_y, sig_width, sig_height)
        else:
            logger.warning("Could not find empty space on the right side. Defaulting to bottom-right (overlap possible).")
            return (last_page_index + 1, target_x, margin, sig_width, sig_height)

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

def load_signature_profiles():
    """Loads signature profiles from signature_profiles.json."""
    try:
        current_dir = os.path.dirname(os.path.abspath(__file__))
        json_path = os.path.join(current_dir, "signature_profiles.json")
        with open(json_path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except Exception as e:
        logger.warning(f"Could not load signature_profiles.json: {e}. Using internal defaults.")
        return {}

def generate_config_lines(visible, profile=None, x=None, y=None, width=None, height=None, page=None, location=None, reason=None, timestamp=False):
    """Generates the configuration lines."""
    config_lines = []
    
    if visible:
        # Default values
        rect_x = 10
        rect_y = 122
        rect_w = 27
        rect_h = 13
        sig_page = 1
        custom_text = "Firmado digitalmente"
        
        # Load From Profile if available
        if profile:
             rect_x = profile.get("rect", {}).get("x", rect_x)
             rect_y = profile.get("rect", {}).get("y", rect_y)
             rect_w = profile.get("rect", {}).get("width", rect_w)
             rect_h = profile.get("rect", {}).get("height", rect_h)
             sig_page = profile.get("page", sig_page)
             custom_text = profile.get("text", custom_text)

        # Allow overrides via kwargs if provided (programmatic overrides)
        if x is not None: rect_x = x
        if y is not None: rect_y = y
        if width is not None: rect_w = width
        if height is not None: rect_h = height
        if page is not None: sig_page = page
        
        config_lines.append(f"signaturePositionOnPageLowerLeftX={rect_x}")
        config_lines.append(f"signaturePositionOnPageLowerLeftY={rect_y}")
        config_lines.append(f"signaturePositionOnPageUpperRightX={rect_x + rect_w}")
        config_lines.append(f"signaturePositionOnPageUpperRightY={rect_y + rect_h}")
        config_lines.append(f"signaturePage={sig_page}")
        
        # Standard visible signature config
        config_lines.append("signatureRenderingMode=1")
        
        config_lines.append(f"signatureText={custom_text}")
        config_lines.append(f"layer2Text={custom_text}")
    
    if location:
        config_lines.append(f"signatureProductionCity={location}")
        
    if reason:
        config_lines.append(f"signatureReason={reason}")
        
    if timestamp:
         config_lines.append("applyTimestamp=true")

    return config_lines

def sign_pdf(autofirma_cmd, input_file, output_file, cert_path, password, location=None, reason=None, visible=False, timestamp=False, alias=None, profile=None):
    """Executes the Autofirma command to sign a single PDF."""
    
    # Calculate position if visible is requested
    # If using a profile with fixed coordinates, dynamic calculation is skipped by generate_config_lines using the profile values.
    # However, if profile suggests dynamic (e.g. missing rect), we might want to calculate.
    # For now, we assume if visible is true and we have a profile, the profile dictates the layout.
    # If no profile, defaults in generate_config_lines apply (which are now custom defaults).
    
    # Fallback/Retry Logic Preparation
    # If we need to calculate variables for dynamic profiles, do it here.
    # But currently the requirement is fixed coordinates from profile.
    
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
    
    # Strategy: Try primary config first. If it fails (AutoFirma crash), try fallback.
    
    # 1. Generate Primary Config
    # We pass the profile. The generate_config_lines function handles extracting X,Y from it.
    config_lines = generate_config_lines(visible, profile=profile, location=location, reason=reason, timestamp=timestamp)
    
    # Helper to execute sign command with a specific config
    def execute_sign_attempt(current_config_lines, description="Primary"):
        cmd_attempt = list(cmd) # Clone base cmd
        config_path_cleanup = None
        
        if current_config_lines:
            # Use Base64 encoding for config
            config_content = "\n".join(current_config_lines)
            config_base64 = base64.b64encode(config_content.encode('utf-8')).decode('utf-8')
            cmd_attempt.extend(["-config", config_base64])
            logger.info(f"[{description}] Config Base64 prefix: {config_base64[:15]}...")

        try:
            logger.info(f"[{description}] Executing signing command...")
            result = subprocess.run(cmd_attempt, capture_output=True, text=True, check=False)
            
            output_exists = os.path.exists(output_file)
            
            if result.returncode == 0 and output_exists:
                logger.info(f"[{description}] Successfully signed: {os.path.basename(input_file)}")
                return True, result
            else:
                logger.warning(f"[{description}] Signing failed. Code: {result.returncode}")
                # Log a bit of stderr for context
                if result.stderr:
                    logger.warning(f"[{description}] Stderr: {result.stderr[:200]}...")
                return False, result
        except Exception as e:
            logger.error(f"[{description}] Exception: {e}")
            return False, None

    # Attempt 1: Primary
    success, result = execute_sign_attempt(config_lines, "Primary")
    
    if success:
        return True
    
    # Attempt 2: Fallback (Safe Zone - Bottom Left) if visible
    if visible and not success:
        logger.warning("Primary signature placement failed. Attempting fallback to Safe Zone (Bottom Left).")
        
        # Fallback coordinates (Safe Zone)
        fallback_x = 50
        fallback_y = 50
        
        # For fallback, we ignore the profile's position and try known safe values, 
        # but we might want to keep the text or other settings from the profile?
        # Let's create a temporary profile or just override args.
        # generate_config_lines accepts overrides.
        
        # Use profile if available for text/page, but override coords.
        fallback_config = generate_config_lines(visible, profile=profile, x=fallback_x, y=fallback_y, location=location, reason=reason, timestamp=timestamp)
        
        success_fallback, result_fallback = execute_sign_attempt(fallback_config, "Fallback")
        
        if success_fallback:
            return True
        
        # If fallback failed, rely on the last result (primary or fallback) to log full error
        result = result_fallback

    # Final Failure Logging
    logger.error(f"Failed to sign: {os.path.basename(input_file)}")
    if not os.path.exists(output_file):
         logger.error(f"Output file was NOT created at: {output_file}")
    
    if result:
        logger.error(f"Exit Code: {result.returncode}")
        logger.error(f"Stderr: {result.stderr}")
        logger.error(f"Stdout: {result.stdout}")

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
    parser.add_argument("-P", "--profile", default="default", help="Visible signature profile name (from signature_profiles.json)")
    
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

    # Ensure output dir is absolute
    args.output_dir = os.path.abspath(args.output_dir)
    os.makedirs(args.output_dir, exist_ok=True)

    # Find Autofirma
    autofirma_cmd = find_autofirma_command()
    if not autofirma_cmd:
        logger.error("AutoFirma executable not found. Please install AutoFirma.")
        sys.exit(1)
    
    # Load Profiles
    profiles = load_signature_profiles()
    active_profile = profiles.get(args.profile)
    if not active_profile and args.profile != "default":
        logger.warning(f"Profile '{args.profile}' not found. Using defaults.")
    
    # Process files - Ensure absolute paths
    input_dir_abs = os.path.abspath(args.input_dir)
    pdf_files = glob.glob(os.path.join(input_dir_abs, "*.pdf"))
    
    # Cert path absolute
    cert_path_abs = os.path.abspath(args.cert)
    
    if not pdf_files:
        logger.warning(f"No PDF files found in {args.input_dir}")
        sys.exit(0)

    logger.info(f"Found {len(pdf_files)} PDF files to process.")

    success_count = 0
    failure_count = 0

    for pdf_file in pdf_files:
        filename = os.path.basename(pdf_file)
        # Avoid processing already signed files if they are in the same dir (though usually output_dir is different)
        if "-signed.pdf" in filename:
            continue
            
        output_filename = os.path.splitext(filename)[0] + "-signed.pdf"
        output_path = os.path.join(args.output_dir, output_filename)
        
        if sign_pdf(autofirma_cmd, pdf_file, output_path, cert_path_abs, password, 
                   location=args.location, reason=args.reason, visible=args.visible, timestamp=args.timestamp, alias=args.alias,
                   profile=active_profile):
            success_count += 1
        else:
            failure_count += 1

    logger.info("Signing process completed.")
    logger.info(f"Total: {len(pdf_files)}, Success: {success_count}, Failed: {failure_count}")

    if failure_count > 0:
        sys.exit(1)

if __name__ == "__main__":
    main()
