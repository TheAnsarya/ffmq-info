#!/usr/bin/env python3
"""
Analyze FFMQ ROM to find missing characters in character table.
Cross-references dictionary bytes with simple.tbl to find unknowns.
"""

import sys
from pathlib import Path

def load_rom(rom_path: str) -> bytes:
	"""Load ROM file."""
	with open(rom_path, 'rb') as f:
		return f.read()

def load_simple_tbl(tbl_path: str) -> dict:
	"""Load simple.tbl character mappings."""
	mappings = {}
	try:
		with open(tbl_path, 'r', encoding='utf-8') as f:
			for line in f:
				line = line.strip()
				if not line or line.startswith(';'):
					continue
				if '=' in line:
					byte_str, char = line.split('=', 1)
					byte_val = int(byte_str, 16)
					mappings[byte_val] = char
	except Exception as e:
		print(f"Error loading {tbl_path}: {e}")
	return mappings

def extract_raw_dictionary(rom: bytes, dict_addr: int = 0x01BA35, num_entries: int = 80) -> list:
	"""Extract raw dictionary entries from ROM."""
	entries = []
	offset = dict_addr
	
	for i in range(num_entries):
		if offset >= len(rom):
			break
		
		length = rom[offset]
		offset += 1
		
		data = rom[offset:offset + length]
		offset += length
		
		entries.append((i + 0x30, bytes(data)))
	
	return entries

def analyze_byte_usage(rom: bytes, dict_addr: int = 0x01BA35):
	"""Analyze which bytes are used in the dictionary."""
	entries = extract_raw_dictionary(rom, dict_addr)
	
	byte_counts = {}
	for idx, data in entries:
		for byte in data:
			byte_counts[byte] = byte_counts.get(byte, 0) + 1
	
	return byte_counts

