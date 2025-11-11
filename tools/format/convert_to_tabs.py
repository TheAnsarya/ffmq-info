#!/usr/bin/env python3
"""
Convert Python files from spaces to tabs per .editorconfig
"""

import sys
from pathlib import Path
from typing import List, Tuple


def convert_file(file_path: Path, spaces_per_tab: int = 4, dry_run: bool = False) -> Tuple[bool, str]:
	"""
	Convert indentation from spaces to tabs.
	
	Args:
		file_path: Path to the Python file
		spaces_per_tab: Number of spaces to convert to one tab (default: 4)
		dry_run: If True, don't write changes, just report them
		
	Returns:
		Tuple of (changed, message)
	"""
	try:
		with open(file_path, 'r', encoding='utf-8') as f:
			original_lines = f.readlines()
	except Exception as e:
		return (False, f"Error reading: {e}")
	
	converted_lines = []
	changed = False
	
	for line_num, line in enumerate(original_lines, 1):
		# Only process lines that start with spaces
		if not line or line[0] != ' ':
			converted_lines.append(line)
			continue
		
		# Count leading spaces
		indent = 0
		for char in line:
			if char == ' ':
				indent += 1
			elif char == '\t':
				# Already has tabs, skip this line
				converted_lines.append(line)
				break
			else:
				# Found non-whitespace
				break
		else:
			# Empty line with only spaces
			converted_lines.append(line)
			continue
		
		if indent > 0:
			# Convert spaces to tabs
			tabs = indent // spaces_per_tab
			remainder = indent % spaces_per_tab
			
			if tabs > 0:
				# Build new line with tabs
				new_line = ('\t' * tabs) + (' ' * remainder) + line[indent:]
				converted_lines.append(new_line)
				
				if new_line != line:
					changed = True
			else:
				# Less than one tab worth of spaces, keep as-is
				converted_lines.append(line)
		else:
			converted_lines.append(line)
	
	if changed and not dry_run:
		try:
			with open(file_path, 'w', encoding='utf-8') as f:
				f.writelines(converted_lines)
			return (True, "Converted")
		except Exception as e:
			return (False, f"Error writing: {e}")
	
	return (changed, "Would convert" if dry_run and changed else "No changes")


def find_python_files(root_dir: Path, exclude_dirs: List[str] | None = None) -> List[Path]:
	"""
	Find all Python files in the directory tree.
	
	Args:
		root_dir: Root directory to search
		exclude_dirs: Directories to exclude (default: venv, .git, node_modules, __pycache__)
		
	Returns:
		List of Path objects for Python files
	"""
	if exclude_dirs is None:
		exclude_dirs = ['venv', '.venv', 'env', '.env', '.git', 'node_modules', '__pycache__', 'build', 'dist']
	
	python_files = []
	
	for py_file in root_dir.rglob('*.py'):
		# Check if file is in excluded directory
		excluded = False
		for exclude_dir in exclude_dirs:
			if exclude_dir in py_file.parts:
				excluded = True
				break
		
		if not excluded:
			python_files.append(py_file)
	
	return sorted(python_files)


def main():
	"""Main entry point"""
	import argparse
	
	parser = argparse.ArgumentParser(
		description='Convert Python files from spaces to tabs per .editorconfig'
	)
	parser.add_argument(
		'path',
		nargs='?',
		default='.',
		help='Directory or file to convert (default: current directory)'
	)
	parser.add_argument(
		'--spaces-per-tab',
		type=int,
		default=4,
		help='Number of spaces per tab (default: 4)'
	)
	parser.add_argument(
		'--dry-run',
		action='store_true',
		help='Show what would be changed without modifying files'
	)
	parser.add_argument(
		'--verbose',
		action='store_true',
		help='Show all files processed, not just changed files'
	)
	
	args = parser.parse_args()
	
	path = Path(args.path)
	
	if not path.exists():
		print(f"Error: Path '{path}' does not exist", file=sys.stderr)
		sys.exit(1)
	
	# Find Python files
	if path.is_file():
		if path.suffix == '.py':
			python_files = [path]
		else:
			print(f"Error: '{path}' is not a Python file", file=sys.stderr)
			sys.exit(1)
	else:
		python_files = find_python_files(path)
	
	if not python_files:
		print("No Python files found")
		return
	
	print(f"Found {len(python_files)} Python file(s)")
	
	if args.dry_run:
		print("DRY RUN MODE - No files will be modified\n")
	
	# Convert files
	changed_count = 0
	error_count = 0
	
	for py_file in python_files:
		changed, message = convert_file(py_file, args.spaces_per_tab, args.dry_run)
		
		if changed:
			changed_count += 1
			print(f"[CONVERT] {py_file}: {message}")
		elif "Error" in message:
			error_count += 1
			print(f"[ERROR] {py_file}: {message}")
		elif args.verbose:
			print(f"[OK] {py_file}: {message}")
	
	# Summary
	print(f"\n{'=' * 60}")
	print(f"Total files processed: {len(python_files)}")
	print(f"Files {'that would be ' if args.dry_run else ''}changed: {changed_count}")
	
	if error_count > 0:
		print(f"Errors: {error_count}")
	
	if args.dry_run and changed_count > 0:
		print("\nRun without --dry-run to apply changes")
	
	if error_count > 0:
		sys.exit(1)


if __name__ == '__main__':
	main()
