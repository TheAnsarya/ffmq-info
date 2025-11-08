#!/usr/bin/env python3
"""
SNES Graphics Format Library
Core graphics format handlers for SNES tile, palette, and tilemap data
Supports 2BPP, 4BPP, 8BPP tile formats and SNES RGB555 palette format
"""

import struct
from typing import List, Tuple, Optional
from dataclasses import dataclass

@dataclass
class SNESColor:
	"""SNES RGB555 color (15-bit color: 5-bits per channel)"""
	r: int	# Red (0-31)
	g: int	# Green (0-31)
	b: int	# Blue (0-31)
	
	@classmethod
	def from_snes(cls, word: int) -> 'SNESColor':
		"""Create color from SNES RGB555 format word (0BBBBBGGGGGRRRRR)"""
		return cls(
			r=(word & 0x1f),
			g=((word >> 5) & 0x1f),
			b=((word >> 10) & 0x1f)
		)
	
	def to_snes(self) -> int:
		"""Convert to SNES RGB555 format word"""
		return (self.r & 0x1f) | ((self.g & 0x1f) << 5) | ((self.b & 0x1f) << 10)
	
	def to_rgb888(self) -> Tuple[int, int, int]:
		"""Convert to standard RGB (0-255 per channel)"""
		# Convert 5-bit to 8-bit by shifting and copying high bits to low bits
		return (
			(self.r << 3) | (self.r >> 2),
			(self.g << 3) | (self.g >> 2),
			(self.b << 3) | (self.b >> 2)
		)
	
	@classmethod
	def from_rgb888(cls, r: int, g: int, b: int) -> 'SNESColor':
		"""Create color from RGB (0-255 per channel)"""
		return cls(r=r >> 3, g=g >> 3, b=b >> 3)
	
	def __str__(self) -> str:
		r8, g8, b8 = self.to_rgb888()
		return f"RGB({r8:02x},{g8:02x},{b8:02x}) SNES:${self.to_snes():04x}"


class SNESPalette:
	"""SNES palette (up to 256 colors, organized in 16-color sub-palettes)"""
	
	def __init__(self, colors: Optional[List[SNESColor]] = None):
		self.colors = colors if colors else []
	
	@classmethod
	def from_bytes(cls, data: bytes, offset: int = 0, count: int = 256) -> 'SNESPalette':
		"""Load palette from raw bytes (SNES RGB555 format, 2 bytes per color)"""
		colors = []
		for i in range(count):
			byte_offset = offset + i * 2
			if byte_offset + 1 < len(data):
				word = struct.unpack('<H', data[byte_offset:byte_offset + 2])[0]
				colors.append(SNESColor.from_snes(word))
			else:
				break
		return cls(colors)
	
	def to_bytes(self) -> bytes:
		"""Convert palette to raw bytes (SNES RGB555 format)"""
		data = bytearray()
		for color in self.colors:
			data.extend(struct.pack('<H', color.to_snes()))
		return bytes(data)
	
	def get_subpalette(self, index: int) -> List[SNESColor]:
		"""Get a 16-color sub-palette (palettes 0-15)"""
		start = index * 16
		end = start + 16
		return self.colors[start:end] if end <= len(self.colors) else []
	
	def set_color(self, index: int, color: SNESColor) -> None:
		"""Set a color in the palette"""
		while len(self.colors) <= index:
			self.colors.append(SNESColor(0, 0, 0))
		self.colors[index] = color
	
	def __len__(self) -> int:
		return len(self.colors)
	
	def __str__(self) -> str:
		return f"SNESPalette({len(self.colors)} colors)"


