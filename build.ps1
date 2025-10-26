# Build FFMQ ROM from source
#
# Usage:
#   .\build.ps1                    # Basic build
#   .\build.ps1 -Verbose           # Verbose output
#   .\build.ps1 -Symbols           # Generate symbol file
#   .\build.ps1 -Output test.sfc   # Custom output path

param(
    [string]$Source = "src\asm\ffmq_working.asm",
    [string]$Output = "build\ffmq-rebuilt.sfc",
    [switch]$Symbols,
    [switch]$Verbose,
    [switch]$Clean
)

$ErrorActionPreference = "Stop"

# Script directory
$ScriptDir = $PSScriptRoot

# Colors for output
function Write-Success { param($Message) Write-Host "✅ $Message" -ForegroundColor Green }
function Write-Error { param($Message) Write-Host "❌ $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "ℹ️  $Message" -ForegroundColor Cyan }
function Write-Warning { param($Message) Write-Host "⚠️  $Message" -ForegroundColor Yellow }

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host "  FFMQ Disassembly Build System" -ForegroundColor Magenta
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
Write-Host ""

# Clean build directory if requested
if ($Clean) {
    Write-Info "Cleaning build directory..."
    if (Test-Path "build") {
        Remove-Item "build\*" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Success "Build directory cleaned"
    }
}

# Create build directory
if (-not (Test-Path "build")) {
    Write-Info "Creating build directory..."
    New-Item -ItemType Directory -Path "build" | Out-Null
    Write-Success "Build directory created"
}

# Copy base ROM
$baseRom = Resolve-Path "~roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc" -ErrorAction SilentlyContinue
if ($baseRom -and (Test-Path $baseRom)) {
    Write-Info "Copying base ROM..."
    Copy-Item $baseRom $Output -Force
    Write-Success "Base ROM copied"
} else {
    Write-Warning "Base ROM not found at ~roms/. Output will be patch-only."
}

# Check for asar
Write-Info "Checking for asar assembler..."
$asarPath = $null

# Check in PATH
$asarPath = Get-Command "asar" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source

# Check in project root
if (-not $asarPath) {
    if (Test-Path "asar.exe") {
        $asarPath = Join-Path $ScriptDir "asar.exe"
        Write-Info "Found asar in project root"
    }
}

# Check in tools directory
if (-not $asarPath) {
    if (Test-Path "tools\asar.exe") {
        $asarPath = Join-Path $ScriptDir "tools\asar.exe"
        Write-Info "Found asar in tools directory"
    }
}

if (-not $asarPath) {
    Write-Error "asar assembler not found!"
    Write-Host ""
    Write-Host "Please install asar:" -ForegroundColor Yellow
    Write-Host "  1. Download from: https://github.com/RPGHacker/asar/releases" -ForegroundColor White
    Write-Host "  2. Extract asar.exe to project root or add to PATH" -ForegroundColor White
    Write-Host ""
    exit 1
}

Write-Success "Found asar: $asarPath"

# Build arguments
$asarArgs = @()

if ($Verbose) {
    $asarArgs += "-v"
}

if ($Symbols) {
    $symbolFile = Join-Path "build" "symbols.sym"
    $asarArgs += "--symbols=wla"
    $asarArgs += $symbolFile
    Write-Info "Symbol file: $symbolFile"
}

$asarArgs += $Source
$asarArgs += $Output

# Show build info
Write-Host ""
Write-Info "Source: $Source"
Write-Info "Output: $Output"
Write-Host ""

# Build
Write-Info "Starting assembly..."
Write-Host ""

$buildStart = Get-Date

try {
    & $asarPath @asarArgs
    $exitCode = $LASTEXITCODE
} catch {
    $exitCode = 1
    Write-Error "Assembly failed with exception: $_"
}

$buildEnd = Get-Date
$buildTime = ($buildEnd - $buildStart).TotalSeconds

Write-Host ""

if ($exitCode -eq 0) {
    Write-Success "Assembly completed in $([math]::Round($buildTime, 2)) seconds"
    Write-Host ""
    
    # Check output file
    if (Test-Path $Output) {
        $fileInfo = Get-Item $Output
        $fileSize = $fileInfo.Length
        $expectedSize = 1048576  # 1MB
        
        Write-Info "Output file: $Output"
        Write-Info "File size: $fileSize bytes"
        
        if ($fileSize -eq $expectedSize) {
            Write-Success "File size matches expected 1MB"
        } else {
            Write-Warning "File size is $fileSize bytes (expected $expectedSize)"
            Write-Warning "ROM may not be correctly padded"
        }
        
        # Calculate hash
        Write-Host ""
        Write-Info "Calculating SHA256 hash..."
        $hash = Get-FileHash $Output -Algorithm SHA256
        Write-Info "SHA256: $($hash.Hash)"
        
        # Compare with original if available
        $originalRom = "~roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc"
        if (Test-Path $originalRom) {
            Write-Host ""
            Write-Info "Comparing with original ROM..."
            $originalHash = Get-FileHash $originalRom -Algorithm SHA256
            
            if ($hash.Hash -eq $originalHash.Hash) {
                Write-Success "✨ PERFECT MATCH! ROM is byte-for-byte identical to original!"
            } else {
                Write-Warning "ROM differs from original"
                Write-Info "Original: $($originalHash.Hash)"
                Write-Info "Rebuilt:  $($hash.Hash)"
            }
        }
        
        Write-Host ""
        Write-Success "Build complete!"
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Cyan
        Write-Host "  • Test in emulator: mesen $Output" -ForegroundColor White
        Write-Host "  • View symbols: build\symbols.sym (if generated)" -ForegroundColor White
        Write-Host "  • Compare with original ROM" -ForegroundColor White
        
    } else {
        Write-Error "Output file was not created!"
        exit 1
    }
    
} else {
    Write-Error "Assembly failed with exit code $exitCode"
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "  • Check error messages above" -ForegroundColor White
    Write-Host "  • Verify all include files exist" -ForegroundColor White
    Write-Host "  • Check for label conflicts" -ForegroundColor White
    Write-Host "  • Review docs\build-instructions.md" -ForegroundColor White
    Write-Host ""
    exit $exitCode
}

Write-Host ""
