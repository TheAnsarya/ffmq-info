#!/usr/bin/env python3
"""
Dynamic Insertion Code Analyzer for Final Fantasy Mystic Quest
================================================================

Maps control codes 0x10-0x1E to their actual behavior by analyzing
usage patterns in extracted dialogs. These codes insert dynamic
content like stats, numbers, item names, etc.

Author: TheAnsarya
Date: 2025-11-12
License: MIT
"""

import json
import re
from collections import defaultdict
from pathlib import Path
from typing import Dict, List, Tuple, Optional


class DynamicCodeAnalyzer:
	"""Analyzes control codes 0x10-0x1E to identify what they insert."""
	
	def __init__(self, rom_path: str):
		"""
		Initialize the analyzer.
		
		Args:
			rom_path: Path to Final Fantasy Mystic Quest ROM file
		"""
		self.rom_path = Path(rom_path)
		self.dialogs: Dict[int, Dict] = {}
		self.code_contexts: Dict[int, List[Dict]] = defaultdict(list)
		self.code_stats: Dict[int, Dict] = {}
		
		# Map code IDs to descriptions (initial hypotheses)
		self.code_names = {
			0x10: "ITEM_NAME",
			0x11: "SPELL_NAME",
			0x12: "MONSTER_NAME",
			0x13: "CHARACTER_NAME",
			0x14: "LOCATION_NAME",
			0x15: "NUMBER_VALUE",
			0x16: "OBJECT_NAME",
			0x17: "WEAPON_NAME",
			0x18: "ARMOR_NAME",
			0x19: "ACCESSORY_NAME",
			0x1A: "POSITION_Y",
			0x1B: "POSITION_X",
			0x1C: "UNKNOWN_1C",
			0x1D: "UNKNOWN_1D",
			0x1E: "UNKNOWN_1E",
		}
	
	def load_extracted_dialogs(self, dialogs_path: Optional[str] = None) -> None:
		"""
		Load extracted dialog data from JSON file.
		
		Args:
			dialogs_path: Path to extracted dialogs JSON (optional)
		"""
		if dialogs_path is None:
			# Try default locations
			locations = [
				"data/extracted_dialogs.json",
				"data/all_dialogs.json",
				"extracted_dialogs.json",
			]
			
			for loc in locations:
				path = Path(loc)
				if path.exists():
					dialogs_path = str(path)
					break
		
		if dialogs_path is None:
			raise FileNotFoundError("No extracted dialogs JSON found")
		
		print(f"Loading dialogs from: {dialogs_path}")
		
		with open(dialogs_path, 'r', encoding='utf-8') as f:
			data = json.load(f)
		
		# Handle different JSON structures
		if isinstance(data, dict) and 'dialogs' in data:
			self.dialogs = {int(d['id']): d for d in data['dialogs']}
		elif isinstance(data, list):
			self.dialogs = {int(d['id']): d for d in data}
		else:
			self.dialogs = data
		
		print(f"Loaded {len(self.dialogs)} dialogs")
	
	def extract_code_contexts(self, context_chars: int = 40) -> None:
		"""
		Extract surrounding context for each control code occurrence.
		
		Args:
			context_chars: Number of characters before/after to capture
		"""
		print("\nExtracting code contexts...")
		
		target_codes = range(0x10, 0x1F)  # 0x10-0x1E
		
		for dialog_id, dialog in self.dialogs.items():
			text = dialog.get('decoded_text', '')
			raw_bytes = dialog.get('raw_bytes', [])
			
			# Find all control code occurrences in text
			for match in re.finditer(r'\[CMD:(1[0-9A-E])\]', text):
				code_hex = match.group(1)
				code_value = int(code_hex, 16)
				
				if code_value not in target_codes:
					continue
				
				# Extract context
				start_pos = match.start()
				end_pos = match.end()
				
				before = text[max(0, start_pos - context_chars):start_pos]
				code = match.group(0)
				after = text[end_pos:end_pos + context_chars]
				
				# Store context
				self.code_contexts[code_value].append({
					'dialog_id': dialog_id,
					'position': start_pos,
					'before': before,
					'code': code,
					'after': after,
					'full_context': before + code + after,
				})
		
		# Print summary
		for code in sorted(target_codes):
			count = len(self.code_contexts[code])
			if count > 0:
				print(f"  Code 0x{code:02X}: {count} occurrences")
	
	def analyze_patterns(self) -> None:
		"""Analyze patterns in code usage to identify what each code does."""
		print("\nAnalyzing patterns...")
		
		for code in range(0x10, 0x1F):
			contexts = self.code_contexts[code]
			
			if not contexts:
				continue
			
			# Analyze common patterns
			before_tokens = defaultdict(int)
			after_tokens = defaultdict(int)
			dialog_ids = set()
			
			for ctx in contexts:
				dialog_ids.add(ctx['dialog_id'])
				
				# Extract tokens before/after (last/first 20 chars)
				before = ctx['before'][-20:].strip()
				after = ctx['after'][:20].strip()
				
				if before:
					before_tokens[before] += 1
				if after:
					after_tokens[after] += 1
			
			# Store statistics
			self.code_stats[code] = {
				'count': len(contexts),
				'dialogs': sorted(dialog_ids),
				'dialog_count': len(dialog_ids),
				'common_before': sorted(before_tokens.items(), key=lambda x: x[1], reverse=True)[:5],
				'common_after': sorted(after_tokens.items(), key=lambda x: x[1], reverse=True)[:5],
			}
	
	def analyze_dictionary_codes(self) -> Dict[int, Dict]:
		"""
		Analyze codes 0x1D and 0x1E in dictionary entries 0x50 and 0x51.
		
		Returns:
			Dictionary analysis results
		"""
		print("\nAnalyzing dictionary entries 0x50 and 0x51...")
		
		# These patterns are known from CONTROL_CODES_ANALYSIS.md
		# Dictionary 0x50: 05 1D 9E 00 04 → [ITEM][CMD:1D]E[END][NAME]
		# Dictionary 0x51: 05 1E 9E 00 04 → [ITEM][CMD:1E]E[END][NAME]
		
		results = {
			0x50: {
				'raw_bytes': [0x05, 0x1D, 0x9E, 0x00, 0x04],
				'decoded': '[ITEM][CMD:1D]E[END][NAME]',
				'pattern': 'Insert item name → 0x1D operation → letter E → END → character name',
			},
			0x51: {
				'raw_bytes': [0x05, 0x1E, 0x9E, 0x00, 0x04],
				'decoded': '[ITEM][CMD:1E]E[END][NAME]',
				'pattern': 'Insert item name → 0x1E operation → letter E → END → character name',
			},
		}
		
		# Find dialogs that use dictionary entries 0x50 or 0x51
		for dialog_id, dialog in self.dialogs.items():
			raw_bytes = dialog.get('raw_bytes', [])
			
			if 0x50 in raw_bytes:
				results[0x50].setdefault('used_in_dialogs', []).append(dialog_id)
			if 0x51 in raw_bytes:
				results[0x51].setdefault('used_in_dialogs', []).append(dialog_id)
		
		return results
	
	def generate_report(self, output_path: str) -> None:
		"""
		Generate comprehensive analysis report.
		
		Args:
			output_path: Path to output report file
		"""
		print(f"\nGenerating report: {output_path}")
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("=" * 80 + "\n")
			f.write("Dynamic Insertion Code Analysis Report\n")
			f.write("Final Fantasy Mystic Quest - Control Codes 0x10-0x1E\n")
			f.write("=" * 80 + "\n\n")
			
			# Overview
			f.write("## Overview\n\n")
			f.write(f"Total dialogs analyzed: {len(self.dialogs)}\n")
			f.write(f"Codes analyzed: 0x10-0x1E (15 codes)\n\n")
			
			# Summary table
			f.write("## Code Frequency Summary\n\n")
			f.write("| Code | Name | Count | Dialogs | Coverage |\n")
			f.write("|------|------|-------|---------|----------|\n")
			
			for code in range(0x10, 0x1F):
				stats = self.code_stats.get(code, {})
				count = stats.get('count', 0)
				dialog_count = stats.get('dialog_count', 0)
				coverage = (dialog_count / len(self.dialogs) * 100) if self.dialogs else 0
				name = self.code_names.get(code, f"UNKNOWN_{code:02X}")
				
				f.write(f"| 0x{code:02X} | {name} | {count} | {dialog_count} | {coverage:.1f}% |\n")
			
			f.write("\n")
			
			# Detailed analysis for each code
			f.write("## Detailed Code Analysis\n\n")
			
			for code in range(0x10, 0x1F):
				contexts = self.code_contexts[code]
				
				if not contexts:
					continue
				
				stats = self.code_stats[code]
				name = self.code_names.get(code, f"UNKNOWN_{code:02X}")
				
				f.write("-" * 80 + "\n")
				f.write(f"### Code 0x{code:02X}: {name}\n\n")
				f.write(f"**Occurrences**: {stats['count']}\n")
				f.write(f"**Dialogs**: {stats['dialog_count']} ({', '.join(f'0x{d:02X}' for d in stats['dialogs'][:10])}...)\n\n")
				
				# Common patterns
				if stats['common_before']:
					f.write("**Common preceding text**:\n")
					for text, count in stats['common_before']:
						f.write(f"  - \"{text}\" ({count}x)\n")
					f.write("\n")
				
				if stats['common_after']:
					f.write("**Common following text**:\n")
					for text, count in stats['common_after']:
						f.write(f"  - \"{text}\" ({count}x)\n")
					f.write("\n")
				
				# Example contexts
				f.write("**Example contexts** (first 5):\n\n")
				for i, ctx in enumerate(contexts[:5], 1):
					f.write(f"{i}. Dialog 0x{ctx['dialog_id']:02X}:\n")
					f.write(f"   ```\n")
					f.write(f"   {ctx['full_context']}\n")
					f.write(f"   ```\n\n")
			
			# Dictionary analysis
			f.write("-" * 80 + "\n")
			f.write("## Dictionary Entry Analysis\n\n")
			
			dict_results = self.analyze_dictionary_codes()
			
			for entry_id, data in sorted(dict_results.items()):
				f.write(f"### Dictionary Entry 0x{entry_id:02X}\n\n")
				f.write(f"**Raw bytes**: {' '.join(f'{b:02X}' for b in data['raw_bytes'])}\n")
				f.write(f"**Decoded**: {data['decoded']}\n")
				f.write(f"**Pattern**: {data['pattern']}\n")
				
				if 'used_in_dialogs' in data:
					dialogs = data['used_in_dialogs']
					f.write(f"**Used in dialogs**: {len(dialogs)} ({', '.join(f'0x{d:02X}' for d in dialogs[:10])}...)\n")
				
				f.write("\n")
			
			# Hypotheses and conclusions
			f.write("-" * 80 + "\n")
			f.write("## Hypotheses and Conclusions\n\n")
			
			f.write("### Code 0x1D vs 0x1E\n\n")
			f.write("Both codes appear in similar dictionary patterns:\n")
			f.write("- 0x1D: Used in dictionary 0x50\n")
			f.write("- 0x1E: Used in dictionary 0x51\n")
			f.write("- Pattern: [ITEM][CMD:XX]E[END][NAME]\n\n")
			f.write("**Hypothesis**: These codes control item name display formatting.\n")
			f.write("The difference between 0x1D and 0x1E may be:\n")
			f.write("- Different text positioning (left vs right aligned)\n")
			f.write("- Different capitalization (lowercase 'e' vs uppercase 'E')\n")
			f.write("- Different grammatical context (possessive vs nominative)\n\n")
			
			f.write("### Codes 0x10-0x19\n\n")
			f.write("Pattern analysis suggests these insert dynamic content:\n")
			f.write("- 0x10: Item names (high frequency)\n")
			f.write("- 0x11: Spell names (moderate frequency)\n")
			f.write("- 0x12: Monster names (moderate frequency)\n")
			f.write("- 0x13: Character names (moderate frequency)\n")
			f.write("- 0x14: Location names (low frequency)\n")
			f.write("- 0x18: Armor names (moderate frequency)\n\n")
			
			f.write("### Next Steps\n\n")
			f.write("1. Create ROM test patches to validate hypotheses\n")
			f.write("2. Disassemble dialog rendering code at 009DC1-009DD2\n")
			f.write("3. Trace jump table for codes 0x10-0x1E\n")
			f.write("4. Document confirmed behaviors\n\n")
			
			f.write("=" * 80 + "\n")
			f.write("End of Report\n")
			f.write("=" * 80 + "\n")
		
		print(f"Report generated: {output_path}")
	
	def generate_context_samples(self, output_path: str, samples_per_code: int = 10) -> None:
		"""
		Generate file with context samples for manual review.
		
		Args:
			output_path: Path to output samples file
			samples_per_code: Number of samples to include per code
		"""
		print(f"\nGenerating context samples: {output_path}")
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("=" * 80 + "\n")
			f.write("Context Samples for Manual Review\n")
			f.write("=" * 80 + "\n\n")
			
			for code in range(0x10, 0x1F):
				contexts = self.code_contexts[code]
				
				if not contexts:
					continue
				
				name = self.code_names.get(code, f"UNKNOWN_{code:02X}")
				
				f.write(f"\n{'=' * 80}\n")
				f.write(f"Code 0x{code:02X}: {name} ({len(contexts)} total occurrences)\n")
				f.write(f"{'=' * 80}\n\n")
				
				for i, ctx in enumerate(contexts[:samples_per_code], 1):
					f.write(f"Sample {i}/{min(samples_per_code, len(contexts))}:\n")
					f.write(f"  Dialog: 0x{ctx['dialog_id']:02X}\n")
					f.write(f"  Position: {ctx['position']}\n")
					f.write(f"  Context:\n")
					f.write(f"    {ctx['full_context']}\n")
					f.write("\n")
		
		print(f"Context samples generated: {output_path}")


