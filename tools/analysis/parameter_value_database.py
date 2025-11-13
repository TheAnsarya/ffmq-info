#!/usr/bin/env python3
"""
Parameter Value Database - Build comprehensive parameter reference
Extracts and documents parameter usage across all event scripts

Features:
- Extract all parameter values from scripts
- Group by command type
- Track value distributions
- Identify common patterns
- Document value meanings from context
- Generate reference documentation
- Export to JSON/CSV/SQLite
- Interactive parameter lookup

Value Analysis:
- Frequency analysis per parameter position
- Range detection (min/max values)
- Common value sets
- Contextual usage examples
- Cross-reference with known values

Usage:
	python parameter_value_database.py --script dialogs.txt
	python parameter_value_database.py --script *.txt --export-json params.json
	python parameter_value_database.py --script dialogs.txt --export-csv params.csv
	python parameter_value_database.py --script dialogs.txt --lookup CALL_SUBROUTINE
	python parameter_value_database.py --script dialogs.txt --export-sqlite params.db
"""

import argparse
import re
import json
import csv
import sqlite3
from pathlib import Path
from typing import Dict, List, Set, Optional, Any, Tuple
from dataclasses import dataclass, field, asdict
from collections import Counter, defaultdict


@dataclass
class ParameterValue:
	"""A parameter value instance"""
	value: str
	command: str
	position: int  # 0-indexed parameter position
	dialog_id: str
	line_number: int
	context: str = ""  # Surrounding lines for context


@dataclass
class ParameterStats:
	"""Statistics for a specific parameter position"""
	command: str
	position: int
	total_occurrences: int
	unique_values: int
	value_frequencies: Dict[str, int]
	min_value: Optional[int] = None
	max_value: Optional[int] = None
	common_values: List[Tuple[str, int]] = field(default_factory=list)
	examples: List[ParameterValue] = field(default_factory=list)


@dataclass
class CommandParameterInfo:
	"""Complete parameter information for a command"""
	command: str
	total_uses: int
	parameter_count: int
	parameters: List[ParameterStats]
	description: str = ""
	syntax: str = ""


@dataclass
class ParameterDatabase:
	"""Complete parameter value database"""
	script_files: List[str]
	total_commands: int
	total_parameters: int
	commands: Dict[str, CommandParameterInfo]
	
	def get_command(self, command: str) -> Optional[CommandParameterInfo]:
		"""Get parameter info for command"""
		return self.commands.get(command)
	
	def lookup_value(self, value: str) -> List[ParameterValue]:
		"""Find all uses of a specific value"""
		results = []
		for cmd_info in self.commands.values():
			for param_stat in cmd_info.parameters:
				for example in param_stat.examples:
					if example.value == value:
						results.append(example)
		return results


