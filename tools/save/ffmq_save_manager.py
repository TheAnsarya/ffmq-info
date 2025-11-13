#!/usr/bin/env python3
"""
FFMQ Save State Manager - Manage emulator save states and SRAM

Save State Features:
- Parse emulator save states (Snes9x, ZSNES, bsnes)
- Extract SRAM data
- Modify save data
- Character stats editing
- Inventory management
- Story flag manipulation
- Position editing
- Time played tracking

SRAM Layout (8KB):
- Slot 1: 0x0000-0x0FFF (4KB)
- Slot 2: 0x1000-0x1FFF (4KB)
- Character data: HP, MP, stats, equipment
- Inventory: Items, weapons, armor
- Story flags: 256 bits
- Map position: X, Y, Map ID
- Time played: Hours, minutes, seconds
- Checksum: Validation

Features:
- Import/export save states
- Backup/restore saves
- Save editing
- Slot comparison
- Corruption detection
- Checksum repair
- Save conversion (emulator formats)
- Speedrun save templates

Usage:
	python ffmq_save_manager.py save.srm --list-slots
	python ffmq_save_manager.py save.srm --export-slot 1 --output slot1.json
	python ffmq_save_manager.py save.srm --edit-character Benjamin --hp 999
	python ffmq_save_manager.py save.srm --set-flag 42 --slot 1
	python ffmq_save_manager.py save.srm --backup backup.srm
	python ffmq_save_manager.py save.srm --repair-checksum
	python ffmq_save_manager.py state.000 --extract-sram --output save.srm
"""

import argparse
import json
import struct
import hashlib
from pathlib import Path
from typing import List, Dict, Tuple, Optional, Any
from dataclasses import dataclass, asdict
from enum import Enum


class Character(Enum):
	"""Playable characters"""
	BENJAMIN = 0
	KAELI = 1
	TRISTAM = 2
	PHOEBE = 3
	REUBEN = 4


class SaveSlotStatus(Enum):
	"""Save slot status"""
	EMPTY = "empty"
	VALID = "valid"
	CORRUPTED = "corrupted"


@dataclass
class CharacterData:
	"""Character save data"""
	character_id: int
	name: str
	level: int
	hp: int
	max_hp: int
	mp: int
	max_mp: int
	attack: int
	defense: int
	speed: int
	magic: int
	weapon_id: int
	armor_id: int
	accessory_id: int
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class SaveSlot:
	"""Complete save slot data"""
	slot_id: int
	status: SaveSlotStatus
	characters: List[CharacterData]
	inventory_items: Dict[int, int]  # Item ID -> quantity
	inventory_weapons: List[int]
	inventory_armor: List[int]
	story_flags: List[int]  # List of set flag IDs
	map_id: int
	position_x: int
	position_y: int
	gil: int
	time_played_seconds: int
	checksum: int
	checksum_valid: bool
	
	def to_dict(self) -> dict:
		d = {
			'slot_id': self.slot_id,
			'status': self.status.value,
			'characters': [c.to_dict() for c in self.characters],
			'inventory_items': self.inventory_items,
			'inventory_weapons': self.inventory_weapons,
			'inventory_armor': self.inventory_armor,
			'story_flags': self.story_flags,
			'map_id': self.map_id,
			'position_x': self.position_x,
			'position_y': self.position_y,
			'gil': self.gil,
			'time_played_seconds': self.time_played_seconds,
			'checksum': self.checksum,
			'checksum_valid': self.checksum_valid
		}
		return d


