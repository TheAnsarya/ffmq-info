# FFMQ Dialog Toolkit - User Guide

Complete guide to using the Final Fantasy Mystic Quest dialog editing toolkit.

## Table of Contents

1. [Quick Start](#quick-start)
2. [Installation](#installation)
3. [Tools Overview](#tools-overview)
4. [Dialog Suite GUI](#dialog-suite-gui)
5. [Character Table Optimization](#character-table-optimization)
6. [Translation Workflow](#translation-workflow)
7. [Batch Editing](#batch-editing)
8. [Advanced Features](#advanced-features)
9. [Troubleshooting](#troubleshooting)

## Quick Start

### Launching the Complete Suite

The easiest way to get started is to launch the comprehensive Dialog Suite GUI:

```bash
python launcher.py suite
```

This launches a tabbed interface with access to all tools.

### Using the Launcher

The launcher provides easy access to all tools:

```bash
# List all available tools
python launcher.py --list

# Launch a specific tool
python launcher.py <tool-name>

# Examples
python launcher.py suite          # Complete GUI
python launcher.py optimizer      # Character table optimizer
python launcher.py table-editor   # Character table editor
```

## Installation

### Requirements

- Python 3.10 or higher
- pygame-ce (for GUI tools)
- Standard library modules (json, pathlib, etc.)

### Setup

1. Create and activate a virtual environment (recommended):

```bash
python -m venv .venv
.venv\Scripts\activate  # Windows
source .venv/bin/activate  # Linux/Mac
```

2. Install dependencies:

```bash
pip install pygame-ce pillow
```

3. Verify installation:

```bash
python launcher.py --list
```

## Tools Overview

### Dialog Suite (`suite`)

**The complete integrated application** - Recommended for most users.

Features:
- Tabbed interface for all tools
- Welcome screen with quick access
- Statistics and analysis
- Character table optimization
- All tools in one place

Launch: `python launcher.py suite`

### Character Table Editor (`table-editor`)

**Visual editor for character encoding tables.**

Features:
- Add/edit/delete character mappings
- Supports multi-character sequences (compression)
- Scrolling list of all entries
- Color-coded display (purple for multi-char, orange for control codes)
- Auto-optimization integration
- Undo/redo support

Launch: `python launcher.py table-editor`

Controls:
- Click entry to select
- "Add New" button to create entry
- "Delete" to remove selected entry
- "Edit" to modify selected entry
- "Optimize" to run auto-optimization
- "Save" to write changes

### Character Table Optimizer (`optimizer`)

**Analyzes dialog corpus and suggests optimal compression sequences.**

Features:
- Analyzes all dialogs to find common patterns
- Identifies n-grams (2-20 character sequences)
- Calculates byte savings for each candidate
- Priority scoring (considers frequency, savings, compression ratio)
- Generates ready-to-use table entries

Launch: `python launcher.py optimizer`

Algorithm:
- Scans corpus for all possible sequences
- Filters by frequency (minimum 3 occurrences)
- Calculates: `priority = byte_savings×10 + frequency×5 + compression_ratio×2 + length×0.5`
- Ranks candidates by priority score

Example output:
```
Top 20 Compression Candidates:
1. 'he Crystal' - 72 bytes saved (freq: 8, score: 785.00)
2. 'you ' - 45 bytes saved (freq: 15, score: 535.00)
3. 'the ' - 69 bytes saved (freq: 23, score: 815.00)
...

Expected compression: 26.9% (733 bytes → 536 bytes)
Total bytes saved: 197
```

### NPC Dialog Manager (`npc-manager`)

**Links NPCs to dialogs with conditional branching logic.**

Features:
- Assign multiple dialogs per NPC
- Flag-based conditional dialogs
- Item-based conditional dialogs
- Event progression support
- Position tracking
- JSON persistence

Launch: `python launcher.py npc-manager`

Dialog priority:
1. Flag-triggered dialogs (highest priority)
2. Item-triggered dialogs
3. Event dialogs
4. Default dialog (fallback)

Example configuration:
```json
{
  "(0, 1)": {
    "npc_name": "Old Man",
    "default_dialog": 1,
    "flag_dialogs": {
      "0x10": 2,
      "0x20": 3
    },
    "item_dialogs": {
      "0x01": 4
    }
  }
}
```

### Dialog Search Engine (`search`)

**Advanced search with multiple modes and relevance scoring.**

Features:
- 4 search modes: TEXT, REGEX, FUZZY, CONTROL_CODE
- Case-sensitive toggle
- Whole-word matching
- Relevance scoring
- Search history
- Duplicate detection
- Smart suggestions

Launch: `python launcher.py search`

Search modes:

**TEXT**: Simple text search with case sensitivity
```python
results = search_engine.search("Crystal", SearchMode.TEXT)
```

**REGEX**: Regular expression patterns
```python
results = search_engine.search("[A-Z][a-z]+ of [A-Z]", SearchMode.REGEX)
```

**FUZZY**: Tolerates small differences (1 error per 4 characters)
```python
results = search_engine.search("Cristal", SearchMode.FUZZY)  # Finds "Crystal"
```

**CONTROL_CODE**: Search for specific control codes
```python
results = search_engine.search("WAIT", SearchMode.CONTROL_CODE)
```

Relevance scoring:
- Match count (40% weight)
- First match position (30% weight) - earlier is better
- Match coverage (30% weight) - more of the text matched

### Translation Helper (`translator`)

**Complete translation workflow with memory and glossary.**

Features:
- Translation memory with fuzzy matching (Jaccard similarity)
- Glossary management for consistent terminology
- Progress tracking (draft/review/approved)
- Batch operations
- Import/export
- Validation and warnings

Launch: `python launcher.py translator`

Workflow:

1. **Create project:**
```python
project = TranslationProject()
project.add_translation(0x0001, "Welcome to the game", "Bienvenido al juego", "draft")
```

2. **Use translation memory:**
```python
suggestions = project.memory.find_similar("Welcome to my game", threshold=0.3)
# Returns: [("Welcome to the game", "Bienvenido al juego", 0.67)]
```

3. **Add glossary terms:**
```python
project.glossary.add_entry("Crystal", "Cristal", mandatory=True)
```

4. **Validate:**
```python
warnings = project.glossary.validate_translation("The crystal awaits", "El gem espera")
# Warning: Missing mandatory term 'Cristal' in translation
```

5. **Track progress:**
```python
stats = project.get_translation_stats()
# {'total': 2, 'draft': 1, 'review': 0, 'approved': 1, 'completion': 50.0}
```

### Batch Dialog Editor (`batch-editor`)

**Mass editing operations across multiple dialogs.**

Features:
- Find and replace (text/regex/whole-words)
- Batch insert control codes
- Batch formatting operations
- Error detection
- Text statistics
- Undo support (50 operations)

Launch: `python launcher.py batch-editor`

Operations:

**Find and Replace:**
```python
result = batch_editor.find_and_replace(
    dialogs, "Crystal", "Gem",
    mode="text", whole_words=True, case_sensitive=True
)
# Returns: BatchEditOperation with affected_dialogs and changes_made
```

**Insert Control Codes:**
```python
result = batch_editor.batch_insert_control_code(
    dialogs, "[WAIT]",
    position="end"  # or "start", "before:text", "after:text"
)
```

**Reformat:**
```python
result = batch_editor.batch_reformat(
    dialogs,
    operations=["normalize_whitespace", "trim", "capitalize_sentences"]
)
```

**Error Detection:**
```python
errors = batch_editor.find_potential_errors(dialogs)
# Returns: {dialog_id: [list of error descriptions]}
```

Error types detected:
- Unbalanced brackets/parentheses/quotes
- Double spaces
- Trailing/leading whitespace
- Missing sentence punctuation
- Repeated punctuation
- Long lines (>255 chars)
- Empty dialogs
- Invalid control codes

**Statistics:**
```python
stats = batch_editor.analyze_text_statistics(dialogs)
```

Returns:
- Total characters/words/lines/dialogs
- Average/min/max length
- Unique word count
- Most common words (Counter)
- Character frequency
- Control code usage

### Dialog Flow Visualizer (`flow-viz`)

**Visualize dialog relationships and conversation flows.**

Features:
- Build dialog flow graphs
- Find conversation paths
- Detect cycles (infinite loops)
- Complexity analysis
- Export to Graphviz DOT format
- Export to Mermaid diagram format

Launch: `python launcher.py flow-viz`

Usage:

1. **Build graph:**
```python
graph = DialogFlowGraph()
graph.add_node(0x0001, next_dialogs=[0x0002])
graph.add_node(0x0002, next_dialogs=[0x0003, 0x0004], flag_requirements={0x10})
```

2. **Find paths:**
```python
paths = graph.find_conversation_paths(0x0001, max_depth=10)
for path in paths:
    print(f"Path: {[f'0x{d:04X}' for d in path.dialogs]}")
    print(f"Requires flags: {path.flags_required}")
```

3. **Analyze complexity:**
```python
metrics = graph.analyze_complexity()
# Returns: {
#   'total_dialogs': 4,
#   'total_connections': 3,
#   'branching_points': 1,
#   'longest_path': 3,
#   'has_cycles': False,
#   ...
# }
```

4. **Export diagrams:**
```python
dot_content = graph.export_to_graphviz()
mermaid_content = graph.export_to_mermaid()
```

Graphviz visualization:
```bash
# Generate graph (requires Graphviz installed)
dot -Tpng dialog_flow.dot -o dialog_flow.png
```

## Dialog Suite GUI

The Dialog Suite provides a comprehensive interface integrating all tools.

### Tabs

**Welcome** (Ctrl+1)
- Feature overview
- Quick access hints
- Keyboard shortcuts

**Browser** (Ctrl+2)
- Browse all dialogs
- Search and filter
- Edit selected dialog

**Statistics** (Ctrl+3)
- Text statistics
- Word frequency analysis
- Error detection
- Press F5 to refresh

**Optimizer** (Ctrl+4)
- Character table optimization
- Compression candidates
- Byte savings estimates
- Press F5 to run analysis

**NPCs** (Ctrl+5)
- NPC dialog management
- Conditional branching
- Position tracking

**Translation** (Ctrl+6)
- Translation memory
- Glossary management
- Progress tracking

**Flow** (Ctrl+7)
- Dialog flow visualization
- Path finding
- Complexity metrics

### Keyboard Shortcuts

Global:
- `Ctrl+1` to `Ctrl+7` - Switch tabs
- `F1` - Help
- `F5` - Refresh/reload current view
- `F11` - Toggle fullscreen
- `Esc` - Exit fullscreen

## Character Table Optimization

### Understanding Compression

Character tables map byte values to text sequences. Multi-character entries compress text:

Standard entry: `41=A` (1 byte → 1 character)
Compressed entry: `F0=the ` (1 byte → 4 characters, saves 3 bytes per occurrence)

### Optimization Workflow

1. **Run Analysis:**
   ```bash
   python launcher.py optimizer
   ```

2. **Review Candidates:**
   - Look for high-frequency sequences
   - Prioritize high byte savings
   - Consider game context (common words/phrases)

3. **Apply to Character Table:**
   - Launch character table editor
   - Add top candidates manually, OR
   - Use "Optimize" button to apply automatically

4. **Verify Compression:**
   - Check statistics for actual byte savings
   - Test in-game to verify display

### Example Optimization

Original table (170 entries):
- Standard ASCII mappings
- Some control codes

After optimization (+20 entries):
- Added "the ", "you ", "and ", etc.
- 26.9% compression achieved
- 197 bytes saved on dialog corpus

## Translation Workflow

### Step-by-Step Translation

1. **Create Project:**
```python
project = TranslationProject()
project.source_language = "en"
project.target_language = "es"
```

2. **Setup Glossary:**
```python
# Add mandatory terms
project.glossary.add_entry("Crystal", "Cristal", mandatory=True)
project.glossary.add_entry("Hero", "Héroe", mandatory=True)

# Add optional terms
project.glossary.add_entry("potion", "poción", mandatory=False, notes="lowercase")
```

3. **Translate Dialogs:**
```python
# Start with draft
project.add_translation(0x0001, "The Crystal awaits you", "El Cristal te espera", "draft")

# Use translation memory for similar text
suggestions = project.memory.find_similar("The Crystal calls to you")
# Returns similar previous translations

# Mark for review
project.update_translation_status(0x0001, "review")

# Approve when ready
project.update_translation_status(0x0001, "approved")
```

4. **Validate:**
```python
# Check for glossary compliance
warnings = project.validate_all_translations()
for dialog_id, warning_list in warnings.items():
    print(f"Dialog 0x{dialog_id:04X}: {', '.join(warning_list)}")
```

5. **Track Progress:**
```python
stats = project.get_translation_stats()
print(f"Progress: {stats['completion']:.1f}% complete")
print(f"Approved: {stats['approved']} / {stats['total']}")
```

6. **Save/Load:**
```python
project.save_to_file("translation_spanish.json")
project = TranslationProject.load_from_file("translation_spanish.json")
```

### Translation Memory

The translation memory uses Jaccard similarity to find similar previous translations:

Similarity = |set(words_A) ∩ set(words_B)| / |set(words_A) ∪ set(words_B)|

Example:
- "the crystal awaits" vs "the crystal calls"
- Shared words: {the, crystal} = 2
- Total unique words: {the, crystal, awaits, calls} = 4
- Similarity: 2/4 = 0.50

Threshold of 0.3 (30%) returns matches with at least 30% word overlap.

## Batch Editing

### Common Batch Operations

**Global Find and Replace:**
```python
# Replace all instances
result = batch_editor.find_and_replace(dialogs, "old", "new")
print(f"Affected {len(result.affected_dialogs)} dialogs")

# Whole words only
result = batch_editor.find_and_replace(dialogs, "the", "a", whole_words=True)

# Case sensitive
result = batch_editor.find_and_replace(dialogs, "Crystal", "Gem", case_sensitive=True)

# Regex patterns
result = batch_editor.find_and_replace(
    dialogs, r'\b(\w+) of (\w+)\b', r'\2 \1',
    mode="regex"
)
```

**Add Control Codes:**
```python
# Add [WAIT] to end of all dialogs
result = batch_editor.batch_insert_control_code(dialogs, "[WAIT]", position="end")

# Add [CLEAR] after specific text
result = batch_editor.batch_insert_control_code(
    dialogs, "[CLEAR]",
    position="after:important phrase"
)
```

**Formatting:**
```python
# Normalize all whitespace
result = batch_editor.batch_reformat(dialogs, ["normalize_whitespace"])

# Multiple operations
result = batch_editor.batch_reformat(dialogs, [
    "normalize_whitespace",
    "trim",
    "capitalize_sentences",
    "remove_trailing_spaces"
])
```

### Error Detection and Cleanup

Run error detection to find issues:

```python
errors = batch_editor.find_potential_errors(dialogs)

for dialog_id, issues in errors.items():
    print(f"\nDialog 0x{dialog_id:04X}:")
    for issue in issues:
        print(f"  - {issue}")
```

Common fixes:
```python
# Fix double spaces
batch_editor.batch_reformat(dialogs, ["normalize_whitespace"])

# Fix trailing spaces
batch_editor.batch_reformat(dialogs, ["remove_trailing_spaces"])

# Fix leading spaces
batch_editor.batch_reformat(dialogs, ["remove_leading_spaces"])

# Fix newlines
batch_editor.batch_reformat(dialogs, ["normalize_newlines"])

# Capitalize sentences
batch_editor.batch_reformat(dialogs, ["capitalize_sentences"])
```

### Undo/Redo

All batch operations support undo:

```python
# Make change
result = batch_editor.find_and_replace(dialogs, "old", "new")

# Undo if needed
if not satisfied:
    batch_editor.undo()
    
# Redo if changed mind
batch_editor.redo()
```

Undo history: 50 operations (configurable)

## Advanced Features

### Custom Control Codes

Define custom control codes in `dialog_database.py`:

```python
CONTROL_CODES = {
    0xF0: "[WAIT]",
    0xF1: "[CLEAR]",
    0xF2: "[NAME]",
    0xF3: "[LINE]",
    0xF4: "[CHOICE]",
    # Add your own
    0xF5: "[CUSTOM]",
}
```

### Dialog Encoding/Decoding

Encode text to bytes:
```python
encoded = encode_text("Hello[WAIT]World", character_table)
# Returns: bytearray with character codes
```

Decode bytes to text:
```python
decoded = decode_text(encoded_bytes, character_table)
# Returns: "Hello[WAIT]World"
```

### ROM Integration

Load dialogs from ROM:
```python
db = DialogDatabase()
db.load_from_rom("ffmq.smc", dialog_pointers)
```

Save dialogs to ROM:
```python
db.save_to_rom("ffmq_modified.smc", dialog_pointers)
```

## Troubleshooting

### pygame Not Found

**Error:** `ModuleNotFoundError: No module named 'pygame'`

**Solution:**
```bash
pip install pygame-ce
```

Make sure you're in the virtual environment if using one.

### File Not Found Errors

**Error:** `FileNotFoundError: [Errno 2] No such file or directory`

**Solution:** Make sure you're running from the correct directory:
```bash
cd tools/map-editor
python launcher.py suite
```

Or use full paths:
```bash
python C:\path\to\tools\map-editor\launcher.py suite
```

### Character Table Issues

**Problem:** Characters not displaying correctly

**Solution:**
1. Verify table file format (HEX=STRING)
2. Check encoding (UTF-8)
3. Verify all entries are valid
4. Test with character table editor

### Dialog Display Issues

**Problem:** Dialogs appear garbled or truncated

**Solution:**
1. Check for invalid control codes
2. Verify maximum line length (usually 255 chars)
3. Check for encoding issues
4. Use error detection in batch editor

### Performance Issues

**Problem:** Slow performance with many dialogs

**Solution:**
1. Process dialogs in batches
2. Use search to filter before editing
3. Close unused tools/windows
4. Increase Python memory if needed

## Tips and Best Practices

### Character Table Optimization

- Run optimization after adding new dialogs
- Prioritize frequently used phrases
- Consider language patterns (articles, prepositions)
- Test in-game after changes
- Keep backup of original table

### Translation

- Use glossary for consistent terminology
- Review translations before approving
- Leverage translation memory for similar text
- Consider text length limits (compressed text expands)
- Test character encoding compatibility

### Batch Editing

- Always test on a few dialogs first (dry run)
- Use undo if results unexpected
- Save before major batch operations
- Combine operations when possible
- Run error detection after changes

### General

- Keep backups of all files
- Use version control (git)
- Test in-game frequently
- Document custom changes
- Share optimized tables with community

## Support and Resources

### Documentation

- `ADVANCED_FEATURES.md` - Detailed technical documentation
- `README.md` - Project overview
- Source code comments - Inline documentation

### Tools Location

All tools are in `tools/map-editor/`:
- `dialog_suite.py` - Main GUI application
- `launcher.py` - Command-line launcher
- `ui/` - GUI components
- `utils/` - Utility modules
- `docs/` - Documentation

### Getting Help

1. Check this user guide
2. Review ADVANCED_FEATURES.md
3. Examine demo code in utility modules
4. Check source code comments

## Appendix: Command Reference

### Launcher Commands

```bash
python launcher.py --list              # List all tools
python launcher.py suite               # Launch Dialog Suite
python launcher.py browser             # Launch Dialog Browser
python launcher.py table-editor        # Launch Character Table Editor
python launcher.py optimizer           # Run Character Table Optimizer
python launcher.py npc-manager         # Launch NPC Dialog Manager
python launcher.py search              # Launch Dialog Search Engine
python launcher.py translator          # Launch Translation Helper
python launcher.py batch-editor        # Launch Batch Dialog Editor
python launcher.py flow-viz            # Launch Dialog Flow Visualizer
python launcher.py format              # Run Tab Formatter
```

### Keyboard Shortcuts

**Dialog Suite:**
- `Ctrl+1` - Welcome tab
- `Ctrl+2` - Browser tab
- `Ctrl+3` - Statistics tab
- `Ctrl+4` - Optimizer tab
- `Ctrl+5` - NPCs tab
- `Ctrl+6` - Translation tab
- `Ctrl+7` - Flow tab
- `F1` - Help
- `F5` - Refresh
- `F11` - Fullscreen
- `Esc` - Exit fullscreen

**Character Table Editor:**
- `Click` - Select entry
- `Double-click` - Edit entry
- `Delete` - Delete selected entry
- `Ctrl+Z` - Undo
- `Ctrl+S` - Save
- `Scroll wheel` - Scroll list

### File Formats

**Character Table (.tbl):**
```
HEX=STRING
41=A
42=B
F0=the 
```

**NPC Configuration (.json):**
```json
{
  "(map_id, npc_id)": {
    "npc_name": "Name",
    "default_dialog": 1,
    "flag_dialogs": {"0x10": 2},
    "item_dialogs": {"0x01": 3}
  }
}
```

**Translation Project (.json):**
```json
{
  "source_language": "en",
  "target_language": "es",
  "translations": {
    "0x0001": {
      "source_text": "Hello",
      "translated_text": "Hola",
      "status": "approved"
    }
  }
}
```

---

*For technical details and API reference, see ADVANCED_FEATURES.md*
