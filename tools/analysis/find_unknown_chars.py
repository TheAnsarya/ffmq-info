#!/usr/bin/env python3
"""
Identify unknown characters in the dictionary system.

Analyzes which bytes are marked as '#' and their context.
"""

import os
import sys

ROM_PATH = "roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"
DICT_ADDR = 0x01BA35  # PC address

def load_rom(rom_path: str) -> bytes:
	"""Load ROM file."""
	with open(rom_path, 'rb') as f:
		return f.read()

def extract_raw_dictionary(rom: bytes, addr: int):
	"""Extract raw dictionary entries."""
	entries = []
	offset = addr
	
	for i in range(80):  # 80 dictionary entries (0x30-0x7F)
		length = rom[offset]
		offset += 1
		
		if length > 0:
			data = rom[offset:offset + length]
			entries.append((addr + (offset - addr - 1), length, list(data)))
			offset += length
		else:
			entries.append((addr + (offset - addr - 1), 0, []))
	
	return entries

def analyze_unknown_chars():
	"""Find and analyze unknown characters."""
	rom = load_rom(ROM_PATH)
	
	# Load simple table
	simple_map = {}
	with open('simple.tbl', 'r', encoding='utf-8') as f:
		for line in f:
			line = line.strip()
			if line and '=' in line and not line.startswith('#'):
				byte_hex, char = line.split('=', 1)
				byte_val = int(byte_hex, 16)
				simple_map[byte_val] = char
	
	# Extract dictionary
	raw_dict = extract_raw_dictionary(rom, DICT_ADDR)
	
	# Find all bytes that decode to '#'
	unknown_bytes = set()
	
	print("=" * 80)
	print("Unknown Characters in Dictionary")
	print("=" * 80)
	
	for idx, (addr, length, data) in enumerate(raw_dict):
		dict_idx = 0x30 + idx
		decoded = []
		
		for byte in data:
			if byte < 0x30:
				# Control code
				decoded.append(f"[CMD:{byte:02X}]")
			elif 0x30 <= byte < 0x80:
				# Dictionary reference
				decoded.append(f"[DICT:{byte:02X}]")
			else:
				# Direct character
				char = simple_map.get(byte, '#')
				if char == '#':
					unknown_bytes.add(byte)
				decoded.append(char)
		
		decoded_str = ''.join(decoded)
		if '#' in decoded_str:
			print(f"\nEntry 0x{dict_idx:02X}: {decoded_str}")
			print(f"  Raw bytes: {' '.join(f'{b:02X}' for b in data)}")
			
			# Show which specific bytes are unknown
			for byte in data:
				if byte >= 0x80 and simple_map.get(byte, '#') == '#':
					print(f"  Unknown byte: 0x{byte:02X}")
	
	print("\n" + "=" * 80)
	print(f"Total unique unknown bytes: {len(unknown_bytes)}")
	print("=" * 80)
	
	for byte in sorted(unknown_bytes):
		print(f"  0x{byte:02X} (decimal {byte})")
	
	# Analyze these bytes in context
	print("\n" + "=" * 80)
	print("Context Analysis")
	print("=" * 80)
	
	for byte in sorted(unknown_bytes):
		print(f"\n0x{byte:02X}:")
		
		# Check if it's in ASCII range
		if 0x20 <= byte <= 0x7E:
			ascii_char = chr(byte)
			print(f"  ASCII character: '{ascii_char}'")
			
			# Check if it makes sense
			if ascii_char.isalpha() or ascii_char.isdigit() or ascii_char in " .,!?'-":
				print(f"  ✓ Likely correct: '{ascii_char}'")
		
		# Find where it appears in dictionary
		appearances = []
		for idx, (addr, length, data) in enumerate(raw_dict):
			if byte in data:
				dict_idx = 0x30 + idx
				appearances.append(dict_idx)
		
		if appearances:
			print(f"  Appears in dictionary entries: {', '.join(f'0x{x:02X}' for x in appearances)}")
	
	return sorted(unknown_bytes)


if __name__ == '__main__':
	unknown = analyze_unknown_chars()
	
	print("\n" + "=" * 80)
	print("Suggested Updates to simple.tbl:")
	print("=" * 80)
	
	for byte in unknown:
		if 0x20 <= byte <= 0x7E:
			ascii_char = chr(byte)
			print(f"{byte:02X}={ascii_char}")
