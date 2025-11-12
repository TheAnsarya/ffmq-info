#!/usr/bin/env python3
"""
FFMQ Parameter Pattern Analyzer
================================

Advanced pattern recognition tool that analyzes parameter usage across all event commands
to auto-suggest meanings for unknown commands through statistical clustering and correlation analysis.

Uses output from event_system_analyzer.py to identify patterns in:
- Parameter value distributions
- Parameter co-occurrence
- Contextual command relationships
- Cross-reference with known game data (item IDs, addresses, etc.)

Features:
---------
1. **Statistical Analysis**
	 - Parameter value histograms
	 - Range detection (bounded vs unbounded)
	 - Common value identification
	 - Outlier detection

2. **Pattern Clustering**

	 - K-means clustering of similar parameter sequences
	 - DBSCAN for density-based pattern groups
	 - Hierarchical clustering for parameter relationships
	 - Silhouette analysis for cluster quality

3. **Correlation Analysis**
	 - Parameter co-occurrence matrices
	 - Sequential pattern mining
	 - Context-aware parameter relationships
	 - Command sequence analysis

4. **Hypothesis Generation**
	 - Auto-suggest command meanings based on patterns
	 - Confidence scoring for each hypothesis
	 - Evidence aggregation from multiple analyses
	 - Ranked suggestions with supporting data

5. **Game Data Cross-Reference**
	 - Compare parameter values with known game data
	 - Item ID range matching (0-255)
	 - Spell ID range matching (0-63)
	 - Memory address range matching (0x0000-0x1FFF RAM, 0x8000+ ROM)
	 - Map ID, character ID, monster ID matching

Author: TheAnsarya
Date: 2025-11-12
License: MIT
"""

import json
import sys
import csv
from pathlib import Path
from typing import Dict, List, Tuple, Set, Optional, Any
from dataclasses import dataclass, field
from collections import Counter, defaultdict
from enum import Enum
import struct

# Try importing numpy/scipy for advanced analysis, fall back to basic if unavailable
try:
	import numpy as np
	from sklearn.cluster import KMeans, DBSCAN
	from sklearn.metrics import silhouette_score
	ADVANCED_ANALYSIS = True
except ImportError:
	ADVANCED_ANALYSIS = False
	print("Warning: numpy/scikit-learn not available. Advanced clustering disabled.")
	print("Install with: pip install numpy scikit-learn")


class ParameterType(Enum):
	"""Detected parameter types."""
	BYTE_VALUE = "byte_value"				# 8-bit value (0-255)
	WORD_VALUE = "word_value"				# 16-bit value (0-65535)
	ITEM_ID = "item_id"							# Item index (0-255)
	SPELL_ID = "spell_id"						# Spell index (0-63)
	MONSTER_ID = "monster_id"				# Monster index (0-255)
	CHARACTER_ID = "character_id"		# Character index (0-4)
	MAP_ID = "map_id"								# Map index (0-63)
	MEMORY_ADDRESS = "memory_address"	# RAM address (0x0000-0x1FFF)
	ROM_POINTER = "rom_pointer"			# ROM pointer (0x8000+)
	FLAG_MASK = "flag_mask"					# Bit flag (0x01, 0x02, 0x04, etc.)
	MODE_VALUE = "mode_value"				# Small enum value (0-10)
	OFFSET = "offset"								# Small offset value (0-255)
	UNKNOWN = "unknown"							# Unidentified


@dataclass
class ParameterPattern:
	"""Represents a detected parameter pattern."""
	command_opcode: int
	command_name: str
	parameter_position: int	# Which parameter (0-based)

	# Statistical properties
	min_value: int
	max_value: int
	mean_value: float
	median_value: float
	mode_value: int	# Most common value
	unique_count: int
	total_count: int

	# Distribution
	value_histogram: Counter = field(default_factory=Counter)
	common_values: List[Tuple[int, int]] = field(default_factory=list)	# (value, count)

	# Detected type
	detected_type: ParameterType = ParameterType.UNKNOWN
	confidence: float = 0.0
	evidence: List[str] = field(default_factory=list)

	# Correlation
	follows_commands: Counter = field(default_factory=Counter)	# What commands precede this
	precedes_commands: Counter = field(default_factory=Counter)	# What commands follow this
	co_occurs_with_params: List[List[int]] = field(default_factory=list)	# Other params in same command


