# FFMQ SRAM Editor - Usage Guide

Complete guide to using the FFMQ SRAM save file editor tool.

---

## Table of Contents

1. [Quick Start](#quick-start)
2. [Installation](#installation)
3. [Common Operations](#common-operations)
4. [Advanced Usage](#advanced-usage)
5. [JSON Format](#json-format)
6. [Troubleshooting](#troubleshooting)
7. [Examples](#examples)

---

## Quick Start

### View All Saves

```bash
python tools/save/ffmq_sram_editor.py save.srm --list
```

### Extract Save to JSON

```bash
python tools/save/ffmq_sram_editor.py save.srm --extract 1A --output slot1.json
```

### Edit JSON (modify gold, level, etc.)

```json
{
	"gold": 9999999,
	"character1": {
		"level": 99,
		"current_hp": 999,
		"max_hp": 999
	}
}
```

### Insert Modified Save

```bash
python tools/save/ffmq_sram_editor.py save.srm --insert slot1.json --slot 1A --output save_modified.srm
```

---

## Installation

### Requirements

- Python 3.7+
- No external dependencies (uses only standard library)

### Setup

1. Place `ffmq_sram_editor.py` in `tools/save/` directory
2. Ensure Python is in your PATH
3. Make executable (Unix/Mac):
	```bash
	chmod +x tools/save/ffmq_sram_editor.py
	```

### Verify Installation

```bash
python tools/save/ffmq_sram_editor.py --help
```

---

## Common Operations

### 1. List All Save Slots

Show status of all 9 save slots:

```bash
python tools/save/ffmq_sram_editor.py save.srm --list
```

**Output**:
```
=== SRAM Save Slots ===

1A: ✓ VALID
  Character 1: Benjamin (Lv 25)
  Character 2: Kaeli (Lv 23)
  Gold: 12,500
  Play Time: 05:32:18
  Map: 15

2A: ✗ EMPTY/INVALID

3A: ✓ VALID
  Character 1: Ben (Lv 45)
  Character 2: Phoebe (Lv 44)
  Gold: 850,000
  Play Time: 12:15:47
  Map: 42
```

### 2. Verify Checksums

Check all slots for corruption:

```bash
python tools/save/ffmq_sram_editor.py save.srm --verify
```

**Output**:
```
=== SRAM Verification ===

1A: ✓ Valid (checksum 0x3F2A)
1B: ✓ Valid (checksum 0x3F2A)
1C: ✓ Valid (checksum 0x3F2A)
2A: ✗ Empty/Invalid
2B: ✗ Empty/Invalid
2C: ✗ Empty/Invalid
3A: ✓ Valid (checksum 0x8B14)
3B: ⚠ Checksum error (stored 0x8B14)
3C: ✓ Valid (checksum 0x8B14)

Total: 6 valid, 1 invalid
```

### 3. Fix Checksums

Recalculate and fix all checksums:

```bash
python tools/save/ffmq_sram_editor.py save.srm --fix-checksums
```

**Use Case**: After manually hex-editing SRAM.

### 4. Create Backup

Always backup before editing:

```bash
python tools/save/ffmq_sram_editor.py save.srm --backup save_backup.srm --list
```

### 5. Extract to JSON

Export a save slot for editing:

```bash
# Extract slot 1A
python tools/save/ffmq_sram_editor.py save.srm --extract 1A --output slot1a.json

# Extract slot 3C (third save, copy C)
python tools/save/ffmq_sram_editor.py save.srm --extract 3C --output slot3c.json
```

### 6. Insert from JSON

Import modified save slot:

```bash
# Insert into slot 1A
python tools/save/ffmq_sram_editor.py save.srm --insert slot1a_edited.json --slot 1A --output save_modified.srm

# Insert into all three copies for safety
python tools/save/ffmq_sram_editor.py save.srm --insert edited.json --slot 1A --output temp1.srm
python tools/save/ffmq_sram_editor.py temp1.srm --insert edited.json --slot 1B --output temp2.srm
python tools/save/ffmq_sram_editor.py temp2.srm --insert edited.json --slot 1C --output save_final.srm
```

---

## Advanced Usage

### Create New Game+ Save

1. Extract endgame save:
	```bash
	python tools/save/ffmq_sram_editor.py endgame.srm --extract 1A --output ng_plus.json
	```

2. Edit JSON to reset story but keep stats:
	```json
	{
		"map_id": 0,
		"position": {"x": 10, "y": 15, "facing": 0},
		"character1": {
			"level": 50,
			"experience": 500000,
			"max_hp": 999,
			"current_hp": 999,
			"stats": {
				"current": {"attack": 99, "defense": 99, "speed": 99, "magic": 99}
			}
		},
		"gold": 1000000
	}
	```

3. Insert as new save:
	```bash
	python tools/save/ffmq_sram_editor.py newsave.srm --insert ng_plus.json --slot 1A
	```

### Testing/Debug Saves

Create speedrun testing saves:

**Early Game Test (Level 10, 50k gold)**:
```bash
python tools/save/ffmq_sram_editor.py test.srm --extract 1A --output earlygame.json
# Edit: level=10, gold=50000, map=5
python tools/save/ffmq_sram_editor.py test.srm --insert earlygame.json --slot 1A
```

**Mid Game Test (Level 40, Ice Pyramid)**:
```json
{
	"map_id": 30,
	"character1": {"level": 40, "max_hp": 650},
	"character2": {"level": 40, "max_hp": 600},
	"gold": 500000
}
```

**Boss Rush Test (Max Stats)**:
```json
{
	"character1": {
		"level": 99,
		"max_hp": 999,
		"current_hp": 999,
		"stats": {
			"current": {"attack": 99, "defense": 99, "speed": 99, "magic": 99},
			"base": {"attack": 99, "defense": 99, "speed": 99, "magic": 99}
		}
	}
}
```

### Batch Operations

**Extract all used slots**:
```bash
for slot in 1A 2A 3A; do
	python tools/save/ffmq_sram_editor.py save.srm --extract $slot --output "backup_${slot}.json"
done
```

**Verify multiple files**:
```bash
for file in saves/*.srm; do
	echo "Checking $file:"
	python tools/save/ffmq_sram_editor.py "$file" --verify
done
```

---

## JSON Format

### Complete JSON Structure

```json
{
	"slot_id": 0,
	"valid": true,
	"checksum": "0x3F2A",
	"character1": {
		"name": "Benjamin",
		"level": 25,
		"experience": 50000,
		"current_hp": 320,
		"max_hp": 320,
		"status": "0x00",
		"stats": {
			"current": {
				"attack": 45,
				"defense": 40,
				"speed": 38,
				"magic": 42
			},
			"base": {
				"attack": 30,
				"defense": 28,
				"speed": 26,
				"magic": 32
			}
		},
		"weapon_count": 1,
		"weapon_id": 5
	},
	"character2": {
		"name": "Kaeli",
		"level": 23,
		"experience": 42000,
		"current_hp": 280,
		"max_hp": 280,
		"status": "0x00",
		"stats": {
			"current": {
				"attack": 40,
				"defense": 35,
				"speed": 45,
				"magic": 38
			},
			"base": {
				"attack": 25,
				"defense": 23,
				"speed": 35,
				"magic": 28
			}
		},
		"weapon_count": 1,
		"weapon_id": 8
	},
	"gold": 12500,
	"position": {
		"x": 128,
		"y": 64,
		"facing": 0
	},
	"map_id": 15,
	"play_time": {
		"hours": 5,
		"minutes": 32,
		"seconds": 18,
		"total_seconds": 19938
	},
	"cure_count": 12
}
```

### Field Descriptions

#### Character Fields

- **name**: 1-8 ASCII characters
- **level**: 1-99
- **experience**: 0-9,999,999
- **current_hp**: 0-65535 (should be ≤ max_hp)
- **max_hp**: 0-65535 (typically 50-999)
- **status**: Hex string (0x00-0xFF)
	- 0x00 = Normal
	- 0x01 = Poison
	- 0x02 = Dark
	- 0x80 = Fatal/KO
- **stats.current**: Including equipment bonuses (0-99 each)
- **stats.base**: Without equipment (0-99 each)
- **weapon_count**: Number of equipped weapons (0-?)
- **weapon_id**: Weapon type ID (0-255)

#### Party Fields

- **gold**: 0-9,999,999
- **position.x**: 0-255 (tile X coordinate)
- **position.y**: 0-255 (tile Y coordinate)
- **position.facing**: 0=Down, 1=Up, 2=Left, 3=Right
- **map_id**: 0-255 (current map number)
- **play_time**: Hours (0-255), Minutes (0-59), Seconds (0-59)
- **cure_count**: Number of cures used (0-255)

### Editing Guidelines

#### Safe Edits

These fields can be safely modified:

- **gold**: Any value 0-9,999,999
- **level**: 1-99 (affects stats calculation)
- **experience**: Match level or set to 0
- **current_hp/max_hp**: Reasonable values (50-999)
- **stats.current**: 0-99 (game will recalculate from base + equipment)
- **stats.base**: 0-99 (affects growth)
- **position**: Valid coordinates for current map
- **play_time**: Any values in range

#### Risky Edits

Modify with caution:

- **name**: Must be valid ASCII, max 8 chars
- **status**: Complex bitfield, test thoroughly
- **weapon_id**: Must be valid weapon (unknown IDs)
- **weapon_count**: Unknown effects
- **map_id**: Must be valid map or game may crash

#### Dangerous Edits

Avoid modifying (unknown format):

- **checksum**: Tool recalculates automatically
- **slot_id**: Should match target slot
- **valid**: Set to true unless creating empty slot

---

## Troubleshooting

### Checksum Errors

**Symptom**: "⚠ Checksum error" when verifying

**Causes**:
- Manual hex editing without fixing checksum
- Corrupted save file
- Incomplete file transfer

**Solutions**:
```bash
# Fix all checksums
python tools/save/ffmq_sram_editor.py save.srm --fix-checksums

# Or extract and re-insert to force recalculation
python tools/save/ffmq_sram_editor.py save.srm --extract 1A --output temp.json
python tools/save/ffmq_sram_editor.py save.srm --insert temp.json --slot 1A --output save_fixed.srm
```

### Invalid Save Slots

**Symptom**: "✗ EMPTY/INVALID" when listing

**Causes**:
- Unused save slot
- Missing "FF0!" header
- Completely corrupted data

**Solutions**:
- Slot is empty (normal)
- If should be valid, restore from backup
- Copy from redundant slot (1A→1B→1C)

### Game Crashes After Loading

**Causes**:
- Invalid map_id
- Corrupted position data
- Invalid weapon/equipment IDs
- Malformed character name

**Solutions**:
1. Restore original save backup
2. Re-extract to JSON
3. Make smaller, incremental edits
4. Test after each change
5. Use known-good values from working saves

### JSON Import Fails

**Symptom**: "Error importing JSON"

**Causes**:
- Malformed JSON syntax
- Missing required fields
- Invalid data types

**Solutions**:
```bash
# Validate JSON syntax
python -m json.tool slot1.json

# Compare with freshly extracted JSON
python tools/save/ffmq_sram_editor.py save.srm --extract 1A --output reference.json
```

### File Not Found

**Symptom**: "Error loading SRAM: [Errno 2] No such file"

**Solutions**:
```bash
# Use absolute paths
python tools/save/ffmq_sram_editor.py "C:/Users/me/saves/save.srm" --list

# Or navigate to file directory
cd saves
python ../tools/save/ffmq_sram_editor.py save.srm --list
```

---

## Examples

### Example 1: Max Gold Cheat

```bash
# Extract
python tools/save/ffmq_sram_editor.py save.srm --extract 1A --output maxgold.json

# Edit maxgold.json - change gold to:
#   "gold": 9999999,

# Insert
python tools/save/ffmq_sram_editor.py save.srm --insert maxgold.json --slot 1A --output save_rich.srm
```

### Example 2: Level Up Party

```bash
# Extract
python tools/save/ffmq_sram_editor.py save.srm --extract 1A --output levelup.json

# Edit both characters:
#   "character1": {"level": 50, "experience": 500000, "max_hp": 750}
#   "character2": {"level": 50, "experience": 500000, "max_hp": 700}

# Insert
python tools/save/ffmq_sram_editor.py save.srm --insert levelup.json --slot 1A --output save_leveled.srm
```

### Example 3: Teleport to Location

```bash
# Extract
python tools/save/ffmq_sram_editor.py save.srm --extract 1A --output teleport.json

# Edit position and map:
#   "map_id": 25,
#   "position": {"x": 50, "y": 30, "facing": 0}

# Insert
python tools/save/ffmq_sram_editor.py save.srm --insert teleport.json --slot 1A --output save_teleported.srm
```

### Example 4: Reset Play Time

```bash
# Extract
python tools/save/ffmq_sram_editor.py save.srm --extract 1A --output resettime.json

# Edit play time:
#   "play_time": {"hours": 0, "minutes": 0, "seconds": 0}

# Insert
python tools/save/ffmq_sram_editor.py save.srm --insert resettime.json --slot 1A
```

### Example 5: Create Testing Suite

```bash
#!/bin/bash
# Create multiple test saves

BASE="save.srm"

# Early game test
python tools/save/ffmq_sram_editor.py $BASE --extract 1A --output test_early.json
# Edit: level=10, gold=50000, map=5
python tools/save/ffmq_sram_editor.py $BASE --insert test_early.json --slot 2A --output tests.srm

# Mid game test  
python tools/save/ffmq_sram_editor.py $BASE --extract 1A --output test_mid.json
# Edit: level=40, gold=500000, map=30
python tools/save/ffmq_sram_editor.py tests.srm --insert test_mid.json --slot 2B --output tests.srm

# End game test
python tools/save/ffmq_sram_editor.py $BASE --extract 1A --output test_end.json
# Edit: level=99, gold=9999999, max stats
python tools/save/ffmq_sram_editor.py tests.srm --insert test_end.json --slot 2C --output tests.srm

echo "Test saves created in slots 2A, 2B, 2C"
```

### Example 6: Backup All Saves

```bash
#!/bin/bash
# Backup all valid saves to JSON

SRAM="save.srm"
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Copy original SRAM
cp "$SRAM" "$BACKUP_DIR/original.srm"

# Extract all slots
for slot in 1A 1B 1C 2A 2B 2C 3A 3B 3C; do
	python tools/save/ffmq_sram_editor.py "$SRAM" --extract "$slot" --output "$BACKUP_DIR/slot_${slot}.json" 2>/dev/null
done

echo "Backup created in $BACKUP_DIR"
```

---

## Tips & Best Practices

### Always Create Backups

```bash
# Before any edits
cp save.srm save_backup_$(date +%Y%m%d).srm
```

### Use Version Control

```bash
# Track save file changes
git init save_history
cp save.srm save_history/
cd save_history
git add save.srm
git commit -m "Initial save state"
```

### Test in Emulator First

1. Make edits to copy of SRAM
2. Test in emulator (SNES9x, bsnes, etc.)
3. Verify game loads and plays correctly
4. Only then apply to real cartridge saves

### Incremental Edits

Make small changes and test between:

```bash
# Step 1: Gold only
python tools/save/ffmq_sram_editor.py save.srm --extract 1A --output step1.json
# Edit gold
python tools/save/ffmq_sram_editor.py save.srm --insert step1.json --slot 1A --output save_v1.srm
# TEST

# Step 2: Level
python tools/save/ffmq_sram_editor.py save_v1.srm --extract 1A --output step2.json
# Edit level
python tools/save/ffmq_sram_editor.py save_v1.srm --insert step2.json --slot 1A --output save_v2.srm
# TEST
```

### Keep Reference Saves

Maintain known-good saves for comparison:

```bash
saves/
	original.srm          # Unmodified
	reference_lv25.srm    # Known good level 25
	reference_endgame.srm # Known good endgame
	working.srm           # Current edits
```

---

## See Also

- [SRAM Schema Documentation](SRAM_SCHEMA.md) - Complete field reference
- [DataCrystal SRAM Map](https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest/SRAM_map) - Original research

---

## Support

For bugs or feature requests, create an issue in the project repository.

For SRAM format questions, see SRAM_SCHEMA.md documentation.
