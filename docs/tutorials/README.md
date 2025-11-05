# FFMQ Modding Tutorials

Complete guide to modding Final Fantasy Mystic Quest, from basic data editing to advanced assembly modifications.

## Tutorial Index

### 🎯 Getting Started

**[Modding Quick Start](MODDING_QUICKSTART.md)** ⭐ *Start here!*
- Your first mod: Double enemy HP
- Understanding the modding workflow
- 6 common modding tasks
- Testing and troubleshooting
- **Difficulty**: Beginner
- **Time**: 30 minutes

### 📊 Data Modding Guides

**[Enemy Modding Guide](ENEMY_MODDING.md)**
- Complete enemy data structure reference
- Element system (weaknesses/resistances)
- 9 code examples (super boss, scaling, balance)
- Validation and testing
- **Difficulty**: Beginner to Intermediate
- **Time**: 1-2 hours

**[Spell Modding Guide](SPELL_MODDING.md)**
- Spell system overview (16 effects, 12 learnable)
- MP cost balancing guidelines
- 9 code examples (power, costs, elements)
- Preset spell configurations
- **Difficulty**: Beginner to Intermediate
- **Time**: 1-2 hours

**[Text Modding Guide](TEXT_MODDING.md)**
- Character encoding table
- Enemy name editing
- Text extraction tools
- 6 code examples (renaming, validation)
- Dialogue system overview
- **Difficulty**: Intermediate
- **Time**: 1-2 hours

### ⚙️ Advanced Modding

**[Advanced Modding Guide](ADVANCED_MODDING.md)**
- 65816 assembly basics
- Battle formula modifications
- ROM patching (IPS/UPS)
- Custom mechanics (auto-dash, save anywhere)
- Complete example mods
- **Difficulty**: Advanced
- **Time**: 3-5 hours

## Learning Paths

### Path 1: Casual Modder

*Goal: Make simple balance changes*

1. **Modding Quick Start** - Learn the basics
2. **Enemy Modding** - Adjust enemy difficulty
3. **Spell Modding** - Balance magic system
4. **Use example mods** - `tools/mods/` directory

**Time commitment**: 2-3 hours

### Path 2: Aspiring Randomizer

*Goal: Create significant content variations*

1. **Modding Quick Start** - Foundation
2. **Enemy Modding** - Random stats/weaknesses
3. **Spell Modding** - Random power/costs
4. **Text Modding** - Custom names
5. **Advanced: ROM Patching** - Distribution

**Time commitment**: 5-8 hours

### Path 3: Complete Overhaul

*Goal: Create major gameplay changes*

1. **All basic tutorials** - Master data editing
2. **Advanced Modding** - Assembly and formulas
3. **Battle formula modification** - Change core mechanics
4. **Custom features** - New game modes

**Time commitment**: 10-20 hours

## Quick Reference

### Common Tasks

