# FFMQ SRAM Editor - Installation & Usage Guide

## Overview

This package provides comprehensive save file editing tools for Final Fantasy: Mystic Quest:

1. **CLI Editor** (`ffmq_sram_editor_enhanced.py`) - Command-line interface
2. **GUI Editor** (`ffmq_sram_gui_editor.py`) - Graphical interface (wxPython)
3. **Research Documentation** - Complete SRAM field mapping

## Features

### Full Coverage
- ✅ Character stats (level, exp, HP, attack, defense, speed, magic)
- ✅ Equipment system (weapons, armor, accessories)
- ✅ Spell/magic learning
- ✅ Inventory management (consumables, key items, weapons, armor)
- ✅ Quest and event flags (256 story events, 256 treasure chests)
- ✅ Battle statistics (battles won, damage dealt, monster book)
- ✅ Party data (gold, position, map, play time)
- ✅ Automatic checksum validation and repair

### Item Database
- **20 consumable/key items**: Cure Potion, Heal Potion, Seed, Refresher, Elixir, Venus Key, Multi-Key, Mask, etc.
- **15 weapons**: Steel Sword, Knight Sword, Excalibur, Axe, Battle Axe, Cat Claw, Bomb, Morning Star, etc.
- **7 armor pieces**: Steel Armor, Noble Armor, Gaia's Armor, Relica Armor, Mystic Robe, Flame Armor, Black Robe
- **3 accessories**: Charm, Magic Ring, Cupid Locket
- **12 spells**: Exit, Cure, Heal, Life, Quake, Blizzard, Fire, Aero, Thunder, White, Meteor, Flare

---

## Installation

### Prerequisites
- **Python 3.8+** (required)
- **wxPython** (optional, for GUI only)

### Windows Installation

```powershell
# Install Python (if not already installed)
# Download from: https://www.python.org/downloads/

# Install wxPython for GUI editor (optional)
pip install wxPython

# Navigate to save tools directory
cd tools/save

# Verify installation
python ffmq_sram_editor_enhanced.py --help
```

### Linux/Mac Installation

```bash
# Install Python (usually pre-installed)
python3 --version

# Install wxPython for GUI editor (optional)
pip3 install wxPython

# Navigate to save tools directory
cd tools/save

# Make scripts executable
chmod +x ffmq_sram_editor_enhanced.py
chmod +x ffmq_sram_gui_editor.py

# Verify installation
python3 ffmq_sram_editor_enhanced.py --help
```

---

## CLI Editor Usage

### Extract Save Slot to JSON

```bash
# Extract slot 0 (first save slot, copy A)
python ffmq_sram_editor_enhanced.py extract mysave.srm --slot 0 --output save1.json

# Extract slot 3 (second save slot, copy A)
python ffmq_sram_editor_enhanced.py extract mysave.srm --slot 3 --output save2.json
```

### Edit JSON Manually

Open `save1.json` in any text editor. The JSON is organized hierarchically:

```json
{
	"character1": {
		"name": "Benjamin",
		"level": 45,
		"hp": {"current": 450, "max": 450},
		"current_stats": {"attack": 75, "defense": 60, ...},
		"weapon": {"name": "Excalibur", "id": 2},
		"equipment": {
			"armor": "Gaia's Armor",
			"accessory1": "Magic Ring",
			"accessory2": "None"
		},
		"spells": ["Exit", "Cure", "Heal", "Fire", "Thunder", "Flare"]
	},
	"party": {
		"gold": 9999999,
		"position": {"x": 15, "y": 20, "facing": "DOWN"},
		"play_time": "12:34:56"
	},
	"inventory": {
		"consumables": [
			{"name": "Cure Potion", "quantity": 99},
			{"name": "Heal Potion", "quantity": 50}
		],
		"key_items": ["Venus Key", "Multi-Key", "Libra Crest"],
		"weapons": {"Excalibur": 1, "Giant's Axe": 1},
		"armor": {"Gaia's Armor": 1, "Black Robe": 1}
	},
	"flags": {
		"treasure_chests_opened": [0, 1, 2, 5, 10, 42],
		"story_events": [0, 1, 2, 3, 4]
	}
}
```

**Editing Tips**:
- Modify values directly (numbers, strings, true/false)
- Add/remove items from arrays
- Change stats, gold, position, etc.
- Max values: Level 99, Gold 9,999,999, HP 65535, Stats 99

### Insert Edited JSON Back to SRAM

