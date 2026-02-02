#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Script para corregir problemas de instalación de UsbDk en Windows
    Script to fix UsbDk installation issues on Windows

.DESCRIPTION
    Este script diagnostica y corrige problemas comunes con la instalación de UsbDk:
    - Verifica privilegios de administrador
    - Detiene y elimina servicios UsbDk existentes
    - Limpia entradas de registro de instalaciones fallidas
    - Elimina instaladores MSI en caché
    - Reinstala UsbDk correctamente
    - Inicia servicios UsbDk
    - Verifica el estado de la instalación

.PARAMETER MsiPath
    Ruta al archivo MSI de UsbDk. Si no se especifica, buscará en rutas comunes.

.PARAMETER CleanOnly
    Solo limpia la instalación existente sin reinstalar.

.PARAMETER SkipReboot
    No solicita reinicio incluso si es necesario.

.EXAMPLE
    .\Fix-UsbDkInstallation.ps1
    .\Fix-UsbDkInstallation.ps1 -MsiPath "C:\Downloads\UsbDk_1.0.22_x64.msi"
    .\Fix-UsbDkInstallation.ps1 -CleanOnly

.NOTES
    Requiere privilegios de administrador
    Compatible con Windows 7/8/8.1/10/11
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$MsiPath,
    
    [Parameter(Mandatory=$false)]
    [switch]$CleanOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$SkipReboot
)

# Configuración de colores y formato
$ErrorActionPreference = "Continue"
$VerbosePreference = "Continue"

# Constantes
$USBDK_SERVICE_NAME = "UsbDk"
$USBDK_PRODUCT_CODE = "{6D4A6ED0-CF41-4615-A4B3-BDA018C3C1CD}"
$USBDK_REGISTRY_PATH = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$USBDK_PRODUCT_CODE"
$USBDK_DRIVER_NAME = "UsbDk.sys"
$LOG_FILE = "$env:TEMP\UsbDk_Fix_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

# Función para escribir log
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    Add-Content -Path $LOG_FILE -Value $logMessage
    
    switch ($Level) {
        "ERROR" { Write-Host $Message -ForegroundColor Red }
        "WARNING" { Write-Host $Message -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $Message -ForegroundColor Green }
        default { Write-Host $Message }
    }
}

# Función para verificar privilegios de administrador
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Función para detener servicios UsbDk
function Stop-UsbDkServices {
    Write-Log "Deteniendo servicios UsbDk..."
    
    $services = @("UsbDk", "UsbDkHelper")
    foreach ($serviceName in $services) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            if ($service.Status -eq "Running") {
                Write-Log "Deteniendo servicio $serviceName..."
                try {
                    Stop-Service -Name $serviceName -Force -ErrorAction Stop
                    Write-Log "Servicio $serviceName detenido exitosamente" "SUCCESS"
                } catch {
                    Write-Log "Error al detener servicio $serviceName : $_" "ERROR"
                }
            } else {
                Write-Log "Servicio $serviceName ya está detenido"
            }
        } else {
            Write-Log "Servicio $serviceName no encontrado"
        }
    }
}

# Función para eliminar servicios UsbDk
function Remove-UsbDkServices {
    Write-Log "Eliminando servicios UsbDk..."
    
    $services = @("UsbDk", "UsbDkHelper")
    foreach ($serviceName in $services) {
        $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
        if ($service) {
            Write-Log "Eliminando servicio $serviceName..."
            try {
                # Detener el servicio primero
                if ($service.Status -eq "Running") {
                    Stop-Service -Name $serviceName -Force -ErrorAction Stop
                }
                
                # Eliminar el servicio usando sc.exe
                $result = & sc.exe delete $serviceName 2>&1
                if ($LASTEXITCODE -eq 0) {
                    Write-Log "Servicio $serviceName eliminado exitosamente" "SUCCESS"
                } else {
                    Write-Log "Error al eliminar servicio $serviceName : $result" "WARNING"
                }
            } catch {
                Write-Log "Error al eliminar servicio $serviceName : $_" "ERROR"
            }
        }
    }
}

