<#
.SYNOPSIS
    FFMQ Round-Trip Build Test
    
.DESCRIPTION
    Verifies that building the ROM from source produces a byte-perfect match
    with the original ROM. This is the gold standard for build system integrity.
    
.PARAMETER OriginalROM
    Path to the original FFMQ ROM file for comparison
    
.PARAMETER BuildFile
    Assembly source file to build from
    
.PARAMETER OutputROM
    Path where the built ROM will be output
    
.PARAMETER Verbose
    Show detailed output during testing
    
.EXAMPLE
    .\test-roundtrip.ps1
    
.EXAMPLE
    .\test-roundtrip.ps1 -OriginalROM "roms\ffmq-usa.sfc" -Verbose
    
.NOTES
    Author: FFMQ Disassembly Project
    Version: 1.0
    Last Updated: 2025-11-01
#>

param(
    [Parameter(HelpMessage="Path to original ROM")]
    [string]$OriginalROM = "roms\ffmq-original.sfc",
    
    [Parameter(HelpMessage="Assembly source file to build")]
    [string]$BuildFile = "ffmq - onlygood.asm",
    
    [Parameter(HelpMessage="Output ROM file path")]
    [string]$OutputROM = "ffmq - onlygood.sfc",
    
    [Parameter(HelpMessage="Show detailed output")]
    [switch]$Verbose
)

# Color constants
$ColorHeader = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorError = "Red"
$ColorInfo = "White"

# Banner
function Show-Banner {
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor $ColorHeader
    Write-Host "  FFMQ Round-Trip Build Test v1.0" -ForegroundColor $ColorHeader
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor $ColorHeader
    Write-Host ""
}

# Step header
function Show-Step {
    param([string]$StepNumber, [string]$Description)
    Write-Host ""
    Write-Host "[$StepNumber] $Description" -ForegroundColor $ColorWarning
    Write-Host ("-" * 60) -ForegroundColor DarkGray
}

# Success message
function Show-Success {
    param([string]$Message)
    Write-Host "  ✓ $Message" -ForegroundColor $ColorSuccess
}

# Error message
function Show-Error {
    param([string]$Message)
    Write-Host "  ✗ $Message" -ForegroundColor $ColorError
}

# Info message
function Show-Info {
    param([string]$Message)
    Write-Host "  → $Message" -ForegroundColor $ColorInfo
}

# Test result summary
function Show-Result {
    param([bool]$Success)
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor $ColorHeader
    if ($Success) {
        Write-Host "  ROUND-TRIP TEST: PASSED ✓" -ForegroundColor $ColorSuccess
        Write-Host "  Build produces byte-perfect match with original ROM" -ForegroundColor $ColorSuccess
    } else {
        Write-Host "  ROUND-TRIP TEST: FAILED ✗" -ForegroundColor $ColorError
        Write-Host "  Build does NOT match original ROM" -ForegroundColor $ColorError
    }
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor $ColorHeader
    Write-Host ""
}

