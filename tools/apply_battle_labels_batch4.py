#!/usr/bin/env python3
"""Apply batch 4 - remaining high-frequency battle/graphics RAM labels."""

import re
from pathlib import Path

# Batch 4: Remaining labels with 5-10 uses (only addresses with defined labels)
LABELS = {
	'1a4c': 'gfx_mode_control',  # 9 uses
	'1a45': 'sprite_control',  # 8 uses
	'1904': 'battle_actor1_x',  # 8 uses
	'1a55': 'layer_flags',  # 8 uses
	'1a51': 'buffer_state',  # 7 uses
	'1a0b': 'battle_sprite_config1',  # 7 uses
	'1a14': 'gfx_buffer_addr_1',  # 7 uses
	'19ec': 'battle_entity_confirm',  # 7 uses
	'1944': 'battle_array_elem_5',  # 7 uses
	'1a5b': 'world_map_flag',  # 7 uses
	'1a2f': 'coord_offset_ref',  # 7 uses
	'1a7e': 'battle_unit_data',  # 7 uses
	'1a3d': 'battle_sprite_comp1',  # 7 uses
	'1906': 'battle_actor1_y',  # 7 uses
	'19b9': 'source_pointer',  # 6 uses
	'1a26': 'buffer_size_backup',  # 6 uses
	'1a3f': 'battle_sprite_comp2',  # 6 uses
	'197d': 'sprite_direction',  # 6 uses
	'1916': 'battle_gfx_config',  # 6 uses
	'1a41': 'battle_sprite_comp3',  # 6 uses
	'1a82': 'battle_unit_flags_ext',  # 6 uses
	'1a60': 'battle_state_primary',  # 6 uses
	'1941': 'battle_array_elem_2',  # 6 uses
	'1a43': 'battle_sprite_comp4',  # 6 uses
	'19af': 'anim_state_counter',  # 6 uses
	'1a33': 'coord_flag',  # 6 uses
	'1978': 'anim_table_ptr_hi',  # 6 uses
	'1a62': 'entity_data_page',  # 6 uses
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
