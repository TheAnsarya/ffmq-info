<#
.SYNOPSIS
	Convert all ASM code and hex values to lowercase.

.DESCRIPTION
	Converts assembly files, documentation, and data files to use lowercase:
	- Assembly instructions (LDA → lda, STA → sta, etc.)
	- Registers (A, X, Y → a, x, y)
	- Directives (.ORG → .org, .DB → .db, etc.)
	- Hexadecimal values ($0abc → $0abc, $ff → $ff)
	- Label hex addresses (DATA8_0a8000 → DATA8_0a8000)

.PARAMETER Path
	File or directory to convert. Directories are processed recursively.

.PARAMETER FileType
	Type of files to process: ASM, Markdown, CSV, JSON, All

.PARAMETER DryRun
	Preview changes without modifying files.

.PARAMETER SkipBackup
	Skip creating backup before modifying files.

.PARAMETER Filter
	File pattern filter (default depends on FileType)

.EXAMPLE
	.\convert_to_lowercase.ps1 -Path src/asm -FileType ASM -DryRun
	Preview ASM conversion

.EXAMPLE
	.\convert_to_lowercase.ps1 -Path docs -FileType Markdown
	Convert all markdown files

.EXAMPLE
	.\convert_to_lowercase.ps1 -Path . -FileType All
	Convert entire project

.NOTES
	Author: GitHub Copilot
	Version: 1.0
	Date: 2025-11-01
	Issue: #48 ASM Formatting - Convert All Code to Lowercase
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $true, Position = 0)]
	[string]$Path,

	[Parameter(Mandatory = $false)]
	[ValidateSet('ASM', 'Markdown', 'CSV', 'JSON', 'PowerShell', 'Python', 'All')]
	[string]$fileType = 'ASM',

	[Parameter()]
	[switch]$dryRun,

	[Parameter()]
	[switch]$SkipBackup,

	[Parameter()]
	[string[]]$filter
)

#region Configuration

$script:FileTypeFilters = @{
	'ASM' = @('*.asm', '*.s', '*.inc')
	'Markdown' = @('*.md')
	'CSV' = @('*.csv')
	'JSON' = @('*.json')
	'PowerShell' = @('*.ps1')
	'Python' = @('*.py')
	'All' = @('*.asm', '*.s', '*.inc', '*.md', '*.csv', '*.json', '*.ps1', '*.py')
}

