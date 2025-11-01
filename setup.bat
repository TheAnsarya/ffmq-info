@echo off
REM Final Fantasy Mystic Quest - Development Environment Setup (Windows)
REM This script helps set up the FFMQ development environment on Windows

echo Final Fantasy Mystic Quest - Development Environment Setup
echo ==========================================================
echo.

REM Check if we're in the right directory
if not exist "Makefile" (
    echo Error: Makefile not found. Please run this from the project root directory.
    pause
    exit /b 1
)

REM Check for Python
echo Checking for Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo Error: Python not found. Please install Python 3.x
    echo Download from: https://python.org/
    pause
    exit /b 1
) else (
    echo Python found: 
    python --version
)
echo.

REM Check for required directories
echo Setting up directories...
if not exist "~roms" (
    echo Creating ~roms directory...
    mkdir "~roms"
    echo.
    echo Please copy your Final Fantasy Mystic Quest ROM files to the ~roms directory:
    echo   - Final Fantasy - Mystic Quest (U) (V1.1).sfc (recommended)
    echo   - Other regional versions (optional)
    echo.
    echo Press any key when you have copied the ROM files...
    pause >nul
)

if not exist "build" (
    echo Creating build directory...
    mkdir "build"
)

if not exist "assets" (
    echo Creating assets directory...
    mkdir "assets"
    mkdir "assets\graphics"
    mkdir "assets\text"
    mkdir "assets\music"
)

echo.
echo Checking ROM files...
python tools\setup_rom.py "~roms"
if errorlevel 1 (
    echo.
    echo ROM setup failed. Please check the ROM files and try again.
    pause
    exit /b 1
)

echo.
echo ==========================================================
echo Development Environment Setup Complete!
echo ==========================================================
echo.
echo Available commands:
echo   make setup-env     - Check development tools
echo   make extract-assets - Extract graphics, text, and music
echo   make rom           - Build the ROM
echo   make test          - Test ROM in emulator
echo   make clean         - Clean build files
echo   make help          - Show all available commands
echo.
echo Tool requirements:
echo   - ca65/cc65: https://cc65.github.io/
echo   - asar: https://github.com/RPGHacker/asar
echo   - MesenS (optional): https://github.com/SourMesen/Mesen-S
echo.
echo Next steps:
echo   1. Install the required tools (see URLs above)
echo   2. Run: make setup-env
echo   3. Run: make extract-assets
echo   4. Run: make rom
echo.
pause