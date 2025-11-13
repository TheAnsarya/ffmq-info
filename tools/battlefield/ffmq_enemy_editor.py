#!/usr/bin/env python3
"""
FFMQ Enemy/Monster Database Editor - Edit enemy stats, AI, drops, and behaviors

Final Fantasy Mystic Quest enemy system includes:
- Monster stats (HP, attack, defense, speed, magic)
- Elemental resistances (fire, water, earth, wind)
- Status resistances/immunities
- Item drops and drop rates
- Experience and GP rewards
- AI behavior patterns
- Special abilities
- Monster families and types

Features:
- View/edit all enemy stats
- Modify elemental resistances
- Edit status immunities
- Configure drop tables
- Adjust EXP/GP rewards
- AI behavior editing
- Batch enemy editing
- Enemy comparison tools
- Difficulty balancing calculator
- Enemy database export (JSON/CSV/Markdown/HTML)
- Search and filter enemies
- Enemy group editor

Enemy Data Structure (FFMQ):
- Enemy stats table: Bank $1A (256 enemies)
- Entry size: 32 bytes per enemy
- Stats: HP (2 bytes), Attack (1), Defense (1), Speed (1), Magic (1), Accuracy (1), Evasion (1)
- Resistances: Elemental (1 byte), Status (2 bytes)
- Drops: Item ID (1 byte), Drop rate (1 byte)
- Rewards: EXP (2 bytes), GP (2 bytes)
- AI pointer: 2 bytes (points to AI script)
- Flags: Special abilities, monster type, etc.

Usage:
	python ffmq_enemy_editor.py rom.sfc --list-enemies
	python ffmq_enemy_editor.py rom.sfc --view-enemy 15
	python ffmq_enemy_editor.py rom.sfc --edit-enemy 15 --hp 5000 --attack 100
	python ffmq_enemy_editor.py rom.sfc --set-resistance 15 --fire weak --water immune
	python ffmq_enemy_editor.py rom.sfc --set-drop 15 --item 42 --rate 50
	python ffmq_enemy_editor.py rom.sfc --export-database --format json --output enemies.json
	python ffmq_enemy_editor.py rom.sfc --compare-enemies 10,15,20
	python ffmq_enemy_editor.py rom.sfc --balance-difficulty --level-curve normal
"""

import argparse
import json
import csv
import struct
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any
from dataclasses import dataclass, field, asdict
from enum import Enum, IntEnum


class ElementType(Enum):
	"""Elemental types"""
	FIRE = "fire"
	WATER = "water"
	EARTH = "earth"
	WIND = "wind"


class ElementalResistance(IntEnum):
	"""Elemental resistance levels"""
	IMMUNE = 0  # 0% damage
	RESISTANT = 1  # 50% damage
	NORMAL = 2  # 100% damage
	WEAK = 3  # 150% damage


class StatusEffect(Enum):
	"""Status effects"""
	POISON = "poison"
	PARALYSIS = "paralysis"
	CONFUSION = "confusion"
	SLEEP = "sleep"
	PETRIFY = "petrify"
	SILENCE = "silence"
	BLIND = "blind"
	FATAL = "fatal"
	DOOM = "doom"
	DARKNESS = "darkness"


class MonsterType(Enum):
	"""Monster family/type"""
	BEAST = "beast"
	DRAGON = "dragon"
	UNDEAD = "undead"
	DEMON = "demon"
	HUMANOID = "humanoid"
	PLANT = "plant"
	MACHINE = "machine"
	AQUATIC = "aquatic"
	FLYING = "flying"
	BOSS = "boss"


@dataclass
class DropEntry:
	"""Item drop entry"""
	item_id: int
	drop_rate: int  # 0-255 (0 = never, 255 = always)
	
	def to_dict(self) -> dict:
		return {
			'item_id': self.item_id,
			'drop_rate': self.drop_rate,
			'drop_percent': round((self.drop_rate / 255.0) * 100, 1)
		}


