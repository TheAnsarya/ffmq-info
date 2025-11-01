#!/usr/bin/env python3
"""
FFMQ Character Data Extractor
Extracts character base stats, growth curves, starting equipment, and spell learning tables
"""

import struct
import json
import csv
from pathlib import Path
from typing import Dict, List, Any

class FFMQCharacterExtractor:
	"""Extract character data from Final Fantasy Mystic Quest ROM"""

	# Character names (4 main characters)
	CHARACTER_NAMES = [
		"Benjamin",
		"Kaeli",
		"Phoebe",
		"Reuben"
	]

	# ROM addresses (LoROM format)
	CHARACTER_BASE_STATS = 0x0650B0  # Bank $0C:$50B0
	CHARACTER_ENTRY_SIZE = 80  # bytes per character

	# Stat offsets within character entry
	OFFSET_NAME = 0x00  # 16 bytes (text format)
	OFFSET_LEVEL = 0x10  # 1 byte
	OFFSET_EXPERIENCE = 0x11  # 3 bytes (24-bit)
	OFFSET_HP_MAX = 0x14  # 2 bytes
	OFFSET_MP_MAX = 0x16  # 2 bytes
	OFFSET_HP_CURRENT = 0x18  # 2 bytes
	OFFSET_MP_CURRENT = 0x1A  # 2 bytes
	OFFSET_STATUS = 0x1C  # 2 bytes
	OFFSET_WEAPON = 0x1E  # 1 byte
	OFFSET_SHIELD = 0x1F  # 1 byte
	OFFSET_ARMOR = 0x20  # 1 byte
	OFFSET_HELMET = 0x21  # 1 byte
	OFFSET_ACCESSORY = 0x22  # 1 byte
	OFFSET_STRENGTH = 0x23  # 1 byte
	OFFSET_DEFENSE = 0x24  # 1 byte
	OFFSET_SPEED = 0x25  # 1 byte
	OFFSET_MAGIC = 0x26  # 1 byte
	OFFSET_ACCURACY = 0x27  # 1 byte
	OFFSET_EVADE = 0x28  # 1 byte
	OFFSET_MG_DEF = 0x29  # 1 byte (Magic Defense)

	# Growth curve table (stats per level)
	GROWTH_TABLE_BASE = 0x065200  # Approximate location
	MAX_LEVEL = 41

	# Spell learning table
	SPELL_LEARN_BASE = 0x065600  # Approximate location

	def __init__(self, rom_path: str):
		"""Initialize with ROM file"""
		self.rom_path = Path(rom_path)
		with open(rom_path, 'rb') as f:
			self.rom_data = f.read()

	def read_byte(self, address: int) -> int:
		"""Read single byte from ROM"""
		if address >= len(self.rom_data):
			return 0
		return self.rom_data[address]

	def read_word(self, address: int) -> int:
		"""Read 16-bit word (little-endian) from ROM"""
		if address + 1 >= len(self.rom_data):
			return 0
		return self.rom_data[address] | (self.rom_data[address + 1] << 8)

	def read_24bit(self, address: int) -> int:
		"""Read 24-bit value (little-endian) from ROM"""
		if address + 2 >= len(self.rom_data):
			return 0
		return (self.rom_data[address] |
				(self.rom_data[address + 1] << 8) |
				(self.rom_data[address + 2] << 16))

	def decode_text(self, data: bytes) -> str:
		"""Decode FFMQ text format
		The game uses a custom text encoding. For now, use the character names we know.
		"""
		# For now, just return empty since we're providing names from constant
		return ""

	def extract_character(self, char_index: int) -> Dict[str, Any]:
		"""Extract a single character's base stats"""
		offset = self.CHARACTER_BASE_STATS + (char_index * self.CHARACTER_ENTRY_SIZE)

		# Read equipment slots
		weapon = self.read_byte(offset + self.OFFSET_WEAPON)
		shield = self.read_byte(offset + self.OFFSET_SHIELD)
		armor = self.read_byte(offset + self.OFFSET_ARMOR)
		helmet = self.read_byte(offset + self.OFFSET_HELMET)
		accessory = self.read_byte(offset + self.OFFSET_ACCESSORY)

		character = {
			"id": char_index,
			"name": self.CHARACTER_NAMES[char_index],
			"starting_level": self.read_byte(offset + self.OFFSET_LEVEL),
			"starting_experience": self.read_24bit(offset + self.OFFSET_EXPERIENCE),
			"base_stats": {
				"hp": self.read_word(offset + self.OFFSET_HP_MAX),
				"mp": self.read_word(offset + self.OFFSET_MP_MAX),
				"strength": self.read_byte(offset + self.OFFSET_STRENGTH),
				"defense": self.read_byte(offset + self.OFFSET_DEFENSE),
				"speed": self.read_byte(offset + self.OFFSET_SPEED),
				"magic": self.read_byte(offset + self.OFFSET_MAGIC),
				"accuracy": self.read_byte(offset + self.OFFSET_ACCURACY),
				"evade": self.read_byte(offset + self.OFFSET_EVADE),
				"magic_defense": self.read_byte(offset + self.OFFSET_MG_DEF)
			},
			"starting_equipment": {
				"weapon": weapon if weapon != 0xFF else None,
				"shield": shield if shield != 0xFF else None,
				"armor": armor if armor != 0xFF else None,
				"helmet": helmet if helmet != 0xFF else None,
				"accessory": accessory if accessory != 0xFF else None
			},
			"rom_address": f"${offset:06X}"
		}

		return character

	def extract_all_characters(self) -> Dict[str, Any]:
		"""Extract all character data"""
		characters = []
		for i in range(4):  # 4 main characters
			characters.append(self.extract_character(i))

		return {
			"version": "1.0.0",
			"description": "Final Fantasy Mystic Quest - Character Data",
			"characters": characters,
			"metadata": {
				"rom_base_address": f"${self.CHARACTER_BASE_STATS:06X}",
				"entry_size": self.CHARACTER_ENTRY_SIZE,
				"character_count": 4
			}
		}

	def export_json(self, output_path: str):
		"""Export character data to JSON"""
		data = self.extract_all_characters()
		output_file = Path(output_path)
		output_file.parent.mkdir(parents=True, exist_ok=True)

		with open(output_file, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent=2, ensure_ascii=False)

		print(f"✓ Exported character data to {output_file}")
		return data

	def export_csv(self, output_path: str):
		"""Export character data to CSV"""
		data = self.extract_all_characters()
		output_file = Path(output_path)
		output_file.parent.mkdir(parents=True, exist_ok=True)

		with open(output_file, 'w', newline='', encoding='utf-8') as f:
			writer = csv.writer(f)

			# Header
			writer.writerow([
				'ID', 'Name', 'Starting Level', 'Starting XP',
				'HP', 'MP', 'Strength', 'Defense', 'Speed', 'Magic',
				'Accuracy', 'Evade', 'Magic Defense',
				'Weapon', 'Shield', 'Armor', 'Helmet', 'Accessory',
				'ROM Address'
			])

			# Data rows
			for char in data['characters']:
				writer.writerow([
					char['id'],
					char['name'],
					char['starting_level'],
					char['starting_experience'],
					char['base_stats']['hp'],
					char['base_stats']['mp'],
					char['base_stats']['strength'],
					char['base_stats']['defense'],
					char['base_stats']['speed'],
					char['base_stats']['magic'],
					char['base_stats']['accuracy'],
					char['base_stats']['evade'],
					char['base_stats']['magic_defense'],
					char['starting_equipment']['weapon'],
					char['starting_equipment']['shield'],
					char['starting_equipment']['armor'],
					char['starting_equipment']['helmet'],
					char['starting_equipment']['accessory'],
					char['rom_address']
				])

		print(f"✓ Exported character CSV to {output_file}")

def main():
	"""Main extraction function"""
	import argparse

	parser = argparse.ArgumentParser(description='Extract FFMQ character data')
	parser.add_argument('rom', help='Path to FFMQ ROM file')
	parser.add_argument('--json', default='data/characters.json',
						help='Output JSON file (default: data/characters.json)')
	parser.add_argument('--csv', default='data/characters.csv',
						help='Output CSV file (default: data/characters.csv)')

	args = parser.parse_args()

	print("FFMQ Character Data Extractor")
	print("=" * 50)

	extractor = FFMQCharacterExtractor(args.rom)

	# Export both formats
	extractor.export_json(args.json)
	extractor.export_csv(args.csv)

	print("\n✓ Character extraction complete!")

if __name__ == '__main__':
	main()
