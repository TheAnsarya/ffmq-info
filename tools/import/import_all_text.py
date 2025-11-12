#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest - Complete Text Importer
Imports edited text from JSON back into ROM

Features:
- Imports all text tables: items, weapons, armor, accessories, spells, monsters, locations
- Imports all 116 dialogs with full DTE compression
- Validates text fits within size constraints
- Creates backup of original ROM
- Comprehensive error checking and reporting

Usage:
	python import_all_text.py <input_json> <output_rom> [--source-rom rom.sfc]
"""

import sys
import os
import json
import shutil
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from datetime import datetime

# Add parent directories to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent / 'map-editor'))
from utils.dialog_text import DialogText
from utils.dialog_database import DialogDatabase


class TextImporter:
	"""Import edited text back into FFMQ ROM"""

	def __init__(self, source_rom: Path, output_rom: Path):
		"""Initialize importer"""
		self.source_rom = Path(source_rom)
		self.output_rom = Path(output_rom)
		self.rom_data: Optional[bytearray] = None
		self.dialog_text = DialogText()
		self.errors: List[str] = []
		self.warnings: List[str] = []
		self.stats = {
			'tables_updated': 0,
			'strings_updated': 0,
			'bytes_written': 0,
			'errors': 0,
			'warnings': 0
		}

	def load_rom(self) -> bool:
		"""Load source ROM"""
		if not self.source_rom.exists():
			self.errors.append(f"Source ROM not found: {self.source_rom}")
			return False

		with open(self.source_rom, 'rb') as f:
			self.rom_data = bytearray(f.read())

		print(f"✓ Loaded source ROM: {self.source_rom.name} ({len(self.rom_data):,} bytes)")
		return True

	def save_rom(self) -> bool:
		"""Save modified ROM"""
		if not self.rom_data:
			self.errors.append("No ROM data to save")
			return False

		# Create output directory if needed
		self.output_rom.parent.mkdir(parents=True, exist_ok=True)

		with open(self.output_rom, 'wb') as f:
			f.write(self.rom_data)

		print(f"\n✓ Saved modified ROM: {self.output_rom} ({len(self.rom_data):,} bytes)")
		return True

	def write_fixed_string(self, offset: int, text: str, max_length: int, table_name: str, entry_id: int) -> bool:
		"""
		Write a fixed-length string at given offset

		Args:
			offset: PC address in ROM
			text: Text to encode
			max_length: Maximum bytes allowed
			table_name: Name of table (for error messages)
			entry_id: Entry ID (for error messages)

		Returns:
			True if successful
		"""
		try:
			# Encode text
			encoded = self.dialog_text.encode(text)

			# Check length
			if len(encoded) > max_length:
				self.errors.append(
					f"{table_name}[{entry_id}]: Text too long! "
					f"{len(encoded)} bytes > {max_length} max"
				)
				return False

			# Pad with zeros if needed
			while len(encoded) < max_length:
				encoded.append(0x00)

			# Write to ROM
			if offset + max_length > len(self.rom_data):
				self.errors.append(
					f"{table_name}[{entry_id}]: Offset ${offset:06X} out of bounds"
				)
				return False

			self.rom_data[offset:offset + max_length] = encoded
			self.stats['bytes_written'] += len(encoded)

			return True

		except Exception as e:
			self.errors.append(f"{table_name}[{entry_id}]: Encoding failed - {e}")
			return False

	def import_text_table(self, table_name: str, table_data: Dict) -> bool:
		"""Import a fixed-length text table"""
		print(f"\nImporting {table_name}...")

		config = table_data['config']
		strings = table_data['strings']

		address = config['address']
		max_length = config['max_length']

		success_count = 0

		for entry in strings:
			entry_id = entry['id']
			text = entry['text']
			offset = address + (entry_id * max_length)

			if self.write_fixed_string(offset, text, max_length, table_name, entry_id):
				success_count += 1

		self.stats['strings_updated'] += success_count
		print(f"  ✓ Imported {success_count}/{len(strings)} entries")

		return success_count == len(strings)

	def import_dialogs(self, dialog_data: Dict) -> bool:
		"""Import dialogs using DialogDatabase"""
		print(f"\nImporting dialogs...")

		strings = dialog_data['strings']

		# Create temp ROM for DialogDatabase
		temp_rom = self.output_rom.parent / f"_temp_{self.output_rom.name}"
		with open(temp_rom, 'wb') as f:
			f.write(self.rom_data)

		try:
			# Use DialogDatabase to write dialogs
			db = DialogDatabase(temp_rom)

			success_count = 0
			for entry in strings:
				dialog_id = entry['id']
				text = entry['text']

				try:
					db.update_dialog(dialog_id, text)
					success_count += 1
				except Exception as e:
					self.errors.append(f"Dialog[{dialog_id}]: {e}")

			# Read back modified ROM
			with open(temp_rom, 'rb') as f:
				self.rom_data = bytearray(f.read())

			self.stats['strings_updated'] += success_count
			print(f"  ✓ Imported {success_count}/{len(strings)} dialogs")

			return success_count == len(strings)

		finally:
			# Clean up temp file
			if temp_rom.exists():
				temp_rom.unlink()

	def import_all(self, json_data: Dict) -> bool:
		"""Import all text from JSON"""
		print("="*70)
		print("FFMQ Complete Text Import")
		print("="*70)

		if not self.load_rom():
			return False

		# Validate JSON structure
		if 'tables' not in json_data:
			self.errors.append("Invalid JSON: missing 'tables' key")
			return False

		tables = json_data['tables']

		# Import each table
		for table_name, table_data in tables.items():
			if table_name == 'dialog':
				# Special handling for dialogs
				self.import_dialogs(table_data)
			else:
				# Fixed-length tables
				self.import_text_table(table_name, table_data)

			self.stats['tables_updated'] += 1

		# Save modified ROM
		if not self.save_rom():
			return False

		# Print summary
		print("\n" + "="*70)
		print("Import Summary")
		print("="*70)
		print(f"Tables updated:  {self.stats['tables_updated']}")
		print(f"Strings updated: {self.stats['strings_updated']}")
		print(f"Bytes written:   {self.stats['bytes_written']:,}")
		print(f"Errors:		  {len(self.errors)}")
		print(f"Warnings:		{len(self.warnings)}")

		if self.errors:
			print("\n❌ ERRORS:")
			for error in self.errors[:10]:  # Show first 10
				print(f"  - {error}")
			if len(self.errors) > 10:
				print(f"  ... and {len(self.errors) - 10} more")

		if self.warnings:
			print("\n⚠️  WARNINGS:")
			for warning in self.warnings[:10]:
				print(f"  - {warning}")
			if len(self.warnings) > 10:
				print(f"  ... and {len(self.warnings) - 10} more")

		print("="*70)

		return len(self.errors) == 0

	def create_backup(self) -> bool:
		"""Create backup of source ROM"""
		if not self.source_rom.exists():
			return False

		timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
		backup_path = self.source_rom.parent / f"{self.source_rom.stem}_backup_{timestamp}{self.source_rom.suffix}"

		shutil.copy2(self.source_rom, backup_path)
		print(f"✓ Created backup: {backup_path.name}")

		return True


def main():
	"""Main entry point"""
	import argparse

	parser = argparse.ArgumentParser(
		description='Import edited text into FFMQ ROM'
	)
	parser.add_argument('input_json', help='Path to text_data.json file')
	parser.add_argument('output_rom', help='Path for output ROM file')
	parser.add_argument('--source-rom', '-s', help='Source ROM to modify (default: use path from JSON)')
	parser.add_argument('--no-backup', action='store_true', help='Skip backup creation')
	parser.add_argument('--force', '-f', action='store_true', help='Overwrite output without confirmation')

	args = parser.parse_args()

	# Load JSON
	json_path = Path(args.input_json)
	if not json_path.exists():
		print(f"ERROR: JSON file not found: {json_path}")
		return 1

	with open(json_path, 'r', encoding='utf-8') as f:
		json_data = json.load(f)

	# Determine source ROM
	if args.source_rom:
		source_rom = Path(args.source_rom)
	else:
		# Try to find ROM from JSON metadata
		if 'rom_file' in json_data:
			rom_name = json_data['rom_file']
			# Look in common locations
			for search_dir in [Path('roms'), Path('.')]:
				candidate = search_dir / rom_name
				if candidate.exists():
					source_rom = candidate
					break
			else:
				print(f"ERROR: Could not find ROM '{rom_name}'. Use --source-rom to specify.")
				return 1
		else:
			print("ERROR: No --source-rom specified and JSON doesn't contain rom_file")
			return 1

	if not source_rom.exists():
		print(f"ERROR: Source ROM not found: {source_rom}")
		return 1

	output_rom = Path(args.output_rom)

	# Check if output already exists
	if output_rom.exists() and not args.force:
		response = input(f"Output ROM '{output_rom}' already exists. Overwrite? (y/N): ")
		if response.lower() != 'y':
			print("Aborted.")
			return 0

	# Create importer
	importer = TextImporter(source_rom, output_rom)

	# Create backup
	if not args.no_backup:
		importer.create_backup()

	# Import text
	success = importer.import_all(json_data)

	if success:
		print("\n✓ Import completed successfully!")
		return 0
	else:
		print("\n❌ Import completed with errors!")
		return 1


if __name__ == '__main__':
	sys.exit(main())
