#!/usr/bin/env python3
"""Test character table loading"""

# Load character table
char_map = {}
with open('complex_reference.tbl', 'r', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if not line or '=' not in line:
            continue
        byte_str, char_str = line.split('=', 1)
        byte_val = int(byte_str, 16)
        char_map[byte_val] = char_str

print(f'Loaded {len(char_map)} character mappings')
print(f'0x40 (should be "e "): {repr(char_map.get(0x40, "NOT FOUND"))}')
print(f'0x41 (should be "the "): {repr(char_map.get(0x41, "NOT FOUND"))}')
print(f'0xB4 (should be "a"): {repr(char_map.get(0xB4, "NOT FOUND"))}')
print(f'0xC7 (should be "t"): {repr(char_map.get(0xC7, "NOT FOUND"))}')
print(f'0xFF (should be " "): {repr(char_map.get(0xFF, "NOT FOUND"))}')
