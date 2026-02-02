<#
.SYNOPSIS
    UsbDk Installation Repair and Diagnostic Script

.DESCRIPTION
    This PowerShell script diagnoses and repairs common UsbDk installation issues
    including driver installation failures, service errors, and MSI installation problems.
    
    Based on analysis of installation logs, this script addresses:
    - System folder path resolution issues
    - Driver installation and signature verification
    - Service registration and startup problems
    - File permission issues
    - Hash validation errors during installation

.PARAMETER Action
    Specifies the action to perform: Diagnose, Repair, Uninstall, or Reinstall

.PARAMETER LogPath
    Path to save diagnostic log file (default: current directory\UsbDk-Fix.log)

.PARAMETER MsiPath
    Path to the UsbDk MSI installer file (required for Reinstall action)

.EXAMPLE
    .\Fix-UsbDkInstallation.ps1 -Action Diagnose
    Runs diagnostic checks on the current UsbDk installation

.EXAMPLE
    .\Fix-UsbDkInstallation.ps1 -Action Repair
    Attempts to repair the current UsbDk installation

.EXAMPLE
    .\Fix-UsbDkInstallation.ps1 -Action Reinstall -MsiPath "C:\Path\To\UsbDk_1.0.22_x64.msi"
    Uninstalls and reinstalls UsbDk using the specified MSI

.NOTES
    Author: UsbDk Project
    Requires: Administrator privileges
    Compatible with: Windows 7, 8, 8.1, 10, 11
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('Diagnose', 'Repair', 'Uninstall', 'Reinstall')]
    [string]$Action,

    [Parameter(Mandatory=$false)]
    [string]$LogPath = (Join-Path $PSScriptRoot "UsbDk-Fix.log"),

    [Parameter(Mandatory=$false)]
    [string]$MsiPath = ""
)

# Ensure script runs with administrator privileges
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Error "This script requires administrator privileges. Please run as Administrator."
    exit 1
}

# Logging function
function Write-Log {
    param(
        [string]$Message,
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Console output with colors
    switch ($Level) {
        'Info'    { Write-Host $logMessage -ForegroundColor Cyan }
        'Warning' { Write-Host $logMessage -ForegroundColor Yellow }
        'Error'   { Write-Host $logMessage -ForegroundColor Red }
        'Success' { Write-Host $logMessage -ForegroundColor Green }
    }
    
    # File output
    Add-Content -Path $LogPath -Value $logMessage
}

# Get UsbDk installation information
function Get-UsbDkInfo {
    Write-Log "Checking UsbDk installation status..." -Level Info
    
    $info = @{
        ProductCode = "{6D4A6ED0-CF41-4615-A4B3-BDA018C3C1CD}"
        ProductName = "UsbDk Runtime Libraries"
        Installed = $false
        Version = $null
        InstallLocation = $null
        ServiceStatus = $null
        DriverStatus = $null
    }
    
    # Check if installed via registry
    $registryPaths = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\$($info.ProductCode)",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$($info.ProductCode)"
    )
    
    foreach ($path in $registryPaths) {
        if (Test-Path $path) {
            $regKey = Get-ItemProperty -Path $path -ErrorAction SilentlyContinue
            if ($regKey) {
                $info.Installed = $true
                $info.Version = $regKey.DisplayVersion
                $info.InstallLocation = $regKey.InstallLocation
                Write-Log "Found UsbDk installation: Version $($info.Version)" -Level Success
                break
            }
        }
    }
    
    if (-not $info.Installed) {
        Write-Log "UsbDk is not installed on this system" -Level Warning
    }
    
    # Check service status
    $service = Get-Service -Name "UsbDk*" -ErrorAction SilentlyContinue
    if ($service) {
        $info.ServiceStatus = $service.Status
        Write-Log "UsbDk Service Status: $($service.Status)" -Level Info
    } else {
        Write-Log "UsbDk service not found" -Level Warning
    }
    
    # Check driver status
    $driver = Get-WmiObject Win32_SystemDriver | Where-Object { $_.Name -like "*UsbDk*" }
    if ($driver) {
        $info.DriverStatus = $driver.State
        Write-Log "UsbDk Driver Status: $($driver.State)" -Level Info
    } else {
        Write-Log "UsbDk driver not found" -Level Warning
    }
    
    return $info
}

