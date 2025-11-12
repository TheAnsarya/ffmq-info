"""
FFMQ Item Data Structures

Comprehensive item system including weapons, armor, consumables,
and key items with stats, effects, and restrictions.
"""

from dataclasses import dataclass, field
from typing import List, Dict, Optional
from enum import IntEnum, IntFlag
import struct


class ItemType(IntEnum):
	"""Item categories"""
	CONSUMABLE = 0
	WEAPON = 1
	ARMOR = 2
	HELMET = 3
	ACCESSORY = 4
	KEY_ITEM = 5
	COIN = 6
	BOOK = 7


class ItemFlags(IntFlag):
	"""Item behavior flags"""
	NONE = 0
	USABLE_IN_BATTLE = 0x01
	USABLE_IN_FIELD = 0x02
	THROWABLE = 0x04
	STACKABLE = 0x08
	SELLABLE = 0x10
	TRADEABLE = 0x20
	DROPPABLE = 0x40
	CURSED = 0x80
	EQUIPMENT_LOCKED = 0x100


class EquipRestriction(IntFlag):
	"""Who can equip this item"""
	NONE = 0
	BENJAMIN = 0x01
	KAELI = 0x02
	PHOEBE = 0x04
	REUBEN = 0x08
	TRISTAM = 0x10
	ALL = 0x1F


class StatusEffect(IntFlag):
	"""Status effects items can cure/inflict"""
	NONE = 0
	POISON = 0x01
	BLIND = 0x02
	SILENCE = 0x04
	SLEEP = 0x08
	PARALYZE = 0x10
	CONFUSE = 0x20
	PETRIFY = 0x40
	KO = 0x80
	REGEN = 0x100
	PROTECT = 0x200
	SHELL = 0x400


@dataclass
class ItemEffect:
	"""Item use effect"""
	effect_type: int = 0	  # 0=heal HP, 1=heal MP, 2=cure status, 3=damage, 4=buff
	power: int = 0			# Effect strength
	target: int = 0		   # 0=single, 1=all allies, 2=all enemies
	status_mask: StatusEffect = StatusEffect.NONE
	
	def to_bytes(self) -> bytes:
		"""Convert to ROM bytes"""
		return struct.pack('<BBBH', self.effect_type, self.power, self.target, self.status_mask)
	
	@classmethod
	def from_bytes(cls, data: bytes) -> 'ItemEffect':
		"""Load from ROM bytes"""
		effect_type, power, target, status = struct.unpack('<BBBH', data[:5])
		return cls(
			effect_type=effect_type,
			power=power,
			target=target,
			status_mask=StatusEffect(status)
		)


@dataclass
class EquipmentStats:
	"""Equipment stat bonuses"""
	attack: int = 0
	defense: int = 0
	magic: int = 0
	magic_defense: int = 0
	speed: int = 0
	accuracy: int = 0
	evade: int = 0
	hp_bonus: int = 0
	mp_bonus: int = 0
	
	def to_bytes(self) -> bytes:
		"""Convert to ROM bytes"""
		return struct.pack('<9h',  # Signed shorts for negative bonuses
			self.attack, self.defense, self.magic, self.magic_defense,
			self.speed, self.accuracy, self.evade, self.hp_bonus, self.mp_bonus
		)
	
	@classmethod
	def from_bytes(cls, data: bytes) -> 'EquipmentStats':
		"""Load from ROM bytes"""
		values = struct.unpack('<9h', data[:18])
		return cls(
			attack=values[0], defense=values[1], magic=values[2],
			magic_defense=values[3], speed=values[4], accuracy=values[5],
			evade=values[6], hp_bonus=values[7], mp_bonus=values[8]
		)


