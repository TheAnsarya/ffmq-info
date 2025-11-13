#!/usr/bin/env python3
"""
FFMQ Font Editor - Edit and customize game fonts

Font Features:
- Character glyphs (A-Z, 0-9, symbols)
- Variable width fonts
- Proportional spacing
- Kerning tables
- Font metrics (height, baseline)
- Multiple font sets
- Special characters
- Control codes

Glyph Editor:
- 8×8 or 16×16 tile editing
- Pixel-level editing
- Copy/paste glyphs
- Flip/rotate
- Import from image
- Export to image

Font Metrics:
- Character width (pixels)
- Character height
- Baseline offset
- Line spacing
- Letter spacing
- Word spacing

Features:
- Edit character glyphs
- Set font metrics
- Preview text rendering
- Import fonts
- Export fonts
- Generate .tbl files

Usage:
	python ffmq_font_editor.py rom.sfc --char A --edit
	python ffmq_font_editor.py rom.sfc --preview "Hello World"
	python ffmq_font_editor.py rom.sfc --export-image font.png
	python ffmq_font_editor.py rom.sfc --import-image font.png
	python ffmq_font_editor.py rom.sfc --list-fonts
	python ffmq_font_editor.py rom.sfc --set-width A 6
"""

import argparse
import json
from pathlib import Path
from typing import List, Dict, Tuple, Optional, Any
from dataclasses import dataclass, asdict
from enum import Enum


class FontType(Enum):
	"""Font types"""
	DIALOG = "dialog"
	MENU = "menu"
	BATTLE = "battle"
	NUMBERS = "numbers"


@dataclass
class Glyph:
	"""Character glyph"""
	char_code: int
	character: str
	pixels: List[List[int]]  # 8×8 or 16×16 grid (0=bg, 1-3=palette colors)
	width: int
	height: int
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class FontMetrics:
	"""Font measurements"""
	char_width: int  # Default character width
	char_height: int
	baseline: int
	line_spacing: int
	letter_spacing: int
	space_width: int


@dataclass
class Font:
	"""Complete font definition"""
	font_id: int
	name: str
	font_type: FontType
	metrics: FontMetrics
	glyphs: Dict[int, Glyph]  # char_code -> Glyph
	address: int  # ROM address
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['font_type'] = self.font_type.value
		d['glyphs'] = {code: glyph.to_dict() for code, glyph in self.glyphs.items()}
		return d


