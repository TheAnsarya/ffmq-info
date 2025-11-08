# Battle Data Tools

This directory contains tools for working with Final Fantasy Mystic Quest's battle system, including enemy data, spells, attacks, and combat mechanics.

## Core Tools

### Enemy Management
- **enemy_editor_gui.py** ⭐ - GUI application for editing enemy data
  - Interactive interface for modifying enemy stats, AI, drops, and weaknesses
  - Real-time validation and preview
  - Export/import functionality
  - Usage: `python tools/battle/enemy_editor_gui.py`

- **view_enemy.py** - Command-line enemy data viewer
  - Display detailed enemy statistics
  - Export enemy data to JSON/CSV
  - Compare multiple enemies
  - Usage: `python tools/battle/view_enemy.py <enemy_id>`

### Attack and Battle Data
- **generate_attack_table.py** - Generate attack lookup tables
  - Creates assembly tables for enemy attacks
  - Validates attack references
  - Generates documentation
  - Usage: `python tools/battle/generate_attack_table.py`

- **integrate_battle_data.py** - Integrate battle data into ROM
  - Imports modified battle data
  - Validates data integrity
  - Updates ROM with new battle parameters
  - Usage: `python tools/battle/integrate_battle_data.py --input <data.json>`

### Spell System

#### Analysis Tools
- **analyze_spell_flags.py** - Analyze spell flag bytes
  - Decodes spell behavior flags
  - Documents flag combinations
  - Identifies unknown flags
  - Usage: `python tools/battle/analyze_spell_flags.py`

- **analyze_spell_structure.py** - Analyze spell data structure
  - Maps spell data layout
  - Identifies data patterns
  - Generates structure documentation
  - Usage: `python tools/battle/analyze_spell_structure.py`

- **analyze_spell_unknown_bytes.py** - Investigate unknown spell bytes
  - Research unexplained data fields
  - Test hypotheses about byte meanings
  - Track findings across ROM versions
  - Usage: `python tools/battle/analyze_spell_unknown_bytes.py`

#### Research and Validation
- **find_spell_data.py** - Locate spell data in ROM
  - Search for spell-related data
  - Identify data structures
  - Map memory locations
  - Usage: `python tools/battle/find_spell_data.py [--pattern <hex>]`

- **spell_research_report.py** - Generate spell research documentation
  - Compile research findings
  - Create comprehensive reports
  - Track research progress
  - Usage: `python tools/battle/spell_research_report.py --output <report.md>`

- **test_spell_learning_hypothesis.py** - Test spell learning theories
  - Validate spell learning mechanics
  - Test level requirements
  - Document findings
  - Usage: `python tools/battle/test_spell_learning_hypothesis.py`

- **verify_spell_data.py** - Validate spell data integrity
  - Check spell data consistency
  - Validate references
  - Report errors
  - Usage: `python tools/battle/verify_spell_data.py`

## Common Workflows

### Editing Enemy Data
```bash
# Method 1: GUI Editor (recommended for most users)
python tools/battle/enemy_editor_gui.py

# Method 2: View specific enemy data
python tools/battle/view_enemy.py 42  # View enemy ID 42

# Method 3: Batch modification via JSON
python tools/battle/view_enemy.py --export enemies.json
# Edit enemies.json
python tools/battle/integrate_battle_data.py --input enemies.json
```

### Spell Research Workflow
```bash
# 1. Find spell data locations
python tools/battle/find_spell_data.py

# 2. Analyze spell structure
python tools/battle/analyze_spell_structure.py

# 3. Investigate flags
python tools/battle/analyze_spell_flags.py

# 4. Test hypotheses
python tools/battle/test_spell_learning_hypothesis.py

# 5. Generate report
python tools/battle/spell_research_report.py --output spell_report.md

# 6. Validate final data
python tools/battle/verify_spell_data.py
```

### Creating Custom Attacks
```bash
# 1. Generate attack table template
python tools/battle/generate_attack_table.py --template

# 2. Edit attack data in generated JSON

# 3. Integrate into ROM
python tools/battle/integrate_battle_data.py --attacks custom_attacks.json

# 4. Verify integration
python tools/battle/verify_spell_data.py
```

## Data Formats

### Enemy Data Structure
```python
{
    "id": 0,
    "name": "Enemy Name",
    "hp": 1000,
    "defense": 50,
    "attack": 75,
    "speed": 100,
    "magic": 50,
    "weaknesses": ["fire", "ice"],
    "resistances": ["poison"],
    "drops": [
        {"item_id": 5, "rate": 25},
        {"item_id": 10, "rate": 10}
    ],
    "attacks": [0x01, 0x05, 0x0A],
    "ai_pattern": 0x00
}
```

### Spell Data Structure
```python
{
    "id": 0,
    "name": "Spell Name",
    "power": 100,
    "element": "fire",
    "target": "single",
    "mp_cost": 10,
    "flags": 0x42,  # Behavior flags
    "animation": 0x05,
    "learn_level": 15
}
```

### Attack Data Structure
```python
{
    "id": 0,
    "name": "Attack Name",
    "power": 50,
    "element": "physical",
    "target_type": "single",
    "accuracy": 95,
    "flags": 0x00,
    "animation": 0x01,
    "status_effects": ["poison", "sleep"]
}
```

## Dependencies

- Python 3.7+
- `tkinter` (for enemy_editor_gui.py)
- `json` (standard library)
- `struct` (standard library)
- ROM file access modules from `tools/rom-operations/`

## See Also

- **tools/graphics/** - For editing battle graphics and sprites
- **tools/data-extraction/** - For extracting original battle data
- **tools/validation/** - For validating modified battle data
- **docs/technical/BATTLE_SYSTEM.md** - Battle system documentation
- **docs/rom-hacking/ENEMY_DATA.md** - Enemy data format reference

## Tips and Best Practices

### Enemy Editing
- Always backup ROM before making changes
- Use GUI editor for single enemy modifications
- Use JSON import for batch modifications
- Verify changes with `verify_spell_data.py` before testing
- Test in emulator after each modification

### Spell Research
- Start with `analyze_spell_structure.py` for overview
- Use `find_spell_data.py` to locate related data
- Document findings in spell_research_report
- Cross-reference with DataCrystal wiki data
- Test hypotheses in emulator

### Attack Creation
- Base new attacks on existing templates
- Maintain consistent power scaling
- Test element interactions thoroughly
- Verify animation IDs exist
- Check status effect compatibility

## Troubleshooting

**Issue: Enemy editor won't launch**
- Solution: Ensure tkinter is installed: `pip install tk`

**Issue: Changes don't appear in ROM**
- Solution: Check ROM is not read-only, verify integration logs

**Issue: Invalid spell data errors**
- Solution: Run `verify_spell_data.py` to identify issues

**Issue: Attack animations crash game**
- Solution: Verify animation ID exists in graphics data

## Contributing

When adding new battle tools:
1. Follow naming convention: `<action>_<entity>.py`
2. Add comprehensive docstrings
3. Update this README with tool description
4. Add usage examples
5. Document data formats if introducing new ones
6. Add validation for all user inputs
7. Create tests in `tools/testing/`

## Future Development

Planned additions:
- [ ] Battle AI editor
- [ ] Formation editor
- [ ] Status effect editor
- [ ] Battle script decompiler
- [ ] Damage formula calculator
- [ ] Enemy stat balancing tool
- [ ] Battle simulator for testing
