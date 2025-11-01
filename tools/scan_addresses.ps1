<#
.SYNOPSIS
    Scans ASM files for raw memory addresses and generates usage reports.

.DESCRIPTION
    This script scans all assembly files in the project to identify raw memory
    addresses, categorize them by type (WRAM, Hardware, ROM), count occurrences,
    and generate comprehensive reports for labeling prioritization.

.PARAMETER SourcePath
    Path to the source directory containing ASM files. Defaults to ../src

.PARAMETER OutputPath
    Path where the report CSV will be generated. Defaults to ../reports/address_usage_report.csv

.PARAMETER Verbose
    Show detailed progress information

.EXAMPLE
    .\scan_addresses.ps1
    Scans all ASM files and generates the default report

.EXAMPLE
    .\scan_addresses.ps1 -SourcePath "C:\myproject\src" -Verbose
    Scans custom path with verbose output

.NOTES
    Author: Address Inventory System
    Created for Issue #23: Memory Labels: Address Inventory and Analysis
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$SourcePath = (Join-Path $PSScriptRoot "..\src"),
    
    [Parameter()]
    [string]$OutputPath = (Join-Path $PSScriptRoot "..\reports\address_usage_report.csv"),
    
    [Parameter()]
    [switch]$VerboseOutput
)

# Color output helpers
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Step {
    param([string]$Message)
    Write-ColorOutput "==> $Message" "Cyan"
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" "Green"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠ $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" "Red"
}

# Address categorization functions
function Get-AddressCategory {
    param(
        [string]$Address
    )
    
    # Convert to integer for range checking
    $addr = [Convert]::ToInt32($Address.TrimStart('$'), 16)
    
    # SNES Memory Map categorization
    if ($addr -ge 0x0000 -and $addr -le 0x00FF) {
        return "Zero Page (Direct Page)"
    }
    elseif ($addr -ge 0x0100 -and $addr -le 0x01FF) {
        return "Stack"
    }
    elseif ($addr -ge 0x0200 -and $addr -le 0x1FFF) {
        return "WRAM (Low)"
    }
    elseif ($addr -ge 0x2000 -and $addr -le 0x20FF) {
        return "PPU Registers (Unmapped)"
    }
    elseif ($addr -ge 0x2100 -and $addr -le 0x21FF) {
        return "PPU Registers"
    }
    elseif ($addr -ge 0x2200 -and $addr -le 0x3FFF) {
        return "PPU Registers (Unmapped)"
    }
    elseif ($addr -ge 0x4000 -and $addr -le 0x41FF) {
        return "Controller/Old-Style Joypad"
    }
    elseif ($addr -ge 0x4200 -and $addr -le 0x43FF) {
        return "CPU Registers/DMA/PPU"
    }
    elseif ($addr -ge 0x4400 -and $addr -le 0x5FFF) {
        return "Hardware Registers (Unmapped)"
    }
    elseif ($addr -ge 0x6000 -and $addr -le 0x7FFF) {
        return "Expansion"
    }
    elseif ($addr -ge 0x8000 -and $addr -le 0xFFFF) {
        return "ROM (Bank dependent)"
    }
    else {
        return "Unknown"
    }
}

function Get-AddressType {
    param(
        [string]$Address
    )
    
    $addr = [Convert]::ToInt32($Address.TrimStart('$'), 16)
    
    if ($addr -ge 0x0000 -and $addr -le 0x1FFF) {
        return "WRAM"
    }
    elseif ($addr -ge 0x2100 -and $addr -le 0x21FF) {
        return "PPU"
    }
    elseif ($addr -ge 0x4000 -and $addr -le 0x43FF) {
        return "Hardware"
    }
    elseif ($addr -ge 0x8000 -and $addr -le 0xFFFF) {
        return "ROM"
    }
    else {
        return "Other"
    }
}