```bash
# Insert modified save back to slot 0
python ffmq_sram_editor_enhanced.py insert save1.json mysave.srm --slot 0

# Checksum is automatically recalculated!
```

### Verify SRAM Checksums

```bash
# Verify all slots in SRAM file
python ffmq_sram_editor_enhanced.py verify mysave.srm

# Output:
# Slot 0: ✓ VALID
# Slot 1: ✓ VALID
# Slot 2: ✓ VALID
# Slot 3: EMPTY (no signature)
# ...
```

---

## GUI Editor Usage

### Launch GUI

```bash
# Launch with no file (use File > Open)
python ffmq_sram_gui_editor.py

# Launch with SRAM file pre-loaded
python ffmq_sram_gui_editor.py mysave.srm
```

### GUI Workflow

1. **Open SRAM**: File > Open SRAM (Ctrl+O)
2. **Select Slot**: Choose from dropdown (Slot 0-8, 3 copies of 3 save slots)
3. **Edit Tabs**:
   - **Character 1/2**: Edit name, level, exp, HP, stats, equipment, spells
   - **Party Data**: Edit gold, position, map ID, play time
   - **Inventory**: View/edit items (simplified UI)
   - **Quests & Flags**: View quest progress, treasure chests
   - **Statistics**: View battle stats, monster book
4. **Apply Changes**: Click "Apply Changes to Slot" button
5. **Save SRAM**: File > Save SRAM (Ctrl+S)

### GUI Features

- **Dropdown menus** for weapons, armor, accessories
- **Checkboxes** for learned spells
- **Spinners** for stats (auto-clamp to valid ranges)
- **Real-time validation** (prevents invalid values)
- **Automatic checksum** recalculation on save
- **Slot switching** with unsaved changes warning

---

## Advanced Usage

### Batch Editing Multiple Slots

```bash
# Extract all 3 slots
for i in {0..2}; do
  python ffmq_sram_editor_enhanced.py extract mysave.srm --slot $i --output slot$i.json
done

# Edit JSON files (e.g., max gold on all)
# (Use jq, sed, or manual editing)

# Insert all back
for i in {0..2}; do
  python ffmq_sram_editor_enhanced.py insert slot$i.json mysave.srm --slot $i
done
```

### PowerShell Batch (Windows)

```powershell
# Extract all slots
0..2 | ForEach-Object {
  python ffmq_sram_editor_enhanced.py extract mysave.srm --slot $_ --output "slot$_.json"
}

# Insert all slots
0..2 | ForEach-Object {
  python ffmq_sram_editor_enhanced.py insert "slot$_.json" mysave.srm --slot $_
}
```

### Create Max Stats Template

```python
import json

template = {
	"character1": {
		"level": 99,
		"experience": 9999999,
		"hp": {"current": 9999, "max": 9999},
		"current_stats": {"attack": 99, "defense": 99, "speed": 99, "magic": 99},
		"base_stats": {"attack": 99, "defense": 99, "speed": 99, "magic": 99},
		"spells": ["Exit", "Cure", "Heal", "Life", "Quake", "Blizzard", 
		           "Fire", "Aero", "Thunder", "White", "Meteor", "Flare"]
	},
	"party": {"gold": 9999999}
}

with open('max_stats_template.json', 'w') as f:
	json.dump(template, f, indent='\t')
```

---

## SRAM Structure Reference

### Slot Layout (908 bytes each)

```
0x000-0x003: Signature "FF0!"
0x004-0x005: Checksum (16-bit, little-endian)
0x006-0x055: Character 1 (80 bytes)
0x056-0x0A5: Character 2 (80 bytes)
0x0A6-0x0A8: Gold (24-bit, max 9,999,999)
0x0AB-0x0AC: Position X, Y
0x0AD: Facing direction (0=Down, 1=Up, 2=Left, 3=Right)
0x0B3: Map ID
0x0B9-0x0BB: Play time (Hours, Minutes, Seconds)
0x0C1: Cure count
0x0C2-0x38B: Inventory, flags, statistics (714 bytes)
```

### Character Block (80 bytes each)

