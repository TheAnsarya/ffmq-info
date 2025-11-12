# ROM Hacking Tools

This directory contains tools for compiling and decompiling FFMQ dialog/event scripts.

## Tools Overview

### **enhanced_dialog_compiler.py** - Enhanced Dialog/Event Script Compiler ⚡ NEW
**STATUS**: ✅ Production-ready  
**LINES**: 620 (with TABS formatting)  
**DOCUMENTATION**: See `docs/ROM_HACKING_TOOLCHAIN_GUIDE.md`

**Purpose**: Compile human-readable dialog/event scripts to ROM format with full validation for all 48 event commands.

**Key Features**:
- **Full Command Support** - All 48 event commands (0x00-0x2F)
- **Parameter Validation** - Type checking and range validation for all parameters
- **Control Flow Checking** - Validates branching logic, subroutine calls, loops
- **Memory Safety** - Validates memory addresses and pointer ranges
- **Debugging** - Detailed error messages with line numbers and context
- **Optimization** - Auto-generates subroutine calls for repeated text

**Quick Start**:
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

| Category | Commands | Count |
|----------|----------|-------|
| **Basic Operations** | END, NEWLINE, WAIT, ASTERISK, NAME, ITEM, SPACE | 7 |
| **Complex Operations** | UNK_07, CALL_SUBROUTINE, UNK_09-UNK_0F, MEMORY_WRITE | 9 |
| **Dynamic Insertion** | INSERT_ITEM, INSERT_SPELL, INSERT_MONSTER, INSERT_CHARACTER, INSERT_LOCATION, INSERT_NUMBER, INSERT_OBJECT, INSERT_WEAPON, INSERT_ARMOR, INSERT_ACCESSORY | 10 |
| **Formatting** | TEXTBOX_BELOW, TEXTBOX_ABOVE, UNK_1C, FORMAT_ITEM_E1, FORMAT_ITEM_E2, CRYSTAL | 6 |
| **State Control** | UNK_20-UNK_22, EXTERNAL_CALL_1-3, SET_STATE_VAR, SET_STATE_BYTE, SET_STATE_WORD, SET_STATE_BYTE_2-3, UNK_2A, UNK_2C, SET_STATE_WORD_2, UNK_2E, UNK_2F | 16 |

**Parameter Types**:
- `byte` - 0-255
- `item_id` - 0-255
- `spell_id` - 0-63
- `monster_id` - 0-255
- `character_id` - 0-4 (Benjamin, Kaeli, Tristam, Phoebe, Reuben)
- `location_id` - 0-63
- `mode` - 0-10
- `crystal_id` - 0-4 (Wind, Fire, Water, Earth)
- `address` - 0x0000-0xFFFF (16-bit memory address)
- `value` - 0x0000-0xFFFF (16-bit value)
- `pointer` - 0x8000-0xFFFF (ROM pointer)

**Error Reporting**:
```
Line 15: Command MEMORY_WRITE expects 4 parameters, got 2
Line 23: Parameter value 300 (0x012C) out of range for spell_id (0-63)
Line 42: Dialog 5 not closed with [END]
```

**Use Cases**:
- Modify existing dialog text
- Create new event sequences
- Translate game text
- Add custom quest events
- ROM hacking projects

---

### **event_script_decompiler.py** - Event Script Decompiler ⚡ NEW
**STATUS**: ✅ Production-ready  
**LINES**: 760 (with TABS formatting)  
**DOCUMENTATION**: See `docs/ROM_HACKING_TOOLCHAIN_GUIDE.md`

**Purpose**: Decompile ROM event scripts to human-readable format (reverse operation of compiler).

**Key Features**:
- **Full Command Recognition** - All 48 event commands (0x00-0x2F)
- **Parameter Type Detection** - Auto-detects parameter types (addresses, items, spells, etc.)
- **Control Flow Analysis** - Maps subroutine calls and branches
- **Memory Operation Detection** - Identifies memory writes and flag operations
- **Text Extraction** - Decodes dialog text with proper formatting
- **Annotation** - Adds helpful comments explaining command purposes

**Quick Start**:
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

**Automatic Annotations**:
- Item names (e.g., "Item: Cure Potion")
- Spell names (e.g., "Spell: Fire")
- Character names (e.g., "Character: Benjamin")
- Monster names (e.g., "Monster: Behemoth")
- Memory operations (e.g., "Set memory $1A50 = 0x0001")
- Subroutine targets (e.g., "-> Subroutine at 0x9120")

