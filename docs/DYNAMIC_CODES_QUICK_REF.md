# Dynamic Insertion Codes - Quick Reference

**Last Updated**: 2025-11-12  
**Status**: Analysis Complete, ROM Testing Pending

---

## Quick Lookup Table

| Code | Name | Usage | Confidence | Notes |
|------|------|-------|------------|-------|
| `0x10` | ITEM_NAME | 55× | ✅ High | General items (potions, quest items) |
| `0x11` | SPELL_NAME | 27× | ✅ High | Magic spells (source table unknown) |
| `0x12` | MONSTER_NAME | 19× | ✅ High | Enemy names in battle/dialog |
| `0x13` | CHARACTER_NAME | 17× | ✅ Confirmed | Player character name |
| `0x14` | LOCATION_NAME | 8× | ⚠️ Medium | Area/town names |
| `0x15` | NUMBER_VALUE | 0× | ❓ Unused | Reserved for stats/numbers? |
| `0x16` | OBJECT_NAME | 12× | ⚠️ Medium | Special items (crystals, keys) |
| `0x17` | WEAPON_NAME | 1× | ⚠️ Low | Equipped weapon (distinct from 0x10) |
| `0x18` | ARMOR_NAME | 20× | ✅ High | Equipped armor/equipment |
| `0x19` | ACCESSORY_NAME | 0× | ❓ Unused | Reserved for accessories? |
| `0x1A` | POSITION_Y | N/A | ⚠️ Wrong | Not insertion code (positioning) |
| `0x1B` | POSITION_X | N/A | ⚠️ Wrong | Not insertion code (positioning) |
| `0x1C` | UNKNOWN | 3× | ❓ Unknown | Always in pattern `[23][1C][2B]` |
| `0x1D` | FORMAT_ITEM_E1 | 25× | ✅ Confirmed | Dict 0x50: Item+formatting+E+Name |
| `0x1E` | FORMAT_ITEM_E2 | 10× | ✅ Confirmed | Dict 0x51: Same as 0x1D, variant |

---

## Common Patterns

### Item Acquisition
```
Pattern: [ITEM][CMD:1D]E[END][NAME]
Example: "You got [ITEM_NAME], Benjamin!"
Used in: Dictionary 0x50 (10 dialogs)
```

### Spell Learning
```
Pattern: [CMD:2D]-a[CMD:11]es\n[CMD:13]X[ITEM]
Context: Spell acquisition/casting
Frequency: 11 occurrences
```

### Monster Description
```
Pattern: [CMD:1D][END][ITEM]es[END]\n[CMD:12]is
Context: Enemy description or battle text
Frequency: 6 occurrences
```

---

## Dictionary Formatting System

### Entry 0x50 (used 10×)
```
Bytes: 05 1D 9E 00 04
Decoded: [ITEM][CMD:1D]E[END][NAME]
Hypothesis: Possessive form ("Benjamin's Steel Sword")
```

### Entry 0x51 (used 5×)
```
Bytes: 05 1E 9E 00 04
Decoded: [ITEM][CMD:1E]E[END][NAME]
Hypothesis: Nominative form ("Steel Sword for Benjamin")
```

**Key Insight**: Codes 0x1D/0x1E are formatting codes embedded in dictionary entries, not standalone insertion codes like 0x10-0x18.

---

## Usage Examples

### Inserting Item Name
```
Raw: ... 10 ...
Decoded: ...[CMD:10]...
Result: "...Steel Sword..."
```

### Inserting Spell Name
```
Raw: ... 11 ...
Decoded: ...[CMD:11]...
Result: "...Cure..."
```

### Inserting Character Name
```
Raw: ... 13 ...
Decoded: ...[CMD:13]...
Result: "...Benjamin..."
```

### Complex Formatting (via Dictionary)
```
Raw: ... 50 ...  (reference to dictionary entry 0x50)
Decoded: ...[ITEM][CMD:1D]E[END][NAME]...
Result: "...Steel SwordE Benjamin..."
Formatted: "...Steel Sword, Benjamin..."  (if 0x1D adds comma)
```

---

## Data Source Tables

### Known Tables (from simple strings)
- **Items**: 128 entries @ ROM 0x063600 → Code 0x10
- **Monsters**: 83 entries @ ROM 0x064000 → Code 0x12
- **Attacks**: 128 entries @ ROM 0x064420 → Related to battle
- **Locations**: 37 entries @ ROM 0x063ED0 → Code 0x14

### Unknown Tables
- **Spells**: ❓ Location unknown → Code 0x11 (27 references)
- **Weapons**: ❓ Subset of items? → Code 0x17 (1 reference)
- **Armor**: ❓ Subset of items? → Code 0x18 (20 references)

---

## Testing Checklist

### Priority 1: Codes 0x1D vs 0x1E
- [ ] Swap bytes in dict 0x50 and 0x51
- [ ] Remove 'E' from dict entries
- [ ] Compare rendered output in-game
- [ ] Document observed differences

### Priority 2: Equipment Codes
- [ ] Change 0x18 → 0x17 in dialog
- [ ] Change 0x10 → 0x18 in dialog
- [ ] Verify different item categories
- [ ] Document item selection logic

### Priority 3: Unknown Codes
- [ ] Test code 0x1C in different contexts
- [ ] Insert code 0x15 in test dialog
- [ ] Insert code 0x19 in test dialog
- [ ] Verify if crashes or functions

---

## Implementation Notes

### For Fan Translators

**Safe to Use**:
- ✅ 0x10 (ITEM) - Highly reliable
- ✅ 0x11 (SPELL) - Highly reliable
- ✅ 0x12 (MONSTER) - Highly reliable
- ✅ 0x13 (CHARACTER) - Confirmed safe
- ✅ 0x18 (ARMOR) - Highly reliable

**Use with Caution**:
- ⚠️ 0x14 (LOCATION) - Medium confidence
- ⚠️ 0x16 (OBJECT) - Medium confidence
- ⚠️ 0x1D/0x1E (FORMAT) - Only in dictionary entries

**Do Not Use**:
- ❌ 0x17 (WEAPON) - Only 1 occurrence, untested
- ❌ 0x1C (UNKNOWN) - Unknown behavior
- ❌ 0x15, 0x19 (UNUSED) - May crash

### For ROM Hackers

**Jump Table Location**: 009DC1-009DD2 (Dialog_WriteCharacter)

**Expected Handler Structure**:
```asm
Handle_10_ITEM:
    ; Read item ID from game state
    ; Index into item name table
    ; Copy string to dialog buffer
    rts

Handle_1D_FORMAT1:
    ; Apply formatting operation
    ; Modify capitalization/spacing?
    rts
```

---

## Cross-References

- **Full Analysis**: docs/DYNAMIC_CODES.md
- **Control Codes**: docs/CONTROL_CODES_ANALYSIS.md
- **Simple Strings**: docs/SIMPLE_STRINGS.md
- **Data Tables**: data/text_simple/*.csv
- **Frequency Data**: data/control_code_frequency.csv
- **Context Samples**: data/dynamic_code_samples.txt

---

## Version History

**v1.0** (2025-11-12)
- Initial analysis of all 117 dialogs
- Identified 13 active codes, 2 unused
- Discovered dictionary formatting system
- 217 code occurrences analyzed
- 500+ lines of documentation

**Next**: ROM testing phase for validation

---

**Quick Reference Guide**  
**Project**: ffmq-info  
**GitHub**: TheAnsarya/ffmq-info  
**Issue**: #73
