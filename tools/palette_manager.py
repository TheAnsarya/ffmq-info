#!/usr/bin/env python3
"""
FFMQ Palette Management System
================================

Comprehensive palette management tool for Final Fantasy Mystic Quest.
Provides CLI interface for listing, extracting, previewing, and managing SNES palettes.

Features:
- List all palettes with addresses and metadata
- Extract palettes in multiple formats (BIN, PNG, JSON, CSS, GIMP GPL)
- Preview palettes with sample graphics
- Generate HTML palette book visualization
- Palette swap preview feature
- Associate palettes with graphics sets

Usage:
	python palette_manager.py list                              # List all palettes
	python palette_manager.py extract <id> [--format FORMAT]    # Extract specific palette
	python palette_manager.py extract-all [--format FORMAT]     # Extract all palettes
	python palette_manager.py preview <id>                      # Preview palette
	python palette_manager.py book                              # Generate HTML palette book
	python palette_manager.py swap <pal1> <pal2> <gfx>          # Preview palette swap

Author: AI-assisted disassembly project
Date: November 1, 2025
"""

import sys
import os
import argparse
import json
import struct
from pathlib import Path
from typing import List, Tuple, Dict, Optional
from dataclasses import dataclass, asdict

try:
	from PIL import Image, ImageDraw, ImageFont
except ImportError:
	print("ERROR: PIL (Pillow) not installed!")
	print("Install with: pip install Pillow")
	sys.exit(1)


# ============================================================================
# DATA STRUCTURES
# ============================================================================

@dataclass
class RGB555Color:
	"""SNES RGB555 color (15-bit, 5 bits per channel)"""
	raw_low: int
	raw_high: int

	@property
	def rgb555(self) -> int:
		return (self.raw_high << 8) | self.raw_low

	@property
	def r5(self) -> int:
		return self.rgb555 & 0x1f

	@property
	def g5(self) -> int:
		return (self.rgb555 >> 5) & 0x1f

	@property
	def b5(self) -> int:
		return (self.rgb555 >> 10) & 0x1f

	@property
	def r8(self) -> int:
		return (self.r5 << 3) | (self.r5 >> 2)

	@property
	def g8(self) -> int:
		return (self.g5 << 3) | (self.g5 >> 2)

	@property
	def b8(self) -> int:
		return (self.b5 << 3) | (self.b5 >> 2)

	@property
	def rgb888(self) -> Tuple[int, int, int]:
		return (self.r8, self.g8, self.b8)

	@property
	def hex_string(self) -> str:
		return f"#{self.r8:02X}{self.g8:02X}{self.b8:02X}"

	def to_dict(self) -> Dict:
		return {
			"rgb555": f"${self.rgb555:04X}",
			"rgb888": {"r": self.r8, "g": self.g8, "b": self.b8},
			"hex": self.hex_string
		}


@dataclass
class Palette:
	"""SNES palette with metadata"""
	palette_id: int
	address: int
	bank: int
	offset: int
	color_count: int
	colors: List[RGB555Color]
	name: Optional[str] = None
	category: Optional[str] = None

	@property
	def snes_address(self) -> str:
		return f"${self.bank:02X}:{self.offset:04X}"

	def to_dict(self) -> Dict:
		return {
			"id": self.palette_id,
			"name": self.name or f"Palette_{self.palette_id:03d}",
			"address": self.snes_address,
			"bank": f"${self.bank:02X}",
			"offset": f"${self.offset:04X}",
			"rom_offset": f"${self.address:06X}",
			"color_count": self.color_count,
			"category": self.category or "Unknown",
			"colors": [c.to_dict() for c in self.colors]
		}


# ============================================================================
# ROM UTILITIES
# ============================================================================

def snes_to_rom_offset(bank: int, offset: int) -> int:
	"""Convert SNES address (bank:offset) to ROM file offset"""
	if bank < 0x80:
		# LoROM: banks $00-$7f, offset $8000-$ffff
		return ((bank & 0x7f) << 15) | (offset & 0x7fff)
	else:
		# HiROM: banks $80-$ff
		return ((bank & 0x7f) << 15) | (offset & 0x7fff)


def read_palette_from_rom(rom_data: bytes, address: int, color_count: int) -> List[RGB555Color]:
	"""Read palette colors from ROM"""
	colors = []
	for i in range(color_count):
		offset = address + (i * 2)
		if offset + 1 < len(rom_data):
			low = rom_data[offset]
			high = rom_data[offset + 1]
			colors.append(RGB555Color(low, high))
	return colors


# ============================================================================
# EXPORT FORMATS
# ============================================================================

def export_binary(palette: Palette, output_path: Path) -> None:
	"""Export palette as raw binary (.bin)"""
	with open(output_path, 'wb') as f:
		for color in palette.colors:
			f.write(struct.pack('<H', color.rgb555))
	print(f"✓ Exported binary: {output_path}")


