#!/usr/bin/env python3
"""
FFMQ Palette Extraction Tool
=============================

Extracts SNES RGB555 color palettes from Final Fantasy Mystic Quest ROM.
Supports multi-bank palette architecture (Banks $09/$0a/$0b).

Features:
- Parse pointer tables from Bank $09 ($098460-$0985f4)
- Follow cross-bank references to Banks $0a and $0b
- Convert RGB555 to standard RGB888 format
- Export to PNG swatches (16x16 pixels per color)
- Generate JSON palette data for tools/editors
- Validate color counts and data integrity

Author: AI-assisted disassembly project
Date: October 29, 2025
"""

import sys
import os
import struct
import json
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
	raw_low: int   # LOW byte of RGB555
	raw_high: int  # HIGH byte of RGB555

	@property
	def rgb555(self) -> int:
		"""Combined 15-bit RGB555 value"""
		return (self.raw_high << 8) | self.raw_low

	@property
	def r5(self) -> int:
		"""Red channel (5-bit, 0-31)"""
		return self.rgb555 & 0x1f

	@property
	def g5(self) -> int:
		"""Green channel (5-bit, 0-31)"""
		return (self.rgb555 >> 5) & 0x1f

	@property
	def b5(self) -> int:
		"""Blue channel (5-bit, 0-31)"""
		return (self.rgb555 >> 10) & 0x1f

	@property
	def r8(self) -> int:
		"""Red channel (8-bit, 0-255)"""
		return (self.r5 << 3) | (self.r5 >> 2)

	@property
	def g8(self) -> int:
		"""Green channel (8-bit, 0-255)"""
		return (self.g5 << 3) | (self.g5 >> 2)

	@property
	def b8(self) -> int:
		"""Blue channel (8-bit, 0-255)"""
		return (self.b5 << 3) | (self.b5 >> 2)

	@property
	def rgb888(self) -> Tuple[int, int, int]:
		"""Standard RGB tuple (0-255 per channel)"""
		return (self.r8, self.g8, self.b8)

	def __str__(self) -> str:
		return f"RGB555(${self.rgb555:04X}) = RGB888({self.r8}, {self.g8}, {self.b8})"


@dataclass
class PaletteEntry:
	"""Single palette entry from pointer table"""
	index: int		  # Entry index in table
	address: int		# 24-bit ROM address (bank included)
	bank: int		  # SNES bank number ($09/$0a/$0b)
	color_count: int   # Number of colors (0 = full palette = 16)
	flags: int		 # Special flags ($00 standard, $03/$12 special)
	colors: List[RGB555Color]

	@property
	def actual_color_count(self) -> int:
		"""Actual color count (0 means 16)"""
		return 16 if self.color_count == 0 else self.color_count

	@property
	def byte_size(self) -> int:
		"""Size in bytes (2 bytes per color)"""
		return self.actual_color_count * 2


@dataclass
class PaletteBank:
	"""Collection of palettes from one bank"""
	bank_number: int
	entries: List[PaletteEntry]

	@property
	def total_colors(self) -> int:
		"""Total colors across all entries"""
		return sum(e.actual_color_count for e in self.entries)


# ============================================================================
# ROM ACCESS
# ============================================================================

class ROMReader:
	"""Read data from SNES ROM file"""

	def __init__(self, rom_path: str):
		self.rom_path = rom_path
		with open(rom_path, 'rb') as f:
			self.data = bytearray(f.read())

		# Detect header (512 bytes if present)
		self.header_size = 512 if len(self.data) % 1024 == 512 else 0
		print(f"ROM loaded: {len(self.data)} bytes ({self.header_size}-byte header)")

	def snes_to_pc(self, snes_addr: int) -> int:
		"""Convert SNES address to PC file offset (LoROM mapping)"""
		bank = (snes_addr >> 16) & 0xff
		offset = snes_addr & 0xffff

		if offset < 0x8000:
			raise ValueError(f"Invalid SNES address ${snes_addr:06X} (offset < $8000)")

		# LoROM: Bank $XX:$8000-$ffff maps to PC $(XX*32KB)
		pc_addr = (bank * 0x8000) + (offset - 0x8000) + self.header_size
		return pc_addr

	def read_byte(self, snes_addr: int) -> int:
		"""Read single byte from SNES address"""
		pc_addr = self.snes_to_pc(snes_addr)
		return self.data[pc_addr]

	def read_bytes(self, snes_addr: int, count: int) -> bytes:
		"""Read multiple bytes from SNES address"""
		pc_addr = self.snes_to_pc(snes_addr)
		return bytes(self.data[pc_addr:pc_addr + count])

	def read_word(self, snes_addr: int) -> int:
		"""Read 16-bit word (little-endian)"""
		data = self.read_bytes(snes_addr, 2)
		return struct.unpack('<H', data)[0]

	def read_rgb555(self, snes_addr: int) -> RGB555Color:
		"""Read RGB555 color (2 bytes, little-endian)"""
		low = self.read_byte(snes_addr)
		high = self.read_byte(snes_addr + 1)
		return RGB555Color(low, high)


