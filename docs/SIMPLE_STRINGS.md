# FFMQ Simple String Extraction - Complete Guide

**Last Updated:** 2025-11-12  
**Tool Version:** 3.0.0  
**Status:** ✅ **COMPLETE** (760 strings extracted from 10 tables)

---

## Overview

This document describes the extraction of **simple (non-compressed) text strings** from Final Fantasy Mystic Quest ROM. These strings use a **direct byte-to-character mapping** (no dictionary compression) and are stored in **fixed-length tables**.

### Extracted String Types

| Category | Count | Max Length | ROM Address | Status |
|----------|-------|------------|-------------|--------|
| **Item Names** | 231 | 12 bytes | `$064120` | ✅ Complete |
| **Spell Names** | 32 | 12 bytes | `$064210` | ✅ Complete |
| **Weapon Names** | 57 | 12 bytes | `$0642A0` | ✅ Complete |
| **Helmet Names** | 10 | 12 bytes | `$064354` | ✅ Complete |
| **Armor Names** | 20 | 12 bytes | `$064378` | ✅ Complete |
| **Shield Names** | 10 | 12 bytes | `$0643CC` | ✅ Complete |
| **Accessory Names** | 24 | 12 bytes | `$0643FC` | ✅ Complete |
| **Attack Names** | 128 | 12 bytes | `$064420` | ✅ Complete |
| **Monster Names** | 211 | 16 bytes | `$064BA0` | ✅ Complete |
| **Location Names** | 37 | 16 bytes | `$063ED0` | ✅ Complete |
| **TOTAL** | **760** | — | — | ✅ Complete |

---

## Text Encoding

### Character Table

Simple strings use the **`simple.tbl`** character table with direct byte-to-character mapping:

```
Character Ranges:
	0x00-0x8F: Control codes and placeholders (#)
	0x90-0x99: Digits (0-9)
	0x9A-0xB3: Uppercase (A-Z)
	0xB4-0xCD: Lowercase (a-z)
	0xCE-0xFF: Punctuation and special characters
```

### String Format

```
[text bytes] [padding: 0x03 or 0xFF] [terminator: 0x00]
```

**Example - "Fire" (Spell Name):**
```
ROM Bytes:  9F BC C5 B8 03 03 03 03 03 03 03 00
Decoded:    F  i  r  e  ·  ·  ·  ·  ·  ·  ·  [END]
            ↑  ↑  ↑  ↑  ←──── padding ────→  ↑
            text (4 bytes)   (7 bytes)    terminator
```

---

## Extraction Usage

### Command-Line Tool

#### Extract All Simple Strings (JSON)
```bash
python tools/extraction/extract_simple_text.py \
	"roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc" \
	--output-dir data/text_simple \
	--json data/text_simple/all_simple_text.json
```

#### Using Integrated Toolkit
```bash
python tools/ffmq_text_tool.py extract-simple \
	"roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc" \
	data/all_simple_text.json \
	--format json
```

### Output Formats

#### JSON Output
```json
{
	"version": "3.0.0",
	"game": "Final Fantasy Mystic Quest",
	"extraction_date": "2025-11-12T14:04:20.126946",
	"total_entries": 760,
	"tables": {
		"item_names": {
			"count": 231,
			"address": "$064120",
			"entry_length": 12,
			"entries": [
				{"id": 0, "text": "Elixir", "address": 409888, "length": 6},
				{"id": 1, "text": "TreeWither", "address": 409900, "length": 10},
				...
			]
		},
		...
	}
}
```

#### CSV Output
```csv
ID,Text,Address,Length
0,Elixir,$064120,6
1,TreeWither,$06412C,10
2,Wakewater,$064138,9
```

#### Text Output
```
ITEM NAMES
======================================================================
Extracted: 2025-11-12T14:04:20.126946
Address: $064120
Count: 231 entries
======================================================================

[  0] Elixir
[  1] TreeWither
[  2] Wakewater
...
```

---

## Detailed String Tables

### 1. Item Names (`$064120`)

