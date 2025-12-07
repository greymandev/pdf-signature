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

    @patch('autofirma.get_java_command')
    @patch('platform.system')
    @patch('os.path.exists')
    def test_find_autofirma_command_windows(self, mock_exists, mock_system, mock_java):
        mock_system.return_value = "Windows"
        # Mock that the first path exists
        mock_exists.side_effect = lambda p: "AutoFirma.exe" in p
        
        cmd = autofirma.find_autofirma_command()
        self.assertIsNotNone(cmd)
        self.assertIn("AutoFirma.exe", cmd[0])

    @patch('autofirma.get_java_command')
    @patch('platform.system')
    @patch('os.path.exists')
    def test_find_autofirma_command_linux(self, mock_exists, mock_system, mock_java):
        mock_system.return_value = "Linux"
        mock_exists.side_effect = lambda p: p == "/usr/bin/autofirma"
        
        cmd = autofirma.find_autofirma_command()
        self.assertEqual(cmd, ["/usr/bin/autofirma"])

    def test_create_config(self):
        config_path = autofirma.create_config(visible=True, x=100, y=200)
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
                autofirma_cmd=["/usr/bin/autofirma"],
                input_file="test.pdf",
                output_file="test-signed.pdf",
                cert_path="cert.pfx",
                password="pass",
                alias="myalias"
            )
            
        self.assertTrue(result)
        
        # Verify command arguments
        args = mock_run.call_args[0][0]
        self.assertEqual(args[0], "/usr/bin/autofirma")
        self.assertIn("sign", args)
        self.assertIn("-i", args)
        self.assertIn("test.pdf", args)
        self.assertIn("pkcs12:cert.pfx", args)
        self.assertIn("-alias", args)
        self.assertIn("myalias", args)

    @patch('subprocess.run')
    def test_sign_pdf_failure(self, mock_run):
        # Mock failed execution
        mock_result = MagicMock()
        mock_result.returncode = 1
        mock_result.stderr = "Error signing"
        mock_run.return_value = mock_result
        
        result = autofirma.sign_pdf(
            autofirma_cmd=["/usr/bin/autofirma"],
            input_file="test.pdf",
            output_file="test-signed.pdf",
            cert_path="cert.pfx",
            password="pass",
            alias="myalias"
        )
        
        self.assertFalse(result)

if __name__ == '__main__':
    unittest.main()
