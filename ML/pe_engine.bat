@echo off
rem ====================================================
rem  pe_engine.bat (auto-generated) - finds the engine for this project
rem    sets ENGINE_DIR = <engine root>\Engine
rem    order: PE_ENGINE env -> <project>\engine.ini -> <project>\..\engine.ini (shared) -> ..\..
rem    engine.ini (gitignored, one per PC):   engine=D:\GIT\PEE2
rem ====================================================
set "PE_ENGINE_ROOT="
if defined PE_ENGINE set "PE_ENGINE_ROOT=%PE_ENGINE%"
if not defined PE_ENGINE_ROOT if exist "%~dp0engine.ini" for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%~dp0engine.ini") do if /i "%%a"=="engine" set "PE_ENGINE_ROOT=%%~b"
if not defined PE_ENGINE_ROOT if exist "%~dp0..\engine.ini" for /f "usebackq eol=# tokens=1,* delims==" %%a in ("%~dp0..\engine.ini") do if /i "%%a"=="engine" set "PE_ENGINE_ROOT=%%~b"
if not defined PE_ENGINE_ROOT if exist "%~dp0..\..\Engine\Tools\PEBuilder.py" for %%I in ("%~dp0..\..") do set "PE_ENGINE_ROOT=%%~fI"
if not defined PE_ENGINE_ROOT (
    echo [pe_engine] engine location unknown - write engine.ini ^(gitignored^) with one line:
    echo [pe_engine]     engine=D:\path\to\engine   ^(the folder that has Engine\ and ExternalTools\^)
    echo [pe_engine]   shared for all projects: %~dp0..\engine.ini   or just this one: %~dp0engine.ini
    echo [pe_engine]   agents: do not search the disk for an engine - ask the user to set up the engine and engine.ini
    exit /b 1
)
if not exist "%PE_ENGINE_ROOT%\Engine\Tools\PEBuilder.py" (
    echo [pe_engine] no engine at "%PE_ENGINE_ROOT%" ^(Engine\Tools\PEBuilder.py missing - check engine.ini^)
    echo [pe_engine]   agents: do not search the disk for an engine - ask the user to set up the engine and engine.ini
    exit /b 1
)
set "ENGINE_DIR=%PE_ENGINE_ROOT%\Engine"
echo [pe_engine] engine = %PE_ENGINE_ROOT%
exit /b 0
