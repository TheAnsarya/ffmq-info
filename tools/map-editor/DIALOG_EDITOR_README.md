# FFMQ Dialog Editor System

A comprehensive, professional-grade dialog editing suite for Final Fantasy Mystic Quest (SNES).

## Overview

The FFMQ Dialog Editor is a complete toolset for viewing, editing, translating, and managing dialog text and event scripts in Final Fantasy Mystic Quest. It provides a modern, user-friendly interface with advanced features like syntax highlighting, autocomplete, visual scripting, and multi-format export/import.

## Features

### Core Systems

- **Dialog Text Encoding/Decoding**
  - Support for FFMQ's custom character encoding
  - Complex character table with multi-character sequences (e.g., "the " → single byte)
  - Automatic compression using longest-match algorithm
  - Full control code support

- **Event Script Engine**
  - Complete parser and bytecode generator
  - Support for branches, loops, conditionals
  - Visual flowchart generation
  - Syntax validation and error checking

- **Dialog Database**
  - Browse and search all dialogs in ROM
  - Address mapping (PC ↔ SNES)
  - Modification tracking
  - Batch operations

### User Interface

- **Dialog Browser**
  - List view with search and filtering
  - Detailed dialog information panel
  - Sorting by ID, address, length, or text
  - Real-time metrics display

- **Enhanced Text Editor**
  - Syntax highlighting for control codes and text
  - Autocomplete for control codes and common phrases
  - Multi-line editing with cursor navigation
  - Real-time validation and warnings

- **FFMQ Dialog Preview**
  - Authentic SNES-style dialog box
  - Animated text display
  - Control code visualization
  - [WAIT] pause indicators

- **Visual Script Flowchart**
  - Graphical representation of event scripts
  - Shows branching logic and flow
  - Interactive node navigation

### Translation Tools

- **Multi-Format Export**
  - JSON - Best for version control
  - CSV - Excel-compatible
  - PO - Gettext for professional translation tools
  - Excel CSV - UTF-8 BOM for Excel

- **Import with Validation**
  - Pre-import validation
  - Detailed error reporting
  - Character encoding verification
  - Length limit checking

## File Structure

```
tools/map-editor/
├── utils/
│   ├── dialog_text.py          # Character encoding and dialog text handling
│   ├── dialog_database.py      # ROM dialog database management
│   ├── event_script.py         # Event script parser and engine
│   └── dialog_export.py        # Export/import tools
├── ui/
│   ├── dialog_editor.py        # Main dialog editor UI
│   ├── dialog_editor_enhanced.py  # Enhanced features (highlighting, autocomplete)
│   ├── dialog_browser.py       # Dialog browser UI
│   └── dialog_integration.py   # Map editor integration
├── docs/
│   └── DIALOG_EDITOR_GUIDE.md  # Complete user and API documentation
├── dialog_editor_app.py        # Complete standalone application
└── tests/
    └── test_dialog_system.py   # Comprehensive test suite
```

## Quick Start

### Installation

```bash
# Install dependencies
pip install pygame

# Navigate to map editor directory
cd tools/map-editor

# Run the complete dialog editor application
python dialog_editor_app.py

# Or run the browser only
python ui/dialog_browser.py
```

### Basic Usage

```python
from utils.dialog_text import DialogText
from utils.dialog_database import DialogDatabase

# Load dialogs from ROM
db = DialogDatabase()
db.load_from_rom("ffmq.smc")

# Create text handler
dt = DialogText()

# Encode text
text = "Welcome to Foresta!\nYour adventure begins."
encoded = dt.encode(text)

# Decode bytes
decoded = dt.decode(encoded)

# Search dialogs
results = db.search_dialogs("Crystal")

# Edit dialog
dialog = db.dialogs[0x0001]
dialog.text = "New text here!"
dialog.raw_bytes = dt.encode(dialog.text)
dialog.modified = True

# Save to ROM
db.save_to_rom("ffmq_modified.smc")
```

### Translation Workflow

