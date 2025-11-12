"""
Extract enemy-specific palettes from Bank 09.

Enemy palettes are at $098000 (file offset 0x048000).
Each enemy has a dedicated 16-byte palette (8 colors × 2 bytes RGB555).
"""

import os
import sys
import struct
from pathlib import Path
from typing import List, Tuple
import json

sys.path.insert(0, str(Path(__file__).parent.parent))

from extraction.extract_graphics import RGB555Color


class EnemyPaletteExtractor:
	"""Extract enemy palettes from Bank 09."""

	def __init__(self, rom_path: str):
		"""Load ROM data."""
		with open(rom_path, 'rb') as f:
			self.rom_data = f.read()

	def extract_enemy_palette(self, enemy_id: int) -> List[Tuple[int, int, int]]:
		"""
		Extract 8-color palette for specific enemy.

		Bank 09 enemy palettes start at $098000 (file offset 0x048000).
		Each palette is 16 bytes (8 colors × 2 bytes RGB555).
		
		Args:
			enemy_id: Enemy ID (0-82)
			
		Returns:
			List of 8 RGB888 tuples
		"""
		# Bank 09 palettes start at file offset 0x048000
		palette_base = 0x048000
		palette_offset = palette_base + (enemy_id * 16)

		colors = []
		for i in range(8):
			offset = palette_offset + (i * 2)
			
			# Read RGB555 value (little-endian)
			low = self.rom_data[offset]
			high = self.rom_data[offset + 1]
			
			# Convert to RGB888
			color = RGB555Color.from_bytes(low, high)
			rgb888 = color.to_rgb888()
			colors.append(rgb888)

		return colors

	def extract_all_enemy_palettes(self, num_enemies: int = 83) -> dict:
		"""Extract palettes for all enemies."""
		palettes = {}
		
		for enemy_id in range(num_enemies):
			palette = self.extract_enemy_palette(enemy_id)
			palettes[enemy_id] = palette

		return palettes

	def export_enemy_palettes_json(self, output_path: str):
		"""Export all enemy palettes as JSON."""
		# Load enemy names
		enemies_path = Path("data/extracted/enemies/enemies.json")
		if enemies_path.exists():
			with open(enemies_path) as f:
				enemy_data = json.load(f)
				enemy_names = {e['id']: e['name'] for e in enemy_data['enemies']}
		else:
			enemy_names = {}

		palettes = self.extract_all_enemy_palettes(83)

		output_data = {
			'metadata': {
				'source': 'Bank 09 enemy palette table',
				'rom_offset': '0x048000',
				'format': 'RGB555 (8 colors per enemy)',
				'total_enemies': 83
			},
			'palettes': []
		}

		for enemy_id, colors in palettes.items():
			name = enemy_names.get(enemy_id, f"Enemy {enemy_id}")
			
			palette_entry = {
				'enemy_id': enemy_id,
				'enemy_name': name,
				'rom_offset': f"0x{0x048000 + (enemy_id * 16):06X}",
				'colors': []
			}

			for i, (r, g, b) in enumerate(colors):
				color_entry = {
					'index': i,
					'rgb': [r, g, b],
					'hex': f"#{r:02X}{g:02X}{b:02X}",
					'name': self._color_name(i)
				}
				palette_entry['colors'].append(color_entry)

			output_data['palettes'].append(palette_entry)

		with open(output_path, 'w') as f:
			json.dump(output_data, f, indent=2)

		return len(palettes)

	def _color_name(self, index: int) -> str:
		"""Get descriptive name for color slot."""
		names = [
			'transparent',  # 0
			'primary',	  # 1
			'secondary',	# 2
			'shadow',	   # 3
			'dark',		 # 4
			'accent',	   # 5
			'highlight',	# 6
			'outline'	   # 7
		]
		return names[index] if index < len(names) else f"color_{index}"

	def print_palette_table(self, num_enemies: int = 83):
		"""Print formatted palette table."""
		# Load enemy names
		enemies_path = Path("data/extracted/enemies/enemies.json")
		if enemies_path.exists():
			with open(enemies_path) as f:
				enemy_data = json.load(f)
				enemy_names = {e['id']: e['name'] for e in enemy_data['enemies']}
		else:
			enemy_names = {}

		print("\n" + "=" * 100)
		print(f"Enemy Palette Table (Bank 09 @ $098000)")
		print("=" * 100)
		print(f"{'ID':<4} {'Name':<25} {'ROM Offset':<12} {'Colors (RGB Hex)'}")
		print("-" * 100)

		for enemy_id in range(num_enemies):
			name = enemy_names.get(enemy_id, f"Enemy {enemy_id}")
			colors = self.extract_enemy_palette(enemy_id)
			
			rom_offset = f"0x{0x048000 + (enemy_id * 16):06X}"
			
			# Show first 4 colors
			color_hex = ' '.join(f"#{r:02X}{g:02X}{b:02X}" for r, g, b in colors[:4])
			
			print(f"{enemy_id:<4} {name:<25} {rom_offset:<12} {color_hex}...")


def main():
	"""Main palette extraction routine."""
	print("=" * 100)
	print("FFMQ Enemy Palette Extraction")
	print("=" * 100)
	print()

	rom_path = "roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"

	print(f"Loading ROM: {rom_path}")
	extractor = EnemyPaletteExtractor(rom_path)
	print("* ROM loaded")

	# Print palette table
	extractor.print_palette_table(83)

	# Export JSON
	print("\nExporting enemy palettes...")
	output_path = "data/extracted/palettes/enemy_palettes.json"
	Path(output_path).parent.mkdir(parents=True, exist_ok=True)
	
	count = extractor.export_enemy_palettes_json(output_path)
	print(f"* Exported {count} enemy palettes to: {output_path}")

	print("\n" + "=" * 100)
	print("Palette Extraction Complete!")
	print("=" * 100)
	print()
	print("Next Steps:")
	print("  1. Update extract_all_enemies.py to use enemy palettes")
	print("  2. Re-extract all enemy sprites with correct colors")
	print("  3. Verify sprites match in-game appearance")
	print()

	return 0


if __name__ == '__main__':
	sys.exit(main())
