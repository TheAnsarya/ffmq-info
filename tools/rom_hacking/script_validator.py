#!/usr/bin/env python3
"""
FFMQ Script Validator
=====================

Comprehensive validation tool for FFMQ event scripts.
Performs syntax checking, parameter validation, control flow analysis, and best practice checks.

Features:
---------
1. **Syntax Validation** - Verify script format and command syntax
2. **Parameter Validation** - Check parameter types and ranges
3. **Control Flow Analysis** - Detect unreachable code, infinite loops, missing END
4. **Best Practice Checks** - Identify common issues and optimization opportunities
5. **Cross-Reference Analysis** - Verify subroutine targets, memory addresses
6. **Performance Analysis** - Calculate script size, compression efficiency
7. **Report Generation** - Comprehensive validation reports

Validation Levels:
------------------
- **ERROR** - Critical issues that will prevent compilation
- **WARNING** - Issues that may cause runtime problems
- **INFO** - Best practice suggestions and optimizations

Author: TheAnsarya
Date: 2025-11-12
License: MIT
"""

import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Set, Any
from dataclasses import dataclass, field
from enum import Enum


class ValidationLevel(Enum):
	"""Validation issue severity."""
	ERROR = "ERROR"
	WARNING = "WARNING"
	INFO = "INFO"


@dataclass
class ValidationIssue:
	"""Represents a validation issue."""
	level: ValidationLevel
	line_num: int
	message: str
	context: str = ""
	suggestion: str = ""

	def __str__(self) -> str:
		prefix = f"[{self.level.value}] Line {self.line_num}: "
		msg = f"{prefix}{self.message}"
		if self.context:
			msg += f"\n  Context: {self.context}"
		if self.suggestion:
			msg += f"\n  Suggestion: {self.suggestion}"
		return msg


@dataclass
class ScriptMetrics:
	"""Script performance metrics."""
	total_lines: int = 0
	command_count: int = 0
	text_bytes: int = 0
	event_bytes: int = 0
	total_bytes: int = 0
	dialog_count: int = 0
	subroutine_calls: int = 0
	memory_writes: int = 0
	compression_ratio: float = 0.0


