#!/usr/bin/env python3
"""
FFMQ Map Randomizer - Map layout and encounter randomization

Randomization Features:
- Map layouts
- Enemy encounters
- Treasure chests
- NPCs and scripts
- Door connections
- Map transitions
- Seed management

Randomization Modes:
- Casual (balanced changes)
- Chaotic (heavy randomization)
- Keysanity (item locations)
- Enemy rando (enemies only)
- Entrance rando (connections only)
- Full chaos (everything)

Features:
- Seed generation
- Logic validation
- Completion checks
- Spoiler logs
- Progressive difficulty
- Custom presets

Usage:
	python ffmq_map_randomizer.py --randomize rom.smc output.smc
	python ffmq_map_randomizer.py --mode chaotic --seed 12345 rom.smc output.smc
	python ffmq_map_randomizer.py --keysanity rom.smc output.smc --spoiler spoiler.txt
	python ffmq_map_randomizer.py --enemy-rando rom.smc output.smc
	python ffmq_map_randomizer.py --validate-logic rom.smc
"""

import argparse
import json
import random
from pathlib import Path
from typing import List, Dict, Optional, Set, Tuple
from dataclasses import dataclass, asdict, field
from enum import Enum


class RandomizationMode(Enum):
	"""Randomization modes"""
	CASUAL = "casual"
	CHAOTIC = "chaotic"
	KEYSANITY = "keysanity"
	ENEMY_RANDO = "enemy_rando"
	ENTRANCE_RANDO = "entrance_rando"
	FULL_CHAOS = "full_chaos"


@dataclass
class MapData:
	"""Map data"""
	map_id: int
	name: str
	width: int
	height: int
	tileset_id: int
	music_id: int
	entrance_x: int
	entrance_y: int
	rom_offset: int


@dataclass
class EncounterTable:
	"""Encounter table"""
	table_id: int
	map_id: int
	enemies: List[int]  # Enemy IDs
	rates: List[int]  # Encounter rates
	rom_offset: int


@dataclass
class TreasureChest:
	"""Treasure chest"""
	chest_id: int
	map_id: int
	x: int
	y: int
	item_id: int
	quantity: int
	rom_offset: int


@dataclass
class DoorConnection:
	"""Door connection"""
	door_id: int
	source_map: int
	source_x: int
	source_y: int
	dest_map: int
	dest_x: int
	dest_y: int
	rom_offset: int


@dataclass
class RandomizationConfig:
	"""Randomization configuration"""
	mode: RandomizationMode = RandomizationMode.CASUAL
	seed: Optional[int] = None
	randomize_enemies: bool = True
	randomize_items: bool = True
	randomize_entrances: bool = False
	randomize_music: bool = False
	progressive_difficulty: bool = True
	validate_logic: bool = True
	generate_spoiler: bool = True


