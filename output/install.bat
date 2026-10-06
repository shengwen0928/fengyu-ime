@echo off

rem argument 1: [ /s | /t ] register ime as zh_CN | zh_TW keyboard layout
set install_option=/s
if /i "%1" == "/t" set install_option=/t

set CD_BACK=%CD%
cd "%~dp0"

if /i "%2" == "/register" goto register

echo stopping service from an older version.
call stop_service.bat

echo configuring preset input schemas...
FengyuDeployer.exe /install

echo administrative permissions required. detecting permissions...
net session >nul 2>&1
if not %errorlevel% == 0 (
  echo elevating command prompt...
  cscript sudo.js "%~nx0" %install_option% /register
  exit /b
)

:register
echo registering Fengyu IME to your system.
echo install_option=%install_option%

cscript check_windows_version.js
if errorlevel 2 goto win7_x64_install
if errorlevel 1 goto xp_install

:win7_install
FengyuSetup.exe %install_option%
rem regsvr32.exe /s "%CD%\fengyu.dll"
goto next

:win7_x64_install
FengyuSetupx64.exe %install_option%
rem regsvr32.exe /s "%CD%\fengyu.dll"
rem regsvr32.exe /s "%CD%\fengyux64.dll"
goto next

:xp_install
FengyuSetup.exe %install_option%
goto next

:next
reg add "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Run" /v FengyuServer /t REG_SZ /d "%CD%\FengyuServer.exe" /f

:done
start FengyuServer.exe

if /i "%2" == "/register" pause
echo installed.
cd "%CD_BACK%"
