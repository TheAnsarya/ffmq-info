# FFMQ ROM Hacking Toolkit - Quick Reference
## Complete Guide to Dialog System Modification and Control Code Analysis

================================================================================

## 🚀 Quick Start

### For Fan Translators

**Extract game text:**
```bash
python tools/extraction/extract_dialogs.py
```

**Write your translation** in `data/my_translation.txt`:
```
[DIALOG 0]
@TEXTBOX_BOTTOM
Bienvenido al mundo de
Final Fantasy Mystic Quest!
[WAIT]
[END]
```

**Compile translation:**
```bash
python tools/rom_hacking/dialog_compiler.py data/my_translation.txt --rom input.sfc --output translated.sfc
```

**Test in emulator:**
```bash
mesen translated.sfc
```

### For ROM Hackers

**Analyze unknown codes:**
```bash
python tools/analysis/unknown_code_investigator.py
```

**Optimize dictionary:**
```bash
python tools/analysis/dictionary_optimizer.py
```

**Create test ROM:**
```bash
python tools/testing/rom_test_patcher.py
```

**Analyze subroutines:**
```bash
python tools/analysis/subroutine_analyzer.py
```

================================================================================

## 📚 Complete Toolkit

### Analysis Tools

#### 1. Dictionary Optimizer
**Purpose**: Analyze dictionary compression efficiency

**Usage**:
```bash
python tools/analysis/dictionary_optimizer.py
```

**Outputs**:
- `docs/DICTIONARY_OPTIMIZATION.md` - Complete analysis report
- Compression ratio: 4.70:1
- Space efficiency: 78.7%
- Bytes saved: 3,376
- Top performing entries
- Underused entries (replacement candidates)

**Key Findings**:
- 8 entries never used
- 25 entries used < 5 times
- Top 20 entries provide majority of benefit

#### 2. Unknown Code Investigator
**Purpose**: Identify functionality of unknown control codes

**Usage**:
```bash
python tools/analysis/unknown_code_investigator.py
```

**Outputs**:
- `docs/UNKNOWN_CODES_INVESTIGATION.md` - Investigation report
- Usage statistics for each code
- Parameter pattern analysis
- Hypotheses generation
- Priority investigation list

**Codes Investigated**:
- 0x07 (4 uses) - Unclear functionality
- 0x09 (32 uses) - 2-byte param, likely memory operation
- 0x0A (33 uses) - 2-byte param, similar to 0x09
- 0x0B (27 uses) - 2-byte param, forms family with 0x09/0x0A
- 0x0C (13 uses) - No params, needs testing
- 0x0D (8 uses) - No params, needs testing

#### 3. Subroutine Analyzer
**Purpose**: Disassemble external subroutines called by handlers

**Usage**:
```bash
python tools/analysis/subroutine_analyzer.py
```

**Outputs**:
- `docs/SUBROUTINE_ANALYSIS.md` - Disassembly report
- JSL call documentation
- Register usage tracking
- Memory access patterns

**Features**:
- SNES to PC address conversion (LoROM)
- 65816 instruction decoder (40+ opcodes)
- Automatic disassembly
- Bitfield operation identification

### ROM Modification Tools

#### 4. ROM Test Patcher
**Purpose**: Generate test ROMs for empirical validation

**Usage**:
```bash
python tools/testing/rom_test_patcher.py
```

**Outputs**:
- 5 test ROMs in `roms/test/`
- `docs/ROM_TEST_RESULTS.md` - Test documentation

**Test Scenarios**:
1. `test_format_1d_vs_1e.sfc` - Formatting code differences
2. `test_memory_write_0e.sfc` - Memory write validation
3. `test_subroutine_0x08.sfc` - Subroutine call test
4. `test_equipment_slots.sfc` - Equipment slot detection
5. `test_unused_codes.sfc` - Unused code functionality

**Usage in Emulator**:
1. Load test ROM in emulator
2. Open memory viewer
3. Observe dialog display
4. Check memory changes
5. Document results

#### 5. Dialog Compiler
**Purpose**: Compile human-readable scripts to ROM format

