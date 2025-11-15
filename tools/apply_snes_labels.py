#!/usr/bin/env python3
"""
Apply SNES hardware register labels from snes_registers.inc
"""

import re
from pathlib import Path

def extract_snes_labels(inc_file):
	"""Extract SNES hardware register labels."""
	content = inc_file.read_text(encoding='utf-8')
	# Pattern: !REGISTER = $address
	pattern = r'^!(\w+)\s*=\s*\$([0-9a-fA-F]{4})'
	labels = {}
	
	for match in re.finditer(pattern, content, re.MULTILINE):
		label_name = match.group(1)
		address = match.group(2).lower()
		labels[address] = label_name
	
	return labels

def main():
	repo_root = Path(r'c:\Users\me\source\repos\ffmq-info')
	asm_dir = repo_root / 'src' / 'asm'
	snes_inc = repo_root / 'src' / 'include' / 'snes_registers.inc'
	
	print("Extracting SNES hardware labels...")
	snes_labels = extract_snes_labels(snes_inc)
	print(f"Found {len(snes_labels)} SNES hardware register labels")
	
	# Apply to all ASM files
	files = list(asm_dir.rglob('*.asm'))
	total_replacements = 0
	files_modified = 0
	
	for asm_file in files:
		content = asm_file.read_text(encoding='utf-8')
		original = content
		file_replacements = 0
		
		for addr, label in snes_labels.items():
			# Match .w/.W/.b/.B $address
			pattern = rf'\.(?:w|W|b|B) \${addr}(?!\w)'
			replacement = f'.w !{label}'
			count = len(re.findall(pattern, content, re.IGNORECASE))
			if count > 0:
				content = re.sub(pattern, replacement, content, flags=re.IGNORECASE)
				file_replacements += count
		
		if content != original:
			asm_file.write_text(content, encoding='utf-8', newline='\r\n')
			total_replacements += file_replacements
			files_modified += 1
			print(f"{asm_file.name}: {file_replacements} replacements")
	
	print(f"\n✓ TOTAL: {total_replacements} SNES labels applied across {files_modified} files")

if __name__ == '__main__':
	main()
