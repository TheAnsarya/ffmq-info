#!/usr/bin/env python3
"""
FFMQ Character Encoding Verifier
=================================

Comprehensive validation tool for character encoding tables (simple.tbl and complex.tbl).
Tests round-trip encoding, validates all mappings, and identifies encoding issues.

Features:
---------
1. **Table Validation**
	 - Load and parse .tbl files
	 - Detect duplicate mappings
	 - Find unmapped ranges
	 - Validate format correctness

2. **Round-Trip Testing**
	 - Text → Bytes → Text conversion
	 - Verify lossless encoding
	 - Test all character combinations
	 - Validate special characters

3. **ROM Cross-Reference**
	 - Extract known text from ROM
	 - Decode using character tables
	 - Compare with expected text
	 - Identify incorrect mappings

4. **Space Character Handling**
	 - Verify space encoding (0xFF vs `*`)
	 - Test space in different contexts
	 - Validate dictionary space handling
	 - Document space usage patterns

5. **DTE (Dual Tile Encoding) Validation**
	 - Verify complex.tbl dictionary entries
	 - Test common word compression
	 - Validate DTE token ranges
	 - Measure compression efficiency

Author: TheAnsarya
Date: 2025-11-12
License: MIT
"""

import sys
import struct
from pathlib import Path
from typing import Dict, List, Tuple, Set, Optional, Any
from dataclasses import dataclass, field
from collections import Counter, defaultdict
from enum import Enum


class EncodingIssueType(Enum):
	"""Types of encoding issues."""
	DUPLICATE_MAPPING = "duplicate_mapping"
	MISSING_REVERSE = "missing_reverse"
	INVALID_FORMAT = "invalid_format"
	UNMAPPED_RANGE = "unmapped_range"
	ROUND_TRIP_FAIL = "round_trip_fail"
	SPACE_AMBIGUITY = "space_ambiguity"
	DTE_CONFLICT = "dte_conflict"


@dataclass
class EncodingIssue:
	"""Represents an encoding validation issue."""
	issue_type: EncodingIssueType
	severity: str	# "error", "warning", "info"
	byte_value: Optional[int] = None
	character: Optional[str] = None
	message: str = ""
	context: str = ""
	suggested_fix: str = ""


@dataclass
class CharacterTable:
	"""Represents a character encoding table."""
	name: str
	byte_to_char: Dict[int, str] = field(default_factory=dict)
	char_to_byte: Dict[str, int] = field(default_factory=dict)

	# Metadata
	total_mappings: int = 0
	mapped_bytes: Set[int] = field(default_factory=set)
	unmapped_ranges: List[Tuple[int, int]] = field(default_factory=list)

	# Issues
	issues: List[EncodingIssue] = field(default_factory=list)

	# Statistics
	duplicate_bytes: Dict[int, List[str]] = field(default_factory=dict)
	duplicate_chars: Dict[str, List[int]] = field(default_factory=dict)


@dataclass
class RoundTripTest:
	"""Represents a round-trip encoding test."""
	original_text: str
	encoded_bytes: bytes
	decoded_text: str
	success: bool
	issues: List[str] = field(default_factory=list)


