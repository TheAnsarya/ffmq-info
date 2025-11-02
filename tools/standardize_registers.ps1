# Standardize Hardware Register References
# Replace numeric addresses with symbolic SNES_* labels
# Created: November 2, 2025

param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,

    [switch]$DryRun
)

# Hardware register mappings (from labels.asm)
# Note: PowerShell hashtables are case-insensitive, so we handle both cases in the pattern
$registerMappings = @(
    @{Num='211b'; Name='SNES_M7A'}
    @{Num='211c'; Name='SNES_M7B'}
    @{Num='2115'; Name='SNES_VMAINC'}
    @{Num='2116'; Name='SNES_VMADDL'}
    @{Num='2118'; Name='SNES_VMDATAL'}
    @{Num='2119'; Name='SNES_VMDATAH'}
    @{Num='2121'; Name='SNES_CGADD'}
    @{Num='2122'; Name='SNES_CGDATA'}
    @{Num='2101'; Name='SNES_OBJSEL'}
    @{Num='2102'; Name='SNES_OAMADDL'}
    @{Num='2103'; Name='SNES_OAMADDH'}
    @{Num='2106'; Name='SNES_MOSAIC'}
    @{Num='2107'; Name='SNES_BG1SC'}
    @{Num='2108'; Name='SNES_BG2SC'}
    @{Num='210f'; Name='SNES_BG2HOFS'}
    @{Num='212c'; Name='SNES_TM'}
    @{Num='212d'; Name='SNES_TS'}
    @{Num='2123'; Name='SNES_W12SEL'}
    @{Num='2124'; Name='SNES_W34SEL'}
    @{Num='2125'; Name='SNES_WOBJSEL'}
    @{Num='2127'; Name='SNES_WH1'}
    @{Num='2129'; Name='SNES_WH3'}
    @{Num='2130'; Name='SNES_CGSWSEL'}
    @{Num='2131'; Name='SNES_CGADSUB'}
    @{Num='2180'; Name='SNES_WMDATA'}
    @{Num='2181'; Name='SNES_WMADDL'}
    @{Num='2183'; Name='SNES_WMADDH'}
)

Write-Host "Standardizing hardware registers in: $FilePath" -ForegroundColor Cyan

if (!(Test-Path $FilePath)) {
    Write-Host "ERROR: File not found: $FilePath" -ForegroundColor Red
    exit 1
}

$content = Get-Content $FilePath -Raw
$replacementCount = 0

foreach ($mapping in $registerMappings) {
    $numeric = $mapping.Num
    $symbolic = $mapping.Name

    # Match instruction operands only (not comments or data)
    # Pattern: instruction.mode $21xx (case-insensitive hex)
    $pattern = "(\s(?:lda|ldx|ldy|sta|stx|sty|stz|adc|sbc|and|ora|eor|cmp|cpx|cpy|bit|inc|dec|asl|lsr|rol|ror|jmp|jsr)\.(?:B|W|L)?\s+)\`$$numeric(?=\s|;)"

    if ($content -match $pattern) {
        $regexMatches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        $count = $regexMatches.Count
        $content = $content -replace $pattern, "`$1$symbolic"
        $replacementCount += $count
        Write-Host "  Replaced $count occurrence(s) of `$$numeric with $symbolic" -ForegroundColor Green
    }
}if ($replacementCount -eq 0) {
    Write-Host "  No numeric hardware register references found!" -ForegroundColor Yellow
} else {
    Write-Host "`nTotal replacements: $replacementCount" -ForegroundColor Cyan

    if ($DryRun) {
        Write-Host "`n[DRY RUN] Would save changes to: $FilePath" -ForegroundColor Yellow
        Write-Host "Run without -DryRun to apply changes" -ForegroundColor Yellow
    } else {
        Set-Content -Path $FilePath -Value $content -NoNewline
        Write-Host "✅ Changes saved to: $FilePath" -ForegroundColor Green
    }
}

# Show statistics
$lines = ($content -split "`n").Count
Write-Host "`nFile statistics:" -ForegroundColor Cyan
Write-Host "  Lines: $lines"
Write-Host "  Replacements: $replacementCount"
Write-Host "  File: $FilePath"
