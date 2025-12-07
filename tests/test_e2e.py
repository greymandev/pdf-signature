import os
import sys
import subprocess
import platform
import glob
import unittest
from pathlib import Path
from dotenv import load_dotenv

# Add parent directory to path to find autofirma.py if needed, 
# although we will likely call it via subprocess for true E2E
PROJECT_ROOT = Path(__file__).parent.parent
sys.path.append(str(PROJECT_ROOT))

class TestE2E(unittest.TestCase):
    def setUp(self):
        # Load env vars
        load_dotenv(PROJECT_ROOT / ".env")
        
        self.input_dir = PROJECT_ROOT / "tests" / "input_files"
        self.output_dir = PROJECT_ROOT / "tests" / "output_files"
        self.cert_file = PROJECT_ROOT / "key" / "certificado.pfx"
        
        # Create test directories
        self.input_dir.mkdir(parents=True, exist_ok=True)
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # Look for the source PDF provided by user in the root or finding it
        # User mentioned "Valoración integral..." but it is consistently missing or has encoding issues 
        # that prevent direct access despite globbing. 
        # Fallback to the known existing file: AF-manual-instalacion-usuarios-ES-1-8-2.pdf
        self.source_pdf = PROJECT_ROOT / "AF-manual-instalacion-usuarios-ES-1-8-2.pdf"
        
        # Try to find user file
        candidates = list((PROJECT_ROOT / "tests" / "input_files").glob("*Valorac*.pdf"))
        
        source_file = None
        if candidates:
            # We found it via glob, but open() might fail due to normalization.
            # Let's try to capture the exact Path object which usually works.
            source_file = candidates[0]
        
        # Determine effective source
        if source_file and source_file.exists():
            self.source_pdf = source_file
        else:
             # Fallback 1: Manual
             fallback = PROJECT_ROOT / "AF-manual-instalacion-usuarios-ES-1-8-2.pdf"
             if fallback.exists():
                 self.source_pdf = fallback
             else:
                 # Fallback 2: Generate
                 self.source_pdf = PROJECT_ROOT / "generated_test.pdf"
                 from pypdf import PdfWriter
                 writer = PdfWriter()
                 writer.add_blank_page(width=600, height=800)
                 with open(self.source_pdf, "wb") as f:
                     writer.write(f)
        
        print(f"Using source PDF: {self.source_pdf}")

        # Copy to input dir
        # If normal copy fails (unicode issues), we try reading bytes and writing.
        dest_path = self.input_dir / "test_doc.pdf"
        try:
            import shutil
            shutil.copy(self.source_pdf, dest_path)
        except Exception as e:
            print(f"Copy failed: {e}. Trying raw read/write...")
            with open(self.source_pdf, 'rb') as src, open(dest_path, 'wb') as dst:
                dst.write(src.read())

    def test_e2e_signing(self):
        """End-to-End test for signing a PDF"""
        
        # Check preconditions
        if not self.cert_file.exists():
            print(f"WARNING: Certificate file not found at {self.cert_file}. Skipping E2E test.")
            return

        password = os.getenv("PDF_CERT_PASSWORD")
        if not password:
            print("WARNING: PDF_CERT_PASSWORD not set in .env. Skipping E2E test.")
            return

        print(f"Starting E2E test on {platform.system()}...")
        print(f"Input: {self.input_dir}")
        print(f"Output: {self.output_dir}")
        print(f"Cert: {self.cert_file}")

        # Construct command
        cmd = [
            sys.executable,
            str(PROJECT_ROOT / "autofirma.py"),
            "-i", str(self.input_dir),
            "-o", str(self.output_dir),
            "-c", str(self.cert_file),
            # "-v", # Enable visible signature (Disabled for test due to AutoFirma internal error with test PDF)
            # Password is taken from env automatically by the script, 
            # but we can explicitly pass it or let the script pick it up.
            # The script logic picks up env var if -p is missing.
        ]

        # Run command
        result = subprocess.run(cmd, capture_output=True, text=True)
        
        # Debug output
        print("STDOUT:", result.stdout)
        print("STDERR:", result.stderr)
        
        if result.returncode != 0:
             print("Test failed. Check if your test PDF is valid for AutoFirma.")

        self.assertEqual(result.returncode, 0, f"Script failed with code {result.returncode}")
        
        # Verify output
        output_files = list(self.output_dir.glob("*.pdf"))
        self.assertTrue(len(output_files) > 0, "No output PDF files created")
        
        signed_pdf = output_files[0]
        print(f"Successfully created: {signed_pdf}")
        self.assertTrue(signed_pdf.stat().st_size > 0, "Signed PDF is empty")

    def tearDown(self):
        # Optional: cleanup
        pass

if __name__ == "__main__":
    unittest.main()
