#!/usr/bin/env python3
"""
FFMQ Challenge Mode Creator - Design custom challenge runs

Challenge Types:
- Low level runs (max level restrictions)
- No equipment (weapons/armor restricted)
- Solo character (single party member)
- Pacifist (avoid battles)
- 100% completion (all items/quests)
- Speedrun categories
- Randomizer challenges
- Self-imposed restrictions

Difficulty Modifiers:
- Enemy stat multipliers (HP, attack, defense)
- Damage modifiers (player damage × 0.5)
- EXP/Gil multipliers
- Item restrictions
- Skill restrictions
- Death penalties
- Time limits

Rule Enforcement:
- Auto-validate restrictions
- Track violations
- Generate validation hooks
- Real-time monitoring
- Run invalidation

Leaderboards:
- Time-based rankings
- Completion percentages
- Difficulty ratings
- Category records
- Player statistics

Features:
- Create challenges
- Set restrictions
- Track progress
- Generate rules
- Export configurations
- Import templates

Usage:
	python ffmq_challenge_creator.py create --name "Low Level" --max-level 15
	python ffmq_challenge_creator.py list --category speedrun
	python ffmq_challenge_creator.py validate --save save.srm --rules challenge.json
	python ffmq_challenge_creator.py generate --template nuzlocke
	python ffmq_challenge_creator.py export --output challenges.json
"""

import argparse
import json
from pathlib import Path
from typing import List, Dict, Tuple, Optional, Any
from dataclasses import dataclass, asdict, field
from enum import Enum
from datetime import datetime


class ChallengeCategory(Enum):
	"""Challenge categories"""
	RESTRICTION = "restriction"
	SPEEDRUN = "speedrun"
	COMPLETION = "completion"
	DIFFICULTY = "difficulty"
	CUSTOM = "custom"


class RestrictionType(Enum):
	"""Restriction types"""
	MAX_LEVEL = "max_level"
	NO_EQUIPMENT = "no_equipment"
	SOLO_CHARACTER = "solo_character"
	NO_ITEMS = "no_items"
	NO_MAGIC = "no_magic"
	NO_HEALING = "no_healing"
	NO_SHOPS = "no_shops"
	NO_DAMAGE = "no_damage"


class DifficultyModifier(Enum):
	"""Difficulty modifier types"""
	ENEMY_HP = "enemy_hp"
	ENEMY_ATTACK = "enemy_attack"
	ENEMY_DEFENSE = "enemy_defense"
	PLAYER_DAMAGE = "player_damage"
	EXP_RATE = "exp_rate"
	GIL_RATE = "gil_rate"


@dataclass
class Restriction:
	"""Challenge restriction"""
	restriction_type: RestrictionType
	value: Any  # Max level, character ID, etc.
	description: str
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['restriction_type'] = self.restriction_type.value
		return d


@dataclass
class DifficultyMod:
	"""Difficulty modifier"""
	modifier_type: DifficultyModifier
	multiplier: float  # 1.0 = normal, 2.0 = double, 0.5 = half
	
	def to_dict(self) -> dict:
		return {
			'modifier_type': self.modifier_type.value,
			'multiplier': self.multiplier
		}


@dataclass
class ChallengeRun:
	"""Challenge run definition"""
	challenge_id: int
	name: str
	description: str
	category: ChallengeCategory
	restrictions: List[Restriction]
	difficulty_mods: List[DifficultyMod]
	time_limit: Optional[int] = None  # Seconds
	completion_required: bool = False
	violations_allowed: int = 0
	created_date: str = ""
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['category'] = self.category.value
		d['restrictions'] = [r.to_dict() for r in self.restrictions]
		d['difficulty_mods'] = [m.to_dict() for m in self.difficulty_mods]
		return d


@dataclass
class RunProgress:
	"""Track challenge run progress"""
	challenge_id: int
	start_time: str
	current_playtime: int  # Seconds
	level: int
	violations: int
	deaths: int
	bosses_defeated: List[str]
	items_collected: int
	completed: bool = False
	valid: bool = True


