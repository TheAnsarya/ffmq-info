# GitHub Issues - SRAM Save Editor Work

GitHub issues created for SRAM save file editor implementation.

**Created**: 2025-11-13  
**Session**: Nov 13, 2025 SRAM Editor Development

---

## Issue #90: SRAM Save Editor - Core Tool Implementation

**Title**: Implement comprehensive SRAM save file editor

**Labels**: `enhancement`, `tool`, `save-editing`, `priority-high`

**Description**:

Create a comprehensive SRAM (.srm) save file editor for Final Fantasy: Mystic Quest with full read/write capabilities.

### Requirements

**Core Features**:
- [x] Load .srm files (8,172 bytes)
- [x] Parse 9 save slots (3 slots × 3 redundant copies A/B/C)
- [x] Validate "FF0!" header signature
- [x] Calculate and verify 16-bit checksums
- [x] Extract character data (name, level, exp, HP, stats, status, weapon)
- [x] Extract party data (gold, position, map, play time, cure count)
- [x] Export slots to JSON for editing
- [x] Import modified slots from JSON
- [x] Fix corrupted checksums
- [x] List all slots with status display
- [x] Backup functionality

**Character Editing**:
- [x] Name (8 bytes, ASCII)
- [x] Level (1-99)
- [x] Experience (0-9,999,999)
- [x] HP (current/max, 0-65535)
- [x] Stats (Attack/Defense/Speed/Magic current + base, 0-99)
- [x] Status effects (bitfield)
- [x] Weapon data (count + ID)

**Party Editing**:
- [x] Gold (0-9,999,999)
- [x] Player position (X, Y, facing direction)
- [x] Map ID
- [x] Play time (hours:minutes:seconds)
- [x] Cure count

**CLI Interface**:
- [x] `--list` - Show all save slots
- [x] `--verify` - Check checksums
- [x] `--fix-checksums` - Repair all checksums
- [x] `--extract SLOT` - Export to JSON
- [x] `--insert JSON --slot SLOT` - Import from JSON
- [x] `--backup FILE` - Create backup
- [x] `--verbose` - Detailed output

### Implementation

**File**: `tools/save/ffmq_sram_editor.py` (~680 lines)

**Architecture**:
- `CharacterData` dataclass (0x50 bytes each)
- `SaveSlot` dataclass (0x38C bytes each)
- `SRAMEditor` class with all operations
- JSON import/export using standard library
- Comprehensive error handling

**Data Structures**:
```python
@dataclass
class CharacterData:
	name: str
	level: int
	experience: int
	current_hp: int
	max_hp: int
	status: int
	current_attack/defense/speed/magic: int
	base_attack/defense/speed/magic: int
	weapon_count: int
	weapon_id: int
	raw_data: bytes

@dataclass
class SaveSlot:
	slot_id: int
	valid: bool
	checksum: int
	character1: CharacterData
	character2: CharacterData
	gold: int
	player_x/y/facing: int
	map_id: int
	play_time_hours/minutes/seconds: int
	cure_count: int
	raw_data: bytes
```

### Testing

**File**: `tools/save/test_sram_editor.py` (~460 lines)

**Test Coverage**:
- [x] Character data packing/unpacking
- [x] Save slot extraction/insertion
- [x] Checksum calculation/verification
- [x] JSON export/import roundtrip
- [x] Value clamping (max limits enforced)
- [x] File I/O operations
- [x] Edge cases (empty slots, corrupted data)
- [x] Data validation

**Run Tests**:
```bash
python tools/save/test_sram_editor.py
python tools/save/test_sram_editor.py -v  # Verbose
```

### Documentation

- [x] SRAM Schema: `docs/save/SRAM_SCHEMA.md` (~490 lines)
- [x] Usage Guide: `docs/save/SRAM_EDITOR_USAGE.md` (~580 lines)
- [x] Code documentation: Comprehensive docstrings
- [x] Examples: Common operations documented

### Usage Examples

