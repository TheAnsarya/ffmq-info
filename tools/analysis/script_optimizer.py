#!/usr/bin/env python3
"""
Script Optimizer - Identify optimization opportunities in event scripts
Detects inefficiencies, redundancies, and suggests improvements

Features:
- Detects redundant command sequences
- Identifies inefficient patterns (excessive WAITs, unnecessary NEWLINEs)
- Suggests subroutine extraction opportunities
- Finds duplicate text blocks
- Detects unreachable code
- Analyzes memory access patterns
- Calculates compression potential
- Generates optimization reports with before/after size estimates

Optimization Categories:
1. Redundancy Removal - Duplicate code blocks
2. Subroutine Extraction - Repeated command sequences
3. Text Deduplication - Identical text strings
4. Pattern Simplification - Command chain optimization
5. Dead Code Elimination - Unreachable code removal
6. Memory Access Optimization - Reduce redundant reads/writes

Usage:
	python script_optimizer.py --script dialogs.txt
	python script_optimizer.py --script file1.txt file2.txt --aggressive
	python script_optimizer.py --script dialogs.txt --report optimizations.md
	python script_optimizer.py --script dialogs.txt --apply --output optimized.txt
"""

import argparse
import re
import hashlib
from pathlib import Path
from typing import Dict, List, Tuple, Set, Optional
from dataclasses import dataclass, field
from collections import Counter, defaultdict
from enum import Enum


class OptimizationType(Enum):
	"""Types of optimizations available"""
	REDUNDANCY_REMOVAL = "redundancy_removal"
	SUBROUTINE_EXTRACTION = "subroutine_extraction"
	TEXT_DEDUPLICATION = "text_deduplication"
	PATTERN_SIMPLIFICATION = "pattern_simplification"
	DEAD_CODE_ELIMINATION = "dead_code_elimination"
	MEMORY_OPTIMIZATION = "memory_optimization"


class SeverityLevel(Enum):
	"""Optimization opportunity severity"""
	LOW = "low"  # Minor savings
	MEDIUM = "medium"  # Moderate savings
	HIGH = "high"  # Significant savings
	CRITICAL = "critical"  # Essential optimization


@dataclass
class CommandSequence:
	"""A sequence of commands that appears in scripts"""
	commands: List[str]
	sequence_hash: str
	occurrences: List[Tuple[str, int]]  # (dialog_id, line_number)
	total_bytes: int

	def __hash__(self):
		return hash(self.sequence_hash)


@dataclass
class TextBlock:
	"""A block of text that may be duplicated"""
	text: str
	text_hash: str
	occurrences: List[Tuple[str, int]]
	byte_count: int

	def __hash__(self):
		return hash(self.text_hash)


@dataclass
class OptimizationOpportunity:
	"""An identified optimization opportunity"""
	optimization_type: OptimizationType
	severity: SeverityLevel
	dialog_id: str
	line_numbers: List[int]
	description: str
	current_bytes: int
	optimized_bytes: int
	savings_bytes: int
	savings_percent: float
	suggestion: str
	code_before: str = ""
	code_after: str = ""


@dataclass
class MemoryAccess:
	"""Memory access pattern tracking"""
	address: str
	access_type: str  # "read" or "write"
	dialog_id: str
	line_number: int
	value: Optional[str] = None


@dataclass
class OptimizationReport:
	"""Complete optimization analysis report"""
	script_files: List[str]
	total_dialogs: int
	total_lines: int
	total_bytes: int
	opportunities: List[OptimizationOpportunity]
	potential_savings: int
	potential_savings_percent: float
	optimization_summary: Dict[str, int] = field(default_factory=dict)


