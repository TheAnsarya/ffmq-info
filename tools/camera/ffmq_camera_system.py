#!/usr/bin/env python3
"""
FFMQ Camera System Editor - Camera controls and boundaries

Camera Features:
- Camera modes
- Boundaries
- Following behavior
- Smooth transitions
- Zoom levels
- Screen shake

Camera Types:
- Fixed camera
- Follow player
- Follow target
- Cinematic
- Battle camera
- Cutscene camera

Features:
- Position control
- Speed/acceleration
- Boundaries/limits
- Focus targets
- Zoom management
- Transition curves

Usage:
	python ffmq_camera_system.py --extract rom.smc cameras.json
	python ffmq_camera_system.py --insert cameras.json rom.smc
	python ffmq_camera_system.py --camera 0 --show cameras.json
	python ffmq_camera_system.py --mode 0 --set-mode follow
	python ffmq_camera_system.py --test camera_0.json
"""

import argparse
import json
from pathlib import Path
from typing import List, Dict, Optional, Tuple, Any
from dataclasses import dataclass, asdict, field
from enum import Enum


class CameraMode(Enum):
	"""Camera behavior modes"""
	FIXED = 0
	FOLLOW_PLAYER = 1
	FOLLOW_TARGET = 2
	CINEMATIC = 3
	BATTLE = 4
	CUTSCENE = 5
	FREE = 6


class TransitionCurve(Enum):
	"""Camera transition curves"""
	LINEAR = 0
	EASE_IN = 1
	EASE_OUT = 2
	EASE_IN_OUT = 3
	SMOOTH = 4


@dataclass
class CameraBounds:
	"""Camera boundary limits"""
	min_x: int
	min_y: int
	max_x: int
	max_y: int


@dataclass
class CameraTarget:
	"""Camera follow target"""
	target_type: str  # "player", "npc", "sprite", "position"
	target_id: int
	offset_x: int = 0
	offset_y: int = 0


@dataclass
class CameraTransition:
	"""Camera transition settings"""
	curve: TransitionCurve
	duration: int  # frames
	ease_factor: float = 0.5


@dataclass
class Camera:
	"""Camera configuration"""
	camera_id: int
	name: str
	mode: CameraMode
	position_x: int = 0
	position_y: int = 0
	zoom_level: float = 1.0
	bounds: Optional[CameraBounds] = None
	target: Optional[CameraTarget] = None
	transition: Optional[CameraTransition] = None
	follow_speed: float = 1.0
	smooth_factor: float = 0.1
	shake_enabled: bool = False
	shake_intensity: int = 0
	shake_duration: int = 0


