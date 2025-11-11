#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest - Spell Data Extractor
Extracts spell stats, power, effects, and targeting

ROM Address: $060F36 (Bank $0C, near item data)
Structure: 6 bytes per spell, 16 entries
Note: MP cost is always 1 (not stored in table)
	  Spell type derived from ID (White: 0-3, Black: 4-7, Wizard: 8-10)
"""

import sys
import json
import csv
from pathlib import Path
from typing import Dict, List, Optional

class SpellExtractor:
	"""Extract spell data from FFMQ ROM"""

	# Spell data location (RESEARCH COMPLETE - Found via ROM scanning)
	# Located in Bank $0C near item data
	# Pattern found by tools/find_spell_data.py scan
	SPELL_DATA_ADDRESS = 0x060F36  # Bank $0C - spell data table
	SPELL_COUNT = 16  # Estimated based on scan results
	SPELL_ENTRY_SIZE = 6  # Bytes per spell entry (confirmed by scan)

	# NOTE: Element information is NOT in the spell data table at $060F36
	# Elements appear to be hardcoded in spell execution code rather than stored in data
	# Byte 2 of the spell data is NOT the element field (verified by testing)
	# Keeping element constants for reference only
	ELEMENTS = {
		0x00: 'None',
		0x01: 'Fire',
		0x02: 'Water',
		0x03: 'Wind',
		0x04: 'Earth'
	}

	# Enemy type flags (bit flags for "strong against" system)
	# Spells have "strong against" and "weak against" flags like weapons/armor
	ENEMY_TYPE_FLAGS = {
		0x01: 'Beast',
		0x02: 'Plant',
		0x04: 'Undead',
		0x08: 'Dragon',
		0x10: 'Aquatic',
		0x20: 'Flying',
		0x40: 'Humanoid',
		0x80: 'Magical'
	}

	# Spell targets
	TARGETS = {
		0x00: 'Single Enemy',
		0x01: 'All Enemies',
		0x02: 'Self',
		0x03: 'Single Ally',
		0x04: 'All Allies'
	}

	# Spell types
	SPELL_TYPES = {
		0x00: 'Offensive',
		0x01: 'Healing',
		0x02: 'Status',
		0x03: 'Buff',
		0x04: 'Debuff'
	}

	# Known spell names (from constants and text extraction)
	SPELL_NAMES = [
		# White Magic (0-3)
		'Cure', 'Heal', 'Life', 'Exit',
		# Black Magic (4-7)
		'Fire', 'Blizzard', 'Thunder', 'Quake',
		# Wizard Magic (8-10)
		'Meteor', 'Flare', 'Teleport',
		# Additional/Unknown
		'Spell_11', 'Spell_12', 'Spell_13', 'Spell_14', 'Spell_15'
	]

	# Spell types based on ID ranges
	SPELL_TYPES = {
		0: 'White', 1: 'White', 2: 'White', 3: 'White',  # 0-3: White Magic
		4: 'Black', 5: 'Black', 6: 'Black', 7: 'Black',  # 4-7: Black Magic
		8: 'Wizard', 9: 'Wizard', 10: 'Wizard',          # 8-10: Wizard Magic
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

	def decode_enemy_type_flags(self, byte_value: int) -> List[str]:
		"""Decode enemy type bitfield into list of types"""
		types = []
		for bit, name in self.ENEMY_TYPE_FLAGS.items():
			if byte_value & bit:
				types.append(name)
		return types if types else ['None']

	def read_word(self, address: int) -> int:
		"""Read a 16-bit word (little-endian) from ROM"""
		if address + 1 < len(self.rom_data):
			return self.rom_data[address] | (self.rom_data[address + 1] << 8)
		return 0

	def extract_spell(self, spell_id: int) -> Dict:
		"""Extract a single spell's data"""
		base_addr = self.SPELL_DATA_ADDRESS + (spell_id * self.SPELL_ENTRY_SIZE)

		# Parse spell data structure (found via ROM scanning and user feedback)
		# Offset  Size  Field
		# +$00    1     Base power (verified correct)
		# +$01    1     Unknown - possibly level/tier requirement (values 1-20)
		# +$02    1     Unknown - NOT element (verified incorrect by testing)
		# +$03    1     Enemy type flags - "strong against" bitfield
		# +$04    1     Enemy type flags - possibly target type or range
		# +$05    1     Enemy type flags - possibly "weak against" or secondary flags

		byte3_raw = self.read_byte(base_addr + 3)
		byte4_raw = self.read_byte(base_addr + 4)
		byte5_raw = self.read_byte(base_addr + 5)

		spell_data = {
			'id': spell_id,
			'name': self.SPELL_NAMES[spell_id] if spell_id < len(self.SPELL_NAMES) else f'Spell_{spell_id:02d}',
			'spell_type': self.SPELL_TYPES.get(spell_id, 'Unknown'),
			'power': self.read_byte(base_addr),
			'byte1': self.read_byte(base_addr + 1),  # Unknown - possibly level requirement
			'byte2': self.read_byte(base_addr + 2),  # Unknown - NOT element (verified incorrect)
			'byte3': byte3_raw,
			'byte4': byte4_raw,
			'byte5': byte5_raw,
			'strong_against': self.decode_enemy_type_flags(byte3_raw),  # Decoded enemy type flags
			'target_type': self.decode_enemy_type_flags(byte4_raw),     # Decoded target/range flags
			'special_flags': self.decode_enemy_type_flags(byte5_raw),   # Decoded special/weak flags
			'address': f"${base_addr:06X}"
		}

		# Interpret unknown bytes
		spell_data['notes'] = self.interpret_notes(spell_data)

		return spell_data

	def interpret_notes(self, spell: Dict) -> List[str]:
		"""Generate notes about the spell"""
		notes = []

		if spell['power'] > 0:
			notes.append(f"{spell['power']} base power")

		# Note: Element not stored in this table
		notes.append("Element not in spell data table")

		return notes

	def extract_all(self) -> List[Dict]:
		"""Extract all spell data"""
		print(f"\n✨ Extracting spell data from ${self.SPELL_DATA_ADDRESS:06X}...")

		spells = []

		for i in range(self.SPELL_COUNT):
			spell = self.extract_spell(i)

			# Skip empty entries (power = 0 indicates unused slot)
			if spell['power'] > 0:
				spells.append(spell)

		print(f"  Extracted {len(spells)} spells")
		return spells

	def save_json(self, output_dir: str, spells: List[Dict]):
		"""Save spell data to JSON"""
		output_path = Path(output_dir)
		output_path.mkdir(parents=True, exist_ok=True)

		json_file = output_path / 'spells.json'

		json_output = {
			'version': '1.0.0',
			'game': 'Final Fantasy Mystic Quest',
			'note': 'Spell data addresses are approximate and need verification',
			'spells': spells
		}

		with open(json_file, 'w', encoding='utf-8') as f:
			json.dump(json_output, f, indent=2, ensure_ascii=False)

		print(f"\n💾 Saved JSON: {json_file}")

	def save_csv(self, output_dir: str, spells: List[Dict]):
		"""Save spell data to CSV"""
		output_path = Path(output_dir)
		output_path.mkdir(parents=True, exist_ok=True)

		csv_file = output_path / 'spells.csv'

		# Flatten list fields for CSV
		csv_rows = []
		for spell in spells:
			row = spell.copy()
			row['notes'] = '; '.join(spell['notes'])
			row['strong_against'] = ', '.join(spell['strong_against'])
			row['target_type'] = ', '.join(spell['target_type'])
			row['special_flags'] = ', '.join(spell['special_flags'])
			csv_rows.append(row)

		if csv_rows:
			with open(csv_file, 'w', encoding='utf-8', newline='') as f:
				fieldnames = ['id', 'name', 'spell_type', 'power', 'byte1', 'byte2',
							 'byte3', 'byte4', 'byte5', 'strong_against', 'target_type',
							 'special_flags', 'notes', 'address']
				writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction='ignore')
				writer.writeheader()
				writer.writerows(csv_rows)

		print(f"📊 Saved CSV: {csv_file}")

	def generate_statistics(self, spells: List[Dict]) -> str:
		"""Generate spell statistics report"""
		lines = []
		lines.append("="*80)
		lines.append(" Final Fantasy Mystic Quest - Spell Data Statistics")
		lines.append("="*80)
		lines.append("")

		lines.append(f"Total Spells: {len(spells)}")
		lines.append("")

		# By type
		type_counts = {}
		for spell in spells:
			spell_type = spell.get('spell_type', 'Unknown')
			type_counts[spell_type] = type_counts.get(spell_type, 0) + 1

		lines.append("Spell Types:")
		lines.append("-"*80)
		for spell_type, count in sorted(type_counts.items()):
			lines.append(f"  {spell_type:12s}: {count:2d} spells")
		lines.append("")

		# By element
		element_counts = {}
		for spell in spells:
			element = spell.get('element', 'None')
			element_counts[element] = element_counts.get(element, 0) + 1

		lines.append("Elements:")
		lines.append("-"*80)
		for element, count in sorted(element_counts.items()):
			lines.append(f"  {element:12s}: {count:2d} spells")
		lines.append("")

		# Note about MP cost
		lines.append("MP Cost:")
		lines.append("-"*80)
		lines.append("  All spells cost 1 MP (not stored in table)")
		lines.append("")

		# Power range
		powers = [s['power'] for s in spells if s['power'] > 0]
		if powers:
			lines.append("Spell Power:")
			lines.append("-"*80)
			lines.append(f"  Minimum: {min(powers):3d}")
			lines.append(f"  Maximum: {max(powers):3d}")
			lines.append(f"  Average: {sum(powers) / len(powers):5.1f}")
			lines.append("")

		lines.append("="*80)

		return '\n'.join(lines)

