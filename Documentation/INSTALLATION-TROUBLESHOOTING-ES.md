# Análisis de Errores de Instalación de UsbDk y Soluciones

## Resumen Ejecutivo

Este documento analiza los problemas de instalación del MSI de UsbDk identificados en el archivo de registro `unpack.log` y proporciona soluciones automatizadas para corregir estos errores.

## Análisis del Log de Instalación

### Información General
- **Producto**: UsbDk Runtime Libraries v1.0.22 (x64)
- **Archivo MSI**: UsbDk_1.0.22_x64.msi
- **Código de Producto**: {6D4A6ED0-CF41-4615-A4B3-BDA018C3C1CD}
- **Usuario**: ralva
- **Fecha**: 02/02/2026 01:06:23
- **Acción**: ADMIN (Instalación administrativa)

### Errores Identificados

#### 1. Error 2756 - Problemas con Carpetas del Sistema
```
MSI (s) (C8:6C) [01:06:24:027]: Note: 1: 2756 2: System64Folder
MSI (s) (C8:6C) [01:06:24:028]: Note: 1: 2756 2: SystemFolder
```

**Causa**: El instalador no puede resolver correctamente las rutas de las carpetas System32 y System64. Esto ocurre cuando se usa `ACTION=ADMIN` con un `TARGETDIR` personalizado.

**Impacto**: El instalador intenta copiar archivos a ubicaciones del sistema pero no puede determinar las rutas correctas.

#### 2. Error 3 - SECREPAIR: Fallo al Calcular Hash
```
MSI (s) (C8:6C) [01:06:24:078]: SECREPAIR: Failed to open the file:C:\Users\ralva\Downloads\xx\UsbDk for computing its hash. Error:3
MSI (s) (C8:6C) [01:06:24:078]: SECUREREPAIR: Failed to CreateContentHash of the file: xx\UsbDk: for computing its hash. Error: 3
```

**Causa**: 
- El instalador intenta abrir un archivo o directorio llamado "UsbDk" que no existe
- Error 3 en Windows significa "El sistema no puede encontrar la ruta especificada"
- Esto ocurre durante la creación de la base de datos de hash de seguridad para reparaciones futuras

**Impacto**: La función de reparación segura no funcionará correctamente, aunque la instalación continúa.

#### 3. Instalación Administrativa Incorrecta
```
Command Line: TARGETDIR=C:\Users\ralva\Downloads\xx ACTION=ADMIN CURRENTDIRECTORY=C:\Users\ralva\Downloads CLIENTUILEVEL=2 CLIENTPROCESSID=3528
```

**Causa**: Se está ejecutando una instalación administrativa (`ACTION=ADMIN`) en lugar de una instalación normal. Esto descomprime el MSI en una ubicación de red pero no instala realmente los controladores.

**Impacto**: Los archivos se copian pero los controladores no se registran con Windows y los servicios no se inician.

### Estado Final de la Instalación

A pesar de los errores, el registro muestra:
```
MSI (s) (C8:6C) [01:06:24:882]: Product: UsbDk Runtime Libraries -- Installation completed successfully.
```

Sin embargo, esto solo significa que la instalación administrativa se completó (los archivos se copiaron), no que el sistema esté funcionalmente instalado.

## Problemas Comunes de Instalación

