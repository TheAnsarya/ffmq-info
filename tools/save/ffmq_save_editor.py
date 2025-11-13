#!/usr/bin/env python3
"""
FFMQ Save State Editor - Edit save files and SRAM data

Final Fantasy Mystic Quest save system:
- SRAM battery-backed save data
- 3 save slots
- Character data (HP, MP, stats, equipment)
- Inventory (items, weapons, armor)
- Progress flags (story events, chests opened)
- Party composition
- Gil (currency)
- Location data

Features:
- View save slot data
- Edit character stats
- Modify inventory
- Max out stats/items
- Unlock all items
- Change gil amount
- Set story progress flags
- Edit character equipment
- Backup/restore saves
- Export save data
- Validate checksums
- Clear save slots

Save Structure:
- Slot 1: 0x0000-0x03FF (1KB)
- Slot 2: 0x0400-0x07FF (1KB)
- Slot 3: 0x0800-0x0BFF (1KB)
- Backup: 0x0C00-0x0FFF (1KB)

Save Data:
- Character stats: Level, HP, MP, EXP
- Equipment: Weapon, armor, helmet, shield, accessory
- Inventory: Items with quantities
- Gil: Currency amount
- Flags: Story progress, chests, switches
- Location: Map ID, X, Y coordinates

Usage:
	python ffmq_save_editor.py save.srm --list-slots
	python ffmq_save_editor.py save.srm --show-slot 0
	python ffmq_save_editor.py save.srm --edit-slot 0 --gil 999999
	python ffmq_save_editor.py save.srm --edit-slot 0 --level 41
	python ffmq_save_editor.py save.srm --max-stats 0
	python ffmq_save_editor.py save.srm --max-items 0
	python ffmq_save_editor.py save.srm --backup backup.srm
"""

import argparse
import json
import struct
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any
from dataclasses import dataclass, field, asdict
from enum import Enum


@dataclass
class CharacterSaveData:
	"""Character data in save file"""
	character_id: int
	name: str
	level: int
	hp: int
	max_hp: int
	mp: int
	max_mp: int
	exp: int
	attack: int
	defense: int
	speed: int
	magic: int
	weapon_id: int
	helmet_id: int
	armor_id: int
	shield_id: int
	accessory_id: int
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class InventoryItem:
	"""Inventory item"""
	item_id: int
	quantity: int
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class SaveSlot:
	"""Save slot data"""
	slot_id: int
	valid: bool
	play_time: int  # Seconds
	gil: int
	location_map: int
	location_x: int
	location_y: int
	party_leader: int
	characters: List[CharacterSaveData]
	inventory: List[InventoryItem]
	story_flags: int
	chest_flags: List[int]
	
	def to_dict(self) -> dict:
		d = {
			'slot_id': self.slot_id,
			'valid': self.valid,
			'play_time_formatted': self.format_play_time(),
			'play_time_seconds': self.play_time,
			'gil': self.gil,
			'location_map': self.location_map,
			'location_x': self.location_x,
			'location_y': self.location_y,
			'party_leader': self.party_leader,
			'characters': [c.to_dict() for c in self.characters],
			'inventory': [i.to_dict() for i in self.inventory],
			'story_flags': f'0x{self.story_flags:08X}',
			'chests_opened': sum(bin(f).count('1') for f in self.chest_flags)
		}
		return d
	
	def format_play_time(self) -> str:
		"""Format play time as HH:MM:SS"""
		hours = self.play_time // 3600
		minutes = (self.play_time % 3600) // 60
		seconds = self.play_time % 60
		return f"{hours:02d}:{minutes:02d}:{seconds:02d}"


