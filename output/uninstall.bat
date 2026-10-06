@echo off

set CD_BACK=%CD%
cd "%~dp0"

if /i "%1" == "/unregister" goto unregister

echo stopping service.
call stop_service.bat

echo administrative permissions required. detecting permissions...
net session >nul 2>&1
if not %errorlevel% == 0 (
  echo elevating command prompt...
  cscript sudo.js "%~nx0" /unregister
  exit /b
)

:unregister
echo uninstalling Fengyu ime.

cscript check_windows_version.js
if errorlevel 2 goto win7_x64_uninstall
if errorlevel 1 goto xp_uninstall

:win7_uninstall
FengyuSetup.exe /u
rem regsvr32.exe /s /u "%CD%\fengyu.dll"
goto next

:win7_x64_uninstall
FengyuSetupx64.exe /u
rem regsvr32.exe /s /u "%CD%\fengyu.dll"
rem regsvr32.exe /s /u "%CD%\fengyux64.dll"
goto next

:xp_uninstall
FengyuSetup.exe /u
goto next

:next
reg delete "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run" /v FengyuServer /f

:done
if /i "%1" == "/unregister" pause
echo uninstalled.
cd "%CD_BACK%"
