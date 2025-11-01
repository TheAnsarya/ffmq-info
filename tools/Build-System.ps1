#Requires -Version 5.1
<#
.SYNOPSIS
	Modern build system for Final Fantasy Mystic Quest SNES disassembly project.

.DESCRIPTION
	Comprehensive build orchestration system that handles:
	- ROM assembly from source files
	- Asset extraction and injection
	- Build validation and comparison
	- Progress tracking and reporting
	- Symbol generation
	- Automated testing

.PARAMETER Target
	Build target to execute. Valid options:
	- build: Assemble ROM from source
	- clean: Remove all build artifacts
	- rebuild: Clean and build
	- extract: Extract all assets from original ROM
	- validate: Validate built ROM
	- compare: Compare built ROM with original
	- symbols: Generate symbol files
	- all: Complete build pipeline

.PARAMETER Configuration
	Path to build configuration JSON file. Defaults to build.config.json

.PARAMETER Verbose
	Enable verbose output for debugging

.PARAMETER Force
	Force rebuild even if no changes detected

.EXAMPLE
	.\Build-System.ps1 -Target build
	Builds the ROM from source files

.EXAMPLE
	.\Build-System.ps1 -Target rebuild -Verbose
	Cleans and rebuilds with verbose output

.LINK
	https://github.com/TheAnsarya/ffmq-info

.NOTES
	Author: Build System Team
	Date: October 30, 2025
	Version: 2.0.0
	Requires: PowerShell 5.1+, asar assembler, Python 3.8+
#>

[CmdletBinding()]
param(
	[Parameter(Position = 0)]
	[ValidateSet('build', 'clean', 'rebuild', 'extract', 'validate', 'compare', 'symbols', 'all', 'help')]
	[string]$Target = 'build',

	[Parameter()]
	[string]$Configuration = 'build.config.json',

	[Parameter()]
	[switch]$Force
)

# Set strict mode for better error handling
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/set-strictmode
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Script metadata
$script:BuildSystemVersion = '2.0.0'
$script:BuildDate = Get-Date
$script:ScriptRoot = Split-Path -Parent $PSScriptRoot
$script:BuildConfig = $null
$script:BuildStartTime = Get-Date
$script:BuildLog = @()

#region Helper Functions

<#
.SYNOPSIS
	Writes a success message to the console.
#>
function Write-Success {
	param([string]$Message)
	Write-Host "✅ $Message" -ForegroundColor Green
}

<#
.SYNOPSIS
	Writes an error message to the console.
#>
function Write-Error {
	param([string]$Message)
	Write-Host "❌ $Message" -ForegroundColor Red
}

<#
.SYNOPSIS
	Writes an info message to the console.
