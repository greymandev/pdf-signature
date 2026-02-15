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

    @patch.dict(os.environ, {
        'PDF_SIG_RECT_X': '100',
        'PDF_SIG_RECT_Y': '200',
        'PDF_SIG_WIDTH': '50',
        'PDF_SIG_HEIGHT': '25',
        'PDF_SIG_PAGE': '1',
        'PDF_SIG_TEXT': 'Test signature',
        'PDF_SIG_COLOR': 'black'
    })
    def test_generate_config_lines_visible(self):
        """Test that visible signature config generates correct lines."""
        config_lines = autofirma.generate_config_lines(visible=True)
        
        self.assertIn("signaturePositionOnPageLowerLeftX=100", config_lines)
        self.assertIn("signaturePositionOnPageLowerLeftY=200", config_lines)
        self.assertIn("signaturePositionOnPageUpperRightX=150", config_lines)  # x + width
        self.assertIn("signaturePositionOnPageUpperRightY=225", config_lines)  # y + height
        self.assertIn("signatureRenderingMode=1", config_lines)
        self.assertIn("layer2Text=Test signature", config_lines)
    
    def test_generate_config_lines_with_reason_location(self):
        """Test that reason and location are added to config."""
        config_lines = autofirma.generate_config_lines(
            visible=False, 
            location="Madrid", 
            reason="Test signature"
        )
        
        self.assertIn("signatureProductionCity=Madrid", config_lines)
        self.assertIn("signatureReason=Test signature", config_lines)
    
    def test_generate_config_lines_invisible(self):
        """Test that invisible signature generates minimal config."""
        config_lines = autofirma.generate_config_lines(visible=False)
        
        # Should not have position lines for invisible signature
        self.assertFalse(any("signaturePositionOnPage" in line for line in config_lines))

    @patch('subprocess.run')
    def test_sign_pdf_success(self, mock_run):
        """Test successful PDF signing with native Linux command."""
        # Mock successful execution
        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_run.return_value = mock_result
        
        # Mock output file existence
        with patch('os.path.exists', return_value=True):
            result = autofirma.sign_pdf(
                autofirma_cmd=["/usr/bin/autofirma"],  # Native Linux command
                input_file="test.pdf",
                output_file="test-signed.pdf",
                cert_path="cert.pfx",
                password="pass",
                alias="myalias"
            )
            
        self.assertTrue(result)
        
        # Verify command arguments for native command
        args = mock_run.call_args[0][0]
        self.assertEqual(args[0], "/usr/bin/autofirma")
        self.assertIn("sign", args)
        self.assertIn("-i", args)
        self.assertIn("test.pdf", args)
        self.assertIn("pkcs12:cert.pfx", args)
        self.assertIn("-alias", args)
        self.assertIn("myalias", args)

    @patch('subprocess.run')
    def test_sign_pdf_success_with_jar(self, mock_run):
        """Test successful PDF signing with JAR command (macOS)."""
        # Mock successful execution
        mock_result = MagicMock()
        mock_result.returncode = 0
        mock_run.return_value = mock_result
        
        # Mock output file existence
        with patch('os.path.exists', return_value=True):
            result = autofirma.sign_pdf(
                autofirma_cmd=["java", "-jar", "/Applications/AutoFirma.app/Contents/Resources/JAR/AutoFirma.jar"],
                input_file="test.pdf",
                output_file="test-signed.pdf",
                cert_path="cert.pfx",
                password="pass",
                alias="myalias"
            )
            
        self.assertTrue(result)
        
        # Verify command arguments for JAR command
        args = mock_run.call_args[0][0]
        self.assertEqual(args[0], "java")
        self.assertEqual(args[1], "-jar")
        self.assertIn("AutoFirma.jar", args[2])
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
