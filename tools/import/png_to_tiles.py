#!/usr/bin/env python3
"""
PNG to SNES Tile Converter
Converts PNG images back to 4BPP/2BPP SNES tile format for ROM insertion.

This is the import counterpart to extract_graphics.py, enabling round-trip editing:
Extract → Edit in PNG → Re-import → Build ROM

Features:
- PNG to 4BPP tile encoding
- PNG to 2BPP tile encoding
- Palette generation from PNG
- RGB888 → RGB555 color conversion
- Tile validation and error checking

Usage:
	python png_to_tiles.py input.png output.bin --format 4bpp --palette palette.json
	python png_to_tiles.py sprite.png sprite.bin --format 2bpp --auto-palette

Author: FFMQ Disassembly Project
Date: 2025-11-02
"""

import sys
import json
from pathlib import Path
from PIL import Image
from typing import List, Tuple, Optional, Dict
import struct

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))
from extraction.extract_graphics import RGB555Color


class PNGToTileConverter:
	"""Converts PNG images to SNES tile format (4BPP or 2BPP)."""
	
	def __init__(self, format: str = '4bpp'):
		"""
		Initialize the converter.
		
		Args:
			format: Tile format ('4bpp' or '2bpp')
		"""
		self.format = format.lower()
		self.bytes_per_tile = 32 if self.format == '4bpp' else 16
		self.colors_per_tile = 16 if self.format == '4bpp' else 4
		
	def rgb888_to_rgb555(self, r: int, g: int, b: int) -> int:
		"""
		Convert RGB888 (24-bit) to RGB555 (15-bit) SNES format.
		
		Args:
			r: Red component (0-255)
			g: Green component (0-255)
			b: Blue component (0-255)
			
		Returns:
			RGB555 value as 16-bit integer (0bbbbbgg gggrrrrr)
		"""
		# Convert 8-bit to 5-bit by dividing by 8 (right shift 3)
		r5 = (r >> 3) & 0x1f
		g5 = (g >> 3) & 0x1f
		b5 = (b >> 3) & 0x1f
		
		# Pack into RGB555 format: 0bbbbbgg gggrrrrr (BGR order, little-endian)
		rgb555 = (b5 << 10) | (g5 << 5) | r5
		return rgb555
	
	def create_palette_from_png(self, image: Image.Image) -> List[Tuple[int, int, int, int]]:
		"""
		Extract palette from PNG image.
		
		Args:
			image: PIL Image object
			
		Returns:
			List of (R, G, B, A) tuples for palette colors
			
		Raises:
			ValueError: If image has too many colors for format
		"""
		# Convert to RGBA if not already
		if image.mode != 'RGBA':
			image = image.convert('RGBA')
		
		# Get unique colors
		colors = set()
		width, height = image.size
		
		for y in range(height):
			for x in range(width):
				rgba = image.getpixel((x, y))
				colors.add(rgba)
		
		# Check color count
		max_colors = self.colors_per_tile
		if len(colors) > max_colors:
			raise ValueError(
				f"Image has {len(colors)} colors but {self.format} format supports max {max_colors}"
			)
		
		# Sort colors (transparent first, then by brightness)
		def color_brightness(rgba):
			r, g, b, a = rgba
			if a == 0:  # Transparent
				return -1
			return r + g + b
		
		palette = sorted(colors, key=color_brightness)
		
		# Pad to required size
		while len(palette) < max_colors:
			palette.append((0, 0, 0, 0))
		
		return palette
	
	def create_color_index_map(self, palette: List[Tuple[int, int, int, int]]) -> Dict[Tuple[int, int, int, int], int]:
		"""
		Create a mapping from RGBA colors to palette indices.
		
		Args:
			palette: List of RGBA tuples
			
		Returns:
			Dictionary mapping RGBA to index
		"""
		return {color: idx for idx, color in enumerate(palette)}
	
	def encode_tile_4bpp(self, pixels: List[List[int]]) -> bytes:
		"""
		Encode an 8x8 tile in 4BPP format.
		
		4BPP format uses 4 bitplanes (32 bytes per tile):
		- Bitplane 0-1: Bytes 0-15 (2 bytes per row)
		- Bitplane 2-3: Bytes 16-31 (2 bytes per row)
		
		Args:
			pixels: 8x8 array of palette indices (0-15)
			
		Returns:
			32 bytes of 4BPP tile data
		"""
		tile_data = bytearray(32)
		
		for row in range(8):
			# Get 8 pixels for this row
			row_pixels = pixels[row]
			
			# Encode bitplane 0 (bit 0 of each pixel)
			bp0 = 0
			for col in range(8):
				if row_pixels[col] & 0x01:
					bp0 |= (1 << (7 - col))
			
			# Encode bitplane 1 (bit 1 of each pixel)
			bp1 = 0
			for col in range(8):
				if row_pixels[col] & 0x02:
					bp1 |= (1 << (7 - col))
			
			# Encode bitplane 2 (bit 2 of each pixel)
			bp2 = 0
			for col in range(8):
				if row_pixels[col] & 0x04:
					bp2 |= (1 << (7 - col))
			
			# Encode bitplane 3 (bit 3 of each pixel)
			bp3 = 0
			for col in range(8):
				if row_pixels[col] & 0x08:
					bp3 |= (1 << (7 - col))
			
			# Write bitplanes to tile data
			tile_data[row * 2] = bp0
			tile_data[row * 2 + 1] = bp1
			tile_data[16 + row * 2] = bp2
			tile_data[16 + row * 2 + 1] = bp3
		
		return bytes(tile_data)
	
	def encode_tile_2bpp(self, pixels: List[List[int]]) -> bytes:
		"""
		Encode an 8x8 tile in 2BPP format.
		
		2BPP format uses 2 bitplanes (16 bytes per tile):
		- 2 bytes per row (bitplane 0 and 1)
		
		Args:
			pixels: 8x8 array of palette indices (0-3)
			
		Returns:
			16 bytes of 2BPP tile data
		"""
		tile_data = bytearray(16)
		
		for row in range(8):
			# Get 8 pixels for this row
			row_pixels = pixels[row]
			
			# Encode bitplane 0 (bit 0 of each pixel)
			bp0 = 0
			for col in range(8):
				if row_pixels[col] & 0x01:
					bp0 |= (1 << (7 - col))
			
			# Encode bitplane 1 (bit 1 of each pixel)
			bp1 = 0
			for col in range(8):
				if row_pixels[col] & 0x02:
					bp1 |= (1 << (7 - col))
			
			# Write bitplanes to tile data
			tile_data[row * 2] = bp0
			tile_data[row * 2 + 1] = bp1
		
		return bytes(tile_data)
	
	def convert_png_to_tiles(self, png_path: Path) -> Tuple[bytes, List[Tuple[int, int, int, int]]]:
		"""
		Convert a PNG image to SNES tile format.
		
		Args:
			png_path: Path to PNG file
			
		Returns:
			Tuple of (tile_data_bytes, palette)
			
		Raises:
			ValueError: If image dimensions aren't multiples of 8
		"""
		# Load image
		image = Image.open(png_path)
		width, height = image.size
		
		# Validate dimensions
		if width % 8 != 0 or height % 8 != 0:
			raise ValueError(
				f"Image dimensions must be multiples of 8. Got {width}x{height}"
			)
		
		# Create palette from image
		palette = self.create_palette_from_png(image)
		color_map = self.create_color_index_map(palette)
		
		# Convert to RGBA if needed
		if image.mode != 'RGBA':
			image = image.convert('RGBA')
		
		# Calculate number of tiles
		tiles_x = width // 8
		tiles_y = height // 8
		total_tiles = tiles_x * tiles_y
		
		# Convert each tile
		all_tile_data = bytearray()
		
		for tile_y in range(tiles_y):
			for tile_x in range(tiles_x):
				# Extract 8x8 tile pixels
				tile_pixels = []
				for row in range(8):
					pixel_row = []
					y = tile_y * 8 + row
					for col in range(8):
						x = tile_x * 8 + col
						rgba = image.getpixel((x, y))
						palette_index = color_map[rgba]
						pixel_row.append(palette_index)
					tile_pixels.append(pixel_row)
				
				# Encode tile
				if self.format == '4bpp':
					tile_data = self.encode_tile_4bpp(tile_pixels)
				else:
					tile_data = self.encode_tile_2bpp(tile_pixels)
				
				all_tile_data.extend(tile_data)
		
		print(f"✓ Converted {total_tiles} tiles from {width}x{height} PNG")
		print(f"  Format: {self.format.upper()}")
		print(f"  Colors: {len([c for c in palette if c[3] > 0])}")
		
		return bytes(all_tile_data), palette
	
	def save_palette_json(self, palette: List[Tuple[int, int, int, int]], output_path: Path):
		"""
		Save palette to JSON file in FFMQ format.
		
		Args:
			palette: List of RGBA tuples
			output_path: Path to output JSON file
		"""
		palette_data = {
			"format": "RGB555",
			"colors": []
		}
		
		for idx, (r, g, b, a) in enumerate(palette):
			rgb555 = self.rgb888_to_rgb555(r, g, b)
			
			color_entry = {
				"index": idx,
				"rgb555": rgb555,
				"rgb888": {
					"r": r,
					"g": g,
					"b": b,
					"a": a
				},
				"hex": f"#{r:02x}{g:02x}{b:02x}",
				"name": f"Color{idx:02d}"
			}
			
			palette_data["colors"].append(color_entry)
		
		with open(output_path, 'w') as f:
			json.dump(palette_data, f, indent=2)
		
		print(f"✓ Saved palette to {output_path}")