### 1. Controladores No Firmados
En Windows 7 de 64 bits sin la actualización de seguridad [3033929](https://technet.microsoft.com/en-us/library/security/3033929), el controlador UsbDk (firmado con SHA-256) no se reconoce correctamente.

### 2. Servicios No Iniciados
El servicio UsbDk puede no iniciarse automáticamente después de la instalación debido a:
- Permisos insuficientes
- Archivos de controlador faltantes
- Conflictos con otros controladores USB

### 3. Errores de Permisos
La instalación requiere privilegios elevados y permisos SYSTEM completos en el directorio de instalación.

## Soluciones Implementadas

### Script de Reparación PowerShell

El script `Fix-UsbDkInstallation.ps1` proporciona las siguientes funcionalidades:

#### 1. Diagnóstico Completo
```powershell
.\Fix-UsbDkInstallation.ps1 -Action Diagnose
```

Verifica:
- ✅ Versión de Windows compatible
- ✅ Arquitectura del sistema (32/64 bits)
- ✅ Estado de instalación de UsbDk
- ✅ Firma digital del controlador
- ✅ Estado del servicio UsbDk
- ✅ Estado del controlador del sistema
- ✅ Permisos de archivos
- ✅ Claves de registro del servicio

#### 2. Reparación Automática
```powershell
.\Fix-UsbDkInstallation.ps1 -Action Repair
```

Ejecuta:
1. Detiene el servicio UsbDk si está en ejecución
2. Ejecuta reparación MSI (`msiexec.exe /fa`)
3. Reinicia el servicio UsbDk
4. Verifica la reparación con diagnóstico completo

#### 3. Desinstalación Limpia
```powershell
.\Fix-UsbDkInstallation.ps1 -Action Uninstall
```

Elimina completamente:
- Archivos de instalación
- Servicios registrados
- Controladores del sistema
- Entradas del registro

#### 4. Reinstalación Completa
```powershell
.\Fix-UsbDkInstallation.ps1 -Action Reinstall -MsiPath "C:\Ruta\Al\UsbDk_1.0.22_x64.msi"
```

Proceso:
1. Desinstala la versión existente
2. Instala la nueva versión desde el MSI especificado
3. Verifica la instalación con diagnóstico

### Script Batch de Interfaz

El archivo `Fix-UsbDkInstallation.bat` proporciona un menú interactivo simple:

```
1. Diagnosticar instalación de UsbDk
2. Reparar instalación de UsbDk
3. Desinstalar UsbDk
4. Reinstalar UsbDk (requiere archivo MSI)
5. Salir
```

## Instrucciones de Uso

### Requisitos Previos
1. Windows 7 o posterior
2. Privilegios de administrador
3. PowerShell 3.0 o posterior
4. Para reinstalación: archivo MSI de UsbDk

### Pasos para Reparar la Instalación

#### Método 1: Usar el Script Batch (Más Fácil)

1. Descargue ambos archivos:
   - `Fix-UsbDkInstallation.ps1`
   - `Fix-UsbDkInstallation.bat`

2. Colóquelos en la misma carpeta

3. Haga clic derecho en `Fix-UsbDkInstallation.bat` y seleccione "Ejecutar como administrador"

4. Seleccione la opción deseada del menú

#### Método 2: Usar PowerShell Directamente

1. Abra PowerShell como administrador

2. Navegue a la carpeta que contiene el script:
   ```powershell
   cd C:\Ruta\A\Los\Scripts
   ```

3. Ejecute el diagnóstico primero:
   ```powershell
   .\Fix-UsbDkInstallation.ps1 -Action Diagnose
   ```

4. Repare si se encuentran problemas:
   ```powershell
   .\Fix-UsbDkInstallation.ps1 -Action Repair
   ```

5. O reinstale completamente si es necesario:
   ```powershell
   .\Fix-UsbDkInstallation.ps1 -Action Reinstall -MsiPath "C:\Downloads\UsbDk_1.0.22_x64.msi"
   ```

### Solución de Problemas Adicionales

#### Si el script de PowerShell no se ejecuta

Puede que necesite cambiar la política de ejecución de PowerShell:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Si la instalación requiere reinicio

Algunos cambios de controladores requieren un reinicio del sistema. El script le informará si es necesario.

#### Si persisten los problemas del servicio

Intente iniciar manualmente el servicio:

```powershell
# Verificar estado
Get-Service -Name "UsbDk*"

# Iniciar servicio
Start-Service -Name "UsbDk"

# Configurar inicio automático
Set-Service -Name "UsbDk" -StartupType Automatic
```

## Registros y Depuración

### Ubicaciones de Archivos de Registro

1. **Registro del Script de Reparación**:
   - Ubicación: Mismo directorio que el script
   - Nombre: `UsbDk-Fix.log`

2. **Registros de MSI**:
   - Diagnóstico: `%TEMP%\UsbDk-Repair.log`
   - Instalación: `%TEMP%\UsbDk-Install.log`
   - Desinstalación: `%TEMP%\UsbDk-Uninstall.log`

3. **Visor de Eventos de Windows**:
   - Aplicación: Busque eventos relacionados con UsbDk
   - Sistema: Busque errores de controladores

### Códigos de Salida de MSI Comunes

| Código | Significado |
|--------|-------------|
| 0 | Éxito |
| 3010 | Éxito (requiere reinicio) |
| 1602 | Instalación cancelada por el usuario |
| 1603 | Error fatal durante la instalación |
| 1618 | Otra instalación ya en progreso |
| 1638 | Ya está instalada otra versión |

## Correcciones para Instalación Manual

Si los scripts automatizados no funcionan, puede intentar estos pasos manuales:

### 1. Desinstalación Manual Completa

```powershell
# Desinstalar mediante código de producto
msiexec.exe /x {6D4A6ED0-CF41-4615-A4B3-BDA018C3C1CD} /qb

# O mediante archivo MSI
msiexec.exe /x "C:\Ruta\A\UsbDk_1.0.22_x64.msi" /qb
```

### 2. Instalación Normal (No Administrativa)

```powershell
# Instalación estándar
msiexec.exe /i "C:\Ruta\A\UsbDk_1.0.22_x64.msi" /qb /l*v "C:\Temp\install.log"
```

**IMPORTANTE**: No use `ACTION=ADMIN` o `TARGETDIR` personalizado a menos que esté creando una imagen de instalación administrativa.

### 3. Reparación Forzada

```powershell
# Reparar todos los archivos
msiexec.exe /fa {6D4A6ED0-CF41-4615-A4B3-BDA018C3C1CD} /qb

# O reinstalar si falta el registro
msiexec.exe /fvomus {6D4A6ED0-CF41-4615-A4B3-BDA018C3C1CD} /qb
```

### 4. Verificar Firma del Controlador (Solo Windows 7)

En Windows 7, asegúrese de tener instalada la actualización KB3033929:

```powershell
# Verificar si está instalada
Get-HotFix -Id KB3033929

# Si no está instalada, descárguela de Windows Update
```

## Soporte Adicional

Si los problemas persisten después de usar estos scripts:

1. Revise los archivos de registro generados
2. Ejecute el diagnóstico y guarde la salida
3. Verifique el Visor de Eventos de Windows para errores del sistema
4. Contacte al equipo de desarrollo de UsbDk con:
   - Versión de Windows
   - Arquitectura del sistema
   - Archivos de registro completos
   - Salida del diagnóstico

## Referencias

- Repositorio de UsbDk: https://github.com/daynix/UsbDk
- Documentación de WiX Toolset: https://wixtoolset.org/
- Referencia de línea de comandos de MSI: https://docs.microsoft.com/en-us/windows/win32/msi/command-line-options
- Actualización de seguridad KB3033929: https://support.microsoft.com/en-us/kb/3033929

## Licencia

Este script se proporciona bajo la misma licencia que el proyecto UsbDk (consulte el archivo LICENSE en el repositorio).

---

**Nota**: Este documento y los scripts fueron creados basándose en el análisis del archivo de registro `unpack.log` proporcionado. Si encuentra problemas adicionales no cubiertos aquí, contribuya con sus hallazgos al proyecto.