```
0x00-0x07: Name (8 bytes ASCII)
0x10: Level (1-99)
0x11-0x13: Experience (24-bit, max 9,999,999)
0x14-0x15: Current HP (16-bit)
0x16-0x17: Max HP (16-bit)
0x21: Status effects
0x22-0x25: Current stats (Attack, Defense, Speed, Magic)
0x26-0x29: Base stats (Attack, Defense, Speed, Magic)
0x30-0x31: Weapon (count, ID)
0x32-0x36: Equipment (Armor, Helmet, Shield, Accessory 1, Accessory 2)
0x37-0x38: Learned spells (16-bit bitfield)
0x39: Character flags (in party, available)
0x3C-0x3F: Status resistances (Poison, Paralysis, Petrify, Fatal)
```

### Inventory Block

```
0x0C2-0x0E1: Consumable items (16 items × 2 bytes)
0x0E2-0x0E3: Key items bitfield (16 bits)
0x0E4-0x103: Weapon inventory (15 weapons × 2 bytes)
0x104-0x113: Armor inventory (7 armor × 2 bytes)
0x114-0x11B: Accessory inventory (3 accessories × 2 bytes)
```

### Quest Flags

```
0x1C2-0x1E1: Story event flags (256 bits)
0x1E2-0x201: Treasure chest flags (256 bits)
0x202-0x211: NPC interaction flags (128 bits)
0x212-0x221: Battlefield completion flags (128 bits)
```

---

## Troubleshooting

### "Invalid SRAM size" Error

- **Problem**: SRAM file is not exactly 8,172 bytes (0x1FEC)
- **Solution**: Verify file is genuine FFMQ save file, not corrupted

### "Invalid slot signature" Error

- **Problem**: Slot doesn't start with "FF0!"
- **Solution**: Slot may be empty or corrupted; try another slot (0-8)

### "Invalid checksum" Warning

- **Problem**: Checksum doesn't match data
- **Solution**: Editor auto-fixes this on save; ignore warning or manually fix

### wxPython Import Error

- **Problem**: `ImportError: No module named 'wx'`
- **Solution**: Install wxPython: `pip install wxPython`

### JSON Parsing Error

- **Problem**: "JSONDecodeError: Expecting property name"
- **Solution**: Fix JSON syntax (missing commas, quotes, brackets)

### Changes Not Appearing In-Game

- **Problem**: Edited save not loading correctly
- **Solution**: 
  1. Verify checksum is valid (`verify` command)
  2. Ensure correct slot was edited (0-8)
  3. Check emulator is loading correct .srm file
  4. Try editing all 3 copies of slot (e.g., 0, 1, 2 for first save)

---

## Examples

### Max Out Everything

```bash
# Extract
python ffmq_sram_editor_enhanced.py extract mysave.srm --slot 0 -o max.json

# Edit max.json (or use Python script)
# Set: level=99, exp=9999999, hp=9999, all stats=99, gold=9999999
# Add: all weapons, all armor, all spells

# Insert
python ffmq_sram_editor_enhanced.py insert max.json mysave.srm --slot 0
```

### Unlock All Spells

```json
"character1": {
	"spells": [
		"Exit", "Cure", "Heal", "Life",
		"Quake", "Blizzard", "Fire", "Aero",
		"Thunder", "White", "Meteor", "Flare"
	]
}
```

### Open All Treasure Chests

```json
"flags": {
	"treasure_chests_opened": [
		0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, ... 255
	]
}
```

(Generate with Python: `list(range(256))`)

### Change Starting Position

```json
"party": {
	"position": {"x": 15, "y": 20, "facing": "DOWN"},
	"map_id": 5
}
```

---

## Documentation

- **SRAM Schema**: `docs/save/SRAM_SCHEMA.md` - Original known fields
- **Unknown Fields Research**: `docs/save/SRAM_UNKNOWN_FIELDS_RESEARCH.md` - Complete SRAM map
- **Editor Usage**: `docs/save/SRAM_EDITOR_USAGE.md` - Original CLI usage
- **GitHub Issues**: `docs/save/SRAM_GITHUB_ISSUES.md` - Feature requests and bugs

---

## Credits

- **FFMQ Disassembly Project**: ROM analysis and data extraction
- **DataCrystal**: SRAM structure reference
- **wxPython**: GUI framework

---

## License

See LICENSE file in repository root.

---

## Support

For issues, questions, or feature requests:
1. Check existing GitHub issues: `docs/save/SRAM_GITHUB_ISSUES.md`
2. Review documentation above
3. Open new GitHub issue with:
   - SRAM file size and source
   - Python version (`python --version`)
   - wxPython version (`pip show wxPython`)
   - Full error message and traceback
   - Steps to reproduce

---

**Happy save editing!** 🎮