```bash
# Export all dialogs to JSON
python utils/dialog_export.py export ffmq.smc dialogs.json --format json --pretty

# Translator edits dialogs.json...

# Validate translation
python utils/dialog_export.py import ffmq.smc dialogs.json --validate-only

# Import translated dialogs
python utils/dialog_export.py import ffmq.smc dialogs.json --output ffmq_translated.smc
```

## Character Encoding

FFMQ uses a custom character encoding with multi-character sequences for compression.

### Character Table

- **Single characters**: A-Z (0x9A-0xB3), a-z (0xB4-0xCD), 0-9 (0x90-0x99)
- **Punctuation**: ! (0xCE), ? (0xCF), , (0xD0), ' (0xD1), . (0xD2)
- **Multi-char sequences**: "the " (0x41), "you" (0x44), "ing " (0x48)
- **Special**: "Crystal" (0x3D), "Rainbow Road" (0x3E), "prophecy" (0x71)

The encoder uses a **longest-match algorithm** to maximize compression:
- Tries to match up to 20 characters at once
- Prefers multi-character sequences over single characters
- Falls back gracefully for unknown characters

### Control Codes

| Code | Byte | Description |
|------|------|-------------|
| `[END]` | 0x00 | End of string (auto-added) |
| `[NEWLINE]` | 0x01 | Line break (use `\n` in text) |
| `[WAIT]` | 0x02 | Wait for button press |
| `[CLEAR]` | 0x03 | Clear dialog box |
| `[NAME]` | 0x04 | Insert character name |
| `[ITEM]` | 0x05 | Insert item name |
| `[SLOW]` | 0x07 | Slow text speed |
| `[NORMAL]` | 0x08 | Normal text speed |
| `[FAST]` | 0x09 | Fast text speed |
| `[WHITE]` | 0x0A | White text |
| `[YELLOW]` | 0x0B | Yellow text |
| `[GREEN]` | 0x0C | Green text |
| `[SOUND:XX]` | 0x0D+XX | Play sound effect |

## Event Scripting

### Script Structure

```
LABEL start
	SHOW_DIALOG 0x0001
	CHECK_FLAG 0x10
	IF_TRUE has_item
	SHOW_DIALOG 0x0002
	GOTO end

LABEL has_item
	SHOW_DIALOG 0x0003
	GIVE_ITEM 0x05
	SET_FLAG 0x11

LABEL end
	END_SCRIPT
```

### Command Categories

- **Dialog**: SHOW_DIALOG, CLOSE_DIALOG, CHOICE
- **Flow Control**: IF_TRUE, IF_FALSE, GOTO, CALL, RETURN, END_SCRIPT
- **Flags**: SET_FLAG, CLEAR_FLAG, CHECK_FLAG
- **Items**: GIVE_ITEM, TAKE_ITEM, CHECK_ITEM
- **Character**: MOVE_NPC, FACE_PLAYER, TELEPORT, LOCK_PLAYER, UNLOCK_PLAYER
- **Effects**: SOUND_EFFECT, MUSIC, FADE_OUT, FADE_IN, SHAKE_SCREEN

See `docs/DIALOG_EDITOR_GUIDE.md` for complete command reference.

## Application Features

### Tab 1: Browser
- Search and filter dialogs
- Sort by ID, address, length, or text
- View detailed dialog information
- See metrics and validation warnings

### Tab 2: Editor
- Syntax-highlighted text editing
- Autocomplete (press Tab)
- Real-time metrics (bytes, characters, lines)
- Live validation
- Save/revert controls

### Tab 3: Scripts
- Event script editor
- Visual flowchart (Ctrl+B to build)
- Syntax highlighting
- Command reference

### Tab 4: Preview
- FFMQ-style dialog box
- Animated text display
- Control code visualization
- Preview any dialog

### Tab 5: Export
- Export to JSON, CSV, PO formats
- Validate all dialogs
- Import translated files
- Status reporting

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Ctrl+1-5 | Switch tabs |
| Ctrl+S | Save dialog |
| Ctrl+P | Toggle preview |
| Ctrl+B | Build script flowchart |
| Tab | Autocomplete |
| Ctrl+Z | Undo (in editors) |
| Ctrl+F | Find (in browser) |

