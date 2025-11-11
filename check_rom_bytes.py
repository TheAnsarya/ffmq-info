#!/usr/bin/env python3
"""Check ROM bytes for dialogs"""

with open('roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc', 'rb') as f:
	# Pointer table is at PC 0x0D636
	ptr_table_offset = 0x0D636

	# Check dialog 0x16 (22 decimal) which has "beautiful"
	dialog_id = 0x16
	f.seek(ptr_table_offset + dialog_id * 2)
	ptr = int.from_bytes(f.read(2), 'little')

	print(f"Dialog 0x{dialog_id:02X} pointer (SNES addr in bank): ${ptr:04X}")

	# Convert SNES address to PC address
	# LoROM: SNES $03xxxx maps to PC $01(xxxx-8000)
	# So pointer $F320 in bank $03 → PC $018000 + ($F320 - $8000) = $01F320
	if ptr >= 0x8000:
		pc_addr = 0x018000 + (ptr - 0x8000)
	else:
		pc_addr = 0x018000 + ptr

	print(f"PC address: ${pc_addr:06X}")

	f.seek(pc_addr)
	data = f.read(20)
	print(f"Bytes: {' '.join(f'{b:02X}' for b in data)}")
	print("\nExpected text: 's beautiful as ever!'")
	print("\nWith current mapping:")
	print("  0x45='s ', 0xB5='b', 0x5E='ea', 0xC8='u', 0xC7='t', 0xBC='i', 0xB9='f', 0xC8='u', 0x49='er'")
	print("  Would give: 's beautifuer...' WRONG!")

	print("\nLet's try ORIGINAL table from simple.tbl or find what DTE is correct")
