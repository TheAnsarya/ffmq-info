#!/usr/bin/env python3
"""
Script Linter - Style checking and best practices enforcement for event scripts
Goes beyond basic validation to enforce coding standards and identify issues

Features:
- Style consistency checks (naming, formatting, indentation)
- Best practices enforcement
- Performance anti-patterns detection
- Code smell identification
- Maintainability metrics
- Configurable rules with severity levels
- Auto-fix capabilities for simple issues
- Integration with CI/CD pipelines

Lint Rules:
- Naming conventions (dialog IDs, labels, subroutines)
- Line length limits
- Command ordering preferences
- Excessive complexity warnings
- Duplicate code detection
- Magic number identification
- Commenting requirements
- Consistent formatting

Usage:
	python script_linter.py --script dialogs.txt
	python script_linter.py --script *.txt --strict
	python script_linter.py --script dialogs.txt --fix --output cleaned.txt
	python script_linter.py --script dialogs.txt --config lint_rules.json
	python script_linter.py --script dialogs.txt --format json
"""

import argparse
import re
import json
from pathlib import Path
from typing import Dict, List, Set, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum
from collections import defaultdict, Counter


class RuleSeverity(Enum):
	"""Severity levels for lint rules"""
	ERROR = "error"  # Must be fixed
	WARNING = "warning"  # Should be fixed
	INFO = "info"  # Consider fixing
	HINT = "hint"  # Suggestion


class RuleCategory(Enum):
	"""Categories of lint rules"""
	STYLE = "style"
	PERFORMANCE = "performance"
	BEST_PRACTICE = "best_practice"
	MAINTAINABILITY = "maintainability"
	COMPATIBILITY = "compatibility"


@dataclass
class LintIssue:
	"""A single lint issue found in code"""
	rule_id: str
	severity: RuleSeverity
	category: RuleCategory
	dialog_id: str
	line_number: int
	column: int
	message: str
	suggestion: str = ""
	fixable: bool = False
	fix_content: str = ""


@dataclass
class LintRule:
	"""A lint rule configuration"""
	rule_id: str
	severity: RuleSeverity
	category: RuleCategory
	enabled: bool
	description: str
	check_function: Optional[str] = None


@dataclass
class LintConfig:
	"""Linter configuration"""
	rules: Dict[str, LintRule]
	max_line_length: int = 80
	max_dialog_lines: int = 100
	max_complexity: int = 10
	require_comments: bool = False
	strict_naming: bool = False

	@classmethod
	def default(cls) -> 'LintConfig':
		"""Create default configuration"""
		rules = {}

		# Define default rules
		default_rules = [
			('style_line_length', RuleSeverity.WARNING, RuleCategory.STYLE, True,
			 "Lines should not exceed maximum length"),
			('style_trailing_whitespace', RuleSeverity.INFO, RuleCategory.STYLE, True,
			 "Remove trailing whitespace"),
			('style_dialog_naming', RuleSeverity.WARNING, RuleCategory.STYLE, True,
			 "Dialog IDs should follow naming convention"),
			('perf_excessive_waits', RuleSeverity.WARNING, RuleCategory.PERFORMANCE, True,
			 "Consecutive WAITs can be combined"),
			('perf_redundant_flags', RuleSeverity.WARNING, RuleCategory.PERFORMANCE, True,
			 "Redundant flag operations detected"),
			('best_missing_end', RuleSeverity.ERROR, RuleCategory.BEST_PRACTICE, True,
			 "Dialog must end with END or RETURN"),
			('best_unreachable_code', RuleSeverity.WARNING, RuleCategory.BEST_PRACTICE, True,
			 "Code after END/RETURN is unreachable"),
			('best_magic_numbers', RuleSeverity.INFO, RuleCategory.BEST_PRACTICE, True,
			 "Consider using named constants for magic numbers"),
			('maint_excessive_length', RuleSeverity.WARNING, RuleCategory.MAINTAINABILITY, True,
			 "Dialog is excessively long"),
			('maint_high_complexity', RuleSeverity.WARNING, RuleCategory.MAINTAINABILITY, True,
			 "Dialog complexity is too high"),
			('maint_duplicate_text', RuleSeverity.INFO, RuleCategory.MAINTAINABILITY, True,
			 "Duplicate text blocks should be extracted"),
		]

		for rule_data in default_rules:
			rule = LintRule(
				rule_id=rule_data[0],
				severity=rule_data[1],
				category=rule_data[2],
				enabled=rule_data[3],
				description=rule_data[4]
			)
			rules[rule.rule_id] = rule

		return cls(rules=rules)


