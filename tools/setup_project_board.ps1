#!/usr/bin/env pwsh
<#
.SYNOPSIS
	Helper script to set up GitHub Project Board for FFMQ Disassembly

.DESCRIPTION
	This script provides commands and information to help set up the GitHub Project Board.
	Due to GitHub CLI project permissions, some steps need to be done via web interface.

.NOTES
	Project Board Setup Guide
	- Creates a board with proper workflow columns
	- Organizes 47 issues by priority and parent
#>

$errorActionPreference = "Stop"

Write-Host @"
╔════════════════════════════════════════════════════════════════════════════╗
║                  GitHub Project Board Setup Guide                          ║
║                  FFMQ Disassembly Project (47 Issues)                      ║
╚════════════════════════════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# Check current repository
$repo = git remote get-url origin
if ($repo -match "github\.com[:/](.+)/(.+?)(\.git)?$") {
	$owner = $matches[1]
	$repoName = $matches[2]
	Write-Host "Repository: $owner/$repoName" -ForegroundColor Green
} else {
	Write-Error "Could not determine repository"
	exit 1
}

Write-Host @"

📋 STEP 1: Create New Project Board
════════════════════════════════════════════════════════════════════════════

1. Go to: https://github.com/$owner/$repoName/projects

2. Click the green "New project" button

3. Select "Board" template (recommended)
   - OR select "Table" if you prefer spreadsheet view
   - OR start from "Blank" and customize

4. Configure the project:
   - Name: "FFMQ Disassembly Progress"
   - Description: "Track progress on Final Fantasy Mystic Quest disassembly project"
   - Click "Create project"

"@ -ForegroundColor White

Read-Host "Press Enter when you've created the project board..."

Write-Host @"

🏛️ STEP 2: Set Up Workflow Columns
════════════════════════════════════════════════════════════════════════════

Default "Board" template comes with columns:
  📥 Todo
  🔄 In Progress
  ✅ Done

RECOMMENDED: Add these additional columns for better workflow:

1. Click "..." on any column → "New column" to add:
   - 📋 Backlog (for lower priority items)
   - 🎯 Ready (for high priority items ready to start)
   - 👀 Review (for items awaiting review)

2. Arrange columns in this order (drag to reorder):
   📋 Backlog → 🎯 Ready → 🔄 In Progress → 👀 Review → ✅ Done

"@ -ForegroundColor White

Read-Host "Press Enter when you've set up the columns..."

Write-Host @"

➕ STEP 3: Add All 47 Issues to Project Board
════════════════════════════════════════════════════════════════════════════

METHOD A: Add issues individually via web interface
────────────────────────────────────────────────────────────────────────────
1. On the project board, click "+" or "Add item"
2. Search for issue numbers: #1, #2, #3, etc.
3. Add each issue to the board

METHOD B: Add issues in bulk (RECOMMENDED)
────────────────────────────────────────────────────────────────────────────
1. Go to: https://github.com/$owner/$repoName/issues
2. Select all issues (use checkboxes on left)
3. Click "Projects" dropdown at top
4. Select your "FFMQ Disassembly Progress" project
5. All 47 issues will be added at once!

"@ -ForegroundColor White

Read-Host "Press Enter when you've added all issues..."

Write-Host @"

🎯 STEP 4: Organize Issues by Priority
════════════════════════════════════════════════════════════════════════════

Organize the 47 issues into columns based on priority and readiness:

📋 BACKLOG (Low Priority - 15 issues)
────────────────────────────────────────────────────────────────────────────
Parent Issues:
  #6-#10: Complete Code Disassembly - Banks 04, 05, 06, 0E, 0F

Granular Issues:
  #17: ASM Formatting: Format Priority 2-3 Banks
  #29-#31: Memory Labels (Medium/Low Priority)
  #44-#47: Comprehensive Documentation (4 issues)

🎯 READY (High Priority - Ready to Start - 17 issues)
────────────────────────────────────────────────────────────────────────────
Parent Issues:
  #1: ASM Code Formatting
  #2: Basic Documentation
  #3: Memory Address & Variable Labels

Granular Issues - ASM Formatting:
  #13: Prerequisites and Setup
  #14: Develop format_asm.ps1 Script
  #15: Testing and Validation
  #16: Format Priority 1 Banks

