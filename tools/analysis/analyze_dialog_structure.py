#!/usr/bin/env python3
"""
Analyze FFMQ dialog structure to understand:
1. Which bytes are control codes vs text
2. Distribution of bytes in dialog data
3. Patterns that help identify DTE sequences

This helps fix the broken DTE table in complex.tbl
"""

import sys
from pathlib import Path
from collections import defaultdict, Counter

# Known control codes (confirmed from assembly and CONTROL_CODES.md)
KNOWN_CONTROLS = {
	0x00: '[END]',
	0x01: '{newline}',
	0x02: '[WAIT]',
	0x03: '[ASTERISK]',
	0x04: '[NAME]',
	0x05: '[ITEM]',
	0x06: '[SPACE]',
	0x1A: '[TEXTBOX_BELOW]',
	0x1B: '[TEXTBOX_ABOVE]',
	0x1F: '[CRYSTAL]',
	0x23: '[CLEAR]',
	0x30: '[PARA]',
	0x36: '[PAGE]',
}

# Extended control codes (0x80-0x8F)
EXTENDED_CONTROLS = set(range(0x80, 0x90))

def load_rom(rom_path: Path) -> bytes:
	"""Load ROM file"""
	with open(rom_path, 'rb') as f:
		return f.read()

def get_dialog_pointers(rom: bytes, ptr_table_addr: int = 0x00D636, count: int = 117) -> list:
	"""Extract dialog pointer table"""
	pointers = []
	for i in range(count):
		offset = ptr_table_addr + (i * 2)
		ptr = int.from_bytes(rom[offset:offset+2], 'little')
		pointers.append(ptr)
	return pointers

def get_dialog_bytes(rom: bytes, ptr: int, bank_offset: int = 0x018000, max_len: int = 512) -> bytes:
	"""Extract raw dialog bytes from ROM"""
	addr = bank_offset + (ptr & 0x7FFF)
	
	# Read until 0x00 (END) or max length
	dialog_bytes = []
	for i in range(max_len):
		if addr + i >= len(rom):
			break
		b = rom[addr + i]
		dialog_bytes.append(b)
		if b == 0x00:  # END
			break
	
	return bytes(dialog_bytes)

def analyze_byte_distribution(rom_path: str):
	"""Analyze byte distribution across all dialogs"""
	rom = load_rom(Path(rom_path))
	pointers = get_dialog_pointers(rom)
	
	# Statistics
	byte_freq = Counter()
	byte_positions = defaultdict(list)  # Which dialogs contain each byte
	byte_context = defaultdict(list)  # Surrounding bytes
	
	# Control code usage
	control_usage = Counter()
	
	print(f"Analyzing {len(pointers)} dialogs...")
	
	for dialog_id, ptr in enumerate(pointers):
		dialog_bytes = get_dialog_bytes(rom, ptr)
		
		for pos, b in enumerate(dialog_bytes):
			byte_freq[b] += 1
			byte_positions[b].append(dialog_id)
			
			# Track context (prev/next bytes)
			if pos > 0 and pos < len(dialog_bytes) - 1:
				prev_b = dialog_bytes[pos-1]
				next_b = dialog_bytes[pos+1]
				byte_context[b].append((prev_b, next_b))
			
			# Count control code usage
			if b in KNOWN_CONTROLS:
				control_usage[KNOWN_CONTROLS[b]] += 1
	
	# Output results
	print("\n" + "="*80)
	print("BYTE FREQUENCY ANALYSIS")
	print("="*80)
	
	# Group by byte range
	ranges = [
		(0x00, 0x0F, "Basic Control Codes"),
		(0x10, 0x3F, "Event Parameters / Early DTE"),
		(0x40, 0x7F, "DTE Compression"),
		(0x80, 0x8F, "Extended Controls"),
		(0x90, 0xCF, "Single Characters (lowercase?)"),
		(0xD0, 0xFF, "Single Characters (uppercase/punctuation?)"),
	]
	
	for start, end, desc in ranges:
		print(f"\n{desc} (0x{start:02X}-0x{end:02X}):")
		print("-" * 80)
		
		range_bytes = [(b, count) for b, count in byte_freq.most_common() if start <= b <= end]
		
		for b, count in range_bytes[:20]:  # Top 20 in each range
			dialogs_with = len(byte_positions[b])
			ctrl_name = KNOWN_CONTROLS.get(b, '')
			
			if ctrl_name:
				print(f"  0x{b:02X}: {count:4d} uses in {dialogs_with:3d} dialogs - {ctrl_name}")
			else:
				print(f"  0x{b:02X}: {count:4d} uses in {dialogs_with:3d} dialogs")
	
	# Control code usage
	print("\n" + "="*80)
	print("KNOWN CONTROL CODE USAGE")
	print("="*80)
	for code_name, count in control_usage.most_common():
		print(f"  {code_name:20s}: {count:4d} uses")
	
	# Find bytes that NEVER appear - these might be unused or incorrectly mapped
	print("\n" + "="*80)
	print("UNUSED BYTES (never appear in dialogs)")
	print("="*80)
	unused = [b for b in range(0x00, 0x100) if b not in byte_freq]
	for i in range(0, len(unused), 16):
		chunk = unused[i:i+16]
		hex_str = ' '.join(f'{b:02X}' for b in chunk)
		print(f"  {hex_str}")
	
	# Most common bytes (likely space, common letters, or DTE for "the", "and", etc.)
	print("\n" + "="*80)
	print("TOP 30 MOST COMMON BYTES (across all dialogs)")
	print("="*80)
	for b, count in byte_freq.most_common(30):
		dialogs_with = len(byte_positions[b])
		ctrl_name = KNOWN_CONTROLS.get(b, '')
		if ctrl_name:
			print(f"  0x{b:02X}: {count:4d} uses in {dialogs_with:3d} dialogs - {ctrl_name}")
		else:
			# Try to show context
			contexts = byte_context[b][:3]  # First 3 contexts
			context_str = ', '.join(f'[{prev:02X}]->{b:02X}->[{next_:02X}]' for prev, next_ in contexts)
			print(f"  0x{b:02X}: {count:4d} uses in {dialogs_with:3d} dialogs ({context_str}...)")
	
	print("\n" + "="*80)
	print("ANALYSIS COMPLETE")
	print("="*80)

if __name__ == '__main__':
	rom_path = sys.argv[1] if len(sys.argv) > 1 else r'roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc'
	analyze_byte_distribution(rom_path)
