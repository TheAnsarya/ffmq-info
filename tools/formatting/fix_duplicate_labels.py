#!/usr/bin/env python3
"""
Fix Duplicate Label Names

Converts duplicate label names to local labels (+ or -) or unique names
to fix assembly errors.

Usage:
	python tools/fix_duplicate_labels.py [--dry-run]
"""

import re
import sys
from pathlib import Path
from collections import defaultdict

def fix_duplicate_labels(filepath, dry_run=False):
	"""Fix duplicate label names in an ASM file"""
	with open(filepath, 'r', encoding='utf-8') as f:
		lines = f.readlines()
	
	# Track label usage
	label_lines = defaultdict(list)
	
	# First pass: find all labels
	for i, line in enumerate(lines):
		# Match label definitions (word at start of line followed by colon)
		match = re.match(r'^([A-Za-z_][A-Za-z0-9_]*):', line)
		if match:
			label = match.group(1)
			label_lines[label].append(i)
	
	# Find duplicates
	duplicates = {label: line_nums for label, line_nums in label_lines.items() 
				  if len(line_nums) > 1}
	
	if not duplicates:
		print(f"  No duplicate labels found in {filepath.name}")
		return lines, 0
	
	print(f"\n  Found {len(duplicates)} duplicate labels:")
	changes = 0
	
	for label, line_nums in sorted(duplicates.items()):
		print(f"    {label}: {len(line_nums)} occurrences at lines {line_nums[:5]}...")
		
		# Strategy: For simple labels like RTS_Label, PHP_Label, etc., make them local
		# by converting to anonymous labels
		if label in ['RTS_Label', 'PHP_Label', 'PLP_Label', 'RTL_Label', 
					 'SEC_Label', 'CLC_Label', 'SEI_Label', 'CLI_Label',
					 'NOP_Label', 'BRK_Label']:
			# Replace with anonymous local label
			for line_num in line_nums:
				old_line = lines[line_num]
				# Just remove the label - the instruction speaks for itself
				new_line = re.sub(r'^' + label + ':', '', old_line)
				if new_line != old_line:
					lines[line_num] = new_line
					changes += 1
		else:
			# For other labels, make them unique with suffix
			for idx, line_num in enumerate(line_nums[1:], start=1):  # Skip first occurrence
				old_line = lines[line_num]
				new_label = f"{label}_{idx}"
				new_line = old_line.replace(f"{label}:", f"{new_label}:")
				if new_line != old_line:
					lines[line_num] = new_line
					changes += 1
					print(f"      Line {line_num}: {label} → {new_label}")
	
	if not dry_run and changes > 0:
		with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
			f.writelines(lines)
		print(f"\n  ✓ Fixed {changes} duplicate labels in {filepath.name}")
	elif dry_run:
		print(f"\n  [DRY RUN] Would fix {changes} duplicate labels")
	
	return lines, changes

def main():
	dry_run = '--dry-run' in sys.argv
	
	# Find all ASM files
	asm_dir = Path('src/asm')
	asm_files = sorted(asm_dir.glob('bank_*_documented.asm'))
	
	if not asm_files:
		print("No ASM files found!")
		return 1
	
	print(f"Fixing duplicate labels in {len(asm_files)} files...")
	if dry_run:
		print("[DRY RUN MODE - No changes will be made]")
	
	total_changes = 0
	for filepath in asm_files:
		_, changes = fix_duplicate_labels(filepath, dry_run)
		total_changes += changes
	
	print(f"\n{'[DRY RUN] Would make' if dry_run else 'Made'} {total_changes} total changes")
	return 0

if __name__ == '__main__':
	sys.exit(main())
