"""
Extract UI graphics elements from FFMQ ROM.

Extracts icons, cursors, HP/MP gauges, status symbols, and other UI elements
based on documented ROM locations from Menus.wikitext and Graphics.wikitext.

ROM Locations:
	- $02a600: Window borders (32 tiles, 2BPP)
	- $02a800: Cursor sprites (4 tiles, 2BPP, 4 animation frames)
	- $02ac00: Menu icons (16 tiles, 4BPP) - Item/magic/equipment icons
	- $02ae00: Status symbols (8 tiles, 4BPP) - HP/MP/status effect icons
	- $02b000: Number font (10 tiles, 2BPP) - Digits 0-9
	- $02b200: Dialog box (12 tiles, 2BPP) - Speech bubble corners/edges
	- $02b400: Shop tiles (24 tiles, 4BPP) - Gold coin, buy/sell icons
	- $02b800: Config tiles (16 tiles, 4BPP) - Sound/window color preview
	- $02bc00: Battle menu (20 tiles, 4BPP) - Attack/Magic/Item/Run graphics
	- $058000: Font (Latin) (96 tiles, 2BPP) - ASCII $20-$7f
	- $09fb95+: Number graphics (battle damage display)
	- $09fc85+: Special icon graphics (status effects, elemental symbols)

References:
	- datacrystal/ROM_map/Menus.wikitext - Complete UI documentation
	- datacrystal/ROM_map/Graphics.wikitext - Graphics format specs
	- src/asm/bank_09_documented.asm - Graphics data locations
"""

import os
import sys
import json
import struct
from pathlib import Path
from typing import List, Tuple, Optional, Dict
from dataclasses import dataclass, asdict

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
	from PIL import Image
except ImportError:
	print("ERROR: Pillow library required")
	print("Install with: pip install Pillow")
	sys.exit(1)


# ROM Configuration
ROM_PATH = "roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"

# Output directory
OUTPUT_DIR = Path("data/extracted/ui")

# UI Graphics ROM Locations (file offsets, unheadered)
UI_GRAPHICS = {
	# Format: (offset, tile_count, bits_per_pixel, description)
	'window_borders': (0x012600, 32, 2, "Window border tiles (corners, edges, fill)"),
	'cursor_sprite': (0x012800, 4, 2, "Cursor sprite (4 animation frames)"),
	'menu_icons': (0x012c00, 16, 4, "Item/Magic/Equipment icons"),
	'status_symbols': (0x012e00, 8, 4, "HP/MP/Status effect icons"),
	'number_font': (0x013000, 10, 2, "Digits 0-9 for stats/gold"),
	'dialog_box': (0x013200, 12, 2, "Speech bubble corners/edges"),
	'shop_tiles': (0x013400, 24, 4, "Gold coin, buy/sell icons"),
	'config_tiles': (0x013800, 16, 4, "Sound/window color preview"),
	'battle_menu': (0x013c00, 20, 4, "Attack/Magic/Item/Run graphics"),
	'font_latin': (0x058000, 96, 2, "ASCII $20-$7f font"),
}

# Default palettes for 2BPP and 4BPP graphics
PALETTE_2BPP = [
	(0, 0, 0, 0),		# Color 0: Transparent
	(255, 255, 255, 255), # Color 1: White
	(192, 192, 192, 255), # Color 2: Light gray
	(128, 128, 128, 255), # Color 3: Dark gray
]

PALETTE_4BPP = [
	(0, 0, 0, 0),		# Color 0: Transparent
	(255, 255, 255, 255), # Color 1: White
	(0, 0, 0, 255),	  # Color 2: Black
	(255, 0, 0, 255),	# Color 3: Red
	(0, 255, 0, 255),	# Color 4: Green
	(0, 0, 255, 255),	# Color 5: Blue
	(255, 255, 0, 255),  # Color 6: Yellow
	(255, 0, 255, 255),  # Color 7: Magenta
	(0, 255, 255, 255),  # Color 8: Cyan
	(192, 192, 192, 255), # Color 9: Light gray
	(128, 128, 128, 255), # Color 10: Dark gray
	(255, 128, 0, 255),  # Color 11: Orange
	(128, 0, 255, 255),  # Color 12: Purple
	(0, 128, 255, 255),  # Color 13: Light blue
	(255, 192, 203, 255), # Color 14: Pink
	(128, 64, 0, 255),   # Color 15: Brown
]