class ScriptOptimizer:
	"""Analyzes and optimizes event scripts"""

	# Inefficient patterns to detect
	INEFFICIENT_PATTERNS = {
		'excessive_waits': (r'(WAIT\s+\d+\s*\n){3,}', "Multiple consecutive WAITs can be combined"),
		'unnecessary_newlines': (r'(NEWLINE\s*\n){3,}', "Multiple consecutive NEWLINEs can be reduced"),
		'redundant_flag_checks': (r'CHECK_FLAG\s+(\S+).*\nCHECK_FLAG\s+\1', "Redundant flag check"),
		'write_then_read': (r'MEMORY_WRITE\s+(\S+)\s+(\S+).*\nMEMORY_READ\s+\1', "Write followed by read of same address"),
	}

	# Minimum sequence length for subroutine extraction
	MIN_SUBROUTINE_LENGTH = 3
	MIN_SUBROUTINE_OCCURRENCES = 3

	# Minimum text length for deduplication
	MIN_TEXT_LENGTH = 20
	MIN_TEXT_OCCURRENCES = 2

	def __init__(self, aggressive: bool = False, verbose: bool = False):
		self.aggressive = aggressive
		self.verbose = verbose
		self.dialogs: Dict[str, List[str]] = {}
		self.command_sequences: List[CommandSequence] = []
		self.text_blocks: List[TextBlock] = []
		self.memory_accesses: List[MemoryAccess] = []
		self.opportunities: List[OptimizationOpportunity] = []

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
			lines = [line.strip() for line in dialog_content.split('\n') if line.strip()]
			self.dialogs[dialog_id] = lines

	def calculate_byte_size(self, lines: List[str]) -> int:
		"""Estimate byte size of compiled script"""
		total = 0
		for line in lines:
			# Simple heuristic: command = 1 byte + parameters
			if line.startswith('"'):
				# Text line
				text = line.strip('"')
				total += len(text) + 1  # +1 for null terminator
			elif 'WAIT' in line or 'NEWLINE' in line or 'END' in line:
				total += 1
			elif 'SET_FLAG' in line or 'CLEAR_FLAG' in line or 'CHECK_FLAG' in line:
				total += 2  # Command + flag ID
			elif 'CALL_SUBROUTINE' in line:
				total += 3  # Command + 2-byte address
			elif 'MEMORY_WRITE' in line or 'MEMORY_READ' in line:
				total += 4  # Command + address + value
			else:
				total += 1  # Unknown command
		return total

	def extract_command_sequences(self, min_length: int = 3) -> None:
		"""Extract all command sequences of specified minimum length"""
		sequences_dict: Dict[str, CommandSequence] = {}

		for dialog_id, lines in self.dialogs.items():
			# Extract non-text commands only
			commands = [line for line in lines if not line.startswith('"')]

			# Generate all subsequences
			for start in range(len(commands)):
				for length in range(min_length, min(len(commands) - start + 1, 10)):
					subseq = commands[start:start + length]
					seq_str = '\n'.join(subseq)
					seq_hash = hashlib.md5(seq_str.encode()).hexdigest()

					if seq_hash in sequences_dict:
						sequences_dict[seq_hash].occurrences.append((dialog_id, start))
					else:
						sequences_dict[seq_hash] = CommandSequence(
							commands=subseq,
							sequence_hash=seq_hash,
							occurrences=[(dialog_id, start)],
							total_bytes=self.calculate_byte_size(subseq)
						)

		# Filter to only sequences with multiple occurrences
		self.command_sequences = [
			seq for seq in sequences_dict.values()
			if len(seq.occurrences) >= self.MIN_SUBROUTINE_OCCURRENCES
		]

		# Sort by potential savings
		self.command_sequences.sort(
			key=lambda s: s.total_bytes * len(s.occurrences),
			reverse=True
		)

	def extract_text_blocks(self) -> None:
		"""Extract all text blocks for deduplication analysis"""
		text_dict: Dict[str, TextBlock] = {}

		for dialog_id, lines in self.dialogs.items():
			for line_num, line in enumerate(lines):
				if line.startswith('"'):
					text = line.strip('"')
					if len(text) < self.MIN_TEXT_LENGTH:
						continue

					text_hash = hashlib.md5(text.encode()).hexdigest()

					if text_hash in text_dict:
						text_dict[text_hash].occurrences.append((dialog_id, line_num))
					else:
						text_dict[text_hash] = TextBlock(
							text=text,
							text_hash=text_hash,
							occurrences=[(dialog_id, line_num)],
							byte_count=len(text) + 1
						)

		# Filter to duplicates only
		self.text_blocks = [
			block for block in text_dict.values()
			if len(block.occurrences) >= self.MIN_TEXT_OCCURRENCES
		]

		# Sort by potential savings
		self.text_blocks.sort(
			key=lambda b: b.byte_count * len(b.occurrences),
			reverse=True
		)

	def analyze_memory_accesses(self) -> None:
		"""Analyze memory access patterns for optimization"""
		for dialog_id, lines in self.dialogs.items():
			for line_num, line in enumerate(lines):
				if 'MEMORY_WRITE' in line:
					parts = line.split()
					if len(parts) >= 3:
						self.memory_accesses.append(MemoryAccess(
							address=parts[1],
							access_type='write',
							dialog_id=dialog_id,
							line_number=line_num,
							value=parts[2] if len(parts) > 2 else None
						))
				elif 'MEMORY_READ' in line:
					parts = line.split()
					if len(parts) >= 2:
						self.memory_accesses.append(MemoryAccess(
							address=parts[1],
							access_type='read',
							dialog_id=dialog_id,
							line_number=line_num
						))

	def detect_inefficient_patterns(self) -> None:
		"""Detect known inefficient patterns"""
		for dialog_id, lines in self.dialogs.items():
			dialog_text = '\n'.join(lines)

			for pattern_name, (pattern, description) in self.INEFFICIENT_PATTERNS.items():
				matches = list(re.finditer(pattern, dialog_text, re.MULTILINE))

				for match in matches:
					# Calculate line numbers
					before_match = dialog_text[:match.start()]
					start_line = before_match.count('\n')
					end_line = start_line + match.group(0).count('\n')

					# Estimate savings
					matched_lines = match.group(0).split('\n')
					current_bytes = self.calculate_byte_size(matched_lines)
					optimized_bytes = current_bytes // 2  # Rough estimate

					severity = SeverityLevel.MEDIUM
					if current_bytes > 20:
						severity = SeverityLevel.HIGH
					elif current_bytes < 5:
						severity = SeverityLevel.LOW

					self.opportunities.append(OptimizationOpportunity(
						optimization_type=OptimizationType.PATTERN_SIMPLIFICATION,
						severity=severity,
						dialog_id=dialog_id,
						line_numbers=list(range(start_line, end_line + 1)),
						description=description,
						current_bytes=current_bytes,
						optimized_bytes=optimized_bytes,
						savings_bytes=current_bytes - optimized_bytes,
						savings_percent=((current_bytes - optimized_bytes) / current_bytes * 100),
						suggestion=f"Simplify {pattern_name} pattern",
						code_before=match.group(0),
						code_after=self._suggest_pattern_fix(pattern_name, match.group(0))
					))

	def _suggest_pattern_fix(self, pattern_name: str, code: str) -> str:
		"""Suggest fix for inefficient pattern"""
		if pattern_name == 'excessive_waits':
			# Combine consecutive WAITs
			waits = re.findall(r'WAIT\s+(\d+)', code)
			total = sum(int(w) for w in waits)
			return f"WAIT {total}"
		elif pattern_name == 'unnecessary_newlines':
			# Reduce to single NEWLINE
			return "NEWLINE"
		elif pattern_name == 'redundant_flag_checks':
			# Keep only first check
			lines = code.split('\n')
			return lines[0] if lines else code
		elif pattern_name == 'write_then_read':
			# Suggest using register or eliminating read
			return code.split('\n')[0] + "\n; Consider using register to avoid read"
		return code

	def detect_subroutine_opportunities(self) -> None:
		"""Identify sequences that should be extracted as subroutines"""
		for seq in self.command_sequences:
			if len(seq.occurrences) < self.MIN_SUBROUTINE_OCCURRENCES:
				continue

			# Calculate savings
			current_bytes = seq.total_bytes * len(seq.occurrences)
			optimized_bytes = seq.total_bytes + (3 * len(seq.occurrences))  # Subroutine + CALL commands
			savings = current_bytes - optimized_bytes

			if savings <= 0:
				continue

			severity = SeverityLevel.MEDIUM
			if savings > 100:
				severity = SeverityLevel.HIGH
			if savings > 500:
				severity = SeverityLevel.CRITICAL

			# Get first occurrence for example
			first_dialog = seq.occurrences[0][0]

			self.opportunities.append(OptimizationOpportunity(
				optimization_type=OptimizationType.SUBROUTINE_EXTRACTION,
				severity=severity,
				dialog_id=first_dialog,
				line_numbers=[occ[1] for occ in seq.occurrences],
				description=f"Command sequence repeated {len(seq.occurrences)} times",
				current_bytes=current_bytes,
				optimized_bytes=optimized_bytes,
				savings_bytes=savings,
				savings_percent=(savings / current_bytes * 100),
				suggestion=f"Extract as subroutine SUB_{seq.sequence_hash[:8].upper()}",
				code_before='\n'.join(seq.commands),
				code_after=f"CALL_SUBROUTINE SUB_{seq.sequence_hash[:8].upper()}"
			))

	def detect_text_deduplication(self) -> None:
		"""Identify duplicate text blocks"""
		for block in self.text_blocks:
			if len(block.occurrences) < self.MIN_TEXT_OCCURRENCES:
				continue

			# Calculate savings
			current_bytes = block.byte_count * len(block.occurrences)
			optimized_bytes = block.byte_count + (3 * len(block.occurrences))  # Text + CALL references
			savings = current_bytes - optimized_bytes

			if savings <= 0:
				continue

			severity = SeverityLevel.LOW
			if savings > 50:
				severity = SeverityLevel.MEDIUM
			if savings > 200:
				severity = SeverityLevel.HIGH

			first_dialog = block.occurrences[0][0]

			self.opportunities.append(OptimizationOpportunity(
				optimization_type=OptimizationType.TEXT_DEDUPLICATION,
				severity=severity,
				dialog_id=first_dialog,
				line_numbers=[occ[1] for occ in block.occurrences],
				description=f"Text appears {len(block.occurrences)} times",
				current_bytes=current_bytes,
				optimized_bytes=optimized_bytes,
				savings_bytes=savings,
				savings_percent=(savings / current_bytes * 100),
				suggestion=f"Create text subroutine TEXT_{block.text_hash[:8].upper()}",
				code_before=f'"{block.text}"',
				code_after=f"CALL_SUBROUTINE TEXT_{block.text_hash[:8].upper()}"
			))

	def detect_dead_code(self) -> None:
		"""Detect unreachable code after END, RETURN, etc."""
		for dialog_id, lines in self.dialogs.items():
			for i, line in enumerate(lines):
				if line in ['END', 'RETURN']:
					# Check if there's code after this
					if i < len(lines) - 1:
						remaining_lines = lines[i + 1:]
						dead_bytes = self.calculate_byte_size(remaining_lines)

						if dead_bytes > 0:
							self.opportunities.append(OptimizationOpportunity(
								optimization_type=OptimizationType.DEAD_CODE_ELIMINATION,
								severity=SeverityLevel.MEDIUM,
								dialog_id=dialog_id,
								line_numbers=list(range(i + 1, len(lines))),
								description=f"Unreachable code after {line}",
								current_bytes=dead_bytes,
								optimized_bytes=0,
								savings_bytes=dead_bytes,
								savings_percent=100.0,
								suggestion="Remove unreachable code",
								code_before='\n'.join(remaining_lines),
								code_after=""
							))
						break

	def detect_memory_optimizations(self) -> None:
		"""Detect redundant memory operations"""
		# Group by address
		by_address: Dict[str, List[MemoryAccess]] = defaultdict(list)
		for access in self.memory_accesses:
			by_address[access.address].append(access)

		# Find redundant patterns
		for address, accesses in by_address.items():
			# Sort by dialog and line number
			accesses.sort(key=lambda a: (a.dialog_id, a.line_number))

			# Look for write-read pairs in same dialog
			for i in range(len(accesses) - 1):
				if (accesses[i].access_type == 'write' and
					accesses[i + 1].access_type == 'read' and
					accesses[i].dialog_id == accesses[i + 1].dialog_id and
					accesses[i + 1].line_number - accesses[i].line_number <= 5):

					self.opportunities.append(OptimizationOpportunity(
						optimization_type=OptimizationType.MEMORY_OPTIMIZATION,
						severity=SeverityLevel.LOW,
						dialog_id=accesses[i].dialog_id,
						line_numbers=[accesses[i].line_number, accesses[i + 1].line_number],
						description=f"Write to {address} followed by read",
						current_bytes=8,  # 4 bytes per operation
						optimized_bytes=4,  # Keep value in register
						savings_bytes=4,
						savings_percent=50.0,
						suggestion="Store value in register instead of re-reading from memory",
						code_before=f"MEMORY_WRITE {address} {accesses[i].value}\n...\nMEMORY_READ {address}",
						code_after=f"MEMORY_WRITE {address} {accesses[i].value}\n...\n; Use register value"
					))

	def analyze(self, script_paths: List[Path]) -> OptimizationReport:
		"""Perform complete optimization analysis"""
		# Parse all scripts
		for path in script_paths:
			self.parse_script_file(path)

		total_lines = sum(len(lines) for lines in self.dialogs.values())
		total_bytes = sum(self.calculate_byte_size(lines) for lines in self.dialogs.values())

		if self.verbose:
			print(f"\nAnalyzing {len(self.dialogs)} dialogs ({total_lines} lines, ~{total_bytes} bytes)...")

		# Run all analyses
		self.extract_command_sequences()
		self.extract_text_blocks()
		self.analyze_memory_accesses()

		self.detect_inefficient_patterns()
		self.detect_subroutine_opportunities()
		self.detect_text_deduplication()
		self.detect_dead_code()
		self.detect_memory_optimizations()

		# Calculate total potential savings
		total_savings = sum(opp.savings_bytes for opp in self.opportunities)
		savings_percent = (total_savings / total_bytes * 100) if total_bytes > 0 else 0

		# Group by type
		summary = {}
		for opp in self.opportunities:
			opt_type = opp.optimization_type.value
			if opt_type not in summary:
				summary[opt_type] = 0
			summary[opt_type] += opp.savings_bytes

		return OptimizationReport(
			script_files=[str(p) for p in script_paths],
			total_dialogs=len(self.dialogs),
			total_lines=total_lines,
			total_bytes=total_bytes,
			opportunities=sorted(self.opportunities, key=lambda o: o.savings_bytes, reverse=True),
			potential_savings=total_savings,
			potential_savings_percent=savings_percent,
			optimization_summary=summary
		)

	def generate_report(self, report: OptimizationReport) -> str:
		"""Generate Markdown optimization report"""
		lines = [
			"# Script Optimization Report",
			"",
			"## Summary",
			f"- **Scripts Analyzed**: {len(report.script_files)}",
			f"- **Total Dialogs**: {report.total_dialogs}",
			f"- **Total Lines**: {report.total_lines:,}",
			f"- **Total Bytes**: {report.total_bytes:,}",
			f"- **Optimization Opportunities**: {len(report.opportunities)}",
			f"- **Potential Savings**: {report.potential_savings:,} bytes ({report.potential_savings_percent:.1f}%)",
			"",
			"## Savings by Category",
			""
		]

		for opt_type, savings in sorted(report.optimization_summary.items(), key=lambda x: x[1], reverse=True):
			percent = (savings / report.total_bytes * 100) if report.total_bytes > 0 else 0
			lines.append(f"- **{opt_type.replace('_', ' ').title()}**: {savings:,} bytes ({percent:.1f}%)")

		lines.extend([
			"",
			"## Top Optimization Opportunities",
			""
		])

		# Group by severity
		by_severity = {
			SeverityLevel.CRITICAL: [],
			SeverityLevel.HIGH: [],
			SeverityLevel.MEDIUM: [],
			SeverityLevel.LOW: []
		}

		for opp in report.opportunities:
			by_severity[opp.severity].append(opp)

		for severity in [SeverityLevel.CRITICAL, SeverityLevel.HIGH, SeverityLevel.MEDIUM, SeverityLevel.LOW]:
			opps = by_severity[severity]
			if not opps:
				continue

			lines.append(f"### {severity.value.upper()} Priority ({len(opps)} opportunities)")
			lines.append("")

			for opp in opps[:20]:  # Top 20 per severity
				lines.extend([
					f"#### {opp.dialog_id} - {opp.description}",
					f"- **Type**: {opp.optimization_type.value.replace('_', ' ').title()}",
					f"- **Savings**: {opp.savings_bytes} bytes ({opp.savings_percent:.1f}%)",
					f"- **Suggestion**: {opp.suggestion}",
					""
				])

				if opp.code_before:
					lines.extend([
						"**Before:**",
						"```",
						opp.code_before[:200] + ("..." if len(opp.code_before) > 200 else ""),
						"```",
						""
					])

				if opp.code_after:
					lines.extend([
						"**After:**",
						"```",
						opp.code_after[:200] + ("..." if len(opp.code_after) > 200 else ""),
						"```",
						""
					])

		return '\n'.join(lines)

	def apply_optimizations(self, output_path: Path, optimizations_to_apply: Optional[List[str]] = None) -> None:
		"""Apply optimizations and save optimized script"""
		# For now, just generate optimized version with comments
		# Full implementation would actually apply transformations

		lines = [
			"; Optimized Script",
			f"; Original size: {sum(self.calculate_byte_size(lines) for lines in self.dialogs.values())} bytes",
			f"; Optimized size: TBD",
			f"; Savings: TBD",
			"",
			"; NOTE: This is a preview. Manual review required.",
			""
		]

		for dialog_id, dialog_lines in sorted(self.dialogs.items()):
			lines.append(f"DIALOG {dialog_id}:")
			lines.extend(dialog_lines)
			lines.append("")

		with open(output_path, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))

		if self.verbose:
			print(f"\nOptimized script written to {output_path}")


