#!/usr/bin/env python3
"""
FFMQ Palette Editor - Color palette and graphics editor

Palette Features:
- Color editing
- Palette swapping
- Gradient generation
- Palette cycling
- Color matching
- Export/import

Palette Types:
- Sprite palettes
- Background palettes
- UI palettes
- Font palettes
- Effect palettes
- Battle palettes

Features:
- RGB color editing
- SNES color format
- Palette preview
- Color cycling
- Gradient tools
- Import from PNG

Usage:
	python ffmq_palette_editor.py --extract rom.smc palettes.json
	python ffmq_palette_editor.py --insert palettes.json rom.smc
	python ffmq_palette_editor.py --palette 0 --show palettes.json
	python ffmq_palette_editor.py --export palette_0.pal
	python ffmq_palette_editor.py --import palette_0.pal rom.smc
"""

import argparse
import json
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict, field


@dataclass
class Color:
	"""RGB color"""
	r: int  # 0-255
	g: int  # 0-255
	b: int  # 0-255
	
	def to_snes(self) -> int:
		"""Convert to SNES 15-bit BGR format"""
		# Scale to 5-bit (0-31)
		r5 = self.r >> 3
		g5 = self.g >> 3
		b5 = self.b >> 3
		
		# Pack as BGR555
		return (b5 << 10) | (g5 << 5) | r5
	
	@staticmethod
	def from_snes(value: int) -> 'Color':
		"""Create color from SNES 15-bit BGR format"""
		r5 = value & 0x1F
		g5 = (value >> 5) & 0x1F
		b5 = (value >> 10) & 0x1F
		
		# Scale to 8-bit (0-255)
		r = (r5 << 3) | (r5 >> 2)
		g = (g5 << 3) | (g5 >> 2)
		b = (b5 << 3) | (b5 >> 2)
		
		return Color(r, g, b)


@dataclass
class Palette:
	"""Color palette"""
	palette_id: int
	name: str
	colors: List[Color] = field(default_factory=list)
	size: int = 16
	rom_offset: int = 0


