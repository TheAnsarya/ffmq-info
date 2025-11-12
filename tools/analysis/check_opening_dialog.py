#!/usr/bin/env python3
"""Check dialog 0x59 (opening dialog)"""

rom_path = "roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"

with open(rom_path, "rb") as f:
	rom_data = bytearray(f.read())

dialog_id = 0x59
pointer_table_addr = 0x00D636
dialog_bank_start = 0x018000

ptr_addr = pointer_table_addr + (dialog_id * 2)
pointer = rom_data[ptr_addr] | (rom_data[ptr_addr + 1] << 8)
pc_address = dialog_bank_start + (pointer & 0x7FFF)

print(f"Dialog 0x59 (opening dialog - 'For years Mac...'):")
print(f"  Pointer: 0x{pointer:04X} → PC: 0x{pc_address:06X}")
print(f"  First 80 bytes:")

dialog_bytes = []
for i in range(80):
	byte = rom_data[pc_address + i]
	dialog_bytes.append(byte)
	if byte == 0x00:
		break

for i, byte in enumerate(dialog_bytes):
	if i % 16 == 0:
		print(f"  {i:04X}: ", end="")
	print(f"{byte:02X} ", end="")
	if (i + 1) % 16 == 0 or i == len(dialog_bytes) - 1:
		print()

# Expected text
expected = "For years Mac's been studying a Prophecy"
print(f"\nExpected: '{expected}'")