# Main test function
function Test-RoundTrip {
    Show-Banner
    
    # Step 1: Verify Prerequisites
    Show-Step "1/5" "Checking Prerequisites"
    
    # Check for asar
    try {
        $asarVersion = & asar --version 2>&1
        Show-Success "Asar assembler found: $asarVersion"
    } catch {
        Show-Error "Asar assembler not found in PATH"
        Show-Info "Download from: https://www.smwcentral.net/?p=section&a=details&id=19043"
        Show-Info "Add asar.exe to system PATH or current directory"
        return $false
    }
    
    # Check for original ROM
    if (-not (Test-Path $OriginalROM)) {
        Show-Error "Original ROM not found: $OriginalROM"
        Show-Info "Place the original FFMQ ROM at: $OriginalROM"
        Show-Info "Or specify path with -OriginalROM parameter"
        return $false
    }
    
    $originalSize = (Get-Item $OriginalROM).Length
    Show-Success "Original ROM found: $OriginalROM ($originalSize bytes)"
    
    # Check for build file
    if (-not (Test-Path $BuildFile)) {
        Show-Error "Build file not found: $BuildFile"
        return $false
    }
    Show-Success "Build file found: $BuildFile"
    
    # Step 2: Calculate Original ROM Hash
    Show-Step "2/5" "Calculating Original ROM Checksums"
    
    $originalMD5 = (Get-FileHash $OriginalROM -Algorithm MD5).Hash
    $originalSHA256 = (Get-FileHash $OriginalROM -Algorithm SHA256).Hash
    
    Show-Info "Size:   $originalSize bytes"
    Show-Info "MD5:    $originalMD5"
    if ($Verbose) {
        Show-Info "SHA256: $originalSHA256"
    }
    
    # Step 3: Clean Previous Build
    Show-Step "3/5" "Cleaning Previous Build Output"
    
    if (Test-Path $OutputROM) {
        Remove-Item $OutputROM -Force
        Show-Success "Removed previous build: $OutputROM"
    } else {
        Show-Info "No previous build to clean"
    }
    
    # Step 4: Build ROM from Source
    Show-Step "4/5" "Building ROM from Source"
    
    Show-Info "Running: asar `"$BuildFile`""
    $buildStartTime = Get-Date
    
    try {
        $asarOutput = & asar $BuildFile 2>&1
        $buildEndTime = Get-Date
        $buildDuration = ($buildEndTime - $buildStartTime).TotalSeconds
        
        if ($LASTEXITCODE -ne 0) {
            Show-Error "Build failed with exit code: $LASTEXITCODE"
            Show-Info "Asar output:"
            Write-Host $asarOutput -ForegroundColor $ColorError
            return $false
        }
        
        Show-Success "Build completed in $([math]::Round($buildDuration, 2)) seconds"
        
        if ($Verbose -and $asarOutput) {
            Show-Info "Build output:"
            Write-Host $asarOutput -ForegroundColor DarkGray
        }
        
    } catch {
        Show-Error "Build failed with exception: $($_.Exception.Message)"
        return $false
    }
    
    # Verify output file was created
    if (-not (Test-Path $OutputROM)) {
        Show-Error "Output ROM was not created: $OutputROM"
        Show-Info "Check build file for errors"
        return $false
    }
    
    $builtSize = (Get-Item $OutputROM).Length
    Show-Success "Output ROM created: $OutputROM ($builtSize bytes)"
    
    # Step 5: Verify Byte-Perfect Match
    Show-Step "5/5" "Verifying Byte-Perfect Match"
    
    # Check sizes first
    Show-Info "Comparing file sizes..."
    Show-Info "  Original: $originalSize bytes"
    Show-Info "  Built:    $builtSize bytes"
    
    if ($originalSize -ne $builtSize) {
        Show-Error "SIZE MISMATCH!"
        $sizeDiff = [math]::Abs($builtSize - $originalSize)
        Show-Info "Difference: $sizeDiff bytes"
        
        if ($builtSize -lt $originalSize) {
            Show-Info "Built ROM is SMALLER (missing data?)"
        } else {
            Show-Info "Built ROM is LARGER (extra data?)"
        }
        
        return $false
    }
    Show-Success "File sizes match"
    
    # Byte-by-byte comparison
    Show-Info "Performing byte-by-byte comparison..."
    
    $comparisonStartTime = Get-Date
    $fcOutput = & fc.exe /b $OriginalROM $OutputROM 2>&1
    $comparisonEndTime = Get-Date
    $comparisonDuration = ($comparisonEndTime - $comparisonStartTime).TotalSeconds
    
    if ($LASTEXITCODE -eq 0) {
        Show-Success "PERFECT MATCH! All bytes identical"
        Show-Info "Comparison completed in $([math]::Round($comparisonDuration, 2)) seconds"
        
        # Calculate built ROM checksums
        Show-Info ""
        Show-Info "Built ROM checksums:"
        $builtMD5 = (Get-FileHash $OutputROM -Algorithm MD5).Hash
        Show-Info "  MD5:    $builtMD5"
        
        if ($Verbose) {
            $builtSHA256 = (Get-FileHash $OutputROM -Algorithm SHA256).Hash
            Show-Info "  SHA256: $builtSHA256"
        }
        
        # Verify checksums match
        if ($originalMD5 -eq $builtMD5) {
            Show-Success "Checksums verified: MD5 match"
        } else {
            Show-Error "Checksum mismatch (this should never happen!)"
            return $false
        }
        
        return $true
        
    } else {
        Show-Error "BYTE MISMATCH! ROMs are different"
        Show-Info "Comparison completed in $([math]::Round($comparisonDuration, 2)) seconds"
        
        # Parse fc output to find first difference
        $fcLines = $fcOutput -split "`r?`n"
        $firstDiff = $fcLines | Where-Object { $_ -match '^[0-9A-F]+:' } | Select-Object -First 1
        
        if ($firstDiff) {
            Show-Info ""
            Show-Info "First difference found:"
            Write-Host "  $firstDiff" -ForegroundColor $ColorWarning
            
            # Parse offset
            if ($firstDiff -match '^([0-9A-F]+):') {
                $offset = [Convert]::ToInt32($matches[1], 16)
                $offsetHex = "0x{0:X6}" -f $offset
                
                # Convert to LoROM bank:address
                $bank = [math]::Floor($offset / 0x8000)
                $addr = ($offset % 0x8000) + 0x8000
                $bankAddr = "`${0:X2}:{1:X4}" -f $bank, $addr
                
                Show-Info "  ROM Offset: $offsetHex"
                Show-Info "  LoROM Addr: $bankAddr"
                Show-Info ""
                Show-Info "Check source code at this location for discrepancies"
            }
        }
        
        if ($Verbose) {
            Show-Info ""
            Show-Info "All differences (first 20):"
            $fcLines | Where-Object { $_ -match '^[0-9A-F]+:' } | Select-Object -First 20 | ForEach-Object {
                Write-Host "  $_" -ForegroundColor DarkGray
            }
        }
        
        return $false
    }
}

# Run the test
$testResult = Test-RoundTrip

# Show final result
Show-Result -Success $testResult

# Exit with appropriate code
if ($testResult) {
    exit 0
} else {
    exit 1
}
