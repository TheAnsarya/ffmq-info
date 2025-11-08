#!/usr/bin/env python3
"""
FFMQ Dialog Text System
Handles encoding, decoding, and manipulation of FFMQ dialog text
"""

from dataclasses import dataclass, field
from typing import Dict, List, Tuple, Optional, Set
from pathlib import Path
from enum import IntEnum
import struct


class ControlCode(IntEnum):
	"""FFMQ text control codes"""
	END = 0x00          # End of string (required)
	NEWLINE = 0x01      # Line break
	WAIT = 0x02         # Wait for button press
	CLEAR = 0x03        # Clear dialog box
	NAME = 0x04         # Insert character name
	ITEM = 0x05         # Insert item name
	SPACE = 0x06        # Space character (also used in tbl as _)
	SPEED_SLOW = 0x07   # Slow text speed
	SPEED_NORM = 0x08   # Normal text speed
	SPEED_FAST = 0x09   # Fast text speed
	COLOR_0 = 0x0A      # Color palette 0 (white)
	COLOR_1 = 0x0B      # Color palette 1 (yellow)
	COLOR_2 = 0x0C      # Color palette 2 (green)
	SOUND = 0x0D        # Play sound effect (+ param)
	# Note: Period, comma, exclamation, question mark likely mapped differently
	# or are part of graphics/tiles, not text encoding


# Control code display names for UI
CONTROL_NAMES = {
	ControlCode.END: "[END]",
	ControlCode.NEWLINE: "[NEWLINE]",
	ControlCode.WAIT: "[WAIT]",
	ControlCode.CLEAR: "[CLEAR]",
	ControlCode.NAME: "[NAME]",
	ControlCode.ITEM: "[ITEM]",
	ControlCode.SPEED_SLOW: "[SLOW]",
	ControlCode.SPEED_NORM: "[NORMAL]",
	ControlCode.SPEED_FAST: "[FAST]",
	ControlCode.COLOR_0: "[WHITE]",
	ControlCode.COLOR_1: "[YELLOW]",
	ControlCode.COLOR_2: "[GREEN]",
	ControlCode.SOUND: "[SOUND]"
}

# Reverse mapping for encoding
CONTROL_STRINGS = {v: k for k, v in CONTROL_NAMES.items()}


@dataclass
class DialogMetrics:
	"""Metrics for a dialog string"""
	byte_count: int              # Total bytes (including control codes)
	char_count: int              # Visible characters only
	line_count: int              # Number of lines
	estimated_time: float        # Estimated display time in seconds
	control_codes: Dict[str, int]  # Count of each control code used
	max_line_length: int         # Longest line in characters
	warnings: List[str] = field(default_factory=list)  # Validation warnings

	def __str__(self) -> str:
		"""Human-readable metrics"""
		return (
			f"{self.byte_count} bytes | "
			f"{self.char_count} chars | "
			f"{self.line_count} lines | "
			f"~{self.estimated_time:.1f}s"
		)


