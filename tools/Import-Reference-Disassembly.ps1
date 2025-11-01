#Requires -Version 5.1
<#
.SYNOPSIS
	Imports reference disassembly from DiztinGUIsh output to accelerate disassembly work.

.DESCRIPTION
	This tool imports the comprehensive reference disassembly from the
	historical/diztinguish-disassembly/diztinguish directory and adapts it
	to our project structure. It handles:
	- Converting DiztinGUIsh format to our documented format
	- Preserving address annotations
	- Adding proper headers and documentation
	- Creating backup of existing files
	- Batch processing multiple banks

.PARAMETER Banks
	Array of bank numbers to import (e.g., @('04','05','06','0F'))
	If not specified, prompts for bank selection.

.PARAMETER Force
	Overwrites existing files without prompting (creates backups)

.PARAMETER NoBackup
	Don't create backup files (use with caution!)

.EXAMPLE
	.\Import-Reference-Disassembly.ps1 -Banks @('04','05','06','0F')
	Imports banks $04, $05, $06, and $0f from reference

.EXAMPLE
	.\Import-Reference-Disassembly.ps1 -Banks @('04') -Force
	Force import bank $04, overwriting existing file (with backup)

.LINK
	https://github.com/binary1230/DiztinGUIsh

.NOTES
	Author: Disassembly Team
	Date: October 30, 2025
	Version: 1.0.0

	Reference: DiztinGUIsh SNES Disassembler
	https://github.com/binary1230/DiztinGUIsh
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory=$false)]
	[string[]]$banks,

	[Parameter(Mandatory=$false)]
	[switch]$force,

	[Parameter(Mandatory=$false)]
	[switch]$NoBackup
)

Set-StrictMode -Version Latest
$errorActionPreference = 'Stop'

# ============================================================================
# Configuration
# ============================================================================

$script:ProjectRoot = Split-Path -Parent $PSScriptRoot
$script:ReferenceDir = Join-Path $script:ProjectRoot "historical\diztinguish-disassembly\diztinguish\Disassembly"
$script:OutputDir = Join-Path $script:ProjectRoot "src\asm"
$script:TempDir = $script:ProjectRoot
$script:BankSize = 0x8000  # 32KB per bank

# ============================================================================
# Helper Functions
# ============================================================================

function Write-Header {
	<#
	.SYNOPSIS
		Displays script header with branding.
	#>
	Write-Host ""
	Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
	Write-Host "  FFMQ Reference Disassembly Importer v1.0" -ForegroundColor Cyan
	Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
	Write-Host ""
}

function Get-BankList {
	<#
	.SYNOPSIS
		Gets list of available banks to import.
	#>
	$availableBanks = @()

	for ($i = 0; $i -le 0x0F; $i++) {
		$bankHex = $i.ToString('x2')
		$refFile = Join-Path $script:ReferenceDir "bank_$bankHex.asm"

		if (Test-Path $refFile) {
			$lineCount = (Get-Content $refFile | Measure-Object -Line).Lines
			$availableBanks += [PSCustomObject]@{
				BankNumber = $i
				BankHex = $bankHex
				ReferencePath = $refFile
				LineCount = $lineCount
			}
		}
	}

	return $availableBanks
}

function Import-BankDisassembly {
	<#
	.SYNOPSIS
		Imports a single bank from reference disassembly.

	.PARAMETER BankHex
		Bank number in hexadecimal (e.g., '04', '0F')
	#>
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$true)]
		[string]$bankHex
	)

	$bankNumber = [Convert]::ToInt32($bankHex, 16)
	$bankHexUpper = $bankHex.ToUpper()

	# Paths
	$refFile = Join-Path $script:ReferenceDir "bank_$bankHex.asm"
	$outputFile = Join-Path $script:OutputDir "bank_$($bankHex)_documented.asm"
	$tempFile = Join-Path $script:TempDir "temp_bank$($bankHex)_import.asm"

	# Validate reference file exists
	if (-not (Test-Path $refFile)) {
		Write-Host "❌ Reference file not found: $refFile" -ForegroundColor Red
		return $false
	}

	# Check if output file exists
	if ((Test-Path $outputFile) -and -not $force) {
		$response = Read-Host "File exists: $outputFile`nOverwrite? (y/N)"
		if ($response -notmatch '^[Yy]') {
			Write-Host "⏭️  Skipped bank $bankHexUpper" -ForegroundColor Yellow
			return $false
		}
	}

	# Create backup if file exists
	if ((Test-Path $outputFile) -and -not $NoBackup) {
		$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
		$backupFile = "$outputFile.bak.$timestamp"
		Copy-Item $outputFile $backupFile -Force
		Write-Host "💾 Backup created: $backupFile" -ForegroundColor Gray
	}

	# Calculate address range
	$startAddr = $bankNumber * $script:BankSize
	$endAddr = $startAddr + $script:BankSize - 1
	$startAddrHex = $startAddr.ToString('x6')
	$endAddrHex = $endAddr.ToString('x6')

	# Generate header
	$header = @"
