 #!/usr/bin/env python3
"""
FFMQ Dialog Decoder - Correct Version
Based on assembly analysis of Dialog_WriteCharacter at 009DC1-009DD2

Byte ranges:
- 0x00-0x2F: Command codes (use jump table)
- 0x30-0x7F: DTE text sequences (2-4 characters)
- 0x80-0xFF: Single-byte text characters
"""

# Load complex.tbl properly
def load_complex_tbl(path='complex.tbl'):
	"""Load character mapping from complex.tbl"""
	table = {}
	with open(path, 'r', encoding='utf-8') as f:
		for line in f:
			line = line.strip()
			if not line or line.startswith('#'):
				continue
			if '=' in line:
				byte_str, text = line.split('=', 1)
				byte_val = int(byte_str, 16)
				table[byte_val] = text
	return table

# Decode dialog with correct structure
def decode_dialog(dialog_bytes: bytes, char_table: dict) -> str:
	"""Decode dialog bytes using correct command/text separation"""
	result = []
	
	for b in dialog_bytes:
		if b < 0x30:
			# Command code
			if b in char_table:
				result.append(char_table[b])
			else:
				result.append(f'[CMD:{b:02X}]')
		elif 0x30 <= b < 0x80:
			# DTE text sequence
			if b in char_table:
				result.append(char_table[b])
			else:
				result.append(f'[DTE:{b:02X}]')
		else:
			# Single character (0x80+)
			if b in char_table:
				result.append(char_table[b])
			else:
				result.append(f'[CHR:{b:02X}]')
	
	return ''.join(result)

# Test with dialog 0x59
if __name__ == '__main__':
	import sys
	from pathlib import Path
	
	# Load ROM
	rom_path = Path(r'roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc')
	rom = rom_path.read_bytes()
	
	# Load character table
	char_table = load_complex_tbl('complex.tbl')
	
	# Get dialog 0x59
	ptr_table = 0x00D636
	bank_offset = 0x018000
	dialog_id = 0x59
	
	ptr_idx = dialog_id * 2
	ptr = int.from_bytes(rom[ptr_table + ptr_idx:ptr_table + ptr_idx + 2], 'little')
	addr = bank_offset + (ptr & 0x7FFF)
	
	# Read bytes until END
	dialog_bytes = []
	for i in range(512):
		if addr + i >= len(rom):
			break
		b = rom[addr + i]
		dialog_bytes.append(b)
		if b == 0x00:  # END
			break
	
	dialog_bytes = bytes(dialog_bytes)
	
	# Decode
	decoded = decode_dialog(dialog_bytes, char_table)
	
	print(f"Dialog 0x{dialog_id:02X}:")
	print(f"Raw bytes: {dialog_bytes.hex(' ')}")
	print(f"\nDecoded:")
	print(decoded)
	print(f"\nExpected:")
	print("For years Mac's been studying a Prophecy")