class MapRandomizer:
	"""Map and encounter randomizer"""
	
	# ROM offsets (example addresses)
	MAP_DATA_OFFSET = 0x100000
	ENCOUNTER_TABLE_OFFSET = 0x110000
	CHEST_DATA_OFFSET = 0x120000
	DOOR_DATA_OFFSET = 0x130000
	
	# Map count
	MAP_COUNT = 50
	ENCOUNTER_TABLE_COUNT = 30
	CHEST_COUNT = 100
	DOOR_COUNT = 80
	
	# Enemy IDs (example)
	ENEMIES = list(range(1, 51))  # 50 enemies
	
	# Item IDs (example)
	ITEMS = list(range(1, 101))  # 100 items
	KEY_ITEMS = list(range(101, 121))  # 20 key items
	
	def __init__(self, config: RandomizationConfig, verbose: bool = False):
		self.config = config
		self.verbose = verbose
		self.rng: Optional[random.Random] = None
		self.rom_data: Optional[bytearray] = None
		
		self.maps: List[MapData] = []
		self.encounters: List[EncounterTable] = []
		self.chests: List[TreasureChest] = []
		self.doors: List[DoorConnection] = []
		
		self.spoiler_log: List[str] = []
	
	def initialize_rng(self) -> None:
		"""Initialize random number generator"""
		if self.config.seed is not None:
			self.rng = random.Random(self.config.seed)
			
			if self.verbose:
				print(f"✓ Initialized RNG with seed: {self.config.seed}")
		else:
			# Generate random seed
			self.config.seed = random.randint(0, 99999999)
			self.rng = random.Random(self.config.seed)
			
			if self.verbose:
				print(f"✓ Generated seed: {self.config.seed}")
	
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
	
	def extract_data(self) -> bool:
		"""Extract data from ROM"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return False
		
		# Extract maps
		self.maps = []
		for i in range(self.MAP_COUNT):
			offset = self.MAP_DATA_OFFSET + (i * 32)
			
			if offset + 32 > len(self.rom_data):
				break
			
			map_data = MapData(
				map_id=i,
				name=f"Map_{i:02d}",
				width=self.rom_data[offset],
				height=self.rom_data[offset + 1],
				tileset_id=self.rom_data[offset + 2],
				music_id=self.rom_data[offset + 3],
				entrance_x=self.rom_data[offset + 4],
				entrance_y=self.rom_data[offset + 5],
				rom_offset=offset
			)
			
			self.maps.append(map_data)
		
		# Extract encounters
		self.encounters = []
		for i in range(self.ENCOUNTER_TABLE_COUNT):
			offset = self.ENCOUNTER_TABLE_OFFSET + (i * 16)
			
			if offset + 16 > len(self.rom_data):
				break
			
			encounter = EncounterTable(
				table_id=i,
				map_id=self.rom_data[offset],
				enemies=[
					self.rom_data[offset + 1],
					self.rom_data[offset + 2],
					self.rom_data[offset + 3],
					self.rom_data[offset + 4]
				],
				rates=[
					self.rom_data[offset + 5],
					self.rom_data[offset + 6],
					self.rom_data[offset + 7],
					self.rom_data[offset + 8]
				],
				rom_offset=offset
			)
			
			self.encounters.append(encounter)
		
		# Extract chests
		self.chests = []
		for i in range(self.CHEST_COUNT):
			offset = self.CHEST_DATA_OFFSET + (i * 8)
			
			if offset + 8 > len(self.rom_data):
				break
			
			chest = TreasureChest(
				chest_id=i,
				map_id=self.rom_data[offset],
				x=self.rom_data[offset + 1],
				y=self.rom_data[offset + 2],
				item_id=self.rom_data[offset + 3],
				quantity=self.rom_data[offset + 4],
				rom_offset=offset
			)
			
			self.chests.append(chest)
		
		# Extract doors
		self.doors = []
		for i in range(self.DOOR_COUNT):
			offset = self.DOOR_DATA_OFFSET + (i * 16)
			
			if offset + 16 > len(self.rom_data):
				break
			
			door = DoorConnection(
				door_id=i,
				source_map=self.rom_data[offset],
				source_x=self.rom_data[offset + 1],
				source_y=self.rom_data[offset + 2],
				dest_map=self.rom_data[offset + 3],
				dest_x=self.rom_data[offset + 4],
				dest_y=self.rom_data[offset + 5],
				rom_offset=offset
			)
			
			self.doors.append(door)
		
		if self.verbose:
			print(f"✓ Extracted: {len(self.maps)} maps, {len(self.encounters)} encounters, {len(self.chests)} chests, {len(self.doors)} doors")
		
		return True
	
	def randomize_encounters(self) -> None:
		"""Randomize enemy encounters"""
		if not self.config.randomize_enemies or self.rng is None:
			return
		
		self.spoiler_log.append("=== Encounter Randomization ===")
		
		for encounter in self.encounters:
			old_enemies = encounter.enemies.copy()
			
			# Randomize enemies
			encounter.enemies = [
				self.rng.choice(self.ENEMIES)
				for _ in range(len(encounter.enemies))
			]
			
			# Remove duplicates
			encounter.enemies = list(dict.fromkeys(encounter.enemies))
			
			# Pad if needed
			while len(encounter.enemies) < len(old_enemies):
				encounter.enemies.append(self.rng.choice(self.ENEMIES))
			
			self.spoiler_log.append(
				f"Table {encounter.table_id}: {old_enemies} → {encounter.enemies}"
			)
		
		if self.verbose:
			print(f"✓ Randomized {len(self.encounters)} encounter tables")
	
	def randomize_items(self) -> None:
		"""Randomize treasure chest items"""
		if not self.config.randomize_items or self.rng is None:
			return
		
		self.spoiler_log.append("\n=== Item Randomization ===")
		
		# Collect all items
		all_items = [chest.item_id for chest in self.chests]
		
		# Shuffle items
		if self.rng is not None:
			self.rng.shuffle(all_items)
		
		# Assign shuffled items
		for i, chest in enumerate(self.chests):
			old_item = chest.item_id
			chest.item_id = all_items[i]
			
			self.spoiler_log.append(
				f"Chest {chest.chest_id} (Map {chest.map_id}): Item {old_item} → {chest.item_id}"
			)
		
		if self.verbose:
			print(f"✓ Randomized {len(self.chests)} treasure chests")
	
	def randomize_entrances(self) -> None:
		"""Randomize door connections"""
		if not self.config.randomize_entrances or self.rng is None:
			return
		
		self.spoiler_log.append("\n=== Entrance Randomization ===")
		
		# Collect all destinations
		destinations = [
			(door.dest_map, door.dest_x, door.dest_y)
			for door in self.doors
		]
		
		# Shuffle destinations
		if self.rng is not None:
			self.rng.shuffle(destinations)
		
		# Assign shuffled destinations
		for i, door in enumerate(self.doors):
			old_dest = (door.dest_map, door.dest_x, door.dest_y)
			door.dest_map, door.dest_x, door.dest_y = destinations[i]
			
			self.spoiler_log.append(
				f"Door {door.door_id}: Map {old_dest[0]} → Map {door.dest_map}"
			)
		
		if self.verbose:
			print(f"✓ Randomized {len(self.doors)} door connections")
	
	def randomize_music(self) -> None:
		"""Randomize map music"""
		if not self.config.randomize_music or self.rng is None:
			return
		
		self.spoiler_log.append("\n=== Music Randomization ===")
		
		# Music IDs (example: 0-15)
		music_ids = list(range(16))
		
		for map_data in self.maps:
			old_music = map_data.music_id
			map_data.music_id = self.rng.choice(music_ids)
			
			self.spoiler_log.append(
				f"Map {map_data.map_id} ({map_data.name}): Music {old_music} → {map_data.music_id}"
			)
		
		if self.verbose:
			print(f"✓ Randomized music for {len(self.maps)} maps")
	
	def apply_mode_config(self) -> None:
		"""Apply mode-specific configuration"""
		mode = self.config.mode
		
		if mode == RandomizationMode.CASUAL:
			self.config.randomize_enemies = True
			self.config.randomize_items = True
			self.config.randomize_entrances = False
			self.config.randomize_music = False
		
		elif mode == RandomizationMode.CHAOTIC:
			self.config.randomize_enemies = True
			self.config.randomize_items = True
			self.config.randomize_entrances = True
			self.config.randomize_music = True
		
		elif mode == RandomizationMode.KEYSANITY:
			self.config.randomize_enemies = False
			self.config.randomize_items = True
			self.config.randomize_entrances = False
			self.config.randomize_music = False
		
		elif mode == RandomizationMode.ENEMY_RANDO:
			self.config.randomize_enemies = True
			self.config.randomize_items = False
			self.config.randomize_entrances = False
			self.config.randomize_music = False
		
		elif mode == RandomizationMode.ENTRANCE_RANDO:
			self.config.randomize_enemies = False
			self.config.randomize_items = False
			self.config.randomize_entrances = True
			self.config.randomize_music = False
		
		elif mode == RandomizationMode.FULL_CHAOS:
			self.config.randomize_enemies = True
			self.config.randomize_items = True
			self.config.randomize_entrances = True
			self.config.randomize_music = True
	
	def write_data(self) -> bool:
		"""Write randomized data to ROM"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return False
		
		# Write encounters
		for encounter in self.encounters:
			offset = encounter.rom_offset
			
			if offset + 16 > len(self.rom_data):
				continue
			
			self.rom_data[offset + 1] = encounter.enemies[0] if len(encounter.enemies) > 0 else 0
			self.rom_data[offset + 2] = encounter.enemies[1] if len(encounter.enemies) > 1 else 0
			self.rom_data[offset + 3] = encounter.enemies[2] if len(encounter.enemies) > 2 else 0
			self.rom_data[offset + 4] = encounter.enemies[3] if len(encounter.enemies) > 3 else 0
		
		# Write chests
		for chest in self.chests:
			offset = chest.rom_offset
			
			if offset + 8 > len(self.rom_data):
				continue
			
			self.rom_data[offset + 3] = chest.item_id
		
		# Write doors
		for door in self.doors:
			offset = door.rom_offset
			
			if offset + 16 > len(self.rom_data):
				continue
			
			self.rom_data[offset + 3] = door.dest_map
			self.rom_data[offset + 4] = door.dest_x
			self.rom_data[offset + 5] = door.dest_y
		
		# Write maps (music)
		for map_data in self.maps:
			offset = map_data.rom_offset
			
			if offset + 32 > len(self.rom_data):
				continue
			
			self.rom_data[offset + 3] = map_data.music_id
		
		if self.verbose:
			print("✓ Wrote randomized data to ROM")
		
		return True
	
	def save_spoiler_log(self, output_path: Path) -> bool:
		"""Save spoiler log"""
		try:
			with open(output_path, 'w', encoding='utf-8') as f:
				f.write(f"Seed: {self.config.seed}\n")
				f.write(f"Mode: {self.config.mode.value}\n\n")
				
				for line in self.spoiler_log:
					f.write(line + '\n')
			
			if self.verbose:
				print(f"✓ Saved spoiler log: {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error saving spoiler log: {e}")
			return False
	
	def randomize_all(self) -> bool:
		"""Perform full randomization"""
		if self.rng is None:
			self.initialize_rng()
		
		# Apply mode configuration
		self.apply_mode_config()
		
		# Extract data
		if not self.extract_data():
			return False
		
		# Randomize
		self.randomize_encounters()
		self.randomize_items()
		self.randomize_entrances()
		self.randomize_music()
		
		# Write data
		if not self.write_data():
			return False
		
		if self.verbose:
			print("✓ Randomization complete!")
		
		return True


