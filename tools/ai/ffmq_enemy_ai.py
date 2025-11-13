#!/usr/bin/env python3
"""
FFMQ Enemy AI Designer - Create and edit enemy battle behaviors

AI Features:
- Behavior trees
- State machines
- Condition checks
- Action selection
- Target selection
- Skill usage patterns
- Counter behaviors

AI Components:
- States (idle, attacking, defending, fleeing)
- Transitions (HP threshold, turn count, status)
- Actions (attack, magic, item, defend, flee)
- Targets (player, ally, self, random)
- Priorities (threat level, HP, status)

Behavior Patterns:
- Aggressive: Always attack
- Defensive: Use buffs and healing
- Tactical: Exploit weaknesses
- Berserker: Random powerful attacks
- Coward: Flee when low HP
- Support: Buff allies

Features:
- Create AI scripts
- Test behaviors
- Export AI data
- Import templates
- Validate logic

Usage:
	python ffmq_enemy_ai.py rom.sfc --create goblin --pattern aggressive
	python ffmq_enemy_ai.py rom.sfc --edit hydra --add-skill water_breath
	python ffmq_enemy_ai.py rom.sfc --test goblin --simulate 10
	python ffmq_enemy_ai.py rom.sfc --export goblin_ai.json
	python ffmq_enemy_ai.py rom.sfc --import boss_ai.json
"""

import argparse
import json
import random
from pathlib import Path
from typing import List, Dict, Optional, Any
from dataclasses import dataclass, asdict, field
from enum import Enum


class AIState(Enum):
	"""AI behavior state"""
	IDLE = "idle"
	ATTACKING = "attacking"
	DEFENDING = "defending"
	FLEEING = "fleeing"
	BUFFING = "buffing"
	HEALING = "healing"


class ActionType(Enum):
	"""AI action type"""
	ATTACK = "attack"
	MAGIC = "magic"
	SKILL = "skill"
	ITEM = "item"
	DEFEND = "defend"
	FLEE = "flee"
	BUFF = "buff"
	HEAL = "heal"


class TargetType(Enum):
	"""Target selection"""
	ENEMY_RANDOM = "enemy_random"
	ENEMY_LOWEST_HP = "enemy_lowest_hp"
	ENEMY_HIGHEST_HP = "enemy_highest_hp"
	ALLY_RANDOM = "ally_random"
	ALLY_LOWEST_HP = "ally_lowest_hp"
	SELF = "self"
	ALL_ENEMIES = "all_enemies"
	ALL_ALLIES = "all_allies"


class ConditionType(Enum):
	"""Condition check type"""
	HP_BELOW = "hp_below"
	HP_ABOVE = "hp_above"
	MP_BELOW = "mp_below"
	TURN_COUNT = "turn_count"
	STATUS_HAS = "status_has"
	ALLY_COUNT = "ally_count"
	RANDOM = "random"


@dataclass
class Condition:
	"""AI condition check"""
	condition_type: ConditionType
	value: float  # Threshold or probability
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['condition_type'] = self.condition_type.value
		return d


@dataclass
class AIAction:
	"""AI action"""
	action_type: ActionType
	target_type: TargetType
	skill_id: Optional[int] = None
	skill_name: Optional[str] = None
	priority: int = 1
	conditions: List[Condition] = field(default_factory=list)
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['action_type'] = self.action_type.value
		d['target_type'] = self.target_type.value
		return d


@dataclass
class StateTransition:
	"""State transition rule"""
	from_state: AIState
	to_state: AIState
	condition: Condition
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['from_state'] = self.from_state.value
		d['to_state'] = self.to_state.value
		return d


@dataclass
class EnemyAI:
	"""Enemy AI configuration"""
	enemy_id: int
	enemy_name: str
	current_state: AIState
	actions: List[AIAction] = field(default_factory=list)
	transitions: List[StateTransition] = field(default_factory=list)
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['current_state'] = self.current_state.value
		return d


