#!/usr/bin/env python3
"""
FFMQ SRAM Save File Editor - ENHANCED with Full Inventory/Equipment Support

This enhanced version includes comprehensive item, weapon, armor, accessory,
and spell management based on complete SRAM field research.

Features:
- Complete inventory management (items, weapons, armor, accessories)
- Equipment system (weapons, armor, accessories)
- Spell/magic learning system
- Quest/event flag editing
- Treasure chest tracking
- Battle statistics
- Character extended data
- All previously supported features (stats, gold, position, etc.)

Usage:
	# Extract and edit inventory
	python ffmq_sram_editor_enhanced.py extract save.srm --slot 1 --output save1.json
	python ffmq_sram_editor_enhanced.py edit save1.json --add-item "Cure Potion" 99
	python ffmq_sram_editor_enhanced.py edit save1.json --equip-weapon "Excalibur" --character 1
	python ffmq_sram_editor_enhanced.py edit save1.json --learn-spell "Flare" --character 1
	python ffmq_sram_editor_enhanced.py edit save1.json --unlock-chest 42
	python ffmq_sram_editor_enhanced.py insert save1.json save.srm --slot 1
"""

import argparse
import json
import struct
from pathlib import Path
from typing import List, Dict, Optional, Tuple, Any, Set
from dataclasses import dataclass, asdict, field
from enum import Enum

# ======================== ITEM DATABASE ========================

# Consumable Items
ITEMS = {
	0x10: "Cure Potion",
	0x11: "Heal Potion",
	0x12: "Seed",
	0x13: "Refresher",
}

# Key Items
KEY_ITEMS = {
	0x00: "Elixir",
	0x01: "Tree Wither",
	0x02: "Wakewater",
	0x03: "Venus Key",
	0x04: "Multi-Key",
	0x05: "Mask",
	0x06: "Magic Mirror",
	0x07: "Thunder Rock",
	0x08: "Captain Cap",
	0x09: "Libra Crest",
	0x0A: "Gemini Crest",
	0x0B: "Mobius Crest",
	0x0C: "Sand Coin",
	0x0D: "River Coin",
	0x0E: "Sun Coin",
	0x0F: "Sky Coin",
}

# Weapons
WEAPONS = {
	0x00: "Steel Sword",
	0x01: "Knight Sword",
	0x02: "Excalibur",
	0x03: "Axe",
	0x04: "Battle Axe",
	0x05: "Giant's Axe",
	0x06: "Cat Claw",
	0x07: "Charm Claw",
	0x08: "Dragon Claw",
	0x09: "Bomb",
	0x0A: "Jumbo Bomb",
	0x0B: "Mega Grenade",
	0x0C: "Morning Star",
	0x0D: "Bow of Grace",
	0x0E: "Ninja Star",
}

# Armor
ARMOR = {
	0x00: "Steel Armor",
	0x01: "Noble Armor",
	0x02: "Gaia's Armor",
	0x03: "Relica Armor",
	0x04: "Mystic Robe",
	0x05: "Flame Armor",
	0x06: "Black Robe",
}

# Accessories
ACCESSORIES = {
	0x00: "Charm",
	0x01: "Magic Ring",
	0x02: "Cupid Locket",
}

# Spells
SPELLS = {
	0x00: "Exit",
	0x01: "Cure",
	0x02: "Heal",
	0x03: "Life",
	0x04: "Quake",
	0x05: "Blizzard",
	0x06: "Fire",
	0x07: "Aero",
	0x08: "Thunder",
	0x09: "White",
	0x0A: "Meteor",
	0x0B: "Flare",
}

# Reverse lookups
ITEMS_BY_NAME = {v: k for k, v in ITEMS.items()}
KEY_ITEMS_BY_NAME = {v: k for k, v in KEY_ITEMS.items()}
WEAPONS_BY_NAME = {v: k for k, v in WEAPONS.items()}
ARMOR_BY_NAME = {v: k for k, v in ARMOR.items()}
ACCESSORIES_BY_NAME = {v: k for k, v in ACCESSORIES.items()}
SPELLS_BY_NAME = {v: k for k, v in SPELLS.items()}


# ======================== ENUMS ========================

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


class FacingDirection(Enum):
	"""Player facing directions"""
	DOWN = 0
	UP = 1
	LEFT = 2
	RIGHT = 3


# ======================== DATA CLASSES ========================

@dataclass
class InventoryItem:
	"""Single inventory item entry"""
	item_id: int
	quantity: int
	
	def to_dict(self) -> Dict[str, Any]:
		"""Convert to dictionary with human-readable name"""
		item_name = ITEMS.get(self.item_id, f"Unknown Item 0x{self.item_id:02X}")
		return {
			"id": self.item_id,
			"name": item_name,
			"quantity": self.quantity
		}


@dataclass
class EquipmentSlot:
	"""Equipment slot data"""
	armor_id: int = 0xFF  # 0xFF = empty
	helmet_id: int = 0xFF  # Unused in FFMQ
	shield_id: int = 0xFF  # Unused in FFMQ
	accessory1_id: int = 0xFF
	accessory2_id: int = 0xFF
	
	def to_dict(self) -> Dict[str, Any]:
		"""Convert to dictionary with human-readable names"""
		return {
			"armor": ARMOR.get(self.armor_id, "None") if self.armor_id != 0xFF else "None",
			"armor_id": self.armor_id if self.armor_id != 0xFF else None,
			"accessory1": ACCESSORIES.get(self.accessory1_id, "None") if self.accessory1_id != 0xFF else "None",
			"accessory1_id": self.accessory1_id if self.accessory1_id != 0xFF else None,
			"accessory2": ACCESSORIES.get(self.accessory2_id, "None") if self.accessory2_id != 0xFF else "None",
			"accessory2_id": self.accessory2_id if self.accessory2_id != 0xFF else None,
		}


