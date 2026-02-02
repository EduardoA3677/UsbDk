# UsbDk Installation Repair Tools - Quick Start Guide

## Overview

This directory contains automated tools to diagnose and repair UsbDk installation issues on Windows.

## Files

- **Fix-UsbDkInstallation.ps1** - PowerShell script with repair functionality
- **Fix-UsbDkInstallation.bat** - Interactive batch menu (easiest to use)

## Quick Start

### Option 1: Interactive Menu (Recommended)

1. Right-click `Fix-UsbDkInstallation.bat`
2. Select "Run as Administrator"
3. Choose from the menu:
   - `1` - Diagnose installation issues
   - `2` - Repair UsbDk installation
   - `3` - Uninstall UsbDk
   - `4` - Reinstall UsbDk (requires MSI file)

### Option 2: PowerShell Direct

Open PowerShell as Administrator and run:

```powershell
# Diagnose issues
.\Fix-UsbDkInstallation.ps1 -Action Diagnose

# Repair installation
.\Fix-UsbDkInstallation.ps1 -Action Repair

# Uninstall
.\Fix-UsbDkInstallation.ps1 -Action Uninstall

# Reinstall (provide MSI path)
.\Fix-UsbDkInstallation.ps1 -Action Reinstall -MsiPath "C:\Path\To\UsbDk.msi"
```

## What the Scripts Do

### Diagnose Mode
- Checks Windows version compatibility
- Verifies UsbDk installation status
- Tests driver digital signature
- Monitors service status
- Validates file permissions
- Checks registry keys
- Generates detailed report

### Repair Mode
- Stops UsbDk service
- Runs MSI repair operation
- Restarts service
- Verifies repair success
- Logs all operations

### Uninstall Mode
- Cleanly removes UsbDk
- Unregisters services
- Removes drivers
- Cleans registry

### Reinstall Mode
- Uninstalls existing version
- Installs new version from MSI
- Verifies installation
- Starts services

## Requirements

- Windows 7 or later
- Administrator privileges
- PowerShell 3.0+ (pre-installed on Windows 8+)
- For reinstall: UsbDk MSI installer file

## Troubleshooting

### "Scripts are disabled on this system"

If you see a PowerShell execution policy error, run:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Log Files

Check these locations for detailed logs:

- Script log: `UsbDk-Fix.log` (same directory as script)
- MSI logs: `%TEMP%\UsbDk-*.log`
- Windows Event Viewer: Application and System logs

## Documentation

For comprehensive troubleshooting information, see:

- **English**: `../Documentation/INSTALLATION-TROUBLESHOOTING.md`
- **Español**: `../Documentation/INSTALLATION-TROUBLESHOOTING-ES.md`

## Common Issues Addressed

1. **Error 2756** - System folder path resolution
2. **Error 3** - File hash computation failures
3. **Service not starting** - Permission and registration issues
4. **Driver signature errors** - Especially on Windows 7
5. **Incomplete installations** - Administrative install mode issues

## Support

If problems persist:

1. Run diagnosis and save the output
2. Check generated log files
3. Review Windows Event Viewer
4. Contact UsbDk support with:
   - Windows version and architecture
   - Complete log files
   - Diagnosis output

## License

These tools are provided under the same license as UsbDk (see LICENSE in repository root).
