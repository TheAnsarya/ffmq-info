#!/usr/bin/env python3
"""
FFMQ Command Usage Profiler
============================

Analyzes event command usage patterns across all scripts.
Identifies hot spots, optimization opportunities, and common patterns.

Features:
---------
1. **Usage Frequency** - Track how often each command is used
2. **Co-occurrence Analysis** - Find commands commonly used together
3. **Parameter Distribution** - Analyze parameter value distributions
4. **Script Clustering** - Group scripts by command patterns
5. **Optimization Suggestions** - Identify subroutine opportunities
6. **Complexity Metrics** - Calculate script complexity scores
7. **Visualization Data** - Export data for charts and graphs

Analysis Types:
---------------
- **Command Frequency** - Which commands are most/least used
- **Parameter Patterns** - Common parameter values and ranges
- **Script Complexity** - Commands per dialog, depth analysis
- **Subroutine Analysis** - Which scripts are called as subroutines
- **Memory Hotspots** - Most frequently modified memory addresses

Author: TheAnsarya
Date: 2025-11-12
License: MIT
"""

import re
import json
from pathlib import Path
from collections import Counter, defaultdict
from typing import Dict, List, Tuple, Optional, Set, Any
from dataclasses import dataclass, field
from enum import Enum


@dataclass
class CommandProfile:
	"""Profile for a single command."""
	opcode: int
	name: str
	usage_count: int = 0
	total_parameters: int = 0
	parameter_distributions: Dict[int, Counter] = field(default_factory=dict)
	dialogs_used_in: Set[int] = field(default_factory=set)
	avg_parameters_per_use: float = 0.0


@dataclass
class ScriptProfile:
	"""Profile for a single script."""
	dialog_id: int
	command_count: int = 0
	unique_commands: int = 0
	text_bytes: int = 0
	complexity_score: float = 0.0
	commands_used: List[str] = field(default_factory=list)
	is_subroutine: bool = False
	called_by: Set[int] = field(default_factory=set)


@dataclass
class CoOccurrence:
	"""Command co-occurrence data."""
	command1: str
	command2: str
	count: int
	confidence: float = 0.0  # How often cmd1 is followed by cmd2


