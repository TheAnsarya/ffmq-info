# FFMQ Enemy Editor - User Guide

## Quick Start

### Launch the Editor

```bash
python tools/enemy_editor_gui.py
```

**Requirements:**
- Python 3.7 or later
- tkinter (usually included with Python)
- Enemy data extracted (run `python tools/extraction/extract_enemies.py` first)

## Interface Overview

```
┌─────────────────────────────────────────────────────────────────┐
│ File  Edit  Tools  Help                                         │
├───────────┬─────────────────────────────────────────────────────┤
│ Enemies   │ Enemy Information                                   │
│           │ ID: 000                                             │
│ Search:   │ Name: Brownie                                       │
│ [____]    │                                                     │
│           ├─────────────────────────────────────────────────────┤
│ 00: Brow..│ Stats│Resistances│Weaknesses│Level & Rewards       │
│ 01: Mint..│                                                     │
│ 02: Red ..│ HP:        [50 ] ━━━━━━━━━━━━━━━━━━━━━━━━         │
│ ...       │ Attack:    [3  ] ━━━━                               │
│ (83 total)│ Defense:   [1  ] ━                                  │
│           │ Speed:     [3  ] ━━━                                │
│           │ ...                                                 │
│           │                                                     │
│           │ [Previous Enemy] [Next Enemy]    [Apply Changes]   │
├───────────┴─────────────────────────────────────────────────────┤
│ Ready                                                            │
└─────────────────────────────────────────────────────────────────┘
```

## Features

### 1. Enemy Selection

**Browse Enemies:**
- Scroll through the list of 83 enemies on the left
- Click any enemy to load their data
- Use Previous/Next buttons to navigate sequentially

**Search:**
- Type in the search box to filter enemies
- Search is case-insensitive
- Matches enemy names (e.g., "toad" shows all toad variants)

### 2. Editing Stats

**Stats Tab:**
- Edit all basic stats: HP, Attack, Defense, Speed, etc.
- Use spinboxes for precise values
- Use sliders for quick adjustments
- Values update in real-time

**Stat Ranges:**
- HP: 0 - 65,535
- All other stats: 0 - 255

### 3. Resistances & Weaknesses

**Visual Element Selection:**

Each element has a checkbox - just click to toggle!

**Elements Available:**
- **Status Effects:** Silence, Blind, Poison, Confusion, Sleep, Paralysis, Stone, Doom
- **Damage Types:** Projectile, Bomb, Axe, Zombie  
- **Elements:** Air, Fire, Water, Earth

**Example: Making a Fire-Resistant Plant Enemy**
1. Go to Resistances tab
2. Check: Fire, Axe
3. Go to Weaknesses tab  
4. Check: Water, Bomb
5. Click "Apply Changes"

**Technical Info:**
- See the hex bitfield value at the bottom
- Useful for debugging or manual ROM editing

### 4. Level & Rewards

**Configure:**
- **Level:** Enemy's level (1-99)
- **XP Multiplier:** Experience points multiplier (0-255)
- **GP Multiplier:** Gold pieces multiplier (0-255)

**How Rewards Work:**
```
Actual XP = Base XP × XP Multiplier
Actual GP = Base GP × GP Multiplier
```

## Workflow

### Basic Edit Workflow

1. **Select Enemy** - Click enemy in list or use Previous/Next
2. **Edit Stats** - Modify values in the Stats tab
3. **Set Elements** - Configure resistances and weaknesses
4. **Apply Changes** - Click "Apply Changes" button
5. **Save** - File → Save (Ctrl+S)
6. **Export** - File → Export to ASM (Ctrl+E)

### Making a "Super Brownie" Mod

```
1. Select "00: Brownie" from the list
2. Stats Tab:
   - HP: 50 → 500
   - Attack: 3 → 15
   - Defense: 1 → 10
3. Resistances Tab:
   - Check: Fire, Earth
4. Weaknesses Tab:
   - Check: Water
5. Level & Rewards Tab:
   - Level: 1 → 5
   - XP Multiplier: 22 → 50
6. Click "Apply Changes"
7. File → Save
8. File → Export to ASM
```