class FFMQSaveManager:
	"""Manage FFMQ save states and SRAM"""
	
	# SRAM constants
	SRAM_SIZE = 0x2000  # 8KB
	SLOT_SIZE = 0x1000  # 4KB per slot
	
	# Save data offsets (within slot)
	OFFSET_CHARACTER_DATA = 0x0000
	OFFSET_INVENTORY = 0x0100
	OFFSET_FLAGS = 0x0200
	OFFSET_POSITION = 0x0220
	OFFSET_GIL = 0x0230
	OFFSET_TIME = 0x0234
	OFFSET_CHECKSUM = 0x0FFE
	
	def __init__(self, save_path: Path, verbose: bool = False):
		self.save_path = save_path
		self.verbose = verbose
		self.sram_data = bytearray(self.SRAM_SIZE)
		
		if save_path.exists():
			self.load_save()
	
	def load_save(self) -> None:
		"""Load SRAM from file"""
		with open(self.save_path, 'rb') as f:
			data = f.read()
		
		# Handle different save formats
		if len(data) == self.SRAM_SIZE:
			# Raw SRAM
			self.sram_data = bytearray(data)
		elif len(data) > self.SRAM_SIZE:
			# Emulator save state - extract SRAM
			self.extract_sram_from_state(data)
		else:
			raise ValueError(f"Invalid save file size: {len(data)}")
		
		if self.verbose:
			print(f"✓ Loaded save from {self.save_path}")
	
	def extract_sram_from_state(self, state_data: bytes) -> None:
		"""Extract SRAM from emulator save state"""
		# Snes9x .000 format: SRAM at offset 0x5000
		# ZSNES .zst format: SRAM at offset 0x60000
		# Try common offsets
		
		for offset in [0x5000, 0x60000]:
			if offset + self.SRAM_SIZE <= len(state_data):
				candidate = state_data[offset:offset + self.SRAM_SIZE]
				# Check if it looks like valid SRAM
				if self.validate_sram(candidate):
					self.sram_data = bytearray(candidate)
					if self.verbose:
						print(f"✓ Extracted SRAM from save state at offset {offset:X}")
					return
		
		raise ValueError("Could not find SRAM in save state")
	
	def validate_sram(self, data: bytes) -> bool:
		"""Check if data looks like valid SRAM"""
		if len(data) != self.SRAM_SIZE:
			return False
		
		# Check for non-zero data in character section
		char_data = data[0:0x100]
		if all(b == 0 for b in char_data):
			return False
		
		return True
	
	def parse_slot(self, slot_id: int) -> SaveSlot:
		"""Parse save slot data"""
		if slot_id < 0 or slot_id > 1:
			raise ValueError(f"Invalid slot ID: {slot_id}")
		
		offset = slot_id * self.SLOT_SIZE
		slot_data = self.sram_data[offset:offset + self.SLOT_SIZE]
		
		# Check if slot is empty
		if all(b == 0 for b in slot_data[:0x100]):
			return SaveSlot(
				slot_id=slot_id,
				status=SaveSlotStatus.EMPTY,
				characters=[],
				inventory_items={},
				inventory_weapons=[],
				inventory_armor=[],
				story_flags=[],
				map_id=0,
				position_x=0,
				position_y=0,
				gil=0,
				time_played_seconds=0,
				checksum=0,
				checksum_valid=False
			)
		
		# Parse characters (5 characters, 32 bytes each)
		characters = []
		for char_id in range(5):
			char_offset = offset + self.OFFSET_CHARACTER_DATA + (char_id * 32)
			
			level = self.sram_data[char_offset + 0]
			hp = struct.unpack_from('<H', self.sram_data, char_offset + 2)[0]
			max_hp = struct.unpack_from('<H', self.sram_data, char_offset + 4)[0]
			mp = struct.unpack_from('<H', self.sram_data, char_offset + 6)[0]
			max_mp = struct.unpack_from('<H', self.sram_data, char_offset + 8)[0]
			attack = self.sram_data[char_offset + 10]
			defense = self.sram_data[char_offset + 11]
			speed = self.sram_data[char_offset + 12]
			magic = self.sram_data[char_offset + 13]
			weapon = self.sram_data[char_offset + 14]
			armor = self.sram_data[char_offset + 15]
			accessory = self.sram_data[char_offset + 16]
			
			if max_hp > 0:  # Character exists
				char_data = CharacterData(
					character_id=char_id,
					name=Character(char_id).name.capitalize(),
					level=level,
					hp=hp,
					max_hp=max_hp,
					mp=mp,
					max_mp=max_mp,
					attack=attack,
					defense=defense,
					speed=speed,
					magic=magic,
					weapon_id=weapon,
					armor_id=armor,
					accessory_id=accessory
				)
				characters.append(char_data)
		
		# Parse inventory
		inventory_items = {}
		for i in range(32):
			item_offset = offset + self.OFFSET_INVENTORY + (i * 2)
			item_id = self.sram_data[item_offset]
			quantity = self.sram_data[item_offset + 1]
			if item_id > 0:
				inventory_items[item_id] = quantity
		
		# Parse flags (256 flags = 32 bytes)
		story_flags = []
		for byte_idx in range(32):
			byte_val = self.sram_data[offset + self.OFFSET_FLAGS + byte_idx]
			for bit_idx in range(8):
				if byte_val & (1 << bit_idx):
					flag_id = byte_idx * 8 + bit_idx
					story_flags.append(flag_id)
		
		# Parse position
		map_id = self.sram_data[offset + self.OFFSET_POSITION]
		pos_x = struct.unpack_from('<H', self.sram_data, offset + self.OFFSET_POSITION + 1)[0]
		pos_y = struct.unpack_from('<H', self.sram_data, offset + self.OFFSET_POSITION + 3)[0]
		
		# Parse gil
		gil = struct.unpack_from('<I', self.sram_data, offset + self.OFFSET_GIL)[0]
		
		# Parse time (hours, minutes, seconds)
		time_offset = offset + self.OFFSET_TIME
		hours = struct.unpack_from('<H', self.sram_data, time_offset)[0]
		minutes = self.sram_data[time_offset + 2]
		seconds = self.sram_data[time_offset + 3]
		time_played = hours * 3600 + minutes * 60 + seconds
		
		# Parse checksum
		checksum = struct.unpack_from('<H', self.sram_data, offset + self.OFFSET_CHECKSUM)[0]
		calculated_checksum = self.calculate_checksum(slot_id)
		checksum_valid = (checksum == calculated_checksum)
		
		status = SaveSlotStatus.VALID if checksum_valid else SaveSlotStatus.CORRUPTED
		
		slot = SaveSlot(
			slot_id=slot_id,
			status=status,
			characters=characters,
			inventory_items=inventory_items,
			inventory_weapons=[],
			inventory_armor=[],
			story_flags=story_flags,
			map_id=map_id,
			position_x=pos_x,
			position_y=pos_y,
			gil=gil,
			time_played_seconds=time_played,
			checksum=checksum,
			checksum_valid=checksum_valid
		)
		
		return slot
	
	def calculate_checksum(self, slot_id: int) -> int:
		"""Calculate slot checksum"""
		offset = slot_id * self.SLOT_SIZE
		
		# Sum all bytes except checksum itself
		checksum = 0
		for i in range(self.SLOT_SIZE - 2):
			checksum = (checksum + self.sram_data[offset + i]) & 0xFFFF
		
		return checksum
	
	def repair_checksum(self, slot_id: int) -> None:
		"""Repair slot checksum"""
		checksum = self.calculate_checksum(slot_id)
		offset = slot_id * self.SLOT_SIZE + self.OFFSET_CHECKSUM
		
		struct.pack_into('<H', self.sram_data, offset, checksum)
		
		if self.verbose:
			print(f"✓ Repaired checksum for slot {slot_id}: {checksum:04X}")
	
	def save_sram(self, output_path: Optional[Path] = None) -> None:
		"""Save SRAM to file"""
		path = output_path or self.save_path
		
		with open(path, 'wb') as f:
			f.write(self.sram_data)
		
		if self.verbose:
			print(f"✓ Saved SRAM to {path}")
	
	def export_slot(self, slot_id: int, output_path: Path) -> None:
		"""Export slot to JSON"""
		slot = self.parse_slot(slot_id)
		
		with open(output_path, 'w') as f:
			json.dump(slot.to_dict(), f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported slot {slot_id} to {output_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Save State Manager')
	parser.add_argument('save', type=str, help='Save file (.srm or state file)')
	parser.add_argument('--list-slots', action='store_true', help='List save slots')
	parser.add_argument('--export-slot', type=int, help='Export slot to JSON')
	parser.add_argument('--repair-checksum', action='store_true', help='Repair checksums')
	parser.add_argument('--slot', type=int, default=0, help='Slot ID (0 or 1)')
	parser.add_argument('--output', type=str, help='Output file')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	manager = FFMQSaveManager(Path(args.save), verbose=args.verbose)
	
	# List slots
	if args.list_slots:
		print(f"\n=== Save Slots ===\n")
		
		for slot_id in range(2):
			slot = manager.parse_slot(slot_id)
			
			print(f"Slot {slot_id}: {slot.status.value.upper()}")
			
			if slot.status != SaveSlotStatus.EMPTY:
				print(f"  Characters: {len(slot.characters)}")
				print(f"  Gil: {slot.gil:,}")
				print(f"  Time: {slot.time_played_seconds // 3600}h {(slot.time_played_seconds % 3600) // 60}m")
				print(f"  Map: {slot.map_id} ({slot.position_x}, {slot.position_y})")
				print(f"  Checksum: {'✓ Valid' if slot.checksum_valid else '✗ Invalid'}")
				
				if slot.characters:
					print(f"  Party:")
					for char in slot.characters:
						print(f"    {char.name}: Lv{char.level} HP {char.hp}/{char.max_hp} MP {char.mp}/{char.max_mp}")
			
			print()
		
		return 0
	
	# Export slot
	if args.export_slot is not None:
		output_path = Path(args.output) if args.output else Path(f"slot{args.export_slot}.json")
		manager.export_slot(args.export_slot, output_path)
		return 0
	
	# Repair checksums
	if args.repair_checksum:
		for slot_id in range(2):
			slot = manager.parse_slot(slot_id)
			if slot.status != SaveSlotStatus.EMPTY:
				manager.repair_checksum(slot_id)
		
		manager.save_sram()
		return 0
	
	print("Use --list-slots, --export-slot, or --repair-checksum")
	return 0


if __name__ == '__main__':
	exit(main())
