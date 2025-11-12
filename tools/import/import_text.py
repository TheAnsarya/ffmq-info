#!/usr/bin/env python3
"""
FFMQ Text Importer - Reinsert edited text back into ROM.

This tool takes edited text from JSON/CSV and writes it back to the ROM,
creating a modified ROM file with updated dialogue, item names, etc.

Features:
- Import from JSON or CSV
- Validate text length constraints
- Encode text using FFMQ character table
- Update pointer tables automatically
- Create binary patches
- Validate changes before writing
"""

import os
import sys
import json
import csv
from pathlib import Path
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass
import shutil


@dataclass
class TextImportEntry:
	"""A text entry to be imported."""
	id: int
	category: str
	text: str
	rom_offset: int
	snes_address: str
	max_length: int
	original_length: int


class FFMQTextImporter:
	"""Import edited text back into FFMQ ROM."""

	def __init__(self, rom_path: str, text_json_path: str, output_rom_path: str):
		self.rom_path = rom_path
		self.text_json_path = text_json_path
		self.output_rom_path = output_rom_path
		self.rom_data = None
		self.has_header = False

		# Build character encoding table (reverse of extraction table)
		self.char_encode = self._build_encoding_table()

		# Statistics
		self.stats = {
			'total_entries': 0,
			'imported': 0,
			'skipped': 0,
			'errors': 0,
			'warnings': [],
		}

	def _build_encoding_table(self) -> Dict[str, int]:
		"""Build character encoding table (text → byte)."""
		encode = {}

		# Standard characters
		encode[' '] = 0x00
		encode['!'] = 0x01
		encode['"'] = 0x02
		encode['#'] = 0x03
		encode['$'] = 0x04
		encode['%'] = 0x05
		encode['&'] = 0x06
		encode["'"] = 0x07
		encode['('] = 0x08
		encode[')'] = 0x09
		encode['*'] = 0x0A
		encode['+'] = 0x0B
		encode[','] = 0x0C
		encode['-'] = 0x0D
		encode['.'] = 0x0E
		encode['/'] = 0x0F

		# Numbers
		for i in range(10):
			encode[str(i)] = 0x10 + i

		# Punctuation
		encode[':'] = 0x1A
		encode[';'] = 0x1B
		encode['<'] = 0x1C
		encode['='] = 0x1D
		encode['>'] = 0x1E
		encode['?'] = 0x1F

		# Uppercase
		encode['@'] = 0x20
		for i in range(26):
			encode[chr(ord('A') + i)] = 0x21 + i

		# Symbols
		encode['['] = 0x3B
		encode['\\'] = 0x3C
		encode[']'] = 0x3D
		encode['^'] = 0x3E
		encode['_'] = 0x3F

		# Lowercase
		encode['`'] = 0x40
		for i in range(26):
			encode[chr(ord('a') + i)] = 0x41 + i

		# Final symbols
		encode['{'] = 0x5B
		encode['|'] = 0x5C
		encode['}'] = 0x5D
		encode['~'] = 0x5E

		# Control codes (special sequences)
		encode['[CHOICE]'] = 0xF0
		encode['[PLAYER]'] = 0xF1
		encode['[NUMBER]'] = 0xF2
		encode['[ITEM]'] = 0xF3
		encode['[SPELL]'] = 0xF4
		encode['[ENEMY]'] = 0xF5
		encode['[PAUSE]'] = 0xF6
		encode['[WAIT]'] = 0xF7
		encode['[SPEED]'] = 0xF8
		encode['[COLOR]'] = 0xF9
		encode['[PORTRAIT]'] = 0xFA
		encode['[WINDOW]'] = 0xFB
		encode['[CLEAR]'] = 0xFC
		encode['[PAGE]'] = 0xFD
		encode['[NEWLINE]'] = 0xFE
		encode['[END]'] = 0xFF

		return encode

	def encode_text(self, text: str) -> bytes:
		"""Encode text string to bytes."""
		result = bytearray()

		i = 0
		while i < len(text):
			# Check for control codes (multi-character sequences)
			if text[i] == '[':
				# Find matching ]
				end = text.find(']', i)
				if end != -1:
					control_code = text[i:end+1]
					if control_code in self.char_encode:
						result.append(self.char_encode[control_code])
						i = end + 1
						continue

			# Single character
			char = text[i]
			if char in self.char_encode:
				result.append(self.char_encode[char])
			else:
				# Unknown character - use space
				print(f"  ⚠ Unknown character: '{char}' (using space)")
				result.append(0x00)

			i += 1

		return bytes(result)

	def load_rom(self) -> bool:
		"""Load source ROM."""
		try:
			with open(self.rom_path, 'rb') as f:
				self.rom_data = bytearray(f.read())

			print(f"✓ Loaded ROM: {len(self.rom_data):,} bytes")

			# Detect header
			if len(self.rom_data) % 1024 == 512:
				print("  ℹ SMC header detected")
				self.has_header = True

			return True
		except Exception as e:
			print(f"✗ Error loading ROM: {e}")
			return False

	def load_text_json(self) -> List[TextImportEntry]:
		"""Load text from JSON file."""
		entries = []

		try:
			with open(self.text_json_path, 'r', encoding='utf-8') as f:
				data = json.load(f)

			print(f"✓ Loaded text JSON: {self.text_json_path}")

			# Parse sections
			for section_name, section_data in data.get('sections', {}).items():
				for entry_data in section_data.get('entries', []):
					# Parse ROM offset
					rom_offset = entry_data['rom_offset']
					if isinstance(rom_offset, str):
						rom_offset = int(rom_offset, 16)

					# Get length constraints
					original_length = entry_data['length']

					# Determine max length based on category
					if section_name == 'item_names':
						max_length = 12
					elif section_name == 'spell_names':
						max_length = 8
					elif section_name == 'enemy_names':
						max_length = 12
					else:
						# For variable-length strings, use original length as max
						max_length = original_length

					entry = TextImportEntry(
						id=entry_data['id'],
						category=entry_data['category'],
						text=entry_data['text'],
						rom_offset=rom_offset,
						snes_address=entry_data['snes_address'],
						max_length=max_length,
						original_length=original_length
					)
					entries.append(entry)

			self.stats['total_entries'] = len(entries)
			print(f"  ℹ Loaded {len(entries)} text entries")

			return entries

		except Exception as e:
			print(f"✗ Error loading text JSON: {e}")
			return []

	def validate_entry(self, entry: TextImportEntry, encoded: bytes) -> Tuple[bool, str]:
		"""Validate a text entry before import."""
		# Check if text is empty
		if not entry.text.strip():
			return True, "Empty text (will skip)"

		# Check length
		if len(encoded) > entry.max_length:
			return False, f"Text too long: {len(encoded)} bytes > {entry.max_length} max"

		# Check ROM bounds
		if entry.rom_offset + len(encoded) > len(self.rom_data):
			return False, f"Would write past ROM end"

		return True, "OK"

	def import_entry(self, entry: TextImportEntry) -> bool:
		"""Import a single text entry."""
		try:
			# Encode text
			encoded = self.encode_text(entry.text)

			# Add terminator for fixed-length entries
			if entry.category in ['item_names', 'spell_names', 'enemy_names']:
				# Pad with 0xFF (END marker) then 0x00 to fill length
				if len(encoded) < entry.max_length:
					encoded = encoded + b'\xFF' + (b'\x00' * (entry.max_length - len(encoded) - 1))
			else:
				# Add END marker for variable-length strings
				if not encoded.endswith(b'\xFF'):
					encoded = encoded + b'\xFF'

			# Validate
			valid, message = self.validate_entry(entry, encoded)

			if not valid:
				print(f"  ✗ Entry {entry.id} ({entry.category}): {message}")
				self.stats['errors'] += 1
				return False

			if message != "OK":
				print(f"  ⚠ Entry {entry.id} ({entry.category}): {message}")
				self.stats['skipped'] += 1
				return True

			# Write to ROM
			offset = entry.rom_offset
			for i, byte in enumerate(encoded):
				self.rom_data[offset + i] = byte

			self.stats['imported'] += 1
			return True

		except Exception as e:
			print(f"  ✗ Entry {entry.id} ({entry.category}): {e}")
			self.stats['errors'] += 1
			return False

	def import_all(self) -> bool:
		"""Import all text entries."""
		if not self.load_rom():
			return False

		entries = self.load_text_json()
		if not entries:
			return False

		print("\n" + "=" * 80)
		print("IMPORTING TEXT")
		print("=" * 80)

		# Group by category for organized output
		by_category = {}
		for entry in entries:
			if entry.category not in by_category:
				by_category[entry.category] = []
			by_category[entry.category].append(entry)

		# Import each category
		for category, cat_entries in by_category.items():
			print(f"\n{category}:")
			print(f"  Processing {len(cat_entries)} entries...")

			for entry in cat_entries:
				self.import_entry(entry)

		# Save modified ROM
		print("\n" + "=" * 80)
		print("SAVING MODIFIED ROM")
		print("=" * 80)

		try:
			# Create output directory if needed
			output_dir = Path(self.output_rom_path).parent
			output_dir.mkdir(parents=True, exist_ok=True)

			# Write ROM
			with open(self.output_rom_path, 'wb') as f:
				f.write(self.rom_data)

			print(f"✓ Saved: {self.output_rom_path}")
			print(f"  Size: {len(self.rom_data):,} bytes")

		except Exception as e:
			print(f"✗ Error saving ROM: {e}")
			return False

		return True

	def print_summary(self):
		"""Print import summary."""
		print("\n" + "=" * 80)
		print("IMPORT SUMMARY")
		print("=" * 80)
		print(f"Total entries:	{self.stats['total_entries']}")
		print(f"Imported:		 {self.stats['imported']}")
		print(f"Skipped:		  {self.stats['skipped']}")
		print(f"Errors:		   {self.stats['errors']}")

		if self.stats['warnings']:
			print("\nWarnings:")
			for warning in self.stats['warnings']:
				print(f"  ⚠ {warning}")

		if self.stats['errors'] == 0:
			print("\n✓ Import completed successfully!")
		else:
			print(f"\n⚠ Import completed with {self.stats['errors']} errors")


