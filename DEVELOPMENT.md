# Guía de Desarrollo de PDF Signer

Este documento está dirigido a desarrolladores que quieran contribuir o modificar el proyecto PDF Signer.

## Requisitos de Desarrollo

- Java Development Kit (JDK) 8 o superior
- Gradle 8.14 o superior
- Git
- IDE recomendado: IntelliJ IDEA o Eclipse

## Estructura del Proyecto

```
pdf-signature/
├── src/
│   ├── main/java/      # Código fuente principal
│   └── test/java/      # Pruebas unitarias
├── build.gradle        # Configuración de Gradle
├── gradle/             # Wrapper de Gradle
├── releases/           # Distribuciones compiladas
└── examples/           # Ejemplos de uso
```

## Configuración del Entorno

1. Clona el repositorio:
```bash
git clone https://github.com/yourusername/pdf-signature.git
cd pdf-signature
```

2. Configura el JDK:
```bash
# Windows
set JAVA_HOME=C:\Program Files\Java\jdk1.8.0_xxx

# Mac/Linux
export JAVA_HOME=/path/to/jdk
```

3. Verifica la instalación:
```bash
./gradlew --version
```

## Compilación

### Desarrollo Local

```bash
./gradlew clean build
```

### Generar Distribución

```bash
./gradlew clean build copyJarToReleases
```

## Pruebas

### Ejecutar Pruebas Unitarias

```bash
./gradlew test
```

### Ejecutar Pruebas de Integración

```bash
./gradlew integrationTest
```

Los resultados de las pruebas se encuentran en `build/reports/tests/`.

## Estructura del Código

### Componentes Principales

1. **PDFSignerApp.java**
   - Punto de entrada de la aplicación
   - Manejo de argumentos de línea de comandos
   - Interfaz gráfica (Swing)

2. **Configuración de Firma**
   ```java
   private static final String DEFAULT_LOCATION = "Madrid";
   private static final String DEFAULT_REASON = "Document validation";
   private static final boolean DEFAULT_VISIBLE = false;
   private static final boolean DEFAULT_TIMESTAMP = false;
   ```

3. **Apariencia de Firma**
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

## Empaquetado

### Requisitos por Plataforma

#### macOS
- Xcode Command Line Tools
- Certificado de desarrollador de Apple (opcional)

#### Windows
- Visual Studio Build Tools
- Windows SDK

#### Linux
- Build Essentials
- RPM Build Tools (para .rpm)
- Debian Build Tools (para .deb)

### Generar Paquetes

```bash
./gradlew jpackage
```

Los paquetes generados se encontrarán en `build/jpackage/`.

## Guías de Estilo

1. **Código Java**
   - Seguir las convenciones de Java
   - Documentar todas las clases y métodos públicos
   - Usar nombres descriptivos
   - Mantener métodos cortos y enfocados

2. **Commits**
   - Mensajes claros y descriptivos
   - Referenciar issues cuando sea relevante
   - Un cambio lógico por commit

3. **Pull Requests**
   - Descripción clara del cambio
   - Referenciar issues relacionados
   - Incluir pruebas cuando sea necesario

## Seguridad

1. **Manejo de Contraseñas**
   - Limpiar arrays de contraseñas después de usarlos
   - No almacenar contraseñas en texto plano
   - Usar variables de entorno para desarrollo

2. **Validación de Entrada**
   - Validar todas las entradas del usuario
   - Sanitizar rutas de archivos
   - Manejar excepciones apropiadamente

## Depuración

1. **Logs**
   - Usar niveles de log apropiados
   - Incluir información contextual
   - No exponer información sensible

2. **Pruebas**
   - Escribir pruebas unitarias
   - Incluir pruebas de integración
   - Simular diferentes escenarios

## Contribución

1. Fork el repositorio
2. Crea una rama para tu feature
3. Haz tus cambios
4. Ejecuta las pruebas
5. Envía un pull request

## Recursos

- [Documentación de Gradle](https://docs.gradle.org/)
- [Documentación de Java](https://docs.oracle.com/javase/8/docs/)
- [Guía de estilo de Java](https://google.github.io/styleguide/javaguide.html)
- [Documentación de AutoFirma](https://firmaelectronica.gob.es/Home/Ciudadanos/Aplicaciones-Firma.html) 