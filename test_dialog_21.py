#!/usr/bin/env python3
"""Test dialog 0x21 decoding"""

import sys
sys.path.insert(0, 'tools/map-editor')

from utils.dialog_database import DialogDatabase
from pathlib import Path

db = DialogDatabase(Path('roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc'))
db.extract_all_dialogs()

# Test dialog 0x16 which should have "s beautiful as ever!"
dialog_id = 0x16  # Dialog 22
entry = db.dialogs.get(dialog_id)

if entry:
	print(f"Dialog 0x{dialog_id:02X} ({dialog_id}):")
	print(f"Raw bytes: {' '.join(f'{b:02X}' for b in entry.raw_bytes)}")
	print(f"Text: {entry.text!r}")
	print(f"\nExpected: Something with 's beautiful as ever!'")

	# Decode specific bytes manually
	from utils.dialog_text import CharacterTable, DialogText
	table = CharacterTable(Path('complex.tbl'))
	dt = DialogText(table)

	# Specific sequence: should be "s beautiful as ever!"
	# Let's decode the bytes
	decoded_manual = dt.decode(bytes(entry.raw_bytes))
	print(f"\nManual decode: {decoded_manual!r}")
else:
	print(f"Dialog 0x{dialog_id:02X} not found")
