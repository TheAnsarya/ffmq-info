#!/usr/bin/env python3
"""
Map Dialog Commands to Functions
Cross-reference ROM code with dialog data to identify command functions
"""

from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Tuple
import struct


# Known commands from analysis and DataCrystal
KNOWN_COMMANDS = {
	# Confirmed from game behavior and DataCrystal
	0x00: {"name": "END", "bytes": 1, "function": "End of string", "confirmed": True},
	0x01: {"name": "NEWLINE", "bytes": 1, "function": "Line break", "confirmed": True},
	0x02: {"name": "WAIT", "bytes": 1, "function": "Wait for button press", "confirmed": True},
	0x03: {"name": "ASTERISK", "bytes": 1, "function": "Display asterisk character", "confirmed": False},
	0x04: {"name": "NAME", "bytes": 1, "function": "Insert character name", "confirmed": True},
	0x05: {"name": "ITEM", "bytes": 1, "function": "Insert item name", "confirmed": True},
	0x06: {"name": "SPACE", "bytes": 1, "function": "Space character", "confirmed": True},
	
	# Text speed/timing (speculative from analysis)
	0x07: {"name": "SPEED_SLOW", "bytes": 1, "function": "Slow text speed", "confirmed": False},
	0x08: {"name": "SPEED_NORM", "bytes": 1, "function": "Normal text speed", "confirmed": False},
	0x09: {"name": "SPEED_FAST", "bytes": 1, "function": "Fast text speed", "confirmed": False},
	
	# Multi-byte commands from pattern analysis
	0x0A: {"name": "DELAY", "bytes": 2, "function": "Delay with parameter", "confirmed": False},
	0x0D: {"name": "SET_FLAG", "bytes": 3, "function": "Set game flag (param1, param2)", "confirmed": False},
	
	# Dialog box positioning (from DataCrystal)
	0x1A: {"name": "TEXTBOX_BELOW", "bytes": 1, "function": "Position dialog box below", "confirmed": True},
	0x1B: {"name": "TEXTBOX_ABOVE", "bytes": 1, "function": "Position dialog box above", "confirmed": True},
	
	# Dialog control
	0x23: {"name": "CLEAR", "bytes": 1, "function": "Clear dialog box", "confirmed": True},
	0x30: {"name": "PARA", "bytes": 1, "function": "Paragraph break", "confirmed": True},
	0x36: {"name": "PAGE", "bytes": 1, "function": "New page/dialog box", "confirmed": True},
	
	# Extended control codes (0x80-0x8F)
	0x80: {"name": "EXT_80", "bytes": 2, "function": "Extended command with param", "confirmed": False},
	0x81: {"name": "EXT_81", "bytes": 2, "function": "Extended command with param", "confirmed": False},
	0x82: {"name": "EXT_82", "bytes": 2, "function": "Extended command with param", "confirmed": False},
	0x88: {"name": "EXT_88", "bytes": 2, "function": "Extended command (followed by 0x10)", "confirmed": False},
	0x8B: {"name": "EXT_8B", "bytes": 2, "function": "Extended command (followed by 0x05)", "confirmed": False},
	0x8D: {"name": "EXT_8D", "bytes": 2, "function": "Extended command with param", "confirmed": False},
	0x8E: {"name": "EXT_8E", "bytes": 2, "function": "Extended command (usually 0x14)", "confirmed": False},
	0x8F: {"name": "EXT_8F", "bytes": 2, "function": "Extended command (usually 0x30)", "confirmed": False},
	
	# Commands from frequency analysis
	0x10: {"name": "PARAM_10", "bytes": 1, "function": "Parameter/event code", "confirmed": False},
	0x14: {"name": "PARAM_14", "bytes": 2, "function": "Multi-byte parameter (usually 0x91)", "confirmed": False},
	0x20: {"name": "PARAM_20", "bytes": 1, "function": "Parameter/event code", "confirmed": False},
	0x2A: {"name": "PARAM_2A", "bytes": 1, "function": "Parameter/event code", "confirmed": False},
	0x2C: {"name": "PARAM_2C", "bytes": 1, "function": "Parameter/event code", "confirmed": False},
}


