# Guía de Desarrollo de PDF Signer

Este documento detalla la configuración avanzada, estructura y flujo de trabajo para desarrolladores que deseen contribuir o modificar el script `autofirma.py`.

## Requisitos de Desarrollo

- **Python 3.8+**
- **AutoFirma**: Debe estar instalado en el sistema.
- **Dependencias**:
  ```bash
  pip install -r requirements.txt
  ```

## Estructura del Proyecto

```
pdf-signature/
├── autofirma.py              # Script principal (Wrapper de AutoFirma)
├── signature_profiles.json   # Perfiles de firma predefinidos
├── .env                      # Variables de entorno (no versionar)
├── .env.template             # Plantilla de variables de entorno
├── run.sh                    # Script de ejecución (Mac/Linux)
├── run.ps1                   # Script de ejecución (Windows)
├── requirements.txt          # Dependencias Python
├── README.md                 # Documentación principal
├── docs/
│   ├── DEVELOPMENT.md        # Esta guía
│   └── QUICKSTART.md         # Guía rápida de inicio
├── tests/
│   ├── input_files/          # PDFs de prueba
│   ├── output_files/         # Resultados de pruebas
│   └── README.md             # Guía de pruebas
└── key/                      # Directorio para certificados
```

## Arquitectura

### Flujo de Firma Visible

1. **Generación de Configuración**: El script genera un string de configuración con los parámetros de firma visible
2. **Escapado para Shell**: La configuración se escapa usando comillas simples para evitar que el shell interprete las variables `$$`
3. **Ejecución vía Shell**: Se usa `shell=True` en subprocess para que el shell procese los saltos de línea (`\n`) correctamente
4. **Reemplazo de Variables**: AutoFirma reemplaza las variables (`$$SUBJECTCN$$`, `$$SIGNDATE$$`, etc.) con los valores reales del certificado

### Parámetros de Configuración (AutoFirma)

| Parámetro | Descripción | Ejemplo |
|-----------|-------------|---------|
| `layer2Text` | Texto de la firma | `Firmado por $$SUBJECTCN$$` |
| `signaturePositionOnPageLowerLeftX` | Coordenada X inferior izquierda | `400` |
| `signaturePositionOnPageLowerLeftY` | Coordenada Y inferior izquierda | `50` |
| `signaturePositionOnPageUpperRightX` | Coordenada X superior derecha | `550` |
| `signaturePositionOnPageUpperRightY` | Coordenada Y superior derecha | `100` |
| `signaturePage` | Página de firma (1=primera, -1=última) | `1` |
| `signatureRenderingMode` | Modo de renderizado (1=texto+gráfico) | `1` |
| `layer2FontColor` | Color del texto | `black` |
| `signatureProductionCity` | Ciudad | `Madrid` |
| `signatureReason` | Razón de firma | `Contrato` |
| `applyTimestamp` | Añadir sello de tiempo | `true` |

### Variables Dinámicas

AutoFirma reemplaza automáticamente estas variables en el texto:

- `$$SUBJECTCN$$` - Nombre del firmante (CN del sujeto)
- `$$ISSUERCN$$` - Entidad emisora (CN del emisor)
- `$$SIGNDATE=FORMATO$$` - Fecha de firma con formato Java SimpleDateFormat
- `$$LOCATION$$` - Ubicación configurada
- `$$REASON$$` - Razón configurada

**Formatos de fecha comunes:**
- `dd/MM/yyyy` → 15/02/2026
- `yyyy-MM-dd HH:mm:ss` → 2026-02-15 14:30:00
- `dd 'de' MMMM 'de' yyyy` → 15 de febrero de 2026

## Perfiles de Firma

### Estructura del JSON

```json
{
  "nombre_perfil": {
    "page": 1,
    "rect": {
      "x": 400,
      "y": 50,
      "width": 150,
      "height": 50
    },
    "text": "Texto de la firma con $$VARIABLES$$",
    "color": "black",
    "image_path": "./assets/rubrica.jpg"
  }
}
```

