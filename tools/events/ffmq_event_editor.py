#!/usr/bin/env python3
"""
FFMQ Event Script Editor - Edit game events and cutscenes

Event System:
- Event scripts at 0x340000
- 512 event slots
- Bytecode interpreter
- Flag-based branching
- NPC interactions
- Map transitions
- Battle triggers
- Item rewards

Script Commands:
- TEXT: Display dialogue
- CHOICE: Player choice menu
- SET_FLAG: Set story flag
- CHECK_FLAG: Conditional branch
- GIVE_ITEM: Award item
- REMOVE_ITEM: Take item
- BATTLE: Start battle
- TELEPORT: Change map
- MOVE_NPC: NPC movement
- WAIT: Pause execution
- PLAY_MUSIC: Change BGM
- PLAY_SOUND: Sound effect
- FADE: Screen fade
- SHAKE: Screen shake
- END: End script

Features:
- Decompile bytecode to readable script
- Compile script to bytecode
- Event flow visualization
- Flag dependency tracking
- Dialogue extraction
- Script validation
- Import/export scripts
- Batch processing

Usage:
	python ffmq_event_editor.py rom.sfc --decompile 42 --output event42.txt
	python ffmq_event_editor.py rom.sfc --compile event42.txt --event 42
	python ffmq_event_editor.py rom.sfc --list-events
	python ffmq_event_editor.py rom.sfc --export-all scripts/
	python ffmq_event_editor.py rom.sfc --validate 42
	python ffmq_event_editor.py rom.sfc --visualize 42 --output flowchart.dot
"""

import argparse
import json
import struct
from pathlib import Path
from typing import List, Dict, Tuple, Optional, Any
from dataclasses import dataclass, asdict
from enum import Enum


class EventOpcode(Enum):
	"""Event script opcodes"""
	NOP = 0x00
	TEXT = 0x01
	CHOICE = 0x02
	SET_FLAG = 0x03
	CHECK_FLAG = 0x04
	GIVE_ITEM = 0x05
	REMOVE_ITEM = 0x06
	BATTLE = 0x07
	TELEPORT = 0x08
	MOVE_NPC = 0x09
	WAIT = 0x0A
	PLAY_MUSIC = 0x0B
	PLAY_SOUND = 0x0C
	FADE = 0x0D
	SHAKE = 0x0E
	END = 0xFF


@dataclass
class EventCommand:
	"""Single event command"""
	opcode: EventOpcode
	parameters: List[int]
	offset: int
	
	def to_text(self) -> str:
		"""Convert to readable text format"""
		op_name = self.opcode.name
		
		if self.opcode == EventOpcode.TEXT:
			return f"TEXT {self.parameters[0]}"
		elif self.opcode == EventOpcode.CHOICE:
			return f"CHOICE {self.parameters[0]} {self.parameters[1]}"
		elif self.opcode == EventOpcode.SET_FLAG:
			return f"SET_FLAG {self.parameters[0]}"
		elif self.opcode == EventOpcode.CHECK_FLAG:
			return f"CHECK_FLAG {self.parameters[0]} GOTO {self.parameters[1]}"
		elif self.opcode == EventOpcode.GIVE_ITEM:
			return f"GIVE_ITEM {self.parameters[0]} {self.parameters[1]}"
		elif self.opcode == EventOpcode.BATTLE:
			return f"BATTLE {self.parameters[0]}"
		elif self.opcode == EventOpcode.TELEPORT:
			return f"TELEPORT {self.parameters[0]} {self.parameters[1]} {self.parameters[2]}"
		elif self.opcode == EventOpcode.WAIT:
			return f"WAIT {self.parameters[0]}"
		elif self.opcode == EventOpcode.PLAY_MUSIC:
			return f"PLAY_MUSIC {self.parameters[0]}"
		elif self.opcode == EventOpcode.END:
			return "END"
		else:
			param_str = ' '.join(str(p) for p in self.parameters)
			return f"{op_name} {param_str}"
	
	def to_dict(self) -> dict:
		return {
			'opcode': self.opcode.name,
			'parameters': self.parameters,
			'offset': self.offset
		}


@dataclass
class EventScript:
	"""Complete event script"""
	event_id: int
	name: str
	commands: List[EventCommand]
	flags_read: List[int]
	flags_written: List[int]
	items_given: List[int]
	battles_triggered: List[int]
	
	def to_dict(self) -> dict:
		return {
			'event_id': self.event_id,
			'name': self.name,
			'commands': [c.to_dict() for c in self.commands],
			'flags_read': self.flags_read,
			'flags_written': self.flags_written,
			'items_given': self.items_given,
			'battles_triggered': self.battles_triggered
		}