# Commands that need investigation (high frequency, unknown function)
NEEDS_INVESTIGATION = [
	0x03, 0x07, 0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
	0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x20, 0x21, 0x22,
	0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C,
	0x31, 0x32, 0x33, 0x34, 0x35, 0x37, 0x38, 0x3A, 0x3B,
	0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x88, 0x89, 0x8A, 0x8B, 0x8D
]


# Menu/shop/inn commands (mentioned by user, need to find)
MENU_COMMANDS = {
	"shop": None,  # To be identified
	"inn": None,   # To be identified
	"yes_no": None,  # To be identified
	"menu_open": None,  # To be identified
}


def analyze_command_sequences():
	"""Analyze command byte sequences to identify patterns"""
	rom_path = Path(__file__).parent.parent.parent / 'roms' / 'Final Fantasy - Mystic Quest (U) (V1.1).sfc'
	
	if not rom_path.exists():
		print(f"ERROR: ROM not found at {rom_path}")
		return
	
	with open(rom_path, 'rb') as f:
		rom_data = f.read()
	
	# Extract all dialogs
	pointer_table_pc = 0x0D636
	dialog_count = 116
	
	print("Analyzing command sequences in all dialogs...\n")
	
	command_patterns = defaultdict(list)
	
	for dialog_id in range(dialog_count):
		# Read pointer
		ptr_offset = pointer_table_pc + (dialog_id * 2)
		snes_pointer = struct.unpack('<H', rom_data[ptr_offset:ptr_offset+2])[0]
		
		# Convert to PC address
		if snes_pointer >= 0x8000:
			pc_address = 0x018000 + (snes_pointer - 0x8000)
		else:
			pc_address = 0x018000 + snes_pointer
		
		# Read dialog bytes
		dialog_bytes = bytearray()
		offset = pc_address
		while offset < len(rom_data):
			byte = rom_data[offset]
			dialog_bytes.append(byte)
			if byte == 0x00:
				break
			offset += 1
		
		# Find command sequences
		i = 0
		while i < len(dialog_bytes):
			byte = dialog_bytes[i]
			
			# Check if it's a control code
			if byte < 0x3D or (byte >= 0x80 and byte < 0x90):
				# Extract context (3 bytes before and after)
				before = dialog_bytes[max(0, i-3):i]
				after = dialog_bytes[i+1:min(len(dialog_bytes), i+4)]
				
				command_patterns[byte].append({
					'dialog_id': dialog_id,
					'position': i,
					'before': before.hex(),
					'after': after.hex(),
					'full_context': dialog_bytes[max(0, i-5):min(len(dialog_bytes), i+6)].hex()
				})
			
			i += 1
	
	# Generate mapping guide
	output_path = Path(__file__).parent.parent.parent / 'docs' / 'DIALOG_COMMAND_MAPPING.md'
	
	with open(output_path, 'w', encoding='utf-8') as f:
		f.write("# FFMQ Dialog Command Mapping Guide\n\n")
		f.write("## Command Reference\n\n")
		f.write("This document maps all control codes used in FFMQ dialog system.\n\n")
		
		# Confirmed commands
		f.write("### Confirmed Commands\n\n")
		f.write("| Byte | Name | Bytes | Function | Evidence |\n")
		f.write("|------|------|-------|----------|----------|\n")
		
		for byte_val in sorted(KNOWN_COMMANDS.keys()):
			cmd = KNOWN_COMMANDS[byte_val]
			if cmd['confirmed']:
				f.write(f"| 0x{byte_val:02X} | {cmd['name']} | {cmd['bytes']} | {cmd['function']} | ✓ |\n")
		
		# Speculative commands
		f.write("\n### Speculative Commands (Need Verification)\n\n")
		f.write("| Byte | Name | Bytes | Function | Evidence |\n")
		f.write("|------|------|-------|----------|----------|\n")
		
		for byte_val in sorted(KNOWN_COMMANDS.keys()):
			cmd = KNOWN_COMMANDS[byte_val]
			if not cmd['confirmed']:
				f.write(f"| 0x{byte_val:02X} | {cmd['name']} | {cmd['bytes']} | {cmd['function']} | Pattern analysis |\n")
		
		# Commands needing investigation
		f.write("\n### Commands Needing Investigation\n\n")
		f.write("These commands appear in dialogs but their function is unknown:\n\n")
		f.write("| Byte | Uses | Sample Contexts |\n")
		f.write("|------|------|----------------|\n")
		
		for byte_val in sorted(NEEDS_INVESTIGATION):
			if byte_val in command_patterns:
				uses = len(command_patterns[byte_val])
				# Get 2 sample contexts
				samples = command_patterns[byte_val][:2]
				context_str = "<br>".join([f"D{s['dialog_id']}:{s['full_context']}" for s in samples])
				f.write(f"| 0x{byte_val:02X} | {uses} | {context_str} |\n")
		
		# Detailed analysis per command
		f.write("\n## Detailed Command Analysis\n\n")
		
		for byte_val in sorted(command_patterns.keys()):
			if byte_val < 0x3D or (byte_val >= 0x80 and byte_val < 0x90):
				f.write(f"\n### 0x{byte_val:02X}\n\n")
				
				if byte_val in KNOWN_COMMANDS:
					cmd = KNOWN_COMMANDS[byte_val]
					f.write(f"**Name:** {cmd['name']}\n\n")
					f.write(f"**Function:** {cmd['function']}\n\n")
					f.write(f"**Byte Count:** {cmd['bytes']}\n\n")
					f.write(f"**Status:** {'✓ Confirmed' if cmd['confirmed'] else '? Speculative'}\n\n")
				
				patterns = command_patterns[byte_val]
				f.write(f"**Total Uses:** {len(patterns)}\n\n")
				
				# Show first 5 contexts
				f.write("**Sample Contexts:**\n\n")
				f.write("```\n")
				for i, ctx in enumerate(patterns[:5]):
					f.write(f"Dialog {ctx['dialog_id']:3d} pos {ctx['position']:3d}: ...{ctx['before']} [{byte_val:02X}] {ctx['after']}...\n")
				f.write("```\n")
		
		# Research notes
		f.write("\n## Research Notes\n\n")
		f.write("### Menu Commands\n\n")
		f.write("User mentioned dialog contains commands for:\n")
		f.write("- Shop menu\n")
		f.write("- Inn menu\n")
		f.write("- Yes/No prompts\n\n")
		f.write("**Action Required:** Analyze game code to find these specific commands.\n\n")
		
		f.write("### Character Movement\n\n")
		f.write("Dialog can trigger character movement/positioning.\n\n")
		f.write("**Candidates:**\n")
		f.write("- 0x36 (PAGE) - might also trigger movement\n")
		f.write("- 0x10-0x3B range - likely event parameters\n\n")
		
		f.write("### Dialog Box Positioning\n\n")
		f.write("**Confirmed from DataCrystal:**\n")
		f.write("- 0x1A: Position textbox below\n")
		f.write("- 0x1B: Position textbox above\n\n")
	
	print(f"Mapping guide written to {output_path}")
	
	# Summary
	print(f"\nCommand Analysis Summary:")
	print(f"  Total unique control codes: {len(command_patterns)}")
	print(f"  Confirmed commands: {sum(1 for c in KNOWN_COMMANDS.values() if c['confirmed'])}")
	print(f"  Speculative commands: {sum(1 for c in KNOWN_COMMANDS.values() if not c['confirmed'])}")
	print(f"  Need investigation: {len(NEEDS_INVESTIGATION)}")


if __name__ == '__main__':
	analyze_command_sequences()
