#!/usr/bin/env python3
"""
FFMQ Dictionary Extractor
Extracts and decodes the dialog compression dictionary from ROM

Dictionary location: SNES $03:BA35 (PC 0x01BA35)
Format: 80 entries for bytes 0x30-0x7F
Each entry: [length_byte] [data_bytes...]
Data bytes can recursively reference other dictionary entries!
"""

import sys
from pathlib import Path
from typing import Dict, List, Tuple

class DictionaryExtractor:
	"""Extract and decode FFMQ dialog dictionary"""
	
	DICT_ADDR = 0x01BA35  # PC address of dictionary table
	DICT_ENTRIES = 80	 # Entries for 0x30-0x7F
	DICT_BASE = 0x30	  # First dictionary byte
	
	# Control codes (< 0x30)
	CONTROLS = {
		0x00: '[END]',
		0x01: '{newline}',
		0x02: '[WAIT]',
		0x03: '[ASTERISK]',
		0x04: '[NAME]',
		0x05: '[ITEM]',
		0x06: '[SPACE]',
		0x1A: '[TEXTBOX_BELOW]',
		0x1B: '[TEXTBOX_ABOVE]',
		0x1F: '[CRYSTAL]',
		0x23: '[CLEAR]',
		0x30: '[PARA]',
		0x36: '[PAGE]',
	}
	
	def __init__(self, rom_path: str, char_table_path: str = 'simple.tbl'):
		"""Initialize with ROM and character table"""
		self.rom_path = Path(rom_path)
		self.char_table_path = Path(char_table_path)
		self.rom: bytes = b''
		self.char_table = {}
		self.dictionary = {}  # byte -> decoded string
		self.raw_dictionary = {}  # byte -> raw bytes
		
	def load_rom(self):
		"""Load ROM data"""
		self.rom = self.rom_path.read_bytes()
		print(f"Loaded ROM: {self.rom_path.name} ({len(self.rom)} bytes)")
		
	def load_char_table(self):
		"""Load character table (0x80-0xFF → characters)"""
		with open(self.char_table_path, 'r', encoding='utf-8') as f:
			for line in f:
				line = line.strip()
				if not line or line.startswith('#') or '=' not in line:
					continue
				byte_str, char = line.split('=', 1)
				self.char_table[int(byte_str, 16)] = char
		print(f"Loaded {len(self.char_table)} character mappings from {self.char_table_path.name}")
		
	def extract_raw_dictionary(self):
		"""Extract raw dictionary entries (before decoding)"""
		addr = self.DICT_ADDR
		
		for i in range(self.DICT_ENTRIES):
			byte_val = self.DICT_BASE + i
			
			# Read length
			length = self.rom[addr]
			addr += 1
			
			# Read data bytes
			data = bytes(self.rom[addr:addr+length])
			addr += length
			
			self.raw_dictionary[byte_val] = data
			
		print(f"Extracted {len(self.raw_dictionary)} raw dictionary entries")
		
	def decode_byte(self, b: int, depth: int = 0, max_depth: int = 10) -> str:
		"""Decode a single byte with recursive dictionary expansion"""
		if depth > max_depth:
			return f'[DEPTH_LIMIT:{b:02X}]'
		
		# Control code
		if b < 0x30:
			return self.CONTROLS.get(b, f'[CMD:{b:02X}]')
		
		# Dictionary reference - recursively expand
		if 0x30 <= b < 0x80:
			if b in self.dictionary:
				return self.dictionary[b]  # Already decoded
			
			# Decode recursively
			if b not in self.raw_dictionary:
				return f'[MISSING_DICT:{b:02X}]'
			
			raw_bytes = self.raw_dictionary[b]
			decoded = ''.join(self.decode_byte(rb, depth+1, max_depth) for rb in raw_bytes)
			self.dictionary[b] = decoded  # Cache
			return decoded
		
		# Direct character (0x80-0xFF)
		return self.char_table.get(b, f'[CHR:{b:02X}]')
	
	def decode_dictionary(self):
		"""Decode all dictionary entries"""
		print("\nDecoding dictionary entries...")
		
		for byte_val in sorted(self.raw_dictionary.keys()):
			decoded = self.decode_byte(byte_val)
			self.dictionary[byte_val] = decoded
		
		print(f"Decoded {len(self.dictionary)} dictionary entries")
	
	def print_dictionary(self):
		"""Print all dictionary entries"""
		print("\n" + "="*80)
		print("FFMQ DIALOG DICTIONARY (0x30-0x7F)")
		print("="*80)
		
		for byte_val in sorted(self.dictionary.keys()):
			raw_bytes = self.raw_dictionary[byte_val]
			decoded = self.dictionary[byte_val]
			hex_str = ' '.join(f'{b:02X}' for b in raw_bytes)
			
			print(f"0x{byte_val:02X}: {decoded}")
			print(f"	   Raw: [{len(raw_bytes)}] {hex_str}")
			print()
	
	def export_complex_tbl(self, output_path: str = 'complex_extracted.tbl'):
		"""Export dictionary as a .tbl file"""
		with open(output_path, 'w', encoding='utf-8') as f:
			# Write control codes first
			for byte_val, text in sorted(self.CONTROLS.items()):
				f.write(f'{byte_val:02X}={text}\n')
			
			f.write('\n# Dictionary Entries (0x30-0x7F)\n')
			
			# Write dictionary entries
			for byte_val in sorted(self.dictionary.keys()):
				decoded = self.dictionary[byte_val]
				f.write(f'{byte_val:02X}={decoded}\n')
			
			f.write('\n# Direct Characters (0x80-0xFF)\n')
			
			# Write simple.tbl character mappings
			for byte_val in sorted(self.char_table.keys()):
				char = self.char_table[byte_val]
				f.write(f'{byte_val:02X}={char}\n')
		
		print(f"\nExported dictionary to {output_path}")
	
	def test_dialog(self, dialog_id: int):
		"""Test decoding a specific dialog"""
		ptr_table = 0x00D636
		bank_offset = 0x018000
		
		# Get pointer
		ptr_idx = dialog_id * 2
		ptr = int.from_bytes(self.rom[ptr_table + ptr_idx:ptr_table + ptr_idx + 2], 'little')
		addr = bank_offset + (ptr & 0x7FFF)
		
		# Read dialog bytes
		dialog_bytes = []
		for i in range(512):
			if addr + i >= len(self.rom):
				break
			b = self.rom[addr + i]
			dialog_bytes.append(b)
			if b == 0x00:  # END
				break
		
		# Decode
		decoded = ''.join(self.decode_byte(b) for b in dialog_bytes)
		
		print(f"\n" + "="*80)
		print(f"DIALOG 0x{dialog_id:02X} TEST")
		print("="*80)
		print(f"Raw bytes: {' '.join(f'{b:02X}' for b in dialog_bytes[:64])}")
		print(f"\nDecoded:\n{decoded}")
	
	def run(self):
		"""Run full extraction process"""
		self.load_rom()
		self.load_char_table()
		self.extract_raw_dictionary()
		self.decode_dictionary()
		self.print_dictionary()
		self.export_complex_tbl()
		
		# Test known dialogs
		print("\n" + "="*80)
		print("TESTING KNOWN DIALOGS")
		print("="*80)
		self.test_dialog(0x59)  # "For years Mac's been studying a Prophecy"
		self.test_dialog(0x00)  # First dialog
		self.test_dialog(0x21)  # Another test


if __name__ == '__main__':
	rom_path = sys.argv[1] if len(sys.argv) > 1 else r'roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc'
	
	extractor = DictionaryExtractor(rom_path)
	extractor.run()
