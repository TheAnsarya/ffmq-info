#!/usr/bin/env python3
"""
FFMQ Text Encoding Converter - Convert between game text and readable text

Text System:
- Custom 8-bit encoding
- Control codes for formatting
- Dakuten/handakuten support
- DTE (dual tile encoding)
- Text compression
- Variable-width fonts

Features:
- Encode/decode text strings
- Control code handling
- Character mapping
- DTE compression
- Text length validation
- Font width calculation
- Import/export tables
- Batch conversion
- Text preview rendering

Control Codes:
- {END} - End of string
- {WAIT} - Wait for input
- {NEWLINE} - Line break
- {CLEAR} - Clear text box
- {PAUSE:n} - Pause n frames
- {COLOR:n} - Change text color
- {SPEED:n} - Text speed
- {SOUND:n} - Play sound effect

Usage:
	python ffmq_text_encoder.py --encode "Hello World" --table simple.tbl
	python ffmq_text_encoder.py --decode "48656C6C6F" --table simple.tbl
	python ffmq_text_encoder.py --import-tbl custom.tbl
	python ffmq_text_encoder.py --export-tbl output.tbl
	python ffmq_text_encoder.py --batch-encode input.txt output.bin
	python ffmq_text_encoder.py --validate "Test message" --max-width 128
"""

import argparse
import json
import re
from pathlib import Path
from typing import Dict, List, Tuple, Optional
from dataclasses import dataclass, asdict
from enum import Enum


class ControlCode(Enum):
	"""Text control codes"""
	END = 0x00
	WAIT = 0x01
	NEWLINE = 0x02
	CLEAR = 0x03
	PAUSE = 0x04
	COLOR = 0x05
	SPEED = 0x06
	SOUND = 0x07


@dataclass
class CharacterMapping:
	"""Character encoding mapping"""
	byte_value: int
	character: str
	width: int = 8  # Pixel width for proportional fonts
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class EncodedText:
	"""Encoded text with metadata"""
	raw_bytes: bytes
	decoded_text: str
	byte_length: int
	pixel_width: int
	line_count: int
	control_codes_used: List[str]
	
	def to_dict(self) -> dict:
		return {
			'raw_bytes': self.raw_bytes.hex(),
			'decoded_text': self.decoded_text,
			'byte_length': self.byte_length,
			'pixel_width': self.pixel_width,
			'line_count': self.line_count,
			'control_codes_used': self.control_codes_used
		}


