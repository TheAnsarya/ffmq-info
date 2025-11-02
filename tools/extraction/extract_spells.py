#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest - Spell Data Extractor
Extracts spell stats, MP costs, power, effects, and targeting

NOTE: This tool is a framework/placeholder. The exact ROM address for spell data
has not yet been located. It will extract zeros until the proper address is found
through battle code analysis.

Status: NEEDS RESEARCH - Spell data ROM location unknown
TODO: Analyze battle menu code to find where spell data is read
"""

import sys
import json
import csv
from pathlib import Path
from typing import Dict, List, Optional

class SpellExtractor:
	"""Extract spell data from FFMQ ROM"""

	# Spell data location (NEEDS RESEARCH - address unknown)
	# Documentation suggests Bank $09xxxx but exact location needs to be found
	# by analyzing battle code that references spell data
	# Placeholder address - will extract all zeros until proper address is found
	SPELL_DATA_ADDRESS = 0x090000  # Bank $09 - spell data table (PLACEHOLDER)
	SPELL_COUNT = 32
	SPELL_ENTRY_SIZE = 8  # Bytes per spell entry (estimated from docs)

	# Spell elements
	ELEMENTS = {
		0x00: 'None',
		0x01: 'Fire',
		0x02: 'Water',
		0x03: 'Wind',
		0x04: 'Earth'
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

	# Known spell names (from text extraction)
	SPELL_NAMES = [
		'Fire', 'Blizzard', 'Thunder', 'Aero',
		'Cure', 'Life', 'Heal', 'Esuna',
		'Quake', 'Flare', 'White', 'Meteor',
		'Exit', 'Seed', 'Heal', 'Steel',
		'Shell', 'Speed', 'Flame', 'Blizzara',
		'Thundara', 'Aerora', 'Firaga', 'Blizzaga',
		'Thundaga', 'Aeroga', 'Quakera', 'Flarea',
		'Whitera', 'Meteora', 'Ultima', 'Full-Cure'
	]

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

	def extract_spell(self, spell_id: int) -> Dict:
		"""Extract a single spell's data"""
		base_addr = self.SPELL_DATA_ADDRESS + (spell_id * self.SPELL_ENTRY_SIZE)
		
		# Parse spell data structure (based on docs/ROM_DATA_MAP.md)
		# Offset  Size  Field
		# +$00    1     Base power
		# +$01    1     MP cost  
		# +$02    1     Element
		# +$03    1     Target flags
		# +$04    1     Animation ID
		# +$05-$07      Reserved/unknown
		
		spell_data = {
			'id': spell_id,
			'name': self.SPELL_NAMES[spell_id] if spell_id < len(self.SPELL_NAMES) else f'Spell_{spell_id:02d}',
			'power': self.read_byte(base_addr),
			'mp_cost': self.read_byte(base_addr + 1),
			'element': self.ELEMENTS.get(self.read_byte(base_addr + 2), 'Unknown'),
			'target_flags': self.read_byte(base_addr + 3),
			'animation_id': self.read_byte(base_addr + 4),
			'address': f"${base_addr:06X}"
		}
		
		# Interpret target flags
		spell_data['target'] = self.interpret_target(spell_data['target_flags'])
		spell_data['effects'] = self.interpret_effects(spell_data)
		
		return spell_data
	
	def interpret_target(self, flags: int) -> str:
		"""Interpret target flags into readable description"""
		# Target flags interpretation (to be verified)
		if flags & 0x01:
			return 'All Enemies'
		elif flags & 0x02:
			return 'Single Enemy'
		elif flags & 0x04:
			return 'All Allies'
		elif flags & 0x08:
			return 'Single Ally'
		elif flags & 0x10:
			return 'Self'
		return 'Unknown'
	
	def interpret_effects(self, spell: Dict) -> List[str]:
		"""Interpret spell effect flags into readable descriptions"""
		effects = []
		
		# Basic effects based on element and power
		if spell['element'] != 'None':
			effects.append(f"{spell['element']} elemental")
		
		if spell['power'] > 0:
			# Guess spell type based on target
			if 'Ally' in spell['target'] or spell['target'] == 'Self':
				effects.append(f"Restores {spell['power']} HP")
			else:
				effects.append(f"{spell['power']} base damage")
		
		return effects
	
	def extract_all(self) -> List[Dict]:
		"""Extract all spell data"""
		print(f"\n✨ Extracting spell data from ${self.SPELL_DATA_ADDRESS:06X}...")

		spells = []

		for i in range(self.SPELL_COUNT):
			spell = self.extract_spell(i)

			# Skip empty entries (MP cost = 0 and power = 0)
			if spell['mp_cost'] > 0 or spell['power'] > 0:
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

		# Flatten effects list for CSV
		csv_rows = []
		for spell in spells:
			row = spell.copy()
			row['effects'] = '; '.join(spell['effects'])
			csv_rows.append(row)

		if csv_rows:
			with open(csv_file, 'w', encoding='utf-8', newline='') as f:
				fieldnames = ['id', 'name', 'power', 'mp_cost', 'element', 
							 'target', 'target_flags', 'animation_id', 'effects', 'address']
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

		# MP cost range
		if spells:
			mp_costs = [s['mp_cost'] for s in spells if s['mp_cost'] > 0]
			if mp_costs:
				lines.append("MP Costs:")
				lines.append("-"*80)
				lines.append(f"  Minimum: {min(mp_costs):3d}")
				lines.append(f"  Maximum: {max(mp_costs):3d}")
				lines.append(f"  Average: {sum(mp_costs) / len(mp_costs):5.1f}")
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
	print("⚠️  Status: FRAMEWORK ONLY - Spell data ROM address needs research")
	print("     Tool will extract zeros until proper address is located")
	print("     TODO: Analyze battle/menu code to find spell data tables")
	print()

	# Extract spell data
	extractor = SpellExtractor(rom_file)

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
