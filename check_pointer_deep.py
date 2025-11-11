#!/usr/bin/env python3
"""
Deep dive into dialog pointer format
Check multiple theories about SNES LoROM mapping for bank $03
"""

rom_path = 'roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc'

with open(rom_path, 'rb') as f:
	rom = f.read()

ptr_table_addr = 0x00D636

# Get first dialog pointer
ptr0 = (rom[ptr_table_addr + 1] << 8) | rom[ptr_table_addr]
print(f"Dialog 0 pointer: ${ptr0:04X}")
print()

# Try different conversion methods:
conversion_methods = [
	("Method 1: Direct offset in bank $03", 
	 0x018000 + ptr0,
	 "PC = $018000 + pointer"),
	
	("Method 2: LoROM bank $03 full address",
	 0x018000 + (ptr0 & 0x7FFF),
	 "PC = $018000 + (pointer & $7FFF)"),
	
	("Method 3: LoROM with $8000 base",
	 (0x03 * 0x8000) + (ptr0 - 0x8000) if ptr0 >= 0x8000 else 0x018000 + ptr0,
	 "PC = (bank * $8000) + (pointer - $8000)"),
	
	("Method 4: Direct pointer (no bank)",
	 ptr0,
	 "PC = pointer"),
	
	("Method 5: Pointer within full ROM",
	 0x030000 + ptr0,
	 "PC = $030000 + pointer"),
]

print("Testing conversion methods:")
print("=" * 70)

for name, pc_addr, formula in conversion_methods:
	if pc_addr < 0 or pc_addr >= len(rom):
		print(f"\n{name}")
		print(f"  Formula: {formula}")
		print(f"  Result: ${pc_addr:06X} - OUT OF BOUNDS")
		continue
	
	bytes_data = rom[pc_addr:pc_addr+30]
	print(f"\n{name}")
	print(f"  Formula: {formula}")
	print(f"  PC Address: ${pc_addr:06X}")
	print(f"  First 20 bytes: {' '.join(f'{b:02X}' for b in bytes_data[:20])}")
	
	# Analyze if it looks like dialog data
	# Dialog should have:
	# - Control codes (0x00-0x3B, 0x80-0x8F)
	# - DTE codes (0x3D-0x7E)
	# - Characters (0x90-0xCD)
	# - Punctuation (0xCE-0xFF)
	control_codes = sum(1 for b in bytes_data[:20] if 0x00 <= b <= 0x3B or 0x80 <= b <= 0x8F)
	dte_codes = sum(1 for b in bytes_data[:20] if 0x3D <= b <= 0x7E)
	char_codes = sum(1 for b in bytes_data[:20] if 0x90 <= b <= 0xCD)
	
	print(f"  Analysis: {control_codes} control, {dte_codes} DTE, {char_codes} chars")
	score = control_codes + dte_codes + char_codes
	print(f"  Text likelihood score: {score}/20")

# Now check a different dialog - one we know exists
print("\n" + "=" * 70)
print("Checking dialog 33 (known to be large dialog):")
ptr33_offset = ptr_table_addr + (33 * 2)
ptr33 = (rom[ptr33_offset + 1] << 8) | rom[ptr33_offset]
print(f"  Pointer value: ${ptr33:04X}")

# Try Method 2 (most promising)
pc_addr = 0x018000 + (ptr33 & 0x7FFF)
bytes_data = rom[pc_addr:pc_addr+50]
print(f"  PC Address (Method 2): ${pc_addr:06X}")
print(f"  First 50 bytes: {bytes_data.hex()}")
