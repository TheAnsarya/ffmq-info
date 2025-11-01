#Requires -Version 5.1
<#
.SYNOPSIS
	File watcher for automatic rebuilding during development.

.DESCRIPTION
	Monitors source files for changes and automatically triggers rebuilds.
	Includes debouncing to prevent excessive rebuilds during rapid edits.

.PARAMETER WatchPath
	Path(s) to watch for changes. Defaults to src/asm directory.

.PARAMETER BuildScript
	Path to build script to execute. Defaults to tools/Build-System.ps1

.PARAMETER DebounceMs
	Milliseconds to wait before triggering rebuild. Default: 500ms

.PARAMETER AutoLaunch
	Automatically launch ROM in emulator after successful build

.PARAMETER Verbose
	Enable verbose output

.EXAMPLE
	.\Build-Watch.ps1
	Watches src/asm directory and rebuilds on changes

.EXAMPLE
	.\Build-Watch.ps1 -AutoLaunch -Verbose
	Watches and auto-launches emulator after builds

.LINK
	https://github.com/TheAnsarya/ffmq-info
	https://docs.microsoft.com/en-us/dotnet/api/system.io.filesystemwatcher

.NOTES
	Author: Build System Team
	Date: October 30, 2025
	Version: 2.0.0
#>

[CmdletBinding()]
param(
	[Parameter()]
	[string[]]$WatchPath = @("src\asm"),

	[Parameter()]
	[string]$buildScript = "tools\Build-System.ps1",

	[Parameter()]
	[int]$debounceMs = 500,

	[Parameter()]
	[switch]$autoLaunch,

	[Parameter()]
	[switch]$Verbose
)

Set-StrictMode -Version Latest
$errorActionPreference = 'Stop'

$script:ScriptRoot = Split-Path -Parent $PSScriptRoot
$script:LastBuildTime = [DateTime]::MinValue
$script:PendingBuild = $false
$script:BuildCount = 0
$script:SuccessCount = 0
$script:FailCount = 0

#region Helper Functions