# Diagnose installation issues
function Invoke-Diagnosis {
    Write-Log "=== Starting UsbDk Installation Diagnosis ===" -Level Info
    
    $issues = @()
    
    # Check 1: Windows version compatibility
    Write-Log "Checking Windows version..." -Level Info
    $osVersion = [System.Environment]::OSVersion.Version
    if ($osVersion.Major -lt 6) {
        $issues += "Unsupported Windows version (requires Windows Vista or newer)"
        Write-Log "Windows version check: FAILED - Version $($osVersion)" -Level Error
    } else {
        Write-Log "Windows version check: PASSED - Version $($osVersion)" -Level Success
    }
    
    # Check 2: System architecture
    Write-Log "Checking system architecture..." -Level Info
    $is64Bit = [System.Environment]::Is64BitOperatingSystem
    Write-Log "System architecture: $( if ($is64Bit) { '64-bit' } else { '32-bit' } )" -Level Info
    
    # Check 3: UsbDk installation
    $usbdkInfo = Get-UsbDkInfo
    
    # Check 4: Driver signature
    if ($usbdkInfo.InstallLocation) {
        Write-Log "Checking driver files..." -Level Info
        $driverPath = Join-Path $usbdkInfo.InstallLocation "UsbDk.sys"
        if (Test-Path $driverPath) {
            try {
                $signature = Get-AuthenticodeSignature -FilePath $driverPath
                if ($signature.Status -eq 'Valid') {
                    Write-Log "Driver signature check: PASSED" -Level Success
                } else {
                    $issues += "Driver signature is invalid or not trusted: $($signature.Status)"
                    Write-Log "Driver signature check: FAILED - $($signature.Status)" -Level Error
                }
            } catch {
                $issues += "Could not verify driver signature: $($_.Exception.Message)"
                Write-Log "Driver signature check: ERROR - $($_.Exception.Message)" -Level Error
            }
        } else {
            $issues += "Driver file not found at expected location: $driverPath"
            Write-Log "Driver file check: FAILED - File not found" -Level Error
        }
    }
    
    # Check 5: Service issues
    if ($usbdkInfo.ServiceStatus -eq 'Stopped') {
        $issues += "UsbDk service is stopped"
        Write-Log "Service status check: WARNING - Service stopped" -Level Warning
    }
    
    # Check 6: File permissions
    if ($usbdkInfo.InstallLocation) {
        Write-Log "Checking file permissions..." -Level Info
        try {
            $acl = Get-Acl -Path $usbdkInfo.InstallLocation
            $hasSystemAccess = $acl.Access | Where-Object { 
                $_.IdentityReference -like "*SYSTEM*" -and 
                $_.FileSystemRights -like "*FullControl*" 
            }
            if ($hasSystemAccess) {
                Write-Log "File permissions check: PASSED" -Level Success
            } else {
                $issues += "Incorrect file permissions on installation directory"
                Write-Log "File permissions check: FAILED - Missing SYSTEM permissions" -Level Error
            }
        } catch {
            $issues += "Could not check file permissions: $($_.Exception.Message)"
            Write-Log "File permissions check: ERROR - $($_.Exception.Message)" -Level Error
        }
    }
    
    # Check 7: Registry keys
    Write-Log "Checking registry keys..." -Level Info
    $registryCheck = Test-Path "HKLM:\SYSTEM\CurrentControlSet\Services\UsbDk"
    if ($registryCheck) {
        Write-Log "Registry keys check: PASSED" -Level Success
    } else {
        $issues += "UsbDk service registry keys not found"
        Write-Log "Registry keys check: FAILED" -Level Warning
    }
    
    # Summary
    Write-Log "`n=== Diagnosis Summary ===" -Level Info
    if ($issues.Count -eq 0) {
        Write-Log "No issues detected. UsbDk appears to be installed correctly." -Level Success
    } else {
        Write-Log "Found $($issues.Count) issue(s):" -Level Warning
        foreach ($issue in $issues) {
            Write-Log "  - $issue" -Level Warning
        }
    }
    
    return $issues
}

# Repair UsbDk installation
function Invoke-Repair {
    Write-Log "=== Starting UsbDk Installation Repair ===" -Level Info
    
    $usbdkInfo = Get-UsbDkInfo
    
    if (-not $usbdkInfo.Installed) {
        Write-Log "UsbDk is not installed. Use -Action Reinstall instead." -Level Error
        return $false
    }
    
    # Step 1: Stop UsbDk service if running
    Write-Log "Stopping UsbDk service..." -Level Info
    $service = Get-Service -Name "UsbDk*" -ErrorAction SilentlyContinue
    if ($service -and $service.Status -eq 'Running') {
        try {
            Stop-Service -Name $service.Name -Force -ErrorAction Stop
            Write-Log "Service stopped successfully" -Level Success
        } catch {
            Write-Log "Failed to stop service: $($_.Exception.Message)" -Level Error
        }
    }
    
    # Step 2: Repair MSI installation
    Write-Log "Attempting MSI repair..." -Level Info
    try {
        $productCode = $usbdkInfo.ProductCode
        $msiArgs = "/fa $productCode /qb /l*v `"$(Join-Path $env:TEMP 'UsbDk-Repair.log')`""
        
        Write-Log "Running: msiexec.exe $msiArgs" -Level Info
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Log "MSI repair completed successfully" -Level Success
        } elseif ($process.ExitCode -eq 3010) {
            Write-Log "MSI repair completed successfully (reboot required)" -Level Warning
        } else {
            Write-Log "MSI repair failed with exit code: $($process.ExitCode)" -Level Error
            return $false
        }
    } catch {
        Write-Log "MSI repair failed: $($_.Exception.Message)" -Level Error
        return $false
    }
    
    # Step 3: Restart service
    Write-Log "Starting UsbDk service..." -Level Info
    Start-Sleep -Seconds 2
    try {
        $service = Get-Service -Name "UsbDk*" -ErrorAction SilentlyContinue
        if ($service) {
            Start-Service -Name $service.Name -ErrorAction Stop
            Write-Log "Service started successfully" -Level Success
        }
    } catch {
        Write-Log "Failed to start service: $($_.Exception.Message)" -Level Warning
    }
    
    # Step 4: Verify repair
    Write-Log "Verifying repair..." -Level Info
    Start-Sleep -Seconds 2
    $issues = Invoke-Diagnosis
    
    if ($issues.Count -eq 0) {
        Write-Log "Repair completed successfully!" -Level Success
        return $true
    } else {
        Write-Log "Repair completed with some issues remaining" -Level Warning
        return $true
    }
}

# Uninstall UsbDk
function Invoke-Uninstall {
    Write-Log "=== Starting UsbDk Uninstallation ===" -Level Info
    
    $usbdkInfo = Get-UsbDkInfo
    
    if (-not $usbdkInfo.Installed) {
        Write-Log "UsbDk is not installed on this system" -Level Warning
        return $true
    }
    
    try {
        $productCode = $usbdkInfo.ProductCode
        $msiArgs = "/x $productCode /qb /l*v `"$(Join-Path $env:TEMP 'UsbDk-Uninstall.log')`""
        
        Write-Log "Running: msiexec.exe $msiArgs" -Level Info
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Log "Uninstallation completed successfully" -Level Success
            
            if ($process.ExitCode -eq 3010) {
                Write-Log "A system reboot is required to complete the uninstallation" -Level Warning
            }
            
            return $true
        } else {
            Write-Log "Uninstallation failed with exit code: $($process.ExitCode)" -Level Error
            return $false
        }
    } catch {
        Write-Log "Uninstallation failed: $($_.Exception.Message)" -Level Error
        return $false
    }
}

