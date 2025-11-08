# Advanced Dialog Editor Features

This document describes the advanced features added to the FFMQ Dialog Editor system.

## Table of Contents

1. [Character Table Optimizer](#character-table-optimizer)
2. [Character Table Editor UI](#character-table-editor-ui)
3. [NPC Dialog Manager](#npc-dialog-manager)
4. [Dialog Search Engine](#dialog-search-engine)
5. [Translation Helper](#translation-helper)
6. [Batch Dialog Editor](#batch-dialog-editor)
7. [Dialog Flow Visualizer](#dialog-flow-visualizer)
8. [Tab System](#tab-system)

---

## Character Table Optimizer

**File:** `utils/character_table_optimizer.py`

Analyzes dialog text to suggest optimal multi-character sequences for compression.

### Features

- **Corpus Analysis:** Analyzes all dialogs to find common patterns
- **Automatic Suggestions:** Generates optimal compression candidates
- **Byte Savings Calculation:** Shows how much space each suggestion saves
- **Priority Scoring:** Ranks candidates by compression effectiveness
- **Common Word/Phrase Detection:** Identifies frequently used terms

### Usage

```python
from utils.character_table_optimizer import CharacterTableOptimizer

# Create optimizer
optimizer = CharacterTableOptimizer(min_length=2, max_length=15)

# Analyze dialogs
dialogs = ["Welcome to Foresta!", "The Crystal awaits..."]
candidates = optimizer.analyze_corpus(dialogs)

# View top candidates
for candidate in candidates[:10]:
	print(f"{candidate.sequence}: saves {candidate.byte_savings} bytes")

# Generate table entries
table = optimizer.generate_table_entries(num_entries=50, start_byte=0x40)

# Evaluate compression
stats = optimizer.evaluate_compression(dialogs, table)
print(f"Compression ratio: {stats['compression_ratio']:.2f}x")
print(f"Bytes saved: {stats['bytes_saved']}")
```

### Key Classes

- **`CompressionCandidate`:** Represents a potential multi-char sequence
- **`CharacterTableOptimizer`:** Main optimizer class

### Methods

- `analyze_corpus()`: Find optimal compression candidates
- `find_common_words()`: Extract frequently used words
- `find_common_phrases()`: Extract common 2-4 word phrases
- `generate_table_entries()`: Create character table entries
- `evaluate_compression()`: Measure compression effectiveness
- `export_candidates_report()`: Generate detailed report

---

## Character Table Editor UI

**File:** `ui/character_table_editor.py`

Visual editor for the character table (.tbl file) with support for multi-character sequences.

### Features

- **Visual List:** Browse all character table entries
- **Add/Edit/Delete:** Full CRUD operations for entries
- **Multi-Character Support:** Edit complex multi-character sequences
- **Auto-Optimization:** Integrate with optimizer for suggestions
- **Save/Load:** Direct file manipulation
- **Validation:** Checks for duplicates and errors

### Usage

```python
from ui.character_table_editor import CharacterTableEditor

# Launch editor
editor = CharacterTableEditor("path/to/complex.tbl")
editor.run()
```

### UI Controls

- **Click Entry:** Select for editing
- **Add Button:** Create new entry
- **Update Button:** Modify selected entry
- **Delete Button:** Remove selected entry
- **Save Button:** Write changes to file
- **Auto-Optimize:** Run optimizer and suggest entries
- **Mouse Wheel:** Scroll through entries

### Entry Format

- **Byte Value:** Hex value (00-FF)
- **Sequence:** Text string (can be multi-character)
- **Tags:** [CTRL] for control codes, [MULTI] for multi-char

---

## NPC Dialog Manager

**File:** `utils/npc_dialog_manager.py`

Manages the relationship between NPCs and their dialog text, including conditional dialogs.

### Features

- **NPC Configuration:** Link NPCs to dialogs
- **Conditional Dialogs:** Different dialogs based on flags/items
- **Position Tracking:** Store NPC locations on maps
- **Behavior Settings:** Configure NPC interaction behavior
- **Save/Load:** JSON-based persistence

### Usage

```python
from utils.npc_dialog_manager import NPCDialog, NPCDialogManager

# Create manager
manager = NPCDialogManager()

# Add NPC
npc = NPCDialog(
	npc_id=1,
	map_id=0x01,
	position=(10, 15),
	name="Old Man",
	default_dialog_id=0x0001,
	flag_dialogs={0x10: 0x0002},  # Different dialog if flag 0x10 is set
	repeatable=True
)
manager.add_npc(npc)

# Get active dialog based on game state
flags = {0x10}  # Player has flag 0x10
items = set()
dialog_id = npc.get_active_dialog_id(flags, items)  # Returns 0x0002

# Save configuration
manager.save("npc_dialogs.json")
```

### Key Classes

- **`NPCDialog`:** Configuration for a single NPC
- **`NPCDialogManager`:** Manages all NPCs
- **`NPCDialogPanel`:** UI panel for editing NPC configs

### Dialog Priority

1. Flag-based dialogs (highest priority)
2. Item-based dialogs
3. Event dialog
4. Default dialog (fallback)

---

## Dialog Search Engine

**File:** `utils/dialog_search.py`

Advanced search capabilities for finding dialogs with various criteria.

### Features

- **Multiple Search Modes:** Text, regex, fuzzy, control code
- **Relevance Scoring:** Results ranked by match quality
- **Search History:** Remembers previous searches
- **Suggestions:** Auto-complete for search terms
- **Advanced Filters:** By NPC, map, length, control codes
- **Duplicate Detection:** Find similar/identical dialogs

### Usage

```python
from utils.dialog_search import DialogSearchEngine, SearchMode

engine = DialogSearchEngine()

# Text search
results = engine.search(dialogs, "Crystal", SearchMode.TEXT)
for result in results:
	print(f"Dialog 0x{result.dialog_id:04X}: {result.context}")

# Regex search
results = engine.search(dialogs, r'\b[A-Z]\w+ of \w+', SearchMode.REGEX)

# Control code search
results = engine.search(dialogs, "WAIT", SearchMode.CONTROL_CODE)

# Fuzzy search (allows typos)
results = engine.search(dialogs, "Crytal", SearchMode.FUZZY)

# Advanced searches
long_dialogs = engine.search_by_length(dialogs, min_length=100)
wait_dialogs = engine.search_by_control_codes(dialogs, has_codes=["WAIT"])
duplicates = engine.find_duplicates(dialogs)

# Get suggestions
suggestions = engine.get_search_suggestions("Cry", dialogs)
```

### Search Modes

- **TEXT:** Plain text substring search
- **REGEX:** Regular expression patterns
- **FUZZY:** Allows character differences (typo tolerance)
- **CONTROL_CODE:** Find specific control codes

---

## Translation Helper

**File:** `utils/translation_helper.py`

Comprehensive tools for translating FFMQ dialogs into other languages.

### Features

- **Translation Memory:** Remembers previously translated phrases
- **Glossary Management:** Consistent terminology
- **Progress Tracking:** Monitor translation status
- **Validation:** Checks for mandatory terms
- **Multiple Formats:** Save/load translation projects

### Usage

```python
from utils.translation_helper import TranslationProject, TranslationEntry, GlossaryEntry

# Create project
project = TranslationProject("FFMQ Spanish Translation")
project.source_language = "English"
project.target_language = "Spanish"

# Add glossary terms
project.glossary.add_entry(GlossaryEntry(
	source_term="Crystal",
	target_term="Cristal",
	category="item",
	mandatory=True
))

# Add translation
entry = TranslationEntry(
	dialog_id=0x0001,
	original_text="Welcome to Foresta! The Crystal awaits.",
	translated_text="¡Bienvenido a Foresta! El Cristal te espera.",
	status="approved",
	translator="Alice"
))
project.add_translation(entry)

# Check progress
progress = project.get_progress()
print(f"Complete: {progress['percent_complete']:.1f}%")

# Get suggestions from memory
suggestions = project.memory.find_similar("The Crystal")

# Validate translation
warnings = project.glossary.validate_translation(original, translated)

# Save project
project.save("translation_project.json")
```

### Key Classes

- **`TranslationProject`:** Complete translation project
- **`TranslationMemory`:** Stores phrase translations
- **`TranslationGlossary`:** Manages terminology
- **`TranslationEntry`:** Individual dialog translation

### Translation Status

- **draft:** Initial translation
- **review:** Ready for review
- **approved:** Finalized translation

---

## Batch Dialog Editor

**File:** `utils/batch_dialog_editor.py`

Tools for editing multiple dialogs simultaneously.

### Features

- **Find and Replace:** Across all dialogs
- **Batch Control Code Operations:** Add/remove codes
- **Formatting:** Normalize whitespace, capitalization
- **Error Detection:** Find common issues
- **Statistics:** Analyze dialog corpus
- **Undo Support:** Revert batch operations

### Usage

```python
from utils.batch_dialog_editor import BatchDialogEditor

editor = BatchDialogEditor()

# Find and replace
result = editor.find_and_replace(
	dialogs,
	find="Crystal",
	replace="Gem",
	case_sensitive=False,
	whole_words=True
)
print(f"Changed {result.changes_made} instances in {len(result.affected_dialogs)} dialogs")

# Batch insert control code
result = editor.batch_insert_control_code(
	dialogs,
	position="end",
	control_code="[WAIT]"
)

# Batch reformat
result = editor.batch_reformat(
	dialogs,
	operations=["normalize_whitespace", "trim", "capitalize_sentences"]
)

# Analyze statistics
stats = editor.analyze_text_statistics(dialogs)
print(f"Total words: {stats['total_words']}")
print(f"Average length: {stats['average_length']:.1f} chars")
print(f"Most common: {stats['most_common_words'][:5]}")

# Find errors
errors = editor.find_potential_errors(dialogs)
for dialog_id, issues in errors.items():
	print(f"Dialog 0x{dialog_id:04X}: {issues}")

# Undo last operation
editor.undo(dialogs)
```

### Formatting Operations

- **normalize_whitespace:** Multiple spaces → single space
- **remove_trailing_spaces:** Remove end-of-line spaces
- **remove_leading_spaces:** Remove start-of-line spaces
- **normalize_newlines:** Consistent line endings
- **trim:** Remove leading/trailing whitespace
- **capitalize_sentences:** Capitalize first letter

### Error Detection

- Unbalanced control code brackets
- Double spaces
- Trailing/leading spaces
- Missing punctuation
- Repeated punctuation
- Malformed control codes

---

## Dialog Flow Visualizer

**File:** `utils/dialog_flow_visualizer.py`

Visualize dialog relationships and conversation flows.

### Features

- **Flow Graph:** Visual representation of dialog connections
- **Path Finding:** Find all possible conversation paths
- **Complexity Analysis:** Measure conversation complexity
- **Export Formats:** Graphviz DOT, Mermaid
- **NPC Conversation Trees:** Complete dialog trees per NPC
- **Cycle Detection:** Find circular dialog references

### Usage

```python
from utils.dialog_flow_visualizer import DialogFlowGraph, DialogNode

# Create graph
graph = DialogFlowGraph()

# Add nodes
graph.add_node(DialogNode(
	dialog_id=0x0001,
	text_preview="Welcome!",
	npc_id=1,
	is_entry_point=True
))

graph.add_node(DialogNode(
	dialog_id=0x0002,
	text_preview="Goodbye!",
	npc_id=1,
	is_terminal=True
))

# Add edges
graph.add_edge(0x0001, 0x0002, "First talk")

# Find all paths
paths = graph.find_all_paths(0x0001)
for path in paths:
	print(f"Path: {' -> '.join(f'0x{d:04X}' for d in path.dialogs)}")

# Analyze complexity
complexity = graph.analyze_complexity()
print(f"Total dialogs: {complexity['total_dialogs']}")
print(f"Branching points: {complexity['branching_points']}")
print(f"Longest path: {complexity['longest_path']}")

# Export to Graphviz
graph.export_to_graphviz("dialog_flow.dot")

# Export to Mermaid
graph.export_to_mermaid("dialog_flow.mmd")
```

### Graph Features

- **Entry Points:** Dialogs with no predecessors (green)
- **Terminal Nodes:** Dialogs with no successors (red)
- **Branching:** Dialogs with multiple possible next dialogs
- **Labeled Edges:** Show conditions (flags, items)

### Export Formats

**Graphviz DOT:**
```
digraph DialogFlow {
  n0001 [label="0001: Welcome!", style=filled, fillcolor=lightgreen];
  n0002 [label="0002: Goodbye!", style=filled, fillcolor=lightcoral];
  n0001 -> n0002 [label="First talk"];
}
```

**Mermaid:**
```
graph TD
  0001(("0001: Welcome!"))
  0002{"0002: Goodbye!"}
  0001 -->|First talk| 0002
```

---

## Tab System

**File:** `ui/tab_system.py`

Tabbed interface system for organizing different editing modes.

### Features

- **Multiple Tabs:** Switch between different views
- **Keyboard Shortcuts:** Ctrl+1-9 for quick switching
- **Visual Indicators:** Shows active tab
- **Flexible Panels:** Each tab can have different content
- **Event Handling:** Manages events for active panel

### Usage

```python
from ui.tab_system import TabbedPanel, Tab

# Create tabbed panel
panel_rect = pygame.Rect(50, 50, 900, 600)
tabbed_panel = TabbedPanel(panel_rect, tab_height=50)

# Add tabs
tabbed_panel.add_tab(
	Tab("map", "Map Editor", "🗺", True, "Edit map tiles"),
	panel_object=map_editor_panel
)

tabbed_panel.add_tab(
	Tab("dialog", "Dialogs", "💬", True, "Edit dialog text"),
	panel_object=dialog_editor_panel
)

# Handle events
for event in pygame.event.get():
	tabbed_panel.handle_event(event)

# Update and draw
tabbed_panel.update(dt)
tabbed_panel.draw(screen, font)

# Get active tab
active_tab = tabbed_panel.tab_bar.get_active_tab()
print(f"Active: {active_tab.title}")

# Set callback for tab changes
def on_tab_changed(index, tab_id):
	print(f"Switched to {tab_id}")

tabbed_panel.tab_bar.on_tab_changed = on_tab_changed
```

### Keyboard Shortcuts

- **Ctrl+1:** First tab
- **Ctrl+2:** Second tab
- **Ctrl+3:** Third tab
- (etc...)

### Tab Properties

- **id:** Unique identifier
- **title:** Display name
- **icon:** Optional icon character
- **enabled:** Whether tab is clickable
- **tooltip:** Hover text

---

## Integration

All these features integrate seamlessly with the main dialog editor system:

1. **Character Table Optimizer** → feeds suggestions to **Character Table Editor UI**
2. **NPC Dialog Manager** → provides data for **Dialog Flow Visualizer**
3. **Dialog Search Engine** → helps users find dialogs to edit
4. **Translation Helper** → uses **Batch Dialog Editor** for mass operations
5. **Tab System** → organizes all tools in a unified interface

### Complete Workflow Example

```python
# 1. Analyze and optimize character table
optimizer = CharacterTableOptimizer()
candidates = optimizer.analyze_corpus(all_dialogs)
table = optimizer.generate_table_entries(50)

# 2. Edit table with UI
editor = CharacterTableEditor()
editor.run()  # User adds optimized entries

# 3. Set up NPC dialogs
npc_manager = NPCDialogManager()
npc_manager.add_npc(NPCDialog(...))

# 4. Search for dialogs to translate
search_engine = DialogSearchEngine()
results = search_engine.search(dialogs, "Crystal")

# 5. Translate dialogs
translation = TranslationProject()
translation.add_translation(TranslationEntry(...))

# 6. Batch edit for consistency
batch_editor = BatchDialogEditor()
batch_editor.find_and_replace(dialogs, "Crystal", "Cristal")

# 7. Visualize conversation flow
flow_graph = DialogFlowGraph()
flow_graph.build_from_event_scripts(scripts)
flow_graph.export_to_graphviz("flow.dot")
```

---

## Performance Notes

- **Character Table Optimizer:** O(n×m) where n = corpus size, m = max sequence length
- **Search Engine:** O(n×k) where n = number of dialogs, k = average dialog length
- **Flow Visualizer:** O(n+e) where n = nodes, e = edges (standard graph operations)
- **Batch Operations:** O(n×m) where n = number of dialogs, m = operation complexity

---

## Future Enhancements

Potential additions:

1. **Machine Translation Integration:** Google Translate API
2. **Spell Checker:** PyEnchant integration
3. **Voice Acting Support:** TTS preview
4. **Collaborative Translation:** Multi-user editing
5. **Version Control:** Git integration for translations
6. **Analytics Dashboard:** Visual statistics
7. **Template System:** Reusable dialog patterns
8. **Localization Testing:** In-game preview

---

## See Also

- [DIALOG_EDITOR_GUIDE.md](DIALOG_EDITOR_GUIDE.md) - Main user guide
- [API.md](API.md) - API reference
- [DEVELOPMENT.md](DEVELOPMENT.md) - Development guide
