#!/usr/bin/env python3
"""
FFMQ Dialog Compiler
====================

Compiles human-readable dialog scripts into FFMQ ROM format.

This tool enables easy creation and modification of dialog for fan
translations and ROM hacks by providing:

1. Human-readable script format
2. Automatic character encoding
3. Control code integration
4. Dictionary reference insertion
5. Pointer table generation
6. ROM patching

Script Format:
--------------
```
[DIALOG 0]
@TEXTBOX_BOTTOM
Welcome to the world of
#Final Fantasy Mystic Quest#!
[END]

[DIALOG 1]
@TEXTBOX_TOP
What's your name?
[WAIT]
[END]
```

Author: TheAnsarya
Date: 2025-11-12
License: MIT
"""

import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Any


class DialogCompiler:
	"""Compiles human-readable dialog scripts to ROM format."""
	
	# Control code mappings
	CONTROL_CODES = {
		'[END]': 0x00,
		'[NEWLINE]': 0x01,
		'[DELAY]': 0x02,
		'[WAIT]': 0x03,
		'[CONTINUE]': 0x04,
		'[CLEAR]': 0x05,
		'[TEXTBOX_BOTTOM]': 0x23,
		'[TEXTBOX_MIDDLE]': 0x24,
		'[TEXTBOX_TOP]': 0x25,
		'[ITEM]': 0x26,
		'[CMD:08]': 0x08,  # Subroutine call
		'[CMD:0E]': 0x0E,  # Memory write
		'[CMD:10]': 0x10,  # Equipment name
		'[CMD:17]': 0x17,  # Item name
		'[CMD:18]': 0x18,  # Item name
		'[CMD:1D]': 0x1D,  # Formatting code
		'[CMD:1E]': 0x1E,  # Formatting code
		'[NAME]': 0x20,    # Player name
	}
	
	# Special tokens
	TOKENS = {
		'@TEXTBOX_BOTTOM': 0x23,
		'@TEXTBOX_MIDDLE': 0x24,
		'@TEXTBOX_TOP': 0x25,
	}
	
	def __init__(self, table_file: str):
		"""
		Initialize compiler.
		
		Args:
			table_file: Path to character table file (.tbl)
		"""
		self.table_file = Path(table_file)
		self.char_map: Dict[str, int] = {}
		self.reverse_map: Dict[int, str] = {}
		self.dictionary: Dict[int, str] = {}
	
	def load_character_table(self) -> None:
		"""Load character encoding table."""
		print(f"Loading character table: {self.table_file}")
		
		with open(self.table_file, 'r', encoding='utf-8') as f:
			for line in f:
				line = line.strip()
				if not line or line.startswith('#'):
					continue
				
				# Format: BYTE=CHAR
				if '=' in line:
					byte_str, char = line.split('=', 1)
					byte_val = int(byte_str, 16)
					
					self.char_map[char] = byte_val
					self.reverse_map[byte_val] = char
		
		print(f"  Loaded {len(self.char_map)} character mappings")
	
	def compile_text(self, text: str) -> List[int]:
		"""
		Compile text to byte sequence.
		
		Args:
			text: Human-readable text with control codes
		
		Returns:
			List of bytes
		"""
		bytes_out = []
		i = 0
		
		while i < len(text):
			# Check for control codes
			if text[i] == '[':
				# Find closing bracket
				end = text.find(']', i)
				if end != -1:
					code_name = text[i:end+1]
					
					if code_name in self.CONTROL_CODES:
						bytes_out.append(self.CONTROL_CODES[code_name])
						i = end + 1
						continue
					
					# Handle parameterized codes like [CMD:08 XX]
					# Check for space after code name
					if ' ' in code_name:
						parts = code_name[:-1].split()  # Remove ] and split
						base_code = parts[0] + ']'
						
						if base_code in self.CONTROL_CODES:
							bytes_out.append(self.CONTROL_CODES[base_code])
							
							# Parse parameters
							for param in parts[1:]:
								bytes_out.append(int(param, 16))
							
							i = end + 1
							continue
			
			# Check for special tokens (@ prefix)
			if text[i] == '@':
				for token, byte_val in self.TOKENS.items():
					if text[i:i+len(token)] == token:
						bytes_out.append(byte_val)
						i += len(token)
						break
				else:
					i += 1
				continue
			
			# Check for newline
			if text[i] == '\n':
				bytes_out.append(0x01)  # NEWLINE
				i += 1
				continue
			
			# Regular character
			char = text[i]
			if char in self.char_map:
				bytes_out.append(self.char_map[char])
			else:
				# Unknown character - skip with warning
				print(f"Warning: Unknown character '{char}' (U+{ord(char):04X})")
			
			i += 1
		
		return bytes_out
	
	def parse_script(self, script_path: str) -> List[Dict[str, Any]]:
		"""
		Parse dialog script file.
		
		Args:
			script_path: Path to script file
		
		Returns:
			List of dialog dictionaries
		"""
		file_path = Path(script_path)
		
		print(f"Parsing script: {file_path}")
		
		dialogs: List[Dict[str, Any]] = []
		current_dialog: Optional[Dict[str, Any]] = None
		current_text: List[str] = []
		
		with open(file_path, 'r', encoding='utf-8') as f:
			for line_num, line in enumerate(f, 1):
				# Strip trailing whitespace but preserve leading spaces
				line = line.rstrip()
				
				# Skip empty lines and comments
				if not line or line.strip().startswith('#'):
					continue
				
				# Dialog header: [DIALOG N]
				dialog_match = re.match(r'\[DIALOG\s+(\d+)\]', line.strip())
				if dialog_match:
					# Save previous dialog
					if current_dialog is not None:
						current_dialog['text'] = '\n'.join(current_text)
						current_dialog['bytes'] = self.compile_text(current_dialog['text'])
						dialogs.append(current_dialog)
					
					# Start new dialog
					dialog_id = int(dialog_match.group(1))
					current_dialog = {
						'id': dialog_id,
						'line_num': line_num,
					}
					current_text = []
					continue
				
				# Accumulate text lines
				if current_dialog is not None:
					current_text.append(line)
		
		# Save last dialog
		if current_dialog is not None:
			current_dialog['text'] = '\n'.join(current_text)
			current_dialog['bytes'] = self.compile_text(current_dialog['text'])
			dialogs.append(current_dialog)
		
		print(f"  Parsed {len(dialogs)} dialogs")
		
		return dialogs
	
	def generate_pointer_table(self, dialogs: List[Dict[str, Any]], base_address: int) -> List[int]:
		"""
		Generate pointer table for dialogs.
		
		Args:
			dialogs: List of dialog dictionaries
			base_address: Base address for dialog data
		
		Returns:
			List of pointers (16-bit addresses)
		"""
		pointers = []
		current_offset = base_address
		
		for dialog in sorted(dialogs, key=lambda d: d['id']):
			# Pointer is offset from base
			pointer = current_offset
			pointers.append(pointer)
			
			# Advance offset by dialog byte length
			current_offset += len(dialog['bytes'])
		
		return pointers
	
	def patch_rom(self, rom_path: str, dialogs: List[Dict[str, Any]],
	              output_path: str,
	              pointer_table_addr: int = 0x01B835,
	              dialog_data_addr: int = 0x01C000) -> None:
		"""
		Patch ROM with compiled dialogs.
		
		Args:
			rom_path: Input ROM path
			dialogs: Compiled dialogs
			output_path: Output ROM path
			pointer_table_addr: Address to write pointer table
			dialog_data_addr: Address to write dialog data
		"""
		print(f"\nPatching ROM: {rom_path}")
		
		# Load ROM
		with open(rom_path, 'rb') as f:
			rom_data = bytearray(f.read())
		
		print(f"  ROM size: {len(rom_data):,} bytes")
		
		# Generate pointer table
		pointers = self.generate_pointer_table(dialogs, dialog_data_addr)
		
		# Write pointer table
		print(f"  Writing pointer table at 0x{pointer_table_addr:06X}")
		
		for i, pointer in enumerate(pointers):
			addr = pointer_table_addr + (i * 2)
			
			if addr + 1 < len(rom_data):
				# Write 16-bit pointer (little-endian)
				rom_data[addr] = pointer & 0xFF
				rom_data[addr + 1] = (pointer >> 8) & 0xFF
		
		# Write dialog data
		print(f"  Writing dialog data at 0x{dialog_data_addr:06X}")
		
		current_addr = dialog_data_addr
		
		for dialog in sorted(dialogs, key=lambda d: d['id']):
			dialog_bytes = dialog['bytes']
			
			# Write bytes
			for byte_val in dialog_bytes:
				if current_addr < len(rom_data):
					rom_data[current_addr] = byte_val
					current_addr += 1
			
			print(f"    Dialog #{dialog['id']}: {len(dialog_bytes)} bytes")
		
		total_bytes = current_addr - dialog_data_addr
		print(f"  Total dialog data: {total_bytes} bytes")
		
		# Save patched ROM
		with open(output_path, 'wb') as f:
			f.write(rom_data)
		
		print(f"\nPatched ROM saved: {output_path}")
	
	def validate_dialogs(self, dialogs: List[Dict[str, Any]]) -> bool:
		"""
		Validate compiled dialogs.
		
		Args:
			dialogs: List of dialogs
		
		Returns:
			True if all dialogs valid
		"""
		print("\nValidating dialogs...")
		
		errors = []
		
		for dialog in dialogs:
			dialog_id = dialog['id']
			dialog_bytes = dialog['bytes']
			
			# Check for END code
			if 0x00 not in dialog_bytes:
				errors.append(f"Dialog #{dialog_id}: Missing [END] code")
			
			# Check for excessive length
			if len(dialog_bytes) > 1024:
				errors.append(f"Dialog #{dialog_id}: Too long ({len(dialog_bytes)} bytes)")
			
			# Check for invalid bytes
			for byte_val in dialog_bytes:
				if byte_val > 0xFF:
					errors.append(f"Dialog #{dialog_id}: Invalid byte value {byte_val}")
		
		if errors:
			print("  Validation FAILED:")
			for error in errors:
				print(f"    - {error}")
			return False
		else:
			print("  Validation PASSED")
			return True
	
	def generate_report(self, dialogs: List[Dict[str, Any]], output_path: str) -> None:
		"""
		Generate compilation report.
		
		Args:
			dialogs: Compiled dialogs
			output_path: Report file path
		"""
		print(f"\nGenerating report: {output_path}")
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("=" * 80 + "\n")
			f.write("Dialog Compilation Report\n")
			f.write("=" * 80 + "\n\n")
			
			f.write(f"**Total Dialogs**: {len(dialogs)}\n\n")
			
			total_bytes = sum(len(d['bytes']) for d in dialogs)
			f.write(f"**Total Bytes**: {total_bytes:,}\n")
			f.write(f"**Average Dialog Length**: {total_bytes / len(dialogs):.1f} bytes\n\n")
			
			# Dialog details
			for dialog in sorted(dialogs, key=lambda d: d['id']):
				f.write("-" * 80 + "\n")
				f.write(f"## Dialog #{dialog['id']}\n\n")
				f.write(f"**Length**: {len(dialog['bytes'])} bytes\n")
				f.write(f"**Source Line**: {dialog['line_num']}\n\n")
				
				f.write("**Text**:\n```\n")
				f.write(dialog['text'])
				f.write("\n```\n\n")
				
				f.write("**Compiled Bytes**:\n```\n")
				bytes_hex = ' '.join(f'{b:02X}' for b in dialog['bytes'])
				
				# Wrap at 16 bytes per line
				for i in range(0, len(bytes_hex), 48):  # 16 bytes * 3 chars = 48
					f.write(bytes_hex[i:i+48] + "\n")
				
				f.write("```\n\n")
			
			f.write("=" * 80 + "\n")
			f.write("End of Report\n")
			f.write("=" * 80 + "\n")
		
		print(f"Report saved: {output_path}")


