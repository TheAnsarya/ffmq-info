#!/usr/bin/env python3
"""
SNES Asset Extractor

Comprehensive tool for extracting various assets from SNES ROMs.
Features include:
- Graphics extraction (tiles, sprites, backgrounds)
- Palette extraction and export
- Music extraction (SPC700 sequences)
- Sound effect extraction (BRR samples)
- Text/dialog extraction
- Tilemap extraction
- Compression detection and decompression
- Batch extraction with organization

Supported Formats:
- Graphics: CHR (2bpp, 4bpp, 8bpp), PNG export
- Palettes: SNES BGR555, export to RGB, GIMP palette
- Music: SPC, MIDI (if possible)
- Sounds: BRR → WAV conversion
- Text: ASCII, Shift-JIS, custom encodings
"""

from dataclasses import dataclass
from enum import Enum
from typing import Dict, List, Optional, Tuple
import struct
import os


class ColorDepth(Enum):
	"""Graphics color depth"""
	BPP_2 = 2  # 4 colors
	BPP_4 = 4  # 16 colors
	BPP_8 = 8  # 256 colors


class CompressionType(Enum):
	"""Compression types"""
	NONE = "none"
	RLE = "rle"
	LZSS = "lzss"
	LZ77 = "lz77"
	CUSTOM = "custom"


@dataclass
class Palette:
	"""SNES palette (BGR555 format)"""
	colors: List[Tuple[int, int, int]]  # RGB tuples

	@staticmethod
	def from_bgr555(data: bytes, count: int = 16) -> 'Palette':
		"""Convert BGR555 data to RGB palette"""
		colors = []
		for i in range(count):
			if i * 2 + 1 >= len(data):
				break

			bgr555 = struct.unpack('<H', data[i * 2:i * 2 + 2])[0]

			# Extract 5-bit components
			b = (bgr555 >> 10) & 0x1F
			g = (bgr555 >> 5) & 0x1F
			r = bgr555 & 0x1F

			# Convert to 8-bit (scale 0-31 to 0-255)
			r8 = (r * 255) // 31
			g8 = (g * 255) // 31
			b8 = (b * 255) // 31

			colors.append((r8, g8, b8))

		return Palette(colors)

	def to_bgr555(self) -> bytes:
		"""Convert RGB palette to BGR555 data"""
		data = bytearray()
		for r, g, b in self.colors:
			# Convert 8-bit to 5-bit
			r5 = (r * 31) // 255
			g5 = (g * 31) // 255
			b5 = (b * 31) // 255

			# Pack as BGR555
			bgr555 = (b5 << 10) | (g5 << 5) | r5
			data.extend(struct.pack('<H', bgr555))

		return bytes(data)

	def export_gimp_palette(self, filename: str, name: str = "SNES Palette"):
		"""Export as GIMP palette file"""
		with open(filename, 'w') as f:
			f.write(f"GIMP Palette\n")
			f.write(f"Name: {name}\n")
			f.write(f"Columns: 16\n")
			f.write(f"#\n")

			for i, (r, g, b) in enumerate(self.colors):
				f.write(f"{r:3d} {g:3d} {b:3d}  Color {i}\n")


