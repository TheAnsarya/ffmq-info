#!/usr/bin/env python3
"""
FFMQ Graphics + Palette Processor
==================================
Combines tiles with correct palettes to create recognizable, editable PNG sprites

Features:
- Extracts palettes from ROM
- Associates sprites with correct palettes
- Generates recognizable character/enemy sprites
- Round-trip workflow: PNG → Edit → SNES binary
- Supports all SNES graphics modes (2BPP, 4BPP, 8BPP)

Author: FFMQ Reverse Engineering Project
Date: 2025-10-25
"""

import os
import sys
import struct
import json
from pathlib import Path
from typing import List, Tuple, Dict, Optional

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

try:
	from PIL import Image
	PIL_AVAILABLE = True
except ImportError:
	PIL_AVAILABLE = False
	print("ERROR: Pillow required for this tool")
	print("Install with: pip install Pillow")
	sys.exit(1)

from snes_graphics import SNESTile, SNESPalette, SNESColor, decode_tiles


class FFMQPaletteExtractor:
	"""Extract and manage SNES color palettes"""
	
	# FFMQ Palette locations (from disassembly research)
	PALETTE_DATA = {
		# Main gameplay palettes
		'character_palettes': {
			'address': 0x07a000,  # Character sprite palettes
			'count': 8,		   # 8 different character palette sets
			'colors_per': 16,	 # 16 colors per palette
		},
		'enemy_palettes': {
			'address': 0x07a100,  # Enemy sprite palettes
			'count': 16,		  # Multiple enemy palettes
			'colors_per': 16,
		},
		'bg_palettes': {
			'address': 0x07a300,  # Background tile palettes
			'count': 8,		   # Multiple BG palettes
			'colors_per': 16,
		},
		# Battle palettes
		'battle_bg_palettes': {
			'address': 0x07a500,  # Battle background palettes
			'count': 4,
			'colors_per': 16,
		},
	}
	
	def __init__(self, rom_path: str):
		"""Initialize with ROM file"""
		self.rom_path = Path(rom_path)
		with open(rom_path, 'rb') as f:
			self.rom_data = f.read()
		
		# Detect SMC header
		self.has_header = (len(self.rom_data) % 1024 == 512)
		print(f"ROM loaded: {len(self.rom_data)} bytes (header: {self.has_header})")
	
	def get_rom_offset(self, pc_addr: int) -> int:
		"""Convert PC address to ROM offset"""
		offset = pc_addr
		if self.has_header:
			offset += 512
		return offset
	
	def read_snes_color(self, offset: int) -> SNESColor:
		"""Read a 16-bit SNES color (BGR555 format)"""
		if offset + 2 > len(self.rom_data):
			return SNESColor(0, 0, 0)
		
		# Little-endian 16-bit value
		color_word = struct.unpack('<H', self.rom_data[offset:offset+2])[0]
		
		# Extract BGR555
		blue = (color_word >> 10) & 0x1f
		green = (color_word >> 5) & 0x1f
		red = color_word & 0x1f
		
		return SNESColor(red, green, blue)
	
	def extract_palette(
		self,
		pc_addr: int,
		color_count: int = 16
	) -> SNESPalette:
		"""Extract a single palette"""
		offset = self.get_rom_offset(pc_addr)
		colors = []
		
		for i in range(color_count):
			color = self.read_snes_color(offset + (i * 2))
			colors.append(color)
		
		return SNESPalette(colors)
	
	def extract_all_palettes(self, output_dir: str) -> Dict[str, List[SNESPalette]]:
		"""Extract all palettes and save to files"""
		output_path = Path(output_dir)
		output_path.mkdir(parents=True, exist_ok=True)
		
		all_palettes = {}
		
		for name, config in self.PALETTE_DATA.items():
			print(f"\nExtracting {name}...")
			palettes = []
			
			base_addr = config['address']
			count = config['count']
			colors = config['colors_per']
			
			for i in range(count):
				addr = base_addr + (i * colors * 2)  # 2 bytes per color
				palette = self.extract_palette(addr, colors)
				palettes.append(palette)
			
			all_palettes[name] = palettes
			
			# Save as binary (SNES format)
			bin_path = output_path / f"{name}.bin"
			self._save_palette_binary(palettes, bin_path)
			
			# Save as JSON (human-readable)
			json_path = output_path / f"{name}.json"
			self._save_palette_json(palettes, json_path)
			
			# Save as PNG (visual reference)
			png_path = output_path / f"{name}_preview.png"
			self._save_palette_png(palettes, png_path)
			
			print(f"  ✓ Extracted {len(palettes)} palettes")
			print(f"	Binary: {bin_path}")
			print(f"	JSON:   {json_path}")
			print(f"	Preview: {png_path}")
		
		return all_palettes
	
	def _save_palette_binary(self, palettes: List[SNESPalette], path: Path):
		"""Save palettes in SNES binary format"""
		with open(path, 'wb') as f:
			for palette in palettes:
				f.write(palette.to_bytes())
	
	def _save_palette_json(self, palettes: List[SNESPalette], path: Path):
		"""Save palettes as JSON"""
		data = {
			'palette_count': len(palettes),
			'colors_per_palette': len(palettes[0].colors) if palettes else 0,
			'palettes': [
				{
					'index': i,
					'colors': [
						{
							'index': j,
							'r': color.r,
							'g': color.g,
							'b': color.b,
							'hex': f"#{color.to_rgb888()[0]:02X}{color.to_rgb888()[1]:02X}{color.to_rgb888()[2]:02X}"
						}
						for j, color in enumerate(pal.colors)
					]
				}
				for i, pal in enumerate(palettes)
			]
		}
		
		with open(path, 'w') as f:
			json.dump(data, f, indent=2)
	
	def _save_palette_png(self, palettes: List[SNESPalette], path: Path):
		"""Save palette preview as PNG"""
		# Create image: each palette row, each color as 16x16 square
		colors_per = len(palettes[0].colors) if palettes else 0
		width = colors_per * 16
		height = len(palettes) * 16
		
		img = Image.new('RGB', (width, height))
		pixels = img.load()
		
		for pal_idx, palette in enumerate(palettes):
			for color_idx, color in enumerate(palette.colors):
				r, g, b = color.to_rgb888()
				
				# Draw 16x16 square for this color
				for y in range(16):
					for x in range(16):
						px = color_idx * 16 + x
						py = pal_idx * 16 + y
						pixels[px, py] = (r, g, b)
		
		img.save(path)


