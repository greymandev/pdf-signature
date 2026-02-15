# Guía de Inicio Rápido - PDF Signer

Esta guía te ayudará a configurar y ejecutar PDF Signer en menos de 5 minutos.

## Requisitos Previos

1. **Python 3.8+** instalado
2. **AutoFirma** instalado ([Descargar aquí](https://firmaelectronica.gob.es/Home/Ciudadanos/Aplicaciones-Firma.html))
3. **Certificado digital** en formato PFX o P12

## Instalación en 3 Pasos

### Paso 1: Instalar Dependencias

```bash
pip install -r requirements.txt
```

### Paso 2: Configurar Variables de Entorno

**Mac/Linux:**
```bash
cp .env.template .env
```

**Windows:**
```cmd
copy .env.template .env
```

Edita el archivo `.env` con tu editor favorito:

```bash
# Directorios
PDF_INPUT_DIR=./tests/input_files     # PDFs a firmar
PDF_OUTPUT_DIR=./tests/output_files   # PDFs firmados

# Certificado (¡IMPORTANTE! Usa la extensión correcta: .p12 o .pfx)
PDF_CERT_PATH=./key/certificado.p12
PDF_CERT_PASSWORD=tu_contraseña

# Firma visible
PDF_VISIBLE=true

# Coordenadas (esquina inferior derecha de página A4)
PDF_SIG_RECT_X=400
PDF_SIG_RECT_Y=50
PDF_SIG_WIDTH=150
PDF_SIG_HEIGHT=50

# Texto de la firma
PDF_SIG_TEXT="Firmado por $$SUBJECTCN$$ el día $$SIGNDATE=dd/MM/yyyy$$ con certificado emitido por $$ISSUERCN$$"
```

### Paso 3: Ejecutar

**Mac/Linux:**
```bash
./run.sh
```

**Windows PowerShell:**
```powershell
.\run.ps1
```

¡Listo! Tus PDFs firmados estarán en la carpeta configurada.

---

## Uso Avanzado

### Coordenadas de Firma

Las coordenadas se miden desde la **esquina inferior izquierda** en puntos:

```
Página A4: 595 x 842 puntos (72 puntos = 1 pulgada)

Esquina inferior izquierda:  x=50,  y=50
Esquina inferior derecha:    x=400, y=50
Esquina superior izquierda:  x=50,  y=750
Esquina superior derecha:    x=400, y=750
```

**Tamaño recomendado:**
- Width: 150-200 puntos (~5-7 cm)
- Height: 50-80 puntos (~1.8-2.8 cm)

### Variables en el Texto

AutoFirma reemplaza automáticamente estas variables:

| Variable | Resultado |
|----------|-----------|
| `$$SUBJECTCN$$` | Nombre del firmante |
| `$$ISSUERCN$$` | Entidad certificadora |
| `$$SIGNDATE=dd/MM/yyyy$$` | Fecha: 15/02/2026 |
| `$$SIGNDATE=yyyy-MM-dd$$` | Fecha: 2026-02-15 |
| `$$LOCATION$$` | Ubicación configurada |
| `$$REASON$$` | Razón configurada |

**Ejemplo de texto completo:**
```bash
PDF_SIG_TEXT="Documento firmado digitalmente por:
$$SUBJECTCN$$
Fecha: $$SIGNDATE=dd/MM/yyyy HH:mm$$
Entidad: $$ISSUERCN$$"
```



### Ejecución Manual (sin .env)

```bash
python autofirma.py \
  -i ./tests/input_files \
  -o ./tests/output_files \
  -c ./key/certificado.p12 \
  -p "tu_contraseña" \
  -v \
  --sig-x 400 \
  --sig-y 50 \
  --sig-width 150 \
  --sig-height 50
```

---

## Solución de Problemas

### "La firma no se ve"

1. Verifica `PDF_VISIBLE=true` en `.env` o usa `-v`
2. Comprueba que las coordenadas están dentro de la página
3. Asegúrate de que width/height sean > 50 puntos

### "Error: No hay ninguna entrada en el almacén con el alias"

El script detecta automáticamente el alias. Si falla, verifica:

```bash
# Mac
java -jar /Applications/AutoFirma.app/Contents/Resources/JAR/AutoFirma.jar listaliases -store "pkcs12:/ruta/cert.p12" -password "password"

# Windows
"C:\Program Files\AutoFirma\AutoFirmaCommandLine.exe" listaliases -store "pkcs12:C:\ruta\cert.p12" -password "password"
```

### "Variables no se reemplazan"

Usa doble `$`:
- ✅ Correcto: `$$SUBJECTCN$$`
- ❌ Incorrecto: `$SUBJECTCN$`

### "Permission denied" (Mac/Linux)

```bash
chmod +x run.sh
```

### "Execution policy" (Windows PowerShell)

```powershell
# Ejecuta como Administrador
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

---

## Verificación

Para comprobar que la firma es visible:

1. Abre el PDF firmado en **Adobe Acrobat Reader**
2. Ve al panel de firmas (View > Show/Hide > Navigation Panes > Signatures)
3. Debería mostrar: "Signature1 (firma visible)"
4. Haz clic en la firma para ver los detalles

---

## Automatización

### Cron Job (Linux/Mac)

```bash
# Editar crontab
crontab -e

# Ejecutar todos los días a las 9:00 AM
0 9 * * * cd /ruta/a/pdf-signature && ./run.sh
```

### Programador de Tareas (Windows)

1. Abrir Programador de Tareas
2. Crear tarea básica
3. Configurar acción: Iniciar programa
4. Programa: `powershell.exe`
5. Argumentos: `-File "C:\ruta\pdf-signature\run.ps1"`

---

## Documentación Adicional

- [Guía de Desarrollo](DEVELOPMENT.md) - Configuración avanzada
- [README principal](../README.md) - Documentación completa
- [Pruebas](../tests/README.md) - Cómo ejecutar tests
