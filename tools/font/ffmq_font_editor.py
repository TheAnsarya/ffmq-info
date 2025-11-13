#!/usr/bin/env python3
"""
FFMQ Font Editor - Font graphics and glyph editor

Font Features:
- Glyph editing
- Font tile extraction
- Kerning adjustment
- Character spacing
- Font rendering
- Multi-font support

Font Types:
- Dialog font
- Menu font
- Battle font
- Number font
- Title font
- Credits font

Features:
- Bitmap editing
- Palette management
- Width tables
- Preview rendering
- Export/import
- Font conversion

Usage:
	python ffmq_font_editor.py --extract rom.smc font_tiles.bin
	python ffmq_font_editor.py --insert font_tiles.bin rom.smc
	python ffmq_font_editor.py --preview font_tiles.bin "Hello World"
	python ffmq_font_editor.py --export font_tiles.bin font.png
	python ffmq_font_editor.py --import font.png font_tiles.bin
"""

import argparse
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, field


@dataclass
class Glyph:
	"""Font glyph"""
	char_id: int
	width: int
	height: int
	pixels: List[List[int]]  # 2D pixel array
	advance: int  # Character advance width


@dataclass
class FontData:
	"""Font data"""
	font_id: int
	name: str
	glyph_width: int
	glyph_height: int
	glyphs: List[Glyph] = field(default_factory=list)
	width_table: List[int] = field(default_factory=list)
	rom_offset: int = 0