### Creating Difficulty Presets

**Easy Mode (All Enemies):**
- Reduce HP by 50%
- Reduce Attack by 25%
- Add more weaknesses

**Hard Mode (All Enemies):**
- Increase HP by 200%
- Increase all stats by 50%
- Remove some weaknesses
- Add resistances

**Elemental Chaos:**
- Randomize all resistances
- Randomize all weaknesses
- Keep stats the same

## Menu Commands

### File Menu

- **Save** (Ctrl+S) - Save changes to JSON
  - Creates backup: `enemies.json.backup`
  - Preserves original if something goes wrong

- **Export to ASM** (Ctrl+E) - Convert JSON to assembly
  - Runs all conversion tools
  - Generates ASM in `data/converted/`
  - Ready for ROM build

- **Exit** - Close the editor
  - Prompts if unsaved changes exist

### Edit Menu

- **Undo** (Ctrl+Z) - Undo last change
  - Reverts current enemy to previous state
  - Can undo multiple times

- **Reset Enemy** - Reload current enemy from disk
  - Discards all unsaved changes for this enemy
  - Asks for confirmation

- **Reset All** - Reload all enemies from disk
  - Discards ALL unsaved changes
  - Asks for confirmation

### Tools Menu

- **Verify vs GameFAQs** - Check data accuracy
  - Compares enemy HP against GameFAQs database
  - Shows which enemies match/don't match
  - Opens results in new window

- **Test Pipeline** - Run complete data pipeline test
  - Tests extraction, conversion, full workflow
  - Shows test results
  - Useful for debugging

### Help Menu

- **About** - Version and author information

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+S` | Save changes |
| `Ctrl+E` | Export to ASM |
| `Ctrl+Z` | Undo last change |
| `Up/Down` | Navigate enemy list |
| `Tab` | Move between fields |
| `Enter` | Apply changes (when field focused) |

## Tips & Tricks

### 1. Batch Editing Multiple Enemies

While the GUI doesn't have batch edit built-in, you can:
1. Edit enemies one by one (use Next button)
2. Apply Changes after each
3. Save once at the end
4. Or edit the JSON file directly for mass changes

### 2. Comparing with Original Data

1. Tools → Verify vs GameFAQs
2. Check which enemies you've modified
3. Compare HP values

### 3. Testing Changes Quickly

1. Make edits
2. File → Save
3. File → Export to ASM
4. Tools → Test Pipeline (verify conversion worked)

### 4. Element Combinations

**Common Resistance Patterns:**
- **Plants:** Fire, Axe
- **Undead:** Axe, Air, Fire, Earth
- **Water Enemies:** Water, resist Fire
- **Flying Enemies:** Air, Projectile

**Common Weakness Patterns:**
- **Plants:** Poison (yes, poison!)
- **Undead:** Status effects (Blind, Silence)
- **Mechanical:** Bomb
- **Dragons:** Specific opposing elements

### 5. Balancing Tips

**Making Enemies Harder:**
- Increase HP (most noticeable)
- Increase Defense (reduces physical damage)
- Add resistances (make certain strategies useless)
- Remove weaknesses

**Making Enemies Easier:**
- Reduce HP
- Add weaknesses (especially to common elements)
- Reduce Defense and Evade

**Making Boss Fights Interesting:**
- High HP but specific weaknesses
- Strong resistances but one major weakness
- High stats but beatable with right strategy

## Troubleshooting

### "Enemy data not found!"

**Problem:** JSON file doesn't exist

**Solution:**
```bash
python tools/extraction/extract_enemies.py
```

### Changes Not Reflected in Game

**Checklist:**
1. ✓ Clicked "Apply Changes"?
2. ✓ Saved the file (Ctrl+S)?
3. ✓ Exported to ASM (Ctrl+E)?
4. ✓ Rebuilt the ROM?
5. ✓ Using the new ROM in emulator?

### Export Fails

**Check:**
- Conversion scripts are in `tools/conversion/`
- Python environment has all dependencies
- Run: `python tools/conversion/convert_all.py` manually to see error

### GUI Won't Launch

**Windows:**
```bash
# Check if tkinter is installed
python -c "import tkinter; print('OK')"
```

If error, reinstall Python with tcl/tk support

**Linux:**
```bash
sudo apt-get install python3-tk
```

**macOS:**
```bash
# Usually included with Python
# If not, reinstall Python from python.org
```

## Advanced Usage

### Direct JSON Editing

For batch operations, edit `data/extracted/enemies/enemies.json` directly:

```python
import json

