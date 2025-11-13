#!/usr/bin/env python3
"""
FFMQ Bestiary Generator - Auto-generate enemy database and guides

Bestiary Features:
- Enemy database
- Stats display (HP, MP, Attack, Defense, Speed, Magic)
- Elemental affinities
- Status vulnerabilities
- Drop rates
- Location tracking
- Lore/descriptions
- Battle strategies

Enemy Data:
- Base statistics
- Elemental weaknesses/resistances
- Status effect immunities
- Attack patterns
- Special abilities
- EXP/Gil rewards
- Item drops (common/rare)

Guide Generation:
- Enemy listings by area
- Boss strategies
- Weakness charts
- Drop tables
- Completion tracking
- Search/filter

Features:
- Extract enemy data
- Generate bestiary
- Create HTML guide
- Export JSON database
- Import enemy data
- Add custom descriptions

Usage:
	python ffmq_bestiary_generator.py rom.sfc --generate
	python ffmq_bestiary_generator.py rom.sfc --list --area foresta
	python ffmq_bestiary_generator.py rom.sfc --enemy goblin
	python ffmq_bestiary_generator.py rom.sfc --export bestiary.json
	python ffmq_bestiary_generator.py rom.sfc --html bestiary.html
"""

import argparse
import json
from pathlib import Path
from typing import List, Dict, Tuple, Optional, Any
from dataclasses import dataclass, asdict, field
from enum import Enum


class EnemyType(Enum):
	"""Enemy categories"""
	NORMAL = "normal"
	BOSS = "boss"
	MINIBOSS = "miniboss"
	RARE = "rare"


class Element(Enum):
	"""Elemental types"""
	NONE = "none"
	FIRE = "fire"
	ICE = "ice"
	THUNDER = "thunder"
	EARTH = "earth"
	WIND = "wind"
	WATER = "water"
	HOLY = "holy"
	DARK = "dark"


@dataclass
class ElementalAffinity:
	"""Elemental weakness/resistance"""
	element: Element
	modifier: float  # 0.0 = immune, 0.5 = resist, 1.0 = neutral, 1.5 = weak, 2.0 = very weak
	
	def to_dict(self) -> dict:
		return {
			'element': self.element.value,
			'modifier': self.modifier
		}


@dataclass
class ItemDrop:
	"""Enemy item drop"""
	item_id: int
	item_name: str
	drop_rate: int  # 0-100%
	rare: bool
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class Enemy:
	"""Enemy definition"""
	enemy_id: int
	name: str
	enemy_type: EnemyType
	level: int
	hp: int
	mp: int
	attack: int
	defense: int
	speed: int
	magic: int
	exp_reward: int
	gil_reward: int
	elemental_affinities: List[ElementalAffinity]
	status_immunities: List[str]
	drops: List[ItemDrop]
	locations: List[str]
	description: str
	strategy: str
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['enemy_type'] = self.enemy_type.value
		d['elemental_affinities'] = [a.to_dict() for a in self.elemental_affinities]
		d['drops'] = [drop.to_dict() for drop in self.drops]
		return d


