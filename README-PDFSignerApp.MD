# PDFSignerApp - Explicación Detallada

Este documento explica en detalle el funcionamiento del código de la aplicación Java para firmar documentos PDF utilizando AutoFirma.

## Estructura general

La aplicación tiene dos modos de funcionamiento:
1. **Modo GUI**: interfaz gráfica para usuarios finales
2. **Modo línea de comandos**: para automatización

## Componentes principales

### Valores por defecto
```java
private static final String DEFAULT_LOCATION = "Madrid";
private static final String DEFAULT_REASON = "Document validation";
private static final boolean DEFAULT_VISIBLE = false;
private static final boolean DEFAULT_TIMESTAMP = false;
```

Estos valores se utilizan cuando el usuario no especifica estas opciones.

### Configuración de apariencia de firma
```java
private static final int SIG_X = 50;
private static final int SIG_Y = 50;
private static final int SIG_WIDTH = 200;
private static final int SIG_HEIGHT = 100;
private static final int SIG_PAGE = 1;
private static final int SIG_FONT_SIZE = 9;
private static final String SIG_FONT_COLOR = "black";
private static final String SIG_TEXT = "Firmado por [NAME] el día [DATE] Certificado [ISSUER]";
```

Estas constantes definen cómo aparecerá la firma visible en el PDF: posición, tamaño, página, fuente y texto.

### Método main

El punto de entrada de la aplicación que:
- Detecta si se ejecuta en línea de comandos o interfaz gráfica
- Para interfaz gráfica, utiliza Swing para crear la UI
- Para línea de comandos, analiza los parámetros y ejecuta la firma

### Parseo de argumentos

El método `parseArgs()` procesa los argumentos de línea de comandos:
- `-i/--input-dir`: directorio con PDFs a firmar
- `-o/--output-dir`: directorio para PDFs firmados
- `-c/--cert`: archivo de certificado (.pfx o .p12)
- `-p/--password`: contraseña del certificado
- `-l/--location`: ubicación para la firma
- `-r/--reason`: motivo de la firma
- `-v/--visible`: hace que la firma sea visible
- `-t/--timestamp`: añade marca de tiempo

También valida que los parámetros requeridos estén presentes y que las rutas especificadas sean válidas.

### Interfaz gráfica

El método `showGUI()` construye una interfaz con:
- Campos para todas las opciones del programa
- Botones para seleccionar directorios y archivos
- Área de estado para ver el progreso
- Ejecución asíncrona para no bloquear la interfaz durante el procesamiento

La interfaz utiliza GridBagLayout para organizar los componentes de manera ordenada y proporciona feedback visual durante el proceso.

### Procesamiento de PDFs

El método `processPDFs()` realiza el trabajo principal:
1. Encuentra todos los archivos PDF en el directorio de entrada
2. Si la firma es visible, crea un archivo de configuración temporal
3. Localiza el ejecutable de AutoFirma en el sistema
4. Para cada PDF, crea y ejecuta un comando para firmarlo usando AutoFirma
5. Reporta resultados de éxito/fracaso

### Configuración de firma visible

`createSignatureConfigFile()` genera un archivo de propiedades temporal para configurar la apariencia de la firma visible en el PDF, incluyendo posición, tamaño, texto y estilo.

### Detección de AutoFirma

`findAutoFirmaExecutable()` busca la ubicación de AutoFirma en diferentes sistemas operativos:
- Windows: busca en Program Files y Program Files (x86)
- macOS: busca en Applications y ~/Applications
- Linux: busca en ubicaciones comunes como /usr/bin, /usr/local/bin

### Sistema de logs

Implementa dos enfoques:
1. Logs en consola para modo CLI con niveles (INFO, ERROR)
2. Interface `JTextAreaLogger` para mostrar logs en la GUI de forma asíncrona

## Seguridad

La aplicación tiene en cuenta aspectos de seguridad:
- Limpia los arrays de contraseñas después de usarlos
- Valida todas las entradas del usuario
- Elimina archivos temporales después de usarlos

## Manejo de errores

El código incluye validación y manejo de excepciones para:
- Directorios de entrada/salida inválidos
- Problemas con el certificado
- Fallos en la ejecución de AutoFirma
- Validación de parámetros obligatorios

Esta estructura modular y bien organizada facilita el mantenimiento y extensión futura del código. 