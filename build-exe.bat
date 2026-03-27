@echo off
chcp 65001 > nul
setlocal

echo.
echo  ==========================================
echo   Apache Installer -- Build EXE via ps2exe
echo  ==========================================
echo.

set "SCRIPT_DIR=%~dp0"
set "SRC_RU=%SCRIPT_DIR%src\install-apache-ru.ps1"
set "SRC_EN=%SCRIPT_DIR%src\install-apache-en.ps1"
set "OUT_RU=%SCRIPT_DIR%install-apache-ru.exe"
set "OUT_EN=%SCRIPT_DIR%install-apache-en.exe"

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

echo  [>] Building RU version...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Import-Module ps2exe; Invoke-ps2exe '%SRC_RU%' '%OUT_RU%' -requireAdmin -noConsole:$false -title 'Apache Installer' -description 'Apache HTTP Server Installer for Windows' -company 'imiron.ru' -copyright 'Copyright (c) 2026 imiron.ru' -version '1.0.0'"

if exist "%OUT_RU%" (
    echo  [+] Built: %OUT_RU%
) else (
    echo  [!] Build failed for RU version.
)

echo.
echo  [>] Building EN version...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Import-Module ps2exe; Invoke-ps2exe '%SRC_EN%' '%OUT_EN%' -requireAdmin -noConsole:$false -title 'Apache Installer' -description 'Apache HTTP Server Installer for Windows' -company 'imiron.ru' -copyright 'Copyright (c) 2026 imiron.ru' -version '1.0.0'"

if exist "%OUT_EN%" (
    echo  [+] Built: %OUT_EN%
) else (
    echo  [!] Build failed for EN version.
)

echo.
echo  Done. Press any key to exit.
pause > nul
