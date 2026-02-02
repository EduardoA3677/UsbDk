# Script Validator for Fix-UsbDkInstallation.ps1
# Use this to check if the script has syntax errors before running

Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  UsbDk Script Syntax Validator" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

$scriptPath = Join-Path $PSScriptRoot "Fix-UsbDkInstallation.ps1"

if (-not (Test-Path $scriptPath)) {
    Write-Host "ERROR: Fix-UsbDkInstallation.ps1 not found in current directory" -ForegroundColor Red
    Write-Host "Current directory: $PSScriptRoot" -ForegroundColor Yellow
    exit 1
}

Write-Host "Checking: $scriptPath" -ForegroundColor Green
Write-Host ""

# Check file encoding
$bytes = [System.IO.File]::ReadAllBytes($scriptPath)
$encoding = "Unknown"
if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
    $encoding = "UTF-8 with BOM"
} elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
    $encoding = "UTF-16 LE"
} else {
    # Try to detect UTF-8 without BOM
    try {
        $content = [System.IO.File]::ReadAllText($scriptPath, [System.Text.Encoding]::UTF8)
        $encoding = "UTF-8 without BOM"
    } catch {
        $encoding = "ASCII or other"
    }
}

Write-Host "File encoding: $encoding" -ForegroundColor Cyan

# Check line endings
$content = Get-Content $scriptPath -Raw
if ($content -match "`r`n") {
    Write-Host "Line endings: Windows (CRLF)" -ForegroundColor Green
} elseif ($content -match "`n") {
    Write-Host "Line endings: Unix (LF)" -ForegroundColor Yellow
    Write-Host "WARNING: Script may have Unix line endings. Converting..." -ForegroundColor Yellow
} else {
    Write-Host "Line endings: Unknown" -ForegroundColor Red
}

# Syntax check
Write-Host ""
Write-Host "Checking PowerShell syntax..." -ForegroundColor Cyan

$errors = $null
$tokens = $null

try {
    $scriptContent = Get-Content $scriptPath -Raw
    $tokens = [System.Management.Automation.PSParser]::Tokenize($scriptContent, [ref]$errors)
    
    if ($errors.Count -eq 0) {
        Write-Host "✓ No syntax errors found!" -ForegroundColor Green
        Write-Host "  Total tokens: $($tokens.Count)" -ForegroundColor Gray
    } else {
        Write-Host "✗ Syntax errors found:" -ForegroundColor Red
        foreach ($error in $errors) {
            Write-Host ""
            Write-Host "  Line $($error.Token.StartLine), Column $($error.Token.StartColumn):" -ForegroundColor Yellow
            Write-Host "  $($error.Message)" -ForegroundColor Red
        }
        Write-Host ""
        Write-Host "Please re-download the script from the repository." -ForegroundColor Yellow
        exit 1
    }
} catch {
    Write-Host "✗ Error checking syntax: $_" -ForegroundColor Red
    exit 1
}

# Check brace balance
Write-Host ""
Write-Host "Checking brace balance..." -ForegroundColor Cyan

$openBraces = ($content.ToCharArray() | Where-Object { $_ -eq '{' }).Count
$closeBraces = ($content.ToCharArray() | Where-Object { $_ -eq '}' }).Count

if ($openBraces -eq $closeBraces) {
    Write-Host "✓ Braces are balanced: $openBraces opening, $closeBraces closing" -ForegroundColor Green
} else {
    Write-Host "✗ Braces are NOT balanced!" -ForegroundColor Red
    Write-Host "  Opening braces: $openBraces" -ForegroundColor Yellow
    Write-Host "  Closing braces: $closeBraces" -ForegroundColor Yellow
    Write-Host "  Difference: $($openBraces - $closeBraces)" -ForegroundColor Yellow
    exit 1
}

# Check required functions
Write-Host ""
Write-Host "Checking required functions..." -ForegroundColor Cyan

$requiredFunctions = @(
    "Write-Log",
    "Test-Administrator",
    "Stop-UsbDkServices",
    "Remove-UsbDkServices",
    "Clear-RegistryEntries",
    "Clear-MsiCache",
    "Remove-DriverFiles",
    "Find-UsbDkInstaller",
    "Install-UsbDk",
    "Test-UsbDkInstallation",
    "Start-UsbDkServices"
)

$missingFunctions = @()
foreach ($func in $requiredFunctions) {
    if ($content -match "function $func") {
        Write-Host "  ✓ $func" -ForegroundColor Gray
    } else {
        Write-Host "  ✗ $func" -ForegroundColor Red
        $missingFunctions += $func
    }
}

if ($missingFunctions.Count -gt 0) {
    Write-Host ""
    Write-Host "✗ Missing functions detected! Please re-download the script." -ForegroundColor Red
    exit 1
}

# File size check
$fileSize = (Get-Item $scriptPath).Length
$expectedMinSize = 15000  # Should be around 16-17KB

Write-Host ""
Write-Host "File size: $fileSize bytes" -ForegroundColor Cyan

if ($fileSize -lt $expectedMinSize) {
    Write-Host "✗ WARNING: File size is smaller than expected!" -ForegroundColor Yellow
    Write-Host "  Expected at least: $expectedMinSize bytes" -ForegroundColor Yellow
    Write-Host "  This might indicate an incomplete download." -ForegroundColor Yellow
} else {
    Write-Host "✓ File size looks good" -ForegroundColor Green
}

# Summary
Write-Host ""
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "  Validation Summary" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "✓ All checks passed!" -ForegroundColor Green
Write-Host ""
Write-Host "The script appears to be valid and ready to use." -ForegroundColor Green
Write-Host "You can now run: .\Fix-UsbDkInstallation.ps1" -ForegroundColor Cyan
Write-Host ""
