# PDF Signer

Herramienta simple y multiplataforma para firmar documentos PDF masivamente utilizando AutoFirma y certificados PFX/P12.

## Características
- Firma PAdES masiva.
- **Posicionamiento Inteligente**: Cuando se activa firma visible, detecta automáticamente la última página y busca un hueco en blanco (Derecha o Izquierda) para no tapar texto.
- Ejecución Cross-platform (Windows, macOS, Linux).
- Soporte para `.env`.

## Requisitos

- **Python 3** instalado.
- Librerías: `pip install -r requirements.txt` (incluye `python-dotenv` y `pypdf`).
- **AutoFirma** instalado.
- Certificado válido en formato `.pfx` o `.p12`.

## Instalación

1. Clona este repositorio o descarga `autofirma.py`.
2. Asegúrate de tener Python 3 instalado.

## Uso

Ejecuta el script `autofirma.py` con los argumentos necesarios:

```bash
python3 autofirma.py -i <directorio_entrada> -o <directorio_salida> -c <certificado.pfx> -p <contraseña>
```

### Opciones

| Opción | Descripción | Requerido |
|--------|-------------|-----------|
| `-i, --input-dir` | Directorio con los PDFs a firmar | Sí |
| `-o, --output-dir` | Directorio donde se guardarán los PDFs firmados | Sí |
| `-c, --cert` | Ruta al certificado (.pfx o .p12) | Sí |
| `-p, --password` | Contraseña del certificado | Sí* |
| `-l, --location` | Lugar de la firma (Opcional) | No |
| `-r, --reason` | Razón de la firma (Opcional) | No |
| `-v, --visible` | Hacer la firma visible en el PDF | No |
| `-t, --timestamp` | Añadir sello de tiempo (Timestamp) | No |
| `-a, --alias` | Alias del certificado (Si se omite, se detecta auto.) | No |

\* *La contraseña también puede pasarse mediante la variable de entorno `PDF_CERT_PASSWORD` en un archivo `.env` o en el sistema.*


### Ejemplos

**Básico:**
```bash
python3 autofirma.py -i ./docs -o ./signed -c cert.pfx -p 123456
```

**Con firma visible y timestamp:**
```bash
python3 autofirma.py -i ./docs -o ./signed -c cert.pfx -p 123456 -v -t
```

**Usando variable de entorno (Más seguro):**
```bash
export PDF_CERT_PASSWORD="mi_contraseña_secreta"
python3 autofirma.py -i ./docs -o ./signed -c cert.pfx
```

## Solución de Problemas

- **AutoFirma no encontrado**: Asegúrate de que AutoFirma esté instalado en la ubicación por defecto o que el ejecutable esté en tu PATH.
- **Error de permisos**: Asegúrate de tener permisos de lectura/escritura en los directorios de entrada y salida.