def main():
	rom_path = Path(__file__).parent.parent.parent / 'roms' / 'Final Fantasy - Mystic Quest (U) (V1.1).sfc'
	tbl_path = Path(__file__).parent.parent.parent / 'simple.tbl'
	
	if not rom_path.exists():
		print(f"Error: ROM not found at {rom_path}")
		return 1
	
	print("="*80)
	print("FFMQ CHARACTER ANALYSIS")
	print("="*80)
	
	# Load ROM and character table
	print("\n[1/4] Loading ROM and character table...")
	rom = load_rom(str(rom_path))
	char_table = load_simple_tbl(str(tbl_path))
	
	print(f"  ROM size: {len(rom):,} bytes")
	print(f"  Character table entries: {len(char_table)}")
	
	# Extract dictionary
	print("\n[2/4] Extracting dictionary...")
	dict_entries = extract_raw_dictionary(rom)
	print(f"  Extracted {len(dict_entries)} dictionary entries")
	
	# Analyze byte usage in dictionary
	print("\n[3/4] Analyzing byte usage in dictionary...")
	byte_usage = analyze_byte_usage(rom)
	
	# Find unknown bytes
	print("\n[4/4] Finding unknown/missing characters...")
	
	unknown_bytes = []
	for byte_val in sorted(byte_usage.keys()):
		if byte_val >= 0x80:  # Character range
			if byte_val not in char_table or char_table[byte_val] == '#':
				unknown_bytes.append(byte_val)
	
	print(f"\n  Found {len(unknown_bytes)} unknown bytes in dictionary:")
	print()
	
	for byte_val in unknown_bytes:
		count = byte_usage[byte_val]
		current = char_table.get(byte_val, 'NOT_IN_TABLE')
		print(f"	0x{byte_val:02X}: Used {count:3d} times, currently: '{current}'")
	
	# Check for patterns
	print("\n" + "="*80)
	print("PATTERN ANALYSIS")
	print("="*80)
	
	print("\n  Checking for sequential patterns...")
	
	# Look at context where these bytes appear
	print("\n  Context examples for unknown bytes:")
	for byte_val in unknown_bytes[:10]:  # First 10
		print(f"\n  0x{byte_val:02X}:")
		examples_shown = 0
		for idx, data in dict_entries:
			if byte_val in data:
				# Show surrounding context
				pos = data.index(byte_val)
				start = max(0, pos - 3)
				end = min(len(data), pos + 4)
				context = data[start:end]
				
				# Decode context
				context_str = []
				for b in context:
					if b == byte_val:
						context_str.append(f'[0x{b:02X}]')
					elif b < 0x30:
						context_str.append(f'<CMD:{b:02X}>')
					elif b < 0x80:
						context_str.append(f'<DIC:{b:02X}>')
					elif b in char_table:
						context_str.append(char_table[b])
					else:
						context_str.append(f'[0x{b:02X}]')
				
				print(f"	Dict 0x{idx:02X}: {''.join(context_str)}")
				examples_shown += 1
				if examples_shown >= 3:
					break
	
	# Analyze byte ranges
	print("\n" + "="*80)
	print("BYTE RANGE ANALYSIS")
	print("="*80)
	
	ranges = {
		'Control (0x00-0x2F)': [b for b in byte_usage.keys() if b < 0x30],
		'Dictionary (0x30-0x7F)': [b for b in byte_usage.keys() if 0x30 <= b < 0x80],
		'Characters (0x80-0xFF)': [b for b in byte_usage.keys() if b >= 0x80]
	}
	
	for range_name, bytes_in_range in ranges.items():
		print(f"\n  {range_name}:")
		print(f"	Count: {len(bytes_in_range)} different bytes used")
		if bytes_in_range:
			print(f"	Range: 0x{min(bytes_in_range):02X} - 0x{max(bytes_in_range):02X}")
	
	# Check FFMQ's actual font data (if we can find it)
	print("\n" + "="*80)
	print("FONT DATA SEARCH")
	print("="*80)
	
	# FFMQ typically stores font data in a specific format
	# Let's check common locations for tile data patterns
	print("\n  Searching for potential font tile data...")
	
	# Font tiles are typically 8x8 or 8x16, 2bpp or 4bpp
	# Let's look for repeating patterns that could be character data
	
	# Check if there's a character ROM table (common location: 0x3C000-0x3FFFF)
	font_search_ranges = [
		(0x3C000, 0x40000, "High ROM area"),
		(0x10000, 0x20000, "Bank 2"),
		(0x20000, 0x30000, "Bank 4"),
	]
	
	for start, end, name in font_search_ranges:
		if start < len(rom) and end <= len(rom):
			# Look for null-terminated ASCII-like sequences
			region = rom[start:end]
			
			# Check for readable ASCII patterns
			ascii_count = sum(1 for b in region if 0x20 <= b < 0x7F)
			ratio = ascii_count / len(region) if region else 0
			
			if ratio > 0.3:  # More than 30% ASCII
				print(f"	{name} (0x{start:06X}-0x{end:06X}): {ratio*100:.1f}% ASCII-like")
	
	# Save detailed report
	report_path = Path(__file__).parent.parent.parent / 'reports' / 'unknown_characters.txt'
	report_path.parent.mkdir(parents=True, exist_ok=True)
	
	with open(report_path, 'w', encoding='utf-8') as f:
		f.write("FFMQ UNKNOWN CHARACTERS REPORT\n")
		f.write("="*80 + "\n\n")
		f.write(f"Unknown bytes: {len(unknown_bytes)}\n\n")
		
		for byte_val in unknown_bytes:
			count = byte_usage[byte_val]
			current = char_table.get(byte_val, 'NOT_IN_TABLE')
			f.write(f"0x{byte_val:02X}: Used {count} times, currently: '{current}'\n")
			
			# Show examples
			f.write("  Examples:\n")
			for idx, data in dict_entries:
				if byte_val in data:
					f.write(f"	Dictionary entry 0x{idx:02X}: {data.hex()}\n")
	
	print(f"\n  Detailed report saved to: {report_path}")
	
	return 0

if __name__ == '__main__':
	sys.exit(main())
