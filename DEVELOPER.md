# Developer Documentation

## Overview
This project uses a Python script (`autofirma.py`) to wrap the AutoFirma CLI. It is designed to be simple, cross-platform, and easy to maintain.

## Requirements
- Python 3.6+
- AutoFirma installed on the system (for running the actual script, not strictly required for running unit tests).

## Project Structure
- `autofirma.py`: Main script.
- `tests/`: Unit tests.
- `requirements.txt`: Dependencies (currently empty/standard lib).

## Running Tests
We use `unittest` for testing.

### Unit Tests
```bash
python3 -m unittest discover tests
```

### End-to-End (E2E) Tests
To run the E2E tests, you need:
1. A valid certificate in `key/certificado.pfx`.
2. A password set in `.env` as `PDF_CERT_PASSWORD`.
3. A source PDF (the test automatically looks for `*convocatoria*.pdf` or falls back to the manual).

```bash
python3 -m unittest tests/test_e2e.py
```

## Contributing
1. Fork the repository.
2. Create a feature branch.
3. Make your changes.
4. Add tests for new functionality.
5. Ensure all tests pass.
6. Submit a Pull Request.

## Design Decisions
- **Single Script**: To minimize complexity and avoid maintaining multiple shell scripts (bash, bat, ps1) and a Java app.
- **Standard Library**: To avoid dependency hell. The script should run on any standard Python 3 installation.
- **Mocking**: Tests mock `subprocess` and `platform` to ensure they run on any machine, even without AutoFirma installed.