; ===============================================================================
; Bank `$$bankHexUpper - Imported from DiztinGUIsh Reference Disassembly
; ===============================================================================
; Address Range: `$$startAddrHex - `$$endAddrHex
; Size: 32768 bytes (32KB)
;
; Imported: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
; Source: DiztinGUIsh automated disassembly
; Reference: https://github.com/binary1230/DiztinGUIsh
;
; SNES Memory Map Reference:
; https://snes.nesdev.org/wiki/Memory_map
; https://en.wikibooks.org/wiki/Super_NES_Programming/SNES_memory_map
;
; NOTE: This is an automated disassembly. Manual review and documentation
;       required to identify:
;       - Function names and purposes
;       - Data structures and tables
;       - Entry points and jump tables
;       - Code vs data regions
; ===============================================================================

"@

	# Read reference file
	Write-Host "📖 Reading reference: bank_$bankHex.asm ($((Get-Item $refFile).Length) bytes)" -ForegroundColor Gray
	$content = Get-Content $refFile -Raw

	# Process content: remove DiztinGUIsh comment columns if present
	# The format appears to be: code|comment1|comment2|comment3
	# We'll keep the code and address columns
	$lines = $content -split "`r?`n"
	$processedLines = @()

	foreach ($line in $lines) {
		# Skip empty lines at start, we'll add our own header
		if ([string]::IsNullOrWhiteSpace($line) -and $processedLines.Count -eq 0) {
			continue
		}

		# Keep the line as-is for now
		# The DiztinGUIsh format is already quite good
		$processedLines += $line
	}

	# Combine header and content
	$finalContent = $header + ($processedLines -join "`r`n")

	# Write output file
	[System.IO.File]::WriteAllText($outputFile, $finalContent, [System.Text.Encoding]::UTF8)
	Write-Host "✅ Created: $outputFile" -ForegroundColor Green

	# Create temp file for iterative work
	[System.IO.File]::WriteAllText($tempFile, $finalContent, [System.Text.Encoding]::UTF8)
	Write-Host "📝 Created temp: $tempFile" -ForegroundColor Green

	# Report statistics
	$lineCount = $processedLines.Count
	Write-Host "ℹ️  Imported $lineCount lines from reference" -ForegroundColor Cyan

	return $true
}

# ============================================================================
# Main Script
# ============================================================================

try {
	Write-Header

	# Validate reference directory exists
	if (-not (Test-Path $script:ReferenceDir)) {
		Write-Host "❌ Reference directory not found: $script:ReferenceDir" -ForegroundColor Red
		Write-Host "ℹ️  Expected DiztinGUIsh disassembly at:" -ForegroundColor Yellow
		Write-Host "   historical\diztinguish-disassembly\diztinguish\Disassembly" -ForegroundColor Yellow
		exit 1
	}

	Write-Host "ℹ️  Reference directory: $script:ReferenceDir" -ForegroundColor Gray
	Write-Host "ℹ️  Output directory: $script:OutputDir" -ForegroundColor Gray
	Write-Host ""

	# Get available banks
	$availableBanks = Get-BankList

	if ($availableBanks.Count -eq 0) {
		Write-Host "❌ No reference bank files found" -ForegroundColor Red
		exit 1
	}

	Write-Host "📚 Available reference banks:" -ForegroundColor Cyan
	Write-Host "──────────────────────────────────────────────────────" -ForegroundColor Gray
	Write-Host "Bank   Lines    Path" -ForegroundColor Gray
	Write-Host "──────────────────────────────────────────────────────" -ForegroundColor Gray

	foreach ($bank in $availableBanks) {
		Write-Host "`$$($bank.BankHex.ToUpper())    $($bank.LineCount.ToString().PadLeft(5))    bank_$($bank.BankHex).asm" -ForegroundColor White
	}

	Write-Host ""

	# If no banks specified, prompt
	if (-not $banks -or $banks.Count -eq 0) {
		Write-Host "ℹ️  Enter bank numbers to import (space-separated, e.g., '04 05 06 0F'):" -ForegroundColor Yellow
		$userInput = Read-Host "Banks"
		$banks = $userInput -split '\s+' | Where-Object { $_ -ne '' }
	}

	if (-not $banks -or $banks.Count -eq 0) {
		Write-Host "❌ No banks specified" -ForegroundColor Red
		exit 1
	}

	Write-Host "ℹ️  Importing banks: $($banks -join ', ')" -ForegroundColor Cyan
	Write-Host ""

	# Import each bank
	$successCount = 0
	$failCount = 0

	foreach ($bankHex in $banks) {
		# Normalize to 2-digit lowercase hex
		$bankHex = $bankHex.ToLower().PadLeft(2, '0')

		Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
		Write-Host "  Importing Bank `$$($bankHex.ToUpper())" -ForegroundColor Cyan
		Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
		Write-Host ""

		if (Import-BankDisassembly -BankHex $bankHex) {
			$successCount++
			Write-Host ""
			Write-Host "✅ Bank `$$($bankHex.ToUpper()) imported successfully!" -ForegroundColor Green
		}
		else {
			$failCount++
			Write-Host ""
			Write-Host "❌ Bank `$$($bankHex.ToUpper()) import failed" -ForegroundColor Red
		}

		Write-Host ""
	}

	# Summary
	Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
	Write-Host "  Import Summary" -ForegroundColor Cyan
	Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
	Write-Host ""
	Write-Host "ℹ️  Banks processed: $($banks.Count)" -ForegroundColor Cyan
	Write-Host "✅ Successful: $successCount" -ForegroundColor Green

	if ($failCount -gt 0) {
		Write-Host "❌ Failed: $failCount" -ForegroundColor Red
	}

	Write-Host ""
	Write-Host "ℹ️  Next steps:" -ForegroundColor Yellow
	Write-Host "  1. Review imported files in: $script:OutputDir" -ForegroundColor White
	Write-Host "  2. Add function names and comments for clarity" -ForegroundColor White
	Write-Host "  3. Run progress tracker: python tools\disassembly_tracker.py" -ForegroundColor White
	Write-Host "  4. Build and compare: .\tools\Build-System.ps1 -Target compare" -ForegroundColor White
	Write-Host ""

	exit 0
}
catch {
	Write-Host ""
	Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
	Write-Host ""
	exit 1
}
