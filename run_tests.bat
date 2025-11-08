@echo off
REM Run all tests for FFMQ Game Editor

echo Running FFMQ Game Editor Test Suite...
echo.

python tools\map-editor\tests\test_game_data.py

if %ERRORLEVEL% EQU 0 (
    echo.
    echo All tests passed!
    exit /b 0
) else (
    echo.
    echo Tests failed!
    exit /b 1
)