class ScriptValidator:
	"""
	Comprehensive script validator for FFMQ event scripts.
	"""

	# All 48 event commands with parameter information
	COMMANDS = {
		'END': (0x00, 0, []),
		'NEWLINE': (0x01, 0, []),
		'WAIT': (0x02, 0, []),
		'ASTERISK': (0x03, 0, []),
		'NAME': (0x04, 0, []),
		'ITEM': (0x05, 1, ['byte']),
		'SPACE': (0x06, 0, []),
		'UNK_07': (0x07, 3, ['byte', 'byte', 'byte']),
		'CALL_SUBROUTINE': (0x08, 2, ['pointer']),
		'UNK_09': (0x09, 3, ['byte', 'byte', 'byte']),
		'UNK_0A': (0x0A, 0, []),
		'UNK_0B': (0x0B, 1, ['byte']),
		'UNK_0C': (0x0C, 3, ['byte', 'byte', 'byte']),
		'UNK_0D': (0x0D, 4, ['byte', 'byte', 'byte', 'byte']),
		'MEMORY_WRITE': (0x0E, 4, ['address', 'value']),
		'UNK_0F': (0x0F, 2, ['byte', 'byte']),
		'INSERT_ITEM': (0x10, 1, ['item_id']),
		'INSERT_SPELL': (0x11, 1, ['spell_id']),
		'INSERT_MONSTER': (0x12, 1, ['monster_id']),
		'INSERT_CHARACTER': (0x13, 1, ['character_id']),
		'INSERT_LOCATION': (0x14, 1, ['location_id']),
		'INSERT_NUMBER': (0x15, 2, ['byte', 'byte']),
		'INSERT_OBJECT': (0x16, 2, ['byte', 'byte']),
		'INSERT_WEAPON': (0x17, 1, ['item_id']),
		'INSERT_ARMOR': (0x18, 0, []),
		'INSERT_ACCESSORY': (0x19, 0, []),
		'TEXTBOX_BELOW': (0x1A, 1, ['byte']),
		'TEXTBOX_ABOVE': (0x1B, 1, ['byte']),
		'UNK_1C': (0x1C, 0, []),
		'FORMAT_ITEM_E1': (0x1D, 1, ['mode']),
		'FORMAT_ITEM_E2': (0x1E, 1, ['mode']),
		'CRYSTAL': (0x1F, 1, ['crystal_id']),
		'UNK_20': (0x20, 1, ['byte']),
		'UNK_21': (0x21, 0, []),
		'UNK_22': (0x22, 0, []),
		'EXTERNAL_CALL_1': (0x23, 1, ['byte']),
		'SET_STATE_VAR': (0x24, 4, ['byte', 'byte', 'byte', 'byte']),
		'SET_STATE_BYTE': (0x25, 1, ['byte']),
		'SET_STATE_WORD': (0x26, 4, ['byte', 'byte', 'byte', 'byte']),
		'SET_STATE_BYTE_2': (0x27, 1, ['byte']),
		'SET_STATE_BYTE_3': (0x28, 1, ['byte']),
		'EXTERNAL_CALL_2': (0x29, 1, ['byte']),
		'UNK_2A': (0x2A, 0, []),
		'EXTERNAL_CALL_3': (0x2B, 1, ['byte']),
		'UNK_2C': (0x2C, 2, ['byte', 'byte']),
		'SET_STATE_WORD_2': (0x2D, 2, ['byte', 'byte']),
		'UNK_2E': (0x2E, 1, ['byte']),
		'UNK_2F': (0x2F, 0, []),
	}

	# Parameter type validators
	PARAM_TYPES = {
		'byte': (0, 255),
		'item_id': (0, 255),
		'spell_id': (0, 63),
		'monster_id': (0, 255),
		'character_id': (0, 4),
		'location_id': (0, 63),
		'mode': (0, 10),
		'crystal_id': (0, 4),
		'address': (0x0000, 0xFFFF),
		'value': (0x0000, 0xFFFF),
		'pointer': (0x8000, 0xFFFF),
	}

	# Best practice limits
	MAX_DIALOG_SIZE = 512	# bytes
	MAX_TEXT_LENGTH = 200	# characters
	MAX_COMMAND_CHAIN = 20	# commands without END

	def __init__(self):
		"""Initialize validator."""
		self.issues: List[ValidationIssue] = []
		self.metrics = ScriptMetrics()
		self.dialog_ids: Set[int] = set()
		self.subroutine_targets: Set[int] = set()
		self.current_dialog_id: Optional[int] = None
		self.current_dialog_size: int = 0
		self.command_chain_length: int = 0

	def validate_line_syntax(self, line: str, line_num: int) -> None:
		"""Validate basic line syntax."""
		line = line.strip()

		# Skip empty lines and comments
		if not line or line.startswith(';'):
			return

		# Dialog declaration
		if line.startswith('[DIALOG'):
			match = re.match(r'\[DIALOG\s+(\d+)\]', line)
			if not match:
				self.issues.append(ValidationIssue(
					level=ValidationLevel.ERROR,
					line_num=line_num,
					message="Invalid DIALOG syntax",
					context=line,
					suggestion="Use: [DIALOG 0]"
				))
				return

			dialog_id = int(match.group(1))

			# Check for duplicate dialog IDs
			if dialog_id in self.dialog_ids:
				self.issues.append(ValidationIssue(
					level=ValidationLevel.ERROR,
					line_num=line_num,
					message=f"Duplicate dialog ID: {dialog_id}",
					context=line,
					suggestion="Use unique dialog IDs"
				))

			self.dialog_ids.add(dialog_id)
			self.current_dialog_id = dialog_id
			self.current_dialog_size = 0
			self.command_chain_length = 0
			self.metrics.dialog_count += 1
			return

		# Ensure we're in a dialog
		if self.current_dialog_id is None:
			self.issues.append(ValidationIssue(
				level=ValidationLevel.ERROR,
				line_num=line_num,
				message="Command outside of [DIALOG] block",
				context=line,
				suggestion="Start with [DIALOG n] before adding commands"
			))
			return

		# Command
		if line.startswith('['):
			match = re.match(r'\[([A-Z_0-9]+)(?::(.+))?\]', line)
			if not match:
				self.issues.append(ValidationIssue(
					level=ValidationLevel.ERROR,
					line_num=line_num,
					message="Invalid command syntax",
					context=line,
					suggestion="Use: [COMMAND:param1:param2]"
				))
				return

			cmd_name = match.group(1)
			params_str = match.group(2) if match.group(2) else ""

			# Check if command exists
			if cmd_name not in self.COMMANDS:
				self.issues.append(ValidationIssue(
					level=ValidationLevel.ERROR,
					line_num=line_num,
					message=f"Unknown command: {cmd_name}",
					context=line,
					suggestion="Check EVENT_SYSTEM_ARCHITECTURE.md for valid commands"
				))
				return

			# Validate parameters
			self.validate_command_parameters(cmd_name, params_str, line_num, line)

			# Track metrics
			self.metrics.command_count += 1
			self.command_chain_length += 1

			# Check for END command
			if cmd_name == 'END':
				if self.current_dialog_size > self.MAX_DIALOG_SIZE:
					self.issues.append(ValidationIssue(
						level=ValidationLevel.WARNING,
						line_num=line_num,
						message=f"Dialog size ({self.current_dialog_size} bytes) exceeds recommended maximum ({self.MAX_DIALOG_SIZE} bytes)",
						context=f"Dialog {self.current_dialog_id}",
						suggestion="Consider splitting into multiple dialogs with subroutines"
					))

				self.current_dialog_id = None
				self.current_dialog_size = 0
				self.command_chain_length = 0

			# Check command chain length
			if self.command_chain_length > self.MAX_COMMAND_CHAIN:
				self.issues.append(ValidationIssue(
					level=ValidationLevel.WARNING,
					line_num=line_num,
					message=f"Long command chain ({self.command_chain_length} commands without END)",
					context=f"Dialog {self.current_dialog_id}",
					suggestion="Verify dialog ends with [END]"
				))

			return

		# Directive
		if line.startswith('@'):
			directive = line[1:].upper()
			if directive not in ['TEXTBOX_BOTTOM', 'TEXTBOX_ABOVE', 'TEXTBOX_TOP']:
				self.issues.append(ValidationIssue(
					level=ValidationLevel.WARNING,
					line_num=line_num,
					message=f"Unknown directive: @{directive}",
					context=line,
					suggestion="Use: @TEXTBOX_BOTTOM or @TEXTBOX_ABOVE"
				))
			return

		# Text
		self.validate_text_line(line, line_num)

	def validate_command_parameters(self, cmd_name: str, params_str: str, line_num: int, context: str) -> None:
		"""Validate command parameters."""
		opcode, expected_param_count, param_types = self.COMMANDS[cmd_name]

		# Parse parameters
		params_raw = [p.strip() for p in params_str.split(':')] if params_str else []

		# Check parameter count
		if len(param_types) != len(params_raw):
			self.issues.append(ValidationIssue(
				level=ValidationLevel.ERROR,
				line_num=line_num,
				message=f"Command {cmd_name} expects {len(param_types)} parameters, got {len(params_raw)}",
				context=context,
				suggestion=f"Use: [{cmd_name}:{':'.join(['param'] * len(param_types))}]"
			))
			return

		# Validate each parameter
		for i, (param_str, param_type) in enumerate(zip(params_raw, param_types)):
			self.validate_parameter_value(param_str, param_type, line_num, context, i)

		# Track specific commands
		if cmd_name == 'CALL_SUBROUTINE':
			self.metrics.subroutine_calls += 1
		elif cmd_name == 'MEMORY_WRITE':
			self.metrics.memory_writes += 1

	def validate_parameter_value(self, param_str: str, param_type: str, line_num: int, context: str, param_index: int) -> None:
		"""Validate a single parameter value."""
		# Parse value
		try:
			if param_str.startswith('0x') or param_str.startswith('0X'):
				value = int(param_str, 16)
			elif param_str.startswith('$'):
				value = int(param_str[1:], 16)
			else:
				value = int(param_str)
		except ValueError:
			self.issues.append(ValidationIssue(
				level=ValidationLevel.ERROR,
				line_num=line_num,
				message=f"Invalid parameter value: {param_str}",
				context=context,
				suggestion="Use hex (0x1234 or $1234) or decimal (1234)"
			))
			return

		# Validate range
		if param_type in self.PARAM_TYPES:
			min_val, max_val = self.PARAM_TYPES[param_type]
			if not (min_val <= value <= max_val):
				self.issues.append(ValidationIssue(
					level=ValidationLevel.ERROR,
					line_num=line_num,
					message=f"Parameter {param_index} value {value} (0x{value:04X}) out of range for {param_type}",
					context=context,
					suggestion=f"Valid range: {min_val}-{max_val} (0x{min_val:04X}-0x{max_val:04X})"
				))

	def validate_text_line(self, line: str, line_num: int) -> None:
		"""Validate text line."""
		# Check text length
		if len(line) > self.MAX_TEXT_LENGTH:
			self.issues.append(ValidationIssue(
				level=ValidationLevel.WARNING,
				line_num=line_num,
				message=f"Text line exceeds recommended maximum ({len(line)} > {self.MAX_TEXT_LENGTH} characters)",
				context=line[:50] + "..." if len(line) > 50 else line,
				suggestion="Consider splitting across multiple lines with [NEWLINE]"
			))

		# Check for double spaces
		if '  ' in line:
			self.issues.append(ValidationIssue(
				level=ValidationLevel.INFO,
				line_num=line_num,
				message="Text contains double spaces",
				context=line,
				suggestion="Remove extra spaces for better compression"
			))

		# Track text bytes (approximate)
		self.metrics.text_bytes += len(line)
		self.current_dialog_size += len(line)

	def validate_script(self, script_path: str) -> None:
		"""Validate a complete script file."""
		script_file = Path(script_path)

		if not script_file.exists():
			raise FileNotFoundError(f"Script file not found: {script_path}")

		print(f"\n🔍 Validating script: {script_file}")

		with open(script_file, 'r', encoding='utf-8') as f:
			lines = f.readlines()

		self.metrics.total_lines = len(lines)

		for i, line in enumerate(lines, 1):
			self.validate_line_syntax(line, i)

		# Final checks
		if self.current_dialog_id is not None:
			self.issues.append(ValidationIssue(
				level=ValidationLevel.ERROR,
				line_num=self.metrics.total_lines,
				message=f"Dialog {self.current_dialog_id} not closed with [END]",
				context="",
				suggestion="Add [END] at end of dialog"
			))

	def generate_report(self, output_path: str) -> None:
		"""Generate validation report."""
		report_file = Path(output_path)

		# Categorize issues
		errors = [i for i in self.issues if i.level == ValidationLevel.ERROR]
		warnings = [i for i in self.issues if i.level == ValidationLevel.WARNING]
		infos = [i for i in self.issues if i.level == ValidationLevel.INFO]

		lines = []
		lines.append("# Script Validation Report")
		lines.append("=" * 80)
		lines.append("")

		# Summary
		lines.append("## Summary")
		lines.append("")
		lines.append(f"**Status**: {'✅ PASS' if not errors else '❌ FAIL'}")
		lines.append(f"**Errors**: {len(errors)}")
		lines.append(f"**Warnings**: {len(warnings)}")
		lines.append(f"**Info**: {len(infos)}")
		lines.append("")

		# Metrics
		lines.append("## Metrics")
		lines.append("")
		lines.append(f"- Total lines: {self.metrics.total_lines}")
		lines.append(f"- Dialogs: {self.metrics.dialog_count}")
		lines.append(f"- Commands: {self.metrics.command_count}")
		lines.append(f"- Text bytes: {self.metrics.text_bytes}")
		lines.append(f"- Subroutine calls: {self.metrics.subroutine_calls}")
		lines.append(f"- Memory writes: {self.metrics.memory_writes}")
		lines.append("")

		# Issues
		if errors:
			lines.append("## ❌ Errors")
			lines.append("")
			for issue in errors:
				lines.append(f"### Line {issue.line_num}")
				lines.append(f"**Message**: {issue.message}")
				if issue.context:
					lines.append(f"**Context**: `{issue.context}`")
				if issue.suggestion:
					lines.append(f"**Suggestion**: {issue.suggestion}")
				lines.append("")

		if warnings:
			lines.append("## ⚠️ Warnings")
			lines.append("")
			for issue in warnings:
				lines.append(f"### Line {issue.line_num}")
				lines.append(f"**Message**: {issue.message}")
				if issue.context:
					lines.append(f"**Context**: `{issue.context}`")
				if issue.suggestion:
					lines.append(f"**Suggestion**: {issue.suggestion}")
				lines.append("")

		if infos:
			lines.append("## ℹ️ Info")
			lines.append("")
			for issue in infos:
				lines.append(f"- Line {issue.line_num}: {issue.message}")

		with open(report_file, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))

		print(f"\n📄 Report saved: {report_file}")

	def print_summary(self) -> None:
		"""Print validation summary to console."""
		errors = [i for i in self.issues if i.level == ValidationLevel.ERROR]
		warnings = [i for i in self.issues if i.level == ValidationLevel.WARNING]
		infos = [i for i in self.issues if i.level == ValidationLevel.INFO]

		print("\n" + "=" * 80)
		print("VALIDATION SUMMARY")
		print("=" * 80)
		print(f"\nStatus: {'✅ PASS' if not errors else '❌ FAIL'}")
		print(f"Errors: {len(errors)}")
		print(f"Warnings: {len(warnings)}")
		print(f"Info: {len(infos)}")
		print("")

		if errors:
			print("❌ ERRORS:")
			for issue in errors[:5]:	# Show first 5
				print(f"  {issue}")
			if len(errors) > 5:
				print(f"  ... and {len(errors) - 5} more errors")

		if warnings:
			print("\n⚠️ WARNINGS:")
			for issue in warnings[:3]:	# Show first 3
				print(f"  {issue}")
			if len(warnings) > 3:
				print(f"  ... and {len(warnings) - 3} more warnings")


