#!/usr/bin/env python3
"""
FFMQ Event Script Decompiler
=============================

Decompiles FFMQ event scripts from ROM format to human-readable format.
Reverse operation of enhanced_dialog_compiler.py.

Features:
---------
1. **Full Command Recognition** - All 48 event commands (0x00-0x2F)
2. **Parameter Type Detection** - Auto-detects parameter types (addresses, items, spells, etc.)
3. **Control Flow Analysis** - Maps subroutine calls and branches
4. **Memory Operation Detection** - Identifies memory writes and flag operations
5. **Text Extraction** - Decodes dialog text with proper formatting
6. **Annotation** - Adds helpful comments explaining command purposes

Output Format:
--------------
```
; ========================================
; Event Script 0 - Dialog at 0xC0/8FA0
; ========================================
; Total size: 42 bytes
; Commands: 8
; Referenced by: 3 other scripts

[DIALOG 0]
; Textbox positioning
@TEXTBOX_BOTTOM

; Dialog text with formatting
Welcome to Final Fantasy Mystic Quest!
[NEWLINE]
What is your name?
[NAME]
[WAIT]

; Memory operations (quest flag)
[MEMORY_WRITE:0x1A50:0x0001]	; Set quest flag $1A50 = 1

; Control flow
[CALL_SUBROUTINE:0x9120]	; -> Common greeting subroutine
[END]
```

Author: TheAnsarya
Date: 2025-11-12
License: MIT
"""

import struct
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Set, Any
from dataclasses import dataclass, field
from enum import Enum


class ParameterType(Enum):
	"""Parameter type for annotation."""
	BYTE_VALUE = "byte"
	ITEM_ID = "item"
	SPELL_ID = "spell"
	MONSTER_ID = "monster"
	CHARACTER_ID = "character"
	LOCATION_ID = "location"
	CRYSTAL_ID = "crystal"
	MODE_VALUE = "mode"
	MEMORY_ADDRESS = "address"
	ROM_POINTER = "pointer"
	FLAG_MASK = "flag"
	UNKNOWN = "unknown"


@dataclass
class DecompiledCommand:
	"""Represents a decompiled event command."""
	offset: int
	opcode: int
	name: str
	parameters: List[int] = field(default_factory=list)
	param_types: List[ParameterType] = field(default_factory=list)
	size: int = 1
	annotation: str = ""

	def to_script(self, show_offsets: bool = False) -> str:
		"""Convert to human-readable script line."""
		prefix = f"0x{self.offset:04X}: " if show_offsets else ""

		if not self.parameters:
			line = f"{prefix}[{self.name}]"
		else:
			# Format parameters based on type
			formatted_params = []
			i = 0
			while i < len(self.parameters):
				ptype = self.param_types[i] if i < len(self.param_types) else ParameterType.UNKNOWN

				if ptype in [ParameterType.MEMORY_ADDRESS, ParameterType.ROM_POINTER]:
					# 16-bit value (little-endian)
					if i + 1 < len(self.parameters):
						value = self.parameters[i] | (self.parameters[i + 1] << 8)
						formatted_params.append(f"0x{value:04X}")
						i += 2
					else:
						formatted_params.append(f"0x{self.parameters[i]:02X}")
						i += 1
				else:
					# 8-bit value
					formatted_params.append(f"0x{self.parameters[i]:02X}")
					i += 1

			line = f"{prefix}[{self.name}:{':'.join(formatted_params)}]"

		if self.annotation:
			line += f"\t; {self.annotation}"

		return line


@dataclass
class DecompiledScript:
	"""Represents a complete decompiled event script."""
	script_id: int
	start_offset: int
	commands: List[DecompiledCommand] = field(default_factory=list)
	text_segments: List[Tuple[int, str]] = field(default_factory=list)	# (offset, text)
	total_size: int = 0
	subroutine_calls: List[int] = field(default_factory=list)	# Target addresses
	memory_writes: List[Tuple[int, int]] = field(default_factory=list)	# (address, value)
	references: List[int] = field(default_factory=list)	# Scripts that call this one