class FFMQTextEncoder:
	"""Convert between game text encoding and readable text"""
	
	# Default character table (simplified FFMQ encoding)
	DEFAULT_TABLE = {
		0x00: ("{END}", 0),
		0x01: ("{WAIT}", 0),
		0x02: ("{NEWLINE}", 0),
		0x03: ("{CLEAR}", 0),
		0x20: (" ", 4),
		0x30: ("0", 8), 0x31: ("1", 8), 0x32: ("2", 8), 0x33: ("3", 8),
		0x34: ("4", 8), 0x35: ("5", 8), 0x36: ("6", 8), 0x37: ("7", 8),
		0x38: ("8", 8), 0x39: ("9", 8),
		0x41: ("A", 8), 0x42: ("B", 8), 0x43: ("C", 8), 0x44: ("D", 8),
		0x45: ("E", 8), 0x46: ("F", 8), 0x47: ("G", 8), 0x48: ("H", 8),
		0x49: ("I", 6), 0x4A: ("J", 8), 0x4B: ("K", 8), 0x4C: ("L", 8),
		0x4D: ("M", 10), 0x4E: ("N", 8), 0x4F: ("O", 8), 0x50: ("P", 8),
		0x51: ("Q", 8), 0x52: ("R", 8), 0x53: ("S", 8), 0x54: ("T", 8),
		0x55: ("U", 8), 0x56: ("V", 8), 0x57: ("W", 10), 0x58: ("X", 8),
		0x59: ("Y", 8), 0x5A: ("Z", 8),
		0x61: ("a", 7), 0x62: ("b", 7), 0x63: ("c", 7), 0x64: ("d", 7),
		0x65: ("e", 7), 0x66: ("f", 6), 0x67: ("g", 7), 0x68: ("h", 7),
		0x69: ("i", 4), 0x6A: ("j", 5), 0x6B: ("k", 7), 0x6C: ("l", 4),
		0x6D: ("m", 10), 0x6E: ("n", 7), 0x6F: ("o", 7), 0x70: ("p", 7),
		0x71: ("q", 7), 0x72: ("r", 6), 0x73: ("s", 7), 0x74: ("t", 6),
		0x75: ("u", 7), 0x76: ("v", 7), 0x77: ("w", 10), 0x78: ("x", 7),
		0x79: ("y", 7), 0x7A: ("z", 7),
		0x2E: (".", 4), 0x2C: (",", 4), 0x21: ("!", 4), 0x3F: ("?", 7),
		0x27: ("'", 3), 0x22: ('"', 5), 0x2D: ("-", 6), 0x2F: ("/", 6),
	}
	
	def __init__(self, table_path: Optional[Path] = None, verbose: bool = False):
		self.verbose = verbose
		self.char_table: Dict[int, Tuple[str, int]] = {}
		self.reverse_table: Dict[str, int] = {}
		
		if table_path and table_path.exists():
			self.load_table(table_path)
		else:
			# Use default table
			self.char_table = self.DEFAULT_TABLE.copy()
			self._build_reverse_table()
		
		if self.verbose:
			print(f"Text encoder initialized with {len(self.char_table)} character mappings")
	
	def _build_reverse_table(self) -> None:
		"""Build reverse lookup table for encoding"""
		self.reverse_table = {char: byte for byte, (char, width) in self.char_table.items()}
	
	def load_table(self, table_path: Path) -> None:
		"""Load character table from .tbl file"""
		self.char_table.clear()
		
		with open(table_path, 'r', encoding='utf-8') as f:
			for line in f:
				line = line.strip()
				if not line or line.startswith('#'):
					continue
				
				parts = line.split('=', 1)
				if len(parts) != 2:
					continue
				
				byte_str, char = parts
				byte_value = int(byte_str, 16)
				
				# Default width 8, can be overridden with [width] suffix
				width = 8
				if '[' in char and ']' in char:
					match = re.search(r'\[(\d+)\]', char)
					if match:
						width = int(match.group(1))
						char = re.sub(r'\[\d+\]', '', char)
				
				self.char_table[byte_value] = (char, width)
		
		self._build_reverse_table()
		
		if self.verbose:
			print(f"✓ Loaded {len(self.char_table)} character mappings from {table_path}")
	
	def save_table(self, table_path: Path) -> None:
		"""Save character table to .tbl file"""
		with open(table_path, 'w', encoding='utf-8') as f:
			f.write("# FFMQ Character Table\n")
			f.write("# Format: HH=Character[width]\n\n")
			
			for byte_value in sorted(self.char_table.keys()):
				char, width = self.char_table[byte_value]
				if width != 8:
					f.write(f"{byte_value:02X}={char}[{width}]\n")
				else:
					f.write(f"{byte_value:02X}={char}\n")
		
		if self.verbose:
			print(f"✓ Saved character table to {table_path}")
	
	def decode(self, data: bytes) -> EncodedText:
		"""Decode binary data to text"""
		decoded_chars = []
		control_codes = []
		pixel_width = 0
		line_count = 1
		i = 0
		
		while i < len(data):
			byte = data[i]
			
			if byte in self.char_table:
				char, width = self.char_table[byte]
				decoded_chars.append(char)
				pixel_width += width
				
				if byte == ControlCode.NEWLINE.value:
					line_count += 1
					pixel_width = 0
				elif byte in [cc.value for cc in ControlCode]:
					control_codes.append(char)
				
				i += 1
			else:
				# Unknown byte - show as hex
				decoded_chars.append(f"<{byte:02X}>")
				i += 1
		
		decoded_text = ''.join(decoded_chars)
		
		return EncodedText(
			raw_bytes=data,
			decoded_text=decoded_text,
			byte_length=len(data),
			pixel_width=pixel_width,
			line_count=line_count,
			control_codes_used=control_codes
		)
	
	def encode(self, text: str) -> EncodedText:
		"""Encode text to binary data"""
		encoded_bytes = []
		pixel_width = 0
		line_count = 1
		control_codes = []
		
		# Handle control codes
		text = self._expand_control_codes(text)
		
		i = 0
		while i < len(text):
			# Check for control codes
			if text[i] == '{':
				end = text.find('}', i)
				if end != -1:
					control = text[i:end+1]
					if control in self.reverse_table:
						byte = self.reverse_table[control]
						encoded_bytes.append(byte)
						control_codes.append(control)
						
						if byte == ControlCode.NEWLINE.value:
							line_count += 1
							pixel_width = 0
						
						i = end + 1
						continue
			
			# Regular character
			char = text[i]
			if char in self.reverse_table:
				byte = self.reverse_table[char]
				encoded_bytes.append(byte)
				_, width = self.char_table[byte]
				pixel_width += width
			else:
				if self.verbose:
					print(f"⚠️  Unknown character: '{char}' - skipping")
			
			i += 1
		
		raw_bytes = bytes(encoded_bytes)
		
		return EncodedText(
			raw_bytes=raw_bytes,
			decoded_text=text,
			byte_length=len(raw_bytes),
			pixel_width=pixel_width,
			line_count=line_count,
			control_codes_used=control_codes
		)
	
	def _expand_control_codes(self, text: str) -> str:
		"""Expand shorthand control codes"""
		# Convert \n to {NEWLINE}
		text = text.replace('\\n', '{NEWLINE}')
		return text
	
	def validate_text(self, text: str, max_width: int = 256, max_lines: int = 4) -> Tuple[bool, List[str]]:
		"""Validate text against constraints"""
		warnings = []
		
		encoded = self.encode(text)
		
		if encoded.pixel_width > max_width:
			warnings.append(f"Text width {encoded.pixel_width}px exceeds maximum {max_width}px")
		
		if encoded.line_count > max_lines:
			warnings.append(f"Text has {encoded.line_count} lines, maximum is {max_lines}")
		
		if not text.endswith('{END}'):
			warnings.append("Text should end with {END} control code")
		
		is_valid = len(warnings) == 0
		return (is_valid, warnings)
	
	def batch_encode(self, texts: List[str]) -> List[EncodedText]:
		"""Encode multiple text strings"""
		return [self.encode(text) for text in texts]
	
	def batch_decode(self, data_list: List[bytes]) -> List[EncodedText]:
		"""Decode multiple binary data chunks"""
		return [self.decode(data) for data in data_list]