**View all saves**:
```bash
python tools/save/ffmq_sram_editor.py save.srm --list
```

**Extract to JSON**:
```bash
python tools/save/ffmq_sram_editor.py save.srm --extract 1A --output slot1.json
```

**Edit and re-insert**:
```bash
# Edit slot1.json (change gold, level, etc.)
python tools/save/ffmq_sram_editor.py save.srm --insert slot1.json --slot 1A --output save_modified.srm
```

**Verify checksums**:
```bash
python tools/save/ffmq_sram_editor.py save.srm --verify
```

**Fix checksums**:
```bash
python tools/save/ffmq_sram_editor.py save.srm --fix-checksums
```

### Reference

- DataCrystal SRAM Map: https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest/SRAM_map
- Triple redundancy: Each logical slot has 3 copies (A/B/C) for corruption protection
- Checksum: Sum of all bytes after 6-byte header, masked to 16-bit

### Future Enhancements

- [ ] GUI editor (wxPython/Qt)
- [ ] Batch operations script
- [ ] Save comparison tool
- [ ] Automated backup rotation
- [ ] Cloud save sync
- [ ] Save state converter (emulator formats)

---

## Issue #91: SRAM Schema - Complete Field Mapping

**Title**: Document complete SRAM save file structure

**Labels**: `documentation`, `research`, `save-editing`

**Description**:

Create comprehensive documentation of FFMQ SRAM save file format, documenting all known fields and identifying unknown regions for future research.

### Status

**File**: `docs/save/SRAM_SCHEMA.md` (~490 lines)

**Documentation Completed**:
- [x] Overall SRAM layout (8,172 bytes total)
- [x] 9 slot organization (3×3 redundancy)
- [x] Slot offsets table
- [x] Save slot structure (908 bytes each)
- [x] Header format ("FF0!" + checksum)
- [x] Character data structure (80 bytes each)
- [x] Party data fields
- [x] Status effect bitfield documentation
- [x] Data type specifications
- [x] Value limits table
- [x] Usage examples (Python code)
- [x] Checksum algorithm

**Known Fields** (Fully Documented):

**Header** (6 bytes):
- 0x000-0x003: "FF0!" signature
- 0x004-0x005: 16-bit checksum

**Characters** (80 bytes each):
- 0x00-0x07: Name
- 0x10: Level
- 0x11-0x13: Experience (24-bit)
- 0x14-0x15: Current HP
- 0x16-0x17: Max HP
- 0x21: Status effects
- 0x22-0x25: Current stats (Attack/Defense/Speed/Magic)
- 0x26-0x29: Base stats
- 0x30-0x31: Weapon data

**Party Data**:
- 0x0A6-0x0A8: Gold (24-bit)
- 0x0AB-0x0AD: Position (X, Y, facing)
- 0x0B3: Map ID
- 0x0B9-0x0BB: Play time (SS:MM:HH)
- 0x0C1: Cure count

**Unknown Fields** (Research Needed):

**High Priority** (~800 bytes undocumented):
1. **Character unknown block** (0x32-0x4F, 30 bytes per character)
	- Likely: Armor, accessories, learned spells
	- Could be: Inventory, abilities
2. **Party unknown block** (0x0C2-0x38B, 714 bytes)
	- Likely: Full inventory (items, weapons, armor)
	- Could be: Quest flags, story progress, treasure chests
	- May contain: Battle records, monster book
3. **Small unknown blocks**:
	- 0x08-0x0F (8 bytes per character)
	- 0x0A9-0x0AA (2 bytes)
	- 0x0AE-0x0B2 (5 bytes)
	- 0x0B4-0x0B8 (5 bytes)
	- 0x0BC-0x0C0 (5 bytes)

**SRAM Trailer**:
- 0x1FEC-0x1FFF (20 bytes) - Unknown purpose

### Research Methodology

**Save State Comparison**:
1. Create save at known state
2. Make minimal change (collect 1 item, open chest, etc.)
3. Save again
4. Compare hex dumps
5. Document changed bytes

