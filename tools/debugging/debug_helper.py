#!/usr/bin/env python3
"""
Debug Helper - Interactive debugging and inspection for event scripts
Debug ROM execution, trace script flow, inspect memory state

Features:
- Breakpoint system
- Step-through execution
- Memory inspection
- Register viewing
- Call stack tracking
- Flag state monitoring
- Variable watching
- Trace logging

Debugging Modes:
- Interactive: Step through with commands
- Trace: Log all executed commands
- Watch: Monitor specific flags/variables
- Breakpoint: Stop at specific conditions

Inspection Features:
- View current instruction
- Examine memory addresses
- Check flag states
- Display call stack
- Show variable values
- Trace execution history

Commands:
- step: Execute next instruction
- continue: Run until breakpoint
- break: Set breakpoint
- watch: Watch variable/flag
- print: Show value
- backtrace: Display call stack
- info: Show current state

Usage:
	python debug_helper.py script.bin --interactive
	python debug_helper.py script.bin --trace --output trace.log
	python debug_helper.py script.bin --watch 0x1000 --watch flag_42
	python debug_helper.py script.bin --break CALL --break line:50
"""

import argparse
import struct
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple, Any
from dataclasses import dataclass, field
from collections import deque
from enum import Enum
import json


class BreakpointType(Enum):
	"""Breakpoint types"""
	COMMAND = "command"
	LINE = "line"
	ADDRESS = "address"
	FLAG = "flag"
	VARIABLE = "variable"


@dataclass
class Breakpoint:
	"""A debugger breakpoint"""
	bp_type: BreakpointType
	condition: Any
	enabled: bool = True
	hit_count: int = 0


@dataclass
class WatchPoint:
	"""A variable/flag watch"""
	name: str
	address: Optional[int] = None
	flag_id: Optional[int] = None
	last_value: Optional[Any] = None


@dataclass
class ExecutionState:
	"""Current execution state"""
	program_counter: int
	line_number: int
	current_command: str
	parameters: List[Any]
	flags: Dict[int, bool] = field(default_factory=dict)
	variables: Dict[int, int] = field(default_factory=dict)
	call_stack: List[int] = field(default_factory=list)


@dataclass
class TraceEntry:
	"""Execution trace entry"""
	timestamp: int
	line_number: int
	command: str
	parameters: List[Any]
	state_changes: Dict[str, Any] = field(default_factory=dict)


