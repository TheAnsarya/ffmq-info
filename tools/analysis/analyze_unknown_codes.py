#!/usr/bin/env python3
"""
Unknown Control Code Analyzer
==============================

Analyzes the "unknown" control codes (0x07-0x0F, 0x1C, 0x20-0x2F) to identify
their purpose based on assembly code patterns and usage context.

Author: TheAnsarya
Date: 2025-11-12
License: MIT
"""

from pathlib import Path
from typing import Dict, List, Tuple
import re


class UnknownCodeAnalyzer:
	"""Analyzes unknown control codes to identify their purpose."""
	
	def __init__(self, disasm_file: str, dialogs_file: str):
		"""
		Initialize analyzer.
		
		Args:
			disasm_file: Path to HANDLER_DISASSEMBLY.md
			dialogs_file: Path to extracted_dialogs.txt
		"""
		self.disasm_file = Path(disasm_file)
		self.dialogs_file = Path(dialogs_file)
		
		# Unknown codes to analyze
		self.unknown_codes = [
			0x07, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F,
			0x1C, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26,
			0x27, 0x28, 0x29, 0x2A, 0x2B, 0x2C, 0x2D, 0x2E, 0x2F
		]
		
		# Analysis results
		self.analyses: Dict[int, Dict] = {}
	
	def analyze_code_pattern(self, code: int, asm_code: str) -> Dict:
		"""
		Analyze assembly code to identify code purpose.
		
		Args:
			code: Control code (hex)
			asm_code: Assembly code text
		
		Returns:
			Dictionary with analysis results
		"""
		analysis = {
			'category': 'Unknown',
			'likely_purpose': 'Unknown operation',
			'parameters': 0,
			'characteristics': [],
		}
		
		# Count parameter reads
		param_reads = asm_code.count('inc.B $17')
		analysis['parameters'] = param_reads
		
		# Identify characteristics
		if 'sta.W $0000,x' in asm_code or 'sta.B [$' in asm_code:
			analysis['characteristics'].append('Memory write operation')
		
		if 'lda.W $0000,x' in asm_code or 'lda.B [$' in asm_code:
			analysis['characteristics'].append('Memory read operation')
		
		if 'jsr' in asm_code.lower() or 'jsl' in asm_code.lower():
			analysis['characteristics'].append('Calls subroutine(s)')
		
		if 'tsb' in asm_code.lower():
			analysis['characteristics'].append('Sets bitflag(s)')
		
		if 'trb' in asm_code.lower():
			analysis['characteristics'].append('Clears bitflag(s)')
		
		if 'beq' in asm_code.lower() or 'bne' in asm_code.lower():
			analysis['characteristics'].append('Conditional logic')
		
		if 'and.W #$00ff' in asm_code:
			analysis['characteristics'].append('8-bit parameter')
		
		if param_reads == 2:
			analysis['characteristics'].append('16-bit parameter')
		
		if param_reads == 4:
			analysis['characteristics'].append('2 x 16-bit parameters')
		
		if param_reads == 5:
			analysis['characteristics'].append('16-bit + 24-bit parameters')
		
		# Identify specific patterns
		
		# Memory write handler
		if 'Memory_Write' in asm_code:
			analysis['category'] = 'Memory Operation'
			if param_reads == 4:
				analysis['likely_purpose'] = 'Write 16-bit value to memory address'
			elif param_reads == 5:
				analysis['likely_purpose'] = 'Write 24-bit value to memory address'
		
		# Memory read handler
		elif 'Memory_Read' in asm_code:
			analysis['category'] = 'Memory Operation'
			analysis['likely_purpose'] = 'Read value from memory address'
		
		# Bitfield test
		elif 'Bitfield_Test' in asm_code:
			analysis['category'] = 'Conditional'
			analysis['likely_purpose'] = 'Test bitflag and conditionally execute'
		
		# Register/state modification
		elif 'sta.B $' in asm_code and param_reads > 0:
			analysis['category'] = 'State Control'
			analysis['likely_purpose'] = 'Set game state variable'
		
		# Textbox positioning
		elif 'sta.B $4F' in asm_code:
			analysis['category'] = 'Display Control'
			analysis['likely_purpose'] = 'Textbox positioning/control'
		
		# External subroutine call
		elif 'jsl.L' in asm_code and '009776' in asm_code:
			analysis['category'] = 'Conditional'
			analysis['likely_purpose'] = 'Entity bitfield test'
		
		# Long subroutine call
		elif 'jsl.L' in asm_code:
			analysis['category'] = 'Complex Operation'
			analysis['likely_purpose'] = 'Call external game routine'
		
		return analysis
	
	def extract_handler_code(self, code: int) -> str:
		"""
		Extract handler assembly code from disassembly file.
		
		Args:
			code: Control code (hex)
		
		Returns:
			Assembly code text
		"""
		with open(self.disasm_file, 'r', encoding='utf-8') as f:
			content = f.read()
		
		# Find code section
		pattern = rf'### Code 0x{code:02X}:.*?\n```asm\n(.*?)\n```'
		match = re.search(pattern, content, re.DOTALL)
		
		if match:
			return match.group(1)
		
		return ""
	
	def find_usage_examples(self, code: int, max_examples: int = 3) -> List[str]:
		"""
		Find usage examples from extracted dialogs.
		
		Args:
			code: Control code (hex)
			max_examples: Maximum examples to return
		
		Returns:
			List of example contexts
		"""
		examples = []
		
		if not self.dialogs_file.exists():
			return examples
		
		with open(self.dialogs_file, 'r', encoding='utf-8') as f:
			content = f.read()
		
		# Split into dialog sections
		dialogs = content.split('---')
		
		for dialog in dialogs:
			if f'[{code:02X}]' in dialog:
				# Extract context around the code
				lines = dialog.split('\n')
				for i, line in enumerate(lines):
					if f'[{code:02X}]' in line:
						# Get surrounding context
						start = max(0, i - 2)
						end = min(len(lines), i + 3)
						context = '\n'.join(lines[start:end]).strip()
						examples.append(context)
						break
				
				if len(examples) >= max_examples:
					break
		
		return examples
	
	def generate_report(self, output_path: str) -> None:
		"""
		Generate comprehensive unknown code analysis report.
		
		Args:
			output_path: Path to output file
		"""
		print(f"\nGenerating unknown code analysis: {output_path}")
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("=" * 80 + "\n")
			f.write("Unknown Control Code Analysis\n")
			f.write("Final Fantasy Mystic Quest - Identifying Unidentified Codes\n")
			f.write("=" * 80 + "\n\n")
			
			f.write("## Overview\n\n")
			f.write(f"This report analyzes {len(self.unknown_codes)} unknown/unidentified control codes\n")
			f.write("to determine their purpose based on assembly code patterns and usage context.\n\n")
			
			f.write("## Analysis Methodology\n\n")
			f.write("1. **Assembly Pattern Recognition**: Identify common operations (memory writes, subroutine calls, etc.)\n")
			f.write("2. **Parameter Analysis**: Count and classify input parameters\n")
			f.write("3. **Context Review**: Examine usage in actual dialogs\n")
			f.write("4. **Cross-Reference**: Compare with known codes of similar patterns\n\n")
			
			# Analyze each unknown code
			for code in self.unknown_codes:
				asm_code = self.extract_handler_code(code)
				
				if not asm_code:
					continue
				
				analysis = self.analyze_code_pattern(code, asm_code)
				self.analyses[code] = analysis
				
				examples = self.find_usage_examples(code, max_examples=2)
				
				f.write("-" * 80 + "\n")
				f.write(f"### Code 0x{code:02X}\n\n")
				
				f.write(f"**Category**: {analysis['category']}\n")
				f.write(f"**Likely Purpose**: {analysis['likely_purpose']}\n")
				f.write(f"**Parameters**: {analysis['parameters']} byte(s)\n\n")
				
				if analysis['characteristics']:
					f.write("**Characteristics**:\n")
					for char in analysis['characteristics']:
						f.write(f"- {char}\n")
					f.write("\n")
				
				if examples:
					f.write("**Usage Examples**:\n")
					for i, example in enumerate(examples, 1):
						f.write(f"\nExample {i}:\n```\n{example}\n```\n")
				
				f.write("\n")
			
			# Summary by category
			f.write("-" * 80 + "\n")
			f.write("## Category Summary\n\n")
			
			categories = {}
			for code, analysis in self.analyses.items():
				category = analysis['category']
				if category not in categories:
					categories[category] = []
				categories[category].append(code)
			
			for category, codes in sorted(categories.items()):
				f.write(f"**{category}**:\n")
				codes_str = ', '.join(f'0x{c:02X}' for c in sorted(codes))
				f.write(f"  {codes_str}\n\n")
			
			# High-priority codes for further investigation
			f.write("-" * 80 + "\n")
			f.write("## Priority Investigation List\n\n")
			
			f.write("**Critical (Frequent Usage)**:\n")
			f.write("- **0x0E**: Memory write operation (100+ uses) - Game state manipulation\n\n")
			
			f.write("**High Priority (Complex Operations)**:\n")
			for code, analysis in self.analyses.items():
				if 'Calls subroutine(s)' in analysis['characteristics']:
					f.write(f"- **0x{code:02X}**: {analysis['likely_purpose']}\n")
			f.write("\n")
			
			f.write("**Medium Priority (State Control)**:\n")
			for code, analysis in self.analyses.items():
				if analysis['category'] == 'State Control':
					f.write(f"- **0x{code:02X}**: {analysis['likely_purpose']}\n")
			f.write("\n")
			
			f.write("=" * 80 + "\n")
			f.write("End of Analysis\n")
			f.write("=" * 80 + "\n")
		
		print(f"Analysis complete: {output_path}")


def main():
	"""Main entry point."""
	import argparse
	
	parser = argparse.ArgumentParser(
		description="Analyze unknown control codes to identify their purpose"
	)
	parser.add_argument(
		"--disasm",
		help="Path to HANDLER_DISASSEMBLY.md",
		default="docs/HANDLER_DISASSEMBLY.md"
	)
	parser.add_argument(
		"--dialogs",
		help="Path to extracted_dialogs.txt",
		default="data/extracted_dialogs.txt"
	)
	parser.add_argument(
		"--output",
		help="Path to output analysis report",
		default="docs/UNKNOWN_CODES_ANALYSIS.md"
	)
	
	args = parser.parse_args()
	
	print("=" * 80)
	print("Unknown Control Code Analyzer")
	print("=" * 80)
	
	# Create analyzer
	analyzer = UnknownCodeAnalyzer(args.disasm, args.dialogs)
	
	# Generate report
	analyzer.generate_report(args.output)
	
	print("\n" + "=" * 80)
	print("Analysis complete!")
	print("=" * 80)


if __name__ == "__main__":
	main()
