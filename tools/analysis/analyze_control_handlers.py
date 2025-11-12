#!/usr/bin/env python3
"""
Control Code Handler Analysis Tool

Analyzes the control code jump table at $00:9E0E and documents each handler.

This tool helps document the unknown control codes by:
1. Reading the jump table at ROM $00:9E0E
2. Following each handler address
3. Extracting handler code snippets
4. Identifying handler functions

Author: FFMQ Disassembly Project
Date: 2025-01-24
"""

import struct
from pathlib import Path

# ROM location constants
JUMP_TABLE_PC = 0x009E0E  # PC address in ROM
JUMP_TABLE_SIZE = 48  # 48 control code handlers
BANK_00_BASE = 0x000000  # Bank $00 starts at PC 0x000000

def read_jump_table(rom_path):
	"""
	Read the control code jump table from ROM.
	
	Args:
		rom_path: Path to ROM file
	
	Returns:
		dict: Mapping of control code to handler address
	"""
	handlers = {}
	
	with open(rom_path, 'rb') as f:
		f.seek(JUMP_TABLE_PC)
		
		for code in range(JUMP_TABLE_SIZE):
			# Read 16-bit address (little-endian)
			addr_bytes = f.read(2)
			if len(addr_bytes) < 2:
				break
			
			addr = struct.unpack('<H', addr_bytes)[0]
			
			# Convert SNES address to PC address (Bank $00)
			# SNES $00:XXXX -> PC 0x00XXXX (assuming direct mapping for Bank $00)
			pc_addr = addr if addr >= 0x8000 else addr + BANK_00_BASE
			
			handlers[code] = {
				'snes_addr': f'$00:{addr:04X}',
				'pc_addr': f'0x{pc_addr:06X}',
				'pc_offset': pc_addr
			}
	
	return handlers

def extract_handler_code(rom_path, pc_offset, max_bytes=64):
	"""
	Extract code bytes from handler location.
	
	Args:
		rom_path: Path to ROM file
		pc_offset: PC offset of handler
		max_bytes: Maximum bytes to extract
	
	Returns:
		bytes: Handler code bytes
	"""
	with open(rom_path, 'rb') as f:
		f.seek(pc_offset)
		return f.read(max_bytes)

def disassemble_snippet(code_bytes, pc_offset):
	"""
	Create a simple hex dump of code bytes.
	
	For proper disassembly, use external tools like DiztinGUIsh.
	This is just a hex dump with basic pattern recognition.
	"""
	lines = []
	
	# Look for common 65816 patterns
	patterns = {
		0x60: 'RTS',
		0x6B: 'RTL',
		0x40: 'RTI',
		0xA9: 'LDA #',
		0xAD: 'LDA $',
		0x8D: 'STA $',
		0xC9: 'CMP #',
		0xF0: 'BEQ',
		0xD0: 'BNE',
		0x20: 'JSR',
		0x4C: 'JMP',
	}
	
	i = 0
	while i < len(code_bytes):
		addr = pc_offset + i
		byte = code_bytes[i]
		
		# Check for known instruction
		if byte in patterns:
			mnemonic = patterns[byte]
			
			# For branch instructions, show relative offset
			if byte in [0xF0, 0xD0] and i + 1 < len(code_bytes):
				offset = code_bytes[i + 1]
				if offset >= 0x80:
					offset = offset - 256  # Negative offset
				target = addr + 2 + offset
				lines.append(f'{addr:06X}  {byte:02X} {code_bytes[i+1]:02X}	   {mnemonic} ${target:04X}')
				i += 2
				continue
			
			# For JSR/JMP, show target address
			elif byte in [0x20, 0x4C] and i + 2 < len(code_bytes):
				target = struct.unpack('<H', code_bytes[i+1:i+3])[0]
				lines.append(f'{addr:06X}  {byte:02X} {code_bytes[i+1]:02X} {code_bytes[i+2]:02X}	{mnemonic} ${target:04X}')
				i += 3
				continue
			
			# For immediate/absolute addressing
			elif i + 1 < len(code_bytes):
				lines.append(f'{addr:06X}  {byte:02X} {code_bytes[i+1]:02X}	   {mnemonic}')
				i += 2
				continue
		
		# Unknown - just show hex
		lines.append(f'{addr:06X}  {byte:02X}		   ???')
		i += 1
	
	return '\n'.join(lines)

