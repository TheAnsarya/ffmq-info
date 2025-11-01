#!/usr/bin/env python3
"""
FFMQ Item Data Extractor
Extracts weapons, armor, helmets, shields, accessories, and items from ROM
"""

import struct
import json
import csv
from pathlib import Path

class FFMQItemExtractor:
	"""Extract item data from Final Fantasy Mystic Quest ROM"""
	
	# Item data locations in ROM
	ITEM_DATA = {
		'weapons': {
			'address': 0x066000,  # Weapon stats table
			'count': 15,
			'size': 16,  # bytes per weapon
		},
		'armor': {
			'address': 0x066100,  # Armor stats table
			'count': 7,
			'size': 16,
		},
		'helmets': {
			'address': 0x066180,  # Helmet stats table
			'count': 7,
			'size': 16,
		},
		'shields': {
			'address': 0x066200,  # Shield stats table
			'count': 7,
			'size': 16,
		},
		'accessories': {
			'address': 0x066280,  # Accessory stats table
			'count': 11,
			'size': 16,
		},
		'consumables': {
			'address': 0x066380,  # Consumable items
			'count': 20,
			'size': 8,
		},
	}
	
	def __init__(self, rom_path):
		"""Initialize with ROM file"""
		self.rom_path = Path(rom_path)
		with open(rom_path, 'rb') as f:
			self.rom_data = f.read()
	
	def extract_weapon(self, offset):
		"""Extract weapon data"""
		data = self.rom_data[offset:offset+16]
		return {
			'attack': data[0],
			'accuracy': data[1],
			'element': data[2],  # 0=none, 1=fire, 2=water, 3=wind, 4=earth
			'special': data[3],  # Special effects
			'character_equip': data[4],  # Which character can equip (bitmask)
			'price': struct.unpack('<H', data[5:7])[0],
			'sell_price': struct.unpack('<H', data[7:9])[0],
			'flags': data[9],
			'unused': list(data[10:16]),
		}
	
	def extract_armor(self, offset):
		"""Extract armor/helmet/shield data"""
		data = self.rom_data[offset:offset+16]
		return {
			'defense': data[0],
			'evade': data[1],
			'element_resist': data[2],  # Element resistance
			'status_resist': data[3],  # Status resistance
			'character_equip': data[4],
			'price': struct.unpack('<H', data[5:7])[0],
			'sell_price': struct.unpack('<H', data[7:9])[0],
			'flags': data[9],
			'unused': list(data[10:16]),
		}
	
	def extract_accessory(self, offset):
		"""Extract accessory data"""
		data = self.rom_data[offset:offset+16]
		return {
			'effect_type': data[0],  # Type of effect
			'effect_value': data[1],  # Effect magnitude
			'status_grant': data[2],  # Status effects granted
			'status_immune': data[3],  # Status immunities
			'character_equip': data[4],
			'price': struct.unpack('<H', data[5:7])[0],
			'sell_price': struct.unpack('<H', data[7:9])[0],
			'flags': data[9],
			'unused': list(data[10:16]),
		}
	
	def extract_consumable(self, offset):
		"""Extract consumable item data"""
		data = self.rom_data[offset:offset+8]
		return {
			'effect': data[0],  # Item effect
			'power': data[1],  # Effect power
			'target': data[2],  # Target type
			'price': struct.unpack('<H', data[3:5])[0],
			'sell_price': struct.unpack('<H', data[5:7])[0],
			'flags': data[7],
		}
	
	def extract_all_items(self):
		"""Extract all item data from ROM"""
		items = {}
		
		# Extract weapons
		items['weapons'] = []
		for i in range(self.ITEM_DATA['weapons']['count']):
			offset = self.ITEM_DATA['weapons']['address'] + (i * self.ITEM_DATA['weapons']['size'])
			weapon = self.extract_weapon(offset)
			weapon['id'] = i
			items['weapons'].append(weapon)
		
		# Extract armor
		items['armor'] = []
		for i in range(self.ITEM_DATA['armor']['count']):
			offset = self.ITEM_DATA['armor']['address'] + (i * self.ITEM_DATA['armor']['size'])
			armor = self.extract_armor(offset)
			armor['id'] = i
			items['armor'].append(armor)
		
		# Extract helmets
		items['helmets'] = []
		for i in range(self.ITEM_DATA['helmets']['count']):
			offset = self.ITEM_DATA['helmets']['address'] + (i * self.ITEM_DATA['helmets']['size'])
			helmet = self.extract_armor(offset)
			helmet['id'] = i
			items['helmets'].append(helmet)
		
		# Extract shields
		items['shields'] = []
		for i in range(self.ITEM_DATA['shields']['count']):
			offset = self.ITEM_DATA['shields']['address'] + (i * self.ITEM_DATA['shields']['size'])
			shield = self.extract_armor(offset)
			shield['id'] = i
			items['shields'].append(shield)
		
		# Extract accessories
		items['accessories'] = []
		for i in range(self.ITEM_DATA['accessories']['count']):
			offset = self.ITEM_DATA['accessories']['address'] + (i * self.ITEM_DATA['accessories']['size'])
			accessory = self.extract_accessory(offset)
			accessory['id'] = i
			items['accessories'].append(accessory)
		
		# Extract consumables
		items['consumables'] = []
		for i in range(self.ITEM_DATA['consumables']['count']):
			offset = self.ITEM_DATA['consumables']['address'] + (i * self.ITEM_DATA['consumables']['size'])
			consumable = self.extract_consumable(offset)
			consumable['id'] = i
			items['consumables'].append(consumable)
		
		return items
	
	def save_json(self, items, output_path):
		"""Save items as JSON"""
		output_path = Path(output_path)
		output_path.parent.mkdir(parents=True, exist_ok=True)
		
		with open(output_path, 'w') as f:
			json.dump(items, f, indent=2)
		
		print(f"✓ Saved JSON: {output_path}")
	
	def save_csv(self, items, output_dir):
		"""Save items as CSV (one file per category)"""
		output_dir = Path(output_dir)
		output_dir.mkdir(parents=True, exist_ok=True)
		
		for category, item_list in items.items():
			if not item_list:
				continue
			
			csv_path = output_dir / f"{category}.csv"
			fieldnames = ['id'] + [k for k in item_list[0].keys() if k != 'id']
			
			with open(csv_path, 'w', newline='') as f:
				writer = csv.DictWriter(f, fieldnames=fieldnames)
				writer.writeheader()
				writer.writerows(item_list)
			
			print(f"✓ Saved CSV: {csv_path}")
	
	def save_asm(self, items, output_path):
		"""Save items as ASM data"""
		output_path = Path(output_path)
		output_path.parent.mkdir(parents=True, exist_ok=True)
		
		with open(output_path, 'w') as f:
			f.write("; Final Fantasy Mystic Quest - Item Data\n")
			f.write("; Extracted from ROM\n\n")
			
			for category, item_list in items.items():
				f.write(f"\n; {category.upper()} ({len(item_list)} entries)\n")
				f.write(f"{category}_data:\n")
				
				for item in item_list:
					f.write(f"  ; {category}_{item['id']:02d}\n")
					
					if category == 'consumables':
						f.write(f"  db ${item['effect']:02X}, ${item['power']:02X}, ${item['target']:02X}\n")
						f.write(f"  dw ${item['price']:04X}, ${item['sell_price']:04X}\n")
						f.write(f"  db ${item['flags']:02X}\n")
					else:
						# Full 16-byte format
						if category == 'weapons':
							f.write(f"  db ${item['attack']:02X}, ${item['accuracy']:02X}, ")
							f.write(f"${item['element']:02X}, ${item['special']:02X}, ${item['character_equip']:02X}\n")
						elif category == 'accessories':
							f.write(f"  db ${item['effect_type']:02X}, ${item['effect_value']:02X}, ")
							f.write(f"${item['status_grant']:02X}, ${item['status_immune']:02X}, ${item['character_equip']:02X}\n")
						else:  # armor/helmets/shields
							f.write(f"  db ${item['defense']:02X}, ${item['evade']:02X}, ")
							f.write(f"${item['element_resist']:02X}, ${item['status_resist']:02X}, ${item['character_equip']:02X}\n")
						
						f.write(f"  dw ${item['price']:04X}, ${item['sell_price']:04X}\n")
						f.write(f"  db ${item['flags']:02X}\n")
						if 'unused' in item:
							unused_bytes = ', '.join(f"${b:02X}" for b in item['unused'])
							f.write(f"  db {unused_bytes}\n")
					
					f.write("\n")
		
		print(f"✓ Saved ASM: {output_path}")


def main():
	import sys
	
	if len(sys.argv) < 3:
		print("Usage: python extract_items.py <rom_file> <output_dir>")
		print()
		print("Example:")
		print('  python extract_items.py "roms/FFMQ.sfc" "assets/data/"')
		sys.exit(1)
	
	rom_path = sys.argv[1]
	output_dir = sys.argv[2]
	
	# Expand ~ in paths
	rom_path = Path(rom_path).expanduser()
	output_dir = Path(output_dir).expanduser()
	
	print(f"Extracting item data from: {rom_path}")
	print(f"Output directory: {output_dir}")
	print()
	
	extractor = FFMQItemExtractor(rom_path)
	items = extractor.extract_all_items()
	
	# Count total items
	total = sum(len(item_list) for item_list in items.values())
	print(f"Extracted {total} items across {len(items)} categories:")
	for category, item_list in items.items():
		print(f"  {category}: {len(item_list)} entries")
	print()
	
	# Save in multiple formats
	extractor.save_json(items, output_dir / 'items.json')
	extractor.save_csv(items, output_dir / 'items')
	extractor.save_asm(items, output_dir / 'items.asm')
	
	print()
	print("✓ Item extraction complete!")


if __name__ == '__main__':
	main()
