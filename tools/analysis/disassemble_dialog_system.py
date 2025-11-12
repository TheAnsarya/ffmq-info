#!/usr/bin/env python3
"""
Dialog System Disassembly Analyzer for Final Fantasy Mystic Quest
===================================================================

Analyzes the dialog rendering system at 009DC1-009DD2 and maps all
48 control code handlers (0x00-0x2F) using the jump table at 009E0E.

Author: TheAnsarya
Date: 2025-11-12
License: MIT
"""

import struct
from pathlib import Path
from typing import Dict, List, Tuple, Optional


class DialogDisassemblyAnalyzer:
	"""Analyzes dialog rendering system and control code handlers."""
	
	def __init__(self, rom_path: str, asm_path: Optional[str] = None):
		"""
		Initialize the analyzer.
		
		Args:
			rom_path: Path to Final Fantasy Mystic Quest ROM file
			asm_path: Optional path to bank_00.asm file for cross-reference
		"""
		self.rom_path = Path(rom_path)
		self.asm_path = Path(asm_path) if asm_path else None
		self.rom = b''
		
		# Key addresses (SNES addressing)
		self.DIALOG_READ_BYTE_SNES = 0x009DBD
		self.DIALOG_WRITE_CHAR_SNES = 0x009DC9
		self.DIALOG_PROCESS_CMD_SNES = 0x009DD2
		self.JUMP_TABLE_SNES = 0x009E0E
		
		# Convert to ROM offsets (LoROM: PC = (SNES & 0x7FFF) + ((SNES >> 16) * 0x8000))
		self.JUMP_TABLE_ROM = 0x001E0E  # Bank 00: 0x009E0E -> PC 0x001E0E
		
		# Control code handlers
		self.handlers: Dict[int, Dict] = {}
		self.handler_addresses: List[Tuple[int, int]] = []  # (code, address)
		
		# Known control codes (from our analysis)
		self.code_names = {
			0x00: "END",
			0x01: "NEWLINE",
			0x02: "WAIT",
			0x03: "ASTERISK / PORTRAIT",
			0x04: "NAME",
			0x05: "ITEM",
			0x06: "SPACE",
			0x07: "UNKNOWN_07",
			0x08: "UNKNOWN_08 (CRITICAL - 500+ uses)",
			0x09: "UNKNOWN_09",
			0x0A: "UNKNOWN_0A",
			0x0B: "UNKNOWN_0B",
			0x0C: "UNKNOWN_0C",
			0x0D: "UNKNOWN_0D",
			0x0E: "UNKNOWN_0E (FREQUENT - 100+ uses)",
			0x0F: "UNKNOWN_0F",
			0x10: "INSERT_ITEM_NAME",
			0x11: "INSERT_SPELL_NAME",
			0x12: "INSERT_MONSTER_NAME",
			0x13: "INSERT_CHARACTER_NAME",
			0x14: "INSERT_LOCATION_NAME",
			0x15: "INSERT_NUMBER? (UNUSED)",
			0x16: "INSERT_OBJECT_NAME",
			0x17: "INSERT_WEAPON_NAME",
			0x18: "INSERT_ARMOR_NAME",
			0x19: "INSERT_ACCESSORY? (UNUSED)",
			0x1A: "TEXTBOX_BELOW",
			0x1B: "TEXTBOX_ABOVE",
			0x1C: "UNKNOWN_1C",
			0x1D: "FORMAT_ITEM_E1",
			0x1E: "FORMAT_ITEM_E2",
			0x1F: "CRYSTAL",
			0x20: "UNKNOWN_20",
			0x21: "UNKNOWN_21",
			0x22: "UNKNOWN_22",
			0x23: "UNKNOWN_23",
			0x24: "UNKNOWN_24",
			0x25: "UNKNOWN_25",
			0x26: "UNKNOWN_26",
			0x27: "UNKNOWN_27",
			0x28: "UNKNOWN_28",
			0x29: "UNKNOWN_29",
			0x2A: "UNKNOWN_2A",
			0x2B: "UNKNOWN_2B",
			0x2C: "UNKNOWN_2C",
			0x2D: "UNKNOWN_2D",
			0x2E: "UNKNOWN_2E",
			0x2F: "UNKNOWN_2F",
		}
	
	def load_rom(self) -> None:
		"""Load ROM file."""
		self.rom = self.rom_path.read_bytes()
		print(f"Loaded ROM: {self.rom_path.name} ({len(self.rom)} bytes)")
	
	def snes_to_pc(self, snes_addr: int) -> int:
		"""
		Convert SNES address to PC (ROM file) address.
		LoROM formula: PC = (SNES & 0x7FFF) + ((SNES >> 16) * 0x8000)
		
		Args:
			snes_addr: SNES address (24-bit)
		
		Returns:
			PC address in ROM file
		"""
		bank = (snes_addr >> 16) & 0xFF
		offset = snes_addr & 0xFFFF
		
		if offset >= 0x8000:
			# LoROM: High half of bank
			pc = ((bank * 0x8000) + (offset - 0x8000))
		else:
			# Low half (unusual for code)
			pc = ((bank * 0x8000) + offset)
		
		return pc
	
	def pc_to_snes(self, pc_addr: int) -> int:
		"""
		Convert PC (ROM file) address to SNES address.
		
		Args:
			pc_addr: PC address in ROM file
		
		Returns:
			SNES address (24-bit)
		"""
		bank = pc_addr // 0x8000
		offset = pc_addr % 0x8000
		snes = (bank << 16) | (offset + 0x8000)
		return snes
	
	def read_jump_table(self) -> None:
		"""Read the control code jump table at 009E0E."""
		print("\nReading control code jump table at 009E0E...")
		
		# Jump table has 48 entries (0x00-0x2F)
		# Each entry is 2 bytes (16-bit address)
		for code in range(0x30):
			offset = self.JUMP_TABLE_ROM + (code * 2)
			
			if offset + 1 >= len(self.rom):
				print(f"  Warning: Jump table extends beyond ROM (code 0x{code:02X})")
				break
			
			# Read 16-bit little-endian address
			addr_low = self.rom[offset]
			addr_high = self.rom[offset + 1]
			handler_addr = addr_low | (addr_high << 8)
			
			# Convert to full SNES address (bank 00)
			handler_snes = 0x00_0000 | handler_addr
			
			self.handler_addresses.append((code, handler_snes))
			
			# Store handler info
			self.handlers[code] = {
				'address': handler_snes,
				'address_hex': f'0x{handler_snes:06X}',
				'name': self.code_names.get(code, f'UNKNOWN_{code:02X}'),
				'rom_offset': self.snes_to_pc(handler_snes),
			}
		
		print(f"  Read {len(self.handlers)} handler addresses")
	
	def analyze_handler_code(self, code: int, max_bytes: int = 50) -> str:
		"""
		Analyze handler code and extract first few instructions.
		
		Args:
			code: Control code (0x00-0x2F)
			max_bytes: Maximum bytes to read
		
		Returns:
			Hex dump of handler code
		"""
		if code not in self.handlers:
			return "Handler not found"
		
		rom_offset = self.handlers[code]['rom_offset']
		
		if rom_offset + max_bytes > len(self.rom):
			max_bytes = len(self.rom) - rom_offset
		
		code_bytes = self.rom[rom_offset:rom_offset + max_bytes]
		
		# Format as hex dump
		hex_dump = ' '.join(f'{b:02X}' for b in code_bytes[:20])
		if max_bytes > 20:
			hex_dump += '...'
		
		return hex_dump
	
	def identify_handler_patterns(self) -> Dict[str, List[int]]:
		"""
		Identify patterns in handler addresses to group related codes.
		
		Returns:
			Dictionary of patterns with list of codes
		"""
		patterns = {
			'shared_handlers': [],  # Codes sharing same handler
			'sequential': [],  # Handlers in sequential memory
			'null_handlers': [],  # Codes with 0x0000 handler
		}
		
		# Track handler addresses we've seen
		seen_addresses = {}
		
		for code in range(0x30):
			if code not in self.handlers:
				continue
			
			addr = self.handlers[code]['address']
			
			# Check for null handler
			if addr == 0x0000:
				patterns['null_handlers'].append(code)
			
			# Check for shared handlers
			if addr in seen_addresses:
				if addr not in [h['address'] for c, h in self.handlers.items() 
				               if c in patterns['shared_handlers']]:
					patterns['shared_handlers'].append(seen_addresses[addr])
				patterns['shared_handlers'].append(code)
			else:
				seen_addresses[addr] = code
		
		# Check for sequential handlers
		sorted_handlers = sorted(self.handler_addresses, key=lambda x: x[1])
		for i in range(len(sorted_handlers) - 1):
			code1, addr1 = sorted_handlers[i]
			code2, addr2 = sorted_handlers[i + 1]
			
			# If addresses are close (< 32 bytes apart)
			if 0 < (addr2 - addr1) < 32:
				if code1 not in patterns['sequential']:
					patterns['sequential'].append(code1)
				if code2 not in patterns['sequential']:
					patterns['sequential'].append(code2)
		
		return patterns
	
	def generate_report(self, output_path: str) -> None:
		"""
		Generate comprehensive disassembly report.
		
		Args:
			output_path: Path to output report file
		"""
		print(f"\nGenerating disassembly report: {output_path}")
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("=" * 80 + "\n")
			f.write("Dialog System Disassembly Analysis\n")
			f.write("Final Fantasy Mystic Quest - Control Code Handlers\n")
			f.write("=" * 80 + "\n\n")
			
			# Overview
			f.write("## Overview\n\n")
			f.write("**Dialog Rendering System**:\n")
			f.write(f"- Dialog_ReadNextByte: 0x{self.DIALOG_READ_BYTE_SNES:06X}\n")
			f.write(f"- Dialog_WriteCharacter: 0x{self.DIALOG_WRITE_CHAR_SNES:06X}\n")
			f.write(f"- Dialog_ProcessCommand: 0x{self.DIALOG_PROCESS_CMD_SNES:06X}\n")
			f.write(f"- Jump Table: 0x{self.JUMP_TABLE_SNES:06X} (ROM 0x{self.JUMP_TABLE_ROM:06X})\n\n")
			
			f.write("**Control Code Range**: 0x00-0x2F (48 codes total)\n\n")
			
			# Jump table overview
			f.write("## Jump Table Map\n\n")
			f.write("| Code | Name | Handler Address | ROM Offset | First Bytes |\n")
			f.write("|------|------|-----------------|------------|-------------|\n")
			
			for code in range(0x30):
				if code not in self.handlers:
					f.write(f"| 0x{code:02X} | MISSING | N/A | N/A | N/A |\n")
					continue
				
				handler = self.handlers[code]
				name = handler['name']
				addr = handler['address_hex']
				rom_offset = f"0x{handler['rom_offset']:06X}"
				first_bytes = self.analyze_handler_code(code, 12)
				
				f.write(f"| 0x{code:02X} | {name} | {addr} | {rom_offset} | {first_bytes} |\n")
			
			f.write("\n")
			
			# Pattern analysis
			f.write("## Handler Patterns\n\n")
			patterns = self.identify_handler_patterns()
			
			f.write("### Null Handlers (0x0000)\n\n")
			if patterns['null_handlers']:
				f.write("Codes with null/placeholder handlers:\n")
				for code in patterns['null_handlers']:
					name = self.handlers[code]['name']
					f.write(f"  - 0x{code:02X}: {name}\n")
				f.write("\n")
			else:
				f.write("No null handlers found.\n\n")
			
			f.write("### Shared Handlers\n\n")
			if patterns['shared_handlers']:
				# Group by address
				addr_groups = {}
				for code in patterns['shared_handlers']:
					addr = self.handlers[code]['address']
					if addr not in addr_groups:
						addr_groups[addr] = []
					addr_groups[addr].append(code)
				
				f.write("Codes sharing the same handler:\n")
				for addr, codes in sorted(addr_groups.items()):
					if len(codes) > 1:
						codes_str = ', '.join(f'0x{c:02X}' for c in codes)
						f.write(f"  - Handler 0x{addr:06X}: {codes_str}\n")
				f.write("\n")
			else:
				f.write("No shared handlers found.\n\n")
			
			f.write("### Sequential Handlers\n\n")
			if patterns['sequential']:
				f.write("Codes with handlers in sequential memory (likely related):\n")
				sequential_str = ', '.join(f'0x{c:02X}' for c in sorted(patterns['sequential']))
				f.write(f"  {sequential_str}\n\n")
			else:
				f.write("No sequential handler patterns found.\n\n")
			
			# Detailed handler analysis
			f.write("-" * 80 + "\n")
			f.write("## Detailed Handler Analysis\n\n")
			
			# Group by tier (from our dynamic code analysis)
			tiers = {
				'Basic Control Codes (0x00-0x06)': range(0x00, 0x07),
				'Unknown Display Codes (0x07-0x0F)': range(0x07, 0x10),
				'Dynamic Insertion Codes (0x10-0x1F)': range(0x10, 0x20),
				'Advanced Codes (0x20-0x2F)': range(0x20, 0x30),
			}
			
			for tier_name, code_range in tiers.items():
				f.write(f"### {tier_name}\n\n")
				
				for code in code_range:
					if code not in self.handlers:
						continue
					
					handler = self.handlers[code]
					name = handler['name']
					addr = handler['address_hex']
					rom_offset = handler['rom_offset']
					
					f.write(f"**Code 0x{code:02X}: {name}**\n")
					f.write(f"- Handler Address: {addr}\n")
					f.write(f"- ROM Offset: 0x{rom_offset:06X}\n")
					
					# Add usage data from our analysis
					usage_notes = self.get_usage_notes(code)
					if usage_notes:
						f.write(f"- Usage: {usage_notes}\n")
					
					# Hex dump
					hex_dump = self.analyze_handler_code(code, 50)
					f.write(f"- Code: {hex_dump}\n")
					
					f.write("\n")
			
			# Assembly code reference
			f.write("-" * 80 + "\n")
			f.write("## Assembly Code Reference\n\n")
			
			f.write("### Dialog_ReadNextByte (0x009DBD)\n")
			f.write("```asm\n")
			f.write("Dialog_ReadNextByte:\n")
			f.write("    lda.B [$17]         ; Read byte from dialog pointer\n")
			f.write("    inc.B $17           ; Increment pointer\n")
			f.write("    and.W #$00FF        ; Mask to 8-bit\n")
			f.write("    cmp.W #$0080        ; Compare to 0x80\n")
			f.write("    bcc ProcessCommand  ; < 0x80 → control code or dictionary\n")
			f.write("```\n\n")
			
			f.write("### Dialog_WriteCharacter (0x009DC9)\n")
			f.write("```asm\n")
			f.write("Dialog_WriteCharacter:\n")
			f.write("    eor.B $1D           ; XOR with font table selector?\n")
			f.write("    sta.B [$1A]         ; Store to output buffer\n")
			f.write("    inc.B $1A           ; Increment buffer pointer (x2)\n")
			f.write("    inc.B $1A\n")
			f.write("    rts\n")
			f.write("```\n\n")
			
			f.write("### Dialog_ProcessCommand (0x009DD2)\n")
			f.write("```asm\n")
			f.write("Dialog_ProcessCommand:\n")
			f.write("    cmp.W #$0030        ; Compare to 0x30\n")
			f.write("    bcs TextReference   ; >= 0x30 → dictionary entry\n")
			f.write("    asl                 ; Multiply by 2 (word size)\n")
			f.write("    tax                 ; Use as index\n")
			f.write("    jsr.W (JumpTable,x) ; Jump to handler via table\n")
			f.write("    rep #$30            ; Return to 16-bit mode\n")
			f.write("    rts\n")
			f.write("```\n\n")
			
			# Next steps
			f.write("-" * 80 + "\n")
			f.write("## Next Steps\n\n")
			
			f.write("### Priority 1: Disassemble High-Use Handlers\n")
			f.write("1. **Code 0x08** (500+ uses) - CRITICAL\n")
			f.write("2. **Code 0x0E** (100+ uses) - Frequent\n")
			f.write("3. **Codes 0x10-0x1E** (Dynamic insertion)\n\n")
			
			f.write("### Priority 2: Validate Hypotheses\n")
			f.write("1. Test codes 0x1D vs 0x1E behavior\n")
			f.write("2. Verify equipment slot detection (0x10 vs 0x17 vs 0x18)\n")
			f.write("3. Identify table references in handler code\n\n")
			
			f.write("### Priority 3: Document All Handlers\n")
			f.write("1. Create detailed disassembly for each handler\n")
			f.write("2. Identify subroutines called by handlers\n")
			f.write("3. Map data tables used by handlers\n\n")
			
			f.write("=" * 80 + "\n")
			f.write("End of Report\n")
			f.write("=" * 80 + "\n")
		
		print(f"Report generated: {output_path}")
	
	def get_usage_notes(self, code: int) -> str:
		"""
		Get usage notes for a code based on our dynamic analysis.
		
		Args:
			code: Control code (0x00-0x2F)
		
		Returns:
			Usage notes string
		"""
		usage_data = {
			0x00: "117 uses (100% coverage) - Text terminator",
			0x01: "153 uses (37.6% coverage) - Line break",
			0x02: "36 uses (14.5% coverage) - Wait for input",
			0x03: "23 uses (14.5% coverage) - Portrait/NPC ID",
			0x04: "6 uses (5.1% coverage) - Character name",
			0x05: "74 uses (44.4% coverage) - Item insertion",
			0x06: "16 uses (11.1% coverage) - Space character",
			0x08: "28 uses (17.1% coverage) - CRITICAL UNKNOWN",
			0x09: "32 uses (15.4% coverage) - Unknown",
			0x0E: "9 uses (7.7% coverage) - Frequent unknown",
			0x10: "55 uses (30.8% coverage) - Item name insertion",
			0x11: "27 uses (12.8% coverage) - Spell name insertion",
			0x12: "19 uses (13.7% coverage) - Monster name insertion",
			0x13: "17 uses (14.5% coverage) - Character name insertion",
			0x14: "8 uses (6.8% coverage) - Location name insertion",
			0x16: "12 uses (6.0% coverage) - Object name insertion",
			0x17: "1 use (0.9% coverage) - Weapon name insertion",
			0x18: "20 uses (15.4% coverage) - Armor name insertion",
			0x1A: "24 uses (18.8% coverage) - Textbox below",
			0x1B: "7 uses (6.0% coverage) - Textbox above",
			0x1C: "3 uses (2.6% coverage) - Unknown",
			0x1D: "25 uses (17.9% coverage) - Format item E1 (dict 0x50)",
			0x1E: "10 uses (8.5% coverage) - Format item E2 (dict 0x51)",
			0x1F: "2 uses (0.9% coverage) - Crystal reference",
		}
		
		return usage_data.get(code, "Unknown usage")
	
	def generate_handler_list(self, output_path: str) -> None:
		"""
		Generate simple handler address list for quick reference.
		
		Args:
			output_path: Path to output file
		"""
		print(f"\nGenerating handler list: {output_path}")
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("# Control Code Handler Addresses\n\n")
			f.write("```\n")
			
			for code in range(0x30):
				if code not in self.handlers:
					f.write(f"0x{code:02X}: MISSING\n")
					continue
				
				handler = self.handlers[code]
				name = handler['name'].ljust(35)
				addr = handler['address_hex']
				
				f.write(f"0x{code:02X}: {name} → {addr}\n")
			
			f.write("```\n")
		
		print(f"Handler list generated: {output_path}")


def main():
	"""Main entry point."""
	import argparse
	
	parser = argparse.ArgumentParser(
		description="Analyze dialog system disassembly and control code handlers"
	)
	parser.add_argument(
		"rom",
		help="Path to Final Fantasy Mystic Quest ROM file"
	)
	parser.add_argument(
		"--asm",
		help="Path to bank_00.asm file (optional)",
		default=None
	)
	parser.add_argument(
		"--report",
		help="Path to output detailed report",
		default="docs/DIALOG_DISASSEMBLY.md"
	)
	parser.add_argument(
		"--handlers",
		help="Path to output handler list",
		default="data/control_code_handlers.txt"
	)
	
	args = parser.parse_args()
	
	print("=" * 80)
	print("Dialog System Disassembly Analyzer")
	print("=" * 80)
	
	# Create analyzer
	analyzer = DialogDisassemblyAnalyzer(args.rom, args.asm)
	
	# Load ROM
	analyzer.load_rom()
	
	# Read jump table
	analyzer.read_jump_table()
	
	# Generate reports
	analyzer.generate_report(args.report)
	analyzer.generate_handler_list(args.handlers)
	
	print("\n" + "=" * 80)
	print("Analysis complete!")
	print("=" * 80)


if __name__ == "__main__":
	main()
