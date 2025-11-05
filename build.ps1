# Build FFMQ ROM from source
#
# Usage:
#   .\build.ps1                    # Basic build
#   .\build.ps1 -Verbose           # Verbose output
#   .\build.ps1 -Symbols           # Generate symbol file
#   .\build.ps1 -Output test.sfc   # Custom output path
#   .\build.ps1 -DryRun            # Preview build without assembling
#   .\build.ps1 -Parallel          # Enable parallel processing (faster)
#   .\build.ps1 -ValidateROM       # Run ROM validation checks

param(
	[string]$Source = "src\asm\ffmq_working.asm",
	[string]$Output = "build\ffmq-rebuilt.sfc",
	[switch]$Symbols,
	[switch]$Verbose,
	[switch]$Clean,
	[switch]$DryRun,
	[switch]$Parallel,
	[switch]$ValidateROM
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

# ==============================================================================
# REAL BUILD - NO ROM COPYING!
# ==============================================================================
# Old behavior: Copy original ROM and patch over it (99.996% fake match)
# New behavior: Build entire ROM from scratch (HONEST progress tracking)
#
# The output ROM is built ENTIRELY from:
# - Disassembled assembly code
# - Extracted graphics binaries
# - Extracted palette data
# - Extracted text strings
# - Extracted game data (enemies, items, maps, etc.)
#
# This is the ONLY way to track real disassembly progress!
# ==============================================================================

Write-Info "Building ROM from scratch (no ROM copying!)"
Write-Warning "Progress is now HONEST - expect low match % until disassembly complete"

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

Write-Host ""

# Dry run mode
if ($DryRun) {
	Write-Info "DRY RUN MODE - No files will be modified"
	Write-Host ""
	Write-Info "Would build:"
	Write-Info "  Source: $Source"
	Write-Info "  Output: $Output"
	Write-Info "  Symbols: $(if ($Symbols) { 'Yes' } else { 'No' })"
	Write-Info "  Verbose: $(if ($Verbose) { 'Yes' } else { 'No' })"
	Write-Info "  Parallel: $(if ($Parallel) { 'Yes' } else { 'No' })"
	Write-Host ""

	# Check if source file exists
	if (Test-Path $Source) {
		Write-Success "Source file exists"
		$sourceInfo = Get-Item $Source
		Write-Info "Source size: $($sourceInfo.Length) bytes"
		Write-Info "Last modified: $($sourceInfo.LastWriteTime)"
	} else {
		Write-Error "Source file not found: $Source"
		exit 1
	}

	Write-Host ""
	Write-Success "Dry run complete. Use without -DryRun to actually build."
	exit 0
}

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
		
		# ROM Validation
		if ($ValidateROM) {
			Write-Host ""
			Write-Info "Running ROM validation checks..."
			
			$validationPassed = $true
			
			# Check 1: File size
			if ($fileSize -ne $expectedSize) {
				Write-Warning "FAIL: Incorrect file size"
				$validationPassed = $false
			} else {
				Write-Success "PASS: File size correct (1MB)"
			}
			
			# Check 2: Header validation
			Write-Info "Checking ROM header..."
			$romBytes = [System.IO.File]::ReadAllBytes($Output)
			
			# SNES header at 0x7FB0 (internal header location for LoROM)
			$headerOffset = 0x7FB0
			
			# Check game title (21 bytes at 0x7FB0)
			$titleBytes = $romBytes[$headerOffset..($headerOffset + 20)]
			$title = [System.Text.Encoding]::ASCII.GetString($titleBytes) -replace '\0', ''
			Write-Info "Game title: $title"
			
			if ($title -like "*MYSTIC*" -or $title -like "*FINAL*") {
				Write-Success "PASS: Valid game title detected"
			} else {
				Write-Warning "FAIL: Unexpected game title"
				$validationPassed = $false
			}
			
			# Check 3: Checksum (bytes at 0x7FDC-0x7FDD = complement, 0x7FDE-0x7FDF = actual)
			$checksumOffset = 0x7FDE
			$checksum = [BitConverter]::ToUInt16($romBytes, $checksumOffset)
			$complement = [BitConverter]::ToUInt16($romBytes, $checksumOffset - 2)
			Write-Info "Checksum: 0x$($checksum.ToString('X4'))"
			Write-Info "Complement: 0x$($complement.ToString('X4'))"
			
			if (($checksum -bxor $complement) -eq 0xFFFF) {
				Write-Success "PASS: Checksum and complement are valid"
			} else {
				Write-Warning "FAIL: Invalid checksum/complement pair"
				$validationPassed = $false
			}
			
			# Check 4: ROM type (LoROM expected)
			$romType = $romBytes[0x7FD5]
			if ($romType -eq 0x20 -or $romType -eq 0x30) {
				Write-Success "PASS: Valid ROM type (LoROM)"
			} else {
				Write-Warning "FAIL: Unexpected ROM type: 0x$($romType.ToString('X2'))"
				$validationPassed = $false
			}
			
			# Check 5: Region code
			$region = $romBytes[0x7FD9]
			$regionNames = @{
				0x00 = "Japan"
				0x01 = "North America"
				0x02 = "Europe"
			}
			$regionName = $regionNames[$region]
			if ($regionName) {
				Write-Success "PASS: Valid region ($regionName)"
			} else {
				Write-Warning "FAIL: Unknown region code: 0x$($region.ToString('X2'))"
				$validationPassed = $false
			}
			
			Write-Host ""
			if ($validationPassed) {
				Write-Success "✨ All ROM validation checks passed!"
			} else {
				Write-Warning "⚠️  Some validation checks failed"
				Write-Warning "ROM may not be compatible with emulators or real hardware"
			}
		}
		
		Write-Host ""
		Write-Host "Next steps:" -ForegroundColor Cyan
		Write-Host "  • Test in emulator: mesen $Output" -ForegroundColor White
		Write-Host "  • View symbols: build\symbols.sym (if generated)" -ForegroundColor White
		Write-Host "  • Compare with original ROM" -ForegroundColor White
		Write-Host "  • Run validation: .\build.ps1 -ValidateROM" -ForegroundColor White
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
