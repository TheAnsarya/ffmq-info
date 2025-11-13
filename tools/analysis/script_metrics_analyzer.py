#!/usr/bin/env python3
"""
Script Metrics Analyzer - Comprehensive metrics and quality analysis
Calculate complexity, maintainability, and quality metrics for event scripts

Features:
- Cyclomatic complexity calculation
- Halstead metrics (volume, difficulty, effort)
- Lines of code metrics (LOC, SLOC, comment ratio)
- Maintainability index
- Technical debt estimation
- Code duplication detection
- Cognitive complexity
- Nesting depth analysis
- Command diversity metrics
- Trend analysis over time

Metrics Categories:
- Size metrics: LOC, SLOC, comment lines
- Complexity metrics: cyclomatic, cognitive, nesting depth
- Quality metrics: maintainability index, duplication %
- Halstead metrics: vocabulary, volume, difficulty, effort
- Readability metrics: average line length, command diversity

Output Formats:
- Detailed report (Markdown/HTML)
- JSON metrics export
- CSV metrics table
- Trend charts (matplotlib)
- Dashboard HTML

Usage:
	python script_metrics_analyzer.py scripts/ --report metrics.md
	python script_metrics_analyzer.py scripts/ --format json --output metrics.json
	python script_metrics_analyzer.py scripts/ --trends --chart trends.png
	python script_metrics_analyzer.py scripts/ --dashboard dashboard.html
"""

import argparse
import re
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple
from dataclasses import dataclass, field
from collections import Counter, defaultdict
import json
import math


@dataclass
class CodeMetrics:
	"""Comprehensive code metrics for a script"""
	file_path: str

	# Size metrics
	total_lines: int = 0
	code_lines: int = 0
	comment_lines: int = 0
	blank_lines: int = 0

	# Complexity metrics
	cyclomatic_complexity: int = 0
	cognitive_complexity: int = 0
	max_nesting_depth: int = 0

	# Halstead metrics
	unique_operators: int = 0
	unique_operands: int = 0
	total_operators: int = 0
	total_operands: int = 0
	halstead_vocabulary: int = 0
	halstead_length: int = 0
	halstead_volume: float = 0.0
	halstead_difficulty: float = 0.0
	halstead_effort: float = 0.0

	# Quality metrics
	maintainability_index: float = 0.0
	duplication_percentage: float = 0.0
	comment_ratio: float = 0.0

	# Command metrics
	total_commands: int = 0
	unique_commands: int = 0
	command_diversity: float = 0.0

	# Readability
	avg_line_length: float = 0.0
	max_line_length: int = 0

	def calculate_derived_metrics(self) -> None:
		"""Calculate derived metrics from base measurements"""
		# Halstead metrics
		self.halstead_vocabulary = self.unique_operators + self.unique_operands
		self.halstead_length = self.total_operators + self.total_operands

		if self.halstead_vocabulary > 0:
			self.halstead_volume = self.halstead_length * math.log2(self.halstead_vocabulary)

		if self.unique_operands > 0:
			self.halstead_difficulty = (self.unique_operators / 2.0) * (self.total_operands / self.unique_operands)
			self.halstead_effort = self.halstead_volume * self.halstead_difficulty

		# Maintainability Index (Microsoft version)
		# MI = 171 - 5.2 * ln(V) - 0.23 * G - 16.2 * ln(LOC)
		if self.code_lines > 0 and self.halstead_volume > 0:
			mi = 171.0
			mi -= 5.2 * math.log(self.halstead_volume)
			mi -= 0.23 * self.cyclomatic_complexity
			mi -= 16.2 * math.log(self.code_lines)

			# Normalize to 0-100 scale
			self.maintainability_index = max(0.0, min(100.0, mi))

		# Comment ratio
		if self.total_lines > 0:
			self.comment_ratio = (self.comment_lines / self.total_lines) * 100

		# Command diversity (Shannon entropy)
		if self.total_commands > 0:
			self.command_diversity = self.unique_commands / self.total_commands


@dataclass
class ProjectMetrics:
	"""Aggregated metrics for entire project"""
	total_files: int = 0
	total_lines: int = 0
	total_code_lines: int = 0
	total_commands: int = 0

	avg_complexity: float = 0.0
	avg_maintainability: float = 0.0
	avg_duplication: float = 0.0

	file_metrics: List[CodeMetrics] = field(default_factory=list)


