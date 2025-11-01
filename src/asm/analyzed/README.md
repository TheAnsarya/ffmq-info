# FFMQ Disassembly Analysis - Enhanced Code Documentation

This directory contains **analyzed and enhanced** versions of the Diztinguish disassembly with meaningful labels, detailed comments, and reverse-engineered documentation.

## Purpose

While the Diztinguish disassembly in `src/asm/banks/` provides complete code coverage, it uses generic labels like `CODE_008000` and `DATA8_0981D5`. This `analyzed/` directory contains:

1. **Meaningful labels** - Human-readable function names
2. **Detailed comments** - Explanation of what code actually does  
3. **Data structure documentation** - Format specifications and field descriptions
4. **Cross-references** - Connections between related routines
5. **RAM variable mapping** - Purpose and usage of memory locations

## Files

### `boot_sequence.asm` (150+ lines)
**Original Code**: bank_00.asm $008000-$0080ff  
**Analysis**: Complete boot and initialization sequence  
**Status**: ✅ Complete

**Key Discoveries**:
- Three entry points: BootEntry ($008000), AlternateEntry ($008016), WarmBootEntry ($00803a)
- DMA fill operation to clear VRAM on boot
- Save data detection at SRAM $700000, $70038c, $700718
- Boot flags at $7e3665, $7e3667, $7e3668
- Hardware initialization sequence
- Interrupt setup and NMI enable process

**Functions Documented**:
- `BootEntry` - Main entry point after reset
- `InitializeHardware` - Disable screen and interrupts
- `ClearMemory` - Clear work RAM
- `LoadSaveGameData` - Load from SRAM
- `InitializeNewGame` - New game initialization
- `ContinueBootSequence` - Main boot flow
- `MainGameLoop` - Enter main game

### `dma_graphics.asm` (220+ lines)
**Original Code**: bank_00.asm $008247-$008500+  
**Analysis**: DMA transfer routines for graphics and VRAM  
**Status**: ✅ Complete

**Key Discoveries**:
- Three DMA patterns: VRAM fill, tile transfer, palette transfer
- Channel 5 used for most graphics DMA
- VRAM increment modes: $80 (standard), $84 (by 128)
- Source banks: $04-$07 for ROM data, $7e-$7f for RAM
- Transfer sizes: 16-byte tiles (2BPP), 32-byte tiles (4BPP)

**Functions Documented**:
- `InitializeHardware` - Force blank and disable NMI
- `DMA_TransferToVRAM_Ch5` - Generic VRAM DMA transfer
- `DMA_TransferPalette` - Palette data to CGRAM
- `DMA_TransferTileData` - Tile graphics to VRAM
- `SetupTileTransfer` - Calculate tile DMA parameters
- `ExecuteStandardTransfer` - Execute configured DMA

**RAM Variables Mapped**:
- $00d2 - DMA request flags (palette, tile, VRAM)
- $00d4 - Additional DMA flags
- $00d8 - Transfer mode flags
- $01eb-$01f8 - DMA parameter storage
- $0048, $0062, $0064 - Transfer configuration

### `battle_system.asm` (280+ lines)
**Original Code**: bank_09.asm $098000-$098600+  
**Analysis**: Battle system data structures  
**Status**: ✅ Complete

**Key Discoveries**:
- Enemy palette table: 16 bytes per enemy (8 colors RGB555)
- Enemy sprite pointers: 5 bytes per enemy (address, bank, flags)
- ~70 total enemies in the game
- Sprite flags indicate size/complexity ($01=small, $18+=boss)
- Many enemies share graphics (same pointer, different flags)
- Palettes use RGB555 format (15-bit color)

**Data Structures Documented**:
- `EnemyPalette` - 16-byte palette format
- `EnemySpritePointer` - 5-byte sprite pointer structure
- Enemy sprite graphics data (4BPP planar tiles)
- Inferred enemy state block format

**Color Format**:
- RGB555: 0BBBBBGGGGGRRRRR (15-bit)
- Common values: $0000 (black), $7fff (white), $001f (red)

### `menu_system.asm` (350+ lines) ✨ NEW
**Original Code**: bank_0C.asm $0c8000-$0c8200+  
**Analysis**: Menu system, UI, and VBlank control  
**Status**: ✅ Complete

**Key Discoveries**:
- VBlank wait routine (`WaitForVBlank` at $0c8000) - most called routine!
- Equipment display system with stat conversion
- Menu initialization sequence (MenuSystemInit)
- PPU mode switching (Mode 1 ↔ Mode 7)
- Display layer configuration (BG1, BG2, OBJ)
- Callback system for deferred rendering ($0058-$005a)
- Direct page manipulation for fast PPU access