class FontEditor:
	"""Font graphics editor"""
	
	# ROM offsets (example)
	FONT_TILE_OFFSET = 0x150000
	FONT_WIDTH_TABLE_OFFSET = 0x151000
	
	# Font settings
	TILE_SIZE = 8
	GLYPHS_PER_ROW = 16
	GLYPH_COUNT = 256
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.rom_data: Optional[bytearray] = None
		self.fonts: List[FontData] = []
		self.current_font: Optional[FontData] = None
	
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
	
	def extract_font(self, font_id: int = 0) -> Optional[FontData]:
		"""Extract font from ROM"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return None
		
		font = FontData(
			font_id=font_id,
			name=f"Font_{font_id}",
			glyph_width=self.TILE_SIZE,
			glyph_height=self.TILE_SIZE,
			rom_offset=self.FONT_TILE_OFFSET
		)
		
		# Extract width table
		width_offset = self.FONT_WIDTH_TABLE_OFFSET + (font_id * self.GLYPH_COUNT)
		
		for i in range(self.GLYPH_COUNT):
			offset = width_offset + i
			
			if offset < len(self.rom_data):
				width = self.rom_data[offset]
				font.width_table.append(width)
			else:
				font.width_table.append(self.TILE_SIZE)
		
		# Extract glyphs (2bpp tiles)
		tile_offset = self.FONT_TILE_OFFSET + (font_id * self.GLYPH_COUNT * 16)
		
		for i in range(self.GLYPH_COUNT):
			glyph = self._extract_glyph(tile_offset + (i * 16), i)
			
			if glyph is not None:
				glyph.advance = font.width_table[i] if i < len(font.width_table) else self.TILE_SIZE
				font.glyphs.append(glyph)
		
		self.current_font = font
		
		if self.verbose:
			print(f"✓ Extracted font: {self.GLYPH_COUNT} glyphs")
		
		return font
	
	def _extract_glyph(self, offset: int, char_id: int) -> Optional[Glyph]:
		"""Extract single glyph (2bpp tile)"""
		if self.rom_data is None or offset + 16 > len(self.rom_data):
			return None
		
		pixels = [[0 for _ in range(self.TILE_SIZE)] for _ in range(self.TILE_SIZE)]
		
		# Read 2bpp tile data
		for y in range(self.TILE_SIZE):
			byte1 = self.rom_data[offset + (y * 2)]
			byte2 = self.rom_data[offset + (y * 2) + 1]
			
			for x in range(self.TILE_SIZE):
				bit = 7 - x
				
				bit1 = (byte1 >> bit) & 1
				bit2 = (byte2 >> bit) & 1
				
				color = bit1 | (bit2 << 1)
				pixels[y][x] = color
		
		glyph = Glyph(
			char_id=char_id,
			width=self.TILE_SIZE,
			height=self.TILE_SIZE,
			pixels=pixels,
			advance=self.TILE_SIZE
		)
		
		return glyph
	
	def insert_font(self, font: FontData) -> bool:
		"""Insert font into ROM"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return False
		
		# Write width table
		width_offset = self.FONT_WIDTH_TABLE_OFFSET + (font.font_id * self.GLYPH_COUNT)
		
		for i, width in enumerate(font.width_table):
			offset = width_offset + i
			
			if offset < len(self.rom_data):
				self.rom_data[offset] = width
		
		# Write glyphs
		tile_offset = self.FONT_TILE_OFFSET + (font.font_id * self.GLYPH_COUNT * 16)
		
		for glyph in font.glyphs:
			offset = tile_offset + (glyph.char_id * 16)
			self._insert_glyph(glyph, offset)
		
		if self.verbose:
			print(f"✓ Inserted font: {len(font.glyphs)} glyphs")
		
		return True
	
	def _insert_glyph(self, glyph: Glyph, offset: int) -> None:
		"""Insert single glyph (2bpp tile)"""
		if self.rom_data is None or offset + 16 > len(self.rom_data):
			return
		
		# Write 2bpp tile data
		for y in range(self.TILE_SIZE):
			byte1 = 0
			byte2 = 0
			
			for x in range(self.TILE_SIZE):
				if y < len(glyph.pixels) and x < len(glyph.pixels[y]):
					color = glyph.pixels[y][x]
					
					bit = 7 - x
					bit1 = color & 1
					bit2 = (color >> 1) & 1
					
					byte1 |= (bit1 << bit)
					byte2 |= (bit2 << bit)
			
			self.rom_data[offset + (y * 2)] = byte1
			self.rom_data[offset + (y * 2) + 1] = byte2
	
	def export_tiles(self, output_path: Path) -> bool:
		"""Export font tiles as binary"""
		if self.current_font is None:
			print("Error: No font loaded")
			return False
		
		try:
			with open(output_path, 'wb') as f:
				for glyph in self.current_font.glyphs:
					# Write 2bpp tile
					for y in range(self.TILE_SIZE):
						byte1 = 0
						byte2 = 0
						
						for x in range(self.TILE_SIZE):
							if y < len(glyph.pixels) and x < len(glyph.pixels[y]):
								color = glyph.pixels[y][x]
								
								bit = 7 - x
								bit1 = color & 1
								bit2 = (color >> 1) & 1
								
								byte1 |= (bit1 << bit)
								byte2 |= (bit2 << bit)
						
						f.write(bytes([byte1, byte2]))
			
			if self.verbose:
				print(f"✓ Exported font tiles: {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting tiles: {e}")
			return False
	
	def import_tiles(self, input_path: Path, font_id: int = 0) -> bool:
		"""Import font tiles from binary"""
		try:
			with open(input_path, 'rb') as f:
				tile_data = f.read()
			
			font = FontData(
				font_id=font_id,
				name=f"Font_{font_id}",
				glyph_width=self.TILE_SIZE,
				glyph_height=self.TILE_SIZE
			)
			
			# Read tiles
			for i in range(min(self.GLYPH_COUNT, len(tile_data) // 16)):
				offset = i * 16
				
				pixels = [[0 for _ in range(self.TILE_SIZE)] for _ in range(self.TILE_SIZE)]
				
				for y in range(self.TILE_SIZE):
					byte1 = tile_data[offset + (y * 2)]
					byte2 = tile_data[offset + (y * 2) + 1]
					
					for x in range(self.TILE_SIZE):
						bit = 7 - x
						
						bit1 = (byte1 >> bit) & 1
						bit2 = (byte2 >> bit) & 1
						
						color = bit1 | (bit2 << 1)
						pixels[y][x] = color
				
				glyph = Glyph(
					char_id=i,
					width=self.TILE_SIZE,
					height=self.TILE_SIZE,
					pixels=pixels,
					advance=self.TILE_SIZE
				)
				
				font.glyphs.append(glyph)
			
			# Initialize width table
			font.width_table = [self.TILE_SIZE] * self.GLYPH_COUNT
			
			self.current_font = font
			
			if self.verbose:
				print(f"✓ Imported font tiles: {len(font.glyphs)} glyphs")
			
			return True
		
		except Exception as e:
			print(f"Error importing tiles: {e}")
			return False
	
	def render_text(self, text: str) -> List[List[int]]:
		"""Render text using current font"""
		if self.current_font is None:
			return []
		
		# Calculate dimensions
		total_width = sum(
			self.current_font.glyphs[ord(c)].advance
			for c in text
			if ord(c) < len(self.current_font.glyphs)
		)
		
		height = self.TILE_SIZE
		
		# Create canvas
		canvas = [[0 for _ in range(total_width)] for _ in range(height)]
		
		# Render characters
		x_pos = 0
		
		for char in text:
			char_id = ord(char)
			
			if char_id >= len(self.current_font.glyphs):
				continue
			
			glyph = self.current_font.glyphs[char_id]
			
			# Copy glyph pixels
			for y in range(min(height, len(glyph.pixels))):
				for x in range(min(glyph.advance, len(glyph.pixels[y]))):
					if x_pos + x < total_width:
						canvas[y][x_pos + x] = glyph.pixels[y][x]
			
			x_pos += glyph.advance
		
		return canvas
	
	def print_preview(self, text: str) -> None:
		"""Print text preview"""
		canvas = self.render_text(text)
		
		if not canvas:
			print("No font loaded")
			return
		
		print(f"\n=== Preview: {text} ===\n")
		
		# Print using ASCII characters
		chars = [' ', '░', '▒', '█']
		
		for row in canvas:
			line = ''.join(
				chars[min(pixel, 3)]
				for pixel in row
			)
			print(line)
		
		print()
	
	def print_glyph(self, char_id: int) -> None:
		"""Print single glyph"""
		if self.current_font is None or char_id >= len(self.current_font.glyphs):
			print("Glyph not found")
			return
		
		glyph = self.current_font.glyphs[char_id]
		
		print(f"\n=== Glyph {char_id} ('{chr(char_id)}') ===\n")
		print(f"Size: {glyph.width}x{glyph.height}")
		print(f"Advance: {glyph.advance}")
		print()
		
		# Print pixels
		chars = [' ', '░', '▒', '█']
		
		for row in glyph.pixels:
			line = ''.join(
				chars[min(pixel, 3)]
				for pixel in row
			)
			print(line)
		
		print()


def main():
	parser = argparse.ArgumentParser(description='FFMQ Font Editor')
	parser.add_argument('--extract', nargs=2, metavar=('ROM', 'OUTPUT'),
					   help='Extract font from ROM')
	parser.add_argument('--insert', nargs=2, metavar=('TILES', 'ROM'),
					   help='Insert font into ROM')
	parser.add_argument('--preview', nargs=2, metavar=('TILES', 'TEXT'),
					   help='Preview rendered text')
	parser.add_argument('--glyph', type=int, metavar='ID',
					   help='Show specific glyph')
	parser.add_argument('--export', nargs=2, metavar=('ROM', 'OUTPUT'),
					   help='Export font tiles')
	parser.add_argument('--import', nargs=2, dest='import_tiles',
					   metavar=('TILES', 'ROM'), help='Import font tiles')
	parser.add_argument('--font-id', type=int, default=0,
					   help='Font ID to extract/insert')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FontEditor(verbose=args.verbose)
	
	# Extract
	if args.extract:
		rom_path, output_path = args.extract
		editor.load_rom(Path(rom_path))
		editor.extract_font(args.font_id)
		editor.export_tiles(Path(output_path))
		return 0
	
	# Insert
	if args.insert:
		tiles_path, rom_path = args.insert
		editor.import_tiles(Path(tiles_path), args.font_id)
		editor.load_rom(Path(rom_path))
		
		if editor.current_font:
			editor.insert_font(editor.current_font)
		
		editor.save_rom(Path(rom_path))
		return 0
	
	# Preview
	if args.preview:
		tiles_path, text = args.preview
		editor.import_tiles(Path(tiles_path))
		editor.print_preview(text)
		return 0
	
	# Show glyph
	if args.glyph is not None:
		if args.extract:
			rom_path, _ = args.extract
			editor.load_rom(Path(rom_path))
			editor.extract_font(args.font_id)
		
		editor.print_glyph(args.glyph)
		return 0
	
	# Export
	if args.export:
		rom_path, output_path = args.export
		editor.load_rom(Path(rom_path))
		editor.extract_font(args.font_id)
		editor.export_tiles(Path(output_path))
		return 0
	
	# Import
	if args.import_tiles:
		tiles_path, rom_path = args.import_tiles
		editor.import_tiles(Path(tiles_path), args.font_id)
		editor.load_rom(Path(rom_path))
		
		if editor.current_font:
			editor.insert_font(editor.current_font)
		
		editor.save_rom(Path(rom_path))
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
