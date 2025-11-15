#!/usr/bin/env python3
"""Apply batch 3 of high-frequency battle RAM labels."""

import re
from pathlib import Path

# Batch 3: Next 29 labels (11-7 uses each, skipping 3 without defined labels)
LABELS = {
	'19a5': 'battle_state_flag',  # 11 uses
	'19f7': 'anim_loop_counter',  # 11 uses
	'19d3': 'current_direction',  # 11 uses
	'19d5': 'target_direction',  # 11 uses
	'1933': 'battle_counter',  # 11 uses
	'1973': 'sprite_loop_counter',  # 11 uses
	'1979': 'sprite_frame_value',  # 10 uses
	'194d': 'battle_array_elem_11',  # 10 uses
	'1931': 'battle_delta_accum',  # 10 uses
	'19e2': 'battle_gfx_pointer',  # 10 uses
	'1940': 'battle_array_elem_1',  # 10 uses
	'19ac': 'battle_turn_counter',  # 10 uses
	'195f': 'battle_target_select',  # 10 uses
	'194a': 'battle_array_elem_10',  # 10 uses
	'1948': 'battle_temp_data',  # 9 uses
	'193a': 'battle_array_data_1',  # 9 uses
	'1a24': 'buffer_size_ref',  # 9 uses
	'19c9': 'battle_entity_state',  # 9 uses
	'19f0': 'battle_current_enemy',  # 9 uses
	'19f3': 'battle_array_elem_6',  # 9 uses (different from $1945)
	'192a': 'battle_phase',  # 9 uses
	'193c': 'battle_array_data_2',  # 8 uses
	'197e': 'anim_frame_index',  # 8 uses
	'19e6': 'battle_entity_data_ref',  # 8 uses
	'1951': 'battle_init_flag',  # 8 uses
	'19d1': 'coordinate_register',  # 8 uses
	'1a85': 'battle_unit_coord_lo',  # 8 uses
	'19d0': 'movement_flags',  # 8 uses
	'1902': 'battle_actor0_y',  # 8 uses
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
			pattern = rf'\.(?:w|W) \${addr}(?!\w)'
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