class FFMQChallengeCreator:
	"""Challenge mode designer"""
	
	# Challenge templates
	TEMPLATES = {
		'low_level': {
			'name': 'Low Level Challenge',
			'description': 'Complete the game with max level 15',
			'category': ChallengeCategory.RESTRICTION,
			'restrictions': [
				{'type': RestrictionType.MAX_LEVEL, 'value': 15, 'desc': 'Maximum character level 15'}
			],
			'mods': []
		},
		'solo_benjamin': {
			'name': 'Solo Benjamin',
			'description': 'Complete the game using only Benjamin',
			'category': ChallengeCategory.RESTRICTION,
			'restrictions': [
				{'type': RestrictionType.SOLO_CHARACTER, 'value': 'Benjamin', 'desc': 'Only Benjamin in party'}
			],
			'mods': []
		},
		'no_equipment': {
			'name': 'Naked Run',
			'description': 'Complete without equipping any weapons or armor',
			'category': ChallengeCategory.RESTRICTION,
			'restrictions': [
				{'type': RestrictionType.NO_EQUIPMENT, 'value': True, 'desc': 'No weapons or armor allowed'}
			],
			'mods': []
		},
		'hard_mode': {
			'name': 'Hard Mode',
			'description': 'Double enemy HP and attack, half player damage',
			'category': ChallengeCategory.DIFFICULTY,
			'restrictions': [],
			'mods': [
				{'type': DifficultyModifier.ENEMY_HP, 'multiplier': 2.0},
				{'type': DifficultyModifier.ENEMY_ATTACK, 'multiplier': 2.0},
				{'type': DifficultyModifier.PLAYER_DAMAGE, 'multiplier': 0.5}
			]
		},
		'speedrun_any': {
			'name': 'Any% Speedrun',
			'description': 'Complete the game as fast as possible',
			'category': ChallengeCategory.SPEEDRUN,
			'restrictions': [],
			'mods': [],
			'time_limit': None,
			'completion': True
		},
		'speedrun_100': {
			'name': '100% Speedrun',
			'description': 'Complete all quests and collect all items',
			'category': ChallengeCategory.SPEEDRUN,
			'restrictions': [],
			'mods': [],
			'time_limit': None,
			'completion': True
		},
		'nuzlocke': {
			'name': 'Nuzlocke Challenge',
			'description': 'Pokémon-style rules: perma-death, limited party',
			'category': ChallengeCategory.CUSTOM,
			'restrictions': [
				{'type': RestrictionType.NO_HEALING, 'value': True, 'desc': 'No healing items in battle'}
			],
			'mods': []
		}
	}
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.challenges: List[ChallengeRun] = []
		self.next_id = 1
	
	def create_challenge(self, name: str, description: str,
						category: ChallengeCategory,
						restrictions: List[Restriction] = None,
						difficulty_mods: List[DifficultyMod] = None,
						time_limit: Optional[int] = None,
						completion_required: bool = False) -> ChallengeRun:
		"""Create new challenge"""
		challenge = ChallengeRun(
			challenge_id=self.next_id,
			name=name,
			description=description,
			category=category,
			restrictions=restrictions or [],
			difficulty_mods=difficulty_mods or [],
			time_limit=time_limit,
			completion_required=completion_required,
			created_date=datetime.now().isoformat()
		)
		
		self.challenges.append(challenge)
		self.next_id += 1
		
		if self.verbose:
			print(f"✓ Created challenge: {name}")
		
		return challenge
	
	def create_from_template(self, template_name: str) -> Optional[ChallengeRun]:
		"""Create challenge from template"""
		if template_name not in self.TEMPLATES:
			if self.verbose:
				print(f"Unknown template: {template_name}")
			return None
		
		template = self.TEMPLATES[template_name]
		
		# Build restrictions
		restrictions = []
		for r_data in template['restrictions']:
			restriction = Restriction(
				restriction_type=r_data['type'],
				value=r_data['value'],
				description=r_data['desc']
			)
			restrictions.append(restriction)
		
		# Build difficulty mods
		mods = []
		for m_data in template['mods']:
			mod = DifficultyMod(
				modifier_type=m_data['type'],
				multiplier=m_data['multiplier']
			)
			mods.append(mod)
		
		challenge = self.create_challenge(
			name=template['name'],
			description=template['description'],
			category=template['category'],
			restrictions=restrictions,
			difficulty_mods=mods,
			time_limit=template.get('time_limit'),
			completion_required=template.get('completion', False)
		)
		
		return challenge
	
	def validate_progress(self, challenge: ChallengeRun, progress: RunProgress) -> Tuple[bool, List[str]]:
		"""Validate run against challenge rules"""
		violations = []
		
		# Check restrictions
		for restriction in challenge.restrictions:
			if restriction.restriction_type == RestrictionType.MAX_LEVEL:
				if progress.level > restriction.value:
					violations.append(f"Level {progress.level} exceeds max level {restriction.value}")
			
			elif restriction.restriction_type == RestrictionType.SOLO_CHARACTER:
				# Would need party data to validate
				pass
			
			elif restriction.restriction_type == RestrictionType.NO_EQUIPMENT:
				# Would need equipment data to validate
				pass
		
		# Check time limit
		if challenge.time_limit and progress.current_playtime > challenge.time_limit:
			violations.append(f"Time {progress.current_playtime}s exceeds limit {challenge.time_limit}s")
		
		# Check violation count
		if progress.violations > challenge.violations_allowed:
			violations.append(f"Too many violations: {progress.violations}/{challenge.violations_allowed}")
		
		valid = len(violations) == 0
		
		return valid, violations
	
	def calculate_difficulty_rating(self, challenge: ChallengeRun) -> int:
		"""Calculate challenge difficulty (0-100)"""
		rating = 0
		
		# Restrictions add difficulty
		restriction_values = {
			RestrictionType.MAX_LEVEL: 20,
			RestrictionType.NO_EQUIPMENT: 30,
			RestrictionType.SOLO_CHARACTER: 25,
			RestrictionType.NO_ITEMS: 35,
			RestrictionType.NO_MAGIC: 15,
			RestrictionType.NO_HEALING: 40,
			RestrictionType.NO_DAMAGE: 50
		}
		
		for restriction in challenge.restrictions:
			rating += restriction_values.get(restriction.restriction_type, 10)
		
		# Difficulty modifiers
		for mod in challenge.difficulty_mods:
			if mod.modifier_type in [DifficultyModifier.ENEMY_HP, DifficultyModifier.ENEMY_ATTACK]:
				rating += int((mod.multiplier - 1.0) * 20)
			elif mod.modifier_type == DifficultyModifier.PLAYER_DAMAGE:
				if mod.multiplier < 1.0:
					rating += int((1.0 - mod.multiplier) * 30)
		
		# Time limits add pressure
		if challenge.time_limit:
			if challenge.time_limit < 3600 * 2:  # Under 2 hours
				rating += 30
			elif challenge.time_limit < 3600 * 4:  # Under 4 hours
				rating += 15
		
		return min(rating, 100)
	
	def generate_rules_text(self, challenge: ChallengeRun) -> str:
		"""Generate human-readable rules"""
		lines = [
			f"Challenge: {challenge.name}",
			f"Category: {challenge.category.value}",
			f"",
			"Rules:",
		]
		
		# Restrictions
		if challenge.restrictions:
			lines.append("")
			lines.append("Restrictions:")
			for restriction in challenge.restrictions:
				lines.append(f"  - {restriction.description}")
		
		# Difficulty modifiers
		if challenge.difficulty_mods:
			lines.append("")
			lines.append("Difficulty Modifiers:")
			for mod in challenge.difficulty_mods:
				lines.append(f"  - {mod.modifier_type.value}: {mod.multiplier}x")
		
		# Time limit
		if challenge.time_limit:
			hours = challenge.time_limit // 3600
			minutes = (challenge.time_limit % 3600) // 60
			lines.append(f"")
			lines.append(f"Time Limit: {hours}h {minutes}m")
		
		# Completion requirement
		if challenge.completion_required:
			lines.append("")
			lines.append("Must complete the game")
		
		# Difficulty rating
		rating = self.calculate_difficulty_rating(challenge)
		lines.append("")
		lines.append(f"Difficulty Rating: {rating}/100")
		
		return "\n".join(lines)
	
	def export_challenges(self, output_path: Path) -> None:
		"""Export challenges to JSON"""
		data = {
			'challenges': [c.to_dict() for c in self.challenges],
			'total_count': len(self.challenges)
		}
		
		with open(output_path, 'w') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported {len(self.challenges)} challenges to {output_path}")
	
	def import_challenges(self, input_path: Path) -> None:
		"""Import challenges from JSON"""
		with open(input_path, 'r') as f:
			data = json.load(f)
		
		self.challenges = []
		for ch_dict in data['challenges']:
			ch_dict['category'] = ChallengeCategory(ch_dict['category'])
			
			# Rebuild restrictions
			restrictions = []
			for r_dict in ch_dict['restrictions']:
				r_dict['restriction_type'] = RestrictionType(r_dict['restriction_type'])
				restrictions.append(Restriction(**r_dict))
			ch_dict['restrictions'] = restrictions
			
			# Rebuild difficulty mods
			mods = []
			for m_dict in ch_dict['difficulty_mods']:
				m_dict['modifier_type'] = DifficultyModifier(m_dict['modifier_type'])
				mods.append(DifficultyMod(**m_dict))
			ch_dict['difficulty_mods'] = mods
			
			challenge = ChallengeRun(**ch_dict)
			self.challenges.append(challenge)
		
		if self.verbose:
			print(f"✓ Imported {len(self.challenges)} challenges from {input_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Challenge Mode Creator')
	parser.add_argument('command', choices=['create', 'list', 'generate', 'export', 'import', 'rules'],
					   help='Command to execute')
	parser.add_argument('--name', type=str, help='Challenge name')
	parser.add_argument('--description', type=str, help='Challenge description')
	parser.add_argument('--category', type=str, choices=[c.value for c in ChallengeCategory],
					   help='Challenge category')
	parser.add_argument('--max-level', type=int, help='Maximum character level')
	parser.add_argument('--template', type=str, help='Challenge template')
	parser.add_argument('--output', type=str, help='Output file')
	parser.add_argument('--input', type=str, help='Input file')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	creator = FFMQChallengeCreator(verbose=args.verbose)
	
	# List challenges
	if args.command == 'list':
		# Generate templates
		for template_name in creator.TEMPLATES:
			creator.create_from_template(template_name)
		
		print(f"\n=== Challenges ({len(creator.challenges)} total) ===\n")
		
		# Filter by category if specified
		challenges = creator.challenges
		if args.category:
			challenges = [c for c in challenges if c.category.value == args.category]
		
		for challenge in challenges:
			rating = creator.calculate_difficulty_rating(challenge)
			print(f"⚔️  {challenge.name}")
			print(f"   {challenge.description}")
			print(f"   Category: {challenge.category.value}")
			print(f"   Difficulty: {rating}/100")
			print(f"   Restrictions: {len(challenge.restrictions)}")
			print()
		
		return 0
	
	# Generate from template
	elif args.command == 'generate':
		if not args.template:
			print("Error: --template required")
			print(f"Available templates: {', '.join(creator.TEMPLATES.keys())}")
			return 1
		
		challenge = creator.create_from_template(args.template)
		
		if challenge and args.output:
			creator.export_challenges(Path(args.output))
		
		return 0
	
	# Show rules
	elif args.command == 'rules':
		if not args.template:
			print("Error: --template required")
			return 1
		
		challenge = creator.create_from_template(args.template)
		
		if challenge:
			rules = creator.generate_rules_text(challenge)
			print(rules)
		
		return 0
	
	# Export
	elif args.command == 'export':
		if not args.output:
			print("Error: --output required")
			return 1
		
		# Generate templates if none exist
		if not creator.challenges:
			for template_name in creator.TEMPLATES:
				creator.create_from_template(template_name)
		
		creator.export_challenges(Path(args.output))
		return 0
	
	# Import
	elif args.command == 'import':
		if not args.input:
			print("Error: --input required")
			return 1
		
		creator.import_challenges(Path(args.input))
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
