# Final Fantasy Mystic Quest - Build Verification Script
# Assembles bank_00_documented.asm and compares with reference ROM

param(
    [string]$RomPath = "roms\Final Fantasy - Mystic Quest (U) (V1.0) [!].sfc"
)

Write-Host "FFMQ Build Verification System" -ForegroundColor Cyan
Write-Host "==============================" -ForegroundColor Cyan
Write-Host ""

# Check for asar assembler
Write-Host "Checking for asar assembler..." -ForegroundColor Yellow
$asar = Get-Command asar -ErrorAction SilentlyContinue
if (-not $asar) {
    Write-Host "ERROR: asar not found in PATH" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please download asar from:" -ForegroundColor Yellow
    Write-Host "  https://github.com/RPGHacker/asar/releases" -ForegroundColor White
    Write-Host ""
    Write-Host "Extract asar.exe to a directory in your PATH or to this project folder" -ForegroundColor White
    exit 1
}
Write-Host "  Found: $($asar.Source)" -ForegroundColor Green
Write-Host ""

# Check for reference ROM
$romFullPath = Join-Path $PSScriptRoot $RomPath
# Escape brackets in path for Test-Path
$testPath = $romFullPath -replace '\[', '`[' -replace '\]', '`]'

if (-not (Test-Path -LiteralPath $romFullPath)) {
    Write-Host "ERROR: Reference ROM not found at: $romFullPath" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please ensure you have the reference ROM file." -ForegroundColor Yellow
    exit 1
}
Write-Host "Reference ROM: $romFullPath" -ForegroundColor Green
Write-Host ""

# Create build directory if needed
$buildDir = Join-Path $PSScriptRoot "build"
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir | Out-Null
}

# Check if bank_00_documented.asm exists
$sourceFile = Join-Path $PSScriptRoot "src\asm\bank_00_documented.asm"
if (-not (Test-Path $sourceFile)) {
    Write-Host "ERROR: Source file not found: $sourceFile" -ForegroundColor Red
    exit 1
}
Write-Host "Source file: $sourceFile" -ForegroundColor Green
Write-Host ""

# Create a temporary assembly wrapper for bank $00 only
$wrapperFile = Join-Path $buildDir "bank_00_wrapper.asm"
Write-Host "Creating assembly wrapper..." -ForegroundColor Yellow

$wrapperContent = @"
; Temporary wrapper for building bank `$00 only
; This allows us to verify our documented code against the original ROM

arch 65816

; Set origin to bank `$00
org `$008000

; Include SNES hardware register definitions
incsrc "../src/asm/snes_registers.asm"

; Include our documented bank `$00 code
incsrc "../src/asm/bank_00_documented.asm"
"@

Set-Content -Path $wrapperFile -Value $wrapperContent -Encoding ASCII
Write-Host "  Created: $wrapperFile" -ForegroundColor Green
Write-Host ""

# Assemble the code
$outputFile = Join-Path $buildDir "bank_00_test.sfc"
Write-Host "Assembling bank `$00..." -ForegroundColor Yellow
Write-Host "  Command: asar $wrapperFile $outputFile" -ForegroundColor Gray

try {
    & asar $wrapperFile $outputFile 2>&1 | Out-String | Write-Host
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "ERROR: Assembly failed with exit code $LASTEXITCODE" -ForegroundColor Red
        exit 1
    }
    
    if (-not (Test-Path $outputFile)) {
        Write-Host ""
        Write-Host "ERROR: Output file was not created" -ForegroundColor Red
        exit 1
    }
    
    Write-Host ""
    Write-Host "  Success!" -ForegroundColor Green
} catch {
    Write-Host ""
    Write-Host "ERROR: Assembly failed: $_" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Read both files
Write-Host "Comparing with reference ROM..." -ForegroundColor Yellow
$assembled = [System.IO.File]::ReadAllBytes($outputFile)
$reference = [System.IO.File]::ReadAllBytes($romFullPath)

Write-Host "  Assembled size: $($assembled.Length) bytes" -ForegroundColor Gray
Write-Host "  Reference ROM: $($reference.Length) bytes" -ForegroundColor Gray
Write-Host ""

# Compare bank $00 region (0x8000-0xFFFF in ROM is typically at offset 0x200-0x8200 with header)
# SNES ROM headers are typically 512 bytes, so bank $00 starts at offset 0x200
$headerSize = 0x200
$bank00Start = 0x8000
$bank00Offset = $headerSize + $bank00Start

# Determine how much of bank $00 we've documented
# Read our documented file to see its size
$sourceContent = Get-Content $sourceFile -Raw
$lastAddress = if ($sourceContent -match 'CODE_([0-9A-F]+):(?!.*CODE_)') {
    [Convert]::ToInt32($matches[1], 16)
} else {
    0x8000  # Default if we can't find any CODE labels
}

$bytesToCompare = $lastAddress - 0x8000
if ($bytesToCompare -le 0) {
    $bytesToCompare = 0x1000  # Default to 4KB if we can't determine
}

Write-Host "Documented region: `$008000-`$$($lastAddress.ToString('X6'))" -ForegroundColor Cyan
Write-Host "Comparing first $bytesToCompare bytes..." -ForegroundColor Yellow
Write-Host ""

# Compare byte by byte
$differences = 0
$firstDiffOffset = -1

for ($i = 0; $i -lt $bytesToCompare -and $i -lt $assembled.Length; $i++) {
    $refOffset = $bank00Offset + $i
    if ($refOffset -ge $reference.Length) {
        Write-Host "WARNING: Reference ROM too small" -ForegroundColor Yellow
        break
    }
    
    if ($assembled[$i] -ne $reference[$refOffset]) {
        $differences++
        if ($firstDiffOffset -eq -1) {
            $firstDiffOffset = $i
        }
    }
}

# Report results
Write-Host "================================" -ForegroundColor Cyan
if ($differences -eq 0) {
    Write-Host "VERIFICATION SUCCESS!" -ForegroundColor Green
    Write-Host ""
    Write-Host "All $bytesToCompare bytes match the reference ROM exactly." -ForegroundColor Green
    Write-Host "The documented code is byte-perfect." -ForegroundColor Green
} else {
    Write-Host "VERIFICATION FAILED" -ForegroundColor Red
    Write-Host ""
    Write-Host "Found $differences byte difference(s) in $bytesToCompare bytes compared" -ForegroundColor Red
    Write-Host "First difference at offset: 0x$($firstDiffOffset.ToString('X4'))" -ForegroundColor Red
    Write-Host "  ROM address: `$00$((0x8000 + $firstDiffOffset).ToString('X4'))" -ForegroundColor Red
    Write-Host ""
    
    # Show first few differences
    Write-Host "First differences:" -ForegroundColor Yellow
    $diffCount = 0
    for ($i = 0; $i -lt $bytesToCompare -and $diffCount -lt 10; $i++) {
        $refOffset = $bank00Offset + $i
        if ($assembled[$i] -ne $reference[$refOffset]) {
            $addr = 0x8000 + $i
            Write-Host "  `$00$($addr.ToString('X4')): Assembled=0x$($assembled[$i].ToString('X2')) Reference=0x$($reference[$refOffset].ToString('X2'))" -ForegroundColor Red
            $diffCount++
        }
    }
    
    if ($differences -gt 10) {
        Write-Host "  ... and $($differences - 10) more difference(s)" -ForegroundColor Red
    }
}

Write-Host "================================" -ForegroundColor Cyan
Write-Host ""
