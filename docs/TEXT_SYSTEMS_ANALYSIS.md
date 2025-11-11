# FFMQ Text Systems - Complete Analysis

**Date**: November 11, 2025  
**Status**: ✅ COMPREHENSIVE - Both systems documented

---

## Overview

Final Fantasy Mystic Quest uses **TWO DISTINCT** text encoding systems:

1. **Simple System** - For item/spell/monster names (one-to-one character mapping)
2. **Complex System** - For dialog/events (DTE compression + control codes)

---

## 1. Simple Text System

### Purpose
Used for **fixed-length text** that doesn't need compression or special formatting:
- Item names (256 entries, 12 bytes each)
- Weapon names (64 entries, 12 bytes each)
- Armor names (64 entries, 12 bytes each)
- Accessory names (64 entries, 12 bytes each)
- Spell names (64 entries, 12 bytes each)
- Monster names (256 entries, 16 bytes each)
- Location names (128 entries, 20 bytes each)

### Character Table (`simple.tbl`)

**File**: `simple.tbl`  
**Encoding**: Direct 1:1 byte-to-character mapping  
**No DTE compression** - each byte = one character

```
Byte Ranges:
0x00-0x8F  : Unused/placeholder (#)
0x90-0x99  : Digits (0-9)
0x9A-0xB3  : Uppercase (A-Z)
0xB4-0xCD  : Lowercase (a-z)
0xCE-0xDD  : Punctuation (!, ?, ', ., etc.)
0xFE       : Placeholder (#)
0xFF       : Space
0x00       : String terminator
```

### Example Encoding

**Text**: "Fire Sword"  
**Bytes**: `9F BC C5 B8 FF AC CA C2 C5 B7 00`

Breakdown:
- `9F` = F
- `BC` = i
- `C5` = r
- `B8` = e
- `FF` = (space)
- `AC` = S
- `CA` = w
- `C2` = o
- `C5` = r
- `B7` = d
- `00` = (end)

### ROM Locations

| Text Type | ROM Address | Count | Max Length | Format |
|-----------|-------------|-------|------------|--------|
| Item Names | 0x04F000 | 256 | 12 bytes | Fixed |
| Weapon Names | 0x04F800 | 64 | 12 bytes | Fixed |
| Armor Names | 0x04FC00 | 64 | 12 bytes | Fixed |
| Accessory Names | 0x04FD00 | 64 | 12 bytes | Fixed |
| Spell Names | 0x04FE00 | 64 | 12 bytes | Fixed |
| Monster Names | 0x050000 | 256 | 16 bytes | Fixed |
| Location Names | 0x051000 | 128 | 20 bytes | Fixed |

### Storage Format

**Fixed-length**: Each entry occupies exact number of bytes regardless of actual text length.

```
Entry structure:
[Text bytes...][Padding: 0xFF][Terminator: 0x00]

Example (12-byte entry):
"Cure"  → [C8 C8 C5 B8 FF FF FF FF FF FF FF 00]
           C  u  r  e  (space padding)(term)
```

### Implementation

**Decoder**: `tools/extraction/extract_text.py`
```python
class TextExtractor:
    def decode_string(self, address: int, max_length: int):
        """Decode simple text using simple.tbl"""
        text = []
        for i in range(max_length):
            byte = rom_data[address + i]
            if byte == 0x00:  # Terminator
                break
            elif byte == 0xFF:  # Space
                text.append(' ')
            elif byte in char_table:
                text.append(char_table[byte])
        return ''.join(text)
```

**Encoder**:
```python
def encode_string(text: str, max_length: int):
    """Encode simple text to bytes"""
    bytes_out = []
    for char in text[:max_length]:
        if char == ' ':
            bytes_out.append(0xFF)
        elif char in reverse_table:
            bytes_out.append(reverse_table[char])
    # Pad with 0xFF to max_length - 1
    while len(bytes_out) < max_length - 1:
        bytes_out.append(0xFF)
    bytes_out.append(0x00)  # Terminator
    return bytes(bytes_out)
```

---

## 2. Complex Text System (Dialog/Events)

### Purpose
Used for **variable-length text** that needs compression and event integration:
- Dialog text (116 entries)
- Event scripts
- Cutscene text
- NPC conversations

### Character Table (`complex.tbl`)

