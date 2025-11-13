#!/usr/bin/env python3
"""
SNES Tilemap Renderer - Render SNES tilemaps to images

SNES Tilemap Format:
- 2 bytes per tile entry
- Bit 0-9: Tile number (0-1023)
- Bit 10-12: Palette number (0-7)
- Bit 13: Priority
- Bit 14: X flip
- Bit 15: Y flip

Features:
- Render tilemaps to PNG
- Support for tile flipping
- Multiple palette support
- Layer composition
- Export to Tiled TMX format
- Batch rendering

Usage:
	python snes_tilemap_renderer.py rom.sfc --tiles 0x80000 --map 0xC0000 --width 32 --height 32
	python snes_tilemap_renderer.py rom.sfc --tiles 0x80000 --map 0xC0000 --palette 0x82000 --output map.png
	python snes_tilemap_renderer.py rom.sfc --export-tmx --output map.tmx
"""

import argparse
import struct
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import List, Tuple, Optional
from dataclasses import dataclass
from enum import Enum

try:
	from PIL import Image
	PIL_AVAILABLE = True
except ImportError:
	PIL_AVAILABLE = False


@dataclass
class TileEntry:
	"""Single tilemap entry"""
	tile_num: int       # 0-1023
	palette_num: int    # 0-7
	priority: bool
	x_flip: bool
	y_flip: bool
	
	@staticmethod
	def from_word(word: int) -> 'TileEntry':
		"""Decode tilemap entry from 16-bit word"""
		return TileEntry(
			tile_num=word & 0x03FF,
			palette_num=(word >> 10) & 0x07,
			priority=(word >> 13) & 0x01 != 0,
			x_flip=(word >> 14) & 0x01 != 0,
			y_flip=(word >> 15) & 0x01 != 0
		)


@dataclass
class Tile8x8:
	"""8x8 tile with pixel data"""
	pixels: List[List[int]]  # 8x8 array of palette indices
	
	def flip_horizontal(self) -> 'Tile8x8':
		"""Create horizontally flipped tile"""
		flipped = [row[::-1] for row in self.pixels]
		return Tile8x8(flipped)
	
	def flip_vertical(self) -> 'Tile8x8':
		"""Create vertically flipped tile"""
		flipped = self.pixels[::-1]
		return Tile8x8(flipped)


class SNESTilemapDecoder:
	"""Decode SNES tilemaps"""
	
	@staticmethod
	def decode_4bpp_tile(data: bytes, offset: int) -> Tile8x8:
		"""Decode single 4bpp tile"""
		pixels = [[0 for _ in range(8)] for _ in range(8)]
		
		for row in range(8):
			byte_offset_low = offset + (row * 2)
			byte_offset_high = offset + 16 + (row * 2)
			
			if byte_offset_high + 1 >= len(data):
				break
			
			plane0 = data[byte_offset_low]
			plane1 = data[byte_offset_low + 1]
			plane2 = data[byte_offset_high]
			plane3 = data[byte_offset_high + 1]
			
			for col in range(8):
				bit_pos = 7 - col
				bit0 = (plane0 >> bit_pos) & 1
				bit1 = (plane1 >> bit_pos) & 1
				bit2 = (plane2 >> bit_pos) & 1
				bit3 = (plane3 >> bit_pos) & 1
				
				pixels[row][col] = bit0 | (bit1 << 1) | (bit2 << 2) | (bit3 << 3)
		
		return Tile8x8(pixels)
	
	@staticmethod
	def decode_2bpp_tile(data: bytes, offset: int) -> Tile8x8:
		"""Decode single 2bpp tile"""
		pixels = [[0 for _ in range(8)] for _ in range(8)]
		
		for row in range(8):
			byte_offset = offset + (row * 2)
			if byte_offset + 1 >= len(data):
				break
			
			plane0 = data[byte_offset]
			plane1 = data[byte_offset + 1]
			
			for col in range(8):
				bit_pos = 7 - col
				bit0 = (plane0 >> bit_pos) & 1
				bit1 = (plane1 >> bit_pos) & 1
				
				pixels[row][col] = bit0 | (bit1 << 1)
		
		return Tile8x8(pixels)
	
	@staticmethod
	def decode_tilemap(data: bytes, offset: int, width: int, height: int) -> List[List[TileEntry]]:
		"""Decode tilemap data"""
		tilemap = []
		
		for y in range(height):
			row = []
			for x in range(width):
				entry_offset = offset + ((y * width + x) * 2)
				
				if entry_offset + 1 >= len(data):
					row.append(TileEntry(0, 0, False, False, False))
					continue
				
				word = struct.unpack_from('<H', data, entry_offset)[0]
				row.append(TileEntry.from_word(word))
			
			tilemap.append(row)
		
		return tilemap


