#!/usr/bin/env python3
"""
SNES Graphics Extractor - Extract and convert SNES graphics to modern formats
Supports 2bpp, 4bpp, 8bpp tile formats with palette handling

SNES Graphics Format:
- Tiles are 8x8 pixels
- 2bpp: 16 bytes per tile (4 colors)
- 4bpp: 32 bytes per tile (16 colors)  
- 8bpp: 64 bytes per tile (256 colors)
- Palettes: 16-bit BGR555 format (2 bytes per color)

FFMQ Specific Locations (LoROM mapping):
- Character graphics: 0x080000-0x0BFFFF
- Map tiles: 0x0C0000-0x0FFFFF
- Sprite graphics: 0x100000-0x13FFFF
- Palettes: Various locations, typically near graphics data

Features:
- Extract tiles from ROM
- Convert to PNG with PIL
- Palette extraction and conversion
- Tilemap rendering
- Sprite sheet generation
- Auto-detect tile format
- Batch extraction

Usage:
	python snes_graphics_extractor.py rom.sfc --offset 0x80000 --tiles 256 --bpp 4 --palette 0x80200
	python snes_graphics_extractor.py rom.sfc --extract-all --output graphics/
	python snes_graphics_extractor.py rom.sfc --sprite-sheet --offset 0x100000 --width 16
	python snes_graphics_extractor.py rom.sfc --tilemap --offset 0xC0000 --map-width 32
"""

import argparse
import struct
from pathlib import Path
from typing import List, Optional, Tuple
from dataclasses import dataclass
from enum import Enum

try:
	from PIL import Image
	PIL_AVAILABLE = True
except ImportError:
	PIL_AVAILABLE = False
	print("Warning: PIL/Pillow not available. Install with: pip install Pillow")


class TileFormat(Enum):
	"""SNES tile bit depth"""
	BPP_2 = 2  # 4 colors
	BPP_4 = 4  # 16 colors
	BPP_8 = 8  # 256 colors


@dataclass
class SNESPalette:
	"""SNES palette in BGR555 format"""
	colors: List[Tuple[int, int, int]]  # RGB tuples
	
	@staticmethod
	def from_rom(data: bytes, offset: int = 0, num_colors: int = 16) -> 'SNESPalette':
		"""Extract palette from ROM data"""
		colors = []
		for i in range(num_colors):
			pos = offset + (i * 2)
			if pos + 1 >= len(data):
				break
			
			# Read 16-bit BGR555 color
			color_word = struct.unpack_from('<H', data, pos)[0]
			
			# Extract BGR components (5 bits each)
			b = (color_word & 0x7C00) >> 10
			g = (color_word & 0x03E0) >> 5
			r = (color_word & 0x001F)
			
			# Convert 5-bit to 8-bit (scale from 0-31 to 0-255)
			r = (r * 255) // 31
			g = (g * 255) // 31
			b = (b * 255) // 31
			
			colors.append((r, g, b))
		
		return SNESPalette(colors=colors)
	
	def get_default_palette(num_colors: int = 16) -> 'SNESPalette':
		"""Generate default grayscale palette"""
		colors = []
		step = 255 // (num_colors - 1) if num_colors > 1 else 255
		for i in range(num_colors):
			gray = min(255, i * step)
			colors.append((gray, gray, gray))
		return SNESPalette(colors=colors)


