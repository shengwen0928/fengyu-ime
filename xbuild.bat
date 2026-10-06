@echo off
setlocal enabledelayedexpansion
if not defined include (
  echo You should run this inside Developer Command Promt!
  exit /b
)
for %%a in ("%include:;=" "%") do (
  echo %%a| findstr /r "ATLMFC\\include" > nul
  if not errorlevel 1 (
    set "atl_lib_dir=%%a"
    set dpi_manifest=!atl_lib_dir:ATLMFC\include=Include\Manifest\PerMonitorHighDPIAware.manifest!
    if not exist ".\PerMonitorHighDPIAware.manifest" (
      copy ""!dpi_manifest!"" .\
    )
  )
)
rem ---------------------------------------------------------------------------
if not exist env.bat copy env.bat.template env.bat
if exist env.bat call env.bat
set PRODUCT_VERSION=
if not defined FENGYU_ROOT set FENGYU_ROOT=%CD%
if not defined VERSION_MAJOR set VERSION_MAJOR=0
if not defined VERSION_MINOR set VERSION_MINOR=17
if not defined VERSION_PATCH set VERSION_PATCH=4

if not defined FENGYU_VERSION set FENGYU_VERSION=%VERSION_MAJOR%.%VERSION_MINOR%.%VERSION_PATCH%
if not defined FENGYU_BUILD set FENGYU_BUILD=0

rem use numeric build version for release build
set PRODUCT_VERSION=%FENGYU_VERSION%.%FENGYU_BUILD%
rem for non-release build, try to use git commit hash as product build version
if not defined RELEASE_BUILD (
  rem check if git is installed and available, then get the short commit id of head
  git --version >nul 2>&1
  if not errorlevel 1 (
    for /f "delims=" %%i in ('git tag --sort=-creatordate ^| findstr /r "%FENGYU_VERSION%"') do (
      set LAST_TAG=%%i
      goto found_tag
    )
    :found_tag
    for /f "delims=" %%i in ('git rev-list %LAST_TAG%..HEAD --count') do (
      set FENGYU_BUILD=%%i
    )
    rem get short commmit id of head
    for /F %%i in ('git rev-parse --short HEAD') do (set PRODUCT_VERSION=%FENGYU_VERSION%.%FENGYU_BUILD%.%%i)
  )
)

rem FILE_VERSION is always 4 numbers; same as PRODUCT_VERSION in release build
if not defined FILE_VERSION set FILE_VERSION=%FENGYU_VERSION%.%FENGYU_BUILD%
echo PRODUCT_VERSION=%PRODUCT_VERSION%
echo FENGYU_VERSION=%FENGYU_VERSION%
echo FENGYU_BUILD=%FENGYU_BUILD%
echo FENGYU_ROOT=%FENGYU_ROOT%
echo FENGYU_BUNDLED_RECIPES=%FENGYU_BUNDLED_RECIPES%
echo BOOST_ROOT=%BOOST_ROOT%

if defined GITHUB_ENV (
	setlocal enabledelayedexpansion
	echo git_ref_name=%PRODUCT_VERSION%>>!GITHUB_ENV!
)

rem ---------------------------------------------------------------------------
rem parse the command line options
set build_config=release
set build_rebuild=0
set build_boost=0
set boost_build_variant=release
set build_data=0
set build_opencc=0
set build_engine=0
set engine_build_variant=release
set build_fengyu=0
set build_installer=0
set build_arm64=0
set build_clean=0
set build_commands=0
:parse_cmdline_options
  if "%1" == "" goto end_parsing_cmdline_options
  if "%1" == "debug" (
    set build_config=debug
    set boost_build_variant=debug
    set engine_build_variant=debug
  )
  if "%1" == "release" (
    set build_config=release
    set boost_build_variant=release
    set engine_build_variant=release
  )
  if "%1" == "rebuild" set build_rebuild=1
  if "%1" == "boost" set build_boost=1
  if "%1" == "data" set build_data=1
  if "%1" == "opencc" set build_opencc=1
  if "%1" == "engine" set build_engine=1
  if "%1" == "fengyu" set build_fengyu=1
  if "%1" == "installer" set build_installer=1
  if "%1" == "arm64" set build_arm64=1
  if "%1" == "clean" set build_clean=1
  if "%1" == "commands" set build_commands=1
  if "%1" == "all" (
    set build_boost=1
    set build_data=1
    set build_opencc=1
    set build_engine=1
    set build_fengyu=1
    set build_installer=1
    set build_arm64=1
    set build_commands=1
  )
  shift
  goto parse_cmdline_options
:end_parsing_cmdline_options

if %build_fengyu% == 0 (
if %build_boost% == 0 (
if %build_data% == 0 (
if %build_opencc% == 0 (
if %build_engine% == 0 (
if %build_commands% == 0 (
  set build_fengyu=1
))))))
rem 
rem quit FengyuServer.exe before building
cd /d %FENGYU_ROOT%
if exist output\fengyuserver.exe (
  output\fengyuserver.exe /q
)

rem build booost
if %build_boost% == 1 (
  if %build_arm64% == 1 (
    call build.bat boost arm64
  ) else (
    call build.bat boost
  )
  if errorlevel 1 exit /b 1
  cd /d %FENGYU_ROOT%
)
if %build_engine% == 1 (
  call build.bat engine
  if errorlevel 1 exit /b 1
  cd /d %FENGYU_ROOT%
)
if %build_data% == 1 (
  call build.bat data
  if errorlevel 1 exit /b 1
  cd /d %FENGYU_ROOT%
)
if %build_opencc% == 1 (
  call build.bat opencc
  if errorlevel 1 exit /b 1
  cd /d %FENGYU_ROOT%
)

if %build_commands% == 1 (
  echo Generating compile_commands.json
  xmake project -k compile_commands -m %build_config%
)

rem if to clean
if %build_clean% == 1 ( goto clean )
if %build_fengyu% == 0 ( goto end )

if %build_arm64% == 1 (
  xmake f -a arm64 -m %build_config%
  if %build_rebuild% == 1 ( xmake clean )
  xmake
  if errorlevel 1 goto error
  xmake f -a arm  -m %build_config%
  if %build_rebuild% == 1 ( xmake clean )
  xmake
  if errorlevel 1 goto error
)
xmake f -a x64 -m %build_config%
if %build_rebuild% == 1 ( xmake clean )
xmake
if errorlevel 1 goto error
xmake f -a x86 -m %build_config%
if %build_rebuild% == 1 ( xmake clean )
xmake
if errorlevel 1 goto error

if %build_arm64% == 1 (
  pushd arm64x_wrapper
  call build.bat
  if errorlevel 1 goto error
  popd

  copy arm64x_wrapper\fengyuARM64X.dll output
  if errorlevel 1 goto error
  copy arm64x_wrapper\fengyuARM64X.ime output
  if errorlevel 1 goto error
)
if %build_installer% == 1 (
  "%ProgramFiles(x86)%"\NSIS\Bin\makensis.exe ^
  /DFENGYU_VERSION=%FENGYU_VERSION% ^
  /DFENGYU_BUILD=%FENGYU_BUILD% ^
  /DPRODUCT_VERSION=%PRODUCT_VERSION% ^
  output\install.nsi
  if errorlevel 1 goto error
)
goto end

:clean
  if exist build (
    rmdir /s /q build
    if errorlevel 1 (
      echo error cleaning fengyu build
      goto error
    )
    goto end
  )

:error
  echo error building fengyu...
  exit /b 1
  
:end
  cd %FENGYU_ROOT%

