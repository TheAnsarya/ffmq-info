<#
.SYNOPSIS
	Generate FFMQ Build Report
	
.DESCRIPTION
	Creates a detailed report of the current build state including:
	- ROM information and checksums
	- Source file statistics
	- Build verification status
	- Label coverage
	- Recent changes
	
.PARAMETER OutputFile
	Path where the report will be saved
	
.PARAMETER IncludeVerbose
	Include verbose information (file lists, etc.)
	
.EXAMPLE
	.\build-report.ps1
	
.EXAMPLE
	.\build-report.ps1 -OutputFile "reports\build-2025-11-01.txt" -IncludeVerbose
	
.NOTES
	Author: FFMQ Disassembly Project
	Version: 1.0
	Last Updated: 2025-11-01
#>

param(
	[Parameter(HelpMessage="Output file path for the report")]
	[string]$OutputFile = "build-report.txt",
	
	[Parameter(HelpMessage="Include verbose details")]
	[switch]$IncludeVerbose,
	
	[Parameter(HelpMessage="ROM file to analyze")]
	[string]$ROMFile = "ffmq - onlygood.sfc",
	
	[Parameter(HelpMessage="Original ROM for comparison")]
	[string]$OriginalROM = "roms\ffmq-original.sfc"
)

# Initialize report
$report = New-Object System.Text.StringBuilder

function Add-Section {
	param([string]$Title, [string]$Content)
	[void]$report.AppendLine("")
	[void]$report.AppendLine("=" * 70)
	[void]$report.AppendLine("  $Title")
	[void]$report.AppendLine("=" * 70)
	[void]$report.AppendLine("")
	[void]$report.AppendLine($Content)
}

function Add-Subsection {
	param([string]$Title, [string]$Content)
	[void]$report.AppendLine("")
	[void]$report.AppendLine("-" * 70)
	[void]$report.AppendLine($Title)
	[void]$report.AppendLine("-" * 70)
	[void]$report.AppendLine($Content)
}

