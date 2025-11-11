<#
.SYNOPSIS
	FFMQ ROM Hacking Task Runner

.DESCRIPTION
	Provides easy access to common ROM hacking tasks

.PARAMETER Task
	The task to run. Use -Task help to see all available tasks.

.EXAMPLE
	.\ffmq-tasks.ps1 -Task help
	.\ffmq-tasks.ps1 -Task dialog-list
	.\ffmq-tasks.ps1 -Task extract-text
	.\ffmq-tasks.ps1 -Task backup
#>

param(
	[Parameter(Position=0)]
	[string]$Task = "help",

	[Parameter(Position=1)]
	[string]$Arg = ""
)

$RomPath = "roms\FFMQ.sfc"
$ToolsDir = "tools"

function Show-Help {
	Write-Host "FFMQ ROM Hacking - Available Tasks" -ForegroundColor Cyan
	Write-Host ""
	Write-Host "Dialog Tasks:" -ForegroundColor Yellow
	Write-Host "  dialog-list      - List all 116 dialogs"
	Write-Host "  dialog-stats     - Show dialog statistics"
	Write-Host "  dialog-validate  - Validate all dialogs"
	Write-Host "  dialog-fix       - Auto-fix dialog issues"
	Write-Host "  dialog-export    - Export dialogs to JSON"
	Write-Host "  dialog-import    - Import dialogs from JSON"
	Write-Host ""
	Write-Host "Text Tasks:" -ForegroundColor Yellow
	Write-Host "  extract-text     - Extract all text from ROM"
	Write-Host "  import-text      - Import text back to ROM"
	Write-Host "  text-stats       - Show text statistics"
	Write-Host ""
	Write-Host "Analysis Tasks:" -ForegroundColor Yellow
	Write-Host "  analyze-dte      - Analyze DTE compression"
	Write-Host "  check-overflow   - Check for text overflow"
	Write-Host ""
	Write-Host "Safety Tasks:" -ForegroundColor Yellow
	Write-Host "  backup           - Create ROM backup"
	Write-Host "  restore          - List and restore backups"
	Write-Host ""
	Write-Host "Build Tasks:" -ForegroundColor Yellow
	Write-Host "  build            - Build ROM from source"
	Write-Host "  test             - Test ROM in emulator"
	Write-Host "  clean            - Clean build artifacts"
	Write-Host ""
	Write-Host "Quick Commands:" -ForegroundColor Yellow
	Write-Host "  edit <id>        - Edit dialog by ID (e.g., edit 5)"
	Write-Host "  show <id>        - Show dialog by ID"
	Write-Host "  search <text>    - Search for text in dialogs"
	Write-Host ""
	Write-Host "Enemy Tasks:" -ForegroundColor Yellow
	Write-Host "  enemy-edit       - Open enemy editor GUI"
	Write-Host ""
	Write-Host "Info Tasks:" -ForegroundColor Yellow
	Write-Host "  info             - Show project information"
	Write-Host "  git-status       - Show git status"
	Write-Host ""
	Write-Host "Usage: .\ffmq-tasks.ps1 -Task <task> [-Arg <argument>]" -ForegroundColor Green
}

function Invoke-DialogList {
	Push-Location "$ToolsDir\map-editor"
	python dialog_cli.py list
	Pop-Location
}

function Invoke-DialogStats {
	Push-Location "$ToolsDir\map-editor"
	python dialog_cli.py stats
	Pop-Location
}

function Invoke-DialogValidate {
	Push-Location "$ToolsDir\map-editor"
	python dialog_cli.py validate
	Pop-Location
}

function Invoke-DialogFix {
	Push-Location "$ToolsDir\map-editor"
	python dialog_cli.py validate --fix
	Pop-Location
}

function Invoke-DialogExport {
	$date = Get-Date -Format "yyyyMMdd"
	$output = "data\dialogs_$date.json"
	Push-Location "$ToolsDir\map-editor"
	python dialog_cli.py export "..\..\$output"
	Pop-Location
	Write-Host "✓ Exported to $output" -ForegroundColor Green
}

function Invoke-DialogImport {
	$input = "data\dialogs.json"
	if (-not (Test-Path $input)) {
		Write-Host "ERROR: $input not found" -ForegroundColor Red
		return
	}
	Push-Location "$ToolsDir\map-editor"
	python dialog_cli.py import "..\..\$input"
	Pop-Location
}

function Invoke-ExtractText {
	Push-Location "$ToolsDir\extraction"
	python extract_all_text.py "..\..\$RomPath" --output-dir "..\..\data\text"
	Pop-Location
}

function Invoke-ImportText {
	Push-Location "$ToolsDir\import"
	python import_all_text.py "..\..\data\text\text_data.json" "..\..\roms\FFMQ_modified.sfc"
	Pop-Location
}

function Invoke-TextStats {
	$statsFile = "data\text\text_statistics.txt"
	if (Test-Path $statsFile) {
		Get-Content $statsFile
	} else {
		Write-Host "No statistics found. Run: .\ffmq-tasks.ps1 -Task extract-text" -ForegroundColor Yellow
	}
}

function Invoke-AnalyzeDTE {
	Push-Location "$ToolsDir\map-editor"
	python compression_optimizer.py
	Pop-Location
}

function Invoke-CheckOverflow {
	Push-Location "$ToolsDir\map-editor"
	python text_overflow_detector.py
	Pop-Location
}

function Invoke-Backup {
	Push-Location "$ToolsDir\map-editor"
	python dialog_cli.py backup
	Pop-Location
}

