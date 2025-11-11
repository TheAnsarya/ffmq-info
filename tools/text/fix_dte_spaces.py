#!/usr/bin/env python3
"""
Fix complex.tbl DTE table by adding trailing spaces
Based on DataCrystal documentation of Complex Text system

DTE codes that should have trailing spaces:
- $40 = "e " (e + space)
- $41 = "the " (the + space)
- $42 = "t " (t + space)
- $45 = "s " (s + space)
- $46 = "to " (to + space)
- $48 = "ing " (ing + space)
- $5F = "is " (is + space)
- $67 = "a " (a + space)
"""

import sys
from pathlib import Path


def fix_complex_tbl():
	"""Fix complex.tbl by adding trailing spaces to DTE sequences"""
	
	tbl_path = Path('complex.tbl')
	
	if not tbl_path.exists():
		print(f"ERROR: {tbl_path} not found")
		return False
	
	# Read current file
	with open(tbl_path, 'r', encoding='utf-8') as f:
		lines = f.readlines()
	
	# DTE codes that need trailing spaces (from DataCrystal docs)
	dte_with_spaces = {
		'40': 'e ',      # e + space
		'41': 'the ',    # the + space
		'42': 't ',      # t + space
		'45': 's ',      # s + space
		'46': 'to ',     # to + space
		'48': 'ing ',    # ing + space
		'5F': 'is ',     # is + space (duplicate of 53, but with space)
		'67': 'a ',      # a + space
	}
	
	# Process lines
	fixed_lines = []
	changes_made = 0
	
	for line in lines:
		original_line = line
		
		# Check if this is a DTE entry that needs a space
		for code, text in dte_with_spaces.items():
			# Case insensitive match
			if line.strip().upper().startswith(f'{code}='):
				# Extract current value
				parts = line.split('=', 1)
				if len(parts) == 2:
					current_val = parts[1].strip()
					# Only add space if not already present
					if not current_val.endswith(' '):
						line = f"{code}={text}\n"
						if line != original_line:
							changes_made += 1
							print(f"  Fixed {code}: '{current_val}' -> '{text}'")
		
		fixed_lines.append(line)
	
	# Write back if changes were made
	if changes_made > 0:
		with open(tbl_path, 'w', encoding='utf-8') as f:
			f.writelines(fixed_lines)
		
		print(f"\n✓ Fixed {changes_made} DTE entries in {tbl_path}")
		return True
	else:
		print(f"No changes needed in {tbl_path}")
		return True


def main():
	"""Main entry point"""
	print("=" * 70)
	print("Fixing complex.tbl DTE Table")
	print("=" * 70)
	print("\nAdding trailing spaces to DTE sequences...\n")
	
	success = fix_complex_tbl()
	
	if success:
		print("\n✓ DTE table fixed successfully!")
	else:
		print("\n✗ Failed to fix DTE table")
	
	return success


if __name__ == '__main__':
	success = main()
	sys.exit(0 if success else 1)
