"""
Extract graphics tiles and palettes from FFMQ ROM.

This tool extracts graphics data from Banks 04 and 05 using the documented
formats from the disassembly. Outputs PNG images and palette files.

Banks:
    - Bank 04 ($048000-$04FFFF): CHR/Graphics tile data (2BPP/4BPP)
    - Bank 05 ($058000-$05FFFF): RGB555 palette data

References:
    - src/asm/bank_04_documented.asm - Graphics tile format documentation
    - src/asm/bank_05_documented.asm - Palette format documentation
    - docs/ROM_PIPELINE_PLAN.md - Extraction pipeline architecture
"""

import os
import sys
import json
import struct
from pathlib import Path
from typing import List, Tuple, Optional
from dataclasses import dataclass, asdict

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
    from PIL import Image
except ImportError:
    print("ERROR: Pillow library required for graphics extraction")
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


# ROM Configuration
ROM_PATH = "roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"
ROM_SIZE = 524288  # 512KB

# Bank addresses (LoROM mapping: file_offset = bank * 0x8000 + (rom_addr - 0x8000))
BANK_04_START = 0x028000  # Graphics tiles
BANK_04_END = 0x02FFFF
BANK_05_START = 0x030000  # Palettes
BANK_05_END = 0x037FFF

# Output directories
OUTPUT_DIR = Path("data/extracted/graphics")
TILES_DIR = OUTPUT_DIR / "tiles"
PALETTES_DIR = OUTPUT_DIR / "palettes"
SPRITES_DIR = OUTPUT_DIR / "sprites"


@dataclass
class RGB555Color:
    """SNES RGB555 color (15-bit BGR format)."""
    r: int  # 0-31 (5-bit)
    g: int  # 0-31 (5-bit)
    b: int  # 0-31 (5-bit)

    @classmethod
    def from_bytes(cls, low: int, high: int) -> 'RGB555Color':
        """
        Parse RGB555 color from 2-byte little-endian format.

        Format: 0bbbbbgg gggrrrrr
        Byte 0 (LOW):  gggrrrrr (bits 0-7)
        Byte 1 (HIGH): 0bbbbbgg (bits 8-15)
        """
        word = (high << 8) | low
        r = (word >> 0) & 0x1F  # Bits 0-4
        g = (word >> 5) & 0x1F  # Bits 5-9
        b = (word >> 10) & 0x1F  # Bits 10-14
        return cls(r, g, b)

    def to_rgb888(self) -> Tuple[int, int, int]:
        """
        Convert RGB555 (5-bit channels) to RGB888 (8-bit channels).

        Formula: RGB888 = (RGB555 << 3) | (RGB555 >> 2)
        This spreads 5-bit value (0-31) across 8 bits (0-255).
        """
        r8 = (self.r << 3) | (self.r >> 2)
        g8 = (self.g << 3) | (self.g >> 2)
        b8 = (self.b << 3) | (self.b >> 2)
        return (r8, g8, b8)


@dataclass
class Palette:
    """SNES palette (16 colors)."""
    colors: List[RGB555Color]
    name: str = ""
    offset: int = 0

    def to_rgb888_list(self) -> List[Tuple[int, int, int]]:
        """Convert all colors to RGB888 format for PIL."""
        return [c.to_rgb888() for c in self.colors]