class SNESPaletteSet:
	"""Set of SNES palettes"""
	
	def __init__(self, palettes: List[List[Tuple[int, int, int]]]):
		self.palettes = palettes
	
	@staticmethod
	def from_rom(data: bytes, offset: int, num_palettes: int = 8, colors_per_palette: int = 16) -> 'SNESPaletteSet':
		"""Extract multiple palettes from ROM"""
		palettes = []
		
		for pal_idx in range(num_palettes):
			palette = []
			pal_offset = offset + (pal_idx * colors_per_palette * 2)
			
			for color_idx in range(colors_per_palette):
				color_offset = pal_offset + (color_idx * 2)
				
				if color_offset + 1 >= len(data):
					palette.append((255, 0, 255))  # Magenta for missing
					continue
				
				color_word = struct.unpack_from('<H', data, color_offset)[0]
				
				# BGR555 to RGB888
				b = (color_word & 0x7C00) >> 10
				g = (color_word & 0x03E0) >> 5
				r = (color_word & 0x001F)
				
				r = (r * 255) // 31
				g = (g * 255) // 31
				b = (b * 255) // 31
				
				palette.append((r, g, b))
			
			palettes.append(palette)
		
		return SNESPaletteSet(palettes)
	
	def get_color(self, palette_num: int, color_index: int) -> Tuple[int, int, int]:
		"""Get color from specific palette"""
		if palette_num >= len(self.palettes):
			return (255, 0, 255)  # Magenta for invalid palette
		
		palette = self.palettes[palette_num]
		
		if color_index >= len(palette):
			return (255, 0, 255)  # Magenta for invalid color
		
		return palette[color_index]


