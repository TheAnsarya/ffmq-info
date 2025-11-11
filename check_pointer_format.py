#!/usr/bin/env python3
"""Examine dialog pointer table to understand format"""

rom_path = 'roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc'

with open(rom_path, 'rb') as f:
	rom = f.read()

ptr_table_addr = 0x00D636

print("Dialog Pointer Table (first 20 entries):")
print("=" * 70)

for i in range(20):
	offset = ptr_table_addr + (i * 2)
	ptr_low = rom[offset]
	ptr_high = rom[offset + 1]
	pointer = (ptr_high << 8) | ptr_low
	
	print(f"Dialog {i:3d}: ${pointer:04X} at table offset ${offset:06X}")

# Check if pointers are:
# A) Full SNES addresses ($8000-$FFFF range)
# B) Offsets within bank $03 ($0000-$7FFF range)
# C) Something else

print("\n" + "=" * 70)
print("Analysis:")
if rom[ptr_table_addr + 1] >= 0x80:
	print("Pointers appear to be full SNES addresses ($8000-$FFFF range)")
	print("Conversion: PC = (bank * 0x8000) + (pointer - 0x8000)")
else:
	print("Pointers appear to be offsets within bank ($0000-$7FFF range)")
	print("Conversion: PC = 0x018000 + pointer")

# Check a known dialog location
print("\n" + "=" * 70)
print("Testing dialog 0:")
ptr0_offset = ptr_table_addr
ptr0 = (rom[ptr0_offset + 1] << 8) | rom[ptr0_offset]
print(f"  Pointer value: ${ptr0:04X}")
print(f"  If full SNES: PC = ${(0x03 * 0x8000) + (ptr0 - 0x8000):06X}")
print(f"  If offset:    PC = ${0x018000 + ptr0:06X}")

# Read 20 bytes from each location
for method, pc_addr in [
	("Full SNES", (0x03 * 0x8000) + (ptr0 - 0x8000)),
	("Offset", 0x018000 + ptr0)
]:
	bytes_data = rom[pc_addr:pc_addr+20]
	print(f"\n  {method} method -> PC ${pc_addr:06X}:")
	print(f"    Hex: {' '.join(f'{b:02X}' for b in bytes_data[:15])}")
	# Check if it looks like text (has control codes 0x00-0x3B or chars 0x90-0xCD)
	looks_like_text = any((0x00 <= b <= 0x3B) or (0x90 <= b <= 0xCD) or (0x3D <= b <= 0x7E) for b in bytes_data[:10])
	print(f"    Looks like text: {looks_like_text}")