class CharacterTable:
	"""Manages FFMQ character encoding/decoding"""

	def __init__(self, tbl_path: Optional[Path] = None, use_complex: bool = True):
		"""
		Initialize character table

		Args:
			tbl_path: Path to .tbl file (defaults to complex.tbl)
			use_complex: If True, use complex.tbl with multi-char sequences
		"""
		self.byte_to_char: Dict[int, str] = {}
		self.char_to_byte: Dict[str, int] = {}
		self.multi_char_to_byte: Dict[str, int] = {}  # Multi-character sequences
		self.loaded = False

		# Default table path
		if tbl_path is None:
			tbl_name = 'complex.tbl' if use_complex else 'simple.tbl'
			tbl_path = Path(__file__).parent.parent.parent.parent / tbl_name

		self.tbl_path = tbl_path
		self._load_table()

	def _load_table(self) -> bool:
		"""Load character table from .tbl file"""
		if not self.tbl_path.exists():
			# Create default mapping as fallback
			self._create_default_mapping()
			return True

		try:
			with open(self.tbl_path, 'r', encoding='utf-8') as f:
				for line in f:
					line = line.strip()
					if not line or line.startswith('#'):
						continue

					# Parse: HH=C or HHHH=CC format
					if '=' in line:
						parts = line.split('=', 1)
						hex_val = int(parts[0], 16)
						char_str = parts[1]

						# Skip # placeholders
						if char_str == '#':
							continue

						# Handle underscore as space
						if char_str == '_':
							char_str = ' '

						# Parse embedded control codes like {newline} or {08}
						char_str = self._parse_embedded_codes(char_str)

						# Store in appropriate mapping
						self.byte_to_char[hex_val] = char_str

						# For encoding, prioritize longer strings (greedy matching)
						if len(char_str) > 1:
							self.multi_char_to_byte[char_str] = hex_val
						else:
							self.char_to_byte[char_str] = hex_val

			self.loaded = True
			return True
		except Exception as e:
			print(f"Error loading character table: {e}")
			self._create_default_mapping()
			return False

	def _parse_embedded_codes(self, text: str) -> str:
		"""
		Parse embedded control codes in table entries

		Examples:
			"{newline}" → "\n"
			"{08}" → control code 0x08 as string marker
			"!{newline}" → "!\n"
			"{05}{1d}E{00}{04}" → complex multi-byte sequence
		"""
		import re

		# Replace {newline} with actual newline
		text = text.replace('{newline}', '\n')

		# Replace {HH} hex codes with placeholder markers
		# We keep them as-is for now since they're control codes
		# The actual encoding/decoding will handle them

		return text
	def _create_default_mapping(self):
		"""Create default FFMQ character mapping"""
		# Digits: 0x90-0x99 → 0-9
		for i in range(10):
			byte_val = 0x90 + i
			self.byte_to_char[byte_val] = str(i)
			self.char_to_byte[str(i)] = byte_val

		# Uppercase: 0x9A-0xB3 → A-Z
		for i in range(26):
			byte_val = 0x9A + i
			char = chr(ord('A') + i)
			self.byte_to_char[byte_val] = char
			self.char_to_byte[char] = byte_val

		# Lowercase: 0xB4-0xCD → a-z
		for i in range(26):
			byte_val = 0xB4 + i
			char = chr(ord('a') + i)
			self.byte_to_char[byte_val] = char
			self.char_to_byte[char] = byte_val

		# Special characters (from complex.tbl)
		specials = {
			0x06: ' ',   # Space
			0xCE: '!',   # Exclamation
			0xCF: '?',   # Question
			0xD0: ',',   # Comma
			0xD1: "'",   # Apostrophe
			0xD2: '.',   # Period
			0xDA: '-',   # Dash
			0xDB: '&',   # Ampersand
		}
		for byte_val, char in specials.items():
			self.byte_to_char[byte_val] = char
			self.char_to_byte[char] = byte_val

		self.loaded = True

	def encode_char(self, char: str) -> Optional[int]:
		"""Encode a single character to byte"""
		return self.char_to_byte.get(char)

	def encode_text(self, text: str) -> List[int]:
		"""
		Encode text string to bytes using longest-match algorithm

		This handles multi-character sequences like "the " → 0x41
		Uses greedy matching to find the longest possible sequences first.
		"""
		result = []
		i = 0

		while i < len(text):
			# Try to match longest sequence first (up to 20 chars)
			matched = False
			for length in range(min(20, len(text) - i), 0, -1):
				substring = text[i:i+length]

				# Check multi-char mappings first
				if substring in self.multi_char_to_byte:
					result.append(self.multi_char_to_byte[substring])
					i += length
					matched = True
					break
				# Then single-char mappings
				elif length == 1 and substring in self.char_to_byte:
					result.append(self.char_to_byte[substring])
					i += 1
					matched = True
					break

			if not matched:
				# Unknown character - skip or use placeholder
				i += 1

		return result

	def decode_byte(self, byte: int) -> str:
		"""Decode a single byte to character or control code"""
		if byte in self.byte_to_char:
			return self.byte_to_char[byte]
		elif byte in CONTROL_NAMES:
			return CONTROL_NAMES[byte]
		else:
			return f'<{byte:02X}>'


