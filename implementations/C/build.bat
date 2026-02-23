@echo off

gcc ^
    -O3 ^
    -o tstm.exe ^
    tstm.c ^
    error/errors.c ^
    lexer/lexer.c ^
    utils/strings.c ^
    utils/memory.c

REM Define color codes
set "RED=[31m"
set "GREEN=[32m"
set "RESET=[0m"

REM Check if compilation succeeded
if %ERRORLEVEL% neq 0 (
    echo %RED%Compilation failed!
    exit /b %ERRORLEVEL%
)

echo %GREEN%Compilation successful:%RESET% tstm.exe