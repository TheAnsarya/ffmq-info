# FFMQ Automatic Activity Tracker - Simple Wrapper
# Just run this script and forget about it - everything is logged automatically!

param(
	[Parameter(Mandatory=$false)]
	[ValidateSet('start', 'stop', 'status')]
	[string]$Action = 'start',
	
	[Parameter(Mandatory=$false)]
	[int]$Interval = 30
)

$ProjectRoot = $PSScriptRoot
$TrackerScript = Join-Path $ProjectRoot "tools\auto_tracker.py"

# Check if Python is available
try {
	$null = python --version 2>&1
} catch {
	Write-Host "Error: Python not found. Please install Python 3.x" -ForegroundColor Red
	exit 1
}

# Execute tracker command
switch ($Action) {
	'start' {
		Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
		Write-Host "║     Starting Automatic Activity Tracker...       ║" -ForegroundColor Cyan
		Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
		Write-Host ""
		Write-Host "All file changes will be logged automatically!" -ForegroundColor Green
		Write-Host "Checking for changes every $Interval seconds..." -ForegroundColor Yellow
		Write-Host ""
		Write-Host "💡 Tip: This runs in the background. Close this window to stop." -ForegroundColor Gray
		Write-Host ""
		
		& python $TrackerScript start $Interval
	}
	
	'stop' {
		Write-Host "Stopping automatic tracker..." -ForegroundColor Yellow
		& python $TrackerScript stop
	}
	
	'status' {
		& python $TrackerScript status
	}
}
