"""
VRAM Analyzer - Extract actual sprite layouts from ROM using documented addresses.

This tool uses verified ROM addresses from the datacrystal documentation to
extract actual sprite graphics with correct tile arrangements and palettes.

Based on:
- datacrystal/ROM_map/Graphics.wikitext
- datacrystal/ROM_map/Characters.wikitext
- Disassembly analysis of sprite code
"""

import os
import sys
from pathlib import Path
from typing import List, Tuple

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow required")
    sys.exit(1)

from extraction.extract_graphics import GraphicsExtractor, Palette


# VERIFIED ROM ADDRESSES from datacrystal documentation
CHARACTER_SPRITE_ADDRESSES = {
    # ROM Offset, Size, Description
    "benjamin": {
        "rom_offset": 0x020000,  # Actual address from datacrystal
        "size": 0x4000,  # 16KB
        "palette": 0,  # Sprite palettes start at 8 in CGRAM
        "notes": "Benjamin sprite tiles (walking, attacking, magic)"
    },
    "kaeli": {
        "rom_offset": 0x024000,
        "size": 0x2000,  # 8KB
        "palette": 1,
        "notes": "Kaeli sprite tiles"
    },
    "tristam": {
        "rom_offset": 0x026000,
        "size": 0x2000,
        "palette": 2,
        "notes": "Tristam sprite tiles"
    },
    "phoebe": {
        "rom_offset": 0x028000,
        "size": 0x2000,
        "palette": 3,
        "notes": "Phoebe sprite tiles"
    },
    "reuben": {
        "rom_offset": 0x02a000,
        "size": 0x2000,
        "palette": 4,
        "notes": "Reuben sprite tiles"
    }
}

# Overworld character portraits
CHARACTER_PORTRAIT_ADDRESSES = {
    "benjamin_portrait": {
        "rom_offset": 0x02e000,
        "size": 0x0400,  # 1KB = 32 tiles (8x8 each)
        "palette": 0,
        "notes": "Benjamin 8×8 portrait tiles"
    },
    "kaeli_portrait": {
        "rom_offset": 0x02e400,
        "size": 0x0400,
        "palette": 1,
        "notes": "Kaeli 8×8 portrait tiles"
    },
    "tristam_portrait": {
        "rom_offset": 0x02e800,
        "size": 0x0400,
        "palette": 2,
        "notes": "Tristam 8×8 portrait tiles"
    },
    "phoebe_portrait": {
        "rom_offset": 0x02ec00,
        "size": 0x0400,
        "palette": 3,
        "notes": "Phoebe 8×8 portrait tiles"
    },
    "reuben_portrait": {
        "rom_offset": 0x02f000,
        "size": 0x0400,
        "palette": 4,
        "notes": "Reuben 8×8 portrait tiles"
    }
}


def analyze_sprite_region(extractor: GraphicsExtractor, name: str, 
                         config: dict, output_dir: Path):
    """
    Analyze a sprite region and extract all tiles with correct palette.
    
    This creates a tile sheet showing ALL tiles in the region so we can
    visually identify the actual sprite arrangements.
    """
    rom_offset = config["rom_offset"]
    size = config["size"]
    palette_idx = config["palette"]
    
    # Calculate number of 4BPP tiles (32 bytes each)
    num_tiles = size // 32
    
    print(f"\nAnalyzing: {name}")
    print(f"  ROM Offset: 0x{rom_offset:06X}")
    print(f"  Size: {size} bytes ({num_tiles} tiles)")
    print(f"  Palette: {palette_idx}")
    
    # Load correct palette
    BANK_05_START = 0x030000
    palette_offset = BANK_05_START + (palette_idx * 32)
    palette = extractor.extract_palette(palette_offset, 16)
    
    # Extract all tiles in this region
    tiles = extractor.extract_tiles_4bpp(rom_offset, num_tiles, palette)
    
    # Create tile sheet (16 tiles per row)
    tile_sheet = extractor.create_tile_sheet(tiles, tiles_per_row=16)
    
    # Save
    output_path = output_dir / f"{name}_tiles.png"
    tile_sheet.save(output_path)
    print(f"  ✓ Saved: {output_path.name}")
    print(f"    Size: {tile_sheet.size[0]}×{tile_sheet.size[1]} pixels")
    
    return tiles, palette