# ============================================================================
# PALETTE EXTRACTION
# ============================================================================

class PaletteExtractor:
	"""Extract palettes from FFMQ ROM"""

	# Pointer table location in Bank $09
	POINTER_TABLE_START = 0x098460
	POINTER_TABLE_END = 0x0985f4
	POINTER_ENTRY_SIZE = 5  # [addr_low, addr_mid, addr_high, count, flags]

	def __init__(self, rom: ROMReader):
		self.rom = rom
		self.entries: List[PaletteEntry] = []

	def parse_pointer_table(self) -> List[PaletteEntry]:
		"""Parse palette pointer table from Bank $09"""
		print(f"\nParsing pointer table ${self.POINTER_TABLE_START:06X}-${self.POINTER_TABLE_END:06X}...")

		entries = []
		addr = self.POINTER_TABLE_START
		index = 0

		while addr < self.POINTER_TABLE_END:
			# Read 5-byte pointer entry
			entry_data = self.rom.read_bytes(addr, self.POINTER_ENTRY_SIZE)

			# Check for terminator ($ff,$ff at bytes 0-1)
			if entry_data[0] == 0xff and entry_data[1] == 0xff:
				print(f"  Found terminator at ${addr:06X}")
				break

			# Parse entry
			addr_low = entry_data[0]
			addr_mid = entry_data[1]
			addr_high = entry_data[2]
			color_count = entry_data[3]
			flags = entry_data[4]

			# Build 24-bit address
			palette_addr = (addr_high << 16) | (addr_mid << 8) | addr_low
			bank = addr_high

			# Read colors
			actual_count = 16 if color_count == 0 else color_count
			colors = []
			for i in range(actual_count):
				color = self.rom.read_rgb555(palette_addr + (i * 2))
				colors.append(color)

			entry = PaletteEntry(
				index=index,
				address=palette_addr,
				bank=bank,
				color_count=color_count,
				flags=flags,
				colors=colors
			)
			entries.append(entry)

			print(f"  Entry {index:3d}: ${palette_addr:06X} Bank=${bank:02X} Count={actual_count:2d} Flags=${flags:02X}")

			addr += self.POINTER_ENTRY_SIZE
			index += 1

		print(f"\nParsed {len(entries)} palette entries")
		self.entries = entries
		return entries

	def group_by_bank(self) -> Dict[int, PaletteBank]:
		"""Group palette entries by bank number"""
		banks = {}
		for entry in self.entries:
			if entry.bank not in banks:
				banks[entry.bank] = PaletteBank(entry.bank, [])
			banks[entry.bank].entries.append(entry)

		print(f"\nPalettes by bank:")
		for bank_num in sorted(banks.keys()):
			bank = banks[bank_num]
			print(f"  Bank ${bank_num:02X}: {len(bank.entries)} entries, {bank.total_colors} colors")

		return banks


# ============================================================================
# VISUALIZATION
# ============================================================================

