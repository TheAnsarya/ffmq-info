#!/usr/bin/env python3
"""
SNES Sprite Extractor - Extract and assemble SNES sprites (OAM objects)

SNES Sprite System:
- OAM (Object Attribute Memory): 128 sprite entries
- Each sprite: 4 bytes of main data + 2 bits of extra data
- Supports 8x8, 16x16, 32x32, 64x64 pixel sizes
- Tile-based: sprites reference tiles from VRAM
- 8 palettes of 16 colors (palette 0-7)
- Supports H/V flipping, priority

OAM Entry Format (4 bytes):
- Byte 0: X position (low 8 bits)
- Byte 1: Y position
- Byte 2: Tile number (low 8 bits)
- Byte 3: Attributes
  - Bit 0: Palette (bit 0)
  - Bit 1: Palette (bit 1)
  - Bit 2: Palette (bit 2)
  - Bit 3: Priority (bit 0)
  - Bit 4: Priority (bit 1)
  - Bit 5: H flip
  - Bit 6: V flip
  - Bit 7: Tile number (bit 8)

Extra Data (2 bits per sprite):
- Bit 0: X position (bit 8)
- Bit 1: Size toggle

Features:
- Extract sprite graphics from ROM
- Assemble metasprites from OAM data
- Export individual sprites or sprite sheets
- Animation frame extraction
- Multiple export formats (PNG, GIF animation)

Usage:
	python snes_sprite_extractor.py rom.sfc --sprites 0x100000 --output sprites.png
	python snes_sprite_extractor.py rom.sfc --oam 0x7E0200 --tiles 0x100000 --palette 0x100400
	python snes_sprite_extractor.py rom.sfc --animation --frames 8 --output walk.gif
	python snes_sprite_extractor.py rom.sfc --sprite-sheet --width 16 --height 16
"""

import argparse
import struct
from pathlib import Path
from typing import List, Tuple, Optional
from dataclasses import dataclass
from enum import Enum

try:
	from PIL import Image
	PIL_AVAILABLE = True
except ImportError:
	PIL_AVAILABLE = False


class SpriteSize(Enum):
	"""SNES sprite sizes (varies by OAM mode)"""
	SIZE_8x8 = (8, 8)
	SIZE_16x16 = (16, 16)
	SIZE_32x32 = (32, 32)
	SIZE_64x64 = (64, 64)
	SIZE_16x8 = (16, 8)
	SIZE_32x16 = (32, 16)
	SIZE_64x32 = (64, 32)
	SIZE_8x16 = (8, 16)
	SIZE_16x32 = (16, 32)
	SIZE_32x64 = (32, 64)


@dataclass
class OAMEntry:
	"""SNES OAM sprite entry"""
	x: int              # X position (0-511)
	y: int              # Y position (0-255)
	tile_num: int       # Tile number (0-511)
	palette: int        # Palette (0-7)
	priority: int       # Priority (0-3)
	h_flip: bool
	v_flip: bool
	size_toggle: bool   # Determines size based on mode
	
	@staticmethod
	def from_bytes(main_data: bytes, extra_bits: int, index: int) -> 'OAMEntry':
		"""
		Decode OAM entry
		main_data: 4 bytes of main OAM data
		extra_bits: 2 bits from extra data table
		index: sprite index (0-127)
		"""
		if len(main_data) < 4:
			return OAMEntry(0, 0, 0, 0, 0, False, False, False)
		
		x_low = main_data[0]
		y = main_data[1]
		tile_low = main_data[2]
		attr = main_data[3]
		
		# Extract attributes
		palette = attr & 0x07
		priority = (attr >> 3) & 0x03
		h_flip = (attr >> 5) & 0x01 != 0
		v_flip = (attr >> 6) & 0x01 != 0
		tile_high = (attr >> 7) & 0x01
		
		# Extract extra bits
		x_high = extra_bits & 0x01
		size_toggle = (extra_bits >> 1) & 0x01 != 0
		
		# Combine tile number
		tile_num = tile_low | (tile_high << 8)
		
		# Combine X position
		x = x_low | (x_high << 8)
		
		return OAMEntry(
			x=x,
			y=y,
			tile_num=tile_num,
			palette=palette,
			priority=priority,
			h_flip=h_flip,
			v_flip=v_flip,
			size_toggle=size_toggle
		)


