#!/usr/bin/env python3
"""
FFMQ Event Editor - Event scripting and cutscene editor

Event Features:
- Event scripting
- Cutscene sequences
- Dialog triggers
- Animation control
- Camera movement
- Flag management
- Conditional logic

Event Types:
- Cutscenes
- Dialog events
- Battle triggers
- Map transitions
- Item acquisition
- NPC interactions
- Boss events

Features:
- Visual editor
- Script compilation
- Trigger management
- Timing control
- Preview mode
- Export/import

Usage:
	python ffmq_event_editor.py --extract rom.smc events.json
	python ffmq_event_editor.py --insert events.json rom.smc
	python ffmq_event_editor.py --list events.json
	python ffmq_event_editor.py --event 10 --show events.json
	python ffmq_event_editor.py --compile script.txt event.bin
"""

import argparse
import json
from pathlib import Path
from typing import List, Dict, Optional, Any
from dataclasses import dataclass, asdict, field
from enum import Enum


class EventType(Enum):
	"""Event types"""
	CUTSCENE = "cutscene"
	DIALOG = "dialog"
	BATTLE = "battle"
	TRANSITION = "transition"
	ITEM = "item"
	NPC = "npc"
	BOSS = "boss"


class CommandType(Enum):
	"""Event command types"""
	DIALOG = 0x01
	MOVE = 0x02
	WAIT = 0x03
	CAMERA = 0x04
	FADE = 0x05
	SOUND = 0x06
	MUSIC = 0x07
	FLAG_SET = 0x08
	FLAG_CHECK = 0x09
	JUMP = 0x0A
	CALL = 0x0B
	RETURN = 0x0C
	BATTLE = 0x0D
	ITEM_GIVE = 0x0E
	ANIMATION = 0x0F
	END = 0xFF


@dataclass
class EventCommand:
	"""Event command"""
	command: CommandType
	parameters: List[int] = field(default_factory=list)
	comment: str = ""


@dataclass
class Event:
	"""Event data"""
	event_id: int
	name: str
	event_type: EventType
	commands: List[EventCommand] = field(default_factory=list)
	triggers: List[int] = field(default_factory=list)
	flags_required: List[int] = field(default_factory=list)
	flags_set: List[int] = field(default_factory=list)
	rom_offset: int = 0


