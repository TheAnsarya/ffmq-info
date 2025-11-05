# Spell Modding Guide

Complete guide to modifying magic spells and abilities in Final Fantasy Mystic Quest.

## Table of Contents

1. [Spell System Overview](#spell-system-overview)
2. [Basic Spell Modifications](#basic-spell-modifications)
3. [MP Cost Balancing](#mp-cost-balancing)
4. [Element Assignment](#element-assignment)
5. [Creating Spell Sets](#creating-spell-sets)
6. [Testing and Balance](#testing-and-balance)

## Spell System Overview

### Understanding spells.json

Location: `data/spells/spells.json`

```json
{
  "spells": [
    {
      "id": 0,
      "name": "Fire",
      "power": 19,
      "mp_cost": 12,
      "element": "Fire",
      "target": "enemy",
      "effect_type": "damage"
    }
  ]
}
```

### Spell Data Fields

| Field | Type | Range | Description |
|-------|------|-------|-------------|
| `id` | int | 0-15 | Spell ID (16 total effects) |
| `name` | string | - | Spell name |
| `power` | int | 0-255 | Spell power/potency |
| `mp_cost` | int | 0-99 | MP required to cast |
| `element` | string | - | Element type |
| `target` | string | - | Target type (enemy/ally/self) |
| `effect_type` | string | - | Effect category |

### Learnable Spells

12 spells can be learned from books/seals:
1. Exit (0)
2. Cure (1)
3. Heal (2)
4. Life (3)
5. Quake (4)
6. Blizzard (5)
7. Fire (6)
8. Aero (7)
9. Thunder (8)
10. White (9)
11. Meteor (10)
12. Flare (11)

## Basic Spell Modifications

### Example 1: Boost Spell Power

Make Fire more powerful:

```python
import json
from pathlib import Path

def boost_fire_spell():
	spells_file = Path("data/spells/spells.json")
	
	with open(spells_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	# Find Fire spell
	fire = next(s for s in data['spells'] if s['name'] == 'Fire')
	
	# Boost power
	old_power = fire['power']
	fire['power'] = 40  # Was ~20
	
	# Increase MP cost proportionally
	old_mp = fire['mp_cost']
	fire['mp_cost'] = 16  # Was ~12
	
	with open(spells_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print(f"✅ Fire spell upgraded!")
	print(f"   Power: {old_power} → {fire['power']}")
	print(f"   MP Cost: {old_mp} → {fire['mp_cost']}")

if __name__ == "__main__":
	boost_fire_spell()
```

### Example 2: Rebalance All Spells

Create a balanced spell progression:

```python
import json
from pathlib import Path

def rebalance_spell_progression():
	"""
	Rebalance spells so power increases with MP cost.
	Creates clear early/mid/late game spell tiers.
	"""
	spells_file = Path("data/spells/spells.json")
	
	with open(spells_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	# Define spell tiers
	spell_tiers = {
		# Early game (low MP, low power)
		'Fire': {'power': 25, 'mp_cost': 8},
		'Blizzard': {'power': 25, 'mp_cost': 8},
		'Thunder': {'power': 25, 'mp_cost': 8},
		
		# Mid game (medium MP, medium power)
		'Aero': {'power': 40, 'mp_cost': 12},
		'Quake': {'power': 45, 'mp_cost': 14},
		
		# Late game (high MP, high power)
		'Flare': {'power': 60, 'mp_cost': 18},
		'Meteor': {'power': 65, 'mp_cost': 20},
		'White': {'power': 70, 'mp_cost': 22},
		
		# Healing spells
		'Cure': {'power': 30, 'mp_cost': 6},
		'Heal': {'power': 50, 'mp_cost': 10},
		'Life': {'power': 40, 'mp_cost': 12},
		
		# Utility
		'Exit': {'power': 0, 'mp_cost': 4},
	}
	
	for spell in data['spells']:
		if spell['name'] in spell_tiers:
			new_stats = spell_tiers[spell['name']]
			print(f"{spell['name']:12} Power: {spell['power']:2d} → {new_stats['power']:2d}, "
			      f"MP: {spell['mp_cost']:2d} → {new_stats['mp_cost']:2d}")
			
			spell['power'] = new_stats['power']
			spell['mp_cost'] = new_stats['mp_cost']
	
	with open(spells_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print("\n✅ Spells rebalanced!")

if __name__ == "__main__":
	rebalance_spell_progression()
```

### Example 3: Scale Spell Power

Apply a multiplier to all damage spells:

```python
import json
from pathlib import Path

def scale_spell_damage(multiplier=1.5):
	"""
	Scale damage spell power by multiplier.
	Healing spells are also affected.
	"""
	spells_file = Path("data/spells/spells.json")
	
	with open(spells_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	damage_spells = ['Fire', 'Blizzard', 'Thunder', 'Aero', 'Quake', 
	                 'Flare', 'Meteor', 'White']
	
	healing_spells = ['Cure', 'Heal', 'Life']
	
	for spell in data['spells']:
		if spell['name'] in damage_spells:
			old_power = spell['power']
			spell['power'] = min(int(spell['power'] * multiplier), 255)
			print(f"{spell['name']:12} Power: {old_power:2d} → {spell['power']:2d}")
		
		elif spell['name'] in healing_spells:
			# Scale healing too, but less
			old_power = spell['power']
			spell['power'] = min(int(spell['power'] * (1 + (multiplier - 1) * 0.5)), 255)
			print(f"{spell['name']:12} Power: {old_power:2d} → {spell['power']:2d} (healing)")
	
	with open(spells_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print(f"\n✅ Applied {multiplier}x spell damage multiplier")

if __name__ == "__main__":
	scale_spell_damage(1.5)  # 50% more powerful
```

## MP Cost Balancing

### MP Cost Guidelines

| Spell Tier | MP Cost | Power Range | Examples |
|-----------|---------|-------------|----------|
| Low | 4-10 | 20-30 | Fire, Cure, Exit |
| Medium | 11-15 | 35-50 | Aero, Heal, Quake |
| High | 16-25 | 55-70+ | Flare, Meteor, White |

### Example 4: Balance MP Costs

Ensure MP costs scale with power:

```python
import json
from pathlib import Path

def balance_mp_costs():
	"""
	Adjust MP costs based on spell power.
	Formula: MP = (Power / 3) rounded up, with minimums.
	"""
	spells_file = Path("data/spells/spells.json")
	
	with open(spells_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	for spell in data['spells']:
		if spell['power'] > 0:  # Skip utility spells
			# Calculate MP based on power
			calculated_mp = max(4, (spell['power'] + 2) // 3)
			
			old_mp = spell['mp_cost']
			spell['mp_cost'] = calculated_mp
			
			print(f"{spell['name']:12} Power: {spell['power']:2d}, "
			      f"MP: {old_mp:2d} → {spell['mp_cost']:2d}")
	
	with open(spells_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print("\n✅ MP costs balanced")

if __name__ == "__main__":
	balance_mp_costs()
```

### Example 5: Low MP Challenge Mode

Make spells cheaper to encourage magic use:

```python
import json
from pathlib import Path

def low_mp_mode():
	"""Halve all MP costs (minimum 2)"""
	spells_file = Path("data/spells/spells.json")
	
	with open(spells_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	for spell in data['spells']:
		old_mp = spell['mp_cost']
		spell['mp_cost'] = max(2, spell['mp_cost'] // 2)
		print(f"{spell['name']:12} MP: {old_mp:2d} → {spell['mp_cost']:2d}")
	
	with open(spells_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print("\n✅ Low MP mode enabled")

if __name__ == "__main__":
	low_mp_mode()
```

## Element Assignment

### Element Types

Common elements in FFMQ:
- **Fire**: Fire spells
- **Water**: Blizzard spells  
- **Earth**: Quake spells
- **Air**: Aero, Thunder spells
- **Healing**: Cure, Heal, Life
- **Special**: White, Meteor

### Example 6: Change Spell Elements

Make Thunder a Fire spell:

```python
import json
from pathlib import Path

def change_spell_element(spell_name, new_element):
	"""Change a spell's element type"""
	spells_file = Path("data/spells/spells.json")
	
	with open(spells_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	spell = next((s for s in data['spells'] if s['name'] == spell_name), None)
	
	if spell:
		old_element = spell.get('element', 'Unknown')
		spell['element'] = new_element
		
		with open(spells_file, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent=2)
		
		print(f"✅ {spell_name}: {old_element} → {new_element}")
	else:
		print(f"❌ Spell '{spell_name}' not found")

if __name__ == "__main__":
	change_spell_element('Thunder', 'Fire')
```

## Creating Spell Sets

### Example 7: "Beginner Mode" Spell Set

Make all spells more accessible:

```python
import json
from pathlib import Path

def create_beginner_spell_set():
	"""
	Beginner-friendly spell balance:
	- Lower MP costs
	- Higher healing power
	- Moderate damage power
	"""
	spells_file = Path("data/spells/spells.json")
	
	with open(spells_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	beginner_stats = {
		# Damage spells - moderate power, low MP
		'Fire':     {'power': 30, 'mp_cost': 6},
		'Blizzard': {'power': 30, 'mp_cost': 6},
		'Thunder':  {'power': 30, 'mp_cost': 6},
		'Aero':     {'power': 35, 'mp_cost': 8},
		'Quake':    {'power': 40, 'mp_cost': 10},
		'Flare':    {'power': 50, 'mp_cost': 12},
		'Meteor':   {'power': 55, 'mp_cost': 14},
		'White':    {'power': 60, 'mp_cost': 16},
		
		# Healing spells - boosted power, very low MP
		'Cure':     {'power': 40, 'mp_cost': 4},
		'Heal':     {'power': 70, 'mp_cost': 6},
		'Life':     {'power': 50, 'mp_cost': 8},
		
		# Utility
		'Exit':     {'power': 0, 'mp_cost': 2},
	}
	
	for spell in data['spells']:
		if spell['name'] in beginner_stats:
			spell.update(beginner_stats[spell['name']])
			print(f"✅ {spell['name']:12} Power: {spell['power']:2d}, MP: {spell['mp_cost']:2d}")
	
	with open(spells_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print("\n✅ Beginner spell set created!")

if __name__ == "__main__":
	create_beginner_spell_set()
```

### Example 8: "Hard Mode" Spell Set

Create a challenging spell balance:

```python
import json
from pathlib import Path

def create_hard_mode_spell_set():
	"""
	Hard mode spell balance:
	- Higher MP costs
	- Lower healing power
	- Damage requires strategy
	"""
	spells_file = Path("data/spells/spells.json")
	
	with open(spells_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	hard_mode_stats = {
		# Damage spells - good power, high MP
		'Fire':     {'power': 25, 'mp_cost': 14},
		'Blizzard': {'power': 25, 'mp_cost': 14},
		'Thunder':  {'power': 25, 'mp_cost': 14},
		'Aero':     {'power': 40, 'mp_cost': 18},
		'Quake':    {'power': 45, 'mp_cost': 20},
		'Flare':    {'power': 65, 'mp_cost': 25},
		'Meteor':   {'power': 70, 'mp_cost': 28},
		'White':    {'power': 75, 'mp_cost': 30},
		
		# Healing spells - reduced power, moderate MP
		'Cure':     {'power': 25, 'mp_cost': 10},
		'Heal':     {'power': 40, 'mp_cost': 16},
		'Life':     {'power': 35, 'mp_cost': 18},
		
		# Utility
		'Exit':     {'power': 0, 'mp_cost': 8},
	}
	
	for spell in data['spells']:
		if spell['name'] in hard_mode_stats:
			spell.update(hard_mode_stats[spell['name']])
			print(f"✅ {spell['name']:12} Power: {spell['power']:2d}, MP: {spell['mp_cost']:2d}")
	
	with open(spells_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print("\n✅ Hard mode spell set created!")

if __name__ == "__main__":
	create_hard_mode_spell_set()
```

### Example 9: "Glass Cannon" Spell Set

High risk, high reward magic:

```python
import json
from pathlib import Path

def create_glass_cannon_spell_set():
	"""
	Glass cannon balance:
	- Very high damage power
	- Very high MP costs
	- Low healing power
	"""
	spells_file = Path("data/spells/spells.json")
	
	with open(spells_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	for spell in data['spells']:
		# Boost all damage spells significantly
		if spell['name'] in ['Fire', 'Blizzard', 'Thunder', 'Aero', 'Quake', 
		                     'Flare', 'Meteor', 'White']:
			spell['power'] = min(int(spell['power'] * 2.0), 255)
			spell['mp_cost'] = min(int(spell['mp_cost'] * 1.5), 99)
			print(f"⚡ {spell['name']:12} Power: {spell['power']:3d}, MP: {spell['mp_cost']:2d}")
		
		# Reduce healing
		elif spell['name'] in ['Cure', 'Heal', 'Life']:
			spell['power'] = max(int(spell['power'] * 0.6), 10)
			print(f"💊 {spell['name']:12} Power: {spell['power']:3d}, MP: {spell['mp_cost']:2d}")
	
	with open(spells_file, 'w', encoding='utf-8') as f:
		json.dump(data, f, indent=2)
	
	print("\n✅ Glass cannon spell set created!")

if __name__ == "__main__":
	create_glass_cannon_spell_set()
```

## Testing and Balance

### Validation Script

```python
import json
from pathlib import Path

def validate_spell_data():
	"""Check for common spell modding errors"""
	spells_file = Path("data/spells/spells.json")
	
	with open(spells_file, 'r', encoding='utf-8') as f:
		data = json.load(f)
	
	errors = []
	warnings = []
	
	for spell in data['spells']:
		# Check power range
		if spell['power'] > 255:
			errors.append(f"{spell['name']}: Power {spell['power']} > 255 (max)")
		
		# Check MP cost range
		if spell['mp_cost'] > 99:
			errors.append(f"{spell['name']}: MP cost {spell['mp_cost']} > 99 (max)")
		
		# Check if MP cost makes sense for power
		if spell['power'] > 0:  # Only for non-utility spells
			expected_mp = spell['power'] // 3
			if spell['mp_cost'] < expected_mp * 0.5:
				warnings.append(f"{spell['name']}: MP cost seems too low for power")
			elif spell['mp_cost'] > expected_mp * 2:
				warnings.append(f"{spell['name']}: MP cost seems too high for power")
	
	# Report results
	if errors:
		print("❌ Validation errors:")
		for error in errors:
			print(f"   {error}")
	
	if warnings:
		print("\n⚠️  Warnings:")
		for warning in warnings:
			print(f"   {warning}")
	
	if not errors and not warnings:
		print("✅ All spell data valid!")
	
	return len(errors) == 0

if __name__ == "__main__":
	validate_spell_data()
```

### Spell Effectiveness Analysis

Use visualization tools to see spell impact:

```powershell
# Generate spell effectiveness matrix
python tools/visualize_spell_effectiveness.py

# Check spell recommendations
type reports\visualizations\spell_recommendations.txt

# View spell statistics
type reports\visualizations\spell_statistics.txt
```

### Balance Testing Workflow

1. **Modify spells**: Edit `spells.json`
2. **Validate**: Run validation script
3. **Analyze**: Check spell effectiveness visualization
4. **Build ROM**: `python build.ps1`
5. **Test in-game**: Try spells against various enemies
6. **Iterate**: Adjust based on feel

### MP Pool Considerations

Remember to consider the player's MP pool:

- **Benjamin**: ~100 MP at max level
- **Allies**: ~80 MP at max level

Design spell costs around these limits:
- Low spells: 4-10 MP (castable 10+ times)
- Medium spells: 11-20 MP (castable 5-8 times)
- High spells: 21-30 MP (castable 3-4 times)

## Best Practices

### 1. Create Meaningful Choices

```python
# Bad: All spells cost same MP
Fire:     power=30, mp=10
Blizzard: power=30, mp=10
Thunder:  power=30, mp=10

# Good: Different costs create strategic choices
Fire:     power=25, mp=8   # Efficient
Blizzard: power=35, mp=14  # Powerful but expensive
Thunder:  power=30, mp=10  # Balanced
```

### 2. Scale Appropriately

```python
# Bad: Linear scaling
Early: Fire    power=20, mp=8
Mid:   Flare   power=40, mp=16
Late:  Meteor  power=60, mp=24

# Good: Exponential scaling
Early: Fire    power=20, mp=8
Mid:   Flare   power=50, mp=16
Late:  Meteor  power=80, mp=24
```

### 3. Test Against Enemy HP

```python
# Check spell damage relative to enemy HP
enemies_file = Path("data/extracted/enemies/enemies.json")
with open(enemies_file, 'r') as f:
	enemies = json.load(f)['enemies']

avg_hp = sum(e['hp'] for e in enemies) / len(enemies)
print(f"Average enemy HP: {avg_hp:.0f}")

# Your strongest spell should 2-3 shot average enemies
strongest_spell_power = 70
hits_to_kill = avg_hp / strongest_spell_power
print(f"Hits to kill with strongest spell: {hits_to_kill:.1f}")
```

### 4. Document Your Changes

```python
# Create a spell balance document
def export_spell_balance():
	spells_file = Path("data/spells/spells.json")
	with open(spells_file, 'r') as f:
		data = json.load(f)
	
	print("# Spell Balance Chart")
	print("\n| Spell | Power | MP | Power/MP Ratio |")
	print("|-------|-------|----|----|")
	
	for spell in sorted(data['spells'], key=lambda s: s['mp_cost']):
		if spell['power'] > 0:
			ratio = spell['power'] / max(spell['mp_cost'], 1)
			print(f"| {spell['name']:12} | {spell['power']:3d} | "
			      f"{spell['mp_cost']:2d} | {ratio:.2f} |")
```

### 5. Consider Spell Synergies

Think about how spells work together:

```python
# Example: Ensure element variety
elements = {}
for spell in data['spells']:
	element = spell.get('element', 'None')
	elements[element] = elements.get(element, 0) + 1

print("Element distribution:")
for element, count in elements.items():
	print(f"  {element}: {count} spells")
```

## Related Resources

- [Modding Quick Start](MODDING_QUICKSTART.md) - Beginner guide
- [Enemy Modding Guide](ENEMY_MODDING.md) - Enemy stats
- [Element Reference](../ELEMENT_REFERENCE.md) - Element system
- [Spell Effectiveness Matrix](../../reports/visualizations/spell_effectiveness_matrix.csv)

---

**Happy spell crafting! ✨🔮**
