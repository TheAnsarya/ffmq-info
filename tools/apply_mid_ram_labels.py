#!/usr/bin/env python3
"""Apply batch 6 - mid-range RAM labels ($0500-$0Exx)."""

import re
from pathlib import Path

# Batch 6: Mid-range system RAM (player, tilemap, audio)
LABELS = {
	'0e89': 'player_map_x',  # 51 uses (primary label, not tilemap_index alias)
	'0e8b': 'player_facing',  # 35 uses (primary, not battle_type alias)
	'0e91': 'tilemap_counter',  # 29 uses (primary, not battle_map_id alias)
	'0505': 'audio_coord_register',  # 27 uses
	'050a': 'audio_hw_register_1',  # 16 uses
	'0e9c': 'menu_color',  # 14 uses
	'0e00': 'ram_0e00',  # 31 uses (check if label exists)
	'0c00': 'ram_0c00',  # 65 uses (check if label exists)
	'0c02': 'ram_0c02',  # 33 uses
	'0c01': 'ram_0c01',  # 31 uses
	'0a00': 'ram_0a00',  # 28 uses
	'0c0a': 'ram_0c0a',  # 21 uses
	'0c0e': 'ram_0c0e',  # 21 uses
	'0c06': 'ram_0c06',  # 19 uses
	'0c03': 'ram_0c03',  # 17 uses
	'0b00': 'ram_0b00',  # 16 uses
	'0ab2': 'ram_0ab2',  # 14 uses
}

def main():
	repo_root = Path(r'c:\Users\me\source\repos\ffmq-info')
	asm_dir = repo_root / 'src' / 'asm'
	inc_file = repo_root / 'src' / 'include' / 'ffmq_ram_variables.inc'
	
	# Check which labels actually exist
	inc_content = inc_file.read_text(encoding='utf-8')
	existing_labels = {}
	for addr, label in LABELS.items():
		if f'= ${addr}' in inc_content:
			existing_labels[addr] = label
			print(f"✓ ${addr} -> {label}")
		else:
			print(f"✗ ${addr} -> {label} (SKIP - no label defined)")
	
	# Apply only existing labels
	files = list(asm_dir.rglob('*.asm'))
	total_replacements = 0
	files_modified = 0
	
	for asm_file in files:
		content = asm_file.read_text(encoding='utf-8')
		original = content
		file_replacements = 0
		
		for addr, label in existing_labels.items():
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