**Count:** 231 items  
**Format:** 12 bytes per entry  
**Examples:**
- `[0]` Elixir
- `[1]` TreeWither
- `[2]` Wakewater
- `[3]` VenusKey
- `[4]` Multi-Key
- `[16]` CurePotion
- `[17]` HealPotion

### 2. Spell Names (`$064210`)

**Count:** 32 spells  
**Format:** 12 bytes per entry  
**Examples:**
- `[0]` Exit
- `[1]` Cure
- `[2]` Heal
- `[3]` Life
- `[4]` Quake
- `[5]` Blizzard
- `[6]` Fire

### 3. Weapon Names (`$0642A0`)

**Count:** 57 weapons  
**Format:** 12 bytes per entry  
**Examples:**
- `[0]` SteelSword
- `[1]` KnightSword
- `[2]` Excalibur
- `[3]` Axe
- `[4]` BattleAxe

### 4. Helmet Names (`$064354`)

**Count:** 10 helmets  
**Format:** 12 bytes per entry  
**Examples:**
- `[0]` SteelHelm
- `[1]` MoonHelm
- `[2]` ApolloHelm

### 5. Armor Names (`$064378`)

**Count:** 20 armor pieces  
**Format:** 12 bytes per entry  
**Examples:**
- `[0]` SteelArmor
- `[1]` NobleArmor
- `[2]` Gaia'sArmor

### 6. Shield Names (`$0643CC`)

**Count:** 10 shields  
**Format:** 12 bytes per entry  
**Examples:**
- `[0]` SteelShield
- `[1]` VenusShield
- `[2]` AegisShield

### 7. Accessory Names (`$0643FC`)

**Count:** 24 accessories  
**Format:** 12 bytes per entry  
**Examples:**
- `[0]` Charm
- `[1]` MagicRing
- `[2]` CupidLocket

### 8. Attack Names (`$064420`)

**Count:** 128 attacks/abilities  
**Format:** 12 bytes per entry  
**Examples:**
- `[0]` Sword
- `[1]` Scimitar
- `[2]` DragonCut
- `[3]` Rapier
- `[4]` Axe
- `[5]` Beam
- `[6]` BoneMissile
- `[7]` Bow&Arrow

### 9. Monster Names (`$064BA0`)

**Count:** 211 monsters (256 slots, 45 empty)  
**Format:** 16 bytes per entry  
**Examples:**
- `[0]` Brownie
- `[1]` Mintmint
- `[2]` RedCap

### 10. Location Names (`$063ED0`)

**Count:** 37 locations  
**Format:** 16 bytes per entry  
**Examples:**
- `[0]` World
- `[1]` FocusTower
- `[2]` HillofDestiny
- `[3]` LevelForest
- `[4]` Foresta
- `[5]` Kaeli'sHouse
- `[36]` DoomCastle

---

## Python API

### SimpleTextExtractor Class

```python
from tools.extraction.extract_simple_text import SimpleTextExtractor

# Create extractor
extractor = SimpleTextExtractor(Path("roms/ffmq.sfc"))

# Extract all strings
all_text = extractor.extract_all()

# Save outputs
extractor.save_json(all_text, Path("data/all_text.json"))
extractor.save_csv(all_text, Path("data/text_tables/"))
extractor.save_text(all_text, Path("data/text_readable/"))
```

### Access Extracted Data

```python
import json

with open("data/all_simple_text.json", "r", encoding="utf-8") as f:
	data = json.load(f)

# Get all item names
items = data["tables"]["item_names"]["entries"]
for item in items[:10]:
	print(f"{item['id']:3d}: {item['text']}")

# Get specific string
spell_data = data["tables"]["spell_names"]["entries"]
fire_spell = spell_data[6]  # Fire is ID 6
print(f"Spell: {fire_spell['text']} at ${fire_spell['address']:06X}")
```

---

## Technical Details

### String Decoding Algorithm

