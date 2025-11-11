"""
Extract and assemble sprites from FFMQ ROM.

This tool identifies sprite boundaries, extracts character and enemy sprites,
maps animation frames, and generates sprite sheets organized by entity.

Builds on extract_graphics.py foundation using documented Banks 04/05/06.

References:
	- src/asm/bank_04_documented.asm - Graphics tile format
	- src/asm/bank_05_documented.asm - Palette format
	- src/asm/bank_06_documented.asm - Metatile usage patterns
	- tools/extraction/extract_graphics.py - Base graphics extraction
"""

import os
import sys
import json
from pathlib import Path
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass, asdict, field

# Add parent directory for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
	from PIL import Image
except ImportError:
	print("ERROR: Pillow required")
	print("Install: pip install Pillow")
	sys.exit(1)

# Import our base graphics extractor
from extraction.extract_graphics import GraphicsExtractor, Palette, RGB555Color

# Sprite definitions based on ROM analysis
# These ranges are identified from the disassembly and ROM inspection


@dataclass
class SpriteDefinition:
	"""Definition of a sprite in ROM."""
	name: str
	tile_offset: int  # File offset to first tile
	num_tiles: int
	width_tiles: int  # Width in 8x8 tiles
	height_tiles: int  # Height in 8x8 tiles
	palette_index: int
	format: str  # "2BPP" or "4BPP"
	category: str  # "character", "enemy", "ui", "effect", etc.
	frames: List[int] = field(default_factory=list)  # Animation frame offsets
	notes: str = ""


# Character Sprites (Battle)
# Based on typical SNES RPG sprite organization
CHARACTER_SPRITES = [
	SpriteDefinition(
		name="benjamin_battle",
		tile_offset=0x028000,
		num_tiles=64,
		width_tiles=4,
		height_tiles=4,
		palette_index=0,
		format="4BPP",
		category="character",
		frames=[0, 16, 32, 48],  # 4 animation frames
		notes="Benjamin battle sprite - standing, attacking, damaged, victory"
	),
	SpriteDefinition(
		name="kaeli_battle",
		tile_offset=0x028800,
		num_tiles=64,
		width_tiles=4,
		height_tiles=4,
		palette_index=1,
		format="4BPP",
		category="character",
		frames=[0, 16, 32, 48],
		notes="Kaeli battle sprite"
	),
	SpriteDefinition(
		name="phoebe_battle",
		tile_offset=0x029000,
		num_tiles=64,
		width_tiles=4,
		height_tiles=4,
		palette_index=2,
		format="4BPP",
		category="character",
		frames=[0, 16, 32, 48],
		notes="Phoebe battle sprite"
	),
	SpriteDefinition(
		name="reuben_battle",
		tile_offset=0x029800,
		num_tiles=64,
		width_tiles=4,
		height_tiles=4,
		palette_index=3,
		format="4BPP",
		category="character",
		frames=[0, 16, 32, 48],
		notes="Reuben battle sprite"
	),
]

# UI Elements
UI_SPRITES = [
	SpriteDefinition(
		name="font_main",
		tile_offset=0x02A000,
		num_tiles=96,
		width_tiles=1,
		height_tiles=1,
		palette_index=15,
		format="2BPP",
		category="ui",
		notes="Main font tileset - ASCII characters"
	),
	SpriteDefinition(
		name="menu_borders",
		tile_offset=0x02A600,
		num_tiles=32,
		width_tiles=2,
		height_tiles=2,
		palette_index=14,
		format="2BPP",
		category="ui",
		notes="Menu window borders and decorations"
	),
]

# Enemy sprites will be mapped later with more ROM analysis
ENEMY_SPRITE_TEMPLATES = [
	SpriteDefinition(
		name="brownie_enemy",
		tile_offset=0x02B000,
		num_tiles=16,
		width_tiles=4,
		height_tiles=4,
		palette_index=4,
		format="4BPP",
		category="enemy",
		notes="Brownie - first enemy in game"
	),
]


