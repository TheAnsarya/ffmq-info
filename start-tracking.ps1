# FFMQ Auto-Tracker Launcher
# Starts tracking in background when you start working on the project

$ProjectRoot = Split-Path -Parent $PSScriptRoot

Write-Host ""
Write-Host "╔═══════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "║   FFMQ Development - Automatic Logging Enabled   ║" -ForegroundColor Cyan
Write-Host "╚═══════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Check if tracker is already running
$TrackerScript = Join-Path $ProjectRoot "tools\auto_tracker.py"
$Status = & python $TrackerScript status 2>&1

if ($Status -match "running") {
	Write-Host "✓ Automatic logging is already active!" -ForegroundColor Green
	Write-Host ""
} else {
	Write-Host "Starting automatic activity tracker..." -ForegroundColor Yellow
	
	# Start tracker in background job
	Start-Job -ScriptBlock {
		param($TrackerPath, $Interval)
		& python $TrackerPath start $Interval
	} -ArgumentList $TrackerScript, 30 | Out-Null
	
	Start-Sleep -Seconds 2
	
	Write-Host "✓ Automatic logging is now active!" -ForegroundColor Green
	Write-Host ""
	Write-Host "All your file changes will be logged automatically." -ForegroundColor Gray
	Write-Host "No need to run .\update.ps1 manually anymore!" -ForegroundColor Gray
	Write-Host ""
}

Write-Host "Commands:" -ForegroundColor Yellow
Write-Host "  .\track.ps1 status  - Check tracking status" -ForegroundColor Gray
Write-Host "  .\track.ps1 stop    - Stop automatic tracking" -ForegroundColor Gray
Write-Host "  .\track.ps1 start   - Start automatic tracking" -ForegroundColor Gray
Write-Host ""
Write-Host "💡 Tracker runs in background, no need to keep window open!" -ForegroundColor Cyan
Write-Host ""
