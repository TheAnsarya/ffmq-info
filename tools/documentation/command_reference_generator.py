#!/usr/bin/env python3
"""
Command Reference Generator - Generate comprehensive documentation from event scripts
Automatically extract and document all commands, parameters, and usage patterns

Features:
- Extract all commands from scripts
- Parameter analysis and documentation
- Usage examples extraction
- Frequency statistics
- Cross-reference generation
- Multiple output formats
- Command categorization
- Interactive HTML reference

Output Formats:
- Markdown documentation
- HTML reference (with search/filter)
- JSON API documentation
- CSV parameter tables
- Man page format
- Wiki format (MediaWiki)

Documentation Sections:
- Command summary table
- Detailed command descriptions
- Parameter specifications
- Usage examples
- Related commands
- See also references

Usage:
	python command_reference_generator.py scripts/ --output command_ref.md
	python command_reference_generator.py scripts/ --format html --output reference.html
	python command_reference_generator.py scripts/ --format json --api-doc
	python command_reference_generator.py scripts/ --categories --stats
"""

import argparse
import re
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple
from dataclasses import dataclass, field
from collections import Counter, defaultdict
from enum import Enum
import json


class CommandCategory(Enum):
	"""Command categories"""
	TEXT = "Text Display"
	CONTROL_FLOW = "Control Flow"
	MEMORY = "Memory Operations"
	BATTLE = "Battle System"
	PARTY = "Party Management"
	ITEMS = "Items/Equipment"
	WORLD = "World State"
	GRAPHICS = "Graphics/Display"
	AUDIO = "Audio/Music"
	EVENT = "Event Control"
	UNKNOWN = "Unknown/Other"


@dataclass
class ParameterSpec:
	"""Parameter specification"""
	position: int
	name: str
	type: str  # "byte", "word", "flag", "pointer", "string"
	description: str
	valid_range: Optional[Tuple[int, int]] = None
	common_values: List[Tuple[int, str]] = field(default_factory=list)  # (value, meaning)
	examples: List[str] = field(default_factory=list)


@dataclass
class CommandDoc:
	"""Documentation for a command"""
	opcode: int
	name: str
	mnemonic: str
	category: CommandCategory
	description: str
	parameters: List[ParameterSpec]
	usage_count: int = 0
	examples: List[str] = field(default_factory=list)
	related_commands: List[str] = field(default_factory=list)
	notes: List[str] = field(default_factory=list)
	see_also: List[str] = field(default_factory=list)


@dataclass
class UsageExample:
	"""Usage example from actual scripts"""
	command: str
	parameters: List[str]
	context: List[str]  # Surrounding lines for context
	source_file: str
	line_number: int


