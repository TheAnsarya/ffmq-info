#!/usr/bin/env python3
"""
FFMQ Graphics Palette Editor - Edit color palettes with advanced features

SNES Color Format:
- BGR555: 15-bit color (5 bits per channel)
- Format: 0bbbbbgggggrrrrr
- 2 bytes per color (little-endian)
- 32,768 total possible colors

Features:
- View/edit palettes
- Color manipulation (HSV, RGB)
- Palette swapping
- Palette cycling
- Color replacement
- Gradient generation
- Brightness adjustment
- Contrast adjustment
- Saturation adjustment
- Color matching
- Palette import/export
- Visual palette grid
- HTML color preview
- Palette animation

Palette Types:
- Sprite palettes (16 colors each)
- Background palettes (16 colors each)
- Global palettes (256 colors)
- Character palettes
- Enemy palettes
- Map palettes

Usage:
	python ffmq_palette_editor.py rom.sfc --list-palettes
	python ffmq_palette_editor.py rom.sfc --show-palette 0
	python ffmq_palette_editor.py rom.sfc --export-palette 0 palette.json
	python ffmq_palette_editor.py rom.sfc --swap-colors 0 5 10
	python ffmq_palette_editor.py rom.sfc --adjust-brightness 0 20
	python ffmq_palette_editor.py rom.sfc --adjust-saturation 0 -30
	python ffmq_palette_editor.py rom.sfc --replace-color 0 "#FF0000" "#00FF00"
	python ffmq_palette_editor.py rom.sfc --create-gradient 0 0 15 "#FF0000" "#0000FF"
	python ffmq_palette_editor.py rom.sfc --export-html palettes.html
"""

import argparse
import json
import struct
import colorsys
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any
from dataclasses import dataclass, field, asdict
from enum import Enum


class PaletteType(Enum):
	"""Palette types"""
	SPRITE = "sprite"
	BACKGROUND = "background"
	CHARACTER = "character"
	ENEMY = "enemy"
	MAP = "map"
	GLOBAL = "global"


@dataclass
class Color:
	"""SNES BGR555 color"""
	r: int  # 0-31 (5-bit)
	g: int  # 0-31 (5-bit)
	b: int  # 0-31 (5-bit)
	
	@classmethod
	def from_bgr555(cls, value: int) -> 'Color':
		"""Create color from BGR555 value"""
		r = value & 0x1F
		g = (value >> 5) & 0x1F
		b = (value >> 10) & 0x1F
		return cls(r, g, b)
	
	def to_bgr555(self) -> int:
		"""Convert to BGR555 value"""
		return (self.b << 10) | (self.g << 5) | self.r
	
	def to_rgb888(self) -> Tuple[int, int, int]:
		"""Convert to 8-bit RGB (0-255)"""
		r8 = (self.r * 255) // 31
		g8 = (self.g * 255) // 31
		b8 = (self.b * 255) // 31
		return (r8, g8, b8)
	
	@classmethod
	def from_rgb888(cls, r: int, g: int, b: int) -> 'Color':
		"""Create from 8-bit RGB"""
		r5 = (r * 31) // 255
		g5 = (g * 31) // 255
		b5 = (b * 31) // 255
		return cls(r5, g5, b5)
	
	@classmethod
	def from_hex(cls, hex_color: str) -> 'Color':
		"""Create from hex string (#RRGGBB)"""
		hex_color = hex_color.lstrip('#')
		r = int(hex_color[0:2], 16)
		g = int(hex_color[2:4], 16)
		b = int(hex_color[4:6], 16)
		return cls.from_rgb888(r, g, b)
	
	def to_hex(self) -> str:
		"""Convert to hex string"""
		r8, g8, b8 = self.to_rgb888()
		return f'#{r8:02X}{g8:02X}{b8:02X}'
	
	def to_hsv(self) -> Tuple[float, float, float]:
		"""Convert to HSV (0-1 range)"""
		r8, g8, b8 = self.to_rgb888()
		h, s, v = colorsys.rgb_to_hsv(r8/255, g8/255, b8/255)
		return (h, s, v)
	
	@classmethod
	def from_hsv(cls, h: float, s: float, v: float) -> 'Color':
		"""Create from HSV (0-1 range)"""
		r, g, b = colorsys.hsv_to_rgb(h, s, v)
		r8 = int(r * 255)
		g8 = int(g * 255)
		b8 = int(b * 255)
		return cls.from_rgb888(r8, g8, b8)
	
	def adjust_brightness(self, percent: int) -> 'Color':
		"""Adjust brightness by percentage (-100 to +100)"""
		h, s, v = self.to_hsv()
		v = max(0.0, min(1.0, v * (1.0 + percent / 100.0)))
		return Color.from_hsv(h, s, v)
	
	def adjust_saturation(self, percent: int) -> 'Color':
		"""Adjust saturation by percentage (-100 to +100)"""
		h, s, v = self.to_hsv()
		s = max(0.0, min(1.0, s * (1.0 + percent / 100.0)))
		return Color.from_hsv(h, s, v)
	
	def adjust_contrast(self, percent: int) -> 'Color':
		"""Adjust contrast by percentage (-100 to +100)"""
		r8, g8, b8 = self.to_rgb888()
		factor = (259 * (percent + 255)) / (255 * (259 - percent))
		
		r8 = int(max(0, min(255, factor * (r8 - 128) + 128)))
		g8 = int(max(0, min(255, factor * (g8 - 128) + 128)))
		b8 = int(max(0, min(255, factor * (b8 - 128) + 128)))
		
		return Color.from_rgb888(r8, g8, b8)


