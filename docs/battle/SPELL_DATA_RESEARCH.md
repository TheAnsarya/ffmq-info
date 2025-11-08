# Spell Data Research - Final Fantasy Mystic Quest# Spell Data Extraction - Research Required



## Summary## Status

**INCOMPLETE** - Framework created but ROM address unknown

Successfully located and decoded spell data ROM structure at address `$060F36` with enemy type "strong against" flags.

## Problem

## ROM LocationThe exact ROM address where spell data is stored has not been located. The extraction tool (`tools/extraction/extract_spells.py`) is currently using a placeholder address and will extract zeros.



- **Address**: `$060F36` (PC offset in LoROM)## What We Know

- **Bank**: $0C  

- **Entry Count**: 16 spells (11 known + 5 unknown/unused)From `docs/ROM_DATA_MAP.md`:

- **Entry Size**: 6 bytes- Spell data is likely in Bank $09xxxx 

- **Total Size**: 96 bytes ($060F36-$060F96)- Structure (per entry):

  ```

## Data Structure  Offset  Size  Field

  +$00    1     Base power

### Spell Entry Format (6 bytes)  +$01    1     MP cost

  +$02    1     Element

```  +$03    1     Target flags

Offset  Size  Field           Description  +$04    1     Animation ID

------  ----  -----           -----------  ```

+$00    1     Power           Base spell power (verified: 9-96 range)- Estimated ~256 bytes total

+$01    1     Byte1           Unknown - possibly level/tier requirement (values 1-20)- Approximately 32 spells

+$02    1     Byte2           Unknown - NOT element (verified incorrect by testing)

+$03    1     StrongAgainst   Enemy type flags - "strong against" bitfield## Research Steps

+$04    1     TargetType      Enemy type flags - possibly target type or range

+$05    1     SpecialFlags    Enemy type flags - possibly "weak against" or secondary effects### 1. Find Spell Data References in Code

```

Search for code that reads spell properties during battle:

### Enemy Type Flags (Bitfield)

```bash

Bytes 3-5 use bit flags to indicate enemy types, similar to weapon/armor "strong against" system:# Search for MP cost checks

grep -r "LDA.*\$.*; MP cost" src/asm/

```

Bit   Value  Enemy Type# Search for spell power references  

---   -----  ----------grep -r "spell.*power\|spell.*damage" src/asm/

0     $01    Beast

1     $02    Plant# Search for element checks

2     $04    Undeadgrep -r "element\|fire\|ice\|lightning" src/asm/bank_00*.asm

3     $08    Dragon```

4     $10    Aquatic

5     $20    Flying### 2. Analyze Battle/Menu Code

6     $40    Humanoid

7     $80    MagicalKey files to examine:

```- `src/asm/bank_00_documented.asm` - Contains `Menu_Spell_*` functions

  - Lines ~13000-13200: Spell menu handling

Multiple flags can be set per byte (bitwise OR).  - `Menu_Spell_DecrementMP`: Reads MP cost

  - `Menu_Spell_UseHeal`: Reads spell power from `$1025,X`

## Spell Data Summary- Look for where data is loaded into `$1025,X`



See `data/extracted/spells/spells.csv` for complete extracted data with decoded enemy type flags.### 3. Follow Data Flow



## Next Steps1. Find where spell ID is used as an index

2. Trace what table it indexes into

1. Analyze battle damage calculation code to confirm flag meanings3. Look for LDA instructions with long addresses ($xxxxxx format)

2. Decode byte 1 (level requirement hypothesis)4. Convert SNES address to ROM offset

3. Decode byte 2 (animation/effect ID hypothesis)

4. Find where element is stored/calculated### 4. Verify with Known Values

5. Identify the 5 unknown spell slots (IDs 11-15)

Once address is found, verify with known spell data:

## Tools Created- Cure: Low MP cost (2-4), moderate power (~30)

- Fire: Low MP cost (2-4), low power (~20)

- `tools/find_spell_data.py` - ROM scanner- Flare: High MP cost (8-12), high power (~60-80)

- `tools/analyze_spell_structure.py` - Structure analyzer

- `tools/analyze_spell_flags.py` - Enemy type flag decoder## Address Conversion

- `tools/verify_spell_data.py` - Data verifier

- `tools/extraction/extract_spells.py` - Full extractor with flag decodingIf code uses SNES LoROM addressing:

- CPU address `$09xxxx` = ROM offset `$048000 + (xxxx - 8000)`

## Date- CPU address `$0D8000-DFFF` = ROM offset `$068000-06FFFF`



Research completed: November 1, 2025## Next Actions

Branch: `52-spell-data-address`

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
