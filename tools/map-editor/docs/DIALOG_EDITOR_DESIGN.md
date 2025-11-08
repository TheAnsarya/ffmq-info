# FFMQ Dialog & Event Script Editor - Design Document

## Overview

A comprehensive, visual dialog and event scripting editor for Final Fantasy Mystic Quest, integrated into the map editor. This tool will enable ROM hackers to:
- View, edit, and create dialog text with visual preview
- Edit event scripts with command palette and visual flow
- Manage dialog pointers and memory allocation
- Test dialog in-game context
- Export/import dialog for translation/localization

## System Architecture

### Core Components

1. **Dialog Text System** (`utils/dialog_text.py`)
   - Text encoding/decoding (FFMQ charset)
   - Control code handling (wait, clear, newline, etc.)
   - Character name/item name substitution
   - Length validation and truncation
   - Text metrics (byte count, estimated display time)

2. **Event Script Engine** (`utils/event_script.py`)
   - Command parser/generator
   - Script bytecode encoder/decoder
   - Control flow analysis (jumps, branches, loops)
   - Variable/flag tracking
   - Command validation

3. **Dialog Database** (`utils/dialog_database.py`)
   - Dialog pointer table management
   - Dialog indexing and searching
   - Free space management
   - Dialog references tracking (which NPCs use which dialog)
   - Batch operations (export/import)

4. **Dialog Editor UI** (`ui/dialog_editor.py`)
   - Text editor with live preview
   - Command palette (visual command insertion)
   - Script flow visualizer
   - Character counter with warnings
   - In-game preview simulation

5. **Integration** (`ui/dialog_integration.py`)
   - Map editor integration (edit NPC dialog from map)
   - Event trigger editor (link map events to scripts)
   - Dialog testing (preview in map context)

### Data Structures

#### Dialog Entry
```python
@dataclass
class DialogEntry:
	id: int                    # Dialog ID (index in pointer table)
	text: str                  # Decoded text with control codes
	raw_bytes: bytearray       # Original ROM bytes
	pointer: int               # ROM pointer address
	address: int               # Actual data address in ROM
	length: int                # Length in bytes
	references: List[str]      # NPCs/events that use this dialog
	tags: List[str]            # User tags (e.g., "boss", "quest", "shop")
	notes: str                 # User notes
	modified: bool             # Has been edited
```

#### Event Command
```python
@dataclass
class EventCommand:
	opcode: int                # Command byte
	name: str                  # Human-readable name
	parameters: List[int]      # Command parameters
	length: int                # Total bytes (opcode + params)
	address: int               # ROM address
	description: str           # What this command does
	flow_type: str             # 'linear', 'branch', 'jump', 'return'
```

#### Event Script
```python
@dataclass
class EventScript:
	id: int                    # Script ID
	commands: List[EventCommand]
	entry_point: int           # ROM address where script starts
	length: int                # Total byte length
	references: List[str]      # Map events that call this
	flow_graph: Dict           # Control flow graph
	variables_used: Set[int]   # Which variables this script uses
	flags_set: Set[int]        # Which flags this sets
	flags_checked: Set[int]    # Which flags this checks
```

## FFMQ Dialog System Specification

### Text Encoding

Based on `simple.tbl` and `extract_text.py`:

```
Character Ranges:
0x90-0x99 : Digits (0-9)
0x9A-0xB3 : Uppercase (A-Z)
0xB4-0xCD : Lowercase (a-z)
0x06      : Space
0x0E      : Period (.)
0x0F      : Comma (,)
0x10      : Apostrophe (')
0x11      : Exclamation (!)
0x12      : Question (?)
0x13      : Dash (-)
```

### Control Codes

```python
CTRL_END         = 0x00  # End of string (required)
CTRL_NEWLINE     = 0x01  # Line break
CTRL_WAIT        = 0x02  # Wait for button press
CTRL_CLEAR       = 0x03  # Clear dialog box
CTRL_NAME        = 0x04  # Insert character name
CTRL_ITEM        = 0x05  # Insert item name
CTRL_SPEED_SLOW  = 0x07  # Slow text speed
CTRL_SPEED_NORM  = 0x08  # Normal text speed
CTRL_SPEED_FAST  = 0x09  # Fast text speed
CTRL_COLOR_0     = 0x0A  # Color palette 0
CTRL_COLOR_1     = 0x0B  # Color palette 1
CTRL_COLOR_2     = 0x0C  # Color palette 2
CTRL_SOUND       = 0x0D  # Play sound effect (+ param)
```

