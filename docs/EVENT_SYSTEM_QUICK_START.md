# Event System Analysis - Quick Start Guide

**Quick reference for analyzing FFMQ's event system using the Event System Analyzer tool.**

---

## 🚀 Quick Start (5 Minutes)

### Step 1: Run the Analyzer

```powershell
# Navigate to project root
cd c:\Users\me\source\repos\ffmq-info

# Run basic analysis
python tools/analysis/event_system_analyzer.py --rom roms/ffmq.sfc --table simple.tbl
```

**What it does**:
- Analyzes all 256 dialogs in the ROM
- Treats each dialog as an event script
- Extracts all event commands and parameters
- Generates 6 comprehensive output files

### Step 2: Review the Statistics

```powershell
# View statistics (Windows)
notepad output\event_system_statistics.json

# Or use VS Code
code output\event_system_statistics.json
```

**What to look for**:
- **Total commands**: How many commands across all dialogs
- **Most used commands**: Prioritize analysis of high-use commands
- **Unknown command usage**: Which unknown commands to investigate first

### Step 3: Check the Documentation

```powershell
# View auto-generated command reference
code output\EVENT_COMMAND_REFERENCE.md
```

**What to review**:
- Command usage statistics
- Parameter patterns for each command
- Examples of each command in context
- Category breakdowns

### Step 4: Analyze Specific Aspects

**Subroutine Call Graph**:
```powershell
# Open in Excel/spreadsheet viewer
start output\subroutine_call_graph.csv
```
*Find reusable dialog components*

**Memory Modifications**:
```powershell
# Open in Excel/spreadsheet viewer
start output\memory_modification_map.csv
```
*Track game state changes*

**Parameter Patterns**:
```powershell
# Open in Excel/spreadsheet viewer
start output\parameter_patterns.csv
```
*Identify parameter meanings*

---

## 📊 Understanding the Outputs

### File 1: `event_system_statistics.json`

**Purpose**: High-level overview of the entire event system

**Key sections**:
```json
{
  "total_dialogs": 256,
  "total_commands": 2450,
  "command_usage": {
    "0x08 (CALL_SUBROUTINE)": 532,    // Most used command
    "0x0E (MEMORY_WRITE)": 124,       // Second most used
    "0x01 (NEWLINE)": 153,            // Text display
    ...
  },
  "category_usage": {
    "control_flow": 750,              // Branching, calls, returns
    "text_display": 400,              // Display text
    "state_modification": 300,        // Modify game state
    "dynamic_insertion": 250,         // Insert names, items
    "formatting": 100,                // Textbox positioning
    "memory_operation": 150           // Direct RAM access
  }
}
```

**How to use**:
1. Check `total_dialogs` - Should be 256 if full ROM analyzed
2. Review `command_usage` - Prioritize high-count unknowns
3. Check `category_usage` - Understand system composition

### File 2: `event_scripts.json`

**Purpose**: Detailed analysis of each dialog as an event script

**Example entry**:
```json
{
  "dialog_id": 5,
  "address": "0x018A5C",
  "length": 78,
  "commands": [
    {
      "opcode": 1,
      "name": "NEWLINE",
      "address": 100,
      "dialog_id": 5,
      "position": 12,
      "parameters": [],
      "category": "text_display",
      "context_before": [0x54, 0x65, 0x78, 0x74, 0x20],
      "context_after": [0x08, 0xA0, 0x8F, 0x00, 0x02],
      "follows": null,
      "precedes": 8
    },
    {
      "opcode": 8,
      "name": "CALL_SUBROUTINE",
      "address": 113,
      "dialog_id": 5,
      "position": 13,
      "parameters": [160, 143],
      "category": "control_flow",
      "context_before": [0x01, 0x54, 0x65, 0x78, 0x74],
      "context_after": [0x00, 0x02, 0x01, 0x00, 0x00],
      "follows": 1,
      "precedes": 0
    }
  ],
  "text_segments": [
    "Some text here..."
  ],
  "calls_subroutines": ["0x8FA0"],
  "modifies_memory": [],
  "has_branching": false,
  "has_loops": false,
  "statistics": {
    "command_count": 12,
    "unique_commands": 5,
    "text_bytes": 45,
    "event_bytes": 33,
    "subroutine_calls": 1,
    "memory_writes": 0
  }
}
```