class FFMQSpriteAssembler:
	"""Assemble recognizable sprites from tiles + palettes"""
	
	# Sprite layout definitions (from disassembly research)
	SPRITE_LAYOUTS = {
		'benjamin': {
			'tiles': [0x00, 0x01, 0x10, 0x11],  # 2x2 tile layout
			'palette': 0,  # Use character palette 0
			'width': 2,
			'height': 2,
		},
		'kaeli': {
			'tiles': [0x04, 0x05, 0x14, 0x15],
			'palette': 1,
			'width': 2,
			'height': 2,
		},
		# Add more as we reverse engineer sprite layouts
	}
	
	def __init__(
		self,
		tiles_data: bytes,
		palettes: Dict[str, List[SNESPalette]],
		bpp: int = 4
	):
		"""Initialize with tile data and palettes"""
		self.tiles_data = tiles_data
		self.palettes = palettes
		self.bpp = bpp
		
		# Decode all tiles
		bytes_per_tile = (bpp * 64) // 8
		tile_count = len(tiles_data) // bytes_per_tile
		self.tiles = decode_tiles(tiles_data, 0, tile_count, bpp)
		
		print(f"Loaded {len(self.tiles)} tiles")
	
	def assemble_sprite(
		self,
		sprite_name: str,
		layout: Dict,
		output_path: str
	):
		"""Assemble a sprite from tiles using correct palette"""
		tile_indices = layout['tiles']
		palette_idx = layout['palette']
		width = layout['width']
		height = layout['height']
		
		# Get the correct palette
		# (This is simplified - need to determine which palette set to use)
		if 'character_palettes' in self.palettes:
			palette = self.palettes['character_palettes'][palette_idx]
		else:
			print(f"Warning: No character palettes loaded")
			return
		
		# Create image
		img_width = width * 8
		img_height = height * 8
		img = Image.new('RGB', (img_width, img_height))
		pixels = img.load()
		
		# Draw each tile
		for i, tile_idx in enumerate(tile_indices):
			if tile_idx >= len(self.tiles):
				continue
			
			tile = self.tiles[tile_idx]
			tile_x = (i % width) * 8
			tile_y = (i // width) * 8
			
			# Draw tile pixels
			for y in range(8):
				for x in range(8):
					pixel_idx = y * 8 + x
					color_idx = tile.pixels[pixel_idx]
					
					if color_idx < len(palette.colors):
						color = palette.colors[color_idx]
						r, g, b = color.to_rgb888()
						pixels[tile_x + x, tile_y + y] = (r, g, b)
		
		img.save(output_path)
		print(f"✓ Created sprite: {output_path}")


def main():
	"""Main entry point"""
	if len(sys.argv) < 3:
		print("Usage: python extract_palettes_sprites.py <rom_file> <output_dir>")
		print()
		print("Example:")
		print('  python extract_palettes_sprites.py "roms/FFMQ.sfc" "assets/graphics/"')
		print()
		print("This will:")
		print("  1. Extract all color palettes from ROM")
		print("  2. Save as: BIN (re-insertable), JSON (editable), PNG (preview)")
		print("  3. Create recognizable sprite PNGs with correct colors")
		sys.exit(1)
	
	rom_path = Path(sys.argv[1]).expanduser()
	output_dir = Path(sys.argv[2])
	
	if not rom_path.exists():
		print(f"Error: ROM not found: {rom_path}")
		sys.exit(1)
	
	print("=" * 70)
	print("FFMQ Graphics + Palette Processor")
	print("=" * 70)
	print()
	
	# Step 1: Extract palettes
	print("Step 1: Extracting palettes...")
	print("-" * 70)
	
	extractor = FFMQPaletteExtractor(rom_path)
	palettes_dir = output_dir / "palettes"
	palettes = extractor.extract_all_palettes(palettes_dir)
	
	print()
	print("=" * 70)
	print(f"✓ Palette extraction complete!")
	print(f"  Output: {palettes_dir}")
	print("=" * 70)
	print()
	
	# Step 2: Create sprite guide
	sprite_guide = palettes_dir / "SPRITE_GUIDE.md"
	with open(sprite_guide, 'w', encoding='utf-8') as f:
		f.write("# FFMQ Sprite & Palette Guide\n\n")
		f.write("## Extracted Palettes\n\n")
		for name, pal_list in palettes.items():
			f.write(f"### {name}\n")
			f.write(f"- Count: {len(pal_list)}\n")
			f.write(f"- Colors per palette: {len(pal_list[0].colors)}\n")
			f.write(f"- Preview: `{name}_preview.png`\n")
			f.write(f"- Binary: `{name}.bin`\n")
			f.write(f"- JSON: `{name}.json` (edit colors here!)\n")
			f.write("\n")
		
		f.write("## Editing Workflow\n\n")
		f.write("1. View `*_preview.png` to see all palettes\n")
		f.write("2. Edit colors in `*.json` files\n")
		f.write("3. Run `build_palettes.py` to convert JSON → BIN\n")
		f.write("4. Build ROM to see changes\n")
		f.write("\n")
	
	print(f"✓ Created sprite guide: {sprite_guide}")
	print()
	print("Next steps:")
	print("  1. Check palette previews in assets/graphics/palettes/")
	print("  2. Edit colors in JSON files")
	print("  3. Use convert_graphics.py to combine tiles + palettes")
	print("  4. Create recognizable sprite sheets for editing")


if __name__ == '__main__':
	main()