**Usage**:
```bash
# Full compilation and patching
python tools/rom_hacking/dialog_compiler.py script.txt --rom input.sfc --output output.sfc

# Compile only (no patching)
python tools/rom_hacking/dialog_compiler.py script.txt --no-patch

# With validation
python tools/rom_hacking/dialog_compiler.py script.txt --validate

# Generate report
python tools/rom_hacking/dialog_compiler.py script.txt --report compilation_report.md
```

**Script Format**:
```
[DIALOG N]
@TEXTBOX_POSITION
Text goes here
[CONTROL_CODE]
More text
[END]
```

**Control Codes**:
- `[END]` - End dialog
- `[NEWLINE]` - New line
- `[WAIT]` - Wait for button press
- `[DELAY]` - Add delay
- `[CLEAR]` - Clear textbox
- `[NAME]` - Player name
- `[ITEM]` - Item name
- `@TEXTBOX_BOTTOM` - Position textbox (bottom)
- `@TEXTBOX_MIDDLE` - Position textbox (middle)
- `@TEXTBOX_TOP` - Position textbox (top)
- `[CMD:XX]` - Any control code by hex value

================================================================================

## 🔬 Control Code Reference

### Fully Understood (33 codes)

| Code | Name | Parameters | Purpose |
|------|------|------------|---------|
| 0x00 | END | None | End dialog |
| 0x01 | NEWLINE | None | New line |
| 0x02 | DELAY | None | Add delay |
| 0x03 | WAIT | None | Wait for button |
| 0x04 | CONTINUE | None | Continue to next dialog |
| 0x05 | CLEAR | None | Clear textbox |
| 0x06 | UNK_06 | 1 byte | Unknown |
| 0x08 | SUBROUTINE | 2 bytes | Call dialog subroutine |
| 0x0E | MEMORY_WRITE | 4 bytes | Write value to memory |
| 0x10 | EQUIPMENT | 1 byte | Insert equipment name |
| 0x11-0x16 | Various | Varies | Formatting/display codes |
| 0x17 | ITEM_NAME | 1 byte | Insert item name |
| 0x18 | ITEM_NAME2 | 1 byte | Insert item name (variant) |
| 0x1A-0x22 | Various | Varies | Special functions |
| 0x23 | TEXTBOX_BOTTOM | None | Position textbox bottom |
| 0x24 | TEXTBOX_MIDDLE | None | Position textbox middle |
| 0x25 | TEXTBOX_TOP | None | Position textbox top |
| 0x26 | ITEM_PREFIX | None | Item name prefix |
| 0x20 | PLAYER_NAME | None | Insert player name |

### Investigated (6 codes)

| Code | Occurrences | Parameters | Hypothesis |
|------|-------------|------------|------------|
| 0x07 | 4 | 0 bytes | Unclear functionality |
| 0x09 | 32 | 2 bytes | Memory operation/table lookup |
| 0x0A | 33 | 2 bytes | Similar to 0x09 (variant) |
| 0x0B | 27 | 2 bytes | Forms family with 0x09/0x0A |
| 0x0C | 13 | 0 bytes | Needs emulator testing |
| 0x0D | 8 | 0 bytes | Needs emulator testing |

### Dictionary Entries (80 codes)

| Code Range | Purpose |
|------------|---------|
| 0x30-0x7F | Dictionary entry references (80 entries) |

**Special Dictionary Entries**:
- 0x30: Most efficient (384 bytes saved, 24 uses)
- 0x50-0x51: Use formatting codes 0x1D, 0x1E
- 0x37, 0x39, 0x3B, 0x3E: Never used (replacement candidates)

### Character Codes (beyond 0x7F)

See `simple.tbl` for complete character mapping.

================================================================================

## 📖 Workflow Examples

### Example 1: Fan Translation to Spanish

**Step 1: Extract dialogs**
```bash
python tools/extraction/extract_dialogs.py
# Creates data/extracted_dialogs.json
```

**Step 2: Create translation script**