## Testing

Run the comprehensive test suite:

```bash
python tests/test_dialog_system.py
```

Tests cover:
- Character encoding/decoding
- Control code handling
- Dialog validation
- Event script parsing
- Database operations
- Export/import functionality

## API Reference

### DialogText

```python
dt = DialogText()

# Encode text to bytes
encoded = dt.encode("Welcome![WAIT]")

# Decode bytes to text
decoded = dt.decode(encoded)

# Validate text
is_valid, errors = dt.validate("Some text")

# Calculate metrics
metrics = dt.calculate_metrics("Dialog text")
print(f"Bytes: {metrics.byte_count}")
print(f"Characters: {metrics.char_count}")
print(f"Lines: {metrics.line_count}")
```

### DialogDatabase

```python
db = DialogDatabase()

# Load from ROM
db.load_from_rom("ffmq.smc")

# Search dialogs
results = db.search_dialogs("Crystal")

# Get dialog by ID
dialog = db.dialogs[0x0001]

# Save to ROM
db.save_to_rom("ffmq_modified.smc")

# Address conversion
pc_addr = db.snes_to_pc(0x03, 0x8000)  # SNES $03:8000 → PC
bank, snes_addr = db.pc_to_snes(0x018000)  # PC → SNES
```

### EventScriptEngine

```python
engine = EventScriptEngine()

# Parse script
script = engine.parse("""
	SHOW_DIALOG 0x0001
	END_SCRIPT
""")

# Generate bytecode
bytecode = engine.generate_bytecode(script)

# Disassemble bytecode
disassembly = engine.disassemble(bytecode)

# Validate script
is_valid, errors = engine.validate(script)
```

## Architecture

### Dialog Text System
- `CharacterTable`: Manages character encoding table
- `DialogText`: Encode/decode dialog text
- `DialogMetrics`: Calculate and store dialog metrics
- `ControlCode`: Enum of all control codes

### Dialog Database
- `DialogEntry`: Single dialog entry with metadata
- `DialogDatabase`: Complete ROM dialog database
- Address mapping utilities

### Event Script Engine
- `CommandDef`: Command definition
- `EventScript`: Parsed script representation
- `EventScriptEngine`: Parser and bytecode generator

### UI Components
- `EnhancedTextEditor`: Syntax highlighting and autocomplete
- `FFMQDialogPreview`: SNES-style dialog preview
- `VisualScriptFlowchart`: Script visualization
- `DialogBrowser`: Complete browser interface
- `DialogEditorPanel`: Integrated editor panel

### Export/Import
- `DialogExporter`: Export to multiple formats
- `DialogImporter`: Import with validation
- `TranslationEntry`: Translation entry structure

## Contributing

Contributions welcome! Areas for enhancement:

- [ ] Additional export formats (XLIFF, TMX)
- [ ] In-game font rendering
- [ ] Dialog audio timing
- [ ] Advanced search (regex, wildcards)
- [ ] Batch editing operations
- [ ] Script debugging/stepping
- [ ] Custom control code definitions
- [ ] Plugin system

## Documentation

Complete documentation available in:
- `docs/DIALOG_EDITOR_GUIDE.md` - Complete user guide and API reference
- `tools/map-editor/SESSION_SUMMARY.md` - Project creation session notes
- `tools/map-editor/DEVELOPMENT.md` - Architecture and development guide

## License

Part of the FFMQ Info project. See LICENSE file for details.

## Credits

- Dialog system design: Reverse-engineered from FFMQ (SNES)
- Character table: Extracted from FFMQ ROM
- UI framework: pygame
- Testing: unittest

## Version History

### 1.0 (November 2025)
- Initial release
- Complete dialog text system
- Event script engine
- Enhanced UI with syntax highlighting
- Export/import tools
- Comprehensive documentation
- Full test suite

---

**Built with ❤️ for the FFMQ community**
