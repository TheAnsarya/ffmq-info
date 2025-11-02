"""
Re-extract all 83 enemy sprites with CORRECT enemy-specific palettes.

Uses enemy_palettes.json from Bank 09 to render sprites with accurate colors
that match the game's appearance.
"""

import os
import sys
import json
from pathlib import Path
from typing import List, Dict
from PIL import Image

sys.path.insert(0, str(Path(__file__).parent.parent))

from extraction.extract_sprites import SpriteDefinition
from extraction.extract_graphics import GraphicsExtractor, Palette, RGB555Color


def load_enemy_palettes() -> Dict[int, Palette]:
    """Load enemy-specific palettes from Bank 09 extraction."""
    palettes_path = Path("data/extracted/palettes/enemy_palettes.json")

    with open(palettes_path) as f:
        data = json.load(f)

    palettes = {}
    for pal_entry in data['palettes']:
        enemy_id = pal_entry['enemy_id']

        # Convert RGB to RGB555Color objects
        colors = []
        for color_data in pal_entry['colors']:
            r, g, b = color_data['rgb']
            # Convert back to 5-bit values
            r5 = r >> 3
            g5 = g >> 3
            b5 = b >> 3
            colors.append(RGB555Color(r5, g5, b5))

        palette = Palette(
            colors=colors,
            name=f"enemy_{enemy_id:02d}_{pal_entry['enemy_name'].lower().replace(' ', '_')}",
            offset=int(pal_entry['rom_offset'], 16)
        )
        palettes[enemy_id] = palette

    return palettes


def load_enemy_sprite_definitions(json_path: str) -> List[SpriteDefinition]:
    """Load sprite definitions from JSON."""
    with open(json_path) as f:
        data = json.load(f)

    sprite_defs = []
    for sprite in data['sprites']:
        tile_offset = int(sprite['tile_offset'], 16)

        sprite_def = SpriteDefinition(
            name=sprite['name'],
            tile_offset=tile_offset,
            num_tiles=sprite['num_tiles'],
            width_tiles=sprite['width_tiles'],
            height_tiles=sprite['height_tiles'],
            palette_index=0,  # Will be overridden per enemy
            format=sprite['format'],
            category=sprite['category'],
            frames=[],
            notes=sprite['notes']
        )
        sprite_defs.append(sprite_def)

    return sprite_defs


def create_enemy_sprite_mapping(sprite_defs: List[SpriteDefinition]) -> Dict:
    """Create mapping of enemy IDs to sprite definitions."""
    with open("data/extracted/sprites/enemy_sprite_defs.json") as f:
        metadata = json.load(f)

    enemy_to_sprite = {}

    for i, sprite_data in enumerate(metadata['sprites']):
        sprite_def = sprite_defs[i]
        enemy_ids = sprite_data['enemy_ids']
        primary_id = enemy_ids[0]
        is_shared = len(enemy_ids) > 1

        for enemy_id in enemy_ids:
            enemy_to_sprite[enemy_id] = {
                'sprite_def': sprite_def,
                'is_shared': is_shared,
                'primary_enemy': primary_id,
                'shared_with': enemy_ids if is_shared else None
            }

    return enemy_to_sprite


def extract_sprite_with_palette(extractor: GraphicsExtractor,
                                  sprite_def: SpriteDefinition,
                                  palette: Palette) -> Image.Image:
    """Extract sprite using specific palette (4BPP format)."""
    # Extract tiles
    tiles = extractor.extract_tiles_4bpp(
        sprite_def.tile_offset,
        sprite_def.num_tiles,
        palette
    )

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
        palette_colors = palette.to_rgb888_list()

        for py in range(8):
            for px in range(8):
                idx = py * 8 + px
                color = pixels[idx]
                # Color index 0 is transparent
                if color == palette_colors[0]:
                    tile_rgba.putpixel((px, py), (0, 0, 0, 0))
                else:
                    tile_rgba.putpixel((px, py), color + (255,))

        sprite.paste(tile_rgba, (x, y), tile_rgba)

    return sprite


