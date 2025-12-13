# Guía de Inicio Rápido - PDF Signer 🚀

Esta guía te ayudará a configurar y ejecutar PDF Signer en **menos de 5 minutos**.

## 📋 Requisitos Previos

1. **Python 3.8+** instalado
2. **AutoFirma** instalado ([Descargar aquí](https://firmaelectronica.gob.es/Home/Ciudadanos/Aplicaciones-Firma.html))
3. **Certificado digital** en formato PFX/P12

## ⚡ Configuración en 3 Pasos

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

Abre `.env` en tu editor favorito y configura:

```bash
# REQUERIDO: Edita estos valores
PDF_INPUT_DIR=./pdfs              # Tu carpeta con PDFs
PDF_OUTPUT_DIR=./signed            # Carpeta para PDFs firmados
PDF_CERT_PATH=./key/cert.pfx       # Ruta a tu certificado
PDF_CERT_PASSWORD=tu_contraseña    # Contraseña del certificado

# OPCIONAL: Personaliza la firma
PDF_VISIBLE=true                   # Firma visible (true/false)
PDF_LOCATION=Madrid, España        # Ubicación
PDF_REASON=Firma de documentos     # Razón de firma
PDF_PROFILE=default                # Perfil de firma
```

### Paso 3: Ejecutar el Script

**Mac/Linux:**
```bash
./run.sh
```

**Windows PowerShell:**
```powershell
.\run.ps1
```

¡Eso es todo! 🎉 Tus PDFs firmados estarán en la carpeta de salida configurada.

---

## 🔧 Solución de Problemas

### Error: "No se encuentra el archivo .env"
- Asegúrate de haber copiado `.env.template` a `.env`
- Verifica que estés en el directorio correcto del proyecto

### Error: "AutoFirma executable not found"
- Instala AutoFirma desde [el sitio oficial](https://firmaelectronica.gob.es/Home/Ciudadanos/Aplicaciones-Firma.html)
- En Mac, verifica que esté en `/Applications/AutoFirma.app`
- En Windows, verifica la instalación en `Program Files`

### Error: "Permission denied" al ejecutar run.sh (Mac/Linux)
```bash
chmod +x run.sh
```

### Error en PowerShell: "Execution policy"
```powershell
# Ejecuta PowerShell como Administrador
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### La firma no se ve en el PDF
- Verifica que `PDF_VISIBLE=true` en tu archivo `.env`
- Prueba con diferentes perfiles en `signature_profiles.json`
- Consulta [DEVELOPMENT.md](DEVELOPMENT.md) para ajustar coordenadas

---

## 📚 Documentación Adicional

- **Configuración Avanzada:** [DEVELOPMENT.md](DEVELOPMENT.md)
- **Perfiles de Firma:** Edita `signature_profiles.json`
- **Pruebas:** [../tests/README.md](../tests/README.md)

---

## 💡 Consejos

### Firma Múltiple de PDFs
Coloca todos tus PDFs en la carpeta `PDF_INPUT_DIR` y el script los procesará automáticamente.

### Automatización Completa
- **Windows:** Programa una tarea en el Programador de Tareas
- **Mac/Linux:** Crea un cron job o usa launchd

Ejemplo de cron (Linux/Mac):
```bash
# Ejecutar cada día a las 9:00 AM
0 9 * * * cd /ruta/a/pdf-signature && ./run.sh
```

### Integración con CI/CD
Los scripts son perfectos para integración continua. Configura variables de entorno en tu pipeline y ejecuta directamente.

---

## ❓ ¿Necesitas Ayuda?

Si encuentras problemas, revisa:
1. Los logs que muestra el script en la terminal
2. La [documentación completa](../README.md)
3. Los [ejemplos de prueba](../tests/README.md)
