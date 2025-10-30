#Requires -Version 5.1
<#
.SYNOPSIS
	ROM validation and comparison tool for FFMQ build system.

.DESCRIPTION
	Comprehensive validation system that verifies built ROMs against the original,
	generates detailed comparison reports, and tracks disassembly progress.

.PARAMETER RomPath
	Path to the ROM to validate

.PARAMETER ReferencePath
	Path to reference ROM for comparison

.PARAMETER OutputReport
	Path to save detailed comparison report

.PARAMETER Verbose
	Enable verbose output

.EXAMPLE
	.\Build-Validator.ps1 -RomPath "build\ffmq-rebuilt.sfc"
	Validates the built ROM

.EXAMPLE
	.\Build-Validator.ps1 -RomPath "build\ffmq-rebuilt.sfc" -ReferencePath "roms\original.sfc" -OutputReport "build\comparison.txt"
	Compares ROMs and generates detailed report

.LINK
	https://github.com/TheAnsarya/ffmq-info

.NOTES
	Author: Build System Team
	Date: October 30, 2025
	Version: 2.0.0
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[string]$RomPath,

	[Parameter()]
	[string]$ReferencePath = "",

	[Parameter()]
	[string]$OutputReport = "",

	[Parameter()]
	[switch]$Verbose
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ScriptRoot = Split-Path -Parent $PSScriptRoot

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
	Validates ROM header information.
.DESCRIPTION
	Checks SNES ROM header for correct formatting and checksums.
.LINK
	https://snes.nesdev.org/wiki/ROM_file_formats
	https://en.wikibooks.org/wiki/Super_NES_Programming/SNES_memory_map
#>
function Test-RomHeader {
	param([byte[]]$RomData)

	Write-Info "Validating ROM header..."

	# SNES ROM header is at $00ffc0 in HiROM mode
	# https://snes.nesdev.org/wiki/ROM_header
	$headerOffset = 0xffc0

	# Internal ROM name (21 bytes at $ffc0)
	$romName = [System.Text.Encoding]::ASCII.GetString($RomData, $headerOffset, 21).Trim()
	Write-Info "ROM Name: $romName"

	# ROM makeup byte ($ffd5)
	$romMakeup = $RomData[$headerOffset + 0x15]
	$mapMode = $romMakeup -band 0x0f
	$speed = ($romMakeup -band 0x10) -shr 4

	$mapModeStr = switch ($mapMode) {
		0 { "LoROM" }
		1 { "HiROM" }
		2 { "LoROM + S-DD1" }
		3 { "LoROM + SA-1" }
		5 { "ExHiROM" }
		default { "Unknown ($mapMode)" }
	}

	$speedStr = if ($speed -eq 0) { "SlowROM" } else { "FastROM" }

	Write-Info "Map Mode: $mapModeStr, Speed: $speedStr"

	# ROM type ($ffd6)
	$romType = $RomData[$headerOffset + 0x16]
	Write-Info "ROM Type: 0x$($romType.ToString('x2'))"

	# ROM size ($ffd7) - Size = 1024 << value
	$romSizeValue = $RomData[$headerOffset + 0x17]
	$romSize = 1024 * [Math]::Pow(2, $romSizeValue)
	Write-Info "ROM Size: $romSize bytes ($romSizeValue)"

	# SRAM size ($ffd8)
	$sramSizeValue = $RomData[$headerOffset + 0x18]
	if ($sramSizeValue -gt 0) {
		$sramSize = 1024 * [Math]::Pow(2, $sramSizeValue)
		Write-Info "SRAM Size: $sramSize bytes"
	}
	else {
		Write-Info "SRAM Size: None"
	}

	# Checksums
	$complement = [BitConverter]::ToUInt16($RomData, $headerOffset + 0x1c)
	$checksum = [BitConverter]::ToUInt16($RomData, $headerOffset + 0x1e)

	Write-Info "Checksum: 0x$($checksum.ToString('x4'))"
	Write-Info "Complement: 0x$($complement.ToString('x4'))"

	# Validate checksum complement
	# https://snes.nesdev.org/wiki/ROM_header#Checksum
	$expectedComplement = 0xffff - $checksum
	if ($complement -eq $expectedComplement) {
		Write-Success "Checksum complement valid"
	}
	else {
		Write-Warning "Checksum complement mismatch! Expected: 0x$($expectedComplement.ToString('x4'))"
	}

	return @{
		Name       = $romName
		MapMode    = $mapModeStr
		Speed      = $speedStr
		Type       = $romType
		Size       = $romSize
		SramSize   = if ($sramSizeValue -gt 0) { $sramSize } else { 0 }
		Checksum   = $checksum
		Complement = $complement
	}
}

