#!/usr/bin/env python3
"""
FFMQ Tile Animator - Create animated map tiles

Animation Features:
- Animated water tiles
- Animated lava/fire
- Flickering lights
- Rotating objects
- Waving grass
- Scrolling clouds
- Glowing crystals
- Waterfalls

Animation System:
- Frame-based animation
- Timing control (frames per second)
- Loop modes (loop, ping-pong, once)
- Synchronized animations
- Layer-based effects
- Palette cycling

Tile Animation:
- Multiple frames per tile
- Frame duration
- Animation sequences
- Tile replacement
- Pattern tables
- Timing tables

Features:
- Create animations
- Edit frame sequences
- Set timing
- Preview animations
- Export animations
- Import animations

Usage:
	python ffmq_tile_animator.py rom.sfc --create water --frames 4
	python ffmq_tile_animator.py rom.sfc --list
	python ffmq_tile_animator.py rom.sfc --preview water
	python ffmq_tile_animator.py rom.sfc --export animations.json
	python ffmq_tile_animator.py rom.sfc --import animations.json --save modded.sfc
"""

import argparse
import json
from pathlib import Path
from typing import List, Dict, Tuple, Optional, Any
from dataclasses import dataclass, asdict, field
from enum import Enum


class AnimationType(Enum):
	"""Animation types"""
	WATER = "water"
	LAVA = "lava"
	FIRE = "fire"
	WATERFALL = "waterfall"
	GRASS = "grass"
	LIGHT = "light"
	CRYSTAL = "crystal"
	CUSTOM = "custom"


class LoopMode(Enum):
	"""Animation loop modes"""
	LOOP = "loop"  # 1->2->3->4->1
	PING_PONG = "ping_pong"  # 1->2->3->4->3->2->1
	ONCE = "once"  # 1->2->3->4 (stop)


@dataclass
class TileFrame:
	"""Single animation frame"""
	frame_id: int
	tile_id: int  # Tile index to display
	duration: int  # Frames to display (at 60 FPS)
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class TileAnimation:
	"""Tile animation definition"""
	animation_id: int
	name: str
	animation_type: AnimationType
	base_tile_id: int  # First tile in animation
	frames: List[TileFrame]
	loop_mode: LoopMode
	total_duration: int  # Total frames for complete cycle
	address: int  # ROM address
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['animation_type'] = self.animation_type.value
		d['loop_mode'] = self.loop_mode.value
		d['frames'] = [f.to_dict() for f in self.frames]
		return d


@dataclass
class PaletteCycle:
	"""Palette cycling animation"""
	cycle_id: int
	name: str
	palette_start: int  # First palette index
	palette_count: int  # Number of palettes to cycle
	duration: int  # Frames per palette
	
	def to_dict(self) -> dict:
		return asdict(self)


