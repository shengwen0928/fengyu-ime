
@echo off
setlocal

call :find_toolchain
if errorlevel 1 exit /b 1

REM Build dummy object files
cl.exe /c /Fo:dummy.o dummy.c || exit /b 1
cl.exe /c /arm64EC /Fo:dummy_x64.o dummy.c || exit /b 1

REM Build fengyu.dll wrapper
link.exe /lib /machine:x64 /def:FengyuTSF_x64.def /out:FengyuTSF_x64.lib /ignore:4104
link.exe /lib /machine:arm64 /def:FengyuTSF_arm64.def /out:FengyuTSF_arm64.lib /ignore:4104
link.exe /dll /noentry /machine:arm64x /defArm64Native:FengyuTSF_arm64.def /def:FengyuTSF_x64.def ^
  /out:fengyuARM64X.dll dummy.o dummy_x64.o FengyuTSF_x64.lib FengyuTSF_arm64.lib /ignore:4104

REM Build fengyu.ime wrapper
link.exe /lib /machine:x64 /def:FengyuIME_x64.def /out:FengyuIME_x64.lib /ignore:4104
link.exe /lib /machine:arm64 /def:FengyuIME_arm64.def /out:FengyuIME_arm64.lib /ignore:4104
link.exe /dll /noentry /machine:arm64x /defArm64Native:FengyuIME_arm64.def /def:FengyuIME_x64.def ^
  /out:fengyuARM64X.ime dummy.o dummy_x64.o FengyuIME_x64.lib FengyuIME_arm64.lib /ignore:4104

endlocal
exit /b

:find_toolchain
set VSWHERE="%PROGRAMFILES%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist %VSWHERE% (
  set VSWHERE="%PROGRAMFILES(X86)%\Microsoft Visual Studio\Installer\vswhere.exe"
)
if not exist %VSWHERE% (
  echo vswhere not found, could not find a working MSVC install.
  exit /b 1
)

for /f "usebackq tokens=*" %%i in (`%VSWHERE% -latest -requires Microsoft.VisualStudio.Component.VC.Tools.ARM64EC -property installationPath`) do (
  set ARM64EC_TOOLCHAIN=%%i
)

if exist "%ARM64EC_TOOLCHAIN%\Common7\Tools\vsdevcmd.bat" (
  call "%ARM64EC_TOOLCHAIN%\Common7\Tools\vsdevcmd.bat" -arch=arm64 -host_arch=x86
  echo.
) else (
  echo ARM64EC capable toolchain not found
  exit /b 1
)

exit /b