**Functions Documented**:
- `WaitForVBlank` - VBlank synchronization (critical!)
- `DisplayEquipmentInfo` - Equipment window display
- `ConvertStatBonus` - Stat display value conversion
- `MenuSystemInit` - Complete menu system setup
- `LoadMenuContent` - Menu rendering and updates

**RAM Variables Mapped**:
- $00d8 bit 6 - VBlank occurred flag (THE synchronization flag)
- $00d2/$00d4/$00d6 - DMA and display flags
- $00e2 - Callback pending flags
- $00aa - Screen brightness
- $7e3665 - Menu initialized flag

**Display Modes**:
- Mode 1: Standard gameplay (BG1+BG2+OBJ, 4-color)
- Mode 7: Menu/status (rotation/scaling effects)

### `ram_map.asm` (280+ lines) ✨ NEW
**Original Code**: Analysis across all banks  
**Analysis**: Complete RAM variable mapping  
**Status**: ✅ Complete

**Key Discoveries**:
- Comprehensive memory layout ($0000-$7fffff)
- Critical flag byte documentation ($00d2-$00df)
- VBlank flag at $00d8 bit 6 (set by NMI, cleared by wait)
- DMA parameter storage ($01eb-$01f8)
- Save data structure (3 slots × ~900 bytes in SRAM)
- Boot flags ($7e3665, $7e3667, $7e3668)
- Flag byte usage patterns (TSB/TRB/AND)

**Memory Regions Mapped**:
- Zero Page ($0000-$00ff) - Fast access variables
- Page 1 ($0100-$01ff) - System parameters
- Low RAM ($0200-$1fff) - Game data
- Work RAM $7e ($7e0000-$7e7fff) - Main game state
- Work RAM $7f ($7f0000-$7fffff) - Buffers
- SRAM ($700000-$7fffff) - Save data

**Critical Variables Identified**:
- $00d8 - VBlank sync (most important!)
- $00d2 - DMA flags
- $00d4 - Transfer flags
- $01f4-$01f8 - DMA parameters
- $7e3665 - Save/init flag
- $700000/$70038c/$700718 - Save slots

**Confidence Levels**:
- ✅ High: VBlank flag, DMA flags, boot flags, save slots
- ⚠️ Medium: Equipment stats, menu parameters
- ❓ Low: Character block layout details

## Usage

### For ROM Hacking

1. **Find what you want to change**:
   ```
   # Want to modify boot sequence?
   Read: analyzed/boot_sequence.asm
   Edit: banks/bank_00.asm at the documented addresses
   ```

2. **Understand the original code**:
   ```
   # Diztinguish says CODE_008000
   # Analysis says BootEntry - main entry point
   # Now you know what it does!
   ```

3. **Cross-reference**:
   ```
   # Analysis shows boot calls InitializeGameState at $0d8000
   # Look at banks/bank_0D.asm at that address
   # Find related code
   ```

### For Reverse Engineering

1. Start with analyzed files to understand high-level flow
2. Use labels and comments as guide
3. Trace into bank files for detailed implementation  
4. Add your own discoveries to analyzed files

### For Building

Analyzed files are **documentation only**:
- Do NOT include them in builds
- Edit the original bank files in `src/asm/banks/`
- Use analyzed files as reference
- Keep analyzed files updated when you learn more

## Analysis Methodology

Each analyzed file was created by:

1. **Pattern Recognition**: Identifying code patterns (loops, tables, handlers)
2. **Cross-Referencing**: Following JSR/JSL calls between routines
3. **Data Structure Analysis**: Examining repeating byte patterns
4. **Hardware Knowledge**: Understanding SNES registers and DMA
5. **Gameplay Testing**: Correlating code with observed game behavior
6. **Iterative Refinement**: Multiple passes to improve accuracy

## Confidence Levels

Labels and comments have varying confidence:

- ✅ **High Confidence**: Based on clear evidence (hardware registers, known patterns)
- ⚠️ **Medium Confidence**: Logical inference from context
- ❓ **Low Confidence**: Educated guess, needs verification

Example:
```asm
BootEntry:                          ; ✅ High - This is definitely the entry point
    JSR.W InitializeHardware        ; ✅ High - Writes to SNES_INIDISP
    JSL.L InitializeGameState       ; ⚠️ Medium - Seems to init state based on what it does
    LDA.L $7e3667                   ; ❓ Low - Don't know exact purpose yet
```