### Dialog Storage

```
Pointer Table: ROM $00D636 (PC address)
- 256 entries (16-bit pointers)
- Little-endian format
- Points to bank $03 addresses

Dialog Data: Bank $03 (ROM $018000-$01FFFF)
- Variable length strings
- Null-terminated (0x00)
- Can contain control codes
- Maximum practical length: 512 bytes
```

## Event Script System Specification

### Command Categories

#### 1. Dialog Commands
```
0x00 : SHOW_DIALOG(dialog_id)    # Display dialog by ID
0x01 : CHOICE_2(option1, option2) # 2-choice menu
0x02 : CHOICE_3(opt1, opt2, opt3) # 3-choice menu
0x03 : SHOW_TEXT(text_ptr)        # Show text at pointer
```

#### 2. Flow Control
```
0x10 : JUMP(address)              # Unconditional jump
0x11 : CALL(address)              # Call subroutine
0x12 : RETURN                     # Return from subroutine
0x13 : IF_FLAG(flag, address)     # Jump if flag set
0x14 : IF_NOT_FLAG(flag, addr)    # Jump if flag clear
0x15 : IF_ITEM(item, address)     # Jump if player has item
```

#### 3. Flag/Variable Operations
```
0x20 : SET_FLAG(flag_id)          # Set game flag
0x21 : CLEAR_FLAG(flag_id)        # Clear game flag
0x22 : SET_VAR(var_id, value)     # Set variable
0x23 : ADD_VAR(var_id, amount)    # Add to variable
0x24 : SUB_VAR(var_id, amount)    # Subtract from var
```

#### 4. Item/Party Commands
```
0x30 : GIVE_ITEM(item_id, count)  # Give item to player
0x31 : TAKE_ITEM(item_id, count)  # Remove item
0x32 : GIVE_GP(amount)            # Give gold
0x33 : TAKE_GP(amount)            # Take gold
0x34 : GIVE_EXP(amount)           # Give experience
```

#### 5. Map/Character Commands
```
0x40 : WARP(map_id, x, y)         # Teleport to map
0x41 : MOVE_NPC(npc_id, x, y)     # Move NPC
0x42 : HIDE_NPC(npc_id)           # Hide NPC
0x43 : SHOW_NPC(npc_id)           # Show NPC
0x44 : FACE_DIRECTION(direction)  # Turn character
```

#### 6. Battle/Effect Commands
```
0x50 : START_BATTLE(enemy_id)     # Start battle
0x51 : PLAY_SOUND(sound_id)       # Play sound effect
0x52 : PLAY_MUSIC(music_id)       # Change music
0x53 : FLASH_SCREEN(color, dur)   # Screen flash
0x54 : SHAKE_SCREEN(dur)          # Screen shake
```

#### 7. Special Commands
```
0x60 : SAVE_GAME                  # Open save menu
0x61 : GAME_OVER                  # Game over screen
0x62 : CREDITS                    # Roll credits
0x63 : WAIT(frames)               # Wait frames
0xFF : END_SCRIPT                 # End event script
```

## User Interface Design

### Main Dialog Editor Window

