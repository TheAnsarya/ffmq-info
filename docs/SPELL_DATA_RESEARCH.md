# Spell Data Extraction - Research Required

## Status
**INCOMPLETE** - Framework created but ROM address unknown

## Problem
The exact ROM address where spell data is stored has not been located. The extraction tool (`tools/extraction/extract_spells.py`) is currently using a placeholder address and will extract zeros.

## What We Know

From `docs/ROM_DATA_MAP.md`:
- Spell data is likely in Bank $09xxxx 
- Structure (per entry):
  ```
  Offset  Size  Field
  +$00    1     Base power
  +$01    1     MP cost
  +$02    1     Element
  +$03    1     Target flags
  +$04    1     Animation ID
  ```
- Estimated ~256 bytes total
- Approximately 32 spells

## Research Steps

### 1. Find Spell Data References in Code

Search for code that reads spell properties during battle:

```bash
# Search for MP cost checks
grep -r "LDA.*\$.*; MP cost" src/asm/

# Search for spell power references  
grep -r "spell.*power\|spell.*damage" src/asm/

# Search for element checks
grep -r "element\|fire\|ice\|lightning" src/asm/bank_00*.asm
```

### 2. Analyze Battle/Menu Code

Key files to examine:
- `src/asm/bank_00_documented.asm` - Contains `Menu_Spell_*` functions
  - Lines ~13000-13200: Spell menu handling
  - `Menu_Spell_DecrementMP`: Reads MP cost
  - `Menu_Spell_UseHeal`: Reads spell power from `$1025,X`
- Look for where data is loaded into `$1025,X`

### 3. Follow Data Flow

1. Find where spell ID is used as an index
2. Trace what table it indexes into
3. Look for LDA instructions with long addresses ($xxxxxx format)
4. Convert SNES address to ROM offset

### 4. Verify with Known Values

Once address is found, verify with known spell data:
- Cure: Low MP cost (2-4), moderate power (~30)
- Fire: Low MP cost (2-4), low power (~20)
- Flare: High MP cost (8-12), high power (~60-80)

## Address Conversion

If code uses SNES LoROM addressing:
- CPU address `$09xxxx` = ROM offset `$048000 + (xxxx - 8000)`
- CPU address `$0D8000-DFFF` = ROM offset `$068000-06FFFF`

## Next Actions

1. **Search battle code** for spell data table references
2. **Disassemble spell handling** in menu/battle routines
3. **Update SPELL_DATA_ADDRESS** in `tools/extraction/extract_spells.py`
4. **Test extraction** with known spell values
5. **Verify all 32 spells** extract correctly

## Related Files

- `tools/extraction/extract_spells.py` - Extraction tool (needs address)
- `src/asm/bank_00_documented.asm` - Battle/menu code
- `docs/ROM_DATA_MAP.md` - ROM structure documentation
- `data/text/text_data.csv` - Contains spell names (mostly placeholders)

## Estimated Effort

- Research: 2-4 hours
- Implementation: 1 hour
- Verification: 1 hour
- **Total: 4-6 hours**

## Priority

**MEDIUM** - Spell data is important for game documentation but not critical for build system or core disassembly work.

## Related Issues

- Issue #5: Data Extraction Pipeline (parent issue)
- This is the last major data extraction task
