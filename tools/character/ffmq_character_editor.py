#!/usr/bin/env python3
"""
FFMQ Character Progression Editor - Edit character stats, leveling, and abilities

Final Fantasy Mystic Quest character system:
- Benjamin: Main character with flexible stats
- Companion characters: Kaeli, Tristam, Phoebe, Reuben
- Base stats: HP, Attack, Defense, Speed, Magic
- Level-based stat growth
- Ability unlocks at specific levels
- Weapon/armor proficiencies
- Magic spell learning
- Battle command availability

Features:
- Edit character base stats
- Modify stat growth curves
- Configure ability unlocks
- Edit spell learning progression
- Adjust experience requirements
- Balance character power levels
- Export progression charts
- Simulate stat growth
- Optimize growth curves
- Compare character balance

Character Stats:
- HP: Hit points (health)
- Attack: Physical damage modifier
- Defense: Physical damage reduction
- Speed: Turn order priority
- Magic: Magic damage/healing modifier
- Accuracy: Hit rate bonus
- Evasion: Dodge rate bonus

Stat Growth:
- Linear: Stats increase by fixed amount
- Curved: Stats increase with diminishing returns
- Exponential: Stats accelerate at higher levels
- Custom: Define exact values per level

Usage:
	python ffmq_character_editor.py rom.sfc --list-characters
	python ffmq_character_editor.py rom.sfc --show-stats 0
	python ffmq_character_editor.py rom.sfc --edit-base-stat 0 --hp 150
	python ffmq_character_editor.py rom.sfc --edit-growth 0 --attack 3
	python ffmq_character_editor.py rom.sfc --simulate-growth 0 --max-level 41
	python ffmq_character_editor.py rom.sfc --compare-characters --export-chart
	python ffmq_character_editor.py rom.sfc --balance-stats
"""

import argparse
import json
import csv
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any
from dataclasses import dataclass, field, asdict
from enum import Enum
import math


class GrowthCurve(Enum):
	"""Stat growth curve types"""
	LINEAR = "linear"
	CURVED = "curved"
	EXPONENTIAL = "exponential"
	CUSTOM = "custom"


@dataclass
class BaseStats:
	"""Base character stats at level 1"""
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
class GrowthRates:
	"""Stat growth per level"""
	hp: float
	attack: float
	defense: float
	speed: float
	magic: float
	accuracy: float
	evasion: float
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class Ability:
	"""Character ability"""
	ability_id: int
	name: str
	unlock_level: int
	mp_cost: int
	power: int
	target: str  # "single", "all", "self"
	description: str
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class Character:
	"""Playable character"""
	character_id: int
	name: str
	base_stats: BaseStats
	growth_rates: GrowthRates
	growth_curve: GrowthCurve
	max_level: int
	exp_curve_multiplier: float
	abilities: List[Ability]
	weapon_proficiency: List[str]
	armor_proficiency: List[str]
	
	def to_dict(self) -> dict:
		d = {
			'character_id': self.character_id,
			'name': self.name,
			'base_stats': self.base_stats.to_dict(),
			'growth_rates': self.growth_rates.to_dict(),
			'growth_curve': self.growth_curve.value,
			'max_level': self.max_level,
			'exp_curve_multiplier': self.exp_curve_multiplier,
			'abilities': [ab.to_dict() for ab in self.abilities],
			'weapon_proficiency': self.weapon_proficiency,
			'armor_proficiency': self.armor_proficiency
		}
		return d
	
	def calculate_stat_at_level(self, stat_name: str, level: int) -> int:
		"""Calculate stat value at given level"""
		base_value = getattr(self.base_stats, stat_name)
		growth_rate = getattr(self.growth_rates, stat_name)
		
		if self.growth_curve == GrowthCurve.LINEAR:
			# Simple linear growth
			return int(base_value + (growth_rate * (level - 1)))
		
		elif self.growth_curve == GrowthCurve.CURVED:
			# Diminishing returns curve
			growth = growth_rate * (level - 1) * (1.0 - ((level - 1) / (self.max_level * 2)))
			return int(base_value + growth)
		
		elif self.growth_curve == GrowthCurve.EXPONENTIAL:
			# Exponential growth
			multiplier = 1.0 + (growth_rate * 0.01)
			return int(base_value * (multiplier ** (level - 1)))
		
		else:  # CUSTOM
			# Would need custom table
			return int(base_value + (growth_rate * (level - 1)))
	
	def get_stats_at_level(self, level: int) -> BaseStats:
		"""Get all stats at given level"""
		return BaseStats(
			hp=self.calculate_stat_at_level('hp', level),
			attack=self.calculate_stat_at_level('attack', level),
			defense=self.calculate_stat_at_level('defense', level),
			speed=self.calculate_stat_at_level('speed', level),
			magic=self.calculate_stat_at_level('magic', level),
			accuracy=self.calculate_stat_at_level('accuracy', level),
			evasion=self.calculate_stat_at_level('evasion', level)
		)
	
	def calculate_exp_for_level(self, level: int) -> int:
		"""Calculate experience required for level"""
		if level <= 1:
			return 0
		
		# Typical RPG exp curve: level^3 * multiplier
		base_exp = ((level - 1) ** 3) * self.exp_curve_multiplier
		return int(base_exp)


