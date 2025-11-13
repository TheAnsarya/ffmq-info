#!/usr/bin/env python3
"""
FFMQ Input Manager - Controller and input handling

Input Features:
- SNES controller input
- Button mapping
- Input recording
- Input playback
- Macro system
- Combo detection

SNES Controller:
- D-Pad (Up, Down, Left, Right)
- Face buttons (A, B, X, Y)
- Shoulder buttons (L, R)
- Start, Select

Input Features:
- Button state tracking
- Press/release detection
- Hold duration
- Combo sequences
- Input macros
- TAS (Tool-Assisted Speedrun) support

Features:
- Record input sequences
- Playback recordings
- Create macros
- Detect combos
- Export to movie format
- Frame-by-frame control

Usage:
	python ffmq_input_manager.py --record session.inp
	python ffmq_input_manager.py --playback session.inp
	python ffmq_input_manager.py --create-macro "quick_menu" --buttons "START,A,A"
	python ffmq_input_manager.py --detect-combo
	python ffmq_input_manager.py --export-movie session.smv
"""

import argparse
import json
import struct
from pathlib import Path
from typing import List, Dict, Optional, Tuple, Set
from dataclasses import dataclass, asdict, field
from enum import Enum, Flag


class Button(Flag):
	"""SNES controller buttons (bit flags)"""
	NONE = 0
	B = 1 << 0
	Y = 1 << 1
	SELECT = 1 << 2
	START = 1 << 3
	UP = 1 << 4
	DOWN = 1 << 5
	LEFT = 1 << 6
	RIGHT = 1 << 7
	A = 1 << 8
	X = 1 << 9
	L = 1 << 10
	R = 1 << 11


class InputType(Enum):
	"""Input event type"""
	PRESS = "press"
	RELEASE = "release"
	HOLD = "hold"


@dataclass
class InputFrame:
	"""Input state for a single frame"""
	frame: int
	buttons: Button
	
	def has_button(self, button: Button) -> bool:
		"""Check if button is pressed"""
		return bool(self.buttons & button)
	
	def to_dict(self) -> dict:
		"""Convert to dictionary"""
		return {
			'frame': self.frame,
			'buttons': self.buttons.value
		}


@dataclass
class InputEvent:
	"""Input event"""
	frame: int
	button: Button
	event_type: InputType
	duration: int = 0  # For holds


@dataclass
class Combo:
	"""Button combo sequence"""
	combo_id: int
	name: str
	buttons: List[Button]
	max_gap: int = 10  # Max frames between inputs
	description: str = ""


@dataclass
class Macro:
	"""Input macro"""
	macro_id: int
	name: str
	inputs: List[InputFrame]
	description: str = ""


