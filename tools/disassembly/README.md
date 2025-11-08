# Disassembly Tools

This directory contains tools for disassembling ROMs, applying labels, and managing disassembly projects.

## Core Disassembly Tools

### Python Tools
- **mass_disassemble.py** - Batch disassembly of ROM sections
  - Disassemble multiple banks at once
  - Automatic label generation
  - Output to organized file structure
  - Progress tracking and logging
  - Usage: `python tools/disassembly/mass_disassemble.py --banks 00-0F --output src/`

- **convert_diztinguish.py** - Convert Diztinguish markup to assembly
  - Imports Diztinguish project files
  - Converts annotations to comments
  - Preserves label information
  - Generates buildable assembly
  - Usage: `python tools/disassembly/convert_diztinguish.py --input project.diz --output src/`

## PowerShell Disassembly Scripts

### Automated Disassembly
- **Aggressive-Disassemble.ps1** - Aggressive disassembly with heuristics
  - Uses multiple disassembly strategies
  - Attempts automatic code/data separation
  - Generates comprehensive label set
  - Creates detailed annotations
  - Usage: `.\tools\disassembly\Aggressive-Disassemble.ps1 -RomFile <rom.smc> -Output src\`

### Reference Integration
- **Import-Reference-Disassembly.ps1** - Import from reference disassembly
  - Imports labels from reference projects
  - Merges with existing disassembly
  - Preserves local modifications
  - Updates cross-references
  - Usage: `.\tools\disassembly\Import-Reference-Disassembly.ps1 -Reference <path> -Target src\`

### Label Management
- **apply_labels.ps1** - Apply label definitions to assembly
  - Imports labels from CSV/JSON
  - Updates assembly with new labels
  - Renames references throughout
  - Validates label uniqueness
  - Usage: `.\tools\disassembly\apply_labels.ps1 -Labels <labels.csv> -Source src\`

## Common Workflows

### Complete ROM Disassembly
```powershell
# 1. Initial aggressive disassembly
.\tools\disassembly\Aggressive-Disassemble.ps1 -RomFile roms\original.smc -Output src\initial\

# 2. Import any reference labels
.\tools\disassembly\Import-Reference-Disassembly.ps1 -Reference reference\ffmq\ -Target src\

# 3. Apply custom labels
.\tools\disassembly\apply_labels.ps1 -Labels data\custom_labels.csv -Source src\

# 4. Verify buildability
python tools/build/build_rom.py
python tools/build/compare_roms.py roms/original.smc build/output.smc
```

### Bank-by-Bank Disassembly
```bash
# Disassemble specific banks
python tools/disassembly/mass_disassemble.py --banks 00,01,02 --output src/

# Disassemble range
python tools/disassembly/mass_disassemble.py --banks 00-0F --output src/

# Disassemble with labels
python tools/disassembly/mass_disassemble.py --banks 03 --labels data/bank03_labels.json --output src/
```

### Import from Diztinguish
```bash
# Convert Diztinguish project
python tools/disassembly/convert_diztinguish.py --input ffmq.diz --output src/

# Import specific banks
python tools/disassembly/convert_diztinguish.py --input ffmq.diz --banks 00-03 --output src/

# Preserve existing work
python tools/disassembly/convert_diztinguish.py --input ffmq.diz --output src/ --merge
```

### Label Management
```powershell
# Apply labels from CSV
.\tools\disassembly\apply_labels.ps1 -Labels labels\battle_functions.csv -Source src\

# Apply from JSON
.\tools\disassembly\apply_labels.ps1 -Labels labels\all_labels.json -Source src\

