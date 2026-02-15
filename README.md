# PDF Signer

Herramienta simple y multiplataforma para firmar documentos PDF masivamente utilizando AutoFirma con soporte completo para firmas visibles.

## Características

- Firma visible y configurable (Posición, texto, macros).
- Ejecución desatendida desde línea de comandos.
- Soporte para perfiles de configuración (`signature_profiles.json`).
- Variables dinámicas en el texto de firma (nombre, fecha, entidad emisora).
- Compatible con certificados PFX/P12.
- Soporte multiplataforma (macOS, Windows, Linux).

## Instalación

### Requisitos

1. **Python 3.8+** instalado
2. **[AutoFirma](https://firmaelectronica.gob.es/Home/Ciudadanos/Aplicaciones-Firma.html)** instalado
3. **Certificado digital** en formato PFX o P12

### Dependencias

```bash
pip install -r requirements.txt
```

## Uso Rápido

### Opción 1: Configuración Automática (Recomendado)

1. **Configurar variables de entorno:**

   ```bash
   # Mac/Linux
   cp .env.template .env
   
   # Windows
   copy .env.template .env
   ```

2. **Editar `.env`** con tus valores personales:

   ```bash
   # Certificado (¡IMPORTANTE! usar la extensión correcta .p12 o .pfx)
   PDF_CERT_PATH=./key/certificado.p12
   PDF_CERT_PASSWORD=tu_contraseña
   
   # Para firma visible
   PDF_VISIBLE=true
   PDF_SIG_RECT_X=400
   PDF_SIG_RECT_Y=50
   PDF_SIG_WIDTH=150
   PDF_SIG_HEIGHT=50
   ```

3. **Ejecutar:**

   ```bash
   # Mac/Linux
   ./run.sh
   
   # Windows PowerShell
   .\run.ps1
   ```

### Opción 2: Ejecución Manual

```bash
python autofirma.py -i ./pdfs -o ./signed -c cert.p12 -p password -v
```

### Argumentos Principales

| Argumento | Descripción |
|-----------|-------------|
| `-i` | Directorio de entrada con PDFs |
| `-o` | Directorio de salida para PDFs firmados |
| `-c` | Ruta al certificado (.pfx o .p12) |
| `-p` | Contraseña del certificado |
| `-v` | Habilitar firma visible |
| `-l` | Ubicación de la firma |
| `-r` | Razón de la firma |
| `-t` | Añadir timestamp |

## Configuración de Firma Visible

### Coordenadas

Las coordenadas en PDF se miden desde la **esquina inferior izquierda** en puntos (72 puntos = 1 pulgada ≈ 2.54 cm):

```bash
# Ejemplo: Firma en esquina inferior derecha de página A4
PDF_SIG_RECT_X=400      # Desde la izquierda
PDF_SIG_RECT_Y=50       # Desde abajo
PDF_SIG_WIDTH=150       # Ancho ~5.3 cm
PDF_SIG_HEIGHT=50       # Alto ~1.8 cm
```

**Tamaños de página comunes (puntos):**
- A4: 595 x 842
- Letter: 612 x 792

### Variables Disponibles en el Texto

El texto de la firma (`PDF_SIG_TEXT`) soporta variables que se reemplazan automáticamente:

| Variable | Descripción |
|----------|-------------|
| `$$SUBJECTCN$$` | Nombre del firmante |
| `$$ISSUERCN$$` | Entidad emisora del certificado |
| `$$SIGNDATE=FORMATO$$` | Fecha de firma (formato Java) |
| `$$LOCATION$$` | Ubicación de la firma |
| `$$REASON$$` | Razón de la firma |

**Ejemplo:**
```bash
PDF_SIG_TEXT="Firmado por $$SUBJECTCN$$ el día $$SIGNDATE=dd/MM/yyyy$$ con certificado emitido por $$ISSUERCN$$"
```

### Perfiles de Firma

Puedes definir perfiles predefinidos en `signature_profiles.json`:

```json
{
  "default": {
    "page": 1,
    "rect": {
      "x": 400,
      "y": 50,
      "width": 150,
      "height": 50
    },
    "text": "Firmado por $$SUBJECTCN$$ el día $$SIGNDATE=dd/MM/yyyy$$"
  }
}
```

Uso con perfil:
```bash
python autofirma.py -i ./pdfs -o ./signed -c cert.p12 -p password -v -P default
```

## Documentación Adicional

- **[Guía de Desarrollo](docs/DEVELOPMENT.md)** - Configuración avanzada y desarrollo
- **[Guía de Inicio Rápido](docs/QUICKSTART.md)** - Tutorial paso a paso
- **[Pruebas](tests/README.md)** - Cómo ejecutar tests

## Solución de Problemas

### "La firma no aparece visible"

1. Verifica que `PDF_VISIBLE=true` o usas `-v`
2. Comprueba que las coordenadas no están fuera de la página
3. Asegúrate de que el tamaño (width/height) sea suficiente (> 50 puntos)

### "Error: No se hay ninguna entrada en el almacen con el alias"

El script detecta automáticamente el alias del certificado. Si falla:
```bash
java -jar /Applications/AutoFirma.app/Contents/Resources/JAR/AutoFirma.jar listaliases -store "pkcs12:/ruta/cert.p12" -password "password"
```

### "Las variables no se reemplazan"

Asegúrate de usar el formato correcto con doble `$`:
- ✅ Correcto: `$$SUBJECTCN$$`
- ❌ Incorrecto: `$SUBJECTCN$`

## Licencia

[LICENSE](LICENSE)