`spanish_translation.txt`:
```
[DIALOG 0]
@TEXTBOX_BOTTOM
Bienvenido al mundo de
Final Fantasy Mystic Quest!
[WAIT]
[END]

[DIALOG 1]
@TEXTBOX_TOP
¿Cómo te llamas?
[WAIT]
[NAME]
[NEWLINE]
¡Encantado de conocerte!
[END]
```

**Step 3: Compile translation**
```bash
python tools/rom_hacking/dialog_compiler.py spanish_translation.txt \
    --rom FFMQ.sfc \
    --output FFMQ_Spanish.sfc \
    --validate
```

**Step 4: Test**
```bash
mesen FFMQ_Spanish.sfc
```

**Step 5: Iterate**
- Modify script
- Recompile
- Test again

### Example 2: ROM Hack with Custom Content

**Step 1: Analyze dictionary for space**
```bash
python tools/analysis/dictionary_optimizer.py
# Check DICTIONARY_OPTIMIZATION.md for underused entries
```

**Step 2: Create custom dialog script**

`custom_quest.txt`:
```
[DIALOG 0]
@TEXTBOX_BOTTOM
Welcome to the
CUSTOM QUEST!
[NEWLINE]
This is a fan-made
adventure!
[WAIT]
[END]
```

**Step 3: Compile custom content**
```bash
python tools/rom_hacking/dialog_compiler.py custom_quest.txt \
    --rom FFMQ.sfc \
    --output FFMQ_CustomQuest.sfc
```

**Step 4: Test functionality**
```bash
python tools/testing/rom_test_patcher.py
# Generate test ROMs for validation
```

**Step 5: Validate in emulator**
- Load test ROMs
- Check memory viewer
- Verify all custom codes work

### Example 3: Investigating Unknown Code

**Step 1: Run investigator**
```bash
python tools/analysis/unknown_code_investigator.py
# Creates UNKNOWN_CODES_INVESTIGATION.md
```

**Step 2: Review findings**
```bash
# Check priority codes (0x09, 0x0A, 0x0B)
# Review usage patterns
# Read hypotheses
```

**Step 3: Create test ROM**

Edit `tools/testing/rom_test_patcher.py` to add new test:
```python
def test_code_0x09(self):
    """Test code 0x09 with various parameters."""
    dialog_bytes = [
        0x25,  # TEXTBOX_TOP
        0x01,  # NEWLINE
        0x09, 0xDE, 0xF5,  # Code 0x09 with 2-byte param
        0x00,  # END
    ]
    return dialog_bytes
```

**Step 4: Generate and test**
```bash
python tools/testing/rom_test_patcher.py
# Test in emulator
# Document results
```

================================================================================

## 🎯 Common Tasks

### Find Space for Custom Text

```bash
# Analyze dictionary
python tools/analysis/dictionary_optimizer.py

# Check underused entries in DICTIONARY_OPTIMIZATION.md
# Replace entries with 0 occurrences
```

### Validate Dialog Length

```bash
# Compile with validation
python tools/rom_hacking/dialog_compiler.py script.txt --validate

# Check compilation report
# Look for length warnings
```

### Debug Control Code Issues

```bash
# Search for code usage
python tools/analysis/unknown_code_investigator.py

# Create test ROM
python tools/testing/rom_test_patcher.py

# Test in emulator with memory viewer
```

### Optimize Compression

```bash
# Run optimizer
python tools/analysis/dictionary_optimizer.py

# Review top performers (preserve these)
# Review underused entries (replace these)
# Maintain 2:1+ compression ratio
```

================================================================================

## 📊 Tool Options Reference

### Dialog Compiler Options

```
--table FILE        Character table file (.tbl)
--rom FILE          Input ROM file
--output FILE       Output ROM file
--report FILE       Generate compilation report
--validate          Validate dialogs before patching
--no-patch          Skip ROM patching (compile only)
```

### Unknown Code Investigator Options

```
--disassembly FILE  Handler disassembly file
--dialogs FILE      Extracted dialogs JSON
--output FILE       Investigation report path
```

### Dictionary Optimizer Options

```
--frequency FILE    Dictionary usage CSV
--dialogs FILE      Extracted dialogs JSON
--output FILE       Optimization report path
```

