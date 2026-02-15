# Guía de Despliegue con Docker

Esta guía explica cómo ejecutar PDF Signer en un contenedor Docker usando Docker Compose.

## Requisitos

- **Docker** instalado ([Descargar Docker](https://www.docker.com/get-started))
- **Docker Compose** instalado (incluido con Docker Desktop)

## Configuración Rápida

### 1. Preparar Archivos

Asegúrate de tener la siguiente estructura:

```
pdf-signature/
├── tests/
│   ├── input_files/     # PDFs a firmar
│   └── output_files/    # PDFs firmados (se generan)
├── key/
│   └── certificado.p12  # Tu certificado digital
├── docker-compose.yml
└── .env.docker          # Plantilla de configuración
```

### 2. Configurar Variables de Entorno

Copia el archivo de configuración para Docker:

```bash
cp .env.docker .env
```

Edita el archivo `.env` y configura **al menos** la contraseña del certificado:

```bash
# REQUERIDO
PDF_CERT_PASSWORD=tu_contraseña_real

# Opcional: Personalizar firma visible
PDF_VISIBLE=true
PDF_SIG_RECT_X=400
PDF_SIG_RECT_Y=50
PDF_SIG_WIDTH=150
PDF_SIG_HEIGHT=50
```

### 3. Colocar Archivos

1. **PDFs a firmar**: Colócalos en `./tests/input_files/`
2. **Certificado**: Coloca tu archivo `.p12` o `.pfx` en `./key/certificado.p12`

## Ejecución

### Construir y Ejecutar

```bash
docker-compose up --build
```

### Solo Ejecutar (si ya está construido)

```bash
docker-compose up
```

### Ejecutar en Segundo Plano

```bash
docker-compose up -d
```

### Ver Logs

```bash
docker-compose logs -f
```

### Detener

```bash
docker-compose down
```

## Volúmenes

El contenedor monta tres directorios locales:

| Directorio Local | Directorio en Contenedor | Propósito |
|------------------|--------------------------|-----------|
| `./tests/input_files` | `/app/input_files` | PDFs a firmar |
| `./tests/output_files` | `/app/output_files` | PDFs firmados |
| `./key` | `/app/key` | Certificado digital |

> [!NOTE]
> Los PDFs firmados aparecerán automáticamente en `./tests/output_files/` después de la ejecución.

## Configuración Avanzada

### Personalizar Directorios

Edita `docker-compose.yml` para cambiar los directorios montados:

```yaml
volumes:
  - /ruta/personalizada/input:/app/input_files
  - /ruta/personalizada/output:/app/output_files
  - /ruta/personalizada/certs:/app/key
```

### Variables de Entorno Disponibles

Todas las variables del archivo `.env`:

```bash
# Requeridas
PDF_CERT_PASSWORD=contraseña

# Firma visible
PDF_VISIBLE=true
PDF_SIG_PAGE=1
PDF_SIG_RECT_X=400
PDF_SIG_RECT_Y=50
PDF_SIG_WIDTH=150
PDF_SIG_HEIGHT=50
PDF_SIG_TEXT="Firmado por $$SUBJECTCN$$"
PDF_SIG_COLOR=black

# Opcionales
PDF_LOCATION=Madrid
PDF_REASON=Firma oficial
PDF_TIMESTAMP=true
PDF_ALIAS=mi_alias
```

### Ejecutar con Parámetros Personalizados

Puedes sobrescribir variables directamente:

```bash
PDF_CERT_PASSWORD=mipass PDF_VISIBLE=false docker-compose up
```

## Solución de Problemas

### Error: "No module named 'dotenv'"

Reconstruye la imagen:
```bash
docker-compose build --no-cache
```

### Error: "Certificate file does not exist"

Verifica que el certificado esté en `./key/certificado.p12`

### Error: "Input directory does not exist"

Asegúrate de que `./tests/input_files/` existe y contiene PDFs.

### Los PDFs no se firman

1. Verifica los logs: `docker-compose logs`
2. Comprueba que el certificado es válido
3. Verifica que `PDF_CERT_PASSWORD` es correcta

## Ejemplo Completo

```bash
# 1. Preparar estructura
mkdir -p tests/input_files tests/output_files key

# 2. Copiar certificado
cp mi_certificado.p12 key/certificado.p12

# 3. Copiar PDFs a firmar
cp mis_pdfs/*.pdf tests/input_files/

# 4. Configurar variables
cp .env.docker .env
nano .env  # Editar y añadir PDF_CERT_PASSWORD

# 5. Ejecutar
docker-compose up --build

# 6. Verificar resultados
ls tests/output_files/
```

## Integración CI/CD

### GitHub Actions

```yaml
name: Sign PDFs

on: [push]

jobs:
  sign:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Build and Run
        env:
          PDF_CERT_PASSWORD: ${{ secrets.CERT_PASSWORD }}
        run: |
          docker-compose up --build
          
      - name: Upload Signed PDFs
        uses: actions/upload-artifact@v3
        with:
          name: signed-pdfs
          path: tests/output_files/
```

### GitLab CI

```yaml
sign-pdfs:
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker-compose up --build
  artifacts:
    paths:
      - tests/output_files/
```

## Notas de Seguridad

> [!WARNING]
> **Nunca** commitees el archivo `.env` con tu contraseña real al repositorio.

Buenas prácticas:
1. Usa `.env` solo localmente
2. En producción, usa Docker secrets o variables de entorno del sistema
3. Mantén el directorio `key/` fuera del control de versiones (ya está en `.gitignore`)

## Referencias

- [Documentación principal](../README.md)
- [Guía de desarrollo](DEVELOPMENT.md)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
