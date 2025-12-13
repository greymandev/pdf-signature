#!/bin/bash
# ============================================================================
# PDF Signer - Script de Ejecución Automática para Mac/Ubuntu
# ============================================================================
# Este script carga las variables de entorno desde .env y ejecuta autofirma.py
# automáticamente sin requerir parámetros manuales.
#
# Uso: ./run.sh

set -e  # Salir si cualquier comando falla

# Colores para mensajes
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${CYAN}============================================${NC}"
echo -e "${CYAN}  PDF Signer - Ejecución Automática${NC}"
echo -e "${CYAN}============================================${NC}"
echo ""

# Verificar que existe el archivo .env
if [ ! -f ".env" ]; then
    echo -e "${RED}ERROR: No se encuentra el archivo .env${NC}"
    echo ""
    echo "Por favor, crea el archivo .env basándote en .env.template:"
    echo "  cp .env.template .env"
    echo ""
    echo "Luego edita .env con tus valores personales."
    exit 1
fi

# Cargar variables de entorno desde .env
echo -e "${CYAN}Cargando configuración desde .env...${NC}"

# Parsear .env de manera segura (maneja valores con espacios)
while IFS= read -r line || [ -n "$line" ]; do
    # Ignorar líneas vacías y comentarios
    [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
    
    # Parsear variable=valor
    if [[ "$line" =~ ^[[:space:]]*([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
        var_name="${BASH_REMATCH[1]}"
        var_value="${BASH_REMATCH[2]}"
        
        # Remover comillas si existen (simples o dobles)
        var_value="${var_value%\"}"
        var_value="${var_value#\"}"
        var_value="${var_value%\'}"
        var_value="${var_value#\'}"
        
        # Exportar variable
        export "$var_name=$var_value"
    fi
done < .env

# Validar variables requeridas
missing_vars=()
[ -z "$PDF_INPUT_DIR" ] && missing_vars+=("PDF_INPUT_DIR")
[ -z "$PDF_OUTPUT_DIR" ] && missing_vars+=("PDF_OUTPUT_DIR")
[ -z "$PDF_CERT_PATH" ] && missing_vars+=("PDF_CERT_PATH")
[ -z "$PDF_CERT_PASSWORD" ] && missing_vars+=("PDF_CERT_PASSWORD")

if [ ${#missing_vars[@]} -gt 0 ]; then
    echo -e "${RED}ERROR: Faltan las siguientes variables requeridas en .env:${NC}"
    for var in "${missing_vars[@]}"; do
        echo -e "  ${YELLOW}- $var${NC}"
    done
    echo ""
    echo "Por favor, edita .env y configura todos los valores requeridos."
    exit 1
fi

# Construir comando de autofirma.py
echo -e "${CYAN}Construyendo comando de ejecución...${NC}"
cmd=(python3 autofirma.py -i "$PDF_INPUT_DIR" -o "$PDF_OUTPUT_DIR" -c "$PDF_CERT_PATH")

# Agregar parámetros opcionales
[ -n "$PDF_LOCATION" ] && cmd+=(-l "$PDF_LOCATION")
[ -n "$PDF_REASON" ] && cmd+=(-r "$PDF_REASON")
[ "$PDF_VISIBLE" = "true" ] && cmd+=(-v)
[ "$PDF_TIMESTAMP" = "true" ] && cmd+=(-t)
[ -n "$PDF_PROFILE" ] && cmd+=(-P "$PDF_PROFILE")
[ -n "$PDF_ALIAS" ] && cmd+=(-a "$PDF_ALIAS")

# Mostrar configuración
echo ""
echo -e "${CYAN}Configuración:${NC}"
echo "  Input:   $PDF_INPUT_DIR"
echo "  Output:  $PDF_OUTPUT_DIR"
echo "  Cert:    $PDF_CERT_PATH"
echo "  Visible: ${PDF_VISIBLE:-false}"
echo "  Profile: ${PDF_PROFILE:-default}"
echo ""

# Ejecutar autofirma.py
echo -e "${CYAN}Ejecutando PDF Signer...${NC}"
echo ""

if "${cmd[@]}"; then
    echo ""
    echo -e "${GREEN}✓ Proceso completado exitosamente${NC}"
    exit 0
else
    exit_code=$?
    echo ""
    echo -e "${RED}✗ El proceso finalizó con errores (código: $exit_code)${NC}"
    exit $exit_code
fi
