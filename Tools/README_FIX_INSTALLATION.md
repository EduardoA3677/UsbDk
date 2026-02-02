# UsbDk Installation Fix Tool / Herramienta de Reparación de Instalación

[English](#english) | [Español](#español)

---

## English

### Overview

This PowerShell script fixes common UsbDk installation issues on Windows systems. Based on analysis of installation logs, it addresses problems such as:

- Failed MSI installations
- Service startup failures
- Driver loading issues
- Registry corruption
- Cached installer conflicts

### Installation Log Analysis

The script was developed based on analysis of the installation log from:
```
https://raw.githubusercontent.com/EduardoA3677/kernel_buildboty/refs/heads/sauce/unpack.log
```

**Common issues identified:**
- Error 2756: System folder access issues
- Administrative installation (ACTION=ADMIN) conflicts
- Cached MSI files causing conflicts
- Service registration failures
- Driver installation problems

### Requirements

- **Operating System:** Windows 7/8/8.1/10/11 (x64)
- **Privileges:** Administrator rights
- **PowerShell:** Version 5.1 or higher
- **UsbDk MSI Installer:** Downloaded from official sources

### Usage

#### Basic Usage

1. **Download the script** to your computer
2. **Open PowerShell as Administrator:**
   - Right-click on PowerShell
   - Select "Run as Administrator"
3. **Navigate to the script directory:**
   ```powershell
   cd C:\Path\To\Script
   ```
4. **Run the script:**
   ```powershell
   .\Fix-UsbDkInstallation.ps1
   ```

#### Advanced Usage

**Specify MSI installer path:**
```powershell
.\Fix-UsbDkInstallation.ps1 -MsiPath "C:\Downloads\UsbDk_1.0.22_x64.msi"
```

**Clean only (no reinstallation):**
```powershell
.\Fix-UsbDkInstallation.ps1 -CleanOnly
```

**Skip reboot prompt:**
```powershell
.\Fix-UsbDkInstallation.ps1 -SkipReboot
```

**Combine parameters:**
```powershell
.\Fix-UsbDkInstallation.ps1 -MsiPath "C:\Downloads\UsbDk_1.0.22_x64.msi" -SkipReboot
```

### What the Script Does

1. **Verification Phase:**
   - Checks for administrator privileges
   - Creates detailed log file

2. **Cleanup Phase:**
   - Stops running UsbDk services
   - Removes UsbDk services from system
   - Cleans registry entries
   - Removes cached MSI files
   - Deletes old driver files

3. **Installation Phase:**
   - Locates or uses specified MSI installer
   - Performs clean installation
   - Starts UsbDk services

4. **Verification Phase:**
   - Validates registry entries
   - Checks service status
   - Verifies driver files

### Troubleshooting

#### Error: "This script requires administrator privileges"
**Solution:** Right-click PowerShell and select "Run as Administrator"

#### Error: "Execution of scripts is disabled"
**Solution:** Run this command in Administrator PowerShell:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Error: "MSI installer not found"
**Solution:** 
- Download UsbDk MSI from official sources
- Use the `-MsiPath` parameter to specify the location

#### Installation succeeds but services won't start
**Solution:**
- Reboot your computer
- Check Windows Event Viewer for driver errors
- Ensure Windows security updates are installed (especially KB3033929 for Windows 7)

#### Driver signature verification fails
**Solution:**
- Ensure you have Windows Update KB3033929 installed (Windows 7)
- Temporarily disable driver signature enforcement:
  ```
  1. Hold Shift and click Restart
  2. Select Troubleshoot > Advanced options > Startup Settings > Restart
  3. Press F7 to disable driver signature enforcement
  ```

### Log Files

The script creates detailed log files in:
```
%TEMP%\UsbDk_Fix_YYYYMMDD_HHMMSS.log
%TEMP%\UsbDk_Install_YYYYMMDD_HHMMSS.log
```

Check these logs if you encounter issues.

### Common Error Codes

| Exit Code | Meaning |
|-----------|---------|
| 0 | Success |
| 1 | Administrator privileges required or installation failed |
| 3010 | Success, reboot required |

### Additional Resources

- **UsbDk Repository:** https://github.com/daynix/UsbDk
- **Documentation:** See ARCHITECTURE file in repository
- **API Documentation:** See UsbDkHelper/UsbDkHelper.h

---

## Español

### Descripción General

Este script de PowerShell corrige problemas comunes de instalación de UsbDk en sistemas Windows. Basado en análisis de registros de instalación, aborda problemas como:

- Instalaciones MSI fallidas
- Fallos en inicio de servicios
- Problemas de carga de drivers
- Corrupción de registro
- Conflictos con instaladores en caché

### Análisis del Log de Instalación

El script fue desarrollado basándose en el análisis del log de instalación de:
```
https://raw.githubusercontent.com/EduardoA3677/kernel_buildboty/refs/heads/sauce/unpack.log
```

**Problemas comunes identificados:**
- Error 2756: Problemas de acceso a carpetas del sistema
- Conflictos de instalación administrativa (ACTION=ADMIN)
- Archivos MSI en caché causando conflictos
- Fallos en el registro de servicios
- Problemas de instalación de drivers

### Requisitos

- **Sistema Operativo:** Windows 7/8/8.1/10/11 (x64)
- **Privilegios:** Derechos de administrador
- **PowerShell:** Versión 5.1 o superior
- **Instalador MSI de UsbDk:** Descargado de fuentes oficiales

### Uso

#### Uso Básico

1. **Descargue el script** a su computadora
2. **Abra PowerShell como Administrador:**
   - Clic derecho en PowerShell
   - Seleccione "Ejecutar como administrador"
3. **Navegue al directorio del script:**
   ```powershell
   cd C:\Ruta\Del\Script
   ```
4. **Ejecute el script:**
   ```powershell
   .\Fix-UsbDkInstallation.ps1
   ```

#### Uso Avanzado

**Especificar ruta del instalador MSI:**
```powershell
.\Fix-UsbDkInstallation.ps1 -MsiPath "C:\Descargas\UsbDk_1.0.22_x64.msi"
```

**Solo limpiar (sin reinstalación):**
```powershell
.\Fix-UsbDkInstallation.ps1 -CleanOnly
```

**Omitir solicitud de reinicio:**
```powershell
.\Fix-UsbDkInstallation.ps1 -SkipReboot
```

**Combinar parámetros:**
```powershell
.\Fix-UsbDkInstallation.ps1 -MsiPath "C:\Descargas\UsbDk_1.0.22_x64.msi" -SkipReboot
```

### Qué Hace el Script

1. **Fase de Verificación:**
   - Verifica privilegios de administrador
   - Crea archivo de log detallado

2. **Fase de Limpieza:**
   - Detiene servicios UsbDk en ejecución
   - Elimina servicios UsbDk del sistema
   - Limpia entradas del registro
   - Elimina archivos MSI en caché
   - Borra archivos de drivers antiguos

3. **Fase de Instalación:**
   - Localiza o usa el instalador MSI especificado
   - Realiza instalación limpia
   - Inicia servicios UsbDk

4. **Fase de Verificación:**
   - Valida entradas del registro
   - Verifica estado de servicios
   - Comprueba archivos de drivers

### Solución de Problemas

#### Error: "Este script requiere privilegios de administrador"
**Solución:** Clic derecho en PowerShell y seleccione "Ejecutar como administrador"

#### Error: "La ejecución de scripts está deshabilitada"
**Solución:** Ejecute este comando en PowerShell como Administrador:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Error: "Instalador MSI no encontrado"
**Solución:** 
- Descargue el MSI de UsbDk de fuentes oficiales
- Use el parámetro `-MsiPath` para especificar la ubicación

#### La instalación tiene éxito pero los servicios no inician
**Solución:**
- Reinicie su computadora
- Verifique el Visor de eventos de Windows para errores del driver
- Asegúrese de tener las actualizaciones de seguridad de Windows instaladas (especialmente KB3033929 para Windows 7)

#### Falla la verificación de firma del driver
**Solución:**
- Asegúrese de tener instalada la actualización KB3033929 de Windows (Windows 7)
- Deshabilite temporalmente la verificación de firma de drivers:
  ```
  1. Mantenga presionado Shift y haga clic en Reiniciar
  2. Seleccione Solucionar problemas > Opciones avanzadas > Configuración de inicio > Reiniciar
  3. Presione F7 para deshabilitar la verificación de firma de drivers
  ```

### Archivos de Log

El script crea archivos de log detallados en:
```
%TEMP%\UsbDk_Fix_YYYYMMDD_HHMMSS.log
%TEMP%\UsbDk_Install_YYYYMMDD_HHMMSS.log
```

Revise estos logs si encuentra problemas.

### Códigos de Error Comunes

| Código de Salida | Significado |
|------------------|-------------|
| 0 | Éxito |
| 1 | Se requieren privilegios de administrador o la instalación falló |
| 3010 | Éxito, se requiere reinicio |

### Recursos Adicionales

- **Repositorio UsbDk:** https://github.com/daynix/UsbDk
- **Documentación:** Ver archivo ARCHITECTURE en el repositorio
- **Documentación de API:** Ver UsbDkHelper/UsbDkHelper.h

---

## Support / Soporte

If you encounter issues not covered in this document, please:
Si encuentra problemas no cubiertos en este documento, por favor:

1. Check the log files / Revise los archivos de log
2. Review Windows Event Viewer / Revise el Visor de eventos de Windows
3. Create an issue in the repository / Cree un issue en el repositorio
4. Include log files and error messages / Incluya archivos de log y mensajes de error

---

## License / Licencia

This tool is provided under the same license as the UsbDk project.
See the LICENSE file in the repository root.

Esta herramienta se proporciona bajo la misma licencia que el proyecto UsbDk.
Vea el archivo LICENSE en la raíz del repositorio.