def main():
	"""Main function for command-line usage."""
	import argparse
	
	parser = argparse.ArgumentParser(
		description='Convert PNG images to SNES tile format (4BPP or 2BPP)'
	)
	parser.add_argument('input', type=Path, help='Input PNG file')
	parser.add_argument('output', type=Path, help='Output binary file (.bin)')
	parser.add_argument('--format', choices=['4bpp', '2bpp'], default='4bpp',
						help='Tile format (default: 4bpp)')
	parser.add_argument('--palette', type=Path, help='Output palette JSON file')
	parser.add_argument('--auto-palette', action='store_true',
						help='Auto-generate palette filename from output')
	
	args = parser.parse_args()
	
	# Create converter
	converter = PNGToTileConverter(format=args.format)
	
	# Convert PNG to tiles
	print(f"\n🎨 Converting PNG to {args.format.upper()} tiles...")
	print(f"   Input: {args.input}")
	
	try:
		tile_data, palette = converter.convert_png_to_tiles(args.input)
		
		# Save tile data
		args.output.parent.mkdir(parents=True, exist_ok=True)
		with open(args.output, 'wb') as f:
			f.write(tile_data)
		
		print(f"✓ Saved {len(tile_data)} bytes to {args.output}")
		
		# Save palette if requested
		palette_path = args.palette
		if args.auto_palette and not palette_path:
			palette_path = args.output.with_suffix('.json')
		
		if palette_path:
			converter.save_palette_json(palette, palette_path)
		
		print("\n✅ Conversion complete!")
		
	except Exception as e:
		print(f"\n❌ Error: {e}")
		return 1
	
	return 0


if __name__ == '__main__':
	sys.exit(main())