class EventScriptDecompiler:
	"""
	Decompiler for FFMQ event scripts with full 48-command support.
	"""

	# All 48 event commands with parameter information
	# (opcode: (name, param_count, param_types))
	COMMANDS = {
		# Basic operations (0x00-0x06)
		0x00: ('END', 0, []),
		0x01: ('NEWLINE', 0, []),
		0x02: ('WAIT', 0, []),
		0x03: ('ASTERISK', 0, []),
		0x04: ('NAME', 0, []),
		0x05: ('ITEM', 1, [ParameterType.BYTE_VALUE]),
		0x06: ('SPACE', 0, []),

		# Complex operations (0x07-0x0F)
		0x07: ('UNK_07', 3, [ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE]),
		0x08: ('CALL_SUBROUTINE', 2, [ParameterType.ROM_POINTER]),
		0x09: ('UNK_09', 3, [ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE]),
		0x0A: ('UNK_0A', 0, []),
		0x0B: ('UNK_0B', 1, [ParameterType.BYTE_VALUE]),
		0x0C: ('UNK_0C', 3, [ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE]),
		0x0D: ('UNK_0D', 4, [ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE]),
		0x0E: ('MEMORY_WRITE', 4, [ParameterType.MEMORY_ADDRESS, ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE]),
		0x0F: ('UNK_0F', 2, [ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE]),

		# Dynamic insertion (0x10-0x19)
		0x10: ('INSERT_ITEM', 1, [ParameterType.ITEM_ID]),
		0x11: ('INSERT_SPELL', 1, [ParameterType.SPELL_ID]),
		0x12: ('INSERT_MONSTER', 1, [ParameterType.MONSTER_ID]),
		0x13: ('INSERT_CHARACTER', 1, [ParameterType.CHARACTER_ID]),
		0x14: ('INSERT_LOCATION', 1, [ParameterType.LOCATION_ID]),
		0x15: ('INSERT_NUMBER', 2, [ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE]),
		0x16: ('INSERT_OBJECT', 2, [ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE]),
		0x17: ('INSERT_WEAPON', 1, [ParameterType.ITEM_ID]),
		0x18: ('INSERT_ARMOR', 0, []),
		0x19: ('INSERT_ACCESSORY', 0, []),

		# Formatting (0x1A-0x1F)
		0x1A: ('TEXTBOX_BELOW', 1, [ParameterType.BYTE_VALUE]),
		0x1B: ('TEXTBOX_ABOVE', 1, [ParameterType.BYTE_VALUE]),
		0x1C: ('UNK_1C', 0, []),
		0x1D: ('FORMAT_ITEM_E1', 1, [ParameterType.MODE_VALUE]),
		0x1E: ('FORMAT_ITEM_E2', 1, [ParameterType.MODE_VALUE]),
		0x1F: ('CRYSTAL', 1, [ParameterType.CRYSTAL_ID]),

		# State control (0x20-0x2F)
		0x20: ('UNK_20', 1, [ParameterType.BYTE_VALUE]),
		0x21: ('UNK_21', 0, []),
		0x22: ('UNK_22', 0, []),
		0x23: ('EXTERNAL_CALL_1', 1, [ParameterType.BYTE_VALUE]),
		0x24: ('SET_STATE_VAR', 4, [ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE]),
		0x25: ('SET_STATE_BYTE', 1, [ParameterType.BYTE_VALUE]),
		0x26: ('SET_STATE_WORD', 4, [ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE]),
		0x27: ('SET_STATE_BYTE_2', 1, [ParameterType.BYTE_VALUE]),
		0x28: ('SET_STATE_BYTE_3', 1, [ParameterType.BYTE_VALUE]),
		0x29: ('EXTERNAL_CALL_2', 1, [ParameterType.BYTE_VALUE]),
		0x2A: ('UNK_2A', 0, []),
		0x2B: ('EXTERNAL_CALL_3', 1, [ParameterType.BYTE_VALUE]),
		0x2C: ('UNK_2C', 2, [ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE]),
		0x2D: ('SET_STATE_WORD_2', 2, [ParameterType.BYTE_VALUE, ParameterType.BYTE_VALUE]),
		0x2E: ('UNK_2E', 1, [ParameterType.BYTE_VALUE]),
		0x2F: ('UNK_2F', 0, []),
	}

	# Item ID to name mapping (sample - extend with full item list)
	ITEM_NAMES = {
		0x00: "Cure Potion",
		0x01: "Heal Potion",
		0x02: "Seed",
		0x03: "Elixir",
		0x04: "Refresher",
		# ... Add more item names
	}

	# Spell ID to name mapping (sample)
	SPELL_NAMES = {
		0x00: "Cure",
		0x01: "Fire",
		0x02: "Blizzard",
		0x03: "Thunder",
		0x04: "Aero",
		# ... Add more spell names
	}

	# Character ID to name mapping
	CHARACTER_NAMES = {
		0x00: "Benjamin",
		0x01: "Kaeli",
		0x02: "Tristam",
		0x03: "Phoebe",
		0x04: "Reuben",
	}

	# Monster ID to name mapping (sample)
	MONSTER_NAMES = {
		0x00: "Behemoth",
		0x01: "Flazzard",
		# ... Add more monster names
	}

	def __init__(self, table_file: str, rom_file: Optional[str] = None):
		"""
		Initialize decompiler.

		Args:
			table_file: Path to character table file (.tbl)
			rom_file: Optional ROM file for validation
		"""
		self.table_file = Path(table_file)
		self.rom_file = Path(rom_file) if rom_file else None

		self.byte_to_char: Dict[int, str] = {}
		self.char_to_byte: Dict[str, int] = {}

		self.scripts: List[DecompiledScript] = []
		self.subroutine_map: Dict[int, int] = {}	# offset -> script_id

	def load_character_table(self) -> None:
		"""Load character encoding table."""
		print(f"Loading character table: {self.table_file}")

		if not self.table_file.exists():
			raise FileNotFoundError(f"Character table not found: {self.table_file}")

		with open(self.table_file, 'r', encoding='utf-8') as f:
			for line in f:
				line = line.strip()
				if not line or line.startswith('#'):
					continue

				if '=' in line:
					byte_str, char = line.split('=', 1)
					try:
						byte_val = int(byte_str, 16)
						self.char_to_byte[char] = byte_val
						self.byte_to_char[byte_val] = char
					except ValueError:
						print(f"Warning: Invalid byte value in table: {byte_str}")

		print(f"  Loaded {len(self.byte_to_char)} character mappings")

	def decode_text(self, data: bytes, offset: int) -> Tuple[str, int]:
		"""
		Decode text from byte data.

		Args:
			data: ROM data
			offset: Start offset

		Returns:
			(decoded_text, bytes_read)
		"""
		text = ""
		bytes_read = 0

		while offset + bytes_read < len(data):
			byte = data[offset + bytes_read]

			# Check if byte is an event command
			if byte in self.COMMANDS:
				break

			# Decode character
			if byte in self.byte_to_char:
				text += self.byte_to_char[byte]
			else:
				text += f"[{byte:02X}]"	# Unknown byte

			bytes_read += 1

			# Stop at reasonable text length (sanity check)
			if bytes_read > 1000:
				break

		return text, bytes_read

	def annotate_command(self, cmd: DecompiledCommand) -> None:
		"""Add helpful annotation to command."""
		if cmd.name == 'CALL_SUBROUTINE' and len(cmd.parameters) >= 2:
			target = cmd.parameters[0] | (cmd.parameters[1] << 8)
			cmd.annotation = f"-> Subroutine at 0x{target:04X}"

		elif cmd.name == 'MEMORY_WRITE' and len(cmd.parameters) >= 4:
			addr = cmd.parameters[0] | (cmd.parameters[1] << 8)
			value = cmd.parameters[2] | (cmd.parameters[3] << 8)
			cmd.annotation = f"Set memory ${addr:04X} = 0x{value:04X}"

		elif cmd.name == 'INSERT_ITEM' and len(cmd.parameters) >= 1:
			item_id = cmd.parameters[0]
			if item_id in self.ITEM_NAMES:
				cmd.annotation = f"Item: {self.ITEM_NAMES[item_id]}"

		elif cmd.name == 'INSERT_SPELL' and len(cmd.parameters) >= 1:
			spell_id = cmd.parameters[0]
			if spell_id in self.SPELL_NAMES:
				cmd.annotation = f"Spell: {self.SPELL_NAMES[spell_id]}"

		elif cmd.name == 'INSERT_CHARACTER' and len(cmd.parameters) >= 1:
			char_id = cmd.parameters[0]
			if char_id in self.CHARACTER_NAMES:
				cmd.annotation = f"Character: {self.CHARACTER_NAMES[char_id]}"

		elif cmd.name == 'INSERT_MONSTER' and len(cmd.parameters) >= 1:
			monster_id = cmd.parameters[0]
			if monster_id in self.MONSTER_NAMES:
				cmd.annotation = f"Monster: {self.MONSTER_NAMES[monster_id]}"

		elif cmd.name == 'FORMAT_ITEM_E1':
			cmd.annotation = "Item formatting (0x1D variant)"

		elif cmd.name == 'FORMAT_ITEM_E2':
			cmd.annotation = "Item formatting (0x1E variant)"

		elif cmd.name == 'TEXTBOX_BELOW':
			cmd.annotation = "Position textbox at bottom"

		elif cmd.name == 'TEXTBOX_ABOVE':
			cmd.annotation = "Position textbox at top"

		elif cmd.name == 'CRYSTAL' and len(cmd.parameters) >= 1:
			crystal_names = {0: "Wind", 1: "Fire", 2: "Water", 3: "Earth"}
			crystal_id = cmd.parameters[0]
			if crystal_id in crystal_names:
				cmd.annotation = f"Crystal: {crystal_names[crystal_id]}"

	def decompile_script(self, data: bytes, start_offset: int, script_id: int = 0, max_size: int = 1024) -> DecompiledScript:
		"""
		Decompile a single event script.

		Args:
			data: ROM data
			start_offset: Start offset in ROM
			script_id: Script identifier
			max_size: Maximum script size (sanity check)

		Returns:
			DecompiledScript
		"""
		script = DecompiledScript(script_id=script_id, start_offset=start_offset)

		offset = start_offset
		bytes_read = 0

		while bytes_read < max_size and offset < len(data):
			byte = data[offset]

			# Check if byte is text or command
			if byte in self.COMMANDS:
				# Event command
				cmd_name, param_count, param_types = self.COMMANDS[byte]

				# Read parameters
				parameters = []
				for i in range(param_count):
					if offset + 1 + i < len(data):
						parameters.append(data[offset + 1 + i])
					else:
						break

				cmd_size = 1 + param_count

				cmd = DecompiledCommand(
					offset=offset,
					opcode=byte,
					name=cmd_name,
					parameters=parameters,
					param_types=param_types,
					size=cmd_size
				)

				# Annotate command
				self.annotate_command(cmd)

				script.commands.append(cmd)

				# Track subroutine calls
				if cmd_name == 'CALL_SUBROUTINE' and len(parameters) >= 2:
					target = parameters[0] | (parameters[1] << 8)
					script.subroutine_calls.append(target)

				# Track memory writes
				if cmd_name == 'MEMORY_WRITE' and len(parameters) >= 4:
					addr = parameters[0] | (parameters[1] << 8)
					value = parameters[2] | (parameters[3] << 8)
					script.memory_writes.append((addr, value))

				offset += cmd_size
				bytes_read += cmd_size

				# Stop at END command
				if cmd_name == 'END':
					break

			else:
				# Text segment
				text, text_bytes = self.decode_text(data, offset)
				if text:
					script.text_segments.append((offset, text))

				offset += text_bytes
				bytes_read += text_bytes

				# Safety: if no text decoded, advance 1 byte
				if text_bytes == 0:
					offset += 1
					bytes_read += 1

		script.total_size = bytes_read
		return script

	def decompile_batch(self, data: bytes, start_offsets: List[int]) -> None:
		"""
		Decompile multiple scripts.

		Args:
			data: ROM data
			start_offsets: List of starting offsets
		"""
		print(f"\n🔍 Decompiling {len(start_offsets)} scripts...")

		for script_id, offset in enumerate(start_offsets):
			print(f"  Script {script_id} at 0x{offset:04X}...", end='')

			try:
				script = self.decompile_script(data, offset, script_id)
				self.scripts.append(script)
				self.subroutine_map[offset] = script_id
				print(f" ✅ ({script.total_size} bytes, {len(script.commands)} commands)")
			except Exception as e:
				print(f" ❌ Error: {e}")

		print(f"\n  Decompiled {len(self.scripts)} scripts successfully")

	def build_reference_map(self) -> None:
		"""Build map of which scripts reference which."""
		print("\n🔗 Building reference map...")

		for script in self.scripts:
			for target_offset in script.subroutine_calls:
				if target_offset in self.subroutine_map:
					target_id = self.subroutine_map[target_offset]
					if script.script_id not in self.scripts[target_id].references:
						self.scripts[target_id].references.append(script.script_id)

		print(f"  ✅ Reference map complete")

	def export_script(self, script: DecompiledScript, show_offsets: bool = False) -> List[str]:
		"""
		Export script to human-readable format.

		Args:
			script: Script to export
			show_offsets: Include ROM offsets in output

		Returns:
			List of output lines
		"""
		lines = []

		# Header
		lines.append("; " + "=" * 78)
		lines.append(f"; Event Script {script.script_id} - at 0x{script.start_offset:04X}")
		lines.append("; " + "=" * 78)
		lines.append(f"; Total size: {script.total_size} bytes")
		lines.append(f"; Commands: {len(script.commands)}")
		lines.append(f"; Text segments: {len(script.text_segments)}")

		if script.references:
			ref_str = ', '.join(str(r) for r in script.references)
			lines.append(f"; Referenced by: Scripts {ref_str}")

		if script.subroutine_calls:
			lines.append(f"; Calls {len(script.subroutine_calls)} subroutines")

		if script.memory_writes:
			lines.append(f"; Memory writes: {len(script.memory_writes)}")
			for addr, value in script.memory_writes[:3]:	# Show first 3
				lines.append(f";   - ${addr:04X} = 0x{value:04X}")

		lines.append("")
		lines.append(f"[DIALOG {script.script_id}]")

		# Interleave text and commands in offset order
		all_items = []

		for offset, text in script.text_segments:
			all_items.append((offset, 'text', text))

		for cmd in script.commands:
			all_items.append((cmd.offset, 'command', cmd))

		all_items.sort(key=lambda x: x[0])

		# Output items
		for offset, item_type, item in all_items:
			if item_type == 'text':
				# Text segment
				for line in item.split('\n'):
					if line.strip():
						lines.append(line)
			else:
				# Command
				lines.append(item.to_script(show_offsets))

		lines.append("")

		return lines

	def export_all(self, output_path: str, show_offsets: bool = False) -> None:
		"""
		Export all decompiled scripts to file.

		Args:
			output_path: Output file path
			show_offsets: Include ROM offsets
		"""
		print(f"\n📝 Exporting to: {output_path}")

		output_file = Path(output_path)
		output_file.parent.mkdir(parents=True, exist_ok=True)

		all_lines = []
		all_lines.append("; " + "=" * 78)
		all_lines.append("; FFMQ Decompiled Event Scripts")
		all_lines.append("; " + "=" * 78)
		all_lines.append(f"; Total scripts: {len(self.scripts)}")
		all_lines.append(f"; Total commands: {sum(len(s.commands) for s in self.scripts)}")
		all_lines.append(f"; Generated by: event_script_decompiler.py")
		all_lines.append("; " + "=" * 78)
		all_lines.append("")
		all_lines.append("")

		for script in self.scripts:
			all_lines.extend(self.export_script(script, show_offsets))
			all_lines.append("")

		with open(output_file, 'w', encoding='utf-8') as f:
			f.write('\n'.join(all_lines))

		print(f"  ✅ Exported {len(self.scripts)} scripts")

	def generate_report(self, output_path: str) -> None:
		"""Generate decompilation report."""
		print(f"\n📊 Generating report: {output_path}")

		report_file = Path(output_path)

		lines = []
		lines.append("# Event Script Decompilation Report")
		lines.append("=" * 80)
		lines.append("")
		lines.append(f"**Total Scripts**: {len(self.scripts)}")
		lines.append(f"**Total Commands**: {sum(len(s.commands) for s in self.scripts)}")
		lines.append(f"**Total Size**: {sum(s.total_size for s in self.scripts)} bytes")
		lines.append("")

		# Command usage statistics
		cmd_usage = {}
		for script in self.scripts:
			for cmd in script.commands:
				if cmd.name not in cmd_usage:
					cmd_usage[cmd.name] = 0
				cmd_usage[cmd.name] += 1

		lines.append("## Command Usage Statistics")
		lines.append("")
		lines.append("| Command | Count | % |")
		lines.append("|---------|------:|---:|")

		total_cmds = sum(cmd_usage.values())
		for cmd_name, count in sorted(cmd_usage.items(), key=lambda x: x[1], reverse=True):
			pct = (count / total_cmds * 100) if total_cmds > 0 else 0
			lines.append(f"| {cmd_name} | {count} | {pct:.1f}% |")

		lines.append("")

		# Subroutine call graph
		lines.append("## Subroutine Call Graph")
		lines.append("")
		for script in self.scripts:
			if script.subroutine_calls:
				lines.append(f"### Script {script.script_id} (0x{script.start_offset:04X})")
				for target in script.subroutine_calls:
					if target in self.subroutine_map:
						target_id = self.subroutine_map[target]
						lines.append(f"- Calls Script {target_id} at 0x{target:04X}")
					else:
						lines.append(f"- Calls unknown subroutine at 0x{target:04X}")
				lines.append("")

		# Memory operations
		lines.append("## Memory Operations")
		lines.append("")
		for script in self.scripts:
			if script.memory_writes:
				lines.append(f"### Script {script.script_id}")
				for addr, value in script.memory_writes:
					lines.append(f"- Write ${addr:04X} = 0x{value:04X}")
				lines.append("")

		with open(report_file, 'w', encoding='utf-8') as f:
			f.write('\n'.join(lines))

		print(f"  ✅ Report saved")