| Task | Tutorial | Difficulty |
|------|----------|-----------|
| Change enemy HP | [Enemy Modding](ENEMY_MODDING.md#example-1-create-a-super-boss) | ⭐ Easy |
| Rename enemies | [Text Modding](TEXT_MODDING.md#example-1-rename-an-enemy) | ⭐ Easy |
| Boost spell power | [Spell Modding](SPELL_MODDING.md#example-1-boost-spell-power) | ⭐ Easy |
| Balance MP costs | [Spell Modding](SPELL_MODDING.md#example-4-balance-mp-costs) | ⭐⭐ Medium |
| Add weaknesses | [Enemy Modding](ENEMY_MODDING.md#example-4-add-random-weaknesses) | ⭐⭐ Medium |
| Create difficulty mode | [Enemy Modding](ENEMY_MODDING.md#example-2-apply-difficulty-multiplier) | ⭐⭐ Medium |
| Extract dialogue | [Text Modding](TEXT_MODDING.md#dialogue-editing) | ⭐⭐⭐ Hard |
| Modify damage formula | [Advanced](ADVANCED_MODDING.md#battle-formula-modding) | ⭐⭐⭐⭐ Very Hard |
| Add custom features | [Advanced](ADVANCED_MODDING.md#custom-mechanics) | ⭐⭐⭐⭐ Very Hard |

### Example Mod Scripts

Pre-built mods in `tools/mods/`:

- **double_enemy_hp.py** - Double all enemy HP (beginner)
- **boost_spell_power.py** - Increase magic damage 50% (beginner)
- **hard_mode.py** - Comprehensive difficulty overhaul (intermediate)
- **add_elemental_weaknesses.py** - Give all enemies weaknesses (intermediate)

See [tools/mods/README.md](../../tools/mods/README.md) for usage.

## Data Structure Reference

### Enemy Data (14 bytes)

```python
{
	"id": 0,              # Enemy ID (0-82)
	"name": "Brownie",    # Name (max 25 bytes)
	"hp": 50,             # HP (0-65535)
	"attack": 10,         # Attack power (0-255)
	"defense": 5,         # Defense (0-255)
	"magic": 0,           # Magic power (0-255)
	"magic_defense": 0,   # Magic defense (0-255)
	"speed": 10,          # Speed (0-255)
	"weaknesses": 0x0000, # Element bitfield
	"resistances": 0x0000 # Element bitfield
}
```

### Spell Data (12 learnable)

```python
{
	"id": 0,              # Spell ID
	"name": "Fire",       # Name
	"power": 25,          # Base power (0-255)
	"mp_cost": 8,         # MP cost (0-99)
	"element": 0x2000,    # Element (Fire)
	"target": "enemy",    # Target type
	"effect_type": "damage" # Effect category
}
```

### Attack Data (169 attacks)

```python
{
	"id": 0,              # Attack ID
	"name": "Tackle",     # Name
	"power": 20,          # Base power (0-255)
	"element": 0x0000,    # Element bitfield
	"accuracy": 200,      # Hit rate (0-255)
	"type": "physical",   # Attack type
	"target": "single"    # Target selection
}
```

## Tools and Utilities

### Data Extraction

```powershell
# Extract enemy data
python tools/extract_enemies.py

# Extract attack data
python tools/extract_attacks.py

# Extract spell data
python tools/extract_spells.py

# Extract text data
python tools/extraction/extract_text.py roms/ffmq.sfc data/extracted/text
```

### Visualization

```powershell
# Enemy element chart
python tools/visualize_elements.py

# Spell effectiveness matrix
python tools/visualize_spell_effectiveness.py

# Enemy-attack network
python tools/visualize_enemy_attacks.py

# Results saved to: reports/visualizations/
```

### Testing

```powershell
# Run unit tests
python tests/run_unit_tests.py

# Run integration tests
python tools/run_tests.py

# Validate ROM build
python verify-build.ps1
```

### Building

```powershell
# Build modified ROM
python build.ps1

# Quick verification
python verify-build.ps1

# Output: roms/ffmq_rebuilt.sfc
```

## Modding Workflow

```
┌─────────────────┐
│  Extract Data   │  python tools/extract_*.py
│  (JSON files)   │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Modify Data    │  Edit JSON files or run mod scripts
│  (Python/JSON)  │  python tools/mods/your_mod.py
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Build ROM      │  python build.ps1
│  (ASM→ROM)      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Test in Emu    │  SNES emulator (MESEN-S, bsnes, etc.)
│  (Play!)        │
└────────┬────────┘
         │
         ▼
    ┌────────┐
    │ Good?  │
    └───┬────┘
        │
    ┌───┴───┐
    │ Yes   │ No → git restore data/
    └───┬───┘      (revert changes)
        │
        ▼
┌─────────────────┐
│  Commit & Share │  git commit -m "My awesome mod"
│  (Version Ctrl) │  Create IPS patch for distribution
└─────────────────┘
```

## Community Resources

### Forums and Discussion

- **ROMhacking.net** - ROM hacking community
- **FFMQ Discord** - FFMQ-specific discussions
- **SNESdev** - SNES development resources

### Tools

- **Emulators**: MESEN-S (debugging), bsnes-plus, Snes9x
- **Hex Editors**: HxD (Windows), Hex Fiend (Mac), xxd (Linux)
- **Assemblers**: bass, asar (65816 assembly)
- **Patch Tools**: Lunar IPS, beat (UPS), Flips

### External Documentation

- **65816 Reference**: https://wiki.superfamicom.org/65816-reference
- **SNES Dev Manual**: Official Nintendo documentation
- **FFMQ Randomizer**: Source code with detailed formulas

## Contributing

Found a bug? Want to improve tutorials?

1. Open an issue: GitHub Issues
2. Submit a pull request
3. Share your mods in the community
4. Document your findings

## FAQ

### Q: Will modding break my game?

A: Not if you work on ROM copies. Never edit your only ROM file. Always use `git restore` to revert changes.

### Q: Can I distribute my modified ROM?

A: **No**. Only distribute patch files (.ips, .ups). Users apply patches to their own legal ROM copies.

### Q: Do I need to know programming?

A: For basic mods (JSON editing), no. For advanced mods (assembly), yes.

### Q: Can I make a randomizer?

A: Yes! Study the enemy/spell modding guides, then randomize the JSON data before building.

### Q: How do I report bugs in my mod?

A: Test thoroughly, document the issue, check assembly/data files, use debugger to trace execution.

### Q: Can mods work on real SNES hardware?

A: Yes, if properly created. Test on flash carts (Everdrive, SD2SNES) or reproduction cartridges.

## Troubleshooting

### Build fails

```powershell
# Check JSON syntax
python -c "import json; json.load(open('data/extracted/enemies/enemies.json'))"

# Verify data ranges
python tools/validate_data.py

# Clean and rebuild
Remove-Item -Recurse build/, roms/ffmq_rebuilt.sfc
python build.ps1
```

### Changes don't appear

- Did you run `python build.ps1`?
- Are you testing the right ROM? (roms/ffmq_rebuilt.sfc)
- Did the build complete successfully?
- Check build output for errors

### Game crashes

- **Data corruption**: Restore from git
- **Invalid values**: Check HP/stat ranges
- **Assembly errors**: Review assembly patches
- **Use debugger**: MESEN-S to find crash point

## Project Structure

```
ffmq-info/
├── docs/tutorials/          # ← You are here
│   ├── README.md           # This file
│   ├── MODDING_QUICKSTART.md
│   ├── ENEMY_MODDING.md
│   ├── SPELL_MODDING.md
│   ├── TEXT_MODDING.md
│   └── ADVANCED_MODDING.md
├── tools/mods/             # Example mod scripts
│   ├── double_enemy_hp.py
│   ├── boost_spell_power.py
│   ├── hard_mode.py
│   └── add_elemental_weaknesses.py
├── data/
│   ├── extracted/          # JSON game data (editable)
│   └── converted/          # ASM data (generated)
├── src/asm/                # Assembly source
└── roms/
    └── ffmq_rebuilt.sfc    # Your modded ROM
```

## Next Steps

### I'm new to modding
→ Start with **[Modding Quick Start](MODDING_QUICKSTART.md)**

### I want to balance the game
→ Read **[Enemy Modding](ENEMY_MODDING.md)** and **[Spell Modding](SPELL_MODDING.md)**

### I want to create a randomizer
→ Study all data modding guides, then randomize JSON files

### I want to add new features
→ Master data modding first, then tackle **[Advanced Modding](ADVANCED_MODDING.md)**

### I want to fix bugs
→ **[Advanced Modding](ADVANCED_MODDING.md)** → Assembly section

---

## Credits

**FFMQ** - © Square (now Square Enix)  
**Tutorial Authors** - FFMQ disassembly project contributors  
**Tools** - Community ROM hacking tools and emulators

---

**Happy modding! 🎮✨**

*Last updated: November 4, 2025*
