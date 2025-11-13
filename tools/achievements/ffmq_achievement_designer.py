#!/usr/bin/env python3
"""
FFMQ Achievement Designer - Create custom achievement/trophy system

Achievement Features:
- Story milestones
- Combat achievements
- Collection achievements
- Speedrun achievements
- Challenge achievements
- Hidden/secret achievements
- Progression tracking
- Unlock conditions

Achievement Types:
- Bronze/Silver/Gold/Platinum
- Points/score system
- Rarity percentages
- Dependencies/chains
- One-time vs repeatable
- Tracked statistics

Unlock Conditions:
- Defeat boss
- Collect all items
- Complete quest
- Reach level
- Time-based (speedrun)
- Damage taken
- Deaths count
- Sequence breaks

Tracking System:
- Game state monitoring
- Progress snapshots
- Save file integration
- Statistics tracking
- Unlock timestamps

Features:
- Design achievements
- Set unlock criteria
- Track progress
- Generate unlock hooks
- Export to JSON
- Import from templates

Usage:
	python ffmq_achievement_designer.py create --name "Dragon Slayer"
	python ffmq_achievement_designer.py list --rarity gold
	python ffmq_achievement_designer.py track --save-file save.srm
	python ffmq_achievement_designer.py generate --template speedrun
	python ffmq_achievement_designer.py export --output achievements.json
"""

import argparse
import json
from pathlib import Path
from typing import List, Dict, Tuple, Optional, Any
from dataclasses import dataclass, asdict, field
from enum import Enum
from datetime import datetime


class AchievementRarity(Enum):
	"""Achievement rarity levels"""
	BRONZE = "bronze"
	SILVER = "silver"
	GOLD = "gold"
	PLATINUM = "platinum"


class AchievementType(Enum):
	"""Achievement categories"""
	STORY = "story"
	COMBAT = "combat"
	COLLECTION = "collection"
	SPEEDRUN = "speedrun"
	CHALLENGE = "challenge"
	EXPLORATION = "exploration"
	SECRET = "secret"


class ConditionType(Enum):
	"""Unlock condition types"""
	DEFEAT_BOSS = "defeat_boss"
	COLLECT_ITEM = "collect_item"
	REACH_LEVEL = "reach_level"
	COMPLETE_QUEST = "complete_quest"
	TIME_LIMIT = "time_limit"
	DAMAGE_TAKEN = "damage_taken"
	DEATH_COUNT = "death_count"
	FLAG_SET = "flag_set"


@dataclass
class UnlockCondition:
	"""Single unlock condition"""
	condition_type: ConditionType
	target: str  # Boss name, item ID, level, etc.
	value: int  # Required value (level, count, time in seconds)
	comparison: str  # "=", ">", "<", ">=", "<="
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['condition_type'] = self.condition_type.value
		return d


@dataclass
class Achievement:
	"""Achievement definition"""
	achievement_id: int
	name: str
	description: str
	achievement_type: AchievementType
	rarity: AchievementRarity
	points: int
	hidden: bool
	conditions: List[UnlockCondition]
	dependencies: List[int] = field(default_factory=list)  # Other achievement IDs
	repeatable: bool = False
	statistics: List[str] = field(default_factory=list)  # Stats to track
	unlock_date: Optional[str] = None
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['achievement_type'] = self.achievement_type.value
		d['rarity'] = self.rarity.value
		d['conditions'] = [c.to_dict() for c in self.conditions]
		return d


@dataclass
class GameStatistics:
	"""Tracked game statistics"""
	playtime_seconds: int
	level: int
	bosses_defeated: List[str]
	items_collected: List[int]
	quests_completed: List[int]
	deaths: int
	damage_taken: int
	flags_set: List[int]