## Contributing Analysis

If you discover new information:

1. Verify your findings thoroughly
2. Add meaningful labels (not just renaming CODE_xxx)
3. Document WHY you think code does what it does
4. Include cross-references to related routines
5. Note confidence level of your analysis
6. Update this README with your discoveries

## Files TODO

Additional areas needing analysis:

- [ ] Text rendering engine (update existing `text_engine.asm`)
- [ ] Graphics loading (update existing `graphics_engine.asm`)
- [ ] Sound/music system
- [ ] Map/field system
- [ ] Event/script system
- [ ] Item/equipment system (partially done - equipment display)
- [ ] Magic/spell system
- [ ] AI routines
- [ ] Save/load system (partially done - SRAM structure)
- [ ] Input handling
- [ ] Sprite/OAM management
- [ ] Collision detection
- [ ] World map system

---

### 6. nmi_handler.asm (230 lines)

**Purpose:** Document the NMI (VBlank) interrupt handler - the heartbeat of the graphics system.

**Analysis:**
- **NMI Vector:** $00ffe6 → Points to $011b
- **IRQ Vector:** $00ffee → Points to $0117

- **VBlank Synchronization System:**
  - NMI fires ~60 times/second at start of VBlank
  - Sets flag at $00d8.6 to signal VBlank occurred
  - WaitForVBlank ($0c8000) clears flag and waits for NMI to set it
  - This ensures ALL graphics updates happen during safe VBlank period!

- **DMA Transfer Patterns:**
  - Main VRAM transfer: Channel 5, mode $1801
  - Source: Bank $7f + offset from $01f6-$01f8
  - Size: From $01f4-$01f5
  - Dest VRAM: Address in $01f8-$01f9
  - VMAINC = $84 (word increment)
  - Trigger: Write $20 to MDMAEN ($420b)

- **OAM (Sprite) Updates:**
  - Main OAM: 512 bytes from $0c00 → $2102
  - Extended OAM: 32 bytes from $0e00 → $2102+$100
  - Size controlled by $01f0-$01f3
  - Mode $0400 (byte to fixed address)

- **Update Flags (checked by NMI):**
  - $00d2.7: VRAM tilemap update
  - $00d2.6: Full background refresh
  - $00d2.5: Palette transfer
  - $00dd.6: Major DMA operation pending
  - $00d4.1: Tilemap reload
  - $00e2.6: Execute callback at [$0058]

- **Typical NMI Flow:**
  1. Save registers
  2. Check and execute callback if $00e2.6 set
  3. Process tilemap transfer if $00d4.1 set
  4. Execute major DMA if $00dd.6 set
  5. Update VRAM if $00d2.7 set
  6. Transfer palettes if $00d2.5 set
  7. Refresh background if $00d2.6 set
  8. **Set VBlank flag** at $00d8.6
  9. Return from interrupt

**Key Discoveries:**
- **CRITICAL:** VBlank flag at $00d8.6 is the fundamental sync point for entire graphics system
- Main game loop pattern: Update logic → Prepare data → WaitForVBlank → NMI transfers data
- All screen updates synchronized through flag system (main code sets, NMI checks/clears)
- DMA transfers happen ONLY during VBlank for glitch-free rendering
- Callback system at $0058-$005a for custom NMI operations

**Confidence:** MEDIUM-HIGH
- VBlank flag system: VERIFIED
- DMA patterns: VERIFIED  
- Flag system: VERIFIED
- Complete NMI flow: INFERRED (actual handler code at $011b needs manual trace)

---

### 7. input_handler.asm (380 lines)

**Purpose:** Document the input/controller handling system with auto-repeat and state management.

**Analysis:**
- **Hardware Reading:**
  - Reads SNES_CNTRL1L ($4218) each frame
  - 16-bit button state in standard SNES format
  - Buttons: B/Y/Select/Start/Up/Down/Left/Right/A/X/L/R

- **State Management Variables:**
  - `$0092`: Current frame button state (raw hardware)
  - `$0094`: New button presses (edge detection: 0→1 transitions)
  - `$0096`: Previous frame state (for comparison)
  - `$0090`: Injected input (for demo mode/scripted sequences)
  - `$0007`: Processed input output (after auto-repeat)
  - `$0009`: Auto-repeat timer (frames)

- **Auto-Repeat System:**
  - Initial press: Immediate response, set timer to 25 frames
  - Hold for 25 frames: First auto-repeat, reset timer to 5 frames
  - Subsequent repeats: Every 5 frames while held
  - Pattern: `Press → 25 frame delay → Repeat every 5 frames`
  - This creates comfortable menu scrolling UX!