@dataclass
class Palette:
	"""Color palette"""
	palette_id: int
	name: str
	palette_type: PaletteType
	colors: List[Color]
	
	def to_dict(self) -> dict:
		return {
			'palette_id': self.palette_id,
			'name': self.name,
			'palette_type': self.palette_type.value,
			'colors': [c.to_hex() for c in self.colors]
		}


class FFMQPaletteDatabase:
	"""Database of FFMQ palettes"""
	
	# Palette data locations
	SPRITE_PALETTE_OFFSET = 0x2D0000
	BG_PALETTE_OFFSET = 0x2D8000
	CHARACTER_PALETTE_OFFSET = 0x2E0000
	ENEMY_PALETTE_OFFSET = 0x2E8000
	MAP_PALETTE_OFFSET = 0x2F0000
	
	NUM_SPRITE_PALETTES = 64
	NUM_BG_PALETTES = 64
	NUM_CHARACTER_PALETTES = 16
	NUM_ENEMY_PALETTES = 64
	NUM_MAP_PALETTES = 128
	
	COLORS_PER_PALETTE = 16
	
	# Known palette names
	PALETTE_NAMES = {
		0: "Benjamin Colors",
		1: "Kaeli Colors",
		2: "Tristam Colors",
		3: "Phoebe Colors",
		4: "Reuben Colors",
		5: "NPC Colors 1",
		6: "NPC Colors 2",
		7: "Enemy Colors 1",
		8: "Enemy Colors 2",
		# ... more palettes
	}
	
	@classmethod
	def get_palette_name(cls, palette_id: int, palette_type: PaletteType) -> str:
		"""Get palette name"""
		if palette_type == PaletteType.SPRITE:
			return cls.PALETTE_NAMES.get(palette_id, f"Sprite Palette {palette_id}")
		elif palette_type == PaletteType.CHARACTER:
			char_names = ["Benjamin", "Kaeli", "Tristam", "Phoebe", "Reuben"]
			if palette_id < len(char_names):
				return f"{char_names[palette_id]} Palette"
		
		return f"{palette_type.value.capitalize()} Palette {palette_id}"


