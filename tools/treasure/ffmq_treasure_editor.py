#!/usr/bin/env python3
"""
FFMQ Treasure Editor - Edit treasure chests and item placement

FFMQ Treasure System:
- 256 treasure chests
- Map-based placement
- Item contents
- Opened flags
- Hidden chests
- Mimic chests (battle trigger)
- GP treasures
- Key items

Features:
- View all treasures
- Edit chest contents
- Modify positions
- Set hidden/visible flags
- Configure mimics
- Randomize treasures
- Balance progression
- Export treasure lists
- Import custom placements
- Treasure maps generation

Chest Structure:
- Chest ID (0-255)
- Map ID
- Position (X, Y)
- Item ID or GP amount
- Flags (opened, hidden, mimic)
- Required item (key)

Usage:
	python ffmq_treasure_editor.py rom.sfc --list-treasures
	python ffmq_treasure_editor.py rom.sfc --show-treasure 10
	python ffmq_treasure_editor.py rom.sfc --edit-treasure 10 --item 50 --hidden
	python ffmq_treasure_editor.py rom.sfc --list-map 0
	python ffmq_treasure_editor.py rom.sfc --randomize --seed 12345
	python ffmq_treasure_editor.py rom.sfc --export treasures.json
	python ffmq_treasure_editor.py rom.sfc --generate-map treasure_map.html
"""

import argparse
import json
import struct
import random
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any, Set
from dataclasses import dataclass, field, asdict
from enum import Enum


class TreasureType(Enum):
	"""Treasure types"""
	ITEM = "item"
	GP = "gp"
	KEY_ITEM = "key_item"
	MIMIC = "mimic"


@dataclass
class Treasure:
	"""Treasure chest"""
	chest_id: int
	map_id: int
	x: int
	y: int
	treasure_type: TreasureType
	item_id: int
	item_name: str
	gp_amount: int
	is_hidden: bool
	is_opened: bool
	is_mimic: bool
	required_item: int  # Key item ID needed to open
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['treasure_type'] = self.treasure_type.value
		return d


class FFMQTreasureDatabase:
	"""Database of FFMQ treasures"""
	
	# Treasure data location
	TREASURE_DATA_OFFSET = 0x350000
	NUM_TREASURES = 256
	TREASURE_SIZE = 8
	
	# Treasure flags offset
	TREASURE_FLAGS_OFFSET = 0x358000
	
	# Item names (subset)
	ITEM_NAMES = {
		# Weapons
		0: "Steel Sword",
		1: "Knight Sword",
		2: "Excalibur",
		3: "Battle Axe",
		4: "Dragon Claw",
		5: "Light Bomb",
		
		# Armor
		10: "Iron Helm",
		11: "Steel Helm",
		12: "Moon Helm",
		20: "Leather Armor",
		21: "Bronze Armor",
		22: "Iron Armor",
		30: "Iron Shield",
		31: "Steel Shield",
		40: "Charm",
		41: "Magic Ring",
		
		# Consumables
		50: "Cure Potion",
		51: "Heal Potion",
		52: "Refresher",
		53: "Ether",
		54: "Elixir",
		55: "Seed",
		
		# Key Items
		100: "Venus Key",
		101: "Multi Key",
		102: "Mask",
		103: "Magic Coin",
		104: "Sand Coin",
		105: "River Coin",
		106: "Sun Coin",
	}
	
	# Map names (subset)
	MAP_NAMES = {
		0: "Hill of Destiny",
		1: "Foresta",
		2: "Aquaria",
		3: "Fireburg",
		4: "Windia",
		5: "Level Forest",
		6: "Bone Dungeon",
		7: "Focus Tower",
		# ... more maps
	}
	
	@classmethod
	def get_item_name(cls, item_id: int) -> str:
		"""Get item name"""
		return cls.ITEM_NAMES.get(item_id, f"Item {item_id}")
	
	@classmethod
	def get_map_name(cls, map_id: int) -> str:
		"""Get map name"""
		return cls.MAP_NAMES.get(map_id, f"Map {map_id}")
	
	@classmethod
	def is_key_item(cls, item_id: int) -> bool:
		"""Check if item is a key item"""
		return 100 <= item_id < 120


