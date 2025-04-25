# PDF Signature Tool

A Java application for automating PDF signing using AutoFirma digital signature software.

## Features

- Sign PDF files in batch mode from a directory
- GUI interface for interactive use
- Command line interface for automation
- Support for visible and invisible signatures
- Timestamp support
- Certificate password protection
- Detailed logging of operations
- Customizable signature appearance
- Cross-platform support (Windows, macOS, Linux)

## Requirements

- Java 8 or higher
- [AutoFirma](https://firmaelectronica.gob.es/Home/Descargas.html) installed on your system
- A digital certificate in PKCS#12 format (.pfx or .p12)

## Installation

1. Download the latest release from the releases page
2. Ensure AutoFirma is installed on your system
3. Place your certificate file (.pfx or .p12) in a secure location
4. Run the application using Java

## Usage

### GUI Mode

To start the application in GUI mode, simply run the JAR file without any arguments:

```
java -jar pdf-signature.jar
```

Follow the on-screen prompts to:
1. Select input directory containing PDF files
2. Select output directory for signed PDFs
3. Select your certificate file
4. Enter your certificate password
5. Configure signing options (location, reason, visibility)

### Command Line Mode

For batch processing or automation, use the command line interface:

```
java -jar pdf-signature.jar [OPTIONS]
```

Options:
- `-i, --input-dir`: Input directory containing PDF files (required)
- `-o, --output-dir`: Output directory for signed PDFs (required)
- `-c, --cert`: Path to the PFX certificate file (required)
- `-p, --password`: Password for the PFX certificate (required)
- `-l, --location`: Location for signature (default: Madrid)
- `-r, --reason`: Reason for signature (default: Document validation)
- `-v, --visible`: Make signature visible (default: false)
- `-t, --timestamp`: Add timestamp to signature (default: false)
- `-h, --help`: Display help message

Example:
```
java -jar pdf-signature.jar -i ./pdfs -o ./signed_pdfs -c ./certificate.pfx -p mypassword -l "Barcelona" -r "Invoice approval" -v
```

## Building from Source

1. Clone this repository
2. Build using your favorite Java IDE or with javac:
   ```
   javac PDFSignerApp.java
   ```
3. Run the compiled application:
   ```
   java PDFSignerApp
   ```

## Shell Script Version

For users who prefer a shell script instead of Java, a `auto_sign_pdf.sh` script is included that provides similar functionality using direct calls to AutoFirma.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Troubleshooting

- Make sure AutoFirma is properly installed and accessible in your PATH
- For visible signatures, ensure you have appropriate permissions to modify the PDF
- Check that your certificate is valid and the password is correct
- If signing fails, check AutoFirma logs for more detailed error information
- Some PDFs may be protected against modifications - these cannot be signed