#!/usr/bin/env python3
"""
ROM I/O utilities for FFMQ Map Editor
Handles reading and writing map data from/to ROM files
"""

import struct
from pathlib import Path
from typing import Optional, Tuple, List
import numpy as np

class ROMHandler:
	"""Handles FFMQ ROM file operations"""

	# ROM memory map addresses (LoROM format)
	MAP_HEADER_BASE = 0x028000  # Map header table
	MAP_DATA_BASE = 0x030000    # Compressed map data
	COLLISION_BASE = 0x038000   # Collision data
	TILESET_BASE = 0x080000     # Tileset graphics
	PALETTE_BASE = 0x0C0000     # Palette data

	# Constants
	HEADER_SIZE = 32            # Bytes per map header
	MAX_MAPS = 128              # Maximum number of maps

	def __init__(self, rom_path: Optional[str] = None):
		"""Initialize ROM handler"""
		self.rom_path = None
		self.rom_data = None

		if rom_path:
			self.load_rom(rom_path)

	def load_rom(self, rom_path: str) -> bool:
		"""Load a ROM file"""
		try:
			path = Path(rom_path)
			if not path.exists():
				print(f"ROM file not found: {rom_path}")
				return False

			with open(path, 'rb') as f:
				self.rom_data = bytearray(f.read())

			self.rom_path = path
			print(f"Loaded ROM: {path.name} ({len(self.rom_data):,} bytes)")
			return True

		except Exception as e:
			print(f"Error loading ROM: {e}")
			return False

	def save_rom(self, output_path: Optional[str] = None) -> bool:
		"""Save ROM data to file"""
		if self.rom_data is None:
			print("No ROM data loaded")
			return False

		try:
			path = Path(output_path or self.rom_path)

			with open(path, 'wb') as f:
				f.write(self.rom_data)

			print(f"Saved ROM: {path.name}")
			return True

		except Exception as e:
			print(f"Error saving ROM: {e}")
			return False

	def read_byte(self, address: int) -> int:
		"""Read a single byte from ROM"""
		if self.rom_data and 0 <= address < len(self.rom_data):
			return self.rom_data[address]
		return 0

	def read_word(self, address: int) -> int:
		"""Read a 16-bit word (little-endian) from ROM"""
		if self.rom_data and 0 <= address + 1 < len(self.rom_data):
			return struct.unpack_from('<H', self.rom_data, address)[0]
		return 0

	def read_bytes(self, address: int, count: int) -> bytes:
		"""Read multiple bytes from ROM"""
		if self.rom_data and 0 <= address + count <= len(self.rom_data):
			return bytes(self.rom_data[address:address + count])
		return b''

	def write_byte(self, address: int, value: int) -> bool:
		"""Write a single byte to ROM"""
		if self.rom_data and 0 <= address < len(self.rom_data):
			self.rom_data[address] = value & 0xFF
			return True
		return False

	def write_word(self, address: int, value: int) -> bool:
		"""Write a 16-bit word (little-endian) to ROM"""
		if self.rom_data and 0 <= address + 1 < len(self.rom_data):
			struct.pack_into('<H', self.rom_data, address, value & 0xFFFF)
			return True
		return False

	def write_bytes(self, address: int, data: bytes) -> bool:
		"""Write multiple bytes to ROM"""
		if self.rom_data and 0 <= address + len(data) <= len(self.rom_data):
			self.rom_data[address:address + len(data)] = data
			return True
		return False

	def read_map_header(self, map_id: int) -> Optional[dict]:
		"""Read map header from ROM"""
		if not self.rom_data or not (0 <= map_id < self.MAX_MAPS):
			return None

		address = self.MAP_HEADER_BASE + (map_id * self.HEADER_SIZE)

		header = {
			'map_id': map_id,
			'map_type': self.read_byte(address + 0),
			'width': self.read_byte(address + 2),
			'height': self.read_byte(address + 3),
			'tileset_id': self.read_byte(address + 6),
			'palette_id': self.read_byte(address + 7),
			'music_id': self.read_word(address + 8),
			'encounter_rate': self.read_byte(address + 10),
			'encounter_group': self.read_byte(address + 11),
			'spawn_x': self.read_word(address + 12),
			'spawn_y': self.read_word(address + 14),
			'flags': self.read_byte(address + 16),
		}

		return header

	def write_map_header(self, map_id: int, header: dict) -> bool:
		"""Write map header to ROM"""
		if not self.rom_data or not (0 <= map_id < self.MAX_MAPS):
			return False

		address = self.MAP_HEADER_BASE + (map_id * self.HEADER_SIZE)

		self.write_byte(address + 0, header.get('map_type', 0))
		self.write_byte(address + 2, header.get('width', 0))
		self.write_byte(address + 3, header.get('height', 0))
		self.write_byte(address + 6, header.get('tileset_id', 0))
		self.write_byte(address + 7, header.get('palette_id', 0))
		self.write_word(address + 8, header.get('music_id', 0))
		self.write_byte(address + 10, header.get('encounter_rate', 0))
		self.write_byte(address + 11, header.get('encounter_group', 0))
		self.write_word(address + 12, header.get('spawn_x', 0))
		self.write_word(address + 14, header.get('spawn_y', 0))
		self.write_byte(address + 16, header.get('flags', 0))

		return True

	def read_map_layer(self, map_id: int, layer: int,
					  width: int, height: int) -> Optional[np.ndarray]:
		"""
		Read map layer data from ROM

		Args:
			map_id: Map ID (0-127)
			layer: Layer number (0=BG1, 1=BG2, 2=BG3)
			width: Map width in tiles
			height: Map height in tiles

		Returns:
			numpy array of tile IDs (height x width)
		"""
		from .compression import FFMQCompression

		if self.rom_data is None:
			return None

		# Calculate expected decompressed size
		expected_size = width * height * 2  # 2 bytes per tile

		# Get map header to find layer data pointers
		header = self.read_map_header(map_id)
		if not header:
			return np.zeros((height, width), dtype=np.uint8)

		# Layer data pointers stored after main 32-byte header
		# Offset = base + (map_id * 44) + 32 + (layer * 4)
		# 44 = 32-byte header + 3 * 4-byte layer pointers
		layer_ptr_offset = self.MAP_DATA_BASE + (map_id * 44) + 32 + (layer * 4)
		layer_data_ptr = self.read_dword(layer_ptr_offset)

		if layer_data_ptr == 0 or layer_data_ptr == 0xFFFFFFFF:
			# No data for this layer
			return np.zeros((height, width), dtype=np.uint8)

		# Convert SNES address to PC address
		layer_data_address = self.snes_to_pc_address(layer_data_ptr)

		if layer_data_address < 0 or layer_data_address >= len(self.rom_data):
			return np.zeros((height, width), dtype=np.uint8)

		# Read compressed data
		# First 2 bytes store compressed data size
		compressed_size = self.read_word(layer_data_address)

		if compressed_size == 0 or compressed_size > 0x8000:
			# Invalid size
			return np.zeros((height, width), dtype=np.uint8)

		compressed_data = self.read_bytes(layer_data_address + 2, compressed_size)

		# Decompress
		try:
			decompressed = FFMQCompression.decompress_layer(compressed_data, expected_size)
		except Exception as e:
			print(f"Decompression error for map {map_id} layer {layer}: {e}")
			return np.zeros((height, width), dtype=np.uint8)

		# Convert to 2D array of tile IDs
		# Each tile is 2 bytes: [tile_id] [attributes]
		layer_array = np.zeros((height, width), dtype=np.uint8)
		for y in range(height):
			for x in range(width):
				offset = (y * width + x) * 2
				if offset < len(decompressed):
					layer_array[y, x] = decompressed[offset]

		return layer_array

	def write_map_layer(self, map_id: int, layer: int,
					   data: np.ndarray) -> bool:
		"""
		Write map layer data to ROM

		Args:
			map_id: Map ID (0-127)
			layer: Layer number (0=BG1, 1=BG2, 2=BG3)
			data: numpy array of tile IDs (height x width)

		Returns:
			True if successful, False otherwise
		"""
		from .compression import FFMQCompression

		if self.rom_data is None:
			return False

		height, width = data.shape

		# Convert 2D array to byte array
		# Each tile is 2 bytes: [tile_id] [attributes]
		# For simplicity, attributes set to 0
		uncompressed = bytearray()
		for y in range(height):
			for x in range(width):
				uncompressed.append(data[y, x])  # Tile ID
				uncompressed.append(0x00)         # Attributes

		# Compress
		try:
			compressed = FFMQCompression.compress_map(bytes(uncompressed))
		except Exception as e:
			print(f"Compression error for map {map_id} layer {layer}: {e}")
			return False

		# Get current layer data pointer
		layer_ptr_offset = self.MAP_DATA_BASE + (map_id * 44) + 32 + (layer * 4)
		current_ptr = self.read_dword(layer_ptr_offset)

		# For now, we'll need to allocate new space for compressed data
		# This is complex as it requires ROM expansion or finding free space
		# TODO: Implement proper ROM space allocation

		# Simple approach: write to end of ROM if there's space
		new_data_address = len(self.rom_data)

		# Check if we need to expand ROM
		required_space = len(compressed) + 2  # +2 for size word
		if new_data_address + required_space > len(self.rom_data):
			# Need to expand ROM - pad to next bank boundary
			new_size = ((new_data_address + required_space + 0x7FFF) // 0x8000) * 0x8000
			self.rom_data.extend(bytes(new_size - len(self.rom_data)))

		# Write compressed size
		self.write_word(new_data_address, len(compressed))

		# Write compressed data
		self.write_bytes(new_data_address + 2, compressed)

		# Update layer pointer to new location
		new_ptr = self.pc_to_snes_address(new_data_address)
		self.write_dword(layer_ptr_offset, new_ptr)

		return True

	def read_tileset_graphics(self, tileset_id: int) -> Optional[bytes]:
		"""
		Read tileset graphics from ROM

		Args:
			tileset_id: Tileset ID (0-15)

		Returns:
			Raw 4bpp tile data (32 bytes per 8x8 tile), or None on error
		"""
		if self.rom_data is None:
			return None

		if not (0 <= tileset_id < 16):
			return None

		# FFMQ tileset organization:
		# - Each tileset contains 256 tiles
		# - Each tile is 8x8 pixels
		# - 4bpp format (4 bits per pixel, 16 colors)
		# - 32 bytes per tile (4 bitplanes × 2 bytes per row × 8 rows)
		# - Total: 256 tiles × 32 bytes = 8KB per tileset

		tileset_size = 256 * 32  # 8192 bytes
		tileset_address = self.TILESET_BASE + (tileset_id * tileset_size)

		if tileset_address + tileset_size > len(self.rom_data):
			return None

		return self.read_bytes(tileset_address, tileset_size)

	def read_palette(self, palette_id: int) -> Optional[List[Tuple[int, int, int]]]:
		"""
		Read palette from ROM

		Args:
			palette_id: Palette ID (0-15)

		Returns:
			List of (R, G, B) tuples (0-255 range), or None on error
		"""
		from .tileset_manager import decode_snes_palette

		if self.rom_data is None:
			return None

		if not (0 <= palette_id < 16):
			return None

		# FFMQ palette organization:
		# - Each palette has 16 colors
		# - Each color is 2 bytes (15-bit SNES format)
		# - 16 colors × 2 bytes = 32 bytes per palette

		palette_size = 16 * 2  # 32 bytes
		palette_address = self.PALETTE_BASE + (palette_id * palette_size)

		if palette_address + palette_size > len(self.rom_data):
			return None

		palette_data = self.read_bytes(palette_address, palette_size)
		
		# Decode SNES 15-bit palette to RGB
		return decode_snes_palette(palette_data, 16)
	
	def snes_to_pc_address(self, snes_address: int) -> int:
		"""Convert SNES LoROM address to PC file offset"""
		# LoROM mapping: $00-7D:8000-FFFF → PC $0000-3EFFFF
		bank = (snes_address >> 16) & 0xFF
		offset = snes_address & 0xFFFF
		
		if offset < 0x8000:
			# Not mapped in LoROM
			return -1

		pc_address = (bank * 0x8000) + (offset - 0x8000)
		return pc_address

	def pc_to_snes_address(self, pc_address: int) -> int:
		"""Convert PC file offset to SNES LoROM address"""
		bank = pc_address // 0x8000
		offset = (pc_address % 0x8000) + 0x8000
		return (bank << 16) | offset