class ParameterValueExtractor:
	"""Extract and analyze parameter values from scripts"""
	
	# Known command parameter counts and descriptions
	COMMAND_DEFINITIONS = {
		'END': (0, "End of script/dialog", "END"),
		'WAIT': (1, "Wait for specified frames", "WAIT <frames>"),
		'NEWLINE': (0, "Insert line break", "NEWLINE"),
		'SET_FLAG': (1, "Set event flag", "SET_FLAG <flag_id>"),
		'CLEAR_FLAG': (1, "Clear event flag", "CLEAR_FLAG <flag_id>"),
		'CHECK_FLAG': (1, "Check if flag is set", "CHECK_FLAG <flag_id>"),
		'CALL_SUBROUTINE': (1, "Call event subroutine", "CALL_SUBROUTINE <address>"),
		'MEMORY_WRITE': (2, "Write value to memory", "MEMORY_WRITE <address> <value>"),
		'MEMORY_READ': (1, "Read value from memory", "MEMORY_READ <address>"),
		'JUMP': (1, "Unconditional jump", "JUMP <address>"),
		'JUMP_IF': (1, "Conditional jump", "JUMP_IF <address>"),
		'SHOW_SPRITE': (3, "Display sprite", "SHOW_SPRITE <sprite_id> <x> <y>"),
		'HIDE_SPRITE': (1, "Hide sprite", "HIDE_SPRITE <sprite_id>"),
		'MOVE_SPRITE': (3, "Move sprite to position", "MOVE_SPRITE <sprite_id> <x> <y>"),
		'PLAY_SOUND': (1, "Play sound effect", "PLAY_SOUND <sound_id>"),
		'PLAY_MUSIC': (1, "Play background music", "PLAY_MUSIC <music_id>"),
		'FADE_OUT': (1, "Fade out screen", "FADE_OUT <speed>"),
		'FADE_IN': (1, "Fade in screen", "FADE_IN <speed>"),
		'SHAKE_SCREEN': (2, "Shake screen effect", "SHAKE_SCREEN <intensity> <duration>"),
		'GIVE_ITEM': (2, "Add item to inventory", "GIVE_ITEM <item_id> <quantity>"),
		'REMOVE_ITEM': (2, "Remove item from inventory", "REMOVE_ITEM <item_id> <quantity>"),
		'CHECK_ITEM': (1, "Check if player has item", "CHECK_ITEM <item_id>"),
		'GIVE_GP': (1, "Give gold/currency", "GIVE_GP <amount>"),
		'REMOVE_GP': (1, "Remove gold/currency", "REMOVE_GP <amount>"),
		'ADD_PARTY_MEMBER': (1, "Add character to party", "ADD_PARTY_MEMBER <character_id>"),
		'REMOVE_PARTY_MEMBER': (1, "Remove character from party", "REMOVE_PARTY_MEMBER <character_id>"),
		'BATTLE': (1, "Start battle encounter", "BATTLE <enemy_group_id>"),
		'GAME_OVER': (0, "Trigger game over", "GAME_OVER"),
		'HEAL_PARTY': (0, "Fully heal all party members", "HEAL_PARTY"),
		'RETURN': (0, "Return from subroutine", "RETURN"),
	}
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.dialogs: Dict[str, List[str]] = {}
		self.parameter_values: List[ParameterValue] = []
		self.command_stats: Dict[str, CommandParameterInfo] = {}
	
	def parse_script_file(self, script_path: Path) -> None:
		"""Parse script file into dialog dictionary"""
		if self.verbose:
			print(f"Parsing {script_path}...")
		
		with open(script_path, 'r', encoding='utf-8') as f:
			content = f.read()
		
		# Split by dialog markers
		dialog_pattern = r'^DIALOG\s+(\S+):(.*?)(?=^DIALOG\s+|\Z)'
		matches = re.finditer(dialog_pattern, content, re.MULTILINE | re.DOTALL)
		
		for match in matches:
			dialog_id = match.group(1)
			dialog_content = match.group(2).strip()
			lines = [line.strip() for line in dialog_content.split('\n') if line.strip()]
			self.dialogs[dialog_id] = lines
	
	def extract_parameters(self) -> None:
		"""Extract all parameter values from dialogs"""
		if self.verbose:
			print(f"\nExtracting parameters from {len(self.dialogs)} dialogs...")
		
		for dialog_id, lines in self.dialogs.items():
			for line_num, line in enumerate(lines, 1):
				# Skip text lines
				if line.startswith('"'):
					continue
				
				# Parse command and parameters
				parts = line.split()
				if not parts:
					continue
				
				command = parts[0]
				params = parts[1:]
				
				# Extract each parameter
				for pos, param in enumerate(params):
					# Get context (surrounding lines)
					context_lines = []
					for i in range(max(0, line_num - 2), min(len(lines), line_num + 2)):
						if i != line_num - 1:
							context_lines.append(lines[i])
					context = '\n'.join(context_lines)
					
					param_value = ParameterValue(
						value=param,
						command=command,
						position=pos,
						dialog_id=dialog_id,
						line_number=line_num,
						context=context
					)
					self.parameter_values.append(param_value)
		
		if self.verbose:
			print(f"  Extracted {len(self.parameter_values)} parameter values")
	
	def build_statistics(self) -> None:
		"""Build statistical analysis of parameters"""
		if self.verbose:
			print("\nBuilding parameter statistics...")
		
		# Group by command and position
		command_params: Dict[str, Dict[int, List[ParameterValue]]] = defaultdict(lambda: defaultdict(list))
		
		for pv in self.parameter_values:
			command_params[pv.command][pv.position].append(pv)
		
		# Build stats for each command
		for command, positions in command_params.items():
			param_stats_list = []
			
			for position in sorted(positions.keys()):
				values = positions[position]
				value_freq = Counter(v.value for v in values)
				
				# Try to parse as integers for range analysis
				int_values = []
				for v in values:
					try:
						int_values.append(int(v.value, 0))  # Support hex with 0x prefix
					except ValueError:
						pass
				
				min_val = min(int_values) if int_values else None
				max_val = max(int_values) if int_values else None
				
				# Get common values (top 10)
				common = value_freq.most_common(10)
				
				# Get example uses
				examples = values[:5]  # First 5 examples
				
				param_stat = ParameterStats(
					command=command,
					position=position,
					total_occurrences=len(values),
					unique_values=len(value_freq),
					value_frequencies=dict(value_freq),
					min_value=min_val,
					max_value=max_val,
					common_values=common,
					examples=examples
				)
				param_stats_list.append(param_stat)
			
			# Get command definition
			param_count, description, syntax = self.COMMAND_DEFINITIONS.get(
				command,
				(len(param_stats_list), "Unknown command", f"{command} <params>")
			)
			
			cmd_info = CommandParameterInfo(
				command=command,
				total_uses=sum(s.total_occurrences for s in param_stats_list),
				parameter_count=len(param_stats_list),
				parameters=param_stats_list,
				description=description,
				syntax=syntax
			)
			self.command_stats[command] = cmd_info
		
		if self.verbose:
			print(f"  Analyzed {len(self.command_stats)} commands")
	
	def build_database(self, script_paths: List[Path]) -> ParameterDatabase:
		"""Build complete parameter database"""
		# Parse all scripts
		for path in script_paths:
			self.parse_script_file(path)
		
		# Extract and analyze
		self.extract_parameters()
		self.build_statistics()
		
		db = ParameterDatabase(
			script_files=[str(p) for p in script_paths],
			total_commands=sum(info.total_uses for info in self.command_stats.values()),
			total_parameters=len(self.parameter_values),
			commands=self.command_stats
		)
		
		return db
	
	def export_json(self, db: ParameterDatabase, output_path: Path) -> None:
		"""Export database to JSON"""
		data = {
			'script_files': db.script_files,
			'total_commands': db.total_commands,
			'total_parameters': db.total_parameters,
			'commands': {}
		}
		
		for cmd, info in db.commands.items():
			cmd_data = {
				'total_uses': info.total_uses,
				'parameter_count': info.parameter_count,
				'description': info.description,
				'syntax': info.syntax,
				'parameters': []
			}
			
			for param in info.parameters:
				param_data = {
					'position': param.position,
					'total_occurrences': param.total_occurrences,
					'unique_values': param.unique_values,
					'min_value': param.min_value,
					'max_value': param.max_value,
					'common_values': param.common_values,
					'value_frequencies': param.value_frequencies
				}
				cmd_data['parameters'].append(param_data)
			
			data['commands'][cmd] = cmd_data
		
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent=2)
		
		if self.verbose:
			print(f"\nExported to JSON: {output_path}")
	
	def export_csv(self, db: ParameterDatabase, output_path: Path) -> None:
		"""Export database to CSV"""
		with open(output_path, 'w', newline='', encoding='utf-8') as f:
			writer = csv.writer(f)
			writer.writerow([
				'Command', 'Position', 'Total Uses', 'Unique Values', 
				'Min', 'Max', 'Most Common', 'Frequency'
			])
			
			for cmd, info in sorted(db.commands.items()):
				for param in info.parameters:
					if param.common_values:
						most_common_val, most_common_freq = param.common_values[0]
					else:
						most_common_val, most_common_freq = '', 0
					
					writer.writerow([
						cmd,
						param.position,
						param.total_occurrences,
						param.unique_values,
						param.min_value if param.min_value is not None else '',
						param.max_value if param.max_value is not None else '',
						most_common_val,
						most_common_freq
					])
		
		if self.verbose:
			print(f"\nExported to CSV: {output_path}")
	
	def export_sqlite(self, db: ParameterDatabase, output_path: Path) -> None:
		"""Export database to SQLite"""
		conn = sqlite3.connect(output_path)
		cursor = conn.cursor()
		
		# Create tables
		cursor.execute('''
			CREATE TABLE IF NOT EXISTS commands (
				command TEXT PRIMARY KEY,
				total_uses INTEGER,
				parameter_count INTEGER,
				description TEXT,
				syntax TEXT
			)
		''')
		
		cursor.execute('''
			CREATE TABLE IF NOT EXISTS parameters (
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				command TEXT,
				position INTEGER,
				total_occurrences INTEGER,
				unique_values INTEGER,
				min_value INTEGER,
				max_value INTEGER,
				FOREIGN KEY (command) REFERENCES commands(command)
			)
		''')
		
		cursor.execute('''
			CREATE TABLE IF NOT EXISTS parameter_values (
				id INTEGER PRIMARY KEY AUTOINCREMENT,
				command TEXT,
				position INTEGER,
				value TEXT,
				frequency INTEGER,
				dialog_id TEXT,
				line_number INTEGER,
				FOREIGN KEY (command) REFERENCES commands(command)
			)
		''')
		
		# Insert commands
		for cmd, info in db.commands.items():
			cursor.execute('''
				INSERT INTO commands (command, total_uses, parameter_count, description, syntax)
				VALUES (?, ?, ?, ?, ?)
			''', (cmd, info.total_uses, info.parameter_count, info.description, info.syntax))
			
			# Insert parameter stats
			for param in info.parameters:
				cursor.execute('''
					INSERT INTO parameters (command, position, total_occurrences, unique_values, min_value, max_value)
					VALUES (?, ?, ?, ?, ?, ?)
				''', (cmd, param.position, param.total_occurrences, param.unique_values, 
				      param.min_value, param.max_value))
				
				# Insert value frequencies
				for value, freq in param.value_frequencies.items():
					# Get example dialog_id and line_number
					example = next((ex for ex in param.examples if ex.value == value), None)
					dialog_id = example.dialog_id if example else ''
					line_num = example.line_number if example else 0
					
					cursor.execute('''
						INSERT INTO parameter_values (command, position, value, frequency, dialog_id, line_number)
						VALUES (?, ?, ?, ?, ?, ?)
					''', (cmd, param.position, value, freq, dialog_id, line_num))
		
		conn.commit()
		conn.close()
		
		if self.verbose:
			print(f"\nExported to SQLite: {output_path}")
	
	def generate_report(self, db: ParameterDatabase) -> str:
		"""Generate parameter reference documentation"""
		lines = [
			"# Parameter Value Database Report",
			"",
			"## Overview",
			f"- **Scripts Analyzed**: {len(db.script_files)}",
			f"- **Total Commands**: {db.total_commands:,}",
			f"- **Total Parameters**: {db.total_parameters:,}",
			f"- **Unique Commands**: {len(db.commands)}",
			"",
			"## Command Reference",
			""
		]
		
		for cmd, info in sorted(db.commands.items()):
			lines.extend([
				f"### {cmd}",
				f"**Description**: {info.description}",
				f"**Syntax**: `{info.syntax}`",
				f"**Uses**: {info.total_uses:,}",
				""
			])
			
			if info.parameters:
				lines.append("**Parameters**:")
				lines.append("")
				
				for param in info.parameters:
					lines.append(f"**Parameter {param.position}**:")
					lines.append(f"- Occurrences: {param.total_occurrences:,}")
					lines.append(f"- Unique values: {param.unique_values}")
					
					if param.min_value is not None and param.max_value is not None:
						lines.append(f"- Range: {param.min_value} to {param.max_value}")
					
					if param.common_values:
						lines.append("- Common values:")
						for value, freq in param.common_values[:5]:
							percent = (freq / param.total_occurrences) * 100
							lines.append(f"  - `{value}`: {freq} times ({percent:.1f}%)")
					
					# Show example usage
					if param.examples:
						lines.append("- Example usage:")
						example = param.examples[0]
						lines.append(f"  ```")
						lines.append(f"  {example.command} {example.value}  ; {example.dialog_id} line {example.line_number}")
						lines.append(f"  ```")
					
					lines.append("")
			
			lines.append("---")
			lines.append("")
		
		return '\n'.join(lines)
	
	def interactive_lookup(self, db: ParameterDatabase) -> None:
		"""Interactive parameter lookup"""
		print("\n=== Parameter Database Lookup ===")
		print("Commands: list, lookup <command>, value <value>, quit")
		
		while True:
			try:
				query = input("\n> ").strip()
				
				if not query:
					continue
				
				parts = query.split(None, 1)
				cmd = parts[0].lower()
				
				if cmd == 'quit' or cmd == 'exit':
					break
				
				elif cmd == 'list':
					print(f"\nAvailable commands ({len(db.commands)}):")
					for command in sorted(db.commands.keys()):
						info = db.commands[command]
						print(f"  {command:20s} - {info.description}")
				
				elif cmd == 'lookup' and len(parts) == 2:
					command = parts[1].upper()
					info = db.get_command(command)
					
					if info:
						print(f"\n{command}")
						print(f"Description: {info.description}")
						print(f"Syntax: {info.syntax}")
						print(f"Uses: {info.total_uses:,}")
						print(f"\nParameters ({info.parameter_count}):")
						
						for param in info.parameters:
							print(f"\n  Position {param.position}:")
							print(f"    Occurrences: {param.total_occurrences:,}")
							print(f"    Unique: {param.unique_values}")
							if param.min_value is not None:
								print(f"    Range: {param.min_value} - {param.max_value}")
							print(f"    Common values: {', '.join(str(v) for v, _ in param.common_values[:5])}")
					else:
						print(f"Command '{command}' not found")
				
				elif cmd == 'value' and len(parts) == 2:
					value = parts[1]
					results = db.lookup_value(value)
					
					if results:
						print(f"\nFound {len(results)} uses of value '{value}':")
						for pv in results[:20]:
							print(f"  {pv.command} param{pv.position} in {pv.dialog_id} line {pv.line_number}")
					else:
						print(f"Value '{value}' not found")
				
				else:
					print("Unknown command. Try: list, lookup <command>, value <value>, quit")
			
			except (EOFError, KeyboardInterrupt):
				break
		
		print("\nGoodbye!")