**Report Sections**:
1. **Summary** - Scripts, commands, total size
2. **Command Usage Statistics** - Frequency of each command
3. **Subroutine Call Graph** - Which scripts call which
4. **Memory Operations** - All memory writes across scripts

**Use Cases**:
- Extract existing dialog text for translation
- Understand event script structure
- Analyze game quest flow
- Create event script database
- Reverse engineer event system

---

## Workflow Examples

### Example 1: Modify Existing Dialog

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
```

### Example 2: Create New Event

```bash
# Step 1: Write script
cat > new_event.txt << 'EOF'
[DIALOG 100]
@TEXTBOX_BOTTOM

You found a mysterious crystal!
[NEWLINE]
[WAIT]

[INSERT_ITEM:0x42]	; Cure Potion
[NEWLINE]
[WAIT]

[MEMORY_WRITE:0x1C00:0x0001]	; Set quest flag
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
```

### Example 3: Batch Decompilation

```bash
# Decompile multiple scripts
python tools/rom_hacking/event_script_decompiler.py \
	--rom ffmq.sfc \
	--table simple.tbl \
	--offsets 0x8FA0,0x9000,0x9100,0x9200,0x9300 \
	--output all_dialogs.txt \
	--report decompilation_report.md
```

---

## Parameter Reference

### Memory Addresses (MEMORY_WRITE command)

Common memory regions:
- `0x1A00-0x1AFF` - Quest flags
- `0x1B00-0x1BFF` - Character stats
- `0x1C00-0x1CFF` - Item inventory
- `0x1D00-0x1DFF` - Game state

### ROM Pointers (CALL_SUBROUTINE command)

Pointer format:
- **0x8000-0xFFFF** - Bank-relative ROM address
- **Bank byte** - Not included in 16-bit pointer (determined by context)

### Item IDs (INSERT_ITEM command)

Sample item IDs:
- `0x00` - Cure Potion
- `0x01` - Heal Potion
- `0x02` - Seed
- `0x03` - Elixir
- `0x04` - Refresher

### Spell IDs (INSERT_SPELL command)

Sample spell IDs:
- `0x00` - Cure
- `0x01` - Fire
- `0x02` - Blizzard
- `0x03` - Thunder
- `0x04` - Aero

### Character IDs (INSERT_CHARACTER command)

- `0x00` - Benjamin
- `0x01` - Kaeli
- `0x02` - Tristam
- `0x03` - Phoebe
- `0x04` - Reuben

### Crystal IDs (CRYSTAL command)

- `0x00` - Wind Crystal
- `0x01` - Fire Crystal
- `0x02` - Water Crystal
- `0x03` - Earth Crystal

---

## Best Practices

### Script Writing

1. **Use comments** - Document purpose of each section
2. **Validate parameters** - Use correct types and ranges
3. **Test incrementally** - Compile small sections first
4. **End with [END]** - Always close dialogs properly

### Good Script Example

```
[DIALOG 0]
; Initialize quest event
@TEXTBOX_BOTTOM

; Greeting dialog
Welcome, brave warrior!
[NEWLINE]
[WAIT]

; Give item reward
[INSERT_ITEM:0x00]	; Cure Potion
You received a Cure Potion!
[NEWLINE]
[WAIT]

; Set quest completion flag
[MEMORY_WRITE:0x1A50:0x0001]	; quest_flag_5 = true

; Call common ending
[CALL_SUBROUTINE:0x9000]	; -> Quest complete message
[END]
```

### Bad Script Example

```
[DIALOG 0]
Welcome!
[NEWLINE]
[MEMORY_WRITE:6736:1]	; What flag is this?
[CALL_SUBROUTINE:0xFFFF]	; Invalid pointer!
; Missing [END]
```

---

## Troubleshooting

### Common Errors

**"Character not in encoding table"**
- Add character to simple.tbl

**"Parameter value out of range"**
- Check parameter type ranges

**"Dialog not closed with [END]"**
- Add [END] at end of dialog

**"Invalid command syntax"**
- Use format: `[COMMAND:param1:param2]`

---

## References

- **ROM_HACKING_TOOLCHAIN_GUIDE.md** - Complete workflow guide
- **EVENT_SYSTEM_ARCHITECTURE.md** - Event system design
- **CONTROL_CODE_IDENTIFICATION.md** - Control code details

---

**Last Updated**: 2025-11-12  
**Author**: TheAnsarya  
**Version**: 1.0.0
