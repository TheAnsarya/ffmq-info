#!/usr/bin/env python3
"""
SNES Palette Extractor - Extract and convert SNES palettes to modern formats

SNES Palette Format (BGR555):
- 2 bytes per color
- 5 bits each for Blue, Green, Red (15-bit color)
- Format: 0BBBBBGG GGGRRRRR
- Total colors: 32,768 possible

Palette Formats:
- Raw binary (.pal)
- Adobe Color Table (.act)
- GIMP Palette (.gpl)
- Paint Shop Pro (.pal)
- JSON with RGB/hex values
- PNG palette strip
- HTML/CSS color swatches

Features:
- Extract palettes from ROM
- Convert BGR555 to RGB888
- Multiple export formats
- Batch extraction
- Palette analysis (color count, duplicates, etc.)
- Palette generation (grayscale, gradients)

Usage:
	python snes_palette_extractor.py rom.sfc --offset 0x80200 --colors 16 --output palette.gpl
	python snes_palette_extractor.py rom.sfc --extract-all --output palettes/
	python snes_palette_extractor.py rom.sfc --offset 0x80200 --preview
	python snes_palette_extractor.py rom.sfc --analyze --offset 0x80200
"""

import argparse
import json
import struct
from pathlib import Path
from typing import List, Tuple, Optional, Dict
from dataclasses import dataclass
from enum import Enum

try:
	from PIL import Image
	PIL_AVAILABLE = True
except ImportError:
	PIL_AVAILABLE = False


class PaletteFormat(Enum):
	"""Output palette format"""
	GIMP = "gpl"       # GIMP Palette
	ACT = "act"        # Adobe Color Table
	PAL = "pal"        # Raw palette
	JSON = "json"      # JSON format
	PNG = "png"        # PNG palette strip
	HTML = "html"      # HTML color swatches
	CSS = "css"        # CSS stylesheet


@dataclass
class SNESColor:
	"""Single SNES color"""
	r: int  # 0-255
	g: int  # 0-255
	b: int  # 0-255
	
	@staticmethod
	def from_bgr555(word: int) -> 'SNESColor':
		"""Convert BGR555 word to RGB color"""
		b = (word & 0x7C00) >> 10
		g = (word & 0x03E0) >> 5
		r = (word & 0x001F)
		
		# Convert 5-bit to 8-bit (0-31 -> 0-255)
		r = (r * 255) // 31
		g = (g * 255) // 31
		b = (b * 255) // 31
		
		return SNESColor(r, g, b)
	
	def to_hex(self) -> str:
		"""Convert to hex string (#RRGGBB)"""
		return f"#{self.r:02X}{self.g:02X}{self.b:02X}"
	
	def to_tuple(self) -> Tuple[int, int, int]:
		"""Convert to RGB tuple"""
		return (self.r, self.g, self.b)


