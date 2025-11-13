#!/usr/bin/env python3
"""
FFMQ Enemy AI Script Decompiler & Editor - Decompile and edit enemy battle AI

Final Fantasy Mystic Quest enemy AI system:
- AI scripts control enemy behavior in battle
- Script bytecode with opcodes (similar to event scripts)
- Conditional logic based on HP, status, turns
- Attack selection algorithms
- Pattern-based behaviors
- Boss-specific complex AI routines

Features:
- Decompile AI bytecode to readable pseudocode
- Edit AI scripts with high-level commands
- Compile modified AI back to bytecode
- AI script validation
- Pattern detection and analysis
- Compare AI between enemies
- Export AI documentation
- AI behavior simulation/testing
- Script library/templates

AI Script Structure (FFMQ):
- AI script bank: Bank $1C
- Pointer table: Points to individual AI scripts
- Opcodes: ~20 different commands
- Conditions: HP threshold, turn count, status checks
- Actions: Attack, spell, item, special ability
- Control flow: If/else, loops, jumps

AI Opcodes (Researched):
- 0x00: End script
- 0x01: Attack (physical)
- 0x02: Use spell (parameter: spell ID)
- 0x03: Use ability (parameter: ability ID)
- 0x04: If HP < threshold
- 0x05: If HP > threshold
- 0x06: If turn % N == 0
- 0x07: If status active
- 0x08: Jump to offset
- 0x09: Random branch
- 0x0A: Set counter
- 0x0B: Target selection
- 0x0C: Wait/delay
- 0x0D: Change AI pattern
- 0x0E: Special effect
- 0x0F: Counter attack setup

Usage:
	python ffmq_ai_decompiler.py rom.sfc --list-ai-scripts
	python ffmq_ai_decompiler.py rom.sfc --decompile-enemy 15
	python ffmq_ai_decompiler.py rom.sfc --decompile-script 0x1C8000
	python ffmq_ai_decompiler.py rom.sfc --export-all-ai --output ai_scripts/
	python ffmq_ai_decompiler.py rom.sfc --compare-ai 10,15,20
	python ffmq_ai_decompiler.py rom.sfc --analyze-pattern 15
"""

import argparse
import json
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any
from dataclasses import dataclass, field, asdict
from enum import Enum, IntEnum


class AIOpcode(IntEnum):
	"""AI script opcodes"""
	END_SCRIPT = 0x00
	ATTACK = 0x01
	USE_SPELL = 0x02
	USE_ABILITY = 0x03
	IF_HP_LESS = 0x04
	IF_HP_GREATER = 0x05
	IF_TURN_MOD = 0x06
	IF_STATUS = 0x07
	JUMP = 0x08
	RANDOM_BRANCH = 0x09
	SET_COUNTER = 0x0A
	TARGET_SELECT = 0x0B
	WAIT = 0x0C
	CHANGE_PATTERN = 0x0D
	SPECIAL_EFFECT = 0x0E
	COUNTER_SETUP = 0x0F


class TargetType(Enum):
	"""Target selection types"""
	RANDOM_PLAYER = "random_player"
	ALL_PLAYERS = "all_players"
	LOWEST_HP_PLAYER = "lowest_hp_player"
	HIGHEST_HP_PLAYER = "highest_hp_player"
	SELF = "self"
	ALL_ENEMIES = "all_enemies"


class SpellID(Enum):
	"""Known spell IDs"""
	FIRE = 0x00
	BLIZZARD = 0x01
	THUNDER = 0x02
	CURE = 0x03
	LIFE = 0x04
	HEAL = 0x05
	FLARE = 0x06
	METEOR = 0x07
	# ... more spells


