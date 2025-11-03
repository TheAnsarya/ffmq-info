# FFMQ Enemy Modding - Quick Reference Guide

## 🚀 Quick Start (3 Steps)

```bash
# 1. Edit enemies visually
enemy_editor.bat

# 2. Build your modified ROM
pwsh -File build.ps1

# 3. Test in emulator
mesen build/ffmq-rebuilt.sfc
```

That's it! Your enemy modifications are now in the game.

## 📋 Complete Workflow

### Step 1: Edit Enemy Data

**Option A: Visual Editor (Recommended)**
```bash
enemy_editor.bat          # Windows
./enemy_editor.sh         # Linux/Mac
```

Features:
- Browse all 83 enemies
- Edit stats with sliders (HP: 0-65535, others: 0-255)
- Visual element resistance/weakness checkboxes
- Search and filter enemies
- Undo/redo support (Ctrl+Z)
- Built-in verification tools

**Option B: Edit JSON Directly**
```bash
# Open in your text editor
notepad data/extracted/enemies/enemies.json

# Or use Python
python -c "import json; data=json.load(open('data/extracted/enemies/enemies.json')); data['enemies'][0]['hp']=999; json.dump(data, open('data/extracted/enemies/enemies.json','w'), indent=2)"
```

### Step 2: Convert to Assembly (Automatic if using build.ps1)

```bash
# Convert JSON changes to ASM
python tools/conversion/convert_all.py
```

Generates:
- `data/converted/enemies/enemies_stats.asm` - Enemy stats (14 bytes × 83)
- `data/converted/enemies/enemies_level.asm` - Enemy levels (3 bytes × 83)
- `data/converted/attacks/attacks_data.asm` - Attack data (7 bytes × 169)
- `data/converted/attacks/enemy_attack_links.asm` - Enemy-attack links

### Step 3: Build ROM

```bash
# Build the modified ROM
pwsh -File build.ps1
```

Output: `build/ffmq-rebuilt.sfc` (512 KB)

### Step 4: Verify (Optional but Recommended)

```bash
# Verify your changes are in the ROM
python tools/verify_build_integration.py

# Or run all tests
python tools/run_all_tests.py
```

### Step 5: Test In-Game

```bash
# Launch in your emulator
mesen build/ffmq-rebuilt.sfc

# Or use any SNES emulator:
# - Mesen2 (recommended)
# - SNES9x
# - bsnes/higan
# - RetroArch
```

## 🛠️ Advanced Operations

### Batch Modifications

```python
import json

# Load enemy data
with open('data/extracted/enemies/enemies.json', 'r') as f:
    data = json.load(f)

# Double all enemy HP
for enemy in data['enemies']:
    enemy['hp'] = min(enemy['hp'] * 2, 65535)  # Cap at max value

# Save changes
with open('data/extracted/enemies/enemies.json', 'w') as f:
    json.dump(data, f, indent=2)

print(f"Modified {len(data['enemies'])} enemies")
```

### Element-Themed Modifications

```python
import json

# Make all enemies weak to fire
FIRE_ELEMENT = 0x1000  # Bit 12

with open('data/extracted/enemies/enemies.json', 'r') as f:
    data = json.load(f)

for enemy in data['enemies']:
    enemy['weaknesses'] |= FIRE_ELEMENT

with open('data/extracted/enemies/enemies.json', 'w') as f:
    json.dump(data, f, indent=2)
```

### Difficulty Modes

```python
import json

def create_hard_mode(multiplier=1.5):
    """Increase all enemy stats by multiplier."""
    with open('data/extracted/enemies/enemies.json', 'r') as f:
        data = json.load(f)
    
    for enemy in data['enemies']:
        enemy['hp'] = min(int(enemy['hp'] * multiplier), 65535)
        enemy['attack'] = min(int(enemy['attack'] * multiplier), 255)
        enemy['defense'] = min(int(enemy['defense'] * multiplier), 255)
        enemy['magic'] = min(int(enemy['magic'] * multiplier), 255)
    
    with open('data/extracted/enemies/enemies.json', 'w') as f:
        json.dump(data, f, indent=2)
    
    print(f"Created hard mode (×{multiplier})")

create_hard_mode(1.5)  # 50% harder
```

## 🧪 Testing & Verification

### Run All Tests

```bash
# Comprehensive test suite
python tools/run_all_tests.py

# Specific test category
python tools/run_all_tests.py --category pipeline
python tools/run_all_tests.py --category gamefaqs
python tools/run_all_tests.py --category build

# Verbose output
python tools/run_all_tests.py --verbose
```

### Individual Tests

