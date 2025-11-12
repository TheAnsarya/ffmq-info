#!/usr/bin/env python3
"""
Verify DTE table mappings against known dialog text in ROM
Tests complex.tbl DTE entries by decoding known dialogs and checking for readable output

Uses known dialog 0x59 ("For years Mac's been studying...") as test case
"""

import sys
from pathlib import Path

# Add tools to path
sys.path.insert(0, str(Path(__file__).parent / 'tools' / 'map-editor'))
from utils.dialog_database import DialogDatabase
from utils.dialog_text import CharacterTable, DialogText

def main():
	rom_path = Path('roms') / 'Final Fantasy - Mystic Quest (U) (V1.1).sfc'
	
	if not rom_path.exists():
		print(f"ERROR: ROM not found at {rom_path}")
		return 1
	
	print("=" * 70)
	print("DTE Table Verification")
	print("=" * 70)
	
	# Load complex character table
	table_path = Path('complex.tbl')
	char_table = CharacterTable(table_path, use_complex=True)
	dialog_text = DialogText(char_table)
	
	print(f"\n✓ Loaded {table_path}")
	print(f"  - Single characters: {len(char_table.char_to_byte)}")
	print(f"  - DTE sequences: {len(char_table.multi_char_to_byte)}")
	print(f"  - Control codes: {len([k for k in char_table.byte_to_char if isinstance(k, int) and k < 0x3D])}")
	
	# Extract dialogs
	db = DialogDatabase(rom_path)
	db.extract_all_dialogs()
	
	print(f"\n✓ Extracted {len(db.dialogs)} dialogs from ROM")
	
	# Test known dialogs
	test_cases = [
		(0x00, "First dialog"),
		(0x21, "Common dialog"),
		(0x59, "Opening: 'For years Mac's been studying a Prophecy...'"),
	]
	
	print("\n" + "=" * 70)
	print("Testing Known Dialogs")
	print("=" * 70)
	
	for dialog_id, description in test_cases:
		print(f"\nDialog 0x{dialog_id:02X}: {description}")
		print("-" * 70)
		
		if dialog_id in db.dialogs:
			entry = db.dialogs[dialog_id]
			print(f"Address: ${entry.address:06X}")
			print(f"Length:  {entry.length} bytes")
			print(f"\nDecoded text:")
			print(entry.text[:200])  # First 200 chars
			if len(entry.text) > 200:
				print("...")
		else:
			print(f"  ERROR: Dialog 0x{dialog_id:02X} not found!")
	
	# Analyze DTE usage
	print("\n" + "=" * 70)
	print("DTE Usage Analysis")
	print("=" * 70)
	
	dte_count = {}
	total_chars = 0
	total_dte = 0
	
	for dialog_id, entry in sorted(db.dialogs.items()):
		if not entry or not entry.text:
			continue
		
		total_chars += len(entry.text)
		
		# Count DTE sequences in decoded text
		for dte_seq in char_table.multi_char_to_byte.keys():
			count = entry.text.count(dte_seq)
			if count > 0:
				if dte_seq not in dte_count:
					dte_count[dte_seq] = 0
				dte_count[dte_seq] += count
				total_dte += count
	
	print(f"\nTotal characters decoded: {total_chars}")
	print(f"Total DTE sequences found: {total_dte}")
	
	if dte_count:
		print(f"\nTop 20 DTE sequences by frequency:")
		sorted_dte = sorted(dte_count.items(), key=lambda x: x[1], reverse=True)
		for i, (seq, count) in enumerate(sorted_dte[:20], 1):
			# Find byte value
			byte_val = char_table.multi_char_to_byte.get(seq, None)
			if byte_val is not None:
				print(f"  {i:2d}. 0x{byte_val:02X} = {seq!r:15s} ({count:3d} times)")
			else:
				print(f"  {i:2d}. ???? = {seq!r:15s} ({count:3d} times)")
	
	# Check for garbled output (control codes in main text)
	print("\n" + "=" * 70)
	print("Text Quality Check")
	print("=" * 70)
	
	garbled_dialogs = []
	for dialog_id, entry in sorted(db.dialogs.items()):
		if not entry or not entry.text:
			continue
		
		# Count control code tags in output
		control_tags = entry.text.count('[')
		text_without_tags = entry.text.replace('[', '').replace(']', '')
		
		# If more than 50% control codes, likely garbled
		if len(text_without_tags) > 0:
			tag_ratio = control_tags / len(text_without_tags)
			if tag_ratio > 0.3:  # More than 30% control codes
				garbled_dialogs.append((dialog_id, tag_ratio, entry.text[:50]))
	
	if garbled_dialogs:
		print(f"\n⚠️  Found {len(garbled_dialogs)} potentially garbled dialogs:")
		for dialog_id, ratio, sample in garbled_dialogs[:10]:
			print(f"  Dialog 0x{dialog_id:02X}: {ratio*100:.1f}% control codes")
			print(f"    Sample: {sample}...")
	else:
		print("\n✓ No heavily garbled dialogs detected")
	
	print("\n" + "=" * 70)
	print("Verification Complete")
	print("=" * 70)
	
	return 0

if __name__ == '__main__':
	sys.exit(main())
