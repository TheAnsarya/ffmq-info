#!/usr/bin/env python3
"""
Quick script to convert Python files from spaces to tabs
Processes all .py files in the project
"""

import sys
from pathlib import Path
import re


def convert_file_to_tabs(file_path: Path, tab_size: int = 4) -> bool:
	"""Convert a Python file from spaces to tabs"""
	try:
		with open(file_path, 'r', encoding='utf-8') as f:
			lines = f.readlines()
		
		converted = []
		modified = False
		
		for line in lines:
			# Count leading spaces
			match = re.match(r'^( +)', line)
			if match:
				spaces = len(match.group(1))
				if spaces % tab_size == 0:  # Only convert if evenly divisible
					tabs = spaces // tab_size
					new_line = ('\t' * tabs) + line[spaces:]
					converted.append(new_line)
					if new_line != line:
						modified = True
				else:
					converted.append(line)  # Keep as-is if not evenly divisible
			else:
				converted.append(line)
		
		if modified:
			with open(file_path, 'w', encoding='utf-8') as f:
				f.writelines(converted)
			return True
		
		return False
		
	except Exception as e:
		print(f"ERROR processing {file_path}: {e}")
		return False


def main():
	"""Convert all Python files in project to tabs"""
	project_root = Path(__file__).parent
	
	# Find all Python files
	py_files = list(project_root.rglob('*.py'))
	
	print(f"Found {len(py_files)} Python files")
	print("Converting spaces to tabs...")
	
	converted_count = 0
	
	for py_file in py_files:
		# Skip virtual environments and build directories
		if any(part in py_file.parts for part in ['venv', '.venv', 'env', 'build', 'dist', '__pycache__']):
			continue
		
		if convert_file_to_tabs(py_file):
			converted_count += 1
			print(f"  ✓ {py_file.relative_to(project_root)}")
	
	print(f"\n✓ Converted {converted_count} files to tabs")
	print(f"✓ {len(py_files) - converted_count} files already using tabs or skipped")


if __name__ == '__main__':
	main()
