#!/usr/bin/env python3
"""
FFMQ Control Code Frequency Analyzer
Analyzes control code usage patterns across all 117 dialogs.

This helps identify:
- Which control codes are critical (high frequency)
- Which codes need disassembly priority (unknown + frequent)
- Position-specific patterns (code placement in dialogs)

Author: FFMQ Disassembly Project
Date: 2025-11-12
"""

import sys
from pathlib import Path
from collections import Counter, defaultdict
from typing import Dict, List, Tuple, Set

# Import dialog extractor
sys.path.insert(0, str(Path(__file__).parent.parent / 'extraction'))
from extract_all_dialogs import DialogExtractor


class ControlCodeAnalyzer:
	"""Analyzes control code usage patterns."""
	
	# Control code classifications
	CONFIRMED = {
		0x00: 'End of text / Null terminator',
		0x01: 'Newline',
		0x02: 'Pause / Wait for input',
		0x03: 'Portrait command / NPC ID',
		0x04: 'Speed 0 (instant)',
		0x05: 'Speed 1 (fast)',
		0x06: 'Speed 2 (normal)',
		0x1A: 'Position Y (vertical positioning)',
		0x1B: 'Position X (horizontal positioning)',
		0x1F: 'Crystal (battle item reference)',
	}
	
	UNKNOWN_HIGH_PRIORITY = {
		0x08: 'CRITICAL - Unknown (500+ occurrences, 90% coverage)',
		0x0E: 'Frequent unknown (100+ occurrences)',
	}
	
	SUSPECTED = {
		0x07: 'Speed 3? (slowest)',
		0x09: 'Speed 5? (custom)',
		0x0A: 'Unknown - rare',
		0x0B: 'Unknown - rare',
		0x0C: 'Unknown - rare',
		0x0D: 'Unknown - rare',
		0x0F: 'Unknown - rare',
		0x10: 'Dynamic insertion? (item)',
		0x11: 'Dynamic insertion? (spell)',
		0x12: 'Dynamic insertion? (monster)',
		0x13: 'Dynamic insertion? (character)',
		0x14: 'Dynamic insertion? (location)',
		0x15: 'Dynamic insertion? (number)',
		0x16: 'Dynamic insertion? (object)',
		0x17: 'Dynamic insertion? (weapon)',
		0x18: 'Dynamic insertion? (armor)',
		0x19: 'Dynamic insertion? (accessory)',
		0x1C: 'Unknown positioning?',
		0x1D: 'Unknown positioning?',
		0x1E: 'Unknown positioning?',
	}
	
	def __init__(self, rom_path: str, table_path: str = 'complex.tbl'):
		self.rom_path = rom_path
		self.table_path = table_path
		self.extractor = DialogExtractor(rom_path)
		
		# Statistics
		self.code_counts = Counter()
		self.dialogs_with_code = defaultdict(set)
		self.position_patterns = defaultdict(list)  # code -> [positions in dialog]
		self.code_pairs = Counter()  # Adjacent code pairs
		
	def analyze(self):
		"""Run complete analysis."""
		print(f"{'='*80}")
		print(f"FFMQ CONTROL CODE FREQUENCY ANALYSIS")
		print(f"{'='*80}\n")
		
		# Load ROM and data
		self.extractor.load_rom()
		self.extractor.load_char_table(self.table_path)
		self.extractor.load_dictionary()
		
		# Analyze all dialogs
		print("Analyzing control codes in 117 dialogs...\n")
		
		for i in range(117):
			_, raw_bytes = self.extractor.extract_dialog(i)
			self.analyze_dialog(i, raw_bytes)
		
		# Display results
		self.display_frequency_table()
		self.display_dialog_coverage()
		self.display_code_pairs()
		self.display_disassembly_priorities()
		self.display_position_patterns()
	
	def analyze_dialog(self, dialog_id: int, raw_bytes: bytes):
		"""Analyze a single dialog for control codes."""
		prev_byte = None
		
		for pos, byte in enumerate(raw_bytes):
			# Count control codes (0x00-0x1F)
			if byte <= 0x1F:
				self.code_counts[byte] += 1
				self.dialogs_with_code[byte].add(dialog_id)
				self.position_patterns[byte].append(pos)
				
				# Track adjacent code pairs
				if prev_byte is not None and prev_byte <= 0x1F:
					self.code_pairs[(prev_byte, byte)] += 1
			
			prev_byte = byte
	
	def display_frequency_table(self):
		"""Display control code frequency table."""
		print(f"{'='*80}")
		print(f"CONTROL CODE FREQUENCY (0x00-0x1F)")
		print(f"{'='*80}\n")
		
		print(f"{'Code':<6} {'Count':<8} {'Dialogs':<10} {'Coverage':<10} {'Description'}")
		print(f"{'-'*80}")
		
		for code in range(0x20):
			count = self.code_counts.get(code, 0)
			dialogs = len(self.dialogs_with_code.get(code, set()))
			coverage = (dialogs / 117 * 100) if dialogs > 0 else 0
			
			# Get description
			desc = self.CONFIRMED.get(code)
			if not desc:
				desc = self.UNKNOWN_HIGH_PRIORITY.get(code)
			if not desc:
				desc = self.SUSPECTED.get(code, 'Unknown')
			
			# Truncate long descriptions
			if len(desc) > 40:
				desc = desc[:37] + '...'
			
			# Highlight critical codes
			prefix = '🔴' if code in self.UNKNOWN_HIGH_PRIORITY else ''
			prefix = '✅' if code in self.CONFIRMED else prefix
			prefix = '⚠️ ' if code in self.SUSPECTED and count > 0 else prefix
			
			if count > 0:
				print(f"{prefix}0x{code:02X}  {count:6}   {dialogs:3}/117    {coverage:5.1f}%     {desc}")
	
	def display_dialog_coverage(self):
		"""Display which codes appear in most dialogs."""
		print(f"\n{'='*80}")
		print(f"DIALOG COVERAGE (codes appearing in most dialogs)")
		print(f"{'='*80}\n")
		
		# Sort by dialog coverage
		coverage_sorted = sorted(
			[(code, len(dialogs)) for code, dialogs in self.dialogs_with_code.items()],
			key=lambda x: x[1],
			reverse=True
		)[:15]
		
		print(f"{'Rank':<6} {'Code':<6} {'Dialogs':<12} {'Coverage':<12} {'Description'}")
		print(f"{'-'*80}")
		
		for rank, (code, dialog_count) in enumerate(coverage_sorted, 1):
			coverage = dialog_count / 117 * 100
			
			desc = self.CONFIRMED.get(code)
			if not desc:
				desc = self.UNKNOWN_HIGH_PRIORITY.get(code)
			if not desc:
				desc = self.SUSPECTED.get(code, 'Unknown')
			
			if len(desc) > 35:
				desc = desc[:32] + '...'
			
			print(f"{rank:<6} 0x{code:02X}  {dialog_count:3}/117      {coverage:5.1f}%       {desc}")
	
	def display_code_pairs(self):
		"""Display most common adjacent code pairs."""
		print(f"\n{'='*80}")
		print(f"MOST COMMON ADJACENT CODE PAIRS (control codes appearing together)")
		print(f"{'='*80}\n")
		
		# Sort by frequency
		top_pairs = sorted(
			self.code_pairs.items(),
			key=lambda x: x[1],
			reverse=True
		)[:20]
		
		if not top_pairs:
			print("No adjacent code pairs found.")
			return
		
		print(f"{'Count':<8} {'Pair':<15} {'Description'}")
		print(f"{'-'*80}")
		
		for (code1, code2), count in top_pairs:
			desc1 = self._get_short_desc(code1)
			desc2 = self._get_short_desc(code2)
			
			print(f"{count:6}   0x{code1:02X}, 0x{code2:02X}    {desc1} → {desc2}")
	
	def display_disassembly_priorities(self):
		"""Display recommended disassembly priorities."""
		print(f"\n{'='*80}")
		print(f"🎯 DISASSEMBLY PRIORITY RECOMMENDATIONS")
		print(f"{'='*80}\n")
		
		print("CRITICAL PRIORITY (block all other work):")
		for code, desc in self.UNKNOWN_HIGH_PRIORITY.items():
			count = self.code_counts.get(code, 0)
			dialogs = len(self.dialogs_with_code.get(code, set()))
			coverage = (dialogs / 117 * 100) if dialogs > 0 else 0
			
			print(f"  🔴 0x{code:02X}: {count:6} uses, {dialogs:3}/117 dialogs ({coverage:5.1f}%)")
			print(f"      {desc}")
			print(f"      → Issue #72: Disassemble function at 009DC1-009DD2")
		
		print("\nHIGH PRIORITY (frequent unknowns):")
		high_priority = [
			code for code in range(0x20)
			if code not in self.CONFIRMED
			and code not in self.UNKNOWN_HIGH_PRIORITY
			and self.code_counts.get(code, 0) > 10
		]
		
		for code in sorted(high_priority, key=lambda c: self.code_counts.get(c, 0), reverse=True):
			count = self.code_counts.get(code, 0)
			dialogs = len(self.dialogs_with_code.get(code, set()))
			desc = self.SUSPECTED.get(code, 'Unknown')
			
			print(f"  ⚠️  0x{code:02X}: {count:6} uses, {dialogs:3}/117 dialogs - {desc}")
		
		print("\nLOW PRIORITY (rare codes):")
		low_priority = [
			code for code in range(0x20)
			if code not in self.CONFIRMED
			and code not in self.UNKNOWN_HIGH_PRIORITY
			and 0 < self.code_counts.get(code, 0) <= 10
		]
		
		for code in sorted(low_priority):
			count = self.code_counts.get(code, 0)
			desc = self.SUSPECTED.get(code, 'Unknown')
			print(f"     0x{code:02X}: {count:6} uses - {desc}")
	
	def display_position_patterns(self):
		"""Display position patterns for critical codes."""
		print(f"\n{'='*80}")
		print(f"POSITION PATTERNS (where codes appear in dialogs)")
		print(f"{'='*80}\n")
		
		# Analyze critical code 0x08
		if 0x08 in self.position_patterns:
			positions = self.position_patterns[0x08]
			
			print("Code 0x08 Position Analysis:")
			print(f"  Total occurrences: {len(positions)}")
			print(f"  Average position:  {sum(positions) / len(positions):.1f}")
			print(f"  Min position:      {min(positions)}")
			print(f"  Max position:      {max(positions)}")
			
			# Position distribution
			position_ranges = {
				'Start (0-10)': sum(1 for p in positions if p <= 10),
				'Early (11-30)': sum(1 for p in positions if 11 <= p <= 30),
				'Middle (31-60)': sum(1 for p in positions if 31 <= p <= 60),
				'Late (61-100)': sum(1 for p in positions if 61 <= p <= 100),
				'End (101+)': sum(1 for p in positions if p > 100),
			}
			
			print("\n  Position distribution:")
			for range_name, count in position_ranges.items():
				pct = count / len(positions) * 100
				bar = '█' * int(pct / 2)
				print(f"    {range_name:<20} {count:4} ({pct:5.1f}%)  {bar}")
	
	def _get_short_desc(self, code: int) -> str:
		"""Get shortened description for a code."""
		desc = self.CONFIRMED.get(code)
		if not desc:
			desc = self.UNKNOWN_HIGH_PRIORITY.get(code)
		if not desc:
			desc = self.SUSPECTED.get(code, 'Unknown')
		
		# Truncate
		if len(desc) > 20:
			desc = desc[:17] + '...'
		
		return desc
	
	def export_csv(self, output_path: str = 'data/control_code_frequency.csv'):
		"""Export results to CSV."""
		import csv
		
		output = Path(output_path)
		output.parent.mkdir(parents=True, exist_ok=True)
		
		with output.open('w', newline='', encoding='utf-8') as f:
			writer = csv.writer(f)
			writer.writerow(['Code', 'Count', 'Dialogs', 'Coverage_Pct', 'Description', 'Status'])
			
			for code in range(0x20):
				count = self.code_counts.get(code, 0)
				dialogs = len(self.dialogs_with_code.get(code, set()))
				coverage = (dialogs / 117 * 100) if dialogs > 0 else 0
				
				desc = self.CONFIRMED.get(code)
				status = 'Confirmed'
				if not desc:
					desc = self.UNKNOWN_HIGH_PRIORITY.get(code)
					status = 'Critical Unknown'
				if not desc:
					desc = self.SUSPECTED.get(code, 'Unknown')
					status = 'Suspected' if code in self.SUSPECTED else 'Unknown'
				
				writer.writerow([
					f'0x{code:02X}',
					count,
					dialogs,
					f'{coverage:.1f}',
					desc,
					status
				])
		
		print(f"\n✅ Exported frequency data to {output_path}")


def main():
	"""Main entry point."""
	rom_path = sys.argv[1] if len(sys.argv) > 1 else r'roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc'
	
	analyzer = ControlCodeAnalyzer(rom_path)
	analyzer.analyze()
	analyzer.export_csv()
	
	print(f"\n{'='*80}")
	print(f"✅ ANALYSIS COMPLETE")
	print(f"{'='*80}")
	print(f"\nNext Steps:")
	print(f"  1. Disassemble code 0x08 handler (009DC1-009DD2) - Issue #72")
	print(f"  2. Test 0x08 removal/replacement in ROM patches - Issue #75")
	print(f"  3. Map dynamic insertion codes 0x10-0x1E - Issue #73")
	
	return 0


if __name__ == '__main__':
	sys.exit(main())
