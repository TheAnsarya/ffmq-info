#!/usr/bin/env python3
"""
Control Code Handler Disassembly Extractor
============================================

Extracts disassembled handler code from bank_00.asm for all 48 control codes.
Cross-references with jump table data to create comprehensive documentation.

Author: TheAnsarya
Date: 2025-11-12
License: MIT
"""

import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional


class HandlerDisassemblyExtractor:
	"""Extracts and documents control code handler disassembly."""
	
	def __init__(self, asm_path: str, handlers_file: str):
		"""
		Initialize the extractor.
		
		Args:
			asm_path: Path to bank_00.asm file
			handlers_file: Path to control_code_handlers.txt (from previous analysis)
		"""
		self.asm_path = Path(asm_path)
		self.handlers_file = Path(handlers_file)
		self.handlers: Dict[int, Dict] = {}
		self.asm_lines: List[str] = []
		self.label_map: Dict[int, str] = {}  # Address → label name
		
		# Known handler names (from our analysis + discoveries)
		self.handler_names = {
			0x00: ("Dialog_End", "END - Sets bit to signal dialog end"),
			0x01: ("Dialog_Newline", "NEWLINE - Advance to next line"),
			0x02: ("Dialog_Wait", "WAIT - Wait for user input"),
			0x03: ("Dialog_Portrait", "ASTERISK/PORTRAIT - Display NPC portrait"),
			0x04: ("Dialog_Name", "NAME - Insert character name"),
			0x05: ("Dialog_Item", "ITEM - Insert item name"),
			0x06: ("Dialog_Space", "SPACE - Insert space character"),
			0x07: ("Dialog_Unknown07", "Unknown control code 0x07"),
			0x08: ("Dialog_ExecuteSubroutine_WithPointer", "SUBROUTINE CALL - Execute dialog subroutine (CRITICAL - 500+ uses)"),
			0x09: ("Dialog_Unknown09", "Unknown control code 0x09"),
			0x0A: ("Dialog_Unknown0A", "Unknown control code 0x0A"),
			0x0B: ("Dialog_Unknown0B", "Unknown control code 0x0B"),
			0x0C: ("Dialog_Unknown0C", "Unknown control code 0x0C"),
			0x0D: ("Dialog_Unknown0D", "Unknown control code 0x0D"),
			0x0E: ("Dialog_Unknown0E", "Unknown control code 0x0E (FREQUENT - 100+ uses)"),
			0x0F: ("Dialog_Unknown0F", "Unknown control code 0x0F"),
			0x10: ("Dialog_InsertItemName", "INSERT_ITEM_NAME - Dynamic item name"),
			0x11: ("Dialog_InsertSpellName", "INSERT_SPELL_NAME - Dynamic spell name"),
			0x12: ("Dialog_InsertMonsterName", "INSERT_MONSTER_NAME - Dynamic monster name"),
			0x13: ("Dialog_InsertCharacterName", "INSERT_CHARACTER_NAME - Dynamic character name"),
			0x14: ("Dialog_InsertLocationName", "INSERT_LOCATION_NAME - Dynamic location name"),
			0x15: ("Dialog_InsertNumber", "INSERT_NUMBER? - Unused/number insertion"),
			0x16: ("Dialog_InsertObjectName", "INSERT_OBJECT_NAME - Dynamic object name"),
			0x17: ("Dialog_InsertWeaponName", "INSERT_WEAPON_NAME - Dynamic weapon name"),
			0x18: ("Dialog_InsertArmorName", "INSERT_ARMOR_NAME - Dynamic armor name"),
			0x19: ("Dialog_InsertAccessory", "INSERT_ACCESSORY? - Unused/accessory name"),
			0x1A: ("Dialog_TextboxBelow", "TEXTBOX_BELOW - Position textbox below"),
			0x1B: ("Dialog_TextboxAbove", "TEXTBOX_ABOVE - Position textbox above"),
			0x1C: ("Dialog_Unknown1C", "Unknown control code 0x1C"),
			0x1D: ("Dialog_FormatItemE1", "FORMAT_ITEM_E1 - Dictionary 0x50 formatting"),
			0x1E: ("Dialog_FormatItemE2", "FORMAT_ITEM_E2 - Dictionary 0x51 formatting"),
			0x1F: ("Dialog_Crystal", "CRYSTAL - Crystal reference"),
			0x20: ("Dialog_Unknown20", "Unknown control code 0x20"),
			0x21: ("Dialog_Unknown21", "Unknown control code 0x21"),
			0x22: ("Dialog_Unknown22", "Unknown control code 0x22"),
			0x23: ("Dialog_Unknown23", "Unknown control code 0x23"),
			0x24: ("Dialog_Unknown24", "Unknown control code 0x24"),
			0x25: ("Dialog_Unknown25", "Unknown control code 0x25"),
			0x26: ("Dialog_Unknown26", "Unknown control code 0x26"),
			0x27: ("Dialog_Unknown27", "Unknown control code 0x27"),
			0x28: ("Dialog_Unknown28", "Unknown control code 0x28"),
			0x29: ("Dialog_Unknown29", "Unknown control code 0x29"),
			0x2A: ("Dialog_Unknown2A", "Unknown control code 0x2A"),
			0x2B: ("Dialog_Unknown2B", "Unknown control code 0x2B"),
			0x2C: ("Dialog_Unknown2C", "Unknown control code 0x2C"),
			0x2D: ("Dialog_Unknown2D", "Unknown control code 0x2D"),
			0x2E: ("Dialog_Unknown2E", "Unknown control code 0x2E"),
			0x2F: ("Dialog_Unknown2F", "Unknown control code 0x2F"),
		}
	
	def load_handlers(self) -> None:
		"""Load handler addresses from control_code_handlers.txt."""
		print(f"Loading handler addresses from {self.handlers_file}...")
		
		with open(self.handlers_file, 'r', encoding='utf-8') as f:
			for line in f:
				line = line.strip()
				if not line or line.startswith('#') or line == '```':
					continue
				
				# Parse: 0x00: NAME → 0x00A378
				match = re.match(r'0x([0-9A-F]{2}):\s+.*?→\s+0x([0-9A-F]{6})', line)
				if match:
					code = int(match.group(1), 16)
					address = int(match.group(2), 16)
					
					label_name, description = self.handler_names.get(code, (f"Unknown_{code:02X}", "Unknown"))
					
					self.handlers[code] = {
						'address': address,
						'address_hex': f'0x{address:06X}',
						'label': label_name,
						'description': description,
					}
		
		print(f"  Loaded {len(self.handlers)} handler addresses")
	
	def load_assembly(self) -> None:
		"""Load assembly file."""
		print(f"Loading assembly from {self.asm_path}...")
		
		with open(self.asm_path, 'r', encoding='utf-8') as f:
			self.asm_lines = f.readlines()
		
		print(f"  Loaded {len(self.asm_lines)} lines of assembly")
	
	def build_label_map(self) -> None:
		"""Build map of addresses to label names from assembly."""
		print("Building label map from assembly...")
		
		label_pattern = re.compile(r'^([A-Za-z_][A-Za-z0-9_]*):\s*$')
		addr_pattern = re.compile(r';([0-9A-F]{6})\|')
		
		current_label = None
		
		for line in self.asm_lines:
			# Check for label
			label_match = label_pattern.match(line)
			if label_match:
				current_label = label_match.group(1)
				continue
			
			# Check for address comment
			addr_match = addr_pattern.search(line)
			if addr_match and current_label:
				address = int(addr_match.group(1), 16)
				if address not in self.label_map:
					self.label_map[address] = current_label
				current_label = None  # Only map first instruction of label
		
		print(f"  Built map with {len(self.label_map)} labels")
	
	def find_handler_code(self, address: int, max_lines: int = 50) -> Tuple[List[str], Optional[str]]:
		"""
		Find handler code in assembly at given address.
		
		Args:
			address: SNES address of handler
			max_lines: Maximum lines to extract
		
		Returns:
			Tuple of (code_lines, label_name)
		"""
		# Find starting line
		addr_hex = f'{address:06X}'
		start_line = -1
		
		for i, line in enumerate(self.asm_lines):
			if f';{addr_hex}|' in line:
				start_line = i
				break
		
		if start_line == -1:
			return ([], None)
		
		# Look backwards for label
		label_name = self.label_map.get(address)
		if not label_name:
			for i in range(start_line - 1, max(0, start_line - 10), -1):
				if self.asm_lines[i].strip().endswith(':'):
					label_name = self.asm_lines[i].strip()[:-1]
					break
		
		# Extract code until next label or RTS
		code_lines = []
		for i in range(start_line, min(start_line + max_lines, len(self.asm_lines))):
			line = self.asm_lines[i]
			
			# Stop at next label (unless it's the first line)
			if i > start_line and line.strip().endswith(':'):
				break
			
			# Stop at RTS (but include it)
			if '\trts' in line.lower() or '|60      |' in line:
				code_lines.append(line.rstrip())
				break
			
			# Stop at RTL
			if '\trtl' in line.lower() or '|6B      |' in line:
				code_lines.append(line.rstrip())
				break
			
			# Stop at JMP (unconditional)
			if '\tjmp.w' in line.lower() or '\tjmp.l' in line.lower():
				code_lines.append(line.rstrip())
				break
			
			code_lines.append(line.rstrip())
		
		return (code_lines, label_name)
	
	def generate_documentation(self, output_path: str) -> None:
		"""
		Generate comprehensive handler documentation.
		
		Args:
			output_path: Path to output documentation file
		"""
		print(f"\nGenerating handler documentation: {output_path}")
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("=" * 80 + "\n")
			f.write("Control Code Handler Disassembly\n")
			f.write("Final Fantasy Mystic Quest - Complete Handler Documentation\n")
			f.write("=" * 80 + "\n\n")
			
			f.write("## Overview\n\n")
			f.write("This document contains the complete disassembled code for all 48 control\n")
			f.write("code handlers (0x00-0x2F) used in the dialog rendering system.\n\n")
			
			f.write("**Jump Table Location**: 0x009E0E (ROM 0x001E0E)\n\n")
			
			# Group by tier
			tiers = [
				("Basic Control Codes (0x00-0x06)", range(0x00, 0x07)),
				("Unknown Display Codes (0x07-0x0F)", range(0x07, 0x10)),
				("Dynamic Insertion Codes (0x10-0x1F)", range(0x10, 0x20)),
				("Advanced Codes (0x20-0x2F)", range(0x20, 0x30)),
			]
			
			for tier_name, code_range in tiers:
				f.write("-" * 80 + "\n")
				f.write(f"## {tier_name}\n\n")
				
				for code in code_range:
					if code not in self.handlers:
						continue
					
					handler = self.handlers[code]
					address = handler['address']
					label = handler['label']
					description = handler['description']
					
					# Extract handler code
					code_lines, found_label = self.find_handler_code(address, max_lines=80)
					
					if not code_lines:
						f.write(f"### Code 0x{code:02X}: {label}\n\n")
						f.write(f"**ERROR**: Handler code not found at {handler['address_hex']}\n\n")
						continue
					
					# Write header
					f.write(f"### Code 0x{code:02X}: {label}\n\n")
					f.write(f"**Address**: {handler['address_hex']}\n")
					f.write(f"**Description**: {description}\n")
					if found_label and found_label != label:
						f.write(f"**Assembly Label**: `{found_label}`\n")
					f.write("\n")
					
					# Write disassembly
					f.write("```asm\n")
					for line in code_lines:
						f.write(line + "\n")
					f.write("```\n\n")
					
					# Add analysis notes for critical codes
					notes = self.get_handler_notes(code, code_lines)
					if notes:
						f.write("**Analysis**:\n")
						for note in notes:
							f.write(f"- {note}\n")
						f.write("\n")
			
			# Summary section
			f.write("-" * 80 + "\n")
			f.write("## Handler Summary\n\n")
			
			f.write("### Critical Handlers\n\n")
			critical = [
				(0x00, "END - Text terminator (117 uses = 100% coverage)"),
				(0x08, "SUBROUTINE CALL - Execute dialog subroutine (500+ uses)"),
				(0x0E, "Unknown frequent operation (100+ uses)"),
				(0x10, "INSERT_ITEM_NAME - Most common dynamic code (55 uses)"),
			]
			
			for code, desc in critical:
				if code in self.handlers:
					addr = self.handlers[code]['address_hex']
					label = self.handlers[code]['label']
					f.write(f"- **0x{code:02X}**: `{label}` ({addr}) - {desc}\n")
			
			f.write("\n### Handler Groups\n\n")
			f.write("**Basic Operations**: 0x00 (END), 0x01 (NEWLINE), 0x02 (WAIT)\n\n")
			f.write("**Dynamic Insertion**: 0x10-0x18 (Item, Spell, Monster, etc.)\n\n")
			f.write("**Formatting**: 0x1D (FORMAT_ITEM_E1), 0x1E (FORMAT_ITEM_E2)\n\n")
			f.write("**Textbox Control**: 0x1A (BELOW), 0x1B (ABOVE)\n\n")
			
			f.write("=" * 80 + "\n")
			f.write("End of Documentation\n")
			f.write("=" * 80 + "\n")
		
		print(f"Documentation generated: {output_path}")
	
	def get_handler_notes(self, code: int, code_lines: List[str]) -> List[str]:
		"""
		Generate analysis notes for a handler based on its code.
		
		Args:
			code: Control code (0x00-0x2F)
			code_lines: Disassembled code lines
		
		Returns:
			List of analysis notes
		"""
		notes = []
		
		# Analyze based on code patterns
		code_text = '\n'.join(code_lines).upper()
		
		# Check for subroutine calls
		if 'JSR' in code_text or 'JSL' in code_text:
			notes.append("Calls subroutines - complex operation")
		
		# Check for parameter reading
		if 'LDA.B [$17]' in code_text and 'INC.B $17' in code_text:
			param_count = code_text.count('INC.B $17')
			if param_count > 0:
				notes.append(f"Reads {param_count} parameter byte(s) from dialog stream")
		
		# Check for memory writes
		if 'STA' in code_text:
			notes.append("Modifies memory/state")
		
		# Check for bit operations
		if 'TSB' in code_text or 'TRB' in code_text:
			notes.append("Sets/clears bitflags")
		
		# Check for conditional branches
		if 'BEQ' in code_text or 'BNE' in code_text or 'BCC' in code_text or 'BCS' in code_text:
			notes.append("Contains conditional logic")
		
		# Specific code analysis
		if code == 0x00:
			notes.append("Sets bit 0x80 in $00D0 to signal dialog end")
		
		elif code == 0x08:
			notes.append("Reads 16-bit pointer from dialog stream")
			notes.append("Executes nested dialog subroutine at that pointer")
			notes.append("CRITICAL: Used for reusable dialog fragments")
		
		elif code in range(0x10, 0x19):
			notes.append("Dynamic text insertion - reads index, looks up name in table")
		
		elif code == 0x1D or code == 0x1E:
			notes.append("Special formatting for dictionary entries 0x50/0x51")
			notes.append("Related to equipment name display formatting")
		
		return notes


def main():
	"""Main entry point."""
	import argparse
	
	parser = argparse.ArgumentParser(
		description="Extract disassembled control code handlers from assembly"
	)
	parser.add_argument(
		"--asm",
		help="Path to bank_00.asm file",
		default="src/asm/banks/bank_00.asm"
	)
	parser.add_argument(
		"--handlers",
		help="Path to control_code_handlers.txt",
		default="data/control_code_handlers.txt"
	)
	parser.add_argument(
		"--output",
		help="Path to output documentation",
		default="docs/HANDLER_DISASSEMBLY.md"
	)
	
	args = parser.parse_args()
	
	print("=" * 80)
	print("Control Code Handler Disassembly Extractor")
	print("=" * 80)
	
	# Create extractor
	extractor = HandlerDisassemblyExtractor(args.asm, args.handlers)
	
	# Load data
	extractor.load_handlers()
	extractor.load_assembly()
	extractor.build_label_map()
	
	# Generate documentation
	extractor.generate_documentation(args.output)
	
	print("\n" + "=" * 80)
	print("Extraction complete!")
	print("=" * 80)


if __name__ == "__main__":
	main()
