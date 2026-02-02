# Guía Rápida: Solución de Errores de Instalación de UsbDk

## Basado en Análisis del Log de Instalación

### URL del Log Analizado
```
https://raw.githubusercontent.com/EduardoA3677/kernel_buildboty/refs/heads/sauce/unpack.log
```

---

## Errores Comunes Identificados en el Log

### 1. Error 2756 - Problemas con System Folder

**Descripción del Error en el Log:**
```
MSI (s) (C8:6C) [01:06:24:027]: Note: 1: 2756 2: System64Folder
MSI (s) (C8:6C) [01:06:24:028]: Note: 1: 2756 2: SystemFolder
```

**Causa:**
- El instalador está intentando una instalación administrativa (ACTION=ADMIN)
- Problemas de permisos en carpetas del sistema
- Instalación previa corrupta

**Solución:**
1. **Ejecutar el Script de Reparación:**
   ```powershell
   .\Fix-UsbDkInstallation.ps1
   ```

2. **O manualmente:**
   - Desinstalar UsbDk completamente usando el Panel de Control
   - Limpiar entradas de registro en:
     * `HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{6D4A6ED0-CF41-4615-A4B3-BDA018C3C1CD}`
   - Eliminar carpeta de caché de Windows Installer:
     * `C:\Windows\Installer\` (buscar archivos relacionados con UsbDk)
   - Reinstalar con instalación normal (no administrativa)

### 2. Instalación Administrativa Incorrecta

**Descripción del Error en el Log:**
```
PROPERTY CHANGE: Adding ACTION property. Its value is 'ADMIN'.
Command Line: TARGETDIR=C:\Users\ralva\Downloads\xx ACTION=ADMIN
```

**Causa:**
- Se está intentando hacer una instalación administrativa (desempacar MSI)
- El comando `/a` fue usado en msiexec
- No es una instalación normal en el sistema

**Solución:**
No use el flag `/a` o `ACTION=ADMIN`. Use instalación normal:

```cmd
msiexec /i UsbDk_1.0.22_x64.msi /qn /norestart
```

O use el script de reparación que instala correctamente:
```powershell
.\Fix-UsbDkInstallation.ps1 -MsiPath "C:\ruta\al\UsbDk_1.0.22_x64.msi"
```

### 3. Directorio de Destino Incorrecto

**Descripción del Error en el Log:**
```
PROPERTY CHANGE: Adding TARGETDIR property. Its value is 'C:\Users\ralva\Downloads\xx'.
PROPERTY CHANGE: Modifying ProgramFiles64Folder property. 
Its current value is 'C:\Program Files\'. 
Its new value: 'C:\Users\ralva\Downloads\xx\UsbDk Runtime Library\'.
```

**Causa:**
- Se especificó un TARGETDIR personalizado
- El instalador intenta instalar en una ubicación incorrecta

**Solución:**
No especifique TARGETDIR. Deje que el instalador use la ubicación predeterminada:

```powershell
# Correcto - sin especificar TARGETDIR
msiexec /i UsbDk_1.0.22_x64.msi /qn /norestart

