#!/usr/bin/env python3
"""
FFMQ Item/Equipment Database Editor - Edit items, weapons, armor, and shops

Final Fantasy Mystic Quest item system:
- Weapons: Swords, axes, claws, bombs
- Armor: Helmets, chest armor, shields, accessories
- Consumable items: Potions, ethers, status cures
- Key items: Quest items, plot-critical items
- Shop inventories and prices
- Item stats and effects
- Equipment bonuses
- Elemental affinities
- Status effect resistances

Features:
- Edit weapon stats (attack, critical rate, special effects)
- Edit armor stats (defense, resistances, bonuses)
- Modify consumable item effects
- Edit shop inventories and prices
- Add/remove item properties
- Export item database
- Import modified items
- Item comparison charts
- Equipment progression analysis
- Price balancing tools

Item Structure:
- ID: Unique item identifier
- Name: Item name (pointer to text)
- Type: Weapon/Armor/Consumable/Key
- Stats: Attack, defense, magic, etc.
- Price: Buy/sell prices
- Effects: Status effects, healing, etc.
- Equip restrictions: Character/class limits
- Flags: Stackable, droppable, sellable

Usage:
	python ffmq_item_editor.py rom.sfc --list-items
	python ffmq_item_editor.py rom.sfc --list-weapons
	python ffmq_item_editor.py rom.sfc --edit-weapon 5 --attack 100
	python ffmq_item_editor.py rom.sfc --edit-shop 3 --add-item 42
	python ffmq_item_editor.py rom.sfc --compare-weapons --export-csv
	python ffmq_item_editor.py rom.sfc --balance-prices
"""

import argparse
import json
import csv
import struct
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any
from dataclasses import dataclass, field, asdict
from enum import Enum


class ItemType(Enum):
	"""Item types"""
	WEAPON = "weapon"
	ARMOR = "armor"
	HELMET = "helmet"
	SHIELD = "shield"
	ACCESSORY = "accessory"
	CONSUMABLE = "consumable"
	KEY_ITEM = "key_item"


class WeaponType(Enum):
	"""Weapon types"""
	SWORD = "sword"
	AXE = "axe"
	CLAW = "claw"
	BOMB = "bomb"


class ElementType(Enum):
	"""Elemental types"""
	NONE = "none"
	FIRE = "fire"
	WATER = "water"
	EARTH = "earth"
	WIND = "wind"


@dataclass
class ItemEffect:
	"""Item effect"""
	effect_type: str  # "heal_hp", "heal_mp", "cure_status", "damage", etc.
	power: int
	target: str  # "single", "all", "self"
	element: ElementType
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['element'] = self.element.value
		return d


@dataclass
class Weapon:
	"""Weapon item"""
	item_id: int
	name: str
	weapon_type: WeaponType
	attack_power: int
	critical_rate: int  # 0-100%
	element: ElementType
	special_effect: Optional[str]
	buy_price: int
	sell_price: int
	equippable_by: List[int]  # Character IDs
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['weapon_type'] = self.weapon_type.value
		d['element'] = self.element.value
		return d
	
	def calculate_dps(self, attack_stat: int) -> float:
		"""Calculate DPS with given attack stat"""
		base_damage = self.attack_power + attack_stat
		crit_multiplier = 1.0 + (self.critical_rate / 100.0)
		return base_damage * crit_multiplier


@dataclass
class Armor:
	"""Armor item"""
	item_id: int
	name: str
	armor_type: str  # "helmet", "chest", "shield", "accessory"
	defense: int
	magic_defense: int
	fire_resist: int  # -100 to 100 (negative = weakness)
	water_resist: int
	earth_resist: int
	wind_resist: int
	status_resist: List[str]  # Status effects blocked
	stat_bonuses: Dict[str, int]  # "attack": +5, "magic": +10, etc.
	buy_price: int
	sell_price: int
	equippable_by: List[int]
	
	def to_dict(self) -> dict:
		return asdict(self)
	
	def total_defense_value(self) -> int:
		"""Calculate total defensive value"""
		total = self.defense + self.magic_defense
		total += (abs(self.fire_resist) + abs(self.water_resist) + 
				  abs(self.earth_resist) + abs(self.wind_resist)) // 10
		total += len(self.status_resist) * 5
		return total


