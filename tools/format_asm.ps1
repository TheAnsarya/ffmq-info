<#
.SYNOPSIS
	Format ASM source files according to project standards.

.DESCRIPTION
	Formats SNES 65816 assembly (.asm, .s, .inc) files to match .editorconfig standards:
	- Convert line endings to CRLF
	- Ensure UTF-8 encoding (with BOM)
	- Convert leading spaces to tabs (intelligent, preserves alignment)
	- Align assembly columns: labels, opcodes, operands, comments
	- Trim trailing whitespace
	- Ensure final newline

.PARAMETER Path
	File or directory to format. Directories are processed recursively.

.PARAMETER DryRun
	Preview changes without modifying files. Shows what would be changed.

.PARAMETER Verbose
	Show detailed information about processing and changes.

.PARAMETER SkipBackup
	Skip creating backup before modifying files (not recommended).

.PARAMETER Filter
	File pattern filter for directory processing (default: *.asm,*.s,*.inc)

.EXAMPLE
	.\format_asm.ps1 -Path src/asm/bank_00.asm
	Format a single file

.EXAMPLE
	.\format_asm.ps1 -Path src/asm -DryRun -Verbose
	Preview changes for all ASM files in directory (dry-run mode)

.EXAMPLE
	.\format_asm.ps1 -Path src/asm -Filter "*.asm"
	Format only .asm files in directory

.NOTES
	Author: GitHub Copilot
	Version: 1.0
	Date: 2025-11-01
	Requires: PowerShell 7+

.LINK
	https://github.com/TheAnsarya/ffmq-info
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $true, Position = 0, HelpMessage = "File or directory to format")]
	[string]$Path,

	[Parameter(HelpMessage = "Preview changes without modifying files")]
	[switch]$dryRun,

	[Parameter(HelpMessage = "Skip creating backup before modifying files")]
	[switch]$SkipBackup,

	[Parameter(HelpMessage = "File pattern filter for directory processing")]
	[string[]]$filter = @("*.asm", "*.s", "*.inc")
)

#region Configuration

# Column alignment settings for ASM formatting
$script:Config = @{
	# Column positions (0-based)
	LabelColumn   = 0      # Labels start at column 0
	OpcodeColumn  = 23     # Opcodes aligned at column 23 (based on bank_00.asm analysis)
	OperandColumn = 47     # Operands aligned at column 47
	CommentColumn = 57     # Comments start at column 57 (semicolon position)

	# Tab settings
	TabSize       = 4      # Tab width (from .editorconfig)
	UseSpaces     = $false # Use tabs for indentation (from .editorconfig)

	# Line ending settings
	LineEnding    = "`r`n" # CRLF (from .editorconfig)

	# Encoding settings
	Encoding      = 'utf8BOM' # UTF-8 with BOM (from .editorconfig)

	# Formatting behavior
	PreserveBlankLines = $true
	TrimTrailingWhitespace = $true
	InsertFinalNewline = $true

	# Patterns
	LabelPattern  = '^\s*([A-Za-z_][A-Za-z0-9_]*):?\s*$'       # Label only lines
	CodePattern   = '^\s*([A-Za-z_][A-Za-z0-9_]*:)?\s*([A-Za-z][A-Za-z0-9\.]*)\s*(.*?)\s*(;.*)?$' # Code lines
	CommentPattern = '^\s*(;.*)$'                               # Comment only lines
	DirectivePattern = '^\s*(\.[A-Za-z][A-Za-z0-9]*)\s*(.*?)\s*(;.*)?$' # Assembler directives
}

#endregion

#region Helper Functions

function Write-VerboseMessage {
	param([string]$Message)
	if ($VerbosePreference -eq 'Continue') {
		Write-Host $Message -ForegroundColor Cyan
	}
}

function Write-SuccessMessage {
	param([string]$Message)
	Write-Host $Message -ForegroundColor Green
}