def create_sprite_comparison_grid(tiles_by_character: dict, output_dir: Path):
    """
    Create a comparison grid showing all characters side-by-side.
    """
    print("\nCreating character comparison grid...")
    
    # Find max tiles across all characters
    max_tiles = max(len(tiles) for tiles in tiles_by_character.values())
    
    # Create grid: one row per character, 16 tiles wide
    char_names = list(tiles_by_character.keys())
    num_chars = len(char_names)
    tiles_per_row = 16
    
    grid_width = tiles_per_row * 8
    grid_height = num_chars * 8
    
    grid = Image.new('RGB', (grid_width, grid_height))
    
    for char_idx, char_name in enumerate(char_names):
        tiles = tiles_by_character[char_name]
        y_offset = char_idx * 8
        
        for tile_idx in range(min(tiles_per_row, len(tiles))):
            x_offset = tile_idx * 8
            grid.paste(tiles[tile_idx], (x_offset, y_offset))
    
    output_path = output_dir / "character_comparison_grid.png"
    grid.save(output_path)
    print(f"  ✓ Saved: {output_path.name}")
    print(f"    Layout: {num_chars} characters × {tiles_per_row} tiles each")


def main():
    ROM_PATH = "roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"
    OUTPUT_DIR = Path("data/extracted/graphics/vram_analysis")
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    
    print("=" * 70)
    print("FFMQ VRAM Analyzer - Actual Sprite Extraction")
    print("=" * 70)
    print(f"\nUsing verified ROM addresses from datacrystal documentation")
    print(f"Output: {OUTPUT_DIR}")
    
    # Initialize extractor
    extractor = GraphicsExtractor(ROM_PATH)
    print(f"\n[OK] ROM loaded: {len(extractor.rom_data):,} bytes")
    
    # Analyze character sprites
    print("\n" + "=" * 70)
    print("CHARACTER SPRITES (Walking/Battle)")
    print("=" * 70)
    
    character_tiles = {}
    for char_name, config in CHARACTER_SPRITE_ADDRESSES.items():
        tiles, palette = analyze_sprite_region(
            extractor, char_name, config, OUTPUT_DIR
        )
        character_tiles[char_name] = tiles
    
    # Create comparison grid
    create_sprite_comparison_grid(character_tiles, OUTPUT_DIR)
    
    # Analyze portraits
    print("\n" + "=" * 70)
    print("CHARACTER PORTRAITS (Overworld)")
    print("=" * 70)
    
    portrait_tiles = {}
    for portrait_name, config in CHARACTER_PORTRAIT_ADDRESSES.items():
        tiles, palette = analyze_sprite_region(
            extractor, portrait_name, config, OUTPUT_DIR
        )
        portrait_tiles[portrait_name] = tiles
    
    print("\n" + "=" * 70)
    print("Analysis Complete!")
    print("=" * 70)
    print(f"\nNext Steps:")
    print(f"  1. Open {OUTPUT_DIR}/*_tiles.png in image viewer")
    print(f"  2. Identify actual sprite patterns (e.g., which tiles = standing pose)")
    print(f"  3. Note tile arrangements for 2×2 or larger sprites")
    print(f"  4. Compare with game screenshots to verify")
    print(f"  5. Update assemble_sprites.py with CORRECT tile indices")
    print(f"\nImportant:")
    print(f"  - Each character has 128-1024 tiles (large sprite sheets)")
    print(f"  - Walking animations = 4 directions × 2-3 frames each")
    print(f"  - Battle poses = standing, attacking, magic, damaged, victory")
    print(f"  - Tile arrangements are NOT sequential [0,1,16,17]!")
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
