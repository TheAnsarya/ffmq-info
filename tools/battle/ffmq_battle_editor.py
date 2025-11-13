#!/usr/bin/env python3
"""
FFMQ Battle System Editor - Battle mechanics and formula editor

Battle Features:
- Damage formulas
- Element system
- Status effects
- Turn order
- AI patterns
- Reward calculation

Battle Elements:
- Physical damage
- Magic damage
- Critical hits
- Elemental modifiers
- Status application
- Counter attacks

Features:
- Formula editing
- Balance testing
- AI script editor
- Reward calculator
- Export/import
- Simulation mode

Usage:
	python ffmq_battle_editor.py --extract rom.smc battle.json
	python ffmq_battle_editor.py --insert battle.json rom.smc
	python ffmq_battle_editor.py --formula damage
	python ffmq_battle_editor.py --test-damage 100 50 0
	python ffmq_battle_editor.py --simulate 5 15
"""

import argparse
import json
from pathlib import Path
from typing import List, Dict, Optional, Tuple, Any
from dataclasses import dataclass, asdict, field
from enum import Enum
import random


class Element(Enum):
	"""Elements"""
	NONE = 0
	FIRE = 1
	WATER = 2
	EARTH = 3
	WIND = 4


class StatusEffect(Enum):
	"""Status effects"""
	POISON = "poison"
	PARALYSIS = "paralysis"
	CONFUSION = "confusion"
	SLEEP = "sleep"
	DARKNESS = "darkness"
	SILENCE = "silence"


@dataclass
class DamageFormula:
	"""Damage calculation formula"""
	base_multiplier: float = 1.0
	attack_factor: float = 1.0
	defense_factor: float = 0.5
	variance: float = 0.1
	crit_multiplier: float = 2.0
	crit_rate: float = 0.05


@dataclass
class ElementalModifier:
	"""Elemental damage modifier"""
	attacker_element: Element
	defender_element: Element
	multiplier: float = 1.0


@dataclass
class StatusApplication:
	"""Status effect application"""
	status: StatusEffect
	base_chance: float = 0.25
	duration_min: int = 3
	duration_max: int = 5


@dataclass
class AIPattern:
	"""AI behavior pattern"""
	pattern_id: int
	name: str
	hp_threshold: float = 1.0
	actions: List[Dict[str, Any]] = field(default_factory=list)
	priority: int = 0


@dataclass
class BattleReward:
	"""Battle rewards"""
	exp_base: int
	gil_base: int
	exp_multiplier: float = 1.0
	gil_multiplier: float = 1.0
	item_drop_rate: float = 0.1
	item_drop_id: int = 0


@dataclass
class BattleSystem:
	"""Battle system data"""
	damage_formula: DamageFormula = field(default_factory=DamageFormula)
	elemental_modifiers: List[ElementalModifier] = field(default_factory=list)
	status_effects: List[StatusApplication] = field(default_factory=list)
	ai_patterns: List[AIPattern] = field(default_factory=list)
	rewards: List[BattleReward] = field(default_factory=list)
	rom_offset: int = 0x180000


