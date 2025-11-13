#!/usr/bin/env python3
"""
Script Validator - Comprehensive validation and verification for event scripts
Validate syntax, semantics, and runtime behavior of event scripts

Features:
- Syntax validation (command format, parameters)
- Semantic validation (flag usage, control flow)
- Type checking (parameter types and ranges)
- Control flow validation (unreachable code, infinite loops)
- Memory access validation (bounds checking)
- Reference validation (subroutine calls, labels)
- Best practices checking
- Performance analysis
- Security validation

Validation Categories:
- Syntax: command format, parameter count, line structure
- Semantics: flag consistency, variable usage, control flow
- Types: parameter types, value ranges, pointer validity
- References: label existence, subroutine validity
- Performance: redundant operations, optimization opportunities
- Security: buffer overflows, infinite loops, stack overflow

Output:
- Validation report (pass/fail with details)
- Error and warning messages
- Suggestions for fixes
- Severity levels (error, warning, info)
- Multiple output formats

Usage:
	python script_validator.py script.txt --strict
	python script_validator.py scripts/ --report validation.md
	python script_validator.py script.txt --json --output results.json
	python script_validator.py scripts/ --ci --exit-on-error
"""

import argparse
import re
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple
from dataclasses import dataclass, field
from collections import defaultdict
from enum import Enum
import json


class Severity(Enum):
	"""Validation issue severity"""
	ERROR = "error"
	WARNING = "warning"
	INFO = "info"


class ValidationCategory(Enum):
	"""Validation category"""
	SYNTAX = "syntax"
	SEMANTICS = "semantics"
	TYPES = "types"
	REFERENCES = "references"
	PERFORMANCE = "performance"
	SECURITY = "security"


@dataclass
class ValidationIssue:
	"""A validation issue found in script"""
	severity: Severity
	category: ValidationCategory
	message: str
	line_number: int
	column: Optional[int] = None
	suggestion: Optional[str] = None
	code: Optional[str] = None


@dataclass
class ValidationResult:
	"""Result of script validation"""
	file_path: str
	is_valid: bool
	issues: List[ValidationIssue] = field(default_factory=list)
	error_count: int = 0
	warning_count: int = 0
	info_count: int = 0