### ROM Test Patcher Options

```
(No command-line options - edit script to add tests)
```

### Subroutine Analyzer Options

```
--rom FILE          ROM file path
--log FILE          Disassembly log file
--output FILE       Analysis report path
```

================================================================================

## 🔍 Troubleshooting

### "Unknown character" warnings

**Problem**: Compiler shows warnings for unknown characters

**Solution**: Check `simple.tbl` for character codes
- Space is 0xFF
- Most common characters are 0x80-0x9F
- Add missing characters to table if needed

### Compilation validation errors

**Problem**: "Missing [END] code" error

**Solution**: Ensure every dialog ends with `[END]`
```
[DIALOG 0]
Your text here
[END]  <- Don't forget this!
```

### Dialog overflow

**Problem**: Text too long for textbox

**Solution**: 
- Check compilation report for length
- Add `[NEWLINE]` to break lines
- Split into multiple dialogs
- Use dictionary compression

### Test ROM not working

**Problem**: Test ROM crashes or freezes

**Solution**:
- Check test scenario code
- Verify dialog pointer redirection
- Test with known-good codes first
- Use emulator debugger

================================================================================

## 📚 Documentation Files

### Analysis Reports

- `docs/DICTIONARY_OPTIMIZATION.md` - Dictionary compression analysis
- `docs/UNKNOWN_CODES_INVESTIGATION.md` - Unknown code investigation
- `docs/SUBROUTINE_ANALYSIS.md` - External subroutine analysis
- `docs/ROM_TEST_RESULTS.md` - Test ROM documentation
- `docs/SESSION_PROGRESS_REPORT.md` - Complete session summary

### Technical Reference

- `docs/HANDLER_DISASSEMBLY.md` - Complete handler disassembly
- `simple.tbl` - Character encoding table
- `data/dictionary_usage.csv` - Dictionary usage statistics

### User Guides

- `README.md` - Main project documentation
- `docs/QUICK_REFERENCE.md` - This file
- `data/sample_dialog_script.txt` - Example script

================================================================================

## 🚀 Next Steps

### For Beginners

1. Read this quick reference
2. Try sample dialog script
3. Compile with `--no-patch` to practice
4. Test with emulator

### For Translators

1. Extract existing dialogs
2. Create translation script
3. Compile and test
4. Iterate until complete

### For ROM Hackers

1. Run all analysis tools
2. Study reports
3. Create test ROMs
4. Experiment with custom codes

### For Researchers

1. Review disassembly documentation
2. Run unknown code investigator
3. Validate hypotheses with test ROMs
4. Document findings

================================================================================

## 💡 Tips and Best Practices

### Translation Tips

1. **Preserve control codes** - Keep all [CMD:XX] codes in same positions
2. **Test frequently** - Compile and test often to catch issues early
3. **Use validation** - Always compile with `--validate` flag
4. **Check length** - Monitor dialog length in compilation reports
5. **Maintain compression** - Keep similar text patterns for dictionary efficiency

### ROM Hacking Tips

1. **Start small** - Test one code at a time
2. **Document everything** - Keep notes on discoveries
3. **Use test ROMs** - Don't modify main ROM directly
4. **Check memory** - Use emulator memory viewer for validation
5. **Compare with original** - Always test against original ROM behavior

### Analysis Tips

1. **Run all tools** - Use complete toolkit for comprehensive analysis
2. **Cross-reference** - Compare results across different tools
3. **Trust high usage** - Codes used frequently are easier to understand
4. **Test hypotheses** - Create test ROMs to validate theories
5. **Share findings** - Document discoveries for community

================================================================================

## 📞 Support

### Issues?

- Check troubleshooting section above
- Review documentation files
- Test with sample script first
- Create GitHub issue if needed

### Contributing?

- Run analysis tools
- Document findings
- Share test results
- Submit pull requests

================================================================================

**Last Updated**: 2025-11-12
**Version**: 1.0
**Author**: TheAnsarya

For complete documentation, see `docs/SESSION_PROGRESS_REPORT.md`
