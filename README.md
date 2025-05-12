# PDF Signer

Herramienta para firmar documentos PDF utilizando AutoFirma (herramienta oficial del gobierno español para firmas electrónicas) con certificados PFX.

## Requisitos

- AutoFirma instalado ([Descarga oficial](https://firmaelectronica.gob.es/Home/Descargas.html))
- Certificado válido en formato PFX (.pfx) o P12 (.p12)
- Java Runtime Environment (JRE) 8 o superior (solo para la versión Java)

## Versiones Disponibles

### 1. Aplicación Java (Recomendada)

La aplicación `PDFSignerApp` proporciona tanto una interfaz gráfica como una interfaz de línea de comandos.

#### Instalación

1. Descarga la última versión desde la carpeta `releases`
2. Extrae el contenido en una carpeta de tu elección
3. Asegúrate de que Java esté instalado en tu sistema

#### Ejecución

**Interfaz Gráfica:**
- En Windows: Haz doble clic en `run.bat`
- En Mac/Linux: Ejecuta `./run.sh`

**Línea de Comandos:**
```bash
# Windows
java -cp "PDFSigner-1.0.0.jar;libs/*" PDFSignerApp [opciones]

# Mac/Linux
java -cp "PDFSigner-1.0.0.jar:libs/*" PDFSignerApp [opciones]
```

### 2. Scripts

También disponemos de scripts para diferentes sistemas operativos:

- `auto_sign_pdf.sh` (Linux/macOS)
- `auto_sign_pdf.bat` (Windows CMD)
- `auto_sign_pdf.ps1` (Windows PowerShell)

## Uso

### Opciones Comunes

| Opción | Descripción | Requerido | Valor por defecto |
|--------|-------------|-----------|-------------------|
| `-i, --input-dir` | Directorio con PDFs a firmar | Sí | - |
| `-o, --output-dir` | Directorio para PDFs firmados | Sí | - |
| `-c, --cert` | Ruta al certificado PFX | Sí | - |
| `-p, --password` | Contraseña del certificado | Sí | - |
| `-l, --location` | Ubicación para la firma | No | Madrid |
| `-r, --reason` | Razón de la firma | No | Document validation |
| `-v, --visible` | Hacer la firma visible | No | false |
| `-t, --timestamp` | Añadir sello de tiempo | No | false |

### Uso Seguro de Contraseñas

Para mayor seguridad, puedes usar la variable de entorno `PDF_CERT_PASSWORD`:

```bash
# Windows (CMD)
set PDF_CERT_PASSWORD=tu_contraseña

# Windows (PowerShell)
$Env:PDF_CERT_PASSWORD = "tu_contraseña"

# Mac/Linux
export PDF_CERT_PASSWORD='tu_contraseña'
```

### Ejemplos

**Interfaz Gráfica:**
1. Ejecuta la aplicación
2. Selecciona el directorio de entrada con los PDFs
3. Selecciona el directorio de salida
4. Selecciona el certificado PFX
5. Introduce la contraseña
6. Configura las opciones adicionales
7. Haz clic en "Firmar"

**Línea de Comandos:**
```bash
# Ejemplo básico
java -jar PDFSigner-1.0.0.jar -i ./pdfs -o ./firmados -c ./certificado.pfx -p micontraseña

# Con firma visible
java -jar PDFSigner-1.0.0.jar -i ./pdfs -o ./firmados -c ./certificado.pfx -p micontraseña -v -l "Madrid" -r "Validación de documento"
```

## Solución de Problemas

### Problemas Comunes

1. **AutoFirma no encontrado**
   - Verifica que AutoFirma esté instalado
   - Comprueba que esté en una ubicación estándar o en el PATH

2. **Error de certificado**
   - Verifica que el formato sea PFX/P12
   - Comprueba que la contraseña sea correcta

3. **Permisos denegados**
   - Ejecuta como administrador si es necesario
   - Verifica los permisos de los directorios

4. **Java no encontrado**
   - Instala Java 8 o superior
   - Verifica que JAVA_HOME esté configurado

## Soporte

Si encuentras algún problema:
1. Verifica los requisitos previos
2. Revisa la sección de solución de problemas
3. Abre un issue en el repositorio con:
   - Sistema operativo
   - Versión de Java
   - Pasos para reproducir el error
   - Logs de error (si los hay)
