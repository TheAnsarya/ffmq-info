@echo off
REM FFMQ Enemy Editor Launcher (Windows)
REM Quick launcher for the GUI enemy editor

echo.
echo ========================================
echo  FFMQ Enemy Editor
echo ========================================
echo.

REM Check if virtual environment exists
if exist .venv\Scripts\python.exe (
    echo Using virtual environment...
    .venv\Scripts\python.exe tools\enemy_editor_gui.py
) else (
    echo Using system Python...
    python tools\enemy_editor_gui.py
)

if errorlevel 1 (
    echo.
    echo ========================================
    echo  Error launching editor!
    echo ========================================
    echo.
    echo Make sure enemy data is extracted first:
    echo   python tools/extraction/extract_enemies.py
    echo.
    pause
)
