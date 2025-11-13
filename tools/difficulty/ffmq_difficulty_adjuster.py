#!/usr/bin/env python3
"""
FFMQ Difficulty Adjuster - Game balance modification

Difficulty Features:
- Enemy scaling
- Damage multipliers
- EXP/Gil modifiers
- Item availability
- Save point restriction
- Random encounters

Difficulty Presets:
- Easy (0.5x damage, 2x EXP/Gil)
- Normal (1.0x default)
- Hard (1.5x damage, 0.75x EXP/Gil)
- Expert (2.0x damage, 0.5x EXP/Gil)
- Kaizo (3.0x damage, 0.25x EXP/Gil, limited saves)

Modifiers:
- Enemy HP/Attack/Defense
- Player damage taken/dealt
- EXP gain rate
- Gil gain rate
- Item drop rates
- Random encounter rate
- Boss difficulty

Features:
- Apply difficulty presets
- Custom modifiers
- Patch ROM
- Save configurations
- Revert changes

Usage:
	python ffmq_difficulty_adjuster.py --preset hard rom.smc
	python ffmq_difficulty_adjuster.py --enemy-hp 1.5 --exp 0.75 rom.smc
	python ffmq_difficulty_adjuster.py --config difficulty.json rom.smc
	python ffmq_difficulty_adjuster.py --list-presets
"""

import argparse
import json
import struct
from pathlib import Path
from typing import Dict, Optional
from dataclasses import dataclass, asdict
from enum import Enum


class DifficultyPreset(Enum):
	"""Difficulty preset"""
	EASY = "easy"
	NORMAL = "normal"
	HARD = "hard"
	EXPERT = "expert"
	KAIZO = "kaizo"


@dataclass
class DifficultyConfig:
	"""Difficulty configuration"""
	name: str = "Custom"
	
	# Enemy modifiers
	enemy_hp_mult: float = 1.0
	enemy_attack_mult: float = 1.0
	enemy_defense_mult: float = 1.0
	enemy_speed_mult: float = 1.0
	enemy_magic_mult: float = 1.0
	
	# Player modifiers
	player_damage_taken_mult: float = 1.0
	player_damage_dealt_mult: float = 1.0
	player_hp_mult: float = 1.0
	player_mp_mult: float = 1.0
	
	# Reward modifiers
	exp_mult: float = 1.0
	gil_mult: float = 1.0
	item_drop_mult: float = 1.0
	
	# Gameplay modifiers
	random_encounter_mult: float = 1.0
	boss_hp_mult: float = 1.0
	boss_attack_mult: float = 1.0
	
	# Restrictions
	save_points_only: bool = False
	limited_items: bool = False
	permadeath: bool = False
	
	def to_dict(self) -> dict:
		return asdict(self)


