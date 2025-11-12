#!/usr/bin/env python3
"""
Build empirical DTE table by matching ROM bytes to expected text.

Strategy:
1. We know single-byte characters from simple.tbl
2. We know 0xFF = space
3. We can deduce DTE sequences by elimination
"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))

from tools.text.simple_text_decoder import SimpleTextDecoder


# Dialog 0x59 data
EXPECTED_TEXT = "For years Mac's been studying a Prophecy. On his way back from doing research, he found a magic Bone, which he brought to Benjamin. We're being attacked by monsters! Benjamin, you can do it!"

ROM_BYTES = bytes([
	0x4C, 0x70, 0xC1, 0xB4, 0xC0, 0x40, 0xB5, 0xB8, 0xB9, 0x5C, 0xB8, 0xCE, 0x1B, 0x32, 0x9F, 0x5C,
	0xFF, 0xCC, 0x5E, 0xC5, 0x45, 0xA6, 0xB4, 0xB6, 0x4E, 0xB5, 0xB8, 0x56, 0xFF, 0x65, 0xC8, 0xB7,
	0xCC, 0x48, 0x78, 0xA9, 0xC5, 0xC2, 0xC3, 0xBB, 0xB8, 0xB6, 0xCC, 0xD2, 0xFF, 0xFF, 0xA8, 0xC1,
	0xFF, 0xBB, 0x5F, 0x63, 0x59, 0xB5, 0x6C, 0xFF, 0xB9, 0xC5, 0x69, 0xFF, 0xB7, 0xC2, 0x48, 0xC6,
	0x69, 0x40, 0xC5, 0x60, 0x5E, 0xC5, 0xB6, 0xBB, 0xD2, 0xFF, 0xBB, 0x40, 0xB9, 0xC2, 0xC8, 0xC1,
	0xB7, 0xFF, 0xB4, 0xFF, 0xC0, 0xB4, 0xBD, 0xBC, 0xB6, 0xFF, 0xA5, 0xC2, 0xC1, 0xB8, 0xD2, 0xFF,
	0xCF, 0xBB, 0xBC, 0xB6, 0xBB, 0xFF, 0xBB, 0x40, 0xB5, 0xC5, 0xC2, 0xC8, 0xBD, 0xBE, 0x42, 0xC2,
	0xFF, 0xA5, 0xB8, 0xC1, 0xBF, 0xB4, 0xC0, 0xBC, 0xC1, 0xD2, 0xFF, 0xAC, 0x40, 0xD2, 0xC5, 0x40,
	0xB5, 0x56, 0xFF, 0xB4, 0xBE, 0xBE, 0xB4, 0xB6, 0xBE, 0x60, 0xFF, 0xB5, 0xCC, 0xFF, 0xC0, 0xC2,
	0xC1, 0xD2, 0xC5, 0xD2, 0xCD, 0xFF, 0xA5, 0xB8, 0xC1, 0xBF, 0xB4, 0xC0, 0xBC, 0xC1, 0xD2, 0xFF,
	0xCC, 0xC2, 0xC8, 0xFF, 0xB6, 0xB4, 0xC1, 0xFF, 0xB7, 0xC2, 0xFF, 0xBC, 0x42, 0xCD
])


def build_dte_table():
	"""Build DTE table by matching bytes to expected text"""
	
	decoder = SimpleTextDecoder()
	simple_chars = decoder.char_table
	
	# DTE mappings we'll deduce
	dte_map = {}
	
	# Process byte by byte, matching to expected text
	text_pos = 0
	byte_pos = 0
	
	print("=" * 80)
	print("BUILDING DTE TABLE")
	print("=" * 80)
	
	while byte_pos < len(ROM_BYTES) and text_pos < len(EXPECTED_TEXT):
		byte = ROM_BYTES[byte_pos]
		
		# Skip control codes
		if byte < 0x40:
			print(f"Byte {byte_pos:03d} (0x{byte:02X}): [CONTROL]")
			byte_pos += 1
			continue
		
		# Check if it's 0xFF (space)
		if byte == 0xFF:
			expected = EXPECTED_TEXT[text_pos] if text_pos < len(EXPECTED_TEXT) else '?'
			if expected == ' ':
				print(f"Byte {byte_pos:03d} (0xFF): ' ' (space) OK")
				text_pos += 1
				byte_pos += 1
			else:
				print(f"Byte {byte_pos:03d} (0xFF): ' ' but expected '{expected}' MISMATCH")
				byte_pos += 1
			continue
		
		# Check if it's a known single character
		if byte in simple_chars:
			char = simple_chars[byte]
			expected = EXPECTED_TEXT[text_pos] if text_pos < len(EXPECTED_TEXT) else '?'
			
			if char == expected:
				print(f"Byte {byte_pos:03d} (0x{byte:02X}): '{char}' OK")
				text_pos += 1
				byte_pos += 1
			else:
				# Not a match - might be DTE
				# Try to find how many characters this byte represents
				for dte_len in range(2, 8):
					if text_pos + dte_len > len(EXPECTED_TEXT):
						break
					
					dte_text = EXPECTED_TEXT[text_pos:text_pos + dte_len]
					
					# Check if next byte matches next expected character
					if byte_pos + 1 < len(ROM_BYTES):
						next_byte = ROM_BYTES[byte_pos + 1]
						
						if next_byte == 0xFF:  # Space
							expected_after = EXPECTED_TEXT[text_pos + dte_len] if text_pos + dte_len < len(EXPECTED_TEXT) else '?'
							if expected_after == ' ':
								# Found DTE!
								print(f"Byte {byte_pos:03d} (0x{byte:02X}): '{dte_text}' [DTE] OK")
								dte_map[byte] = dte_text
								text_pos += dte_len
								byte_pos += 1
								break
						elif next_byte in simple_chars:
							next_char = simple_chars[next_byte]
							expected_after = EXPECTED_TEXT[text_pos + dte_len] if text_pos + dte_len < len(EXPECTED_TEXT) else '?'
							
							if next_char == expected_after:
								# Found DTE!
								print(f"Byte {byte_pos:03d} (0x{byte:02X}): '{dte_text}' [DTE] OK")
								dte_map[byte] = dte_text
								text_pos += dte_len
								byte_pos += 1
								break
				else:
					# No match found
					print(f"Byte {byte_pos:03d} (0x{byte:02X}): '{char}' but expected '{expected}' - MISMATCH")
					byte_pos += 1
		else:
			# Unknown byte - must be DTE
			# Try different lengths
			for dte_len in range(1, 8):
				if text_pos + dte_len > len(EXPECTED_TEXT):
					break
				
				dte_text = EXPECTED_TEXT[text_pos:text_pos + dte_len]
				
				# Check next byte
				if byte_pos + 1 < len(ROM_BYTES):
					next_byte = ROM_BYTES[byte_pos + 1]
					
					if next_byte == 0xFF:
						expected_after = EXPECTED_TEXT[text_pos + dte_len] if text_pos + dte_len < len(EXPECTED_TEXT) else ''
						if expected_after == ' ':
							print(f"Byte {byte_pos:03d} (0x{byte:02X}): '{dte_text}' [DTE] OK")
							dte_map[byte] = dte_text
							text_pos += dte_len
							byte_pos += 1
							break
					elif next_byte in simple_chars:
						next_char = simple_chars[next_byte]
						expected_after = EXPECTED_TEXT[text_pos + dte_len] if text_pos + dte_len < len(EXPECTED_TEXT) else ''
						
						if expected_after and next_char == expected_after:
							print(f"Byte {byte_pos:03d} (0x{byte:02X}): '{dte_text}' [DTE] OK")
							dte_map[byte] = dte_text
							text_pos += dte_len
							byte_pos += 1
							break
					elif next_byte < 0x40:  # Control code
						# Assume DTE before control code
						print(f"Byte {byte_pos:03d} (0x{byte:02X}): '{dte_text}' [DTE?] (before control)")
						dte_map[byte] = dte_text
						text_pos += dte_len
						byte_pos += 1
						break
			else:
				# Couldn't match
				print(f"Byte {byte_pos:03d} (0x{byte:02X}): [UNKNOWN DTE]")
				byte_pos += 1
	
	# Print DTE table
	print("\n" + "=" * 80)
	print("DTE TABLE")
	print("=" * 80)
	
	for byte in sorted(dte_map.keys()):
		text = dte_map[byte]
		print(f"0x{byte:02X} = '{text}'")
	
	print(f"\nTotal DTE codes found: {len(dte_map)}")
	
	return dte_map


def main():
	"""Main entry point"""
	dte_map = build_dte_table()
	
	# Export to file
	output_path = "dte_deduced.tbl"
	with open(output_path, 'w', encoding='utf-8') as f:
		f.write("# DTE mappings deduced from dialog 0x59\n\n")
		for byte in sorted(dte_map.keys()):
			text = dte_map[byte]
			f.write(f"{byte:02X}={text}\n")
	
	print(f"\nExported to: {output_path}")


if __name__ == '__main__':
	main()