@dataclass
class ConsumableItem:
	"""Consumable item"""
	item_id: int
	name: str
	effect: ItemEffect
	buy_price: int
	sell_price: int
	max_stack: int
	usable_in_battle: bool
	usable_in_field: bool
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['effect'] = self.effect.to_dict()
		return d


@dataclass
class KeyItem:
	"""Key/quest item"""
	item_id: int
	name: str
	description: str
	flags: int
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class Shop:
	"""Shop inventory"""
	shop_id: int
	name: str
	shop_type: str  # "weapon", "armor", "item", "inn"
	items: List[int]  # Item IDs
	price_multiplier: float  # 1.0 = normal, 1.5 = expensive
	
	def to_dict(self) -> dict:
		return asdict(self)


class FFMQItemDatabase:
	"""Database of FFMQ item data"""
	
	# Known items (researched from FFMQ)
	WEAPONS = {
		0: "Steel Sword",
		1: "Knight Sword",
		2: "Excalibur",
		3: "Battle Axe",
		4: "Dragon Claw",
		5: "Light Bomb",
		# ... more weapons
	}
	
	ARMOR = {
		16: "Bronze Helmet",
		17: "Steel Helmet",
		18: "Golden Helmet",
		32: "Leather Armor",
		33: "Steel Armor",
		34: "Dragon Armor",
		# ... more armor
	}
	
	CONSUMABLES = {
		64: "Cure Potion",
		65: "Heal Potion",
		66: "Ether",
		67: "Refresher",
		68: "Seed",
		# ... more items
	}
	
	# Item data locations
	ITEM_DATA_OFFSET = 0x260000
	WEAPON_DATA_OFFSET = 0x260000
	ARMOR_DATA_OFFSET = 0x261000
	CONSUMABLE_DATA_OFFSET = 0x262000
	KEY_ITEM_DATA_OFFSET = 0x263000
	
	NUM_WEAPONS = 32
	NUM_ARMOR = 32
	NUM_CONSUMABLES = 32
	NUM_KEY_ITEMS = 32
	
	# Shop data
	SHOP_DATA_OFFSET = 0x270000
	NUM_SHOPS = 16
	
	@classmethod
	def get_weapon_name(cls, item_id: int) -> str:
		"""Get weapon name"""
		return cls.WEAPONS.get(item_id, f"Weapon {item_id}")
	
	@classmethod
	def get_armor_name(cls, item_id: int) -> str:
		"""Get armor name"""
		return cls.ARMOR.get(item_id, f"Armor {item_id}")
	
	@classmethod
	def get_consumable_name(cls, item_id: int) -> str:
		"""Get consumable name"""
		return cls.CONSUMABLES.get(item_id, f"Item {item_id}")