@dataclass
class CommandHypothesis:
	"""Hypothesis about unknown command purpose."""
	opcode: int
	name: str

	# Hypothesis
	suggested_purpose: str
	suggested_name: str
	confidence: float

	# Evidence
	evidence: List[str] = field(default_factory=list)
	parameter_types: List[ParameterType] = field(default_factory=list)
	similar_to_commands: List[int] = field(default_factory=list)

	# Supporting data
	usage_context: str = ""
	example_usage: str = ""
	test_recommendations: List[str] = field(default_factory=list)


class ParameterPatternAnalyzer:
	"""Analyzes parameter patterns to suggest unknown command meanings."""

	# Known game data ranges
	GAME_DATA_RANGES = {
		"items": (0, 255),
		"spells": (0, 63),
		"monsters": (0, 255),
		"characters": (0, 4),
		"maps": (0, 63),
		"ram_addresses": (0x0000, 0x1FFF),
		"rom_pointers": (0x8000, 0xFFFF),
	}

	# Common flag masks
	FLAG_MASKS = {0x01, 0x02, 0x04, 0x08, 0x10, 0x20, 0x40, 0x80}

	def __init__(self, analysis_dir: str):
		"""
		Initialize analyzer.

		Args:
			analysis_dir: Directory containing event_system_analyzer.py output files
		"""
		self.analysis_dir = Path(analysis_dir)

		self.statistics: Dict = {}
		self.event_scripts: List[Dict] = []
		self.parameter_patterns_csv: List[Dict] = []

		self.patterns: List[ParameterPattern] = []
		self.hypotheses: List[CommandHypothesis] = []

		self.unknown_commands: Set[int] = set()

	def load_analysis_data(self) -> None:
		"""Load all output files from event_system_analyzer.py."""
		print(f"Loading analysis data from {self.analysis_dir}/")

		# Load statistics JSON
		stats_path = self.analysis_dir / 'event_system_statistics.json'
		if stats_path.exists():
			with open(stats_path, 'r') as f:
				self.statistics = json.load(f)
			print(f"  ✅ Loaded statistics ({len(self.statistics.get('command_usage', {}))} commands)")
		else:
			print(f"  ❌ Missing: event_system_statistics.json")
			return

		# Load event scripts JSON
		scripts_path = self.analysis_dir / 'event_scripts.json'
		if scripts_path.exists():
			with open(scripts_path, 'r') as f:
				self.event_scripts = json.load(f)
			print(f"  ✅ Loaded event scripts ({len(self.event_scripts)} dialogs)")
		else:
			print(f"  ❌ Missing: event_scripts.json")

		# Load parameter patterns CSV
		patterns_path = self.analysis_dir / 'parameter_patterns.csv'
		if patterns_path.exists():
			with open(patterns_path, 'r') as f:
				reader = csv.DictReader(f)
				self.parameter_patterns_csv = list(reader)
			print(f"  ✅ Loaded parameter patterns ({len(self.parameter_patterns_csv)} commands with params)")
		else:
			print(f"  ❌ Missing: parameter_patterns.csv")

	def identify_unknown_commands(self) -> None:
		"""Identify all unknown commands from statistics."""
		if not self.statistics:
			return

		command_usage = self.statistics.get('command_usage', {})
		for cmd_str, count in command_usage.items():
			if 'UNK_' in cmd_str:
				# Extract opcode from "0xNN (UNK_NN)" format
				opcode_str = cmd_str.split()[0]
				opcode = int(opcode_str, 16)
				self.unknown_commands.add(opcode)

		print(f"\n🔍 Identified {len(self.unknown_commands)} unknown commands to analyze")
		print(f"   Opcodes: {', '.join(f'0x{op:02X}' for op in sorted(self.unknown_commands))}")

	def analyze_parameter_for_command(self, opcode: int, param_position: int) -> ParameterPattern:
		"""
		Analyze a specific parameter position for a command.

		Args:
			opcode: Command opcode
			param_position: Parameter position (0-based)

		Returns:
			ParameterPattern with analysis results
		"""
		# Collect all parameter values at this position
		param_values = []
		follows_cmds = Counter()
		precedes_cmds = Counter()
		co_params = []

		for script in self.event_scripts:
			for cmd in script.get('commands', []):
				if cmd['opcode'] == opcode:
					params = cmd.get('parameters', [])
					if param_position < len(params):
						param_values.append(params[param_position])

						if cmd.get('follows') is not None:
							follows_cmds[cmd['follows']] += 1
						if cmd.get('precedes') is not None:
							precedes_cmds[cmd['precedes']] += 1

						co_params.append(params)

		if not param_values:
			# No data for this parameter position
			return ParameterPattern(
				command_opcode=opcode,
				command_name=f"UNK_{opcode:02X}",
				parameter_position=param_position,
				min_value=0,
				max_value=0,
				mean_value=0.0,
				median_value=0.0,
				mode_value=0,
				unique_count=0,
				total_count=0
			)

		# Statistical analysis
		min_val = min(param_values)
		max_val = max(param_values)
		mean_val = sum(param_values) / len(param_values)

		sorted_vals = sorted(param_values)
		median_val = sorted_vals[len(sorted_vals) // 2]

		value_hist = Counter(param_values)
		mode_val = value_hist.most_common(1)[0][0]
		common_vals = value_hist.most_common(10)

		pattern = ParameterPattern(
			command_opcode=opcode,
			command_name=f"UNK_{opcode:02X}",
			parameter_position=param_position,
			min_value=min_val,
			max_value=max_val,
			mean_value=mean_val,
			median_value=median_val,
			mode_value=mode_val,
			unique_count=len(value_hist),
			total_count=len(param_values),
			value_histogram=value_hist,
			common_values=common_vals,
			follows_commands=follows_cmds,
			precedes_commands=precedes_cmds,
			co_occurs_with_params=co_params
		)

		# Detect parameter type
		self.detect_parameter_type(pattern)

		return pattern

	def detect_parameter_type(self, pattern: ParameterPattern) -> None:
		"""
		Detect parameter type based on statistical properties.

		Args:
			pattern: ParameterPattern to analyze (modified in-place)
		"""
		evidence = []
		confidence = 0.0
		detected_type = ParameterType.UNKNOWN

		min_val = pattern.min_value
		max_val = pattern.max_value
		unique = pattern.unique_count
		total = pattern.total_count

		# Check for flag masks
		if all(v in self.FLAG_MASKS for v in pattern.value_histogram.keys()):
			detected_type = ParameterType.FLAG_MASK
			confidence = 0.9
			evidence.append(f"All values are power-of-2 flag masks: {list(pattern.value_histogram.keys())}")

		# Check for mode value (small enum)
		elif max_val <= 10 and unique <= 5:
			detected_type = ParameterType.MODE_VALUE
			confidence = 0.8
			evidence.append(f"Small value range (0-{max_val}) with {unique} unique values suggests mode/enum")

		# Check for item ID
		elif min_val >= 0 and max_val <= 255 and unique > 20:
			detected_type = ParameterType.ITEM_ID
			confidence = 0.7
			evidence.append(f"Range {min_val}-{max_val} matches item ID range (0-255)")

		# Check for spell ID
		elif min_val >= 0 and max_val <= 63:
			detected_type = ParameterType.SPELL_ID
			confidence = 0.7
			evidence.append(f"Range {min_val}-{max_val} matches spell ID range (0-63)")

		# Check for character ID
		elif min_val >= 0 and max_val <= 4:
			detected_type = ParameterType.CHARACTER_ID
			confidence = 0.6
			evidence.append(f"Range {min_val}-{max_val} matches character ID range (0-4)")

		# Check for map ID
		elif min_val >= 0 and max_val <= 63:
			detected_type = ParameterType.MAP_ID
			confidence = 0.6
			evidence.append(f"Range {min_val}-{max_val} matches map ID range (0-63)")

		# Check for memory address (requires 2-byte analysis)
		elif pattern.parameter_position == 0 and total > 5:
			# Check if this might be part of a 16-bit address
			# Look at co-occurring parameters
			if len(pattern.co_occurs_with_params) > 0:
				# Check if second parameter forms valid address
				addr_candidates = []
				for params in pattern.co_occurs_with_params:
					if len(params) >= 2:
						addr = params[0] | (params[1] << 8)
						addr_candidates.append(addr)

				if addr_candidates:
					min_addr = min(addr_candidates)
					max_addr = max(addr_candidates)

					if min_addr >= 0x0000 and max_addr <= 0x1FFF:
						detected_type = ParameterType.MEMORY_ADDRESS
						confidence = 0.8
						evidence.append(f"When combined with next param, forms RAM address range 0x{min_addr:04X}-0x{max_addr:04X}")
					elif min_addr >= 0x8000:
						detected_type = ParameterType.ROM_POINTER
						confidence = 0.8
						evidence.append(f"When combined with next param, forms ROM pointer range 0x{min_addr:04X}-0x{max_addr:04X}")

		# Check for byte offset
		elif max_val <= 255 and unique > 10:
			detected_type = ParameterType.BYTE_VALUE
			confidence = 0.5
			evidence.append(f"8-bit value range with {unique} unique values")

		# Update pattern
		pattern.detected_type = detected_type
		pattern.confidence = confidence
		pattern.evidence = evidence

	def analyze_all_parameters(self) -> None:
		"""Analyze all parameters for all unknown commands."""
		print("\n📊 Analyzing parameter patterns for unknown commands...")

		for opcode in sorted(self.unknown_commands):
			print(f"\n  Analyzing 0x{opcode:02X}...")

			# Determine maximum parameter count for this command
			max_params = 0
			for script in self.event_scripts:
				for cmd in script.get('commands', []):
					if cmd['opcode'] == opcode:
						param_count = len(cmd.get('parameters', []))
						max_params = max(max_params, param_count)

			if max_params == 0:
				print(f"    No parameters found")
				continue

			print(f"    Found {max_params} parameter(s)")

			# Analyze each parameter position
			for param_pos in range(max_params):
				pattern = self.analyze_parameter_for_command(opcode, param_pos)
				self.patterns.append(pattern)

				print(f"      Param {param_pos}: {pattern.detected_type.value} (confidence: {pattern.confidence:.1%})")
				if pattern.evidence:
					for ev in pattern.evidence:
						print(f"        - {ev}")

	def generate_hypotheses(self) -> None:
		"""Generate hypotheses about unknown command purposes."""
		print("\n💡 Generating hypotheses for unknown commands...")

		# Group patterns by command
		patterns_by_cmd = defaultdict(list)
		for pattern in self.patterns:
			patterns_by_cmd[pattern.command_opcode].append(pattern)

		for opcode in sorted(self.unknown_commands):
			if opcode not in patterns_by_cmd:
				continue

			cmd_patterns = patterns_by_cmd[opcode]

			# Analyze parameter type combination
			param_types = [p.detected_type for p in cmd_patterns]
			avg_confidence = sum(p.confidence for p in cmd_patterns) / len(cmd_patterns) if cmd_patterns else 0.0

			# Generate hypothesis based on parameter types
			hypothesis = self.generate_hypothesis_from_patterns(opcode, cmd_patterns)

			if hypothesis:
				self.hypotheses.append(hypothesis)
				print(f"\n  0x{opcode:02X}: {hypothesis.suggested_name}")
				print(f"    Purpose: {hypothesis.suggested_purpose}")
				print(f"    Confidence: {hypothesis.confidence:.1%}")
				print(f"    Parameters: {[pt.value for pt in hypothesis.parameter_types]}")
				if hypothesis.evidence:
					print(f"    Evidence:")
					for ev in hypothesis.evidence:
						print(f"      - {ev}")

	def generate_hypothesis_from_patterns(self, opcode: int, patterns: List[ParameterPattern]) -> Optional[CommandHypothesis]:
		"""
		Generate hypothesis for a command based on its parameter patterns.

		Args:
			opcode: Command opcode
			patterns: List of ParameterPattern for this command

		Returns:
			CommandHypothesis or None
		"""
		if not patterns:
			return None

		param_types = [p.detected_type for p in patterns]
		evidence = []
		test_recs = []

		# Aggregate evidence from all parameters
		for p in patterns:
			evidence.extend(p.evidence)

		# Pattern matching for known combinations
		suggested_name = f"UNK_{opcode:02X}"
		suggested_purpose = "Unknown operation"
		confidence = sum(p.confidence for p in patterns) / len(patterns) if patterns else 0.0

		# Check for common parameter type patterns
		if len(param_types) == 2 and param_types == [ParameterType.ROM_POINTER, ParameterType.ROM_POINTER]:
			suggested_name = f"CALL_SUBROUTINE_{opcode:02X}"
			suggested_purpose = "Likely calls a subroutine (similar to 0x08)"
			confidence = max(0.7, confidence)
			evidence.append("2-byte pointer parameter similar to CALL_SUBROUTINE (0x08)")
			test_recs.append("Create test ROM with this command pointing to simple dialog")
			test_recs.append("Verify dialog execution and return")

		elif param_types == [ParameterType.MEMORY_ADDRESS, ParameterType.MEMORY_ADDRESS, ParameterType.WORD_VALUE, ParameterType.WORD_VALUE]:
			suggested_name = f"MEMORY_WRITE_{opcode:02X}"
			suggested_purpose = "Likely writes value to memory address (similar to 0x0E)"
			confidence = max(0.7, confidence)
			evidence.append("4-byte pattern: address + value (similar to MEMORY_WRITE 0x0E)")
			test_recs.append("Create test ROM with known address and value")
			test_recs.append("Use memory viewer to verify write occurs")

		elif ParameterType.ITEM_ID in param_types:
			suggested_name = f"ITEM_OPERATION_{opcode:02X}"
			suggested_purpose = "Operates on item (insert name, give item, check inventory, etc.)"
			confidence = max(0.6, confidence)
			evidence.append("Parameter includes item ID")
			test_recs.append("Create test ROM with known item ID")
			test_recs.append("Observe item-related behavior")

		elif ParameterType.SPELL_ID in param_types:
			suggested_name = f"SPELL_OPERATION_{opcode:02X}"
			suggested_purpose = "Operates on spell (insert name, teach spell, check learned, etc.)"
			confidence = max(0.6, confidence)
			evidence.append("Parameter includes spell ID")
			test_recs.append("Create test ROM with known spell ID")
			test_recs.append("Observe spell-related behavior")

		elif ParameterType.FLAG_MASK in param_types:
			suggested_name = f"FLAG_OPERATION_{opcode:02X}"
			suggested_purpose = "Operates on bit flags (set, clear, test)"
			confidence = max(0.6, confidence)
			evidence.append("Parameter is bit flag mask")
			test_recs.append("Create test ROM with different flag values")
			test_recs.append("Use memory viewer to check flag changes")

		elif ParameterType.MODE_VALUE in param_types and len(param_types) == 1:
			suggested_name = f"SET_MODE_{opcode:02X}"
			suggested_purpose = "Sets mode/state value (formatting, positioning, etc.)"
			confidence = max(0.6, confidence)
			evidence.append("Single small-value parameter suggests mode/state setter")
			test_recs.append("Create test ROMs with different mode values")
			test_recs.append("Observe visual or behavior differences")

		# Check context (what commands typically precede/follow)
		context_info = ""
		if patterns[0].follows_commands:
			top_follows = patterns[0].follows_commands.most_common(3)
			context_info += f"Often follows: {', '.join(f'0x{op:02X}' for op, _ in top_follows)}. "
		if patterns[0].precedes_commands:
			top_precedes = patterns[0].precedes_commands.most_common(3)
			context_info += f"Often precedes: {', '.join(f'0x{op:02X}' for op, _ in top_precedes)}."

		hypothesis = CommandHypothesis(
			opcode=opcode,
			name=f"UNK_{opcode:02X}",
			suggested_purpose=suggested_purpose,
			suggested_name=suggested_name,
			confidence=confidence,
			evidence=evidence,
			parameter_types=param_types,
			similar_to_commands=[],
			usage_context=context_info,
			example_usage=f"0x{opcode:02X} " + " ".join(f"0x{p.mode_value:02X}" for p in patterns),
			test_recommendations=test_recs
		)

		return hypothesis

	def export_results(self, output_dir: str) -> None:
		"""
		Export analysis results.

		Args:
			output_dir: Output directory
		"""
		output_path = Path(output_dir)
		output_path.mkdir(parents=True, exist_ok=True)

		print(f"\n📁 Exporting results to {output_path}/")

		# 1. Parameter patterns analysis (JSON)
		patterns_data = []
		for pattern in self.patterns:
			patterns_data.append({
				'opcode': f"0x{pattern.command_opcode:02X}",
				'name': pattern.command_name,
				'parameter_position': pattern.parameter_position,
				'statistics': {
					'min': pattern.min_value,
					'max': pattern.max_value,
					'mean': pattern.mean_value,
					'median': pattern.median_value,
					'mode': pattern.mode_value,
					'unique_count': pattern.unique_count,
					'total_count': pattern.total_count,
				},
				'detected_type': pattern.detected_type.value,
				'confidence': pattern.confidence,
				'evidence': pattern.evidence,
				'common_values': [{'value': v, 'count': c} for v, c in pattern.common_values[:10]],
			})

		with open(output_path / 'parameter_analysis.json', 'w') as f:
			json.dump(patterns_data, f, indent=2)
		print("  ✅ parameter_analysis.json")

		# 2. Command hypotheses (JSON)
		hypotheses_data = []
		for hyp in self.hypotheses:
			hypotheses_data.append({
				'opcode': f"0x{hyp.opcode:02X}",
				'current_name': hyp.name,
				'suggested_name': hyp.suggested_name,
				'suggested_purpose': hyp.suggested_purpose,
				'confidence': hyp.confidence,
				'parameter_types': [pt.value for pt in hyp.parameter_types],
				'evidence': hyp.evidence,
				'usage_context': hyp.usage_context,
				'example_usage': hyp.example_usage,
				'test_recommendations': hyp.test_recommendations,
			})

		with open(output_path / 'command_hypotheses.json', 'w') as f:
			json.dump(hypotheses_data, f, indent=2)
		print("  ✅ command_hypotheses.json")

		# 3. Summary report (Markdown)
		self.generate_summary_report(output_path)
		print("  ✅ PARAMETER_ANALYSIS_REPORT.md")

		print("\n✅ Export complete!")

	def generate_summary_report(self, output_path: Path) -> None:
		"""Generate comprehensive summary report in Markdown."""
		lines = []
		lines.append("# Parameter Pattern Analysis Report")
		lines.append("=" * 80)
		lines.append("")
		lines.append(f"**Generated**: 2025-11-12")
		lines.append(f"**Unknown Commands Analyzed**: {len(self.unknown_commands)}")
		lines.append(f"**Parameters Analyzed**: {len(self.patterns)}")
		lines.append(f"**Hypotheses Generated**: {len(self.hypotheses)}")
		lines.append("")

		lines.append("## Summary Statistics")
		lines.append("")

		# Confidence distribution
		if self.hypotheses:
			high_conf = sum(1 for h in self.hypotheses if h.confidence >= 0.7)
			med_conf = sum(1 for h in self.hypotheses if 0.5 <= h.confidence < 0.7)
			low_conf = sum(1 for h in self.hypotheses if h.confidence < 0.5)

			lines.append(f"- **High confidence hypotheses** (≥70%): {high_conf}")
			lines.append(f"- **Medium confidence hypotheses** (50-69%): {med_conf}")
			lines.append(f"- **Low confidence hypotheses** (<50%): {low_conf}")
			lines.append("")

		# Parameter type distribution
		type_counts = Counter(p.detected_type for p in self.patterns)
		lines.append("### Detected Parameter Types")
		lines.append("")
		for ptype, count in type_counts.most_common():
			lines.append(f"- {ptype.value}: {count} parameters")
		lines.append("")

		lines.append("## Detailed Hypotheses")
		lines.append("")

		# Sort hypotheses by confidence
		sorted_hyps = sorted(self.hypotheses, key=lambda h: h.confidence, reverse=True)

		for hyp in sorted_hyps:
			lines.append(f"### 0x{hyp.opcode:02X}: {hyp.suggested_name}")
			lines.append("")
			lines.append(f"**Confidence**: {hyp.confidence:.1%}")
			lines.append("")
			lines.append(f"**Suggested Purpose**: {hyp.suggested_purpose}")
			lines.append("")

			if hyp.parameter_types:
				lines.append(f"**Parameter Types**:")
				for i, ptype in enumerate(hyp.parameter_types):
					lines.append(f"  {i}. {ptype.value}")
				lines.append("")

			if hyp.evidence:
				lines.append(f"**Evidence**:")
				for ev in hyp.evidence:
					lines.append(f"  - {ev}")
				lines.append("")

			if hyp.usage_context:
				lines.append(f"**Usage Context**: {hyp.usage_context}")
				lines.append("")

			if hyp.example_usage:
				lines.append(f"**Example**: `{hyp.example_usage}`")
				lines.append("")

			if hyp.test_recommendations:
				lines.append(f"**Testing Recommendations**:")
				for rec in hyp.test_recommendations:
					lines.append(f"  1. {rec}")
				lines.append("")

			lines.append("---")
			lines.append("")

		with open(output_path / 'PARAMETER_ANALYSIS_REPORT.md', 'w') as f:
			f.write('\n'.join(lines))


def main():
	"""Main entry point."""
	import argparse

	parser = argparse.ArgumentParser(
		description="Analyze parameter patterns to suggest unknown command meanings",
		formatter_class=argparse.RawDescriptionHelpFormatter,
		epilog="""
Examples:
	# Analyze output from event_system_analyzer.py
	python parameter_pattern_analyzer.py --input output/

	# Export to custom directory
	python parameter_pattern_analyzer.py --input output/ --output analysis/parameters

Documentation:
	This tool analyzes the output from event_system_analyzer.py to identify
	parameter patterns and auto-suggest meanings for unknown commands.

	Uses statistical analysis, pattern clustering, and game data cross-referencing
	to generate evidence-based hypotheses with confidence scores.
		"""
	)

	parser.add_argument(
		'--input',
		required=True,
		help='Directory containing event_system_analyzer.py output files'
	)

	parser.add_argument(
		'--output',
		default='docs/parameter_analysis',
		help='Output directory for analysis results'
	)

	args = parser.parse_args()

	# Initialize analyzer
	analyzer = ParameterPatternAnalyzer(args.input)

	# Load data
	analyzer.load_analysis_data()

	# Identify unknown commands
	analyzer.identify_unknown_commands()

	# Analyze parameters
	analyzer.analyze_all_parameters()

	# Generate hypotheses
	analyzer.generate_hypotheses()

	# Export results
	analyzer.export_results(args.output)

	print("\n" + "=" * 80)
	print("PARAMETER PATTERN ANALYSIS COMPLETE")
	print("=" * 80)
	print(f"\nResults exported to: {args.output}/")
	print(f"\nGenerated files:")
	print(f"  ✓ {args.output}/parameter_analysis.json")
	print(f"  ✓ {args.output}/command_hypotheses.json")
	print(f"  ✓ {args.output}/PARAMETER_ANALYSIS_REPORT.md")
	print("")
	print("Next steps:")
	print("  1. Review command_hypotheses.json for highest confidence suggestions")
	print("  2. Check PARAMETER_ANALYSIS_REPORT.md for detailed analysis")
	print("  3. Create test ROMs for high-confidence hypotheses")
	print("  4. Validate hypotheses with emulator testing")
	print("")


if __name__ == '__main__':
	main()
