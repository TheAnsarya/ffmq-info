#!/usr/bin/env python3
"""Quick analysis of dictionary structure"""

import sys

rom = open(r'roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc', 'rb').read()

dict_addr = 0x01BA35

print("Dictionary table raw bytes (first 160 bytes):")
for row in range(10):
	offset = row * 16
	bytes_str = ' '.join(f'{rom[dict_addr+offset+i]:02X}' for i in range(16))
	ascii_str = ''.join(chr(rom[dict_addr+offset+i]) if 32 <= rom[dict_addr+offset+i] < 127 else '.' for i in range(16))
	print(f'{dict_addr+offset:06X}: {bytes_str}  {ascii_str}')

print("\nLooking for null terminators (00):")
for i in range(200):
	if rom[dict_addr + i] == 0x00:
		print(f'Found 0x00 at offset {i} (absolute 0x{dict_addr+i:06X})')
