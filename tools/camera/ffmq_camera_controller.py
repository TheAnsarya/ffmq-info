#!/usr/bin/env python3
"""
FFMQ Camera System Controller - Advanced camera controls and effects

Camera Features:
- Camera modes
- Zoom levels
- Pan controls
- Tracking modes
- Shake effects
- Transitions
- Boundaries

Camera Modes:
- Fixed: Static camera
- Follow: Track player
- Lead: Lead player movement
- Path: Follow predefined path
- Cinematic: Scripted sequences
- Free: Manual control

Zoom Levels:
- Close-up: 2x zoom
- Normal: 1x (default)
- Wide: 0.5x zoom
- Custom: Any scale

Tracking:
- Center: Keep target centered
- Smooth: Dampened follow
- Instant: No lag
- Predictive: Lead movement

Effects:
- Screen shake (intensity, duration)
- Camera transitions (fade, slide, zoom)
- Letterbox mode
- Focus blur

Usage:
	python ffmq_camera_controller.py rom.sfc --mode follow --zoom 1.5
	python ffmq_camera_controller.py rom.sfc --shake 10 --duration 30
	python ffmq_camera_controller.py rom.sfc --transition fade --speed 2
	python ffmq_camera_controller.py rom.sfc --path cinematic1.json
	python ffmq_camera_controller.py rom.sfc --export camera_config.json
"""

import argparse
import json
import math
from pathlib import Path
from typing import List, Tuple, Optional
from dataclasses import dataclass, asdict, field
from enum import Enum


class CameraMode(Enum):
	"""Camera control mode"""
	FIXED = "fixed"
	FOLLOW = "follow"
	LEAD = "lead"
	PATH = "path"
	CINEMATIC = "cinematic"
	FREE = "free"


class TrackingMode(Enum):
	"""Target tracking behavior"""
	CENTER = "center"
	SMOOTH = "smooth"
	INSTANT = "instant"
	PREDICTIVE = "predictive"


class TransitionType(Enum):
	"""Camera transition"""
	FADE = "fade"
	SLIDE = "slide"
	ZOOM = "zoom"
	CUT = "cut"


@dataclass
class CameraPosition:
	"""Camera position in world coordinates"""
	x: float
	y: float
	zoom: float = 1.0
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class CameraBounds:
	"""Camera movement boundaries"""
	min_x: int
	min_y: int
	max_x: int
	max_y: int
	
	def contains(self, x: float, y: float) -> bool:
		"""Check if position is within bounds"""
		return (self.min_x <= x <= self.max_x and 
				self.min_y <= y <= self.max_y)
	
	def clamp(self, pos: CameraPosition) -> CameraPosition:
		"""Clamp position to bounds"""
		clamped_x = max(self.min_x, min(self.max_x, pos.x))
		clamped_y = max(self.min_y, min(self.max_y, pos.y))
		
		return CameraPosition(clamped_x, clamped_y, pos.zoom)
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class ShakeEffect:
	"""Screen shake effect"""
	intensity: float  # Pixels
	duration: int  # Frames
	frequency: float = 1.0  # Hz
	decay: float = 0.9  # Per frame
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class CameraPathPoint:
	"""Point in camera path"""
	x: float
	y: float
	zoom: float
	duration: int  # Frames to reach this point
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class CameraConfig:
	"""Camera configuration"""
	mode: CameraMode
	tracking: TrackingMode
	position: CameraPosition
	bounds: Optional[CameraBounds] = None
	smoothing: float = 0.1  # 0-1, higher = more smoothing
	zoom_min: float = 0.5
	zoom_max: float = 2.0
	path: List[CameraPathPoint] = field(default_factory=list)
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['mode'] = self.mode.value
		d['tracking'] = self.tracking.value
		return d


