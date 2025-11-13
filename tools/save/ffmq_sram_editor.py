#!/usr/bin/env python3
"""
FFMQ SRAM Save File Editor - Comprehensive save game editor

SRAM Structure:
- 9 save slots (3 slots × 3 copies for redundancy)
- Each slot: 0x38C bytes (908 bytes)
- Total SRAM: 0x1FEC bytes (8,172 bytes)

Save Slot Layout:
- Header: "FF0!" + 2-byte checksum
- Character 1: 0x50 bytes (80 bytes)
- Character 2: 0x50 bytes (80 bytes)
- Gold: 3 bytes (max 9,999,999)
- Position: X, Y, Facing
- Map ID
- Play Time: Hours, Minutes, Seconds
- Item counts and flags

Character Data (0x50 bytes each):
- Name: 8 bytes
- Level: 1 byte (max 99)
- Experience: 3 bytes (max 9,999,999)
- HP: Current/Max (2 bytes each)
- Stats: Attack, Defense, Speed, Magic (current + base)
- Status
- Weapon data

Features:
- Extract/insert save files from/to SRAM
- Edit character stats, gold, items
- Modify position, map, play time
- Verify/fix checksums
- Export to JSON for easy editing
- Import from JSON
- Backup/restore functionality

Reference: https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest/SRAM_map

Usage:
	python ffmq_sram_editor.py --extract save.srm --slot 1 --output save1.json
	python ffmq_sram_editor.py --edit save1.json --gold 9999999 --level 99
	python ffmq_sram_editor.py --insert save1.json save.srm --slot 1
	python ffmq_sram_editor.py --verify save.srm
	python ffmq_sram_editor.py --backup save.srm save_backup.srm
"""

import argparse
import json
import struct
from pathlib import Path
from typing import List, Dict, Optional, Tuple, Any
from dataclasses import dataclass, asdict, field
from enum import Enum


class StatusEffect(Enum):
	"""Character status effects"""
	NORMAL = 0x00
	POISON = 0x01
	DARK = 0x02
	MOOGLE = 0x04
	MINI = 0x08
	CONFUSION = 0x10
	PARALYZE = 0x20
	PETRIFY = 0x40
	FATAL = 0x80


@dataclass
class CharacterData:
	"""Character save data (0x50 bytes)"""
	name: str = "Benjamin"  # 8 bytes
	level: int = 1  # Max 99
	experience: int = 0  # Max 9,999,999 (3 bytes)
	current_hp: int = 50  # Max 65535 (2 bytes)
	max_hp: int = 50  # Max 65535 (2 bytes)
	status: int = 0  # Status flags
	current_attack: int = 5  # Max 99
	current_defense: int = 5  # Max 99
	current_speed: int = 5  # Max 99
	current_magic: int = 5  # Max 99
	base_attack: int = 5  # Max 99
	base_defense: int = 5  # Max 99
	base_speed: int = 5  # Max 99
	base_magic: int = 5  # Max 99
	weapon_count: int = 0  # Number of weapons equipped
	weapon_id: int = 0  # Current weapon ID
	raw_data: bytes = b'\x00' * 0x50  # Full 80 bytes


@dataclass
class SaveSlot:
	"""Save slot data (0x38C bytes)"""
	slot_id: int = 0  # 0-2 (A, B, C copies)
	valid: bool = False
	checksum: int = 0
	character1: CharacterData = field(default_factory=CharacterData)
	character2: CharacterData = field(default_factory=CharacterData)
	gold: int = 0  # Max 9,999,999 (3 bytes)
	player_x: int = 0  # Player X position
	player_y: int = 0  # Player Y position
	player_facing: int = 0  # 0=Down, 1=Up, 2=Left, 3=Right
	map_id: int = 0  # Current map
	play_time_hours: int = 0  # Hours played
	play_time_minutes: int = 0  # Minutes
	play_time_seconds: int = 0  # Seconds
	cure_count: int = 0  # Number of cures used
	raw_data: bytes = b'\x00' * 0x38C  # Full slot data


