#!/bin/bash
#
# Script para firmar documentos usando AutoFirma
# Adaptado para usar configuración desde .env
#
# Ejecutar:
#   Pasar el documento PDF a firmar como parámetro.
#   El resultado es otro documento con una coletilla en el nombre.
#
#    ./script.sh documento.pdf
#

set -e  # Exit on error

# Directorio del script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Cargar variables del .env de forma segura (maneja espacios)
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "[INFO] Cargando configuración desde .env..."
    # Usar export con lectura línea por línea para manejar espacios
    while IFS= read -r line || [ -n "$line" ]; do
        # Ignorar líneas vacías y comentarios
        if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi
        # Exportar la variable (eval maneja correctamente las comillas)
        if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
            export "${BASH_REMATCH[1]}=${BASH_REMATCH[2]}"
        fi
    done < "$SCRIPT_DIR/.env"
else
    echo "[ERROR] No se encuentra el archivo .env en $SCRIPT_DIR"
    exit 1
fi

# Validar parámetro
if [ -z "$1" ]; then
    echo "[ERROR] Uso: $0 <archivo.pdf>"
    exit 1
fi

# Leemos el nombre del archivo pdf pasado por línea de comandos
ARCHIVO="$1"
if [ ! -f "$ARCHIVO" ]; then
    echo "[ERROR] El archivo $ARCHIVO no existe"
    exit 1
fi

# Creamos el nombre del archivo resultado
ARCHIVOFIRMADO="${ARCHIVO/%.pdf/_firmado.pdf}"

### Configuración desde .env ###

# Certificado (añadimos prefijo pkcs12: si no lo tiene)
STORE="$PDF_CERT_PATH"
if [[ ! "$STORE" =~ ^pkcs12: ]]; then
    STORE="pkcs12:$STORE"
fi

PASSWORD="$PDF_CERT_PASSWORD"
LOCATION="${PDF_LOCATION:-}"
REASON="${PDF_REASON:-}"

# Buscar Java
JAVA_CMD="java"
if [ -n "$JAVA_HOME" ]; then
    JAVA_CMD="$JAVA_HOME/bin/java"
fi

# Buscar AutoFirma JAR
AUTOFIRMA=""
if [ -f "/Applications/AutoFirma.app/Contents/Resources/JAR/AutoFirma.jar" ]; then
    AUTOFIRMA="/Applications/AutoFirma.app/Contents/Resources/JAR/AutoFirma.jar"
elif [ -f "/usr/lib/AutoFirma/AutoFirma.jar" ]; then
    AUTOFIRMA="/usr/lib/AutoFirma/AutoFirma.jar"
else
    echo "[ERROR] No se encuentra AutoFirma.jar"
    exit 1
fi

echo "[INFO] Usando AutoFirma: $AUTOFIRMA"

# Formato
FORMAT="pades"

# Posición de la firma visible (desde .env)
PositionOnPageLowerLeftX="${PDF_SIG_RECT_X:-10}"
PositionOnPageLowerLeftY="${PDF_SIG_RECT_Y:-122}"
PositionOnPageUpperRightX=$((PositionOnPageLowerLeftX + ${PDF_SIG_WIDTH:-27}))
PositionOnPageUpperRightY=$((PositionOnPageLowerLeftY + ${PDF_SIG_HEIGHT:-13}))

# Fuente de letras
l2FontColor="${PDF_SIG_COLOR:-black}"
l2FontSize='7'
l2FontFamily='1'
l2FontStyle='0'

# Página
signaturaPage="${PDF_SIG_PAGE:-1}"

# Imagen de rúbrica (si existe)
signatureRubricImage=""
if [ -n "$PDF_SIG_IMAGE_PATH" ] && [ -f "$PDF_SIG_IMAGE_PATH" ]; then
    echo "[INFO] Codificando imagen de rúbrica..."
    signatureRubricImage=$(base64 < "$PDF_SIG_IMAGE_PATH" | tr -d '\n')
fi

# Texto de la firma (desde .env o default)
LAYER2TEXT="${PDF_SIG_TEXT:-Firmado por \$\$SUBJECTCN\$\$ el día \$\$SIGNDATE=dd/MM/yyyy\$\$}"

# Configuración que espera AutoFirma
CONFIG="layer2Text=$LAYER2TEXT
signaturePositionOnPageLowerLeftX=$PositionOnPageLowerLeftX
signaturePositionOnPageLowerLeftY=$PositionOnPageLowerLeftY
signaturePositionOnPageUpperRightX=$PositionOnPageUpperRightX
signaturePositionOnPageUpperRightY=$PositionOnPageUpperRightY
layer2FontColor=$l2FontColor
layer2FontSize=$l2FontSize
layer2FontFamily=$l2FontFamily
layer2FontStyle=$l2FontStyle
signaturePage=$signaturaPage"

# Añadir imagen si existe
if [ -n "$signatureRubricImage" ]; then
    CONFIG="$CONFIG
signatureRubricImage=$signatureRubricImage"
fi

# Añadir metadata si existe
if [ -n "$LOCATION" ]; then
    CONFIG="$CONFIG
signatureProductionCity=$LOCATION"
fi

if [ -n "$REASON" ]; then
    CONFIG="$CONFIG
signatureReason=$REASON"
fi

### Firma del documento ###

echo "[INFO] Obteniendo alias del certificado..."
ALIASES=$($JAVA_CMD -jar "$AUTOFIRMA" listaliases -store "$STORE" -password "$PASSWORD" 2>/dev/null | head -n 1)

if [ -z "$ALIASES" ]; then
    echo "[ERROR] No se pudo obtener el alias del certificado"
    exit 1
fi

echo "[INFO] Usando alias: $ALIASES"
echo "[INFO] Firmando documento: $ARCHIVO"
echo "[INFO] Salida: $ARCHIVOFIRMADO"

$JAVA_CMD -jar "$AUTOFIRMA" sign \
    -i "$ARCHIVO" \
    -o "$ARCHIVOFIRMADO" \
    -store "$STORE" \
    -format "$FORMAT" \
    -password "$PASSWORD" \
    -alias "$ALIASES" \
    -config "$CONFIG"

if [ $? -eq 0 ] && [ -f "$ARCHIVOFIRMADO" ]; then
    echo "[SUCCESS] Documento firmado correctamente: $ARCHIVOFIRMADO"
else
    echo "[ERROR] La firma falló"
    exit 1
fi