class SNESTile:
	"""8x8 SNES tile"""
	
	def __init__(self, pixel_data: List[List[int]]):
		"""
		Initialize tile with pixel data
		pixel_data: 8x8 array of palette indices
		"""
		self.pixels = pixel_data
	
	@staticmethod
	def decode_2bpp(data: bytes, offset: int = 0) -> 'SNESTile':
		"""
		Decode 2bpp tile (16 bytes = 8x8 pixels, 4 colors)
		
		2bpp format: 2 bitplanes, interleaved by row
		Bytes 0-1: Row 0 (plane 0, plane 1)
		Bytes 2-3: Row 1
		...
		Bytes 14-15: Row 7
		"""
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
		
		return SNESTile(pixels)
	
	@staticmethod
	def decode_4bpp(data: bytes, offset: int = 0) -> 'SNESTile':
		"""
		Decode 4bpp tile (32 bytes = 8x8 pixels, 16 colors)
		
		4bpp format: 4 bitplanes, interleaved
		Bytes 0-1: Row 0 (plane 0-1)
		Bytes 16-17: Row 0 (plane 2-3)
		Bytes 2-3: Row 1 (plane 0-1)
		...
		"""
		pixels = [[0 for _ in range(8)] for _ in range(8)]
		
		for row in range(8):
			# Planes 0-1 (lower 2 bits)
			byte_offset_low = offset + (row * 2)
			# Planes 2-3 (upper 2 bits)
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
		
		return SNESTile(pixels)
	
	@staticmethod
	def decode_8bpp(data: bytes, offset: int = 0) -> 'SNESTile':
		"""
		Decode 8bpp tile (64 bytes = 8x8 pixels, 256 colors)
		
		8bpp format: 8 bitplanes, interleaved in groups
		"""
		pixels = [[0 for _ in range(8)] for _ in range(8)]
		
		for row in range(8):
			# 8 planes total, organized in groups
			byte_offsets = [
				offset + (row * 2),      # Planes 0-1
				offset + 16 + (row * 2), # Planes 2-3
				offset + 32 + (row * 2), # Planes 4-5
				offset + 48 + (row * 2), # Planes 6-7
			]
			
			if byte_offsets[-1] + 1 >= len(data):
				break
			
			planes = []
			for byte_off in byte_offsets:
				planes.append(data[byte_off])
				planes.append(data[byte_off + 1])
			
			for col in range(8):
				bit_pos = 7 - col
				pixel_value = 0
				
				for plane_idx in range(8):
					bit = (planes[plane_idx] >> bit_pos) & 1
					pixel_value |= (bit << plane_idx)
				
				pixels[row][col] = pixel_value
		
		return SNESTile(pixels)


