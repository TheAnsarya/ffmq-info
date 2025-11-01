#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates granular GitHub issues for each major subtask category

.DESCRIPTION
    This script creates individual GitHub issues for each major subtask category,
    converting the hierarchical sub-task lists into standalone tracked issues.
    Each parent issue gets child issues for its major categories.

.PARAMETER DryRun
    If specified, shows what would be created without making changes

.EXAMPLE
    .\create_github_granular_issues.ps1
    Creates all granular issues

.EXAMPLE
    .\create_github_granular_issues.ps1 -DryRun
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
        if ($remote -match "github\.com[:/](.+)/(.+?)(\.git)?$") {
            return "$($matches[1])/$($matches[2])"
        }
        throw "Could not parse repository name from git remote"
    }
    catch {
        Write-Error "Could not determine repository name: $_"
        exit 1
    }
}

Write-Host "🎯 GitHub Granular Issue Creator for FFMQ Disassembly Project" -ForegroundColor Cyan
Write-Host "================================================================`n" -ForegroundColor Cyan

# Verify prerequisites
Test-GitHubCLI
$repo = Get-RepoName
Write-Host "✓ Repository: $repo`n" -ForegroundColor Green

if ($dryRun) {
    Write-Host "🔍 DRY RUN MODE - No changes will be made`n" -ForegroundColor Yellow
}

