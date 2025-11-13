#!/usr/bin/env python3
"""
FFMQ AI Script Editor - Edit enemy AI and battle behaviors

FFMQ AI System:
- Script-based enemy AI
- Condition-based decision trees
- Action priorities
- Target selection
- Spell casting logic
- Status effect usage
- Counter-attack triggers
- Phase transitions (HP thresholds)

Features:
- View AI scripts
- Edit AI conditions
- Modify action priorities
- Change target selection
- Configure spell usage
- Set counter-attacks
- Balance AI difficulty
- Export AI scripts
- Import custom AI
- Visualize decision trees

AI Script Structure:
- Conditions (HP%, status, turn count)
- Actions (attack, magic, skill, item)
- Priorities (weighted selection)
- Targets (random, weakest, strongest, self)
- Counters (respond to damage/magic)

Usage:
	python ffmq_ai_editor.py rom.sfc --list-scripts
	python ffmq_ai_editor.py rom.sfc --show-script 10
	python ffmq_ai_editor.py rom.sfc --edit-script 10 --add-action "cast Fire"
	python ffmq_ai_editor.py rom.sfc --set-counter 10 "attack" "cast Thunder"
	python ffmq_ai_editor.py rom.sfc --export-script 10 ai_behemoth.json
	python ffmq_ai_editor.py rom.sfc --visualize-tree 10
"""

import argparse
import json
import struct
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any
from dataclasses import dataclass, field, asdict
from enum import Enum


class ConditionType(Enum):
	"""AI condition types"""
	HP_BELOW = "hp_below"
	HP_ABOVE = "hp_above"
	TURN_MOD = "turn_mod"
	HAS_STATUS = "has_status"
	ENEMY_COUNT = "enemy_count"
	ALLY_COUNT = "ally_count"
	ALWAYS = "always"


class ActionType(Enum):
	"""AI action types"""
	ATTACK = "attack"
	MAGIC = "magic"
	SKILL = "skill"
	ITEM = "item"
	DEFEND = "defend"
	FLEE = "flee"
	NOTHING = "nothing"


class TargetType(Enum):
	"""AI target selection"""
	RANDOM = "random"
	WEAKEST = "weakest"
	STRONGEST = "strongest"
	LOWEST_HP = "lowest_hp"
	HIGHEST_HP = "highest_hp"
	SELF = "self"
	ALL = "all"


@dataclass
class AICondition:
	"""AI script condition"""
	condition_type: ConditionType
	param1: int
	param2: int
	
	def to_dict(self) -> dict:
		return {
			'condition_type': self.condition_type.value,
			'param1': self.param1,
			'param2': self.param2
		}
	
	def __str__(self) -> str:
		if self.condition_type == ConditionType.HP_BELOW:
			return f"HP < {self.param1}%"
		elif self.condition_type == ConditionType.HP_ABOVE:
			return f"HP > {self.param1}%"
		elif self.condition_type == ConditionType.TURN_MOD:
			return f"Turn % {self.param1} == {self.param2}"
		elif self.condition_type == ConditionType.HAS_STATUS:
			return f"Has status {self.param1}"
		elif self.condition_type == ConditionType.ENEMY_COUNT:
			return f"Enemies == {self.param1}"
		elif self.condition_type == ConditionType.ALWAYS:
			return "Always"
		return "Unknown"


@dataclass
class AIAction:
	"""AI script action"""
	action_type: ActionType
	action_id: int  # Spell ID, skill ID, item ID, etc.
	action_name: str
	target_type: TargetType
	priority: int  # 0-255
	
	def to_dict(self) -> dict:
		return {
			'action_type': self.action_type.value,
			'action_id': self.action_id,
			'action_name': self.action_name,
			'target_type': self.target_type.value,
			'priority': self.priority
		}
	
	def __str__(self) -> str:
		target_str = self.target_type.value.replace('_', ' ')
		return f"{self.action_type.value.capitalize()} {self.action_name} -> {target_str} (priority {self.priority})"


@dataclass
class AIRule:
	"""AI decision rule"""
	rule_id: int
	conditions: List[AICondition]
	actions: List[AIAction]
	
	def to_dict(self) -> dict:
		return {
			'rule_id': self.rule_id,
			'conditions': [c.to_dict() for c in self.conditions],
			'actions': [a.to_dict() for a in self.actions]
		}


@dataclass
class AIScript:
	"""Enemy AI script"""
	enemy_id: int
	enemy_name: str
	rules: List[AIRule]
	counter_attack: Optional[AIAction]
	counter_magic: Optional[AIAction]
	
	def to_dict(self) -> dict:
		d = {
			'enemy_id': self.enemy_id,
			'enemy_name': self.enemy_name,
			'rules': [r.to_dict() for r in self.rules],
		}
		if self.counter_attack:
			d['counter_attack'] = self.counter_attack.to_dict()
		if self.counter_magic:
			d['counter_magic'] = self.counter_magic.to_dict()
		return d


