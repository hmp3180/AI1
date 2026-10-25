@echo off
rem ====================================================
rem  build.bat (auto-generated)
rem    usage: build.bat [preset] [options] [--no-cook] [--clean | --clean-build | --clean-cook]
rem      (default preset: win64)
rem      builds the code, then cooks the assets. code only: --no-cook
rem      (cook comes last: the assetgen cook runs the project exe in bin_dev)
rem      --clean-build  rebuild all objects   --clean-cook  recook everything   --clean  both
rem      log is quiet by default (warnings/errors + summary). full log: -v
rem      e.g. build.bat    build.bat win64 -v    build.bat --no-cook    build.bat --clean
rem ====================================================
setlocal
cd /d "%~dp0"

call "%~dp0pe_engine.bat"
if errorlevel 1 exit /b 1
set "PYTHON=%ENGINE_DIR%\.venv\Scripts\python.exe"
if not exist "%PYTHON%" set "PYTHON=python"
set "BUILDER=%ENGINE_DIR%\Tools\PEBuilder.py"
set "COOKER=%ENGINE_DIR%\Tools\CookAssets.py"

rem --no-cook and --clean* are handled here, the rest goes to the builder. a first arg without - is the preset.
set "ARGS="
set "PRESET="
set "COOK=1"
set "COOKV="
set "COOKCLEAN="
set "FIRST=1"
:args
if "%~1"=="" goto argsdone
if /i "%~1"=="--no-cook" (
    set "COOK=0"
) else if /i "%~1"=="--clean" (
    set "ARGS=%ARGS% --clean"
    set "COOKCLEAN=--clean"
) else if /i "%~1"=="--clean-build" (
    set "ARGS=%ARGS% --clean"
) else if /i "%~1"=="--clean-cook" (
    set "COOKCLEAN=--clean"
) else (
    set "ARGS=%ARGS% %1"
    if /i "%~1"=="-v" set "COOKV=-v"
    if defined FIRST set "PRESET=%~1"
)
set "FIRST="
shift
goto args
:argsdone
if "%PRESET:~0,1%"=="-" set "PRESET="
if not defined PRESET (
    set "PRESET=win64"
    set "ARGS=win64%ARGS%"
)

"%PYTHON%" "%BUILDER%" --project-root "%CD%" %ARGS%
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
    echo.
    echo [build.bat] BUILD FAILED ^(exit %RC%^)
    exit /b %RC%
)
if "%COOK%"=="0" exit /b 0

set "PLATFORM=win64"
if /i "%PRESET:~0,7%"=="android" set "PLATFORM=android"
"%PYTHON%" "%COOKER%" --project-root "%CD%" --platform %PLATFORM% %COOKCLEAN% %COOKV%
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
    echo.
    echo [build.bat] COOK FAILED ^(exit %RC%^)
)
exit /b %RC%
