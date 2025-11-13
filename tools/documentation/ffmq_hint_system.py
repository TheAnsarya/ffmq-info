#!/usr/bin/env python3
"""
FFMQ Hint System Designer - Context-sensitive in-game hints

Hint Features:
- Context-aware hints
- Progression tracking
- Spoiler levels
- Location-based hints
- Item hints
- Boss hints
- Puzzle hints

Hint Types:
- Next objective
- Item location
- Boss strategy
- Puzzle solution
- Character location
- Equipment upgrade
- Hidden treasure

Spoiler Levels:
- None: No spoilers
- Vague: General direction
- Specific: Exact location
- Complete: Full solution

Hint Triggers:
- Player location
- Current quest
- Items obtained
- Bosses defeated
- Time spent
- Deaths count

Features:
- Create hint database
- Add custom hints
- Test hint system
- Export hint data
- Generate hint NPC dialogue

Usage:
	python ffmq_hint_system.py --create
	python ffmq_hint_system.py --add-hint "Talk to the elder in Foresta" --trigger foresta_start
	python ffmq_hint_system.py --test --location foresta --progress 0
	python ffmq_hint_system.py --export hints.json
	python ffmq_hint_system.py --spoiler-level vague
"""

import argparse
import json
from pathlib import Path
from typing import List, Dict, Optional, Set
from dataclasses import dataclass, asdict, field
from enum import Enum


class SpoilerLevel(Enum):
	"""Spoiler level"""
	NONE = 0
	VAGUE = 1
	SPECIFIC = 2
	COMPLETE = 3


class HintType(Enum):
	"""Hint category"""
	OBJECTIVE = "objective"
	ITEM = "item"
	BOSS = "boss"
	PUZZLE = "puzzle"
	LOCATION = "location"
	EQUIPMENT = "equipment"
	SECRET = "secret"


@dataclass
class HintCondition:
	"""Condition for showing hint"""
	condition_type: str  # location, quest, item, boss, flag
	value: str
	comparison: str = "=="  # ==, !=, >, <, >=, <=, in
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class Hint:
	"""Single hint"""
	hint_id: str
	hint_type: HintType
	spoiler_level: SpoilerLevel
	text: str
	conditions: List[HintCondition] = field(default_factory=list)
	priority: int = 1  # Higher priority shown first
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['hint_type'] = self.hint_type.value
		d['spoiler_level'] = self.spoiler_level.value
		return d


@dataclass
class GameProgress:
	"""Player progress tracking"""
	location: str
	quests_completed: Set[str] = field(default_factory=set)
	items_obtained: Set[str] = field(default_factory=set)
	bosses_defeated: Set[str] = field(default_factory=set)
	flags_set: Set[str] = field(default_factory=set)
	level: int = 1
	playtime: int = 0  # seconds