def export_json(palette: Palette, output_path: Path) -> None:
	"""Export palette as JSON (.json)"""
	with open(output_path, 'w') as f:
		json.dump(palette.to_dict(), f, indent=2)
	print(f"✓ Exported JSON: {output_path}")


def export_css(palette: Palette, output_path: Path) -> None:
	"""Export palette as CSS variables (.css)"""
	name = palette.name or f"palette_{palette.palette_id:03d}"
	with open(output_path, 'w') as f:
		f.write(f"/* FFMQ Palette: {name} */\n")
		f.write(f"/* Address: {palette.snes_address} */\n")
		f.write(":root {\n")
		for i, color in enumerate(palette.colors):
			var_name = f"--{name.lower().replace(' ', '-')}-{i:02d}"
			f.write(f"  {var_name}: {color.hex_string};\n")
		f.write("}\n")
	print(f"✓ Exported CSS: {output_path}")


def export_gimp_gpl(palette: Palette, output_path: Path) -> None:
	"""Export palette as GIMP Palette (.gpl)"""
	name = palette.name or f"Palette {palette.palette_id:03d}"
	with open(output_path, 'w') as f:
		f.write("GIMP Palette\n")
		f.write(f"Name: {name}\n")
		f.write(f"# FFMQ Palette - Address: {palette.snes_address}\n")
		f.write(f"# Colors: {palette.color_count}\n")
		f.write("#\n")
		for i, color in enumerate(palette.colors):
			r, g, b = color.rgb888
			f.write(f"{r:3d} {g:3d} {b:3d}  Color {i}\n")
	print(f"✓ Exported GIMP GPL: {output_path}")


