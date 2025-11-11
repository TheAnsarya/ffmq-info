#!/usr/bin/env python3
"""
Test FFMQ dialog encoding (writing text back to bytes)
"""

import sys
from pathlib import Path

# Add parent directories to path
sys.path.insert(0, str(Path(__file__).parent))
sys.path.insert(0, str(Path(__file__).parent / 'tools' / 'map-editor'))

from utils.dialog_text import DialogText, CharacterTable

def test_encoding():
    """Test encoding text to bytes"""

    print("=== FFMQ Dialog Encoding Test ===\n")

    # Initialize
    char_table = CharacterTable()
    dialog_text = DialogText(char_table)

    # Test cases
    test_cases = [
        ("Hello", "Simple word"),
        ("The prophecy will be fulfilled.", "DTE sequences"),
        ("Look over there.", "Common phrase"),
        ("you will save the World.", "Multiple DTE"),
    ]

    print("Testing encode/decode round-trip:\n")

    for text, description in test_cases:
        print(f"Test: {description}")
        print(f"  Original text: '{text}'")

        # Encode
        encoded_bytes = dialog_text.encode(text, add_end=True)
        print(f"  Encoded bytes: {' '.join(f'{b:02X}' for b in encoded_bytes)}")
        print(f"  Byte count: {len(encoded_bytes)}")

        # Decode back
        decoded_text = dialog_text.decode(encoded_bytes, include_end=False)
        # Clean up for comparison
        decoded_clean = decoded_text.replace('[END]', '').strip()

        # Compare
        if decoded_clean == text:
            print(f"  ✓ Round-trip successful!")
        else:
            print(f"  ✗ Round-trip FAILED!")
            print(f"    Decoded: '{decoded_clean}'")

        print()

    # Test specific DTE sequences
    print("\nTesting DTE compression:\n")

    dte_tests = [
        ("the", 0x41, "the (no space)"),
        ("prophecy", 0x71, "prophecy"),
        ("you", 0x44, "you"),
        ("Crystal", 0x3D, "Crystal"),
    ]

    for text, expected_byte, description in dte_tests:
        encoded = dialog_text.encode(text, add_end=False)

        if len(encoded) == 1 and encoded[0] == expected_byte:
            print(f"✓ '{text}' → 0x{encoded[0]:02X} ({description})")
        elif len(encoded) == 1:
            print(f"✗ '{text}' → 0x{encoded[0]:02X} (expected 0x{expected_byte:02X})")
        else:
            print(f"✗ '{text}' → {' '.join(f'{b:02X}' for b in encoded)} (expected single byte 0x{expected_byte:02X})")

    # Test compression efficiency
    print("\n\nCompression efficiency:\n")

    long_text = "The prophecy says that you will save the World. Look over there."

    # Encode with DTE
    encoded_dte = dialog_text.encode(long_text, add_end=False)

    # Calculate what it would be without DTE (all individual chars)
    char_count = len([c for c in long_text if c != '[' and c != ']'])

    print(f"Text: '{long_text}'")
    print(f"  Character count: {char_count}")
    print(f"  Encoded bytes (with DTE): {len(encoded_dte)}")
    print(f"  Compression ratio: {len(encoded_dte) / char_count * 100:.1f}%")
    print(f"  Space saved: {char_count - len(encoded_dte)} bytes")

    return True

if __name__ == '__main__':
    success = test_encoding()
    sys.exit(0 if success else 1)
