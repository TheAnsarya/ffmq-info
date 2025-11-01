# Granular Issues Creation Summary

**Date**: November 1, 2025  
**Branch**: `ai-code-trial-todo-1`  
**Status**: ✅ Complete

## Overview

Successfully created 35 granular GitHub issues to break down major subtask categories into individually trackable items. This builds upon the previous hierarchical sub-task system by converting major work categories into standalone issues.

## Issue Hierarchy

The project now has a 3-tier issue tracking system:

### Tier 1: Parent Issues (12 issues)
Main goal-level issues that represent major project objectives:
- #1: 🎨 ASM Code Formatting
- #2: 📚 Basic Documentation
- #3: 🏷️ Memory Address & Variable Label System
- #4: 🖼️ Graphics Extraction Pipeline
- #5: 📦 Data Extraction Pipeline
- #6-#10: 🔍 Complete Code Disassembly (Banks 04, 05, 06, 0E, 0F)
- #11: 🔄 Asset Build System
- #12: 📚 Comprehensive System Documentation

### Tier 2: Granular Child Issues (35 issues - NEW)
Major subtask categories broken into trackable issues:

**Parent #1 - ASM Formatting** (5 child issues):
- #13: Prerequisites and Setup
- #14: Develop format_asm.ps1 Script
- #15: Testing and Validation
- #16: Format Priority 1 Banks (6 files)
- #17: Format Priority 2-3 Banks and Integration

**Parent #2 - Documentation** (5 child issues):
- #18: Planning and Templates
- #19: ARCHITECTURE.md - System Overview
- #20: BUILD_GUIDE.md - Building the ROM
- #21: MODDING_GUIDE.md - Game Modifications
- #22: CONTRIBUTING.md and Organization

**Parent #3 - Memory Labels** (9 child issues):
- #23: Address Inventory and Analysis
- #24: RAM Map Documentation
- #25: ROM Data Map Documentation
- #26: Label Naming Conventions
- #27: Label Replacement Tool Development
- #28: High Priority WRAM Labels
- #29: Medium Priority WRAM Labels
- #30: ROM Data Table Labels
- #31: Documentation and Maintenance

**Parent #4 - Graphics** (5 child issues):
- #32: Core Extraction Tools Development
- #33: Palette Management System
- #34: Character and Enemy Sprites Extraction
- #35: UI and Environmental Graphics Extraction
- #36: Asset Organization and Documentation

**Parent #5 - Data** (4 child issues):
- #37: Core Extraction Tools Development
- #38: Game Data Extraction (Characters, Enemies, Items)
- #39: Map and Text Extraction
- #40: Asset Organization and Documentation

**Parent #11 - Build System** (3 child issues):
- #41: Graphics and Data Import Tools
- #42: Build Orchestration and ROM Integrity
- #43: Round-Trip Testing and Documentation

**Parent #12 - Comprehensive Docs** (4 child issues):
- #44: System Architecture Documentation
- #45: Data Structures and Function Reference
- #46: Visual Documentation and Community Resources
- #47: Documentation Maintenance System

**Parent #6-#10** (Bank Disassembly):
- Not broken down into granular issues - already well-structured with detailed sub-tasks

### Tier 3: Detailed Sub-tasks (420+ items)
Checklist items in issue comments providing step-by-step implementation details.

## Total Tracking Items

- **47 GitHub Issues**: 12 parents + 35 children
- **420+ Sub-tasks**: Detailed checklists in comments
- **Total**: 467+ tracked items across 3 levels of granularity

## Created Scripts

### `tools/create_github_granular_issues.ps1`
**Purpose**: Create standalone GitHub issues for major subtask categories

**Features**:
- Creates 35 granular child issues with parent references
- Adds appropriate labels (priority, type, effort, requirements)
- Includes detailed description, task checklists, acceptance criteria, and effort estimates
- Dry-run mode for preview before execution
- Automatic parent-child linking via issue body references
- Rate limiting to avoid API throttling

**Key Fix Applied**:
- Filters out non-existent `parent: #N` labels during issue creation
- Ensures issues are created successfully with existing labels only
- Parent references maintained in issue body text

**Usage**:
```powershell
# Preview what will be created
.\tools\create_github_granular_issues.ps1 -DryRun

# Create all granular issues
.\tools\create_github_granular_issues.ps1
```

## Issue Structure

Each granular issue includes:

1. **Parent Reference**: Links back to the parent issue
2. **Description**: Clear explanation of the work category
3. **Task Checklist**: Specific actionable items
4. **Acceptance Criteria**: Definition of done
5. **Estimated Effort**: Time estimate for planning
6. **Related Issues**: Cross-references to dependencies
7. **Labels**: 
   - Priority (high/medium/low)
   - Type (formatting, documentation, tools, etc.)
   - Effort (large - for significant tasks)
   - Requirements (testing, review, etc.)