@dataclass
class Tile:
	"""Graphics tile (8×8 pixels)"""
	pixels: List[List[int]]  # 8×8 array of palette indices

	@staticmethod
	def from_chr_2bpp(data: bytes) -> 'Tile':
		"""Decode 2bpp CHR tile (16 bytes)"""
		pixels = [[0] * 8 for _ in range(8)]

		for y in range(8):
			# Each row is 2 bytes (bitplane 0 and 1)
			bp0 = data[y]
			bp1 = data[y + 8]

			for x in range(8):
				bit = 7 - x
				bit0 = (bp0 >> bit) & 1
				bit1 = (bp1 >> bit) & 1
				pixels[y][x] = bit0 | (bit1 << 1)

		return Tile(pixels)

	@staticmethod
	def from_chr_4bpp(data: bytes) -> 'Tile':
		"""Decode 4bpp CHR tile (32 bytes)"""
		pixels = [[0] * 8 for _ in range(8)]

		for y in range(8):
			# Each row is 8 bytes (4 bitplanes × 2 bytes)
			bp0 = data[y]
			bp1 = data[y + 8]
			bp2 = data[y + 16]
			bp3 = data[y + 24]

			for x in range(8):
				bit = 7 - x
				bit0 = (bp0 >> bit) & 1
				bit1 = (bp1 >> bit) & 1
				bit2 = (bp2 >> bit) & 1
				bit3 = (bp3 >> bit) & 1
				pixels[y][x] = bit0 | (bit1 << 1) | (bit2 << 2) | (bit3 << 3)

		return Tile(pixels)

	@staticmethod
	def from_chr_8bpp(data: bytes) -> 'Tile':
		"""Decode 8bpp CHR tile (64 bytes)"""
		pixels = [[0] * 8 for _ in range(8)]

		for y in range(8):
			# Each row is 8 bytes (8 bitplanes)
			for x in range(8):
				bit = 7 - x
				color = 0
				for plane in range(8):
					bp = data[y + plane * 8]
					color |= ((bp >> bit) & 1) << plane
				pixels[y][x] = color

		return Tile(pixels)

	def to_chr_2bpp(self) -> bytes:
		"""Encode as 2bpp CHR"""
		data = bytearray(16)

		for y in range(8):
			bp0 = 0
			bp1 = 0
			for x in range(8):
				bit = 7 - x
				color = self.pixels[y][x]
				if color & 1:
					bp0 |= (1 << bit)
				if color & 2:
					bp1 |= (1 << bit)

			data[y] = bp0
			data[y + 8] = bp1

		return bytes(data)

	def to_chr_4bpp(self) -> bytes:
		"""Encode as 4bpp CHR"""
		data = bytearray(32)

		for y in range(8):
			bp0 = bp1 = bp2 = bp3 = 0
			for x in range(8):
				bit = 7 - x
				color = self.pixels[y][x]
				if color & 1:
					bp0 |= (1 << bit)
				if color & 2:
					bp1 |= (1 << bit)
				if color & 4:
					bp2 |= (1 << bit)
				if color & 8:
					bp3 |= (1 << bit)

			data[y] = bp0
			data[y + 8] = bp1
			data[y + 16] = bp2
			data[y + 24] = bp3

		return bytes(data)

	def to_image_data(self, palette: Palette, scale: int = 1) -> List[List[Tuple[int, int, int]]]:
		"""Convert to RGB image data"""
		height = 8 * scale
		width = 8 * scale
		image = [[(0, 0, 0) for _ in range(width)] for _ in range(height)]

		for y in range(8):
			for x in range(8):
				color_idx = self.pixels[y][x]
				if color_idx < len(palette.colors):
					color = palette.colors[color_idx]
				else:
					color = (0, 0, 0)

				# Scale up
				for sy in range(scale):
					for sx in range(scale):
						image[y * scale + sy][x * scale + sx] = color

		return image


