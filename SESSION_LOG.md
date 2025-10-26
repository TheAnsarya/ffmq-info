# FFMQ Disassembly Session Log
## Session: October 26, 2025

### CRITICAL DISCOVERY: Graphics are COMPRESSED!

**Problem Identified:**
- Extracted graphics and palettes appear as nonsense
- Root cause: Data is compressed using FFMQ-specific algorithms

**Compression Algorithms Found (from logsmall repo):**
1. **ExpandSecondHalfWithZeros** - 3bpp→4bpp graphics expansion
   - Writes 16 bytes, then next 8 bytes each followed by zero
   - Used for 3bpp graphics displayed in 4bpp mode
   - Input in $18 byte chunks
   
2. **SimpleTailWindowCompression** - Tilemap/data compression
   - LZ-style with 256-byte sliding window
   - Command+data stream format
   - Used for map tilemaps and other data

3. **ExpandNibblesMasked** - Palette compression
   - Splits bytes into nibbles, masks with 0x07
   - Used for palette indices

### Multi-Bank Attack Strategy

**Parallel Disassembly Plan:**
- Bank $00: Continue (10% done - 1,394/14,017 lines)
- Bank $01: Start battle system
- Banks $02-05: Smaller banks in parallel
- Target: Maximum progress before next week

**Progress Tracking:**
- Total code: 74,682 lines
- Current: 1,394 lines (1.9%)
- Goal: 10,000+ lines by end of session

### Tools Created

1. **convert_diztinguish.py** - Format converter (working but encoding issues)
2. **Compression decompressors** - TO CREATE

### Git Commits This Session

1. b70f3a2: Reality check - removed ROM copying
2. cc944f3: Reality check documentation
3. c695688: Bank 00 boot sequence (600 lines)
4. 6853ea8: Bank 00 continued (1,394 lines)

---

## Next Actions

1. ✅ Create compression tools
2. ✅ Fix graphics extraction
3. ✅ Continue Bank $00 disassembly
4. ✅ Start Bank $01 in parallel
5. ✅ Document everything
6. ✅ Commit regularly

---

## Implementation Notes

### SNES Architecture
- 65816 CPU (16-bit)
- LoROM mapping
- Banks $00-$0F contain code
- DMA channels for fast transfers
- VBlank for display updates

### FFMQ Specific
- Dual buffer rendering (battle/field)
- Character switching (Benjamin/Phoebe)
- Menu navigation with wrapping
- Compressed graphics in ROM

---

## Resources
- logsmall repo: https://github.com/TheAnsarya/logsmall
- Compression algorithms documented
- Debug logs with annotated SNES code