class SNESTile:
	"""SNES 8x8 pixel tile with palette indices"""
	
	def __init__(self, width: int = 8, height: int = 8):
		self.width = width
		self.height = height
		self.pixels = [[0 for _ in range(width)] for _ in range(height)]
	
	def get_pixel(self, x: int, y: int) -> int:
		"""Get palette index for pixel at (x, y)"""
		if 0 <= x < self.width and 0 <= y < self.height:
			return self.pixels[y][x]
		return 0
	
	def set_pixel(self, x: int, y: int, palette_index: int) -> None:
		"""Set palette index for pixel at (x, y)"""
		if 0 <= x < self.width and 0 <= y < self.height:
			self.pixels[y][x] = palette_index
	
	@classmethod
	def decode_2bpp(cls, data: bytes, offset: int = 0) -> 'SNESTile':
		"""
		Decode 2BPP tile from bytes (16 bytes = 8x8 tile, 2 bits per pixel)
		Format: 2 bitplanes interleaved by row
		Bytes 0-1: Row 0 (plane 0, plane 1)
		Bytes 2-3: Row 1 (plane 0, plane 1)
		...
		"""
		tile = cls(8, 8)
		for y in range(8):
			byte_offset = offset + y * 2
			if byte_offset + 1 >= len(data):
				break
			
			plane0 = data[byte_offset]
			plane1 = data[byte_offset + 1]
			
			for x in range(8):
				bit_mask = 1 << (7 - x)
				pixel = 0
				if plane0 & bit_mask:
					pixel |= 1
				if plane1 & bit_mask:
					pixel |= 2
				tile.pixels[y][x] = pixel
		
		return tile
	
	@classmethod
	def decode_4bpp(cls, data: bytes, offset: int = 0) -> 'SNESTile':
		"""
		Decode 4BPP tile from bytes (32 bytes = 8x8 tile, 4 bits per pixel)
		Format: 4 bitplanes, planes 0-1 interleaved, then planes 2-3 interleaved
		Bytes 0-1: Row 0 planes 0-1
		Bytes 2-3: Row 1 planes 0-1
		...
		Bytes 16-17: Row 0 planes 2-3
		Bytes 18-19: Row 1 planes 2-3
		...
		"""
		tile = cls(8, 8)
		for y in range(8):
			plane01_offset = offset + y * 2
			plane23_offset = offset + 16 + y * 2
			
			if plane23_offset + 1 >= len(data):
				break
			
			plane0 = data[plane01_offset]
			plane1 = data[plane01_offset + 1]
			plane2 = data[plane23_offset]
			plane3 = data[plane23_offset + 1]
			
			for x in range(8):
				bit_mask = 1 << (7 - x)
				pixel = 0
				if plane0 & bit_mask:
					pixel |= 1
				if plane1 & bit_mask:
					pixel |= 2
				if plane2 & bit_mask:
					pixel |= 4
				if plane3 & bit_mask:
					pixel |= 8
				tile.pixels[y][x] = pixel
		
		return tile
	
	@classmethod
	def decode_8bpp(cls, data: bytes, offset: int = 0) -> 'SNESTile':
		"""
		Decode 8BPP tile from bytes (64 bytes = 8x8 tile, 8 bits per pixel)
		Format: 8 bitplanes, planes 0-1 interleaved, then 2-3, then 4-5, then 6-7
		"""
		tile = cls(8, 8)
		for y in range(8):
			plane01_offset = offset + y * 2
			plane23_offset = offset + 16 + y * 2
			plane45_offset = offset + 32 + y * 2
			plane67_offset = offset + 48 + y * 2
			
			if plane67_offset + 1 >= len(data):
				break
			
			plane0 = data[plane01_offset]
			plane1 = data[plane01_offset + 1]
			plane2 = data[plane23_offset]
			plane3 = data[plane23_offset + 1]
			plane4 = data[plane45_offset]
			plane5 = data[plane45_offset + 1]
			plane6 = data[plane67_offset]
			plane7 = data[plane67_offset + 1]
			
			for x in range(8):
				bit_mask = 1 << (7 - x)
				pixel = 0
				if plane0 & bit_mask:
					pixel |= 1
				if plane1 & bit_mask:
					pixel |= 2
				if plane2 & bit_mask:
					pixel |= 4
				if plane3 & bit_mask:
					pixel |= 8
				if plane4 & bit_mask:
					pixel |= 16
				if plane5 & bit_mask:
					pixel |= 32
				if plane6 & bit_mask:
					pixel |= 64
				if plane7 & bit_mask:
					pixel |= 128
				tile.pixels[y][x] = pixel
		
		return tile
	
	def encode_2bpp(self) -> bytes:
		"""Encode tile to 2BPP format (16 bytes)"""
		data = bytearray(16)
		for y in range(8):
			plane0 = 0
			plane1 = 0
			for x in range(8):
				pixel = self.pixels[y][x]
				bit_mask = 1 << (7 - x)
				if pixel & 1:
					plane0 |= bit_mask
				if pixel & 2:
					plane1 |= bit_mask
			data[y * 2] = plane0
			data[y * 2 + 1] = plane1
		return bytes(data)
	
	def encode_4bpp(self) -> bytes:
		"""Encode tile to 4BPP format (32 bytes)"""
		data = bytearray(32)
		for y in range(8):
			plane0 = plane1 = plane2 = plane3 = 0
			for x in range(8):
				pixel = self.pixels[y][x]
				bit_mask = 1 << (7 - x)
				if pixel & 1:
					plane0 |= bit_mask
				if pixel & 2:
					plane1 |= bit_mask
				if pixel & 4:
					plane2 |= bit_mask
				if pixel & 8:
					plane3 |= bit_mask
			data[y * 2] = plane0
			data[y * 2 + 1] = plane1
			data[16 + y * 2] = plane2
			data[16 + y * 2 + 1] = plane3
		return bytes(data)
	
	def encode_8bpp(self) -> bytes:
		"""Encode tile to 8BPP format (64 bytes)"""
		data = bytearray(64)
		for y in range(8):
			planes = [0] * 8
			for x in range(8):
				pixel = self.pixels[y][x]
				bit_mask = 1 << (7 - x)
				for bit in range(8):
					if pixel & (1 << bit):
						planes[bit] |= bit_mask
			# Write interleaved pairs
			for pair in range(4):
				data[pair * 16 + y * 2] = planes[pair * 2]
				data[pair * 16 + y * 2 + 1] = planes[pair * 2 + 1]
		return bytes(data)
	
	def flip_horizontal(self) -> 'SNESTile':
		"""Return horizontally flipped copy of tile"""
		flipped = SNESTile(self.width, self.height)
		for y in range(self.height):
			for x in range(self.width):
				flipped.pixels[y][self.width - 1 - x] = self.pixels[y][x]
		return flipped
	
	def flip_vertical(self) -> 'SNESTile':
		"""Return vertically flipped copy of tile"""
		flipped = SNESTile(self.width, self.height)
		for y in range(self.height):
			for x in range(self.width):
				flipped.pixels[self.height - 1 - y][x] = self.pixels[y][x]
		return flipped
	
	def __str__(self) -> str:
		"""ASCII representation of tile"""
		chars = " ░▒▓█"
		lines = []
		for y in range(self.height):
			line = ""
			for x in range(self.width):
				pixel = self.pixels[y][x]
				# Map to character based on palette index
				char_idx = min(pixel, len(chars) - 1)
				line += chars[char_idx] * 2	# Double width for square-ish appearance
			lines.append(line)
		return "\n".join(lines)