class FFMQHintSystem:
	"""Hint system designer"""
	
	# Default hint database
	DEFAULT_HINTS = [
		{
			'hint_id': 'foresta_start',
			'hint_type': HintType.OBJECTIVE,
			'spoiler_level': SpoilerLevel.VAGUE,
			'text': 'The elder in Foresta might have information about your quest.',
			'conditions': [
				{'condition_type': 'location', 'value': 'foresta', 'comparison': '=='}
			],
			'priority': 1
		},
		{
			'hint_id': 'venus_key_location',
			'hint_type': HintType.ITEM,
			'spoiler_level': SpoilerLevel.SPECIFIC,
			'text': 'The Venus Key can be obtained by defeating the Hydra at Falls Basin.',
			'conditions': [
				{'condition_type': 'item', 'value': 'venus_key', 'comparison': 'not in'}
			],
			'priority': 2
		},
		{
			'hint_id': 'hydra_weakness',
			'hint_type': HintType.BOSS,
			'spoiler_level': SpoilerLevel.SPECIFIC,
			'text': 'The Hydra is weak to fire magic. Target one head at a time.',
			'conditions': [
				{'condition_type': 'boss', 'value': 'hydra', 'comparison': 'not in'},
				{'condition_type': 'location', 'value': 'falls_basin', 'comparison': '=='}
			],
			'priority': 3
		},
		{
			'hint_id': 'sealed_temple_puzzle',
			'hint_type': HintType.PUZZLE,
			'spoiler_level': SpoilerLevel.VAGUE,
			'text': 'Pay attention to the order of the crystals in the Sealed Temple.',
			'conditions': [
				{'condition_type': 'location', 'value': 'sealed_temple', 'comparison': '=='}
			],
			'priority': 2
		},
		{
			'hint_id': 'aquaria_access',
			'hint_type': HintType.LOCATION,
			'spoiler_level': SpoilerLevel.SPECIFIC,
			'text': 'You need the Venus Key to access Aquaria from Foresta.',
			'conditions': [
				{'condition_type': 'item', 'value': 'venus_key', 'comparison': 'not in'},
				{'condition_type': 'quest', 'value': 'foresta_complete', 'comparison': 'in'}
			],
			'priority': 2
		},
		{
			'hint_id': 'upgrade_equipment',
			'hint_type': HintType.EQUIPMENT,
			'spoiler_level': SpoilerLevel.VAGUE,
			'text': 'Visit the shop to upgrade your equipment before challenging the boss.',
			'conditions': [
				{'condition_type': 'level', 'value': '8', 'comparison': '>='}
			],
			'priority': 1
		},
		{
			'hint_id': 'hidden_chest_foresta',
			'hint_type': HintType.SECRET,
			'spoiler_level': SpoilerLevel.COMPLETE,
			'text': 'There is a hidden chest behind the waterfall in Foresta Forest.',
			'conditions': [
				{'condition_type': 'location', 'value': 'foresta', 'comparison': '=='}
			],
			'priority': 1
		}
	]
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.hints: List[Hint] = []
		self._load_default_hints()
	
	def _load_default_hints(self) -> None:
		"""Load default hint database"""
		for hint_data in self.DEFAULT_HINTS:
			conditions = [HintCondition(**c) for c in hint_data['conditions']]
			
			hint = Hint(
				hint_id=hint_data['hint_id'],
				hint_type=hint_data['hint_type'],
				spoiler_level=hint_data['spoiler_level'],
				text=hint_data['text'],
				conditions=conditions,
				priority=hint_data['priority']
			)
			
			self.hints.append(hint)
	
	def add_hint(self, hint: Hint) -> None:
		"""Add hint to database"""
		self.hints.append(hint)
		
		if self.verbose:
			print(f"✓ Added hint: {hint.hint_id}")
	
	def get_hints_for_progress(self, progress: GameProgress, 
							   max_spoiler: SpoilerLevel = SpoilerLevel.SPECIFIC) -> List[Hint]:
		"""Get applicable hints for current progress"""
		applicable = []
		
		for hint in self.hints:
			# Check spoiler level
			if hint.spoiler_level.value > max_spoiler.value:
				continue
			
			# Check all conditions
			if self._check_conditions(hint.conditions, progress):
				applicable.append(hint)
		
		# Sort by priority (higher first)
		applicable.sort(key=lambda h: h.priority, reverse=True)
		
		return applicable
	
	def _check_conditions(self, conditions: List[HintCondition], 
						  progress: GameProgress) -> bool:
		"""Check if all conditions are met"""
		for condition in conditions:
			if not self._check_condition(condition, progress):
				return False
		
		return True
	
	def _check_condition(self, condition: HintCondition, progress: GameProgress) -> bool:
		"""Check single condition"""
		ctype = condition.condition_type
		value = condition.value
		comp = condition.comparison
		
		if ctype == 'location':
			actual = progress.location
			return self._compare(actual, value, comp)
		
		elif ctype == 'quest':
			if comp == 'in':
				return value in progress.quests_completed
			elif comp == 'not in':
				return value not in progress.quests_completed
		
		elif ctype == 'item':
			if comp == 'in':
				return value in progress.items_obtained
			elif comp == 'not in':
				return value not in progress.items_obtained
		
		elif ctype == 'boss':
			if comp == 'in':
				return value in progress.bosses_defeated
			elif comp == 'not in':
				return value not in progress.bosses_defeated
		
		elif ctype == 'flag':
			if comp == 'in':
				return value in progress.flags_set
			elif comp == 'not in':
				return value not in progress.flags_set
		
		elif ctype == 'level':
			actual = progress.level
			try:
				target = int(value)
				return self._compare(actual, target, comp)
			except ValueError:
				return False
		
		return False
	
	def _compare(self, actual: any, expected: any, comparison: str) -> bool:
		"""Compare values"""
		if comparison == '==':
			return actual == expected
		elif comparison == '!=':
			return actual != expected
		elif comparison == '>':
			return actual > expected
		elif comparison == '<':
			return actual < expected
		elif comparison == '>=':
			return actual >= expected
		elif comparison == '<=':
			return actual <= expected
		elif comparison == 'in':
			return actual in expected
		elif comparison == 'not in':
			return actual not in expected
		
		return False
	
	def generate_npc_dialogue(self, hint: Hint) -> str:
		"""Generate NPC dialogue for hint"""
		dialogue_templates = {
			HintType.OBJECTIVE: [
				"I heard that {hint}",
				"You should know that {hint}",
				"The word is that {hint}"
			],
			HintType.ITEM: [
				"They say {hint}",
				"I've heard {hint}",
				"Rumor has it {hint}"
			],
			HintType.BOSS: [
				"Be careful! {hint}",
				"A warning: {hint}",
				"Listen well: {hint}"
			],
			HintType.PUZZLE: [
				"A tip: {hint}",
				"Here's a clue: {hint}",
				"Remember: {hint}"
			],
			HintType.LOCATION: [
				"To get there, {hint}",
				"For your journey: {hint}",
				"Know this: {hint}"
			],
			HintType.EQUIPMENT: [
				"Some advice: {hint}",
				"For your safety: {hint}",
				"Don't forget: {hint}"
			],
			HintType.SECRET: [
				"Psst... {hint}",
				"I shouldn't tell you this, but {hint}",
				"Keep this secret: {hint}"
			]
		}
		
		templates = dialogue_templates.get(hint.hint_type, ["Did you know? {hint}"])
		template = templates[0]  # Use first template
		
		return template.format(hint=hint.text)
	
	def export_json(self, output_path: Path) -> None:
		"""Export hints to JSON"""
		data = {
			'hints': [h.to_dict() for h in self.hints]
		}
		
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported {len(self.hints)} hints to {output_path}")
	
	def import_json(self, input_path: Path) -> None:
		"""Import hints from JSON"""
		with open(input_path, 'r', encoding='utf-8') as f:
			data = json.load(f)
		
		self.hints = []
		
		for hint_data in data['hints']:
			# Convert enums
			hint_data['hint_type'] = HintType(hint_data['hint_type'])
			hint_data['spoiler_level'] = SpoilerLevel(hint_data['spoiler_level'])
			
			# Convert conditions
			conditions = [HintCondition(**c) for c in hint_data['conditions']]
			hint_data['conditions'] = conditions
			
			hint = Hint(**hint_data)
			self.hints.append(hint)
		
		if self.verbose:
			print(f"✓ Imported {len(self.hints)} hints from {input_path}")
	
	def print_hints_table(self, hints: List[Hint]) -> None:
		"""Print hints in table format"""
		if not hints:
			print("No hints available")
			return
		
		print(f"\n{'ID':<20} {'Type':<12} {'Spoiler':<10} {'Priority':<8}")
		print('-' * 50)
		
		for hint in hints:
			print(f"{hint.hint_id:<20} {hint.hint_type.value:<12} "
				  f"{hint.spoiler_level.name:<10} {hint.priority:<8}")
		
		print()


