#!/usr/bin/env python3
"""
FFMQ Dictionary Usage Frequency Analyzer
Analyzes how often each dictionary entry is used across all 117 dialogs.

This helps identify:
- Most valuable dictionary entries (high usage)
- Wasted dictionary slots (low/zero usage)
- Optimization opportunities for fan translations

Author: FFMQ Disassembly Project
Date: 2025-11-12
"""

import sys
from pathlib import Path
from collections import Counter
from typing import Dict, List, Tuple

# Import dialog extractor
sys.path.insert(0, str(Path(__file__).parent.parent / 'extraction'))
from extract_all_dialogs import DialogExtractor


class DictionaryUsageAnalyzer:
	"""Analyzes dictionary entry usage across all dialogs."""
	
	def __init__(self, rom_path: str, table_path: str = 'complex.tbl'):
		self.rom_path = rom_path
		self.table_path = table_path
		self.extractor = DialogExtractor(rom_path)
		self.usage_counts = Counter()
		self.total_bytes_saved = {}
		
	def analyze(self):
		"""Run complete analysis."""
		print(f"{'='*80}")
		print(f"FFMQ DICTIONARY USAGE FREQUENCY ANALYSIS")
		print(f"{'='*80}\n")
		
		# Load ROM and dictionary
		self.extractor.load_rom()
		self.extractor.load_char_table(self.table_path)
		self.extractor.load_dictionary()
		
		# Analyze all dialogs
		print("Analyzing dictionary usage across 117 dialogs...\n")
		
		for i in range(117):
			_, raw_bytes = self.extractor.extract_dialog(i)
			
			# Count dictionary byte occurrences
			for byte in raw_bytes:
				if 0x30 <= byte < 0x80:  # Dictionary range
					self.usage_counts[byte] += 1
		
		# Calculate compression savings
		self.calculate_savings()
		
		# Display results
		self.display_results()
		self.display_top_entries()
		self.display_unused_entries()
		self.display_statistics()
	
	def calculate_savings(self):
		"""Calculate bytes saved by each dictionary entry."""
		for byte_val in range(0x30, 0x80):
			usage = self.usage_counts.get(byte_val, 0)
			
			# Get dictionary entry text
			entry_text = self.extractor.dictionary.get(byte_val, '')
			entry_length = len(entry_text)
			
			# Savings = (entry_length - 1) × usage_count
			# -1 because the dictionary byte itself is 1 byte
			savings = (entry_length - 1) * usage
			
			self.total_bytes_saved[byte_val] = savings
	
	def display_results(self):
		"""Display complete results table."""
		print(f"{'='*80}")
		print(f"DICTIONARY ENTRY USAGE (0x30-0x7F)")
		print(f"{'='*80}\n")
		print(f"{'Byte':<6} {'Usage':<8} {'Entry Text':<30} {'Length':<8} {'Savings'}")
		print(f"{'-'*80}")
		
		for byte_val in range(0x30, 0x80):
			usage = self.usage_counts.get(byte_val, 0)
			entry_text = self.extractor.dictionary.get(byte_val, '???')
			entry_length = len(entry_text)
			savings = self.total_bytes_saved.get(byte_val, 0)
			
			# Truncate long entries
			display_text = entry_text[:28] + '..' if len(entry_text) > 30 else entry_text
			display_text = display_text.replace('\n', '\\n')
			
			print(f"0x{byte_val:02X}  {usage:6}   {display_text:<30} {entry_length:4}     {savings:5} bytes")
	
	def display_top_entries(self):
		"""Display top 20 most-used dictionary entries."""
		print(f"\n{'='*80}")
		print(f"TOP 20 MOST-USED DICTIONARY ENTRIES")
		print(f"{'='*80}\n")
		
		# Sort by usage count
		sorted_entries = sorted(
			self.usage_counts.items(),
			key=lambda x: x[1],
			reverse=True
		)[:20]
		
		print(f"{'Rank':<6} {'Byte':<6} {'Usage':<8} {'Savings':<10} {'Entry Text'}")
		print(f"{'-'*80}")
		
		for rank, (byte_val, usage) in enumerate(sorted_entries, 1):
			entry_text = self.extractor.dictionary.get(byte_val, '???')
			savings = self.total_bytes_saved.get(byte_val, 0)
			
			display_text = entry_text[:40] + '..' if len(entry_text) > 42 else entry_text
			display_text = display_text.replace('\n', '\\n')
			
			print(f"{rank:<6} 0x{byte_val:02X}  {usage:6}   {savings:6} bytes  {display_text}")
	
	def display_unused_entries(self):
		"""Display unused or rarely-used dictionary entries."""
		print(f"\n{'='*80}")
		print(f"UNUSED OR RARELY-USED DICTIONARY ENTRIES (< 5 uses)")
		print(f"{'='*80}\n")
		
		# Find entries with < 5 uses
		rare_entries = [
			(byte_val, self.usage_counts.get(byte_val, 0))
			for byte_val in range(0x30, 0x80)
			if self.usage_counts.get(byte_val, 0) < 5
		]
		
		if not rare_entries:
			print("✅ All dictionary entries are well-utilized!")
		else:
			print(f"Found {len(rare_entries)} dictionary entries with < 5 uses:\n")
			print(f"{'Byte':<6} {'Usage':<8} {'Entry Text'}")
			print(f"{'-'*80}")
			
			for byte_val, usage in sorted(rare_entries, key=lambda x: x[1]):
				entry_text = self.extractor.dictionary.get(byte_val, '???')
				display_text = entry_text[:60] if len(entry_text) <= 60 else entry_text[:58] + '..'
				display_text = display_text.replace('\n', '\\n')
				
				print(f"0x{byte_val:02X}  {usage:6}   {display_text}")
			
			print(f"\n⚠️  These {len(rare_entries)} entries could potentially be replaced")
			print(f"   with more common patterns for better compression.")
	
	def display_statistics(self):
		"""Display overall statistics."""
		print(f"\n{'='*80}")
		print(f"COMPRESSION STATISTICS")
		print(f"{'='*80}\n")
		
		# Calculate totals
		total_dictionary_uses = sum(self.usage_counts.values())
		total_bytes_saved = sum(self.total_bytes_saved.values())
		
		# Dictionary entry statistics
		entries_used = sum(1 for count in self.usage_counts.values() if count > 0)
		entries_unused = 80 - entries_used
		
		# Average usage
		avg_usage = total_dictionary_uses / 80 if total_dictionary_uses > 0 else 0
		avg_usage_of_used = total_dictionary_uses / entries_used if entries_used > 0 else 0
		
		print(f"Dictionary Entries:")
		print(f"  Total entries:          80")
		print(f"  Entries used:           {entries_used} ({entries_used * 100 / 80:.1f}%)")
		print(f"  Entries unused:         {entries_unused} ({entries_unused * 100 / 80:.1f}%)")
		print(f"  Average usage per entry: {avg_usage:.1f} times")
		print(f"  Average usage (used only): {avg_usage_of_used:.1f} times")
		
		print(f"\nCompression Impact:")
		print(f"  Total dictionary uses:   {total_dictionary_uses}")
		print(f"  Total bytes saved:       {total_bytes_saved:,} bytes")
		print(f"  Average saving per use:  {total_bytes_saved / total_dictionary_uses:.2f} bytes")
		
		print(f"\nTop Savers (by total bytes saved):")
		top_savers = sorted(
			self.total_bytes_saved.items(),
			key=lambda x: x[1],
			reverse=True
		)[:5]
		
		for byte_val, savings in top_savers:
			entry_text = self.extractor.dictionary.get(byte_val, '???')[:30]
			usage = self.usage_counts.get(byte_val, 0)
			print(f"  0x{byte_val:02X}: {savings:5} bytes ({usage:3}× '{entry_text}')")
	
	def export_csv(self, output_path: str = 'data/dictionary_usage.csv'):
		"""Export results to CSV for further analysis."""
		import csv
		
		output = Path(output_path)
		output.parent.mkdir(parents=True, exist_ok=True)
		
		with output.open('w', newline='', encoding='utf-8') as f:
			writer = csv.writer(f)
			writer.writerow(['Byte', 'Usage', 'Entry_Text', 'Length', 'Bytes_Saved'])
			
			for byte_val in range(0x30, 0x80):
				usage = self.usage_counts.get(byte_val, 0)
				entry_text = self.extractor.dictionary.get(byte_val, '???')
				entry_length = len(entry_text)
				savings = self.total_bytes_saved.get(byte_val, 0)
				
				writer.writerow([
					f'0x{byte_val:02X}',
					usage,
					entry_text.replace('\n', '\\n'),
					entry_length,
					savings
				])
		
		print(f"\n✅ Exported usage data to {output_path}")


def main():
	"""Main entry point."""
	rom_path = sys.argv[1] if len(sys.argv) > 1 else r'roms\Final Fantasy - Mystic Quest (U) (V1.1).sfc'
	
	analyzer = DictionaryUsageAnalyzer(rom_path)
	analyzer.analyze()
	analyzer.export_csv()
	
	print(f"\n{'='*80}")
	print(f"✅ ANALYSIS COMPLETE")
	print(f"{'='*80}")
	
	return 0


if __name__ == '__main__':
	sys.exit(main())
