#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Adds task checklists as comments to child issues

.DESCRIPTION
    This script extracts the tasks from each child issue's body and adds them
    as a separate checklist comment, making them easier to track and check off.

.PARAMETER DryRun
    If specified, shows what would be created without making changes

.EXAMPLE
    .\add_tasks_to_child_issues.ps1
    Adds task checklists to all child issues

.EXAMPLE
    .\add_tasks_to_child_issues.ps1 -DryRun
    Shows what would be created without making changes
#>

param(
    [switch]$dryRun
)

$errorActionPreference = "Stop"

# Check if gh CLI is installed and authenticated
function Test-GitHubCLI {
    try {
        $null = gh --version 2>$null
        $authStatus = gh auth status 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "GitHub CLI not authenticated. Run: gh auth login"
            exit 1
        }
        Write-Host "✓ GitHub CLI authenticated" -ForegroundColor Green
        return $true
    }
    catch {
        Write-Error "GitHub CLI not found. Install from: https://cli.github.com"
        exit 1
    }
}

# Get the repository name
function Get-RepoName {
    try {
        $remote = git remote get-url origin
        if ($remote -match "github\.com[:/](.+?)(?:\.git)?$") {
            return $matches[1]
        }
        throw "Could not parse repository from remote URL: $remote"
    }
    catch {
        Write-Error "Failed to get repository name: $_"
        exit 1
    }
}

Write-Host ""
Write-Host "📝 Add Task Checklists to Child Issues" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Test-GitHubCLI
$repo = Get-RepoName
Write-Host "✓ Repository: $repo" -ForegroundColor Green
Write-Host ""

if ($dryRun) {
    Write-Host "🔍 DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
    Write-Host ""
}

# Child issues range: #13-#47
$childIssues = 13..47

$addedcount = 0
$skippedCount = 0
$errorCount = 0

foreach ($issueNum in $childIssues) {
    Write-Host "[$issueNum] Processing child issue #$issueNum" -ForegroundColor Cyan

    try {
        # Get the issue body
        $issueData = gh issue view $issueNum --repo $repo --json body,title,comments | ConvertFrom-Json
        $body = $issueData.body
        $title = $issueData.title

        # Check if there's already a checklist comment
        $hasChecklist = $false
        foreach ($comment in $issueData.comments) {
            if ($comment.body -match "## 📋 Task Checklist" -or $comment.body -match "## ✅ Progress Tracking") {
                $hasChecklist = $true
                break
            }
        }

        if ($hasChecklist) {
            Write-Host "  ⚠ Already has checklist comment - skipping" -ForegroundColor Yellow
            $skippedCount++
            continue
        }

        # Extract tasks section from body
        if ($body -match "## Tasks\s+((?:- \[ \].*\n?)+)") {
            $tasks = $matches[1].Trim()

            # Create checklist comment
            $comment = @"
## ✅ Progress Tracking

Track your progress on this issue by checking off tasks as you complete them:

$tasks

---

**💡 Tip**: Check off tasks as you complete them to track progress!
"@

            if ($dryRun) {
                Write-Host "  [DRY RUN] Would add checklist comment" -ForegroundColor Yellow
                Write-Host "  Preview (first 150 chars):" -ForegroundColor Gray
                Write-Host "  $($comment.Substring(0, [Math]::Min(150, $comment.Length)))..." -ForegroundColor DarkGray
            }
            else {
                # Add comment to issue
                $tempFile = [System.IO.Path]::GetTempFileName()
                Set-Content -Path $tempFile -Value $comment -NoNewline

                $result = gh issue comment $issueNum --repo $repo --body-file $tempFile
                Remove-Item $tempFile

                Write-Host "  ✓ Added checklist comment" -ForegroundColor Green
                $addedcount++

                Start-Sleep -Milliseconds 500  # Rate limiting
            }
        }
        else {
            Write-Host "  ⚠ No tasks found in issue body - skipping" -ForegroundColor Yellow
            $skippedCount++
        }
    }
    catch {
        Write-Host "  ✗ Error processing #$issueNum : $_" -ForegroundColor Red
        $errorCount++
    }

    Write-Host ""
}

Write-Host ""
Write-Host " + ====================================================================== +" -ForegroundColor Cyan
Write-Host ""
Write-Host "✨ Task Checklist Addition Summary" -ForegroundColor Cyan
Write-Host "====================================================================== + " -ForegroundColor Cyan
Write-Host ""

if ($dryRun) {
    Write-Host "🔍 DRY RUN Complete!" -ForegroundColor Yellow
    Write-Host "Would have added checklist comments to child issues" -ForegroundColor Yellow
}
else {
    Write-Host "✓ Added checklists: $addedcount" -ForegroundColor Green
    Write-Host "⚠ Skipped: $skippedCount" -ForegroundColor Yellow
    if ($errorCount -gt 0) {
        Write-Host "✗ Errors: $errorCount" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Each child issue now has a checklist comment" -ForegroundColor White
    Write-Host "  2. Check off tasks as you work to track progress" -ForegroundColor White
    Write-Host "  3. Close child issues when all tasks are complete" -ForegroundColor White
    Write-Host "  4. Parent issues close when all children are done" -ForegroundColor White
}

Write-Host ""
Write-Host "Done! 🎉" -ForegroundColor Green
Write-Host ""
