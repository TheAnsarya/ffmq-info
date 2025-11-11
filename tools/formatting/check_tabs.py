#!/usr/bin/env python3
"""
Check Python files for tabs vs spaces consistency

Verifies that Python files use tabs (not spaces) for indentation.
This is a quick check script for CI or local validation.

Usage:
	python tools/formatting/check_tabs.py [path]

Examples:
	# Check current directory
	python tools/formatting/check_tabs.py
	
	# Check specific directory
	python tools/formatting/check_tabs.py tools/
	
	# Check single file
	python tools/formatting/check_tabs.py tools/text/decoder.py

Exit codes:
	0: All files use tabs
	1: Some files use spaces
"""

import sys
from pathlib import Path
from typing import List, Tuple


def check_file_tabs(file_path: Path) -> Tuple[bool, int]:
	"""
	Check if file uses tabs for indentation
	
	Args:
		file_path: Path to Python file
	
	Returns:
		(uses_tabs, lines_with_spaces)
	"""
	try:
		with open(file_path, 'r', encoding='utf-8') as f:
			lines = f.readlines()
	except Exception as e:
		print(f"  ⚠️  Error reading {file_path}: {e}")
		return True, 0  # Skip this file
	
	lines_with_spaces = 0
	
	for line_num, line in enumerate(lines, start=1):
		# Skip empty lines and lines without indentation
		if not line or line[0] not in (' ', '\t'):
			continue
		
		# Check for leading spaces (4+ spaces likely indentation)
		if line.startswith('    '):
			lines_with_spaces += 1
	
	uses_tabs = lines_with_spaces == 0
	return uses_tabs, lines_with_spaces


def check_directory_tabs(dir_path: Path, recursive: bool = True) -> List[Tuple[Path, int]]:
	"""
	Check all Python files in directory
	
	Args:
		dir_path: Directory path
		recursive: Recurse into subdirectories
	
	Returns:
		List of (file_path, lines_with_spaces) for files with issues
	"""
	# Find Python files
	if recursive:
		py_files = list(dir_path.rglob('*.py'))
	else:
		py_files = list(dir_path.glob('*.py'))
	
	issues = []
	
	for py_file in py_files:
		uses_tabs, lines_with_spaces = check_file_tabs(py_file)
		if not uses_tabs:
			issues.append((py_file, lines_with_spaces))
	
	return issues


def main():
	import argparse
	
	parser = argparse.ArgumentParser(
		description='Check Python files for tabs vs spaces',
		epilog='Returns exit code 0 if all files use tabs, 1 otherwise'
	)
	parser.add_argument('path', type=Path, nargs='?', default=Path('.'),
		help='File or directory to check (default: current directory)')
	
	args = parser.parse_args()
	
	print("\n" + "=" * 70)
	print("Python Tab Formatting Check")
	print("=" * 70)
	print()
	
	# Check path
	issues = []
	
	if args.path.is_file():
		uses_tabs, lines_with_spaces = check_file_tabs(args.path)
		if not uses_tabs:
			issues.append((args.path, lines_with_spaces))
	elif args.path.is_dir():
		issues = check_directory_tabs(args.path, recursive=True)
	else:
		print(f"ERROR: Path not found: {args.path}")
		return 1
	
	# Report
	if issues:
		print(f"❌ Found {len(issues)} file(s) using spaces instead of tabs:\n")
		for file_path, lines_with_spaces in issues[:20]:  # Show first 20
			print(f"  {file_path}: {lines_with_spaces} lines with spaces")
		
		if len(issues) > 20:
			print(f"  ... and {len(issues) - 20} more files")
		
		print("\nTo fix, run:")
		print(f"  python tools/formatting/convert_spaces_to_tabs.py {args.path}")
		print("\n" + "=" * 70)
		return 1
	else:
		print("✅ All files use tabs for indentation")
		print("\n" + "=" * 70)
		return 0


if __name__ == '__main__':
	sys.exit(main())
