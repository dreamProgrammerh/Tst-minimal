@echo off
setlocal enabledelayedexpansion

REM Get the directory where this batch file is located
set "SCRIPT_DIR=%~dp0"
REM Remove trailing backslash
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

REM Change to the script directory so relative paths work
pushd "%SCRIPT_DIR%"

REM Build with relative paths (now safe because we're in the right directory)
gcc ^
    -O3 ^
    -o tstm.exe ^
    tstm.c ^
    program\string-pool.c ^
    error\errors.c ^
    error\reporter.c ^
    lexer\lexer.c ^
    parser\parser.c ^
    parser\ast.c ^
    utils\globals.c ^
    utils\strings.c ^
    utils\memory.c

REM Define color codes
set "RED=[31m"
set "GREEN=[32m"
set "RESET=[0m"

REM Check if compilation succeeded
if %ERRORLEVEL% neq 0 (
    echo %RED%Compilation failed!%RESET%
    popd
    exit /b %ERRORLEVEL%
)

echo %GREEN%Compilation successful:%RESET% tstm.exe

REM Return to original directory
popd