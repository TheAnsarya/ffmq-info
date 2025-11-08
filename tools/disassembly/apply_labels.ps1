<#
.SYNOPSIS
	Apply labels to FFMQ assembly code
	
.DESCRIPTION
	Automated tool for replacing memory addresses with descriptive labels in
	assembly source files. Supports multiple input formats (CSV/JSON), handles
	different addressing modes, and verifies ROM integrity after replacement.
	
.PARAMETER InputFile
	Path to CSV or JSON file containing address-to-label mappings
	
.PARAMETER SourceFiles
	Array of assembly source files to process. Use wildcards for multiple files.
	
.PARAMETER DryRun
	If specified, shows what would be changed without modifying files
	
.PARAMETER Verify
	If specified, builds ROM after changes and verifies it matches original
	
.PARAMETER BackupDir
	Directory to store backups. Default: backups/
	
.PARAMETER OriginalROM
	Path to original ROM for verification. Default: roms/ffmq-original.sfc
	
.EXAMPLE
	.\apply_labels.ps1 -InputFile labels.csv -SourceFiles "src/asm/bank_00.asm" -DryRun
	
.EXAMPLE
	.\apply_labels.ps1 -InputFile labels.json -SourceFiles "src/asm/*.asm" -Verify
	
.EXAMPLE
	.\apply_labels.ps1 -InputFile labels.csv -SourceFiles "src/asm/bank_00.asm","src/asm/bank_01.asm"
	
.NOTES
	Author: FFMQ Disassembly Project
	Version: 1.0
	Issue: #27 - Memory Labels: Label Replacement Tool Development
	Last Updated: November 1, 2025
	
	Addressing Modes Supported:
	- Absolute: LDA $7e0040
	- Direct Page: LDA $40
	- Long: LDA $7e0040
	- Indexed: LDA $7e0040,X
#>

[CmdletBinding()]
param(
	[Parameter(Mandatory=$true, HelpMessage="Path to CSV or JSON file with label mappings")]
	[ValidateScript({Test-Path $_})]
	[string]$InputFile,
	
	[Parameter(Mandatory=$true, HelpMessage="Source files to process (supports wildcards)")]
	[string[]]$SourceFiles,
	
	[Parameter(HelpMessage="Show changes without modifying files")]
	[switch]$dryRun,
	
	[Parameter(HelpMessage="Verify ROM matches after replacement")]
	[switch]$Verify,
	
	[Parameter(HelpMessage="Backup directory")]
	[string]$backupDir = "backups",
	
	[Parameter(HelpMessage="Original ROM path for verification")]
	[string]$OriginalROM = "roms\ffmq-original.sfc",
	
	[Parameter(HelpMessage="Show verbose output")]
	[switch]$Verbose
)

# ============================================================================
# Configuration
# ============================================================================

$errorActionPreference = "Stop"
$script:replacementCount = 0
$script:fileCount = 0
$script:errorCount = 0

# ============================================================================
# Helper Functions
# ============================================================================

function Write-ColorOutput {
	param(
		[string]$Message,
		[string]$color = "White"
	)
	Write-Host $Message -ForegroundColor $color
}

