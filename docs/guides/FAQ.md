# FAQ - Frequently Asked Questions

## Table of Contents

- [General Questions](#general-questions)
- [Getting Started](#getting-started)
- [Modding Questions](#modding-questions)
- [Building and Development](#building-and-development)
- [Technical Questions](#technical-questions)
- [Contributing](#contributing)

---

## General Questions

### What is this project?

This is a comprehensive reverse engineering and modding project for Final Fantasy Mystic Quest (SNES). It provides:
- Complete ROM disassembly
- Data extraction tools
- Modding tutorials and tools
- Build system for creating modified ROMs
- Documentation of game mechanics

### What can I do with this project?

You can:
- **Create mods** - Modify enemy stats, spells, text, and more
- **Learn** - Study how FFMQ works internally
- **Build ROMs** - Create custom versions of the game
- **Contribute** - Help improve the disassembly and tools
- **Create randomizers** - Randomize game elements
- **Research** - Analyze game mechanics and formulas

### Is this legal?

Yes, reverse engineering for interoperability and preservation is generally legal. However:
- ✅ **Legal**: Owning the tools, disassembly, and documentation
- ✅ **Legal**: Creating patches (.ips, .ups files)
- ✅ **Legal**: Modding your own legally-obtained ROM
- ❌ **Illegal**: Distributing copyrighted ROM files
- ❌ **Illegal**: Sharing modified ROMs

**Always use your own legally-obtained ROM copy.**

### Do I need the original ROM?

Yes, you need a legal copy of the Final Fantasy Mystic Quest (US) SNES ROM to:
- Extract data
- Build modified versions
- Test mods

This project does **not** include or distribute ROM files.

---

## Getting Started

### What do I need to get started with modding?

**Minimum requirements**:
- Python 3.9 or higher
- FFMQ ROM file (legally obtained)
- SNES emulator (MESEN-S, bsnes, Snes9x)
- Text editor (VS Code recommended)

**Recommended**:
- Git (for version control)
- PowerShell 5.1+ (Windows) or bash (Linux/Mac)
- Basic Python knowledge

### Where should I start?

1. **Clone the repository**:
   ```bash
   git clone https://github.com/TheAnsarya/ffmq-info.git
   cd ffmq-info
   ```

2. **Install Python dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Read the quick start**:
   - [docs/tutorials/MODDING_QUICKSTART.md](docs/tutorials/MODDING_QUICKSTART.md)

4. **Try an example mod**:
   ```bash
   python tools/mods/double_enemy_hp.py
   python build.ps1
   ```

### I'm not a programmer. Can I still mod FFMQ?

Yes! Start with the JSON-based data modding:
- **No programming needed** - Edit JSON files with any text editor
- **Example mods provided** - Copy and modify existing scripts
- **Step-by-step tutorials** - Clear instructions with examples
- **Active community** - Ask questions and get help

See [docs/tutorials/MODDING_QUICKSTART.md](docs/tutorials/MODDING_QUICKSTART.md) for a beginner-friendly guide.

### What's the difference between extraction and modding?

- **Extraction**: Converting ROM data to editable formats (JSON, CSV)
  - Example: `python tools/extract_enemies.py`
  - Result: `data/extracted/enemies/enemies.json`

- **Modding**: Changing the extracted data
  - Example: Edit JSON to double enemy HP
  - Tools: Any text editor

- **Building**: Converting modified data back to ROM
  - Example: `python build.ps1`
  - Result: `roms/ffmq_rebuilt.sfc`

**Workflow**: Extract → Modify → Build → Test

---

## Modding Questions

### How do I change enemy HP?

**Quick method** (using example mod):
```bash
python tools/mods/double_enemy_hp.py
python build.ps1
```

**Manual method**:
1. Open `data/extracted/enemies/enemies.json`
2. Find the enemy (e.g., "Brownie")
3. Change the `hp` value
4. Save the file
5. Run `python build.ps1`
6. Test `roms/ffmq_rebuilt.sfc` in emulator

See [docs/tutorials/ENEMY_MODDING.md](docs/tutorials/ENEMY_MODDING.md) for details.

### How do I modify spell power?

1. Open `data/spells/spells.json`
2. Find the spell (e.g., "Fire")
3. Change `power` and/or `mp_cost`
4. Save and rebuild

See [docs/tutorials/SPELL_MODDING.md](docs/tutorials/SPELL_MODDING.md) for examples.

### Can I rename enemies?

Yes! Edit the `name` field in `data/extracted/enemies/enemies.json`.

**Important**: Enemy names must be 25 bytes or less (ASCII characters = 1 byte each).

See [docs/tutorials/TEXT_MODDING.md](docs/tutorials/TEXT_MODDING.md) for details.

### How do I add elemental weaknesses?

Use the element bitfield system:

```python
# Element values
Fire  = 0x2000
Water = 0x4000
Earth = 0x8000
Air   = 0x1000

# Example: Make enemy weak to Fire and Water
enemy['weaknesses'] = 0x2000 | 0x4000  # = 0x6000
```

See [docs/tutorials/ENEMY_MODDING.md](docs/tutorials/ENEMY_MODDING.md#element-system) for the complete reference.

### Can I create a randomizer?

Yes! Randomize the JSON data files before building:

```python
import json
import random

# Load enemy data
with open('data/extracted/enemies/enemies.json', 'r') as f:
    data = json.load(f)

# Randomize HP
for enemy in data['enemies']:
    enemy['hp'] = random.randint(100, 10000)

# Save
with open('data/extracted/enemies/enemies.json', 'w') as f:
    json.dump(data, f, indent=2)
```

Then `python build.ps1` to create the randomized ROM.

### How do I revert my changes?

```bash
# Revert specific file
git restore data/extracted/enemies/enemies.json

# Revert all data files
git restore data/

# Rebuild clean ROM
python build.ps1
```

### My mod makes the game crash. What do I do?

**Common causes**:
1. **Invalid values** - HP > 65535, stats > 255
2. **Missing terminator** - Text strings need null terminator
3. **Corrupted JSON** - Syntax errors in JSON files
4. **Build errors** - Check build.ps1 output

**Debug steps**:
1. Check build output for errors
2. Validate JSON syntax
3. Verify value ranges
4. Test in debugger (MESEN-S)
5. Revert and try smaller changes

---

## Building and Development

### How do I build a ROM from source?

```bash
# Windows (PowerShell)
python build.ps1

# Linux/Mac
python build.py

# Output: roms/ffmq_rebuilt.sfc
```

The build process:
1. Converts JSON data to ASM
2. Assembles ASM to binary
3. Creates final ROM file
4. Validates checksums

### The build fails. What's wrong?

**Check for**:
1. **Python version**: Requires Python 3.9+
   ```bash
   python --version
   ```

2. **Missing dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Invalid data**: Check JSON files for syntax errors
   ```bash
   python -c "import json; json.load(open('data/extracted/enemies/enemies.json'))"
   ```

4. **Missing files**: Ensure all required files exist

### How do I verify my ROM build?

```bash
# Quick verification
python verify-build.ps1

# Run unit tests
python tests/run_unit_tests.py

# Run integration tests
python tools/run_tests.py
```

### Can I build on Linux/Mac?

Yes! The project works on all platforms:

**Linux/Mac**:
```bash
# Install Python 3.9+
python3 --version

# Install dependencies
pip3 install -r requirements.txt

# Build
python3 build.py
```

Most scripts have cross-platform support. Windows-specific `.ps1` scripts have `.py` equivalents.

### What emulator should I use?

**For modding/testing**:
- **MESEN-S** - Best debugger, memory viewer, trace logging
- **bsnes-plus** - Excellent debugging features
- **Snes9x** - Fast, good compatibility

**For playing**:
- **Snes9x** - Best accuracy and speed
- **ZSNES** - Classic option (less accurate)

### How do I use the debugger?

**MESEN-S debugger**:
1. Load ROM: File → Open
2. Open debugger: Debug → Debugger
3. Set breakpoint: Click line number in code view
4. Watch memory: Debug → Memory Viewer
5. Trace execution: Debug → Trace Logger

See [docs/tutorials/ADVANCED_MODDING.md](docs/tutorials/ADVANCED_MODDING.md#debugging-techniques) for details.

---

## Technical Questions

### What is the ROM's address space?

FFMQ uses **LoROM mapping**:

```
$00:8000-$00:FFFF  Bank 00 (32KB) - Boot/System
$01:8000-$01:FFFF  Bank 01 (32KB) - Battle Engine
$02:8000-$02:FFFF  Bank 02 (32KB) - Battle Data
...
$0F:8000-$0F:FFFF  Bank 0F (32KB) - Last bank

Total ROM size: 2MB (16 banks × 32KB + header)
```

See [docs/ROM_STRUCTURE.md](docs/ROM_STRUCTURE.md) for complete mapping.

### Where is enemy data stored?

| Data Type | Bank | ROM Offset | Size |
|-----------|------|------------|------|
| Enemy Stats | $02 | $C275 | 14 bytes × 83 |
| Enemy Levels | $02 | $C17C | 3 bytes × 83 |
| Attack Data | $02 | $BC78 | 7 bytes × 169 |
| Attack Links | $02 | $BE94 | 6 bytes × 82 |

### What is the damage formula?

**Physical damage**:
```
Base = (Attack - Defense) × 2
Variance = Random(224-255) / 256  ≈ 88-100%
Damage = Base × Variance
Critical = Damage × 2 (5% chance)
```

**Magic damage**:
```
Base = Spell Power + Magic Stat
Variance = Random(240-255) / 256  ≈ 94-100%
Damage = Base × Variance
```

See [docs/BATTLE_MECHANICS.md](docs/BATTLE_MECHANICS.md) for complete formulas.

### How does the element system work?

Elements use 16-bit bitfields:

```
Bit  Value  Element
---  -----  -------
0    0x0001 Silence
1    0x0002 Blind
2    0x0004 Poison
...
12   0x1000 Air
13   0x2000 Fire
14   0x4000 Water
15   0x8000 Earth
```

**Combining elements**:
```python
weaknesses = 0x2000 | 0x4000  # Fire + Water = 0x6000
```

### Can I add new enemies/spells?

**Current limitations**:
- Fixed number of enemies (83)
- Fixed number of spells (16 effects, 12 learnable)
- Adding new entries requires assembly modification

**Workaround**: Replace existing unused entries.

**Future**: Advanced modding could expand tables (assembly work required).

### Where is dialogue stored?

**Dialogue system**:
- Pointer table: Bank $01, ROM $00D636
- String data: Bank $03, various addresses
- Encoding: Custom character table (see `simple.tbl`)
- Format: Null-terminated with control codes

**Status**: Extraction works, re-insertion in progress.

---

## Contributing

### How can I contribute?

**Ways to contribute**:
1. **Documentation** - Improve tutorials, add examples
2. **Testing** - Report bugs, test mods
3. **Tools** - Create new extraction/modding tools
4. **Disassembly** - Help document assembly code
5. **Community** - Answer questions, share mods
6. **Tutorials** - Write guides for specific mods

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### I found a bug. What should I do?

**Report bugs**:
1. Check existing issues: https://github.com/TheAnsarya/ffmq-info/issues
2. Create new issue with:
   - Clear description
   - Steps to reproduce
   - Expected vs actual behavior
   - System info (OS, Python version)
   - Error messages/logs

### How do I submit a mod?

**Share your mod**:
1. **Create a patch file** (.ips or .ups)
2. **Document your changes** (what was modified)
3. **Share on**:
   - GitHub (create a repository)
   - ROMhacking.net
   - FFMQ community forums

**Never distribute modified ROMs** - only patch files!

### What coding style should I use?

**Python**:
- Follow PEP 8
- Use type hints
- Document functions
- Use tabs for indentation (project standard)

**Assembly**:
- Lowercase mnemonics
- Descriptive labels (not CODE_XXXX)
- Comment each routine
- Use tabs for indentation

See [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Can I use this for other games?

The tools and techniques are general-purpose and can be adapted for other SNES games. However, game-specific data (addresses, formats) will differ.

The extraction framework (`tools/extraction/`) and build system could be reused with modifications.

---

## Troubleshooting

### "ModuleNotFoundError: No module named 'X'"

Install dependencies:
```bash
pip install -r requirements.txt
```

### "FileNotFoundError: roms/ffmq.sfc"

Place your FFMQ ROM in the `roms/` directory and rename it to `ffmq.sfc`.

### "JSON decode error"

Your JSON file has syntax errors. Validate it:
```bash
python -c "import json; json.load(open('your_file.json'))"
```

Or use an online JSON validator.

### Build succeeds but ROM doesn't work

1. **Check file size**: Should be 2,097,152 bytes (2MB)
2. **Verify checksum**: Run `python verify-build.ps1`
3. **Test in emulator**: Try different emulator
4. **Check for data corruption**: Revert to clean state

### Changes don't appear in game

1. **Did you rebuild?** Run `python build.ps1` after changes
2. **Testing right ROM?** Use `roms/ffmq_rebuilt.sfc`, not original
3. **Clean build?** Delete `build/` folder and rebuild
4. **Value ranges?** Check if values are within valid limits

---

## Additional Resources

### Documentation

- [Modding Quick Start](docs/tutorials/MODDING_QUICKSTART.md)
- [Enemy Modding Guide](docs/tutorials/ENEMY_MODDING.md)
- [Spell Modding Guide](docs/tutorials/SPELL_MODDING.md)
- [Text Modding Guide](docs/tutorials/TEXT_MODDING.md)
- [Advanced Modding](docs/tutorials/ADVANCED_MODDING.md)

### External Links

- **ROMhacking.net** - https://www.romhacking.net/
- **65816 Reference** - https://wiki.superfamicom.org/65816-reference
- **SNES Dev Manual** - Nintendo official documentation
- **FFMQ Randomizer** - https://github.com/adeadman/ffmqr

### Community

- GitHub Issues - Report bugs and request features
- FFMQ Discord servers - Real-time chat
- ROMhacking forums - General discussion

---

**Still have questions?** Open an issue on GitHub or ask in the community!

*Last updated: November 4, 2025*
