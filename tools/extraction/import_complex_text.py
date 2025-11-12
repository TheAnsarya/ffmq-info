#!/usr/bin/env python3
"""
FFMQ Complex Text Re-insertion Tool
Inserts modified dialog text back into ROM with dictionary compression.
"""

import sys
import struct
from pathlib import Path
from typing import Dict, List, Tuple

def load_character_table(tbl_path: str) -> Tuple[Dict[str, int], Dict[int, str]]:
	"""Load character table for encoding/decoding."""
	char_to_byte = {}
	byte_to_char = {}
	
	with open(tbl_path, 'r', encoding='utf-8') as f:
		for line in f:
			line = line.strip()
			if not line or line.startswith(';'):
				continue
			if '=' in line:
				byte_str, char = line.split('=', 1)
				byte_val = int(byte_str, 16)
				byte_to_char[byte_val] = char
				char_to_byte[char] = byte_val
	
	return char_to_byte, byte_to_char

def load_dictionary(rom: bytes, dict_addr: int = 0x01BA35, num_entries: int = 80) -> Dict[int, bytes]:
	"""Load dictionary entries from ROM."""
	dictionary = {}
	offset = dict_addr
	
	for i in range(num_entries):
		entry_id = i + 0x30
		length = rom[offset]
		offset += 1
		data = rom[offset:offset + length]
		offset += length
		dictionary[entry_id] = bytes(data)
	
	return dictionary

def load_dialogs_from_text(text_path: str) -> Dict[int, str]:
	"""Load dialogs from extracted text file."""
	dialogs = {}
	current_dialog = None
	current_text = []
	
	with open(text_path, 'r', encoding='utf-8') as f:
		for line in f:
			line = line.rstrip('\n')
			
			# Check for dialog header
			if line.startswith('### Dialog 0x'):
				# Save previous dialog
				if current_dialog is not None:
					dialogs[current_dialog] = '\n'.join(current_text)
				
				# Start new dialog
				dialog_id_str = line.split('0x')[1].split()[0]
				current_dialog = int(dialog_id_str, 16)
				current_text = []
			elif current_dialog is not None and line and not line.startswith('---'):
				# Add line to current dialog
				current_text.append(line)
		
		# Save last dialog
		if current_dialog is not None:
			dialogs[current_dialog] = '\n'.join(current_text)
	
	return dialogs

def find_dictionary_match(text: str, dictionary: Dict[int, bytes], byte_to_char: Dict[int, str], char_to_byte: Dict[str, int]) -> Tuple[int, int]:
	"""Find best dictionary entry that matches start of text."""
	best_match_id = None
	best_match_len = 0
	
	for dict_id, dict_bytes in dictionary.items():
		# Decode dictionary entry
		decoded = decode_bytes(dict_bytes, byte_to_char, dictionary)
		
		if text.startswith(decoded) and len(decoded) > best_match_len:
			best_match_id = dict_id
			best_match_len = len(decoded)
	
	return best_match_id, best_match_len

def decode_bytes(data: bytes, byte_to_char: Dict[int, str], dictionary: Dict[int, bytes], depth: int = 0) -> str:
	"""Decode bytes to text, handling dictionary recursion."""
	if depth > 10:  # Prevent infinite recursion
		return ''
	
	result = []
	i = 0
	while i < len(data):
		byte = data[i]
		
		if byte < 0x30:
			# Control code - represent as tag
			result.append(f'[CMD:{byte:02X}]')
			i += 1
		elif byte < 0x80:
			# Dictionary reference
			if byte in dictionary:
				dict_data = dictionary[byte]
				decoded = decode_bytes(dict_data, byte_to_char, dictionary, depth + 1)
				result.append(decoded)
			else:
				result.append(f'[DICT:{byte:02X}]')
			i += 1
		else:
			# Regular character
			char = byte_to_char.get(byte, f'[0x{byte:02X}]')
			result.append(char)
			i += 1
	
	return ''.join(result)

def encode_text(text: str, char_to_byte: Dict[str, int], dictionary: Dict[int, bytes], byte_to_char: Dict[int, str]) -> bytes:
	"""Encode text to bytes with dictionary compression."""
	result = []
	i = 0
	
	while i < len(text):
		# Check for control codes [CMD:XX]
		if text[i:i+5] == '[CMD:' and text[i+9:i+10] == ']':
			code_hex = text[i+5:i+9]
			try:
				code_byte = int(code_hex, 16)
				result.append(code_byte)
				i += 10
				continue
			except:
				pass
		
		# Check for special tags
		if text[i] == '[':
			# Find matching ]
			end = text.find(']', i)
			if end != -1:
				tag = text[i+1:end]
				
				# Map tags to control codes
				tag_map = {
					'END': 0x00,
					'newline': 0x01,
					'{newline}': 0x01,
					'WAIT': 0x02,
					'ASTERISK': 0x03,
					'NAME': 0x04,
					'ITEM': 0x05,
					'SPACE': 0x06,
					'TEXTBOX_BELOW': 0x1A,
					'TEXTBOX_ABOVE': 0x1B,
					'CRYSTAL': 0x1F,
				}
				
				if tag in tag_map:
					result.append(tag_map[tag])
					i = end + 1
					continue
		
		# Try dictionary compression
		dict_id, dict_len = find_dictionary_match(text[i:], dictionary, byte_to_char, char_to_byte)
		if dict_len >= 2:  # Only use dict if it saves space
			result.append(dict_id)
			i += dict_len
			continue
		
		# Encode as single character
		if text[i] in char_to_byte:
			result.append(char_to_byte[text[i]])
			i += 1
		else:
			# Unknown character - skip it
			print(f"Warning: Unknown character '{text[i]}' at position {i}")
			i += 1
	
	# Add terminator if not present
	if not result or result[-1] != 0x00:
		result.append(0x00)
	
	return bytes(result)