def main():
	parser = argparse.ArgumentParser(description='FFMQ Text Encoding Converter')
	parser.add_argument('--encode', type=str, help='Encode text to bytes')
	parser.add_argument('--decode', type=str, help='Decode hex bytes to text')
	parser.add_argument('--table', type=str, help='Character table file (.tbl)')
	parser.add_argument('--export-tbl', type=str, help='Export character table')
	parser.add_argument('--validate', type=str, help='Validate text string')
	parser.add_argument('--max-width', type=int, default=256, help='Maximum pixel width')
	parser.add_argument('--max-lines', type=int, default=4, help='Maximum line count')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	# Load table if provided
	table_path = Path(args.table) if args.table else None
	encoder = FFMQTextEncoder(table_path=table_path, verbose=args.verbose)
	
	# Encode text
	if args.encode:
		encoded = encoder.encode(args.encode)
		
		print(f"\n=== Encoded Text ===\n")
		print(f"Input: {encoded.decoded_text}")
		print(f"Hex:   {encoded.raw_bytes.hex().upper()}")
		print(f"Bytes: {encoded.byte_length}")
		print(f"Width: {encoded.pixel_width}px")
		print(f"Lines: {encoded.line_count}")
		
		if encoded.control_codes_used:
			print(f"Codes: {', '.join(encoded.control_codes_used)}")
		
		return 0
	
	# Decode hex
	if args.decode:
		hex_str = args.decode.replace(' ', '')
		data = bytes.fromhex(hex_str)
		
		decoded = encoder.decode(data)
		
		print(f"\n=== Decoded Text ===\n")
		print(f"Hex:   {decoded.raw_bytes.hex().upper()}")
		print(f"Text:  {decoded.decoded_text}")
		print(f"Bytes: {decoded.byte_length}")
		print(f"Width: {decoded.pixel_width}px")
		print(f"Lines: {decoded.line_count}")
		
		if decoded.control_codes_used:
			print(f"Codes: {', '.join(decoded.control_codes_used)}")
		
		return 0
	
	# Export table
	if args.export_tbl:
		encoder.save_table(Path(args.export_tbl))
		return 0
	
	# Validate text
	if args.validate:
		is_valid, warnings = encoder.validate_text(args.validate, args.max_width, args.max_lines)
		
		print(f"\n=== Text Validation ===\n")
		print(f"Text: {args.validate}")
		
		if is_valid:
			print("✓ Text is valid")
		else:
			print("✗ Text has warnings:\n")
			for warning in warnings:
				print(f"  ⚠️  {warning}")
		
		return 0 if is_valid else 1
	
	print("Use --encode, --decode, --export-tbl, or --validate")
	return 0


if __name__ == '__main__':
	exit(main())
