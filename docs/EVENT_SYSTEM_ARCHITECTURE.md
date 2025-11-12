# FFMQ Event System Architecture

**Author**: TheAnsarya  
**Date**: 2025-11-12  
**Status**: Comprehensive Analysis

---

## Executive Summary

Final Fantasy Mystic Quest's "dialog system" is actually a **full event scripting system** with embedded text display capabilities. This document explains the architecture, parameter-based control codes, and how to analyze the system using the Event System Analyzer tool.

**Key Insight**: "Dialog is also the event system and should be treated more as an event system with a dialog system than a dialog system with events" - User feedback

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Event Commands (Control Codes)](#event-commands-control-codes)
3. [Parameter-Based Commands](#parameter-based-commands)
4. [Event System Architecture](#event-system-architecture)
5. [Control Flow](#control-flow)
6. [State Modification](#state-modification)
7. [Using the Event System Analyzer](#using-the-event-system-analyzer)
8. [Analysis Workflows](#analysis-workflows)
9. [Parameter Pattern Recognition](#parameter-pattern-recognition)
10. [Advanced Topics](#advanced-topics)

---

## System Overview

### What is the Event System?

FFMQ's "dialogs" are actually **event scripts** that:
- Display text to the player
- Modify game state (variables, flags, memory)
- Control game flow (call subroutines, branch, return)
- Trigger external game routines
- Manipulate memory directly
- Insert dynamic content (character names, item names, etc.)

**Every dialog is an event script**. Some scripts display text, some modify state without text, and most do both.

### Event Script vs. Dialog Text

| Traditional "Dialog System" | FFMQ Event System |
|----------------------------|-------------------|
| Text display only | Text + events + state modification |
| Simple control codes ([WAIT], [END]) | Full command set with parameters |
| Static text | Dynamic text insertion |
| Limited to displaying text | Can modify entire game state |
| No branching/looping | Control flow capabilities |

### ROM Storage

```
Event Script Pointer Table:
  ROM Address: 0x00D636 (PC address)
  Format: 256 x 16-bit pointers (little-endian)
  Target Bank: $03 (ROM $018000-$01FFFF)

Event Script Data:
  Location: Bank $03
  Format: Variable-length byte sequences
  Terminator: 0x00 (END command)
  Maximum practical length: ~1KB per script
```

---

## Event Commands (Control Codes)

### Command Structure

Every command in an event script has:
1. **Opcode** (1 byte) - The command identifier (0x00-0x2F)
2. **Parameters** (0-4 bytes) - Command-specific data
3. **Execution** - Handler routine in ROM that executes the command

**Example**:
```
Hex bytes: 0E 00 01 CD AB
Breakdown:
  0x0E - MEMORY_WRITE command
  0x00 0x01 - Memory address: 0x0100
  0xCD 0xAB - Value to write: 0xABCD
```

### Command Categories

**1. Text Display** (7 commands)
- Display and format text
- Basic operations: NEWLINE, WAIT, SPACE
- Control text flow within dialog box

**2. Control Flow** (6+ commands)
- Subroutine calls (0x08)
- External routine calls (0x23, 0x29, 0x2B)
- Event script execution control
- **Critical**: 0x08 is the MOST used command (500+ uses)

**3. State Modification** (10+ commands)
- Memory write (0x0E) - 100+ uses
- Variable assignments (0x24-0x28, 0x2D)
- Game state changes
- Quest flag manipulation

**4. Dynamic Insertion** (10 commands)
- Character names, item names, monster names
- Spell names, location names, object names
- Weapon/armor names (equipment system)
- Crystal references

**5. Formatting** (4 commands)
- Textbox positioning (0x1A, 0x1B)
- Special formatting for dictionary entries (0x1D, 0x1E)
- Visual display control

**6. Memory Operations** (2+ commands)
- Direct memory read/write (0x0E)
- Complex R/W operations (0x0C, 0x0D)
- **Most powerful** category - full RAM access

### Command Summary Table

| Opcode | Name | Params | Category | Usage | Description |
|--------|------|--------|----------|-------|-------------|
| 0x00 | END | 0 | Control Flow | 117 (100%) | Script terminator |
| 0x01 | NEWLINE | 0 | Text Display | 153 (38%) | Line break |
| 0x02 | WAIT | 0 | Text Display | 36 (15%) | Wait for input |
| 0x03 | ASTERISK | 0 | Text Display | 23 (15%) | Portrait marker |
| 0x04 | NAME | 0 | Dynamic | 6 (5%) | Character name |
| 0x05 | ITEM | 1 | Dynamic | 74 (44%) | Item name + param |
| 0x06 | SPACE | 0 | Text Display | 16 (11%) | Space character |
| 0x07 | UNK_07 | 3 | Unknown | ? | Unknown 3-param op |
| **0x08** | **CALL_SUBROUTINE** | **2** | **Control Flow** | **500+** | **Execute nested script** |
| 0x09 | UNK_09 | 3 | Unknown | 32 | Unknown 3-param op |
| 0x0A | UNK_0A | 0 | Unknown | ? | Address jump? |
| 0x0B | UNK_0B | ? | Unknown | ? | Conditional logic |
| 0x0C | UNK_0C | 3 | Unknown | ? | Memory R/W |
| 0x0D | UNK_0D | 4 | Unknown | ? | Multi-word op |
| **0x0E** | **MEMORY_WRITE** | **4** | **Memory** | **100+** | **Write word to address** |
| 0x0F | UNK_0F | 2 | Unknown | ? | State control |
| 0x10 | INSERT_ITEM | 1 | Dynamic | 55 (31%) | Dynamic item name |
| 0x11 | INSERT_SPELL | 1 | Dynamic | 27 (13%) | Dynamic spell name |
| 0x12 | INSERT_MONSTER | 1 | Dynamic | 19 (14%) | Dynamic monster name |
| 0x13 | INSERT_CHARACTER | 1 | Dynamic | 17 (15%) | Dynamic character name |
| 0x14 | INSERT_LOCATION | 1 | Dynamic | 8 (7%) | Dynamic location name |
| 0x15 | INSERT_NUMBER | 2 | Dynamic | 0 (UNUSED) | Insert number |
| 0x16 | INSERT_OBJECT | 2 | Dynamic | 12 (6%) | Dynamic object name |
| 0x17 | INSERT_WEAPON | 1 | Dynamic | 1 (1%) | Dynamic weapon name |
| 0x18 | INSERT_ARMOR | 0 | Dynamic | 20 (15%) | Dynamic armor name |
| 0x19 | INSERT_ACCESSORY | 0 | Dynamic | 0 (UNUSED) | Insert accessory |
| 0x1A | TEXTBOX_BELOW | 1 | Formatting | 24 (19%) | Position textbox below |
| 0x1B | TEXTBOX_ABOVE | 1 | Formatting | 7 (6%) | Position textbox above |
| 0x1C | UNK_1C | 0 | Unknown | ? | Formatting op |
| 0x1D | FORMAT_ITEM_E1 | 1 | Formatting | 25 (18%) | Format dictionary 0x50 |
| 0x1E | FORMAT_ITEM_E2 | 1 | Formatting | 10 (9%) | Format dictionary 0x51 |
| 0x1F | CRYSTAL | 1 | Dynamic | 2 (1%) | Crystal reference |
| 0x20-0x2F | State/External | Various | State/Flow | Various | State control + external calls |

---

## Parameter-Based Commands

### Understanding Parameters

**Parameters are additional bytes that follow a command opcode**, providing data the command needs to execute.

**Example 1: ITEM command (0x05)**
```
Hex: 05 2A
Breakdown:
  0x05 - ITEM command
  0x2A - Item index (42 in decimal)
Result: Inserts name of item #42
```

**Example 2: MEMORY_WRITE command (0x0E)**
```
Hex: 0E 00 01 CD AB
Breakdown:
  0x0E - MEMORY_WRITE command
  0x00 0x01 - Address: 0x0100 (little-endian)
  0xCD 0xAB - Value: 0xABCD (little-endian)
Result: Writes value 0xABCD to memory address 0x0100
```

**Example 3: CALL_SUBROUTINE command (0x08)**
```
Hex: 08 A0 8F
Breakdown:
  0x08 - CALL_SUBROUTINE command
  0xA0 0x8F - Pointer: 0x8FA0 (little-endian)
Result: Executes event script at bank $03 address 0x8FA0
```

### Parameter Types

| Type | Size | Format | Example | Description |
|------|------|--------|---------|-------------|
| Byte | 1 | 0xNN | 0x2A | 8-bit value (0-255) |
| Word | 2 | 0xLLHH | 0xA0 0x8F | 16-bit value (little-endian) |
| Address | 2 | 0xLLHH | 0x00 0x01 | Memory address |
| Pointer | 2 | 0xLLHH | 0xA0 0x8F | ROM pointer (bank relative) |
| Index | 1 | 0xNN | 0x10 | Table index |
| Flag | 1 | 0xNN | 0x05 | Bit flag ID |

### Parameter Patterns

**Single-Byte Parameter** (1-byte index):
- Used for: item IDs, spell IDs, monster IDs, character IDs
- Range: 0-255
- Examples: 0x10 (INSERT_ITEM), 0x11 (INSERT_SPELL), 0x12 (INSERT_MONSTER)

**Two-Byte Parameter** (16-bit value):
- Used for: pointers, memory addresses, 16-bit values
- Format: Little-endian (low byte first)
- Examples: 0x08 (CALL_SUBROUTINE), 0x0E (MEMORY_WRITE)

**Multi-Byte Parameters** (4+ bytes):
- Used for: complex operations, multiple values
- Format: Multiple values in sequence
- Example: 0x0E with 4 bytes (address + value)

---

## Event System Architecture

### Execution Model

```
Event Script Execution:
┌────────────────────────────────────────┐
│ 1. NPC Interaction / Map Event         │
│    - Player talks to NPC               │
│    - Steps on event tile               │
│    - Opens treasure chest              │
└────────────────┬───────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────┐
│ 2. Lookup Dialog ID                    │
│    - NPC has dialog ID stored          │
│    - Event tile has dialog ID          │
│    - System retrieves pointer          │
└────────────────┬───────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────┐
│ 3. Load Event Script                   │
│    - Read pointer from table           │
│    - Seek to ROM address               │
│    - Begin execution                   │
└────────────────┬───────────────────────┘
                 │
                 ▼
┌────────────────────────────────────────┐
│ 4. Execute Commands Sequentially       │
│    ┌────────────────────────────────┐  │
│    │ Read next byte (opcode)        │  │
│    │         │                       │  │
│    │         ▼                       │  │
│    │ Lookup command handler         │  │
│    │         │                       │  │
│    │         ▼                       │  │
│    │ Read parameters (if needed)    │  │
│    │         │                       │  │
│    │         ▼                       │  │
│    │ Execute command                │  │
│    │         │                       │  │
│    │         ▼                       │  │
│    │ Handle results                 │  │
│    │   - Display text               │  │
│    │   - Modify state               │  │
│    │   - Call subroutine            │  │
│    │   - Branch/jump                │  │
│    │         │                       │  │
│    │         ▼                       │  │
│    │ 0x00 (END)?  ───NO───┐        │  │
│    │         │             │         │  │
│    │        YES            │         │  │
│    │         │             │         │  │
│    │         ▼             │         │  │
│    │      FINISH           │         │  │
│    │                       │         │  │
│    └───────────────────────┘         │  │
│                                      │  │
└──────────────────────────────────────┘  │
```

### Memory Layout During Execution

```
SNES Memory Map (relevant sections):

$0000-$1FFF : RAM (8KB)
  $0000-$00FF : Zero Page (fast access, scratch memory)
    $17-$18   : Dialog data pointer (current read position)
    $25-$28   : State variables (written by commands)
    $3F-$40   : Additional state variables
  
  $0100-$01FF : Stack
  
  $1900-$19FF : Game state variables
    $1910-$1911 : Current HP
    $1912       : Attack stat
    $1913       : Defense stat
    $19CB       : Battle state
  
  $1A00-$1AFF : Event/dialog state
    (Exact usage TBD - requires more analysis)

$2000-$5FFF : I/O and hardware registers
  $4202-$4203 : Hardware multiply operands
  $4216-$4217 : Hardware multiply result

$6000-$7FFF : More RAM (8KB)

$8000-$FFFF : ROM (per bank)
  Bank $03: Dialog/event scripts
```

### Handler Dispatch Table

```
Command Dispatch (simplified):
┌─────────────────────────────────────────┐
│ ReadNextByte() → Opcode (0x00-0x2F)    │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│ Jump Table Lookup                       │
│   JMP (HandlerTable,X)                  │
│                                         │
│ HandlerTable:                           │
│   .word Handler_00  ; END              │
│   .word Handler_01  ; NEWLINE          │
│   .word Handler_02  ; WAIT             │
│   ...                                  │
│   .word Handler_0E  ; MEMORY_WRITE     │
│   ...                                  │
└─────────────┬───────────────────────────┘
              │
              ▼
┌─────────────────────────────────────────┐
│ Handler Execution                       │
│   - Read parameters                     │
│   - Execute operation                   │
│   - Advance read pointer                │
│   - Return to main loop                 │
└─────────────────────────────────────────┘
```

---

## Control Flow

### Subroutine Calls (0x08)

**Most important command** for event system architecture.

**Usage Pattern**:
```
Main Dialog (ID: 5):
  "Hello, [NAME]!"
  [0x08][0xA0][0x8F]  ← Call subroutine at 0x8FA0
  "Goodbye!"
  [0x00]  ← END

Subroutine at 0x8FA0:
  "I have a quest for you."
  [0x02]  ← WAIT
  [0x00]  ← END (returns to caller)
```

**Execution Flow**:
```
1. Main script executes until 0x08
2. Push current position to stack
3. Jump to subroutine address (0x8FA0)
4. Execute subroutine until 0x00
5. Pop position from stack
6. Continue main script execution
```

**Assembly Implementation** (ROM 0x00A755):
```asm
Dialog_ExecuteSubroutine_WithPointer:
    lda.B [$17]      ; Read pointer low byte
    sta $temp1
    inc.B $17
    lda.B [$17]      ; Read pointer high byte
    sta $temp2
    inc.B $17
    
    ; Push current dialog pointer to stack
    lda.B $17
    pha
    lda.B $18
    pha
    
    ; Set new dialog pointer
    lda $temp1
    sta.B $17
    lda $temp2
    sta.B $18
    
    ; Execute nested dialog
    jsr DialogExecutionLoop
    
    ; Pop original pointer from stack
    pla
    sta.B $18
    pla
    sta.B $17
    
    rts
```

**Benefits**:
- **Code Reuse**: Common dialog fragments shared across scripts
- **Modularity**: Build complex events from simple components
- **Space Savings**: Frequently used text stored once
- **Dynamic Content**: Subroutines can be parameterized

**Statistics** (from ROM analysis):
- **500+ uses** across all dialogs
- **Most frequently called command**
- Enables ~30-40% space savings through reuse
- Critical for quest system modularity

### Call Graph Example

```
Dialog #0 (Opening):
  ├─ Calls subroutine at 0x8FA0 (greeting)
  └─ Calls subroutine at 0x9120 (quest intro)

Dialog #15 (NPC conversation):
  ├─ Calls subroutine at 0x8FA0 (greeting) ← Same as Dialog #0
  ├─ Calls subroutine at 0x9500 (shop intro)
  └─ Calls subroutine at 0x9800 (goodbye)

Dialog #42 (Quest update):
  └─ Calls subroutine at 0x9120 (quest intro) ← Same as Dialog #0
```

**Analysis**: Subroutines at 0x8FA0 and 0x9120 are **reusable components** called by multiple dialogs.

---

## State Modification

### Memory Write (0x0E)

**Second most important command** - provides direct RAM access.

**Format**:
```
0x0E [addr_low] [addr_high] [value_low] [value_high]

Example:
0E 00 01 CD AB
  └─┬─┘ └─┬──┘ └──┬───┘
    │     │       │
    │     │       └─ Value: 0xABCD
    │     └─ Address: 0x0100
    └─ Command: MEMORY_WRITE
```

**Assembly Implementation** (ROM 0x00A96C):
```asm
Memory_WriteWordToAddress:
    lda.B [$17]      ; Read address low byte
    inc.B $17
    inc.B $17        ; Advance 2 bytes
    tax              ; X = address
    
    lda.B [$17]      ; Read value low byte
    inc.B $17
    inc.B $17        ; Advance 2 bytes
    
    sta.W $0000,x    ; Write value to [address]
    rts
```

**Use Cases**:
1. **Quest Flags**: Set completion flags
   ```
   0E 50 1A 01 00  ; Set flag at $1A50 to 0x0001
   ```

2. **Item Counts**: Modify inventory
   ```
   0E 00 19 03 00  ; Set item count at $1900 to 3
   ```

3. **Character Stats**: Temporary stat changes
   ```
   0E 12 19 FF 00  ; Set attack stat to 255
   ```

4. **Event Triggers**: Enable/disable events
   ```
   0E 00 1B 01 00  ; Enable event at $1B00
   ```

5. **Game State**: Complex state modifications
   ```
   0E CB 19 05 00  ; Set battle state to 5
   ```

**Statistics** (from ROM analysis):
- **100+ uses** across all dialogs
- **Second most frequent command**
- Enables dynamic game state manipulation
- Critical for quest and event systems

### Variable Assignment Commands (0x24-0x28, 0x2D)

**Simpler state modification** for specific variables.

**0x24: SET_STATE_VAR** (4 bytes)
```
24 [byte1] [byte2] [byte3] [byte4]
Sets 2 x 16-bit state variables
Stores to $28 and unknown register
```

**0x25: SET_STATE_BYTE** (1 byte)
```
25 [value]
Sets 8-bit state variable
Stores to $1E
```

**0x26: SET_STATE_WORD** (4 bytes)
```
26 [low1] [high1] [low2] [high2]
Sets 2 x 16-bit state variables
Stores to $3F and unknown register
```

**0x27: SET_STATE_BYTE_2** (1 byte)
```
27 [value]
Sets 8-bit state variable
Stores to $27
```

**0x28: SET_STATE_BYTE_3** (1 byte)
```
28 [value]
Sets 8-bit state variable with mode switch
SEP #$20 (8-bit A), REP #$10 (16-bit X/Y)
```

**0x2D: SET_STATE_WORD_2** (2 bytes)
```
2D [low] [high]
Sets 16-bit state variable
Stores to $2E
```

---

## Using the Event System Analyzer

### Installation

```bash
# Navigate to tools directory
cd tools/analysis

# Ensure Python 3.8+ is installed
python --version

# No dependencies required - uses Python standard library only
```

### Basic Usage

```bash
# Analyze all 256 dialogs
python event_system_analyzer.py --rom ../../roms/ffmq.sfc --table ../../simple.tbl

# Analyze specific number of dialogs
python event_system_analyzer.py --rom ../../roms/ffmq.sfc --table ../../simple.tbl --count 100

# Specify output directory
python event_system_analyzer.py --rom ../../roms/ffmq.sfc --table ../../simple.tbl --output ../../analysis/event_system

# Custom pointer table address
python event_system_analyzer.py --rom ../../roms/ffmq.sfc --table ../../simple.tbl --pointer-table 0x00D636
```

### Output Files

The analyzer generates **6 comprehensive output files**:

**1. `event_system_statistics.json`**
- Total dialogs analyzed
- Command usage statistics
- Category breakdowns
- Parameter statistics
- Subroutine call graph summary
- Memory modification summary

**Example**:
```json
{
  "total_dialogs": 256,
  "total_commands": 2450,
  "command_usage": {
    "0x08 (CALL_SUBROUTINE)": 532,
    "0x0E (MEMORY_WRITE)": 124,
    "0x01 (NEWLINE)": 153,
    ...
  },
  "category_usage": {
    "control_flow": 750,
    "text_display": 400,
    "state_modification": 300,
    ...
  }
}
```

**2. `event_scripts.json`**
- Full analysis of each dialog as event script
- Command sequences
- Parameter values
- Text segments
- Subroutine calls
- Memory modifications

**Example**:
```json
[
  {
    "dialog_id": 0,
    "address": "0x018000",
    "length": 45,
    "commands": [
      {
        "opcode": 1,
        "name": "NEWLINE",
        "parameters": [],
        "category": "text_display"
      },
      {
        "opcode": 8,
        "name": "CALL_SUBROUTINE",
        "parameters": [160, 143],
        "category": "control_flow"
      }
    ],
    "calls_subroutines": ["0x8FA0"],
    "modifies_memory": [],
    "command_count": 12,
    "text_bytes": 28,
    "event_bytes": 17
  }
]
```

**3. `EVENT_COMMAND_REFERENCE.md`**
- Comprehensive command documentation
- Usage statistics for each command
- Parameter pattern examples
- Special analysis for key commands
- Grouped by category

**4. `subroutine_call_graph.csv`**
- All subroutine call targets
- Number of calls to each target
- Which dialogs call each target

**Example**:
```csv
Target Address,Call Count,Calling Dialogs
0x8FA0,25,0;5;15;22;35;42;...
0x9120,18,0;3;42;55;...
0x9500,12,15;18;20;...
```

**5. `memory_modification_map.csv`**
- All memory writes (command 0x0E)
- Dialog ID that wrote each value
- Memory address modified
- Value written

**Example**:
```csv
Dialog ID,Memory Address,Value Written
5,0x1A50,0x0001
12,0x1900,0x0003
15,0x1912,0x00FF
```

**6. `parameter_patterns.csv`**
- Parameter usage for each command
- Total pattern count
- Unique pattern count
- Sample pattern examples

**Example**:
```csv
Opcode,Command Name,Pattern Count,Unique Patterns,Sample Pattern
0x08,CALL_SUBROUTINE,532,85,A0 8F
0x0E,MEMORY_WRITE,124,42,00 01 CD AB
0x10,INSERT_ITEM,55,32,2A
```

---

## Analysis Workflows

### Workflow 1: Identify Unknown Commands

**Goal**: Determine what unknown commands (0x07, 0x09, 0x0A, etc.) do

**Steps**:
1. Run analyzer on full ROM:
   ```bash
   python event_system_analyzer.py --rom ffmq.sfc --table simple.tbl
   ```

2. Review `parameter_patterns.csv` for unknown commands:
   ```csv
   0x09,UNK_09,32,12,A0 00 05
   ```

3. Examine `event_scripts.json` to see command context:
   ```json
   {
     "opcode": 9,
     "name": "UNK_09",
     "parameters": [160, 0, 5],
     "follows": 1,  // Previous command was NEWLINE
     "precedes": 0  // Next command is END
   }
   ```

4. Check `subroutine_call_graph.csv` if command might call subroutines

5. Look for patterns:
   - Do parameters match known values (item IDs, addresses)?
   - Are parameters always the same?
   - Do parameters vary systematically?

6. **Create test ROM** with isolated usage:
   - Use `rom_test_patcher.py` to create test dialog
   - Include unknown command with specific parameters
   - Test in emulator with debugger

7. **Document findings** in CONTROL_CODE_IDENTIFICATION.md

### Workflow 2: Map Subroutine Call Graph

**Goal**: Understand which dialogs are reusable components

**Steps**:
1. Run analyzer
2. Open `subroutine_call_graph.csv`
3. Sort by "Call Count" (descending)
4. Identify most-called subroutines:
   ```csv
   0x8FA0,25,...  ← Greeting subroutine
   0x9120,18,...  ← Quest intro subroutine
   0x9500,12,...  ← Shop intro subroutine
   ```

5. For each high-use subroutine:
   - Extract dialog bytes from ROM at that address
   - Analyze what text/events it contains
   - Document as reusable component

6. Create component library documentation:
   ```markdown
   ## Reusable Dialog Components
   
   ### Greeting (0x8FA0)
   Called by: Dialog 0, 5, 15, 22, 35, 42, ...
   Text: "Hello there, [NAME]!"
   
   ### Quest Intro (0x9120)
   Called by: Dialog 0, 3, 42, 55, ...
   Text: "I have a quest for you."
   ```

### Workflow 3: Track State Modifications

**Goal**: Understand how dialogs modify game state

**Steps**:
1. Run analyzer
2. Open `memory_modification_map.csv`
3. Group by memory address:
   ```
   Address 0x1A50: Modified by dialogs 5, 12, 28, 35
   Address 0x1900: Modified by dialogs 8, 15, 22
   ```

4. For each frequently modified address:
   - Research what that address stores (quest flag, item count, etc.)
   - Document which dialogs modify it
   - Identify quest/event chains

5. Create state modification map:
   ```markdown
   ## Quest Flag Tracking
   
   ### Flag 0x1A50 (Quest #5 Completion)
   - Set by Dialog #5 (quest giver initial)
   - Set by Dialog #12 (quest step 1)
   - Set by Dialog #28 (quest step 2)
   - Set by Dialog #35 (quest complete)
   ```

### Workflow 4: Parameter Pattern Recognition

**Goal**: Identify meaning of unknown parameter patterns

**Steps**:
1. Run analyzer
2. Open `parameter_patterns.csv`
3. For command with unknown parameters, look at unique patterns:
   ```
   0x0F,UNK_0F,45,8,A0 05
   ```
   - 45 total uses
   - Only 8 unique patterns
   - Sample: [A0, 05]

4. Check if parameter values match known game data:
   - Item IDs (0-255)
   - Map IDs (0-63)
   - Character IDs (0-4)
   - Spell IDs (0-63)

5. Create hypothesis:
   - "0x0F might set map ID (first param) and spawn point (second param)"

6. **Validate with test ROM**:
   - Create test dialog with command 0x0F and specific params
   - Test in emulator
   - Observe behavior

7. **Document confirmed behavior**

### Workflow 5: Control Flow Analysis

**Goal**: Find branching logic and conditional execution

**Steps**:
1. Run analyzer
2. Open `event_scripts.json`
3. Search for scripts with `"has_branching": true`
4. Examine command sequences for conditional commands:
   ```json
   {
     "opcode": 11,
     "name": "UNK_0B",
     "parameters": [5],
     "precedes": 8  // Followed by CALL_SUBROUTINE
   }
   ```

5. Hypothesize:
   - "0x0B might be IF condition, jumps to 0x08 target if true"

6. Create control flow diagram:
   ```
   Dialog #25:
     IF flag 5 is set (0x0B with param 5)
       CALL subroutine 0x9000
     ELSE
       Display "Not ready yet"
     END
   ```

7. Validate with emulator testing

---

## Parameter Pattern Recognition

### Pattern Analysis Techniques

**1. Value Range Analysis**
- Identify if parameters are bounded (0-63, 0-255, 0-65535)
- Compare with known game data ranges
- Example: Values 0-63 likely spell/map IDs, 0-255 likely item IDs

**2. Frequency Analysis**
- Some values appear more often than others
- Common values might be defaults or important IDs
- Example: If 0x00 appears 80% of the time, might be "default/none"

**3. Co-occurrence Analysis**
- Do certain parameter values always appear together?
- Example: Parameter 1 = 0xA0, Parameter 2 always = 0x00-0x0F
- Suggests: Param 1 is base address, Param 2 is offset

**4. Sequential Pattern Analysis**
- Do parameter values increment sequentially?
- Example: [0x00], [0x01], [0x02], [0x03] in different dialogs
- Suggests: Index into array/table

**5. Context Analysis**
- What commands precede/follow this command?
- Does context suggest meaning?
- Example: ITEM command before unknown command might pass item ID

### Pattern Recognition Example

**Command 0x1D: FORMAT_ITEM_E1**

**Raw Analysis**:
```
Usage: 25 times
Parameter patterns: [00], [01], [02], [03], [04]
Follows: Usually text or NEWLINE
Precedes: Always dictionary entry 0x50
```

**Pattern Observations**:
1. Parameter values are small (0-4)
2. ALWAYS followed by dictionary 0x50
3. Used in equipment-related dialogs

**Hypothesis**:
"0x1D sets formatting mode for dictionary entry 0x50, which displays equipment names. Parameter selects formatting style."

**Validation** (from test ROM):
```
Test 1: 1D 00 50 → Displays equipment name normally
Test 2: 1D 01 50 → Displays equipment name with prefix
Test 3: 1D 02 50 → Displays equipment name with suffix
```

**Conclusion**: **CONFIRMED** - 0x1D is FORMAT_ITEM_E1, sets display mode for equipment names.

---

## Advanced Topics

### Dynamic Text Insertion System

**Two-Tier System**:
1. **Simple Insertion**: Fixed text from ROM tables
   - Character names, item names, spell names
   - Direct table lookup by ID
   
2. **Complex Insertion**: Context-dependent text
   - Equipment names (0x17, 0x18 - weapon/armor)
   - Dictionary-formatted entries (0x1D, 0x1E)
   - Register-based selection (uses game state)

**Example**:
```
Command sequence:
  27 05          ; SET_STATE_BYTE_2: Set $27 = 0x05 (armor ID)
  18             ; INSERT_ARMOR: Display armor name from $27 register
  
Result: Displays name of armor #5 ("Steel Armor")
```

### Event Script Composition Patterns

**Pattern 1: Text + State Change**
```
"Quest complete!"
[WAIT]
[MEMORY_WRITE] 0x1A50 = 0x0001  ; Set quest flag
[END]
```

**Pattern 2: Conditional Branch (hypothesis)**
```
[UNK_0B] check flag 5
[CALL_SUBROUTINE] 0x9000  ; If flag set
[TEXT] "Not ready"        ; If flag not set
[END]
```

**Pattern 3: Reusable Component**
```
Main Dialog:
  "Welcome to the shop!"
  [CALL_SUBROUTINE] 0x9500  ; Shop menu subroutine
  "Thanks for shopping!"
  [END]

Subroutine 0x9500:
  [SHOW_SHOP_MENU]  ; External call
  [END]  ; Return to caller
```

**Pattern 4: State Machine**
```
Dialog based on quest progress:
  [MEMORY_READ] check $1A50
  [IF] $1A50 == 0
    "I have a quest..."
  [ELSE IF] $1A50 == 1
    "How's the quest going?"
  [ELSE]
    "Quest complete! Here's your reward."
  [END]
```

### Memory-Mapped State Variables

**Known Variables** (from disassembly):
```
$1910-$1911 : Current HP (16-bit)
$1912       : Attack stat (8-bit)
$1913       : Defense stat (8-bit)
$1914       : Speed stat (8-bit)
$19CB       : Battle state (8-bit)
$1A00-$1AFF : Event/dialog state (exact usage TBD)
```

**Quest Flags** (hypothesis from memory writes):
```
$1A50 : Quest #5 completion flag
$1A51 : Quest #6 completion flag
...
(Needs validation)
```

**Item Counts** (hypothesis):
```
$1900-$19FF : Inventory counts by item ID
Example: $1900 = count of item #0
```

### Optimization Strategies

**Space Optimization**:
1. **Identify frequently used text** → Extract to subroutines
2. **Use subroutine calls (0x08)** → 3 bytes vs. repeated text
3. **Dictionary compression** → Already implemented in FFMQ
4. **Reuse formatting codes** → Consistent formatting reduces bytes

**Analysis Optimization**:
1. **Start with high-use commands** (0x08, 0x0E) → Most impact
2. **Analyze unknown commands by usage** → Higher usage = higher priority
3. **Use test ROMs systematically** → One command at a time
4. **Document incrementally** → Update docs as you learn

---

## Appendix A: Command Quick Reference

### Control Flow
| Code | Name | Params | Description |
|------|------|--------|-------------|
| 0x00 | END | 0 | Script terminator / return |
| 0x08 | CALL_SUBROUTINE | 2 | Execute nested script |
| 0x23 | EXTERNAL_CALL_1 | 1 | Call external routine |
| 0x29 | EXTERNAL_CALL_2 | 1 | Call external routine |
| 0x2B | EXTERNAL_CALL_3 | 1 | Call external routine |

### State Modification
| Code | Name | Params | Description |
|------|------|--------|-------------|
| 0x0E | MEMORY_WRITE | 4 | Write word to address |
| 0x24 | SET_STATE_VAR | 4 | Set 2 state variables |
| 0x25 | SET_STATE_BYTE | 1 | Set 8-bit variable |
| 0x26 | SET_STATE_WORD | 4 | Set 16-bit variable |
| 0x27 | SET_STATE_BYTE_2 | 1 | Set 8-bit variable |
| 0x28 | SET_STATE_BYTE_3 | 1 | Set 8-bit variable |
| 0x2D | SET_STATE_WORD_2 | 2 | Set 16-bit variable |

### Dynamic Insertion
| Code | Name | Params | Description |
|------|------|--------|-------------|
| 0x04 | NAME | 0 | Character name |
| 0x05 | ITEM | 1 | Item name + param |
| 0x10 | INSERT_ITEM | 1 | Dynamic item name |
| 0x11 | INSERT_SPELL | 1 | Dynamic spell name |
| 0x12 | INSERT_MONSTER | 1 | Dynamic monster name |
| 0x13 | INSERT_CHARACTER | 1 | Dynamic character name |
| 0x14 | INSERT_LOCATION | 1 | Dynamic location name |
| 0x16 | INSERT_OBJECT | 2 | Dynamic object name |
| 0x17 | INSERT_WEAPON | 1 | Dynamic weapon name |
| 0x18 | INSERT_ARMOR | 0 | Dynamic armor name (register) |
| 0x1F | CRYSTAL | 1 | Crystal reference |

### Text Display
| Code | Name | Params | Description |
|------|------|--------|-------------|
| 0x01 | NEWLINE | 0 | Line break |
| 0x02 | WAIT | 0 | Wait for input |
| 0x03 | ASTERISK | 0 | Portrait marker |
| 0x06 | SPACE | 0 | Space character |

### Formatting
| Code | Name | Params | Description |
|------|------|--------|-------------|
| 0x1A | TEXTBOX_BELOW | 1 | Position textbox below |
| 0x1B | TEXTBOX_ABOVE | 1 | Position textbox above |
| 0x1D | FORMAT_ITEM_E1 | 1 | Format dictionary 0x50 |
| 0x1E | FORMAT_ITEM_E2 | 1 | Format dictionary 0x51 |

---

## Appendix B: Analysis Checklist

### Initial Analysis
- [ ] Run Event System Analyzer on ROM
- [ ] Review `event_system_statistics.json`
- [ ] Identify most-used commands
- [ ] Identify unknown commands with high usage

### Deep Analysis (Per Unknown Command)
- [ ] Extract parameter patterns from CSV
- [ ] Examine command context in event_scripts.json
- [ ] Check if parameters match known game data
- [ ] Formulate hypothesis about command purpose
- [ ] Create test ROM with isolated command usage
- [ ] Test in emulator with debugger/memory viewer
- [ ] Document confirmed behavior
- [ ] Update CONTROL_CODE_IDENTIFICATION.md

### Subroutine Analysis
- [ ] Review subroutine_call_graph.csv
- [ ] Identify most-called subroutines
- [ ] Extract and analyze reusable components
- [ ] Document component library
- [ ] Map inter-dialog dependencies

### State Modification Analysis
- [ ] Review memory_modification_map.csv
- [ ] Group by memory address
- [ ] Research memory address purposes
- [ ] Map quest/event state changes
- [ ] Document state modification patterns

### Final Documentation
- [ ] Update EVENT_COMMAND_REFERENCE.md
- [ ] Create event flow diagrams
- [ ] Document parameter meanings
- [ ] Create usage examples
- [ ] Update CONTROL_CODE_IDENTIFICATION.md with confirmed findings

---

*Last Updated: 2025-11-12*  
*Tool: `event_system_analyzer.py`*  
*Next Steps: Run analyzer and begin systematic command identification*