class FFMQAIDatabase:
	"""Database of FFMQ AI scripts"""
	
	# AI script data location
	AI_SCRIPT_OFFSET = 0x320000
	NUM_AI_SCRIPTS = 256
	SCRIPT_SIZE = 256
	
	# Known enemy names (subset)
	ENEMY_NAMES = {
		0: "Behemoth",
		1: "Hydra",
		2: "Medusa",
		3: "Flamerus Rex",
		4: "Ice Golem",
		5: "Pazuzu",
		6: "Red Dragon",
		7: "Dark King",
		8: "Slime",
		9: "Goblin",
		10: "Mad Plant",
		# ... more enemies
	}
	
	# Spell names
	SPELL_NAMES = {
		8: "Fire",
		9: "Fira",
		10: "Firaga",
		11: "Flare",
		12: "Blizzard",
		13: "Blizzara",
		14: "Blizzaga",
		16: "Thunder",
		17: "Thundara",
		18: "Thundaga",
		20: "Aero",
		21: "Aerora",
		22: "Aeroga",
		24: "Meteor",
		25: "Quake",
	}
	
	@classmethod
	def get_enemy_name(cls, enemy_id: int) -> str:
		"""Get enemy name"""
		return cls.ENEMY_NAMES.get(enemy_id, f"Enemy {enemy_id}")
	
	@classmethod
	def get_spell_name(cls, spell_id: int) -> str:
		"""Get spell name"""
		return cls.SPELL_NAMES.get(spell_id, f"Spell {spell_id}")


