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
	"""FFMQ text control codes - comprehensive mapping from ROM analysis"""
	# Basic text control (confirmed from analysis)
	END = 0x00		  # End of string (required) - 116 uses
	NEWLINE = 0x01	  # Line break - 70 uses
	WAIT = 0x02		 # Wait for button press - 17 uses
	ASTERISK = 0x03	 # Display asterisk or special marker - 15 uses
	NAME = 0x04		 # Insert character name - 7 uses
	ITEM = 0x05		 # Insert item name - 150 uses (most common!)
	SPACE = 0x06		# Space character - 16 uses

	# Text speed/timing (speculative, need verification)
	SPEED_SLOW = 0x07   # Slow text speed - 18 uses
	SPEED_NORM = 0x08   # Normal text speed - 55 uses
	SPEED_FAST = 0x09   # Fast text speed - 14 uses
	DELAY = 0x0A		# Delay with parameter (multi-byte) - 36 uses

	# Unknown basic commands (need investigation)
	UNK_0B = 0x0B	   # Unknown - 7 uses
	UNK_0C = 0x0C	   # Unknown (NOT green text!) - 10 uses
	UNK_0D = 0x0D	   # Unknown, possibly SET_FLAG - 17 uses
	UNK_0E = 0x0E	   # Unknown - 9 uses
	UNK_0F = 0x0F	   # Unknown - 10 uses

	# Event parameters (appear in dialogs with event triggers)
	PARAM_10 = 0x10	 # Event parameter - 25 uses
	PARAM_11 = 0x11	 # Event parameter - 14 uses
	PARAM_12 = 0x12	 # Event parameter - 11 uses
	PARAM_13 = 0x13	 # Event parameter - 7 uses
	PARAM_14 = 0x14	 # Multi-byte parameter (usually 0x91) - 26 uses
	PARAM_15 = 0x15	 # Event parameter - 6 uses
	PARAM_16 = 0x16	 # Event parameter - 12 uses

	# Dialog box positioning (confirmed from DataCrystal)
	TEXTBOX_BELOW = 0x1A  # Position dialog box below - 29 uses
	TEXTBOX_ABOVE = 0x1B  # Position dialog box above - 4 uses
	PARAM_1C = 0x1C	 # Unknown parameter - 1 use
	PARAM_1D = 0x1D	 # Event parameter (often followed by 0x00) - 6 uses
	PARAM_1E = 0x1E	 # Event parameter - 5 uses
	CRYSTAL = 0x1F	  # Crystal-related event - 11 uses

	# More event parameters
	PARAM_20 = 0x20	 # Event parameter - 15 uses
	PARAM_21 = 0x21	 # Event parameter - 8 uses
	PARAM_22 = 0x22	 # Event parameter - 4 uses
	CLEAR = 0x23		# Clear dialog box - 14 uses
	PARAM_24 = 0x24	 # Event parameter - 11 uses
	PARAM_25 = 0x25	 # Event parameter - 8 uses
	PARAM_26 = 0x26	 # Event parameter - 3 uses
	PARAM_27 = 0x27	 # Event parameter - 7 uses
	PARAM_28 = 0x28	 # Event parameter - 2 uses
	PARAM_29 = 0x29	 # Event parameter - 2 uses
	PARAM_2A = 0x2A	 # Event parameter - 19 uses
	PARAM_2B = 0x2B	 # Event parameter - 14 uses
	PARAM_2C = 0x2C	 # Event parameter - 22 uses

	# Dialog control
	PARA = 0x30		 # Paragraph break - 44 uses
	PARAM_31 = 0x31	 # Event parameter - 3 uses
	PARAM_32 = 0x32	 # Event parameter - 6 uses
	PARAM_33 = 0x33	 # Event parameter - 2 uses
	PARAM_34 = 0x34	 # Event parameter - 1 use
	PARAM_35 = 0x35	 # Event parameter - 3 uses
	PAGE = 0x36		 # New page/dialog box - 29 uses
	PARAM_37 = 0x37	 # Event parameter - 2 uses
	PARAM_38 = 0x38	 # Event parameter - 4 uses
	PARAM_3A = 0x3A	 # Event parameter - 1 use
	PARAM_3B = 0x3B	 # Event parameter - 4 uses

	# Extended control codes (0x80-0x8F) - multi-byte commands
	EXT_80 = 0x80	   # Extended command with param - 5 uses
	EXT_81 = 0x81	   # Extended command with param - 7 uses
	EXT_82 = 0x82	   # Extended command with param - 4 uses
	EXT_83 = 0x83	   # Extended command with param - 2 uses
	EXT_84 = 0x84	   # Extended command with param - 1 use
	EXT_85 = 0x85	   # Extended command with param - 3 uses
	EXT_86 = 0x86	   # Extended command with param - 1 use
	EXT_88 = 0x88	   # Extended command (usually followed by 0x10) - 6 uses
	EXT_89 = 0x89	   # Extended command with param - 3 uses
	EXT_8A = 0x8A	   # Extended command with param - 1 use
	EXT_8B = 0x8B	   # Extended command (usually followed by 0x05) - 5 uses
	EXT_8D = 0x8D	   # Extended command with param - 6 uses
	EXT_8E = 0x8E	   # Extended command (usually followed by 0x14) - 17 uses
	EXT_8F = 0x8F	   # Extended command (usually followed by 0x30) - 16 uses