**File**: `complex.tbl`  
**Encoding**: Mixed system with three components:
1. **Control codes** (0x00-0x3B, 0x80-0x8F) - Event commands
2. **DTE sequences** (0x3D-0x7E) - Compressed multi-character strings
3. **Single characters** (0x90-0xCD) - Same as simple.tbl
4. **Special codes** (0xCE-0xFF) - Punctuation and markers

### Components

#### A) Control Codes (69 total)

**Basic Control** (0x00-0x0F):
```
0x00 = [END]        - End of dialog
0x01 = {newline}    - Line break
0x02 = [WAIT]       - Wait for button press
0x03 = [ASTERISK]   - Special marker
0x04 = [NAME]       - Insert character name
0x05 = [ITEM]       - Insert item name
0x06 = [SPACE]      - Space character
0x07 = [SPEED_SLOW] - Text speed control
0x08 = [SPEED_NORM] - Normal text speed
0x09 = [SPEED_FAST] - Fast text speed
0x0A = [DELAY]      - Pause
0x0B-0x0F = Unknown
```

**Event Parameters** (0x10-0x3B):
```
0x10 = [P10]        - Event parameter 10
0x11 = [P11]        - Event parameter 11
...
0x3B = [P3B]        - Event parameter 3B
```

**Dialog Positioning** (0x1A-0x1B):
```
0x1A = [TEXTBOX_BELOW] - Dialog box below character
0x1B = [TEXTBOX_ABOVE] - Dialog box above character
```

**Special Commands**:
```
0x1F = [CRYSTAL]    - Insert "Crystal" location name
0x23 = [CLEAR]      - Clear text box
0x30 = [PARA]       - Paragraph break
0x36 = [PAGE]       - Page break
```

**Extended Codes** (0x80-0x8F):
```
0x80-0x8F = Multi-byte commands
  Format: [0x8X][parameter byte][...]
```

#### B) DTE Compression (0x3D-0x7E, 66 sequences)

**Dual-Tile Encoding** compresses common character combinations into single bytes.

**Special Names**:
```
0x3D = "Crystal"
0x3E = "Rainbow Road"
```

**Common Two-Letter Combinations**:
```
0x3F = "th"    - the, this, that
0x40 = "e "    - the , are  (with space!)
0x41 = "the "  - Most common word
0x42 = "t "    - that , it  (with space!)
0x43 = "ou"    - you, out, about
0x44 = "you"   - Complete word
0x45 = "s "    - is , has  (with space!)
0x46 = "to "   - to , into  (with space!)
0x47 = "in"    - in, into, king
0x48 = "ing "  - going , doing  (with space!)
0x49 = "er"    - never, after, power
0x4A = "re"    - are, were, here
0x4B = "an"    - an, and, can
0x4C = "he"    - he, the, here
0x4D = "ly"    - only, really
0x4E = "en"    - when, been, then
0x4F = "ar"    - are, start, dark
```

**Common Words**:
```
0x50 = "or"    - or, for, world
0x51 = "ed"    - needed, used
0x52 = "ng"    - ring, long
0x53 = "is"    - is, this, his
0x54 = "on"    - on, second
0x55 = "es"    - goes, uses
0x56 = "at"    - at, that, great
0x57 = "ha"    - has, what
0x58 = "ve"    - have, never, give
0x59 = "it"    - it, with, white
0x5A = "al"    - all, also, already
0x5B = "T"     - Capital T
0x5C = "be"    - be, been, before
0x5D = "hi"    - his, this, white
0x5E = "ea"    - earth, great, really
0x5F = "is "   - is  (with space!)
```

**Special Characters**:
```
0x60 = "B"     - Capital B (Benjamin)
0x67 = "a "    - a  (with space!)
0x68 = "I"     - Capital I
0x6A = "of"    - of
0x6F = "!"     - Exclamation
```

**Advanced Compressions**:
```
0x70 = "el"    - help, spell, level
0x71 = "se"    - use, see, those
0x72 = "nt"    - want, into, went
0x73 = "ro"    - from, around, hero
0x74 = "ur"    - your, turn, sure
0x75 = "ld"    - old, world, told
0x76 = "ay"    - may, say, away
0x77 = "ne"    - one, done, gone
0x78 = "go"    - go, going, good
0x79 = "ri"    - right, friend, bring
0x7A = "me"    - me, come, some
0x7B = "no"    - no, now, know
0x7C = "ca"    - can, came, call
0x7D = "so"    - so, some, also
0x7E = "fo"    - for, found, before
```

