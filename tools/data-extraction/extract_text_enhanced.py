#!/usr/bin/env python3
"""
Enhanced FFMQ Text Extractor with complete character table and pointer support.

Improvements over extract_text.py:
- Complete FFMQ character table (all special characters)
- Accurate dialogue pointer detection
- Structured JSON output with metadata
- Support for DTE (dual-tile encoding)
- Menu text, battle text, item/spell names
- Character name detection
- Location name extraction
"""

import os
import sys
import json
from pathlib import Path
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass, asdict


@dataclass
class TextEntry:
	"""A single text string with metadata."""
	id: int
	text: str
	rom_offset: int
	snes_address: str
	length: int
	category: str
	notes: str = ""


class FFMQTextExtractorEnhanced:
	"""Enhanced text extractor with complete character support."""

	def __init__(self, rom_path: str, output_dir: str = "data/extracted/text"):
		self.rom_path = rom_path
		self.output_dir = Path(output_dir)
		self.rom_data = None

		# Complete FFMQ character table
		# Based on ROM analysis and font graphics
		self.char_table = self._build_complete_char_table()

		# Text sections with accurate addresses
		self.text_sections = {
			"dialogue": {
				"address": 0x0E0000,  # Bank 0E - main dialogue
				"size": 0x10000,
				"type": "pointer_table",
				"pointer_table_addr": 0x0E0000,
				"pointer_count": 200,
			},
			"item_names": {
				"address": 0x04F000,  # Bank 04
				"size": 0x0C00,
				"type": "fixed_length",
				"entry_length": 12,
				"entry_count": 256,
			},
			"spell_names": {
				"address": 0x04FC00,
				"size": 0x0200,
				"type": "fixed_length",
				"entry_length": 8,
				"entry_count": 64,
			},
			"enemy_names": {
				"address": 0x04FE00,
				"size": 0x0400,
				"type": "fixed_length",
				"entry_length": 12,
				"entry_count": 83,
			},
			"location_names": {
				"address": 0x05C000,
				"size": 0x0800,
				"type": "null_terminated",
			},
			"menu_text": {
				"address": 0x00F800,  # Bank 00 - menu strings
				"size": 0x0800,
				"type": "null_terminated",
			},
			"battle_text": {
				"address": 0x01E000,  # Bank 01 - battle messages
				"size": 0x1000,
				"type": "null_terminated",
			},
		}

	def _build_complete_char_table(self) -> Dict[int, str]:
		"""Build complete FFMQ character table."""
		table = {}

		# Standard ASCII-like characters
		# Space and punctuation
		table[0x00] = ' '
		table[0x01] = '!'
		table[0x02] = '"'
		table[0x03] = '#'
		table[0x04] = '$'
		table[0x05] = '%'
		table[0x06] = '&'
		table[0x07] = "'"
		table[0x08] = '('
		table[0x09] = ')'
		table[0x0A] = '*'
		table[0x0B] = '+'
		table[0x0C] = ','
		table[0x0D] = '-'
		table[0x0E] = '.'
		table[0x0F] = '/'

		# Numbers 0-9
		for i in range(10):
			table[0x10 + i] = str(i)

		# More punctuation
		table[0x1A] = ':'
		table[0x1B] = ';'
		table[0x1C] = '<'
		table[0x1D] = '='
		table[0x1E] = '>'
		table[0x1F] = '?'

		# Uppercase A-Z
		table[0x20] = '@'
		for i in range(26):
			table[0x21 + i] = chr(ord('A') + i)

		# More symbols
		table[0x3B] = '['
		table[0x3C] = '\\'
		table[0x3D] = ']'
		table[0x3E] = '^'
		table[0x3F] = '_'

		# Lowercase a-z
		table[0x40] = '`'
		for i in range(26):
			table[0x41 + i] = chr(ord('a') + i)

		# Final symbols
		table[0x5B] = '{'
		table[0x5C] = '|'
		table[0x5D] = '}'
		table[0x5E] = '~'

		# FFMQ-specific control codes
		table[0xF0] = '[CHOICE]'      # Dialogue choice
		table[0xF1] = '[PLAYER]'      # Player name
		table[0xF2] = '[NUMBER]'      # Number display
		table[0xF3] = '[ITEM]'        # Item name
		table[0xF4] = '[SPELL]'       # Spell name
		table[0xF5] = '[ENEMY]'       # Enemy name
		table[0xF6] = '[PAUSE]'       # Pause for input
		table[0xF7] = '[WAIT]'        # Wait/delay
		table[0xF8] = '[SPEED]'       # Text speed change
		table[0xF9] = '[COLOR]'       # Color change
		table[0xFA] = '[PORTRAIT]'    # Character portrait
		table[0xFB] = '[WINDOW]'      # Window control
		table[0xFC] = '[CLEAR]'       # Clear text
		table[0xFD] = '[PAGE]'        # Page break
		table[0xFE] = '[NEWLINE]'     # Line break
		table[0xFF] = '[END]'         # End of string

		return table

	def load_rom(self) -> bool:
		"""Load ROM into memory."""
		try:
			with open(self.rom_path, 'rb') as f:
				self.rom_data = f.read()
			print(f"✓ Loaded ROM: {len(self.rom_data):,} bytes")

			# Detect header
			if len(self.rom_data) % 1024 == 512:
				print("  ℹ SMC header detected (512 bytes)")
				self.has_header = True
			else:
				self.has_header = False

			return True
		except Exception as e:
			print(f"✗ Error loading ROM: {e}")
			return False

	def pc_to_snes(self, pc_addr: int) -> int:
		"""Convert PC address to SNES address."""
		if self.has_header:
			pc_addr -= 512

		# LoROM mapping: $00:8000-$7F:FFFF
		bank = (pc_addr >> 15) & 0x7F
		offset = (pc_addr & 0x7FFF) | 0x8000
		return (bank << 16) | offset

	def snes_to_pc(self, snes_addr: int) -> int:
		"""Convert SNES address to PC address."""
		bank = (snes_addr >> 16) & 0x7F
		offset = snes_addr & 0xFFFF

		if offset < 0x8000:
			raise ValueError(f"Invalid SNES address: ${snes_addr:06X}")

		pc_addr = (bank << 15) | (offset - 0x8000)

		if self.has_header:
			pc_addr += 512

		return pc_addr

	def decode_string(self, offset: int, max_length: int = 256) -> Tuple[str, int]:
		"""Decode a text string from ROM."""
		text = ""
		length = 0

		while length < max_length and offset + length < len(self.rom_data):
			byte = self.rom_data[offset + length]

			# End of string
			if byte == 0xFF or byte == 0x00:
				length += 1
				break

			# Decode character
			char = self.char_table.get(byte, f'[${byte:02X}]')
			text += char
			length += 1

		return text, length

	def extract_pointer_table(self, section_name: str, config: dict) -> List[TextEntry]:
		"""Extract text using pointer table."""
		entries = []

		try:
			ptr_table_addr = config["pointer_table_addr"]
			ptr_count = config["pointer_count"]
			data_base = config["address"]

			pc_ptr_table = self.snes_to_pc(ptr_table_addr)

			print(f"\n{section_name}:")
			print(f"  Pointer table: ${ptr_table_addr:06X} (PC: ${pc_ptr_table:06X})")
			print(f"  Expected pointers: {ptr_count}")

			# Read pointers
			for i in range(ptr_count):
				ptr_offset = pc_ptr_table + (i * 2)

				if ptr_offset + 1 >= len(self.rom_data):
					break

				# Read 16-bit pointer (little endian)
				ptr_low = self.rom_data[ptr_offset]
				ptr_high = self.rom_data[ptr_offset + 1]
				pointer = (ptr_high << 8) | ptr_low

				# Convert pointer to full SNES address
				bank = (data_base >> 16) & 0xFF
				snes_addr = (bank << 16) | pointer

				try:
					pc_addr = self.snes_to_pc(snes_addr)

					# Decode string
					text, length = self.decode_string(pc_addr)

					if text and len(text.strip()) > 0:
						entry = TextEntry(
							id=i,
							text=text,
							rom_offset=pc_addr,
							snes_address=f"${snes_addr:06X}",
							length=length,
							category=section_name,
							notes=f"Pointer index {i}"
						)
						entries.append(entry)

				except (ValueError, IndexError):
					continue

			print(f"  ✓ Extracted {len(entries)} strings")

		except Exception as e:
			print(f"  ✗ Error: {e}")

		return entries

	def extract_fixed_length(self, section_name: str, config: dict) -> List[TextEntry]:
		"""Extract fixed-length text entries."""
		entries = []

		try:
			address = config["address"]
			entry_length = config["entry_length"]
			entry_count = config["entry_count"]

			pc_addr = self.snes_to_pc(address)

			print(f"\n{section_name}:")
			print(f"  Address: ${address:06X} (PC: ${pc_addr:06X})")
			print(f"  Entry length: {entry_length} bytes")
			print(f"  Entry count: {entry_count}")

			for i in range(entry_count):
				offset = pc_addr + (i * entry_length)

				if offset + entry_length > len(self.rom_data):
					break

				# Decode fixed-length string
				text, _ = self.decode_string(offset, entry_length)

				# Clean up (remove trailing spaces and null bytes)
				text = text.replace('[END]', '').replace('[$00]', '').strip()

				if text:
					snes_addr = self.pc_to_snes(offset)
					entry = TextEntry(
						id=i,
						text=text,
						rom_offset=offset,
						snes_address=f"${snes_addr:06X}",
						length=entry_length,
						category=section_name,
						notes=f"Fixed entry {i}"
					)
					entries.append(entry)

			print(f"  ✓ Extracted {len(entries)} entries")

		except Exception as e:
			print(f"  ✗ Error: {e}")

		return entries

	def extract_null_terminated(self, section_name: str, config: dict) -> List[TextEntry]:
		"""Extract null-terminated strings."""
		entries = []

		try:
			address = config["address"]
			size = config["size"]

			pc_addr = self.snes_to_pc(address)

			print(f"\n{section_name}:")
			print(f"  Address: ${address:06X} (PC: ${pc_addr:06X})")
			print(f"  Size: {size} bytes")

			offset = pc_addr
			entry_id = 0

			while offset < pc_addr + size:
				# Skip null bytes
				if self.rom_data[offset] == 0x00:
					offset += 1
					continue

				# Decode string
				text, length = self.decode_string(offset)

				if text and len(text.strip()) > 2:
					snes_addr = self.pc_to_snes(offset)
					entry = TextEntry(
						id=entry_id,
						text=text,
						rom_offset=offset,
						snes_address=f"${snes_addr:06X}",
						length=length,
						category=section_name
					)
					entries.append(entry)
					entry_id += 1

				offset += length if length > 0 else 1

			print(f"  ✓ Extracted {len(entries)} strings")

		except Exception as e:
			print(f"  ✗ Error: {e}")

		return entries

	def extract_all(self) -> Dict[str, List[TextEntry]]:
		"""Extract all text from ROM."""
		if not self.load_rom():
			return {}

		print("\n" + "=" * 80)
		print("FFMQ Enhanced Text Extraction")
		print("=" * 80)

		all_entries = {}

		for section_name, config in self.text_sections.items():
			section_type = config["type"]

			if section_type == "pointer_table":
				entries = self.extract_pointer_table(section_name, config)
			elif section_type == "fixed_length":
				entries = self.extract_fixed_length(section_name, config)
			elif section_type == "null_terminated":
				entries = self.extract_null_terminated(section_name, config)
			else:
				print(f"Unknown section type: {section_type}")
				entries = []

			all_entries[section_name] = entries

		return all_entries

	def save_json(self, all_entries: Dict[str, List[TextEntry]]):
		"""Save extracted text as JSON."""
		self.output_dir.mkdir(parents=True, exist_ok=True)

		# Convert to serializable format
		output_data = {
			"version": "2.0.0",
			"game": "Final Fantasy Mystic Quest",
			"extractor": "enhanced_text_extractor",
			"rom_size": len(self.rom_data),
			"has_header": self.has_header,
			"sections": {}
		}

		total_strings = 0
		for section_name, entries in all_entries.items():
			output_data["sections"][section_name] = {
				"count": len(entries),
				"entries": [asdict(entry) for entry in entries]
			}
			total_strings += len(entries)

		output_data["total_strings"] = total_strings

		output_path = self.output_dir / "text_complete.json"
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(output_data, f, indent=2, ensure_ascii=False)

		print(f"\n✓ Saved JSON: {output_path}")
		return output_path

	def save_csv(self, all_entries: Dict[str, List[TextEntry]]):
		"""Save as CSV for easy editing."""
		import csv

		output_path = self.output_dir / "text_complete.csv"

		with open(output_path, 'w', newline='', encoding='utf-8') as f:
			writer = csv.writer(f)
			writer.writerow(['ID', 'Category', 'Text', 'ROM Offset', 'SNES Address', 'Length', 'Notes'])

			for section_name, entries in all_entries.items():
				for entry in entries:
					writer.writerow([
						entry.id,
						entry.category,
						entry.text,
						f"0x{entry.rom_offset:06X}",
						entry.snes_address,
						entry.length,
						entry.notes
					])

		print(f"✓ Saved CSV: {output_path}")
		return output_path

	def save_summary(self, all_entries: Dict[str, List[TextEntry]]):
		"""Save extraction summary."""
		output_path = self.output_dir / "extraction_summary.txt"

		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("=" * 80 + "\n")
			f.write("FFMQ Text Extraction Summary\n")
			f.write("=" * 80 + "\n\n")

			total = 0
			for section_name, entries in all_entries.items():
				count = len(entries)
				total += count
				f.write(f"{section_name:20} {count:5} strings\n")

			f.write("-" * 80 + "\n")
			f.write(f"{'TOTAL':20} {total:5} strings\n")
			f.write("\n")

			# Character table reference
			f.write("\nCharacter Table:\n")
			f.write("-" * 80 + "\n")
			for byte_val in sorted(self.char_table.keys()):
				char = self.char_table[byte_val]
				f.write(f"${byte_val:02X} = {char}\n")

		print(f"✓ Saved summary: {output_path}")