# Control code display names for UI (comprehensive mapping)
CONTROL_NAMES = {
	# Basic text control (confirmed)
	ControlCode.END: "[END]",
	ControlCode.NEWLINE: "[NEWLINE]",
	ControlCode.WAIT: "[WAIT]",
	ControlCode.ASTERISK: "[ASTERISK]",
	ControlCode.NAME: "[NAME]",
	ControlCode.ITEM: "[ITEM]",
	ControlCode.SPACE: "[SPACE]",

	# Text speed/timing
	ControlCode.SPEED_SLOW: "[SLOW]",
	ControlCode.SPEED_NORM: "[NORMAL]",
	ControlCode.SPEED_FAST: "[FAST]",
	ControlCode.DELAY: "[DELAY]",

	# Unknown commands
	ControlCode.UNK_0B: "[UNK_0B]",
	ControlCode.UNK_0C: "[UNK_0C]",
	ControlCode.UNK_0D: "[UNK_0D]",
	ControlCode.UNK_0E: "[UNK_0E]",
	ControlCode.UNK_0F: "[UNK_0F]",

	# Event parameters
	ControlCode.PARAM_10: "[P10]",
	ControlCode.PARAM_11: "[P11]",
	ControlCode.PARAM_12: "[P12]",
	ControlCode.PARAM_13: "[P13]",
	ControlCode.PARAM_14: "[P14]",
	ControlCode.PARAM_15: "[P15]",
	ControlCode.PARAM_16: "[P16]",

	# Dialog positioning (confirmed)
	ControlCode.TEXTBOX_BELOW: "[TEXTBOX_BELOW]",
	ControlCode.TEXTBOX_ABOVE: "[TEXTBOX_ABOVE]",
	ControlCode.PARAM_1C: "[P1C]",
	ControlCode.PARAM_1D: "[P1D]",
	ControlCode.PARAM_1E: "[P1E]",
	ControlCode.CRYSTAL: "[CRYSTAL]",

	# More parameters
	ControlCode.PARAM_20: "[P20]",
	ControlCode.PARAM_21: "[P21]",
	ControlCode.PARAM_22: "[P22]",
	ControlCode.CLEAR: "[CLEAR]",
	ControlCode.PARAM_24: "[P24]",
	ControlCode.PARAM_25: "[P25]",
	ControlCode.PARAM_26: "[P26]",
	ControlCode.PARAM_27: "[P27]",
	ControlCode.PARAM_28: "[P28]",
	ControlCode.PARAM_29: "[P29]",
	ControlCode.PARAM_2A: "[P2A]",
	ControlCode.PARAM_2B: "[P2B]",
	ControlCode.PARAM_2C: "[P2C]",

	# Dialog control
	ControlCode.PARA: "[PARA]",
	ControlCode.PARAM_31: "[P31]",
	ControlCode.PARAM_32: "[P32]",
	ControlCode.PARAM_33: "[P33]",
	ControlCode.PARAM_34: "[P34]",
	ControlCode.PARAM_35: "[P35]",
	ControlCode.PAGE: "[PAGE]",
	ControlCode.PARAM_37: "[P37]",
	ControlCode.PARAM_38: "[P38]",
	ControlCode.PARAM_3A: "[P3A]",
	ControlCode.PARAM_3B: "[P3B]",

	# Extended commands (0x80-0x8F)
	ControlCode.EXT_80: "[C80]",
	ControlCode.EXT_81: "[C81]",
	ControlCode.EXT_82: "[C82]",
	ControlCode.EXT_83: "[C83]",
	ControlCode.EXT_84: "[C84]",
	ControlCode.EXT_85: "[C85]",
	ControlCode.EXT_86: "[C86]",
	ControlCode.EXT_88: "[C88]",
	ControlCode.EXT_89: "[C89]",
	ControlCode.EXT_8A: "[C8A]",
	ControlCode.EXT_8B: "[C8B]",
	ControlCode.EXT_8D: "[C8D]",
	ControlCode.EXT_8E: "[C8E]",
	ControlCode.EXT_8F: "[C8F]",
}

