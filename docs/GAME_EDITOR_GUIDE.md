# FFMQ Game Editor - Complete Guide

## Overview

The FFMQ Game Editor is a comprehensive suite of tools for editing all aspects of Final Fantasy Mystic Quest ROM data. It provides visual editors, database managers, and CLI tools for modifying enemies, spells, items, dungeons, dialogs, and more.

## Table of Contents

- [Installation](#installation)
- [Quick Start](#quick-start)
- [ROM Structure](#rom-structure)
- [Enemy System](#enemy-system)
- [Spell System](#spell-system)
- [Item System](#item-system)
- [Dungeon System](#dungeon-system)
- [Dialog System](#dialog-system)
- [Formation Editor](#formation-editor)
- [Database Operations](#database-operations)
- [Data Export/Import](#data-exportimport)
- [Troubleshooting](#troubleshooting)

---

## Installation

### Requirements

- Python 3.8+
- pygame-ce (`pip install pygame-ce`)
- Additional dependencies: See `requirements.txt`

### Setup

```powershell
# Clone repository
git clone <repository-url>
cd ffmq-info

# Install dependencies
pip install -r requirements.txt

# Or install pygame directly
pip install pygame-ce
```

---

## Quick Start

### Launch Game Editor

```powershell
# Main unified editor
python tools/map-editor/game_editor.py

# Standalone enemy editor
python tools/map-editor/ui/enemy_editor.py rom.smc

# Formation editor
python tools/map-editor/ui/formation_editor.py rom.smc

# Dialog CLI
python tools/map-editor/dialog_cli.py
```

### Basic Workflow

1. **Load ROM**: File → Open ROM or Ctrl+O
2. **Edit Data**: Navigate tabs, modify values
3. **Save Changes**: Ctrl+S or File → Save
4. **Export**: File → Export (JSON/CSV)

---

## ROM Structure

### Memory Map

FFMQ uses LoROM format with fixed data blocks:

| Data Type | Address   | Count | Size (bytes) | Total   |
|-----------|-----------|-------|--------------|---------|
| Enemies   | 0x0D0000  | 256   | 256          | 64KB    |
| Spells    | 0x0E0000  | 128   | 64           | 8KB     |
| Items     | 0x0F0000  | 256   | 32           | 8KB     |
| Dialogs   | Various   | ~1000 | Variable     | ~40KB   |

### Data Formats

All data uses little-endian byte order. Structures are packed with no padding unless specified.

---

## Enemy System

### Enemy Data Structure (256 bytes)

```python
class Enemy:
    # Header (32 bytes)
    enemy_id: int           # 0x00: Unique ID (0x00-0xFF)
    name: str               # 0x01: Name (16 bytes, null-terminated)
    level: int              # 0x11: Level (1-99)
    enemy_type: int         # 0x12: Type flags
    
    # Stats (16 bytes)
    stats: EnemyStats       # 0x13-0x22
        hp: int             # Max HP (0-65535)
        attack: int         # Physical attack (0-255)
        defense: int        # Physical defense (0-255)
        magic: int          # Magic power (0-255)
        magic_def: int      # Magic defense (0-255)
        speed: int          # Speed/agility (0-255)
        accuracy: int       # Hit rate % (0-100)
        evasion: int        # Evade rate % (0-100)
    
    # Resistances (9 bytes)
    resistances: ResistanceData  # 0x23-0x2B
        fire: int           # Fire resistance (0-255)
        water: int          # Water resistance
        earth: int          # Earth resistance
        wind: int           # Wind resistance
        holy: int           # Holy resistance
        dark: int           # Dark resistance
        poison: int         # Poison resistance
        status: int         # Status effect resistance
        physical: int       # Physical damage resistance
    
    # Rewards (8 bytes)
    exp: int                # 0x2C: Experience points
    gold: int               # 0x2E: Gold dropped
    drops: List[ItemDrop]   # 0x30: Item drops (up to 3)
    
    # AI Script (64 bytes)
    ai_script: AIScript     # 0x38-0x77
        behavior: AIBehavior
        actions: List[AIAction]  # Up to 8 actions
    
    # Sprite (32 bytes)
    sprite: SpriteInfo      # 0x78-0x97
        sprite_id: int
        palette: int
        size: int
        animation_frames: int
    
    # Flags (16 bytes)
    flags: EnemyFlags       # 0x98-0xA7
        BOSS
        UNDEAD
        FLYING
        AQUATIC
        HUMANOID
        MECHANICAL
        DRAGON
        REGENERATES
        COUNTER_ATTACK
        MULTI_PART
        IMMUNE_INSTANT_DEATH
        IMMUNE_STATUS
```

### Resistance Values

- **0**: Immune (0% damage)
- **128**: Normal (100% damage)
- **255**: Weak (200% damage)

### Enemy Flags

```python
class EnemyFlags(IntFlag):
    BOSS = 0x0001               # Boss enemy, special music
    UNDEAD = 0x0002             # Takes damage from healing
    FLYING = 0x0004             # Immune to earth attacks
    AQUATIC = 0x0008            # Weak to lightning
    HUMANOID = 0x0010           # Affected by confusion
    MECHANICAL = 0x0020         # Immune to poison/status
    DRAGON = 0x0040             # Weak to dragon killer
    REGENERATES = 0x0080        # Regenerates HP per turn
    COUNTER_ATTACK = 0x0100     # Counters physical attacks
    MULTI_PART = 0x0200         # Multiple targetable parts
    IMMUNE_INSTANT_DEATH = 0x0400  # Can't be killed instantly
    IMMUNE_STATUS = 0x0800      # Immune to all status effects
```

### AI Behavior Types

```python
class AIBehavior(IntEnum):
    RANDOM = 0          # Random attacks
    AGGRESSIVE = 1      # Targets weakest party member
    DEFENSIVE = 2       # Uses healing/buffs when low HP
    TACTICAL = 3        # Exploits elemental weaknesses
    BERSERKER = 4       # Only physical attacks
    CASTER = 5          # Prefers magic
    SUPPORT = 6         # Uses buffs/debuffs
    ADAPTIVE = 7        # Changes based on HP threshold
```

### Item Drops

```python
class ItemDrop:
    item_id: int        # Item to drop
    drop_type: DropType # ALWAYS, COMMON, UNCOMMON, RARE
    quantity: int       # Amount (1-99)
    
    # Drop rates
    ALWAYS = 100%
    COMMON = 50%
    UNCOMMON = 25%
    RARE = 12.5%
```

### Example: Create Enemy

```python
from utils.enemy_data import Enemy, EnemyStats, ResistanceData
from utils.enemy_database import EnemyDatabase

# Create stats
stats = EnemyStats(
    hp=500,
    attack=45,
    defense=30,
    magic=25,
    magic_def=20,
    speed=35,
    accuracy=90,
    evasion=10
)

# Create resistances
resistances = ResistanceData(
    fire=128,      # Normal
    water=255,     # Weak
    earth=64,      # Resistant
    wind=128,
    holy=128,
    dark=128,
    poison=0,      # Immune
    status=50,
    physical=128
)

# Create enemy
enemy = Enemy(
    enemy_id=0x10,
    name="Fire Drake",
    level=15,
    stats=stats,
    resistances=resistances,
    exp=450,
    gold=200
)

# Save to database
db = EnemyDatabase()
db.enemies[0x10] = enemy
db.save_to_rom("rom.smc")
```

### Database Operations

```python
# Load enemies
db = EnemyDatabase()
db.load_from_rom("rom.smc")

# Search
bosses = db.get_bosses()
high_level = db.filter_by_level(20, 99)
undead = db.filter_by_flags(EnemyFlags.UNDEAD)

# Modify
enemy = db.enemies[0x10]
enemy.stats.hp = 600
db.save_to_rom("rom.smc")

# Batch operations
db.batch_scale_stats(1.5, enemy_ids=[0x10, 0x11, 0x12])

# Export
db.export_to_csv("enemies.csv")
db.export_to_json("enemies.json")
```

---

## Spell System

### Spell Data Structure (64 bytes)

```python
class Spell:
    spell_id: int               # 0x00: Unique ID
    name: str                   # 0x01: Name (16 bytes)
    element: SpellElement       # 0x11: Element type
    target: SpellTarget         # 0x12: Targeting mode
    mp_cost: int                # 0x13: MP required
    power: int                  # 0x14: Base power
    accuracy: int               # 0x15: Hit rate %
    formula: DamageFormula      # 0x16: Damage calculation
    flags: SpellFlags           # 0x17: Spell properties
    animation: AnimationData    # 0x18-0x2F: Visual effects
    status_effects: List[StatusEffect]  # 0x30-0x3F
```

### Elements

```python
class SpellElement(IntEnum):
    NONE = 0
    FIRE = 1
    WATER = 2
    EARTH = 3
    WIND = 4
    HOLY = 5
    DARK = 6
    POISON = 7
```

### Targeting Modes

```python
class SpellTarget(IntEnum):
    SINGLE_ENEMY = 0        # One enemy
    ALL_ENEMIES = 1         # All enemies
    SINGLE_ALLY = 2         # One party member
    ALL_ALLIES = 3          # Entire party
    SELF = 4                # Caster only
    RANDOM_ENEMY = 5        # Random enemy
    ALL_BUT_SELF = 6        # Party except caster
    DEAD_ALLY = 7           # Revive target
```

### Damage Formulas

```python
class DamageFormula(IntEnum):
    FIXED = 0               # power
    MAGIC_BASED = 1         # power * caster.magic / 16
    LEVEL_BASED = 2         # power * caster.level / 8
    HP_PERCENTAGE = 3       # target.max_hp * power / 100
    MP_BASED = 4            # power * caster.mp / 32
    DEFENSE_PIERCE = 5      # power * 2 (ignores defense)
    HYBRID = 6              # (power + caster.attack) * caster.magic / 32
    RANDOM = 7              # random(power/2, power*2)
```

### Spell Flags

```python
class SpellFlags(IntFlag):
    OFFENSIVE = 0x01        # Damages enemies
    HEALING = 0x02          # Restores HP
    STATUS_EFFECT = 0x04    # Applies status
    REVIVE = 0x08           # Revives fallen ally
    REFLECTABLE = 0x10      # Can be reflected
    MULTI_HIT = 0x20        # Hits multiple times
    DRAIN = 0x40            # Absorbs damage as HP
    PIERCING = 0x80         # Ignores resistances
    AREA_EFFECT = 0x100     # Affects area
    SILENT_CAST = 0x200     # Can cast while silenced
```

### Status Effects

```python
class StatusEffect(IntFlag):
    POISON = 0x0001
    SLEEP = 0x0002
    PARALYSIS = 0x0004
    CONFUSION = 0x0008
    SILENCE = 0x0010
    BLIND = 0x0020
    PETRIFY = 0x0040
    DEATH = 0x0080
    REGEN = 0x0100
    PROTECT = 0x0200
    SHELL = 0x0400
    HASTE = 0x0800
    SLOW = 0x1000
```

### Example: Create Spell Progression

```python
from utils.spell_database import SpellDatabase

db = SpellDatabase()

# Create Fire → Fira → Firaga progression
fire_tier = db.create_spell_progression(
    base_name="Fire",
    element=SpellElement.FIRE,
    base_power=20,
    base_mp=4,
    tier_count=3,
    power_scaling=1.5,
    mp_scaling=1.3
)

# Results:
# Fire:   20 power, 4 MP
# Fira:   30 power, 6 MP  
# Firaga: 45 power, 8 MP
```

---

## Item System

### Item Data Structure (32 bytes)

```python
class Item:
    item_id: int                # 0x00: Unique ID
    name: str                   # 0x01: Name (12 bytes)
    item_type: ItemType         # 0x0D: Type
    flags: ItemFlags            # 0x0E: Properties
    buy_price: int              # 0x10: Shop buy price
    sell_price: int             # 0x12: Shop sell price
    icon_id: int                # 0x14: Icon sprite
    
    # Equipment only
    equipment_stats: EquipmentStats  # 0x15-0x1D
        attack: int
        defense: int
        magic: int
        magic_def: int
        speed: int
        hp_bonus: int
        mp_bonus: int
        accuracy: int
        evasion: int
    
    restrictions: EquipRestriction   # 0x1E: Who can equip
    
    # Consumable only
    effect: ItemEffect          # 0x1F-0x1F
        effect_type: int
        power: int
        status: StatusEffect
```

### Item Types

```python
class ItemType(IntEnum):
    CONSUMABLE = 0      # Potions, ethers
    WEAPON = 1          # Swords, axes
    ARMOR = 2           # Body armor
    HELMET = 3          # Head gear
    ACCESSORY = 4       # Rings, amulets
    KEY_ITEM = 5        # Quest items
    COIN = 6            # Currency items
    BOOK = 7            # Spell books
```

### Item Flags

```python
class ItemFlags(IntFlag):
    USABLE_IN_BATTLE = 0x01     # Can use during battle
    USABLE_IN_FIELD = 0x02      # Can use on map
    CONSUMABLE = 0x04           # Single use
    CURSED = 0x08               # Can't unequip
    RARE = 0x10                 # Rare item
    TWO_HANDED = 0x20           # Weapon: requires both hands
    ELEMENTAL = 0x40            # Has elemental property
    QUEST_ITEM = 0x80           # Can't sell/drop
    STACKABLE = 0x100           # Multiple in one slot
```

### Equipment Restrictions

```python
class EquipRestriction(IntFlag):
    BENJAMIN = 0x01
    KAELI = 0x02
    PHOEBE = 0x04
    REUBEN = 0x08
    TRISTAM = 0x10
    ALL = 0x1F
```

### Example: Create Weapon

```python
from utils.item_data import Item, EquipmentStats, ItemType, EquipRestriction

sword = Item(
    item_id=0x20,
    name="Steel Sword",
    item_type=ItemType.WEAPON,
    buy_price=500,
    sell_price=250,
    equipment_stats=EquipmentStats(
        attack=35,
        accuracy=95
    ),
    restrictions=EquipRestriction.BENJAMIN | EquipRestriction.KAELI
)
```

---

## Dungeon System

### Dungeon Components

```python
# Enemy Formation (up to 6 enemies)
formation = EnemyFormation(
    formation_id=1,
    enemy_ids=[0x10, 0x10, 0x11],  # 2 Goblins, 1 Orc
    positions=[(64, 64), (96, 64), (128, 64)],
    surprise_rate=10,
    preemptive_rate=15
)

# Encounter Table (weighted)
table = EncounterTable(
    formations=[
        (formation1, 40),  # 40% weight
        (formation2, 35),  # 35% weight
        (formation3, 25)   # 25% weight
    ]
)

# Dungeon Zone
zone = DungeonZone(
    zone_id=1,
    encounter_zone=EncounterZone.NORMAL,
    encounter_rate=30,  # Base encounter rate
    encounter_table=table,
    x=0, y=0, width=128, height=128
)

# Complete Dungeon
dungeon = DungeonMap(
    dungeon_id=1,
    name="Dark Cave",
    zones=[zone1, zone2],
    terrain_type=TerrainType.CAVE
)
```

### Encounter Zones

```python
class EncounterZone(IntEnum):
    NORMAL = 0          # Standard encounter rate
    HIGH_RATE = 1       # 2x encounter rate
    BOSS_AREA = 2       # No random encounters
    SAFE_ZONE = 3       # No encounters
```

### Terrain Types

```python
class TerrainType(IntEnum):
    OVERWORLD = 0
    CAVE = 1
    DUNGEON = 2
    TOWER = 3
    FOREST = 4
    WATER = 5
    MOUNTAIN = 6
    CASTLE = 7
```

---

## Formation Editor

### Visual Editor

The formation editor provides drag-and-drop enemy placement:

**Features:**
- Visual battle screen preview
- Grid snapping (16px)
- Enemy list with search
- Real-time positioning
- Formation save/load

**Controls:**
- **Click Enemy**: Select
- **Drag Enemy**: Move position
- **Delete Key**: Remove selected
- **Add Button**: Place new enemy
- **Save Button**: Save formation

**Launch:**
```powershell
python tools/map-editor/ui/formation_editor.py rom.smc
```

---

## Database Operations

### Common Operations

```python
# Load database
from utils.enemy_database import EnemyDatabase

db = EnemyDatabase()
db.load_from_rom("rom.smc")

# Search
results = db.search_enemies("Dragon")
bosses = db.get_bosses()
high_level = db.filter_by_level(30, 99)

# Sort
by_difficulty = db.get_by_difficulty()
by_hp = sorted(db.enemies.values(), key=lambda e: e.stats.hp)

# Modify
enemy = db.enemies[0x50]
enemy.stats.hp *= 2
db.save_to_rom("rom.smc")

# Clone
new_enemy = db.clone_enemy(0x50, new_id=0x51)
new_enemy.name = "Red Dragon"

# Batch operations
db.batch_scale_stats(1.25, level_range=(20, 30))

# Statistics
stats = db.get_statistics()
print(f"Total enemies: {stats['total_count']}")
print(f"Average HP: {stats['average_hp']}")
print(f"Boss count: {stats['boss_count']}")
```

### Export Formats

**CSV Export:**
```python
db.export_to_csv("enemies.csv")
```

Output:
```csv
ID,Name,Level,HP,Attack,Defense,Magic,Speed,EXP,Gold
0x10,Goblin,5,45,12,8,5,15,25,10
0x11,Orc,8,85,22,15,8,12,55,25
```

**JSON Export:**
```python
db.export_to_json("enemies.json")
```

Output:
```json
{
  "metadata": {
    "total_enemies": 256,
    "export_date": "2025-01-15"
  },
  "enemies": [
    {
      "id": 16,
      "name": "Goblin",
      "level": 5,
      "stats": {
        "hp": 45,
        "attack": 12
      }
    }
  ]
}
```

---

## Data Export/Import

### Batch Export

```python
# Export all game data
from utils.enemy_database import EnemyDatabase
from utils.spell_database import SpellDatabase
from utils.item_database import ItemDatabase

enemy_db = EnemyDatabase()
enemy_db.load_from_rom("rom.smc")
enemy_db.export_to_json("exports/enemies.json")

spell_db = SpellDatabase()
spell_db.load_from_rom("rom.smc")
spell_db.export_to_json("exports/spells.json")

item_db = ItemDatabase()
item_db.load_from_rom("rom.smc")
item_db.export_to_json("exports/items.json")
```

### Import Modified Data

```python
import json

# Load modified JSON
with open("exports/enemies_modified.json") as f:
    data = json.load(f)

# Apply changes
db = EnemyDatabase()
db.load_from_rom("rom.smc")

for enemy_data in data['enemies']:
    enemy_id = enemy_data['id']
    if enemy_id in db.enemies:
        enemy = db.enemies[enemy_id]
        enemy.stats.hp = enemy_data['stats']['hp']
        # ... apply other changes

db.save_to_rom("rom_modified.smc")
```

---

## Troubleshooting

### Common Issues

**1. Pygame Import Error**

```
ImportError: No module named 'pygame'
```

**Solution:**
```powershell
pip install pygame-ce
```

Note: pygame-ce installs as `pygame`, not `pygame_ce`.

**2. ROM Not Loading**

```
Error: Could not read ROM file
```

**Solution:**
- Verify ROM is valid SNES format
- Check file permissions
- Ensure ROM is LoROM (not HiROM)

**3. Data Corruption**

```
Warning: Invalid data at offset 0x...
```

**Solution:**
- Backup ROM before editing
- Validate data ranges (HP 0-65535, etc.)
- Check byte alignment

**4. Missing Dependencies**

```
ModuleNotFoundError: No module named 'dataclasses'
```

**Solution:**
```powershell
# Python 3.7+: dataclasses is built-in
# Python 3.6: install backport
pip install dataclasses
```

### Debug Mode

Enable debug output:

```python
import logging

logging.basicConfig(level=logging.DEBUG)

db = EnemyDatabase()
db.load_from_rom("rom.smc")  # Will print detailed logs
```

### Validate ROM

```python
from utils.enemy_database import EnemyDatabase

db = EnemyDatabase()
db.load_from_rom("rom.smc")

# Check for issues
for enemy_id, enemy in db.enemies.items():
    # Validate HP range
    if enemy.stats.hp > 65535:
        print(f"Invalid HP for enemy {enemy_id}: {enemy.stats.hp}")
    
    # Validate level
    if enemy.level > 99:
        print(f"Invalid level for enemy {enemy_id}: {enemy.level}")
    
    # Validate resistances
    for element, value in enemy.resistances.__dict__.items():
        if value > 255:
            print(f"Invalid {element} resistance for {enemy_id}: {value}")
```

---

## Advanced Topics

### Custom Damage Formulas

Modify spell damage calculation:

```python
from utils.spell_data import Spell, DamageFormula

# Create custom formula
def calculate_custom_damage(spell: Spell, caster_magic: int, target_defense: int) -> int:
    base = spell.power * caster_magic // 16
    reduced = base * (255 - target_defense) // 255
    return max(1, reduced)

# Use in battle calculations
spell = spell_db.spells[0x10]
damage = calculate_custom_damage(spell, caster.magic, target.magic_def)
```

### Procedural Content Generation

Generate random enemies:

```python
import random
from utils.enemy_data import Enemy, EnemyStats, ResistanceData

def generate_random_enemy(enemy_id: int, level: int) -> Enemy:
    """Generate random enemy based on level"""
    
    hp = level * random.randint(15, 25)
    attack = level * random.randint(2, 4)
    defense = level * random.randint(1, 3)
    
    stats = EnemyStats(
        hp=hp,
        attack=attack,
        defense=defense,
        magic=level,
        magic_def=level,
        speed=random.randint(10, 50),
        accuracy=random.randint(80, 95),
        evasion=random.randint(5, 20)
    )
    
    # Random resistances
    resistances = ResistanceData(
        fire=random.randint(0, 255),
        water=random.randint(0, 255),
        earth=random.randint(0, 255),
        wind=random.randint(0, 255),
        holy=128,
        dark=128,
        poison=random.randint(0, 128),
        status=random.randint(50, 150),
        physical=128
    )
    
    return Enemy(
        enemy_id=enemy_id,
        name=f"Random Enemy {enemy_id}",
        level=level,
        stats=stats,
        resistances=resistances,
        exp=level * 50,
        gold=level * 10
    )

# Generate 10 random enemies
db = EnemyDatabase()
for i in range(10):
    enemy = generate_random_enemy(0xF0 + i, level=random.randint(5, 30))
    db.enemies[enemy.enemy_id] = enemy

db.save_to_rom("rom_random.smc")
```

---

## Keyboard Shortcuts

### Game Editor

| Shortcut | Action |
|----------|--------|
| Ctrl+O | Open ROM |
| Ctrl+S | Save ROM |
| Ctrl+E | Export Data |
| Ctrl+1-8 | Switch Tabs |
| F1 | Toggle Stats |
| Esc | Cancel |

### Enemy Editor

| Shortcut | Action |
|----------|--------|
| Ctrl+S | Save Changes |
| Ctrl+F | Search |
| Ctrl+N | New Enemy |
| Ctrl+D | Duplicate |
| Delete | Delete Enemy |
| Up/Down | Navigate List |

### Formation Editor

| Shortcut | Action |
|----------|--------|
| Drag | Move Enemy |
| Delete | Remove Selected |
| Ctrl+A | Add Enemy |
| Ctrl+S | Save Formation |
| Ctrl+Z | Undo |

---

## API Reference

### EnemyDatabase

```python
class EnemyDatabase:
    def load_from_rom(path: str) -> None
    def save_to_rom(path: str) -> None
    def search_enemies(query: str) -> List[Enemy]
    def filter_by_level(min_level: int, max_level: int) -> List[Enemy]
    def filter_by_flags(flags: EnemyFlags) -> List[Enemy]
    def get_bosses() -> List[Enemy]
    def get_by_difficulty() -> List[Enemy]
    def clone_enemy(enemy_id: int, new_id: int) -> Enemy
    def batch_scale_stats(multiplier: float, **filters) -> None
    def get_statistics() -> Dict[str, Any]
    def export_to_csv(path: str) -> None
    def export_to_json(path: str) -> None
```

### SpellDatabase

```python
class SpellDatabase:
    def load_from_rom(path: str) -> None
    def save_to_rom(path: str) -> None
    def filter_by_element(element: SpellElement) -> List[Spell]
    def filter_by_target(target: SpellTarget) -> List[Spell]
    def get_healing_spells() -> List[Spell]
    def get_offensive_spells() -> List[Spell]
    def create_spell_progression(...) -> List[Spell]
    def batch_scale_power(multiplier: float) -> None
```

### ItemDatabase

```python
class ItemDatabase:
    def load_from_rom(path: str) -> None
    def save_to_rom(path: str) -> None
    def filter_by_type(item_type: ItemType) -> List[Item]
    def get_weapons() -> List[Item]
    def get_armor() -> List[Item]
    def get_consumables() -> List[Item]
    def get_by_price(min_price: int, max_price: int) -> List[Item]
    def get_equipment_by_stats() -> List[Item]
```

---

## Contributing

When adding new features:

1. Follow existing data structure patterns
2. Use dataclasses with `to_bytes()`/`from_bytes()`
3. Add type hints
4. Include docstrings
5. Write unit tests
6. Update this guide

---

## Credits

**FFMQ Game Editor Suite**
- Enemy System
- Spell System
- Item System
- Dungeon System
- Formation Editor
- Database Managers

**Technologies:**
- Python 3.8+
- pygame-ce
- dataclasses

---

## Version History

**v1.0.0** (2025-01-15)
- Initial release
- Enemy/Spell/Item/Dungeon editing
- Visual formation editor
- Database export/import
- 5,400+ lines of code

---

## License

See LICENSE file for details.
