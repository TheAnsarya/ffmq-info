#Requires -Version 5.1
<#
.SYNOPSIS
	Aggressive bank disassembly script for rapid ROM bank extraction.

.DESCRIPTION
	Automates the process of disassembling ROM banks using the temp file workflow.
	Extracts raw bank data, creates initial disassembly, and sets up temp files
	for iterative refinement.

	This script is designed for SPEED - it processes banks quickly using automated
	tools and creates working temp files for manual refinement.

.PARAMETER Banks
	Array of bank numbers to disassemble (hex format: 00, 01, 0F, etc.)

.PARAMETER ReferenceRom
	Path to reference ROM file

.PARAMETER OutputDir
	Directory for temp files (defaults to project root)

.PARAMETER Force
	Overwrite existing files

.EXAMPLE
	.\Aggressive-Disassemble.ps1 -Banks @('0F')
	Disassemble bank $0F

.EXAMPLE
	.\Aggressive-Disassemble.ps1 -Banks @('04','05','06') -Force
	Aggressively disassemble banks $04, $05, $06

.LINK
	https://github.com/TheAnsarya/ffmq-info

.NOTES
	Author: Disassembly Team
	Date: October 30, 2025
	Version: 1.0.0

	SNES Memory Map Reference:
	https://snes.nesdev.org/wiki/Memory_map
	https://en.wikibooks.org/wiki/Super_NES_Programming/SNES_memory_map
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[string[]]$Banks,

	[Parameter()]
	[string]$ReferenceRom = "roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc",

	[Parameter()]
	[string]$OutputDir = ".",

	[Parameter()]
	[switch]$Force
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ScriptRoot = $PSScriptRoot | Split-Path -Parent
$script:BankSize = 0x8000  # 32KB per bank
$script:ProcessedBanks = 0

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
	Extracts a bank from the reference ROM.
.DESCRIPTION
	Reads raw binary data for a specific bank from the ROM file.
	SNES ROM banks are 32KB ($8000 bytes) each.
.LINK
	https://snes.nesdev.org/wiki/ROM_file_formats
#>
function Get-BankData {
	param(
		[int]$BankNumber,
		[string]$RomPath
	)

	if (-not (Test-Path $RomPath)) {
		throw "ROM file not found: $RomPath"
	}

	# Calculate bank offset
	# For HiROM: Bank $00 = offset $0000, Bank $01 = offset $8000, etc.
	$offset = $BankNumber * $script:BankSize

	Write-Info "Extracting bank $($BankNumber.ToString('x2').ToUpper()) from offset 0x$($offset.ToString('x6'))"

	# Read bank data
	$romData = [System.IO.File]::ReadAllBytes($RomPath)

	if ($offset + $script:BankSize -gt $romData.Length) {
		throw "Bank offset exceeds ROM size!"
	}

	$bankData = $romData[$offset..($offset + $script:BankSize - 1)]

	return $bankData
}

<#
.SYNOPSIS
	Creates an initial disassembly template for a bank.
.DESCRIPTION
	Generates a documented assembly file template with proper headers,
	organization comments, and data sections.
