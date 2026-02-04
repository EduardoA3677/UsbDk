@echo off
REM Build and Sign UsbDk Locally
REM Requires: Visual Studio, WDK, WiX Toolset

echo ================================
echo UsbDk Local Build and Sign Script
echo ================================
echo.

REM Check for administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo ERROR: This script requires Administrator privileges
    echo Please run as Administrator
    pause
    exit /b 1
)

REM Configuration
set CERT_NAME=UsbDkTestCert
set CERT_PASSWORD=TestPassword123!
set BUILD_CONFIG=Release
set BUILD_PLATFORM=x64

echo Step 1: Generating test certificate...
echo ======================================

REM Create certificate using PowerShell
powershell -Command ^
    "$cert = New-SelfSignedCertificate -Type CodeSigningCert -Subject 'CN=UsbDk Test Certificate, O=Test, C=US' -KeyAlgorithm RSA -KeyLength 2048 -HashAlgorithm SHA256 -CertStoreLocation 'Cert:\CurrentUser\My' -KeyExportPolicy Exportable -NotAfter (Get-Date).AddYears(2); ^
    $pfxPath = '%CD%\%CERT_NAME%.pfx'; ^
    $password = ConvertTo-SecureString -String '%CERT_PASSWORD%' -Force -AsPlainText; ^
    Export-PfxCertificate -Cert $cert -FilePath $pfxPath -Password $password | Out-Null; ^
    $cerPath = '%CD%\%CERT_NAME%.cer'; ^
    Export-Certificate -Cert $cert -FilePath $cerPath | Out-Null; ^
    Write-Host 'Certificate created: ' $cert.Thumbprint"

if not exist "%CERT_NAME%.pfx" (
    echo ERROR: Failed to create certificate
    pause
    exit /b 1
)

echo Certificate generated successfully
echo.

echo Step 2: Installing certificate to Trusted Root...
echo =================================================
certutil -addstore "Root" "%CERT_NAME%.cer"
certutil -addstore "TrustedPublisher" "%CERT_NAME%.cer"
echo.

echo Step 3: Building solution...
echo ============================
msbuild UsbDk.sln /p:Configuration=%BUILD_CONFIG% /p:Platform=%BUILD_PLATFORM% /m
if %errorLevel% neq 0 (
    echo ERROR: Build failed
    pause
    exit /b 1
)
echo Build completed successfully
echo.

echo Step 4: Signing driver files...
echo ================================

REM Sign .sys files
for /r %%f in (UsbDk.sys) do (
    if exist "%%f" (
        echo Signing: %%f
        signtool sign /f "%CERT_NAME%.pfx" /p "%CERT_PASSWORD%" /fd SHA256 /t http://timestamp.digicert.com "%%f"
    )
)

REM Sign .dll files
for /r %%f in (UsbDkHelper.dll) do (
    if exist "%%f" (
        echo Signing: %%f
        signtool sign /f "%CERT_NAME%.pfx" /p "%CERT_PASSWORD%" /fd SHA256 /t http://timestamp.digicert.com "%%f"
    )
)

REM Sign .exe files
for /r %%f in (UsbDkController.exe UsbDkInstHelper.exe) do (
    if exist "%%f" (
        echo Signing: %%f
        signtool sign /f "%CERT_NAME%.pfx" /p "%CERT_PASSWORD%" /fd SHA256 /t http://timestamp.digicert.com "%%f"
    )
)

echo Driver files signed successfully
echo.

echo Step 5: Building MSI installer...
echo ==================================
cd Tools\Installer

REM Build with WiX
candle.exe UsbDkInstaller.wxs -dUsbDk64Bit=yes -dConfig=%BUILD_CONFIG% -dUsbDkVersion=1.0.22 -arch x64
if %errorLevel% neq 0 (
    echo ERROR: WiX candle failed
    cd ..\..
    pause
    exit /b 1
)

light.exe UsbDkInstaller.wixobj -out ..\..\UsbDk_x64_signed.msi -ext WixUIExtension
if %errorLevel% neq 0 (
    echo ERROR: WiX light failed
    cd ..\..
    pause
    exit /b 1
)

cd ..\..
echo MSI built successfully
echo.

echo Step 6: Signing MSI installer...
echo =================================
signtool sign /f "%CERT_NAME%.pfx" /p "%CERT_PASSWORD%" /fd SHA256 /d "UsbDk Runtime Libraries" /t http://timestamp.digicert.com "UsbDk_x64_signed.msi"
if %errorLevel% neq 0 (
    echo ERROR: Failed to sign MSI
    pause
    exit /b 1
)

echo MSI signed successfully
echo.

echo Step 7: Creating release package...
echo ====================================
if not exist "Release_Package" mkdir Release_Package
copy "UsbDk_x64_signed.msi" "Release_Package\"
copy "%CERT_NAME%.cer" "Release_Package\InstallCertificate.cer"

REM Create installation instructions
(
echo UsbDk Test-Signed Release
echo ========================
echo.
echo Installation Steps:
echo 1. Install certificate: certutil -addstore "Root" InstallCertificate.cer
echo 2. Enable test signing: bcdedit /set testsigning on
echo 3. Reboot computer
echo 4. Install MSI: UsbDk_x64_signed.msi
) > "Release_Package\README.txt"

echo Release package created in Release_Package\
echo.

echo ================================
echo BUILD AND SIGN COMPLETED!
echo ================================
echo.
echo Output files:
echo - UsbDk_x64_signed.msi (Signed installer)
echo - %CERT_NAME%.pfx (Certificate - keep secure!)
echo - %CERT_NAME%.cer (Public certificate)
echo - Release_Package\ (Complete release package)
echo.
echo IMPORTANT: 
echo - Enable test signing mode: bcdedit /set testsigning on
echo - Reboot before installing the driver
echo.

pause
