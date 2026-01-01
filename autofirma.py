#!/usr/bin/env python3
import os
import sys
import argparse
import subprocess
import platform
import glob
import logging
import shutil
import base64
from dotenv import load_dotenv

# Load environment variables from .env file
load_dotenv()

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

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

def get_base64_image(image_path):
    """Reads an image file and returns its base64 string."""
    if not image_path or not os.path.exists(image_path):
        return None
    try:
        with open(image_path, "rb") as img_file:
            return base64.b64encode(img_file.read()).decode('utf-8')
    except Exception as e:
        logger.error(f"Error reading image {image_path}: {e}")
        return None

def generate_config_lines(visible, location=None, reason=None, timestamp=False):
    """Generates the configuration lines reading from Environment Variables."""
    config_lines = []
    
    if visible:
        # Validar variables requeridas para firma visible
        required_vars = {
            'PDF_SIG_RECT_X': 'Coordenada X de la firma',
            'PDF_SIG_RECT_Y': 'Coordenada Y de la firma',
            'PDF_SIG_WIDTH': 'Ancho de la firma',
            'PDF_SIG_HEIGHT': 'Alto de la firma'
        }
        
        missing_vars = []
        for var, description in required_vars.items():
            if not os.environ.get(var):
                missing_vars.append(f"{var} ({description})")
        
        if missing_vars:
            error_msg = "Para usar firma visible, debes configurar las siguientes variables en tu .env:\n"
            error_msg += "\n".join(f"  - {var}" for var in missing_vars)
            logger.error(error_msg)
            raise ValueError(error_msg)
        
        # Leer configuración desde .env (ahora sin defaults)
        rect_x = os.environ.get("PDF_SIG_RECT_X")
        rect_y = os.environ.get("PDF_SIG_RECT_Y")
        rect_w = os.environ.get("PDF_SIG_WIDTH")
        rect_h = os.environ.get("PDF_SIG_HEIGHT")
        sig_page = os.environ.get("PDF_SIG_PAGE", "1")  # Default razonable: primera página
        
        # Texto (con default razonable)
        default_text = "Firmado por $$SUBJECTCN$$ el día $$SIGNDATE=dd/MM/yyyy$$"
        custom_text = os.environ.get("PDF_SIG_TEXT", default_text)
        
        # Determinar si se debe manejar literal \n para multiline text desde env
        custom_text = custom_text.replace("\\n", "\n")

        # Color (default razonable)
        color = os.environ.get("PDF_SIG_COLOR", "black")
        
        # Image
        image_path = os.environ.get("PDF_SIG_IMAGE_PATH")
        image_base64 = get_base64_image(image_path)
        
        # Construct Config
        config_lines.append(f"layer2Text={custom_text}")
        config_lines.append(f"signaturePositionOnPageLowerLeftX={rect_x}")
        config_lines.append(f"signaturePositionOnPageLowerLeftY={rect_y}")
        config_lines.append(f"signaturePositionOnPageUpperRightX={int(rect_x) + int(rect_w)}")
        config_lines.append(f"signaturePositionOnPageUpperRightY={int(rect_y) + int(rect_h)}")
        config_lines.append(f"signaturePage={sig_page}")
        config_lines.append("signatureRenderingMode=1")
        
        # Font settings from .env (Advanced)
        config_lines.append(f"layer2FontColor={color}")
        # Could add size/family if needed via env, but keeping simple for now
        
        if image_base64:
             config_lines.append(f"signatureRubricImage={image_base64}")

    if location:
        config_lines.append(f"signatureProductionCity={location}")
        
    if reason:
        config_lines.append(f"signatureReason={reason}")
        
    if timestamp:
         config_lines.append("applyTimestamp=true")

    return config_lines

