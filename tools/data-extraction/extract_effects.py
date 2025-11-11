#!/usr/bin/env python3
"""
Extract magic effect and battle animation graphics from FFMQ ROM.

This tool extracts:
- Spell effect animations (Fire, Ice, Thunder, Cure, etc.)
- Battle animations (weapon attacks, criticals)
- Status effect graphics
- Particle effects

Output: PNG images + JSON metadata for animation frames.

Based on Bank 04 graphics analysis.
"""

import os
import sys
import json
from pathlib import Path
from typing import List, Dict, Tuple, Optional
from dataclasses import dataclass

# Add parent directory for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
	from PIL import Image
except ImportError:
	print("ERROR: Pillow required")
	print("Install: pip install Pillow")
	sys.exit(1)

# Import existing infrastructure
from extraction.extract_graphics import GraphicsExtractor
from extraction.extract_sprites import SpriteDefinition


# ============================================================================
# Magic Effect Definitions
# ============================================================================
# Based on Bank 04 analysis - these are estimated offsets

SPELL_EFFECTS = [
	SpriteDefinition(
		name="fire_effect",
		tile_offset=0x04E000,  # Estimated
		num_tiles=64,  # 8 frames × 8 tiles per frame
		width_tiles=2,
		height_tiles=2,
		palette_index=8,
		format="4BPP",
		category="effect",
		frames=[0, 8, 16, 24, 32, 40, 48, 56],  # 8 animation frames
		notes="Fire spell effect animation - 8 frames"
	),
	SpriteDefinition(
		name="ice_effect",
		tile_offset=0x04E400,
		num_tiles=64,
		width_tiles=2,
		height_tiles=2,
		palette_index=9,
		format="4BPP",
		category="effect",
		frames=[0, 8, 16, 24, 32, 40, 48, 56],
		notes="Ice spell effect animation - 8 frames"
	),
	SpriteDefinition(
		name="thunder_effect",
		tile_offset=0x04E800,
		num_tiles=64,
		width_tiles=2,
		height_tiles=3,
		palette_index=10,
		format="4BPP",
		category="effect",
		frames=[0, 12, 24, 36, 48, 60],  # 6 frames (taller sprite)
		notes="Thunder spell effect animation - 6 frames"
	),
	SpriteDefinition(
		name="cure_effect",
		tile_offset=0x04EC00,
		num_tiles=32,
		width_tiles=2,
		height_tiles=2,
		palette_index=11,
		format="4BPP",
		category="effect",
		frames=[0, 8, 16, 24],  # 4 frames
		notes="Cure spell effect animation - 4 frames"
	),
	SpriteDefinition(
		name="white_magic_effect",
		tile_offset=0x04EE00,
		num_tiles=32,
		width_tiles=2,
		height_tiles=2,
		palette_index=12,
		format="4BPP",
		category="effect",
		frames=[0, 8, 16, 24],
		notes="White magic effect - 4 frames"
	),
	SpriteDefinition(
		name="wizard_magic_effect",
		tile_offset=0x04F000,
		num_tiles=32,
		width_tiles=2,
		height_tiles=2,
		palette_index=13,
		format="4BPP",
		category="effect",
		frames=[0, 8, 16, 24],
		notes="Wizard magic effect - 4 frames"
	),
]


# Weapon attack animations
ATTACK_EFFECTS = [
	SpriteDefinition(
		name="sword_slash",
		tile_offset=0x04F200,
		num_tiles=24,
		width_tiles=3,
		height_tiles=2,
		palette_index=14,
		format="4BPP",
		category="effect",
		frames=[0, 6, 12, 18],  # 4 frames
		notes="Sword slash animation - 4 frames"
	),
	SpriteDefinition(
		name="axe_swing",
		tile_offset=0x04F380,
		num_tiles=24,
		width_tiles=3,
		height_tiles=2,
		palette_index=14,
		format="4BPP",
		category="effect",
		frames=[0, 6, 12, 18],
		notes="Axe swing animation - 4 frames"
	),
	SpriteDefinition(
		name="critical_hit",
		tile_offset=0x04F500,
		num_tiles=16,
		width_tiles=2,
		height_tiles=2,
		palette_index=15,
		format="4BPP",
		category="effect",
		frames=[0, 8],  # 2 frames (flash effect)
		notes="Critical hit flash - 2 frames"
	),
]


