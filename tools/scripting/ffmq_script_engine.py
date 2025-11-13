#!/usr/bin/env python3
"""
FFMQ Script Engine - Cutscene and event scripting system

Script Features:
- Event scripting
- Cutscene sequences
- Dialog system
- Camera control
- Character movement
- Sound effects
- Branching paths

Script Commands:
- DIALOG: Show text
- MOVE: Move character
- WAIT: Pause execution
- CAMERA: Control camera
- SOUND: Play sound/music
- FLAG: Set/check flags
- BRANCH: Conditional execution
- BATTLE: Start battle

Script Structure:
- Events (named sequences)
- Commands (individual actions)
- Parameters (command args)
- Labels (jump targets)
- Conditions (branching)

Features:
- Create scripts
- Parse script files
- Compile to bytecode
- Execute scripts
- Debug mode

Usage:
	python ffmq_script_engine.py rom.sfc --create intro_cutscene.txt
	python ffmq_script_engine.py rom.sfc --parse script.txt
	python ffmq_script_engine.py rom.sfc --compile script.txt --output script.bin
	python ffmq_script_engine.py rom.sfc --execute script.txt
	python ffmq_script_engine.py rom.sfc --validate script.txt
"""

import argparse
import re
from pathlib import Path
from typing import List, Dict, Optional, Any, Tuple
from dataclasses import dataclass, asdict, field
from enum import Enum


class CommandType(Enum):
	"""Script command type"""
	DIALOG = "dialog"
	MOVE = "move"
	WAIT = "wait"
	CAMERA = "camera"
	SOUND = "sound"
	MUSIC = "music"
	FLAG_SET = "flag_set"
	FLAG_CHECK = "flag_check"
	BRANCH = "branch"
	LABEL = "label"
	JUMP = "jump"
	BATTLE = "battle"
	FADE = "fade"
	SHAKE = "shake"
	END = "end"


@dataclass
class ScriptCommand:
	"""Single script command"""
	command_type: CommandType
	parameters: List[str] = field(default_factory=list)
	line_number: int = 0
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['command_type'] = self.command_type.value
		return d


@dataclass
class ScriptEvent:
	"""Event (sequence of commands)"""
	event_id: str
	name: str
	commands: List[ScriptCommand] = field(default_factory=list)
	
	def to_dict(self) -> dict:
		return asdict(self)