**Hex Editor Testing**:
1. Modify suspected fields
2. Load in emulator
3. Observe effects
4. Document findings

**Disassembly Analysis**:
1. Trace save/load routines in ROM
2. Identify what reads/writes each offset
3. Reverse engineer data structures
4. Cross-reference with RAM dumps

**Community Cross-Reference**:
1. Compare with other FF game formats
2. Check similar SNES RPG structures
3. Review existing documentation databases

### Documentation Includes

- [x] Complete offset tables with descriptions
- [x] Data type specifications
- [x] Value ranges and limits
- [x] Checksum algorithm documentation
- [x] Status effect bitfield breakdown
- [x] Python usage examples
- [x] Research methodology
- [x] Unknown field identification
- [x] Future work priorities

### References

- DataCrystal: https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest/SRAM_map
- TCRF: https://tcrf.net/Final_Fantasy:_Mystic_Quest
- SNES Dev Wiki: https://wiki.superfamicom.org/

---

## Issue #92: SRAM Unknown Fields - Reverse Engineering

**Title**: Research and document unknown SRAM fields

**Labels**: `research`, `reverse-engineering`, `save-editing`, `help-wanted`

**Description**:

Reverse engineer the ~800 bytes of undocumented SRAM fields to complete the save file format specification.

### Unknown Fields Summary

**Total Undocumented**: ~800 bytes per save slot (~47% of slot data)

**Priority Targets**:

1. **Character Equipment/Inventory** (30 bytes × 2 characters = 60 bytes)
	- Offset: 0x32-0x4F (per character)
	- Likely contains: Armor ID, accessory IDs, learned spells
	- Research method: Equip/unequip items, compare saves

2. **Party Inventory** (714 bytes - largest unknown block)
	- Offset: 0x0C2-0x38B (within save slot)
	- Likely contains:
		- Item inventory (consumables, key items)
		- Weapon collection
		- Armor collection
		- Spell inventory
		- Quest/event flags
		- Story progress markers
		- Treasure chest states
		- NPC interaction flags
		- Battle statistics
		- Monster book data
	- Research method: Collect items, open chests, progress story

3. **Character Metadata** (8 bytes × 2 characters = 16 bytes)
	- Offset: 0x08-0x0F (per character)
	- Unknown purpose
	- Research method: Test various character states

4. **Small Unknown Blocks** (17 bytes total)
	- 0x0A9-0x0AA (2 bytes) - Between gold and position
	- 0x0AE-0x0B2 (5 bytes) - Between position and map
	- 0x0B4-0x0B8 (5 bytes) - Between map and time
	- 0x0BC-0x0C0 (5 bytes) - Between time and cure count
	- Research method: Systematic testing

### Research Plan

**Phase 1: Item Inventory** (Week 1-2)
- [ ] Create fresh save
- [ ] Collect items one by one
- [ ] Save after each item
- [ ] Compare hex dumps
- [ ] Map item IDs to offsets
- [ ] Document storage format

**Phase 2: Equipment System** (Week 2-3)
- [ ] Test weapon/armor equipping
- [ ] Test accessory system
- [ ] Map equipment slots
- [ ] Document equipment IDs

**Phase 3: Quest/Event Flags** (Week 3-4)
- [ ] Progress through story
- [ ] Save at each major event
- [ ] Map story flags
- [ ] Document treasure chest bits

**Phase 4: Battle/Stats Data** (Week 4-5)
- [ ] Test battle statistics
- [ ] Check monster book
- [ ] Document tracking systems

**Phase 5: Validation** (Week 5-6)
- [ ] Create test saves with all fields
- [ ] Verify in-game
- [ ] Update documentation
- [ ] Create validation tool

### Tools Needed

- [x] SRAM editor (implemented)
- [ ] Hex diff tool
- [ ] Save state comparison script
- [ ] Automated testing framework
- [ ] ROM disassembler (already have)
- [ ] Emulator with RAM watch

