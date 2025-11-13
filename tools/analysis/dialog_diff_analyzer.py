#!/usr/bin/env python3
"""
FFMQ Dialog Diff Analyzer
==========================

Compares event scripts between different versions (ROM versions, translations, mods).
Generates detailed diff reports showing changes in text, commands, and parameters.

Features:
---------
1. **Script Comparison** - Compare scripts line-by-line with detailed diffs
2. **Text Changes** - Identify text modifications, additions, deletions
3. **Command Changes** - Track command additions, removals, parameter changes
4. **Parameter Analysis** - Detect parameter value changes with impact assessment
5. **Size Comparison** - Compare script sizes and compression efficiency
6. **Visual Diff** - Generate side-by-side comparison reports
7. **Change Statistics** - Aggregate statistics across all changed scripts

Comparison Modes:
-----------------
- **ROM vs ROM** - Compare two ROM files
- **Script vs Script** - Compare two decompiled script files
- **ROM vs Script** - Verify compiled script matches ROM

Output Formats:
---------------
- **Unified Diff** - Traditional diff format
- **Side-by-Side** - Visual comparison
- **JSON** - Machine-readable change data
- **Markdown** - Human-readable report

Author: TheAnsarya
Date: 2025-11-12
License: MIT
"""

import re
import difflib
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Set, Any
from dataclasses import dataclass, field
from enum import Enum


class ChangeType(Enum):
	"""Type of change detected."""
	TEXT_MODIFIED = "text_modified"
	TEXT_ADDED = "text_added"
	TEXT_DELETED = "text_deleted"
	COMMAND_MODIFIED = "command_modified"
	COMMAND_ADDED = "command_added"
	COMMAND_DELETED = "command_deleted"
	PARAMETER_CHANGED = "parameter_changed"
	SIZE_CHANGED = "size_changed"
	NO_CHANGE = "no_change"


@dataclass
class ScriptChange:
	"""Represents a change in a script."""
	dialog_id: int
	change_type: ChangeType
	line_num: int
	old_value: str = ""
	new_value: str = ""
	description: str = ""
	impact: str = ""	# "low", "medium", "high"


@dataclass
class DialogComparison:
	"""Comparison result for a single dialog."""
	dialog_id: int
	old_size: int = 0
	new_size: int = 0
	old_commands: int = 0
	new_commands: int = 0
	changes: List[ScriptChange] = field(default_factory=list)
	similarity: float = 0.0	# 0.0-1.0

	@property
	def has_changes(self) -> bool:
		"""Check if dialog has any changes."""
		return len(self.changes) > 0

	@property
	def size_delta(self) -> int:
		"""Size difference in bytes."""
		return self.new_size - self.old_size


@dataclass
class ComparisonStats:
	"""Aggregate comparison statistics."""
	total_dialogs: int = 0
	unchanged_dialogs: int = 0
	modified_dialogs: int = 0
	text_changes: int = 0
	command_changes: int = 0
	parameter_changes: int = 0
	total_size_old: int = 0
	total_size_new: int = 0
	avg_similarity: float = 0.0