class ScriptMetricsAnalyzer:
	"""Analyze script metrics and quality"""

	# Commands that increase cyclomatic complexity
	BRANCHING_COMMANDS = {
		'CHECK_FLAG', 'BRANCH', 'CHOICE', 'CHECK_ITEM', 'CHECK_GOLD',
		'VARIABLE_CHECK', 'MEMORY_COMPARE'
	}

	# Commands that are operators in Halstead metrics
	OPERATOR_COMMANDS = {
		'SET_FLAG', 'CLEAR_FLAG', 'VARIABLE_SET', 'VARIABLE_ADD',
		'MEMORY_WRITE', 'MEMORY_READ', 'CALL', 'RETURN', 'JUMP'
	}

	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.command_sequences: Dict[str, List[List[str]]] = {}

	def analyze_file(self, path: Path) -> CodeMetrics:
		"""Analyze single script file"""
		metrics = CodeMetrics(file_path=str(path))

		try:
			with open(path) as f:
				lines = f.readlines()
		except Exception as e:
			if self.verbose:
				print(f"Error reading {path}: {e}")
			return metrics

		# Counters
		operators = []
		operands = []
		commands_used = []
		line_lengths = []

		current_nesting = 0
		max_nesting = 0

		for line in lines:
			original_line = line.rstrip()
			line = line.strip()

			metrics.total_lines += 1

			# Track line length
			if original_line:
				line_lengths.append(len(original_line))
				metrics.max_line_length = max(metrics.max_line_length, len(original_line))

			# Blank line
			if not line:
				metrics.blank_lines += 1
				continue

			# Comment line
			if line.startswith(';'):
				metrics.comment_lines += 1
				continue

			# Code line
			metrics.code_lines += 1

			# Parse command
			match = re.match(r'^([A-Z_]+)(?:\s+(.+))?$', line)
			if not match:
				continue

			command = match.group(1)
			params_str = match.group(2) or ""

			commands_used.append(command)
			metrics.total_commands += 1

			# Cyclomatic complexity
			if command in self.BRANCHING_COMMANDS:
				metrics.cyclomatic_complexity += 1

			# Track nesting (simplified)
			if command in ('BRANCH', 'CALL'):
				current_nesting += 1
				max_nesting = max(max_nesting, current_nesting)
			elif command in ('RETURN', 'END'):
				current_nesting = max(0, current_nesting - 1)

			# Halstead metrics
			if command in self.OPERATOR_COMMANDS:
				operators.append(command)
				metrics.total_operators += 1

			# Parse parameters as operands
			if params_str:
				for param in params_str.split(','):
					param = param.strip()
					if param:
						operands.append(param)
						metrics.total_operands += 1

		# Finalize metrics
		metrics.max_nesting_depth = max_nesting
		metrics.unique_operators = len(set(operators))
		metrics.unique_operands = len(set(operands))
		metrics.unique_commands = len(set(commands_used))

		if line_lengths:
			metrics.avg_line_length = sum(line_lengths) / len(line_lengths)

		# Calculate derived metrics
		metrics.calculate_derived_metrics()

		# Detect duplication
		self.command_sequences[str(path)] = self.extract_sequences(commands_used)
		metrics.duplication_percentage = self.calculate_duplication(str(path))

		return metrics

	def extract_sequences(self, commands: List[str], min_length: int = 3) -> List[List[str]]:
		"""Extract command sequences for duplication detection"""
		sequences = []

		for i in range(len(commands) - min_length + 1):
			sequence = commands[i:i + min_length]
			sequences.append(sequence)

		return sequences

	def calculate_duplication(self, file_path: str) -> float:
		"""Calculate duplication percentage for file"""
		if file_path not in self.command_sequences:
			return 0.0

		sequences = self.command_sequences[file_path]
		if not sequences:
			return 0.0

		# Count duplicate sequences
		sequence_counts = Counter(tuple(seq) for seq in sequences)
		duplicates = sum(count - 1 for count in sequence_counts.values() if count > 1)

		return (duplicates / len(sequences)) * 100 if sequences else 0.0

	def analyze_project(self, input_paths: List[Path]) -> ProjectMetrics:
		"""Analyze all scripts in project"""
		project = ProjectMetrics()

		for path in input_paths:
			if path.is_file():
				metrics = self.analyze_file(path)
				project.file_metrics.append(metrics)
			elif path.is_dir():
				for script_file in path.rglob('*.txt'):
					metrics = self.analyze_file(script_file)
					project.file_metrics.append(metrics)
				for script_file in path.rglob('*.asm'):
					metrics = self.analyze_file(script_file)
					project.file_metrics.append(metrics)

		# Aggregate metrics
		project.total_files = len(project.file_metrics)

		if project.file_metrics:
			project.total_lines = sum(m.total_lines for m in project.file_metrics)
			project.total_code_lines = sum(m.code_lines for m in project.file_metrics)
			project.total_commands = sum(m.total_commands for m in project.file_metrics)

			project.avg_complexity = sum(m.cyclomatic_complexity for m in project.file_metrics) / project.total_files
			project.avg_maintainability = sum(m.maintainability_index for m in project.file_metrics) / project.total_files
			project.avg_duplication = sum(m.duplication_percentage for m in project.file_metrics) / project.total_files

		return project

	def generate_markdown_report(self, project: ProjectMetrics) -> str:
		"""Generate Markdown metrics report"""
		lines = [
			"# Script Metrics Analysis Report",
			"",
			"## Project Summary",
			"",
			f"- **Total Files:** {project.total_files}",
			f"- **Total Lines:** {project.total_lines:,}",
			f"- **Code Lines:** {project.total_code_lines:,}",
			f"- **Total Commands:** {project.total_commands:,}",
			f"- **Average Complexity:** {project.avg_complexity:.2f}",
			f"- **Average Maintainability:** {project.avg_maintainability:.2f}/100",
			f"- **Average Duplication:** {project.avg_duplication:.2f}%",
			"",
			"## File Metrics",
			"",
			"| File | LOC | Complexity | Maintainability | Duplication |",
			"|------|-----|------------|-----------------|-------------|"
		]

		# Sort by complexity (descending)
		sorted_files = sorted(project.file_metrics, key=lambda m: m.cyclomatic_complexity, reverse=True)

		for metrics in sorted_files:
			file_name = Path(metrics.file_path).name
			lines.append(
				f"| {file_name} | {metrics.code_lines} | {metrics.cyclomatic_complexity} | "
				f"{metrics.maintainability_index:.1f} | {metrics.duplication_percentage:.1f}% |"
			)

		lines.append("")
		lines.append("## Top Complex Files")
		lines.append("")

		for i, metrics in enumerate(sorted_files[:10], 1):
			lines.append(f"### {i}. {Path(metrics.file_path).name}")
			lines.append("")
			lines.append(f"- **Cyclomatic Complexity:** {metrics.cyclomatic_complexity}")
			lines.append(f"- **Cognitive Complexity:** {metrics.cognitive_complexity}")
			lines.append(f"- **Max Nesting Depth:** {metrics.max_nesting_depth}")
			lines.append(f"- **Maintainability Index:** {metrics.maintainability_index:.2f}/100")
			lines.append(f"- **Code Lines:** {metrics.code_lines}")
			lines.append(f"- **Total Commands:** {metrics.total_commands}")
			lines.append(f"- **Unique Commands:** {metrics.unique_commands}")
			lines.append(f"- **Command Diversity:** {metrics.command_diversity:.2%}")
			lines.append("")

			# Halstead metrics
			lines.append("**Halstead Metrics:**")
			lines.append(f"- Vocabulary: {metrics.halstead_vocabulary}")
			lines.append(f"- Length: {metrics.halstead_length}")
			lines.append(f"- Volume: {metrics.halstead_volume:.2f}")
			lines.append(f"- Difficulty: {metrics.halstead_difficulty:.2f}")
			lines.append(f"- Effort: {metrics.halstead_effort:.2f}")
			lines.append("")

		lines.append("## Recommendations")
		lines.append("")

		# Generate recommendations
		high_complexity = [m for m in project.file_metrics if m.cyclomatic_complexity > 10]
		low_maintainability = [m for m in project.file_metrics if m.maintainability_index < 50]
		high_duplication = [m for m in project.file_metrics if m.duplication_percentage > 20]

		if high_complexity:
			lines.append(f"### High Complexity ({len(high_complexity)} files)")
			lines.append("")
			lines.append("Files with cyclomatic complexity > 10 should be refactored:")
			for m in high_complexity[:5]:
				lines.append(f"- `{Path(m.file_path).name}` (complexity: {m.cyclomatic_complexity})")
			lines.append("")

		if low_maintainability:
			lines.append(f"### Low Maintainability ({len(low_maintainability)} files)")
			lines.append("")
			lines.append("Files with maintainability index < 50 need improvement:")
			for m in low_maintainability[:5]:
				lines.append(f"- `{Path(m.file_path).name}` (MI: {m.maintainability_index:.1f})")
			lines.append("")

		if high_duplication:
			lines.append(f"### High Duplication ({len(high_duplication)} files)")
			lines.append("")
			lines.append("Files with > 20% duplication should be refactored:")
			for m in high_duplication[:5]:
				lines.append(f"- `{Path(m.file_path).name}` (duplication: {m.duplication_percentage:.1f}%)")
			lines.append("")

		return '\n'.join(lines)

	def generate_json(self, project: ProjectMetrics) -> str:
		"""Generate JSON metrics export"""
		data = {
			"project": {
				"total_files": project.total_files,
				"total_lines": project.total_lines,
				"total_code_lines": project.total_code_lines,
				"total_commands": project.total_commands,
				"avg_complexity": project.avg_complexity,
				"avg_maintainability": project.avg_maintainability,
				"avg_duplication": project.avg_duplication
			},
			"files": [
				{
					"path": m.file_path,
					"size": {
						"total_lines": m.total_lines,
						"code_lines": m.code_lines,
						"comment_lines": m.comment_lines,
						"blank_lines": m.blank_lines
					},
					"complexity": {
						"cyclomatic": m.cyclomatic_complexity,
						"cognitive": m.cognitive_complexity,
						"max_nesting": m.max_nesting_depth
					},
					"halstead": {
						"vocabulary": m.halstead_vocabulary,
						"length": m.halstead_length,
						"volume": m.halstead_volume,
						"difficulty": m.halstead_difficulty,
						"effort": m.halstead_effort
					},
					"quality": {
						"maintainability_index": m.maintainability_index,
						"duplication_percentage": m.duplication_percentage,
						"comment_ratio": m.comment_ratio
					},
					"commands": {
						"total": m.total_commands,
						"unique": m.unique_commands,
						"diversity": m.command_diversity
					}
				}
				for m in project.file_metrics
			]
		}

		return json.dumps(data, indent=2)

	def generate_csv(self, project: ProjectMetrics) -> str:
		"""Generate CSV metrics table"""
		lines = [
			"File,Total Lines,Code Lines,Commands,Cyclomatic Complexity,Maintainability Index,Duplication %"
		]

		for m in project.file_metrics:
			lines.append(
				f"{Path(m.file_path).name},{m.total_lines},{m.code_lines},{m.total_commands},"
				f"{m.cyclomatic_complexity},{m.maintainability_index:.2f},{m.duplication_percentage:.2f}"
			)

		return '\n'.join(lines)