# Reverse mapping for encoding
CONTROL_STRINGS = {v: k for k, v in CONTROL_NAMES.items()}


@dataclass
class DialogMetrics:
	"""Metrics for a dialog string"""
	byte_count: int			  # Total bytes (including control codes)
	char_count: int			  # Visible characters only
	line_count: int			  # Number of lines
	estimated_time: float		# Estimated display time in seconds
	control_codes: Dict[str, int]  # Count of each control code used
	max_line_length: int		 # Longest line in characters
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
					# Only strip newlines and leading whitespace, preserve trailing spaces in values
					line = line.rstrip('\r\n').lstrip()
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

					# Store in byte_to_char mapping (always update for decoding)
					self.byte_to_char[hex_val] = char_str

					# For encoding, only use FIRST occurrence (prefer earlier entries)
					# This way duplicates like 0x44="you" and 0x55="you" will use 0x44
					if len(char_str) > 1:
						# Multi-character DTE sequence
						if char_str not in self.multi_char_to_byte:
							self.multi_char_to_byte[char_str] = hex_val
					else:
						# Single character
						if char_str not in self.char_to_byte:
							self.char_to_byte[char_str] = hex_val

			self.loaded = True

			# Build reverse mapping for control codes (for encoding)
			self._build_control_code_mapping()

			return True
		except Exception as e:
			print(f"Error loading character table: {e}")
			self._create_default_mapping()
			return False

	def _build_control_code_mapping(self):
		"""Build reverse mapping for control codes like [PARA] -> 0x30"""
		global CONTROL_STRINGS

		# Start with base control codes - map tag strings to byte values
		control_map: Dict[str, int] = {}
		for code, name in CONTROL_NAMES.items():
			control_map[name] = code.value  # Use .value to get the integer

		# Add all control codes from loaded table
		for byte_val, char_str in self.byte_to_char.items():
			# Check if it's a control code tag like [PARA], [CRYSTAL], etc.
			if char_str.startswith('[') and char_str.endswith(']'):
				control_map[char_str] = byte_val

		CONTROL_STRINGS = control_map

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
		else:
			# Try to find control code
			try:
				code = ControlCode(byte)
				return CONTROL_NAMES.get(code, f'<{byte:02X}>')
			except ValueError:
				return f'<{byte:02X}>'


class DialogText:
	"""Handles FFMQ dialog text encoding and decoding"""

	# Dialog limits
	MAX_DIALOG_LENGTH = 512	  # Maximum bytes per dialog
	MAX_LINE_LENGTH = 32		 # Maximum characters per line (approximate)
	CHARS_PER_SECOND = 8.0	   # Average text display speed

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
			elif byte in [c.value for c in ControlCode]:
				# Check if this control code has parameters (multi-byte commands)
				if byte == ControlCode.UNK_0D and i < len(data):
					# 0x0D appears to be a multi-byte command
					param = data[i]
					i += 1
					text_parts.append(f'[UNK_0D:{param:02X}]')
				else:
					# Find the ControlCode enum by value
					try:
						code = ControlCode(byte)
						text_parts.append(CONTROL_NAMES.get(code, f'[{byte:02X}]'))
					except ValueError:
						text_parts.append(f'[{byte:02X}]')
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
					if tag.startswith('[UNK_0D:'):
						result.append(ControlCode.UNK_0D)
						# Extract hex parameter
						param_hex = tag[8:-1]
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

		# Handle parameterized codes (multi-byte commands)
		if code == ControlCode.UNK_0D and param is not None:
			tag = f'[UNK_0D:{param:02X}]'

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
			print(f"	- {warning}")
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
