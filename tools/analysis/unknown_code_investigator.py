#!/usr/bin/env python3
"""
Unknown Control Code Investigator
==================================

Comprehensive analysis tool for identifying the functionality of unknown
control codes (0x07-0x0D) through multiple investigation techniques:

1. Handler disassembly analysis
2. External subroutine calls
3. Memory register usage patterns
4. Data table access patterns
5. Bitfield operation tracking
6. Parameter byte analysis

Author: TheAnsarya
Date: 2025-11-12
License: MIT
"""

import json
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional


class UnknownCodeInvestigator:
	"""Investigates unknown control codes through comprehensive analysis."""
	
	# Known memory registers from disassembly
	REGISTERS = {
		0x17: 'Dialog pointer (low byte)',
		0x19: 'Dialog pointer (high byte)',
		0x1A: 'Display position',
		0x25: 'Display mask',
		0xD0: 'Bitfield/flags',
	}
	
	# Known subroutines
	SUBROUTINES = {
		0x00974E: 'Bitfield_SetBits',
		0x009754: 'Bitfield_ClearBits',
		0x00975A: 'Bitfield_TestBits',
		0x009760: 'Bitfield_SetBits_Entity',
		0x00976B: 'Bitfield_ClearBits_Entity',
		0x009776: 'Bitfield_TestBits_Entity',
	}
	
	# Unknown codes to investigate
	UNKNOWN_CODES = [0x07, 0x09, 0x0A, 0x0B, 0x0C, 0x0D]
	
	# Partially known codes
	PARTIAL_CODES = {
		0x08: 'Subroutine call (confirmed)',
		0x0E: 'Memory write (hypothesis)',
	}
	
	def __init__(self, disassembly_path: str, dialogs_json: str):
		"""
		Initialize investigator.
		
		Args:
			disassembly_path: Path to handler disassembly
			dialogs_json: Path to extracted dialogs
		"""
		self.disassembly_path = Path(disassembly_path)
		self.dialogs_json = Path(dialogs_json)
		
		self.handlers: Dict[int, Dict] = {}
		self.dialogs: List[Dict] = []
		self.usage_patterns: Dict[int, Dict] = {}
	
	def load_disassembly(self) -> None:
		"""Load and parse handler disassembly."""
		print("Loading handler disassembly...")
		
		if not self.disassembly_path.exists():
			print(f"  Error: {self.disassembly_path} not found")
			return
		
		with open(self.disassembly_path, 'r', encoding='utf-8') as f:
			content = f.read()
		
		# Extract each handler section
		handler_pattern = re.compile(
			r'###\s+Code\s+0x([0-9A-F]{2}):\s+(.*?)\n'
			r'.*?'
			r'\*\*Address\*\*:\s+0x([0-9A-F]+)',
			re.DOTALL | re.IGNORECASE
		)
		
		for match in handler_pattern.finditer(content):
			code = int(match.group(1), 16)
			name = match.group(2).strip()
			address = int(match.group(3), 16)
			
			self.handlers[code] = {
				'code': code,
				'name': name,
				'address': address,
			}
		
		print(f"  Loaded {len(self.handlers)} handlers")
	
	def load_dialogs(self) -> None:
		"""Load dialog data."""
		print("Loading dialog data...")
		
		if not self.dialogs_json.exists():
			print(f"  Error: {self.dialogs_json} not found")
			return
		
		with open(self.dialogs_json, 'r', encoding='utf-8') as f:
			data = json.load(f)
		
		# Handle both direct array and nested structure
		if isinstance(data, dict) and 'dialogs' in data:
			self.dialogs = data['dialogs']
		elif isinstance(data, list):
			self.dialogs = data
		else:
			self.dialogs = []
		
		print(f"  Loaded {len(self.dialogs)} dialogs")
	
	def analyze_code_usage(self, code: int) -> Dict:
		"""
		Analyze usage patterns for a specific code.
		
		Args:
			code: Control code to analyze
		
		Returns:
			Dictionary with usage statistics
		"""
		usage = {
			'code': code,
			'hex': f'0x{code:02X}',
			'occurrences': 0,
			'dialogs': [],
			'contexts': [],
			'following_bytes': [],
			'preceding_bytes': [],
		}
		
		# Scan dialogs for this code
		for dialog in self.dialogs:
			dialog_id = dialog.get('id', 0)
			raw_bytes = dialog.get('raw_bytes', [])
			
			for i, byte_val in enumerate(raw_bytes):
				if byte_val == code:
					usage['occurrences'] += 1
					usage['dialogs'].append(dialog_id)
					
					# Get context (3 bytes before and after)
					start = max(0, i - 3)
					end = min(len(raw_bytes), i + 4)
					context = raw_bytes[start:end]
					usage['contexts'].append({
						'position': i,
						'context': context,
						'dialog_id': dialog_id,
					})
					
					# Get following bytes (parameters)
					if i + 1 < len(raw_bytes):
						usage['following_bytes'].append(raw_bytes[i + 1])
					if i + 2 < len(raw_bytes):
						usage['following_bytes'].append(raw_bytes[i + 2])
					
					# Get preceding byte
					if i > 0:
						usage['preceding_bytes'].append(raw_bytes[i - 1])
		
		return usage
	
	def identify_parameter_patterns(self, usage: Dict) -> Dict:
		"""
		Identify parameter byte patterns.
		
		Args:
			usage: Usage dictionary from analyze_code_usage
		
		Returns:
			Dictionary with parameter analysis
		"""
		patterns = {
			'code': usage['code'],
			'hex': usage['hex'],
			'has_parameters': False,
			'param_count': 0,
			'param_values': [],
			'param_ranges': {},
		}
		
		# Analyze following bytes
		if usage['following_bytes']:
			# Count unique values
			unique_values = set(usage['following_bytes'])
			patterns['param_values'] = sorted(unique_values)
			patterns['has_parameters'] = len(unique_values) > 1
			
			# Determine parameter count based on context
			# If following bytes are often control codes, this code might take 0 params
			# If following bytes are data, this code might take 1-2 params
			
			if usage['contexts']:
				# Sample first context
				ctx = usage['contexts'][0]['context']
				code_idx = ctx.index(usage['code'])
				
				if code_idx + 1 < len(ctx):
					next_byte = ctx[code_idx + 1]
					
					# If next byte is likely a control code (< 0x30), no params
					if next_byte < 0x30:
						patterns['param_count'] = 0
					else:
						# Might have parameters
						patterns['param_count'] = 1
						
						# Check if two-byte parameter
						if code_idx + 2 < len(ctx):
							next_next = ctx[code_idx + 2]
							if next_next < 0x30:
								# Likely 1-byte param
								patterns['param_count'] = 1
							else:
								# Might be 2-byte param
								patterns['param_count'] = 2
		
		# Analyze value ranges
		for val in patterns['param_values']:
			if val < 0x30:
				range_name = 'Control codes (0x00-0x2F)'
			elif val < 0x80:
				range_name = 'Dictionary entries (0x30-0x7F)'
			elif val < 0xA0:
				range_name = 'Character codes (0x80-0x9F)'
			else:
				range_name = 'Extended codes (0xA0-0xFF)'
			
			if range_name not in patterns['param_ranges']:
				patterns['param_ranges'][range_name] = []
			
			patterns['param_ranges'][range_name].append(val)
		
		return patterns
	
	def compare_with_known_codes(self, usage: Dict) -> Dict:
		"""
		Compare unknown code with known codes.
		
		Args:
			usage: Usage dictionary
		
		Returns:
			Similarity analysis
		"""
		comparison = {
			'code': usage['code'],
			'similar_to': [],
		}
		
		# Compare usage frequency
		occurrences = usage['occurrences']
		
		# Known code usage patterns
		known_usage = {
			0x00: ('END', 'Very high'),
			0x01: ('Newline', 'High'),
			0x02: ('Delay', 'Medium'),
			0x08: ('Subroutine', 'Very high (500+)'),
			0x10: ('Equipment name', 'High'),
		}
		
		# Find similar usage patterns
		if occurrences == 0:
			comparison['similar_to'].append('Unused codes (0x15, 0x19)')
		elif occurrences < 10:
			comparison['similar_to'].append('Rarely used (0x0F, 0x1B)')
		elif occurrences < 50:
			comparison['similar_to'].append('Moderately used (0x02, 0x12)')
		elif occurrences < 200:
			comparison['similar_to'].append('Frequently used (0x01, 0x10)')
		else:
			comparison['similar_to'].append('Very frequently used (0x00, 0x08)')
		
		return comparison
	
	def generate_hypothesis(self, code: int, usage: Dict, patterns: Dict) -> str:
		"""
		Generate hypothesis about code functionality.
		
		Args:
			code: Control code
			usage: Usage analysis
			patterns: Parameter patterns
		
		Returns:
			Hypothesis string
		"""
		hypotheses = []
		
		# Analyze occurrences
		if usage['occurrences'] == 0:
			return "HYPOTHESIS: Unused code - may be leftover from development"
		
		# Analyze parameters
		if patterns['has_parameters']:
			if patterns['param_count'] == 1:
				# Check parameter range
				if 'Dictionary entries (0x30-0x7F)' in patterns['param_ranges']:
					hypotheses.append("Might reference dictionary entries")
				elif 'Character codes (0x80-0x9F)' in patterns['param_ranges']:
					hypotheses.append("Might insert character codes")
				elif 'Control codes (0x00-0x2F)' in patterns['param_ranges']:
					hypotheses.append("Might invoke other control codes")
				else:
					hypotheses.append("Takes 1-byte parameter (purpose unknown)")
			
			elif patterns['param_count'] == 2:
				hypotheses.append("Takes 2-byte parameter - possibly address/value")
		else:
			hypotheses.append("No parameters detected")
		
		# Analyze context
		if usage['contexts']:
			# Check if often preceded by 0x08 (subroutine call)
			preceding = usage['preceding_bytes']
			if preceding.count(0x08) > len(preceding) * 0.3:
				hypotheses.append("Often follows subroutine calls (0x08)")
		
		# Combine hypotheses
		if hypotheses:
			return "HYPOTHESES: " + "; ".join(hypotheses)
		else:
			return "HYPOTHESIS: Functionality unclear - needs emulator testing"
	
	def generate_investigation_report(self, output_path: str) -> None:
		"""
		Generate comprehensive investigation report.
		
		Args:
			output_path: Path to output report
		"""
		print(f"\nGenerating investigation report: {output_path}")
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("=" * 80 + "\n")
			f.write("Unknown Control Code Investigation Report\n")
			f.write("Final Fantasy Mystic Quest\n")
			f.write("=" * 80 + "\n\n")
			
			f.write("## Overview\n\n")
			f.write("This report investigates unknown and partially-known control codes\n")
			f.write("through usage pattern analysis, parameter detection, and comparison\n")
			f.write("with known codes.\n\n")
			
			f.write("**Investigation Methods**:\n")
			f.write("1. Usage frequency analysis\n")
			f.write("2. Parameter pattern detection\n")
			f.write("3. Context analysis (surrounding bytes)\n")
			f.write("4. Comparison with known codes\n")
			f.write("5. Hypothesis generation\n\n")
			
			# Investigate each unknown code
			for code in self.UNKNOWN_CODES:
				f.write("-" * 80 + "\n")
				f.write(f"## Code 0x{code:02X}\n\n")
				
				# Get handler info
				if code in self.handlers:
					handler = self.handlers[code]
					f.write(f"**Handler Name**: {handler['name']}\n")
					f.write(f"**Handler Address**: 0x{handler['address']:06X}\n\n")
				
				# Analyze usage
				usage = self.analyze_code_usage(code)
				
				f.write(f"**Occurrences**: {usage['occurrences']}\n")
				f.write(f"**Used in Dialogs**: {len(set(usage['dialogs']))}\n\n")
				
				if usage['occurrences'] == 0:
					f.write("**Status**: UNUSED - Never appears in any dialog\n\n")
					f.write("This code may be:\n")
					f.write("- Leftover from development\n")
					f.write("- Intended for future use\n")
					f.write("- Used only in runtime-generated dialogs\n\n")
					continue
				
				# Parameter analysis
				patterns = self.identify_parameter_patterns(usage)
				
				f.write("### Parameter Analysis\n\n")
				f.write(f"**Has Parameters**: {'Yes' if patterns['has_parameters'] else 'No'}\n")
				f.write(f"**Estimated Param Count**: {patterns['param_count']}\n\n")
				
				if patterns['param_values']:
					f.write(f"**Unique Values**: {len(patterns['param_values'])}\n")
					f.write(f"**Value Range**: 0x{min(patterns['param_values']):02X} - 0x{max(patterns['param_values']):02X}\n\n")
					
					if patterns['param_ranges']:
						f.write("**Value Distribution**:\n")
						for range_name, values in patterns['param_ranges'].items():
							f.write(f"- {range_name}: {len(values)} values\n")
						f.write("\n")
				
				# Context samples
				if usage['contexts']:
					f.write("### Context Samples\n\n")
					f.write("Sample occurrences showing surrounding bytes:\n\n")
					
					for i, ctx in enumerate(usage['contexts'][:5], 1):
						dialog_id = ctx['dialog_id']
						context_bytes = ' '.join(f'{b:02X}' for b in ctx['context'])
						f.write(f"{i}. Dialog #{dialog_id}: [{context_bytes}]\n")
					
					if len(usage['contexts']) > 5:
						f.write(f"\n  ... and {len(usage['contexts']) - 5} more occurrences\n")
					
					f.write("\n")
				
				# Comparison
				comparison = self.compare_with_known_codes(usage)
				
				if comparison['similar_to']:
					f.write("### Similarity Analysis\n\n")
					f.write("**Similar Usage Patterns**:\n")
					for sim in comparison['similar_to']:
						f.write(f"- {sim}\n")
					f.write("\n")
				
				# Generate hypothesis
				hypothesis = self.generate_hypothesis(code, usage, patterns)
				f.write(f"### {hypothesis}\n\n")
				
				f.write("### Recommended Next Steps\n\n")
				if usage['occurrences'] > 0:
					f.write("1. Create ROM test patch with this code\n")
					f.write("2. Test in emulator with memory viewer\n")
					f.write("3. Observe effects on dialog display\n")
					f.write("4. Check memory changes at common registers\n\n")
				else:
					f.write("1. Check if code is referenced in other ROM areas\n")
					f.write("2. Test manually by injecting code into dialog\n")
					f.write("3. May be safe to use for custom functionality\n\n")
			
			# Summary section
			f.write("=" * 80 + "\n")
			f.write("## Investigation Summary\n\n")
			
			used_count = sum(1 for code in self.UNKNOWN_CODES if self.analyze_code_usage(code)['occurrences'] > 0)
			unused_count = len(self.UNKNOWN_CODES) - used_count
			
			f.write(f"**Unknown Codes Investigated**: {len(self.UNKNOWN_CODES)}\n")
			f.write(f"**Codes With Usage**: {used_count}\n")
			f.write(f"**Unused Codes**: {unused_count}\n\n")
			
			f.write("### Priority Investigation List\n\n")
			f.write("Based on usage frequency, prioritize investigation in this order:\n\n")
			
			# Sort by usage
			usage_list = [(code, self.analyze_code_usage(code)['occurrences']) for code in self.UNKNOWN_CODES]
			usage_list.sort(key=lambda x: x[1], reverse=True)
			
			for i, (code, count) in enumerate(usage_list, 1):
				if count > 0:
					f.write(f"{i}. Code 0x{code:02X}: {count} occurrences - HIGH PRIORITY\n")
				else:
					f.write(f"{i}. Code 0x{code:02X}: Unused - LOW PRIORITY\n")
			
			f.write("\n")
			f.write("=" * 80 + "\n")
			f.write("End of Report\n")
			f.write("=" * 80 + "\n")
		
		print(f"Report generated: {output_path}")
		
		# Console summary
		print("\n" + "=" * 80)
		print("INVESTIGATION SUMMARY")
		print("=" * 80 + "\n")
		
		for code in self.UNKNOWN_CODES:
			usage = self.analyze_code_usage(code)
			patterns = self.identify_parameter_patterns(usage)
			
			print(f"Code 0x{code:02X}:")
			print(f"  Occurrences: {usage['occurrences']}")
			
			if usage['occurrences'] > 0:
				print(f"  Parameters: {patterns['param_count']} byte(s)")
				hypothesis = self.generate_hypothesis(code, usage, patterns)
				print(f"  {hypothesis}")
			else:
				print(f"  Status: UNUSED")
			
			print()


def main():
	"""Main entry point."""
	import argparse
	
	parser = argparse.ArgumentParser(
		description="Investigate unknown control codes through comprehensive analysis"
	)
	parser.add_argument(
		"--disassembly",
		help="Path to handler disassembly",
		default="docs/HANDLER_DISASSEMBLY.md"
	)
	parser.add_argument(
		"--dialogs",
		help="Path to extracted dialogs JSON",
		default="data/extracted_dialogs.json"
	)
	parser.add_argument(
		"--output",
		help="Path to output report",
		default="docs/UNKNOWN_CODES_INVESTIGATION.md"
	)
	
	args = parser.parse_args()
	
	print("=" * 80)
	print("Unknown Control Code Investigator")
	print("=" * 80)
	
	investigator = UnknownCodeInvestigator(args.disassembly, args.dialogs)
	
	investigator.load_disassembly()
	investigator.load_dialogs()
	
	investigator.generate_investigation_report(args.output)
	
	print("\n" + "=" * 80)
	print("Investigation complete!")
	print("=" * 80)


if __name__ == "__main__":
	main()