class SRAMEditor:
	"""SRAM save file editor"""
	
	# SRAM layout constants
	SLOT_SIZE = 0x38C  # 908 bytes per slot
	TOTAL_SLOTS = 9  # 3 slots × 3 copies
	SRAM_SIZE = 0x1FEC  # 8,172 bytes total
	CHARACTER_SIZE = 0x50  # 80 bytes per character
	
	# Slot offsets
	SLOT_OFFSETS = {
		'1A': 0x0000, '2A': 0x038C, '3A': 0x0718,
		'1B': 0x0AA4, '2B': 0x0E30, '3B': 0x11BC,
		'1C': 0x154B, '2C': 0x18D4, '3C': 0x1C60
	}
	
	# Within-slot offsets
	OFFSET_HEADER = 0x000  # "FF0!" + checksum
	OFFSET_CHAR1 = 0x006
	OFFSET_CHAR2 = 0x056
	OFFSET_GOLD = 0x0A6
	OFFSET_PLAYER_X = 0x0AB
	OFFSET_PLAYER_Y = 0x0AC
	OFFSET_PLAYER_FACING = 0x0AD
	OFFSET_MAP_ID = 0x0B3
	OFFSET_PLAY_TIME = 0x0B9  # 3 bytes: SSMMHH
	OFFSET_CURE_COUNT = 0x0C1
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.sram_data: Optional[bytearray] = None
		self.slots: Dict[str, SaveSlot] = {}
	
	def load_sram(self, sram_path: Path) -> bool:
		"""Load SRAM file"""
		try:
			with open(sram_path, 'rb') as f:
				self.sram_data = bytearray(f.read())
			
			if len(self.sram_data) < self.SRAM_SIZE:
				# Pad to full size
				self.sram_data += b'\x00' * (self.SRAM_SIZE - len(self.sram_data))
			
			if self.verbose:
				print(f"✓ Loaded SRAM: {sram_path} ({len(self.sram_data):,} bytes)")
			
			return True
		
		except Exception as e:
			print(f"Error loading SRAM: {e}")
			return False
	
	def save_sram(self, output_path: Path) -> bool:
		"""Save SRAM file"""
		if self.sram_data is None:
			print("Error: No SRAM loaded")
			return False
		
		try:
			with open(output_path, 'wb') as f:
				f.write(self.sram_data[:self.SRAM_SIZE])
			
			if self.verbose:
				print(f"✓ Saved SRAM: {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error saving SRAM: {e}")
			return False
	
	def calculate_checksum(self, slot_data: bytes) -> int:
		"""Calculate checksum for save slot"""
		# Checksum is sum of all bytes after header (bytes 6+)
		# Stored as 16-bit value at offset 4-5
		checksum = sum(slot_data[6:]) & 0xFFFF
		return checksum
	
	def verify_slot(self, slot_name: str) -> bool:
		"""Verify slot header and checksum"""
		if self.sram_data is None:
			return False
		
		offset = self.SLOT_OFFSETS.get(slot_name)
		if offset is None:
			return False
		
		slot_data = self.sram_data[offset:offset + self.SLOT_SIZE]
		
		# Check header "FF0!"
		header = bytes(slot_data[0:4])
		if header != b'FF0!':
			return False
		
		# Verify checksum
		stored_checksum = struct.unpack('<H', slot_data[4:6])[0]
		calculated_checksum = self.calculate_checksum(slot_data)
		
		return stored_checksum == calculated_checksum
	
	def fix_checksum(self, slot_name: str) -> bool:
		"""Fix checksum for slot"""
		if self.sram_data is None:
			return False
		
		offset = self.SLOT_OFFSETS.get(slot_name)
		if offset is None:
			return False
		
		slot_data = self.sram_data[offset:offset + self.SLOT_SIZE]
		
		# Calculate and update checksum
		checksum = self.calculate_checksum(slot_data)
		struct.pack_into('<H', self.sram_data, offset + 4, checksum)
		
		if self.verbose:
			print(f"✓ Fixed checksum for slot {slot_name}: 0x{checksum:04X}")
		
		return True
	
	def extract_character(self, char_data: bytes) -> CharacterData:
		"""Extract character data from bytes"""
		char = CharacterData()
		char.raw_data = char_data
		
		# Name (8 bytes, null-terminated)
		name_bytes = char_data[0:8]
		char.name = name_bytes.split(b'\x00')[0].decode('ascii', errors='ignore')
		
		# Level
		char.level = char_data[0x10]
		
		# Experience (3 bytes, little-endian)
		char.experience = struct.unpack('<I', char_data[0x11:0x14] + b'\x00')[0]
		
		# HP
		char.current_hp = struct.unpack('<H', char_data[0x14:0x16])[0]
		char.max_hp = struct.unpack('<H', char_data[0x16:0x18])[0]
		
		# Status
		char.status = char_data[0x21]
		
		# Current stats
		char.current_attack = char_data[0x22]
		char.current_defense = char_data[0x23]
		char.current_speed = char_data[0x24]
		char.current_magic = char_data[0x25]
		
		# Base stats
		char.base_attack = char_data[0x26]
		char.base_defense = char_data[0x27]
		char.base_speed = char_data[0x28]
		char.base_magic = char_data[0x29]
		
		# Weapon
		char.weapon_count = char_data[0x30]
		char.weapon_id = char_data[0x31]
		
		return char
	
	def pack_character(self, char: CharacterData) -> bytes:
		"""Pack character data to bytes"""
		data = bytearray(char.raw_data)
		
		# Name (8 bytes, null-padded)
		name_bytes = char.name.encode('ascii')[:8].ljust(8, b'\x00')
		data[0:8] = name_bytes
		
		# Level
		data[0x10] = min(char.level, 99)
		
		# Experience (3 bytes)
		exp_bytes = struct.pack('<I', min(char.experience, 9999999))[:3]
		data[0x11:0x14] = exp_bytes
		
		# HP
		struct.pack_into('<H', data, 0x14, min(char.current_hp, 65535))
		struct.pack_into('<H', data, 0x16, min(char.max_hp, 65535))
		
		# Status
		data[0x21] = char.status
		
		# Current stats
		data[0x22] = min(char.current_attack, 99)
		data[0x23] = min(char.current_defense, 99)
		data[0x24] = min(char.current_speed, 99)
		data[0x25] = min(char.current_magic, 99)
		
		# Base stats
		data[0x26] = min(char.base_attack, 99)
		data[0x27] = min(char.base_defense, 99)
		data[0x28] = min(char.base_speed, 99)
		data[0x29] = min(char.base_magic, 99)
		
		# Weapon
		data[0x30] = char.weapon_count
		data[0x31] = char.weapon_id
		
		return bytes(data)
	
	def extract_slot(self, slot_name: str) -> Optional[SaveSlot]:
		"""Extract save slot data"""
		if self.sram_data is None:
			return None
		
		offset = self.SLOT_OFFSETS.get(slot_name)
		if offset is None:
			return None
		
		slot_data = self.sram_data[offset:offset + self.SLOT_SIZE]
		
		slot = SaveSlot()
		slot.slot_id = int(slot_name[0]) - 1  # 0-2
		slot.raw_data = bytes(slot_data)
		
		# Verify header
		header = bytes(slot_data[0:4])
		slot.valid = (header == b'FF0!')
		
		if not slot.valid:
			return slot
		
		# Checksum
		slot.checksum = struct.unpack('<H', slot_data[4:6])[0]
		
		# Characters
		char1_data = slot_data[self.OFFSET_CHAR1:self.OFFSET_CHAR1 + self.CHARACTER_SIZE]
		char2_data = slot_data[self.OFFSET_CHAR2:self.OFFSET_CHAR2 + self.CHARACTER_SIZE]
		
		slot.character1 = self.extract_character(char1_data)
		slot.character2 = self.extract_character(char2_data)
		
		# Gold (3 bytes, little-endian)
		slot.gold = struct.unpack('<I', slot_data[self.OFFSET_GOLD:self.OFFSET_GOLD + 3] + b'\x00')[0]
		
		# Position
		slot.player_x = slot_data[self.OFFSET_PLAYER_X]
		slot.player_y = slot_data[self.OFFSET_PLAYER_Y]
		slot.player_facing = slot_data[self.OFFSET_PLAYER_FACING]
		
		# Map
		slot.map_id = slot_data[self.OFFSET_MAP_ID]
		
		# Play time (3 bytes: SSMMHH)
		time_bytes = slot_data[self.OFFSET_PLAY_TIME:self.OFFSET_PLAY_TIME + 3]
		slot.play_time_seconds = time_bytes[0]
		slot.play_time_minutes = time_bytes[1]
		slot.play_time_hours = time_bytes[2]
		
		# Cure count
		slot.cure_count = slot_data[self.OFFSET_CURE_COUNT]
		
		return slot
	
	def insert_slot(self, slot: SaveSlot, slot_name: str) -> bool:
		"""Insert save slot data"""
		if self.sram_data is None:
			return False
		
		offset = self.SLOT_OFFSETS.get(slot_name)
		if offset is None:
			return False
		
		# Start with existing data or zeros
		slot_data = bytearray(slot.raw_data if slot.raw_data else b'\x00' * self.SLOT_SIZE)
		
		# Header
		slot_data[0:4] = b'FF0!'
		
		# Characters
		char1_bytes = self.pack_character(slot.character1)
		char2_bytes = self.pack_character(slot.character2)
		
		slot_data[self.OFFSET_CHAR1:self.OFFSET_CHAR1 + self.CHARACTER_SIZE] = char1_bytes
		slot_data[self.OFFSET_CHAR2:self.OFFSET_CHAR2 + self.CHARACTER_SIZE] = char2_bytes
		
		# Gold (3 bytes)
		gold_bytes = struct.pack('<I', min(slot.gold, 9999999))[:3]
		slot_data[self.OFFSET_GOLD:self.OFFSET_GOLD + 3] = gold_bytes
		
		# Position
		slot_data[self.OFFSET_PLAYER_X] = slot.player_x
		slot_data[self.OFFSET_PLAYER_Y] = slot.player_y
		slot_data[self.OFFSET_PLAYER_FACING] = slot.player_facing & 0x03
		
		# Map
		slot_data[self.OFFSET_MAP_ID] = slot.map_id
		
		# Play time
		slot_data[self.OFFSET_PLAY_TIME] = slot.play_time_seconds
		slot_data[self.OFFSET_PLAY_TIME + 1] = slot.play_time_minutes
		slot_data[self.OFFSET_PLAY_TIME + 2] = slot.play_time_hours
		
		# Cure count
		slot_data[self.OFFSET_CURE_COUNT] = slot.cure_count
		
		# Calculate checksum
		checksum = self.calculate_checksum(slot_data)
		struct.pack_into('<H', slot_data, 4, checksum)
		
		# Write to SRAM
		self.sram_data[offset:offset + self.SLOT_SIZE] = slot_data
		
		if self.verbose:
			print(f"✓ Inserted slot {slot_name} with checksum 0x{checksum:04X}")
		
		return True
	
	def export_slot_json(self, slot: SaveSlot, output_path: Path) -> bool:
		"""Export slot to JSON"""
		try:
			data: Dict[str, Any] = {
				'slot_id': slot.slot_id,
				'valid': slot.valid,
				'checksum': f"0x{slot.checksum:04X}",
				'character1': {
					'name': slot.character1.name,
					'level': slot.character1.level,
					'experience': slot.character1.experience,
					'current_hp': slot.character1.current_hp,
					'max_hp': slot.character1.max_hp,
					'status': f"0x{slot.character1.status:02X}",
					'stats': {
						'current': {
							'attack': slot.character1.current_attack,
							'defense': slot.character1.current_defense,
							'speed': slot.character1.current_speed,
							'magic': slot.character1.current_magic
						},
						'base': {
							'attack': slot.character1.base_attack,
							'defense': slot.character1.base_defense,
							'speed': slot.character1.base_speed,
							'magic': slot.character1.base_magic
						}
					},
					'weapon_count': slot.character1.weapon_count,
					'weapon_id': slot.character1.weapon_id
				},
				'character2': {
					'name': slot.character2.name,
					'level': slot.character2.level,
					'experience': slot.character2.experience,
					'current_hp': slot.character2.current_hp,
					'max_hp': slot.character2.max_hp,
					'status': f"0x{slot.character2.status:02X}",
					'stats': {
						'current': {
							'attack': slot.character2.current_attack,
							'defense': slot.character2.current_defense,
							'speed': slot.character2.current_speed,
							'magic': slot.character2.current_magic
						},
						'base': {
							'attack': slot.character2.base_attack,
							'defense': slot.character2.base_defense,
							'speed': slot.character2.base_speed,
							'magic': slot.character2.base_magic
						}
					},
					'weapon_count': slot.character2.weapon_count,
					'weapon_id': slot.character2.weapon_id
				},
				'gold': slot.gold,
				'position': {
					'x': slot.player_x,
					'y': slot.player_y,
					'facing': slot.player_facing
				},
				'map_id': slot.map_id,
				'play_time': {
					'hours': slot.play_time_hours,
					'minutes': slot.play_time_minutes,
					'seconds': slot.play_time_seconds,
					'total_seconds': slot.play_time_hours * 3600 + slot.play_time_minutes * 60 + slot.play_time_seconds
				},
				'cure_count': slot.cure_count
			}
			
			with open(output_path, 'w', encoding='utf-8') as f:
				json.dump(data, f, indent='\t')
			
			if self.verbose:
				print(f"✓ Exported to JSON: {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting JSON: {e}")
			return False
	
	def import_slot_json(self, input_path: Path) -> Optional[SaveSlot]:
		"""Import slot from JSON"""
		try:
			with open(input_path, 'r', encoding='utf-8') as f:
				data = json.load(f)
			
			slot = SaveSlot()
			slot.slot_id = data.get('slot_id', 0)
			slot.valid = data.get('valid', True)
			
			# Character 1
			c1 = data['character1']
			slot.character1.name = c1['name']
			slot.character1.level = c1['level']
			slot.character1.experience = c1['experience']
			slot.character1.current_hp = c1['current_hp']
			slot.character1.max_hp = c1['max_hp']
			slot.character1.status = int(c1.get('status', '0x00'), 16)
			
			slot.character1.current_attack = c1['stats']['current']['attack']
			slot.character1.current_defense = c1['stats']['current']['defense']
			slot.character1.current_speed = c1['stats']['current']['speed']
			slot.character1.current_magic = c1['stats']['current']['magic']
			
			slot.character1.base_attack = c1['stats']['base']['attack']
			slot.character1.base_defense = c1['stats']['base']['defense']
			slot.character1.base_speed = c1['stats']['base']['speed']
			slot.character1.base_magic = c1['stats']['base']['magic']
			
			slot.character1.weapon_count = c1.get('weapon_count', 0)
			slot.character1.weapon_id = c1.get('weapon_id', 0)
			
			# Character 2
			c2 = data['character2']
			slot.character2.name = c2['name']
			slot.character2.level = c2['level']
			slot.character2.experience = c2['experience']
			slot.character2.current_hp = c2['current_hp']
			slot.character2.max_hp = c2['max_hp']
			slot.character2.status = int(c2.get('status', '0x00'), 16)
			
			slot.character2.current_attack = c2['stats']['current']['attack']
			slot.character2.current_defense = c2['stats']['current']['defense']
			slot.character2.current_speed = c2['stats']['current']['speed']
			slot.character2.current_magic = c2['stats']['current']['magic']
			
			slot.character2.base_attack = c2['stats']['base']['attack']
			slot.character2.base_defense = c2['stats']['base']['defense']
			slot.character2.base_speed = c2['stats']['base']['speed']
			slot.character2.base_magic = c2['stats']['base']['magic']
			
			slot.character2.weapon_count = c2.get('weapon_count', 0)
			slot.character2.weapon_id = c2.get('weapon_id', 0)
			
			# Other data
			slot.gold = data['gold']
			slot.player_x = data['position']['x']
			slot.player_y = data['position']['y']
			slot.player_facing = data['position']['facing']
			slot.map_id = data['map_id']
			slot.play_time_hours = data['play_time']['hours']
			slot.play_time_minutes = data['play_time']['minutes']
			slot.play_time_seconds = data['play_time']['seconds']
			slot.cure_count = data['cure_count']
			
			if self.verbose:
				print(f"✓ Imported from JSON: {input_path}")
			
			return slot
		
		except Exception as e:
			print(f"Error importing JSON: {e}")
			return None
	
	def list_slots(self) -> None:
		"""List all save slots with status"""
		if self.sram_data is None:
			print("Error: No SRAM loaded")
			return
		
		print("\n=== SRAM Save Slots ===\n")
		
		for slot_name in sorted(self.SLOT_OFFSETS.keys()):
			valid = self.verify_slot(slot_name)
			slot = self.extract_slot(slot_name)
			
			if slot and slot.valid:
				status = "✓ VALID" if valid else "⚠ CHECKSUM ERROR"
				print(f"{slot_name}: {status}")
				print(f"  Character 1: {slot.character1.name} (Lv {slot.character1.level})")
				print(f"  Character 2: {slot.character2.name} (Lv {slot.character2.level})")
				print(f"  Gold: {slot.gold:,}")
				print(f"  Play Time: {slot.play_time_hours:02d}:{slot.play_time_minutes:02d}:{slot.play_time_seconds:02d}")
				print(f"  Map: {slot.map_id}")
			else:
				print(f"{slot_name}: ✗ EMPTY/INVALID")
			
			print()
	
	def verify_all(self) -> None:
		"""Verify all save slots"""
		if self.sram_data is None:
			print("Error: No SRAM loaded")
			return
		
		print("\n=== SRAM Verification ===\n")
		
		valid_count = 0
		invalid_count = 0
		
		for slot_name in sorted(self.SLOT_OFFSETS.keys()):
			valid = self.verify_slot(slot_name)
			slot = self.extract_slot(slot_name)
			
			if slot and slot.valid:
				if valid:
					print(f"{slot_name}: ✓ Valid (checksum 0x{slot.checksum:04X})")
					valid_count += 1
				else:
					print(f"{slot_name}: ⚠ Checksum error (stored 0x{slot.checksum:04X})")
					invalid_count += 1
			else:
				print(f"{slot_name}: ✗ Empty/Invalid")
		
		print(f"\nTotal: {valid_count} valid, {invalid_count} invalid")


