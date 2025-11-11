#!/usr/bin/env python3
"""Test DTE sequences with spaces"""

import sys
sys.path.insert(0, 'tools/map-editor')

from utils.dialog_text import CharacterTable
from pathlib import Path

# Load table
table = CharacterTable(Path('complex.tbl'))

print("=== DTE Sequences with Spaces Test ===\n")

# Test sequences that should have spaces
test_sequences = [
	(0x40, "e "),
	(0x41, "the "),
	(0x42, "t "),
	(0x45, "s "),
	(0x46, "to "),
	(0x48, "ing "),
	(0x5F, "is "),
	(0x67, "a "),
]

print("Checking byte → char mappings (decoding):")
for byte_val, expected in test_sequences:
	actual = table.byte_to_char.get(byte_val, "NOT FOUND")
	match = "✓" if actual == expected else "✗"
	print(f"  {match} 0x{byte_val:02X} → {actual!r} (expected {expected!r})")

print("\nChecking char → byte mappings (encoding):")
for byte_val, sequence in test_sequences:
	actual_byte = table.multi_char_to_byte.get(sequence, None)
	match = "✓" if actual_byte == byte_val else "✗"
	hex_str = f"0x{actual_byte:02X}" if actual_byte is not None else "NOT FOUND"
	print(f"  {match} {sequence!r} → {hex_str} (expected 0x{byte_val:02X})")

print("\nChecking common words with DTE:")
# Test encoding a sentence
test_text = "the Crystal is going to help you"
print(f"Test text: {test_text!r}")

from utils.dialog_text import DialogText
dt = DialogText(table)
encoded = dt.encode(test_text, add_end=False)
decoded = dt.decode(bytes(encoded))

print(f"Encoded: {' '.join(f'{b:02X}' for b in encoded)} ({len(encoded)} bytes)")
print(f"Decoded: {decoded!r}")
print(f"Match: {'✓' if decoded == test_text else '✗'}")