def insert_dialogs_into_rom(rom_path: str, dialogs: Dict[int, str], output_path: str):
	"""Insert modified dialogs into ROM."""
	# Load ROM
	with open(rom_path, 'rb') as f:
		rom = bytearray(f.read())
	
	# Load character tables and dictionary
	tbl_path = Path(__file__).parent.parent.parent / 'simple.tbl'
	char_to_byte, byte_to_char = load_character_table(str(tbl_path))
	dictionary = load_dictionary(rom)
	
	print("="*80)
	print("FFMQ COMPLEX TEXT RE-INSERTION")
	print("="*80)
	
	# Dialog pointer table at 0x01B835
	dialog_ptrs_addr = 0x01B835
	
	# Encode all dialogs
	encoded_dialogs = {}
	total_original_size = 0
	total_new_size = 0
	
	print("\nEncoding dialogs...")
	for dialog_id in sorted(dialogs.keys()):
		text = dialogs[dialog_id]
		encoded = encode_text(text, char_to_byte, dictionary, byte_to_char)
		encoded_dialogs[dialog_id] = encoded
		
		# Get original size
		ptr_offset = dialog_ptrs_addr + (dialog_id * 2)
		ptr = rom[ptr_offset] | (rom[ptr_offset + 1] << 8)
		dialog_addr = 0x030000 + ptr
		
		if dialog_id + 1 < 117:
			next_ptr_offset = dialog_ptrs_addr + ((dialog_id + 1) * 2)
			next_ptr = rom[next_ptr_offset] | (rom[next_ptr_offset + 1] << 8)
			next_addr = 0x030000 + next_ptr
			original_size = next_addr - dialog_addr
		else:
			original_size = 100  # Estimate for last dialog
		
		total_original_size += original_size
		total_new_size += len(encoded)
		
		if len(encoded) > original_size:
			print(f"  WARNING: Dialog 0x{dialog_id:02X} is too large! " +
				  f"({len(encoded)} bytes vs {original_size} bytes available)")
	
	print(f"\nOriginal total size: {total_original_size} bytes")
	print(f"New total size: {total_new_size} bytes")
	print(f"Difference: {total_new_size - total_original_size:+d} bytes")
	
	if total_new_size > total_original_size:
		print("\n⚠️  WARNING: New dialogs are larger than original!")
		print("   This will require relocating the dialog data block.")
		print("   For now, only in-place edits (same or smaller) are supported.")
		return 1
	
	# Write dialogs back to ROM
	print("\nWriting dialogs to ROM...")
	modified_count = 0
	
	for dialog_id in sorted(encoded_dialogs.keys()):
		encoded = encoded_dialogs[dialog_id]
		
		# Get dialog address
		ptr_offset = dialog_ptrs_addr + (dialog_id * 2)
		ptr = rom[ptr_offset] | (rom[ptr_offset + 1] << 8)
		dialog_addr = 0x030000 + ptr
		
		# Get space available
		if dialog_id + 1 < 117:
			next_ptr_offset = dialog_ptrs_addr + ((dialog_id + 1) * 2)
			next_ptr = rom[next_ptr_offset] | (rom[next_ptr_offset + 1] << 8)
			next_addr = 0x030000 + next_ptr
			space_available = next_addr - dialog_addr
		else:
			space_available = 200  # Estimate
		
		# Only write if it fits
		if len(encoded) <= space_available:
			rom[dialog_addr:dialog_addr + len(encoded)] = encoded
			# Fill remaining space with 0xFF
			if len(encoded) < space_available:
				rom[dialog_addr + len(encoded):dialog_addr + space_available] = bytes([0xFF] * (space_available - len(encoded)))
			modified_count += 1
		else:
			print(f"  Skipping dialog 0x{dialog_id:02X} (too large)")
	
	# Save modified ROM
	with open(output_path, 'wb') as f:
		f.write(rom)
	
	print(f"\n✓ Modified {modified_count} dialogs")
	print(f"✓ Saved to: {output_path}")
	
	return 0

def main():
	if len(sys.argv) < 3:
		print("Usage: python import_complex_text.py <input_text_file> <output_rom>")
		print()
		print("Example:")
		print("  python import_complex_text.py extracted_dialogs.txt modified_rom.sfc")
		return 1
	
	text_path = sys.argv[1]
	output_path = sys.argv[2]
	
	# Find original ROM
	rom_path = Path(__file__).parent.parent.parent / 'roms' / 'Final Fantasy - Mystic Quest (U) (V1.1).sfc'
	
	if not rom_path.exists():
		print(f"Error: ROM not found at {rom_path}")
		return 1
	
	if not Path(text_path).exists():
		print(f"Error: Text file not found: {text_path}")
		return 1
	
	# Load dialogs from text file
	print(f"Loading dialogs from {text_path}...")
	dialogs = load_dialogs_from_text(text_path)
	print(f"Loaded {len(dialogs)} dialogs")
	
	# Insert into ROM
	return insert_dialogs_into_rom(str(rom_path), dialogs, output_path)

if __name__ == '__main__':
	sys.exit(main())