### Deliverables

- [ ] Updated SRAM_SCHEMA.md with all fields
- [ ] Item ID database
- [ ] Equipment ID database
- [ ] Quest flag documentation
- [ ] Treasure chest map
- [ ] Test suite with all fields

### Community Help Wanted

This is a large reverse engineering task. Community contributions welcome:

1. **Save state donations**: Various game states for comparison
2. **Testing**: Verify findings across different saves
3. **Disassembly**: Help trace save/load routines in ROM
4. **Documentation**: Write up findings
5. **Tool development**: Automated comparison tools

---

## Issue #93: SRAM Editor - Testing and Validation

**Title**: Comprehensive testing of SRAM editor with real save files

**Labels**: `testing`, `validation`, `save-editing`, `priority-medium`

**Description**:

Thoroughly test SRAM editor with real save files from actual gameplay to ensure reliability and data integrity.

### Test Suite Status

**Unit Tests**: ✅ Implemented (`tools/save/test_sram_editor.py`, ~460 lines)

**Test Coverage** (48 test cases):
- [x] Character data structures
- [x] Save slot structures
- [x] Checksum calculation
- [x] Character packing/unpacking
- [x] Value clamping (max limits)
- [x] SRAM file I/O
- [x] JSON export/import
- [x] Data validation
- [x] Edge cases
- [x] Error handling

**Run Unit Tests**:
```bash
python tools/save/test_sram_editor.py
python tools/save/test_sram_editor.py -v
```

### Real-World Testing Needed

**Test Categories**:

1. **Fresh Save Testing**
	- [ ] Extract new game save
	- [ ] Modify character names
	- [ ] Edit starting stats
	- [ ] Verify in-game
	- [ ] Test all 3 save slots

2. **Mid-Game Save Testing**
	- [ ] Extract mid-game save (level 20-40)
	- [ ] Modify gold
	- [ ] Change levels
	- [ ] Edit equipment
	- [ ] Verify in-game

3. **End-Game Save Testing**
	- [ ] Extract end-game save (level 80-99)
	- [ ] Test max values
	- [ ] Modify completion status
	- [ ] Verify in-game

4. **Edge Case Testing**
	- [ ] Corrupted save recovery
	- [ ] Empty slot handling
	- [ ] Checksum fixing
	- [ ] Invalid data handling
	- [ ] Boundary values (0, max)

5. **Roundtrip Testing**
	- [ ] Extract → Edit → Insert → Play
	- [ ] Verify no data loss
	- [ ] Confirm checksum validity
	- [ ] Test all redundant copies (A/B/C)

6. **JSON Editing Testing**
	- [ ] Max gold (9,999,999)
	- [ ] Max level (99)
	- [ ] Max HP (test 999, 9999)
	- [ ] Max stats (99 each)
	- [ ] Name changes (8 char limit)
	- [ ] Position teleporting
	- [ ] Map changing
	- [ ] Play time modification

### Test Matrix

| Save State | Extract | Edit | Insert | Verify | Status |
|------------|---------|------|--------|--------|--------|
| New Game   | ⏳      | ⏳   | ⏳     | ⏳     | Pending |
| Early Game | ⏳      | ⏳   | ⏳     | ⏳     | Pending |
| Mid Game   | ⏳      | ⏳   | ⏳     | ⏳     | Pending |
| End Game   | ⏳      | ⏳   | ⏳     | ⏳     | Pending |
| 100% Save  | ⏳      | ⏳   | ⏳     | ⏳     | Pending |
| Corrupted  | ⏳      | ⏳   | ⏳     | ⏳     | Pending |

### Emulator Testing

**Recommended Emulators**:
- SNES9x (most compatible)
- bsnes (accuracy)
- Mesen-S (debugging features)

**Testing Procedure**:
1. Load original save in emulator
2. Note current state (gold, level, position, etc.)
3. Extract save to JSON
4. Make specific edits
5. Insert back to SRAM
6. Load in emulator
7. Verify changes applied correctly
8. Test gameplay (no crashes, data intact)

