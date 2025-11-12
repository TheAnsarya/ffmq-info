#!/usr/bin/env python3
"""
Deep Control Code Analysis - Count codes in dictionary entries too.
This provides a more accurate picture by counting control codes both:
1. Directly in dialog text
2. Inside dictionary entries that get expanded

Author: FFMQ Disassembly Project
Date: 2025-11-12
"""

import sys
from pathlib import Path
from collections import Counter, defaultdict

sys.path.insert(0, str(Path(__file__).parent.parent / 'extraction'))
from extract_all_dialogs import DialogExtractor


class DeepControlCodeAnalyzer:
	"""Analyzes control code usage including dictionary expansion."""
	
	def __init__(self, rom_path: str, table_path: str = 'complex.tbl'):
		self.rom_path = rom_path
		self.table_path = table_path
		self.extractor = DialogExtractor(rom_path)
		
		# Raw counts (in compressed dialog data)
		self.raw_code_counts = Counter()
		self.raw_dialogs_with_code = defaultdict(set)
		
		# Expanded counts (after dictionary expansion)
		self.expanded_code_counts = Counter()
		self.expanded_dialogs_with_code = defaultdict(set)
		
	def analyze(self):
		"""Run complete analysis."""
		print(f"{'='*80}")
		print(f"DEEP CONTROL CODE ANALYSIS (with Dictionary Expansion)")
		print(f"{'='*80}\n")
		
		# Load ROM and data
		self.extractor.load_rom()
		self.extractor.load_char_table(self.table_path)
		self.extractor.load_dictionary()
		
		print("Analyzing control codes in 117 dialogs (raw + expanded)...\n")
		
		for i in range(117):
			decoded_text, raw_bytes = self.extractor.extract_dialog(i)
			self.analyze_dialog_raw(i, raw_bytes)
			self.analyze_dialog_expanded(i, decoded_text)
		
		# Display comparison
		self.display_comparison()
	
	def analyze_dialog_raw(self, dialog_id: int, raw_bytes: bytes):
		"""Analyze raw dialog bytes (compressed)."""
		for byte in raw_bytes:
			if byte <= 0x1F:  # Control code
				self.raw_code_counts[byte] += 1
				self.raw_dialogs_with_code[byte].add(dialog_id)
	
	def analyze_dialog_expanded(self, dialog_id: int, decoded_text: str):
		"""Analyze decoded text (after dictionary expansion)."""
		# Count control code markers in decoded text
		import re
		
		# Match [CMD:XX] patterns
		for match in re.finditer(r'\[CMD:([0-9A-F]{2})\]', decoded_text):
			code = int(match.group(1), 16)
			self.expanded_code_counts[code] += 1
			self.expanded_dialogs_with_code[code].add(dialog_id)
		
		# Count other control markers
		if '[END]' in decoded_text:
			self.expanded_code_counts[0x00] += decoded_text.count('[END]')
			self.expanded_dialogs_with_code[0x00].add(dialog_id)
		
		if '\n' in decoded_text:
			self.expanded_code_counts[0x01] += decoded_text.count('\n')
			self.expanded_dialogs_with_code[0x01].add(dialog_id)
		
		if '[WAIT]' in decoded_text:
			self.expanded_code_counts[0x02] += decoded_text.count('[WAIT]')
			self.expanded_dialogs_with_code[0x02].add(dialog_id)
		
		if '[ASTERISK]' in decoded_text:
			self.expanded_code_counts[0x03] += decoded_text.count('[ASTERISK]')
			self.expanded_dialogs_with_code[0x03].add(dialog_id)
		
		if '[NAME]' in decoded_text:
			self.expanded_code_counts[0x04] += decoded_text.count('[NAME]')
			self.expanded_dialogs_with_code[0x04].add(dialog_id)
		
		if '[ITEM]' in decoded_text:
			self.expanded_code_counts[0x05] += decoded_text.count('[ITEM]')
			self.expanded_dialogs_with_code[0x05].add(dialog_id)
		
		if '[TEXTBOX_BELOW]' in decoded_text:
			self.expanded_code_counts[0x1A] += decoded_text.count('[TEXTBOX_BELOW]')
			self.expanded_dialogs_with_code[0x1A].add(dialog_id)
		
		if '[TEXTBOX_ABOVE]' in decoded_text:
			self.expanded_code_counts[0x1B] += decoded_text.count('[TEXTBOX_ABOVE]')
			self.expanded_dialogs_with_code[0x1B].add(dialog_id)
		
		if '[CRYSTAL]' in decoded_text:
			self.expanded_code_counts[0x1F] += decoded_text.count('[CRYSTAL]')
			self.expanded_dialogs_with_code[0x1F].add(dialog_id)
	
	def display_comparison(self):
		"""Display raw vs expanded counts."""
		print(f"{'='*80}")
		print(f"RAW vs EXPANDED CONTROL CODE COUNTS")
		print(f"{'='*80}\n")
		print(f"{'Code':<6} {'Raw':<8} {'Expanded':<10} {'Multiplier':<12} {'Description'}")
		print(f"{'-'*80}")
		
		all_codes = set(self.raw_code_counts.keys()) | set(self.expanded_code_counts.keys())
		
		for code in sorted(all_codes):
			raw_count = self.raw_code_counts.get(code, 0)
			exp_count = self.expanded_code_counts.get(code, 0)
			
			if raw_count > 0:
				multiplier = exp_count / raw_count
			else:
				multiplier = exp_count if exp_count > 0 else 0
			
			desc = self._get_desc(code)
			
			# Highlight critical amplification
			prefix = '🔥' if multiplier > 10 else ''
			prefix = '⚡' if 5 <= multiplier <= 10 else prefix
			prefix = '✅' if multiplier > 0 else prefix
			
			if exp_count > 0:
				print(f"{prefix}0x{code:02X}  {raw_count:6}   {exp_count:8}   {multiplier:8.1f}x    {desc}")
		
		print(f"\n{'='*80}")
		print(f"KEY FINDINGS")
		print(f"{'='*80}\n")
		
		# Find codes with highest amplification
		amplified = []
		dict_only = []
		for code in all_codes:
			raw = self.raw_code_counts.get(code, 0)
			exp = self.expanded_code_counts.get(code, 0)
			if raw > 0:
				amp = exp / raw
				if amp > 5:
					amplified.append((code, raw, exp, amp))
			elif exp > 0:  # Only in dictionary
				dict_only.append((code, exp))
		
		if amplified:
			amplified.sort(key=lambda x: x[3], reverse=True)
			print("Codes with high dictionary amplification (>5x):")
			print(f"{'Code':<6} {'Raw':<8} {'Expanded':<10} {'Amplification':<15} {'Description'}")
			print(f"{'-'*80}")
			for code, raw, exp, amp in amplified:
				desc = self._get_desc(code)
				print(f"0x{code:02X}  {raw:6}   {exp:8}   {amp:8.1f}x         {desc}")
			
			print(f"\n💡 These codes appear frequently in dictionary entries!")
			print(f"   This explains why they seem less common in raw dialog data.")
		
		if dict_only:
			dict_only.sort(key=lambda x: x[1], reverse=True)
			print("\n🔍 Codes that ONLY exist in dictionary entries (never in raw dialogs):")
			print(f"{'Code':<6} {'Expanded Count':<15} {'Description'}")
			print(f"{'-'*80}")
			for code, exp in dict_only:
				desc = self._get_desc(code)
				print(f"0x{code:02X}  {exp:8}           {desc}")
			
			print(f"\n⚠️  These {len(dict_only)} codes are ONLY referenced via dictionary!")
			print(f"   This suggests they're part of common text patterns.")

		
		# Calculate total codes
		total_raw = sum(self.raw_code_counts.values())
		total_exp = sum(self.expanded_code_counts.values())
		
		print(f"\nTotal Control Codes:")
		print(f"  Raw (compressed):  {total_raw:,}")
		print(f"  Expanded (decoded): {total_exp:,}")
		print(f"  Overall amplification: {total_exp / total_raw:.2f}x")
	
	def _get_desc(self, code: int) -> str:
		"""Get description for a code."""
		descs = {
			0x00: 'End of text',
			0x01: 'Newline',
			0x02: 'Pause/Wait',
			0x03: 'Portrait',
			0x04: 'Speed 0',
			0x05: 'Speed 1',
			0x06: 'Speed 2',
			0x08: 'CRITICAL Unknown',
			0x0E: 'Frequent Unknown',
			0x10: 'Dynamic insertion?',
			0x1A: 'Position Y',
			0x1B: 'Position X',
			0x1F: 'Crystal',
		}
		return descs.get(code, f'Unknown 0x{code:02X}')


def main():
	"""Main entry point."""
	rom_path = sys.argv[1] if len(sys.argv) > 1 else r'roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc'
	
	analyzer = DeepControlCodeAnalyzer(rom_path)
	analyzer.analyze()
	
	print(f"\n{'='*80}")
	print(f"✅ DEEP ANALYSIS COMPLETE")
	print(f"{'='*80}")
	
	return 0


if __name__ == '__main__':
	sys.exit(main())