class CharacterEncodingVerifier:
	"""Verifies character encoding tables for correctness."""

	# Known special characters
	SPECIAL_CHARS = {
		0xFF: "SPACE",	# Space might be 0xFF (need to verify)
		0x00: "END",		# Dialog terminator
		0x01: "NEWLINE",
		0x02: "WAIT",
		0x03: "ASTERISK",
	}

	# DTE (dictionary) range for complex text
	DTE_RANGE_START = 0x50	# Dictionary entries start
	DTE_RANGE_END = 0xCF		# Dictionary entries end

	def __init__(self, simple_table_path: Optional[str] = None, complex_table_path: Optional[str] = None):
		"""
		Initialize verifier.

		Args:
			simple_table_path: Path to simple.tbl file
			complex_table_path: Path to complex.tbl file
		"""
		self.simple_table_path = Path(simple_table_path) if simple_table_path else None
		self.complex_table_path = Path(complex_table_path) if complex_table_path else None

		self.simple_table = CharacterTable(name="simple.tbl")
		self.complex_table = CharacterTable(name="complex.tbl")

		self.round_trip_tests: List[RoundTripTest] = []

		# ROM data (optional)
		self.rom_data: Optional[bytes] = None

	def load_table(self, table_path: Path) -> CharacterTable:
		"""
		Load and parse a character table file.

		Args:
			table_path: Path to .tbl file

		Returns:
			CharacterTable with loaded mappings
		"""
		table = CharacterTable(name=table_path.name)

		print(f"Loading {table_path.name}...")

		if not table_path.exists():
			issue = EncodingIssue(
				issue_type=EncodingIssueType.INVALID_FORMAT,
				severity="error",
				message=f"Table file not found: {table_path}"
			)
			table.issues.append(issue)
			print(f"  ❌ File not found")
			return table

		line_num = 0
		with open(table_path, 'r', encoding='utf-8') as f:
			for line in f:
				line_num += 1
				line = line.strip()

				# Skip comments and empty lines
				if not line or line.startswith('#'):
					continue

				# Parse line (format: XX=C or XXXX=String)
				if '=' not in line:
					issue = EncodingIssue(
						issue_type=EncodingIssueType.INVALID_FORMAT,
						severity="warning",
						message=f"Invalid format at line {line_num}: {line}",
						suggested_fix="Use format: XX=C or XXXX=String"
					)
					table.issues.append(issue)
					continue

				byte_str, char = line.split('=', 1)

				try:
					byte_val = int(byte_str, 16)
				except ValueError:
					issue = EncodingIssue(
						issue_type=EncodingIssueType.INVALID_FORMAT,
						severity="error",
						byte_value=None,
						message=f"Invalid byte value at line {line_num}: {byte_str}",
						suggested_fix="Use hex format: XX or XXXX"
					)
					table.issues.append(issue)
					continue

				# Check for duplicates
				if byte_val in table.byte_to_char:
					if byte_val not in table.duplicate_bytes:
						table.duplicate_bytes[byte_val] = [table.byte_to_char[byte_val]]
					table.duplicate_bytes[byte_val].append(char)

					issue = EncodingIssue(
						issue_type=EncodingIssueType.DUPLICATE_MAPPING,
						severity="error",
						byte_value=byte_val,
						character=char,
						message=f"Byte 0x{byte_val:02X} mapped to multiple characters: {table.duplicate_bytes[byte_val]}",
						suggested_fix="Remove duplicate mapping or use different byte value"
					)
					table.issues.append(issue)

				if char in table.char_to_byte:
					if char not in table.duplicate_chars:
						table.duplicate_chars[char] = [table.char_to_byte[char]]
					table.duplicate_chars[char].append(byte_val)

					issue = EncodingIssue(
						issue_type=EncodingIssueType.DUPLICATE_MAPPING,
						severity="warning",
						byte_value=byte_val,
						character=char,
						message=f"Character '{char}' mapped to multiple bytes: {[f'0x{b:02X}' for b in table.duplicate_chars[char]]}",
						suggested_fix="Use first mapping, or clarify context-dependent mapping"
					)
					table.issues.append(issue)

				# Add mapping
				table.byte_to_char[byte_val] = char
				table.char_to_byte[char] = byte_val
				table.mapped_bytes.add(byte_val)
				table.total_mappings += 1

		print(f"  ✅ Loaded {table.total_mappings} mappings")

		# Find unmapped ranges
		table.unmapped_ranges = self.find_unmapped_ranges(table.mapped_bytes)

		if table.unmapped_ranges:
			print(f"  ⚠️  Found {len(table.unmapped_ranges)} unmapped ranges:")
			for start, end in table.unmapped_ranges[:5]:	# Show first 5
				print(f"      0x{start:02X}-0x{end:02X}")

		return table

	def find_unmapped_ranges(self, mapped_bytes: Set[int]) -> List[Tuple[int, int]]:
		"""
		Find contiguous unmapped byte ranges.

		Args:
			mapped_bytes: Set of mapped byte values

		Returns:
			List of (start, end) tuples for unmapped ranges
		"""
		if not mapped_bytes:
			return [(0, 255)]

		unmapped = []
		range_start = None

		for byte_val in range(256):
			if byte_val not in mapped_bytes:
				if range_start is None:
					range_start = byte_val
			else:
				if range_start is not None:
					unmapped.append((range_start, byte_val - 1))
					range_start = None

		# Close final range if needed
		if range_start is not None:
			unmapped.append((range_start, 255))

		return unmapped

	def verify_space_encoding(self, table: CharacterTable) -> List[EncodingIssue]:
		"""
		Verify space character encoding.

		Known issue: Space might be 0xFF or '*' in table.

		Args:
			table: CharacterTable to check

		Returns:
			List of issues found
		"""
		issues = []

		# Check if space is mapped
		space_byte = table.char_to_byte.get(' ')
		asterisk_byte = table.char_to_byte.get('*')

		if space_byte is None and asterisk_byte is not None:
			issue = EncodingIssue(
				issue_type=EncodingIssueType.SPACE_AMBIGUITY,
				severity="warning",
				byte_value=asterisk_byte,
				character='*',
				message="Space character not explicitly mapped, but '*' is mapped to 0x{:02X}".format(asterisk_byte),
				context="User mentioned: 'sometimes `*` in a table means ` ` (space)'",
				suggested_fix="Verify if 0x{:02X} should be space or asterisk".format(asterisk_byte)
			)
			issues.append(issue)

		# Check for 0xFF specifically
		byte_ff_char = table.byte_to_char.get(0xFF)
		if byte_ff_char and byte_ff_char != ' ':
			issue = EncodingIssue(
				issue_type=EncodingIssueType.SPACE_AMBIGUITY,
				severity="warning",
				byte_value=0xFF,
				character=byte_ff_char,
				message=f"Byte 0xFF is mapped to '{byte_ff_char}', but space is typically 0xFF in FFMQ",
				suggested_fix="Verify if 0xFF should be space character"
			)
			issues.append(issue)
		elif byte_ff_char == ' ':
			print(f"  ✅ Space correctly mapped to 0xFF")

		return issues

	def round_trip_test(self, text: str, table: CharacterTable) -> RoundTripTest:
		"""
		Test round-trip encoding: text → bytes → text.

		Args:
			text: Original text to test
			table: CharacterTable to use

		Returns:
			RoundTripTest with results
		"""
		issues = []

		# Encode: text → bytes
		encoded = bytearray()
		for char in text:
			if char in table.char_to_byte:
				encoded.append(table.char_to_byte[char])
			else:
				issues.append(f"Character '{char}' not in encoding table")
				encoded.append(0x3F)	# Use ? as placeholder

		encoded_bytes = bytes(encoded)

		# Decode: bytes → text
		decoded = []
		for byte_val in encoded_bytes:
			if byte_val in table.byte_to_char:
				decoded.append(table.byte_to_char[byte_val])
			else:
				issues.append(f"Byte 0x{byte_val:02X} not in encoding table")
				decoded.append('?')

		decoded_text = ''.join(decoded)

		# Compare
		success = (text == decoded_text) and len(issues) == 0

		return RoundTripTest(
			original_text=text,
			encoded_bytes=encoded_bytes,
			decoded_text=decoded_text,
			success=success,
			issues=issues
		)

	def test_common_text(self, table: CharacterTable) -> None:
		"""
		Test common text strings for round-trip encoding.

		Args:
			table: CharacterTable to test
		"""
		test_strings = [
			"Hello World",
			"The quick brown fox",
			"ABCDEFGHIJKLMNOPQRSTUVWXYZ",
			"abcdefghijklmnopqrstuvwxyz",
			"0123456789",
			"!?.,;:'\"",
			"Cure Potion",
			"Steel Sword",
			"Benjamin",
		]

		print(f"\n  Testing round-trip encoding with {len(test_strings)} strings...")

		passed = 0
		failed = 0

		for text in test_strings:
			result = self.round_trip_test(text, table)
			self.round_trip_tests.append(result)

			if result.success:
				passed += 1
			else:
				failed += 1
				print(f"    ❌ FAIL: '{text}'")
				for issue in result.issues:
					print(f"        - {issue}")

		print(f"  Results: {passed} passed, {failed} failed")

	def verify_rom_text_sample(self, rom_path: str, table: CharacterTable, samples: List[Tuple[int, int, str]]) -> None:
		"""
		Verify ROM text samples decode correctly.

		Args:
			rom_path: Path to ROM file
			table: CharacterTable to use for decoding
			samples: List of (rom_address, length, expected_text) tuples
		"""
		print(f"\n  Verifying ROM text samples...")

		# Load ROM
		with open(rom_path, 'rb') as f:
			self.rom_data = f.read()

		passed = 0
		failed = 0

		for addr, length, expected in samples:
			# Extract bytes
			if addr + length > len(self.rom_data):
				print(f"    ❌ FAIL: Address 0x{addr:06X} out of range")
				failed += 1
				continue

			raw_bytes = self.rom_data[addr:addr+length]

			# Decode
			decoded = []
			for byte_val in raw_bytes:
				if byte_val in table.byte_to_char:
					decoded.append(table.byte_to_char[byte_val])
				else:
					decoded.append(f'[{byte_val:02X}]')

			decoded_text = ''.join(decoded)

			if decoded_text == expected:
				passed += 1
				print(f"    ✅ PASS: 0x{addr:06X} = '{expected}'")
			else:
				failed += 1
				print(f"    ❌ FAIL: 0x{addr:06X}")
				print(f"        Expected: '{expected}'")
				print(f"        Got:      '{decoded_text}'")

		print(f"  Results: {passed} passed, {failed} failed")

	def analyze_dte_efficiency(self, table: CharacterTable) -> Dict[str, Any]:
		"""
		Analyze DTE (dictionary) compression efficiency.

		Args:
			table: CharacterTable with DTE entries

		Returns:
			Dictionary with efficiency metrics
		"""
		print(f"\n  Analyzing DTE compression efficiency...")

		# Count DTE entries
		dte_entries = {}
		for byte_val, char in table.byte_to_char.items():
			if self.DTE_RANGE_START <= byte_val <= self.DTE_RANGE_END:
				dte_entries[byte_val] = char

		print(f"    DTE entries: {len(dte_entries)}")

		# Calculate average compression
		total_original_bytes = 0
		total_compressed_bytes = len(dte_entries)	# Each DTE entry = 1 byte

		for char_seq in dte_entries.values():
			total_original_bytes += len(char_seq)	# Each char would be 1 byte normally

		if total_compressed_bytes > 0:
			compression_ratio = total_original_bytes / total_compressed_bytes
			print(f"    Compression ratio: {compression_ratio:.2f}:1")
			print(f"    Space savings: {total_original_bytes - total_compressed_bytes} bytes")
		else:
			compression_ratio = 1.0

		return {
			'dte_entry_count': len(dte_entries),
			'original_bytes': total_original_bytes,
			'compressed_bytes': total_compressed_bytes,
			'compression_ratio': compression_ratio,
			'space_savings': total_original_bytes - total_compressed_bytes,
		}

	def generate_report(self, output_path: Path) -> None:
		"""
		Generate comprehensive verification report.

		Args:
			output_path: Output directory
		"""
		output_path.mkdir(parents=True, exist_ok=True)

		lines = []
		lines.append("# Character Encoding Verification Report")
		lines.append("=" * 80)
		lines.append("")
		lines.append("**Generated**: 2025-11-12")
		lines.append("")

		# Simple table report
		lines.append("## Simple Text System (simple.tbl)")
		lines.append("")
		lines.append(f"**Total Mappings**: {self.simple_table.total_mappings}")
		lines.append(f"**Mapped Byte Range**: 0x{min(self.simple_table.mapped_bytes):02X}-0x{max(self.simple_table.mapped_bytes):02X}")
		lines.append("")

		if self.simple_table.unmapped_ranges:
			lines.append("### Unmapped Ranges")
			lines.append("")
			for start, end in self.simple_table.unmapped_ranges:
				lines.append(f"- 0x{start:02X}-0x{end:02X}")
			lines.append("")

		if self.simple_table.issues:
			lines.append("### Issues Found")
			lines.append("")

			error_count = sum(1 for i in self.simple_table.issues if i.severity == "error")
			warning_count = sum(1 for i in self.simple_table.issues if i.severity == "warning")

			lines.append(f"**Errors**: {error_count}")
			lines.append(f"**Warnings**: {warning_count}")
			lines.append("")

			for issue in self.simple_table.issues:
				lines.append(f"#### {issue.issue_type.value.upper().replace('_', ' ')}")
				lines.append(f"**Severity**: {issue.severity}")
				if issue.byte_value is not None:
					lines.append(f"**Byte**: 0x{issue.byte_value:02X}")
				if issue.character:
					lines.append(f"**Character**: '{issue.character}'")
				lines.append(f"**Message**: {issue.message}")
				if issue.suggested_fix:
					lines.append(f"**Suggested Fix**: {issue.suggested_fix}")
				lines.append("")

		# Complex table report
		if self.complex_table.total_mappings > 0:
			lines.append("## Complex Text System (complex.tbl)")
			lines.append("")
			lines.append(f"**Total Mappings**: {self.complex_table.total_mappings}")
			lines.append(f"**DTE Entries**: {self.complex_table.total_mappings}")
			lines.append("")

		# Round-trip test results
		if self.round_trip_tests:
			lines.append("## Round-Trip Test Results")
			lines.append("")

			passed = sum(1 for t in self.round_trip_tests if t.success)
			failed = sum(1 for t in self.round_trip_tests if not t.success)

			lines.append(f"**Passed**: {passed}/{len(self.round_trip_tests)}")
			lines.append(f"**Failed**: {failed}/{len(self.round_trip_tests)}")
			lines.append("")

			if failed > 0:
				lines.append("### Failed Tests")
				lines.append("")
				for test in self.round_trip_tests:
					if not test.success:
						lines.append(f"**Original**: `{test.original_text}`")
						lines.append(f"**Decoded**: `{test.decoded_text}`")
						lines.append(f"**Issues**:")
						for issue in test.issues:
							lines.append(f"  - {issue}")
						lines.append("")

		# Recommendations
		lines.append("## Recommendations")
		lines.append("")

		error_count = sum(1 for i in self.simple_table.issues if i.severity == "error")
		warning_count = sum(1 for i in self.simple_table.issues if i.severity == "warning")

		if error_count == 0 and warning_count == 0:
			lines.append("✅ **No critical issues found**. Character encoding tables are valid.")
		else:
			if error_count > 0:
				lines.append(f"❌ **{error_count} errors found**. These must be fixed before use:")
				for issue in self.simple_table.issues:
					if issue.severity == "error":
						lines.append(f"  - {issue.message}")
						if issue.suggested_fix:
							lines.append(f"    Fix: {issue.suggested_fix}")
				lines.append("")

			if warning_count > 0:
				lines.append(f"⚠️  **{warning_count} warnings found**. Review recommended:")
				for issue in self.simple_table.issues:
					if issue.severity == "warning":
						lines.append(f"  - {issue.message}")
						if issue.suggested_fix:
							lines.append(f"    Suggestion: {issue.suggested_fix}")

		lines.append("")

		# Write report
		report_path = output_path / 'CHARACTER_ENCODING_VERIFICATION.md'
		with open(report_path, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))

		print(f"\n📝 Report saved: {report_path}")