function Write-WarningMessage {
	param([string]$Message)
	Write-Host $Message -ForegroundColor Yellow
}

function Write-ErrorMessage {
	param([string]$Message)
	Write-Host $Message -ForegroundColor Red
}

function Test-IsAsmFile {
	param([string]$filePath)
	$extension = [System.IO.Path]::GetExtension($filePath).ToLower()
	return $extension -in @('.asm', '.s', '.inc')
}

function Get-AsmFiles {
	param(
		[string]$Path,
		[string[]]$filter
	)

	if (Test-Path -Path $Path -PathType Leaf) {
		if (Test-IsAsmFile -FilePath $Path) {
			return @(Get-Item -Path $Path)
		}
		else {
			Write-WarningMessage "Skipping non-ASM file: $Path"
			return @()
		}
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

function Convert-SpacesToTabs {
	param(
		[string]$Line,
		[int]$TabSize = 4
	)

	# Only convert leading spaces, preserve spaces in strings and comments
	if ($Line -match '^( +)(.*)$') {
		$leadingSpaces = $Matches[1]
		$rest = $Matches[2]

		$spaceCount = $leadingSpaces.Length
		$tabCount = [Math]::Floor($spaceCount / $TabSize)
		$remainingSpaces = $spaceCount % $TabSize

		return ("`t" * $tabCount) + (" " * $remainingSpaces) + $rest
	}

	return $Line
}

function Get-ColumnPosition {
	param(
		[string]$Text,
		[int]$TabSize = 4
	)

	$position = 0
	foreach ($char in $Text.ToCharArray()) {
		if ($char -eq "`t") {
			# Tab advances to next tab stop
			$position = [Math]::Ceiling(($position + 1) / $TabSize) * $TabSize
		}
		else {
			$position++
		}
	}
	return $position
}

function Add-Padding {
	param(
		[string]$Text,
		[int]$TargetColumn,
		[int]$TabSize = 4,
		[bool]$UseTabs = $true
	)

	$currentColumn = Get-ColumnPosition -Text $Text -TabSize $TabSize

	if ($currentColumn -ge $TargetColumn) {
		# Already past target, add single space
		return $Text + " "
	}

	$spacesNeeded = $TargetColumn - $currentColumn

	if ($UseTabs) {
		# Use tabs where possible, spaces for remainder
		$tabsNeeded = [Math]::Floor($spacesNeeded / $TabSize)
		$spacesRemainder = $spacesNeeded % $TabSize
		return $Text + ("`t" * $tabsNeeded) + (" " * $spacesRemainder)
	}
	else {
		return $Text + (" " * $spacesNeeded)
	}
}

function Format-AsmLine {
	param(
		[string]$Line,
		[hashtable]$config
	)

	$originalLine = $Line

	# Preserve blank lines
	if ([string]::IsNullOrWhiteSpace($Line)) {
		return ""
	}

	# Convert leading spaces to tabs
	$Line = Convert-SpacesToTabs -Line $Line -TabSize $config.TabSize

	# Trim trailing whitespace
	$Line = $Line.TrimEnd()

	# Comment-only line
	if ($Line -match '^\s*(;.*)$') {
		$comment = $Matches[1]
		# Comments aligned to comment column
		$padding = "`t" * [Math]::Floor($config.CommentColumn / $config.TabSize)
		return $padding + $comment
	}

	# Label-only line (with optional colon)
	if ($Line -match '^\s*([A-Za-z_][A-Za-z0-9_]*):?\s*$') {
		$label = $Matches[1]
		# Labels start at column 0
		return $label + ":"
	}

	# Assembler directive (.ORG, .DB, etc.) - some assemblers use dots
	if ($Line -match '^\s*(\.[A-Za-z][A-Za-z0-9]*)\s+(.*?)\s*(;.*)?$') {
		$directive = $Matches[1]
		$args = $Matches[2]
		$comment = if ($Matches[3]) { $Matches[3] } else { "" }

		# Directives start at label column
		$result = $directive

		# Add operand
		if ($args) {
			$result = Add-Padding -Text $result -TargetColumn $config.OperandColumn -TabSize $config.TabSize -UseTabs (!$config.UseSpaces)
			$result += $args
		}

		# Add comment
		if ($comment) {
			$result = Add-Padding -Text $result -TargetColumn $config.CommentColumn -TabSize $config.TabSize -UseTabs (!$config.UseSpaces)
			$result += $comment
		}

		return $result
	}

	# Regular assembler directive (ORG, DB, etc.) - without dots
	if ($Line -match '^\s*([A-Z][A-Z0-9]*)\s+(.*?)\s*(;.*)?$') {
		$directive = $Matches[1]
		$args = $Matches[2]
		$comment = if ($Matches[3]) { $Matches[3] } else { "" }

		# Check if it's actually an instruction (3-letter opcodes)
		$isInstruction = $directive.Length -eq 3 -and $directive -match '^[A-Z]{3}$'

		if ($isInstruction) {
			# Format as instruction
			$result = ""
			$result = Add-Padding -Text $result -TargetColumn $config.OpcodeColumn -TabSize $config.TabSize -UseTabs (!$config.UseSpaces)
			$result += $directive

			if ($args) {
				$result = Add-Padding -Text $result -TargetColumn $config.OperandColumn -TabSize $config.TabSize -UseTabs (!$config.UseSpaces)
				$result += $args
			}

			if ($comment) {
				$result = Add-Padding -Text $result -TargetColumn $config.CommentColumn -TabSize $config.TabSize -UseTabs (!$config.UseSpaces)
				$result += $comment
			}

			return $result
		}
		else {
			# Format as directive
			$result = $directive

			if ($args) {
				$result = Add-Padding -Text $result -TargetColumn $config.OperandColumn -TabSize $config.TabSize -UseTabs (!$config.UseSpaces)
				$result += $args
			}

			if ($comment) {
				$result = Add-Padding -Text $result -TargetColumn $config.CommentColumn -TabSize $config.TabSize -UseTabs (!$config.UseSpaces)
				$result += $comment
			}

			return $result
		}
	}

	# Label + instruction on same line
	if ($Line -match '^\s*([A-Za-z_][A-Za-z0-9_]*):?\s+([A-Za-z][A-Za-z0-9\.]*)\s*(.*?)\s*(;.*)?$') {
		$label = $Matches[1]
		$opcode = $Matches[2]
		$operand = $Matches[3]
		$comment = if ($Matches[4]) { $Matches[4] } else { "" }

		# Label at column 0
		$result = $label + ":"

		# Opcode at opcode column
		$result = Add-Padding -Text $result -TargetColumn $config.OpcodeColumn -TabSize $config.TabSize -UseTabs (!$config.UseSpaces)
		$result += $opcode

		# Operand
		if ($operand) {
			$result = Add-Padding -Text $result -TargetColumn $config.OperandColumn -TabSize $config.TabSize -UseTabs (!$config.UseSpaces)
			$result += $operand
		}

		# Comment
		if ($comment) {
			$result = Add-Padding -Text $result -TargetColumn $config.CommentColumn -TabSize $config.TabSize -UseTabs (!$config.UseSpaces)
			$result += $comment
		}

		return $result
	}

	# Instruction-only line (no label) - must start with whitespace
	if ($Line -match '^\s+([A-Z][A-Z0-9\.]*)\s*(.*?)\s*(;.*)?$') {
		$opcode = $Matches[1]
		$operand = $Matches[2]
		$comment = if ($Matches[3]) { $Matches[3] } else { "" }

		$result = ""
		$result = Add-Padding -Text $result -TargetColumn $config.OpcodeColumn -TabSize $config.TabSize -UseTabs (!$config.UseSpaces)
		$result += $opcode

		if ($operand) {
			$result = Add-Padding -Text $result -TargetColumn $config.OperandColumn -TabSize $config.TabSize -UseTabs (!$config.UseSpaces)
			$result += $operand
		}

		if ($comment) {
			$result = Add-Padding -Text $result -TargetColumn $config.CommentColumn -TabSize $config.TabSize -UseTabs (!$config.UseSpaces)
			$result += $comment
		}

		return $result
	}	# If we get here, preserve the line as-is (but with space->tab conversion and trimming)
	return $Line
}

function Format-AsmContent {
	param(
		[string[]]$Lines,
		[hashtable]$config
	)

	$formattedLines = @()

	foreach ($line in $Lines) {
		$formattedLine = Format-AsmLine -Line $line -Config $config
		$formattedLines += $formattedLine
	}

	return $formattedLines
}

function Get-LineEndingType {
	param([string]$content)

	if ($content -match "`r`n") {
		return "CRLF"
	}
	elseif ($content -match "`n") {
		return "LF"
	}
	elseif ($content -match "`r") {
		return "CR"
	}
	else {
		return "None"
	}
}

function Compare-FileChanges {
	param(
		[string[]]$OriginalLines,
		[string[]]$formattedLines
	)

	$changes = @{
		LinesChanged = 0
		LinesAdded = 0
		LinesRemoved = 0
		TotalChanges = 0
	}

	$maxLines = [Math]::Max($OriginalLines.Count, $formattedLines.Count)

	for ($i = 0; $i -lt $maxLines; $i++) {
		$original = if ($i -lt $OriginalLines.Count) { $OriginalLines[$i] } else { $null }
		$formatted = if ($i -lt $formattedLines.Count) { $formattedLines[$i] } else { $null }

		if ($original -ne $formatted) {
			if ($null -eq $original) {
				$changes.LinesAdded++
			}
			elseif ($null -eq $formatted) {
				$changes.LinesRemoved++
			}
			else {
				$changes.LinesChanged++
			}
			$changes.TotalChanges++
		}
	}

	return $changes
}

function Format-AsmFile {
	param(
		[System.IO.FileInfo]$file,
		[hashtable]$config,
		[bool]$dryRun,
		[bool]$SkipBackup
	)

	Write-VerboseMessage "Processing: $($file.FullName)"

	try {
		# Read file content (detect encoding)
		$content = Get-Content -Path $file.FullName -Raw -Encoding UTF8

		# Detect original line endings
		$originalLineEnding = Get-LineEndingType -Content $content
		Write-VerboseMessage "  Original line ending: $originalLineEnding"

		# Split into lines (handle any line ending type)
		$lines = $content -split "`r`n|`r|`n"

		Write-VerboseMessage "  Total lines: $($lines.Count)"

		# Format lines
		$formattedLines = Format-AsmContent -Lines $lines -Config $config

		# Join lines with CRLF
		$formattedContent = ($formattedLines -join $config.LineEnding)

		# Ensure final newline
		if ($config.InsertFinalNewline -and -not $formattedContent.EndsWith($config.LineEnding)) {
			$formattedContent += $config.LineEnding
		}

		# Compare changes
		$changes = Compare-FileChanges -OriginalLines $lines -FormattedLines $formattedLines

		if ($changes.TotalChanges -eq 0) {
			Write-VerboseMessage "  No changes needed"
			return @{
				File = $file.FullName
				Changed = $false
				Changes = $changes
			}
		}

		Write-VerboseMessage "  Changes detected:"
		Write-VerboseMessage "    - Lines changed: $($changes.LinesChanged)"
		if ($changes.LinesAdded -gt 0) {
			Write-VerboseMessage "    - Lines added: $($changes.LinesAdded)"
		}
		if ($changes.LinesRemoved -gt 0) {
			Write-VerboseMessage "    - Lines removed: $($changes.LinesRemoved)"
		}

		if ($dryRun) {
			Write-Host "  [DRY-RUN] Would format: $($file.Name) ($($changes.TotalChanges) changes)" -ForegroundColor Yellow
			return @{
				File = $file.FullName
				Changed = $true
				DryRun = $true
				Changes = $changes
			}
		}

		# Create backup if not skipped
		if (-not $SkipBackup) {
			$backupPath = $file.FullName + ".bak"
			Copy-Item -Path $file.FullName -Destination $backupPath -Force
			Write-VerboseMessage "  Backup created: $backupPath"
		}

		# Write formatted content (UTF-8 with BOM)
		[System.IO.File]::WriteAllText($file.FullName, $formattedContent, [System.Text.UTF8Encoding]::new($true))

		Write-SuccessMessage "  ✓ Formatted: $($file.Name) ($($changes.TotalChanges) changes)"

		return @{
			File = $file.FullName
			Changed = $true
			DryRun = $false
			Changes = $changes
		}
	}
	catch {
		Write-ErrorMessage "  ✗ Error processing $($file.Name): $_"
		return @{
			File = $file.FullName
			Changed = $false
			Error = $_.Exception.Message
		}
	}
}

#endregion

#region Main Script

try {
	Write-Host "`n=== FFMQ ASM Formatter ===" -ForegroundColor Cyan
	Write-Host "Version 1.0 | $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`n" -ForegroundColor Gray

	# Validate PowerShell version
	if ($PSVersionTable.PSVersion.Major -lt 7) {
		Write-ErrorMessage "This script requires PowerShell 7 or later."
		Write-Host "Current version: $($PSVersionTable.PSVersion)" -ForegroundColor Red
		exit 1
	}

	# Resolve path
	$resolvedPath = Resolve-Path -Path $Path -ErrorAction Stop
	Write-Host "Target: $resolvedPath" -ForegroundColor White

	if ($dryRun) {
		Write-Host "Mode: DRY-RUN (preview only, no changes)" -ForegroundColor Yellow
	}
	else {
		Write-Host "Mode: FORMATTING (files will be modified)" -ForegroundColor Green
	}

	Write-Host ""

	# Get files to process
	$files = Get-AsmFiles -Path $resolvedPath -Filter $filter

	if ($files.Count -eq 0) {
		Write-WarningMessage "No ASM files found matching filter: $($filter -join ', ')"
		exit 0
	}

	Write-Host "Files to process: $($files.Count)" -ForegroundColor White
	Write-Host ""

	# Process files
	$results = @()
	foreach ($file in $files) {
		$result = Format-AsmFile -File $file -Config $script:Config -DryRun:$dryRun -SkipBackup:$SkipBackup
		$results += $result
	}

	# Summary
	Write-Host "`n=== Summary ===" -ForegroundColor Cyan

	$totalProcessed = $results.Count
	$totalChanged = ($results | Where-Object { $_.Changed -eq $true }).Count
	$totalUnchanged = ($results | Where-Object { $_.Changed -eq $false -and -not $_.Error }).Count
	$totalErrors = ($results | Where-Object { $_.Error }).Count

	Write-Host "Files processed: $totalProcessed" -ForegroundColor White
	Write-Host "Files changed: $totalChanged" -ForegroundColor $(if ($totalChanged -gt 0) { "Green" } else { "Gray" })
	Write-Host "Files unchanged: $totalUnchanged" -ForegroundColor Gray	if ($totalErrors -gt 0) {
		Write-Host "Errors: $totalErrors" -ForegroundColor Red
	}

	if ($dryRun -and $totalChanged -gt 0) {
		Write-Host "`nRe-run without -DryRun to apply changes." -ForegroundColor Yellow
	}

	Write-Host ""

	exit 0
}
catch {
	Write-ErrorMessage "`n✗ Fatal error: $_"
	Write-Host $_.ScriptStackTrace -ForegroundColor Red
	exit 1
}

#endregion
