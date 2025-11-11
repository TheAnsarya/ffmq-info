# FFMQ Dialog CLI - Quick Reference

## Overview

The FFMQ Dialog CLI is a comprehensive command-line tool for managing dialog text in Final Fantasy: Mystic Quest ROMs.

## Installation

No installation needed - just Python 3.6+ required.

```bash
cd /path/to/ffmq-info
python tools/map-editor/dialog_cli.py --help
```

## Commands

### 1. List Dialogs

Show all dialog IDs in the ROM.

```bash
# List IDs only
python tools/map-editor/dialog_cli.py list

# List with full text
python tools/map-editor/dialog_cli.py list -v
```

**Output:**
```
Found 116 dialogs
  0x0001  0x0002  0x0004  0x0007  0x000A  0x000B  0x000C  0x000D
  0x000E  0x000F  0x0010  0x0011  0x0012  0x0013  0x0014  0x0015
  ...
```

---

### 2. Show Dialog

Display a specific dialog with metadata.

```bash
python tools/map-editor/dialog_cli.py show 0x21
```

**Output:**
```
Dialog ID:  0x0021
Pointer:    0x00F8D0
Address:    0x01F8D0
Length:     302 bytes

Text:
----------------------------------------------------------------------
[P25][YELLOW][P26][P1A][C81]Look over there.
That's the [CRYSTAL], once the heart of the World.
...
----------------------------------------------------------------------
```

---

### 3. Search Dialogs

Search for text across all dialogs.

```bash
# Simple text search
python tools/map-editor/dialog_cli.py search "Knight"

# Case-sensitive search
python tools/map-editor/dialog_cli.py search "Knight" -s

# Regex search
python tools/map-editor/dialog_cli.py search "K.*t" -r

# Show full text
python tools/map-editor/dialog_cli.py search "prophecy" -v
```

**Output:**
```
Found 4 matches for "Knight":

0x0021: [P25][YELLOW][P26][P1A][C81]Look over there...
  At that time the Knight will appear.

0x0059: For years Mac's been studying a Prophecy...
  The Knight is Benjamin, and you're him.
```

---

### 4. Find Dialogs (Simple)

Quick way to find which dialogs contain specific text.

```bash
# Find dialogs
python tools/map-editor/dialog_cli.py find "Crystal"

# Ignore case
python tools/map-editor/dialog_cli.py find "crystal" -i

# Count only
python tools/map-editor/dialog_cli.py find "prophecy" -c
```

**Output:**
```
Found 12 dialogs containing 'Crystal':
  0x0021  0x0023  0x0024  0x0025  0x0026  0x0027  0x0028  0x0029
  0x002A  0x002B  0x002C  0x002D
```

---

### 5. Edit Dialog

Edit dialog text and write back to ROM.

```bash
# Interactive mode (type text in terminal)
python tools/map-editor/dialog_cli.py edit 0x21

# Inline mode (provide text directly)
python tools/map-editor/dialog_cli.py edit 0x21 --text "New dialog text[PARA]Second paragraph"

# Auto-confirm (no prompt)
python tools/map-editor/dialog_cli.py edit 0x21 --text "New text" --yes

# Save to different ROM
python tools/map-editor/dialog_cli.py edit 0x21 --text "New text" --output patched.sfc
```

**Interactive Example:**
```
Editing Dialog 0x0021
----------------------------------------------------------------------
Current text:
[P25][YELLOW][P26][P1A][C81]Look over there...
----------------------------------------------------------------------

Enter new text (use [TAG] for control codes, empty line to cancel):
This is new text!
[PARA]Second line here.

Validation:
  ✓ Valid

Encoded to 28 bytes (original: 302 bytes)

Save changes? [y/N]: y

✓ Dialog updated and saved to Final Fantasy - Mystic Quest (U) (V1.1).sfc
```

**Control Codes Available:**
- `[END]` - End of string (auto-added)
- `[PARA]` - Paragraph break
- `[PAGE]` - Page break
- `[WAIT]` - Wait for button
- `[CLEAR]` - Clear dialog box
- `[NAME]` - Insert character name
- `[ITEM]` - Insert item name
- `[CRYSTAL]` - Crystal symbol
- `[P10]` through `[P38]` - Position codes
- `[C80]` through `[C8F]` - Color codes
- Many more in complex.tbl

---

### 6. Export Dialogs

Export all dialogs to various formats.

```bash
# Export to JSON (default, includes metadata)
python tools/map-editor/dialog_cli.py export dialogs.json

# Export to plain text (human-readable)
python tools/map-editor/dialog_cli.py export dialogs.txt --format txt

# Export to CSV (spreadsheet-compatible)
python tools/map-editor/dialog_cli.py export dialogs.csv --format csv
```

**JSON Format:**
```json
{
  "dialogs": [
    {
      "id": 1,
      "text": " [ITEM][PAGE][NORMAL]...",
      "bytes": "0x06,0x05,0x36,...",
      "length": 10,
      "pointer": "0xA27F",
      "address": "0x01A27F",
      "references": [],
      "tags": [],
      "notes": "",
      "modified": false
    }
  ],
  "count": 116,
  "rom": "Final Fantasy - Mystic Quest (U) (V1.1).sfc"
}
```

**Text Format:**
```
Dialog 0x0001
======================================================================
 [ITEM][PAGE][NORMAL][NORMAL][NORMAL][NORMAL][NORMAL][SLOW]

Dialog 0x0002
======================================================================
y[CLEAR][CLEAR]
```