**How to use**:
1. Find specific dialog by `dialog_id`
2. Review `commands` array for event sequence
3. Check `calls_subroutines` for nested execution
4. Check `modifies_memory` for state changes
5. Use `context_before`/`context_after` to understand command usage

### File 3: `EVENT_COMMAND_REFERENCE.md`

**Purpose**: Auto-generated documentation for all commands

**Contains**:
- Command summary table
- Category groupings
- Usage statistics per command
- Parameter pattern examples
- Special analysis for key commands (0x08, 0x0E)

**How to use**:
1. Quick reference for command details
2. See which commands are most used
3. Review parameter patterns for unknown commands
4. Cross-reference with disassembly

### File 4: `subroutine_call_graph.csv`

**Purpose**: Map all subroutine calls (command 0x08)

**Format**:
```csv
Target Address,Call Count,Calling Dialogs
0x8FA0,25,0;5;15;22;35;42;48;52;...
0x9120,18,0;3;42;55;60;...
0x9500,12,15;18;20;25;...
```

**How to use**:
1. Sort by "Call Count" (descending) to find most-reused components
2. For each high-count target:
   - Extract dialog bytes from ROM at that address
   - Analyze what it contains (greeting, shop menu, etc.)
   - Document as reusable component
3. Map inter-dialog dependencies

**Example analysis**:
```
Target 0x8FA0 called 25 times:
  → Likely a common greeting or intro sequence
  → Extract and document as "Greeting Component"
  → Used by: Opening dialog, NPC conversations, quest givers
```

### File 5: `memory_modification_map.csv`

**Purpose**: Track all memory writes (command 0x0E)

**Format**:
```csv
Dialog ID,Memory Address,Value Written
5,0x1A50,0x0001
12,0x1A50,0x0002
28,0x1A50,0x0003
15,0x1900,0x0005
```

**How to use**:
1. Group by "Memory Address" to see which dialogs modify the same location
2. Identify quest progression:
   ```
   Address 0x1A50:
     Dialog 5 writes 0x0001 → Quest started
     Dialog 12 writes 0x0002 → Quest step 1
     Dialog 28 writes 0x0003 → Quest step 2
     Dialog 35 writes 0x0004 → Quest complete
   ```
3. Map game state variables
4. Document quest/event chains

### File 6: `parameter_patterns.csv`

**Purpose**: Analyze parameter usage for all commands

**Format**:
```csv
Opcode,Command Name,Pattern Count,Unique Patterns,Sample Pattern
0x08,CALL_SUBROUTINE,532,85,A0 8F
0x0E,MEMORY_WRITE,124,42,00 01 CD AB
0x10,INSERT_ITEM,55,32,2A
0x07,UNK_07,45,8,A0 00 05
```

**How to use**:
1. For unknown commands, check "Unique Patterns"
   - Low unique count → Limited parameter space (might be flag/mode)
   - High unique count → Wide parameter space (might be index/address)
2. Review "Sample Pattern" examples
3. Compare pattern values with known game data:
   - 0-63: Spell/map IDs
   - 0-255: Item/monster IDs
   - 0x0000-0x1FFF: RAM addresses
   - 0x8000-0xFFFF: ROM addresses
4. Formulate hypotheses about parameter meanings

---

## 🔍 Common Analysis Tasks

### Task 1: Identify What Unknown Command Does

**Example**: What does command 0x09 do?

**Steps**:

1. **Check usage statistics**:
   ```powershell
   # Open statistics file
   code output\event_system_statistics.json
   # Look for "0x09"
   ```
   *Result*: Used 32 times

2. **Check parameter patterns**:
   ```powershell
   # Open parameter patterns
   start output\parameter_patterns.csv
   # Find row for 0x09
   ```
   *Result*: 12 unique patterns, sample: `A0 00 05`

3. **Examine specific usage**:
   ```powershell
   # Open event scripts
   code output\event_scripts.json
   # Search for "opcode": 9
   ```
   *Result*: See command context, what precedes/follows it

4. **Analyze parameter values**:
   - First param: 0xA0 (160) - Not item ID (too high), maybe address?
   - Second param: 0x00 (0) - Could be flag, index, or zero value
   - Third param: 0x05 (5) - Small value, maybe mode/flag

5. **Form hypothesis**:
   - "0x09 might write value (param 3) to address (param 1 + param 2)"
   - Similar to 0x0E but different format?

6. **Create test ROM**:
   ```powershell
   # Use rom_test_patcher.py
   python tools/testing/rom_test_patcher.py --test-command 0x09 --params 0xA0 0x00 0x05
   ```