# Función para limpiar registro de Windows
function Clear-RegistryEntries {
    Write-Log "Limpiando entradas de registro..."
    
    # Limpiar entradas de producto
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$USBDK_PRODUCT_CODE",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$USBDK_PRODUCT_CODE",
        "HKLM:\SYSTEM\CurrentControlSet\Services\UsbDk",
        "HKLM:\SYSTEM\CurrentControlSet\Services\UsbDkHelper"
    )
    
    foreach ($path in $registryPaths) {
        if (Test-Path $path) {
            Write-Log "Eliminando entrada de registro: $path"
            try {
                Remove-Item -Path $path -Recurse -Force -ErrorAction Stop
                Write-Log "Entrada eliminada exitosamente: $path" "SUCCESS"
            } catch {
                Write-Log "Error al eliminar entrada de registro $path : $_" "WARNING"
            }
        } else {
            Write-Log "Entrada de registro no encontrada: $path"
        }
    }
    
    # Limpiar claves de Windows Installer
    Write-Log "Limpiando claves de Windows Installer..."
    $installerPath = "HKLM:\SOFTWARE\Classes\Installer\Products"
    if (Test-Path $installerPath) {
        $products = Get-ChildItem -Path $installerPath -ErrorAction SilentlyContinue
        foreach ($product in $products) {
            $productName = (Get-ItemProperty -Path $product.PSPath -Name "ProductName" -ErrorAction SilentlyContinue).ProductName
            if ($productName -like "*UsbDk*") {
                Write-Log "Eliminando producto Windows Installer: $productName"
                try {
                    Remove-Item -Path $product.PSPath -Recurse -Force -ErrorAction Stop
                    Write-Log "Producto eliminado: $productName" "SUCCESS"
                } catch {
                    Write-Log "Error al eliminar producto: $_" "WARNING"
                }
            }
        }
    }
}

# Función para limpiar archivos de caché MSI
function Clear-MsiCache {
    Write-Log "Limpiando caché de MSI..."
    
    $msiCachePath = "$env:SystemRoot\Installer"
    if (Test-Path $msiCachePath) {
        $msiFiles = Get-ChildItem -Path $msiCachePath -Filter "*.msi" -ErrorAction SilentlyContinue
        foreach ($msi in $msiFiles) {
            try {
                # Intentar obtener la información del producto del MSI
                $installer = New-Object -ComObject WindowsInstaller.Installer
                $database = $installer.GetType().InvokeMember("OpenDatabase", "InvokeMethod", $null, $installer, @($msi.FullName, 0))
                $view = $database.GetType().InvokeMember("OpenView", "InvokeMethod", $null, $database, ("SELECT Value FROM Property WHERE Property='ProductName'"))
                $view.GetType().InvokeMember("Execute", "InvokeMethod", $null, $view, $null)
                $record = $view.GetType().InvokeMember("Fetch", "InvokeMethod", $null, $view, $null)
                
                if ($record) {
                    $productName = $record.GetType().InvokeMember("StringData", "GetProperty", $null, $record, 1)
                    if ($productName -like "*UsbDk*") {
                        Write-Log "Eliminando archivo MSI en caché: $($msi.Name)"
                        Remove-Item -Path $msi.FullName -Force -ErrorAction Stop
                        Write-Log "Archivo MSI eliminado: $($msi.Name)" "SUCCESS"
                    }
                }
                [System.Runtime.Interopservices.Marshal]::ReleaseComObject($database) | Out-Null
            } catch {
                # Ignorar errores al leer MSI
            }
        }
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($installer) | Out-Null
    }
}

# Función para eliminar archivos de driver
function Remove-DriverFiles {
    Write-Log "Eliminando archivos de driver UsbDk..."
    
    $driverPaths = @(
        "$env:SystemRoot\System32\drivers\UsbDk.sys",
        "$env:SystemRoot\System32\UsbDkHelper.dll",
        "$env:SystemRoot\SysWOW64\UsbDkHelper.dll"
    )
    
    foreach ($path in $driverPaths) {
        if (Test-Path $path) {
            Write-Log "Eliminando archivo: $path"
            try {
                # Tomar ownership del archivo
                takeown /F "$path" /A 2>&1 | Out-Null
                icacls "$path" /grant Administrators:F 2>&1 | Out-Null
                
                Remove-Item -Path $path -Force -ErrorAction Stop
                Write-Log "Archivo eliminado: $path" "SUCCESS"
            } catch {
                Write-Log "Error al eliminar archivo $path : $_" "WARNING"
            }
        } else {
            Write-Log "Archivo no encontrado: $path"
        }
    }
}

