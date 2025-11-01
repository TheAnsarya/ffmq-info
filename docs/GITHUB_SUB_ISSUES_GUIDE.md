# GitHub Sub-Issues Guide

This guide explains how to use the sub-issue creation system for the FFMQ Disassembly Project.

## Overview

The `tools/create_github_sub_issues.ps1` script adds detailed task checklists to GitHub issues, breaking down each major goal into actionable sub-tasks.

## What It Creates

The script adds a comment to each of the 12 main GitHub issues with:
- **Hierarchical task lists** organized by category
- **Checkboxes** for tracking progress
- **Task counts** and effort estimates
- **Cross-references** to TODO.md for detailed context

### Total Breakdown
- **12 main issues** (#1-#12)
- **420 total sub-tasks** across all issues
- **Organized by priority** (High, Medium, Low)

## Usage

### Dry Run (Preview)
```powershell
.\tools\create_github_sub_issues.ps1 -DryRun
```
Shows what would be created without making changes.

### Create Sub-Issues
```powershell
.\tools\create_github_sub_issues.ps1
```
Adds task list comments to all 12 GitHub issues.

## Sub-Task Distribution

| Issue # | Title | Sub-Tasks | Effort (hrs) |
|---------|-------|-----------|--------------|
| #1 | ASM Code Formatting | 37 | 16-24 |
| #2 | Basic Documentation | 36 | 8-12 |
| #3 | Memory Address Labels | 51 | 40-60 |
| #4 | Graphics Extraction | 60 | 60-80 |
| #5 | Data Extraction | 56 | 40-60 |
| #6 | Bank $04 Disassembly | 19 | 20-30 |
| #7 | Bank $05 Disassembly | 17 | 20-30 |
| #8 | Bank $06 Disassembly | 17 | 20-30 |
| #9 | Bank $0e Disassembly | 21 | 30-40 |
| #10 | Bank $0f Disassembly | 21 | 30-40 |
| #11 | Asset Build System | 39 | 40-50 |
| #12 | Comprehensive Documentation | 46 | 80-120 |
| **TOTAL** | **All Issues** | **420** | **404-606** |

## Sub-Task Structure

Each issue's sub-tasks are organized into logical groups:

### Example: Issue #1 (ASM Code Formatting)
1. **Prerequisites** (3 tasks)
   - Setup .editorconfig
   - Verify tools
   - Backup files

2. **Formatting Script Development** (7 tasks)
   - Create main script
   - Implement conversions
   - Add features

3. **Testing & Validation** (5 tasks)
   - Test on sample file
   - Verify ROM match

4. **Priority 1-3 Banks** (23 tasks)
   - Format each bank file
   - Verify individually

5. **Build Integration** (5 tasks)
   - Add to build scripts
   - Document standards

## Checking Off Tasks

As you complete work:

1. **On GitHub Web Interface**:
   - Go to the issue
   - Find the sub-task checklist comment
   - Click the checkbox next to completed tasks

2. **Via GitHub CLI**:
   ```powershell
   gh issue edit <issue-number> --add-label "in-progress"
   ```

3. **Update Project Board**:
   - Move issue cards as sub-tasks progress
   - Use labels to track status

## Workflow Recommendations

### For Each Issue:
1. **Review sub-task checklist** to understand scope
2. **Mark issue as "in-progress"** on project board
3. **Work through sub-tasks sequentially** (unless parallel work possible)
4. **Check off tasks as completed** in the GitHub comment
5. **Commit frequently** with references to issue number
6. **Move to "Review"** when all sub-tasks complete
7. **Close issue** after final verification

### Commit Message Format:
```
Progress on #<issue>: <description of work>

- [x] Sub-task 1 description
- [x] Sub-task 2 description
- [ ] Sub-task 3 (in progress)
```

### PR Linking:
When creating PRs, reference the issue:
```
Closes #<issue-number>
```
This auto-closes the issue when PR is merged.

## Regenerating Sub-Tasks

If TODO.md is updated with new details:

1. **Edit** `tools/create_github_sub_issues.ps1`
2. **Update** the here-strings for affected issues
3. **Test** with `-DryRun`
4. **Run** script to add updated comment
5. **Note**: This adds a NEW comment, doesn't edit existing ones

## Integration with Project Board

After running this script:

1. **Project board columns** map to task progress:
   - **Backlog**: Issues not started (0 tasks checked)
   - **Ready**: Issues ready to start (prerequisites done)
   - **In Progress**: Issues being worked (some tasks checked)
   - **Review**: Issues complete (all tasks checked, awaiting review)
   - **Done**: Issues closed (all verified)

2. **Use GitHub Projects automation**:
   - Auto-move to "In Progress" when first task checked
   - Auto-move to "Review" when all tasks checked
   - Auto-move to "Done" when issue closed

## Tips

- **Work incrementally**: Don't try to complete all sub-tasks at once
- **Commit after each logical group**: Easier to track and revert if needed
- **Update task lists promptly**: Keeps everyone informed of progress
- **Add notes as comments**: Document challenges or decisions
- **Cross-reference**: Link related issues and PRs
- **Celebrate milestones**: Mark major sub-task groups as you finish!

## Troubleshooting

### Script Fails
- Verify GitHub CLI authenticated: `gh auth status`
- Check repository: `git remote get-url origin`
- Ensure in correct directory: repository root

### Can't Check Off Tasks
- Checkboxes only work in issue comments (not PR descriptions)
- Need write access to repository
- Try refreshing the page

### Sub-Tasks Out of Sync with Work
- Add new comment with current status
- Reference original checklist
- Update TODO.md and regenerate if needed

## See Also

- [TODO.md](../TODO.md) - Detailed task descriptions and estimates
- [QUICK_TODO_SUMMARY.md](../QUICK_TODO_SUMMARY.md) - Quick reference
- [GITHUB_SETUP_GUIDE.md](GITHUB_SETUP_GUIDE.md) - GitHub CLI setup
- [PROJECT_BOARD_SETUP.md](PROJECT_BOARD_SETUP.md) - Project board configuration

---

**Last Updated**: October 31, 2025  
**Script Version**: 1.0  
**Total Sub-Tasks**: 420 across 12 issues