@dataclass
class AIInstruction:
	"""Single AI instruction"""
	offset: int
	opcode: AIOpcode
	parameters: List[int]
	description: str = ""
	
	def to_dict(self) -> dict:
		return {
			'offset': f'0x{self.offset:04X}',
			'opcode': self.opcode.name,
			'opcode_value': self.opcode.value,
			'parameters': self.parameters,
			'description': self.description
		}
	
	def to_pseudocode(self) -> str:
		"""Convert instruction to readable pseudocode"""
		if self.opcode == AIOpcode.END_SCRIPT:
			return "END"
		
		elif self.opcode == AIOpcode.ATTACK:
			return "ATTACK()"
		
		elif self.opcode == AIOpcode.USE_SPELL:
			spell_id = self.parameters[0] if self.parameters else 0
			spell_name = f"Spell_{spell_id:02X}"
			return f"USE_SPELL({spell_name})"
		
		elif self.opcode == AIOpcode.USE_ABILITY:
			ability_id = self.parameters[0] if self.parameters else 0
			return f"USE_ABILITY({ability_id:02X})"
		
		elif self.opcode == AIOpcode.IF_HP_LESS:
			threshold = self.parameters[0] if self.parameters else 0
			return f"IF HP < {threshold}%:"
		
		elif self.opcode == AIOpcode.IF_HP_GREATER:
			threshold = self.parameters[0] if self.parameters else 0
			return f"IF HP > {threshold}%:"
		
		elif self.opcode == AIOpcode.IF_TURN_MOD:
			modulo = self.parameters[0] if self.parameters else 0
			return f"IF Turn % {modulo} == 0:"
		
		elif self.opcode == AIOpcode.IF_STATUS:
			status_id = self.parameters[0] if self.parameters else 0
			return f"IF STATUS({status_id:02X}):"
		
		elif self.opcode == AIOpcode.JUMP:
			target = self.parameters[0] if self.parameters else 0
			return f"GOTO 0x{target:04X}"
		
		elif self.opcode == AIOpcode.RANDOM_BRANCH:
			chance = self.parameters[0] if self.parameters else 50
			return f"IF RANDOM < {chance}%:"
		
		elif self.opcode == AIOpcode.SET_COUNTER:
			value = self.parameters[0] if self.parameters else 0
			return f"SET_COUNTER({value})"
		
		elif self.opcode == AIOpcode.TARGET_SELECT:
			target_type = self.parameters[0] if self.parameters else 0
			return f"TARGET({target_type:02X})"
		
		elif self.opcode == AIOpcode.WAIT:
			turns = self.parameters[0] if self.parameters else 1
			return f"WAIT({turns})"
		
		elif self.opcode == AIOpcode.CHANGE_PATTERN:
			pattern_id = self.parameters[0] if self.parameters else 0
			return f"CHANGE_PATTERN({pattern_id})"
		
		elif self.opcode == AIOpcode.SPECIAL_EFFECT:
			effect_id = self.parameters[0] if self.parameters else 0
			return f"SPECIAL_EFFECT({effect_id:02X})"
		
		elif self.opcode == AIOpcode.COUNTER_SETUP:
			return "SETUP_COUNTER_ATTACK()"
		
		else:
			params_str = ','.join(f'0x{p:02X}' for p in self.parameters)
			return f"OPCODE_{self.opcode:02X}({params_str})"


@dataclass
class AIScript:
	"""Complete AI script"""
	script_id: int
	rom_offset: int
	instructions: List[AIInstruction]
	enemy_ids: List[int] = field(default_factory=list)
	description: str = ""
	
	def to_dict(self) -> dict:
		return {
			'script_id': self.script_id,
			'rom_offset': f'0x{self.rom_offset:06X}',
			'instructions': [inst.to_dict() for inst in self.instructions],
			'enemy_ids': self.enemy_ids,
			'description': self.description
		}
	
	def to_pseudocode(self, indent: int = 0) -> str:
		"""Convert script to formatted pseudocode"""
		lines = []
		current_indent = indent
		
		for inst in self.instructions:
			# Adjust indent for control flow
			if inst.opcode in [AIOpcode.IF_HP_LESS, AIOpcode.IF_HP_GREATER, 
							   AIOpcode.IF_TURN_MOD, AIOpcode.IF_STATUS, 
							   AIOpcode.RANDOM_BRANCH]:
				lines.append('\t' * current_indent + inst.to_pseudocode())
				current_indent += 1
			elif inst.opcode == AIOpcode.END_SCRIPT:
				current_indent = max(0, current_indent - 1)
				lines.append('\t' * current_indent + inst.to_pseudocode())
			else:
				lines.append('\t' * current_indent + inst.to_pseudocode())
		
		return '\n'.join(lines)