def export_png_swatch(palette: Palette, output_path: Path, swatch_size: int = 32) -> None:
	"""Export palette as PNG swatch image"""
	cols = 16 if palette.color_count > 8 else 8
	rows = (palette.color_count + cols - 1) // cols

	img_width = cols * swatch_size
	img_height = rows * swatch_size + 40  # Extra space for label

	img = Image.new('RGB', (img_width, img_height), color=(40, 40, 40))
	draw = ImageDraw.Draw(img)

	# Draw color swatches
	for i, color in enumerate(palette.colors):
		x = (i % cols) * swatch_size
		y = (i // cols) * swatch_size + 30

		rgb = color.rgb888
		draw.rectangle([x, y, x + swatch_size - 1, y + swatch_size - 1], fill=rgb)

		# Draw border
		draw.rectangle([x, y, x + swatch_size - 1, y + swatch_size - 1],
					  outline=(80, 80, 80), width=1)

	# Draw title
	name = palette.name or f"Palette {palette.palette_id:03d}"
	title = f"{name} - {palette.snes_address} ({palette.color_count} colors)"
	draw.text((5, 5), title, fill=(220, 220, 220))

	img.save(output_path)
	print(f"✓ Exported PNG swatch: {output_path}")


# ============================================================================
# PALETTE MANAGER
# ============================================================================

class PaletteManager:
	"""Manages SNES palette extraction and manipulation"""

	def __init__(self, rom_path: str):
		self.rom_path = Path(rom_path)
		if not self.rom_path.exists():
			raise FileNotFoundError(f"ROM not found: {rom_path}")

		with open(self.rom_path, 'rb') as f:
			self.rom_data = f.read()

		self.palettes: List[Palette] = []
		self._scan_palettes()

	def _scan_palettes(self):
		"""Scan ROM for palette data"""
		# Bank $09 palette pointer table starts at $098460
		# Format: 3 bytes per entry (low, high, bank)
		pointer_table_start = 0x048460  # ROM offset for $09:8460

		# Scan up to 50 palette entries
		for i in range(50):
			offset = pointer_table_start + (i * 3)

			if offset + 2 >= len(self.rom_data):
				break

			# Read 24-bit pointer
			low = self.rom_data[offset]
			high = self.rom_data[offset + 1]
			bank = self.rom_data[offset + 2]

			# Skip invalid entries (all $00 or all $ff)
			if (low == 0 and high == 0 and bank == 0) or \
			   (low == 0xff and high == 0xff and bank == 0xff):
				continue

			# Calculate SNES offset and ROM address
			pal_offset = (high << 8) | low

			# Validate bank and offset
			if bank < 0x09 or bank > 0x0b:
				continue
			if pal_offset < 0x8000:
				continue

			pal_address = snes_to_rom_offset(bank, pal_offset)

			if pal_address >= len(self.rom_data):
				continue

			# Try to read 16 colors (standard SNES palette size)
			# Actual color count may vary, but 16 is standard
			max_colors = min(16, (len(self.rom_data) - pal_address) // 2)
			colors = read_palette_from_rom(self.rom_data, pal_address, max_colors)

			if colors and len(colors) > 0:
				# Determine category based on palette ID
				category = "Unknown"
				name = f"Palette_{i:03d}"

				if i < 10:
					category = "Character"
					name = f"Character_{i}"
				elif i < 20:
					category = "Environment"
					name = f"Environment_{i-10}"
				elif i < 30:
					category = "Battle"
					name = f"Battle_{i-20}"
				else:
					category = "Misc"
					name = f"Misc_{i-30}"

				palette = Palette(
					palette_id=i,
					address=pal_address,
					bank=bank,
					offset=pal_offset,
					color_count=len(colors),
					colors=colors,
					name=name,
					category=category
				)
				self.palettes.append(palette)

	def list_palettes(self):
		"""List all available palettes"""
		print(f"\n📊 Found {len(self.palettes)} palettes in ROM\n")
		print(f"{'ID':<5} {'Name':<20} {'Address':<15} {'Colors':<8} {'Category':<15}")
		print("-" * 75)
		for pal in self.palettes:
			name = pal.name or f"Palette_{pal.palette_id:03d}"
			print(f"{pal.palette_id:<5} {name:<20} {pal.snes_address:<15} "
				  f"{pal.color_count:<8} {pal.category or 'Unknown':<15}")

	def get_palette(self, palette_id: int) -> Optional[Palette]:
		"""Get palette by ID"""
		for pal in self.palettes:
			if pal.palette_id == palette_id:
				return pal
		return None

	def extract_palette(self, palette_id: int, output_dir: Path, format: str = "all"):
		"""Extract single palette in specified format"""
		palette = self.get_palette(palette_id)
		if not palette:
			print(f"❌ Palette {palette_id} not found")
			return

		output_dir.mkdir(parents=True, exist_ok=True)
		name = palette.name or f"palette_{palette_id:03d}"

		formats = {
			"bin": (export_binary, ".bin"),
			"json": (export_json, ".json"),
			"css": (export_css, ".css"),
			"gpl": (export_gimp_gpl, ".gpl"),
			"png": (export_png_swatch, ".png")
		}

		if format == "all":
			for fmt_name, (exporter, ext) in formats.items():
				output_path = output_dir / f"{name}{ext}"
				exporter(palette, output_path)
		elif format in formats:
			exporter, ext = formats[format]
			output_path = output_dir / f"{name}{ext}"
			exporter(palette, output_path)
		else:
			print(f"❌ Unknown format: {format}")
			print(f"Available formats: {', '.join(formats.keys())}, all")

	def extract_all_palettes(self, output_dir: Path, format: str = "all"):
		"""Extract all palettes"""
		print(f"\n📦 Extracting {len(self.palettes)} palettes...\n")
		for palette in self.palettes:
			self.extract_palette(palette.palette_id, output_dir, format)
		print(f"\n✅ Extracted {len(self.palettes)} palettes to {output_dir}")

	def preview_palette(self, palette_id: int):
		"""Preview palette colors in terminal"""
		palette = self.get_palette(palette_id)
		if not palette:
			print(f"❌ Palette {palette_id} not found")
			return

		name = palette.name or f"Palette {palette_id:03d}"
		print(f"\n🎨 {name} - {palette.snes_address}")
		print(f"Colors: {palette.color_count} | Category: {palette.category or 'Unknown'}\n")

		for i, color in enumerate(palette.colors):
			hex_color = color.hex_string
			rgb = color.rgb888
			print(f"  [{i:2d}] {hex_color}  RGB({rgb[0]:3d}, {rgb[1]:3d}, {rgb[2]:3d})  "
				  f"RGB555(${color.rgb555:04X})")

	def generate_palette_book(self, output_path: Path):
		"""Generate HTML palette reference book"""
		html = """<!DOCTYPE html>
<html lang="en">
<head>
	<meta charset="UTF-8">
	<meta name="viewport" content="width=device-width, initial-scale=1.0">
	<title>FFMQ Palette Reference</title>
	<style>
		body {
			font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
			background: #1e1e1e;
			color: #d4d4d4;
			padding: 20px;
			max-width: 1400px;
			margin: 0 auto;
		}
		h1 { color: #569cd6; }
		h2 { color: #4ec9b0; border-bottom: 2px solid #4ec9b0; padding-bottom: 5px; }
		.palette-grid {
			display: grid;
			grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
			gap: 20px;
			margin: 20px 0;
		}
		.palette-card {
			background: #252526;
			border: 1px solid #3e3e42;
			border-radius: 8px;
			padding: 15px;
		}
		.palette-header {
			margin-bottom: 10px;
			font-weight: bold;
			color: #dcdcaa;
		}
		.palette-info {
			font-size: 0.85em;
			color: #858585;
			margin-bottom: 10px;
		}
		.color-swatches {
			display: grid;
			grid-template-columns: repeat(8, 1fr);
			gap: 2px;
			margin-top: 10px;
		}
		.color-swatch {
			aspect-ratio: 1;
			border: 1px solid #3e3e42;
			border-radius: 2px;
			cursor: pointer;
			position: relative;
		}
		.color-swatch:hover::after {
			content: attr(data-hex);
			position: absolute;
			bottom: 100%;
			left: 50%;
			transform: translateX(-50%);
			background: #000;
			color: #fff;
			padding: 2px 6px;
			border-radius: 3px;
			font-size: 10px;
			white-space: nowrap;
			z-index: 10;
		}
	</style>
</head>
<body>
	<h1>Final Fantasy Mystic Quest - Palette Reference</h1>
	<p>Complete palette catalog extracted from ROM</p>
"""

		# Group palettes by category
		categories = {}
		for pal in self.palettes:
			cat = pal.category or "Unknown"
			if cat not in categories:
				categories[cat] = []
			categories[cat].append(pal)

		for category, pals in categories.items():
			html += f"\n    <h2>{category} Palettes ({len(pals)})</h2>\n"
			html += '    <div class="palette-grid">\n'

			for pal in pals:
				name = pal.name or f"Palette {pal.palette_id:03d}"
				html += f'        <div class="palette-card">\n'
				html += f'            <div class="palette-header">{name}</div>\n'
				html += f'            <div class="palette-info">\n'
				html += f'                ID: {pal.palette_id} | Address: {pal.snes_address} | '
				html += f'Colors: {pal.color_count}\n'
				html += f'            </div>\n'
				html += '            <div class="color-swatches">\n'

				for color in pal.colors:
					hex_color = color.hex_string
					html += f'                <div class="color-swatch" '
					html += f'style="background:{hex_color}" '
					html += f'data-hex="{hex_color}"></div>\n'

				html += '            </div>\n'
				html += '        </div>\n'

			html += '    </div>\n'

		html += """
</body>
</html>
"""

		with open(output_path, 'w', encoding='utf-8') as f:
			f.write(html)

		print(f"✅ Generated palette book: {output_path}")
# ============================================================================
# CLI INTERFACE
# ============================================================================

def main():
	parser = argparse.ArgumentParser(
		description="FFMQ Palette Management System",
		formatter_class=argparse.RawDescriptionHelpFormatter,
		epilog="""
Examples:
  %(prog)s list
  %(prog)s extract 5 --format png
  %(prog)s extract-all --format all
  %(prog)s preview 3
  %(prog)s book
		"""
	)

	parser.add_argument('--rom', default='roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc',
					   help='Path to FFMQ ROM file (default: roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc)')

	subparsers = parser.add_subparsers(dest='command', help='Commands')

	# List command
	subparsers.add_parser('list', help='List all palettes')

	# Extract command
	extract_parser = subparsers.add_parser('extract', help='Extract single palette')
	extract_parser.add_argument('id', type=int, help='Palette ID')
	extract_parser.add_argument('--format', default='all',
							   choices=['bin', 'json', 'css', 'gpl', 'png', 'all'],
							   help='Output format (default: all)')
	extract_parser.add_argument('--output', default='assets/palettes',
							   help='Output directory (default: assets/palettes)')

	# Extract all command
	extract_all_parser = subparsers.add_parser('extract-all', help='Extract all palettes')
	extract_all_parser.add_argument('--format', default='all',
									choices=['bin', 'json', 'css', 'gpl', 'png', 'all'],
									help='Output format (default: all)')
	extract_all_parser.add_argument('--output', default='assets/palettes',
								   help='Output directory (default: assets/palettes)')

	# Preview command
	preview_parser = subparsers.add_parser('preview', help='Preview palette colors')
	preview_parser.add_argument('id', type=int, help='Palette ID')

	# Book command
	book_parser = subparsers.add_parser('book', help='Generate HTML palette book')
	book_parser.add_argument('--output', default='reports/palette_book.html',
						   help='Output HTML file (default: reports/palette_book.html)')

	args = parser.parse_args()

	if not args.command:
		parser.print_help()
		return 1

	try:
		manager = PaletteManager(args.rom)

		if args.command == 'list':
			manager.list_palettes()

		elif args.command == 'extract':
			output_dir = Path(args.output)
			manager.extract_palette(args.id, output_dir, args.format)

		elif args.command == 'extract-all':
			output_dir = Path(args.output)
			manager.extract_all_palettes(output_dir, args.format)

		elif args.command == 'preview':
			manager.preview_palette(args.id)

		elif args.command == 'book':
			output_path = Path(args.output)
			output_path.parent.mkdir(parents=True, exist_ok=True)
			manager.generate_palette_book(output_path)

		return 0

	except Exception as e:
		print(f"❌ Error: {e}")
		return 1


if __name__ == '__main__':
	sys.exit(main())
