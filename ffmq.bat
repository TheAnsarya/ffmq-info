@echo off
REM FFMQ Task Runner - Batch Wrapper
REM Provides easier access to PowerShell task runner

if "%1"=="" (
	powershell -ExecutionPolicy Bypass -File "%~dp0ffmq-tasks.ps1" -Task help
) else if "%1"=="edit" (
	powershell -ExecutionPolicy Bypass -File "%~dp0ffmq-tasks.ps1" -Task edit -Arg "%2"
) else if "%1"=="show" (
	powershell -ExecutionPolicy Bypass -File "%~dp0ffmq-tasks.ps1" -Task show -Arg "%2"
) else if "%1"=="search" (
	powershell -ExecutionPolicy Bypass -File "%~dp0ffmq-tasks.ps1" -Task search -Arg "%2"
) else (
	powershell -ExecutionPolicy Bypass -File "%~dp0ffmq-tasks.ps1" -Task "%1"
)
