#!/usr/bin/env python3
"""
Import graphics from PNG/JSON back to SNES ROM format.

This tool is the reverse of extract_graphics.py - it converts modern formats
back to SNES tile and palette data for ROM insertion.

Features:
    - PNG → SNES tiles (2BPP/4BPP)
    - RGB888 → RGB555 palette conversion
    - Sprite sheet → individual tiles
    - Graphics compression (3BPP, LZ)
    - Validation against SNES constraints
"""

import os
import sys
import json
import struct
from pathlib import Path
from typing import List, Tuple, Optional
from dataclasses import dataclass

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow library required for graphics import")
    print("Install with: pip install Pillow")
    sys.exit(1)

# Import compression tools
try:
    from ffmq_compression import (
        ExpandSecondHalfWithZeros,
        SimpleTailWindowCompression
    )
except ImportError:
    print("WARNING: ffmq_compression.py not found - compression features disabled")
    ExpandSecondHalfWithZeros = None
    SimpleTailWindowCompression = None


@dataclass
class RGB555Color:
    """SNES RGB555 color (15-bit BGR format)."""
    r: int  # 0-31 (5-bit)
    g: int  # 0-31 (5-bit)
    b: int  # 0-31 (5-bit)

    @classmethod
    def from_rgb888(cls, r8: int, g8: int, b8: int) -> 'RGB555Color':
        """
        Convert RGB888 (8-bit channels) to RGB555 (5-bit channels).

        Formula: RGB555 = RGB888 >> 3
        This compresses 8-bit value (0-255) to 5 bits (0-31).
        """
        r5 = r8 >> 3
        g5 = g8 >> 3
        b5 = b8 >> 3
        return cls(r5, g5, b5)

    def to_bytes(self) -> bytes:
        """
        Convert to 2-byte little-endian RGB555 format.

        Format: 0bbbbbgggggrrrrr
        Byte 0 (LOW):  gggrrrrr (bits 0-7)
        Byte 1 (HIGH): 0bbbbbgg (bits 8-15)
        """
        word = (self.b << 10) | (self.g << 5) | self.r
        low = word & 0xFF
        high = (word >> 8) & 0xFF
        return bytes([low, high])


@dataclass
class SNESPalette:
    """SNES palette (16 colors max)."""
    colors: List[RGB555Color]
    name: str = ""

    def to_bytes(self) -> bytes:
        """Export palette as SNES binary format."""
        data = bytearray()
        for color in self.colors:
            data.extend(color.to_bytes())
        return bytes(data)

    @classmethod
    def from_json(cls, json_path: Path) -> 'SNESPalette':
        """Load palette from JSON file (extract_graphics.py format)."""
        with open(json_path, 'r') as f:
            data = json.load(f)

        colors = []
        # Prefer RGB888 if available, otherwise use RGB555
        if 'colors_rgb888' in data:
            for c in data['colors_rgb888']:
                colors.append(RGB555Color.from_rgb888(c['r'], c['g'], c['b']))
        elif 'colors_rgb555' in data:
            for c in data['colors_rgb555']:
                colors.append(RGB555Color(c['r5'], c['g5'], c['b5']))
        else:
            raise ValueError("JSON must contain colors_rgb888 or colors_rgb555")

        return cls(colors=colors, name=data.get('name', ''))