# Validate labels before applying
.\tools\disassembly\apply_labels.ps1 -Labels labels\new_labels.csv -Source src\ -ValidateOnly
```

## Disassembly Strategies

### Strategy 1: Linear Disassembly
- Start at known entry points
- Follow execution flow
- Mark code vs data
- Generate labels for branches

### Strategy 2: Heuristic Analysis
- Identify code patterns
- Detect data structures
- Find function boundaries
- Infer jump tables

### Strategy 3: Reference-Based
- Import from known-good disassembly
- Validate against ROM
- Merge with local work
- Update documentation

### Strategy 4: Interactive
- Use Diztinguish for manual markup
- Review auto-generated labels
- Refine code/data boundaries
- Add semantic labels

## Label File Formats

### CSV Format
```csv
Address,Label,Comment,Bank
8000,MainGameLoop,Primary game loop,00
8100,InitializeSystem,System initialization,00
C000,BattleEngine_Start,Start battle sequence,02
```

### JSON Format
```json
{
    "labels": [
        {
            "address": "0x008000",
            "label": "MainGameLoop",
            "comment": "Primary game loop",
            "bank": "00",
            "type": "function"
        },
        {
            "address": "0x008100",
            "label": "InitializeSystem",
            "comment": "System initialization",
            "bank": "00",
            "type": "function"
        }
    ]
}
```

### Diztinguish Format
See Diztinguish documentation for .diz file format.

## Disassembler Configuration

### disasm_config.json
```json
{
    "architecture": "65816",
    "rom_type": "lorom",
    "entry_points": [
        {"address": "0x008000", "bank": "00", "name": "Reset"},
        {"address": "0x00FFE4", "bank": "00", "name": "COP"},
        {"address": "0x00FFE8", "bank": "00", "name": "BRK"}
    ],
    "data_regions": [
        {"start": "0x0C8000", "end": "0x0CFFFF", "type": "graphics"},
        {"start": "0x10C000", "end": "0x10FFFF", "type": "text"}
    ],
    "output": {
        "format": "asm",
        "split_banks": true,
        "include_hex": true,
        "label_style": "descriptive"
    }
}
```

## Label Naming Conventions

### Function Labels
```asm
; Pattern: Category_Action[_Detail]
BattleEngine_Initialize
Graphics_LoadSprite
Input_ReadController
Menu_DisplayOptions
```

### Data Labels
```asm
; Pattern: DataType_Purpose[_Detail]
EnemyData_HPValues
TextPointers_Dialogue
GraphicsData_PlayerSprites
SoundData_MusicTracks
```

### Local Labels
```asm
; Pattern: .lowercase_descriptor
.loop
.skip_zero
.load_next
.done
```

## Disassembly Quality Metrics

### Code Coverage
- Percentage of ROM disassembled
- Code vs data identification accuracy
- Label completeness

### Label Quality
- Descriptive vs generic names
- Naming convention compliance
- Documentation completeness

### Buildability
- Can disassembly reassemble?
- Byte-perfect match with original?
- All references resolved?

## Dependencies

- Python 3.7+
- PowerShell 5.1+ (for .ps1 scripts)
- **Diztinguish** (optional, for .diz import)
- Disassembler tool (asar, WLA-DX, or similar)

## See Also

- **tools/build/** - For reassembling disassembly
- **tools/formatting/** - For formatting disassembled code
- **tools/analysis/** - For analyzing disassembly quality
- **docs/technical/DISASSEMBLY_GUIDE.md** - Disassembly guide
- **Diztinguish** - https://github.com/IsoFrieze/DiztinGUIsh

## Tips and Best Practices

### Starting a Disassembly
1. Get clean reference ROM
2. Identify ROM mapping (LoROM/HiROM)
3. Find entry points (reset vector, interrupts)
4. Start with known code sections
5. Use existing documentation

### Code vs Data Separation
- Look for RTS/RTL/RTI patterns (code)
- Check for pointer tables
- Identify graphics compression
- Find text strings
- Mark music/sound data

### Label Creation
- Start with addresses (Label_8000)
- Refine to descriptive names
- Document purpose in comments
- Follow naming conventions
- Keep labels unique

### Validation
- Build after each major change
- Compare with original ROM
- Test in emulator
- Check all references resolve
- Verify data integrity

## Troubleshooting

**Issue: Disassembly produces unbuildable code**
- Solution: Check code/data boundaries, verify bank mapping

**Issue: Labels conflict**
- Solution: Use unique suffixes, check for duplicates

**Issue: Reference import fails**
- Solution: Verify reference format matches, check bank mapping

**Issue: Build output differs from original**
- Solution: Check data alignment, verify no data reordering

## Advanced Techniques

### Automated Pattern Recognition
```python
from tools.disassembly.mass_disassemble import PatternRecognizer

recognizer = PatternRecognizer(rom_data)
functions = recognizer.find_functions()
data_tables = recognizer.find_data_tables()
jump_tables = recognizer.find_jump_tables()
```

### Custom Label Generation
```python
from tools.disassembly.mass_disassemble import LabelGenerator

generator = LabelGenerator()
generator.add_naming_rule("battle", "^C[0-9A-F]{4}", "Battle_")
generator.add_naming_rule("graphics", "^0C[0-9A-F]{4}", "Graphics_")
labels = generator.generate(rom_data)
```

### Merge Disassemblies
```powershell
# Merge two disassembly projects
.\tools\disassembly\merge_disassemblies.ps1 `
    -Source1 src\version1\ `
    -Source2 src\version2\ `
    -Output src\merged\ `
    -PreferSource1Labels
```

## Contributing

When adding disassembly tools:
1. Preserve original ROM data
2. Generate buildable output
3. Document disassembly strategies
4. Add validation checks
5. Support standard label formats
6. Include progress tracking
7. Update this README

## Future Development

Planned additions:
- [ ] AI-assisted code/data separation
- [ ] Automatic function signature detection
- [ ] Cross-reference graph visualization
- [ ] Interactive disassembly browser
- [ ] Collaborative disassembly features
- [ ] Version control integration
- [ ] Real-time build verification