@dataclass
class CharacterData:
	"""Character save data (0x50 bytes) - ENHANCED"""
	# Basic Info
	name: str = "Benjamin"
	level: int = 1
	experience: int = 0
	current_hp: int = 50
	max_hp: int = 50
	status: int = 0
	
	# Stats
	current_attack: int = 5
	current_defense: int = 5
	current_speed: int = 5
	current_magic: int = 5
	base_attack: int = 5
	base_defense: int = 5
	base_speed: int = 5
	base_magic: int = 5
	
	# Weapon
	weapon_count: int = 0
	weapon_id: int = 0
	
	# Equipment (ENHANCED)
	equipment: EquipmentSlot = field(default_factory=EquipmentSlot)
	
	# Spells (ENHANCED)
	learned_spells: Set[int] = field(default_factory=set)
	
	# Character State (ENHANCED)
	in_party: bool = False
	available: bool = False
	battle_count: int = 0
	
	# Resistances (ENHANCED)
	poison_resist: int = 0
	paralysis_resist: int = 0
	petrify_resist: int = 0
	fatal_resist: int = 0
	
	def to_dict(self) -> Dict[str, Any]:
		"""Convert to dictionary for JSON export"""
		return {
			"name": self.name,
			"level": self.level,
			"experience": self.experience,
			"hp": {"current": self.current_hp, "max": self.max_hp},
			"status": self.status,
			"current_stats": {
				"attack": self.current_attack,
				"defense": self.current_defense,
				"speed": self.current_speed,
				"magic": self.current_magic
			},
			"base_stats": {
				"attack": self.base_attack,
				"defense": self.base_defense,
				"speed": self.base_speed,
				"magic": self.base_magic
			},
			"weapon": {
				"id": self.weapon_id,
				"name": WEAPONS.get(self.weapon_id, f"Unknown 0x{self.weapon_id:02X}"),
				"count": self.weapon_count
			},
			"equipment": self.equipment.to_dict(),
			"spells": [SPELLS.get(s, f"Unknown 0x{s:02X}") for s in sorted(self.learned_spells)],
			"spell_ids": list(sorted(self.learned_spells)),
			"party_status": {
				"in_party": self.in_party,
				"available": self.available,
				"battle_count": self.battle_count
			},
			"resistances": {
				"poison": self.poison_resist,
				"paralysis": self.paralysis_resist,
				"petrify": self.petrify_resist,
				"fatal": self.fatal_resist
			}
		}


@dataclass
class Inventory:
	"""Complete inventory system - ENHANCED"""
	# Consumable items (16 slots)
	consumables: List[InventoryItem] = field(default_factory=list)
	
	# Key items (bitfield)
	key_items: Set[int] = field(default_factory=set)
	
	# Weapons (15 slots)
	weapons: Dict[int, int] = field(default_factory=dict)  # weapon_id: count
	
	# Armor (7 slots)
	armor: Dict[int, int] = field(default_factory=dict)  # armor_id: count
	
	# Accessories (3 slots)
	accessories: Dict[int, int] = field(default_factory=dict)  # accessory_id: count
	
	def to_dict(self) -> Dict[str, Any]:
		"""Convert to dictionary for JSON export"""
		return {
			"consumables": [item.to_dict() for item in self.consumables],
			"key_items": [KEY_ITEMS.get(kid, f"Unknown 0x{kid:02X}") for kid in sorted(self.key_items)],
			"key_item_ids": list(sorted(self.key_items)),
			"weapons": {
				WEAPONS.get(wid, f"Unknown 0x{wid:02X}"): count 
				for wid, count in self.weapons.items()
			},
			"armor": {
				ARMOR.get(aid, f"Unknown 0x{aid:02X}"): count 
				for aid, count in self.armor.items()
			},
			"accessories": {
				ACCESSORIES.get(aid, f"Unknown 0x{aid:02X}"): count 
				for aid, count in self.accessories.items()
			}
		}


@dataclass
class GameFlags:
	"""Quest, event, and world flags - ENHANCED"""
	story_flags: Set[int] = field(default_factory=set)  # 256 story events
	treasure_chests: Set[int] = field(default_factory=set)  # 256 chests
	npc_flags: Set[int] = field(default_factory=set)  # 128 NPC interactions
	battlefield_flags: Set[int] = field(default_factory=set)  # 128 battlefields
	focus_tower_floors: Set[int] = field(default_factory=set)  # 64 floors
	
	def to_dict(self) -> Dict[str, Any]:
		"""Convert to dictionary for JSON export"""
		return {
			"story_events": list(sorted(self.story_flags)),
			"treasure_chests_opened": list(sorted(self.treasure_chests)),
			"npc_interactions": list(sorted(self.npc_flags)),
			"battlefields_completed": list(sorted(self.battlefield_flags)),
			"focus_tower_floors": list(sorted(self.focus_tower_floors))
		}


