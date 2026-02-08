# Windows 11 25H2 Compatibility Update

## Overview

This document describes the updates made to the UsbDk driver to ensure full compatibility with Windows 11 25H2 using WDK 10.0.26100.0 and modern Windows APIs.

## Changes Made

### 1. KMDF Version Update

**Previous Version:** KMDF 1.15  
**New Version:** KMDF 1.25

KMDF 1.25 provides improved compatibility with Windows 10 version 2004+ and Windows 11, enabling the use of modern kernel APIs.

#### Files Modified:

- **UsbDk/UsbDk.vcxproj**
  - Updated all Win10 configurations (Win32 and x64, Debug and Release variants)
  - Changed `KMDF_VERSION_MINOR` from 15 to 25
  - Configurations: Win10 Debug, Win10 Release, Win10 Debug_NoSign

- **UsbDkHelper/UsbDkHelper.vcxproj**
  - Updated all Win10 configurations (Win32 and x64, Debug and Release variants)
  - Changed preprocessor definition `KMDF_VERSION_MINOR` from 11 to 25
  - Updated include paths from `kmdf\1.11` to `kmdf\1.25`

- **UsbDkHelper/UsbDk.inf**
  - Updated `KmdfLibraryVersion` from 1.15 to 1.25
  - Ensures consistency between driver binary and INF declaration

### 2. Modern API Usage

**ExAllocatePool2 API:**
- The driver now uses `ExAllocatePool2()` API throughout
- Requires Windows 10 version 2004 (20H1) or later
- Provides improved security and performance
- Helper function `PoolTypeToPoolFlags()` uses conditional logic instead of switch statements to avoid duplicate case errors when `NonPagedPool` and `NonPagedPoolNx` have the same value on Windows 8+

**Minimum Windows Version:**
- Windows 10 version 2004 (20H1, NTDDI_WIN10_MN)
- Windows 10 versions below 2004 are no longer supported
- Full support for Windows 11 all versions

### 3. Code Updates

**Alloc.h:**
- Updated `PoolTypeToPoolFlags()` to use conditional logic instead of switch
- Avoids "duplicate case value" compilation errors
- Uses `ExAllocatePool2()` for all allocations

**Memory Allocation Files:**
- `MemoryBuffer.h`: Uses `ExAllocatePool2()`
- `DeviceAccess.cpp`: Uses `ExAllocatePool2()`
- `FilterDevice.cpp`: Uses `ExAllocatePool2()`
- `UsbDkUtil.cpp`: Uses `ExAllocatePool2()`

## Technical Verification

### Memory Pool Allocation ✅

The driver uses modern, secure memory allocation APIs:

- **API:** `ExAllocatePool2()` (modern API for Windows 10 version 2004+)
- **Pool Type:** `NonPagedPoolNx` for Windows 8+ (non-executable memory)
- **Location:** `UsbDk/Alloc.h`, `UsbDk/MemoryBuffer.h`, and other source files

This provides:
- Enhanced security hardening against code injection
- Full compatibility with Windows 11 memory protection features
- Modern API usage as recommended by Microsoft

### Legacy Support

**Removed:** Support for Windows XP, 7, 8, and 8.1 has been removed.

**Minimum Requirements:**
- Windows 10 version 2004 (20H1, May 2020 Update) or later
- Windows 11 all versions fully supported

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
   The GitHub Actions workflow automatically builds and signs the driver.

## Compatibility Matrix

| OS Version | KMDF Version | Status |
|------------|--------------|--------|
| Windows 11 25H2 | 1.25 | ✅ Fully Supported |
| Windows 11 22H2 | 1.25 | ✅ Fully Supported |
| Windows 11 21H2 | 1.25 | ✅ Fully Supported |
| Windows 10 22H2 | 1.25 | ✅ Supported |
| Windows 10 21H2 | 1.25 | ✅ Supported |
| Windows 10 21H1 | 1.25 | ✅ Supported |
| Windows 10 20H2 | 1.25 | ✅ Supported |
| Windows 10 20H1 (2004) | 1.25 | ✅ Supported (Minimum) |
| Windows 10 <2004 | N/A | ❌ Not Supported |
| Windows 8.1 | N/A | ❌ Not Supported |
| Windows 8 | N/A | ❌ Not Supported |
| Windows 7 | N/A | ❌ Not Supported |
| Windows XP | N/A | ❌ Not Supported |

## Security Features

- ✅ Non-executable memory pools (NonPagedPoolNx)
- ✅ Modern allocation APIs (ExAllocatePool2)
- ✅ Proper driver signing support
- ✅ Windows 11 security model compliance
- ✅ No deprecated API usage

## References

- [WDK 10.0.26100.0 Documentation](https://docs.microsoft.com/en-us/windows-hardware/drivers/wdk/)
- [KMDF Version History](https://docs.microsoft.com/en-us/windows-hardware/drivers/wdf/kmdf-version-history)
- [ExAllocatePool2 Documentation](https://docs.microsoft.com/en-us/windows-hardware/drivers/ddi/wdm/nf-wdm-exallocatepool2)
- [Windows Driver Signing Requirements](https://docs.microsoft.com/en-us/windows-hardware/drivers/install/driver-signing)

## Changelog

**2026-02-08:**
- **BREAKING CHANGE:** Removed support for Windows XP, 7, 8, and 8.1
- Updated minimum Windows version to Windows 10 version 2004 (20H1, May 2020)
- Updated KMDF version from 1.15 to 1.25 for Win10 configurations
- Enabled ExAllocatePool2() API usage throughout the driver
- Fixed duplicate case value compilation errors in Alloc.h
- Simplified codebase by removing legacy OS conditional compilation
- Verified secure memory allocation APIs
- Full support for Windows 10 version 2004+ and Windows 11 all versions
