#!/usr/bin/env python3
"""
FFMQ Simple Text Extractor
Extracts all fixed-length text tables from ROM using correct addresses

Extracts:
	- Item names (232 entries, 12 bytes each)
	- Weapon names (57 entries, 12 bytes each)
	- Armor names (20 entries, 12 bytes each)
	- Helmet names (10 entries, 12 bytes each)
	- Shield names (10 entries, 12 bytes each)
	- Accessory names (24 entries, 12 bytes each)
	- Spell names (32 entries, 12 bytes each)
	- Monster names (256 entries, 16 bytes each)

ROM Addresses from source code (.asm files):
	Items:	   $064120 (PC: 0x064120)
	Spells:	  $064210 (PC: 0x064210)
	Weapons:	 $0642A0 (PC: 0x0642A0)
	Helmets:	 $064354 (PC: 0x064354)
	Armor:	   $064378 (PC: 0x064378)
	Shields:	 $0643CC (PC: 0x0643CC)
	Accessories: $0643FC (PC: 0x0643FC)
	Monsters:	$064BA0 (PC: 0x064BA0)

Usage:
	python extract_simple_text.py <rom_path> [--output-dir data/text_fixed]
"""

import sys
import csv
import json
from pathlib import Path
from datetime import datetime
from dataclasses import dataclass
from typing import Optional

# Add tools directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))
from text.simple_text_decoder import SimpleTextDecoder


@dataclass
class TextTableConfig:
	"""Configuration for a text table in ROM"""
	name: str		   # Table name (e.g., "item_names")
	address: int		# PC address in ROM
	count: int		  # Number of entries
	entry_length: int   # Bytes per entry