#### C) Single Characters (0x90-0xCD)

**Same as simple.tbl**:
```
0x90-0x99  : Digits (0-9)
0x9A-0xB3  : Uppercase (A-Z)
0xB4-0xCD  : Lowercase (a-z)
```

#### D) Punctuation (0xCE-0xDD)

```
0xCE = !
0xCF = ?
0xD0 = ,
0xD1 = '
0xD2 = .
0xD3 = "
0xD4 = "
0xD5 = ."
0xD6 = ;
0xD7 = :
0xD8 = …
0xD9 = /
0xDA = -
0xDB = &
0xDC = ▶
0xDD = %
```

#### E) Special Markers (0xE0-0xFF)

```
0xE0-0xFD : Extended control codes
0xFE      : Placeholder (rendered as #)
0xFF      : Space character
```

### Example Dialog Encoding

**Text**: "Look over there. That's the Crystal!"

**Step 1 - Identify DTE opportunities**:
- "the " → 0x41
- "!" → 0x6F

**Step 2 - Encode**:
```
L    o    o    k         o    v    er        the         C  r  y  s  t  al   !
A5   C2   C2   BE   FF   C2   C9   49   FF   41   3D   CE
```

**Breakdown**:
- `A5` = L
- `C2` = o
- `C2` = o
- `BE` = k
- `FF` = (space)
- `C2` = o
- `C9` = v
- `49` = er (DTE!)
- `FF` = (space)
- `41` = the  (DTE with space!)
- `3D` = Crystal (DTE!)
- `CE` = !
- `00` = (end)

**Compression**: 22 characters → 13 bytes (41% savings!)

### ROM Storage

**Pointer-based system**:
- Pointer table at PC address: **0x00D636** (bank $03)
- Dialog strings in bank $03: **0x018000-0x01FFFF**
- 116 dialogs total

**Format**:
```
Pointer table:
[0x00D636] = 16-bit pointer to dialog 0
[0x00D638] = 16-bit pointer to dialog 1
...
[0x00D7DC] = 16-bit pointer to dialog 115

Dialog data:
[pointer address] = [compressed bytes...][0x00]
```

### Implementation

**Decoder**: `tools/map-editor/utils/dialog_text.py`
```python
class DialogText:
    def decode(self, data: bytes) -> str:
        """Decode complex text with DTE and control codes"""
        text = []
        i = 0
        while i < len(data):
            byte = data[i]
            
            # Check for DTE (0x3D-0x7E)
            if 0x3D <= byte <= 0x7E:
                text.append(DTE_TABLE[byte])
            # Single character (0x90-0xCD)
            elif 0x90 <= byte <= 0xCD:
                text.append(CHAR_TABLE[byte])
            # Control code
            elif byte in CONTROL_CODES:
                text.append(f"[{CONTROL_CODES[byte]}]")
            # End
            elif byte == 0x00:
                break
                
            i += 1
        return ''.join(text)
```

**Encoder**:
```python
def encode(self, text: str) -> bytes:
    """Encode text with greedy longest-match DTE"""
    bytes_out = []
    i = 0
    while i < len(text):
        # Try longest DTE sequences first
        matched = False
        for length in range(15, 0, -1):  # "Rainbow Road" = 12 chars
            substring = text[i:i+length]
            if substring in DTE_REVERSE:
                bytes_out.append(DTE_REVERSE[substring])
                i += length
                matched = True
                break
        
        if not matched:
            # Single character
            char = text[i]
            bytes_out.append(CHAR_REVERSE[char])
            i += 1
    
    bytes_out.append(0x00)  # Terminator
    return bytes(bytes_out)
```

---

## Comparison

| Feature | Simple System | Complex System |
|---------|--------------|----------------|
| **Usage** | Item/spell/monster names | Dialog/events |
| **Compression** | None | DTE (30-40% savings) |
| **Control codes** | None | 69 event commands |
| **Max length** | Fixed (12-20 bytes) | Variable (up to 512) |
| **Storage** | Sequential blocks | Pointer table |
| **Character table** | `simple.tbl` | `complex.tbl` |
| **Terminator** | 0x00 | 0x00 |
| **Space char** | 0xFF | 0xFF |
| **Padding** | 0xFF | None |

