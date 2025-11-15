#!/usr/bin/env python3
"""Apply next batch of high-frequency battle RAM labels."""

import re
from pathlib import Path

# Batch 2: Next 30 high-frequency labels
LABELS = {
	'1929': 'battle_anim_timer',  # 25 uses
	'19d7': 'env_state_param',  # 25 uses
	'1a46': 'battle_phase_counter',  # 24 uses
	'1977': 'anim_table_ptr',  # 23 uses
	'1937': 'battle_scene_mode',  # 23 uses
	'1943': 'battle_array_elem_4',  # 22 uses (different from $19f1)
	'192e': 'tilemap_y_offset',  # 22 uses
	'19bd': 'gfx_config_register',  # 22 uses
	'194b': 'battle_state_flag',  # 21 uses
	'1924': 'battle_coord_x_boundary',  # 20 uses
	'1938': 'battle_character_param',  # 19 uses
	'1949': 'battle_array_elem_9',  # 19 uses
	'19ea': 'battle_index_temp',  # 18 uses
	'1900': 'battle_actor0_x',  # 18 uses
	'19cf': 'movement_config',  # 17 uses
	'1936': 'battle_coord_y_processed',  # 17 uses
	'19b0': 'graphics_status',  # 16 uses
	'1a87': 'battle_unit_coord_hi',  # 16 uses
	'1947': 'battle_array_elem_8',  # 15 uses
	'1925': 'battle_coord_y_boundary',  # 15 uses
	'19e7': 'battle_state_param',  # 15 uses
	'199d': 'env_coordinates',  # 14 uses
	'1928': 'battle_render_temp',  # 14 uses
	'192c': 'battle_temp_hi',  # 13 uses
	'1945': 'battle_array_elem_6',  # 13 uses
	'1975': 'sprite_data_offset',  # 13 uses
	'19e8': 'battle_index_x',  # 12 uses
	'1a31': 'coord_x_result',  # 12 uses
	'1980': 'sprite_anim_y_base',  # 11 uses
	'194c': 'battle_anim_counter',  # 11 uses
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
			# Pattern: .W $XXXX or .w $XXXX (not already labeled with !)
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