def main():
	parser = argparse.ArgumentParser(description='Optimize event scripts for size and efficiency')
	parser.add_argument('--script', type=Path, nargs='+', required=True, help='Script file(s) to analyze')
	parser.add_argument('--report', type=Path, help='Output optimization report')
	parser.add_argument('--apply', action='store_true', help='Apply optimizations (preview mode)')
	parser.add_argument('--output', type=Path, help='Output file for optimized script')
	parser.add_argument('--aggressive', action='store_true', help='Enable aggressive optimizations')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')

	args = parser.parse_args()

	optimizer = ScriptOptimizer(aggressive=args.aggressive, verbose=args.verbose)

	# Analyze scripts
	report = optimizer.analyze(args.script)

	# Generate report
	if args.report:
		report_text = optimizer.generate_report(report)
		with open(args.report, 'w', encoding='utf-8') as f:
			f.write(report_text)
		if args.verbose:
			print(f"\nReport saved to {args.report}")

	# Apply optimizations
	if args.apply and args.output:
		optimizer.apply_optimizations(args.output)

	# Print summary
	print(f"\n✓ Analysis complete")
	print(f"  Found {len(report.opportunities)} optimization opportunities")
	print(f"  Potential savings: {report.potential_savings:,} bytes ({report.potential_savings_percent:.1f}%)")
	print(f"\nTop 5 Opportunities:")
	for i, opp in enumerate(report.opportunities[:5], 1):
		print(f"  {i}. {opp.dialog_id}: {opp.description} ({opp.savings_bytes} bytes)")

	return 0


if __name__ == '__main__':
	exit(main())