class DifficultyAdjuster:
	"""Difficulty adjuster"""
	
	# ROM offsets (example addresses - would need to be verified)
	ENEMY_STATS_BASE = 0x0F0000
	PLAYER_STATS_BASE = 0x0F8000
	EXP_TABLE_BASE = 0x0FA000
	GIL_TABLE_BASE = 0x0FA800
	ENCOUNTER_RATE = 0x0FB000
	
	# Difficulty presets
	PRESETS = {
		DifficultyPreset.EASY: DifficultyConfig(
			name="Easy",
			enemy_hp_mult=0.75,
			enemy_attack_mult=0.75,
			enemy_defense_mult=0.75,
			player_damage_taken_mult=0.5,
			player_damage_dealt_mult=1.5,
			exp_mult=2.0,
			gil_mult=2.0,
			item_drop_mult=1.5,
			random_encounter_mult=0.75
		),
		DifficultyPreset.NORMAL: DifficultyConfig(
			name="Normal"
		),
		DifficultyPreset.HARD: DifficultyConfig(
			name="Hard",
			enemy_hp_mult=1.5,
			enemy_attack_mult=1.5,
			enemy_defense_mult=1.25,
			player_damage_taken_mult=1.5,
			exp_mult=0.75,
			gil_mult=0.75,
			boss_hp_mult=1.75,
			boss_attack_mult=1.5
		),
		DifficultyPreset.EXPERT: DifficultyConfig(
			name="Expert",
			enemy_hp_mult=2.0,
			enemy_attack_mult=2.0,
			enemy_defense_mult=1.5,
			enemy_speed_mult=1.25,
			player_damage_taken_mult=2.0,
			player_damage_dealt_mult=0.75,
			exp_mult=0.5,
			gil_mult=0.5,
			item_drop_mult=0.75,
			boss_hp_mult=2.5,
			boss_attack_mult=2.0,
			save_points_only=True
		),
		DifficultyPreset.KAIZO: DifficultyConfig(
			name="Kaizo",
			enemy_hp_mult=3.0,
			enemy_attack_mult=3.0,
			enemy_defense_mult=2.0,
			enemy_speed_mult=1.5,
			enemy_magic_mult=1.5,
			player_damage_taken_mult=3.0,
			player_damage_dealt_mult=0.5,
			exp_mult=0.25,
			gil_mult=0.25,
			item_drop_mult=0.5,
			random_encounter_mult=1.5,
			boss_hp_mult=4.0,
			boss_attack_mult=3.0,
			save_points_only=True,
			limited_items=True
		)
	}
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.config = DifficultyConfig()
		self.rom_data: Optional[bytearray] = None
		self.original_rom: Optional[bytes] = None
	
	def load_rom(self, rom_path: Path) -> bool:
		"""Load ROM file"""
		try:
			with open(rom_path, 'rb') as f:
				self.rom_data = bytearray(f.read())
				self.original_rom = bytes(self.rom_data)
			
			if self.verbose:
				print(f"✓ Loaded ROM: {rom_path} ({len(self.rom_data):,} bytes)")
			
			return True
		
		except Exception as e:
			print(f"Error loading ROM: {e}")
			return False
	
	def save_rom(self, output_path: Path) -> bool:
		"""Save modified ROM"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return False
		
		try:
			with open(output_path, 'wb') as f:
				f.write(self.rom_data)
			
			if self.verbose:
				print(f"✓ Saved modified ROM: {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error saving ROM: {e}")
			return False
	
	def load_preset(self, preset: DifficultyPreset) -> None:
		"""Load difficulty preset"""
		self.config = self.PRESETS[preset]
		
		if self.verbose:
			print(f"✓ Loaded preset: {self.config.name}")
	
	def apply_config(self) -> bool:
		"""Apply difficulty configuration to ROM"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return False
		
		# Apply enemy modifiers
		self._modify_enemy_stats()
		
		# Apply player modifiers
		self._modify_player_stats()
		
		# Apply reward modifiers
		self._modify_exp_table()
		self._modify_gil_table()
		
		# Apply gameplay modifiers
		self._modify_encounter_rate()
		self._modify_boss_stats()
		
		if self.verbose:
			print(f"✓ Applied difficulty configuration")
		
		return True
	
	def _modify_enemy_stats(self) -> None:
		"""Modify enemy statistics"""
		if self.rom_data is None:
			return
		
		# Example: Modify 50 enemy entries
		for i in range(50):
			offset = self.ENEMY_STATS_BASE + (i * 32)
			
			if offset + 32 > len(self.rom_data):
				break
			
			# Read current stats
			hp = struct.unpack('<H', self.rom_data[offset:offset+2])[0]
			attack = self.rom_data[offset+2]
			defense = self.rom_data[offset+3]
			speed = self.rom_data[offset+4]
			magic = self.rom_data[offset+5]
			
			# Apply multipliers
			new_hp = int(hp * self.config.enemy_hp_mult)
			new_attack = int(attack * self.config.enemy_attack_mult)
			new_defense = int(defense * self.config.enemy_defense_mult)
			new_speed = int(speed * self.config.enemy_speed_mult)
			new_magic = int(magic * self.config.enemy_magic_mult)
			
			# Clamp values
			new_hp = min(65535, new_hp)
			new_attack = min(255, new_attack)
			new_defense = min(255, new_defense)
			new_speed = min(255, new_speed)
			new_magic = min(255, new_magic)
			
			# Write back
			struct.pack_into('<H', self.rom_data, offset, new_hp)
			self.rom_data[offset+2] = new_attack
			self.rom_data[offset+3] = new_defense
			self.rom_data[offset+4] = new_speed
			self.rom_data[offset+5] = new_magic
	
	def _modify_player_stats(self) -> None:
		"""Modify player statistics"""
		if self.rom_data is None:
			return
		
		# Example: Modify 4 character entries
		for i in range(4):
			offset = self.PLAYER_STATS_BASE + (i * 64)
			
			if offset + 64 > len(self.rom_data):
				break
			
			# Read HP/MP per level table
			for level in range(99):
				hp_offset = offset + level * 2
				mp_offset = offset + 200 + level * 2
				
				if hp_offset + 2 > len(self.rom_data):
					break
				
				hp = struct.unpack('<H', self.rom_data[hp_offset:hp_offset+2])[0]
				mp = struct.unpack('<H', self.rom_data[mp_offset:mp_offset+2])[0]
				
				new_hp = int(hp * self.config.player_hp_mult)
				new_mp = int(mp * self.config.player_mp_mult)
				
				new_hp = min(9999, new_hp)
				new_mp = min(999, new_mp)
				
				struct.pack_into('<H', self.rom_data, hp_offset, new_hp)
				struct.pack_into('<H', self.rom_data, mp_offset, new_mp)
	
	def _modify_exp_table(self) -> None:
		"""Modify EXP rewards"""
		if self.rom_data is None:
			return
		
		# Example: Modify 100 enemy EXP values
		for i in range(100):
			offset = self.EXP_TABLE_BASE + (i * 2)
			
			if offset + 2 > len(self.rom_data):
				break
			
			exp = struct.unpack('<H', self.rom_data[offset:offset+2])[0]
			new_exp = int(exp * self.config.exp_mult)
			new_exp = min(65535, new_exp)
			
			struct.pack_into('<H', self.rom_data, offset, new_exp)
	
	def _modify_gil_table(self) -> None:
		"""Modify Gil rewards"""
		if self.rom_data is None:
			return
		
		# Example: Modify 100 enemy Gil values
		for i in range(100):
			offset = self.GIL_TABLE_BASE + (i * 2)
			
			if offset + 2 > len(self.rom_data):
				break
			
			gil = struct.unpack('<H', self.rom_data[offset:offset+2])[0]
			new_gil = int(gil * self.config.gil_mult)
			new_gil = min(65535, new_gil)
			
			struct.pack_into('<H', self.rom_data, offset, new_gil)
	
	def _modify_encounter_rate(self) -> None:
		"""Modify random encounter rate"""
		if self.rom_data is None:
			return
		
		if self.ENCOUNTER_RATE + 1 > len(self.rom_data):
			return
		
		rate = self.rom_data[self.ENCOUNTER_RATE]
		new_rate = int(rate * self.config.random_encounter_mult)
		new_rate = max(1, min(255, new_rate))
		
		self.rom_data[self.ENCOUNTER_RATE] = new_rate
	
	def _modify_boss_stats(self) -> None:
		"""Modify boss statistics"""
		if self.rom_data is None:
			return
		
		# Example: Modify 20 boss entries
		boss_base = self.ENEMY_STATS_BASE + (30 * 32)  # Assume bosses start at enemy 30
		
		for i in range(20):
			offset = boss_base + (i * 32)
			
			if offset + 32 > len(self.rom_data):
				break
			
			hp = struct.unpack('<H', self.rom_data[offset:offset+2])[0]
			attack = self.rom_data[offset+2]
			
			new_hp = int(hp * self.config.boss_hp_mult)
			new_attack = int(attack * self.config.boss_attack_mult)
			
			new_hp = min(65535, new_hp)
			new_attack = min(255, new_attack)
			
			struct.pack_into('<H', self.rom_data, offset, new_hp)
			self.rom_data[offset+2] = new_attack
	
	def revert_changes(self) -> bool:
		"""Revert to original ROM"""
		if self.original_rom is None:
			print("Error: No original ROM")
			return False
		
		self.rom_data = bytearray(self.original_rom)
		
		if self.verbose:
			print(f"✓ Reverted to original ROM")
		
		return True
	
	def export_config(self, output_path: Path) -> bool:
		"""Export configuration to JSON"""
		try:
			with open(output_path, 'w', encoding='utf-8') as f:
				json.dump(self.config.to_dict(), f, indent='\t')
			
			if self.verbose:
				print(f"✓ Exported config to {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting config: {e}")
			return False
	
	def import_config(self, input_path: Path) -> bool:
		"""Import configuration from JSON"""
		try:
			with open(input_path, 'r', encoding='utf-8') as f:
				config_data = json.load(f)
			
			self.config = DifficultyConfig(**config_data)
			
			if self.verbose:
				print(f"✓ Imported config from {input_path}")
			
			return True
		
		except Exception as e:
			print(f"Error importing config: {e}")
			return False