def main():
	"""Main entry point."""
	import argparse

	parser = argparse.ArgumentParser(
		description="Decompile FFMQ event scripts from ROM format",
		formatter_class=argparse.RawDescriptionHelpFormatter,
		epilog="""
Examples:
	# Decompile specific script offsets
	python event_script_decompiler.py --rom ffmq.sfc --table simple.tbl --offsets 0x8FA0,0x9000,0x9100

	# Decompile with offset annotations
	python event_script_decompiler.py --rom ffmq.sfc --table simple.tbl --offsets 0x8FA0 --show-offsets

	# Generate detailed report
	python event_script_decompiler.py --rom ffmq.sfc --table simple.tbl --offsets 0x8FA0 --report output/report.md

Documentation:
	Supports all 48 event commands with automatic parameter type detection.
	See EVENT_SYSTEM_ARCHITECTURE.md for command reference.
		"""
	)

	parser.add_argument(
		'--rom',
		required=True,
		help='Path to ROM file'
	)

	parser.add_argument(
		'--table',
		required=True,
		help='Path to character table file (.tbl)'
	)

	parser.add_argument(
		'--offsets',
		required=True,
		help='Comma-separated list of script start offsets (hex: 0x8FA0 or decimal: 36768)'
	)

	parser.add_argument(
		'--output',
		default='output/decompiled_scripts.txt',
		help='Output file for decompiled scripts'
	)

	parser.add_argument(
		'--report',
		default='output/decompilation_report.md',
		help='Path for decompilation report'
	)

	parser.add_argument(
		'--show-offsets',
		action='store_true',
		help='Include ROM offsets in output'
	)

	args = parser.parse_args()

	print("=" * 80)
	print("EVENT SCRIPT DECOMPILER")
	print("=" * 80)

	# Parse offsets
	offset_strs = args.offsets.split(',')
	offsets = []
	for offset_str in offset_strs:
		offset_str = offset_str.strip()
		if offset_str.startswith('0x') or offset_str.startswith('0X'):
			offsets.append(int(offset_str, 16))
		else:
			offsets.append(int(offset_str))

	print(f"\nScript offsets: {', '.join(f'0x{o:04X}' for o in offsets)}")

	# Initialize decompiler
	decompiler = EventScriptDecompiler(args.table, args.rom)

	# Load character table
	decompiler.load_character_table()

	# Load ROM data
	print(f"\nLoading ROM: {args.rom}")
	with open(args.rom, 'rb') as f:
		rom_data = f.read()
	print(f"  ROM size: {len(rom_data):,} bytes")

	# Decompile scripts
	decompiler.decompile_batch(rom_data, offsets)

	# Build reference map
	decompiler.build_reference_map()

	# Export results
	decompiler.export_all(args.output, args.show_offsets)

	# Generate report
	decompiler.generate_report(args.report)

	print("\n" + "=" * 80)
	print("DECOMPILATION COMPLETE")
	print("=" * 80)
	print(f"\nScripts decompiled: {len(decompiler.scripts)}")
	print(f"Total commands: {sum(len(s.commands) for s in decompiler.scripts)}")
	print(f"Total size: {sum(s.total_size for s in decompiler.scripts)} bytes")
	print("")


if __name__ == '__main__':
	main()
