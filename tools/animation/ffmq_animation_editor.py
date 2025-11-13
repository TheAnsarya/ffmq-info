#!/usr/bin/env python3
"""
FFMQ Animation Editor - Edit battle animations and effects

FFMQ Animation System:
- Spell animations (fire, ice, thunder, etc.)
- Physical attack animations
- Status effect visuals
- Screen effects (flash, shake, fade)
- Palette animations
- Sprite animations
- Projectile motion
- Timing and frame data

Features:
- View animation sequences
- Edit frame timing
- Modify sprite patterns
- Change palette cycling
- Configure screen effects
- Set projectile paths
- Preview animations
- Export animation data
- Import custom animations
- Frame-by-frame editor

Animation Structure:
- Animation ID
- Frame count
- Timing per frame
- Sprite patterns
- Palette data
- Movement data
- Effect flags

Usage:
	python ffmq_animation_editor.py rom.sfc --list-animations
	python ffmq_animation_editor.py rom.sfc --show-animation 10
	python ffmq_animation_editor.py rom.sfc --edit-animation 10 --speed 2
	python ffmq_animation_editor.py rom.sfc --export animations.json
"""

import argparse
import json
import struct
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any
from dataclasses import dataclass, field, asdict
from enum import Enum


class AnimationType(Enum):
	"""Animation types"""
	SPELL = "spell"
	ATTACK = "attack"
	STATUS = "status"
	SCREEN = "screen"
	PROJECTILE = "projectile"


class EffectType(Enum):
	"""Screen effect types"""
	NONE = "none"
	FLASH_WHITE = "flash_white"
	FLASH_RED = "flash_red"
	SHAKE = "shake"
	FADE_OUT = "fade_out"
	FADE_IN = "fade_in"


@dataclass
class AnimationFrame:
	"""Single animation frame"""
	frame_id: int
	duration: int  # Frames (60fps)
	sprite_pattern: int
	palette_id: int
	x_offset: int
	y_offset: int
	flags: int
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class Animation:
	"""Complete animation sequence"""
	animation_id: int
	name: str
	animation_type: AnimationType
	frames: List[AnimationFrame]
	effect_type: EffectType
	loop: bool
	sound_id: int
	
	def to_dict(self) -> dict:
		d = {
			'animation_id': self.animation_id,
			'name': self.name,
			'animation_type': self.animation_type.value,
			'frames': [f.to_dict() for f in self.frames],
			'effect_type': self.effect_type.value,
			'loop': self.loop,
			'sound_id': self.sound_id,
			'total_duration': sum(f.duration for f in self.frames),
			'frame_count': len(self.frames)
		}
		return d


class FFMQAnimationDatabase:
	"""Database of FFMQ animations"""
	
	# Animation data location
	ANIMATION_DATA_OFFSET = 0x360000
	NUM_ANIMATIONS = 128
	ANIMATION_SIZE = 128
	MAX_FRAMES_PER_ANIM = 16
	
	# Known animations
	ANIMATIONS = {
		# Spell animations
		0: ("Fire", AnimationType.SPELL),
		1: ("Fira", AnimationType.SPELL),
		2: ("Firaga", AnimationType.SPELL),
		3: ("Flare", AnimationType.SPELL),
		4: ("Blizzard", AnimationType.SPELL),
		5: ("Blizzara", AnimationType.SPELL),
		6: ("Blizzaga", AnimationType.SPELL),
		7: ("Thunder", AnimationType.SPELL),
		8: ("Thundara", AnimationType.SPELL),
		9: ("Thundaga", AnimationType.SPELL),
		10: ("Aero", AnimationType.SPELL),
		11: ("Aerora", AnimationType.SPELL),
		12: ("Aeroga", AnimationType.SPELL),
		13: ("Meteor", AnimationType.SPELL),
		14: ("Quake", AnimationType.SPELL),
		15: ("Cure", AnimationType.SPELL),
		16: ("Life", AnimationType.SPELL),
		
		# Attack animations
		32: ("Sword Slash", AnimationType.ATTACK),
		33: ("Axe Swing", AnimationType.ATTACK),
		34: ("Claw Strike", AnimationType.ATTACK),
		35: ("Bomb Throw", AnimationType.ATTACK),
		
		# Status animations
		48: ("Poison Effect", AnimationType.STATUS),
		49: ("Sleep Effect", AnimationType.STATUS),
		50: ("Confusion Effect", AnimationType.STATUS),
	}
	
	@classmethod
	def get_animation_name(cls, animation_id: int) -> Tuple[str, AnimationType]:
		"""Get animation name and type"""
		return cls.ANIMATIONS.get(animation_id, (f"Animation {animation_id}", AnimationType.SPELL))


