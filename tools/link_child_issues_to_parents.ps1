#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Links granular child issues to their parent issues

.DESCRIPTION
    This script updates parent issue descriptions to include links to all their child issues,
    creating a clear parent-child relationship visible in the GitHub UI.

.PARAMETER DryRun
    If specified, shows what would be updated without making changes

.EXAMPLE
    .\link_child_issues_to_parents.ps1
    Updates all parent issues with child issue links

.EXAMPLE
    .\link_child_issues_to_parents.ps1 -DryRun
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
Write-Host "🔗 Link Child Issues to Parent Issues" -ForegroundColor Cyan
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
    Write-Host "  Child issues: $($children.Count)" -ForegroundColor Gray

    # Get current issue body
    try {
        $currentBody = gh issue view $parentNum --repo $repo --json body --jq '.body'

        # Build child issues section
        $childSection = @"

---

## 🎯 Child Issues

This parent issue is broken down into the following trackable sub-issues:

"@

        foreach ($child in $children) {
            $childSection += "- #$($child.num): $($child.title)`n"
        }

        $childSection += @"

**Progress**: Track individual child issues above. This parent issue stays open until all children are complete.

"@

        # Check if child section already exists
        if ($currentBody -match "## 🎯 Child Issues") {
            Write-Host "  ⚠ Child issues section already exists - skipping" -ForegroundColor Yellow
            continue
        }

        # Append child section to body
        $newBody = $currentBody + $childSection

        if ($DryRun) {
            Write-Host "  [DRY RUN] Would append child issues section" -ForegroundColor Yellow
            Write-Host "  Preview:" -ForegroundColor Gray
            Write-Host "  ---" -ForegroundColor DarkGray
            Write-Host $childSection.Substring(0, [Math]::Min(200, $childSection.Length)) -ForegroundColor DarkGray
            Write-Host "  ..." -ForegroundColor DarkGray
        }
        else {
            # Create temp file with new body
            $tempFile = [System.IO.Path]::GetTempFileName()
            Set-Content -Path $tempFile -Value $newBody -NoNewline

            # Update the issue
            $result = gh issue edit $parentNum --repo $repo --body-file $tempFile
            Remove-Item $tempFile

            Write-Host "  ✓ Updated parent issue #$parentNum" -ForegroundColor Green
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
Write-Host "✨ Parent Issue Update Summary" -ForegroundColor Cyan
Write-Host "====================================================================== + " -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "🔍 DRY RUN Complete!" -ForegroundColor Yellow
    Write-Host "Would have updated $($parentChildMap.Keys.Count) parent issues with child issue links" -ForegroundColor Yellow
}
else {
    Write-Host "✓ Updated $updateCount parent issues" -ForegroundColor Green
    if ($errorCount -gt 0) {
        Write-Host "✗ Errors: $errorCount" -ForegroundColor Red
    }

    Write-Host ""
    Write-Host "🎯 Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. View parent issues to see child issue links" -ForegroundColor White
    Write-Host "  2. Each parent now shows all its child issues" -ForegroundColor White
    Write-Host "  3. Child issues link back to parents in their descriptions" -ForegroundColor White
    Write-Host "  4. Set up GitHub Project Board to organize all issues" -ForegroundColor White
}

Write-Host ""
Write-Host "Done! 🎉" -ForegroundColor Green
Write-Host ""