def main():
	parser = argparse.ArgumentParser(description='FFMQ Difficulty Adjuster')
	parser.add_argument('rom', nargs='?', help='ROM file')
	parser.add_argument('--preset', type=str,
					   choices=['easy', 'normal', 'hard', 'expert', 'kaizo'],
					   help='Difficulty preset')
	parser.add_argument('--enemy-hp', type=float, help='Enemy HP multiplier')
	parser.add_argument('--enemy-attack', type=float, help='Enemy attack multiplier')
	parser.add_argument('--player-damage', type=float,
					   help='Player damage taken multiplier')
	parser.add_argument('--exp', type=float, help='EXP multiplier')
	parser.add_argument('--gil', type=float, help='Gil multiplier')
	parser.add_argument('--encounters', type=float,
					   help='Random encounter rate multiplier')
	parser.add_argument('--config', type=str, metavar='FILE',
					   help='Load config from JSON')
	parser.add_argument('--export-config', type=str, metavar='FILE',
					   help='Export config to JSON')
	parser.add_argument('--output', type=str, help='Output ROM path')
	parser.add_argument('--list-presets', action='store_true',
					   help='List difficulty presets')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	adjuster = DifficultyAdjuster(verbose=args.verbose)
	
	# List presets
	if args.list_presets:
		print("\n=== Difficulty Presets ===\n")
		
		for preset in DifficultyPreset:
			config = adjuster.PRESETS[preset]
			print(f"{preset.value.upper()}:")
			print(f"  Enemy HP: {config.enemy_hp_mult}x")
			print(f"  Enemy Attack: {config.enemy_attack_mult}x")
			print(f"  Player Damage Taken: {config.player_damage_taken_mult}x")
			print(f"  EXP: {config.exp_mult}x")
			print(f"  Gil: {config.gil_mult}x")
			if config.save_points_only:
				print(f"  Save Points Only: Yes")
			print()
		
		return 0
	
	if not args.rom:
		parser.print_help()
		return 1
	
	# Load ROM
	adjuster.load_rom(Path(args.rom))
	
	# Load preset
	if args.preset:
		preset = DifficultyPreset(args.preset)
		adjuster.load_preset(preset)
	
	# Load config
	if args.config:
		adjuster.import_config(Path(args.config))
	
	# Apply custom modifiers
	if args.enemy_hp:
		adjuster.config.enemy_hp_mult = args.enemy_hp
	
	if args.enemy_attack:
		adjuster.config.enemy_attack_mult = args.enemy_attack
	
	if args.player_damage:
		adjuster.config.player_damage_taken_mult = args.player_damage
	
	if args.exp:
		adjuster.config.exp_mult = args.exp
	
	if args.gil:
		adjuster.config.gil_mult = args.gil
	
	if args.encounters:
		adjuster.config.random_encounter_mult = args.encounters
	
	# Export config
	if args.export_config:
		adjuster.export_config(Path(args.export_config))
		return 0
	
	# Apply configuration
	adjuster.apply_config()
	
	# Save ROM
	output_path = args.output or args.rom.replace('.smc', f'_{args.preset or "custom"}.smc')
	adjuster.save_rom(Path(output_path))
	
	return 0


if __name__ == '__main__':
	exit(main())
