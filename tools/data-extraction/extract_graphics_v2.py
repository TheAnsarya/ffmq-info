#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest - Graphics Extractor v2
Enhanced graphics extractor with PNG output and comprehensive format support
"""

import os
import sys
import struct
from typing import List, Tuple, Optional, Dict
from snes_graphics import SNESTile, SNESPalette, SNESColor, decode_tiles
from convert_graphics import TileImageConverter

try:
	from PIL import Image
	PIL_AVAILABLE = True
except ImportError:
	PIL_AVAILABLE = False
	print("Warning: PIL not available. PNG conversion disabled.")
	print("Install with: pip install Pillow")


class FFMQGraphicsExtractorV2:
	"""Extract graphics from Final Fantasy Mystic Quest ROM with PNG support"""
	
	def __init__(self, rom_path: str, output_dir: str):
		self.rom_path = rom_path
		self.output_dir = output_dir
		self.rom_data = None
		self.has_header = False
		
		# FFMQ graphics locations (PC addresses from disassembly)
		# Based on analysis of load-graphics-routines.asm
		self.tile_locations = {
			'main_tiles': {
				'pc_addr': 0x028c80,		# $05:8c80 in ROM
				'size': 0x36600,			# $22 * $100 tiles * $30 bytes
				'bpp': 4,
				'description': 'Main background tiles (34 banks)',
			},
			'extra_tiles': {
				'pc_addr': 0x020000,		# $04:8000 in ROM
				'size': 0x1800,				# $100 tiles
				'bpp': 4,
				'description': 'Extra background tiles',
			},
			'sprite_tiles': {
				'pc_addr': 0x03b013,		# $07:b013 in ROM
				'size': 0x10be9,			# Until $07:dbfc
				'bpp': 4,
				'description': 'Sprite graphics data',
			},
		}
		
		# Palette locations (estimates based on typical layout)
		self.palette_locations = {
			'main_palettes': {
				'pc_addr': 0x038000,		# $07:8000 area
				'size': 0x200,				# 256 colors
				'description': 'Main color palettes',
			},
		}
	
	def load_rom(self) -> bool:
		"""Load ROM file into memory and detect header"""
		try:
			with open(self.rom_path, 'rb') as f:
				self.rom_data = f.read()
			
			# Detect SMC header (512 bytes)
			self.has_header = (len(self.rom_data) % 1024 == 512)
			
			print(f"Loaded ROM: {len(self.rom_data)} bytes")
			print(f"Header detected: {self.has_header}")
			return True
		except FileNotFoundError:
			print(f"Error: ROM file not found: {self.rom_path}")
			return False
		except Exception as e:
			print(f"Error loading ROM: {e}")
			return False
	
	def get_rom_address(self, pc_addr: int) -> int:
		"""Get actual ROM offset accounting for header"""
		if self.has_header:
			return pc_addr + 512
		return pc_addr
	
	def extract_tiles_raw(
		self,
		name: str,
		pc_addr: int,
		size: int,
		bpp: int
	) -> Optional[bytes]:
		"""Extract raw tile data from ROM"""
		rom_offset = self.get_rom_address(pc_addr)
		
		if rom_offset + size > len(self.rom_data):
			print(f"Warning: {name} extends beyond ROM")
			size = len(self.rom_data) - rom_offset
		
		if size <= 0:
			print(f"Error: Invalid size for {name}")
			return None
		
		data = self.rom_data[rom_offset:rom_offset + size]
		
		# Save raw data
		os.makedirs(self.output_dir, exist_ok=True)
		raw_path = os.path.join(self.output_dir, f"{name}_raw.bin")
		with open(raw_path, 'wb') as f:
			f.write(data)
		
		bytes_per_tile = (bpp * 64) // 8
		tile_count = size // bytes_per_tile
		
		print(f"Extracted {name}: {tile_count} tiles ({size} bytes) -> {raw_path}")
		return data
	
	def extract_tiles_to_png(
		self,
		name: str,
		pc_addr: int,
		size: int,
		bpp: int,
		palette: Optional[SNESPalette] = None,
		tiles_per_row: int = 16
	) -> bool:
		"""Extract tiles and convert to PNG"""
		if not PIL_AVAILABLE:
			print(f"Skipping PNG conversion for {name} (PIL not available)")
			return False
		
		# Extract raw data
		data = self.extract_tiles_raw(name, pc_addr, size, bpp)
		if not data:
			return False
		
		# Decode tiles
		bytes_per_tile = (bpp * 64) // 8
		tile_count = size // bytes_per_tile
		tiles = decode_tiles(data, 0, tile_count, bpp)
		
		# Use provided palette or generate grayscale
		if not palette:
			colors = []
			max_colors = 2 ** bpp
			for i in range(max_colors):
				intensity = (i * 31) // (max_colors - 1) if max_colors > 1 else 0
				colors.append(SNESColor(intensity, intensity, intensity))
			palette = SNESPalette(colors)
		
		# Convert to image
		img = TileImageConverter.tiles_to_indexed_image(tiles, palette, tiles_per_row)
		
		# Save PNG
		png_path = os.path.join(self.output_dir, f"{name}.png")
		img.save(png_path)
		print(f"Saved PNG: {png_path} ({len(tiles)} tiles)")
		
		return True
	
	def extract_palette(
		self,
		name: str,
		pc_addr: int,
		size: int,
		save_txt: bool = True
	) -> Optional[SNESPalette]:
		"""Extract palette data from ROM"""
		rom_offset = self.get_rom_address(pc_addr)
		
		if rom_offset + size > len(self.rom_data):
			print(f"Warning: {name} palette extends beyond ROM")
			size = len(self.rom_data) - rom_offset
		
		if size <= 0:
			print(f"Error: Invalid size for {name} palette")
			return None
		
		data = self.rom_data[rom_offset:rom_offset + size]
		
		# Parse palette
		palette = SNESPalette.from_bytes(data, count=size // 2)
		
		# Save raw palette
		os.makedirs(self.output_dir, exist_ok=True)
		raw_path = os.path.join(self.output_dir, f"{name}_palette.bin")
		with open(raw_path, 'wb') as f:
			f.write(palette.to_bytes())
		
		print(f"Extracted {name}: {len(palette)} colors -> {raw_path}")
		
		# Save human-readable format
		if save_txt:
			txt_path = os.path.join(self.output_dir, f"{name}_palette.txt")
			with open(txt_path, 'w') as f:
				f.write(f"Palette: {name}\n")
				f.write(f"Size: {len(palette)} colors\n\n")
				
				for i in range(len(palette)):
					color = palette.colors[i]
					r, g, b = color.to_rgb888()
					f.write(f"Color {i:02X}: RGB({r:02X},{g:02X},{b:02X}) ")
					f.write(f"SNES:${color.to_snes():04X}\n")
					
					# Add visual separator every 16 colors (sub-palette)
					if (i + 1) % 16 == 0:
						f.write("\n")
			
			print(f"Saved palette text: {txt_path}")
		
		return palette
	
	def extract_all_graphics(self) -> bool:
		"""Extract all graphics from ROM"""
		if not self.load_rom():
			return False
		
		print("\n" + "=" * 60)
		print("Final Fantasy Mystic Quest - Graphics Extraction")
		print("=" * 60 + "\n")
		
		# Extract palettes first
		print("Extracting palettes...")
		palettes = {}
		for name, info in self.palette_locations.items():
			print(f"\n{name}: {info['description']}")
			pal = self.extract_palette(name, info['pc_addr'], info['size'])
			if pal:
				palettes[name] = pal
		
		# Extract tiles
		print("\n" + "-" * 60)
		print("Extracting tiles...")
		for name, info in self.tile_locations.items():
			print(f"\n{name}: {info['description']}")
			
			# Try to use a palette if available
			palette = palettes.get('main_palettes')
			
			self.extract_tiles_to_png(
				name,
				info['pc_addr'],
				info['size'],
				info['bpp'],
				palette=palette,
				tiles_per_row=16
			)
		
		print("\n" + "=" * 60)
		print(f"Graphics extraction complete!")
		print(f"Output directory: {self.output_dir}")
		print("=" * 60 + "\n")
		
		return True
	
	def generate_documentation(self) -> None:
		"""Generate documentation about extracted graphics"""
		doc_path = os.path.join(self.output_dir, "README.md")
		
		with open(doc_path, 'w') as f:
			f.write("# Final Fantasy Mystic Quest - Extracted Graphics\n\n")
			f.write("This directory contains graphics extracted from the FFMQ ROM.\n\n")
			
			f.write("## Tile Sets\n\n")
			for name, info in self.tile_locations.items():
				f.write(f"### {name}\n")
				f.write(f"- **Description:** {info['description']}\n")
				f.write(f"- **PC Address:** ${info['pc_addr']:06X}\n")
				f.write(f"- **Size:** {info['size']} bytes\n")
				f.write(f"- **Format:** {info['bpp']}BPP\n")
				f.write(f"- **Files:**\n")
				f.write(f"  - `{name}_raw.bin` - Raw SNES tile data\n")
				if PIL_AVAILABLE:
					f.write(f"  - `{name}.png` - PNG preview image\n")
				f.write("\n")
			
			f.write("## Palettes\n\n")
			for name, info in self.palette_locations.items():
				f.write(f"### {name}\n")
				f.write(f"- **Description:** {info['description']}\n")
				f.write(f"- **PC Address:** ${info['pc_addr']:06X}\n")
				f.write(f"- **Size:** {info['size']} bytes\n")
				f.write(f"- **Files:**\n")
				f.write(f"  - `{name}_palette.bin` - Raw SNES palette data\n")
				f.write(f"  - `{name}_palette.txt` - Human-readable color list\n")
				f.write("\n")
			
			f.write("## File Formats\n\n")
			f.write("### SNES Tile Format\n")
			f.write("- **2BPP:** 16 bytes per 8x8 tile (4 colors)\n")
			f.write("- **4BPP:** 32 bytes per 8x8 tile (16 colors)\n")
			f.write("- **8BPP:** 64 bytes per 8x8 tile (256 colors)\n\n")
			
			f.write("### SNES Palette Format\n")
			f.write("- **RGB555:** 2 bytes per color (15-bit color)\n")
			f.write("- **Format:** `0BBBBBGGGGGRRRRR` (5 bits per channel)\n")
			f.write("- **Organization:** 16 colors per sub-palette\n\n")
			
			f.write("## Editing Graphics\n\n")
			f.write("1. Edit the PNG files in your image editor\n")
			f.write("2. Use `convert_graphics.py` to convert back to SNES format:\n")
			f.write("   ```bash\n")
			f.write("   python convert_graphics.py to-snes <input.png> <output.bin> --bpp 4\n")
			f.write("   ```\n")
			f.write("3. Inject the modified data back into the ROM\n\n")
			
			f.write("## Tools\n\n")
			f.write("- `extract_graphics_v2.py` - This extraction script\n")
			f.write("- `convert_graphics.py` - Convert between SNES and PNG\n")
			f.write("- `snes_graphics.py` - Core SNES graphics format library\n\n")
		
		print(f"Generated documentation: {doc_path}")


def main():
	"""Command-line interface"""
	import argparse
	
	parser = argparse.ArgumentParser(
		description='Extract graphics from Final Fantasy Mystic Quest ROM'
	)
	parser.add_argument('rom', help='Path to FFMQ ROM file (.sfc/.smc)')
	parser.add_argument('output', nargs='?', default='assets/graphics',
						help='Output directory (default: assets/graphics)')
	parser.add_argument('--no-png', action='store_true',
						help='Skip PNG conversion (raw data only)')
	parser.add_argument('--docs', action='store_true',
						help='Generate documentation')
	
	args = parser.parse_args()
	
	extractor = FFMQGraphicsExtractorV2(args.rom, args.output)
	
	if args.no_png:
		PIL_AVAILABLE = False
	
	success = extractor.extract_all_graphics()
	
	if success and args.docs:
		extractor.generate_documentation()
	
	sys.exit(0 if success else 1)


if __name__ == '__main__':
	main()