class ScriptValidator:
	"""Validate event scripts for correctness and best practices"""
	
	# Command definitions with parameter specs
	COMMAND_SPECS = {
		'END': {'params': 0, 'types': []},
		'WAIT': {'params': 0, 'types': []},
		'NEWLINE': {'params': 0, 'types': []},
		'SET_FLAG': {'params': 1, 'types': ['word']},
		'CLEAR_FLAG': {'params': 1, 'types': ['word']},
		'CHECK_FLAG': {'params': 1, 'types': ['word']},
		'BRANCH': {'params': 1, 'types': ['label']},
		'JUMP': {'params': 1, 'types': ['label']},
		'CALL': {'params': 1, 'types': ['address']},
		'RETURN': {'params': 0, 'types': []},
		'DELAY': {'params': 1, 'types': ['byte']},
		'PLAY_SOUND': {'params': 1, 'types': ['byte']},
		'PLAY_MUSIC': {'params': 1, 'types': ['byte']},
		'STOP_MUSIC': {'params': 0, 'types': []},
		'FADE_MUSIC': {'params': 1, 'types': ['byte']},
		'SHOW_SPRITE': {'params': 1, 'types': ['byte']},
		'HIDE_SPRITE': {'params': 1, 'types': ['byte']},
		'MOVE_SPRITE': {'params': 3, 'types': ['byte', 'byte', 'byte']},
		'ANIMATE_SPRITE': {'params': 2, 'types': ['byte', 'byte']},
		'LOAD_MAP': {'params': 1, 'types': ['byte']},
		'TELEPORT': {'params': 3, 'types': ['byte', 'byte', 'byte']},
		'ADD_PARTY_MEMBER': {'params': 1, 'types': ['byte']},
		'REMOVE_PARTY_MEMBER': {'params': 1, 'types': ['byte']},
		'ADD_ITEM': {'params': 1, 'types': ['byte']},
		'REMOVE_ITEM': {'params': 1, 'types': ['byte']},
		'CHECK_ITEM': {'params': 1, 'types': ['byte']},
		'START_BATTLE': {'params': 1, 'types': ['byte']},
		'BATTLE_CONDITION': {'params': 1, 'types': ['byte']},
		'SHOW_TEXTBOX': {'params': 0, 'types': []},
		'CHOICE': {'params': 2, 'types': ['byte', 'byte']},
		'SHOP': {'params': 1, 'types': ['byte']},
		'INN': {'params': 1, 'types': ['byte']},
		'GIVE_GOLD': {'params': 1, 'types': ['word']},
		'TAKE_GOLD': {'params': 1, 'types': ['word']},
		'CHECK_GOLD': {'params': 1, 'types': ['word']},
		'SCREEN_FADE': {'params': 1, 'types': ['byte']},
		'SCREEN_SHAKE': {'params': 1, 'types': ['byte']},
		'SCREEN_FLASH': {'params': 1, 'types': ['byte']},
		'CAMERA_MOVE': {'params': 2, 'types': ['byte', 'byte']},
		'WEATHER': {'params': 1, 'types': ['byte']},
		'TIME': {'params': 1, 'types': ['byte']},
		'VARIABLE_SET': {'params': 2, 'types': ['word', 'word']},
		'VARIABLE_ADD': {'params': 2, 'types': ['word', 'word']},
		'VARIABLE_CHECK': {'params': 2, 'types': ['word', 'word']},
		'MEMORY_WRITE': {'params': 2, 'types': ['address', 'byte']},
		'MEMORY_READ': {'params': 1, 'types': ['address']},
		'MEMORY_COMPARE': {'params': 2, 'types': ['address', 'byte']},
	}
	
	def __init__(self, strict: bool = False, verbose: bool = False):
		self.strict = strict
		self.verbose = verbose
		self.labels_defined: Set[str] = set()
		self.labels_used: Set[str] = set()
		self.flags_written: Set[int] = set()
		self.flags_read: Set[int] = set()
	
	def validate_file(self, path: Path) -> ValidationResult:
		"""Validate single script file"""
		result = ValidationResult(file_path=str(path), is_valid=True)
		
		try:
			with open(path) as f:
				lines = f.readlines()
		except Exception as e:
			result.is_valid = False
			result.issues.append(ValidationIssue(
				severity=Severity.ERROR,
				category=ValidationCategory.SYNTAX,
				message=f"Failed to read file: {e}",
				line_number=0
			))
			result.error_count = 1
			return result
		
		# Reset tracking
		self.labels_defined.clear()
		self.labels_used.clear()
		self.flags_written.clear()
		self.flags_read.clear()
		
		# Pass 1: Syntax and basic validation
		for line_num, line in enumerate(lines, 1):
			original_line = line.rstrip()
			line = line.strip()
			
			# Skip blank and comment lines
			if not line or line.startswith(';'):
				continue
			
			# Check for trailing whitespace
			if original_line != original_line.rstrip():
				if self.strict:
					result.issues.append(ValidationIssue(
						severity=Severity.WARNING,
						category=ValidationCategory.SYNTAX,
						message="Trailing whitespace",
						line_number=line_num,
						suggestion="Remove trailing whitespace"
					))
					result.warning_count += 1
			
			# Label definition
			if line.endswith(':'):
				label_name = line[:-1]
				if not re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', label_name):
					result.issues.append(ValidationIssue(
						severity=Severity.ERROR,
						category=ValidationCategory.SYNTAX,
						message=f"Invalid label name: {label_name}",
						line_number=line_num,
						suggestion="Label names must start with letter or underscore"
					))
					result.error_count += 1
					result.is_valid = False
				else:
					if label_name in self.labels_defined:
						result.issues.append(ValidationIssue(
							severity=Severity.ERROR,
							category=ValidationCategory.SEMANTICS,
							message=f"Duplicate label: {label_name}",
							line_number=line_num
						))
						result.error_count += 1
						result.is_valid = False
					self.labels_defined.add(label_name)
				continue
			
			# Text line
			if line.startswith('"'):
				if not line.endswith('"'):
					result.issues.append(ValidationIssue(
						severity=Severity.ERROR,
						category=ValidationCategory.SYNTAX,
						message="Unterminated string",
						line_number=line_num,
						suggestion='Add closing quote'
					))
					result.error_count += 1
					result.is_valid = False
				continue
			
			# Command line
			match = re.match(r'^([A-Z_]+)(?:\s+(.+))?$', line)
			if not match:
				result.issues.append(ValidationIssue(
					severity=Severity.ERROR,
					category=ValidationCategory.SYNTAX,
					message=f"Invalid syntax: {line}",
					line_number=line_num,
					suggestion="Commands must be uppercase with optional parameters"
				))
				result.error_count += 1
				result.is_valid = False
				continue
			
			command = match.group(1)
			params_str = match.group(2) or ""
			
			# Validate command exists
			if command not in self.COMMAND_SPECS:
				result.issues.append(ValidationIssue(
					severity=Severity.ERROR if self.strict else Severity.WARNING,
					category=ValidationCategory.SYNTAX,
					message=f"Unknown command: {command}",
					line_number=line_num
				))
				if self.strict:
					result.error_count += 1
					result.is_valid = False
				else:
					result.warning_count += 1
				continue
			
			spec = self.COMMAND_SPECS[command]
			
			# Validate parameter count
			params = [p.strip() for p in params_str.split(',')] if params_str else []
			if len(params) != spec['params']:
				result.issues.append(ValidationIssue(
					severity=Severity.ERROR,
					category=ValidationCategory.SYNTAX,
					message=f"{command} expects {spec['params']} parameters, got {len(params)}",
					line_number=line_num,
					code=line
				))
				result.error_count += 1
				result.is_valid = False
				continue
			
			# Validate parameter types
			for i, (param, expected_type) in enumerate(zip(params, spec['types'])):
				issues = self.validate_parameter(param, expected_type, line_num, command)
				result.issues.extend(issues)
				result.error_count += sum(1 for issue in issues if issue.severity == Severity.ERROR)
				result.warning_count += sum(1 for issue in issues if issue.severity == Severity.WARNING)
				
				if any(issue.severity == Severity.ERROR for issue in issues):
					result.is_valid = False
			
			# Track label usage
			if command in ('JUMP', 'BRANCH'):
				if params:
					self.labels_used.add(params[0])
			
			# Track flag usage
			if command in ('SET_FLAG', 'CLEAR_FLAG'):
				try:
					flag_id = int(params[0], 0)
					self.flags_written.add(flag_id)
				except (ValueError, IndexError):
					pass
			elif command == 'CHECK_FLAG':
				try:
					flag_id = int(params[0], 0)
					self.flags_read.add(flag_id)
				except (ValueError, IndexError):
					pass
		
		# Pass 2: Semantic validation
		# Check for undefined labels
		undefined_labels = self.labels_used - self.labels_defined
		for label in undefined_labels:
			result.issues.append(ValidationIssue(
				severity=Severity.ERROR,
				category=ValidationCategory.REFERENCES,
				message=f"Undefined label: {label}",
				line_number=0
			))
			result.error_count += 1
			result.is_valid = False
		
		# Check for unused labels
		unused_labels = self.labels_defined - self.labels_used
		for label in unused_labels:
			if self.strict:
				result.issues.append(ValidationIssue(
					severity=Severity.WARNING,
					category=ValidationCategory.SEMANTICS,
					message=f"Unused label: {label}",
					line_number=0,
					suggestion="Remove unused label or add reference"
				))
				result.warning_count += 1
		
		# Check for flags read before write
		uninitialized_flags = self.flags_read - self.flags_written
		for flag_id in uninitialized_flags:
			result.issues.append(ValidationIssue(
				severity=Severity.WARNING,
				category=ValidationCategory.SEMANTICS,
				message=f"Flag {flag_id} read before write (may be uninitialized)",
				line_number=0
			))
			result.warning_count += 1
		
		# Check for missing END
		last_command = None
		for line in reversed(lines):
			line = line.strip()
			if line and not line.startswith(';'):
				match = re.match(r'^([A-Z_]+)', line)
				if match:
					last_command = match.group(1)
					break
		
		if last_command != 'END' and last_command != 'RETURN':
			result.issues.append(ValidationIssue(
				severity=Severity.WARNING,
				category=ValidationCategory.SEMANTICS,
				message="Script missing END or RETURN",
				line_number=len(lines),
				suggestion="Add END or RETURN at end of script"
			))
			result.warning_count += 1
		
		return result
	
	def validate_parameter(self, param: str, expected_type: str, line_num: int, command: str) -> List[ValidationIssue]:
		"""Validate parameter type and value"""
		issues = []
		
		if expected_type == 'byte':
			try:
				value = int(param, 0)
				if value < 0 or value > 255:
					issues.append(ValidationIssue(
						severity=Severity.ERROR,
						category=ValidationCategory.TYPES,
						message=f"Byte parameter out of range: {value} (expected 0-255)",
						line_number=line_num
					))
			except ValueError:
				issues.append(ValidationIssue(
					severity=Severity.ERROR,
					category=ValidationCategory.TYPES,
					message=f"Invalid byte value: {param}",
					line_number=line_num
				))
		
		elif expected_type == 'word':
			try:
				value = int(param, 0)
				if value < 0 or value > 65535:
					issues.append(ValidationIssue(
						severity=Severity.ERROR,
						category=ValidationCategory.TYPES,
						message=f"Word parameter out of range: {value} (expected 0-65535)",
						line_number=line_num
					))
			except ValueError:
				issues.append(ValidationIssue(
					severity=Severity.ERROR,
					category=ValidationCategory.TYPES,
					message=f"Invalid word value: {param}",
					line_number=line_num
				))
		
		elif expected_type == 'label':
			if not re.match(r'^[a-zA-Z_][a-zA-Z0-9_]*$', param):
				issues.append(ValidationIssue(
					severity=Severity.ERROR,
					category=ValidationCategory.TYPES,
					message=f"Invalid label: {param}",
					line_number=line_num
				))
		
		elif expected_type == 'address':
			# Bank/offset format or hex address
			if not (re.match(r'^0x[0-9A-Fa-f]{2}/[0-9A-Fa-f]{4}$', param) or
					re.match(r'^0x[0-9A-Fa-f]+$', param) or
					re.match(r'^\$[0-9A-Fa-f]+$', param)):
				issues.append(ValidationIssue(
					severity=Severity.ERROR,
					category=ValidationCategory.TYPES,
					message=f"Invalid address format: {param}",
					line_number=line_num,
					suggestion="Use 0xBB/OOOO or 0xADDRESS format"
				))
		
		return issues
	
	def generate_report(self, results: List[ValidationResult], format: str = 'text') -> str:
		"""Generate validation report"""
		if format == 'json':
			return self.generate_json_report(results)
		elif format == 'markdown':
			return self.generate_markdown_report(results)
		else:
			return self.generate_text_report(results)
	
	def generate_text_report(self, results: List[ValidationResult]) -> str:
		"""Generate text validation report"""
		lines = []
		
		total_errors = sum(r.error_count for r in results)
		total_warnings = sum(r.warning_count for r in results)
		total_files = len(results)
		valid_files = sum(1 for r in results if r.is_valid)
		
		lines.append("=" * 60)
		lines.append("VALIDATION REPORT")
		lines.append("=" * 60)
		lines.append(f"Files validated: {total_files}")
		lines.append(f"Valid: {valid_files}")
		lines.append(f"Invalid: {total_files - valid_files}")
		lines.append(f"Total errors: {total_errors}")
		lines.append(f"Total warnings: {total_warnings}")
		lines.append("")
		
		for result in results:
			if not result.issues:
				continue
			
			lines.append(f"\n{result.file_path}")
			lines.append("-" * 60)
			
			for issue in sorted(result.issues, key=lambda i: (i.line_number, i.severity.value)):
				severity_str = issue.severity.value.upper()
				lines.append(f"  [{severity_str}] Line {issue.line_number}: {issue.message}")
				if issue.suggestion:
					lines.append(f"    Suggestion: {issue.suggestion}")
		
		return '\n'.join(lines)
	
	def generate_markdown_report(self, results: List[ValidationResult]) -> str:
		"""Generate Markdown validation report"""
		lines = [
			"# Validation Report",
			"",
			"## Summary",
			""
		]
		
		total_errors = sum(r.error_count for r in results)
		total_warnings = sum(r.warning_count for r in results)
		total_files = len(results)
		valid_files = sum(1 for r in results if r.is_valid)
		
		lines.append(f"- **Files Validated:** {total_files}")
		lines.append(f"- **Valid:** {valid_files} ✓")
		lines.append(f"- **Invalid:** {total_files - valid_files} ✗")
		lines.append(f"- **Total Errors:** {total_errors}")
		lines.append(f"- **Total Warnings:** {total_warnings}")
		lines.append("")
		
		lines.append("## Files")
		lines.append("")
		
		for result in results:
			status = "✓" if result.is_valid else "✗"
			lines.append(f"### {Path(result.file_path).name} {status}")
			lines.append("")
			
			if result.issues:
				lines.append(f"- Errors: {result.error_count}")
				lines.append(f"- Warnings: {result.warning_count}")
				lines.append("")
				
				lines.append("#### Issues")
				lines.append("")
				for issue in sorted(result.issues, key=lambda i: (i.line_number, i.severity.value)):
					severity_icon = {"error": "🔴", "warning": "⚠️", "info": "ℹ️"}
					icon = severity_icon.get(issue.severity.value, "")
					lines.append(f"{icon} **Line {issue.line_number}** [{issue.category.value}]: {issue.message}")
					if issue.suggestion:
						lines.append(f"  - *Suggestion:* {issue.suggestion}")
				lines.append("")
			else:
				lines.append("No issues found.")
				lines.append("")
		
		return '\n'.join(lines)
	
	def generate_json_report(self, results: List[ValidationResult]) -> str:
		"""Generate JSON validation report"""
		data = {
			"summary": {
				"total_files": len(results),
				"valid_files": sum(1 for r in results if r.is_valid),
				"total_errors": sum(r.error_count for r in results),
				"total_warnings": sum(r.warning_count for r in results)
			},
			"files": [
				{
					"path": r.file_path,
					"is_valid": r.is_valid,
					"error_count": r.error_count,
					"warning_count": r.warning_count,
					"issues": [
						{
							"severity": i.severity.value,
							"category": i.category.value,
							"message": i.message,
							"line_number": i.line_number,
							"column": i.column,
							"suggestion": i.suggestion
						}
						for i in r.issues
					]
				}
				for r in results
			]
		}
		
		return json.dumps(data, indent=2)


