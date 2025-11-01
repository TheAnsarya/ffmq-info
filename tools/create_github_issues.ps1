# GitHub Issues Creation Script for FFMQ Disassembly Project
# Prerequisites: Install GitHub CLI (gh) and authenticate: gh auth login

param(
    [switch]$DryRun = $false,
    [switch]$CreateProject = $true
)

$repo = "TheAnsarya/ffmq-info"

Write-Host "================================" -ForegroundColor Cyan
Write-Host "FFMQ GitHub Issues Creator" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host ""

if ($DryRun) {
    Write-Host "⚠️  DRY RUN MODE - No issues will be created" -ForegroundColor Yellow
    Write-Host ""
}

# Check if gh CLI is installed
try {
    $ghVersion = gh --version
    Write-Host "✓ GitHub CLI found: $($ghVersion[0])" -ForegroundColor Green
} catch {
    Write-Host "✗ GitHub CLI not found. Please install: https://cli.github.com/" -ForegroundColor Red
    exit 1
}

# Define all issues based on TODO.md
$issues = @(
    # IMMEDIATE PRIORITY (1-2 weeks)
    @{
        title = "🏷️ Finish Code Labeling - Bank 00 Section Files (68 labels)"
        body = @"
## Goal
Eliminate the final 68 CODE_* labels to achieve **100% campaign completion**! 🏆

## Current Status
- **95% complete** (1,539 → 68 labels remaining)
- All remaining labels are in Bank 00 section files (low priority files)

## Files to Complete
- [ ] ``bank_00_section2.asm`` - 8 labels (1-2 hours)
- [ ] ``bank_00_section3.asm`` - 10 labels (1-2 hours)
- [ ] ``bank_00_section4.asm`` - 20 labels (2-3 hours)
- [ ] ``bank_00_section5.asm`` - 30 labels (3-4 hours)

## Action Items
1. [ ] Analyze section files to understand their purpose
2. [ ] Determine if section files are critical or redundant
3. [ ] Create batch renaming strategy (PowerShell bulk replacement)
4. [ ] Execute label elimination for all 68 labels
5. [ ] Verify ROM match after each section completion
6. [ ] Update CAMPAIGN_PROGRESS.md to 100% completion
7. [ ] Celebrate milestone! 🎉

## Estimated Effort
**8-12 hours**

## Priority
**HIGH** - Near completion, major milestone

## References
- See ``TODO.md`` section 1
- See ``CAMPAIGN_PROGRESS.md`` for current stats
"@
        labels = @("priority: high", "type: code-labeling", "milestone: 100%")
        milestone = "100% Code Labels"
    },

    @{
        title = "🎨 ASM Code Formatting Standardization"
        body = @"
## Goal
Apply consistent formatting to all ASM files: CRLF, UTF-8, tabs (4 spaces display)

## Requirements
- **Line Endings**: CRLF (``\r\n``)
- **Encoding**: UTF-8
- **Indentation**: TABS (not spaces)
- **Tab Display**: 4 spaces per tab
- **Column Alignment**: Labels, opcodes, operands, comments

## Files to Format
- 6 Priority 1 banks (100% complete banks)
- 5 Priority 2 banks (documented banks)
- 4 Priority 3 banks (section files)
- 5 Priority 4 banks (undocumented, if exist)

## Action Items
1. [ ] Create ``.editorconfig`` file in repository root
2. [ ] Create ``tools/format_asm.ps1`` formatting script
   - Convert spaces → tabs intelligently
   - Ensure CRLF line endings
   - Verify UTF-8 encoding
   - Align columns properly
   - Dry-run mode with preview
3. [ ] Test on one file (``bank_00_documented.asm``)
4. [ ] Build ROM and verify 100% match
5. [ ] Apply to all Priority 1 files (6 banks)
6. [ ] Apply to Priority 2 & 3 files
7. [ ] Update build scripts to verify formatting
8. [ ] Document standards in README/CONTRIBUTING

## Estimated Effort
**16-24 hours**

## Priority
**HIGH** - Foundation for maintainability

## Critical
⚠️ **MUST maintain 100% ROM match throughout formatting!**

## References
- See ``TODO.md`` section 2
"@
        labels = @("priority: high", "type: formatting", "requires: testing")
    },

    @{
        title = "📚 Create Basic Documentation (Architecture, Build, Modding Guides)"
        body = @"
## Goal
Write essential documentation to enable contributors and modders

## Documents to Create
1. [ ] ``docs/ARCHITECTURE.md`` - High-level ROM overview
   - ROM layout (banks, contents)
   - Memory map (WRAM, SRAM, hardware registers)
   - System initialization
   - Main game loop
   - Inter-system communication

2. [ ] ``docs/BUILD_GUIDE.md`` - How to build the ROM
   - Prerequisites (Python, PowerShell, asar)
   - Step-by-step build instructions
   - Troubleshooting common errors
   - ROM integrity verification

3. [ ] ``docs/MODDING_GUIDE.md`` - Quick start for modders
   - Environment setup
   - Modifying character stats
   - Editing dialogue text
   - Replacing graphics
   - Adding new items/spells
   - Modifying maps
   - Common pitfalls

## Estimated Effort
**8-12 hours**

## Priority
**HIGH** - Enables collaboration

## References
- See ``TODO.md`` section 7
"@
        labels = @("priority: high", "type: documentation")
    },

    # SHORT-TERM PRIORITY (1-2 months)
    @{
        title = "🏷️ Memory Address & Variable Label System"
        body = @"
## Goal
Replace all raw memory addresses (``$xxxx``) with meaningful labels

## Categories
- **RAM Addresses**: Zero page, WRAM low, WRAM extended
- **ROM Addresses**: Code labels (95% done), Data labels (tables, graphics, text, music)
- **Hardware Registers**: PPU, DMA (verify consistent naming)

## Action Items
1. [ ] Inventory all address references
   - Scan ASM files for ``$xxxx`` patterns
   - Categorize by range (WRAM/ROM/Hardware)
   - Count occurrences (identify high-use addresses)
2. [ ] Create ``docs/RAM_MAP.md``
3. [ ] Create ``docs/ROM_DATA_MAP.md``
4. [ ] Define naming conventions (``docs/LABEL_CONVENTIONS.md``)
5. [ ] Create ``tools/apply_labels.ps1`` replacement tool
6. [ ] Apply labels systematically (start with most-used)
7. [ ] Verify ROM match after each batch

## Estimated Effort
**40-60 hours** (largest single task)

## Priority
**MEDIUM** - Improves code readability dramatically

## Challenge
Requires deep understanding of game logic for meaningful names

## References
- See ``TODO.md`` section 3
"@
        labels = @("priority: medium", "type: code-labeling", "effort: large")
    },

    @{
        title = "🖼️ Graphics Extraction Pipeline (PNG + JSON + Palettes)"
        body = @"
## Goal
Create robust extraction system for all ROM graphics assets

## Features
- Extract tiles (4bpp SNES format) → PNG + BIN + JSON
- Extract palettes (RGB555) → PNG swatches + JSON + CSS
- Generate sprite sheets with animation frames
- Render tilemaps (full screens/maps)
- Decompress compressed graphics
- Multiple views: individual sprites, sprite sheets, palette variants

## Assets to Extract
- [ ] Character sprites (Benjamin, Kaeli, Phoebe, Reuben)
- [ ] Enemy sprites (~100+ different sprites)
- [ ] Battle effects (magic, explosions, particles)
- [ ] UI graphics (fonts, windows, borders, cursors, icons)
- [ ] Environmental graphics (tilesets, animated tiles, backgrounds)
- [ ] All palettes with preview swatches

## Tools to Create
- [ ] ``tools/extract_graphics.py`` (comprehensive extractor)
- [ ] ``tools/palette_manager.py`` (palette tools)
- [ ] ``tools/graphics_catalog.py`` (asset scanner)
- [ ] ``tools/generate_asset_browser.py`` (HTML viewer)

## Estimated Effort
**60-80 hours**

## Priority
**MEDIUM** - Visible progress, community interest

## References
- See ``TODO.md`` section 5
"@
        labels = @("priority: medium", "type: graphics", "type: extraction", "effort: large")
    },

    @{
        title = "📦 Data Extraction Pipeline (JSON/CSV for all game data)"
        body = @"
## Goal
Extract all game data into modern formats (JSON, CSV)

## Data to Extract
- [ ] Character stats (base stats, growth curves, equipment)
- [ ] Enemy stats (HP, attack, defense, AI, drops)
- [ ] Item data (weapons, armor, accessories, consumables)
- [ ] Spell data (magic spells, MP cost, power, effects)
- [ ] Map data (layouts, collision, event triggers, NPCs)
- [ ] Shop inventories
- [ ] Text strings (dialogue, menus) - translation-friendly

## Tools to Create
- [ ] ``tools/extract_data.py`` (generic data extractor)
- [ ] ``tools/text_extractor.py`` (text decompression)
- [ ] ``tools/music_extractor.py`` (SPC700 music/sound)

## Output Formats
- JSON (structured data, tool-friendly)
- CSV (spreadsheet-friendly, translation)
- PO files (gettext translation format)

## Estimated Effort
**40-60 hours**

## Priority
**MEDIUM** - Enables ROM hacking, translation

## References
- See ``TODO.md`` section 5
"@
        labels = @("priority: medium", "type: data", "type: extraction", "effort: large")
    },

    # MID-TERM PRIORITY (3-6 months)
    @{
        title = "🔍 Complete Code Disassembly - Bank $04"
        body = @"
## Goal
Disassemble and document Bank $04 (Data Bank, ~4,000 lines estimated)

## Action Items
1. [ ] Run ``grep_search`` to identify code vs data regions
2. [ ] Look for subroutine entry points (JSR/JSL targets)
3. [ ] Create ``bank_04_documented.asm`` with initial analysis
4. [ ] Identify all CODE_04 labels
5. [ ] Document all functions and data structures
6. [ ] Verify ROM match

## Estimated Effort
**20-30 hours**

## Priority
**LOW** - Part of remaining banks completion

## References
- See ``TODO.md`` section 4
"@
        labels = @("priority: low", "type: disassembly", "bank: 04")
    },

    @{
        title = "🔍 Complete Code Disassembly - Bank $05"
        body = @"
## Goal
Disassemble and document Bank $05 (Data Bank, ~4,000 lines estimated)

## Action Items
1. [ ] Run ``grep_search`` to identify code vs data regions
2. [ ] Look for subroutine entry points (JSR/JSL targets)
3. [ ] Create ``bank_05_documented.asm`` with initial analysis
4. [ ] May be pure data (tables, stats, items, enemies)
5. [ ] Document all data structures
6. [ ] Verify ROM match

## Estimated Effort
**20-30 hours**

## Priority
**LOW** - Part of remaining banks completion

## References
- See ``TODO.md`` section 4
"@
        labels = @("priority: low", "type: disassembly", "bank: 05")
    },

    @{
        title = "🔍 Complete Code Disassembly - Bank $06"
        body = @"
## Goal
Disassemble and document Bank $06 (Data Bank, ~4,000 lines estimated)

## Action Items
1. [ ] Run ``grep_search`` to identify code vs data regions
2. [ ] Look for subroutine entry points (JSR/JSL targets)
3. [ ] Create ``bank_06_documented.asm`` with initial analysis
4. [ ] Possible music/sound data continuation
5. [ ] Document all data structures
6. [ ] Verify ROM match

## Estimated Effort
**20-30 hours**

## Priority
**LOW** - Part of remaining banks completion

## References
- See ``TODO.md`` section 4
"@
        labels = @("priority: low", "type: disassembly", "bank: 06")
    },

    @{
        title = "🔍 Complete Code Disassembly - Bank $0E"
        body = @"
## Goal
Disassemble and document Bank $0E (Unknown, ~5,000 lines estimated)

## Action Items
1. [ ] Initial exploration: search for JSR/RTS patterns (code) vs bulk data
2. [ ] Run ``grep_search`` to identify regions
3. [ ] Create ``bank_0E_documented.asm`` with analysis
4. [ ] Completely unknown - could be anything
5. [ ] Document all systems found
6. [ ] Verify ROM match

## Estimated Effort
**30-40 hours**

## Priority
**LOW** - Part of remaining banks completion

## References
- See ``TODO.md`` section 4
"@
        labels = @("priority: low", "type: disassembly", "bank: 0E")
    },

    @{
        title = "🔍 Complete Code Disassembly - Bank $0F"
        body = @"
## Goal
Disassemble and document Bank $0F (Unknown, ~5,000 lines estimated)

## Action Items
1. [ ] Initial exploration: search for JSR/RTS patterns (code) vs bulk data
2. [ ] Run ``grep_search`` to identify regions
3. [ ] Create ``bank_0F_documented.asm`` with analysis
4. [ ] Likely similar to $0E
5. [ ] May contain additional systems or overflow data
6. [ ] Verify ROM match

## Estimated Effort
**30-40 hours**

## Priority
**LOW** - Part of remaining banks completion

## References
- See ``TODO.md`` section 4
"@
        labels = @("priority: low", "type: disassembly", "bank: 0F")
    },

    @{
        title = "🔄 Asset Build System (Import Graphics/Data → ROM)"
        body = @"
## Goal
Create reverse transformation pipeline: modified assets → ROM format

## Components
1. [ ] ``tools/import_graphics.py`` - PNG → SNES tiles
2. [ ] ``tools/import_data.py`` - JSON/CSV → binary structs
3. [ ] ``tools/build_rom.py`` - orchestrate full build
4. [ ] Build modes: clean, incremental, validate, dry-run
5. [ ] Asset change detection (SHA256 hashes)
6. [ ] ``tools/rom_diff.py`` - compare ROMs byte-by-byte

## Critical Test
⚠️ **Round-trip integrity**: extract → import → identical ROM

This proves extraction/import are perfect inverses!

## Estimated Effort
**40-50 hours**

## Priority
**MEDIUM** - Completes the asset pipeline

## References
- See ``TODO.md`` section 6
"@
        labels = @("priority: medium", "type: build-system", "type: tools", "effort: large")
    },

    @{
        title = "📚 Comprehensive System Documentation"
        body = @"
## Goal
Document all major systems with architecture guides and diagrams

## Documents to Create
- [ ] ``docs/BATTLE_SYSTEM.md`` - Battle flow, damage formulas, AI
- [ ] ``docs/GRAPHICS_SYSTEM.md`` - PPU, tiles, palettes, sprites, VRAM
- [ ] ``docs/TEXT_SYSTEM.md`` - Compression, rendering, control codes
- [ ] ``docs/SOUND_SYSTEM.md`` - SPC700 driver, music, sound effects
- [ ] ``docs/MAP_SYSTEM.md`` - Map format, collision, events, NPCs
- [ ] ``docs/DATA_STRUCTURES.md`` - All struct definitions with examples
- [ ] ``docs/FUNCTION_REFERENCE.md`` - All 500+ functions documented

## Visual Documentation
- [ ] System diagrams (Mermaid or PNG)
- [ ] ROM bank layout diagram
- [ ] Memory map diagram
- [ ] State machine charts
- [ ] Data flow diagrams

## Estimated Effort
**80-120 hours**

## Priority
**LOW** - Time-consuming, but can be done incrementally

## References
- See ``TODO.md`` section 7
"@
        labels = @("priority: low", "type: documentation", "effort: large")
    }
)