@dataclass
class UIElement:
	"""UI graphics element metadata."""
	name: str
	offset: int
	tile_count: int
	bits_per_pixel: int
	description: str
	width_tiles: int = 1
	height_tiles: int = 1
	
	def to_dict(self) -> Dict:
		"""Convert to dictionary for JSON export."""
		return {
			'name': self.name,
			'rom_offset': f"${self.offset:06x}",
			'tile_count': self.tile_count,
			'bits_per_pixel': self.bits_per_pixel,
			'description': self.description,
			'tile_size': '8×8 pixels',
			'width_tiles': self.width_tiles,
			'height_tiles': self.height_tiles,
			'total_pixels': f"{self.width_tiles * 8}×{self.height_tiles * 8}",
		}


class UIGraphicsExtractor:
	"""Extract UI graphics from FFMQ ROM."""
	
	def __init__(self, rom_path: str = ROM_PATH, output_dir: str = str(OUTPUT_DIR)):
		"""Initialize extractor."""
		self.rom_path = rom_path
		self.output_dir = Path(output_dir)
		self.output_dir.mkdir(parents=True, exist_ok=True)
		
		# Load ROM
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
	
	def decode_tile_2bpp(self, tile_data: bytes) -> List[int]:
		"""
		Decode a single 8×8 tile from 2BPP format.
		
		2BPP format: 16 bytes per tile
		- Bytes 0-7: Bitplane 0 (one byte per row)
		- Bytes 8-15: Bitplane 1 (one byte per row)
		
		Returns list of 64 pixel values (0-3).
		"""
		if len(tile_data) != 16:
			raise ValueError(f"2BPP tile must be 16 bytes, got {len(tile_data)}")
		
		pixels = []
		for row in range(8):
			bp0 = tile_data[row]	  # Bitplane 0
			bp1 = tile_data[row + 8]   # Bitplane 1
			
			for bit in range(7, -1, -1):  # Left to right
				pixel = ((bp1 >> bit) & 1) << 1 | ((bp0 >> bit) & 1)
				pixels.append(pixel)
		
		return pixels
	
	def decode_tile_4bpp(self, tile_data: bytes) -> List[int]:
		"""
		Decode a single 8×8 tile from 4BPP format.
		
		4BPP format: 32 bytes per tile
		- Bytes 0-1: Bitplanes 0-1 for row 0
		- Bytes 2-3: Bitplanes 0-1 for row 1
		- ...
		- Bytes 14-15: Bitplanes 0-1 for row 7
		- Bytes 16-17: Bitplanes 2-3 for row 0
		- ...
		
		Returns list of 64 pixel values (0-15).
		"""
		if len(tile_data) != 32:
			raise ValueError(f"4BPP tile must be 32 bytes, got {len(tile_data)}")
		
		pixels = []
		for row in range(8):
			bp0 = tile_data[row * 2]
			bp1 = tile_data[row * 2 + 1]
			bp2 = tile_data[row * 2 + 16]
			bp3 = tile_data[row * 2 + 17]
			
			for bit in range(7, -1, -1):  # Left to right
				pixel = (
					((bp3 >> bit) & 1) << 3 |
					((bp2 >> bit) & 1) << 2 |
					((bp1 >> bit) & 1) << 1 |
					((bp0 >> bit) & 1)
				)
				pixels.append(pixel)
		
		return pixels
	
	def create_tile_image(self, pixels: List[int], palette: List[Tuple[int, int, int, int]]) -> Image.Image:
		"""Create PIL Image from pixel data and palette."""
		img = Image.new('RGBA', (8, 8))
		img_data = []
		
		for pixel in pixels:
			if pixel < len(palette):
				img_data.append(palette[pixel])
			else:
				img_data.append((255, 0, 255, 255))  # Magenta for error
		
		img.putdata(img_data)
		return img
	
	def extract_ui_element(self, name: str, offset: int, tile_count: int, 
						  bpp: int, description: str) -> UIElement:
		"""Extract a UI graphics element."""
		print(f"\nExtracting: {name}")
		print(f"  Offset: ${offset:06x}")
		print(f"  Tiles: {tile_count}")
		print(f"  Format: {bpp}BPP")
		
		# Calculate bytes per tile
		bytes_per_tile = 16 if bpp == 2 else 32
		
		# Choose palette
		palette = PALETTE_2BPP if bpp == 2 else PALETTE_4BPP
		
		# Extract tiles
		tiles = []
		for i in range(tile_count):
			tile_offset = offset + (i * bytes_per_tile)
			tile_data = self.rom_data[tile_offset:tile_offset + bytes_per_tile]
			
			if bpp == 2:
				pixels = self.decode_tile_2bpp(tile_data)
			else:
				pixels = self.decode_tile_4bpp(tile_data)
			
			tile_img = self.create_tile_image(pixels, palette)
			tiles.append(tile_img)
		
		# Create sprite sheet (arrange tiles in a grid)
		tiles_per_row = min(16, tile_count)
		rows = (tile_count + tiles_per_row - 1) // tiles_per_row
		
		sheet_width = tiles_per_row * 8
		sheet_height = rows * 8
		sheet = Image.new('RGBA', (sheet_width, sheet_height), (0, 0, 0, 0))
		
		for idx, tile in enumerate(tiles):
			x = (idx % tiles_per_row) * 8
			y = (idx // tiles_per_row) * 8
			sheet.paste(tile, (x, y))
		
		# Save sprite sheet
		sheet_path = self.output_dir / f"{name}_sheet.png"
		sheet.save(sheet_path)
		print(f"  ✓ Saved sheet: {sheet_path}")
		
		# Save individual tiles if requested (for small sets)
		if tile_count <= 32:
			for idx, tile in enumerate(tiles):
				tile_path = self.output_dir / f"{name}_tile_{idx:02d}.png"
				tile.save(tile_path)
			print(f"  ✓ Saved {tile_count} individual tiles")
		
		# Create metadata
		element = UIElement(
			name=name,
			offset=offset,
			tile_count=tile_count,
			bits_per_pixel=bpp,
			description=description,
			width_tiles=tiles_per_row,
			height_tiles=rows
		)
		
		# Save metadata
		meta_path = self.output_dir / f"{name}_meta.json"
		with open(meta_path, 'w') as f:
			json.dump(element.to_dict(), f, indent=2)
		print(f"  ✓ Saved metadata: {meta_path}")
		
		return element
	
	def extract_all(self):
		"""Extract all UI graphics elements."""
		print("=" * 80)
		print("FFMQ UI Graphics Extraction")
		print("=" * 80)
		
		elements = []
		
		for name, (offset, tile_count, bpp, desc) in UI_GRAPHICS.items():
			element = self.extract_ui_element(name, offset, tile_count, bpp, desc)
			elements.append(element)
		
		# Create summary
		summary = {
			'rom_file': os.path.basename(self.rom_path),
			'extraction_date': 'November 4, 2025',
			'total_elements': len(elements),
			'elements': [e.to_dict() for e in elements],
			'notes': [
				'All UI graphics extracted from documented ROM locations',
				'See datacrystal/ROM_map/Menus.wikitext for complete documentation',
				'Palettes are default/placeholder - actual game uses dynamic palettes',
				'Font graphics include Latin ASCII $20-$7f (96 characters)',
				'Icon and symbol graphics use 4BPP for multi-color display',
			]
		}
		
		summary_path = self.output_dir / 'ui_graphics_summary.json'
		with open(summary_path, 'w') as f:
			json.dump(summary, f, indent=2)
		
		print("\n" + "=" * 80)
		print("UI Graphics Extraction Complete!")
		print("=" * 80)
		print(f"Output: {self.output_dir}")
		print(f"Elements extracted: {len(elements)}")
		print(f"Summary: {summary_path}")
		
		return elements


def main():
	"""Main entry point."""
	if not os.path.exists(ROM_PATH):
		print(f"ERROR: ROM not found: {ROM_PATH}")
		print("Please place the FFMQ ROM (U) V1.1 in the roms/ directory")
		return 1
	
	extractor = UIGraphicsExtractor()
	extractor.extract_all()
	
	return 0


if __name__ == '__main__':
	sys.exit(main())
