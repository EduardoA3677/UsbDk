# Fix-UsbDkInstallation.ps1
# PowerShell script to fix UsbDk service installation issues
# This script can help resolve problems with UsbDk driver service and USB port functionality

#Requires -RunAsAdministrator

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [switch]$UninstallOnly,
    
    [Parameter(Mandatory=$false)]
    [switch]$CleanRegistry
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Function to write colored output
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Function to find UsbDkController.exe
function Find-UsbDkController {
    $possiblePaths = @(
        "${env:ProgramFiles}\UsbDk Runtime Library\UsbDkController.exe",
        "${env:ProgramFiles(x86)}\UsbDk Runtime Library\UsbDkController.exe",
        "$PSScriptRoot\UsbDkController.exe"
    )
    
    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            return $path
        }
    }
    return $null
}

# Function to check if UsbDk service exists
function Test-UsbDkService {
    try {
        $service = Get-Service -Name "UsbDk" -ErrorAction SilentlyContinue
        return $null -ne $service
    } catch {
        return $false
    }
}

# Function to check if UsbDk driver is installed
function Test-UsbDkDriver {
    $driverPath = "$env:SystemRoot\System32\drivers\UsbDk.sys"
    return Test-Path $driverPath
}

# Function to stop UsbDk service
function Stop-UsbDkService {
    try {
        if (Test-UsbDkService) {
            Write-ColorOutput "Stopping UsbDk service..." "Yellow"
            $service = Get-Service -Name "UsbDk" -ErrorAction SilentlyContinue
            if ($service.Status -eq "Running") {
                Stop-Service -Name "UsbDk" -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
                Write-ColorOutput "UsbDk service stopped successfully." "Green"
            } else {
                Write-ColorOutput "UsbDk service is not running." "Gray"
            }
        }
    } catch {
        Write-ColorOutput "Warning: Could not stop UsbDk service: $_" "Yellow"
    }
}

# Function to uninstall UsbDk
function Uninstall-UsbDk {
    param([string]$ControllerPath)
    
    Write-ColorOutput "`nUninstalling UsbDk..." "Yellow"
    
    try {
        if ($ControllerPath -and (Test-Path $ControllerPath)) {
            Write-ColorOutput "Using UsbDkController.exe to uninstall..." "Cyan"
            $process = Start-Process -FilePath $ControllerPath -ArgumentList "-u" -Wait -PassThru -NoNewWindow
            
            if ($process.ExitCode -eq 0) {
                Write-ColorOutput "UsbDk uninstalled successfully." "Green"
                return $true
            } else {
                Write-ColorOutput "UsbDkController.exe returned exit code: $($process.ExitCode)" "Yellow"
            }
        } else {
            Write-ColorOutput "UsbDkController.exe not found. Attempting manual cleanup..." "Yellow"
        }
        
        # If controller is not available or failed, try manual cleanup
        Stop-UsbDkService
        
        # Check if driver file still exists
        $UsbDkSys = "$env:SystemRoot\System32\drivers\UsbDk.sys"
        if (Test-Path $UsbDkSys) {
            Write-ColorOutput "Driver file still exists at: $UsbDkSys" "Yellow"
            Write-ColorOutput "You may need to manually delete it after reboot." "Yellow"
        }
        
        return $true
        
    } catch {
        Write-ColorOutput "Error during uninstallation: $_" "Red"
        return $false
    }
}

# Function to clean UsbDk registry entries
function Remove-UsbDkRegistryEntries {
    Write-ColorOutput "`nCleaning UsbDk registry entries..." "Yellow"
    
    try {
        # Path to USB device class registry
        $usbClassPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{36FC9E60-C465-11CF-8056-444553540000}"
        
        if (Test-Path $usbClassPath) {
            Write-ColorOutput "Checking for UsbDk UpperFilters..." "Cyan"
            
            $upperFilters = Get-ItemProperty -Path $usbClassPath -Name "UpperFilters" -ErrorAction SilentlyContinue
            
            if ($upperFilters -and $upperFilters.UpperFilters) {
                $filters = $upperFilters.UpperFilters
                Write-ColorOutput "Current UpperFilters: $($filters -join ', ')" "Gray"
                
                # Remove UsbDk from filters
                $newFilters = $filters | Where-Object { $_ -ne "UsbDk" }
                
                if ($newFilters.Count -lt $filters.Count) {
                    if ($newFilters.Count -eq 0) {
                        Write-ColorOutput "Removing UpperFilters registry value..." "Yellow"
                        Remove-ItemProperty -Path $usbClassPath -Name "UpperFilters" -ErrorAction SilentlyContinue
                    } else {
                        Write-ColorOutput "Updating UpperFilters without UsbDk..." "Yellow"
                        Set-ItemProperty -Path $usbClassPath -Name "UpperFilters" -Value $newFilters
                    }
                    Write-ColorOutput "UsbDk removed from UpperFilters." "Green"
                } else {
                    Write-ColorOutput "UsbDk not found in UpperFilters." "Gray"
                }
            } else {
                Write-ColorOutput "No UpperFilters found." "Gray"
            }
        } else {
            Write-ColorOutput "USB class registry path not found." "Yellow"
        }
        
        Write-ColorOutput "Registry cleanup completed." "Green"
        return $true
        
    } catch {
        Write-ColorOutput "Error cleaning registry: $_" "Red"
        return $false
    }
}