# Create milestone if it doesn't exist
if (-not $DryRun) {
    Write-Host "Creating milestone: 100% Code Labels..." -ForegroundColor Cyan
    try {
        gh api repos/$repo/milestones -f title="100% Code Labels" -f description="Complete elimination of all CODE_* generic labels" -f state="open" 2>$null
        Write-Host "✓ Milestone created" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Milestone may already exist or couldn't be created" -ForegroundColor Yellow
    }
}

# Create labels if they don't exist
$labelsToCreate = @(
    @{name="priority: high"; color="d73a4a"; description="High priority task"},
    @{name="priority: medium"; color="fbca04"; description="Medium priority task"},
    @{name="priority: low"; color="0e8a16"; description="Low priority task"},
    @{name="type: code-labeling"; color="1d76db"; description="Code label replacement"},
    @{name="type: formatting"; color="5319e7"; description="Code formatting"},
    @{name="type: documentation"; color="0075ca"; description="Documentation"},
    @{name="type: graphics"; color="c2e0c6"; description="Graphics extraction/import"},
    @{name="type: data"; color="c5def5"; description="Data extraction/import"},
    @{name="type: extraction"; color="bfdadc"; description="Asset extraction"},
    @{name="type: disassembly"; color="e99695"; description="Code disassembly"},
    @{name="type: build-system"; color="f9d0c4"; description="Build system"},
    @{name="type: tools"; color="fef2c0"; description="Development tools"},
    @{name="effort: large"; color="d876e3"; description="Large time investment"},
    @{name="requires: testing"; color="ff6347"; description="Requires extensive testing"},
    @{name="milestone: 100%"; color="gold"; description="100% completion milestone"},
    @{name="bank: 04"; color="ededed"; description="Bank 04"},
    @{name="bank: 05"; color="ededed"; description="Bank 05"},
    @{name="bank: 06"; color="ededed"; description="Bank 06"},
    @{name="bank: 0E"; color="ededed"; description="Bank 0E"},
    @{name="bank: 0F"; color="ededed"; description="Bank 0F"}
)

