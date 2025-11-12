#!/usr/bin/env python3
"""
FFMQ Event Script System
Handles event scripting commands, bytecode parsing, and script flow analysis
"""

from dataclasses import dataclass, field
from typing import Dict, List, Tuple, Optional, Set
from enum import IntEnum
import json


class CommandCategory(IntEnum):
	"""Event command categories"""
	DIALOG = 0x00
	FLOW = 0x10
	FLAGS = 0x20
	ITEMS = 0x30
	MAP = 0x40
	BATTLE = 0x50
	SPECIAL = 0x60


@dataclass
class CommandDefinition:
	"""Definition of an event command"""
	opcode: int
	name: str
	category: CommandCategory
	param_count: int
	param_names: List[str]
	param_types: List[str]  # 'byte', 'word', 'address', 'string'
	description: str
	flow_type: str = 'linear'  # 'linear', 'branch', 'jump', 'call', 'return', 'end'
	
	def format_params(self, params: List[int]) -> str:
		"""Format parameters for display"""
		if not params:
			return ""
		
		parts = []
		for i, (param, ptype) in enumerate(zip(params, self.param_types)):
			name = self.param_names[i] if i < len(self.param_names) else f"param{i}"
			
			if ptype == 'address':
				parts.append(f"{name}=@{param:04X}")
			elif ptype == 'word':
				parts.append(f"{name}={param:04X}")
			else:
				parts.append(f"{name}={param}")
		
		return ', '.join(parts)


@dataclass
class EventCommand:
	"""A single event command instance"""
	opcode: int
	name: str
	parameters: List[int]
	length: int
	address: int
	description: str
	flow_type: str
	definition: Optional[CommandDefinition] = None
	
	def __str__(self) -> str:
		"""String representation"""
		if self.definition:
			params_str = self.definition.format_params(self.parameters)
			return f"{self.name}({params_str})"
		else:
			params_str = ', '.join(f'{p:02X}' for p in self.parameters)
			return f"{self.name}({params_str})"
	
	def to_bytes(self) -> bytearray:
		"""Convert command back to bytecode"""
		data = bytearray([self.opcode])
		for param in self.parameters:
			# Determine if param is byte or word based on value
			if param > 0xFF:
				# 16-bit little-endian
				data.append(param & 0xFF)
				data.append((param >> 8) & 0xFF)
			else:
				data.append(param)
		return data


@dataclass
class EventScript:
	"""Complete event script"""
	id: int
	commands: List[EventCommand] = field(default_factory=list)
	entry_point: int = 0
	length: int = 0
	references: List[str] = field(default_factory=list)
	variables_used: Set[int] = field(default_factory=set)
	flags_set: Set[int] = field(default_factory=set)
	flags_checked: Set[int] = field(default_factory=set)
	dialogs_used: Set[int] = field(default_factory=set)
	items_used: Set[int] = field(default_factory=set)
	
	def __str__(self) -> str:
		"""String representation"""
		lines = [f"Event Script #{self.id} @ 0x{self.entry_point:06X}"]
		lines.append(f"  Commands: {len(self.commands)}")
		lines.append(f"  Length: {self.length} bytes")
		if self.flags_set:
			lines.append(f"  Flags Set: {sorted(self.flags_set)}")
		if self.flags_checked:
			lines.append(f"  Flags Checked: {sorted(self.flags_checked)}")
		return '\n'.join(lines)
	
	def to_bytecode(self) -> bytearray:
		"""Convert entire script to bytecode"""
		data = bytearray()
		for cmd in self.commands:
			data.extend(cmd.to_bytes())
		return data
	
	def to_dict(self) -> dict:
		"""Export to dictionary"""
		return {
			'id': self.id,
			'entry_point': f'0x{self.entry_point:06X}',
			'length': self.length,
			'commands': [
				{
					'address': f'0x{cmd.address:06X}',
					'opcode': f'0x{cmd.opcode:02X}',
					'name': cmd.name,
					'parameters': cmd.parameters,
					'flow_type': cmd.flow_type
				}
				for cmd in self.commands
			],
			'variables': {
				'flags_set': list(self.flags_set),
				'flags_checked': list(self.flags_checked),
				'dialogs': list(self.dialogs_used),
				'items': list(self.items_used)
			}
		}