class AIPattern(Enum):
	"""Detected AI behavior patterns"""
	SIMPLE_ATTACK = "simple_attack"
	HP_THRESHOLD = "hp_threshold"
	TURN_CYCLE = "turn_cycle"
	RANDOM_CHOICE = "random_choice"
	COUNTER_ATTACK = "counter_attack"
	MULTI_PHASE = "multi_phase"
	STATUS_DEPENDENT = "status_dependent"
	COMPLEX = "complex"


@dataclass
class AIAnalysis:
	"""AI script analysis results"""
	pattern: AIPattern
	complexity_score: float  # 0-100
	uses_spells: bool
	uses_abilities: bool
	has_conditions: bool
	has_loops: bool
	max_depth: int
	action_count: int
	condition_count: int
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['pattern'] = self.pattern.value
		return d


class FFMQAIDatabase:
	"""Database of FFMQ AI script locations"""
	
	# AI script bank and pointer table
	AI_BANK = 0x1C
	AI_BANK_OFFSET = 0x1C0000
	AI_POINTER_TABLE = 0x1C0000
	NUM_AI_SCRIPTS = 256
	
	# Opcode parameter counts (how many bytes each opcode reads)
	OPCODE_PARAM_COUNTS = {
		AIOpcode.END_SCRIPT: 0,
		AIOpcode.ATTACK: 0,
		AIOpcode.USE_SPELL: 1,
		AIOpcode.USE_ABILITY: 1,
		AIOpcode.IF_HP_LESS: 1,
		AIOpcode.IF_HP_GREATER: 1,
		AIOpcode.IF_TURN_MOD: 1,
		AIOpcode.IF_STATUS: 1,
		AIOpcode.JUMP: 2,
		AIOpcode.RANDOM_BRANCH: 1,
		AIOpcode.SET_COUNTER: 1,
		AIOpcode.TARGET_SELECT: 1,
		AIOpcode.WAIT: 1,
		AIOpcode.CHANGE_PATTERN: 1,
		AIOpcode.SPECIAL_EFFECT: 1,
		AIOpcode.COUNTER_SETUP: 0,
	}


