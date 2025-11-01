#!/usr/bin/env python3
"""
FFMQ Graphics Converter
Converts SNES 4bpp/8bpp tile data to PNG images
Handles BGR555 palette format
"""

import os
import sys
import json
from pathlib import Path
from typing import List, Tuple

try:
	from PIL import Image
except ImportError:
	print("ERROR: Pillow library required. Install with: pip install Pillow")
	sys.exit(1)

class SNESGraphicsConverter:
	"""Convert SNES graphics to PNG format"""

	def __init__(self, input_base: str = "data", output_base: str = "data"):
		self.input_base = Path(input_base)
		self.output_base = Path(output_base)

	def bgr555_to_rgb(self, color: int) -> Tuple[int, int, int]:
		"""Convert SNES BGR555 color to RGB888"""
		# BGR555 format: 0bbbbbgg gggrrrrr
		r = (color & 0x001f) << 3  # 5 bits -> 8 bits
		g = ((color & 0x03e0) >> 5) << 3
		b = ((color & 0x7c00) >> 10) << 3

		# Expand 5-bit to 8-bit (repeat top 3 bits in bottom 3 bits)
		r |= (r >> 5)
		g |= (g >> 5)
		b |= (b >> 5)

		return (r, g, b)

	def decode_4bpp_tile(self, tile_data: bytes) -> List[int]:
		"""Decode SNES 4bpp tile (8x8 pixels, 32 bytes)"""
		pixels = []

		# 4bpp format: 2 bitplanes per row, 8 rows
		for row in range(8):
			offset = row * 2
			plane0 = tile_data[offset]
			plane1 = tile_data[offset + 1]
			plane2 = tile_data[offset + 16]
			plane3 = tile_data[offset + 17]

			for bit in range(7, -1, -1):
				pixel = 0
				if plane0 & (1 << bit):
					pixel |= 0x01
				if plane1 & (1 << bit):
					pixel |= 0x02
				if plane2 & (1 << bit):
					pixel |= 0x04
				if plane3 & (1 << bit):
					pixel |= 0x08
				pixels.append(pixel)

		return pixels

	def decode_8bpp_tile(self, tile_data: bytes) -> List[int]:
		"""Decode SNES 8bpp tile (8x8 pixels, 64 bytes)"""
		pixels = []

		# 8bpp format: 4 bitplanes per row, 8 rows
		for row in range(8):
			offset = row * 2
			planes = [
				tile_data[offset],
				tile_data[offset + 1],
				tile_data[offset + 16],
				tile_data[offset + 17],
				tile_data[offset + 32],
				tile_data[offset + 33],
				tile_data[offset + 48],
				tile_data[offset + 49]
			]

			for bit in range(7, -1, -1):
				pixel = 0
				for i, plane in enumerate(planes):
					if plane & (1 << bit):
						pixel |= (1 << i)
				pixels.append(pixel)

		return pixels

	def convert_tiles_to_png(self, input_file: Path, output_file: Path,
							 bpp: int = 4, tiles_per_row: int = 16,
							 palette: List[Tuple[int, int, int]] = None):
		"""Convert tile data to PNG image"""

		# Load tile data
		tile_data = input_file.read_bytes()

		# Calculate tile dimensions
		bytes_per_tile = 32 if bpp == 4 else 64
		num_tiles = len(tile_data) // bytes_per_tile

		if num_tiles == 0:
			print(f"WARNING: No complete tiles in {input_file.name}")
			return False

		# Calculate image dimensions
		rows = (num_tiles + tiles_per_row - 1) // tiles_per_row
		width = tiles_per_row * 8
		height = rows * 8

		# Create default palette if none provided
		if palette is None:
			# Grayscale palette
			palette = [(i * 17, i * 17, i * 17) for i in range(16 if bpp == 4 else 256)]

		# Create image
		img = Image.new('RGB', (width, height), color=(0, 0, 0))
		pixels = img.load()

		# Decode tiles
		decode_func = self.decode_4bpp_tile if bpp == 4 else self.decode_8bpp_tile

		for tile_idx in range(num_tiles):
			tile_offset = tile_idx * bytes_per_tile
			tile_pixels = decode_func(tile_data[tile_offset:tile_offset + bytes_per_tile])

			# Calculate tile position in image
			tile_x = (tile_idx % tiles_per_row) * 8
			tile_y = (tile_idx // tiles_per_row) * 8

			# Draw tile
			for py in range(8):
				for px in range(8):
					pixel_idx = py * 8 + px
					color_idx = tile_pixels[pixel_idx]
					color = palette[color_idx % len(palette)]
					pixels[tile_x + px, tile_y + py] = color

		# Save PNG
		output_file.parent.mkdir(parents=True, exist_ok=True)
		img.save(output_file)

		print(f"CONVERTED: {input_file.name} -> {output_file.name} ({num_tiles} tiles, {width}x{height}px)")

		# Save metadata
		metadata = {
			"source_file": str(input_file.relative_to(self.input_base.parent)),
			"output_file": str(output_file.relative_to(self.output_base.parent)),
			"bpp": bpp,
			"num_tiles": num_tiles,
			"tiles_per_row": tiles_per_row,
			"width": width,
			"height": height,
			"palette": "default_grayscale" if palette is None else "custom"
		}

		metadata_file = output_file.with_suffix('.json')
		with open(metadata_file, 'w') as f:
			json.dump(metadata, f, indent=2)

		return True

	def convert_all_graphics(self):
		"""Convert all graphics in data/graphics/ to PNG"""

		graphics_dir = self.input_base / "graphics"
		if not graphics_dir.exists():
			print(f"ERROR: Graphics directory not found: {graphics_dir}")
			return False

		# Find all .bin files
		bin_files = list(graphics_dir.glob("*.bin"))

		print(f"Found {len(bin_files)} binary graphics files")

		for bin_file in bin_files:
			# Output to data/graphics/2_converted_png/
			output_file = self.output_base / "graphics" / "2_converted_png" / bin_file.with_suffix('.png').name

			# Convert (assume 4bpp for now, can be adjusted per file)
			self.convert_tiles_to_png(bin_file, output_file, bpp=4, tiles_per_row=16)

		return True

def main():
	"""Main entry point"""

	print("=" * 70)
	print("FFMQ GRAPHICS CONVERTER")
	print("=" * 70)

	converter = SNESGraphicsConverter()
	success = converter.convert_all_graphics()

	print("\n" + "=" * 70)
	print("CONVERSION COMPLETE" if success else "CONVERSION FAILED")
	print("=" * 70)

	sys.exit(0 if success else 1)

if __name__ == "__main__":
	main()