class EventScriptEngine:
	"""Event script parser and generator"""
	
	def __init__(self):
		"""Initialize event script engine"""
		self.commands: Dict[int, CommandDefinition] = {}
		self._initialize_commands()
	
	def _initialize_commands(self):
		"""Initialize command definitions"""
		
		# Dialog Commands (0x00-0x0F)
		self._add_command(0x00, "SHOW_DIALOG", CommandCategory.DIALOG, 1, ['dialog_id'], ['byte'],
			"Display dialog by ID")
		self._add_command(0x01, "CHOICE_2", CommandCategory.DIALOG, 2, ['option1', 'option2'], ['byte', 'byte'],
			"2-choice menu")
		self._add_command(0x02, "CHOICE_3", CommandCategory.DIALOG, 3, ['opt1', 'opt2', 'opt3'], ['byte', 'byte', 'byte'],
			"3-choice menu")
		self._add_command(0x03, "SHOW_TEXT", CommandCategory.DIALOG, 2, ['text_ptr'], ['word'],
			"Show text at pointer")
		
		# Flow Control (0x10-0x1F)
		self._add_command(0x10, "JUMP", CommandCategory.FLOW, 2, ['address'], ['word'],
			"Unconditional jump", flow_type='jump')
		self._add_command(0x11, "CALL", CommandCategory.FLOW, 2, ['address'], ['word'],
			"Call subroutine", flow_type='call')
		self._add_command(0x12, "RETURN", CommandCategory.FLOW, 0, [], [],
			"Return from subroutine", flow_type='return')
		self._add_command(0x13, "IF_FLAG", CommandCategory.FLOW, 3, ['flag', 'address'], ['byte', 'word'],
			"Jump if flag set", flow_type='branch')
		self._add_command(0x14, "IF_NOT_FLAG", CommandCategory.FLOW, 3, ['flag', 'address'], ['byte', 'word'],
			"Jump if flag clear", flow_type='branch')
		self._add_command(0x15, "IF_ITEM", CommandCategory.FLOW, 3, ['item', 'address'], ['byte', 'word'],
			"Jump if player has item", flow_type='branch')
		self._add_command(0x16, "IF_NOT_ITEM", CommandCategory.FLOW, 3, ['item', 'address'], ['byte', 'word'],
			"Jump if player lacks item", flow_type='branch')
		self._add_command(0x17, "IF_GP_GREATER", CommandCategory.FLOW, 4, ['amount', 'address'], ['word', 'word'],
			"Jump if GP >= amount", flow_type='branch')
		
		# Flag/Variable Operations (0x20-0x2F)
		self._add_command(0x20, "SET_FLAG", CommandCategory.FLAGS, 1, ['flag_id'], ['byte'],
			"Set game flag")
		self._add_command(0x21, "CLEAR_FLAG", CommandCategory.FLAGS, 1, ['flag_id'], ['byte'],
			"Clear game flag")
		self._add_command(0x22, "SET_VAR", CommandCategory.FLAGS, 2, ['var_id', 'value'], ['byte', 'byte'],
			"Set variable")
		self._add_command(0x23, "ADD_VAR", CommandCategory.FLAGS, 2, ['var_id', 'amount'], ['byte', 'byte'],
			"Add to variable")
		self._add_command(0x24, "SUB_VAR", CommandCategory.FLAGS, 2, ['var_id', 'amount'], ['byte', 'byte'],
			"Subtract from variable")
		self._add_command(0x25, "TOGGLE_FLAG", CommandCategory.FLAGS, 1, ['flag_id'], ['byte'],
			"Toggle flag state")
		
		# Item/Party Commands (0x30-0x3F)
		self._add_command(0x30, "GIVE_ITEM", CommandCategory.ITEMS, 2, ['item_id', 'count'], ['byte', 'byte'],
			"Give item to player")
		self._add_command(0x31, "TAKE_ITEM", CommandCategory.ITEMS, 2, ['item_id', 'count'], ['byte', 'byte'],
			"Remove item from player")
		self._add_command(0x32, "GIVE_GP", CommandCategory.ITEMS, 2, ['amount'], ['word'],
			"Give gold")
		self._add_command(0x33, "TAKE_GP", CommandCategory.ITEMS, 2, ['amount'], ['word'],
			"Take gold")
		self._add_command(0x34, "GIVE_EXP", CommandCategory.ITEMS, 2, ['amount'], ['word'],
			"Give experience")
		self._add_command(0x35, "GIVE_WEAPON", CommandCategory.ITEMS, 1, ['weapon_id'], ['byte'],
			"Give weapon")
		self._add_command(0x36, "GIVE_ARMOR", CommandCategory.ITEMS, 1, ['armor_id'], ['byte'],
			"Give armor")
		self._add_command(0x37, "RESTORE_HP", CommandCategory.ITEMS, 0, [], [],
			"Restore full HP")
		
		# Map/Character Commands (0x40-0x4F)
		self._add_command(0x40, "WARP", CommandCategory.MAP, 3, ['map_id', 'x', 'y'], ['byte', 'byte', 'byte'],
			"Teleport to map")
		self._add_command(0x41, "MOVE_NPC", CommandCategory.MAP, 3, ['npc_id', 'x', 'y'], ['byte', 'byte', 'byte'],
			"Move NPC to position")
		self._add_command(0x42, "HIDE_NPC", CommandCategory.MAP, 1, ['npc_id'], ['byte'],
			"Hide NPC")
		self._add_command(0x43, "SHOW_NPC", CommandCategory.MAP, 1, ['npc_id'], ['byte'],
			"Show NPC")
		self._add_command(0x44, "FACE_DIRECTION", CommandCategory.MAP, 1, ['direction'], ['byte'],
			"Turn character (0=up, 1=right, 2=down, 3=left)")
		self._add_command(0x45, "WALK_PATH", CommandCategory.MAP, 2, ['path_id'], ['word'],
			"Walk predefined path")
		self._add_command(0x46, "SET_SPRITE", CommandCategory.MAP, 2, ['npc_id', 'sprite'], ['byte', 'byte'],
			"Change NPC sprite")
		
		# Battle/Effect Commands (0x50-0x5F)
		self._add_command(0x50, "START_BATTLE", CommandCategory.BATTLE, 1, ['enemy_id'], ['byte'],
			"Start battle")
		self._add_command(0x51, "PLAY_SOUND", CommandCategory.BATTLE, 1, ['sound_id'], ['byte'],
			"Play sound effect")
		self._add_command(0x52, "PLAY_MUSIC", CommandCategory.BATTLE, 1, ['music_id'], ['byte'],
			"Change music")
		self._add_command(0x53, "FLASH_SCREEN", CommandCategory.BATTLE, 2, ['color', 'duration'], ['byte', 'byte'],
			"Screen flash")
		self._add_command(0x54, "SHAKE_SCREEN", CommandCategory.BATTLE, 1, ['duration'], ['byte'],
			"Screen shake")
		self._add_command(0x55, "FADE_OUT", CommandCategory.BATTLE, 0, [], [],
			"Fade screen to black")
		self._add_command(0x56, "FADE_IN", CommandCategory.BATTLE, 0, [], [],
			"Fade screen from black")
		
		# Special Commands (0x60-0xFF)
		self._add_command(0x60, "SAVE_GAME", CommandCategory.SPECIAL, 0, [], [],
			"Open save menu")
		self._add_command(0x61, "GAME_OVER", CommandCategory.SPECIAL, 0, [], [],
			"Game over screen")
		self._add_command(0x62, "CREDITS", CommandCategory.SPECIAL, 0, [], [],
			"Roll credits")
		self._add_command(0x63, "WAIT", CommandCategory.SPECIAL, 1, ['frames'], ['byte'],
			"Wait specified frames")
		self._add_command(0x64, "WAIT_MOVE", CommandCategory.SPECIAL, 0, [], [],
			"Wait for movement to complete")
		self._add_command(0x65, "LOCK_PLAYER", CommandCategory.SPECIAL, 0, [], [],
			"Disable player control")
		self._add_command(0x66, "UNLOCK_PLAYER", CommandCategory.SPECIAL, 0, [], [],
			"Enable player control")
		
		self._add_command(0xFF, "END_SCRIPT", CommandCategory.SPECIAL, 0, [], [],
			"End event script", flow_type='end')
	
	def _add_command(self, opcode: int, name: str, category: CommandCategory,
		param_count: int, param_names: List[str], param_types: List[str],
		description: str, flow_type: str = 'linear'):
		"""Add a command definition"""
		cmd_def = CommandDefinition(
			opcode=opcode,
			name=name,
			category=category,
			param_count=param_count,
			param_names=param_names,
			param_types=param_types,
			description=description,
			flow_type=flow_type
		)
		self.commands[opcode] = cmd_def
	
	def parse_bytecode(self, data: bytes, start_address: int = 0) -> EventScript:
		"""
		Parse event script bytecode
		
		Args:
			data: Raw bytecode
			start_address: Starting ROM address (for display)
			
		Returns:
			EventScript object
		"""
		script = EventScript(id=0, entry_point=start_address)
		
		offset = 0
		
		while offset < len(data):
			# Read opcode
			opcode = data[offset]
			cmd_address = start_address + offset
			offset += 1
			
			# Get command definition
			cmd_def = self.commands.get(opcode)
			
			if cmd_def is None:
				# Unknown command - skip
				cmd = EventCommand(
					opcode=opcode,
					name=f"UNKNOWN_{opcode:02X}",
					parameters=[],
					length=1,
					address=cmd_address,
					description=f"Unknown opcode 0x{opcode:02X}",
					flow_type='linear'
				)
				script.commands.append(cmd)
				
				# Stop at unknown command
				break
			
			# Read parameters
			params = []
			for ptype in cmd_def.param_types:
				if ptype == 'word' or ptype == 'address':
					# 16-bit little-endian
					if offset + 2 <= len(data):
						low = data[offset]
						high = data[offset + 1]
						params.append((high << 8) | low)
						offset += 2
				else:  # byte
					if offset < len(data):
						params.append(data[offset])
						offset += 1
			
			# Create command
			cmd_length = 1 + len(cmd_def.param_types)  # Approximation
			cmd = EventCommand(
				opcode=opcode,
				name=cmd_def.name,
				parameters=params,
				length=cmd_length,
				address=cmd_address,
				description=cmd_def.description,
				flow_type=cmd_def.flow_type,
				definition=cmd_def
			)
			
			script.commands.append(cmd)
			
			# Track variables used
			if cmd.name == "SET_FLAG":
				script.flags_set.add(params[0])
			elif cmd.name == "CLEAR_FLAG":
				script.flags_set.add(params[0])
			elif cmd.name in ("IF_FLAG", "IF_NOT_FLAG"):
				script.flags_checked.add(params[0])
			elif cmd.name == "SHOW_DIALOG":
				script.dialogs_used.add(params[0])
			elif cmd.name in ("GIVE_ITEM", "TAKE_ITEM", "IF_ITEM", "IF_NOT_ITEM"):
				script.items_used.add(params[0])
			
			# Stop at end
			if cmd.flow_type == 'end':
				break
		
		script.length = offset
		return script
	
	def generate_bytecode(self, script: EventScript) -> bytearray:
		"""
		Generate bytecode from script
		
		Args:
			script: EventScript to convert
			
		Returns:
			Bytecode ready for ROM
		"""
		return script.to_bytecode()
	
	def validate_script(self, script: EventScript) -> Tuple[bool, List[str]]:
		"""
		Validate event script
		
		Args:
			script: Script to validate
			
		Returns:
			Tuple of (is_valid, list_of_errors)
		"""
		errors = []
		
		# Check for empty script
		if not script.commands:
			errors.append("Script is empty")
			return False, errors
		
		# Check for END_SCRIPT
		has_end = any(cmd.flow_type == 'end' for cmd in script.commands)
		if not has_end:
			errors.append("Script missing END_SCRIPT command")
		
		# Check for invalid jumps
		for cmd in script.commands:
			if cmd.flow_type in ('jump', 'branch', 'call'):
				# Get target address from parameters
				if cmd.parameters:
					target = cmd.parameters[-1]  # Last param is usually address
					
					# Check if target is within script bounds
					# (This is approximate without full ROM context)
					if target < script.entry_point or target > script.entry_point + script.length + 1000:
						errors.append(f"{cmd.name} at 0x{cmd.address:06X} has suspicious target: 0x{target:04X}")
		
		# Check for unreachable code
		for i, cmd in enumerate(script.commands):
			if cmd.flow_type == 'end' and i < len(script.commands) - 1:
				errors.append(f"Unreachable code after {cmd.name} at 0x{cmd.address:06X}")
				break
		
		is_valid = len(errors) == 0
		return is_valid, errors
	
	def disassemble(self, script: EventScript) -> str:
		"""
		Disassemble script to readable text
		
		Args:
			script: Script to disassemble
			
		Returns:
			Human-readable script listing
		"""
		lines = []
		lines.append(f"; Event Script #{script.id}")
		lines.append(f"; Entry Point: 0x{script.entry_point:06X}")
		lines.append(f"; Length: {script.length} bytes")
		lines.append("")
		
		for cmd in script.commands:
			# Format: @ADDRESS: COMMAND(params)  ; description
			addr_str = f"@{cmd.address:06X}:"
			cmd_str = str(cmd)
			comment = f"; {cmd.description}"
			
			lines.append(f"{addr_str:12} {cmd_str:30} {comment}")
		
		return '\n'.join(lines)
	
	def get_command_by_name(self, name: str) -> Optional[CommandDefinition]:
		"""Get command definition by name"""
		for cmd_def in self.commands.values():
			if cmd_def.name == name:
				return cmd_def
		return None
	
	def get_commands_by_category(self, category: CommandCategory) -> List[CommandDefinition]:
		"""Get all commands in a category"""
		return [cmd for cmd in self.commands.values() if cmd.category == category]


