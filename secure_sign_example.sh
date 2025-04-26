#!/bin/bash
# ============================================================
# Ejemplo de firma segura de PDFs
# ============================================================
# Este script muestra las diferentes formas de proporcionar una contraseña
# de forma segura al firmador de PDFs, con énfasis en el uso de variables
# de entorno como método recomendado.
# 
# Autor: gr3ym4n
# ============================================================

# Colores para mensajes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Directorios para la prueba
INPUT_DIR="./input_pdfs"
OUTPUT_DIR="./signed_pdfs"
CERT_FILE="./certificate.pfx"

# Crear directorio temporal para archivo de contraseña
TEMP_DIR=$(mktemp -d)
PASSWORD_FILE="$TEMP_DIR/password.txt"

# Función para limpiar archivos temporales al salir
cleanup() {
  echo -e "${BLUE}Limpiando recursos temporales...${NC}"
  echo -e "${BLUE}Limpiando variable de entorno PDF_CERT_PASSWORD...${NC}"
  unset PDF_CERT_PASSWORD
  echo -e "${BLUE}Eliminando archivos temporales...${NC}"
  rm -rf "$TEMP_DIR"
}

# Registrar la función de limpieza para que se ejecute al salir
trap cleanup EXIT

echo -e "${YELLOW}IMPORTANTE: El método recomendado es usar la variable de entorno PDF_CERT_PASSWORD${NC}"
echo ""

echo -e "${GREEN}Ejemplo 1: Usar una variable de entorno (RECOMENDADO)${NC}"
echo "# Establecer la variable de entorno (espacio al inicio evita registro en historial)"
echo " export PDF_CERT_PASSWORD='tu_contraseña_segura'"
echo ""
echo "# Ejecutar el script (detecta automáticamente la variable)"
echo "./auto_sign_pdf.sh -i $INPUT_DIR -o $OUTPUT_DIR -c $CERT_FILE"
echo ""
echo "# Limpiar la variable cuando termine"
echo "unset PDF_CERT_PASSWORD"
echo ""

echo -e "${GREEN}Ejemplo práctico: Establecer ahora la variable de entorno${NC}"
read -s -p "Introduce una contraseña para la demostración (no se mostrará): " DEMO_PASSWORD
echo # Agregar salto de línea
if [ -n "$DEMO_PASSWORD" ]; then
  export PDF_CERT_PASSWORD="$DEMO_PASSWORD"
  echo -e "${GREEN}Variable PDF_CERT_PASSWORD establecida. Ahora puedes usar:${NC}"
  echo "./auto_sign_pdf.sh -i $INPUT_DIR -o $OUTPUT_DIR -c $CERT_FILE"
  echo -e "${YELLOW}La variable se eliminará automáticamente al salir del script${NC}"
  echo ""
fi

echo -e "${GREEN}Ejemplo 2: Especificar una variable de entorno diferente${NC}"
echo "# Guardar la contraseña en otra variable de entorno"
echo "export MI_CERT_PASSWORD='otra_contraseña_segura'"
echo ""
echo "# Usar esa variable específica"
echo "./auto_sign_pdf.sh -i $INPUT_DIR -o $OUTPUT_DIR -c $CERT_FILE --password-env MI_CERT_PASSWORD"
echo ""

echo -e "${GREEN}Ejemplo 3: Usar un archivo de contraseña${NC}"
echo "# Crear un archivo con permisos restrictivos"
echo "echo 'tu_contraseña_segura' > $PASSWORD_FILE"
echo "chmod 600 $PASSWORD_FILE  # Establecer permisos restrictivos"
echo ""
echo "# Usar el archivo para la autenticación"
echo "./auto_sign_pdf.sh -i $INPUT_DIR -o $OUTPUT_DIR -c $CERT_FILE --password-file $PASSWORD_FILE"
echo ""
echo "# No olvides eliminar el archivo cuando termines"
echo "rm $PASSWORD_FILE"
echo ""

echo -e "${GREEN}Ejemplo 4: Solicitar la contraseña interactivamente${NC}"
echo "./auto_sign_pdf.sh -i $INPUT_DIR -o $OUTPUT_DIR -c $CERT_FILE --prompt-password"
echo ""

echo -e "${BLUE}Recomendaciones de seguridad:${NC}"
echo "1. PREFERIR usar la variable de entorno PDF_CERT_PASSWORD (método predeterminado)"
echo "2. EVITAR pasar contraseñas como argumentos en línea de comandos"
echo "3. Limpiar las variables de entorno cuando termines (unset PDF_CERT_PASSWORD)"
echo "4. Si usas archivos de contraseña, aplicar permisos restrictivos (chmod 600)"
echo "5. Considerar usar un administrador de credenciales del sistema"
echo ""

echo -e "${GREEN}Integración con keyring en Linux:${NC}"
echo "SECRET=\$(secret-tool lookup application pdf-signer certificate mycert)"
echo "export PDF_CERT_PASSWORD=\"\$SECRET\""
echo "./auto_sign_pdf.sh -i $INPUT_DIR -o $OUTPUT_DIR -c $CERT_FILE"
echo ""

echo -e "${GREEN}Integración con keychain en macOS:${NC}"
echo "SECRET=\$(security find-generic-password -a \$USER -s \"pdf-signer-cert\" -w)"
echo "export PDF_CERT_PASSWORD=\"\$SECRET\""
echo "./auto_sign_pdf.sh -i $INPUT_DIR -o $OUTPUT_DIR -c $CERT_FILE"
echo "" 