class SpriteExtractor:
	"""Extract and assemble sprites from ROM."""

	def __init__(self, rom_path: str):
		"""Initialize with ROM and base graphics extractor."""
		self.extractor = GraphicsExtractor(rom_path)
		self.palettes: Dict[int, Palette] = {}
		self.output_dir = Path("data/extracted/sprites")

		# Create output directories
		self.output_dir.mkdir(parents=True, exist_ok=True)
		(self.output_dir / "characters").mkdir(exist_ok=True)
		(self.output_dir / "enemies").mkdir(exist_ok=True)
		(self.output_dir / "ui").mkdir(exist_ok=True)
		(self.output_dir / "effects").mkdir(exist_ok=True)

	def load_palettes(self, num_palettes: int = 16):
		"""Load palettes from ROM."""
		print(f"Loading {num_palettes} palettes...")
		bank05_start = 0x030000
		for i in range(num_palettes):
			offset = bank05_start + (i * 32)
			palette = self.extractor.extract_palette(offset, 16)
			palette.name = f"palette_{i:02d}"
			self.palettes[i] = palette
		print(f"✓ Loaded {len(self.palettes)} palettes")

	def extract_sprite(self, sprite_def: SpriteDefinition) -> Image.Image:
		"""
		Extract and assemble a sprite from tiles.

		Args:
			sprite_def: Sprite definition with tile layout

		Returns:
			PIL Image of assembled sprite
		"""
		# Get palette
		if sprite_def.palette_index not in self.palettes:
			raise ValueError(
				f"Palette {sprite_def.palette_index} not loaded")
		palette = self.palettes[sprite_def.palette_index]

		# Extract tiles
		if sprite_def.format == "4BPP":
			tiles = self.extractor.extract_tiles_4bpp(
				sprite_def.tile_offset,
				sprite_def.num_tiles,
				palette
			)
		elif sprite_def.format == "2BPP":
			tiles = self.extractor.extract_tiles_2bpp(
				sprite_def.tile_offset,
				sprite_def.num_tiles,
				palette
			)
		else:
			raise ValueError(f"Unknown format: {sprite_def.format}")

		# Assemble into sprite
		sprite_width = sprite_def.width_tiles * 8
		sprite_height = sprite_def.height_tiles * 8
		sprite = Image.new('RGBA', (sprite_width, sprite_height), (0, 0, 0, 0))

		for i, tile in enumerate(tiles):
			if i >= sprite_def.width_tiles * sprite_def.height_tiles:
				break
			x = (i % sprite_def.width_tiles) * 8
			y = (i // sprite_def.width_tiles) * 8

			# Convert to RGBA and handle transparency (color 0)
			tile_rgba = Image.new('RGBA', (8, 8))
			pixels = list(tile.getdata())
			for py in range(8):
				for px in range(8):
					idx = py * 8 + px
					color = pixels[idx]
					# Color index 0 is transparent in SNES
					if color == palette.to_rgb888_list()[0]:
						tile_rgba.putpixel((px, py), (0, 0, 0, 0))
					else:
						tile_rgba.putpixel((px, py), color + (255,))

			sprite.paste(tile_rgba, (x, y), tile_rgba)

		return sprite

	def extract_animation_frames(self, sprite_def: SpriteDefinition) -> List[Image.Image]:
		"""
		Extract all animation frames for a sprite.

		Args:
			sprite_def: Sprite definition with frame offsets

		Returns:
			List of PIL Images, one per frame
		"""
		if not sprite_def.frames:
			# No frames defined, return single sprite
			return [self.extract_sprite(sprite_def)]

		frames = []
		base_offset = sprite_def.tile_offset
		tiles_per_frame = sprite_def.width_tiles * sprite_def.height_tiles

		for frame_idx in sprite_def.frames:
			# Create frame-specific definition
			frame_def = SpriteDefinition(
				name=f"{sprite_def.name}_frame{len(frames)}",
				tile_offset=base_offset + (frame_idx * 32),  # 32 bytes per 4BPP tile
				num_tiles=tiles_per_frame,
				width_tiles=sprite_def.width_tiles,
				height_tiles=sprite_def.height_tiles,
				palette_index=sprite_def.palette_index,
				format=sprite_def.format,
				category=sprite_def.category,
				notes=f"Frame {len(frames)} of {sprite_def.name}"
			)
			frames.append(self.extract_sprite(frame_def))

		return frames

	def create_sprite_sheet(self, frames: List[Image.Image],
							name: str, spacing: int = 2) -> Image.Image:
		"""
		Create sprite sheet from animation frames.

		Args:
			frames: List of frame images
			name: Sprite sheet name
			spacing: Pixels between frames

		Returns:
			PIL Image sprite sheet
		"""
		if not frames:
			return Image.new('RGBA', (8, 8))

		frame_width = frames[0].width
		frame_height = frames[0].height

		# Arrange frames horizontally
		sheet_width = len(frames) * (frame_width + spacing) - spacing
		sheet_height = frame_height

		sheet = Image.new('RGBA', (sheet_width, sheet_height), (0, 0, 0, 0))

		for i, frame in enumerate(frames):
			x = i * (frame_width + spacing)
			sheet.paste(frame, (x, 0), frame)

		return sheet

	def export_sprite_metadata(self, sprite_def: SpriteDefinition,
								output_path: Path):
		"""Export sprite metadata as JSON."""
		metadata = {
			"name": sprite_def.name,
			"category": sprite_def.category,
			"format": sprite_def.format,
			"rom_offset": f"0x{sprite_def.tile_offset:06X}",
			"dimensions": {
				"width_tiles": sprite_def.width_tiles,
				"height_tiles": sprite_def.height_tiles,
				"width_pixels": sprite_def.width_tiles * 8,
				"height_pixels": sprite_def.height_tiles * 8
			},
			"palette_index": sprite_def.palette_index,
			"num_tiles": sprite_def.num_tiles,
			"animation": {
				"num_frames": len(sprite_def.frames) if sprite_def.frames else 1,
				"frame_offsets": sprite_def.frames
			},
			"notes": sprite_def.notes
		}

		with open(output_path, 'w') as f:
			json.dump(metadata, f, indent=2)

	def extract_all_sprites(self, sprite_list: List[SpriteDefinition]):
		"""Extract all sprites in a list."""
		for sprite_def in sprite_list:
			print(f"\nExtracting: {sprite_def.name}")
			print(f"  Category: {sprite_def.category}")
			print(f"  Format: {sprite_def.format}")
			print(f"  Size: {sprite_def.width_tiles}x{sprite_def.height_tiles} tiles")

			try:
				# Extract frames
				frames = self.extract_animation_frames(sprite_def)
				print(f"  ✓ Extracted {len(frames)} frame(s)")

				# Save individual frames
				# Map category to directory (handle plural forms)
				dir_name = sprite_def.category
				if sprite_def.category == "character":
					dir_name = "characters"
				elif sprite_def.category == "enemy":
					dir_name = "enemies"
				elif sprite_def.category == "effect":
					dir_name = "effects"

				category_dir = self.output_dir / dir_name
				category_dir.mkdir(exist_ok=True)

				for i, frame in enumerate(frames):
					if len(frames) > 1:
						frame_path = category_dir / \
							f"{sprite_def.name}_frame{i}.png"
					else:
						frame_path = category_dir / f"{sprite_def.name}.png"
					frame.save(frame_path)

				# Create sprite sheet if multiple frames
				if len(frames) > 1:
					sheet = self.create_sprite_sheet(
						frames, sprite_def.name)
					sheet_path = category_dir / \
						f"{sprite_def.name}_sheet.png"
					sheet.save(sheet_path)
					print(f"  ✓ Created sprite sheet: {sheet.width}x{sheet.height}px")

				# Export metadata
				meta_path = category_dir / f"{sprite_def.name}_meta.json"
				self.export_sprite_metadata(sprite_def, meta_path)

				print(f"  ✓ Saved to: {category_dir}")

			except Exception as e:
				print(f"  ✗ Error: {e}")


def main():
	"""Main sprite extraction routine."""
	print("=" * 70)
	print("FFMQ Sprite Extraction Tool")
	print("=" * 70)
	print()

	rom_path = "roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"

	print(f"Loading ROM: {rom_path}")
	try:
		extractor = SpriteExtractor(rom_path)
		print(f"✓ ROM loaded")
	except Exception as e:
		print(f"✗ Error: {e}")
		return 1

	# Load palettes
	print()
	extractor.load_palettes(16)

	# Extract character sprites
	print()
	print("=" * 70)
	print("Extracting Character Battle Sprites")
	print("=" * 70)
	extractor.extract_all_sprites(CHARACTER_SPRITES)

	# Extract UI elements
	print()
	print("=" * 70)
	print("Extracting UI Elements")
	print("=" * 70)
	extractor.extract_all_sprites(UI_SPRITES)

	# Extract sample enemy sprites
	print()
	print("=" * 70)
	print("Extracting Enemy Sprites (Sample)")
	print("=" * 70)
	extractor.extract_all_sprites(ENEMY_SPRITE_TEMPLATES)

	print()
	print("=" * 70)
	print("Sprite Extraction Complete!")
	print("=" * 70)
	print(f"Output: {extractor.output_dir}")
	print()
	print("Extracted:")
	print(f"  - {len(CHARACTER_SPRITES)} character sprites")
	print(f"  - {len(UI_SPRITES)} UI elements")
	print(f"  - {len(ENEMY_SPRITE_TEMPLATES)} enemy sprites (sample)")
	print()
	print("Next Steps:")
	print("  1. Review extracted sprites for accuracy")
	print("  2. Identify additional enemy sprite locations in ROM")
	print("  3. Map all animation frames for characters/enemies")
	print("  4. Document sprite tile ranges in bank_04_documented.asm")
	print("  5. Create comprehensive sprite catalog")
	print()
	print("Note: Sprite offsets are estimates based on typical SNES RPG")
	print("      organization. Verify with ROM inspection and disassembly.")

	return 0


if __name__ == '__main__':
	sys.exit(main())
