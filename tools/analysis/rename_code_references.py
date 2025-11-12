#!/usr/bin/env python3
"""
Smart CODE_* reference updater.
Reads comments next to CODE_* references and renames them based on the comment text.
"""

import re
from pathlib import Path
from collections import defaultdict
from typing import Dict, List, Tuple, Set

def read_file(filepath: Path) -> List[str]:
	"""Read file into lines."""
	with open(filepath, 'r', encoding='utf-8') as f:
		return f.readlines()

def write_file(filepath: Path, lines: List[str]):
	"""Write lines to file."""
	with open(filepath, 'w', encoding='utf-8') as f:
		f.writelines(lines)

def extract_meaningful_name(comment: str) -> str:
	"""Convert a comment to a meaningful PascalCase label."""
	# Remove address references
	comment = re.sub(r';[0-9A-F]{6}\|[0-9A-F ]+\|[0-9A-F]{6}', '', comment)
	comment = re.sub(r'[0-9A-F]{6}', '', comment)
	comment = comment.strip().strip(';').strip()
	
	if not comment or len(comment) < 3:
		return None
	
	# Extract words
	words = re.findall(r'[a-zA-Z][a-zA-Z0-9]*', comment)
	if not words:
		return None
	
	# Skip generic words
	skip_words = {'the', 'a', 'an', 'and', 'or', 'but', 'for', 'to', 'from', 'in', 'on', 'at', 'by', 'with'}
	words = [w for w in words if w.lower() not in skip_words]
	
	if not words:
		return None
	
	# Limit to 6 words for reasonable label length
	words = words[:6]
	
	# Convert to PascalCase
	return ''.join(word.capitalize() for word in words)

def main():
	src_dir = Path(__file__).parent.parent.parent / 'src' / 'asm'
	
	print("="*80)
	print("SMART CODE_* REFERENCE RENAMING")
	print("="*80)
	
	# Step 1: Find all CODE_* references with their comments
	print("\n[1/4] Scanning for CODE_* references...")
	
	label_info = defaultdict(list)  # CODE_* -> [(filepath, line_num, line_text, comment), ...]
	
	asm_files = sorted(src_dir.rglob('*.asm'))
	
	for asm_file in asm_files:
		try:
			lines = read_file(asm_file)
			for i, line in enumerate(lines):
				# Find CODE_* in line
				for match in re.finditer(r'\b(CODE_[0-9A-Fa-f]+)\b', line, re.IGNORECASE):
					code_label = match.group(1).upper()
					
					# Extract comment if present
					comment = ''
					if ';' in line:
						comment = line.split(';', 1)[1].strip()
					
					label_info[code_label].append((asm_file, i, line, comment))
		except Exception as e:
			print(f"  Error reading {asm_file.name}: {e}")
	
	print(f"  Found {len(label_info)} unique CODE_* labels")
	print(f"  Total references: {sum(len(refs) for refs in label_info.values())}")
	
	# Step 2: Suggest names based on comments
	print("\n[2/4] Analyzing comments and suggesting names...")
	
	rename_map = {}  # CODE_* -> new_name
	used_names = set()
	
	for code_label in sorted(label_info.keys()):
		refs = label_info[code_label]
		
		# Try to find a comment with meaningful text
		best_name = None
		best_comment = None
		
		for filepath, line_num, line_text, comment in refs:
			if comment:
				name = extract_meaningful_name(comment)
				if name and name not in used_names:
					best_name = name
					best_comment = comment
					break
		
		# If no unique name from comments, generate from address
		if not best_name:
			# Try again allowing duplicates, we'll add numbers
			for filepath, line_num, line_text, comment in refs:
				if comment:
					name = extract_meaningful_name(comment)
					if name:
						base_name = name
						counter = 2
						while name in used_names:
							name = f"{base_name}{counter}"
							counter += 1
						best_name = name
						best_comment = comment
						break
		
		# Last resort: use address-based name
		if not best_name:
			best_name = f"Sub_{code_label[5:]}"  # Remove CODE_ prefix
			best_comment = "No comment available"
		
		rename_map[code_label] = best_name
		used_names.add(best_name)
	
	# Display samples
	print(f"\n  Sample renames:")
	for i, (code_label, new_name) in enumerate(sorted(rename_map.items())[:20]):
		refs = label_info[code_label]
		example_comment = next((c for f, l, t, c in refs if c), "")
		print(f"    {code_label} -> {new_name}")
		if example_comment:
			example_short = example_comment[:60] + "..." if len(example_comment) > 60 else example_comment
			print(f"      From: {example_short}")
	
	if len(rename_map) > 20:
		print(f"    ... and {len(rename_map) - 20} more")
	
	# Step 3: Apply renames
	print("\n[3/4] Applying renames...")
	
	files_modified = 0
	total_replacements = 0
	
	for asm_file in asm_files:
		try:
			lines = read_file(asm_file)
			modified = False
			
			for i, line in enumerate(lines):
				original_line = line
				
				# Replace each CODE_* reference
				for code_label, new_name in rename_map.items():
					# Use word boundary to avoid partial matches
					pattern = re.compile(r'\b' + re.escape(code_label) + r'\b', re.IGNORECASE)
					line = pattern.sub(new_name, line)
				
				if line != original_line:
					lines[i] = line
					modified = True
					total_replacements += 1
			
			if modified:
				write_file(asm_file, lines)
				files_modified += 1
				print(f"  Modified: {asm_file.relative_to(src_dir)}")
		except Exception as e:
			print(f"  Error processing {asm_file.name}: {e}")
	
	print(f"\n  Modified {files_modified} files")
	print(f"  Made {total_replacements} line replacements")
	
	# Step 4: Save report
	print("\n[4/4] Saving report...")
	
	report_file = Path(__file__).parent.parent.parent / 'reports' / 'code_reference_renames.txt'
	report_file.parent.mkdir(parents=True, exist_ok=True)
	
	with open(report_file, 'w', encoding='utf-8') as f:
		f.write("CODE_* REFERENCE RENAME REPORT\n")
		f.write("="*80 + "\n\n")
		f.write(f"Total labels renamed: {len(rename_map)}\n")
		f.write(f"Files modified: {files_modified}\n")
		f.write(f"Total line replacements: {total_replacements}\n\n")
		
		f.write("="*80 + "\n")
		f.write("RENAME MAPPINGS\n")
		f.write("="*80 + "\n\n")
		
		for code_label, new_name in sorted(rename_map.items()):
			refs = label_info[code_label]
			f.write(f"{code_label} -> {new_name}\n")
			f.write(f"  References: {len(refs)}\n")
			
			# Show a sample comment
			for filepath, line_num, line_text, comment in refs:
				if comment:
					f.write(f"  Comment: {comment}\n")
					break
			
			# List files where it appears
			files = list(set(str(fp.relative_to(src_dir)) for fp, _, _, _ in refs))
			f.write(f"  Files: {', '.join(files[:5])}")
			if len(files) > 5:
				f.write(f" ... and {len(files) - 5} more")
			f.write("\n\n")
	
	print(f"  Report saved to: {report_file}")
	
	print("\n" + "="*80)
	print("RENAMING COMPLETE!")
	print("="*80)
	print(f"\n✓ Renamed {len(rename_map)} CODE_* labels")
	print(f"✓ Modified {files_modified} files")
	print(f"✓ Made {total_replacements} replacements")
	print(f"\nNext: Review report and verify assembly still builds correctly")

if __name__ == '__main__':
	main()
