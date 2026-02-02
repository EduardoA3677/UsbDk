# 🚀 Guía de Inicio Rápido / Quick Start Guide

## 🇪🇸 Español - Instrucciones Rápidas

### ¿Qué hace este script?
✅ Soluciona problemas de instalación de UsbDk en Windows  
✅ Limpia instalaciones fallidas anteriores  
✅ Reinstala UsbDk correctamente  
✅ Verifica que todo funcione  

### Pasos Rápidos (5 minutos)

#### Opción 1: Método Más Fácil 🎯

1. **Descarga** estos archivos a tu escritorio:
   - `Fix-UsbDkInstallation.bat`
   - `Fix-UsbDkInstallation.ps1`

2. **Haz clic derecho** en `Fix-UsbDkInstallation.bat`

3. **Selecciona** "Ejecutar como administrador"

4. **Espera** a que termine (unos 2-3 minutos)

5. **¡Listo!** 🎉

#### Opción 2: Con Instalador Específico

Si tienes el archivo MSI de UsbDk descargado:

1. **Abre PowerShell como Administrador**:
   - Busca "PowerShell" en el menú inicio
   - Clic derecho → "Ejecutar como administrador"

2. **Navega** a la carpeta donde descargaste el script:
   ```powershell
   cd C:\Users\TuUsuario\Downloads
   ```

3. **Ejecuta**:
   ```powershell
   .\Fix-UsbDkInstallation.ps1 -MsiPath "C:\Ruta\Al\UsbDk_1.0.22_x64.msi"
   ```

### ⚠️ Errores Comunes

**"No se puede ejecutar scripts"**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**"Requiere privilegios de administrador"**
- Asegúrate de hacer clic derecho → "Ejecutar como administrador"

---

## 🇺🇸 English - Quick Instructions

### What does this script do?
✅ Fixes UsbDk installation issues on Windows  
✅ Cleans up previous failed installations  
✅ Reinstalls UsbDk correctly  
✅ Verifies everything works  

### Quick Steps (5 minutes)

#### Option 1: Easiest Method 🎯

1. **Download** these files to your desktop:
   - `Fix-UsbDkInstallation.bat`
   - `Fix-UsbDkInstallation.ps1`

2. **Right-click** on `Fix-UsbDkInstallation.bat`

3. **Select** "Run as administrator"

4. **Wait** for it to finish (about 2-3 minutes)

5. **Done!** 🎉

#### Option 2: With Specific Installer

If you have the UsbDk MSI file downloaded:

1. **Open PowerShell as Administrator**:
   - Search for "PowerShell" in start menu
   - Right-click → "Run as administrator"

2. **Navigate** to where you downloaded the script:
   ```powershell
   cd C:\Users\YourUser\Downloads
   ```

3. **Run**:
   ```powershell
   .\Fix-UsbDkInstallation.ps1 -MsiPath "C:\Path\To\UsbDk_1.0.22_x64.msi"
   ```

### ⚠️ Common Errors

**"Cannot run scripts"**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**"Requires administrator privileges"**
- Make sure to right-click → "Run as administrator"

---

## 📋 What Gets Fixed

| Issue | Solution |
|-------|----------|
| 🔴 Error 2756 (System folder access) | ✅ Cleans registry and reinstalls |
| 🔴 Service won't start | ✅ Removes and reinstalls services |
| 🔴 Driver not loading | ✅ Removes old drivers and reinstalls |
| 🔴 MSI installer conflicts | ✅ Clears installer cache |
| 🔴 Previous installation corrupted | ✅ Complete cleanup and reinstall |

## 🗂️ Log Files

After running, check these files if you have issues:
```
%TEMP%\UsbDk_Fix_YYYYMMDD_HHMMSS.log
%TEMP%\UsbDk_Install_YYYYMMDD_HHMMSS.log
```

To view:
```cmd
notepad %TEMP%\UsbDk_Fix_*.log
```

## 🆘 Need Help?

1. ✅ Check `README_FIX_INSTALLATION.md` for detailed instructions
2. ✅ Check `ERRORES_COMUNES.md` for error solutions (Spanish)
3. ✅ Review the log files mentioned above
4. ✅ Create an issue on GitHub with your log files

## 📊 Expected Results

### ✅ Success
```
✓✓✓ UsbDk instalado y verificado exitosamente ✓✓✓
✓✓✓ UsbDk installed and verified successfully ✓✓✓
```

### ⚠️ Needs Reboot
```
UsbDk installed successfully, but reboot is required
```
→ Just restart your computer

### ❌ Failed
```
Error en la instalación / Installation failed
```
→ Check the log file and review common errors guide

---

## 🔧 Advanced Options

### Clean Only (No Reinstall)
```powershell
.\Fix-UsbDkInstallation.ps1 -CleanOnly
```

### Skip Reboot Prompt
```powershell
.\Fix-UsbDkInstallation.ps1 -SkipReboot
```

### Specific Installer Path
```powershell
.\Fix-UsbDkInstallation.ps1 -MsiPath "C:\Downloads\UsbDk_1.0.22_x64.msi"
```

### Combine Options
```powershell
.\Fix-UsbDkInstallation.ps1 -MsiPath "C:\Downloads\UsbDk_1.0.22_x64.msi" -SkipReboot
```

---

## 📦 Package Contents

| File | Description |
|------|-------------|
| `Fix-UsbDkInstallation.bat` | 🟢 Easy launcher (double-click) |
| `Fix-UsbDkInstallation.ps1` | 🔵 Main PowerShell script |
| `README_FIX_INSTALLATION.md` | 📖 Detailed documentation (EN/ES) |
| `ERRORES_COMUNES.md` | 📖 Common errors guide (Spanish) |
| `QUICK_START.md` | ⚡ This quick start guide |

---

## ⏱️ Typical Timeline

1. **Cleanup Phase**: 30-60 seconds
2. **Installation Phase**: 1-2 minutes  
3. **Verification Phase**: 10-20 seconds
4. **Total**: ~2-3 minutes

---

## 🎯 Based On

This script was created by analyzing the installation log from:
```
https://raw.githubusercontent.com/EduardoA3677/kernel_buildboty/refs/heads/sauce/unpack.log
```

**Key problems identified and fixed:**
- ❌ ACTION=ADMIN (administrative installation) → ✅ Normal installation
- ❌ TARGETDIR incorrectly specified → ✅ Uses default paths
- ❌ Error 2756 System folder issues → ✅ Registry cleanup
- ❌ Service registration failures → ✅ Complete service reinstall

---

**Version:** 1.0.0  
**Date:** 2026-02-02  
**Compatibility:** Windows 7/8/8.1/10/11 (x64)