# Header
[void]$report.AppendLine("╔" + ("═" * 68) + "╗")
[void]$report.AppendLine("║" + (" " * 15) + "FFMQ BUILD REPORT" + (" " * 36) + "║")
[void]$report.AppendLine("╚" + ("═" * 68) + "╝")
[void]$report.AppendLine("")
[void]$report.AppendLine("Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
[void]$report.AppendLine("User: $env:USERNAME")
[void]$report.AppendLine("Computer: $env:COMPUTERNAME")

# ROM Information
if (Test-Path $ROMFile) {
	$romInfo = Get-Item $ROMFile
	$md5 = (Get-FileHash $ROMFile -Algorithm MD5).Hash
	$sha256 = (Get-FileHash $ROMFile -Algorithm SHA256).Hash
	
	$content = @"
File Name:  $($romInfo.Name)
File Path:  $($romInfo.FullName)
File Size:  $($romInfo.Length) bytes ($([math]::Round($romInfo.Length / 1KB, 2)) KB)
Created:    $($romInfo.CreationTime)
Modified:   $($romInfo.LastWriteTime)

Checksums:
  MD5:      $md5
  SHA-256:  $sha256

Expected Size: 1,048,576 bytes (1 MB)
Size Match:    $(if ($romInfo.Length -eq 1048576) { "✓ YES" } else { "✗ NO" })
"@
	
	Add-Section "ROM INFORMATION" $content
} else {
	Add-Section "ROM INFORMATION" "ROM file not found: $ROMFile"
}

# Build Verification
if ((Test-Path $ROMFile) -and (Test-Path $OriginalROM)) {
	$originalSize = (Get-Item $OriginalROM).Length
	$builtSize = (Get-Item $ROMFile).Length
	
	$sizeMatch = $originalSize -eq $builtSize
	
	if ($sizeMatch) {
		# Do byte comparison
		$fcOutput = & fc.exe /b $OriginalROM $ROMFile 2>&1
		$byteMatch = $LASTEXITCODE -eq 0
	} else {
		$byteMatch = $false
	}
	
	$content = @"
Original ROM: $OriginalROM
Built ROM:    $ROMFile

Size Check:
  Original:  $originalSize bytes
  Built:     $builtSize bytes
  Match:     $(if ($sizeMatch) { "✓ YES" } else { "✗ NO" })

Byte-Perfect Check:
  Status:    $(if ($byteMatch) { "✓ PERFECT MATCH" } else { "✗ DIFFERENCES FOUND" })

Round-Trip Status: $(if ($byteMatch) { "✓ PASSED" } else { "✗ FAILED" })
"@
	
	Add-Section "BUILD VERIFICATION" $content
} else {
	Add-Section "BUILD VERIFICATION" "Cannot verify: Missing ROM file(s)"
}

# Source Files
$asmFiles = Get-ChildItem -Recurse -Include *.asm -ErrorAction SilentlyContinue
$incFiles = Get-ChildItem -Recurse -Include *.inc -ErrorAction SilentlyContinue
$totalLines = 0

if ($asmFiles) {
	$totalLines += ($asmFiles | ForEach-Object { (Get-Content $_.FullName -ErrorAction SilentlyContinue).Count } | Measure-Object -Sum).Sum
}
if ($incFiles) {
	$totalLines += ($incFiles | ForEach-Object { (Get-Content $_.FullName -ErrorAction SilentlyContinue).Count } | Measure-Object -Sum).Sum
}

$content = @"
Assembly Files (.asm):  $($asmFiles.Count)
Include Files (.inc):   $($incFiles.Count)
Total Source Files:     $($asmFiles.Count + $incFiles.Count)

Estimated Lines of Code: $totalLines

Main Build File: $(if (Test-Path "ffmq - onlygood.asm") { "✓ ffmq - onlygood.asm" } else { "✗ Not found" })
"@

if ($IncludeVerbose -and $asmFiles) {
	$content += "`n`nAssembly Files:`n"
	$asmFiles | Sort-Object FullName | ForEach-Object {
		$lines = (Get-Content $_.FullName -ErrorAction SilentlyContinue).Count
		$content += "  - $($_.Name) ($lines lines)`n"
	}
}

Add-Section "SOURCE FILES" $content

# Build Tools
$asarInstalled = $null
try {
	$asarVersion = & asar --version 2>&1
	$asarInstalled = $true
} catch {
	$asarInstalled = $false
}

$content = @"
Asar Assembler:
  Status:    $(if ($asarInstalled) { "✓ Installed" } else { "✗ Not Found" })
"@

if ($asarInstalled) {
	$content += "  Version:   $asarVersion`n"
	$asarPath = (Get-Command asar -ErrorAction SilentlyContinue).Source
	if ($asarPath) {
		$content += "  Location:  $asarPath`n"
	}
}

$dotnetInstalled = $null
try {
	$dotnetVersion = & dotnet --version 2>&1
	$dotnetInstalled = $true
} catch {
	$dotnetInstalled = $false
}

$content += "`n.NET Framework:`n"
$content += "  Status:    $(if ($dotnetInstalled) { "✓ Installed" } else { "✗ Not Found" })`n"
if ($dotnetInstalled) {
	$content += "  Version:   $dotnetVersion`n"
}

Add-Section "BUILD TOOLS" $content

# Labels (if label file exists)
if (Test-Path "src\include\ffmq_ram_variables.inc") {
	$labelContent = Get-Content "src\include\ffmq_ram_variables.inc"
	$labelCount = ($labelContent | Select-String "^!" | Measure-Object).Count
	$labelLines = ($labelContent | Measure-Object -Line).Lines
	
	$content = @"
Label File: src\include\ffmq_ram_variables.inc
Total Labels Defined: $labelCount
Label File Size: $labelLines lines

Recent Labels (Last 10):
"@
	
	$recentLabels = $labelContent | Select-String "^!" | Select-Object -Last 10
	foreach ($label in $recentLabels) {
		$content += "`n  $($label.Line)"
	}
	
	Add-Section "MEMORY LABELS" $content
} else {
	Add-Section "MEMORY LABELS" "Label file not found"
}

# Recent Changes (if Git is available)
try {
	$gitInstalled = & git --version 2>&1
	$gitLog = & git log --oneline -10 2>&1
	
	$content = @"
Git Status: ✓ Available

Recent Commits (Last 10):
"@
	
	$gitLog | ForEach-Object {
		$content += "`n  $_"
	}
	
	# Check for uncommitted changes
	$gitStatus = & git status --short 2>&1
	if ($gitStatus) {
		$content += "`n`nUncommitted Changes:`n"
		$gitStatus | ForEach-Object {
			$content += "`n  $_"
		}
	} else {
		$content += "`n`nUncommitted Changes: None (working directory clean)"
	}
	
	Add-Section "VERSION CONTROL" $content
	
} catch {
	Add-Section "VERSION CONTROL" "Git not available"
}

# Project Statistics
$totalAssets = 0
$assetDirs = @("assets", "data", "graphics")

foreach ($dir in $assetDirs) {
	if (Test-Path $dir) {
		$totalAssets += (Get-ChildItem -Path $dir -Recurse -File -ErrorAction SilentlyContinue | Measure-Object).Count
	}
}

$content = @"
Project Structure:
  Source Directory:     $(if (Test-Path "src") { "✓ Present" } else { "✗ Missing" })
  Assets Directory:     $(if (Test-Path "assets") { "✓ Present" } else { "✗ Missing" })
  Build Directory:      $(if (Test-Path "build") { "✓ Present" } else { "✗ Missing" })
  ROMs Directory:       $(if (Test-Path "roms") { "✓ Present" } else { "✗ Missing" })

Total Asset Files: $totalAssets

Documentation:
  BUILD_GUIDE.md:       $(if (Test-Path "BUILD_GUIDE.md") { "✓ Present" } else { "✗ Missing" })
  TROUBLESHOOTING.md:   $(if (Test-Path "TROUBLESHOOTING.md") { "✓ Present" } else { "✗ Missing" })
  README.md:            $(if (Test-Path "README.md") { "✓ Present" } else { "✗ Missing" })
"@

Add-Section "PROJECT STATISTICS" $content

# Recommendations
$recommendations = @()

if (-not (Test-Path $ROMFile)) {
	$recommendations += "- Build the ROM using: asar 'ffmq - onlygood.asm'"
}

if ((Test-Path $ROMFile) -and (Test-Path $OriginalROM)) {
	$fcOutput = & fc.exe /b $OriginalROM $ROMFile 2>&1
	if ($LASTEXITCODE -ne 0) {
		$recommendations += "- ROM does not match original - run round-trip test: .\test-roundtrip.ps1"
	}
}

if (-not $asarInstalled) {
	$recommendations += "- Install Asar assembler from https://www.smwcentral.net/"
}

if ($recommendations.Count -eq 0) {
	$recommendations += "- Build system is healthy! ✓"
	$recommendations += "- Consider running .\test-roundtrip.ps1 for verification"
}

$content = $recommendations -join "`n"
Add-Section "RECOMMENDATIONS" $content

# Footer
[void]$report.AppendLine("")
[void]$report.AppendLine("=" * 70)
[void]$report.AppendLine("End of Report")
[void]$report.AppendLine("=" * 70)

# Save report
$reportContent = $report.ToString()
$reportContent | Out-File $OutputFile -Encoding UTF8

Write-Host "Build report generated successfully!" -ForegroundColor Green
Write-Host "Saved to: $OutputFile" -ForegroundColor Cyan
Write-Host ""
Write-Host "Quick Summary:" -ForegroundColor Yellow
Write-Host "  ROM File: $(if (Test-Path $ROMFile) { '✓' } else { '✗' }) " -NoNewline
if (Test-Path $ROMFile) {
	Write-Host "($((Get-Item $ROMFile).Length) bytes)"
} else {
	Write-Host ""
}
Write-Host "  Build Tools: $(if ($asarInstalled) { '✓' } else { '✗' }) Asar"
Write-Host "  Source Files: $($asmFiles.Count) .asm, $($incFiles.Count) .inc"

# Return report content
return $reportContent
