# FFMQ Modding Quick Start Guide

Complete beginner-friendly guide to modding Final Fantasy Mystic Quest using this toolkit.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Your First Mod: Boosting Enemy HP](#your-first-mod-boosting-enemy-hp)
3. [Understanding the Workflow](#understanding-the-workflow)
4. [Common Modding Tasks](#common-modding-tasks)
5. [Testing Your Mods](#testing-your-mods)
6. [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools
- ✅ Python 3.9+ installed
- ✅ Original FFMQ ROM (US V1.1): `Final Fantasy - Mystic Quest (U) (V1.1).sfc`
- ✅ SNES emulator (recommended: Snes9x, bsnes, Mesen2)
- ✅ This repository cloned and set up

### Initial Setup

```powershell
# 1. Clone repository (if not done)
git clone https://github.com/TheAnsarya/ffmq-info.git
cd ffmq-info

# 2. Place your ROM in roms/ folder
copy "path\to\your\rom.sfc" "roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc"

# 3. Run initial extraction
python tools/extract_all_assets.py

# 4. Verify build system works
python build.ps1
```

You should now have:
- `data/extracted/` - All game data in JSON format
- `roms/ffmq_rebuilt.sfc` - Rebuilt ROM (should match original)

## Your First Mod: Boosting Enemy HP

Let's make a simple mod that doubles all enemy HP values.

### Step 1: Understand the Data

```powershell
# Open the enemy data file
code data/extracted/enemies/enemies.json
```

You'll see enemy data structured like this:
```json
{
  "enemies": [
    {
      "id": 0,
      "name": "Behemoth",
      "hp": 400,
      "attack": 40,
      "defense": 45,
      "speed": 25,
      "magic": 60,
      "resistances": 0,
      "weaknesses": 256
    }
  ]
}
```

### Step 2: Create a Mod Script

Create `tools/mods/double_enemy_hp.py`:

```python
#!/usr/bin/env python3
"""
Double Enemy HP Mod

Doubles the HP of all enemies in FFMQ.
"""

import json
from pathlib import Path

def double_enemy_hp():
	"""Double all enemy HP values"""
	project_dir = Path(__file__).parent.parent.parent
	enemies_file = project_dir / "data" / "extracted" / "enemies" / "enemies.json"
	
	# Load enemy data
	with open(enemies_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	# Double all HP values
	for enemy in data['enemies']:
		old_hp = enemy['hp']
		enemy['hp'] = min(old_hp * 2, 65535)  # Cap at max 16-bit value
		print(f"{enemy['name']}: {old_hp} → {enemy['hp']} HP")
	
	# Save modified data
	with open(enemies_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print(f"\n✅ Modified {len(data['enemies'])} enemies")
	print("Next: Run 'python build.ps1' to build modded ROM")

if __name__ == "__main__":
	double_enemy_hp()
```

### Step 3: Apply Your Mod

```powershell
# Run the mod script
python tools/mods/double_enemy_hp.py

# Expected output:
# Behemoth: 400 → 800 HP
# Mad Plant: 60 → 120 HP
# ...
# ✅ Modified 83 enemies
```

### Step 4: Build Modded ROM

```powershell
# Build the ROM with your changes
python build.ps1

# Your modded ROM is now at:
# roms/ffmq_rebuilt.sfc
```

### Step 5: Test in Emulator

1. Open `roms/ffmq_rebuilt.sfc` in your SNES emulator
2. Start a new game or load a save
3. Enter a battle - enemies should have double HP!

### Step 6: Revert Changes (Optional)

```powershell
# Restore original data
git restore data/extracted/enemies/enemies.json

# Rebuild clean ROM
python build.ps1
```

🎉 **Congratulations!** You've created your first FFMQ mod!

## Understanding the Workflow

### The Modding Cycle

```
1. EXTRACT          2. MODIFY          3. BUILD           4. TEST
   │                   │                  │                  │
   ├─→ ROM to JSON ─→ Edit JSON data ─→ JSON to ROM ─→ Play in emulator
   │                   │                  │                  │
   └───────────────────┴──────────────────┴──────────────────┘
                    Repeat as needed
```

### Data Flow

```
Original ROM (roms/*.sfc)
    ↓
Extract tools (tools/extract_*.py)
    ↓
JSON data (data/extracted/*/*.json)
    ↓ ← YOU MODIFY HERE
Build system (build.ps1, src/*.asm)
    ↓
Modded ROM (roms/ffmq_rebuilt.sfc)
    ↓
Test in emulator
```

### Key Directories

```
ffmq-info/
├── data/extracted/          ← Modify JSON files here
│   ├── enemies/
│   ├── attacks/
│   ├── spells/
│   └── text/
├── tools/mods/              ← Put your mod scripts here
├── roms/
│   ├── *.sfc (original)     ← Original ROM (read-only)
│   └── ffmq_rebuilt.sfc     ← Built modded ROM (test this)
└── src/                     ← Advanced: assembly code
```

## Common Modding Tasks

### Task 1: Modify Enemy Stats

**Goal**: Make Behemoth stronger

```python
import json
from pathlib import Path

# Load enemies
enemies_file = Path("data/extracted/enemies/enemies.json")
with open(enemies_file, 'r', encoding='utf-8') as f:
	data = json.load(f)

# Find Behemoth (ID 82)
behemoth = data['enemies'][82]

# Boost stats
behemoth['hp'] = 1000        # More HP
behemoth['attack'] = 100     # Stronger attacks
behemoth['defense'] = 80     # Harder to damage
behemoth['speed'] = 50       # Faster turns

# Save
with open(enemies_file, 'w', encoding='utf-8') as f:
	json.dump(data, f, indent=2)

print("✅ Behemoth is now much stronger!")
```

### Task 2: Modify Spell Power

**Goal**: Make Fire spell more powerful

```python
import json
from pathlib import Path

# Load spells
spells_file = Path("data/spells/spells.json")
with open(spells_file, 'r', encoding='utf-8') as f:
	data = json.load(f)

# Find Fire spell (ID 6 in our data)
fire_spell = next(s for s in data['spells'] if s['name'] == 'Fire')

# Boost power
fire_spell['power'] = 50     # Default is ~20
fire_spell['mp_cost'] = 8    # Increase MP cost too

# Save
with open(spells_file, 'w', encoding='utf-8') as f:
	json.dump(data, f, indent=2)

print("✅ Fire spell is now more powerful!")
```

### Task 3: Modify Attack Power

**Goal**: Make a specific enemy attack stronger

```python
import json
from pathlib import Path

# Load attacks
attacks_file = Path("data/extracted/attacks/attacks.json")
with open(attacks_file, 'r', encoding='utf-8') as f:
	data = json.load(f)

# Boost power of attack ID 10
data['attacks'][10]['power'] = 100

# Save
with open(attacks_file, 'w', encoding='utf-8') as f:
	json.dump(data, f, indent=2)

print("✅ Attack modified!")
```

### Task 4: Change Text

**Goal**: Rename an enemy

```python
import json
from pathlib import Path

# Load enemies
enemies_file = Path("data/extracted/enemies/enemies.json")
with open(enemies_file, 'r', encoding='utf-8') as f:
	data = json.load(f)

# Rename Behemoth
data['enemies'][82]['name'] = "MEGA BOSS"

# Save
with open(enemies_file, 'w', encoding='utf-8') as f:
	json.dump(data, f, indent=2)

print("✅ Enemy renamed!")
```

### Task 5: Create Enemy Element Weaknesses

**Goal**: Make Behemoth weak to Fire

Element bitfield values:
```
Fire   = 0x2000  (bit 13)
Water  = 0x4000  (bit 14)
Earth  = 0x8000  (bit 15)
```

```python
import json
from pathlib import Path

# Load enemies
enemies_file = Path("data/extracted/enemies/enemies.json")
with open(enemies_file, 'r', encoding='utf-8') as f:
	data = json.load(f)

# Make Behemoth weak to Fire
behemoth = data['enemies'][82]
behemoth['weaknesses'] = 0x2000  # Fire element

# Save
with open(enemies_file, 'w', encoding='utf-8') as f:
	json.dump(data, f, indent=2)

print("✅ Behemoth is now weak to Fire!")
```

### Task 6: Randomize Enemy Stats

**Goal**: Add variety to enemies

```python
import json
import random
from pathlib import Path

# Load enemies
enemies_file = Path("data/extracted/enemies/enemies.json")
with open(enemies_file, 'r', encoding='utf-8') as f:
	data = json.load(f)

# Randomize stats within ±20%
for enemy in data['enemies']:
	for stat in ['hp', 'attack', 'defense', 'speed', 'magic']:
		original = enemy[stat]
		variance = int(original * 0.2)
		enemy[stat] = max(1, original + random.randint(-variance, variance))

# Save
with open(enemies_file, 'w', encoding='utf-8') as f:
	json.dump(data, f, indent=2)

print("✅ Enemy stats randomized!")
```

## Testing Your Mods

### Quick Test Checklist

```powershell
# 1. Validate JSON syntax
python -m json.tool data/extracted/enemies/enemies.json > nul
echo "✅ JSON is valid"

# 2. Run unit tests
python tests/run_unit_tests.py

# 3. Build ROM
python build.ps1

# 4. Test in emulator
# Open roms/ffmq_rebuilt.sfc and play!
```

### Using Test Mode

Load a save file near the enemy you modified for quick testing:

1. Use a save editor or emulator save states
2. Position yourself near the target enemy
3. Load the modded ROM
4. Enter battle and verify changes

### Verification Tools

```powershell
# Check if your changes are in the data
python -c "import json; print(json.load(open('data/extracted/enemies/enemies.json'))['enemies'][82])"

# Compare with original
git diff data/extracted/enemies/enemies.json
```

## Troubleshooting

### Problem: "Build fails after modifying data"

**Cause**: Invalid data values (e.g., HP > 65535)

**Solution**: Check value ranges
```python
# Valid ranges:
# HP: 0-65535 (16-bit)
# Stats (attack, defense, etc.): 0-255 (8-bit)
# Element bitfields: 0-65535 (16-bit)
```

### Problem: "Changes don't appear in game"

**Checklist**:
1. ✅ Did you run `python build.ps1` after modifying JSON?
2. ✅ Are you loading the correct ROM (`roms/ffmq_rebuilt.sfc`)?
3. ✅ Did the build complete without errors?
4. ✅ Are you testing the right enemy/spell/item?

### Problem: "JSON syntax error"

**Cause**: Malformed JSON file

**Solution**: Validate and fix
```powershell
# Find the error
python -m json.tool data/extracted/enemies/enemies.json

# Common issues:
# - Missing commas between elements
# - Trailing commas (not allowed in JSON)
# - Unmatched brackets/braces
```

### Problem: "Game crashes after modding"

**Possible causes**:
- Invalid element bitfields (use only valid bits)
- Attack/spell IDs out of range
- Text too long (exceeds allocated space)

**Solution**: Restore and retry
```powershell
git restore data/extracted/enemies/enemies.json
python build.ps1
# Try smaller changes
```

## Best Practices

### 1. Always Backup

```powershell
# Before major changes
git add -A
git commit -m "Backup before modding"
```

### 2. Make Incremental Changes

- Modify one thing at a time
- Test after each change
- Easier to identify what broke

### 3. Use Version Control

```powershell
# Create a branch for your mod
git checkout -b my-mod-name

# Commit your changes
git add data/extracted/
git commit -m "Description of mod"
```

### 4. Document Your Mods

Create a `MOD_NOTES.md`:
```markdown
# My FFMQ Mod

## Changes
- Doubled all enemy HP
- Boosted Fire spell power to 50
- Made Behemoth weak to Fire

## Testing
- Tested first 5 enemies: ✅
- Tested boss battles: ✅
```

### 5. Test Thoroughly

Test checklist:
- [ ] Unit tests pass
- [ ] ROM builds successfully
- [ ] Game loads without crashing
- [ ] Modified content works as expected
- [ ] No unintended side effects

## Next Steps

Now that you know the basics:

1. **Explore Data**: Browse `data/extracted/` to see what you can modify
2. **Read Advanced Guides**: See other tutorials for complex mods
3. **Study Visualizations**: Use `tools/visualize_*.py` to understand game balance
4. **Join Community**: Share your mods and get feedback

## Related Documentation

- [Enemy Modding Guide](ENEMY_MODDING.md) - Detailed enemy editing
- [Spell Modding Guide](SPELL_MODDING.md) - Magic system modifications
- [Text Modding Guide](TEXT_MODDING.md) - Dialogue and text editing
- [Advanced Techniques](ADVANCED_MODDING.md) - Assembly-level modding

---

**Happy Modding! 🎮✨**