def sign_pdf(autofirma_cmd, input_file, output_file, cert_path, password, location=None, reason=None, visible=False, timestamp=False, alias=None):
    """Executes the Autofirma command to sign a single PDF."""
    
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
    
    # Generate Config
    config_lines = generate_config_lines(visible, location=location, reason=reason, timestamp=timestamp)
    
    cmd_attempt = list(cmd)
    
    if config_lines:
        config_content = "\n".join(config_lines)
        logger.info(f"[Config] Content:\n{config_content}") 
        
        config_base64 = base64.b64encode(config_content.encode('utf-8')).decode('utf-8')
        cmd_attempt.extend(["-config", config_base64])

    try:
        logger.info(f"Executing signing command...")
        result = subprocess.run(cmd_attempt, capture_output=True, text=True, check=False)
        
        output_exists = os.path.exists(output_file)
        
        if result.returncode == 0 and output_exists:
            logger.info(f"Successfully signed: {os.path.basename(input_file)}")
            return True
        else:
            logger.warning(f"Signing failed. Code: {result.returncode}")
            if result.stderr:
                logger.warning(f"Stderr: {result.stderr[:500]}...") # Log more stderr
            return False
            
    except Exception as e:
        logger.error(f"Exception: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description="AutoFirma PDF Signing Tool")
    
    # Make arguments optional for dual-mode support (CLI or Env)
    parser.add_argument("-i", "--input-dir", help="Input directory containing PDF files")
    parser.add_argument("-o", "--output-dir", help="Output directory for signed PDFs")
    parser.add_argument("-c", "--cert", help="Path to the PFX/P12 certificate file")
    parser.add_argument("-p", "--password", help="Password for the certificate (can also use PDF_CERT_PASSWORD env var)")
    parser.add_argument("-l", "--location", help="Location for signature")
    parser.add_argument("-r", "--reason", help="Reason for signature")
    parser.add_argument("-v", "--visible", action="store_true", help="Make signature visible")
    parser.add_argument("-t", "--timestamp", action="store_true", help="Add timestamp to signature")
    parser.add_argument("-a", "--alias", help="Certificate alias (optional, will auto-detect if omitted)")
    
    args = parser.parse_args()

    # --- Configuration Resolution (CLI vs Env) ---
    def get_env_bool(key):
        return os.environ.get(key, "").lower() == "true"

    input_dir = args.input_dir or os.environ.get("PDF_INPUT_DIR")
    output_dir = args.output_dir or os.environ.get("PDF_OUTPUT_DIR")
    cert_path = args.cert or os.environ.get("PDF_CERT_PATH")
    password = args.password or os.environ.get("PDF_CERT_PASSWORD")
    location = args.location or os.environ.get("PDF_LOCATION")
    reason = args.reason or os.environ.get("PDF_REASON")
    visible = args.visible or get_env_bool("PDF_VISIBLE")
    timestamp = args.timestamp or get_env_bool("PDF_TIMESTAMP")
    alias = args.alias or os.environ.get("PDF_ALIAS")
    
    # --- Validation ---
    missing_params = []
    if not input_dir: missing_params.append("Input Directory (-i / PDF_INPUT_DIR)")
    if not output_dir: missing_params.append("Output Directory (-o / PDF_OUTPUT_DIR)")
    if not cert_path: missing_params.append("Certificate Path (-c / PDF_CERT_PATH)")
    if not password: missing_params.append("Password (-p / PDF_CERT_PASSWORD)")
    
    if missing_params:
        logger.error("Missing required configuration parameters:")
        for p in missing_params:
            logger.error(f"  - {p}")
        logger.error("Please provide them via command line arguments or .env file.")
        sys.exit(1)

    # Validate Paths
    if not os.path.isdir(input_dir):
        logger.error(f"Input directory does not exist: {input_dir}")
        sys.exit(1)
        
    if not os.path.exists(cert_path):
        logger.error(f"Certificate file does not exist: {cert_path}")
        sys.exit(1)

    output_dir = os.path.abspath(output_dir)
    # Ensure creation
    if not os.path.exists(output_dir):
        try:
             os.makedirs(output_dir, exist_ok=True)
        except Exception as e:
             logger.error(f"Could not create output directory: {e}")
             sys.exit(1)


    autofirma_cmd = find_autofirma_command()
    if not autofirma_cmd:
        logger.error("AutoFirma executable not found. Please install AutoFirma.")
        sys.exit(1)
    
    input_dir_abs = os.path.abspath(input_dir)
    pdf_files = glob.glob(os.path.join(input_dir_abs, "*.pdf"))
    cert_path_abs = os.path.abspath(cert_path)
    
    if not pdf_files:
        logger.warning(f"No PDF files found in {input_dir}")
        sys.exit(0)

    logger.info(f"Found {len(pdf_files)} PDF files to process.")

    success_count = 0
    failure_count = 0

    for pdf_file in pdf_files:
        filename = os.path.basename(pdf_file)
        if "-signed.pdf" in filename: continue
            
        output_filename = os.path.splitext(filename)[0] + "-signed.pdf"
        output_path = os.path.join(output_dir, output_filename)
        
        if sign_pdf(autofirma_cmd, pdf_file, output_path, cert_path_abs, password, 
                   location=location, reason=reason, visible=visible, timestamp=timestamp, alias=alias):
            success_count += 1
        else:
            failure_count += 1

    logger.info("Signing process completed.")
    logger.info(f"Total: {len(pdf_files)}, Success: {success_count}, Failed: {failure_count}")

    if failure_count > 0:
        sys.exit(1)

if __name__ == "__main__":
    main()
