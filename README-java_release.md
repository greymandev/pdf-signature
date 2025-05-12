# PDF Signer - Distribución Java

Este directorio contiene la distribución Java de la aplicación PDF Signer, lista para ser ejecutada en cualquier sistema operativo con Java instalado.

## Estructura de archivos

- **PDFSigner-1.0.0.jar**: El archivo ejecutable principal de la aplicación.
- **libs/**: Directorio que contiene todas las dependencias necesarias para ejecutar la aplicación.

## Requisitos

- Java Runtime Environment (JRE) 8 o superior.

## Ejecución

### En Mac/Linux

1. Abre una terminal.
2. Navega al directorio `releases`.
3. Ejecuta el script `run.sh`:
   ```sh
   ./run.sh
   ```

### En Windows

1. Abre una ventana de comandos (cmd).
2. Navega al directorio `releases`.
3. Ejecuta el script `run.bat`:
   ```bat
   run.bat
   ```

## Ejecución manual

Si prefieres ejecutar la aplicación manualmente, utiliza el siguiente comando desde el directorio `releases`:

### En Mac/Linux:
```sh
java -cp "PDFSigner-1.0.0.jar:libs/*" PDFSignerApp
```

### En Windows:
```bat
java -cp "PDFSigner-1.0.0.jar;libs/*" PDFSignerApp
```

## Notas adicionales

- Asegúrate de que Java esté correctamente instalado y configurado en tu sistema.
- Si encuentras algún problema, verifica que todas las dependencias estén presentes en el directorio `libs/`. 