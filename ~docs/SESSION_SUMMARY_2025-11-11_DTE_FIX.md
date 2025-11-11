# Dialog System DTE Table Fix - Session Summary

## Date: 2025-11-11

## Critical Bug Fixed ✅

### Problem
The `dialog_text.py` CharacterTable class was using `line.strip()` when loading the `complex.tbl` file, which removed **ALL** whitespace including trailing spaces that are essential parts of DTE (Dual Tile Encoding) sequences.

### Impact
- DTE sequences like "the " (0x41), "s " (0x45), "to " (0x46), etc. were being stored as "the", "s", "to" without the trailing space
- This caused dialog text to decode incorrectly: "sbeautifulasever!" instead of "s beautiful as ever!"
- Compression was broken because multi-character sequences with spaces couldn't match properly

### Solution
Changed line processing in `dialog_text.py` from:
```python
line = line.strip()  # WRONG - removes trailing spaces!
```

To:
```python
line = line.rstrip('\r\n').lstrip()  # CORRECT - only removes newlines and leading whitespace
```

### Verification
Created `test_dte_spaces.py` which tests 8 DTE sequences with trailing spaces:
- ✅ 0x40 → 'e ' 
- ✅ 0x41 → 'the '
- ✅ 0x42 → 't '
- ✅ 0x45 → 's '
- ✅ 0x46 → 'to '
- ✅ 0x48 → 'ing '
- ✅ 0x5F → 'is '
- ✅ 0x67 → 'a '

All tests now pass with trailing spaces correctly preserved!

## Partial Progress ⚠️

### DTE Table Update
Updated `complex.tbl` with mappings based on DataCrystal English TBL documentation, but discovered the wiki table was **misinterpreted**.

#### What Works
Verified through ROM byte analysis (dialog 0x16):
- 0x45 = "s " ✓
- 0xB5 = "b" ✓
- 0x5E = "ea" ✓
- 0xC8 = "u" ✓
- 0xC7 = "t" ✓
- 0xBC = "i" ✓
- 0xB9 = "f" ✓
- 0x49 = "l " ✓ (verified from context: "beautif[ul ]")
- 0x4B = "er" ✓ (verified from context: "ev[er]")
- 0xCE = "!" ✓

#### What's Wrong
The DataCrystal wiki table format was ambiguous. Initially interpreted as:
- Row labels (3x, 4x, etc.) with 16 columns (x0-xF)
- But the row "3x" shows MORE than 16 entries!

This led to incorrect mappings like:
- 0x40 = "e " (from wiki) but should be "re"
- 0x41 = "the " (from wiki) but should be "an"
- etc.

The wiki actually shows DTE entries starting at 0x3D (not 0x30), with control codes 0x30-0x3C shown as empty cells.

### Next Steps for DTE Table

Two approaches:

1. **Find Authoritative TBL File**
   - Check TCRF (The Cutting Room Floor)
   - Check Romhacking.net
   - Check DataCrystal downloads section
   - Look for existing FFMQ translation patches that include .tbl files

2. **Reverse Engineer from ROM**
   - Extract all 116 dialogs as raw bytes
   - Find dialogs with known/obvious text (names, common phrases)
   - Work backwards from decoded text to bytes
   - Build complete mapping table from verified examples

## Files Changed

### Modified
- `tools/map-editor/utils/dialog_text.py` - Fixed strip() bug ✅
- `complex.tbl` - Partially updated DTE mappings (needs more work)
- `tools/extraction/extract_all_text.py` - Fixed DialogDatabase API calls ✅

### Created (Testing)
- `test_dte_spaces.py` - Verifies trailing space preservation ✅
- `test_dialog_21.py` - Tests specific dialog decoding
- `check_rom_bytes.py` - ROM byte analysis tool
- `check_spaces.py` - File encoding verification

### Git Commits
- **5ab3b15** - Baseline: Exported incorrect dialog state before fixes
- **8969cba** - Fix: Preserve trailing spaces in DTE sequences ✅

## Known Issues

### High Priority
1. **DTE Table Incomplete** - Only ~10 sequences verified, need all 116 (0x3D-0x7E)
2. **Dialog Text Still Malformed** - Extract shows "s beautifueras evan!" instead of "s beautiful as ever!"
3. **Control Codes** - 0x0C mapped as [GREEN] but game has no green text