class PaletteEditor:
	"""Palette and color editor"""
	
	# ROM offsets (example)
	PALETTE_DATA_OFFSET = 0x1A0000
	PALETTE_COUNT = 32
	COLORS_PER_PALETTE = 16
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.rom_data: Optional[bytearray] = None
		self.palettes: List[Palette] = []
	
	def load_rom(self, rom_path: Path) -> bool:
		"""Load ROM file"""
		try:
			with open(rom_path, 'rb') as f:
				self.rom_data = bytearray(f.read())
			
			if self.verbose:
				print(f"✓ Loaded ROM: {rom_path} ({len(self.rom_data):,} bytes)")
			
			return True
		
		except Exception as e:
			print(f"Error loading ROM: {e}")
			return False
	
	def save_rom(self, output_path: Path) -> bool:
		"""Save ROM file"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return False
		
		try:
			with open(output_path, 'wb') as f:
				f.write(self.rom_data)
			
			if self.verbose:
				print(f"✓ Saved ROM: {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error saving ROM: {e}")
			return False
	
	def extract_palettes(self) -> List[Palette]:
		"""Extract palettes from ROM"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return []
		
		self.palettes = []
		
		for i in range(self.PALETTE_COUNT):
			offset = self.PALETTE_DATA_OFFSET + (i * self.COLORS_PER_PALETTE * 2)
			
			if offset + (self.COLORS_PER_PALETTE * 2) > len(self.rom_data):
				break
			
			colors = []
			
			for j in range(self.COLORS_PER_PALETTE):
				color_offset = offset + (j * 2)
				
				# Read 16-bit color value
				color_value = int.from_bytes(
					self.rom_data[color_offset:color_offset+2],
					byteorder='little'
				)
				
				color = Color.from_snes(color_value)
				colors.append(color)
			
			palette = Palette(
				palette_id=i,
				name=f"Palette_{i:02d}",
				colors=colors,
				size=self.COLORS_PER_PALETTE,
				rom_offset=offset
			)
			
			self.palettes.append(palette)
		
		if self.verbose:
			print(f"✓ Extracted {len(self.palettes)} palettes")
		
		return self.palettes
	
	def insert_palettes(self) -> bool:
		"""Insert palettes into ROM"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return False
		
		for palette in self.palettes:
			offset = palette.rom_offset
			
			for j, color in enumerate(palette.colors):
				color_offset = offset + (j * 2)
				
				if color_offset + 2 > len(self.rom_data):
					break
				
				# Write 16-bit color value
				color_value = color.to_snes()
				self.rom_data[color_offset:color_offset+2] = color_value.to_bytes(2, byteorder='little')
		
		if self.verbose:
			print(f"✓ Inserted {len(self.palettes)} palettes")
		
		return True
	
	def set_color(self, palette_id: int, color_index: int, r: int, g: int, b: int) -> bool:
		"""Set color in palette"""
		palette = next((p for p in self.palettes if p.palette_id == palette_id), None)
		
		if palette is None:
			print(f"Palette {palette_id} not found")
			return False
		
		if color_index >= len(palette.colors):
			print(f"Color index {color_index} out of range")
			return False
		
		palette.colors[color_index] = Color(r, g, b)
		
		if self.verbose:
			print(f"✓ Set color {color_index} in palette {palette_id} to RGB({r}, {g}, {b})")
		
		return True
	
	def generate_gradient(self, palette_id: int, start_index: int, end_index: int,
						 start_color: Tuple[int, int, int], end_color: Tuple[int, int, int]) -> bool:
		"""Generate gradient between colors"""
		palette = next((p for p in self.palettes if p.palette_id == palette_id), None)
		
		if palette is None:
			print(f"Palette {palette_id} not found")
			return False
		
		steps = end_index - start_index + 1
		
		if steps < 2:
			print("Need at least 2 colors for gradient")
			return False
		
		# Generate gradient
		for i in range(steps):
			t = i / (steps - 1)
			
			r = int(start_color[0] + (end_color[0] - start_color[0]) * t)
			g = int(start_color[1] + (end_color[1] - start_color[1]) * t)
			b = int(start_color[2] + (end_color[2] - start_color[2]) * t)
			
			color_index = start_index + i
			
			if color_index < len(palette.colors):
				palette.colors[color_index] = Color(r, g, b)
		
		if self.verbose:
			print(f"✓ Generated gradient in palette {palette_id} from {start_index} to {end_index}")
		
		return True
	
	def copy_palette(self, source_id: int, dest_id: int) -> bool:
		"""Copy palette"""
		source = next((p for p in self.palettes if p.palette_id == source_id), None)
		dest = next((p for p in self.palettes if p.palette_id == dest_id), None)
		
		if source is None or dest is None:
			print("Palette not found")
			return False
		
		dest.colors = [Color(c.r, c.g, c.b) for c in source.colors]
		
		if self.verbose:
			print(f"✓ Copied palette {source_id} to {dest_id}")
		
		return True
	
	def export_palette(self, palette_id: int, output_path: Path) -> bool:
		"""Export palette to .pal file"""
		palette = next((p for p in self.palettes if p.palette_id == palette_id), None)
		
		if palette is None:
			print(f"Palette {palette_id} not found")
			return False
		
		try:
			with open(output_path, 'w', encoding='utf-8') as f:
				f.write("JASC-PAL\n")
				f.write("0100\n")
				f.write(f"{len(palette.colors)}\n")
				
				for color in palette.colors:
					f.write(f"{color.r} {color.g} {color.b}\n")
			
			if self.verbose:
				print(f"✓ Exported palette {palette_id} to {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting palette: {e}")
			return False
	
	def import_palette(self, palette_id: int, input_path: Path) -> bool:
		"""Import palette from .pal file"""
		palette = next((p for p in self.palettes if p.palette_id == palette_id), None)
		
		if palette is None:
			print(f"Palette {palette_id} not found")
			return False
		
		try:
			with open(input_path, 'r', encoding='utf-8') as f:
				lines = f.readlines()
			
			# Skip header (JASC-PAL format)
			if len(lines) < 3 or not lines[0].strip().startswith("JASC-PAL"):
				print("Invalid palette file format")
				return False
			
			color_count = int(lines[2].strip())
			
			palette.colors = []
			
			for i in range(3, min(3 + color_count, len(lines))):
				parts = lines[i].strip().split()
				
				if len(parts) >= 3:
					r = int(parts[0])
					g = int(parts[1])
					b = int(parts[2])
					
					palette.colors.append(Color(r, g, b))
			
			if self.verbose:
				print(f"✓ Imported palette from {input_path} to palette {palette_id}")
			
			return True
		
		except Exception as e:
			print(f"Error importing palette: {e}")
			return False
	
	def export_json(self, output_path: Path) -> bool:
		"""Export palettes to JSON"""
		try:
			data = {
				'palettes': []
			}
			
			for palette in self.palettes:
				palette_data = {
					'palette_id': palette.palette_id,
					'name': palette.name,
					'colors': [
						{
							'r': c.r,
							'g': c.g,
							'b': c.b
						}
						for c in palette.colors
					],
					'size': palette.size,
					'rom_offset': palette.rom_offset
				}
				
				data['palettes'].append(palette_data)
			
			with open(output_path, 'w', encoding='utf-8') as f:
				json.dump(data, f, indent='\t')
			
			if self.verbose:
				print(f"✓ Exported palettes to {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting palettes: {e}")
			return False
	
	def import_json(self, input_path: Path) -> bool:
		"""Import palettes from JSON"""
		try:
			with open(input_path, 'r', encoding='utf-8') as f:
				data = json.load(f)
			
			self.palettes = []
			
			for palette_data in data['palettes']:
				colors = [
					Color(c['r'], c['g'], c['b'])
					for c in palette_data['colors']
				]
				
				palette = Palette(
					palette_id=palette_data['palette_id'],
					name=palette_data['name'],
					colors=colors,
					size=palette_data.get('size', 16),
					rom_offset=palette_data['rom_offset']
				)
				
				self.palettes.append(palette)
			
			if self.verbose:
				print(f"✓ Imported {len(self.palettes)} palettes")
			
			return True
		
		except Exception as e:
			print(f"Error importing palettes: {e}")
			return False
	
	def print_palette(self, palette_id: int) -> None:
		"""Print palette details"""
		palette = next((p for p in self.palettes if p.palette_id == palette_id), None)
		
		if palette is None:
			print(f"Palette {palette_id} not found")
			return
		
		print(f"\n=== Palette {palette.palette_id}: {palette.name} ===\n")
		print(f"Colors: {len(palette.colors)}")
		print()
		
		for i, color in enumerate(palette.colors):
			print(f"  {i:2d}: RGB({color.r:3d}, {color.g:3d}, {color.b:3d}) = #{color.r:02X}{color.g:02X}{color.b:02X}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Palette Editor')
	parser.add_argument('--extract', nargs=2, metavar=('ROM', 'OUTPUT'),
					   help='Extract palettes from ROM')
	parser.add_argument('--insert', nargs=2, metavar=('PALETTES', 'ROM'),
					   help='Insert palettes into ROM')
	parser.add_argument('--palette', type=int, metavar='ID',
					   help='Show specific palette')
	parser.add_argument('--show', type=str, metavar='FILE',
					   help='Palettes file for --palette')
	parser.add_argument('--export', type=str, metavar='FILE',
					   help='Export palette to .pal file')
	parser.add_argument('--import', dest='import_pal', type=str,
					   metavar='FILE', help='Import palette from .pal file')
	parser.add_argument('--set-color', nargs=5,
					   metavar=('PAL_ID', 'INDEX', 'R', 'G', 'B'),
					   help='Set color in palette')
	parser.add_argument('--gradient', nargs=8,
					   metavar=('PAL_ID', 'START_IDX', 'END_IDX', 'R1', 'G1', 'B1', 'R2', 'G2', 'B2'),
					   help='Generate gradient')
	parser.add_argument('--copy', nargs=2, type=int,
					   metavar=('SOURCE_ID', 'DEST_ID'),
					   help='Copy palette')
	parser.add_argument('--file', type=str, metavar='FILE',
					   help='Palettes JSON file')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = PaletteEditor(verbose=args.verbose)
	
	# Extract
	if args.extract:
		rom_path, output_path = args.extract
		editor.load_rom(Path(rom_path))
		editor.extract_palettes()
		editor.export_json(Path(output_path))
		return 0
	
	# Load file
	if args.file:
		editor.import_json(Path(args.file))
	
	# Insert
	if args.insert:
		palettes_path, rom_path = args.insert
		editor.import_json(Path(palettes_path))
		editor.load_rom(Path(rom_path))
		editor.insert_palettes()
		editor.save_rom(Path(rom_path))
		return 0
	
	# Show palette
	if args.palette is not None:
		if args.show:
			editor.import_json(Path(args.show))
		
		editor.print_palette(args.palette)
		return 0
	
	# Export palette
	if args.export:
		if args.palette is not None:
			editor.export_palette(args.palette, Path(args.export))
		else:
			print("Specify --palette ID")
		
		return 0
	
	# Import palette
	if args.import_pal:
		if args.palette is not None:
			editor.import_palette(args.palette, Path(args.import_pal))
			
			if args.file:
				editor.export_json(Path(args.file))
		else:
			print("Specify --palette ID")
		
		return 0
	
	# Set color
	if args.set_color:
		pal_id, index, r, g, b = [int(x) for x in args.set_color]
		editor.set_color(pal_id, index, r, g, b)
		
		if args.file:
			editor.export_json(Path(args.file))
		
		return 0
	
	# Gradient
	if args.gradient:
		pal_id, start, end, r1, g1, b1, r2, g2, b2 = [int(x) for x in args.gradient]
		editor.generate_gradient(pal_id, start, end, (r1, g1, b1), (r2, g2, b2))
		
		if args.file:
			editor.export_json(Path(args.file))
		
		return 0
	
	# Copy
	if args.copy:
		source_id, dest_id = args.copy
		editor.copy_palette(source_id, dest_id)
		
		if args.file:
			editor.export_json(Path(args.file))
		
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