# Example usage
if __name__ == '__main__':
	# Create engine
	engine = EventScriptEngine()
	
	# Example bytecode (hypothetical)
	example_bytecode = bytearray([
		0x00, 0x2D,			  # SHOW_DIALOG(45)
		0x01, 0x01, 0x02,		# CHOICE_2(1, 2)
		0x13, 0x0A, 0x20, 0x00,  # IF_FLAG(10, @0020)
		0x30, 0x05, 0x01,		# GIVE_ITEM(5, 1)
		0x20, 0x0A,			  # SET_FLAG(10)
		0x10, 0x00, 0x00,		# JUMP(@0000)
		0x00, 0x2E,			  # SHOW_DIALOG(46)
		0xFF					 # END_SCRIPT
	])
	
	# Parse
	script = engine.parse_bytecode(example_bytecode, start_address=0x2F456)
	
	print(script)
	print()
	
	# Disassemble
	print("Disassembly:")
	print(engine.disassemble(script))
	print()
	
	# Validate
	is_valid, errors = engine.validate_script(script)
	print(f"Valid: {is_valid}")
	if errors:
		print("Errors:")
		for error in errors:
			print(f"  - {error}")
	print()
	
	# Show command categories
	print("Available command categories:")
	for category in CommandCategory:
		commands = engine.get_commands_by_category(category)
		print(f"  {category.name}: {len(commands)} commands")