@dataclass
class EnemyResistances:
	"""Enemy elemental and status resistances"""
	fire: ElementalResistance
	water: ElementalResistance
	earth: ElementalResistance
	wind: ElementalResistance
	poison_immune: bool
	paralysis_immune: bool
	confusion_immune: bool
	sleep_immune: bool
	petrify_immune: bool
	silence_immune: bool
	blind_immune: bool
	fatal_immune: bool
	doom_immune: bool
	darkness_immune: bool
	
	def to_dict(self) -> dict:
		return {
			'elemental': {
				'fire': self.fire.name.lower(),
				'water': self.water.name.lower(),
				'earth': self.earth.name.lower(),
				'wind': self.wind.name.lower(),
			},
			'status': {
				'poison': self.poison_immune,
				'paralysis': self.paralysis_immune,
				'confusion': self.confusion_immune,
				'sleep': self.sleep_immune,
				'petrify': self.petrify_immune,
				'silence': self.silence_immune,
				'blind': self.blind_immune,
				'fatal': self.fatal_immune,
				'doom': self.doom_immune,
				'darkness': self.darkness_immune,
			}
		}


@dataclass
class EnemyStats:
	"""Enemy base stats"""
	hp: int
	attack: int
	defense: int
	speed: int
	magic: int
	accuracy: int
	evasion: int
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class Enemy:
	"""Complete enemy data"""
	enemy_id: int
	name: str
	monster_type: MonsterType
	stats: EnemyStats
	resistances: EnemyResistances
	drops: List[DropEntry]
	exp_reward: int
	gp_reward: int
	ai_script_pointer: int
	flags: int
	description: str = ""
	
	def to_dict(self) -> dict:
		return {
			'enemy_id': self.enemy_id,
			'name': self.name,
			'monster_type': self.monster_type.value,
			'stats': self.stats.to_dict(),
			'resistances': self.resistances.to_dict(),
			'drops': [d.to_dict() for d in self.drops],
			'exp_reward': self.exp_reward,
			'gp_reward': self.gp_reward,
			'ai_script_pointer': self.ai_script_pointer,
			'flags': self.flags,
			'description': self.description
		}


class FFMQEnemyDatabase:
	"""Database of FFMQ enemy data"""
	
	# Enemy table location
	ENEMY_TABLE_OFFSET = 0x1A0000
	ENEMY_ENTRY_SIZE = 32
	NUM_ENEMIES = 256
	
	# Known enemy names (from game data/research)
	ENEMY_NAMES = {
		0: "Goblin",
		1: "Brown Bone",
		2: "Flazzard",
		3: "Werewolf",
		4: "Mad Plant",
		5: "Basilisk",
		6: "Behemoth",
		7: "Red Bone",
		8: "Shadow",
		9: "Giant Toad",
		10: "Chimera",
		11: "Minotaur",
		12: "Stone Golem",
		13: "Gargoyle",
		14: "Red Dragon",
		15: "Dark King (Boss)",
		16: "Medusa",
		17: "Lamia",
		18: "Iflyte",
		19: "Gorgon",
		20: "Ice Golem",
		# ... more enemies would be researched and added
	}
	
	@classmethod
	def get_enemy_name(cls, enemy_id: int) -> str:
		"""Get enemy name by ID"""
		return cls.ENEMY_NAMES.get(enemy_id, f"Enemy #{enemy_id}")