# Patterns to convert
$script:Patterns = @{
	# 65816 instructions (3-letter opcodes)
	Instructions = @(
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

	# Directives
	Directives = @(
		'.ORG', '.DB', '.DW', '.DL', '.DD', '.BYTE', '.WORD', '.LONG', '.DWORD',
		'.ASCII', '.ASCIIZ', '.INCLUDE', '.INCBIN', '.EQU', '.DEFINE', '.MACRO',
		'.ENDM', '.REPT', '.ENDR', '.IF', '.ELSE', '.ENDIF', '.SECTION', '.ENDS',
		'.BANK', '.BASE', '.FILL', '.PAD', '.ALIGN', '.DS', '.DSB', '.DSW'
	)

	# WLA-DX specific (without dots)
	WLADirectives = @(
		'ORG', 'DB', 'DW', 'DL', 'DD', 'BYTE', 'WORD', 'LONG', 'DWORD',
		'ASCII', 'ASCIIZ', 'INCLUDE', 'INCBIN', 'EQU', 'DEFINE', 'MACRO',
		'ENDM', 'REPT', 'ENDR', 'SECTION', 'ENDS', 'BANK', 'BASE', 'FILL',
		'PAD', 'ALIGN', 'DS', 'DSB', 'DSW', 'PRINT', 'PRINTT', 'PRINTV'
	)

	# Register names (when standalone)
	Registers = @('A', 'X', 'Y', 'S', 'P', 'DB', 'DP', 'PB')
}

#endregion

#region Helper Functions

function Write-Status {
	param(
		[string]$Message,
		[ValidateSet('Info', 'Success', 'Warning', 'Error', 'Verbose')]
		[string]$Type = 'Info'
	)

	$color = switch ($Type) {
		'Info' { 'Cyan' }
		'Success' { 'Green' }
		'Warning' { 'Yellow' }
		'Error' { 'Red' }
		'Verbose' { 'Gray' }
	}

	if ($Type -eq 'Verbose' -and $VerbosePreference -ne 'Continue') {
		return
	}

	Write-Host $Message -ForegroundColor $color
}

function Convert-HexToLowercase {
	param([string]$Text)

	if ([string]::IsNullOrEmpty($Text)) {
		return $Text
	}

	# Convert $XXXX hex values to lowercase
	# Use simple regex with callback
	$pattern = '\$([0-9A-Fa-f]+)'
	$result = [regex]::Replace($Text, $pattern, {
		param($match)
		'$' + $match.Groups[1].Value.ToLower()
	})

	return $result
}

function Convert-InstructionsToLowercase {
	param([string]$Text)

	if ([string]::IsNullOrEmpty($Text)) {
		return $Text
	}

	$result = $Text

	# Convert instructions (word boundaries)
	foreach ($instruction in $script:Patterns.Instructions) {
		# Use word boundaries to avoid partial matches
		$result = $result -creplace "\b$instruction\b", $instruction.ToLower()
	}

	return $result
}

function Convert-DirectivesToLowercase {
	param([string]$Text)

	if ([string]::IsNullOrEmpty($Text)) {
		return $Text
	}

	$result = $Text

	# Convert directives with dots
	foreach ($directive in $script:Patterns.Directives) {
		$escaped = [regex]::Escape($directive)
		$result = $result -creplace "$escaped\b", $directive.ToLower()
	}

	# Convert WLA-DX directives (without dots, but only at start of words)
	foreach ($directive in $script:Patterns.WLADirectives) {
		$result = $result -creplace "\b$directive\b", $directive.ToLower()
	}

	return $result
}

function Convert-RegistersToLowercase {
	param([string]$Text)

	if ([string]::IsNullOrEmpty($Text)) {
		return $Text
	}

	$result = $Text

	# Only convert registers when they appear as standalone operands
	# e.g., ",X" or ",Y" or standalone "A"
	$result = $result -creplace ',X\b', ',x'
	$result = $result -creplace ',Y\b', ',y'
	$result = $result -creplace ',S\b', ',s'

	# Standalone register at end of line or before comment
	$result = $result -creplace '\bA\s*(;|$)', 'a$1'
	$result = $result -creplace '\bX\s*(;|$)', 'x$1'
	$result = $result -creplace '\bY\s*(;|$)', 'y$1'

	return $result
}

function Convert-LabelHexToLowercase {
	param([string]$Text)

	if ([string]::IsNullOrEmpty($Text)) {
		return $Text
	}

	# Convert DATA8_XXXXXX, DATA16_XXXXXX, ADDR_XXXXXX labels
	$pattern = '(DATA8_|DATA16_|ADDR_)([0-9A-Fa-f]{6})'
	$result = [regex]::Replace($Text, $pattern, {
		param($match)
		$match.Groups[1].Value + $match.Groups[2].Value.ToLower()
	})

	return $result
}function Convert-AsmLine {
	param([string]$Line)

	# Skip blank lines
	if ([string]::IsNullOrWhiteSpace($Line)) {
		return $Line
	}

	# Skip lines that are only comments (don't convert hex in comments for now)
	if ($Line -match '^\s*;') {
		# Still convert hex in comments
		return Convert-HexToLowercase -Text $Line
	}

	# Split line into code and comment parts
	$semicolonIndex = $Line.IndexOf(';')
	if ($semicolonIndex -ge 0) {
		$codePart = $Line.Substring(0, $semicolonIndex)
		$commentPart = $Line.Substring($semicolonIndex)
	}
	else {
		$codePart = $Line
		$commentPart = ''
	}

	# Convert code part
	$codePart = Convert-HexToLowercase -Text $codePart
	$codePart = Convert-InstructionsToLowercase -Text $codePart
	$codePart = Convert-DirectivesToLowercase -Text $codePart
	$codePart = Convert-RegistersToLowercase -Text $codePart
	$codePart = Convert-LabelHexToLowercase -Text $codePart

	# Convert hex in comment part
	if ($commentPart) {
		$commentPart = Convert-HexToLowercase -Text $commentPart
	}

	return $codePart + $commentPart
}function Convert-MarkdownContent {
	param([string]$content)

	# Convert hex values in markdown
	$result = Convert-HexToLowercase -Text $content

	# Convert hex in code blocks and inline code
	# This preserves the structure but lowercases hex

	return $result
}

function Convert-CsvContent {
	param([string]$content)

	# Convert hex values in CSV
	# Be careful with quoted fields
	$lines = $content -split "`r`n|`r|`n"
	$convertedLines = @()

	foreach ($line in $lines) {
		$convertedLine = Convert-HexToLowercase -Text $line
		$convertedLine = Convert-LabelHexToLowercase -Text $convertedLine
		$convertedLines += $convertedLine
	}

	return ($convertedLines -join "`r`n")
}

function Convert-JsonContent {
	param([string]$content)

	# Convert hex values in JSON
	# Be careful with string values
	$result = Convert-HexToLowercase -Text $content
	$result = Convert-LabelHexToLowercase -Text $result

	return $result
}

function Convert-PowerShellContent {
	param([string]$content)

	# Convert hex values in PowerShell scripts
	# Be careful with strings and comments
	$lines = $content -split "`r`n|`r|`n"
	$convertedLines = @()

	foreach ($line in $lines) {
		# Convert hex values
		$convertedLine = Convert-HexToLowercase -Text $line
		$convertedLine = Convert-LabelHexToLowercase -Text $convertedLine
		$convertedLines += $convertedLine
	}

	return ($convertedLines -join "`r`n")
}

function Convert-PythonContent {
	param([string]$content)

	# Convert hex values in Python scripts
	$lines = $content -split "`r`n|`r|`n"
	$convertedLines = @()

	foreach ($line in $lines) {
		# Convert hex values (Python uses 0x prefix too)
		$convertedLine = Convert-HexToLowercase -Text $line
		$convertedLine = Convert-LabelHexToLowercase -Text $convertedLine

		# Also handle 0xXXXX format
		$pattern = '0x([0-9A-Fa-f]+)'
		$convertedLine = [regex]::Replace($convertedLine, $pattern, {
			param($match)
			'0x' + $match.Groups[1].Value.ToLower()
		})

		$convertedLines += $convertedLine
	}

	return ($convertedLines -join "`r`n")
}function Convert-FileContent {
	param(
		[string]$content,
		[string]$extension
	)

	switch ($extension.ToLower()) {
		{ $_ -in @('.asm', '.s', '.inc') } {
			$lines = $content -split "`r`n|`r|`n"
			$convertedLines = @()
			foreach ($line in $lines) {
				$convertedLines += Convert-AsmLine -Line $line
			}
			return ($convertedLines -join "`r`n")
		}
		'.md' {
			return Convert-MarkdownContent -Content $content
		}
		'.csv' {
			return Convert-CsvContent -Content $content
		}
		'.json' {
			return Convert-JsonContent -Content $content
		}
		'.ps1' {
			return Convert-PowerShellContent -Content $content
		}
		'.py' {
			return Convert-PythonContent -Content $content
		}
		default {
			Write-Status "Unknown file type: $extension" -Type Warning
			return $content
		}
	}
}

function Test-FileChanged {
	param(
		[string]$Original,
		[string]$converted
	)

	return $Original -cne $converted  # Case-sensitive comparison
}

function Get-ChangeCount {
	param(
		[string]$Original,
		[string]$converted
	)

	if ([string]::IsNullOrEmpty($Original) -and [string]::IsNullOrEmpty($converted)) {
		return 0
	}

	$originalLines = if ($Original) { $Original -split "`r`n|`r|`n" } else { @() }
	$convertedLines = if ($converted) { $converted -split "`r`n|`r|`n" } else { @() }

	$maxCount = [Math]::Max($originalLines.Count, $convertedLines.Count)
	if ($maxCount -eq 0) { return 0 }

	$changes = 0
	for ($i = 0; $i -lt $maxCount; $i++) {
		$origLine = if ($i -lt $originalLines.Count) { $originalLines[$i] } else { '' }
		$convLine = if ($i -lt $convertedLines.Count) { $convertedLines[$i] } else { '' }

		if ($origLine -cne $convLine) {
			$changes++
		}
	}

	return $changes
}function Get-FilesToProcess {
	param(
		[string]$Path,
		[string[]]$filter
	)

	if (Test-Path -Path $Path -PathType Leaf) {
		return @(Get-Item -Path $Path)
	}
	elseif (Test-Path -Path $Path -PathType Container) {
		$files = @()
		foreach ($pattern in $filter) {
			$files += Get-ChildItem -Path $Path -Filter $pattern -Recurse -File
		}
		return $files
	}
	else {
		throw "Path not found: $Path"
	}
}

function Convert-File {
	param(
		[System.IO.FileInfo]$file,
		[bool]$dryRun,
		[bool]$SkipBackup
	)

	Write-Status "Processing: $($file.FullName)" -Type Verbose

	try {
		# Read file
		$originalContent = Get-Content -Path $file.FullName -Raw -Encoding UTF8

		if ([string]::IsNullOrEmpty($originalContent)) {
			Write-Status "  File is empty, skipping" -Type Verbose
			return @{
				File = $file.FullName
				Changed = $false
				ChangeCount = 0
			}
		}

		# Convert content
		try {
			$convertedContent = Convert-FileContent -Content $originalContent -Extension $file.Extension
		}
		catch {
			Write-Status "  ✗ Error converting content: $_" -Type Error
			Write-Status "  Stack trace: $($_.ScriptStackTrace)" -Type Verbose
			return @{
				File = $file.FullName
				Changed = $false
				Error = "Conversion error: $($_.Exception.Message)"
			}
		}

		# Check if changed
		if (-not (Test-FileChanged -Original $originalContent -Converted $convertedContent)) {
			Write-Status "  No changes needed" -Type Verbose
			return @{
				File = $file.FullName
				Changed = $false
				ChangeCount = 0
			}
		}

		$changeCount = Get-ChangeCount -Original $originalContent -Converted $convertedContent

		if ($dryRun) {
			Write-Status "  [DRY-RUN] Would convert: $($file.Name) ($changeCount lines changed)" -Type Warning
			return @{
				File = $file.FullName
				Changed = $true
				DryRun = $true
				ChangeCount = $changeCount
			}
		}

		# Create backup
		if (-not $SkipBackup) {
			$backupPath = $file.FullName + '.bak'
			Copy-Item -Path $file.FullName -Destination $backupPath -Force
			Write-Status "  Backup created: $backupPath" -Type Verbose
		}

		# Write converted content (preserve encoding)
		[System.IO.File]::WriteAllText($file.FullName, $convertedContent, [System.Text.UTF8Encoding]::new($true))

		Write-Status "  ✓ Converted: $($file.Name) ($changeCount lines changed)" -Type Success

		return @{
			File = $file.FullName
			Changed = $true
			DryRun = $false
			ChangeCount = $changeCount
		}
	}
	catch {
		Write-Status "  ✗ Error: $_" -Type Error
		Write-Status "  Stack trace: $($_.ScriptStackTrace)" -Type Verbose
		return @{
			File = $file.FullName
			Changed = $false
			Error = $_.Exception.Message
		}
	}
}#endregion

#region Main Script

try {
	Write-Host "`n=== FFMQ Lowercase Converter ===" -ForegroundColor Cyan
	Write-Host "Version 1.0 | Issue #48 | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor Gray

	# Validate PowerShell version
	if ($PSVersionTable.PSVersion.Major -lt 7) {
		Write-Status "This script requires PowerShell 7 or later." -Type Error
		Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Red
		exit 1
	}

	# Resolve path
	$resolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
	Write-Host "Target: $resolvedPath" -ForegroundColor White
	Write-Host "File Type: $fileType" -ForegroundColor White

	# Determine filter
	$actualFilter = if ($filter) { $filter } else { $script:FileTypeFilters[$fileType] }
	Write-Host "Filter: $($actualFilter -join ', ')" -ForegroundColor White

	if ($dryRun) {
		Write-Host "Mode: DRY-RUN (preview only)" -ForegroundColor Yellow
	}
	else {
		Write-Host "Mode: CONVERTING" -ForegroundColor Green
	}
	Write-Host ""

	# Get files
	$files = Get-FilesToProcess -Path $resolvedPath -Filter $actualFilter

	if ($files.Count -eq 0) {
		Write-Status "No files found matching filter." -Type Warning
		exit 0
	}

	Write-Host "Files to process: $($files.Count)" -ForegroundColor White
	Write-Host ""

	# Process files
	$results = @()
	foreach ($file in $files) {
		$result = Convert-File -File $file -DryRun:$dryRun -SkipBackup:$SkipBackup
		$results += $result
	}

	# Summary
	Write-Host "`n=== Summary ===" -ForegroundColor Cyan

	$totalProcessed = $results.Count
	$totalChanged = ($results | Where-Object { $_.Changed -eq $true }).Count
	$totalUnchanged = ($results | Where-Object { $_.Changed -eq $false -and -not $_.Error }).Count
	$totalErrors = ($results | Where-Object { $_.Error }).Count
	$totalLineChanges = ($results | Measure-Object -Property ChangeCount -Sum).Sum

	Write-Host "Files processed: $totalProcessed" -ForegroundColor White
	Write-Host "Files converted: $totalChanged" -ForegroundColor $(if ($totalChanged -gt 0) { 'Green' } else { 'Gray' })
	Write-Host "Files unchanged: $totalUnchanged" -ForegroundColor Gray
	Write-Host "Total line changes: $totalLineChanges" -ForegroundColor White

	if ($totalErrors -gt 0) {
		Write-Host "Errors: $totalErrors" -ForegroundColor Red
	}

	if ($dryRun -and $totalChanged -gt 0) {
		Write-Host "`nRe-run without -DryRun to apply changes." -ForegroundColor Yellow
	}

	Write-Host ""

	exit 0
}
catch {
	Write-Status "`n✗ Fatal error: $_" -Type Error
	Write-Host $_.ScriptStackTrace -ForegroundColor Red
	exit 1
}

#endregion