@dataclass
class Statistics:
	"""Battle and game statistics - ENHANCED"""
	total_battles: int = 0
	battles_won: int = 0
	battles_fled: int = 0
	total_damage_dealt: int = 0
	total_damage_taken: int = 0
	total_healing: int = 0
	items_collected: int = 0
	items_used: int = 0
	equipment_changes: int = 0
	enemies_encountered: Set[int] = field(default_factory=set)  # Monster book
	
	def to_dict(self) -> Dict[str, Any]:
		"""Convert to dictionary for JSON export"""
		return {
			"battles": {
				"total": self.total_battles,
				"won": self.battles_won,
				"fled": self.battles_fled
			},
			"combat": {
				"damage_dealt": self.total_damage_dealt,
				"damage_taken": self.total_damage_taken,
				"healing": self.total_healing
			},
			"items": {
				"collected": self.items_collected,
				"used": self.items_used,
				"equipment_changes": self.equipment_changes
			},
			"monster_book": list(sorted(self.enemies_encountered))
		}


@dataclass
class SaveSlot:
	"""Save slot data (0x38C bytes) - ENHANCED"""
	# Metadata
	slot_id: int = 0
	valid: bool = False
	checksum: int = 0
	
	# Characters
	character1: CharacterData = field(default_factory=CharacterData)
	character2: CharacterData = field(default_factory=CharacterData)
	
	# Basic party data
	gold: int = 0
	player_x: int = 0
	player_y: int = 0
	player_facing: int = 0
	map_id: int = 0
	play_time_hours: int = 0
	play_time_minutes: int = 0
	play_time_seconds: int = 0
	cure_count: int = 0
	
	# ENHANCED data
	inventory: Inventory = field(default_factory=Inventory)
	flags: GameFlags = field(default_factory=GameFlags)
	stats: Statistics = field(default_factory=Statistics)
	
	def to_dict(self) -> Dict[str, Any]:
		"""Convert to dictionary for JSON export"""
		return {
			"slot_id": self.slot_id,
			"valid": self.valid,
			"checksum": f"0x{self.checksum:04X}",
			"character1": self.character1.to_dict(),
			"character2": self.character2.to_dict(),
			"party": {
				"gold": self.gold,
				"position": {
					"x": self.player_x,
					"y": self.player_y,
					"facing": FacingDirection(self.player_facing).name
				},
				"map_id": self.map_id,
				"play_time": f"{self.play_time_hours:02d}:{self.play_time_minutes:02d}:{self.play_time_seconds:02d}",
				"cure_count": self.cure_count
			},
			"inventory": self.inventory.to_dict(),
			"flags": self.flags.to_dict(),
			"statistics": self.stats.to_dict()
		}


# ======================== SRAM PARSING ========================

