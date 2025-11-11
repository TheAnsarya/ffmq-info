#!/usr/bin/env python3
"""Check which byte code is used for 'you' in actual dialogs"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent / 'tools' / 'map-editor'))

from utils.dialog_database import DialogDatabase

rom_path = Path("roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc")
db = DialogDatabase(rom_path)
db.extract_all_dialogs()

# Find dialogs containing "you" and check their raw bytes
for dialog_id in [0x21, 0x39, 0x3E]:
    if dialog_id not in db.dialogs:
        continue

    dialog = db.dialogs[dialog_id]

    # Find "you" in text
    if 'you' in dialog.text.lower():
        print(f"\nDialog 0x{dialog_id:02X}:")
        print(f"  Text snippet: {dialog.text[:100]}")
        print(f"  Raw bytes: {' '.join(f'{b:02X}' for b in dialog.raw_bytes[:30])}")

        # Look for 0x44 or 0x55 in raw bytes
        if 0x44 in dialog.raw_bytes:
            print(f"  Contains 0x44")
        if 0x55 in dialog.raw_bytes:
            print(f"  Contains 0x55")
