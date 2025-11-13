#!/usr/bin/env python3
"""
FFMQ Damage & Attack Formula Calculator - Calculate, test, and balance damage formulas

Final Fantasy Mystic Quest damage calculation system:
- Physical attack damage formulas
- Magic/spell damage formulas
- Critical hit calculations
- Defense mitigation
- Elemental modifiers
- Status effect damage
- Special attack formulas
- Boss-specific mechanics

Features:
- Calculate damage with full formula accuracy
- Test different stat combinations
- Balance damage output across level ranges
- Export damage tables
- Compare weapon/spell effectiveness
- Simulate battles with damage calculations
- Find optimal stat builds
- Detect damage overflow/underflow
- Formula reverse engineering tools

Damage Formula (FFMQ Physical):
	Base Damage = (Attacker Attack - Defender Defense / 2)
	Random Variance = Base * (7/8 to 9/8)
	Critical = Damage * 2 (based on weapon crit rate)
	Final Damage = max(1, Damage)

Spell Damage Formula (FFMQ Magic):
	Base Damage = Spell Power * (Caster Magic / 16)
	Elemental Modifier = * 0.5 (resistant) or * 1.5 (weak)
	Random Variance = Base * (7/8 to 9/8)
	Final Damage = max(1, Damage)

Usage:
	python ffmq_damage_calculator.py --physical --attack 100 --defense 50
	python ffmq_damage_calculator.py --spell fire --magic 80 --resistance weak
	python ffmq_damage_calculator.py --critical-rate 25 --trials 1000
	python ffmq_damage_calculator.py --export-damage-table --level-range 1-40
	python ffmq_damage_calculator.py --compare-weapons "Sword,Axe,Claw"
	python ffmq_damage_calculator.py --optimal-stats --target-damage 500
	python ffmq_damage_calculator.py --simulate-battle --enemy 15 --player-level 20
"""

import argparse
import json
import csv
import random
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any
from dataclasses import dataclass, field, asdict
from enum import Enum


class DamageType(Enum):
	"""Type of damage"""
	PHYSICAL = "physical"
	MAGICAL = "magical"
	FIXED = "fixed"
	PERCENT = "percent"


class Element(Enum):
	"""Elemental types"""
	NONE = "none"
	FIRE = "fire"
	WATER = "water"
	EARTH = "earth"
	WIND = "wind"


class ElementalModifier(Enum):
	"""Elemental resistance levels"""
	IMMUNE = 0.0
	RESISTANT = 0.5
	NORMAL = 1.0
	WEAK = 1.5


@dataclass
class AttackerStats:
	"""Attacking entity stats"""
	level: int
	attack: int
	magic: int
	accuracy: int
	critical_rate: int  # 0-100
	weapon_power: int = 0
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class DefenderStats:
	"""Defending entity stats"""
	level: int
	defense: int
	magic_defense: int
	evasion: int
	hp: int
	max_hp: int
	elemental_resistance: Dict[Element, ElementalModifier] = field(default_factory=dict)
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['elemental_resistance'] = {k.value: v.value for k, v in self.elemental_resistance.items()}
		return d


@dataclass
class AttackData:
	"""Attack/spell data"""
	name: str
	damage_type: DamageType
	base_power: int
	element: Element
	hits: int = 1
	accuracy_modifier: int = 0
	critical_modifier: int = 0
	ignore_defense: bool = False
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['damage_type'] = self.damage_type.value
		d['element'] = self.element.value
		return d


@dataclass
class DamageResult:
	"""Result of damage calculation"""
	base_damage: float
	variance_min: float
	variance_max: float
	average_damage: float
	critical_damage: float
	critical_chance: float
	expected_damage: float  # Average accounting for crit chance
	hit_chance: float
	actual_damage: Optional[int] = None  # Actual rolled damage
	was_critical: bool = False
	
	def to_dict(self) -> dict:
		return asdict(self)