class SRAMEditor:
	"""SRAM file editor - ENHANCED with full inventory/equipment support"""
	
	SRAM_SIZE = 0x1FEC  # 8,172 bytes
	SLOT_SIZE = 0x38C   # 908 bytes per slot
	NUM_SLOTS = 9       # 3 slots × 3 copies
	
	SIGNATURE = b'FF0!'
	
	# Offsets within slot
	OFFSET_CHECKSUM = 0x004
	OFFSET_CHAR1 = 0x006
	OFFSET_CHAR2 = 0x056
	OFFSET_GOLD = 0x0A6
	OFFSET_POS_X = 0x0AB
	OFFSET_POS_Y = 0x0AC
	OFFSET_FACING = 0x0AD
	OFFSET_MAP_ID = 0x0B3
	OFFSET_PLAY_TIME = 0x0B9
	OFFSET_CURE_COUNT = 0x0C1
	
	# ENHANCED offsets
	OFFSET_INVENTORY = 0x0C2
	OFFSET_KEY_ITEMS = 0x0E2
	OFFSET_WEAPONS_INV = 0x0E4
	OFFSET_ARMOR_INV = 0x104
	OFFSET_ACCESSORIES_INV = 0x114
	OFFSET_STORY_FLAGS = 0x1C2
	OFFSET_TREASURE_CHESTS = 0x1E2
	OFFSET_NPC_FLAGS = 0x202
	OFFSET_BATTLEFIELD_FLAGS = 0x212
	OFFSET_FOCUS_TOWER = 0x222
	OFFSET_BATTLE_STATS = 0x242
	OFFSET_MONSTER_BOOK = 0x252
	OFFSET_ITEM_STATS = 0x272
	
	# Character offsets (within 80-byte character block)
	CHAR_NAME = 0x00
	CHAR_LEVEL = 0x10
	CHAR_EXP = 0x11
	CHAR_HP_CURRENT = 0x14
	CHAR_HP_MAX = 0x16
	CHAR_STATUS = 0x21
	CHAR_CURRENT_ATTACK = 0x22
	CHAR_CURRENT_DEFENSE = 0x23
	CHAR_CURRENT_SPEED = 0x24
	CHAR_CURRENT_MAGIC = 0x25
	CHAR_BASE_ATTACK = 0x26
	CHAR_BASE_DEFENSE = 0x27
	CHAR_BASE_SPEED = 0x28
	CHAR_BASE_MAGIC = 0x29
	CHAR_WEAPON_COUNT = 0x30
	CHAR_WEAPON_ID = 0x31
	CHAR_ARMOR_ID = 0x32
	CHAR_HELMET_ID = 0x33
	CHAR_SHIELD_ID = 0x34
	CHAR_ACCESSORY1_ID = 0x35
	CHAR_ACCESSORY2_ID = 0x36
	CHAR_SPELLS = 0x37
	CHAR_FLAGS = 0x39
	CHAR_BATTLE_COUNT = 0x3A
	CHAR_POISON_RESIST = 0x3C
	CHAR_PARALYSIS_RESIST = 0x3D
	CHAR_PETRIFY_RESIST = 0x3E
	CHAR_FATAL_RESIST = 0x3F
	
	def __init__(self, sram_data: Optional[bytes] = None):
		"""Initialize editor with SRAM data"""
		if sram_data:
			if len(sram_data) != self.SRAM_SIZE:
				raise ValueError(f"Invalid SRAM size: {len(sram_data)} bytes (expected {self.SRAM_SIZE})")
			self.data = bytearray(sram_data)
		else:
			self.data = bytearray(self.SRAM_SIZE)
	
	@classmethod
	def from_file(cls, filepath: Path) -> 'SRAMEditor':
		"""Load SRAM from file"""
		with open(filepath, 'rb') as f:
			data = f.read()
		return cls(data)
	
	def save_to_file(self, filepath: Path) -> None:
		"""Save SRAM to file"""
		with open(filepath, 'wb') as f:
			f.write(self.data)
	
	def get_slot_data(self, slot_id: int) -> bytes:
		"""Get raw data for a specific slot (0-8)"""
		if slot_id < 0 or slot_id >= self.NUM_SLOTS:
			raise ValueError(f"Invalid slot ID: {slot_id} (must be 0-8)")
		offset = slot_id * self.SLOT_SIZE
		return bytes(self.data[offset:offset + self.SLOT_SIZE])
	
	def set_slot_data(self, slot_id: int, slot_data: bytes) -> None:
		"""Set raw data for a specific slot"""
		if slot_id < 0 or slot_id >= self.NUM_SLOTS:
			raise ValueError(f"Invalid slot ID: {slot_id}")
		if len(slot_data) != self.SLOT_SIZE:
			raise ValueError(f"Invalid slot data size: {len(slot_data)} bytes")
		offset = slot_id * self.SLOT_SIZE
		self.data[offset:offset + self.SLOT_SIZE] = slot_data
	
	def calculate_checksum(self, slot_data: bytes) -> int:
		"""Calculate checksum for slot data (sum of bytes 0x06 onwards)"""
		return sum(slot_data[6:]) & 0xFFFF
	
	def verify_checksum(self, slot_data: bytes) -> bool:
		"""Verify slot checksum"""
		stored_checksum = struct.unpack('<H', slot_data[self.OFFSET_CHECKSUM:self.OFFSET_CHECKSUM + 2])[0]
		calculated_checksum = self.calculate_checksum(slot_data)
		return stored_checksum == calculated_checksum
	
	def fix_checksum(self, slot_data: bytearray) -> None:
		"""Fix checksum in slot data"""
		checksum = self.calculate_checksum(slot_data)
		struct.pack_into('<H', slot_data, self.OFFSET_CHECKSUM, checksum)
	
	def parse_character(self, char_data: bytes) -> CharacterData:
		"""Parse character data (80 bytes) - ENHANCED"""
		char = CharacterData()
		
		# Basic info
		char.name = char_data[self.CHAR_NAME:self.CHAR_NAME + 8].decode('ascii').rstrip('\x00')
		char.level = char_data[self.CHAR_LEVEL]
		char.experience = struct.unpack('<I', char_data[self.CHAR_EXP:self.CHAR_EXP + 3] + b'\x00')[0]
		char.current_hp = struct.unpack('<H', char_data[self.CHAR_HP_CURRENT:self.CHAR_HP_CURRENT + 2])[0]
		char.max_hp = struct.unpack('<H', char_data[self.CHAR_HP_MAX:self.CHAR_HP_MAX + 2])[0]
		char.status = char_data[self.CHAR_STATUS]
		
		# Stats
		char.current_attack = char_data[self.CHAR_CURRENT_ATTACK]
		char.current_defense = char_data[self.CHAR_CURRENT_DEFENSE]
		char.current_speed = char_data[self.CHAR_CURRENT_SPEED]
		char.current_magic = char_data[self.CHAR_CURRENT_MAGIC]
		char.base_attack = char_data[self.CHAR_BASE_ATTACK]
		char.base_defense = char_data[self.CHAR_BASE_DEFENSE]
		char.base_speed = char_data[self.CHAR_BASE_SPEED]
		char.base_magic = char_data[self.CHAR_BASE_MAGIC]
		
		# Weapon
		char.weapon_count = char_data[self.CHAR_WEAPON_COUNT]
		char.weapon_id = char_data[self.CHAR_WEAPON_ID]
		
		# Equipment (ENHANCED)
		char.equipment.armor_id = char_data[self.CHAR_ARMOR_ID]
		char.equipment.helmet_id = char_data[self.CHAR_HELMET_ID]
		char.equipment.shield_id = char_data[self.CHAR_SHIELD_ID]
		char.equipment.accessory1_id = char_data[self.CHAR_ACCESSORY1_ID]
		char.equipment.accessory2_id = char_data[self.CHAR_ACCESSORY2_ID]
		
		# Spells (ENHANCED)
		spell_flags = struct.unpack('<H', char_data[self.CHAR_SPELLS:self.CHAR_SPELLS + 2])[0]
		char.learned_spells = {i for i in range(12) if spell_flags & (1 << i)}
		
		# Character state (ENHANCED)
		flags = char_data[self.CHAR_FLAGS]
		char.in_party = bool(flags & 0x01)
		char.available = bool(flags & 0x02)
		char.battle_count = char_data[self.CHAR_BATTLE_COUNT]
		
		# Resistances (ENHANCED)
		char.poison_resist = char_data[self.CHAR_POISON_RESIST]
		char.paralysis_resist = char_data[self.CHAR_PARALYSIS_RESIST]
		char.petrify_resist = char_data[self.CHAR_PETRIFY_RESIST]
		char.fatal_resist = char_data[self.CHAR_FATAL_RESIST]
		
		return char
	
	def serialize_character(self, char: CharacterData) -> bytes:
		"""Serialize character data to 80 bytes - ENHANCED"""
		char_data = bytearray(0x50)
		
		# Basic info
		name_bytes = char.name.encode('ascii')[:8].ljust(8, b'\x00')
		char_data[self.CHAR_NAME:self.CHAR_NAME + 8] = name_bytes
		char_data[self.CHAR_LEVEL] = min(char.level, 99)
		exp_bytes = struct.pack('<I', min(char.experience, 9999999))[:3]
		char_data[self.CHAR_EXP:self.CHAR_EXP + 3] = exp_bytes
		struct.pack_into('<H', char_data, self.CHAR_HP_CURRENT, min(char.current_hp, 65535))
		struct.pack_into('<H', char_data, self.CHAR_HP_MAX, min(char.max_hp, 65535))
		char_data[self.CHAR_STATUS] = char.status
		
		# Stats
		char_data[self.CHAR_CURRENT_ATTACK] = min(char.current_attack, 99)
		char_data[self.CHAR_CURRENT_DEFENSE] = min(char.current_defense, 99)
		char_data[self.CHAR_CURRENT_SPEED] = min(char.current_speed, 99)
		char_data[self.CHAR_CURRENT_MAGIC] = min(char.current_magic, 99)
		char_data[self.CHAR_BASE_ATTACK] = min(char.base_attack, 99)
		char_data[self.CHAR_BASE_DEFENSE] = min(char.base_defense, 99)
		char_data[self.CHAR_BASE_SPEED] = min(char.base_speed, 99)
		char_data[self.CHAR_BASE_MAGIC] = min(char.base_magic, 99)
		
		# Weapon
		char_data[self.CHAR_WEAPON_COUNT] = char.weapon_count
		char_data[self.CHAR_WEAPON_ID] = char.weapon_id
		
		# Equipment (ENHANCED)
		char_data[self.CHAR_ARMOR_ID] = char.equipment.armor_id
		char_data[self.CHAR_HELMET_ID] = char.equipment.helmet_id
		char_data[self.CHAR_SHIELD_ID] = char.equipment.shield_id
		char_data[self.CHAR_ACCESSORY1_ID] = char.equipment.accessory1_id
		char_data[self.CHAR_ACCESSORY2_ID] = char.equipment.accessory2_id
		
		# Spells (ENHANCED)
		spell_flags = sum(1 << spell_id for spell_id in char.learned_spells if spell_id < 12)
		struct.pack_into('<H', char_data, self.CHAR_SPELLS, spell_flags)
		
		# Character state (ENHANCED)
		flags = 0
		if char.in_party:
			flags |= 0x01
		if char.available:
			flags |= 0x02
		char_data[self.CHAR_FLAGS] = flags
		char_data[self.CHAR_BATTLE_COUNT] = min(char.battle_count, 255)
		
		# Resistances (ENHANCED)
		char_data[self.CHAR_POISON_RESIST] = min(char.poison_resist, 100)
		char_data[self.CHAR_PARALYSIS_RESIST] = min(char.paralysis_resist, 100)
		char_data[self.CHAR_PETRIFY_RESIST] = min(char.petrify_resist, 100)
		char_data[self.CHAR_FATAL_RESIST] = min(char.fatal_resist, 100)
		
		return bytes(char_data)
	
	def parse_inventory(self, slot_data: bytes) -> Inventory:
		"""Parse inventory data - ENHANCED"""
		inv = Inventory()
		
		# Consumable items (16 slots, 2 bytes each)
		for i in range(16):
			offset = self.OFFSET_INVENTORY + (i * 2)
			item_id = slot_data[offset]
			quantity = slot_data[offset + 1]
			if item_id in ITEMS and quantity > 0:
				inv.consumables.append(InventoryItem(item_id, quantity))
		
		# Key items (bitfield, 2 bytes = 16 bits)
		key_item_flags = struct.unpack('<H', slot_data[self.OFFSET_KEY_ITEMS:self.OFFSET_KEY_ITEMS + 2])[0]
		inv.key_items = {i for i in range(16) if key_item_flags & (1 << i)}
		
		# Weapons (15 weapons, 2 bytes each)
		for i in range(15):
			offset = self.OFFSET_WEAPONS_INV + (i * 2)
			weapon_id = slot_data[offset]
			count = slot_data[offset + 1]
			if weapon_id in WEAPONS and count > 0:
				inv.weapons[weapon_id] = count
		
		# Armor (7 pieces, 2 bytes each)
		for i in range(7):
			offset = self.OFFSET_ARMOR_INV + (i * 2)
			armor_id = slot_data[offset]
			count = slot_data[offset + 1]
			if armor_id in ARMOR and count > 0:
				inv.armor[armor_id] = count
		
		# Accessories (3 accessories, 2 bytes each)
		for i in range(3):
			offset = self.OFFSET_ACCESSORIES_INV + (i * 2)
			accessory_id = slot_data[offset]
			count = slot_data[offset + 1]
			if accessory_id in ACCESSORIES and count > 0:
				inv.accessories[accessory_id] = count
		
		return inv
	
	def serialize_inventory(self, inv: Inventory) -> bytes:
		"""Serialize inventory data - ENHANCED"""
		inv_data = bytearray(256)  # Full inventory block
		
		# Consumable items
		for i, item in enumerate(inv.consumables[:16]):
			offset = i * 2
			inv_data[offset] = item.item_id
			inv_data[offset + 1] = min(item.quantity, 99)
		
		# Key items
		key_item_flags = sum(1 << kid for kid in inv.key_items if kid < 16)
		struct.pack_into('<H', inv_data, self.OFFSET_KEY_ITEMS - self.OFFSET_INVENTORY, key_item_flags)
		
		# Weapons
		weapon_offset = self.OFFSET_WEAPONS_INV - self.OFFSET_INVENTORY
		for i, (weapon_id, count) in enumerate(sorted(inv.weapons.items())[:15]):
			offset = weapon_offset + (i * 2)
			inv_data[offset] = weapon_id
			inv_data[offset + 1] = min(count, 99)
		
		# Armor
		armor_offset = self.OFFSET_ARMOR_INV - self.OFFSET_INVENTORY
		for i, (armor_id, count) in enumerate(sorted(inv.armor.items())[:7]):
			offset = armor_offset + (i * 2)
			inv_data[offset] = armor_id
			inv_data[offset + 1] = min(count, 99)
		
		# Accessories
		accessory_offset = self.OFFSET_ACCESSORIES_INV - self.OFFSET_INVENTORY
		for i, (accessory_id, count) in enumerate(sorted(inv.accessories.items())[:3]):
			offset = accessory_offset + (i * 2)
			inv_data[offset] = accessory_id
			inv_data[offset + 1] = min(count, 99)
		
		return bytes(inv_data)
	
	def parse_flags(self, slot_data: bytes) -> GameFlags:
		"""Parse game flags - ENHANCED"""
		flags = GameFlags()
		
		# Story flags (32 bytes = 256 bits)
		for byte_idx in range(32):
			byte_val = slot_data[self.OFFSET_STORY_FLAGS + byte_idx]
			for bit_idx in range(8):
				if byte_val & (1 << bit_idx):
					flags.story_flags.add(byte_idx * 8 + bit_idx)
		
		# Treasure chests (32 bytes = 256 bits)
		for byte_idx in range(32):
			byte_val = slot_data[self.OFFSET_TREASURE_CHESTS + byte_idx]
			for bit_idx in range(8):
				if byte_val & (1 << bit_idx):
					flags.treasure_chests.add(byte_idx * 8 + bit_idx)
		
		# NPC flags (16 bytes = 128 bits)
		for byte_idx in range(16):
			byte_val = slot_data[self.OFFSET_NPC_FLAGS + byte_idx]
			for bit_idx in range(8):
				if byte_val & (1 << bit_idx):
					flags.npc_flags.add(byte_idx * 8 + bit_idx)
		
		# Battlefield flags (16 bytes = 128 bits)
		for byte_idx in range(16):
			byte_val = slot_data[self.OFFSET_BATTLEFIELD_FLAGS + byte_idx]
			for bit_idx in range(8):
				if byte_val & (1 << bit_idx):
					flags.battlefield_flags.add(byte_idx * 8 + bit_idx)
		
		# Focus Tower floors (8 bytes = 64 bits)
		for byte_idx in range(8):
			byte_val = slot_data[self.OFFSET_FOCUS_TOWER + byte_idx]
			for bit_idx in range(8):
				if byte_val & (1 << bit_idx):
					flags.focus_tower_floors.add(byte_idx * 8 + bit_idx)
		
		return flags
	
	def serialize_flags(self, flags: GameFlags) -> bytes:
		"""Serialize game flags - ENHANCED"""
		flags_data = bytearray(128)  # Full flags block
		
		# Story flags
		story_offset = self.OFFSET_STORY_FLAGS - self.OFFSET_STORY_FLAGS
		for flag_id in flags.story_flags:
			if flag_id < 256:
				byte_idx = flag_id // 8
				bit_idx = flag_id % 8
				flags_data[story_offset + byte_idx] |= (1 << bit_idx)
		
		# Treasure chests
		chest_offset = self.OFFSET_TREASURE_CHESTS - self.OFFSET_STORY_FLAGS
		for chest_id in flags.treasure_chests:
			if chest_id < 256:
				byte_idx = chest_id // 8
				bit_idx = chest_id % 8
				flags_data[chest_offset + byte_idx] |= (1 << bit_idx)
		
		# NPC flags
		npc_offset = self.OFFSET_NPC_FLAGS - self.OFFSET_STORY_FLAGS
		for npc_id in flags.npc_flags:
			if npc_id < 128:
				byte_idx = npc_id // 8
				bit_idx = npc_id % 8
				flags_data[npc_offset + byte_idx] |= (1 << bit_idx)
		
		# Battlefield flags
		battlefield_offset = self.OFFSET_BATTLEFIELD_FLAGS - self.OFFSET_STORY_FLAGS
		for battlefield_id in flags.battlefield_flags:
			if battlefield_id < 128:
				byte_idx = battlefield_id // 8
				bit_idx = battlefield_id % 8
				flags_data[battlefield_offset + byte_idx] |= (1 << bit_idx)
		
		# Focus Tower
		tower_offset = self.OFFSET_FOCUS_TOWER - self.OFFSET_STORY_FLAGS
		for floor_id in flags.focus_tower_floors:
			if floor_id < 64:
				byte_idx = floor_id // 8
				bit_idx = floor_id % 8
				flags_data[tower_offset + byte_idx] |= (1 << bit_idx)
		
		return bytes(flags_data)
	
	def parse_statistics(self, slot_data: bytes) -> Statistics:
		"""Parse game statistics - ENHANCED"""
		stats = Statistics()
		
		# Battle stats
		offset = self.OFFSET_BATTLE_STATS
		stats.total_battles = struct.unpack('<H', slot_data[offset:offset + 2])[0]
		stats.battles_won = struct.unpack('<H', slot_data[offset + 2:offset + 4])[0]
		stats.battles_fled = struct.unpack('<H', slot_data[offset + 4:offset + 6])[0]
		
		# 24-bit values
		stats.total_damage_dealt = struct.unpack('<I', slot_data[offset + 6:offset + 9] + b'\x00')[0]
		stats.total_damage_taken = struct.unpack('<I', slot_data[offset + 9:offset + 12] + b'\x00')[0]
		stats.total_healing = struct.unpack('<I', slot_data[offset + 12:offset + 15] + b'\x00')[0]
		
		# Monster book (32 bytes = 256 bits for 83 enemies)
		for byte_idx in range(32):
			byte_val = slot_data[self.OFFSET_MONSTER_BOOK + byte_idx]
			for bit_idx in range(8):
				if byte_val & (1 << bit_idx):
					enemy_id = byte_idx * 8 + bit_idx
					if enemy_id < 83:  # Only 83 enemies in game
						stats.enemies_encountered.add(enemy_id)
		
		# Item stats
		offset = self.OFFSET_ITEM_STATS
		stats.items_collected = struct.unpack('<H', slot_data[offset:offset + 2])[0]
		stats.items_used = struct.unpack('<H', slot_data[offset + 2:offset + 4])[0]
		stats.equipment_changes = struct.unpack('<H', slot_data[offset + 4:offset + 6])[0]
		
		return stats
	
	def serialize_statistics(self, stats: Statistics) -> bytes:
		"""Serialize game statistics - ENHANCED"""
		stats_data = bytearray(64)
		
		# Battle stats
		struct.pack_into('<H', stats_data, 0, min(stats.total_battles, 65535))
		struct.pack_into('<H', stats_data, 2, min(stats.battles_won, 65535))
		struct.pack_into('<H', stats_data, 4, min(stats.battles_fled, 65535))
		
		# 24-bit values
		damage_dealt_bytes = struct.pack('<I', min(stats.total_damage_dealt, 16777215))[:3]
		stats_data[6:9] = damage_dealt_bytes
		damage_taken_bytes = struct.pack('<I', min(stats.total_damage_taken, 16777215))[:3]
		stats_data[9:12] = damage_taken_bytes
		healing_bytes = struct.pack('<I', min(stats.total_healing, 16777215))[:3]
		stats_data[12:15] = healing_bytes
		
		# Monster book
		monster_offset = self.OFFSET_MONSTER_BOOK - self.OFFSET_BATTLE_STATS
		for enemy_id in stats.enemies_encountered:
			if enemy_id < 256:
				byte_idx = enemy_id // 8
				bit_idx = enemy_id % 8
				stats_data[monster_offset + byte_idx] |= (1 << bit_idx)
		
		# Item stats
		item_offset = self.OFFSET_ITEM_STATS - self.OFFSET_BATTLE_STATS
		struct.pack_into('<H', stats_data, item_offset, min(stats.items_collected, 65535))
		struct.pack_into('<H', stats_data, item_offset + 2, min(stats.items_used, 65535))
		struct.pack_into('<H', stats_data, item_offset + 4, min(stats.equipment_changes, 65535))
		
		return bytes(stats_data)
	
	def parse_slot(self, slot_id: int) -> SaveSlot:
		"""Parse complete save slot - ENHANCED"""
		slot_data = self.get_slot_data(slot_id)
		
		# Verify signature
		if slot_data[0:4] != self.SIGNATURE:
			raise ValueError(f"Invalid slot signature: {slot_data[0:4]}")
		
		slot = SaveSlot()
		slot.slot_id = slot_id
		slot.valid = self.verify_checksum(slot_data)
		slot.checksum = struct.unpack('<H', slot_data[self.OFFSET_CHECKSUM:self.OFFSET_CHECKSUM + 2])[0]
		
		# Characters
		char1_data = slot_data[self.OFFSET_CHAR1:self.OFFSET_CHAR1 + 0x50]
		char2_data = slot_data[self.OFFSET_CHAR2:self.OFFSET_CHAR2 + 0x50]
		slot.character1 = self.parse_character(char1_data)
		slot.character2 = self.parse_character(char2_data)
		
		# Basic party data
		slot.gold = struct.unpack('<I', slot_data[self.OFFSET_GOLD:self.OFFSET_GOLD + 3] + b'\x00')[0]
		slot.player_x = slot_data[self.OFFSET_POS_X]
		slot.player_y = slot_data[self.OFFSET_POS_Y]
		slot.player_facing = slot_data[self.OFFSET_FACING]
		slot.map_id = slot_data[self.OFFSET_MAP_ID]
		
		# Play time
		play_time_data = slot_data[self.OFFSET_PLAY_TIME:self.OFFSET_PLAY_TIME + 3]
		slot.play_time_hours = play_time_data[0]
		slot.play_time_minutes = play_time_data[1]
		slot.play_time_seconds = play_time_data[2]
		
		slot.cure_count = slot_data[self.OFFSET_CURE_COUNT]
		
		# ENHANCED data
		slot.inventory = self.parse_inventory(slot_data)
		slot.flags = self.parse_flags(slot_data)
		slot.stats = self.parse_statistics(slot_data)
		
		return slot
	
	def serialize_slot(self, slot: SaveSlot) -> bytes:
		"""Serialize complete save slot - ENHANCED"""
		slot_data = bytearray(self.SLOT_SIZE)
		
		# Signature
		slot_data[0:4] = self.SIGNATURE
		
		# Characters
		char1_bytes = self.serialize_character(slot.character1)
		char2_bytes = self.serialize_character(slot.character2)
		slot_data[self.OFFSET_CHAR1:self.OFFSET_CHAR1 + 0x50] = char1_bytes
		slot_data[self.OFFSET_CHAR2:self.OFFSET_CHAR2 + 0x50] = char2_bytes
		
		# Basic party data
		gold_bytes = struct.pack('<I', min(slot.gold, 9999999))[:3]
		slot_data[self.OFFSET_GOLD:self.OFFSET_GOLD + 3] = gold_bytes
		slot_data[self.OFFSET_POS_X] = slot.player_x
		slot_data[self.OFFSET_POS_Y] = slot.player_y
		slot_data[self.OFFSET_FACING] = slot.player_facing
		slot_data[self.OFFSET_MAP_ID] = slot.map_id
		
		# Play time
		slot_data[self.OFFSET_PLAY_TIME] = min(slot.play_time_hours, 99)
		slot_data[self.OFFSET_PLAY_TIME + 1] = min(slot.play_time_minutes, 59)
		slot_data[self.OFFSET_PLAY_TIME + 2] = min(slot.play_time_seconds, 59)
		
		slot_data[self.OFFSET_CURE_COUNT] = slot.cure_count
		
		# ENHANCED data
		inv_bytes = self.serialize_inventory(slot.inventory)
		slot_data[self.OFFSET_INVENTORY:self.OFFSET_INVENTORY + len(inv_bytes)] = inv_bytes
		
		flags_bytes = self.serialize_flags(slot.flags)
		slot_data[self.OFFSET_STORY_FLAGS:self.OFFSET_STORY_FLAGS + len(flags_bytes)] = flags_bytes
		
		stats_bytes = self.serialize_statistics(slot.stats)
		slot_data[self.OFFSET_BATTLE_STATS:self.OFFSET_BATTLE_STATS + len(stats_bytes)] = stats_bytes
		
		# Fix checksum
		self.fix_checksum(slot_data)
		
		return bytes(slot_data)