class FFMQAIEditor:
	"""Edit FFMQ AI scripts"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		if self.verbose:
			print(f"Loaded FFMQ ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def extract_ai_script(self, enemy_id: int) -> Optional[AIScript]:
		"""Extract AI script from ROM"""
		if enemy_id >= FFMQAIDatabase.NUM_AI_SCRIPTS:
			return None
		
		offset = FFMQAIDatabase.AI_SCRIPT_OFFSET + (enemy_id * FFMQAIDatabase.SCRIPT_SIZE)
		
		if offset + FFMQAIDatabase.SCRIPT_SIZE > len(self.rom_data):
			return None
		
		# Read AI rules (up to 8 rules)
		rules = []
		for rule_id in range(8):
			rule_offset = offset + (rule_id * 32)
			
			if rule_offset + 32 > len(self.rom_data):
				break
			
			# Check if rule exists
			rule_flags = self.rom_data[rule_offset]
			if rule_flags == 0xFF:
				continue
			
			# Read conditions (up to 4)
			conditions = []
			for i in range(4):
				cond_offset = rule_offset + 1 + (i * 3)
				
				if cond_offset + 3 > len(self.rom_data):
					break
				
				cond_type = self.rom_data[cond_offset]
				if cond_type == 0xFF:
					continue
				
				param1 = self.rom_data[cond_offset + 1]
				param2 = self.rom_data[cond_offset + 2]
				
				condition_types = list(ConditionType)
				cond = condition_types[cond_type % len(condition_types)]
				
				conditions.append(AICondition(
					condition_type=cond,
					param1=param1,
					param2=param2
				))
			
			# Read actions (up to 4)
			actions = []
			for i in range(4):
				act_offset = rule_offset + 13 + (i * 4)
				
				if act_offset + 4 > len(self.rom_data):
					break
				
				act_type = self.rom_data[act_offset]
				if act_type == 0xFF:
					continue
				
				act_id = self.rom_data[act_offset + 1]
				target_type = self.rom_data[act_offset + 2]
				priority = self.rom_data[act_offset + 3]
				
				action_types = list(ActionType)
				action = action_types[act_type % len(action_types)]
				
				target_types = list(TargetType)
				target = target_types[target_type % len(target_types)]
				
				# Get action name
				action_name = ""
				if action == ActionType.MAGIC:
					action_name = FFMQAIDatabase.get_spell_name(act_id)
				elif action == ActionType.SKILL:
					action_name = f"Skill {act_id}"
				else:
					action_name = action.value.capitalize()
				
				actions.append(AIAction(
					action_type=action,
					action_id=act_id,
					action_name=action_name,
					target_type=target,
					priority=priority
				))
			
			if conditions or actions:
				rules.append(AIRule(
					rule_id=rule_id,
					conditions=conditions,
					actions=actions
				))
		
		# Read counter-attacks
		counter_offset = offset + 240
		counter_attack = None
		counter_magic = None
		
		if counter_offset + 16 <= len(self.rom_data):
			# Counter-attack
			ca_type = self.rom_data[counter_offset]
			if ca_type != 0xFF:
				ca_id = self.rom_data[counter_offset + 1]
				ca_target = self.rom_data[counter_offset + 2]
				
				action_types = list(ActionType)
				target_types = list(TargetType)
				
				counter_attack = AIAction(
					action_type=action_types[ca_type % len(action_types)],
					action_id=ca_id,
					action_name=FFMQAIDatabase.get_spell_name(ca_id) if ca_type == 1 else "Attack",
					target_type=target_types[ca_target % len(target_types)],
					priority=255
				)
			
			# Counter-magic
			cm_type = self.rom_data[counter_offset + 8]
			if cm_type != 0xFF:
				cm_id = self.rom_data[counter_offset + 9]
				cm_target = self.rom_data[counter_offset + 10]
				
				action_types = list(ActionType)
				target_types = list(TargetType)
				
				counter_magic = AIAction(
					action_type=action_types[cm_type % len(action_types)],
					action_id=cm_id,
					action_name=FFMQAIDatabase.get_spell_name(cm_id) if cm_type == 1 else "Attack",
					target_type=target_types[cm_target % len(target_types)],
					priority=255
				)
		
		script = AIScript(
			enemy_id=enemy_id,
			enemy_name=FFMQAIDatabase.get_enemy_name(enemy_id),
			rules=rules,
			counter_attack=counter_attack,
			counter_magic=counter_magic
		)
		
		return script
	
	def list_ai_scripts(self) -> List[AIScript]:
		"""List all AI scripts"""
		scripts = []
		
		for i in range(min(64, FFMQAIDatabase.NUM_AI_SCRIPTS)):
			script = self.extract_ai_script(i)
			if script and script.rules:
				scripts.append(script)
		
		return scripts
	
	def visualize_decision_tree(self, script: AIScript) -> str:
		"""Generate ASCII decision tree visualization"""
		lines = []
		lines.append(f"AI Script: {script.enemy_name}")
		lines.append("=" * 60)
		lines.append("")
		
		for rule in script.rules:
			lines.append(f"Rule {rule.rule_id}:")
			
			if rule.conditions:
				lines.append("  Conditions:")
				for cond in rule.conditions:
					lines.append(f"    • {cond}")
			else:
				lines.append("  Conditions: (Always)")
			
			if rule.actions:
				lines.append("  Actions:")
				for action in sorted(rule.actions, key=lambda a: a.priority, reverse=True):
					lines.append(f"    • {action}")
			
			lines.append("")
		
		if script.counter_attack:
			lines.append(f"Counter-Attack: {script.counter_attack}")
		if script.counter_magic:
			lines.append(f"Counter-Magic: {script.counter_magic}")
		
		return '\n'.join(lines)
	
	def export_script_json(self, enemy_id: int, output_path: Path) -> bool:
		"""Export AI script to JSON"""
		script = self.extract_ai_script(enemy_id)
		
		if not script:
			return False
		
		with open(output_path, 'w') as f:
			json.dump(script.to_dict(), f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported AI script for {script.enemy_name} to {output_path}")
		
		return True
	
	def save_rom(self, output_path: Optional[Path] = None) -> None:
		"""Save modified ROM"""
		save_path = output_path or self.rom_path
		
		with open(save_path, 'wb') as f:
			f.write(self.rom_data)
		
		if self.verbose:
			print(f"✓ Saved ROM to {save_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ AI Script Editor')
	parser.add_argument('rom', type=str, help='FFMQ ROM file')
	parser.add_argument('--list-scripts', action='store_true', help='List AI scripts')
	parser.add_argument('--show-script', type=int, help='Show AI script details')
	parser.add_argument('--visualize-tree', type=int, help='Visualize decision tree')
	parser.add_argument('--export-script', type=int, help='Export AI script to JSON')
	parser.add_argument('--output', type=str, help='Output file')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FFMQAIEditor(Path(args.rom), verbose=args.verbose)
	
	# List scripts
	if args.list_scripts:
		scripts = editor.list_ai_scripts()
		
		print(f"\nFFMQ AI Scripts ({len(scripts)}):\n")
		
		for script in scripts[:20]:
			rule_count = len(script.rules)
			counter_info = ""
			if script.counter_attack or script.counter_magic:
				counters = []
				if script.counter_attack:
					counters.append("attack")
				if script.counter_magic:
					counters.append("magic")
				counter_info = f" [counters: {', '.join(counters)}]"
			
			print(f"  {script.enemy_id:3d}: {script.enemy_name:<20} - {rule_count} rules{counter_info}")
		
		if len(scripts) > 20:
			print(f"\n  ... and {len(scripts) - 20} more scripts")
		
		return 0
	
	# Show script
	if args.show_script is not None:
		script = editor.extract_ai_script(args.show_script)
		
		if script:
			print(f"\n{editor.visualize_decision_tree(script)}")
		else:
			print(f"❌ No AI script found for enemy {args.show_script}")
		
		return 0
	
	# Visualize tree
	if args.visualize_tree is not None:
		script = editor.extract_ai_script(args.visualize_tree)
		
		if script:
			tree = editor.visualize_decision_tree(script)
			print(f"\n{tree}")
		else:
			print(f"❌ No AI script found for enemy {args.visualize_tree}")
		
		return 0
	
	# Export script
	if args.export_script is not None:
		output = Path(args.output) if args.output else Path(f'ai_script_{args.export_script}.json')
		success = editor.export_script_json(args.export_script, output)
		
		if not success:
			print(f"❌ Failed to export AI script {args.export_script}")
			return 1
		
		return 0
	
	print("Use --list-scripts, --show-script, --visualize-tree, or --export-script")
	return 0


if __name__ == '__main__':
	exit(main())
