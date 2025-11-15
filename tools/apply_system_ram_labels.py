#!/usr/bin/env python3
"""Apply batch 5 - system RAM labels ($00xx-$04xx range)."""

import re
from pathlib import Path

# Batch 5: High-frequency system RAM variables
LABELS = {
	'00d2': 'system_flags_1',  # 27 uses
	'00d4': 'system_flags_2',  # 37 uses
	'00d6': 'system_flags_3',  # 20 uses
	'00d8': 'system_flags_4',  # 24 uses
	'00da': 'system_flags_5',  # 34 uses
	'00db': 'system_flags_6',  # 21 uses
	'0111': 'system_interrupt_flags',  # 40 uses
	'0110': 'battle_ready_flag',  # 25 uses
	'00f0': 'state_marker',  # 18 uses
}

def main():
	repo_root = Path(r'c:\Users\me\source\repos\ffmq-info')
	asm_dir = repo_root / 'src' / 'asm'
	
	files = list(asm_dir.rglob('*.asm'))
	total_replacements = 0
	files_modified = 0
	
	for asm_file in files:
		content = asm_file.read_text(encoding='utf-8')
		original = content
		file_replacements = 0
		
		for addr, label in LABELS.items():
			pattern = rf'\.(?:w|W|b|B) \${addr}(?!\w)'
			replacement = f'.w !{label}'
			count = len(re.findall(pattern, content))
			if count > 0:
				content = re.sub(pattern, replacement, content)
				file_replacements += count
		
		if content != original:
			asm_file.write_text(content, encoding='utf-8', newline='\r\n')
			total_replacements += file_replacements
			files_modified += 1
			print(f"{asm_file.name}: {file_replacements} replacements")
	
	print(f"\nTotal: {total_replacements} labels applied across {files_modified} files")

if __name__ == '__main__':
	main()