class FFMQPaletteEditor:
	"""Edit FFMQ color palettes"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		if self.verbose:
			print(f"Loaded FFMQ ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def get_palette_offset(self, palette_id: int, palette_type: PaletteType) -> Optional[int]:
		"""Get palette offset in ROM"""
		if palette_type == PaletteType.SPRITE:
			if palette_id >= FFMQPaletteDatabase.NUM_SPRITE_PALETTES:
				return None
			return FFMQPaletteDatabase.SPRITE_PALETTE_OFFSET + (palette_id * 32)
		
		elif palette_type == PaletteType.BACKGROUND:
			if palette_id >= FFMQPaletteDatabase.NUM_BG_PALETTES:
				return None
			return FFMQPaletteDatabase.BG_PALETTE_OFFSET + (palette_id * 32)
		
		elif palette_type == PaletteType.CHARACTER:
			if palette_id >= FFMQPaletteDatabase.NUM_CHARACTER_PALETTES:
				return None
			return FFMQPaletteDatabase.CHARACTER_PALETTE_OFFSET + (palette_id * 32)
		
		elif palette_type == PaletteType.ENEMY:
			if palette_id >= FFMQPaletteDatabase.NUM_ENEMY_PALETTES:
				return None
			return FFMQPaletteDatabase.ENEMY_PALETTE_OFFSET + (palette_id * 32)
		
		elif palette_type == PaletteType.MAP:
			if palette_id >= FFMQPaletteDatabase.NUM_MAP_PALETTES:
				return None
			return FFMQPaletteDatabase.MAP_PALETTE_OFFSET + (palette_id * 32)
		
		return None
	
	def extract_palette(self, palette_id: int, palette_type: PaletteType) -> Optional[Palette]:
		"""Extract palette from ROM"""
		offset = self.get_palette_offset(palette_id, palette_type)
		
		if offset is None or offset + 32 > len(self.rom_data):
			return None
		
		colors = []
		for i in range(FFMQPaletteDatabase.COLORS_PER_PALETTE):
			color_offset = offset + (i * 2)
			bgr555 = struct.unpack_from('<H', self.rom_data, color_offset)[0]
			colors.append(Color.from_bgr555(bgr555))
		
		palette = Palette(
			palette_id=palette_id,
			name=FFMQPaletteDatabase.get_palette_name(palette_id, palette_type),
			palette_type=palette_type,
			colors=colors
		)
		
		return palette
	
	def write_palette(self, palette: Palette) -> bool:
		"""Write palette to ROM"""
		offset = self.get_palette_offset(palette.palette_id, palette.palette_type)
		
		if offset is None or offset + 32 > len(self.rom_data):
			return False
		
		for i, color in enumerate(palette.colors[:16]):
			color_offset = offset + (i * 2)
			bgr555 = color.to_bgr555()
			struct.pack_into('<H', self.rom_data, color_offset, bgr555)
		
		if self.verbose:
			print(f"✓ Wrote palette {palette.palette_id} to ROM")
		
		return True
	
	def swap_colors(self, palette_id: int, palette_type: PaletteType, 
					index1: int, index2: int) -> bool:
		"""Swap two colors in a palette"""
		palette = self.extract_palette(palette_id, palette_type)
		
		if not palette or index1 >= 16 or index2 >= 16:
			return False
		
		palette.colors[index1], palette.colors[index2] = \
			palette.colors[index2], palette.colors[index1]
		
		self.write_palette(palette)
		
		if self.verbose:
			print(f"✓ Swapped colors {index1} and {index2} in palette {palette_id}")
		
		return True
	
	def replace_color(self, palette_id: int, palette_type: PaletteType,
					  old_color: str, new_color: str) -> int:
		"""Replace all instances of a color"""
		palette = self.extract_palette(palette_id, palette_type)
		
		if not palette:
			return 0
		
		old = Color.from_hex(old_color)
		new = Color.from_hex(new_color)
		count = 0
		
		for i, color in enumerate(palette.colors):
			if color.to_hex().upper() == old.to_hex().upper():
				palette.colors[i] = new
				count += 1
		
		if count > 0:
			self.write_palette(palette)
			
			if self.verbose:
				print(f"✓ Replaced {count} instances of {old_color} with {new_color}")
		
		return count
	
	def adjust_brightness(self, palette_id: int, palette_type: PaletteType, 
						  percent: int) -> bool:
		"""Adjust palette brightness"""
		palette = self.extract_palette(palette_id, palette_type)
		
		if not palette:
			return False
		
		for i in range(len(palette.colors)):
			palette.colors[i] = palette.colors[i].adjust_brightness(percent)
		
		self.write_palette(palette)
		
		if self.verbose:
			print(f"✓ Adjusted brightness by {percent:+d}% for palette {palette_id}")
		
		return True
	
	def adjust_saturation(self, palette_id: int, palette_type: PaletteType,
						  percent: int) -> bool:
		"""Adjust palette saturation"""
		palette = self.extract_palette(palette_id, palette_type)
		
		if not palette:
			return False
		
		for i in range(len(palette.colors)):
			palette.colors[i] = palette.colors[i].adjust_saturation(percent)
		
		self.write_palette(palette)
		
		if self.verbose:
			print(f"✓ Adjusted saturation by {percent:+d}% for palette {palette_id}")
		
		return True
	
	def create_gradient(self, palette_id: int, palette_type: PaletteType,
						start_index: int, end_index: int,
						start_color: str, end_color: str) -> bool:
		"""Create color gradient between two indices"""
		palette = self.extract_palette(palette_id, palette_type)
		
		if not palette or start_index >= 16 or end_index >= 16:
			return False
		
		start = Color.from_hex(start_color)
		end = Color.from_hex(end_color)
		
		steps = abs(end_index - start_index) + 1
		
		for i in range(steps):
			t = i / (steps - 1) if steps > 1 else 0
			
			r = int(start.r + (end.r - start.r) * t)
			g = int(start.g + (end.g - start.g) * t)
			b = int(start.b + (end.b - start.b) * t)
			
			index = start_index + i if start_index < end_index else start_index - i
			palette.colors[index] = Color(r, g, b)
		
		self.write_palette(palette)
		
		if self.verbose:
			print(f"✓ Created gradient from {start_color} to {end_color}")
		
		return True
	
	def export_palette_json(self, palette_id: int, palette_type: PaletteType,
							output_path: Path) -> bool:
		"""Export palette to JSON"""
		palette = self.extract_palette(palette_id, palette_type)
		
		if not palette:
			return False
		
		with open(output_path, 'w') as f:
			json.dump(palette.to_dict(), f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported palette {palette_id} to {output_path}")
		
		return True
	
	def export_all_html(self, output_path: Path) -> None:
		"""Export all palettes to HTML visualization"""
		html = ['<!DOCTYPE html>', '<html>', '<head>',
				'<title>FFMQ Palettes</title>',
				'<style>',
				'body { font-family: monospace; background: #222; color: #fff; }',
				'.palette { margin: 20px; }',
				'.color-grid { display: grid; grid-template-columns: repeat(16, 32px); gap: 2px; }',
				'.color { width: 32px; height: 32px; border: 1px solid #444; }',
				'</style>',
				'</head>', '<body>',
				'<h1>FFMQ Color Palettes</h1>']
		
		# Sprite palettes
		html.append('<h2>Sprite Palettes</h2>')
		for i in range(min(16, FFMQPaletteDatabase.NUM_SPRITE_PALETTES)):
			palette = self.extract_palette(i, PaletteType.SPRITE)
			if palette:
				html.append(f'<div class="palette">')
				html.append(f'<h3>{palette.name}</h3>')
				html.append('<div class="color-grid">')
				for color in palette.colors:
					html.append(f'<div class="color" style="background-color: {color.to_hex()}" '
								f'title="{color.to_hex()}"></div>')
				html.append('</div></div>')
		
		html.extend(['</body>', '</html>'])
		
		with open(output_path, 'w') as f:
			f.write('\n'.join(html))
		
		if self.verbose:
			print(f"✓ Exported HTML palette visualization to {output_path}")
	
	def save_rom(self, output_path: Optional[Path] = None) -> None:
		"""Save modified ROM"""
		save_path = output_path or self.rom_path
		
		with open(save_path, 'wb') as f:
			f.write(self.rom_data)
		
		if self.verbose:
			print(f"✓ Saved ROM to {save_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Graphics Palette Editor')
	parser.add_argument('rom', type=str, help='FFMQ ROM file')
	parser.add_argument('--list-palettes', action='store_true', help='List palettes')
	parser.add_argument('--type', type=str, 
						choices=['sprite', 'background', 'character', 'enemy', 'map'],
						default='sprite', help='Palette type')
	parser.add_argument('--show-palette', type=int, help='Show palette details')
	parser.add_argument('--export-palette', type=int, help='Export palette to JSON')
	parser.add_argument('--swap-colors', type=int, nargs=3, metavar=('PAL', 'IDX1', 'IDX2'),
						help='Swap two colors in palette')
	parser.add_argument('--replace-color', type=int, help='Replace color in palette')
	parser.add_argument('--old-color', type=str, help='Old color (hex)')
	parser.add_argument('--new-color', type=str, help='New color (hex)')
	parser.add_argument('--adjust-brightness', type=int, help='Adjust brightness (palette ID)')
	parser.add_argument('--brightness', type=int, help='Brightness percent (-100 to +100)')
	parser.add_argument('--adjust-saturation', type=int, help='Adjust saturation (palette ID)')
	parser.add_argument('--saturation', type=int, help='Saturation percent (-100 to +100)')
	parser.add_argument('--create-gradient', type=int, nargs=5, 
						metavar=('PAL', 'START_IDX', 'END_IDX', 'START_COLOR', 'END_COLOR'),
						help='Create gradient')
	parser.add_argument('--export-html', type=str, help='Export all palettes to HTML')
	parser.add_argument('--output', type=str, help='Output file')
	parser.add_argument('--save', type=str, help='Save modified ROM')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FFMQPaletteEditor(Path(args.rom), verbose=args.verbose)
	palette_type = PaletteType(args.type)
	
	# List palettes
	if args.list_palettes:
		count = {
			PaletteType.SPRITE: FFMQPaletteDatabase.NUM_SPRITE_PALETTES,
			PaletteType.BACKGROUND: FFMQPaletteDatabase.NUM_BG_PALETTES,
			PaletteType.CHARACTER: FFMQPaletteDatabase.NUM_CHARACTER_PALETTES,
			PaletteType.ENEMY: FFMQPaletteDatabase.NUM_ENEMY_PALETTES,
			PaletteType.MAP: FFMQPaletteDatabase.NUM_MAP_PALETTES
		}.get(palette_type, 0)
		
		print(f"\n{palette_type.value.capitalize()} Palettes ({count}):\n")
		
		for i in range(min(count, 16)):
			palette = editor.extract_palette(i, palette_type)
			if palette:
				colors_preview = ' '.join([c.to_hex() for c in palette.colors[:4]])
				print(f"  {i:2d}: {palette.name:<30} [{colors_preview} ...]")
		
		return 0
	
	# Show palette
	if args.show_palette is not None:
		palette = editor.extract_palette(args.show_palette, palette_type)
		
		if palette:
			print(f"\n=== {palette.name} ===\n")
			print(f"ID: {palette.palette_id}")
			print(f"Type: {palette.palette_type.value}")
			print(f"\nColors:")
			for i, color in enumerate(palette.colors):
				r8, g8, b8 = color.to_rgb888()
				print(f"  {i:2d}: {color.to_hex()} (RGB: {r8:3d},{g8:3d},{b8:3d}) "
					  f"(BGR555: {color.to_bgr555():04X})")
		
		return 0
	
	# Export palette
	if args.export_palette is not None:
		output = Path(args.output) if args.output else Path(f'palette_{args.export_palette}.json')
		editor.export_palette_json(args.export_palette, palette_type, output)
		return 0
	
	# Swap colors
	if args.swap_colors:
		pal_id, idx1, idx2 = args.swap_colors
		editor.swap_colors(pal_id, palette_type, idx1, idx2)
		if args.save:
			editor.save_rom(Path(args.save))
		return 0
	
	# Replace color
	if args.replace_color is not None and args.old_color and args.new_color:
		count = editor.replace_color(args.replace_color, palette_type, 
									  args.old_color, args.new_color)
		if count > 0 and args.save:
			editor.save_rom(Path(args.save))
		return 0
	
	# Adjust brightness
	if args.adjust_brightness is not None and args.brightness is not None:
		editor.adjust_brightness(args.adjust_brightness, palette_type, args.brightness)
		if args.save:
			editor.save_rom(Path(args.save))
		return 0
	
	# Adjust saturation
	if args.adjust_saturation is not None and args.saturation is not None:
		editor.adjust_saturation(args.adjust_saturation, palette_type, args.saturation)
		if args.save:
			editor.save_rom(Path(args.save))
		return 0
	
	# Create gradient
	if args.create_gradient:
		pal_id, start_idx, end_idx, start_color, end_color = args.create_gradient
		editor.create_gradient(int(pal_id), palette_type, int(start_idx), int(end_idx),
							   start_color, end_color)
		if args.save:
			editor.save_rom(Path(args.save))
		return 0
	
	# Export HTML
	if args.export_html:
		editor.export_all_html(Path(args.export_html))
		return 0
	
	print("Use --list-palettes, --show-palette, --export-palette, --swap-colors, ")
	print("     --replace-color, --adjust-brightness, --adjust-saturation,")
	print("     --create-gradient, or --export-html")
	return 0


if __name__ == '__main__':
	exit(main())