class DialogText:
	"""Handles FFMQ dialog text encoding and decoding"""

	# Dialog limits
	MAX_DIALOG_LENGTH = 512      # Maximum bytes per dialog
	MAX_LINE_LENGTH = 32         # Maximum characters per line (approximate)
	CHARS_PER_SECOND = 8.0       # Average text display speed

	def __init__(self, char_table: Optional[CharacterTable] = None):
		"""
		Initialize dialog text handler

		Args:
			char_table: Character table (creates default if None)
		"""
		self.char_table = char_table or CharacterTable()

	def decode(self, data: bytes, include_end: bool = False) -> str:
		"""
		Decode ROM bytes to text string

		Args:
			data: Raw bytes from ROM
			include_end: Include [END] marker in output

		Returns:
			Decoded text string with control codes as [TAGS]
		"""
		text_parts = []
		i = 0

		while i < len(data):
			byte = data[i]
			i += 1

			if byte == ControlCode.END:
				if include_end:
					text_parts.append('[END]')
				break
			elif byte == ControlCode.NEWLINE:
				text_parts.append('\n')
			elif byte in CONTROL_NAMES:
				# Check if this control code has parameters
				if byte == ControlCode.SOUND and i < len(data):
					param = data[i]
					i += 1
					text_parts.append(f'[SOUND:{param:02X}]')
				else:
					text_parts.append(CONTROL_NAMES[byte])
			elif byte in self.char_table.byte_to_char:
				text_parts.append(self.char_table.byte_to_char[byte])
			else:
				# Unknown byte - show as hex
				text_parts.append(f'<{byte:02X}>')

		return ''.join(text_parts)

	def encode(self, text: str, add_end: bool = True) -> bytearray:
		"""
		Encode text string to ROM bytes

		Args:
			text: Text string with control codes as [TAGS]
			add_end: Automatically add [END] terminator

		Returns:
			Byte array ready for ROM insertion
		"""
		result = bytearray()
		i = 0

		while i < len(text):
			# Check for control code tags
			if text[i] == '[':
				# Find closing bracket
				end_bracket = text.find(']', i)
				if end_bracket != -1:
					tag = text[i:end_bracket + 1]

					# Check for parameterized control codes
					if tag.startswith('[SOUND:'):
						result.append(ControlCode.SOUND)
						# Extract hex parameter
						param_hex = tag[7:-1]
						result.append(int(param_hex, 16))
					elif tag in CONTROL_STRINGS:
						result.append(CONTROL_STRINGS[tag])
					else:
						# Unknown tag - skip
						pass

					i = end_bracket + 1
					continue

			# Check for newline
			if text[i] == '\n':
				result.append(ControlCode.NEWLINE)
				i += 1
				continue

			# Use longest-match encoding for multi-character sequences
			# Try to match from current position forward
			matched = False
			for length in range(min(20, len(text) - i), 0, -1):
				substring = text[i:i+length]

				# Skip if substring contains control codes or newlines
				if '[' in substring or '\n' in substring:
					continue

				# Check multi-char mappings first
				if substring in self.char_table.multi_char_to_byte:
					result.append(self.char_table.multi_char_to_byte[substring])
					i += length
					matched = True
					break
				# Then single-char mappings
				elif length == 1:
					byte_val = self.char_table.encode_char(substring)
					if byte_val is not None:
						result.append(byte_val)
						i += 1
						matched = True
						break

			if not matched:
				# Unknown character - skip
				i += 1

		# Add terminator
		if add_end and (not result or result[-1] != ControlCode.END):
			result.append(ControlCode.END)

		return result

	def calculate_metrics(self, text: str) -> DialogMetrics:
		"""
		Calculate metrics for dialog text

		Args:
			text: Decoded text string

		Returns:
			DialogMetrics with analysis
		"""
		# Encode to get byte count
		encoded = self.encode(text)
		byte_count = len(encoded)

		# Count visible characters (exclude control codes and newlines)
		char_count = 0
		control_codes = {}

		i = 0
		while i < len(text):
			if text[i] == '[':
				# Control code
				end_bracket = text.find(']', i)
				if end_bracket != -1:
					tag = text[i:end_bracket + 1]
					control_codes[tag] = control_codes.get(tag, 0) + 1
					i = end_bracket + 1
					continue
			elif text[i] == '\n':
				i += 1
				continue

			char_count += 1
			i += 1

		# Count lines
		lines = text.split('\n')
		line_count = len([line for line in lines if line.strip()])

		# Calculate max line length (visible chars only)
		max_line_length = 0
		for line in lines:
			# Remove control codes from line
			clean_line = line
			while '[' in clean_line:
				start = clean_line.find('[')
				end = clean_line.find(']', start)
				if end != -1:
					clean_line = clean_line[:start] + clean_line[end + 1:]
				else:
					break
			max_line_length = max(max_line_length, len(clean_line))

		# Estimate display time
		# Base time + character time + wait time
		base_time = 0.5  # Dialog box open time
		char_time = char_count / self.CHARS_PER_SECOND
		wait_time = control_codes.get('[WAIT]', 0) * 1.0
		estimated_time = base_time + char_time + wait_time

		# Generate warnings
		warnings = []
		if byte_count > self.MAX_DIALOG_LENGTH:
			warnings.append(f"Dialog too long ({byte_count}/{self.MAX_DIALOG_LENGTH} bytes)")
		if max_line_length > self.MAX_LINE_LENGTH:
			warnings.append(f"Line too long ({max_line_length}/{self.MAX_LINE_LENGTH} chars)")
		if line_count > 4:
			warnings.append(f"Too many lines ({line_count}), consider using [CLEAR]")
		if '[WAIT]' not in control_codes and char_count > 50:
			warnings.append("Long dialog without [WAIT] - player may miss text")

		return DialogMetrics(
			byte_count=byte_count,
			char_count=char_count,
			line_count=line_count,
			estimated_time=estimated_time,
			control_codes=control_codes,
			max_line_length=max_line_length,
			warnings=warnings
		)

	def validate(self, text: str) -> Tuple[bool, List[str]]:
		"""
		Validate dialog text

		Args:
			text: Dialog text to validate

		Returns:
			Tuple of (is_valid, list_of_errors)
		"""
		errors = []

		# Check metrics
		metrics = self.calculate_metrics(text)

		# Critical errors
		if metrics.byte_count > self.MAX_DIALOG_LENGTH:
			errors.append(f"Dialog exceeds maximum length: {metrics.byte_count}/{self.MAX_DIALOG_LENGTH} bytes")

		# Check for unclosed control codes
		bracket_count = text.count('[') - text.count(']')
		if bracket_count != 0:
			errors.append(f"Unmatched control code brackets: {abs(bracket_count)} {'opening' if bracket_count > 0 else 'closing'}")

		# Check for valid control codes
		i = 0
		while i < len(text):
			if text[i] == '[':
				end_bracket = text.find(']', i)
				if end_bracket != -1:
					tag = text[i:end_bracket + 1]
					# Check if it's a valid control code
					if tag not in CONTROL_STRINGS and not tag.startswith('[SOUND:'):
						errors.append(f"Unknown control code: {tag}")
					i = end_bracket + 1
				else:
					i += 1
			else:
				i += 1

		# Add warnings as info (not errors)
		is_valid = len(errors) == 0
		all_messages = errors + [f"Warning: {w}" for w in metrics.warnings]

		return is_valid, all_messages

	def format_for_display(self, text: str, max_width: int = 32) -> List[str]:
		"""
		Format text for display preview (word wrap, line breaks)

		Args:
			text: Decoded dialog text
			max_width: Maximum characters per line

		Returns:
			List of lines for display
		"""
		lines = []
		current_line = ""

		# Split by explicit newlines first
		paragraphs = text.split('\n')

		for para in paragraphs:
			# Remove control codes for wrapping calculation
			clean_para = para
			while '[' in clean_para:
				start = clean_para.find('[')
				end = clean_para.find(']', start)
				if end != -1:
					clean_para = clean_para[:start] + clean_para[end + 1:]
				else:
					break

			# Word wrap
			words = clean_para.split(' ')
			current_line = ""

			for word in words:
				if len(current_line) + len(word) + 1 <= max_width:
					if current_line:
						current_line += " " + word
					else:
						current_line = word
				else:
					if current_line:
						lines.append(current_line)
					current_line = word

			if current_line:
				lines.append(current_line)

		return lines

	def insert_control_code(self, text: str, position: int, code: ControlCode, param: Optional[int] = None) -> str:
		"""
		Insert a control code at specified position

		Args:
			text: Original text
			position: Character position to insert at
			code: Control code to insert
			param: Optional parameter (for SOUND, etc.)

		Returns:
			Modified text with control code inserted
		"""
		tag = CONTROL_NAMES.get(code, f'[{code:02X}]')

		# Handle parameterized codes
		if code == ControlCode.SOUND and param is not None:
			tag = f'[SOUND:{param:02X}]'

		return text[:position] + tag + text[position:]

	def remove_control_code(self, text: str, position: int) -> str:
		"""
		Remove control code at specified position

		Args:
			text: Original text
			position: Position of control code

		Returns:
			Text with control code removed
		"""
		if position >= len(text) or text[position] != '[':
			return text

		end_bracket = text.find(']', position)
		if end_bracket != -1:
			return text[:position] + text[end_bracket + 1:]

		return text


