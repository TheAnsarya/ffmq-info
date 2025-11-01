<#
.SYNOPSIS
	Format priority ASM bank files with verification and individual commits.

.DESCRIPTION
	Formats the 6 priority documented bank files one at a time:
	- Creates backup before formatting
	- Applies formatting
	- Verifies changes
	- Creates individual git commit
	- Generates formatting report

.PARAMETER BankFile
	Specific bank file to format (optional, processes all if not specified)

.PARAMETER SkipCommit
	Skip git commit (for testing)

.PARAMETER DryRun
	Preview changes without applying

.EXAMPLE
	.\format_priority_banks.ps1
	Format all priority banks with commits

.EXAMPLE
	.\format_priority_banks.ps1 -BankFile src\asm\bank_00_documented.asm
	Format specific bank only

.EXAMPLE
	.\format_priority_banks.ps1 -DryRun
	Preview all formatting changes

.NOTES
	Author: GitHub Copilot
	Version: 1.0
	Date: 2025-11-01
	Requires: PowerShell 7+, format_asm.ps1
#>

[CmdletBinding()]
param(
	[Parameter(HelpMessage = "Specific bank file to format")]
	[string]$BankFile,

	[Parameter(HelpMessage = "Skip git commit")]
	[switch]$SkipCommit,

	[Parameter(HelpMessage = "Preview changes without applying")]
	[switch]$DryRun
)

#region Configuration

$script:PriorityBanks = @(
	@{
		File = "src\asm\bank_00_documented.asm"
		Description = "Bank $00 - Core Engine & Initialization"
		EstimatedLines = 14693
	},
	@{
		File = "src\asm\bank_01_documented.asm"
		Description = "Bank $01 - Engine Code"
		EstimatedLines = 9671
	},
	@{
		File = "src\asm\bank_02_documented.asm"
		Description = "Bank $02 - Engine Routines"
		EstimatedLines = 9000
	},
	@{
		File = "src\asm\bank_0B_documented.asm"
		Description = "Bank $0B - Game Logic"
		EstimatedLines = 3700
	},
	@{
		File = "src\asm\bank_0C_documented.asm"
		Description = "Bank $0C - Menu System & UI"
		EstimatedLines = 4200
	},
	@{
		File = "src\asm\bank_0D_documented.asm"
		Description = "Bank $0D - Menu & UI"
		EstimatedLines = 2900
	}
)

#endregion

#region Helper Functions

function Write-BankHeader {
	param([string]$Title)
	Write-Host "`n$('=' * 100)" -ForegroundColor Cyan
	Write-Host "  $Title" -ForegroundColor White
	Write-Host $('=' * 100) -ForegroundColor Cyan
}

function Write-Step {
	param([string]$Step, [int]$Number, [int]$Total)
	Write-Host "`n[$Number/$Total] $Step" -ForegroundColor Yellow
}

function Write-Success {
	param([string]$Message)
	Write-Host "  ✓ $Message" -ForegroundColor Green
}

function Write-Failure {
	param([string]$Message)
	Write-Host "  ✗ $Message" -ForegroundColor Red
}

function Write-Info {
	param([string]$Message)
	Write-Host "  ℹ $Message" -ForegroundColor Cyan
}

function Get-LineCount {
	param([string]$FilePath)
	if (-not (Test-Path $FilePath)) {
		return 0
	}
	return (Get-Content $FilePath).Count
}

