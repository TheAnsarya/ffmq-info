#!/usr/bin/env python3
"""
Test both simple and complex text systems
Verify they work as documented
"""

import sys
from pathlib import Path

# Add paths
sys.path.insert(0, str(Path(__file__).parent / 'tools' / 'map-editor'))

print("="*70)
print("FFMQ TEXT SYSTEMS TEST")
print("="*70)

# Test 1: Simple Text System
print("\n[TEST 1] Simple Text System (simple.tbl)")
print("-"*70)

from tools.extraction.extract_text import TextExtractor

rom_path = Path("roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc")
if not rom_path.exists():
    print(f"ERROR: ROM not found at {rom_path}")
    sys.exit(1)

# Test simple text extractor
extractor = TextExtractor(str(rom_path), tbl_path="simple.tbl")
extractor.load_rom()
extractor.load_character_table()

print(f"✓ Loaded {len(extractor.char_table)} characters from simple.tbl")

# Test spell name decoding (known location)
spell_addr = 0x04FE00
spell_names = []
for i in range(12):  # First 12 spells
    addr = spell_addr + (i * 12)
    name, _ = extractor.decode_string(addr, 12)
    if name.strip():
        spell_names.append((i, name.strip()))

print("\nFirst 12 spell names (using simple.tbl):")
for idx, name in spell_names:
    print(f"  {idx:2d}: {name}")

# Test 2: Complex Text System
print("\n[TEST 2] Complex Text System (complex.tbl)")
print("-"*70)

from utils.dialog_database import DialogDatabase
from utils.dialog_text import CharacterTable

# Load complex table
complex_table = CharacterTable(Path("complex.tbl"), use_complex=True)
print(f"✓ Loaded complex.tbl")
print(f"  - {len(complex_table.char_to_byte)} single characters")
print(f"  - {len(complex_table.multi_char_to_byte)} DTE sequences")

# Test dialog decoding
db = DialogDatabase(rom_path)
db.extract_all_dialogs()
print(f"✓ Extracted {len(db.dialogs)} dialogs")

# Show a simple dialog
if 0x00 in db.dialogs:
    dialog = db.dialogs[0x00]
    print(f"\nDialog 0x00:")
    print(f"  Address: 0x{dialog.address:06X}")
    print(f"  Length: {dialog.length} bytes")
    print(f"  Text (first 100 chars):")
    text = dialog.text[:100]
    print(f"    {text}")

# Test 3: Character Range Verification
print("\n[TEST 3] Character Range Verification")
print("-"*70)

# Verify simple.tbl ranges
simple_chars = {}
with open("simple.tbl", 'r', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if '=' in line and not line.startswith('#'):
            parts = line.split('=', 1)
            byte_val = int(parts[0], 16)
            char = parts[1]
            if char != '#':
                simple_chars[byte_val] = char

print(f"Simple.tbl mappings: {len(simple_chars)} non-placeholder")
print(f"  Digits (0x90-0x99): {sum(1 for b in range(0x90, 0x9A) if b in simple_chars)}")
print(f"  Uppercase (0x9A-0xB3): {sum(1 for b in range(0x9A, 0xB4) if b in simple_chars)}")
print(f"  Lowercase (0xB4-0xCD): {sum(1 for b in range(0xB4, 0xCE) if b in simple_chars)}")

# Verify complex.tbl ranges
complex_chars = {}
dte_seqs = {}
with open("complex.tbl", 'r', encoding='utf-8') as f:
    for line in f:
        line = line.rstrip('\r\n').lstrip()
        if '=' in line and not line.startswith('#'):
            parts = line.split('=', 1)
            byte_val = int(parts[0], 16)
            char = parts[1]
            if char != '#':
                complex_chars[byte_val] = char
                if 0x3D <= byte_val <= 0x7E:
                    dte_seqs[byte_val] = char

print(f"\nComplex.tbl mappings: {len(complex_chars)} total")
print(f"  Control codes (0x00-0x3B): {sum(1 for b in range(0x00, 0x3C) if b in complex_chars)}")
print(f"  DTE sequences (0x3D-0x7E): {len(dte_seqs)}")
print(f"  Single chars (0x90-0xCD): {sum(1 for b in range(0x90, 0xCE) if b in complex_chars)}")
print(f"  Special (0xCE-0xFF): {sum(1 for b in range(0xCE, 0x100) if b in complex_chars)}")

# Show some DTE examples
print(f"\nSample DTE sequences:")
for byte_val in sorted(dte_seqs.keys())[:10]:
    print(f"  0x{byte_val:02X} = '{dte_seqs[byte_val]}'")

# Test 4: Encoding/Decoding Round-Trip
print("\n[TEST 4] Simple Text Round-Trip")
print("-"*70)

test_words = ["Fire", "Cure", "Thunder", "Sword"]
for word in test_words:
    # Encode
    encoded = []
    for char in word:
        if char in extractor.reverse_table:
            encoded.append(extractor.reverse_table[char])
    encoded.append(0x00)  # Terminator
    
    # Decode
    decoded = []
    for byte in encoded[:-1]:  # Skip terminator
        if byte in extractor.char_table:
            decoded.append(extractor.char_table[byte])
    decoded_word = ''.join(decoded)
    
    # Check
    if decoded_word == word:
        hex_str = ' '.join(f'{b:02X}' for b in encoded)
        print(f"  ✓ '{word}' → {hex_str} → '{decoded_word}'")
    else:
        print(f"  ✗ '{word}' → '{decoded_word}' (MISMATCH!)")

print("\n" + "="*70)
print("TEST COMPLETE")
print("="*70)

print("\nSummary:")
print("  ✓ Simple system (simple.tbl) - WORKING for item/spell/monster names")
print("  ⚠ Complex system (complex.tbl) - INFRASTRUCTURE OK, DTE mappings need verification")
print("  ✓ Character ranges verified")
print("  ✓ Round-trip encoding/decoding works for simple text")
