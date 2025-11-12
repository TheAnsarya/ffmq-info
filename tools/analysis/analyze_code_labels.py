#!/usr/bin/env python3
"""
Analyze CODE_* labels in assembly files and suggest meaningful names.

This tool:
1. Finds all CODE_* labels in assembly files
2. Analyzes surrounding context (comments, operations)
3. Suggests meaningful replacement names
4. Generates report and optionally applies changes
"""

import re
import os
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Tuple, Set

class CodeLabelAnalyzer:
	"""Analyzes CODE_* labels and suggests meaningful names."""
	
	def __init__(self, src_dir: str):
		self.src_dir = Path(src_dir)
		self.labels: Dict[str, Dict] = {}
		self.references: Dict[str, List[Tuple[str, int]]] = defaultdict(list)
		
	def find_all_labels(self):
		"""Find all CODE_* labels in assembly files."""
		print("Scanning for CODE_* labels...")
		
		for asm_file in self.src_dir.rglob("*.asm"):
			self.analyze_file(asm_file)
			
		print(f"\nFound {len(self.labels)} unique CODE_* labels")
		print(f"Found {sum(len(refs) for refs in self.references.values())} total references")
		
	def analyze_file(self, filepath: Path):
		"""Analyze a single assembly file."""
		try:
			with open(filepath, 'r', encoding='utf-8') as f:
				lines = f.readlines()
		except Exception as e:
			print(f"Error reading {filepath}: {e}")
			return
			
		for line_num, line in enumerate(lines, 1):
			# Check for label definition
			label_match = re.match(r'^(CODE_[0-9A-F]+):', line)
			if label_match:
				label_name = label_match.group(1)
				if label_name not in self.labels:
					context = self.extract_context(lines, line_num)
					self.labels[label_name] = {
						'file': str(filepath),
						'line': line_num,
						'context': context,
						'suggested_name': self.suggest_name(label_name, context)
					}
			
			# Check for label reference
			ref_matches = re.finditer(r'\b(CODE_[0-9A-F]+)\b', line)
			for match in ref_matches:
				label_name = match.group(1)
				self.references[label_name].append((str(filepath), line_num))
				
	def extract_context(self, lines: List[str], label_line: int) -> Dict:
		"""Extract context around a label."""
		context = {
			'comments_before': [],
			'comments_after': [],
			'operations': [],
			'section_comment': None
		}
		
		# Look for section comment (lines starting with ; and uppercase)
		for i in range(max(0, label_line - 20), label_line):
			line = lines[i].strip()
			if line.startswith(';') and line.startswith('; CODE_'):
				# This is a function header comment
				context['section_comment'] = line
				break
		
		# Get comments before label (up to 5 lines)
		for i in range(max(0, label_line - 6), label_line - 1):
			line = lines[i].strip()
			if line.startswith(';'):
				context['comments_before'].append(line)
				
		# Get operations after label (up to 10 lines)
		for i in range(label_line, min(len(lines), label_line + 10)):
			line = lines[i].strip()
			if line and not line.startswith(';'):
				# Extract operation
				op_match = re.match(r'^\s*([a-z]+\.?[wlb]?)\s', line, re.IGNORECASE)
				if op_match:
					context['operations'].append(op_match.group(1).lower())
				# Check for comments after operation
				comment_match = re.search(r';(.+)$', line)
				if comment_match:
					context['comments_after'].append(comment_match.group(1).strip())
			elif line.startswith(';'):
				context['comments_after'].append(line)
				
			# Stop if we hit another label
			if re.match(r'^[A-Za-z_][A-Za-z0-9_]+:', line):
				break
				
		return context
		
	def suggest_name(self, label: str, context: Dict) -> str:
		"""Suggest a meaningful name based on context."""
		address = label.replace('CODE_', '')
		
		# Check section comment first
		if context['section_comment']:
			comment = context['section_comment']
			# Try to extract function name from comment
			name_match = re.search(r'CODE_[0-9A-F]+:\s*(.+)', comment)
			if name_match:
				suggested = name_match.group(1).strip()
				# Clean up the name
				suggested = re.sub(r'\s+', '_', suggested)
				suggested = re.sub(r'[^\w_]', '', suggested)
				if suggested and not suggested.startswith('CODE_'):
					return suggested
		
		# Look for meaningful comments
		all_comments = context['comments_before'] + context['comments_after']
		for comment in all_comments:
			comment = comment.lstrip(';').strip()
			
			# Common patterns
			patterns = [
				(r'^([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+)*)', 'from_comment'),
				(r'Loop', 'Loop'),
				(r'Wait|Delay', 'Wait'),
				(r'Check|Verify|Test', 'Check'),
				(r'Init|Initialize', 'Initialize'),
				(r'Load|Upload|Transfer', 'Load'),
				(r'Save|Store|Write', 'Save'),
				(r'Clear|Reset', 'Clear'),
				(r'Exit|Return|Done', 'Exit'),
				(r'If\s+(.+)', 'Conditional'),
			]
			
			for pattern, suggestion_type in patterns:
				match = re.search(pattern, comment, re.IGNORECASE)
				if match:
					if suggestion_type == 'from_comment':
						name = match.group(1)
						name = re.sub(r'\s+', '_', name)
						return f"{name}_{address}"
					else:
						return f"{suggestion_type}_{address}"
		
		# Analyze operations
		ops = context['operations'][:5]
		if ops:
			# Common operation patterns
			if ops[0] == 'rts' or ops[0] == 'rtl':
				return f"Return_{address}"
			elif ops[0] in ['jmp', 'jml', 'jsr', 'jsl']:
				return f"Jump_{address}"
			elif 'lda' in ops and 'sta' in ops:
				return f"Copy_{address}"
			elif 'lda' in ops or 'ldx' in ops or 'ldy' in ops:
				return f"Load_{address}"
			elif 'sta' in ops or 'stx' in ops or 'sty' in ops:
				return f"Store_{address}"
			elif any(op.startswith('b') and op != 'bit' for op in ops):
				return f"Branch_{address}"
				
		# Default: keep CODE_ prefix but mark as needing manual review
		return f"UNKNOWN_{address}"
		
	def generate_report(self, output_file: str = None):
		"""Generate a report of all labels and suggestions."""
		report_lines = []
		report_lines.append("=" * 80)
		report_lines.append("CODE_* Label Analysis Report")
		report_lines.append("=" * 80)
		report_lines.append(f"\nTotal Labels: {len(self.labels)}")
		report_lines.append(f"Total References: {sum(len(refs) for refs in self.references.values())}")
		report_lines.append("\n" + "=" * 80)
		
		# Group by file
		by_file = defaultdict(list)
		for label, info in sorted(self.labels.items()):
			by_file[info['file']].append((label, info))
			
		for filepath in sorted(by_file.keys()):
			report_lines.append(f"\n\nFile: {filepath}")
			report_lines.append("-" * 80)
			
			for label, info in sorted(by_file[filepath], key=lambda x: x[1]['line']):
				ref_count = len(self.references.get(label, []))
				report_lines.append(f"\nLine {info['line']}: {label}")
				report_lines.append(f"  Suggested: {info['suggested_name']}")
				report_lines.append(f"  References: {ref_count}")
				
				if info['context']['section_comment']:
					report_lines.append(f"  Section: {info['context']['section_comment']}")
					
				if info['context']['comments_before']:
					report_lines.append("  Comments before:")
					for comment in info['context']['comments_before'][-3:]:
						report_lines.append(f"    {comment}")
						
				if info['context']['operations']:
					ops_str = ', '.join(info['context']['operations'][:5])
					report_lines.append(f"  Operations: {ops_str}")
					
		report_lines.append("\n" + "=" * 80)
		report_lines.append("\nSummary by Suggestion Type:")
		report_lines.append("-" * 80)
		
		suggestion_counts = defaultdict(int)
		for info in self.labels.values():
			suggestion_type = info['suggested_name'].split('_')[0]
			suggestion_counts[suggestion_type] += 1
			
		for suggestion_type, count in sorted(suggestion_counts.items(), key=lambda x: -x[1]):
			report_lines.append(f"  {suggestion_type}: {count}")
			
		report = '\n'.join(report_lines)
		
		if output_file:
			with open(output_file, 'w', encoding='utf-8') as f:
				f.write(report)
			print(f"\nReport written to: {output_file}")
		else:
			print(report)
			
		return report
		
	def generate_rename_plan(self, output_file: str):
		"""Generate a JSON file with rename plan."""
		import json
		
		rename_plan = {
			'metadata': {
				'total_labels': len(self.labels),
				'total_references': sum(len(refs) for refs in self.references.values())
			},
			'renames': []
		}
		
		for label, info in sorted(self.labels.items()):
			rename_plan['renames'].append({
				'old_name': label,
				'new_name': info['suggested_name'],
				'file': info['file'],
				'line': info['line'],
				'references': len(self.references.get(label, [])),
				'context': {
					'section_comment': info['context']['section_comment'],
					'operations': info['context']['operations'][:5]
				}
			})
			
		with open(output_file, 'w', encoding='utf-8') as f:
			json.dump(rename_plan, f, indent=2)
			
		print(f"Rename plan written to: {output_file}")
		
	def apply_renames(self, dry_run: bool = True):
		"""Apply the suggested renames to files."""
		if dry_run:
			print("\n=== DRY RUN MODE ===")
			print("No files will be modified. Use dry_run=False to apply changes.")
			
		files_to_modify = defaultdict(list)
		
		# Group renames by file
		for label, info in self.labels.items():
			new_name = info['suggested_name']
			if new_name and new_name != label:
				files_to_modify[info['file']].append((label, new_name))
				for ref_file, ref_line in self.references.get(label, []):
					if (label, new_name) not in files_to_modify[ref_file]:
						files_to_modify[ref_file].append((label, new_name))
		
		# Apply renames file by file
		for filepath, renames in files_to_modify.items():
			print(f"\nProcessing: {filepath}")
			print(f"  {len(renames)} renames to apply")
			
			if dry_run:
				for old, new in renames[:5]:
					print(f"    {old} -> {new}")
				if len(renames) > 5:
					print(f"    ... and {len(renames) - 5} more")
			else:
				self.apply_renames_to_file(filepath, renames)
				
	def apply_renames_to_file(self, filepath: str, renames: List[Tuple[str, str]]):
		"""Apply renames to a single file."""
		try:
			with open(filepath, 'r', encoding='utf-8') as f:
				content = f.read()
		except Exception as e:
			print(f"  Error reading file: {e}")
			return
			
		# Apply each rename as whole-word replacement
		for old_name, new_name in renames:
			# Replace label definition
			content = re.sub(
				rf'^{re.escape(old_name)}:',
				f'{new_name}:',
				content,
				flags=re.MULTILINE
			)
			# Replace references (whole word only)
			content = re.sub(
				rf'\b{re.escape(old_name)}\b',
				new_name,
				content
			)
			
		try:
			with open(filepath, 'w', encoding='utf-8') as f:
				f.write(content)
			print(f"  ✓ Successfully updated {filepath}")
		except Exception as e:
			print(f"  Error writing file: {e}")


def main():
	"""Main entry point."""
	import sys
	
	# Configuration
	src_dir = "src/asm"
	report_file = "reports/code_labels_analysis.txt"
	plan_file = "reports/code_labels_rename_plan.json"
	
	# Create reports directory
	os.makedirs("reports", exist_ok=True)
	
	# Initialize analyzer
	analyzer = CodeLabelAnalyzer(src_dir)
	
	# Find all labels
	analyzer.find_all_labels()
	
	# Generate report
	analyzer.generate_report(report_file)
	
	# Generate rename plan
	analyzer.generate_rename_plan(plan_file)
	
	# Show sample of suggestions
	print("\n" + "=" * 80)
	print("Sample Suggestions:")
	print("=" * 80)
	
	sample_count = 0
	for label, info in sorted(analyzer.labels.items()):
		if info['suggested_name'] != f"UNKNOWN_{label.replace('CODE_', '')}":
			print(f"\n{label} -> {info['suggested_name']}")
			if info['context']['section_comment']:
				print(f"  {info['context']['section_comment']}")
			sample_count += 1
			if sample_count >= 20:
				break
	
	print(f"\n\nSee full report in: {report_file}")
	print(f"See rename plan in: {plan_file}")


if __name__ == '__main__':
	main()