7. **Test in emulator**:
   - Load test ROM in Mesen-S
   - Open memory viewer at address 0x00A0
   - Trigger test dialog
   - Observe memory changes

8. **Document findings**:
   ```powershell
   # Update identification doc
   code docs/CONTROL_CODE_IDENTIFICATION.md
   # Add confirmed behavior
   ```

### Task 2: Find Reusable Dialog Components

**Goal**: Identify commonly called subroutines

**Steps**:

1. **Open subroutine call graph**:
   ```powershell
   start output\subroutine_call_graph.csv
   ```

2. **Sort by "Call Count" (descending)**

3. **Top targets** (example):
   ```
   0x8FA0 - 25 calls
   0x9120 - 18 calls
   0x9500 - 12 calls
   0x9800 - 8 calls
   ```

4. **For each target, extract dialog data**:
   ```powershell
   # Use dialog extractor or hex editor
   # Open ROM at bank $03, address $8FA0
   # Extract bytes until 0x00 (END)
   ```

5. **Decode extracted bytes**:
   ```python
   # Quick decoder
   python
   >>> with open('roms/ffmq.sfc', 'rb') as f:
   ...     f.seek(0x018FA0)  # PC address for bank $03, $8FA0
   ...     data = f.read(100)
   ...     print(' '.join(f'{b:02X}' for b in data[:50]))
   ```

6. **Identify component type**:
   - Text-heavy → Common dialog fragment ("Hello!", "Goodbye!")
   - Commands-heavy → Functional component (shop menu, save menu)
   - Mixed → Complex interaction

7. **Document component**:
   ```markdown
   ## Subroutine 0x8FA0: Greeting Component
   
   **Called by**: Dialogs 0, 5, 15, 22, 35, 42, ... (25 total)
   
   **Content**:
   - "Hello there, [NAME]!"
   - [WAIT]
   - [END]
   
   **Purpose**: Standard NPC greeting
   ```

### Task 3: Map Quest Progression

**Goal**: Understand how a quest tracks progress

**Steps**:

1. **Open memory modification map**:
   ```powershell
   start output\memory_modification_map.csv
   ```

2. **Group by memory address** (use Excel/spreadsheet):
   ```
   Address 0x1A50:
     Dialog 5: 0x0001
     Dialog 12: 0x0002
     Dialog 28: 0x0003
     Dialog 35: 0x0004
   ```

3. **Identify progression pattern**:
   - Sequential values → Quest stages
   - Different addresses → Multiple quest flags
   - Non-sequential → Complex state machine

4. **For each dialog, review content**:
   ```powershell
   # Check event_scripts.json for dialog 5
   code output\event_scripts.json
   # Search for "dialog_id": 5
   ```

5. **Map quest flow**:
   ```
   Quest #5 Progression:
   
   Stage 0 (0x1A50 = 0x0000): Quest not started
     → Talk to NPC (Dialog 5)
     → Sets 0x1A50 = 0x0001
   
   Stage 1 (0x1A50 = 0x0001): Quest active
     → Complete objective
     → Talk to NPC (Dialog 12)
     → Sets 0x1A50 = 0x0002
   
   Stage 2 (0x1A50 = 0x0002): Objective 1 complete
     → Complete second objective
     → Talk to NPC (Dialog 28)
     → Sets 0x1A50 = 0x0003
   
   Stage 3 (0x1A50 = 0x0003): Objective 2 complete
     → Return to quest giver (Dialog 35)
     → Sets 0x1A50 = 0x0004
     → Quest complete!
   ```

6. **Document quest**:
   ```markdown
   ## Quest #5: [Quest Name]
   
   **Flag Address**: 0x1A50
   
   **Progression**:
   1. Quest Start (Dialog 5): Flag → 0x0001
   2. Objective 1 (Dialog 12): Flag → 0x0002
   3. Objective 2 (Dialog 28): Flag → 0x0003
   4. Quest Complete (Dialog 35): Flag → 0x0004
   
   **Rewards**: [From dialog text/memory writes]
   ```

### Task 4: Understand Parameter Meanings

**Goal**: Determine what a command's parameters mean

**Example**: Command 0x1D with 1-byte parameter

**Steps**:

1. **Check parameter patterns**:
   ```powershell
   start output\parameter_patterns.csv
   # Find 0x1D row
   ```
   *Result*: 25 uses, 5 unique patterns: [00], [01], [02], [03], [04]