@dataclass
class BRRSample:
	"""SNES BRR audio sample"""
	data: bytes
	loop_point: int = 0

	def to_pcm(self) -> bytes:
		"""Convert BRR to 16-bit PCM"""
		pcm_samples = []

		# BRR decoder state
		prev1 = 0
		prev2 = 0

		# Process blocks (9 bytes each)
		for block_offset in range(0, len(self.data), 9):
			if block_offset + 9 > len(self.data):
				break

			block = self.data[block_offset:block_offset + 9]
			header = block[0]

			# Parse header
			shift = header >> 4
			filter_mode = (header >> 2) & 3
			end_flag = (header >> 0) & 1
			loop_flag = (header >> 1) & 1

			# Decode 16 samples from 8 bytes
			for byte_idx in range(1, 9):
				byte_val = block[byte_idx]

				# Two 4-bit samples per byte
				for nibble in [byte_val >> 4, byte_val & 0x0F]:
					# Sign extend 4-bit to 16-bit
					if nibble & 8:
						sample = (nibble - 16) << shift
					else:
						sample = nibble << shift

					# Apply filter
					if filter_mode == 0:
						# No filter
						pass
					elif filter_mode == 1:
						# Filter 1: sample += prev1 * 15/16
						sample += prev1 + ((-prev1) >> 4)
					elif filter_mode == 2:
						# Filter 2: sample += prev1 * 61/32 - prev2 * 15/16
						sample += (prev1 << 1) + ((-prev1 * 3) >> 5) - prev2 + ((prev2) >> 4)
					elif filter_mode == 3:
						# Filter 3: sample += prev1 * 115/64 - prev2 * 13/16
						sample += (prev1 << 1) + ((-(prev1 * 13)) >> 6) - prev2 + (((prev2 * 3)) >> 4)

					# Clamp to 16-bit
					sample = max(-32768, min(32767, sample))

					pcm_samples.append(sample)

					# Update history
					prev2 = prev1
					prev1 = sample

			if end_flag:
				break

		# Convert to bytes
		pcm_data = bytearray()
		for sample in pcm_samples:
			pcm_data.extend(struct.pack('<h', sample))

		return bytes(pcm_data)

	def export_wav(self, filename: str, sample_rate: int = 32000):
		"""Export as WAV file"""
		pcm_data = self.to_pcm()
		num_samples = len(pcm_data) // 2

		with open(filename, 'wb') as f:
			# RIFF header
			f.write(b'RIFF')
			f.write(struct.pack('<I', 36 + len(pcm_data)))
			f.write(b'WAVE')

			# fmt chunk
			f.write(b'fmt ')
			f.write(struct.pack('<I', 16))  # Chunk size
			f.write(struct.pack('<H', 1))   # PCM format
			f.write(struct.pack('<H', 1))   # Mono
			f.write(struct.pack('<I', sample_rate))
			f.write(struct.pack('<I', sample_rate * 2))  # Byte rate
			f.write(struct.pack('<H', 2))   # Block align
			f.write(struct.pack('<H', 16))  # Bits per sample

			# data chunk
			f.write(b'data')
			f.write(struct.pack('<I', len(pcm_data)))
			f.write(pcm_data)