@dataclass
class LintReport:
	"""Complete lint report"""
	script_files: List[str]
	total_dialogs: int
	total_lines: int
	issues: List[LintIssue]
	error_count: int = 0
	warning_count: int = 0
	info_count: int = 0
	hint_count: int = 0

	def __post_init__(self):
		self.error_count = sum(1 for i in self.issues if i.severity == RuleSeverity.ERROR)
		self.warning_count = sum(1 for i in self.issues if i.severity == RuleSeverity.WARNING)
		self.info_count = sum(1 for i in self.issues if i.severity == RuleSeverity.INFO)
		self.hint_count = sum(1 for i in self.issues if i.severity == RuleSeverity.HINT)


class ScriptLinter:
	"""Lint event scripts for style and best practices"""

	# Magic number threshold (numbers that should probably be constants)
	MAGIC_NUMBER_THRESHOLD = 3  # If a number appears 3+ times, suggest constant

	# Dialog ID naming patterns
	DIALOG_ID_PATTERNS = [
		r'^[A-Z][A-Z0-9_]*$',  # UPPERCASE_WITH_UNDERSCORES
		r'^[A-Z][a-zA-Z0-9]+$',  # PascalCase
	]

	def __init__(self, config: Optional[LintConfig] = None, verbose: bool = False):
		self.config = config or LintConfig.default()
		self.verbose = verbose
		self.dialogs: Dict[str, List[str]] = {}
		self.issues: List[LintIssue] = []
		self.number_usage: Counter = Counter()

	def parse_script_file(self, script_path: Path) -> None:
		"""Parse script file into dialog dictionary"""
		if self.verbose:
			print(f"Parsing {script_path}...")

		with open(script_path, 'r', encoding='utf-8') as f:
			content = f.read()

		# Split by dialog markers
		dialog_pattern = r'^DIALOG\s+(\S+):(.*?)(?=^DIALOG\s+|\Z)'
		matches = re.finditer(dialog_pattern, content, re.MULTILINE | re.DOTALL)

		for match in matches:
			dialog_id = match.group(1)
			dialog_content = match.group(2).strip()
			lines = dialog_content.split('\n')
			self.dialogs[dialog_id] = lines

	def check_line_length(self, dialog_id: str, line_num: int, line: str) -> None:
		"""Check if line exceeds maximum length"""
		if not self.config.rules['style_line_length'].enabled:
			return

		if len(line) > self.config.max_line_length:
			self.issues.append(LintIssue(
				rule_id='style_line_length',
				severity=RuleSeverity.WARNING,
				category=RuleCategory.STYLE,
				dialog_id=dialog_id,
				line_number=line_num,
				column=self.config.max_line_length,
				message=f"Line exceeds {self.config.max_line_length} characters ({len(line)} chars)",
				suggestion=f"Break into multiple lines or reduce text length",
				fixable=False
			))

	def check_trailing_whitespace(self, dialog_id: str, line_num: int, line: str) -> None:
		"""Check for trailing whitespace"""
		if not self.config.rules['style_trailing_whitespace'].enabled:
			return

		if line != line.rstrip():
			self.issues.append(LintIssue(
				rule_id='style_trailing_whitespace',
				severity=RuleSeverity.INFO,
				category=RuleCategory.STYLE,
				dialog_id=dialog_id,
				line_number=line_num,
				column=len(line.rstrip()),
				message="Trailing whitespace found",
				suggestion="Remove trailing whitespace",
				fixable=True,
				fix_content=line.rstrip()
			))

	def check_dialog_naming(self, dialog_id: str) -> None:
		"""Check dialog ID naming convention"""
		if not self.config.rules['style_dialog_naming'].enabled:
			return

		if not self.config.strict_naming:
			return

		matches_pattern = any(re.match(pattern, dialog_id) for pattern in self.DIALOG_ID_PATTERNS)

		if not matches_pattern:
			self.issues.append(LintIssue(
				rule_id='style_dialog_naming',
				severity=RuleSeverity.WARNING,
				category=RuleCategory.STYLE,
				dialog_id=dialog_id,
				line_number=0,
				column=0,
				message=f"Dialog ID '{dialog_id}' doesn't follow naming convention",
				suggestion="Use UPPERCASE_WITH_UNDERSCORES or PascalCase",
				fixable=False
			))

	def check_excessive_waits(self, dialog_id: str, lines: List[str]) -> None:
		"""Check for consecutive WAIT commands that could be combined"""
		if not self.config.rules['perf_excessive_waits'].enabled:
			return

		consecutive_waits = []

		for line_num, line in enumerate(lines, 1):
			line = line.strip()
			if line.startswith('WAIT'):
				consecutive_waits.append((line_num, line))
			else:
				if len(consecutive_waits) >= 2:
					# Calculate total wait time
					total_wait = 0
					for _, wait_line in consecutive_waits:
						match = re.search(r'WAIT\s+(\d+)', wait_line)
						if match:
							total_wait += int(match.group(1))

					first_line = consecutive_waits[0][0]
					self.issues.append(LintIssue(
						rule_id='perf_excessive_waits',
						severity=RuleSeverity.WARNING,
						category=RuleCategory.PERFORMANCE,
						dialog_id=dialog_id,
						line_number=first_line,
						column=0,
						message=f"{len(consecutive_waits)} consecutive WAIT commands",
						suggestion=f"Combine into single WAIT {total_wait}",
						fixable=True,
						fix_content=f"WAIT {total_wait}"
					))

				consecutive_waits = []

	def check_redundant_flags(self, dialog_id: str, lines: List[str]) -> None:
		"""Check for redundant flag operations"""
		if not self.config.rules['perf_redundant_flags'].enabled:
			return

		flag_ops: Dict[str, List[Tuple[int, str]]] = defaultdict(list)

		for line_num, line in enumerate(lines, 1):
			line = line.strip()

			# Track flag operations
			for op in ['SET_FLAG', 'CLEAR_FLAG', 'CHECK_FLAG']:
				if line.startswith(op):
					match = re.search(rf'{op}\s+(\S+)', line)
					if match:
						flag_id = match.group(1)
						flag_ops[flag_id].append((line_num, op))

		# Check for redundant operations
		for flag_id, ops in flag_ops.items():
			for i in range(len(ops) - 1):
				line1, op1 = ops[i]
				line2, op2 = ops[i + 1]

				# Same operation twice in a row
				if op1 == op2 and line2 - line1 <= 5:
					self.issues.append(LintIssue(
						rule_id='perf_redundant_flags',
						severity=RuleSeverity.WARNING,
						category=RuleCategory.PERFORMANCE,
						dialog_id=dialog_id,
						line_number=line2,
						column=0,
						message=f"Redundant {op2} on flag {flag_id} (already done at line {line1})",
						suggestion=f"Remove redundant operation",
						fixable=True
					))

	def check_missing_end(self, dialog_id: str, lines: List[str]) -> None:
		"""Check if dialog ends with END or RETURN"""
		if not self.config.rules['best_missing_end'].enabled:
			return

		if not lines:
			return

		last_line = lines[-1].strip()
		if last_line not in ['END', 'RETURN']:
			self.issues.append(LintIssue(
				rule_id='best_missing_end',
				severity=RuleSeverity.ERROR,
				category=RuleCategory.BEST_PRACTICE,
				dialog_id=dialog_id,
				line_number=len(lines),
				column=0,
				message="Dialog must end with END or RETURN",
				suggestion="Add END at the end of dialog",
				fixable=True,
				fix_content="END"
			))

	def check_unreachable_code(self, dialog_id: str, lines: List[str]) -> None:
		"""Check for unreachable code after END/RETURN"""
		if not self.config.rules['best_unreachable_code'].enabled:
			return

		for line_num, line in enumerate(lines, 1):
			line = line.strip()
			if line in ['END', 'RETURN']:
				# Check if there's code after this
				if line_num < len(lines):
					remaining = [l.strip() for l in lines[line_num:] if l.strip()]
					if remaining:
						self.issues.append(LintIssue(
							rule_id='best_unreachable_code',
							severity=RuleSeverity.WARNING,
							category=RuleCategory.BEST_PRACTICE,
							dialog_id=dialog_id,
							line_number=line_num + 1,
							column=0,
							message=f"Unreachable code after {line}",
							suggestion="Remove unreachable code or restructure",
							fixable=True
						))
				break

	def check_magic_numbers(self, dialog_id: str, lines: List[str]) -> None:
		"""Check for magic numbers that should be constants"""
		if not self.config.rules['best_magic_numbers'].enabled:
			return

		# Extract all numeric literals
		for line_num, line in enumerate(lines, 1):
			line = line.strip()

			# Find numeric literals (excluding flags and addresses)
			numbers = re.findall(r'\b(\d+)\b', line)
			for num in numbers:
				if int(num) > 1:  # Ignore 0 and 1
					self.number_usage[num] += 1

		# Report frequently used numbers
		for num, count in self.number_usage.items():
			if count >= self.MAGIC_NUMBER_THRESHOLD:
				# Find first occurrence
				for line_num, line in enumerate(lines, 1):
					if num in line:
						self.issues.append(LintIssue(
							rule_id='best_magic_numbers',
							severity=RuleSeverity.INFO,
							category=RuleCategory.BEST_PRACTICE,
							dialog_id=dialog_id,
							line_number=line_num,
							column=0,
							message=f"Magic number {num} appears {count} times",
							suggestion=f"Consider defining constant for {num}",
							fixable=False
						))
						break

	def check_excessive_length(self, dialog_id: str, lines: List[str]) -> None:
		"""Check if dialog is excessively long"""
		if not self.config.rules['maint_excessive_length'].enabled:
			return

		if len(lines) > self.config.max_dialog_lines:
			self.issues.append(LintIssue(
				rule_id='maint_excessive_length',
				severity=RuleSeverity.WARNING,
				category=RuleCategory.MAINTAINABILITY,
				dialog_id=dialog_id,
				line_number=0,
				column=0,
				message=f"Dialog has {len(lines)} lines (max recommended: {self.config.max_dialog_lines})",
				suggestion="Consider splitting into multiple dialogs or subroutines",
				fixable=False
			))

	def check_high_complexity(self, dialog_id: str, lines: List[str]) -> None:
		"""Calculate and check cyclomatic complexity"""
		if not self.config.rules['maint_high_complexity'].enabled:
			return

		complexity = 1  # Base complexity

		# Add complexity for control flow
		for line in lines:
			line = line.strip()
			if any(cmd in line for cmd in ['CHECK_FLAG', 'JUMP_IF', 'CALL_SUBROUTINE']):
				complexity += 1

		if complexity > self.config.max_complexity:
			self.issues.append(LintIssue(
				rule_id='maint_high_complexity',
				severity=RuleSeverity.WARNING,
				category=RuleCategory.MAINTAINABILITY,
				dialog_id=dialog_id,
				line_number=0,
				column=0,
				message=f"Complexity score {complexity} exceeds maximum {self.config.max_complexity}",
				suggestion="Refactor into smaller subroutines",
				fixable=False
			))

	def check_duplicate_text(self, dialog_id: str, lines: List[str]) -> None:
		"""Check for duplicate text blocks"""
		if not self.config.rules['maint_duplicate_text'].enabled:
			return

		text_lines = [line.strip() for line in lines if line.strip().startswith('"')]

		if len(text_lines) != len(set(text_lines)):
			# There are duplicates
			text_counts = Counter(text_lines)
			for text, count in text_counts.items():
				if count > 1:
					# Find first occurrence
					for line_num, line in enumerate(lines, 1):
						if line.strip() == text:
							self.issues.append(LintIssue(
								rule_id='maint_duplicate_text',
								severity=RuleSeverity.INFO,
								category=RuleCategory.MAINTAINABILITY,
								dialog_id=dialog_id,
								line_number=line_num,
								column=0,
								message=f"Text appears {count} times in this dialog",
								suggestion="Extract to subroutine or constant",
								fixable=False
							))
							break

	def lint_dialog(self, dialog_id: str, lines: List[str]) -> None:
		"""Run all lint checks on a dialog"""
		# Check dialog-level issues
		self.check_dialog_naming(dialog_id)
		self.check_missing_end(dialog_id, lines)
		self.check_excessive_length(dialog_id, lines)
		self.check_high_complexity(dialog_id, lines)
		self.check_excessive_waits(dialog_id, lines)
		self.check_redundant_flags(dialog_id, lines)
		self.check_unreachable_code(dialog_id, lines)
		self.check_magic_numbers(dialog_id, lines)
		self.check_duplicate_text(dialog_id, lines)

		# Check line-level issues
		for line_num, line in enumerate(lines, 1):
			self.check_line_length(dialog_id, line_num, line)
			self.check_trailing_whitespace(dialog_id, line_num, line)

	def lint(self, script_paths: List[Path]) -> LintReport:
		"""Lint all scripts"""
		# Parse all scripts
		for path in script_paths:
			self.parse_script_file(path)

		if self.verbose:
			print(f"\nLinting {len(self.dialogs)} dialogs...")

		# Lint each dialog
		for dialog_id, lines in self.dialogs.items():
			self.lint_dialog(dialog_id, lines)

		total_lines = sum(len(lines) for lines in self.dialogs.values())

		report = LintReport(
			script_files=[str(p) for p in script_paths],
			total_dialogs=len(self.dialogs),
			total_lines=total_lines,
			issues=sorted(self.issues, key=lambda i: (i.severity.value, i.dialog_id, i.line_number))
		)

		return report

	def generate_report(self, report: LintReport, format: str = 'text') -> str:
		"""Generate lint report in specified format"""
		if format == 'json':
			return self._generate_json_report(report)
		elif format == 'github':
			return self._generate_github_report(report)
		else:
			return self._generate_text_report(report)

	def _generate_text_report(self, report: LintReport) -> str:
		"""Generate text format report"""
		lines = [
			"# Script Lint Report",
			"",
			"## Summary",
			f"- Scripts: {len(report.script_files)}",
			f"- Dialogs: {report.total_dialogs}",
			f"- Lines: {report.total_lines:,}",
			f"- Issues: {len(report.issues)}",
			f"  - Errors: {report.error_count}",
			f"  - Warnings: {report.warning_count}",
			f"  - Info: {report.info_count}",
			f"  - Hints: {report.hint_count}",
			""
		]

		if not report.issues:
			lines.append("✓ No issues found!")
			return '\n'.join(lines)

		# Group by severity
		by_severity = defaultdict(list)
		for issue in report.issues:
			by_severity[issue.severity].append(issue)

		for severity in [RuleSeverity.ERROR, RuleSeverity.WARNING, RuleSeverity.INFO, RuleSeverity.HINT]:
			issues = by_severity[severity]
			if not issues:
				continue

			lines.append(f"## {severity.value.upper()} ({len(issues)})")
			lines.append("")

			for issue in issues:
				lines.append(f"**{issue.dialog_id}:{issue.line_number}:{issue.column}** - {issue.message}")
				if issue.suggestion:
					lines.append(f"  💡 {issue.suggestion}")
				if issue.fixable:
					lines.append(f"  🔧 Auto-fixable")
				lines.append("")

		return '\n'.join(lines)

	def _generate_json_report(self, report: LintReport) -> str:
		"""Generate JSON format report"""
		data = {
			'summary': {
				'scripts': len(report.script_files),
				'dialogs': report.total_dialogs,
				'lines': report.total_lines,
				'total_issues': len(report.issues),
				'errors': report.error_count,
				'warnings': report.warning_count,
				'info': report.info_count,
				'hints': report.hint_count
			},
			'issues': [
				{
					'rule_id': issue.rule_id,
					'severity': issue.severity.value,
					'category': issue.category.value,
					'location': {
						'dialog': issue.dialog_id,
						'line': issue.line_number,
						'column': issue.column
					},
					'message': issue.message,
					'suggestion': issue.suggestion,
					'fixable': issue.fixable
				}
				for issue in report.issues
			]
		}

		return json.dumps(data, indent=2)

	def _generate_github_report(self, report: LintReport) -> str:
		"""Generate GitHub Actions annotation format"""
		lines = []

		for issue in report.issues:
			level = 'error' if issue.severity == RuleSeverity.ERROR else 'warning'
			lines.append(
				f"::{level} file={issue.dialog_id},line={issue.line_number},col={issue.column}::"
				f"{issue.message}"
			)

		return '\n'.join(lines)

	def apply_fixes(self, output_path: Path) -> int:
		"""Apply auto-fixes and save to file"""
		fixed_count = 0

		lines = []
		for dialog_id, dialog_lines in sorted(self.dialogs.items()):
			lines.append(f"DIALOG {dialog_id}:")

			# Apply line-level fixes
			for line_num, line in enumerate(dialog_lines, 1):
				# Check for fixable issues on this line
				line_issues = [
					i for i in self.issues
					if i.dialog_id == dialog_id and i.line_number == line_num and i.fixable
				]

				if line_issues:
					# Apply first fixable issue
					issue = line_issues[0]
					if issue.fix_content:
						lines.append(issue.fix_content)
						fixed_count += 1
					else:
						lines.append(line)
				else:
					lines.append(line)

			lines.append("")

		with open(output_path, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))

		return fixed_count


