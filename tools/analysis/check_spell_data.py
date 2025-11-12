#!/usr/bin/env python3
"""Check actual ROM spell names"""
import sys
from pathlib import Path
sys.path.insert(0, 'tools/extraction')
from extract_text import TextExtractor

rom = TextExtractor('roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc', 'simple.tbl')
rom.load_rom()
rom.load_character_table()

# Known spell locations from monster-names.asm source
# Spell names should be at different address
addresses = [
	(0x04FE00, "Spell names (from TEXT_TABLES)"),
	(0x064210, "Spell names (from .asm source)"),  # PC address
]

for base_addr, label in addresses:
	print(f"\n{label} at 0x{base_addr:06X}:")
	for i in range(12):
		addr = base_addr + (i * 12)
		if addr >= len(rom.rom_data):
			print(f"  [{i:2d}] ADDRESS OUT OF RANGE")
			break
		hex_bytes = ' '.join(f'{rom.rom_data[addr+j]:02X}' for j in range(12))
		text, _ = rom.decode_string(addr, 12)
		clean_text = text.replace('#', '').strip()
		if clean_text:
			print(f"  [{i:2d}] {hex_bytes} -> '{text}'")
		else:
			print(f"  [{i:2d}] {hex_bytes} -> (empty/placeholders)")
