# Building and Signing UsbDk

This document explains how to build and sign UsbDk drivers and installer.

## Overview

UsbDk requires code signing for the drivers (.sys files) and the MSI installer. This can be done with:
1. **Test certificates** (for development/testing)
2. **Production certificates** (for distribution - requires WHQL or attestation signing)

## Automated Build (GitHub Actions)

### GitHub Actions Workflow

The repository includes a GitHub Actions workflow that automatically:
- Generates a self-signed test certificate
- Builds all components
- Signs all driver files (.sys, .dll, .exe)
- Creates a signed MSI installer
- Packages everything for distribution

**To trigger the workflow:**

1. Push to main/master/develop branch, OR
2. Create a pull request, OR
3. Manually trigger from Actions tab → "Build and Sign UsbDk" → "Run workflow"

**Workflow outputs:**
- `UsbDk-Signed-Release` artifact containing:
  - `UsbDk_x64_signed.msi` - Signed installer
  - `InstallCertificate.cer` - Test certificate
  - `Install_Certificate.bat` - Helper script
  - `README_INSTALLATION.txt` - Installation instructions

### Downloading Build Artifacts

1. Go to the "Actions" tab in GitHub
2. Click on the latest successful workflow run
3. Download the "UsbDk-Signed-Release" artifact
4. Extract the ZIP file

## Local Build with Signing

### Prerequisites

**Required Tools:**
- Visual Studio 2015 or newer
- Windows Driver Kit (WDK) 10
- Windows 10 SDK
- WiX Toolset v3.11 or newer
- Administrator privileges (for certificate installation and signing)

### Quick Build Script

Use the provided `build-and-sign.bat` script:

```batch
# Run as Administrator
build-and-sign.bat
```

This script will:
1. Generate a test certificate
2. Install it to the trusted store
3. Build the solution
4. Sign all binaries
5. Create signed MSI
6. Package for distribution

### Manual Build Steps

#### 1. Generate Test Certificate

```powershell
# Run PowerShell as Administrator
$cert = New-SelfSignedCertificate `
  -Type CodeSigningCert `
  -Subject "CN=UsbDk Test Certificate, O=YourOrg, C=US" `
  -KeyAlgorithm RSA `
  -KeyLength 2048 `
  -HashAlgorithm SHA256 `
  -CertStoreLocation "Cert:\CurrentUser\My" `
  -KeyExportPolicy Exportable `
  -NotAfter (Get-Date).AddYears(2)

# Export to PFX (for signing)
$password = ConvertTo-SecureString -String "YourPassword" -Force -AsPlainText
Export-PfxCertificate -Cert $cert -FilePath "UsbDkTestCert.pfx" -Password $password

# Export to CER (for distribution)
Export-Certificate -Cert $cert -FilePath "UsbDkTestCert.cer"
```

#### 2. Install Certificate

```batch
# Run as Administrator
certutil -addstore "Root" UsbDkTestCert.cer
certutil -addstore "TrustedPublisher" UsbDkTestCert.cer
```

#### 3. Build Solution

```batch
msbuild UsbDk.sln /p:Configuration=Release /p:Platform=x64 /m
```

#### 4. Sign Driver Files

```batch
# Sign .sys driver
signtool sign /f UsbDkTestCert.pfx /p YourPassword /fd SHA256 /t http://timestamp.digicert.com "path\to\UsbDk.sys"

# Sign DLL
signtool sign /f UsbDkTestCert.pfx /p YourPassword /fd SHA256 /t http://timestamp.digicert.com "path\to\UsbDkHelper.dll"

# Sign executables
signtool sign /f UsbDkTestCert.pfx /p YourPassword /fd SHA256 /t http://timestamp.digicert.com "path\to\UsbDkController.exe"
```

#### 5. Build MSI

```batch
cd Tools\Installer

# Compile WiX
candle.exe UsbDkInstaller.wxs -dUsbDk64Bit=yes -dConfig=Release -dUsbDkVersion=1.0.22 -arch x64

# Link MSI
light.exe UsbDkInstaller.wixobj -out UsbDk_x64_signed.msi -ext WixUIExtension
```

#### 6. Sign MSI

```batch
signtool sign /f UsbDkTestCert.pfx /p YourPassword /fd SHA256 /d "UsbDk Runtime Libraries" /t http://timestamp.digicert.com "UsbDk_x64_signed.msi"
```