# Define granular issues - each major subtask category becomes its own issue
$granularIssues = @(
    # Issue #1 - ASM Code Formatting - broken into 5 child issues
    @{
        parent = 1
        title = "ASM Formatting: Prerequisites and Setup"
        labels = @("priority: high", "type: formatting", "parent: #1")
        body = @"
**Parent Issue**: #1 🎨 ASM Code Formatting

## Description
Set up the prerequisites and tooling needed for ASM code formatting standardization.

## Tasks
- [ ] Create .editorconfig file in repository root with ASM formatting rules
- [ ] Install/verify PowerShell 7+ for cross-platform script support
- [ ] Backup current ASM files before formatting changes

## Acceptance Criteria
- .editorconfig file exists with correct ASM rules (CRLF, UTF-8, tabs)
- PowerShell 7+ installed and verified
- Backup of all ASM files created
- All team members can use the .editorconfig in their editors

## Estimated Effort
1-2 hours

## Related
- Part of #1 (ASM Code Formatting)
- See TODO.md section 2 for detailed requirements
"@
    },
    @{
        parent = 1
        title = "ASM Formatting: Develop format_asm.ps1 Script"
        labels = @("priority: high", "type: formatting", "type: tools", "parent: #1")
        body = @"
**Parent Issue**: #1 🎨 ASM Code Formatting

## Description
Create the main ASM formatting script with all required features.

## Tasks
- [ ] Create tools/format_asm.ps1 - main formatting script
- [ ] Implement CRLF line ending conversion
- [ ] Implement UTF-8 encoding verification/conversion
- [ ] Implement space-to-tab conversion (intelligent, preserve alignment)
- [ ] Implement column alignment: labels (col 0), opcodes, operands, comments
- [ ] Add dry-run mode to preview changes without modification
- [ ] Add verbose output showing what would change

## Acceptance Criteria
- Script exists and is executable
- All conversion features implemented and tested
- Dry-run mode works correctly
- Verbose output is helpful and accurate
- Script follows PowerShell best practices

## Estimated Effort
6-8 hours

## Related
- Part of #1 (ASM Code Formatting)
- Depends on Prerequisites issue
- See TODO.md section 2 for detailed requirements
"@
    },
    @{
        parent = 1
        title = "ASM Formatting: Testing and Validation"
        labels = @("priority: high", "type: formatting", "requires: testing", "parent: #1")
        body = @"
**Parent Issue**: #1 🎨 ASM Code Formatting

## Description
Test the formatting script thoroughly before applying to all files.

## Tasks
- [ ] Test script on bank_00_documented.asm in dry-run mode
- [ ] Review diff output to verify correct formatting
- [ ] Apply formatting to test file
- [ ] Build ROM and verify 100% match with original
- [ ] Create test cases for edge cases (nested labels, special characters)

## Acceptance Criteria
- Script tested on at least one bank file
- ROM build matches original 100% after formatting
- Edge cases identified and handled
- Test documentation created
- No regressions in ROM functionality

## Estimated Effort
2-3 hours

## Related
- Part of #1 (ASM Code Formatting)
- Depends on Script Development issue
- Critical: ROM match must be verified
"@
    },
    @{
        parent = 1
        title = "ASM Formatting: Format Priority 1 Banks (6 files)"
        labels = @("priority: high", "type: formatting", "effort: large", "parent: #1")
        body = @"
**Parent Issue**: #1 🎨 ASM Code Formatting

## Description
Apply formatting to the 6 main documented banks (those at 100% completion).

## Tasks
- [ ] Format src/asm/bank_00_documented.asm (~6,000 lines)
- [ ] Format src/asm/bank_01_documented.asm (9,671 lines)
- [ ] Format src/asm/bank_02_documented.asm (~9,000 lines)
- [ ] Format src/asm/bank_0B_documented.asm (~3,700 lines)
- [ ] Format src/asm/bank_0C_documented.asm (~4,200 lines)
- [ ] Format src/asm/bank_0D_documented.asm (~2,900 lines)
- [ ] Verify ROM match after each bank
- [ ] Commit each bank individually with clear message

## Acceptance Criteria
- All 6 banks formatted consistently
- ROM builds and matches original 100% after each bank
- Individual commits for each bank
- No code changes, only formatting

## Estimated Effort
4-6 hours

## Related
- Part of #1 (ASM Code Formatting)
- Depends on Testing issue
- Affects ~35,000 lines of code
"@
    },
    @{
        parent = 1
        title = "ASM Formatting: Format Priority 2-3 Banks and Integration"
        labels = @("priority: medium", "type: formatting", "parent: #1")
        body = @"
**Parent Issue**: #1 🎨 ASM Code Formatting

## Description
Format remaining banks and integrate formatting into build process.

## Priority 2 Banks (5 files)
- [ ] Format src/asm/bank_03_documented.asm (2,672 lines)
- [ ] Format src/asm/bank_07_documented.asm (2,307 lines)
- [ ] Format src/asm/bank_08_documented.asm (2,156 lines)
- [ ] Format src/asm/bank_09_documented.asm (2,083 lines)
- [ ] Format src/asm/bank_0A_documented.asm (2,058 lines)

## Priority 3 Sections (4 files)
- [ ] Format src/asm/bank_00_section2.asm
- [ ] Format src/asm/bank_00_section3.asm
- [ ] Format src/asm/bank_00_section4.asm
- [ ] Format src/asm/bank_00_section5.asm

## Build Integration
- [ ] Add pre-build formatting check to build scripts
- [ ] Create formatting verification task in tasks.json
- [ ] Document formatting standards in CONTRIBUTING.md
- [ ] Add formatting instructions to README.md
- [ ] Create automated formatting GitHub Action (optional)

## Estimated Effort
6-8 hours

## Related
- Part of #1 (ASM Code Formatting)
- Final formatting tasks
"@
    },

    # Issue #2 - Basic Documentation - broken into 5 child issues
    @{
        parent = 2
        title = "Documentation: Planning and Templates"
        labels = @("priority: high", "type: documentation", "parent: #2")
        body = @"
**Parent Issue**: #2 📚 Basic Documentation

## Description
Plan documentation structure and create reusable templates.

## Tasks
- [ ] Inventory all existing docs in ~docs/ and docs/ directories
- [ ] Identify documentation gaps and outdated information
- [ ] Create prioritized list of docs to create/update
- [ ] Create documentation templates for consistency

## Acceptance Criteria
- Complete inventory of existing documentation
- Gaps identified and prioritized
- Documentation templates created and approved
- Templates are reusable and well-structured

## Estimated Effort
2-3 hours

## Related
- Part of #2 (Basic Documentation)
- Foundation for all other documentation work
"@
    },
    @{
        parent = 2
        title = "Documentation: ARCHITECTURE.md - System Overview"
        labels = @("priority: high", "type: documentation", "parent: #2")
        body = @"
**Parent Issue**: #2 📚 Basic Documentation

## Description
Create comprehensive system architecture documentation.

## Tasks
- [ ] Document ROM bank layout (what each bank contains)
- [ ] Document memory map (WRAM, SRAM, hardware registers)
- [ ] Document system initialization and bootup sequence
- [ ] Document main game loop structure
- [ ] Document inter-system communication patterns
- [ ] Create system architecture diagram (Mermaid or PNG)
- [ ] Add cross-references to detailed system docs

## Acceptance Criteria
- ARCHITECTURE.md created and complete
- All major systems documented
- Architecture diagram included
- Cross-references to other docs added
- Reviewed and approved

## Estimated Effort
3-4 hours

## Related
- Part of #2 (Basic Documentation)
- Most important overview document
- See TODO.md section 7 for details
"@
    },
    @{
        parent = 2
        title = "Documentation: BUILD_GUIDE.md - Building the ROM"
        labels = @("priority: high", "type: documentation", "parent: #2")
        body = @"
**Parent Issue**: #2 📚 Basic Documentation

## Description
Create step-by-step build guide for contributors.

## Tasks
- [ ] Document prerequisites (Python, PowerShell, asar, git)
- [ ] Document step-by-step build instructions
- [ ] Document verification steps (ROM hash, test in emulator)
- [ ] Document troubleshooting for common build errors
- [ ] Document build options (incremental, clean, validate)
- [ ] Add platform-specific notes (Windows, Linux, macOS)

## Acceptance Criteria
- BUILD_GUIDE.md created and complete
- Instructions are clear and tested
- Prerequisites list is complete
- Troubleshooting section is helpful
- Works on all major platforms

## Estimated Effort
2-3 hours

## Related
- Part of #2 (Basic Documentation)
- Critical for new contributors
"@
    },
    @{
        parent = 2
        title = "Documentation: MODDING_GUIDE.md - Game Modifications"
        labels = @("priority: high", "type: documentation", "parent: #2")
        body = @"
**Parent Issue**: #2 📚 Basic Documentation

## Description
Create guide for modding and customizing the game.

## Tasks
- [ ] Document how to set up development environment
- [ ] Document how to modify character stats (with examples)
- [ ] Document how to edit dialogue text
- [ ] Document how to replace graphics (tiles, sprites, palettes)
- [ ] Document how to add new items/spells
- [ ] Document how to modify maps
- [ ] Document common pitfalls and solutions
- [ ] Add example modifications with before/after screenshots

## Acceptance Criteria
- MODDING_GUIDE.md created and complete
- Examples are clear and tested
- Screenshots included where helpful
- Common pitfalls documented
- Beginner-friendly

## Estimated Effort
3-4 hours

## Related
- Part of #2 (Basic Documentation)
- Enables community contributions
"@
    },
    @{
        parent = 2
        title = "Documentation: CONTRIBUTING.md and Organization"
        labels = @("priority: high", "type: documentation", "parent: #2")
        body = @"
**Parent Issue**: #2 📚 Basic Documentation

## Description
Create contribution guidelines and organize all documentation.

## CONTRIBUTING.md
- [ ] Document code style guidelines (ASM, Python, PowerShell)
- [ ] Document documentation standards
- [ ] Document how to submit changes (PR workflow)
- [ ] Document label naming conventions
- [ ] Document testing requirements
- [ ] Add commit message guidelines

## Documentation Organization
- [ ] Create docs/README.md as documentation index
- [ ] Organize docs by category (Code, Systems, Data, Tutorials)
- [ ] Provide recommended reading order for newcomers
- [ ] Add links between related documentation files
- [ ] Update main README.md with link to docs

## Estimated Effort
2-3 hours

## Related
- Part of #2 (Basic Documentation)
- Final documentation tasks
"@
    },

    # Issue #3 - Memory Labels - broken into 9 child issues (one per major category)
    @{
        parent = 3
        title = "Memory Labels: Address Inventory and Analysis"
        labels = @("priority: medium", "type: code-labeling", "parent: #3")
        body = @"
**Parent Issue**: #3 🏷️ Memory Address & Variable Labels

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
"@
    },
    @{
        parent = 3
        title = "Memory Labels: RAM Map Documentation"
        labels = @("priority: medium", "type: documentation", "parent: #3")
        body = @"
**Parent Issue**: #3 🏷️ Memory Address & Variable Labels

## Description
Document all RAM variables and create comprehensive RAM map.

## Tasks
- [ ] Create docs/RAM_MAP.md structure
- [ ] Document Zero Page variables (\$00-\$ff)
- [ ] Document WRAM variables (\$0200-\$1fff)
- [ ] Document Extended RAM (\$7e2000-\$7fffff)
- [ ] Document variable size, type, purpose for each
- [ ] Note which banks/systems use each variable
- [ ] Add visual memory map diagram

## Acceptance Criteria
- RAM_MAP.md created and complete
- All major RAM regions documented
- Visual diagram included
- Cross-references to code added
- Reviewed and accurate

## Estimated Effort
6-8 hours

## Related
- Part of #3 (Memory Labels)
- Critical reference document
"@
    },
    @{
        parent = 3
        title = "Memory Labels: ROM Data Map Documentation"
        labels = @("priority: medium", "type: documentation", "parent: #3")
        body = @"
**Parent Issue**: #3 🏷️ Memory Address & Variable Labels

## Description
Document all ROM data tables and structures.

## Tasks
- [ ] Create docs/ROM_DATA_MAP.md structure
- [ ] List all DATA8/DATA16/ADDR tables per bank
- [ ] Document table structure, entry size, count
- [ ] Cross-reference with code that uses each table
- [ ] Identify graphics/text/sound data regions

## Acceptance Criteria
- ROM_DATA_MAP.md created and complete
- All data tables catalogued
- Table structures documented
- Cross-references complete
- Graphics/text/sound regions identified

## Estimated Effort
6-8 hours

## Related
- Part of #3 (Memory Labels)
- Complements RAM_MAP.md
"@
    },
    @{
        parent = 3
        title = "Memory Labels: Label Naming Conventions"
        labels = @("priority: medium", "type: documentation", "parent: #3")
        body = @"
**Parent Issue**: #3 🏷️ Memory Address & Variable Labels

## Description
Define and document naming conventions for all label types.

## Tasks
- [ ] Create docs/LABEL_CONVENTIONS.md
- [ ] Define RAM variable conventions (g_Global, s_Stat, f_Flag)
- [ ] Define ROM data conventions (DATA_Bank_Description, TBL_System_Type)
- [ ] Define pointer conventions (PTR_Target, ADDR_Destination)
- [ ] Define graphics conventions (GFX_Character_Animation, PAL_Scene)
- [ ] Define hardware register conventions (use standard SNES names)

## Acceptance Criteria
- LABEL_CONVENTIONS.md created and approved
- All naming patterns documented with examples
- Conventions are consistent and clear
- Team agrees on conventions
- Easy to follow for contributors

## Estimated Effort
2-3 hours

## Related
- Part of #3 (Memory Labels)
- Must be complete before labeling starts
"@
    },
    @{
        parent = 3
        title = "Memory Labels: Label Replacement Tool Development"
        labels = @("priority: medium", "type: tools", "parent: #3")
        body = @"
**Parent Issue**: #3 🏷️ Memory Address & Variable Labels

## Description
Create automated tool for applying labels to code.

## Tasks
- [ ] Create tools/apply_labels.ps1 script
- [ ] Implement CSV/JSON input for address→label mappings
- [ ] Implement address replacement preserving context
- [ ] Handle different addressing modes (absolute/direct/long)
- [ ] Add dry-run mode with diff output
- [ ] Add verification: ROM must match after replacement

## Acceptance Criteria
- Script created and tested
- Supports multiple input formats
- Preserves code correctness
- Dry-run mode works
- ROM verification built-in
- Well-documented

## Estimated Effort
6-8 hours

## Related
- Part of #3 (Memory Labels)
- Critical tool for bulk labeling
"@
    },
    @{
        parent = 3
        title = "Memory Labels: High Priority WRAM Labels"
        labels = @("priority: medium", "type: code-labeling", "effort: large", "parent: #3")
        body = @"
**Parent Issue**: #3 🏷️ Memory Address & Variable Labels

## Description
Label the most frequently used WRAM variables.

## Tasks
- [ ] Label top 50 most-used WRAM addresses
- [ ] Label player character stat variables
- [ ] Label game state flags (progression, events)
- [ ] Label battle system variables
- [ ] Label graphics/PPU control variables
- [ ] Verify ROM match after each batch (~50 labels)

## Acceptance Criteria
- All high-priority WRAM addresses labeled
- Labels follow naming conventions
- ROM matches original after labeling
- Documentation updated
- Commits include label descriptions

## Estimated Effort
8-10 hours

## Related
- Part of #3 (Memory Labels)
- Highest impact labeling work
"@
    },
    @{
        parent = 3
        title = "Memory Labels: Medium Priority WRAM Labels"
        labels = @("priority: low", "type: code-labeling", "parent: #3")
        body = @"
**Parent Issue**: #3 🏷️ Memory Address & Variable Labels

## Description
Label remaining important WRAM variables.

## Tasks
- [ ] Label inventory/equipment variables
- [ ] Label menu system variables
- [ ] Label sound/music control variables
- [ ] Label map/collision variables
- [ ] Label remaining frequently-used addresses

## Acceptance Criteria
- All medium-priority WRAM addresses labeled
- Labels follow conventions
- ROM matches original
- Documentation updated

## Estimated Effort
6-8 hours

## Related
- Part of #3 (Memory Labels)
- Depends on high priority labels
"@
    },
    @{
        parent = 3
        title = "Memory Labels: ROM Data Table Labels"
        labels = @("priority: low", "type: code-labeling", "parent: #3")
        body = @"
**Parent Issue**: #3 🏷️ Memory Address & Variable Labels

## Description
Label all ROM data tables and structures.

## Tasks
- [ ] Label character data tables
- [ ] Label enemy data tables
- [ ] Label item/equipment data tables
- [ ] Label spell data tables
- [ ] Label pointer tables
- [ ] Label graphics data regions

## Acceptance Criteria
- All data tables labeled
- Labels descriptive and consistent
- ROM matches original
- ROM_DATA_MAP.md updated

## Estimated Effort
6-8 hours

## Related
- Part of #3 (Memory Labels)
- Completes ROM labeling
"@
    },
    @{
        parent = 3
        title = "Memory Labels: Documentation and Maintenance"
        labels = @("priority: low", "type: documentation", "parent: #3")
        body = @"
**Parent Issue**: #3 🏷️ Memory Address & Variable Labels

## Description
Keep documentation in sync with applied labels and create maintenance systems.

## Tasks
- [ ] Keep RAM_MAP.md in sync with applied labels
- [ ] Add inline comments explaining complex data structures
- [ ] Create cross-reference index (label → addresses)
- [ ] Update ARCHITECTURE.md with memory organization
- [ ] Create label coverage report

## Acceptance Criteria
- All documentation up to date
- Cross-references complete
- Coverage report generated
- Maintenance process documented
- Easy to keep in sync going forward

## Estimated Effort
4-6 hours

## Related
- Part of #3 (Memory Labels)
- Ongoing maintenance task
"@
    }

    # Note: Issues #4-12 would continue this pattern
    # For brevity, I'll create a representative sample for each major issue
)

