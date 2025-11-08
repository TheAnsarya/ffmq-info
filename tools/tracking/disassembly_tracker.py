#!/usr/bin/env python3
"""
FFMQ Disassembly Progress Tracker

Analyzes current disassembly progress across all ROM banks and compares
with the reference ROM to track completion percentage.

Usage:
	python tools/disassembly_tracker.py [--report output.json] [--verbose]

Author: Disassembly Team
Date: October 30, 2025
Version: 1.0.0
"""

import json
import os
import sys
from pathlib import Path
from typing import Dict, List, Tuple
from dataclasses import dataclass, asdict
from datetime import datetime


@dataclass
class BankStatus:
	"""Status information for a single ROM bank."""
	bank_number: int
	bank_hex: str
	documented_file: str
	exists: bool
	file_size: int
	line_count: int
	has_temp_files: bool
	temp_file_count: int
	estimated_completion: float
	status: str  # 'complete', 'in-progress', 'not-started', 'missing'
	notes: str


class DisassemblyTracker:
	"""
	Tracks disassembly progress across all ROM banks.

	Reference:
	https://snes.nesdev.org/wiki/ROM_file_formats
	https://en.wikibooks.org/wiki/Super_NES_Programming/SNES_memory_map
	"""

	def __init__(self, project_root: Path):
		"""
		Initialize the tracker.

		Args:
			project_root: Root directory of the FFMQ project
		"""
		self.project_root = project_root
		self.src_asm = project_root / "src" / "asm"
		self.config_file = project_root / "build.config.json"
		self.rom_size = 1048576  # 1 MB SNES ROM
		self.bank_size = 0x8000  # 32KB per bank
		self.num_banks = 16  # Banks $00-$0f for 1MB ROM

		# Load configuration
		self.config = self._load_config()

	def _load_config(self) -> dict:
		"""Load build configuration from JSON file."""
		if not self.config_file.exists():
			return {}

		with open(self.config_file, 'r', encoding='utf-8') as f:
			return json.load(f)

	def get_bank_status(self, bank_num: int) -> BankStatus:
		"""
		Get status information for a specific bank.

		Args:
			bank_num: Bank number (0x00 - 0x0f)

		Returns:
			BankStatus object with current status
		"""
		bank_hex = f"{bank_num:02x}"
		documented_file = f"bank_{bank_hex}_documented.asm"
		file_path = self.src_asm / documented_file

		# Check if documented file exists
		exists = file_path.exists()
		file_size = file_path.stat().st_size if exists else 0

		# Count lines in file
		line_count = 0
		if exists:
			with open(file_path, 'r', encoding='utf-8') as f:
				line_count = sum(1 for _ in f)

		# Check for temp files
		temp_pattern = f"temp_bank{bank_hex}_*.asm"
		temp_files = list(self.project_root.glob(temp_pattern))
		has_temp_files = len(temp_files) > 0
		temp_file_count = len(temp_files)

		# Estimate completion based on file size and line count
		# A fully documented bank should have ~1000-3000 lines
		# https://github.com/TheAnsarya/ffmq-info - Project standards
		estimated_completion = 0.0
		status = "missing"
		notes = ""

		if exists:
			if line_count < 100:
				status = "not-started"
				estimated_completion = 5.0
				notes = "Minimal stub file"
			elif line_count < 500:
				status = "in-progress"
				estimated_completion = 25.0
				notes = "Early disassembly"
			elif line_count < 1500:
				status = "in-progress"
				estimated_completion = 50.0
				notes = "Partial disassembly"
			elif line_count < 2500:
				status = "in-progress"
				estimated_completion = 75.0
				notes = "Advanced disassembly"
			else:
				status = "complete"
				estimated_completion = 95.0
				notes = "Fully documented"
		else:
			notes = "No documented file exists"

		# Adjust status based on temp files
		if has_temp_files:
			notes += f" ({temp_file_count} temp files)"
			if status == "not-started":
				status = "in-progress"
				estimated_completion = max(estimated_completion, 10.0)

		return BankStatus(
			bank_number=bank_num,
			bank_hex=bank_hex,
			documented_file=documented_file,
			exists=exists,
			file_size=file_size,
			line_count=line_count,
			has_temp_files=has_temp_files,
			temp_file_count=temp_file_count,
			estimated_completion=estimated_completion,
			status=status,
			notes=notes
		)

	def analyze_all_banks(self) -> List[BankStatus]:
		"""
		Analyze all ROM banks.

		Returns:
			List of BankStatus objects for all banks
		"""
		return [self.get_bank_status(i) for i in range(self.num_banks)]

	def calculate_overall_progress(self, banks: List[BankStatus]) -> Dict:
		"""
		Calculate overall disassembly progress.

		Args:
			banks: List of BankStatus objects

		Returns:
			Dictionary with progress statistics
		"""
		total_banks = len(banks)
		complete_banks = sum(1 for b in banks if b.status == "complete")
		in_progress_banks = sum(1 for b in banks if b.status == "in-progress")
		not_started_banks = sum(1 for b in banks if b.status == "not-started")
		missing_banks = sum(1 for b in banks if b.status == "missing")

		# Calculate weighted completion
		total_completion = sum(b.estimated_completion for b in banks)
		overall_completion = total_completion / total_banks

		# Calculate total lines
		total_lines = sum(b.line_count for b in banks)
		total_size = sum(b.file_size for b in banks)

		# Count temp files
		total_temp_files = sum(b.temp_file_count for b in banks)

		return {
			"timestamp": datetime.now().isoformat(),
			"reference_rom": self.config.get("paths", {}).get("roms", {}).get("original", "Unknown"),
			"total_banks": total_banks,
			"complete_banks": complete_banks,
			"in_progress_banks": in_progress_banks,
			"not_started_banks": not_started_banks,
			"missing_banks": missing_banks,
			"overall_completion_percent": round(overall_completion, 2),
			"total_lines": total_lines,
			"total_size_bytes": total_size,
			"total_temp_files": total_temp_files,
			"rom_size_bytes": self.rom_size,
			"bank_size_bytes": self.bank_size
		}

	def generate_report(self, output_file: Path = None) -> Dict:
		"""
		Generate comprehensive progress report.

		Args:
			output_file: Optional path to save JSON report

		Returns:
			Complete report dictionary
		"""
		banks = self.analyze_all_banks()
		progress = self.calculate_overall_progress(banks)

		# Build complete report
		report = {
			"project": "Final Fantasy Mystic Quest Disassembly",
			"progress": progress,
			"banks": [asdict(b) for b in banks],
			"summary": {
				"next_priority": self._identify_next_priorities(banks),
				"recommendations": self._generate_recommendations(banks)
			}
		}

		# Save to file if requested
		if output_file:
			output_file.parent.mkdir(parents=True, exist_ok=True)
			with open(output_file, 'w', encoding='utf-8') as f:
				json.dump(report, f, indent='\t')

		return report

	def _identify_next_priorities(self, banks: List[BankStatus]) -> List[str]:
		"""Identify which banks should be worked on next."""
		priorities = []

		# Missing banks are highest priority
		missing = [b.bank_hex for b in banks if b.status == "missing"]
		if missing:
			priorities.append(f"Create missing banks: {', '.join(f'${b}' for b in missing)}")

		# Not started banks
		not_started = [b.bank_hex for b in banks if b.status == "not-started"]
		if not_started:
			priorities.append(f"Start disassembly: {', '.join(f'${b}' for b in not_started)}")

		# In-progress with temp files (likely being worked on)
		with_temps = [b.bank_hex for b in banks if b.has_temp_files and b.status == "in-progress"]
		if with_temps:
			priorities.append(f"Continue work on: {', '.join(f'${b}' for b in with_temps)}")

		# In-progress without temp files
		without_temps = [b.bank_hex for b in banks if not b.has_temp_files and b.status == "in-progress"]
		if without_temps:
			priorities.append(f"Resume disassembly: {', '.join(f'${b}' for b in without_temps)}")

		return priorities

	def _generate_recommendations(self, banks: List[BankStatus]) -> List[str]:
		"""Generate recommendations for improving disassembly."""
		recommendations = []

		# Calculate progress
		in_progress = [b for b in banks if b.status == "in-progress"]

		if len(in_progress) > 5:
			recommendations.append("Focus on completing banks in progress before starting new ones")

		# Check for temp files
		total_temps = sum(b.temp_file_count for b in banks)
		if total_temps > 20:
			recommendations.append(f"Clean up {total_temps} temp files - consolidate into documented files")

		# Check completion percentage
		progress = self.calculate_overall_progress(banks)
		completion = progress["overall_completion_percent"]

		if completion < 50:
			recommendations.append("Use aggressive disassembly script to accelerate progress")
		elif completion < 80:
			recommendations.append("Focus on documenting and cleaning up existing disassembly")
		else:
			recommendations.append("Nearly complete! Focus on final validation and cleanup")

		return recommendations

	def print_summary(self):
		"""Print a human-readable summary to console."""
		banks = self.analyze_all_banks()
		progress = self.calculate_overall_progress(banks)

		print("═" * 70)
		print("  FFMQ Disassembly Progress Tracker")
		print("═" * 70)
		print()
		print(f"Reference ROM: {progress['reference_rom']}")
		print(f"Timestamp: {progress['timestamp']}")
		print()
		print("Overall Progress:")
		print(f"  Completion: {progress['overall_completion_percent']}%")
		print(f"  Complete Banks: {progress['complete_banks']}/{progress['total_banks']}")
		print(f"  In Progress: {progress['in_progress_banks']}")
		print(f"  Not Started: {progress['not_started_banks']}")
		print(f"  Missing: {progress['missing_banks']}")
		print()
		print(f"Total Lines: {progress['total_lines']:,}")
		print(f"Total Size: {progress['total_size_bytes']:,} bytes")
		print(f"Temp Files: {progress['total_temp_files']}")
		print()
		print("─" * 70)
		print("Bank Status:")
		print("─" * 70)
		print(f"{'Bank':<6} {'Status':<15} {'Lines':<8} {'Completion':<12} {'Notes'}")
		print("─" * 70)

		for bank in banks:
			status_color = {
				'complete': '✅',
				'in-progress': '🔄',
				'not-started': '⭕',
				'missing': '❌'
			}.get(bank.status, '❓')

			print(f"${bank.bank_hex}    {status_color} {bank.status:<12} "
			      f"{bank.line_count:<8} {bank.estimated_completion:>5.1f}%      "
			      f"{bank.notes}")

		print("─" * 70)
		print()
		print("Next Priorities:")
		priorities = self._identify_next_priorities(banks)
		for i, priority in enumerate(priorities, 1):
			print(f"  {i}. {priority}")

		print()
		print("Recommendations:")
		recommendations = self._generate_recommendations(banks)
		for i, rec in enumerate(recommendations, 1):
			print(f"  {i}. {rec}")

		print()
		print("═" * 70)


def main():
	"""Main entry point."""
	import argparse

	parser = argparse.ArgumentParser(
		description="Track FFMQ disassembly progress across all ROM banks"
	)
	parser.add_argument(
		'--report',
		type=str,
		help='Output JSON report file path'
	)
	parser.add_argument(
		'--verbose',
		action='store_true',
		help='Show detailed output'
	)

	args = parser.parse_args()

	# Find project root
	project_root = Path(__file__).parent.parent

	# Create tracker
	tracker = DisassemblyTracker(project_root)

	# Print summary
	tracker.print_summary()

	# Generate report if requested
	if args.report:
		output_path = Path(args.report)
		report = tracker.generate_report(output_path)
		print(f"\n✅ Report saved to: {output_path}")

	return 0


if __name__ == "__main__":
	sys.exit(main())