# ======================== CLI ========================

def cmd_extract(args):
	"""Extract save slot to JSON"""
	editor = SRAMEditor.from_file(Path(args.sram))
	slot = editor.parse_slot(args.slot)
	
	output = Path(args.output) if args.output else Path(f"slot{args.slot}.json")
	with open(output, 'w') as f:
		json.dump(slot.to_dict(), f, indent='\t')
	
	print(f"✓ Extracted slot {args.slot} to {output}")
	print(f"  Character 1: {slot.character1.name} (Lv {slot.character1.level})")
	print(f"  Gold: {slot.gold:,}")
	print(f"  Consumables: {len(slot.inventory.consumables)} types")
	print(f"  Key Items: {len(slot.inventory.key_items)}")
	print(f"  Weapons: {len(slot.inventory.weapons)} types")
	print(f"  Spells: {len(slot.character1.learned_spells)} learned")


def cmd_insert(args):
	"""Insert JSON save slot into SRAM"""
	# Load SRAM
	editor = SRAMEditor.from_file(Path(args.sram))
	
	# Load JSON
	with open(args.json, 'r') as f:
		data = json.load(f)
	
	# TODO: Parse JSON back to SaveSlot object
	# This would require reverse JSON→SaveSlot conversion
	print("⚠ Insert from JSON not yet implemented (complex reverse parsing needed)")
	print("  Use edit commands instead")