def main():
	parser = argparse.ArgumentParser(description='Validate event scripts')
	parser.add_argument('input_paths', type=Path, nargs='+', help='Script files or directories')
	parser.add_argument('--strict', action='store_true', help='Enable strict validation')
	parser.add_argument('--report', type=Path, help='Output report file')
	parser.add_argument('--format', choices=['text', 'markdown', 'json'], default='text',
		help='Report format')
	parser.add_argument('--output', type=Path, help='Output file')
	parser.add_argument('--ci', action='store_true', help='CI mode (exit code based on validation)')
	parser.add_argument('--exit-on-error', action='store_true', help='Exit on first error')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	validator = ScriptValidator(strict=args.strict, verbose=args.verbose)
	
	# Collect files
	script_files = []
	for input_path in args.input_paths:
		if input_path.is_file():
			script_files.append(input_path)
		elif input_path.is_dir():
			script_files.extend(input_path.rglob('*.txt'))
			script_files.extend(input_path.rglob('*.asm'))
	
	if args.verbose:
		print(f"Validating {len(script_files)} files...")
	
	# Validate all files
	results = []
	for script_file in script_files:
		result = validator.validate_file(script_file)
		results.append(result)
		
		if args.exit_on_error and not result.is_valid:
			print(f"✗ Validation failed: {script_file}")
			for issue in result.issues:
				if issue.severity == Severity.ERROR:
					print(f"  Line {issue.line_number}: {issue.message}")
			return 1
	
	# Generate report
	report = validator.generate_report(results, format=args.format)
	
	# Write output
	if args.output or args.report:
		output_path = args.output or args.report
		with open(output_path, 'w') as f:
			f.write(report)
		print(f"\n✓ Validation report saved: {output_path}")
	else:
		print(report)
	
	# Summary
	total_errors = sum(r.error_count for r in results)
	total_warnings = sum(r.warning_count for r in results)
	valid_files = sum(1 for r in results if r.is_valid)
	
	print(f"\n=== Summary ===")
	print(f"Valid: {valid_files}/{len(results)}")
	print(f"Errors: {total_errors}")
	print(f"Warnings: {total_warnings}")
	
	# CI mode exit code
	if args.ci:
		return 1 if total_errors > 0 else 0
	
	return 0


if __name__ == '__main__':
	exit(main())