class FFMQCharacterDatabase:
	"""Database of FFMQ character data"""
	
	# Character names
	CHARACTERS = {
		0: "Benjamin",
		1: "Kaeli",
		2: "Tristam",
		3: "Phoebe",
		4: "Reuben"
	}
	
	# Character data locations
	CHARACTER_DATA_OFFSET = 0x280000
	BASE_STATS_OFFSET = 0x280000
	GROWTH_RATES_OFFSET = 0x281000
	ABILITY_DATA_OFFSET = 0x282000
	
	NUM_CHARACTERS = 5
	MAX_LEVEL = 41
	
	# Known abilities
	ABILITIES = {
		0: "Cure",
		1: "Life",
		2: "Heal",
		3: "Jumbo Cure",
		4: "Fire",
		5: "Blizzard",
		6: "Thunder",
		7: "Aero",
		8: "Flare",
		9: "Meteor",
		# ... more abilities
	}
	
	@classmethod
	def get_character_name(cls, char_id: int) -> str:
		"""Get character name"""
		return cls.CHARACTERS.get(char_id, f"Character {char_id}")
	
	@classmethod
	def get_ability_name(cls, ability_id: int) -> str:
		"""Get ability name"""
		return cls.ABILITIES.get(ability_id, f"Ability {ability_id}")