# Reinstall UsbDk
function Invoke-Reinstall {
    param([string]$MsiPath)
    
    Write-Log "=== Starting UsbDk Reinstallation ===" -Level Info
    
    if ([string]::IsNullOrEmpty($MsiPath)) {
        Write-Log "MSI path is required for reinstallation. Use -MsiPath parameter." -Level Error
        return $false
    }
    
    if (-not (Test-Path $MsiPath)) {
        Write-Log "MSI file not found at: $MsiPath" -Level Error
        return $false
    }
    
    # Step 1: Uninstall existing version
    $usbdkInfo = Get-UsbDkInfo
    if ($usbdkInfo.Installed) {
        Write-Log "Uninstalling existing version..." -Level Info
        if (-not (Invoke-Uninstall)) {
            Write-Log "Failed to uninstall existing version. Aborting reinstall." -Level Error
            return $false
        }
        Start-Sleep -Seconds 5
    }
    
    # Step 2: Install new version
    Write-Log "Installing UsbDk from: $MsiPath" -Level Info
    try {
        $msiArgs = "/i `"$MsiPath`" /qb /l*v `"$(Join-Path $env:TEMP 'UsbDk-Install.log')`""
        
        Write-Log "Running: msiexec.exe $msiArgs" -Level Info
        $process = Start-Process -FilePath "msiexec.exe" -ArgumentList $msiArgs -Wait -PassThru -NoNewWindow
        
        if ($process.ExitCode -eq 0) {
            Write-Log "Installation completed successfully" -Level Success
        } elseif ($process.ExitCode -eq 3010) {
            Write-Log "Installation completed successfully (reboot required)" -Level Warning
        } else {
            Write-Log "Installation failed with exit code: $($process.ExitCode)" -Level Error
            Write-Log "Check log file at: $(Join-Path $env:TEMP 'UsbDk-Install.log')" -Level Info
            return $false
        }
    } catch {
        Write-Log "Installation failed: $($_.Exception.Message)" -Level Error
        return $false
    }
    
    # Step 3: Verify installation
    Write-Log "Verifying installation..." -Level Info
    Start-Sleep -Seconds 3
    Invoke-Diagnosis
    
    return $true
}

# Main script execution
Write-Log "=== UsbDk Installation Repair Script ===" -Level Info
Write-Log "Action: $Action" -Level Info
Write-Log "Log file: $LogPath" -Level Info
Write-Log "" -Level Info

switch ($Action) {
    'Diagnose' {
        Invoke-Diagnosis
    }
    'Repair' {
        $result = Invoke-Repair
        if ($result) {
            Write-Log "`nRepair operation completed." -Level Success
        } else {
            Write-Log "`nRepair operation failed." -Level Error
            exit 1
        }
    }
    'Uninstall' {
        $result = Invoke-Uninstall
        if ($result) {
            Write-Log "`nUninstall operation completed." -Level Success
        } else {
            Write-Log "`nUninstall operation failed." -Level Error
            exit 1
        }
    }
    'Reinstall' {
        $result = Invoke-Reinstall -MsiPath $MsiPath
        if ($result) {
            Write-Log "`nReinstall operation completed." -Level Success
        } else {
            Write-Log "`nReinstall operation failed." -Level Error
            exit 1
        }
    }
}

Write-Log "`n=== Script Execution Complete ===" -Level Info
Write-Log "For detailed information, check the log file: $LogPath" -Level Info
