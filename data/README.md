# FFMQ Data Directory

This directory contains extracted and organized game data from Final Fantasy: Mystic Quest, structured for analysis, modding, and documentation purposes.

## Table of Contents

- [Directory Structure](#directory-structure)
- [Data File Types](#data-file-types)
- [File Naming Conventions](#file-naming-conventions)
- [Data Formats](#data-formats)
- [Using the Data](#using-the-data)
- [Contributing](#contributing)

## Directory Structure

```
data/
├── README.md                 # This file
├── schemas/                  # JSON schemas for data validation
│   ├── character_schema.json
│   ├── enemy_schema.json
│   ├── item_schema.json
│   ├── map_schema.json
│   ├── text_schema.json
│   └── graphics_schema.json
├── characters/              # Character stats, growth, equipment
│   ├── characters.json      # All character data
│   └── stat_growth.json     # Level-up stat progression
├── enemies/                 # Enemy stats, AI, behavior
│   ├── enemies.json         # All enemy data
│   ├── ai_patterns.json     # AI behavior patterns
│   └── formations.json      # Battle formations
├── items/                   # Items, equipment, consumables
│   ├── weapons.json         # Weapon stats and properties
│   ├── armor.json           # Armor stats and properties
│   ├── accessories.json     # Accessory stats and properties
│   └── consumables.json     # Consumable items (potions, etc.)
├── spells/                  # Magic spells and abilities
│   ├── white_magic.json     # White magic spells
│   ├── black_magic.json     # Black magic spells
│   └── wizard_magic.json    # Wizard magic spells
├── maps/                    # Map data, tilemaps, collision
│   ├── map_tilemaps.json    # Map tilemap data (current)
│   ├── world_map.json       # World map configuration
│   ├── towns.json           # Town map data
│   └── dungeons.json        # Dungeon map data
├── text/                    # Dialog, menus, text data
│   ├── text_data.json       # Text and dialog (current)
│   ├── dialog_tree.json     # Dialog branching structure
│   ├── menu_text.json       # Menu strings
│   └── battle_text.json     # Battle messages
├── graphics/                # Graphics data, tiles, palettes
│   ├── tiles/               # Tile data (.bin files)
│   ├── palettes/            # Palette data
│   ├── sprites/             # Sprite data
│   └── metadata.json        # Graphics metadata
├── music/                   # Music and sound data
│   ├── tracks.json          # Music track metadata
│   ├── sfx.json             # Sound effect metadata
│   └── instruments.json     # Instrument definitions
└── extracted/               # Raw extracted data (temporary)
    └── .gitkeep
```

## Data File Types

### JSON Data Files

All structured game data is stored in JSON format for easy parsing and modification:

- **Character Data**: Stats, growth rates, equipment, starting values
- **Enemy Data**: HP, stats, AI patterns, drops, EXP/GP
- **Item Data**: Weapons, armor, accessories, consumables
- **Spell Data**: Magic spells, effects, costs, targeting
- **Map Data**: Tilemaps, collision, events, NPCs
- **Text Data**: Dialog, menus, battle messages
- **Graphics Metadata**: Tile references, palette assignments

### Binary Data Files

Raw graphics and music data preserved in binary format:

- **Tile Data** (.bin): 2bpp/4bpp tile graphics
- **Palette Data** (.bin): SNES 15-bit BGR color palettes
- **Compressed Graphics**: Graphics with compression flags
- **Music Data** (.spc): SPC700 music and sound data

### Schema Files

JSON Schema files validate data structure and enforce consistency:

- Located in `schemas/` directory
- Used by validation tools
- Document required fields and data types
- Enable IDE autocomplete and validation

## File Naming Conventions

### JSON Files

- **Lowercase with underscores**: `enemy_formations.json`
- **Descriptive names**: `character_stat_growth.json` not `stats.json`
- **Plural for collections**: `enemies.json` not `enemy.json`
- **Singular for single entities**: `world_map.json`

### Binary Files

- **Hex address prefix**: `048000-tiles.bin` (ROM address $048000)
- **Descriptive suffix**: `title-screen-crystals-01.bin`
- **Type indicator**: `-tiles.bin`, `-palette.bin`, `-sprite.bin`

### Schema Files

- **Match data file**: `enemies.json` → `enemy_schema.json`
- **Singular form**: `enemy_schema.json` not `enemies_schema.json`
- **_schema suffix**: Always end with `_schema.json`

## Data Formats

### Character Data Format

```json
{
  "id": 0,
  "name": "Benjamin",
  "starting_level": 1,
  "base_stats": {
    "hp": 100,
    "max_hp": 100,
    "white_magic": 10,
    "black_magic": 0,
    "wizard_magic": 0,
    "speed": 10,
    "strength": 12,
    "defense": 10
  },
  "stat_growth": {
    "hp_per_level": 15,
    "white_magic_per_level": 2,
    "speed_per_level": 1,
    "strength_per_level": 2,
    "defense_per_level": 1
  },
  "equipment_slots": ["weapon", "armor", "accessory"],
  "starting_equipment": {
    "weapon": "steel_sword",
    "armor": null,
    "accessory": null
  }
}
```

### Enemy Data Format

```json
{
  "id": 0,
  "name": "Behemoth",
  "stats": {
    "hp": 280,
    "speed": 12,
    "attack": 25,
    "defense": 15,
    "magic_defense": 10
  },
  "ai_pattern": "aggressive_melee",
  "attacks": ["bite", "charge"],
  "weaknesses": ["thunder"],
  "resistances": ["earth"],
  "drops": {
    "exp": 50,
    "gp": 40,
    "items": [
      {"id": "cure_potion", "rate": 0.25}
    ]
  }
}
```

### Map Data Format

```json
{
  "map_id": 0,
  "name": "Foresta",
  "type": "town",
  "dimensions": {
    "width": 32,
    "height": 32
  },
  "tileset_id": 1,
  "music_track": 3,
  "layers": {
    "bg1": "collision and main graphics",
    "bg2": "background decoration",
    "bg3": "text layer"
  },
  "metatiles": {
    "count": 256,
    "format": "16x16 pixels (4x 8x8 tiles)"
  },
  "collision_data": "1 byte per tile",
  "events": [],
  "npcs": [],
  "warps": []
}
```

### Text Data Format

```json
{
  "text_id": 0,
  "bank": "$0d",
  "address": "$0d8000",
  "type": "dialog",
  "speaker": "Old Man",
  "text": "Welcome to Foresta!{NEWLINE}The Crystal is in danger!",
  "control_codes": {
    "NEWLINE": "$01",
    "WAIT": "$02",
    "END": "$00"
  },
  "compressed": true,
  "encoding": "DTE"
}
```

### Graphics Metadata Format

```json
{
  "file": "048000-tiles.bin",
  "rom_address": "$048000",
  "size_bytes": 8192,
  "format": "4bpp",
  "tile_count": 256,
  "usage": "Title screen crystals",
  "palette": 0,
  "compression": "none"
}
```

## Using the Data

### Reading Data Files

All JSON files can be read with standard JSON parsers:

```python
import json

# Load enemy data
with open('data/enemies/enemies.json', 'r') as f:
    enemies = json.load(f)

# Access specific enemy
behemoth = enemies['enemies'][0]
print(f"HP: {behemoth['stats']['hp']}")
```

### Validating Data

Use JSON schemas to validate data structure:

```python
import json
import jsonschema

# Load schema and data
with open('data/schemas/enemy_schema.json', 'r') as f:
    schema = json.load(f)
with open('data/enemies/enemies.json', 'r') as f:
    data = json.load(f)

# Validate
jsonschema.validate(instance=data, schema=schema)
```

### Modifying Data

1. **Edit JSON files directly** in a text editor
2. **Validate changes** against schemas
3. **Test in-game** using build tools
4. **Commit changes** with descriptive messages

### Binary Data

Binary graphics files require special tools:

```bash
# Extract tiles from ROM (example)
python tools/extract_graphics.py --address 0x048000 --size 8192 --output data/graphics/tiles/048000-tiles.bin

# View tiles
python tools/view_tiles.py data/graphics/tiles/048000-tiles.bin --bpp 4 --palette data/graphics/palettes/title.bin
```

## Data Coverage Status

Track extraction progress:

- ✅ **Text Data**: Partial (structure defined, needs population)
- ✅ **Map Tilemaps**: Complete (256 metatiles extracted)
- ✅ **Graphics Tiles**: Partial (title screen tiles extracted)
- ⏳ **Characters**: Not started
- ⏳ **Enemies**: Not started
- ⏳ **Items**: Not started
- ⏳ **Spells**: Not started
- ⏳ **Music**: Not started

See `docs/DATA_STRUCTURES.md` for detailed extraction status and specifications.

## Contributing

### Adding New Data

1. **Determine category**: Which subdirectory does it belong in?
2. **Create schema first**: Define structure in `schemas/`
3. **Extract data**: Use appropriate extraction tools
4. **Validate**: Test against schema
5. **Document**: Update this README and DATA_STRUCTURES.md
6. **Commit**: Use descriptive commit messages

### Data Quality Standards

- **Accuracy**: Data must match ROM exactly
- **Completeness**: Document unknown/unused fields
- **Validation**: All data must pass schema validation
- **Documentation**: Complex structures need inline comments
- **Testing**: Changes must not break ROM build

### Naming Conventions

- Use `snake_case` for all field names
- Use descriptive names: `max_hp` not `mhp`
- Use consistent terminology across all files
- Match in-game names where possible
- Document abbreviations in schemas

## Tools

Data extraction and manipulation tools:

- **tools/extract_text.py**: Extract dialog and text
- **tools/extract_graphics.py**: Extract tiles and palettes
- **tools/extract_maps.py**: Extract map data
- **tools/validate_data.py**: Validate against schemas
- **tools/coverage_report.py**: Generate coverage reports

See `docs/TOOLS.md` for detailed tool documentation.

## Related Documentation

- **docs/DATA_STRUCTURES.md**: Detailed data structure specifications
- **docs/TEXT_SYSTEM.md**: Text encoding and compression
- **docs/GRAPHICS_SYSTEM.md**: Graphics format details
- **docs/MAP_SYSTEM.md**: Map data organization
- **docs/BATTLE_SYSTEM.md**: Battle data structures
- **docs/SOUND_SYSTEM.md**: Music and sound formats
- **docs/MODDING_GUIDE.md**: Using data for mods

## License

All extracted data is for educational and preservation purposes. Original game content © Square Enix.
