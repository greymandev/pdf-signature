import unittest
import os
import sys
import tempfile
import shutil
from unittest.mock import patch, MagicMock
from pathlib import Path

# Add parent directory to path to import autofirma
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
import autofirma

class TestAutofirma(unittest.TestCase):

    @patch('platform.system')
    @patch('os.path.exists')
    def test_find_autofirma_windows(self, mock_exists, mock_system):
        mock_system.return_value = "Windows"
        # Mock that the first path exists
        mock_exists.side_effect = lambda p: "AutoFirma.exe" in p
        
        path = autofirma.find_autofirma()
        self.assertIsNotNone(path)
        self.assertIn("AutoFirma.exe", path)

    @patch('platform.system')
    @patch('os.path.exists')
    def test_find_autofirma_linux(self, mock_exists, mock_system):
        mock_system.return_value = "Linux"
        mock_exists.side_effect = lambda p: p == "/usr/bin/autofirma"
        
        path = autofirma.find_autofirma()
        self.assertEqual(path, "/usr/bin/autofirma")

    def test_create_visible_config(self):
        config_path = autofirma.create_visible_config(x=100, y=200)
        self.assertTrue(os.path.exists(config_path))
        
        with open(config_path, 'r') as f:
            content = f.read()
            self.assertIn("signaturePositionOnPageLowerLeftX=100", content)
            self.assertIn("signaturePositionOnPageLowerLeftY=200", content)
            
        os.remove(config_path)

    @patch('subprocess.run')
    def test_sign_pdf_success(self, mock_run):
        # Mock successful execution
        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_run.return_value = mock_result
        
        # Mock output file existence
        with patch('os.path.exists', return_value=True):
            result = autofirma.sign_pdf(
                autofirma_path="/usr/bin/autofirma",
                input_file="test.pdf",
                output_file="test-signed.pdf",
                cert_path="cert.pfx",
                password="pass"
            )
            
        self.assertTrue(result)
        
        # Verify command arguments
        args = mock_run.call_args[0][0]
        self.assertEqual(args[0], "/usr/bin/autofirma")
        self.assertIn("sign", args)
        self.assertIn("-i", args)
        self.assertIn("test.pdf", args)
        self.assertIn("pkcs12:cert.pfx", args)

    @patch('subprocess.run')
    def test_sign_pdf_failure(self, mock_run):
        # Mock failed execution
        mock_result = MagicMock()
        mock_result.returncode = 1
        mock_result.stderr = "Error signing"
        mock_run.return_value = mock_result
        
        result = autofirma.sign_pdf(
            autofirma_path="/usr/bin/autofirma",
            input_file="test.pdf",
            output_file="test-signed.pdf",
            cert_path="cert.pfx",
            password="pass"
        )
        
        self.assertFalse(result)

if __name__ == '__main__':
    unittest.main()
