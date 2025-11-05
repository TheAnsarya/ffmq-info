# Advanced Modding Tutorial

Learn advanced FFMQ modding techniques including assembly code modification, battle formula adjustments, ROM patching, and creating custom game mechanics.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Assembly Basics](#assembly-basics)
- [Battle Formula Modding](#battle-formula-modding)
- [ROM Patching](#rom-patching)
- [Custom Mechanics](#custom-mechanics)
- [Advanced Workflows](#advanced-workflows)
- [Debugging Techniques](#debugging-techniques)
- [Best Practices](#best-practices)

---

## Overview

### What is Advanced Modding?

Advanced modding goes beyond editing JSON data to modify the game's code itself:

- **Assembly code changes** - Modify game logic at the CPU instruction level
- **Battle formula adjustments** - Change damage calculations, hit rates
- **Custom mechanics** - Add new features not in the original game
- **ROM patches** - Create distributable modifications
- **Performance optimization** - Improve game speed and efficiency

### When to Use Advanced Modding

Use advanced techniques when you need to:
- Change game mechanics that aren't exposed in JSON data
- Fix bugs in the original game
- Add completely new features
- Optimize performance
- Create complex balance changes requiring formula adjustments

---

## Prerequisites

### Required Knowledge

Before attempting advanced modding, you should understand:

1. **Basic modding** - Completed [MODDING_QUICKSTART.md](MODDING_QUICKSTART.md)
2. **Programming concepts** - Variables, loops, conditions
3. **Hexadecimal** - Reading and writing hex values
4. **Binary/bitwise operations** - AND, OR, XOR, bit shifting

### Required Tools

```bash
# Assembler (for assembly modifications)
# Install bass or asar assembler
# Download: https://github.com/ARM9/bass

# Hex editor (for direct ROM editing)
# HxD (Windows) or hex fiend (Mac) or xxd (Linux)

# Debugger (for testing)
# MESEN-S, bsnes-plus, or other SNES emulators with debugging

# Python 3.9+ (for automation)
python --version
```

### SNES Architecture Basics

**CPU**: Ricoh 5A22 (65c816 variant)
- 16-bit processor with 8-bit compatibility
- 24-bit address space (16MB total)
- Variable register sizes (A: 8 or 16-bit, X/Y: 8 or 16-bit)

**ROM Mapping**: LoROM (Low ROM)
- Bank $00-$7F: ROM and RAM
- Bank $80-$FF: ROM mirror
- ROM size: 2MB (FFMQ)

**Memory Regions**:
```
$0000-$1FFF:  RAM (8KB)
$2000-$5FFF:  I/O and expansion
$6000-$7FFF:  More RAM
$8000-$FFFF:  ROM (per bank)
```

---

## Assembly Basics

### 65816 Instruction Set Overview

#### Common Instructions

```asm
; Data movement
LDA #$42        ; Load A with immediate value $42
STA $1000       ; Store A to address $1000
LDX $2000       ; Load X from address $2000
STX $3000       ; Store X to address $3000

; Arithmetic
ADC #$10        ; Add $10 to A (with carry)
SBC #$05        ; Subtract $05 from A (with carry)
INC $1000       ; Increment value at $1000
DEC $2000       ; Decrement value at $2000

; Comparison
CMP #$42        ; Compare A with $42 (sets flags)
CPX #$10        ; Compare X with $10
CPY #$20        ; Compare Y with $20

; Branching
BEQ label       ; Branch if equal (zero flag set)
BNE label       ; Branch if not equal
BCS label       ; Branch if carry set
BCC label       ; Branch if carry clear
BMI label       ; Branch if minus (negative)
BPL label       ; Branch if plus (positive)

; Bitwise operations
AND #$0F        ; Bitwise AND with $0F
ORA #$80        ; Bitwise OR with $80
EOR #$FF        ; Bitwise XOR with $FF
ASL A           ; Shift A left (multiply by 2)
LSR A           ; Shift A right (divide by 2)

; Control
JSR $8000       ; Jump to subroutine at $8000
RTS             ; Return from subroutine
RTL             ; Return from long subroutine
NOP             ; No operation (do nothing)
```

#### Register Size Control

```asm
SEP #$20        ; Set Processor Status: Set 8-bit mode for A
REP #$20        ; Reset Processor Status: Set 16-bit mode for A
SEP #$10        ; Set 8-bit mode for X,Y
REP #$10        ; Set 16-bit mode for X,Y
```

**Important**: Always track register sizes! Incorrect sizes cause bugs.

### FFMQ ROM Structure

```
ROM Address Range    | Contents
---------------------|--------------------
$00:8000-$00:FFFF    | Boot/Init code
$01:8000-$01:FFFF    | Battle system
$02:8000-$02:FFFF    | Battle data (enemies, attacks)
$03:8000-$03:FFFF    | Event scripts, dialogue
$07:8000-$07:FFFF    | Graphics data
$0B:8000-$0B:FFFF    | Battle calculations
$0D:8000-$0D:FFFF    | Menu system
```

### Reading Assembly Code

Example from FFMQ battle system:

```asm
; Calculate physical damage
; Input: A = Attacker index, X = Defender index
; Output: Y = Damage value

CalculatePhysicalDamage:
	SEP #$20            ; 8-bit A
	STA $00             ; Store attacker index
	STX $01             ; Store defender index
	
	; Get attacker's attack stat
	LDX $00             ; X = attacker index
	LDA.L CharAttack,X  ; Load attack stat from table
	STA $10             ; Store in scratch RAM
	
	; Get defender's defense stat  
	LDX $01             ; X = defender index
	LDA.L EnemyDef,X    ; Load defense stat
	STA $11             ; Store in scratch RAM
	
	; Calculate base damage = Attack - Defense
	LDA $10             ; A = Attack
	SEC                 ; Set carry for subtraction
	SBC $11             ; A = Attack - Defense
	BMI .MinDamage      ; If negative, use minimum
	
	ASL A               ; Multiply by 2
	STA $12             ; Store base damage
	
	; Add random variance (224-255 range = 88-100%)
	JSR GetRandom       ; Get random number in A
	AND #$1F            ; Mask to 0-31
	CLC                 ; Clear carry
	ADC #224            ; Add 224 (range: 224-255)
	STA $13             ; Store variance multiplier
	
	; Final damage = Base × Variance / 256
	LDA $12             ; A = base damage
	STA $4202           ; Hardware multiply operand 1
	LDA $13             ; A = variance
	STA $4203           ; Hardware multiply operand 2
	NOP                 ; Wait for multiply (2 cycles)
	NOP
	LDA $4217           ; Read result high byte
	STA $02             ; Store final damage
	
	RTS

.MinDamage:
	LDA #$01            ; Minimum 1 damage
	STA $02
	RTS
```

**Key observations**:
- Uses scratch RAM ($00-$13) for temporary values
- Hardware multiplier registers ($4202-$4203, $4217)
- Structured with labels (CalculatePhysicalDamage, .MinDamage)
- Comments explain each step

---

## Battle Formula Modding

### Understanding Damage Formulas

FFMQ's damage calculation (simplified):

```
Physical Damage = ((Attack - Defense) × 2) × Variance
Where Variance = Random(224-255) / 256 ≈ 88-100%

Magic Damage = (Spell Power + Magic Stat) × Variance
Where Variance = Random(240-255) / 256 ≈ 94-100%

Critical Hit = Damage × 2
```

### Example 1: Increase Damage Variance

Make damage more random (50%-150% instead of 88%-100%):

**Original code** (Bank $0B, approximate location):
```asm
; Random variance 224-255
JSR GetRandom
AND #$1F           ; 0-31
ADC #224           ; 224-255
```

**Modified code** (wider variance):
```asm
; Random variance 128-255
JSR GetRandom      ; 0-255
LSR A              ; Divide by 2 = 0-127
ADC #128           ; 128-255
```

**Creating the patch**:

1. Find the code location using a debugger or disassembly
2. Note the ROM address (e.g., $0B:A234 → PC $058234)
3. Create patch file:

```asm
; damage_variance.asm
; Increases damage variance range

pushpc
org $058234        ; PC address of variance code

; New variance calculation
JSR GetRandom      ; Get random 0-255
LSR A              ; Divide by 2 (0-127)
ADC #$80           ; Add 128 (128-255)
; (Next instruction continues normally)

pullpc
```

4. Apply patch to build:

```asm
; In ffmq_working.asm, add:
pushpc
incsrc "patches/damage_variance.asm"
pullpc
```

### Example 2: Modify Critical Hit Rate

Change critical hit from 5% to 10%:

**Original code**:
```asm
JSR GetRandom      ; A = 0-255
CMP #$0D           ; Compare with 13 (13/256 ≈ 5%)
BCS .NoCritical    ; Branch if >= 13 (no critical)
```

**Modified code**:
```asm
JSR GetRandom      ; A = 0-255
CMP #$1A           ; Compare with 26 (26/256 ≈ 10%)
BCS .NoCritical    ; Branch if >= 26 (no critical)
```

**Patch file** (`critical_rate.asm`):
```asm
; critical_rate.asm
; Doubles critical hit rate (5% → 10%)

pushpc
org $058345        ; PC address of critical check

CMP #$1A           ; New threshold: 26/256 ≈ 10%

pullpc
```

### Example 3: Add Defense Penetration

Make high attack ignore some defense:

**New formula**: `Effective Defense = Defense - (Attack / 4)`

```asm
; defense_penetration.asm
; High attack reduces enemy defense effectiveness

pushpc
org $058200        ; Find suitable location

; Original: A = Attack, $11 = Defense
; New: Reduce defense by Attack/4

CalculateEffectiveDefense:
	PHA                ; Save attack value
	LSR A              ; Attack / 2
	LSR A              ; Attack / 4
	STA $12            ; Store penetration
	
	LDA $11            ; Load defense
	SEC
	SBC $12            ; Defense - penetration
	BCS .PositiveDefense
	LDA #$00           ; Min defense = 0
.PositiveDefense:
	STA $11            ; Store effective defense
	
	PLA                ; Restore attack value
	; Continue with normal calculation

pullpc
```

### Example 4: Elemental Damage Multiplier

Modify elemental weakness multiplier (2x → 3x):

**Original**:
```asm
; If weakness, double damage
LDA $02            ; Load damage
ASL A              ; Multiply by 2
STA $02            ; Store doubled damage
```

**Modified**:
```asm
; If weakness, triple damage
LDA $02            ; Load damage
STA $10            ; Save original
ASL A              ; × 2
CLC
ADC $10            ; + original = × 3
STA $02            ; Store tripled damage
```

---

## ROM Patching

### Creating IPS Patches

IPS (International Patching System) patches are the standard for ROM modifications.

#### Manual IPS Creation

1. **Make a backup**: Copy original ROM to `ffmq_original.sfc`
2. **Modify ROM**: Apply your changes to `ffmq_modified.sfc`
3. **Create patch**:

```powershell
# Using Lunar IPS or similar tool
# Select original ROM
# Select modified ROM
# Save patch as "my_mod.ips"
```

#### Automated Patch Creation

```python
#!/usr/bin/env python3
"""Create IPS patch from original and modified ROM"""

def create_ips_patch(original_rom: str, modified_rom: str, output_ips: str):
	"""Generate IPS patch file"""
	
	# Read ROMs
	with open(original_rom, 'rb') as f:
		original = bytearray(f.read())
	
	with open(modified_rom, 'rb') as f:
		modified = bytearray(f.read())
	
	# Find differences
	changes = []
	i = 0
	while i < len(original):
		if original[i] != modified[i]:
			# Found difference
			start = i
			while i < len(original) and original[i] != modified[i]:
				i += 1
			changes.append((start, modified[start:i]))
		else:
			i += 1
	
	# Write IPS file
	with open(output_ips, 'wb') as f:
		# IPS header
		f.write(b'PATCH')
		
		# Write changes
		for offset, data in changes:
			# Offset (3 bytes, big-endian)
			f.write(offset.to_bytes(3, 'big'))
			# Size (2 bytes, big-endian)
			f.write(len(data).to_bytes(2, 'big'))
			# Data
			f.write(data)
		
		# EOF marker
		f.write(b'EOF')
	
	print(f"✅ Created IPS patch: {output_ips}")
	print(f"   Changes: {len(changes)} sections")
	print(f"   Total bytes modified: {sum(len(d) for _, d in changes)}")

# Usage
if __name__ == "__main__":
	create_ips_patch(
		'roms/ffmq_original.sfc',
		'roms/ffmq_rebuilt.sfc',
		'patches/my_mod.ips'
	)
```

### Applying IPS Patches

```python
#!/usr/bin/env python3
"""Apply IPS patch to ROM"""

def apply_ips_patch(rom_file: str, ips_file: str, output_file: str):
	"""Apply IPS patch to ROM file"""
	
	# Read ROM
	with open(rom_file, 'rb') as f:
		rom = bytearray(f.read())
	
	# Read IPS
	with open(ips_file, 'rb') as f:
		ips = f.read()
	
	# Verify header
	if ips[:5] != b'PATCH':
		raise ValueError("Invalid IPS file")
	
	# Apply patches
	i = 5
	while i < len(ips):
		# Check for EOF
		if ips[i:i+3] == b'EOF':
			break
		
		# Read offset (3 bytes, big-endian)
		offset = int.from_bytes(ips[i:i+3], 'big')
		i += 3
		
		# Read size (2 bytes, big-endian)
		size = int.from_bytes(ips[i:i+2], 'big')
		i += 2
		
		if size == 0:
			# RLE encoding
			rle_size = int.from_bytes(ips[i:i+2], 'big')
			i += 2
			rle_byte = ips[i]
			i += 1
			rom[offset:offset+rle_size] = [rle_byte] * rle_size
		else:
			# Normal patch
			rom[offset:offset+size] = ips[i:i+size]
			i += size
	
	# Write patched ROM
	with open(output_file, 'wb') as f:
		f.write(rom)
	
	print(f"✅ Applied patch: {ips_file}")
	print(f"   Output: {output_file}")

# Usage
if __name__ == "__main__":
	apply_ips_patch(
		'roms/ffmq.sfc',
		'patches/my_mod.ips',
		'roms/ffmq_patched.sfc'
	)
```

### UPS Patches (Modern Alternative)

UPS patches are more robust than IPS:

- Checksum verification
- Bidirectional patching
- Better error detection

```python
# UPS creation (simplified)
def create_ups_patch(original: str, modified: str, output: str):
	"""Create UPS patch (simplified implementation)"""
	# UPS format is more complex than IPS
	# Recommend using existing tools:
	# - beat (https://github.com/higan-emu/beat)
	# - ups-utils
	import subprocess
	subprocess.run([
		'beat',
		'-create',
		'-source', original,
		'-target', modified,
		'-output', output
	])
```

---

## Custom Mechanics

### Example 1: Auto-Dash Feature

Add ability to dash without holding Y button.

**Concept**: Modify movement speed check to always use dash speed.

```asm
; auto_dash.asm
; Makes character always run at dash speed

pushpc
org $01A234        ; Movement speed routine

; Original code checked Y button
; LDA $4218         ; Read controller 1
; AND #$4000        ; Test Y button
; BEQ .NormalSpeed  ; If not pressed, use normal speed

; New code: Always use dash speed
LDA #$4000         ; Pretend Y is always pressed
NOP                ; Pad to same size
NOP
; (continues normally)

pullpc
```

### Example 2: Increased EXP/Gold

Double EXP and Gold rewards:

```asm
; double_rewards.asm
; Doubles EXP and Gold from battles

pushpc
org $0B9000        ; Battle reward calculation

; After loading EXP value
DoubleEXP:
	ASL A              ; Multiply by 2
	BCC .NoOverflow    ; Check if overflow
	LDA #$FFFF         ; Cap at max
.NoOverflow:
	; Continue normally

pullpc

pushpc
org $0B9050        ; Gold calculation

; After loading Gold value
DoubleGold:
	ASL A              ; Multiply by 2
	BCC .NoOverflow    ; Check if overflow
	LDA #$FFFF         ; Cap at max
.NoOverflow:
	; Continue normally

pullpc
```

### Example 3: Save Anywhere

Allow saving outside of inn/save points:

```asm
; save_anywhere.asm
; Removes save point restriction

pushpc
org $01C500        ; Menu access check

; Original: Check if at save point
; LDA $1234         ; Load location flags
; AND #$80          ; Test save point flag
; BEQ .NoSave       ; Can't save here

; New: Always allow save
LDA #$80           ; Pretend we're at save point
NOP                ; Pad
NOP
; (continues normally)

pullpc
```

### Example 4: Fast Battle Text

Speed up battle messages:

```asm
; fast_battle_text.asm
; Increases text display speed in battles

pushpc
org $08A100        ; Text delay routine

; Original: Wait N frames between characters
; LDA #$04          ; 4 frame delay
; STA $xx           ; Store delay

; New: Faster text
LDA #$01           ; 1 frame delay
STA $xx            ; Store delay

pullpc
```

---

## Advanced Workflows

### Disassembly-Based Modding

For complex mods, work with full disassembly:

1. **Disassemble ROM**:
```bash
# Using asar or bass
asar --disassemble ffmq.sfc > ffmq_disasm.asm
```

2. **Make changes** in assembly source

3. **Reassemble**:
```bash
asar ffmq_modified.asm ffmq_rebuilt.sfc
```

4. **Test** in emulator

### Automated Testing

```python
#!/usr/bin/env python3
"""Automated ROM testing"""

import subprocess
import hashlib

def verify_rom_build():
	"""Verify ROM assembles correctly"""
	
	# Build ROM
	result = subprocess.run(
		['make', 'build'],
		capture_output=True,
		text=True
	)
	
	if result.returncode != 0:
		print("❌ Build failed:")
		print(result.stderr)
		return False
	
	# Check ROM size
	rom_size = os.path.getsize('roms/ffmq_rebuilt.sfc')
	if rom_size != 2097152:  # 2MB
		print(f"❌ Wrong ROM size: {rom_size} bytes")
		return False
	
	# Verify checksum
	with open('roms/ffmq_rebuilt.sfc', 'rb') as f:
		rom_data = f.read()
	
	# SNES header checksum at $7FDC-$7FDF
	header_sum = int.from_bytes(rom_data[0x7FDE:0x7FE0], 'little')
	actual_sum = sum(rom_data) & 0xFFFF
	
	if header_sum != actual_sum:
		print(f"❌ Checksum mismatch: {header_sum:04X} != {actual_sum:04X}")
		return False
	
	print("✅ ROM build verified!")
	return True

if __name__ == "__main__":
	verify_rom_build()
```

### Version Control Best Practices

```bash
# Create feature branch
git checkout -b feature/double-damage

# Make changes
# Edit assembly files or patches

# Test thoroughly
make build
make test

# Commit with descriptive message
git add src/asm/
git commit -m "feat: Double physical damage multiplier

- Modified damage calculation in bank $0B
- Changed multiplier from 2x to 4x
- Adjusted variance range for balance
- Updated battle formula documentation"

# Create patch file for distribution
python tools/create_patch.py --ips

# Merge when ready
git checkout master
git merge feature/double-damage
```

---

## Debugging Techniques

### Using MESEN-S Debugger

1. **Set breakpoints**:
   - Battle damage calculation: `$0B:A000`
   - Enemy initialization: `$0B:8149`
   - Experience award: `$0B:9000`

2. **Watch memory**:
   - Current HP: `$1910-$1911`
   - Attack stat: `$1912`
   - Defense stat: `$1913`
   - Battle state: `$19CB`

3. **Trace execution**:
   - Enable CPU trace log
   - Filter by address range (e.g., $0B:8000-$0B:FFFF)
   - Analyze instruction flow

### Memory Watch Example

```
Address  | Size | Name             | Value
---------|------|------------------|-------
$1910    | 2    | Enemy HP         | 5000
$1912    | 1    | Enemy Attack     | 120
$1913    | 1    | Enemy Defense    | 80
$1914    | 1    | Enemy Speed      | 100
$19CB    | 1    | Battle State     | 05
$1A00    | 2    | Damage Calc      | 234
```

### Logging and Diagnostics

Add diagnostic code to ROMs:

```asm
; debug_log.asm
; Outputs debug info to unused RAM for inspection

; After damage calculation
CalculateDamage:
	; ... normal calculation ...
	
	; Debug: Store values for inspection
	LDA $10            ; Attack value
	STA $7F0000        ; Store to unused RAM
	LDA $11            ; Defense value
	STA $7F0001
	LDA $02            ; Final damage
	STA $7F0002
	
	RTS
```

Then inspect $7F0000-$7F0002 in debugger to see calculation steps.

---

## Best Practices

### Code Organization

```
patches/
├── balance/
│   ├── double_damage.asm
│   ├── critical_rate.asm
│   └── exp_multiplier.asm
├── qol/
│   ├── auto_dash.asm
│   ├── fast_text.asm
│   └── save_anywhere.asm
└── bugfixes/
    ├── overflow_fix.asm
    └── glitch_patches.asm
```

### Documentation Standards

```asm
;==============================================================================
; Patch Name: Double Damage Mod
; Author: YourName
; Date: 2025-11-04
; Version: 1.0
;==============================================================================
; Description:
;   Doubles all physical damage in battle by modifying the damage multiplier
;   from 2x to 4x in the damage calculation routine.
;
; Changes:
;   - Bank $0B, $A100: ASL A → ASL A; ASL A (double the multiply)
;
; Compatibility:
;   - Works with base FFMQ ROM (US version)
;   - May conflict with other damage formula mods
;
; Known Issues:
;   - Very high attack values may cause overflow
;   - Critical hits can deal 9999+ damage
;==============================================================================

pushpc
org $058100

; Original code:
;   ASL A              ; Multiply by 2

; Modified code:
ASL A                  ; Multiply by 2
ASL A                  ; Multiply by 4 total

pullpc
```

### Testing Checklist

Before releasing a mod:

- [ ] ROM builds without errors
- [ ] ROM boots in emulator
- [ ] Modified features work as intended
- [ ] No crashes or freezes
- [ ] No graphical glitches
- [ ] Save states work correctly
- [ ] Tested on real hardware (if possible)
- [ ] Documented all changes
- [ ] Created clean patch file
- [ ] Tested patch application
- [ ] Verified no unintended changes

### Performance Considerations

**Avoid**:
- Excessive loops in time-critical code
- Unnecessary memory copies
- Unoptimized arithmetic

**Prefer**:
- Hardware multiply/divide registers
- Lookup tables over calculations
- Optimized instruction sequences

```asm
; Slow: Multiply by 10 using addition
LDA #$00
CLC
Loop:
	ADC #$0A
	DEX
	BNE Loop

; Fast: Use hardware multiplier
LDA #$0A
STA $4202        ; Operand 1
STX $4203        ; Operand 2
NOP
NOP
LDA $4216        ; Result
```

---

## Safety and Caution

### ⚠️ Important Warnings

1. **Never edit your only ROM copy** - Always work on backups
2. **Test extensively** - Bugs in assembly can corrupt saves
3. **Version control** - Use git for all modifications
4. **Document changes** - You'll forget what you did in a month
5. **Share responsibly** - Don't distribute copyrighted ROMs

### Responsible Modding

- ✅ Create and share patch files (.ips, .ups)
- ✅ Document compatibility requirements
- ✅ Credit original game creators
- ✅ Note if mod is incomplete/experimental
- ❌ Don't distribute modified ROMs
- ❌ Don't claim original game as your work

---

## Further Reading

### Assembly Resources

- **65816 Opcodes**: https://wiki.superfamicom.org/65816-reference
- **SNES Dev Manual**: Official Nintendo development docs
- **Programming the 65816**: Western Design Center databook

### FFMQ-Specific Resources

- **FFMQ Disassembly**: `src/asm/` directory in this repo
- **Battle Mechanics**: [BATTLE_MECHANICS.md](../BATTLE_MECHANICS.md)
- **Data Structures**: [docs/DATA_STRUCTURES.md](../DATA_STRUCTURES.md)
- **FFMQ Randomizer**: Source code with extensive formula documentation

### Community

- FFMQ Discord servers
- ROMhacking.net forums
- SNESdev community

---

## Example Complete Mod

### "Difficult Mode" Mod

Comprehensive balance changes:

```asm
;==============================================================================
; FFMQ: Difficult Mode
; Version 1.0
; A complete balance overhaul making FFMQ more challenging
;==============================================================================

; 1. Increase enemy HP by 50%
pushpc
org $0B81C0        ; Enemy HP initialization

; After loading HP
LDA $1910          ; Load HP low byte
STA $4202          ; Multiply operand 1
LDA #$96           ; 150 (decimal)
STA $4203          ; Multiply operand 2
NOP
NOP
LDA $4216          ; Result low byte
STA $10
LDA $4217          ; Result high byte
STA $11

; Divide by 100 to get 1.5x
LDA #$64           ; 100
STA $4204          ; Divide operand
STZ $4205
LDA $10
STA $4206          ; Dividend low
LDA $11
STA $4207          ; Dividend high
NOP; Wait
NOP
NOP
NOP
LDA $4214          ; Result low byte
STA $1910          ; Store new HP

pullpc

; 2. Reduce healing effectiveness by 30%
pushpc
org $0BA500        ; Healing calculation

; After calculating heal amount
LDA $02            ; Heal amount
STA $4202
LDA #$46           ; 70 (decimal) = 70%
STA $4203
NOP
NOP
LDA $4217          ; Result high byte (÷ 256)
STA $02            ; Store reduced healing

pullpc

; 3. Increase enemy attack by 25%
pushpc
org $0B8200        ; Enemy attack initialization

LDA $1912          ; Load attack
STA $4202
LDA #$7D           ; 125 (decimal)
STA $4203
NOP
NOP
LDA $4217          ; Result high byte
STA $1912          ; Store increased attack

pullpc

; 4. Reduce EXP gain by 20%
pushpc
org $0B9010        ; EXP award

; After loading EXP
LDA $10            ; EXP low byte
STA $4202
LDA #$50           ; 80 (decimal)
STA $4203
NOP
NOP
LDA $4217          ; Result ÷ 256 ≈ ×0.8
STA $10

pullpc

;==============================================================================
; End of Difficult Mode patches
;==============================================================================
```

To use:
1. Add to `src/asm/ffmq_working.asm`:
   ```asm
   incsrc "patches/difficult_mode.asm"
   ```
2. Build: `python build.ps1`
3. Test: Load ROM in emulator

---

## Conclusion

Advanced modding opens up infinite possibilities for FFMQ customization. Start small, test thoroughly, and gradually build up to more complex modifications.

**Remember**:
- Learn by studying existing code
- Test every change immediately
- Document everything you do
- Share your discoveries with the community

### Related Tutorials

- [Modding Quick Start](MODDING_QUICKSTART.md) - Basic modding
- [Enemy Modding](ENEMY_MODDING.md) - Enemy stat editing
- [Spell Modding](SPELL_MODDING.md) - Magic system editing
- [Text Modding](TEXT_MODDING.md) - Dialogue and text

---

**Happy advanced modding! 🔧⚙️**
