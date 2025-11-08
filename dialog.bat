@echo off
REM FFMQ Dialog Manager CLI wrapper
REM Sets up the environment and launches the CLI

cd /d %~dp0
cd tools\map-editor

REM Check if venv exists
if not exist "..\..\. venv\Scripts\python.exe" (
	echo Error: Virtual environment not found
	echo Please run setup.ps1 first
	exit /b 1
)

REM Run the CLI with venv Python
"..\..\. venv\Scripts\python.exe" dialog_cli.py %*
