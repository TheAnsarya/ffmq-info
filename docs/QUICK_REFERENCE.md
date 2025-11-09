# FFMQ Editor Quick Reference

## Quick Start

### Run Main Editor
```powershell
python tools/map-editor/game_editor.py path/to/ffmq.smc
```

### Run Graphics Editor
```powershell
python tools/map-editor/graphics_editor.py path/to/ffmq.smc
```

### Run Music Editor
```powershell
python tools/map-editor/music_editor.py path/to/ffmq.smc
```

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+S` | Save ROM |
| `Ctrl+O` | Open ROM |
| `Ctrl+1-8` | Switch to tab 1-8 |
| `F1` | Toggle statistics |
| `ESC` | Quit editor |

---

## Graphics Quick Reference

### ROM Addresses
```python
TILESET_BASE  = 0x080000  # Character tileset (256 tiles)
PALETTE_BASE  = 0x0C0000  # All palettes
SPRITE_BASE   = 0x0A0000  # Sprite metadata
```

### Palette IDs
- 0-7: Character palettes
- 8-23: Enemy palettes

### Color Format
- **SNES**: 15-bit BGR555 (0BBBBBGGGGGRRRRR)
- **Editor**: 24-bit RGB888 (for easy editing)

### Tile Format
- Size: 8×8 pixels
- Format: 4bpp planar (16 colors)
- Storage: 32 bytes per tile

### Quick Actions
```python
# Export palette
db.export_palette_to_image(0, "palette.png")

# Export tileset
db.export_tileset_to_image(0, 0, "tiles.png")

# Import palette
db.import_palette_from_image(0, "custom.png")

# Optimize palette
db.optimize_palette(0)
```

---

## Music Quick Reference

### ROM Addresses
```python
MUSIC_TABLE_BASE  = 0x0D8000  # Track pointers (32 tracks)
SFX_TABLE_BASE    = 0x0DA000  # SFX pointers (64 SFX)
SAMPLE_TABLE_BASE = 0x0DC000  # Sample data (32 samples)
SPC_DATA_BASE     = 0x0E0000  # SPC driver code
```

### Track IDs (Selected)
| ID | Name |
|----|------|
| 0x00 | Title Theme |
| 0x01 | Overworld |
| 0x02 | Town Theme |
| 0x03 | Dungeon Theme |
| 0x04 | Battle Theme |
| 0x05 | Boss Battle |
| 0x06 | Final Battle |
| 0x07 | Victory Fanfare |

### SFX IDs (Selected)
| ID | Name |
|----|------|
| 0x00 | Cursor Move |
| 0x01 | Menu Select |
| 0x02 | Menu Cancel |
| 0x04 | Level Up |
| 0x08 | Attack Hit |
| 0x0A | Spell Cast |
| 0x0B | Heal |
| 0x10 | Enemy Death |

### Track Properties
- **Tempo**: 40-240 BPM
- **Volume**: 0-127
- **Channels**: 8 channels (bitmask)
- **Loop**: Start/end in ticks

### SFX Properties
- **Priority**: 0-127 (higher = more important)
- **Volume**: 0-127
- **Pitch**: 0-127 (64 = normal)
- **Pan**: 0-127 (0=L, 64=C, 127=R)

### Quick Actions
```python
# Export track
db.export_spc(0x01, "overworld.spc")

# Import track
track = db.import_spc("custom.spc")

# Duplicate track
new_track = db.duplicate_track(0x01, 0x10)

# Swap tracks
db.swap_tracks(0x01, 0x02)

# Validate track
issues = db.validate_track(0x01)
```

---

## Enemy Quick Reference

### Enemy Properties
- **HP**: 1-65535
- **Attack**: 0-255
- **Defense**: 0-255
- **Speed**: 0-255
- **Element**: Fire, Water, Earth, Wind, Thunder, Ice, Holy, Dark
- **Type**: Normal, Boss, Mini-Boss, Undead, Flying, Dragon

### Quick Actions
```python
# Get enemy
enemy = db.get_enemy(0)

# Modify stats
enemy.hp = 500
enemy.attack = 50
enemy.defense = 30

# Set element
enemy.element = ElementType.FIRE

# Save
db.save_to_rom()
```

---

## Spell Quick Reference

### Spell Properties
- **MP Cost**: 0-255
- **Power**: 0-255 (damage/healing amount)
- **Accuracy**: 0-100%
- **Target**: Single, All Enemies, All Allies, Self
- **Element**: Fire, Water, Earth, Wind, Thunder, Ice, Holy, Dark
- **Status**: Poison, Sleep, Paralyze, Confusion, etc.

### Quick Actions
```python
# Get spell
spell = db.get_spell(0)

# Modify
spell.mp_cost = 10
spell.power = 80
spell.accuracy = 95

# Set element
spell.element = ElementType.THUNDER
```

---

## Item Quick Reference

### Item Properties
- **Type**: Consumable, Weapon, Armor, Accessory, Key Item
- **Effect**: Heal, Cure Status, Damage, Stat Boost
- **Power**: 0-255 (effect strength)
- **Price**: 0-65535 GP

### Quick Actions
```python
# Get item
item = db.get_item(0)

# Modify
item.price = 500
item.effect_power = 50

# Set type
item.item_type = ItemType.CONSUMABLE
```

---

## Common Code Patterns

### Load, Edit, Save Pattern
```python
from utils.enemy_database import EnemyDatabase

# Load
db = EnemyDatabase()
db.load_from_rom("ffmq.smc")

# Edit
enemy = db.get_enemy(0)
enemy.hp = 1000

# Save
db.save_to_rom("ffmq_modified.smc")
```

### Batch Operations
```python
# Increase all enemy HP by 50%
for enemy in db.enemies.values():
    enemy.hp = int(enemy.hp * 1.5)