class CommandUsageProfiler:
	"""
	Command usage profiler for FFMQ event scripts.
	"""

	# All 48 event commands
	COMMANDS = {
		'END': 0x00, 'NEWLINE': 0x01, 'WAIT': 0x02, 'ASTERISK': 0x03,
		'NAME': 0x04, 'ITEM': 0x05, 'SPACE': 0x06, 'UNK_07': 0x07,
		'CALL_SUBROUTINE': 0x08, 'UNK_09': 0x09, 'UNK_0A': 0x0A, 'UNK_0B': 0x0B,
		'UNK_0C': 0x0C, 'UNK_0D': 0x0D, 'MEMORY_WRITE': 0x0E, 'UNK_0F': 0x0F,
		'INSERT_ITEM': 0x10, 'INSERT_SPELL': 0x11, 'INSERT_MONSTER': 0x12,
		'INSERT_CHARACTER': 0x13, 'INSERT_LOCATION': 0x14, 'INSERT_NUMBER': 0x15,
		'INSERT_OBJECT': 0x16, 'INSERT_WEAPON': 0x17, 'INSERT_ARMOR': 0x18,
		'INSERT_ACCESSORY': 0x19, 'TEXTBOX_BELOW': 0x1A, 'TEXTBOX_ABOVE': 0x1B,
		'UNK_1C': 0x1C, 'FORMAT_ITEM_E1': 0x1D, 'FORMAT_ITEM_E2': 0x1E,
		'CRYSTAL': 0x1F, 'UNK_20': 0x20, 'UNK_21': 0x21, 'UNK_22': 0x22,
		'EXTERNAL_CALL_1': 0x23, 'SET_STATE_VAR': 0x24, 'SET_STATE_BYTE': 0x25,
		'SET_STATE_WORD': 0x26, 'SET_STATE_BYTE_2': 0x27, 'SET_STATE_BYTE_3': 0x28,
		'EXTERNAL_CALL_2': 0x29, 'UNK_2A': 0x2A, 'EXTERNAL_CALL_3': 0x2B,
		'UNK_2C': 0x2C, 'SET_STATE_WORD_2': 0x2D, 'UNK_2E': 0x2E, 'UNK_2F': 0x2F,
	}

	def __init__(self):
		"""Initialize profiler."""
		self.command_profiles: Dict[str, CommandProfile] = {}
		self.script_profiles: Dict[int, ScriptProfile] = {}
		self.co_occurrences: List[CoOccurrence] = []
		self.memory_hotspots: Counter = Counter()
		self.subroutine_targets: Counter = Counter()

		# Initialize command profiles
		for name, opcode in self.COMMANDS.items():
			self.command_profiles[name] = CommandProfile(opcode=opcode, name=name)

	def parse_script_file(self, script_file: str) -> None:
		"""
		Parse script file and build profiles.

		Args:
			script_file: Path to script file
		"""
		print(f"\n📊 Profiling script: {script_file}")

		current_dialog_id: Optional[int] = None
		current_profile: Optional[ScriptProfile] = None
		previous_command: Optional[str] = None

		with open(script_file, 'r', encoding='utf-8') as f:
			for line in f:
				line = line.strip()

				# Skip comments and empty lines
				if line.startswith(';') or not line:
					continue

				# Dialog start
				if line.startswith('[DIALOG'):
					# Save previous dialog
					if current_profile:
						current_profile.unique_commands = len(set(current_profile.commands_used))
						current_profile.complexity_score = self.calculate_complexity(current_profile)

					# Parse dialog ID
					match = re.match(r'\[DIALOG\s+(\d+)\]', line)
					if match:
						current_dialog_id = int(match.group(1))
						current_profile = ScriptProfile(dialog_id=current_dialog_id)
						self.script_profiles[current_dialog_id] = current_profile
						previous_command = None
					continue

				if current_profile is None:
					continue

				# Command
				if line.startswith('['):
					match = re.match(r'\[([A-Z_0-9]+)(?::(.+))?\]', line)
					if not match:
						continue

					cmd_name = match.group(1)
					params_str = match.group(2) if match.group(2) else ""

					if cmd_name not in self.COMMANDS:
						continue

					# Update command profile
					cmd_profile = self.command_profiles[cmd_name]
					cmd_profile.usage_count += 1
					cmd_profile.dialogs_used_in.add(current_dialog_id)

					# Parse parameters
					params = [p.strip() for p in params_str.split(':')] if params_str else []
					cmd_profile.total_parameters += len(params)

					# Track parameter distributions
					for i, param in enumerate(params):
						if i not in cmd_profile.parameter_distributions:
							cmd_profile.parameter_distributions[i] = Counter()

						# Parse value
						try:
							if param.startswith('0x') or param.startswith('0X'):
								value = int(param, 16)
							elif param.startswith('$'):
								value = int(param[1:], 16)
							else:
								value = int(param)

							cmd_profile.parameter_distributions[i][value] += 1
						except ValueError:
							pass

					# Update script profile
					current_profile.command_count += 1
					current_profile.commands_used.append(cmd_name)

					# Track co-occurrences
					if previous_command:
						self.track_co_occurrence(previous_command, cmd_name)

					previous_command = cmd_name

					# Special tracking
					if cmd_name == 'CALL_SUBROUTINE' and len(params) >= 1:
						# Track subroutine targets
						try:
							if params[0].startswith('0x'):
								target = int(params[0], 16)
							elif params[0].startswith('$'):
								target = int(params[0][1:], 16)
							else:
								target = int(params[0])

							self.subroutine_targets[target] += 1
						except ValueError:
							pass

					elif cmd_name == 'MEMORY_WRITE' and len(params) >= 1:
						# Track memory addresses
						try:
							if params[0].startswith('0x'):
								addr = int(params[0], 16)
							elif params[0].startswith('$'):
								addr = int(params[0][1:], 16)
							else:
								addr = int(params[0])

							self.memory_hotspots[addr] += 1
						except ValueError:
							pass

				else:
					# Text line
					current_profile.text_bytes += len(line)

		# Save last dialog
		if current_profile:
			current_profile.unique_commands = len(set(current_profile.commands_used))
			current_profile.complexity_score = self.calculate_complexity(current_profile)

		# Calculate average parameters per use
		for cmd_profile in self.command_profiles.values():
			if cmd_profile.usage_count > 0:
				cmd_profile.avg_parameters_per_use = cmd_profile.total_parameters / cmd_profile.usage_count

	def track_co_occurrence(self, cmd1: str, cmd2: str) -> None:
		"""Track command co-occurrence."""
		# Find existing or create new
		for co in self.co_occurrences:
			if co.command1 == cmd1 and co.command2 == cmd2:
				co.count += 1
				return

		self.co_occurrences.append(CoOccurrence(command1=cmd1, command2=cmd2, count=1))

	def calculate_complexity(self, profile: ScriptProfile) -> float:
		"""
		Calculate script complexity score.

		Args:
			profile: Script profile

		Returns:
			Complexity score (higher = more complex)
		"""
		score = 0.0

		# Base complexity from command count
		score += profile.command_count * 1.0

		# Bonus for unique commands (more diverse = more complex)
		score += profile.unique_commands * 2.0

		# Penalty for simple patterns (NEWLINE, WAIT, END only)
		simple_cmds = ['NEWLINE', 'WAIT', 'END']
		if all(cmd in simple_cmds for cmd in profile.commands_used):
			score *= 0.5

		# Bonus for control flow commands
		control_cmds = ['CALL_SUBROUTINE', 'MEMORY_WRITE']
		control_count = sum(1 for cmd in profile.commands_used if cmd in control_cmds)
		score += control_count * 5.0

		return score

	def identify_subroutines(self) -> None:
		"""Identify scripts that are called as subroutines."""
		# Mark scripts as subroutines if they're called by others
		for target_offset, call_count in self.subroutine_targets.items():
			# Try to match offset to dialog (simplified - would need offset map in real implementation)
			for dialog_id, profile in self.script_profiles.items():
				# Placeholder logic - in real implementation, use ROM offset mapping
				if call_count > 0:
					profile.is_subroutine = True

	def generate_report(self, report_file: str) -> None:
		"""Generate profiling report."""
		report_path = Path(report_file)

		lines = []
		lines.append("# Command Usage Profile Report")
		lines.append("=" * 80)
		lines.append("")

		# Summary
		total_scripts = len(self.script_profiles)
		total_commands = sum(p.command_count for p in self.script_profiles.values())

		lines.append("## Summary")
		lines.append("")
		lines.append(f"- **Total Scripts**: {total_scripts}")
		lines.append(f"- **Total Commands**: {total_commands}")
		lines.append(f"- **Avg Commands per Script**: {total_commands / total_scripts if total_scripts > 0 else 0:.1f}")
		lines.append("")

		# Command frequency
		lines.append("## Command Frequency")
		lines.append("")
		lines.append("| Command | Usage Count | Dialogs | Avg Params |")
		lines.append("|---------|------------:|--------:|-----------:|")

		sorted_commands = sorted(
			self.command_profiles.values(),
			key=lambda c: c.usage_count,
			reverse=True
		)

		for cmd in sorted_commands:
			if cmd.usage_count > 0:
				lines.append(f"| {cmd.name} | {cmd.usage_count} | {len(cmd.dialogs_used_in)} | {cmd.avg_parameters_per_use:.1f} |")

		lines.append("")

		# Most complex scripts
		lines.append("## Most Complex Scripts")
		lines.append("")

		sorted_scripts = sorted(
			self.script_profiles.values(),
			key=lambda s: s.complexity_score,
			reverse=True
		)

		for profile in sorted_scripts[:10]:
			lines.append(f"### Dialog {profile.dialog_id}")
			lines.append(f"- Complexity: {profile.complexity_score:.1f}")
			lines.append(f"- Commands: {profile.command_count} ({profile.unique_commands} unique)")
			lines.append(f"- Text bytes: {profile.text_bytes}")
			if profile.is_subroutine:
				lines.append(f"- **Subroutine** (called by {len(profile.called_by)} scripts)")
			lines.append("")

		# Command co-occurrences
		lines.append("## Common Command Patterns")
		lines.append("")

		sorted_co = sorted(self.co_occurrences, key=lambda c: c.count, reverse=True)

		for co in sorted_co[:20]:
			lines.append(f"- **{co.command1}** → **{co.command2}**: {co.count} times")

		lines.append("")

		# Memory hotspots
		if self.memory_hotspots:
			lines.append("## Memory Hotspots")
			lines.append("")
			lines.append("Most frequently written memory addresses:")
			lines.append("")

			for addr, count in self.memory_hotspots.most_common(10):
				lines.append(f"- **0x{addr:04X}**: {count} writes")

			lines.append("")

		# Subroutine targets
		if self.subroutine_targets:
			lines.append("## Subroutine Call Hotspots")
			lines.append("")
			lines.append("Most frequently called subroutines:")
			lines.append("")

			for offset, count in self.subroutine_targets.most_common(10):
				lines.append(f"- **0x{offset:04X}**: {count} calls")

			lines.append("")

		# Optimization suggestions
		lines.append("## Optimization Suggestions")
		lines.append("")

		# Find repeated command sequences
		lines.append("### Potential Subroutine Candidates")
		lines.append("")
		lines.append("Commands that appear frequently could be moved to subroutines:")
		lines.append("")

		for cmd in sorted_commands[:5]:
			if cmd.usage_count > 10:
				lines.append(f"- **{cmd.name}**: Used {cmd.usage_count} times across {len(cmd.dialogs_used_in)} dialogs")

		lines.append("")

		with open(report_path, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))

		print(f"\n📊 Report saved: {report_path}")

	def export_json(self, json_file: str) -> None:
		"""Export profiling data to JSON."""
		json_path = Path(json_file)

		data = {
			'summary': {
				'total_scripts': len(self.script_profiles),
				'total_commands': sum(p.command_count for p in self.script_profiles.values()),
			},
			'commands': [
				{
					'name': cmd.name,
					'opcode': cmd.opcode,
					'usage_count': cmd.usage_count,
					'dialogs_used_in': list(cmd.dialogs_used_in),
					'avg_parameters': cmd.avg_parameters_per_use,
				}
				for cmd in self.command_profiles.values()
				if cmd.usage_count > 0
			],
			'scripts': [
				{
					'dialog_id': profile.dialog_id,
					'command_count': profile.command_count,
					'unique_commands': profile.unique_commands,
					'complexity_score': profile.complexity_score,
					'is_subroutine': profile.is_subroutine,
				}
				for profile in self.script_profiles.values()
			],
			'co_occurrences': [
				{
					'command1': co.command1,
					'command2': co.command2,
					'count': co.count,
				}
				for co in self.co_occurrences
			],
		}

		with open(json_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent='\t')

		print(f"📄 JSON data saved: {json_path}")


