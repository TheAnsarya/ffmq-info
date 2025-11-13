#!/usr/bin/env python3
"""
FFMQ Status Effect Editor - Edit status effects and ailments

Status Effects in FFMQ:
- Poison: HP loss over time
- Darkness: Reduced accuracy
- Confusion: Random targeting
- Silence: Cannot cast magic
- Sleep: Cannot act (breaks on damage)
- Paralyze: Cannot act
- Stone: Petrified (instant death)
- Death: KO'd

Features:
- View status effect data
- Edit effect parameters
- Modify durations
- Change damage formulas
- Set resistance values
- Configure cure methods
- Balance status difficulty
- Export effect database
- Import custom effects
- Status immunity settings

Effect Parameters:
- Base duration (turns)
- Damage per turn (poison)
- Accuracy modifier (darkness)
- Success rate
- Immunity flags
- Cure items
- Cure spells
- Auto-cure on battle end

Usage:
	python ffmq_status_editor.py rom.sfc --list-effects
	python ffmq_status_editor.py rom.sfc --show-effect poison
	python ffmq_status_editor.py rom.sfc --edit-effect poison --duration 5 --damage 20
	python ffmq_status_editor.py rom.sfc --set-immunity 0 poison
	python ffmq_status_editor.py rom.sfc --export effects.json
"""

import argparse
import json
import struct
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any, Set
from dataclasses import dataclass, field, asdict
from enum import Enum


class StatusEffect(Enum):
	"""Status effect types"""
	POISON = 0
	DARKNESS = 1
	CONFUSION = 2
	SILENCE = 3
	SLEEP = 4
	PARALYZE = 5
	STONE = 6
	DEATH = 7


class CureMethod(Enum):
	"""Methods to cure status"""
	ITEM = "item"
	SPELL = "spell"
	TIME = "time"
	DAMAGE = "damage"
	BATTLE_END = "battle_end"


@dataclass
class StatusEffectData:
	"""Status effect parameters"""
	effect_id: int
	name: str
	effect_type: StatusEffect
	base_duration: int  # Turns
	damage_per_turn: int  # For poison
	accuracy_modifier: int  # Percentage (-100 to +100)
	success_rate: int  # Percentage
	cure_methods: List[CureMethod]
	cure_items: List[int]
	cure_spells: List[int]
	auto_cure: bool  # Cure on battle end
	prevents_actions: bool
	prevents_magic: bool
	breaks_on_damage: bool
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['effect_type'] = self.effect_type.value
		d['cure_methods'] = [m.value for m in self.cure_methods]
		return d


@dataclass
class CharacterImmunity:
	"""Character status immunities"""
	character_id: int
	character_name: str
	immunities: Set[StatusEffect]
	
	def to_dict(self) -> dict:
		return {
			'character_id': self.character_id,
			'character_name': self.character_name,
			'immunities': [e.value for e in self.immunities]
		}


class FFMQStatusDatabase:
	"""Database of FFMQ status effects"""
	
	# Status effect data location
	STATUS_DATA_OFFSET = 0x310000
	NUM_STATUS_EFFECTS = 8
	STATUS_SIZE = 16
	
	# Character immunity data
	IMMUNITY_DATA_OFFSET = 0x311000
	NUM_CHARACTERS = 5
	
	# Status effect names
	STATUS_NAMES = {
		StatusEffect.POISON: "Poison",
		StatusEffect.DARKNESS: "Darkness",
		StatusEffect.CONFUSION: "Confusion",
		StatusEffect.SILENCE: "Silence",
		StatusEffect.SLEEP: "Sleep",
		StatusEffect.PARALYZE: "Paralyze",
		StatusEffect.STONE: "Stone",
		StatusEffect.DEATH: "Death",
	}
	
	# Cure items for each status
	CURE_ITEMS = {
		StatusEffect.POISON: [50, 54],  # Cure Potion, Elixir
		StatusEffect.DARKNESS: [51, 54],  # Heal Potion, Elixir
		StatusEffect.CONFUSION: [52, 54],  # Refresher, Elixir
		StatusEffect.SILENCE: [53, 54],  # Ether, Elixir
		StatusEffect.SLEEP: [],  # Breaks on damage
		StatusEffect.PARALYZE: [54],  # Elixir only
		StatusEffect.STONE: [54],  # Elixir only
		StatusEffect.DEATH: [54],  # Elixir only (or Life spell)
	}
	
	# Cure spells
	CURE_SPELLS = {
		StatusEffect.POISON: [2],  # Heal
		StatusEffect.DARKNESS: [2],  # Heal
		StatusEffect.CONFUSION: [3],  # Refresh
		StatusEffect.SILENCE: [3],  # Refresh
		StatusEffect.SLEEP: [],
		StatusEffect.PARALYZE: [],
		StatusEffect.STONE: [1],  # Life
		StatusEffect.DEATH: [1],  # Life
	}
	
	# Character names
	CHARACTER_NAMES = ["Benjamin", "Kaeli", "Tristam", "Phoebe", "Reuben"]