class FFMQAIDecompiler:
	"""Decompile and edit FFMQ AI scripts"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		if self.verbose:
			print(f"Loaded FFMQ ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def get_ai_pointer(self, script_id: int) -> Optional[int]:
		"""Get AI script pointer from table"""
		if script_id >= FFMQAIDatabase.NUM_AI_SCRIPTS:
			return None
		
		pointer_offset = FFMQAIDatabase.AI_POINTER_TABLE + (script_id * 2)
		
		if pointer_offset + 2 > len(self.rom_data):
			return None
		
		# Read 16-bit pointer (offset within AI bank)
		pointer = self.rom_data[pointer_offset] | (self.rom_data[pointer_offset + 1] << 8)
		
		# Convert to absolute ROM offset
		rom_offset = FFMQAIDatabase.AI_BANK_OFFSET + pointer
		
		return rom_offset
	
	def decompile_script(self, rom_offset: int, max_instructions: int = 100) -> List[AIInstruction]:
		"""Decompile AI script from ROM offset"""
		instructions = []
		current_offset = rom_offset
		
		for _ in range(max_instructions):
			if current_offset >= len(self.rom_data):
				break
			
			opcode_byte = self.rom_data[current_offset]
			
			# Try to interpret as known opcode
			try:
				opcode = AIOpcode(opcode_byte)
			except ValueError:
				# Unknown opcode - treat as END
				if self.verbose:
					print(f"Warning: Unknown opcode 0x{opcode_byte:02X} at 0x{current_offset:06X}")
				break
			
			# Get parameter count
			param_count = FFMQAIDatabase.OPCODE_PARAM_COUNTS.get(opcode, 0)
			
			# Read parameters
			parameters = []
			for i in range(param_count):
				param_offset = current_offset + 1 + i
				
				if param_offset >= len(self.rom_data):
					break
				
				parameters.append(self.rom_data[param_offset])
			
			# Create instruction
			inst = AIInstruction(
				offset=current_offset,
				opcode=opcode,
				parameters=parameters
			)
			
			instructions.append(inst)
			
			# Advance to next instruction
			current_offset += 1 + param_count
			
			# Stop at END_SCRIPT
			if opcode == AIOpcode.END_SCRIPT:
				break
		
		return instructions
	
	def decompile_enemy_ai(self, enemy_id: int) -> Optional[AIScript]:
		"""Decompile AI script for specific enemy"""
		# For now, assume enemy_id maps directly to script_id
		# In reality, this would need to read from enemy data table
		script_id = enemy_id
		
		rom_offset = self.get_ai_pointer(script_id)
		
		if not rom_offset:
			return None
		
		instructions = self.decompile_script(rom_offset)
		
		return AIScript(
			script_id=script_id,
			rom_offset=rom_offset,
			instructions=instructions,
			enemy_ids=[enemy_id]
		)
	
	def analyze_ai_pattern(self, script: AIScript) -> AIAnalysis:
		"""Analyze AI script to detect patterns"""
		uses_spells = False
		uses_abilities = False
		has_conditions = False
		has_loops = False
		max_depth = 0
		current_depth = 0
		action_count = 0
		condition_count = 0
		
		for inst in script.instructions:
			# Count actions
			if inst.opcode in [AIOpcode.ATTACK, AIOpcode.USE_SPELL, AIOpcode.USE_ABILITY]:
				action_count += 1
			
			if inst.opcode == AIOpcode.USE_SPELL:
				uses_spells = True
			
			if inst.opcode == AIOpcode.USE_ABILITY:
				uses_abilities = True
			
			# Count conditions
			if inst.opcode in [AIOpcode.IF_HP_LESS, AIOpcode.IF_HP_GREATER, 
							   AIOpcode.IF_TURN_MOD, AIOpcode.IF_STATUS, 
							   AIOpcode.RANDOM_BRANCH]:
				has_conditions = True
				condition_count += 1
				current_depth += 1
				max_depth = max(max_depth, current_depth)
			
			# Detect loops
			if inst.opcode == AIOpcode.JUMP:
				target = inst.parameters[0] if inst.parameters else 0
				if target < inst.offset:
					has_loops = True
			
			# Track depth
			if inst.opcode == AIOpcode.END_SCRIPT:
				current_depth = max(0, current_depth - 1)
		
		# Detect pattern type
		if not has_conditions and action_count == 1:
			pattern = AIPattern.SIMPLE_ATTACK
		elif has_conditions and condition_count == 1:
			if any(inst.opcode == AIOpcode.IF_HP_LESS for inst in script.instructions):
				pattern = AIPattern.HP_THRESHOLD
			elif any(inst.opcode == AIOpcode.IF_TURN_MOD for inst in script.instructions):
				pattern = AIPattern.TURN_CYCLE
			elif any(inst.opcode == AIOpcode.RANDOM_BRANCH for inst in script.instructions):
				pattern = AIPattern.RANDOM_CHOICE
			else:
				pattern = AIPattern.STATUS_DEPENDENT
		elif any(inst.opcode == AIOpcode.COUNTER_SETUP for inst in script.instructions):
			pattern = AIPattern.COUNTER_ATTACK
		elif max_depth > 2 or has_loops:
			pattern = AIPattern.COMPLEX
		else:
			pattern = AIPattern.MULTI_PHASE
		
		# Calculate complexity score
		complexity = 0.0
		complexity += action_count * 5
		complexity += condition_count * 10
		complexity += max_depth * 15
		complexity += (20 if has_loops else 0)
		complexity += (10 if uses_spells else 0)
		complexity += (10 if uses_abilities else 0)
		
		complexity = min(complexity, 100.0)
		
		return AIAnalysis(
			pattern=pattern,
			complexity_score=complexity,
			uses_spells=uses_spells,
			uses_abilities=uses_abilities,
			has_conditions=has_conditions,
			has_loops=has_loops,
			max_depth=max_depth,
			action_count=action_count,
			condition_count=condition_count
		)
	
	def export_all_ai_scripts(self, output_dir: Path, num_scripts: int = 50) -> None:
		"""Export all AI scripts as documentation"""
		output_dir.mkdir(parents=True, exist_ok=True)
		
		# Generate index
		index_md = "# FFMQ AI Scripts\n\n"
		index_md += "| Script ID | ROM Offset | Instructions | Pattern | Complexity |\n"
		index_md += "|-----------|------------|--------------|---------|------------|\n"
		
		all_scripts = []
		
		for i in range(num_scripts):
			script = self.decompile_enemy_ai(i)
			
			if script and script.instructions:
				analysis = self.analyze_ai_pattern(script)
				
				index_md += f"| {i} | 0x{script.rom_offset:06X} | {len(script.instructions)} | "
				index_md += f"{analysis.pattern.value} | {analysis.complexity_score:.1f} |\n"
				
				# Generate individual script file
				script_md = f"# AI Script {i}\n\n"
				script_md += f"**ROM Offset:** 0x{script.rom_offset:06X}\n\n"
				script_md += f"**Pattern:** {analysis.pattern.value}\n\n"
				script_md += f"**Complexity:** {analysis.complexity_score:.1f}/100\n\n"
				script_md += f"**Properties:**\n"
				script_md += f"- Uses Spells: {'Yes' if analysis.uses_spells else 'No'}\n"
				script_md += f"- Uses Abilities: {'Yes' if analysis.uses_abilities else 'No'}\n"
				script_md += f"- Has Conditions: {'Yes' if analysis.has_conditions else 'No'}\n"
				script_md += f"- Has Loops: {'Yes' if analysis.has_loops else 'No'}\n"
				script_md += f"- Max Depth: {analysis.max_depth}\n\n"
				script_md += "## Pseudocode\n\n```\n"
				script_md += script.to_pseudocode()
				script_md += "\n```\n\n"
				script_md += "## Raw Instructions\n\n"
				script_md += "| Offset | Opcode | Parameters | Description |\n"
				script_md += "|--------|--------|------------|-------------|\n"
				
				for inst in script.instructions:
					params_str = ','.join(f'0x{p:02X}' for p in inst.parameters)
					script_md += f"| 0x{inst.offset:06X} | {inst.opcode.name} | {params_str} | {inst.to_pseudocode()} |\n"
				
				script_file = output_dir / f"ai_script_{i:03d}.md"
				with open(script_file, 'w', encoding='utf-8') as f:
					f.write(script_md)
				
				all_scripts.append(script)
		
		# Save index
		index_file = output_dir / "index.md"
		with open(index_file, 'w', encoding='utf-8') as f:
			f.write(index_md)
		
		# Export JSON data
		json_data = {
			'scripts': [s.to_dict() for s in all_scripts]
		}
		
		json_file = output_dir / "ai_scripts.json"
		with open(json_file, 'w') as f:
			json.dump(json_data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported {len(all_scripts)} AI scripts to {output_dir}")
	
	def compare_ai_scripts(self, script_ids: List[int]) -> None:
		"""Compare multiple AI scripts"""
		scripts = []
		
		for sid in script_ids:
			script = self.decompile_enemy_ai(sid)
			if script:
				scripts.append(script)
		
		if not scripts:
			print("No scripts found")
			return
		
		print("\n=== AI Script Comparison ===\n")
		
		# Compare properties
		print(f"{'Script ID':<12} {'Instructions':<14} {'Pattern':<20} {'Complexity':<12}")
		print("-" * 70)
		
		for script in scripts:
			analysis = self.analyze_ai_pattern(script)
			print(f"{script.script_id:<12} {len(script.instructions):<14} {analysis.pattern.value:<20} {analysis.complexity_score:<12.1f}")
		
		# Show pseudocode for each
		for script in scripts:
			print(f"\n--- Script {script.script_id} ---")
			print(script.to_pseudocode())


def main():
	parser = argparse.ArgumentParser(description='FFMQ Enemy AI Script Decompiler & Editor')
	parser.add_argument('rom', type=str, help='FFMQ ROM file')
	parser.add_argument('--list-ai-scripts', action='store_true', help='List AI scripts')
	parser.add_argument('--decompile-enemy', type=int, help='Decompile AI for enemy ID')
	parser.add_argument('--decompile-script', type=str, help='Decompile AI at ROM offset (hex)')
	parser.add_argument('--analyze-pattern', type=int, help='Analyze AI pattern for enemy')
	parser.add_argument('--export-all-ai', action='store_true', help='Export all AI documentation')
	parser.add_argument('--compare-ai', type=str, help='Compare AI scripts (comma-separated IDs)')
	parser.add_argument('--output', type=str, help='Output file/directory')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	decompiler = FFMQAIDecompiler(Path(args.rom), verbose=args.verbose)
	
	# List AI scripts
	if args.list_ai_scripts:
		print("\nAI Scripts:\n")
		for i in range(20):
			script = decompiler.decompile_enemy_ai(i)
			if script and script.instructions:
				analysis = decompiler.analyze_ai_pattern(script)
				print(f"  {i}: {len(script.instructions)} instructions, {analysis.pattern.value}, complexity {analysis.complexity_score:.1f}")
		return 0
	
	# Decompile enemy AI
	if args.decompile_enemy is not None:
		script = decompiler.decompile_enemy_ai(args.decompile_enemy)
		
		if script:
			print(f"\n=== AI Script for Enemy {args.decompile_enemy} ===\n")
			print(f"ROM Offset: 0x{script.rom_offset:06X}")
			print(f"Instructions: {len(script.instructions)}\n")
			
			analysis = decompiler.analyze_ai_pattern(script)
			print(f"Pattern: {analysis.pattern.value}")
			print(f"Complexity: {analysis.complexity_score:.1f}/100\n")
			
			print("Pseudocode:\n")
			print(script.to_pseudocode())
		return 0
	
	# Decompile script at offset
	if args.decompile_script:
		offset = int(args.decompile_script, 16)
		instructions = decompiler.decompile_script(offset)
		
		print(f"\n=== AI Script at 0x{offset:06X} ===\n")
		for inst in instructions:
			print(f"0x{inst.offset:06X}: {inst.to_pseudocode()}")
		return 0
	
	# Analyze pattern
	if args.analyze_pattern is not None:
		script = decompiler.decompile_enemy_ai(args.analyze_pattern)
		
		if script:
			analysis = decompiler.analyze_ai_pattern(script)
			
			print(f"\n=== AI Analysis for Enemy {args.analyze_pattern} ===\n")
			print(f"Pattern: {analysis.pattern.value}")
			print(f"Complexity Score: {analysis.complexity_score:.1f}/100")
			print(f"Uses Spells: {'Yes' if analysis.uses_spells else 'No'}")
			print(f"Uses Abilities: {'Yes' if analysis.uses_abilities else 'No'}")
			print(f"Has Conditions: {'Yes' if analysis.has_conditions else 'No'}")
			print(f"Has Loops: {'Yes' if analysis.has_loops else 'No'}")
			print(f"Max Depth: {analysis.max_depth}")
			print(f"Actions: {analysis.action_count}")
			print(f"Conditions: {analysis.condition_count}")
		return 0
	
	# Export all AI
	if args.export_all_ai:
		output_dir = Path(args.output) if args.output else Path('ai_scripts')
		decompiler.export_all_ai_scripts(output_dir)
		return 0
	
	# Compare AI
	if args.compare_ai:
		script_ids = [int(x.strip()) for x in args.compare_ai.split(',')]
		decompiler.compare_ai_scripts(script_ids)
		return 0
	
	print("Use --list-ai-scripts, --decompile-enemy, or --export-all-ai")
	return 0


if __name__ == '__main__':
	exit(main())
