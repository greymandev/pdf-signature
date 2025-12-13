# Guía de Desarrollo de PDF Signer

Este documento detalla la configuración, estructura y flujo de trabajo para desarrolladores que deseen contribuir o modificar el script `autofirma.py`.

## Requisitos de Desarrollo

- **Python 3.8+**
- **AutoFirma**: Debe estar instalado en el sistema.
- **Dependencias**:
  ```bash
  pip install -r requirements.txt
  ```

## Estructura del Proyecto

- `autofirma.py`: Script principal (Wrapper de AutoFirma).
- `signature_profiles.json`: Archivo de configuración para perfiles de firma visible.
- `tests/`: Directorio de pruebas.
  - `test_e2e.py`: Prueba End-to-End recomendada.
  - `input_files/`: Archivos PDF de prueba.
  - `output_files/`: Resultados de las pruebas (ignorados por git).
- `key/`: Directorio para certificados (ignorado por git, excepto ejemplos).

## Configuración

### 1. Variables de Entorno
Crea un archivo `.env` en la raíz del proyecto para definir secretos locales:
```ini
PDF_CERT_PASSWORD=tu_contraseña_del_certificado
```

### 2. Perfiles de Firma Visible (`signature_profiles.json`)
El sistema utiliza un archivo JSON para definir los parámetros de la firma visible.
Puedes editar `signature_profiles.json` para añadir o modificar perfiles.

**Estructura:**
```json
{
  "default": {
    "page": 1,
    "rect": {
      "x": 10,
      "y": 122,
      "width": 27,
      "height": 13
    },
    "text": "Firmado por $$SUBJECTCN$$ el día $$SIGNDATE=dd/MM/yyyy$$..."
  },
  "mi_perfil_personalizado": {
      ...
  }
}
```

**Uso:**
Usa el argumento `-P` o `--profile` para invocar un perfil específico:
```bash
python autofirma.py ... -v -P mi_perfil_personalizado
```

## Pruebas

Para información detallada sobre cómo ejecutar las pruebas, consulta [tests/README.md](tests/README.md).

### Ejecución Rápida
```bash
python -m unittest tests/test_e2e.py
```

## Flujo de Trabajo
1. Realiza cambios en `autofirma.py` o los perfiles.
2. Ejecuta `test_e2e.py` para verificar que la firma sigue funcionando.
3. Verifica visualmente el PDF resultante en `tests/output_files/` si hiciste cambios de diseño. 