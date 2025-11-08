"""
FFMQ Item Database Manager

Manages the complete item database including loading from ROM,
saving to ROM, searching, and shop management.
"""

from typing import Dict, List, Optional, Tuple
from pathlib import Path
import struct
import json

from item_data import Item, ItemType, ItemFlags, EquipRestriction, ITEM_NAMES


# ROM addresses for item data
ITEM_DATA_BASE = 0x0F0000  # Base address for item data
ITEM_COUNT = 256           # Total number of items
ITEM_SIZE = 32             # Size of each item data block


class ItemDatabase:
	"""
	Manages the complete FFMQ item database
	
	Handles loading items from ROM, editing, and saving back to ROM.
	"""
	
	def __init__(self):
		"""Initialize empty item database"""
		self.items: Dict[int, Item] = {}
		self.rom_data: Optional[bytes] = None
		self.rom_path: Optional[Path] = None
	
	def load_from_rom(self, rom_path: str):
		"""
		Load all items from ROM
		
		Args:
			rom_path: Path to FFMQ ROM file
		"""
		rom_path_obj = Path(rom_path)
		if not rom_path_obj.exists():
			raise FileNotFoundError(f"ROM not found: {rom_path}")
		
		with open(rom_path_obj, 'rb') as f:
			self.rom_data = f.read()
		
		self.rom_path = rom_path_obj
		self.items.clear()
		
		# Load each item
		for item_id in range(ITEM_COUNT):
			address = ITEM_DATA_BASE + (item_id * ITEM_SIZE)
			
			if address + ITEM_SIZE > len(self.rom_data):
				break
			
			item_bytes = self.rom_data[address:address + ITEM_SIZE]
			item = Item.from_bytes(item_id, item_bytes, address)
			
			# Set name from database if available
			if item_id in ITEM_NAMES:
				item.name = ITEM_NAMES[item_id]
			
			self.items[item_id] = item
		
		print(f"Loaded {len(self.items)} items from ROM")
	
	def save_to_rom(self, output_path: str):
		"""
		Save all items to ROM
		
		Args:
			output_path: Output ROM file path
		"""
		if not self.rom_data:
			raise RuntimeError("No ROM data loaded")
		
		# Create copy of ROM data
		new_rom = bytearray(self.rom_data)
		
		# Write each modified item
		modified_count = 0
		for item_id, item in self.items.items():
			if item.modified:
				address = ITEM_DATA_BASE + (item_id * ITEM_SIZE)
				item_bytes = item.to_bytes()
				new_rom[address:address + len(item_bytes)] = item_bytes
				modified_count += 1
		
		# Write to file
		with open(output_path, 'wb') as f:
			f.write(new_rom)
		
		print(f"Saved {modified_count} modified items to {output_path}")
	
	def get_item(self, item_id: int) -> Optional[Item]:
		"""Get item by ID"""
		return self.items.get(item_id)
	
	def search_items(self, query: str, case_sensitive: bool = False) -> List[Item]:
		"""Search items by name"""
		if not case_sensitive:
			query = query.lower()
		
		results = []
		for item in self.items.values():
			name = item.name if case_sensitive else item.name.lower()
			if query in name:
				results.append(item)
		
		return results
	
	def filter_by_type(self, item_type: ItemType) -> List[Item]:
		"""Filter items by type"""
		return [item for item in self.items.values() if item.item_type == item_type]
	
	def get_weapons(self) -> List[Item]:
		"""Get all weapons"""
		return self.filter_by_type(ItemType.WEAPON)
	
	def get_armor(self) -> List[Item]:
		"""Get all armor"""
		return self.filter_by_type(ItemType.ARMOR)
	
	def get_consumables(self) -> List[Item]:
		"""Get all consumables"""
		return self.filter_by_type(ItemType.CONSUMABLE)
	
	def get_key_items(self) -> List[Item]:
		"""Get all key items"""
		return self.filter_by_type(ItemType.KEY_ITEM)
	
	def get_by_price(self, ascending: bool = True) -> List[Item]:
		"""Get items sorted by buy price"""
		return sorted(
			self.items.values(),
			key=lambda i: i.buy_price,
			reverse=not ascending
		)
	
	def get_statistics(self) -> Dict[str, any]:
		"""Get database statistics"""
		if not self.items:
			return {}
		
		total = len(self.items)
		modified = sum(1 for i in self.items.values() if i.modified)
		
		# Count by type
		type_counts = {}
		for item in self.items.values():
			type_name = item.item_type.name
			type_counts[type_name] = type_counts.get(type_name, 0) + 1
		
		# Average prices
		sellable = [i for i in self.items.values() if i.flags & ItemFlags.SELLABLE]
		avg_buy = sum(i.buy_price for i in sellable) / len(sellable) if sellable else 0
		avg_sell = sum(i.sell_price for i in sellable) / len(sellable) if sellable else 0
		
		# Most expensive
		most_expensive = max(self.items.values(), key=lambda i: i.buy_price)
		
		# Best equipment (by total stats)
		equipment = [i for i in self.items.values() if i.is_equipment()]
		best_equipment = max(equipment, key=lambda i: i.get_total_stats_value()) if equipment else None
		
		return {
			'total': total,
			'modified': modified,
			'type_counts': type_counts,
			'avg_buy_price': avg_buy,
			'avg_sell_price': avg_sell,
			'most_expensive': most_expensive,
			'best_equipment': best_equipment
		}
	
	def export_to_csv(self, output_path: str):
		"""Export item database to CSV"""
		import csv
		
		with open(output_path, 'w', newline='', encoding='utf-8') as f:
			writer = csv.writer(f)
			
			# Header
			writer.writerow([
				'ID', 'Name', 'Type', 'Buy Price', 'Sell Price',
				'Attack', 'Defense', 'Magic', 'MagicDef', 'Speed',
				'Equip By', 'Flags'
			])
			
			# Data
			for item_id, item in sorted(self.items.items()):
				equip_by = ', '.join(item.get_who_can_equip()) if item.is_equipment() else 'N/A'
				
				writer.writerow([
					f'0x{item_id:03X}',
					item.name,
					item.item_type.name,
					item.buy_price,
					item.sell_price,
					item.equipment_stats.attack if item.is_equipment() else '',
					item.equipment_stats.defense if item.is_equipment() else '',
					item.equipment_stats.magic if item.is_equipment() else '',
					item.equipment_stats.magic_defense if item.is_equipment() else '',
					item.equipment_stats.speed if item.is_equipment() else '',
					equip_by,
					item.flags.name
				])
	
	def export_to_json(self, output_path: str, pretty: bool = True):
		"""Export item database to JSON"""
		from dataclasses import asdict
		
		data = {}
		for item_id, item in self.items.items():
			item_dict = {
				'id': item_id,
				'name': item.name,
				'type': item.item_type.name,
				'buy_price': item.buy_price,
				'sell_price': item.sell_price,
				'max_stack': item.max_stack,
				'flags': item.flags.value,
			}
			
			if item.is_equipment():
				item_dict['equipment_stats'] = asdict(item.equipment_stats)
				item_dict['equip_restriction'] = item.get_who_can_equip()
			else:
				item_dict['effect'] = asdict(item.effect)
			
			data[f'0x{item_id:03X}'] = item_dict
		
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent=2 if pretty else None)