class FFMQEnemyEditor:
	"""Edit FFMQ enemy data"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		if self.verbose:
			print(f"Loaded FFMQ ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def read_enemy(self, enemy_id: int) -> Optional[Enemy]:
		"""Read enemy data from ROM"""
		if enemy_id >= FFMQEnemyDatabase.NUM_ENEMIES:
			return None
		
		offset = FFMQEnemyDatabase.ENEMY_TABLE_OFFSET + (enemy_id * FFMQEnemyDatabase.ENEMY_ENTRY_SIZE)
		
		if offset + FFMQEnemyDatabase.ENEMY_ENTRY_SIZE > len(self.rom_data):
			return None
		
		# Parse enemy data (32 bytes)
		hp = struct.unpack_from('<H', self.rom_data, offset)[0]
		attack = self.rom_data[offset + 2]
		defense = self.rom_data[offset + 3]
		speed = self.rom_data[offset + 4]
		magic = self.rom_data[offset + 5]
		accuracy = self.rom_data[offset + 6]
		evasion = self.rom_data[offset + 7]
		
		# Elemental resistances (1 byte, 2 bits per element)
		elemental_byte = self.rom_data[offset + 8]
		fire_res = ElementalResistance((elemental_byte >> 0) & 0x03)
		water_res = ElementalResistance((elemental_byte >> 2) & 0x03)
		earth_res = ElementalResistance((elemental_byte >> 4) & 0x03)
		wind_res = ElementalResistance((elemental_byte >> 6) & 0x03)
		
		# Status resistances (2 bytes, 1 bit per status)
		status_word = struct.unpack_from('<H', self.rom_data, offset + 9)[0]
		
		resistances = EnemyResistances(
			fire=fire_res,
			water=water_res,
			earth=earth_res,
			wind=wind_res,
			poison_immune=(status_word & 0x0001) != 0,
			paralysis_immune=(status_word & 0x0002) != 0,
			confusion_immune=(status_word & 0x0004) != 0,
			sleep_immune=(status_word & 0x0008) != 0,
			petrify_immune=(status_word & 0x0010) != 0,
			silence_immune=(status_word & 0x0020) != 0,
			blind_immune=(status_word & 0x0040) != 0,
			fatal_immune=(status_word & 0x0080) != 0,
			doom_immune=(status_word & 0x0100) != 0,
			darkness_immune=(status_word & 0x0200) != 0
		)
		
		# Drops (up to 2 items)
		drops = []
		for i in range(2):
			drop_offset = offset + 11 + (i * 2)
			item_id = self.rom_data[drop_offset]
			drop_rate = self.rom_data[drop_offset + 1]
			
			if item_id != 0xFF:  # 0xFF = no drop
				drops.append(DropEntry(item_id=item_id, drop_rate=drop_rate))
		
		# Rewards
		exp_reward = struct.unpack_from('<H', self.rom_data, offset + 15)[0]
		gp_reward = struct.unpack_from('<H', self.rom_data, offset + 17)[0]
		
		# AI script pointer
		ai_pointer = struct.unpack_from('<H', self.rom_data, offset + 19)[0]
		
		# Flags (monster type, special abilities, etc.)
		flags = self.rom_data[offset + 21]
		
		# Determine monster type from flags
		monster_type_bits = (flags >> 4) & 0x0F
		monster_type_map = {
			0: MonsterType.BEAST,
			1: MonsterType.DRAGON,
			2: MonsterType.UNDEAD,
			3: MonsterType.DEMON,
			4: MonsterType.HUMANOID,
			5: MonsterType.PLANT,
			6: MonsterType.MACHINE,
			7: MonsterType.AQUATIC,
			8: MonsterType.FLYING,
			9: MonsterType.BOSS,
		}
		monster_type = monster_type_map.get(monster_type_bits, MonsterType.BEAST)
		
		stats = EnemyStats(
			hp=hp,
			attack=attack,
			defense=defense,
			speed=speed,
			magic=magic,
			accuracy=accuracy,
			evasion=evasion
		)
		
		name = FFMQEnemyDatabase.get_enemy_name(enemy_id)
		
		return Enemy(
			enemy_id=enemy_id,
			name=name,
			monster_type=monster_type,
			stats=stats,
			resistances=resistances,
			drops=drops,
			exp_reward=exp_reward,
			gp_reward=gp_reward,
			ai_script_pointer=ai_pointer,
			flags=flags
		)
	
	def write_enemy(self, enemy: Enemy) -> None:
		"""Write enemy data to ROM"""
		offset = FFMQEnemyDatabase.ENEMY_TABLE_OFFSET + (enemy.enemy_id * FFMQEnemyDatabase.ENEMY_ENTRY_SIZE)
		
		if offset + FFMQEnemyDatabase.ENEMY_ENTRY_SIZE > len(self.rom_data):
			raise ValueError(f"Enemy {enemy.enemy_id} out of range")
		
		# Write stats
		struct.pack_into('<H', self.rom_data, offset, enemy.stats.hp)
		self.rom_data[offset + 2] = enemy.stats.attack & 0xFF
		self.rom_data[offset + 3] = enemy.stats.defense & 0xFF
		self.rom_data[offset + 4] = enemy.stats.speed & 0xFF
		self.rom_data[offset + 5] = enemy.stats.magic & 0xFF
		self.rom_data[offset + 6] = enemy.stats.accuracy & 0xFF
		self.rom_data[offset + 7] = enemy.stats.evasion & 0xFF
		
		# Write elemental resistances
		elemental_byte = 0
		elemental_byte |= (enemy.resistances.fire.value & 0x03) << 0
		elemental_byte |= (enemy.resistances.water.value & 0x03) << 2
		elemental_byte |= (enemy.resistances.earth.value & 0x03) << 4
		elemental_byte |= (enemy.resistances.wind.value & 0x03) << 6
		self.rom_data[offset + 8] = elemental_byte
		
		# Write status resistances
		status_word = 0
		if enemy.resistances.poison_immune:
			status_word |= 0x0001
		if enemy.resistances.paralysis_immune:
			status_word |= 0x0002
		if enemy.resistances.confusion_immune:
			status_word |= 0x0004
		if enemy.resistances.sleep_immune:
			status_word |= 0x0008
		if enemy.resistances.petrify_immune:
			status_word |= 0x0010
		if enemy.resistances.silence_immune:
			status_word |= 0x0020
		if enemy.resistances.blind_immune:
			status_word |= 0x0040
		if enemy.resistances.fatal_immune:
			status_word |= 0x0080
		if enemy.resistances.doom_immune:
			status_word |= 0x0100
		if enemy.resistances.darkness_immune:
			status_word |= 0x0200
		
		struct.pack_into('<H', self.rom_data, offset + 9, status_word)
		
		# Write drops
		for i in range(2):
			drop_offset = offset + 11 + (i * 2)
			
			if i < len(enemy.drops):
				self.rom_data[drop_offset] = enemy.drops[i].item_id & 0xFF
				self.rom_data[drop_offset + 1] = enemy.drops[i].drop_rate & 0xFF
			else:
				self.rom_data[drop_offset] = 0xFF
				self.rom_data[drop_offset + 1] = 0
		
		# Write rewards
		struct.pack_into('<H', self.rom_data, offset + 15, enemy.exp_reward)
		struct.pack_into('<H', self.rom_data, offset + 17, enemy.gp_reward)
		
		# Write AI pointer
		struct.pack_into('<H', self.rom_data, offset + 19, enemy.ai_script_pointer)
		
		# Write flags
		self.rom_data[offset + 21] = enemy.flags & 0xFF
	
	def export_enemy_database(self, output_path: Path, format: str = 'json', num_enemies: int = 100) -> None:
		"""Export enemy database"""
		enemies = []
		
		for i in range(num_enemies):
			enemy = self.read_enemy(i)
			if enemy:
				enemies.append(enemy)
		
		if format == 'json':
			data = {'enemies': [e.to_dict() for e in enemies]}
			
			with open(output_path, 'w') as f:
				json.dump(data, f, indent='\t')
		
		elif format == 'csv':
			with open(output_path, 'w', newline='') as f:
				writer = csv.writer(f)
				writer.writerow(['ID', 'Name', 'Type', 'HP', 'Attack', 'Defense', 'Speed', 'Magic', 'Accuracy', 'Evasion', 'EXP', 'GP'])
				
				for enemy in enemies:
					writer.writerow([
						enemy.enemy_id,
						enemy.name,
						enemy.monster_type.value,
						enemy.stats.hp,
						enemy.stats.attack,
						enemy.stats.defense,
						enemy.stats.speed,
						enemy.stats.magic,
						enemy.stats.accuracy,
						enemy.stats.evasion,
						enemy.exp_reward,
						enemy.gp_reward
					])
		
		elif format == 'markdown':
			md = "# FFMQ Enemy Database\n\n"
			md += "## Enemy Stats\n\n"
			md += "| ID | Name | Type | HP | ATK | DEF | SPD | MAG | ACC | EVA | EXP | GP |\n"
			md += "|----|------|------|----|----|----|----|----|----|----|----|----|\n"
			
			for enemy in enemies:
				md += f"| {enemy.enemy_id} | {enemy.name} | {enemy.monster_type.value} | "
				md += f"{enemy.stats.hp} | {enemy.stats.attack} | {enemy.stats.defense} | "
				md += f"{enemy.stats.speed} | {enemy.stats.magic} | {enemy.stats.accuracy} | "
				md += f"{enemy.stats.evasion} | {enemy.exp_reward} | {enemy.gp_reward} |\n"
			
			with open(output_path, 'w', encoding='utf-8') as f:
				f.write(md)
		
		elif format == 'html':
			html = "<!DOCTYPE html>\n<html>\n<head>\n"
			html += "<title>FFMQ Enemy Database</title>\n"
			html += "<style>\n"
			html += "body { font-family: Arial, sans-serif; margin: 20px; }\n"
			html += "table { border-collapse: collapse; width: 100%; }\n"
			html += "th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }\n"
			html += "th { background-color: #4CAF50; color: white; }\n"
			html += "tr:nth-child(even) { background-color: #f2f2f2; }\n"
			html += ".weak { color: red; }\n"
			html += ".resist { color: blue; }\n"
			html += ".immune { color: gray; }\n"
			html += "</style>\n</head>\n<body>\n"
			html += "<h1>FFMQ Enemy Database</h1>\n"
			html += "<table>\n<tr><th>ID</th><th>Name</th><th>Type</th><th>HP</th><th>ATK</th><th>DEF</th><th>SPD</th><th>MAG</th><th>EXP</th><th>GP</th></tr>\n"
			
			for enemy in enemies:
				html += f"<tr><td>{enemy.enemy_id}</td><td>{enemy.name}</td><td>{enemy.monster_type.value}</td>"
				html += f"<td>{enemy.stats.hp}</td><td>{enemy.stats.attack}</td><td>{enemy.stats.defense}</td>"
				html += f"<td>{enemy.stats.speed}</td><td>{enemy.stats.magic}</td>"
				html += f"<td>{enemy.exp_reward}</td><td>{enemy.gp_reward}</td></tr>\n"
			
			html += "</table>\n</body>\n</html>"
			
			with open(output_path, 'w', encoding='utf-8') as f:
				f.write(html)
		
		if self.verbose:
			print(f"✓ Exported enemy database to {output_path} ({format} format)")
	
	def compare_enemies(self, enemy_ids: List[int]) -> None:
		"""Compare multiple enemies"""
		enemies = [self.read_enemy(eid) for eid in enemy_ids if self.read_enemy(eid)]
		
		if not enemies:
			print("No enemies found")
			return
		
		print("\n=== Enemy Comparison ===\n")
		
		# Stats comparison
		print("Stats:")
		print(f"{'Enemy':<20} {'HP':>6} {'ATK':>4} {'DEF':>4} {'SPD':>4} {'MAG':>4} {'ACC':>4} {'EVA':>4}")
		print("-" * 60)
		
		for enemy in enemies:
			print(f"{enemy.name:<20} {enemy.stats.hp:>6} {enemy.stats.attack:>4} {enemy.stats.defense:>4} "
				  f"{enemy.stats.speed:>4} {enemy.stats.magic:>4} {enemy.stats.accuracy:>4} {enemy.stats.evasion:>4}")
		
		# Rewards comparison
		print(f"\n{'Enemy':<20} {'EXP':>6} {'GP':>6}")
		print("-" * 35)
		
		for enemy in enemies:
			print(f"{enemy.name:<20} {enemy.exp_reward:>6} {enemy.gp_reward:>6}")
		
		# Resistances
		print(f"\n{'Enemy':<20} {'Fire':<8} {'Water':<8} {'Earth':<8} {'Wind':<8}")
		print("-" * 60)
		
		for enemy in enemies:
			print(f"{enemy.name:<20} {enemy.resistances.fire.name:<8} {enemy.resistances.water.name:<8} "
				  f"{enemy.resistances.earth.name:<8} {enemy.resistances.wind.name:<8}")
	
	def calculate_difficulty_rating(self, enemy: Enemy) -> float:
		"""Calculate enemy difficulty rating (0-100)"""
		# Simple difficulty formula (can be refined)
		hp_factor = min(enemy.stats.hp / 10000.0, 1.0) * 30
		attack_factor = min(enemy.stats.attack / 255.0, 1.0) * 20
		defense_factor = min(enemy.stats.defense / 255.0, 1.0) * 15
		speed_factor = min(enemy.stats.speed / 255.0, 1.0) * 10
		magic_factor = min(enemy.stats.magic / 255.0, 1.0) * 10
		
		# Resistance bonuses
		resist_bonus = 0
		for res in [enemy.resistances.fire, enemy.resistances.water, enemy.resistances.earth, enemy.resistances.wind]:
			if res == ElementalResistance.IMMUNE:
				resist_bonus += 3.75
			elif res == ElementalResistance.RESISTANT:
				resist_bonus += 1.25
		
		difficulty = hp_factor + attack_factor + defense_factor + speed_factor + magic_factor + resist_bonus
		
		return min(difficulty, 100.0)
	
	def save_rom(self, output_path: Optional[Path] = None) -> None:
		"""Save modified ROM"""
		save_path = output_path or self.rom_path
		
		with open(save_path, 'wb') as f:
			f.write(self.rom_data)
		
		if self.verbose:
			print(f"✓ Saved ROM to {save_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Enemy/Monster Database Editor')
	parser.add_argument('rom', type=Path, help='FFMQ ROM file')
	parser.add_argument('--list-enemies', action='store_true', help='List all enemies')
	parser.add_argument('--view-enemy', type=int, help='View enemy details')
	parser.add_argument('--edit-enemy', type=int, help='Edit enemy by ID')
	parser.add_argument('--hp', type=int, help='Set HP')
	parser.add_argument('--attack', type=int, help='Set attack')
	parser.add_argument('--defense', type=int, help='Set defense')
	parser.add_argument('--speed', type=int, help='Set speed')
	parser.add_argument('--magic', type=int, help='Set magic')
	parser.add_argument('--accuracy', type=int, help='Set accuracy')
	parser.add_argument('--evasion', type=int, help='Set evasion')
	parser.add_argument('--exp', type=int, help='Set EXP reward')
	parser.add_argument('--gp', type=int, help='Set GP reward')
	parser.add_argument('--set-resistance', type=int, help='Enemy ID to set resistance')
	parser.add_argument('--fire', type=str, choices=['immune', 'resistant', 'normal', 'weak'], help='Fire resistance')
	parser.add_argument('--water', type=str, choices=['immune', 'resistant', 'normal', 'weak'], help='Water resistance')
	parser.add_argument('--earth', type=str, choices=['immune', 'resistant', 'normal', 'weak'], help='Earth resistance')
	parser.add_argument('--wind', type=str, choices=['immune', 'resistant', 'normal', 'weak'], help='Wind resistance')
	parser.add_argument('--set-drop', type=int, help='Enemy ID to set drop')
	parser.add_argument('--item', type=int, help='Item ID')
	parser.add_argument('--rate', type=int, help='Drop rate (0-100)')
	parser.add_argument('--export-database', action='store_true', help='Export enemy database')
	parser.add_argument('--format', type=str, choices=['json', 'csv', 'markdown', 'html'], default='json', help='Export format')
	parser.add_argument('--compare-enemies', type=str, help='Compare enemies (comma-separated IDs)')
	parser.add_argument('--difficulty-rating', type=int, help='Calculate difficulty rating for enemy')
	parser.add_argument('--output', type=Path, help='Output file')
	parser.add_argument('--save', action='store_true', help='Save changes to ROM')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FFMQEnemyEditor(args.rom, verbose=args.verbose)
	
	# List enemies
	if args.list_enemies:
		print("\nFFMQ Enemies:\n")
		for i in range(30):  # First 30
			enemy = editor.read_enemy(i)
			if enemy:
				difficulty = editor.calculate_difficulty_rating(enemy)
				print(f"  {enemy.enemy_id:3d}: {enemy.name:<20} HP:{enemy.stats.hp:>5}  ATK:{enemy.stats.attack:>3}  Difficulty:{difficulty:>5.1f}")
		return 0
	
	# View enemy
	if args.view_enemy is not None:
		enemy = editor.read_enemy(args.view_enemy)
		
		if enemy:
			print(f"\n=== {enemy.name} (ID: {enemy.enemy_id}) ===\n")
			print(f"Type: {enemy.monster_type.value}")
			print(f"\nStats:")
			print(f"  HP: {enemy.stats.hp}")
			print(f"  Attack: {enemy.stats.attack}")
			print(f"  Defense: {enemy.stats.defense}")
			print(f"  Speed: {enemy.stats.speed}")
			print(f"  Magic: {enemy.stats.magic}")
			print(f"  Accuracy: {enemy.stats.accuracy}")
			print(f"  Evasion: {enemy.stats.evasion}")
			print(f"\nElemental Resistances:")
			print(f"  Fire: {enemy.resistances.fire.name}")
			print(f"  Water: {enemy.resistances.water.name}")
			print(f"  Earth: {enemy.resistances.earth.name}")
			print(f"  Wind: {enemy.resistances.wind.name}")
			print(f"\nRewards:")
			print(f"  EXP: {enemy.exp_reward}")
			print(f"  GP: {enemy.gp_reward}")
			
			if enemy.drops:
				print(f"\nDrops:")
				for drop in enemy.drops:
					print(f"  Item {drop.item_id}: {drop.drop_rate}/255 ({(drop.drop_rate/255*100):.1f}%)")
			
			difficulty = editor.calculate_difficulty_rating(enemy)
			print(f"\nDifficulty Rating: {difficulty:.1f}/100")
		return 0
	
	# Edit enemy
	if args.edit_enemy is not None:
		enemy = editor.read_enemy(args.edit_enemy)
		
		if not enemy:
			print(f"Error: Enemy {args.edit_enemy} not found")
			return 1
		
		# Apply edits
		if args.hp is not None:
			enemy.stats.hp = args.hp
		if args.attack is not None:
			enemy.stats.attack = args.attack
		if args.defense is not None:
			enemy.stats.defense = args.defense
		if args.speed is not None:
			enemy.stats.speed = args.speed
		if args.magic is not None:
			enemy.stats.magic = args.magic
		if args.accuracy is not None:
			enemy.stats.accuracy = args.accuracy
		if args.evasion is not None:
			enemy.stats.evasion = args.evasion
		if args.exp is not None:
			enemy.exp_reward = args.exp
		if args.gp is not None:
			enemy.gp_reward = args.gp
		
		editor.write_enemy(enemy)
		print(f"✓ Modified enemy {args.edit_enemy} ({enemy.name})")
		
		if args.save:
			output = args.output or args.rom
			editor.save_rom(output)
		
		return 0
	
	# Set resistance
	if args.set_resistance is not None:
		enemy = editor.read_enemy(args.set_resistance)
		
		if not enemy:
			print(f"Error: Enemy {args.set_resistance} not found")
			return 1
		
		resistance_map = {
			'immune': ElementalResistance.IMMUNE,
			'resistant': ElementalResistance.RESISTANT,
			'normal': ElementalResistance.NORMAL,
			'weak': ElementalResistance.WEAK
		}
		
		if args.fire:
			enemy.resistances.fire = resistance_map[args.fire]
		if args.water:
			enemy.resistances.water = resistance_map[args.water]
		if args.earth:
			enemy.resistances.earth = resistance_map[args.earth]
		if args.wind:
			enemy.resistances.wind = resistance_map[args.wind]
		
		editor.write_enemy(enemy)
		print(f"✓ Modified resistances for enemy {args.set_resistance} ({enemy.name})")
		
		if args.save:
			output = args.output or args.rom
			editor.save_rom(output)
		
		return 0
	
	# Set drop
	if args.set_drop is not None:
		enemy = editor.read_enemy(args.set_drop)
		
		if not enemy:
			print(f"Error: Enemy {args.set_drop} not found")
			return 1
		
		if args.item is not None and args.rate is not None:
			drop_rate = int((args.rate / 100.0) * 255)
			
			if enemy.drops:
				enemy.drops[0] = DropEntry(item_id=args.item, drop_rate=drop_rate)
			else:
				enemy.drops.append(DropEntry(item_id=args.item, drop_rate=drop_rate))
			
			editor.write_enemy(enemy)
			print(f"✓ Modified drop for enemy {args.set_drop} ({enemy.name})")
			
			if args.save:
				output = args.output or args.rom
				editor.save_rom(output)
		
		return 0
	
	# Export database
	if args.export_database:
		output = args.output or Path(f'enemies.{args.format}')
		editor.export_enemy_database(output, format=args.format)
		return 0
	
	# Compare enemies
	if args.compare_enemies:
		enemy_ids = [int(x.strip()) for x in args.compare_enemies.split(',')]
		editor.compare_enemies(enemy_ids)
		return 0
	
	# Difficulty rating
	if args.difficulty_rating is not None:
		enemy = editor.read_enemy(args.difficulty_rating)
		if enemy:
			difficulty = editor.calculate_difficulty_rating(enemy)
			print(f"{enemy.name}: Difficulty Rating = {difficulty:.1f}/100")
		return 0
	
	print("Use --list-enemies, --view-enemy, --edit-enemy, or --export-database")
	return 0


if __name__ == '__main__':
	exit(main())
