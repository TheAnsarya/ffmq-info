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

### Phase 1: Analyze Source Structure ✅
- [x] Review all bank_XX_documented.asm files
- [x] Extract address ranges for all major sections
- [x] Categorize code vs data blocks
- [x] Document system boundaries

### Phase 2: Enhance Existing Subpages
- [ ] ROM_map/Enemies - Add detailed offset tables
- [ ] ROM_map/Attacks - Add damage formula breakdowns
- [ ] ROM_map/Graphics - Add compression format details
- [ ] ROM_map/Maps - Add full map database tables
- [ ] ROM_map/Menus - Add window system tables
- [ ] ROM_map/Sound - Add SPC driver structure
- [ ] ROM_map/Characters - Add stat progression tables

### Phase 3: Create ROM_map/Code
- [ ] Bank $00 - Main Engine (32KB: $008000-$00FFFF)
- [ ] Bank $01 - Battle System (32KB: $018000-$01FFFF)
- [ ] Bank $02 - System Management (32KB: $028000-$02FFFF)
- [ ] Bank $03-$06 - Game Data (128KB: $038000-$06FFFF)
- [ ] Bank $07 - Animation (32KB: $078000-$07FFFF)
- [ ] Bank $08-$09 - Graphics (64KB: $088000-$09FFFF)
- [ ] Bank $0A-$0C - More Data (96KB: $0A8000-$0CFFFF)
- [ ] Bank $0D - SPC700 Audio Driver (32KB: $0D8000-$0DFFFF)
- [ ] Bank $0E-$0F - Additional Data (64KB: $0E8000-$0FFFFF)

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

### Bank Structure Reference

| Bank | SNES Address | Size | Primary Content |
|------|--------------|------|-----------------|
| $00 | $008000-$00FFFF | 32KB | Main game engine, boot, DMA, NMI |
| $01 | $018000-$01FFFF | 32KB | Battle system, enemy/attack data |
| $02 | $028000-$02FFFF | 32KB | System management, threading |
| $03 | $038000-$03FFFF | 32KB | Map data, graphics, palettes |
| $04 | $048000-$04FFFF | 32KB | Item/weapon/armor data, text |
| $05 | $058000-$05FFFF | 32KB | Enemy graphics (3BPP) |
| $06 | $068000-$06FFFF | 32KB | Character/NPC graphics, tiles |
| $07 | $078000-$07FFFF | 32KB | Animation system, music data |
| $08-$09 | $088000-$09FFFF | 64KB | Text strings, dialog data |
| $0A-$0C | $0A8000-$0CFFFF | 96KB | Enemy graphics, spell animations |
| $0D | $0D8000-$0DFFFF | 32KB | SPC700 audio driver, music |
| $0E-$0F | $0E8000-$0FFFFF | 64KB | Additional graphics, data |

### Table Format Example

```mediawiki
{| class="wikitable sortable"
! Start || End || Size || Bank || Type || Description || Source Link
|-
| $008000 || $0082FF || 768 || $00 || Code || Boot sequence and hardware initialization || [https://github.com/TheAnsarya/ffmq-info/blob/main/src/asm/bank_00_documented.asm#L1 bank_00]
|-
| $014275 || $01469F || 2,603 || $01 || Data || Enemy stats data (83 enemies × 74 bytes) || [https://github.com/TheAnsarya/ffmq-info/blob/main/data/extracted/enemies/enemies.json enemies.json]
|-
| $0D8000 || $0D87FF || 2,048 || $0D || Code || SPC700 IPL upload driver || [https://github.com/TheAnsarya/ffmq-info/blob/main/src/asm/bank_0D_documented.asm#L1 bank_0D]
|-
...
|}
```

## Files to Create/Update

### New Files to Create
- `datacrystal/ROM_map/Code.wikitext` - Bank-by-bank code organization (~800 lines)
- `datacrystal/ROM_map/Complete.wikitext` - Complete ROM map table (~2,000+ lines)

### Existing Files to Update
- `datacrystal/ROM_map.wikitext` - Main page with links to new subpages
- `datacrystal/ROM_map/Enemies.wikitext` - Add detailed offset tables
- `datacrystal/ROM_map/Attacks.wikitext` - Add formula breakdowns
- `datacrystal/ROM_map/Graphics.wikitext` - Add format specifications
- `datacrystal/ROM_map/Maps.wikitext` - Add full map database
- `datacrystal/ROM_map/Menus.wikitext` - Add window system details
- `datacrystal/ROM_map/Sound.wikitext` - Add SPC driver structure
- `datacrystal/ROM_map/Characters.wikitext` - Add stat progression tables

## Success Criteria

- [ ] All 16 banks fully documented with address ranges
- [ ] Complete ROM map table covers $000000-$07FFFF (512KB)
- [ ] All subpages have detailed offset tables
- [ ] Cross-references work between all pages
- [ ] No significant "unknown" regions remain
- [ ] Documentation matches V1.1 ROM exactly
- [ ] Sortable tables for easy navigation
- [ ] GitHub source file links work correctly

## References

- **Repository**: https://github.com/TheAnsarya/ffmq-info
- **Source ASM**: `/src/asm/bank_XX_documented.asm`
- **Function Reference**: `/docs/FUNCTION_REFERENCE.md`
- **DataCrystal TODO**: `DATACRYSTAL_TODO.md`
- **Current ROM Map**: `datacrystal/ROM_map.wikitext`

## Time Estimate

| Phase | Task | Estimated Time |
|-------|------|----------------|
| 1 | Source analysis (bank structure extraction) | 4-6 hours ✅ |
| 2 | Enhance existing subpages (7 pages × 1-2 hrs) | 8-12 hours |
| 3 | Create ROM_map/Code (16 banks) | 10-15 hours |
| 4 | Create ROM_map/Complete (full table) | 15-20 hours |
| 5 | Update main ROM_map page | 2-3 hours |
| **Total** | | **40-55 hours** |

## Priority

**HIGH** - This is foundational documentation that enables all other modding work and provides complete ROM coverage for the community.

## Labels

`documentation`, `datacrystal`, `rom-map`, `enhancement`, `high-priority`, `wiki`

---

**Created**: November 6, 2025
**Assignee**: @TheAnsarya
**Status**: Ready for implementation
