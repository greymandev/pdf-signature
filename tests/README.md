# Documentación de Pruebas (Tests)

Este proyecto incluye pruebas automatizadas para validar el correcto funcionamiento del firmado de PDFs.

## Prerrequisitos

Asegúrate de tener configurado el entorno como se indica en `../DEVELOPMENT.md`, incluyendo:
- `requirements.txt` instalados.
- `.env` con `PDF_CERT_PASSWORD`.
- Certificado válido en `../key/certificado.pfx`.

## Scripts de Prueba

### `test_e2e.py` (Principal)
Es la prueba End-to-End recomendada. 
**Qué hace:**
1. Busca PDFs en `tests/input_files/`.
2. Ejecuta `autofirma.py` invocando el binario real de AutoFirma.
3. Verifica que se generen los archivos firmados en `tests/output_files/`.

**Ejecución:**
Desde la raíz del proyecto:
```bash
python -m unittest tests/test_e2e.py
```

### `test_autofirma.py` (Unitario)
Pruebas unitarias que "mockean" (simulan) las llamadas al sistema. Útil para probar la lógica interna (cálculo de coordenadas, generación de comandos) sin necesitar AutoFirma instalado.

**Ejecución:**
```bash
python -m unittest tests/test_autofirma.py
```

## Añadir Nuevas Pruebas

1. Añade un nuevo archivo PDF a `tests/input_files/`.
2. Al ejecutar `test_e2e.py`, el script intentará firmarlo automáticamente.
3. Si necesitas lógica específica, edita `tests/test_e2e.py` para añadir aserciones adicionales.