class GraphicsImporter:
    """Import graphics from PNG/JSON to SNES format."""

    def __init__(self):
        """Initialize graphics importer."""
        pass

    def image_to_2bpp_tile(self, img: Image.Image,
                           palette: SNESPalette) -> bytes:
        """
        Convert 8x8 PIL Image to 2BPP tile data.

        Args:
            img: 8x8 PIL Image
            palette: Palette to use for color indices

        Returns:
            16 bytes of 2BPP tile data
        """
        if img.size != (8, 8):
            raise ValueError(f"Tile must be 8x8, got {img.size}")

        # Convert image to RGB if needed
        if img.mode != 'RGB':
            img = img.convert('RGB')

        # Build palette lookup
        palette_rgb = [(c.r << 3, c.g << 3, c.b << 3) for c in palette.colors]

        # Extract pixel indices
        pixels = []
        for y in range(8):
            for x in range(8):
                rgb = img.getpixel((x, y))
                # Find closest color in palette
                closest_idx = 0
                min_dist = float('inf')
                for i, pal_rgb in enumerate(palette_rgb[:4]):  # Only 4 colors in 2BPP
                    dist = sum((a - b) ** 2 for a, b in zip(rgb, pal_rgb))
                    if dist < min_dist:
                        min_dist = dist
                        closest_idx = i
                pixels.append(closest_idx)

        # Encode as 2BPP
        data = bytearray(16)
        for row in range(8):
            plane0 = 0
            plane1 = 0
            for col in range(8):
                idx = pixels[row * 8 + col]
                bit = 7 - col  # MSB first
                plane0 |= ((idx & 1) << bit)
                plane1 |= (((idx >> 1) & 1) << bit)

            data[row * 2] = plane0
            data[row * 2 + 1] = plane1

        return bytes(data)

    def image_to_4bpp_tile(self, img: Image.Image,
                           palette: SNESPalette) -> bytes:
        """
        Convert 8x8 PIL Image to 4BPP tile data.

        Args:
            img: 8x8 PIL Image
            palette: Palette to use for color indices

        Returns:
            32 bytes of 4BPP tile data
        """
        if img.size != (8, 8):
            raise ValueError(f"Tile must be 8x8, got {img.size}")

        # Convert image to RGB if needed
        if img.mode != 'RGB':
            img = img.convert('RGB')

        # Build palette lookup (convert RGB555 to RGB888 for comparison)
        palette_rgb = [
            ((c.r << 3) | (c.r >> 2),
             (c.g << 3) | (c.g >> 2),
             (c.b << 3) | (c.b >> 2))
            for c in palette.colors
        ]

        # Extract pixel indices
        pixels = []
        for y in range(8):
            for x in range(8):
                rgb = img.getpixel((x, y))
                # Find closest color in palette
                closest_idx = 0
                min_dist = float('inf')
                for i, pal_rgb in enumerate(palette_rgb[:16]):  # 16 colors in 4BPP
                    dist = sum((a - b) ** 2 for a, b in zip(rgb, pal_rgb))
                    if dist < min_dist:
                        min_dist = dist
                        closest_idx = i
                pixels.append(closest_idx)

        # Encode as 4BPP (planes 0-1, then planes 2-3)
        data = bytearray(32)
        for row in range(8):
            plane0 = 0
            plane1 = 0
            plane2 = 0
            plane3 = 0
            for col in range(8):
                idx = pixels[row * 8 + col]
                bit = 7 - col  # MSB first
                plane0 |= ((idx & 1) << bit)
                plane1 |= (((idx >> 1) & 1) << bit)
                plane2 |= (((idx >> 2) & 1) << bit)
                plane3 |= (((idx >> 3) & 1) << bit)

            data[row * 2] = plane0
            data[row * 2 + 1] = plane1
            data[16 + row * 2] = plane2
            data[16 + row * 2 + 1] = plane3

        return bytes(data)

    def sprite_sheet_to_tiles(self, sheet_path: Path,
                              tiles_per_row: int = 16) -> List[Image.Image]:
        """
        Extract individual 8x8 tiles from sprite sheet.

        Args:
            sheet_path: Path to sprite sheet PNG
            tiles_per_row: Number of tiles per row

        Returns:
            List of 8x8 PIL Images
        """
        sheet = Image.open(sheet_path)
        width, height = sheet.size

        if width % 8 != 0 or height % 8 != 0:
            raise ValueError(f"Sheet size must be multiple of 8, got {width}x{height}")

        tiles = []
        rows = height // 8
        cols = width // 8

        for row in range(rows):
            for col in range(cols):
                x = col * 8
                y = row * 8
                tile = sheet.crop((x, y, x + 8, y + 8))
                tiles.append(tile)

        return tiles

    def compress_4bpp_to_3bpp(self, data_4bpp: bytes) -> bytes:
        """
        Compress 4BPP graphics to 3BPP format.

        Uses ExpandSecondHalfWithZeros algorithm (reverse).

        Args:
            data_4bpp: 4BPP tile data (32 bytes per tile)

        Returns:
            3BPP compressed data (24 bytes per tile)
        """
        if ExpandSecondHalfWithZeros is None:
            raise RuntimeError("ffmq_compression.py not available")

        return ExpandSecondHalfWithZeros.compress(data_4bpp)

    def compress_lz(self, data: bytes) -> bytes:
        """
        Compress data using LZ compression.

        Uses SimpleTailWindowCompression algorithm.

        Args:
            data: Uncompressed data

        Returns:
            LZ compressed data
        """
        if SimpleTailWindowCompression is None:
            raise RuntimeError("ffmq_compression.py not available")

        return SimpleTailWindowCompression.compress(data)

    def validate_tile_data(self, data: bytes, bpp: int) -> bool:
        """
        Validate tile data conforms to SNES constraints.

        Args:
            data: Tile data to validate
            bpp: Bits per pixel (2 or 4)

        Returns:
            True if valid
        """
        bytes_per_tile = 16 if bpp == 2 else 32

        if len(data) % bytes_per_tile != 0:
            print(f"ERROR: Data size {len(data)} not multiple of {bytes_per_tile}")
            return False

        if bpp not in [2, 4]:
            print(f"ERROR: Only 2BPP and 4BPP supported, got {bpp}BPP")
            return False

        return True

    def validate_palette(self, palette: SNESPalette, max_colors: int = 16) -> bool:
        """
        Validate palette conforms to SNES constraints.

        Args:
            palette: Palette to validate
            max_colors: Maximum colors allowed

        Returns:
            True if valid
        """
        if len(palette.colors) > max_colors:
            print(f"ERROR: Palette has {len(palette.colors)} colors, max {max_colors}")
            return False

        for i, color in enumerate(palette.colors):
            if not (0 <= color.r <= 31 and
                    0 <= color.g <= 31 and
                    0 <= color.b <= 31):
                print(f"ERROR: Color {i} out of range (RGB555): {color}")
                return False

        return True