def analyze_handlers(rom_path, output_path=None):
	"""
	Analyze all control code handlers and generate report.
	
	Args:
		rom_path: Path to ROM file
		output_path: Optional output file path
	"""
	print("Control Code Handler Analysis")
	print("=" * 70)
	print(f"ROM: {rom_path}")
	print(f"Jump Table: PC {JUMP_TABLE_PC:06X} (SNES $00:{JUMP_TABLE_PC:04X})")
	print(f"Handlers: {JUMP_TABLE_SIZE}")
	print("=" * 70)
	print()
	
	# Read jump table
	handlers = read_jump_table(rom_path)
	
	if not handlers:
		print("❌ ERROR: Could not read jump table!")
		return
	
	print(f"✅ Read {len(handlers)} handler addresses\n")
	
	# Group handlers by address (find duplicates)
	addr_to_codes = {}
	for code, info in handlers.items():
		addr = info['pc_offset']
		if addr not in addr_to_codes:
			addr_to_codes[addr] = []
		addr_to_codes[addr].append(code)
	
	# Analyze each unique handler
	output_lines = []
	output_lines.append("FFMQ Control Code Handler Analysis")
	output_lines.append("=" * 70)
	output_lines.append(f"Jump Table Location: ROM PC {JUMP_TABLE_PC:06X} (SNES $00:{JUMP_TABLE_PC:04X})")
	output_lines.append(f"Total Handlers: {JUMP_TABLE_SIZE}")
	output_lines.append(f"Unique Handlers: {len(addr_to_codes)}")
	output_lines.append("")
	
	# Show handler table
	output_lines.append("Handler Table:")
	output_lines.append("-" * 70)
	output_lines.append(f"{'Code':<6} {'SNES Addr':<12} {'PC Addr':<12} {'Shared With':<20}")
	output_lines.append("-" * 70)
	
	for code in range(JUMP_TABLE_SIZE):
		if code not in handlers:
			continue
		
		info = handlers[code]
		shared = addr_to_codes[info['pc_offset']]
		shared_str = ', '.join(f'{c:02X}' for c in shared if c != code)
		
		output_lines.append(f"0x{code:02X}   {info['snes_addr']:<12} {info['pc_addr']:<12} {shared_str:<20}")
	
	output_lines.append("")
	output_lines.append("")
	
	# Show code snippets for unique handlers
	output_lines.append("Handler Code Snippets:")
	output_lines.append("=" * 70)
	
	for addr in sorted(addr_to_codes.keys()):
		codes = addr_to_codes[addr]
		codes_str = ', '.join(f'0x{c:02X}' for c in codes)
		
		output_lines.append("")
		output_lines.append(f"Handler for: {codes_str}")
		output_lines.append(f"Location: PC {addr:06X}")
		output_lines.append("-" * 70)
		
		# Extract and disassemble code
		code_bytes = extract_handler_code(rom_path, addr)
		disasm = disassemble_snippet(code_bytes, addr)
		
		output_lines.append(disasm)
		output_lines.append("")
	
	# Print to console
	for line in output_lines:
		print(line)
	
	# Save to file if requested
	if output_path:
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write('\n'.join(output_lines))
		print(f"\n✅ Report saved to {output_path}")

def main():
	"""Main entry point."""
	import sys
	
	if len(sys.argv) < 2:
		print("Usage: python analyze_control_handlers.py <rom_path> [output_path]")
		print()
		print("Example:")
		print("  python tools/analysis/analyze_control_handlers.py roms/ffmq.sfc reports/control_handlers.txt")
		return 1
	
	rom_path = sys.argv[1]
	output_path = sys.argv[2] if len(sys.argv) > 2 else None
	
	if not Path(rom_path).exists():
		print(f"❌ ERROR: ROM file not found: {rom_path}")
		return 1
	
	analyze_handlers(rom_path, output_path)
	return 0

if __name__ == "__main__":
	import sys
	sys.exit(main())