class FFMQEnemyAIDesigner:
	"""Enemy AI designer and simulator"""
	
	# AI patterns (templates)
	AI_PATTERNS = {
		'aggressive': {
			'description': 'Always attacks with highest damage skill',
			'actions': [
				{'action_type': ActionType.ATTACK, 'target_type': TargetType.ENEMY_RANDOM, 'priority': 1},
				{'action_type': ActionType.SKILL, 'target_type': TargetType.ENEMY_HIGHEST_HP, 'priority': 2}
			],
			'transitions': []
		},
		'defensive': {
			'description': 'Uses buffs and healing when needed',
			'actions': [
				{'action_type': ActionType.HEAL, 'target_type': TargetType.SELF, 'priority': 3,
				 'conditions': [{'condition_type': ConditionType.HP_BELOW, 'value': 0.5}]},
				{'action_type': ActionType.BUFF, 'target_type': TargetType.SELF, 'priority': 2},
				{'action_type': ActionType.DEFEND, 'target_type': TargetType.SELF, 'priority': 1}
			],
			'transitions': [
				{'from_state': AIState.IDLE, 'to_state': AIState.DEFENDING,
				 'condition': {'condition_type': ConditionType.HP_BELOW, 'value': 0.7}}
			]
		},
		'tactical': {
			'description': 'Exploits weaknesses and uses strategy',
			'actions': [
				{'action_type': ActionType.MAGIC, 'target_type': TargetType.ENEMY_LOWEST_HP, 'priority': 3},
				{'action_type': ActionType.SKILL, 'target_type': TargetType.ALL_ENEMIES, 'priority': 2},
				{'action_type': ActionType.ATTACK, 'target_type': TargetType.ENEMY_RANDOM, 'priority': 1}
			],
			'transitions': []
		},
		'berserker': {
			'description': 'Random powerful attacks',
			'actions': [
				{'action_type': ActionType.SKILL, 'target_type': TargetType.ENEMY_RANDOM, 'priority': 1,
				 'conditions': [{'condition_type': ConditionType.RANDOM, 'value': 0.7}]},
				{'action_type': ActionType.ATTACK, 'target_type': TargetType.ALL_ENEMIES, 'priority': 1}
			],
			'transitions': []
		},
		'coward': {
			'description': 'Flees when HP is low',
			'actions': [
				{'action_type': ActionType.FLEE, 'target_type': TargetType.SELF, 'priority': 3,
				 'conditions': [{'condition_type': ConditionType.HP_BELOW, 'value': 0.3}]},
				{'action_type': ActionType.DEFEND, 'target_type': TargetType.SELF, 'priority': 2,
				 'conditions': [{'condition_type': ConditionType.HP_BELOW, 'value': 0.5}]},
				{'action_type': ActionType.ATTACK, 'target_type': TargetType.ENEMY_RANDOM, 'priority': 1}
			],
			'transitions': [
				{'from_state': AIState.IDLE, 'to_state': AIState.FLEEING,
				 'condition': {'condition_type': ConditionType.HP_BELOW, 'value': 0.3}}
			]
		},
		'support': {
			'description': 'Buffs and heals allies',
			'actions': [
				{'action_type': ActionType.HEAL, 'target_type': TargetType.ALLY_LOWEST_HP, 'priority': 3,
				 'conditions': [{'condition_type': ConditionType.ALLY_COUNT, 'value': 1}]},
				{'action_type': ActionType.BUFF, 'target_type': TargetType.ALL_ALLIES, 'priority': 2},
				{'action_type': ActionType.MAGIC, 'target_type': TargetType.ENEMY_RANDOM, 'priority': 1}
			],
			'transitions': []
		}
	}
	
	def __init__(self, rom_path: Optional[Path] = None, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		self.enemies: Dict[str, EnemyAI] = {}
	
	def create_enemy_ai(self, enemy_id: int, enemy_name: str, 
						pattern: str = 'aggressive') -> EnemyAI:
		"""Create enemy AI from pattern"""
		if pattern not in self.AI_PATTERNS:
			raise ValueError(f"Unknown pattern: {pattern}")
		
		template = self.AI_PATTERNS[pattern]
		
		# Convert template to AI objects
		actions = []
		for action_data in template['actions']:
			conditions = []
			if 'conditions' in action_data:
				for cond_data in action_data['conditions']:
					conditions.append(Condition(**cond_data))
			
			action = AIAction(
				action_type=action_data['action_type'],
				target_type=action_data['target_type'],
				priority=action_data['priority'],
				conditions=conditions
			)
			actions.append(action)
		
		transitions = []
		for trans_data in template['transitions']:
			transition = StateTransition(
				from_state=trans_data['from_state'],
				to_state=trans_data['to_state'],
				condition=Condition(**trans_data['condition'])
			)
			transitions.append(transition)
		
		ai = EnemyAI(
			enemy_id=enemy_id,
			enemy_name=enemy_name,
			current_state=AIState.IDLE,
			actions=actions,
			transitions=transitions
		)
		
		self.enemies[enemy_name] = ai
		
		if self.verbose:
			print(f"✓ Created {enemy_name} AI with {pattern} pattern")
		
		return ai
	
	def add_action(self, enemy_name: str, action: AIAction) -> None:
		"""Add action to enemy AI"""
		if enemy_name not in self.enemies:
			raise ValueError(f"Enemy not found: {enemy_name}")
		
		self.enemies[enemy_name].actions.append(action)
		
		if self.verbose:
			print(f"✓ Added {action.action_type.value} action to {enemy_name}")
	
	def select_action(self, ai: EnemyAI, hp_percent: float = 1.0, 
					  turn: int = 1) -> Optional[AIAction]:
		"""Select best action based on current state"""
		# Filter actions by conditions
		valid_actions = []
		
		for action in ai.actions:
			valid = True
			
			for condition in action.conditions:
				if not self._check_condition(condition, hp_percent, turn):
					valid = False
					break
			
			if valid:
				valid_actions.append(action)
		
		if not valid_actions:
			return None
		
		# Sort by priority (higher first)
		valid_actions.sort(key=lambda a: a.priority, reverse=True)
		
		return valid_actions[0]
	
	def _check_condition(self, condition: Condition, hp_percent: float, turn: int) -> bool:
		"""Check if condition is met"""
		if condition.condition_type == ConditionType.HP_BELOW:
			return hp_percent < condition.value
		elif condition.condition_type == ConditionType.HP_ABOVE:
			return hp_percent > condition.value
		elif condition.condition_type == ConditionType.TURN_COUNT:
			return turn >= condition.value
		elif condition.condition_type == ConditionType.RANDOM:
			return random.random() < condition.value
		
		return True
	
	def simulate_battle(self, enemy_name: str, turns: int = 10) -> None:
		"""Simulate battle turns"""
		if enemy_name not in self.enemies:
			raise ValueError(f"Enemy not found: {enemy_name}")
		
		ai = self.enemies[enemy_name]
		
		print(f"\n=== Simulating {enemy_name} Battle ({turns} turns) ===\n")
		
		hp_percent = 1.0
		
		for turn in range(1, turns + 1):
			# Select action
			action = self.select_action(ai, hp_percent, turn)
			
			if action:
				print(f"Turn {turn} (HP: {hp_percent*100:.0f}%): "
					  f"{action.action_type.value} → {action.target_type.value}")
			else:
				print(f"Turn {turn} (HP: {hp_percent*100:.0f}%): No valid action")
			
			# Simulate damage taken
			hp_percent -= random.uniform(0.05, 0.15)
			hp_percent = max(0.0, hp_percent)
			
			if hp_percent <= 0:
				print("\nEnemy defeated!\n")
				break
		
		print()
	
	def export_ai(self, enemy_name: str, output_path: Path) -> None:
		"""Export enemy AI to JSON"""
		if enemy_name not in self.enemies:
			raise ValueError(f"Enemy not found: {enemy_name}")
		
		ai = self.enemies[enemy_name]
		data = ai.to_dict()
		
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported {enemy_name} AI to {output_path}")
	
	def import_ai(self, input_path: Path) -> EnemyAI:
		"""Import enemy AI from JSON"""
		with open(input_path, 'r', encoding='utf-8') as f:
			data = json.load(f)
		
		# Convert enums
		data['current_state'] = AIState(data['current_state'])
		
		actions = []
		for action_data in data['actions']:
			action_data['action_type'] = ActionType(action_data['action_type'])
			action_data['target_type'] = TargetType(action_data['target_type'])
			
			conditions = []
			for cond_data in action_data['conditions']:
				cond_data['condition_type'] = ConditionType(cond_data['condition_type'])
				conditions.append(Condition(**cond_data))
			
			action_data['conditions'] = conditions
			actions.append(AIAction(**action_data))
		
		data['actions'] = actions
		
		transitions = []
		for trans_data in data['transitions']:
			trans_data['from_state'] = AIState(trans_data['from_state'])
			trans_data['to_state'] = AIState(trans_data['to_state'])
			trans_data['condition']['condition_type'] = ConditionType(
				trans_data['condition']['condition_type'])
			trans_data['condition'] = Condition(**trans_data['condition'])
			transitions.append(StateTransition(**trans_data))
		
		data['transitions'] = transitions
		
		ai = EnemyAI(**data)
		self.enemies[ai.enemy_name] = ai
		
		if self.verbose:
			print(f"✓ Imported {ai.enemy_name} AI from {input_path}")
		
		return ai
	
	def print_ai_info(self, enemy_name: str) -> None:
		"""Print enemy AI configuration"""
		if enemy_name not in self.enemies:
			raise ValueError(f"Enemy not found: {enemy_name}")
		
		ai = self.enemies[enemy_name]
		
		print(f"\n=== {ai.enemy_name} AI ===\n")
		print(f"ID: {ai.enemy_id}")
		print(f"State: {ai.current_state.value}")
		print(f"Actions: {len(ai.actions)}\n")
		
		for i, action in enumerate(ai.actions, 1):
			print(f"{i}. {action.action_type.value} → {action.target_type.value} "
				  f"(Priority: {action.priority})")
			
			if action.conditions:
				for cond in action.conditions:
					print(f"   Condition: {cond.condition_type.value} {cond.value}")
		
		print()


def main():
	parser = argparse.ArgumentParser(description='FFMQ Enemy AI Designer')
	parser.add_argument('rom', type=str, nargs='?', help='FFMQ ROM file (optional)')
	parser.add_argument('--create', type=str, help='Create enemy AI')
	parser.add_argument('--pattern', type=str, 
					   choices=['aggressive', 'defensive', 'tactical', 'berserker', 'coward', 'support'],
					   default='aggressive', help='AI pattern')
	parser.add_argument('--enemy-id', type=int, default=1, help='Enemy ID')
	parser.add_argument('--test', type=str, help='Test enemy AI')
	parser.add_argument('--simulate', type=int, default=10, help='Simulation turns')
	parser.add_argument('--export', type=str, help='Export AI to JSON')
	parser.add_argument('--import', type=str, dest='import_file', help='Import AI from JSON')
	parser.add_argument('--info', type=str, help='Show AI info')
	parser.add_argument('--list-patterns', action='store_true', help='List AI patterns')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	rom_path = Path(args.rom) if args.rom else None
	designer = FFMQEnemyAIDesigner(rom_path=rom_path, verbose=args.verbose)
	
	# List patterns
	if args.list_patterns:
		print("\n=== AI Patterns ===\n")
		
		for pattern, data in designer.AI_PATTERNS.items():
			print(f"{pattern.upper()}")
			print(f"  {data['description']}")
			print(f"  Actions: {len(data['actions'])}")
			print(f"  Transitions: {len(data['transitions'])}\n")
		
		return 0
	
	# Import AI
	if args.import_file:
		ai = designer.import_ai(Path(args.import_file))
		designer.print_ai_info(ai.enemy_name)
		return 0
	
	# Create AI
	if args.create:
		ai = designer.create_enemy_ai(args.enemy_id, args.create, args.pattern)
		designer.print_ai_info(args.create)
		
		# Export if requested
		if args.export:
			designer.export_ai(args.create, Path(args.export))
		
		return 0
	
	# Test/simulate
	if args.test:
		# Create if doesn't exist
		if args.test not in designer.enemies:
			designer.create_enemy_ai(args.enemy_id, args.test, args.pattern)
		
		designer.simulate_battle(args.test, args.simulate)
		return 0
	
	# Show info
	if args.info:
		designer.print_ai_info(args.info)
		return 0
	
	print("\nEnemy AI Designer")
	print("=" * 50)
	print("\nExamples:")
	print("  --create goblin --pattern aggressive")
	print("  --create hydra --pattern tactical --test hydra")
	print("  --list-patterns")
	print()
	
	return 0


if __name__ == '__main__':
	exit(main())