# Status effects
STATUS_EFFECTS = [
	SpriteDefinition(
		name="poison_effect",
		tile_offset=0x04F600,
		num_tiles=16,
		width_tiles=2,
		height_tiles=2,
		palette_index=7,
		format="4BPP",
		category="effect",
		frames=[0, 8],  # 2 frames (bubbles)
		notes="Poison status bubbles - 2 frames"
	),
	SpriteDefinition(
		name="confusion_stars",
		tile_offset=0x04F700,
		num_tiles=8,
		width_tiles=2,
		height_tiles=1,
		palette_index=7,
		format="4BPP",
		category="effect",
		frames=[0, 4],  # 2 frames
		notes="Confusion stars - 2 frames"
	),
	SpriteDefinition(
		name="sleep_zzz",
		tile_offset=0x04F780,
		num_tiles=4,
		width_tiles=1,
		height_tiles=1,
		palette_index=7,
		format="4BPP",
		category="effect",
		frames=[0, 2],  # 2 frames
		notes="Sleep Z's - 2 frames"
	),
]


# Particle effects
PARTICLE_EFFECTS = [
	SpriteDefinition(
		name="sparkle",
		tile_offset=0x04F800,
		num_tiles=16,
		width_tiles=1,
		height_tiles=1,
		palette_index=15,
		format="4BPP",
		category="effect",
		frames=[0, 2, 4, 6, 8, 10, 12, 14],  # 8 frames
		notes="Sparkle particle - 8 frames"
	),
	SpriteDefinition(
		name="explosion_small",
		tile_offset=0x04F880,
		num_tiles=24,
		width_tiles=2,
		height_tiles=2,
		palette_index=14,
		format="4BPP",
		category="effect",
		frames=[0, 8, 16],  # 3 frames
		notes="Small explosion - 3 frames"
	),
	SpriteDefinition(
		name="magic_circle",
		tile_offset=0x04F980,
		num_tiles=32,
		width_tiles=4,
		height_tiles=2,
		palette_index=13,
		format="4BPP",
		category="effect",
		frames=[0, 8, 16, 24],  # 4 frames (rotating)
		notes="Magic circle - 4 frames"
	),
]