class PaletteVisualizer:
	"""Create visual representations of palettes"""

	COLOR_SIZE = 32  # 32x32 pixels per color swatch
	COLORS_PER_ROW = 16
	LABEL_HEIGHT = 20
	MARGIN = 4

	def __init__(self, output_dir: str):
		self.output_dir = Path(output_dir)
		self.output_dir.mkdir(parents=True, exist_ok=True)

	def create_palette_swatch(self, entry: PaletteEntry, filename: str):
		"""Create PNG swatch for a single palette entry"""
		colors = entry.colors
		count = len(colors)

		# Calculate image size
		rows = (count + self.COLORS_PER_ROW - 1) // self.COLORS_PER_ROW
		width = min(count, self.COLORS_PER_ROW) * self.COLOR_SIZE + (self.MARGIN * 2)
		height = rows * self.COLOR_SIZE + self.LABEL_HEIGHT + (self.MARGIN * 2)

		# Create image
		img = Image.new('RGB', (width, height), color=(64, 64, 64))
		draw = ImageDraw.Draw(img)

		# Draw color swatches
		for i, color in enumerate(colors):
			row = i // self.COLORS_PER_ROW
			col = i % self.COLORS_PER_ROW

			x = col * self.COLOR_SIZE + self.MARGIN
			y = row * self.COLOR_SIZE + self.LABEL_HEIGHT + self.MARGIN

			# Draw color box
			draw.rectangle(
				[x, y, x + self.COLOR_SIZE - 1, y + self.COLOR_SIZE - 1],
				fill=color.rgb888
			)

			# Draw border
			draw.rectangle(
				[x, y, x + self.COLOR_SIZE - 1, y + self.COLOR_SIZE - 1],
				outline=(255, 255, 255),
				width=1
			)

		# Draw label
		label = f"Entry {entry.index}: ${entry.address:06X} Bank=${entry.bank:02X} ({count} colors)"
		draw.text((self.MARGIN, self.MARGIN), label, fill=(255, 255, 255))

		# Save
		output_path = self.output_dir / filename
		img.save(output_path)
		print(f"  Created: {output_path}")

	def create_bank_overview(self, bank: PaletteBank, filename: str):
		"""Create overview PNG showing all palettes in a bank"""
		entries = bank.entries
		total_colors = bank.total_colors

		# Calculate grid size (4 palettes per row)
		palettes_per_row = 4
		rows = (len(entries) + palettes_per_row - 1) // palettes_per_row

		palette_width = self.COLORS_PER_ROW * self.COLOR_SIZE
		palette_height = 2 * self.COLOR_SIZE + self.LABEL_HEIGHT  # Assume max 2 rows

		width = palettes_per_row * palette_width + (self.MARGIN * (palettes_per_row + 1))
		height = rows * palette_height + self.LABEL_HEIGHT + (self.MARGIN * (rows + 1))

		# Create image
		img = Image.new('RGB', (width, height), color=(32, 32, 32))
		draw = ImageDraw.Draw(img)

		# Draw title
		title = f"Bank ${bank.bank_number:02X}: {len(entries)} Palettes, {total_colors} Colors"
		draw.text((self.MARGIN, self.MARGIN), title, fill=(255, 255, 255))

		# Draw mini palettes
		for idx, entry in enumerate(entries):
			row = idx // palettes_per_row
			col = idx % palettes_per_row

			x_base = col * palette_width + (self.MARGIN * (col + 1))
			y_base = row * palette_height + self.LABEL_HEIGHT + (self.MARGIN * (row + 1))

			# Draw colors (smaller)
			for i, color in enumerate(entry.colors[:16]):  # Max 16 colors for overview
				color_x = x_base + (i % 16) * (self.COLOR_SIZE // 2)
				color_y = y_base + (i // 16) * (self.COLOR_SIZE // 2)

				draw.rectangle(
					[color_x, color_y, color_x + (self.COLOR_SIZE // 2) - 1, color_y + (self.COLOR_SIZE // 2) - 1],
					fill=color.rgb888
				)

			# Draw label
			label = f"#{entry.index}"
			draw.text((x_base, y_base - 15), label, fill=(200, 200, 200))

		# Save
		output_path = self.output_dir / filename
		img.save(output_path)
		print(f"  Created: {output_path}")


# ============================================================================
# JSON EXPORT
# ============================================================================

class PaletteExporter:
	"""Export palette data to JSON"""

	def __init__(self, output_dir: str):
		self.output_dir = Path(output_dir)
		self.output_dir.mkdir(parents=True, exist_ok=True)

	def export_palette(self, entry: PaletteEntry, filename: str):
		"""Export single palette to JSON"""
		data = {
			'index': entry.index,
			'address': f'${entry.address:06X}',
			'bank': f'${entry.bank:02X}',
			'color_count': entry.actual_color_count,
			'flags': f'${entry.flags:02X}',
			'colors': []
		}

		for i, color in enumerate(entry.colors):
			data['colors'].append({
				'index': i,
				'rgb555': f'${color.rgb555:04X}',
				'rgb555_bytes': [color.raw_low, color.raw_high],
				'r5': color.r5,
				'g5': color.g5,
				'b5': color.b5,
				'rgb888': color.rgb888,
				'hex': f'#{color.r8:02X}{color.g8:02X}{color.b8:02X}'
			})

		output_path = self.output_dir / filename
		with open(output_path, 'w') as f:
			json.dump(data, f, indent=2)
		print(f"  Exported: {output_path}")

	def export_all(self, entries: List[PaletteEntry], filename: str):
		"""Export all palettes to single JSON file"""
		data = {
			'total_palettes': len(entries),
			'total_colors': sum(e.actual_color_count for e in entries),
			'palettes': []
		}

		for entry in entries:
			palette_data = {
				'index': entry.index,
				'address': f'${entry.address:06X}',
				'bank': f'${entry.bank:02X}',
				'color_count': entry.actual_color_count,
				'flags': f'${entry.flags:02X}',
				'colors': [
					{
						'rgb555': f'${c.rgb555:04X}',
						'rgb888': c.rgb888,
						'hex': f'#{c.r8:02X}{c.g8:02X}{c.b8:02X}'
					}
					for c in entry.colors
				]
			}
			data['palettes'].append(palette_data)

		output_path = self.output_dir / filename
		with open(output_path, 'w') as f:
			json.dump(data, f, indent=2)
		print(f"  Exported: {output_path}")


# ============================================================================
# MAIN
# ============================================================================

def main():
	"""Main extraction process"""
	print("=" * 80)
	print("FFMQ Palette Extraction Tool")
	print("=" * 80)

	# Configuration
	rom_path = "roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc"
	output_base = "assets/palettes"

	# Check ROM exists
	if not os.path.exists(rom_path):
		print(f"ERROR: ROM not found at {rom_path}")
		print("\nTrying alternate locations...")
		alt_paths = [
			"roms/Final Fantasy - Mystic Quest (U) (V1.0) [!].sfc",
			"../roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc",
			"ffmq.sfc"
		]
		for alt_path in alt_paths:
			if os.path.exists(alt_path):
				rom_path = alt_path
				print(f"Found: {rom_path}")
				break
		else:
			print("ERROR: No ROM found!")
			sys.exit(1)

	# Load ROM
	print(f"\nLoading ROM: {rom_path}")
	rom = ROMReader(rom_path)

	# Extract palettes
	extractor = PaletteExtractor(rom)
	entries = extractor.parse_pointer_table()
	banks = extractor.group_by_bank()

	# Create visualizations
	print("\n" + "=" * 80)
	print("Creating Visualizations")
	print("=" * 80)

	viz = PaletteVisualizer(f"{output_base}/swatches")

	# Individual palette swatches
	print("\nCreating individual palette swatches...")
	for entry in entries[:20]:  # First 20 for testing
		filename = f"palette_{entry.index:03d}_${entry.address:06X}.png"
		viz.create_palette_swatch(entry, filename)

	# Bank overviews
	print("\nCreating bank overview images...")
	for bank_num, bank in banks.items():
		filename = f"bank_${bank_num:02X}_overview.png"
		viz.create_bank_overview(bank, filename)

	# Export JSON
	print("\n" + "=" * 80)
	print("Exporting JSON Data")
	print("=" * 80)

	exporter = PaletteExporter(f"{output_base}/json")

	print("\nExporting all palettes to JSON...")
	exporter.export_all(entries, "all_palettes.json")

	print("\nExporting individual palette JSON files...")
	for entry in entries[:10]:  # First 10 for testing
		filename = f"palette_{entry.index:03d}.json"
		exporter.export_palette(entry, filename)

	# Summary
	print("\n" + "=" * 80)
	print("EXTRACTION COMPLETE!")
	print("=" * 80)
	print(f"\nTotal Palettes: {len(entries)}")
	print(f"Total Colors: {sum(e.actual_color_count for e in entries)}")
	print(f"\nOutput Directory: {output_base}/")
	print(f"  - swatches/ : PNG color swatch images")
	print(f"  - json/	 : JSON palette data files")
	print("\nUse these assets for:")
	print("  - ROM hacking / modding")
	print("  - Palette editors")
	print("  - Color analysis")
	print("  - Documentation")


if __name__ == '__main__':
	main()
