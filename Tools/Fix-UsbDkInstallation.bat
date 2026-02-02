@echo off
REM UsbDk Installation Fix Tool - Batch Wrapper
REM Script para corregir instalacion de UsbDk / Script to fix UsbDk installation

echo.
echo ===============================================================
echo    UsbDk Installation Fix Tool / Herramienta de Reparacion
echo ===============================================================
echo.

REM Check for admin privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: Este script requiere privilegios de administrador
    echo ERROR: This script requires administrator privileges
    echo.
    echo Por favor, ejecute como administrador / Please run as administrator:
    echo 1. Clic derecho en este archivo / Right-click this file
    echo 2. Seleccione "Ejecutar como administrador" / Select "Run as administrator"
    echo.
    pause
    exit /b 1
)

echo Iniciando reparacion de UsbDk...
echo Starting UsbDk repair...
echo.

REM Get the script directory
set "SCRIPT_DIR=%~dp0"

REM Check if PowerShell script exists
if not exist "%SCRIPT_DIR%Fix-UsbDkInstallation.ps1" (
    echo ERROR: No se encuentra Fix-UsbDkInstallation.ps1
    echo ERROR: Fix-UsbDkInstallation.ps1 not found
    echo.
    echo El archivo debe estar en: / File should be in:
    echo %SCRIPT_DIR%
    echo.
    pause
    exit /b 1
)

REM Run PowerShell script
echo Ejecutando script de PowerShell...
echo Running PowerShell script...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%Fix-UsbDkInstallation.ps1" %*

set EXIT_CODE=%errorLevel%

echo.
echo ===============================================================
if %EXIT_CODE% equ 0 (
    echo    Proceso completado exitosamente / Process completed successfully
) else (
    echo    Proceso completado con errores / Process completed with errors
    echo    Codigo de salida / Exit code: %EXIT_CODE%
)
echo ===============================================================
echo.
echo Presione cualquier tecla para salir / Press any key to exit...
pause >nul

exit /b %EXIT_CODE%