#### 7. Verify Signatures

```batch
# Verify driver signature
signtool verify /pa /v "path\to\UsbDk.sys"

# Verify MSI signature
signtool verify /pa /v "UsbDk_x64_signed.msi"
```

## Production Signing (WHQL/Attestation)

For production/distribution, test certificates are not sufficient. You need:

### Option 1: WHQL Certification (Recommended)
1. Join the [Windows Hardware Developer Program](https://docs.microsoft.com/en-us/windows-hardware/drivers/dashboard/)
2. Submit driver for WHQL certification
3. Microsoft signs your driver with their production certificate
4. Driver works on all Windows systems without test mode

### Option 2: Attestation Signing
1. Join the Windows Hardware Developer Program
2. Submit driver for attestation signing
3. Receive attestation-signed driver
4. Works on Windows 10+ without test mode (may not work on older Windows versions)

### Steps for Production Signing:

1. **Prepare Driver Package:**
   ```batch
   # Build release version
   msbuild UsbDk.sln /p:Configuration=Release /p:Platform=x64
   ```

2. **Create HLK/HCK Test Results:**
   - Run Hardware Lab Kit tests
   - Generate test results package

3. **Submit to Partner Center:**
   - Create submission package
   - Upload to Windows Hardware Partner Center
   - Wait for Microsoft signing

4. **Download Signed Driver:**
   - Download production-signed driver
   - Replace files in installer package

5. **Sign MSI with EV Certificate:**
   ```batch
   # Use EV certificate from trusted CA
   signtool sign /sha1 <cert-thumbprint> /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 "UsbDk_x64.msi"
   ```

## Installing Test-Signed Drivers

### For Users Installing Test-Signed Builds:

1. **Install Certificate:**
   ```batch
   # Run as Administrator
   certutil -addstore "Root" InstallCertificate.cer
   certutil -addstore "TrustedPublisher" InstallCertificate.cer
   ```

2. **Enable Test Signing Mode:**
   ```batch
   # Run as Administrator
   bcdedit /set testsigning on
   ```

3. **Reboot Computer**

4. **Install MSI:**
   ```batch
   msiexec /i UsbDk_x64_signed.msi
   ```
   Or double-click the MSI file.

### For Windows 11 with Secure Boot:

If test-signed drivers still won't load:
1. Disable Secure Boot in UEFI/BIOS settings
2. Reboot
3. Verify test signing mode is on
4. Install driver

## Troubleshooting

### "Driver signature cannot be verified"
- Ensure certificate is installed in Root and TrustedPublisher stores
- Enable test signing mode
- Reboot after enabling test signing

### "Code 52: Windows cannot verify the digital signature"
- Check that files are actually signed: `signtool verify /pa /v filename.sys`
- Re-sign with correct certificate
- Ensure timestamp server is accessible

### "The hash for the file is not present in the specified catalog file"
- Driver not properly signed
- Re-sign the driver files
- Verify signature with signtool

### Build Errors
- **"Cannot find WiX"**: Install WiX Toolset and add to PATH
- **"Cannot find signtool"**: Install Windows SDK
- **"Access Denied"**: Run as Administrator

## Security Considerations

### Test Certificates
⚠️ **NEVER distribute test-signed drivers to end users**
- Test certificates are for development only
- They compromise system security when installed
- Users must enable test signing mode (reduces security)

### Certificate Management
- **Keep .pfx files secure** - they contain private keys
- **Use strong passwords** for .pfx files
- **Store production certificates in HSM** (Hardware Security Module)
- **Never commit certificates to source control** (added to .gitignore)

### For Production
- Always use proper WHQL or attestation signing
- Use EV certificates for MSI signing
- Follow Microsoft's driver signing requirements
- Keep private keys in secure hardware

## References

- [Driver Signing Requirements](https://docs.microsoft.com/en-us/windows-hardware/drivers/install/driver-signing)
- [Test Signing](https://docs.microsoft.com/en-us/windows-hardware/drivers/install/test-signing)
- [Windows Hardware Dev Center Dashboard](https://partner.microsoft.com/dashboard/hardware/search)
- [SignTool Documentation](https://docs.microsoft.com/en-us/windows/win32/seccrypto/signtool)
- [WiX Toolset](https://wixtoolset.org/)
