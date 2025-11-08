"""
Dialog Database Validator

Validates dialog data integrity and consistency.
"""

from dataclasses import dataclass
from typing import Dict, List
import sys
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from utils.dialog_database import DialogEntry, DialogDatabase


@dataclass
class ValidationIssue:
	"""A validation issue"""
	severity: str  # "error", "warning", "info"
	category: str  # "encoding", "length", "format", "reference", etc.
	dialog_id: int
	message: str
	suggestion: str = ""


class DialogValidator:
	"""Validates dialog database integrity"""

	def __init__(self, db: DialogDatabase, character_table: Dict[int, str]):
		self.db = db
		self.character_table = character_table
		self.issues: List[ValidationIssue] = []

	def validate_all(self) -> List[ValidationIssue]:
		"""Run all validation checks"""
		self.issues = []

		self.check_encoding()
		self.check_lengths()
		self.check_formatting()
		self.check_references()
		self.check_control_codes()
		self.check_duplicates()
		self.check_empty()

		return self.issues

	def check_encoding(self):
		"""Check for encoding issues"""
		for dialog_id, dialog in self.db.dialogs.items():
			# Check for invalid characters
			try:
				dialog.text.encode('utf-8')
			except UnicodeEncodeError as e:
				self.issues.append(ValidationIssue(
					severity="error",
					category="encoding",
					dialog_id=dialog_id,
					message=f"Invalid Unicode character at position {e.start}",
					suggestion="Remove or replace invalid characters"
				))

			# Check for characters not in table
			for char in dialog.text:
				if char not in ['\n', '\r'] and ord(char) > 127:
					# Extended ASCII or Unicode - check if in table
					if ord(char) not in self.character_table:
						self.issues.append(ValidationIssue(
							severity="warning",
							category="encoding",
							dialog_id=dialog_id,
							message=f"Character '{char}' (0x{ord(char):02X}) not in character table",
							suggestion="Add to character table or replace with standard character"
						))

	def check_lengths(self):
		"""Check for length issues"""
		for dialog_id, dialog in self.db.dialogs.items():
			# Check total length
			if len(dialog.text) > 1024:
				self.issues.append(ValidationIssue(
					severity="warning",
					category="length",
					dialog_id=dialog_id,
					message=f"Very long dialog ({len(dialog.text)} characters)",
					suggestion="Consider splitting into multiple dialogs"
				))

			# Check line lengths
			lines = dialog.text.split('\n')
			for i, line in enumerate(lines, 1):
				if len(line) > 255:
					self.issues.append(ValidationIssue(
						severity="error",
						category="length",
						dialog_id=dialog_id,
						message=f"Line {i} exceeds 255 characters ({len(line)} chars)",
						suggestion="Split line or reduce text"
					))

				if len(line) > 40:  # Typical display width
					self.issues.append(ValidationIssue(
						severity="info",
						category="length",
						dialog_id=dialog_id,
						message=f"Line {i} may be too wide for display ({len(line)} chars)",
						suggestion="Consider breaking line at ~40 characters"
					))

	def check_formatting(self):
		"""Check for formatting issues"""
		for dialog_id, dialog in self.db.dialogs.items():
			text = dialog.text

			# Leading/trailing whitespace
			if text != text.strip():
				self.issues.append(ValidationIssue(
					severity="warning",
					category="format",
					dialog_id=dialog_id,
					message="Dialog has leading or trailing whitespace",
					suggestion="Run batch trim operation"
				))

			# Double spaces
			if '  ' in text:
				self.issues.append(ValidationIssue(
					severity="warning",
					category="format",
					dialog_id=dialog_id,
					message="Dialog contains double spaces",
					suggestion="Run batch normalize_whitespace operation"
				))

			# Tab characters (usually not desired)
			if '\t' in text:
				self.issues.append(ValidationIssue(
					severity="warning",
					category="format",
					dialog_id=dialog_id,
					message="Dialog contains tab characters",
					suggestion="Replace tabs with spaces"
				))

			# Mixed line endings
			if '\r\n' in text and '\n' in text.replace('\r\n', ''):
				self.issues.append(ValidationIssue(
					severity="warning",
					category="format",
					dialog_id=dialog_id,
					message="Dialog has mixed line endings (CRLF and LF)",
					suggestion="Run batch normalize_newlines operation"
				))

	def check_references(self):
		"""Check for broken references"""
		all_ids = set(self.db.dialogs.keys())

		for dialog_id, dialog in self.db.dialogs.items():
			# Check for referenced dialog IDs (e.g., in next_dialog property)
			if hasattr(dialog, 'next_dialog') and dialog.next_dialog:
				if dialog.next_dialog not in all_ids:
					self.issues.append(ValidationIssue(
						severity="error",
						category="reference",
						dialog_id=dialog_id,
						message=f"References non-existent dialog 0x{dialog.next_dialog:04X}",
						suggestion="Update reference or create missing dialog"
					))

			# Check for dialog ID references in text (e.g., "See dialog 0x1234")
			import re
			for match in re.finditer(r'0x([0-9a-fA-F]{4})', dialog.text):
				ref_id = int(match.group(1), 16)
				if ref_id not in all_ids and ref_id < 0x1000:  # Likely dialog ID
					self.issues.append(ValidationIssue(
						severity="info",
						category="reference",
						dialog_id=dialog_id,
						message=f"Text contains possible dialog reference 0x{ref_id:04X} that doesn't exist",
						suggestion="Verify if this is actually a dialog reference"
					))

	def check_control_codes(self):
		"""Check for control code issues"""
		import re

		for dialog_id, dialog in self.db.dialogs.items():
			text = dialog.text

			# Find all control codes
			control_codes = re.findall(r'\[([A-Z_]+)\]', text)

			# Check for unknown control codes
			known_codes = {'WAIT', 'CLEAR', 'NAME', 'LINE', 'CHOICE', 'END', 'PAGE'}
			for code in control_codes:
				if code not in known_codes:
					self.issues.append(ValidationIssue(
						severity="warning",
						category="control_code",
						dialog_id=dialog_id,
						message=f"Unknown control code [{code}]",
						suggestion=f"Verify this is a valid control code. Known codes: {', '.join(sorted(known_codes))}"
					))

			# Check for unbalanced brackets
			open_count = text.count('[')
			close_count = text.count(']')
			if open_count != close_count:
				self.issues.append(ValidationIssue(
					severity="error",
					category="control_code",
					dialog_id=dialog_id,
					message=f"Unbalanced brackets ([ = {open_count}, ] = {close_count})",
					suggestion="Add missing bracket or remove extra bracket"
				))

			# Check for malformed codes (e.g., "[wait ]" with space)
			malformed = re.findall(r'\[[A-Z_]+ .*?\]', text)
			if malformed:
				self.issues.append(ValidationIssue(
					severity="warning",
					category="control_code",
					dialog_id=dialog_id,
					message=f"Possible malformed control codes: {', '.join(malformed)}",
					suggestion="Remove spaces from control codes"
				))

	def check_duplicates(self):
		"""Check for duplicate dialog text"""
		text_to_ids: Dict[str, List[int]] = {}

		for dialog_id, dialog in self.db.dialogs.items():
			normalized = dialog.text.strip().lower()
			if normalized not in text_to_ids:
				text_to_ids[normalized] = []
			text_to_ids[normalized].append(dialog_id)

		# Report duplicates
		for text, ids in text_to_ids.items():
			if len(ids) > 1 and text:  # More than one dialog with same text
				for dialog_id in ids:
					self.issues.append(ValidationIssue(
						severity="info",
						category="duplicate",
						dialog_id=dialog_id,
						message=f"Duplicate text (also in: {', '.join(f'0x{id:04X}' for id in ids if id != dialog_id)})",
						suggestion="Consider reusing dialog ID if appropriate"
					))

	def check_empty(self):
		"""Check for empty dialogs"""
		for dialog_id, dialog in self.db.dialogs.items():
			if not dialog.text.strip():
				self.issues.append(ValidationIssue(
					severity="warning",
					category="empty",
					dialog_id=dialog_id,
					message="Dialog is empty or contains only whitespace",
					suggestion="Add content or remove dialog"
				))

	def get_issues_by_severity(self) -> Dict[str, List[ValidationIssue]]:
		"""Group issues by severity"""
		result = {"error": [], "warning": [], "info": []}
		for issue in self.issues:
			result[issue.severity].append(issue)
		return result

	def get_issues_by_category(self) -> Dict[str, List[ValidationIssue]]:
		"""Group issues by category"""
		result: Dict[str, List[ValidationIssue]] = {}
		for issue in self.issues:
			if issue.category not in result:
				result[issue.category] = []
			result[issue.category].append(issue)
		return result

	def generate_report(self) -> str:
		"""Generate a validation report"""
		lines = []
		lines.append("=" * 70)
		lines.append("Dialog Database Validation Report")
		lines.append("=" * 70)
		lines.append("")

		# Summary
		by_severity = self.get_issues_by_severity()
		lines.append(f"Total Issues: {len(self.issues)}")
		lines.append(f"  Errors:   {len(by_severity['error'])}")
		lines.append(f"  Warnings: {len(by_severity['warning'])}")
		lines.append(f"  Info:     {len(by_severity['info'])}")
		lines.append("")

		# Issues by category
		by_category = self.get_issues_by_category()
		lines.append("Issues by Category:")
		for category, issues in sorted(by_category.items()):
			lines.append(f"  {category}: {len(issues)}")
		lines.append("")

		# Detailed issues
		for severity in ['error', 'warning', 'info']:
			severity_issues = by_severity[severity]
			if not severity_issues:
				continue

			lines.append("-" * 70)
			lines.append(f"{severity.upper()}S ({len(severity_issues)})")
			lines.append("-" * 70)

			for issue in severity_issues:
				lines.append(f"\nDialog 0x{issue.dialog_id:04X} [{issue.category}]")
				lines.append(f"  {issue.message}")
				if issue.suggestion:
					lines.append(f"  Suggestion: {issue.suggestion}")

		lines.append("")
		lines.append("=" * 70)
		lines.append("End of Report")
		lines.append("=" * 70)

		return "\n".join(lines)


