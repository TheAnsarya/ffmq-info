<#
.SYNOPSIS
	Rename labels that conflict with instruction names.

.DESCRIPTION
	Renames labels like RTS:, PHP:, SEC:, etc. to RTS_Label:, PHP_Label:, etc.
	This prevents conflicts when converting to lowercase where 'rts:' would
	be ambiguous with the 'rts' instruction.

.PARAMETER Path
	File or directory to process.

.PARAMETER DryRun
	Preview changes without modifying files.

.EXAMPLE
	.\rename_instruction_labels.ps1 -Path src/asm -DryRun
	Preview label renames

.EXAMPLE
	.\rename_instruction_labels.ps1 -Path src/asm
	Rename all conflicting labels
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[string]$Path,

	[Parameter()]
	[switch]$dryRun
)

# List of instruction names that might be used as labels
$script:InstructionNames = @(
	'ADC', 'AND', 'ASL', 'BCC', 'BCS', 'BEQ', 'BIT', 'BMI', 'BNE', 'BPL',
	'BRA', 'BRK', 'BRL', 'BVC', 'BVS', 'CLC', 'CLD', 'CLI', 'CLV', 'CMP',
	'COP', 'CPX', 'CPY', 'DEC', 'DEX', 'DEY', 'EOR', 'INC', 'INX', 'INY',
	'JML', 'JMP', 'JSL', 'JSR', 'LDA', 'LDX', 'LDY', 'LSR', 'MVN', 'MVP',
	'NOP', 'ORA', 'PEA', 'PEI', 'PER', 'PHA', 'PHB', 'PHD', 'PHK', 'PHP',
	'PHX', 'PHY', 'PLA', 'PLB', 'PLD', 'PLP', 'PLX', 'PLY', 'REP', 'ROL',
	'ROR', 'RTI', 'RTL', 'RTS', 'SBC', 'SEC', 'SED', 'SEI', 'SEP', 'STA',
	'STP', 'STX', 'STY', 'STZ', 'TAX', 'TAY', 'TCD', 'TCS', 'TDC', 'TRB',
	'TSB', 'TSC', 'TSX', 'TXA', 'TXS', 'TXY', 'TYA', 'TYX', 'WAI', 'WDM',
	'XBA', 'XCE'
)

function Rename-InstructionLabels {
	param(
		[System.IO.FileInfo]$file,
		[bool]$dryRun
	)

	Write-Host "Processing: $($file.FullName)" -ForegroundColor Cyan

	# Read file
	$content = Get-Content -Path $file.FullName -Raw -Encoding UTF8
	$lines = $content -split "`r`n|`r|`n"

	$modified = $false
	$changeCount = 0
	$newLines = @()

	foreach ($line in $lines) {
		$newLine = $line

		# Check if line is a label (starts with optional whitespace, then identifier, then colon)
		if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*):') {
			$labelName = $Matches[1]

			# Check if label name matches an instruction
			if ($labelName -in $script:InstructionNames) {
				# Rename the label
				$newLabelName = "${labelName}_Label"
				$pattern = "^(\s*)${labelName}:"
				$replacement = "`$1${newLabelName}:"
				$newLine = $line -replace $pattern, $replacement

				if ($newLine -ne $line) {
					$modified = $true
					$changeCount++
					Write-Host "  Line ${changeCount}: ${labelName}: -> ${newLabelName}:" -ForegroundColor Yellow
				}
			}
		}

		$newLines += $newLine
	}

	if (-not $modified) {
		Write-Host "  No conflicting labels found" -ForegroundColor Gray
		return @{
			File = $file.FullName
			Changed = $false
			ChangeCount = 0
		}
	}

	if ($dryRun) {
		Write-Host "  [DRY-RUN] Would rename $changeCount labels" -ForegroundColor Yellow
		return @{
			File = $file.FullName
			Changed = $true
			DryRun = $true
			ChangeCount = $changeCount
		}
	}

	# Write modified content
	$newContent = ($newLines -join "`r`n")
	if (-not $newContent.EndsWith("`r`n")) {
		$newContent += "`r`n"
	}

	# Create backup
	$backupPath = $file.FullName + '.bak'
	Copy-Item -Path $file.FullName -Destination $backupPath -Force

	# Write file
	[System.IO.File]::WriteAllText($file.FullName, $newContent, [System.Text.UTF8Encoding]::new($true))

	Write-Host "  ✓ Renamed $changeCount labels" -ForegroundColor Green

	return @{
		File = $file.FullName
		Changed = $true
		DryRun = $false
		ChangeCount = $changeCount
	}
}

# Main script
Write-Host "`n=== Instruction Label Renamer ===" -ForegroundColor Cyan
Write-Host "Fixing labels that conflict with instruction names`n" -ForegroundColor Gray

# Get files
if (Test-Path -Path $Path -PathType Leaf) {
	$files = @(Get-Item -Path $Path)
}
else {
	$files = Get-ChildItem -Path $Path -Filter "*.asm" -Recurse -File
}

Write-Host "Files to process: $($files.Count)`n" -ForegroundColor White

# Process files
$results = @()
foreach ($file in $files) {
	$result = Rename-InstructionLabels -File $file -DryRun:$dryRun
	$results += $result
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$totalChanged = ($results | Where-Object { $_.Changed -eq $true }).Count
$totalLabelsRenamed = ($results | Measure-Object -Property ChangeCount -Sum).Sum

Write-Host "Files processed: $($files.Count)" -ForegroundColor White
Write-Host "Files modified: $totalChanged" -ForegroundColor Green
Write-Host "Labels renamed: $totalLabelsRenamed" -ForegroundColor White

if ($dryRun -and $totalChanged -gt 0) {
	Write-Host "`nRe-run without -DryRun to apply changes." -ForegroundColor Yellow
}

Write-Host ""
