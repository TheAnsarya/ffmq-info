# Project Board Organization Guide

**Project Name**: FFMQ Disassembly Progress  
**Total Issues**: 47 (12 parents + 35 children)  
**Setup Time**: ~5 minutes  

## Quick Setup

### Option 1: Interactive Script (Recommended)
```powershell
.\tools\setup_project_board.ps1
```

### Option 2: Manual Web Interface
1. Go to: https://github.com/TheAnsarya/ffmq-info/projects
2. Click "New project" → Select "Board"
3. Name: "FFMQ Disassembly Progress"
4. Follow steps below

## Workflow Columns

Recommended 5-column workflow:

```
📋 Backlog → 🎯 Ready → 🔄 In Progress → 👀 Review → ✅ Done
```

- **Backlog**: Low priority, future work
- **Ready**: High priority, ready to start
- **In Progress**: Currently being worked on
- **Review**: Awaiting code review or testing
- **Done**: Completed and closed

## Issue Organization by Column

### 📋 Backlog (15 issues - Low Priority)

**Parent Issues** (5):
- #6: Complete Code Disassembly - Bank 04
- #7: Complete Code Disassembly - Bank 05
- #8: Complete Code Disassembly - Bank 06
- #9: Complete Code Disassembly - Bank 0E
- #10: Complete Code Disassembly - Bank 0F

**Granular Issues** (10):
- #17: ASM Formatting: Format Priority 2-3 Banks and Integration
- #29: Memory Labels: Medium Priority WRAM Labels
- #30: Memory Labels: ROM Data Table Labels
- #31: Memory Labels: Documentation and Maintenance
- #44: Docs: System Architecture Documentation
- #45: Docs: Data Structures and Function Reference
- #46: Docs: Visual Documentation and Community Resources
- #47: Docs: Documentation Maintenance System

Plus 2 more if not started yet.

### 🎯 Ready (17 issues - High Priority, Ready to Start)

**Parent Issues** (3):
- #1: 🎨 ASM Code Formatting
- #2: 📚 Basic Documentation
- #3: 🏷️ Memory Address & Variable Labels

**ASM Formatting** (4 granular issues):
- #13: ASM Formatting: Prerequisites and Setup
- #14: ASM Formatting: Develop format_asm.ps1 Script
- #15: ASM Formatting: Testing and Validation
- #16: ASM Formatting: Format Priority 1 Banks (6 files)

**Documentation** (5 granular issues):
- #18: Documentation: Planning and Templates
- #19: Documentation: ARCHITECTURE.md - System Overview
- #20: Documentation: BUILD_GUIDE.md - Building the ROM
- #21: Documentation: MODDING_GUIDE.md - Game Modifications
- #22: Documentation: CONTRIBUTING.md and Organization

**Memory Labels** (5 granular issues):
- #23: Memory Labels: Address Inventory and Analysis
- #24: Memory Labels: RAM Map Documentation
- #25: Memory Labels: ROM Data Map Documentation
- #26: Memory Labels: Label Naming Conventions
- #27: Memory Labels: Label Replacement Tool Development

### 📊 Todo (15 issues - Medium Priority)

**Parent Issues** (4):
- #4: 🖼️ Graphics Extraction Pipeline
- #5: 📦 Data Extraction Pipeline
- #11: 🔄 Asset Build System
- #12: 📚 Comprehensive System Documentation

**Memory Labels** (1 granular issue):
- #28: Memory Labels: High Priority WRAM Labels

**Graphics Extraction** (5 granular issues):
- #32: Graphics: Core Extraction Tools Development
- #33: Graphics: Palette Management System
- #34: Graphics: Character and Enemy Sprites Extraction
- #35: Graphics: UI and Environmental Graphics Extraction
- #36: Graphics: Asset Organization and Documentation

**Data Extraction** (4 granular issues):
- #37: Data: Core Extraction Tools Development
- #38: Data: Game Data Extraction (Characters, Enemies, Items)
- #39: Data: Map and Text Extraction
- #40: Data: Asset Organization and Documentation

**Build System** (3 granular issues):
- #41: Build System: Graphics and Data Import Tools
- #42: Build System: Build Orchestration and ROM Integrity
- #43: Build System: Round-Trip Testing and Documentation

## Issue Grouping by Parent

Organize child issues under their parent for visual hierarchy:

### Parent #1: ASM Code Formatting
```
#1 (Parent)
├── #13: Prerequisites and Setup
├── #14: Develop format_asm.ps1 Script
├── #15: Testing and Validation
├── #16: Format Priority 1 Banks (6 files)
└── #17: Format Priority 2-3 Banks and Integration
```

### Parent #2: Basic Documentation
```
#2 (Parent)
├── #18: Planning and Templates
├── #19: ARCHITECTURE.md - System Overview
├── #20: BUILD_GUIDE.md - Building the ROM
├── #21: MODDING_GUIDE.md - Game Modifications
└── #22: CONTRIBUTING.md and Organization
```

### Parent #3: Memory Labels
```
#3 (Parent)
├── #23: Address Inventory and Analysis
├── #24: RAM Map Documentation
├── #25: ROM Data Map Documentation
├── #26: Label Naming Conventions
├── #27: Label Replacement Tool Development
├── #28: High Priority WRAM Labels
├── #29: Medium Priority WRAM Labels
├── #30: ROM Data Table Labels
└── #31: Documentation and Maintenance
```

### Parent #4: Graphics Extraction
```
#4 (Parent)
├── #32: Core Extraction Tools Development
├── #33: Palette Management System
├── #34: Character and Enemy Sprites Extraction
├── #35: UI and Environmental Graphics Extraction
└── #36: Asset Organization and Documentation
```

