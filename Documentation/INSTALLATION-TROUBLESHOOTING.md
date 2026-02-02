# UsbDk Installation Error Analysis and Solutions

## Executive Summary

This document analyzes UsbDk MSI installation issues identified in the `unpack.log` file and provides automated solutions to fix these errors.

## Installation Log Analysis

### General Information
- **Product**: UsbDk Runtime Libraries v1.0.22 (x64)
- **MSI File**: UsbDk_1.0.22_x64.msi
- **Product Code**: {6D4A6ED0-CF41-4615-A4B3-BDA018C3C1CD}
- **Date**: 02/02/2026 01:06:23
- **Action**: ADMIN (Administrative installation)

### Identified Errors

#### 1. Error 2756 - System Folder Issues
```
MSI (s) (C8:6C) [01:06:24:027]: Note: 1: 2756 2: System64Folder
MSI (s) (C8:6C) [01:06:24:028]: Note: 1: 2756 2: SystemFolder
```

**Cause**: The installer cannot correctly resolve System32 and System64 folder paths. This occurs when using `ACTION=ADMIN` with a custom `TARGETDIR`.

**Impact**: The installer attempts to copy files to system locations but cannot determine the correct paths.

#### 2. Error 3 - SECREPAIR: Hash Calculation Failure
```
MSI (s) (C8:6C) [01:06:24:078]: SECREPAIR: Failed to open the file:C:\Users\ralva\Downloads\xx\UsbDk for computing its hash. Error:3
MSI (s) (C8:6C) [01:06:24:078]: SECUREREPAIR: Failed to CreateContentHash of the file: xx\UsbDk: for computing its hash. Error: 3
```

**Cause**: 
- The installer tries to open a file or directory called "UsbDk" that doesn't exist
- Error 3 in Windows means "The system cannot find the path specified"
- This occurs during creation of the security hash database for future repairs

**Impact**: Secure repair functionality won't work correctly, although installation continues.

#### 3. Incorrect Administrative Installation
```
Command Line: TARGETDIR=C:\Users\ralva\Downloads\xx ACTION=ADMIN CURRENTDIRECTORY=C:\Users\ralva\Downloads CLIENTUILEVEL=2 CLIENTPROCESSID=3528
```

**Cause**: An administrative installation (`ACTION=ADMIN`) is being run instead of a normal installation. This unpacks the MSI to a network location but doesn't actually install the drivers.

**Impact**: Files are copied but drivers are not registered with Windows and services don't start.

### Final Installation Status

Despite the errors, the log shows:
```
MSI (s) (C8:6C) [01:06:24:882]: Product: UsbDk Runtime Libraries -- Installation completed successfully.
```

However, this only means the administrative installation completed (files copied), not that the system is functionally installed.

## Common Installation Issues