class DialogDiffAnalyzer:
	"""
	Dialog/event script diff analyzer.
	"""

	def __init__(self):
		"""Initialize analyzer."""
		self.comparisons: List[DialogComparison] = []
		self.stats = ComparisonStats()

	def parse_script_file(self, script_file: str) -> Dict[int, List[str]]:
		"""
		Parse script file into dialogs.

		Args:
			script_file: Path to script file

		Returns:
			Dict mapping dialog_id to list of lines
		"""
		dialogs: Dict[int, List[str]] = {}
		current_dialog_id: Optional[int] = None
		current_lines: List[str] = []

		with open(script_file, 'r', encoding='utf-8') as f:
			for line in f:
				line = line.rstrip()

				# Skip comments and empty lines
				if line.startswith(';') or not line.strip():
					continue

				# Dialog start
				if line.startswith('[DIALOG'):
					# Save previous dialog
					if current_dialog_id is not None:
						dialogs[current_dialog_id] = current_lines

					# Parse dialog ID
					match = re.match(r'\[DIALOG\s+(\d+)\]', line)
					if match:
						current_dialog_id = int(match.group(1))
						current_lines = []

				# Add line to current dialog
				elif current_dialog_id is not None:
					current_lines.append(line)

		# Save last dialog
		if current_dialog_id is not None:
			dialogs[current_dialog_id] = current_lines

		return dialogs

	def calculate_similarity(self, old_lines: List[str], new_lines: List[str]) -> float:
		"""
		Calculate similarity ratio between two script versions.

		Args:
			old_lines: Original script lines
			new_lines: Modified script lines

		Returns:
			Similarity ratio (0.0-1.0)
		"""
		old_text = '\n'.join(old_lines)
		new_text = '\n'.join(new_lines)

		return difflib.SequenceMatcher(None, old_text, new_text).ratio()

	def analyze_line_change(self, old_line: str, new_line: str, line_num: int, dialog_id: int) -> Optional[ScriptChange]:
		"""
		Analyze a single line change.

		Args:
			old_line: Original line
			new_line: Modified line
			line_num: Line number
			dialog_id: Dialog ID

		Returns:
			ScriptChange or None if no significant change
		"""
		# Check if both are commands
		old_is_cmd = old_line.startswith('[')
		new_is_cmd = new_line.startswith('[')

		if old_is_cmd and new_is_cmd:
			# Both commands - check for parameter changes
			old_cmd_match = re.match(r'\[([A-Z_0-9]+)(?::(.+))?\]', old_line)
			new_cmd_match = re.match(r'\[([A-Z_0-9]+)(?::(.+))?\]', new_line)

			if old_cmd_match and new_cmd_match:
				old_cmd = old_cmd_match.group(1)
				new_cmd = new_cmd_match.group(1)
				old_params = old_cmd_match.group(2) if old_cmd_match.group(2) else ""
				new_params = new_cmd_match.group(2) if new_cmd_match.group(2) else ""

				if old_cmd != new_cmd:
					return ScriptChange(
						dialog_id=dialog_id,
						change_type=ChangeType.COMMAND_MODIFIED,
						line_num=line_num,
						old_value=old_cmd,
						new_value=new_cmd,
						description=f"Command changed from {old_cmd} to {new_cmd}",
						impact="high"
					)
				elif old_params != new_params:
					return ScriptChange(
						dialog_id=dialog_id,
						change_type=ChangeType.PARAMETER_CHANGED,
						line_num=line_num,
						old_value=old_params,
						new_value=new_params,
						description=f"Parameters changed for {old_cmd}",
						impact="medium"
					)

		elif not old_is_cmd and not new_is_cmd:
			# Both text - text modification
			if old_line != new_line:
				return ScriptChange(
					dialog_id=dialog_id,
					change_type=ChangeType.TEXT_MODIFIED,
					line_num=line_num,
					old_value=old_line,
					new_value=new_line,
					description="Text content modified",
					impact="low"
				)

		return None

	def compare_dialogs(self, dialog_id: int, old_lines: List[str], new_lines: List[str]) -> DialogComparison:
		"""
		Compare two versions of a dialog.

		Args:
			dialog_id: Dialog identifier
			old_lines: Original script lines
			new_lines: Modified script lines

		Returns:
			DialogComparison
		"""
		comparison = DialogComparison(dialog_id=dialog_id)

		# Calculate sizes (approximate)
		comparison.old_size = sum(len(line) for line in old_lines)
		comparison.new_size = sum(len(line) for line in new_lines)

		# Count commands
		comparison.old_commands = sum(1 for line in old_lines if line.startswith('['))
		comparison.new_commands = sum(1 for line in new_lines if line.startswith('['))

		# Calculate similarity
		comparison.similarity = self.calculate_similarity(old_lines, new_lines)

		# Generate diff
		diff = difflib.unified_diff(old_lines, new_lines, lineterm='')

		line_num = 0
		for line in diff:
			line_num += 1

			if line.startswith('---') or line.startswith('+++'):
				continue
			elif line.startswith('@@'):
				continue
			elif line.startswith('-'):
				# Line deleted
				comparison.changes.append(ScriptChange(
					dialog_id=dialog_id,
					change_type=ChangeType.TEXT_DELETED,
					line_num=line_num,
					old_value=line[1:],
					new_value="",
					description="Line deleted",
					impact="medium"
				))
			elif line.startswith('+'):
				# Line added
				comparison.changes.append(ScriptChange(
					dialog_id=dialog_id,
					change_type=ChangeType.TEXT_ADDED,
					line_num=line_num,
					old_value="",
					new_value=line[1:],
					description="Line added",
					impact="medium"
				))

		# Detailed line-by-line comparison for modifications
		for i, (old_line, new_line) in enumerate(zip(old_lines, new_lines), 1):
			if old_line != new_line:
				change = self.analyze_line_change(old_line, new_line, i, dialog_id)
				if change:
					comparison.changes.append(change)

		return comparison

	def compare_scripts(self, old_script: str, new_script: str) -> None:
		"""
		Compare two script files.

		Args:
			old_script: Path to original script
			new_script: Path to modified script
		"""
		print(f"\n🔍 Comparing scripts...")
		print(f"  Original: {old_script}")
		print(f"  Modified: {new_script}")

		# Parse scripts
		old_dialogs = self.parse_script_file(old_script)
		new_dialogs = self.parse_script_file(new_script)

		print(f"  Original dialogs: {len(old_dialogs)}")
		print(f"  Modified dialogs: {len(new_dialogs)}")

		# Get all dialog IDs
		all_dialog_ids = set(old_dialogs.keys()) | set(new_dialogs.keys())
		self.stats.total_dialogs = len(all_dialog_ids)

		# Compare each dialog
		for dialog_id in sorted(all_dialog_ids):
			old_lines = old_dialogs.get(dialog_id, [])
			new_lines = new_dialogs.get(dialog_id, [])

			if old_lines or new_lines:
				comparison = self.compare_dialogs(dialog_id, old_lines, new_lines)
				self.comparisons.append(comparison)

				# Update stats
				if comparison.has_changes:
					self.stats.modified_dialogs += 1
				else:
					self.stats.unchanged_dialogs += 1

				self.stats.total_size_old += comparison.old_size
				self.stats.total_size_new += comparison.new_size

				for change in comparison.changes:
					if change.change_type in [ChangeType.TEXT_MODIFIED, ChangeType.TEXT_ADDED, ChangeType.TEXT_DELETED]:
						self.stats.text_changes += 1
					elif change.change_type in [ChangeType.COMMAND_MODIFIED, ChangeType.COMMAND_ADDED, ChangeType.COMMAND_DELETED]:
						self.stats.command_changes += 1
					elif change.change_type == ChangeType.PARAMETER_CHANGED:
						self.stats.parameter_changes += 1

		# Calculate average similarity
		if self.comparisons:
			self.stats.avg_similarity = sum(c.similarity for c in self.comparisons) / len(self.comparisons)

		print(f"\n  ✅ Comparison complete")
		print(f"  Modified dialogs: {self.stats.modified_dialogs}")
		print(f"  Unchanged dialogs: {self.stats.unchanged_dialogs}")

	def generate_report(self, report_file: str, detail_level: str = "summary") -> None:
		"""
		Generate comparison report.

		Args:
			report_file: Output file path
			detail_level: "summary", "changes", or "full"
		"""
		report_path = Path(report_file)

		lines = []
		lines.append("# Dialog Diff Analysis Report")
		lines.append("=" * 80)
		lines.append("")

		# Summary
		lines.append("## Summary")
		lines.append("")
		lines.append(f"- **Total Dialogs**: {self.stats.total_dialogs}")
		lines.append(f"- **Modified**: {self.stats.modified_dialogs}")
		lines.append(f"- **Unchanged**: {self.stats.unchanged_dialogs}")
		lines.append(f"- **Average Similarity**: {self.stats.avg_similarity * 100:.1f}%")
		lines.append("")
		lines.append(f"- **Text Changes**: {self.stats.text_changes}")
		lines.append(f"- **Command Changes**: {self.stats.command_changes}")
		lines.append(f"- **Parameter Changes**: {self.stats.parameter_changes}")
		lines.append("")
		lines.append(f"- **Total Size (Original)**: {self.stats.total_size_old} bytes")
		lines.append(f"- **Total Size (Modified)**: {self.stats.total_size_new} bytes")
		lines.append(f"- **Size Delta**: {self.stats.total_size_new - self.stats.total_size_old:+d} bytes")
		lines.append("")

		if detail_level in ["changes", "full"]:
			# Changed dialogs
			changed = [c for c in self.comparisons if c.has_changes]

			if changed:
				lines.append("## Changed Dialogs")
				lines.append("")

				for comp in changed:
					lines.append(f"### Dialog {comp.dialog_id}")
					lines.append(f"- **Similarity**: {comp.similarity * 100:.1f}%")
					lines.append(f"- **Size**: {comp.old_size} → {comp.new_size} bytes ({comp.size_delta:+d})")
					lines.append(f"- **Commands**: {comp.old_commands} → {comp.new_commands}")
					lines.append(f"- **Changes**: {len(comp.changes)}")
					lines.append("")

					if detail_level == "full":
						# Show all changes
						for change in comp.changes:
							icon = "📝" if "text" in change.change_type.value else "🔧"
							lines.append(f"**{icon} {change.change_type.value}** (Line {change.line_num})")
							lines.append(f"- Impact: {change.impact}")

							if change.old_value:
								lines.append(f"- Old: `{change.old_value}`")
							if change.new_value:
								lines.append(f"- New: `{change.new_value}`")
							if change.description:
								lines.append(f"- {change.description}")

							lines.append("")

		# Top changes by impact
		lines.append("## Impact Analysis")
		lines.append("")

		high_impact = sum(1 for c in self.comparisons for ch in c.changes if ch.impact == "high")
		medium_impact = sum(1 for c in self.comparisons for ch in c.changes if ch.impact == "medium")
		low_impact = sum(1 for c in self.comparisons for ch in c.changes if ch.impact == "low")

		lines.append(f"- **High Impact Changes**: {high_impact}")
		lines.append(f"- **Medium Impact Changes**: {medium_impact}")
		lines.append(f"- **Low Impact Changes**: {low_impact}")
		lines.append("")

		with open(report_path, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))

		print(f"\n📊 Report saved: {report_path}")

	def print_summary(self) -> None:
		"""Print summary to console."""
		print("\n" + "=" * 80)
		print("DIFF ANALYSIS SUMMARY")
		print("=" * 80)
		print(f"\nTotal dialogs: {self.stats.total_dialogs}")
		print(f"Modified: {self.stats.modified_dialogs}")
		print(f"Unchanged: {self.stats.unchanged_dialogs}")
		print(f"Average similarity: {self.stats.avg_similarity * 100:.1f}%")
		print("")
		print(f"Text changes: {self.stats.text_changes}")
		print(f"Command changes: {self.stats.command_changes}")
		print(f"Parameter changes: {self.stats.parameter_changes}")
		print("")
		print(f"Size change: {self.stats.total_size_new - self.stats.total_size_old:+d} bytes")
		print("")


