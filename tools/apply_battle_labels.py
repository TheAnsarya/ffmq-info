#!/usr/bin/env python3
"""Apply high-frequency battle RAM labels across ASM files."""

import re
from pathlib import Path

# High-frequency labels to apply (manually selected from include file)
LABELS = {
	'192b': 'battle_temp_work',  # 157 uses
	'19ee': 'battle_gfx_index',  # 100 uses (also battle_actor_index - context dependent)
	'1935': 'battle_data_index_1',  # 85 uses
	'192d': 'tilemap_x_offset',  # 79 uses
	'1a72': 'battle_status_array',  # 70 uses
	'193b': 'battle_data_index_3',  # 60 uses
	'1926': 'battle_gfx_flags',  # 51 uses
	'192f': 'battle_color_accum',  # 32 uses
	'1939': 'battle_data_index_2',  # 42 uses
	'19b4': 'battle_coord_state',  # 38 uses (also battle_animation_timer)
	'19f1': 'battle_array_elem_4',  # 36 uses (also battle_stats_addr)
	'193f': 'battle_data_index_4',  # 33 uses
	'1a80': 'battle_unit_flags',  # 31 uses
	'193d': 'battle_data_temp_1',  # 31 uses
	'19cb': 'movement_state',  # 29 uses
	'19bf': 'gfx_config_alt',  # 28 uses
	'1a54': 'hardware_flags',  # 28 uses
	'1993': 'graphics_state_param',  # 27 uses (also battle_atb_gauge)
	'19ef': 'battle_gfx_attrib',  # 26 uses
	'197f': 'sprite_move_speed',  # 26 uses
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
			# Case-insensitive matching
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