Granular Issues - Documentation:
  #18: Planning and Templates
  #19: ARCHITECTURE.md
  #20: BUILD_GUIDE.md
  #21: MODDING_GUIDE.md
  #22: CONTRIBUTING.md

Granular Issues - Memory Labels (High/Medium):
  #23: Address Inventory and Analysis
  #24: RAM Map Documentation
  #25: ROM Data Map Documentation
  #26: Label Naming Conventions

📊 TODO (Medium Priority - 15 issues)
────────────────────────────────────────────────────────────────────────────
Parent Issues:
  #4: Graphics Extraction Pipeline
  #5: Data Extraction Pipeline
  #11: Asset Build System
  #12: Comprehensive Documentation

Granular Issues - Memory Labels:
  #27: Label Replacement Tool
  #28: High Priority WRAM Labels

Granular Issues - Graphics:
  #32-#36: Graphics extraction (5 issues)

Granular Issues - Data:
  #37-#40: Data extraction (4 issues)

Granular Issues - Build System:
  #41-#43: Build system (3 issues)

"@ -ForegroundColor White

Read-Host "Press Enter when you've organized the issues..."

Write-Host @"

👥 STEP 5: Optional Enhancements
════════════════════════════════════════════════════════════════════════════

A. Group by Parent Issue
────────────────────────────────────────────────────────────────────────────
   On the board, you can manually arrange child issues under their parent:

   #1 (Parent: ASM Formatting)
	 ↳ #13: Prerequisites
	 ↳ #14: Script Development
	 ↳ #15: Testing
	 ↳ #16: Priority 1 Banks
	 ↳ #17: Priority 2-3 Banks

B. Add Custom Fields (Project Settings)
────────────────────────────────────────────────────────────────────────────
   - Parent Issue (Link to parent #)
   - Estimated Hours (from issue descriptions)
   - Dependencies (blocking/blocked by)

C. Set Up Automation
────────────────────────────────────────────────────────────────────────────
   In Project Settings → Workflows:
   - Auto-add new issues to Backlog
   - Auto-move to Done when issue closed
   - Auto-move to Review when PR created

D. Add Iteration/Milestone Planning
────────────────────────────────────────────────────────────────────────────
   Create iterations for sprint planning:
   - Sprint 1: ASM Formatting foundation (#13-#15)
   - Sprint 2: Documentation basics (#18-#22)
   - Sprint 3: Memory labels setup (#23-#26)

"@ -ForegroundColor White

Write-Host @"

✅ STEP 6: Verify Setup
════════════════════════════════════════════════════════════════════════════

Checklist:
  ☐ Project board created: "FFMQ Disassembly Progress"
  ☐ Workflow columns configured (5 columns recommended)
  ☐ All 47 issues added to board
  ☐ Issues organized by priority:
	 - 17 issues in Ready (high priority)
	 - 15 issues in Todo (medium priority)
	 - 15 issues in Backlog (low priority)
  ☐ Issues grouped by parent (optional)
  ☐ Automation enabled (optional)

"@ -ForegroundColor Green

Write-Host @"

🎯 PROJECT BOARD IS READY!
════════════════════════════════════════════════════════════════════════════

Your board URL (bookmark this):
👉 https://github.com/$owner/$repoName/projects

Next Steps:
1. Pick a high-priority issue from the Ready column
2. Move it to "In Progress"
3. Create a feature branch (e.g., git checkout -b feature/issue-13)
4. Start checking off sub-tasks!
5. When complete, create PR and move to Review
6. After merge, issue auto-closes and moves to Done

Happy coding! 🚀

"@ -ForegroundColor Cyan

# Generate issue list for reference
Write-Host "`n📊 Quick Reference: All 47 Issues" -ForegroundColor Yellow
Write-Host "═══════════════════════════════════════════════════════════════`n" -ForegroundColor Yellow

Write-Host "Fetching current issue list..." -ForegroundColor Gray
gh issue list --limit 50 --json number,title,labels --jq '.[] | "#\(.number): \(.title)"' | Sort-Object

Write-Host "`n✨ Setup guide complete!`n" -ForegroundColor Green
