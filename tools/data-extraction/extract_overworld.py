#!/usr/bin/env python3
"""
Extract overworld graphics from FFMQ ROM.

This tool extracts overworld-specific graphics including:
- Map tileset (8×8 tiles for terrain, objects, etc.)
- Walking sprites (Benjamin and NPCs with 4 directions × 3 frames)
- Object sprites (chests, doors, switches, etc.)
- Overworld UI elements

Output: PNG images + JSON metadata compatible with existing pipeline.

Based on Bank 04 documentation and existing sprite extraction tools.
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

# Import our existing extraction infrastructure
from extraction.extract_graphics import GraphicsExtractor, Palette, RGB555Color
from extraction.extract_sprites import SpriteDefinition


# ============================================================================
# Overworld Tileset Definitions
# ============================================================================
# Based on Bank 04 analysis and typical SNES RPG overworld structure

OVERWORLD_TILESETS = {
	"hill_of_destiny": {
		"offset": 0x048000,  # Start of Bank 04
		"size": 0x1000,      # 256 tiles (4KB)
		"format": "4BPP",
		"tiles_wide": 16,
		"notes": "Starting area tileset - grass, rocks, trees"
	},
	"forest": {
		"offset": 0x049000,
		"size": 0x1000,
		"format": "4BPP",
		"tiles_wide": 16,
		"notes": "Forest area tileset - trees, bushes, paths"
	},
	"desert": {
		"offset": 0x04A000,
		"size": 0x1000,
		"format": "4BPP",
		"tiles_wide": 16,
		"notes": "Desert area tileset - sand, cacti, rocks"
	},
	"town": {
		"offset": 0x04B000,
		"size": 0x1000,
		"format": "4BPP",
		"tiles_wide": 16,
		"notes": "Town tileset - buildings, roads, decorations"
	},
}


# ============================================================================
# Overworld Sprite Definitions
# ============================================================================
# Walking sprites and NPC sprites with animations

WALKING_SPRITES = [
	SpriteDefinition(
		name="benjamin_walk",
		tile_offset=0x04C000,  # Estimated based on Bank 04 layout
		num_tiles=192,  # 4 directions × 3 frames × 16 tiles per frame
		width_tiles=2,
		height_tiles=2,
		palette_index=0,
		format="4BPP",
		category="overworld",
		frames=[0, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176],
		notes="Benjamin walking - 4 directions (up, down, left, right) × 3 frames each"
	),
	SpriteDefinition(
		name="kaeli_walk",
		tile_offset=0x04C600,
		num_tiles=192,
		width_tiles=2,
		height_tiles=2,
		palette_index=1,
		format="4BPP",
		category="overworld",
		frames=[0, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176],
		notes="Kaeli walking - 4 directions × 3 frames"
	),
	SpriteDefinition(
		name="phoebe_walk",
		tile_offset=0x04CC00,
		num_tiles=192,
		width_tiles=2,
		height_tiles=2,
		palette_index=2,
		format="4BPP",
		category="overworld",
		frames=[0, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176],
		notes="Phoebe walking - 4 directions × 3 frames"
	),
	SpriteDefinition(
		name="reuben_walk",
		tile_offset=0x04D200,
		num_tiles=192,
		width_tiles=2,
		height_tiles=2,
		palette_index=3,
		format="4BPP",
		category="overworld",
		frames=[0, 16, 32, 48, 64, 80, 96, 112, 128, 144, 160, 176],
		notes="Reuben walking - 4 directions × 3 frames"
	),
]


OBJECT_SPRITES = [
	SpriteDefinition(
		name="chest_closed",
		tile_offset=0x04D800,
		num_tiles=4,
		width_tiles=2,
		height_tiles=1,
		palette_index=10,
		format="4BPP",
		category="overworld",
		notes="Closed treasure chest"
	),
	SpriteDefinition(
		name="chest_open",
		tile_offset=0x04D840,
		num_tiles=4,
		width_tiles=2,
		height_tiles=1,
		palette_index=10,
		format="4BPP",
		category="overworld",
		notes="Open treasure chest"
	),
	SpriteDefinition(
		name="door",
		tile_offset=0x04D880,
		num_tiles=4,
		width_tiles=2,
		height_tiles=2,
		palette_index=11,
		format="4BPP",
		category="overworld",
		notes="Door sprite"
	),
	SpriteDefinition(
		name="switch",
		tile_offset=0x04D8C0,
		num_tiles=2,
		width_tiles=1,
		height_tiles=1,
		palette_index=11,
		format="4BPP",
		category="overworld",
		notes="Switch/lever"
	),
]


# ============================================================================
# NPC Sprite Definitions
# ============================================================================
# Various NPCs with limited animations

NPC_SPRITES = [
	SpriteDefinition(
		name="npc_old_man",
		tile_offset=0x04D900,
		num_tiles=16,
		width_tiles=2,
		height_tiles=2,
		palette_index=4,
		format="4BPP",
		category="overworld",
		frames=[0, 8],  # 2 idle frames
		notes="Old man NPC"
	),
	SpriteDefinition(
		name="npc_woman",
		tile_offset=0x04DA00,
		num_tiles=16,
		width_tiles=2,
		height_tiles=2,
		palette_index=5,
		format="4BPP",
		category="overworld",
		frames=[0, 8],
		notes="Woman NPC"
	),
	SpriteDefinition(
		name="npc_guard",
		tile_offset=0x04DB00,
		num_tiles=16,
		width_tiles=2,
		height_tiles=2,
		palette_index=6,
		format="4BPP",
		category="overworld",
		frames=[0, 8],
		notes="Guard NPC"
	),
]


class OverworldGraphicsExtractor:
	"""Extract overworld-specific graphics from FFMQ ROM."""

	def __init__(self, rom_path: str, output_dir: str = "data/extracted/overworld"):
		self.rom_path = rom_path
		self.output_dir = Path(output_dir)
		self.graphics_extractor = GraphicsExtractor(rom_path)

		# Create output directories
		self.tileset_dir = self.output_dir / "tilesets"
		self.sprite_dir = self.output_dir / "sprites"
		self.object_dir = self.output_dir / "objects"
		self.npc_dir = self.output_dir / "npcs"

		for d in [self.tileset_dir, self.sprite_dir, self.object_dir, self.npc_dir]:
			d.mkdir(parents=True, exist_ok=True)

	def extract_tileset(self, tileset_name: str, tileset_def: dict) -> bool:
		"""Extract a tileset to PNG + JSON."""
		print(f"\nExtracting tileset: {tileset_name}")
		print(f"  Offset: 0x{tileset_def['offset']:06X}")
		print(f"  Size: {tileset_def['size']} bytes")
		print(f"  Format: {tileset_def['format']}")

		try:
			# Extract tiles
			tiles = []
			tile_size = 32 if tileset_def['format'] == "4BPP" else 16
			num_tiles = tileset_def['size'] // tile_size

			for i in range(num_tiles):
				tile_offset = tileset_def['offset'] + (i * tile_size)

				if tileset_def['format'] == "4BPP":
					tile = self.graphics_extractor.decode_tile_4bpp(tile_offset)
				else:
					tile = self.graphics_extractor.decode_tile_2bpp(tile_offset)

				tiles.append(tile)

			# Create tileset image
			tiles_wide = tileset_def['tiles_wide']
			tiles_high = (num_tiles + tiles_wide - 1) // tiles_wide

			img = Image.new('RGB', (tiles_wide * 8, tiles_high * 8))

			# Default grayscale palette for preview
			palette = self._create_default_palette()

			for idx, tile in enumerate(tiles):
				tile_x = (idx % tiles_wide) * 8
				tile_y = (idx // tiles_wide) * 8

				for y in range(8):
					for x in range(8):
						color = palette[tile[y][x]]
						img.putpixel((tile_x + x, tile_y + y), color)

			# Save PNG
			output_path = self.tileset_dir / f"{tileset_name}.png"
			img.save(output_path)
			print(f"  ✓ Saved: {output_path}")

			# Save metadata
			metadata = {
				"name": tileset_name,
				"category": "tileset",
				"format": tileset_def['format'],
				"rom_offset": f"0x{tileset_def['offset']:06X}",
				"size_bytes": tileset_def['size'],
				"num_tiles": num_tiles,
				"dimensions": {
					"tiles_wide": tiles_wide,
					"tiles_high": tiles_high,
					"width_pixels": tiles_wide * 8,
					"height_pixels": tiles_high * 8
				},
				"notes": tileset_def['notes']
			}

			meta_path = self.tileset_dir / f"{tileset_name}_meta.json"
			with open(meta_path, 'w') as f:
				json.dump(metadata, f, indent=2)

			print(f"  ✓ Metadata: {meta_path}")
			return True

		except Exception as e:
			print(f"  ✗ Error: {e}")
			return False

	def extract_sprite(self, sprite_def: SpriteDefinition, output_dir: Path) -> bool:
		"""Extract a sprite with animation frames."""
		print(f"\nExtracting sprite: {sprite_def.name}")
		print(f"  Size: {sprite_def.width_tiles}×{sprite_def.height_tiles} tiles")
		print(f"  Frames: {len(sprite_def.frames) if sprite_def.frames else 1}")

		try:
			# Get tile size based on format
			tile_size = 32 if sprite_def.format == "4BPP" else 16

			# Extract each frame
			frames = []
			frame_offsets = sprite_def.frames if sprite_def.frames else [0]

			for frame_idx, frame_offset in enumerate(frame_offsets):
				# Create frame image
				width = sprite_def.width_tiles * 8
				height = sprite_def.height_tiles * 8
				frame_img = Image.new('RGB', (width, height))

				# Default palette
				palette = self._create_default_palette()

				# Extract tiles for this frame
				tiles_in_frame = sprite_def.width_tiles * sprite_def.height_tiles

				for tile_idx in range(tiles_in_frame):
					tile_file_offset = sprite_def.tile_offset + (frame_offset * tile_size) + (tile_idx * tile_size)

					if sprite_def.format == "4BPP":
						tile = self.graphics_extractor.decode_tile_4bpp(tile_file_offset)
					else:
						tile = self.graphics_extractor.decode_tile_2bpp(tile_file_offset)

					# Calculate tile position in frame
					tile_x = (tile_idx % sprite_def.width_tiles) * 8
					tile_y = (tile_idx // sprite_def.width_tiles) * 8

					# Draw tile
					for y in range(8):
						for x in range(8):
							pixel_value = tile[y][x]
							color = palette[pixel_value]
							frame_img.putpixel((tile_x + x, tile_y + y), color)

				frames.append(frame_img)

			# Save frames
			if len(frames) == 1:
				# Single frame sprite
				output_path = output_dir / f"{sprite_def.name}.png"
				frames[0].save(output_path)
				print(f"  ✓ Saved: {output_path}")
			else:
				# Multi-frame sprite - save individual frames and sprite sheet
				for idx, frame in enumerate(frames):
					frame_path = output_dir / f"{sprite_def.name}_frame{idx:02d}.png"
					frame.save(frame_path)

				# Create sprite sheet
				sheet_width = width * min(len(frames), 4)  # Max 4 frames per row
				sheet_height = height * ((len(frames) + 3) // 4)
				sprite_sheet = Image.new('RGB', (sheet_width, sheet_height))

				for idx, frame in enumerate(frames):
					x = (idx % 4) * width
					y = (idx // 4) * height
					sprite_sheet.paste(frame, (x, y))

				sheet_path = output_dir / f"{sprite_def.name}_sheet.png"
				sprite_sheet.save(sheet_path)
				print(f"  ✓ Saved {len(frames)} frames + sheet: {sheet_path}")

			# Save metadata
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
					"num_frames": len(frame_offsets),
					"frame_offsets": sprite_def.frames
				},
				"notes": sprite_def.notes
			}

			meta_path = output_dir / f"{sprite_def.name}_meta.json"
			with open(meta_path, 'w') as f:
				json.dump(metadata, f, indent=2)

			return True

		except Exception as e:
			print(f"  ✗ Error: {e}")
			import traceback
			traceback.print_exc()
			return False

	def _create_default_palette(self) -> List[Tuple[int, int, int]]:
		"""Create a default grayscale palette for preview."""
		return [(i * 17, i * 17, i * 17) for i in range(16)]

	def extract_all(self):
		"""Extract all overworld graphics."""
		print("=" * 80)
		print("FFMQ Overworld Graphics Extraction")
		print("=" * 80)

		# Extract tilesets
		print("\n" + "=" * 80)
		print("TILESETS")
		print("=" * 80)

		success_count = 0
		for name, tileset_def in OVERWORLD_TILESETS.items():
			if self.extract_tileset(name, tileset_def):
				success_count += 1

		print(f"\n✓ Extracted {success_count}/{len(OVERWORLD_TILESETS)} tilesets")

		# Extract walking sprites
		print("\n" + "=" * 80)
		print("WALKING SPRITES")
		print("=" * 80)

		success_count = 0
		for sprite_def in WALKING_SPRITES:
			if self.extract_sprite(sprite_def, self.sprite_dir):
				success_count += 1

		print(f"\n✓ Extracted {success_count}/{len(WALKING_SPRITES)} walking sprites")

		# Extract object sprites
		print("\n" + "=" * 80)
		print("OBJECT SPRITES")
		print("=" * 80)

		success_count = 0
		for sprite_def in OBJECT_SPRITES:
			if self.extract_sprite(sprite_def, self.object_dir):
				success_count += 1

		print(f"\n✓ Extracted {success_count}/{len(OBJECT_SPRITES)} object sprites")

		# Extract NPC sprites
		print("\n" + "=" * 80)
		print("NPC SPRITES")
		print("=" * 80)

		success_count = 0
		for sprite_def in NPC_SPRITES:
			if self.extract_sprite(sprite_def, self.npc_dir):
				success_count += 1

		print(f"\n✓ Extracted {success_count}/{len(NPC_SPRITES)} NPC sprites")

		# Summary
		print("\n" + "=" * 80)
		print("EXTRACTION COMPLETE")
		print("=" * 80)
		print(f"\nOutput directory: {self.output_dir}")
		print("\nNext steps:")
		print("1. Verify extracted graphics match expected content")
		print("2. Update sprite definitions if offsets are incorrect")
		print("3. Extract correct palettes from ROM for accurate colors")
		print("4. Integrate with build_integration.py for rebuild pipeline")


def main():
	"""Main extraction routine."""
	if len(sys.argv) < 2:
		print("Usage: python extract_overworld.py <rom_file> [output_dir]")
		print("Example: python extract_overworld.py roms/FFMQ.sfc data/extracted/overworld")
		return 1

	rom_path = sys.argv[1]
	output_dir = sys.argv[2] if len(sys.argv) > 2 else "data/extracted/overworld"

	if not os.path.exists(rom_path):
		print(f"Error: ROM file not found: {rom_path}")
		return 1

	extractor = OverworldGraphicsExtractor(rom_path, output_dir)
	extractor.extract_all()

	return 0


if __name__ == '__main__':
	sys.exit(main())
