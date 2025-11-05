# Enemy Modding Guide

Comprehensive guide to modifying enemy stats, behaviors, and attributes in Final Fantasy Mystic Quest.

## Table of Contents

1. [Enemy Data Structure](#enemy-data-structure)
2. [Basic Enemy Modifications](#basic-enemy-modifications)
3. [Element System](#element-system)
4. [Advanced Enemy Editing](#advanced-enemy-editing)
5. [Enemy-Attack Relationships](#enemy-attack-relationships)
6. [Testing and Balancing](#testing-and-balancing)

## Enemy Data Structure

### Understanding enemies.json

Location: `data/extracted/enemies/enemies.json`

```json
{
  "metadata": {
    "game": "FFMQ",
    "count": 83,
    "description": "Enemy stats from Bank $02, ROM $C275 (14 bytes per enemy)"
  },
  "enemies": [
    {
      "id": 0,
      "name": "Behemoth",
      "hp": 400,
      "attack": 40,
      "defense": 45,
      "speed": 25,
      "magic": 60,
      "resistances": 0,
      "magic_defense": 30,
      "magic_evade": 20,
      "accuracy": 99,
      "evade": 10,
      "weaknesses": 256
    }
  ]
}
```

### Field Descriptions

| Field | Type | Range | Description |
|-------|------|-------|-------------|
| `id` | int | 0-82 | Enemy ID (83 total enemies) |
| `name` | string | - | Enemy name (for reference) |
| `hp` | int | 0-65535 | Hit points (16-bit) |
| `attack` | int | 0-255 | Physical attack power |
| `defense` | int | 0-255 | Physical defense |
| `speed` | int | 0-255 | Turn order/agility |
| `magic` | int | 0-255 | Magic power |
| `resistances` | int | 0-65535 | Element resistance bitfield |
| `magic_defense` | int | 0-255 | Magic defense |
| `magic_evade` | int | 0-255 | Magic evasion |
| `accuracy` | int | 0-255 | Physical accuracy |
| `evade` | int | 0-255 | Physical evasion |
| `weaknesses` | int | 0-65535 | Element weakness bitfield |

### ROM Address Reference

- **Bank**: $02
- **ROM Address**: $C275
- **Entry Size**: 14 bytes per enemy
- **Total Entries**: 83 enemies

## Basic Enemy Modifications

### Example 1: Create a Super Boss

Make Behemoth (final boss) much more challenging:

```python
import json
from pathlib import Path

def create_super_behemoth():
	enemies_file = Path("data/extracted/enemies/enemies.json")
	
	with open(enemies_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	# Behemoth is ID 82
	behemoth = data['enemies'][82]
	
	# Quadruple HP
	behemoth['hp'] = 1600
	
	# Max out offensive stats
	behemoth['attack'] = 120
	behemoth['magic'] = 99
	behemoth['accuracy'] = 99
	
	# Boost defensive stats
	behemoth['defense'] = 90
	behemoth['magic_defense'] = 80
	behemoth['evade'] = 30
	behemoth['magic_evade'] = 40
	
	# Make faster
	behemoth['speed'] = 60
	
	with open(enemies_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print("✅ Super Behemoth created!")
	print(f"   HP: 400 → {behemoth['hp']}")
	print(f"   Attack: 40 → {behemoth['attack']}")
	print(f"   Defense: 45 → {behemoth['defense']}")

if __name__ == "__main__":
	create_super_behemoth()
```

### Example 2: Scale Enemy Difficulty

Create a difficulty curve by scaling all enemies:

```python
import json
from pathlib import Path

def apply_difficulty_multiplier(multiplier=1.5):
	"""
	Scale enemy stats by a multiplier.
	multiplier=1.5 means 150% difficulty (harder)
	multiplier=0.75 means 75% difficulty (easier)
	"""
	enemies_file = Path("data/extracted/enemies/enemies.json")
	
	with open(enemies_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	for enemy in data['enemies']:
		# Scale HP (16-bit max)
		enemy['hp'] = min(int(enemy['hp'] * multiplier), 65535)
		
		# Scale offensive stats (8-bit max)
		enemy['attack'] = min(int(enemy['attack'] * multiplier), 255)
		enemy['magic'] = min(int(enemy['magic'] * multiplier), 255)
		
		# Scale defensive stats
		enemy['defense'] = min(int(enemy['defense'] * multiplier), 255)
		enemy['magic_defense'] = min(int(enemy['magic_defense'] * multiplier), 255)
		
		print(f"{enemy['name']:20} HP: {enemy['hp']}")
	
	with open(enemies_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print(f"\n✅ Applied {multiplier}x difficulty multiplier to all enemies")

if __name__ == "__main__":
	apply_difficulty_multiplier(1.5)  # 50% harder
```

### Example 3: Balance Enemy Stats

Ensure no enemy is too weak or too strong:

```python
import json
from pathlib import Path

def balance_enemy_stats():
	"""Enforce minimum and maximum stat values"""
	enemies_file = Path("data/extracted/enemies/enemies.json")
	
	with open(enemies_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	MIN_HP = 50
	MIN_STATS = 10
	MAX_BOSS_HP = 2000
	
	for enemy in data['enemies']:
		# Ensure minimum HP
		if enemy['hp'] < MIN_HP:
			enemy['hp'] = MIN_HP
		
		# Cap boss HP
		if enemy['id'] >= 80 and enemy['hp'] > MAX_BOSS_HP:
			enemy['hp'] = MAX_BOSS_HP
		
		# Ensure minimum offensive stats
		enemy['attack'] = max(enemy['attack'], MIN_STATS)
		enemy['magic'] = max(enemy['magic'], MIN_STATS)
		
		# Ensure minimum defensive stats
		enemy['defense'] = max(enemy['defense'], MIN_STATS)
		enemy['magic_defense'] = max(enemy['magic_defense'], MIN_STATS)
	
	with open(enemies_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print("✅ Enemy stats balanced")

if __name__ == "__main__":
	balance_enemy_stats()
```

## Element System

### Element Bitfield Reference

FFMQ uses 16-bit bitfields for resistances and weaknesses:

```python
ELEMENTS = {
	'Silence':    0x0001,  # Bit 0
	'Blind':      0x0002,  # Bit 1
	'Poison':     0x0004,  # Bit 2
	'Confusion':  0x0008,  # Bit 3
	'Sleep':      0x0010,  # Bit 4
	'Paralysis':  0x0020,  # Bit 5
	'Stone':      0x0040,  # Bit 6
	'Doom':       0x0080,  # Bit 7
	'Projectile': 0x0100,  # Bit 8
	'Bomb':       0x0200,  # Bit 9
	'Axe':        0x0400,  # Bit 10
	'Zombie':     0x0800,  # Bit 11
	'Air':        0x1000,  # Bit 12
	'Fire':       0x2000,  # Bit 13
	'Water':      0x4000,  # Bit 14
	'Earth':      0x8000,  # Bit 15
}
```

### Working with Elements

#### Set Single Element

```python
# Make enemy weak to Fire
enemy['weaknesses'] = 0x2000  # Fire only

# Make enemy resist Water
enemy['resistances'] = 0x4000  # Water only
```

#### Combine Multiple Elements

```python
# Weak to Fire AND Water
enemy['weaknesses'] = 0x2000 | 0x4000  # = 0x6000

# Resist Fire, Water, AND Earth
enemy['resistances'] = 0x2000 | 0x4000 | 0x8000  # = 0xE000
```

#### Helper Functions

```python
def add_weakness(enemy, element_value):
	"""Add element weakness to enemy"""
	enemy['weaknesses'] |= element_value

def add_resistance(enemy, element_value):
	"""Add element resistance to enemy"""
	enemy['resistances'] |= element_value

def remove_weakness(enemy, element_value):
	"""Remove element weakness from enemy"""
	enemy['weaknesses'] &= ~element_value

def has_weakness(enemy, element_value):
	"""Check if enemy has weakness"""
	return (enemy['weaknesses'] & element_value) != 0

# Usage:
FIRE = 0x2000
add_weakness(behemoth, FIRE)
```

### Example 4: Elemental Weaknesses Mod

Give all enemies at least one elemental weakness:

```python
import json
import random
from pathlib import Path

ELEMENTS = {
	'Fire':   0x2000,
	'Water':  0x4000,
	'Earth':  0x8000,
	'Air':    0x1000,
}

def add_random_weaknesses():
	enemies_file = Path("data/extracted/enemies/enemies.json")
	
	with open(enemies_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	for enemy in data['enemies']:
		# If enemy has no weaknesses, give them one
		if enemy['weaknesses'] == 0:
			# Pick 1-2 random elements
			num_weaknesses = random.randint(1, 2)
			elements = random.sample(list(ELEMENTS.values()), num_weaknesses)
			
			enemy['weaknesses'] = 0
			for element in elements:
				enemy['weaknesses'] |= element
			
			element_names = [k for k, v in ELEMENTS.items() if enemy['weaknesses'] & v]
			print(f"{enemy['name']:20} now weak to: {', '.join(element_names)}")
	
	with open(enemies_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print("\n✅ Added random elemental weaknesses")

if __name__ == "__main__":
	add_random_weaknesses()
```

### Example 5: Classical RPG Elements

Implement Fire/Water/Earth triangle:

```python
import json
from pathlib import Path

FIRE = 0x2000
WATER = 0x4000
EARTH = 0x8000

def apply_element_triangle():
	"""
	Fire → Water (Fire weak to Water)
	Water → Earth (Water weak to Earth)
	Earth → Fire (Earth weak to Fire)
	"""
	enemies_file = Path("data/extracted/enemies/enemies.json")
	
	with open(enemies_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	for enemy in data['enemies']:
		# If resistant to Fire, make weak to Water
		if enemy['resistances'] & FIRE:
			enemy['weaknesses'] |= WATER
			print(f"{enemy['name']}: Fire resist → Water weakness")
		
		# If resistant to Water, make weak to Earth
		if enemy['resistances'] & WATER:
			enemy['weaknesses'] |= EARTH
			print(f"{enemy['name']}: Water resist → Earth weakness")
		
		# If resistant to Earth, make weak to Fire
		if enemy['resistances'] & EARTH:
			enemy['weaknesses'] |= FIRE
			print(f"{enemy['name']}: Earth resist → Fire weakness")
	
	with open(enemies_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print("\n✅ Applied elemental triangle")

if __name__ == "__main__":
	apply_element_triangle()
```

## Advanced Enemy Editing

### Example 6: Progressive Difficulty Curve

Make enemies harder as the game progresses:

```python
import json
from pathlib import Path

def apply_progressive_difficulty():
	"""
	Enemies get stronger based on their ID.
	Assumes enemy IDs roughly correlate with game progression.
	"""
	enemies_file = Path("data/extracted/enemies/enemies.json")
	
	with open(enemies_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	for enemy in data['enemies']:
		enemy_id = enemy['id']
		
		# Calculate multiplier: 1.0x (early game) to 2.0x (late game)
		progress = enemy_id / 82.0  # 0.0 to 1.0
		multiplier = 1.0 + progress  # 1.0 to 2.0
		
		# Apply multiplier to stats
		enemy['hp'] = min(int(enemy['hp'] * multiplier), 65535)
		enemy['attack'] = min(int(enemy['attack'] * multiplier), 255)
		enemy['defense'] = min(int(enemy['defense'] * multiplier), 255)
		enemy['magic'] = min(int(enemy['magic'] * multiplier), 255)
		
		print(f"ID {enemy_id:2d} {enemy['name']:20} [{multiplier:.2f}x] HP: {enemy['hp']}")
	
	with open(enemies_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print("\n✅ Applied progressive difficulty curve")

if __name__ == "__main__":
	apply_progressive_difficulty()
```

### Example 7: Stat Correlation

Ensure stats make sense together (fast enemies = low defense, etc.):

```python
import json
from pathlib import Path

def correlate_stats():
	"""Create logical stat relationships"""
	enemies_file = Path("data/extracted/enemies/enemies.json")
	
	with open(enemies_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	for enemy in data['enemies']:
		# Fast enemies should have lower defense
		if enemy['speed'] > 60:
			enemy['defense'] = min(enemy['defense'], 40)
			enemy['evade'] = min(enemy['evade'] + 20, 255)
			print(f"{enemy['name']}: Fast → Low defense, high evade")
		
		# High defense enemies should be slower
		if enemy['defense'] > 70:
			enemy['speed'] = min(enemy['speed'], 30)
			print(f"{enemy['name']}: High defense → Slower")
		
		# High magic enemies should have lower physical attack
		if enemy['magic'] > 70:
			enemy['attack'] = int(enemy['attack'] * 0.7)
			print(f"{enemy['name']}: High magic → Lower physical attack")
	
	with open(enemies_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print("\n✅ Applied stat correlations")

if __name__ == "__main__":
	correlate_stats()
```

## Enemy-Attack Relationships

### Understanding enemy_attack_links.json

Location: `data/extracted/enemy_attack_links/enemy_attack_links.json`

This file maps which attacks enemies can use:

```json
{
  "links": [
    {
      "enemy_id": 0,
      "attack_ids": [10, 15, 23]
    }
  ]
}
```

### Example 8: Give Enemy New Attack

```python
import json
from pathlib import Path

def add_attack_to_enemy(enemy_id, attack_id):
	"""Add an attack to an enemy's arsenal"""
	links_file = Path("data/extracted/enemy_attack_links/enemy_attack_links.json")
	
	with open(links_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	# Find enemy's link entry
	enemy_link = next((link for link in data['links'] if link['enemy_id'] == enemy_id), None)
	
	if enemy_link and attack_id not in enemy_link['attack_ids']:
		enemy_link['attack_ids'].append(attack_id)
		
		with open(links_file, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent=2)
		
		print(f"✅ Added attack {attack_id} to enemy {enemy_id}")
	else:
		print(f"❌ Enemy {enemy_id} not found or already has attack {attack_id}")

if __name__ == "__main__":
	add_attack_to_enemy(82, 50)  # Give Behemoth attack 50
```

## Testing and Balancing

### Validation Script

```python
import json
from pathlib import Path

def validate_enemy_data():
	"""Check for common modding errors"""
	enemies_file = Path("data/extracted/enemies/enemies.json")
	
	with open(enemies_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	errors = []
	
	for enemy in data['enemies']:
		# Check HP range
		if enemy['hp'] > 65535:
			errors.append(f"{enemy['name']}: HP {enemy['hp']} > 65535 (max)")
		
		# Check stat ranges
		for stat in ['attack', 'defense', 'speed', 'magic', 'magic_defense', 
		             'magic_evade', 'accuracy', 'evade']:
			if enemy[stat] > 255:
				errors.append(f"{enemy['name']}: {stat} {enemy[stat]} > 255 (max)")
		
		# Check for resistance/weakness overlap
		overlap = enemy['resistances'] & enemy['weaknesses']
		if overlap != 0:
			errors.append(f"{enemy['name']}: Resistance/weakness overlap: 0x{overlap:04X}")
	
	if errors:
		print("❌ Validation errors found:")
		for error in errors:
			print(f"   {error}")
		return False
	else:
		print("✅ All enemy data valid!")
		return True

if __name__ == "__main__":
	validate_enemy_data()
```

### Balance Analysis

Use visualization tools to analyze your changes:

```powershell
# Generate enemy stats visualization
python tools/visualize_elements.py

# Check enemy-attack relationships
python tools/visualize_enemy_attacks.py

# Analyze spell effectiveness
python tools/visualize_spell_effectiveness.py
```

### Testing Workflow

1. **Modify data**: Edit `enemies.json`
2. **Validate**: Run validation script
3. **Build ROM**: `python build.ps1`
4. **Quick test**: Load save near modified enemy
5. **Play test**: Verify changes feel right
6. **Iterate**: Adjust based on testing

## Best Practices

### 1. Document Your Changes

```python
# Add comments in your mod scripts
def boost_boss_stats():
	"""
	Mod: "Challenging Bosses" v1.0
	Author: YourName
	Date: 2025-11-04
	
	Description:
	- Doubles all boss HP (IDs 70-82)
	- Increases boss attack by 50%
	- Adds elemental resistances
	"""
	# ... implementation
```

### 2. Keep Backups

```powershell
# Before major changes
copy data/extracted/enemies/enemies.json data/extracted/enemies/enemies.json.backup
```

### 3. Test Incrementally

- Modify 1-5 enemies at a time
- Test each batch before continuing
- Easier to identify balance issues

### 4. Consider Player Progression

- Early enemies: Lower stats
- Mid-game: Medium stats, add elemental weaknesses
- Late game: High stats, complex element interactions
- Bosses: Unique, memorable stat distributions

### 5. Use Visualization Tools

```powershell
# Before modding: Generate baseline
python tools/visualize_elements.py
copy reports/visualizations reports/visualizations_original

# After modding: Compare
python tools/visualize_elements.py
# Compare with original to see impact
```

## Related Resources

- [Modding Quick Start](MODDING_QUICKSTART.md) - Beginner guide
- [Spell Modding Guide](SPELL_MODDING.md) - Magic system
- [Attack Modding Guide](ATTACK_MODDING.md) - Combat moves
- [Element Reference](../ELEMENT_REFERENCE.md) - Complete element documentation

---

**Have fun creating challenging encounters! ⚔️**