# Convenience functions
def decode_dialog(data: bytes) -> str:
	"""Quick decode dialog bytes to text"""
	handler = DialogText()
	return handler.decode(data)


def encode_dialog(text: str) -> bytearray:
	"""Quick encode text to dialog bytes"""
	handler = DialogText()
	return handler.encode(text)


def validate_dialog(text: str) -> Tuple[bool, List[str]]:
	"""Quick validate dialog text"""
	handler = DialogText()
	return handler.validate(text)


# Example usage and testing
if __name__ == '__main__':
	# Test encoding/decoding
	handler = DialogText()

	# Test simple text
	test_text = "Welcome to Libra![NEWLINE]What brings you here?[WAIT]"
	print("Original text:")
	print(test_text)
	print()

	# Encode
	encoded = handler.encode(test_text)
	print(f"Encoded ({len(encoded)} bytes):")
	print(' '.join(f'{b:02X}' for b in encoded))
	print()

	# Decode back
	decoded = handler.decode(encoded)
	print("Decoded text:")
	print(decoded)
	print()

	# Calculate metrics
	metrics = handler.calculate_metrics(test_text)
	print("Metrics:")
	print(f"  {metrics}")
	if metrics.warnings:
		print("  Warnings:")
		for warning in metrics.warnings:
			print(f"    - {warning}")
	print()

	# Validate
	is_valid, messages = handler.validate(test_text)
	print(f"Valid: {is_valid}")
	if messages:
		for msg in messages:
			print(f"  - {msg}")
	print()

	# Format for display
	display_lines = handler.format_for_display(test_text)
	print("Display preview:")
	print("┌" + "─" * 34 + "┐")
	for line in display_lines:
		print(f"│ {line:<32} │")
	print("└" + "─" * 34 + "┘")