### Example Issue Structure

```markdown
**Parent Issue**: #3 🏷️ Memory Address & Variable Label System

## Description
Scan and catalog all raw memory addresses used in the codebase.

## Tasks
- [ ] Scan all ASM files for raw address patterns
- [ ] Categorize addresses by range (WRAM, ROM, Hardware)
- [ ] Count occurrences of each unique address
- [ ] Identify most-used addresses for priority labeling
- [ ] Create reports/address_usage_report.csv

## Acceptance Criteria
- All addresses catalogued
- Usage frequency calculated
- Report generated in CSV format
- Addresses categorized by type
- Priority list created

## Estimated Effort
4-6 hours

## Related
- Part of #3 (Memory Labels)
- Foundation for all labeling work
```

## Benefits of Granular Issues

### Tracking & Visibility
- ✅ Each major work category is individually trackable
- ✅ Better visibility on Kanban board (actual cards vs. comment checklists)
- ✅ Can see at a glance what's in progress, blocked, or completed
- ✅ Issue numbers in commits create better traceability

### Project Management
- ✅ Issues can be assigned to different team members
- ✅ Can apply additional labels to granular issues without affecting parents
- ✅ Close/reopen granular issues independently
- ✅ Team members can subscribe to specific granular issues
- ✅ GitHub automation works better with actual issues vs. comment checkboxes

### Organization
- ✅ Reduces overwhelming 420-item checklist into manageable chunks
- ✅ Clear separation between high-level goals, work categories, and detailed tasks
- ✅ Easier to identify blockers and dependencies at the right level
- ✅ Can track progress at multiple granularities (goal → category → task)

## Next Steps

1. **Manual Project Board Setup** (~5 minutes)
   - Add all 47 issues to the project board
   - Organize by parent/priority
   - Create columns: Backlog, Todo, In Progress, Review, Done

2. **Optional: Create Parent Labels**
   ```powershell
   # Create labels for parent-child tracking
   gh label create "parent: #1" --color "0E8A16"
   gh label create "parent: #2" --color "0E8A16"
   # ... etc for all parents
   ```

3. **Update Parent Issue Bodies**
   - Add "Child Issues" section to each parent
   - Link to all granular child issues
   - Example for Parent #1:
     ```markdown
     ## Child Issues
     - #13: Prerequisites and Setup
     - #14: Develop format_asm.ps1 Script
     - #15: Testing and Validation
     - #16: Format Priority 1 Banks (6 files)
     - #17: Format Priority 2-3 Banks and Integration
     ```

4. **Start Working on First Issues**
   - Recommended starting points:
     - #13: ASM Formatting: Prerequisites and Setup
     - #18: Documentation: Planning and Templates
     - #23: Memory Labels: Address Inventory and Analysis

## Files Created/Modified

### Created
- `tools/create_github_granular_issues.ps1` (1,308 lines)
  - PowerShell script to create 35 granular issues
  - Includes dry-run mode and comprehensive issue definitions

### Modified
- None (this is a new feature addition)

### Documentation
- `docs/GRANULAR_ISSUES_SUMMARY.md` (this file)
  - Summary of granular issues creation
  - Benefits and usage guide

## Git History

```
e01b9ce - Fix: Filter out non-existent parent labels in granular issues script
b31ed8a - Add create_github_granular_issues.ps1 script
```

## Repository Links

- **All Issues**: https://github.com/TheAnsarya/ffmq-info/issues
- **Parent Issues**: Filter by labels `priority: high`, `priority: medium`, `priority: low` and no number > #12
- **Granular Issues**: Issues #13-#47

## Statistics

- **Script Runtime**: ~20 seconds (35 issues × 0.5s rate limiting)
- **Lines of Code**: 1,308 lines in granular issues script
- **Total Issues Created**: 35 granular issues
- **Total Issues in Project**: 47 (12 parents + 35 children)
- **Average Tasks per Granular Issue**: 5-8 tasks
- **Estimated Total Effort**: 180-250 hours across all granular issues

## Related Documentation

- [GITHUB_SUB_ISSUES_GUIDE.md](GITHUB_SUB_ISSUES_GUIDE.md) - Guide for the sub-task comment system
- [GITHUB_SETUP_SUMMARY.md](GITHUB_SETUP_SUMMARY.md) - Complete project management overview
- [TODO.md](../TODO.md) - Master roadmap and task list (1,080 lines)

---

**Status**: ✅ All 35 granular issues successfully created  
**Branch**: `ai-code-trial-todo-1`  
**Committed**: November 1, 2025  
**Ready for**: Kanban board setup and task assignment
