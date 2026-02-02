@echo off
REM UsbDk Installation Repair Script - Batch Wrapper
REM This script provides a simple interface to run the PowerShell repair script

setlocal EnableDelayedExpansion

echo ============================================
echo  UsbDk Installation Repair Tool
echo ============================================
echo.

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires administrator privileges.
    echo Please right-click and select "Run as Administrator"
    echo.
    pause
    exit /b 1
)

:MENU
echo Please select an option:
echo.
echo 1. Diagnose UsbDk Installation
echo 2. Repair UsbDk Installation  
echo 3. Uninstall UsbDk
echo 4. Reinstall UsbDk (requires MSI file)
echo 5. Exit
echo.
set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" goto DIAGNOSE
if "%choice%"=="2" goto REPAIR
if "%choice%"=="3" goto UNINSTALL
if "%choice%"=="4" goto REINSTALL
if "%choice%"=="5" goto EXIT
goto MENU

:DIAGNOSE
echo.
echo Running diagnosis...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Fix-UsbDkInstallation.ps1" -Action Diagnose
goto CONTINUE

:REPAIR
echo.
echo Running repair...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Fix-UsbDkInstallation.ps1" -Action Repair
goto CONTINUE

:UNINSTALL
echo.
echo Running uninstall...
set /p confirm="Are you sure you want to uninstall UsbDk? (Y/N): "
if /i "%confirm%"=="Y" (
    powershell.exe -ExecutionPolicy Bypass -File "%~dp0Fix-UsbDkInstallation.ps1" -Action Uninstall
)
goto CONTINUE

:REINSTALL
echo.
set /p msipath="Enter the full path to the UsbDk MSI file: "
if not exist "%msipath%" (
    echo ERROR: MSI file not found at specified path
    goto CONTINUE
)
echo Running reinstall...
powershell.exe -ExecutionPolicy Bypass -File "%~dp0Fix-UsbDkInstallation.ps1" -Action Reinstall -MsiPath "%msipath%"
goto CONTINUE

:CONTINUE
echo.
echo ============================================
echo.
pause
cls
goto MENU

:EXIT
echo.
echo Exiting...
exit /b 0
