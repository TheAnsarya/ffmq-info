# FFMQ Dialog Toolkit - Quick Reference

## 🚀 Quick Start

```bash
# Launch the complete suite
python launcher.py suite

# List all tools
python launcher.py --list
```

## 🎮 Keyboard Shortcuts

### Dialog Suite
| Key | Action |
|-----|--------|
| `Ctrl+1-7` | Switch tabs |
| `F1` | Help |
| `F5` | Refresh |
| `F11` | Fullscreen |
| `Esc` | Exit fullscreen |

## 🛠️ Available Tools

| Tool | Command | Description |
|------|---------|-------------|
| **Dialog Suite** | `suite` | Complete integrated GUI |
| **Character Table Editor** | `table-editor` | Edit character mappings |
| **Optimizer** | `optimizer` | Analyze and optimize compression |
| **NPC Manager** | `npc-manager` | Link NPCs to dialogs |
| **Search** | `search` | Advanced dialog search |
| **Translator** | `translator` | Translation workflow |
| **Batch Editor** | `batch-editor` | Mass editing operations |
| **Flow Visualizer** | `flow-viz` | Visualize dialog flow |

## 📝 Common Tasks

### Character Table Optimization
```bash
# 1. Run analysis
python launcher.py optimizer

# 2. Review top candidates
# 3. Open character table editor
python launcher.py table-editor

# 4. Add/edit entries
# 5. Save and test
```

### Translation Workflow
```python
# Create project
project = TranslationProject()

# Add glossary
project.glossary.add_entry("Crystal", "Cristal", mandatory=True)

# Translate
project.add_translation(0x0001, "source", "translation", "draft")

# Use memory for suggestions
suggestions = project.memory.find_similar("new text")

# Approve
project.update_translation_status(0x0001, "approved")

# Save
project.save_to_file("translation.json")
```

### Batch Editing
```python
# Find and replace
result = batch_editor.find_and_replace(dialogs, "old", "new")

# Add control codes
result = batch_editor.batch_insert_control_code(dialogs, "[WAIT]", "end")

# Format
result = batch_editor.batch_reformat(dialogs, ["normalize_whitespace", "trim"])

# Find errors
errors = batch_editor.find_potential_errors(dialogs)

# Undo if needed
batch_editor.undo()
```

### Dialog Search
```python
# Text search
results = search_engine.search("Crystal", SearchMode.TEXT)

# Regex search
results = search_engine.search("[A-Z][a-z]+ of", SearchMode.REGEX)

# Fuzzy search (tolerates typos)
results = search_engine.search("Cristal", SearchMode.FUZZY)

# Control code search
results = search_engine.search("WAIT", SearchMode.CONTROL_CODE)
```

## 📊 Character Table Format

```
HEX=STRING
41=A
42=B
F0=the     # Multi-char entry (compression)
F1=[WAIT]  # Control code
```

**Multi-character entries save space:**
- `F0=the ` → 1 byte represents 4 characters
- Saves 3 bytes per occurrence
- Critical for fitting text in limited ROM space

## 🔍 Search Modes

| Mode | Description | Example |
|------|-------------|---------|
| **TEXT** | Simple text search | "Crystal" |
| **REGEX** | Pattern matching | `[A-Z][a-z]+` |
| **FUZZY** | Tolerates typos | "Cristal" finds "Crystal" |
| **CONTROL_CODE** | Find control codes | "WAIT" finds [WAIT] |

## ⚡ Batch Operations

### Find and Replace
```python
# Basic
find_and_replace(dialogs, "old", "new")

# Whole words
find_and_replace(dialogs, "the", "a", whole_words=True)

# Case sensitive
find_and_replace(dialogs, "Crystal", "Gem", case_sensitive=True)

# Regex
find_and_replace(dialogs, r'\b(\w+) of (\w+)\b', r'\2 \1', mode="regex")
```

### Formatting
```python
# Available operations:
- normalize_whitespace  # Fix double spaces, etc.
- remove_trailing_spaces
- remove_leading_spaces  
- normalize_newlines
- trim
- capitalize_sentences
```

### Error Detection
```python
# Detects:
- Unbalanced brackets/parens/quotes
- Double spaces
- Trailing/leading whitespace
- Missing punctuation
- Repeated punctuation
- Long lines (>255)
- Empty dialogs
- Invalid control codes
```

## 📈 Compression Algorithm

**Priority Score:**
```
score = byte_savings×10 + frequency×5 + compression_ratio×2 + length×0.5
```

**Example:**
- Sequence: "the " (4 chars)
- Frequency: 23 occurrences
- Byte savings: 69 bytes (23 × 3)
- Compression ratio: 4.0 (4 chars / 1 byte)
- **Score: 690 + 115 + 8 + 2 = 815**

## 🌍 Translation Memory

**Jaccard Similarity:**
```
similarity = |words_A ∩ words_B| / |words_A ∪ words_B|
```

**Example:**
- Text A: "the crystal awaits"
- Text B: "the crystal calls"
- Shared: {the, crystal} = 2
- Total: {the, crystal, awaits, calls} = 4
- **Similarity: 2/4 = 0.50 (50%)**

Threshold 0.3 returns matches with ≥30% overlap.

## 📂 File Locations

```
tools/map-editor/
├── dialog_suite.py          # Main GUI app
├── launcher.py              # CLI launcher
├── ui/                      # GUI components
│   ├── dialog_browser.py
│   ├── character_table_editor.py
│   ├── tab_system.py
│   └── ...
├── utils/                   # Utilities
│   ├── dialog_database.py
│   ├── character_table_optimizer.py
│   ├── npc_dialog_manager.py
│   ├── dialog_search.py
│   ├── translation_helper.py
│   ├── batch_dialog_editor.py
│   └── dialog_flow_visualizer.py
└── docs/                    # Documentation
    ├── USER_GUIDE.md
    ├── ADVANCED_FEATURES.md
    └── QUICK_REFERENCE.md
```

## 🐛 Troubleshooting

| Problem | Solution |
|---------|----------|
| `pygame not found` | `pip install pygame-ce` |
| `File not found` | Run from `tools/map-editor/` or use full paths |
| Characters garbled | Check character table encoding (UTF-8) |
| Slow performance | Process in batches, use search to filter |

## 💡 Tips

✅ **DO:**
- Keep backups
- Test on small samples first
- Use undo feature
- Run error detection after batch edits
- Save before major operations

❌ **DON'T:**
- Edit ROM directly without backup
- Batch edit all dialogs at once
- Ignore error warnings
- Skip validation
- Forget to save work

## 📚 Learn More

- **Full Guide:** `docs/USER_GUIDE.md`
- **API Reference:** `docs/ADVANCED_FEATURES.md`
- **Source Code:** Inline comments in modules

---

**Version 1.0** | Created for Final Fantasy Mystic Quest ROM hacking
