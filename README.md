[![Build Status](https://ci.appveyor.com/api/projects/status/p3s6bdbx8mq8o0hu?svg=true)](https://ci.appveyor.com/api/projects/status/p3s6bdbx8mq8o0hu?svg=true)

# UsbDk

UsbDk (USB Development Kit) is a open-source library for Windows meant
to provide user mode applications with direct and exclusive access to
USB devices by detaching those from Windows PNP manager and device drivers
and providing user mode with API for USB-specific operations on the device.

The library is intended to be as generic as possible, support  all types of
USB devices, bulk and isochronous transfers, composite devices etc.

Library supports all Windows OS versions starting from Windows XP/2003 through Windows 11.

**Windows 11 25H2 Compatible:** The driver has been verified to work with Windows 11 25H2 using WDK 10.0.26100.0 and KMDF 1.15. See [Windows11_25H2_Compatibility.md](Documentation/Windows11_25H2_Compatibility.md) for details.

## Documentation

* See ARCHITECTURE document in the source tree root.
* See Documentation folder in the source tree root.
* See UsbDkHelper\UsbDkHelper.h UsbDkHelper\UsbDkHelperHider.h for API documentation

## Building

**For detailed build and signing instructions, see [Documentation/BuildingAndSigning.md](Documentation/BuildingAndSigning.md)**

**Quick Start:**

### Automated Build (Recommended)
The repository includes a GitHub Actions workflow that automatically builds and signs everything:
- Go to Actions tab → "Build and Sign UsbDk" → "Run workflow"
- Download the "UsbDk-Signed-Release" artifact

### Local Build
Use the provided script (requires Administrator privileges):
```batch
build-and-sign.bat
```

### Manual Build
**Tools required:**

* Visual Studio 2015/Visual Studio 2015 Express update 3 or newer
* WDK 10
* Windows 10 SDK
* Wix Toolset V3.8+ (for building MSI installer)
* WDK 7.1 (for Windows XP/2003/Vista/2008 builds)

***Compilation***

Just open UsbDk.sln from the source tree root in Visual Studio 2015 and compile
desired configuration.

For signing drivers and creating signed MSI, see the detailed documentation.

## Installing and running

Use UsbDkController.exe to install/uninstall and verify basic operation.
Run UsbDkController.exe without parameters for command line options.

**Windows 11 Note:** The installer will automatically attempt to enable test signing mode
if installing an unsigned or self-signed driver. Administrator privileges are required,
and a reboot will be requested after enabling test signing mode.

## Known issues

* Installation on 64-bit versions of Windows 7 fails if security update
  [3033929](https://technet.microsoft.com/en-us/library/security/3033929)
  is not installed. Reason: UsbDk driver is signed by SHA-256 certificate. Without this update
  Windows 7 does not recognize the signature properly and fails to load the driver.

* On Windows 11 and Windows 10 (version 1607 and later), unsigned or self-signed drivers require
  additional configuration to load:
  - **AUTOMATIC**: The installer will automatically attempt to enable test signing mode when needed
  - For production use, drivers must be properly signed with a certificate from a trusted CA
  - Manual option: Enable test signing mode with `Bcdedit.exe -set TESTSIGNING ON` (requires reboot)
  - **Note**: Secure Boot may need to be disabled in UEFI settings for unsigned drivers
  - See Documentation/DriverSigning.txt for more details on driver signing requirements
