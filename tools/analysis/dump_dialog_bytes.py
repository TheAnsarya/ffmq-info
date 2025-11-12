#!/usr/bin/env python3
"""
Dump first N dialogs with raw bytes to identify patterns.
"""

import sys
from pathlib import Path

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent.parent))


def dump_dialogs(rom_path: str, count: int = 10):
	"""
	Dump first N dialogs with raw bytes.
	
	Args:
		rom_path: Path to ROM file
		count: Number of dialogs to dump
	"""
	# Load ROM
	with open(rom_path, 'rb') as f:
		rom_data = bytearray(f.read())
	
	# Dialog pointer table
	pointer_table_addr = 0x00D636
	dialog_bank_start = 0x018000
	
	print("=" * 80)
	print(f"FIRST {count} DIALOGS - RAW BYTES")
	print("=" * 80)
	
	for dialog_id in range(count):
		# Read pointer
		ptr_addr = pointer_table_addr + (dialog_id * 2)
		pointer = rom_data[ptr_addr] | (rom_data[ptr_addr + 1] << 8)
		
		# Convert to PC address
		pc_address = dialog_bank_start + (pointer & 0x7FFF)
		
		# Read bytes until 0x00 or 100 bytes
		dialog_bytes = []
		for i in range(100):
			byte = rom_data[pc_address + i]
			dialog_bytes.append(byte)
			
			if byte == 0x00:
				break
		
		# Print dialog info
		print(f"\nDialog {dialog_id}:")
		print(f"  Pointer: 0x{pointer:04X} → PC: 0x{pc_address:06X}")
		print(f"  Bytes ({len(dialog_bytes)}): ", end='')
		
		# Print bytes in groups of 16
		for i, byte in enumerate(dialog_bytes):
			if i > 0 and i % 16 == 0:
				print()
				print(f"		 {' ' * 17}", end='')
			
			print(f"{byte:02X} ", end='')
		
		print()
		
		# Print ASCII representation for reference
		print(f"  ASCII: ", end='')
		for byte in dialog_bytes:
			if 0x20 <= byte <= 0x7E:
				print(chr(byte), end='')
			else:
				print('.', end='')
		
		print()


def main():
	"""Main entry point"""
	import argparse
	
	parser = argparse.ArgumentParser(
		description='Dump dialog raw bytes for analysis'
	)
	parser.add_argument(
		'rom_path',
		help='Path to FFMQ ROM file'
	)
	parser.add_argument(
		'--count',
		type=int,
		default=20,
		help='Number of dialogs to dump (default: 20)'
	)
	
	args = parser.parse_args()
	
	# Check ROM exists
	rom_path = Path(args.rom_path)
	if not rom_path.exists():
		print(f"Error: ROM file not found: {rom_path}", file=sys.stderr)
		sys.exit(1)
	
	dump_dialogs(args.rom_path, args.count)


if __name__ == '__main__':
	main()