# Add more granular issues for remaining parent issues
$granularIssues += @(
    # Issue #4 - Graphics Extraction
    @{
        parent = 4
        title = "Graphics: Core Extraction Tools Development"
        labels = @("priority: medium", "type: graphics", "type: tools", "parent: #4")
        body = @"
**Parent Issue**: #4 🖼️ Graphics Extraction Pipeline

## Description
Create the core graphics extraction tools.

## Tasks
- [ ] Create tools/extract_graphics.py - main graphics extractor
- [ ] Implement tile extraction (2bpp/4bpp/8bpp formats)
- [ ] Implement palette extraction (RGB555→RGB888 conversion)
- [ ] Implement sprite sheet generation
- [ ] Implement tilemap rendering
- [ ] Implement compressed graphics decompression
- [ ] Add metadata JSON output for each asset

## Estimated Effort
12-16 hours

## Related
- Part of #4 (Graphics Extraction)
"@
    },
    @{
        parent = 4
        title = "Graphics: Palette Management System"
        labels = @("priority: medium", "type: graphics", "type: tools", "parent: #4")
        body = @"
**Parent Issue**: #4 🖼️ Graphics Extraction Pipeline

## Description
Create comprehensive palette management tools.

## Tasks
- [ ] Create tools/palette_manager.py
- [ ] Implement palette listing (all palettes with addresses)
- [ ] Implement palette extraction (BIN/PNG/JSON/CSS formats)
- [ ] Implement palette preview with sample graphics
- [ ] Implement palette association with graphics sets
- [ ] Generate HTML palette book visualization
- [ ] Add palette swap preview feature

## Estimated Effort
8-10 hours

## Related
- Part of #4 (Graphics Extraction)
"@
    },
    @{
        parent = 4
        title = "Graphics: Character and Enemy Sprites Extraction"
        labels = @("priority: medium", "type: graphics", "type: extraction", "effort: large", "parent: #4")
        body = @"
**Parent Issue**: #4 🖼️ Graphics Extraction Pipeline

## Description
Extract all character and enemy sprites.

## Character Sprites
- [ ] Extract Benjamin sprites (walk, battle, all directions)
- [ ] Extract Kaeli sprites (walk, battle, all directions)
- [ ] Extract Phoebe sprites (walk, battle, all directions)
- [ ] Extract Reuben sprites (walk, battle, all directions)
- [ ] Generate sprite sheets with all animations
- [ ] Generate individual PNGs per animation frame
- [ ] Create JSON metadata (frame size, palette refs, etc.)

## Enemy Sprites
- [ ] Extract all enemy sprites (~100+ enemies)
- [ ] Extract boss sprites (larger, multi-sprite)
- [ ] Generate enemy sprite sheets
- [ ] Extract animation frames (idle, attack, hurt, death)
- [ ] Create enemy graphics catalog with thumbnails

## Estimated Effort
16-20 hours

## Related
- Part of #4 (Graphics Extraction)
"@
    },
    @{
        parent = 4
        title = "Graphics: UI and Environmental Graphics Extraction"
        labels = @("priority: medium", "type: graphics", "type: extraction", "parent: #4")
        body = @"
**Parent Issue**: #4 🖼️ Graphics Extraction Pipeline

## Description
Extract all UI elements and environmental graphics.

## UI Graphics
- [ ] Extract fonts (dialogue, battle, menu fonts)
- [ ] Extract window graphics (borders, backgrounds)
- [ ] Extract cursors and selection indicators
- [ ] Extract icons (items, equipment, status icons)
- [ ] Extract UI gauges (HP, MP, experience bars)
- [ ] Generate UI asset catalog

## Environmental Graphics
- [ ] Extract terrain tilesets (grass, desert, snow, dungeon)
- [ ] Extract animated tiles (water, lava, waterfalls)
- [ ] Extract background layers (parallax scrolling elements)
- [ ] Extract Mode 7 textures (world map rotation)
- [ ] Generate tileset previews with assembled screens

## Estimated Effort
12-16 hours

## Related
- Part of #4 (Graphics Extraction)
"@
    },
    @{
        parent = 4
        title = "Graphics: Asset Organization and Documentation"
        labels = @("priority: medium", "type: graphics", "type: documentation", "parent: #4")
        body = @"
**Parent Issue**: #4 🖼️ Graphics Extraction Pipeline

## Description
Organize extracted assets and create comprehensive documentation.

## Tasks
- [ ] Create standardized assets/graphics/ directory structure
- [ ] Generate extraction_manifest.json master asset registry
- [ ] Create docs/GRAPHICS_EXTRACTION_REPORT.md
- [ ] Generate visual asset index (HTML with thumbnails)
- [ ] Document uncatalogued/unknown graphics regions
- [ ] Create statistics report (total tiles, palettes, coverage %)

## Estimated Effort
6-8 hours

## Related
- Part of #4 (Graphics Extraction)
"@
    },

    # Issue #5 - Data Extraction
    @{
        parent = 5
        title = "Data: Core Extraction Tools Development"
        labels = @("priority: medium", "type: data", "type: tools", "parent: #5")
        body = @"
**Parent Issue**: #5 📦 Data Extraction Pipeline

## Description
Create the core data extraction framework.

## Tasks
- [ ] Create tools/extract_data.py - generic data extractor
- [ ] Implement JSON schema-based structure definition
- [ ] Implement struct array extraction from ROM offset
- [ ] Implement multiple output formats (JSON/CSV/SQLite)
- [ ] Support nested structures and pointer handling
- [ ] Add compressed data decompression support

## Estimated Effort
10-12 hours

## Related
- Part of #5 (Data Extraction)
"@
    },
    @{
        parent = 5
        title = "Data: Game Data Extraction (Characters, Enemies, Items)"
        labels = @("priority: medium", "type: data", "type: extraction", "effort: large", "parent: #5")
        body = @"
**Parent Issue**: #5 📦 Data Extraction Pipeline

## Description
Extract all character, enemy, and item data.

## Character Data
- [ ] Extract character base stats (HP, MP, Attack, Defense, etc.)
- [ ] Extract character growth curves
- [ ] Extract starting inventory and equipment
- [ ] Extract spell learning tables
- [ ] Generate data/characters.json and CSV
- [ ] Create character data schema

## Enemy Data
- [ ] Extract enemy stats (HP, Attack, Defense, Magic, Speed)
- [ ] Extract elemental affinities and resistances
- [ ] Extract status effect immunities
- [ ] Extract drop rates (items, gold, experience)
- [ ] Extract AI behavior patterns
- [ ] Generate data/enemies.json and CSV
- [ ] Create enemy data schema

## Item & Equipment Data
- [ ] Extract weapon/armor/accessory data
- [ ] Extract consumable item data
- [ ] Generate data/items.json and CSV
- [ ] Create item data schema

## Estimated Effort
14-18 hours

## Related
- Part of #5 (Data Extraction)
"@
    },
    @{
        parent = 5
        title = "Data: Map and Text Extraction"
        labels = @("priority: medium", "type: data", "type: extraction", "parent: #5")
        body = @"
**Parent Issue**: #5 📦 Data Extraction Pipeline

## Description
Extract all map data and text/dialogue.

## Map Data
- [ ] Extract map layouts and dimensions
- [ ] Extract collision data
- [ ] Extract event triggers and scripts
- [ ] Extract NPC placements and dialogues
- [ ] Extract chest locations and contents
- [ ] Extract enemy encounter data
- [ ] Generate data/maps/*.json

## Text & Dialogue
- [ ] Create tools/text_extractor.py specialized tool
- [ ] Implement FFMQ text decompression
- [ ] Parse text control codes with descriptions
- [ ] Extract all dialogue strings
- [ ] Generate data/text_en.json with ID→string mapping
- [ ] Export to translation formats (CSV, PO files)
- [ ] Generate text statistics report

## Estimated Effort
12-16 hours

## Related
- Part of #5 (Data Extraction)
"@
    },
    @{
        parent = 5
        title = "Data: Asset Organization and Documentation"
        labels = @("priority: medium", "type: data", "type: documentation", "parent: #5")
        body = @"
**Parent Issue**: #5 📦 Data Extraction Pipeline

## Description
Organize extracted data and create schemas and documentation.

## Tasks
- [ ] Create standardized data/ directory structure
- [ ] Create JSON schemas for all data types
- [ ] Generate data/README.md explaining data files
- [ ] Create docs/DATA_STRUCTURES.md with detailed specs
- [ ] Document extraction process and data formats
- [ ] Create data coverage report

## Estimated Effort
6-8 hours

## Related
- Part of #5 (Data Extraction)
"@
    },

    # Issues #6-10 are bank disassembly - already well-structured, minimal breakdown needed
    # Just add a tracking issue for each

    # Issue #11 - Asset Build System
    @{
        parent = 11
        title = "Build System: Graphics and Data Import Tools"
        labels = @("priority: medium", "type: build-system", "type: tools", "parent: #11")
        body = @"
**Parent Issue**: #11 🔄 Asset Build System

## Description
Create tools to import modified assets back into ROM format.

## Graphics Import
- [ ] Create tools/import_graphics.py
- [ ] Implement PNG → SNES tiles conversion
- [ ] Implement palette import (RGB888 → RGB555)
- [ ] Implement sprite sheet → tile data conversion
- [ ] Implement graphics compression
- [ ] Add validation

## Data Import
- [ ] Create tools/import_data.py
- [ ] Implement JSON/CSV → binary struct conversion
- [ ] Implement text compression for dialogue
- [ ] Implement data validation against schemas
- [ ] Handle pointers and nested structures
- [ ] Add size validation

## Estimated Effort
12-16 hours

## Related
- Part of #11 (Asset Build System)
"@
    },
    @{
        parent = 11
        title = "Build System: Build Orchestration and ROM Integrity"
        labels = @("priority: medium", "type: build-system", "requires: testing", "parent: #11")
        body = @"
**Parent Issue**: #11 🔄 Asset Build System

## Description
Create the main build orchestration system and integrity verification.

## Build Orchestration
- [ ] Create tools/build_rom.py main build script
- [ ] Implement asset change detection (hash-based)
- [ ] Implement incremental build (only changed assets)
- [ ] Implement clean build (full rebuild)
- [ ] Implement validation mode
- [ ] Add dry-run mode

## Build Integration
- [ ] Update build.ps1 to integrate asset import
- [ ] Create Makefile targets
- [ ] Create asset hashing system
- [ ] Implement build caching
- [ ] Add parallel processing

## ROM Integrity
- [ ] Create tools/rom_diff.py
- [ ] Implement checksum verification
- [ ] Implement ROM header validation
- [ ] Create integrity report generator
- [ ] Add emulator compatibility checks

## Estimated Effort
14-18 hours

## Related
- Part of #11 (Asset Build System)
"@
    },
    @{
        parent = 11
        title = "Build System: Round-Trip Testing and Documentation"
        labels = @("priority: medium", "type: build-system", "requires: testing", "parent: #11")
        body = @"
**Parent Issue**: #11 🔄 Asset Build System

## Description
Verify complete round-trip integrity and document the build system.

## Round-Trip Testing
- [ ] Extract all assets from original ROM
- [ ] Build ROM from extracted assets (no mods)
- [ ] Verify built ROM is 100% identical to original
- [ ] Debug any discrepancies
- [ ] Document round-trip process in BUILD_GUIDE.md
- [ ] Create automated round-trip test script

## Build Documentation
- [ ] Update BUILD_GUIDE.md with asset build workflow
- [ ] Document incremental vs clean builds
- [ ] Create build report format
- [ ] Add troubleshooting guide
- [ ] Document ROM space management

## Estimated Effort
8-12 hours

## Related
- Part of #11 (Asset Build System)
- Critical: Round-trip must be perfect
"@
    },

    # Issue #12 - Comprehensive Documentation
    @{
        parent = 12
        title = "Docs: System Architecture Documentation"
        labels = @("priority: low", "type: documentation", "effort: large", "parent: #12")
        body = @"
**Parent Issue**: #12 📚 Comprehensive Documentation

## Description
Create detailed system architecture documentation for all major systems.

## Tasks
- [ ] Create docs/BATTLE_SYSTEM.md (flow, formulas, AI)
- [ ] Create docs/GRAPHICS_SYSTEM.md (PPU, tiles, sprites)
- [ ] Create docs/TEXT_SYSTEM.md (compression, rendering)
- [ ] Create docs/SOUND_SYSTEM.md (SPC700, music format)
- [ ] Create docs/MAP_SYSTEM.md (collision, events, NPCs)
- [ ] Add system diagrams (state machines, flowcharts)
- [ ] Cross-reference all systems with code locations

## Estimated Effort
20-30 hours

## Related
- Part of #12 (Comprehensive Documentation)
"@
    },
    @{
        parent = 12
        title = "Docs: Data Structures and Function Reference"
        labels = @("priority: low", "type: documentation", "effort: large", "parent: #12")
        body = @"
**Parent Issue**: #12 📚 Comprehensive Documentation

## Description
Document all data structures and create complete function reference.

## Data Structures
- [ ] Expand docs/DATA_STRUCTURES.md
- [ ] Document all major structs (character, enemy, item, etc.)
- [ ] Add C struct definitions
- [ ] Provide real ROM examples

## Function Reference
- [ ] Create docs/FUNCTION_REFERENCE.md
- [ ] Document all 500+ functions
- [ ] Group by system
- [ ] Include: location, purpose, parameters, returns, side effects
- [ ] Add algorithm explanations
- [ ] Cross-reference calling functions
- [ ] Generate from code comments where possible

## Estimated Effort
30-40 hours

## Related
- Part of #12 (Comprehensive Documentation)
- Largest documentation effort
"@
    },
    @{
        parent = 12
        title = "Docs: Visual Documentation and Community Resources"
        labels = @("priority: low", "type: documentation", "parent: #12")
        body = @"
**Parent Issue**: #12 📚 Comprehensive Documentation

## Description
Create visual documentation and community-facing resources.

## Visual Documentation
- [ ] Create ROM bank layout diagram
- [ ] Create memory map diagram
- [ ] Create battle system state machine diagram
- [ ] Create graphics pipeline flowchart
- [ ] Create text decompression flowchart
- [ ] Add annotated screenshots
- [ ] Use Mermaid diagrams where possible

## Web Documentation (Optional)
- [ ] Create HTML asset browser
- [ ] Create searchable function reference
- [ ] Create interactive ROM viewer
- [ ] Deploy documentation site (GitHub Pages?)
- [ ] Add search functionality

## Community Documentation
- [ ] Create FAQ.md
- [ ] Create EXAMPLES.md with modding examples
- [ ] Create CHANGELOG.md
- [ ] Create ROADMAP.md
- [ ] Add video tutorials (optional)

## Estimated Effort
20-30 hours

## Related
- Part of #12 (Comprehensive Documentation)
"@
    },
    @{
        parent = 12
        title = "Docs: Documentation Maintenance System"
        labels = @("priority: low", "type: documentation", "parent: #12")
        body = @"
**Parent Issue**: #12 📚 Comprehensive Documentation

## Description
Establish ongoing documentation maintenance processes.

## Tasks
- [ ] Create documentation update checklist
- [ ] Add doc update reminders to PR template
- [ ] Establish monthly documentation review process
- [ ] Create documentation coverage reports
- [ ] Add automated doc generation where possible
- [ ] Set up documentation CI/CD checks

## Estimated Effort
8-12 hours

## Related
- Part of #12 (Comprehensive Documentation)
- Ensures docs stay current
"@
    }
)

# Create all granular issues
Write-Host "📝 Creating Granular GitHub Issues...`n" -ForegroundColor Cyan

$issueCount = 0
$errorCount = 0
$createdIssues = @()

foreach ($issueData in $granularIssues) {
    $issueCount++
    $parentNum = $issueData.parent
    $title = $issueData.title
    $labels = $issueData.labels -join ","
    $body = $issueData.body

    Write-Host "[$issueCount] Creating: $title" -ForegroundColor Yellow
    Write-Host "  Parent: #$parentNum | Labels: $($issueData.labels -join ', ')" -ForegroundColor Gray

    if ($dryRun) {
        Write-Host "  [DRY RUN] Would create issue" -ForegroundColor Cyan
        Write-Host "  Preview (first 150 chars of body):" -ForegroundColor Gray
        Write-Host "  $($body.Substring(0, [Math]::Min(150, $body.Length)))..." -ForegroundColor DarkGray
        Write-Host ""
        $createdIssues += @{ number = "DRY-RUN-$issueCount"; title = $title; parent = $parentNum }
    }
    else {
        try {
            # Create the issue
            $tempFile = [System.IO.Path]::GetTempFileName()
            Set-Content -Path $tempFile -Value $body -NoNewline

            # Filter out parent labels (they don't exist yet in the repo)
            $existingLabels = $labels -split "," | Where-Object { $_ -notmatch "parent:" } | ForEach-Object { $_.Trim() }
            $labelString = $existingLabels -join ","

            $result = gh issue create `
                --repo $repo `
                --title $title `
                --body-file $tempFile `
                --label $labelString

            Remove-Item $tempFile

            # Extract issue number from result (format: "https://github.com/owner/repo/issues/123")
            if ($result -match "/issues/(\d+)") {
                $issueNumber = $matches[1]
                Write-Host "  ✓ Created issue #$issueNumber" -ForegroundColor Green
                Write-Host "  $result" -ForegroundColor DarkGray
                $createdIssues += @{ number = $issueNumber; title = $title; parent = $parentNum }
            }

            Start-Sleep -Milliseconds 500  # Rate limiting
        }
        catch {
            Write-Host "  ✗ Error: $_" -ForegroundColor Red
            $errorCount++
        }
    }
}

Write-Host "`n" + ("="*70) + "`n" -ForegroundColor Cyan
Write-Host "✨ Granular Issue Creation Summary" -ForegroundColor Green
Write-Host ("="*70) + "`n" -ForegroundColor Cyan

if ($dryRun) {
    Write-Host "🔍 DRY RUN Complete!" -ForegroundColor Yellow
    Write-Host "Would have created $issueCount granular issues`n" -ForegroundColor Yellow
} else {
    Write-Host "✓ Created $issueCount granular issues" -ForegroundColor Green

    if ($errorCount -gt 0) {
        Write-Host "⚠ $errorCount errors encountered`n" -ForegroundColor Yellow
    }

    Write-Host "`n📊 Issues Created by Parent:" -ForegroundColor Cyan
    $createdIssues | Group-Object -Property parent | Sort-Object Name | ForEach-Object {
        Write-Host "  Parent #$($_.Name): $($_.Count) child issues" -ForegroundColor White
    }

    Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. View all issues at: https://github.com/$repo/issues" -ForegroundColor White
    Write-Host "  2. Add these granular issues to your project board" -ForegroundColor White
    Write-Host "  3. Link child issues to parent issues in descriptions" -ForegroundColor White
    Write-Host "  4. Start working on individual granular tasks`n" -ForegroundColor White
}

Write-Host "Done! 🎉" -ForegroundColor Green