function Write-Success {
	param([string]$Message)
	Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error {
	param([string]$Message)
	Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
	param([string]$Message)
	Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Warning {
	param([string]$Message)
	Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Debug {
	param([string]$Message)
	if ($Verbose) {
		Write-Host "🔍 $Message" -ForegroundColor Gray
	}
}

function Write-Section {
	param([string]$Title)
	Write-Host ""
	Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
	Write-Host "  $Title" -ForegroundColor Magenta
	Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
	Write-Host ""
}

<#
.SYNOPSIS
	Triggers a build with debouncing to prevent excessive rebuilds.
.DESCRIPTION
	Uses a timer-based debouncing mechanism to wait for file system to settle
	before triggering the actual build process.
.LINK
	https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/start-sleep
#>
function Invoke-DebouncedBuild {
	param([string]$Reason)

	$now = Get-Date
	$timeSinceLastBuild = ($now - $script:LastBuildTime).TotalMilliseconds

	if ($timeSinceLastBuild -lt $debounceMs) {
		Write-Debug "Build debounced ($([math]::Round($timeSinceLastBuild))ms since last)"
		$script:PendingBuild = $true
		return
	}

	Write-Debug "Triggering build: $Reason"
	$script:LastBuildTime = $now
	$script:PendingBuild = $false

	Invoke-Build -Reason $Reason
}

<#
.SYNOPSIS
	Executes the build process.
#>
function Invoke-Build {
	param([string]$Reason)

	$script:BuildCount++

	Write-Section "Build #$script:BuildCount - $Reason"

	$buildScriptPath = Join-Path $script:ScriptRoot $buildScript

	if (-not (Test-Path $buildScriptPath)) {
		Write-Error "Build script not found: $buildScriptPath"
		$script:FailCount++
		return
	}

	Write-Info "Timestamp: $(Get-Date -Format 'HH:mm:ss')"
	Write-Info "Build script: $buildScriptPath"
	Write-Host ""

	$buildStart = Get-Date

	try {
		# Execute build script
		& $buildScriptPath -Target build -Verbose:$Verbose

		$buildEnd = Get-Date
		$buildTime = ($buildEnd - $buildStart).TotalSeconds

		Write-Host ""
		Write-Success "Build completed in $([math]::Round($buildTime, 2)) seconds"
		$script:SuccessCount++

		# Auto-launch if requested
		if ($autoLaunch) {
			Invoke-AutoLaunch
		}

		# Show statistics
		Write-Host ""
		Write-Info "Build statistics:"
		Write-Host "  Total builds:  $script:BuildCount" -ForegroundColor White
		Write-Host "  Successful:    $script:SuccessCount" -ForegroundColor Green
		Write-Host "  Failed:        $script:FailCount" -ForegroundColor $(if ($script:FailCount -gt 0) { 'Red' } else { 'White' })
	}
	catch {
		$script:FailCount++
		Write-Error "Build failed: $_"
	}

	Write-Host ""
	Write-Info "Watching for changes... (Press Ctrl+C to stop)"
	Write-Host ""
}

<#
.SYNOPSIS
	Launches the built ROM in emulator.
#>
function Invoke-AutoLaunch {
	Write-Info "Auto-launching ROM..."

	# Load config to get ROM path and emulator
	$configPath = Join-Path $script:ScriptRoot "build.config.json"
	if (Test-Path $configPath) {
		$config = Get-Content $configPath -Raw | ConvertFrom-Json
		$romPath = Join-Path $script:ScriptRoot $config.build.outputRom

		if (Test-Path $romPath) {
			# Try to find emulator
			$emulatorPaths = $config.tools.emulator.searchPaths
			$emulatorExe = $config.tools.emulator.executable

			foreach ($searchPath in $emulatorPaths) {
				$emulatorPath = Join-Path $searchPath $emulatorExe
				if (Test-Path $emulatorPath) {
					Write-Info "Launching: $emulatorPath"
					Start-Process $emulatorPath -ArgumentList "`"$romPath`""
					Write-Success "Emulator launched"
					return
				}
			}

			Write-Warning "Emulator not found in configured paths"
		}
		else {
			Write-Warning "Built ROM not found: $romPath"
		}
	}
}

<#
.SYNOPSIS
	Creates and configures file system watcher.
.DESCRIPTION
	Sets up FileSystemWatcher to monitor specified paths for changes to
	assembly source files (.asm, .s, .inc).
.LINK
	https://docs.microsoft.com/en-us/dotnet/api/system.io.filesystemwatcher
#>
function New-FileWatcher {
	param([string]$Path)

	$fullPath = Join-Path $script:ScriptRoot $Path

	if (-not (Test-Path $fullPath)) {
		Write-Warning "Watch path does not exist: $fullPath"
		return $null
	}

	Write-Info "Watching: $fullPath"

	# Create FileSystemWatcher
	# https://docs.microsoft.com/en-us/dotnet/api/system.io.filesystemwatcher
	$watcher = New-Object System.IO.FileSystemWatcher
	$watcher.Path = $fullPath
	$watcher.IncludeSubdirectories = $true
	$watcher.EnableRaisingEvents = $true

	# Watch for assembly files
	$watcher.Filter = "*.*"

	# Define event handlers
	$onChange = {
		param($source, $eventArgs)

		$extension = [System.IO.Path]::GetExtension($eventArgs.Name)

		# Only trigger on assembly source files
		if ($extension -in @('.asm', '.s', '.inc')) {
			$relativePath = $eventArgs.FullPath.Replace($script:ScriptRoot, "").TrimStart('\')
			$reason = "File changed: $relativePath"

			Invoke-DebouncedBuild -Reason $reason
		}
	}

	$onCreate = {
		param($source, $eventArgs)

		$extension = [System.IO.Path]::GetExtension($eventArgs.Name)

		if ($extension -in @('.asm', '.s', '.inc')) {
			$relativePath = $eventArgs.FullPath.Replace($script:ScriptRoot, "").TrimStart('\')
			$reason = "File created: $relativePath"

			Invoke-DebouncedBuild -Reason $reason
		}
	}

	$onDelete = {
		param($source, $eventArgs)

		$extension = [System.IO.Path]::GetExtension($eventArgs.Name)

		if ($extension -in @('.asm', '.s', '.inc')) {
			$relativePath = $eventArgs.FullPath.Replace($script:ScriptRoot, "").TrimStart('\')
			$reason = "File deleted: $relativePath"

			Write-Warning $reason
		}
	}

	$onRename = {
		param($source, $eventArgs)

		$extension = [System.IO.Path]::GetExtension($eventArgs.Name)

		if ($extension -in @('.asm', '.s', '.inc')) {
			$oldRelative = $eventArgs.OldFullPath.Replace($script:ScriptRoot, "").TrimStart('\')
			$newRelative = $eventArgs.FullPath.Replace($script:ScriptRoot, "").TrimStart('\')
			$reason = "File renamed: $oldRelative -> $newRelative"

			Invoke-DebouncedBuild -Reason $reason
		}
	}

	# Register event handlers
	# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/register-objectevent
	Register-ObjectEvent -InputObject $watcher -EventName "Changed" -Action $onChange | Out-Null
	Register-ObjectEvent -InputObject $watcher -EventName "Created" -Action $onCreate | Out-Null
	Register-ObjectEvent -InputObject $watcher -EventName "Deleted" -Action $onDelete | Out-Null
	Register-ObjectEvent -InputObject $watcher -EventName "Renamed" -Action $onRename | Out-Null

	return $watcher
}

#endregion

#region Main Execution

try {
	Write-Section "FFMQ Build Watch v2.0.0"

	Write-Info "Development mode: Automatic rebuild on file changes"
	Write-Info "Debounce delay: ${DebounceMs}ms"
	if ($autoLaunch) {
		Write-Info "Auto-launch: Enabled"
	}
	Write-Host ""

	# Create watchers for all paths
	$watchers = @()
	foreach ($path in $WatchPath) {
		$watcher = New-FileWatcher -Path $path
		if ($watcher) {
			$watchers += $watcher
		}
	}

	if ($watchers.Count -eq 0) {
		throw "No valid watch paths configured"
	}

	Write-Host ""
	Write-Success "File watching started"
	Write-Info "Monitoring $($watchers.Count) path(s) for changes"
	Write-Host ""
	Write-Host "Press Ctrl+C to stop watching..." -ForegroundColor Yellow
	Write-Host ""

	# Initial build
	Invoke-Build -Reason "Initial build"

	# Keep script running and check for pending builds
	while ($true) {
		Start-Sleep -Milliseconds 100

		# Check if there's a pending build after debounce period
		if ($script:PendingBuild) {
			$timeSinceLastBuild = ([DateTime]::Now - $script:LastBuildTime).TotalMilliseconds
			if ($timeSinceLastBuild -ge $debounceMs) {
				Invoke-DebouncedBuild -Reason "Debounced file changes"
			}
		}
	}
}
catch {
	Write-Host ""
	Write-Error "Watch mode failed: $_"
	Write-Host ""
}
finally {
	# Cleanup watchers
	if ($watchers) {
		foreach ($watcher in $watchers) {
			if ($watcher) {
				$watcher.EnableRaisingEvents = $false
				$watcher.Dispose()
			}
		}
	}

	# Unregister event handlers
	Get-EventSubscriber | Unregister-Event

	Write-Host ""
	Write-Info "File watching stopped"
	Write-Host ""
}

#endregion