# Incorrecto - con TARGETDIR
msiexec /i UsbDk_1.0.22_x64.msi TARGETDIR=C:\alguna\ruta /qn
```

---

## Procedimiento Completo de Reparación

### Método 1: Usar el Script Automático (Recomendado)

1. **Descargar el script:**
   - `Fix-UsbDkInstallation.ps1`
   - `Fix-UsbDkInstallation.bat`

2. **Ejecutar como Administrador:**
   - Clic derecho en `Fix-UsbDkInstallation.bat`
   - Seleccionar "Ejecutar como administrador"

3. **Seguir las instrucciones en pantalla**

### Método 2: Reparación Manual

#### Paso 1: Detener Servicios
```powershell
Stop-Service -Name "UsbDk" -Force -ErrorAction SilentlyContinue
sc.exe stop UsbDk
```

#### Paso 2: Eliminar Servicios
```powershell
sc.exe delete UsbDk
sc.exe delete UsbDkHelper
```

#### Paso 3: Limpiar Registro
Abrir Registry Editor (regedit.exe) y eliminar:
```
HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{6D4A6ED0-CF41-4615-A4B3-BDA018C3C1CD}
HKLM\SYSTEM\CurrentControlSet\Services\UsbDk
HKLM\SYSTEM\CurrentControlSet\Services\UsbDkHelper
```

#### Paso 4: Eliminar Archivos de Driver
```powershell
takeown /F "C:\Windows\System32\drivers\UsbDk.sys" /A
icacls "C:\Windows\System32\drivers\UsbDk.sys" /grant Administrators:F
del "C:\Windows\System32\drivers\UsbDk.sys"
```

#### Paso 5: Reinstalar
```cmd
msiexec /i UsbDk_1.0.22_x64.msi /qn /L*v C:\temp\usbdk_install.log
```

#### Paso 6: Verificar
```powershell
Get-Service -Name "UsbDk"
Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{6D4A6ED0-CF41-4615-A4B3-BDA018C3C1CD}"
```

---

## Errores Específicos y Soluciones

### Error: "Servicio no puede iniciar"

**Síntomas:**
- El servicio UsbDk está instalado pero no inicia
- Error en Event Viewer

**Solución:**
1. Verificar firma del driver (Windows 7 requiere KB3033929)
2. Verificar que el archivo del driver existe:
   ```
   C:\Windows\System32\drivers\UsbDk.sys
   ```
3. Revisar Event Viewer:
   ```
   eventvwr.msc > Windows Logs > System
   ```
4. Considerar deshabilitar temporalmente la verificación de firma de drivers

### Error: "Instalación requiere reinicio"

**Código de salida MSI: 3010**

**Solución:**
- Reiniciar el sistema
- O usar el flag `/forcerestart`:
  ```cmd
  msiexec /i UsbDk_1.0.22_x64.msi /qn /forcerestart
  ```

### Error: "No se puede acceder al servicio de Windows Installer"

**Solución:**
1. Verificar que el servicio Windows Installer está en ejecución:
   ```powershell
   Get-Service -Name "msiserver"
   Start-Service -Name "msiserver"
   ```

2. O usar command line:
   ```cmd
   net start msiserver
   ```

---

## Verificación Post-Instalación

### Verificar que UsbDk está instalado correctamente:

```powershell
# Verificar servicio
Get-Service -Name "UsbDk"

# Verificar registro
Test-Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{6D4A6ED0-CF41-4615-A4B3-BDA018C3C1CD}"

# Verificar driver
Test-Path "C:\Windows\System32\drivers\UsbDk.sys"

# Verificar DLL
Test-Path "C:\Windows\System32\UsbDkHelper.dll"
Test-Path "C:\Windows\SysWOW64\UsbDkHelper.dll"
```

### Probar funcionalidad básica:

```cmd
# Usar UsbDkController para enumerar dispositivos
cd "C:\Program Files\UsbDk Runtime Library"
UsbDkController.exe -n
```

---

## Logs Útiles

### Ubicación de Logs de Instalación:
```
%TEMP%\UsbDk_Fix_*.log          (Script de reparación)
%TEMP%\UsbDk_Install_*.log      (Instalación MSI)
C:\Windows\Logs\*               (Logs del sistema)
```

### Ver logs de instalación MSI:
```cmd
# Durante instalación
msiexec /i UsbDk_1.0.22_x64.msi /L*v C:\temp\install.log

# Ver log
notepad C:\temp\install.log
```

### Event Viewer:
```
Windows Logs > System
Windows Logs > Application
```
Filtrar por fuente: "MsiInstaller", "Service Control Manager"

---

## Requisitos del Sistema

### Windows 7/2008 R2:
- **IMPORTANTE:** Instalar KB3033929 antes de instalar UsbDk
- Descargar desde: https://support.microsoft.com/kb/3033929
- Razón: UsbDk está firmado con certificado SHA-256

### Windows 8/8.1/10/11:
- Sin requisitos especiales
- Asegurarse de que Windows Update esté actualizado

---

## Contacto y Soporte

- **GitHub Issues:** https://github.com/daynix/UsbDk/issues
- **Documentación:** Ver archivo ARCHITECTURE en el repositorio
- **Script de Reparación:** Ver README_FIX_INSTALLATION.md

---

## Notas Importantes

1. **Siempre ejecutar como Administrador**
2. **No usar instalación administrativa (ACTION=ADMIN) para instalación normal**
3. **No especificar TARGETDIR personalizado**
4. **Reiniciar si se solicita (código de salida 3010)**
5. **En Windows 7, instalar KB3033929 primero**
6. **Revisar logs si hay problemas**

---

**Última actualización:** 2026-02-02
**Basado en:** Análisis del log de instalación de UsbDk_1.0.22_x64.msi