def main():
	parser = argparse.ArgumentParser(description='Build parameter value database from scripts')
	parser.add_argument('--script', type=Path, nargs='+', required=True, help='Script file(s) to analyze')
	parser.add_argument('--export-json', type=Path, help='Export to JSON file')
	parser.add_argument('--export-csv', type=Path, help='Export to CSV file')
	parser.add_argument('--export-sqlite', type=Path, help='Export to SQLite database')
	parser.add_argument('--report', type=Path, help='Generate reference documentation')
	parser.add_argument('--lookup', type=str, help='Look up specific command')
	parser.add_argument('--interactive', action='store_true', help='Interactive lookup mode')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	extractor = ParameterValueExtractor(verbose=args.verbose)
	
	# Build database
	db = extractor.build_database(args.script)
	
	# Export to requested formats
	if args.export_json:
		extractor.export_json(db, args.export_json)
	
	if args.export_csv:
		extractor.export_csv(db, args.export_csv)
	
	if args.export_sqlite:
		extractor.export_sqlite(db, args.export_sqlite)
	
	if args.report:
		report = extractor.generate_report(db)
		with open(args.report, 'w', encoding='utf-8') as f:
			f.write(report)
		if args.verbose:
			print(f"\nReport saved to {args.report}")
	
	# Lookup specific command
	if args.lookup:
		info = db.get_command(args.lookup.upper())
		if info:
			print(f"\n{info.command}")
			print(f"Description: {info.description}")
			print(f"Syntax: {info.syntax}")
			print(f"Parameters: {info.parameter_count}")
			for param in info.parameters:
				print(f"  Position {param.position}: {param.unique_values} unique values ({param.total_occurrences} uses)")
		else:
			print(f"Command '{args.lookup}' not found")
	
	# Interactive mode
	if args.interactive:
		extractor.interactive_lookup(db)
	
	# Print summary
	if not args.interactive:
		print(f"\n✓ Parameter database built")
		print(f"  Commands: {len(db.commands)}")
		print(f"  Total parameters: {db.total_parameters:,}")
		print(f"  Total command uses: {db.total_commands:,}")
		
		# Top commands by usage
		top_commands = sorted(db.commands.items(), key=lambda x: x[1].total_uses, reverse=True)[:10]
		print(f"\nTop 10 Commands:")
		for cmd, info in top_commands:
			print(f"  {cmd:20s} {info.total_uses:>6,} uses")
	
	return 0


if __name__ == '__main__':
	exit(main())
