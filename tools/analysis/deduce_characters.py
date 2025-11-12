#!/usr/bin/env python3
"""
Deduce unknown character mappings by analyzing patterns in the dictionary.
"""

import sys
from pathlib import Path

def load_rom(rom_path: str) -> bytes:
	"""Load ROM file."""
	with open(rom_path, 'rb') as f:
		return f.read()

def extract_dict_entry(rom: bytes, dict_addr: int, entry_num: int) -> bytes:
	"""Extract a specific dictionary entry."""
	offset = dict_addr
	
	for i in range(entry_num):
		length = rom[offset]
		offset += 1 + length
	
	length = rom[offset]
	offset += 1
	return rom[offset:offset + length]

def main():
	rom_path = Path(__file__).parent.parent.parent / 'roms' / 'Final Fantasy - Mystic Quest (U) (V1.1).sfc'
	
	if not rom_path.exists():
		print(f"Error: ROM not found at {rom_path}")
		return 1
	
	rom = load_rom(str(rom_path))
	dict_addr = 0x01BA35
	
	print("="*80)
	print("DEDUCING UNKNOWN CHARACTERS FROM PATTERNS")
	print("="*80)
	
	# Based on analysis, let's look at specific patterns
	# FFMQ uses a standard character set, let's check known entries
	
	print("\n[Analyzing specific dictionary entries]")
	
	# Entry 0x4D which contains 0xD0
	entry_4d = extract_dict_entry(rom, dict_addr, 0x4D - 0x30)
	print(f"\nDict 0x4D (contains 0xD0): {entry_4d.hex()}")
	print(f"  Bytes: {[f'0x{b:02X}' for b in entry_4d]}")
	
	# Entry 0x31-0x32 which contain 0x83
	entry_31 = extract_dict_entry(rom, dict_addr, 0x31 - 0x30)
	print(f"\nDict 0x31 (contains 0x83): {entry_31.hex()}")
	print(f"  Bytes: {[f'0x{b:02X}' for b in entry_31]}")
	
	entry_32 = extract_dict_entry(rom, dict_addr, 0x32 - 0x30)
	print(f"\nDict 0x32 (contains 0x83): {entry_32.hex()}")
	print(f"  Bytes: {[f'0x{b:02X}' for b in entry_32]}")
	
	# Entry 0x33 which contains 0x84
	entry_33 = extract_dict_entry(rom, dict_addr, 0x33 - 0x30)
	print(f"\nDict 0x33 (contains 0x84): {entry_33.hex()}")
	print(f"  Bytes: {[f'0x{b:02X}' for b in entry_33]}")
	
	# Entry 0x6E-0x6F which contain 0xCE
	entry_6e = extract_dict_entry(rom, dict_addr, 0x6E - 0x30)
	print(f"\nDict 0x6E (contains 0xCE): {entry_6e.hex()}")
	print(f"  Bytes: {[f'0x{b:02X}' for b in entry_6e]}")
	
	# Let's check what dialogs use these entries
	print("\n" + "="*80)
	print("CHECKING DIALOG USAGE")
	print("="*80)
	
	# Dialog pointers start at 0x01B835
	dialog_ptrs_addr = 0x01B835
	num_dialogs = 117
	
	# Read all dialog pointers
	dialog_addrs = []
	for i in range(num_dialogs):
		ptr_offset = dialog_ptrs_addr + (i * 2)
		ptr = rom[ptr_offset] | (rom[ptr_offset + 1] << 8)
		# Pointers are relative to bank 0x03
		dialog_addr = 0x030000 + ptr
		dialog_addrs.append(dialog_addr)
	
	# Check which dialogs use dict entries with unknown bytes
	unknown_dict_entries = [0x31, 0x32, 0x33, 0x36, 0x4D, 0x6E, 0x6F, 0x7F]
	
	print(f"\nSearching dialogs that use dictionary entries with unknown bytes...")
	
	for dialog_num in range(num_dialogs):
		dialog_addr = dialog_addrs[dialog_num]
		next_addr = dialog_addrs[dialog_num + 1] if dialog_num + 1 < num_dialogs else dialog_addr + 200
		
		dialog_data = rom[dialog_addr:next_addr]
		
		# Check if any unknown dict entries are used
		uses_unknown = False
		for entry in unknown_dict_entries:
			if entry in dialog_data:
				uses_unknown = True
				break
		
		if uses_unknown:
			print(f"\nDialog 0x{dialog_num:02X} (PC 0x{dialog_addr:06X}):")
			print(f"  Bytes: {dialog_data[:40].hex()}")
			print(f"  Dict entries: {[f'0x{b:02X}' for b in dialog_data if 0x30 <= b < 0x80][:10]}")
	
	# Based on FFMQ knowledge, let's make educated guesses
	print("\n" + "="*80)
	print("EDUCATED GUESSES")
	print("="*80)
	
	guesses = {
		0x80: "?",  # Could be a special character
		0x81: "!",  # Likely exclamation after CMD:08
		0x83: "é",  # Common in fantasy names (Pokémon, Café)
		0x84: "è",  # Another accented e
		0x87: "à",  # Accented a
		0x8A: "ü",  # German umlaut
		0x8B: "ö",  # Another umlaut
		0x8C: "ä",  # Another umlaut
		0xCE: "'",  # Likely apostrophe or quote
		0xD0: ".",  # Period
		0xD2: ",",  # Comma (used 5 times, most common punctuation)
		0xDC: ":",  # Colon
		0xDE: ";",  # Semicolon
		0xE7: "\"", # Quote mark
		0xEB: "?",  # Question mark
		0xF7: "!",  # Exclamation
	}
	
	print("\nSuggested character mappings:")
	for byte_val, char in sorted(guesses.items()):
		print(f"  0x{byte_val:02X} = {char}")
	
	# Let's check if these make sense by looking at actual game text
	# FFMQ has known dialog strings we can reference
	print("\n" + "="*80)
	print("VALIDATION AGAINST KNOWN GAME TEXT")
	print("="*80)
	
	# Dialog 0x00 is typically the intro text
	dialog_00 = rom[dialog_addrs[0]:dialog_addrs[1]]
	print(f"\nDialog 0x00 (intro): {dialog_00.hex()}")
	
	# Check for patterns
	print("\nLooking for common English patterns...")
	print("(e.g., period at end of sentences, commas in lists)")
	
	# Count how often 0xD2 appears before spaces or at sentence boundaries
	sentence_enders = [b for b in rom[dialog_addrs[0]:dialog_addrs[50]] if b == 0xD0 or b == 0xEB or b == 0xF7]
	print(f"\nPotential sentence enders (0xD0, 0xEB, 0xF7): {len(sentence_enders)} instances")
	
	return 0

if __name__ == '__main__':
	sys.exit(main())