class EffectGraphicsExtractor:
	"""Extract effect graphics from FFMQ ROM."""

	def __init__(self, rom_path: str, output_dir: str = "data/extracted/effects"):
		self.rom_path = rom_path
		self.output_dir = Path(output_dir)
		self.graphics_extractor = GraphicsExtractor(rom_path)

		# Create category directories
		self.spells_dir = self.output_dir / "spells"
		self.attacks_dir = self.output_dir / "attacks"
		self.status_dir = self.output_dir / "status"
		self.particles_dir = self.output_dir / "particles"

		for d in [self.spells_dir, self.attacks_dir, self.status_dir, self.particles_dir]:
			d.mkdir(parents=True, exist_ok=True)

	def extract_effect(self, effect_def: SpriteDefinition, output_dir: Path) -> bool:
		"""Extract an effect animation."""
		print(f"\n{effect_def.name}")
		print(f"  Frames: {len(effect_def.frames)}")
		print(f"  Size: {effect_def.width_tiles}×{effect_def.height_tiles} tiles")

		try:
			tile_size = 32 if effect_def.format == "4BPP" else 16

			# Extract each frame
			frames = []
			for frame_offset in effect_def.frames:
				# Create frame image
				width = effect_def.width_tiles * 8
				height = effect_def.height_tiles * 8
				frame_img = Image.new('RGBA', (width, height), (0, 0, 0, 0))

				# Default palette with transparency
				palette = self._create_effect_palette()

				# Extract tiles for this frame
				tiles_in_frame = effect_def.width_tiles * effect_def.height_tiles

				for tile_idx in range(tiles_in_frame):
					tile_file_offset = effect_def.tile_offset + (frame_offset * tile_size) + (tile_idx * tile_size)

					if effect_def.format == "4BPP":
						tile = self.graphics_extractor.decode_tile_4bpp(tile_file_offset)
					else:
						tile = self.graphics_extractor.decode_tile_2bpp(tile_file_offset)

					# Calculate tile position
					tile_x = (tile_idx % effect_def.width_tiles) * 8
					tile_y = (tile_idx // effect_def.width_tiles) * 8

					# Draw tile with transparency
					for y in range(8):
						for x in range(8):
							pixel_value = tile[y][x]
							color = palette[pixel_value]
							frame_img.putpixel((tile_x + x, tile_y + y), color)

				frames.append(frame_img)

			# Save individual frames
			for idx, frame in enumerate(frames):
				frame_path = output_dir / f"{effect_def.name}_frame{idx:02d}.png"
				frame.save(frame_path)

			# Create sprite sheet
			width = effect_def.width_tiles * 8
			height = effect_def.height_tiles * 8
			frames_per_row = min(len(frames), 8)
			sheet_width = width * frames_per_row
			sheet_height = height * ((len(frames) + frames_per_row - 1) // frames_per_row)

			sprite_sheet = Image.new('RGBA', (sheet_width, sheet_height), (0, 0, 0, 0))

			for idx, frame in enumerate(frames):
				x = (idx % frames_per_row) * width
				y = (idx // frames_per_row) * height
				sprite_sheet.paste(frame, (x, y))

			sheet_path = output_dir / f"{effect_def.name}_sheet.png"
			sprite_sheet.save(sheet_path)
			print(f"  ✓ Saved {len(frames)} frames + sheet")

			# Save metadata
			metadata = {
				"name": effect_def.name,
				"category": effect_def.category,
				"format": effect_def.format,
				"rom_offset": f"0x{effect_def.tile_offset:06X}",
				"dimensions": {
					"width_tiles": effect_def.width_tiles,
					"height_tiles": effect_def.height_tiles,
					"width_pixels": effect_def.width_tiles * 8,
					"height_pixels": effect_def.height_tiles * 8
				},
				"palette_index": effect_def.palette_index,
				"animation": {
					"num_frames": len(effect_def.frames),
					"frame_offsets": effect_def.frames,
					"frame_rate": "60 FPS (game speed)"
				},
				"notes": effect_def.notes
			}

			meta_path = output_dir / f"{effect_def.name}_meta.json"
			with open(meta_path, 'w') as f:
				json.dump(metadata, f, indent=2)

			return True

		except Exception as e:
			print(f"  ✗ Error: {e}")
			import traceback
			traceback.print_exc()
			return False

	def _create_effect_palette(self) -> List[Tuple[int, int, int, int]]:
		"""Create palette with transparency for effects."""
		palette = []
		for i in range(16):
			if i == 0:
				# Transparent
				palette.append((0, 0, 0, 0))
			else:
				# Visible colors (grayscale preview)
				val = i * 17
				palette.append((val, val, val, 255))
		return palette

	def extract_all(self):
		"""Extract all effect graphics."""
		print("=" * 80)
		print("FFMQ Effect Graphics Extraction")
		print("=" * 80)

		# Extract spell effects
		print("\n" + "=" * 80)
		print("SPELL EFFECTS")
		print("=" * 80)

		success_count = 0
		for effect_def in SPELL_EFFECTS:
			if self.extract_effect(effect_def, self.spells_dir):
				success_count += 1

		print(f"\n✓ Extracted {success_count}/{len(SPELL_EFFECTS)} spell effects")

		# Extract attack effects
		print("\n" + "=" * 80)
		print("ATTACK EFFECTS")
		print("=" * 80)

		success_count = 0
		for effect_def in ATTACK_EFFECTS:
			if self.extract_effect(effect_def, self.attacks_dir):
				success_count += 1

		print(f"\n✓ Extracted {success_count}/{len(ATTACK_EFFECTS)} attack effects")

		# Extract status effects
		print("\n" + "=" * 80)
		print("STATUS EFFECTS")
		print("=" * 80)

		success_count = 0
		for effect_def in STATUS_EFFECTS:
			if self.extract_effect(effect_def, self.status_dir):
				success_count += 1

		print(f"\n✓ Extracted {success_count}/{len(STATUS_EFFECTS)} status effects")

		# Extract particle effects
		print("\n" + "=" * 80)
		print("PARTICLE EFFECTS")
		print("=" * 80)

		success_count = 0
		for effect_def in PARTICLE_EFFECTS:
			if self.extract_effect(effect_def, self.particles_dir):
				success_count += 1

		print(f"\n✓ Extracted {success_count}/{len(PARTICLE_EFFECTS)} particle effects")

		# Summary
		print("\n" + "=" * 80)
		print("EXTRACTION COMPLETE")
		print("=" * 80)
		print(f"\nOutput directory: {self.output_dir}")
		print("\nCategories extracted:")
		print(f"  - Spell effects: {len(SPELL_EFFECTS)}")
		print(f"  - Attack effects: {len(ATTACK_EFFECTS)}")
		print(f"  - Status effects: {len(STATUS_EFFECTS)}")
		print(f"  - Particle effects: {len(PARTICLE_EFFECTS)}")
		print(f"\nTotal: {len(SPELL_EFFECTS) + len(ATTACK_EFFECTS) + len(STATUS_EFFECTS) + len(PARTICLE_EFFECTS)} effects")
		print("\nNext steps:")
		print("1. Verify extracted animations match game effects")
		print("2. Update offsets if graphics don't match expected content")
		print("3. Extract correct palettes for accurate colors")
		print("4. Create import tool for effect modifications")


def main():
	"""Main extraction routine."""
	if len(sys.argv) < 2:
		print("Usage: python extract_effects.py <rom_file> [output_dir]")
		print("Example: python extract_effects.py roms/FFMQ.sfc data/extracted/effects")
		return 1

	rom_path = sys.argv[1]
	output_dir = sys.argv[2] if len(sys.argv) > 2 else "data/extracted/effects"

	if not os.path.exists(rom_path):
		print(f"Error: ROM file not found: {rom_path}")
		return 1

	extractor = EffectGraphicsExtractor(rom_path, output_dir)
	extractor.extract_all()

	return 0


if __name__ == '__main__':
	sys.exit(main())
