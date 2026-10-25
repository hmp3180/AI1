@echo off
rem ====================================================
rem  pemcp.bat - runs the engine's PEMCP for the projects in this repository
rem    .mcp.json calls this. engine = PE_ENGINE env, or engine.ini here (engine=D:\GIT\PEE2)
rem    stdout is the MCP channel - messages go to stderr only
rem ====================================================
setlocal
set "PE_ROOT="
if defined PE_ENGINE set "PE_ROOT=%PE_ENGINE%"
if not defined PE_ROOT if exist "%~dp0engine.ini" for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%~dp0engine.ini") do if /i "%%a"=="engine" set "PE_ROOT=%%~b"
if not exist "%PE_ROOT%\Engine\Tools\PEMCP\pemcp.py" (
    echo [pemcp] engine not found - write engine.ini here with one line: engine=D:\path\to\engine 1>&2
    exit /b 1
)
"%PE_ROOT%\Engine\.venv\Scripts\python.exe" -I "%PE_ROOT%\Engine\Tools\PEMCP\pemcp.py" --projects "%~dp0."