class GraphicsExtractor:
    """Extract graphics and palettes from FFMQ ROM."""

    def __init__(self, rom_path: str):
        """Initialize with ROM file path."""
        self.rom_path = Path(rom_path)
        if not self.rom_path.exists():
            raise FileNotFoundError(f"ROM not found: {rom_path}")

        with open(self.rom_path, 'rb') as f:
            self.rom_data = f.read()

        if len(self.rom_data) != ROM_SIZE:
            raise ValueError(
                f"Invalid ROM size: {len(self.rom_data)} (expected {ROM_SIZE})")

    def extract_palette(self, offset: int, num_colors: int = 16) -> Palette:
        """
        Extract palette from ROM at given offset.

        Args:
            offset: File offset in ROM (LoROM format)
            num_colors: Number of colors to extract (default 16)

        Returns:
            Palette object with RGB555 colors
        """
        colors = []
        for i in range(num_colors):
            addr = offset + (i * 2)
            if addr + 1 >= len(self.rom_data):
                break
            low = self.rom_data[addr]
            high = self.rom_data[addr + 1]
            colors.append(RGB555Color.from_bytes(low, high))

        return Palette(colors=colors, offset=offset)

    def decode_2bpp_tile(self, data: bytes) -> List[int]:
        """
        Decode 2BPP tile data (4 colors, 16 bytes).

        Format: 2 bitplanes interleaved by row
        - Bytes 0-1: Row 0 (plane0, plane1)
        - Bytes 2-3: Row 1 (plane0, plane1)
        - ... (8 rows total)

        Returns:
            List of 64 pixel values (0-3)
        """
        if len(data) != 16:
            raise ValueError(f"2BPP tile must be 16 bytes, got {len(data)}")

        pixels = []
        for row in range(8):
            plane0 = data[row * 2]
            plane1 = data[row * 2 + 1]

            for col in range(8):
                bit = 7 - col  # MSB first
                bit0 = (plane0 >> bit) & 1
                bit1 = (plane1 >> bit) & 1
                pixel = (bit1 << 1) | bit0
                pixels.append(pixel)

        return pixels

    def decode_4bpp_tile(self, data: bytes) -> List[int]:
        """
        Decode 4BPP tile data (16 colors, 32 bytes).

        Format: 4 bitplanes, planes 0-1 interleaved, then planes 2-3
        - Bytes 0-15: Rows 0-7 planes 0-1 (2 bytes per row)
        - Bytes 16-31: Rows 0-7 planes 2-3 (2 bytes per row)

        Returns:
            List of 64 pixel values (0-15)
        """
        if len(data) != 32:
            raise ValueError(f"4BPP tile must be 32 bytes, got {len(data)}")

        pixels = []
        for row in range(8):
            plane0 = data[row * 2]
            plane1 = data[row * 2 + 1]
            plane2 = data[16 + row * 2]
            plane3 = data[16 + row * 2 + 1]

            for col in range(8):
                bit = 7 - col  # MSB first
                bit0 = (plane0 >> bit) & 1
                bit1 = (plane1 >> bit) & 1
                bit2 = (plane2 >> bit) & 1
                bit3 = (plane3 >> bit) & 1
                pixel = (bit3 << 3) | (bit2 << 2) | (bit1 << 1) | bit0
                pixels.append(pixel)

        return pixels

    def render_tile(self, pixels: List[int], palette: Palette) -> Image.Image:
        """
        Render 8x8 tile with palette to PIL Image.

        Args:
            pixels: List of 64 palette indices
            palette: Palette to use for colors

        Returns:
            8x8 PIL Image in RGB mode
        """
        if len(pixels) != 64:
            raise ValueError(f"Tile must have 64 pixels, got {len(pixels)}")

        img = Image.new('RGB', (8, 8))
        palette_rgb = palette.to_rgb888_list()

        for y in range(8):
            for x in range(8):
                idx = y * 8 + x
                color_idx = pixels[idx]
                if color_idx < len(palette_rgb):
                    img.putpixel((x, y), palette_rgb[color_idx])

        return img

    def extract_tiles_2bpp(self, start_offset: int, count: int,
                           palette: Palette) -> List[Image.Image]:
        """
        Extract multiple 2BPP tiles and render with palette.

        Args:
            start_offset: File offset to start extraction
            count: Number of tiles to extract
            palette: Palette to use for rendering

        Returns:
            List of 8x8 PIL Images
        """
        tiles = []
        for i in range(count):
            offset = start_offset + (i * 16)  # 16 bytes per 2BPP tile
            if offset + 16 > len(self.rom_data):
                break

            tile_data = self.rom_data[offset:offset + 16]
            pixels = self.decode_2bpp_tile(tile_data)
            tile_img = self.render_tile(pixels, palette)
            tiles.append(tile_img)

        return tiles

    def extract_tiles_4bpp(self, start_offset: int, count: int,
                           palette: Palette) -> List[Image.Image]:
        """
        Extract multiple 4BPP tiles and render with palette.

        Args:
            start_offset: File offset to start extraction
            count: Number of tiles to extract
            palette: Palette to use for rendering

        Returns:
            List of 8x8 PIL Images
        """
        tiles = []
        for i in range(count):
            offset = start_offset + (i * 32)  # 32 bytes per 4BPP tile
            if offset + 32 > len(self.rom_data):
                break

            tile_data = self.rom_data[offset:offset + 32]
            pixels = self.decode_4bpp_tile(tile_data)
            tile_img = self.render_tile(pixels, palette)
            tiles.append(tile_img)

        return tiles

    def create_tile_sheet(self, tiles: List[Image.Image],
                          tiles_per_row: int = 16) -> Image.Image:
        """
        Combine multiple 8x8 tiles into a sheet.

        Args:
            tiles: List of 8x8 tile images
            tiles_per_row: Number of tiles per row in sheet

        Returns:
            PIL Image containing all tiles in a grid
        """
        if not tiles:
            return Image.new('RGB', (8, 8))

        num_tiles = len(tiles)
        rows = (num_tiles + tiles_per_row - 1) // tiles_per_row
        sheet_width = tiles_per_row * 8
        sheet_height = rows * 8

        sheet = Image.new('RGB', (sheet_width, sheet_height))

        for i, tile in enumerate(tiles):
            x = (i % tiles_per_row) * 8
            y = (i // tiles_per_row) * 8
            sheet.paste(tile, (x, y))

        return sheet

    def export_palette_json(self, palette: Palette, output_path: Path):
        """Export palette to JSON format."""
        palette_data = {
            "format": "RGB555",
            "num_colors": len(palette.colors),
            "rom_offset": f"0x{palette.offset:06X}",
            "colors_rgb555": [
                {
                    "index": i,
                    "r5": c.r,
                    "g5": c.g,
                    "b5": c.b,
                    "hex": f"#{c.r:02X}{c.g:02X}{c.b:02X}"
                }
                for i, c in enumerate(palette.colors)
            ],
            "colors_rgb888": [
                {
                    "index": i,
                    "r": rgb[0],
                    "g": rgb[1],
                    "b": rgb[2],
                    "hex": f"#{rgb[0]:02X}{rgb[1]:02X}{rgb[2]:02X}"
                }
                for i, rgb in enumerate(palette.to_rgb888_list())
            ]
        }

        with open(output_path, 'w') as f:
            json.dump(palette_data, f, indent=2)

    # =========================================================================
    # COMPRESSION SUPPORT
    # =========================================================================

    def decompress_3bpp_to_4bpp(self, compressed_data: bytes) -> bytes:
        """
        Decompress 3BPP graphics to 4BPP format.

        Uses ExpandSecondHalfWithZeros algorithm from FFMQ.
        Input must be in $18 byte chunks (24 bytes per tile).
        Output is $20 byte chunks (32 bytes per tile).

        Args:
            compressed_data: 3BPP compressed graphics data

        Returns:
            4BPP decompressed graphics data
        """
        if ExpandSecondHalfWithZeros is None:
            raise RuntimeError("ffmq_compression.py not available")

        return ExpandSecondHalfWithZeros.decompress(compressed_data)

    def decompress_lz_data(self, compressed_data: bytes,
                           output_size: int = 0x2000) -> bytes:
        """
        Decompress LZ-compressed data (tilemaps, etc).

        Uses SimpleTailWindowCompression algorithm from FFMQ.

        Args:
            compressed_data: LZ compressed data
            output_size: Expected output size (default 8KB)

        Returns:
            Decompressed data
        """
        if SimpleTailWindowCompression is None:
            raise RuntimeError("ffmq_compression.py not available")

        return SimpleTailWindowCompression.decompress(compressed_data, output_size)

    def extract_compressed_tiles_3bpp(self, start_offset: int, tile_count: int,
                                      palette: Palette) -> List[Image.Image]:
        """
        Extract 3BPP compressed tiles (decompressed to 4BPP).

        Args:
            start_offset: File offset to compressed data
            tile_count: Number of tiles to extract
            palette: Palette to use for rendering

        Returns:
            List of 8x8 PIL Images
        """
        # 3BPP tiles are 24 bytes each
        compressed_size = tile_count * 24
        compressed_data = self.rom_data[start_offset:start_offset + compressed_size]

        # Decompress to 4BPP
        decompressed_data = self.decompress_3bpp_to_4bpp(compressed_data)

        # Extract tiles from decompressed data
        tiles = []
        for i in range(tile_count):
            offset = i * 32  # 32 bytes per 4BPP tile
            if offset + 32 > len(decompressed_data):
                break

            tile_data = decompressed_data[offset:offset + 32]
            pixels = self.decode_4bpp_tile(tile_data)
            tile_img = self.render_tile(pixels, palette)
            tiles.append(tile_img)

        return tiles

    # =========================================================================
    # TILEMAP RENDERING
    # =========================================================================

    @dataclass
    class TilemapEntry:
        """SNES tilemap entry (16-bit word)."""
        tile_id: int      # Bits 0-9: tile index (0-1023)
        palette_id: int   # Bits 10-12: palette select (0-7)
        priority: int     # Bit 13: priority (0=low, 1=high)
        flip_x: bool      # Bit 14: horizontal flip
        flip_y: bool      # Bit 15: vertical flip

        @classmethod
        def from_word(cls, word: int) -> 'GraphicsExtractor.TilemapEntry':
            """Parse tilemap entry from 16-bit word."""
            return cls(
                tile_id=(word & 0x3FF),
                palette_id=(word >> 10) & 0x7,
                priority=(word >> 13) & 0x1,
                flip_x=bool(word & 0x4000),
                flip_y=bool(word & 0x8000)
            )

    def parse_tilemap(self, tilemap_data: bytes) -> List['GraphicsExtractor.TilemapEntry']:
        """
        Parse SNES tilemap data into tilemap entries.

        Args:
            tilemap_data: Raw tilemap data (2 bytes per entry)

        Returns:
            List of TilemapEntry objects
        """
        entries = []
        for i in range(0, len(tilemap_data), 2):
            if i + 1 >= len(tilemap_data):
                break

            word = tilemap_data[i] | (tilemap_data[i + 1] << 8)
            entry = self.TilemapEntry.from_word(word)
            entries.append(entry)

        return entries

    def render_tilemap(self, tilemap_entries: List['GraphicsExtractor.TilemapEntry'],
                       tiles: List[Image.Image], palettes: List[Palette],
                       width_tiles: int, height_tiles: int) -> Image.Image:
        """
        Render a tilemap to an image using SNES attributes.

        Supports:
        - Tile ID selection (which 8x8 tile to use)
        - Palette selection (8 palettes)
        - Horizontal/vertical flipping
        - Priority (not visually rendered, but parsed)

        Args:
            tilemap_entries: List of tilemap entries
            tiles: List of available 8x8 tiles (as pixel data, not images)
            palettes: List of 8 palettes for palette select
            width_tiles: Width of tilemap in tiles
            height_tiles: Height of tilemap in tiles

        Returns:
            PIL Image of rendered tilemap
        """
        if not tilemap_entries:
            return Image.new('RGB', (8, 8))

        # Create output image
        width_px = width_tiles * 8
        height_px = height_tiles * 8
        output = Image.new('RGB', (width_px, height_px))

        # Render each tile
        for i, entry in enumerate(tilemap_entries):
            if i >= width_tiles * height_tiles:
                break

            tile_x = (i % width_tiles) * 8
            tile_y = (i // width_tiles) * 8

            # Get tile (bounds check)
            if entry.tile_id >= len(tiles):
                continue

            tile_img = tiles[entry.tile_id].copy()

            # Apply flips
            if entry.flip_x:
                tile_img = tile_img.transpose(Image.FLIP_LEFT_RIGHT)
            if entry.flip_y:
                tile_img = tile_img.transpose(Image.FLIP_TOP_BOTTOM)

            # Paste tile
            output.paste(tile_img, (tile_x, tile_y))

        return output

    def render_tilemap_from_rom(self, tilemap_offset: int,
                                tiles_offset: int, tile_count: int,
                                palette_offset: int, palette_count: int,
                                width_tiles: int, height_tiles: int,
                                compressed: bool = False) -> Image.Image:
        """
        High-level tilemap rendering from ROM offsets.

        Args:
            tilemap_offset: Offset to tilemap data in ROM
            tiles_offset: Offset to tile graphics in ROM
            tile_count: Number of tiles to load
            palette_offset: Offset to palette data in ROM
            palette_count: Number of palettes to load
            width_tiles: Width of tilemap in tiles
            height_tiles: Height of tilemap in tiles
            compressed: Whether tilemap data is LZ compressed

        Returns:
            PIL Image of rendered tilemap
        """
        # Load tilemap data
        tilemap_size = width_tiles * height_tiles * 2  # 2 bytes per entry
        tilemap_data = self.rom_data[tilemap_offset:tilemap_offset + tilemap_size * 2]

        if compressed:
            tilemap_data = self.decompress_lz_data(tilemap_data, tilemap_size)

        tilemap_entries = self.parse_tilemap(tilemap_data)

        # Load palettes (up to 8)
        palettes = []
        for i in range(min(palette_count, 8)):
            offset = palette_offset + (i * 32)
            palette = self.extract_palette(offset, 16)
            palettes.append(palette)

        # Pad to 8 palettes if needed
        while len(palettes) < 8:
            palettes.append(palettes[0] if palettes else self.extract_palette(palette_offset, 16))

        # Load tiles (4BPP)
        tiles = self.extract_tiles_4bpp(tiles_offset, tile_count, palettes[0])

        # Render tilemap
        return self.render_tilemap(tilemap_entries, tiles, palettes,
                                   width_tiles, height_tiles)


def main():
    """Main extraction routine."""
    print("=" * 70)
    print("FFMQ Graphics Extraction Tool")
    print("=" * 70)
    print()

    # Create output directories
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    TILES_DIR.mkdir(exist_ok=True)
    PALETTES_DIR.mkdir(exist_ok=True)
    SPRITES_DIR.mkdir(exist_ok=True)

    # Initialize extractor
    print(f"Loading ROM: {ROM_PATH}")
    try:
        extractor = GraphicsExtractor(ROM_PATH)
        print(f"[OK] ROM loaded: {len(extractor.rom_data):,} bytes")
    except Exception as e:
        print(f"[ERROR] Error loading ROM: {e}")
        return 1

    print()
    print("Extracting Palettes (Bank 05)...")
    print("-" * 70)

    # Extract first 16 palettes (example)
    palettes = []
    for i in range(16):
        offset = BANK_05_START + (i * 32)  # 32 bytes per palette (16 colors)
        palette = extractor.extract_palette(offset, 16)
        palette.name = f"palette_{i:02d}"
        palettes.append(palette)

        # Export palette JSON
        json_path = PALETTES_DIR / f"{palette.name}.json"
        extractor.export_palette_json(palette, json_path)
        print(f"[OK] Palette {i:2d}: {len(palette.colors)} colors -> {json_path.name}")

    print()
    print("Extracting Graphics Tiles (Bank 04)...")
    print("-" * 70)

    # Extract sample tile sets with first palette
    default_palette = palettes[0]

    # Example: Extract first 256 tiles as 4BPP
    print("Extracting 4BPP tiles (0x028000+)...")
    tiles_4bpp = extractor.extract_tiles_4bpp(BANK_04_START, 256, default_palette)
    print(f"[OK] Extracted {len(tiles_4bpp)} 4BPP tiles")

    # Create tile sheet
    tile_sheet = extractor.create_tile_sheet(tiles_4bpp, tiles_per_row=16)
    sheet_path = TILES_DIR / "bank04_tiles_4bpp_sheet.png"
    tile_sheet.save(sheet_path)
    print(f"[OK] Saved tile sheet: {sheet_path} ({tile_sheet.size[0]}x{tile_sheet.size[1]})")

    # Save individual tiles
    for i, tile in enumerate(tiles_4bpp[:64]):  # Save first 64 tiles as examples
        tile_path = TILES_DIR / f"tile_4bpp_{i:04d}.png"
        tile.save(tile_path)

    print(f"[OK] Saved {min(64, len(tiles_4bpp))} individual tiles")

    print()
    print("=" * 70)
    print("Extraction Complete!")
    print("=" * 70)
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"  - Palettes: {PALETTES_DIR}")
    print(f"  - Tiles: {TILES_DIR}")
    print(f"  - Sprites: {SPRITES_DIR}")
    print()
    print("Next steps:")
    print("  - Review extracted palettes in JSON format")
    print("  - Examine tile sheets to identify sprite boundaries")
    print("  - Use different palettes to render different sprite sets")
    print("  - Document tile ranges for specific graphics (enemies, UI, etc.)")

    return 0


if __name__ == '__main__':
    sys.exit(main())
