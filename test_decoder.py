#!/usr/bin/env python3
"""
Test FFMQ dialog decoder with Dialog 0x16
"""

import sys
from pathlib import Path

# Add parent directories to path
sys.path.insert(0, str(Path(__file__).parent))
sys.path.insert(0, str(Path(__file__).parent / 'tools' / 'map-editor'))

from utils.dialog_database import DialogDatabase

def test_dialog_16():
	"""Test decoding of Dialog 0x16: 'The prophecy will be fulfilled.'"""

	# ROM path
	rom_path = Path("roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc")

	if not rom_path.exists():
		print(f"ERROR: ROM not found at {rom_path}")
		return False

	print("=== Testing Dialog 0x16 Decoder ===\n")
	print(f"ROM: {rom_path}")
	print()

	# Load database and extract dialogs
	db = DialogDatabase(rom_path)
	db.extract_all_dialogs()

	# Get Dialog 0x16
	dialog_id = 0x16
	if dialog_id not in db.dialogs:
		print(f"ERROR: Dialog 0x{dialog_id:02X} not found in database")
		print(f"Available dialogs: {sorted(db.dialogs.keys())[:20]}...")
		return False

	dialog = db.dialogs[dialog_id]

	print(f"Dialog ID:    0x{dialog_id:02X}")
	print(f"Pointer:      0x{dialog.pointer:04X}")
	print(f"Address (PC): 0x{dialog.address:06X}")
	print(f"Length:       {dialog.length} bytes")
	print()
	print("Raw bytes:")
	print("  " + " ".join(f"{b:02X}" for b in dialog.raw_bytes[:32]))
	if len(dialog.raw_bytes) > 32:
		print(f"  ... ({len(dialog.raw_bytes)} bytes total)")
	print()
	print("Expected text:")
	print('  "The prophecy will be fulfilled."')
	print()
	print("Decoded text:")
	print(f'  "{dialog.text}"')
	print()

	# Verify correctness
	expected = "The prophecy will be fulfilled."
	# Remove control codes for comparison
	decoded_clean = dialog.text.replace('[END]', '').replace('\n', ' ').strip()

	if expected in decoded_clean or decoded_clean in expected:
		print("✓ SUCCESS: Dialog decoded correctly!")
		return True
	else:
		print("✗ FAILED: Dialog decoding mismatch")
		print(f"  Expected: '{expected}'")
		print(f"  Got:      '{decoded_clean}'")
		return False

if __name__ == '__main__':
	success = test_dialog_16()
	sys.exit(0 if success else 1)
