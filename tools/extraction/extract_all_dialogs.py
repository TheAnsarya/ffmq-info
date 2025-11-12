#!/usr/bin/env python3
"""
Extract ALL FFMQ dialogs with proper dictionary decoding.
Uses correct pointer table at 0x01B835 and dictionary at 0x01BA35.
"""

import sys
from pathlib import Path

class DialogExtractor:
	def __init__(self, rom_path: str):
		self.rom_path = Path(rom_path)
		self.rom = b''
		self.char_table = {}
		self.dictionary = {}
		
	def load_rom(self):
		"""Load ROM file."""
		self.rom = self.rom_path.read_bytes()
		print(f"Loaded ROM: {self.rom_path.name} ({len(self.rom)} bytes)")
		
	def load_char_table(self, table_path='simple.tbl'):
		"""Load character mappings.
		Note: Only load control codes (0x00-0x2F) and characters (0x80+).
		Dictionary entries (0x30-0x7E) will be loaded from ROM.
		"""
		with open(table_path, 'r', encoding='utf-8') as f:
			for line in f:
				line = line.strip()
				if not line or line.startswith('#') or '=' not in line:
					continue
				byte_str, char = line.split('=', 1)
				byte_val = int(byte_str, 16)
				# Only load control codes and character bytes, skip dictionary range
				if byte_val < 0x30 or byte_val >= 0x80:
					self.char_table[byte_val] = char
		print(f"Loaded {len(self.char_table)} character mappings")
		
	def load_dictionary(self):
		"""Load and decode dictionary entries."""
		dict_addr = 0x01BA35
		
		# First pass: load raw dictionary
		raw_dict = {}
		addr = dict_addr
		for i in range(80):
			byte_val = 0x30 + i
			length = self.rom[addr]
			addr += 1
			data = bytes(self.rom[addr:addr+length])
			addr += length
			raw_dict[byte_val] = data
		
		# Second pass: decode with recursion
		def decode_entry(byte_val, depth=0):
			if depth > 10:
				return f'[DEPTH:{byte_val:02X}]'
			if byte_val in self.dictionary:
				return self.dictionary[byte_val]
			
			if byte_val not in raw_dict:
				return f'[?{byte_val:02X}]'
			
			result = ''
			for b in raw_dict[byte_val]:
				if b < 0x30:  # Control code
					result += self.decode_control(b)
				elif b < 0x80:  # Dictionary reference
					result += decode_entry(b, depth + 1)
				else:  # Character
					result += self.char_table.get(b, f'#{b:02X}')
			
			self.dictionary[byte_val] = result
			return result
		
		# Decode all entries
		for i in range(80):
			decode_entry(0x30 + i)
		
		print(f"Decoded {len(self.dictionary)} dictionary entries")
		
	def decode_control(self, byte):
		"""Decode control code byte."""
		controls = {
			0x00: '[END]',
			0x01: '\n',  # newline
			0x02: '[WAIT]',
			0x03: '[ASTERISK]',
			0x04: '[NAME]',
			0x05: '[ITEM]',
			0x06: ' ',  # space
			0x1A: '[TEXTBOX_BELOW]',
			0x1B: '[TEXTBOX_ABOVE]',
			0x1F: '[CRYSTAL]',
		}
		return controls.get(byte, f'[CMD:{byte:02X}]')
		
	def decode_byte(self, byte):
		"""Decode a single byte."""
		if byte < 0x30:  # Control code
			return self.decode_control(byte)
		elif byte < 0x80:  # Dictionary
			return self.dictionary.get(byte, f'[D{byte:02X}]')
		else:  # Character
			return self.char_table.get(byte, f'#{byte:02X}')
	
	def extract_dialog(self, dialog_num):
		"""Extract and decode a specific dialog."""
		ptr_table = 0x01B835
		base_addr = 0x030000
		
		# Read pointer
		ptr_offset = ptr_table + (dialog_num * 2)
		ptr = self.rom[ptr_offset] | (self.rom[ptr_offset + 1] << 8)
		
		# Calculate dialog address
		# Pointers are SNES addresses in bank $03 ($8000-$FFFF range)
		# Convert to PC using LoROM formula: PC = 0x018000 + (snes_addr - 0x8000)
		dialog_addr = 0x018000 + (ptr - 0x8000)
		
		# Read until END (0x00) or max length
		dialog_bytes = []
		for i in range(512):
			if dialog_addr + i >= len(self.rom):
				break
			b = self.rom[dialog_addr + i]
			dialog_bytes.append(b)
			if b == 0x00:  # END
				break
		
		# Decode
		decoded = ''.join(self.decode_byte(b) for b in dialog_bytes)
		return decoded, dialog_bytes
	
	def extract_all(self):
		"""Extract all 117 dialogs."""
		print("\n" + "="*80)
		print("EXTRACTING ALL DIALOGS")
		print("="*80)
		
		for i in range(117):
			decoded, raw = self.extract_dialog(i)
			print(f"\nDialog 0x{i:02X}:")
			print(decoded)
			print(f"(Raw: {' '.join(f'{b:02X}' for b in raw[:20])}{'...' if len(raw) > 20 else ''})")
	
	def run(self, table_path='simple.tbl'):
		"""Run extraction."""
		self.load_rom()
		self.load_char_table(table_path)
		self.load_dictionary()
		self.extract_all()

if __name__ == '__main__':
	rom_path = sys.argv[1] if len(sys.argv) > 1 else r'roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc'
	table_path = sys.argv[2] if len(sys.argv) > 2 else 'simple.tbl'
	
	extractor = DialogExtractor(rom_path)
	extractor.run(table_path)
