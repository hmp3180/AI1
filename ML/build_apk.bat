@echo off
rem ====================================================
rem  build_apk.bat (auto-generated)
rem    cooks Android assets, then builds the Android APK.
rem ====================================================
setlocal
cd /d "%~dp0"

call "%~dp0pe_engine.bat"
if errorlevel 1 exit /b 1
set "PYTHON=%ENGINE_DIR%\.venv\Scripts\python.exe"
if not exist "%PYTHON%" set "PYTHON=python"
set "COOKER=%ENGINE_DIR%\Tools\CookAssets.py"
set "BUILDER=%ENGINE_DIR%\Tools\PEBuilder.py"

echo [build_apk.bat] cooking Android assets...
"%PYTHON%" "%COOKER%" --project-root "%CD%" --platform android
set "RC=%ERRORLEVEL%"
if not "%RC%"=="0" (
    echo.
    echo [build_apk.bat] COOK FAILED ^(exit %RC%^)
    exit /b %RC%
)

echo [build_apk.bat] building APK...
"%PYTHON%" "%BUILDER%" --project-root "%CD%" android
set "RC=%ERRORLEVEL%"
if "%RC%"=="0" (
    echo.
    echo [build_apk.bat] APK output: %CD%\bin_android\apk
) else (
    echo.
    echo [build_apk.bat] BUILD FAILED ^(exit %RC%^)
)
exit /b %RC%
