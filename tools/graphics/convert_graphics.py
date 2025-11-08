#!/usr/bin/env python3
"""
SNES Graphics to PNG Converter
Convert between SNES tile formats and PNG images for editing
"""

import os
import sys
from typing import List, Tuple, Optional
from snes_graphics import SNESTile, SNESPalette, SNESColor, decode_tiles, encode_tiles

try:
	from PIL import Image
except ImportError:
	print("Error: Pillow (PIL) required. Install with: pip install Pillow")
	sys.exit(1)


class TileImageConverter:
	"""Convert between SNES tiles and PNG images"""
	
	@staticmethod
	def tiles_to_image(
		tiles: List[SNESTile],
		palette: SNESPalette,
		tiles_per_row: int = 16,
		tile_width: int = 8,
		tile_height: int = 8
	) -> Image.Image:
		"""
		Convert SNES tiles to PNG image
		
		Args:
			tiles: List of SNESTile objects
			palette: SNESPalette to use for colors
			tiles_per_row: Number of tiles per row in output image
			tile_width: Width of each tile in pixels
			tile_height: Height of each tile in pixels
		
		Returns:
			PIL Image object
		"""
		tile_count = len(tiles)
		rows = (tile_count + tiles_per_row - 1) // tiles_per_row
		
		img_width = tiles_per_row * tile_width
		img_height = rows * tile_height
		
		# Create RGB image
		img = Image.new('RGB', (img_width, img_height), color=(0, 0, 0))
		pixels = img.load()
		
		for tile_idx, tile in enumerate(tiles):
			tile_x = (tile_idx % tiles_per_row) * tile_width
			tile_y = (tile_idx // tiles_per_row) * tile_height
			
			for y in range(tile_height):
				for x in range(tile_width):
					palette_idx = tile.get_pixel(x, y)
					if palette_idx < len(palette.colors):
						color = palette.colors[palette_idx].to_rgb888()
					else:
						color = (0, 0, 0)
					
					img_x = tile_x + x
					img_y = tile_y + y
					pixels[img_x, img_y] = color
		
		return img
	
	@staticmethod
	def tiles_to_indexed_image(
		tiles: List[SNESTile],
		palette: SNESPalette,
		tiles_per_row: int = 16,
		tile_width: int = 8,
		tile_height: int = 8
	) -> Image.Image:
		"""
		Convert SNES tiles to indexed PNG image (palette mode)
		This preserves exact palette indices for round-trip conversion
		
		Args:
			tiles: List of SNESTile objects
			palette: SNESPalette to use for colors
			tiles_per_row: Number of tiles per row in output image
			tile_width: Width of each tile in pixels
			tile_height: Height of each tile in pixels
		
		Returns:
			PIL Image object in palette mode
		"""
		tile_count = len(tiles)
		rows = (tile_count + tiles_per_row - 1) // tiles_per_row
		
		img_width = tiles_per_row * tile_width
		img_height = rows * tile_height
		
		# Create indexed image
		img = Image.new('P', (img_width, img_height), color=0)
		
		# Set palette (PIL expects RGB triplets)
		pal_data = []
		for i in range(256):
			if i < len(palette.colors):
				r, g, b = palette.colors[i].to_rgb888()
			else:
				r, g, b = 0, 0, 0
			pal_data.extend([r, g, b])
		img.putpalette(pal_data)
		
		pixels = img.load()
		
		for tile_idx, tile in enumerate(tiles):
			tile_x = (tile_idx % tiles_per_row) * tile_width
			tile_y = (tile_idx // tiles_per_row) * tile_height
			
			for y in range(tile_height):
				for x in range(tile_width):
					palette_idx = tile.get_pixel(x, y)
					img_x = tile_x + x
					img_y = tile_y + y
					pixels[img_x, img_y] = palette_idx
		
		return img
	
	@staticmethod
	def image_to_tiles(
		img: Image.Image,
		tile_width: int = 8,
		tile_height: int = 8,
		bpp: int = 4
	) -> Tuple[List[SNESTile], Optional[SNESPalette]]:
		"""
		Convert PNG image to SNES tiles
		
		Args:
			img: PIL Image object
			tile_width: Width of each tile in pixels
			tile_height: Height of each tile in pixels
			bpp: Bits per pixel (2, 4, or 8)
		
		Returns:
			Tuple of (tiles list, palette or None)
		"""
		tiles = []
		palette = None
		
		# Handle indexed images (palette mode)
		if img.mode == 'P':
			pal_data = img.getpalette()
			colors = []
			for i in range(256):
				r = pal_data[i * 3]
				g = pal_data[i * 3 + 1]
				b = pal_data[i * 3 + 2]
				colors.append(SNESColor.from_rgb888(r, g, b))
			palette = SNESPalette(colors)
			
			pixels = img.load()
		else:
			# Convert RGB/RGBA to indexed by quantizing
			if img.mode != 'RGB':
				img = img.convert('RGB')
			
			# Quantize to appropriate number of colors
			max_colors = 2 ** bpp
			quantized = img.quantize(colors=max_colors)
			
			pal_data = quantized.getpalette()
			colors = []
			for i in range(max_colors):
				r = pal_data[i * 3] if pal_data else 0
				g = pal_data[i * 3 + 1] if pal_data else 0
				b = pal_data[i * 3 + 2] if pal_data else 0
				colors.append(SNESColor.from_rgb888(r, g, b))
			palette = SNESPalette(colors)
			
			pixels = quantized.load()
			img = quantized
		
		# Extract tiles
		img_width, img_height = img.size
		tiles_wide = img_width // tile_width
		tiles_high = img_height // tile_height
		
		for tile_y in range(tiles_high):
			for tile_x in range(tiles_wide):
				tile = SNESTile(tile_width, tile_height)
				
				for y in range(tile_height):
					for x in range(tile_width):
						img_x = tile_x * tile_width + x
						img_y = tile_y * tile_height + y
						if img_x < img_width and img_y < img_height:
							tile.set_pixel(x, y, pixels[img_x, img_y])
				
				tiles.append(tile)
		
		return tiles, palette


def convert_snes_to_png(
	input_file: str,
	output_file: str,
	palette_file: Optional[str] = None,
	bpp: int = 4,
	tiles_per_row: int = 16,
	tile_count: Optional[int] = None,
	offset: int = 0,
	indexed: bool = False
) -> bool:
	"""
	Convert SNES tile data to PNG image
	
	Args:
		input_file: Path to raw SNES tile data file
		output_file: Path to output PNG file
		palette_file: Path to SNES palette file (optional, generates grayscale if missing)
		bpp: Bits per pixel (2, 4, or 8)
		tiles_per_row: Number of tiles per row in output
		tile_count: Number of tiles to convert (None = all)
		offset: Starting offset in input file
		indexed: Output indexed PNG instead of RGB
	
	Returns:
		True if successful
	"""
	try:
		# Load tile data
		with open(input_file, 'rb') as f:
			data = f.read()
		
		# Calculate tile count if not specified
		if tile_count is None:
			bytes_per_tile = (bpp * 64) // 8
			tile_count = (len(data) - offset) // bytes_per_tile
		
		# Decode tiles
		tiles = decode_tiles(data, offset, tile_count, bpp)
		
		# Load or generate palette
		if palette_file and os.path.exists(palette_file):
			with open(palette_file, 'rb') as f:
				pal_data = f.read()
			palette = SNESPalette.from_bytes(pal_data, count=2 ** bpp)
		else:
			# Generate grayscale palette
			colors = []
			max_colors = 2 ** bpp
			for i in range(max_colors):
				intensity = (i * 31) // (max_colors - 1) if max_colors > 1 else 0
				colors.append(SNESColor(intensity, intensity, intensity))
			palette = SNESPalette(colors)
		
		# Convert to image
		if indexed:
			img = TileImageConverter.tiles_to_indexed_image(tiles, palette, tiles_per_row)
		else:
			img = TileImageConverter.tiles_to_image(tiles, palette, tiles_per_row)
		
		# Save PNG
		img.save(output_file)
		print(f"Converted {len(tiles)} tiles to {output_file}")
		return True
		
	except Exception as e:
		print(f"Error converting SNES to PNG: {e}")
		import traceback
		traceback.print_exc()
		return False


def convert_png_to_snes(
	input_file: str,
	output_file: str,
	palette_file: Optional[str] = None,
	bpp: int = 4,
	tile_width: int = 8,
	tile_height: int = 8
) -> bool:
	"""
	Convert PNG image to SNES tile data
	
	Args:
		input_file: Path to input PNG file
		output_file: Path to output raw SNES tile data file
		palette_file: Path to output SNES palette file (optional)
		bpp: Bits per pixel (2, 4, or 8)
		tile_width: Width of each tile in pixels
		tile_height: Height of each tile in pixels
	
	Returns:
		True if successful
	"""
	try:
		# Load PNG
		img = Image.open(input_file)
		
		# Convert to tiles
		tiles, palette = TileImageConverter.image_to_tiles(img, tile_width, tile_height, bpp)
		
		# Encode tiles
		tile_data = encode_tiles(tiles, bpp)
		
		# Save tile data
		with open(output_file, 'wb') as f:
			f.write(tile_data)
		
		print(f"Converted {len(tiles)} tiles to {output_file}")
		
		# Save palette if requested
		if palette_file and palette:
			with open(palette_file, 'wb') as f:
				f.write(palette.to_bytes())
			print(f"Saved palette to {palette_file}")
		
		return True
		
	except Exception as e:
		print(f"Error converting PNG to SNES: {e}")
		import traceback
		traceback.print_exc()
		return False


def main():
	"""Command-line interface"""
	import argparse
	
	parser = argparse.ArgumentParser(
		description='Convert between SNES tile data and PNG images'
	)
	
	subparsers = parser.add_subparsers(dest='command', help='Command to execute')
	
	# SNES to PNG
	to_png = subparsers.add_parser('to-png', help='Convert SNES tiles to PNG')
	to_png.add_argument('input', help='Input SNES tile file (.bin)')
	to_png.add_argument('output', help='Output PNG file (.png)')
	to_png.add_argument('--palette', '-p', help='SNES palette file (.bin)')
	to_png.add_argument('--bpp', '-b', type=int, choices=[2, 4, 8], default=4,
						help='Bits per pixel (default: 4)')
	to_png.add_argument('--tiles-per-row', '-r', type=int, default=16,
						help='Tiles per row (default: 16)')
	to_png.add_argument('--count', '-c', type=int, help='Number of tiles to convert')
	to_png.add_argument('--offset', '-o', type=int, default=0,
						help='Starting offset in file (default: 0)')
	to_png.add_argument('--indexed', '-i', action='store_true',
						help='Output indexed PNG (preserves exact palette)')
	
	# PNG to SNES
	to_snes = subparsers.add_parser('to-snes', help='Convert PNG to SNES tiles')
	to_snes.add_argument('input', help='Input PNG file (.png)')
	to_snes.add_argument('output', help='Output SNES tile file (.bin)')
	to_snes.add_argument('--palette', '-p', help='Output SNES palette file (.bin)')
	to_snes.add_argument('--bpp', '-b', type=int, choices=[2, 4, 8], default=4,
						help='Bits per pixel (default: 4)')
	to_snes.add_argument('--tile-width', '-w', type=int, default=8,
						help='Tile width (default: 8)')
	to_snes.add_argument('--tile-height', '-h', type=int, default=8,
						help='Tile height (default: 8)')
	
	args = parser.parse_args()
	
	if args.command == 'to-png':
		success = convert_snes_to_png(
			args.input, args.output, args.palette,
			args.bpp, args.tiles_per_row, args.count, args.offset, args.indexed
		)
	elif args.command == 'to-snes':
		success = convert_png_to_snes(
			args.input, args.output, args.palette,
			args.bpp, args.tile_width, args.tile_height
		)
	else:
		parser.print_help()
		sys.exit(1)
	
	sys.exit(0 if success else 1)


if __name__ == '__main__':
	main()