2. **Examine command context**:
   ```powershell
   code output\event_scripts.json
   # Search for "opcode": 29 (0x1D)
   ```
   *Result*: Always followed by dictionary entry 0x50

3. **Look at precedes/follows**:
   ```json
   {
     "opcode": 29,
     "name": "UNK_1D",
     "parameters": [2],
     "precedes": 80,  // Dictionary entry 0x50
     "follows": 1     // NEWLINE
   }
   ```

4. **Hypothesis**:
   - "0x1D sets formatting mode for the following dictionary entry"
   - Parameter selects formatting style (0-4)

5. **Validate with test ROM**:
   ```
   Test 1: [0x1D][0x00][0x50] → Normal display
   Test 2: [0x1D][0x01][0x50] → With article ("a ", "an ")
   Test 3: [0x1D][0x02][0x50] → Capitalized
   Test 4: [0x1D][0x03][0x50] → With possessive
   Test 5: [0x1D][0x04][0x50] → Plural
   ```

6. **Test in emulator and observe**

7. **Document confirmed behavior**:
   ```markdown
   ### 0x1D: FORMAT_ITEM_E1
   
   **Category**: Formatting
   **Parameters**: 1 byte (formatting mode)
   **Usage**: 25 times
   
   **Description**: Sets display formatting for the following dictionary entry (0x50).
   
   **Parameter Values**:
   - 0x00: Normal display
   - 0x01: With article ("a sword", "an axe")
   - 0x02: Capitalized
   - 0x03: Possessive ("Benjamin's sword")
   - 0x04: Plural ("swords")
   
   **Example**:
   ```
   0x1D 0x01 0x50 → Displays "a [equipment name]"
   ```
   ```

---

## 🛠️ Advanced Workflows

### Workflow: Systematic Unknown Command Identification

**Goal**: Identify all unknown commands methodically

**Steps**:

1. **Create command priority list**:
   ```powershell
   # From event_system_statistics.json, list unknown commands by usage
   python
   >>> import json
   >>> with open('output/event_system_statistics.json') as f:
   ...     stats = json.load(f)
   >>> unknowns = [(cmd, count) for cmd, count in stats['command_usage'].items() if 'UNK' in cmd]
   >>> unknowns.sort(key=lambda x: x[1], reverse=True)
   >>> for cmd, count in unknowns:
   ...     print(f"{cmd}: {count} uses")
   ```

2. **For each unknown command (highest usage first)**:
   - Extract parameter patterns
   - Analyze command context
   - Form hypothesis
   - Create test ROM
   - Validate in emulator
   - Document findings

3. **Track progress**:
   ```markdown
   # Command Identification Progress
   
   - [x] 0x08 - CALL_SUBROUTINE (confirmed)
   - [x] 0x0E - MEMORY_WRITE (confirmed)
   - [ ] 0x09 - Testing in progress
   - [ ] 0x07 - Hypothesis formed
   - [ ] 0x0A - Pattern analysis complete
   - [ ] 0x0B - Not started
   ```

### Workflow: Create Comprehensive Event Flow Diagrams

**Goal**: Visualize event system architecture

**Steps**:

1. **Export subroutine call graph to visualization tool**:
   ```python
   import csv
   import networkx as nx
   import matplotlib.pyplot as plt
   
   # Load call graph
   G = nx.DiGraph()
   with open('output/subroutine_call_graph.csv') as f:
       reader = csv.DictReader(f)
       for row in reader:
           target = row['Target Address']
           callers = row['Calling Dialogs'].split(';')
           for caller in callers:
               G.add_edge(f"Dialog {caller}", f"Sub {target}")
   
   # Draw graph
   pos = nx.spring_layout(G)
   nx.draw(G, pos, with_labels=True, node_color='lightblue')
   plt.savefig('output/call_graph.png')
   ```

2. **Create state machine diagram for quests**:
   - Use memory_modification_map.csv
   - Map state transitions
   - Generate flowchart (Mermaid, Graphviz, etc.)

3. **Document event chains**:
   ```markdown
   ## Event Chain: Opening Sequence
   
   ```mermaid
   graph TD
     A[Dialog 0: Opening] --> B[Subroutine 0x8FA0: Greeting]
     A --> C[Subroutine 0x9120: Quest Intro]
     C --> D[Set Flag 0x1A50 = 1]
     D --> E[Dialog 5: Quest Active]
   ```
   ```