class SimpleTextExtractor:
	"""Extract all simple fixed-length text from FFMQ ROM"""
	
	# Text table configurations (from .asm source files)
	TABLES = [
		TextTableConfig("item_names", 0x064120, 232, 12),
		TextTableConfig("spell_names", 0x064210, 32, 12),
		TextTableConfig("weapon_names", 0x0642A0, 57, 12),
		TextTableConfig("helmet_names", 0x064354, 10, 12),
		TextTableConfig("armor_names", 0x064378, 20, 12),
		TextTableConfig("shield_names", 0x0643CC, 10, 12),
		TextTableConfig("accessory_names", 0x0643FC, 24, 12),
		TextTableConfig("attack_names", 0x064420, 128, 12),  # Attack/ability names
		TextTableConfig("monster_names", 0x064BA0, 256, 16),
		TextTableConfig("location_names", 0x063ED0, 37, 16),  # Location/area names (37 valid entries)
	]
	
	def __init__(self, rom_path: Path):
		"""
		Initialize extractor
		
		Args:
			rom_path: Path to FFMQ ROM file
		"""
		self.rom_path = Path(rom_path)
		self.rom_data: Optional[bytes] = None
		self.decoder = SimpleTextDecoder()
	
	def load_rom(self) -> bool:
		"""Load ROM file"""
		if not self.rom_path.exists():
			print(f"ERROR: ROM not found: {self.rom_path}")
			return False
		
		with open(self.rom_path, 'rb') as f:
			self.rom_data = f.read()
		
		print(f"✓ Loaded ROM: {self.rom_path.name} ({len(self.rom_data):,} bytes)")
		return True
	
	def extract_table(self, config: TextTableConfig) -> list[dict]:
		"""
		Extract a single text table
		
		Args:
			config: Table configuration
		
		Returns:
			List of dicts with: id, text, address, length
		"""
		print(f"\n  Extracting {config.name}...")
		print(f"	Address: ${config.address:06X}")
		print(f"	Entries: {config.count} x {config.entry_length} bytes")
		
		entries = self.decoder.decode_table(
			self.rom_data,
			config.address,
			config.count,
			config.entry_length
		)
		
		print(f"	✓ Found {len(entries)} non-empty entries")
		
		# Show first 5 as sample
		if entries:
			print(f"	Sample: {entries[0]['text']}")
			if len(entries) > 1:
				print(f"			{entries[1]['text']}")
			if len(entries) > 2:
				print(f"			{entries[2]['text']}")
		
		return entries
	
	def extract_all(self) -> dict:
		"""
		Extract all text tables
		
		Returns:
			Dict with all extracted text organized by table
		"""
		print("=" * 70)
		print("FFMQ Simple Text Extraction")
		print("=" * 70)
		
		if not self.load_rom():
			return {}
		
		# Extract all tables
		all_text = {
			'version': '3.0.0',
			'game': 'Final Fantasy Mystic Quest',
			'extraction_date': datetime.now().isoformat(),
			'rom_file': self.rom_path.name,
			'decoder': 'SimpleTextDecoder',
			'character_table': 'simple.tbl',
			'total_entries': 0,
			'tables': {}
		}
		
		for config in self.TABLES:
			entries = self.extract_table(config)
			
			all_text['tables'][config.name] = {
				'count': len(entries),
				'address': f"${config.address:06X}",
				'entry_length': config.entry_length,
				'entries': entries
			}
			all_text['total_entries'] += len(entries)
		
		print("\n" + "=" * 70)
		print(f"✓ Total: {all_text['total_entries']} entries extracted")
		print("=" * 70)
		
		return all_text
	
	def save_csv(self, data: dict, output_dir: Path):
		"""
		Save each table as CSV
		
		Args:
			data: Extracted text data
			output_dir: Output directory
		"""
		output_dir = Path(output_dir)
		output_dir.mkdir(parents=True, exist_ok=True)
		
		print(f"\nSaving CSV files to {output_dir}...")
		
		for table_name, table_data in data['tables'].items():
			csv_path = output_dir / f"{table_name}.csv"
			
			with open(csv_path, 'w', encoding='utf-8', newline='') as f:
				writer = csv.writer(f)
				writer.writerow(['ID', 'Text', 'Address', 'Length'])
				
				for entry in table_data['entries']:
					writer.writerow([
						entry['id'],
						entry['text'],
						f"${entry['address']:06X}",
						entry['length']
					])
			
			print(f"  ✓ {csv_path.name}: {table_data['count']} entries")
	
	def save_json(self, data: dict, output_path: Path):
		"""
		Save all data as JSON
		
		Args:
			data: Extracted text data
			output_path: Output file path
		"""
		output_path = Path(output_path)
		output_path.parent.mkdir(parents=True, exist_ok=True)
		
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent=2, ensure_ascii=False)
		
		print(f"\n✓ Saved JSON: {output_path}")
	
	def save_text(self, data: dict, output_dir: Path):
		"""
		Save each table as human-readable text
		
		Args:
			data: Extracted text data
			output_dir: Output directory
		"""
		output_dir = Path(output_dir)
		output_dir.mkdir(parents=True, exist_ok=True)
		
		print(f"\nSaving text files to {output_dir}...")
		
		for table_name, table_data in data['tables'].items():
			txt_path = output_dir / f"{table_name}.txt"
			
			with open(txt_path, 'w', encoding='utf-8') as f:
				f.write(f"{table_name.upper().replace('_', ' ')}\n")
				f.write("=" * 70 + "\n")
				f.write(f"Extracted: {data['extraction_date']}\n")
				f.write(f"Address: {table_data['address']}\n")
				f.write(f"Count: {table_data['count']} entries\n")
				f.write("=" * 70 + "\n\n")
				
				for entry in table_data['entries']:
					f.write(f"[{entry['id']:3d}] {entry['text']}\n")
			
			print(f"  ✓ {txt_path.name}")


def main():
	"""Main entry point"""
	import argparse
	
	parser = argparse.ArgumentParser(
		description='Extract simple text from FFMQ ROM'
	)
	parser.add_argument(
		'rom_path',
		help='Path to FFMQ ROM file'
	)
	parser.add_argument(
		'--output-dir',
		default='data/text_fixed',
		help='Output directory for CSV/text files (default: data/text_fixed)'
	)
	parser.add_argument(
		'--json',
		help='Output JSON file path (optional)'
	)
	
	args = parser.parse_args()
	
	# Extract
	extractor = SimpleTextExtractor(Path(args.rom_path))
	data = extractor.extract_all()
	
	if not data:
		return False
	
	# Save outputs
	extractor.save_csv(data, Path(args.output_dir))
	extractor.save_text(data, Path(args.output_dir))
	
	if args.json:
		extractor.save_json(data, Path(args.json))
	
	print("\n✓ Extraction complete!")
	return True


if __name__ == '__main__':
	success = main()
	sys.exit(0 if success else 1)
