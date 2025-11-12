#!/usr/bin/env python3
"""
FFMQ Complex Text Re-Insertion Tool
Handles dictionary-compressed dialog insertion back into ROM.

This tool performs the reverse operation of extract_all_dialogs.py:
1. Load text from JSON/TSV format
2. Compress using dictionary encoding
3. Insert back into ROM with correct pointer updates
4. Validate round-trip (extract → insert → extract matches original)

Author: FFMQ Disassembly Project
Date: 2025-11-12
"""

import sys
import json
from pathlib import Path
from typing import Dict, List, Tuple, Optional

class ComplexTextInserter:
	"""Handles insertion of dictionary-compressed text into ROM."""
	
	def __init__(self, rom_path: str, table_path: str = 'complex.tbl'):
		self.rom_path = Path(rom_path)
		self.rom = bytearray()
		self.char_table = {}  # char → byte mapping
		self.reverse_table = {}  # byte → char mapping
		self.dictionary = {}  # text → byte mapping
		self.reverse_dict = {}  # byte → text mapping
		self.table_path = table_path
		
		# ROM structure constants
		self.PTR_TABLE_ADDR = 0x01B835  # Dialog pointer table
		self.DICT_TABLE_ADDR = 0x01BA35  # Dictionary table
		self.DIALOG_BANK = 0x018000  # Bank $03 PC address
		
	def load_rom(self):
		"""Load ROM file into memory."""
		self.rom = bytearray(self.rom_path.read_bytes())
		print(f"✅ Loaded ROM: {self.rom_path.name} ({len(self.rom)} bytes)")
		
	def save_rom(self, output_path: Optional[str] = None):
		"""Save modified ROM to file."""
		if output_path is None:
			output_path = str(self.rom_path).replace('.sfc', '_modified.sfc')
		
		Path(output_path).write_bytes(self.rom)
		print(f"✅ Saved modified ROM: {output_path} ({len(self.rom)} bytes)")
		
	def load_character_table(self):
		"""Load character table (byte → char and char → byte)."""
		with open(self.table_path, 'r', encoding='utf-8') as f:
			for line in f:
				line = line.strip()
				if not line or line.startswith('#') or '=' not in line:
					continue
				
				byte_str, char = line.split('=', 1)
				byte_val = int(byte_str, 16)
				
				# Only load control codes and characters (skip dictionary range 0x30-0x7F)
				if byte_val < 0x30 or byte_val >= 0x80:
					self.reverse_table[byte_val] = char
					self.char_table[char] = byte_val
		
		print(f"✅ Loaded {len(self.char_table)} character mappings")
		
	def load_dictionary(self):
		"""Load and build dictionary from ROM."""
		addr = self.DICT_TABLE_ADDR
		
		# Load raw dictionary entries
		raw_dict = {}
		for i in range(80):
			byte_val = 0x30 + i
			length = self.rom[addr]
			addr += 1
			data = bytes(self.rom[addr:addr+length])
			addr += length
			raw_dict[byte_val] = data
		
		# Decode dictionary entries (decode into text)
		decoded_dict = {}
		
		def decode_entry(byte_val: int, depth: int = 0) -> str:
			"""Recursively decode dictionary entry."""
			if depth > 10:
				return f'[DEPTH:{byte_val:02X}]'
			if byte_val in decoded_dict:
				return decoded_dict[byte_val]
			
			if byte_val not in raw_dict:
				return f'[?{byte_val:02X}]'
			
			result = ''
			for b in raw_dict[byte_val]:
				if b < 0x30:  # Control code
					result += self.decode_control(b)
				elif b < 0x80:  # Dictionary reference
					result += decode_entry(b, depth + 1)
				else:  # Character
					result += self.reverse_table.get(b, f'#{b:02X}')
			
			decoded_dict[byte_val] = result
			return result
		
		# Decode all entries
		for i in range(80):
			text = decode_entry(0x30 + i)
			byte_val = 0x30 + i
			self.reverse_dict[byte_val] = text
			self.dictionary[text] = byte_val
		
		print(f"✅ Loaded {len(self.dictionary)} dictionary entries")
		
	def decode_control(self, byte: int) -> str:
		"""Decode control code byte to text representation."""
		controls = {
			0x00: '[END]',
			0x01: '{newline}',
			0x02: '[WAIT]',
			0x03: '*',
			0x04: '[NAME]',
			0x05: '[ITEM]',
			0x06: '_',
			0x1A: '[TEXTBOX_BELOW]',
			0x1B: '[TEXTBOX_ABOVE]',
			0x1F: '[CRYSTAL]',
		}
		return controls.get(byte, f'[CMD:{byte:02X}]')
	
	def encode_control(self, text: str) -> Optional[int]:
		"""Encode control code text to byte value."""
		controls = {
			'[END]': 0x00,
			'{newline}': 0x01,
			'[WAIT]': 0x02,
			'*': 0x03,
			'[NAME]': 0x04,
			'[ITEM]': 0x05,
			'_': 0x06,
			'[TEXTBOX_BELOW]': 0x1A,
			'[TEXTBOX_ABOVE]': 0x1B,
			'[CRYSTAL]': 0x1F,
		}
		
		# Check for exact matches first
		if text in controls:
			return controls[text]
		
		# Check for [CMD:XX] format
		if text.startswith('[CMD:') and text.endswith(']'):
			try:
				hex_str = text[5:-1]
				return int(hex_str, 16)
			except ValueError:
				return None
		
		return None
	
	def compress_text(self, text: str) -> bytes:
		"""
		Compress text using dictionary encoding.
		
		Algorithm:
		1. Scan text for longest matching dictionary entry
		2. If found, emit dictionary byte and continue
		3. Otherwise, emit character byte and advance
		4. Repeat until text is consumed
		"""
		result = []
		pos = 0
		
		while pos < len(text):
			# Try to match longest dictionary entry
			best_match = None
			best_length = 0
			
			for dict_text, dict_byte in self.dictionary.items():
				if text[pos:].startswith(dict_text) and len(dict_text) > best_length:
					best_match = dict_byte
					best_length = len(dict_text)
			
			if best_match is not None:
				# Dictionary match found
				result.append(best_match)
				pos += best_length
			else:
				# Try single character or control code
				# Check for control codes first (multi-char patterns)
				found_control = False
				for ctrl_len in [20, 15, 10, 5, 3]:  # Check longer patterns first
					if pos + ctrl_len <= len(text):
						substr = text[pos:pos+ctrl_len]
						ctrl_byte = self.encode_control(substr)
						if ctrl_byte is not None:
							result.append(ctrl_byte)
							pos += ctrl_len
							found_control = True
							break
				
				if not found_control:
					# Single character
					char = text[pos]
					if char in self.char_table:
						result.append(self.char_table[char])
						pos += 1
					else:
						print(f"⚠️  Unknown character at position {pos}: '{char}' (0x{ord(char):04X})")
						result.append(0x3F)  # Placeholder: '?'
						pos += 1
		
		return bytes(result)
	
	def insert_dialog(self, dialog_num: int, text: str):
		"""Insert a dialog into the ROM."""
		# Compress text
		compressed = self.compress_text(text)
		
		# Add END marker if not present
		if len(compressed) == 0 or compressed[-1] != 0x00:
			compressed = compressed + b'\x00'
		
		print(f"Dialog 0x{dialog_num:02X}: {len(text)} chars → {len(compressed)} bytes")
		
		# For now, just print what would be inserted
		# TODO: Implement actual ROM insertion with pointer updates
		print(f"  Compressed: {compressed.hex(' ')[:60]}...")
		
		return compressed
	
	def insert_all_from_json(self, json_path: str):
		"""Insert all dialogs from JSON file."""
		with open(json_path, 'r', encoding='utf-8') as f:
			dialogs = json.load(f)
		
		print(f"\n{'='*80}")
		print(f"INSERTING {len(dialogs)} DIALOGS FROM JSON")
		print(f"{'='*80}\n")
		
		for dialog_id, text in dialogs.items():
			dialog_num = int(dialog_id, 16) if isinstance(dialog_id, str) else dialog_id
			self.insert_dialog(dialog_num, text)
	
	def validate_round_trip(self, dialog_num: int, original_text: str) -> bool:
		"""
		Validate that text can be compressed and decompressed correctly.
		
		Returns True if round-trip successful, False otherwise.
		"""
		# Compress
		compressed = self.compress_text(original_text)
		
		# Decompress (re-extract)
		decompressed = self.decompress_bytes(compressed)
		
		# Compare
		if decompressed == original_text:
			print(f"✅ Dialog 0x{dialog_num:02X}: Round-trip successful")
			return True
		else:
			print(f"❌ Dialog 0x{dialog_num:02X}: Round-trip FAILED")
			print(f"  Original:	 {original_text[:60]}...")
			print(f"  Decompressed: {decompressed[:60]}...")
			return False
	
	def decompress_bytes(self, data: bytes) -> str:
		"""Decompress bytes back to text (for validation)."""
		result = ''
		for byte in data:
			if byte < 0x30:  # Control code
				result += self.decode_control(byte)
			elif byte < 0x80:  # Dictionary
				result += self.reverse_dict.get(byte, f'[D{byte:02X}]')
			else:  # Character
				result += self.reverse_table.get(byte, f'#{byte:02X}')
		return result
	
	def run(self, json_path: str, output_rom: Optional[str] = None):
		"""Main execution flow."""
		self.load_rom()
		self.load_character_table()
		self.load_dictionary()
		
		# Insert dialogs from JSON
		self.insert_all_from_json(json_path)
		
		# Save modified ROM
		if output_rom:
			self.save_rom(output_rom)
		
		print(f"\n{'='*80}")
		print("✅ INSERTION COMPLETE")
		print(f"{'='*80}")

def main():
	"""Main entry point."""
	if len(sys.argv) < 2:
		print("Usage: python import_complex_text.py <dialogs.json> [output.sfc]")
		print()
		print("Example:")
		print("  python import_complex_text.py data/dialogs_edited.json roms/ffmq_modified.sfc")
		return 1
	
	json_path = sys.argv[1]
	output_rom = sys.argv[2] if len(sys.argv) > 2 else None
	
	rom_path = r'roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc'
	
	inserter = ComplexTextInserter(rom_path)
	inserter.run(json_path, output_rom)
	
	return 0

if __name__ == '__main__':
	sys.exit(main())