class SNESTilemapRenderer:
	"""Render SNES tilemaps to images"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = f.read()
		
		if self.verbose:
			print(f"Loaded ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def render_tilemap(self, tile_offset: int, map_offset: int, palette_offset: int,
					   map_width: int, map_height: int,
					   bits_per_pixel: int = 4,
					   num_palettes: int = 8) -> Optional[Image.Image]:
		"""Render tilemap to image"""
		if not PIL_AVAILABLE:
			print("Error: PIL/Pillow required for rendering")
			return None
		
		if self.verbose:
			print(f"\nRendering tilemap:")
			print(f"  Tiles: 0x{tile_offset:06X}")
			print(f"  Map: 0x{map_offset:06X}")
			print(f"  Palette: 0x{palette_offset:06X}")
			print(f"  Size: {map_width}x{map_height} tiles")
			print(f"  Format: {bits_per_pixel}bpp")
		
		# Load palettes
		colors_per_palette = 2 ** bits_per_pixel
		palette_set = SNESPaletteSet.from_rom(
			self.rom_data,
			palette_offset,
			num_palettes,
			colors_per_palette
		)
		
		# Decode tilemap
		tilemap = SNESTilemapDecoder.decode_tilemap(
			self.rom_data,
			map_offset,
			map_width,
			map_height
		)
		
		# Find max tile number to know how many tiles to load
		max_tile = 0
		for row in tilemap:
			for entry in row:
				max_tile = max(max_tile, entry.tile_num)
		
		if self.verbose:
			print(f"  Max tile: {max_tile}")
		
		# Load tiles
		bytes_per_tile = (bits_per_pixel * 8 * 8) // 8
		tiles = []
		
		for i in range(max_tile + 1):
			tile_data_offset = tile_offset + (i * bytes_per_tile)
			
			if bits_per_pixel == 4:
				tile = SNESTilemapDecoder.decode_4bpp_tile(self.rom_data, tile_data_offset)
			elif bits_per_pixel == 2:
				tile = SNESTilemapDecoder.decode_2bpp_tile(self.rom_data, tile_data_offset)
			else:
				print(f"Error: Unsupported BPP: {bits_per_pixel}")
				return None
			
			tiles.append(tile)
		
		# Create image
		img_width = map_width * 8
		img_height = map_height * 8
		img = Image.new('RGB', (img_width, img_height), (0, 0, 0))
		pixels = img.load()
		
		# Render each tile
		for map_y in range(map_height):
			for map_x in range(map_width):
				entry = tilemap[map_y][map_x]
				
				if entry.tile_num >= len(tiles):
					continue
				
				tile = tiles[entry.tile_num]
				
				# Apply flips
				if entry.x_flip:
					tile = tile.flip_horizontal()
				if entry.y_flip:
					tile = tile.flip_vertical()
				
				# Render tile
				for y in range(8):
					for x in range(8):
						color_idx = tile.pixels[y][x]
						color = palette_set.get_color(entry.palette_num, color_idx)
						
						dst_x = map_x * 8 + x
						dst_y = map_y * 8 + y
						
						if dst_x < img_width and dst_y < img_height:
							pixels[dst_x, dst_y] = color
		
		if self.verbose:
			print(f"  Output: {img.width}x{img.height} pixels")
		
		return img
	
	def export_tmx(self, map_offset: int, map_width: int, map_height: int,
				   tile_image_path: str, output_path: Path) -> None:
		"""Export to Tiled TMX format"""
		# Decode tilemap
		tilemap = SNESTilemapDecoder.decode_tilemap(
			self.rom_data,
			map_offset,
			map_width,
			map_height
		)
		
		# Create TMX XML
		root = ET.Element('map', {
			'version': '1.0',
			'orientation': 'orthogonal',
			'renderorder': 'right-down',
			'width': str(map_width),
			'height': str(map_height),
			'tilewidth': '8',
			'tileheight': '8',
		})
		
		# Add tileset
		tileset = ET.SubElement(root, 'tileset', {
			'firstgid': '1',
			'name': 'tiles',
			'tilewidth': '8',
			'tileheight': '8',
		})
		
		tileset_image = ET.SubElement(tileset, 'image', {
			'source': tile_image_path,
			'width': '128',  # 16 tiles * 8 pixels
			'height': '128',
		})
		
		# Add layer
		layer = ET.SubElement(root, 'layer', {
			'name': 'Tile Layer 1',
			'width': str(map_width),
			'height': str(map_height),
		})
		
		# Add data
		data = ET.SubElement(layer, 'data', {'encoding': 'csv'})
		
		csv_rows = []
		for row in tilemap:
			csv_row = ','.join(str(entry.tile_num + 1) for entry in row)  # +1 for GID
			csv_rows.append(csv_row)
		
		data.text = '\n' + ',\n'.join(csv_rows) + '\n'
		
		# Write to file
		tree = ET.ElementTree(root)
		ET.indent(tree, '\t')
		tree.write(output_path, encoding='utf-8', xml_declaration=True)
		
		if self.verbose:
			print(f"✓ Exported TMX to {output_path}")
	
	def analyze_tilemap(self, map_offset: int, map_width: int, map_height: int) -> dict:
		"""Analyze tilemap data"""
		tilemap = SNESTilemapDecoder.decode_tilemap(
			self.rom_data,
			map_offset,
			map_width,
			map_height
		)
		
		tile_usage = {}
		palette_usage = {}
		flips_h = 0
		flips_v = 0
		
		for row in tilemap:
			for entry in row:
				# Count tile usage
				tile_usage[entry.tile_num] = tile_usage.get(entry.tile_num, 0) + 1
				
				# Count palette usage
				palette_usage[entry.palette_num] = palette_usage.get(entry.palette_num, 0) + 1
				
				# Count flips
				if entry.x_flip:
					flips_h += 1
				if entry.y_flip:
					flips_v += 1
		
		return {
			'total_entries': map_width * map_height,
			'unique_tiles': len(tile_usage),
			'most_used_tile': max(tile_usage.items(), key=lambda x: x[1]) if tile_usage else (0, 0),
			'palettes_used': sorted(palette_usage.keys()),
			'horizontal_flips': flips_h,
			'vertical_flips': flips_v,
		}


def main():
	parser = argparse.ArgumentParser(description='Render SNES tilemaps')
	parser.add_argument('rom', type=Path, help='ROM file')
	parser.add_argument('--tiles', type=lambda x: int(x, 0), required=True, help='Tile data offset (hex)')
	parser.add_argument('--map', type=lambda x: int(x, 0), required=True, help='Tilemap offset (hex)')
	parser.add_argument('--palette', type=lambda x: int(x, 0), help='Palette offset (hex)')
	parser.add_argument('--width', type=int, default=32, help='Map width in tiles')
	parser.add_argument('--height', type=int, default=32, help='Map height in tiles')
	parser.add_argument('--bpp', type=int, choices=[2, 4], default=4, help='Bits per pixel')
	parser.add_argument('--num-palettes', type=int, default=8, help='Number of palettes')
	parser.add_argument('--output', type=Path, help='Output PNG file')
	parser.add_argument('--export-tmx', action='store_true', help='Export to Tiled TMX format')
	parser.add_argument('--tile-image', type=str, default='tiles.png', help='Tile image path for TMX')
	parser.add_argument('--analyze', action='store_true', help='Analyze tilemap')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	if not PIL_AVAILABLE and not args.export_tmx and not args.analyze:
		print("Error: PIL/Pillow required for rendering. Install with: pip install Pillow")
		return 1
	
	renderer = SNESTilemapRenderer(args.rom, verbose=args.verbose)
	
	# Analyze
	if args.analyze:
		analysis = renderer.analyze_tilemap(args.map, args.width, args.height)
		
		print(f"\nTilemap Analysis:")
		print(f"  Total entries: {analysis['total_entries']}")
		print(f"  Unique tiles: {analysis['unique_tiles']}")
		print(f"  Most used tile: #{analysis['most_used_tile'][0]} ({analysis['most_used_tile'][1]} times)")
		print(f"  Palettes used: {analysis['palettes_used']}")
		print(f"  Horizontal flips: {analysis['horizontal_flips']}")
		print(f"  Vertical flips: {analysis['vertical_flips']}")
		return 0
	
	# Export TMX
	if args.export_tmx:
		output_path = args.output or Path('tilemap.tmx')
		renderer.export_tmx(args.map, args.width, args.height, args.tile_image, output_path)
		return 0
	
	# Render to PNG
	if args.palette is None:
		print("Error: --palette required for rendering (or use --analyze, --export-tmx)")
		return 1
	
	img = renderer.render_tilemap(
		args.tiles,
		args.map,
		args.palette,
		args.width,
		args.height,
		args.bpp,
		args.num_palettes
	)
	
	if img:
		output_path = args.output or Path('tilemap.png')
		img.save(output_path)
		print(f"✓ Rendered tilemap to {output_path}")
		return 0
	
	return 1


if __name__ == '__main__':
	exit(main())
