#!/usr/bin/env python3
"""
External Subroutine Analyzer
=============================

Analyzes external subroutine calls (JSL instructions) from control code
handlers to identify what operations are performed by unknown codes.

This tool helps reverse engineer unknown control codes by:
1. Extracting JSL target addresses from handlers
2. Disassembling subroutine code
3. Analyzing register usage and operations
4. Identifying data table accesses
5. Determining subroutine purpose

Author: TheAnsarya
Date: 2025-11-12
License: MIT
"""

import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional


class SubroutineAnalyzer:
	"""Analyzes external subroutines called by control code handlers."""
	
	# SNES 65816 instruction set patterns
	INSTRUCTIONS = {
		# Load/Store
		'LDA': r'(A[D9F5]|B[D9F]|AD|BD|AF|BF)',
		'LDX': r'(A[E26]|B[E6]|AE|BE)',
		'LDY': r'(A[C04]|B[C4]|AC|BC)',
		'STA': r'(8[D9F5]|9[D9F]|8D|9D|8F|9F)',
		'STX': r'(8[E6]|9[E6]|8E)',
		'STY': r'(8[C4]|9[C4]|8C)',
		'STZ': r'(64|74|9C|9E)',
		
		# Arithmetic
		'ADC': r'(6[D9F5]|7[D9F]|6D|7D|6F|7F)',
		'SBC': r'(E[D9F5]|F[D9F]|ED|FD|EF|FF)',
		'INC': r'(E6|F6|EE|FE|1A)',
		'DEC': r'(C6|D6|CE|DE|3A)',
		'INX': r'E8',
		'INY': r'C8',
		'DEX': r'CA',
		'DEY': r'88',
		
		# Logic
		'AND': r'(2[D9F5]|3[D9F]|2D|3D|2F|3F)',
		'ORA': r'(0[D9F5]|1[D9F]|0D|1D|0F|1F)',
		'EOR': r'(4[D9F5]|5[D9F]|4D|5D|4F|5F)',
		'BIT': r'(24|2C|89)',
		
		# Shifts
		'ASL': r'(0[A6]|1[6E]|0E)',
		'LSR': r'(4[A6]|5[6E]|4E)',
		'ROL': r'(2[A6]|3[6E]|2E)',
		'ROR': r'(6[A6]|7[6E]|6E)',
		
		# Branches
		'BCC': r'90',
		'BCS': r'B0',
		'BEQ': r'F0',
		'BMI': r'30',
		'BNE': r'D0',
		'BPL': r'10',
		'BRA': r'80',
		'BRL': r'82',
		'BVC': r'50',
		'BVS': r'70',
		
		# Jumps/Calls
		'JMP': r'(4C|5C|6C|DC)',
		'JSR': r'20',
		'JSL': r'22',
		'RTS': r'60',
		'RTL': r'6B',
		'RTI': r'40',
		
		# Stack
		'PHA': r'48',
		'PLA': r'68',
		'PHX': r'DA',
		'PLX': r'FA',
		'PHY': r'5A',
		'PLY': r'7A',
		'PHB': r'8B',
		'PLB': r'AB',
		'PHD': r'0B',
		'PLD': r'2B',
		'PHK': r'4B',
		
		# Transfers
		'TAX': r'AA',
		'TAY': r'A8',
		'TXA': r'8A',
		'TYA': r'98',
		'TSX': r'BA',
		'TXS': r'9A',
		'TCD': r'5B',
		'TDC': r'7B',
		'TCS': r'1B',
		'TSC': r'3B',
		'TXY': r'9B',
		'TYX': r'BB',
		
		# Flags
		'CLC': r'18',
		'SEC': r'38',
		'CLI': r'58',
		'SEI': r'78',
		'CLV': r'B8',
		'CLD': r'D8',
		'SED': r'F8',
		'REP': r'C2',
		'SEP': r'E2',
		'XBA': r'EB',
		'XCE': r'FB',
		
		# Misc
		'NOP': r'EA',
		'WDM': r'42',
		'STP': r'DB',
		'WAI': r'CB',
		'CMP': r'(C[D9F5]|D[D9F]|CD|DD|CF|DF)',
		'CPX': r'(E[04C]|EC)',
		'CPY': r'(C[04C]|CC)',
		'MVN': r'54',
		'MVP': r'44',
		'PEA': r'F4',
		'PEI': r'D4',
		'PER': r'62',
	}
	
	def __init__(self, rom_path: str, disassembly_log: str):
		"""
		Initialize analyzer.
		
		Args:
			rom_path: Path to ROM file
			disassembly_log: Path to disassembly log
		"""
		self.rom_path = Path(rom_path)
		self.disassembly_log = Path(disassembly_log)
		
		self.rom_data: Optional[bytes] = None
		self.subroutines: Dict[int, Dict] = {}
		self.handlers: Dict[int, Dict] = {}
	
	def load_rom(self) -> None:
		"""Load ROM file into memory."""
		print(f"Loading ROM: {self.rom_path}")
		
		with open(self.rom_path, 'rb') as f:
			self.rom_data = f.read()
		
		print(f"  ROM size: {len(self.rom_data):,} bytes")
	
	def extract_jsl_calls(self, log_file: Optional[str] = None) -> Dict[int, List[int]]:
		"""
		Extract JSL call targets from disassembly log.
		
		Args:
			log_file: Optional specific log file to parse
		
		Returns:
			Dictionary mapping handler code to list of JSL targets
		"""
		log_path = Path(log_file) if log_file else self.disassembly_log
		
		print(f"Extracting JSL calls from: {log_path}")
		
		jsl_calls = {}
		current_handler = None
		
		# Pattern for handler start
		# Format: ### Code 0x01: Dialog_Newline
		handler_pattern = re.compile(r'###\s+Code\s+0x([0-9A-F]{2}):', re.IGNORECASE)
		
		# Pattern for JSL instruction
		# Format: jsl.L Bitfield_TestBits                    ;00A76C|225A9700|00975A;
		# The third hex value (00975A) is the target address
		jsl_pattern = re.compile(r'jsl\.L.*?\|22([0-9A-F]{6})\|([0-9A-F]{6});')
		
		if not log_path.exists():
			print(f"  Warning: Log file not found: {log_path}")
			return jsl_calls
		
		with open(log_path, 'r', encoding='utf-8') as f:
			for line in f:
				# Check for handler start
				handler_match = handler_pattern.search(line)
				if handler_match:
					current_handler = int(handler_match.group(1), 16)
					continue
				
				# Check for JSL call
				if current_handler is not None:
					jsl_match = jsl_pattern.search(line)
					if jsl_match:
						# Use the third hex value as the target (actual subroutine address)
						target = int(jsl_match.group(2), 16)
						
						if current_handler not in jsl_calls:
							jsl_calls[current_handler] = []
						
						jsl_calls[current_handler].append(target)
		
		print(f"  Found JSL calls in {len(jsl_calls)} handlers")
		
		return jsl_calls
	
	def snes_to_pc(self, snes_addr: int) -> int:
		"""
		Convert SNES address to PC (ROM file) address.
		
		For LoROM mapping (FFMQ uses LoROM):
		Bank 00-7D: $8000-$FFFF -> PC = (bank * 0x8000) + (addr - 0x8000)
		Bank 80-FF: Mirror of 00-7F
		
		Args:
			snes_addr: 24-bit SNES address (0xBANKADDR)
		
		Returns:
			PC address in ROM file
		"""
		bank = (snes_addr >> 16) & 0xFF
		addr = snes_addr & 0xFFFF
		
		# Handle mirrored banks
		if bank >= 0x80:
			bank -= 0x80
		
		# LoROM mapping
		if bank <= 0x7D and addr >= 0x8000:
			pc_addr = (bank * 0x8000) + (addr - 0x8000)
			return pc_addr
		else:
			# Invalid or special address
			return -1
	
	def disassemble_subroutine(self, snes_addr: int, max_bytes: int = 256) -> List[Dict]:
		"""
		Disassemble subroutine at given address.
		
		Args:
			snes_addr: SNES address of subroutine
			max_bytes: Maximum bytes to disassemble
		
		Returns:
			List of disassembled instructions
		"""
		if self.rom_data is None:
			return []
		
		pc_addr = self.snes_to_pc(snes_addr)
		
		if pc_addr < 0 or pc_addr >= len(self.rom_data):
			return []
		
		instructions = []
		offset = 0
		
		while offset < max_bytes:
			if pc_addr + offset >= len(self.rom_data):
				break
			
			opcode = self.rom_data[pc_addr + offset]
			
			# Try to decode instruction
			instr = self.decode_instruction(pc_addr + offset, opcode)
			
			if instr:
				instructions.append(instr)
				offset += instr['length']
				
				# Stop at RTL or RTS
				if instr['mnemonic'] in ['RTL', 'RTS']:
					break
			else:
				# Unknown instruction, stop
				break
		
		return instructions
	
	def decode_instruction(self, pc_addr: int, opcode: int) -> Optional[Dict]:
		"""
		Decode single instruction.
		
		Args:
			pc_addr: PC address of instruction
			opcode: Opcode byte
		
		Returns:
			Dictionary with instruction info or None
		"""
		if self.rom_data is None:
			return None
		
		# Simple instruction length table (not complete, but covers common cases)
		# Format: opcode -> (mnemonic, length)
		instr_table = {
			0x60: ('RTS', 1),
			0x6B: ('RTL', 1),
			0x22: ('JSL', 4),
			0x20: ('JSR', 3),
			0xA9: ('LDA', 3),  # LDA #imm16
			0xAD: ('LDA', 3),  # LDA abs
			0xBD: ('LDA', 3),  # LDA abs,X
			0xB9: ('LDA', 3),  # LDA abs,Y
			0xAF: ('LDA', 4),  # LDA long
			0xBF: ('LDA', 4),  # LDA long,X
			0x8D: ('STA', 3),  # STA abs
			0x9D: ('STA', 3),  # STA abs,X
			0x99: ('STA', 3),  # STA abs,Y
			0x8F: ('STA', 4),  # STA long
			0x9F: ('STA', 4),  # STA long,X
			0xC2: ('REP', 2),  # REP #imm
			0xE2: ('SEP', 2),  # SEP #imm
			0x5C: ('JMP', 4),  # JMP long
			0x4C: ('JMP', 3),  # JMP abs
			0xF0: ('BEQ', 2),  # BEQ rel
			0xD0: ('BNE', 2),  # BNE rel
			0x90: ('BCC', 2),  # BCC rel
			0xB0: ('BCS', 2),  # BCS rel
			0x80: ('BRA', 2),  # BRA rel
			0x48: ('PHA', 1),
			0x68: ('PLA', 1),
			0xDA: ('PHX', 1),
			0xFA: ('PLX', 1),
			0x5A: ('PHY', 1),
			0x7A: ('PLY', 1),
			0x8B: ('PHB', 1),
			0xAB: ('PLB', 1),
			0xAA: ('TAX', 1),
			0xA8: ('TAY', 1),
			0x8A: ('TXA', 1),
			0x98: ('TYA', 1),
			0xE8: ('INX', 1),
			0xC8: ('INY', 1),
			0xCA: ('DEX', 1),
			0x88: ('DEY', 1),
			0x1A: ('INC', 1),  # INC A
			0x3A: ('DEC', 1),  # DEC A
			0xEA: ('NOP', 1),
		}
		
		if opcode in instr_table:
			mnemonic, length = instr_table[opcode]
			
			# Read operand bytes
			operand_bytes = []
			for i in range(1, length):
				if pc_addr + i < len(self.rom_data):
					operand_bytes.append(self.rom_data[pc_addr + i])
			
			# Format operand
			if length == 1:
				operand = ''
			elif length == 2:
				operand = f'#${operand_bytes[0]:02X}'
			elif length == 3:
				addr = operand_bytes[0] | (operand_bytes[1] << 8)
				operand = f'${addr:04X}'
			elif length == 4:
				addr = operand_bytes[0] | (operand_bytes[1] << 8) | (operand_bytes[2] << 16)
				operand = f'${addr:06X}'
			else:
				operand = ''
			
			return {
				'pc_addr': pc_addr,
				'opcode': opcode,
				'mnemonic': mnemonic,
				'operand': operand,
				'length': length,
				'bytes': [opcode] + operand_bytes,
			}
		else:
			# Unknown opcode - return minimal info
			return {
				'pc_addr': pc_addr,
				'opcode': opcode,
				'mnemonic': '???',
				'operand': '',
				'length': 1,
				'bytes': [opcode],
			}
	
	def analyze_subroutine(self, snes_addr: int) -> Dict:
		"""
		Analyze subroutine to determine its purpose.
		
		Args:
			snes_addr: SNES address of subroutine
		
		Returns:
			Analysis results dictionary
		"""
		instructions = self.disassemble_subroutine(snes_addr)
		
		analysis = {
			'address': snes_addr,
			'hex': f'${snes_addr:06X}',
			'instruction_count': len(instructions),
			'total_bytes': sum(i['length'] for i in instructions),
			'uses_accumulator': False,
			'uses_x_register': False,
			'uses_y_register': False,
			'has_branches': False,
			'has_calls': False,
			'loads_from_memory': [],
			'stores_to_memory': [],
			'called_subroutines': [],
			'instructions': instructions,
		}
		
		for instr in instructions:
			mnemonic = instr['mnemonic']
			
			# Check register usage
			if mnemonic in ['LDA', 'STA', 'ADC', 'SBC', 'CMP', 'INC', 'DEC']:
				analysis['uses_accumulator'] = True
			
			if mnemonic in ['LDX', 'STX', 'INX', 'DEX', 'CPX']:
				analysis['uses_x_register'] = True
			
			if mnemonic in ['LDY', 'STY', 'INY', 'DEY', 'CPY']:
				analysis['uses_y_register'] = True
			
			# Check for branches
			if mnemonic in ['BEQ', 'BNE', 'BCC', 'BCS', 'BRA', 'BMI', 'BPL', 'BVC', 'BVS']:
				analysis['has_branches'] = True
			
			# Check for calls
			if mnemonic in ['JSL', 'JSR']:
				analysis['has_calls'] = True
				if instr['operand']:
					analysis['called_subroutines'].append(instr['operand'])
			
			# Track memory accesses
			if mnemonic.startswith('LD') and '$' in instr['operand']:
				analysis['loads_from_memory'].append(instr['operand'])
			
			if mnemonic.startswith('ST') and '$' in instr['operand']:
				analysis['stores_to_memory'].append(instr['operand'])
		
		return analysis
	
	def generate_report(self, output_path: str) -> None:
		"""
		Generate comprehensive subroutine analysis report.
		
		Args:
			output_path: Path to output report
		"""
		print(f"\nGenerating subroutine analysis report: {output_path}")
		
		# Extract JSL calls from disassembly
		jsl_calls = self.extract_jsl_calls()
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("=" * 80 + "\n")
			f.write("External Subroutine Analysis Report\n")
			f.write("Final Fantasy Mystic Quest - Control Code Handlers\n")
			f.write("=" * 80 + "\n\n")
			
			f.write("## Overview\n\n")
			f.write("This report analyzes external subroutines (JSL calls) used by\n")
			f.write("control code handlers to help identify unknown code functionality.\n\n")
			
			# Process each handler with JSL calls
			for code, targets in sorted(jsl_calls.items()):
				f.write("-" * 80 + "\n")
				f.write(f"## Handler 0x{code:02X}\n\n")
				
				f.write(f"**JSL Calls**: {len(targets)}\n\n")
				
				for target in targets:
					f.write(f"### Subroutine ${target:06X}\n\n")
					
					# Analyze subroutine
					analysis = self.analyze_subroutine(target)
					
					f.write(f"**PC Address**: ${self.snes_to_pc(target):06X}\n")
					f.write(f"**Instructions**: {analysis['instruction_count']}\n")
					f.write(f"**Total Bytes**: {analysis['total_bytes']}\n\n")
					
					f.write("**Register Usage**:\n")
					if analysis['uses_accumulator']:
						f.write("- Uses Accumulator (A)\n")
					if analysis['uses_x_register']:
						f.write("- Uses X Register\n")
					if analysis['uses_y_register']:
						f.write("- Uses Y Register\n")
					f.write("\n")
					
					if analysis['loads_from_memory']:
						f.write("**Loads From Memory**:\n")
						for addr in set(analysis['loads_from_memory']):
							f.write(f"- {addr}\n")
						f.write("\n")
					
					if analysis['stores_to_memory']:
						f.write("**Stores To Memory**:\n")
						for addr in set(analysis['stores_to_memory']):
							f.write(f"- {addr}\n")
						f.write("\n")
					
					if analysis['called_subroutines']:
						f.write("**Calls Other Subroutines**:\n")
						for addr in analysis['called_subroutines']:
							f.write(f"- {addr}\n")
						f.write("\n")
					
					# Show disassembly
					f.write("**Disassembly**:\n```\n")
					for instr in analysis['instructions']:
						pc = instr['pc_addr']
						opcode = ' '.join(f'{b:02X}' for b in instr['bytes'])
						mnemonic = instr['mnemonic']
						operand = instr['operand']
						
						f.write(f"${pc:06X}: {opcode:12} {mnemonic:6} {operand}\n")
					f.write("```\n\n")
			
			f.write("=" * 80 + "\n")
			f.write("End of Report\n")
			f.write("=" * 80 + "\n")
		
		print(f"Report generated: {output_path}")


def main():
	"""Main entry point."""
	import argparse
	
	parser = argparse.ArgumentParser(
		description="Analyze external subroutines called by control code handlers"
	)
	parser.add_argument(
		"--rom",
		help="Path to ROM file",
		default="roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"
	)
	parser.add_argument(
		"--log",
		help="Path to disassembly log",
		default="docs/HANDLER_DISASSEMBLY.md"
	)
	parser.add_argument(
		"--output",
		help="Path to output report",
		default="docs/SUBROUTINE_ANALYSIS.md"
	)
	
	args = parser.parse_args()
	
	print("=" * 80)
	print("External Subroutine Analyzer")
	print("=" * 80)
	
	analyzer = SubroutineAnalyzer(args.rom, args.log)
	
	analyzer.load_rom()
	analyzer.generate_report(args.output)
	
	print("\n" + "=" * 80)
	print("Analysis complete!")
	print("=" * 80)


if __name__ == "__main__":
	main()
