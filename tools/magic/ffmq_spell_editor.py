#!/usr/bin/env python3
"""
FFMQ Spell/Magic Database Editor - Edit spell data and magic system

Final Fantasy Mystic Quest magic system:
- White Magic (healing/support)
- Black Magic (offensive)
- Wizard Magic (powerful spells)
- Magic power scaling
- MP costs
- Target selection
- Elemental properties
- Status effects
- Animation IDs

Features:
- View spell database
- Edit spell power/MP cost
- Modify spell effects
- Change spell targeting
- Set elemental types
- Configure animations
- Balance spell costs
- Export spell lists
- Import custom spells
- Calculate DPS/healing efficiency

Spell Categories:
- Cure spells (Cure, Life, Heal, etc.)
- Attack spells (Fire, Blizzard, Thunder, Aero)
- Status spells (Sleep, Poison, etc.)
- Support spells (Shield, Refresh, etc.)

Usage:
	python ffmq_spell_editor.py rom.sfc --list-spells
	python ffmq_spell_editor.py rom.sfc --show-spell Cure
	python ffmq_spell_editor.py rom.sfc --edit-spell Fire --power 50 --mp 8
	python ffmq_spell_editor.py rom.sfc --balance-costs
	python ffmq_spell_editor.py rom.sfc --export spells.json
	python ffmq_spell_editor.py rom.sfc --calculate-efficiency
"""

import argparse
import json
import struct
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any
from dataclasses import dataclass, field, asdict
from enum import Enum


class SpellType(Enum):
	"""Spell categories"""
	WHITE = "white"
	BLACK = "black"
	WIZARD = "wizard"
	SUPPORT = "support"


class TargetType(Enum):
	"""Spell target types"""
	SINGLE_ENEMY = "single_enemy"
	ALL_ENEMIES = "all_enemies"
	SINGLE_ALLY = "single_ally"
	ALL_ALLIES = "all_allies"
	SELF = "self"
	RANDOM_ENEMY = "random_enemy"


class Element(Enum):
	"""Elemental types"""
	NONE = "none"
	FIRE = "fire"
	WATER = "water"
	EARTH = "earth"
	WIND = "wind"


@dataclass
class StatusEffect:
	"""Status effect application"""
	effect_id: int
	effect_name: str
	chance: int  # Percentage
	duration: int  # Turns
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class Spell:
	"""Magic spell"""
	spell_id: int
	name: str
	spell_type: SpellType
	power: int
	mp_cost: int
	target: TargetType
	element: Element
	accuracy: int
	animation_id: int
	status_effects: List[StatusEffect]
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['spell_type'] = self.spell_type.value
		d['target'] = self.target.value
		d['element'] = self.element.value
		d['status_effects'] = [s.to_dict() for s in self.status_effects]
		return d


class FFMQSpellDatabase:
	"""Database of FFMQ spells"""
	
	# Spell data location
	SPELL_DATA_OFFSET = 0x2C0000
	NUM_SPELLS = 64
	SPELL_SIZE = 16
	
	# Known spells with IDs
	SPELLS = {
		# White Magic - Healing
		0: "Cure",
		1: "Life",
		2: "Heal",
		3: "Refresh",
		
		# White Magic - Support
		4: "Barrier",
		5: "Shell",
		6: "Raise",
		7: "Jumbo Cure",
		
		# Black Magic - Fire
		8: "Fire",
		9: "Fira",
		10: "Firaga",
		11: "Flare",
		
		# Black Magic - Ice
		12: "Blizzard",
		13: "Blizzara",
		14: "Blizzaga",
		
		# Black Magic - Thunder
		16: "Thunder",
		17: "Thundara",
		18: "Thundaga",
		
		# Black Magic - Wind
		20: "Aero",
		21: "Aerora",
		22: "Aeroga",
		
		# Wizard Magic
		24: "Meteor",
		25: "Quake",
		26: "Tornado",
		27: "Ultima",
		
		# Status Magic
		32: "Sleep",
		33: "Poison",
		34: "Confusion",
		35: "Silence",
		36: "Darkness",
		37: "Slow",
		38: "Stone",
		39: "Death",
	}
	
	# Status effects
	STATUS_EFFECTS = {
		0: "None",
		1: "Poison",
		2: "Darkness",
		3: "Confusion",
		4: "Silence",
		5: "Sleep",
		6: "Paralyze",
		7: "Stone",
		8: "Death",
	}
	
	@classmethod
	def get_spell_name(cls, spell_id: int) -> str:
		"""Get spell name by ID"""
		return cls.SPELLS.get(spell_id, f"Spell {spell_id}")
	
	@classmethod
	def get_status_name(cls, status_id: int) -> str:
		"""Get status effect name"""
		return cls.STATUS_EFFECTS.get(status_id, f"Status {status_id}")