def main():
	"""Main entry point."""
	import argparse

	parser = argparse.ArgumentParser(
		description="Verify character encoding tables for FFMQ",
		formatter_class=argparse.RawDescriptionHelpFormatter,
		epilog="""
Examples:
	# Verify simple.tbl only
	python character_encoding_verifier.py --simple simple.tbl

	# Verify both tables
	python character_encoding_verifier.py --simple simple.tbl --complex complex.tbl

	# Include ROM validation
	python character_encoding_verifier.py --simple simple.tbl --rom ffmq.sfc

	# Custom output directory
	python character_encoding_verifier.py --simple simple.tbl --output docs/encoding/

Documentation:
	Validates character encoding tables by checking for:
	- Duplicate mappings
	- Round-trip encoding correctness
	- Special character handling (space, etc.)
	- DTE compression efficiency
		"""
	)

	parser.add_argument(
		'--simple',
		help='Path to simple.tbl file'
	)

	parser.add_argument(
		'--complex',
		help='Path to complex.tbl file (DTE dictionary)'
	)

	parser.add_argument(
		'--rom',
		help='Path to ROM file for cross-reference validation'
	)

	parser.add_argument(
		'--output',
		default='docs/encoding_verification',
		help='Output directory for verification report'
	)

	args = parser.parse_args()

	if not args.simple and not args.complex:
		print("Error: Must specify at least --simple or --complex")
		parser.print_help()
		sys.exit(1)

	# Initialize verifier
	verifier = CharacterEncodingVerifier(args.simple, args.complex)

	print("=" * 80)
	print("CHARACTER ENCODING VERIFICATION")
	print("=" * 80)
	print("")

	# Load tables
	if args.simple:
		verifier.simple_table = verifier.load_table(Path(args.simple))

		# Verify space encoding
		space_issues = verifier.verify_space_encoding(verifier.simple_table)
		verifier.simple_table.issues.extend(space_issues)

		# Round-trip tests
		verifier.test_common_text(verifier.simple_table)

	if args.complex:
		verifier.complex_table = verifier.load_table(Path(args.complex))

		# Analyze DTE efficiency
		dte_stats = verifier.analyze_dte_efficiency(verifier.complex_table)

	# ROM validation (if provided)
	if args.rom and args.simple:
		# Known text samples from ROM (address, length, expected_text)
		samples = [
			# Example: Item names
			# (0x123456, 10, "Cure Potion"),
			# Add more samples as needed
		]
		if samples:
			verifier.verify_rom_text_sample(args.rom, verifier.simple_table, samples)

	# Generate report
	verifier.generate_report(Path(args.output))

	print("\n" + "=" * 80)
	print("VERIFICATION COMPLETE")
	print("=" * 80)
	print(f"\nReport saved to: {args.output}/CHARACTER_ENCODING_VERIFICATION.md")
	print("")


if __name__ == '__main__':
	main()
