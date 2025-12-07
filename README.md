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

```bash
python autofirma.py -i ./docs -o ./signed -c cert.pfx -p 123456 -v
```

### Argumentos Principales
- `-i`: Directorio de entrada.
- `-o`: Directorio de salida.
- `-c`: Certificado (.pfx).
- `-p`: Contraseña (o usar variable `PDF_CERT_PASSWORD`).
- `-v`: Firma visible.
- `-P` / `--profile`: Perfil de firma (ver abajo).

## Configuración Avanzada

Para detalles sobre cómo configurar **perfiles de firma visible** (coordenadas, textos personalizados) y para la **guía de desarrollo**, consulta:

👉 [Guía de Desarrollo y Configuración Avanzada (DEVELOPMENT.md)](DEVELOPMENT.md)

## Pruebas

Para ejecutar los tests, consulta:

👉 [Guía de Pruebas (tests/README.md)](tests/README.md)
