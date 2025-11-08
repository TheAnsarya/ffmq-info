# Complete Modding Tutorial

> **Difficulty:** Beginner to Advanced  
> **Time:** 2-4 hours for complete tutorial  
> **Requirements:** Python 3.8+, Asar, MesenS emulator

This tutorial teaches you everything you need to know to mod Final Fantasy Mystic Quest, from simple stat changes to complex code modifications.

## 📖 Tutorial Structure

**Part 1:** Basic Modding (30 min) - Enemy stats  
**Part 2:** Intermediate Modding (45 min) - Graphics and text  
**Part 3:** Advanced Modding (60 min) - Code modifications  
**Part 4:** Distribution (15 min) - Creating patches

---

## Part 1: Basic Modding - Enemy Stats (30 minutes)

### Tutorial 1.1: Double Enemy HP (10 minutes)

**Goal:** Make all enemies twice as tough

**Steps:**

1. **Open Enemy Editor:**
```bash
python tools/enemy_editor_gui.py
```

2. **Modify Brownie (Enemy #0):**
   - Current HP: 50
   - New HP: 100
   - Click "Save Enemy"

3. **Bulk Edit All Enemies:**
```python
# Create script: double_hp.py
import json

with open('assets/data/enemies.json', 'r') as f:
    data = json.load(f)

for enemy in data['enemies']:
    enemy['hp'] *= 2

with open('assets/data/enemies.json', 'w') as f:
    json.dump(data, f, indent=2)

print("All enemy HP doubled!")
```

4. **Run script:**
```bash
python double_hp.py
```

5. **Build ROM:**
```powershell
.\build.ps1
```

6. **Test:**
```bash
mesen build/ffmq-rebuilt.sfc
```

**Expected Result:** First battle against Brownie now has 100 HP instead of 50

---

### Tutorial 1.2: Create Super Boss (10 minutes)

**Goal:** Make Dark King (final boss) ridiculously overpowered

**Steps:**

1. **Open Enemy Editor**

2. **Select "Dark King" (Enemy #82)**

3. **Modify Stats:**
   - HP: 65535 (max)
   - Attack: 255 (max)
   - Defense: 255 (max)
   - Speed: 255 (max)
   - Magic: 255 (max)

4. **Set All Resistances:**
   - Check all boxes under "Immune"
   - This makes him immune to everything

5. **Save and Build:**
```powershell
.\build.ps1
```

6. **Test Final Battle**

**Expected Result:** Nearly impossible final boss!

---

### Tutorial 1.3: Custom Enemy Weaknesses (10 minutes)

**Goal:** Make specific enemies weak to specific elements

**Example: Fire-Weak Slime**

1. **Open Enemy Editor → Select "Evil Sword" (Enemy #23)**

2. **Element Weaknesses:**
   - Weak: Check "Fire", "Water"
   - Resist: Check "Earth"
   - Immune: Check "Air"

3. **Save Changes**

4. **Build and Test:**
```powershell
.\build.ps1
mesen build/ffmq-rebuilt.sfc
```

5. **In-Game Test:**
   - Use Fire spell → Extra damage ✅
   - Use Earth spell → Reduced damage ✅
   - Use Air spell → No effect ✅

**Congratulations!** You've completed basic modding!

---

## Part 2: Intermediate Modding - Graphics & Text (45 minutes)

### Tutorial 2.1: Extract and Modify Graphics (20 minutes)

**Goal:** Change enemy sprite colors

**Steps:**

1. **Extract Graphics:**
```bash
python tools/extract_graphics_v2.py roms/original.sfc
```

**Output:** `assets/graphics/` directory with PNG files

2. **Find Enemy Sprite:**
```bash
# Enemy sprites are in specific files
# Brownie is in: assets/graphics/enemy_brownie.png
```

3. **Edit in Image Editor:**
   - Open `enemy_brownie.png` in GIMP/Photoshop/Paint.NET
   - Change colors (e.g., brown → blue)
   - Save as PNG

4. **Convert Back to SNES Format:**
```bash
python tools/convert_graphics.py to-snes assets/graphics/enemy_brownie.png src/graphics/enemy_brownie.bin --format 4bpp
```

5. **Build ROM:**
```powershell
.\build.ps1
```

6. **Test:**
```bash
mesen build/ffmq-rebuilt.sfc
```

**Expected Result:** Brownie now appears in blue instead of brown!

---

### Tutorial 2.2: Edit Enemy Names (15 minutes)

**Goal:** Rename enemies with custom text

**Steps:**

1. **Find Text Data:**
```bash
# Enemy names are in: src/data/text/monster-names.asm
```

2. **Open File:**
```asm
; Monster names (original)
DATA8 "Brownie", 0
DATA8 "Mad Plant", 0
DATA8 "Goblin", 0
; ... etc
```

3. **Edit Names:**
```asm
; Modified names
DATA8 "BigBrown", 0      ; Was: Brownie
DATA8 "AngryFlower", 0   ; Was: Mad Plant
DATA8 "GreenGuy", 0      ; Was: Goblin
```

4. **Note Text Limits:**
   - Each name has character limit
   - Check original length
   - DTE encoding affects length

5. **Build and Test:**
```powershell
.\build.ps1
mesen build/ffmq-rebuilt.sfc
```

**Expected Result:** Enemies appear with new names in battle!

---

### Tutorial 2.3: Custom Palettes (10 minutes)

**Goal:** Create custom enemy color palettes

**Steps:**

1. **Extract Palettes:**
```bash
python tools/extract_palettes.py roms/original.sfc
```

**Output:** `assets/graphics/palettes/` with palette files

2. **Edit Palette:**
```python
# Palette format: 15-bit RGB555
# Create: edit_palette.py

import struct

def rgb888_to_rgb555(r, g, b):
    """Convert 24-bit RGB to 15-bit RGB555"""
    r5 = (r >> 3) & 0x1F
    g5 = (g >> 3) & 0x1F
    b5 = (b >> 3) & 0x1F
    return (b5 << 10) | (g5 << 5) | r5

# Example: Create red palette
palette = []
for i in range(16):
    if i == 0:
        # Color 0 = transparent
        palette.append(0)
    else:
        # Shades of red
        intensity = i * 17  # 0-255
        rgb555 = rgb888_to_rgb555(255, intensity, intensity)
        palette.append(rgb555)

# Write palette file
with open('assets/graphics/palettes/enemy_red.pal', 'wb') as f:
    for color in palette:
        f.write(struct.pack('<H', color))

print("Red palette created!")
```

3. **Apply Palette:**
   - Requires modifying palette loading code
   - Advanced topic (see Part 3)

---

## Part 3: Advanced Modding - Code Modifications (60 minutes)

### Tutorial 3.1: Modify Damage Formula (20 minutes)

**Goal:** Change how damage is calculated

**Find Damage Calculation Code:**

```bash
# Search in FUNCTION_REFERENCE.md
# Look for "damage" or "attack"
```

**Original Code (bank_0B.asm):**
```asm
; Original damage formula
; Damage = (Attack * 2) - Defense
CalculateDamage:
	lda	AttackerAttack
	asl	a		; *2
	sec
	sbc	DefenderDefense
	sta	DamageResult
	rts
```

**Modified: Triple Damage:**
```asm
; Modified damage formula
; Damage = (Attack * 3) - Defense
CalculateDamage:
	lda	AttackerAttack
	sta	$00		; Store original
	asl	a		; *2
	clc
	adc	$00		; +1 = *3
	sec
	sbc	DefenderDefense
	sta	DamageResult
	rts
```

**Build and Test:**
```powershell
.\build.ps1 -Verbose
mesen build/ffmq-rebuilt.sfc
```

**Expected Result:** All attacks do 1.5x more damage!

---

### Tutorial 3.2: Add New Status Effect (20 minutes)

**Goal:** Create "Haste" status (doubles ATB speed)

**Challenge:** Complex - requires multiple code changes

**Steps:**

1. **Define Status Bit:**
```asm
; In include/ffmq_constants.inc
STATUS_HASTE = $0200  ; Bit 9 (unused)
```

2. **Modify ATB Update:**
```asm
; In bank_0B.asm - UpdateATBGauge
UpdateATBGauge:
	lda	CharacterStatus
	and	#STATUS_HASTE
	beq	.normalSpeed
	; Haste: add 2 instead of 1
	lda	ATBGauge
	clc
	adc	#2
	sta	ATBGauge
	rts
.normalSpeed:
	lda	ATBGauge
	inc	a
	sta	ATBGauge
	rts
```

3. **Add Haste Spell:**
   - Requires spell data modification
   - Add to spell list
   - Set status bit

4. **Test Thoroughly**

**Note:** This is simplified; real implementation more complex

---

### Tutorial 3.3: Increase Party Size (20 minutes)

**Goal:** Allow 4 party members instead of 3

**Challenge:** VERY ADVANCED - requires extensive changes

**Required Changes:**

1. **Character Data Arrays:**
```asm
; Extend arrays from 3 to 4 elements
CharacterHP: DATA16 0, 0, 0, 0  ; Was: 3 elements
CharacterMP: DATA16 0, 0, 0, 0
; ... etc for all character arrays
```

2. **Battle Screen Layout:**
   - Adjust character sprite positions
   - Modify UI rendering code
   - Update menu system

3. **Input Handling:**
   - Support 4th character selection
   - Update cursor movement

4. **Combat Logic:**
   - Update turn order calculation
   - Modify AI target selection

**Complexity:** 4-8 hours of work minimum

**Resources:**
- See BATTLE_SYSTEM.md for architecture
- See FUNCTION_REFERENCE.md for relevant functions
- Study character handling code in Bank $0B

---

## Part 4: Distribution - Creating Patches (15 minutes)

### Tutorial 4.1: Create IPS Patch (5 minutes)

**Goal:** Create distributable patch file

**Why Patches?**
- Can't distribute modified ROM (copyright)
- CAN distribute patch file
- Users apply patch to their own ROM

**Steps:**

1. **Install Patch Tool:**
   - Download Lunar IPS: https://www.romhacking.net/utilities/240/

2. **Create Patch:**
   - Open Lunar IPS
   - Click "Create IPS Patch"
   - Original: `roms/original.sfc`
   - Modified: `build/ffmq-rebuilt.sfc`
   - Save: `your-mod.ips`

3. **Test Patch:**
   - Make copy of original ROM
   - Apply patch to copy
   - Verify modified ROM works

---

### Tutorial 4.2: Write README (5 minutes)

**Goal:** Document your mod for users

**Template:**
```markdown
# Your Mod Name

Brief description of what your mod does.

## Features
- Feature 1
- Feature 2
- Feature 3

## Installation
1. Obtain clean FFMQ ROM (US v1.1)
2. Apply patch with Lunar IPS
3. Play in SNES emulator

## Changes
### Enemies
- Brownie HP: 50 → 100
- Dark King stats: All maxed

### Graphics
- Brownie sprite recolored blue

### Code
- Damage formula: 2x → 3x multiplier

## Credits
- Original game: Square
- Tools: FFMQ Disassembly Project
- Mod by: Your Name

## Version History
### v1.0 (2025-11-07)
- Initial release
```

---

### Tutorial 4.3: Share Your Mod (5 minutes)

**Where to Share:**

1. **ROMhacking.net**
   - Submit to hacks database
   - Include screenshot
   - Write description

2. **GitHub**
   - Create repository
   - Include patch file
   - Write documentation

3. **Reddit**
   - r/romhacking
   - r/finalfantasy
   - Include video/screenshots

**Best Practices:**
- Test thoroughly before release
- Include clear installation instructions
- Credit tools and resources used
- Be receptive to feedback
- Update based on bug reports

---

## 🎓 Advanced Topics

### Disassembly Reading

**How to Find Code:**

1. **Use FUNCTION_REFERENCE.md:**
```bash
# Search for keywords
# Example: "battle", "damage", "enemy"
```

2. **Use Address Mapping:**
```bash
# Find function at specific address
# Example: $80:8234 = bank_00.asm line 150
```

3. **Follow Code Flow:**
```asm
; Start at known function
MainBattleLoop:
	jsr	UpdateATB    ; Follow this
	jsr	ProcessAI    ; And this
	jsr	HandleInput  ; And this
	; etc
```

### Debugging Techniques

**1. Use Emulator Debugger:**
- MesenS has excellent debugger
- Set breakpoints
- Watch memory
- Step through code

**2. Add Debug Code:**
```asm
; Example: Log damage values
CalculateDamage:
	; ... damage calculation ...
	lda	DamageResult
	sta	$7E0000  ; Write to unused RAM
	; View in emulator memory viewer
	rts
```

**3. Compare Behavior:**
- Test same scenario in original ROM
- Test in modified ROM
- Compare results

### Hex Editing

**When to Hex Edit:**
- Small changes (single byte)
- Quick testing
- Learning addresses

**Tools:**
- HxD (Windows)
- Hex Fiend (Mac)
- hexdump (Linux)

**Example:**
```bash
# Find enemy HP in ROM
# Brownie HP = 50 (0x32)
# Location: $0C8000 (Bank $0C offset $0000)
# Change to 100 (0x64)
```

**Caution:** Hex editing dangerous for complex changes!

---

## 🔧 Troubleshooting

### "ROM doesn't work in emulator"

**Possible causes:**
1. Wrong ROM version (need US v1.1)
2. Corrupted ROM file
3. Build errors
4. Invalid modifications

**Solutions:**
```powershell
# 1. Verify ROM CRC32
certutil -hashfile roms\original.sfc
# Expected: 2c52c792

# 2. Check build log
Get-Content logs\build-latest.log

# 3. Test with original code
.\test-roundtrip.ps1
```

### "Changes don't appear in game"

**Possible causes:**
1. Modified wrong file
2. Build didn't include changes
3. Testing wrong ROM

**Solutions:**
```powershell
# 1. Verify build timestamp
Get-ChildItem build\ffmq-rebuilt.sfc

# 2. Rebuild clean
.\build.ps1 -Clean

# 3. Check ROM you're loading
```

### "Game crashes"

**Possible causes:**
1. Invalid code changes
2. Memory overflow
3. Bad pointer/address

**Solutions:**
1. Use emulator debugger
2. Check crash address
3. Review recent code changes
4. Test incremental changes

---

## 📚 Next Steps

### Learn More

**Documentation:**
- [FUNCTION_REFERENCE.md](FUNCTION_REFERENCE.md) - All functions
- [BATTLE_SYSTEM.md](BATTLE_SYSTEM.md) - Battle mechanics
- [ROM_DATA_MAP.md](ROM_DATA_MAP.md) - ROM layout

**External Resources:**
- SNES Dev Manual
- 65816 Assembly Reference
- ROMhacking.net tutorials

### Mod Ideas

**Beginner:**
- Stat rebalance
- Enemy name changes
- Color palette swaps

**Intermediate:**
- New enemy formations
- Custom sprites
- Item stat modifications

**Advanced:**
- New spells/abilities
- Battle system changes
- Additional party members
- Custom maps

### Join Community

- GitHub: Contribute to project
- Discord: Chat with modders
- ROMhacking.net: Share mods

---

## 🎉 Congratulations!

You've completed the complete modding tutorial! You now know:

✅ How to modify enemy stats  
✅ How to edit graphics and text  
✅ How to change code  
✅ How to create and distribute patches  

**Start modding!** 🎮

---

## 📝 Quick Reference

### Common Commands

```powershell
# Build ROM
.\build.ps1

# Run tests
python tools/run_all_tests.py

# Format code
.\tools\format_asm.ps1 -Path file.asm

# Extract graphics
python tools/extract_graphics_v2.py rom.sfc

# Edit enemies
python tools/enemy_editor_gui.py
```

### Important Files

```
assets/data/enemies.json          - Enemy stats (JSON)
src/asm/bank_0B_documented.asm    - Battle code
src/data/text/monster-names.asm   - Enemy names
src/graphics/                     - Graphics data
build/ffmq-rebuilt.sfc           - Output ROM
```

### Useful Tools

- **Enemy Editor:** `enemy_editor_gui.py`
- **Graphics:** `extract_graphics_v2.py`, `convert_graphics.py`
- **Testing:** `run_all_tests.py`
- **Build:** `build.ps1`

---

*Happy modding!* 🎮

*Tutorial version 1.0 | Last updated: 2025-11-07*
