# GitHub Project Configuration
# This file contains project-specific settings for GitHub CLI operations

# Project Information
$ProjectOwner = "TheAnsarya"
$ProjectRepo = "ffmq-info"
$ProjectNumber = 3
$ProjectUrl = "https://github.com/users/TheAnsarya/projects/3"

# Helper function to create an issue with project assignment
function New-ProjectIssue {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Title,
        
        [Parameter(Mandatory=$true)]
        [string]$Body,
        
        [string[]]$Labels,
        
        [switch]$AddToProject
    )
    
    # Create the issue
    $labelArgs = if ($Labels) { "--label", ($Labels -join ",") } else { @() }
    
    $issueUrl = gh issue create --title $Title --body $Body @labelArgs
    
    if ($issueUrl) {
        Write-Host "✓ Created issue: $issueUrl" -ForegroundColor Green
        
        # Note: Adding to project requires additional GraphQL API calls
        # For now, issues can be manually added to the project board
        if ($AddToProject) {
            Write-Host "⚠ Note: Please manually add this issue to Project #3: $ProjectUrl" -ForegroundColor Yellow
        }
        
        return $issueUrl
    }
    else {
        Write-Host "✗ Failed to create issue" -ForegroundColor Red
        return $null
    }
}

# Helper function to view project issues
function Get-ProjectIssues {
    Write-Host "Opening project board: $ProjectUrl" -ForegroundColor Cyan
    Start-Process $ProjectUrl
}

# Export functions
Export-ModuleMember -Function New-ProjectIssue, Get-ProjectIssues

# Display project info
Write-Host "`n📊 GitHub Project Configuration Loaded" -ForegroundColor Cyan
Write-Host "   Owner: $ProjectOwner" -ForegroundColor Gray
Write-Host "   Repo: $ProjectRepo" -ForegroundColor Gray
Write-Host "   Project #: $ProjectNumber" -ForegroundColor Gray
Write-Host "   URL: $ProjectUrl" -ForegroundColor Gray
Write-Host ""