```bash
# Pipeline integrity
python tools/test_pipeline.py

# GameFAQs verification
python tools/verify_gamefaqs_data.py

# Build integration
python tools/verify_build_integration.py
```

## 📊 Enemy Stats Reference

### Stat Ranges

| Stat | Min | Max | Notes |
|------|-----|-----|-------|
| HP | 0 | 65535 | 16-bit value |
| Attack | 0 | 255 | 8-bit value |
| Defense | 0 | 255 | 8-bit value |
| Speed | 0 | 255 | 8-bit value |
| Magic | 0 | 255 | 8-bit value |
| Magic Defense | 0 | 255 | 8-bit value |
| Magic Evade | 0 | 255 | 8-bit value |
| Accuracy | 0 | 255 | 8-bit value |
| Evade | 0 | 255 | 8-bit value |
| Level | 0 | 255 | 8-bit value |

### Element Bitfield

| Bit | Element/Status | Hex Value |
|-----|----------------|-----------|
| 0 | Silence | 0x0001 |
| 1 | Blind | 0x0002 |
| 2 | Poison | 0x0004 |
| 3 | Confusion | 0x0008 |
| 4 | Sleep | 0x0010 |
| 5 | Paralysis | 0x0020 |
| 6 | Stone | 0x0040 |
| 7 | Doom | 0x0080 |
| 8 | Projectile | 0x0100 |
| 9 | Bomb | 0x0200 |
| 10 | Axe | 0x0400 |
| 11 | Zombie | 0x0800 |
| 12 | Air | 0x1000 |
| 13 | Fire | 0x2000 |
| 14 | Water | 0x4000 |
| 15 | Earth | 0x8000 |

## 🐛 Troubleshooting

### Enemy Editor Won't Launch

```bash
# Check Python environment
python --version  # Should be 3.7+

# Activate virtual environment
.venv\Scripts\activate  # Windows
source .venv/bin/activate  # Linux/Mac

# Install dependencies
pip install -r requirements.txt
```

### Build Fails

```bash
# Check asar is installed
asar --version

# Verify source files exist
dir src\asm\ffmq_working.asm  # Windows
ls src/asm/ffmq_working.asm   # Linux/Mac

# Check for errors in converted ASM
python tools/verify_build_integration.py
```

### Changes Not Appearing in ROM

```bash
# Ensure conversion ran
python tools/conversion/convert_all.py

# Rebuild ROM
pwsh -File build.ps1

# Verify integration
python tools/verify_build_integration.py
```

### Test Failures

```bash
# Run verbose tests
python tools/run_all_tests.py --verbose

# Check specific test
python tools/test_pipeline.py

# Restore original data
git checkout data/extracted/enemies/enemies.json
python tools/conversion/convert_all.py
```

## 📚 Additional Resources

### Documentation
- `README.md` - Project overview
- `ENEMY_EDITOR_GUIDE.md` - Detailed GUI editor guide
- `BATTLE_DATA_PIPELINE.md` - Technical pipeline documentation
- `BUILD_INTEGRATION_COMPLETE.md` - Build system details

### Tools
- `tools/enemy_editor_gui.py` - Visual enemy editor
- `tools/conversion/convert_all.py` - JSON to ASM converter
- `tools/test_pipeline.py` - Pipeline integrity tests
- `tools/run_all_tests.py` - Master test runner

### Community Resources
- GameFAQs Enemy Guide: https://gamefaqs.gamespot.com/snes/532476-final-fantasy-mystic-quest/faqs/23095
- SNES ROM Hacking: https://www.romhacking.net/
- FFMQ Speedrunning: https://www.speedrun.com/ffmq

## 🎯 Common Modding Goals

### Easy Mode (Half Difficulty)
```bash
python -c "import json; d=json.load(open('data/extracted/enemies/enemies.json')); [e.update({'hp': e['hp']//2, 'attack': e['attack']//2}) for e in d['enemies']]; json.dump(d, open('data/extracted/enemies/enemies.json','w'), indent=2)"
```

### Super Brownie Boss Fight
```bash
python -c "import json; d=json.load(open('data/extracted/enemies/enemies.json')); d['enemies'][0].update({'hp': 9999, 'attack': 99, 'defense': 50}); json.dump(d, open('data/extracted/enemies/enemies.json','w'), indent=2)"
```

### All Enemies Weak to Fire
```bash
python -c "import json; d=json.load(open('data/extracted/enemies/enemies.json')); [e.update({'weaknesses': e['weaknesses'] | 0x2000}) for e in d['enemies']]; json.dump(d, open('data/extracted/enemies/enemies.json','w'), indent=2)"
```

---

**Happy Modding!** 🎮

For questions or issues, check the documentation or run the test suite.
