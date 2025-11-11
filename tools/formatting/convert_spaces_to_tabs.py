#!/usr/bin/env python3
"""
Convert spaces to tabs in Python files

Converts leading spaces to tabs while preserving:
- String literals (no modification)
- Multi-line strings
- Comments (indentation converted)
- Mixed indentation (spaces→tabs for leading whitespace only)

Usage:
	python tools/formatting/convert_spaces_to_tabs.py [path] [options]

Examples:
	# Convert single file
	python tools/formatting/convert_spaces_to_tabs.py tools/text/decoder.py
	
	# Convert directory recursively
	python tools/formatting/convert_spaces_to_tabs.py tools/
	
	# Dry run (preview changes)
	python tools/formatting/convert_spaces_to_tabs.py tools/ --dry-run
	
	# Convert with specific tab width
	python tools/formatting/convert_spaces_to_tabs.py tools/ --tab-width 4
"""

import sys
import re
from pathlib import Path
from typing import List, Tuple


class SpaceToTabConverter:
	"""Convert leading spaces to tabs in Python files"""
	
	def __init__(self, tab_width: int = 4, dry_run: bool = False):
		"""
		Initialize converter
		
		Args:
			tab_width: Number of spaces per tab (default: 4)
			dry_run: If True, don't write changes (preview only)
		"""
		self.tab_width = tab_width
		self.dry_run = dry_run
		self.files_converted = 0
		self.files_skipped = 0
		self.total_lines_changed = 0
	
	def convert_line(self, line: str) -> Tuple[str, bool]:
		"""
		Convert leading spaces to tabs in a single line
		
		Args:
			line: Line to convert
		
		Returns:
			(converted_line, was_changed)
		"""
		# Find leading whitespace
		match = re.match(r'^( +)', line)
		if not match:
			return line, False
		
		leading_spaces = match.group(1)
		rest_of_line = line[len(leading_spaces):]
		
		# Convert spaces to tabs
		num_spaces = len(leading_spaces)
		num_tabs = num_spaces // self.tab_width
		remaining_spaces = num_spaces % self.tab_width
		
		new_leading = '\t' * num_tabs + ' ' * remaining_spaces
		new_line = new_leading + rest_of_line
		
		changed = new_leading != leading_spaces
		return new_line, changed
	
	def convert_file(self, file_path: Path) -> bool:
		"""
		Convert a single file
		
		Args:
			file_path: Path to file
		
		Returns:
			True if file was modified
		"""
		if not file_path.exists():
			print(f"  ⚠️  File not found: {file_path}")
			return False
		
		# Read file
		try:
			with open(file_path, 'r', encoding='utf-8') as f:
				lines = f.readlines()
		except Exception as e:
			print(f"  ⚠️  Error reading {file_path}: {e}")
			return False
		
		# Convert lines
		new_lines = []
		lines_changed = 0
		in_multiline_string = False
		multiline_delimiter = None
		
		for line in lines:
			# Track multiline strings
			if '"""' in line or "'''" in line:
				if not in_multiline_string:
					# Starting multiline string
					if '"""' in line:
						multiline_delimiter = '"""'
					else:
						multiline_delimiter = "'''"
					in_multiline_string = True
				elif multiline_delimiter in line:
					# Ending multiline string
					in_multiline_string = False
					multiline_delimiter = None
			
			# Convert if not in multiline string
			if in_multiline_string:
				new_lines.append(line)
			else:
				new_line, changed = self.convert_line(line)
				new_lines.append(new_line)
				if changed:
					lines_changed += 1
		
		# Write if changes were made
		if lines_changed > 0:
			if self.dry_run:
				print(f"  ✏️  Would convert {lines_changed} lines in {file_path.name}")
			else:
				try:
					with open(file_path, 'w', encoding='utf-8') as f:
						f.writelines(new_lines)
					print(f"  ✓ Converted {lines_changed} lines in {file_path.name}")
				except Exception as e:
					print(f"  ⚠️  Error writing {file_path}: {e}")
					return False
			
			self.total_lines_changed += lines_changed
			return True
		
		return False
	
	def convert_directory(self, dir_path: Path, recursive: bool = True) -> None:
		"""
		Convert all Python files in directory
		
		Args:
			dir_path: Directory path
			recursive: If True, recurse into subdirectories
		"""
		if not dir_path.is_dir():
			print(f"ERROR: Not a directory: {dir_path}")
			return
		
		# Find Python files
		if recursive:
			py_files = list(dir_path.rglob('*.py'))
		else:
			py_files = list(dir_path.glob('*.py'))
		
		if not py_files:
			print(f"  No Python files found in {dir_path}")
			return
		
		print(f"\nConverting {len(py_files)} files in {dir_path}...")
		
		for py_file in py_files:
			if self.convert_file(py_file):
				self.files_converted += 1
			else:
				self.files_skipped += 1
	
	def convert_path(self, path: Path) -> None:
		"""
		Convert file or directory
		
		Args:
			path: Path to file or directory
		"""
		if path.is_file():
			if self.convert_file(path):
				self.files_converted += 1
			else:
				self.files_skipped += 1
		elif path.is_dir():
			self.convert_directory(path, recursive=True)
		else:
			print(f"ERROR: Path not found: {path}")
	
	def print_summary(self) -> None:
		"""Print conversion summary"""
		print("\n" + "=" * 70)
		if self.dry_run:
			print("DRY RUN SUMMARY")
		else:
			print("CONVERSION SUMMARY")
		print("=" * 70)
		print(f"Files converted: {self.files_converted}")
		print(f"Files skipped:   {self.files_skipped}")
		print(f"Lines changed:   {self.total_lines_changed}")
		print("=" * 70)


def main():
	import argparse
	
	parser = argparse.ArgumentParser(
		description='Convert leading spaces to tabs in Python files',
		epilog='Example: python convert_spaces_to_tabs.py tools/ --dry-run'
	)
	parser.add_argument('path', type=Path, nargs='?', default=Path('.'),
		help='File or directory to convert (default: current directory)')
	parser.add_argument('--tab-width', type=int, default=4,
		help='Number of spaces per tab (default: 4)')
	parser.add_argument('--dry-run', action='store_true',
		help='Preview changes without modifying files')
	
	args = parser.parse_args()
	
	# Create converter
	converter = SpaceToTabConverter(
		tab_width=args.tab_width,
		dry_run=args.dry_run
	)
	
	# Header
	print("\n" + "=" * 70)
	print("Python Spaces → Tabs Converter")
	print("=" * 70)
	print(f"Tab width: {args.tab_width} spaces")
	if args.dry_run:
		print("Mode: DRY RUN (no changes will be written)")
	print()
	
	# Convert
	converter.convert_path(args.path)
	
	# Summary
	converter.print_summary()
	
	return 0 if converter.files_converted > 0 or args.dry_run else 1


if __name__ == '__main__':
	sys.exit(main())
