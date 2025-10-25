# Chat Log Helper - Quick Updates
# Easy-to-use wrapper for updating chat logs during development

param(
	[Parameter(Mandatory=$false)]
	[string]$Type,
	
	[Parameter(Mandatory=$false)]
	[string]$Message,
	
	[Parameter(Mandatory=$false)]
	[string[]]$Files,
	
	[Parameter(Mandatory=$false)]
	[string]$Answer
)

# Get project root
$ProjectRoot = Split-Path -Parent $PSScriptRoot

# Path to updater script
$UpdaterScript = Join-Path $ProjectRoot "tools\update_chat_log.py"

# Display help if no parameters
if (-not $Type) {
	Write-Host "FFMQ Chat Log Helper" -ForegroundColor Cyan
	Write-Host "=====================" -ForegroundColor Cyan
	Write-Host ""
	Write-Host "Usage:" -ForegroundColor Yellow
	Write-Host "  .\log.ps1 -Type commit -Message 'commit message'"
	Write-Host "  .\log.ps1 -Type change -Message 'what changed' -Files file1.py,file2.s"
	Write-Host "  .\log.ps1 -Type question -Message 'question' -Answer 'answer'"
	Write-Host "  .\log.ps1 -Type summary"
	Write-Host ""
	Write-Host "Examples:" -ForegroundColor Yellow
	Write-Host "  .\log.ps1 -Type change -Message 'Fixed tile extraction bug'"
	Write-Host "  .\log.ps1 -Type question -Message 'How does 4BPP encoding work?'"
	Write-Host "  .\log.ps1 -Type summary"
	Write-Host ""
	exit 0
}

# Build command based on type
$CommandArgs = @($UpdaterScript)

switch ($Type.ToLower()) {
	"commit" {
		if (-not $Message) {
			Write-Host "Error: Commit requires -Message parameter" -ForegroundColor Red
			exit 1
		}
		$CommandArgs += "--commit"
		$CommandArgs += $Message
		if ($Files) {
			$CommandArgs += "--files"
			$CommandArgs += $Files
		}
	}
	
	"change" {
		if (-not $Message) {
			Write-Host "Error: Change requires -Message parameter" -ForegroundColor Red
			exit 1
		}
		$CommandArgs += "--change"
		$CommandArgs += $Message
		if ($Files) {
			$CommandArgs += "--files"
			$CommandArgs += $Files
		}
	}
	
	"question" {
		if (-not $Message) {
			Write-Host "Error: Question requires -Message parameter" -ForegroundColor Red
			exit 1
		}
		$CommandArgs += "--question"
		$CommandArgs += $Message
		if ($Answer) {
			$CommandArgs += "--answer"
			$CommandArgs += $Answer
		}
	}
	
	"summary" {
		$CommandArgs += "--summary"
	}
	
	default {
		Write-Host "Error: Unknown type '$Type'" -ForegroundColor Red
		Write-Host "Valid types: commit, change, question, summary" -ForegroundColor Yellow
		exit 1
	}
}

# Run the updater
try {
	& python @CommandArgs
} catch {
	Write-Host "Error running chat log updater: $_" -ForegroundColor Red
	exit 1
}
