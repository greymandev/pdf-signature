#!/bin/bash

# Script para ejecutar las pruebas en sistemas Unix/Linux/macOS

# Verificar si Gradle está instalado
if ! command -v gradle &> /dev/null; then
    echo "Gradle no está instalado. Usando Gradle Wrapper."
    if [ ! -f "./gradlew" ]; then
        echo "Generando Gradle Wrapper..."
        gradle wrapper
    fi
    GRADLE_CMD="./gradlew"
else
    GRADLE_CMD="gradle"
fi

# Ejecutar las pruebas
echo "Ejecutando pruebas con $GRADLE_CMD..."
$GRADLE_CMD clean test

# Mostrar el resultado
if [ $? -eq 0 ]; then
    echo "¡Pruebas completadas con éxito!"
else
    echo "Las pruebas han fallado. Revisa los errores."
fi 