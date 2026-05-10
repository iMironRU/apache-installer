@echo off
chcp 65001 > nul
setlocal

echo.
echo  ==========================================
echo   Apache Installer -- Build EXE via ps2exe
echo  ==========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "SRC=%SCRIPT_DIR%src\install-apache.ps1"
set "OUT=%SCRIPT_DIR%install-apache.exe"

:: Check PowerShell
where powershell > nul 2>&1
if %errorLevel% neq 0 (
    echo  [!] PowerShell not found.
    pause
    exit /b 1
)

:: Check ps2exe module
powershell -NoProfile -Command "if (-not (Get-Module -ListAvailable -Name ps2exe)) { exit 1 }" > nul 2>&1
if %errorLevel% neq 0 (
    echo  [~] ps2exe module not found. Installing...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Install-Module -Name ps2exe -Scope CurrentUser -Force"
    if %errorLevel% neq 0 (
        echo  [!] Failed to install ps2exe.
        echo      Try manually: Install-Module -Name ps2exe -Scope CurrentUser -Force
        pause
        exit /b 1
    )
    echo  [+] ps2exe installed.
)

echo  [>] Building install-apache.exe ...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Import-Module ps2exe; Invoke-ps2exe '%SRC%' '%OUT%' -requireAdmin -noConsole:$false -title 'Apache Installer' -description 'Apache HTTP Server Installer for Windows (en/ru)' -company 'imiron.ru' -copyright 'Copyright (c) 2026 imiron.ru' -version '2.0.0'"

if exist "%OUT%" (
    echo  [+] Built: %OUT%
) else (
    echo  [!] Build failed.
    pause
    exit /b 1
)

echo.
echo  Done. Press any key to exit.
pause > nul