- **Input Processing Modes:**
  - Normal mode: Standard gameplay input
  - Menu mode ($00d2.3): Special handler at CODE_0092F0
  - Dialog mode ($00db.2): Text advance handling
  - Disabled ($00d6.6): Input completely ignored

- **Input Injection:**
  - $0090 can be set by code to simulate button presses
  - OR'd with hardware input
  - Used for: Demo mode, scripted events, auto-battle
  - Cleared each frame after processing

- **Edge Detection Algorithm:**
  ```
  New_Presses = Current_State AND NOT Previous_State
  This detects 0→1 button transitions
  Example: If A was not pressed last frame but is now
          → New_Press.A = 1 (trigger action)
  ```

**Key Discoveries:**
- **Auto-repeat timing** creates the "feel" of menu navigation
  - 25 frame initial delay prevents accidental scrolling
  - 5 frame repeat rate feels responsive but controlled
- **Layered architecture**: Hardware → State → Auto-repeat → Context processing
- **Input injection** enables demo mode and scripted sequences
- **Context-aware** processing changes behavior based on game state
- Button constants: B=$8000, Y=$4000, Start=$1000, A=$0080, etc.

**Confidence:** HIGH
- Hardware registers: VERIFIED
- State variables: VERIFIED  
- Auto-repeat logic: VERIFIED
- All timings measured from code

---

## Cross-Reference Tables

### Major Routines by Bank

| Bank | Address | Name | Purpose |
|------|---------|------|---------|
| $00 | $008000 | BootEntry | Main entry point |
| $00 | $008247 | InitializeHardware | Disable screen/NMI |
| $00 | $0081f0 | ClearMemory | Clear work RAM |
| $00 | $008385 | DMA_TransferToVRAM_Ch5 | VRAM DMA channel 5 |
| $09 | $098000 | EnemyPaletteTable | Enemy color data |
| $09 | $098460 | EnemySpritePointers | Enemy graphics pointers |
| $0c | $0c8000 | WaitForVBlank | Wait for vertical blank |
| $0c | $0c8080 | MenuSystemInit | Initialize menus |
| $0d | $0d8000 | InitializeGameState | Initialize game vars |
| $0d | $0d8004 | InitializeInterrupts | Setup NMI/IRQ |

### Important RAM Variables

| Address | Size | Name | Purpose |
|---------|------|------|---------|
| $7e3665 | 1 | SaveDataFlag | Save data present flag |
| $7e3667 | 1 | BootFlag1 | Boot sequence flag 1 |
| $7e3668 | 1 | BootFlag2 | Boot sequence flag 2 |
| $00aa | 1 | ScreenBrightness | Screen brightness (0-15) |
| $00d2 | 1 | DMARequestFlags1 | DMA request flags |
| $00d4 | 1 | DMARequestFlags2 | Additional DMA flags |
| $00d6 | 1 | SystemFlags | System control flags |
| $00d8 | 1 | VBlankFlag | VBlank & timing flags |
| $00da | 2 | HardwareFlags | Hardware configuration |
| $00de | 1 | GeneralFlags1 | General purpose flags |
| $0090 | 2 | InjectedInput | Injected button state |
| $0092 | 2 | CurrentButtons | Current frame buttons |
| $0094 | 2 | NewPresses | New button presses (edge) |
| $0096 | 2 | PreviousButtons | Previous frame buttons |
| $0007 | 1 | ProcessedInput | Auto-repeat output |
| $0009 | 1 | AutoRepeatTimer | Frames until repeat |
| $0111 | 1 | GeneralFlags2 | General purpose flags |
| $0112 | 1 | SavedNMIFlags | Saved interrupt enable |

## External References

- **SNES Dev Manual**: https://snesdev.mesen.ca/
- **65816 Programming**: http://www.6502.org/tutorials/65c816opcodes.html
- **Diztinguish**: https://github.com/Dotsarecool/DiztinGUIsh
- **RGB555 Color**: https://en.wikipedia.org/wiki/List_of_monochrome_and_RGB_palettes#15-bit_RGB

---

*Analysis is ongoing. This documentation improves as we learn more about the game's code.*

**Last Updated**: 2025-10-24  
**Files Analyzed**: 8 (boot, DMA, battle, menu, RAM, NMI, input, README)  
**Functions Documented**: 30+  
**Data Structures**: 10+  
**Lines of Analysis**: 2,510+  
**Confidence**: Medium-High to High