<#
.SYNOPSIS
	Compares two ROMs byte-by-byte and generates detailed difference report.
#>
function Compare-Roms {
	param(
		[byte[]]$Rom1,
		[byte[]]$Rom2,
		[string]$Rom1Name = "ROM 1",
		[string]$Rom2Name = "ROM 2"
	)

	Write-Info "Comparing ROMs byte-by-byte..."

	$differences = @()
	$minSize = [Math]::Min($Rom1.Length, $Rom2.Length)

	# Compare byte-by-byte
	# https://docs.microsoft.com/en-us/dotnet/api/system.array
	for ($i = 0; $i -lt $minSize; $i++) {
		if ($Rom1[$i] -ne $Rom2[$i]) {
			$differences += @{
				Offset = $i
				Byte1  = $Rom1[$i]
				Byte2  = $Rom2[$i]
			}
		}
	}

	# Check for size differences
	if ($Rom1.Length -ne $Rom2.Length) {
		Write-Warning "ROM sizes differ: $Rom1Name=$($Rom1.Length), $Rom2Name=$($Rom2.Length)"
	}

	Write-Host ""

	if ($differences.Count -eq 0) {
		Write-Success "✨ ROMs are byte-for-byte identical!"
		return @{
			Identical   = $true
			Differences = 0
			MatchPercent = 100.0
		}
	}
	else {
		$matchPercent = (1 - ($differences.Count / $minSize)) * 100

		Write-Warning "Found $($differences.Count) differences"
		Write-Info "Match: $([math]::Round($matchPercent, 4))%"
		Write-Host ""

		# Show first few differences
		$showCount = [Math]::Min(20, $differences.Count)
		Write-Info "First $showCount differences:"
		Write-Host ""
		Write-Host "  Offset       $Rom1Name  $Rom2Name" -ForegroundColor Gray
		Write-Host "  ─────────────────────────────────" -ForegroundColor Gray

		for ($i = 0; $i -lt $showCount; $i++) {
			$diff = $differences[$i]
			$offsetStr = "0x$($diff.Offset.ToString('x6'))"
			$byte1Str = "0x$($diff.Byte1.ToString('x2'))"
			$byte2Str = "0x$($diff.Byte2.ToString('x2'))"

			Write-Host "  $offsetStr    $byte1Str      $byte2Str" -ForegroundColor White
		}

		if ($differences.Count -gt $showCount) {
			Write-Host "  ... and $($differences.Count - $showCount) more" -ForegroundColor Gray
		}

		Write-Host ""

		return @{
			Identical    = $false
			Differences  = $differences.Count
			MatchPercent = $matchPercent
			DiffList     = $differences
		}
	}
}

<#
.SYNOPSIS
	Generates detailed comparison report.