```
┌─────────────────────────────────────────────────────────────┐
│ FFMQ Dialog Editor                               [File] [?]  │
├─────────────────────────────────────────────────────────────┤
│ ┌─ Dialog List ────┐ ┌─ Text Editor ──────────────────────┐│
│ │ Search: [______] │ │ Dialog #045: "Welcome to Libra"    ││
│ │                  │ │                                    ││
│ │ 001 King's Room  │ │ Text: [━━━━━━━━━━━━━━━━━━━━━━━━━] ││
│ │ 002 Old Man      │ │ Welcome to Libra![NEWLINE]        ││
│ │ 003 Weapon Shop  │ │ What brings you here?[WAIT]       ││
│ │ ...              │ │                                    ││
│ │▼045 Libra Entry  │ │ Preview: ┌──────────────────────┐ ││
│ │ 046 Libra Guard  │ │          │ Welcome to Libra!    │ ││
│ │ 047 Libra Elder  │ │          │ What brings you here?│ ││
│ │                  │ │          │         ▼ [A]        │ ││
│ │ [New] [Delete]   │ │          └──────────────────────┘ ││
│ └──────────────────┘ │                                    ││
│                      │ Commands: [Insert]                 ││
│ ┌─ Command Palette ┐ │ [Newline] [Wait] [Clear] [Name]   ││
│ │ ● Dialog         │ │ [Item] [Speed] [Color] [Sound]    ││
│ │   Flow Control   │ │                                    ││
│ │   Flags/Vars     │ │ Stats: 28/512 bytes | ~3.5 sec    ││
│ │   Items/Party    │ │                                    ││
│ │   Map/Character  │ │ Tags: [town] [greeting]           ││
│ │   Battle/Effects │ │ Notes: Entry dialog for Libra     ││
│ └──────────────────┘ └────────────────────────────────────┘│
├─────────────────────────────────────────────────────────────┤
│ References: NPC_045 (Libra, 12,8) | MAP_003 (event_02)    │
└─────────────────────────────────────────────────────────────┘
```

### Event Script Visual Editor

```
┌─────────────────────────────────────────────────────────────┐
│ Event Script Editor - Script #023                           │
├─────────────────────────────────────────────────────────────┤
│ ┌─ Flow View ──────────┐ ┌─ Code View ──────────────────┐  │
│ │                      │ │ 000: SHOW_DIALOG(45)         │  │
│ │  ┌─────────────┐     │ │ 003: CHOICE_2("Yes", "No")   │  │
│ │  │SHOW_DIALOG  │     │ │ 008: IF_FLAG(10, @020)       │  │
│ │  │   #045      │     │ │ 012: GIVE_ITEM(ELIXIR, 1)    │  │
│ │  └──────┬──────┘     │ │ 016: SET_FLAG(10)            │  │
│ │         │            │ │ 018: JUMP(@000)              │  │
│ │  ┌──────▼──────┐     │ │ 020: SHOW_DIALOG(46)         │  │
│ │  │  CHOICE_2   │     │ │ 023: END_SCRIPT              │  │
│ │  │ Yes  │  No  │     │ │                              │  │
│ │  └──┬───┴───┬──┘     │ │ Selected: Line 012           │  │
│ │     │       │        │ │                              │  │
│ │  ┌──▼────┐  │        │ │ Command: GIVE_ITEM           │  │
│ │  │IF_FLAG│  │        │ │ Item: [Elixir      ▼]        │  │
│ │  │  #10  │  │        │ │ Count: [1]                   │  │
│ │  └─┬───┬─┘  │        │ │                              │  │
│ │    │Yes│No  │        │ │ [Insert] [Delete] [Move]     │  │
│ │    │   └────┼────┐   │ └──────────────────────────────┘  │
│ │ ┌──▼──┐  ┌──▼──┐ │   │                                   │
│ │ │GIVE │  │SHOW │ │   │ ┌─ Variables Used ──┐            │
│ │ │ITEM │  │DIAL.│ │   │ │ Flags: 10          │            │
│ │ └──┬──┘  └──┬──┘ │   │ │ Items: ELIXIR      │            │
│ │    │        │    │   │ │ Dialogs: 45, 46    │            │
│ │ ┌──▼────────▼────▼┐  │ └────────────────────┘            │
│ │ │   END_SCRIPT    │  │                                   │
│ │ └─────────────────┘  │                                   │
│ └──────────────────────┘                                   │
├─────────────────────────────────────────────────────────────┤
│ [Validate] [Test] [Export]              ✓ No errors found  │
└─────────────────────────────────────────────────────────────┘
```

## Implementation Plan

### Phase 1: Core Text System (Foundation)
- [x] Format all files with tabs/CRLF/UTF-8
- [ ] Create `dialog_text.py` with encoding/decoding
- [ ] Create `dialog_database.py` with pointer management
- [ ] Add text validation and metrics
- [ ] Create unit tests for text operations

### Phase 2: Event Script Engine
- [ ] Create `event_script.py` with command definitions
- [ ] Implement bytecode parser/generator
- [ ] Add control flow analysis
- [ ] Create script validation system
- [ ] Add unit tests for script operations

