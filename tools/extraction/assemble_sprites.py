"""
Assemble recognizable sprites from tiles + palettes + OAM metadata.

This tool combines extracted tiles with palette and layout information to create
complete, recognizable sprite PNGs (enemies, characters, etc.) that match what's
actually displayed in-game.

Usage:
	python tools/extraction/assemble_sprites.py

Output:
	data/extracted/graphics/sprites/
	├── characters/
	│   ├── benjamin.png
	│   ├── kaeli.png
	│   └── ...
	├── enemies/
	│   ├── brown_bear.png
	│   ├── behemoth.png
	│   └── ...
	└── metadata/
		├── benjamin.json
		└── ...
"""

import os
import sys
import json
from pathlib import Path
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass, field

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
	from PIL import Image
except ImportError:
	print("ERROR: Pillow library required")
	print("Install with: pip install Pillow")
	sys.exit(1)

# Import the graphics extractor for tile/palette loading
try:
	from extraction.extract_graphics import GraphicsExtractor, Palette
except ImportError:
	print("ERROR: extract_graphics.py not found in tools/extraction/")
	sys.exit(1)


# ROM Configuration
ROM_PATH = "roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"

# Output directories
OUTPUT_DIR = Path("data/extracted/graphics/sprites")
CHARACTERS_DIR = OUTPUT_DIR / "characters"
ENEMIES_DIR = OUTPUT_DIR / "enemies"
METADATA_DIR = OUTPUT_DIR / "metadata"


@dataclass
class SpriteLayout:
	"""Layout definition for assembling a multi-tile sprite."""
	name: str
	category: str  # "character", "enemy", "npc", "ui"
	width_tiles: int  # Width in 8x8 tiles
	height_tiles: int  # Height in 8x8 tiles
	tile_offset: int  # ROM offset to first tile
	palette_index: int  # Which palette (0-7)
	tiles: List[int] = field(default_factory=list)  # Tile indices (relative to tile_offset)
	notes: str = ""


# Sprite definitions based on ROM analysis and disassembly
# These are educated guesses based on typical SNES sprite organization
# TODO: Extract actual sprite metadata from ROM OAM tables

CHARACTER_SPRITES = [
	SpriteLayout(
		name="benjamin",
		category="character",
		width_tiles=2,
		height_tiles=2,
		tile_offset=0x028000,  # Bank 04 start
		palette_index=1,  # From disassembly: Benjamin uses palette 1
		tiles=[0, 1, 16, 17],  # 2x2 tile arrangement (typical SNES sprite)
		notes="Benjamin - main character sprite (standing pose)"
	),
	SpriteLayout(
		name="kaeli",
		category="character",
		width_tiles=2,
		height_tiles=2,
		tile_offset=0x028000,
		palette_index=2,  # Likely palette 2
		tiles=[4, 5, 20, 21],
		notes="Kaeli - companion sprite"
	),
	SpriteLayout(
		name="phoebe",
		category="character",
		width_tiles=2,
		height_tiles=2,
		tile_offset=0x028000,
		palette_index=3,  # Likely palette 3
		tiles=[8, 9, 24, 25],
		notes="Phoebe - companion sprite"
	),
	SpriteLayout(
		name="reuben",
		category="character",
		width_tiles=2,
		height_tiles=2,
		tile_offset=0x028000,
		palette_index=4,  # Likely palette 4
		tiles=[12, 13, 28, 29],
		notes="Reuben - companion sprite"
	),
]

# Enemy sprites - will expand this based on actual testing
ENEMY_SPRITES = [
	SpriteLayout(
		name="brown_bear",
		category="enemy",
		width_tiles=4,
		height_tiles=4,
		tile_offset=0x028000,
		palette_index=3,  # From disassembly: enemies often use palette 3
		tiles=[
			32, 33, 34, 35,
			48, 49, 50, 51,
			64, 65, 66, 67,
			80, 81, 82, 83
		],
		notes="Brown Bear - common enemy (4x4 tiles = 32x32 pixels)"
	),
	SpriteLayout(
		name="behemoth",
		category="enemy",
		width_tiles=4,
		height_tiles=4,
		tile_offset=0x028000,
		palette_index=6,  # From disassembly: $d2 attribute = palette 6
		tiles=[
			96, 97, 98, 99,
			112, 113, 114, 115,
			128, 129, 130, 131,
			144, 145, 146, 147
		],
		notes="Behemoth - larger enemy"
	),
]