class FFMQAchievementDesigner:
	"""Achievement system designer"""
	
	# Known bosses
	BOSSES = [
		"Hydra", "Medusa", "Minotaur", "Flamerus Rex",
		"Ice Golem", "Stone Golem", "Twinhead Wyvern",
		"Pazuzu", "Dualhead Hydra", "Dark King"
	]
	
	# Story progression flags
	STORY_FLAGS = {
		1: "Hill of Destiny completed",
		2: "Foresta cleared",
		3: "Aquaria cleared",
		4: "Fireburg cleared",
		5: "Windia cleared",
		10: "Focus Tower reached",
		20: "Dark King defeated"
	}
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.achievements: List[Achievement] = []
		self.next_id = 1
	
	def create_achievement(self, name: str, description: str,
						  achievement_type: AchievementType,
						  rarity: AchievementRarity,
						  conditions: List[UnlockCondition],
						  points: int = 10,
						  hidden: bool = False,
						  dependencies: List[int] = None,
						  repeatable: bool = False) -> Achievement:
		"""Create new achievement"""
		achievement = Achievement(
			achievement_id=self.next_id,
			name=name,
			description=description,
			achievement_type=achievement_type,
			rarity=rarity,
			points=points,
			hidden=hidden,
			conditions=conditions,
			dependencies=dependencies or [],
			repeatable=repeatable
		)
		
		self.achievements.append(achievement)
		self.next_id += 1
		
		if self.verbose:
			print(f"✓ Created achievement: {name} ({rarity.value}, {points} points)")
		
		return achievement
	
	def generate_story_achievements(self) -> List[Achievement]:
		"""Generate story milestone achievements"""
		achievements = []
		
		# Area completions
		areas = [
			("Foresta Hero", "Complete all Foresta quests", 2, AchievementRarity.BRONZE, 10),
			("Aquaria Hero", "Complete all Aquaria quests", 3, AchievementRarity.BRONZE, 10),
			("Fireburg Hero", "Complete all Fireburg quests", 4, AchievementRarity.BRONZE, 10),
			("Windia Hero", "Complete all Windia quests", 5, AchievementRarity.BRONZE, 10),
		]
		
		for name, desc, flag, rarity, points in areas:
			condition = UnlockCondition(
				condition_type=ConditionType.FLAG_SET,
				target=str(flag),
				value=1,
				comparison="="
			)
			
			achievement = self.create_achievement(
				name=name,
				description=desc,
				achievement_type=AchievementType.STORY,
				rarity=rarity,
				conditions=[condition],
				points=points
			)
			achievements.append(achievement)
		
		# Final boss
		condition = UnlockCondition(
			condition_type=ConditionType.DEFEAT_BOSS,
			target="Dark King",
			value=1,
			comparison="="
		)
		
		achievement = self.create_achievement(
			name="Hero of Light",
			description="Defeat the Dark King and save the world",
			achievement_type=AchievementType.STORY,
			rarity=AchievementRarity.GOLD,
			conditions=[condition],
			points=50
		)
		achievements.append(achievement)
		
		return achievements
	
	def generate_combat_achievements(self) -> List[Achievement]:
		"""Generate combat achievements"""
		achievements = []
		
		# Boss rushes
		for boss in self.BOSSES[:5]:
			condition = UnlockCondition(
				condition_type=ConditionType.DEFEAT_BOSS,
				target=boss,
				value=1,
				comparison="="
			)
			
			achievement = self.create_achievement(
				name=f"{boss} Slayer",
				description=f"Defeat {boss}",
				achievement_type=AchievementType.COMBAT,
				rarity=AchievementRarity.BRONZE,
				conditions=[condition],
				points=5
			)
			achievements.append(achievement)
		
		# No deaths
		condition = UnlockCondition(
			condition_type=ConditionType.DEATH_COUNT,
			target="deaths",
			value=0,
			comparison="="
		)
		
		achievement = self.create_achievement(
			name="Deathless Run",
			description="Complete the game without dying",
			achievement_type=AchievementType.CHALLENGE,
			rarity=AchievementRarity.PLATINUM,
			conditions=[condition],
			points=100,
			hidden=True
		)
		achievements.append(achievement)
		
		return achievements
	
	def generate_speedrun_achievements(self) -> List[Achievement]:
		"""Generate speedrun achievements"""
		achievements = []
		
		# Time-based challenges
		time_challenges = [
			("Speed Demon", "Complete the game in under 4 hours", 4 * 3600, AchievementRarity.SILVER, 30),
			("Speedrunner", "Complete the game in under 3 hours", 3 * 3600, AchievementRarity.GOLD, 50),
			("World Record Pace", "Complete the game in under 2 hours", 2 * 3600, AchievementRarity.PLATINUM, 100),
		]
		
		for name, desc, time_seconds, rarity, points in time_challenges:
			condition = UnlockCondition(
				condition_type=ConditionType.TIME_LIMIT,
				target="playtime",
				value=time_seconds,
				comparison="<"
			)
			
			achievement = self.create_achievement(
				name=name,
				description=desc,
				achievement_type=AchievementType.SPEEDRUN,
				rarity=rarity,
				conditions=[condition],
				points=points
			)
			achievements.append(achievement)
		
		return achievements
	
	def generate_collection_achievements(self) -> List[Achievement]:
		"""Generate collection achievements"""
		achievements = []
		
		# Item milestones
		milestones = [
			("Treasure Hunter", "Collect 50 items", 50, AchievementRarity.BRONZE, 10),
			("Master Collector", "Collect 100 items", 100, AchievementRarity.SILVER, 25),
			("Completionist", "Collect all items", 256, AchievementRarity.GOLD, 50),
		]
		
		for name, desc, count, rarity, points in milestones:
			condition = UnlockCondition(
				condition_type=ConditionType.COLLECT_ITEM,
				target="total",
				value=count,
				comparison=">="
			)
			
			achievement = self.create_achievement(
				name=name,
				description=desc,
				achievement_type=AchievementType.COLLECTION,
				rarity=rarity,
				conditions=[condition],
				points=points
			)
			achievements.append(achievement)
		
		return achievements
	
	def check_achievement(self, achievement: Achievement, stats: GameStatistics) -> bool:
		"""Check if achievement is unlocked"""
		# Check dependencies first
		for dep_id in achievement.dependencies:
			dep_achievement = next((a for a in self.achievements if a.achievement_id == dep_id), None)
			if dep_achievement and not dep_achievement.unlock_date:
				return False
		
		# Check all conditions
		for condition in achievement.conditions:
			if not self._check_condition(condition, stats):
				return False
		
		return True
	
	def _check_condition(self, condition: UnlockCondition, stats: GameStatistics) -> bool:
		"""Check single condition"""
		if condition.condition_type == ConditionType.DEFEAT_BOSS:
			return condition.target in stats.bosses_defeated
		
		elif condition.condition_type == ConditionType.COLLECT_ITEM:
			if condition.target == "total":
				count = len(stats.items_collected)
			else:
				item_id = int(condition.target)
				count = 1 if item_id in stats.items_collected else 0
			
			return self._compare(count, condition.value, condition.comparison)
		
		elif condition.condition_type == ConditionType.REACH_LEVEL:
			return self._compare(stats.level, condition.value, condition.comparison)
		
		elif condition.condition_type == ConditionType.TIME_LIMIT:
			return self._compare(stats.playtime_seconds, condition.value, condition.comparison)
		
		elif condition.condition_type == ConditionType.DEATH_COUNT:
			return self._compare(stats.deaths, condition.value, condition.comparison)
		
		elif condition.condition_type == ConditionType.FLAG_SET:
			flag_id = int(condition.target)
			return flag_id in stats.flags_set
		
		return False
	
	def _compare(self, actual: int, expected: int, operator: str) -> bool:
		"""Compare values"""
		if operator == "=":
			return actual == expected
		elif operator == ">":
			return actual > expected
		elif operator == "<":
			return actual < expected
		elif operator == ">=":
			return actual >= expected
		elif operator == "<=":
			return actual <= expected
		return False
	
	def unlock_achievement(self, achievement: Achievement) -> None:
		"""Mark achievement as unlocked"""
		achievement.unlock_date = datetime.now().isoformat()
		
		if self.verbose:
			print(f"🏆 Achievement Unlocked: {achievement.name} (+{achievement.points} points)")
	
	def export_achievements(self, output_path: Path) -> None:
		"""Export achievements to JSON"""
		data = {
			'achievements': [a.to_dict() for a in self.achievements],
			'total_count': len(self.achievements),
			'total_points': sum(a.points for a in self.achievements)
		}
		
		with open(output_path, 'w') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported {len(self.achievements)} achievements to {output_path}")
	
	def import_achievements(self, input_path: Path) -> None:
		"""Import achievements from JSON"""
		with open(input_path, 'r') as f:
			data = json.load(f)
		
		self.achievements = []
		for ach_dict in data['achievements']:
			ach_dict['achievement_type'] = AchievementType(ach_dict['achievement_type'])
			ach_dict['rarity'] = AchievementRarity(ach_dict['rarity'])
			
			# Rebuild conditions
			conditions = []
			for cond_dict in ach_dict['conditions']:
				cond_dict['condition_type'] = ConditionType(cond_dict['condition_type'])
				conditions.append(UnlockCondition(**cond_dict))
			ach_dict['conditions'] = conditions
			
			achievement = Achievement(**ach_dict)
			self.achievements.append(achievement)
		
		if self.verbose:
			print(f"✓ Imported {len(self.achievements)} achievements from {input_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Achievement Designer')
	parser.add_argument('command', choices=['create', 'list', 'generate', 'export', 'import'],
					   help='Command to execute')
	parser.add_argument('--name', type=str, help='Achievement name')
	parser.add_argument('--description', type=str, help='Achievement description')
	parser.add_argument('--type', type=str, choices=[t.value for t in AchievementType],
					   help='Achievement type')
	parser.add_argument('--rarity', type=str, choices=[r.value for r in AchievementRarity],
					   help='Achievement rarity')
	parser.add_argument('--points', type=int, default=10, help='Achievement points')
	parser.add_argument('--hidden', action='store_true', help='Hidden achievement')
	parser.add_argument('--template', type=str, choices=['story', 'combat', 'speedrun', 'collection'],
					   help='Achievement template')
	parser.add_argument('--output', type=str, help='Output file')
	parser.add_argument('--input', type=str, help='Input file')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	designer = FFMQAchievementDesigner(verbose=args.verbose)
	
	# List achievements
	if args.command == 'list':
		# Generate default achievements
		designer.generate_story_achievements()
		designer.generate_combat_achievements()
		designer.generate_speedrun_achievements()
		designer.generate_collection_achievements()
		
		print(f"\n=== Achievements ({len(designer.achievements)} total) ===\n")
		
		# Filter by rarity if specified
		achievements = designer.achievements
		if args.rarity:
			achievements = [a for a in achievements if a.rarity.value == args.rarity]
		
		for achievement in achievements:
			icon = "🔒" if achievement.hidden else "🏆"
			print(f"{icon} {achievement.name} ({achievement.rarity.value.upper()})")
			print(f"   {achievement.description}")
			print(f"   Points: {achievement.points}")
			print(f"   Type: {achievement.achievement_type.value}")
			print()
		
		return 0
	
	# Generate template
	elif args.command == 'generate':
		if not args.template:
			print("Error: --template required")
			return 1
		
		if args.template == 'story':
			achievements = designer.generate_story_achievements()
		elif args.template == 'combat':
			achievements = designer.generate_combat_achievements()
		elif args.template == 'speedrun':
			achievements = designer.generate_speedrun_achievements()
		elif args.template == 'collection':
			achievements = designer.generate_collection_achievements()
		
		print(f"✓ Generated {len(achievements)} {args.template} achievements")
		
		if args.output:
			designer.export_achievements(Path(args.output))
		
		return 0
	
	# Export
	elif args.command == 'export':
		if not args.output:
			print("Error: --output required")
			return 1
		
		# Generate default achievements if none exist
		if not designer.achievements:
			designer.generate_story_achievements()
			designer.generate_combat_achievements()
			designer.generate_speedrun_achievements()
			designer.generate_collection_achievements()
		
		designer.export_achievements(Path(args.output))
		return 0
	
	# Import
	elif args.command == 'import':
		if not args.input:
			print("Error: --input required")
			return 1
		
		designer.import_achievements(Path(args.input))
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
