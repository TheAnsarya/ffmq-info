#!/usr/bin/env python3
"""Find where 0x44 and 0x55 appear in dialogs and what they decode to"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent / 'tools' / 'map-editor'))

from utils.dialog_database import DialogDatabase
from utils.dialog_text import DialogText, CharacterTable

rom_path = Path("roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc")
db = DialogDatabase(rom_path)
db.extract_all_dialogs()

char_table = CharacterTable()
dialog_text = DialogText(char_table)

print("Looking for 0x44 and 0x55 usage:\n")

# Check what these bytes map to
print(f"0x44 maps to: '{char_table.byte_to_char.get(0x44, 'UNKNOWN')}'")
print(f"0x55 maps to: '{char_table.byte_to_char.get(0x55, 'UNKNOWN')}'")
print()

# Find contexts where each appears
contexts_44 = []
contexts_55 = []

for dialog_id, dialog in db.dialogs.items():
	raw = dialog.raw_bytes
	
	# Find 0x44
	for i, byte in enumerate(raw):
		if byte == 0x44:
			# Get context (decode 5 bytes before and after)
			start = max(0, i - 5)
			end = min(len(raw), i + 6)
			chunk = raw[start:end]
			decoded = dialog_text.decode(chunk, include_end=False)
			contexts_44.append((dialog_id, i, decoded))
	
	# Find 0x55
	for i, byte in enumerate(raw):
		if byte == 0x55:
			start = max(0, i - 5)
			end = min(len(raw), i + 6)
			chunk = raw[start:end]
			decoded = dialog_text.decode(chunk, include_end=False)
			contexts_55.append((dialog_id, i, decoded))

print(f"Found 0x44 in {len(contexts_44)} locations")
print("Sample contexts for 0x44:")
for dialog_id, pos, decoded in contexts_44[:5]:
	print(f"  Dialog 0x{dialog_id:02X} pos {pos}: '{decoded}'")

print(f"\nFound 0x55 in {len(contexts_55)} locations")
print("Sample contexts for 0x55:")
for dialog_id, pos, decoded in contexts_55[:5]:
	print(f"  Dialog 0x{dialog_id:02X} pos {pos}: '{decoded}'")