def decode_tiles(data: bytes, offset: int, count: int, bpp: int) -> List[SNESTile]:
	"""
	Decode multiple tiles from data
	
	Args:
		data: Raw tile data
		offset: Starting offset in data
		count: Number of tiles to decode
		bpp: Bits per pixel (2, 4, or 8)
	
	Returns:
		List of SNESTile objects
	"""
	tiles = []
	bytes_per_tile = (bpp * 64) // 8	# 8x8 pixels, bpp bits per pixel, 8 bits per byte
	
	decode_func = {
		2: SNESTile.decode_2bpp,
		4: SNESTile.decode_4bpp,
		8: SNESTile.decode_8bpp,
	}.get(bpp)
	
	if not decode_func:
		raise ValueError(f"Unsupported BPP: {bpp}")
	
	for i in range(count):
		tile_offset = offset + i * bytes_per_tile
		if tile_offset + bytes_per_tile <= len(data):
			tiles.append(decode_func(data, tile_offset))
		else:
			break
	
	return tiles


def encode_tiles(tiles: List[SNESTile], bpp: int) -> bytes:
	"""
	Encode multiple tiles to raw data
	
	Args:
		tiles: List of SNESTile objects
		bpp: Bits per pixel (2, 4, or 8)
	
	Returns:
		Raw tile data as bytes
	"""
	encode_func = {
		2: SNESTile.encode_2bpp,
		4: SNESTile.encode_4bpp,
		8: SNESTile.encode_8bpp,
	}.get(bpp)
	
	if not encode_func:
		raise ValueError(f"Unsupported BPP: {bpp}")
	
	data = bytearray()
	for tile in tiles:
		data.extend(encode_func(tile))
	
	return bytes(data)