### Perfiles Incluidos

- **default**: Esquina inferior izquierda, texto básico
- **bottom_right**: Esquina inferior derecha, texto extendido
- **top_right**: Esquina superior derecha, texto azul
- **last_page**: Última página del documento
- **with_image**: Incluye imagen de rúbrica

## Configuración

### Variables de Entorno (.env)

Ver `.env.template` para la lista completa. Las más importantes:

```bash
# Certificado (¡Verificar extensión!)
PDF_CERT_PATH=./key/certificado.p12  # o .pfx

# Firma visible
PDF_VISIBLE=true
PDF_SIG_RECT_X=400
PDF_SIG_RECT_Y=50
PDF_SIG_WIDTH=150
PDF_SIG_HEIGHT=50
PDF_SIG_TEXT="Firmado por $$SUBJECTCN$$"

# Metadata
PDF_LOCATION=Madrid
PDF_REASON=Firma de contrato
PDF_TIMESTAMP=false
```

### Detección de Alias

El script detecta automáticamente el alias del certificado usando:

```bash
AutoFirmaCommandLine listaliases -store "pkcs12:/ruta/cert.p12" -password "password"
```

Si hay múltiples alias, usa el primero encontrado.

## Depuración

### Ver Comando Completo

Habilitar logging DEBUG en el script:

```python
logging.basicConfig(
    level=logging.DEBUG,  # Cambiar de INFO a DEBUG
    ...
)
```

### Probar Comando Manualmente

```bash
java -jar /Applications/AutoFirma.app/Contents/Resources/JAR/AutoFirma.jar \
  sign \
  -i "documento.pdf" \
  -o "firmado.pdf" \
  -store "pkcs12:certificado.p12" \
  -password "password" \
  -alias "imported private key" \
  -format pades \
  -config "layer2Text=Firmado por \$\$SUBJECTCN\$\$\nsignaturePositionOnPageLowerLeftX=100\nsignaturePage=1"
```

### Problemas Comunes

#### "Firma invisible" en Adobe Acrobat

1. Verificar que las coordenadas están dentro de la página
2. Comprobar que el tamaño (width/height) es suficiente
3. Revisar logs para errores de AutoFirma

#### Variables no se reemplazan

Las variables deben usar doble `$`:
- ✅ `$$SUBJECTCN$$`
- ❌ `$SUBJECTCN$`

#### Error de alias

Verificar alias disponibles:
```bash
java -jar AutoFirma.jar listaliases -store "pkcs12:cert.p12" -password "pass"
```

## Pruebas

### Ejecución de Tests

```bash
python -m unittest tests/test_e2e.py
```

### Verificación Manual

1. Firmar un PDF de prueba
2. Abrir en Adobe Acrobat Reader
3. Verificar panel de firmas muestra "Signature1 (firma visible)"
4. Confirmar que las variables se reemplazaron correctamente

## Flujo de Trabajo Git

1. Realizar cambios en `autofirma.py`
2. Probar con PDFs de ejemplo en `tests/input_files/`
3. Verificar visualmente el resultado en `tests/output_files/`
4. Actualizar documentación si es necesario
5. Commit con mensaje descriptivo

## Notas Técnicas

### Por qué shell=True

El parámetro `-config` de AutoFirma espera una cadena con saltos de línea literales (`\n`). Al usar `shell=True`, el shell procesa estos caracteres antes de pasarlos a AutoFirma, lo que es necesario para que el formato sea correcto.

### Por qué comillas simples

Las comillas simples (`'...'`) en el shell previenen la expansión de variables (`$$SUBJECTCN$$` → `$SUBJECTCN$$`), permitiendo que AutoFirma las procese correctamente.

## Referencias

- [AutoFirma - Portal de Firma Electrónica](https://firmaelectronica.gob.es/)
- [Java SimpleDateFormat](https://docs.oracle.com/javase/8/docs/api/java/text/SimpleDateFormat.html)
- [PDF Coordinate System](https://www.prepressure.com/pdf/basics/page-boxes)
