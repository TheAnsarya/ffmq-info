<#
.SYNOPSIS
	Fix excessive indentation in ASM files.

.DESCRIPTION
	Normalizes indentation in assembly files:
	- Labels at column 0
	- Instructions with 1 tab indent (when no label)
	- Converts excessive spaces to proper tabs
	- Maintains comment alignment where reasonable

.PARAMETER Path
	File or directory to process.

.PARAMETER DryRun
	Preview changes without modifying files.

.EXAMPLE
	.\fix_indentation.ps1 -Path src/asm -DryRun
	Preview indentation fixes

.EXAMPLE
	.\fix_indentation.ps1 -Path src/asm
	Fix all ASM files
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory = $true)]
	[string]$Path,

	[Parameter()]
	[switch]$DryRun
)

function Normalize-Indentation {
	param([string]$Line)

	# Skip blank lines
	if ([string]::IsNullOrWhiteSpace($Line)) {
		return ""
	}

	# Trim all leading/trailing whitespace
	$trimmed = $Line.Trim()

	# Pure comment line
	if ($trimmed -match '^;') {
		return ";$($trimmed.Substring(1))"
	}

	# Check if line has a label (starts with identifier followed by colon)
	if ($trimmed -match '^([A-Za-z_][A-Za-z0-9_]*):(.*)$') {
		$label = $Matches[1]
		$rest = $Matches[2].Trim()

		# Label at column 0
		if ([string]::IsNullOrWhiteSpace($rest)) {
			# Label only
			return "${label}:"
		}
		else {
			# Label + instruction on same line (label at col 0, instruction after tab)
			return "${label}:`t${rest}"
		}
	}

	# Check if line starts with a directive (.org, .db, etc.)
	if ($trimmed -match '^\.(org|db|dw|dl|dd|include|incsrc|incbin|macro|endmacro|if|ifdef|ifndef|else|endif)') {
		# Directives at column 0
		return $trimmed
	}

	# Regular instruction line - one tab indent
	return "`t" + $trimmed
}function Fix-FileIndentation {
	param(
		[System.IO.FileInfo]$File,
		[bool]$DryRun
	)

	Write-Host "Processing: $($File.Name)" -ForegroundColor Cyan

	# Read file
	$content = Get-Content -Path $File.FullName -Raw -Encoding UTF8
	if ([string]::IsNullOrEmpty($content)) {
		Write-Host "  File is empty, skipping" -ForegroundColor Gray
		return @{
			File = $File.FullName
			Changed = $false
			ChangeCount = 0
		}
	}

	$lines = $content -split "`r`n|`r|`n"
	$newLines = @()
	$changeCount = 0

	foreach ($line in $lines) {
		$newLine = Normalize-Indentation -Line $line
		if ($newLine -cne $line) {
			$changeCount++
		}
		$newLines += $newLine
	}

	if ($changeCount -eq 0) {
		Write-Host "  No changes needed" -ForegroundColor Gray
		return @{
			File = $File.FullName
			Changed = $false
			ChangeCount = 0
		}
	}

	if ($DryRun) {
		Write-Host "  [DRY-RUN] Would fix $changeCount lines" -ForegroundColor Yellow
		return @{
			File = $File.FullName
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
	$backupPath = $File.FullName + '.bak'
	Copy-Item -Path $File.FullName -Destination $backupPath -Force

	# Write file
	[System.IO.File]::WriteAllText($File.FullName, $newContent, [System.Text.UTF8Encoding]::new($true))

	Write-Host "  ✓ Fixed $changeCount lines" -ForegroundColor Green

	return @{
		File = $File.FullName
		Changed = $true
		DryRun = $false
		ChangeCount = $changeCount
	}
}

# Main script
Write-Host "`n=== ASM Indentation Fixer ===" -ForegroundColor Cyan
Write-Host "Issue #49: Fix Excessive Indentation`n" -ForegroundColor Gray

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
	$result = Fix-FileIndentation -File $file -DryRun:$DryRun
	$results += $result
}

# Summary
Write-Host "`n=== Summary ===" -ForegroundColor Cyan
$totalChanged = ($results | Where-Object { $_.Changed -eq $true }).Count
$totalLinesFixed = ($results | Measure-Object -Property ChangeCount -Sum).Sum

Write-Host "Files processed: $($files.Count)" -ForegroundColor White
Write-Host "Files modified: $totalChanged" -ForegroundColor Green
Write-Host "Lines fixed: $totalLinesFixed" -ForegroundColor White

if ($DryRun -and $totalChanged -gt 0) {
	Write-Host "`nRe-run without -DryRun to apply changes." -ForegroundColor Yellow
}

Write-Host ""
