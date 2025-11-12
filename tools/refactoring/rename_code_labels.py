#!/usr/bin/env python3
"""
Automated CODE_* label renaming tool.

Uses existing section comments to rename CODE_* labels intelligently.
"""

import re
import os
import json
from pathlib import Path
from typing import Dict, List, Tuple, Optional

class LabelRenamer:
	"""Renames CODE_* labels using context."""
	
	def __init__(self, src_dir: str = "src/asm"):
		self.src_dir = Path(src_dir)
		self.rename_map: Dict[str, str] = {}
		self.stats = {
			'total_labels': 0,
			'renamed': 0,
			'loop_labels': 0,
			'branch_targets': 0,
			'functions': 0
		}
	
	def analyze_and_rename_file(self, filepath: Path) -> int:
		"""Analyze a file and build rename map."""
		try:
			with open(filepath, 'r', encoding='utf-8') as f:
				lines = f.readlines()
		except Exception as e:
			print(f"Error reading {filepath}: {e}")
			return 0
		
		renames = 0
		current_function = None
		
		for i, line in enumerate(lines):
			# Check for function/section header
			section_match = re.match(r'^;\s*={5,}\s*$', line)
			if section_match and i + 1 < len(lines):
				# Next line might have function name
				next_line = lines[i + 1].strip()
				func_match = re.match(r'^;\s*CODE_([0-9A-F]+):\s*(.+)$', next_line)
				if func_match:
					addr = func_match.group(1)
					func_name = func_match.group(2).strip()
					# Clean up function name
					func_name = self.clean_function_name(func_name)
					current_function = func_name
			
			# Check for CODE_* label
			label_match = re.match(r'^(CODE_([0-9A-F]+)):', line)
			if label_match:
				old_label = label_match.group(1)
				addr = label_match.group(2)
				self.stats['total_labels'] += 1
				
				# Determine new name based on context
				new_name = None
				
				# Check previous lines for section comment with name
				# Pattern: ; CODE_XXXXXX: Function Name
				context_start = max(0, i - 15)
				for j in range(i - 1, context_start - 1, -1):
					prev_line = lines[j].strip()
					
					# Look for the specific pattern
					section_match = re.match(r'^;\s*CODE_[0-9A-F]+:\s*(.+)$', prev_line)
					if section_match:
						func_desc = section_match.group(1).strip()
						new_name = self.clean_function_name(func_desc)
						self.stats['functions'] += 1
						break
					
					# Stop if we hit another CODE label
					if prev_line.startswith('CODE_') and prev_line.endswith(':'):
						break
				
				# If no section comment found, try other methods
				if not new_name:
					# Check next few lines to determine role
					next_lines = lines[i+1:min(i+6, len(lines))]
					role = self.determine_label_role(next_lines)
					
					if role == 'loop':
						if current_function:
							new_name = f"{current_function}_Loop_{addr}"
						else:
							new_name = f"Loop_{addr}"
						self.stats['loop_labels'] += 1
					elif role == 'branch':
						if current_function:
							new_name = f"{current_function}_Branch_{addr}"
						else:
							new_name = f"Branch_{addr}"
						self.stats['branch_targets'] += 1
					elif role == 'return':
						if current_function:
							new_name = f"{current_function}_Return_{addr}"
						else:
							new_name = f"Return_{addr}"
					elif role == 'exit':
						if current_function:
							new_name = f"{current_function}_Exit_{addr}"
						else:
							new_name = f"Exit_{addr}"
				
				# Last resort: generic descriptive name
				if not new_name:
					next_lines = lines[i+1:min(i+6, len(lines))]
					role = self.determine_label_role(next_lines)
					if role:
						new_name = f"{role.title()}_{addr}"
					else:
						new_name = f"Label_{addr}"
				
				# Store rename
				if new_name and new_name != old_label:
					self.rename_map[old_label] = new_name
					renames += 1
					self.stats['renamed'] += 1
		
		return renames
	
	def clean_function_name(self, name: str) -> str:
		"""Clean up function name for use as label."""
		# Remove extra whitespace
		name = ' '.join(name.split())
		
		# Convert to valid identifier
		name = re.sub(r'[^\w\s-]', '', name)
		name = re.sub(r'[\s-]+', '_', name)
		
		# Remove common prefixes/suffixes
		name = re.sub(r'^(Function|Routine|Subroutine|Handler)_', '', name, flags=re.IGNORECASE)
		name = re.sub(r'_(Function|Routine|Subroutine|Handler)$', '', name, flags=re.IGNORECASE)
		
		# Capitalize properly
		parts = name.split('_')
		parts = [p.capitalize() if p.islower() else p for p in parts]
		name = '_'.join(parts)
		
		return name
	
	def extract_name_from_comment(self, comment: str) -> Optional[str]:
		"""Extract a usable name from a comment line."""
		# Common patterns
		patterns = [
			r'^([A-Z][a-zA-Z]+(?:\s+[A-Z][a-zA-Z]+){0,3})',  # Title Case phrase
			r'^(Loop|Wait|Check|Init|Load|Save|Clear|Exit|Transfer|Send|Receive)',  # Action words
		]
		
		for pattern in patterns:
			match = re.search(pattern, comment)
			if match:
				name = match.group(1)
				name = re.sub(r'\s+', '_', name)
				return name
		
		return None
	
	def determine_label_role(self, next_lines: List[str]) -> Optional[str]:
		"""Determine the role of a label based on following code."""
		if not next_lines:
			return None
		
		# Get actual code lines (skip comments)
		code_lines = []
		for line in next_lines:
			stripped = line.strip()
			if stripped and not stripped.startswith(';'):
				# Extract opcode
				op_match = re.match(r'^\s*([a-z]+\.?[wlb]?)\s', stripped, re.IGNORECASE)
				if op_match:
					code_lines.append(op_match.group(1).lower())
		
		if not code_lines:
			return None
		
		first_op = code_lines[0]
		
		# Return/Exit
		if first_op in ['rts', 'rtl', 'rti']:
			return 'return'
		
		# Loop patterns
		if first_op in ['dex', 'dey', 'dec', 'inx', 'iny', 'inc']:
			# Check if followed by a branch back
			if len(code_lines) > 1 and code_lines[1] in ['bne', 'beq', 'bpl', 'bmi', 'bcc', 'bcs']:
				return 'loop'
		
		# Compare then branch (conditional)
		if first_op in ['cmp', 'cpx', 'cpy', 'bit']:
			return 'check'
		
		# Branch target
		if first_op.startswith('b') and first_op not in ['bit', 'brk']:
			return 'branch'
		
		# Load/Store operations
		if first_op.startswith('ld'):
			return 'load'
		if first_op.startswith('st'):
			return 'store'
		
		return None
	
	def apply_renames(self, dry_run: bool = False) -> int:
		"""Apply all renames to files."""
		if not self.rename_map:
			print("No renames to apply!")
			return 0
		
		if dry_run:
			print("=== DRY RUN - No files will be modified ===\n")
		
		files_modified = 0
		
		for asm_file in self.src_dir.rglob("*.asm"):
			if self.apply_renames_to_file(asm_file, dry_run):
				files_modified += 1
		
		return files_modified
	
	def apply_renames_to_file(self, filepath: Path, dry_run: bool) -> bool:
		"""Apply renames to a single file."""
		try:
			with open(filepath, 'r', encoding='utf-8') as f:
				content = f.read()
		except Exception as e:
			print(f"Error reading {filepath}: {e}")
			return False
		
		original_content = content
		changes = 0
		
		# Apply each rename
		for old_name, new_name in self.rename_map.items():
			# Count occurrences before
			old_count = len(re.findall(rf'\b{re.escape(old_name)}\b', content))
			
			if old_count > 0:
				# Replace label definition
				content = re.sub(
					rf'^{re.escape(old_name)}:',
					f'{new_name}:',
					content,
					flags=re.MULTILINE
				)
				
				# Replace all references (whole word)
				content = re.sub(
					rf'\b{re.escape(old_name)}\b',
					new_name,
					content
				)
				
				changes += old_count
		
		if changes > 0:
			if dry_run:
				print(f"Would modify {filepath}: {changes} replacements")
			else:
				try:
					with open(filepath, 'w', encoding='utf-8') as f:
						f.write(content)
					print(f"✓ Modified {filepath}: {changes} replacements")
				except Exception as e:
					print(f"Error writing {filepath}: {e}")
					return False
			return True
		
		return False
	
	def save_rename_map(self, filename: str):
		"""Save the rename map to a JSON file."""
		with open(filename, 'w', encoding='utf-8') as f:
			json.dump({
				'stats': self.stats,
				'renames': self.rename_map
			}, f, indent=2)
		print(f"\nRename map saved to: {filename}")


