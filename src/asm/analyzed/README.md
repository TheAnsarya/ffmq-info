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

### `boot_sequence.asm`
**Original Code**: bank_00.asm $008000-$0080FF  
**Analysis**: Complete boot and initialization sequence

**Key Discoveries**:
- Three entry points: BootEntry ($008000), AlternateEntry ($008016), WarmBootEntry ($00803A)
- DMA fill operation to clear VRAM on boot
- Save data detection at SRAM $700000, $70038C, $700718
- Boot flags at $7E3665, $7E3667, $7E3668
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

### `dma_graphics.asm`
**Original Code**: bank_00.asm $008247-$008500+  
**Analysis**: DMA transfer routines for graphics and VRAM

**Key Discoveries**:
- Three DMA patterns: VRAM fill, tile transfer, palette transfer
- Channel 5 used for most graphics DMA
- VRAM increment modes: $80 (standard), $84 (by 128)
- Source banks: $04-$07 for ROM data, $7E-$7F for RAM
- Transfer sizes: 16-byte tiles (2BPP), 32-byte tiles (4BPP)

**Functions Documented**:
- `InitializeHardware` - Force blank and disable NMI
- `DMA_TransferToVRAM_Ch5` - Generic VRAM DMA transfer
- `DMA_TransferPalette` - Palette data to CGRAM
- `DMA_TransferTileData` - Tile graphics to VRAM
- `SetupTileTransfer` - Calculate tile DMA parameters
- `ExecuteStandardTransfer` - Execute configured DMA

**RAM Variables Mapped**:
- $00D2 - DMA request flags (palette, tile, VRAM)
- $00D4 - Additional DMA flags
- $00D8 - Transfer mode flags
- $01EB-$01F8 - DMA parameter storage
- $0048, $0062, $0064 - Transfer configuration

### `battle_system.asm`
**Original Code**: bank_09.asm $098000-$098600+  
**Analysis**: Battle system data structures

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
- Common values: $0000 (black), $7FFF (white), $001F (red)

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
   # Analysis shows boot calls InitializeGameState at $0D8000
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
    LDA.L $7E3667                   ; ❓ Low - Don't know exact purpose yet
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

- [ ] Menu system (bank_0C, bank_0D)
- [ ] Text rendering engine (already partially in `text_engine.asm`)
- [ ] Graphics loading (already partially in `graphics_engine.asm`)
- [ ] Sound/music system
- [ ] Map/field system
- [ ] Event/script system
- [ ] Item/equipment system
- [ ] Magic/spell system
- [ ] AI routines
- [ ] Save/load system

## Cross-Reference Tables

### Major Routines by Bank

| Bank | Address | Name | Purpose |
|------|---------|------|---------|
| $00 | $008000 | BootEntry | Main entry point |
| $00 | $008247 | InitializeHardware | Disable screen/NMI |
| $00 | $0081F0 | ClearMemory | Clear work RAM |
| $00 | $008385 | DMA_TransferToVRAM_Ch5 | VRAM DMA channel 5 |
| $09 | $098000 | EnemyPaletteTable | Enemy color data |
| $09 | $098460 | EnemySpritePointers | Enemy graphics pointers |
| $0C | $0C8000 | WaitForVBlank | Wait for vertical blank |
| $0C | $0C8080 | MenuSystemInit | Initialize menus |
| $0D | $0D8000 | InitializeGameState | Initialize game vars |
| $0D | $0D8004 | InitializeInterrupts | Setup NMI/IRQ |

### Important RAM Variables

| Address | Size | Name | Purpose |
|---------|------|------|---------|
| $7E3665 | 1 | SaveDataFlag | Save data present flag |
| $7E3667 | 1 | BootFlag1 | Boot sequence flag 1 |
| $7E3668 | 1 | BootFlag2 | Boot sequence flag 2 |
| $00AA | 1 | ScreenBrightness | Screen brightness (0-15) |
| $00D2 | 1 | DMARequestFlags1 | DMA request flags |
| $00D4 | 1 | DMARequestFlags2 | Additional DMA flags |
| $00DA | 2 | HardwareFlags | Hardware configuration |
| $00DE | 1 | GeneralFlags1 | General purpose flags |
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
**Files Analyzed**: 3  
**Functions Documented**: 15+  
**Data Structures**: 4+  
**Confidence**: Medium-High