### Hardware Testing (Optional)

For ultimate validation:
- [ ] Test with real SNES hardware
- [ ] Use flash cart (Everdrive, SD2SNES)
- [ ] Verify save integrity on cart
- [ ] Test multiple save/load cycles

### Regression Testing

After any tool updates:
- [ ] Re-run all unit tests
- [ ] Re-test known-good saves
- [ ] Verify no regressions
- [ ] Update test suite as needed

### Bug Tracking

Create issues for any failures:
- Checksum mismatches
- Data corruption
- Game crashes
- Incorrect values
- JSON import errors

### Success Criteria

- [ ] All unit tests pass
- [ ] 10+ real saves tested successfully
- [ ] No data loss in roundtrip tests
- [ ] No game crashes from edited saves
- [ ] All documented fields verified
- [ ] Tool marked stable

---

## Issue #94: SRAM Editor - GUI Version (Future Enhancement)

**Title**: Create graphical user interface for SRAM editor

**Labels**: `enhancement`, `gui`, `save-editing`, `future`, `help-wanted`

**Description**:

Develop a user-friendly GUI application for SRAM save editing, making the tool accessible to non-technical users.

### Status

**Priority**: LOW (CLI tool sufficient for now)  
**Timeline**: Future enhancement  
**Dependencies**: Issue #90 (core tool) must be stable

### Proposed Features

**Main Window**:
- [ ] Open .srm file (file picker)
- [ ] Display all 9 save slots
- [ ] Show slot validity (✓/✗)
- [ ] Highlight active slot
- [ ] Slot comparison view

**Slot Editor**:
- [ ] Character 1/2 tabs
	- Name input (8 char limit)
	- Level slider (1-99) with numeric input
	- Experience input (formatted with commas)
	- HP current/max spinboxes
	- Status effect checkboxes
	- Stats sliders (0-99) with current/base
	- Weapon dropdown
- [ ] Party tab
	- Gold input (max 9,999,999)
	- Position X/Y inputs
	- Facing direction dropdown
	- Map ID dropdown (with names if mapped)
	- Play time inputs (HH:MM:SS)
	- Cure count
- [ ] Unknown data hex viewer (read-only)

**Operations**:
- [ ] Extract slot (save to JSON)
- [ ] Import slot (load from JSON)
- [ ] Copy slot (to another slot)
- [ ] Clear slot
- [ ] Verify checksum (with auto-fix button)
- [ ] Backup entire SRAM

**UI Features**:
- [ ] Real-time validation (highlight invalid values)
- [ ] Tooltips with value ranges
- [ ] Undo/redo support
- [ ] Keyboard shortcuts
- [ ] Dark mode support
- [ ] Localization support (EN/JP)

### Technology Options

**Option 1: wxPython**
- Pros: Native look, cross-platform, mature
- Cons: Large dependency

**Option 2: PyQt/PySide**
- Pros: Professional, feature-rich, Qt Designer
- Cons: Licensing (PyQt GPL, PySide LGPL)

**Option 3: tkinter**
- Pros: Built-in, no dependencies
- Cons: Limited features, dated look

**Option 4: Dear PyGui**
- Pros: Modern, GPU-accelerated, immediate mode
- Cons: Different paradigm, less mature

**Recommendation**: PyQt5/PySide6 (best balance)

### Architecture

```python
class SRAMEditorGUI:
	"""Main application window"""
	- open_sram()
	- save_sram()
	- slot_selector: SlotListWidget
	- slot_editor: SlotEditorWidget
	- menu_bar: Menu actions
	- status_bar: Status messages

class SlotListWidget:
	"""Display all 9 slots"""
	- Show validity status
	- Select active slot
	- Quick info display

class SlotEditorWidget:
	"""Edit selected slot"""
	- CharacterEditorWidget × 2
	- PartyEditorWidget
	- UnknownDataViewer

class CharacterEditorWidget:
	"""Edit character data"""
	- Name, level, exp, HP
	- Stats, status, weapon
	- Real-time validation

class PartyEditorWidget:
	"""Edit party data"""
	- Gold, position, map
	- Play time, cure count
```