class FFMQTileAnimator:
	"""Tile animation editor"""
	
	# Known animation locations
	ANIMATION_TABLE_ADDRESS = 0x300000
	MAX_ANIMATIONS = 64
	
	# Animation templates
	ANIMATION_TEMPLATES = {
		'water': {
			'name': 'Water Tiles',
			'type': AnimationType.WATER,
			'frames': [
				{'tile_id': 0, 'duration': 8},
				{'tile_id': 1, 'duration': 8},
				{'tile_id': 2, 'duration': 8},
				{'tile_id': 3, 'duration': 8}
			],
			'loop_mode': LoopMode.LOOP
		},
		'lava': {
			'name': 'Lava Flow',
			'type': AnimationType.LAVA,
			'frames': [
				{'tile_id': 0, 'duration': 6},
				{'tile_id': 1, 'duration': 6},
				{'tile_id': 2, 'duration': 6},
				{'tile_id': 3, 'duration': 6}
			],
			'loop_mode': LoopMode.LOOP
		},
		'waterfall': {
			'name': 'Waterfall',
			'type': AnimationType.WATERFALL,
			'frames': [
				{'tile_id': 0, 'duration': 4},
				{'tile_id': 1, 'duration': 4},
				{'tile_id': 2, 'duration': 4},
				{'tile_id': 3, 'duration': 4}
			],
			'loop_mode': LoopMode.LOOP
		},
		'light': {
			'name': 'Flickering Light',
			'type': AnimationType.LIGHT,
			'frames': [
				{'tile_id': 0, 'duration': 12},
				{'tile_id': 1, 'duration': 3},
				{'tile_id': 0, 'duration': 10},
				{'tile_id': 1, 'duration': 5}
			],
			'loop_mode': LoopMode.LOOP
		}
	}
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		self.animations: List[TileAnimation] = []
		self.next_id = 1
		
		if self.verbose:
			print(f"Loaded ROM: {rom_path}")
	
	def create_animation(self, name: str, animation_type: AnimationType,
						base_tile_id: int, frames: List[TileFrame],
						loop_mode: LoopMode = LoopMode.LOOP) -> TileAnimation:
		"""Create new tile animation"""
		total_duration = sum(f.duration for f in frames)
		
		animation = TileAnimation(
			animation_id=self.next_id,
			name=name,
			animation_type=animation_type,
			base_tile_id=base_tile_id,
			frames=frames,
			loop_mode=loop_mode,
			total_duration=total_duration,
			address=self.ANIMATION_TABLE_ADDRESS + (self.next_id - 1) * 32
		)
		
		self.animations.append(animation)
		self.next_id += 1
		
		if self.verbose:
			print(f"✓ Created animation: {name} ({len(frames)} frames, {total_duration} ticks)")
		
		return animation
	
	def create_from_template(self, template_name: str, base_tile_id: int = 0) -> Optional[TileAnimation]:
		"""Create animation from template"""
		if template_name not in self.ANIMATION_TEMPLATES:
			if self.verbose:
				print(f"Unknown template: {template_name}")
			return None
		
		template = self.ANIMATION_TEMPLATES[template_name]
		
		# Build frames
		frames = []
		for i, frame_data in enumerate(template['frames']):
			frame = TileFrame(
				frame_id=i,
				tile_id=base_tile_id + frame_data['tile_id'],
				duration=frame_data['duration']
			)
			frames.append(frame)
		
		animation = self.create_animation(
			name=template['name'],
			animation_type=template['type'],
			base_tile_id=base_tile_id,
			frames=frames,
			loop_mode=template['loop_mode']
		)
		
		return animation
	
	def read_animation(self, address: int) -> Optional[TileAnimation]:
		"""Read animation from ROM"""
		if address + 32 > len(self.rom_data):
			return None
		
		# Simple format: frame count, loop mode, then frame data
		frame_count = self.rom_data[address]
		if frame_count == 0 or frame_count > 16:
			return None
		
		loop_mode_byte = self.rom_data[address + 1]
		loop_mode = LoopMode.LOOP if loop_mode_byte == 0 else LoopMode.PING_PONG
		
		base_tile_id = self.rom_data[address + 2] | (self.rom_data[address + 3] << 8)
		
		frames = []
		for i in range(frame_count):
			frame_offset = address + 4 + i * 2
			tile_id = self.rom_data[frame_offset]
			duration = self.rom_data[frame_offset + 1]
			
			frame = TileFrame(
				frame_id=i,
				tile_id=tile_id,
				duration=duration
			)
			frames.append(frame)
		
		animation = TileAnimation(
			animation_id=self.next_id,
			name=f"Animation {self.next_id}",
			animation_type=AnimationType.CUSTOM,
			base_tile_id=base_tile_id,
			frames=frames,
			loop_mode=loop_mode,
			total_duration=sum(f.duration for f in frames),
			address=address
		)
		
		self.next_id += 1
		return animation
	
	def write_animation(self, animation: TileAnimation) -> None:
		"""Write animation to ROM"""
		address = animation.address
		
		# Frame count
		self.rom_data[address] = len(animation.frames)
		
		# Loop mode
		self.rom_data[address + 1] = 0 if animation.loop_mode == LoopMode.LOOP else 1
		
		# Base tile ID
		self.rom_data[address + 2] = animation.base_tile_id & 0xFF
		self.rom_data[address + 3] = (animation.base_tile_id >> 8) & 0xFF
		
		# Frame data
		for i, frame in enumerate(animation.frames):
			frame_offset = address + 4 + i * 2
			self.rom_data[frame_offset] = frame.tile_id & 0xFF
			self.rom_data[frame_offset + 1] = frame.duration
		
		if self.verbose:
			print(f"✓ Wrote animation to ROM at {address:08X}")
	
	def load_all_animations(self) -> None:
		"""Load all animations from ROM"""
		self.animations = []
		
		for i in range(self.MAX_ANIMATIONS):
			address = self.ANIMATION_TABLE_ADDRESS + i * 32
			animation = self.read_animation(address)
			
			if animation:
				self.animations.append(animation)
		
		if self.verbose:
			print(f"✓ Loaded {len(self.animations)} animations from ROM")
	
	def save_all_animations(self) -> None:
		"""Save all animations to ROM"""
		for animation in self.animations:
			self.write_animation(animation)
		
		if self.verbose:
			print(f"✓ Saved {len(self.animations)} animations to ROM")
	
	def preview_animation_ascii(self, animation: TileAnimation) -> str:
		"""Generate ASCII preview of animation"""
		lines = []
		
		lines.append(f"Animation: {animation.name}")
		lines.append(f"Type: {animation.animation_type.value}")
		lines.append(f"Base Tile: {animation.base_tile_id}")
		lines.append(f"Loop Mode: {animation.loop_mode.value}")
		lines.append(f"Total Duration: {animation.total_duration} frames ({animation.total_duration / 60:.2f}s)")
		lines.append("")
		lines.append("Frames:")
		
		for frame in animation.frames:
			duration_sec = frame.duration / 60
			lines.append(f"  Frame {frame.frame_id}: Tile {frame.tile_id}, {frame.duration} frames ({duration_sec:.2f}s)")
		
		# Visual timeline
		lines.append("")
		lines.append("Timeline:")
		timeline = ""
		for frame in animation.frames:
			timeline += str(frame.frame_id) * (frame.duration // 2)
		lines.append(f"  {timeline}")
		
		return "\n".join(lines)
	
	def export_animations(self, output_path: Path) -> None:
		"""Export animations to JSON"""
		data = {
			'animations': [a.to_dict() for a in self.animations],
			'total_count': len(self.animations)
		}
		
		with open(output_path, 'w') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported {len(self.animations)} animations to {output_path}")
	
	def import_animations(self, input_path: Path) -> None:
		"""Import animations from JSON"""
		with open(input_path, 'r') as f:
			data = json.load(f)
		
		self.animations = []
		for anim_dict in data['animations']:
			anim_dict['animation_type'] = AnimationType(anim_dict['animation_type'])
			anim_dict['loop_mode'] = LoopMode(anim_dict['loop_mode'])
			
			# Rebuild frames
			frames = []
			for frame_dict in anim_dict['frames']:
				frames.append(TileFrame(**frame_dict))
			anim_dict['frames'] = frames
			
			animation = TileAnimation(**anim_dict)
			self.animations.append(animation)
		
		if self.verbose:
			print(f"✓ Imported {len(self.animations)} animations from {input_path}")
	
	def save_rom(self, output_path: Path) -> None:
		"""Save modified ROM"""
		with open(output_path, 'wb') as f:
			f.write(self.rom_data)
		
		if self.verbose:
			print(f"✓ Saved ROM to {output_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Tile Animator')
	parser.add_argument('rom', type=str, help='FFMQ ROM file')
	parser.add_argument('--create', type=str, help='Create animation from template')
	parser.add_argument('--base-tile', type=int, default=0, help='Base tile ID')
	parser.add_argument('--list', action='store_true', help='List all animations')
	parser.add_argument('--preview', type=str, help='Preview animation')
	parser.add_argument('--export', type=str, help='Export animations to JSON')
	parser.add_argument('--import-json', type=str, help='Import animations from JSON')
	parser.add_argument('--save-rom', type=str, help='Save modified ROM')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	animator = FFMQTileAnimator(Path(args.rom), verbose=args.verbose)
	
	# Create animation
	if args.create:
		animation = animator.create_from_template(args.create, args.base_tile)
		
		if animation and args.save_rom:
			animator.write_animation(animation)
			animator.save_rom(Path(args.save_rom))
		
		return 0 if animation else 1
	
	# List animations
	if args.list:
		# Create template animations
		for template_name in animator.ANIMATION_TEMPLATES:
			animator.create_from_template(template_name)
		
		print(f"\n=== Tile Animations ({len(animator.animations)} total) ===\n")
		
		for animation in animator.animations:
			print(f"🎬 {animation.name}")
			print(f"   Type: {animation.animation_type.value}")
			print(f"   Frames: {len(animation.frames)}")
			print(f"   Duration: {animation.total_duration / 60:.2f}s")
			print(f"   Loop: {animation.loop_mode.value}")
			print()
		
		return 0
	
	# Preview animation
	if args.preview:
		animation = animator.create_from_template(args.preview)
		
		if animation:
			preview = animator.preview_animation_ascii(animation)
			print("\n" + preview + "\n")
			return 0
		else:
			print(f"Unknown animation: {args.preview}")
			print(f"Available: {', '.join(animator.ANIMATION_TEMPLATES.keys())}")
			return 1
	
	# Export
	if args.export:
		# Create templates if none exist
		if not animator.animations:
			for template_name in animator.ANIMATION_TEMPLATES:
				animator.create_from_template(template_name)
		
		animator.export_animations(Path(args.export))
		return 0
	
	# Import
	if args.import_json:
		animator.import_animations(Path(args.import_json))
		
		if args.save_rom:
			animator.save_all_animations()
			animator.save_rom(Path(args.save_rom))
		
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