**CSV Format:**
```csv
ID,Pointer,Address,Length,Text
0x0001,0x00A27F,0x01A27F,10," [ITEM][PAGE]..."
0x0002,0x0C488,0x01C488,4,"y[CLEAR][CLEAR]"
```

---

### 7. Statistics

Show ROM dialog statistics.

```bash
# Basic stats
python tools/map-editor/dialog_cli.py stats

# Detailed analysis
python tools/map-editor/dialog_cli.py stats -v
```

**Output:**
```
======================================================================
FFMQ DIALOG DATABASE STATISTICS
======================================================================

Dialog Count:
  Total dialogs: 116
  Total bytes: 4,162
  Average bytes per dialog: 35.9

Size Range:
  Smallest dialog: 2 bytes
  Largest dialog: 302 bytes
  Smallest: 0x0004 (2 bytes)
  Largest: 0x0021 (302 bytes)

Control Code Usage:
  [ITEM        ]:  78 occurrences
  [NORMAL      ]:  69 occurrences
  [PAGE        ]:  44 occurrences
  [PARA        ]:  41 occurrences
  [P1A         ]:  37 occurrences

Text Analysis:
  Total characters: 9,876
  Compression ratio: 57.9%
  Unique words: 221
```

---

### 8. Count

Count characters, bytes, and words in dialogs.

```bash
# Count all dialogs
python tools/map-editor/dialog_cli.py count

# Count specific dialog
python tools/map-editor/dialog_cli.py count 0x59
```

**Output (specific):**
```
Dialog 0x0059:
  Characters: 393
  Bytes: 233
  Compression: 40.7%
  Words: 24
  Control codes: 14
```

**Output (all):**
```
All dialogs:
  Total characters: 9,876
  Total bytes: 4,162
  Compression: 57.9%
```

---

## Common Workflows

### Translation Project

1. Export original dialogs:
   ```bash
   python tools/map-editor/dialog_cli.py export original.json
   ```

2. Edit JSON file with translated text (mark `"modified": true`)

3. Import back (when implemented):
   ```bash
   python tools/map-editor/dialog_cli.py import original.json --output translated.sfc
   ```

### Quick Text Changes

Edit specific dialogs:
```bash
python tools/map-editor/dialog_cli.py edit 0x21 --text "Modified text" --yes
```

### Analysis

View statistics and search:
```bash
python tools/map-editor/dialog_cli.py stats -v
python tools/map-editor/dialog_cli.py find "Crystal"
python tools/map-editor/dialog_cli.py count
```

---

## Technical Details

### ROM Structure

- **Format:** LoROM SNES
- **Size:** 512 KiB (524,288 bytes)
- **Dialog Bank:** 0x03 (PC address 0x018000-0x01FFFF)
- **Pointer Table:** 0x00D636
- **Dialog Count:** 116

### Encoding

- **Type:** DTE (Dual Tile Encoding)
- **Compression:** ~58% average
- **Character Table:** complex.tbl (217 entries)
- **Control Codes:** 77 codes (0x00-0x3C, 0x80-0x8F, 0xE0-0xFF)
- **DTE Sequences:** 116 multi-char (e.g., "prophecy" → 0x71)

### Validation

- Maximum dialog length: 512 bytes
- Control codes must be in [BRACKETS]
- All control codes must be defined in complex.tbl
- Text automatically validated before writing

### Safety

- Automatic ROM backup created (.bak file)
- Validation before every write
- In-place or relocated updates (automatic)
- Pointer table automatically updated

---

## Troubleshooting

### "ROM file not found"

Specify ROM path explicitly:
```bash
python tools/map-editor/dialog_cli.py --rom "roms/ffmq.sfc" list
```

### "Dialog exceeds maximum length"

Dialog too large (>512 bytes). Shorten text or use more DTE sequences.

### "Unknown control code"

Use only codes defined in complex.tbl. Check with:
```bash
grep "^\w\{2\}=\[" complex.tbl
```

### "Validation failed"

Check error messages:
- Unclosed brackets: `[TAG` without `]`
- Unknown codes: `[INVALID]` not in complex.tbl
- Too long: Reduce text length

---

## Examples

### Example 1: Simple Edit
```bash
python tools/map-editor/dialog_cli.py edit 0x21 \
  --text "Hello World[PARA]This is a test!" \
  --yes
```

### Example 2: Export and Analyze
```bash
python tools/map-editor/dialog_cli.py export all_dialogs.json
python tools/map-editor/dialog_cli.py stats -v
python tools/map-editor/dialog_cli.py count
```

### Example 3: Find and Edit
```bash
# Find dialogs with "prophecy"
python tools/map-editor/dialog_cli.py find "prophecy"

# Show specific dialog
python tools/map-editor/dialog_cli.py show 0x59

# Edit it
python tools/map-editor/dialog_cli.py edit 0x59
```

---

## Command Summary

| Command | Description | Example |
|---------|-------------|---------|
| `list` | List all dialog IDs | `dialog_cli.py list` |
| `show` | Show specific dialog | `dialog_cli.py show 0x21` |
| `search` | Search for text (advanced) | `dialog_cli.py search "Knight" -v` |
| `find` | Find dialogs (simple) | `dialog_cli.py find "Crystal" -i` |
| `edit` | Edit dialog text | `dialog_cli.py edit 0x21` |
| `export` | Export all dialogs | `dialog_cli.py export dialogs.json` |
| `stats` | Show statistics | `dialog_cli.py stats -v` |
| `count` | Count chars/bytes/words | `dialog_cli.py count 0x59` |

---

**For more info, run:** `python tools/map-editor/dialog_cli.py --help`
