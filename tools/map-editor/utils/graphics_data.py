"""
FFMQ Graphics Data Structures

Handles sprite, tileset, palette, and animation data for the game.
Supports 4bpp SNES graphics format.
"""

from dataclasses import dataclass, field
from typing import List, Tuple, Optional
from enum import IntEnum, IntFlag
import struct


class SpriteSize(IntEnum):
	"""Sprite size options"""
	SIZE_8x8 = 0
	SIZE_16x16 = 1
	SIZE_24x24 = 2
	SIZE_32x32 = 3
	SIZE_16x32 = 4
	SIZE_32x64 = 5


class PaletteType(IntEnum):
	"""Palette types"""
	SPRITE = 0
	BACKGROUND = 1
	ENEMY = 2
	CHARACTER = 3
	UI = 4


class AnimationType(IntEnum):
	"""Animation types"""
	IDLE = 0
	WALK = 1
	ATTACK = 2
	HURT = 3
	DEATH = 4
	SPECIAL = 5


@dataclass
class Color:
	"""SNES 15-bit color (BGR555)"""
	red: int  # 0-31
	green: int  # 0-31
	blue: int  # 0-31

	def to_rgb888(self) -> Tuple[int, int, int]:
		"""Convert to 24-bit RGB"""
		r = (self.red * 255) // 31
		g = (self.green * 255) // 31
		b = (self.blue * 255) // 31
		return (r, g, b)

	def to_bgr555(self) -> int:
		"""Convert to 15-bit BGR555"""
		return self.blue | (self.green << 5) | (self.red << 10)

	@staticmethod
	def from_bgr555(value: int) -> 'Color':
		"""Create from 15-bit BGR555"""
		blue = value & 0x1F
		green = (value >> 5) & 0x1F
		red = (value >> 10) & 0x1F
		return Color(red, green, blue)

	@staticmethod
	def from_rgb888(r: int, g: int, b: int) -> 'Color':
		"""Create from 24-bit RGB"""
		red = (r * 31) // 255
		green = (g * 31) // 255
		blue = (b * 31) // 255
		return Color(red, green, blue)

	def __str__(self) -> str:
		r, g, b = self.to_rgb888()
		return f"RGB({r}, {g}, {b})"


@dataclass
class Palette:
	"""16-color palette"""
	palette_id: int
	palette_type: PaletteType
	colors: List[Color] = field(default_factory=lambda: [Color(0, 0, 0)] * 16)
	name: str = ""

	def to_bytes(self) -> bytes:
		"""Convert to 32 bytes (16 colors × 2 bytes)"""
		data = bytearray(32)
		for i, color in enumerate(self.colors[:16]):
			value = color.to_bgr555()
			struct.pack_into('<H', data, i * 2, value)
		return bytes(data)

	@staticmethod
	def from_bytes(data: bytes, palette_id: int) -> 'Palette':
		"""Create from byte data"""
		if len(data) < 32:
			raise ValueError(f"Palette data must be at least 32 bytes, got {len(data)}")

		colors = []
		for i in range(16):
			value = struct.unpack_from('<H', data, i * 2)[0]
			colors.append(Color.from_bgr555(value))

		return Palette(
			palette_id=palette_id,
			palette_type=PaletteType.SPRITE,
			colors=colors
		)

	def get_color(self, index: int) -> Color:
		"""Get color at index"""
		if 0 <= index < len(self.colors):
			return self.colors[index]
		return Color(0, 0, 0)

	def set_color(self, index: int, color: Color):
		"""Set color at index"""
		if 0 <= index < 16:
			self.colors[index] = color


@dataclass
class Tile:
	"""8x8 tile (4bpp = 32 bytes)"""
	tile_id: int
	pixels: List[int] = field(default_factory=lambda: [0] * 64)  # 8x8 pixels, 4-bit each

	def to_bytes(self) -> bytes:
		"""Convert to 32 bytes (4bpp planar format)"""
		data = bytearray(32)

		# SNES uses planar format: 4 bitplanes
		for y in range(8):
			for plane in range(4):
				byte_val = 0
				for x in range(8):
					pixel = self.pixels[y * 8 + x]
					bit = (pixel >> plane) & 1
					byte_val |= bit << (7 - x)
				data[y * 4 + plane] = byte_val

		return bytes(data)

	@staticmethod
	def from_bytes(data: bytes, tile_id: int) -> 'Tile':
		"""Create from byte data (4bpp planar)"""
		if len(data) < 32:
			raise ValueError(f"Tile data must be at least 32 bytes, got {len(data)}")

		pixels = [0] * 64

		# Decode planar format
		for y in range(8):
			for x in range(8):
				pixel = 0
				for plane in range(4):
					byte_val = data[y * 4 + plane]
					bit = (byte_val >> (7 - x)) & 1
					pixel |= bit << plane
				pixels[y * 8 + x] = pixel

		return Tile(tile_id=tile_id, pixels=pixels)

	def get_pixel(self, x: int, y: int) -> int:
		"""Get pixel value at (x, y)"""
		if 0 <= x < 8 and 0 <= y < 8:
			return self.pixels[y * 8 + x]
		return 0

	def set_pixel(self, x: int, y: int, value: int):
		"""Set pixel value at (x, y)"""
		if 0 <= x < 8 and 0 <= y < 8 and 0 <= value < 16:
			self.pixels[y * 8 + x] = value

	def flip_horizontal(self):
		"""Flip tile horizontally"""
		new_pixels = [0] * 64
		for y in range(8):
			for x in range(8):
				new_pixels[y * 8 + x] = self.pixels[y * 8 + (7 - x)]
		self.pixels = new_pixels

	def flip_vertical(self):
		"""Flip tile vertically"""
		new_pixels = [0] * 64
		for y in range(8):
			for x in range(8):
				new_pixels[y * 8 + x] = self.pixels[(7 - y) * 8 + x]
		self.pixels = new_pixels


