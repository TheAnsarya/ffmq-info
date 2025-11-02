#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest - Map Data Extractor
Extracts map layouts, collision data, events, NPCs, chests, and encounters
"""

import sys
import json
import csv
from pathlib import Path
from typing import Dict, List, Optional, Tuple

class MapExtractor:
	"""Extract map data from FFMQ ROM"""

	# Known map data locations (approximate - need verification)
	MAP_DATA = {
		'map_headers': {
			'address': 0x028000,  # Map header table
			'count': 128,
			'entry_size': 16
		},
		'collision_data': {
			'address': 0x030000,  # Collision map data
			'count': 128
		},
		'npc_data': {
			'address': 0x038000,  # NPC placement data
			'count': 256
		},
		'chest_data': {
			'address': 0x03C000,  # Chest locations and contents
			'count': 256
		},
		'encounter_data': {
			'address': 0x03E000,  # Enemy encounter zones
			'count': 128
		},
		'event_triggers': {
			'address': 0x040000,  # Event trigger data
			'count': 512
		}
	}

	# Map types
	MAP_TYPES = {
		0x00: 'Overworld',
		0x01: 'Town',
		0x02: 'Dungeon',
		0x03: 'Battle',
		0x04: 'Special'
	}

	def __init__(self, rom_path: str):
		"""Initialize with ROM path"""
		self.rom_path = Path(rom_path)
		self.rom_data = bytearray()

	def load_rom(self) -> bool:
		"""Load ROM file"""
		if not self.rom_path.exists():
			print(f"❌ ROM not found: {self.rom_path}")
			return False

		with open(self.rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())

		print(f"✓ Loaded ROM: {self.rom_path.name} ({len(self.rom_data):,} bytes)")
		return True

	def read_byte(self, address: int) -> int:
		"""Read a single byte from ROM"""
		if address < len(self.rom_data):
			return self.rom_data[address]
		return 0

	def read_word(self, address: int) -> int:
		"""Read a 16-bit word (little-endian) from ROM"""
		if address + 1 < len(self.rom_data):
			return self.rom_data[address] | (self.rom_data[address + 1] << 8)
		return 0

	def extract_map_headers(self) -> List[Dict]:
		"""Extract map header information"""
		config = self.MAP_DATA['map_headers']
		address = config['address']
		count = config['count']
		entry_size = config['entry_size']

		print(f"\n📍 Extracting map headers from ${address:06X}...")

		maps = []

		for i in range(count):
			base_addr = address + (i * entry_size)

			# Parse map header (structure to be verified)
			map_data = {
				'id': i,
				'type': self.MAP_TYPES.get(self.read_byte(base_addr), 'Unknown'),
				'width': self.read_byte(base_addr + 1),
				'height': self.read_byte(base_addr + 2),
				'tileset_id': self.read_byte(base_addr + 3),
				'palette_id': self.read_byte(base_addr + 4),
				'music_id': self.read_byte(base_addr + 5),
				'flags': self.read_byte(base_addr + 6),
				'layout_ptr': self.read_word(base_addr + 8),
				'collision_ptr': self.read_word(base_addr + 10),
				'events_ptr': self.read_word(base_addr + 12),
				'address': f"${base_addr:06X}"
			}

			# Skip empty entries
			if map_data['width'] > 0 and map_data['height'] > 0:
				maps.append(map_data)

		print(f"  Extracted {len(maps)} map headers")
		return maps

	def extract_npc_data(self) -> List[Dict]:
		"""Extract NPC placement and dialogue data"""
		config = self.MAP_DATA['npc_data']
		address = config['address']
		count = config['count']

		print(f"\n👥 Extracting NPC data from ${address:06X}...")

		npcs = []

		for i in range(count):
			base_addr = address + (i * 16)  # Assume 16 bytes per NPC

			npc_data = {
				'id': i,
				'map_id': self.read_byte(base_addr),
				'x': self.read_byte(base_addr + 1),
				'y': self.read_byte(base_addr + 2),
				'sprite_id': self.read_byte(base_addr + 3),
				'dialogue_id': self.read_word(base_addr + 4),
				'movement_type': self.read_byte(base_addr + 6),
				'flags': self.read_byte(base_addr + 7),
				'address': f"${base_addr:06X}"
			}

			# Skip empty entries
			if npc_data['map_id'] != 0xFF:
				npcs.append(npc_data)

		print(f"  Extracted {len(npcs)} NPCs")
		return npcs

	def extract_chest_data(self) -> List[Dict]:
		"""Extract chest locations and contents"""
		config = self.MAP_DATA['chest_data']
		address = config['address']
		count = config['count']

		print(f"\n💰 Extracting chest data from ${address:06X}...")

		chests = []

		for i in range(count):
			base_addr = address + (i * 8)  # Assume 8 bytes per chest

			chest_data = {
				'id': i,
				'map_id': self.read_byte(base_addr),
				'x': self.read_byte(base_addr + 1),
				'y': self.read_byte(base_addr + 2),
				'item_id': self.read_byte(base_addr + 3),
				'quantity': self.read_byte(base_addr + 4),
				'flags': self.read_byte(base_addr + 5),
				'address': f"${base_addr:06X}"
			}

			# Skip empty entries
			if chest_data['map_id'] != 0xFF:
				chests.append(chest_data)

		print(f"  Extracted {len(chests)} chests")
		return chests

	def extract_encounter_data(self) -> List[Dict]:
		"""Extract enemy encounter zone data"""
		config = self.MAP_DATA['encounter_data']
		address = config['address']
		count = config['count']

		print(f"\n⚔️  Extracting encounter data from ${address:06X}...")

		encounters = []

		for i in range(count):
			base_addr = address + (i * 16)  # Assume 16 bytes per zone

			encounter_data = {
				'id': i,
				'map_id': self.read_byte(base_addr),
				'zone_x': self.read_byte(base_addr + 1),
				'zone_y': self.read_byte(base_addr + 2),
				'zone_width': self.read_byte(base_addr + 3),
				'zone_height': self.read_byte(base_addr + 4),
				'enemy_group': self.read_byte(base_addr + 5),
				'encounter_rate': self.read_byte(base_addr + 6),
				'battle_bg': self.read_byte(base_addr + 7),
				'address': f"${base_addr:06X}"
			}

			# Skip empty entries
			if encounter_data['map_id'] != 0xFF:
				encounters.append(encounter_data)

		print(f"  Extracted {len(encounters)} encounter zones")
		return encounters

	def extract_all(self) -> Dict[str, List[Dict]]:
		"""Extract all map data"""
		all_data = {}

		all_data['maps'] = self.extract_map_headers()
		all_data['npcs'] = self.extract_npc_data()
		all_data['chests'] = self.extract_chest_data()
		all_data['encounters'] = self.extract_encounter_data()

		return all_data

	def save_json(self, output_dir: str, map_data: Dict):
		"""Save map data to JSON files"""
		output_path = Path(output_dir)
		output_path.mkdir(parents=True, exist_ok=True)

		# Save comprehensive JSON
		json_file = output_path / 'maps_data.json'
		with open(json_file, 'w', encoding='utf-8') as f:
			json_output = {
				'version': '1.0.0',
				'game': 'Final Fantasy Mystic Quest',
				'note': 'Map data addresses are approximate and need verification',
				'data': map_data
			}
			json.dump(json_output, f, indent=2, ensure_ascii=False)

		print(f"\n💾 Saved JSON: {json_file}")

		# Save individual files for each category
		for category, data in map_data.items():
			category_file = output_path / f'{category}.json'
			with open(category_file, 'w', encoding='utf-8') as f:
				json.dump(data, f, indent=2, ensure_ascii=False)
			print(f"💾 Saved: {category_file}")

	def save_csv(self, output_dir: str, map_data: Dict):
		"""Save map data to CSV files"""
		output_path = Path(output_dir)
		output_path.mkdir(parents=True, exist_ok=True)

		# Save maps
		if map_data.get('maps'):
			csv_file = output_path / 'maps.csv'
			with open(csv_file, 'w', encoding='utf-8', newline='') as f:
				writer = csv.DictWriter(f, fieldnames=map_data['maps'][0].keys())
				writer.writeheader()
				writer.writerows(map_data['maps'])
			print(f"📊 Saved CSV: {csv_file}")

		# Save NPCs
		if map_data.get('npcs'):
			csv_file = output_path / 'npcs.csv'
			with open(csv_file, 'w', encoding='utf-8', newline='') as f:
				writer = csv.DictWriter(f, fieldnames=map_data['npcs'][0].keys())
				writer.writeheader()
				writer.writerows(map_data['npcs'])
			print(f"📊 Saved CSV: {csv_file}")

		# Save chests
		if map_data.get('chests'):
			csv_file = output_path / 'chests.csv'
			with open(csv_file, 'w', encoding='utf-8', newline='') as f:
				writer = csv.DictWriter(f, fieldnames=map_data['chests'][0].keys())
				writer.writeheader()
				writer.writerows(map_data['chests'])
			print(f"📊 Saved CSV: {csv_file}")

		# Save encounters
		if map_data.get('encounters'):
			csv_file = output_path / 'encounters.csv'
			with open(csv_file, 'w', encoding='utf-8', newline='') as f:
				writer = csv.DictWriter(f, fieldnames=map_data['encounters'][0].keys())
				writer.writeheader()
				writer.writerows(map_data['encounters'])
			print(f"📊 Saved CSV: {csv_file}")

	def generate_statistics(self, map_data: Dict) -> str:
		"""Generate map statistics report"""
		lines = []
		lines.append("="*80)
		lines.append(" Final Fantasy Mystic Quest - Map Data Statistics")
		lines.append("="*80)
		lines.append("")

		lines.append(f"Maps:       {len(map_data.get('maps', []))} total")
		lines.append(f"NPCs:       {len(map_data.get('npcs', []))} total")
		lines.append(f"Chests:     {len(map_data.get('chests', []))} total")
		lines.append(f"Encounters: {len(map_data.get('encounters', []))} encounter zones")
		lines.append("")

		# Map type breakdown
		if map_data.get('maps'):
			lines.append("Map Types:")
			lines.append("-"*80)
			type_counts = {}
			for m in map_data['maps']:
				map_type = m.get('type', 'Unknown')
				type_counts[map_type] = type_counts.get(map_type, 0) + 1

			for map_type, count in sorted(type_counts.items()):
				lines.append(f"  {map_type:12s}: {count:3d} maps")
			lines.append("")

		lines.append("="*80)

		return '\n'.join(lines)

def main():
	"""Main entry point"""
	if len(sys.argv) < 3:
		print("Usage: extract_maps.py <rom_file> <output_dir> [--format json,csv]")
		print("\nExtracts map data, NPCs, chests, and encounters from FFMQ ROM")
		print("\nOptions:")
		print("  --format <fmt>    Output formats: json,csv,all (default: all)")
		print("\nNote: Map data addresses are approximate and need verification")
		sys.exit(1)

	rom_file = sys.argv[1]
	output_dir = sys.argv[2]

	# Parse options
	output_formats = ['all']
	if '--format' in sys.argv:
		idx = sys.argv.index('--format')
		if idx + 1 < len(sys.argv):
			output_formats = sys.argv[idx + 1].split(',')

	print("="*80)
	print("Final Fantasy Mystic Quest - Map Data Extractor")
	print("="*80)
	print()
	print("⚠️  Note: Map data addresses are approximate and need verification")
	print("         Extracted data may need manual validation")
	print()

	# Extract map data
	extractor = MapExtractor(rom_file)

	if not extractor.load_rom():
		sys.exit(1)

	print("\nExtracting map data...")
	map_data = extractor.extract_all()

	# Determine output formats
	if 'all' in output_formats:
		output_formats = ['json', 'csv']

	print(f"\nSaving in formats: {', '.join(output_formats)}")

	if 'json' in output_formats:
		extractor.save_json(output_dir, map_data)

	if 'csv' in output_formats:
		extractor.save_csv(output_dir, map_data)

	# Generate statistics
	stats = extractor.generate_statistics(map_data)
	print()
	print(stats)

	# Save statistics
	output_path = Path(output_dir)
	stats_file = output_path / 'map_statistics.txt'
	stats_file.write_text(stats, encoding='utf-8')
	print(f"\n💾 Saved statistics: {stats_file}")

	print()
	print("="*80)
	print("Map extraction complete!")
	print("⚠️  Remember to verify extracted data against actual ROM structure")
	print("="*80)

if __name__ == '__main__':
	main()
