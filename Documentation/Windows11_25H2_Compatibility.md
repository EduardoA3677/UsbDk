# Windows 11 25H2 Compatibility Update

## Overview

This document describes the fix applied to the UsbDk driver to resolve KMDF version mismatch and ensure compatibility with Windows 11 25H2 using WDK 10.0.26100.0.

## Issue

The UsbDk driver project configuration (UsbDk.vcxproj) was using KMDF 1.15 for Windows 10 configurations, but the INF file (UsbDk.inf) declared KMDF 1.11. This version mismatch could cause installation and runtime issues.

## Fix Applied

**File Modified:** `UsbDkHelper/UsbDk.inf`

**Change:** Updated `KmdfLibraryVersion` from 1.11 to 1.15

This ensures the INF file matches the actual KMDF version used by the driver, as configured in the project files.

### KMDF Version Information

- **KMDF 1.15** is the correct and supported version for Windows 10 target (0x0A00) with WDK 10.0.26100.0
- **KMDF 1.31** is NOT supported for Windows10 TargetVersion - attempting to use it causes build error: "Unknown or unsupported property value '1.31' for KmdfVersion for target OS 'Windows10'"
- The driver supports both Windows 10 and Windows 11 using KMDF 1.15

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

To build the driver:

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
| Windows 11 25H2 | 1.15 | ✅ Supported |
| Windows 11 22H2 | 1.15 | ✅ Supported |
| Windows 10 22H2 | 1.15 | ✅ Supported |
| Windows 10 21H2 | 1.15 | ✅ Supported |
| Windows 8.1 | 1.11 | ✅ Supported (Legacy) |
| Windows 8 | 1.11 | ✅ Supported (Legacy) |
| Windows 7 | 1.11 | ✅ Supported (Legacy) |

## Security Features

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
- Fixed KMDF version mismatch between UsbDk.vcxproj (1.15) and UsbDk.inf (1.11)
- Updated INF KmdfLibraryVersion to 1.15 to match driver configuration
- KMDF 1.15 is the correct version for Windows 10/11 with WDK 10.0.26100.0
- Verified secure memory allocation APIs (ExAllocatePool2 with NonPagedPoolNx)
- Maintained backward compatibility with legacy Windows versions
