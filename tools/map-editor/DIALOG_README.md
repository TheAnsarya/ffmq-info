# FFMQ Dialog Editor Toolkit

Professional dialog editing tools for Final Fantasy Mystic Quest ROM hacking.

**Part of the FFMQ Map Editor Suite**

## 🌟 Features

- **📝 Dialog Browser** - Browse, search, and edit all game dialogs
- **🔤 Character Table Optimizer** - Automatically find optimal text compression sequences  
- **✏️ Character Table Editor** - Visual editor for character encoding tables
- **👥 NPC Dialog Manager** - Link NPCs to dialogs with conditional branching
- **🔍 Advanced Search** - TEXT, REGEX, FUZZY, and CONTROL_CODE search modes
- **🌍 Translation Tools** - Complete translation workflow with memory and glossary
- **⚙️ Batch Editor** - Mass editing operations with undo support
- **📊 Flow Visualizer** - Visualize and analyze dialog conversation flows
- **📈 Statistics** - Text analysis, word frequency, error detection

## 🚀 Quick Start

### Launch the Dialog Suite

```bash
# Launch the complete suite
python launcher.py suite

# Or launch individual tools
python launcher.py --list           # See all available tools
python launcher.py optimizer        # Character table optimizer
python launcher.py table-editor     # Character table editor
```

## 📚 Documentation

- **[User Guide](docs/USER_GUIDE.md)** - Complete guide with tutorials and workflows
- **[Quick Reference](docs/QUICK_REFERENCE.md)** - Handy reference card
- **[Advanced Features](docs/ADVANCED_FEATURES.md)** - API reference and technical details

## 🎮 Dialog Suite

Unified tabbed interface for all dialog tools with keyboard shortcuts (Ctrl+1-7) and integrated workflows.

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

## 📖 Quick Examples

### Character Table Optimization
```bash
python launcher.py optimizer
# Analyzes dialogs and suggests optimal compression
# Example: 'the ' saves 69 bytes (23 occurrences)
```

### Translation Workflow
```python
project = TranslationProject()
project.glossary.add_entry("Crystal", "Cristal", mandatory=True)
project.add_translation(0x0001, "source", "translation", "draft")
project.save_to_file("translation.json")
```

### Batch Editing
```python
batch_editor.find_and_replace(dialogs, "old", "new")
batch_editor.batch_reformat(dialogs, ["normalize_whitespace", "trim"])
errors = batch_editor.find_potential_errors(dialogs)
```

---

**For complete documentation, see [USER_GUIDE.md](docs/USER_GUIDE.md)**