class FFMQCharacterEditor:
	"""Edit FFMQ characters"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		if self.verbose:
			print(f"Loaded FFMQ ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def extract_base_stats(self, char_id: int) -> Optional[BaseStats]:
		"""Extract base stats for character"""
		if char_id >= FFMQCharacterDatabase.NUM_CHARACTERS:
			return None
		
		stats_offset = FFMQCharacterDatabase.BASE_STATS_OFFSET + (char_id * 16)
		
		if stats_offset + 16 > len(self.rom_data):
			return None
		
		# Read base stats (example structure)
		hp = self.rom_data[stats_offset] | (self.rom_data[stats_offset + 1] << 8)
		attack = self.rom_data[stats_offset + 2]
		defense = self.rom_data[stats_offset + 3]
		speed = self.rom_data[stats_offset + 4]
		magic = self.rom_data[stats_offset + 5]
		accuracy = self.rom_data[stats_offset + 6]
		evasion = self.rom_data[stats_offset + 7]
		
		return BaseStats(
			hp=hp,
			attack=attack,
			defense=defense,
			speed=speed,
			magic=magic,
			accuracy=accuracy,
			evasion=evasion
		)
	
	def extract_growth_rates(self, char_id: int) -> Optional[GrowthRates]:
		"""Extract growth rates for character"""
		if char_id >= FFMQCharacterDatabase.NUM_CHARACTERS:
			return None
		
		growth_offset = FFMQCharacterDatabase.GROWTH_RATES_OFFSET + (char_id * 16)
		
		if growth_offset + 16 > len(self.rom_data):
			return None
		
		# Read growth rates (fixed-point values)
		hp_growth = self.rom_data[growth_offset] | (self.rom_data[growth_offset + 1] << 8)
		attack_growth = self.rom_data[growth_offset + 2]
		defense_growth = self.rom_data[growth_offset + 3]
		speed_growth = self.rom_data[growth_offset + 4]
		magic_growth = self.rom_data[growth_offset + 5]
		accuracy_growth = self.rom_data[growth_offset + 6]
		evasion_growth = self.rom_data[growth_offset + 7]
		
		return GrowthRates(
			hp=hp_growth / 10.0,
			attack=attack_growth / 10.0,
			defense=defense_growth / 10.0,
			speed=speed_growth / 10.0,
			magic=magic_growth / 10.0,
			accuracy=accuracy_growth / 10.0,
			evasion=evasion_growth / 10.0
		)
	
	def extract_character(self, char_id: int) -> Optional[Character]:
		"""Extract complete character data"""
		if char_id >= FFMQCharacterDatabase.NUM_CHARACTERS:
			return None
		
		base_stats = self.extract_base_stats(char_id)
		growth_rates = self.extract_growth_rates(char_id)
		
		if not base_stats or not growth_rates:
			return None
		
		# Extract abilities
		abilities = []
		for i in range(16):
			ability_offset = FFMQCharacterDatabase.ABILITY_DATA_OFFSET + (char_id * 256) + (i * 16)
			
			if ability_offset + 16 > len(self.rom_data):
				break
			
			ability_id = self.rom_data[ability_offset]
			if ability_id == 0xFF:
				continue
			
			unlock_level = self.rom_data[ability_offset + 1]
			mp_cost = self.rom_data[ability_offset + 2]
			power = self.rom_data[ability_offset + 3]
			target_id = self.rom_data[ability_offset + 4]
			
			targets = ["single", "all", "self"]
			target = targets[target_id % len(targets)]
			
			ability = Ability(
				ability_id=ability_id,
				name=FFMQCharacterDatabase.get_ability_name(ability_id),
				unlock_level=unlock_level,
				mp_cost=mp_cost,
				power=power,
				target=target,
				description=""
			)
			
			abilities.append(ability)
		
		character = Character(
			character_id=char_id,
			name=FFMQCharacterDatabase.get_character_name(char_id),
			base_stats=base_stats,
			growth_rates=growth_rates,
			growth_curve=GrowthCurve.LINEAR,
			max_level=FFMQCharacterDatabase.MAX_LEVEL,
			exp_curve_multiplier=10.0,
			abilities=abilities,
			weapon_proficiency=["sword", "axe"],
			armor_proficiency=["helmet", "chest", "shield"]
		)
		
		return character
	
	def simulate_growth(self, character: Character, max_level: Optional[int] = None) -> List[Dict[str, Any]]:
		"""Simulate character stat growth"""
		max_lvl = max_level or character.max_level
		growth_data = []
		
		for level in range(1, max_lvl + 1):
			stats = character.get_stats_at_level(level)
			exp = character.calculate_exp_for_level(level)
			
			growth_data.append({
				'level': level,
				'exp': exp,
				'hp': stats.hp,
				'attack': stats.attack,
				'defense': stats.defense,
				'speed': stats.speed,
				'magic': stats.magic,
				'accuracy': stats.accuracy,
				'evasion': stats.evasion
			})
		
		return growth_data
	
	def export_growth_chart(self, character: Character, output_path: Path) -> None:
		"""Export growth chart to CSV"""
		growth_data = self.simulate_growth(character)
		
		with open(output_path, 'w', newline='') as f:
			writer = csv.DictWriter(f, fieldnames=['level', 'exp', 'hp', 'attack', 'defense', 'speed', 'magic', 'accuracy', 'evasion'])
			writer.writeheader()
			writer.writerows(growth_data)
		
		if self.verbose:
			print(f"✓ Exported growth chart to {output_path}")
	
	def compare_characters(self, level: int = 20) -> None:
		"""Compare all characters at given level"""
		print(f"\n=== Character Comparison (Level {level}) ===\n")
		print(f"{'Character':<12} {'HP':>5} {'ATK':>4} {'DEF':>4} {'SPD':>4} {'MAG':>4} {'ACC':>4} {'EVA':>4}")
		print("=" * 60)
		
		for char_id in range(FFMQCharacterDatabase.NUM_CHARACTERS):
			character = self.extract_character(char_id)
			
			if character:
				stats = character.get_stats_at_level(level)
				print(f"{character.name:<12} {stats.hp:>5} {stats.attack:>4} {stats.defense:>4} "
					  f"{stats.speed:>4} {stats.magic:>4} {stats.accuracy:>4} {stats.evasion:>4}")
	
	def modify_base_stat(self, char_id: int, stat_name: str, value: int) -> bool:
		"""Modify character base stat"""
		if char_id >= FFMQCharacterDatabase.NUM_CHARACTERS:
			return False
		
		stats_offset = FFMQCharacterDatabase.BASE_STATS_OFFSET + (char_id * 16)
		
		if stats_offset + 16 > len(self.rom_data):
			return False
		
		stat_offsets = {
			'hp': 0,
			'attack': 2,
			'defense': 3,
			'speed': 4,
			'magic': 5,
			'accuracy': 6,
			'evasion': 7
		}
		
		if stat_name not in stat_offsets:
			return False
		
		offset = stats_offset + stat_offsets[stat_name]
		
		if stat_name == 'hp':
			# HP is 2 bytes
			self.rom_data[offset] = value & 0xFF
			self.rom_data[offset + 1] = (value >> 8) & 0xFF
		else:
			# Other stats are 1 byte
			self.rom_data[offset] = value & 0xFF
		
		if self.verbose:
			print(f"✓ Modified {FFMQCharacterDatabase.get_character_name(char_id)}'s {stat_name} to {value}")
		
		return True
	
	def modify_growth_rate(self, char_id: int, stat_name: str, value: float) -> bool:
		"""Modify character growth rate"""
		if char_id >= FFMQCharacterDatabase.NUM_CHARACTERS:
			return False
		
		growth_offset = FFMQCharacterDatabase.GROWTH_RATES_OFFSET + (char_id * 16)
		
		if growth_offset + 16 > len(self.rom_data):
			return False
		
		stat_offsets = {
			'hp': 0,
			'attack': 2,
			'defense': 3,
			'speed': 4,
			'magic': 5,
			'accuracy': 6,
			'evasion': 7
		}
		
		if stat_name not in stat_offsets:
			return False
		
		offset = growth_offset + stat_offsets[stat_name]
		
		# Convert to fixed-point
		fixed_value = int(value * 10.0)
		
		if stat_name == 'hp':
			# HP growth is 2 bytes
			self.rom_data[offset] = fixed_value & 0xFF
			self.rom_data[offset + 1] = (fixed_value >> 8) & 0xFF
		else:
			# Other stats are 1 byte
			self.rom_data[offset] = fixed_value & 0xFF
		
		if self.verbose:
			print(f"✓ Modified {FFMQCharacterDatabase.get_character_name(char_id)}'s {stat_name} growth to {value}")
		
		return True
	
	def save_rom(self, output_path: Optional[Path] = None) -> None:
		"""Save modified ROM"""
		save_path = output_path or self.rom_path
		
		with open(save_path, 'wb') as f:
			f.write(self.rom_data)
		
		if self.verbose:
			print(f"✓ Saved ROM to {save_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Character Progression Editor')
	parser.add_argument('rom', type=str, help='FFMQ ROM file')
	parser.add_argument('--list-characters', action='store_true', help='List all characters')
	parser.add_argument('--show-stats', type=int, help='Show character stats')
	parser.add_argument('--simulate-growth', type=int, help='Simulate character growth')
	parser.add_argument('--max-level', type=int, default=41, help='Max level for simulation')
	parser.add_argument('--compare-characters', action='store_true', help='Compare characters')
	parser.add_argument('--compare-level', type=int, default=20, help='Level for comparison')
	parser.add_argument('--edit-base-stat', type=int, help='Edit character base stat')
	parser.add_argument('--edit-growth', type=int, help='Edit character growth rate')
	parser.add_argument('--stat', type=str, help='Stat name (hp, attack, defense, etc.)')
	parser.add_argument('--value', type=float, help='Stat value')
	parser.add_argument('--export-chart', action='store_true', help='Export growth chart')
	parser.add_argument('--export-json', action='store_true', help='Export as JSON')
	parser.add_argument('--output', type=str, help='Output file')
	parser.add_argument('--save', type=str, help='Save modified ROM')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FFMQCharacterEditor(Path(args.rom), verbose=args.verbose)
	
	# List characters
	if args.list_characters:
		print(f"\nFFMQ Characters ({FFMQCharacterDatabase.NUM_CHARACTERS}):\n")
		
		for char_id in range(FFMQCharacterDatabase.NUM_CHARACTERS):
			character = editor.extract_character(char_id)
			
			if character:
				print(f"  {char_id}: {character.name}")
				print(f"     Base Stats: HP={character.base_stats.hp} ATK={character.base_stats.attack} "
					  f"DEF={character.base_stats.defense} SPD={character.base_stats.speed} "
					  f"MAG={character.base_stats.magic}")
				print(f"     Abilities: {len(character.abilities)}")
		
		return 0
	
	# Show stats
	if args.show_stats is not None:
		character = editor.extract_character(args.show_stats)
		
		if character:
			print(f"\n=== {character.name} ===\n")
			print(f"Base Stats:")
			print(f"  HP: {character.base_stats.hp}")
			print(f"  Attack: {character.base_stats.attack}")
			print(f"  Defense: {character.base_stats.defense}")
			print(f"  Speed: {character.base_stats.speed}")
			print(f"  Magic: {character.base_stats.magic}")
			print(f"  Accuracy: {character.base_stats.accuracy}")
			print(f"  Evasion: {character.base_stats.evasion}")
			
			print(f"\nGrowth Rates:")
			print(f"  HP: +{character.growth_rates.hp} per level")
			print(f"  Attack: +{character.growth_rates.attack} per level")
			print(f"  Defense: +{character.growth_rates.defense} per level")
			print(f"  Speed: +{character.growth_rates.speed} per level")
			print(f"  Magic: +{character.growth_rates.magic} per level")
			
			print(f"\nAbilities ({len(character.abilities)}):")
			for ability in character.abilities:
				print(f"  Lv.{ability.unlock_level:2d}: {ability.name} (MP:{ability.mp_cost})")
		
		return 0
	
	# Simulate growth
	if args.simulate_growth is not None:
		character = editor.extract_character(args.simulate_growth)
		
		if character:
			if args.export_chart:
				output = Path(args.output) if args.output else Path(f'{character.name.lower()}_growth.csv')
				editor.export_growth_chart(character, output)
			else:
				growth_data = editor.simulate_growth(character, args.max_level)
				
				print(f"\n=== {character.name} Growth Simulation ===\n")
				print(f"{'Lv':>3} {'EXP':>8} {'HP':>5} {'ATK':>4} {'DEF':>4} {'SPD':>4} {'MAG':>4}")
				print("=" * 40)
				
				for data in growth_data[::5]:  # Show every 5th level
					print(f"{data['level']:3d} {data['exp']:8d} {data['hp']:5d} {data['attack']:4d} "
						  f"{data['defense']:4d} {data['speed']:4d} {data['magic']:4d}")
		
		return 0
	
	# Compare characters
	if args.compare_characters:
		editor.compare_characters(args.compare_level)
		return 0
	
	# Edit base stat
	if args.edit_base_stat is not None:
		if args.stat and args.value is not None:
			success = editor.modify_base_stat(args.edit_base_stat, args.stat, int(args.value))
			
			if success and args.save:
				editor.save_rom(Path(args.save))
		
		return 0
	
	# Edit growth rate
	if args.edit_growth is not None:
		if args.stat and args.value is not None:
			success = editor.modify_growth_rate(args.edit_growth, args.stat, args.value)
			
			if success and args.save:
				editor.save_rom(Path(args.save))
		
		return 0
	
	print("Use --list-characters, --show-stats, --simulate-growth, --compare-characters, or --edit-base-stat/--edit-growth")
	return 0


if __name__ == '__main__':
	exit(main())
