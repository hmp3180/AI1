@echo off
rem ====================================================
rem  cook.bat (auto-generated)
rem    cooks Assets/ into cooked_assets/ (incremental).
rem    usage: cook.bat [--platform win64|android|all] [--force] [--clean] [-v|-q]
rem    logs are quiet by default (-v for one line per asset).
rem ====================================================
setlocal
cd /d "%~dp0"

call "%~dp0pe_engine.bat"
if errorlevel 1 exit /b 1
set "PYTHON=%ENGINE_DIR%\.venv\Scripts\python.exe"
if not exist "%PYTHON%" set "PYTHON=python"
set "COOKER=%ENGINE_DIR%\Tools\CookAssets.py"

"%PYTHON%" "%COOKER%" --project-root "%CD%" %*
exit /b %ERRORLEVEL%