### 1. Unsigned Drivers
On 64-bit Windows 7 without security update [3033929](https://technet.microsoft.com/en-us/library/security/3033929), the UsbDk driver (signed with SHA-256) is not recognized properly.

### 2. Services Not Started
The UsbDk service may not start automatically after installation due to:
- Insufficient permissions
- Missing driver files
- Conflicts with other USB drivers

### 3. Permission Errors
Installation requires elevated privileges and full SYSTEM permissions on the installation directory.

## Implemented Solutions

### PowerShell Repair Script

The `Fix-UsbDkInstallation.ps1` script provides the following functionality:

#### 1. Complete Diagnosis
```powershell
.\Fix-UsbDkInstallation.ps1 -Action Diagnose
```

Checks:
- ✅ Compatible Windows version
- ✅ System architecture (32/64 bit)
- ✅ UsbDk installation status
- ✅ Driver digital signature
- ✅ UsbDk service status
- ✅ System driver status
- ✅ File permissions
- ✅ Service registry keys

#### 2. Automatic Repair
```powershell
.\Fix-UsbDkInstallation.ps1 -Action Repair
```

Performs:
1. Stops UsbDk service if running
2. Runs MSI repair (`msiexec.exe /fa`)
3. Restarts UsbDk service
4. Verifies repair with full diagnosis

#### 3. Clean Uninstall
```powershell
.\Fix-UsbDkInstallation.ps1 -Action Uninstall
```

Removes completely:
- Installation files
- Registered services
- System drivers
- Registry entries

#### 4. Complete Reinstallation
```powershell
.\Fix-UsbDkInstallation.ps1 -Action Reinstall -MsiPath "C:\Path\To\UsbDk_1.0.22_x64.msi"
```

Process:
1. Uninstalls existing version
2. Installs new version from specified MSI
3. Verifies installation with diagnosis

### Batch Interface Script

The `Fix-UsbDkInstallation.bat` file provides a simple interactive menu:

```
1. Diagnose UsbDk Installation
2. Repair UsbDk Installation
3. Uninstall UsbDk
4. Reinstall UsbDk (requires MSI file)
5. Exit
```

## Usage Instructions

### Prerequisites
1. Windows 7 or later
2. Administrator privileges
3. PowerShell 3.0 or later
4. For reinstallation: UsbDk MSI file

### Steps to Repair Installation

#### Method 1: Use Batch Script (Easiest)

1. Download both files:
   - `Fix-UsbDkInstallation.ps1`
   - `Fix-UsbDkInstallation.bat`

2. Place them in the same folder

3. Right-click `Fix-UsbDkInstallation.bat` and select "Run as administrator"

4. Select desired option from menu

#### Method 2: Use PowerShell Directly

1. Open PowerShell as administrator

2. Navigate to folder containing the script:
   ```powershell
   cd C:\Path\To\Scripts
   ```

3. Run diagnosis first:
   ```powershell
   .\Fix-UsbDkInstallation.ps1 -Action Diagnose
   ```

4. Repair if issues found:
   ```powershell
   .\Fix-UsbDkInstallation.ps1 -Action Repair
   ```

5. Or reinstall completely if needed:
   ```powershell
   .\Fix-UsbDkInstallation.ps1 -Action Reinstall -MsiPath "C:\Downloads\UsbDk_1.0.22_x64.msi"
   ```

### Additional Troubleshooting

#### If PowerShell script won't run

You may need to change PowerShell execution policy:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### If installation requires reboot

Some driver changes require a system restart. The script will inform you if necessary.

#### If service issues persist

Try starting the service manually:

```powershell
# Check status
Get-Service -Name "UsbDk*"

# Start service
Start-Service -Name "UsbDk"

# Configure automatic startup
Set-Service -Name "UsbDk" -StartupType Automatic
```

## Logs and Debugging

### Log File Locations

1. **Repair Script Log**:
   - Location: Same directory as script
   - Name: `UsbDk-Fix.log`

2. **MSI Logs**:
   - Repair: `%TEMP%\UsbDk-Repair.log`
   - Install: `%TEMP%\UsbDk-Install.log`
   - Uninstall: `%TEMP%\UsbDk-Uninstall.log`

3. **Windows Event Viewer**:
   - Application: Look for UsbDk-related events
   - System: Look for driver errors

### Common MSI Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 3010 | Success (reboot required) |
| 1602 | Installation canceled by user |
| 1603 | Fatal error during installation |
| 1618 | Another installation already in progress |
| 1638 | Another version already installed |

## Manual Installation Fixes

If automated scripts don't work, try these manual steps:

### 1. Complete Manual Uninstall

```powershell
# Uninstall via product code
msiexec.exe /x {6D4A6ED0-CF41-4615-A4B3-BDA018C3C1CD} /qb

# Or via MSI file
msiexec.exe /x "C:\Path\To\UsbDk_1.0.22_x64.msi" /qb
```

### 2. Normal (Non-Administrative) Installation

```powershell
# Standard installation
msiexec.exe /i "C:\Path\To\UsbDk_1.0.22_x64.msi" /qb /l*v "C:\Temp\install.log"
```

**IMPORTANT**: Do not use `ACTION=ADMIN` or custom `TARGETDIR` unless creating an administrative installation image.

### 3. Force Repair

```powershell
# Repair all files
msiexec.exe /fa {6D4A6ED0-CF41-4615-A4B3-BDA018C3C1CD} /qb

# Or reinstall if registration missing
msiexec.exe /fvomus {6D4A6ED0-CF41-4615-A4B3-BDA018C3C1CD} /qb
```

### 4. Verify Driver Signature (Windows 7 Only)

On Windows 7, ensure KB3033929 update is installed:

```powershell
# Check if installed
Get-HotFix -Id KB3033929

# If not installed, download from Windows Update
```

## Additional Support

If problems persist after using these scripts:

1. Review generated log files
2. Run diagnosis and save output
3. Check Windows Event Viewer for system errors
4. Contact UsbDk development team with:
   - Windows version
   - System architecture
   - Complete log files
   - Diagnosis output

## References

- UsbDk Repository: https://github.com/daynix/UsbDk
- WiX Toolset Documentation: https://wixtoolset.org/
- MSI Command Line Reference: https://docs.microsoft.com/en-us/windows/win32/msi/command-line-options
- Security Update KB3033929: https://support.microsoft.com/en-us/kb/3033929

## License

This script is provided under the same license as the UsbDk project (see LICENSE file in repository).

---

**Note**: This document and scripts were created based on analysis of the provided `unpack.log` file. If you encounter additional issues not covered here, please contribute your findings to the project.
