#!/usr/bin/env pwsh
<#
.SYNOPSIS
	Quick ROM build verification script

.DESCRIPTION
	Quickly verifies that the ROM builds correctly and matches expected hash.
	Useful for CI/CD or quick sanity checks.

.PARAMETER Verbose
	Show detailed build output

.EXAMPLE
	.\quick-verify.ps1
	.\quick-verify.ps1 -Verbose
#>

param(
	[switch]$Verbose
)

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host "  FFMQ Quick Build Verification" -ForegroundColor Cyan
Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Cyan
Write-Host ""

# Expected hash for valid ROM
$EXPECTED_HASH = "F71817F55FEBD32FD1DCE617A326A77B6B062DD0D4058ECD289F64AF1B7A1D05"
$BUILD_OUTPUT = "build\ffmq-rebuilt.sfc"

# Step 1: Build ROM
Write-Host "�� Step 1: Building ROM..." -ForegroundColor Yellow

if ($Verbose) {
	& .\build.ps1
} else {
	$buildOutput = & .\build.ps1 2>&1
	if ($LASTEXITCODE -ne 0) {
		Write-Host "❌ Build failed!" -ForegroundColor Red
		Write-Host $buildOutput
		exit 1
	}
}

if (-not (Test-Path $BUILD_OUTPUT)) {
	Write-Host "❌ Build failed - output file not found!" -ForegroundColor Red
	exit 1
}

Write-Host "✓ Build completed successfully" -ForegroundColor Green
Write-Host ""

# Step 2: Calculate hash
Write-Host "🔍 Step 2: Verifying ROM hash..." -ForegroundColor Yellow

$hash = (Get-FileHash $BUILD_OUTPUT -Algorithm SHA256).Hash

Write-Host "  Expected: $EXPECTED_HASH" -ForegroundColor Gray
Write-Host "  Actual:   $hash" -ForegroundColor Gray
Write-Host ""

if ($hash -eq $EXPECTED_HASH) {
	Write-Host "✅ VERIFICATION PASSED" -ForegroundColor Green
	Write-Host "   ROM builds correctly and matches expected hash!" -ForegroundColor Green
	Write-Host ""

	# Step 3: Run integrity check
	Write-Host "🔍 Step 3: Running integrity check..." -ForegroundColor Yellow
	python tools\rom_integrity.py $BUILD_OUTPUT

	exit 0
} else {
	Write-Host "❌ VERIFICATION FAILED" -ForegroundColor Red
	Write-Host "   ROM hash does not match expected value!" -ForegroundColor Red
	Write-Host ""
	Write-Host "This could mean:" -ForegroundColor Yellow
	Write-Host "  • Assembly source has been modified" -ForegroundColor Yellow
	Write-Host "  • Build tools generated different output" -ForegroundColor Yellow
	Write-Host "  • ROM header or padding changed" -ForegroundColor Yellow
	Write-Host ""

	exit 1
}