#>
function New-ComparisonReport {
	param(
		[hashtable]$ComparisonResult,
		[hashtable]$Rom1Header,
		[hashtable]$Rom2Header,
		[string]$Rom1Path,
		[string]$Rom2Path,
		[string]$OutputPath
	)

	Write-Info "Generating comparison report..."

	$report = @"
═══════════════════════════════════════════════════════════════════════════
  FFMQ ROM Comparison Report
  Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
═══════════════════════════════════════════════════════════════════════════

ROM 1: $Rom1Path
ROM 2: $Rom2Path

───────────────────────────────────────────────────────────────────────────
  ROM 1 Header Information
───────────────────────────────────────────────────────────────────────────
Name:       $($Rom1Header.Name)
Map Mode:   $($Rom1Header.MapMode)
Speed:      $($Rom1Header.Speed)
Type:       0x$($Rom1Header.Type.ToString('x2'))
Size:       $($Rom1Header.Size) bytes
SRAM Size:  $($Rom1Header.SramSize) bytes
Checksum:   0x$($Rom1Header.Checksum.ToString('x4'))
Complement: 0x$($Rom1Header.Complement.ToString('x4'))

───────────────────────────────────────────────────────────────────────────
  ROM 2 Header Information
───────────────────────────────────────────────────────────────────────────
Name:       $($Rom2Header.Name)
Map Mode:   $($Rom2Header.MapMode)
Speed:      $($Rom2Header.Speed)
Type:       0x$($Rom2Header.Type.ToString('x2'))
Size:       $($Rom2Header.Size) bytes
SRAM Size:  $($Rom2Header.SramSize) bytes
Checksum:   0x$($Rom2Header.Checksum.ToString('x4'))
Complement: 0x$($Rom2Header.Complement.ToString('x4'))

───────────────────────────────────────────────────────────────────────────
  Comparison Results
───────────────────────────────────────────────────────────────────────────
Identical:      $($ComparisonResult.Identical)
Differences:    $($ComparisonResult.Differences)
Match Percent:  $([math]::Round($ComparisonResult.MatchPercent, 4))%

"@

	if (-not $ComparisonResult.Identical -and $ComparisonResult.DiffList) {
		$report += @"
───────────────────────────────────────────────────────────────────────────
  Detailed Differences
───────────────────────────────────────────────────────────────────────────

Offset       ROM 1    ROM 2
───────────────────────────────

"@

		foreach ($diff in $ComparisonResult.DiffList) {
			$offsetStr = "0x$($diff.Offset.ToString('x6'))"
			$byte1Str = "0x$($diff.Byte1.ToString('x2'))"
			$byte2Str = "0x$($diff.Byte2.ToString('x2'))"
			$report += "$offsetStr    $byte1Str       $byte2Str`r`n"
		}
	}

	$report += @"

═══════════════════════════════════════════════════════════════════════════
  End of Report
═══════════════════════════════════════════════════════════════════════════
"@

	# Save report
	$reportDir = Split-Path $OutputPath -Parent
	if ($reportDir -and -not (Test-Path $reportDir)) {
		New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
	}

	$report | Out-File $OutputPath -Encoding UTF8
	Write-Success "Report saved: $OutputPath"
}

#endregion

#region Main Execution

try {
	Write-Section "FFMQ ROM Validator v2.0.0"

	# Resolve paths
	$romFullPath = Join-Path $script:ScriptRoot $RomPath
	if (-not (Test-Path $romFullPath)) {
		throw "ROM not found: $romFullPath"
	}

	Write-Info "ROM: $romFullPath"

	# Load ROM
	Write-Info "Loading ROM..."
	$romData = [System.IO.File]::ReadAllBytes($romFullPath)
	Write-Success "Loaded $($romData.Length) bytes"
	Write-Host ""

	# Validate header
	Write-Section "ROM Header Validation"
	$romHeader = Test-RomHeader -RomData $romData

	# Compare with reference if provided
	if ($ReferencePath) {
		$refFullPath = Join-Path $script:ScriptRoot $ReferencePath
		if (-not (Test-Path $refFullPath)) {
			throw "Reference ROM not found: $refFullPath"
		}

		Write-Section "ROM Comparison"
		Write-Info "Reference: $refFullPath"
		Write-Host ""

		# Load reference ROM
		Write-Info "Loading reference ROM..."
		$refData = [System.IO.File]::ReadAllBytes($refFullPath)
		Write-Success "Loaded $($refData.Length) bytes"
		Write-Host ""

		# Validate reference header
		$refHeader = Test-RomHeader -RomData $refData

		# Compare
		$comparison = Compare-Roms `
			-Rom1 $romData `
			-Rom2 $refData `
			-Rom1Name "Built" `
			-Rom2Name "Original"

		# Generate report if requested
		if ($OutputReport) {
			$reportFullPath = Join-Path $script:ScriptRoot $OutputReport
			New-ComparisonReport `
				-ComparisonResult $comparison `
				-Rom1Header $romHeader `
				-Rom2Header $refHeader `
				-Rom1Path $romFullPath `
				-Rom2Path $refFullPath `
				-OutputPath $reportFullPath
		}

		# Calculate SHA256
		Write-Section "Checksum Verification"
		Write-Info "Calculating SHA256 checksums..."
		$romHash = Get-FileHash $romFullPath -Algorithm SHA256
		$refHash = Get-FileHash $refFullPath -Algorithm SHA256

		Write-Info "Built:    $($romHash.Hash.ToLower())"
		Write-Info "Original: $($refHash.Hash.ToLower())"
		Write-Host ""

		if ($romHash.Hash -eq $refHash.Hash) {
			Write-Success "✨ SHA256 checksums match!"
		}
		else {
			Write-Warning "SHA256 checksums differ"
		}
	}

	Write-Host ""
	Write-Success "Validation complete!"
	Write-Host ""
}
catch {
	Write-Host ""
	Write-Error "Validation failed: $_"
	Write-Host ""
	exit 1
}

#endregion