# Función para buscar el instalador MSI
function Find-UsbDkInstaller {
    Write-Log "Buscando instalador UsbDk..."
    
    $searchPaths = @(
        "$env:USERPROFILE\Downloads",
        "$env:USERPROFILE\Desktop",
        "C:\",
        "$PSScriptRoot"
    )
    
    foreach ($searchPath in $searchPaths) {
        if (Test-Path $searchPath) {
            $msiFiles = Get-ChildItem -Path $searchPath -Filter "UsbDk*.msi" -Recurse -Depth 2 -ErrorAction SilentlyContinue
            if ($msiFiles) {
                $latestMsi = $msiFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                Write-Log "Instalador encontrado: $($latestMsi.FullName)" "SUCCESS"
                return $latestMsi.FullName
            }
        }
    }
    
    Write-Log "No se encontró instalador MSI de UsbDk" "WARNING"
    return $null
}

# Función para instalar UsbDk
function Install-UsbDk {
    param([string]$InstallerPath)
    
    if (-not (Test-Path $InstallerPath)) {
        Write-Log "Archivo instalador no encontrado: $InstallerPath" "ERROR"
        return $false
    }
    
    Write-Log "Instalando UsbDk desde: $InstallerPath"
    Write-Log "Esto puede tardar varios minutos..."
    
    try {
        # Instalar usando msiexec con logging completo
        $logPath = "$env:TEMP\UsbDk_Install_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
        $arguments = @(
            "/i",
            "`"$InstallerPath`"",
            "/qn",  # Quiet mode, no user interaction
            "/norestart",
            "/L*v",
            "`"$logPath`""
        )
        
        Write-Log "Ejecutando: msiexec.exe $($arguments -join ' ')"
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $arguments -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Log "UsbDk instalado exitosamente" "SUCCESS"
            Write-Log "Log de instalación guardado en: $logPath"
            return $true
        } elseif ($process.ExitCode -eq 3010) {
            Write-Log "UsbDk instalado exitosamente, pero se requiere reinicio" "WARNING"
            Write-Log "Log de instalación guardado en: $logPath"
            return $true
        } else {
            Write-Log "Error en la instalación. Código de salida: $($process.ExitCode)" "ERROR"
            Write-Log "Consulte el log en: $logPath" "ERROR"
            return $false
        }
    } catch {
        Write-Log "Error al instalar UsbDk: $_" "ERROR"
        return $false
    }
}

# Función para verificar instalación
function Test-UsbDkInstallation {
    Write-Log "Verificando instalación de UsbDk..."
    
    $checks = @{
        "Registro" = $false
        "Servicio" = $false
        "Driver" = $false
    }
    
    # Verificar registro
    if (Test-Path $USBDK_REGISTRY_PATH) {
        $checks["Registro"] = $true
        Write-Log "✓ Entrada de registro encontrada" "SUCCESS"
    } else {
        Write-Log "✗ Entrada de registro no encontrada" "WARNING"
    }
    
    # Verificar servicio
    $service = Get-Service -Name $USBDK_SERVICE_NAME -ErrorAction SilentlyContinue
    if ($service) {
        $checks["Servicio"] = $true
        Write-Log "✓ Servicio UsbDk encontrado (Estado: $($service.Status))" "SUCCESS"
    } else {
        Write-Log "✗ Servicio UsbDk no encontrado" "WARNING"
    }
    
    # Verificar archivo de driver
    $driverPath = "$env:SystemRoot\System32\drivers\$USBDK_DRIVER_NAME"
    if (Test-Path $driverPath) {
        $checks["Driver"] = $true
        Write-Log "✓ Driver UsbDk encontrado" "SUCCESS"
    } else {
        Write-Log "✗ Driver UsbDk no encontrado" "WARNING"
    }
    
    return ($checks.Values -contains $false) -eq $false
}

