#!/usr/bin/env python3
"""
FFMQ Dialog Editor - Text and dialog management

Dialog Features:
- Text editing
- Character mapping
- Dialog flow control
- Text compression
- Multi-language support
- Font customization

Dialog Types:
- NPC dialog
- System messages
- Battle text
- Item descriptions
- Tutorial text
- Cutscene dialog

Features:
- Table file support
- Text searching
- Batch editing
- Preview rendering
- Export/import
- Character counting

Usage:
	python ffmq_dialog_editor.py --extract rom.smc dialog.json
	python ffmq_dialog_editor.py --insert dialog.json rom.smc
	python ffmq_dialog_editor.py --search "Benjamin" dialog.json
	python ffmq_dialog_editor.py --table simple.tbl
	python ffmq_dialog_editor.py --stats dialog.json
"""

import argparse
import json
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict, field


@dataclass
class DialogEntry:
	"""Dialog entry"""
	entry_id: int
	text: str
	speaker: str = ""
	location: str = ""
	rom_offset: int = 0
	compressed: bool = False
	tags: List[str] = field(default_factory=list)


@dataclass
class CharacterMapping:
	"""Character table mapping"""
	char: str
	value: int


class DialogEditor:
	"""Dialog and text editor"""
	
	# Default character table (simplified)
	DEFAULT_TABLE = {
		0x20: ' ',
		0x41: 'A', 0x42: 'B', 0x43: 'C', 0x44: 'D', 0x45: 'E',
		0x46: 'F', 0x47: 'G', 0x48: 'H', 0x49: 'I', 0x4A: 'J',
		0x4B: 'K', 0x4C: 'L', 0x4D: 'M', 0x4E: 'N', 0x4F: 'O',
		0x50: 'P', 0x51: 'Q', 0x52: 'R', 0x53: 'S', 0x54: 'T',
		0x55: 'U', 0x56: 'V', 0x57: 'W', 0x58: 'X', 0x59: 'Y',
		0x5A: 'Z',
		0x61: 'a', 0x62: 'b', 0x63: 'c', 0x64: 'd', 0x65: 'e',
		0x66: 'f', 0x67: 'g', 0x68: 'h', 0x69: 'i', 0x6A: 'j',
		0x6B: 'k', 0x6C: 'l', 0x6D: 'm', 0x6E: 'n', 0x6F: 'o',
		0x70: 'p', 0x71: 'q', 0x72: 'r', 0x73: 's', 0x74: 't',
		0x75: 'u', 0x76: 'v', 0x77: 'w', 0x78: 'x', 0x79: 'y',
		0x7A: 'z',
		0x30: '0', 0x31: '1', 0x32: '2', 0x33: '3', 0x34: '4',
		0x35: '5', 0x36: '6', 0x37: '7', 0x38: '8', 0x39: '9',
		0x2E: '.', 0x2C: ',', 0x21: '!', 0x3F: '?', 0x27: "'",
		0x00: '[END]',
		0x01: '[NEWLINE]',
		0x02: '[WAIT]',
		0xFE: '[PLAYER]',
		0xFF: '[END]',
	}
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.char_table = self.DEFAULT_TABLE.copy()
		self.reverse_table = {v: k for k, v in self.char_table.items() if len(v) == 1}
		self.dialog_entries: List[DialogEntry] = []
		self.rom_data: Optional[bytearray] = None
	
	def load_table(self, table_path: Path) -> bool:
		"""Load character table file"""
		try:
			self.char_table = {}
			
			with open(table_path, 'r', encoding='utf-8') as f:
				for line in f:
					line = line.strip()
					if not line or line.startswith('#'):
						continue
					
					# Parse format: HH=C or HH=[TAG]
					parts = line.split('=', 1)
					if len(parts) != 2:
						continue
					
					value = int(parts[0], 16)
					char = parts[1]
					
					self.char_table[value] = char
			
			# Build reverse table
			self.reverse_table = {v: k for k, v in self.char_table.items() if len(v) == 1}
			
			if self.verbose:
				print(f"✓ Loaded character table: {len(self.char_table)} entries")
			
			return True
		
		except Exception as e:
			print(f"Error loading table: {e}")
			return False
	
	def load_rom(self, rom_path: Path) -> bool:
		"""Load ROM file"""
		try:
			with open(rom_path, 'rb') as f:
				self.rom_data = bytearray(f.read())
			
			if self.verbose:
				print(f"✓ Loaded ROM: {rom_path} ({len(self.rom_data):,} bytes)")
			
			return True
		
		except Exception as e:
			print(f"Error loading ROM: {e}")
			return False
	
	def save_rom(self, output_path: Path) -> bool:
		"""Save ROM file"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return False
		
		try:
			with open(output_path, 'wb') as f:
				f.write(self.rom_data)
			
			if self.verbose:
				print(f"✓ Saved ROM: {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error saving ROM: {e}")
			return False
	
	def decode_text(self, data: bytes) -> str:
		"""Decode bytes to text"""
		text = []
		
		for byte in data:
			if byte in self.char_table:
				char = self.char_table[byte]
				
				# Check for terminator
				if char in ['[END]', '[TERM]']:
					break
				
				text.append(char)
			else:
				text.append(f'<{byte:02X}>')
		
		return ''.join(text)
	
	def encode_text(self, text: str) -> bytes:
		"""Encode text to bytes"""
		data = bytearray()
		
		i = 0
		while i < len(text):
			# Check for special tags
			if text[i] == '[':
				end = text.find(']', i)
				if end != -1:
					tag = text[i:end+1]
					
					# Find tag in table
					for value, char in self.char_table.items():
						if char == tag:
							data.append(value)
							break
					
					i = end + 1
					continue
			
			# Normal character
			char = text[i]
			if char in self.reverse_table:
				data.append(self.reverse_table[char])
			else:
				# Unknown character - skip or use placeholder
				data.append(0x3F)  # '?'
			
			i += 1
		
		# Add terminator
		data.append(0xFF)
		
		return bytes(data)
	
	def extract_dialog(self, start_offset: int, count: int) -> List[DialogEntry]:
		"""Extract dialog from ROM"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return []
		
		self.dialog_entries = []
		
		for i in range(count):
			# Read pointer (example: 2-byte pointers)
			pointer_offset = start_offset + (i * 2)
			
			if pointer_offset + 2 > len(self.rom_data):
				break
			
			pointer = int.from_bytes(
				self.rom_data[pointer_offset:pointer_offset+2],
				byteorder='little'
			)
			
			# Read text (until terminator)
			text_data = bytearray()
			offset = pointer
			
			while offset < len(self.rom_data):
				byte = self.rom_data[offset]
				text_data.append(byte)
				
				if byte == 0xFF:  # Terminator
					break
				
				offset += 1
			
			# Decode text
			text = self.decode_text(text_data)
			
			entry = DialogEntry(
				entry_id=i,
				text=text,
				rom_offset=pointer
			)
			
			self.dialog_entries.append(entry)
		
		if self.verbose:
			print(f"✓ Extracted {len(self.dialog_entries)} dialog entries")
		
		return self.dialog_entries
	
	def insert_dialog(self) -> bool:
		"""Insert dialog into ROM"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return False
		
		for entry in self.dialog_entries:
			# Encode text
			data = self.encode_text(entry.text)
			
			# Write to ROM
			offset = entry.rom_offset
			
			if offset + len(data) > len(self.rom_data):
				print(f"Warning: Entry {entry.entry_id} exceeds ROM size")
				continue
			
			self.rom_data[offset:offset+len(data)] = data
		
		if self.verbose:
			print(f"✓ Inserted {len(self.dialog_entries)} dialog entries")
		
		return True
	
	def search_dialog(self, query: str) -> List[DialogEntry]:
		"""Search dialog entries"""
		results = []
		
		query_lower = query.lower()
		
		for entry in self.dialog_entries:
			if query_lower in entry.text.lower():
				results.append(entry)
		
		if self.verbose:
			print(f"✓ Found {len(results)} matches")
		
		return results
	
	def replace_text(self, old_text: str, new_text: str) -> int:
		"""Replace text in all entries"""
		count = 0
		
		for entry in self.dialog_entries:
			if old_text in entry.text:
				entry.text = entry.text.replace(old_text, new_text)
				count += 1
		
		if self.verbose:
			print(f"✓ Replaced text in {count} entries")
		
		return count
	
	def export_json(self, output_path: Path) -> bool:
		"""Export dialog to JSON"""
		try:
			data = {
				'entries': [asdict(e) for e in self.dialog_entries]
			}
			
			with open(output_path, 'w', encoding='utf-8') as f:
				json.dump(data, f, indent='\t', ensure_ascii=False)
			
			if self.verbose:
				print(f"✓ Exported dialog to {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting dialog: {e}")
			return False
	
	def import_json(self, input_path: Path) -> bool:
		"""Import dialog from JSON"""
		try:
			with open(input_path, 'r', encoding='utf-8') as f:
				data = json.load(f)
			
			self.dialog_entries = []
			for entry_data in data['entries']:
				entry = DialogEntry(**entry_data)
				self.dialog_entries.append(entry)
			
			if self.verbose:
				print(f"✓ Imported {len(self.dialog_entries)} entries")
			
			return True
		
		except Exception as e:
			print(f"Error importing dialog: {e}")
			return False
	
	def print_statistics(self) -> None:
		"""Print dialog statistics"""
		if not self.dialog_entries:
			print("No dialog entries loaded")
			return
		
		total_chars = sum(len(e.text) for e in self.dialog_entries)
		avg_chars = total_chars / len(self.dialog_entries) if self.dialog_entries else 0
		
		print(f"\n=== Dialog Statistics ===\n")
		print(f"Total Entries: {len(self.dialog_entries)}")
		print(f"Total Characters: {total_chars:,}")
		print(f"Average Length: {avg_chars:.1f} characters")
		
		# Longest entry
		longest = max(self.dialog_entries, key=lambda e: len(e.text))
		print(f"\nLongest Entry: #{longest.entry_id}")
		print(f"Length: {len(longest.text)} characters")
		print(f"Text: {longest.text[:80]}...")
	
	def print_entries(self, limit: int = 10) -> None:
		"""Print dialog entries"""
		print(f"\n=== Dialog Entries ===\n")
		
		for entry in self.dialog_entries[:limit]:
			print(f"Entry #{entry.entry_id} (0x{entry.rom_offset:06X}):")
			print(f"  {entry.text}")
			print()
		
		if len(self.dialog_entries) > limit:
			print(f"... and {len(self.dialog_entries) - limit} more entries")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Dialog Editor')
	parser.add_argument('--table', type=str, help='Character table file')
	parser.add_argument('--extract', nargs=2, metavar=('ROM', 'OUTPUT'),
					   help='Extract dialog from ROM')
	parser.add_argument('--insert', nargs=2, metavar=('DIALOG', 'ROM'),
					   help='Insert dialog into ROM')
	parser.add_argument('--search', type=str, metavar='QUERY',
					   help='Search dialog')
	parser.add_argument('--replace', nargs=2, metavar=('OLD', 'NEW'),
					   help='Replace text')
	parser.add_argument('--import', type=str, dest='import_file',
					   metavar='FILE', help='Import dialog from JSON')
	parser.add_argument('--export', type=str, metavar='FILE',
					   help='Export dialog to JSON')
	parser.add_argument('--stats', action='store_true', help='Show statistics')
	parser.add_argument('--list', action='store_true', help='List entries')
	parser.add_argument('--start-offset', type=lambda x: int(x, 0),
					   default=0x80000, help='Dialog start offset')
	parser.add_argument('--count', type=int, default=100,
					   help='Number of entries to extract')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = DialogEditor(verbose=args.verbose)
	
	# Load table
	if args.table:
		editor.load_table(Path(args.table))
	
	# Extract
	if args.extract:
		rom_path, output_path = args.extract
		editor.load_rom(Path(rom_path))
		editor.extract_dialog(args.start_offset, args.count)
		editor.export_json(Path(output_path))
		return 0
	
	# Import
	if args.import_file:
		editor.import_json(Path(args.import_file))
	
	# Insert
	if args.insert:
		dialog_path, rom_path = args.insert
		editor.import_json(Path(dialog_path))
		editor.load_rom(Path(rom_path))
		editor.insert_dialog()
		editor.save_rom(Path(rom_path))
		return 0
	
	# Search
	if args.search:
		results = editor.search_dialog(args.search)
		
		for entry in results:
			print(f"Entry #{entry.entry_id}: {entry.text}")
		
		return 0
	
	# Replace
	if args.replace:
		old, new = args.replace
		editor.replace_text(old, new)
		
		if args.export:
			editor.export_json(Path(args.export))
		
		return 0
	
	# Export
	if args.export:
		editor.export_json(Path(args.export))
		return 0
	
	# Statistics
	if args.stats:
		editor.print_statistics()
		return 0
	
	# List
	if args.list or not any([args.extract, args.insert, args.search, args.replace, args.export, args.stats]):
		editor.print_entries()
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
