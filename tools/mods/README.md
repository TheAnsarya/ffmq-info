# FFMQ Example Mods

This directory contains example mod scripts that demonstrate how to modify Final Fantasy Mystic Quest using the extracted game data.

## Available Mods

### 1. Double Enemy HP (`double_enemy_hp.py`)
**Difficulty**: Beginner  
**What it does**: Doubles the HP of all 83 enemies

```powershell
python tools/mods/double_enemy_hp.py
python build.ps1
```

Great first mod to learn the basics!

### 2. Boost Spell Power (`boost_spell_power.py`)
**Difficulty**: Beginner  
**What it does**: 
- Increases damage spell power by 50%
- Increases MP costs by 25%

```powershell
python tools/mods/boost_spell_power.py
python build.ps1
```

Makes magic more powerful throughout the game.

### 3. Hard Mode (`hard_mode.py`)
**Difficulty**: Intermediate  
**What it does**:
- Enemy HP +50%
- Enemy attack/defense +25%
- Healing spell power -30%
- All MP costs +20%

```powershell
python tools/mods/hard_mode.py
python build.ps1
```

Creates a challenging playthrough for experienced players.

### 4. Elemental Weaknesses (`add_elemental_weaknesses.py`)
**Difficulty**: Intermediate  
**What it does**: Gives every enemy at least one elemental weakness

```powershell
python tools/mods/add_elemental_weaknesses.py
python build.ps1
```

Encourages strategic spell usage.

## How to Use

### Basic Workflow

1. **Choose a mod** from the list above
2. **Run the mod script**:
   ```powershell
   python tools/mods/your_chosen_mod.py
   ```
3. **Build the ROM**:
   ```powershell
   python build.ps1
   ```
4. **Test in emulator**: Open `roms/ffmq_rebuilt.sfc`

### Reverting Changes

To undo a mod and restore original data:

```powershell
# Revert specific files
git restore data/extracted/enemies/enemies.json
git restore data/spells/spells.json

# Or revert all data
git restore data/

# Rebuild clean ROM
python build.ps1
```

### Combining Mods

You can run multiple mods in sequence:

```powershell
# Apply hard mode
python tools/mods/hard_mode.py

# Then add elemental weaknesses
python tools/mods/add_elemental_weaknesses.py

# Build once with all changes
python build.ps1
```

## Creating Your Own Mods

### Template Script

```python
#!/usr/bin/env python3
"""
My Custom Mod: Description

What your mod does and why.
"""

import json
from pathlib import Path

def my_mod_function():
	"""Main mod logic"""
	project_dir = Path(__file__).parent.parent.parent
	enemies_file = project_dir / "data" / "extracted" / "enemies" / "enemies.json"
	
	# Load data
	with open(enemies_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	# Modify data
	for enemy in data['enemies']:
		# Your changes here
		enemy['hp'] = int(enemy['hp'] * 1.5)
	
	# Save data
	with open(enemies_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print("✅ Mod applied!")

if __name__ == "__main__":
	my_mod_function()
```

### Tips for Mod Creation

1. **Start simple**: Modify one thing at a time
2. **Test frequently**: Build and test after each change
3. **Use git**: Commit before and after applying mods
4. **Document**: Add comments explaining what your mod does
5. **Validate**: Check value ranges (HP: 0-65535, Stats: 0-255)

### Data File Locations

```
data/
├── extracted/
│   ├── enemies/enemies.json          # Enemy stats
│   ├── attacks/attacks.json          # Attack data
│   └── enemy_attack_links/           # Enemy-attack relationships
└── spells/spells.json                # Spell data
```

## Advanced Modding

### Using Visualization Tools

Before and after modding, use visualization tools to analyze changes:

```powershell
# Generate enemy stats visualization
python tools/visualize_elements.py

# Check spell effectiveness
python tools/visualize_spell_effectiveness.py

# View enemy-attack network
python tools/visualize_enemy_attacks.py

# Results in: reports/visualizations/
```

### Running Unit Tests

Verify your changes don't break data integrity:

```powershell
# Run all unit tests
python tests/run_unit_tests.py

# Run integration tests
python tools/run_tests.py
```

### Mod Versioning

Track your mod versions:

```powershell
# Create mod branch
git checkout -b my-mod-v1.0

# Make changes
python tools/mods/my_mod.py

# Commit
git add data/
git commit -m "My Mod v1.0: Description"

# Tag version
git tag my-mod-v1.0
```

## Troubleshooting

### "JSON decode error"
- **Cause**: Syntax error in JSON file
- **Fix**: Restore from git and try again

### "Build fails"
- **Cause**: Invalid data values (e.g., HP > 65535)
- **Fix**: Check value ranges in your mod script

### "Changes don't appear in game"
- **Cause**: Didn't rebuild ROM or testing wrong file
- **Fix**: Run `python build.ps1` and test `roms/ffmq_rebuilt.sfc`

## Related Documentation

- [Modding Quick Start](../../docs/tutorials/MODDING_QUICKSTART.md)
- [Enemy Modding Guide](../../docs/tutorials/ENEMY_MODDING.md)
- [Spell Modding Guide](../../docs/tutorials/SPELL_MODDING.md)

## Sharing Your Mods

Found a cool mod you'd like to share?

1. Clean up your code
2. Add documentation
3. Create a pull request
4. Share on FFMQ communities

---

**Happy modding! 🎮**