def main():
	"""Main entry point."""
	import argparse
	
	parser = argparse.ArgumentParser(
		description="Compile human-readable dialog scripts to FFMQ ROM format"
	)
	parser.add_argument(
		"script",
		help="Input script file (.txt)"
	)
	parser.add_argument(
		"--table",
		help="Character table file (.tbl)",
		default="simple.tbl"
	)
	parser.add_argument(
		"--rom",
		help="Input ROM file",
		default="roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"
	)
	parser.add_argument(
		"--output",
		help="Output ROM file",
		default="roms/compiled_dialog.sfc"
	)
	parser.add_argument(
		"--report",
		help="Generate compilation report",
		default="docs/COMPILATION_REPORT.md"
	)
	parser.add_argument(
		"--validate",
		help="Validate dialogs before patching",
		action="store_true"
	)
	parser.add_argument(
		"--no-patch",
		help="Skip ROM patching (compile only)",
		action="store_true"
	)
	
	args = parser.parse_args()
	
	print("=" * 80)
	print("FFMQ Dialog Compiler")
	print("=" * 80)
	
	compiler = DialogCompiler(args.table)
	compiler.load_character_table()
	
	# Parse script
	dialogs = compiler.parse_script(args.script)
	
	# Validate if requested
	if args.validate:
		if not compiler.validate_dialogs(dialogs):
			print("\nCompilation aborted due to validation errors")
			return
	
	# Generate report
	if args.report:
		compiler.generate_report(dialogs, args.report)
	
	# Patch ROM
	if not args.no_patch:
		compiler.patch_rom(args.rom, dialogs, args.output)
	else:
		print("\nSkipping ROM patching (--no-patch)")
	
	print("\n" + "=" * 80)
	print("Compilation complete!")
	print("=" * 80)


if __name__ == "__main__":
	main()