function Get-AddressPriority {
    param(
        [int]$Occurrences,
        [string]$Type
    )
    
    # Priority based on usage frequency and type
    if ($Type -eq "WRAM") {
        if ($Occurrences -ge 50) { return "Critical" }
        elseif ($Occurrences -ge 20) { return "High" }
        elseif ($Occurrences -ge 10) { return "Medium" }
        else { return "Low" }
    }
    elseif ($Type -eq "PPU" -or $Type -eq "Hardware") {
        if ($Occurrences -ge 10) { return "High" }
        elseif ($Occurrences -ge 5) { return "Medium" }
        else { return "Low" }
    }
    elseif ($Type -eq "ROM") {
        if ($Occurrences -ge 100) { return "High" }
        elseif ($Occurrences -ge 50) { return "Medium" }
        else { return "Low" }
    }
    else {
        return "Low"
    }
}

function Get-SuggestedLabel {
    param(
        [string]$Address,
        [string]$Type,
        [string]$Category
    )
    
    $addr = [Convert]::ToInt32($Address.TrimStart('$'), 16)
    
    # Known hardware registers
    $hardwareRegisters = @{
        '2100' = 'INIDISP'
        '2101' = 'OBSEL'
        '2102' = 'OAMADDL'
        '2103' = 'OAMADDH'
        '2104' = 'OAMDATA'
        '2105' = 'BGMODE'
        '2106' = 'MOSAIC'
        '2107' = 'BG1SC'
        '2108' = 'BG2SC'
        '2109' = 'BG3SC'
        '210A' = 'BG4SC'
        '210B' = 'BG12NBA'
        '210C' = 'BG34NBA'
        '210D' = 'BG1HOFS'
        '210E' = 'BG1VOFS'
        '210F' = 'BG2HOFS'
        '2110' = 'BG2VOFS'
        '2111' = 'BG3HOFS'
        '2112' = 'BG3VOFS'
        '2113' = 'BG4HOFS'
        '2114' = 'BG4VOFS'
        '2115' = 'VMAIN'
        '2116' = 'VMADDL'
        '2117' = 'VMADDH'
        '2118' = 'VMDATAL'
        '2119' = 'VMDATAH'
        '211A' = 'M7SEL'
        '211B' = 'M7A'
        '211C' = 'M7B'
        '211D' = 'M7C'
        '211E' = 'M7D'
        '211F' = 'M7X'
        '2120' = 'M7Y'
        '2121' = 'CGADD'
        '2122' = 'CGDATA'
        '2123' = 'W12SEL'
        '2124' = 'W34SEL'
        '2125' = 'WOBJSEL'
        '2126' = 'WH0'
        '2127' = 'WH1'
        '2128' = 'WH2'
        '2129' = 'WH3'
        '212A' = 'WBGLOG'
        '212B' = 'WOBJLOG'
        '212C' = 'TM'
        '212D' = 'TS'
        '212E' = 'TMW'
        '212F' = 'TSW'
        '2130' = 'CGWSEL'
        '2131' = 'CGADSUB'
        '2132' = 'COLDATA'
        '2133' = 'SETINI'
        '4016' = 'JOYSER0'
        '4017' = 'JOYSER1'
        '4200' = 'NMITIMEN'
        '4201' = 'WRIO'
        '4202' = 'WRMPYA'
        '4203' = 'WRMPYB'
        '4204' = 'WRDIVL'
        '4205' = 'WRDIVH'
        '4206' = 'WRDIVB'
        '4207' = 'HTIMEL'
        '4208' = 'HTIMEH'
        '4209' = 'VTIMEL'
        '420A' = 'VTIMEH'
        '420B' = 'MDMAEN'
        '420C' = 'HDMAEN'
        '420D' = 'MEMSEL'
        '4210' = 'RDNMI'
        '4211' = 'TIMEUP'
        '4212' = 'HVBJOY'
        '4213' = 'RDIO'
        '4214' = 'RDDIVL'
        '4215' = 'RDDIVH'
        '4216' = 'RDMPYL'
        '4217' = 'RDMPYH'
        '4218' = 'JOY1L'
        '4219' = 'JOY1H'
        '421A' = 'JOY2L'
        '421B' = 'JOY2H'
    }
    
    $addrHex = $Address.TrimStart('$').ToUpper()
    if ($hardwareRegisters.ContainsKey($addrHex)) {
        return $hardwareRegisters[$addrHex]
    }
    
    # Generate suggested label based on category
    if ($Type -eq "WRAM") {
        if ($Category -eq "Zero Page (Direct Page)") {
            return "var_" + $addrHex.ToLower()
        }
        else {
            return "wram_" + $addrHex.ToLower()
        }
    }
    elseif ($Type -eq "PPU") {
        return "ppu_" + $addrHex.ToLower()
    }
    elseif ($Type -eq "Hardware") {
        return "hw_" + $addrHex.ToLower()
    }
    elseif ($Type -eq "ROM") {
        return "rom_" + $addrHex.ToLower()
    }
    else {
        return "addr_" + $addrHex.ToLower()
    }
}