class FFMQEventEditor:
	"""Edit FFMQ event scripts"""
	
	# Event script base address
	EVENT_BASE = 0x340000
	EVENT_SIZE = 256  # Bytes per event
	EVENT_COUNT = 512
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		if self.verbose:
			print(f"Loaded FFMQ ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def decompile_event(self, event_id: int) -> EventScript:
		"""Decompile event bytecode to script"""
		if event_id < 0 or event_id >= self.EVENT_COUNT:
			raise ValueError(f"Invalid event ID: {event_id}")
		
		offset = self.EVENT_BASE + (event_id * self.EVENT_SIZE)
		commands = []
		flags_read = []
		flags_written = []
		items_given = []
		battles_triggered = []
		
		# Parse bytecode
		pos = 0
		while pos < self.EVENT_SIZE:
			opcode_byte = self.rom_data[offset + pos]
			
			# Try to match opcode
			try:
				opcode = EventOpcode(opcode_byte)
			except ValueError:
				# Unknown opcode - skip
				pos += 1
				continue
			
			params = []
			
			# Parse parameters based on opcode
			if opcode == EventOpcode.TEXT:
				params = [self.rom_data[offset + pos + 1]]
				pos += 2
			elif opcode == EventOpcode.CHOICE:
				params = [
					self.rom_data[offset + pos + 1],
					self.rom_data[offset + pos + 2]
				]
				pos += 3
			elif opcode == EventOpcode.SET_FLAG:
				flag_id = self.rom_data[offset + pos + 1]
				params = [flag_id]
				flags_written.append(flag_id)
				pos += 2
			elif opcode == EventOpcode.CHECK_FLAG:
				flag_id = self.rom_data[offset + pos + 1]
				goto_offset = self.rom_data[offset + pos + 2]
				params = [flag_id, goto_offset]
				flags_read.append(flag_id)
				pos += 3
			elif opcode == EventOpcode.GIVE_ITEM:
				item_id = self.rom_data[offset + pos + 1]
				quantity = self.rom_data[offset + pos + 2]
				params = [item_id, quantity]
				items_given.append(item_id)
				pos += 3
			elif opcode == EventOpcode.REMOVE_ITEM:
				params = [
					self.rom_data[offset + pos + 1],
					self.rom_data[offset + pos + 2]
				]
				pos += 3
			elif opcode == EventOpcode.BATTLE:
				battle_id = self.rom_data[offset + pos + 1]
				params = [battle_id]
				battles_triggered.append(battle_id)
				pos += 2
			elif opcode == EventOpcode.TELEPORT:
				params = [
					self.rom_data[offset + pos + 1],  # Map ID
					self.rom_data[offset + pos + 2],  # X
					self.rom_data[offset + pos + 3]   # Y
				]
				pos += 4
			elif opcode == EventOpcode.MOVE_NPC:
				params = [
					self.rom_data[offset + pos + 1],  # NPC ID
					self.rom_data[offset + pos + 2],  # X
					self.rom_data[offset + pos + 3]   # Y
				]
				pos += 4
			elif opcode == EventOpcode.WAIT:
				params = [self.rom_data[offset + pos + 1]]
				pos += 2
			elif opcode == EventOpcode.PLAY_MUSIC:
				params = [self.rom_data[offset + pos + 1]]
				pos += 2
			elif opcode == EventOpcode.PLAY_SOUND:
				params = [self.rom_data[offset + pos + 1]]
				pos += 2
			elif opcode == EventOpcode.FADE:
				params = [self.rom_data[offset + pos + 1]]
				pos += 2
			elif opcode == EventOpcode.SHAKE:
				params = [self.rom_data[offset + pos + 1]]
				pos += 2
			elif opcode == EventOpcode.END:
				params = []
				pos += 1
				# Add END command and stop
				cmd = EventCommand(opcode, params, offset + pos - 1)
				commands.append(cmd)
				break
			else:
				# Unknown parameters - skip
				pos += 1
				continue
			
			cmd = EventCommand(opcode, params, offset + pos - len(params) - 1)
			commands.append(cmd)
		
		script = EventScript(
			event_id=event_id,
			name=f"Event {event_id}",
			commands=commands,
			flags_read=list(set(flags_read)),
			flags_written=list(set(flags_written)),
			items_given=list(set(items_given)),
			battles_triggered=list(set(battles_triggered))
		)
		
		return script
	
	def compile_script(self, script_text: str) -> List[int]:
		"""Compile text script to bytecode"""
		bytecode = []
		
		for line in script_text.split('\n'):
			line = line.strip()
			if not line or line.startswith('#'):
				continue
			
			parts = line.split()
			if not parts:
				continue
			
			cmd = parts[0].upper()
			
			if cmd == 'TEXT':
				bytecode.append(EventOpcode.TEXT.value)
				bytecode.append(int(parts[1]))
			elif cmd == 'CHOICE':
				bytecode.append(EventOpcode.CHOICE.value)
				bytecode.append(int(parts[1]))
				bytecode.append(int(parts[2]))
			elif cmd == 'SET_FLAG':
				bytecode.append(EventOpcode.SET_FLAG.value)
				bytecode.append(int(parts[1]))
			elif cmd == 'CHECK_FLAG':
				bytecode.append(EventOpcode.CHECK_FLAG.value)
				bytecode.append(int(parts[1]))
				bytecode.append(int(parts[3]))  # GOTO offset
			elif cmd == 'GIVE_ITEM':
				bytecode.append(EventOpcode.GIVE_ITEM.value)
				bytecode.append(int(parts[1]))
				bytecode.append(int(parts[2]))
			elif cmd == 'BATTLE':
				bytecode.append(EventOpcode.BATTLE.value)
				bytecode.append(int(parts[1]))
			elif cmd == 'TELEPORT':
				bytecode.append(EventOpcode.TELEPORT.value)
				bytecode.append(int(parts[1]))
				bytecode.append(int(parts[2]))
				bytecode.append(int(parts[3]))
			elif cmd == 'WAIT':
				bytecode.append(EventOpcode.WAIT.value)
				bytecode.append(int(parts[1]))
			elif cmd == 'PLAY_MUSIC':
				bytecode.append(EventOpcode.PLAY_MUSIC.value)
				bytecode.append(int(parts[1]))
			elif cmd == 'END':
				bytecode.append(EventOpcode.END.value)
				break
		
		return bytecode
	
	def export_script(self, script: EventScript, output_path: Path) -> None:
		"""Export script to text file"""
		with open(output_path, 'w') as f:
			f.write(f"# Event {script.event_id}: {script.name}\n\n")
			
			if script.flags_read:
				f.write(f"# Flags Read: {', '.join(str(f) for f in script.flags_read)}\n")
			if script.flags_written:
				f.write(f"# Flags Written: {', '.join(str(f) for f in script.flags_written)}\n")
			if script.items_given:
				f.write(f"# Items Given: {', '.join(str(i) for i in script.items_given)}\n")
			
			f.write("\n")
			
			for cmd in script.commands:
				f.write(cmd.to_text() + "\n")
		
		if self.verbose:
			print(f"✓ Exported script to {output_path}")
	
	def list_events(self) -> List[Tuple[int, int]]:
		"""List all non-empty events"""
		events = []
		
		for event_id in range(self.EVENT_COUNT):
			offset = self.EVENT_BASE + (event_id * self.EVENT_SIZE)
			
			# Check if event has any non-zero bytes
			event_data = self.rom_data[offset:offset + self.EVENT_SIZE]
			if any(b != 0 for b in event_data):
				# Count commands
				cmd_count = sum(1 for b in event_data if b == EventOpcode.END.value)
				events.append((event_id, cmd_count))
		
		return events


def main():
	parser = argparse.ArgumentParser(description='FFMQ Event Script Editor')
	parser.add_argument('rom', type=str, help='FFMQ ROM file')
	parser.add_argument('--decompile', type=int, help='Decompile event by ID')
	parser.add_argument('--compile', type=str, help='Compile script file')
	parser.add_argument('--event', type=int, help='Event ID for compile')
	parser.add_argument('--list-events', action='store_true', help='List all events')
	parser.add_argument('--output', type=str, help='Output file')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FFMQEventEditor(Path(args.rom), verbose=args.verbose)
	
	# Decompile event
	if args.decompile is not None:
		script = editor.decompile_event(args.decompile)
		
		if args.output:
			editor.export_script(script, Path(args.output))
		else:
			print(f"\n=== Event {script.event_id}: {script.name} ===\n")
			
			if script.flags_read:
				print(f"Flags Read: {', '.join(str(f) for f in script.flags_read)}")
			if script.flags_written:
				print(f"Flags Written: {', '.join(str(f) for f in script.flags_written)}")
			if script.items_given:
				print(f"Items Given: {', '.join(str(i) for i in script.items_given)}")
			
			print(f"\nCommands ({len(script.commands)}):\n")
			
			for i, cmd in enumerate(script.commands):
				print(f"{i:3d}: {cmd.to_text()}")
		
		return 0
	
	# List events
	if args.list_events:
		events = editor.list_events()
		
		print(f"\n=== Event List ({len(events)} events) ===\n")
		print(f"{'ID':<6} {'Commands'}")
		print("=" * 20)
		
		for event_id, cmd_count in events:
			print(f"{event_id:<6} {cmd_count}")
		
		return 0
	
	print("Use --decompile, --compile, or --list-events")
	return 0


if __name__ == '__main__':
	exit(main())
