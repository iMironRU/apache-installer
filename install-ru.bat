@echo off
chcp 65001 > nul
setlocal

set "SCRIPT_DIR=%~dp0"
set "PS_RU=%SCRIPT_DIR%src\install-apache-ru.ps1"
set "EXE_RU=%SCRIPT_DIR%install-apache-ru.exe"

if exist "%EXE_RU%" (
    set "TARGET=%EXE_RU%"
    set "IS_EXE=1"
) else if exist "%PS_RU%" (
    set "TARGET=%PS_RU%"
    set "IS_EXE=0"
) else (
    echo.
    echo  [!] install-apache-ru.ps1 not found.
    echo      Expected: %PS_RU%
    echo.
    pause
    exit /b 1
)

net session > nul 2>&1
if %errorLevel% == 0 goto :run

echo Requesting administrator privileges...
if "%IS_EXE%"=="1" (
    powershell -NoProfile -Command "Start-Process '%TARGET%' -Verb RunAs -Wait"
) else (
    powershell -NoProfile -Command "Start-Process powershell -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%TARGET%""' -Verb RunAs -Wait"
)
exit /b

:run
if "%IS_EXE%"=="1" (
    "%TARGET%"
) else (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%TARGET%"
)

if %errorLevel% neq 0 (
    echo.
    echo  [!] Script failed. Error code: %errorLevel%
    echo      Check log file in: %SCRIPT_DIR%
    echo.
    pause
)