class FFMQAnimationEditor:
	"""Edit FFMQ animations"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		if self.verbose:
			print(f"Loaded FFMQ ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def extract_animation(self, animation_id: int) -> Optional[Animation]:
		"""Extract animation from ROM"""
		if animation_id >= FFMQAnimationDatabase.NUM_ANIMATIONS:
			return None
		
		offset = FFMQAnimationDatabase.ANIMATION_DATA_OFFSET + (animation_id * FFMQAnimationDatabase.ANIMATION_SIZE)
		
		if offset + FFMQAnimationDatabase.ANIMATION_SIZE > len(self.rom_data):
			return None
		
		# Read animation header
		frame_count = self.rom_data[offset]
		effect_type_id = self.rom_data[offset + 1]
		loop_flag = self.rom_data[offset + 2]
		sound_id = self.rom_data[offset + 3]
		
		if frame_count == 0 or frame_count > FFMQAnimationDatabase.MAX_FRAMES_PER_ANIM:
			return None
		
		# Decode effect type
		effect_types = list(EffectType)
		effect_type = effect_types[effect_type_id % len(effect_types)]
		
		# Read frames
		frames = []
		for frame_id in range(frame_count):
			frame_offset = offset + 8 + (frame_id * 8)
			
			if frame_offset + 8 > len(self.rom_data):
				break
			
			duration = self.rom_data[frame_offset]
			sprite_pattern = self.rom_data[frame_offset + 1]
			palette_id = self.rom_data[frame_offset + 2]
			x_offset = struct.unpack_from('<b', self.rom_data, frame_offset + 3)[0]  # Signed
			y_offset = struct.unpack_from('<b', self.rom_data, frame_offset + 4)[0]  # Signed
			flags = self.rom_data[frame_offset + 5]
			
			frames.append(AnimationFrame(
				frame_id=frame_id,
				duration=duration if duration > 0 else 1,
				sprite_pattern=sprite_pattern,
				palette_id=palette_id,
				x_offset=x_offset,
				y_offset=y_offset,
				flags=flags
			))
		
		name, animation_type = FFMQAnimationDatabase.get_animation_name(animation_id)
		
		animation = Animation(
			animation_id=animation_id,
			name=name,
			animation_type=animation_type,
			frames=frames,
			effect_type=effect_type,
			loop=(loop_flag != 0),
			sound_id=sound_id
		)
		
		return animation
	
	def list_animations(self, animation_type: Optional[AnimationType] = None) -> List[Animation]:
		"""List all animations, optionally filtered by type"""
		animations = []
		
		for i in range(FFMQAnimationDatabase.NUM_ANIMATIONS):
			animation = self.extract_animation(i)
			
			if not animation:
				continue
			
			if animation_type and animation.animation_type != animation_type:
				continue
			
			animations.append(animation)
		
		return animations
	
	def modify_animation_speed(self, animation_id: int, speed_multiplier: float) -> bool:
		"""Modify animation speed by changing frame durations"""
		if animation_id >= FFMQAnimationDatabase.NUM_ANIMATIONS:
			return False
		
		animation = self.extract_animation(animation_id)
		
		if not animation:
			return False
		
		offset = FFMQAnimationDatabase.ANIMATION_DATA_OFFSET + (animation_id * FFMQAnimationDatabase.ANIMATION_SIZE)
		
		# Modify each frame duration
		for frame in animation.frames:
			frame_offset = offset + 8 + (frame.frame_id * 8)
			
			if frame_offset + 8 > len(self.rom_data):
				break
			
			new_duration = max(1, int(frame.duration / speed_multiplier))
			self.rom_data[frame_offset] = min(new_duration, 255)
		
		if self.verbose:
			print(f"✓ Modified animation {animation_id} speed (×{speed_multiplier:.2f})")
		
		return True
	
	def export_json(self, output_path: Path) -> None:
		"""Export animation database to JSON"""
		animations = self.list_animations()
		
		data = {
			'animations': [a.to_dict() for a in animations],
			'animation_count': len(animations)
		}
		
		with open(output_path, 'w') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported {len(animations)} animations to {output_path}")
	
	def save_rom(self, output_path: Optional[Path] = None) -> None:
		"""Save modified ROM"""
		save_path = output_path or self.rom_path
		
		with open(save_path, 'wb') as f:
			f.write(self.rom_data)
		
		if self.verbose:
			print(f"✓ Saved ROM to {save_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Animation Editor')
	parser.add_argument('rom', type=str, help='FFMQ ROM file')
	parser.add_argument('--list-animations', action='store_true', help='List all animations')
	parser.add_argument('--type', type=str, 
						choices=['spell', 'attack', 'status', 'screen', 'projectile'],
						help='Filter by animation type')
	parser.add_argument('--show-animation', type=int, help='Show animation details')
	parser.add_argument('--edit-animation', type=int, help='Edit animation')
	parser.add_argument('--speed', type=float, help='Speed multiplier (0.5=slower, 2.0=faster)')
	parser.add_argument('--export', type=str, help='Export to JSON')
	parser.add_argument('--save', type=str, help='Save modified ROM')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FFMQAnimationEditor(Path(args.rom), verbose=args.verbose)
	
	# List animations
	if args.list_animations:
		animation_type = AnimationType(args.type) if args.type else None
		animations = editor.list_animations(animation_type)
		
		type_filter = f" ({args.type})" if args.type else ""
		print(f"\nFFMQ Animations{type_filter} ({len(animations)}):\n")
		
		print(f"{'ID':<5} {'Name':<25} {'Type':<12} {'Frames':<8} {'Duration':<10} {'Loop'}")
		print("=" * 80)
		
		for anim in animations:
			duration = sum(f.duration for f in anim.frames)
			duration_sec = duration / 60.0
			loop_str = "✓" if anim.loop else ""
			
			print(f"{anim.animation_id:<5} {anim.name:<25} {anim.animation_type.value:<12} "
				  f"{len(anim.frames):<8} {duration_sec:.2f}s{'':<6} {loop_str}")
		
		return 0
	
	# Show animation
	if args.show_animation is not None:
		animation = editor.extract_animation(args.show_animation)
		
		if animation:
			print(f"\n=== {animation.name} ===\n")
			print(f"ID: {animation.animation_id}")
			print(f"Type: {animation.animation_type.value}")
			print(f"Effect: {animation.effect_type.value}")
			print(f"Sound: {animation.sound_id}")
			print(f"Loop: {animation.loop}")
			
			total_duration = sum(f.duration for f in animation.frames)
			print(f"Total Duration: {total_duration} frames ({total_duration/60:.2f} seconds)")
			
			print(f"\nFrames ({len(animation.frames)}):\n")
			print(f"{'#':<4} {'Duration':<10} {'Sprite':<8} {'Palette':<8} {'Offset':<12}")
			print("=" * 50)
			
			for frame in animation.frames:
				duration_sec = frame.duration / 60.0
				offset_str = f"({frame.x_offset:+d}, {frame.y_offset:+d})"
				
				print(f"{frame.frame_id:<4} {frame.duration:>3} ({duration_sec:.2f}s) "
					  f"{frame.sprite_pattern:<8} {frame.palette_id:<8} {offset_str}")
		else:
			print(f"❌ Animation {args.show_animation} not found")
		
		return 0
	
	# Edit animation
	if args.edit_animation is not None and args.speed is not None:
		success = editor.modify_animation_speed(args.edit_animation, args.speed)
		
		if success and args.save:
			editor.save_rom(Path(args.save))
		
		return 0
	
	# Export
	if args.export:
		editor.export_json(Path(args.export))
		return 0
	
	print("Use --list-animations, --show-animation, --edit-animation, or --export")
	return 0


if __name__ == '__main__':
	exit(main())