### Parent #5: Data Extraction
```
#5 (Parent)
├── #37: Core Extraction Tools Development
├── #38: Game Data Extraction (Characters, Enemies, Items)
├── #39: Map and Text Extraction
└── #40: Asset Organization and Documentation
```

### Parent #6-10: Bank Disassembly
```
#6: Bank 04 (standalone - no granular issues)
#7: Bank 05 (standalone - no granular issues)
#8: Bank 06 (standalone - no granular issues)
#9: Bank 0E (standalone - no granular issues)
#10: Bank 0F (standalone - no granular issues)
```

### Parent #11: Asset Build System
```
#11 (Parent)
├── #41: Graphics and Data Import Tools
├── #42: Build Orchestration and ROM Integrity
└── #43: Round-Trip Testing and Documentation
```

### Parent #12: Comprehensive Documentation
```
#12 (Parent)
├── #44: System Architecture Documentation
├── #45: Data Structures and Function Reference
├── #46: Visual Documentation and Community Resources
└── #47: Documentation Maintenance System
```

## Bulk Issue Management

### Add All Issues at Once
1. Go to https://github.com/TheAnsarya/ffmq-info/issues
2. Click checkbox at top to select all visible issues
3. Click "Projects" dropdown
4. Select "FFMQ Disassembly Progress"
5. All issues added instantly!

### Filter Issues by Label
Use GitHub's label filter to organize:
- `priority:high` → Move to Ready
- `priority:medium` → Move to Todo
- `priority:low` → Move to Backlog

### Filter Issues by Type
- `type:formatting` → ASM formatting issues
- `type:documentation` → Documentation issues
- `type:code-labeling` → Memory label issues
- `type:graphics` → Graphics extraction
- `type:data` → Data extraction
- `type:build-system` → Build system
- `type:disassembly` → Bank disassembly

## Project Board Automation

Enable these automations in Project Settings → Workflows:

### Auto-add Issues
- **Trigger**: New issue created
- **Action**: Add to "Backlog" column

### Auto-move to In Progress
- **Trigger**: Issue assigned
- **Action**: Move to "In Progress"

### Auto-move to Review
- **Trigger**: PR linked to issue
- **Action**: Move to "Review"

### Auto-move to Done
- **Trigger**: Issue closed
- **Action**: Move to "Done"

## Custom Fields (Optional)

Add these fields for better tracking:

| Field Name | Type | Values |
|------------|------|--------|
| Parent Issue | Single Select | #1, #2, #3, #4, #5, #11, #12 |
| Effort | Number | Hours (from issue estimates) |
| Dependencies | Text | Blocking/Blocked issues |
| Sprint | Iteration | Sprint 1, 2, 3, etc. |

## Iteration Planning

Suggested sprint grouping:

### Sprint 1: Foundation (Weeks 1-2)
- #13: ASM Prerequisites
- #14: Format Script Development
- #18: Documentation Planning
- #23: Memory Address Inventory

### Sprint 2: Core Tools (Weeks 3-4)
- #15: ASM Testing
- #19: ARCHITECTURE.md
- #24: RAM Map Documentation
- #27: Label Replacement Tool

### Sprint 3: Implementation (Weeks 5-6)
- #16: Format Priority 1 Banks
- #20: BUILD_GUIDE.md
- #25: ROM Data Map
- #28: High Priority Labels

### Sprint 4: Integration (Weeks 7-8)
- #17: Format Priority 2-3 Banks
- #21: MODDING_GUIDE.md
- #26: Label Conventions
- #22: CONTRIBUTING.md

## Quick Reference Commands

### View Issues by Priority
```powershell
# High priority
gh issue list --label "priority:high"

# Medium priority
gh issue list --label "priority:medium"

# Low priority
gh issue list --label "priority:low"
```

### View Issues by Type
```powershell
# Formatting issues
gh issue list --label "type:formatting"

# Documentation issues
gh issue list --label "type:documentation"

# All types
gh issue list --label "type:formatting,type:documentation,type:code-labeling"
```

### View Child Issues for a Parent
```powershell
# Find all issues referencing parent #1
gh issue list --search "Parent Issue: #1"

# Or view parent issue to see children in description
gh issue view 1
```

## Tips for Effective Board Management

### 1. Limit Work in Progress
- Keep only 2-3 issues in "In Progress" at a time
- Focus on completing before starting new work

### 2. Regular Updates
- Update issue progress daily
- Check off completed sub-tasks
- Add comments on blockers

### 3. Use Draft PRs
- Create draft PR when starting work
- Link to issue in PR description
- Move issue to "Review" when PR ready

### 4. Close Complete Issues
- Mark all sub-tasks as done
- Add completion comment
- Close issue (auto-moves to Done)

### 5. Review Weekly
- Check board at start of week
- Move ready issues from Backlog to Ready
- Adjust priorities based on progress

## Project Board URL

After setup, bookmark your board:
**https://github.com/TheAnsarya/ffmq-info/projects/1**

(Project number may vary - use your actual project URL)

## Need Help?

- **GitHub Projects Docs**: https://docs.github.com/en/issues/planning-and-tracking-with-projects
- **Project Templates**: https://docs.github.com/en/issues/planning-and-tracking-with-projects/creating-projects/creating-a-project
- **Automation Docs**: https://docs.github.com/en/issues/planning-and-tracking-with-projects/automating-your-project

---

**Last Updated**: November 1, 2025  
**Total Issues**: 47 (12 parents + 35 children)  
**Ready to Track**: ✅
