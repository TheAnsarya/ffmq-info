#!/usr/bin/env python3
"""
Analyze dialog 0x59 (opening dialog) to deduce DTE mappings.

Expected text: "For years Mac's been studying a Prophecy. On his way back from doing research..."
ROM bytes: 4C 70 C1 B4 C0 40 B5 B8 B9 5C B8 CE 1B...

This script compares the ROM bytes to the expected text character-by-character
to determine which bytes represent which DTE sequences.
"""

import sys
from pathlib import Path

# Add parent directory
sys.path.insert(0, str(Path(__file__).parent))

from tools.text.simple_text_decoder import SimpleTextDecoder


# Expected text for dialog 0x59 (from game)
EXPECTED_TEXT = "For years Mac's been studying a Prophecy. On his way back from doing research, he found a magic Bone, which he brought to Benjamin. We're being attacked by monsters! Benjamin, you can do it!"

# ROM bytes for dialog 0x59
ROM_BYTES = bytes([
	0x4C, 0x70, 0xC1, 0xB4, 0xC0, 0x40, 0xB5, 0xB8, 0xB9, 0x5C, 0xB8, 0xCE, 0x1B, 0x32, 0x9F, 0x5C,
	0xFF, 0xCC, 0x5E, 0xC5, 0x45, 0xA6, 0xB4, 0xB6, 0x4E, 0xB5, 0xB8, 0x56, 0xFF, 0x65, 0xC8, 0xB7,
	0xCC, 0x48, 0x78, 0xA9, 0xC5, 0xC2, 0xC3, 0xBB, 0xB8, 0xB6, 0xCC, 0xD2, 0xFF, 0xFF, 0xA8, 0xC1,
	0xFF, 0xBB, 0x5F, 0x63, 0x59, 0xB5, 0x6C, 0xFF, 0xB9, 0xC5, 0x69, 0xFF, 0xB7, 0xC2, 0x48, 0xC6,
	0x69, 0x40, 0xC5, 0x60, 0x5E, 0xC5, 0xB6, 0xBB, 0x4D, 0x41, 0xBF, 0xB4, 0xBE, 0x40, 0xB7, 0xC5,
])


def analyze_dte():
	"""Analyze the opening dialog to deduce DTE mappings"""
	
	# Load simple character table
	decoder = SimpleTextDecoder()
	simple_chars = decoder.char_table
	
	print("=" * 80)
	print("DTE ANALYSIS - Dialog 0x59 (Opening Dialog)")
	print("=" * 80)
	print(f"Expected: '{EXPECTED_TEXT[:80]}...'")
	print(f"ROM bytes: {' '.join(f'{b:02X}' for b in ROM_BYTES[:32])}...")
	print()
	
	# Manual analysis based on expected text patterns
	dte_map = {}
	
	# Let's analyze byte by byte
	print("Byte-by-Byte Analysis:")
	print("-" * 80)
	
	# Start with known patterns
	# "For" = bytes should start with F + or
	# Looking at: 4C 70 C1 B4 C0 40...
	
	# 0x9F = 'F' (we know this from simple.tbl)
	# But first byte is 0x4C...
	
	# Actually, let me check simple.tbl first
	print("\nSingle-byte characters in ROM bytes:")
	for i, byte in enumerate(ROM_BYTES[:80]):
		if byte in simple_chars:
			char = simple_chars[byte]
			print(f"  Byte {i:02d} (0x{byte:02X}): '{char}'")
	
	print("\nDTE candidates (bytes not in simple.tbl):")
	dte_bytes = set()
	for byte in ROM_BYTES:
		if byte not in simple_chars and byte >= 0x40:  # Not control code, not simple char
			dte_bytes.add(byte)
	
	for byte in sorted(dte_bytes):
		print(f"  0x{byte:02X}")
	
	print(f"\nTotal DTE candidates: {len(dte_bytes)}")
	
	# Let me try a different approach: frequency analysis
	# Common 2-letter sequences in English
	common_pairs = [
		"th", "he", "in", "er", "an", "re", "on", "at", "en", "nd",
		"ti", "es", "or", "te", "of", "ed", "is", "it", "al", "ar",
		"st", "to", "nt", "ng", "se", "ha", "as", "ou", "io", "le"
	]
	
	# Common 3-letter sequences
	common_triples = [
		"the", "and", "ing", "ion", "tio", "ent", "ati", "for", "her", "ter",
		"ear", "are", "rou", "you", "all", "his", "our"
	]
	
	print("\nLooking for common sequences in expected text:")
	text_lower = EXPECTED_TEXT.lower()
	
	found_sequences = {}
	for seq in common_pairs + common_triples:
		count = text_lower.count(seq)
		if count > 0:
			found_sequences[seq] = count
	
	# Sort by frequency
	sorted_seqs = sorted(found_sequences.items(), key=lambda x: x[1], reverse=True)
	
	print("\nMost common sequences:")
	for seq, count in sorted_seqs[:20]:
		print(f"  '{seq}': {count} times")
	
	# Now let's try to match specific patterns
	print("\n" + "=" * 80)
	print("PATTERN MATCHING")
	print("=" * 80)
	
	# Expected: "For years Mac's"
	# Let's assume:
	# - 0xFF = space (likely)
	# - Letters are encoded somehow
	
	# Looking at first 16 bytes: 4C 70 C1 B4 C0 40 B5 B8 B9 5C B8 CE 1B 32 9F 5C
	# Expected: "For years Mac's"
	
	# If "For" is at the start, let's check if any bytes map to single letters
	# F=0x9F, o=0xC2, r=0xC5 from simple.tbl (maybe)
	
	# Check if F appears anywhere
	f_byte = 0x9F  # F from simple.tbl
	if f_byte in simple_chars:
		print(f"\n'F' = 0x{f_byte:02X} (simple.tbl)")
		
		# Look for F in ROM bytes
		f_positions = [i for i, b in enumerate(ROM_BYTES) if b == f_byte]
		print(f"  Found at positions: {f_positions}")
		
		if f_positions:
			print(f"  Expected F at: {[i for i, c in enumerate(EXPECTED_TEXT) if c == 'F']}")
	
	# Let me try a different strategy: look at the 0xFF bytes (likely spaces)
	print("\n0xFF positions (likely spaces):")
	space_positions = [i for i, b in enumerate(ROM_BYTES) if b == 0xFF]
	print(f"  ROM positions: {space_positions[:10]}")
	print(f"  Expected space positions: {[i for i, c in enumerate(EXPECTED_TEXT[:80]) if c == ' '][:10]}")
	
	# If 0xFF=space at position 15 matches expected space at position...
	# Let's count how many bytes come before first space
	if space_positions:
		first_space_byte = space_positions[0]
		print(f"\nFirst 0xFF at byte position: {first_space_byte}")
		print(f"  Bytes before: {' '.join(f'{b:02X}' for b in ROM_BYTES[:first_space_byte])}")
		
		# Expected text before first space
		first_space_char = EXPECTED_TEXT.index(' ')
		print(f"First space in expected text at char position: {first_space_char}")
		print(f"  Text before: '{EXPECTED_TEXT[:first_space_char]}'")
		
		# "For" is 3 characters, but we have 15 bytes before space
		# This suggests heavy DTE compression
		
		# Let's try: "For" might be a single DTE byte
		if first_space_byte < len(ROM_BYTES):
			print(f"\nPossible DTE mapping:")
			print(f"  0x{ROM_BYTES[0]:02X} might be 'For'")


def main():
	"""Main entry point"""
	analyze_dte()


if __name__ == '__main__':
	main()