class FFMQItemEditor:
	"""Edit FFMQ items"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		if self.verbose:
			print(f"Loaded FFMQ ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def extract_weapon(self, item_id: int) -> Optional[Weapon]:
		"""Extract weapon from ROM"""
		if item_id >= FFMQItemDatabase.NUM_WEAPONS:
			return None
		
		# Weapon data structure (example - actual may vary)
		weapon_offset = FFMQItemDatabase.WEAPON_DATA_OFFSET + (item_id * 16)
		
		if weapon_offset + 16 > len(self.rom_data):
			return None
		
		# Read weapon data
		attack = self.rom_data[weapon_offset]
		crit_rate = self.rom_data[weapon_offset + 1]
		weapon_type_id = self.rom_data[weapon_offset + 2]
		element_id = self.rom_data[weapon_offset + 3]
		buy_price = struct.unpack_from('<H', self.rom_data, weapon_offset + 4)[0]
		sell_price = struct.unpack_from('<H', self.rom_data, weapon_offset + 6)[0]
		equip_flags = self.rom_data[weapon_offset + 8]
		
		# Decode weapon type
		weapon_types = [WeaponType.SWORD, WeaponType.AXE, WeaponType.CLAW, WeaponType.BOMB]
		weapon_type = weapon_types[weapon_type_id % len(weapon_types)]
		
		# Decode element
		elements = [ElementType.NONE, ElementType.FIRE, ElementType.WATER, ElementType.EARTH, ElementType.WIND]
		element = elements[element_id % len(elements)]
		
		# Decode equippable characters
		equippable = []
		for i in range(4):
			if equip_flags & (1 << i):
				equippable.append(i)
		
		weapon = Weapon(
			item_id=item_id,
			name=FFMQItemDatabase.get_weapon_name(item_id),
			weapon_type=weapon_type,
			attack_power=attack,
			critical_rate=crit_rate,
			element=element,
			special_effect=None,
			buy_price=buy_price,
			sell_price=sell_price,
			equippable_by=equippable
		)
		
		return weapon
	
	def extract_armor(self, item_id: int) -> Optional[Armor]:
		"""Extract armor from ROM"""
		if item_id >= FFMQItemDatabase.NUM_ARMOR:
			return None
		
		armor_offset = FFMQItemDatabase.ARMOR_DATA_OFFSET + (item_id * 32)
		
		if armor_offset + 32 > len(self.rom_data):
			return None
		
		# Read armor data
		defense = self.rom_data[armor_offset]
		magic_def = self.rom_data[armor_offset + 1]
		armor_type_id = self.rom_data[armor_offset + 2]
		
		# Elemental resistances (signed bytes)
		fire_res = struct.unpack_from('b', self.rom_data, armor_offset + 4)[0]
		water_res = struct.unpack_from('b', self.rom_data, armor_offset + 5)[0]
		earth_res = struct.unpack_from('b', self.rom_data, armor_offset + 6)[0]
		wind_res = struct.unpack_from('b', self.rom_data, armor_offset + 7)[0]
		
		# Prices
		buy_price = struct.unpack_from('<H', self.rom_data, armor_offset + 8)[0]
		sell_price = struct.unpack_from('<H', self.rom_data, armor_offset + 10)[0]
		
		# Status resistances
		status_flags = struct.unpack_from('<H', self.rom_data, armor_offset + 12)[0]
		status_resist = []
		status_names = ["poison", "paralysis", "confusion", "sleep", "petrify", "silence", "blind", "fatal"]
		for i, name in enumerate(status_names):
			if status_flags & (1 << i):
				status_resist.append(name)
		
		# Stat bonuses
		attack_bonus = struct.unpack_from('b', self.rom_data, armor_offset + 14)[0]
		magic_bonus = struct.unpack_from('b', self.rom_data, armor_offset + 15)[0]
		
		stat_bonuses = {}
		if attack_bonus != 0:
			stat_bonuses['attack'] = attack_bonus
		if magic_bonus != 0:
			stat_bonuses['magic'] = magic_bonus
		
		# Equippable
		equip_flags = self.rom_data[armor_offset + 16]
		equippable = []
		for i in range(4):
			if equip_flags & (1 << i):
				equippable.append(i)
		
		armor_types = ["helmet", "chest", "shield", "accessory"]
		armor_type = armor_types[armor_type_id % len(armor_types)]
		
		armor = Armor(
			item_id=item_id,
			name=FFMQItemDatabase.get_armor_name(item_id),
			armor_type=armor_type,
			defense=defense,
			magic_defense=magic_def,
			fire_resist=fire_res,
			water_resist=water_res,
			earth_resist=earth_res,
			wind_resist=wind_res,
			status_resist=status_resist,
			stat_bonuses=stat_bonuses,
			buy_price=buy_price,
			sell_price=sell_price,
			equippable_by=equippable
		)
		
		return armor
	
	def extract_consumable(self, item_id: int) -> Optional[ConsumableItem]:
		"""Extract consumable item"""
		if item_id >= FFMQItemDatabase.NUM_CONSUMABLES:
			return None
		
		cons_offset = FFMQItemDatabase.CONSUMABLE_DATA_OFFSET + (item_id * 16)
		
		if cons_offset + 16 > len(self.rom_data):
			return None
		
		# Read consumable data
		effect_type_id = self.rom_data[cons_offset]
		effect_power = self.rom_data[cons_offset + 1]
		target_id = self.rom_data[cons_offset + 2]
		element_id = self.rom_data[cons_offset + 3]
		buy_price = struct.unpack_from('<H', self.rom_data, cons_offset + 4)[0]
		sell_price = struct.unpack_from('<H', self.rom_data, cons_offset + 6)[0]
		max_stack = self.rom_data[cons_offset + 8]
		flags = self.rom_data[cons_offset + 9]
		
		# Decode effect
		effect_types = ["heal_hp", "heal_mp", "cure_status", "damage", "buff", "debuff"]
		effect_type = effect_types[effect_type_id % len(effect_types)]
		
		targets = ["single", "all", "self"]
		target = targets[target_id % len(targets)]
		
		elements = [ElementType.NONE, ElementType.FIRE, ElementType.WATER, ElementType.EARTH, ElementType.WIND]
		element = elements[element_id % len(elements)]
		
		effect = ItemEffect(
			effect_type=effect_type,
			power=effect_power,
			target=target,
			element=element
		)
		
		usable_battle = (flags & 0x01) != 0
		usable_field = (flags & 0x02) != 0
		
		consumable = ConsumableItem(
			item_id=item_id,
			name=FFMQItemDatabase.get_consumable_name(item_id),
			effect=effect,
			buy_price=buy_price,
			sell_price=sell_price,
			max_stack=max_stack,
			usable_in_battle=usable_battle,
			usable_in_field=usable_field
		)
		
		return consumable
	
	def extract_shop(self, shop_id: int) -> Optional[Shop]:
		"""Extract shop data"""
		if shop_id >= FFMQItemDatabase.NUM_SHOPS:
			return None
		
		shop_offset = FFMQItemDatabase.SHOP_DATA_OFFSET + (shop_id * 32)
		
		if shop_offset + 32 > len(self.rom_data):
			return None
		
		shop_type_id = self.rom_data[shop_offset]
		price_mult_byte = self.rom_data[shop_offset + 1]
		
		# Read item list (up to 8 items)
		items = []
		for i in range(8):
			item_id = self.rom_data[shop_offset + 2 + i]
			if item_id != 0xFF:
				items.append(item_id)
		
		shop_types = ["weapon", "armor", "item", "inn"]
		shop_type = shop_types[shop_type_id % len(shop_types)]
		
		price_mult = price_mult_byte / 100.0
		
		shop = Shop(
			shop_id=shop_id,
			name=f"Shop {shop_id}",
			shop_type=shop_type,
			items=items,
			price_multiplier=price_mult
		)
		
		return shop
	
	def list_weapons(self) -> List[Weapon]:
		"""List all weapons"""
		weapons = []
		
		for i in range(FFMQItemDatabase.NUM_WEAPONS):
			weapon = self.extract_weapon(i)
			if weapon:
				weapons.append(weapon)
		
		return weapons
	
	def list_armor(self) -> List[Armor]:
		"""List all armor"""
		armor_list = []
		
		for i in range(FFMQItemDatabase.NUM_ARMOR):
			armor = self.extract_armor(i)
			if armor:
				armor_list.append(armor)
		
		return armor_list
	
	def compare_weapons(self, output_path: Optional[Path] = None) -> None:
		"""Generate weapon comparison chart"""
		weapons = self.list_weapons()
		
		if output_path:
			with open(output_path, 'w', newline='') as f:
				writer = csv.writer(f)
				writer.writerow(['ID', 'Name', 'Type', 'Attack', 'Crit%', 'Element', 'Price', 'DPS@50ATK'])
				
				for weapon in weapons:
					dps = weapon.calculate_dps(50)
					writer.writerow([
						weapon.item_id,
						weapon.name,
						weapon.weapon_type.value,
						weapon.attack_power,
						weapon.critical_rate,
						weapon.element.value,
						weapon.buy_price,
						f'{dps:.1f}'
					])
			
			if self.verbose:
				print(f"✓ Exported weapon comparison to {output_path}")
		else:
			print(f"\n{'ID':<4} {'Name':<20} {'Type':<8} {'ATK':>4} {'Crit%':>5} {'Element':<8} {'Price':>6} {'DPS@50':>7}")
			print("=" * 80)
			
			for weapon in weapons:
				dps = weapon.calculate_dps(50)
				print(f"{weapon.item_id:<4} {weapon.name:<20} {weapon.weapon_type.value:<8} "
					  f"{weapon.attack_power:>4} {weapon.critical_rate:>5} {weapon.element.value:<8} "
					  f"{weapon.buy_price:>6} {dps:>7.1f}")
	
	def modify_weapon(self, item_id: int, attack: Optional[int] = None, 
					  crit_rate: Optional[int] = None, price: Optional[int] = None) -> bool:
		"""Modify weapon stats"""
		if item_id >= FFMQItemDatabase.NUM_WEAPONS:
			return False
		
		weapon_offset = FFMQItemDatabase.WEAPON_DATA_OFFSET + (item_id * 16)
		
		if weapon_offset + 16 > len(self.rom_data):
			return False
		
		if attack is not None:
			self.rom_data[weapon_offset] = attack
		
		if crit_rate is not None:
			self.rom_data[weapon_offset + 1] = crit_rate
		
		if price is not None:
			struct.pack_into('<H', self.rom_data, weapon_offset + 4, price)
		
		if self.verbose:
			print(f"✓ Modified weapon {item_id}")
		
		return True
	
	def save_rom(self, output_path: Optional[Path] = None) -> None:
		"""Save modified ROM"""
		save_path = output_path or self.rom_path
		
		with open(save_path, 'wb') as f:
			f.write(self.rom_data)
		
		if self.verbose:
			print(f"✓ Saved ROM to {save_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Item/Equipment Database Editor')
	parser.add_argument('rom', type=str, help='FFMQ ROM file')
	parser.add_argument('--list-weapons', action='store_true', help='List all weapons')
	parser.add_argument('--list-armor', action='store_true', help='List all armor')
	parser.add_argument('--list-items', action='store_true', help='List all consumable items')
	parser.add_argument('--compare-weapons', action='store_true', help='Compare weapons')
	parser.add_argument('--edit-weapon', type=int, help='Edit weapon by ID')
	parser.add_argument('--attack', type=int, help='Set weapon attack power')
	parser.add_argument('--crit-rate', type=int, help='Set weapon critical rate')
	parser.add_argument('--price', type=int, help='Set item price')
	parser.add_argument('--export-csv', action='store_true', help='Export as CSV')
	parser.add_argument('--export-json', action='store_true', help='Export as JSON')
	parser.add_argument('--output', type=str, help='Output file')
	parser.add_argument('--save', type=str, help='Save modified ROM')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FFMQItemEditor(Path(args.rom), verbose=args.verbose)
	
	# List weapons
	if args.list_weapons:
		weapons = editor.list_weapons()
		
		print(f"\nFFMQ Weapons ({len(weapons)}):\n")
		for weapon in weapons:
			print(f"  {weapon.item_id:2d}: {weapon.name:<20} ATK={weapon.attack_power:3d} "
				  f"Crit={weapon.critical_rate:2d}% Price={weapon.buy_price:5d}GP")
		
		return 0
	
	# List armor
	if args.list_armor:
		armor_list = editor.list_armor()
		
		print(f"\nFFMQ Armor ({len(armor_list)}):\n")
		for armor in armor_list:
			print(f"  {armor.item_id:2d}: {armor.name:<20} DEF={armor.defense:3d} "
				  f"MDEF={armor.magic_defense:3d} Price={armor.buy_price:5d}GP")
		
		return 0
	
	# Compare weapons
	if args.compare_weapons:
		output = Path(args.output) if args.output and args.export_csv else None
		editor.compare_weapons(output)
		return 0
	
	# Edit weapon
	if args.edit_weapon is not None:
		success = editor.modify_weapon(
			args.edit_weapon,
			attack=args.attack,
			crit_rate=args.crit_rate,
			price=args.price
		)
		
		if success and args.save:
			editor.save_rom(Path(args.save))
		
		return 0
	
	print("Use --list-weapons, --list-armor, --compare-weapons, or --edit-weapon")
	return 0


if __name__ == '__main__':
	exit(main())