def main():
    """Re-extract all enemy sprites with correct palettes."""
    print("=" * 80)
    print("FFMQ Enemy Sprite Re-extraction (With Correct Palettes)")
    print("=" * 80)
    print()

    rom_path = "roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"

    # Load enemy palettes from Bank 09
    print("Loading enemy-specific palettes from Bank 09...")
    enemy_palettes = load_enemy_palettes()
    print(f"* Loaded {len(enemy_palettes)} enemy palettes")

    # Load sprite definitions
    sprite_defs_path = "data/extracted/sprites/enemy_sprite_defs.json"
    print(f"\nLoading sprite definitions: {sprite_defs_path}")
    sprite_defs = load_enemy_sprite_definitions(sprite_defs_path)
    print(f"* Loaded {len(sprite_defs)} unique sprite definitions")

    # Load enemy names
    print("\nLoading enemy data...")
    enemies_path = Path("data/extracted/enemies/enemies.json")
    if enemies_path.exists():
        with open(enemies_path) as f:
            data = json.load(f)
            enemy_names = {e['id']: e['name'] for e in data['enemies']}
    else:
        enemy_names = {}
    print(f"* Loaded {len(enemy_names)} enemy names")

    # Create enemy->sprite mapping
    print("\nCreating enemy-to-sprite mapping...")
    enemy_mapping = create_enemy_sprite_mapping(sprite_defs)
    print(f"* Mapped {len(enemy_mapping)} enemies to sprites")

    # Initialize extractor
    print(f"\nLoading ROM: {rom_path}")
    extractor = GraphicsExtractor(rom_path)
    print("* ROM loaded")

    # Extract each enemy with its specific palette
    print("\n" + "=" * 80)
    print("Re-Extracting Enemy Sprites (With Correct Colors)")
    print("=" * 80)
    print()

    output_dir = Path("data/extracted/sprites/enemies")
    output_dir.mkdir(parents=True, exist_ok=True)

    errors = []
    extracted = 0

    for enemy_id in range(83):
        if enemy_id not in enemy_mapping or enemy_id not in enemy_palettes:
            print(f"! Enemy {enemy_id}: Missing data")
            errors.append(f"Enemy {enemy_id}: Missing mapping or palette")
            continue

        mapping = enemy_mapping[enemy_id]
        sprite_def = mapping['sprite_def']
        palette = enemy_palettes[enemy_id]
        enemy_name = enemy_names.get(enemy_id, f"Enemy_{enemy_id:02d}")

        # Create enemy-specific sprite def
        enemy_sprite_def = SpriteDefinition(
            name=f"enemy_{enemy_id:02d}_{sprite_def.name}",
            tile_offset=sprite_def.tile_offset,
            num_tiles=sprite_def.num_tiles,
            width_tiles=sprite_def.width_tiles,
            height_tiles=sprite_def.height_tiles,
            palette_index=enemy_id,
            format=sprite_def.format,
            category="enemy",
            frames=[],
            notes=f"{enemy_name} (ID {enemy_id}) - Palette from Bank 09"
        )

        # Show what we're extracting
        shared_info = ""
        if mapping['is_shared'] and enemy_id != mapping['primary_enemy']:
            primary_name = enemy_names.get(
                mapping['primary_enemy'], f"Enemy_{mapping['primary_enemy']:02d}")
            shared_info = f" (shares graphics with {primary_name})"

        print(f"[{enemy_id:2d}] {enemy_name:<25} {sprite_def.width_tiles}x{sprite_def.height_tiles} tiles{shared_info}")

        try:
            # Extract sprite with enemy-specific palette
            sprite = extract_sprite_with_palette(extractor, enemy_sprite_def, palette)

            # Save
            sprite_path = output_dir / f"{enemy_sprite_def.name}.png"
            sprite.save(sprite_path)

            # Export metadata
            meta_path = output_dir / f"{enemy_sprite_def.name}_meta.json"
            metadata = {
                'name': enemy_sprite_def.name,
                'enemy_id': enemy_id,
                'enemy_name': enemy_name,
                'category': 'enemy',
                'format': '4BPP',
                'rom_offset': f"0x{enemy_sprite_def.tile_offset:06X}",
                'palette_offset': f"0x{palette.offset:06X}",
                'dimensions': {
                    'width_tiles': enemy_sprite_def.width_tiles,
                    'height_tiles': enemy_sprite_def.height_tiles,
                    'width_pixels': enemy_sprite_def.width_tiles * 8,
                    'height_pixels': enemy_sprite_def.height_tiles * 8
                },
                'num_tiles': enemy_sprite_def.num_tiles,
                'shares_graphics': mapping['is_shared'],
                'shared_with': mapping['shared_with'] if mapping['is_shared'] else None,
                'notes': enemy_sprite_def.notes
            }

            with open(meta_path, 'w') as f:
                json.dump(metadata, f, indent=2)

            extracted += 1

        except Exception as e:
            print(f"  X Error: {e}")
            errors.append(f"Enemy {enemy_id} ({enemy_name}): {e}")

    # Print summary
    print()
    print("=" * 80)
    print("Re-Extraction Summary")
    print("=" * 80)
    print(f"Total Enemies: 83")
    print(f"Successfully Extracted: {extracted}")
    print(f"Errors: {len(errors)}")

    if errors:
        print("\nErrors encountered:")
        for error in errors:
            print(f"  - {error}")

    print()
    print("* Enemy sprite re-extraction complete with correct palettes!")
    print(f"* Output: {output_dir}")
    print()
    print("Next Steps:")
    print("  1. Verify sprites look correct (check skeleton, etc.)")
    print("  2. Regenerate visual catalog with create_sprite_catalog.py")
    print("  3. Compare with in-game screenshots")
    print()

    return 0 if len(errors) == 0 else 1


if __name__ == '__main__':
    sys.exit(main())
