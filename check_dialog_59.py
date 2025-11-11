#!/usr/bin/env python3
"""Check specific dialog raw bytes to debug DTE"""

rom_path = 'roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc'

with open(rom_path, 'rb') as f:
	rom = f.read()

# Check dialog 0x59 (should be "For years Mac...")
dialog_id = 0x59
ptr_table = 0x00D636
ptr_addr = ptr_table + (dialog_id * 2)
ptr = int.from_bytes(rom[ptr_addr:ptr_addr+2], 'little')
bank3_offset = 0x018000
dialog_addr = bank3_offset + ptr

print(f"Dialog 0x{dialog_id:02X}:")
print(f"  Pointer at ${ptr_addr:06X} = ${ptr:04X}")
print(f"  Data at bank $03:${ptr:04X} (PC: ${dialog_addr:06X})")

bytes_data = rom[dialog_addr:dialog_addr+30]
print(f"  First 30 bytes: {bytes_data.hex()}")
print(f"  Hex: {' '.join(f'{b:02X}' for b in bytes_data[:15])}")

# Expected: "For years Mac" starts with "F" + "or" + " " + "ye" + "ar" + "s " + ...
# F = 0x9F (uppercase F)
# or = 0x50 (DTE "or")
# space = 0xFF
# ...

print(f"\nFirst few bytes decoded:")
print(f"  0x9F = 'F' (uppercase F)")
print(f"  0x{bytes_data[1]:02X} = should be 'or' (DTE 0x50)")
print(f"  0x{bytes_data[2]:02X} = should be space (0xFF)")
