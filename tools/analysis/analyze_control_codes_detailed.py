#!/usr/bin/env python3
"""
Document unknown dialog control codes by analyzing assembly and usage patterns.
"""

import sys
from pathlib import Path

def load_rom(rom_path: str) -> bytes:
	"""Load ROM file."""
	with open(rom_path, 'rb') as f:
		return f.read()

def extract_dialog(rom: bytes, dialog_num: int) -> bytes:
	"""Extract a specific dialog."""
	dialog_ptrs_addr = 0x01B835
	
	# Read pointer for this dialog
	ptr_offset = dialog_ptrs_addr + (dialog_num * 2)
	ptr = rom[ptr_offset] | (rom[ptr_offset + 1] << 8)
	dialog_addr = 0x030000 + ptr
	
	# Read next pointer to know where dialog ends
	if dialog_num + 1 < 117:
		next_ptr_offset = dialog_ptrs_addr + ((dialog_num + 1) * 2)
		next_ptr = rom[next_ptr_offset] | (rom[next_ptr_offset + 1] << 8)
		next_addr = 0x030000 + next_ptr
	else:
		next_addr = dialog_addr + 200  # Max dialog length
	
	return rom[dialog_addr:next_addr]

def analyze_control_code_usage(rom: bytes):
	"""Analyze how each control code is used across all dialogs."""
	usage = {}  # code -> [(dialog_num, position, context), ...]
	
	for dialog_num in range(117):
		data = extract_dialog(rom, dialog_num)
		
		for pos, byte in enumerate(data):
			if byte < 0x30:  # Control code range
				if byte not in usage:
					usage[byte] = []
				
				# Get surrounding context
				start = max(0, pos - 3)
				end = min(len(data), pos + 4)
				context = data[start:end]
				
				usage[byte].append((dialog_num, pos, context))
	
	return usage

def format_context(context: bytes, center_pos: int) -> str:
	"""Format context bytes for display."""
	result = []
	for i, b in enumerate(context):
		if i == center_pos:
			result.append(f'[{b:02X}]')
		elif b < 0x30:
			result.append(f'<{b:02X}>')
		elif b < 0x80:
			result.append(f'D{b:02X}')
		else:
			result.append(f'{b:02X}')
	return ' '.join(result)

def main():
	rom_path = Path(__file__).parent.parent.parent / 'roms' / 'Final Fantasy - Mystic Quest (U) (V1.1).sfc'
	
	if not rom_path.exists():
		print(f"Error: ROM not found at {rom_path}")
		return 1
	
	print("="*80)
	print("DIALOG CONTROL CODE ANALYSIS")
	print("="*80)
	
	rom = load_rom(str(rom_path))
	
	print("\nAnalyzing control code usage across all 117 dialogs...")
	usage = analyze_control_code_usage(rom)
	
	# Focus on unknown control codes
	unknown_codes = [0x08, 0x0E, 0x0B, 0x0C, 0x0D, 0x0F, 0x10, 0x12, 0x13, 0x14,
	                 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x20, 0x21, 0x24, 0x26, 0x27, 0x28]
	
	print("\n" + "="*80)
	print("UNKNOWN CONTROL CODES")
	print("="*80)
	
	for code in sorted(unknown_codes):
		if code in usage:
			occurrences = usage[code]
			print(f"\nControl Code 0x{code:02X}:")
			print(f"  Used {len(occurrences)} times in {len(set(d for d, p, c in occurrences))} dialogs")
			
			# Show first few examples with context
			print(f"  Examples:")
			for i, (dialog_num, pos, context) in enumerate(occurrences[:5]):
				# Find where the code is in the context
				code_idx = next(j for j, b in enumerate(context) if b == code)
				ctx_str = format_context(context, code_idx)
				print(f"    Dialog 0x{dialog_num:02X} pos {pos:3d}: {ctx_str}")
			
			if len(occurrences) > 5:
				print(f"    ... and {len(occurrences) - 5} more")
			
			# Analyze patterns
			# Check what typically comes after this code
			next_bytes = {}
			for dialog_num, pos, context in occurrences:
				code_idx = next(j for j, b in enumerate(context) if b == code)
				if code_idx + 1 < len(context):
					next_byte = context[code_idx + 1]
					next_bytes[next_byte] = next_bytes.get(next_byte, 0) + 1
			
			if next_bytes:
				top_next = sorted(next_bytes.items(), key=lambda x: x[1], reverse=True)[:3]
				print(f"  Most common following bytes:")
				for byte, count in top_next:
					if byte < 0x30:
						print(f"    CMD:0x{byte:02X} ({count} times)")
					elif byte < 0x80:
						print(f"    DICT:0x{byte:02X} ({count} times)")
					else:
						print(f"    CHAR:0x{byte:02X} ({count} times)")
	
	# Check assembly for jump table
	print("\n" + "="*80)
	print("ASSEMBLY ANALYSIS")
	print("="*80)
	
	print("\nControl code jump table should be at $00:9E0E")
	print("Each control code has a handler address in the jump table")
	
	# The jump table is at PC 0x009E0E (SNES $00:9E0E)
	jump_table_addr = 0x009E0E
	
	print("\nJump table entries (first 16 control codes):")
	for code in range(0x10):
		offset = jump_table_addr + (code * 2)
		if offset + 1 < len(rom):
			addr_lo = rom[offset]
			addr_hi = rom[offset + 1]
			handler_addr = addr_lo | (addr_hi << 8)
			print(f"  CMD:0x{code:02X} -> $00:{handler_addr:04X}")
	
	# Save detailed report
	report_path = Path(__file__).parent.parent.parent / 'reports' / 'control_codes_analysis.txt'
	report_path.parent.mkdir(parents=True, exist_ok=True)
	
	with open(report_path, 'w', encoding='utf-8') as f:
		f.write("DIALOG CONTROL CODES ANALYSIS\n")
		f.write("="*80 + "\n\n")
		
		for code in sorted(usage.keys()):
			occurrences = usage[code]
			f.write(f"\nControl Code 0x{code:02X}:\n")
			f.write(f"  Used {len(occurrences)} times in {len(set(d for d, p, c in occurrences))} dialogs\n")
			
			f.write(f"  All occurrences:\n")
			for dialog_num, pos, context in occurrences:
				code_idx = next(j for j, b in enumerate(context) if b == code)
				ctx_str = format_context(context, code_idx)
				f.write(f"    Dialog 0x{dialog_num:02X} pos {pos:3d}: {ctx_str}\n")
			f.write("\n")
	
	print(f"\nDetailed report saved to: {report_path}")
	
	return 0

if __name__ == '__main__':
	sys.exit(main())
