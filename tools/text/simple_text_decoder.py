#!/usr/bin/env python3
"""
FFMQ Simple Text Decoder
Handles decoding of fixed-length text using simple character table (simple.tbl)

Used for: Items, Weapons, Armor, Accessories, Spells, Monsters
NOT for dialogs (use DialogText for complex DTE-compressed text)
"""

import sys
from pathlib import Path
from typing import Dict, Tuple, Optional


class SimpleTextDecoder:
	"""
	Decode FFMQ simple text using direct byte-to-character mapping
	
	Character ranges (from simple.tbl):
		0x00-0x8F: Control codes and placeholders
		0x90-0x99: Digits (0-9)
		0x9A-0xB3: Uppercase (A-Z)
		0xB4-0xCD: Lowercase (a-z)
		0xCE-0xFF: Punctuation and special characters
	
	String format:
		[text bytes] [padding: 0x03 or 0xFF] [terminator: 0x00]
		or
		[text bytes] [terminator: 0x00]
	"""
	
	def __init__(self, tbl_path: Optional[Path] = None):
		"""
		Initialize decoder with character table
		
		Args:
			tbl_path: Path to simple.tbl file (auto-detected if None)
		"""
		self.char_table: Dict[int, str] = {}
		self.reverse_table: Dict[str, int] = {}
		
		# Auto-detect simple.tbl location
		if tbl_path is None:
			# Try workspace root
			tbl_path = Path(__file__).parent.parent.parent / 'simple.tbl'
		
		self.tbl_path = Path(tbl_path)
		self.load_character_table()
	
	def load_character_table(self) -> bool:
		"""
		Load character table from simple.tbl
		
		Format: XX=C where XX is hex byte, C is character
		Example: 9F=F (byte 0x9F maps to 'F')
		
		Returns:
			True if loaded successfully
		"""
		if not self.tbl_path.exists():
			raise FileNotFoundError(f"Character table not found: {self.tbl_path}")
		
		with open(self.tbl_path, 'r', encoding='utf-8') as f:
			for line in f:
				line = line.strip()
				if not line or '=' not in line:
					continue
				
				# Parse: XX=C
				parts = line.split('=', 1)
				if len(parts) != 2:
					continue
				
				hex_str, char = parts
				try:
					byte_val = int(hex_str, 16)
					# Skip placeholder entries (# or empty)
					if char and char != '#':
						self.char_table[byte_val] = char
						self.reverse_table[char] = byte_val
				except ValueError:
					continue
		
		return len(self.char_table) > 0
	
	def decode(self, data: bytes, max_length: Optional[int] = None) -> Tuple[str, int]:
		"""
		Decode fixed-length text from byte data
		
		Args:
			data: Byte data to decode
			max_length: Maximum length to process (None = all data)
		
		Returns:
			(decoded_text, actual_byte_length)
		
		Example:
			>>> decoder.decode(bytes([0x9F, 0xBC, 0xC5, 0xB8, 0x03, 0x03, 0x03, 0x03]))
			('Fire', 4)
		"""
		if max_length is not None:
			data = data[:max_length]
		
		text = []
		actual_length = 0
		
		for i, byte in enumerate(data):
			actual_length = i + 1
			
			# Terminator: end of string
			if byte == 0x00:
				break
			
			# Padding bytes: skip but continue counting
			if byte == 0x03 or byte == 0xFF:
				continue
			
			# Lookup character
			if byte in self.char_table:
				char = self.char_table[byte]
				text.append(char)
			else:
				# Unknown byte - show as hex
				text.append(f'<{byte:02X}>')
		
		return ''.join(text), actual_length
	
	def encode(self, text: str, fixed_length: int, padding_byte: int = 0x03) -> bytes:
		"""
		Encode text to fixed-length byte array
		
		Args:
			text: Text string to encode
			fixed_length: Total byte length (includes padding/terminator)
			padding_byte: Byte to use for padding (0x03 or 0xFF)
		
		Returns:
			Fixed-length byte array
		
		Raises:
			ValueError: If text is too long for fixed_length
		
		Example:
			>>> decoder.encode('Fire', 12, padding_byte=0x03)
			b'\\x9F\\xBC\\xC5\\xB8\\x03\\x03\\x03\\x03\\x03\\x03\\x03\\x03'
		"""
		# Encode each character
		encoded = []
		for char in text:
			if char not in self.reverse_table:
				raise ValueError(f"Character '{char}' not in character table")
			encoded.append(self.reverse_table[char])
		
		# Check length
		if len(encoded) >= fixed_length:
			raise ValueError(
				f"Text too long: {len(encoded)} bytes >= {fixed_length} max "
				f"(text: '{text}')"
			)
		
		# Pad to fixed length
		while len(encoded) < fixed_length:
			encoded.append(padding_byte)
		
		return bytes(encoded)
	
	def decode_table(
		self,
		rom_data: bytes,
		start_address: int,
		entry_count: int,
		entry_length: int
	) -> list[dict]:
		"""
		Decode a table of fixed-length strings
		
		Args:
			rom_data: ROM data bytes
			start_address: PC address in ROM
			entry_count: Number of entries to decode
			entry_length: Bytes per entry
		
		Returns:
			List of dicts with: id, text, address, length
		
		Example:
			>>> decoder.decode_table(rom_data, 0x064210, 64, 12)
			[
				{'id': 0, 'text': 'Exit', 'address': 0x064210, 'length': 4},
				{'id': 1, 'text': 'Cure', 'address': 0x06421C, 'length': 4},
				...
			]
		"""
		entries = []
		current_addr = start_address
		
		for entry_id in range(entry_count):
			# Extract data
			if current_addr + entry_length > len(rom_data):
				break
			
			entry_data = rom_data[current_addr:current_addr + entry_length]
			
			# Decode
			text, actual_len = self.decode(entry_data, max_length=entry_length)
			
			# Only include non-empty entries
			if text.strip():
				entries.append({
					'id': entry_id,
					'text': text,
					'address': current_addr,
					'length': actual_len
				})
			
			current_addr += entry_length
		
		return entries
	
	def get_stats(self) -> dict:
		"""Get decoder statistics"""
		return {
			'total_chars': len(self.char_table),
			'digits': sum(1 for b in self.char_table if 0x90 <= b <= 0x99),
			'uppercase': sum(1 for b in self.char_table if 0x9A <= b <= 0xB3),
			'lowercase': sum(1 for b in self.char_table if 0xB4 <= b <= 0xCD),
			'special': sum(1 for b in self.char_table if b > 0xCD),
		}


def main():
	"""Test the decoder"""
	decoder = SimpleTextDecoder()
	stats = decoder.get_stats()
	
	print("Simple Text Decoder - Character Table Stats")
	print("=" * 70)
	print(f"Total characters: {stats['total_chars']}")
	print(f"  Digits (0-9):   {stats['digits']}")
	print(f"  Uppercase (A-Z): {stats['uppercase']}")
	print(f"  Lowercase (a-z): {stats['lowercase']}")
	print(f"  Special chars:   {stats['special']}")
	print()
	
	# Test with spell name "Fire"
	test_data = bytes([0x9F, 0xBC, 0xC5, 0xB8, 0x03, 0x03, 0x03, 0x03])
	text, length = decoder.decode(test_data)
	print(f"Test decode: {test_data.hex()} -> '{text}' (length: {length})")
	
	# Test encode
	encoded = decoder.encode('Fire', 12, padding_byte=0x03)
	print(f"Test encode: 'Fire' -> {encoded.hex()}")
	
	return True


if __name__ == '__main__':
	success = main()
	sys.exit(0 if success else 1)