function Invoke-Restore {
	Write-Host "Available backups:" -ForegroundColor Cyan
	Get-ChildItem "roms\*backup*.sfc" -ErrorAction SilentlyContinue | ForEach-Object {
		Write-Host "  $($_.Name)" -ForegroundColor Yellow
	}
	Write-Host ""
	Write-Host "To restore, run:" -ForegroundColor Green
	Write-Host "  cd tools\map-editor" -ForegroundColor Gray
	Write-Host "  python dialog_cli.py restore ..\..\roms\<backup_file>" -ForegroundColor Gray
}

function Invoke-Build {
	.\build.ps1
}

function Invoke-Test {
	if (Test-Path "build\ffmq-rebuilt.sfc") {
		if (Get-Command mesen -ErrorAction SilentlyContinue) {
			mesen "build\ffmq-rebuilt.sfc"
		} else {
			Write-Host "MesenS emulator not found in PATH" -ForegroundColor Yellow
			Write-Host "Install from: https://github.com/SourMesen/Mesen-S" -ForegroundColor Cyan
		}
	} else {
		Write-Host "No ROM found. Run: .\ffmq-tasks.ps1 -Task build" -ForegroundColor Yellow
	}
}

function Invoke-Clean {
	Write-Host "Cleaning build artifacts..." -ForegroundColor Cyan
	Remove-Item "build\*.sfc", "build\*.log", "build\*.sym" -ErrorAction SilentlyContinue
	Write-Host "✓ Done!" -ForegroundColor Green
}

function Invoke-Edit {
	param([string]$Id)
	if ($Id -eq "") {
		Write-Host "ERROR: Dialog ID required. Usage: edit <id>" -ForegroundColor Red
		return
	}
	Push-Location "$ToolsDir\map-editor"
	python dialog_cli.py edit $Id
	Pop-Location
}

function Invoke-Show {
	param([string]$Id)
	if ($Id -eq "") {
		Write-Host "ERROR: Dialog ID required. Usage: show <id>" -ForegroundColor Red
		return
	}
	Push-Location "$ToolsDir\map-editor"
	python dialog_cli.py show $Id
	Pop-Location
}

function Invoke-Search {
	param([string]$Text)
	if ($Text -eq "") {
		Write-Host "ERROR: Search text required. Usage: search <text>" -ForegroundColor Red
		return
	}
	Push-Location "$ToolsDir\map-editor"
	python dialog_cli.py search "$Text"
	Pop-Location
}

function Invoke-EnemyEdit {
	Push-Location "$ToolsDir\map-editor"
	python enemy_editor.py
	Pop-Location
}

function Show-Info {
	Write-Host "FFMQ ROM Hacking Project Information" -ForegroundColor Cyan
	Write-Host "======================================" -ForegroundColor Cyan
	Write-Host ""

	Write-Host "ROM File: " -NoNewline
	Write-Host $RomPath -ForegroundColor Yellow

	if (Test-Path $RomPath) {
		$size = (Get-Item $RomPath).Length
		Write-Host "ROM Status: " -NoNewline
		Write-Host "FOUND ($size bytes)" -ForegroundColor Green
	} else {
		Write-Host "ROM Status: " -NoNewline
		Write-Host "NOT FOUND" -ForegroundColor Red
	}

	Write-Host ""
	Write-Host "Dialogs: " -NoNewline
	Write-Host "116 total" -ForegroundColor Cyan
	Write-Host "Control Codes: " -NoNewline
	Write-Host "77 mapped" -ForegroundColor Cyan
	Write-Host "DTE Sequences: " -NoNewline
	Write-Host "116 compressed" -ForegroundColor Cyan
	Write-Host "Compression Ratio: " -NoNewline
	Write-Host "~57.9%" -ForegroundColor Cyan

	Write-Host ""
	Write-Host "Tools Available:" -ForegroundColor Yellow
	Write-Host "  • Dialog CLI (15 commands)"
	Write-Host "  • Text Extraction"
	Write-Host "  • Text Import"
	Write-Host "  • Compression Optimizer"
	Write-Host "  • Overflow Detector"
	Write-Host "  • Enemy Editor"

	Write-Host ""
	Write-Host "Documentation:" -ForegroundColor Yellow
	Write-Host "  • README.md"
	Write-Host "  • docs\DIALOG_COMMANDS.md"
	Write-Host "  • tools\map-editor\COMMAND_REFERENCE.md"
	Write-Host "  • tools\map-editor\QUICK_REFERENCE.md"
}

function Show-GitStatus {
	git status --short
}

# Main task router
switch ($Task.ToLower()) {
	"help" { Show-Help }
	"dialog-list" { Invoke-DialogList }
	"dialog-stats" { Invoke-DialogStats }
	"dialog-validate" { Invoke-DialogValidate }
	"dialog-fix" { Invoke-DialogFix }
	"dialog-export" { Invoke-DialogExport }
	"dialog-import" { Invoke-DialogImport }
	"extract-text" { Invoke-ExtractText }
	"import-text" { Invoke-ImportText }
	"text-stats" { Invoke-TextStats }
	"analyze-dte" { Invoke-AnalyzeDTE }
	"check-overflow" { Invoke-CheckOverflow }
	"backup" { Invoke-Backup }
	"restore" { Invoke-Restore }
	"build" { Invoke-Build }
	"test" { Invoke-Test }
	"clean" { Invoke-Clean }
	"edit" { Invoke-Edit -Id $Arg }
	"show" { Invoke-Show -Id $Arg }
	"search" { Invoke-Search -Text $Arg }
	"enemy-edit" { Invoke-EnemyEdit }
	"info" { Show-Info }
	"git-status" { Show-GitStatus }
	default {
		Write-Host "Unknown task: $Task" -ForegroundColor Red
		Write-Host ""
		Show-Help
	}
}