def main():
	"""Main entry point."""
	import argparse
	
	parser = argparse.ArgumentParser(
		description="Analyze dynamic insertion codes 0x10-0x1E in FFMQ dialogs"
	)
	parser.add_argument(
		"rom",
		help="Path to Final Fantasy Mystic Quest ROM file"
	)
	parser.add_argument(
		"--dialogs",
		help="Path to extracted dialogs JSON file (optional)",
		default=None
	)
	parser.add_argument(
		"--output",
		help="Path to output report file",
		default="data/dynamic_code_analysis.txt"
	)
	parser.add_argument(
		"--samples",
		help="Path to output context samples file",
		default="data/dynamic_code_samples.txt"
	)
	parser.add_argument(
		"--context-chars",
		help="Number of context characters before/after code",
		type=int,
		default=40
	)
	parser.add_argument(
		"--samples-per-code",
		help="Number of samples per code in samples file",
		type=int,
		default=10
	)
	
	args = parser.parse_args()
	
	print("=" * 80)
	print("Dynamic Insertion Code Analyzer")
	print("=" * 80)
	
	# Create analyzer
	analyzer = DynamicCodeAnalyzer(args.rom)
	
	# Load dialogs
	analyzer.load_extracted_dialogs(args.dialogs)
	
	# Extract contexts
	analyzer.extract_code_contexts(args.context_chars)
	
	# Analyze patterns
	analyzer.analyze_patterns()
	
	# Generate reports
	analyzer.generate_report(args.output)
	analyzer.generate_context_samples(args.samples, args.samples_per_code)
	
	print("\n" + "=" * 80)
	print("Analysis complete!")
	print("=" * 80)


if __name__ == "__main__":
	main()
