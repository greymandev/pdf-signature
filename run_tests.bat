@echo off
REM Script para ejecutar las pruebas en sistemas Windows

REM Verificar si Gradle está instalado
where gradle >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo Gradle no está instalado. Usando Gradle Wrapper.
    if not exist gradlew.bat (
        echo Generando Gradle Wrapper...
        gradle wrapper
    )
    set GRADLE_CMD=gradlew.bat
) else (
    set GRADLE_CMD=gradle
)

REM Ejecutar las pruebas
echo Ejecutando pruebas con %GRADLE_CMD%...
%GRADLE_CMD% clean test

REM Mostrar el resultado
if %ERRORLEVEL% equ 0 (
    echo ¡Pruebas completadas con éxito!
) else (
    echo Las pruebas han fallado. Revisa los errores.
)

pause 