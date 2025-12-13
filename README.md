# PDF Signer

Herramienta simple y multiplataforma para firmar documentos PDF masivamente utilizando AutoFirma.

## Características
- Firma visible y configurable (Posición, texto, macros).
- Ejecución desatendida desde línea de comandos.
- Soporte para perfiles de configuración (`signature_profiles.json`).

## Instalación

1. **Requisitos**: Python 3.8+ y [AutoFirma](https://firmaelectronica.gob.es/Home/Ciudadanos/Aplicaciones-Firma.html) instalado.
2. **Dependencias**:
   ```bash
   pip install -r requirements.txt
   ```

## Uso Rápido

### Opción 1: Ejecución Automática (Recomendado)

1. **Configurar variables de entorno:**
   ```bash
   # Mac/Linux
   cp .env.template .env
   
   # Windows
   copy .env.template .env
   ```

2. **Editar `.env`** con tus valores personales (directorios, certificado, contraseña, etc.)

3. **Ejecutar el script:**
   ```bash
   # Mac/Linux
   ./run.sh
   
   # Windows PowerShell
   .\run.ps1
   ```

### Opción 2: Ejecución Manual

```bash
python autofirma.py -i ./pdfs -o ./signed -c cert.pfx -p 123456 -v
```

### Argumentos Principales (Solo para Ejecución Manual)
- `-i`: Directorio de entrada.
- `-o`: Directorio de salida.
- `-c`: Certificado (.pfx).
- `-p`: Contraseña (o usar variable `PDF_CERT_PASSWORD`).
- `-v`: Firma visible.
- `-P` / `--profile`: Perfil de firma (ver abajo).

## Configuración Avanzada

Para detalles sobre cómo configurar **perfiles de firma visible** (coordenadas, textos personalizados) y para la **guía de desarrollo**, consulta:

👉 [Guía de Desarrollo y Configuración Avanzada](docs/DEVELOPMENT.md)

👉 [Guía de Inicio Rápido](docs/QUICKSTART.md)

## Pruebas

Para ejecutar los tests, consulta:

👉 [Guía de Pruebas (tests/README.md)](tests/README.md)
