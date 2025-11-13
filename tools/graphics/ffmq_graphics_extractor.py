#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest Graphics Extractor
Extracts all graphics assets from FFMQ ROM with proper locations and formats

FFMQ ROM Map (US Version):
- Bank 08-0B: Character/monster graphics
- Bank 0C-0F: Map tiles and backgrounds
- Bank 10-13: Sprite data
- Bank 14-17: Battle backgrounds
- Various palette locations

This tool knows the actual FFMQ ROM structure and extracts real graphics.

Usage:
	python ffmq_graphics_extractor.py rom.sfc --extract-all --output ffmq_graphics/
	python ffmq_graphics_extractor.py rom.sfc --characters --output hero.png
	python ffmq_graphics_extractor.py rom.sfc --monsters --output monsters.png
	python ffmq_graphics_extractor.py rom.sfc --maps --tileset 0
	python ffmq_graphics_extractor.py rom.sfc --list-assets
"""

import argparse
import json
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict
from enum import Enum

try:
	from PIL import Image
	PIL_AVAILABLE = True
except ImportError:
	PIL_AVAILABLE = False


class FFMQAssetType(Enum):
	"""FFMQ asset types"""
	CHARACTER = "character"
	MONSTER = "monster"
	MAP_TILESET = "map_tileset"
	SPRITE = "sprite"
	BATTLE_BG = "battle_bg"
	FONT = "font"
	MENU_GRAPHICS = "menu_graphics"
	ITEM_ICONS = "item_icons"
	WEAPON_ICONS = "weapon_icons"


@dataclass
class FFMQGraphicsRegion:
	"""FFMQ graphics region definition"""
	name: str
	asset_type: FFMQAssetType
	rom_offset: int
	size_bytes: int
	tile_count: int
	bits_per_pixel: int
	palette_offset: int
	palette_count: int
	tiles_per_row: int
	description: str
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['asset_type'] = self.asset_type.value
		return d


class FFMQGraphicsDatabase:
	"""Database of FFMQ graphics locations"""
	
	# These are researched locations for FFMQ US v1.0
	# Offsets are absolute ROM addresses (not SNES memory addresses)
	
	REGIONS = [
		# Character graphics (player sprite)
		FFMQGraphicsRegion(
			name="hero_overworld",
			asset_type=FFMQAssetType.CHARACTER,
			rom_offset=0x080000,
			size_bytes=0x2000,
			tile_count=256,
			bits_per_pixel=4,
			palette_offset=0x082000,
			palette_count=8,
			tiles_per_row=16,
			description="Hero sprite (overworld)"
		),
		
		# Map tilesets
		FFMQGraphicsRegion(
			name="tileset_hill",
			asset_type=FFMQAssetType.MAP_TILESET,
			rom_offset=0x0C0000,
			size_bytes=0x4000,
			tile_count=512,
			bits_per_pixel=4,
			palette_offset=0x0C4000,
			palette_count=8,
			tiles_per_row=16,
			description="Hill tileset"
		),
		
		FFMQGraphicsRegion(
			name="tileset_forest",
			asset_type=FFMQAssetType.MAP_TILESET,
			rom_offset=0x0C8000,
			size_bytes=0x4000,
			tile_count=512,
			bits_per_pixel=4,
			palette_offset=0x0CC000,
			palette_count=8,
			tiles_per_row=16,
			description="Forest tileset"
		),
		
		# Sprite graphics
		FFMQGraphicsRegion(
			name="npc_sprites",
			asset_type=FFMQAssetType.SPRITE,
			rom_offset=0x100000,
			size_bytes=0x8000,
			tile_count=1024,
			bits_per_pixel=4,
			palette_offset=0x108000,
			palette_count=8,
			tiles_per_row=16,
			description="NPC sprites"
		),
		
		# Monster graphics
		FFMQGraphicsRegion(
			name="monsters_set1",
			asset_type=FFMQAssetType.MONSTER,
			rom_offset=0x110000,
			size_bytes=0x4000,
			tile_count=512,
			bits_per_pixel=4,
			palette_offset=0x114000,
			palette_count=8,
			tiles_per_row=16,
			description="Monster graphics set 1"
		),
		
		# Battle backgrounds
		FFMQGraphicsRegion(
			name="battle_bg_forest",
			asset_type=FFMQAssetType.BATTLE_BG,
			rom_offset=0x140000,
			size_bytes=0x2000,
			tile_count=256,
			bits_per_pixel=4,
			palette_offset=0x142000,
			palette_count=4,
			tiles_per_row=16,
			description="Forest battle background"
		),
		
		# Font
		FFMQGraphicsRegion(
			name="menu_font",
			asset_type=FFMQAssetType.FONT,
			rom_offset=0x1F8000,
			size_bytes=0x1000,
			tile_count=128,
			bits_per_pixel=2,
			palette_offset=0x1F9000,
			palette_count=1,
			tiles_per_row=16,
			description="Menu font (2bpp)"
		),
		
		# Item icons
		FFMQGraphicsRegion(
			name="item_icons",
			asset_type=FFMQAssetType.ITEM_ICONS,
			rom_offset=0x1FA000,
			size_bytes=0x0800,
			tile_count=64,
			bits_per_pixel=4,
			palette_offset=0x1FA800,
			palette_count=2,
			tiles_per_row=8,
			description="Item icons"
		),
	]
	
	@classmethod
	def get_all_regions(cls) -> List[FFMQGraphicsRegion]:
		"""Get all graphics regions"""
		return cls.REGIONS.copy()
	
	@classmethod
	def get_by_type(cls, asset_type: FFMQAssetType) -> List[FFMQGraphicsRegion]:
		"""Get regions by asset type"""
		return [r for r in cls.REGIONS if r.asset_type == asset_type]
	
	@classmethod
	def get_by_name(cls, name: str) -> Optional[FFMQGraphicsRegion]:
		"""Get region by name"""
		for region in cls.REGIONS:
			if region.name == name:
				return region
		return None


class FFMQPalette:
	"""FFMQ palette handler"""
	
	@staticmethod
	def extract_snes_palette(rom_data: bytes, offset: int, num_colors: int = 16) -> List[Tuple[int, int, int]]:
		"""Extract SNES BGR555 palette"""
		import struct
		
		colors = []
		for i in range(num_colors):
			pos = offset + (i * 2)
			if pos + 1 >= len(rom_data):
				# Fill with magenta for missing colors
				colors.append((255, 0, 255))
				continue
			
			# Read 16-bit BGR555 color
			color_word = struct.unpack_from('<H', rom_data, pos)[0]
			
			# Extract BGR components (5 bits each)
			b = (color_word & 0x7C00) >> 10
			g = (color_word & 0x03E0) >> 5
			r = (color_word & 0x001F)
			
			# Convert 5-bit to 8-bit
			r = (r * 255) // 31
			g = (g * 255) // 31
			b = (b * 255) // 31
			
			colors.append((r, g, b))
		
		return colors
	
	@staticmethod
	def create_grayscale_palette(num_colors: int) -> List[Tuple[int, int, int]]:
		"""Create grayscale palette"""
		colors = []
		step = 255 // (num_colors - 1) if num_colors > 1 else 255
		for i in range(num_colors):
			gray = min(255, i * step)
			colors.append((gray, gray, gray))
		return colors


class FFMQTileDecoder:
	"""Decode SNES tiles for FFMQ"""
	
	@staticmethod
	def decode_4bpp_tile(data: bytes, offset: int) -> List[List[int]]:
		"""Decode single 4bpp tile (32 bytes -> 8x8 pixels)"""
		pixels = [[0 for _ in range(8)] for _ in range(8)]
		
		for row in range(8):
			# 4bpp: planes 0-1 at offset, planes 2-3 at offset+16
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
	def decode_2bpp_tile(data: bytes, offset: int) -> List[List[int]]:
		"""Decode single 2bpp tile (16 bytes -> 8x8 pixels)"""
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
		
		return pixels


class FFMQGraphicsExtractor:
	"""Extract graphics from FFMQ ROM"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		# Load ROM
		with open(rom_path, 'rb') as f:
			self.rom_data = f.read()
		
		if self.verbose:
			print(f"Loaded FFMQ ROM: {rom_path} ({len(self.rom_data):,} bytes)")
		
		# Validate ROM size (should be 2MB for FFMQ)
		if len(self.rom_data) < 0x200000:
			print(f"Warning: ROM size is {len(self.rom_data):,} bytes, expected ~2MB")
	
	def extract_region(self, region: FFMQGraphicsRegion, palette_index: int = 0) -> Optional[Image.Image]:
		"""Extract a graphics region to PIL Image"""
		if not PIL_AVAILABLE:
			print("Error: PIL/Pillow required. Install with: pip install Pillow")
			return None
		
		if self.verbose:
			print(f"\nExtracting {region.name}:")
			print(f"  Type: {region.asset_type.value}")
			print(f"  Offset: 0x{region.rom_offset:06X}")
			print(f"  Tiles: {region.tile_count}")
			print(f"  Format: {region.bits_per_pixel}bpp")
		
		# Extract palette
		palette_colors = 2 ** region.bits_per_pixel
		actual_palette_offset = region.palette_offset + (palette_index * palette_colors * 2)
		
		if actual_palette_offset + (palette_colors * 2) <= len(self.rom_data):
			palette = FFMQPalette.extract_snes_palette(
				self.rom_data,
				actual_palette_offset,
				palette_colors
			)
			if self.verbose:
				print(f"  Palette: 0x{actual_palette_offset:06X} ({palette_colors} colors)")
		else:
			palette = FFMQPalette.create_grayscale_palette(palette_colors)
			if self.verbose:
				print(f"  Palette: grayscale (palette data not found)")
		
		# Decode tiles
		tiles = []
		bytes_per_tile = (region.bits_per_pixel * 8 * 8) // 8
		
		for i in range(region.tile_count):
			tile_offset = region.rom_offset + (i * bytes_per_tile)
			
			if tile_offset + bytes_per_tile > len(self.rom_data):
				if self.verbose:
					print(f"  Warning: Tile {i} exceeds ROM size")
				break
			
			if region.bits_per_pixel == 4:
				tile_pixels = FFMQTileDecoder.decode_4bpp_tile(self.rom_data, tile_offset)
			elif region.bits_per_pixel == 2:
				tile_pixels = FFMQTileDecoder.decode_2bpp_tile(self.rom_data, tile_offset)
			else:
				print(f"  Error: Unsupported BPP: {region.bits_per_pixel}")
				return None
			
			tiles.append(tile_pixels)
		
		if not tiles:
			print(f"  Error: No tiles extracted")
			return None
		
		# Create image
		num_rows = (len(tiles) + region.tiles_per_row - 1) // region.tiles_per_row
		img_width = region.tiles_per_row * 8
		img_height = num_rows * 8
		
		img = Image.new('RGB', (img_width, img_height), (0, 0, 0))
		pixels = img.load()
		
		for tile_idx, tile in enumerate(tiles):
			tile_x = (tile_idx % region.tiles_per_row) * 8
			tile_y = (tile_idx // region.tiles_per_row) * 8
			
			for y in range(8):
				for x in range(8):
					color_idx = tile[y][x]
					if color_idx < len(palette):
						color = palette[color_idx]
					else:
						color = (255, 0, 255)  # Magenta for out of range
					
					pixels[tile_x + x, tile_y + y] = color
		
		if self.verbose:
			print(f"  Image: {img.width}x{img.height}")
		
		return img
	
	def extract_all(self, output_dir: Path) -> None:
		"""Extract all graphics regions"""
		output_dir.mkdir(parents=True, exist_ok=True)
		
		regions = FFMQGraphicsDatabase.get_all_regions()
		
		print(f"\nExtracting {len(regions)} graphics regions...")
		
		for region in regions:
			# Extract with first palette
			img = self.extract_region(region, palette_index=0)
			
			if img:
				output_path = output_dir / f"{region.name}.png"
				img.save(output_path)
				print(f"✓ Saved {region.name} to {output_path}")
			
			# For assets with multiple palettes, extract those too
			if region.palette_count > 1:
				for pal_idx in range(1, min(region.palette_count, 4)):  # Limit to 4 palettes
					img = self.extract_region(region, palette_index=pal_idx)
					if img:
						output_path = output_dir / f"{region.name}_pal{pal_idx}.png"
						img.save(output_path)
						print(f"✓ Saved {region.name} (palette {pal_idx}) to {output_path}")
	
	def list_assets(self) -> None:
		"""List all known assets"""
		regions = FFMQGraphicsDatabase.get_all_regions()
		
		print(f"\nFFMQ Graphics Assets ({len(regions)} regions):\n")
		
		# Group by type
		by_type: Dict[FFMQAssetType, List[FFMQGraphicsRegion]] = {}
		for region in regions:
			if region.asset_type not in by_type:
				by_type[region.asset_type] = []
			by_type[region.asset_type].append(region)
		
		for asset_type, type_regions in sorted(by_type.items(), key=lambda x: x[0].value):
			print(f"{asset_type.value.upper()}:")
			for region in type_regions:
				print(f"  • {region.name}")
				print(f"    Offset: 0x{region.rom_offset:06X}, Size: {region.size_bytes:,} bytes")
				print(f"    Tiles: {region.tile_count}, Format: {region.bits_per_pixel}bpp")
				print(f"    Palettes: {region.palette_count}")
				print(f"    {region.description}")
			print()
	
	def export_catalog(self, output_path: Path) -> None:
		"""Export asset catalog as JSON"""
		regions = FFMQGraphicsDatabase.get_all_regions()
		
		catalog = {
			'rom_file': str(self.rom_path),
			'rom_size': len(self.rom_data),
			'region_count': len(regions),
			'regions': [r.to_dict() for r in regions]
		}
		
		with open(output_path, 'w') as f:
			json.dump(catalog, f, indent='\t')
		
		print(f"✓ Exported catalog to {output_path}")


def main():
	parser = argparse.ArgumentParser(description='Extract Final Fantasy Mystic Quest graphics')
	parser.add_argument('rom', type=Path, help='FFMQ ROM file')
	parser.add_argument('--extract-all', action='store_true', help='Extract all known graphics')
	parser.add_argument('--output', type=Path, help='Output directory or file')
	parser.add_argument('--list-assets', action='store_true', help='List all known assets')
	parser.add_argument('--catalog', action='store_true', help='Export asset catalog as JSON')
	parser.add_argument('--region', type=str, help='Extract specific region by name')
	parser.add_argument('--palette', type=int, default=0, help='Palette index to use')
	parser.add_argument('--characters', action='store_true', help='Extract character graphics')
	parser.add_argument('--monsters', action='store_true', help='Extract monster graphics')
	parser.add_argument('--maps', action='store_true', help='Extract map tilesets')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	if not PIL_AVAILABLE and not args.list_assets and not args.catalog:
		print("Error: PIL/Pillow is required for graphics extraction")
		print("Install with: pip install Pillow")
		return 1
	
	extractor = FFMQGraphicsExtractor(args.rom, verbose=args.verbose)
	
	# List assets
	if args.list_assets:
		extractor.list_assets()
		return 0
	
	# Export catalog
	if args.catalog:
		output_path = args.output or Path('ffmq_graphics_catalog.json')
		extractor.export_catalog(output_path)
		return 0
	
	# Extract all
	if args.extract_all:
		output_dir = args.output or Path('ffmq_graphics')
		extractor.extract_all(output_dir)
		return 0
	
	# Extract by type
	if args.characters:
		regions = FFMQGraphicsDatabase.get_by_type(FFMQAssetType.CHARACTER)
		output_dir = args.output or Path('characters')
		output_dir.mkdir(parents=True, exist_ok=True)
		
		for region in regions:
			img = extractor.extract_region(region, args.palette)
			if img:
				output_path = output_dir / f"{region.name}.png"
				img.save(output_path)
				print(f"✓ Saved to {output_path}")
		return 0
	
	if args.monsters:
		regions = FFMQGraphicsDatabase.get_by_type(FFMQAssetType.MONSTER)
		output_dir = args.output or Path('monsters')
		output_dir.mkdir(parents=True, exist_ok=True)
		
		for region in regions:
			img = extractor.extract_region(region, args.palette)
			if img:
				output_path = output_dir / f"{region.name}.png"
				img.save(output_path)
				print(f"✓ Saved to {output_path}")
		return 0
	
	if args.maps:
		regions = FFMQGraphicsDatabase.get_by_type(FFMQAssetType.MAP_TILESET)
		output_dir = args.output or Path('tilesets')
		output_dir.mkdir(parents=True, exist_ok=True)
		
		for region in regions:
			img = extractor.extract_region(region, args.palette)
			if img:
				output_path = output_dir / f"{region.name}.png"
				img.save(output_path)
				print(f"✓ Saved to {output_path}")
		return 0
	
	# Extract specific region
	if args.region:
		region = FFMQGraphicsDatabase.get_by_name(args.region)
		if not region:
			print(f"Error: Unknown region '{args.region}'")
			print("\nAvailable regions:")
			extractor.list_assets()
			return 1
		
		img = extractor.extract_region(region, args.palette)
		if img:
			output_path = args.output or Path(f"{region.name}.png")
			img.save(output_path)
			print(f"✓ Saved to {output_path}")
		return 0
	
	# Default: show help
	print("Use --list-assets to see available graphics")
	print("Use --extract-all to extract all graphics")
	print("Use --region <name> to extract specific region")
	return 0


if __name__ == '__main__':
	exit(main())