class DebugHelper:
	"""Interactive debugger for event scripts"""

	# Command opcodes
	OPCODES = {
		0x00: 'END',
		0x01: 'WAIT',
		0x02: 'NEWLINE',
		0x03: 'SET_FLAG',
		0x04: 'CLEAR_FLAG',
		0x05: 'CHECK_FLAG',
		0x06: 'BRANCH',
		0x07: 'JUMP',
		0x08: 'CALL',
		0x09: 'RETURN',
		0x0A: 'DELAY',
		0x20: 'MEMORY_WRITE',
		0x2A: 'VARIABLE_SET',
		0x2B: 'VARIABLE_ADD',
		0x2C: 'VARIABLE_CHECK',
	}

	def __init__(self, script_data: bytes, verbose: bool = False):
		self.script_data = script_data
		self.verbose = verbose
		self.state = ExecutionState(
			program_counter=0,
			line_number=1,
			current_command='',
			parameters=[]
		)
		self.breakpoints: List[Breakpoint] = []
		self.watchpoints: List[WatchPoint] = []
		self.trace: List[TraceEntry] = []
		self.running = True
		self.step_mode = False
		self.trace_mode = False

	def fetch_instruction(self) -> Tuple[str, List[Any]]:
		"""Fetch next instruction"""
		if self.state.program_counter >= len(self.script_data):
			return ('END', [])

		opcode = self.script_data[self.state.program_counter]
		command = self.OPCODES.get(opcode, f'UNKNOWN_{opcode:02X}')

		params = []
		pc = self.state.program_counter + 1

		# Parse parameters based on command
		if command in ('SET_FLAG', 'CLEAR_FLAG', 'CHECK_FLAG'):
			if pc + 1 < len(self.script_data):
				flag_id = struct.unpack_from('<H', self.script_data, pc)[0]
				params.append(flag_id)
				pc += 2

		elif command == 'DELAY':
			if pc < len(self.script_data):
				frames = self.script_data[pc]
				params.append(frames)
				pc += 1

		elif command in ('CALL', 'JUMP', 'BRANCH'):
			if pc + 2 < len(self.script_data):
				# Address (bank/offset)
				bank = self.script_data[pc]
				offset = struct.unpack_from('<H', self.script_data, pc + 1)[0]
				params.append(f"0x{bank:02X}/{offset:04X}")
				pc += 3

		elif command in ('VARIABLE_SET', 'VARIABLE_ADD', 'VARIABLE_CHECK'):
			if pc + 3 < len(self.script_data):
				addr = struct.unpack_from('<H', self.script_data, pc)[0]
				value = struct.unpack_from('<H', self.script_data, pc + 2)[0]
				params.append(addr)
				params.append(value)
				pc += 4

		elif command == 'MEMORY_WRITE':
			if pc + 2 < len(self.script_data):
				addr = struct.unpack_from('<H', self.script_data, pc)[0]
				value = self.script_data[pc + 2]
				params.append(addr)
				params.append(value)
				pc += 3

		return (command, params)

	def execute_instruction(self, command: str, params: List[Any]) -> None:
		"""Execute instruction and update state"""
		state_changes = {}

		if command == 'SET_FLAG' and params:
			flag_id = params[0]
			self.state.flags[flag_id] = True
			state_changes['flag'] = (flag_id, True)

		elif command == 'CLEAR_FLAG' and params:
			flag_id = params[0]
			self.state.flags[flag_id] = False
			state_changes['flag'] = (flag_id, False)

		elif command == 'VARIABLE_SET' and len(params) >= 2:
			addr, value = params[0], params[1]
			self.state.variables[addr] = value
			state_changes['variable'] = (addr, value)

		elif command == 'VARIABLE_ADD' and len(params) >= 2:
			addr, value = params[0], params[1]
			current = self.state.variables.get(addr, 0)
			self.state.variables[addr] = current + value
			state_changes['variable'] = (addr, current + value)

		elif command == 'CALL' and params:
			# Push return address
			self.state.call_stack.append(self.state.program_counter)
			state_changes['call'] = params[0]

		elif command == 'RETURN':
			if self.state.call_stack:
				return_addr = self.state.call_stack.pop()
				self.state.program_counter = return_addr
				state_changes['return'] = return_addr

		elif command == 'END':
			self.running = False

		# Record trace
		if self.trace_mode:
			entry = TraceEntry(
				timestamp=len(self.trace),
				line_number=self.state.line_number,
				command=command,
				parameters=params,
				state_changes=state_changes
			)
			self.trace.append(entry)

		# Check watchpoints
		for watch in self.watchpoints:
			if watch.flag_id is not None:
				current_value = self.state.flags.get(watch.flag_id, False)
				if current_value != watch.last_value:
					print(f"Watch: {watch.name} changed to {current_value}")
					watch.last_value = current_value

			elif watch.address is not None:
				current_value = self.state.variables.get(watch.address, 0)
				if current_value != watch.last_value:
					print(f"Watch: {watch.name} changed to {current_value}")
					watch.last_value = current_value

	def check_breakpoints(self, command: str) -> bool:
		"""Check if breakpoint hit"""
		for bp in self.breakpoints:
			if not bp.enabled:
				continue

			hit = False

			if bp.bp_type == BreakpointType.COMMAND:
				hit = (command == bp.condition)
			elif bp.bp_type == BreakpointType.LINE:
				hit = (self.state.line_number == bp.condition)
			elif bp.bp_type == BreakpointType.ADDRESS:
				hit = (self.state.program_counter == bp.condition)

			if hit:
				bp.hit_count += 1
				return True

		return False

	def run(self, interactive: bool = False) -> None:
		"""Run debugger"""
		self.step_mode = interactive

		while self.running and self.state.program_counter < len(self.script_data):
			# Fetch instruction
			command, params = self.fetch_instruction()
			self.state.current_command = command
			self.state.parameters = params

			# Check breakpoints
			if self.check_breakpoints(command):
				print(f"\nBreakpoint hit at line {self.state.line_number}")
				self.step_mode = True

			# Interactive mode
			if self.step_mode:
				self.show_current_state()

				while True:
					user_input = input("\n(debug) ").strip().lower()

					if user_input in ('s', 'step', ''):
						break
					elif user_input in ('c', 'continue'):
						self.step_mode = False
						break
					elif user_input.startswith('b '):
						# Set breakpoint
						parts = user_input.split()
						if len(parts) >= 2:
							self.add_breakpoint(parts[1])
					elif user_input.startswith('w '):
						# Add watch
						parts = user_input.split()
						if len(parts) >= 2:
							self.add_watch(parts[1])
					elif user_input.startswith('p '):
						# Print value
						parts = user_input.split()
						if len(parts) >= 2:
							self.print_value(parts[1])
					elif user_input in ('bt', 'backtrace'):
						self.show_backtrace()
					elif user_input in ('i', 'info'):
						self.show_current_state()
					elif user_input in ('q', 'quit'):
						self.running = False
						return
					elif user_input in ('h', 'help'):
						self.show_help()
					else:
						print(f"Unknown command: {user_input}")

			# Execute instruction
			self.execute_instruction(command, params)

			# Advance PC
			if command != 'RETURN':  # RETURN sets PC
				# Calculate instruction size
				inst_size = 1  # Opcode
				if command in ('SET_FLAG', 'CLEAR_FLAG', 'CHECK_FLAG'):
					inst_size += 2
				elif command == 'DELAY':
					inst_size += 1
				elif command in ('CALL', 'JUMP', 'BRANCH'):
					inst_size += 3
				elif command in ('VARIABLE_SET', 'VARIABLE_ADD', 'VARIABLE_CHECK'):
					inst_size += 4
				elif command == 'MEMORY_WRITE':
					inst_size += 3

				self.state.program_counter += inst_size

			self.state.line_number += 1

	def show_current_state(self) -> None:
		"""Display current execution state"""
		print(f"\nLine {self.state.line_number}: {self.state.current_command}", end='')
		if self.state.parameters:
			print(f" {', '.join(str(p) for p in self.state.parameters)}", end='')
		print()
		print(f"PC: 0x{self.state.program_counter:06X}")
		print(f"Stack depth: {len(self.state.call_stack)}")

	def show_backtrace(self) -> None:
		"""Show call stack"""
		print("\nCall stack:")
		for i, addr in enumerate(reversed(self.state.call_stack)):
			print(f"  #{i}: 0x{addr:06X}")

	def print_value(self, expr: str) -> None:
		"""Print value of expression"""
		if expr.startswith('flag_'):
			try:
				flag_id = int(expr[5:])
				value = self.state.flags.get(flag_id, False)
				print(f"{expr} = {value}")
			except ValueError:
				print(f"Invalid flag: {expr}")

		elif expr.startswith('var_'):
			try:
				addr = int(expr[4:], 0)
				value = self.state.variables.get(addr, 0)
				print(f"{expr} = {value}")
			except ValueError:
				print(f"Invalid variable: {expr}")

		elif expr.startswith('0x'):
			try:
				addr = int(expr, 16)
				value = self.state.variables.get(addr, 0)
				print(f"[{expr}] = {value}")
			except ValueError:
				print(f"Invalid address: {expr}")

	def add_breakpoint(self, condition: str) -> None:
		"""Add breakpoint"""
		if condition.startswith('line:'):
			line_num = int(condition[5:])
			bp = Breakpoint(BreakpointType.LINE, line_num)
			self.breakpoints.append(bp)
			print(f"Breakpoint set at line {line_num}")
		else:
			# Command breakpoint
			bp = Breakpoint(BreakpointType.COMMAND, condition.upper())
			self.breakpoints.append(bp)
			print(f"Breakpoint set on command {condition.upper()}")

	def add_watch(self, expr: str) -> None:
		"""Add watchpoint"""
		if expr.startswith('flag_'):
			flag_id = int(expr[5:])
			watch = WatchPoint(name=expr, flag_id=flag_id)
			self.watchpoints.append(watch)
			print(f"Watching {expr}")
		elif expr.startswith('0x'):
			addr = int(expr, 16)
			watch = WatchPoint(name=expr, address=addr)
			self.watchpoints.append(watch)
			print(f"Watching {expr}")

	def show_help(self) -> None:
		"""Show help"""
		print("""
Debug Commands:
  s, step          - Execute next instruction
  c, continue      - Continue execution
  b <cond>         - Set breakpoint (e.g., 'b CALL' or 'b line:10')
  w <expr>         - Watch variable (e.g., 'w flag_42' or 'w 0x1000')
  p <expr>         - Print value (e.g., 'p flag_42' or 'p var_0x1000')
  bt, backtrace    - Show call stack
  i, info          - Show current state
  h, help          - Show this help
  q, quit          - Quit debugger
""")

	def export_trace(self, output_path: Path) -> None:
		"""Export execution trace"""
		data = {
			"total_steps": len(self.trace),
			"trace": [
				{
					"timestamp": entry.timestamp,
					"line": entry.line_number,
					"command": entry.command,
					"parameters": entry.parameters,
					"changes": entry.state_changes
				}
				for entry in self.trace
			]
		}

		with open(output_path, 'w') as f:
			json.dump(data, f, indent=2)