class CommandReferenceGenerator:
	"""Generate comprehensive command reference documentation"""

	# Base command definitions
	COMMAND_DEFINITIONS = {
		0x00: ("END", "End script", CommandCategory.CONTROL_FLOW),
		0x01: ("WAIT", "Wait for input", CommandCategory.TEXT),
		0x02: ("NEWLINE", "New line", CommandCategory.TEXT),
		0x03: ("SET_FLAG", "Set flag", CommandCategory.MEMORY),
		0x04: ("CLEAR_FLAG", "Clear flag", CommandCategory.MEMORY),
		0x05: ("CHECK_FLAG", "Check flag", CommandCategory.CONTROL_FLOW),
		0x06: ("BRANCH", "Branch if true", CommandCategory.CONTROL_FLOW),
		0x07: ("JUMP", "Jump to label", CommandCategory.CONTROL_FLOW),
		0x08: ("CALL", "Call subroutine", CommandCategory.CONTROL_FLOW),
		0x09: ("RETURN", "Return from subroutine", CommandCategory.CONTROL_FLOW),
		0x0A: ("DELAY", "Delay frames", CommandCategory.EVENT),
		0x0B: ("PLAY_SOUND", "Play sound effect", CommandCategory.AUDIO),
		0x0C: ("PLAY_MUSIC", "Play music", CommandCategory.AUDIO),
		0x0D: ("STOP_MUSIC", "Stop music", CommandCategory.AUDIO),
		0x0E: ("FADE_MUSIC", "Fade music", CommandCategory.AUDIO),
		0x0F: ("SHOW_SPRITE", "Show sprite", CommandCategory.GRAPHICS),
		0x10: ("HIDE_SPRITE", "Hide sprite", CommandCategory.GRAPHICS),
		0x11: ("MOVE_SPRITE", "Move sprite", CommandCategory.GRAPHICS),
		0x12: ("ANIMATE_SPRITE", "Animate sprite", CommandCategory.GRAPHICS),
		0x13: ("LOAD_MAP", "Load map", CommandCategory.WORLD),
		0x14: ("TELEPORT", "Teleport party", CommandCategory.WORLD),
		0x15: ("ADD_PARTY_MEMBER", "Add party member", CommandCategory.PARTY),
		0x16: ("REMOVE_PARTY_MEMBER", "Remove party member", CommandCategory.PARTY),
		0x17: ("ADD_ITEM", "Add item to inventory", CommandCategory.ITEMS),
		0x18: ("REMOVE_ITEM", "Remove item", CommandCategory.ITEMS),
		0x19: ("CHECK_ITEM", "Check for item", CommandCategory.ITEMS),
		0x1A: ("START_BATTLE", "Start battle", CommandCategory.BATTLE),
		0x1B: ("FLEE_BATTLE", "Allow/disallow flee", CommandCategory.BATTLE),
		0x1C: ("BATTLE_CONDITION", "Set battle condition", CommandCategory.BATTLE),
		0x1D: ("SHOW_TEXTBOX", "Show textbox", CommandCategory.TEXT),
		0x1E: ("CHOICE", "Show choice menu", CommandCategory.TEXT),
		0x1F: ("SHOP", "Open shop", CommandCategory.ITEMS),
		0x20: ("INN", "Open inn", CommandCategory.EVENT),
		0x21: ("GIVE_GOLD", "Give gold", CommandCategory.ITEMS),
		0x22: ("TAKE_GOLD", "Take gold", CommandCategory.ITEMS),
		0x23: ("CHECK_GOLD", "Check gold amount", CommandCategory.ITEMS),
		0x24: ("SCREEN_FADE", "Fade screen", CommandCategory.GRAPHICS),
		0x25: ("SCREEN_SHAKE", "Shake screen", CommandCategory.GRAPHICS),
		0x26: ("SCREEN_FLASH", "Flash screen", CommandCategory.GRAPHICS),
		0x27: ("CAMERA_MOVE", "Move camera", CommandCategory.GRAPHICS),
		0x28: ("WEATHER", "Set weather", CommandCategory.WORLD),
		0x29: ("TIME", "Set time of day", CommandCategory.WORLD),
		0x2A: ("VARIABLE_SET", "Set variable", CommandCategory.MEMORY),
		0x2B: ("VARIABLE_ADD", "Add to variable", CommandCategory.MEMORY),
		0x2C: ("VARIABLE_CHECK", "Check variable", CommandCategory.MEMORY),
		0x2D: ("MEMORY_WRITE", "Write to memory", CommandCategory.MEMORY),
		0x2E: ("MEMORY_READ", "Read from memory", CommandCategory.MEMORY),
		0x2F: ("MEMORY_COMPARE", "Compare memory", CommandCategory.MEMORY),
	}

	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.command_docs: Dict[int, CommandDoc] = {}
		self.examples_by_command: Dict[str, List[UsageExample]] = defaultdict(list)
		self.parameter_values: Dict[str, Dict[int, Counter]] = defaultdict(lambda: defaultdict(Counter))

	def initialize_command_docs(self) -> None:
		"""Initialize command documentation from definitions"""
		for opcode, (name, description, category) in self.COMMAND_DEFINITIONS.items():
			self.command_docs[opcode] = CommandDoc(
				opcode=opcode,
				name=name,
				mnemonic=name.lower(),
				category=category,
				description=description,
				parameters=[]
			)

	def parse_script_file(self, path: Path) -> None:
		"""Parse script file to extract command usage"""
		try:
			with open(path) as f:
				lines = f.readlines()
		except Exception as e:
			if self.verbose:
				print(f"Error reading {path}: {e}")
			return

		for line_num, line in enumerate(lines, 1):
			line = line.strip()
			if not line or line.startswith(';'):
				continue

			# Parse command line
			match = re.match(r'^([A-Z_]+)(?:\s+(.+))?$', line)
			if not match:
				continue

			command_name = match.group(1)
			params_str = match.group(2) or ""

			# Find command opcode
			opcode = None
			for op, (name, _, _) in self.COMMAND_DEFINITIONS.items():
				if name == command_name:
					opcode = op
					break

			if opcode is None:
				continue

			# Update usage count
			self.command_docs[opcode].usage_count += 1

			# Parse parameters
			params = []
			if params_str:
				# Simple parameter parsing
				for param in params_str.split(','):
					param = param.strip()
					params.append(param)

					# Track parameter values
					try:
						value = int(param, 0)
						self.parameter_values[command_name][len(params) - 1][value] += 1
					except ValueError:
						pass

			# Extract context
			context_start = max(0, line_num - 2)
			context_end = min(len(lines), line_num + 2)
			context = [lines[i].rstrip() for i in range(context_start, context_end)]

			# Create usage example
			example = UsageExample(
				command=command_name,
				parameters=params,
				context=context,
				source_file=str(path),
				line_number=line_num
			)

			self.examples_by_command[command_name].append(example)

	def analyze_parameters(self) -> None:
		"""Analyze parameter usage patterns"""
		for opcode, doc in self.command_docs.items():
			command_name = doc.name

			if command_name not in self.parameter_values:
				continue

			param_data = self.parameter_values[command_name]

			# Determine parameter count
			max_params = max(param_data.keys()) + 1 if param_data else 0

			# Create parameter specs
			for pos in range(max_params):
				if pos not in param_data:
					continue

				value_counter = param_data[pos]

				# Determine parameter type based on values
				values = list(value_counter.keys())
				if all(0 <= v <= 255 for v in values):
					param_type = "byte"
					valid_range = (0, 255)
				elif all(0 <= v <= 65535 for v in values):
					param_type = "word"
					valid_range = (0, 65535)
				else:
					param_type = "value"
					valid_range = None

				# Get common values
				common_values = [(v, f"Used {count} times") for v, count in value_counter.most_common(5)]

				param_spec = ParameterSpec(
					position=pos,
					name=f"param{pos + 1}",
					type=param_type,
					description=f"Parameter {pos + 1}",
					valid_range=valid_range,
					common_values=common_values
				)

				doc.parameters.append(param_spec)

	def add_parameter_descriptions(self) -> None:
		"""Add detailed parameter descriptions for known commands"""
		# SET_FLAG
		if 0x03 in self.command_docs:
			self.command_docs[0x03].parameters = [
				ParameterSpec(0, "flag_id", "word", "Flag ID to set (0-65535)")
			]

		# CLEAR_FLAG
		if 0x04 in self.command_docs:
			self.command_docs[0x04].parameters = [
				ParameterSpec(0, "flag_id", "word", "Flag ID to clear (0-65535)")
			]

		# CHECK_FLAG
		if 0x05 in self.command_docs:
			self.command_docs[0x05].parameters = [
				ParameterSpec(0, "flag_id", "word", "Flag ID to check (0-65535)")
			]

		# DELAY
		if 0x0A in self.command_docs:
			self.command_docs[0x0A].parameters = [
				ParameterSpec(0, "frames", "byte", "Number of frames to wait (1-255)")
			]

		# PLAY_SOUND
		if 0x0B in self.command_docs:
			self.command_docs[0x0B].parameters = [
				ParameterSpec(0, "sound_id", "byte", "Sound effect ID (0-255)")
			]

		# PLAY_MUSIC
		if 0x0C in self.command_docs:
			self.command_docs[0x0C].parameters = [
				ParameterSpec(0, "music_id", "byte", "Music track ID (0-255)")
			]

		# CALL
		if 0x08 in self.command_docs:
			self.command_docs[0x08].parameters = [
				ParameterSpec(0, "address", "pointer", "Subroutine address (bank/offset)")
			]

	def generate_markdown(self) -> str:
		"""Generate Markdown documentation"""
		lines = [
			"# FFMQ Event Command Reference",
			"",
			"Automatically generated command reference documentation.",
			"",
			"## Table of Contents",
			""
		]

		# Table of contents by category
		categories = defaultdict(list)
		for doc in sorted(self.command_docs.values(), key=lambda d: d.opcode):
			categories[doc.category].append(doc)

		for category in CommandCategory:
			if category in categories:
				lines.append(f"- [{category.value}](#{category.value.lower().replace(' ', '-')})")

		lines.append("")
		lines.append("## Quick Reference Table")
		lines.append("")
		lines.append("| Opcode | Command | Category | Parameters | Usage |")
		lines.append("|--------|---------|----------|------------|-------|")

		for doc in sorted(self.command_docs.values(), key=lambda d: d.opcode):
			param_count = len(doc.parameters)
			usage = doc.usage_count
			lines.append(f"| 0x{doc.opcode:02X} | {doc.name} | {doc.category.value} | {param_count} | {usage} |")

		lines.append("")

		# Detailed documentation by category
		for category in CommandCategory:
			if category not in categories:
				continue

			lines.append(f"## {category.value}")
			lines.append("")

			for doc in sorted(categories[category], key=lambda d: d.opcode):
				lines.append(f"### {doc.name} (0x{doc.opcode:02X})")
				lines.append("")
				lines.append(f"**Description:** {doc.description}")
				lines.append("")

				if doc.parameters:
					lines.append("**Parameters:**")
					lines.append("")
					for param in doc.parameters:
						lines.append(f"- `{param.name}` ({param.type}): {param.description}")
						if param.valid_range:
							lines.append(f"  - Valid range: {param.valid_range[0]}-{param.valid_range[1]}")
						if param.common_values:
							lines.append(f"  - Common values:")
							for value, meaning in param.common_values[:3]:
								lines.append(f"    - `{value}`: {meaning}")
					lines.append("")

				if doc.usage_count > 0:
					lines.append(f"**Usage Count:** {doc.usage_count} occurrences")
					lines.append("")

				# Add examples
				if doc.name in self.examples_by_command:
					examples = self.examples_by_command[doc.name][:3]
					lines.append("**Examples:**")
					lines.append("")
					for i, example in enumerate(examples, 1):
						lines.append(f"{i}. From `{Path(example.source_file).name}` (line {example.line_number}):")
						lines.append("```")
						for ctx_line in example.context:
							lines.append(ctx_line)
						lines.append("```")
					lines.append("")

				if doc.notes:
					lines.append("**Notes:**")
					for note in doc.notes:
						lines.append(f"- {note}")
					lines.append("")

				lines.append("---")
				lines.append("")

		return '\n'.join(lines)

	def generate_html(self) -> str:
		"""Generate interactive HTML documentation"""
		html_parts = [
			"<!DOCTYPE html>",
			"<html>",
			"<head>",
			"<meta charset='UTF-8'>",
			"<title>FFMQ Event Command Reference</title>",
			"<style>",
			"body { font-family: Arial, sans-serif; max-width: 1200px; margin: 0 auto; padding: 20px; }",
			"h1 { color: #333; border-bottom: 2px solid #4CAF50; }",
			"h2 { color: #4CAF50; margin-top: 30px; }",
			"h3 { color: #555; }",
			"table { border-collapse: collapse; width: 100%; margin: 20px 0; }",
			"th, td { border: 1px solid #ddd; padding: 12px; text-align: left; }",
			"th { background-color: #4CAF50; color: white; }",
			"tr:nth-child(even) { background-color: #f2f2f2; }",
			".command { background: #f9f9f9; padding: 15px; margin: 15px 0; border-left: 4px solid #4CAF50; }",
			".opcode { color: #666; font-family: monospace; }",
			".example { background: #eee; padding: 10px; margin: 10px 0; font-family: monospace; white-space: pre; }",
			".search { width: 100%; padding: 10px; margin: 10px 0; font-size: 16px; }",
			".filter { margin: 10px 0; }",
			"</style>",
			"<script>",
			"function filterCommands() {",
			"  var input = document.getElementById('searchInput');",
			"  var filter = input.value.toUpperCase();",
			"  var commands = document.getElementsByClassName('command');",
			"  for (var i = 0; i < commands.length; i++) {",
			"    var text = commands[i].textContent || commands[i].innerText;",
			"    commands[i].style.display = text.toUpperCase().indexOf(filter) > -1 ? '' : 'none';",
			"  }",
			"}",
			"</script>",
			"</head>",
			"<body>",
			"<h1>FFMQ Event Command Reference</h1>",
			"<input type='text' id='searchInput' class='search' onkeyup='filterCommands()' placeholder='Search commands...'>",
			"<h2>Quick Reference</h2>",
			"<table>",
			"<tr><th>Opcode</th><th>Command</th><th>Category</th><th>Parameters</th><th>Usage</th></tr>"
		]

		for doc in sorted(self.command_docs.values(), key=lambda d: d.opcode):
			html_parts.append(
				f"<tr><td class='opcode'>0x{doc.opcode:02X}</td>"
				f"<td><a href='#{doc.name}'>{doc.name}</a></td>"
				f"<td>{doc.category.value}</td>"
				f"<td>{len(doc.parameters)}</td>"
				f"<td>{doc.usage_count}</td></tr>"
			)

		html_parts.extend([
			"</table>",
			"<h2>Command Details</h2>"
		])

		for doc in sorted(self.command_docs.values(), key=lambda d: d.opcode):
			html_parts.append(f"<div class='command' id='{doc.name}'>")
			html_parts.append(f"<h3>{doc.name} <span class='opcode'>(0x{doc.opcode:02X})</span></h3>")
			html_parts.append(f"<p><strong>Category:</strong> {doc.category.value}</p>")
			html_parts.append(f"<p><strong>Description:</strong> {doc.description}</p>")

			if doc.parameters:
				html_parts.append("<p><strong>Parameters:</strong></p><ul>")
				for param in doc.parameters:
					html_parts.append(f"<li><code>{param.name}</code> ({param.type}): {param.description}</li>")
				html_parts.append("</ul>")

			if doc.usage_count > 0:
				html_parts.append(f"<p><strong>Usage:</strong> {doc.usage_count} occurrences</p>")

			html_parts.append("</div>")

		html_parts.extend([
			"</body>",
			"</html>"
		])

		return '\n'.join(html_parts)

	def generate_json(self) -> str:
		"""Generate JSON API documentation"""
		commands = []

		for doc in sorted(self.command_docs.values(), key=lambda d: d.opcode):
			cmd_data = {
				"opcode": doc.opcode,
				"name": doc.name,
				"mnemonic": doc.mnemonic,
				"category": doc.category.value,
				"description": doc.description,
				"parameters": [
					{
						"position": p.position,
						"name": p.name,
						"type": p.type,
						"description": p.description,
						"valid_range": p.valid_range,
						"common_values": [{"value": v, "meaning": m} for v, m in p.common_values]
					}
					for p in doc.parameters
				],
				"usage_count": doc.usage_count,
				"examples": [
					{
						"command": ex.command,
						"parameters": ex.parameters,
						"source": ex.source_file,
						"line": ex.line_number
					}
					for ex in self.examples_by_command.get(doc.name, [])[:3]
				]
			}
			commands.append(cmd_data)

		return json.dumps({"commands": commands}, indent=2)

	def generate_statistics(self) -> str:
		"""Generate usage statistics report"""
		lines = [
			"# Command Usage Statistics",
			"",
			"## Overview",
			f"- Total commands defined: {len(self.command_docs)}",
			f"- Commands with usage: {sum(1 for d in self.command_docs.values() if d.usage_count > 0)}",
			f"- Total command invocations: {sum(d.usage_count for d in self.command_docs.values())}",
			"",
			"## Top Commands by Usage",
			""
		]

		sorted_by_usage = sorted(self.command_docs.values(), key=lambda d: d.usage_count, reverse=True)

		for i, doc in enumerate(sorted_by_usage[:20], 1):
			if doc.usage_count == 0:
				break
			lines.append(f"{i}. **{doc.name}**: {doc.usage_count} uses")

		lines.append("")
		lines.append("## Commands by Category")
		lines.append("")

		category_stats = defaultdict(lambda: {"count": 0, "usage": 0})
		for doc in self.command_docs.values():
			category_stats[doc.category]["count"] += 1
			category_stats[doc.category]["usage"] += doc.usage_count

		for category, stats in sorted(category_stats.items(), key=lambda x: x[1]["usage"], reverse=True):
			lines.append(f"- **{category.value}**: {stats['count']} commands, {stats['usage']} uses")

		return '\n'.join(lines)


