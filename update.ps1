# FFMQ Development - Continuous Chat Log Monitor
# Monitors file changes and prompts for chat log updates

param(
	[Parameter(Mandatory=$false)]
	[switch]$Monitor,
	
	[Parameter(Mandatory=$false)]
	[switch]$QuickLog
)

# Get project root
$ProjectRoot = Split-Path -Parent $PSScriptRoot

# Colors for output
$ColorInfo = "Cyan"
$ColorSuccess = "Green"
$ColorWarning = "Yellow"
$ColorPrompt = "Magenta"

function Show-Banner {
	Write-Host ""
	Write-Host "╔══════════════════════════════════════════════╗" -ForegroundColor $ColorInfo
	Write-Host "║   FFMQ Chat Log - Continuous Update System  ║" -ForegroundColor $ColorInfo
	Write-Host "╚══════════════════════════════════════════════╝" -ForegroundColor $ColorInfo
	Write-Host ""
}

function Get-GitStatus {
	"""
	Get current git status including modified files.
	
	Returns hashtable with git information for logging purposes.
	Reference: https://git-scm.com/docs/git-status
	"""
	try {
		$Status = git status --short 2>$null
		$ModifiedFiles = @()
		$AddedFiles = @()
		$DeletedFiles = @()
		
		if ($Status) {
			foreach ($Line in $Status) {
				$StatusCode = $Line.Substring(0, 2).Trim()
				$File = $Line.Substring(3)
				
				switch -Regex ($StatusCode) {
					'^M' { $ModifiedFiles += $File }
					'^A' { $AddedFiles += $File }
					'^D' { $DeletedFiles += $File }
					'M$' { $ModifiedFiles += $File }
				}
			}
		}
		
		return @{
			HasChanges = ($ModifiedFiles.Count -gt 0 -or $AddedFiles.Count -gt 0 -or $DeletedFiles.Count -gt 0)
			Modified = $ModifiedFiles
			Added = $AddedFiles
			Deleted = $DeletedFiles
			Total = $ModifiedFiles.Count + $AddedFiles.Count + $DeletedFiles.Count
		}
	} catch {
		return @{
			HasChanges = $false
			Modified = @()
			Added = @()
			Deleted = @()
			Total = 0
		}
	}
}

function Prompt-ForUpdate {
	"""
	Prompt user to log what they're working on.
	
	This ensures chat logs are always updated with current work,
	not just when committing. Provides quick logging interface.
	"""
	Show-Banner
	
	$GitStatus = Get-GitStatus
	
	# Show current changes
	if ($GitStatus.HasChanges) {
		Write-Host "📝 You have $($GitStatus.Total) file(s) with changes:" -ForegroundColor $ColorWarning
		
		if ($GitStatus.Modified.Count -gt 0) {
			Write-Host "   Modified:" -ForegroundColor $ColorWarning
			$GitStatus.Modified | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
		}
		
		if ($GitStatus.Added.Count -gt 0) {
			Write-Host "   Added:" -ForegroundColor $ColorSuccess
			$GitStatus.Added | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
		}
		
		if ($GitStatus.Deleted.Count -gt 0) {
			Write-Host "   Deleted:" -ForegroundColor "Red"
			$GitStatus.Deleted | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
		}
		
		Write-Host ""
	} else {
		Write-Host "✓ No uncommitted changes detected" -ForegroundColor $ColorSuccess
		Write-Host ""
	}
	
	# Quick log menu
	Write-Host "What would you like to log?" -ForegroundColor $ColorPrompt
	Write-Host ""
	Write-Host "  1) 💡 Change/Update - Log what you just changed" -ForegroundColor $ColorInfo
	Write-Host "  2) ❓ Question - Log a question you have" -ForegroundColor $ColorInfo
	Write-Host "  3) 💭 Note - Log a thought or decision" -ForegroundColor $ColorInfo
	Write-Host "  4) 📊 Summary - View today's activity" -ForegroundColor $ColorInfo
	Write-Host "  5) ⏭️  Skip - Continue without logging" -ForegroundColor Gray
	Write-Host ""
	
	$Choice = Read-Host "Enter choice (1-5)"
	
	switch ($Choice) {
		"1" {
			# Log a change
			Write-Host ""
			$Description = Read-Host "Describe what you changed"
			
			if ($Description) {
				$AllFiles = $GitStatus.Modified + $GitStatus.Added + $GitStatus.Deleted
				
				if ($AllFiles.Count -gt 0) {
					& python "$ProjectRoot\tools\update_chat_log.py" --change $Description --files $AllFiles
				} else {
					& python "$ProjectRoot\tools\update_chat_log.py" --change $Description
				}
				
				Write-Host ""
				Write-Host "✓ Change logged successfully!" -ForegroundColor $ColorSuccess
			}
		}
		
		"2" {
			# Log a question
			Write-Host ""
			$Question = Read-Host "What's your question"
			
			if ($Question) {
				$Answer = Read-Host "Answer (optional, press Enter to skip)"
				
				if ($Answer) {
					& python "$ProjectRoot\tools\update_chat_log.py" --question $Question --answer $Answer
				} else {
					& python "$ProjectRoot\tools\update_chat_log.py" --question $Question
				}
				
				Write-Host ""
				Write-Host "✓ Question logged successfully!" -ForegroundColor $ColorSuccess
			}
		}
		
		"3" {
			# Log a note/decision
			Write-Host ""
			$Note = Read-Host "What's the note or decision"
			
			if ($Note) {
				& python "$ProjectRoot\tools\update_chat_log.py" --change "Note: $Note"
				
				Write-Host ""
				Write-Host "✓ Note logged successfully!" -ForegroundColor $ColorSuccess
			}
		}
		
		"4" {
			# Show summary
			Write-Host ""
			& python "$ProjectRoot\tools\update_chat_log.py" --summary
		}
		
		"5" {
			# Skip
			Write-Host ""
			Write-Host "Skipped logging. Remember to log your work!" -ForegroundColor $ColorWarning
		}
		
		default {
			Write-Host ""
			Write-Host "Invalid choice. Skipped logging." -ForegroundColor "Red"
		}
	}
	
	Write-Host ""
	Write-Host "💡 Tip: Run '.\update.ps1' anytime to log your work!" -ForegroundColor $ColorInfo
	Write-Host ""
}

function Start-FileMonitor {
	"""
	Monitor source files for changes and prompt for logging.
	
	Watches for file modifications and reminds developer to log changes.
	This ensures chat logs are always up-to-date with current work.
	Reference: https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_file_system_provider
	"""
	Write-Host "Starting file monitor..." -ForegroundColor $ColorInfo
	Write-Host "Watching for changes in source files..." -ForegroundColor $ColorInfo
	Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor $ColorWarning
	Write-Host ""
	
	$LastCheck = Get-Date
	$CheckInterval = 300  # Check every 5 minutes
	
	while ($true) {
		Start-Sleep -Seconds $CheckInterval
		
		$GitStatus = Get-GitStatus
		
		if ($GitStatus.HasChanges) {
			Write-Host ""
			Write-Host "⚠️  Changes detected! Time to log what you're working on." -ForegroundColor $ColorWarning
			Prompt-ForUpdate
		}
		
		$LastCheck = Get-Date
	}
}

# Main execution
if ($Monitor) {
	Start-FileMonitor
} elseif ($QuickLog) {
	Prompt-ForUpdate
} else {
	# Default: show interactive prompt
	Prompt-ForUpdate
}