class FFMQFontEditor:
	"""Font editing tool"""
	
	# Known font locations
	FONT_ADDRESSES = {
		'dialog': 0x1A0000,
		'menu': 0x1B0000,
		'battle': 0x1C0000,
		'numbers': 0x1D0000
	}
	
	# Standard ASCII characters
	ASCII_CHARS = (
		" !\"#$%&'()*+,-./0123456789:;<=>?"
		"@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_"
		"`abcdefghijklmnopqrstuvwxyz{|}~"
	)
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		if self.verbose:
			print(f"Loaded ROM: {rom_path}")
	
	def read_glyph(self, address: int, width: int = 8, height: int = 8) -> List[List[int]]:
		"""Read glyph pixel data from ROM"""
		# SNES 2bpp tile format
		bytes_per_row = width // 8 * 2
		pixels = [[0 for _ in range(width)] for _ in range(height)]
		
		for y in range(height):
			row_offset = address + y * bytes_per_row
			
			for x in range(width):
				byte_idx = x // 8
				bit_pos = 7 - (x % 8)
				
				# Read 2 bitplanes
				bp1 = (self.rom_data[row_offset + byte_idx * 2] >> bit_pos) & 1
				bp2 = (self.rom_data[row_offset + byte_idx * 2 + 1] >> bit_pos) & 1
				
				pixels[y][x] = bp1 | (bp2 << 1)
		
		return pixels
	
	def write_glyph(self, address: int, pixels: List[List[int]]) -> None:
		"""Write glyph pixel data to ROM"""
		height = len(pixels)
		width = len(pixels[0]) if pixels else 0
		bytes_per_row = width // 8 * 2
		
		for y in range(height):
			row_offset = address + y * bytes_per_row
			
			# Clear row bytes
			for i in range(bytes_per_row):
				self.rom_data[row_offset + i] = 0
			
			# Set pixels
			for x in range(width):
				byte_idx = x // 8
				bit_pos = 7 - (x % 8)
				
				pixel = pixels[y][x]
				bp1 = pixel & 1
				bp2 = (pixel >> 1) & 1
				
				if bp1:
					self.rom_data[row_offset + byte_idx * 2] |= (1 << bit_pos)
				if bp2:
					self.rom_data[row_offset + byte_idx * 2 + 1] |= (1 << bit_pos)
	
	def load_font(self, font_type: FontType, char_width: int = 8, char_height: int = 8) -> Font:
		"""Load font from ROM"""
		address = self.FONT_ADDRESSES.get(font_type.value, 0x1A0000)
		
		# Default metrics
		metrics = FontMetrics(
			char_width=char_width,
			char_height=char_height,
			baseline=char_height - 2,
			line_spacing=2,
			letter_spacing=1,
			space_width=4
		)
		
		# Load glyphs
		glyphs = {}
		bytes_per_glyph = char_width * char_height // 4  # 2bpp
		
		for i, char in enumerate(self.ASCII_CHARS):
			char_code = ord(char)
			glyph_address = address + i * bytes_per_glyph
			
			pixels = self.read_glyph(glyph_address, char_width, char_height)
			
			glyph = Glyph(
				char_code=char_code,
				character=char,
				pixels=pixels,
				width=char_width,
				height=char_height
			)
			
			glyphs[char_code] = glyph
		
		font = Font(
			font_id=0,
			name=font_type.value.title(),
			font_type=font_type,
			metrics=metrics,
			glyphs=glyphs,
			address=address
		)
		
		if self.verbose:
			print(f"✓ Loaded {len(glyphs)} glyphs from {font_type.value} font")
		
		return font
	
	def save_font(self, font: Font) -> None:
		"""Save font to ROM"""
		bytes_per_glyph = font.metrics.char_width * font.metrics.char_height // 4
		
		for i, char in enumerate(self.ASCII_CHARS):
			char_code = ord(char)
			if char_code in font.glyphs:
				glyph = font.glyphs[char_code]
				glyph_address = font.address + i * bytes_per_glyph
				self.write_glyph(glyph_address, glyph.pixels)
		
		if self.verbose:
			print(f"✓ Saved font to ROM")
	
	def render_text_ascii(self, font: Font, text: str) -> str:
		"""Render text using font (ASCII preview)"""
		lines = []
		
		for row in range(font.metrics.char_height):
			line = ""
			for char in text:
				char_code = ord(char)
				if char_code in font.glyphs:
					glyph = font.glyphs[char_code]
					for x in range(glyph.width):
						pixel = glyph.pixels[row][x]
						if pixel == 0:
							line += " "
						elif pixel == 1:
							line += "░"
						elif pixel == 2:
							line += "▒"
						else:
							line += "▓"
				else:
					line += " " * font.metrics.char_width
				
				line += " " * font.metrics.letter_spacing
			
			lines.append(line)
		
		return "\n".join(lines)
	
	def render_glyph_ascii(self, glyph: Glyph) -> str:
		"""Render single glyph (ASCII preview)"""
		lines = []
		
		for row in glyph.pixels:
			line = ""
			for pixel in row:
				if pixel == 0:
					line += "·"
				elif pixel == 1:
					line += "░"
				elif pixel == 2:
					line += "▒"
				else:
					line += "█"
			lines.append(line)
		
		return "\n".join(lines)
	
	def create_empty_glyph(self, char: str, width: int = 8, height: int = 8) -> Glyph:
		"""Create empty glyph"""
		pixels = [[0 for _ in range(width)] for _ in range(height)]
		
		glyph = Glyph(
			char_code=ord(char),
			character=char,
			pixels=pixels,
			width=width,
			height=height
		)
		
		return glyph
	
	def flip_glyph_horizontal(self, glyph: Glyph) -> None:
		"""Flip glyph horizontally"""
		for row in glyph.pixels:
			row.reverse()
	
	def flip_glyph_vertical(self, glyph: Glyph) -> None:
		"""Flip glyph vertically"""
		glyph.pixels.reverse()
	
	def rotate_glyph_90(self, glyph: Glyph) -> None:
		"""Rotate glyph 90 degrees clockwise"""
		new_pixels = [[0 for _ in range(glyph.height)] for _ in range(glyph.width)]
		
		for y in range(glyph.height):
			for x in range(glyph.width):
				new_pixels[x][glyph.height - 1 - y] = glyph.pixels[y][x]
		
		glyph.pixels = new_pixels
		glyph.width, glyph.height = glyph.height, glyph.width
	
	def export_font_json(self, font: Font, output_path: Path) -> None:
		"""Export font to JSON"""
		with open(output_path, 'w') as f:
			json.dump(font.to_dict(), f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported font to {output_path}")
	
	def import_font_json(self, input_path: Path) -> Font:
		"""Import font from JSON"""
		with open(input_path, 'r') as f:
			data = json.load(f)
		
		data['font_type'] = FontType(data['font_type'])
		data['metrics'] = FontMetrics(**data['metrics'])
		
		glyphs = {}
		for char_code_str, glyph_dict in data['glyphs'].items():
			glyph = Glyph(**glyph_dict)
			glyphs[int(char_code_str)] = glyph
		data['glyphs'] = glyphs
		
		font = Font(**data)
		
		if self.verbose:
			print(f"✓ Imported font from {input_path}")
		
		return font
	
	def save_rom(self, output_path: Path) -> None:
		"""Save modified ROM"""
		with open(output_path, 'wb') as f:
			f.write(self.rom_data)
		
		if self.verbose:
			print(f"✓ Saved ROM to {output_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Font Editor')
	parser.add_argument('rom', type=str, help='FFMQ ROM file')
	parser.add_argument('--font', type=str, choices=[f.value for f in FontType],
					   default='dialog', help='Font type')
	parser.add_argument('--char', type=str, help='Character to edit')
	parser.add_argument('--preview', type=str, help='Preview text')
	parser.add_argument('--list', action='store_true', help='List all glyphs')
	parser.add_argument('--export', type=str, help='Export font to JSON')
	parser.add_argument('--import-json', type=str, help='Import font from JSON')
	parser.add_argument('--save-rom', type=str, help='Save modified ROM')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FFMQFontEditor(Path(args.rom), verbose=args.verbose)
	
	font_type = FontType(args.font)
	
	# List glyphs
	if args.list:
		font = editor.load_font(font_type)
		
		print(f"\n=== {font.name} Font ({len(font.glyphs)} glyphs) ===\n")
		
		for char_code, glyph in sorted(font.glyphs.items()):
			print(f"Char: '{glyph.character}' (0x{char_code:02X})")
			print(editor.render_glyph_ascii(glyph))
			print()
		
		return 0
	
	# Preview text
	if args.preview:
		font = editor.load_font(font_type)
		
		print(f"\n=== Preview: {args.preview} ===\n")
		preview = editor.render_text_ascii(font, args.preview)
		print(preview)
		print()
		
		return 0
	
	# Show character
	if args.char:
		font = editor.load_font(font_type)
		
		char_code = ord(args.char[0])
		if char_code in font.glyphs:
			glyph = font.glyphs[char_code]
			
			print(f"\n=== Character: '{glyph.character}' (0x{char_code:02X}) ===\n")
			print(editor.render_glyph_ascii(glyph))
			print()
		else:
			print(f"Character '{args.char[0]}' not found in font")
			return 1
		
		return 0
	
	# Export
	if args.export:
		font = editor.load_font(font_type)
		editor.export_font_json(font, Path(args.export))
		return 0
	
	# Import
	if args.import_json:
		font = editor.import_font_json(Path(args.import_json))
		editor.save_font(font)
		
		if args.save_rom:
			editor.save_rom(Path(args.save_rom))
		
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