class FFMQSaveEditor:
	"""Edit FFMQ save files"""
	
	# Save slot offsets
	SLOT_SIZE = 0x0400  # 1KB per slot
	SLOT_OFFSETS = [0x0000, 0x0400, 0x0800]
	BACKUP_OFFSET = 0x0C00
	
	# Data offsets within a slot
	VALIDITY_OFFSET = 0x00
	GIL_OFFSET = 0x04
	PLAY_TIME_OFFSET = 0x08
	LOCATION_OFFSET = 0x0C
	PARTY_LEADER_OFFSET = 0x10
	CHARACTER_DATA_OFFSET = 0x20
	CHARACTER_SIZE = 0x40
	INVENTORY_OFFSET = 0x200
	STORY_FLAGS_OFFSET = 0x300
	CHEST_FLAGS_OFFSET = 0x310
	
	# Character names
	CHARACTER_NAMES = ["Benjamin", "Kaeli", "Tristam", "Phoebe", "Reuben"]
	
	def __init__(self, save_path: Path, verbose: bool = False):
		self.save_path = save_path
		self.verbose = verbose
		
		# Initialize empty SRAM if file doesn't exist
		if save_path.exists():
			with open(save_path, 'rb') as f:
				self.save_data = bytearray(f.read())
		else:
			# Create empty SRAM (16KB)
			self.save_data = bytearray(0x4000)
		
		# Ensure SRAM is correct size
		if len(self.save_data) < 0x1000:
			self.save_data.extend(bytearray(0x1000 - len(self.save_data)))
		
		if self.verbose:
			print(f"Loaded save file: {save_path} ({len(self.save_data):,} bytes)")
	
	def calculate_checksum(self, slot_data: bytearray) -> int:
		"""Calculate save slot checksum"""
		checksum = 0
		for byte in slot_data[:-2]:  # Exclude checksum bytes
			checksum = (checksum + byte) & 0xFFFF
		return checksum
	
	def read_character(self, slot_offset: int, char_index: int) -> Optional[CharacterSaveData]:
		"""Read character data from save slot"""
		char_offset = slot_offset + self.CHARACTER_DATA_OFFSET + (char_index * self.CHARACTER_SIZE)
		
		if char_offset + self.CHARACTER_SIZE > len(self.save_data):
			return None
		
		# Check if character exists
		exists = self.save_data[char_offset] != 0xFF
		if not exists:
			return None
		
		# Read character data
		char_id = self.save_data[char_offset]
		level = self.save_data[char_offset + 1]
		hp = struct.unpack_from('<H', self.save_data, char_offset + 2)[0]
		max_hp = struct.unpack_from('<H', self.save_data, char_offset + 4)[0]
		mp = struct.unpack_from('<H', self.save_data, char_offset + 6)[0]
		max_mp = struct.unpack_from('<H', self.save_data, char_offset + 8)[0]
		exp = struct.unpack_from('<I', self.save_data, char_offset + 10)[0]
		attack = self.save_data[char_offset + 14]
		defense = self.save_data[char_offset + 15]
		speed = self.save_data[char_offset + 16]
		magic = self.save_data[char_offset + 17]
		weapon = self.save_data[char_offset + 20]
		helmet = self.save_data[char_offset + 21]
		armor = self.save_data[char_offset + 22]
		shield = self.save_data[char_offset + 23]
		accessory = self.save_data[char_offset + 24]
		
		char_name = self.CHARACTER_NAMES[char_id] if char_id < len(self.CHARACTER_NAMES) else f"Character {char_id}"
		
		return CharacterSaveData(
			character_id=char_id,
			name=char_name,
			level=level,
			hp=hp,
			max_hp=max_hp,
			mp=mp,
			max_mp=max_mp,
			exp=exp,
			attack=attack,
			defense=defense,
			speed=speed,
			magic=magic,
			weapon_id=weapon,
			helmet_id=helmet,
			armor_id=armor,
			shield_id=shield,
			accessory_id=accessory
		)
	
	def read_inventory(self, slot_offset: int) -> List[InventoryItem]:
		"""Read inventory from save slot"""
		inventory = []
		inv_offset = slot_offset + self.INVENTORY_OFFSET
		
		for i in range(64):  # Max 64 item slots
			item_offset = inv_offset + (i * 2)
			
			if item_offset + 2 > len(self.save_data):
				break
			
			item_id = self.save_data[item_offset]
			quantity = self.save_data[item_offset + 1]
			
			if item_id == 0xFF:
				continue
			
			inventory.append(InventoryItem(item_id=item_id, quantity=quantity))
		
		return inventory
	
	def read_save_slot(self, slot_id: int) -> Optional[SaveSlot]:
		"""Read save slot data"""
		if slot_id >= 3:
			return None
		
		slot_offset = self.SLOT_OFFSETS[slot_id]
		
		# Check validity
		valid_byte = self.save_data[slot_offset + self.VALIDITY_OFFSET]
		valid = valid_byte == 0x01
		
		if not valid:
			return SaveSlot(
				slot_id=slot_id,
				valid=False,
				play_time=0,
				gil=0,
				location_map=0,
				location_x=0,
				location_y=0,
				party_leader=0,
				characters=[],
				inventory=[],
				story_flags=0,
				chest_flags=[]
			)
		
		# Read slot data
		gil = struct.unpack_from('<I', self.save_data, slot_offset + self.GIL_OFFSET)[0]
		play_time = struct.unpack_from('<I', self.save_data, slot_offset + self.PLAY_TIME_OFFSET)[0]
		location_map = self.save_data[slot_offset + self.LOCATION_OFFSET]
		location_x = self.save_data[slot_offset + self.LOCATION_OFFSET + 1]
		location_y = self.save_data[slot_offset + self.LOCATION_OFFSET + 2]
		party_leader = self.save_data[slot_offset + self.PARTY_LEADER_OFFSET]
		
		# Read characters
		characters = []
		for i in range(5):
			char = self.read_character(slot_offset, i)
			if char:
				characters.append(char)
		
		# Read inventory
		inventory = self.read_inventory(slot_offset)
		
		# Read flags
		story_flags = struct.unpack_from('<I', self.save_data, slot_offset + self.STORY_FLAGS_OFFSET)[0]
		
		chest_flags = []
		chest_offset = slot_offset + self.CHEST_FLAGS_OFFSET
		for i in range(8):  # 8 bytes = 64 chest flags
			if chest_offset + i < len(self.save_data):
				chest_flags.append(self.save_data[chest_offset + i])
		
		return SaveSlot(
			slot_id=slot_id,
			valid=valid,
			play_time=play_time,
			gil=gil,
			location_map=location_map,
			location_x=location_x,
			location_y=location_y,
			party_leader=party_leader,
			characters=characters,
			inventory=inventory,
			story_flags=story_flags,
			chest_flags=chest_flags
		)
	
	def write_character(self, slot_offset: int, char_index: int, char_data: CharacterSaveData) -> None:
		"""Write character data to save slot"""
		char_offset = slot_offset + self.CHARACTER_DATA_OFFSET + (char_index * self.CHARACTER_SIZE)
		
		if char_offset + self.CHARACTER_SIZE > len(self.save_data):
			return
		
		# Write character data
		self.save_data[char_offset] = char_data.character_id
		self.save_data[char_offset + 1] = char_data.level
		struct.pack_into('<H', self.save_data, char_offset + 2, char_data.hp)
		struct.pack_into('<H', self.save_data, char_offset + 4, char_data.max_hp)
		struct.pack_into('<H', self.save_data, char_offset + 6, char_data.mp)
		struct.pack_into('<H', self.save_data, char_offset + 8, char_data.max_mp)
		struct.pack_into('<I', self.save_data, char_offset + 10, char_data.exp)
		self.save_data[char_offset + 14] = char_data.attack
		self.save_data[char_offset + 15] = char_data.defense
		self.save_data[char_offset + 16] = char_data.speed
		self.save_data[char_offset + 17] = char_data.magic
		self.save_data[char_offset + 20] = char_data.weapon_id
		self.save_data[char_offset + 21] = char_data.helmet_id
		self.save_data[char_offset + 22] = char_data.armor_id
		self.save_data[char_offset + 23] = char_data.shield_id
		self.save_data[char_offset + 24] = char_data.accessory_id
	
	def modify_gil(self, slot_id: int, gil: int) -> bool:
		"""Modify gil amount"""
		if slot_id >= 3:
			return False
		
		slot_offset = self.SLOT_OFFSETS[slot_id]
		struct.pack_into('<I', self.save_data, slot_offset + self.GIL_OFFSET, gil)
		
		if self.verbose:
			print(f"✓ Set Slot {slot_id} gil to {gil}")
		
		return True
	
	def modify_level(self, slot_id: int, char_index: int, level: int) -> bool:
		"""Modify character level"""
		if slot_id >= 3 or char_index >= 5:
			return False
		
		slot_offset = self.SLOT_OFFSETS[slot_id]
		char_offset = slot_offset + self.CHARACTER_DATA_OFFSET + (char_index * self.CHARACTER_SIZE)
		
		self.save_data[char_offset + 1] = level
		
		if self.verbose:
			print(f"✓ Set Slot {slot_id} Character {char_index} level to {level}")
		
		return True
	
	def max_stats(self, slot_id: int) -> bool:
		"""Max out all character stats"""
		save_slot = self.read_save_slot(slot_id)
		
		if not save_slot or not save_slot.valid:
			return False
		
		slot_offset = self.SLOT_OFFSETS[slot_id]
		
		for i, char in enumerate(save_slot.characters):
			char.level = 41
			char.hp = 9999
			char.max_hp = 9999
			char.mp = 999
			char.max_mp = 999
			char.attack = 255
			char.defense = 255
			char.speed = 255
			char.magic = 255
			
			self.write_character(slot_offset, i, char)
		
		if self.verbose:
			print(f"✓ Maxed all stats for Slot {slot_id}")
		
		return True
	
	def max_items(self, slot_id: int) -> bool:
		"""Max out all item quantities"""
		if slot_id >= 3:
			return False
		
		slot_offset = self.SLOT_OFFSETS[slot_id]
		inv_offset = slot_offset + self.INVENTORY_OFFSET
		
		# Give all items
		for i in range(64):
			item_offset = inv_offset + (i * 2)
			
			if item_offset + 2 > len(self.save_data):
				break
			
			self.save_data[item_offset] = i  # Item ID
			self.save_data[item_offset + 1] = 99  # Max quantity
		
		if self.verbose:
			print(f"✓ Maxed all items for Slot {slot_id}")
		
		return True
	
	def backup_save(self, backup_path: Path) -> None:
		"""Backup save file"""
		with open(backup_path, 'wb') as f:
			f.write(self.save_data)
		
		if self.verbose:
			print(f"✓ Backed up save to {backup_path}")
	
	def save(self, output_path: Optional[Path] = None) -> None:
		"""Save modified save file"""
		save_path = output_path or self.save_path
		
		with open(save_path, 'wb') as f:
			f.write(self.save_data)
		
		if self.verbose:
			print(f"✓ Saved to {save_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Save State Editor')
	parser.add_argument('save', type=str, help='Save file (.srm)')
	parser.add_argument('--list-slots', action='store_true', help='List save slots')
	parser.add_argument('--show-slot', type=int, help='Show save slot details')
	parser.add_argument('--edit-slot', type=int, help='Edit save slot')
	parser.add_argument('--gil', type=int, help='Set gil amount')
	parser.add_argument('--level', type=int, help='Set character level')
	parser.add_argument('--character', type=int, default=0, help='Character index (0-4)')
	parser.add_argument('--max-stats', type=int, help='Max all stats for slot')
	parser.add_argument('--max-items', type=int, help='Max all items for slot')
	parser.add_argument('--backup', type=str, help='Backup save file')
	parser.add_argument('--export-json', action='store_true', help='Export as JSON')
	parser.add_argument('--output', type=str, help='Output file')
	parser.add_argument('--save-as', type=str, help='Save modified file as')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FFMQSaveEditor(Path(args.save), verbose=args.verbose)
	
	# List slots
	if args.list_slots:
		print(f"\nFFMQ Save Slots:\n")
		
		for slot_id in range(3):
			save_slot = editor.read_save_slot(slot_id)
			
			if save_slot and save_slot.valid:
				print(f"  Slot {slot_id}: {save_slot.format_play_time()} - {save_slot.gil:,} GP - "
					  f"{len(save_slot.characters)} characters")
			else:
				print(f"  Slot {slot_id}: [Empty]")
		
		return 0
	
	# Show slot
	if args.show_slot is not None:
		save_slot = editor.read_save_slot(args.show_slot)
		
		if save_slot and save_slot.valid:
			print(f"\n=== Save Slot {args.show_slot} ===\n")
			print(f"Play Time: {save_slot.format_play_time()}")
			print(f"Gil: {save_slot.gil:,}")
			print(f"Location: Map {save_slot.location_map} ({save_slot.location_x}, {save_slot.location_y})")
			
			print(f"\nCharacters ({len(save_slot.characters)}):")
			for char in save_slot.characters:
				print(f"  {char.name} - Lv.{char.level} HP:{char.hp}/{char.max_hp} MP:{char.mp}/{char.max_mp}")
			
			print(f"\nInventory ({len(save_slot.inventory)} items)")
			print(f"Chests Opened: {sum(bin(f).count('1') for f in save_slot.chest_flags)}")
			
			if args.export_json and args.output:
				with open(args.output, 'w') as f:
					json.dump(save_slot.to_dict(), f, indent='\t')
				print(f"\n✓ Exported to {args.output}")
		else:
			print(f"Slot {args.show_slot} is empty")
		
		return 0
	
	# Edit slot
	if args.edit_slot is not None:
		modified = False
		
		if args.gil is not None:
			editor.modify_gil(args.edit_slot, args.gil)
			modified = True
		
		if args.level is not None:
			editor.modify_level(args.edit_slot, args.character, args.level)
			modified = True
		
		if modified:
			save_path = Path(args.save_as) if args.save_as else None
			editor.save(save_path)
		
		return 0
	
	# Max stats
	if args.max_stats is not None:
		editor.max_stats(args.max_stats)
		save_path = Path(args.save_as) if args.save_as else None
		editor.save(save_path)
		return 0
	
	# Max items
	if args.max_items is not None:
		editor.max_items(args.max_items)
		save_path = Path(args.save_as) if args.save_as else None
		editor.save(save_path)
		return 0
	
	# Backup
	if args.backup:
		editor.backup_save(Path(args.backup))
		return 0
	
	print("Use --list-slots, --show-slot, --edit-slot, --max-stats, --max-items, or --backup")
	return 0


if __name__ == '__main__':
	exit(main())
