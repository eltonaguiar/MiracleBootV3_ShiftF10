@echo off
setlocal EnableDelayedExpansion
:: Define target directory
set "MB=%TEMP%\MiracleBoot"
mkdir "%MB%" 2>nul
pushd "%MB%"

:: ============================================================
:: PHASE 1: Build the Universal Launcher (.cmd)
:: ============================================================
(
echo @echo off
echo title Miracle Boot v7.1 - Universal Entry
echo cd /d "%%~dp0"
echo :: Environment Detection
echo set ENV=FullOS
echo reg query "HKLM\Software\Microsoft\Windows NT\CurrentVersion\WinPE" ^>nul 2^>^&1 ^&^& set ENV=WinPE
echo echo [MiracleBoot] Environment: %%ENV%%
echo.
echo :: Check for GUI support (mshta)
echo where mshta.exe ^>nul 2^>^&1
echo if errorlevel 1 (
echo     echo [!] MSHTA not found. Falling back to CLI mode...
echo     goto CLI
echo )
echo start "" mshta.exe "%%~dp0MiracleBoot.hta"
echo exit /b
echo.
echo :CLI
echo call "%%~dp0WinRepairTool.cmd"
echo exit /b
) > "MiracleBoot.cmd"

:: ============================================================
:: PHASE 2: Build the GUI Interface (.hta)
:: ============================================================
(
echo ^<html^>^<head^>^<title^>Miracle Boot v7.1^</title^>
echo ^<hta:application applicationname="MiracleBoot" border="thin" caption="yes" scroll="no" singleinstance="yes" /^>
echo ^<style^>
echo body { font-family: 'Segoe UI', Tahoma, sans-serif; background: #1e1e1e; color: #ffffff; margin: 20px; }
echo .header { border-bottom: 2px solid #0078d7; padding-bottom: 10px; margin-bottom: 20px; }
echo .btn { background: #333; color: white; border: 1px solid #555; width: 100%%; padding: 10px; margin: 5px 0; cursor: pointer; text-align: left; }
echo .btn:hover { background: #0078d7; border-color: #005a9e; }
echo .footer { font-size: 0.8em; color: #888; margin-top: 20px; text-align: center; }
echo .section-title { font-weight: bold; color: #0078d7; margin-top: 10px; display: block; }
echo ^</style^>
echo ^<script language="VBScript"^>
echo Sub Run(cmd)
echo   Set shell = CreateObject("WScript.Shell")
echo   shell.Run cmd, 1, False
echo End Sub
echo ^</script^>^</head^>^<body^>
echo ^<div class="header"^>^<h2^>Miracle Boot v7.1^</h2^>^<small^>Universal Recovery Environment^</small^>^</div^>
echo ^<span class="section-title"^>SYSTEM TOOLS^</span^>
echo ^<button class="btn" onclick="Run('notepad.exe')"^>1. Notepad (Text Editor)^</button^>
echo ^<button class="btn" onclick="Run('regedit.exe')"^>2. Registry Editor^</button^>
echo ^<button class="btn" onclick="Run('diskpart.exe')"^>3. DiskPart (Disk Management)^</button^>
echo ^<button class="btn" onclick="Run('cmd.exe /k bcdedit')"^>4. BCDedit (Boot Config)^</button^>
echo ^<span class="section-title"^>QUICK REPAIRS^</span^>
echo ^<button class="btn" onclick="Run('cmd.exe /c bcdedit /set {bootmgr} displaybootmenu yes ^& bcdedit /timeout 10')"^>Force Boot Menu (10s)^</button^>
echo ^<div class="footer"^>MiracleBoot v7.1 - [cite: 4, 5, 8]^</div^>
echo ^</body^>^</html^>
) > "MiracleBoot.hta"

:: ============================================================
:: PHASE 3: Build the CLI Repair Tool (.cmd)
:: ============================================================
(
echo @echo off
echo title Miracle Boot v7.1 - CLI Repair Tool
echo :MENU
echo cls
echo =====================================
echo    Miracle Boot v7.1 - CLI MODE
echo =====================================
echo [1] Notepad
echo [2] Registry Editor
echo [3] DiskPart
echo [4] BCDEdit (Show Config)
echo [5] Force Boot Menu (10s)
echo [6] Exit
echo.
echo [cite: 2]
echo.
echo set /p CHOICE=Select option: 
echo if "%%CHOICE%%"=="1" start notepad ^& goto MENU
echo if "%%CHOICE%%"=="2" start regedit ^& goto MENU
echo if "%%CHOICE%%"=="3" start diskpart ^& goto MENU
echo if "%%CHOICE%%"=="4" bcdedit ^& pause ^& goto MENU
echo if "%%CHOICE%%"=="5" (
echo    bcdedit /set {bootmgr} displaybootmenu yes
echo    bcdedit /timeout 10
echo    echo Boot menu forced. ^& pause ^& goto MENU
echo )
echo if "%%CHOICE%%"=="6" exit /b
) > "WinRepairTool.cmd"

:: ============================================================
:: PHASE 4: Execution
:: ============================================================
echo [MiracleBoot] Extraction Complete.
echo [MiracleBoot] Launching...
call "MiracleBoot.cmd"
popd
