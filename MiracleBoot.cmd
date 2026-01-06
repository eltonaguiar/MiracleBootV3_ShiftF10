@echo off
title MIRACLE BOOT - UNIVERSAL ENTRY
setlocal ENABLEDELAYEDEXPANSION

:: ================================
:: PATH SETUP
:: ================================
set BASE=%~dp0
set PS1=%BASE%MiracleBoot.ps1
set LOG=%BASE%Logs

if not exist "%LOG%" mkdir "%LOG%"

echo [*] MiracleBoot CMD started >> "%LOG%\entry.log"

:: ================================
:: CHECK POWERSHELL
:: ================================
where powershell.exe >nul 2>&1
if %ERRORLEVEL%==0 (
    echo [+] PowerShell found >> "%LOG%\entry.log"
    powershell -NoProfile -ExecutionPolicy Bypass -File "%PS1%"
    exit /b
)

echo [!] PowerShell missing – CMD fallback >> "%LOG%\entry.log"

:: ================================
:: CMD FALLBACK MENU
:: ================================
:MENU
cls
echo ============================================
echo  MIRACLE BOOT - CMD FAILOVER MODE
echo ============================================
echo.
echo [1] Initialize Network (wpeinit)
echo [2] Rebuild EFI + BCD
echo [3] Inject Drivers from .\Drivers folder
echo [4] Exit
echo.

set /p CHOICE=Choose:

if "%CHOICE%"=="1" goto NET
if "%CHOICE%"=="2" goto BCD
if "%CHOICE%"=="3" goto DRIVERS
if "%CHOICE%"=="4" exit /b
goto MENU

:NET
wpeinit
ping -n 2 8.8.8.8
pause
goto MENU

:BCD
for %%D in (C D E F G H I J) do (
    if exist %%D:\Windows set WIN=%%D:
)

if not defined WIN (
    echo No Windows installation found.
    pause
    goto MENU
)

for %%E in (S T U V W X Y Z) do (
    mountvol %%E: /S >nul 2>&1 && set ESP=%%E:
)

if not defined ESP (
    echo EFI partition not found.
    pause
    goto MENU
)

bcdboot %WIN%\Windows /s %ESP% /f UEFI
echo BCD rebuilt successfully.
pause
goto MENU

:DRIVERS
for %%D in (C D E F G H I J) do (
    if exist %%D:\Windows set WIN=%%D:
)

if not defined WIN (
    echo No Windows installation found.
    pause
    goto MENU
)

if exist "%BASE%Drivers" (
    dism /Image:%WIN% /Add-Driver /Driver:"%BASE%Drivers" /Recurse /ForceUnsigned
    echo Drivers injected.
) else (
    echo No Drivers folder found.
)

pause
goto MENU