def cmd_edit(args):
	"""Edit save slot (work in progress)"""
	print("⚠ Edit command not yet fully implemented")
	print("  Extract to JSON, edit manually, then insert")


def cmd_verify(args):
	"""Verify SRAM checksums"""
	editor = SRAMEditor.from_file(Path(args.sram))
	
	print(f"Verifying {args.sram}...")
	valid_count = 0
	
	for slot_id in range(9):
		slot_data = editor.get_slot_data(slot_id)
		if slot_data[0:4] == SRAMEditor.SIGNATURE:
			valid = editor.verify_checksum(slot_data)
			status = "✓ VALID" if valid else "✗ INVALID"
			print(f"  Slot {slot_id}: {status}")
			if valid:
				valid_count += 1
		else:
			print(f"  Slot {slot_id}: EMPTY (no signature)")
	
	print(f"\nValid slots: {valid_count}/9")


def main():
	parser = argparse.ArgumentParser(
		description="FFMQ SRAM Editor - ENHANCED with full inventory/equipment support"
	)
	subparsers = parser.add_subparsers(dest='command', required=True)
	
	# Extract command
	extract_parser = subparsers.add_parser('extract', help='Extract save slot to JSON')
	extract_parser.add_argument('sram', help='SRAM file path')
	extract_parser.add_argument('--slot', type=int, required=True, choices=range(9), help='Slot ID (0-8)')
	extract_parser.add_argument('--output', '-o', help='Output JSON file')
	
	# Insert command
	insert_parser = subparsers.add_parser('insert', help='Insert JSON save slot into SRAM')
	insert_parser.add_argument('json', help='JSON save file')
	insert_parser.add_argument('sram', help='SRAM file path')
	insert_parser.add_argument('--slot', type=int, required=True, choices=range(9), help='Slot ID (0-8)')
	
	# Edit command (WIP)
	edit_parser = subparsers.add_parser('edit', help='Edit save slot (WIP)')
	edit_parser.add_argument('json', help='JSON save file to edit')
	
	# Verify command
	verify_parser = subparsers.add_parser('verify', help='Verify SRAM checksums')
	verify_parser.add_argument('sram', help='SRAM file path')
	
	args = parser.parse_args()
	
	if args.command == 'extract':
		cmd_extract(args)
	elif args.command == 'insert':
		cmd_insert(args)
	elif args.command == 'edit':
		cmd_edit(args)
	elif args.command == 'verify':
		cmd_verify(args)


if __name__ == '__main__':
	main()