def main():
	parser = argparse.ArgumentParser(description='FFMQ Hint System Designer')
	parser.add_argument('--create', action='store_true', help='Create hint database')
	parser.add_argument('--add-hint', type=str, help='Add custom hint text')
	parser.add_argument('--trigger', type=str, help='Hint trigger condition')
	parser.add_argument('--test', action='store_true', help='Test hint system')
	parser.add_argument('--location', type=str, default='foresta', help='Test location')
	parser.add_argument('--progress', type=int, default=0, help='Test progress level')
	parser.add_argument('--spoiler-level', type=str, 
					   choices=['none', 'vague', 'specific', 'complete'],
					   default='specific', help='Max spoiler level')
	parser.add_argument('--export', type=str, help='Export to JSON')
	parser.add_argument('--import', type=str, dest='import_file', help='Import from JSON')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	system = FFMQHintSystem(verbose=args.verbose)
	
	# Import hints
	if args.import_file:
		system.import_json(Path(args.import_file))
		return 0
	
	# Add custom hint
	if args.add_hint and args.trigger:
		condition = HintCondition(
			condition_type='location',
			value=args.trigger,
			comparison='=='
		)
		
		hint = Hint(
			hint_id=f'custom_{args.trigger}',
			hint_type=HintType.OBJECTIVE,
			spoiler_level=SpoilerLevel.VAGUE,
			text=args.add_hint,
			conditions=[condition],
			priority=1
		)
		
		system.add_hint(hint)
		print(f"Added hint: {args.add_hint}")
		return 0
	
	# Test hint system
	if args.test:
		# Parse spoiler level
		spoiler_map = {
			'none': SpoilerLevel.NONE,
			'vague': SpoilerLevel.VAGUE,
			'specific': SpoilerLevel.SPECIFIC,
			'complete': SpoilerLevel.COMPLETE
		}
		max_spoiler = spoiler_map[args.spoiler_level]
		
		# Create test progress
		progress = GameProgress(
			location=args.location,
			level=args.progress
		)
		
		print(f"\n=== Testing Hints ===")
		print(f"Location: {progress.location}")
		print(f"Max Spoiler: {max_spoiler.name}")
		print(f"Progress Level: {progress.level}\n")
		
		# Get applicable hints
		hints = system.get_hints_for_progress(progress, max_spoiler)
		
		if hints:
			print(f"Found {len(hints)} applicable hint(s):\n")
			
			for i, hint in enumerate(hints, 1):
				print(f"{i}. [{hint.hint_type.value}] {hint.text}")
				
				# Show NPC dialogue
				dialogue = system.generate_npc_dialogue(hint)
				print(f"   NPC: \"{dialogue}\"\n")
		else:
			print("No hints available for current progress")
		
		return 0
	
	# Export hints
	if args.export:
		system.export_json(Path(args.export))
		return 0
	
	# Show hint database
	if args.create or True:  # Default action
		print("\n=== Hint Database ===\n")
		print(f"Total hints: {len(system.hints)}\n")
		
		system.print_hints_table(system.hints)
		
		# Show sample
		if system.hints:
			sample = system.hints[0]
			print(f"Sample hint: {sample.hint_id}")
			print(f"  Text: {sample.text}")
			print(f"  Type: {sample.hint_type.value}")
			print(f"  Spoiler: {sample.spoiler_level.name}")
			print(f"  Conditions: {len(sample.conditions)}")
			
			dialogue = system.generate_npc_dialogue(sample)
			print(f"  NPC Dialogue: \"{dialogue}\"\n")
	
	return 0


if __name__ == '__main__':
	exit(main())