class BattleEditor:
	"""Battle system editor"""
	
	# ROM offsets (example)
	DAMAGE_FORMULA_OFFSET = 0x180000
	ELEMENT_TABLE_OFFSET = 0x180100
	AI_PATTERN_OFFSET = 0x180200
	REWARD_TABLE_OFFSET = 0x180400
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.rom_data: Optional[bytearray] = None
		self.battle_system = BattleSystem()
	
	def load_rom(self, rom_path: Path) -> bool:
		"""Load ROM file"""
		try:
			with open(rom_path, 'rb') as f:
				self.rom_data = bytearray(f.read())
			
			if self.verbose:
				print(f"✓ Loaded ROM: {rom_path} ({len(self.rom_data):,} bytes)")
			
			return True
		
		except Exception as e:
			print(f"Error loading ROM: {e}")
			return False
	
	def save_rom(self, output_path: Path) -> bool:
		"""Save ROM file"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return False
		
		try:
			with open(output_path, 'wb') as f:
				f.write(self.rom_data)
			
			if self.verbose:
				print(f"✓ Saved ROM: {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error saving ROM: {e}")
			return False
	
	def extract_battle_system(self) -> BattleSystem:
		"""Extract battle system from ROM"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return self.battle_system
		
		# Extract damage formula
		offset = self.DAMAGE_FORMULA_OFFSET
		
		if offset + 16 <= len(self.rom_data):
			self.battle_system.damage_formula = DamageFormula(
				base_multiplier=self.rom_data[offset] / 100.0,
				attack_factor=self.rom_data[offset + 1] / 100.0,
				defense_factor=self.rom_data[offset + 2] / 100.0,
				variance=self.rom_data[offset + 3] / 100.0,
				crit_multiplier=self.rom_data[offset + 4] / 100.0,
				crit_rate=self.rom_data[offset + 5] / 100.0
			)
		
		# Extract elemental modifiers
		offset = self.ELEMENT_TABLE_OFFSET
		
		for i in range(25):  # 5x5 element table
			if offset + 1 > len(self.rom_data):
				break
			
			attacker_elem = Element(i // 5)
			defender_elem = Element(i % 5)
			multiplier = self.rom_data[offset] / 100.0
			
			modifier = ElementalModifier(
				attacker_element=attacker_elem,
				defender_element=defender_elem,
				multiplier=multiplier
			)
			
			self.battle_system.elemental_modifiers.append(modifier)
			offset += 1
		
		if self.verbose:
			print("✓ Extracted battle system")
		
		return self.battle_system
	
	def insert_battle_system(self) -> bool:
		"""Insert battle system into ROM"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return False
		
		# Write damage formula
		offset = self.DAMAGE_FORMULA_OFFSET
		formula = self.battle_system.damage_formula
		
		if offset + 16 <= len(self.rom_data):
			self.rom_data[offset] = int(formula.base_multiplier * 100)
			self.rom_data[offset + 1] = int(formula.attack_factor * 100)
			self.rom_data[offset + 2] = int(formula.defense_factor * 100)
			self.rom_data[offset + 3] = int(formula.variance * 100)
			self.rom_data[offset + 4] = int(formula.crit_multiplier * 100)
			self.rom_data[offset + 5] = int(formula.crit_rate * 100)
		
		# Write elemental modifiers
		offset = self.ELEMENT_TABLE_OFFSET
		
		for modifier in self.battle_system.elemental_modifiers:
			if offset >= len(self.rom_data):
				break
			
			self.rom_data[offset] = int(modifier.multiplier * 100)
			offset += 1
		
		if self.verbose:
			print("✓ Inserted battle system")
		
		return True
	
	def calculate_damage(self, attack: int, defense: int, level: int, 
						element_mult: float = 1.0) -> int:
		"""Calculate damage using formula"""
		formula = self.battle_system.damage_formula
		
		# Base damage
		damage = formula.base_multiplier * (
			(attack * formula.attack_factor) - (defense * formula.defense_factor)
		)
		
		# Level factor
		damage *= (1.0 + level / 100.0)
		
		# Elemental modifier
		damage *= element_mult
		
		# Variance
		variance = random.uniform(1.0 - formula.variance, 1.0 + formula.variance)
		damage *= variance
		
		# Critical hit
		if random.random() < formula.crit_rate:
			damage *= formula.crit_multiplier
			if self.verbose:
				print("  Critical hit!")
		
		return max(1, int(damage))
	
	def get_elemental_multiplier(self, attacker: Element, defender: Element) -> float:
		"""Get elemental damage multiplier"""
		for modifier in self.battle_system.elemental_modifiers:
			if (modifier.attacker_element == attacker and 
				modifier.defender_element == defender):
				return modifier.multiplier
		
		return 1.0
	
	def simulate_battle(self, attacker_id: int, defender_id: int, 
					   rounds: int = 10) -> Dict[str, Any]:
		"""Simulate battle rounds"""
		results: Dict[str, Any] = {
			'total_damage': 0,
			'average_damage': 0.0,
			'min_damage': 999999,
			'max_damage': 0,
			'crits': 0,
			'rounds': rounds
		}
		
		# Example stats
		attack = 50 + (attacker_id * 5)
		defense = 30 + (defender_id * 3)
		level = 10
		
		damages = []
		
		for i in range(rounds):
			damage = self.calculate_damage(attack, defense, level)
			damages.append(damage)
			
			results['total_damage'] += damage
			results['min_damage'] = min(results['min_damage'], damage)
			results['max_damage'] = max(results['max_damage'], damage)
		
		results['average_damage'] = results['total_damage'] / rounds if rounds > 0 else 0
		
		return results
	
	def export_json(self, output_path: Path) -> bool:
		"""Export battle system to JSON"""
		try:
			data = {
				'damage_formula': asdict(self.battle_system.damage_formula),
				'elemental_modifiers': [
					{
						'attacker_element': m.attacker_element.name,
						'defender_element': m.defender_element.name,
						'multiplier': m.multiplier
					}
					for m in self.battle_system.elemental_modifiers
				],
				'status_effects': [
					{
						'status': s.status.value,
						'base_chance': s.base_chance,
						'duration_min': s.duration_min,
						'duration_max': s.duration_max
					}
					for s in self.battle_system.status_effects
				],
				'rom_offset': self.battle_system.rom_offset
			}
			
			with open(output_path, 'w', encoding='utf-8') as f:
				json.dump(data, f, indent='\t')
			
			if self.verbose:
				print(f"✓ Exported battle system to {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting battle system: {e}")
			return False
	
	def import_json(self, input_path: Path) -> bool:
		"""Import battle system from JSON"""
		try:
			with open(input_path, 'r', encoding='utf-8') as f:
				data = json.load(f)
			
			# Import damage formula
			formula_data = data['damage_formula']
			self.battle_system.damage_formula = DamageFormula(**formula_data)
			
			# Import elemental modifiers
			self.battle_system.elemental_modifiers = []
			for m_data in data.get('elemental_modifiers', []):
				modifier = ElementalModifier(
					attacker_element=Element[m_data['attacker_element']],
					defender_element=Element[m_data['defender_element']],
					multiplier=m_data['multiplier']
				)
				self.battle_system.elemental_modifiers.append(modifier)
			
			if self.verbose:
				print("✓ Imported battle system")
			
			return True
		
		except Exception as e:
			print(f"Error importing battle system: {e}")
			return False
	
	def print_formula(self) -> None:
		"""Print damage formula"""
		formula = self.battle_system.damage_formula
		
		print("\n=== Damage Formula ===\n")
		print(f"Base Multiplier: {formula.base_multiplier:.2f}")
		print(f"Attack Factor: {formula.attack_factor:.2f}")
		print(f"Defense Factor: {formula.defense_factor:.2f}")
		print(f"Variance: ±{formula.variance * 100:.0f}%")
		print(f"Critical Multiplier: {formula.crit_multiplier:.2f}x")
		print(f"Critical Rate: {formula.crit_rate * 100:.1f}%")
		print()
		print("Formula: damage = base * ((attack * atk_factor) - (defense * def_factor)) * (1 + level/100) * element_mult * variance")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Battle System Editor')
	parser.add_argument('--extract', nargs=2, metavar=('ROM', 'OUTPUT'),
					   help='Extract battle system from ROM')
	parser.add_argument('--insert', nargs=2, metavar=('BATTLE', 'ROM'),
					   help='Insert battle system into ROM')
	parser.add_argument('--formula', action='store_true',
					   help='Show damage formula')
	parser.add_argument('--test-damage', nargs=3, type=int,
					   metavar=('ATTACK', 'DEFENSE', 'LEVEL'),
					   help='Test damage calculation')
	parser.add_argument('--simulate', nargs=2, type=int,
					   metavar=('ATTACKER_ID', 'DEFENDER_ID'),
					   help='Simulate battle')
	parser.add_argument('--rounds', type=int, default=10,
					   help='Simulation rounds')
	parser.add_argument('--file', type=str, metavar='FILE',
					   help='Battle system JSON file')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = BattleEditor(verbose=args.verbose)
	
	# Extract
	if args.extract:
		rom_path, output_path = args.extract
		editor.load_rom(Path(rom_path))
		editor.extract_battle_system()
		editor.export_json(Path(output_path))
		return 0
	
	# Load file
	if args.file:
		editor.import_json(Path(args.file))
	
	# Insert
	if args.insert:
		battle_path, rom_path = args.insert
		editor.import_json(Path(battle_path))
		editor.load_rom(Path(rom_path))
		editor.insert_battle_system()
		editor.save_rom(Path(rom_path))
		return 0
	
	# Show formula
	if args.formula:
		editor.print_formula()
		return 0
	
	# Test damage
	if args.test_damage:
		attack, defense, level = args.test_damage
		
		print(f"\nDamage Test:")
		print(f"  Attack: {attack}")
		print(f"  Defense: {defense}")
		print(f"  Level: {level}")
		print()
		
		for i in range(5):
			damage = editor.calculate_damage(attack, defense, level)
			print(f"  Round {i+1}: {damage} damage")
		
		return 0
	
	# Simulate
	if args.simulate:
		attacker_id, defender_id = args.simulate
		
		results = editor.simulate_battle(attacker_id, defender_id, args.rounds)
		
		print(f"\n=== Battle Simulation ===\n")
		print(f"Attacker ID: {attacker_id}")
		print(f"Defender ID: {defender_id}")
		print(f"Rounds: {results['rounds']}")
		print()
		print(f"Total Damage: {results['total_damage']:,}")
		print(f"Average Damage: {results['average_damage']:.1f}")
		print(f"Min Damage: {results['min_damage']}")
		print(f"Max Damage: {results['max_damage']}")
		
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
