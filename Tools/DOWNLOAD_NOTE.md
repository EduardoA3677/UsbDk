# Important Download Note / Nota Importante de Descarga

## 🇪🇸 Español

### Problema: Errores de Sintaxis al Descargar

Si ve errores como:
```
Falta la llave de cierre "}" en el bloque de instrucciones
Missing closing brace "}" in statement block
```

**Causa:** GitHub puede convertir los finales de línea de Windows (CRLF) a Unix (LF) al ver el archivo en el navegador, y algunos navegadores guardan el archivo con terminaciones de línea incorrectas.

### Solución: Descargar Correctamente

#### Opción 1: Descargar el Archivo RAW (Recomendado) ✅

1. Haga clic en el archivo `Fix-UsbDkInstallation.ps1`
2. Haga clic en el botón **"Raw"** (arriba a la derecha)
3. **Clic derecho → Guardar como...** (NO copiar y pegar)
4. Guarde con el nombre exacto: `Fix-UsbDkInstallation.ps1`

**URL Directa para Descargar:**
```
https://raw.githubusercontent.com/EduardoA3677/UsbDk/copilot/fix-usbdk-installation-errors/Tools/Fix-UsbDkInstallation.ps1
```

#### Opción 2: Clonar el Repositorio

```bash
git clone https://github.com/EduardoA3677/UsbDk.git
cd UsbDk/Tools
```

Git preservará automáticamente los finales de línea correctos.

#### Opción 3: Descargar ZIP del Repositorio

1. Vaya a la página principal del repositorio
2. Haga clic en **"Code" → "Download ZIP"**
3. Extraiga el archivo ZIP
4. Los finales de línea se preservarán correctamente

### Verificar el Archivo

Después de descargar, ejecute:
```powershell
.\Validate-UsbDkScript.ps1
```

Este script verificará:
- ✅ Codificación del archivo (debe ser UTF-8 con BOM)
- ✅ Finales de línea (deben ser Windows CRLF)
- ✅ Sintaxis de PowerShell
- ✅ Balance de llaves
- ✅ Funciones requeridas

### Si los Finales de Línea son Incorrectos

Ejecute este comando en PowerShell:
```powershell
.\Fix-LineEndings.bat
```

O manualmente en PowerShell:
```powershell
$content = Get-Content Fix-UsbDkInstallation.ps1 -Raw
$content = $content -replace "`r?`n", "`r`n"
[System.IO.File]::WriteAllText("Fix-UsbDkInstallation.ps1", $content, [System.Text.Encoding]::UTF8)
```

---

## 🇺🇸 English

### Problem: Syntax Errors When Downloading

If you see errors like:
```
Missing closing brace "}" in statement block
Falta la llave de cierre "}" en el bloque de instrucciones
```

**Cause:** GitHub may convert Windows (CRLF) line endings to Unix (LF) when viewing files in the browser, and some browsers save the file with incorrect line endings.

### Solution: Download Correctly

#### Option 1: Download RAW File (Recommended) ✅

1. Click on the `Fix-UsbDkInstallation.ps1` file
2. Click the **"Raw"** button (top right)
3. **Right-click → Save as...** (DO NOT copy and paste)
4. Save with exact name: `Fix-UsbDkInstallation.ps1`

**Direct Download URL:**
```
https://raw.githubusercontent.com/EduardoA3677/UsbDk/copilot/fix-usbdk-installation-errors/Tools/Fix-UsbDkInstallation.ps1
```

#### Option 2: Clone the Repository

```bash
git clone https://github.com/EduardoA3677/UsbDk.git
cd UsbDk/Tools
```

Git will automatically preserve the correct line endings.

#### Option 3: Download Repository ZIP

1. Go to the main repository page
2. Click **"Code" → "Download ZIP"**
3. Extract the ZIP file
4. Line endings will be preserved correctly

### Verify the File

After downloading, run:
```powershell
.\Validate-UsbDkScript.ps1
```

This script will verify:
- ✅ File encoding (should be UTF-8 with BOM)
- ✅ Line endings (should be Windows CRLF)
- ✅ PowerShell syntax
- ✅ Brace balance
- ✅ Required functions

### If Line Endings are Incorrect

Run this command in PowerShell:
```powershell
.\Fix-LineEndings.bat
```

Or manually in PowerShell:
```powershell
$content = Get-Content Fix-UsbDkInstallation.ps1 -Raw
$content = $content -replace "`r?`n", "`r`n"
[System.IO.File]::WriteAllText("Fix-UsbDkInstallation.ps1", $content, [System.Text.Encoding]::UTF8)
```

---

## 📋 File Specifications

**Correct File Properties:**
- **Encoding:** UTF-8 with BOM (Byte Order Mark)
- **Line Endings:** Windows (CRLF - `\r\n`)
- **Size:** ~17 KB (16,987 bytes)
- **Lines:** 467 lines of code

**To Check File Properties:**

PowerShell:
```powershell
Get-Content Fix-UsbDkInstallation.ps1 -Raw | 
    Select-Object @{N='Size';E={$_.Length}},
                  @{N='HasCRLF';E={$_ -match "`r`n"}},
                  @{N='Lines';E={($_ -split "`n").Count}}
```

---

## ❌ Common Mistakes

### DON'T Do This:
- ❌ Copy code from browser and paste into file
- ❌ Open in Notepad and save (may change encoding)
- ❌ Use "Save Link As" without clicking Raw first
- ❌ Edit the file in an editor that changes line endings

### DO This Instead:
- ✅ Download from Raw link
- ✅ Use git clone
- ✅ Download ZIP file
- ✅ Verify with Validate-UsbDkScript.ps1
- ✅ Use Fix-LineEndings.bat if needed

---

## 🔧 Troubleshooting

### Error: "Token '}' inesperado" or "Unexpected token '}'"

**Solution:** Your file has Unix line endings. Run:
```batch
Fix-LineEndings.bat
```

### Error: "ParserError" or "ParseException"

**Solution:** File encoding or line endings are wrong. Re-download using Raw link.

### Error: File size is much smaller than expected

**Solution:** You downloaded an HTML page instead of the script. Use the Raw link.

### Script runs but does nothing

**Solution:** You may have downloaded a truncated file. Check file size should be ~17 KB.

---

## 📞 Still Having Issues?

1. Run `Validate-UsbDkScript.ps1` to diagnose the problem
2. Check the file size: should be approximately 17 KB
3. Verify line endings with: `(Get-Content Fix-UsbDkInstallation.ps1 -Raw) -match "`r`n"`
4. Re-download using the Raw link
5. If all else fails, clone the repository with git

---

**Last Updated:** 2026-02-02  
**Compatible with:** Windows PowerShell 5.1+, PowerShell Core 7+
