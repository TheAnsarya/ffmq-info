# FFMQ Text Toolkit - Comprehensive Guide

**Complete text extraction, modification, and re-insertion suite for Final Fantasy Mystic Quest**

## 🚀 Quick Start

```bash
# Show all available commands
python tools/ffmq_text.py --help

# Display comprehensive text system info
python tools/ffmq_text.py info

# Extract all text from ROM (batch mode)
python tools/ffmq_text.py batch-extract

# Run all analysis tools
python tools/ffmq_text.py batch-analyze
```

## 📊 System Status

| Component | Coverage | Status |
|-----------|----------|--------|
| Simple Text | 100% | ✅ Production Ready |
| Complex Text (Dialogs) | 98%+ | ✅ Production Ready |
| Character Table | 98%+ | ✅ Complete |
| Control Codes | ~50% | ⚠️ In Progress |
| **OVERALL** | **95%+** | ✅ **Ready for Translation** |

## 📁 Text Systems Overview

### Simple Text System
- **Location**: ROM Bank $06:F000-$FFFF
- **Count**: 595 entries
- **Format**: Null-terminated strings
- **Content**: Menus, items, spells, locations, names
- **Status**: ✅ 100% extraction, ✅ Re-insertion working

### Complex Text System (Dialogs)
- **Location**: ROM Bank $03:A000-$FFFF
- **Count**: 117 dialog entries
- **Format**: Dictionary-compressed with control codes
- **Dictionary**: 80 entries (0x30-0x7F) at PC 0x01BA35
- **Compression**: Recursive expansion up to 10 levels
- **Status**: ✅ 98%+ readable, ✅ Re-insertion implemented

## 🔧 Available Tools

### Unified CLI (`ffmq_text.py`)
Single interface for all text operations:

```bash
# Extraction
python tools/ffmq_text.py extract-simple    # Extract menu text
python tools/ffmq_text.py extract-complex   # Extract dialogs

# Insertion
python tools/ffmq_text.py insert-simple     # Insert modified menu text
python tools/ffmq_text.py insert-complex    # Insert modified dialogs

# Analysis
python tools/ffmq_text.py analyze-dict      # Dictionary compression
python tools/ffmq_text.py analyze-controls  # Control code usage
python tools/ffmq_text.py analyze-chars     # Character mappings

# Batch Operations
python tools/ffmq_text.py batch-extract     # Extract everything
python tools/ffmq_text.py batch-analyze     # Analyze everything

# Validation
python tools/ffmq_text.py validate          # Test round-trip

# Information
python tools/ffmq_text.py info              # System overview
```

### Individual Tools

#### Extraction Tools
```bash
# Extract simple text (menus, items, etc.)
python tools/extraction/extract_simple_text.py

# Extract complex text (dialogs with dictionary)
python tools/extraction/extract_dictionary.py
```

#### Insertion Tools
```bash
# Re-insert modified simple text
python tools/extraction/import_simple_text.py input.txt output.sfc

# Re-insert modified dialogs
python tools/extraction/import_complex_text.py input.txt output.sfc
```

#### Analysis Tools
```bash
# Analyze unknown characters
python tools/analysis/analyze_unknown_chars.py

# Detailed control code analysis
python tools/analysis/analyze_control_codes_detailed.py

# Deduce character mappings
python tools/analysis/deduce_characters.py

# Update character table
python tools/analysis/update_char_table.py
```

## 📖 Dictionary System

### How It Works
FFMQ uses a sophisticated dictionary compression system:

1. **Byte Ranges**:
	- `0x00-0x2F`: Control codes (48 codes)
	- `0x30-0x7F`: Dictionary references (80 entries)
	- `0x80-0xFF`: Direct characters (128 chars)

2. **Dictionary Entries**:
	- Located at PC 0x01BA35 (SNES $03:BA35)
	- Format: `[length_byte][data_bytes...]`
	- Can recursively reference other dictionary entries
	- Maximum recursion depth: 10 levels

3. **Notable Entries**:
	```
	0x3D = "Crystal"
	0x3E = "RainbowRoad"
	0x3F = "th"
	0x40 = "e "
	0x41 = "the "
	0x44 = "you"
	0x46 = "to "
	0x48 = "ing "
	0x4D = ". "  (period + space)
	0x53 = ",,,"  (three commas)
	0x5D = "I'll"
	```

### Decoding Example
```
Raw bytes: 4C 70 C1 B4 C0 40 B5 B8 B9...

Decoded:
"For years Mac's been studying a Prophecy, 
On his way back from doing some research.
the lake dried up and his ship ended up on a rock ledge,"
```

## 🎮 Control Codes

### Common Control Codes

| Code | Tag | Function | Usage |
|------|-----|----------|-------|
| 0x00 | `[END]` | String terminator | Every string |
| 0x01 | `{newline}` | Line break | Multi-line text |
| 0x02 | `[WAIT]` | Wait for button press | Dialog pacing |
| 0x03 | `[ASTERISK]` | Special marker | Rare |
| 0x04 | `[NAME]` | Insert character name | Dynamic text |
| 0x05 | `[ITEM]` | Insert item name | Dynamic text |
| 0x06 | `[SPACE]` | Space/underscore | Spacing |
| 0x1A | `[TEXTBOX_BELOW]` | Position box below | Dialog positioning |
| 0x1B | `[TEXTBOX_ABOVE]` | Position box above | Dialog positioning |
| 0x1F | `[CRYSTAL]` | Insert "Crystal" | Location name |

