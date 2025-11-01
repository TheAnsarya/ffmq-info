# ===============================================
# Catalog ROM Data Tables
# ===============================================
# Scans all ASM files for DATA8/DATA16/ADDR labels
# and generates a comprehensive catalog
# ===============================================

param(
    [string]$asmPath = "$PSScriptRoot\..\src\asm",
    [string]$OutputPath = "$PSScriptRoot\..\reports\rom_data_catalog.csv"
)

Write-Host "🔍 Cataloging ROM Data Tables..." -ForegroundColor Cyan

# Get all documented ASM files
$asmFiles = Get-ChildItem -Path $asmPath -Filter "*_documented.asm" -Recurse

$dataTables = @()

foreach ($file in $asmFiles) {
    Write-Host "  Scanning $($file.Name)..." -ForegroundColor Gray

    # Extract bank number from filename
    if ($file.Name -match 'bank_([0-9A-F]{2})_') {
        $bankNum = $matches[1]
    } else {
        $bankNum = "??"
    }

    $content = Get-Content $file.FullName

    for ($i = 0; $i -lt $content.Length; $i++) {
        $line = $content[$i]

        # Match DATA8_, DATA16_, ADDR_ labels
        if ($line -match '^(DATA8_|DATA16_|ADDR_)([0-9A-F]{6}):(.*)$') {
            $labelType = $matches[1].TrimEnd('_')
            $address = $matches[2]
            $comment = $matches[3].Trim()

            # Extract comment/description if present
            $description = ""
            if ($comment -match ';.*\|(.+?)\|') {
                $description = $matches[1].Trim()
            } elseif ($comment -match ';(.+)') {
                $description = $matches[1].Trim()
            }

            # Look ahead for data definition to estimate size
            $dataBytes = 0
            $dataType = ""
            $nextLine = if ($i + 1 -lt $content.Length) { $content[$i + 1] } else { "" }

            if ($nextLine -match '\s+(db|dw|dl)\s+(.+)') {
                $directive = $matches[1]
                $dataType = switch ($directive) {
                    "db" { "byte" }
                    "dw" { "word" }
                    "dl" { "long" }
                    default { $directive }
                }

                # Count comma-separated values (rough estimate)
                $values = $matches[2] -split ',' | Where-Object { $_ -match '\S' }
                $dataBytes = $values.Count * $(switch ($directive) {
                    "db" { 1 }
                    "dw" { 2 }
                    "dl" { 3 }
                    default { 1 }
                })
            }

            $dataTables += [PSCustomObject]@{
                Bank = $bankNum
                Address = $address
                Label = "$labelType`_$address"
                Type = $labelType
                DataType = $dataType
                EstimatedSize = $dataBytes
                Description = $description
                File = $file.Name
            }
        }
    }
}

Write-Host ""
Write-Host "✅ Found $($dataTables.Count) data tables" -ForegroundColor Green

# Sort by bank and address
$dataTables = $dataTables | Sort-Object Bank, Address

# Export to CSV
$dataTables | Export-Csv -Path $OutputPath -NoTypeInformation
Write-Host "📝 Catalog saved to: $OutputPath" -ForegroundColor Green

# Generate statistics
Write-Host ""
Write-Host "📊 Statistics by Bank:" -ForegroundColor Cyan
$dataTables | Group-Object Bank | Sort-Object Name | ForEach-Object {
    $bank = $_.Name
    $count = $_.Count
    Write-Host "  Bank `$$bank : $count tables" -ForegroundColor Gray
}

Write-Host ""
Write-Host "📊 Statistics by Type:" -ForegroundColor Cyan
$dataTables | Group-Object Type | Sort-Object Count -Descending | ForEach-Object {
    $type = $_.Name
    $count = $_.Count
    Write-Host "  $type : $count tables" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Done!" -ForegroundColor Green