class FFMQScriptEngine:
	"""Script engine for cutscenes and events"""
	
	# Command syntax patterns
	COMMAND_PATTERNS = {
		CommandType.DIALOG: r'DIALOG\s+"([^"]+)"(?:\s+(\d+))?',
		CommandType.MOVE: r'MOVE\s+(\w+)\s+(\d+),(\d+)(?:\s+(\d+))?',
		CommandType.WAIT: r'WAIT\s+(\d+)',
		CommandType.CAMERA: r'CAMERA\s+(\w+)(?:\s+(.+))?',
		CommandType.SOUND: r'SOUND\s+(\d+)',
		CommandType.MUSIC: r'MUSIC\s+(\d+)',
		CommandType.FLAG_SET: r'FLAG_SET\s+(\w+)',
		CommandType.FLAG_CHECK: r'FLAG_CHECK\s+(\w+)',
		CommandType.BRANCH: r'BRANCH\s+(\w+)',
		CommandType.LABEL: r'LABEL\s+(\w+)',
		CommandType.JUMP: r'JUMP\s+(\w+)',
		CommandType.BATTLE: r'BATTLE\s+(\d+)',
		CommandType.FADE: r'FADE\s+(IN|OUT)(?:\s+(\d+))?',
		CommandType.SHAKE: r'SHAKE\s+(\d+)(?:\s+(\d+))?',
		CommandType.END: r'END'
	}
	
	def __init__(self, rom_path: Optional[Path] = None, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		self.events: Dict[str, ScriptEvent] = {}
		self.labels: Dict[str, int] = {}  # Label -> command index
	
	def parse_script_file(self, script_path: Path) -> List[ScriptEvent]:
		"""Parse script file into events"""
		with open(script_path, 'r', encoding='utf-8') as f:
			lines = f.readlines()
		
		events = []
		current_event = None
		
		for line_num, line in enumerate(lines, 1):
			# Strip comments and whitespace
			line = line.split('//')[0].strip()
			
			if not line:
				continue
			
			# Event declaration: EVENT event_id "Event Name"
			event_match = re.match(r'EVENT\s+(\w+)\s+"([^"]+)"', line)
			if event_match:
				event_id = event_match.group(1)
				event_name = event_match.group(2)
				
				current_event = ScriptEvent(
					event_id=event_id,
					name=event_name,
					commands=[]
				)
				
				events.append(current_event)
				
				if self.verbose:
					print(f"Event: {event_id} - {event_name}")
				
				continue
			
			# Parse command
			if current_event:
				command = self._parse_command(line, line_num)
				
				if command:
					current_event.commands.append(command)
		
		# Store events
		for event in events:
			self.events[event.event_id] = event
		
		return events
	
	def _parse_command(self, line: str, line_num: int) -> Optional[ScriptCommand]:
		"""Parse single command line"""
		for cmd_type, pattern in self.COMMAND_PATTERNS.items():
			match = re.match(pattern, line, re.IGNORECASE)
			
			if match:
				params = list(match.groups())
				# Remove None values
				params = [p for p in params if p is not None]
				
				command = ScriptCommand(
					command_type=cmd_type,
					parameters=params,
					line_number=line_num
				)
				
				return command
		
		print(f"Warning: Unknown command at line {line_num}: {line}")
		return None
	
	def create_sample_script(self, output_path: Path) -> None:
		"""Create sample script file"""
		sample = '''// FFMQ Sample Event Script
// Comments start with //

EVENT intro_scene "Introduction Cutscene"
	// Show dialog with character ID
	DIALOG "Welcome to Final Fantasy Mystic Quest!" 0
	WAIT 60
	
	// Move character to position
	MOVE benjamin 128,112 60
	WAIT 60
	
	// Camera control
	CAMERA follow benjamin
	WAIT 30
	
	// Play music
	MUSIC 1
	
	// Set story flag
	FLAG_SET intro_complete
	
	END

EVENT boss_encounter "Boss Battle Event"
	// Fade out
	FADE OUT 30
	WAIT 30
	
	// Play boss music
	MUSIC 5
	
	// Fade in
	FADE IN 30
	
	// Boss dialog
	DIALOG "You dare challenge me?" 1
	WAIT 60
	
	// Screen shake
	SHAKE 10 30
	
	// Start battle
	BATTLE 10
	
	// Check if won
	FLAG_CHECK battle_won
	BRANCH victory_scene
	
	END

EVENT victory_scene "Victory"
	DIALOG "You did it!" 0
	WAIT 60
	
	FLAG_SET boss_defeated
	
	END
'''
		
		with open(output_path, 'w', encoding='utf-8') as f:
			f.write(sample)
		
		if self.verbose:
			print(f"✓ Created sample script: {output_path}")
	
	def compile_to_bytecode(self, event: ScriptEvent) -> bytes:
		"""Compile event to bytecode (simplified)"""
		bytecode = bytearray()
		
		# Event header
		event_id_bytes = event.event_id.encode('ascii')[:16].ljust(16, b'\x00')
		bytecode.extend(event_id_bytes)
		
		# Command count
		bytecode.extend(len(event.commands).to_bytes(2, 'little'))
		
		# Commands
		for cmd in event.commands:
			# Command type (1 byte)
			cmd_type_map = {
				CommandType.DIALOG: 0x01,
				CommandType.MOVE: 0x02,
				CommandType.WAIT: 0x03,
				CommandType.CAMERA: 0x04,
				CommandType.SOUND: 0x05,
				CommandType.MUSIC: 0x06,
				CommandType.FLAG_SET: 0x07,
				CommandType.FLAG_CHECK: 0x08,
				CommandType.BRANCH: 0x09,
				CommandType.LABEL: 0x0A,
				CommandType.JUMP: 0x0B,
				CommandType.BATTLE: 0x0C,
				CommandType.FADE: 0x0D,
				CommandType.SHAKE: 0x0E,
				CommandType.END: 0xFF
			}
			
			bytecode.append(cmd_type_map.get(cmd.command_type, 0x00))
			
			# Parameter count
			bytecode.append(len(cmd.parameters))
			
			# Parameters (variable length strings)
			for param in cmd.parameters:
				param_bytes = param.encode('ascii')[:255]
				bytecode.append(len(param_bytes))
				bytecode.extend(param_bytes)
		
		return bytes(bytecode)
	
	def execute_event(self, event_id: str, debug: bool = False) -> None:
		"""Execute event (simulation)"""
		if event_id not in self.events:
			raise ValueError(f"Event not found: {event_id}")
		
		event = self.events[event_id]
		
		print(f"\n=== Executing: {event.name} ===\n")
		
		pc = 0  # Program counter
		flags = set()  # Story flags
		
		while pc < len(event.commands):
			cmd = event.commands[pc]
			
			if debug:
				print(f"[{pc:03d}] {cmd.command_type.value} {cmd.parameters}")
			
			# Execute command
			if cmd.command_type == CommandType.DIALOG:
				text = cmd.parameters[0]
				char_id = cmd.parameters[1] if len(cmd.parameters) > 1 else "0"
				print(f"  [Character {char_id}]: \"{text}\"")
			
			elif cmd.command_type == CommandType.MOVE:
				char = cmd.parameters[0]
				x, y = cmd.parameters[1], cmd.parameters[2]
				speed = cmd.parameters[3] if len(cmd.parameters) > 3 else "normal"
				print(f"  Moving {char} to ({x}, {y}) at {speed} speed")
			
			elif cmd.command_type == CommandType.WAIT:
				frames = cmd.parameters[0]
				print(f"  Waiting {frames} frames ({int(frames)/60:.1f}s)")
			
			elif cmd.command_type == CommandType.CAMERA:
				mode = cmd.parameters[0]
				target = cmd.parameters[1] if len(cmd.parameters) > 1 else ""
				print(f"  Camera: {mode} {target}")
			
			elif cmd.command_type == CommandType.SOUND:
				sound_id = cmd.parameters[0]
				print(f"  Playing sound {sound_id}")
			
			elif cmd.command_type == CommandType.MUSIC:
				music_id = cmd.parameters[0]
				print(f"  Playing music {music_id}")
			
			elif cmd.command_type == CommandType.FLAG_SET:
				flag = cmd.parameters[0]
				flags.add(flag)
				print(f"  Set flag: {flag}")
			
			elif cmd.command_type == CommandType.FLAG_CHECK:
				flag = cmd.parameters[0]
				result = flag in flags
				print(f"  Check flag: {flag} = {result}")
			
			elif cmd.command_type == CommandType.BRANCH:
				label = cmd.parameters[0]
				print(f"  Branch to: {label}")
				# Would jump to label here
			
			elif cmd.command_type == CommandType.BATTLE:
				enemy_id = cmd.parameters[0]
				print(f"  Starting battle with enemy {enemy_id}")
			
			elif cmd.command_type == CommandType.FADE:
				direction = cmd.parameters[0]
				duration = cmd.parameters[1] if len(cmd.parameters) > 1 else "30"
				print(f"  Fade {direction} over {duration} frames")
			
			elif cmd.command_type == CommandType.SHAKE:
				intensity = cmd.parameters[0]
				duration = cmd.parameters[1] if len(cmd.parameters) > 1 else "30"
				print(f"  Shake screen (intensity: {intensity}, duration: {duration})")
			
			elif cmd.command_type == CommandType.END:
				print(f"  Event end")
				break
			
			pc += 1
		
		print(f"\n=== Event Complete ===\n")
	
	def validate_script(self, event: ScriptEvent) -> List[str]:
		"""Validate script for errors"""
		errors = []
		
		# Check for matching labels and jumps
		labels = set()
		jumps = set()
		
		for cmd in event.commands:
			if cmd.command_type == CommandType.LABEL:
				label = cmd.parameters[0]
				if label in labels:
					errors.append(f"Line {cmd.line_number}: Duplicate label '{label}'")
				labels.add(label)
			
			elif cmd.command_type in (CommandType.JUMP, CommandType.BRANCH):
				jumps.add(cmd.parameters[0])
		
		# Check for undefined labels
		for jump in jumps:
			if jump not in labels:
				errors.append(f"Undefined label: '{jump}'")
		
		# Check for END command
		has_end = any(cmd.command_type == CommandType.END for cmd in event.commands)
		if not has_end:
			errors.append("Missing END command")
		
		return errors
	
	def print_event_info(self, event_id: str) -> None:
		"""Print event information"""
		if event_id not in self.events:
			raise ValueError(f"Event not found: {event_id}")
		
		event = self.events[event_id]
		
		print(f"\n=== Event: {event.name} ===\n")
		print(f"ID: {event.event_id}")
		print(f"Commands: {len(event.commands)}\n")
		
		for i, cmd in enumerate(event.commands):
			print(f"{i:03d}: {cmd.command_type.value} {cmd.parameters}")
		
		print()


def main():
	parser = argparse.ArgumentParser(description='FFMQ Script Engine')
	parser.add_argument('rom', type=str, nargs='?', help='FFMQ ROM file (optional)')
	parser.add_argument('--create', type=str, help='Create sample script file')
	parser.add_argument('--parse', type=str, help='Parse script file')
	parser.add_argument('--compile', type=str, help='Compile script to bytecode')
	parser.add_argument('--output', type=str, help='Output file for compilation')
	parser.add_argument('--execute', type=str, help='Execute script')
	parser.add_argument('--event', type=str, help='Event ID to execute')
	parser.add_argument('--validate', type=str, help='Validate script file')
	parser.add_argument('--debug', action='store_true', help='Debug mode')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	rom_path = Path(args.rom) if args.rom else None
	engine = FFMQScriptEngine(rom_path=rom_path, verbose=args.verbose)
	
	# Create sample
	if args.create:
		engine.create_sample_script(Path(args.create))
		return 0
	
	# Parse script
	if args.parse:
		events = engine.parse_script_file(Path(args.parse))
		
		print(f"\nParsed {len(events)} event(s):\n")
		
		for event in events:
			print(f"  {event.event_id}: {event.name} ({len(event.commands)} commands)")
		
		print()
		return 0
	
	# Compile script
	if args.compile:
		events = engine.parse_script_file(Path(args.compile))
		
		output_file = args.output or "script.bin"
		
		with open(output_file, 'wb') as f:
			for event in events:
				bytecode = engine.compile_to_bytecode(event)
				f.write(bytecode)
		
		print(f"✓ Compiled {len(events)} event(s) to {output_file}")
		return 0
	
	# Execute script
	if args.execute:
		events = engine.parse_script_file(Path(args.execute))
		
		if args.event:
			engine.execute_event(args.event, args.debug)
		else:
			# Execute first event
			if events:
				engine.execute_event(events[0].event_id, args.debug)
		
		return 0
	
	# Validate script
	if args.validate:
		events = engine.parse_script_file(Path(args.validate))
		
		print(f"\n=== Validating Script ===\n")
		
		total_errors = 0
		
		for event in events:
			errors = engine.validate_script(event)
			
			if errors:
				print(f"{event.event_id}:")
				for error in errors:
					print(f"  ❌ {error}")
				total_errors += len(errors)
			else:
				print(f"{event.event_id}: ✓ OK")
		
		print(f"\nTotal errors: {total_errors}\n")
		return 0
	
	print("\nScript Engine")
	print("=" * 50)
	print("\nExamples:")
	print("  --create sample.txt")
	print("  --parse sample.txt")
	print("  --execute sample.txt --event intro_scene --debug")
	print()
	
	return 0


if __name__ == '__main__':
	exit(main())