class AssetExtractor:
	"""Main asset extraction class"""

	def __init__(self, rom_data: bytes):
		self.rom_data = rom_data

	def extract_tiles(self, offset: int, count: int, depth: ColorDepth) -> List[Tile]:
		"""Extract tiles from ROM"""
		tiles = []

		if depth == ColorDepth.BPP_2:
			tile_size = 16
			decode_func = Tile.from_chr_2bpp
		elif depth == ColorDepth.BPP_4:
			tile_size = 32
			decode_func = Tile.from_chr_4bpp
		else:  # BPP_8
			tile_size = 64
			decode_func = Tile.from_chr_8bpp

		for i in range(count):
			tile_offset = offset + (i * tile_size)
			if tile_offset + tile_size <= len(self.rom_data):
				tile_data = self.rom_data[tile_offset:tile_offset + tile_size]
				tiles.append(decode_func(tile_data))

		return tiles

	def extract_palette(self, offset: int, count: int = 16) -> Palette:
		"""Extract palette from ROM"""
		palette_data = self.rom_data[offset:offset + count * 2]
		return Palette.from_bgr555(palette_data, count)

	def extract_palettes(self, offset: int, num_palettes: int = 8, colors_per_palette: int = 16) -> List[Palette]:
		"""Extract multiple palettes"""
		palettes = []
		bytes_per_palette = colors_per_palette * 2

		for i in range(num_palettes):
			pal_offset = offset + (i * bytes_per_palette)
			if pal_offset + bytes_per_palette <= len(self.rom_data):
				palettes.append(self.extract_palette(pal_offset, colors_per_palette))

		return palettes

	def extract_brr_sample(self, offset: int, max_size: int = 0x1000) -> BRRSample:
		"""Extract BRR audio sample"""
		data = bytearray()
		current_offset = offset

		while current_offset < offset + max_size and current_offset < len(self.rom_data):
			# Read 9-byte BRR block
			if current_offset + 9 > len(self.rom_data):
				break

			block = self.rom_data[current_offset:current_offset + 9]
			data.extend(block)

			header = block[0]
			end_flag = header & 1

			current_offset += 9

			if end_flag:
				break

		return BRRSample(bytes(data))

	def find_text_strings(self, min_length: int = 4, encoding: str = 'ascii') -> List[Tuple[int, str]]:
		"""Find text strings in ROM"""
		strings = []
		current_string = []
		start_offset = 0

		for i, byte in enumerate(self.rom_data):
			# Check if printable
			is_printable = False
			if encoding == 'ascii':
				is_printable = 0x20 <= byte < 0x7F
			elif encoding == 'shift_jis':
				# Simplified Shift-JIS detection
				is_printable = (0x20 <= byte < 0x7F) or (0x81 <= byte <= 0x9F) or (0xE0 <= byte <= 0xFC)

			if is_printable:
				if not current_string:
					start_offset = i
				current_string.append(byte)
			else:
				if len(current_string) >= min_length:
					try:
						text = bytes(current_string).decode(encoding, errors='ignore')
						if text.strip():
							strings.append((start_offset, text))
					except:
						pass
				current_string = []

		return strings

	def detect_compression(self, offset: int, size: int = 0x100) -> CompressionType:
		"""Try to detect compression type"""
		if offset + size > len(self.rom_data):
			return CompressionType.NONE

		data = self.rom_data[offset:offset + size]

		# Check for RLE patterns
		run_count = 0
		for i in range(len(data) - 1):
			if data[i] == data[i + 1]:
				run_count += 1

		if run_count > len(data) * 0.3:
			return CompressionType.RLE

		# Check for LZSS patterns (control byte + data)
		lzss_score = 0
		for i in range(0, len(data) - 9, 9):
			control = data[i]
			# LZSS typically has mixed 0/1 bits
			if 0x01 <= control <= 0xFE:
				lzss_score += 1

		if lzss_score > (len(data) // 9) * 0.5:
			return CompressionType.LZSS

		return CompressionType.NONE

	def export_tileset_png(self, tiles: List[Tile], palette: Palette,
						  filename: str, tiles_per_row: int = 16):
		"""Export tileset as PNG (requires PIL)"""
		try:
			from PIL import Image
		except ImportError:
			print("PIL/Pillow not available. Skipping PNG export.")
			return

		# Calculate image dimensions
		num_rows = (len(tiles) + tiles_per_row - 1) // tiles_per_row
		width = tiles_per_row * 8
		height = num_rows * 8

		# Create image
		img = Image.new('RGB', (width, height))
		pixels = img.load()

		# Draw tiles
		for tile_idx, tile in enumerate(tiles):
			tile_x = (tile_idx % tiles_per_row) * 8
			tile_y = (tile_idx // tiles_per_row) * 8

			for y in range(8):
				for x in range(8):
					color_idx = tile.pixels[y][x]
					if color_idx < len(palette.colors):
						color = palette.colors[color_idx]
					else:
						color = (0, 0, 0)

					pixels[tile_x + x, tile_y + y] = color

		img.save(filename)

	def batch_extract(self, output_dir: str):
		"""Batch extract common assets"""
		os.makedirs(output_dir, exist_ok=True)

		print("Asset Extraction Report")
		print("=" * 60)

		# Extract graphics (common locations for SNES games)
		graphics_offsets = [0x10000, 0x20000, 0x30000, 0x40000]
		for idx, offset in enumerate(graphics_offsets):
			if offset + 0x2000 < len(self.rom_data):
				tiles = self.extract_tiles(offset, 128, ColorDepth.BPP_4)
				if tiles:
					filename = os.path.join(output_dir, f"tileset_{idx:02d}.chr")
					with open(filename, 'wb') as f:
						for tile in tiles:
							f.write(tile.to_chr_4bpp())
					print(f"Extracted tileset {idx}: {len(tiles)} tiles → {filename}")

		# Extract palettes (common locations)
		palette_offsets = [0xC000, 0x1C000, 0x2C000]
		for idx, offset in enumerate(palette_offsets):
			if offset + 0x200 < len(self.rom_data):
				palettes = self.extract_palettes(offset, 8, 16)
				if palettes:
					for pal_idx, palette in enumerate(palettes):
						filename = os.path.join(output_dir, f"palette_{idx:02d}_{pal_idx:02d}.gpl")
						palette.export_gimp_palette(filename, f"Palette {idx}-{pal_idx}")
					print(f"Extracted {len(palettes)} palettes from ${offset:06X}")

		# Extract text strings
		strings = self.find_text_strings(min_length=8)
		if strings:
			filename = os.path.join(output_dir, "text_strings.txt")
			with open(filename, 'w', encoding='utf-8') as f:
				for offset, text in strings:
					f.write(f"${offset:06X}: {text}\n")
			print(f"Extracted {len(strings)} text strings → {filename}")

		# Extract BRR samples (look for BRR headers)
		brr_samples = []
		for i in range(0, len(self.rom_data) - 9, 9):
			header = self.rom_data[i]
			# Check for valid BRR header
			if (header & 0x0C) == 0:  # Reserved bits should be 0
				shift = header >> 4
				if 0 <= shift <= 12:  # Valid shift range
					try:
						sample = self.extract_brr_sample(i, max_size=0x800)
						if len(sample.data) >= 9:
							brr_samples.append((i, sample))
					except:
						pass

		# Save first 10 BRR samples
		for idx, (offset, sample) in enumerate(brr_samples[:10]):
			filename = os.path.join(output_dir, f"sample_{idx:03d}.brr")
			with open(filename, 'wb') as f:
				f.write(sample.data)

			# Also export as WAV
			wav_filename = os.path.join(output_dir, f"sample_{idx:03d}.wav")
			try:
				sample.export_wav(wav_filename)
			except:
				pass

		if brr_samples:
			print(f"Extracted {min(len(brr_samples), 10)} BRR samples")

		print("\nExtraction complete!")


def main():
	"""Test asset extractor"""
	# Create test ROM with sample data
	test_rom = bytearray(0x80000)

	# Add some test tiles at 0x10000 (4bpp)
	for i in range(128):
		offset = 0x10000 + (i * 32)
		# Simple pattern
		for y in range(8):
			test_rom[offset + y] = (i + y) & 0xFF
			test_rom[offset + y + 8] = ((i + y) >> 1) & 0xFF
			test_rom[offset + y + 16] = ((i + y) >> 2) & 0xFF
			test_rom[offset + y + 24] = ((i + y) >> 3) & 0xFF

	# Add test palette at 0x20000
	for i in range(16):
		# Gradient from black to white
		intensity = (i * 31) // 15
		bgr555 = (intensity << 10) | (intensity << 5) | intensity
		test_rom[0x20000 + i * 2:0x20000 + i * 2 + 2] = struct.pack('<H', bgr555)

	# Add test text
	text = b"FINAL FANTASY MYSTIC QUEST - ASSET EXTRACTOR TEST"
	test_rom[0x30000:0x30000 + len(text)] = text

	# Create extractor
	extractor = AssetExtractor(bytes(test_rom))

	# Test tile extraction
	print("Extracting tiles...")
	tiles = extractor.extract_tiles(0x10000, 16, ColorDepth.BPP_4)
	print(f"Extracted {len(tiles)} tiles")

	# Test palette extraction
	print("\nExtracting palette...")
	palette = extractor.extract_palette(0x20000, 16)
	print(f"Extracted palette with {len(palette.colors)} colors")

	# Test text extraction
	print("\nFinding text strings...")
	strings = extractor.find_text_strings()
	print(f"Found {len(strings)} strings")
	for offset, text in strings[:5]:
		print(f"  ${offset:06X}: {text}")

	# Batch extraction
	print("\nRunning batch extraction...")
	extractor.batch_extract("extracted_assets")


if __name__ == "__main__":
	main()