function Write-Header {
	param([string]$Title)
	Write-Host ""
	Write-Host ("=" * 70) -ForegroundColor Cyan
	Write-Host "  $Title" -ForegroundColor Cyan
	Write-Host ("=" * 70) -ForegroundColor Cyan
	Write-Host ""
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

function Write-Info {
	param([string]$Message)
	Write-ColorOutput "ℹ $Message" "Cyan"
}

# ============================================================================
# Load Label Mappings
# ============================================================================

function Load-LabelMappings {
	param([string]$filePath)
	
	Write-Info "Loading label mappings from: $filePath"
	
	$extension = [System.IO.Path]::GetExtension($filePath).ToLower()
	$mappings = @{}
	
	try {
		switch ($extension) {
			".csv" {
				# CSV Format: Address,Label,Type,Comment
				# Example: $7e0040,player_x_pos,RAM,Player X position
				$csvData = Import-Csv $filePath
				
				foreach ($row in $csvData) {
					$address = $row.Address.Trim()
					$label = $row.Label.Trim()
					
					if ($address -and $label) {
						# Normalize address format
						$normalizedAddr = Normalize-Address $address
						
						$mappings[$normalizedAddr] = @{
							Label = $label
							Type = if ($row.Type) { $row.Type.Trim() } else { "Unknown" }
							Comment = if ($row.Comment) { $row.Comment.Trim() } else { "" }
							OriginalAddress = $address
						}
					}
				}
			}
			
			".json" {
				# JSON Format:
				# {
				#   "mappings": [
				#     {"address": "$7e0040", "label": "player_x_pos", "type": "RAM", "comment": "Player X position"},
				#     ...
				#   ]
				# }
				$jsonData = Get-Content $filePath -Raw | ConvertFrom-Json
				
				foreach ($item in $jsonData.mappings) {
					$address = $item.address.Trim()
					$label = $item.label.Trim()
					
					if ($address -and $label) {
						$normalizedAddr = Normalize-Address $address
						
						$mappings[$normalizedAddr] = @{
							Label = $label
							Type = if ($item.type) { $item.type } else { "Unknown" }
							Comment = if ($item.comment) { $item.comment } else { "" }
							OriginalAddress = $address
						}
					}
				}
			}
			
			default {
				throw "Unsupported file format: $extension (use .csv or .json)"
			}
		}
		
		Write-Success "Loaded $($mappings.Count) label mappings"
		return $mappings
		
	} catch {
		Write-Error "Failed to load mappings: $_"
		throw
	}
}

function Normalize-Address {
	param([string]$address)
	
	# Remove $ prefix and convert to uppercase
	$addr = $address.TrimStart('$').ToUpper()
	
	# Pad to ensure consistent format
	# Direct page: 2 hex digits (00-FF)
	# Absolute: 4 hex digits (0000-FFFF) 
	# Long: 6 hex digits (000000-FFFFFF)
	
	if ($addr.Length -le 2) {
		# Direct page
		return $addr.PadLeft(2, '0')
	} elseif ($addr.Length -le 4) {
		# Absolute
		return $addr.PadLeft(4, '0')
	} else {
		# Long address
		return $addr.PadLeft(6, '0')
	}
}

# ============================================================================
# Address Detection and Replacement
# ============================================================================

function Get-AddressingModePatterns {
	param([string]$NormalizedAddress)
	
	# Generate regex patterns for different addressing modes
	$patterns = @()
	
	# Determine address type
	$addrLen = $NormalizedAddress.Length
	
	if ($addrLen -eq 2) {
		# Direct Page ($00-$ff)
		$hex = $NormalizedAddress
		
		# Direct: LDA $40
		$patterns += "\b(LD[AXYDS]|ST[AXYDZP]|CP[XY]|AD[CD]|SBC|AND|OR[AR]|EOR|BIT|INC|DEC|ASL|LSR|ROL|ROR|TSB|TRB)\s+\`$$hex\b"
		
		# Direct indexed: LDA $40,X
		$patterns += "\b(LD[AXYDS]|ST[AXYDZP]|CP[XY]|AD[CD]|SBC|AND|OR[AR]|EOR|BIT|INC|DEC|ASL|LSR|ROL|ROR)\s+\`$$hex\s*,\s*[XY]\b"
		
	} elseif ($addrLen -eq 4) {
		# Absolute ($0000-$ffff)
		$hex = $NormalizedAddress
		
		# Absolute: LDA $7e40 or LDA $0040
		$patterns += "\b(LD[AXYDS]|ST[AXYDZP]|CP[XY]|AD[CD]|SBC|AND|OR[AR]|EOR|BIT|INC|DEC|ASL|LSR|ROL|ROR|TSB|TRB|JMP|JSR)\s+\`$$hex\b"
		
		# Absolute indexed: LDA $7e40,X
		$patterns += "\b(LD[AXYDS]|ST[AXYDZP]|CP[XY]|AD[CD]|SBC|AND|OR[AR]|EOR|BIT|INC|DEC|ASL|LSR|ROL|ROR)\s+\`$$hex\s*,\s*[XY]\b"
		
	} elseif ($addrLen -eq 6) {
		# Long ($000000-$ffffff)
		$hex = $NormalizedAddress
		
		# Long: LDA $7e0040
		$patterns += "\b(LD[AXYDS]|ST[AXYDZP]|CP[XY]|AD[CD]|SBC|AND|OR[AR]|EOR|BIT|JMP|JSR)\s+\`$$hex\b"
		
		# Long indexed: LDA $7e0040,X
		$patterns += "\b(LD[AXYDS]|ST[AXYDZP]|CP[XY]|AD[CD]|SBC|AND|OR[AR]|EOR)\s+\`$$hex\s*,\s*[XY]\b"
	}
	
	return $patterns
}

function Apply-LabelsToFile {
	param(
		[string]$filePath,
		[hashtable]$Mappings,
		[bool]$IsDryRun
	)
	
	if (-not (Test-Path $filePath)) {
		Write-Warning "File not found: $filePath"
		return
	}
	
	Write-Info "Processing: $filePath"
	
	# Read file content
	$content = Get-Content $filePath -Raw
	$originalContent = $content
	$fileReplacements = 0
	$replacementDetails = @()
	
	# Process each label mapping
	foreach ($normalizedAddr in $Mappings.Keys) {
		$mapping = $Mappings[$normalizedAddr]
		$label = $mapping.Label
		
		# Get patterns for this address
		$patterns = Get-AddressingModePatterns $normalizedAddr
		
		foreach ($pattern in $patterns) {
			# Find all matches
			$matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
			
			if ($matches.Count -gt 0) {
				foreach ($match in $matches) {
					$originalText = $match.Value
					
					# Replace address with label while preserving instruction and indexing
					$replacement = $originalText -replace "\`$$normalizedAddr", "!$label"
					
					# For shorter addresses that might match longer ones, be more careful
					# Only replace if it's the exact address (word boundary or followed by comma/space)
					if ($originalText -ne $replacement) {
						$content = $content.Replace($originalText, $replacement)
						$fileReplacements++
						$script:replacementCount++
						
						$replacementDetails += @{
							Original = $originalText
							Replacement = $replacement
							Address = $mapping.OriginalAddress
							Label = $label
						}
						
						if ($Verbose) {
							Write-ColorOutput "    $originalText -> $replacement" "Gray"
						}
					}
				}
			}
		}
	}
	
	# Show summary for this file
	if ($fileReplacements -gt 0) {
		Write-Success "  $fileReplacements replacements in $(Split-Path $filePath -Leaf)"
		
		if ($dryRun) {
			Write-Warning "  DRY RUN - No changes written to file"
			
			# Show first few replacements as examples
			$exampleCount = [Math]::Min(5, $replacementDetails.Count)
			if ($exampleCount -gt 0) {
				Write-Info "  Example changes:"
				for ($i = 0; $i -lt $exampleCount; $i++) {
					$detail = $replacementDetails[$i]
					Write-ColorOutput "    - $($detail.Original)" "DarkGray"
					Write-ColorOutput "    + $($detail.Replacement)" "Green"
				}
				if ($replacementDetails.Count -gt $exampleCount) {
					Write-ColorOutput "    ... and $($replacementDetails.Count - $exampleCount) more" "DarkGray"
				}
			}
		} else {
			# Create backup
			$backupPath = Join-Path $backupDir (Split-Path $filePath -Leaf)
			$backupPath = $backupPath + ".bak"
			
			if (-not (Test-Path $backupDir)) {
				New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
			}
			
			Copy-Item $filePath $backupPath -Force
			Write-Info "  Backup created: $backupPath"
			
			# Write modified content
			$content | Out-File $filePath -Encoding UTF8 -NoNewline
			Write-Success "  File updated successfully"
			$script:fileCount++
		}
	} else {
		Write-ColorOutput "  No changes needed" "Gray"
	}
}

# ============================================================================
# ROM Verification
# ============================================================================

function Verify-ROMIntegrity {
	param([string]$OriginalROMPath)
	
	Write-Header "ROM VERIFICATION"
	
	# Check if asar is available
	try {
		$asarVersion = & asar --version 2>&1
		Write-Info "Asar version: $asarVersion"
	} catch {
		Write-Error "Asar not found. Cannot verify ROM."
		return $false
	}
	
	# Check if original ROM exists
	if (-not (Test-Path $OriginalROMPath)) {
		Write-Error "Original ROM not found: $OriginalROMPath"
		return $false
	}
	
	# Calculate original ROM checksum
	Write-Info "Calculating original ROM checksum..."
	$originalMD5 = (Get-FileHash $OriginalROMPath -Algorithm MD5).Hash
	Write-ColorOutput "  Original MD5: $originalMD5" "Gray"
	
	# Build ROM from modified source
	Write-Info "Building ROM from modified source..."
	
	$buildFile = "ffmq - onlygood.asm"
	if (-not (Test-Path $buildFile)) {
		Write-Error "Build file not found: $buildFile"
		return $false
	}
	
	$outputROM = "ffmq_modified.sfc"
	
	try {
		# Clean previous build
		if (Test-Path $outputROM) {
			Remove-Item $outputROM -Force
		}
		
		# Build
		$buildOutput = & asar $buildFile $outputROM 2>&1
		
		if ($LASTEXITCODE -ne 0) {
			Write-Error "Build failed:"
			Write-ColorOutput $buildOutput "Red"
			return $false
		}
		
		Write-Success "Build completed successfully"
		
	} catch {
		Write-Error "Build error: $_"
		return $false
	}
	
	# Check if output ROM was created
	if (-not (Test-Path $outputROM)) {
		Write-Error "Output ROM not created: $outputROM"
		return $false
	}
	
	# Calculate modified ROM checksum
	Write-Info "Calculating modified ROM checksum..."
	$modifiedMD5 = (Get-FileHash $outputROM -Algorithm MD5).Hash
	Write-ColorOutput "  Modified MD5: $modifiedMD5" "Gray"
	
	# Compare
	if ($originalMD5 -eq $modifiedMD5) {
		Write-Success "✓ ROM VERIFICATION PASSED - Byte-perfect match!"
		
		# Clean up
		Remove-Item $outputROM -Force
		
		return $true
	} else {
		Write-Error "✗ ROM VERIFICATION FAILED - ROMs do not match!"
		Write-Warning "Output ROM saved as: $outputROM"
		Write-Warning "Compare with original to identify differences"
		
		# Byte-by-byte comparison
		Write-Info "Attempting byte-by-byte comparison..."
		$fcOutput = & fc.exe /b $OriginalROMPath $outputROM 2>&1
		
		if ($LASTEXITCODE -ne 0) {
			# fc.exe returns non-zero when differences found
			$diffLines = $fcOutput | Select-Object -First 10
			Write-ColorOutput "First differences:" "Yellow"
			$diffLines | ForEach-Object { Write-ColorOutput "  $_" "Yellow" }
		}
		
		return $false
	}
}

# ============================================================================
# Main Execution
# ============================================================================

function Main {
	Write-Header "FFMQ LABEL APPLICATION TOOL"
	
	Write-Info "Input File: $InputFile"
	Write-Info "Mode: $(if ($dryRun) { 'DRY RUN (no changes)' } else { 'APPLY CHANGES' })"
	Write-Info "Verification: $(if ($Verify) { 'ENABLED' } else { 'DISABLED' })"
	
	# Load label mappings
	$mappings = Load-LabelMappings $InputFile
	
	if ($mappings.Count -eq 0) {
		Write-Warning "No label mappings loaded. Exiting."
		return
	}
	
	# Expand source files (handle wildcards)
	$expandedFiles = @()
	foreach ($pattern in $SourceFiles) {
		$files = Get-Item $pattern -ErrorAction SilentlyContinue
		if ($files) {
			$expandedFiles += $files
		} else {
			Write-Warning "No files match pattern: $pattern"
		}
	}
	
	if ($expandedFiles.Count -eq 0) {
		Write-Warning "No source files to process. Exiting."
		return
	}
	
	Write-Info "Processing $($expandedFiles.Count) source file(s)"
	Write-Host ""
	
	# Process each file
	foreach ($file in $expandedFiles) {
		Apply-LabelsToFile -FilePath $file.FullName -Mappings $mappings -IsDryRun $dryRun
	}
	
	# Summary
	Write-Header "SUMMARY"
	Write-Info "Total replacements: $script:replacementCount"
	Write-Info "Files modified: $(if ($dryRun) { '0 (DRY RUN)' } else { $script:fileCount })"
	
	if ($script:replacementCount -eq 0) {
		Write-Warning "No addresses were replaced. Possible reasons:"
		Write-ColorOutput "  - Addresses already labeled" "Gray"
		Write-ColorOutput "  - Address format mismatch" "Gray"
		Write-ColorOutput "  - Addresses not present in source files" "Gray"
	}
	
	# ROM verification
	if ($Verify -and -not $dryRun -and $script:replacementCount -gt 0) {
		$verifyResult = Verify-ROMIntegrity $OriginalROM
		
		if (-not $verifyResult) {
			Write-Error "ROM verification failed! Label replacements may have introduced errors."
			Write-Warning "Review backups in: $backupDir"
			exit 1
		}
	}
	
	Write-Host ""
	if ($dryRun) {
		Write-Info "DRY RUN complete. Use without -DryRun to apply changes."
	} else {
		Write-Success "Label application complete!"
		if ($script:fileCount -gt 0) {
			Write-Info "Backups saved in: $backupDir"
		}
	}
}

# Run main function
Main