@dataclass
class SNESPalette:
	"""SNES color palette"""
	colors: List[SNESColor]
	name: str = "palette"
	
	def __len__(self) -> int:
		return len(self.colors)
	
	@staticmethod
	def from_rom(data: bytes, offset: int, num_colors: int = 16, name: str = "palette") -> 'SNESPalette':
		"""Extract palette from ROM"""
		colors = []
		
		for i in range(num_colors):
			pos = offset + (i * 2)
			
			if pos + 1 >= len(data):
				# Fill with magenta for missing colors
				colors.append(SNESColor(255, 0, 255))
				continue
			
			color_word = struct.unpack_from('<H', data, pos)[0]
			colors.append(SNESColor.from_bgr555(color_word))
		
		return SNESPalette(colors=colors, name=name)
	
	@staticmethod
	def create_grayscale(num_colors: int = 16, name: str = "grayscale") -> 'SNESPalette':
		"""Create grayscale palette"""
		colors = []
		step = 255 // (num_colors - 1) if num_colors > 1 else 255
		
		for i in range(num_colors):
			gray = min(255, i * step)
			colors.append(SNESColor(gray, gray, gray))
		
		return SNESPalette(colors=colors, name=name)
	
	@staticmethod
	def create_gradient(color1: Tuple[int, int, int], color2: Tuple[int, int, int],
						num_colors: int = 16, name: str = "gradient") -> 'SNESPalette':
		"""Create gradient palette between two colors"""
		colors = []
		
		for i in range(num_colors):
			t = i / (num_colors - 1) if num_colors > 1 else 0
			
			r = int(color1[0] + (color2[0] - color1[0]) * t)
			g = int(color1[1] + (color2[1] - color1[1]) * t)
			b = int(color1[2] + (color2[2] - color1[2]) * t)
			
			colors.append(SNESColor(r, g, b))
		
		return SNESPalette(colors=colors, name=name)
	
	def analyze(self) -> Dict:
		"""Analyze palette"""
		unique_colors = len(set(c.to_tuple() for c in self.colors))
		
		# Find brightest/darkest
		brightnesses = [(c.r + c.g + c.b) // 3 for c in self.colors]
		brightest_idx = brightnesses.index(max(brightnesses))
		darkest_idx = brightnesses.index(min(brightnesses))
		
		# Check for duplicates
		color_counts = {}
		for c in self.colors:
			key = c.to_tuple()
			color_counts[key] = color_counts.get(key, 0) + 1
		
		duplicates = {k: v for k, v in color_counts.items() if v > 1}
		
		return {
			'total_colors': len(self.colors),
			'unique_colors': unique_colors,
			'has_duplicates': len(duplicates) > 0,
			'duplicate_colors': list(duplicates.keys()),
			'brightest_index': brightest_idx,
			'darkest_index': darkest_idx,
			'average_brightness': sum(brightnesses) // len(brightnesses),
		}


class SNESPaletteExporter:
	"""Export palettes to various formats"""
	
	@staticmethod
	def export_gimp(palette: SNESPalette, output_path: Path) -> None:
		"""Export GIMP palette (.gpl)"""
		with open(output_path, 'w') as f:
			f.write("GIMP Palette\n")
			f.write(f"Name: {palette.name}\n")
			f.write(f"Columns: 16\n")
			f.write("#\n")
			
			for i, color in enumerate(palette.colors):
				f.write(f"{color.r:3d} {color.g:3d} {color.b:3d}  Color {i}\n")
	
	@staticmethod
	def export_act(palette: SNESPalette, output_path: Path) -> None:
		"""Export Adobe Color Table (.act)"""
		# ACT format: 256 RGB triplets (768 bytes)
		with open(output_path, 'wb') as f:
			for color in palette.colors:
				f.write(bytes([color.r, color.g, color.b]))
			
			# Pad to 256 colors
			for _ in range(256 - len(palette)):
				f.write(bytes([0, 0, 0]))
	
	@staticmethod
	def export_raw(palette: SNESPalette, output_path: Path) -> None:
		"""Export raw RGB palette (.pal)"""
		with open(output_path, 'wb') as f:
			for color in palette.colors:
				f.write(bytes([color.r, color.g, color.b]))
	
	@staticmethod
	def export_json(palette: SNESPalette, output_path: Path) -> None:
		"""Export JSON palette"""
		data = {
			'name': palette.name,
			'color_count': len(palette),
			'colors': [
				{
					'index': i,
					'r': c.r,
					'g': c.g,
					'b': c.b,
					'hex': c.to_hex(),
				}
				for i, c in enumerate(palette.colors)
			]
		}
		
		with open(output_path, 'w') as f:
			json.dump(data, f, indent='\t')
	
	@staticmethod
	def export_png(palette: SNESPalette, output_path: Path, scale: int = 32) -> None:
		"""Export palette as PNG strip"""
		if not PIL_AVAILABLE:
			raise RuntimeError("PIL/Pillow required for PNG export")
		
		num_colors = len(palette)
		img = Image.new('RGB', (num_colors * scale, scale))
		pixels = img.load()
		
		for i, color in enumerate(palette.colors):
			for y in range(scale):
				for x in range(scale):
					pixels[i * scale + x, y] = color.to_tuple()
		
		img.save(output_path)
	
	@staticmethod
	def export_html(palette: SNESPalette, output_path: Path) -> None:
		"""Export HTML color swatches"""
		html = f"""<!DOCTYPE html>
<html>
<head>
	<title>{palette.name}</title>
	<style>
		body {{
			font-family: monospace;
			background: #222;
			color: #fff;
			padding: 20px;
		}}
		.palette {{
			display: flex;
			flex-wrap: wrap;
			gap: 10px;
		}}
		.swatch {{
			width: 100px;
			height: 100px;
			border: 2px solid #444;
			display: flex;
			flex-direction: column;
			justify-content: center;
			align-items: center;
			font-size: 10px;
		}}
		.swatch-label {{
			background: rgba(0, 0, 0, 0.7);
			padding: 2px 5px;
			margin-top: 5px;
		}}
		h1 {{
			margin: 0 0 20px 0;
		}}
	</style>
</head>
<body>
	<h1>{palette.name}</h1>
	<p>{len(palette)} colors</p>
	<div class="palette">
"""
		
		for i, color in enumerate(palette.colors):
			html += f'\t\t<div class="swatch" style="background-color: {color.to_hex()};">\n'
			html += f'\t\t\t<div class="swatch-label">#{i}</div>\n'
			html += f'\t\t\t<div class="swatch-label">{color.to_hex()}</div>\n'
			html += f'\t\t</div>\n'
		
		html += """	</div>
</body>
</html>
"""
		
		with open(output_path, 'w') as f:
			f.write(html)
	
	@staticmethod
	def export_css(palette: SNESPalette, output_path: Path) -> None:
		"""Export CSS color variables"""
		css = f"/* {palette.name} - {len(palette)} colors */\n\n"
		css += ":root {\n"
		
		for i, color in enumerate(palette.colors):
			css += f"\t--color-{i}: {color.to_hex()};\n"
		
		css += "}\n\n"
		css += "/* Utility classes */\n"
		
		for i, color in enumerate(palette.colors):
			css += f".bg-color-{i} {{ background-color: {color.to_hex()}; }}\n"
			css += f".text-color-{i} {{ color: {color.to_hex()}; }}\n"
		
		with open(output_path, 'w') as f:
			f.write(css)


class SNESPaletteExtractor:
	"""Extract palettes from SNES ROM"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = f.read()
		
		if self.verbose:
			print(f"Loaded ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def extract_palette(self, offset: int, num_colors: int = 16, name: str = "palette") -> SNESPalette:
		"""Extract palette from ROM"""
		if self.verbose:
			print(f"Extracting palette from 0x{offset:06X} ({num_colors} colors)")
		
		palette = SNESPalette.from_rom(self.rom_data, offset, num_colors, name)
		
		if self.verbose:
			analysis = palette.analyze()
			print(f"  Unique colors: {analysis['unique_colors']}/{analysis['total_colors']}")
			print(f"  Brightness: {analysis['average_brightness']}")
		
		return palette
	
	def find_palettes(self, start_offset: int = 0, end_offset: Optional[int] = None,
					  min_colors: int = 4, max_colors: int = 256) -> List[Tuple[int, SNESPalette]]:
		"""
		Search for palettes in ROM (heuristic)
		Looks for sequences that look like valid BGR555 palettes
		"""
		if end_offset is None:
			end_offset = len(self.rom_data)
		
		palettes = []
		offset = start_offset
		
		if self.verbose:
			print(f"Searching for palettes in 0x{start_offset:06X}-0x{end_offset:06X}...")
		
		while offset < end_offset - 32:  # Need at least 16 colors
			# Try to extract a palette
			test_palette = SNESPalette.from_rom(self.rom_data, offset, 16, f"palette_{offset:06X}")
			
			# Heuristic: valid palettes have some color variation
			analysis = test_palette.analyze()
			
			if analysis['unique_colors'] >= min_colors:
				# Found a potential palette
				palettes.append((offset, test_palette))
				
				if self.verbose:
					print(f"  Found palette at 0x{offset:06X} ({analysis['unique_colors']} unique colors)")
				
				# Skip past this palette
				offset += 32  # 16 colors * 2 bytes
			else:
				offset += 2  # Try next word
		
		return palettes
	
	def export_palette(self, palette: SNESPalette, output_path: Path, 
					   fmt: Optional[PaletteFormat] = None) -> None:
		"""Export palette to file"""
		if fmt is None:
			# Detect format from extension
			ext = output_path.suffix.lower().lstrip('.')
			try:
				fmt = PaletteFormat(ext)
			except ValueError:
				fmt = PaletteFormat.GIMP  # Default
		
		exporter = SNESPaletteExporter()
		
		if fmt == PaletteFormat.GIMP:
			exporter.export_gimp(palette, output_path)
		elif fmt == PaletteFormat.ACT:
			exporter.export_act(palette, output_path)
		elif fmt == PaletteFormat.PAL:
			exporter.export_raw(palette, output_path)
		elif fmt == PaletteFormat.JSON:
			exporter.export_json(palette, output_path)
		elif fmt == PaletteFormat.PNG:
			exporter.export_png(palette, output_path)
		elif fmt == PaletteFormat.HTML:
			exporter.export_html(palette, output_path)
		elif fmt == PaletteFormat.CSS:
			exporter.export_css(palette, output_path)
		
		if self.verbose:
			print(f"✓ Exported {fmt.value} to {output_path}")


def main():
	parser = argparse.ArgumentParser(description='Extract SNES palettes from ROM')
	parser.add_argument('rom', type=Path, help='ROM file')
	parser.add_argument('--offset', type=lambda x: int(x, 0), help='Palette offset (hex)')
	parser.add_argument('--colors', type=int, default=16, help='Number of colors')
	parser.add_argument('--output', type=Path, help='Output file')
	parser.add_argument('--format', type=str, choices=[f.value for f in PaletteFormat],
						help='Output format')
	parser.add_argument('--name', type=str, default='palette', help='Palette name')
	parser.add_argument('--analyze', action='store_true', help='Analyze palette')
	parser.add_argument('--preview', action='store_true', help='Preview palette (PNG)')
	parser.add_argument('--find', action='store_true', help='Search for palettes in ROM')
	parser.add_argument('--start', type=lambda x: int(x, 0), default=0, help='Search start offset')
	parser.add_argument('--end', type=lambda x: int(x, 0), help='Search end offset')
	parser.add_argument('--extract-all', action='store_true', help='Extract all found palettes')
	parser.add_argument('--grayscale', action='store_true', help='Generate grayscale palette')
	parser.add_argument('--gradient', type=str, help='Generate gradient (color1,color2 in hex)')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	extractor = SNESPaletteExtractor(args.rom, verbose=args.verbose)
	
	# Generate grayscale
	if args.grayscale:
		palette = SNESPalette.create_grayscale(args.colors, "grayscale")
		output_path = args.output or Path('grayscale.gpl')
		extractor.export_palette(palette, output_path)
		return 0
	
	# Generate gradient
	if args.gradient:
		colors = args.gradient.split(',')
		if len(colors) != 2:
			print("Error: --gradient requires two hex colors (e.g., FF0000,0000FF)")
			return 1
		
		color1 = tuple(int(colors[0][i:i+2], 16) for i in (0, 2, 4))
		color2 = tuple(int(colors[1][i:i+2], 16) for i in (0, 2, 4))
		
		palette = SNESPalette.create_gradient(color1, color2, args.colors, "gradient")
		output_path = args.output or Path('gradient.gpl')
		extractor.export_palette(palette, output_path)
		return 0
	
	# Find palettes
	if args.find:
		palettes = extractor.find_palettes(args.start, args.end)
		
		print(f"\nFound {len(palettes)} potential palettes:")
		for offset, palette in palettes:
			analysis = palette.analyze()
			print(f"  0x{offset:06X}: {analysis['unique_colors']} unique colors, brightness {analysis['average_brightness']}")
		
		if args.extract_all:
			output_dir = args.output or Path('palettes')
			output_dir.mkdir(parents=True, exist_ok=True)
			
			for offset, palette in palettes:
				output_path = output_dir / f"palette_{offset:06X}.gpl"
				extractor.export_palette(palette, output_path)
		
		return 0
	
	# Extract specific palette
	if args.offset is None:
		print("Error: --offset required (or use --find, --grayscale, --gradient)")
		return 1
	
	palette = extractor.extract_palette(args.offset, args.colors, args.name)
	
	# Analyze
	if args.analyze:
		analysis = palette.analyze()
		print(f"\nPalette Analysis:")
		print(f"  Total colors: {analysis['total_colors']}")
		print(f"  Unique colors: {analysis['unique_colors']}")
		print(f"  Has duplicates: {analysis['has_duplicates']}")
		print(f"  Average brightness: {analysis['average_brightness']}")
		print(f"  Brightest color: #{analysis['brightest_index']} {palette.colors[analysis['brightest_index']].to_hex()}")
		print(f"  Darkest color: #{analysis['darkest_index']} {palette.colors[analysis['darkest_index']].to_hex()}")
		
		if analysis['has_duplicates']:
			print(f"\n  Duplicate colors:")
			for color in analysis['duplicate_colors']:
				print(f"    RGB{color}")
	
	# Preview
	if args.preview:
		if not PIL_AVAILABLE:
			print("Error: PIL/Pillow required for preview. Install with: pip install Pillow")
			return 1
		
		output_path = args.output or Path('palette_preview.png')
		extractor.export_palette(palette, output_path, PaletteFormat.PNG)
		print(f"✓ Preview saved to {output_path}")
		return 0
	
	# Export
	if args.output:
		fmt = PaletteFormat(args.format) if args.format else None
		extractor.export_palette(palette, args.output, fmt)
		return 0
	
	# Default: print colors
	print(f"\nPalette: {palette.name} ({len(palette)} colors)")
	for i, color in enumerate(palette.colors):
		print(f"  {i:2d}: {color.to_hex()}  RGB({color.r:3d}, {color.g:3d}, {color.b:3d})")
	
	return 0


if __name__ == '__main__':
	exit(main())
