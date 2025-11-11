#!/usr/bin/env python3
"""Debug character table loading"""

import sys
sys.path.insert(0, 'tools/map-editor')

from utils.dialog_text import CharacterTable
from pathlib import Path

# Load table
table = CharacterTable(Path('complex.tbl'))

print(f"Table loaded: {table.loaded}")
print(f"byte_to_char entries: {len(table.byte_to_char)}")
print(f"char_to_byte entries: {len(table.char_to_byte)}")
print(f"multi_char_to_byte entries: {len(table.multi_char_to_byte)}")

# Check specific mappings
print("\nChecking specific mappings:")
print(f"  'H' → {table.char_to_byte.get('H', 'NOT FOUND')}")
print(f"  'e' → {table.char_to_byte.get('e', 'NOT FOUND')}")
print(f"  'l' → {table.char_to_byte.get('l', 'NOT FOUND')}")
print(f"  'the ' → {table.multi_char_to_byte.get('the ', 'NOT FOUND')}")
print(f"  'you' → {table.multi_char_to_byte.get('you', 'NOT FOUND')}")

# Check duplicates
you_bytes = []
for byte, char in table.byte_to_char.items():
    if char == "you":
        you_bytes.append(f"0x{byte:02X}")

print(f"\nBytes that decode to 'you': {', '.join(you_bytes)}")