# Función para iniciar servicios UsbDk
function Start-UsbDkServices {
    Write-Log "Iniciando servicios UsbDk..."
    
    $service = Get-Service -Name $USBDK_SERVICE_NAME -ErrorAction SilentlyContinue
    if ($service) {
        try {
            if ($service.Status -ne "Running") {
                Start-Service -Name $USBDK_SERVICE_NAME -ErrorAction Stop
                Write-Log "Servicio UsbDk iniciado exitosamente" "SUCCESS"
            } else {
                Write-Log "Servicio UsbDk ya está en ejecución" "SUCCESS"
            }
        } catch {
            Write-Log "Error al iniciar servicio UsbDk: $_" "WARNING"
            Write-Log "El servicio puede iniciarse automáticamente después de reiniciar" "WARNING"
        }
    } else {
        Write-Log "Servicio UsbDk no encontrado" "WARNING"
    }
}

# ========== MAIN ==========

Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║     UsbDk Installation Fix Tool / Herramienta de Reparación  ║
║                         v1.0.0                               ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

Write-Log "Iniciando script de reparación de UsbDk..."
Write-Log "Log guardado en: $LOG_FILE"

# Verificar privilegios de administrador
if (-not (Test-Administrator)) {
    Write-Log "Este script requiere privilegios de administrador" "ERROR"
    Write-Log "Por favor, ejecute PowerShell como Administrador" "ERROR"
    exit 1
}

Write-Log "Privilegios de administrador verificados" "SUCCESS"

# Paso 1: Detener servicios
Stop-UsbDkServices

# Paso 2: Eliminar servicios
Remove-UsbDkServices

# Paso 3: Limpiar registro
Clear-RegistryEntries

# Paso 4: Limpiar caché MSI
Clear-MsiCache

# Paso 5: Eliminar archivos de driver
Remove-DriverFiles

Write-Log "Limpieza completada" "SUCCESS"

# Si solo se solicitó limpieza, terminar aquí
if ($CleanOnly) {
    Write-Log "Modo de solo limpieza. No se reinstalará UsbDk." "WARNING"
    Write-Log "Script completado exitosamente" "SUCCESS"
    exit 0
}

# Paso 6: Buscar o usar el instalador proporcionado
if ([string]::IsNullOrEmpty($MsiPath)) {
    $MsiPath = Find-UsbDkInstaller
}

if ([string]::IsNullOrEmpty($MsiPath)) {
    Write-Log "No se proporcionó ruta de instalador y no se pudo encontrar uno" "ERROR"
    Write-Log "Use el parámetro -MsiPath para especificar la ruta al instalador" "ERROR"
    Write-Log "Ejemplo: .\Fix-UsbDkInstallation.ps1 -MsiPath 'C:\Downloads\UsbDk_1.0.22_x64.msi'" "ERROR"
    exit 1
}

# Paso 7: Instalar UsbDk
if (Install-UsbDk -InstallerPath $MsiPath) {
    Start-Sleep -Seconds 5
    
    # Paso 8: Iniciar servicios
    Start-UsbDkServices
    
    # Paso 9: Verificar instalación
    Start-Sleep -Seconds 2
    if (Test-UsbDkInstallation) {
        Write-Log "`n✓✓✓ UsbDk instalado y verificado exitosamente ✓✓✓" "SUCCESS"
    } else {
        Write-Log "La instalación se completó pero hay advertencias" "WARNING"
        Write-Log "Es posible que necesite reiniciar el sistema" "WARNING"
    }
    
    # Verificar si se necesita reinicio
    if (-not $SkipReboot) {
        $reboot = Read-Host "`n¿Desea reiniciar el sistema ahora? (S/N)"
        if ($reboot -eq "S" -or $reboot -eq "s") {
            Write-Log "Reiniciando sistema en 10 segundos..."
            Start-Sleep -Seconds 10
            Restart-Computer -Force
        }
    }
} else {
    Write-Log "La instalación falló. Consulte los logs para más detalles." "ERROR"
    exit 1
}

Write-Log "`nScript completado exitosamente" "SUCCESS"
Write-Log "Log completo guardado en: $LOG_FILE"