def main():
	parser = argparse.ArgumentParser(description='Debug event scripts')
	parser.add_argument('script', type=Path, help='Compiled script file')
	parser.add_argument('--interactive', action='store_true', help='Interactive debugging mode')
	parser.add_argument('--trace', action='store_true', help='Enable trace logging')
	parser.add_argument('--output', type=Path, help='Trace output file')
	parser.add_argument('--watch', action='append', help='Add watchpoint')
	parser.add_argument('--break', dest='breakpoint', action='append', help='Add breakpoint')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')

	args = parser.parse_args()

	# Load script
	with open(args.script, 'rb') as f:
		script_data = f.read()

	# Create debugger
	debugger = DebugHelper(script_data, verbose=args.verbose)

	# Enable trace mode
	if args.trace:
		debugger.trace_mode = True

	# Add watchpoints
	if args.watch:
		for watch in args.watch:
			debugger.add_watch(watch)

	# Add breakpoints
	if args.breakpoint:
		for bp in args.breakpoint:
			debugger.add_breakpoint(bp)

	# Run debugger
	print(f"Debugging {args.script}")
	print(f"Script size: {len(script_data)} bytes")

	if args.interactive:
		print("\nInteractive mode - type 'h' for help")

	debugger.run(interactive=args.interactive)

	# Export trace
	if args.output and debugger.trace:
		debugger.export_trace(args.output)
		print(f"\n✓ Trace exported to {args.output}")
		print(f"  Total steps: {len(debugger.trace)}")

	return 0


if __name__ == '__main__':
	exit(main())