```python
def decode_string(rom_data, address, max_length):
	"""Decode a fixed-length string."""
	text = ""
	length = 0
	
	for i in range(max_length):
		byte = rom_data[address + i]
		
		# Terminator
		if byte == 0x00:
			break
		
		# Padding (skip)
		if byte == 0x03 or byte == 0xFF:
			continue
		
		# Map to character
		char = char_table.get(byte, '#')
		text += char
		length += 1
	
	return text, length
```

### ROM Address Calculation

All addresses are **PC (physical) addresses**, not SNES LoROM addresses.

**LoROM → PC Conversion:**
```
PC Address = (Bank × 0x8000) + (Address & 0x7FFF)
```

**Examples:**
- LoROM `$0C:4120` → PC `$064120` (Item Names)
- LoROM `$0C:4210` → PC `$064210` (Spell Names)
- LoROM `$0C:BED0` → PC `$063ED0` (Location Names)

---

## Integration with Text Toolkit

The simple string extractor is fully integrated into `ffmq_text_tool.py`:

```bash
# Extract simple strings
python tools/ffmq_text_tool.py extract-simple ROM OUTPUT.json

# Extract complex dialogs
python tools/ffmq_text_tool.py extract-complex ROM OUTPUT.json

# Insert modified text
python tools/ffmq_text_tool.py insert-complex ROM INPUT.json OUTPUT_ROM

# Validate integrity
python tools/ffmq_text_tool.py validate ROM TEXT.json
```

---

## Future Enhancements

### Planned Features

1. **Simple String Insertion** (Issue #74 continuation)
	- Re-insert edited strings back into ROM
	- Validate length constraints (12/16 bytes)
	- Support batch editing from spreadsheet

2. **Character Name Support**
	- Benjamin, Kaeli, Phoebe, Reuben, Tristam
	- Currently stored separately (needs investigation)

3. **Menu Text Extraction**
	- System menus, battle messages
	- UI strings, tutorials
	- Currently mixed with code (needs disassembly)

4. **String Search Tool**
	- Find strings by ID or text
	- Cross-reference with dialog usage
	- Generate usage reports

### Known Limitations

1. **Fixed-Length Constraint**
	- Strings padded to 12 or 16 bytes
	- Cannot exceed maximum length
	- Shorter strings waste space

2. **No Compression**
	- Each character = 1 byte
	- No dictionary system (unlike dialogs)
	- Larger ROM footprint

3. **Character Table Limited**
	- Only characters in `simple.tbl`
	- No extended Unicode support
	- Special symbols limited

---

## Troubleshooting

### Issue: "ROM not found"
**Solution:** Verify ROM path and filename
```bash
python tools/extraction/extract_simple_text.py "roms/ffmq.sfc"
```

### Issue: "Character table not found"
**Solution:** Ensure `simple.tbl` exists in workspace root
```bash
ls simple.tbl  # Should exist
```

### Issue: Garbled text in output
**Cause:** Wrong ROM address or count  
**Solution:** Verify addresses match source `.asm` files

### Issue: Missing strings
**Cause:** Entry count too low  
**Solution:** Increase count in `TABLES` configuration

---

## References

- **Source Files:** `src/data/text/*.asm`
- **Character Table:** `simple.tbl`
- **Extractor Code:** `tools/extraction/extract_simple_text.py`
- **Decoder Library:** `tools/text/simple_text_decoder.py`
- **Main Toolkit:** `tools/ffmq_text_tool.py`
- **Output Data:** `data/text_simple/`

---

## Changelog

### v3.0.0 (2025-11-12)
- ✅ Added location names extraction (37 entries)
- ✅ Added attack names extraction (128 entries)
- ✅ Integrated into main toolkit (`ffmq_text_tool.py`)
- ✅ Total: **760 strings** across **10 tables**
- ✅ JSON, CSV, and TXT output formats
- ✅ Complete documentation

### v2.0.0 (Previous)
- ✅ Item, spell, weapon, armor, helmet, shield, accessory, monster names
- ✅ Total: 595 strings across 8 tables

---

**Status:** ✅ Simple string extraction **COMPLETE**  
**Next:** Simple string insertion (Issue #74 continuation)