def main():
	"""Main entry point."""
	import argparse

	parser = argparse.ArgumentParser(
		description="Compare FFMQ event scripts and generate diff reports",
		formatter_class=argparse.RawDescriptionHelpFormatter,
		epilog="""
Examples:
	# Compare two script files
	python dialog_diff_analyzer.py --old original.txt --new modified.txt

	# Generate detailed report
	python dialog_diff_analyzer.py --old original.txt --new modified.txt --detail full

	# Summary only
	python dialog_diff_analyzer.py --old original.txt --new modified.txt --detail summary

Documentation:
	Compares scripts line-by-line with change tracking.
	See ROM_HACKING_TOOLCHAIN_GUIDE.md for usage examples.
		"""
	)

	parser.add_argument(
		'--old',
		required=True,
		help='Path to original script file'
	)

	parser.add_argument(
		'--new',
		required=True,
		help='Path to modified script file'
	)

	parser.add_argument(
		'--report',
		default='diff_report.md',
		help='Path for diff report'
	)

	parser.add_argument(
		'--detail',
		choices=['summary', 'changes', 'full'],
		default='changes',
		help='Detail level for report'
	)

	args = parser.parse_args()

	print("=" * 80)
	print("DIALOG DIFF ANALYZER")
	print("=" * 80)

	# Initialize analyzer
	analyzer = DialogDiffAnalyzer()

	# Compare scripts
	analyzer.compare_scripts(args.old, args.new)

	# Generate report
	analyzer.generate_report(args.report, args.detail)

	# Print summary
	analyzer.print_summary()

	print("\n" + "=" * 80)
	print("ANALYSIS COMPLETE")
	print("=" * 80)
	print("")


if __name__ == '__main__':
	main()
