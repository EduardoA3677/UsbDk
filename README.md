[![Build Status](https://ci.appveyor.com/api/projects/status/p3s6bdbx8mq8o0hu?svg=true)](https://ci.appveyor.com/api/projects/status/p3s6bdbx8mq8o0hu?svg=true)

# UsbDk

UsbDk (USB Development Kit) is a open-source library for Windows meant
to provide user mode applications with direct and exclusive access to
USB devices by detaching those from Windows PNP manager and device drivers
and providing user mode with API for USB-specific operations on the device.

The library is intended to be as generic as possible, support  all types of
USB devices, bulk and isochronous transfers, composite devices etc.

Library supports all Windows OS versions starting from Windows XP/2003.

## Documentation

* See ARCHITECTURE document in the source tree root.
* See Documentation folder in the source tree root.
* See UsbDkHelper\UsbDkHelper.h UsbDkHelper\UsbDkHelperHider.h for API documentation

## Building

**Tools required:**

* Visual Studio 2015/Visual Studio 2015 Express update 3 or newer
* WDK 10
* Windows 10 SDK
* Wix Toolset V3.8 (for building MSI installer)
* WDK 7.1 (for Windows XP/2003/Vista/2008 builds)

***Compilation***

Just open UsbDk.sln from the source tree root in Visual Studio 2015 and compile
desired configuration.

## Installing and running

Use UsbDkController.exe to install/uninstall and verify basic operation.
Run UsbDkController.exe without parameters for command line options.

### Troubleshooting Installation Issues

If you encounter problems during installation, use the automated repair tools in the `Tools/` directory:

**Quick Fix (Windows):**
1. Run `Tools\Fix-UsbDkInstallation.bat` as Administrator
2. Select option 1 to diagnose issues
3. Select option 2 to repair the installation

**Advanced Usage:**
```powershell
# Diagnose installation
.\Tools\Fix-UsbDkInstallation.ps1 -Action Diagnose

# Repair installation
.\Tools\Fix-UsbDkInstallation.ps1 -Action Repair

# Reinstall completely
.\Tools\Fix-UsbDkInstallation.ps1 -Action Reinstall -MsiPath "C:\Path\To\UsbDk.msi"
```

For detailed troubleshooting information, see:
* [Installation Troubleshooting Guide (English)](Documentation/INSTALLATION-TROUBLESHOOTING.md)
* [Guía de Solución de Problemas (Español)](Documentation/INSTALLATION-TROUBLESHOOTING-ES.md)

## Known issues

* Installation on 64-bit versions of Windows 7 fails if security update
  [3033929](https://technet.microsoft.com/en-us/library/security/3033929)
  is not installed. Reason: UsbDk driver is signed by SHA-256 certificate. Without this update
  Windows 7 does not recognize the signature properly and fails to load the driver.
