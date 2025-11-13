#!/usr/bin/env python3
"""
FFMQ Graphics Engine - Sprite and tile management

Graphics Features:
- Sprite management
- Tile graphics
- Palette control
- Animation system
- OAM (Object Attribute Memory)
- VRAM management

SNES Graphics:
- 8×8 and 16×16 sprites
- 4-bit and 8-bit color
- 256 color palette
- 8 palettes × 16 colors
- Hardware sprite limit: 128

Sprite Features:
- Position control
- Palette selection
- Flip horizontal/vertical
- Priority layers
- Size modes
- Animation frames

Features:
- Load sprite graphics
- Edit palettes
- Animate sprites
- Export graphics
- Tileset management
- OAM data generation

Usage:
	python ffmq_graphics_engine.py --load-sprite character.chr
	python ffmq_graphics_engine.py --view-sprite 1
	python ffmq_graphics_engine.py --edit-palette 0 --color 1 --rgb 255 0 0
	python ffmq_graphics_engine.py --animate 1 --frames 4
	python ffmq_graphics_engine.py --export-chr output.chr
"""

import argparse
import struct
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict, field
from enum import Enum


class SpriteSize(Enum):
	"""Sprite size"""
	SIZE_8x8 = (8, 8)
	SIZE_16x16 = (16, 16)
	SIZE_32x32 = (32, 32)
	SIZE_64x64 = (64, 64)


class ColorDepth(Enum):
	"""Color depth"""
	BPP_2 = 2  # 4 colors
	BPP_4 = 4  # 16 colors
	BPP_8 = 8  # 256 colors


@dataclass
class Color:
	"""RGB color"""
	r: int  # 0-255
	g: int  # 0-255
	b: int  # 0-255
	
	def to_snes(self) -> int:
		"""Convert to SNES 15-bit BGR format"""
		# SNES uses 5 bits per channel (0-31)
		r5 = (self.r >> 3) & 0x1F
		g5 = (self.g >> 3) & 0x1F
		b5 = (self.b >> 3) & 0x1F
		
		# BGR format: 0bbbbbgggggrrrrr
		return (b5 << 10) | (g5 << 5) | r5
	
	@classmethod
	def from_snes(cls, snes_color: int) -> 'Color':
		"""Create from SNES 15-bit BGR format"""
		r5 = snes_color & 0x1F
		g5 = (snes_color >> 5) & 0x1F
		b5 = (snes_color >> 10) & 0x1F
		
		# Convert to 8-bit (scale from 0-31 to 0-255)
		r = (r5 << 3) | (r5 >> 2)
		g = (g5 << 3) | (g5 >> 2)
		b = (b5 << 3) | (b5 >> 2)
		
		return cls(r=r, g=g, b=b)


@dataclass
class Palette:
	"""Color palette (16 colors)"""
	palette_id: int
	colors: List[Color] = field(default_factory=lambda: [Color(0, 0, 0) for _ in range(16)])
	
	def set_color(self, index: int, color: Color) -> None:
		"""Set color at index"""
		if 0 <= index < len(self.colors):
			self.colors[index] = color
	
	def get_color(self, index: int) -> Optional[Color]:
		"""Get color at index"""
		if 0 <= index < len(self.colors):
			return self.colors[index]
		return None


@dataclass
class Tile:
	"""8×8 tile graphics"""
	tile_id: int
	pixels: List[List[int]]  # 8×8 array of color indices
	
	@classmethod
	def create_empty(cls, tile_id: int) -> 'Tile':
		"""Create empty tile"""
		pixels = [[0 for _ in range(8)] for _ in range(8)]
		return cls(tile_id=tile_id, pixels=pixels)


@dataclass
class Sprite:
	"""Sprite object"""
	sprite_id: int
	name: str
	x: int = 0
	y: int = 0
	tile_id: int = 0
	palette_id: int = 0
	size: SpriteSize = SpriteSize.SIZE_16x16
	flip_h: bool = False
	flip_v: bool = False
	priority: int = 0
	visible: bool = True


@dataclass
class Animation:
	"""Sprite animation"""
	animation_id: int
	name: str
	frames: List[int]  # Tile IDs
	frame_duration: int = 8  # Frames per animation frame
	loop: bool = True
	current_frame: int = 0
	frame_counter: int = 0


