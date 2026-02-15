FROM eclipse-temurin:11-jre

# Metadatos
LABEL maintainer="Greyman"
LABEL description="PDF Signature Tool with AutoFirma"

# Instalar Python 3 y dependencias del sistema
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Crear directorio de trabajo
WORKDIR /app

# Copiar archivos de la aplicación
COPY requirements.txt .
RUN pip3 install --no-cache-dir --break-system-packages -r requirements.txt

COPY autofirma.py .

# Copiar AutoFirma JAR desde sistema local
# IMPORTANTE: Debes tener AutoFirma instalado localmente
# macOS: /Applications/AutoFirma.app/Contents/Resources/JAR/AutoFirma.jar
# Linux: /usr/lib/AutoFirma/AutoFirma.jar
# Windows: C:\Program Files\AutoFirma\AutoFirma.jar
COPY AutoFirma.jar /usr/lib/AutoFirma/AutoFirma.jar

# Crear directorios para volúmenes
RUN mkdir -p /app/input_files /app/output_files /app/key

# Variables de entorno por defecto (pueden sobrescribirse con docker-compose)
ENV PDF_INPUT_DIR=/app/input_files \
    PDF_OUTPUT_DIR=/app/output_files \
    PDF_CERT_PATH=/app/key/certificado.p12 \
    PDF_VISIBLE=true \
    PDF_SIG_PAGE=1 \
    PDF_SIG_RECT_X=400 \
    PDF_SIG_RECT_Y=50 \
    PDF_SIG_WIDTH=150 \
    PDF_SIG_HEIGHT=50 \
    PDF_SIG_COLOR=black

# Comando por defecto
CMD ["python3", "autofirma.py"]
