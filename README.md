# AutoFirma PDF Signing Tools

Este proyecto contiene herramientas para automatizar la firma de archivos PDF utilizando AutoFirma (la herramienta oficial del gobierno español para firmas electrónicas) con un certificado PFX.

## Requisitos

- AutoFirma instalado en el sistema ([Descarga oficial de AutoFirma](https://firmaelectronica.gob.es/Home/Descargas.html))
- Un certificado válido en formato PFX (.pfx) o P12 (.p12)
- Archivos PDF para firmar

## Versiones Disponibles

### 1. Script Bash (para Linux/macOS)

El script `auto_sign_pdf.sh` está diseñado para ser ejecutado en sistemas Unix/Linux/macOS.

### 2. Script Batch (para Windows)

El script `auto_sign_pdf.bat` está diseñado para ser ejecutado en la línea de comandos de Windows (CMD).

### 3. Script PowerShell (para Windows)

El script `auto_sign_pdf.ps1` utiliza PowerShell para un mayor control y funcionalidad en sistemas Windows.

### 4. Aplicación Java

La aplicación `PDFSignerApp.java` proporciona tanto una interfaz gráfica como una interfaz de línea de comandos para la firma de documentos PDF. [Ver documentación detallada](README-PDFSignerApp.MD).

## Uso

### Script Bash (Linux/macOS)

```bash
./auto_sign_pdf.sh -i <directorio_entrada> -o <directorio_salida> -c <archivo_certificado> -p <contraseña> [opciones]
```

Ejemplo:
```bash
./auto_sign_pdf.sh -i ./pdfs -o ./firmados -c ./certificado.pfx -p micontraseña -l "Madrid" -r "Validación de documento" -v
```

### Script Batch (Windows CMD)

```
auto_sign_pdf.bat -i <directorio_entrada> -o <directorio_salida> -c <archivo_certificado> -p <contraseña> [opciones]
```

Ejemplo:
```
auto_sign_pdf.bat -i .\pdfs -o .\firmados -c .\certificado.pfx -p micontraseña -l "Madrid" -r "Validación de documento" -v
```

### Script PowerShell (Windows)

```powershell
.\auto_sign_pdf.ps1 -InputDir <directorio_entrada> -OutputDir <directorio_salida> -CertFile <archivo_certificado> -Password <contraseña> [opciones]
```

Ejemplo:
```powershell
.\auto_sign_pdf.ps1 -InputDir .\pdfs -OutputDir .\firmados -CertFile .\certificado.pfx -Password micontraseña -Location "Madrid" -Reason "Validación de documento" -Visible
```

### Aplicación Java

Modo GUI (interfaz gráfica):
```bash
java -jar PDFSignerApp.jar
```

Modo línea de comandos:
```bash
java -jar PDFSignerApp.jar -i <directorio_entrada> -o <directorio_salida> -c <archivo_certificado> -p <contraseña> [opciones]
```

## Opciones

Todas las herramientas aceptan las siguientes opciones:

| Opción (Bash/Batch) | Opción (PowerShell) | Opción (Java) | Descripción | Requerido | Valor por defecto |
|---------------------|---------------------|---------------|-------------|-----------|-------------------|
| `-i, --input-dir` | `-InputDir` | `-i, --input-dir` | Directorio de entrada con archivos PDF | Sí | - |
| `-o, --output-dir` | `-OutputDir` | `-o, --output-dir` | Directorio de salida para PDFs firmados | Sí | - |
| `-c, --cert` | `-CertFile` | `-c, --cert` | Ruta al archivo de certificado PFX | Sí | - |
| `-p, --password` | `-Password` | `-p, --password` | Contraseña del certificado PFX | Sí | - |
| `-l, --location` | `-Location` | `-l, --location` | Ubicación para la firma | No | Madrid |
| `-r, --reason` | `-Reason` | `-r, --reason` | Razón de la firma | No | Document validation |
| `-v, --visible` | `-Visible` | `-v, --visible` | Hacer la firma visible | No | false |
| `-t, --timestamp` | `-Timestamp` | `-t, --timestamp` | Añadir sello de tiempo a la firma | No | false |
| `-h, --help` | `-?` | `-h, --help` | Mostrar mensaje de ayuda | No | - |

## Configuración de Firma Visible

Cuando se utiliza la opción para hacer la firma visible (`-v`/`--visible`/`-Visible`), las herramientas crean automáticamente un archivo de configuración temporal con los siguientes parámetros por defecto:

- Posición en la página: X=50, Y=50
- Tamaño: Ancho=200, Alto=100
- Página: 1
- Tamaño de fuente: 9
- Color de fuente: negro
- Texto: "Firmado por [NAME] el día [DATE] Certificado [ISSUER]"

## Características

- Procesamiento por lotes de múltiples archivos PDF
- Integración nativa con AutoFirma
- Soporte para firmas visibles e invisibles
- Registro detallado del proceso
- Sellos de tiempo opcional
- Personalización de ubicación y razón de firma
- Interfaz gráfica (versión Java)
- Compatible con Windows, macOS y Linux

## Solución de Problemas

Si encuentra problemas al ejecutar las herramientas, verifique lo siguiente:

1. AutoFirma está correctamente instalado y accesible
2. El certificado PFX es válido y la contraseña es correcta
3. Tiene permisos de lectura/escritura en los directorios de entrada/salida
4. Los archivos PDF no están dañados o protegidos con contraseña

### Soluciones comunes:

- **AutoFirma no encontrado**: Asegúrese de que AutoFirma esté instalado y en una ubicación estándar o en su PATH
- **Error de certificado**: Verifique que el formato del certificado sea PFX/P12 y que la contraseña sea correcta
- **Permisos denegados**: Ejecute los scripts con privilegios de administrador si es necesario

## Notas para Desarrolladores

Para modificar las herramientas o contribuir al proyecto:

1. Clone el repositorio
2. Realice sus cambios
3. Pruebe los cambios con diferentes configuraciones
4. Envíe un pull request con una descripción clara de sus modificaciones

## Documentación Adicional

- [Documentación detallada de PDFSignerApp](README-PDFSignerApp.MD)
- [Guía de empaquetado para diferentes plataformas](README-PACKAGING.md)
- [Sitio oficial de AutoFirma](https://firmaelectronica.gob.es/Home/Ciudadanos/Aplicaciones-Firma.html)

# PDF Signer Test Suite

Este proyecto contiene un conjunto de pruebas unitarias para validar la aplicación PDFSignerApp, que automatiza la firma de documentos PDF con AutoFirma.

## Estructura de las pruebas

Las pruebas unitarias verifican los siguientes aspectos de la aplicación:

1. **Procesamiento de argumentos**: Verifica que los argumentos de línea de comandos se procesen correctamente.
2. **Validación de rutas**: Comprueba que la validación de rutas de archivos y directorios funcione adecuadamente.
3. **Generación de archivos de configuración**: Verifica la correcta creación de archivos de configuración para firmas visibles.
4. **Detección de AutoFirma**: Comprueba que la aplicación pueda detectar el ejecutable de AutoFirma.
5. **Simulación de integración**: Simula el proceso de firma sin ejecutar realmente AutoFirma.

## Requisitos

- Java 8 o superior
- JUnit 4.13.2 (incluido a través de Gradle)
- Gradle (opcional, se puede usar el wrapper incluido)

## Cómo ejecutar las pruebas

### En Windows

1. Ejecuta el script `run_tests.bat` haciendo doble clic en él o desde la línea de comandos:
   ```
   run_tests.bat
   ```

### En Linux/macOS

1. Asegúrate de que el script tenga permisos de ejecución:
   ```
   chmod +x run_tests.sh
   ```

2. Ejecuta el script:
   ```
   ./run_tests.sh
   ```

### Manual con Gradle

Si prefieres ejecutar las pruebas manualmente:

```
gradle clean test
```

O con el wrapper:

```
./gradlew clean test    # En Linux/macOS
gradlew.bat clean test  # En Windows
```

## Resultados de las pruebas

Los resultados detallados de las pruebas se pueden encontrar en `build/reports/tests/test/index.html` después de ejecutar las pruebas.

## Notas importantes

- Estas pruebas se ejecutan sin necesidad de tener AutoFirma instalado, ya que utilizan reflection y simulación para probar la mayor parte de la funcionalidad.
- El test `testFindAutoFirmaExecutable` podría fallar si AutoFirma no está instalado en el sistema, lo cual es esperado.
- Para una validación completa en un entorno de producción, se recomienda complementar estas pruebas unitarias con pruebas de integración utilizando una instalación real de AutoFirma.

# PDF-Signature

Una aplicación en Java para firmar documentos PDF usando certificados digitales a través de AutoFirma.

## Uso seguro de contraseñas

Para mejorar la seguridad, esta aplicación permite varias formas de proporcionar la contraseña del certificado sin exponerla en la línea de comandos:

### Uso de variables de entorno (Método recomendado)

La forma más segura y recomendada es usar la variable de entorno `PDF_CERT_PASSWORD`. La aplicación automáticamente detectará esta variable cuando esté disponible.

#### En Windows (CMD)

```cmd
:: Establecer la variable de entorno
set PDF_CERT_PASSWORD=tu_contraseña_segura

:: Ejecutar el script sin necesidad de especificar la contraseña
auto_sign_pdf.bat -i ./input_pdfs -o ./signed_pdfs -c ./certificate.pfx
```

#### En Windows (PowerShell)

```powershell
# Establecer la variable de entorno
$Env:PDF_CERT_PASSWORD = "tu_contraseña_segura"

# Ejecutar el script sin necesidad de especificar la contraseña
.\auto_sign_pdf.ps1 -InputDir ./input_pdfs -OutputDir ./signed_pdfs -CertFile ./certificate.pfx
```

#### En macOS y Linux

```bash
# Establecer la variable de entorno
export PDF_CERT_PASSWORD='tu_contraseña_segura'

# Ejecutar el script sin necesidad de especificar la contraseña
./auto_sign_pdf.sh -i ./input_pdfs -o ./signed_pdfs -c ./certificate.pfx
```

Para evitar que la contraseña quede registrada en el historial de comandos:

```bash
# Un espacio antes del comando evita que se guarde en el historial en la mayoría de configuraciones
 export PDF_CERT_PASSWORD='tu_contraseña_segura'
```

#### Ejecutar la aplicación Java

```bash
# Establecer la variable de entorno
export PDF_CERT_PASSWORD='tu_contraseña_segura'

# Ejecutar la aplicación Java sin especificar la contraseña
java -jar pdf-signer.jar --input-dir ./input_pdfs --output-dir ./signed_pdfs --cert ./certificate.pfx
```

### Métodos alternativos para proporcionar la contraseña

La aplicación también soporta estos métodos de autenticación:

1. **Solicitud interactiva de contraseña**:
   ```bash
   ./auto_sign_pdf.sh -i ./input_pdfs -o ./signed_pdfs -c ./certificate.pfx --prompt-password
   ```

2. **Archivo de contraseña**:
   ```bash
   # Crear un archivo con permisos restrictivos
   echo 'tu_contraseña_segura' > password.txt
   chmod 600 password.txt

   # Usar el archivo para la autenticación
   ./auto_sign_pdf.sh -i ./input_pdfs -o ./signed_pdfs -c ./certificate.pfx --password-file password.txt
   ```

### Integración con gestores de credenciales del sistema

#### En Linux (usando secretarios de GNOME)

```bash
# Guardar la contraseña en el llavero (solo una vez)
secret-tool store --label="PDF Signer Certificate" application pdf-signer certificate mycert

# Recuperar y usar para la autenticación
PASSWORD=$(secret-tool lookup application pdf-signer certificate mycert)
export PDF_CERT_PASSWORD="$PASSWORD"
./auto_sign_pdf.sh -i ./input_pdfs -o ./signed_pdfs -c ./certificate.pfx
```

#### En macOS (usando Keychain)

```bash
# Guardar la contraseña en Keychain (solo una vez)
security add-generic-password -a $USER -s "pdf-signer-cert" -w "tu_contraseña_segura"

# Recuperar y usar para la autenticación
PASSWORD=$(security find-generic-password -a $USER -s "pdf-signer-cert" -w)
export PDF_CERT_PASSWORD="$PASSWORD"
./auto_sign_pdf.sh -i ./input_pdfs -o ./signed_pdfs -c ./certificate.pfx
```

#### En Windows (usando Credential Manager)

```powershell
# Guardar la contraseña en Credential Manager (solo una vez)
cmdkey /generic:PDF-Signer /user:CertificatePassword /pass:"tu_contraseña_segura"

# Recuperar y usar la contraseña guardada (método simplificado)
$Password = (cmdkey /generic:PDF-Signer | Where-Object {$_ -like "*contraseña*"}) -replace ".*: ", ""
$Env:PDF_CERT_PASSWORD = $Password
.\auto_sign_pdf.ps1 -InputDir ./input_pdfs -OutputDir ./signed_pdfs -CertFile ./certificate.pfx
```

## Recomendaciones de seguridad

1. No pases contraseñas directamente como argumentos en la línea de comandos (visible en `ps` y queda en el historial)
2. Limpia las variables de entorno cuando termines:
   ```bash
   unset PDF_CERT_PASSWORD  # En Linux/macOS
   ```
   ```powershell
   $Env:PDF_CERT_PASSWORD = $null  # En PowerShell
   ```
3. Usa gestores de credenciales del sistema para mayor seguridad
4. Si usas archivos de contraseña, aplica permisos restrictivos y elimínalos después de usarlos
