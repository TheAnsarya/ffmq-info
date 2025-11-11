#!/usr/bin/env python3
"""Test dialog editing"""

import sys
import shutil
from pathlib import Path

sys.path.insert(0, 'tools/map-editor')

from utils.dialog_database import DialogDatabase

# Make a backup ROM for testing
rom_path = Path("roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc")
test_rom = Path("roms/test_edit.sfc")

print("Creating test ROM...")
shutil.copy(rom_path, test_rom)

# Load database
print("Loading ROM...")
db = DialogDatabase(test_rom)
db.extract_all_dialogs()

# Pick a simple dialog to edit
dialog_id = 0x21  # "Look over there. That's the[CRYSTAL]..."

print(f"\nTesting dialog edit for ID 0x{dialog_id:04X}")
dialog = db.dialogs[dialog_id]

print("\nOriginal dialog:")
print("-" * 70)
print(dialog.text)
print("-" * 70)
print(f"Length: {dialog.length} bytes")

# Create new text (shorter, should fit in place)
new_text = "Testing[PARA]New dialog text!"

print("\nNew text:")
print("-" * 70)
print(new_text)
print("-" * 70)

# Encode and check size
encoded = db.dialog_text.encode(new_text)
print(f"Encoded to {len(encoded)} bytes")

# Validate
is_valid, messages = db.dialog_text.validate(new_text)
print(f"\nValidation: {'✓ Valid' if is_valid else '✗ Invalid'}")
for msg in messages:
	print(f"  {msg}")

if not is_valid:
	print("\nStopping - validation failed")
	sys.exit(1)

# Update dialog
print("\nUpdating dialog...")
success = db.update_dialog(dialog_id, new_text)

if not success:
	print("✗ Update failed")
	sys.exit(1)

print("✓ Update successful")

# Save ROM
print("\nSaving ROM...")
if db.save_rom(test_rom):
	print(f"✓ Saved to {test_rom}")
else:
	print("✗ Save failed")
	sys.exit(1)

# Verify by re-reading
print("\nVerifying changes...")
db2 = DialogDatabase(test_rom)
db2.extract_all_dialogs()

dialog_after = db2.dialogs[dialog_id]
print("\nDialog after reload:")
print("-" * 70)
print(dialog_after.text)
print("-" * 70)

if dialog_after.text.replace('[END]', '') == new_text.replace('[END]', ''):
	print("\n✓ Verification successful - dialog updated correctly!")
else:
	print("\n✗ Verification failed - text doesn't match")
	print(f"Expected: {new_text}")
	print(f"Got: {dialog_after.text}")
	sys.exit(1)

# Cleanup
print(f"\nTest complete. Test ROM: {test_rom}")
print("You can compare with original or delete test ROM.")