### Phase 3: Basic UI
- [ ] Create `dialog_editor.py` basic window
- [ ] Implement dialog list view with search
- [ ] Create text editor component
- [ ] Add control code insertion buttons
- [ ] Implement preview pane with FFMQ font rendering

### Phase 4: Advanced UI
- [ ] Create command palette
- [ ] Implement visual script flow editor
- [ ] Add syntax highlighting for scripts
- [ ] Create in-game preview simulator
- [ ] Add batch operations (export/import)

### Phase 5: Map Integration
- [ ] Add dialog editing from NPC properties
- [ ] Create event trigger editor
- [ ] Link map events to scripts
- [ ] Add testing/preview in map context
- [ ] Create dialog reference tracking

### Phase 6: Polish & Documentation
- [ ] Create comprehensive testing suite
- [ ] Write user tutorials
- [ ] Create API documentation
- [ ] Add example scripts
- [ ] Create migration guide for existing text mods

## Technical Specifications

### File Formats

#### Dialog Export Format (JSON)
```json
{
	"version": "1.0",
	"rom": "FFMQ_US_1.0",
	"dialogs": [
		{
			"id": 45,
			"text": "Welcome to Libra!\nWhat brings you here?",
			"bytes": "0x2D,0xB8,0xBF,0xC6,...",
			"length": 28,
			"pointer": "0x8A3F",
			"address": "0x1CA3F",
			"tags": ["town", "greeting"],
			"notes": "Entry dialog for Libra"
		}
	]
}
```

#### Event Script Export Format
```json
{
	"id": 23,
	"entry_point": "0x2F456",
	"commands": [
		{"addr": "0x2F456", "cmd": "SHOW_DIALOG", "params": [45]},
		{"addr": "0x2F459", "cmd": "CHOICE_2", "params": [1, 2]},
		{"addr": "0x2F45E", "cmd": "IF_FLAG", "params": [10, "0x2F470"]}
	],
	"variables": {"flags": [10], "items": [5]},
	"flow": {"branches": 2, "max_depth": 3}
}
```

### ROM Modifications

#### Dialog Pointer Table Expansion
- Original: 256 entries at $00D636
- Expanded: Could extend to 512+ with pointer table relocation
- Free space management required

#### Event Script Storage
- Identify free space in ROM
- Track used/free regions
- Implement script relocation if needed
- Maintain pointer integrity

### Performance Considerations

- Cache decoded dialog to avoid repeated parsing
- Index dialog by tags for fast searching
- Lazy-load script flow graphs (compute on demand)
- Use efficient data structures (dict for O(1) lookup)

## Future Enhancements

### Localization Support
- Multi-language dialog sets
- Character set switching (JP/EN/custom)
- Length validation per language
- Export to industry-standard formats (XLIFF, PO)

### Advanced Scripting
- Visual scripting with node-based editor
- Script templates (common patterns)
- Macro system (reusable script fragments)
- Debugging tools (breakpoints, variable watch)

### AI-Assisted Features
- Dialog generation suggestions
- Text quality analysis
- Consistency checking (name references)
- Auto-formatting and style guide enforcement

### Community Features
- Dialog pack sharing
- Script library (community scripts)
- Translation collaboration tools
- Version control integration

## Success Criteria

1. **Functionality**
   - ✓ Can view all 256 dialogs from ROM
   - ✓ Can edit dialog text and see live preview
   - ✓ Can insert all control codes correctly
   - ✓ Can save changes back to ROM
   - ✓ Changes work correctly in-game

2. **Usability**
   - ✓ Intuitive UI for non-programmers
   - ✓ Visual preview matches in-game appearance
   - ✓ Clear error messages and validation
   - ✓ Undo/redo support
   - ✓ Searchable dialog database

3. **Reliability**
   - ✓ No ROM corruption
   - ✓ Proper bounds checking
   - ✓ Backup system before saves
   - ✓ Validation prevents invalid data
   - ✓ Comprehensive test coverage

4. **Performance**
   - ✓ Dialog loads in <100ms
   - ✓ Preview updates in real-time (<16ms)
   - ✓ Search results in <200ms
   - ✓ ROM save in <500ms

## References

- `tools/extraction/extract_text.py` - Existing text extraction
- `docs/tutorials/TEXT_MODDING.md` - Text modding guide
- `simple.tbl` - Character encoding table
- DataCrystal FFMQ documentation
- SNES ROM hacking resources