class FFMQTreasureEditor:
	"""Edit FFMQ treasure chests"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		if self.verbose:
			print(f"Loaded FFMQ ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def extract_treasure(self, chest_id: int) -> Optional[Treasure]:
		"""Extract treasure from ROM"""
		if chest_id >= FFMQTreasureDatabase.NUM_TREASURES:
			return None
		
		offset = FFMQTreasureDatabase.TREASURE_DATA_OFFSET + (chest_id * FFMQTreasureDatabase.TREASURE_SIZE)
		
		if offset + FFMQTreasureDatabase.TREASURE_SIZE > len(self.rom_data):
			return None
		
		# Read treasure data
		map_id = self.rom_data[offset]
		x = self.rom_data[offset + 1]
		y = self.rom_data[offset + 2]
		item_id = self.rom_data[offset + 3]
		gp_amount = struct.unpack_from('<H', self.rom_data, offset + 4)[0]
		flags = self.rom_data[offset + 6]
		required_item = self.rom_data[offset + 7]
		
		# Decode flags
		is_hidden = (flags & 0x01) != 0
		is_mimic = (flags & 0x02) != 0
		
		# Read opened flag
		flag_offset = FFMQTreasureDatabase.TREASURE_FLAGS_OFFSET + (chest_id // 8)
		flag_bit = chest_id % 8
		is_opened = False
		if flag_offset < len(self.rom_data):
			flag_byte = self.rom_data[flag_offset]
			is_opened = (flag_byte & (1 << flag_bit)) != 0
		
		# Determine treasure type
		treasure_type = TreasureType.ITEM
		if is_mimic:
			treasure_type = TreasureType.MIMIC
		elif gp_amount > 0 and item_id == 0xFF:
			treasure_type = TreasureType.GP
		elif FFMQTreasureDatabase.is_key_item(item_id):
			treasure_type = TreasureType.KEY_ITEM
		
		# Skip invalid treasures
		if map_id == 0xFF:
			return None
		
		treasure = Treasure(
			chest_id=chest_id,
			map_id=map_id,
			x=x,
			y=y,
			treasure_type=treasure_type,
			item_id=item_id if item_id != 0xFF else 0,
			item_name=FFMQTreasureDatabase.get_item_name(item_id) if item_id != 0xFF else "",
			gp_amount=gp_amount,
			is_hidden=is_hidden,
			is_opened=is_opened,
			is_mimic=is_mimic,
			required_item=required_item if required_item != 0xFF else 0
		)
		
		return treasure
	
	def list_treasures(self, map_id: Optional[int] = None, 
					   treasure_type: Optional[TreasureType] = None) -> List[Treasure]:
		"""List all treasures, optionally filtered"""
		treasures = []
		
		for i in range(FFMQTreasureDatabase.NUM_TREASURES):
			treasure = self.extract_treasure(i)
			
			if not treasure:
				continue
			
			if map_id is not None and treasure.map_id != map_id:
				continue
			
			if treasure_type and treasure.treasure_type != treasure_type:
				continue
			
			treasures.append(treasure)
		
		return treasures
	
	def modify_treasure(self, chest_id: int, item_id: Optional[int] = None,
						gp_amount: Optional[int] = None, hidden: Optional[bool] = None,
						mimic: Optional[bool] = None) -> bool:
		"""Modify treasure chest"""
		if chest_id >= FFMQTreasureDatabase.NUM_TREASURES:
			return False
		
		offset = FFMQTreasureDatabase.TREASURE_DATA_OFFSET + (chest_id * FFMQTreasureDatabase.TREASURE_SIZE)
		
		if offset + FFMQTreasureDatabase.TREASURE_SIZE > len(self.rom_data):
			return False
		
		# Modify item
		if item_id is not None:
			self.rom_data[offset + 3] = item_id
			if self.verbose:
				item_name = FFMQTreasureDatabase.get_item_name(item_id)
				print(f"✓ Set chest {chest_id} to contain {item_name}")
		
		# Modify GP
		if gp_amount is not None:
			struct.pack_into('<H', self.rom_data, offset + 4, gp_amount)
			if item_id is None:
				self.rom_data[offset + 3] = 0xFF  # Clear item ID for GP
			if self.verbose:
				print(f"✓ Set chest {chest_id} to contain {gp_amount} GP")
		
		# Modify flags
		flags = self.rom_data[offset + 6]
		
		if hidden is not None:
			if hidden:
				flags |= 0x01
			else:
				flags &= ~0x01
		
		if mimic is not None:
			if mimic:
				flags |= 0x02
			else:
				flags &= ~0x02
		
		if hidden is not None or mimic is not None:
			self.rom_data[offset + 6] = flags
			if self.verbose:
				print(f"✓ Updated flags for chest {chest_id}")
		
		return True
	
	def randomize_treasures(self, seed: int = 0, preserve_key_items: bool = True) -> int:
		"""Randomize treasure contents"""
		if seed:
			random.seed(seed)
		
		# Get all treasures
		treasures = self.list_treasures()
		
		# Separate key items and regular items
		key_treasures = [t for t in treasures if t.treasure_type == TreasureType.KEY_ITEM]
		regular_treasures = [t for t in treasures if t.treasure_type in [TreasureType.ITEM, TreasureType.GP]]
		
		count = 0
		
		# Randomize regular treasures
		available_items = list(range(0, 60))  # Items 0-59
		gp_amounts = [50, 100, 200, 500, 1000, 2000, 5000]
		
		for treasure in regular_treasures:
			# Skip mimics
			if treasure.is_mimic:
				continue
			
			# 70% chance for item, 30% for GP
			if random.random() < 0.7:
				item_id = random.choice(available_items)
				self.modify_treasure(treasure.chest_id, item_id=item_id, gp_amount=0)
			else:
				gp = random.choice(gp_amounts)
				self.modify_treasure(treasure.chest_id, item_id=0xFF, gp_amount=gp)
			
			count += 1
		
		# Optionally shuffle key item locations
		if not preserve_key_items and len(key_treasures) > 1:
			key_item_ids = [t.item_id for t in key_treasures]
			random.shuffle(key_item_ids)
			
			for treasure, new_item_id in zip(key_treasures, key_item_ids):
				self.modify_treasure(treasure.chest_id, item_id=new_item_id)
				count += 1
		
		if self.verbose:
			print(f"✓ Randomized {count} treasures (seed: {seed})")
		
		return count
	
	def export_json(self, output_path: Path) -> None:
		"""Export treasure database to JSON"""
		treasures = self.list_treasures()
		
		data = {
			'treasures': [t.to_dict() for t in treasures],
			'treasure_count': len(treasures)
		}
		
		with open(output_path, 'w') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported {len(treasures)} treasures to {output_path}")
	
	def generate_treasure_map(self, output_path: Path) -> None:
		"""Generate HTML treasure map visualization"""
		treasures = self.list_treasures()
		
		# Group by map
		by_map: Dict[int, List[Treasure]] = {}
		for treasure in treasures:
			if treasure.map_id not in by_map:
				by_map[treasure.map_id] = []
			by_map[treasure.map_id].append(treasure)
		
		html = ['<!DOCTYPE html>', '<html>', '<head>',
				'<title>FFMQ Treasure Map</title>',
				'<style>',
				'body { font-family: monospace; background: #1a1a1a; color: #fff; margin: 20px; }',
				'h1 { color: #ffd700; }',
				'h2 { color: #87ceeb; margin-top: 30px; }',
				'.treasure-list { background: #2a2a2a; padding: 15px; margin: 10px 0; border-radius: 5px; }',
				'.treasure { padding: 5px; margin: 3px 0; border-left: 3px solid #555; padding-left: 10px; }',
				'.treasure.key-item { border-left-color: #ffd700; background: #3a3a00; }',
				'.treasure.gp { border-left-color: #4caf50; }',
				'.treasure.mimic { border-left-color: #f44336; background: #3a0000; }',
				'.treasure.hidden { opacity: 0.6; font-style: italic; }',
				'.location { color: #888; }',
				'</style>',
				'</head>', '<body>',
				'<h1>🗺️ FFMQ Treasure Map</h1>']
		
		for map_id in sorted(by_map.keys()):
			map_name = FFMQTreasureDatabase.get_map_name(map_id)
			map_treasures = by_map[map_id]
			
			html.append(f'<h2>{map_name} ({len(map_treasures)} treasures)</h2>')
			html.append('<div class="treasure-list">')
			
			for treasure in sorted(map_treasures, key=lambda t: (t.y, t.x)):
				css_classes = ['treasure']
				if treasure.treasure_type == TreasureType.KEY_ITEM:
					css_classes.append('key-item')
				elif treasure.treasure_type == TreasureType.GP:
					css_classes.append('gp')
				elif treasure.treasure_type == TreasureType.MIMIC:
					css_classes.append('mimic')
				if treasure.is_hidden:
					css_classes.append('hidden')
				
				content = ""
				if treasure.treasure_type == TreasureType.GP:
					content = f"💰 {treasure.gp_amount} GP"
				elif treasure.treasure_type == TreasureType.MIMIC:
					content = "⚔️ MIMIC!"
				elif treasure.treasure_type == TreasureType.KEY_ITEM:
					content = f"🔑 {treasure.item_name}"
				else:
					content = f"📦 {treasure.item_name}"
				
				hidden_str = " [HIDDEN]" if treasure.is_hidden else ""
				opened_str = " ✓" if treasure.is_opened else ""
				
				html.append(f'<div class="{" ".join(css_classes)}">')
				html.append(f'  {content}{hidden_str}{opened_str}')
				html.append(f'  <span class="location">@ ({treasure.x}, {treasure.y})</span>')
				html.append('</div>')
			
			html.append('</div>')
		
		html.extend(['</body>', '</html>'])
		
		with open(output_path, 'w') as f:
			f.write('\n'.join(html))
		
		if self.verbose:
			print(f"✓ Generated treasure map HTML: {output_path}")
	
	def save_rom(self, output_path: Optional[Path] = None) -> None:
		"""Save modified ROM"""
		save_path = output_path or self.rom_path
		
		with open(save_path, 'wb') as f:
			f.write(self.rom_data)
		
		if self.verbose:
			print(f"✓ Saved ROM to {save_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Treasure Editor')
	parser.add_argument('rom', type=str, help='FFMQ ROM file')
	parser.add_argument('--list-treasures', action='store_true', help='List all treasures')
	parser.add_argument('--list-map', type=int, help='List treasures for map')
	parser.add_argument('--type', type=str, 
						choices=['item', 'gp', 'key_item', 'mimic'],
						help='Filter by treasure type')
	parser.add_argument('--show-treasure', type=int, help='Show treasure details')
	parser.add_argument('--edit-treasure', type=int, help='Edit treasure')
	parser.add_argument('--item', type=int, help='Item ID')
	parser.add_argument('--gp', type=int, help='GP amount')
	parser.add_argument('--hidden', action='store_true', help='Set hidden flag')
	parser.add_argument('--visible', action='store_true', help='Clear hidden flag')
	parser.add_argument('--mimic', action='store_true', help='Set mimic flag')
	parser.add_argument('--randomize', action='store_true', help='Randomize treasures')
	parser.add_argument('--seed', type=int, default=0, help='Random seed')
	parser.add_argument('--preserve-keys', action='store_true', default=True,
						help='Preserve key item locations (default)')
	parser.add_argument('--shuffle-keys', action='store_true',
						help='Shuffle key item locations')
	parser.add_argument('--export', type=str, help='Export to JSON')
	parser.add_argument('--generate-map', type=str, help='Generate treasure map HTML')
	parser.add_argument('--save', type=str, help='Save modified ROM')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FFMQTreasureEditor(Path(args.rom), verbose=args.verbose)
	
	# List treasures
	if args.list_treasures:
		treasure_type = TreasureType(args.type) if args.type else None
		treasures = editor.list_treasures(treasure_type=treasure_type)
		
		type_filter = f" ({args.type})" if args.type else ""
		print(f"\nFFMQ Treasures{type_filter} ({len(treasures)}):\n")
		
		for treasure in treasures[:100]:
			map_name = FFMQTreasureDatabase.get_map_name(treasure.map_id)
			
			content = ""
			if treasure.treasure_type == TreasureType.GP:
				content = f"{treasure.gp_amount} GP"
			elif treasure.treasure_type == TreasureType.MIMIC:
				content = "MIMIC"
			else:
				content = treasure.item_name
			
			flags = []
			if treasure.is_hidden:
				flags.append("hidden")
			if treasure.is_mimic:
				flags.append("mimic")
			if treasure.is_opened:
				flags.append("opened")
			
			flag_str = f" [{', '.join(flags)}]" if flags else ""
			
			print(f"  {treasure.chest_id:3d}: {content:<25} @ {map_name:<20} "
				  f"({treasure.x:3d},{treasure.y:3d}){flag_str}")
		
		if len(treasures) > 100:
			print(f"\n  ... and {len(treasures) - 100} more treasures")
		
		return 0
	
	# List map
	if args.list_map is not None:
		treasures = editor.list_treasures(map_id=args.list_map)
		map_name = FFMQTreasureDatabase.get_map_name(args.list_map)
		
		print(f"\nTreasures in {map_name} ({len(treasures)}):\n")
		
		for treasure in treasures:
			content = ""
			if treasure.treasure_type == TreasureType.GP:
				content = f"💰 {treasure.gp_amount} GP"
			elif treasure.treasure_type == TreasureType.MIMIC:
				content = "⚔️ MIMIC"
			elif treasure.treasure_type == TreasureType.KEY_ITEM:
				content = f"🔑 {treasure.item_name}"
			else:
				content = f"📦 {treasure.item_name}"
			
			print(f"  ({treasure.x:3d},{treasure.y:3d}): {content}")
		
		return 0
	
	# Show treasure
	if args.show_treasure is not None:
		treasure = editor.extract_treasure(args.show_treasure)
		
		if treasure:
			print(f"\n=== Treasure Chest {treasure.chest_id} ===\n")
			print(f"Map: {FFMQTreasureDatabase.get_map_name(treasure.map_id)}")
			print(f"Position: ({treasure.x}, {treasure.y})")
			print(f"Type: {treasure.treasure_type.value}")
			
			if treasure.treasure_type == TreasureType.GP:
				print(f"Contents: {treasure.gp_amount} GP")
			elif treasure.treasure_type == TreasureType.MIMIC:
				print(f"Contents: MIMIC (battle)")
			else:
				print(f"Contents: {treasure.item_name}")
			
			print(f"Hidden: {treasure.is_hidden}")
			print(f"Opened: {treasure.is_opened}")
			print(f"Mimic: {treasure.is_mimic}")
			
			if treasure.required_item > 0:
				req_item = FFMQTreasureDatabase.get_item_name(treasure.required_item)
				print(f"Requires: {req_item}")
		else:
			print(f"❌ Treasure {args.show_treasure} not found")
		
		return 0
	
	# Edit treasure
	if args.edit_treasure is not None:
		hidden = None
		if args.hidden:
			hidden = True
		elif args.visible:
			hidden = False
		
		success = editor.modify_treasure(args.edit_treasure, item_id=args.item,
										  gp_amount=args.gp, hidden=hidden,
										  mimic=args.mimic if args.mimic else None)
		
		if success and args.save:
			editor.save_rom(Path(args.save))
		
		return 0
	
	# Randomize
	if args.randomize:
		preserve = not args.shuffle_keys
		count = editor.randomize_treasures(seed=args.seed, preserve_key_items=preserve)
		print(f"\n✅ Randomized {count} treasures")
		
		if args.save:
			editor.save_rom(Path(args.save))
		
		return 0
	
	# Export
	if args.export:
		editor.export_json(Path(args.export))
		return 0
	
	# Generate map
	if args.generate_map:
		editor.generate_treasure_map(Path(args.generate_map))
		return 0
	
	print("Use --list-treasures, --list-map, --show-treasure, --edit-treasure,")
	print("     --randomize, --export, or --generate-map")
	return 0


if __name__ == '__main__':
	exit(main())