#>
function Write-Info {
	param([string]$Message)
	Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

<#
.SYNOPSIS
	Writes a warning message to the console.
#>
function Write-Warning {
	param([string]$Message)
	Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

<#
.SYNOPSIS
	Writes a debug message to the console if verbose mode is enabled.
#>
function Write-DebugLog {
	param([string]$Message)
	if ($VerbosePreference -ne 'SilentlyContinue') {
		Write-Host "🔍 $Message" -ForegroundColor Gray
	}
}

<#
.SYNOPSIS
	Writes a section header to the console.
#>
function Write-Section {
	param([string]$Title)
	Write-Host ""
	Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
	Write-Host "  $Title" -ForegroundColor Magenta
	Write-Host "═══════════════════════════════════════════════════════" -ForegroundColor Magenta
	Write-Host ""
}

<#
.SYNOPSIS
	Logs a message to both console and log file.
.LINK
	https://docs.microsoft.com/en-us/powershell/scripting/learn/deep-dives/everything-about-arrays
#>
function Write-Log {
	param(
		[string]$Message,
		[ValidateSet('Info', 'Warning', 'Error', 'Success', 'Debug')]
		[string]$Level = 'Info'
	)

	# Create log entry
	$timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
	$logEntry = "[$timestamp] [$Level] $Message"

	# Add to in-memory log
	$script:BuildLog += $logEntry

	# Write to console based on level
	switch ($Level) {
		'Success' { Write-Success $Message }
		'Error' { Write-Error $Message }
		'Warning' { Write-Warning $Message }
		'Info' { Write-Info $Message }
		'Debug' { Write-DebugLog $Message }
	}
}

<#
.SYNOPSIS
	Loads the build configuration from JSON file.
.LINK
	https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/convertfrom-json
#>
function Get-BuildConfiguration {
	param([string]$ConfigPath)

	Write-DebugLog "Loading configuration from: $ConfigPath"

	# Resolve path relative to script root
	$fullPath = Join-Path $script:ScriptRoot $ConfigPath

	if (-not (Test-Path $fullPath)) {
		throw "Configuration file not found: $fullPath"
	}

	try {
		$config = Get-Content $fullPath -Raw | ConvertFrom-Json
		Write-DebugLog "Configuration loaded successfully"
		return $config
	}
	catch {
		throw "Failed to load configuration: $_"
	}
}

<#
.SYNOPSIS
	Finds a tool executable in configured search paths.
.LINK
	https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-command
#>
function Find-Tool {
	param(
		[string]$Name,
		[string]$Executable,
		[string[]]$SearchPaths
	)

	Write-DebugLog "Searching for $Name ($Executable)..."

	# First check if it's in PATH
	$pathTool = Get-Command $Executable -ErrorAction SilentlyContinue
	if ($pathTool) {
		Write-DebugLog "Found $Name in PATH: $($pathTool.Source)"
		return $pathTool.Source
	}

	# Search in configured paths
	foreach ($searchPath in $SearchPaths) {
		$fullPath = Join-Path $script:ScriptRoot $searchPath
		$toolPath = Join-Path $fullPath $Executable

		Write-DebugLog "Checking: $toolPath"

		if (Test-Path $toolPath) {
			Write-DebugLog "Found $Name at: $toolPath"
			return $toolPath
		}
	}

	return $null
}

<#
.SYNOPSIS
	Validates that all required tools are available.
#>
function Test-RequiredTools {
	Write-Log "Validating required tools..." -Level Info

	$allToolsFound = $true

	# Check assembler (asar)
	$asarPath = Find-Tool `
		-Name $script:BuildConfig.tools.assembler.name `
		-Executable $script:BuildConfig.tools.assembler.executable `
		-SearchPaths $script:BuildConfig.tools.assembler.searchPaths

	if ($asarPath) {
		Write-Success "Found asar: $asarPath"
		$script:AsarPath = $asarPath
	}
	else {
		Write-Error "asar assembler not found!"
		Write-Warning "Download from: $($script:BuildConfig.tools.assembler.downloadUrl)"
		$allToolsFound = $false
	}

	# Check Python
	$pythonPath = Get-Command $script:BuildConfig.tools.python.executable -ErrorAction SilentlyContinue
	if ($pythonPath) {
		$pythonVersion = & $pythonPath --version 2>&1
		Write-Success "Found Python: $pythonVersion"
		$script:PythonPath = $pythonPath.Source
	}
	else {
		Write-Error "Python not found!"
		Write-Warning "Install Python $($script:BuildConfig.tools.python.version) or later"
		$allToolsFound = $false
	}

	if (-not $allToolsFound) {
		throw "Required tools missing. Please install missing tools and try again."
	}

	Write-Success "All required tools found"
}

<#
.SYNOPSIS
	Ensures all required directories exist.
.LINK
	https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/new-item
#>
function Initialize-Directories {
	Write-Log "Initializing directories..." -Level Info

	$directories = @(
		$script:BuildConfig.paths.base.build,
		$script:BuildConfig.paths.base.assets,
		$script:BuildConfig.paths.base.data,
		$script:BuildConfig.paths.assets.graphics,
		$script:BuildConfig.paths.assets.text,
		$script:BuildConfig.paths.assets.music,
		$script:BuildConfig.paths.assets.data
	)

	foreach ($dir in $directories) {
		$fullPath = Join-Path $script:ScriptRoot $dir
		if (-not (Test-Path $fullPath)) {
			Write-DebugLog "Creating directory: $fullPath"
			New-Item -ItemType Directory -Path $fullPath -Force | Out-Null
		}
	}

	Write-Success "Directories initialized"
}

#endregion

#region Build Functions

<#
.SYNOPSIS
	Cleans all build artifacts.
#>
function Invoke-Clean {
	Write-Section "Cleaning Build Artifacts"

	$buildPath = Join-Path $script:ScriptRoot $script:BuildConfig.paths.base.build

	if (Test-Path $buildPath) {
		Write-Log "Removing build directory: $buildPath" -Level Info
		Remove-Item "$buildPath\*" -Recurse -Force -ErrorAction SilentlyContinue
		Write-Success "Build artifacts cleaned"
	}
	else {
		Write-Info "Build directory does not exist, nothing to clean"
	}
}

<#
.SYNOPSIS
	Assembles the ROM from source files.
.LINK
	https://github.com/RPGHacker/asar - Asar assembler documentation
#>
function Invoke-Build {
	Write-Section "Building ROM from Source"

	# Ensure directories exist
	Initialize-Directories

	# Resolve paths
	$sourcePath = Join-Path $script:ScriptRoot $script:BuildConfig.build.mainSource
	$outputPath = Join-Path $script:ScriptRoot $script:BuildConfig.build.outputRom

	# Validate source file exists
	if (-not (Test-Path $sourcePath)) {
		throw "Source file not found: $sourcePath"
	}

	Write-Info "Source: $sourcePath"
	Write-Info "Output: $outputPath"
	Write-Host ""

	# Build asar arguments
	$asarArgs = @()

	if ($Verbose -or $script:BuildConfig.build.options.verbose) {
		$asarArgs += '-v'
	}

	if ($script:BuildConfig.build.options.generateSymbols) {
		$symbolPath = Join-Path $script:ScriptRoot $script:BuildConfig.build.symbolFile
		$asarArgs += '--symbols=wla'
		$asarArgs += $symbolPath
		Write-Info "Symbols: $symbolPath"
	}

	$asarArgs += $sourcePath
	$asarArgs += $outputPath

	# Execute assembler
	Write-Info "Assembling ROM..."
	Write-DebugLog "Command: $script:AsarPath $($asarArgs -join ' ')"

	$buildStart = Get-Date

	try {
		& $script:AsarPath @asarArgs
		$exitCode = $LASTEXITCODE
	}
	catch {
		throw "Assembly failed with exception: $_"
	}

	$buildEnd = Get-Date
	$buildTime = ($buildEnd - $buildStart).TotalSeconds

	Write-Host ""

	if ($exitCode -eq 0) {
		Write-Success "Assembly completed in $([math]::Round($buildTime, 2)) seconds"
		Write-Host ""

		# Validate output
		if (Test-Path $outputPath) {
			$fileInfo = Get-Item $outputPath
			$fileSize = $fileInfo.Length

			Write-Info "Output file: $outputPath"
			Write-Info "File size: $fileSize bytes"

			# Check size
			if ($script:BuildConfig.build.options.checkSize) {
				$expectedSize = $script:BuildConfig.build.expectedSize

				if ($fileSize -eq $expectedSize) {
					Write-Success "File size matches expected $expectedSize bytes"
				}
				else {
					Write-Warning "File size is $fileSize bytes (expected $expectedSize)"
				}
			}

			Write-Success "Build complete!"
		}
		else {
			throw "Output file was not created!"
		}
	}
	else {
		throw "Assembly failed with exit code $exitCode"
	}
}

<#
.SYNOPSIS
	Validates the built ROM.
#>
function Invoke-Validate {
	Write-Section "Validating Built ROM"

	$outputPath = Join-Path $script:ScriptRoot $script:BuildConfig.build.outputRom

	if (-not (Test-Path $outputPath)) {
		throw "Built ROM not found: $outputPath. Run 'build' first."
	}

	$fileInfo = Get-Item $outputPath
	$fileSize = $fileInfo.Length

	Write-Info "ROM: $outputPath"
	Write-Info "Size: $fileSize bytes"
	Write-Host ""

	# Validate size
	if ($script:BuildConfig.validation.size.enabled) {
		$expectedSize = $script:BuildConfig.validation.size.expected
		$tolerance = $script:BuildConfig.validation.size.tolerance

		if ($fileSize -ge ($expectedSize - $tolerance) -and $fileSize -le ($expectedSize + $tolerance)) {
			Write-Success "Size validation passed ($fileSize bytes)"
		}
		else {
			Write-Error "Size validation failed! Expected $expectedSize ± $tolerance, got $fileSize"
			throw "Size validation failed"
		}
	}

	# Calculate checksum
	if ($script:BuildConfig.validation.checksum.enabled) {
		Write-Info "Calculating checksum..."
		$algorithm = $script:BuildConfig.validation.checksum.algorithm
		$hash = Get-FileHash $outputPath -Algorithm $algorithm

		Write-Info "$($algorithm.ToUpper()): $($hash.Hash.ToLower())"
	}

	Write-Success "Validation complete!"
}

<#
.SYNOPSIS
	Compares built ROM with original ROM.
#>
function Invoke-Compare {
	Write-Section "Comparing ROMs"

	$outputPath = Join-Path $script:ScriptRoot $script:BuildConfig.build.outputRom
	$originalPath = Join-Path $script:ScriptRoot $script:BuildConfig.paths.roms.original

	if (-not (Test-Path $outputPath)) {
		throw "Built ROM not found: $outputPath. Run 'build' first."
	}

	if (-not (Test-Path $originalPath)) {
		throw "Original ROM not found: $originalPath"
	}

	Write-Info "Built ROM:    $outputPath"
	Write-Info "Original ROM: $originalPath"
	Write-Host ""

	# Calculate hashes
	Write-Info "Calculating checksums..."
	$builtHash = Get-FileHash $outputPath -Algorithm SHA256
	$originalHash = Get-FileHash $originalPath -Algorithm SHA256

	Write-Info "Built:    $($builtHash.Hash.ToLower())"
	Write-Info "Original: $($originalHash.Hash.ToLower())"
	Write-Host ""

	if ($builtHash.Hash -eq $originalHash.Hash) {
		Write-Success "✨ PERFECT MATCH! ROM is byte-for-byte identical!"
	}
	else {
		Write-Warning "ROM differs from original"

		# Use Python comparison tool if available
		$compareTool = Join-Path $script:ScriptRoot "tools\rom_compare.py"
		if (Test-Path $compareTool) {
			Write-Info "Running detailed comparison..."
			& $script:PythonPath $compareTool $originalPath $outputPath
		}
	}
}

<#
.SYNOPSIS
	Extracts all assets from original ROM.
#>
function Invoke-Extract {
	Write-Section "Extracting Assets from ROM"

	$originalPath = Join-Path $script:ScriptRoot $script:BuildConfig.paths.roms.original

	if (-not (Test-Path $originalPath)) {
		throw "Original ROM not found: $originalPath"
	}

	Initialize-Directories

	# Extract graphics
	if ($script:BuildConfig.extraction.graphics.enabled) {
		Write-Info "Extracting graphics..."
		$extractTool = Join-Path $script:ScriptRoot "tools\extract_graphics_v2.py"
		$graphicsPath = Join-Path $script:ScriptRoot $script:BuildConfig.paths.assets.graphics

		if (Test-Path $extractTool) {
			& $script:PythonPath $extractTool $originalPath $graphicsPath --docs
			Write-Success "Graphics extracted"
		}
		else {
			Write-Warning "Graphics extraction tool not found: $extractTool"
		}
	}

	# Extract text
	if ($script:BuildConfig.extraction.text.enabled) {
		Write-Info "Extracting text..."
		$extractTool = Join-Path $script:ScriptRoot "tools\extract_text.py"
		$textPath = Join-Path $script:ScriptRoot $script:BuildConfig.paths.assets.text

		if (Test-Path $extractTool) {
			& $script:PythonPath $extractTool $originalPath $textPath
			Write-Success "Text extracted"
		}
		else {
			Write-Warning "Text extraction tool not found: $extractTool"
		}
	}

	# Extract music
	if ($script:BuildConfig.extraction.music.enabled) {
		Write-Info "Extracting music..."
		$extractTool = Join-Path $script:ScriptRoot "tools\extract_music.py"
		$musicPath = Join-Path $script:ScriptRoot $script:BuildConfig.paths.assets.music

		if (Test-Path $extractTool) {
			& $script:PythonPath $extractTool $originalPath $musicPath
			Write-Success "Music extracted"
		}
		else {
			Write-Warning "Music extraction tool not found: $extractTool"
		}
	}

	Write-Success "Asset extraction complete!"
}

<#
.SYNOPSIS
	Generates symbol files from built ROM.
#>
function Invoke-GenerateSymbols {
	Write-Section "Generating Symbol Files"

	# Symbols are generated during build if enabled in config
	if ($script:BuildConfig.build.options.generateSymbols) {
		Write-Info "Symbols are generated automatically during build"
		Write-Info "Symbol file: $($script:BuildConfig.build.symbolFile)"
	}
	else {
		Write-Warning "Symbol generation is disabled in configuration"
		Write-Info "Enable 'build.options.generateSymbols' in build.config.json"
	}
}

<#
.SYNOPSIS
	Executes complete build pipeline.
#>
function Invoke-All {
	Write-Section "Complete Build Pipeline"

	Invoke-Clean
	Invoke-Build
	Invoke-Validate
	Invoke-Compare

	Write-Section "Pipeline Complete"

	$totalTime = ((Get-Date) - $script:BuildStartTime).TotalSeconds
	Write-Success "Total time: $([math]::Round($totalTime, 2)) seconds"
}

#endregion

#region Main Execution

<#
.SYNOPSIS
	Displays help information.
#>
function Show-Help {
	Write-Section "FFMQ Build System v$script:BuildSystemVersion"

	Write-Host "Usage: .\Build-System.ps1 -Target <target> [options]" -ForegroundColor White
	Write-Host ""
	Write-Host "Targets:" -ForegroundColor Cyan
	Write-Host "  build      - Build ROM from source" -ForegroundColor White
	Write-Host "  clean      - Remove build artifacts" -ForegroundColor White
	Write-Host "  rebuild    - Clean and build" -ForegroundColor White
	Write-Host "  extract    - Extract assets from original ROM" -ForegroundColor White
	Write-Host "  validate   - Validate built ROM" -ForegroundColor White
	Write-Host "  compare    - Compare built ROM with original" -ForegroundColor White
	Write-Host "  symbols    - Generate symbol files" -ForegroundColor White
	Write-Host "  all        - Complete build pipeline" -ForegroundColor White
	Write-Host "  help       - Show this help" -ForegroundColor White
	Write-Host ""
	Write-Host "Options:" -ForegroundColor Cyan
	Write-Host "  -Verbose   - Enable verbose output" -ForegroundColor White
	Write-Host "  -Force     - Force rebuild" -ForegroundColor White
	Write-Host ""
	Write-Host "Examples:" -ForegroundColor Cyan
	Write-Host "  .\Build-System.ps1 -Target build" -ForegroundColor White
	Write-Host "  .\Build-System.ps1 -Target rebuild -Verbose" -ForegroundColor White
	Write-Host "  .\Build-System.ps1 -Target all" -ForegroundColor White
	Write-Host ""
}

# Main entry point
try {
	Write-Section "FFMQ Build System v$script:BuildSystemVersion"

	if ($Target -eq 'help') {
		Show-Help
		exit 0
	}

	# Load configuration
	$script:BuildConfig = Get-BuildConfiguration -ConfigPath $Configuration
	Write-Success "Configuration loaded: $Configuration"

	# Validate tools
	Test-RequiredTools

	# Execute target
	switch ($Target) {
		'build' { Invoke-Build }
		'clean' { Invoke-Clean }
		'rebuild' {
			Invoke-Clean
			Invoke-Build
		}
		'extract' { Invoke-Extract }
		'validate' { Invoke-Validate }
		'compare' { Invoke-Compare }
		'symbols' { Invoke-GenerateSymbols }
		'all' { Invoke-All }
	}

	# Save build log
	$logPath = Join-Path $script:ScriptRoot $script:BuildConfig.logging.file
	$logDir = Split-Path $logPath -Parent
	if (-not (Test-Path $logDir)) {
		New-Item -ItemType Directory -Path $logDir -Force | Out-Null
	}
	$script:BuildLog | Out-File $logPath -Encoding UTF8

	Write-Host ""
	Write-Success "Build system completed successfully!"

	$totalTime = ((Get-Date) - $script:BuildStartTime).TotalSeconds
	Write-Info "Total time: $([math]::Round($totalTime, 2)) seconds"
	Write-Host ""
}
catch {
	Write-Host ""
	Write-Error "Build system failed: $_"
	Write-Host ""
	Write-Host "Stack trace:" -ForegroundColor Red
	Write-Host $_.ScriptStackTrace -ForegroundColor Gray
	Write-Host ""
	exit 1
}

#endregion

