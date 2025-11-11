# FFMQ Text Extraction Guide

## Overview

This document provides a comprehensive guide to extracting and working with text data from Final Fantasy: Mystic Quest ROM.

## Text Systems

FFMQ uses **two distinct text encoding systems**:

### 1. Simple Text System ✅ WORKING
**Purpose:** Fixed-length text for game data  
**Character Table:** `simple.tbl` (direct byte-to-character mapping)  
**Used For:**
- Item names (231 entries)
- Spell names (32 entries)
- Weapon names (57 entries)
- Armor names (20 entries)  
- Helmet names (10 entries)
- Shield names (10 entries)
- Accessory names (24 entries)
- Monster names (211 entries)

**Character Ranges:**
```
0x00-0x8F: Control codes and placeholders
0x90-0x99: Digits (0-9)
0x9A-0xB3: Uppercase letters (A-Z)
0xB4-0xCD: Lowercase letters (a-z)
0xCE-0xFF: Punctuation and special characters
```

**Format:**
```
[text bytes] [padding: 0x03 or 0xFF] [terminator: 0x00]
```

**Example - "Fire":**
```
ROM bytes: 9F BC C5 B8 03 03 03 03 03 03 03 03
Decoded:   F  i  r  e  [padding...]
```

### 2. Complex Text System ⚠️ NEEDS WORK
**Purpose:** Variable-length dialog with compression  
**Character Table:** `complex.tbl` (DTE + control codes)  
**Used For:**
- Dialog text (117+ entries)
- Event scripts

**Components:**
- **Control codes** (0x00-0x3B, 0x80-0x8F): Dialog box control, character names, events
- **DTE sequences** (0x3D-0x7E): Common words/phrases compressed (e.g., 0x41="the ", 0x50="or")
- **Single characters** (0x90-0xCD): Same as simple.tbl
- **Punctuation** (0xCE-0xFF): Special characters

**Current Status:**
- ✅ Infrastructure complete (extraction, pointer reading)
- ✅ Control codes documented
- ⚠️ DTE mappings need verification (output is garbled)
- ❌ Need ROM byte analysis to fix DTE table

## ROM Addresses

All addresses verified from source code (`.asm` files):

| Data Type | SNES Address | PC Address | Count | Length |
|-----------|--------------|------------|-------|--------|
| Items | — | $064120 | 232 | 12 bytes |
| Spells | — | $064210 | 32 | 12 bytes |
| Weapons | — | $0642A0 | 57 | 12 bytes |
| Helmets | — | $064354 | 10 | 12 bytes |
| Armor | — | $064378 | 20 | 12 bytes |
| Shields | — | $0643CC | 10 | 12 bytes |
| Accessories | — | $0643FC | 24 | 12 bytes |
| Monsters | — | $064BA0 | 256 | 16 bytes |
| Dialog Pointers | — | $00D636 | 256 | 2 bytes |
| Dialog Data | $03:$8000+ | $018000-$01FFFF | Variable | Variable |

## Extraction Tools

### Simple Text Extraction (PRODUCTION READY)

**Tool:** `tools/extraction/extract_simple_text.py`

**Usage:**
```bash
python tools/extraction/extract_simple_text.py "rom.sfc" --output-dir data/text_fixed
```

**Output:**
- `data/text_fixed/item_names.csv` (231 entries)
- `data/text_fixed/spell_names.csv` (32 entries)
- `data/text_fixed/weapon_names.csv` (57 entries)
- `data/text_fixed/armor_names.csv` (20 entries)
- `data/text_fixed/helmet_names.csv` (10 entries)
- `data/text_fixed/shield_names.csv` (10 entries)
- `data/text_fixed/accessory_names.csv` (24 entries)
- `data/text_fixed/monster_names.csv` (211 entries)
- Plus .txt files for human-readable format

**Verification:**
```bash
python tools/text/simple_text_decoder.py
# Outputs character table stats and test decode
```

**Sample Output:**
```csv
ID,Text,Address,Length
0,Elixir,$064120,12
1,TreeWither,$06412C,12
2,Wakewater,$064138,12
6,Exit,$064210,12
7,Cure,$06421C,12
8,Fire,$064258,12
```

### Dialog Text Extraction (EXPERIMENTAL)

**Tool:** `tools/extraction/extract_dialog_text.py`

**Usage:**
```bash
python tools/extraction/extract_dialog_text.py "rom.sfc" --output-dir data/text_fixed
```

**Current Issues:**
- Extracts 117 dialogs successfully
- DTE decompression produces garbled output
- Needs ROM byte analysis to fix DTE mappings

**Output:**
- `data/text_fixed/dialog.csv` (117 entries, garbled)
- `data/text_fixed/dialog.txt` (human-readable, garbled)

## Code Architecture

### SimpleTextDecoder (`tools/text/simple_text_decoder.py`)

**Class:** `SimpleTextDecoder`