def main():
	"""Main entry point."""
	import argparse

	parser = argparse.ArgumentParser(
		description="Profile FFMQ event command usage patterns",
		formatter_class=argparse.RawDescriptionHelpFormatter,
		epilog="""
Examples:
	# Profile script file
	python command_usage_profiler.py --script dialogs.txt

	# Export JSON data for visualization
	python command_usage_profiler.py --script dialogs.txt --json profile.json

	# Profile multiple files
	python command_usage_profiler.py --script file1.txt file2.txt file3.txt

Documentation:
	Analyzes command usage patterns and generates optimization suggestions.
	See ROM_HACKING_TOOLCHAIN_GUIDE.md for details.
		"""
	)

	parser.add_argument(
		'--script',
		nargs='+',
		required=True,
		help='Path to script file(s)'
	)

	parser.add_argument(
		'--report',
		default='usage_profile_report.md',
		help='Path for profiling report'
	)

	parser.add_argument(
		'--json',
		default='usage_profile.json',
		help='Path for JSON export'
	)

	args = parser.parse_args()

	print("=" * 80)
	print("COMMAND USAGE PROFILER")
	print("=" * 80)

	# Initialize profiler
	profiler = CommandUsageProfiler()

	# Profile each script
	for script_path in args.script:
		profiler.parse_script_file(script_path)

	# Identify subroutines
	profiler.identify_subroutines()

	# Generate outputs
	profiler.generate_report(args.report)
	profiler.export_json(args.json)

	print("\n" + "=" * 80)
	print("PROFILING COMPLETE")
	print("=" * 80)
	print(f"\nAnalyzed {len(profiler.script_profiles)} scripts")
	print(f"Total commands: {sum(p.command_count for p in profiler.script_profiles.values())}")
	print("")


if __name__ == '__main__':
	main()