class FFMQSpellEditor:
	"""Edit FFMQ spell database"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		if self.verbose:
			print(f"Loaded FFMQ ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def extract_spell(self, spell_id: int) -> Optional[Spell]:
		"""Extract spell data from ROM"""
		if spell_id >= FFMQSpellDatabase.NUM_SPELLS:
			return None
		
		offset = FFMQSpellDatabase.SPELL_DATA_OFFSET + (spell_id * FFMQSpellDatabase.SPELL_SIZE)
		
		if offset + FFMQSpellDatabase.SPELL_SIZE > len(self.rom_data):
			return None
		
		# Read spell data
		spell_type_id = self.rom_data[offset]
		power = self.rom_data[offset + 1]
		mp_cost = self.rom_data[offset + 2]
		target_id = self.rom_data[offset + 3]
		element_id = self.rom_data[offset + 4]
		accuracy = self.rom_data[offset + 5]
		animation_id = self.rom_data[offset + 6]
		
		# Decode spell type
		spell_types = list(SpellType)
		spell_type = spell_types[spell_type_id % len(spell_types)]
		
		# Decode target
		targets = list(TargetType)
		target = targets[target_id % len(targets)]
		
		# Decode element
		elements = list(Element)
		element = elements[element_id % len(elements)]
		
		# Read status effects (up to 4)
		status_effects = []
		for i in range(4):
			status_offset = offset + 8 + (i * 2)
			
			if status_offset + 2 > len(self.rom_data):
				break
			
			effect_id = self.rom_data[status_offset]
			chance = self.rom_data[status_offset + 1]
			
			if effect_id == 0 or effect_id == 0xFF:
				continue
			
			status_effects.append(StatusEffect(
				effect_id=effect_id,
				effect_name=FFMQSpellDatabase.get_status_name(effect_id),
				chance=chance,
				duration=3  # Default duration
			))
		
		spell = Spell(
			spell_id=spell_id,
			name=FFMQSpellDatabase.get_spell_name(spell_id),
			spell_type=spell_type,
			power=power,
			mp_cost=mp_cost,
			target=target,
			element=element,
			accuracy=accuracy,
			animation_id=animation_id,
			status_effects=status_effects
		)
		
		return spell
	
	def list_spells(self, spell_type: Optional[SpellType] = None) -> List[Spell]:
		"""List all spells, optionally filtered by type"""
		spells = []
		
		for i in range(FFMQSpellDatabase.NUM_SPELLS):
			spell = self.extract_spell(i)
			
			if not spell:
				continue
			
			if spell_type and spell.spell_type != spell_type:
				continue
			
			spells.append(spell)
		
		return spells
	
	def modify_spell(self, spell_id: int, power: Optional[int] = None,
					 mp_cost: Optional[int] = None, accuracy: Optional[int] = None) -> bool:
		"""Modify spell parameters"""
		if spell_id >= FFMQSpellDatabase.NUM_SPELLS:
			return False
		
		offset = FFMQSpellDatabase.SPELL_DATA_OFFSET + (spell_id * FFMQSpellDatabase.SPELL_SIZE)
		
		if offset + FFMQSpellDatabase.SPELL_SIZE > len(self.rom_data):
			return False
		
		spell_name = FFMQSpellDatabase.get_spell_name(spell_id)
		
		if power is not None:
			self.rom_data[offset + 1] = min(power, 255)
			if self.verbose:
				print(f"✓ Set {spell_name} power to {power}")
		
		if mp_cost is not None:
			self.rom_data[offset + 2] = min(mp_cost, 255)
			if self.verbose:
				print(f"✓ Set {spell_name} MP cost to {mp_cost}")
		
		if accuracy is not None:
			self.rom_data[offset + 5] = min(accuracy, 100)
			if self.verbose:
				print(f"✓ Set {spell_name} accuracy to {accuracy}%")
		
		return True
	
	def balance_mp_costs(self) -> int:
		"""Auto-balance MP costs based on power"""
		count = 0
		
		for spell_id in range(FFMQSpellDatabase.NUM_SPELLS):
			spell = self.extract_spell(spell_id)
			
			if not spell or spell.power == 0:
				continue
			
			# Calculate balanced MP cost: power / 5, minimum 1
			balanced_mp = max(1, spell.power // 5)
			
			# Apply healing modifier (healing spells cost less)
			if spell.spell_type == SpellType.WHITE:
				balanced_mp = max(1, balanced_mp // 2)
			
			if balanced_mp != spell.mp_cost:
				self.modify_spell(spell_id, mp_cost=balanced_mp)
				count += 1
		
		if self.verbose:
			print(f"✓ Balanced MP costs for {count} spells")
		
		return count
	
	def calculate_efficiency(self, spell: Spell) -> float:
		"""Calculate spell efficiency (damage or healing per MP)"""
		if spell.mp_cost == 0:
			return 0.0
		
		return spell.power / spell.mp_cost
	
	def get_efficiency_rankings(self) -> List[Tuple[Spell, float]]:
		"""Get spells ranked by efficiency"""
		rankings = []
		
		for spell_id in range(FFMQSpellDatabase.NUM_SPELLS):
			spell = self.extract_spell(spell_id)
			
			if not spell or spell.power == 0:
				continue
			
			efficiency = self.calculate_efficiency(spell)
			rankings.append((spell, efficiency))
		
		rankings.sort(key=lambda x: x[1], reverse=True)
		return rankings
	
	def export_json(self, output_path: Path) -> None:
		"""Export spell database to JSON"""
		spells = self.list_spells()
		
		data = {
			'spells': [s.to_dict() for s in spells],
			'spell_count': len(spells)
		}
		
		with open(output_path, 'w') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported {len(spells)} spells to {output_path}")
	
	def save_rom(self, output_path: Optional[Path] = None) -> None:
		"""Save modified ROM"""
		save_path = output_path or self.rom_path
		
		with open(save_path, 'wb') as f:
			f.write(self.rom_data)
		
		if self.verbose:
			print(f"✓ Saved ROM to {save_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Spell/Magic Editor')
	parser.add_argument('rom', type=str, help='FFMQ ROM file')
	parser.add_argument('--list-spells', action='store_true', help='List all spells')
	parser.add_argument('--type', type=str, choices=['white', 'black', 'wizard', 'support'],
						help='Filter by spell type')
	parser.add_argument('--show-spell', type=str, help='Show spell details')
	parser.add_argument('--edit-spell', type=str, help='Edit spell')
	parser.add_argument('--power', type=int, help='Set spell power')
	parser.add_argument('--mp', type=int, help='Set MP cost')
	parser.add_argument('--accuracy', type=int, help='Set accuracy')
	parser.add_argument('--balance-costs', action='store_true', help='Auto-balance MP costs')
	parser.add_argument('--calculate-efficiency', action='store_true', help='Calculate spell efficiency')
	parser.add_argument('--export', type=str, help='Export spells to JSON')
	parser.add_argument('--save', type=str, help='Save modified ROM')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FFMQSpellEditor(Path(args.rom), verbose=args.verbose)
	
	# List spells
	if args.list_spells:
		spell_type = None
		if args.type:
			spell_type = SpellType(args.type)
		
		spells = editor.list_spells(spell_type)
		
		type_filter = f" ({args.type})" if args.type else ""
		print(f"\nFFMQ Spells{type_filter} ({len(spells)}):\n")
		
		for spell in spells:
			status_info = ""
			if spell.status_effects:
				effects = [f"{s.effect_name} ({s.chance}%)" for s in spell.status_effects]
				status_info = f" [{', '.join(effects)}]"
			
			print(f"  {spell.spell_id:2d}: {spell.name:<15} | "
				  f"Pwr:{spell.power:3d} MP:{spell.mp_cost:2d} "
				  f"Acc:{spell.accuracy:3d}% {spell.element.value:<6} "
				  f"{spell.target.value}{status_info}")
		
		return 0
	
	# Show spell details
	if args.show_spell:
		# Find spell by name
		spell_id = None
		for sid, name in FFMQSpellDatabase.SPELLS.items():
			if name.lower() == args.show_spell.lower():
				spell_id = sid
				break
		
		if spell_id is None:
			print(f"❌ Spell '{args.show_spell}' not found")
			return 1
		
		spell = editor.extract_spell(spell_id)
		
		if spell:
			print(f"\n=== {spell.name} ===\n")
			print(f"ID: {spell.spell_id}")
			print(f"Type: {spell.spell_type.value.capitalize()}")
			print(f"Power: {spell.power}")
			print(f"MP Cost: {spell.mp_cost}")
			print(f"Target: {spell.target.value}")
			print(f"Element: {spell.element.value}")
			print(f"Accuracy: {spell.accuracy}%")
			print(f"Animation: {spell.animation_id}")
			
			if spell.status_effects:
				print(f"\nStatus Effects:")
				for effect in spell.status_effects:
					print(f"  • {effect.effect_name}: {effect.chance}% chance, {effect.duration} turns")
			
			efficiency = editor.calculate_efficiency(spell)
			print(f"\nEfficiency: {efficiency:.2f} power/MP")
		
		return 0
	
	# Edit spell
	if args.edit_spell:
		# Find spell by name
		spell_id = None
		for sid, name in FFMQSpellDatabase.SPELLS.items():
			if name.lower() == args.edit_spell.lower():
				spell_id = sid
				break
		
		if spell_id is None:
			print(f"❌ Spell '{args.edit_spell}' not found")
			return 1
		
		success = editor.modify_spell(spell_id, power=args.power, 
									   mp_cost=args.mp, accuracy=args.accuracy)
		
		if success and args.save:
			editor.save_rom(Path(args.save))
		
		return 0
	
	# Balance costs
	if args.balance_costs:
		count = editor.balance_mp_costs()
		
		print(f"\n✅ Balanced MP costs for {count} spells")
		
		if args.save:
			editor.save_rom(Path(args.save))
		
		return 0
	
	# Calculate efficiency
	if args.calculate_efficiency:
		rankings = editor.get_efficiency_rankings()
		
		print(f"\nSpell Efficiency Rankings:\n")
		print(f"{'Rank':<6} {'Spell':<15} {'Power':<7} {'MP':<5} {'Efficiency':<12}")
		print("=" * 60)
		
		for i, (spell, efficiency) in enumerate(rankings[:20], 1):
			print(f"{i:<6} {spell.name:<15} {spell.power:<7} {spell.mp_cost:<5} {efficiency:.2f}")
		
		return 0
	
	# Export
	if args.export:
		editor.export_json(Path(args.export))
		return 0
	
	print("Use --list-spells, --show-spell, --edit-spell, --balance-costs, --calculate-efficiency, or --export")
	return 0


if __name__ == '__main__':
	exit(main())
