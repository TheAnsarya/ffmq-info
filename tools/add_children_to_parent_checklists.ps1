#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Adds child issue links to parent issue task checklists

.DESCRIPTION
    This script updates parent issue comments to include their child issues as
    checkable tasks, allowing you to track parent progress by completing children.

.PARAMETER DryRun
    If specified, shows what would be updated without making changes

.EXAMPLE
    .\add_children_to_parent_checklists.ps1
    Updates all parent issue checklists with child issue links

.EXAMPLE
    .\add_children_to_parent_checklists.ps1 -DryRun
    Shows what would be updated without making changes
#>

param(
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

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

# Parent to child issues mapping
$parentChildMap = @{
    1 = @(
        @{ num = 13; title = "ASM Formatting: Prerequisites and Setup" }
        @{ num = 14; title = "ASM Formatting: Develop format_asm.ps1 Script" }
        @{ num = 15; title = "ASM Formatting: Testing and Validation" }
        @{ num = 16; title = "ASM Formatting: Format Priority 1 Banks (6 files)" }
        @{ num = 17; title = "ASM Formatting: Format Priority 2-3 Banks and Integration" }
    )
    2 = @(
        @{ num = 18; title = "Documentation: Planning and Templates" }
        @{ num = 19; title = "Documentation: ARCHITECTURE.md - System Overview" }
        @{ num = 20; title = "Documentation: BUILD_GUIDE.md - Building the ROM" }
        @{ num = 21; title = "Documentation: MODDING_GUIDE.md - Game Modifications" }
        @{ num = 22; title = "Documentation: CONTRIBUTING.md and Organization" }
    )
    3 = @(
        @{ num = 23; title = "Memory Labels: Address Inventory and Analysis" }
        @{ num = 24; title = "Memory Labels: RAM Map Documentation" }
        @{ num = 25; title = "Memory Labels: ROM Data Map Documentation" }
        @{ num = 26; title = "Memory Labels: Label Naming Conventions" }
        @{ num = 27; title = "Memory Labels: Label Replacement Tool Development" }
        @{ num = 28; title = "Memory Labels: High Priority WRAM Labels" }
        @{ num = 29; title = "Memory Labels: Medium Priority WRAM Labels" }
        @{ num = 30; title = "Memory Labels: ROM Data Table Labels" }
        @{ num = 31; title = "Memory Labels: Documentation and Maintenance" }
    )
    4 = @(
        @{ num = 32; title = "Graphics: Core Extraction Tools Development" }
        @{ num = 33; title = "Graphics: Palette Management System" }
        @{ num = 34; title = "Graphics: Character and Enemy Sprites Extraction" }
        @{ num = 35; title = "Graphics: UI and Environmental Graphics Extraction" }
        @{ num = 36; title = "Graphics: Asset Organization and Documentation" }
    )
    5 = @(
        @{ num = 37; title = "Data: Core Extraction Tools Development" }
        @{ num = 38; title = "Data: Game Data Extraction (Characters, Enemies, Items)" }
        @{ num = 39; title = "Data: Map and Text Extraction" }
        @{ num = 40; title = "Data: Asset Organization and Documentation" }
    )
    11 = @(
        @{ num = 41; title = "Build System: Graphics and Data Import Tools" }
        @{ num = 42; title = "Build System: Build Orchestration and ROM Integrity" }
        @{ num = 43; title = "Build System: Round-Trip Testing and Documentation" }
    )
    12 = @(
        @{ num = 44; title = "Docs: System Architecture Documentation" }
        @{ num = 45; title = "Docs: Data Structures and Function Reference" }
        @{ num = 46; title = "Docs: Visual Documentation and Community Resources" }
        @{ num = 47; title = "Docs: Documentation Maintenance System" }
    )
}

Write-Host ""
Write-Host "🔗 Add Child Issues to Parent Checklists" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host ""

Test-GitHubCLI
$repo = Get-RepoName
Write-Host "✓ Repository: $repo" -ForegroundColor Green
Write-Host ""

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No changes will be made" -ForegroundColor Yellow
    Write-Host ""
}

