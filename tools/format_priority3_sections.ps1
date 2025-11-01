<#
.SYNOPSIS
	Format Priority 3 bank section files with individual git commits.

.DESCRIPTION
	Automates formatting of 4 Priority 3 bank section files:
	- bank_00_section2.asm (353 lines)
	- bank_00_section3.asm (463 lines)
	- bank_00_section4.asm (508 lines)
	- bank_00_section5.asm (530 lines)
	
	For each section:
	1. Verify file exists
	2. Preview changes (dry-run)
	3. Create backup
	4. Apply formatting
	5. Verify results
	6. Create git commit
	7. Clean up backup on success

.PARAMETER DryRun
	Preview changes without modifying files or creating commits.

.PARAMETER NoCommit
	Format files but don't create git commits.

.EXAMPLE
	.\tools\format_priority3_sections.ps1 -DryRun
	Preview formatting changes without applying them.

.EXAMPLE
	.\tools\format_priority3_sections.ps1
	Format all Priority 3 sections and create individual commits.
#>

[CmdletBinding()]
param(
	[switch]$dryRun,
	[switch]$NoCommit
)

# Script configuration
$errorActionPreference = 'Stop'
$ScriptRoot = Split-Path -Parent $PSScriptRoot
$formatScript = Join-Path $ScriptRoot "tools\format_asm.ps1"
$SrcDir = Join-Path $ScriptRoot "src\asm"

# Section configuration
$Sections = @(
	@{
		File = "bank_00_section2.asm"
		Description = "Bank 00 Section 2 - Core Engine Part 2"
		Number = "2"
	}
	@{
		File = "bank_00_section3.asm"
		Description = "Bank 00 Section 3 - Core Engine Part 3"
		Number = "3"
	}
	@{
		File = "bank_00_section4.asm"
		Description = "Bank 00 Section 4 - Core Engine Part 4"
		Number = "4"
	}
	@{
		File = "bank_00_section5.asm"
		Description = "Bank 00 Section 5 - Core Engine Part 5"
		Number = "5"
	}
)

# Statistics
$Stats = @{
	TotalSections = $Sections.Count
	Successful = 0
	Failed = 0
	StartTime = Get-Date
}

function Write-Header {
	param([string]$Text, [int]$Width = 100)
	Write-Host ""
	Write-Host ("=" * $Width)
	Write-Host "  $Text"
	Write-Host ("=" * $Width)
	Write-Host ""
}

function Write-Step {
	param([string]$Text, [string]$Status = "info")
	$symbol = switch ($Status) {
		"success" { "✓"; $color = "Green" }
		"error" { "✗"; $color = "Red" }
		"warning" { "⚠"; $color = "Yellow" }
		default { "ℹ"; $color = "Cyan" }
	}
	Write-Host "  $symbol " -ForegroundColor $color -NoNewline
	Write-Host $Text
}

function Get-FileStats {
	param([string]$Path)
	if (Test-Path $Path) {
		$file = Get-Item $Path
		$lines = (Get-Content $Path -Raw).Split("`n").Count
		return @{
			Exists = $true
			Size = $file.Length
			Lines = $lines
		}
	}
	return @{ Exists = $false }
}