class SNESSpriteDecoder:
	"""Decode SNES sprite tiles"""
	
	@staticmethod
	def decode_4bpp_tile(data: bytes, offset: int) -> List[List[int]]:
		"""Decode 4bpp 8x8 tile"""
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
		
		return pixels
	
	@staticmethod
	def assemble_sprite(tiles: List[List[List[int]]], width_tiles: int, height_tiles: int,
						h_flip: bool = False, v_flip: bool = False) -> List[List[int]]:
		"""Assemble larger sprite from 8x8 tiles"""
		sprite_width = width_tiles * 8
		sprite_height = height_tiles * 8
		pixels = [[0 for _ in range(sprite_width)] for _ in range(sprite_height)]
		
		for tile_y in range(height_tiles):
			for tile_x in range(width_tiles):
				tile_idx = tile_y * width_tiles + tile_x
				
				if tile_idx >= len(tiles):
					continue
				
				tile = tiles[tile_idx]
				
				# Apply flips to individual tile
				if h_flip:
					tile = [row[::-1] for row in tile]
				if v_flip:
					tile = tile[::-1]
				
				# Copy tile to sprite
				for y in range(8):
					for x in range(8):
						sprite_x = tile_x * 8 + x
						sprite_y = tile_y * 8 + y
						pixels[sprite_y][sprite_x] = tile[y][x]
		
		return pixels


