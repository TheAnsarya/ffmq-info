#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest - Complete Text Extractor
Extracts ALL text from ROM using proper DTE decoding and control code handling

Features:
- Uses DialogText for proper DTE compression handling
- Extracts all text tables: items, weapons, armor, accessories, spells, monsters, locations
- Extracts all 116 dialog strings with full control code support
- Generates JSON, CSV, and plain text formats
- Calculates statistics and compression metrics

Usage:
	python extract_all_text.py <rom_path> [--output-dir data/text]
"""

import sys
import os
import json
import csv
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime

# Add parent directories to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent / 'map-editor'))
from utils.dialog_text import DialogText, CharacterTable
from utils.dialog_database import DialogDatabase


@dataclass
class TextTableConfig:
	"""Configuration for a text table in ROM"""
	address: int		# PC address in ROM
	count: int		  # Number of entries
	max_length: int	 # Maximum bytes per entry
	name: str		   # Table name


class TextExtractor:
	"""Extract all text from FFMQ ROM with proper DTE decoding"""

	# Text table configurations (PC addresses)
	TEXT_TABLES = {
		'item_names': TextTableConfig(
			address=0x04F000,
			count=256,
			max_length=12,
			name='item_names'
		),
		'weapon_names': TextTableConfig(
			address=0x04F800,
			count=64,
			max_length=12,
			name='weapon_names'
		),
		'armor_names': TextTableConfig(
			address=0x04FC00,
			count=64,
			max_length=12,
			name='armor_names'
		),
		'accessory_names': TextTableConfig(
			address=0x04FD00,
			count=64,
			max_length=12,
			name='accessory_names'
		),
		'spell_names': TextTableConfig(
			address=0x04FE00,
			count=64,
			max_length=12,
			name='spell_names'
		),
		'monster_names': TextTableConfig(
			address=0x05000,
			count=256,
			max_length=16,
			name='monster_names'
		),
		'location_names': TextTableConfig(
			address=0x051000,
			count=128,
			max_length=20,
			name='location_names'
		)
	}

	def __init__(self, rom_path: Path):
		"""Initialize extractor with ROM path"""
		self.rom_path = Path(rom_path)
		self.rom_data: Optional[bytes] = None
		self.dialog_text = DialogText()
		self.char_table = self.dialog_text.char_table

	def load_rom(self) -> bool:
		"""Load ROM file"""
		if not self.rom_path.exists():
			print(f"ERROR: ROM not found: {self.rom_path}")
			return False

		with open(self.rom_path, 'rb') as f:
			self.rom_data = f.read()

		print(f"✓ Loaded ROM: {self.rom_path.name} ({len(self.rom_data):,} bytes)")
		return True

	def decode_fixed_string(self, offset: int, max_length: int) -> Tuple[str, int]:
		"""
		Decode a fixed-length string at given offset

		Args:
			offset: PC address in ROM
			max_length: Maximum bytes to read

		Returns:
			(decoded_text, actual_length)
		"""
		if offset + max_length > len(self.rom_data):
			return "", 0

		# Read bytes
		data = self.rom_data[offset:offset + max_length]

		# Decode using DialogText
		try:
			text = self.dialog_text.decode(data)

			# Remove [END] marker if present
			text = text.replace('[END]', '')

			# Calculate actual length (up to 0x00 terminator or max)
			actual_len = 0
			for i, byte in enumerate(data):
				actual_len = i + 1
				if byte == 0x00:
					break

			return text.strip(), actual_len
		except Exception as e:
			print(f"  Warning: Failed to decode at ${offset:06X}: {e}")
			return "", 0

	def extract_text_table(self, config: TextTableConfig) -> List[Dict]:
		"""Extract a fixed-length text table"""
		print(f"\nExtracting {config.name}...")

		strings = []
		current_addr = config.address

		for i in range(config.count):
			text, length = self.decode_fixed_string(current_addr, config.max_length)

			# Only include non-empty entries
			if text and text.strip():
				strings.append({
					'id': i,
					'text': text,
					'address': f"${current_addr:06X}",
					'length': length
				})

			current_addr += config.max_length

		print(f"  ✓ Extracted {len(strings)} entries")
		return strings

	def extract_dialogs(self) -> List[Dict]:
		"""Extract all dialog strings using DialogDatabase"""
		print(f"\nExtracting dialogs...")

		# Use DialogDatabase which already handles everything
		db = DialogDatabase(self.rom_path)
		db.extract_all_dialogs()

		dialogs = []
		for dialog_id, entry in sorted(db.dialogs.items()):
			if entry and entry.text:
				dialogs.append({
					'id': dialog_id,
					'text': entry.text,
					'address': f"${entry.address:06X}",
					'pointer': f"${entry.pointer:04X}",
					'length': entry.length
				})

		print(f"  ✓ Extracted {len(dialogs)} dialogs")
		return dialogs

	def extract_all(self) -> Dict:
		"""Extract all text from ROM"""
		print("="*70)
		print("FFMQ Complete Text Extraction")
		print("="*70)

		if not self.load_rom():
			return {}

		all_text = {
			'version': '2.0.0',
			'game': 'Final Fantasy Mystic Quest',
			'extraction_date': datetime.now().isoformat(),
			'rom_file': self.rom_path.name,
			'total_strings': 0,
			'tables': {}
		}

		# Extract fixed-length tables
		for table_name, config in self.TEXT_TABLES.items():
			strings = self.extract_text_table(config)
			all_text['tables'][table_name] = {
				'count': len(strings),
				'config': {
					'address': config.address,
					'count': config.count,
					'max_length': config.max_length
				},
				'strings': strings
			}
			all_text['total_strings'] += len(strings)

		# Extract dialogs
		dialogs = self.extract_dialogs()
		all_text['tables']['dialog'] = {
			'count': len(dialogs),
			'config': {
				'pointer_table': 0x00D636,
				'count': 256,
				'bank': 3,
				'max_length': 512
			},
			'strings': dialogs
		}
		all_text['total_strings'] += len(dialogs)

		print("\n" + "="*70)
		print(f"✓ Total: {all_text['total_strings']} strings extracted")
		print("="*70)

		return all_text

	def save_json(self, data: Dict, output_path: Path):
		"""Save data as JSON"""
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent=2, ensure_ascii=False)
		print(f"\n✓ Saved JSON: {output_path}")

	def save_csv(self, data: Dict, output_dir: Path):
		"""Save each table as CSV"""
		for table_name, table_data in data['tables'].items():
			csv_path = output_dir / f"{table_name}.csv"

			with open(csv_path, 'w', encoding='utf-8', newline='') as f:
				writer = csv.writer(f)
				writer.writerow(['ID', 'Text', 'Address', 'Length'])

				for entry in table_data['strings']:
					writer.writerow([
						entry['id'],
						entry['text'],
						entry['address'],
						entry['length']
					])

			print(f"✓ Saved CSV: {csv_path}")

	def save_text(self, data: Dict, output_dir: Path):
		"""Save as human-readable text files"""
		for table_name, table_data in data['tables'].items():
			txt_path = output_dir / f"{table_name}.txt"

			with open(txt_path, 'w', encoding='utf-8') as f:
				f.write(f"{table_name.upper()}\n")
				f.write(f"{'='*70}\n")
				f.write(f"Extracted: {data['extraction_date']}\n")
				f.write(f"Count: {table_data['count']} entries\n")
				f.write(f"{'='*70}\n\n")

				for entry in table_data['strings']:
					# Format nicely for readability
					f.write(f"[{entry['id']:03d}] {entry['text']}\n")
					if table_name == 'dialog' and len(entry['text']) > 50:
						f.write("\n")  # Extra spacing for long dialogs

			print(f"✓ Saved text: {txt_path}")

	def calculate_statistics(self, data: Dict) -> Dict:
		"""Calculate comprehensive statistics"""
		stats = {
			'total_strings': data['total_strings'],
			'table_counts': {},
			'total_bytes': 0,
			'total_characters': 0,
			'character_frequency': {},
			'control_code_usage': {},
			'dte_usage': {},
			'compression_ratio': 0.0
		}

		for table_name, table_data in data['tables'].items():
			count = table_data['count']
			stats['table_counts'][table_name] = count

			# Analyze each string
			for entry in table_data['strings']:
				text = entry['text']
				stats['total_bytes'] += entry['length']
				stats['total_characters'] += len(text)

				# Character frequency
				for char in text:
					if char not in ['[', ']']:  # Skip control code brackets
						stats['character_frequency'][char] = \
							stats['character_frequency'].get(char, 0) + 1

				# Control code usage
				import re
				for code in re.findall(r'\[[A-Z0-9_]+\]', text):
					stats['control_code_usage'][code] = \
						stats['control_code_usage'].get(code, 0) + 1

		# Calculate compression ratio
		if stats['total_characters'] > 0:
			stats['compression_ratio'] = stats['total_bytes'] / stats['total_characters']

		# Sort by frequency
		stats['character_frequency'] = dict(
			sorted(stats['character_frequency'].items(),
				   key=lambda x: x[1], reverse=True)
		)
		stats['control_code_usage'] = dict(
			sorted(stats['control_code_usage'].items(),
				   key=lambda x: x[1], reverse=True)
		)

		return stats

	def save_statistics(self, data: Dict, output_path: Path):
		"""Save statistics as readable text file"""
		stats = self.calculate_statistics(data)

		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("FINAL FANTASY MYSTIC QUEST - TEXT STATISTICS\n")
			f.write("="*70 + "\n\n")

			f.write("OVERVIEW\n")
			f.write("-"*70 + "\n")
			f.write(f"Total strings:		{stats['total_strings']}\n")
			f.write(f"Total bytes:		  {stats['total_bytes']:,}\n")
			f.write(f"Total characters:	 {stats['total_characters']:,}\n")
			f.write(f"Compression ratio:	{stats['compression_ratio']:.2%}\n")
			f.write(f"Space saved:		  {stats['total_characters'] - stats['total_bytes']:,} bytes\n")
			f.write("\n")

			f.write("TABLE COUNTS\n")
			f.write("-"*70 + "\n")
			for table_name, count in stats['table_counts'].items():
				f.write(f"{table_name:20s} {count:5d} strings\n")
			f.write("\n")

			f.write("TOP 30 CHARACTERS\n")
			f.write("-"*70 + "\n")
			for i, (char, count) in enumerate(list(stats['character_frequency'].items())[:30], 1):
				display_char = repr(char) if char in '\n\t ' else char
				f.write(f"{i:2d}. {display_char:5s} : {count:5d} occurrences\n")
			f.write("\n")

			f.write("CONTROL CODE USAGE\n")
			f.write("-"*70 + "\n")
			for code, count in stats['control_code_usage'].items():
				f.write(f"{code:15s} : {count:5d} occurrences\n")
			f.write("\n")

		print(f"\n✓ Saved statistics: {output_path}")


def main():
	"""Main entry point"""
	import argparse

	parser = argparse.ArgumentParser(
		description='Extract all text from FFMQ ROM with proper DTE decoding'
	)
	parser.add_argument('rom', help='Path to FFMQ ROM file')
	parser.add_argument('--output-dir', '-o', default='data/text',
						help='Output directory (default: data/text)')
	parser.add_argument('--format', '-f', choices=['json', 'csv', 'txt', 'all'],
						default='all', help='Output format (default: all)')

	args = parser.parse_args()

	# Create output directory
	output_dir = Path(args.output_dir)
	output_dir.mkdir(parents=True, exist_ok=True)

	# Extract text
	extractor = TextExtractor(Path(args.rom))
	data = extractor.extract_all()

	if not data:
		print("\nERROR: Extraction failed!")
		return 1

	# Save in requested formats
	print(f"\nSaving to {output_dir}...")

	if args.format in ['json', 'all']:
		extractor.save_json(data, output_dir / 'text_data.json')

	if args.format in ['csv', 'all']:
		extractor.save_csv(data, output_dir)

	if args.format in ['txt', 'all']:
		extractor.save_text(data, output_dir)

	# Always save statistics
	extractor.save_statistics(data, output_dir / 'text_statistics.txt')

	print(f"\n{'='*70}")
	print("✓ Extraction complete!")
	print(f"{'='*70}\n")

	return 0


if __name__ == '__main__':
	sys.exit(main())