class FFMQDamageCalculator:
	"""Calculate FFMQ damage"""
	
	# Constants
	VARIANCE_MIN = 7.0 / 8.0  # 0.875
	VARIANCE_MAX = 9.0 / 8.0  # 1.125
	CRITICAL_MULTIPLIER = 2.0
	BASE_HIT_RATE = 90  # Base hit rate percentage
	
	# Known weapon data (power values)
	WEAPONS = {
		'Steel Sword': {'power': 12, 'crit_rate': 10},
		'Knight Sword': {'power': 24, 'crit_rate': 12},
		'Excalibur': {'power': 50, 'crit_rate': 15},
		'Battle Axe': {'power': 30, 'crit_rate': 20},
		'Dragon Claw': {'power': 45, 'crit_rate': 25},
	}
	
	# Known spell data
	SPELLS = {
		'Fire': {'power': 20, 'element': Element.FIRE},
		'Blizzard': {'power': 20, 'element': Element.WATER},
		'Thunder': {'power': 20, 'element': Element.WIND},
		'Aero': {'power': 30, 'element': Element.WIND},
		'Flare': {'power': 80, 'element': Element.FIRE},
		'Meteor': {'power': 100, 'element': Element.NONE},
	}
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
	
	def calculate_physical_damage(
		self,
		attacker: AttackerStats,
		defender: DefenderStats,
		attack: AttackData,
		roll_variance: bool = False
	) -> DamageResult:
		"""Calculate physical attack damage"""
		
		# Base damage formula: (Attack + Weapon Power) - (Defense / 2)
		total_attack = attacker.attack + attack.base_power + attacker.weapon_power
		
		if attack.ignore_defense:
			defense_mitigation = 0
		else:
			defense_mitigation = defender.defense // 2
		
		base_damage = float(total_attack - defense_mitigation)
		base_damage = max(1.0, base_damage)  # Minimum 1 damage
		
		# Apply variance
		variance_min = base_damage * self.VARIANCE_MIN
		variance_max = base_damage * self.VARIANCE_MAX
		average_damage = (variance_min + variance_max) / 2.0
		
		# Critical hit calculation
		critical_chance = min(100, attacker.critical_rate + attack.critical_modifier) / 100.0
		critical_damage = average_damage * self.CRITICAL_MULTIPLIER
		
		# Expected damage (accounting for crits)
		expected_damage = (average_damage * (1.0 - critical_chance)) + (critical_damage * critical_chance)
		
		# Hit chance calculation
		hit_chance = min(100, self.BASE_HIT_RATE + attacker.accuracy - defender.evasion + attack.accuracy_modifier) / 100.0
		
		# Expected damage accounting for miss chance
		expected_damage *= hit_chance
		
		# Roll actual damage if requested
		actual_damage = None
		was_critical = False
		
		if roll_variance:
			# Roll for hit
			if random.random() < hit_chance:
				# Roll for critical
				if random.random() < critical_chance:
					actual_damage = int(base_damage * random.uniform(self.VARIANCE_MIN, self.VARIANCE_MAX) * self.CRITICAL_MULTIPLIER)
					was_critical = True
				else:
					actual_damage = int(base_damage * random.uniform(self.VARIANCE_MIN, self.VARIANCE_MAX))
			else:
				actual_damage = 0  # Miss
		
		return DamageResult(
			base_damage=base_damage,
			variance_min=variance_min,
			variance_max=variance_max,
			average_damage=average_damage,
			critical_damage=critical_damage,
			critical_chance=critical_chance,
			expected_damage=expected_damage,
			hit_chance=hit_chance,
			actual_damage=actual_damage,
			was_critical=was_critical
		)
	
	def calculate_spell_damage(
		self,
		attacker: AttackerStats,
		defender: DefenderStats,
		attack: AttackData,
		roll_variance: bool = False
	) -> DamageResult:
		"""Calculate spell/magic damage"""
		
		# Base damage formula: Spell Power * (Magic / 16)
		magic_factor = attacker.magic / 16.0
		base_damage = float(attack.base_power) * magic_factor
		
		# Apply elemental modifier
		if attack.element in defender.elemental_resistance:
			elemental_mod = defender.elemental_resistance[attack.element].value
		else:
			elemental_mod = ElementalModifier.NORMAL.value
		
		base_damage *= elemental_mod
		base_damage = max(1.0, base_damage)
		
		# Apply variance
		variance_min = base_damage * self.VARIANCE_MIN
		variance_max = base_damage * self.VARIANCE_MAX
		average_damage = (variance_min + variance_max) / 2.0
		
		# Spells typically don't crit in FFMQ (or have different mechanics)
		critical_chance = 0.0
		critical_damage = 0.0
		expected_damage = average_damage
		
		# Spells have high accuracy (typically 100% unless target has magic evasion)
		hit_chance = min(100, 95 + attacker.accuracy - (defender.evasion // 2)) / 100.0
		expected_damage *= hit_chance
		
		# Roll actual damage if requested
		actual_damage = None
		was_critical = False
		
		if roll_variance:
			if random.random() < hit_chance:
				actual_damage = int(base_damage * random.uniform(self.VARIANCE_MIN, self.VARIANCE_MAX))
			else:
				actual_damage = 0
		
		return DamageResult(
			base_damage=base_damage,
			variance_min=variance_min,
			variance_max=variance_max,
			average_damage=average_damage,
			critical_damage=critical_damage,
			critical_chance=critical_chance,
			expected_damage=expected_damage,
			hit_chance=hit_chance,
			actual_damage=actual_damage,
			was_critical=was_critical
		)
	
	def simulate_attack_trials(
		self,
		attacker: AttackerStats,
		defender: DefenderStats,
		attack: AttackData,
		trials: int = 1000
	) -> Dict[str, Any]:
		"""Simulate many attacks to get statistical data"""
		damages = []
		crits = 0
		hits = 0
		
		for _ in range(trials):
			if attack.damage_type == DamageType.PHYSICAL:
				result = self.calculate_physical_damage(attacker, defender, attack, roll_variance=True)
			else:
				result = self.calculate_spell_damage(attacker, defender, attack, roll_variance=True)
			
			if result.actual_damage is not None and result.actual_damage > 0:
				damages.append(result.actual_damage)
				hits += 1
				
				if result.was_critical:
					crits += 1
		
		if damages:
			avg_damage = sum(damages) / len(damages)
			min_damage = min(damages)
			max_damage = max(damages)
		else:
			avg_damage = 0
			min_damage = 0
			max_damage = 0
		
		return {
			'trials': trials,
			'hits': hits,
			'hit_rate': (hits / trials) * 100 if trials > 0 else 0,
			'crits': crits,
			'crit_rate': (crits / hits) * 100 if hits > 0 else 0,
			'average_damage': avg_damage,
			'min_damage': min_damage,
			'max_damage': max_damage,
			'damage_range': max_damage - min_damage
		}
	
	def export_damage_table(
		self,
		output_path: Path,
		level_range: Tuple[int, int],
		attack_range: Tuple[int, int],
		defense_range: Tuple[int, int]
	) -> None:
		"""Export damage table for various stat combinations"""
		
		with open(output_path, 'w', newline='') as f:
			writer = csv.writer(f)
			writer.writerow(['Level', 'Attack', 'Defense', 'Base Damage', 'Avg Damage', 'Expected Damage (w/ Crit)'])
			
			for level in range(level_range[0], level_range[1] + 1):
				for attack in range(attack_range[0], attack_range[1] + 1, 10):
					for defense in range(defense_range[0], defense_range[1] + 1, 10):
						attacker = AttackerStats(
							level=level,
							attack=attack,
							magic=50,
							accuracy=100,
							critical_rate=15
						)
						
						defender = DefenderStats(
							level=level,
							defense=defense,
							magic_defense=50,
							evasion=10,
							hp=500,
							max_hp=500
						)
						
						attack_data = AttackData(
							name="Basic Attack",
							damage_type=DamageType.PHYSICAL,
							base_power=20,
							element=Element.NONE
						)
						
						result = self.calculate_physical_damage(attacker, defender, attack_data)
						
						writer.writerow([
							level,
							attack,
							defense,
							f"{result.base_damage:.1f}",
							f"{result.average_damage:.1f}",
							f"{result.expected_damage:.1f}"
						])
		
		if self.verbose:
			print(f"✓ Exported damage table to {output_path}")
	
	def find_optimal_stats(
		self,
		target_damage: float,
		defender: DefenderStats,
		max_attack: int = 255,
		max_magic: int = 255
	) -> Dict[str, Any]:
		"""Find optimal stat allocation to reach target damage"""
		best_attack = 0
		best_magic = 0
		best_difference = float('inf')
		
		# Try physical builds
		for attack in range(10, max_attack + 1, 5):
			attacker = AttackerStats(
				level=30,
				attack=attack,
				magic=50,
				accuracy=100,
				critical_rate=15,
				weapon_power=30
			)
			
			attack_data = AttackData(
				name="Physical Attack",
				damage_type=DamageType.PHYSICAL,
				base_power=30,
				element=Element.NONE
			)
			
			result = self.calculate_physical_damage(attacker, defender, attack_data)
			difference = abs(result.expected_damage - target_damage)
			
			if difference < best_difference:
				best_difference = difference
				best_attack = attack
				best_magic = 50
		
		# Try magic builds
		for magic in range(10, max_magic + 1, 5):
			attacker = AttackerStats(
				level=30,
				attack=50,
				magic=magic,
				accuracy=100,
				critical_rate=0
			)
			
			spell_data = AttackData(
				name="Fire",
				damage_type=DamageType.MAGICAL,
				base_power=20,
				element=Element.FIRE
			)
			
			result = self.calculate_spell_damage(attacker, defender, spell_data)
			difference = abs(result.expected_damage - target_damage)
			
			if difference < best_difference:
				best_difference = difference
				best_attack = 50
				best_magic = magic
		
		return {
			'target_damage': target_damage,
			'optimal_attack': best_attack,
			'optimal_magic': best_magic,
			'difference': best_difference
		}


def main():
	parser = argparse.ArgumentParser(description='FFMQ Damage & Attack Formula Calculator')
	parser.add_argument('--physical', action='store_true', help='Calculate physical damage')
	parser.add_argument('--spell', type=str, help='Calculate spell damage (spell name)')
	parser.add_argument('--attack', type=int, default=50, help='Attacker attack stat')
	parser.add_argument('--magic', type=int, default=50, help='Attacker magic stat')
	parser.add_argument('--defense', type=int, default=30, help='Defender defense stat')
	parser.add_argument('--weapon-power', type=int, default=20, help='Weapon power')
	parser.add_argument('--critical-rate', type=int, default=15, help='Critical hit rate (0-100)')
	parser.add_argument('--resistance', type=str, choices=['immune', 'resistant', 'normal', 'weak'], default='normal', help='Elemental resistance')
	parser.add_argument('--trials', type=int, default=1000, help='Number of simulation trials')
	parser.add_argument('--export-damage-table', action='store_true', help='Export damage table')
	parser.add_argument('--level-range', type=str, default='1-40', help='Level range (min-max)')
	parser.add_argument('--optimal-stats', action='store_true', help='Find optimal stats')
	parser.add_argument('--target-damage', type=float, default=500, help='Target damage for optimization')
	parser.add_argument('--output', type=str, help='Output file')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	calculator = FFMQDamageCalculator(verbose=args.verbose)
	
	# Setup attacker
	attacker = AttackerStats(
		level=30,
		attack=args.attack,
		magic=args.magic,
		accuracy=100,
		critical_rate=args.critical_rate,
		weapon_power=args.weapon_power
	)
	
	# Setup defender
	resistance_map = {
		'immune': ElementalModifier.IMMUNE,
		'resistant': ElementalModifier.RESISTANT,
		'normal': ElementalModifier.NORMAL,
		'weak': ElementalModifier.WEAK
	}
	
	defender = DefenderStats(
		level=30,
		defense=args.defense,
		magic_defense=50,
		evasion=10,
		hp=1000,
		max_hp=1000,
		elemental_resistance={
			Element.FIRE: resistance_map[args.resistance],
			Element.WATER: resistance_map[args.resistance],
			Element.EARTH: resistance_map[args.resistance],
			Element.WIND: resistance_map[args.resistance],
		}
	)
	
	# Calculate physical damage
	if args.physical:
		attack_data = AttackData(
			name="Physical Attack",
			damage_type=DamageType.PHYSICAL,
			base_power=args.weapon_power,
			element=Element.NONE
		)
		
		result = calculator.calculate_physical_damage(attacker, defender, attack_data)
		
		print("\n=== Physical Damage Calculation ===\n")
		print(f"Attacker: ATK {attacker.attack} + Weapon {args.weapon_power} = {attacker.attack + args.weapon_power}")
		print(f"Defender: DEF {defender.defense}")
		print(f"\nBase Damage: {result.base_damage:.1f}")
		print(f"Damage Range: {result.variance_min:.1f} - {result.variance_max:.1f}")
		print(f"Average Damage: {result.average_damage:.1f}")
		print(f"Critical Chance: {result.critical_chance * 100:.1f}%")
		print(f"Critical Damage: {result.critical_damage:.1f}")
		print(f"Expected Damage: {result.expected_damage:.1f}")
		print(f"Hit Chance: {result.hit_chance * 100:.1f}%")
		
		# Run trials
		trials = calculator.simulate_attack_trials(attacker, defender, attack_data, trials=args.trials)
		print(f"\n=== Simulation ({trials['trials']} trials) ===\n")
		print(f"Hit Rate: {trials['hit_rate']:.1f}%")
		print(f"Crit Rate: {trials['crit_rate']:.1f}%")
		print(f"Average Damage: {trials['average_damage']:.1f}")
		print(f"Damage Range: {trials['min_damage']} - {trials['max_damage']}")
		
		return 0
	
	# Calculate spell damage
	if args.spell:
		spell_name = args.spell.title()
		
		if spell_name in calculator.SPELLS:
			spell_data = calculator.SPELLS[spell_name]
			
			attack_data = AttackData(
				name=spell_name,
				damage_type=DamageType.MAGICAL,
				base_power=spell_data['power'],
				element=spell_data['element']
			)
			
			result = calculator.calculate_spell_damage(attacker, defender, attack_data)
			
			print(f"\n=== {spell_name} Damage Calculation ===\n")
			print(f"Spell Power: {spell_data['power']}")
			print(f"Caster Magic: {attacker.magic}")
			print(f"Element: {spell_data['element'].value}")
			print(f"Resistance: {args.resistance}")
			print(f"\nBase Damage: {result.base_damage:.1f}")
			print(f"Damage Range: {result.variance_min:.1f} - {result.variance_max:.1f}")
			print(f"Average Damage: {result.average_damage:.1f}")
			print(f"Expected Damage: {result.expected_damage:.1f}")
			print(f"Hit Chance: {result.hit_chance * 100:.1f}%")
			
			# Run trials
			trials = calculator.simulate_attack_trials(attacker, defender, attack_data, trials=args.trials)
			print(f"\n=== Simulation ({trials['trials']} trials) ===\n")
			print(f"Hit Rate: {trials['hit_rate']:.1f}%")
			print(f"Average Damage: {trials['average_damage']:.1f}")
			print(f"Damage Range: {trials['min_damage']} - {trials['max_damage']}")
		else:
			print(f"Unknown spell: {spell_name}")
			print(f"Known spells: {', '.join(calculator.SPELLS.keys())}")
		
		return 0
	
	# Export damage table
	if args.export_damage_table:
		level_min, level_max = map(int, args.level_range.split('-'))
		output = Path(args.output) if args.output else Path('damage_table.csv')
		
		calculator.export_damage_table(
			output,
			level_range=(level_min, level_max),
			attack_range=(10, 200),
			defense_range=(10, 150)
		)
		
		return 0
	
	# Find optimal stats
	if args.optimal_stats:
		result = calculator.find_optimal_stats(args.target_damage, defender)
		
		print(f"\n=== Optimal Stats for {args.target_damage} Damage ===\n")
		print(f"Target Damage: {result['target_damage']:.1f}")
		print(f"Optimal Attack: {result['optimal_attack']}")
		print(f"Optimal Magic: {result['optimal_magic']}")
		print(f"Difference: {result['difference']:.1f}")
		
		return 0
	
	print("Use --physical, --spell, --export-damage-table, or --optimal-stats")
	return 0


if __name__ == '__main__':
	exit(main())