class SNESGraphicsExtractor:
	"""Extract and convert SNES graphics"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		# Load ROM
		with open(rom_path, 'rb') as f:
			self.rom_data = f.read()
		
		if self.verbose:
			print(f"Loaded ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def extract_tiles(self, offset: int, num_tiles: int, 
					  tile_format: TileFormat = TileFormat.BPP_4) -> List[SNESTile]:
		"""Extract tiles from ROM"""
		tiles = []
		bytes_per_tile = {
			TileFormat.BPP_2: 16,
			TileFormat.BPP_4: 32,
			TileFormat.BPP_8: 64
		}[tile_format]
		
		if self.verbose:
			print(f"Extracting {num_tiles} tiles from 0x{offset:06X} ({tile_format.value}bpp)")
		
		for i in range(num_tiles):
			tile_offset = offset + (i * bytes_per_tile)
			
			if tile_offset + bytes_per_tile > len(self.rom_data):
				if self.verbose:
					print(f"  Warning: Reached end of ROM at tile {i}")
				break
			
			if tile_format == TileFormat.BPP_2:
				tile = SNESTile.decode_2bpp(self.rom_data, tile_offset)
			elif tile_format == TileFormat.BPP_4:
				tile = SNESTile.decode_4bpp(self.rom_data, tile_offset)
			elif tile_format == TileFormat.BPP_8:
				tile = SNESTile.decode_8bpp(self.rom_data, tile_offset)
			
			tiles.append(tile)
		
		return tiles
	
	def tiles_to_image(self, tiles: List[SNESTile], palette: SNESPalette,
					   tiles_per_row: int = 16) -> Image.Image:
		"""Convert tiles to PIL Image"""
		if not PIL_AVAILABLE:
			raise RuntimeError("PIL/Pillow required for image export")
		
		num_tiles = len(tiles)
		num_rows = (num_tiles + tiles_per_row - 1) // tiles_per_row
		
		img_width = tiles_per_row * 8
		img_height = num_rows * 8
		
		img = Image.new('RGB', (img_width, img_height), (0, 0, 0))
		pixels = img.load()
		
		for tile_idx, tile in enumerate(tiles):
			tile_x = (tile_idx % tiles_per_row) * 8
			tile_y = (tile_idx // tiles_per_row) * 8
			
			for y in range(8):
				for x in range(8):
					color_idx = tile.pixels[y][x]
					if color_idx < len(palette.colors):
						color = palette.colors[color_idx]
					else:
						color = (255, 0, 255)  # Magenta for invalid indices
					
					pixels[tile_x + x, tile_y + y] = color
		
		return img
	
	def extract_palette(self, offset: int, num_colors: int = 16) -> SNESPalette:
		"""Extract palette from ROM"""
		if offset + (num_colors * 2) > len(self.rom_data):
			if self.verbose:
				print(f"Warning: Palette extends beyond ROM, using default")
			return SNESPalette.get_default_palette(num_colors)
		
		return SNESPalette.from_rom(self.rom_data, offset, num_colors)
	
	def auto_detect_format(self, offset: int) -> TileFormat:
		"""
		Auto-detect tile format based on data patterns
		This is a heuristic - not always accurate
		"""
		# Sample first few tiles and check for patterns
		sample_size = 64
		if offset + sample_size > len(self.rom_data):
			return TileFormat.BPP_4  # Default
		
		sample = self.rom_data[offset:offset + sample_size]
		
		# Check for 4bpp pattern: interleaved bitplanes
		# Bytes 0-15 and 16-31 should have similar patterns
		if len(sample) >= 32:
			low_bytes = sample[0:16]
			high_bytes = sample[16:32]
			
			# Count non-zero bytes
			low_nonzero = sum(1 for b in low_bytes if b != 0)
			high_nonzero = sum(1 for b in high_bytes if b != 0)
			
			# If both halves have data, likely 4bpp
			if low_nonzero > 2 and high_nonzero > 2:
				return TileFormat.BPP_4
		
		# Check for mostly zero data (common in 2bpp)
		zero_bytes = sum(1 for b in sample if b == 0)
		if zero_bytes > sample_size * 0.6:
			return TileFormat.BPP_2
		
		return TileFormat.BPP_4  # Default to 4bpp
	
	def render_tilemap(self, tile_offset: int, map_offset: int,
					   map_width: int, map_height: int,
					   tile_format: TileFormat, palette: SNESPalette) -> Image.Image:
		"""
		Render a tilemap
		
		Tilemap format: 2 bytes per tile
		- Lower 10 bits: tile number
		- Bit 10-11: palette (for modes with multiple palettes)
		- Bit 12-13: priority
		- Bit 14: X flip
		- Bit 15: Y flip
		"""
		if not PIL_AVAILABLE:
			raise RuntimeError("PIL/Pillow required for tilemap rendering")
		
		# Extract all possible tiles
		max_tile_num = 0
		tilemap_data = []
		
		for i in range(map_width * map_height):
			map_pos = map_offset + (i * 2)
			if map_pos + 1 >= len(self.rom_data):
				break
			
			tile_word = struct.unpack_from('<H', self.rom_data, map_pos)[0]
			tile_num = tile_word & 0x03FF
			palette_num = (tile_word >> 10) & 0x03
			x_flip = (tile_word >> 14) & 1
			y_flip = (tile_word >> 15) & 1
			
			tilemap_data.append((tile_num, palette_num, x_flip, y_flip))
			max_tile_num = max(max_tile_num, tile_num)
		
		# Extract tiles
		tiles = self.extract_tiles(tile_offset, max_tile_num + 1, tile_format)
		
		# Create image
		img_width = map_width * 8
		img_height = map_height * 8
		img = Image.new('RGB', (img_width, img_height), (0, 0, 0))
		pixels = img.load()
		
		for map_y in range(map_height):
			for map_x in range(map_width):
				map_idx = map_y * map_width + map_x
				if map_idx >= len(tilemap_data):
					break
				
				tile_num, pal_num, x_flip, y_flip = tilemap_data[map_idx]
				if tile_num >= len(tiles):
					continue
				
				tile = tiles[tile_num]
				
				for y in range(8):
					for x in range(8):
						# Apply flips
						src_x = (7 - x) if x_flip else x
						src_y = (7 - y) if y_flip else y
						
						color_idx = tile.pixels[src_y][src_x]
						if color_idx < len(palette.colors):
							color = palette.colors[color_idx]
						else:
							color = (255, 0, 255)
						
						dst_x = map_x * 8 + x
						dst_y = map_y * 8 + y
						pixels[dst_x, dst_y] = color
		
		return img
	
	def extract_all_graphics(self, output_dir: Path) -> None:
		"""Extract all known FFMQ graphics"""
		output_dir.mkdir(parents=True, exist_ok=True)
		
		# FFMQ known graphics locations (these are examples - adjust based on actual ROM)
		extractions = [
			{
				'name': 'character_graphics',
				'offset': 0x080000,
				'tiles': 512,
				'bpp': TileFormat.BPP_4,
				'palette_offset': 0x080000 + (512 * 32),  # After tile data
			},
			{
				'name': 'map_tiles',
				'offset': 0x0C0000,
				'tiles': 256,
				'bpp': TileFormat.BPP_4,
				'palette_offset': 0x0C0000 + (256 * 32),
			},
			{
				'name': 'sprite_graphics',
				'offset': 0x100000,
				'tiles': 256,
				'bpp': TileFormat.BPP_4,
				'palette_offset': 0x100000 + (256 * 32),
			},
		]
		
		for extraction in extractions:
			if self.verbose:
				print(f"\nExtracting {extraction['name']}...")
			
			# Extract tiles
			tiles = self.extract_tiles(
				extraction['offset'],
				extraction['tiles'],
				extraction['bpp']
			)
			
			# Extract palette
			palette = self.extract_palette(
				extraction['palette_offset'],
				num_colors=16 if extraction['bpp'] == TileFormat.BPP_4 else 4
			)
			
			# Create image
			img = self.tiles_to_image(tiles, palette, tiles_per_row=16)
			
			# Save
			output_path = output_dir / f"{extraction['name']}.png"
			img.save(output_path)
			
			if self.verbose:
				print(f"  Saved to {output_path}")


def main():
	parser = argparse.ArgumentParser(description='Extract SNES graphics from ROM')
	parser.add_argument('rom', type=Path, help='ROM file')
	parser.add_argument('--offset', type=lambda x: int(x, 0), help='Graphics offset (hex)')
	parser.add_argument('--tiles', type=int, default=256, help='Number of tiles to extract')
	parser.add_argument('--bpp', type=int, choices=[2, 4, 8], default=4, help='Bits per pixel')
	parser.add_argument('--palette', type=lambda x: int(x, 0), help='Palette offset (hex)')
	parser.add_argument('--palette-colors', type=int, default=16, help='Number of colors in palette')
	parser.add_argument('--width', type=int, default=16, help='Tiles per row in output')
	parser.add_argument('--output', type=Path, help='Output PNG file')
	parser.add_argument('--extract-all', action='store_true', help='Extract all known graphics')
	parser.add_argument('--sprite-sheet', action='store_true', help='Create sprite sheet')
	parser.add_argument('--tilemap', action='store_true', help='Render tilemap')
	parser.add_argument('--map-offset', type=lambda x: int(x, 0), help='Tilemap data offset')
	parser.add_argument('--map-width', type=int, default=32, help='Tilemap width in tiles')
	parser.add_argument('--map-height', type=int, default=32, help='Tilemap height in tiles')
	parser.add_argument('--auto-detect', action='store_true', help='Auto-detect tile format')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	if not PIL_AVAILABLE:
		print("Error: PIL/Pillow is required. Install with: pip install Pillow")
		return 1
	
	extractor = SNESGraphicsExtractor(args.rom, verbose=args.verbose)
	
	# Extract all mode
	if args.extract_all:
		output_dir = args.output or Path('graphics')
		extractor.extract_all_graphics(output_dir)
		print(f"\n✓ Extracted all graphics to {output_dir}")
		return 0
	
	# Single extraction mode
	if args.offset is None:
		print("Error: --offset required (or use --extract-all)")
		return 1
	
	# Auto-detect format
	if args.auto_detect:
		tile_format = extractor.auto_detect_format(args.offset)
		if args.verbose:
			print(f"Auto-detected format: {tile_format.value}bpp")
	else:
		tile_format = TileFormat(args.bpp)
	
	# Extract palette
	if args.palette:
		palette = extractor.extract_palette(args.palette, args.palette_colors)
	else:
		num_colors = 2 ** args.bpp
		palette = SNESPalette.get_default_palette(num_colors)
		if args.verbose:
			print(f"Using default {num_colors}-color grayscale palette")
	
	# Tilemap rendering
	if args.tilemap and args.map_offset is not None:
		img = extractor.render_tilemap(
			args.offset,
			args.map_offset,
			args.map_width,
			args.map_height,
			tile_format,
			palette
		)
		
		output_path = args.output or Path('tilemap.png')
		img.save(output_path)
		print(f"✓ Tilemap saved to {output_path}")
		return 0
	
	# Standard tile extraction
	tiles = extractor.extract_tiles(args.offset, args.tiles, tile_format)
	img = extractor.tiles_to_image(tiles, palette, args.width)
	
	output_path = args.output or Path('tiles.png')
	img.save(output_path)
	
	print(f"✓ Extracted {len(tiles)} tiles to {output_path}")
	print(f"  Format: {tile_format.value}bpp")
	print(f"  Image size: {img.width}x{img.height}")
	
	return 0


if __name__ == '__main__':
	exit(main())