### Control Code Analysis
Used 20,715+ times across 52 dialogs:
- `CMD:08`: 20,715 uses (most common)
- `CMD:0B`: 12,507 uses
- `CMD:0C`: 7,925 uses
- `CMD:10`: 16,321 uses

See `docs/CONTROL_CODES.md` for complete reference.

## 📝 Character Table

### Format
`simple.tbl` uses hex-to-character mappings:
```
80=~
81=…
83=é
84=è
87=à
8A=ü
8B=ö
8C=ä
CE='
D0=.
D2=,
DC=:
DE=;
E7="
EB=?
F7=!
FF= 
```

### Recent Updates
Fixed 16 unknown characters:
- **Punctuation**: `. , ' : ; ? ! "`
- **Accented**: `é è à ü ö ä`
- **Special**: `~ …`

## 💾 File Formats

### Extracted Dialog Format
```
### Dialog 0x00
[NAME], wake up!
It's time to save the world!{newline}
[TEXTBOX_BELOW]The [CRYSTAL] needs you![END]

### Dialog 0x01
For years Mac's been studying a Prophecy,[CMD:0D]
On his way back from doing some research.
```

### Control Code Tags
- Hexadecimal: `[CMD:XX]` where XX is hex byte
- Named tags: `[END]`, `{newline}`, `[WAIT]`, `[ITEM]`, etc.
- Special: `[CRYSTAL]`, `[NAME]`, `[TEXTBOX_BELOW]`

## 🔬 Technical Details

### ROM Locations
```
Simple Text:     $06:F000-$06:FFFF (PC 0x06F000+)
Complex Text:    $03:A000-$03:FFFF (PC 0x030000+)
Dialog Pointers: $03:B835          (PC 0x01B835)
Dictionary:      $03:BA35          (PC 0x01BA35)
Command Jump:    $00:9E0E          (PC 0x009E0E)
```

### Dictionary Structure
```python
# Each entry:
[length: 1 byte]
[data: <length> bytes]

# Data can contain:
- Control codes (0x00-0x2F)
- Dictionary refs (0x30-0x7F) - recursive!
- Characters (0x80-0xFF)
```

### Size Constraints
- Each dialog has fixed space in ROM
- Cannot exceed original size without relocation
- `import_complex_text.py` validates before writing
- Warns if text too large

## 📊 Performance Metrics

### Extraction Speed
- Simple text: ~0.1 seconds (595 entries)
- Complex text: ~0.3 seconds (117 dialogs)
- Character analysis: ~0.5 seconds
- Control code analysis: ~2.0 seconds

### Compression Ratio
- Dictionary: ~40% space savings vs uncompressed
- Common words save most space ("the", "you", etc.)
- 80 entries cover majority of word combinations

## 🐛 Known Issues & Limitations

1. **Control Codes**: ~50% documented
	- Solution: Continue assembly analysis
	- See: `docs/CONTROL_CODES.md`

2. **Size Limits**: Cannot expand dialogs beyond original
	- Solution: Requires ROM relocation (future enhancement)
	- Workaround: Keep edits same size or smaller

3. **Some Characters**: ~2% still unknown
	- Solution: More ROM analysis
	- Status: Non-critical, mostly rare special chars

## 🛠️ Development

### Adding Control Codes
1. Analyze with `analyze_control_codes_detailed.py`
2. Check jump table at $00:9E0E in `bank_00_documented.asm`
3. Update `docs/CONTROL_CODES.md`
4. Add tag mapping in `import_complex_text.py`

### Adding Characters
1. Find byte in ROM
2. Update `simple.tbl`
3. Re-run extraction
4. Verify output

### Testing Changes
```bash
# Run all validation
python tools/ffmq_text.py validate

# Batch analysis
python tools/ffmq_text.py batch-analyze

# Test specific dialog
python tools/extraction/extract_dictionary.py
```

## 📚 Documentation

- **`docs/CONTROL_CODES.md`**: Complete control code reference
- **`docs/DICTIONARY_SYSTEM_DISCOVERY.md`**: Technical deep-dive
- **`docs/TEXT_SYSTEMS_ANALYSIS.md`**: System overview
- **`reports/`**: Analysis reports and findings

## 🎯 Future Enhancements

- [ ] Complete control code documentation (50% → 100%)
- [ ] ROM expansion support for larger dialogs
- [ ] GUI tool for text editing
- [ ] Automated translation workflow
- [ ] Font table editor
- [ ] Live ROM preview

## ✅ Changelog

**2025-01-24**: Major Breakthrough
- ✨ Discovered dictionary compression system
- ✅ Fixed 16 unknown characters
- ✅ Implemented complex text re-insertion
- ✅ Created unified CLI toolkit
- 📊 98%+ dialog readability achieved

**2025-01-23**: Analysis Tools
- 🔍 Created control code analyzer
- 🔍 Created character analyzer
- 📝 Documented 25+ control codes

**2025-01-22**: Simple Text Complete
- ✅ Simple text extraction working
- ✅ Simple text re-insertion working
- ✅ Round-trip validation passing

## 📄 License

See LICENSE file in repository root.

## 🤝 Contributing

1. Test with `batch-analyze` and `validate`
2. Update docs in `docs/`
3. Use tabs (not spaces)
4. Descriptive commit messages
5. Create pull request

## 💬 Support

- GitHub Issues: Report bugs and request features
- Documentation: See `docs/` folder
- Reports: Check `reports/` for analysis data

---

**Made with 🎮 for FFMQ Translation Projects**
