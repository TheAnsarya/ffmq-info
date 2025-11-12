#!/usr/bin/env python3
"""
Round-trip test for simple text import/export
Tests that we can: extract → edit → import → extract again and get the same result

Usage:
	python tools/import/test_roundtrip.py <rom_path>
"""

import sys
import csv
import tempfile
from pathlib import Path
from typing import List, Dict

sys.path.insert(0, str(Path(__file__).parent.parent))
from extraction.extract_simple_text import SimpleTextExtractor
from import_simple_text import SimpleTextImporter


def run_roundtrip_test(rom_path: Path) -> bool:
	"""
	Test round-trip: extract → modify → import → extract → verify
	
	Args:
		rom_path: Path to ROM file
	
	Returns:
		True if test passes
	"""
	print("\n" + "=" * 70)
	print("FFMQ Round-Trip Test")
	print("=" * 70)
	
	with tempfile.TemporaryDirectory() as tmpdir:
		tmpdir = Path(tmpdir)
		
		# Step 1: Extract original text
		print("\n[1] Extracting original text...")
		extractor = SimpleTextExtractor(rom_path)
		all_text = extractor.extract_all()
		extractor.save_csv(all_text, tmpdir)
		
		original_csv = tmpdir / 'spell_names.csv'
		if not original_csv.exists():
			print("ERROR: Failed to extract spell_names.csv")
			return False
		
		# Load original data
		with open(original_csv, 'r', encoding='utf-8') as f:
			reader = csv.DictReader(f)
			original_data = list(reader)
		
		print(f"  ✓ Extracted {len(original_data)} spell names")
		
		# Step 2: Create modified CSV
		print("\n[2] Creating modified text...")
		modified_csv = tmpdir / 'spell_names_modified.csv'
		modified_data = []
		
		for row in original_data[:5]:  # Modify first 5 entries
			modified_row = row.copy()
			# Add a suffix (but keep within length limit)
			text = row['Text']
			max_len = int(row['Length']) - 1  # Reserve space for terminator
			suffix = "_X"
			if len(text) + len(suffix) <= max_len:
				modified_row['Text'] = text + suffix
			modified_data.append(modified_row)
		
		# Keep rest unchanged
		modified_data.extend(original_data[5:])
		
		# Write modified CSV
		with open(modified_csv, 'w', encoding='utf-8', newline='') as f:
			writer = csv.DictWriter(f, fieldnames=original_data[0].keys())
			writer.writeheader()
			writer.writerows(modified_data)
		
		print(f"  ✓ Modified first 5 entries")
		for i in range(5):
			print(f"	{original_data[i]['Text']} → {modified_data[i]['Text']}")
		
		# Step 3: Import to temporary ROM copy
		print("\n[3] Importing modified text to ROM...")
		temp_rom = tmpdir / 'test_rom.sfc'
		import shutil
		shutil.copy2(rom_path, temp_rom)
		
		importer = SimpleTextImporter(temp_rom, dry_run=False, create_backup=False)
		if not importer.load_rom():
			print("ERROR: Failed to load ROM")
			return False
		
		if not importer.import_csv(modified_csv):
			print("ERROR: Failed to import CSV")
			return False
		
		if not importer.save_rom():
			print("ERROR: Failed to save ROM")
			return False
		
		print(f"  ✓ Imported {importer.changes_made} changes")
		
		# Step 4: Extract from modified ROM
		print("\n[4] Extracting from modified ROM...")
		extractor2 = SimpleTextExtractor(temp_rom)
		all_text2 = extractor2.extract_all()
		extractor2.save_csv(all_text2, tmpdir / 'extracted')
		
		reimported_csv = tmpdir / 'extracted' / 'spell_names.csv'
		if not reimported_csv.exists():
			print("ERROR: Failed to re-extract spell_names.csv")
			return False
		
		# Load re-extracted data
		with open(reimported_csv, 'r', encoding='utf-8') as f:
			reader = csv.DictReader(f)
			reimported_data = list(reader)
		
		print(f"  ✓ Re-extracted {len(reimported_data)} spell names")
		
		# Step 5: Verify round-trip
		print("\n[5] Verifying round-trip...")
		errors = []
		
		for i, (orig, reimported) in enumerate(zip(modified_data, reimported_data)):
			if orig['Text'] != reimported['Text']:
				errors.append(f"  Entry {i}: '{orig['Text']}' != '{reimported['Text']}'")
		
		if errors:
			print(f"  ❌ FAILED: {len(errors)} mismatches:")
			for error in errors[:10]:
				print(error)
			return False
		
		print("  ✓ All entries match!")
		
		# Verify modifications were applied
		for i in range(5):
			expected = original_data[i]['Text'] + "_X"
			actual = reimported_data[i]['Text']
			if expected != actual:
				print(f"  ❌ FAILED: Modification not applied to entry {i}")
				print(f"	Expected: {expected}")
				print(f"	Actual: {actual}")
				return False
		
		print("  ✓ All modifications preserved!")
	
	print("\n" + "=" * 70)
	print("✅ ROUND-TRIP TEST PASSED")
	print("=" * 70)
	return True


def main():
	import argparse
	
	parser = argparse.ArgumentParser(description='Test simple text round-trip')
	parser.add_argument('rom', type=Path, help='ROM file path')
	
	args = parser.parse_args()
	
	if not args.rom.exists():
		print(f"ERROR: ROM not found: {args.rom}")
		return 1
	
	if run_roundtrip_test(args.rom):
		return 0
	else:
		return 1


if __name__ == '__main__':
	sys.exit(main())
