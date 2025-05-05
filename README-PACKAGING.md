# Guía de Empaquetado de PDF Signer

Esta guía explica cómo crear paquetes ejecutables para diferentes sistemas operativos a partir del código fuente de PDF Signer.

## Requisitos Previos

### Para todos los sistemas:
- Java Development Kit (JDK) 8 o superior
- Gradle 8.14 o superior
- Git (opcional, para clonar el repositorio)

### Para macOS:
- Xcode Command Line Tools
- Certificado de desarrollador de Apple (opcional, para firmar la aplicación)

### Para Windows:
- Visual Studio Build Tools
- Windows SDK

### Para Linux:
- Build Essentials
- RPM Build Tools (para paquetes .rpm)
- Debian Build Tools (para paquetes .deb)

## Configuración del Proyecto

1. Clonar el repositorio:
```bash
git clone https://github.com/yourusername/pdf-signature.git
cd pdf-signature
```

2. Asegurarse de que el archivo `build.gradle` contiene la configuración correcta:
```gradle
plugins {
    id 'java'
    id 'application'
    id 'org.beryx.runtime' version '1.13.0'
}

// ... (resto de la configuración)
```

## Creación de Paquetes

### macOS

1. Instalar las herramientas necesarias:
```bash
# Instalar Homebrew si no está instalado
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Instalar Java y Gradle
brew install openjdk gradle
```

2. Configurar Java:
```bash
export JAVA_HOME=/opt/homebrew/opt/openjdk
```

3. Crear el paquete:
```bash
./gradlew jpackage
```

Los archivos generados se encontrarán en `build/jpackage/`:
- `pdf-signature-1.0.dmg` - Imagen de disco para distribución
- `pdf-signature-1.0.pkg` - Instalador de paquete
- `pdf-signature.app` - Aplicación macOS

### Windows

1. Instalar las herramientas necesarias:
   - Instalar JDK desde [Oracle](https://www.oracle.com/java/technologies/downloads/) o [AdoptOpenJDK](https://adoptopenjdk.net/)
   - Instalar Gradle desde [gradle.org](https://gradle.org/install/)
   - Instalar Visual Studio Build Tools con Windows SDK

2. Configurar variables de entorno:
```batch
set JAVA_HOME=C:\Program Files\Java\jdk1.8.0_xxx
set PATH=%JAVA_HOME%\bin;%PATH%
```

3. Crear el paquete:
```batch
gradlew.bat jpackage
```

Los archivos generados se encontrarán en `build/jpackage/`:
- `pdf-signature-1.0.msi` - Instalador de Windows
- `pdf-signature-1.0.exe` - Instalador ejecutable

### Linux

1. Instalar las herramientas necesarias:

Para sistemas basados en Debian/Ubuntu:
```bash
sudo apt-get update
sudo apt-get install -y build-essential
sudo apt-get install -y default-jdk
sudo apt-get install -y gradle
```

Para sistemas basados en Red Hat/Fedora:
```bash
sudo dnf install -y gcc gcc-c++ make
sudo dnf install -y java-1.8.0-openjdk-devel
sudo dnf install -y gradle
```

2. Crear el paquete:
```bash
./gradlew jpackage
```

Los archivos generados se encontrarán en `build/jpackage/`:
- `pdf-signature-1.0.deb` - Para sistemas Debian/Ubuntu
- `pdf-signature-1.0.rpm` - Para sistemas Red Hat/Fedora

## Distribución

### macOS
- Distribuir el archivo `.dmg` o `.pkg`
- Los usuarios pueden hacer doble clic para instalar
- La aplicación se instalará en la carpeta Aplicaciones

### Windows
- Distribuir el archivo `.msi` o `.exe`
- Los usuarios pueden hacer doble clic para instalar
- Se creará un acceso directo en el menú Inicio

### Linux
- Distribuir el archivo `.deb` o `.rpm` según la distribución
- Los usuarios pueden instalar usando:
  ```bash
  # Para Debian/Ubuntu
  sudo dpkg -i pdf-signature.deb
  
  # Para Red Hat/Fedora
  sudo rpm -i pdf-signature.rpm
  ```

## Requisitos para los Usuarios Finales

1. No necesitan tener Java instalado (incluido en el paquete)
2. Necesitan tener AutoFirma instalado:
   - Windows: Instalador desde [AutoFirma](https://firmaelectronica.gob.es/Home/Descargas.html)
   - macOS: Aplicación desde la App Store o sitio web oficial
   - Linux: Paquete desde los repositorios oficiales

## Solución de Problemas

### Errores Comunes

1. Error de permisos:
```bash
chmod +x gradlew
```

2. Error de Java no encontrado:
```bash
# Verificar la instalación de Java
java -version
# Verificar JAVA_HOME
echo $JAVA_HOME
```

3. Error de Gradle:
```bash
# Limpiar la caché de Gradle
./gradlew clean
# Actualizar el wrapper de Gradle
./gradlew wrapper --gradle-version 8.14
```

### Verificación de Paquetes

Para verificar que los paquetes se han creado correctamente:

1. macOS:
```bash
# Verificar el contenido del .dmg
hdiutil attach pdf-signature-1.0.dmg
# Verificar el contenido del .pkg
pkgutil --check-signature pdf-signature-1.0.pkg
```

2. Windows:
```batch
# Verificar el instalador
msiexec /a pdf-signature-1.0.msi /qb
```

3. Linux:
```bash
# Verificar el paquete .deb
dpkg-deb -I pdf-signature-1.0.deb
# Verificar el paquete .rpm
rpm -qip pdf-signature-1.0.rpm
```

## Notas Adicionales

- Los paquetes incluyen un JRE mínimo necesario para ejecutar la aplicación
- Se crean accesos directos y entradas de menú del sistema automáticamente
- Los scripts de instalación/desinstalación se incluyen en cada paquete
- La aplicación requiere permisos de administrador para la instalación

## Soporte

Si encuentras problemas durante el proceso de empaquetado, por favor:
1. Verifica que todos los requisitos previos están instalados
2. Revisa los logs de construcción en `build/reports/`
3. Asegúrate de que AutoFirma está instalado y accesible en el sistema 