class CameraSystem:
	"""Camera system editor"""
	
	# ROM offsets (example)
	CAMERA_DATA_OFFSET = 0x1B0000
	CAMERA_COUNT = 16
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.rom_data: Optional[bytearray] = None
		self.cameras: List[Camera] = []
	
	def load_rom(self, rom_path: Path) -> bool:
		"""Load ROM file"""
		try:
			with open(rom_path, 'rb') as f:
				self.rom_data = bytearray(f.read())
			
			if self.verbose:
				print(f"✓ Loaded ROM: {rom_path} ({len(self.rom_data):,} bytes)")
			
			return True
		
		except Exception as e:
			print(f"Error loading ROM: {e}")
			return False
	
	def save_rom(self, output_path: Path) -> bool:
		"""Save ROM file"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return False
		
		try:
			with open(output_path, 'wb') as f:
				f.write(self.rom_data)
			
			if self.verbose:
				print(f"✓ Saved ROM: {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error saving ROM: {e}")
			return False
	
	def extract_cameras(self) -> List[Camera]:
		"""Extract camera configurations from ROM"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return []
		
		self.cameras = []
		
		for i in range(self.CAMERA_COUNT):
			offset = self.CAMERA_DATA_OFFSET + (i * 32)
			
			if offset + 32 > len(self.rom_data):
				break
			
			# Read camera data
			mode_val = self.rom_data[offset]
			pos_x = int.from_bytes(self.rom_data[offset+1:offset+3], byteorder='little', signed=True)
			pos_y = int.from_bytes(self.rom_data[offset+3:offset+5], byteorder='little', signed=True)
			zoom = self.rom_data[offset+5] / 100.0
			
			# Bounds
			has_bounds = self.rom_data[offset+6] != 0
			bounds = None
			
			if has_bounds:
				min_x = int.from_bytes(self.rom_data[offset+7:offset+9], byteorder='little', signed=True)
				min_y = int.from_bytes(self.rom_data[offset+9:offset+11], byteorder='little', signed=True)
				max_x = int.from_bytes(self.rom_data[offset+11:offset+13], byteorder='little', signed=True)
				max_y = int.from_bytes(self.rom_data[offset+13:offset+15], byteorder='little', signed=True)
				
				bounds = CameraBounds(min_x, min_y, max_x, max_y)
			
			# Target
			has_target = self.rom_data[offset+15] != 0
			target = None
			
			if has_target:
				target_type_val = self.rom_data[offset+16]
				target_id = self.rom_data[offset+17]
				offset_x = int.from_bytes(self.rom_data[offset+18:offset+20], byteorder='little', signed=True)
				offset_y = int.from_bytes(self.rom_data[offset+20:offset+22], byteorder='little', signed=True)
				
				target_types = ["player", "npc", "sprite", "position"]
				target_type = target_types[min(target_type_val, 3)]
				
				target = CameraTarget(target_type, target_id, offset_x, offset_y)
			
			# Settings
			follow_speed = self.rom_data[offset+22] / 100.0
			smooth_factor = self.rom_data[offset+23] / 100.0
			shake_enabled = self.rom_data[offset+24] != 0
			shake_intensity = self.rom_data[offset+25]
			shake_duration = self.rom_data[offset+26]
			
			# Transition
			has_transition = self.rom_data[offset+27] != 0
			transition = None
			
			if has_transition:
				curve_val = self.rom_data[offset+28]
				duration = self.rom_data[offset+29]
				ease_factor = self.rom_data[offset+30] / 100.0
				
				curves = list(TransitionCurve)
				curve = curves[min(curve_val, len(curves) - 1)]
				
				transition = CameraTransition(curve, duration, ease_factor)
			
			# Create camera
			modes = list(CameraMode)
			mode = modes[min(mode_val, len(modes) - 1)]
			
			camera = Camera(
				camera_id=i,
				name=f"Camera_{i:02d}",
				mode=mode,
				position_x=pos_x,
				position_y=pos_y,
				zoom_level=zoom,
				bounds=bounds,
				target=target,
				transition=transition,
				follow_speed=follow_speed,
				smooth_factor=smooth_factor,
				shake_enabled=shake_enabled,
				shake_intensity=shake_intensity,
				shake_duration=shake_duration
			)
			
			self.cameras.append(camera)
		
		if self.verbose:
			print(f"✓ Extracted {len(self.cameras)} cameras")
		
		return self.cameras
	
	def insert_cameras(self) -> bool:
		"""Insert camera configurations into ROM"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return False
		
		for camera in self.cameras:
			offset = self.CAMERA_DATA_OFFSET + (camera.camera_id * 32)
			
			if offset + 32 > len(self.rom_data):
				break
			
			# Write camera data
			self.rom_data[offset] = camera.mode.value
			self.rom_data[offset+1:offset+3] = camera.position_x.to_bytes(2, byteorder='little', signed=True)
			self.rom_data[offset+3:offset+5] = camera.position_y.to_bytes(2, byteorder='little', signed=True)
			self.rom_data[offset+5] = int(camera.zoom_level * 100)
			
			# Bounds
			if camera.bounds:
				self.rom_data[offset+6] = 1
				self.rom_data[offset+7:offset+9] = camera.bounds.min_x.to_bytes(2, byteorder='little', signed=True)
				self.rom_data[offset+9:offset+11] = camera.bounds.min_y.to_bytes(2, byteorder='little', signed=True)
				self.rom_data[offset+11:offset+13] = camera.bounds.max_x.to_bytes(2, byteorder='little', signed=True)
				self.rom_data[offset+13:offset+15] = camera.bounds.max_y.to_bytes(2, byteorder='little', signed=True)
			else:
				self.rom_data[offset+6] = 0
			
			# Target
			if camera.target:
				self.rom_data[offset+15] = 1
				
				target_types = {"player": 0, "npc": 1, "sprite": 2, "position": 3}
				self.rom_data[offset+16] = target_types.get(camera.target.target_type, 0)
				self.rom_data[offset+17] = camera.target.target_id
				self.rom_data[offset+18:offset+20] = camera.target.offset_x.to_bytes(2, byteorder='little', signed=True)
				self.rom_data[offset+20:offset+22] = camera.target.offset_y.to_bytes(2, byteorder='little', signed=True)
			else:
				self.rom_data[offset+15] = 0
			
			# Settings
			self.rom_data[offset+22] = int(camera.follow_speed * 100)
			self.rom_data[offset+23] = int(camera.smooth_factor * 100)
			self.rom_data[offset+24] = 1 if camera.shake_enabled else 0
			self.rom_data[offset+25] = camera.shake_intensity
			self.rom_data[offset+26] = camera.shake_duration
			
			# Transition
			if camera.transition:
				self.rom_data[offset+27] = 1
				self.rom_data[offset+28] = camera.transition.curve.value
				self.rom_data[offset+29] = camera.transition.duration
				self.rom_data[offset+30] = int(camera.transition.ease_factor * 100)
			else:
				self.rom_data[offset+27] = 0
		
		if self.verbose:
			print(f"✓ Inserted {len(self.cameras)} cameras")
		
		return True
	
	def set_mode(self, camera_id: int, mode: CameraMode) -> bool:
		"""Set camera mode"""
		camera = next((c for c in self.cameras if c.camera_id == camera_id), None)
		
		if camera is None:
			print(f"Camera {camera_id} not found")
			return False
		
		camera.mode = mode
		
		if self.verbose:
			print(f"✓ Set camera {camera_id} mode to {mode.name}")
		
		return True
	
	def set_position(self, camera_id: int, x: int, y: int) -> bool:
		"""Set camera position"""
		camera = next((c for c in self.cameras if c.camera_id == camera_id), None)
		
		if camera is None:
			print(f"Camera {camera_id} not found")
			return False
		
		camera.position_x = x
		camera.position_y = y
		
		if self.verbose:
			print(f"✓ Set camera {camera_id} position to ({x}, {y})")
		
		return True
	
	def set_bounds(self, camera_id: int, min_x: int, min_y: int, max_x: int, max_y: int) -> bool:
		"""Set camera boundaries"""
		camera = next((c for c in self.cameras if c.camera_id == camera_id), None)
		
		if camera is None:
			print(f"Camera {camera_id} not found")
			return False
		
		camera.bounds = CameraBounds(min_x, min_y, max_x, max_y)
		
		if self.verbose:
			print(f"✓ Set camera {camera_id} bounds: ({min_x}, {min_y}) to ({max_x}, {max_y})")
		
		return True
	
	def set_target(self, camera_id: int, target_type: str, target_id: int,
				  offset_x: int = 0, offset_y: int = 0) -> bool:
		"""Set camera follow target"""
		camera = next((c for c in self.cameras if c.camera_id == camera_id), None)
		
		if camera is None:
			print(f"Camera {camera_id} not found")
			return False
		
		camera.target = CameraTarget(target_type, target_id, offset_x, offset_y)
		
		if self.verbose:
			print(f"✓ Set camera {camera_id} target: {target_type} {target_id}")
		
		return True
	
	def export_json(self, output_path: Path) -> bool:
		"""Export cameras to JSON"""
		try:
			data = {
				'cameras': []
			}
			
			for camera in self.cameras:
				camera_data: Dict[str, Any] = {
					'camera_id': camera.camera_id,
					'name': camera.name,
					'mode': camera.mode.name,
					'position': {'x': camera.position_x, 'y': camera.position_y},
					'zoom_level': camera.zoom_level,
					'follow_speed': camera.follow_speed,
					'smooth_factor': camera.smooth_factor,
					'shake': {
						'enabled': camera.shake_enabled,
						'intensity': camera.shake_intensity,
						'duration': camera.shake_duration
					}
				}
				
				if camera.bounds:
					camera_data['bounds'] = {
						'min_x': camera.bounds.min_x,
						'min_y': camera.bounds.min_y,
						'max_x': camera.bounds.max_x,
						'max_y': camera.bounds.max_y
					}
				
				if camera.target:
					camera_data['target'] = {
						'type': camera.target.target_type,
						'id': camera.target.target_id,
						'offset_x': camera.target.offset_x,
						'offset_y': camera.target.offset_y
					}
				
				if camera.transition:
					camera_data['transition'] = {
						'curve': camera.transition.curve.name,
						'duration': camera.transition.duration,
						'ease_factor': camera.transition.ease_factor
					}
				
				data['cameras'].append(camera_data)
			
			with open(output_path, 'w', encoding='utf-8') as f:
				json.dump(data, f, indent='\t')
			
			if self.verbose:
				print(f"✓ Exported cameras to {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting cameras: {e}")
			return False
	
	def import_json(self, input_path: Path) -> bool:
		"""Import cameras from JSON"""
		try:
			with open(input_path, 'r', encoding='utf-8') as f:
				data = json.load(f)
			
			self.cameras = []
			
			for camera_data in data['cameras']:
				# Mode
				mode = CameraMode[camera_data['mode']]
				
				# Bounds
				bounds = None
				if 'bounds' in camera_data:
					b = camera_data['bounds']
					bounds = CameraBounds(b['min_x'], b['min_y'], b['max_x'], b['max_y'])
				
				# Target
				target = None
				if 'target' in camera_data:
					t = camera_data['target']
					target = CameraTarget(
						t['type'],
						t['id'],
						t.get('offset_x', 0),
						t.get('offset_y', 0)
					)
				
				# Transition
				transition = None
				if 'transition' in camera_data:
					tr = camera_data['transition']
					curve = TransitionCurve[tr['curve']]
					transition = CameraTransition(
						curve,
						tr['duration'],
						tr.get('ease_factor', 0.5)
					)
				
				# Position
				pos = camera_data['position']
				
				# Shake
				shake = camera_data.get('shake', {})
				
				camera = Camera(
					camera_id=camera_data['camera_id'],
					name=camera_data['name'],
					mode=mode,
					position_x=pos['x'],
					position_y=pos['y'],
					zoom_level=camera_data.get('zoom_level', 1.0),
					bounds=bounds,
					target=target,
					transition=transition,
					follow_speed=camera_data.get('follow_speed', 1.0),
					smooth_factor=camera_data.get('smooth_factor', 0.1),
					shake_enabled=shake.get('enabled', False),
					shake_intensity=shake.get('intensity', 0),
					shake_duration=shake.get('duration', 0)
				)
				
				self.cameras.append(camera)
			
			if self.verbose:
				print(f"✓ Imported {len(self.cameras)} cameras")
			
			return True
		
		except Exception as e:
			print(f"Error importing cameras: {e}")
			return False
	
	def print_camera(self, camera_id: int) -> None:
		"""Print camera details"""
		camera = next((c for c in self.cameras if c.camera_id == camera_id), None)
		
		if camera is None:
			print(f"Camera {camera_id} not found")
			return
		
		print(f"\n=== Camera {camera.camera_id}: {camera.name} ===\n")
		print(f"Mode: {camera.mode.name}")
		print(f"Position: ({camera.position_x}, {camera.position_y})")
		print(f"Zoom: {camera.zoom_level}x")
		print(f"Follow Speed: {camera.follow_speed}")
		print(f"Smooth Factor: {camera.smooth_factor}")
		print()
		
		if camera.bounds:
			print(f"Bounds: ({camera.bounds.min_x}, {camera.bounds.min_y}) to ({camera.bounds.max_x}, {camera.bounds.max_y})")
			print()
		
		if camera.target:
			print(f"Target: {camera.target.target_type} {camera.target.target_id}")
			print(f"Offset: ({camera.target.offset_x}, {camera.target.offset_y})")
			print()
		
		if camera.transition:
			print(f"Transition: {camera.transition.curve.name}")
			print(f"Duration: {camera.transition.duration} frames")
			print(f"Ease: {camera.transition.ease_factor}")
			print()
		
		print(f"Shake: {'Enabled' if camera.shake_enabled else 'Disabled'}")
		if camera.shake_enabled:
			print(f"  Intensity: {camera.shake_intensity}")
			print(f"  Duration: {camera.shake_duration} frames")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Camera System Editor')
	parser.add_argument('--extract', nargs=2, metavar=('ROM', 'OUTPUT'),
					   help='Extract cameras from ROM')
	parser.add_argument('--insert', nargs=2, metavar=('CAMERAS', 'ROM'),
					   help='Insert cameras into ROM')
	parser.add_argument('--camera', type=int, metavar='ID',
					   help='Camera ID for operations')
	parser.add_argument('--show', type=str, metavar='FILE',
					   help='Cameras file for --camera')
	parser.add_argument('--set-mode', type=str, metavar='MODE',
					   choices=['fixed', 'follow_player', 'follow_target', 'cinematic', 'battle', 'cutscene', 'free'],
					   help='Set camera mode')
	parser.add_argument('--set-position', nargs=2, type=int,
					   metavar=('X', 'Y'), help='Set camera position')
	parser.add_argument('--set-bounds', nargs=4, type=int,
					   metavar=('MIN_X', 'MIN_Y', 'MAX_X', 'MAX_Y'),
					   help='Set camera boundaries')
	parser.add_argument('--set-target', nargs='+',
					   metavar=('TYPE', 'ID', '[OFFSET_X]', '[OFFSET_Y]'),
					   help='Set camera target')
	parser.add_argument('--file', type=str, metavar='FILE',
					   help='Cameras JSON file')
	parser.add_argument('--test', type=str, metavar='FILE',
					   help='Test camera configuration')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	system = CameraSystem(verbose=args.verbose)
	
	# Extract
	if args.extract:
		rom_path, output_path = args.extract
		system.load_rom(Path(rom_path))
		system.extract_cameras()
		system.export_json(Path(output_path))
		return 0
	
	# Load file
	if args.file:
		system.import_json(Path(args.file))
	
	# Insert
	if args.insert:
		cameras_path, rom_path = args.insert
		system.import_json(Path(cameras_path))
		system.load_rom(Path(rom_path))
		system.insert_cameras()
		system.save_rom(Path(rom_path))
		return 0
	
	# Show camera
	if args.camera is not None:
		if args.show:
			system.import_json(Path(args.show))
		
		system.print_camera(args.camera)
		return 0
	
	# Set mode
	if args.set_mode and args.camera is not None:
		mode_map = {
			'fixed': CameraMode.FIXED,
			'follow_player': CameraMode.FOLLOW_PLAYER,
			'follow_target': CameraMode.FOLLOW_TARGET,
			'cinematic': CameraMode.CINEMATIC,
			'battle': CameraMode.BATTLE,
			'cutscene': CameraMode.CUTSCENE,
			'free': CameraMode.FREE
		}
		
		system.set_mode(args.camera, mode_map[args.set_mode])
		
		if args.file:
			system.export_json(Path(args.file))
		
		return 0
	
	# Set position
	if args.set_position and args.camera is not None:
		x, y = args.set_position
		system.set_position(args.camera, x, y)
		
		if args.file:
			system.export_json(Path(args.file))
		
		return 0
	
	# Set bounds
	if args.set_bounds and args.camera is not None:
		min_x, min_y, max_x, max_y = args.set_bounds
		system.set_bounds(args.camera, min_x, min_y, max_x, max_y)
		
		if args.file:
			system.export_json(Path(args.file))
		
		return 0
	
	# Set target
	if args.set_target and args.camera is not None:
		target_type = args.set_target[0]
		target_id = int(args.set_target[1])
		offset_x = int(args.set_target[2]) if len(args.set_target) > 2 else 0
		offset_y = int(args.set_target[3]) if len(args.set_target) > 3 else 0
		
		system.set_target(args.camera, target_type, target_id, offset_x, offset_y)
		
		if args.file:
			system.export_json(Path(args.file))
		
		return 0
	
	# Test
	if args.test:
		system.import_json(Path(args.test))
		print(f"\n✓ Loaded {len(system.cameras)} cameras")
		
		for camera in system.cameras:
			system.print_camera(camera.camera_id)
		
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
