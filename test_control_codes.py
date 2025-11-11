#!/usr/bin/env python3
"""Test control code tag encoding"""

import sys
sys.path.insert(0, 'tools/map-editor')

from utils.dialog_text import DialogText, CharacterTable
from pathlib import Path

# Load table
table = CharacterTable(Path('complex.tbl'))
dialog_text = DialogText(table)

print("=== Control Code Encoding Test ===\n")

# Test control code encoding
test_cases = [
    ("Hello[PARA]World", "Text with [PARA]"),
    ("Look[PAGE]Next page", "Text with [PAGE]"),
    ("[CRYSTAL]The Crystal", "Text with [CRYSTAL]"),
    ("Text[P1A]more text", "Text with [P1A]"),
    ("[END]", "Just [END]"),
    ("Normal text", "No control codes"),
]

for text, description in test_cases:
    print(f"Test: {description}")
    print(f"  Input: {text!r}")

    # Encode
    encoded = dialog_text.encode(text, add_end=True)
    print(f"  Encoded: {' '.join(f'{b:02X}' for b in encoded)}")

    # Decode
    decoded = dialog_text.decode(encoded, include_end=True)
    print(f"  Decoded: {decoded!r}")

    # Check round-trip (compare without [END] for clarity)
    original_clean = text.replace('[END]', '')
    decoded_clean = decoded.replace('[END]', '')

    if original_clean == decoded_clean:
        print(f"  ✓ Round-trip successful")
    else:
        print(f"  ✗ Round-trip failed!")
        print(f"    Expected: {original_clean!r}")
        print(f"    Got: {decoded_clean!r}")

    print()

# Test specific control code bytes
print("\nControl code byte mappings:")
test_codes = [
    "[PARA]", "[PAGE]", "[CRYSTAL]", "[P1A]", "[CLEAR]",
    "[WAIT]", "[NAME]", "[ITEM]", "[END]"
]

for tag in test_codes:
    encoded = dialog_text.encode(tag, add_end=False)
    if len(encoded) == 1:
        print(f"  {tag:12} → 0x{encoded[0]:02X}")
    else:
        print(f"  {tag:12} → {' '.join(f'{b:02X}' for b in encoded)} (unexpected length)")