# Main scanning function
function Scan-AsmFiles {
    param(
        [string]$Path
    )
    
    Write-Step "Scanning ASM files in: $Path"
    
    # Find all ASM files
    $asmFiles = Get-ChildItem -Path $Path -Filter "*.asm" -Recurse -File
    Write-ColorOutput "Found $($asmFiles.Count) ASM files" "White"
    
    # Address pattern regex
    # Matches: $XXXX (4 hex digits) in various contexts
    $addressPatterns = @(
        # Direct addressing: LDA $XXXX, STA $XXXX, etc.
        '\b(LDA|STA|LDX|STX|LDY|STY|ADC|SBC|AND|ORA|EOR|CMP|CPX|CPY|BIT|INC|DEC|ASL|LSR|ROL|ROR|JMP|JSR)\s+\$([0-9A-Fa-f]{4})\b',
        # Indexed addressing: LDA $XXXX,X or LDA $XXXX,Y
        '\b(LDA|STA|LDX|STX|LDY|STY|ADC|SBC|AND|ORA|EOR|CMP|CPX|CPY|BIT|INC|DEC|ASL|LSR|ROL|ROR)\s+\$([0-9A-Fa-f]{4}),\s*[XYxy]\b',
        # Long addressing: LDA $XXXXXX (will extract first 4 digits)
        '\b(LDA|STA|LDX|STX|LDY|STY|ADC|SBC|AND|ORA|EOR|CMP|JMP|JSR|JML|JSL)\s+\$([0-9A-Fa-f]{4})[0-9A-Fa-f]{2}\b',
        # Direct addressing without instruction (data references)
        '\.dw\s+\$([0-9A-Fa-f]{4})\b',
        '\.dl\s+\$([0-9A-Fa-f]{4})[0-9A-Fa-f]{2}\b'
    )
    
    # Combined regex for all patterns
    $combinedPattern = '(?:' + ($addressPatterns -join '|') + ')'
    
    # Hash table to store address occurrences
    $addressOccurrences = @{}
    $addressContexts = @{}
    
    $fileCount = 0
    foreach ($file in $asmFiles) {
        $fileCount++
        if ($VerboseOutput) {
            Write-Progress -Activity "Scanning files" -Status "$fileCount / $($asmFiles.Count)" -PercentComplete (($fileCount / $asmFiles.Count) * 100)
        }
        
        $content = Get-Content -Path $file.FullName -Raw
        
        # Find all address matches
        $matches = [regex]::Matches($content, $combinedPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
        
        foreach ($match in $matches) {
            # Extract the address from the match
            $address = $null
            for ($i = 1; $i -lt $match.Groups.Count; $i++) {
                if ($match.Groups[$i].Success -and $match.Groups[$i].Value -match '^[0-9A-Fa-f]{4}$') {
                    $address = '$' + $match.Groups[$i].Value.ToUpper()
                    break
                }
            }
            
            if ($address) {
                # Skip known labels (those that start with uppercase letter after $)
                if ($address -match '^\$[0-9A-Fa-f]{4}$') {
                    if (-not $addressOccurrences.ContainsKey($address)) {
                        $addressOccurrences[$address] = 0
                        $addressContexts[$address] = @()
                    }
                    $addressOccurrences[$address]++
                    
                    # Store context (file and line)
                    if ($addressContexts[$address].Count -lt 5) {  # Limit to first 5 contexts
                        $addressContexts[$address] += "$($file.Name):$($match.Value)"
                    }
                }
            }
        }
    }
    
    Write-Success "Scanned $fileCount files"
    Write-ColorOutput "Found $($addressOccurrences.Count) unique addresses" "White"
    
    return @{
        Occurrences = $addressOccurrences
        Contexts = $addressContexts
    }
}

# Generate CSV report
function Generate-Report {
    param(
        [hashtable]$Occurrences,
        [hashtable]$Contexts,
        [string]$OutputPath
    )
    
    Write-Step "Generating report: $OutputPath"
    
    # Create output directory if needed
    $outputDir = Split-Path -Parent $OutputPath
    if (-not (Test-Path $outputDir)) {
        New-Item -ItemType Directory -Path $outputDir -Force | Out-Null
    }
    
    # Build report data
    $reportData = @()
    
    foreach ($address in ($Occurrences.Keys | Sort-Object)) {
        $count = $Occurrences[$address]
        $type = Get-AddressType -Address $address
        $category = Get-AddressCategory -Address $address
        $priority = Get-AddressPriority -Occurrences $count -Type $type
        $suggestedLabel = Get-SuggestedLabel -Address $address -Type $type -Category $category
        $exampleContexts = ($Contexts[$address] | Select-Object -First 3) -join '; '
        
        $reportData += [PSCustomObject]@{
            Address = $address
            Type = $type
            Category = $category
            Occurrences = $count
            Priority = $priority
            Suggested_Label = $suggestedLabel
            Example_Contexts = $exampleContexts
        }
    }
    
    # Sort by priority and occurrences
    $priorityOrder = @{ 'Critical' = 1; 'High' = 2; 'Medium' = 3; 'Low' = 4 }
    $reportData = $reportData | Sort-Object { $priorityOrder[$_.Priority] }, { -$_.Occurrences }
    
    # Export to CSV
    $reportData | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
    
    Write-Success "Report generated successfully"
    
    # Display summary statistics
    Write-ColorOutput "`n=== Summary Statistics ===" "Cyan"
    Write-ColorOutput "Total unique addresses: $($reportData.Count)" "White"
    
    $byType = $reportData | Group-Object Type
    foreach ($group in $byType) {
        Write-ColorOutput "  $($group.Name): $($group.Count)" "White"
    }
    
    $byPriority = $reportData | Group-Object Priority
    Write-ColorOutput "`nBy Priority:" "Cyan"
    foreach ($group in ($byPriority | Sort-Object { $priorityOrder[$_.Name] })) {
        $color = switch ($group.Name) {
            'Critical' { 'Red' }
            'High' { 'Yellow' }
            'Medium' { 'Cyan' }
            'Low' { 'Gray' }
        }
        Write-ColorOutput "  $($group.Name): $($group.Count)" $color
    }
    
    Write-ColorOutput "`nTop 10 Most-Used Addresses:" "Cyan"
    $reportData | Select-Object -First 10 | ForEach-Object {
        Write-ColorOutput ("  {0} ({1}): {2} occurrences - {3}" -f $_.Address, $_.Type, $_.Occurrences, $_.Suggested_Label) "White"
    }
    
    return $reportData
}

# Main execution
try {
    Write-ColorOutput "`n=== FFMQ Address Scanner ===" "Magenta"
    Write-ColorOutput "Scanning for raw memory addresses in assembly files`n" "White"
    
    # Validate source path
    if (-not (Test-Path $SourcePath)) {
        Write-Error "Source path not found: $SourcePath"
        exit 1
    }
    
    # Scan files
    $scanResults = Scan-AsmFiles -Path $SourcePath
    
    # Generate report
    $reportData = Generate-Report -Occurrences $scanResults.Occurrences -Contexts $scanResults.Contexts -OutputPath $OutputPath
    
    Write-ColorOutput "`n✓ Complete! Report saved to: $OutputPath" "Green"
    
} catch {
    Write-Error "Error: $_"
    Write-Error $_.ScriptStackTrace
    exit 1
}
