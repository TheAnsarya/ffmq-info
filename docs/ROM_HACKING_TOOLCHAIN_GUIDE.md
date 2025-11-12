# FFMQ ROM Hacking Toolchain - Quick Start Guide

This guide covers the complete ROM hacking toolchain for Final Fantasy: Mystic Quest, including analysis, compilation, and decompilation tools.

## Table of Contents

1. [Overview](#overview)
2. [Installation](#installation)
3. [Tool Reference](#tool-reference)
4. [Workflow Examples](#workflow-examples)
5. [Best Practices](#best-practices)

---

## Overview

The FFMQ ROM hacking toolchain consists of four main categories:

### Analysis Tools

- **Parameter Pattern Analyzer** - Analyze parameter patterns to suggest unknown command meanings
- **Character Encoding Verifier** - Validate character table files and encoding
- **Event System Analyzer** - Comprehensive event command statistics and patterns

### Compilation Tools

- **Enhanced Dialog Compiler** - Compile human-readable scripts to ROM format (all 48 commands)
- **Event Script Decompiler** - Decompile ROM data to human-readable scripts

### Validation Tools

- **Character Encoding Verifier** - Round-trip encoding tests and validation
- **Build Verification** - Ensure ROM integrity after modifications

---

## Installation

### Requirements

```bash
# Python 3.8+
python --version

# Required packages (standard library only for most tools)
# Optional: numpy, sklearn for advanced pattern analysis
pip install -r requirements.txt
```

### Setup

```bash
# 1. Clone repository
git clone https://github.com/TheAnsarya/ffmq-info.git
cd ffmq-info

# 2. Verify tools exist
ls tools/rom_hacking/
ls tools/analysis/

# 3. Prepare character tables
# Ensure simple.tbl and complex.tbl are in root directory
```

---

## Tool Reference

### 1. Parameter Pattern Analyzer

**Purpose**: Automatically analyze parameter patterns for unknown event commands and suggest meanings.

**Location**: `tools/analysis/parameter_pattern_analyzer.py`

**Usage**:

```bash
# Basic usage - analyze event system data
python tools/analysis/parameter_pattern_analyzer.py \
	--input output/ \
	--output docs/parameter_analysis

# Advanced usage with clustering (requires sklearn)
python tools/analysis/parameter_pattern_analyzer.py \
	--input output/ \
	--output docs/parameter_analysis \
	--cluster
```

**Input Files** (from event_system_analyzer.py):
- `output/event_command_statistics.json`
- `output/event_command_usage.csv`

**Output Files**:
- `parameter_analysis.json` - Statistical analysis per parameter
- `command_hypotheses.json` - Auto-generated suggestions with confidence scores
- `PARAMETER_ANALYSIS_REPORT.md` - Comprehensive report with evidence

**Key Features**:
- Statistical analysis (min, max, mean, median, mode, histogram)
- Type detection (item IDs, spell IDs, memory addresses, ROM pointers, flag masks)
- Hypothesis generation based on parameter patterns
- Confidence scoring with evidence
- Optional K-means clustering for pattern discovery

**Example Output**:

```json
{
	"UNK_07": {
		"param_0": {
			"type": "ITEM_ID",
			"confidence": 0.85,
			"evidence": ["Values in range 0-255", "Mode=42 (Cure Potion)"],
			"min": 0,
			"max": 255,
			"mean": 67.3
		}
	}
}
```

---

### 2. Character Encoding Verifier

**Purpose**: Validate character table files and ensure correct text encoding.

**Location**: `tools/analysis/character_encoding_verifier.py`

**Usage**:

```bash
# Verify simple.tbl
python tools/analysis/character_encoding_verifier.py \
	--simple simple.tbl

# Verify both tables with ROM cross-reference
python tools/analysis/character_encoding_verifier.py \
	--simple simple.tbl \
	--complex complex.tbl \
	--rom ffmq.sfc
```

**Output Files**:
- `CHARACTER_ENCODING_VERIFICATION.md` - Full validation report

**Validation Checks**:
1. **Duplicate Mappings** - Multiple characters mapped to same byte
2. **Missing Reverse Mappings** - Byte→char exists but char→byte doesn't
3. **Invalid Format** - Malformed table entries
4. **Unmapped Ranges** - Gaps in byte value coverage
5. **Round-trip Tests** - text→bytes→text validation
6. **Space Character** - Special handling for 0xFF vs '*'
7. **DTE Conflicts** - Dual-tile encoding conflicts

**Example Report Section**:

```markdown
## Validation Results

✅ **simple.tbl**: 256 mappings, 0 errors, 2 warnings
⚠️  **complex.tbl**: 512 mappings, 1 error, 5 warnings

### Issues Found

**ERROR**: Duplicate mapping for byte 0x4A
- 'J' → 0x4A
- 'j' → 0x4A
**Suggestion**: Use distinct bytes for uppercase/lowercase

**WARNING**: Unmapped range 0xA0-0xAF (16 bytes)
**Suggestion**: Consider mapping control characters or special symbols
```

---

### 3. Enhanced Dialog Compiler

**Purpose**: Compile human-readable dialog/event scripts to ROM format with full validation.

**Location**: `tools/rom_hacking/enhanced_dialog_compiler.py`

**Usage**:

```bash
# Basic compilation
python tools/rom_hacking/enhanced_dialog_compiler.py \
	--script dialogs.txt \
	--table simple.tbl

# With validation and detailed report
python tools/rom_hacking/enhanced_dialog_compiler.py \
	--script dialogs.txt \
	--table simple.tbl \
	--validate \
	--report output/compilation_report.md

# Export to ROM file
python tools/rom_hacking/enhanced_dialog_compiler.py \
	--script dialogs.txt \
	--table simple.tbl \
	--output compiled_dialogs.bin
```

**Script Format**:

```
; This is a comment

[DIALOG 0]
; Textbox positioning
@TEXTBOX_BOTTOM

; Dialog text
Welcome to Final Fantasy Mystic Quest!
[NEWLINE]
What is your name?
[NAME]
[WAIT]

; Memory operations (quest flag)
[MEMORY_WRITE:0x1A50:0x0001]	; Set quest flag

; Control flow
[CALL_SUBROUTINE:0x9120]	; Call greeting
[END]
```

**Supported Commands** (all 48):

| Category | Commands |
|----------|----------|
| **Basic** | END, NEWLINE, WAIT, ASTERISK, NAME, ITEM, SPACE |
| **Control Flow** | CALL_SUBROUTINE |
| **Memory** | MEMORY_WRITE, SET_STATE_VAR, SET_STATE_BYTE, SET_STATE_WORD |
| **Dynamic Insertion** | INSERT_ITEM, INSERT_SPELL, INSERT_MONSTER, INSERT_CHARACTER, INSERT_LOCATION, INSERT_NUMBER, INSERT_OBJECT, INSERT_WEAPON, INSERT_ARMOR, INSERT_ACCESSORY |
| **Formatting** | TEXTBOX_BELOW, TEXTBOX_ABOVE, FORMAT_ITEM_E1, FORMAT_ITEM_E2, CRYSTAL |
| **External** | EXTERNAL_CALL_1, EXTERNAL_CALL_2, EXTERNAL_CALL_3 |
| **Unknown** | UNK_07, UNK_09, UNK_0A, UNK_0B, UNK_0C, UNK_0D, UNK_0F, UNK_1C, UNK_20, UNK_21, UNK_22, UNK_2A, UNK_2C, UNK_2E, UNK_2F |

**Parameter Validation**:

```python
# Valid parameter types
byte          # 0-255
item_id       # 0-255
spell_id      # 0-63
monster_id    # 0-255
character_id  # 0-4 (Benjamin, Kaeli, Tristam, Phoebe, Reuben)
location_id   # 0-63
mode          # 0-10
crystal_id    # 0-4 (Wind, Fire, Water, Earth)
address       # 0x0000-0xFFFF (16-bit memory address)
value         # 0x0000-0xFFFF (16-bit value)
pointer       # 0x8000-0xFFFF (ROM pointer)
```

**Error Examples**:

```
Line 15: Command MEMORY_WRITE expects 4 parameters, got 2
Line 23: Parameter value 300 (0x012C) out of range for spell_id (0-63)
Line 42: Dialog 5 not closed with [END]
```

---

### 4. Event Script Decompiler

**Purpose**: Decompile ROM event scripts to human-readable format (reverse of compiler).

**Location**: `tools/rom_hacking/event_script_decompiler.py`

**Usage**:

```bash
# Decompile specific script offsets
python tools/rom_hacking/event_script_decompiler.py \
	--rom ffmq.sfc \
	--table simple.tbl \
	--offsets 0x8FA0,0x9000,0x9100

# With ROM offset annotations
python tools/rom_hacking/event_script_decompiler.py \
	--rom ffmq.sfc \
	--table simple.tbl \
	--offsets 0x8FA0 \
	--show-offsets

# Generate detailed analysis report
python tools/rom_hacking/event_script_decompiler.py \
	--rom ffmq.sfc \
	--table simple.tbl \
	--offsets 0x8FA0,0x9000 \
	--report output/decompilation_report.md
```

**Output Format**:

```
; ========================================
; Event Script 0 - at 0xC0/8FA0
; ========================================
; Total size: 42 bytes
; Commands: 8
; Text segments: 3
; Referenced by: Scripts 5, 12, 18
; Calls 1 subroutines
; Memory writes: 2
;   - $1A50 = 0x0001
;   - $1B20 = 0x00FF

[DIALOG 0]
@TEXTBOX_BOTTOM
Welcome to Final Fantasy Mystic Quest!
[NEWLINE]
[WAIT]
[MEMORY_WRITE:0x1A50:0x0001]	; Set memory $1A50 = 0x0001
[CALL_SUBROUTINE:0x9120]	; -> Subroutine at 0x9120
[END]
```

**Features**:
- Automatic parameter type detection
- Helpful annotations for all commands
- Item/spell/character name lookup
- Control flow mapping (subroutine calls)
- Memory operation tracking
- Cross-reference analysis
- Command usage statistics

**Report Sections**:
1. **Summary** - Scripts, commands, total size
2. **Command Usage Statistics** - Frequency of each command
3. **Subroutine Call Graph** - Which scripts call which
4. **Memory Operations** - All memory writes across scripts

---

## Workflow Examples

### Workflow 1: Analyze Unknown Commands

**Goal**: Understand what unknown event commands do.

```bash
# Step 1: Run event system analyzer
python tools/analysis/event_system_analyzer.py \
	--input data/event_scripts/ \
	--output output/

# Step 2: Analyze parameter patterns
python tools/analysis/parameter_pattern_analyzer.py \
	--input output/ \
	--output docs/parameter_analysis

# Step 3: Review hypotheses
cat docs/parameter_analysis/PARAMETER_ANALYSIS_REPORT.md

# Step 4: Test hypothesis in ROM
# Create test ROM with suspected command usage
# (See manual testing tasks in CREATE_GITHUB_ISSUES.md)
```

### Workflow 2: Modify Dialog Text

**Goal**: Change dialog text in the game.

```bash
# Step 1: Decompile existing dialog
python tools/rom_hacking/event_script_decompiler.py \
	--rom ffmq.sfc \
	--table simple.tbl \
	--offsets 0x8FA0 \
	--output original_dialog.txt

# Step 2: Edit dialog in text editor
# Modify original_dialog.txt

# Step 3: Compile modified dialog
python tools/rom_hacking/enhanced_dialog_compiler.py \
	--script modified_dialog.txt \
	--table simple.tbl \
	--validate \
	--output compiled_dialog.bin

# Step 4: Patch ROM
# (Use hex editor or custom patching tool)

# Step 5: Verify encoding
python tools/analysis/character_encoding_verifier.py \
	--simple simple.tbl \
	--rom modified_ffmq.sfc
```

### Workflow 3: Create New Event Script

**Goal**: Write a completely new event sequence.

```bash
# Step 1: Write script in text editor
cat > new_event.txt << 'EOF'
[DIALOG 100]
; New quest event
@TEXTBOX_BOTTOM

You found a mysterious crystal!
[NEWLINE]
[WAIT]

; Give item reward
[INSERT_ITEM:0x42]	; Cure Potion
[NEWLINE]
[WAIT]

; Set quest flag
[MEMORY_WRITE:0x1C00:0x0001]
[END]
EOF

# Step 2: Compile and validate
python tools/rom_hacking/enhanced_dialog_compiler.py \
	--script new_event.txt \
	--table simple.tbl \
	--validate \
	--report new_event_report.md

# Step 3: Check for errors
cat new_event_report.md

# Step 4: Insert into ROM
# (Use ROM patching tool)
```

### Workflow 4: Full ROM Text Audit

**Goal**: Verify all text in ROM uses correct encoding.

```bash
# Step 1: Validate character tables
python tools/analysis/character_encoding_verifier.py \
	--simple simple.tbl \
	--complex complex.tbl \
	--rom ffmq.sfc

# Step 2: Fix any issues found
# Edit .tbl files based on report

# Step 3: Re-verify
python tools/analysis/character_encoding_verifier.py \
	--simple simple.tbl \
	--complex complex.tbl \
	--rom ffmq.sfc

# Step 4: Decompile all dialogs
# (Use script offset list from ROM map)
python tools/rom_hacking/event_script_decompiler.py \
	--rom ffmq.sfc \
	--table simple.tbl \
	--offsets $(cat script_offsets.txt)
```

---

## Best Practices

### Script Writing

1. **Always use comments** - Document purpose of each section
2. **Validate parameters** - Use correct types and ranges
3. **Test incrementally** - Compile and test small sections first
4. **End with [END]** - Always close dialogs properly
5. **Use descriptive names** - Name variables and constants clearly

### Parameter Values

```
✅ GOOD:
[MEMORY_WRITE:0x1A50:0x0001]	; Set quest_flag_5 = true
[INSERT_ITEM:0x00]	; Insert "Cure Potion"

❌ BAD:
[MEMORY_WRITE:6736:1]	; What flag is this?
[INSERT_ITEM:0]	; Which item?
```

### Control Flow

```
✅ GOOD:
; Main dialog
[DIALOG 0]
Welcome!
[CALL_SUBROUTINE:0x9000]	; -> Common greeting
[END]

; Common greeting subroutine
[DIALOG 1]
How are you today?
[WAIT]
[END]

❌ BAD:
[DIALOG 0]
Welcome!
[CALL_SUBROUTINE:0xFFFF]	; Invalid pointer!
; Missing [END]
```

### Validation Workflow

1. **Compile with validation**:
   ```bash
   python enhanced_dialog_compiler.py --validate --report report.md
   ```

2. **Check report for errors**:
   ```bash
   grep "ERROR" report.md
   ```

3. **Fix errors** and recompile

4. **Verify in emulator** before final ROM release

### File Organization

```
project/
├── scripts/
│   ├── dialogs/
│   │   ├── intro.txt
│   │   ├── town_npcs.txt
│   │   └── boss_events.txt
│   └── common/
│       └── subroutines.txt
├── compiled/
│   ├── intro.bin
│   └── town_npcs.bin
└── reports/
    ├── compilation_report.md
    └── validation_report.md
```

---

## Troubleshooting

### Common Errors

**Error: "Character not in encoding table"**
- **Cause**: Using character not defined in .tbl file
- **Solution**: Add character to simple.tbl or use different character

**Error: "Parameter value out of range"**
- **Cause**: Parameter value exceeds allowed range
- **Solution**: Check PARAM_TYPES in enhanced_dialog_compiler.py

**Error: "Dialog not closed with [END]"**
- **Cause**: Missing [END] command
- **Solution**: Add [END] at end of each dialog block

**Error: "Invalid command syntax"**
- **Cause**: Malformed command line
- **Solution**: Use format `[COMMAND:param1:param2]`

### Getting Help

1. **Check documentation**: `docs/EVENT_SYSTEM_ARCHITECTURE.md`
2. **Review examples**: `docs/PARAMETER_ANALYSIS_REPORT.md`
3. **Read error messages** carefully - they include line numbers
4. **Use validation reports** to identify issues
5. **Test in emulator** with save states

---

## Advanced Topics

### Custom Parameter Types

Add new parameter types to enhanced_dialog_compiler.py:

```python
PARAM_TYPES = {
	# ... existing types ...
	'my_custom_type': (0, 100),	# Range 0-100
}
```

### Item/Spell Name Mapping

Add item names to event_script_decompiler.py:

```python
ITEM_NAMES = {
	0x00: "Cure Potion",
	0x01: "Heal Potion",
	# ... add more items ...
}
```

### Batch Processing

Compile multiple scripts:

```bash
for script in scripts/*.txt; do
	python enhanced_dialog_compiler.py \
		--script "$script" \
		--table simple.tbl \
		--output "compiled/$(basename "$script" .txt).bin"
done
```

---

## Tool Comparison Matrix

| Feature | Parameter Analyzer | Encoding Verifier | Enhanced Compiler | Script Decompiler |
|---------|-------------------|-------------------|-------------------|-------------------|
| **Input** | JSON/CSV statistics | .tbl files + ROM | .txt script | ROM data |
| **Output** | Analysis + hypotheses | Validation report | .bin ROM data | .txt script |
| **Validation** | Pattern detection | Round-trip tests | Full parameter validation | Type detection |
| **Use Case** | Research unknown commands | Verify encoding | Modify dialogs | Extract existing scripts |
| **Difficulty** | Intermediate | Beginner | Intermediate | Beginner |

---

## Performance Notes

### Tool Performance

- **Parameter Analyzer**: ~10 seconds for 10,000 commands
- **Encoding Verifier**: <1 second for 512-entry table
- **Enhanced Compiler**: ~5 seconds for 100 dialogs
- **Script Decompiler**: ~3 seconds for 50 scripts

### Optimization Tips

1. **Use specific offsets** - Don't decompile entire ROM
2. **Cache analysis results** - Reuse JSON/CSV outputs
3. **Batch compile** - Process multiple scripts at once
4. **Validate once** - Don't re-validate unchanged tables

---

## References

- **EVENT_SYSTEM_ARCHITECTURE.md** - Complete command reference
- **CONTROL_CODE_IDENTIFICATION.md** - Control code details
- **CREATE_GITHUB_ISSUES.md** - Manual testing procedures
- **DATA_EXTRACTION_PLAN.md** - Comprehensive extraction strategy

---

**Last Updated**: 2025-11-12  
**Author**: TheAnsarya  
**Version**: 1.0.0
