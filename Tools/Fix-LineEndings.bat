@echo off
REM Fix PowerShell Script Line Endings
REM Converts Unix (LF) line endings to Windows (CRLF) if needed

echo.
echo ================================================
echo   Fix UsbDk Script Line Endings
echo ================================================
echo.

if not exist "%~dp0Fix-UsbDkInstallation.ps1" (
    echo ERROR: Fix-UsbDkInstallation.ps1 not found
    echo.
    echo Please ensure the file is in the same directory as this batch file.
    echo Current directory: %~dp0
    pause
    exit /b 1
)

echo Checking and fixing line endings...
echo.

REM Use PowerShell to convert line endings
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "$file = '%~dp0Fix-UsbDkInstallation.ps1'; ^
    $content = Get-Content $file -Raw; ^
    if ($content -match '[^`r]`n') { ^
        Write-Host 'Converting Unix (LF) to Windows (CRLF) line endings...' -ForegroundColor Yellow; ^
        $content = $content -replace '`r?`n', \"`r`n\"; ^
        [System.IO.File]::WriteAllText($file, $content, [System.Text.Encoding]::UTF8); ^
        Write-Host 'Line endings fixed successfully!' -ForegroundColor Green; ^
    } else { ^
        Write-Host 'Line endings are already correct (CRLF)' -ForegroundColor Green; ^
    }"

if %errorLevel% neq 0 (
    echo.
    echo ERROR: Failed to fix line endings
    pause
    exit /b 1
)

echo.
echo ================================================
echo   Line Endings Fixed
echo ================================================
echo.
echo You can now run the script:
echo   Fix-UsbDkInstallation.bat
echo.
pause
