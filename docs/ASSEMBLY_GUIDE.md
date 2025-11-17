# FFMQ Assembly Development Guide

## Table of Contents

1. [Overview](#overview)
2. [Development Environment Setup](#development-environment-setup)
3. [Project Structure](#project-structure)
4. [Assembly Fundamentals](#assembly-fundamentals)
5. [SNES Architecture Primer](#snes-architecture-primer)
6. [FFMQ Code Conventions](#ffmq-code-conventions)
7. [Modification Workflows](#modification-workflows)
8. [Testing & Debugging](#testing--debugging)
9. [Common Modifications](#common-modifications)
10. [Best Practices](#best-practices)

---

## Overview

This guide provides comprehensive instructions for modifying Final Fantasy Mystic Quest's disassembled source code. Whether you're fixing bugs, adding features, or creating rom hacks, this guide covers the essential knowledge and workflows.

### Prerequisites

- Basic understanding of assembly language
- Familiarity with hexadecimal notation
- Text editor (VS Code recommended)
- SNES emulator with debugging capabilities
- Patience and attention to detail

### What You'll Learn

- How to build the ROM from source
- SNES 65816 assembly programming
- FFMQ-specific code patterns
- Safe modification techniques
- Testing and validation procedures

---

## Development Environment Setup

### Required Tools

| Tool               | Purpose                        | Download                           |
|--------------------|--------------------------------|------------------------------------|
| **WLA-DX**         | 65816 assembler                | https://github.com/vhelin/wla-dx   |
| **GNU Make**       | Build automation               | https://www.gnu.org/software/make/ |
| **Hex Editor**     | Binary verification            | HxD, ImHex, or similar             |
| **Emulator**       | Testing (bsnes/Mesen-S)        | https://github.com/bsnes-emu/bsnes |
| **Debugger**       | Advanced debugging (Mesen-S)   | https://github.com/SourMesen/Mesen-S |
| **Text Editor**    | Source editing (VS Code)       | https://code.visualstudio.com/     |

### Windows Setup

```powershell
# Install WLA-DX assembler
# Download from: https://github.com/vhelin/wla-dx/releases
# Extract to C:\wla-dx\
# Add to PATH: C:\wla-dx\binaries\

# Verify installation
wla-65816 --version

# Install GNU Make (via Chocolatey)
choco install make

# Clone FFMQ project
git clone https://github.com/[your-repo]/ffmq-info.git
cd ffmq-info

# Build ROM
make
```

### Linux/macOS Setup

```bash
# Install WLA-DX
git clone https://github.com/vhelin/wla-dx.git
cd wla-dx
mkdir build && cd build
cmake ..
make
sudo make install

# Verify installation
wla-65816 --version

# Clone FFMQ project
git clone https://github.com/[your-repo]/ffmq-info.git
cd ffmq-info

# Build ROM
make
```

### VS Code Configuration

Recommended extensions:

```json
{
  "recommendations": [
    "13xforever.language-x86-64-assembly",
    "ms-vscode.hexeditor",
    "streetsidesoftware.code-spell-checker"
  ]
}
```

**settings.json:**
```json
{
  "files.associations": {
    "*.asm": "asm",
    "*.inc": "asm"
  },
  "editor.insertSpaces": true,
  "editor.tabSize": 4,
  "files.eol": "\n",
  "files.trimTrailingWhitespace": true
}
```

---

## Project Structure

### Directory Organization

```
ffmq-info/
├── build/                    # Build output directory
│   ├── ffmq.sfc             # Final ROM
│   └── *.o                  # Object files
├── src/                      # Source code
│   ├── asm/                 # Assembly files
│   │   ├── bank_00_documented.asm
│   │   ├── bank_01_documented.asm
│   │   └── ...              # Banks 02-0D
│   ├── include/             # Include files
│   │   ├── ffmq_ram_variables.inc
│   │   ├── hardware_registers.inc
│   │   └── macros.inc
│   └── data/                # Data files
│       ├── graphics/
│       ├── music/
│       └── text/
├── docs/                     # Documentation
│   ├── MEMORY_MAP.md
│   ├── GRAPHICS_SYSTEM.md
│   └── ...
├── tools/                    # Build scripts
│   └── update_chat_log.py
├── Makefile                  # Build configuration
└── README.md
```

### Key Files

| File                          | Purpose                                  |
|-------------------------------|------------------------------------------|
| `Makefile`                    | Build automation configuration           |
| `src/asm/ffmq_full_disassembly.asm` | Main assembly entry point      |
| `src/include/ffmq_ram_variables.inc` | RAM variable labels           |
| `src/include/hardware_registers.inc` | SNES hardware register labels |
| `src/asm/bank_XX_documented.asm` | Individual bank code           |

---

## Assembly Fundamentals

### 65816 Processor Basics

The SNES uses the Ricoh 5A22 processor (based on WDC 65816):
- **8-bit or 16-bit modes:** Switchable A/X/Y register sizes
- **24-bit addressing:** 16 MB address space (banked)
- **Variable-length instructions:** 1-4 bytes per instruction

### Register Set

| Register | Size      | Purpose                               |
|----------|-----------|---------------------------------------|
| A        | 8/16-bit  | Accumulator (primary data register)   |
| X        | 8/16-bit  | Index register X                      |
| Y        | 8/16-bit  | Index register Y                      |
| S        | 16-bit    | Stack pointer                         |
| D        | 16-bit    | Direct page base                      |
| DBR      | 8-bit     | Data bank register                    |
| PBR      | 8-bit     | Program bank register                 |
| P        | 8-bit     | Processor status flags                |

### Status Flags (P Register)

```
Bit 7: N (Negative)    - Set if result is negative (bit 7 = 1)
Bit 6: V (Overflow)    - Set on signed overflow
Bit 5: M (Memory/A)    - 0 = 16-bit A, 1 = 8-bit A
Bit 4: X (Index)       - 0 = 16-bit X/Y, 1 = 8-bit X/Y
Bit 3: D (Decimal)     - BCD mode (rarely used on SNES)
Bit 2: I (IRQ Disable) - Disable IRQ interrupts
Bit 1: Z (Zero)        - Set if result is zero
Bit 0: C (Carry)       - Set on carry/borrow
```

### Common Instructions

#### Data Movement

```assembly
; Load
lda #$42                          ; Load immediate: A = $42
ldx memory_addr                   ; Load from memory: X = [memory_addr]
ldy $0100,x                       ; Load indexed: Y = [$0100 + X]

; Store
sta $7e0000                       ; Store A to $7E0000
stx !variable_name                ; Store X to labeled variable
sty $2000,x                       ; Store Y to $2000 + X

; Transfer
tax                               ; A → X
tay                               ; A → Y
txa                               ; X → A
tya                               ; Y → A
txy                               ; X → Y
tyx                               ; Y → X
```

#### Arithmetic

```assembly
; Addition
clc                               ; Clear carry (required!)
adc #$05                          ; A = A + $05 + Carry
adc $1000                         ; A = A + [$1000] + Carry

; Subtraction
sec                               ; Set carry (required for sub!)
sbc #$03                          ; A = A - $03 - !Carry
sbc $1000                         ; A = A - [$1000] - !Carry

; Increment/Decrement
inc a                             ; A++
inc $1000                         ; [$1000]++
inx                               ; X++
iny                               ; Y++
dec a                             ; A--
dec $1000                         ; [$1000]--
dex                               ; X--
dey                               ; Y--
```

#### Logical Operations

```assembly
; AND
and #$0f                          ; A = A & $0F (mask low nibble)
and $1000                         ; A = A & [$1000]

; OR
ora #$80                          ; A = A | $80 (set bit 7)
ora $1000                         ; A = A | [$1000]

; XOR
eor #$ff                          ; A = A ^ $FF (invert bits)

; Bit test
bit #$40                          ; Test bit 6 (N/V flags set)
bit $1000                         ; Test bits in memory
```

#### Shifts

```assembly
; Shift left (multiply by 2)
asl a                             ; A = A << 1
asl $1000                         ; [$1000] = [$1000] << 1

; Shift right (divide by 2)
lsr a                             ; A = A >> 1 (logical)
lsr $1000                         ; [$1000] = [$1000] >> 1

; Rotate left (with carry)
rol a                             ; A = (A << 1) | Carry
rol $1000

; Rotate right (with carry)
ror a                             ; A = (A >> 1) | (Carry << 7)
ror $1000
```

#### Branching

```assembly
; Conditional branches (8-bit relative offset)
beq .label                        ; Branch if Equal (Z=1)
bne .label                        ; Branch if Not Equal (Z=0)
bcs .label                        ; Branch if Carry Set (C=1)
bcc .label                        ; Branch if Carry Clear (C=0)
bmi .label                        ; Branch if Minus (N=1)
bpl .label                        ; Branch if Plus (N=0)
bvs .label                        ; Branch if Overflow Set (V=1)
bvc .label                        ; Branch if Overflow Clear (V=0)
bra .label                        ; Branch Always (unconditional)

; Long jumps
jmp far_address                   ; Jump to address in current bank
jmp ($1000)                       ; Jump indirect
jml $80abcd                       ; Jump to any bank:address

; Subroutines
jsr subroutine                    ; Call subroutine (same bank)
jsl $80abcd                       ; Call subroutine (any bank)
rts                               ; Return from subroutine
rtl                               ; Return from long subroutine
```

#### Stack Operations

```assembly
; Push
pha                               ; Push A
phx                               ; Push X
phy                               ; Push Y
php                               ; Push processor status

; Pull
pla                               ; Pull A
plx                               ; Pull X
ply                               ; Pull Y
plp                               ; Pull processor status
```

### 8-bit vs 16-bit Mode

**Critical:** The M and X flags control register sizes!

```assembly
; 8-bit mode (default for FFMQ)
sep #$30                          ; Set M=1, X=1 (8-bit A/X/Y)
lda #$42                          ; A = $42 (8-bit)
ldx #$80                          ; X = $80 (8-bit)

; 16-bit mode
rep #$30                          ; Clear M=0, X=0 (16-bit A/X/Y)
lda #$1234                        ; A = $1234 (16-bit)
ldx #$8000                        ; X = $8000 (16-bit)

; Mixed mode
sep #$20                          ; Set M=1 (8-bit A)
rep #$10                          ; Clear X=0 (16-bit X/Y)
lda #$42                          ; A = $42 (8-bit)
ldx #$1234                        ; X = $1234 (16-bit)
```

**Important:** Always track mode! Forgetting mode causes bugs.

### Addressing Modes

| Mode              | Syntax           | Example                | Description                    |
|-------------------|------------------|------------------------|--------------------------------|
| Immediate         | `#value`         | `lda #$42`             | Load literal value             |
| Absolute          | `$addr`          | `lda $1000`            | Load from address              |
| Absolute Long     | `$bank:addr`     | `lda $7e0000`          | Load from bank:address         |
| Direct Page       | `$00-$FF`        | `lda $10`              | Load from $00:00XX + D         |
| Indexed X         | `$addr,x`        | `lda $1000,x`          | Load from address + X          |
| Indexed Y         | `$addr,y`        | `lda $1000,y`          | Load from address + Y          |
| Indirect          | `($addr)`        | `jmp ($1000)`          | Jump to address stored at addr |
| Indexed Indirect  | `($addr,x)`      | `lda ($10,x)`          | Load from [($10+X)]            |
| Indirect Indexed  | `($addr),y`      | `lda ($10),y`          | Load from [($10)] + Y          |
| Stack Relative    | `$offset,s`      | `lda $02,s`            | Load from stack + offset       |

---

## SNES Architecture Primer

### Memory Map

The SNES uses a complex banked memory system:

| Address Range     | Size    | Region                  | Typical Use               |
|-------------------|---------|-------------------------|---------------------------|
| $00:0000-$00:1FFF | 8 KB    | WRAM (Low RAM)          | Zero page, stack, variables|
| $00:2000-$00:5FFF | 16 KB   | Hardware registers      | PPU, APU, DMA, etc.       |
| $00:6000-$00:7FFF | 8 KB    | Expansion               | Rarely used               |
| $00:8000-$00:FFFF | 32 KB   | ROM (Bank 0)            | Boot code, vectors        |
| $01:0000-$6F:FFFF | ~7 MB   | ROM (Banks 1-111)       | Game code, data           |
| $70:0000-$7D:FFFF | 896 KB  | SRAM (save data)        | Save files                |
| $7E:0000-$7E:FFFF | 64 KB   | WRAM Bank $7E           | Main work RAM             |
| $7F:0000-$7F:FFFF | 64 KB   | WRAM Bank $7F           | Extended work RAM         |
| $80:0000-$FF:FFFF | 8 MB    | ROM mirror              | Same as $00-$7F           |

### Hardware Registers

Key SNES hardware registers used in FFMQ:

#### PPU (Graphics)

| Address | Name      | Purpose                               |
|---------|-----------|---------------------------------------|
| $2100   | INIDISP   | Screen brightness / force blank       |
| $2105   | BGMODE    | BG mode and tile size                 |
| $210D   | BG1HOFS   | BG1 horizontal scroll                 |
| $210E   | BG1VOFS   | BG1 vertical scroll                   |
| $2116   | VMADDL    | VRAM address (low)                    |
| $2117   | VMADDH    | VRAM address (high)                   |
| $2118   | VMDATAL   | VRAM data write (low)                 |
| $2119   | VMDATAH   | VRAM data write (high)                |
| $2121   | CGADD     | CGRAM (palette) address               |
| $2122   | CGDATA    | CGRAM data write                      |

#### DMA

| Address | Name      | Purpose                               |
|---------|-----------|---------------------------------------|
| $4300   | DMAP0     | DMA 0 parameters                      |
| $4301   | BBAD0     | DMA 0 destination register            |
| $4302   | A1T0L     | DMA 0 source address (low)            |
| $4303   | A1T0H     | DMA 0 source address (high)           |
| $4304   | A1B0      | DMA 0 source bank                     |
| $4305   | DAS0L     | DMA 0 size (low)                      |
| $4306   | DAS0H     | DMA 0 size (high)                     |
| $420B   | MDMAEN    | DMA enable (bits 0-7 = channels 0-7)  |
| $420C   | HDMAEN    | HDMA enable                           |

#### Controllers

| Address | Name      | Purpose                               |
|---------|-----------|---------------------------------------|
| $4016   | JOYWR     | Controller port output                |
| $4016   | JOYA      | Controller 1 data (read)              |
| $4017   | JOYB      | Controller 2 data (read)              |
| $4218   | JOY1L     | Controller 1 data (auto-read, low)    |
| $4219   | JOY1H     | Controller 1 data (auto-read, high)   |

---

## FFMQ Code Conventions

### Label Naming

FFMQ uses semantic label names organized by system:

**Variable labels:**
```assembly
!sprite_x_array    = $1a73        ; Arrays use _array suffix
!gfx_position_x    = $0a25        ; Coordinates use _x/_y/_z/_w
!battle_state_c50  = $0c50        ; State registers use _cXX suffix
!dma_dest_addr     = $0cd0        ; DMA variables use dma_ prefix
!audio_channel_assign = $0628     ; Audio variables use audio_ prefix
```

**Function labels:**
```assembly
UpdateSprites:                    ; PascalCase for functions
.loop:                            ; .local_label for local labels
.done:
    rts

CalculateDamage:
.check_critical:
.apply_multiplier:
.store_result:
    rts
```

### Code Organization

**Bank structure:**
```assembly
; Bank header
.bank 2 slot 0
.org $8000                        ; Start address

; Function 1
Function1Name:
    ; ... code ...
    rts

; Function 2
Function2Name:
    ; ... code ...
    rts

; Data tables
data_table_1:
    .db $01, $02, $03, ...

; Bank footer (if needed)
.org $FFFF
    .db $00                       ; Bank end marker
```

### Comment Style

```assembly
; High-level function description
; Inputs: A = value, X = index
; Outputs: A = result
; Modifies: A, X, flags
FunctionName:
    pha                           ; Save A
    
    ; Check if value is valid
    cmp #$80                      ; Compare with max
    bcs .invalid                  ; Branch if >= $80
    
    ; Process valid value
    asl a                         ; Multiply by 2
    tax                           ; Use as index
    lda data_table,x              ; Look up result
    
    bra .done
    
.invalid:
    lda #$00                      ; Return 0 for invalid
    
.done:
    plx                           ; Restore X
    rts
```

### Common Patterns

#### Loop Pattern

```assembly
ProcessArray:
    ldx #$00                      ; Initialize index
.loop:
    lda array_data,x              ; Load element
    jsr ProcessElement            ; Process it
    inx                           ; Next element
    cpx #array_size               ; Check end
    bcc .loop                     ; Continue if < size
    rts
```

#### 16-bit Arithmetic

```assembly
Add16BitValues:
    rep #$30                      ; 16-bit mode
    lda value1                    ; Load 16-bit value
    clc
    adc value2                    ; Add 16-bit value
    sta result                    ; Store 16-bit result
    sep #$30                      ; Back to 8-bit
    rts
```

#### Save/Restore Registers

```assembly
SafeFunction:
    pha                           ; Save A
    phx                           ; Save X
    phy                           ; Save Y
    
    ; ... do work ...
    
    ply                           ; Restore Y
    plx                           ; Restore X
    pla                           ; Restore A
    rts
```

---

## Modification Workflows

### Basic Modification Process

1. **Identify target code**
   - Use memory map to find relevant variables
   - Search disassembly for function names
   - Reference documentation for system details

2. **Make changes**
   - Edit `.asm` files in `src/asm/`
   - Update labels in `src/include/` if needed
   - Add comments explaining changes

3. **Build ROM**
   ```bash
   make clean
   make
   ```

4. **Test changes**
   - Load ROM in emulator
   - Verify behavior
   - Check for side effects

5. **Debug issues**
   - Use emulator debugger
   - Add debug output (write to unused RAM)
   - Compare with original ROM

### Example: Increase Max HP

**Goal:** Change max HP from 999 to 9999

**Step 1:** Find HP limit code
```bash
# Search for HP checks
grep -r "999" src/asm/
grep -r "#$03\|#$e7" src/asm/  # $03E7 = 999
```

**Step 2:** Locate function (example):
```assembly
; In bank_02_documented.asm
CheckMaxHP:
    rep #$30                      ; 16-bit mode
    lda current_hp
    cmp #$03e7                    ; Compare with 999
    bcc .not_max
    lda #$03e7                    ; Cap at 999
    sta current_hp
.not_max:
    sep #$30
    rts
```

**Step 3:** Modify:
```assembly
; Modified version
CheckMaxHP:
    rep #$30                      ; 16-bit mode
    lda current_hp
    cmp #$270f                    ; Compare with 9999 (changed!)
    bcc .not_max
    lda #$270f                    ; Cap at 9999 (changed!)
    sta current_hp
.not_max:
    sep #$30
    rts
```

**Step 4:** Build & test
```bash
make clean && make
# Test in emulator - level up, check HP display
```

### Example: Add New Item

**Goal:** Create custom weapon with special properties

**Step 1:** Find item data table
```assembly
; In bank_03_documented.asm
weapon_data_table:
    ; Format: ID, Attack, Type, Special
    .db $01, $0a, $00, $00        ; Sword: Attack 10
    .db $02, $14, $00, $01        ; Axe: Attack 20, Special 1
    ; ... more items
```

**Step 2:** Add new entry
```assembly
weapon_data_table:
    ; ... existing items ...
    .db $ff, $32, $00, $05        ; NEW: Super Sword, Attack 50, Special 5
```

**Step 3:** Add to item name table
```assembly
; In bank_05_documented.asm
weapon_names:
    .db "Sword", $00
    .db "Axe", $00
    ; ... more names ...
    .db "Super Sword", $00         ; NEW
```

**Step 4:** Implement special effect
```assembly
; In bank_02_documented.asm (battle damage calculation)
CalculateDamage:
    ; ... existing damage code ...
    
    ; Check weapon type
    lda equipped_weapon
    cmp #$ff                      ; Super Sword?
    bne .normal_damage
    
    ; Apply super sword bonus
    lda damage
    asl a                         ; Double damage!
    sta damage
    
.normal_damage:
    ; ... continue ...
```

---

## Testing & Debugging

### Emulator Testing

**bsnes (accuracy):**
```bash
# Load ROM
bsnes ffmq.sfc

# Features:
# - Cycle-accurate emulation
# - Save states (F5/F7)
# - Slow motion (F6)
# - Fast forward (Tab)
```

**Mesen-S (debugging):**
```bash
# Load ROM with debugger
mesen-s ffmq.sfc

# Features:
# - Full debugger (breakpoints, watches)
# - Memory viewer
# - Event viewer (PPU, CPU)
# - Trace logger
# - Lua scripting
```

### Debug Techniques

#### 1. Breakpoints

```
Mesen-S debugger:
1. Right-click code address → "Add Breakpoint"
2. Run game
3. Execution stops at breakpoint
4. Inspect registers, memory
5. Step through code (F10/F11)
```

#### 2. Memory Watches

```
Watch variables in real-time:
1. Debug → Memory Tools → Watch Window
2. Add address (e.g., $7E0A25 for !gfx_position_x)
3. Monitor value changes
```

#### 3. Debug Output

Write values to unused RAM for logging:

```assembly
; Write debug value to unused RAM $7F0000
DebugWriteValue:
    pha                           ; Save A
    lda debug_value
    sta $7f0000                   ; Write to unused RAM
    pla
    rts

; Read in debugger:
; Memory viewer → Go to $7F0000
```

#### 4. Trace Logging

```
Mesen-S trace logger:
1. Debug → Trace Logger
2. Enable tracing
3. Run game
4. Review execution log
5. Search for specific instructions
```

### Common Issues

| Issue                  | Cause                        | Solution                          |
|------------------------|------------------------------|-----------------------------------|
| Build fails            | Syntax error                 | Check error message, fix syntax   |
| ROM crashes            | Invalid instruction          | Verify opcodes, check mode flags  |
| Infinite loop          | Missing branch condition     | Add exit condition                |
| Wrong behavior         | Incorrect logic              | Add debug output, trace execution |
| Graphical glitches     | Wrong PPU register write     | Verify VRAM/OAM updates          |
| No changes visible     | Wrong bank/address           | Verify modification location      |

---

## Common Modifications

### 1. Stat Adjustments

**Increase starting stats:**
```assembly
; In character_init function
InitPlayerStats:
    lda #$64                      ; HP = 100 (was 50)
    sta player_hp_max
    sta player_hp_current
    
    lda #$32                      ; MP = 50 (was 20)
    sta player_mp_max
    sta player_mp_current
    
    lda #$14                      ; Attack = 20 (was 10)
    sta player_attack
    
    lda #$0a                      ; Defense = 10 (was 5)
    sta player_defense
    
    rts
```

### 2. Experience Multiplier

**Double EXP gain:**
```assembly
; In battle victory function
AwardExperience:
    rep #$30
    lda enemy_exp_value           ; Load EXP
    asl a                         ; × 2 (added!)
    clc
    adc player_exp                ; Add to total
    sta player_exp
    sep #$30
    rts
```

### 3. Item Price Changes

**Reduce shop prices by 50%:**
```assembly
; In shop display function
DisplayItemPrice:
    rep #$30
    lda item_base_price
    lsr a                         ; ÷ 2 (added!)
    sta displayed_price
    sep #$30
    rts
```

### 4. Enemy HP Modification

**Make enemies tougher (×1.5 HP):**
```assembly
; In enemy initialization
InitEnemyStats:
    rep #$30
    lda enemy_base_hp             ; Load base HP
    sta temp_hp
    lsr a                         ; ÷ 2
    clc
    adc temp_hp                   ; + original = ×1.5
    sta enemy_hp_current
    sta enemy_hp_max
    sep #$30
    rts
```

### 5. Infinite MP

**Make spells cost 0 MP:**
```assembly
; In spell cast function
CastSpell:
    ; ... spell effect code ...
    
    ; Deduct MP cost (comment out!)
    ; lda spell_mp_cost
    ; sta temp_cost
    ; lda player_mp_current
    ; sec
    ; sbc temp_cost
    ; sta player_mp_current
    
    ; Skip MP deduction entirely!
    
    rts
```

---

## Best Practices

### 1. Always Comment Changes

```assembly
; MODIFICATION: Increased max HP from 999 to 9999
; Author: YourName
; Date: 2024-12-XX
CheckMaxHP:
    rep #$30
    lda current_hp
    cmp #$270f                    ; Was #$03e7 (999)
    bcc .not_max
    lda #$270f                    ; Was #$03e7 (999)
    sta current_hp
.not_max:
    sep #$30
    rts
```

### 2. Preserve Registers

```assembly
; Good: Save/restore registers
SafeModification:
    pha                           ; Save A
    phx                           ; Save X
    php                           ; Save flags
    
    ; ... your code ...
    
    plp                           ; Restore flags
    plx                           ; Restore X
    pla                           ; Restore A
    rts

; Bad: Don't corrupt registers
UnsafeModification:
    ldx #$00                      ; Corrupts X!
    ; ... (caller might need X)
    rts
```

### 3. Test Thoroughly

- **Save states:** Test before and after each change
- **Edge cases:** Test minimum, maximum, boundary values
- **Side effects:** Check related systems
- **Different scenarios:** Test in various game situations

### 4. Keep Backups

```bash
# Before major changes:
cp build/ffmq.sfc build/ffmq_backup_YYYY-MM-DD.sfc
```

### 5. Use Version Control

```bash
# Commit frequently
git add src/asm/bank_02_documented.asm
git commit -m "Increase max HP to 9999"

# Create branches for experiments
git checkout -b experimental-feature
# ... make changes ...
git checkout main  # Return to stable code
```

### 6. Document Your Work

Create modification notes:

```markdown
# Modifications Log

## 2024-12-XX: Max HP Increase
- **File:** src/asm/bank_02_documented.asm
- **Function:** CheckMaxHP
- **Change:** Increased max HP from 999 to 9999
- **Impact:** Players can have higher HP at high levels
- **Testing:** Tested level 99 character, HP displays correctly
```

---

## Document Info

**Version:** 1.0  
**Last Updated:** December 2024  
**Target Audience:** Intermediate assembly programmers  
**Prerequisites:** Basic 65816 knowledge

**See Also:**
- `MEMORY_MAP.md` - Complete memory layout
- `LABEL_USAGE_GUIDE.md` - How to use labels
- WLA-DX Documentation - Assembler reference
- 65816 Reference Manual - Processor details
