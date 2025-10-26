# FFMQ Development Watch Mode
# Auto-rebuilds on file changes and launches emulator
# Modern SNES development workflow

param(
    [string]$EmulatorPath = "mesen-s.exe",
    [switch]$NoEmulator,
    [switch]$Verbose
)

$ErrorActionPreference = "Continue"

# Colors
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

# Configuration
$MainAsm = "src/asm/ffmq_complete.asm"
$BaseRom = Resolve-Path "~roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"
$OutputRom = "build/ffmq-modified.sfc"
$WatchPath = "src/asm"
$BuildDir = "build"

# Ensure build directory exists
if (!(Test-Path $BuildDir)) {
    New-Item -ItemType Directory -Path $BuildDir -Force | Out-Null
}

# Banner
Clear-Host
Write-Info "╔════════════════════════════════════════════════════════════╗"
Write-Info "║     FFMQ Modern Development Environment (2025)             ║"
Write-Info "╚════════════════════════════════════════════════════════════╝"
Write-Host ""
Write-Info "⚡ Features:"
Write-Host "  • Auto-rebuild on file changes"
Write-Host "  • Hot-reload emulator"
Write-Host "  • Build performance tracking"
Write-Host "  • Error highlighting"
Write-Host ""
Write-Info "📂 Watching: $WatchPath/**/*.asm"
Write-Info "🎮 Emulator: $EmulatorPath"
Write-Info "🔧 Main file: $MainAsm"
Write-Host ""
Write-Warning "Press Ctrl+C to exit"
Write-Host ""
Write-Host "─" * 60
Write-Host ""

# Build function
function Invoke-Build {
    param([bool]$IsInitial = $false)
    
    $buildStart = Get-Date
    
    if ($IsInitial) {
        Write-Info "🔨 Initial build..."
    } else {
        Write-Host ""
        Write-Info "🔄 Rebuilding... ($(Get-Date -Format 'HH:mm:ss'))"
    }
    
    # Copy base ROM
    Copy-Item $BaseRom $OutputRom -Force
    
    # Run asar
    $asarOutput = & asar --verbose --werror $MainAsm $OutputRom 2>&1
    $exitCode = $LASTEXITCODE
    
    $buildTime = ((Get-Date) - $buildStart).TotalMilliseconds
    
    if ($exitCode -eq 0) {
        $romSize = (Get-Item $OutputRom).Length
        Write-Success "✓ Build successful! (${buildTime}ms, $romSize bytes)"
        
        # Launch emulator on initial build
        if ($IsInitial -and !$NoEmulator) {
            Write-Info "🎮 Launching emulator..."
            try {
                Start-Process $EmulatorPath -ArgumentList $OutputRom -ErrorAction SilentlyContinue
                Write-Success "✓ Emulator started"
            } catch {
                Write-Warning "⚠ Could not launch emulator: $_"
                Write-Info "Continuing in watch mode without emulator..."
            }
        }
        
        return $true
    } else {
        Write-Error "✗ Build failed!"
        if ($Verbose) {
            Write-Host $asarOutput
        } else {
            # Show only error lines
            $asarOutput | Where-Object { $_ -match "error|warning" } | ForEach-Object {
                Write-Error "  $_"
            }
        }
        return $false
    }
}

# Initial build
$buildSuccess = Invoke-Build -IsInitial $true

if (!$buildSuccess) {
    Write-Error ""
    Write-Error "Initial build failed. Fix errors and save to rebuild."
    Write-Host ""
}

# File watcher
$watcher = New-Object System.IO.FileSystemWatcher
$watcher.Path = $WatchPath
$watcher.Filter = "*.asm"
$watcher.IncludeSubdirectories = $true
$watcher.EnableRaisingEvents = $true

# Debounce (prevent multiple builds from rapid saves)
$lastBuild = Get-Date
$debounceMs = 500

# Change handler
$onChange = {
    param($sender, $e)
    
    $now = Get-Date
    $timeSinceLastBuild = ($now - $script:lastBuild).TotalMilliseconds
    
    if ($timeSinceLastBuild -gt $script:debounceMs) {
        $script:lastBuild = $now
        
        $changedFile = $e.FullPath | Resolve-Path -Relative
        Write-Info "📝 Changed: $changedFile"
        
        Invoke-Build
    }
}

# Register events
Register-ObjectEvent $watcher "Changed" -Action $onChange | Out-Null
Register-ObjectEvent $watcher "Created" -Action $onChange | Out-Null
Register-ObjectEvent $watcher "Deleted" -Action $onChange | Out-Null

Write-Success "✓ Watch mode active!"
Write-Host ""

# Keep running
try {
    while ($true) {
        Start-Sleep -Seconds 1
    }
} finally {
    # Cleanup
    $watcher.EnableRaisingEvents = $false
    $watcher.Dispose()
    Get-EventSubscriber | Unregister-Event
    Write-Host ""
    Write-Info "Watch mode stopped."
}