def main():
	parser = argparse.ArgumentParser(
		description='FFMQ SRAM Save File Editor',
		epilog='Reference: https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest/SRAM_map'
	)
	
	parser.add_argument('sram', type=str, nargs='?', help='SRAM file (.srm)')
	parser.add_argument('--extract', type=str, metavar='SLOT',
					   help='Extract slot (1A, 2A, 3A, 1B, 2B, 3B, 1C, 2C, 3C)')
	parser.add_argument('--insert', type=str, metavar='JSON',
					   help='Insert from JSON file')
	parser.add_argument('--slot', type=str, metavar='SLOT',
					   help='Target slot for insert')
	parser.add_argument('--output', type=str, metavar='FILE',
					   help='Output file (JSON or SRAM)')
	parser.add_argument('--list', action='store_true',
					   help='List all save slots')
	parser.add_argument('--verify', action='store_true',
					   help='Verify all checksums')
	parser.add_argument('--fix-checksums', action='store_true',
					   help='Fix all checksums')
	parser.add_argument('--backup', type=str, metavar='FILE',
					   help='Create backup of SRAM')
	parser.add_argument('--verbose', action='store_true',
					   help='Verbose output')
	
	args = parser.parse_args()
	
	if not args.sram:
		parser.print_help()
		return 1
	
	editor = SRAMEditor(verbose=args.verbose)
	
	# Load SRAM
	if not editor.load_sram(Path(args.sram)):
		return 1
	
	# Backup
	if args.backup:
		import shutil
		shutil.copy(args.sram, args.backup)
		print(f"✓ Backup created: {args.backup}")
	
	# List slots
	if args.list:
		editor.list_slots()
		return 0
	
	# Verify
	if args.verify:
		editor.verify_all()
		return 0
	
	# Fix checksums
	if args.fix_checksums:
		for slot_name in editor.SLOT_OFFSETS.keys():
			editor.fix_checksum(slot_name)
		
		editor.save_sram(Path(args.sram))
		print("✓ Fixed all checksums")
		return 0
	
	# Extract slot
	if args.extract:
		slot = editor.extract_slot(args.extract.upper())
		
		if not slot or not slot.valid:
			print(f"Error: Slot {args.extract} is empty or invalid")
			return 1
		
		output = Path(args.output) if args.output else Path(f"slot_{args.extract}.json")
		editor.export_slot_json(slot, output)
		return 0
	
	# Insert slot
	if args.insert and args.slot:
		slot = editor.import_slot_json(Path(args.insert))
		
		if not slot:
			print(f"Error: Failed to import {args.insert}")
			return 1
		
		if not editor.insert_slot(slot, args.slot.upper()):
			print(f"Error: Failed to insert into slot {args.slot}")
			return 1
		
		output = Path(args.output) if args.output else Path(args.sram)
		editor.save_sram(output)
		return 0
	
	# Default: list slots
	editor.list_slots()
	return 0


if __name__ == '__main__':
	exit(main())