# Function to enable USB storage
function Enable-UsbStorage {
    Write-ColorOutput "`nEnabling USB storage..." "Yellow"
    
    try {
        $usbStorPath = "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR"
        
        if (Test-Path $usbStorPath) {
            # Set Start to 3 (SERVICE_DEMAND_START - manual start, allows USB storage to work)
            Set-ItemProperty -Path $usbStorPath -Name "Start" -Value 3 -ErrorAction Stop
            Write-ColorOutput "USB storage enabled." "Green"
        } else {
            Write-ColorOutput "USBSTOR service registry key not found." "Yellow"
        }
    } catch {
        Write-ColorOutput "Could not enable USB storage: $_" "Yellow"
    }
}

# Main script execution
try {
    Write-ColorOutput "`n========================================" "Cyan"
    Write-ColorOutput "  UsbDk Installation Fix Utility" "Cyan"
    Write-ColorOutput "========================================`n" "Cyan"
    
    # Check if running as administrator
    if (-not (Test-Administrator)) {
        Write-ColorOutput "ERROR: This script must be run as Administrator!" "Red"
        Write-ColorOutput "Please right-click and select 'Run as Administrator'" "Yellow"
        exit 1
    }
    
    Write-ColorOutput "Running as Administrator: OK" "Green"
    
    # Check current UsbDk status
    Write-ColorOutput "`nChecking UsbDk installation status..." "Cyan"
    
    $serviceExists = Test-UsbDkService
    $driverExists = Test-UsbDkDriver
    $controllerPath = Find-UsbDkController
    
    if ($serviceExists) {
        Write-ColorOutput "UsbDk service: Found" "Yellow"
    } else {
        Write-ColorOutput "UsbDk service: Not found" "Gray"
    }
    
    if ($driverExists) {
        Write-ColorOutput "UsbDk driver: Found" "Yellow"
    } else {
        Write-ColorOutput "UsbDk driver: Not found" "Gray"
    }
    
    if ($controllerPath) {
        Write-ColorOutput "UsbDkController.exe: Found at $controllerPath" "Green"
    } else {
        Write-ColorOutput "UsbDkController.exe: Not found" "Yellow"
    }
    
    # Perform requested actions
    if ($serviceExists -or $driverExists) {
        Write-ColorOutput "`nUsbDk installation detected. Proceeding with fix..." "Yellow"
        
        $uninstallSuccess = Uninstall-UsbDk -ControllerPath $controllerPath
        
        if (-not $uninstallSuccess) {
            Write-ColorOutput "`nWarning: Uninstallation may not have completed successfully." "Yellow"
        }
    } else {
        Write-ColorOutput "`nNo UsbDk installation found." "Gray"
    }
    
    # Clean registry if requested or if issues found
    if ($CleanRegistry -or $serviceExists -or $driverExists) {
        $registryCleanSuccess = Remove-UsbDkRegistryEntries
        
        if (-not $registryCleanSuccess) {
            Write-ColorOutput "`nWarning: Registry cleanup may not have completed successfully." "Yellow"
        }
    }
    
    # Enable USB storage
    Enable-UsbStorage
    
    # Final recommendations
    Write-ColorOutput "`n========================================" "Cyan"
    Write-ColorOutput "  Completion Summary" "Cyan"
    Write-ColorOutput "========================================`n" "Cyan"
    
    if ($UninstallOnly) {
        Write-ColorOutput "UsbDk has been uninstalled." "Green"
    } else {
        Write-ColorOutput "Fix operations completed." "Green"
    }
    
    Write-ColorOutput "`nRecommendations:" "Yellow"
    Write-ColorOutput "1. Restart your computer to complete the changes" "White"
    Write-ColorOutput "2. After restart, test your USB devices" "White"
    Write-ColorOutput "3. If you want to reinstall UsbDk, download the latest version" "White"
    Write-ColorOutput "   from: https://github.com/daynix/UsbDk" "White"
    
    Write-ColorOutput "`nScript completed successfully!" "Green"
    
} catch {
    Write-ColorOutput "`nFATAL ERROR: $($_.Exception.Message)" "Red"
    Write-ColorOutput "Stack Trace: $($_.ScriptStackTrace)" "Red"
    exit 1
} finally {
    Write-ColorOutput ""
}