class FFMQInputManager:
	"""Input recording and playback manager"""
	
	# Button name mapping
	BUTTON_NAMES = {
		'B': Button.B,
		'Y': Button.Y,
		'SELECT': Button.SELECT,
		'START': Button.START,
		'UP': Button.UP,
		'DOWN': Button.DOWN,
		'LEFT': Button.LEFT,
		'RIGHT': Button.RIGHT,
		'A': Button.A,
		'X': Button.X,
		'L': Button.L,
		'R': Button.R,
	}
	
	# Common combos
	DEFAULT_COMBOS = [
		{
			'combo_id': 1,
			'name': 'Quick Menu',
			'buttons': [Button.START, Button.A],
			'max_gap': 5,
			'description': 'Open menu and select first item'
		},
		{
			'combo_id': 2,
			'name': 'Quick Save',
			'buttons': [Button.START, Button.DOWN, Button.DOWN, Button.A],
			'max_gap': 8,
			'description': 'Open menu and save'
		},
		{
			'combo_id': 3,
			'name': 'Dash',
			'buttons': [Button.B, Button.B],
			'max_gap': 3,
			'description': 'Double-tap for dash'
		},
	]
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.recording: List[InputFrame] = []
		self.current_frame = 0
		self.current_buttons = Button.NONE
		self.combos: Dict[int, Combo] = {}
		self.macros: Dict[int, Macro] = {}
		self.button_states: Dict[Button, int] = {}  # Button -> frame pressed
		
		self._load_default_combos()
	
	def _load_default_combos(self) -> None:
		"""Load default combos"""
		for combo_data in self.DEFAULT_COMBOS:
			combo = Combo(**combo_data)
			self.combos[combo.combo_id] = combo
	
	def press_button(self, button: Button) -> None:
		"""Press button"""
		self.current_buttons |= button
		self.button_states[button] = self.current_frame
		
		if self.verbose:
			print(f"Frame {self.current_frame}: Press {self._button_name(button)}")
	
	def release_button(self, button: Button) -> None:
		"""Release button"""
		self.current_buttons &= ~button
		
		if button in self.button_states:
			del self.button_states[button]
		
		if self.verbose:
			print(f"Frame {self.current_frame}: Release {self._button_name(button)}")
	
	def _button_name(self, button: Button) -> str:
		"""Get button name"""
		for name, btn in self.BUTTON_NAMES.items():
			if btn == button:
				return name
		return "UNKNOWN"
	
	def advance_frame(self) -> None:
		"""Advance to next frame"""
		# Record current frame
		frame = InputFrame(
			frame=self.current_frame,
			buttons=self.current_buttons
		)
		self.recording.append(frame)
		
		self.current_frame += 1
	
	def start_recording(self) -> None:
		"""Start new recording"""
		self.recording = []
		self.current_frame = 0
		self.current_buttons = Button.NONE
		self.button_states = {}
		
		if self.verbose:
			print("🔴 Recording started")
	
	def stop_recording(self) -> None:
		"""Stop recording"""
		if self.verbose:
			print(f"⏹ Recording stopped ({len(self.recording)} frames)")
	
	def save_recording(self, output_path: Path) -> bool:
		"""Save recording to file"""
		try:
			data = {
				'frames': len(self.recording),
				'inputs': [frame.to_dict() for frame in self.recording]
			}
			
			with open(output_path, 'w', encoding='utf-8') as f:
				json.dump(data, f, indent='\t')
			
			if self.verbose:
				print(f"✓ Saved recording to {output_path} ({len(self.recording)} frames)")
			
			return True
		
		except Exception as e:
			print(f"Error saving recording: {e}")
			return False
	
	def load_recording(self, input_path: Path) -> bool:
		"""Load recording from file"""
		try:
			with open(input_path, 'r', encoding='utf-8') as f:
				data = json.load(f)
			
			self.recording = []
			
			for frame_data in data['inputs']:
				frame = InputFrame(
					frame=frame_data['frame'],
					buttons=Button(frame_data['buttons'])
				)
				self.recording.append(frame)
			
			if self.verbose:
				print(f"✓ Loaded recording from {input_path} ({len(self.recording)} frames)")
			
			return True
		
		except Exception as e:
			print(f"Error loading recording: {e}")
			return False
	
	def create_macro(self, macro_id: int, name: str, button_sequence: List[str],
					 description: str = "") -> Macro:
		"""Create macro from button sequence"""
		inputs = []
		
		for i, button_name in enumerate(button_sequence):
			if button_name in self.BUTTON_NAMES:
				button = self.BUTTON_NAMES[button_name]
				frame = InputFrame(frame=i, buttons=button)
				inputs.append(frame)
		
		macro = Macro(
			macro_id=macro_id,
			name=name,
			inputs=inputs,
			description=description
		)
		
		self.macros[macro_id] = macro
		
		if self.verbose:
			print(f"✓ Created macro '{name}' ({len(inputs)} inputs)")
		
		return macro
	
	def detect_combo(self, recent_frames: int = 60) -> List[Combo]:
		"""Detect combos in recent input"""
		detected = []
		
		# Get recent frames
		start = max(0, len(self.recording) - recent_frames)
		recent = self.recording[start:]
		
		# Check each combo
		for combo in self.combos.values():
			if self._check_combo_in_frames(combo, recent):
				detected.append(combo)
		
		return detected
	
	def _check_combo_in_frames(self, combo: Combo, frames: List[InputFrame]) -> bool:
		"""Check if combo appears in frames"""
		if len(combo.buttons) == 0:
			return False
		
		combo_idx = 0
		last_match_frame = -1
		
		for frame in frames:
			# Check if current combo button is pressed
			if frame.has_button(combo.buttons[combo_idx]):
				# Check gap from last match
				if last_match_frame >= 0:
					gap = frame.frame - last_match_frame
					if gap > combo.max_gap:
						# Gap too large, reset
						combo_idx = 0
						continue
				
				last_match_frame = frame.frame
				combo_idx += 1
				
				# Complete combo?
				if combo_idx >= len(combo.buttons):
					return True
		
		return False
	
	def export_smv(self, output_path: Path) -> bool:
		"""Export to SNES Movie format (.smv)"""
		try:
			with open(output_path, 'wb') as f:
				# SMV header
				f.write(b'SMV\x1A')  # Signature
				f.write(struct.pack('<I', 1))  # Version
				f.write(struct.pack('<I', 0))  # UID
				f.write(struct.pack('<I', len(self.recording)))  # Frame count
				f.write(struct.pack('<I', 0))  # Rerecord count
				f.write(struct.pack('B', 60))  # FPS (60)
				f.write(struct.pack('B', 1))  # Controllers (1)
				
				# Reserved
				f.write(b'\x00' * 14)
				
				# Controller data (2 bytes per frame for controller 1)
				for frame in self.recording:
					# SNES controller format (16 bits)
					buttons = frame.buttons.value
					f.write(struct.pack('<H', buttons))
			
			if self.verbose:
				print(f"✓ Exported to SMV: {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting SMV: {e}")
			return False
	
	def export_tas(self, output_path: Path) -> bool:
		"""Export to TAS script format"""
		try:
			with open(output_path, 'w', encoding='utf-8') as f:
				f.write(f"# TAS Input Recording\n")
				f.write(f"# Frames: {len(self.recording)}\n\n")
				
				for frame in self.recording:
					buttons = []
					
					for name, button in self.BUTTON_NAMES.items():
						if frame.has_button(button):
							buttons.append(name)
					
					if buttons:
						f.write(f"Frame {frame.frame:6d}: {','.join(buttons)}\n")
					else:
						f.write(f"Frame {frame.frame:6d}: .\n")
			
			if self.verbose:
				print(f"✓ Exported to TAS: {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting TAS: {e}")
			return False
	
	def print_statistics(self) -> None:
		"""Print input statistics"""
		if not self.recording:
			print("No recording data")
			return
		
		# Count button presses
		button_counts: Dict[Button, int] = {}
		
		for frame in self.recording:
			for name, button in self.BUTTON_NAMES.items():
				if frame.has_button(button):
					button_counts[button] = button_counts.get(button, 0) + 1
		
		print(f"\n=== Input Statistics ===\n")
		print(f"Total frames: {len(self.recording)}")
		print(f"\nButton presses:")
		print(f"{'Button':<10} {'Count':<10} {'%':<8}")
		print('-' * 28)
		
		for name, button in sorted(self.BUTTON_NAMES.items()):
			count = button_counts.get(button, 0)
			percent = (count / len(self.recording) * 100) if self.recording else 0
			print(f"{name:<10} {count:<10} {percent:6.2f}%")
	
	def print_macro_list(self) -> None:
		"""Print macro list"""
		if not self.macros:
			print("No macros")
			return
		
		print(f"\n=== Macros ===\n")
		print(f"{'ID':<4} {'Name':<20} {'Inputs':<8} {'Description':<30}")
		print('-' * 62)
		
		for macro_id, macro in sorted(self.macros.items()):
			print(f"{macro.macro_id:<4} {macro.name:<20} {len(macro.inputs):<8} "
				  f"{macro.description:<30}")
	
	def print_combo_list(self) -> None:
		"""Print combo list"""
		print(f"\n=== Combos ===\n")
		print(f"{'ID':<4} {'Name':<20} {'Buttons':<15} {'Description':<30}")
		print('-' * 69)
		
		for combo_id, combo in sorted(self.combos.items()):
			buttons_str = ' → '.join(self._button_name(b) for b in combo.buttons)
			print(f"{combo.combo_id:<4} {combo.name:<20} {buttons_str:<15} "
				  f"{combo.description:<30}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Input Manager')
	parser.add_argument('--record', type=str, metavar='OUTPUT',
					   help='Start recording to file')
	parser.add_argument('--playback', type=str, metavar='INPUT',
					   help='Playback recording')
	parser.add_argument('--create-macro', type=str, nargs=2,
					   metavar=('NAME', 'BUTTONS'), help='Create macro')
	parser.add_argument('--detect-combo', action='store_true',
					   help='Detect combos in recording')
	parser.add_argument('--export-smv', type=str, metavar='OUTPUT',
					   help='Export to SMV format')
	parser.add_argument('--export-tas', type=str, metavar='OUTPUT',
					   help='Export to TAS script')
	parser.add_argument('--statistics', action='store_true',
					   help='Show input statistics')
	parser.add_argument('--list-macros', action='store_true', help='List macros')
	parser.add_argument('--list-combos', action='store_true', help='List combos')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	manager = FFMQInputManager(verbose=args.verbose)
	
	# Load recording for playback
	if args.playback:
		manager.load_recording(Path(args.playback))
	
	# Create macro
	if args.create_macro:
		name, buttons_str = args.create_macro
		buttons = [b.strip() for b in buttons_str.split(',')]
		macro_id = len(manager.macros) + 1
		manager.create_macro(macro_id, name, buttons)
	
	# Detect combos
	if args.detect_combo and manager.recording:
		detected = manager.detect_combo()
		print(f"\nDetected {len(detected)} combo(s):")
		for combo in detected:
			print(f"  - {combo.name}")
		print()
	
	# Export SMV
	if args.export_smv and manager.recording:
		manager.export_smv(Path(args.export_smv))
		return 0
	
	# Export TAS
	if args.export_tas and manager.recording:
		manager.export_tas(Path(args.export_tas))
		return 0
	
	# Statistics
	if args.statistics:
		manager.print_statistics()
		return 0
	
	# List macros
	if args.list_macros:
		manager.print_macro_list()
		return 0
	
	# List combos
	if args.list_combos or not any([args.playback, args.create_macro, args.detect_combo]):
		manager.print_combo_list()
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