class SpriteAssembler:
	"""Assemble sprites from tiles, palettes, and layout definitions."""

	def __init__(self, rom_path: str):
		"""Initialize with ROM file."""
		self.extractor = GraphicsExtractor(rom_path)
		self.palettes = []
		self._load_palettes()

	def _load_palettes(self):
		"""Load all 16 palettes from ROM."""
		BANK_05_START = 0x030000
		for i in range(16):
			offset = BANK_05_START + (i * 32)
			palette = self.extractor.extract_palette(offset, 16)
			palette.name = f"palette_{i:02d}"
			self.palettes.append(palette)

	def assemble_sprite(self, layout: SpriteLayout) -> Image.Image:
		"""
		Assemble a sprite from its layout definition.

		Args:
			layout: SpriteLayout defining the sprite structure

		Returns:
			PIL Image of assembled sprite
		"""
		# Get the correct palette
		if layout.palette_index >= len(self.palettes):
			print(f"WARNING: Palette {layout.palette_index} out of range, using palette 0")
			palette = self.palettes[0]
		else:
			palette = self.palettes[layout.palette_index]

		# Extract tiles at the specified offset
		max_tile_id = max(layout.tiles) if layout.tiles else 0
		num_tiles = max_tile_id + 1
		tiles = self.extractor.extract_tiles_4bpp(layout.tile_offset, num_tiles, palette)

		# Create sprite image
		width_px = layout.width_tiles * 8
		height_px = layout.height_tiles * 8
		sprite = Image.new('RGB', (width_px, height_px))

		# Arrange tiles according to layout
		for i, tile_id in enumerate(layout.tiles):
			if tile_id >= len(tiles):
				print(f"WARNING: Tile {tile_id} out of range (have {len(tiles)} tiles)")
				continue

			# Calculate position in sprite grid
			x_tile = i % layout.width_tiles
			y_tile = i // layout.width_tiles

			x_px = x_tile * 8
			y_px = y_tile * 8

			# Paste tile into sprite
			sprite.paste(tiles[tile_id], (x_px, y_px))

		return sprite

	def export_sprite(self, layout: SpriteLayout, output_path: Path) -> bool:
		"""
		Assemble and export a sprite to PNG.

		Args:
			layout: SpriteLayout defining the sprite
			output_path: Path to save PNG file

		Returns:
			True if successful, False otherwise
		"""
		try:
			sprite = self.assemble_sprite(layout)
			output_path.parent.mkdir(parents=True, exist_ok=True)
			sprite.save(output_path)
			return True
		except Exception as e:
			print(f"ERROR exporting sprite {layout.name}: {e}")
			return False

	def export_sprite_metadata(self, layout: SpriteLayout, output_path: Path):
		"""Export sprite metadata as JSON."""
		metadata = {
			"name": layout.name,
			"category": layout.category,
			"dimensions": {
				"width_tiles": layout.width_tiles,
				"height_tiles": layout.height_tiles,
				"width_pixels": layout.width_tiles * 8,
				"height_pixels": layout.height_tiles * 8
			},
			"rom_offset": f"0x{layout.tile_offset:06X}",
			"palette_index": layout.palette_index,
			"tiles": layout.tiles,
			"notes": layout.notes
		}

		output_path.parent.mkdir(parents=True, exist_ok=True)
		with open(output_path, 'w') as f:
			json.dump(metadata, f, indent=2)

	def create_sprite_sheet(self, sprites: List[SpriteLayout],
						   sprites_per_row: int = 4) -> Image.Image:
		"""
		Create a sprite sheet showing multiple sprites.

		Args:
			sprites: List of SpriteLayout definitions
			sprites_per_row: Number of sprites per row

		Returns:
			PIL Image containing sprite sheet
		"""
		if not sprites:
			return Image.new('RGB', (32, 32))

		# Find max sprite dimensions for grid
		max_width = max(s.width_tiles * 8 for s in sprites)
		max_height = max(s.height_tiles * 8 for s in sprites)

		# Calculate sheet size
		num_sprites = len(sprites)
		rows = (num_sprites + sprites_per_row - 1) // sprites_per_row
		sheet_width = sprites_per_row * max_width
		sheet_height = rows * max_height

		sheet = Image.new('RGB', (sheet_width, sheet_height))

		# Assemble and paste each sprite
		for i, layout in enumerate(sprites):
			sprite = self.assemble_sprite(layout)

			x = (i % sprites_per_row) * max_width
			y = (i // sprites_per_row) * max_height

			sheet.paste(sprite, (x, y))

		return sheet


def main():
	"""Main sprite assembly routine."""
	print("=" * 70)
	print("FFMQ Sprite Assembler")
	print("=" * 70)
	print()

	# Create output directories
	OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
	CHARACTERS_DIR.mkdir(exist_ok=True)
	ENEMIES_DIR.mkdir(exist_ok=True)
	METADATA_DIR.mkdir(exist_ok=True)

	# Initialize assembler
	print(f"Loading ROM: {ROM_PATH}")
	try:
		assembler = SpriteAssembler(ROM_PATH)
		print(f"[OK] ROM loaded, {len(assembler.palettes)} palettes available")
	except Exception as e:
		print(f"[ERROR] Failed to load ROM: {e}")
		return 1

	print()
	print("Assembling Character Sprites...")
	print("-" * 70)

	success_count = 0
	for layout in CHARACTER_SPRITES:
		png_path = CHARACTERS_DIR / f"{layout.name}.png"
		json_path = METADATA_DIR / f"{layout.name}.json"

		# Assemble and export sprite
		if assembler.export_sprite(layout, png_path):
			print(f"[OK] {layout.name:15s} → {png_path.name} "
				  f"({layout.width_tiles * 8}×{layout.height_tiles * 8}px, "
				  f"palette {layout.palette_index})")
			assembler.export_sprite_metadata(layout, json_path)
			success_count += 1
		else:
			print(f"[FAIL] {layout.name}")

	# Create character sprite sheet
	char_sheet = assembler.create_sprite_sheet(CHARACTER_SPRITES, sprites_per_row=4)
	char_sheet_path = CHARACTERS_DIR / "_character_sheet.png"
	char_sheet.save(char_sheet_path)
	print(f"[OK] Character sprite sheet: {char_sheet_path.name}")

	print()
	print("Assembling Enemy Sprites...")
	print("-" * 70)

	for layout in ENEMY_SPRITES:
		png_path = ENEMIES_DIR / f"{layout.name}.png"
		json_path = METADATA_DIR / f"{layout.name}.json"

		if assembler.export_sprite(layout, png_path):
			print(f"[OK] {layout.name:15s} → {png_path.name} "
				  f"({layout.width_tiles * 8}×{layout.height_tiles * 8}px, "
				  f"palette {layout.palette_index})")
			assembler.export_sprite_metadata(layout, json_path)
			success_count += 1
		else:
			print(f"[FAIL] {layout.name}")

	# Create enemy sprite sheet
	enemy_sheet = assembler.create_sprite_sheet(ENEMY_SPRITES, sprites_per_row=3)
	enemy_sheet_path = ENEMIES_DIR / "_enemy_sheet.png"
	enemy_sheet.save(enemy_sheet_path)
	print(f"[OK] Enemy sprite sheet: {enemy_sheet_path.name}")

	print()
	print("=" * 70)
	print("Sprite Assembly Complete!")
	print("=" * 70)
	print(f"Successfully assembled: {success_count} sprites")
	print(f"Output directory: {OUTPUT_DIR}")
	print(f"  - Characters: {CHARACTERS_DIR}")
	print(f"  - Enemies: {ENEMIES_DIR}")
	print(f"  - Metadata: {METADATA_DIR}")
	print()
	print("IMPORTANT: Initial sprite definitions are educated guesses!")
	print("Next steps:")
	print("  1. Compare assembled sprites with game screenshots")
	print("  2. Adjust tile indices in sprite definitions if needed")
	print("  3. Verify palette assignments match in-game appearance")
	print("  4. Extract actual OAM metadata from ROM for accurate layouts")
	print("  5. Expand sprite definitions for all characters/enemies")
	print()
	print("To refine sprites:")
	print("  - Edit sprite definitions in this file (CHARACTER_SPRITES, ENEMY_SPRITES)")
	print("  - Change tile_offset, palette_index, or tiles array")
	print("  - Re-run to regenerate sprites")

	return 0


if __name__ == '__main__':
	sys.exit(main())