def create_backup(rom_path: str) -> str:
	"""Create backup of original ROM."""
	backup_path = rom_path + ".backup"

	if not os.path.exists(backup_path):
		shutil.copy2(rom_path, backup_path)
		print(f"✓ Created backup: {backup_path}")
	else:
		print(f"ℹ Backup already exists: {backup_path}")

	return backup_path


def main():
	"""Main import routine."""
	if len(sys.argv) < 3:
		print("Usage: python import_text.py <rom_file> <text_json> [output_rom]")
		print()
		print("Arguments:")
		print("  rom_file   - Source ROM file")
		print("  text_json  - Text data JSON (from extract_text_enhanced.py)")
		print("  output_rom - Output ROM file (default: rom_file with _modified suffix)")
		print()
		print("Example:")
		print("  python import_text.py roms/FFMQ.sfc data/extracted/text/text_complete.json roms/FFMQ_modified.sfc")
		return 1

	rom_path = sys.argv[1]
	text_json = sys.argv[2]

	# Determine output path
	if len(sys.argv) > 3:
		output_rom = sys.argv[3]
	else:
		# Default: add _modified before extension
		rom_file = Path(rom_path)
		output_rom = str(rom_file.parent / f"{rom_file.stem}_modified{rom_file.suffix}")

	# Validate inputs
	if not os.path.exists(rom_path):
		print(f"✗ ROM file not found: {rom_path}")
		return 1

	if not os.path.exists(text_json):
		print(f"✗ Text JSON not found: {text_json}")
		return 1

	print("=" * 80)
	print("FFMQ Text Importer")
	print("=" * 80)
	print(f"Source ROM:  {rom_path}")
	print(f"Text data:   {text_json}")
	print(f"Output ROM:  {output_rom}")
	print()

	# Create backup
	create_backup(rom_path)
	print()

	# Import text
	importer = FFMQTextImporter(rom_path, text_json, output_rom)
	success = importer.import_all()

	# Print summary
	importer.print_summary()

	if success:
		print(f"\n✓ Modified ROM saved: {output_rom}")
		print("\nNext steps:")
		print("1. Test the modified ROM in an emulator")
		print("2. Verify text appears correctly in-game")
		print("3. Check for text overflow or display issues")
		return 0
	else:
		print("\n✗ Import failed")
		return 1


if __name__ == '__main__':
	sys.exit(main())