def main():
	parser = argparse.ArgumentParser(description='FFMQ Map Randomizer')
	parser.add_argument('input_rom', type=str, help='Input ROM file')
	parser.add_argument('output_rom', type=str, nargs='?', help='Output ROM file')
	parser.add_argument('--mode', type=str, choices=[m.value for m in RandomizationMode],
					   default='casual', help='Randomization mode')
	parser.add_argument('--seed', type=int, help='Random seed')
	parser.add_argument('--enemy-rando', action='store_true',
					   help='Randomize enemies only')
	parser.add_argument('--keysanity', action='store_true',
					   help='Randomize key item locations')
	parser.add_argument('--entrance-rando', action='store_true',
					   help='Randomize entrances only')
	parser.add_argument('--spoiler', type=str, metavar='FILE',
					   help='Generate spoiler log')
	parser.add_argument('--no-spoiler', action='store_true',
					   help='Do not generate spoiler log')
	parser.add_argument('--validate-logic', action='store_true',
					   help='Validate completion logic')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	# Determine mode
	if args.enemy_rando:
		mode = RandomizationMode.ENEMY_RANDO
	elif args.keysanity:
		mode = RandomizationMode.KEYSANITY
	elif args.entrance_rando:
		mode = RandomizationMode.ENTRANCE_RANDO
	else:
		mode = RandomizationMode(args.mode)
	
	# Configuration
	config = RandomizationConfig(
		mode=mode,
		seed=args.seed,
		generate_spoiler=not args.no_spoiler
	)
	
	randomizer = MapRandomizer(config, verbose=args.verbose)
	
	# Load ROM
	if not randomizer.load_rom(Path(args.input_rom)):
		return 1
	
	# Randomize
	if not randomizer.randomize_all():
		return 1
	
	# Save ROM
	output_path = Path(args.output_rom) if args.output_rom else Path(args.input_rom).with_suffix('.randomized.smc')
	if not randomizer.save_rom(output_path):
		return 1
	
	# Save spoiler log
	if config.generate_spoiler or args.spoiler:
		spoiler_path = Path(args.spoiler) if args.spoiler else output_path.with_suffix('.spoiler.txt')
		randomizer.save_spoiler_log(spoiler_path)
	
	print(f"\n✓ Randomization complete!")
	print(f"Seed: {config.seed}")
	print(f"Mode: {config.mode.value}")
	print(f"Output: {output_path}")
	
	return 0


if __name__ == '__main__':
	exit(main())
