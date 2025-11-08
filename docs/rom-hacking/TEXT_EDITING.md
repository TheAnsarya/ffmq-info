# Text Editing Guide for FFMQ

Complete guide to editing all text in Final Fantasy Mystic Quest using the Phase 3 text pipeline.

## Table of Contents
- [Quick Start](#quick-start)
- [Text Categories](#text-categories)
- [Workflow](#workflow)
- [Character Table](#character-table)
- [Control Codes](#control-codes)
- [Limitations](#limitations)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

## Quick Start

### Extract Text
```bash
# Using Makefile (recommended)
make text-extract

# Or directly
python tools/extract_text_enhanced.py roms/FFMQ.sfc data/extracted/text
```

### Edit Text
Open `data/extracted/text/text_complete.json` or `text_complete.csv` in your editor:
- **JSON**: Best for programmatic editing, preserves metadata
- **CSV**: Best for Excel/spreadsheet editing, simple format

### Import Text
```bash
# Using Makefile (recommended)
make text-rebuild

# Or directly
python tools/import/import_text.py roms/FFMQ.sfc data/extracted/text/text_complete.json roms/FFMQ_modified.sfc
```

### Test
```bash
# Test in emulator
start roms/FFMQ_modified.sfc
```

## Text Categories

### 1. Dialogue (200 entries)
- **Format**: Variable-length, pointer-based
- **Includes**: All NPC conversations, story text, system messages
- **Max Length**: Varies per entry (typically 100-200 characters)
- **Terminator**: `[END]` control code

Example:
```json
{
  "id": 0,
  "category": "dialogue",
  "text": "Benjamin! The Dark King has[NEWLINE]returned! You must save the[NEWLINE]Crystal![END]",
  "address": "0x0F0000",
  "max_length": 128
}
```

### 2. Item Names (256 entries)
- **Format**: Fixed-length, 12 bytes
- **Includes**: All items, weapons, armor, accessories
- **Max Length**: 12 characters (strict!)
- **Padding**: Automatic 0xFF + 0x00 padding

Example:
```json
{
  "id": 0,
  "category": "item_names",
  "text": "Cure",
  "address": "0x0F8000",
  "max_length": 12
}
```

### 3. Spell Names (64 entries)
- **Format**: Fixed-length, 8 bytes
- **Includes**: White magic, wizard magic, special attacks
- **Max Length**: 8 characters (strict!)
- **Padding**: Automatic 0xFF + 0x00 padding

Example:
```json
{
  "id": 0,
  "category": "spell_names",
  "text": "Fire",
  "address": "0x0FA000",
  "max_length": 8
}
```

### 4. Enemy Names (83 entries)
- **Format**: Fixed-length, 12 bytes
- **Includes**: All enemy and boss names
- **Max Length**: 12 characters (strict!)
- **Padding**: Automatic 0xFF + 0x00 padding

Example:
```json
{
  "id": 0,
  "category": "enemy_names",
  "text": "Behemoth",
  "address": "0x0FB000",
  "max_length": 12
}
```

### 5. Location Names
- **Format**: Null-terminated
- **Includes**: Town names, dungeon names, area names
- **Max Length**: Varies per entry
- **Terminator**: `[END]` control code

### 6. Menu Text
- **Format**: Null-terminated
- **Includes**: Battle menu, item menu, status screen text
- **Max Length**: Varies per entry
- **Terminator**: `[END]` control code

### 7. Battle Text
- **Format**: Null-terminated
- **Includes**: Attack messages, effect messages, status messages
- **Max Length**: Varies per entry
- **Terminator**: `[END]` control code

## Workflow

### Complete Round-Trip Workflow

```
┌─────────────────┐
│   Extract Text  │  make text-extract
│  ROM → JSON/CSV │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Edit in Any   │  Excel, VS Code, Text Editor
│  Editor You Like│  Edit text_complete.json or .csv
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│   Import Text   │  make text-rebuild
│  JSON/CSV → ROM │  Validates + Writes to ROM
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Test in Emu    │  Play and verify changes
│  Verify Changes │
└─────────────────┘
```

### Incremental Workflow

After initial extraction, you can edit and rebuild multiple times:

```bash
# Extract once
make text-extract

# Edit → Rebuild → Test cycle (repeat as needed)
# Edit files...
make text-rebuild
# Test in emulator...

# Edit more...
make text-rebuild
# Test again...
```

## Character Table

### Standard Characters (A-Z, a-z, 0-9)
All standard ASCII letters, numbers, and common punctuation are supported:

```
A-Z: Uppercase letters
a-z: Lowercase letters
0-9: Numbers
```

### Punctuation
```
. , ! ? : ; ' " - ( ) / space
```

### Special Characters
```
0x00 = (space)
0xFF = [END] terminator
0xFE = [NEWLINE]
```

### Complete Character Mappings

See `tools/extract_text_enhanced.py` for the full 256-character table including:
- Hiragana characters
- Katakana characters
- Special symbols
- Control codes

## Control Codes

### Text Flow Control

| Code | Hex | Description | Usage |
|------|-----|-------------|-------|
| `[NEWLINE]` | 0xFE | Line break | Force new line |
| `[END]` | 0xFF | End of text | Required at end of all text |
| `[PAGE]` | 0xF0 | Page break | New text box |
| `[CLEAR]` | 0xF1 | Clear box | Clear current text box |
| `[WAIT]` | 0xF2 | Wait for input | Pause until button press |
| `[PAUSE]` | 0xF3 | Auto-pause | Brief automatic pause |

### Dynamic Text Insertion

| Code | Description | Example |
|------|-------------|---------|
| `[PLAYER]` | Insert player name | "Hello, [PLAYER]!" → "Hello, Benjamin!" |
| `[NUMBER]` | Insert number | "HP: [NUMBER]" → "HP: 250" |
| `[ITEM]` | Insert item name | "Got [ITEM]!" → "Got Cure!" |
| `[SPELL]` | Insert spell name | "[SPELL] learned!" → "Fire learned!" |
| `[ENEMY]` | Insert enemy name | "[ENEMY] appeared!" → "Behemoth appeared!" |

### Text Formatting

| Code | Description | Usage |
|------|-------------|-------|
| `[SPEED]` | Text speed | Control text display speed |
| `[COLOR]` | Text color | Change text color |
| `[PORTRAIT]` | Character portrait | Display NPC portrait |
| `[WINDOW]` | Window style | Change text box style |

### Menu/Choice

| Code | Description | Usage |
|------|-------------|-------|
| `[CHOICE]` | Choice menu | Present player with options |

## Limitations

### Fixed-Length Text Constraints

**Item Names**: Maximum 12 characters
```
✓ "Cure"        (4 chars, padded to 12)
✓ "Steel Sword" (11 chars, padded to 12)
✗ "Ultra Mega Death Sword" (21 chars - TOO LONG!)
```

**Spell Names**: Maximum 8 characters
```
✓ "Fire"     (4 chars, padded to 8)
✓ "Thunder"  (7 chars, padded to 8)
✗ "Lightning" (9 chars - TOO LONG!)
```

**Enemy Names**: Maximum 12 characters
```
✓ "Behemoth"      (8 chars, padded to 12)
✓ "Dark King"     (9 chars, padded to 12)
✗ "Super Ultimate Dragon" (22 chars - TOO LONG!)
```

### Variable-Length Text Constraints

Dialogue and other variable-length text must fit within the allocated space for that entry. The tool will warn you if text is too long.

### Control Code Limitations

- Control codes count toward character limits
- Some control codes require specific parameters
- Not all control codes work in all contexts

### Encoding Limitations

- Only characters in the character table are supported
- Unknown characters are replaced with spaces
- Special Unicode characters not supported

## Examples

### Example 1: Simple Text Edit

**Original:**
```json
{
  "id": 5,
  "category": "dialogue",
  "text": "Welcome to Foresta![END]"
}
```

**Modified:**
```json
{
  "id": 5,
  "category": "dialogue",
  "text": "Greetings, traveler! Welcome[NEWLINE]to the beautiful town of[NEWLINE]Foresta![END]"
}
```

### Example 2: Item Name Edit

**Original:**
```json
{
  "id": 10,
  "category": "item_names",
  "text": "Cure"
}
```

**Modified:**
```json
{
  "id": 10,
  "category": "item_names",
  "text": "Heal Potion"
}
```

### Example 3: Using Control Codes

**Original:**
```json
{
  "id": 42,
  "category": "dialogue",
  "text": "You found a treasure![END]"
}
```

**Modified:**
```json
{
  "id": 42,
  "category": "dialogue",
  "text": "[PLAYER] found a[NEWLINE][ITEM]![WAIT][NEWLINE]This will be useful![END]"
}
```

### Example 4: Multi-Line Dialogue

```json
{
  "id": 100,
  "category": "dialogue",
  "text": "The Dark King has returned![NEWLINE][WAIT]You must gather the four[NEWLINE]Crystals to defeat him![NEWLINE][PAUSE]Good luck, [PLAYER]![END]"
}
```

## Editing in Excel/CSV

### CSV Format

The CSV file has these columns:
```
id,category,text,address,max_length
0,dialogue,"Welcome to Foresta![END]",0x0F0000,128
10,item_names,Cure,0x0F8000,12
```

### Excel Tips

1. **Open CSV in Excel**: File → Open → Select `text_complete.csv`
2. **Edit Text Column**: Edit the "text" column cells
3. **Control Codes**: Type them exactly: `[NEWLINE]`, `[END]`, etc.
4. **Save**: Save as CSV (not Excel format!)
5. **Import**: Run `make text-rebuild`

### Common Excel Issues

**Issue**: Excel removes `[END]` tags
- **Fix**: Wrap in quotes: `"Welcome![END]"`

**Issue**: Excel mangles special characters
- **Fix**: Save as "CSV UTF-8" not "CSV"

**Issue**: Excel adds extra commas
- **Fix**: Check for commas in text, escape with quotes

## Troubleshooting

### Error: "Text too long"

**Cause**: Your edited text exceeds the maximum length for that entry.

**Fix**: Shorten the text or use abbreviations. Check the `max_length` field.

```json
{
  "id": 10,
  "category": "item_names",
  "text": "Super Ultimate Mega Sword",  // ✗ Too long (25 chars)
  "max_length": 12
}

// Fixed:
{
  "id": 10,
  "category": "item_names",
  "text": "Mega Sword",  // ✓ OK (10 chars)
  "max_length": 12
}
```

### Error: "Invalid character"

**Cause**: You used a character not in the FFMQ character table.

**Fix**: Use only supported characters (A-Z, a-z, 0-9, punctuation). Unknown characters become spaces.

### Error: "Missing [END] tag"

**Cause**: Variable-length text must end with `[END]`.

**Fix**: Add `[END]` at the end of the text:

```json
"text": "Welcome to Foresta!"  // ✗ Missing [END]
"text": "Welcome to Foresta![END]"  // ✓ Correct
```

### Error: "Validation failed"

**Cause**: Text data doesn't match expected format.

**Fix**: Check JSON syntax, ensure all required fields are present:
- `id`
- `category`
- `text`
- `address`
- `max_length`

### Warning: "Backup failed"

**Cause**: ROM file is read-only or in use.

**Fix**: Close emulator, check file permissions, ensure ROM isn't locked.

### Issue: Text doesn't appear in game

**Possible Causes**:
1. Wrong category used
2. Text too long (truncated)
3. Missing control codes
4. ROM not properly modified

**Debug Steps**:
1. Check extraction summary for correct addresses
2. Verify text length is within limits
3. Ensure `[END]` tags are present
4. Test with simple text first
5. Check emulator console for errors

## Advanced Topics

### Batch Editing with Python

```python
import json

# Load text data
with open('data/extracted/text/text_complete.json', 'r') as f:
    data = json.load(f)

# Edit all item names to uppercase
for entry in data:
    if entry['category'] == 'item_names':
        entry['text'] = entry['text'].upper()

# Save modified data
with open('data/extracted/text/text_complete.json', 'w') as f:
    json.dump(data, f, indent=2)
```

### Translation Projects

The text pipeline is ideal for translation:

1. Extract all text: `make text-extract`
2. Translate `text_complete.csv` in Excel
3. Import translated text: `make text-rebuild`
4. Test thoroughly

**Tips for Translation**:
- Respect character limits (especially for items/spells)
- Test text in-game (some languages may need more space)
- Keep control codes in same positions
- Test all dialogue for proper line breaks

### Custom Text Tools

You can build custom tools using the JSON format:

```python
# Find all dialogue mentioning "Crystal"
import json

with open('data/extracted/text/text_complete.json', 'r') as f:
    data = json.load(f)

for entry in data:
    if entry['category'] == 'dialogue' and 'Crystal' in entry['text']:
        print(f"ID {entry['id']}: {entry['text']}")
```

## Quick Reference

### Common Commands

```bash
# Extract text
make text-extract

# Rebuild text
make text-rebuild

# Full pipeline
make text-pipeline

# Direct import
python tools/import/import_text.py roms/FFMQ.sfc data/extracted/text/text_complete.json roms/FFMQ_modified.sfc
```

### File Locations

```
data/extracted/text/
├── text_complete.json      # Main text data (JSON format)
├── text_complete.csv       # Main text data (CSV format)
└── extraction_summary.txt  # Extraction statistics
```

### Control Code Cheatsheet

```
[NEWLINE]   - New line
[END]       - End text (required!)
[PAGE]      - New text box
[WAIT]      - Wait for button
[PAUSE]     - Auto-pause
[PLAYER]    - Insert player name
[ITEM]      - Insert item name
[SPELL]     - Insert spell name
[ENEMY]     - Insert enemy name
```

### Character Limits

```
Item names:     12 characters max
Spell names:     8 characters max
Enemy names:    12 characters max
Dialogue:       Varies (check max_length field)
```

## Support

For issues or questions:
- Check this guide's [Troubleshooting](#troubleshooting) section
- Review `docs/PHASE_3_COMPLETE.md` for system overview
- Check `tools/extract_text_enhanced.py` source code
- See `SESSION_LOG.md` for development notes

---

**Next Steps**: Once you're comfortable with text editing, try:
- [Map Editing Guide](MAP_EDITING.md) - Edit maps in Tiled
- [Graphics Editing Guide](BUILD_INTEGRATION.md) - Edit sprites
- [Complete ROM Building](PHASE_3_COMPLETE.md) - Build with all mods