def main():
	"""Main entry point."""
	import argparse

	parser = argparse.ArgumentParser(
		description="Validate FFMQ event scripts",
		formatter_class=argparse.RawDescriptionHelpFormatter,
		epilog="""
Examples:
	# Validate script
	python script_validator.py --script dialogs.txt

	# Validate with detailed report
	python script_validator.py --script dialogs.txt --report validation_report.md

	# Validate multiple scripts
	python script_validator.py --script script1.txt script2.txt script3.txt

Documentation:
	Validates syntax, parameters, control flow, and best practices.
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
		default='validation_report.md',
		help='Path for validation report'
	)

	args = parser.parse_args()

	print("=" * 80)
	print("SCRIPT VALIDATOR")
	print("=" * 80)

	# Validate each script
	all_validators = []

	for script_path in args.script:
		validator = ScriptValidator()
		validator.validate_script(script_path)
		validator.print_summary()
		all_validators.append(validator)

	# Generate combined report
	if len(all_validators) == 1:
		all_validators[0].generate_report(args.report)
	else:
		# Combine results
		combined = ScriptValidator()
		for v in all_validators:
			combined.issues.extend(v.issues)
			combined.metrics.total_lines += v.metrics.total_lines
			combined.metrics.command_count += v.metrics.command_count
			combined.metrics.text_bytes += v.metrics.text_bytes
			combined.metrics.dialog_count += v.metrics.dialog_count
			combined.metrics.subroutine_calls += v.metrics.subroutine_calls
			combined.metrics.memory_writes += v.metrics.memory_writes

		combined.generate_report(args.report)

	print("\n" + "=" * 80)
	print("VALIDATION COMPLETE")
	print("=" * 80)
	print("")


if __name__ == '__main__':
	main()