### Mockup

```
╔══════════════════════════════════════════════════════════════╗
║ File  Edit  Tools  Help                                     ║
╠══════════════════════════════════════════════════════════════╣
║ Open: C:\saves\mysticquest.srm                              ║
╠═══════════╦══════════════════════════════════════════════════╣
║ Slots     ║ Character 1 | Character 2 | Party | Unknown    ║
║           ║                                                  ║
║ ✓ 1A  Lv25║ Name: [Benjamin_______]  Level: [25] [====]    ║
║ ✓ 1B  Lv25║                                                  ║
║ ✓ 1C  Lv25║ Experience: [50,000    ] HP: [320 ] / [320 ]   ║
║           ║                                                  ║
║ ✗ 2A      ║ Status: [ ] Poison  [ ] Dark  [ ] Moogle       ║
║ ✗ 2B      ║         [ ] Mini    [ ] Confusion  [ ] Paralyze║
║ ✗ 2C      ║         [ ] Petrify [ ] Fatal/KO                ║
║           ║                                                  ║
║ ✓ 3A  Lv45║ Stats (Current / Base):                         ║
║ ⚠ 3B  Lv45║   Attack:  [45] / [30]  [=================]    ║
║ ✓ 3C  Lv45║   Defense: [40] / [28]  [===============]      ║
║           ║   Speed:   [38] / [26]  [==============]        ║
║           ║   Magic:   [42] / [32]  [================]      ║
║           ║                                                  ║
║           ║ Weapon: [Steel Sword ▼]  Count: [1]             ║
║           ║                                                  ║
║           ║ [Extract to JSON]  [Import from JSON]           ║
╠═══════════╩══════════════════════════════════════════════════╣
║ Status: Slot 1A selected - Checksum valid (0x3F2A)          ║
╚══════════════════════════════════════════════════════════════╝
```

### Development Phases

**Phase 1: Minimal GUI** (MVP)
- [ ] Basic window with file open/save
- [ ] Slot list view
- [ ] Simple slot editor (text inputs only)
- [ ] Extract/import buttons

**Phase 2: Enhanced Editor**
- [ ] Improved widgets (sliders, dropdowns)
- [ ] Real-time validation
- [ ] Status effect checkboxes
- [ ] Better layout

**Phase 3: Advanced Features**
- [ ] Copy/paste between slots
- [ ] Undo/redo
- [ ] Hex viewer for unknown data
- [ ] Keyboard shortcuts

**Phase 4: Polish**
- [ ] Icons and styling
- [ ] Dark mode
- [ ] Tooltips and help
- [ ] Localization

### Distribution

**Standalone Executable**:
- PyInstaller or cx_Freeze
- Windows .exe
- macOS .app
- Linux AppImage

**Installation**:
- Python package (pip install ffmq-sram-editor)
- Portable ZIP (no install)

### Timeline Estimate

- Phase 1: 20-30 hours
- Phase 2: 15-20 hours
- Phase 3: 10-15 hours
- Phase 4: 10-15 hours
- **Total**: 55-80 hours

**Priority**: Defer until core CLI tool is battle-tested

---

## Summary

**Created**: 5 GitHub issues (#90-#94)

**Status**:
- ✅ Issue #90: Core tool implemented and tested
- ✅ Issue #91: Documentation complete
- ⏳ Issue #92: Research ongoing (help wanted)
- ⏳ Issue #93: Unit tests done, real-world testing needed
- 📋 Issue #94: Future enhancement (low priority)

**Next Steps**:
1. Real-world testing with actual save files (Issue #93)
2. Unknown field research (Issue #92)
3. Consider GUI development (Issue #94) after core stabilizes