# Load data
with open('data/extracted/enemies/enemies.json', 'r') as f:
    data = json.load(f)

# Boost all early-game enemies (first 10)
for enemy in data['enemies'][:10]:
    enemy['hp'] = int(enemy['hp'] * 1.5)
    enemy['attack'] = int(enemy['attack'] * 1.2)

# Save
with open('data/extracted/enemies/enemies.json', 'w') as f:
    json.dump(data, f, indent=2)
```

Then reopen the GUI to see changes.

### Integration with Build System

After exporting to ASM:

```bash
# Convert data
python tools/conversion/convert_all.py

# Build ROM (when build integration is complete)
make rom

# Test in emulator
# (Use your preferred SNES emulator)
```

## Complete Example: Elemental Themed Mod

### Goal: Make each enemy strongly elemental-themed

**Fire Enemies (Flazzard, etc.):**
- Resistance: Fire, Bomb
- Weakness: Water, Earth
- Boost Attack stat

**Water Enemies (Mad Toad, etc.):**
- Resistance: Water
- Weakness: Fire, Air
- Boost Defense stat

**Earth Enemies (Brownie, etc.):**
- Resistance: Earth, Poison
- Weakness: Air, Bomb
- Boost HP

**Air Enemies (Roc, etc.):**
- Resistance: Air, Projectile
- Weakness: Earth
- Boost Speed stat

**Steps:**
1. Open GUI
2. For each enemy type, set resistances/weaknesses
3. Adjust stats to match element (fast air, tanky earth, etc.)
4. Save and export
5. Build ROM
6. Enjoy themed challenge!

## Reference Tables

### Element Bitfield Values

| Element | Hex Value | Decimal |
|---------|-----------|---------|
| Silence | 0x0001 | 1 |
| Blind | 0x0002 | 2 |
| Poison | 0x0004 | 4 |
| Confusion | 0x0008 | 8 |
| Sleep | 0x0010 | 16 |
| Paralysis | 0x0020 | 32 |
| Stone | 0x0040 | 64 |
| Doom | 0x0080 | 128 |
| Projectile | 0x0100 | 256 |
| Bomb | 0x0200 | 512 |
| Axe | 0x0400 | 1024 |
| Zombie | 0x0800 | 2048 |
| Air | 0x1000 | 4096 |
| Fire | 0x2000 | 8192 |
| Water | 0x4000 | 16384 |
| Earth | 0x8000 | 32768 |

### Common Stat Values

| Enemy Type | Typical HP | Typical Attack | Level |
|------------|-----------|----------------|-------|
| Early Game (Brownie) | 50-200 | 3-12 | 1-5 |
| Mid Game (Flazzard) | 300-600 | 15-25 | 6-15 |
| Late Game (Pazuzu) | 800-2000 | 30-45 | 16-25 |
| Bosses | 6000-40000 | 40-80 | 20-99 |

## Support

For issues or questions:
- Check `docs/BATTLE_DATA_PIPELINE.md` for technical details
- Run `python tools/test_pipeline.py` to verify setup
- See extraction/conversion tool source for data format details

Happy modding! 🎮
