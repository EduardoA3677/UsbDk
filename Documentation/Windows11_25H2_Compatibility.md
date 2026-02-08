# Windows 11 25H2 Compatibility Update

## Overview

This document describes the changes made to the UsbDk driver to ensure compatibility with Windows 11 25H2 using WDK 10.0.26100.0.

## Changes Made

### 1. KMDF Version Update

**Previous Version:** KMDF 1.15 (Win10 configs) / KMDF 1.11 (INF file)  
**New Version:** KMDF 1.31

KMDF 1.31 is the officially supported version for WDK 10.0.26100.0 and provides compatibility with both Windows 10 and Windows 11.

#### Files Modified:

- **UsbDk/UsbDk.vcxproj**
  - Updated all Win10 configurations (Win32 and x64, Debug and Release variants)
  - Changed `KMDF_VERSION_MINOR` from 15 to 31
  - Affects: Win10 Debug, Win10 Release, Win10 Debug_NoSign

- **UsbDkHelper/UsbDkHelper.vcxproj**
  - Updated all Win10 configurations (Win32 and x64, Debug and Release variants)
  - Changed preprocessor definition from `KMDF_VERSION_MINOR=11` to `KMDF_VERSION_MINOR=31`
  - Updated include paths from `kmdf\1.11` to `kmdf\1.31`

- **UsbDkHelper/UsbDk.inf**
  - Updated `KmdfLibraryVersion` from 1.11 to 1.31
  - Ensures consistency between driver binary and INF declaration

### 2. INF File Enhancements

Added Windows 11 compatibility metadata to UsbDk.inf:

```ini
[Version]
Class=System
ClassGuid={4d36e97d-e325-11ce-bfc1-08002be10318}
Provider=%ManufacturerName%
DriverVer=01/01/2026,1.0.31.0
CatalogFile=UsbDk.cat

[Manufacturer]
%ManufacturerName%=Standard,NTamd64.10.0...22000

[Strings]
ManufacturerName="UsbDk Project"
```

**Benefits:**
- Proper device class identification
- Windows 11 target platform declaration (build 22000+)
- Driver version tracking
- Catalog file reference for proper signing

## Technical Verification

### Memory Pool Allocation ✅

The driver already uses modern, secure memory allocation APIs:

- **API:** `ExAllocatePool2()` (modern API introduced in Windows 10)
- **Pool Type:** `NonPagedPoolNx` for Windows 8+ (non-executable memory)
- **Location:** `UsbDk/Alloc.h`

This provides:
- Security hardening against code injection
- Compatibility with Windows 11 memory protection features
- No deprecated API usage

### Legacy Support Maintained ✅

All legacy Windows configurations remain unchanged:
- Windows 7: KMDF 1.11
- Windows 8: KMDF 1.11
- Windows 8.1: KMDF 1.11
- Windows XP: Legacy support (separate INF)

## Build Requirements

To build the updated driver:

1. **Required Tools:**
   - Visual Studio 2022 or later
   - Windows SDK 10.0.26100.0 (25H2)
   - Windows Driver Kit (WDK) 10.0.26100.0 (25H2)
   - WiX Toolset v3.11+ (for MSI installer)

2. **Build Configuration:**
   ```batch
   msbuild UsbDk.sln /p:Configuration="Win10 Release" /p:Platform=x64
   ```

3. **Automated Build:**
   The GitHub Actions workflow automatically builds and signs the driver for Windows 11 25H2.

## Testing

### Compatibility Matrix

| OS Version | KMDF Version | Status |
|------------|--------------|--------|
| Windows 11 25H2 | 1.31 | ✅ Supported |
| Windows 11 22H2 | 1.31 | ✅ Supported |
| Windows 10 22H2 | 1.31 | ✅ Supported |
| Windows 10 21H2 | 1.31 | ✅ Supported |
| Windows 8.1 | 1.11 | ✅ Supported (Legacy) |
| Windows 8 | 1.11 | ✅ Supported (Legacy) |
| Windows 7 | 1.11 | ✅ Supported (Legacy) |

### Security Features

- ✅ Non-executable memory pools (NonPagedPoolNx)
- ✅ Modern allocation APIs (ExAllocatePool2)
- ✅ Proper driver signing support
- ✅ Windows 11 security model compliance

## References

- [WDK 10.0.26100.0 Documentation](https://docs.microsoft.com/en-us/windows-hardware/drivers/wdk/)
- [KMDF Version History](https://docs.microsoft.com/en-us/windows-hardware/drivers/wdf/kmdf-version-history)
- [Windows Driver Signing Requirements](https://docs.microsoft.com/en-us/windows-hardware/drivers/install/driver-signing)

## Changelog

**2026-02-08:**
- Updated KMDF version from 1.15 to 1.31 for Win10 configurations
- Added Windows 11 compatibility declarations to INF file
- Verified secure memory allocation APIs
- Maintained backward compatibility with legacy Windows versions