db.save_to_rom()
```

### Export/Import
```python
# Export to JSON
db.export_to_json("enemies.json")

# Import from JSON
db.import_from_json("enemies_modified.json")
db.save_to_rom()
```

### Validation
```python
from utils.validator import validate_enemy_database

issues = validate_enemy_database(db)
for issue in issues:
    print(f"{issue.severity}: {issue.message}")
```

---

## File Locations

### Main Files
```
tools/map-editor/
├── game_editor.py          # Main unified editor
├── graphics_editor.py      # Graphics editor
├── music_editor.py         # Music editor
├── enemy_editor.py         # Enemy editor
├── formation_editor.py     # Formation editor
├── validator.py            # Data validator
└── comparator.py           # ROM comparator
```

### Data Libraries
```
tools/map-editor/utils/
├── enemy_data.py           # Enemy structures
├── enemy_database.py       # Enemy ROM I/O
├── spell_data.py           # Spell structures
├── spell_database.py       # Spell ROM I/O
├── item_data.py            # Item structures
├── item_database.py        # Item ROM I/O
├── graphics_data.py        # Graphics structures
├── graphics_database.py    # Graphics ROM I/O
├── music_data.py           # Music structures
├── music_database.py       # Music ROM I/O
└── dungeon_map.py          # Dungeon structures
```

### Documentation
```
docs/
├── GAME_EDITOR_GUIDE.md      # Main editor guide
├── GRAPHICS_MUSIC_GUIDE.md   # Graphics/music guide
├── ROADMAP.md                # Development roadmap
└── DELIVERY_REPORT.md        # January 2025 delivery

~docs/
├── SESSION_SUMMARY_2025-11-08.md  # November session
└── SESSION_SUMMARY_2025-01-15.md  # January session
```

---

## Troubleshooting

### Import Errors
```python
# Add parent to path
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent))
```

### ROM Not Loading
- Verify ROM is valid FFMQ (USA) ROM
- Check file permissions
- Ensure ROM is uncompressed (.smc, not .zip)

### Graphics Look Wrong
- Verify using correct palette ID
- Check tile is at correct offset
- Ensure 4bpp planar format

### Music Export Fails
- Verify track has valid data_offset
- Check track data_size > 0
- Ensure ROM has music data at offset

---

## Data Types Reference

### Enums

```python
# Enemy
ElementType: FIRE, WATER, EARTH, WIND, THUNDER, ICE, HOLY, DARK, NONE
EnemyType: NORMAL, BOSS, MINI_BOSS, UNDEAD, FLYING, DRAGON

# Spell
SpellTarget: SINGLE, ALL_ENEMIES, ALL_ALLIES, SELF
SpellType: ATTACK, HEAL, BUFF, DEBUFF, STATUS

# Item
ItemType: CONSUMABLE, WEAPON, ARMOR, ACCESSORY, KEY_ITEM
EffectType: HEAL, CURE_STATUS, DAMAGE, STAT_BOOST

# Graphics
PaletteType: SPRITE, BACKGROUND, ENEMY, CHARACTER, UI
SpriteSize: SIZE_8x8, SIZE_16x16, SIZE_24x24, SIZE_32x32, SIZE_16x32, SIZE_32x64

# Music
MusicType: FIELD, BATTLE, TOWN, DUNGEON, BOSS, EVENT, FANFARE
SoundEffectType: MENU, ATTACK, SPELL, ITEM, FOOTSTEP, AMBIENT
```

---

## Statistics Functions

```python
# Graphics
stats = graphics_db.get_statistics()
# Returns: total_tilesets, total_palettes, total_tiles, etc.

# Music
stats = music_db.get_statistics()
# Returns: total_tracks, total_sfx, total_samples, etc.

# Enemy
bosses = enemy_db.get_bosses()
by_element = enemy_db.get_by_element(ElementType.FIRE)

# Spell
offensive = spell_db.get_offensive_spells()
healing = spell_db.get_healing_spells()

# Item
weapons = item_db.get_weapons()
armor = item_db.get_armor()
consumables = item_db.get_consumables()
```

---

## Advanced Features

### Palette Operations
```python
# Find similar colors
similar = db.find_similar_colors(color, threshold=5)

# Create gradient
from utils.graphics_data import create_gradient_palette
palette = create_gradient_palette(start_color, end_color)

# Optimize (remove duplicates)
removed = db.optimize_palette(palette_id)
```

### Music Operations
```python
# Find unused slots
unused_tracks = db.find_unused_tracks()
unused_sfx = db.find_unused_sfx()

# Note conversion
pitch = note_to_pitch("A4")
note = pitch_to_note(0x1000)

# Duplicate and modify
new_track = db.duplicate_track(0x01, 0x10)
new_track.tempo = 150
```

### Validation
```python
from utils.validator import Validator

validator = Validator()
issues = validator.validate_all()

for issue in issues:
    print(f"[{issue.severity}] {issue.category}: {issue.message}")
```

---

## Tips & Tricks

### Performance
- Load ROM once, keep database in memory
- Batch operations before saving
- Use statistics to verify changes

### Workflow
1. Always work on a copy of the ROM
2. Export to JSON before major changes
3. Test in emulator frequently
4. Use validator before saving

### Best Practices
- Use meaningful names for custom data
- Document changes in session logs
- Keep backups of working ROMs
- Test thoroughly after edits

---

## Quick Links

- **Main Guide**: docs/GAME_EDITOR_GUIDE.md
- **Graphics/Music Guide**: docs/GRAPHICS_MUSIC_GUIDE.md
- **Roadmap**: docs/ROADMAP.md
- **Session Logs**: ~docs/SESSION_SUMMARY_*.md

---

**Last Updated**: November 8, 2025
**Version**: 1.1