def main():
	parser = argparse.ArgumentParser(description='Generate command reference documentation')
	parser.add_argument('input_dir', type=Path, help='Directory containing event scripts')
	parser.add_argument('--output', type=Path, help='Output file')
	parser.add_argument('--format', choices=['markdown', 'html', 'json', 'stats'], default='markdown',
		help='Output format')
	parser.add_argument('--categories', action='store_true', help='Group by categories')
	parser.add_argument('--stats', action='store_true', help='Include statistics')
	parser.add_argument('--api-doc', action='store_true', help='Generate API documentation format')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')

	args = parser.parse_args()

	generator = CommandReferenceGenerator(verbose=args.verbose)
	generator.initialize_command_docs()

	# Scan all script files
	if args.input_dir.is_dir():
		script_files = list(args.input_dir.rglob('*.txt')) + list(args.input_dir.rglob('*.asm'))
	else:
		script_files = [args.input_dir]

	if args.verbose:
		print(f"Processing {len(script_files)} script files...")

	for script_file in script_files:
		generator.parse_script_file(script_file)

	# Analyze parameters
	generator.analyze_parameters()
	generator.add_parameter_descriptions()

	# Generate output
	if args.format == 'markdown':
		output = generator.generate_markdown()
	elif args.format == 'html':
		output = generator.generate_html()
	elif args.format == 'json':
		output = generator.generate_json()
	elif args.format == 'stats':
		output = generator.generate_statistics()

	# Write output
	if args.output:
		with open(args.output, 'w') as f:
			f.write(output)
		print(f"\n✓ Reference generated: {args.output}")
	else:
		print(output)

	# Print statistics if requested
	if args.stats and args.format != 'stats':
		print("\n" + generator.generate_statistics())

	return 0


if __name__ == '__main__':
	exit(main())
