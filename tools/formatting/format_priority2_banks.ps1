<#
.SYNOPSIS
	Format Priority 2 bank files with individual git commits.

.DESCRIPTION
	Automates formatting of 5 Priority 2 documented bank files:
	- bank_03_documented.asm (2,672 lines)
	- bank_07_documented.asm (2,647 lines)
	- bank_08_documented.asm (2,156 lines)
	- bank_09_documented.asm (2,186 lines)
	- bank_0A_documented.asm (2,078 lines)

	For each bank:
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
	.\tools\format_priority2_banks.ps1 -DryRun
	Preview formatting changes without applying them.

.EXAMPLE
	.\tools\format_priority2_banks.ps1
	Format all Priority 2 banks and create individual commits.
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

# Bank configuration
$banks = @(
	@{
		File = "bank_03_documented.asm"
		Description = "Bank 03 - Battle System"
		Number = "03"
	}
	@{
		File = "bank_07_documented.asm"
		Description = "Bank 07 - Field System"
		Number = "07"
	}
	@{
		File = "bank_08_documented.asm"
		Description = "Bank 08 - Map & Graphics"
		Number = "08"
	}
	@{
		File = "bank_09_documented.asm"
		Description = "Bank 09 - Battle Graphics"
		Number = "09"
	}
	@{
		File = "bank_0A_documented.asm"
		Description = "Bank 0A - Text & Dialog"
		Number = "0A"
	}
)

# Statistics
$Stats = @{
	TotalBanks = $banks.Count
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

function Format-Bank {
	param(
		[hashtable]$bank,
		[int]$Number,
		[int]$Total
	)

	$bankDesc = $bank.Description
	$bankFile = $bank.File
	$bankPath = Join-Path $SrcDir $bankFile
	$backupPath = "$bankPath.pre_format_backup"

	Write-Header "Processing Bank $Number/$Total - $bankDesc"

	# Step 1: Verify file exists
	Write-Host "[1/6] Verify file exists: $bankFile"
	$stats = Get-FileStats -Path $bankPath
	if (-not $stats.Exists) {
		Write-Step "File not found: $bankPath" -Status error
		return $false
	}
	Write-Step "File found" -Status success
	Write-Step "Size: $($stats.Size) bytes ($($stats.Lines) lines)"

	# Step 2: Preview formatting changes
	Write-Host ""
	Write-Host "[2/6] Preview formatting changes (dry-run)"
	Write-Step "Executing: .\tools\format_asm.ps1 -Path $bankPath -DryRun"
	Write-Host ""

	& $formatScript -Path $bankPath -DryRun | Out-String | Write-Host

	if ($dryRun) {
		Write-Step "DRY-RUN MODE: Stopping here"
		return $true
	}

	# Step 3: Create backup
	Write-Host ""
	Write-Host "[3/6] Create backup"
	try {
		Copy-Item $bankPath $backupPath -Force
		Write-Step "Backup created: $backupPath" -Status success
	}
	catch {
		Write-Step "Failed to create backup: $_" -Status error
		return $false
	}

	# Step 4: Apply formatting
	Write-Host ""
	Write-Host "[4/6] Apply formatting"
	Write-Step "Executing: .\tools\format_asm.ps1 -Path $bankPath"
	Write-Host ""

	try {
		& $formatScript -Path $bankPath | Out-String | Write-Host
		Write-Step "Formatting applied" -Status success
	}
	catch {
		Write-Step "Formatting failed: $_" -Status error
		# Restore from backup
		Copy-Item $backupPath $bankPath -Force
		Write-Step "Restored from backup" -Status warning
		return $false
	}

	# Step 5: Verify formatted file
	Write-Host ""
	Write-Host "[5/6] Verify formatted file"
	$newStats = Get-FileStats -Path $bankPath
	if (-not $newStats.Exists) {
		Write-Step "Formatted file not found!" -Status error
		Copy-Item $backupPath $bankPath -Force
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
		Write-Step "Staging: $bankPath"

		try {
			git add $bankPath 2>&1 | Out-Null

			$commitMsg = @"
Format $bankFile - ASM code formatting

- Applied CRLF line endings
- Applied UTF-8 with BOM encoding
- Converted spaces to tabs (4 spaces = 1 tab)
- Applied column alignment (labels: 0, opcodes: 23, operands: 47, comments: 57)

Stats:
- Original: $($stats.Size) bytes ($($stats.Lines) lines)
- Formatted: $($newStats.Size) bytes ($($newStats.Lines) lines)
- Change: $sizeDiff bytes ($sizePercent%)

Part of Issue #17 - Priority 2 Banks
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

	Write-Step "Bank processing complete" -Status success
	return $true
}

# Main execution
Clear-Host
Write-Header "ASM Priority 2 Banks Formatting"

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

# Display banks to process
Write-Host "Banks to process: $($banks.Count)"
foreach ($bank in $banks) {
	$path = Join-Path $SrcDir $bank.File
	Write-Host "  - $path ($($bank.Description))"
}
Write-Host ""

# Process each bank
for ($i = 0; $i -lt $banks.Count; $i++) {
	$bank = $banks[$i]
	$number = $i + 1

	$success = Format-Bank -Bank $bank -Number $number -Total $banks.Count

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
Write-Host "  Total Banks: $($Stats.TotalBanks)"
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
	Write-Step "Some banks failed - check errors above" -Status warning
	exit 1
}
else {
	Write-Host ""
	Write-Step "All banks formatted successfully!" -Status success
}
