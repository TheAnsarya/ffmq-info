#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Creates hierarchical sub-issues (task lists) for GitHub issues based on TODO.md

.DESCRIPTION
    This script creates detailed sub-tasks for each main GitHub issue by adding
    task list comments to each issue based on the hierarchical breakdown in TODO.md

.PARAMETER DryRun
    If specified, shows what would be created without making changes

.EXAMPLE
    .\create_github_sub_issues.ps1
    Creates all sub-task comments

.EXAMPLE
    .\create_github_sub_issues.ps1 -DryRun
    Shows what would be created without making changes
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

Write-Host "🔧 GitHub Sub-Issue Creator for FFMQ Disassembly Project" -ForegroundColor Cyan
Write-Host "=========================================================`n" -ForegroundColor Cyan

# Verify prerequisites
Test-GitHubCLI
$repo = Get-RepoName
Write-Host "✓ Repository: $repo`n" -ForegroundColor Green

if ($DryRun) {
    Write-Host "🔍 DRY RUN MODE - No changes will be made`n" -ForegroundColor Yellow
}

# Define sub-tasks for each main issue using here-strings to avoid quoting issues
$subTasks = @{
    "1" = @"
## Sub-Tasks Checklist

### Prerequisites
- [ ] Create .editorconfig file in repository root with ASM formatting rules
- [ ] Install/verify PowerShell 7+ for cross-platform script support
- [ ] Backup current ASM files before formatting changes

### Formatting Script Development
- [ ] Create tools/format_asm.ps1 - main formatting script
- [ ] Implement CRLF line ending conversion
- [ ] Implement UTF-8 encoding verification/conversion
- [ ] Implement space-to-tab conversion (intelligent, preserve alignment)
- [ ] Implement column alignment: labels (col 0), opcodes, operands, comments
- [ ] Add dry-run mode to preview changes without modification
- [ ] Add verbose output showing what would change

### Testing & Validation
- [ ] Test script on bank_00_documented.asm in dry-run mode
- [ ] Review diff output to verify correct formatting
- [ ] Apply formatting to test file
- [ ] Build ROM and verify 100% match with original
- [ ] Create test cases for edge cases (nested labels, special characters)

### Priority 1: Main Documented Banks (6 banks)
- [ ] Format src/asm/bank_00_documented.asm (~6,000 lines)
- [ ] Format src/asm/bank_01_documented.asm (9,671 lines)
- [ ] Format src/asm/bank_02_documented.asm (~9,000 lines)
- [ ] Format src/asm/bank_0B_documented.asm (~3,700 lines)
- [ ] Format src/asm/bank_0C_documented.asm (~4,200 lines)
- [ ] Format src/asm/bank_0D_documented.asm (~2,900 lines)
- [ ] Verify ROM match after each bank
- [ ] Commit each bank individually with clear message

### Priority 2: Other Documented Banks (5 banks)
- [ ] Format src/asm/bank_03_documented.asm (2,672 lines)
- [ ] Format src/asm/bank_07_documented.asm (2,307 lines)
- [ ] Format src/asm/bank_08_documented.asm (2,156 lines)
- [ ] Format src/asm/bank_09_documented.asm (2,083 lines)
- [ ] Format src/asm/bank_0A_documented.asm (2,058 lines)

### Priority 3: Bank 00 Sections (4 files)
- [ ] Format src/asm/bank_00_section2.asm
- [ ] Format src/asm/bank_00_section3.asm
- [ ] Format src/asm/bank_00_section4.asm
- [ ] Format src/asm/bank_00_section5.asm

### Build Integration & Documentation
- [ ] Add pre-build formatting check to build scripts
- [ ] Create formatting verification task in tasks.json
- [ ] Document formatting standards in CONTRIBUTING.md
- [ ] Add formatting instructions to README.md
- [ ] Create automated formatting GitHub Action (optional)

---
**Total: 36 sub-tasks** | See [TODO.md](TODO.md) for detailed context and estimates (16-24 hours)
"@

    "2" = @"
## Sub-Tasks Checklist

### Documentation Audit & Planning
- [ ] Inventory all existing docs in ~docs/ and docs/ directories
- [ ] Identify documentation gaps and outdated information
- [ ] Create prioritized list of docs to create/update
- [ ] Create documentation templates for consistency

### ARCHITECTURE.md - System Overview
- [ ] Document ROM bank layout (what each bank contains)
- [ ] Document memory map (WRAM, SRAM, hardware registers)
- [ ] Document system initialization and bootup sequence
- [ ] Document main game loop structure
- [ ] Document inter-system communication patterns
- [ ] Create system architecture diagram (Mermaid or PNG)
- [ ] Add cross-references to detailed system docs

### BUILD_GUIDE.md - Building the ROM
- [ ] Document prerequisites (Python, PowerShell, asar, git)
- [ ] Document step-by-step build instructions
- [ ] Document verification steps (ROM hash, test in emulator)
- [ ] Document troubleshooting for common build errors
- [ ] Document build options (incremental, clean, validate)
- [ ] Add platform-specific notes (Windows, Linux, macOS)

### MODDING_GUIDE.md - Modifying the Game
- [ ] Document how to set up development environment
- [ ] Document how to modify character stats (with examples)
- [ ] Document how to edit dialogue text
- [ ] Document how to replace graphics (tiles, sprites, palettes)
- [ ] Document how to add new items/spells
- [ ] Document how to modify maps
- [ ] Document common pitfalls and solutions
- [ ] Add example modifications with before/after screenshots

### CONTRIBUTING.md - Contribution Guidelines
- [ ] Document code style guidelines (ASM, Python, PowerShell)
- [ ] Document documentation standards
- [ ] Document how to submit changes (PR workflow)
- [ ] Document label naming conventions
- [ ] Document testing requirements
- [ ] Add commit message guidelines

### Documentation Index & Organization
- [ ] Create docs/README.md as documentation index
- [ ] Organize docs by category (Code, Systems, Data, Tutorials)
- [ ] Provide recommended reading order for newcomers
- [ ] Add links between related documentation files
- [ ] Update main README.md with link to docs

---
**Total: 37 sub-tasks** | See [TODO.md](TODO.md) for detailed context and estimates (8-12 hours)
"@

    "3" = @"
## Sub-Tasks Checklist

### Address Inventory & Analysis
- [ ] Scan all ASM files for raw address patterns
- [ ] Categorize addresses by range (WRAM, ROM, Hardware)
- [ ] Count occurrences of each unique address
- [ ] Identify most-used addresses for priority labeling
- [ ] Create reports/address_usage_report.csv

### RAM Map Documentation
- [ ] Create docs/RAM_MAP.md structure
- [ ] Document Zero Page variables ($00-$FF)
- [ ] Document WRAM variables ($0200-$1FFF)
- [ ] Document Extended RAM ($7E2000-$7FFFFF)
- [ ] Document variable size, type, purpose for each
- [ ] Note which banks/systems use each variable
- [ ] Add visual memory map diagram

### ROM Data Map Documentation
- [ ] Create docs/ROM_DATA_MAP.md structure
- [ ] List all DATA8/DATA16/ADDR tables per bank
- [ ] Document table structure, entry size, count
- [ ] Cross-reference with code that uses each table
- [ ] Identify graphics/text/sound data regions

### Label Naming Conventions
- [ ] Create docs/LABEL_CONVENTIONS.md
- [ ] Define RAM variable conventions (g_Global, s_Stat, f_Flag)
- [ ] Define ROM data conventions (DATA_Bank_Description, TBL_System_Type)
- [ ] Define pointer conventions (PTR_Target, ADDR_Destination)
- [ ] Define graphics conventions (GFX_Character_Animation, PAL_Scene)
- [ ] Define hardware register conventions (use standard SNES names)

### Label Replacement Tool Development
- [ ] Create tools/apply_labels.ps1 script
- [ ] Implement CSV/JSON input for address→label mappings
- [ ] Implement address replacement preserving context
- [ ] Handle different addressing modes (absolute/direct/long)
- [ ] Add dry-run mode with diff output
- [ ] Add verification: ROM must match after replacement

### Systematic Label Application - High Priority
- [ ] Label top 50 most-used WRAM addresses
- [ ] Label player character stat variables
- [ ] Label game state flags (progression, events)
- [ ] Label battle system variables
- [ ] Label graphics/PPU control variables
- [ ] Verify ROM match after each batch (~50 labels)

### Systematic Label Application - Medium Priority
- [ ] Label inventory/equipment variables
- [ ] Label menu system variables
- [ ] Label sound/music control variables
- [ ] Label map/collision variables
- [ ] Label remaining frequently-used addresses

### ROM Data Tables
- [ ] Label character data tables
- [ ] Label enemy data tables
- [ ] Label item/equipment data tables
- [ ] Label spell data tables
- [ ] Label pointer tables
- [ ] Label graphics data regions

### Documentation & Maintenance
- [ ] Keep RAM_MAP.md in sync with applied labels
- [ ] Add inline comments explaining complex data structures
- [ ] Create cross-reference index (label → addresses)
- [ ] Update ARCHITECTURE.md with memory organization
- [ ] Create label coverage report

---
**Total: 54 sub-tasks** | See [TODO.md](TODO.md) for detailed context and estimates (40-60 hours)
"@

    "4" = @"
## Sub-Tasks Checklist

### Core Graphics Extraction Tools
- [ ] Create tools/extract_graphics.py - main graphics extractor
- [ ] Implement tile extraction (2bpp/4bpp/8bpp formats)
- [ ] Implement palette extraction (RGB555→RGB888 conversion)
- [ ] Implement sprite sheet generation
- [ ] Implement tilemap rendering
- [ ] Implement compressed graphics decompression
- [ ] Add metadata JSON output for each asset

### Palette Management Tools
- [ ] Create tools/palette_manager.py
- [ ] Implement palette listing (all palettes with addresses)
- [ ] Implement palette extraction (BIN/PNG/JSON/CSS formats)
- [ ] Implement palette preview with sample graphics
- [ ] Implement palette association with graphics sets
- [ ] Generate HTML palette book visualization
- [ ] Add palette swap preview feature

### Graphics Cataloging
- [ ] Create tools/graphics_catalog.py
- [ ] Scan graphics banks ($07, $08, $09, $0A, $0B)
- [ ] Identify all graphics regions (tiles, palettes, sprites)
- [ ] Generate comprehensive catalog (JSON/CSV/Markdown)
- [ ] Identify uncatalogued regions for further analysis
- [ ] Create reports/graphics_catalog.json

### Character Sprites Extraction
- [ ] Extract Benjamin sprites (walk, battle, all directions)
- [ ] Extract Kaeli sprites (walk, battle, all directions)
- [ ] Extract Phoebe sprites (walk, battle, all directions)
- [ ] Extract Reuben sprites (walk, battle, all directions)
- [ ] Generate sprite sheets with all animations
- [ ] Generate individual PNGs per animation frame
- [ ] Create JSON metadata (frame size, palette refs, etc.)

### Enemy Sprites Extraction
- [ ] Extract all enemy sprites (~100+ enemies)
- [ ] Extract boss sprites (larger, multi-sprite)
- [ ] Generate enemy sprite sheets
- [ ] Extract animation frames (idle, attack, hurt, death)
- [ ] Create enemy graphics catalog with thumbnails

### Battle Effects Extraction
- [ ] Extract magic spell effects (White, Black, Wizard)
- [ ] Extract weapon strike effects
- [ ] Extract elemental effects (fire, ice, thunder, etc.)
- [ ] Extract status effect graphics
- [ ] Generate frame-by-frame animation sequences
- [ ] Create effects catalog with preview GIFs

### UI Graphics Extraction
- [ ] Extract fonts (dialogue, battle, menu fonts)
- [ ] Extract window graphics (borders, backgrounds)
- [ ] Extract cursors and selection indicators
- [ ] Extract icons (items, equipment, status icons)
- [ ] Extract UI gauges (HP, MP, experience bars)
- [ ] Generate UI asset catalog

### Environmental Graphics Extraction
- [ ] Extract terrain tilesets (grass, desert, snow, dungeon)
- [ ] Extract animated tiles (water, lava, waterfalls)
- [ ] Extract background layers (parallax scrolling elements)
- [ ] Extract Mode 7 textures (world map rotation)
- [ ] Generate tileset previews with assembled screens

### Palette Extraction
- [ ] Extract all color palettes with preview swatches
- [ ] Extract day/night palette variants
- [ ] Extract special effect palettes
- [ ] Extract palette animation sequences (color cycling)
- [ ] Generate palette catalog with visual samples

### Asset Organization & Documentation
- [ ] Create standardized assets/graphics/ directory structure
- [ ] Generate extraction_manifest.json master asset registry
- [ ] Create docs/GRAPHICS_EXTRACTION_REPORT.md
- [ ] Generate visual asset index (HTML with thumbnails)
- [ ] Document uncatalogued/unknown graphics regions
- [ ] Create statistics report (total tiles, palettes, coverage %)

---
**Total: 62 sub-tasks** | See [TODO.md](TODO.md) for detailed context and estimates (60-80 hours)
"@

    "5" = @"
## Sub-Tasks Checklist

### Core Data Extraction Tools
- [ ] Create tools/extract_data.py - generic data extractor
- [ ] Implement JSON schema-based structure definition
- [ ] Implement struct array extraction from ROM offset
- [ ] Implement multiple output formats (JSON/CSV/SQLite)
- [ ] Support nested structures and pointer handling
- [ ] Add compressed data decompression support

### Character Data Extraction
- [ ] Extract character base stats (HP, MP, Attack, Defense, etc.)
- [ ] Extract character growth curves
- [ ] Extract starting inventory and equipment
- [ ] Extract spell learning tables
- [ ] Generate data/characters.json and data/characters.csv
- [ ] Create character data schema (schemas/character.schema.json)

### Enemy Data Extraction
- [ ] Extract enemy stats (HP, Attack, Defense, Magic, Speed)
- [ ] Extract elemental affinities and resistances
- [ ] Extract status effect immunities
- [ ] Extract drop rates (items, gold, experience)
- [ ] Extract AI behavior patterns
- [ ] Generate data/enemies.json and data/enemies.csv
- [ ] Create enemy data schema (schemas/enemy.schema.json)

### Item & Equipment Data Extraction
- [ ] Extract weapon data (stats, effects, prices)
- [ ] Extract armor data (defense, resistances, prices)
- [ ] Extract accessory data (effects, restrictions)
- [ ] Extract consumable item data (effects, prices)
- [ ] Generate data/items.json and data/items.csv
- [ ] Create item data schema (schemas/item.schema.json)

### Spell & Magic Data Extraction
- [ ] Extract magic spell data (White, Black, Wizard)
- [ ] Extract MP costs and power values
- [ ] Extract elemental types and target types
- [ ] Extract animation references and status effects
- [ ] Generate data/spells.json and data/spells.csv
- [ ] Create spell data schema (schemas/spell.schema.json)

### Map Data Extraction
- [ ] Extract map layouts and dimensions
- [ ] Extract collision data
- [ ] Extract event triggers and scripts
- [ ] Extract NPC placements and dialogues
- [ ] Extract chest locations and contents
- [ ] Extract enemy encounter data
- [ ] Generate data/maps/*.json (one file per map)

### Shop & Economy Data
- [ ] Extract shop inventory tables
- [ ] Extract item prices per shop
- [ ] Extract shop availability/unlock conditions
- [ ] Generate data/shops.json

### Text & Dialogue Extraction
- [ ] Create tools/text_extractor.py specialized tool
- [ ] Implement FFMQ text decompression (dictionary-based)
- [ ] Parse text control codes ($F0-$FF) with descriptions
- [ ] Extract all dialogue strings
- [ ] Extract menu text and descriptions
- [ ] Generate data/text_en.json with ID→string mapping
- [ ] Export to translation-friendly formats (CSV, PO files)
- [ ] Generate text statistics report

### Asset Organization & Documentation
- [ ] Create standardized data/ directory structure
- [ ] Create JSON schemas for all data types
- [ ] Generate data/README.md explaining data files
- [ ] Create docs/DATA_STRUCTURES.md with detailed specs
- [ ] Document extraction process and data formats
- [ ] Create data coverage report

---
**Total: 50 sub-tasks** | See [TODO.md](TODO.md) for detailed context and estimates (40-60 hours)
"@

    "6" = @"
## Sub-Tasks Checklist

### Initial Analysis
- [ ] Run grep_search to identify code vs data regions
- [ ] Locate subroutine entry points (JSR/JSL targets)
- [ ] Identify data tables and structures
- [ ] Determine bank purpose and systems contained
- [ ] Create initial analysis report

### Code Documentation
- [ ] Create src/asm/bank_04_documented.asm
- [ ] Label all subroutines with descriptive names
- [ ] Add inline comments explaining logic
- [ ] Document function parameters and return values
- [ ] Document side effects and register usage

### Data Documentation
- [ ] Identify and label all data tables
- [ ] Document table structures and entry formats
- [ ] Create data extraction mappings
- [ ] Add data region comments

### Verification & Integration
- [ ] Build ROM and verify 100% match
- [ ] Update ROM_DATA_MAP.md with bank $04 data
- [ ] Update ARCHITECTURE.md with bank $04 systems
- [ ] Add cross-references to other banks
- [ ] Update CAMPAIGN_PROGRESS.md

---
**Total: 18 sub-tasks** | See [TODO.md](TODO.md) for detailed context and estimates (20-30 hours)
"@

    "7" = @"
## Sub-Tasks Checklist

### Initial Analysis
- [ ] Run grep_search to identify code vs data regions
- [ ] Locate subroutine entry points (JSR/JSL targets)
- [ ] Identify data tables and structures
- [ ] Determine bank purpose (likely data-heavy)
- [ ] Create initial analysis report

### Code Documentation
- [ ] Create src/asm/bank_05_documented.asm
- [ ] Label all subroutines with descriptive names
- [ ] Add inline comments explaining logic
- [ ] Document function parameters and return values

### Data Documentation
- [ ] Identify and label all data tables
- [ ] Document table structures (stats, items, enemies?)
- [ ] Create data extraction mappings
- [ ] Add comprehensive data comments

### Verification & Integration
- [ ] Build ROM and verify 100% match
- [ ] Update documentation (ROM_DATA_MAP, ARCHITECTURE)
- [ ] Add cross-references to other banks
- [ ] Update CAMPAIGN_PROGRESS.md

---
**Total: 16 sub-tasks** | See [TODO.md](TODO.md) for detailed context and estimates (20-30 hours)
"@

    "8" = @"
## Sub-Tasks Checklist

### Initial Analysis
- [ ] Run grep_search to identify code vs data regions
- [ ] Check for music/sound data continuation
- [ ] Identify data tables and structures
- [ ] Determine bank purpose
- [ ] Create initial analysis report

### Code Documentation
- [ ] Create src/asm/bank_06_documented.asm
- [ ] Label all subroutines with descriptive names
- [ ] Add inline comments explaining logic
- [ ] Document audio-related functions if present

### Data Documentation
- [ ] Identify and label all data tables
- [ ] Document music/sound data structures if present
- [ ] Create data extraction mappings
- [ ] Add data region comments

### Verification & Integration
- [ ] Build ROM and verify 100% match
- [ ] Update documentation (ROM_DATA_MAP, ARCHITECTURE)
- [ ] Add cross-references to other banks
- [ ] Update CAMPAIGN_PROGRESS.md

---
**Total: 16 sub-tasks** | See [TODO.md](TODO.md) for detailed context and estimates (20-30 hours)
"@

    "9" = @"
## Sub-Tasks Checklist

### Initial Exploration
- [ ] Scan for JSR/RTS patterns to identify code regions
- [ ] Scan for bulk data patterns
- [ ] Create ROM offset map for bank $0E
- [ ] Generate byte frequency analysis
- [ ] Determine likely contents (code, data, graphics, sound)

### Deep Analysis
- [ ] Trace all JSL/JSR calls into bank $0E
- [ ] Identify subroutine entry points
- [ ] Analyze data access patterns
- [ ] Determine bank purpose and system relationships

### Code Documentation
- [ ] Create src/asm/bank_0E_documented.asm
- [ ] Label all subroutines with descriptive names
- [ ] Add extensive inline comments (unknown bank)
- [ ] Document parameters, return values, side effects

### Data Documentation
- [ ] Identify and label all data regions
- [ ] Document data structures and formats
- [ ] Create extraction tools if needed
- [ ] Add comprehensive data comments

### Verification & Integration
- [ ] Build ROM and verify 100% match
- [ ] Update documentation extensively
- [ ] Add cross-references throughout codebase
- [ ] Update CAMPAIGN_PROGRESS.md

---
**Total: 20 sub-tasks** | See [TODO.md](TODO.md) for detailed context and estimates (30-40 hours)
"@

    "10" = @"
## Sub-Tasks Checklist

### Initial Exploration
- [ ] Scan for JSR/RTS patterns to identify code regions
- [ ] Scan for bulk data patterns
- [ ] Create ROM offset map for bank $0F
- [ ] Generate byte frequency analysis
- [ ] Compare patterns with bank $0E (likely similar)

### Deep Analysis
- [ ] Trace all JSL/JSR calls into bank $0F
- [ ] Identify subroutine entry points
- [ ] Analyze data access patterns
- [ ] Determine bank purpose (overflow from other banks?)

### Code Documentation
- [ ] Create src/asm/bank_0F_documented.asm
- [ ] Label all subroutines with descriptive names
- [ ] Add extensive inline comments
- [ ] Document parameters, return values, side effects

### Data Documentation
- [ ] Identify and label all data regions
- [ ] Document data structures and formats
- [ ] Create extraction tools if needed
- [ ] Add comprehensive data comments

### Verification & Integration
- [ ] Build ROM and verify 100% match
- [ ] Update all documentation
- [ ] Complete cross-referencing
- [ ] Final CAMPAIGN_PROGRESS.md update (100% disassembly!)

---
**Total: 20 sub-tasks** | See [TODO.md](TODO.md) for detailed context and estimates (30-40 hours)
"@

    "11" = @"
## Sub-Tasks Checklist

### Graphics Import Tool
- [ ] Create tools/import_graphics.py
- [ ] Implement PNG → SNES tiles conversion
- [ ] Implement palette import (RGB888 → RGB555)
- [ ] Implement sprite sheet → tile data conversion
- [ ] Implement graphics compression (match original format)
- [ ] Add validation (dimensions, color count, format)

### Data Import Tool
- [ ] Create tools/import_data.py
- [ ] Implement JSON/CSV → binary struct conversion
- [ ] Implement text compression for dialogue import
- [ ] Implement data validation against schemas
- [ ] Handle pointers and nested structures
- [ ] Add size validation (detect ROM space overflow)

### Build Orchestration
- [ ] Create tools/build_rom.py main build script
- [ ] Implement asset change detection (hash-based)
- [ ] Implement incremental build (only changed assets)
- [ ] Implement clean build (full rebuild)
- [ ] Implement validation mode (extensive checks)
- [ ] Add dry-run mode (preview without building)

### Build Workflow Integration
- [ ] Update build.ps1 to integrate asset import
- [ ] Create Makefile targets (extract/build/clean/verify)
- [ ] Create assets/metadata/asset_hashes.json system
- [ ] Implement build caching for faster rebuilds
- [ ] Add parallel processing for large asset batches

### ROM Integrity Tools
- [ ] Create tools/rom_diff.py - byte-level ROM comparison
- [ ] Implement checksum calculation and verification
- [ ] Implement ROM header validation
- [ ] Create ROM integrity report generator
- [ ] Add emulator compatibility checks

### Round-Trip Testing
- [ ] Extract all assets from original ROM
- [ ] Build ROM from extracted assets (no mods)
- [ ] Verify built ROM is 100% identical to original
- [ ] Debug any discrepancies in extract/import chain
- [ ] Document round-trip process in BUILD_GUIDE.md
- [ ] Create automated round-trip test script

### Build Documentation & Reporting
- [ ] Update BUILD_GUIDE.md with asset build workflow
- [ ] Document incremental vs clean builds
- [ ] Create build report format (modified assets, size, time)
- [ ] Add troubleshooting guide for build issues
- [ ] Document ROM space management (free space tracking)

---
**Total: 41 sub-tasks** | See [TODO.md](TODO.md) for detailed context and estimates (40-50 hours)
"@

    "12" = @"
## Sub-Tasks Checklist

### System Architecture Documentation
- [ ] Create docs/BATTLE_SYSTEM.md (flow, formulas, AI)
- [ ] Create docs/GRAPHICS_SYSTEM.md (PPU, tiles, sprites)
- [ ] Create docs/TEXT_SYSTEM.md (compression, rendering)
- [ ] Create docs/SOUND_SYSTEM.md (SPC700, music format)
- [ ] Create docs/MAP_SYSTEM.md (collision, events, NPCs)
- [ ] Add system diagrams (state machines, flowcharts)
- [ ] Cross-reference all systems with code locations

### Data Structure Documentation
- [ ] Expand docs/DATA_STRUCTURES.md with all structs
- [ ] Document character struct (byte offsets, fields)
- [ ] Document enemy struct (stats, AI, drops)
- [ ] Document item/spell structs
- [ ] Document map data structures
- [ ] Add C struct definitions for each
- [ ] Provide real ROM examples for each struct

### Function Reference Documentation
- [ ] Create docs/FUNCTION_REFERENCE.md
- [ ] Document all 500+ functions systematically
- [ ] Group by system (Battle, Graphics, Text, etc.)
- [ ] For each function: location, purpose, parameters, returns, side effects
- [ ] Add algorithm explanations and pseudo-code
- [ ] Cross-reference with calling functions
- [ ] Generate from code comments where possible

### Visual Documentation
- [ ] Create ROM bank layout diagram
- [ ] Create memory map diagram (WRAM/SRAM visual)
- [ ] Create battle system state machine diagram
- [ ] Create graphics pipeline flowchart
- [ ] Create text decompression flowchart
- [ ] Add annotated screenshots for tutorials
- [ ] Use Mermaid diagrams where possible

### Web Documentation (Optional Advanced)
- [ ] Create HTML asset browser (from extraction tools)
- [ ] Create searchable function reference (web interface)
- [ ] Create interactive ROM viewer with annotations
- [ ] Create visual data structure explorer
- [ ] Deploy documentation site (GitHub Pages?)
- [ ] Add search functionality across all docs

### Documentation Maintenance System
- [ ] Create documentation update checklist
- [ ] Add doc update reminders to PR template
- [ ] Establish monthly documentation review process
- [ ] Create documentation coverage reports
- [ ] Add automated doc generation where possible
- [ ] Set up documentation CI/CD checks

### Community Documentation
- [ ] Create FAQ.md for common questions
- [ ] Create EXAMPLES.md with modding examples
- [ ] Create CHANGELOG.md with version history
- [ ] Create ROADMAP.md for future plans
- [ ] Add video tutorials (optional)
- [ ] Create Discord/forum documentation guides

---
**Total: 51 sub-tasks** | See [TODO.md](TODO.md) for detailed context and estimates (80-120 hours)
"@
}

# Update each issue with sub-tasks
Write-Host "📝 Adding Sub-Task Checklists to GitHub Issues...`n" -ForegroundColor Cyan

$issueCount = 0
$errorCount = 0
$totalTasks = 0

foreach ($issueNum in $subTasks.Keys | Sort-Object { [int]$_ }) {
    $issueCount++
    $body = $subTasks[$issueNum]

    # Count tasks in this issue
    $taskMatches = ([regex]::Matches($body, "- \[ \]")).Count
    $totalTasks += $taskMatches

    Write-Host "[$issueCount] Issue #$issueNum - $taskMatches sub-tasks" -ForegroundColor Yellow

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would add comment to issue #$issueNum" -ForegroundColor Cyan
        Write-Host "  Preview (first 200 chars):" -ForegroundColor Gray
        Write-Host "  $($body.Substring(0, [Math]::Min(200, $body.Length)))..." -ForegroundColor DarkGray
        Write-Host ""
    }
    else {
        try {
            # Add comment with task list to the issue
            $tempFile = [System.IO.Path]::GetTempFileName()
            Set-Content -Path $tempFile -Value $body -NoNewline
            gh issue comment $issueNum --repo $repo --body-file $tempFile
            Remove-Item $tempFile

            Write-Host "  ✓ Added sub-task checklist comment" -ForegroundColor Green
            Start-Sleep -Milliseconds 500  # Rate limiting
        }
        catch {
            Write-Host "  ✗ Error: $_" -ForegroundColor Red
            $errorCount++
        }
    }
}

Write-Host "`n" + ("="*70) + "`n" -ForegroundColor Cyan
Write-Host "✨ Sub-Task Creation Summary" -ForegroundColor Green
Write-Host ("="*70) + "`n" -ForegroundColor Cyan

if ($DryRun) {
    Write-Host "🔍 DRY RUN Complete!" -ForegroundColor Yellow
    Write-Host "Would have updated $issueCount issues with $totalTasks total sub-tasks`n" -ForegroundColor Yellow
    Write-Host "Run without -DryRun to create actual comments" -ForegroundColor Yellow
}
else {
    Write-Host "✓ Updated $issueCount issues" -ForegroundColor Green
    Write-Host "✓ Added $totalTasks total sub-tasks across all issues" -ForegroundColor Green

    if ($errorCount -gt 0) {
        Write-Host "⚠ $errorCount errors encountered" -ForegroundColor Yellow
    }

    Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
    Write-Host "  1. View issues at: https://github.com/$repo/issues" -ForegroundColor White
    Write-Host "  2. Check off sub-tasks as you complete them" -ForegroundColor White
    Write-Host "  3. Close issues when all sub-tasks are done" -ForegroundColor White
    Write-Host "  4. Use project board to track overall progress`n" -ForegroundColor White
}

Write-Host "Done! 🎉" -ForegroundColor Green