def demo():
	"""Demonstration of dialog validation"""
	# Create test database
	db = DialogDatabase()
	
	# Add some test dialogs with various issues
	db.dialogs[0x0001] = DialogEntry(0x0001, "Hello, world!", bytearray(b"Hello, world!"), 0x1000, 0x1000, 13)
	db.dialogs[0x0002] = DialogEntry(0x0002, "  This has leading spaces", bytearray(), 0x1020, 0x1020, 0)
	db.dialogs[0x0003] = DialogEntry(0x0003, "This has  double spaces", bytearray(), 0x1040, 0x1040, 0)
	db.dialogs[0x0004] = DialogEntry(0x0004, "This has\ttabs", bytearray(), 0x1060, 0x1060, 0)
	db.dialogs[0x0005] = DialogEntry(0x0005, "This has [WAIT] control codes[CLEAR]", bytearray(), 0x1080, 0x1080, 0)
	db.dialogs[0x0006] = DialogEntry(0x0006, "This has [UNKNOWN] code", bytearray(), 0x10A0, 0x10A0, 0)
	db.dialogs[0x0007] = DialogEntry(0x0007, "This has unbalanced [bracket", bytearray(), 0x10C0, 0x10C0, 0)
	db.dialogs[0x0008] = DialogEntry(0x0008, "Hello, world!", bytearray(), 0x10E0, 0x10E0, 0)  # Duplicate
	db.dialogs[0x0009] = DialogEntry(0x0009, "", bytearray(), 0x1100, 0x1100, 0)  # Empty
	db.dialogs[0x000A] = DialogEntry(0x000A, "This line is very very very very very very very very very very very long and exceeds normal display width", bytearray(), 0x1120, 0x1120, 0)

	# Character table (simplified)
	char_table = {i: chr(i) for i in range(128)}

	# Validate
	validator = DialogValidator(db, char_table)
	issues = validator.validate_all()

	# Print report
	print(validator.generate_report())

	print("\n" + "=" * 70)
	print("Issues by severity:")
	by_severity = validator.get_issues_by_severity()
	for severity, severity_issues in by_severity.items():
		print(f"\n{severity.upper()}: {len(severity_issues)}")
		for issue in severity_issues[:5]:  # Show first 5
			print(f"  - Dialog 0x{issue.dialog_id:04X}: {issue.message}")


if __name__ == '__main__':
	demo()
