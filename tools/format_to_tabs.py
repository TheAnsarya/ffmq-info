#!/usr/bin/env python3
"""
Format Python files to use tabs instead of spaces
Converts indentation to tabs and ensures CRLF line endings
"""

import sys
from pathlib import Path


def convert_spaces_to_tabs(file_path: Path, tab_width: int = 4) -> bool:
	"""
	Convert spaces to tabs in a Python file
	
	Args:
		file_path: Path to the Python file
		tab_width: Number of spaces per tab (default 4)
		
	Returns:
		True if file was modified, False otherwise
	"""
	try:
		# Read file with UTF-8 encoding
		with open(file_path, 'r', encoding='utf-8') as f:
			lines = f.readlines()
		
		modified = False
		new_lines = []
		
		for line in lines:
			# Calculate leading spaces
			original = line
			stripped = line.lstrip(' ')
			leading_spaces = len(line) - len(stripped)
			
			if leading_spaces > 0:
				# Convert leading spaces to tabs
				num_tabs = leading_spaces // tab_width
				remaining_spaces = leading_spaces % tab_width
				new_line = '\t' * num_tabs + ' ' * remaining_spaces + stripped
				
				if new_line != original:
					modified = True
				new_lines.append(new_line)
			else:
				new_lines.append(line)
		
		if modified:
			# Write back with CRLF line endings
			with open(file_path, 'w', encoding='utf-8', newline='\r\n') as f:
				for line in new_lines:
					# Strip any existing line endings and add CRLF
					f.write(line.rstrip('\r\n') + '\r\n')
			
			print(f"✓ Formatted: {file_path}")
			return True
		else:
			print(f"  Skipped (already formatted): {file_path}")
			return False
			
	except Exception as e:
		print(f"✗ Error processing {file_path}: {e}")
		return False


def format_directory(directory: Path, pattern: str = '**/*.py') -> tuple[int, int]:
	"""
	Format all Python files in a directory
	
	Args:
		directory: Root directory to search
		pattern: Glob pattern for files to format
		
	Returns:
		Tuple of (files_modified, files_processed)
	"""
	files_modified = 0
	files_processed = 0
	
	for file_path in directory.glob(pattern):
		if file_path.is_file():
			files_processed += 1
			if convert_spaces_to_tabs(file_path):
				files_modified += 1
	
	return files_modified, files_processed


if __name__ == '__main__':
	if len(sys.argv) > 1:
		target = Path(sys.argv[1])
	else:
		# Default to map-editor directory
		target = Path(__file__).parent / 'map-editor'
	
	if not target.exists():
		print(f"Error: Path does not exist: {target}")
		sys.exit(1)
	
	print(f"Formatting Python files in: {target}")
	print("Converting spaces → tabs, LF → CRLF, ensuring UTF-8...")
	print()
	
	modified, processed = format_directory(target)
	
	print()
	print(f"Processed: {processed} files")
	print(f"Modified:  {modified} files")
	print(f"Unchanged: {processed - modified} files")
