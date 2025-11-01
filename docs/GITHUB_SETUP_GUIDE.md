# GitHub Issues & Project Board Setup Guide

## Prerequisites

1. **Install GitHub CLI**
   ```powershell
   # Using winget (Windows 10+)
   winget install GitHub.cli
   
   # Or download from: https://cli.github.com/
   ```

2. **Authenticate GitHub CLI**
   ```powershell
   gh auth login
   # Follow the prompts to authenticate
   ```

3. **Verify Authentication**
   ```powershell
   gh auth status
   # Should show: Logged in to github.com as YourUsername
   ```

## Creating Issues

### Dry Run (Preview Only)
```powershell
# See what would be created without actually creating issues
.\tools\create_github_issues.ps1 -DryRun
```

### Create All Issues
```powershell
# Create all 13 issues with labels and milestones
.\tools\create_github_issues.ps1
```

This will create:
- **3 High Priority Issues** (Immediate: 1-2 weeks)
  - 🏷️ Finish Code Labeling (68 labels)
  - 🎨 ASM Formatting
  - 📚 Basic Documentation

- **3 Medium Priority Issues** (Short-term: 1-2 months)
  - 🏷️ Memory Address Labels
  - 🖼️ Graphics Extraction
  - 📦 Data Extraction

- **7 Low Priority Issues** (Mid-term: 3-6 months)
  - 🔍 Banks 04, 05, 06, 0E, 0F disassembly
  - 🔄 Asset Build System
  - 📚 Comprehensive Documentation

### What the Script Does
1. ✅ Creates milestone: "100% Code Labels"
2. ✅ Creates 20 custom labels (priority, type, effort, bank tags)
3. ✅ Creates 13 detailed issues with:
   - Full descriptions
   - Action item checklists
   - Effort estimates
   - Priority tags
   - Cross-references to TODO.md

## Setting Up Project Board

### Option 1: Manual Setup (Recommended)
1. Go to: https://github.com/TheAnsarya/ffmq-info/projects
2. Click **"New project"** → Select **"Board"** template
3. Name it: **"FFMQ Disassembly Progress"**
4. Configure columns:
   - **📋 Backlog** - Future tasks
   - **📝 Todo** - Ready to start
   - **🔄 In Progress** - Currently working
   - **👀 Review** - Needs verification
   - **✅ Done** - Completed
5. Add all created issues to the board
6. Drag issues to appropriate columns based on status

### Option 2: Using GitHub CLI (Beta)
```powershell
# Create project (requires beta features enabled)
gh project create --owner TheAnsarya --title "FFMQ Disassembly Progress"

# Add issues to project (manual for now)
# GitHub CLI project management is still in beta
```

## Managing Issues

### View All Issues
```powershell
gh issue list --repo TheAnsarya/ffmq-info
```

### View Issues by Priority
```powershell
# High priority
gh issue list --label "priority: high"

# Medium priority
gh issue list --label "priority: medium"

# Low priority
gh issue list --label "priority: low"
```

### View Issues by Type
```powershell
gh issue list --label "type: code-labeling"
gh issue list --label "type: graphics"
gh issue list --label "type: documentation"
```

### Work on an Issue
```powershell
# Create branch for issue #1
git checkout -b issue-1-code-labeling

# Work on the issue...

# Commit with issue reference
git commit -m "Progress on #1: Renamed 20 labels in bank_00_section2.asm"

# Push and create PR
git push -u origin issue-1-code-labeling
gh pr create --title "Complete code labeling (closes #1)"
```

### Close an Issue
```powershell
# Via commit message
git commit -m "Fixes #1: All 68 labels renamed, 100% complete!"

# Via CLI
gh issue close 1 --comment "Completed! All labels renamed."
```

## Project Board Workflow

### Recommended Workflow
1. **Backlog** → New issues, future work
2. **Todo** → Ready to start (move here when planning to work on it)
3. **In Progress** → Actively working (limit to 1-3 items)
4. **Review** → Code complete, needs verification/testing
5. **Done** → Verified and merged

### Moving Issues
- Drag and drop on the web interface
- Or use automation rules (GitHub Actions)

### Automation Ideas
- Auto-move to "In Progress" when branch created
- Auto-move to "Review" when PR opened
- Auto-move to "Done" when PR merged and issue closed

## Customization

### Edit Issues
```powershell
# Edit issue title/body
gh issue edit 1 --title "New title"

# Add labels
gh issue edit 1 --add-label "requires: testing"

# Remove labels
gh issue edit 1 --remove-label "priority: low"
```

### Create Custom Labels
```powershell
gh label create "custom-label" --color "ff0000" --description "My custom label"
```

### Add Assignees
```powershell
gh issue edit 1 --add-assignee @me
```

## Tips

1. **Start Small**: Begin with high-priority issues
2. **Reference Issues**: Use `#123` in commits/PRs to link issues
3. **Update Progress**: Comment on issues as you make progress
4. **Close When Done**: Always close issues when complete
5. **Use Milestones**: Track progress toward "100% Code Labels" milestone
6. **Review Regularly**: Check project board weekly to prioritize

## Example Workflow

```powershell
# 1. View high priority issues
gh issue list --label "priority: high"

# 2. Pick issue #1 (Code Labeling)
gh issue view 1

# 3. Create branch
git checkout -b finish-code-labels

# 4. Work on task (rename labels, verify ROM match)

# 5. Commit with reference
git commit -m "Progress on #1: Bank 00 section 2 complete (8 labels)"

# 6. Continue until issue complete

# 7. Final commit
git commit -m "Fixes #1: All 68 labels eliminated! 🏆"

# 8. Push and create PR
git push -u origin finish-code-labels
gh pr create --title "Complete code labeling campaign" --body "Closes #1"

# 9. Merge PR (issue automatically closed)

# 10. Celebrate! 🎉
```

## Troubleshooting

### "gh: command not found"
- Install GitHub CLI: https://cli.github.com/
- Restart terminal after installation

### "HTTP 401: Bad credentials"
- Re-authenticate: `gh auth login`

### "Failed to create issue"
- Check repository access: `gh repo view TheAnsarya/ffmq-info`
- Verify you have write permissions

### Issues not showing in project
- Projects must be manually configured initially
- Use the web interface to add issues to project board

## Resources

- GitHub CLI Manual: https://cli.github.com/manual/
- GitHub Projects: https://docs.github.com/en/issues/planning-and-tracking-with-projects
- Issue Management: https://docs.github.com/en/issues

---

**Ready to create issues?** Run: `.\tools\create_github_issues.ps1`