if (-not $DryRun) {
    Write-Host "`nCreating labels..." -ForegroundColor Cyan
    foreach ($label in $labelsToCreate) {
        try {
            gh api repos/$repo/labels -f name="$($label.name)" -f color="$($label.color)" -f description="$($label.description)" 2>$null
            Write-Host "  ✓ Created: $($label.name)" -ForegroundColor Green
        } catch {
            Write-Host "  ⚠️  Label exists or couldn't be created: $($label.name)" -ForegroundColor Yellow
        }
    }
}

# Create issues
Write-Host "`nCreating issues..." -ForegroundColor Cyan
$createdIssues = @()

foreach ($issue in $issues) {
    Write-Host "`n📋 $($issue.title)" -ForegroundColor Yellow

    if ($DryRun) {
        Write-Host "  [DRY RUN] Would create issue with:" -ForegroundColor Gray
        Write-Host "    Labels: $($issue.labels -join ', ')" -ForegroundColor Gray
        if ($issue.milestone) {
            Write-Host "    Milestone: $($issue.milestone)" -ForegroundColor Gray
        }
        $createdIssues += @{title=$issue.title; number="[DRY RUN]"}
    } else {
        try {
            # Build gh issue create command
            $cmd = "gh issue create --repo $repo --title `"$($issue.title)`" --body `"$($issue.body)`""

            # Add labels
            if ($issue.labels) {
                foreach ($label in $issue.labels) {
                    $cmd += " --label `"$label`""
                }
            }

            # Add milestone if specified
            if ($issue.milestone) {
                $cmd += " --milestone `"$($issue.milestone)`""
            }

            # Execute command
            $result = Invoke-Expression $cmd

            # Extract issue number from result (format: https://github.com/owner/repo/issues/123)
            if ($result -match '/issues/(\d+)$') {
                $issueNumber = $Matches[1]
                Write-Host "  ✓ Created issue #$issueNumber" -ForegroundColor Green
                $createdIssues += @{title=$issue.title; number=$issueNumber; url=$result}
            }
        } catch {
            Write-Host "  ✗ Failed to create issue: $_" -ForegroundColor Red
        }
    }
}

# Summary
Write-Host "`n================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan
Write-Host "Total issues: $($issues.Count)" -ForegroundColor White
Write-Host "Created: $($createdIssues.Count)" -ForegroundColor Green

if ($createdIssues.Count -gt 0) {
    Write-Host "`nCreated Issues:" -ForegroundColor Cyan
    foreach ($issue in $createdIssues) {
        if ($issue.url) {
            Write-Host "  #$($issue.number): $($issue.title)" -ForegroundColor White
            Write-Host "    $($issue.url)" -ForegroundColor Gray
        } else {
            Write-Host "  $($issue.number): $($issue.title)" -ForegroundColor Gray
        }
    }
}

if ($CreateProject -and -not $DryRun) {
    Write-Host "`n================================" -ForegroundColor Cyan
    Write-Host "PROJECT BOARD SETUP" -ForegroundColor Cyan
    Write-Host "================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "To create a project board manually:" -ForegroundColor Yellow
    Write-Host "1. Go to: https://github.com/$repo/projects" -ForegroundColor White
    Write-Host "2. Click 'New project' → 'Board'" -ForegroundColor White
    Write-Host "3. Name it: 'FFMQ Disassembly Progress'" -ForegroundColor White
    Write-Host "4. Add columns: Backlog, Todo, In Progress, Review, Done" -ForegroundColor White
    Write-Host "5. Add all created issues to the board" -ForegroundColor White
    Write-Host ""
    Write-Host "Or use GitHub CLI (beta):" -ForegroundColor Yellow
    Write-Host "  gh project create --owner TheAnsarya --title 'FFMQ Disassembly Progress'" -ForegroundColor Gray
}

Write-Host "`n✅ Done!" -ForegroundColor Green
