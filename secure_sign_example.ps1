# ============================================================
# Ejemplo de firma segura de PDFs en PowerShell
# ============================================================
# Este script muestra las diferentes formas de proporcionar una contraseña
# de forma segura al firmador de PDFs usando PowerShell, con énfasis en el
# uso de variables de entorno como método recomendado.
# 
# Autor: gr3ym4n
# ============================================================

# Directorios para la prueba
$InputDir = ".\input_pdfs"
$OutputDir = ".\signed_pdfs"
$CertFile = ".\certificate.pfx"

# Crear directorio temporal para archivo de contraseña
$TempDir = [System.IO.Path]::GetTempPath() + [System.Guid]::NewGuid().ToString()
New-Item -ItemType Directory -Path $TempDir | Out-Null
$PasswordFile = "$TempDir\password.txt"

# Función para limpiar archivos temporales al salir
function Cleanup {
    Write-Host "Limpiando recursos temporales..." -ForegroundColor Blue
    Write-Host "Limpiando variable de entorno PDF_CERT_PASSWORD..." -ForegroundColor Blue
    $Env:PDF_CERT_PASSWORD = $null
    Write-Host "Eliminando archivos temporales..." -ForegroundColor Blue
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force
    }
}

# Registrar la función de limpieza para que se ejecute al salir
trap { Cleanup; break; }

try {
    Write-Host "IMPORTANTE: El método recomendado es usar la variable de entorno PDF_CERT_PASSWORD" -ForegroundColor Yellow
    Write-Host ""

    Write-Host "Ejemplo 1: Usar una variable de entorno (RECOMENDADO)" -ForegroundColor Green
    Write-Host "# Establecer la variable de entorno"
    Write-Host '$Env:PDF_CERT_PASSWORD = "tu_contraseña_segura"'
    Write-Host ""
    Write-Host "# Ejecutar el script (detecta automáticamente la variable)"
    Write-Host ".\auto_sign_pdf.ps1 -InputDir $InputDir -OutputDir $OutputDir -CertFile $CertFile"
    Write-Host ""
    Write-Host "# Limpiar la variable cuando termine"
    Write-Host '$Env:PDF_CERT_PASSWORD = $null'
    Write-Host ""

    Write-Host "Ejemplo práctico: Establecer ahora la variable de entorno" -ForegroundColor Green
    $DemoPassword = Read-Host -Prompt "Introduce una contraseña para la demostración" -AsSecureString
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($DemoPassword)
    try {
        $PlainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
        if (-not [string]::IsNullOrEmpty($PlainPassword)) {
            $Env:PDF_CERT_PASSWORD = $PlainPassword
            Write-Host "Variable PDF_CERT_PASSWORD establecida. Ahora puedes usar:" -ForegroundColor Green
            Write-Host ".\auto_sign_pdf.ps1 -InputDir $InputDir -OutputDir $OutputDir -CertFile $CertFile"
            Write-Host "La variable se eliminará automáticamente al salir del script" -ForegroundColor Yellow
            Write-Host ""
        }
    } finally {
        [System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }

    Write-Host "Ejemplo 2: Especificar una variable de entorno diferente" -ForegroundColor Green
    Write-Host "# Guardar la contraseña en otra variable de entorno"
    Write-Host '$Env:MI_CERT_PASSWORD = "otra_contraseña_segura"'
    Write-Host ""
    Write-Host "# Usar esa variable específica"
    Write-Host ".\auto_sign_pdf.ps1 -InputDir $InputDir -OutputDir $OutputDir -CertFile $CertFile -PasswordEnv MI_CERT_PASSWORD"
    Write-Host ""

    Write-Host "Ejemplo 3: Usar un archivo de contraseña" -ForegroundColor Green
    Write-Host "# Crear un archivo con permisos restrictivos"
    Write-Host "Set-Content -Path $PasswordFile -Value 'tu_contraseña_segura' -NoNewline"
    Write-Host "# Establecer permisos restrictivos"
    Write-Host "icacls $PasswordFile /inheritance:r /grant:r `"$($env:USERNAME)`":(F)"
    Write-Host ""
    Write-Host "# Usar el archivo para la autenticación"
    Write-Host ".\auto_sign_pdf.ps1 -InputDir $InputDir -OutputDir $OutputDir -CertFile $CertFile -PasswordFile $PasswordFile"
    Write-Host ""
    Write-Host "# No olvides eliminar el archivo cuando termines"
    Write-Host "Remove-Item -Path $PasswordFile -Force"
    Write-Host ""

    Write-Host "Ejemplo 4: Solicitar la contraseña interactivamente" -ForegroundColor Green
    Write-Host ".\auto_sign_pdf.ps1 -InputDir $InputDir -OutputDir $OutputDir -CertFile $CertFile -PromptPassword"
    Write-Host ""

    Write-Host "Recomendaciones de seguridad:" -ForegroundColor Blue
    Write-Host "1. PREFERIR usar la variable de entorno PDF_CERT_PASSWORD (método predeterminado)"
    Write-Host "2. EVITAR pasar contraseñas como argumentos en línea de comandos"
    Write-Host "3. Limpiar las variables de entorno cuando termines (`$Env:PDF_CERT_PASSWORD = `$null)"
    Write-Host "4. Si usas archivos de contraseña, aplicar permisos restrictivos"
    Write-Host "5. Considerar usar el administrador de credenciales de Windows"
    Write-Host ""

    Write-Host "Integración con Windows Credential Manager:" -ForegroundColor Green
    Write-Host '# Guardar credenciales (solo necesario una vez)'
    Write-Host 'cmdkey /generic:PDF-Signer /user:CertificatePassword /pass:"tu_contraseña_segura"'
    Write-Host ''
    Write-Host '# Recuperar y usar la contraseña guardada'
    Write-Host '$Password = (cmdkey /generic:PDF-Signer | Where-Object {$_ -like "*contraseña*"}) -replace ".*: ", ""'
    Write-Host '$Env:PDF_CERT_PASSWORD = $Password'
    Write-Host '.\auto_sign_pdf.ps1 -InputDir $InputDir -OutputDir $OutputDir -CertFile $CertFile'
    Write-Host '# Limpiar cuando termines'
    Write-Host '$Env:PDF_CERT_PASSWORD = $null'
    Write-Host ""
}
finally {
    # Asegurarse de que se limpien los recursos
    Cleanup
} 