$updateCount = 0
$errorCount = 0

foreach ($parentNum in $parentChildMap.Keys | Sort-Object) {
    $children = $parentChildMap[$parentNum]

    Write-Host "[$parentNum] Updating Parent Issue #$parentNum" -ForegroundColor Cyan
    Write-Host "  Adding $($children.Count) child issues to checklist" -ForegroundColor Gray

    try {
        # Get the issue data including comments
        $issueData = gh issue view $parentNum --repo $repo --comments --json body,comments | ConvertFrom-Json

        # Find the sub-tasks comment
        $commentIndex = -1
        for ($i = 0; $i -lt $issueData.comments.Count; $i++) {
            if ($issueData.comments[$i].body -match "## Sub-Tasks Checklist") {
                $commentIndex = $i
                break
            }
        }

        if ($commentIndex -eq -1) {
            Write-Host "  ⚠ No sub-tasks comment found - skipping" -ForegroundColor Yellow
            continue
        }

        $currentComment = $issueData.comments[$commentIndex].body

        # Check if child issues section already exists
        if ($currentComment -match "### 🎯 Child Issues") {
            Write-Host "  ⚠ Child issues section already exists - skipping" -ForegroundColor Yellow
            continue
        }

        # Build child issues section
        $childSection = @"

### 🎯 Child Issues

Track progress by completing these granular issues:

"@

        foreach ($child in $children) {
            $childSection += "- [ ] #$($child.num): $($child.title)`n"
        }

        $childSection += @"

> **Note**: Check off child issues as they are completed. Parent issue closes when all children are done.

"@

        # Prepend child section to the existing comment (at the top)
        $newComment = "## Sub-Tasks Checklist`n`n" + $childSection + "`n" + $currentComment.Replace("## Sub-Tasks Checklist`n`n", "")

        if ($DryRun) {
            Write-Host "  [DRY RUN] Would update comment with child issues" -ForegroundColor Yellow
            Write-Host "  Preview:" -ForegroundColor Gray
            Write-Host "  ---" -ForegroundColor DarkGray
            Write-Host $childSection.Substring(0, [Math]::Min(200, $childSection.Length)) -ForegroundColor DarkGray
            Write-Host "  ..." -ForegroundColor DarkGray
        }
        else {
            # Get comment ID (need to use GraphQL or API to edit comments)
            # For now, we'll add a new comment instead
            $tempFile = [System.IO.Path]::GetTempFileName()
            Set-Content -Path $tempFile -Value $childSection -NoNewline

            # Add new comment with child issues
            $result = gh issue comment $parentNum --repo $repo --body-file $tempFile
            Remove-Item $tempFile

            Write-Host "  ✓ Added child issues comment to parent #$parentNum" -ForegroundColor Green
            $updateCount++

            Start-Sleep -Milliseconds 500  # Rate limiting
        }
    }
    catch {
        Write-Host "  ✗ Error updating #$parentNum : $_" -ForegroundColor Red
        $errorCount++
    }

    Write-Host ""
}

Write-Host ""
Write-Host " + ====================================================================== +" -ForegroundColor Cyan
Write-Host ""
Write-Host "✨ Parent Checklist Update Summary" -ForegroundColor Cyan
Write-Host "====================================================================== + " -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "🔍 DRY RUN Complete!" -ForegroundColor Yellow
    Write-Host "Would have added child issue checklists to $($parentChildMap.Keys.Count) parent issues" -ForegroundColor Yellow
}
else {
    Write-Host "✓ Updated $updateCount parent issues" -ForegroundColor Green
    if ($errorCount -gt 0) {
        Write-Host "✗ Errors: $errorCount" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. Each parent now has a Child Issues checklist" -ForegroundColor White
    Write-Host "  2. Check off child issues as they are completed" -ForegroundColor White
    Write-Host "  3. Parent progress = % of children completed" -ForegroundColor White
    Write-Host "  4. Close parent when all children are done" -ForegroundColor White
}

Write-Host ""
Write-Host "Done! 🎉" -ForegroundColor Green
Write-Host ""