def main():
    """Command-line interface for graphics import."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Import graphics from PNG/JSON to SNES format"
    )
    parser.add_argument('input', help='Input file (PNG sprite sheet or JSON palette)')
    parser.add_argument('output', help='Output file (binary tile/palette data)')
    parser.add_argument('--format', choices=['2bpp', '4bpp', 'palette'],
                       required=True, help='Output format')
    parser.add_argument('--palette', help='Palette JSON file (required for tiles)')
    parser.add_argument('--compress', choices=['3bpp', 'lz'],
                       help='Compression type')
    parser.add_argument('--tiles-per-row', type=int, default=16,
                       help='Tiles per row in sprite sheet (default: 16)')

    args = parser.parse_args()

    importer = GraphicsImporter()

    try:
        if args.format == 'palette':
            # Import palette
            print(f"Importing palette from {args.input}...")
            palette = SNESPalette.from_json(Path(args.input))

            if not importer.validate_palette(palette):
                return 1

            data = palette.to_bytes()
            print(f"[OK] Palette: {len(palette.colors)} colors, {len(data)} bytes")

        else:
            # Import tiles
            if not args.palette:
                print("ERROR: --palette required for tile import")
                return 1

            print(f"Loading palette from {args.palette}...")
            palette = SNESPalette.from_json(Path(args.palette))

            print(f"Importing tiles from {args.input}...")
            tiles = importer.sprite_sheet_to_tiles(Path(args.input), args.tiles_per_row)
            print(f"[OK] Extracted {len(tiles)} tiles from sprite sheet")

            # Convert tiles to binary
            data = bytearray()
            for i, tile in enumerate(tiles):
                if args.format == '2bpp':
                    tile_data = importer.image_to_2bpp_tile(tile, palette)
                elif args.format == '4bpp':
                    tile_data = importer.image_to_4bpp_tile(tile, palette)
                data.extend(tile_data)

            print(f"[OK] Converted {len(tiles)} tiles to {args.format.upper()}")

            # Validate
            bpp = 2 if args.format == '2bpp' else 4
            if not importer.validate_tile_data(bytes(data), bpp):
                return 1

            # Compress if requested
            if args.compress:
                original_size = len(data)
                if args.compress == '3bpp':
                    data = importer.compress_4bpp_to_3bpp(bytes(data))
                elif args.compress == 'lz':
                    data = importer.compress_lz(bytes(data))
                print(f"[OK] Compressed: {original_size} -> {len(data)} bytes "
                      f"({100 * len(data) / original_size:.1f}%)")

        # Write output
        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, 'wb') as f:
            f.write(data)

        print(f"[OK] Saved: {output_path} ({len(data)} bytes)")
        print()
        print("Import successful!")
        return 0

    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())