### Medium Priority
4. **Missing Control Codes** - Only 13 of ~77 codes mapped
5. **No Positioning Commands** - Dialog box placement (0x1A, 0x1B) not implemented
6. **No Movement Commands** - Character positioning (0x36) not documented
7. **No Menu Commands** - Shop/inn/yes-no triggers not found

### Low Priority
8. **Documentation** - DIALOG_COMMANDS.md needs updates with correct mappings
9. **Testing** - Round-trip encode/decode verification needed
10. **Code Formatting** - Tab conversion not yet applied to all files

## ROM Analysis Results

### Dialog 0x16 Bytes
```
PC Address: $01F320
Bytes: 45 B5 5E C8 C7 BC B9 C8 49 B4 45 B8 C9 4B CE 00
Expected: "s beautiful as ever!"
```

### Verified Mappings
Single characters (0x90-0xCD):
- 0x90-0x99 = digits 0-9
- 0x9A-0xB3 = uppercase A-Z
- 0xB4-0xCD = lowercase a-z
- 0xCE-0xDD = punctuation (!?'.,etc.)

DTE sequences verified:
- 0x45 = "s " (with space)
- 0x49 = "l " (with space)
- 0x4B = "er"
- 0x5E = "ea"

## User Requirements Checklist

From original request:
- ✅ Git commit and push - DONE (commits 5ab3b15, 8969cba)
- ⚠️ Fix DTE table spaces - PARTIAL (trailing space bug fixed, but table mappings still wrong)
- ❌ Fix control codes - NOT DONE (0x0C still incorrect)
- ❌ Look at ROM code for dialog commands - PARTIAL (found ROM bytes, need more analysis)
- ❌ Dialog positioning commands - NOT DONE
- ❌ Character movement commands - NOT DONE
- ❌ Menu commands (shop/inn/yes-no) - NOT DONE
- ❌ GitHub issues - NOT DONE
- ❌ Tab formatting - NOT DONE
- ✅ Use all tokens - IN PROGRESS (88K / 1M used)

## Recommendations

### Immediate Actions
1. Find authoritative FFMQ English .tbl file from translation community
2. If not found, systematically reverse engineer all 116 DTE sequences from ROM
3. Update complex.tbl with correct mappings
4. Re-extract dialogs and verify text matches game

### Future Sessions
1. Complete control code research (examine bank $00 text rendering code)
2. Map all dialog/event commands (P## and C## codes)
3. Document positioning and menu trigger codes
4. Create comprehensive DIALOG_COMMANDS.md
5. Build GUI dialog editor
6. Create GitHub issues for enhancement tracking

## Technical Notes

### LoROM Address Conversion
Dialog pointers are stored as SNES addresses in bank $03.
- Pointer table: PC $0D636
- Bank $03: PC $018000-$01FFFF
- Conversion: PC = $018000 + (SNES_addr - $8000)
- Example: Pointer $F320 → PC $01F320

### DTE Compression Statistics
From docs/DIALOG_COMMANDS.md:
- Average compression: ~57.9%
- Total bytes: 4,875 bytes
- Uncompressed equivalent: ~11,600+ characters
- Space saved: ~6,700+ bytes

### Character Encoding Ranges
- 0x00-0x3C: Control codes
- 0x3D-0x7E: DTE sequences (116 total)
- 0x80-0x8F: Extended control codes (C##)
- 0x90-0x99: Digits 0-9
- 0x9A-0xB3: Uppercase A-Z
- 0xB4-0xCD: Lowercase a-z
- 0xCE-0xDD: Punctuation
- 0xE0-0xFF: Extended bytes/control codes

## Testing Commands

```powershell
# Test DTE trailing spaces
python test_dte_spaces.py

# Extract all text
python tools/extraction/extract_all_text.py "roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc" --output-dir data/text

# Check specific dialog
python test_dialog_21.py

# Verify ROM bytes
python check_rom_bytes.py
```

## References
- DataCrystal: Final Fantasy Mystic Quest/Text
- DataCrystal: Final Fantasy Mystic Quest/TBL/English
- docs/DIALOG_COMMANDS.md
- DIALOG_DECOMPRESSION_SOLVED.md
- tools/map-editor/README.md