class FFMQBestiaryGenerator:
	"""Enemy database and guide generator"""
	
	# Enemy data (sample)
	ENEMY_DATA = {
		1: {
			'name': 'Goblin',
			'type': EnemyType.NORMAL,
			'level': 3,
			'hp': 45,
			'mp': 0,
			'attack': 12,
			'defense': 8,
			'speed': 10,
			'magic': 0,
			'exp': 15,
			'gil': 20,
			'affinities': [
				{'element': Element.FIRE, 'modifier': 1.5},
				{'element': Element.ICE, 'modifier': 0.5}
			],
			'immunities': [],
			'drops': [
				{'item_id': 1, 'name': 'Cure Potion', 'rate': 30, 'rare': False},
				{'item_id': 50, 'name': 'Goblin Fang', 'rate': 5, 'rare': True}
			],
			'locations': ['Hill of Destiny', 'Foresta'],
			'description': 'Small green humanoid creature. Weak but travel in groups.',
			'strategy': 'Use fire magic for extra damage. Physical attacks work well.'
		},
		10: {
			'name': 'Hydra',
			'type': EnemyType.BOSS,
			'level': 10,
			'hp': 450,
			'mp': 100,
			'attack': 35,
			'defense': 20,
			'speed': 15,
			'magic': 25,
			'exp': 250,
			'gil': 500,
			'affinities': [
				{'element': Element.FIRE, 'modifier': 2.0},
				{'element': Element.WATER, 'modifier': 0.0}
			],
			'immunities': ['poison', 'sleep'],
			'drops': [
				{'item_id': 100, 'name': 'Hydra Scale', 'rate': 100, 'rare': False}
			],
			'locations': ['Falls Basin'],
			'description': 'Multi-headed serpent boss. First major challenge.',
			'strategy': 'Focus fire magic on heads. Avoid water attacks. Cure often.'
		},
		20: {
			'name': 'Red Bone',
			'type': EnemyType.NORMAL,
			'level': 8,
			'hp': 120,
			'mp': 20,
			'attack': 25,
			'defense': 15,
			'speed': 12,
			'magic': 10,
			'exp': 45,
			'gil': 60,
			'affinities': [
				{'element': Element.HOLY, 'modifier': 1.5},
				{'element': Element.DARK, 'modifier': 0.5}
			],
			'immunities': ['poison', 'death'],
			'drops': [
				{'item_id': 2, 'name': 'Heal Potion', 'rate': 25, 'rare': False},
				{'item_id': 51, 'name': 'Bone', 'rate': 10, 'rare': True}
			],
			'locations': ['Bone Dungeon', 'Spencer Cave'],
			'description': 'Undead skeleton warrior. Vulnerable to holy magic.',
			'strategy': 'Use White magic spells. Physical attacks less effective.'
		}
	}
	
	# Area data
	AREAS = {
		'foresta': 'Foresta Region',
		'aquaria': 'Aquaria Region',
		'fireburg': 'Fireburg Region',
		'windia': 'Windia Region'
	}
	
	def __init__(self, rom_path: Optional[Path] = None, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		self.enemies: List[Enemy] = []
		
		if rom_path:
			with open(rom_path, 'rb') as f:
				self.rom_data = bytearray(f.read())
			
			if self.verbose:
				print(f"Loaded ROM: {rom_path}")
	
	def load_enemies(self) -> None:
		"""Load enemy data"""
		self.enemies = []
		
		for enemy_id, data in self.ENEMY_DATA.items():
			# Build affinities
			affinities = []
			for aff_data in data['affinities']:
				affinity = ElementalAffinity(
					element=aff_data['element'],
					modifier=aff_data['modifier']
				)
				affinities.append(affinity)
			
			# Build drops
			drops = []
			for drop_data in data['drops']:
				drop = ItemDrop(**drop_data)
				drops.append(drop)
			
			enemy = Enemy(
				enemy_id=enemy_id,
				name=data['name'],
				enemy_type=data['type'],
				level=data['level'],
				hp=data['hp'],
				mp=data['mp'],
				attack=data['attack'],
				defense=data['defense'],
				speed=data['speed'],
				magic=data['magic'],
				exp_reward=data['exp'],
				gil_reward=data['gil'],
				elemental_affinities=affinities,
				status_immunities=data['immunities'],
				drops=drops,
				locations=data['locations'],
				description=data['description'],
				strategy=data['strategy']
			)
			
			self.enemies.append(enemy)
		
		if self.verbose:
			print(f"✓ Loaded {len(self.enemies)} enemies")
	
	def get_enemies_by_location(self, location: str) -> List[Enemy]:
		"""Get enemies in location"""
		return [e for e in self.enemies if location in [loc.lower() for loc in e.locations]]
	
	def get_bosses(self) -> List[Enemy]:
		"""Get boss enemies"""
		return [e for e in self.enemies if e.enemy_type in [EnemyType.BOSS, EnemyType.MINIBOSS]]
	
	def generate_weakness_chart(self) -> Dict[str, Dict[str, str]]:
		"""Generate elemental weakness chart"""
		chart = {}
		
		for enemy in self.enemies:
			weaknesses = []
			resistances = []
			immunities = []
			
			for affinity in enemy.elemental_affinities:
				if affinity.modifier == 0.0:
					immunities.append(affinity.element.value)
				elif affinity.modifier < 1.0:
					resistances.append(affinity.element.value)
				elif affinity.modifier > 1.0:
					weaknesses.append(affinity.element.value)
			
			chart[enemy.name] = {
				'weak': ', '.join(weaknesses) if weaknesses else 'None',
				'resist': ', '.join(resistances) if resistances else 'None',
				'immune': ', '.join(immunities) if immunities else 'None'
			}
		
		return chart
	
	def generate_drop_table(self) -> Dict[str, List[Dict[str, Any]]]:
		"""Generate item drop table"""
		table = {}
		
		for enemy in self.enemies:
			table[enemy.name] = [
				{
					'item': drop.item_name,
					'rate': f"{drop.drop_rate}%",
					'rarity': 'Rare' if drop.rare else 'Common'
				}
				for drop in enemy.drops
			]
		
		return table
	
	def generate_html(self, output_path: Path) -> None:
		"""Generate HTML bestiary"""
		html_lines = [
			"<!DOCTYPE html>",
			"<html>",
			"<head>",
			"<meta charset='UTF-8'>",
			"<title>FFMQ Bestiary</title>",
			"<style>",
			"body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }",
			"h1 { color: #333; }",
			"h2 { color: #666; border-bottom: 2px solid #999; padding-bottom: 5px; }",
			".enemy { background: white; padding: 15px; margin: 10px 0; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }",
			".boss { border-left: 5px solid #d32f2f; }",
			".normal { border-left: 5px solid #1976d2; }",
			".stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; }",
			".stat { background: #f9f9f9; padding: 8px; border-radius: 3px; }",
			".weak { color: #d32f2f; font-weight: bold; }",
			".resist { color: #1976d2; font-weight: bold; }",
			".immune { color: #757575; font-weight: bold; }",
			"</style>",
			"</head>",
			"<body>",
			"<h1>Final Fantasy Mystic Quest - Bestiary</h1>"
		]
		
		# Bosses section
		bosses = self.get_bosses()
		if bosses:
			html_lines.append("<h2>Bosses</h2>")
			for enemy in bosses:
				html_lines.extend(self._enemy_to_html(enemy, 'boss'))
		
		# Normal enemies section
		normals = [e for e in self.enemies if e.enemy_type == EnemyType.NORMAL]
		if normals:
			html_lines.append("<h2>Normal Enemies</h2>")
			for enemy in normals:
				html_lines.extend(self._enemy_to_html(enemy, 'normal'))
		
		html_lines.extend([
			"</body>",
			"</html>"
		])
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write('\n'.join(html_lines))
		
		if self.verbose:
			print(f"✓ Generated HTML bestiary: {output_path}")
	
	def _enemy_to_html(self, enemy: Enemy, css_class: str) -> List[str]:
		"""Convert enemy to HTML"""
		lines = [
			f"<div class='enemy {css_class}'>",
			f"<h3>{enemy.name} (Lv. {enemy.level})</h3>",
			f"<p><em>{enemy.description}</em></p>",
			"<div class='stats'>",
			f"<div class='stat'>HP: {enemy.hp}</div>",
			f"<div class='stat'>MP: {enemy.mp}</div>",
			f"<div class='stat'>Attack: {enemy.attack}</div>",
			f"<div class='stat'>Defense: {enemy.defense}</div>",
			f"<div class='stat'>Speed: {enemy.speed}</div>",
			f"<div class='stat'>Magic: {enemy.magic}</div>",
			"</div>",
			f"<p><strong>Rewards:</strong> {enemy.exp_reward} EXP, {enemy.gil_reward} Gil</p>"
		]
		
		# Elemental affinities
		weaknesses = [a for a in enemy.elemental_affinities if a.modifier > 1.0]
		resistances = [a for a in enemy.elemental_affinities if 0.0 < a.modifier < 1.0]
		immunities = [a for a in enemy.elemental_affinities if a.modifier == 0.0]
		
		if weaknesses or resistances or immunities:
			lines.append("<p><strong>Elements:</strong> ")
			parts = []
			if weaknesses:
				weak_list = ', '.join([a.element.value.title() for a in weaknesses])
				parts.append(f"<span class='weak'>Weak: {weak_list}</span>")
			if resistances:
				resist_list = ', '.join([a.element.value.title() for a in resistances])
				parts.append(f"<span class='resist'>Resist: {resist_list}</span>")
			if immunities:
				immune_list = ', '.join([a.element.value.title() for a in immunities])
				parts.append(f"<span class='immune'>Immune: {immune_list}</span>")
			lines.append(' | '.join(parts) + "</p>")
		
		# Drops
		if enemy.drops:
			lines.append("<p><strong>Drops:</strong>")
			lines.append("<ul>")
			for drop in enemy.drops:
				rarity = " (Rare)" if drop.rare else ""
				lines.append(f"<li>{drop.item_name}: {drop.drop_rate}%{rarity}</li>")
			lines.append("</ul></p>")
		
		# Locations
		lines.append(f"<p><strong>Locations:</strong> {', '.join(enemy.locations)}</p>")
		
		# Strategy
		if enemy.strategy:
			lines.append(f"<p><strong>Strategy:</strong> {enemy.strategy}</p>")
		
		lines.append("</div>")
		
		return lines
	
	def export_json(self, output_path: Path) -> None:
		"""Export bestiary to JSON"""
		data = {
			'enemies': [e.to_dict() for e in self.enemies],
			'total_count': len(self.enemies)
		}
		
		with open(output_path, 'w') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported bestiary to {output_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Bestiary Generator')
	parser.add_argument('rom', type=str, nargs='?', help='FFMQ ROM file (optional)')
	parser.add_argument('--generate', action='store_true', help='Generate bestiary')
	parser.add_argument('--list', action='store_true', help='List enemies')
	parser.add_argument('--enemy', type=str, help='Show specific enemy')
	parser.add_argument('--area', type=str, help='Filter by area')
	parser.add_argument('--bosses', action='store_true', help='Show only bosses')
	parser.add_argument('--export', type=str, help='Export to JSON')
	parser.add_argument('--html', type=str, help='Generate HTML guide')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	rom_path = Path(args.rom) if args.rom else None
	generator = FFMQBestiaryGenerator(rom_path=rom_path, verbose=args.verbose)
	generator.load_enemies()
	
	# List enemies
	if args.list:
		enemies = generator.enemies
		
		if args.area:
			enemies = generator.get_enemies_by_location(args.area)
		elif args.bosses:
			enemies = generator.get_bosses()
		
		print(f"\n=== Bestiary ({len(enemies)} enemies) ===\n")
		
		for enemy in enemies:
			icon = "👑" if enemy.enemy_type == EnemyType.BOSS else "⚔️"
			print(f"{icon} {enemy.name} (Lv. {enemy.level})")
			print(f"   HP: {enemy.hp}  ATK: {enemy.attack}  DEF: {enemy.defense}")
			print(f"   Locations: {', '.join(enemy.locations)}")
			print()
		
		return 0
	
	# Show specific enemy
	if args.enemy:
		enemy = next((e for e in generator.enemies if e.name.lower() == args.enemy.lower()), None)
		
		if enemy:
			print(f"\n=== {enemy.name} ===\n")
			print(f"Level: {enemy.level}")
			print(f"Type: {enemy.enemy_type.value}")
			print(f"\nStats:")
			print(f"  HP: {enemy.hp}")
			print(f"  MP: {enemy.mp}")
			print(f"  Attack: {enemy.attack}")
			print(f"  Defense: {enemy.defense}")
			print(f"  Speed: {enemy.speed}")
			print(f"  Magic: {enemy.magic}")
			print(f"\nRewards: {enemy.exp_reward} EXP, {enemy.gil_reward} Gil")
			print(f"\nDescription: {enemy.description}")
			print(f"Strategy: {enemy.strategy}")
			print()
			return 0
		else:
			print(f"Enemy not found: {args.enemy}")
			return 1
	
	# Generate HTML
	if args.html:
		generator.generate_html(Path(args.html))
		return 0
	
	# Export JSON
	if args.export:
		generator.export_json(Path(args.export))
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