@dataclass
class Sprite:
	"""Sprite composed of multiple tiles"""
	sprite_id: int
	size: SpriteSize
	tiles: List[int] = field(default_factory=list)  # Tile IDs
	palette_id: int = 0
	name: str = ""

	def get_dimensions(self) -> Tuple[int, int]:
		"""Get sprite dimensions in pixels"""
		size_map = {
			SpriteSize.SIZE_8x8: (8, 8),
			SpriteSize.SIZE_16x16: (16, 16),
			SpriteSize.SIZE_24x24: (24, 24),
			SpriteSize.SIZE_32x32: (32, 32),
			SpriteSize.SIZE_16x32: (16, 32),
			SpriteSize.SIZE_32x64: (32, 64),
		}
		return size_map.get(self.size, (16, 16))

	def get_tile_count(self) -> int:
		"""Get number of tiles needed"""
		w, h = self.get_dimensions()
		return (w // 8) * (h // 8)


@dataclass
class AnimationFrame:
	"""Single animation frame"""
	sprite_id: int
	duration: int  # In frames (60fps)
	offset_x: int = 0
	offset_y: int = 0


@dataclass
class Animation:
	"""Sprite animation sequence"""
	animation_id: int
	animation_type: AnimationType
	frames: List[AnimationFrame] = field(default_factory=list)
	loop: bool = True
	name: str = ""

	def get_total_duration(self) -> int:
		"""Get total animation duration in frames"""
		return sum(frame.duration for frame in self.frames)

	def add_frame(self, sprite_id: int, duration: int = 10, offset_x: int = 0, offset_y: int = 0):
		"""Add frame to animation"""
		self.frames.append(AnimationFrame(sprite_id, duration, offset_x, offset_y))


@dataclass
class Tileset:
	"""Collection of tiles"""
	tileset_id: int
	tiles: List[Tile] = field(default_factory=list)
	palette: Optional[Palette] = None
	name: str = ""

	def add_tile(self, tile: Tile):
		"""Add tile to tileset"""
		self.tiles.append(tile)

	def get_tile(self, tile_id: int) -> Optional[Tile]:
		"""Get tile by ID"""
		for tile in self.tiles:
			if tile.tile_id == tile_id:
				return tile
		return None

	def to_bytes(self) -> bytes:
		"""Convert all tiles to bytes"""
		data = bytearray()
		for tile in self.tiles:
			data.extend(tile.to_bytes())
		return bytes(data)

	@staticmethod
	def from_bytes(data: bytes, tileset_id: int, tile_count: int) -> 'Tileset':
		"""Create tileset from bytes"""
		if len(data) < tile_count * 32:
			raise ValueError(f"Not enough data for {tile_count} tiles")

		tiles = []
		for i in range(tile_count):
			tile_data = data[i * 32:(i + 1) * 32]
			tiles.append(Tile.from_bytes(tile_data, i))

		return Tileset(tileset_id=tileset_id, tiles=tiles)


@dataclass
class SpriteSheet:
	"""Collection of sprites using a tileset"""
	sheet_id: int
	tileset: Tileset
	sprites: List[Sprite] = field(default_factory=list)
	palettes: List[Palette] = field(default_factory=list)
	animations: List[Animation] = field(default_factory=list)
	name: str = ""

	def add_sprite(self, sprite: Sprite):
		"""Add sprite to sheet"""
		self.sprites.append(sprite)

	def add_palette(self, palette: Palette):
		"""Add palette to sheet"""
		self.palettes.append(palette)

	def add_animation(self, animation: Animation):
		"""Add animation to sheet"""
		self.animations.append(animation)

	def get_sprite(self, sprite_id: int) -> Optional[Sprite]:
		"""Get sprite by ID"""
		for sprite in self.sprites:
			if sprite.sprite_id == sprite_id:
				return sprite
		return None

	def get_palette(self, palette_id: int) -> Optional[Palette]:
		"""Get palette by ID"""
		for palette in self.palettes:
			if palette.palette_id == palette_id:
				return palette
		return None


# ROM addresses for graphics data
TILESET_BASE = 0x080000  # Base address for tilesets
PALETTE_BASE = 0x0C0000  # Base address for palettes
SPRITE_BASE = 0x0A0000   # Base address for sprite definitions

# Common palette indices
TRANSPARENT = 0
PALETTE_SIZE = 16


def create_gradient_palette(start_color: Color, end_color: Color, steps: int = 16) -> Palette:
	"""Create gradient palette between two colors"""
	palette = Palette(palette_id=0, palette_type=PaletteType.SPRITE)

	for i in range(min(steps, 16)):
		t = i / max(steps - 1, 1)
		r = int(start_color.red + (end_color.red - start_color.red) * t)
		g = int(start_color.green + (end_color.green - start_color.green) * t)
		b = int(start_color.blue + (end_color.blue - start_color.blue) * t)
		palette.colors[i] = Color(r, g, b)

	return palette


def create_blank_tile() -> Tile:
	"""Create blank tile"""
	return Tile(tile_id=0, pixels=[0] * 64)


def create_solid_tile(color_index: int) -> Tile:
	"""Create solid color tile"""
	return Tile(tile_id=0, pixels=[color_index] * 64)
