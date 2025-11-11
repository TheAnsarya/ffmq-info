# FFMQ Dialog CLI - Usage Guide

## Overview
The FFMQ Dialog CLI now has working DTE (Dual Tile Encoding) decompression!

## Installation
No installation needed - just use Python 3.

## Basic Usage

### Show a Specific Dialog
```bash
python tools/map-editor/dialog_cli.py show 0x16
python tools/map-editor/dialog_cli.py show 0x59
```

**Example Output:**
```
Dialog ID:  0x0059
Pointer:    0x00E2AD
Address:    0x01E2AD
Length:     258 bytes

Text:
----------------------------------------------------------------------
ForyearsMac'sbeenstudyingaProphecy.Onhiswaybackfromdoingsomeresearch...
----------------------------------------------------------------------
```

### Search for Text
```bash
python tools/map-editor/dialog_cli.py search "prophecy" -v
python tools/map-editor/dialog_cli.py search "Crystal"
python tools/map-editor/dialog_cli.py search "Benjamin"
```

**Example Output:**
```
Found 4 results for 'prophecy'

0x0021 (score: 0.41)
  Look over there. That's the Crystal, once the heart of the World. 
  An old Prophecy says, "The vile 4 will steal the Power..."

0x0059 (score: 0.35)
  For years Mac's been studying a Prophecy. On his way back from doing 
  some research, the lake dried up and his ship ended up on a rock ledge...
```

### List All Dialogs
```bash
python tools/map-editor/dialog_cli.py list
python tools/map-editor/dialog_cli.py list -v  # Verbose - shows all text
```

## Custom ROM Path
By default, the CLI looks for:
- `roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc`
- `roms/ffmq_rebuilt.sfc`

To use a custom ROM:
```bash
python tools/map-editor/dialog_cli.py --rom "path/to/your/rom.sfc" show 0x16
```

## Features

### ✅ Working Features
- **DTE Decompression**: Multi-character sequences decoded correctly
  - "the " (0x41)
  - "prophecy" (0x71)
  - "you" (0x44)
  - ~60 DTE sequences total
- **Dialog Extraction**: All 116 dialogs extracted from ROM
- **Search**: Find dialogs by text content
- **List**: Show all dialog IDs
- **Show**: Display individual dialogs with metadata

### 🔄 Partial Features
- Control codes partially decoded (END, NEWLINE, etc.)
- Some unknown bytes still show as `<HH>`

### ❌ Not Yet Implemented
- Dialog encoding (writing back to ROM)
- Dialog editing
- Export/import to other formats
- Batch operations
- Character table optimization

## Technical Details

### DTE (Dual Tile Encoding)
- **NOT** bit-packed Huffman (previous assumption was wrong!)
- Simple byte-to-text mapping
- Each byte = single character OR multi-character sequence
- Space character = 0xFF
- Compression ratio: ~30-40% space savings

### Character Table
Location: `complex.tbl`

**Ranges:**
- `0x00-0x0D`: Control codes
- `0x3D-0x7E`: DTE multi-character sequences (62 entries)
- `0x90-0x99`: Numbers 0-9
- `0x9A-0xB3`: Uppercase A-Z
- `0xB4-0xCD`: Lowercase a-z
- `0xCE-0xDD`: Punctuation (!, ?, ', ., etc.)
- `0xFF`: Space character

### ROM Structure
- **Pointer Table**: Bank $01:D636 (SNES address)
- **Dialog Data**: Bank $03 (SNES address)
- **ROM Format**: LoROM, 512 KiB
- **Dialogs**: 116 total

## Examples

### Find All Dialogs Mentioning a Character
```bash
python tools/map-editor/dialog_cli.py search "Benjamin" -v
python tools/map-editor/dialog_cli.py search "Kaeli"
python tools/map-editor/dialog_cli.py search "Phoebe"
```

### Examine Dialog Structure
```bash
python tools/map-editor/dialog_cli.py show 0x21
# Shows: Dialog ID, Pointer, Address, Length, and full decoded text
```

### Quick Dialog Lookup
```bash
# Find dialog with specific phrase
python tools/map-editor/dialog_cli.py search "vile 4 will steal"

# Show the found dialog
python tools/map-editor/dialog_cli.py show 0x21
```

## Troubleshooting

### "ERROR: No ROM file found"
Place your ROM in one of these locations:
- `roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc`
- `roms/ffmq_rebuilt.sfc`

Or specify with `--rom` option.

### Text Appears Garbled
This should no longer happen! The DTE decoder is working correctly.

If you still see issues:
1. Check ROM version (US V1.1 recommended)
2. Verify `complex.tbl` exists
3. Check ROM isn't corrupted

### Import Errors
Make sure you're running from the repo root:
```bash
cd ffmq-info
python tools/map-editor/dialog_cli.py ...
```

## Next Steps

To implement encoding (writing dialogs back to ROM):
1. Implement greedy longest-match algorithm in `CharacterTable.encode_text()`
2. Add padding for dialogs shorter than original
3. Implement dialog relocation for longer dialogs
4. Add pointer table updating

## Files
- `tools/map-editor/dialog_cli.py` - Command-line interface
- `tools/map-editor/utils/dialog_database.py` - ROM reading/writing
- `tools/map-editor/utils/dialog_text.py` - DTE encoding/decoding
- `complex.tbl` - Character table with DTE sequences

## Credits
- **Character tables**: DataCrystal TCRF wiki
- **DTE research**: TheAnsarya/GameInfo GitHub repo
- **FFMQ ROM hacking community**: For documentation and tools

## See Also
- `DIALOG_DECOMPRESSION_SOLVED.md` - Technical explanation
- `DIALOG_DECOMPRESSION_INVESTIGATION.md` - Original (incorrect) investigation
- DataCrystal: https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest/TBL
