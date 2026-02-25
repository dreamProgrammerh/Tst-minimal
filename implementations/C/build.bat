@echo off

gcc ^
    -O3 ^
    -o tstm.exe ^
    tstm.c ^
    program/string-pool.c ^
    error/errors.c ^
    error/reporter.c ^
    lexer/lexer.c ^
    parser/parser.c ^
    parser/ast.c ^
    utils/globals.c ^
    utils/strings.c ^
    utils/memory.c

REM Define color codes
set "RED=[31m"
set "GREEN=[32m"
set "RESET=[0m"

REM Check if compilation succeeded
if %ERRORLEVEL% neq 0 (
    echo %RED%Compilation failed!%RESET%
    exit /b %ERRORLEVEL%
)

echo %GREEN%Compilation successful:%RESET% tstm.exe