def main():
	"""Main entry point"""
	if len(sys.argv) < 3:
		print("Usage: extract_spells.py <rom_file> <output_dir> [--format json,csv]")
		print("\nExtracts spell data from FFMQ ROM")
		print("\nOptions:")
		print("  --format <fmt>    Output formats: json,csv,all (default: all)")
		print("\nNote: Spell data addresses are approximate and need verification")
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
	print("Final Fantasy Mystic Quest - Spell Data Extractor")
	print("="*80)
	print()

	# Extract spell data
	extractor = SpellExtractor(rom_file)

	print(f"ROM Address: ${extractor.SPELL_DATA_ADDRESS:06X}")
	print(f"Entry Size: {extractor.SPELL_ENTRY_SIZE} bytes")
	print("Note: All spells cost 1 MP")
	print()

	if not extractor.load_rom():
		sys.exit(1)

	spells = extractor.extract_all()

	# Determine output formats
	if 'all' in output_formats:
		output_formats = ['json', 'csv']

	print(f"\nSaving in formats: {', '.join(output_formats)}")

	if 'json' in output_formats:
		extractor.save_json(output_dir, spells)

	if 'csv' in output_formats:
		extractor.save_csv(output_dir, spells)

	# Generate statistics
	stats = extractor.generate_statistics(spells)
	print()
	print(stats)

	# Save statistics
	output_path = Path(output_dir)
	stats_file = output_path / 'spell_statistics.txt'
	stats_file.write_text(stats, encoding='utf-8')
	print(f"\n💾 Saved statistics: {stats_file}")

	print()
	print("="*80)
	print("Spell extraction complete!")
	print("⚠️  Remember to verify extracted data against actual ROM structure")
	print("="*80)

if __name__ == '__main__':
	main()
