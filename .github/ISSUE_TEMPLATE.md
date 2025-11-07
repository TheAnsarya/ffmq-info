# DataCrystal ROM Map Documentation Enhancement

## Issue Description

Enhance the DataCrystal wiki ROM map documentation to provide comprehensive, detailed mapping tables for all code blocks and data structures across all ROM banks ($00-$0F).

## Current State

The existing `ROM_map.wikitext` file has:
- ✅ Basic data structure listings with addresses
- ✅ Subpages for specific data types (Enemies, Attacks, Graphics, Maps, Menus, Sound, Characters)
- ⚠️ Limited detail on code organization by bank
- ⚠️ No comprehensive "all-in-one" ROM map table
- ⚠️ Missing detailed bank-by-bank code breakdowns

## Goals

### 1. Enhanced Subpages (More Detail)
Update existing subpages with more detailed tables showing:
- **Start Address** - **End Address** - **Size** - **Type** - **Description**
- Cross-references to disassembly source files
- Function counts and categories
- Technical details (compression, formats, etc.)

### 2. New ROM_map/Code Subpage
Create `ROM_map/Code.wikitext` documenting all 16 banks:
- Bank number and address range
- Total size and code/data breakdown
- Major systems and subsystems
- Function categories
- Links to documented source files

### 3. New ROM_map/Complete Subpage
Create `ROM_map/Complete.wikitext` (or `ROM_map/All.wikitext`) with:
- **Single comprehensive table** covering the entire ROM (000000-07FFFF)
- Every significant data structure and code block
- Sortable/searchable format
- Complete cross-references

## Implementation Plan

### Phase 1: Analyze Source Structure
- [x] Review all bank_XX_documented.asm files
- [ ] Extract address ranges for all major sections
- [ ] Categorize code vs data blocks
- [ ] Document system boundaries

### Phase 2: Enhance Existing Subpages
- [ ] ROM_map/Enemies - Add detailed offset tables
- [ ] ROM_map/Attacks - Add damage formula breakdowns
- [ ] ROM_map/Graphics - Add compression format details
- [ ] ROM_map/Maps - Add full map database tables
- [ ] ROM_map/Menus - Add window system tables
- [ ] ROM_map/Sound - Add SPC driver structure
- [ ] ROM_map/Characters - Add stat progression tables

### Phase 3: Create ROM_map/Code
- [ ] Bank $00 - Main Engine
- [ ] Bank $01 - Battle System
- [ ] Bank $02 - System Management
- [ ] Bank $03-$06 - Game Data
- [ ] Bank $07 - Animation
- [ ] Bank $08-$09 - Graphics
- [ ] Bank $0A-$0C - More Data
- [ ] Bank $0D - SPC700 Audio Driver
- [ ] Bank $0E-$0F - Additional Data

### Phase 4: Create ROM_map/Complete
- [ ] Design comprehensive table structure
- [ ] Populate with all 512KB of ROM mapping
- [ ] Add navigation aids (links, categories)
- [ ] Cross-reference all subpages

### Phase 5: Update Main ROM_map
- [ ] Link to new subpages
- [ ] Update navigation structure
- [ ] Add "quick reference" summary tables

## Expected Benefits

1. **Complete Coverage** - No "mystery" ROM regions
2. **Easy Reference** - Single source of truth for all addresses
3. **Better Navigation** - Links between related sections
4. **Modder-Friendly** - Clear targets for hacking/modifications
5. **Documentation** - Historical record of ROM analysis

## Technical Details

### Bank Structure (Example)
```
Bank $00: $008000-$00FFFF (32KB)
- Boot sequence: $008000-$0082FF
- Main game loop: $008300-$008FFF
- DMA handlers: $009000-$009FFF
- ...
```

### Table Format (Example)
```mediawiki
{| class="wikitable sortable"
! Address Range !! Size !! Type !! Bank !! Description !! Source
|-
| $008000-$0082FF || 768 bytes || Code || $00 || Boot sequence and initialization || [link]
|-
| $014275-$01469F || 2,603 bytes || Data || $01 || Enemy stats (83 enemies × 74 bytes) || [link]
...
|}
```

## Files to Create/Update

### New Files
- `datacrystal/ROM_map/Code.wikitext` - Bank-by-bank code organization
- `datacrystal/ROM_map/Complete.wikitext` - Complete ROM map table

### Updated Files
- `datacrystal/ROM_map.wikitext` - Main page with links
- `datacrystal/ROM_map/Enemies.wikitext` - More detailed tables
- `datacrystal/ROM_map/Attacks.wikitext` - Formula breakdowns
- `datacrystal/ROM_map/Graphics.wikitext` - Format specifications
- `datacrystal/ROM_map/Maps.wikitext` - Full map database
- `datacrystal/ROM_map/Menus.wikitext` - Window system details
- `datacrystal/ROM_map/Sound.wikitext` - SPC driver structure
- `datacrystal/ROM_map/Characters.wikitext` - Stat tables

## Success Criteria

- [ ] All 16 banks fully documented with address ranges
- [ ] Complete ROM map table covers 000000-07FFFF
- [ ] All subpages have detailed offset tables
- [ ] Cross-references work between all pages
- [ ] No significant "unknown" regions remain
- [ ] Documentation matches V1.1 ROM exactly

## References

- ffmq-info repository: https://github.com/TheAnsarya/ffmq-info
- Source ASM files: `/src/asm/bank_XX_documented.asm`
- Function reference: `/docs/FUNCTION_REFERENCE.md`
- DataCrystal TODO: `DATACRYSTAL_TODO.md`

## Time Estimate

- Phase 1 (Analysis): 4-6 hours
- Phase 2 (Subpage enhancement): 8-12 hours
- Phase 3 (Code page): 10-15 hours
- Phase 4 (Complete map): 15-20 hours
- Phase 5 (Main page): 2-3 hours
- **Total**: 40-55 hours

## Priority

**HIGH** - This is foundational documentation that enables all other modding work.

## Labels

`documentation`, `datacrystal`, `rom-map`, `enhancement`, `high-priority`