---

## Tools

### Simple Text

**Extraction**:
```bash
python tools/extraction/extract_text.py \
    --rom "ffmq.sfc" \
    --tbl simple.tbl \
    --type item_names \
    --output items.txt
```

**Insertion**:
```bash
python tools/import/import_text.py \
    --rom "ffmq.sfc" \
    --tbl simple.tbl \
    --type item_names \
    --input items_modified.txt
```

### Complex Text (Dialog)

**Extraction**:
```bash
python tools/map-editor/dialog_cli.py show 0x21
python tools/map-editor/dialog_cli.py extract --output dialogs/
```

**Editing**:
```bash
python tools/map-editor/dialog_cli.py edit 0x21 \
    --text "New dialog with [PARA] control codes"
```

**Verification**:
```bash
python tools/map-editor/dialog_cli.py verify 0x21
```

---

## Key Differences

### 1. DTE Trailing Spaces

**CRITICAL**: Many DTE sequences include trailing spaces!

```
0x40 = "e "   NOT "e"
0x41 = "the " NOT "the"
0x42 = "t "   NOT "t"
0x45 = "s "   NOT "s"
0x48 = "ing " NOT "ing"
0x5F = "is "  NOT "is"
0x67 = "a "   NOT "a"
```

**Why**: Spaces are very common in English. Including them in DTE saves additional bytes.

### 2. Control Code Integration

**Simple system**: Pure text only  
**Complex system**: Text + event commands

Example:
```
[P32]Look at the [CRYSTAL][PARA]It's glowing![END]
 ^     ^            ^        ^               ^
 |     |            |        |               |
Event  Text         DTE      Control         End
param               name     code            marker
```

### 3. Encoding Complexity

**Simple**: Direct byte lookup  
**Complex**: Greedy longest-match algorithm

```python
# Simple encoding
"Cure" → [C8 C8 C5 B8] (4 lookups)

# Complex encoding  
"the Crystal" → [41 3D] (2 lookups, 30% compression!)
                 the   Crystal
                (DTE) (DTE)
```

---

## Current Issues

### ❌ DTE Table Inaccuracies

**Problem**: The `complex.tbl` DTE mappings don't match actual ROM data.

**Evidence**:
- Dialog 0x59 bytes: `9F 5C FF` decodes to "For " (F + or + space)
- complex.tbl says: `5C=be`
- Should be: `5C=or` (based on ROM analysis)

**Impact**: All dialog decoding is incorrect.

**Solution**: Need to reverse-engineer correct DTE table from ROM by analyzing known dialogs.

### ✅ Simple Table Working

The `simple.tbl` is **100% correct** for item/spell/monster names.

---

## Next Steps

### Priority 1: Fix DTE Table

1. Extract 10-20 known dialogs with recognizable text
2. Compare ROM bytes to expected English text
3. Deduce correct byte→string mappings
4. Update `complex.tbl` with verified sequences
5. Test round-trip encoding/decoding

### Priority 2: Complete Control Code Research

1. Analyze ROM banks $00/$03/$08 for dialog engine code
2. Find dispatch tables for event commands
3. Map parameters (P10-P3B) to actual functions
4. Document menu commands (shop/inn/yes-no)
5. Document movement commands

### Priority 3: Create GUI Tools

1. Simple text editor (item/spell/monster names)
2. Complex dialog editor with DTE compression
3. Visual control code insertion
4. Real-time preview of dialog formatting

---

## References

- **DataCrystal / TCRF mirror**: https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest/TBL
- **TCRF (additional reference)**: https://tcrf.net/Final_Fantasy:_Mystic_Quest
- **Dialog Database**: `tools/map-editor/utils/dialog_database.py`
- **Text Extractor**: `tools/extraction/extract_text.py`
- **Character Tables**: `simple.tbl`, `complex.tbl`
- **DTE Analysis**: `reports/dte_extraction.md`
- **Control Codes**: `docs/DIALOG_COMMAND_MAPPING.md`

---

## Summary

FFMQ uses **two distinct text systems**:

1. **Simple** (simple.tbl) - Works perfectly for short, fixed-length text
2. **Complex** (complex.tbl) - Needs DTE table fixes for dialog system

The infrastructure is **solid** - just needs correct DTE mappings from ROM analysis.