### Workflow: Parameter Type Database

**Goal**: Build database of parameter meanings

**Steps**:

1. **Create parameter type mapping**:
   ```json
   {
     "parameter_types": {
       "item_id": {
         "range": "0-255",
         "used_by": ["0x05", "0x10"],
         "examples": {
           "0x00": "Cure Potion",
           "0x2A": "Steel Sword",
           "0xFF": "Invalid"
         }
       },
       "pointer": {
         "range": "0x8000-0xFFFF",
         "format": "little-endian",
         "used_by": ["0x08"],
         "bank": "0x03"
       },
       "memory_address": {
         "range": "0x0000-0x1FFF",
         "format": "little-endian",
         "used_by": ["0x0E"],
         "common_addresses": {
           "0x1A50": "Quest flag 5",
           "0x1900": "Item count",
           "0x1910": "Current HP"
         }
       }
     }
   }
   ```

2. **Validate parameter types against ROM data**:
   - Check if item IDs are valid (0-255)
   - Check if pointers point to valid ROM addresses
   - Check if memory addresses are in RAM range

3. **Generate parameter type documentation**:
   ```markdown
   ## Parameter Types Reference
   
   ### Item ID (1 byte)
   - Range: 0x00-0xFF (0-255)
   - Used by: 0x05 (ITEM), 0x10 (INSERT_ITEM)
   - Examples: See item name table
   
   ### Pointer (2 bytes, little-endian)
   - Range: 0x8000-0xFFFF (bank-relative)
   - Bank: 0x03 (ROM 0x018000-0x01FFFF)
   - Used by: 0x08 (CALL_SUBROUTINE)
   - Format: Low byte first
   - Example: 0xA0 0x8F → Address 0x8FA0
   ```

---

## 📚 Next Steps

After completing basic analysis:

1. **[ ] Review EVENT_SYSTEM_ARCHITECTURE.md** for comprehensive documentation
2. **[ ] Create test ROMs** for unknown commands (see MANUAL_TESTING_TASKS.md)
3. **[ ] Test in emulator** with memory viewer and debugger
4. **[ ] Update CONTROL_CODE_IDENTIFICATION.md** with confirmed findings
5. **[ ] Build parameter type database** for all commands
6. **[ ] Create event flow diagrams** for major quest chains
7. **[ ] Document reusable components** (common subroutines)
8. **[ ] Generate enhanced dialog compiler** with full parameter support

---

## 🆘 Troubleshooting

### Issue: Analyzer crashes with "ROM not found"

**Solution**:
```powershell
# Ensure ROM path is correct
python tools/analysis/event_system_analyzer.py --rom roms/ffmq.sfc --table simple.tbl

# Use absolute path if relative fails
python tools/analysis/event_system_analyzer.py --rom "c:\Users\me\source\repos\ffmq-info\roms\ffmq.sfc" --table simple.tbl
```

### Issue: Character table not loading

**Solution**:
```powershell
# Check table file exists
dir simple.tbl

# Verify table format (each line: XX=C)
type simple.tbl
```

### Issue: Output files not generated

**Solution**:
```powershell
# Check output directory permissions
mkdir output
icacls output /grant Users:F

# Specify output directory explicitly
python tools/analysis/event_system_analyzer.py --rom roms/ffmq.sfc --table simple.tbl --output analysis_output
```

### Issue: JSON files won't open in Excel

**Solution**:
```powershell
# Use proper JSON viewer
code output\event_system_statistics.json

# Or convert to CSV
python
>>> import json, csv
>>> with open('output/event_system_statistics.json') as f:
...     data = json.load(f)
>>> with open('output/statistics.csv', 'w', newline='') as f:
...     writer = csv.writer(f)
...     for key, value in data['command_usage'].items():
...         writer.writerow([key, value])
```

---

## 🔗 Related Documentation

- **EVENT_SYSTEM_ARCHITECTURE.md** - Comprehensive system documentation
- **CONTROL_CODE_IDENTIFICATION.md** - Command identification reference
- **MANUAL_TESTING_TASKS.md** - Test ROM validation procedures
- **DIALOG_EDITOR_DESIGN.md** - Event editor specifications
- **WORKFLOW_GUIDE.md** - General project workflows

---

*Last Updated: 2025-11-12*  
*Tool: `event_system_analyzer.py`*  
*For detailed architecture info, see EVENT_SYSTEM_ARCHITECTURE.md*
