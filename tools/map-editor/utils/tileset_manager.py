#!/usr/bin/env python3
"""
Tileset manager for FFMQ Map Editor
Handles loading, caching, and rendering tilesets
"""

import pygame
from pathlib import Path
from typing import Optional, Tuple, Dict
import struct

class TilesetManager:
	"""Manages tileset graphics and rendering"""
	
	def __init__(self, cache_dir: str = 'data/tilesets'):
		"""Initialize tileset manager"""
		self.cache_dir = Path(cache_dir)
		self.cache_dir.mkdir(parents=True, exist_ok=True)
		
		# Loaded tilesets: {tileset_id: pygame.Surface}
		self.tilesets: Dict[int, pygame.Surface] = {}
		
		# Current tileset
		self.current_tileset_id: Optional[int] = None
		self.current_tileset: Optional[pygame.Surface] = None
		
		# Tile dimensions
		self.tile_width = 8   # SNES tile width in pixels
		self.tile_height = 8  # SNES tile height in pixels
		self.tiles_per_row = 16  # Standard SNES tileset organization
	
	def load_tileset(self, tileset_id: int, 
					tile_data: Optional[bytes] = None,
					palette: Optional[list] = None) -> bool:
		"""
		Load a tileset from raw tile data
		
		Args:
			tileset_id: Tileset ID
			tile_data: Raw 4bpp SNES tile data (16 bytes per tile)
			palette: List of (R,G,B) color tuples
		
		Returns:
			True if successful, False otherwise
		"""
		if tileset_id in self.tilesets:
			# Already loaded
			self.current_tileset_id = tileset_id
			self.current_tileset = self.tilesets[tileset_id]
			return True
		
		# If no tile data provided, generate placeholder tileset
		if tile_data is None or palette is None:
			tileset_surface = self._generate_placeholder_tileset(tileset_id)
		else:
			tileset_surface = self._decode_tileset(tile_data, palette)
		
		if tileset_surface:
			self.tilesets[tileset_id] = tileset_surface
			self.current_tileset_id = tileset_id
			self.current_tileset = tileset_surface
			return True
		
		return False
	
	def get_tile_surface(self, tile_id: int, 
						size: Optional[Tuple[int, int]] = None) -> Optional[pygame.Surface]:
		"""
		Get a pygame surface for a specific tile
		
		Args:
			tile_id: Tile ID (0-255)
			size: Optional (width, height) to scale tile
		
		Returns:
			pygame.Surface containing the tile, or None
		"""
		if self.current_tileset is None:
			return None
		
		if not (0 <= tile_id < 256):
			return None
		
		# Calculate tile position in tileset
		tile_x = (tile_id % self.tiles_per_row) * self.tile_width
		tile_y = (tile_id // self.tiles_per_row) * self.tile_height
		
		# Extract tile from tileset
		tile_surface = pygame.Surface((self.tile_width, self.tile_height))
		tile_surface.blit(self.current_tileset, (0, 0),
						 (tile_x, tile_y, self.tile_width, self.tile_height))
		
		# Scale if requested
		if size:
			tile_surface = pygame.transform.scale(tile_surface, size)
		
		return tile_surface
	
	def _generate_placeholder_tileset(self, tileset_id: int) -> pygame.Surface:
		"""Generate a placeholder tileset with colored tiles"""
		# Create surface for 256 tiles (16x16 grid)
		width = self.tiles_per_row * self.tile_width
		height = 16 * self.tile_height
		surface = pygame.Surface((width, height))
		
		for tile_id in range(256):
			# Calculate position
			tile_x = (tile_id % self.tiles_per_row) * self.tile_width
			tile_y = (tile_id // self.tiles_per_row) * self.tile_height
			
			# Generate color based on tile ID
			if tile_id == 0:
				color = (30, 30, 30)  # Empty tile
			else:
				r = (tile_id * 37 + tileset_id * 13) % 256
				g = (tile_id * 73 + tileset_id * 29) % 256
				b = (tile_id * 109 + tileset_id * 47) % 256
				color = (r, g, b)
			
			# Fill tile
			pygame.draw.rect(surface, color,
						   (tile_x, tile_y, self.tile_width, self.tile_height))
			
			# Draw border
			pygame.draw.rect(surface, (50, 50, 50),
						   (tile_x, tile_y, self.tile_width, self.tile_height), 1)
		
		return surface
	
	def _decode_tileset(self, tile_data: bytes, palette: list) -> pygame.Surface:
		"""
		Decode SNES 4bpp tile data to pygame surface
		
		SNES 4bpp format:
		- 4 bits per pixel (16 colors)
		- 8x8 pixels per tile
		- 32 bytes per tile (4 bitplanes × 2 bytes per row × 8 rows)
		- Bitplanes are interleaved (plane 0-1, then plane 2-3)
		"""
		num_tiles = len(tile_data) // 32
		width = self.tiles_per_row * self.tile_width
		height = ((num_tiles + self.tiles_per_row - 1) // 
				 self.tiles_per_row) * self.tile_height
		
		surface = pygame.Surface((width, height))
		
		for tile_id in range(num_tiles):
			tile_offset = tile_id * 32
			tile_x = (tile_id % self.tiles_per_row) * self.tile_width
			tile_y = (tile_id // self.tiles_per_row) * self.tile_height
			
			# Decode tile
			for y in range(8):
				# Get bitplane data for this row
				bp0 = tile_data[tile_offset + y * 2]
				bp1 = tile_data[tile_offset + y * 2 + 1]
				bp2 = tile_data[tile_offset + 16 + y * 2]
				bp3 = tile_data[tile_offset + 16 + y * 2 + 1]
				
				for x in range(8):
					# Extract bit from each bitplane
					bit = 7 - x
					pixel = (
						((bp0 >> bit) & 1) |
						(((bp1 >> bit) & 1) << 1) |
						(((bp2 >> bit) & 1) << 2) |
						(((bp3 >> bit) & 1) << 3)
					)
					
					# Get color from palette
					if pixel < len(palette):
						color = palette[pixel]
					else:
						color = (255, 0, 255)  # Magenta for errors
					
					# Set pixel
					surface.set_at((tile_x + x, tile_y + y), color)
		
		return surface
	
	def save_tileset_cache(self, tileset_id: int) -> bool:
		"""Save tileset to cache as PNG"""
		if tileset_id not in self.tilesets:
			return False
		
		try:
			cache_file = self.cache_dir / f'tileset_{tileset_id:02X}.png'
			pygame.image.save(self.tilesets[tileset_id], str(cache_file))
			return True
		except Exception as e:
			print(f"Error saving tileset cache: {e}")
			return False
	
	def load_tileset_cache(self, tileset_id: int) -> bool:
		"""Load tileset from cache PNG"""
		cache_file = self.cache_dir / f'tileset_{tileset_id:02X}.png'
		
		if not cache_file.exists():
			return False
		
		try:
			tileset_surface = pygame.image.load(str(cache_file))
			self.tilesets[tileset_id] = tileset_surface
			self.current_tileset_id = tileset_id
			self.current_tileset = tileset_surface
			return True
		except Exception as e:
			print(f"Error loading tileset cache: {e}")
			return False


def decode_snes_palette(palette_data: bytes, num_colors: int = 16) -> list:
	"""
	Decode SNES 15-bit palette to RGB
	
	SNES palette format:
	- 2 bytes per color (little-endian)
	- 5 bits per channel (BGR order)
	- Format: -bbbbbgggggrrrrr
	"""
	palette = []
	
	for i in range(num_colors):
		if i * 2 + 1 >= len(palette_data):
			break
		
		# Read 16-bit color value (little-endian)
		color_value = struct.unpack_from('<H', palette_data, i * 2)[0]
		
		# Extract 5-bit channels
		r5 = (color_value >> 0) & 0x1F
		g5 = (color_value >> 5) & 0x1F
		b5 = (color_value >> 10) & 0x1F
		
		# Convert to 8-bit (scale 0-31 to 0-255)
		r8 = (r5 * 255) // 31
		g8 = (g5 * 255) // 31
		b8 = (b5 * 255) // 31
		
		palette.append((r8, g8, b8))
	
	return palette
