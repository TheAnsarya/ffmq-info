"""
FFMQ Graphics Database Manager

Manages loading, saving, and editing graphics data from ROM.
"""

from typing import List, Dict, Optional, Tuple
from pathlib import Path
import struct

from .graphics_data import (
	Tile, Tileset, Sprite, SpriteSheet, Palette, Animation,
	Color, SpriteSize, PaletteType, AnimationType,
	TILESET_BASE, PALETTE_BASE, SPRITE_BASE
)


class GraphicsDatabase:
	"""Manages all graphics data"""

	def __init__(self):
		self.tilesets: Dict[int, Tileset] = {}
		self.palettes: Dict[int, Palette] = {}
		self.sprite_sheets: Dict[int, SpriteSheet] = {}
		self.rom_path: Optional[str] = None

	def load_from_rom(self, rom_path: str):
		"""Load graphics data from ROM"""
		self.rom_path = rom_path

		with open(rom_path, 'rb') as f:
			rom_data = f.read()

		# Load palettes
		self._load_palettes(rom_data)

		# Load tilesets
		self._load_tilesets(rom_data)

		print(f"Loaded {len(self.palettes)} palettes and {len(self.tilesets)} tilesets")

	def _load_palettes(self, rom_data: bytes):
		"""Load palettes from ROM"""
		# FFMQ has multiple palette sets
		# Load character palettes (8 palettes)
		for i in range(8):
			offset = PALETTE_BASE + (i * 32)
			if offset + 32 <= len(rom_data):
				palette_data = rom_data[offset:offset + 32]
				palette = Palette.from_bytes(palette_data, i)
				palette.palette_type = PaletteType.CHARACTER
				palette.name = f"Character Palette {i}"
				self.palettes[i] = palette

		# Load enemy palettes (16 palettes)
		for i in range(16):
			offset = PALETTE_BASE + 0x100 + (i * 32)
			if offset + 32 <= len(rom_data):
				palette_data = rom_data[offset:offset + 32]
				palette = Palette.from_bytes(palette_data, i + 8)
				palette.palette_type = PaletteType.ENEMY
				palette.name = f"Enemy Palette {i}"
				self.palettes[i + 8] = palette

	def _load_tilesets(self, rom_data: bytes):
		"""Load tilesets from ROM"""
		# Load main character tileset (256 tiles)
		offset = TILESET_BASE
		if offset + (256 * 32) <= len(rom_data):
			tileset_data = rom_data[offset:offset + (256 * 32)]
			tileset = Tileset.from_bytes(tileset_data, 0, 256)
			tileset.name = "Character Tileset"
			if 0 in self.palettes:
				tileset.palette = self.palettes[0]
			self.tilesets[0] = tileset

		# Load enemy tilesets (512 tiles each)
		for i in range(4):
			offset = TILESET_BASE + 0x2000 + (i * 512 * 32)
			if offset + (512 * 32) <= len(rom_data):
				tileset_data = rom_data[offset:offset + (512 * 32)]
				tileset = Tileset.from_bytes(tileset_data, i + 1, 512)
				tileset.name = f"Enemy Tileset {i + 1}"
				if (i + 8) in self.palettes:
					tileset.palette = self.palettes[i + 8]
				self.tilesets[i + 1] = tileset

	def save_to_rom(self, rom_path: Optional[str] = None):
		"""Save graphics data to ROM"""
		if rom_path is None:
			rom_path = self.rom_path

		if rom_path is None:
			raise ValueError("No ROM path specified")

		with open(rom_path, 'rb') as f:
			rom_data = bytearray(f.read())

		# Save palettes
		for palette_id, palette in self.palettes.items():
			if palette.palette_type == PaletteType.CHARACTER and palette_id < 8:
				offset = PALETTE_BASE + (palette_id * 32)
			elif palette.palette_type == PaletteType.ENEMY and palette_id >= 8:
				offset = PALETTE_BASE + 0x100 + ((palette_id - 8) * 32)
			else:
				continue

			if offset + 32 <= len(rom_data):
				palette_bytes = palette.to_bytes()
				rom_data[offset:offset + 32] = palette_bytes

		# Save tilesets
		for tileset_id, tileset in self.tilesets.items():
			if tileset_id == 0:
				offset = TILESET_BASE
			elif 1 <= tileset_id <= 4:
				offset = TILESET_BASE + 0x2000 + ((tileset_id - 1) * 512 * 32)
			else:
				continue

			tileset_bytes = tileset.to_bytes()
			if offset + len(tileset_bytes) <= len(rom_data):
				rom_data[offset:offset + len(tileset_bytes)] = tileset_bytes

		# Write back to ROM
		with open(rom_path, 'wb') as f:
			f.write(rom_data)

		print(f"Saved graphics to {rom_path}")

	def get_tileset(self, tileset_id: int) -> Optional[Tileset]:
		"""Get tileset by ID"""
		return self.tilesets.get(tileset_id)

	def get_palette(self, palette_id: int) -> Optional[Palette]:
		"""Get palette by ID"""
		return self.palettes.get(palette_id)

	def create_sprite_sheet(self, tileset_id: int, palette_ids: List[int]) -> Optional[SpriteSheet]:
		"""Create sprite sheet from tileset and palettes"""
		tileset = self.get_tileset(tileset_id)
		if tileset is None:
			return None

		sheet = SpriteSheet(
			sheet_id=tileset_id,
			tileset=tileset,
			name=tileset.name
		)

		# Add palettes
		for palette_id in palette_ids:
			palette = self.get_palette(palette_id)
			if palette:
				sheet.add_palette(palette)

		return sheet

	def export_palette_to_image(self, palette_id: int, output_path: str):
		"""Export palette as PNG image (16x1 pixels)"""
		palette = self.get_palette(palette_id)
		if palette is None:
			raise ValueError(f"Palette {palette_id} not found")

		try:
			from PIL import Image
		except ImportError:
			print("PIL not installed. Install with: pip install pillow")
			return

		# Create 16x16 image (each color is 1x16 block)
		img = Image.new('RGB', (16, 16))
		pixels = img.load()

		for i, color in enumerate(palette.colors):
			r, g, b = color.to_rgb888()
			# Fill vertical stripe
			for y in range(16):
				pixels[i, y] = (r, g, b)

		img.save(output_path)
		print(f"Exported palette to {output_path}")

	def export_tileset_to_image(self, tileset_id: int, palette_id: int, output_path: str, tiles_per_row: int = 16):
		"""Export tileset as PNG image"""
		tileset = self.get_tileset(tileset_id)
		palette = self.get_palette(palette_id)

		if tileset is None or palette is None:
			raise ValueError("Tileset or palette not found")

		try:
			from PIL import Image
		except ImportError:
			print("PIL not installed. Install with: pip install pillow")
			return

		tile_count = len(tileset.tiles)
		rows = (tile_count + tiles_per_row - 1) // tiles_per_row

		# Create image
		width = tiles_per_row * 8
		height = rows * 8
		img = Image.new('RGB', (width, height))
		pixels = img.load()

		for tile_idx, tile in enumerate(tileset.tiles):
			tile_x = (tile_idx % tiles_per_row) * 8
			tile_y = (tile_idx // tiles_per_row) * 8

			for y in range(8):
				for x in range(8):
					color_idx = tile.get_pixel(x, y)
					color = palette.get_color(color_idx)
					r, g, b = color.to_rgb888()
					pixels[tile_x + x, tile_y + y] = (r, g, b)

		img.save(output_path)
		print(f"Exported tileset to {output_path}")

	def import_palette_from_image(self, palette_id: int, image_path: str):
		"""Import palette from PNG image"""
		try:
			from PIL import Image
		except ImportError:
			print("PIL not installed. Install with: pip install pillow")
			return

		img = Image.open(image_path).convert('RGB')
		pixels = img.load()

		palette = self.palettes.get(palette_id)
		if palette is None:
			palette = Palette(palette_id=palette_id, palette_type=PaletteType.SPRITE)
			self.palettes[palette_id] = palette

		# Sample colors from image
		width, height = img.size
		for i in range(min(16, width)):
			r, g, b = pixels[i, 0]
			palette.colors[i] = Color.from_rgb888(r, g, b)

		print(f"Imported palette from {image_path}")

	def get_statistics(self) -> Dict[str, any]:
		"""Get graphics statistics"""
		stats = {
			'total_tilesets': len(self.tilesets),
			'total_palettes': len(self.palettes),
			'total_tiles': sum(len(ts.tiles) for ts in self.tilesets.values()),
			'character_palettes': len([p for p in self.palettes.values() if p.palette_type == PaletteType.CHARACTER]),
			'enemy_palettes': len([p for p in self.palettes.values() if p.palette_type == PaletteType.ENEMY]),
		}
		return stats

	def find_similar_colors(self, color: Color, threshold: int = 5) -> List[Tuple[int, int, Color]]:
		"""Find similar colors across all palettes"""
		similar = []

		for palette_id, palette in self.palettes.items():
			for color_idx, pal_color in enumerate(palette.colors):
				# Calculate color distance
				dr = abs(color.red - pal_color.red)
				dg = abs(color.green - pal_color.green)
				db = abs(color.blue - pal_color.blue)
				distance = dr + dg + db

				if distance <= threshold:
					similar.append((palette_id, color_idx, pal_color))

		return similar

	def optimize_palette(self, palette_id: int) -> int:
		"""Remove duplicate colors from palette"""
		palette = self.get_palette(palette_id)
		if palette is None:
			return 0

		# Build unique color list
		unique_colors = []
		color_map = {}  # Maps old index to new index

		for i, color in enumerate(palette.colors):
			# Check if color already exists
			found = False
			for j, unique_color in enumerate(unique_colors):
				if (color.red == unique_color.red and
					color.green == unique_color.green and
					color.blue == unique_color.blue):
					color_map[i] = j
					found = True
					break

			if not found:
				color_map[i] = len(unique_colors)
				unique_colors.append(color)

		# Update palette
		removed = 16 - len(unique_colors)
		for i in range(16):
			if i < len(unique_colors):
				palette.colors[i] = unique_colors[i]
			else:
				palette.colors[i] = Color(0, 0, 0)

		return removed
