# FFMQ Dialog Editor - Complete Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Quick Start](#quick-start)
3. [Character Encoding](#character-encoding)
4. [Control Codes](#control-codes)
5. [Event Scripting](#event-scripting)
6. [Dialog Editing Workflow](#dialog-editing-workflow)
7. [Translation Workflow](#translation-workflow)
8. [Advanced Features](#advanced-features)
9. [Troubleshooting](#troubleshooting)
10. [API Reference](#api-reference)

---

## Introduction

The FFMQ Dialog Editor is a comprehensive toolset for viewing, editing, and translating dialog text and event scripts in Final Fantasy Mystic Quest (SNES). It includes:

- **Dialog Text System**: Encode/decode FFMQ's custom character format
- **Event Script Engine**: Parse and generate event scripts with conditional logic
- **Dialog Database**: Browse and search all dialogs in ROM
- **Visual Editor**: Pygame-based UI with syntax highlighting and autocomplete
- **Export/Import Tools**: Support for CSV, JSON, and PO formats for translation

### Features

✨ **Syntax Highlighting**: Color-coded control codes, text, and special characters  
🔍 **Autocomplete**: Suggest control codes and common phrases  
📊 **Visual Flowcharts**: See event script logic flow graphically  
🎮 **FFMQ Preview**: Preview dialog with authentic SNES-style dialog box  
🌍 **Translation Support**: Export/import translations in multiple formats  
📝 **Validation**: Real-time validation of dialog length, control codes, etc.

---

## Quick Start

### Installation

```bash
# Navigate to map editor directory
cd tools/map-editor

# Install dependencies (if needed)
pip install pygame

# Run dialog browser
python ui/dialog_browser.py
```

### Basic Usage

```python
from utils.dialog_text import DialogText
from utils.dialog_database import DialogDatabase

# Create dialog text handler
dialog_text = DialogText()

# Encode text
text = "Welcome to Foresta!\nYour adventure begins."
encoded = dialog_text.encode(text)

# Decode bytes
decoded = dialog_text.decode(encoded)

# Load ROM dialogs
db = DialogDatabase()
db.load_from_rom("ffmq.smc")

# Browse dialogs
for dialog_id, dialog in db.dialogs.items():
	print(f"{dialog_id:04X}: {dialog.text}")
```

---

## Character Encoding

FFMQ uses a custom character encoding with multi-character sequences for compression.

### Character Table

The complex character table (`complex.tbl`) includes:

- **Single characters**: `A-Z`, `a-z`, `0-9`, punctuation
- **Multi-character sequences**: Common words like "the ", "you", "ing "
- **Special entries**: "Crystal", "Rainbow Road", "prophecy"
- **Embedded control codes**: Some entries contain newlines or other codes

### Examples

```
41=the     # "the " (note space) → single byte 0x41
44=you     # "you" → single byte 0x44
48=ing     # "ing " → single byte 0x48
6F=!\n     # "!\n" (exclamation + newline) → single byte 0x6F
```

### Encoding Algorithm

The encoder uses **longest-match** (greedy) algorithm:

1. At each position, try to match the longest possible sequence
2. Check multi-character mappings first (up to 20 characters)
3. Fall back to single-character mappings
4. Skip unknown characters

Example:
```
Input:  "the king"
Step 1: Match "the " (0x41) instead of "t", "h", "e", " " separately
Step 2: Match "k" (0xBE), "i" (0xBC), "n" (0xC1), "g" (0xBA)
Output: [0x41, 0xBE, 0xBC, 0xC1, 0xBA]
```

---

## Control Codes

Control codes modify text display and behavior.

### Basic Control Codes

| Code | Byte | Description | Usage |
|------|------|-------------|-------|
| `[END]` | 0x00 | End of string | Automatically added |
| `[NEWLINE]` | 0x01 | Line break | `\n` in text |
| `[WAIT]` | 0x02 | Wait for button press | User must press A |
| `[CLEAR]` | 0x03 | Clear dialog box | Start fresh screen |
| `[NAME]` | 0x04 | Insert character name | Shows "Benjamin" |
| `[ITEM]` | 0x05 | Insert item name | Shows item being discussed |

### Text Speed

| Code | Byte | Description |
|------|------|-------------|
| `[SLOW]` | 0x07 | Slow text speed |
| `[NORMAL]` | 0x08 | Normal text speed |
| `[FAST]` | 0x09 | Fast text speed |

### Text Color

| Code | Byte | Description |
|------|------|-------------|
| `[WHITE]` | 0x0A | White text (default) |
| `[YELLOW]` | 0x0B | Yellow text (emphasis) |
| `[GREEN]` | 0x0C | Green text (special) |

### Parameterized Codes

Some control codes take parameters:

```
[SOUND:1F]    # Play sound effect 0x1F
```

### Usage Examples

```python
# Basic dialog with wait
text = "Hello, traveler![WAIT]\nWelcome to my shop."

# Multi-line with colors
text = "[YELLOW]Warning![WHITE]\nDanger ahead!"

# With character name
text = "[NAME], you must save the world!"

# Complex example
text = "[SLOW]Once upon a time...[WAIT]\n[NORMAL]A hero arose.[FAST]"
```

---

## Event Scripting

Event scripts control game logic, dialog flow, and conditional behavior.

### Script Structure

```
LABEL start
	SHOW_DIALOG 0x0001      # Show dialog #1
	CHECK_FLAG 0x10         # Check if flag 0x10 is set
	IF_TRUE has_item
	SHOW_DIALOG 0x0002      # "You don't have it"
	GOTO end
	
LABEL has_item
	SHOW_DIALOG 0x0003      # "You have it!"
	GIVE_ITEM 0x05          # Give item #5
	SET_FLAG 0x11           # Set flag 0x11
	
LABEL end
	END_SCRIPT
```

### Command Categories

#### Dialog Commands
- `SHOW_DIALOG <id>` - Display dialog by ID
- `CLOSE_DIALOG` - Close dialog box
- `CHOICE <id>` - Show choice dialog

#### Flow Control
- `IF_TRUE <label>` - Jump if last check was true
- `IF_FALSE <label>` - Jump if last check was false
- `GOTO <label>` - Unconditional jump
- `CALL <label>` - Call subroutine
- `RETURN` - Return from subroutine
- `END_SCRIPT` - End script execution

#### Flags & Items
- `SET_FLAG <flag_id>` - Set flag to true
- `CLEAR_FLAG <flag_id>` - Set flag to false
- `CHECK_FLAG <flag_id>` - Check if flag is set
- `GIVE_ITEM <item_id>` - Add item to inventory
- `TAKE_ITEM <item_id>` - Remove item from inventory
- `CHECK_ITEM <item_id>` - Check if player has item

#### Character Control
- `MOVE_NPC <npc_id> <direction> <steps>` - Move NPC
- `FACE_PLAYER <npc_id>` - NPC faces player
- `TELEPORT <x> <y> <map_id>` - Move player
- `LOCK_PLAYER` - Prevent player movement
- `UNLOCK_PLAYER` - Allow player movement

#### Effects
- `SOUND_EFFECT <sound_id>` - Play sound
- `MUSIC <music_id>` - Change music
- `FADE_OUT` - Fade screen to black
- `FADE_IN` - Fade screen from black
- `SHAKE_SCREEN <duration>` - Shake screen effect

### Example Scripts

**Simple NPC Dialog**
```
LABEL start
	SHOW_DIALOG 0x0010      # "Hello!"
	END_SCRIPT
```

**Quest Check**
```
LABEL npc_talk
	CHECK_FLAG 0x20         # Quest complete?
	IF_TRUE quest_done
	SHOW_DIALOG 0x0030      # "Please help!"
	GOTO end
	
LABEL quest_done
	SHOW_DIALOG 0x0031      # "Thank you!"
	GIVE_ITEM 0x15          # Reward item
	
LABEL end
	END_SCRIPT
```

**Shop Interaction**
```
LABEL shop
	SHOW_DIALOG 0x0040      # "Buy or sell?"
	CHOICE 0x0041           # "Buy / Sell / Leave"
	IF_TRUE buy
	IF_FALSE sell
	GOTO end
	
LABEL buy
	SHOW_SHOP 0x05          # Show shop #5
	GOTO shop
	
LABEL sell
	SHOW_SELL_MENU
	GOTO shop
	
LABEL end
	SHOW_DIALOG 0x0042      # "Come again!"
	END_SCRIPT
```

---

## Dialog Editing Workflow

### 1. Load ROM

```python
from utils.dialog_database import DialogDatabase

db = DialogDatabase()
db.load_from_rom("ffmq.smc")

print(f"Loaded {len(db.dialogs)} dialogs")
```

### 2. Browse Dialogs

```python
# Search by text
results = db.search_dialogs("Crystal")

# Get dialog by ID
dialog = db.dialogs[0x0001]

print(f"Dialog #{dialog.id:04X}")
print(f"Address: ${dialog.address:06X}")
print(f"Text: {dialog.text}")
```

### 3. Edit Dialog

```python
from utils.dialog_text import DialogText

dt = DialogText()

# Get existing dialog
dialog = db.dialogs[0x0001]

# Modify text
new_text = "Welcome, hero!\nYour quest begins."

# Validate
is_valid, messages = dt.validate(new_text)
if not is_valid:
	print(f"Validation errors: {messages}")
else:
	# Update dialog
	dialog.text = new_text
	dialog.raw_bytes = dt.encode(new_text)
	dialog.length = len(dialog.raw_bytes)
	dialog.modified = True
```

### 4. Save to ROM

```python
# Write modified dialogs back to ROM
db.save_to_rom("ffmq_modified.smc")

print(f"Saved {db.get_modified_count()} modified dialogs")
```

---

## Translation Workflow

### Export for Translation

```bash
# Export to JSON (recommended)
python utils/dialog_export.py export ffmq.smc dialogs.json --format json --pretty

# Export to CSV
python utils/dialog_export.py export ffmq.smc dialogs.csv --format csv

# Export to PO (Gettext)
python utils/dialog_export.py export ffmq.smc dialogs.po --format po

# Export to Excel-compatible CSV
python utils/dialog_export.py export ffmq.smc dialogs.csv --format excel
```

### Translate

Edit the exported file and fill in translations:

**JSON Format:**
```json
{
	"dialogs": [
		{
			"id": "0001",
			"original_text": "Welcome to Foresta!",
			"translated_text": "Bienvenido a Foresta!",
			"notes": "Greeting dialog",
			"status": "complete"
		}
	]
}
```

**CSV Format:**
```csv
ID,Original Text,Translated Text,Notes,Status
0001,"Welcome to Foresta!","Bienvenido a Foresta!","Greeting","complete"
```

### Validate Translation

```bash
# Validate without importing
python utils/dialog_export.py import ffmq.smc dialogs.json --validate-only
```

Output:
```
Validation Results:
  Total entries: 500
  Valid translations: 450
  Empty translations: 30
  Invalid translations: 20
  Unknown IDs: 0
  Too long: 10
```

### Import Translation

```bash
# Import from JSON
python utils/dialog_export.py import ffmq.smc dialogs.json --output ffmq_spanish.smc

# Import from CSV
python utils/dialog_export.py import ffmq.smc dialogs.csv --format csv

# Import from PO
python utils/dialog_export.py import ffmq.smc dialogs.po --format po
```

---

## Advanced Features

### Syntax Highlighting

The enhanced text editor provides syntax highlighting:

```python
from ui.dialog_editor_enhanced import EnhancedTextEditor

editor = EnhancedTextEditor(x=10, y=10, width=600, height=400)
editor.text = "Welcome![WAIT]\n[YELLOW]Important![WHITE]"

# Colors:
# - Regular text: White
# - Control codes: Blue
# - Special chars (!?,.): Gold
# - Errors: Red
```

### Autocomplete

Press **Tab** to trigger autocomplete:

- Control code suggestions when typing `[`
- Common phrase suggestions at word boundaries
- Navigate with ↑/↓ arrows
- Accept with Tab or Enter

```python
from ui.dialog_editor_enhanced import AutocompleteEngine

autocomplete = AutocompleteEngine()
suggestions = autocomplete.get_suggestions("Welcome, [", cursor_pos=10)

# Returns:
# [("[WAIT]", "Control code"), ("[NEWLINE]", "Control code"), ...]
```

### Visual Script Flowchart

Visualize event script logic as a flowchart:

```python
from ui.dialog_editor_enhanced import VisualScriptFlowchart
from utils.event_script import EventScript

# Create script
script = EventScript()
script.parse("""
	CHECK_FLAG 0x10
	IF_TRUE has_key
	SHOW_DIALOG 0x0001
	GOTO end
	LABEL has_key
	SHOW_DIALOG 0x0002
	LABEL end
	END_SCRIPT
""")

# Create flowchart
flowchart = VisualScriptFlowchart(width=800, height=600)
flowchart.build_from_script(script)

# Draw to pygame surface
flowchart.draw(surface, font, scroll_y=0)
```

### FFMQ Dialog Preview

Preview dialog with authentic SNES-style dialog box:

```python
from ui.dialog_editor_enhanced import FFMQDialogPreview

preview = FFMQDialogPreview(x=100, y=400, width=480, height=160)
preview.set_text("Welcome, hero!\nPress A to continue.[WAIT]")

# In game loop:
preview.update(dt)
preview.draw(surface, font)

# Features:
# - Animated text scrolling
# - Proper line wrapping
# - [WAIT] pauses with indicator
# - FFMQ-style blue dialog box
```

### Dialog Metrics

Get detailed metrics for dialog text:

```python
from utils.dialog_text import DialogText

dt = DialogText()
text = "Welcome, traveler![WAIT]\nBuy something!"

metrics = dt.calculate_metrics(text)

print(f"Bytes: {metrics.byte_count}")
print(f"Characters: {metrics.char_count}")
print(f"Lines: {metrics.line_count}")
print(f"Estimated time: {metrics.estimated_time:.1f}s")
print(f"Max line length: {metrics.max_line_length}")
print(f"Control codes: {metrics.control_codes}")
print(f"Warnings: {metrics.warnings}")
```

---

## Troubleshooting

### Common Issues

**Dialog too long**
```
Error: Dialog exceeds maximum length (512 bytes)
```
Solution: Shorten text or use multi-character sequences from complex.tbl

**Invalid control code**
```
Error: Unmatched bracket in control code
```
Solution: Ensure all control codes use format `[CODE]` or `[CODE:PARAM]`

**Character not in table**
```
Warning: Character 'é' cannot be encoded
```
Solution: Use only characters in complex.tbl or add custom mapping

**Newline issues**
```
Text displays on one line instead of multiple
```
Solution: Use `\n` for newlines, not `[NEWLINE]` tag (that's for display only)

### Validation

Always validate before encoding:

```python
is_valid, messages = dt.validate(text)
if not is_valid:
	for msg in messages:
		print(f"⚠ {msg}")
```

Common validation checks:
- Dialog length ≤ 512 bytes
- Control codes properly formatted
- All characters can be encoded
- Line lengths ≤ 32 characters (approximate)
- No unmatched brackets

### Debug Tips

**View raw bytes:**
```python
encoded = dt.encode(text)
hex_dump = ' '.join(f'{b:02X}' for b in encoded)
print(hex_dump)
```

**Test round-trip:**
```python
original = "Test text"
encoded = dt.encode(original)
decoded = dt.decode(encoded)
assert original == decoded, "Round-trip failed!"
```

**Check character table:**
```python
char_table = CharacterTable()
print(f"Loaded: {char_table.loaded}")
print(f"Characters: {len(char_table.byte_to_char)}")
print(f"Multi-char: {len(char_table.multi_char_to_byte)}")
```

---

## API Reference

### DialogText

Main class for encoding/decoding dialog text.

```python
class DialogText:
	def __init__(self, char_table: Optional[CharacterTable] = None)
	def encode(self, text: str, add_end: bool = True) -> bytearray
	def decode(self, data: bytes, include_end: bool = False) -> str
	def validate(self, text: str) -> Tuple[bool, List[str]]
	def calculate_metrics(self, text: str) -> DialogMetrics
	def format_for_display(self, text: str, max_width: int = 32) -> List[str]
```

### DialogDatabase

Database for managing all dialogs in ROM.

```python
class DialogDatabase:
	def load_from_rom(self, rom_path: Path) -> int
	def save_to_rom(self, rom_path: Path) -> int
	def search_dialogs(self, query: str) -> List[DialogEntry]
	def get_modified_count(self) -> int
	def snes_to_pc(self, bank: int, address: int) -> int
	def pc_to_snes(self, pc_address: int) -> Tuple[int, int]
```

### EventScriptEngine

Engine for parsing and executing event scripts.

```python
class EventScriptEngine:
	def parse(self, script_text: str) -> EventScript
	def generate_bytecode(self, script: EventScript) -> bytearray
	def disassemble(self, bytecode: bytes) -> str
	def validate(self, script: EventScript) -> Tuple[bool, List[str]]
	def get_command_by_name(self, name: str) -> Optional[CommandDef]
	def get_commands_by_category(self, category: CommandCategory) -> List[CommandDef]
```

### DialogExporter

Export dialogs to various formats.

```python
class DialogExporter:
	def export_to_csv(self, output_path: Path, include_metadata: bool = True) -> int
	def export_to_json(self, output_path: Path, pretty: bool = True) -> int
	def export_to_po(self, output_path: Path) -> int
	def export_to_excel_compatible_csv(self, output_path: Path) -> int
```

### DialogImporter

Import translated dialogs.

```python
class DialogImporter:
	def import_from_csv(self, input_path: Path) -> Tuple[int, List[str]]
	def import_from_json(self, input_path: Path) -> Tuple[int, List[str]]
	def import_from_po(self, input_path: Path) -> Tuple[int, List[str]]
	def validate_import(self, input_path: Path, format: str = 'auto') -> Tuple[bool, List[str], Dict]
```

---

## Examples

### Complete Dialog Editing Example

```python
#!/usr/bin/env python3
from pathlib import Path
from utils.dialog_text import DialogText
from utils.dialog_database import DialogDatabase

# Load ROM
db = DialogDatabase()
db.load_from_rom("ffmq.smc")

# Create text handler
dt = DialogText()

# Find dialog by text
results = db.search_dialogs("Crystal")
if results:
	dialog = results[0]
	print(f"Found dialog #{dialog.id:04X}: {dialog.text}")
	
	# Edit
	new_text = "[YELLOW]Crystal[WHITE] found!\n[SLOW]The world is saved..."
	
	# Validate
	is_valid, messages = dt.validate(new_text)
	if is_valid:
		# Update
		dialog.text = new_text
		dialog.raw_bytes = dt.encode(new_text)
		dialog.length = len(dialog.raw_bytes)
		dialog.modified = True
		
		# Save
		db.save_to_rom("ffmq_modified.smc")
		print("✓ Dialog updated!")
	else:
		print(f"✗ Validation failed: {messages}")
```

### Translation Pipeline Example

```python
#!/usr/bin/env python3
from pathlib import Path
from utils.dialog_text import DialogText
from utils.dialog_database import DialogDatabase
from utils.dialog_export import DialogExporter, DialogImporter

# 1. Export dialogs
db = DialogDatabase()
db.load_from_rom("ffmq.smc")

dt = DialogText()
exporter = DialogExporter(db, dt)

print("Exporting dialogs...")
count = exporter.export_to_json("dialogs_export.json", pretty=True)
print(f"Exported {count} dialogs")

# 2. Translator edits dialogs_export.json...

# 3. Validate translation
importer = DialogImporter(db, dt)
is_valid, errors, stats = importer.validate_import("dialogs_translated.json")

print(f"\nValidation Results:")
print(f"  Valid: {stats['valid_translations']}")
print(f"  Invalid: {stats['invalid_translations']}")

if is_valid:
	# 4. Import translations
	count, errors = importer.import_from_json("dialogs_translated.json")
	print(f"\nImported {count} translations")
	
	# 5. Save translated ROM
	db.save_to_rom("ffmq_translated.smc")
	print("✓ Translated ROM saved!")
else:
	print(f"\n✗ Validation errors found:")
	for error in errors[:10]:
		print(f"  - {error}")
```

---

## License

Part of the FFMQ Info project. See LICENSE file for details.

## Credits

- Dialog system design: Based on FFMQ ROM structure
- Character table: Extracted from FFMQ (SNES)
- UI components: Built with pygame

## Contributing

Contributions welcome! Please see CONTRIBUTING.md for guidelines.

---

**Last Updated:** November 2025  
**Version:** 1.0