**Methods:**
```python
# Initialize with character table
decoder = SimpleTextDecoder()

# Decode fixed-length string
text, length = decoder.decode(bytes_data, max_length=12)

# Encode text to fixed-length bytes
byte_data = decoder.encode('Fire', fixed_length=12, padding_byte=0x03)

# Decode entire table from ROM
entries = decoder.decode_table(rom_data, 0x064210, entry_count=32, entry_length=12)

# Get statistics
stats = decoder.get_stats()
```

**Character Table Format (simple.tbl):**
```
90=0
91=1
...
9F=F
A0=G
...
B3=Z
B4=a
...
CD=z
FF= 
```

### DialogText (`tools/map-editor/utils/dialog_text.py`)

**Class:** `DialogText`

**Methods:**
```python
# Initialize with complex.tbl
dialog_text = DialogText()

# Decode dialog with DTE and control codes
text = dialog_text.decode(bytes_data)

# Encode text back to bytes
bytes_data = dialog_text.encode(text)

# Validate dialog text
is_valid, messages = dialog_text.validate(text)
```

### DialogDatabase (`tools/map-editor/utils/dialog_database.py`)

**Class:** `DialogDatabase`

**Methods:**
```python
# Load ROM
db = DialogDatabase('rom.sfc')
db.load_rom()

# Extract all dialogs
dialogs = db.extract_all_dialogs()

# Get specific dialog
entry = db.get_dialog(dialog_id=33)

# Update dialog
db.update_dialog(dialog_id=33, new_text='Hello world![END]')

# Save ROM
db.save_rom('modified.sfc')
```

## Known Issues

### 1. Dialog DTE Mappings ⚠️

**Problem:** Dialog extraction produces garbled output

**Example:**
```
Expected: "Look someone is coming!"
Actual:   "Loosoovofthanero..."
```

**Root Cause:** DTE byte→string mappings in `complex.tbl` don't match ROM

**Evidence:**
- complex.tbl matches DataCrystal documentation
- Added trailing spaces (0x40="e ", 0x41="the ", etc.)
- Still produces garbled output
- Suggests DataCrystal docs are incomplete or ROM version differs

**Solution:** Reverse-engineer actual DTE mappings from ROM
1. Find dialogs with known English text
2. Compare ROM bytes to expected text
3. Deduce actual byte→string mappings
4. Update complex.tbl with correct mappings

### 2. Control Code Functions ℹ️

**Problem:** Many control codes have unknown functions

**Known Codes:**
- 0x00 = END
- 0x01 = NEWLINE
- 0x02 = WAIT
- 0x04 = NAME (insert character name)
- 0x05 = ITEM (insert item name)
- 0x1A = Textbox below
- 0x1B = Textbox above
- 0x30 = PARA (paragraph)
- 0x36 = PAGE (new page)

**Unknown Codes:** 0x0B, 0x0C, 0x0D, 0x0E, 0x0F, 0x10-0x2C, 0x80-0x8F

**Solution:** Research by analyzing ROM code and dialog context

## Testing

### Test Simple Text Decoder
```bash
python tools/text/simple_text_decoder.py
# Expected output:
# Total characters: 67
# Digits (0-9): 10
# Uppercase (A-Z): 26
# Lowercase (a-z): 26
# Test decode: "Fire"
```

### Test Simple Text Extraction
```bash
python tools/extraction/extract_simple_text.py "roms/rom.sfc" --output-dir test_output
# Check test_output/spell_names.csv for "Fire", "Cure", "Thunder"
```

### Verify Character Mappings
```python
from tools.text.simple_text_decoder import SimpleTextDecoder

decoder = SimpleTextDecoder()

# Test round-trip
original = "Fire"
encoded = decoder.encode(original, 12)
decoded, _ = decoder.decode(encoded)
assert decoded == original  # Should pass
```

## Future Work

### High Priority
1. **Fix DTE table** - Reverse-engineer correct mappings from ROM
2. **Create text re-insertion tool** - Write edited text back to ROM
3. **Research control codes** - Map all codes to game functions

### Medium Priority
4. **Dialog editor GUI** - Visual tool for editing dialogs
5. **Translation workflow** - Import/export for translators
6. **Script dumper** - Extract all game text to single file

### Low Priority
7. **Font editor** - Edit character graphics
8. **Text compression tool** - Optimize DTE for maximum space savings

## References

- **DataCrystal:** https://datacrystal.romhacking.net/wiki/Final_Fantasy:_Mystic_Quest
- **TCRF:** https://tcrf.net/Final_Fantasy:_Mystic_Quest
- **GitHub:** https://github.com/TheAnsarya/ffmq-info
- **Source Code:** `src/data/text/*.asm` files
- **Character Tables:** `simple.tbl`, `complex.tbl`
- **Documentation:** `docs/TEXT_SYSTEMS_ANALYSIS.md`, `docs/TEXT_SYSTEMS_STATUS.md`

## Contributing

See individual GitHub issues for specific tasks:
- Issue #XXX: DTE table reverse engineering
- Issue #XXX: Dialog extraction debugging
- Issue #XXX: Control code research
- Issue #XXX: Text re-insertion tool
- Issue #XXX: Dialog editor GUI

## License

This project is part of the ffmq-info disassembly project.  
See LICENSE file for details.