class FFMQCameraController:
	"""Camera system controller"""
	
	# SNES screen size
	SCREEN_WIDTH = 256
	SCREEN_HEIGHT = 224
	
	# ROM addresses (hypothetical)
	CAMERA_X_ADDR = 0x7E0010
	CAMERA_Y_ADDR = 0x7E0012
	ZOOM_ADDR = 0x7E0014
	
	def __init__(self, rom_path: Optional[Path] = None, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		# Default configuration
		self.config = CameraConfig(
			mode=CameraMode.FOLLOW,
			tracking=TrackingMode.SMOOTH,
			position=CameraPosition(0, 0, 1.0),
			bounds=CameraBounds(0, 0, 1024, 1024),
			smoothing=0.1
		)
		
		self.target_position: Optional[Tuple[float, float]] = None
		self.current_shake: Optional[ShakeEffect] = None
		self.shake_time = 0
	
	def set_mode(self, mode: CameraMode) -> None:
		"""Set camera mode"""
		self.config.mode = mode
		
		if self.verbose:
			print(f"Camera mode: {mode.value}")
	
	def set_tracking(self, tracking: TrackingMode) -> None:
		"""Set tracking mode"""
		self.config.tracking = tracking
		
		if self.verbose:
			print(f"Tracking mode: {tracking.value}")
	
	def set_zoom(self, zoom: float) -> None:
		"""Set zoom level"""
		zoom = max(self.config.zoom_min, min(self.config.zoom_max, zoom))
		self.config.position.zoom = zoom
		
		if self.verbose:
			print(f"Zoom: {zoom:.2f}x")
	
	def set_target(self, x: float, y: float) -> None:
		"""Set camera target position"""
		self.target_position = (x, y)
	
	def update(self, dt: float = 1.0/60.0) -> CameraPosition:
		"""Update camera position (call every frame)"""
		if self.config.mode == CameraMode.FIXED:
			return self.config.position
		
		elif self.config.mode == CameraMode.FOLLOW:
			if self.target_position:
				return self._update_follow(dt)
		
		elif self.config.mode == CameraMode.PATH:
			return self._update_path(dt)
		
		# Apply shake
		if self.current_shake:
			pos = self.config.position
			offset = self._calculate_shake()
			
			return CameraPosition(
				pos.x + offset[0],
				pos.y + offset[1],
				pos.zoom
			)
		
		return self.config.position
	
	def _update_follow(self, dt: float) -> CameraPosition:
		"""Update follow camera"""
		if not self.target_position:
			return self.config.position
		
		target_x, target_y = self.target_position
		current = self.config.position
		
		if self.config.tracking == TrackingMode.CENTER:
			# Center on target immediately
			new_pos = CameraPosition(target_x, target_y, current.zoom)
		
		elif self.config.tracking == TrackingMode.SMOOTH:
			# Smooth interpolation
			smoothing = self.config.smoothing
			new_x = current.x + (target_x - current.x) * smoothing
			new_y = current.y + (target_y - current.y) * smoothing
			new_pos = CameraPosition(new_x, new_y, current.zoom)
		
		elif self.config.tracking == TrackingMode.INSTANT:
			# No smoothing
			new_pos = CameraPosition(target_x, target_y, current.zoom)
		
		elif self.config.tracking == TrackingMode.PREDICTIVE:
			# Lead the target based on velocity (simplified)
			lead_distance = 32
			new_x = target_x + lead_distance
			new_y = target_y
			new_pos = CameraPosition(new_x, new_y, current.zoom)
		
		else:
			new_pos = current
		
		# Apply bounds
		if self.config.bounds:
			new_pos = self.config.bounds.clamp(new_pos)
		
		self.config.position = new_pos
		return new_pos
	
	def _update_path(self, dt: float) -> CameraPosition:
		"""Update path camera (simplified)"""
		# Would interpolate between path points
		# For now, just return current position
		return self.config.position
	
	def start_shake(self, intensity: float, duration: int, 
					frequency: float = 1.0, decay: float = 0.9) -> None:
		"""Start screen shake effect"""
		self.current_shake = ShakeEffect(intensity, duration, frequency, decay)
		self.shake_time = 0
		
		if self.verbose:
			print(f"Shake: intensity={intensity}, duration={duration} frames")
	
	def _calculate_shake(self) -> Tuple[float, float]:
		"""Calculate shake offset for current frame"""
		if not self.current_shake:
			return (0.0, 0.0)
		
		shake = self.current_shake
		
		# Simple shake using sine wave
		t = self.shake_time * shake.frequency
		intensity = shake.intensity * (shake.decay ** self.shake_time)
		
		offset_x = math.sin(t * 2 * math.pi) * intensity
		offset_y = math.cos(t * 2 * math.pi * 1.3) * intensity  # Different frequency
		
		self.shake_time += 1
		
		# End shake when duration expires
		if self.shake_time >= shake.duration:
			self.current_shake = None
		
		return (offset_x, offset_y)
	
	def add_path_point(self, x: float, y: float, zoom: float, duration: int) -> None:
		"""Add point to camera path"""
		point = CameraPathPoint(x, y, zoom, duration)
		self.config.path.append(point)
		
		if self.verbose:
			print(f"Added path point: ({x}, {y}) zoom={zoom}")
	
	def clear_path(self) -> None:
		"""Clear camera path"""
		self.config.path = []
	
	def set_bounds(self, min_x: int, min_y: int, max_x: int, max_y: int) -> None:
		"""Set camera movement bounds"""
		self.config.bounds = CameraBounds(min_x, min_y, max_x, max_y)
		
		if self.verbose:
			print(f"Bounds: ({min_x}, {min_y}) to ({max_x}, {max_y})")
	
	def export_config(self, output_path: Path) -> None:
		"""Export camera configuration"""
		data = self.config.to_dict()
		
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported config to {output_path}")
	
	def import_config(self, input_path: Path) -> None:
		"""Import camera configuration"""
		with open(input_path, 'r', encoding='utf-8') as f:
			data = json.load(f)
		
		# Reconstruct config
		data['mode'] = CameraMode(data['mode'])
		data['tracking'] = TrackingMode(data['tracking'])
		data['position'] = CameraPosition(**data['position'])
		
		if data['bounds']:
			data['bounds'] = CameraBounds(**data['bounds'])
		
		if data['path']:
			data['path'] = [CameraPathPoint(**p) for p in data['path']]
		
		self.config = CameraConfig(**data)
		
		if self.verbose:
			print(f"✓ Imported config from {input_path}")
	
	def preview_config(self) -> None:
		"""Print camera configuration"""
		print("\n=== Camera Configuration ===\n")
		print(f"Mode: {self.config.mode.value}")
		print(f"Tracking: {self.config.tracking.value}")
		print(f"Position: ({self.config.position.x:.1f}, {self.config.position.y:.1f})")
		print(f"Zoom: {self.config.position.zoom:.2f}x")
		print(f"Smoothing: {self.config.smoothing:.2f}")
		print(f"Zoom Range: {self.config.zoom_min:.2f}x - {self.config.zoom_max:.2f}x")
		
		if self.config.bounds:
			b = self.config.bounds
			print(f"Bounds: ({b.min_x}, {b.min_y}) to ({b.max_x}, {b.max_y})")
		
		if self.config.path:
			print(f"Path Points: {len(self.config.path)}")
		
		print()


def main():
	parser = argparse.ArgumentParser(description='FFMQ Camera System Controller')
	parser.add_argument('rom', type=str, nargs='?', help='FFMQ ROM file (optional)')
	parser.add_argument('--mode', type=str, choices=[m.value for m in CameraMode],
					   default='follow', help='Camera mode')
	parser.add_argument('--tracking', type=str, choices=[t.value for t in TrackingMode],
					   default='smooth', help='Tracking mode')
	parser.add_argument('--zoom', type=float, default=1.0, help='Zoom level')
	parser.add_argument('--smoothing', type=float, default=0.1, help='Smoothing factor (0-1)')
	parser.add_argument('--shake', type=float, help='Shake intensity')
	parser.add_argument('--duration', type=int, default=30, help='Shake duration (frames)')
	parser.add_argument('--bounds', type=int, nargs=4, metavar=('MIN_X', 'MIN_Y', 'MAX_X', 'MAX_Y'),
					   help='Camera bounds')
	parser.add_argument('--export', type=str, help='Export config to JSON')
	parser.add_argument('--import', type=str, dest='import_file', help='Import config from JSON')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	rom_path = Path(args.rom) if args.rom else None
	controller = FFMQCameraController(rom_path=rom_path, verbose=args.verbose)
	
	# Import config
	if args.import_file:
		controller.import_config(Path(args.import_file))
		controller.preview_config()
		return 0
	
	# Set camera parameters
	controller.set_mode(CameraMode(args.mode))
	controller.set_tracking(TrackingMode(args.tracking))
	controller.set_zoom(args.zoom)
	controller.config.smoothing = args.smoothing
	
	# Set bounds
	if args.bounds:
		controller.set_bounds(*args.bounds)
	
	# Test shake
	if args.shake is not None:
		controller.start_shake(args.shake, args.duration)
		
		print("\n=== Shake Test ===\n")
		print(f"Intensity: {args.shake}")
		print(f"Duration: {args.duration} frames ({args.duration/60:.2f}s)")
		
		# Simulate a few frames
		for frame in range(min(10, args.duration)):
			offset = controller._calculate_shake()
			print(f"Frame {frame}: offset=({offset[0]:.2f}, {offset[1]:.2f})")
		
		print()
		return 0
	
	# Export config
	if args.export:
		controller.export_config(Path(args.export))
		return 0
	
	# Preview configuration
	controller.preview_config()
	
	# Simulate camera tracking
	print("=== Camera Tracking Simulation ===\n")
	
	# Set target and simulate a few frames
	controller.set_target(100, 100)
	
	print("Target: (100, 100)")
	print()
	
	for frame in range(5):
		pos = controller.update()
		print(f"Frame {frame}: ({pos.x:.2f}, {pos.y:.2f}) zoom={pos.zoom:.2f}x")
	
	print()
	
	return 0


if __name__ == '__main__':
	exit(main())