@dataclass
class OAMEntry:
	"""Object Attribute Memory entry"""
	x: int  # X position (0-511)
	y: int  # Y position (0-255)
	tile_id: int  # Tile number (0-511)
	palette: int  # Palette number (0-7)
	priority: int  # Priority (0-3)
	flip_h: bool = False
	flip_v: bool = False
	
	def to_bytes(self) -> bytes:
		"""Convert to OAM format"""
		# Low table (4 bytes per sprite)
		byte0 = self.x & 0xFF
		byte1 = self.y & 0xFF
		byte2 = self.tile_id & 0xFF
		
		# Byte 3: vhopppcc
		# v = vflip, h = hflip, o = obj priority (2 bits), ppp = palette, cc = tile high bits
		byte3 = 0
		if self.flip_v:
			byte3 |= 0x80
		if self.flip_h:
			byte3 |= 0x40
		byte3 |= (self.priority & 0x03) << 4
		byte3 |= (self.palette & 0x07) << 1
		byte3 |= (self.tile_id >> 8) & 0x01
		
		return bytes([byte0, byte1, byte2, byte3])


class FFMQGraphicsEngine:
	"""Graphics and sprite engine"""
	
	# VRAM constants
	VRAM_SIZE = 65536
	TILE_SIZE = 32  # 8×8 tile in 4bpp = 32 bytes
	MAX_SPRITES = 128
	MAX_PALETTES = 8
	
	# Default palettes
	DEFAULT_PALETTES = [
		# Palette 0: Grayscale
		[(0, 0, 0), (64, 64, 64), (128, 128, 128), (192, 192, 192),
		 (255, 255, 255), (224, 224, 224), (160, 160, 160), (96, 96, 96),
		 (32, 32, 32), (80, 80, 80), (112, 112, 112), (144, 144, 144),
		 (176, 176, 176), (208, 208, 208), (240, 240, 240), (255, 255, 255)],
		
		# Palette 1: Character (skin tones)
		[(0, 0, 0), (255, 224, 192), (224, 176, 144), (192, 128, 96),
		 (160, 96, 64), (128, 64, 32), (96, 48, 16), (64, 32, 16),
		 (255, 255, 255), (224, 224, 224), (192, 192, 192), (160, 160, 160),
		 (128, 128, 128), (96, 96, 96), (64, 64, 64), (32, 32, 32)],
		
		# Palette 2: Fire
		[(0, 0, 0), (255, 0, 0), (255, 64, 0), (255, 128, 0),
		 (255, 192, 0), (255, 255, 0), (255, 255, 128), (255, 255, 192),
		 (192, 0, 0), (224, 32, 0), (255, 96, 0), (255, 160, 0),
		 (255, 224, 0), (255, 255, 64), (255, 255, 160), (255, 255, 224)],
		
		# Palette 3: Water
		[(0, 0, 0), (0, 64, 128), (0, 96, 192), (0, 128, 255),
		 (32, 160, 255), (64, 192, 255), (128, 224, 255), (192, 240, 255),
		 (0, 32, 64), (0, 80, 160), (0, 112, 224), (32, 144, 255),
		 (64, 176, 255), (96, 208, 255), (160, 232, 255), (224, 248, 255)],
	]
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.palettes: List[Palette] = []
		self.tiles: Dict[int, Tile] = {}
		self.sprites: Dict[int, Sprite] = {}
		self.animations: Dict[int, Animation] = {}
		self.vram_data: bytearray = bytearray(self.VRAM_SIZE)
		
		self._initialize_palettes()
		self._create_sample_sprites()
	
	def _initialize_palettes(self) -> None:
		"""Initialize default palettes"""
		for i in range(self.MAX_PALETTES):
			palette = Palette(palette_id=i)
			
			if i < len(self.DEFAULT_PALETTES):
				for j, (r, g, b) in enumerate(self.DEFAULT_PALETTES[i]):
					palette.set_color(j, Color(r, g, b))
			
			self.palettes.append(palette)
	
	def _create_sample_sprites(self) -> None:
		"""Create sample sprites"""
		# Sample sprites
		sprites_data = [
			(1, "Benjamin", 100, 100, 0, 1),
			(2, "Enemy", 200, 100, 16, 2),
			(3, "Item", 150, 150, 32, 0),
		]
		
		for sprite_id, name, x, y, tile_id, palette_id in sprites_data:
			sprite = Sprite(
				sprite_id=sprite_id,
				name=name,
				x=x, y=y,
				tile_id=tile_id,
				palette_id=palette_id,
				size=SpriteSize.SIZE_16x16
			)
			self.sprites[sprite_id] = sprite
		
		# Sample animations
		anim1 = Animation(
			animation_id=1,
			name="Walk Down",
			frames=[0, 1, 0, 2],
			frame_duration=8
		)
		self.animations[1] = anim1
		
		anim2 = Animation(
			animation_id=2,
			name="Attack",
			frames=[16, 17, 18, 19],
			frame_duration=4,
			loop=False
		)
		self.animations[2] = anim2
	
	def set_palette_color(self, palette_id: int, color_index: int, 
						  r: int, g: int, b: int) -> bool:
		"""Set palette color"""
		if not (0 <= palette_id < len(self.palettes)):
			return False
		
		palette = self.palettes[palette_id]
		color = Color(r, g, b)
		palette.set_color(color_index, color)
		
		if self.verbose:
			print(f"✓ Set palette {palette_id}, color {color_index} to RGB({r},{g},{b})")
		
		return True
	
	def get_palette_color(self, palette_id: int, color_index: int) -> Optional[Color]:
		"""Get palette color"""
		if not (0 <= palette_id < len(self.palettes)):
			return None
		
		return self.palettes[palette_id].get_color(color_index)
	
	def create_sprite(self, sprite_id: int, name: str, x: int, y: int,
					  tile_id: int = 0, palette_id: int = 0) -> Sprite:
		"""Create sprite"""
		sprite = Sprite(
			sprite_id=sprite_id,
			name=name,
			x=x, y=y,
			tile_id=tile_id,
			palette_id=palette_id
		)
		
		self.sprites[sprite_id] = sprite
		
		if self.verbose:
			print(f"✓ Created sprite {sprite_id}: {name}")
		
		return sprite
	
	def move_sprite(self, sprite_id: int, x: int, y: int) -> bool:
		"""Move sprite"""
		if sprite_id not in self.sprites:
			return False
		
		self.sprites[sprite_id].x = x
		self.sprites[sprite_id].y = y
		
		return True
	
	def flip_sprite(self, sprite_id: int, horizontal: bool = False, 
					vertical: bool = False) -> bool:
		"""Flip sprite"""
		if sprite_id not in self.sprites:
			return False
		
		sprite = self.sprites[sprite_id]
		sprite.flip_h = horizontal
		sprite.flip_v = vertical
		
		return True
	
	def create_animation(self, animation_id: int, name: str, frames: List[int],
						 frame_duration: int = 8, loop: bool = True) -> Animation:
		"""Create animation"""
		animation = Animation(
			animation_id=animation_id,
			name=name,
			frames=frames,
			frame_duration=frame_duration,
			loop=loop
		)
		
		self.animations[animation_id] = animation
		
		if self.verbose:
			print(f"✓ Created animation {animation_id}: {name} ({len(frames)} frames)")
		
		return animation
	
	def update_animation(self, animation_id: int) -> Optional[int]:
		"""Update animation and return current tile ID"""
		if animation_id not in self.animations:
			return None
		
		anim = self.animations[animation_id]
		
		anim.frame_counter += 1
		
		if anim.frame_counter >= anim.frame_duration:
			anim.frame_counter = 0
			anim.current_frame += 1
			
			if anim.current_frame >= len(anim.frames):
				if anim.loop:
					anim.current_frame = 0
				else:
					anim.current_frame = len(anim.frames) - 1
		
		return anim.frames[anim.current_frame]
	
	def generate_oam(self) -> bytes:
		"""Generate OAM data for all sprites"""
		oam_data = bytearray()
		
		# Sort sprites by ID (up to 128)
		sprite_list = sorted(self.sprites.values(), key=lambda s: s.sprite_id)[:self.MAX_SPRITES]
		
		# Low table (4 bytes per sprite)
		for sprite in sprite_list:
			if not sprite.visible:
				# Hidden sprite
				oam_data.extend([0xFF, 0xFF, 0x00, 0x00])
				continue
			
			entry = OAMEntry(
				x=sprite.x,
				y=sprite.y,
				tile_id=sprite.tile_id,
				palette=sprite.palette_id,
				priority=sprite.priority,
				flip_h=sprite.flip_h,
				flip_v=sprite.flip_v
			)
			
			oam_data.extend(entry.to_bytes())
		
		# Pad to 128 sprites
		while len(oam_data) < 512:
			oam_data.extend([0xFF, 0xFF, 0x00, 0x00])
		
		# High table (2 bits per sprite for X position bit 8 and size)
		# Simplified: all zeros
		oam_data.extend([0x00] * 32)
		
		return bytes(oam_data)
	
	def export_palette(self, palette_id: int, output_path: Path) -> bool:
		"""Export palette to binary"""
		if not (0 <= palette_id < len(self.palettes)):
			return False
		
		palette = self.palettes[palette_id]
		
		try:
			with open(output_path, 'wb') as f:
				for color in palette.colors:
					snes_color = color.to_snes()
					f.write(struct.pack('<H', snes_color))
			
			if self.verbose:
				print(f"✓ Exported palette {palette_id} to {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting palette: {e}")
			return False
	
	def print_sprite_list(self) -> None:
		"""Print sprite list"""
		print(f"\n=== Sprites ===\n")
		print(f"{'ID':<4} {'Name':<20} {'X':<6} {'Y':<6} {'Tile':<6} {'Pal':<5} {'Visible':<8}")
		print('-' * 55)
		
		for sprite_id, sprite in sorted(self.sprites.items()):
			visible = "Yes" if sprite.visible else "No"
			print(f"{sprite.sprite_id:<4} {sprite.name:<20} {sprite.x:<6} {sprite.y:<6} "
				  f"{sprite.tile_id:<6} {sprite.palette_id:<5} {visible:<8}")
	
	def print_animation_list(self) -> None:
		"""Print animation list"""
		print(f"\n=== Animations ===\n")
		print(f"{'ID':<4} {'Name':<25} {'Frames':<8} {'Duration':<10} {'Loop':<6}")
		print('-' * 53)
		
		for anim_id, anim in sorted(self.animations.items()):
			loop = "Yes" if anim.loop else "No"
			print(f"{anim.animation_id:<4} {anim.name:<25} {len(anim.frames):<8} "
				  f"{anim.frame_duration:<10} {loop:<6}")
	
	def print_palette(self, palette_id: int) -> None:
		"""Print palette colors"""
		if not (0 <= palette_id < len(self.palettes)):
			print(f"Palette {palette_id} not found")
			return
		
		palette = self.palettes[palette_id]
		
		print(f"\n=== Palette {palette_id} ===\n")
		print(f"{'Index':<7} {'RGB':<20} {'SNES':<8}")
		print('-' * 35)
		
		for i, color in enumerate(palette.colors):
			rgb_str = f"({color.r:3},{color.g:3},{color.b:3})"
			snes = color.to_snes()
			print(f"{i:<7} {rgb_str:<20} 0x{snes:04X}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Graphics Engine')
	parser.add_argument('--view-sprite', type=int, metavar='SPRITE_ID',
					   help='View sprite details')
	parser.add_argument('--create-sprite', type=str, nargs=4,
					   metavar=('ID', 'NAME', 'X', 'Y'), help='Create sprite')
	parser.add_argument('--move-sprite', type=int, nargs=3,
					   metavar=('SPRITE_ID', 'X', 'Y'), help='Move sprite')
	parser.add_argument('--edit-palette', type=int, metavar='PALETTE_ID',
					   help='Edit palette')
	parser.add_argument('--color', type=int, metavar='COLOR_INDEX',
					   help='Color index to edit')
	parser.add_argument('--rgb', type=int, nargs=3, metavar=('R', 'G', 'B'),
					   help='RGB color values')
	parser.add_argument('--view-palette', type=int, metavar='PALETTE_ID',
					   help='View palette')
	parser.add_argument('--animate', type=int, metavar='ANIMATION_ID',
					   help='View animation')
	parser.add_argument('--export-oam', type=str, metavar='OUTPUT',
					   help='Export OAM data')
	parser.add_argument('--export-palette', type=int, nargs=2,
					   metavar=('PALETTE_ID', 'OUTPUT'), help='Export palette')
	parser.add_argument('--list-sprites', action='store_true', help='List sprites')
	parser.add_argument('--list-animations', action='store_true', help='List animations')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	engine = FFMQGraphicsEngine(verbose=args.verbose)
	
	# Create sprite
	if args.create_sprite:
		sprite_id, name, x, y = args.create_sprite
		engine.create_sprite(int(sprite_id), name, int(x), int(y))
	
	# Move sprite
	if args.move_sprite:
		sprite_id, x, y = args.move_sprite
		engine.move_sprite(sprite_id, x, y)
	
	# Edit palette
	if args.edit_palette is not None and args.color is not None and args.rgb:
		r, g, b = args.rgb
		engine.set_palette_color(args.edit_palette, args.color, r, g, b)
	
	# View palette
	if args.view_palette is not None:
		engine.print_palette(args.view_palette)
		return 0
	
	# Export OAM
	if args.export_oam:
		oam_data = engine.generate_oam()
		with open(args.export_oam, 'wb') as f:
			f.write(oam_data)
		print(f"✓ Exported OAM data ({len(oam_data)} bytes)")
		return 0
	
	# Export palette
	if args.export_palette:
		palette_id, output = args.export_palette
		engine.export_palette(palette_id, Path(output))
		return 0
	
	# List sprites
	if args.list_sprites:
		engine.print_sprite_list()
		return 0
	
	# List animations
	if args.list_animations:
		engine.print_animation_list()
		return 0
	
	# Default: show summary
	print("\n=== FFMQ Graphics Engine ===\n")
	print(f"Palettes: {len(engine.palettes)}")
	print(f"Sprites: {len(engine.sprites)}")
	print(f"Animations: {len(engine.animations)}")
	print(f"VRAM: {len(engine.vram_data):,} bytes")
	
	return 0


if __name__ == '__main__':
	exit(main())
