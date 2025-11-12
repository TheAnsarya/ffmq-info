#!/usr/bin/env python3
"""Debug dialog extraction"""

import sys
sys.path.insert(0, 'tools/extraction')
from extract_all_dialogs import DialogExtractor

e = DialogExtractor('roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc', 'complex_reference.tbl')

print('Checking byte mappings:')
print(f'0x82 in char_table: {0x82 in e.char_table} = {repr(e.char_table.get(0x82, "NOT IN TABLE"))}')
print(f'0xA1 in char_table: {0xA1 in e.char_table} = {repr(e.char_table.get(0xA1, "NOT IN TABLE"))}')
print(f'0x40 in dictionary: {0x40 in e.dictionary}')
print(f'0xFF in char_table: {0xFF in e.char_table} = {repr(e.char_table.get(0xFF, "NOT IN TABLE"))}')

print('\nFirst 10 dictionary entries (decoded):')
for i in range(0x30, 0x3A):
    decoded = e.dictionary.get(i, 'NOT DECODED')
    if decoded != 'NOT DECODED':
        display = repr(decoded[:50]) if len(decoded) > 50 else repr(decoded)
        print(f'0x{i:02X}: {display}')

print('\nDialog 0 raw bytes:')
rom = e.rom
ptr = rom[0x01B835] | (rom[0x01B836] << 8)
addr = 0x018000 + (ptr - 0x8000)
bytes_data = rom[addr:addr+20]
print(' '.join(f'{b:02X}' for b in bytes_data))

print('\nManual decode of first few bytes:')
for i, b in enumerate(bytes_data[:10]):
    if b in e.char_table:
        print(f'  {b:02X}: char_table[{b:02X}] = {repr(e.char_table[b])}')
    elif b in e.dictionary:
        print(f'  {b:02X}: dictionary[{b:02X}] = {repr(e.dictionary[b][:20])}...')
    else:
        print(f'  {b:02X}: NOT FOUND')