#>
function New-BankTemplate {
	param(
		[int]$BankNumber,
		[byte[]]$BankData,
		[string]$OutputPath
	)

	$bankHex = $BankNumber.ToString('x2')
	$bankAddr = ($BankNumber * $script:BankSize).ToString('x6')
	$endAddr = ($BankNumber * $script:BankSize + $script:BankSize - 1).ToString('x6')
	$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
	$bankHexUpper = $bankHex.ToUpper()

	# Build template (use single-quoted here-string to avoid variable expansion)
	$template = @'
; ===============================================================================
; Bank ${BANKHEX} - Auto-generated disassembly template
; ===============================================================================
; Address Range: ${BANKADDR} - ${ENDADDR}
; Size: 32768 bytes (32KB)
;
; Generated: ${TIMESTAMP}
; Reference ROM: Final Fantasy - Mystic Quest (U) (V1.1).sfc
;
; SNES Memory Map Reference:
; https://snes.nesdev.org/wiki/Memory_map
; https://en.wikibooks.org/wiki/Super_NES_Programming/SNES_memory_map
; ===============================================================================

; Bank origin in SNES memory map
org $${BANKADDR}

; ===============================================================================
; Bank ${BANKHEX} Header / Entry Points
; ===============================================================================

; TODO: Identify entry points and jump tables
; Common patterns:
; - JSL/JSR targets
; - Interrupt vectors
; - Data pointers

Bank${BANKHEXUPPER}_Start:

'@

	# Replace placeholders
	$template = $template.Replace('${BANKHEX}', "`$$bankHex")
	$template = $template.Replace('${BANKADDR}', "`$$bankAddr")
	$template = $template.Replace('${ENDADDR}', "`$$endAddr")
	$template = $template.Replace('${TIMESTAMP}', $timestamp)
	$template = $template.Replace('${BANKHEXUPPER}', $bankHexUpper)

	# Analyze data to identify code vs data regions
	# Simple heuristic: look for common opcodes
	$codeRegions = Find-CodeRegions -BankData $BankData

	if ($codeRegions -and $codeRegions.Length -gt 0) {
		$template += "`r`n"
		$template += "; ===============================================================================`r`n"
		$template += "; Detected Code Regions (Heuristic Analysis)`r`n"
		$template += "; ===============================================================================`r`n"
		$template += "; The following regions appear to contain executable code based on`r`n"
		$template += "; opcode pattern analysis. Manual verification required.`r`n"
		$template += ";`r`n"

		foreach ($region in $codeRegions) {
			$startAddr = ($BankNumber * $script:BankSize + $region.Start).ToString('x6')
			$endAddr = ($BankNumber * $script:BankSize + $region.End).ToString('x6')
			$template += "; Region: `$$startAddr - `$$endAddr ($($region.Length) bytes)`r`n"
		}
	}

	# Add raw data section
	$template += "`r`n"
	$template += "; ===============================================================================`r`n"
	$template += "; Raw Bank Data`r`n"
	$template += "; ===============================================================================`r`n"
	$template += "; This section contains the raw binary data from the ROM.`r`n"
	$template += "; Disassemble code regions and identify data structures.`r`n"
	$template += ";`r`n"
	$template += "; Strategy:`r`n"
	$template += "; 1. Identify code entry points (from bank `$00 references)`r`n"
	$template += "; 2. Disassemble code sections`r`n"
	$template += "; 3. Identify data tables and structures`r`n"
	$template += "; 4. Document thoroughly with comments`r`n"
	$template += "; ===============================================================================`r`n"
	$template += "`r`n"

	# Output first chunk of data as db statements
	# This gives a starting point for manual disassembly
	$chunkSize = 16
	for ($i = 0; $i -lt [Math]::Min(256, $BankData.Length); $i += $chunkSize) {
		$bytes = $BankData[$i..[Math]::Min($i + $chunkSize - 1, $BankData.Length - 1)]
		$hexBytes = ($bytes | ForEach-Object { '$' + $_.ToString('x2') }) -join ','
		$addr = ($BankNumber * $script:BankSize + $i).ToString('x6')
		$template += "db $hexBytes  ; `$$addr`r`n"
	}

	$template += @"

; ... (Remaining $(($BankData.Length - 256).ToString('N0')) bytes to disassemble)

; ===============================================================================
; End of Bank `$$bankHex
; ===============================================================================

"@

	# Write template to file
	$template | Out-File $OutputPath -Encoding UTF8 -Force

	return $template
}

<#
.SYNOPSIS
	Finds likely code regions in bank data using heuristic analysis.
.DESCRIPTION
	Analyzes byte patterns to identify regions that likely contain
	executable 65816 assembly code vs. data.
.LINK
	https://wiki.superfamicom.org/65816-reference
#>
function Find-CodeRegions {
	param([byte[]]$BankData)

	$regions = [System.Collections.ArrayList]::new()

	# Common 65816 opcodes (partial list)
	# https://wiki.superfamicom.org/65816-reference
	$commonOpcodes = @(
		0x18,  # CLC
		0x38,  # SEC
		0x4C,  # JMP absolute
		0x5C,  # JML long
		0x60,  # RTS
		0x6B,  # RTL
		0x80,  # BRA
		0x8D,  # STA absolute
		0x9C,  # STZ absolute
		0xA9,  # LDA immediate
		0xAD,  # LDA absolute
		0xC9,  # CMP immediate
		0xD0,  # BNE
		0xE8,  # INX
		0xF0   # BEQ
	)

	# Scan for regions with high opcode density
	$windowSize = 64
	$threshold = 0.3  # 30% common opcodes

	for ($i = 0; $i -lt ($BankData.Length - $windowSize); $i += $windowSize) {
		$window = $BankData[$i..($i + $windowSize - 1)]
		$matchingBytes = @($window | Where-Object { $_ -in $commonOpcodes })
		$opcodeCount = $matchingBytes.Count
		$density = $opcodeCount / $windowSize

		if ($density -ge $threshold) {
			# Found likely code region
			[void]$regions.Add(@{
				Start  = $i
				End    = $i + $windowSize - 1
				Length = $windowSize
			})
		}
	}

	return $regions.ToArray()
}

<#
.SYNOPSIS
	Creates a temp file for iterative disassembly work.
#>
function New-TempBankFile {
	param(
		[int]$BankNumber,
		[int]$Cycle = 1,
		[string]$OutputDir
	)

	$bankHex = $BankNumber.ToString('x2')
	$fileName = "temp_bank$($bankHex)_cycle$('{0:D2}' -f $Cycle).asm"
	$filePath = Join-Path $OutputDir $fileName

	Write-Info "Creating temp file: $fileName"

	# For now, just create a reference to the main bank file
	$content = @"
; ===============================================================================
; Temp Bank `$$bankHex - Cycle $Cycle
; ===============================================================================
; This is a temporary working file for iterative disassembly.
; Merge back into bank_$($bankHex)_documented.asm when complete.
;
; Cycle: $Cycle
; Date: $(Get-Date -Format 'yyyy-MM-dd')
; ===============================================================================

; Include the main bank file for reference
; incsrc "src/asm/bank_$($bankHex)_documented.asm"

; ===============================================================================
; Work Area - Cycle $Cycle
; ===============================================================================

; Add your disassembly work here
; Focus on specific sections and document thoroughly

; TODO: Disassemble next section of bank `$$bankHex

; ===============================================================================
; End of Cycle $Cycle
; ===============================================================================

"@

	$content | Out-File $filePath -Encoding UTF8 -Force

	return $filePath
}

<#
.SYNOPSIS
	Processes a single bank for disassembly.
#>
function Invoke-BankDisassembly {
	param(
		[int]$BankNumber,
		[string]$RomPath,
		[string]$OutputDir,
		[bool]$ForceOverwrite
	)

	$bankHex = $BankNumber.ToString('x2')

	Write-Section "Disassembling Bank `$$($bankHex.ToUpper())"

	# Check if documented file already exists
	$docFile = Join-Path $script:ScriptRoot "src\asm\bank_$($bankHex)_documented.asm"

	if ((Test-Path $docFile) -and -not $ForceOverwrite) {
		Write-Warning "Bank `$$($bankHex) already has documented file: $docFile"
		Write-Info "Use -Force to overwrite"

		$response = Read-Host "Continue with temp file creation only? (Y/N)"
		if ($response -ne 'Y') {
			Write-Info "Skipping bank `$$($bankHex)"
			return
		}
	}

	# Extract bank data
	try {
		$bankData = Get-BankData -BankNumber $BankNumber -RomPath $RomPath
		Write-Success "Extracted $($bankData.Length) bytes"
	}
	catch {
		Write-Error "Failed to extract bank data: $_"
		return
	}

	# Create/update documented file
	if ($ForceOverwrite -or -not (Test-Path $docFile)) {
		try {
			$docDir = Split-Path $docFile -Parent
			if (-not (Test-Path $docDir)) {
				New-Item -ItemType Directory -Path $docDir -Force | Out-Null
			}

			Write-Info "Creating template for bank `$$($bankHex)..."
			New-BankTemplate -BankNumber $BankNumber -BankData $bankData -OutputPath $docFile | Out-Null
			Write-Success "Created documented file: $docFile"
		}
		catch {
			Write-Error "Failed to create documented file: $($_.Exception.Message)"
			Write-Host "Exception details:" -ForegroundColor Red
			Write-Host $_.Exception -ForegroundColor Gray
			Write-Host $_.ScriptStackTrace -ForegroundColor Gray
			return
		}
	}

	# Create temp file for this disassembly session
	try {
		$tempFile = New-TempBankFile -BankNumber $BankNumber -Cycle 1 -OutputDir $OutputDir
		Write-Success "Created temp file: $tempFile"
	}
	catch {
		Write-Error "Failed to create temp file: $_"
		return
	}

	# Success!
	$script:ProcessedBanks++

	Write-Host ""
	Write-Success "Bank `$$($bankHex) disassembly initiated!"
	Write-Info "Next steps:"
	Write-Host "  1. Review $docFile" -ForegroundColor White
	Write-Host "  2. Identify code entry points from bank `$00 references" -ForegroundColor White
	Write-Host "  3. Use temp file for iterative work: $tempFile" -ForegroundColor White
	Write-Host "  4. Document thoroughly with comments" -ForegroundColor White
	Write-Host ""
}

