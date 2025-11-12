#!/usr/bin/env python3
"""
Fix FFMQ Character Table Based on GameFAQs Script

This script creates a corrected character table by analyzing the
GameFAQs script and known ROM patterns.

Author: FFMQ Disassembly Project
Date: 2025-11-12
"""

# Corrected character mappings based on GameFAQs script analysis
CORRECTIONS = {
	# Control codes (0x00-0x2F)
	0x00: '[END]',	  # String terminator
	0x01: '{newline}',  # Line break
	0x02: '[WAIT]',	 # Wait for button
	0x03: '*',		  # Asterisk
	0x04: '[NAME]',	 # Insert character name
	0x05: '[ITEM]',	 # Insert item name
	0x06: '_',		  # Space/underscore
	
	# Dictionary compression range 0x30-0x7F is handled separately
	
	# Numbers (0x90-0x99)
	0x90: '0', 0x91: '1', 0x92: '2', 0x93: '3', 0x94: '4',
	0x95: '5', 0x96: '6', 0x97: '7', 0x98: '8', 0x99: '9',
	
	# Uppercase letters (0x9A-0xB3)
	0x9A: 'A', 0x9B: 'B', 0x9C: 'C', 0x9D: 'D', 0x9E: 'E', 0x9F: 'F',
	0xA0: 'G', 0xA1: 'H', 0xA2: 'I', 0xA3: 'J', 0xA4: 'K', 0xA5: 'L',
	0xA6: 'M', 0xA7: 'N', 0xA8: 'O', 0xA9: 'P', 0xAA: 'Q', 0xAB: 'R',
	0xAC: 'S', 0xAD: 'T', 0xAE: 'U', 0xAF: 'V', 0xB0: 'W', 0xB1: 'X',
	0xB2: 'Y', 0xB3: 'Z',
	
	# Lowercase letters (0xB4-0xCD)
	0xB4: 'a', 0xB5: 'b', 0xB6: 'c', 0xB7: 'd', 0xB8: 'e', 0xB9: 'f',
	0xBA: 'g', 0xBB: 'h', 0xBC: 'i', 0xBD: 'j', 0xBE: 'k', 0xBF: 'l',
	0xC0: 'm', 0xC1: 'n', 0xC2: 'o', 0xC3: 'p', 0xC4: 'q', 0xC5: 'r',
	0xC6: 's', 0xC7: 't', 0xC8: 'u', 0xC9: 'v', 0xCA: 'w', 0xCB: 'x',
	0xCC: 'y', 0xCD: 'z',
	
	# Punctuation and special characters
	0x80: '~',	 # Tilde
	0x81: '…',	 # Ellipsis
	0x83: 'é',	 # e acute
	0x84: 'è',	 # e grave  
	0x87: 'à',	 # a grave
	0x8A: 'ü',	 # u umlaut
	0x8B: 'ö',	 # o umlaut
	0x8C: 'ä',	 # a umlaut
	0xCE: "'",	 # Apostrophe
	0xD0: '.',	 # Period
	0xD1: "'",	 # Right single quote
	0xD2: ',',	 # Comma
	0xDA: '-',	 # Hyphen/dash
	0xDB: '&',	 # Ampersand
	0xDC: ':',	 # Colon
	0xDE: ';',	 # Semicolon
	0xE7: '"',	 # Quote
	0xEB: '?',	 # Question mark
	0xF7: '!',	 # Exclamation mark
	0xFF: ' ',	 # Space
}

def update_character_table(table_path='simple.tbl'):
	"""Update the character table with corrections."""
	print(f"Updating character table: {table_path}")
	print(f"Applying {len(CORRECTIONS)} corrections...")
	
	# Read existing table
	lines = []
	try:
		with open(table_path, 'r', encoding='utf-8') as f:
			lines = f.readlines()
	except FileNotFoundError:
		# Create new table with all unknowns
		lines = [f'{i:02X}=#\n' for i in range(256)]
	
	# Parse existing table
	table = {}
	for line in lines:
		line = line.strip()
		if '=' in line:
			hex_byte, char = line.split('=', 1)
			table[int(hex_byte, 16)] = char
	
	# Apply corrections
	updated = 0
	for byte_val, char in CORRECTIONS.items():
		old_char = table.get(byte_val, '#')
		if old_char != char:
			table[byte_val] = char
			updated += 1
			print(f"  0x{byte_val:02X}: '{old_char}' → '{char}'")
	
	# Fill in unknowns for remaining bytes
	for i in range(256):
		if i not in table:
			table[i] = '#'
	
	# Write updated table
	with open(table_path, 'w', encoding='utf-8') as f:
		for i in range(256):
			f.write(f'{i:02X}={table[i]}\n')
	
	print(f"\n✅ Updated {updated} character mappings")
	print(f"✅ Wrote {len(table)} entries to {table_path}")
	
	# Show statistics
	known = sum(1 for c in table.values() if c != '#')
	unknown = 256 - known
	coverage = known * 100 / 256
	
	print(f"\nStatistics:")
	print(f"  Known characters:   {known}")
	print(f"  Unknown characters: {unknown}")
	print(f"  Coverage:		   {coverage:.1f}%")

def main():
	"""Main entry point."""
	print("=" * 70)
	print("FFMQ Character Table Fix - Based on GameFAQs Script")
	print("=" * 70)
	print()
	
	update_character_table()
	
	print()
	print("=" * 70)
	print("Character table updated successfully!")
	print("=" * 70)
	print()
	print("Next steps:")
	print("  1. Re-extract dialog with updated table")
	print("  2. Compare with GameFAQs script")
	print("  3. Identify any remaining unknown characters")
	print()
	
	return 0

if __name__ == '__main__':
	import sys
	sys.exit(main())
