#!/usr/bin/env python3
"""
CODE Label Analyzer
Scans ASM files for CODE_* placeholder labels and generates progress report
"""

import re
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Tuple

class CodeLabelAnalyzer:
	"""Analyze CODE_* placeholder labels in assembly files"""

	def __init__(self, project_root: str = "."):
		self.project_root = Path(project_root)
		self.code_label_pattern = re.compile(r'\bCODE_([0-9A-F]{6})\b')

	def scan_file(self, file_path: Path) -> Tuple[List[str], Dict[str, int]]:
		"""Scan a single ASM file for CODE labels

		Returns:
			(unique_labels, usage_counts)
		"""
		try:
			content = file_path.read_text(encoding='utf-8')
		except Exception as e:
			print(f"⚠️  Error reading {file_path}: {e}")
			return [], {}

		# Find all CODE labels
		matches = self.code_label_pattern.findall(content)

		# Count usage per label
		usage_counts = defaultdict(int)
		for label in matches:
			usage_counts[f"CODE_{label}"] += 1

		unique_labels = list(set(usage_counts.keys()))

		return unique_labels, dict(usage_counts)

	def scan_project(self) -> Dict[str, Dict]:
		"""Scan all ASM files in project

		Returns:
			{file_path: {labels: [...], usage: {...}}}
		"""
		asm_files = list(self.project_root.glob('src/**/*.asm'))

		results = {}

		for file_path in sorted(asm_files):
			labels, usage = self.scan_file(file_path)
			if labels:  # Only include files with CODE labels
				rel_path = file_path.relative_to(self.project_root)
				results[str(rel_path)] = {
					'labels': sorted(labels),
					'usage': usage,
					'count': len(labels)
				}

		return results

	def generate_report(self, save_to_file: bool = False) -> str:
		"""Generate comprehensive CODE label analysis report"""
		results = self.scan_project()

		# Calculate statistics
		total_unique_labels = set()
		total_usage_count = 0
		files_with_labels = len(results)

		for file_data in results.values():
			total_unique_labels.update(file_data['labels'])
			total_usage_count += sum(file_data['usage'].values())

		# Group labels by bank
		labels_by_bank = defaultdict(list)
		for label in sorted(total_unique_labels):
			bank = label[5:7]  # Extract bank from CODE_XXXXXX
			labels_by_bank[bank].append(label)

		# Build report
		lines = []
		lines.append("="*80)
		lines.append(" CODE Label Analysis Report")
		lines.append("="*80)
		lines.append("")

		# Summary
		lines.append("📊 SUMMARY")
		lines.append("─"*80)
		lines.append(f"  Total Unique CODE Labels: {len(total_unique_labels):,}")
		lines.append(f"  Total Usage Count:        {total_usage_count:,}")
		lines.append(f"  Files with CODE Labels:   {files_with_labels}")
		lines.append(f"  Banks Represented:        {len(labels_by_bank)}")
		lines.append("")

		# Bank breakdown
		lines.append("🏦 LABELS BY BANK")
		lines.append("─"*80)
		for bank in sorted(labels_by_bank.keys()):
			label_count = len(labels_by_bank[bank])
			lines.append(f"  Bank ${bank}: {label_count:3d} labels")
		lines.append("")

		# File breakdown
		lines.append("📄 LABELS BY FILE")
		lines.append("─"*80)

		# Sort files by label count (descending)
		sorted_files = sorted(results.items(),
							 key=lambda x: x[1]['count'],
							 reverse=True)

		for file_path, file_data in sorted_files:
			label_count = file_data['count']
			usage_count = sum(file_data['usage'].values())
			lines.append(f"\n  {file_path}")
			lines.append(f"    Unique labels: {label_count:,}")
			lines.append(f"    Total usage:   {usage_count:,}")

			# Show top labels if there are many
			if label_count > 10:
				# Show top 5 most-used labels
				top_labels = sorted(file_data['usage'].items(),
								   key=lambda x: x[1],
								   reverse=True)[:5]
				lines.append("    Top labels:")
				for label, count in top_labels:
					lines.append(f"      {label}: {count} uses")

		lines.append("")
		lines.append("="*80)

		report = '\n'.join(lines)

		# Save to file if requested
		if save_to_file:
			output_path = self.project_root / 'reports' / 'code_labels.txt'
			output_path.parent.mkdir(parents=True, exist_ok=True)
			output_path.write_text(report, encoding='utf-8')
			print(f"\n💾 Report saved to: {output_path}")

		return report

	def find_undefined_labels(self) -> List[str]:
		"""Find CODE labels that are referenced but never defined"""
		results = self.scan_project()

		# Collect all labels
		all_labels = set()
		defined_labels = set()

		for file_path, file_data in results.items():
			# Read file to check for definitions (labels with colons)
			full_path = self.project_root / file_path
			try:
				content = full_path.read_text(encoding='utf-8')

				# Add all found labels
				for label in file_data['labels']:
					all_labels.add(label)

					# Check if defined (label followed by colon)
					if re.search(rf'^{re.escape(label)}:', content, re.MULTILINE):
						defined_labels.add(label)

			except Exception as e:
				print(f"⚠️  Error reading {file_path}: {e}")
				continue

		# Find undefined (referenced but not defined)
		undefined = all_labels - defined_labels

		return sorted(undefined)

	def generate_undefined_report(self) -> str:
		"""Generate report of undefined CODE labels"""
		undefined = self.find_undefined_labels()

		# Group by bank
		by_bank = defaultdict(list)
		for label in undefined:
			bank = label[5:7]
			by_bank[bank].append(label)

		lines = []
		lines.append("\n" + "="*80)
		lines.append(" Undefined CODE Labels (References without Definitions)")
		lines.append("="*80)
		lines.append("")
		lines.append(f"Total: {len(undefined)} undefined labels")
		lines.append("")

		for bank in sorted(by_bank.keys()):
			labels = by_bank[bank]
			lines.append(f"Bank ${bank}: {len(labels)} undefined")
			for label in sorted(labels)[:10]:  # Show first 10 per bank
				lines.append(f"  {label}")
			if len(labels) > 10:
				lines.append(f"  ... and {len(labels) - 10} more")
			lines.append("")

		lines.append("="*80)

		return '\n'.join(lines)

def main():
	"""Main entry point"""
	import sys

	save_to_file = '--save' in sys.argv
	show_undefined = '--undefined' in sys.argv

	analyzer = CodeLabelAnalyzer()

	# Generate main report
	report = analyzer.generate_report(save_to_file=save_to_file)
	print(report)

	# Generate undefined report if requested
	if show_undefined:
		undefined_report = analyzer.generate_undefined_report()
		print(undefined_report)

		if save_to_file:
			output_path = Path('reports') / 'code_labels_undefined.txt'
			output_path.write_text(undefined_report, encoding='utf-8')
			print(f"💾 Undefined report saved to: {output_path}")

if __name__ == '__main__':
	main()