#endregion

#region Main Execution

try {
	Write-Section "FFMQ Aggressive Bank Disassembler v1.0"

	Write-Info "Target banks: $($Banks -join ', ')"
	Write-Info "Reference ROM: $ReferenceRom"
	Write-Info "Output directory: $OutputDir"
	Write-Host ""

	# Validate ROM path
	$romFullPath = Join-Path $script:ScriptRoot $ReferenceRom
	if (-not (Test-Path $romFullPath)) {
		throw "Reference ROM not found: $romFullPath"
	}

	Write-Success "Found reference ROM: $romFullPath"
	$romSize = (Get-Item $romFullPath).Length
	Write-Info "ROM size: $($romSize.ToString('N0')) bytes"
	Write-Host ""

	# Process each bank
	foreach ($bankHex in $Banks) {
		# Convert hex string to number
		$bankNum = [Convert]::ToInt32($bankHex, 16)

		if ($bankNum -lt 0 -or $bankNum -gt 0x0F) {
			Write-Warning "Invalid bank number: `$$bankHex (must be 00-0F for 1MB ROM)"
			continue
		}

		Invoke-BankDisassembly `
			-BankNumber $bankNum `
			-RomPath $romFullPath `
			-OutputDir $OutputDir `
			-ForceOverwrite $Force
	}

	# Summary
	Write-Section "Disassembly Summary"

	Write-Info "Processed banks: $script:ProcessedBanks/$($Banks.Count)"

	if ($script:ProcessedBanks -gt 0) {
		Write-Success "Disassembly initiated successfully!"
		Write-Host ""
		Write-Info "Run the progress tracker to see updated status:"
		Write-Host "  python tools\disassembly_tracker.py" -ForegroundColor White
	}
	else {
		Write-Warning "No banks were processed"
	}

	Write-Host ""
}
catch {
	Write-Host ""
	Write-Error "Disassembly failed: $_"
	Write-Host ""
	Write-Host "Stack trace:" -ForegroundColor Red
	Write-Host $_.ScriptStackTrace -ForegroundColor Gray
	Write-Host ""
	exit 1
}

#endregion