@dataclass
class Item:
	"""Complete item data"""
	item_id: int = 0
	name: str = "New Item"
	
	# Type and flags
	item_type: ItemType = ItemType.CONSUMABLE
	flags: ItemFlags = ItemFlags.NONE
	
	# Equipment restrictions
	equip_restriction: EquipRestriction = EquipRestriction.NONE
	
	# Stats (for equipment)
	equipment_stats: EquipmentStats = field(default_factory=EquipmentStats)
	
	# Effects (for consumables)
	effect: ItemEffect = field(default_factory=ItemEffect)
	
	# Shop data
	buy_price: int = 0
	sell_price: int = 0
	
	# Stack limits
	max_stack: int = 1		# Maximum stack size (1 = non-stackable)
	
	# Graphics
	icon_id: int = 0		  # Item icon sprite ID
	palette_id: int = 0	   # Palette for icon
	
	# Special properties
	element: int = 0		  # Elemental affinity (for weapons)
	special_effect_id: int = 0  # Special effect ID (e.g., critical boost)
	
	# Metadata
	description: str = ""
	
	# ROM addresses
	address: int = 0
	pointer: int = 0
	
	# Editor
	modified: bool = False
	notes: str = ""
	
	def to_bytes(self) -> bytes:
		"""
		Serialize item to ROM format
		
		Returns:
			bytes: Complete item data block
		"""
		data = bytearray()
		
		# Basic info (8 bytes)
		data.extend(struct.pack('<BBHHHBB',
			self.item_type,
			self.max_stack,
			self.buy_price,
			self.sell_price,
			self.flags,
			self.icon_id,
			self.palette_id
		))
		
		# Equipment restrictions and special (4 bytes)
		data.extend(struct.pack('<BBBB',
			self.equip_restriction,
			self.element,
			self.special_effect_id,
			0  # Padding
		))
		
		# Stats (18 bytes) or effect (5 bytes + padding)
		if self.item_type in [ItemType.WEAPON, ItemType.ARMOR, ItemType.HELMET, ItemType.ACCESSORY]:
			data.extend(self.equipment_stats.to_bytes())
		else:
			data.extend(self.effect.to_bytes())
			data.extend(b'\x00' * 13)  # Padding
		
		# Pad to 32 bytes
		while len(data) < 32:
			data.append(0x00)
		
		return bytes(data[:32])
	
	@classmethod
	def from_bytes(cls, item_id: int, data: bytes, address: int = 0) -> 'Item':
		"""
		Load item from ROM bytes
		
		Args:
			item_id: Item ID
			data: ROM data bytes
			address: ROM address
		
		Returns:
			Item: Loaded item data
		"""
		offset = 0
		
		# Basic info
		item_type, max_stack, buy_price, sell_price, flags, icon, palette = struct.unpack('<BBHHHBB', data[offset:offset+10])
		offset += 10
		
		# Equipment restrictions and special
		equip_rest, element, special, _ = struct.unpack('<BBBB', data[offset:offset+4])
		offset += 4
		
		# Stats or effect
		item_type_enum = ItemType(item_type)
		if item_type_enum in [ItemType.WEAPON, ItemType.ARMOR, ItemType.HELMET, ItemType.ACCESSORY]:
			equipment_stats = EquipmentStats.from_bytes(data[offset:])
			effect = ItemEffect()
		else:
			equipment_stats = EquipmentStats()
			effect = ItemEffect.from_bytes(data[offset:])
		
		return cls(
			item_id=item_id,
			name=f"Item_{item_id:03X}",
			item_type=item_type_enum,
			flags=ItemFlags(flags),
			equip_restriction=EquipRestriction(equip_rest),
			equipment_stats=equipment_stats,
			effect=effect,
			buy_price=buy_price,
			sell_price=sell_price,
			max_stack=max_stack,
			icon_id=icon,
			palette_id=palette,
			element=element,
			special_effect_id=special,
			address=address,
			modified=False
		)
	
	def is_equipment(self) -> bool:
		"""Check if item is equipment"""
		return self.item_type in [ItemType.WEAPON, ItemType.ARMOR, ItemType.HELMET, ItemType.ACCESSORY]
	
	def is_consumable(self) -> bool:
		"""Check if item is consumable"""
		return self.item_type == ItemType.CONSUMABLE
	
	def is_key_item(self) -> bool:
		"""Check if item is a key item"""
		return self.item_type == ItemType.KEY_ITEM
	
	def can_use_in_battle(self) -> bool:
		"""Check if item can be used in battle"""
		return bool(self.flags & ItemFlags.USABLE_IN_BATTLE)
	
	def can_use_in_field(self) -> bool:
		"""Check if item can be used outside battle"""
		return bool(self.flags & ItemFlags.USABLE_IN_FIELD)
	
	def get_total_stats_value(self) -> int:
		"""
		Calculate total stat bonus value
		
		Returns:
			int: Sum of all stat bonuses
		"""
		if not self.is_equipment():
			return 0
		
		return (
			abs(self.equipment_stats.attack) +
			abs(self.equipment_stats.defense) +
			abs(self.equipment_stats.magic) +
			abs(self.equipment_stats.magic_defense) +
			abs(self.equipment_stats.speed) +
			abs(self.equipment_stats.accuracy) +
			abs(self.equipment_stats.evade) +
			(abs(self.equipment_stats.hp_bonus) // 10) +  # HP/MP worth less
			(abs(self.equipment_stats.mp_bonus) // 10)
		)
	
	def get_who_can_equip(self) -> List[str]:
		"""
		Get list of character names who can equip this item
		
		Returns:
			List of character names
		"""
		if not self.is_equipment():
			return []
		
		characters = []
		if self.equip_restriction & EquipRestriction.BENJAMIN:
			characters.append("Benjamin")
		if self.equip_restriction & EquipRestriction.KAELI:
			characters.append("Kaeli")
		if self.equip_restriction & EquipRestriction.PHOEBE:
			characters.append("Phoebe")
		if self.equip_restriction & EquipRestriction.REUBEN:
			characters.append("Reuben")
		if self.equip_restriction & EquipRestriction.TRISTAM:
			characters.append("Tristam")
		
		return characters if characters else ["None"]
	
	def __repr__(self) -> str:
		"""String representation"""
		return (
			f"Item(id=0x{self.item_id:03X}, name='{self.name}', "
			f"type={self.item_type.name}, price={self.buy_price})"
		)


# Item name database (loaded from ROM)
ITEM_NAMES: Dict[int, str] = {
	# Consumables
	0x00: "Cure Potion",
	0x01: "Heal Potion",
	0x02: "Seed",
	0x03: "Refresher",
	0x04: "Elixir",
	0x05: "Ether",
	0x06: "Phoenix",
	
	# Weapons
	0x10: "Steel Sword",
	0x11: "Knight Sword",
	0x12: "Excalibur",
	0x13: "Axe",
	0x14: "Battle Axe",
	0x15: "Bow",
	0x16: "Crossbow",
	
	# Armor
	0x20: "Leather Armor",
	0x21: "Iron Armor",
	0x22: "Steel Armor",
	0x23: "Knight Armor",
	0x24: "Mystic Armor",
	
	# Helmets
	0x30: "Cap",
	0x31: "Iron Helm",
	0x32: "Steel Helm",
	0x33: "Knight Helm",
	
	# Accessories
	0x40: "Power Ring",
	0x41: "Guard Ring",
	0x42: "Magic Ring",
	0x43: "Charm",
	0x44: "Amulet",
	
	# Key Items
	0x50: "Rainbow Road Map",
	0x51: "Crystal",
	0x52: "Dragon Claw",
	0x53: "Venus Key",
	# ...more items
}


def get_item_name(item_id: int) -> str:
	"""
	Get item name by ID
	
	Args:
		item_id: Item ID
	
	Returns:
		str: Item name or default
	"""
	return ITEM_NAMES.get(item_id, f"Item_{item_id:03X}")
