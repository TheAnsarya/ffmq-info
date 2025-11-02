#!/usr/bin/env python3
"""
Sprite Import Tool
Imports edited PNG sprites back into ROM-ready format.

This tool takes edited sprite PNGs and converts them back to the format
needed for ROM insertion, including:
- PNG → 4BPP/2BPP tile conversion
- Palette → RGB555 conversion
- Sprite assembly into tile data
- Metadata validation

Usage:
	python import_sprites.py data/extracted/sprites/enemies/ data/rebuilt/sprites/
	python import_sprites.py sprite.png --output sprite.bin --metadata sprite_meta.json

Author: FFMQ Disassembly Project
Date: 2025-11-02
"""

import sys
import json
from pathlib import Path
from PIL import Image
from typing import List, Dict, Tuple, Optional
import struct

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))
from extraction.extract_graphics import RGB555Color


class SpriteImporter:
	"""Imports edited sprites back into ROM format."""

	def __init__(self):
		"""Initialize the sprite importer."""
		self.imported_count = 0
		self.error_count = 0

	def import_sprite_from_metadata(self, sprite_dir: Path, sprite_name: str) -> Optional[Dict]:
		"""
		Import a sprite using its metadata file.

		Args:
			sprite_dir: Directory containing sprite files
			sprite_name: Base name of sprite (without extension)

		Returns:
			Dictionary with imported sprite data, or None on error
		"""
		# Load metadata
		meta_path = sprite_dir / f"{sprite_name}_meta.json"
		if not meta_path.exists():
			print(f"  ❌ Metadata not found: {meta_path}")
			self.error_count += 1
			return None

		with open(meta_path, 'r') as f:
			metadata = json.load(f)

		# Load PNG
		png_path = sprite_dir / f"{sprite_name}.png"
		if not png_path.exists():
			print(f"  ❌ PNG not found: {png_path}")
			self.error_count += 1
			return None

		try:
			image = Image.open(png_path)
		except Exception as e:
			print(f"  ❌ Failed to load PNG: {e}")
			self.error_count += 1
			return None

		# Validate dimensions match metadata
		expected_width = metadata['tile_width'] * 8
		expected_height = metadata['tile_height'] * 8

		if image.size != (expected_width, expected_height):
			print(f"  ⚠️  Size mismatch: PNG is {image.size}, expected {expected_width}x{expected_height}")

		# Convert to tiles
		import sys
		from pathlib import Path as PathLib
		sys.path.insert(0, str(PathLib(__file__).parent))
		from png_to_tiles import PNGToTileConverter

		format = metadata.get('format', '4bpp')
		converter = PNGToTileConverter(format=format)

		try:
			tile_data, palette = converter.convert_png_to_tiles(png_path)
		except Exception as e:
			print(f"  ❌ Tile conversion failed: {e}")
			self.error_count += 1
			return None

		# Create sprite data structure
		sprite_data = {
			'name': sprite_name,
			'tile_data': tile_data,
			'palette': palette,
			'metadata': metadata,
			'rom_offset': metadata.get('rom_offset'),
			'palette_offset': metadata.get('palette_offset'),
			'size_bytes': len(tile_data)
		}

		self.imported_count += 1
		print(f"  ✓ Imported {sprite_name}: {len(tile_data)} bytes")

		return sprite_data

	def import_directory(self, input_dir: Path, output_dir: Path):
		"""
		Import all sprites from a directory.

		Args:
			input_dir: Directory containing edited sprites
			output_dir: Directory for output binary files
		"""
		print(f"\n📦 Importing sprites from {input_dir}...")

		# Find all metadata files
		meta_files = list(input_dir.glob("*_meta.json"))

		if not meta_files:
			print(f"  ⚠️  No metadata files found")
			return

		print(f"  Found {len(meta_files)} sprites")

		# Create output directory
		output_dir.mkdir(parents=True, exist_ok=True)

		# Import each sprite
		imported_sprites = []

		for meta_file in sorted(meta_files):
			sprite_name = meta_file.stem.replace('_meta', '')

			sprite_data = self.import_sprite_from_metadata(input_dir, sprite_name)

			if sprite_data:
				# Save binary tile data
				bin_path = output_dir / f"{sprite_name}.bin"
				with open(bin_path, 'wb') as f:
					f.write(sprite_data['tile_data'])

				# Save palette if present
				if 'palette' in sprite_data:
					pal_path = output_dir / f"{sprite_name}_palette.bin"
					self.save_palette_binary(sprite_data['palette'], pal_path)

				imported_sprites.append(sprite_data)

		# Create summary
		summary = {
			'total_sprites': len(imported_sprites),
			'total_bytes': sum(s['size_bytes'] for s in imported_sprites),
			'sprites': [
				{
					'name': s['name'],
					'size_bytes': s['size_bytes'],
					'rom_offset': s['rom_offset'],
					'palette_offset': s['palette_offset']
				}
				for s in imported_sprites
			]
		}

		summary_path = output_dir / 'import_summary.json'
		with open(summary_path, 'w') as f:
			json.dump(summary, f, indent=2)

		print(f"\n✅ Import complete:")
		print(f"   Imported: {self.imported_count}")
		print(f"   Errors: {self.error_count}")
		print(f"   Total bytes: {summary['total_bytes']:,}")
		print(f"   Summary: {summary_path}")

	def save_palette_binary(self, palette: List[Tuple[int, int, int, int]], output_path: Path):
		"""
		Save palette in binary RGB555 format.

		Args:
			palette: List of RGBA tuples
			output_path: Path to output binary file
		"""
		palette_data = bytearray()

		for r, g, b, a in palette:
			# Convert RGB888 to RGB555
			r5 = (r >> 3) & 0x1f
			g5 = (g >> 3) & 0x1f
			b5 = (b >> 3) & 0x1f

			rgb555 = (b5 << 10) | (g5 << 5) | r5

			# Write as little-endian 16-bit
			palette_data.extend(struct.pack('<H', rgb555))

		with open(output_path, 'wb') as f:
			f.write(palette_data)


def main():
	"""Main function for command-line usage."""
	import argparse

	parser = argparse.ArgumentParser(
		description='Import edited PNG sprites back to ROM format'
	)
	parser.add_argument('input', type=Path, help='Input directory or PNG file')
	parser.add_argument('output', type=Path, help='Output directory or binary file')
	parser.add_argument('--metadata', type=Path, help='Metadata JSON file (for single file import)')

	args = parser.parse_args()

	importer = SpriteImporter()

	# Check if importing directory or single file
	if args.input.is_dir():
		# Import entire directory
		importer.import_directory(args.input, args.output)
	else:
		# Import single sprite
		print(f"\n📦 Importing single sprite: {args.input}")

		# Get sprite name
		sprite_name = args.input.stem
		sprite_dir = args.input.parent

		sprite_data = importer.import_sprite_from_metadata(sprite_dir, sprite_name)

		if sprite_data:
			# Save to output
			args.output.parent.mkdir(parents=True, exist_ok=True)
			with open(args.output, 'wb') as f:
				f.write(sprite_data['tile_data'])

			print(f"✓ Saved to {args.output}")
			print(f"  Size: {len(sprite_data['tile_data'])} bytes")

			return 0
		else:
			return 1

	return 0 if importer.error_count == 0 else 1


if __name__ == '__main__':
	sys.exit(main())