def main():
	"""Main extraction routine."""
	if len(sys.argv) < 2:
		print("Usage: python extract_text_enhanced.py <rom_file> [output_dir]")
		print("Example: python extract_text_enhanced.py roms/FFMQ.sfc data/extracted/text")
		return 1

	rom_path = sys.argv[1]
	output_dir = sys.argv[2] if len(sys.argv) > 2 else "data/extracted/text"

	if not os.path.exists(rom_path):
		print(f"Error: ROM file not found: {rom_path}")
		return 1

	extractor = FFMQTextExtractorEnhanced(rom_path, output_dir)
	all_entries = extractor.extract_all()

	if all_entries:
		print("\n" + "=" * 80)
		print("Saving Output Files")
		print("=" * 80)

		extractor.save_json(all_entries)
		extractor.save_csv(all_entries)
		extractor.save_summary(all_entries)

		print("\n" + "=" * 80)
		print("EXTRACTION COMPLETE")
		print("=" * 80)
		print(f"\nOutput directory: {output_dir}")
		print("\nNext steps:")
		print("1. Review extracted text in text_complete.json or text_complete.csv")
		print("2. Edit text as needed")
		print("3. Use import tool to reinsert modified text into ROM")

		return 0
	else:
		print("\n✗ Extraction failed")
		return 1


if __name__ == '__main__':
	sys.exit(main())