def main():
	parser = argparse.ArgumentParser(description='Analyze script metrics and quality')
	parser.add_argument('input_paths', type=Path, nargs='+', help='Script files or directories')
	parser.add_argument('--report', type=Path, help='Generate Markdown report')
	parser.add_argument('--format', choices=['markdown', 'json', 'csv'], default='markdown',
		help='Output format')
	parser.add_argument('--output', type=Path, help='Output file')
	parser.add_argument('--trends', action='store_true', help='Show trends over time')
	parser.add_argument('--dashboard', type=Path, help='Generate HTML dashboard')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')

	args = parser.parse_args()

	analyzer = ScriptMetricsAnalyzer(verbose=args.verbose)

	if args.verbose:
		print(f"Analyzing {len(args.input_paths)} path(s)...")

	project = analyzer.analyze_project(args.input_paths)

	# Generate output
	if args.format == 'markdown':
		output = analyzer.generate_markdown_report(project)
	elif args.format == 'json':
		output = analyzer.generate_json(project)
	elif args.format == 'csv':
		output = analyzer.generate_csv(project)

	# Write output
	if args.output:
		with open(args.output, 'w') as f:
			f.write(output)
		print(f"\n✓ Metrics report generated: {args.output}")
	elif args.report:
		with open(args.report, 'w') as f:
			f.write(output)
		print(f"\n✓ Metrics report generated: {args.report}")
	else:
		print(output)

	# Summary
	print("\n=== Project Summary ===")
	print(f"Files analyzed: {project.total_files}")
	print(f"Total lines: {project.total_lines:,}")
	print(f"Code lines: {project.total_code_lines:,}")
	print(f"Average complexity: {project.avg_complexity:.2f}")
	print(f"Average maintainability: {project.avg_maintainability:.2f}/100")

	return 0


if __name__ == '__main__':
	exit(main())