function Format-Section {
	param(
		[hashtable]$Section,
		[int]$Number,
		[int]$Total
	)
	
	$sectionDesc = $Section.Description
	$sectionFile = $Section.File
	$sectionPath = Join-Path $SrcDir $sectionFile
	$backupPath = "$sectionPath.pre_format_backup"
	
	Write-Header "Processing Section $Number/$Total - $sectionDesc"
	
	# Step 1: Verify file exists
	Write-Host "[1/6] Verify file exists: $sectionFile"
	$stats = Get-FileStats -Path $sectionPath
	if (-not $stats.Exists) {
		Write-Step "File not found: $sectionPath" -Status error
		return $false
	}
	Write-Step "File found" -Status success
	Write-Step "Size: $($stats.Size) bytes ($($stats.Lines) lines)"
	
	# Step 2: Preview formatting changes
	Write-Host ""
	Write-Host "[2/6] Preview formatting changes (dry-run)"
	Write-Step "Executing: .\tools\format_asm.ps1 -Path $sectionPath -DryRun"
	Write-Host ""
	
	& $formatScript -Path $sectionPath -DryRun | Out-String | Write-Host
	
	if ($dryRun) {
		Write-Step "DRY-RUN MODE: Stopping here"
		return $true
	}
	
	# Step 3: Create backup
	Write-Host ""
	Write-Host "[3/6] Create backup"
	try {
		Copy-Item $sectionPath $backupPath -Force
		Write-Step "Backup created: $backupPath" -Status success
	}
	catch {
		Write-Step "Failed to create backup: $_" -Status error
		return $false
	}
	
	# Step 4: Apply formatting
	Write-Host ""
	Write-Host "[4/6] Apply formatting"
	Write-Step "Executing: .\tools\format_asm.ps1 -Path $sectionPath"
	Write-Host ""
	
	try {
		& $formatScript -Path $sectionPath | Out-String | Write-Host
		Write-Step "Formatting applied" -Status success
	}
	catch {
		Write-Step "Formatting failed: $_" -Status error
		# Restore from backup
		Copy-Item $backupPath $sectionPath -Force
		Write-Step "Restored from backup" -Status warning
		return $false
	}
	
	# Step 5: Verify formatted file
	Write-Host ""
	Write-Host "[5/6] Verify formatted file"
	$newStats = Get-FileStats -Path $sectionPath
	if (-not $newStats.Exists) {
		Write-Step "Formatted file not found!" -Status error
		Copy-Item $backupPath $sectionPath -Force
		return $false
	}
	
	Write-Step "Formatted file exists" -Status success
	Write-Step "Original: $($stats.Size) bytes ($($stats.Lines) lines)"
	Write-Step "Formatted: $($newStats.Size) bytes ($($newStats.Lines) lines)"
	
	$sizeDiff = $newStats.Size - $stats.Size
	$sizePercent = if ($stats.Size -gt 0) { ($sizeDiff / $stats.Size * 100).ToString("F2") } else { "0" }
	$lineDiff = $newStats.Lines - $stats.Lines
	
	Write-Step "Size change: $sizeDiff bytes ($sizePercent%)"
	Write-Step "Line change: $lineDiff lines"
	
	# Verify line count hasn't changed (formatting shouldn't add/remove lines)
	if ($lineDiff -ne 0) {
		Write-Step "WARNING: Line count changed! This shouldn't happen with formatting." -Status warning
	}
	
	# Step 6: Create git commit
	if (-not $NoCommit) {
		Write-Host ""
		Write-Host "[6/6] Create git commit"
		Write-Step "Staging: $sectionPath"
		
		try {
			git add $sectionPath 2>&1 | Out-Null
			
			$commitMsg = @"
Format $sectionFile - ASM code formatting

- Applied CRLF line endings
- Applied UTF-8 with BOM encoding
- Converted spaces to tabs (4 spaces = 1 tab)
- Applied column alignment (labels: 0, opcodes: 23, operands: 47, comments: 57)

Stats:
- Original: $($stats.Size) bytes ($($stats.Lines) lines)
- Formatted: $($newStats.Size) bytes ($($newStats.Lines) lines)
- Change: $sizeDiff bytes ($sizePercent%)

Part of Issue #17 - Priority 3 Sections
"@
			
			Write-Step "Committing changes..."
			git commit -m $commitMsg 2>&1 | Out-Null
			Write-Step "Git commit created" -Status success
		}
		catch {
			Write-Step "Git commit failed: $_" -Status warning
			# Don't fail the whole process, formatting was successful
		}
	}
	else {
		Write-Step "Skipping git commit (NoCommit flag set)"
	}
	
	# Clean up backup on success
	if (Test-Path $backupPath) {
		Remove-Item $backupPath -Force
	}
	
	Write-Step "Section processing complete" -Status success
	return $true
}

# Main execution
Clear-Host
Write-Header "ASM Priority 3 Sections Formatting"

# Display configuration
$mode = if ($dryRun) { "DRY-RUN (preview only)" } else { "PRODUCTION (will modify files)" }
$commits = if ($NoCommit -or $dryRun) { "Disabled" } else { "Enabled" }

Write-Host "Mode: $mode"
Write-Host "Commits: $commits"
Write-Host "Started: $($Stats.StartTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host ""

# Verify format script exists
if (-not (Test-Path $formatScript)) {
	Write-Step "Format script not found: $formatScript" -Status error
	exit 1
}

# Display sections to process
Write-Host "Sections to process: $($Sections.Count)"
foreach ($section in $Sections) {
	$path = Join-Path $SrcDir $section.File
	Write-Host "  - $path ($($section.Description))"
}
Write-Host ""

# Process each section
for ($i = 0; $i -lt $Sections.Count; $i++) {
	$section = $Sections[$i]
	$number = $i + 1
	
	$success = Format-Section -Section $section -Number $number -Total $Sections.Count
	
	if ($success) {
		$Stats.Successful++
	}
	else {
		$Stats.Failed++
	}
	
	Write-Host ""
}

# Display summary
Write-Header "Summary"

Write-Host "Results:"
Write-Host "  Total Sections: $($Stats.TotalSections)"
if ($Stats.Successful -gt 0) {
	Write-Step "Successful: $($Stats.Successful)" -Status success
}
if ($Stats.Failed -gt 0) {
	Write-Step "Failed: $($Stats.Failed)" -Status error
}

$endTime = Get-Date
$duration = $endTime - $Stats.StartTime
Write-Host ""
Write-Host "Duration: $($duration.ToString('mm\:ss'))"

if ($dryRun) {
	Write-Host ""
	Write-Step "DRY-RUN complete - no changes applied"
}
elseif ($Stats.Failed -gt 0) {
	Write-Host ""
	Write-Step "Some sections failed - check errors above" -Status warning
	exit 1
}
else {
	Write-Host ""
	Write-Step "All sections formatted successfully!" -Status success
}
