@echo off
rem ====================================================
rem  run.bat (auto-generated)
rem    runs the built exe from bin_dev so asset relative
rem    paths resolve correctly.
rem ====================================================
setlocal
cd /d "%~dp0bin_dev"

set "EXE="
for %%F in (*.exe) do set "EXE=%%F"
if "%EXE%"=="" (
    echo [run.bat] no .exe found in bin_dev. Run build.bat first.
    exit /b 1
)

".\%EXE%" %*
exit /b %ERRORLEVEL%