class FFMQStatusEditor:
	"""Edit FFMQ status effect data"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		if self.verbose:
			print(f"Loaded FFMQ ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def extract_status_effect(self, effect_type: StatusEffect) -> Optional[StatusEffectData]:
		"""Extract status effect data from ROM"""
		effect_id = effect_type.value
		
		if effect_id >= FFMQStatusDatabase.NUM_STATUS_EFFECTS:
			return None
		
		offset = FFMQStatusDatabase.STATUS_DATA_OFFSET + (effect_id * FFMQStatusDatabase.STATUS_SIZE)
		
		if offset + FFMQStatusDatabase.STATUS_SIZE > len(self.rom_data):
			return None
		
		# Read status data
		base_duration = self.rom_data[offset]
		damage_per_turn = self.rom_data[offset + 1]
		accuracy_modifier = struct.unpack_from('<b', self.rom_data, offset + 2)[0]  # Signed
		success_rate = self.rom_data[offset + 3]
		flags = self.rom_data[offset + 4]
		
		# Decode flags
		auto_cure = (flags & 0x01) != 0
		prevents_actions = (flags & 0x02) != 0
		prevents_magic = (flags & 0x04) != 0
		breaks_on_damage = (flags & 0x08) != 0
		
		# Determine cure methods
		cure_methods = []
		cure_items = FFMQStatusDatabase.CURE_ITEMS.get(effect_type, [])
		cure_spells = FFMQStatusDatabase.CURE_SPELLS.get(effect_type, [])
		
		if cure_items:
			cure_methods.append(CureMethod.ITEM)
		if cure_spells:
			cure_methods.append(CureMethod.SPELL)
		if base_duration > 0:
			cure_methods.append(CureMethod.TIME)
		if breaks_on_damage:
			cure_methods.append(CureMethod.DAMAGE)
		if auto_cure:
			cure_methods.append(CureMethod.BATTLE_END)
		
		effect = StatusEffectData(
			effect_id=effect_id,
			name=FFMQStatusDatabase.STATUS_NAMES[effect_type],
			effect_type=effect_type,
			base_duration=base_duration,
			damage_per_turn=damage_per_turn,
			accuracy_modifier=accuracy_modifier,
			success_rate=success_rate,
			cure_methods=cure_methods,
			cure_items=cure_items,
			cure_spells=cure_spells,
			auto_cure=auto_cure,
			prevents_actions=prevents_actions,
			prevents_magic=prevents_magic,
			breaks_on_damage=breaks_on_damage
		)
		
		return effect
	
	def list_status_effects(self) -> List[StatusEffectData]:
		"""List all status effects"""
		effects = []
		
		for effect_type in StatusEffect:
			effect = self.extract_status_effect(effect_type)
			if effect:
				effects.append(effect)
		
		return effects
	
	def modify_status_effect(self, effect_type: StatusEffect, 
							 duration: Optional[int] = None,
							 damage: Optional[int] = None,
							 success_rate: Optional[int] = None) -> bool:
		"""Modify status effect parameters"""
		effect_id = effect_type.value
		
		if effect_id >= FFMQStatusDatabase.NUM_STATUS_EFFECTS:
			return False
		
		offset = FFMQStatusDatabase.STATUS_DATA_OFFSET + (effect_id * FFMQStatusDatabase.STATUS_SIZE)
		
		if offset + FFMQStatusDatabase.STATUS_SIZE > len(self.rom_data):
			return False
		
		effect_name = FFMQStatusDatabase.STATUS_NAMES[effect_type]
		
		if duration is not None:
			self.rom_data[offset] = min(duration, 255)
			if self.verbose:
				print(f"✓ Set {effect_name} duration to {duration} turns")
		
		if damage is not None:
			self.rom_data[offset + 1] = min(damage, 255)
			if self.verbose:
				print(f"✓ Set {effect_name} damage to {damage} per turn")
		
		if success_rate is not None:
			self.rom_data[offset + 3] = min(success_rate, 100)
			if self.verbose:
				print(f"✓ Set {effect_name} success rate to {success_rate}%")
		
		return True
	
	def extract_character_immunities(self, character_id: int) -> Optional[CharacterImmunity]:
		"""Extract character status immunities"""
		if character_id >= FFMQStatusDatabase.NUM_CHARACTERS:
			return None
		
		offset = FFMQStatusDatabase.IMMUNITY_DATA_OFFSET + character_id
		
		if offset >= len(self.rom_data):
			return None
		
		immunity_byte = self.rom_data[offset]
		
		# Each bit represents immunity to a status
		immunities = set()
		for effect_type in StatusEffect:
			bit = 1 << effect_type.value
			if immunity_byte & bit:
				immunities.add(effect_type)
		
		char_immunity = CharacterImmunity(
			character_id=character_id,
			character_name=FFMQStatusDatabase.CHARACTER_NAMES[character_id],
			immunities=immunities
		)
		
		return char_immunity
	
	def set_character_immunity(self, character_id: int, effect_type: StatusEffect,
							   immune: bool = True) -> bool:
		"""Set character immunity to status effect"""
		if character_id >= FFMQStatusDatabase.NUM_CHARACTERS:
			return False
		
		offset = FFMQStatusDatabase.IMMUNITY_DATA_OFFSET + character_id
		
		if offset >= len(self.rom_data):
			return False
		
		immunity_byte = self.rom_data[offset]
		bit = 1 << effect_type.value
		
		if immune:
			immunity_byte |= bit
		else:
			immunity_byte &= ~bit
		
		self.rom_data[offset] = immunity_byte
		
		char_name = FFMQStatusDatabase.CHARACTER_NAMES[character_id]
		effect_name = FFMQStatusDatabase.STATUS_NAMES[effect_type]
		
		if self.verbose:
			action = "immune to" if immune else "vulnerable to"
			print(f"✓ Set {char_name} {action} {effect_name}")
		
		return True
	
	def list_character_immunities(self) -> List[CharacterImmunity]:
		"""List all character immunities"""
		immunities = []
		
		for i in range(FFMQStatusDatabase.NUM_CHARACTERS):
			char_immunity = self.extract_character_immunities(i)
			if char_immunity:
				immunities.append(char_immunity)
		
		return immunities
	
	def export_json(self, output_path: Path) -> None:
		"""Export status effect database to JSON"""
		effects = self.list_status_effects()
		immunities = self.list_character_immunities()
		
		data = {
			'status_effects': [e.to_dict() for e in effects],
			'character_immunities': [i.to_dict() for i in immunities]
		}
		
		with open(output_path, 'w') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported {len(effects)} status effects to {output_path}")
	
	def save_rom(self, output_path: Optional[Path] = None) -> None:
		"""Save modified ROM"""
		save_path = output_path or self.rom_path
		
		with open(save_path, 'wb') as f:
			f.write(self.rom_data)
		
		if self.verbose:
			print(f"✓ Saved ROM to {save_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Status Effect Editor')
	parser.add_argument('rom', type=str, help='FFMQ ROM file')
	parser.add_argument('--list-effects', action='store_true', help='List all status effects')
	parser.add_argument('--show-effect', type=str, help='Show effect details')
	parser.add_argument('--edit-effect', type=str, help='Edit status effect')
	parser.add_argument('--duration', type=int, help='Duration in turns')
	parser.add_argument('--damage', type=int, help='Damage per turn')
	parser.add_argument('--success-rate', type=int, help='Success rate percentage')
	parser.add_argument('--list-immunities', action='store_true', help='List character immunities')
	parser.add_argument('--set-immunity', type=int, help='Character ID for immunity')
	parser.add_argument('--effect', type=str, help='Status effect name')
	parser.add_argument('--immune', action='store_true', default=True, help='Set immune (default)')
	parser.add_argument('--vulnerable', action='store_true', help='Set vulnerable')
	parser.add_argument('--export', type=str, help='Export to JSON')
	parser.add_argument('--save', type=str, help='Save modified ROM')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FFMQStatusEditor(Path(args.rom), verbose=args.verbose)
	
	# List effects
	if args.list_effects:
		effects = editor.list_status_effects()
		
		print(f"\nFFMQ Status Effects ({len(effects)}):\n")
		print(f"{'Effect':<12} {'Duration':<10} {'Damage':<8} {'Success':<8} {'Cures'}")
		print("=" * 70)
		
		for effect in effects:
			cure_str = ', '.join([m.value for m in effect.cure_methods])
			flags = []
			if effect.prevents_actions:
				flags.append("no_act")
			if effect.prevents_magic:
				flags.append("no_magic")
			if effect.breaks_on_damage:
				flags.append("breaks")
			
			flag_str = f" [{', '.join(flags)}]" if flags else ""
			
			print(f"{effect.name:<12} {effect.base_duration:<10} {effect.damage_per_turn:<8} "
				  f"{effect.success_rate:<8}% {cure_str}{flag_str}")
		
		return 0
	
	# Show effect
	if args.show_effect:
		# Find effect by name
		effect_type = None
		for et in StatusEffect:
			if FFMQStatusDatabase.STATUS_NAMES[et].lower() == args.show_effect.lower():
				effect_type = et
				break
		
		if effect_type is None:
			print(f"❌ Status effect '{args.show_effect}' not found")
			return 1
		
		effect = editor.extract_status_effect(effect_type)
		
		if effect:
			print(f"\n=== {effect.name} ===\n")
			print(f"ID: {effect.effect_id}")
			print(f"Base Duration: {effect.base_duration} turns")
			print(f"Damage per Turn: {effect.damage_per_turn}")
			print(f"Accuracy Modifier: {effect.accuracy_modifier:+d}%")
			print(f"Success Rate: {effect.success_rate}%")
			print(f"Auto-cure on Battle End: {effect.auto_cure}")
			print(f"Prevents Actions: {effect.prevents_actions}")
			print(f"Prevents Magic: {effect.prevents_magic}")
			print(f"Breaks on Damage: {effect.breaks_on_damage}")
			
			print(f"\nCure Methods:")
			for method in effect.cure_methods:
				print(f"  • {method.value}")
			
			if effect.cure_items:
				print(f"\nCure Items: {effect.cure_items}")
			if effect.cure_spells:
				print(f"Cure Spells: {effect.cure_spells}")
		
		return 0
	
	# Edit effect
	if args.edit_effect:
		# Find effect by name
		effect_type = None
		for et in StatusEffect:
			if FFMQStatusDatabase.STATUS_NAMES[et].lower() == args.edit_effect.lower():
				effect_type = et
				break
		
		if effect_type is None:
			print(f"❌ Status effect '{args.edit_effect}' not found")
			return 1
		
		success = editor.modify_status_effect(effect_type, duration=args.duration,
											   damage=args.damage, success_rate=args.success_rate)
		
		if success and args.save:
			editor.save_rom(Path(args.save))
		
		return 0
	
	# List immunities
	if args.list_immunities:
		immunities = editor.list_character_immunities()
		
		print(f"\nCharacter Status Immunities:\n")
		
		for char_immunity in immunities:
			immune_list = [FFMQStatusDatabase.STATUS_NAMES[e] for e in char_immunity.immunities]
			immune_str = ', '.join(immune_list) if immune_list else "None"
			print(f"  {char_immunity.character_name:<10}: {immune_str}")
		
		return 0
	
	# Set immunity
	if args.set_immunity is not None and args.effect:
		# Find effect by name
		effect_type = None
		for et in StatusEffect:
			if FFMQStatusDatabase.STATUS_NAMES[et].lower() == args.effect.lower():
				effect_type = et
				break
		
		if effect_type is None:
			print(f"❌ Status effect '{args.effect}' not found")
			return 1
		
		immune = not args.vulnerable
		success = editor.set_character_immunity(args.set_immunity, effect_type, immune)
		
		if success and args.save:
			editor.save_rom(Path(args.save))
		
		return 0
	
	# Export
	if args.export:
		editor.export_json(Path(args.export))
		return 0
	
	print("Use --list-effects, --show-effect, --edit-effect, --list-immunities,")
	print("     --set-immunity, or --export")
	return 0


if __name__ == '__main__':
	exit(main())
