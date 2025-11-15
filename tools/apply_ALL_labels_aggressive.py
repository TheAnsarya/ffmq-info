#!/usr/bin/env python3
"""
AGGRESSIVE: Extract ALL labels from include file and apply them across codebase.
This will maximize token usage by doing mass replacements.
"""

import re
from pathlib import Path

def extract_all_labels(inc_file):
	"""Extract all !label = $address definitions from include file."""
	content = inc_file.read_text(encoding='utf-8')
	# Pattern: !label_name = $address
	pattern = r'^!(\w+)\s*=\s*\$([0-9a-fA-F]{4})'
	labels = {}
	
	for match in re.finditer(pattern, content, re.MULTILINE):
		label_name = match.group(1)
		address = match.group(2).lower()
		
		# Skip aliases (multiple labels for same address) - keep only first
		if address not in labels:
			labels[address] = label_name
	
	return labels

def main():
	repo_root = Path(r'c:\Users\me\source\repos\ffmq-info')
	asm_dir = repo_root / 'src' / 'asm'
	inc_file = repo_root / 'src' / 'include' / 'ffmq_ram_variables.inc'
	
	print("Extracting ALL labels from include file...")
	all_labels = extract_all_labels(inc_file)
	print(f"Found {len(all_labels)} unique address labels")
	
	# Apply to all ASM files
	files = list(asm_dir.rglob('*.asm'))
	total_replacements = 0
	files_modified = 0
	
	for asm_file in files:
		content = asm_file.read_text(encoding='utf-8')
		original = content
		file_replacements = 0
		
		for addr, label in all_labels.items():
			# Match .w/.W/.b/.B $address (not followed by more hex digits)
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
	
	print(f"\n✓ TOTAL: {total_replacements} labels applied across {files_modified} files")
	print(f"✓ {len(all_labels)} unique labels available")

if __name__ == '__main__':
	main()
