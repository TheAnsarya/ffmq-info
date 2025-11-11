# FFMQ Dialog Control Codes and Event Commands

## Overview

Final Fantasy Mystic Quest uses a sophisticated dialog system with control codes for text formatting, timing, and in-game events. This document catalogs all known control codes and their functions.

## Text Control Codes

### Basic Text Flow

| Code | Hex | Name | Description |
|------|-----|------|-------------|
| `[END]` | 0x00 | End of String | Required terminator for all text strings |
| `{newline}` | 0x01 | Newline | Line break within same dialog box |
| `[WAIT]` | 0x02 | Wait | Wait for player button press before continuing |
| `*` | 0x03 | Special Character | Asterisk or special marker |
| `[NAME]` | 0x04 | Character Name | Insert player character name |
| `[ITEM]` | 0x05 | Item Name | Insert item name from context |
| `_` | 0x06 | Space | Space character (also used directly in text) |

### Dialog Box Control

| Code | Hex | Name | Description |
|------|-----|------|-------------|
| `[CLEAR]` | 0x23 | Clear Box | Clear current dialog box |
| `[PARA]` | 0x30 | Paragraph | New paragraph within same page (line break + spacing) |
| `[PAGE]` | 0x36 | New Page | Start new dialog box page |

### Unknown Control Codes

These codes appear in the ROM but their exact function is not yet documented:

| Code | Hex | Notes |
|------|-----|-------|
| `[UNK_0E]` | 0x0E | Unknown function |
| `[UNK_0F]` | 0x0F | Unknown function |

## Event Parameter Codes

These codes appear to be used for passing parameters to dialog events or scripting:

### Single-Byte Parameters

| Code | Hex | Likely Function |
|------|-----|----------------|
| `[P10]` | 0x10 | Event parameter |
| `[P11]` | 0x11 | Event parameter |
| `[P12]` | 0x12 | Event parameter |
| `[P13]` | 0x13 | Event parameter |
| `[P14]` | 0x14 | Event parameter |
| `[P15]` | 0x15 | Event parameter |
| `[P1A]` | 0x1A | Event parameter |
| `[P1B]` | 0x1B | Event parameter |
| `[P1C]` | 0x1C | Event parameter |
| `[P1D]` | 0x1D | Event parameter |
| `[P1E]` | 0x1E | Event parameter |
| `[P20]` | 0x20 | Event parameter |
| `[P21]` | 0x21 | Event parameter |
| `[P25]` | 0x25 | Event parameter |
| `[P26]` | 0x26 | Event parameter |
| `[P27]` | 0x27 | Event parameter |
| `[P2A]` | 0x2A | Event parameter |
| `[P2B]` | 0x2B | Event parameter |
| `[P2C]` | 0x2C | Event parameter |
| `[P32]` | 0x32 | Event parameter |
| `[P33]` | 0x33 | Event parameter |
| `[P35]` | 0x35 | Event parameter |
| `[P37]` | 0x37 | Event parameter |
| `[P38]` | 0x38 | Event parameter |

### Special Named Parameters

| Code | Hex | Name | Description |
|------|-----|------|-------------|
| `[CRYSTAL]` | 0x1F | Crystal | Related to crystal events/items |

## Extended Control Codes (0x80-0x8F)

These appear to be extended control codes, possibly for advanced features:

| Code | Hex | Notes |
|------|-----|-------|
| `[C80]` | 0x80 | Unknown extended control |
| `[C81]` | 0x81 | Unknown extended control |
| `[C82]` | 0x82 | Unknown extended control |
| `[C83]` | 0x83 | Unknown extended control |
| `[C85]` | 0x85 | Unknown extended control |
| `[C88]` | 0x88 | Unknown extended control |
| `[C8A]` | 0x8A | Unknown extended control |
| `[C8B]` | 0x8B | Unknown extended control |
| `[C8C]` | 0x8C | Unknown extended control |
| `[C8D]` | 0x8D | Unknown extended control |
| `[C8E]` | 0x8E | Unknown extended control |
| `[C8F]` | 0x8F | Unknown extended control |

## DTE (Dual Tile Encoding) Sequences

FFMQ uses DTE compression where common multi-character sequences are encoded as single bytes. The `complex.tbl` file contains 116 DTE sequences including:

### Common Words and Phrases
- `the` (0x41), `you` (0x44, 0x55), `I'll` (0x5D), `I'm` (0x75)
- `that` (0x70), `prophecy` (0x71), `again` (0x64)
- `monst` (0x7C) - likely for "monster"

### Common Suffixes/Prefixes
- `ing` (0x48), `er` (0x4B, 0x6A), `ed` (0x68), `es` (0x60)
- `ou` (0x43), `en` (0x56), `on` (0x54), `or` (0x5C)

### Common Combinations
- `...` (0x53) - ellipsis
- `'s` (0x4E) - possessive
- `'t` (0x7E) - contraction ending

### Special Location Names
- `Crystal` (0x3D)
- `Rainbow Road` (0x3E)
- `Spencer` (0x79)

### Complex Multi-Byte Sequences

Some DTE entries contain embedded control codes:

```
50={05}{1d}E{00}{04}  - Item insertion with parameters
51={05}{1e}E{00}{04}  - Item insertion with parameters
61={08}{08}{8a}{87}{81}  - Complex control sequence
62={08}{8a}{87}  - Control sequence
6E=!{08}{57}{84}  - Exclamation with controls
6F=!{newline}  - Exclamation with newline
73=.{newline}  - Period with newline
74=.{08}{57}{84}  - Period with controls
```

These appear to be macros that combine text with control codes for common dialog patterns.

## Character Encoding

### Numbers (0x90-0x99)
- `0x91-0x99` → `1-9`

### Uppercase Letters (0x9A-0xB3)
- `0x9A-0xB3` → `A-Z`

### Lowercase Letters (0xB4-0xCD)
- `0xB4-0xCD` → `a-z`

### Punctuation
- `0xCE` → `!` (exclamation)
- `0xCF` → `?` (question)
- `0xD0` → `,` (comma)
- `0xD1` → `'` (apostrophe)
- `0xD2` → `.` (period)
- `0xDA` → `-` (dash)
- `0xDB` → `&` (ampersand)

## Dialog Box Specifications

### Layout
- **Characters per line:** 32 (proportional font)
- **Lines per page:** 3
- **Maximum pages:** 4 (with `[PAGE]` breaks)
- **Total capacity:** ~96 characters per page

### Proportional Font Widths

Characters have varying widths:
- **Narrow (0.5 units):** `.`, `,`, `!`, `i`, `l`
- **Normal (1.0 units):** Most letters and numbers
- **Wide (1.5 units):** `W`, `M`, `m`, `@`

Use the `text_overflow_detector.py` tool to check if dialog text fits within box constraints.

## Compression Statistics

Based on analysis of all 116 dialogs:
- **Average compression ratio:** ~57.9%
- **Total bytes:** 4,875 bytes
- **Uncompressed equivalent:** ~11,600+ characters
- **Space saved:** ~6,700+ bytes

The DTE system saves approximately **58%** of space compared to uncompressed text.

## Usage in Dialog Editing

### Writing Dialog Text

When creating or editing dialog text, use these conventions:

```
Example dialog with proper control codes:
[NAME], you must find the[PARA]Crystal of Fire to save[PARA]the world![WAIT][CLEAR]Use the [ITEM] wisely.[END]
```

### Control Code Best Practices

1. **Always end with `[END]`** - Required for all text strings
2. **Use `[PARA]` for line breaks** - Better than raw newlines within a page
3. **Use `[PAGE]` for multi-page dialogs** - Starts new dialog box
4. **Use `[WAIT]` for dramatic pauses** - Player must press button
5. **Use `[CLEAR]` before new dialog** - Clears previous text

### Validation

Use the dialog CLI tools to validate text:

```bash
# Check for issues
python tools/map-editor/dialog_cli.py validate

# Auto-fix common problems
python tools/map-editor/dialog_cli.py validate --fix

# Check for overflow
python tools/map-editor/text_overflow_detector.py
```

## Technical Implementation

### Dialog Database Structure

Dialogs are stored using a pointer table system:
- **Pointer table:** PC address `0x00D636`
- **Dialog bank:** SNES bank `$03` (PC: `0x018000-0x01FFFF`)
- **Pointer format:** 16-bit little-endian
- **String format:** DTE-compressed with control codes

### Pointer Calculation

```
SNES pointer → PC address:
pc_addr = ((bank - 2) * 0x8000) + (pointer & 0x7FFF)

For bank $03:
pc_addr = ((3 - 2) * 0x8000) + (pointer & 0x7FFF)
pc_addr = 0x8000 + (pointer & 0x7FFF)
```

## Future Research

Areas requiring further investigation:

1. **Parameter Codes (0x10-0x38):** Exact function of P## codes
2. **Extended Controls (0x80-0x8F):** Purpose of C## codes
3. **Unknown Codes (0x0E, 0x0F):** Behavior and usage
4. **Multi-byte Sequences:** Full meaning of complex DTE entries
5. **Event Integration:** How dialog triggers game events
6. **Script Commands:** Relationship to map events and scripts

## Tools

### Extraction
- `tools/extraction/extract_all_text.py` - Extract all text with proper DTE decoding
- `tools/map-editor/dialog_cli.py export` - Export dialogs to JSON

### Editing
- `tools/map-editor/dialog_cli.py edit` - Interactive dialog editor
- `tools/map-editor/dialog_cli.py import` - Import from JSON

### Analysis
- `tools/map-editor/compression_optimizer.py` - DTE optimization analysis
- `tools/map-editor/text_overflow_detector.py` - Detect dialog box overflow
- `tools/map-editor/dialog_cli.py stats` - Show text statistics

### Validation
- `tools/map-editor/dialog_cli.py validate` - Check for issues
- `tools/map-editor/dialog_cli.py validate --fix` - Auto-fix problems

## References

- **DataCrystal Wiki:** FFMQ text encoding documentation
- **complex.tbl:** Character table with DTE mappings
- **dialog_cli.py:** Full-featured dialog editing tool
- **dialog_text.py:** Text encoding/decoding implementation
- **dialog_database.py:** Dialog storage and retrieval

## See Also

- `README.md` - Main documentation
- `COMMAND_REFERENCE.md` - Dialog CLI command reference
- `FINAL_SESSION_SUMMARY.md` - Development session summary