function Format-BankFile {
	param(
		[hashtable]$Bank,
		[int]$Number,
		[int]$Total,
		[bool]$DryRun,
		[bool]$SkipCommit
	)

	$bankDesc = $Bank.Description
	$bankNum = "$Number/$Total"
	Write-BankHeader "Processing Bank $bankNum - $bankDesc"

	$file = $Bank.File
	$fileName = Split-Path $file -Leaf

	# Step 1: Verify file exists
	Write-Step "Verify file exists: $fileName" 1 6

	if (-not (Test-Path $file)) {
		Write-Failure "File not found: $file"
		return @{ Success = $false; Reason = "File not found" }
	}

	$originalInfo = Get-Item $file
	$originalLines = Get-LineCount -FilePath $file

	Write-Success "File found"
	Write-Info "Size: $($originalInfo.Length) bytes ($originalLines lines)"

	# Step 2: Run dry-run to see changes
	Write-Step "Preview formatting changes (dry-run)" 2 6

	Write-Info "Executing: .\tools\format_asm.ps1 -Path $file -DryRun"
	$dryRunOutput = & .\tools\format_asm.ps1 -Path $file -DryRun 2>&1 | Out-String

	# Extract change count
	$changeMatch = $dryRunOutput | Select-String '(\d+) changes'
	$changes = if ($changeMatch) { $changeMatch.Matches[0].Groups[1].Value } else { "unknown" }

	Write-Info "Changes detected: $changes"

	if ($DryRun) {
		Write-Info "DRY-RUN MODE: Stopping here, no changes applied"
		return @{
			Success = $true
			DryRun = $true
			File = $file
			Changes = $changes
		}
	}

	# Step 3: Create backup
	Write-Step "Create backup" 3 6

	$backupPath = "$file.pre_format_backup"
	Copy-Item -Path $file -Destination $backupPath -Force

	if (Test-Path $backupPath) {
		Write-Success "Backup created: $backupPath"
	}
	else {
		Write-Failure "Backup creation failed"
		return @{ Success = $false; Reason = "Backup failed" }
	}

	# Step 4: Apply formatting
	Write-Step "Apply formatting" 4 6

	Write-Info "Executing: .\tools\format_asm.ps1 -Path $file"
	& .\tools\format_asm.ps1 -Path $file 2>&1 | Out-Null
	$formatExitCode = $LASTEXITCODE

	if ($formatExitCode -ne 0) {
		Write-Failure "Formatting failed with exit code $formatExitCode"

		# Restore backup
		Write-Info "Restoring from backup..."
		Copy-Item -Path $backupPath -Destination $file -Force
		Write-Info "Backup restored"

		return @{ Success = $false; Reason = "Format failed, backup restored" }
	}

	Write-Success "Formatting applied"

	# Step 5: Verify formatted file
	Write-Step "Verify formatted file" 5 6

	if (-not (Test-Path $file)) {
		Write-Failure "Formatted file disappeared!"
		Copy-Item -Path $backupPath -Destination $file -Force
		return @{ Success = $false; Reason = "File disappeared" }
	}

	$formattedInfo = Get-Item $file
	$formattedLines = Get-LineCount -FilePath $file

	Write-Success "Formatted file exists"
	Write-Info "Original: $($originalInfo.Length) bytes ($originalLines lines)"
	Write-Info "Formatted: $($formattedInfo.Length) bytes ($formattedLines lines)"

	$sizeDiff = $formattedInfo.Length - $originalInfo.Length
	$lineDiff = $formattedLines - $originalLines
	$sizeChangePercent = [Math]::Round(([Math]::Abs($sizeDiff) / $originalInfo.Length) * 100, 2)

	Write-Info "Size change: $sizeDiff bytes ($sizeChangePercent%)"
	Write-Info "Line change: $lineDiff lines"

	# Sanity checks
	if ($formattedInfo.Length -eq 0) {
		Write-Failure "Formatted file is empty!"
		Copy-Item -Path $backupPath -Destination $file -Force
		return @{ Success = $false; Reason = "File became empty" }
	}

	if ($sizeChangePercent -gt 50) {
		Write-Failure "File size changed by more than 50%!"
		Copy-Item -Path $backupPath -Destination $file -Force
		return @{ Success = $false; Reason = "Excessive size change" }
	}

	# Step 6: Git commit (if not skipped)
	if (-not $SkipCommit) {
		Write-Step "Create git commit" 6 6

		Write-Info "Staging: $file"
		& git add $file 2>&1 | Out-Null

		$commitMessage = @"
Format $fileName - ASM code formatting

Applied consistent formatting to $fileName using format_asm.ps1:
- CRLF line endings
- UTF-8 with BOM encoding
- Space-to-tab conversion
- Column alignment (labels/opcodes/operands/comments)
- Trailing whitespace trimmed
- Final newline ensured

Statistics:
- Lines: $originalLines → $formattedLines ($lineDiff change)
- Size: $($originalInfo.Length) → $($formattedInfo.Length) bytes ($sizeDiff change, $sizeChangePercent%)
- Changes: $changes line modifications

Bank: $($Bank.Description)

Related: #16 (Format Priority 1 Banks), #14 (format_asm.ps1), #15 (Testing)
"@

		Write-Info "Committing changes..."
		& git commit -m $commitMessage 2>&1 | Out-Null

		if ($LASTEXITCODE -eq 0) {
			Write-Success "Git commit created"
		}
		else {
			Write-Failure "Git commit failed"
			return @{ Success = $false; Reason = "Commit failed" }
		}
	}
	else {
		Write-Info "Git commit skipped (use -SkipCommit:$false to enable)"
	}

	# Keep backup for now (will be cleaned up at end)
	Write-Success "Bank processing complete"

	return @{
		Success = $true
		File = $file
		OriginalSize = $originalInfo.Length
		FormattedSize = $formattedInfo.Length
		OriginalLines = $originalLines
		FormattedLines = $formattedLines
		Changes = $changes
		Committed = (-not $SkipCommit)
	}
}