def main():
	"""Main entry point."""
	import sys
	
	renamer = LabelRenamer()
	
	print("Analyzing assembly files...")
	print("=" * 80)
	
	# Analyze all files
	for asm_file in sorted(renamer.src_dir.rglob("*.asm")):
		renames = renamer.analyze_and_rename_file(asm_file)
		if renames > 0:
			print(f"  {asm_file.name}: {renames} labels to rename")
	
	print("\n" + "=" * 80)
	print("Analysis complete!\n")
	print(f"Total labels found:     {renamer.stats['total_labels']}")
	print(f"Labels to rename:       {renamer.stats['renamed']}")
	print(f"  - Functions:          {renamer.stats['functions']}")
	print(f"  - Loop labels:        {renamer.stats['loop_labels']}")
	print(f"  - Branch targets:     {renamer.stats['branch_targets']}")
	print("=" * 80)
	
	# Save rename map
	os.makedirs("reports", exist_ok=True)
	renamer.save_rename_map("reports/label_renames.json")
	
	# Show sample
	print("\nSample renames:")
	print("-" * 80)
	count = 0
	for old, new in sorted(renamer.rename_map.items()):
		if count >= 30:
			print(f"... and {len(renamer.rename_map) - 30} more")
			break
		print(f"  {old:20} -> {new}")
		count += 1
	
	# Ask to apply
	print("\n" + "=" * 80)
	if '--apply' in sys.argv:
		print("Applying renames...")
		files_modified = renamer.apply_renames(dry_run=False)
		print(f"\n✓ Modified {files_modified} files")
	elif '--dry-run' in sys.argv:
		renamer.apply_renames(dry_run=True)
	else:
		print("Run with --apply to apply changes, or --dry-run to preview")


if __name__ == '__main__':
	main()
