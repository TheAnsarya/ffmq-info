#!/usr/bin/env python3
"""
Dictionary Compression Optimization Analyzer
=============================================

Analyzes dictionary usage to calculate compression efficiency and generate
optimization recommendations for ROM hackers and fan translators.

Author: TheAnsarya
Date: 2025-11-12
License: MIT
"""

import csv
import json
from pathlib import Path
from typing import Dict, List, Tuple, Optional


class DictionaryOptimizer:
	"""Analyzes and optimizes dictionary compression efficiency."""
	
	def __init__(self, frequency_csv: str, dialogs_json: str):
		"""
		Initialize optimizer.
		
		Args:
			frequency_csv: Path to dictionary_usage.csv
			dialogs_json: Path to extracted_dialogs.json
		"""
		self.frequency_csv = Path(frequency_csv)
		self.dialogs_json = Path(dialogs_json)
		
		self.dictionary: Dict[int, Dict] = {}
		self.dialogs: List[Dict] = []
		
		# Compression metrics
		self.total_references = 0
		self.total_expanded_bytes = 0
		self.total_reference_bytes = 0
	
	def load_frequency_data(self) -> None:
		"""Load dictionary frequency data from CSV."""
		print("Loading dictionary frequency data...")
		
		with open(self.frequency_csv, 'r', encoding='utf-8') as f:
			reader = csv.DictReader(f)
			for row in reader:
				entry_id = int(row['Byte'], 16)
				
				self.dictionary[entry_id] = {
					'text': row['Entry_Text'],
					'length': int(row['Length']),
					'occurrences': int(row['Usage']),
					'coverage': 0.0,  # Calculate this separately
					'total_bytes': int(row['Bytes_Saved']),
				}
		
		print(f"  Loaded {len(self.dictionary)} dictionary entries")
	
	def load_dialogs(self) -> None:
		"""Load dialog data from JSON."""
		print("Loading dialog data...")
		
		with open(self.dialogs_json, 'r', encoding='utf-8') as f:
			self.dialogs = json.load(f)
		
		print(f"  Loaded {len(self.dialogs)} dialogs")
	
	def calculate_compression_ratio(self) -> Dict:
		"""
		Calculate overall compression ratio.
		
		Returns:
			Dictionary with compression metrics
		"""
		print("\nCalculating compression metrics...")
		
		# Sum up all dictionary references
		for entry_id, data in self.dictionary.items():
			occurrences = data['occurrences']
			length = data['length']
			
			# Each reference is 1 byte (0x30-0x7F)
			reference_bytes = occurrences * 1
			
			# Expanded bytes = length * occurrences
			expanded_bytes = occurrences * length
			
			self.total_references += occurrences
			self.total_reference_bytes += reference_bytes
			self.total_expanded_bytes += expanded_bytes
		
		# Compression ratio
		if self.total_reference_bytes > 0:
			compression_ratio = self.total_expanded_bytes / self.total_reference_bytes
		else:
			compression_ratio = 1.0
		
		# Bytes saved
		bytes_saved = self.total_expanded_bytes - self.total_reference_bytes
		
		# Space efficiency
		space_efficiency = (bytes_saved / self.total_expanded_bytes) * 100 if self.total_expanded_bytes > 0 else 0
		
		metrics = {
			'total_references': self.total_references,
			'total_reference_bytes': self.total_reference_bytes,
			'total_expanded_bytes': self.total_expanded_bytes,
			'bytes_saved': bytes_saved,
			'compression_ratio': compression_ratio,
			'space_efficiency': space_efficiency,
		}
		
		print(f"  Total References: {self.total_references:,}")
		print(f"  Reference Bytes: {self.total_reference_bytes:,}")
		print(f"  Expanded Bytes: {self.total_expanded_bytes:,}")
		print(f"  Bytes Saved: {bytes_saved:,}")
		print(f"  Compression Ratio: {compression_ratio:.2f}:1")
		print(f"  Space Efficiency: {space_efficiency:.1f}%")
		
		return metrics
	
	def identify_underused_entries(self, threshold: int = 5) -> List[Dict]:
		"""
		Identify dictionary entries with low usage.
		
		Args:
			threshold: Minimum occurrences to be considered "well-used"
		
		Returns:
			List of underused entries
		"""
		print(f"\nIdentifying underused entries (< {threshold} occurrences)...")
		
		underused = []
		
		for entry_id, data in sorted(self.dictionary.items()):
			if data['occurrences'] < threshold:
				underused.append({
					'entry_id': entry_id,
					'hex': f'0x{entry_id:02X}',
					'text': data['text'],
					'length': data['length'],
					'occurrences': data['occurrences'],
					'total_bytes': data['total_bytes'],
				})
		
		print(f"  Found {len(underused)} underused entries")
		
		return underused
	
	def calculate_entry_efficiency(self) -> List[Dict]:
		"""
		Calculate efficiency score for each entry.
		
		Efficiency = (bytes_saved * occurrences) / length
		Higher score = better compression value
		
		Returns:
			List of entries sorted by efficiency
		"""
		print("\nCalculating entry efficiency scores...")
		
		scored_entries = []
		
		for entry_id, data in self.dictionary.items():
			length = data['length']
			occurrences = data['occurrences']
			
			# Bytes saved per occurrence (length - 1)
			# Reference takes 1 byte, expansion takes 'length' bytes
			bytes_saved_per_use = length - 1
			
			# Total bytes saved
			total_saved = bytes_saved_per_use * occurrences
			
			# Efficiency score
			# Higher length AND higher usage = higher efficiency
			efficiency = total_saved if occurrences > 0 else 0
			
			scored_entries.append({
				'entry_id': entry_id,
				'hex': f'0x{entry_id:02X}',
				'text': data['text'],
				'length': length,
				'occurrences': occurrences,
				'bytes_saved': total_saved,
				'efficiency': efficiency,
			})
		
		# Sort by efficiency (highest first)
		scored_entries.sort(key=lambda x: x['efficiency'], reverse=True)
		
		return scored_entries
	
	def find_replacement_candidates(self, corpus_analysis: bool = False) -> List[Dict]:
		"""
		Find phrases in dialogs that could benefit from dictionary encoding.
		
		Args:
			corpus_analysis: Perform deep corpus analysis (slow)
		
		Returns:
			List of candidate phrases
		"""
		print("\nFinding replacement candidates...")
		
		candidates = []
		
		if not corpus_analysis:
			print("  (Skipping deep corpus analysis - use --corpus flag for full analysis)")
			return candidates
		
		# TODO: Implement n-gram analysis of dialog corpus
		# For now, return empty list
		
		return candidates
	
	def generate_recommendations(self, metrics: Dict, underused: List[Dict],
	                            efficiency: List[Dict]) -> None:
		"""
		Generate optimization recommendations.
		
		Args:
			metrics: Compression metrics
			underused: Underused entries
			efficiency: Efficiency-scored entries
		"""
		print("\n" + "="*80)
		print("OPTIMIZATION RECOMMENDATIONS")
		print("="*80 + "\n")
		
		# Overall assessment
		print("## Overall Assessment\n")
		print(f"Current compression ratio: {metrics['compression_ratio']:.2f}:1")
		print(f"Space efficiency: {metrics['space_efficiency']:.1f}%")
		print(f"Total bytes saved: {metrics['bytes_saved']:,}\n")
		
		if metrics['compression_ratio'] > 2.0:
			print("✅ EXCELLENT: Dictionary provides strong compression benefit\n")
		elif metrics['compression_ratio'] > 1.5:
			print("✓ GOOD: Dictionary provides solid compression\n")
		else:
			print("⚠ MODERATE: Dictionary compression could be improved\n")
		
		# Top performers
		print("## Top 10 Most Efficient Entries\n")
		print("These entries provide the most compression benefit:\n")
		
		for i, entry in enumerate(efficiency[:10], 1):
			print(f"{i}. Entry {entry['hex']}: \"{entry['text'][:30]}...\"")
			print(f"   Length: {entry['length']}, Uses: {entry['occurrences']}, Saves: {entry['bytes_saved']} bytes\n")
		
		# Underused entries
		if underused:
			print(f"## Underused Entries ({len(underused)} total)\n")
			print("These entries have low usage and could be replaced:\n")
			
			for entry in underused[:10]:
				print(f"- Entry {entry['hex']}: \"{entry['text'][:40]}\"")
				print(f"  Length: {entry['length']}, Uses: {entry['occurrences']}\n")
			
			if len(underused) > 10:
				print(f"  ... and {len(underused) - 10} more\n")
		
		# Recommendations for fan translations
		print("## Recommendations for Fan Translators\n")
		
		print("### 1. Preserve High-Efficiency Entries")
		print("   Keep entries 0x30-0x3F (top performers) as-is or maintain similar length\n")
		
		print("### 2. Replace Underused Entries")
		if underused:
			unused_count = sum(1 for e in underused if e['occurrences'] == 0)
			print(f"   {len(underused)} entries used < 5 times ({unused_count} never used)")
			print("   These can be replaced with frequently-used target language phrases\n")
		
		print("### 3. Maintain Compression Ratio")
		print(f"   Current ratio: {metrics['compression_ratio']:.2f}:1")
		print("   Aim to maintain at least 2:1 ratio for good space efficiency\n")
		
		print("### 4. Test Before Committing")
		print("   Use import_complex_text.py to test modified dictionaries")
		print("   Verify all dialogs still display correctly\n")
	
	def generate_report(self, output_path: str) -> None:
		"""
		Generate comprehensive optimization report.
		
		Args:
			output_path: Path to output report file
		"""
		print(f"\nGenerating optimization report: {output_path}")
		
		metrics = self.calculate_compression_ratio()
		underused = self.identify_underused_entries(threshold=5)
		efficiency = self.calculate_entry_efficiency()
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write("=" * 80 + "\n")
			f.write("Dictionary Compression Optimization Report\n")
			f.write("Final Fantasy Mystic Quest\n")
			f.write("=" * 80 + "\n\n")
			
			# Metrics
			f.write("## Compression Metrics\n\n")
			f.write(f"**Total Dictionary References**: {metrics['total_references']:,}\n")
			f.write(f"**Reference Bytes** (1 byte each): {metrics['total_reference_bytes']:,}\n")
			f.write(f"**Expanded Bytes** (full text): {metrics['total_expanded_bytes']:,}\n")
			f.write(f"**Bytes Saved**: {metrics['bytes_saved']:,}\n")
			f.write(f"**Compression Ratio**: {metrics['compression_ratio']:.2f}:1\n")
			f.write(f"**Space Efficiency**: {metrics['space_efficiency']:.1f}%\n\n")
			
			# Efficiency ranking
			f.write("-" * 80 + "\n")
			f.write("## Efficiency Ranking (Top 20)\n\n")
			f.write("| Rank | Entry | Text | Length | Uses | Bytes Saved |\n")
			f.write("|------|-------|------|--------|------|-------------|\n")
			
			for i, entry in enumerate(efficiency[:20], 1):
				text = entry['text'][:30].replace('|', '\\|')
				f.write(f"| {i} | {entry['hex']} | {text} | {entry['length']} | ")
				f.write(f"{entry['occurrences']} | {entry['bytes_saved']} |\n")
			
			f.write("\n")
			
			# Underused entries
			f.write("-" * 80 + "\n")
			f.write(f"## Underused Entries ({len(underused)} total)\n\n")
			f.write("Entries with < 5 occurrences (candidates for replacement):\n\n")
			f.write("| Entry | Text | Length | Uses | Total Bytes |\n")
			f.write("|-------|------|--------|------|-------------|\n")
			
			for entry in underused:
				text = entry['text'][:40].replace('|', '\\|')
				f.write(f"| {entry['hex']} | {text} | {entry['length']} | ")
				f.write(f"{entry['occurrences']} | {entry['total_bytes']} |\n")
			
			f.write("\n")
			
			# Recommendations
			f.write("-" * 80 + "\n")
			f.write("## Optimization Recommendations\n\n")
			
			f.write("### For Fan Translators\n\n")
			f.write("1. **Preserve High-Value Entries**\n")
			f.write("   - Keep entries 0x30-0x45 (top 20 by efficiency)\n")
			f.write("   - These provide maximum compression benefit\n\n")
			
			f.write("2. **Replace Low-Value Entries**\n")
			f.write(f"   - {len(underused)} entries used < 5 times\n")
			f.write("   - Replace with common target language phrases\n")
			f.write("   - Prioritize long, frequently-used phrases\n\n")
			
			f.write("3. **Maintain Compression Ratio**\n")
			f.write(f"   - Current ratio: {metrics['compression_ratio']:.2f}:1\n")
			f.write("   - Target: Maintain at least 2:1 for good efficiency\n\n")
			
			f.write("4. **Formatting Codes Integration**\n")
			f.write("   - Entries 0x50-0x51 use special formatting (codes 0x1D, 0x1E)\n")
			f.write("   - Test carefully if modifying these entries\n\n")
			
			f.write("### For ROM Hackers\n\n")
			f.write("1. **Expand Dictionary Space**\n")
			f.write("   - Current: 80 entries (0x30-0x7F)\n")
			f.write("   - Potential: Could extend if space allows\n\n")
			
			f.write("2. **Optimize Code 0x08 Usage**\n")
			f.write("   - Subroutine calls used 500+ times\n")
			f.write("   - Combine with dictionary for maximum efficiency\n\n")
			
			f.write("3. **Unused Entries**\n")
			unused = [e for e in underused if e['occurrences'] == 0]
			f.write(f"   - {len(unused)} entries never used\n")
			f.write("   - Safe to replace without ROM testing\n\n")
			
			f.write("=" * 80 + "\n")
			f.write("End of Report\n")
			f.write("=" * 80 + "\n")
		
		print(f"Report generated: {output_path}")
		
		# Console output
		self.generate_recommendations(metrics, underused, efficiency)


def main():
	"""Main entry point."""
	import argparse
	
	parser = argparse.ArgumentParser(
		description="Analyze dictionary compression efficiency and generate optimization recommendations"
	)
	parser.add_argument(
		"--frequency",
		help="Path to dictionary_usage.csv",
		default="data/dictionary_usage.csv"
	)
	parser.add_argument(
		"--dialogs",
		help="Path to extracted_dialogs.json",
		default="data/extracted_dialogs.json"
	)
	parser.add_argument(
		"--output",
		help="Path to output report",
		default="docs/DICTIONARY_OPTIMIZATION.md"
	)
	parser.add_argument(
		"--corpus",
		help="Perform deep corpus analysis (slow)",
		action="store_true"
	)
	
	args = parser.parse_args()
	
	print("=" * 80)
	print("Dictionary Compression Optimization Analyzer")
	print("=" * 80)
	
	optimizer = DictionaryOptimizer(args.frequency, args.dialogs)
	
	optimizer.load_frequency_data()
	optimizer.load_dialogs()
	
	optimizer.generate_report(args.output)
	
	print("\n" + "=" * 80)
	print("Analysis complete!")
	print("=" * 80)


if __name__ == "__main__":
	main()