#endregion

#region Main Script

try {
	Write-BankHeader "ASM Priority Banks Formatting"
	Write-Host "Mode: $(if ($DryRun) { 'DRY-RUN (preview only)' } else { 'PRODUCTION (will modify files)' })"
	Write-Host "Commits: $(if ($SkipCommit) { 'Disabled' } else { 'Enabled' })"
	Write-Host "Started: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

	# Verify format script exists
	if (-not (Test-Path "tools\format_asm.ps1")) {
		Write-Failure "format_asm.ps1 not found in tools directory"
		exit 1
	}

	# Determine which banks to process
	$banksToProcess = if ($BankFile) {
		$script:PriorityBanks | Where-Object { $_.File -eq $BankFile }
	}
	else {
		$script:PriorityBanks
	}

	if ($banksToProcess.Count -eq 0) {
		Write-Failure "No banks to process"
		exit 1
	}

	Write-Host "`nBanks to process: $($banksToProcess.Count)"
	foreach ($bank in $banksToProcess) {
		Write-Host "  - $($bank.File) ($($bank.Description))"
	}

	# Process each bank
	$results = @()
	$totalBanks = $banksToProcess.Count
	$currentBank = 0

	foreach ($bank in $banksToProcess) {
		$currentBank++

		$result = Format-BankFile `
			-Bank $bank `
			-Number $currentBank `
			-Total $totalBanks `
			-DryRun:$DryRun `
			-SkipCommit:$SkipCommit

		$results += $result

		if (-not $result.Success -and -not $result.DryRun) {
			Write-Failure "Bank processing failed: $($result.Reason)"
			Write-Info "Stopping here to prevent cascade failures"
			break
		}
	}

	# Summary
	Write-BankHeader "Summary"

	$successful = ($results | Where-Object { $_.Success }).Count
	$failed = ($results | Where-Object { -not $_.Success -and -not $_.DryRun }).Count

	Write-Host "`nResults:"
	Write-Host "  Total Banks: $($results.Count)"
	Write-Host "  Successful: $successful " -NoNewline
	Write-Host "✓" -ForegroundColor Green

	if ($failed -gt 0) {
		Write-Host "  Failed: $failed " -NoNewline
		Write-Host "✗" -ForegroundColor Red
	}

	if (-not $DryRun) {
		$totalOriginalLines = ($results | Where-Object { $_.Success } | Measure-Object -Property OriginalLines -Sum).Sum
		$totalFormattedLines = ($results | Where-Object { $_.Success } | Measure-Object -Property FormattedLines -Sum).Sum
		$totalChanges = ($results | Where-Object { $_.Success } | ForEach-Object { [int]$_.Changes } | Measure-Object -Sum).Sum

		Write-Host "`nStatistics:"
		Write-Host "  Total Lines: $totalOriginalLines → $totalFormattedLines"
		Write-Host "  Total Changes: $totalChanges"

		if (-not $SkipCommit) {
			Write-Host "`nGit commits created for each bank"
			Write-Host "Use 'git log' to review commits"
		}
	}
	else {
		Write-Host "`nDRY-RUN complete - no changes applied"
		Write-Host "Re-run without -DryRun to apply formatting"
	}

	# Cleanup backups if all successful
	if ($successful -eq $results.Count -and -not $DryRun) {
		Write-Host "`nCleaning up backups..."
		foreach ($result in $results) {
			if ($result.File) {
				$backupPath = "$($result.File).pre_format_backup"
				if (Test-Path $backupPath) {
					Remove-Item $backupPath -Force
					Write-Info "Removed: $backupPath"
				}
			}
		}
	}

	Write-Host ""

	if ($failed -gt 0) {
		exit 1
	}
	else {
		exit 0
	}
}
catch {
	Write-Host "`n✗ Fatal error: $_" -ForegroundColor Red
	Write-Host $_.ScriptStackTrace -ForegroundColor Red
	exit 1
}

#endregion