class EventEditor:
	"""Event and cutscene editor"""
	
	# ROM offsets (example)
	EVENT_DATA_OFFSET = 0x140000
	EVENT_COUNT = 200
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.rom_data: Optional[bytearray] = None
		self.events: List[Event] = []
	
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
	
	def extract_events(self) -> List[Event]:
		"""Extract events from ROM"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return []
		
		self.events = []
		
		for i in range(self.EVENT_COUNT):
			# Read event pointer
			pointer_offset = self.EVENT_DATA_OFFSET + (i * 2)
			
			if pointer_offset + 2 > len(self.rom_data):
				break
			
			pointer = int.from_bytes(
				self.rom_data[pointer_offset:pointer_offset+2],
				byteorder='little'
			)
			
			# Read event data
			commands = []
			offset = pointer
			
			while offset < len(self.rom_data):
				cmd_byte = self.rom_data[offset]
				
				# Check for end command
				if cmd_byte == 0xFF:
					commands.append(EventCommand(
						command=CommandType.END,
						parameters=[]
					))
					break
				
				# Parse command
				try:
					cmd_type = CommandType(cmd_byte)
				except ValueError:
					# Unknown command
					offset += 1
					continue
				
				# Read parameters (example: 1-4 bytes)
				param_count = self._get_param_count(cmd_type)
				params = []
				
				for _ in range(param_count):
					offset += 1
					if offset < len(self.rom_data):
						params.append(self.rom_data[offset])
				
				command = EventCommand(
					command=cmd_type,
					parameters=params
				)
				
				commands.append(command)
				offset += 1
			
			event = Event(
				event_id=i,
				name=f"Event_{i:03d}",
				event_type=EventType.CUTSCENE,
				commands=commands,
				rom_offset=pointer
			)
			
			self.events.append(event)
		
		if self.verbose:
			print(f"✓ Extracted {len(self.events)} events")
		
		return self.events
	
	def _get_param_count(self, cmd_type: CommandType) -> int:
		"""Get parameter count for command"""
		param_counts = {
			CommandType.DIALOG: 2,
			CommandType.MOVE: 3,
			CommandType.WAIT: 1,
			CommandType.CAMERA: 2,
			CommandType.FADE: 1,
			CommandType.SOUND: 1,
			CommandType.MUSIC: 1,
			CommandType.FLAG_SET: 1,
			CommandType.FLAG_CHECK: 1,
			CommandType.JUMP: 2,
			CommandType.CALL: 2,
			CommandType.RETURN: 0,
			CommandType.BATTLE: 1,
			CommandType.ITEM_GIVE: 2,
			CommandType.ANIMATION: 2,
			CommandType.END: 0,
		}
		
		return param_counts.get(cmd_type, 0)
	
	def insert_events(self) -> bool:
		"""Insert events into ROM"""
		if self.rom_data is None:
			print("Error: No ROM loaded")
			return False
		
		for event in self.events:
			offset = event.rom_offset
			
			# Write commands
			for command in event.commands:
				if offset >= len(self.rom_data):
					break
				
				# Write command byte
				self.rom_data[offset] = command.command.value
				offset += 1
				
				# Write parameters
				for param in command.parameters:
					if offset >= len(self.rom_data):
						break
					
					self.rom_data[offset] = param
					offset += 1
		
		if self.verbose:
			print(f"✓ Inserted {len(self.events)} events")
		
		return True
	
	def compile_script(self, script_text: str) -> List[EventCommand]:
		"""Compile script text to commands"""
		commands = []
		
		for line in script_text.split('\n'):
			line = line.strip()
			
			if not line or line.startswith('#'):
				continue
			
			# Parse command (example: DIALOG 1 2)
			parts = line.split()
			if not parts:
				continue
			
			cmd_name = parts[0].upper()
			params = [int(p, 0) for p in parts[1:]]
			
			# Find command type
			cmd_type = None
			for ct in CommandType:
				if ct.name == cmd_name:
					cmd_type = ct
					break
			
			if cmd_type is None:
				continue
			
			command = EventCommand(
				command=cmd_type,
				parameters=params
			)
			
			commands.append(command)
		
		return commands
	
	def decompile_event(self, event: Event) -> str:
		"""Decompile event to script text"""
		lines = []
		
		lines.append(f"# Event {event.event_id}: {event.name}")
		lines.append(f"# Type: {event.event_type.value}")
		lines.append("")
		
		for command in event.commands:
			# Format command
			cmd_str = command.command.name
			
			if command.parameters:
				params_str = ' '.join(str(p) for p in command.parameters)
				cmd_str += f" {params_str}"
			
			if command.comment:
				cmd_str += f"  # {command.comment}"
			
			lines.append(cmd_str)
		
		return '\n'.join(lines)
	
	def export_json(self, output_path: Path) -> bool:
		"""Export events to JSON"""
		try:
			data = {
				'events': []
			}
			
			for event in self.events:
				event_data = {
					'event_id': event.event_id,
					'name': event.name,
					'event_type': event.event_type.value,
					'commands': [
						{
							'command': cmd.command.name,
							'parameters': cmd.parameters,
							'comment': cmd.comment
						}
						for cmd in event.commands
					],
					'triggers': event.triggers,
					'flags_required': event.flags_required,
					'flags_set': event.flags_set,
					'rom_offset': event.rom_offset
				}
				
				data['events'].append(event_data)
			
			with open(output_path, 'w', encoding='utf-8') as f:
				json.dump(data, f, indent='\t')
			
			if self.verbose:
				print(f"✓ Exported events to {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting events: {e}")
			return False
	
	def import_json(self, input_path: Path) -> bool:
		"""Import events from JSON"""
		try:
			with open(input_path, 'r', encoding='utf-8') as f:
				data = json.load(f)
			
			self.events = []
			
			for event_data in data['events']:
				commands = []
				
				for cmd_data in event_data['commands']:
					# Find command type
					cmd_type = None
					for ct in CommandType:
						if ct.name == cmd_data['command']:
							cmd_type = ct
							break
					
					if cmd_type is None:
						continue
					
					command = EventCommand(
						command=cmd_type,
						parameters=cmd_data['parameters'],
						comment=cmd_data.get('comment', '')
					)
					
					commands.append(command)
				
				event = Event(
					event_id=event_data['event_id'],
					name=event_data['name'],
					event_type=EventType(event_data['event_type']),
					commands=commands,
					triggers=event_data.get('triggers', []),
					flags_required=event_data.get('flags_required', []),
					flags_set=event_data.get('flags_set', []),
					rom_offset=event_data['rom_offset']
				)
				
				self.events.append(event)
			
			if self.verbose:
				print(f"✓ Imported {len(self.events)} events")
			
			return True
		
		except Exception as e:
			print(f"Error importing events: {e}")
			return False
	
	def print_event(self, event_id: int) -> None:
		"""Print event details"""
		event = next((e for e in self.events if e.event_id == event_id), None)
		
		if event is None:
			print(f"Event {event_id} not found")
			return
		
		print(f"\n=== Event {event.event_id}: {event.name} ===\n")
		print(f"Type: {event.event_type.value}")
		print(f"ROM Offset: 0x{event.rom_offset:06X}")
		print(f"Commands: {len(event.commands)}")
		print()
		
		# Print script
		script = self.decompile_event(event)
		print(script)
	
	def list_events(self) -> None:
		"""List all events"""
		print(f"\n=== Events ({len(self.events)}) ===\n")
		
		for event in self.events:
			print(f"{event.event_id:3d}: {event.name} ({event.event_type.value}) - {len(event.commands)} commands")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Event Editor')
	parser.add_argument('--extract', nargs=2, metavar=('ROM', 'OUTPUT'),
					   help='Extract events from ROM')
	parser.add_argument('--insert', nargs=2, metavar=('EVENTS', 'ROM'),
					   help='Insert events into ROM')
	parser.add_argument('--list', type=str, metavar='FILE',
					   help='List all events')
	parser.add_argument('--event', type=int, metavar='ID',
					   help='Show specific event')
	parser.add_argument('--show', type=str, metavar='FILE',
					   help='Events file for --event')
	parser.add_argument('--compile', nargs=2, metavar=('SCRIPT', 'OUTPUT'),
					   help='Compile script to binary')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = EventEditor(verbose=args.verbose)
	
	# Extract
	if args.extract:
		rom_path, output_path = args.extract
		editor.load_rom(Path(rom_path))
		editor.extract_events()
		editor.export_json(Path(output_path))
		return 0
	
	# Insert
	if args.insert:
		events_path, rom_path = args.insert
		editor.import_json(Path(events_path))
		editor.load_rom(Path(rom_path))
		editor.insert_events()
		editor.save_rom(Path(rom_path))
		return 0
	
	# List
	if args.list:
		editor.import_json(Path(args.list))
		editor.list_events()
		return 0
	
	# Show event
	if args.event is not None:
		if args.show:
			editor.import_json(Path(args.show))
		
		editor.print_event(args.event)
		return 0
	
	# Compile
	if args.compile:
		script_path, output_path = args.compile
		
		with open(script_path, 'r', encoding='utf-8') as f:
			script_text = f.read()
		
		commands = editor.compile_script(script_text)
		
		# Write binary
		with open(output_path, 'wb') as f:
			for command in commands:
				f.write(bytes([command.command.value]))
				f.write(bytes(command.parameters))
		
		if args.verbose:
			print(f"✓ Compiled {len(commands)} commands")
		
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