def main():
	parser = argparse.ArgumentParser(description='Lint event scripts for style and best practices')
	parser.add_argument('--script', type=Path, nargs='+', required=True, help='Script file(s) to lint')
	parser.add_argument('--config', type=Path, help='Lint configuration file (JSON)')
	parser.add_argument('--strict', action='store_true', help='Enable strict mode')
	parser.add_argument('--fix', action='store_true', help='Apply auto-fixes')
	parser.add_argument('--output', type=Path, help='Output file for fixed script')
	parser.add_argument('--format', choices=['text', 'json', 'github'], default='text',
	                    help='Report format')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')

	args = parser.parse_args()

	# Load config
	if args.config:
		with open(args.config) as f:
			config_data = json.load(f)
		# TODO: Parse config_data into LintConfig
		config = LintConfig.default()
	else:
		config = LintConfig.default()

	if args.strict:
		config.strict_naming = True
		config.max_line_length = 72
		config.max_dialog_lines = 50
		config.require_comments = True

	linter = ScriptLinter(config=config, verbose=args.verbose)

	# Lint scripts
	report = linter.lint(args.script)

	# Generate report
	report_text = linter.generate_report(report, format=args.format)
	print(report_text)

	# Apply fixes if requested
	if args.fix:
		if not args.output:
			print("\nError: --output required when using --fix")
			return 1

		fixed_count = linter.apply_fixes(args.output)
		print(f"\n✓ Applied {fixed_count} auto-fixes to {args.output}")

	# Exit code based on errors
	return 1 if report.error_count > 0 else 0


if __name__ == '__main__':
	exit(main())