class SNESSpriteExtractor:
	"""Extract sprites from SNES ROM"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = f.read()
		
		if self.verbose:
			print(f"Loaded ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def extract_sprite_tiles(self, offset: int, num_tiles: int) -> List[List[List[int]]]:
		"""Extract sprite tiles (4bpp)"""
		tiles = []
		
		for i in range(num_tiles):
			tile_offset = offset + (i * 32)  # 32 bytes per 4bpp tile
			
			if tile_offset + 32 > len(self.rom_data):
				break
			
			tile = SNESSpriteDecoder.decode_4bpp_tile(self.rom_data, tile_offset)
			tiles.append(tile)
		
		return tiles
	
	def extract_palettes(self, offset: int, num_palettes: int = 8) -> List[List[Tuple[int, int, int]]]:
		"""Extract sprite palettes (16 colors each)"""
		palettes = []
		
		for pal_idx in range(num_palettes):
			palette = []
			pal_offset = offset + (pal_idx * 16 * 2)  # 16 colors * 2 bytes
			
			for color_idx in range(16):
				color_offset = pal_offset + (color_idx * 2)
				
				if color_offset + 1 >= len(self.rom_data):
					palette.append((255, 0, 255))
					continue
				
				color_word = struct.unpack_from('<H', self.rom_data, color_offset)[0]
				
				# BGR555 to RGB888
				b = (color_word & 0x7C00) >> 10
				g = (color_word & 0x03E0) >> 5
				r = (color_word & 0x001F)
				
				r = (r * 255) // 31
				g = (g * 255) // 31
				b = (b * 255) // 31
				
				# Color 0 is transparent for sprites
				if color_idx == 0:
					palette.append((0, 0, 0))  # Black for transparency
				else:
					palette.append((r, g, b))
			
			palettes.append(palette)
		
		return palettes
	
	def render_sprite_sheet(self, tile_offset: int, palette_offset: int,
							num_tiles: int, tiles_per_row: int = 16,
							palette_num: int = 0) -> Optional[Image.Image]:
		"""Render sprite tiles as sheet"""
		if not PIL_AVAILABLE:
			print("Error: PIL/Pillow required")
			return None
		
		if self.verbose:
			print(f"\nRendering sprite sheet:")
			print(f"  Tiles: 0x{tile_offset:06X}")
			print(f"  Palette: 0x{palette_offset:06X}")
			print(f"  Count: {num_tiles} tiles")
		
		# Extract tiles and palettes
		tiles = self.extract_sprite_tiles(tile_offset, num_tiles)
		palettes = self.extract_palettes(palette_offset)
		
		if palette_num >= len(palettes):
			palette_num = 0
		
		palette = palettes[palette_num]
		
		# Create image
		num_rows = (num_tiles + tiles_per_row - 1) // tiles_per_row
		img_width = tiles_per_row * 8
		img_height = num_rows * 8
		
		img = Image.new('RGBA', (img_width, img_height), (0, 0, 0, 0))
		pixels = img.load()
		
		for tile_idx, tile in enumerate(tiles):
			tile_x = (tile_idx % tiles_per_row) * 8
			tile_y = (tile_idx // tiles_per_row) * 8
			
			for y in range(8):
				for x in range(8):
					color_idx = tile[y][x]
					
					if color_idx == 0:
						# Transparent
						color = (0, 0, 0, 0)
					else:
						if color_idx < len(palette):
							rgb = palette[color_idx]
							color = (rgb[0], rgb[1], rgb[2], 255)
						else:
							color = (255, 0, 255, 255)  # Magenta
					
					pixels[tile_x + x, tile_y + y] = color
		
		if self.verbose:
			print(f"  Output: {img.width}x{img.height}")
		
		return img
	
	def render_metasprite(self, oam_offset: int, tile_offset: int, palette_offset: int,
						  num_oam_entries: int = 128) -> Optional[Image.Image]:
		"""Render metasprite from OAM data"""
		if not PIL_AVAILABLE:
			print("Error: PIL/Pillow required")
			return None
		
		# Parse OAM data
		oam_entries = []
		
		# Main OAM data (4 bytes per entry)
		for i in range(num_oam_entries):
			main_offset = oam_offset + (i * 4)
			
			if main_offset + 3 >= len(self.rom_data):
				break
			
			main_data = self.rom_data[main_offset:main_offset + 4]
			
			# Extra data (2 bits per entry, packed in bytes)
			extra_offset = oam_offset + (num_oam_entries * 4) + (i // 4)
			extra_byte = self.rom_data[extra_offset] if extra_offset < len(self.rom_data) else 0
			extra_bits = (extra_byte >> ((i % 4) * 2)) & 0x03
			
			entry = OAMEntry.from_bytes(main_data, extra_bits, i)
			oam_entries.append(entry)
		
		# Extract tiles and palettes
		max_tile = max((e.tile_num for e in oam_entries), default=0)
		tiles = self.extract_sprite_tiles(tile_offset, max_tile + 16)
		palettes = self.extract_palettes(palette_offset)
		
		# Find bounding box
		min_x = min((e.x for e in oam_entries if e.tile_num != 0), default=0)
		min_y = min((e.y for e in oam_entries if e.tile_num != 0), default=0)
		max_x = max((e.x + 16 for e in oam_entries if e.tile_num != 0), default=256)
		max_y = max((e.y + 16 for e in oam_entries if e.tile_num != 0), default=256)
		
		width = max_x - min_x
		height = max_y - min_y
		
		# Create image
		img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
		pixels = img.load()
		
		# Render each sprite
		for entry in oam_entries:
			if entry.tile_num >= len(tiles):
				continue
			
			if entry.palette >= len(palettes):
				continue
			
			tile = tiles[entry.tile_num]
			palette = palettes[entry.palette]
			
			# Apply flips
			if entry.h_flip:
				tile = [row[::-1] for row in tile]
			if entry.v_flip:
				tile = tile[::-1]
			
			# Render tile
			for y in range(8):
				for x in range(8):
					dst_x = entry.x - min_x + x
					dst_y = entry.y - min_y + y
					
					if dst_x < 0 or dst_x >= width or dst_y < 0 or dst_y >= height:
						continue
					
					color_idx = tile[y][x]
					
					if color_idx == 0:
						continue  # Transparent
					
					if color_idx < len(palette):
						rgb = palette[color_idx]
						color = (rgb[0], rgb[1], rgb[2], 255)
					else:
						color = (255, 0, 255, 255)
					
					pixels[dst_x, dst_y] = color
		
		return img
	
	def extract_animation(self, tile_offset: int, palette_offset: int,
						  frame_offsets: List[int], tiles_per_frame: int = 16) -> List[Image.Image]:
		"""Extract animation frames"""
		if not PIL_AVAILABLE:
			print("Error: PIL/Pillow required")
			return []
		
		frames = []
		
		for frame_idx, frame_offset in enumerate(frame_offsets):
			if self.verbose:
				print(f"  Extracting frame {frame_idx + 1}/{len(frame_offsets)}...")
			
			img = self.render_sprite_sheet(
				tile_offset + frame_offset,
				palette_offset,
				tiles_per_frame,
				tiles_per_row=4
			)
			
			if img:
				frames.append(img)
		
		return frames


def main():
	parser = argparse.ArgumentParser(description='Extract SNES sprites')
	parser.add_argument('rom', type=Path, help='ROM file')
	parser.add_argument('--sprites', type=lambda x: int(x, 0), help='Sprite tile offset (hex)')
	parser.add_argument('--palette', type=lambda x: int(x, 0), help='Palette offset (hex)')
	parser.add_argument('--oam', type=lambda x: int(x, 0), help='OAM data offset (hex)')
	parser.add_argument('--tiles', type=lambda x: int(x, 0), help='Tile data offset for OAM (hex)')
	parser.add_argument('--count', type=int, default=256, help='Number of tiles to extract')
	parser.add_argument('--width', type=int, default=16, help='Tiles per row')
	parser.add_argument('--palette-num', type=int, default=0, help='Palette to use (0-7)')
	parser.add_argument('--output', type=Path, help='Output PNG file')
	parser.add_argument('--sprite-sheet', action='store_true', help='Extract as sprite sheet')
	parser.add_argument('--metasprite', action='store_true', help='Render metasprite from OAM')
	parser.add_argument('--animation', action='store_true', help='Extract animation frames')
	parser.add_argument('--frames', type=int, default=4, help='Number of animation frames')
	parser.add_argument('--frame-size', type=int, default=512, help='Bytes per frame')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	if not PIL_AVAILABLE:
		print("Error: PIL/Pillow required. Install with: pip install Pillow")
		return 1
	
	extractor = SNESSpriteExtractor(args.rom, verbose=args.verbose)
	
	# Metasprite from OAM
	if args.metasprite:
		if args.oam is None or args.tiles is None or args.palette is None:
			print("Error: --oam, --tiles, and --palette required for metasprite")
			return 1
		
		img = extractor.render_metasprite(args.oam, args.tiles, args.palette)
		
		if img:
			output_path = args.output or Path('metasprite.png')
			img.save(output_path)
			print(f"✓ Rendered metasprite to {output_path}")
		return 0
	
	# Animation
	if args.animation:
		if args.sprites is None or args.palette is None:
			print("Error: --sprites and --palette required for animation")
			return 1
		
		frame_offsets = [i * args.frame_size for i in range(args.frames)]
		frames = extractor.extract_animation(args.sprites, args.palette, frame_offsets)
		
		if frames:
			output_path = args.output or Path('animation.gif')
			frames[0].save(
				output_path,
				save_all=True,
				append_images=frames[1:],
				duration=100,
				loop=0
			)
			print(f"✓ Saved {len(frames)}-frame animation to {output_path}")
		return 0
	
	# Sprite sheet
	if args.sprite_sheet or args.sprites:
		if args.sprites is None or args.palette is None:
			print("Error: --sprites and --palette required")
			return 1
		
		img = extractor.render_sprite_sheet(
			args.sprites,
			args.palette,
			args.count,
			args.width,
			args.palette_num
		)
		
		if img:
			output_path = args.output or Path('sprites.png')
			img.save(output_path)
			print(f"✓ Extracted {args.count} sprite tiles to {output_path}")
		return 0
	
	print("Use --sprite-sheet, --metasprite, or --animation")
	return 0


if __name__ == '__main__':
	exit(main())
