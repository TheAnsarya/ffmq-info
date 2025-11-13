#!/usr/bin/env python3
"""
FFMQ Achievement System - Trophies and unlockables

Achievement Features:
- Trophy tracking
- Progress monitoring
- Unlockable rewards
- Statistics tracking
- Leaderboards
- Challenges

Achievement Types:
- Story progression
- Combat achievements
- Collection achievements
- Speedrun achievements
- Challenge achievements
- Secret achievements

Reward Types:
- Unlockable items
- Bonus content
- Cosmetic options
- Game modifiers
- Achievement points

Features:
- Track achievements
- Award trophies
- Monitor progress
- Export statistics
- Leaderboard integration
- Challenge modes

Usage:
	python ffmq_achievement_system.py --list
	python ffmq_achievement_system.py --check "First Victory"
	python ffmq_achievement_system.py --unlock 1
	python ffmq_achievement_system.py --progress
	python ffmq_achievement_system.py --export achievements.json
"""

import argparse
import json
import time
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict, field
from enum import Enum
from datetime import datetime


class AchievementType(Enum):
	"""Achievement type"""
	STORY = "story"
	COMBAT = "combat"
	COLLECTION = "collection"
	SPEEDRUN = "speedrun"
	CHALLENGE = "challenge"
	SECRET = "secret"


class Rarity(Enum):
	"""Achievement rarity"""
	COMMON = "common"
	UNCOMMON = "uncommon"
	RARE = "rare"
	EPIC = "epic"
	LEGENDARY = "legendary"


@dataclass
class AchievementRequirement:
	"""Achievement requirement"""
	stat: str
	value: int
	comparison: str = ">="  # >=, >, ==, <, <=


@dataclass
class Achievement:
	"""Achievement/trophy"""
	achievement_id: int
	name: str
	description: str
	type: AchievementType
	rarity: Rarity
	points: int
	requirements: List[AchievementRequirement] = field(default_factory=list)
	unlocked: bool = False
	unlock_time: Optional[str] = None
	progress: float = 0.0  # 0.0 to 1.0
	hidden: bool = False
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['type'] = self.type.value
		d['rarity'] = self.rarity.value
		return d


@dataclass
class Statistic:
	"""Player statistic"""
	stat_id: str
	name: str
	value: int = 0
	description: str = ""


@dataclass
class Reward:
	"""Unlockable reward"""
	reward_id: int
	name: str
	description: str
	unlocked: bool = False


@dataclass
class Challenge:
	"""Special challenge"""
	challenge_id: int
	name: str
	description: str
	requirements: List[AchievementRequirement] = field(default_factory=list)
	active: bool = False
	completed: bool = False
	time_limit: Optional[int] = None  # Seconds
	reward_id: Optional[int] = None


class FFMQAchievementSystem:
	"""Achievement and trophy system"""
	
	# Default achievements
	DEFAULT_ACHIEVEMENTS = [
		{
			'achievement_id': 1,
			'name': 'First Steps',
			'description': 'Complete the Hill of Destiny',
			'type': AchievementType.STORY,
			'rarity': Rarity.COMMON,
			'points': 10,
			'requirements': [
				AchievementRequirement('story_progress', 1, '>=')
			]
		},
		{
			'achievement_id': 2,
			'name': 'First Victory',
			'description': 'Win your first battle',
			'type': AchievementType.COMBAT,
			'rarity': Rarity.COMMON,
			'points': 5,
			'requirements': [
				AchievementRequirement('battles_won', 1, '>=')
			]
		},
		{
			'achievement_id': 3,
			'name': 'Battle Master',
			'description': 'Win 100 battles',
			'type': AchievementType.COMBAT,
			'rarity': Rarity.UNCOMMON,
			'points': 25,
			'requirements': [
				AchievementRequirement('battles_won', 100, '>=')
			]
		},
		{
			'achievement_id': 4,
			'name': 'Treasure Hunter',
			'description': 'Open 50 chests',
			'type': AchievementType.COLLECTION,
			'rarity': Rarity.UNCOMMON,
			'points': 20,
			'requirements': [
				AchievementRequirement('chests_opened', 50, '>=')
			]
		},
		{
			'achievement_id': 5,
			'name': 'Speedrunner',
			'description': 'Complete the game in under 5 hours',
			'type': AchievementType.SPEEDRUN,
			'rarity': Rarity.EPIC,
			'points': 100,
			'requirements': [
				AchievementRequirement('playtime', 18000, '<='),  # 5 hours in seconds
				AchievementRequirement('game_completed', 1, '==')
			]
		},
		{
			'achievement_id': 6,
			'name': 'No Damage Run',
			'description': 'Defeat a boss without taking damage',
			'type': AchievementType.CHALLENGE,
			'rarity': Rarity.RARE,
			'points': 50,
			'requirements': [
				AchievementRequirement('boss_no_damage', 1, '>=')
			]
		},
		{
			'achievement_id': 7,
			'name': 'All Items',
			'description': 'Collect all items in the game',
			'type': AchievementType.COLLECTION,
			'rarity': Rarity.EPIC,
			'points': 75,
			'requirements': [
				AchievementRequirement('items_collected', 100, '==')
			]
		},
		{
			'achievement_id': 8,
			'name': 'Perfect Game',
			'description': 'Complete the game with 100% completion',
			'type': AchievementType.CHALLENGE,
			'rarity': Rarity.LEGENDARY,
			'points': 200,
			'requirements': [
				AchievementRequirement('completion_percent', 100, '==')
			]
		},
		{
			'achievement_id': 9,
			'name': 'Secret Hunter',
			'description': 'Discover all secret areas',
			'type': AchievementType.SECRET,
			'rarity': Rarity.RARE,
			'points': 50,
			'requirements': [
				AchievementRequirement('secrets_found', 10, '>=')
			],
			'hidden': True
		},
		{
			'achievement_id': 10,
			'name': 'Level Master',
			'description': 'Reach maximum level',
			'type': AchievementType.COMBAT,
			'rarity': Rarity.RARE,
			'points': 50,
			'requirements': [
				AchievementRequirement('player_level', 99, '>=')
			]
		},
	]
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.achievements: Dict[int, Achievement] = {}
		self.statistics: Dict[str, Statistic] = {}
		self.rewards: Dict[int, Reward] = {}
		self.challenges: Dict[int, Challenge] = {}
		
		self._load_default_achievements()
		self._initialize_statistics()
	
	def _load_default_achievements(self) -> None:
		"""Load default achievements"""
		for ach_data in self.DEFAULT_ACHIEVEMENTS:
			# Handle nested dataclass
			requirements = []
			for req in ach_data.get('requirements', []):
				if isinstance(req, dict):
					requirements.append(AchievementRequirement(**req))
				else:
					requirements.append(req)
			
			ach_data['requirements'] = requirements
			
			achievement = Achievement(**ach_data)
			self.achievements[achievement.achievement_id] = achievement
	
	def _initialize_statistics(self) -> None:
		"""Initialize player statistics"""
		stats = [
			('story_progress', 'Story Progress', 'Current story chapter'),
			('battles_won', 'Battles Won', 'Total battles won'),
			('battles_lost', 'Battles Lost', 'Total battles lost'),
			('chests_opened', 'Chests Opened', 'Total chests opened'),
			('playtime', 'Play Time', 'Total play time in seconds'),
			('boss_no_damage', 'No Damage Boss Kills', 'Bosses defeated without taking damage'),
			('items_collected', 'Items Collected', 'Unique items collected'),
			('game_completed', 'Game Completed', 'Times completed'),
			('completion_percent', 'Completion %', 'Overall completion percentage'),
			('secrets_found', 'Secrets Found', 'Secret areas discovered'),
			('player_level', 'Player Level', 'Maximum character level'),
			('damage_dealt', 'Damage Dealt', 'Total damage dealt'),
			('damage_taken', 'Damage Taken', 'Total damage taken'),
			('steps_taken', 'Steps Taken', 'Total steps walked'),
			('gil_earned', 'Gil Earned', 'Total Gil earned'),
		]
		
		for stat_id, name, description in stats:
			stat = Statistic(
				stat_id=stat_id,
				name=name,
				description=description
			)
			self.statistics[stat_id] = stat
	
	def update_statistic(self, stat_id: str, value: int) -> None:
		"""Update statistic value"""
		if stat_id not in self.statistics:
			return
		
		self.statistics[stat_id].value = value
		
		if self.verbose:
			print(f"📊 {self.statistics[stat_id].name}: {value}")
		
		# Check for achievement unlocks
		self._check_achievements()
	
	def increment_statistic(self, stat_id: str, amount: int = 1) -> None:
		"""Increment statistic"""
		if stat_id in self.statistics:
			self.statistics[stat_id].value += amount
			self._check_achievements()
	
	def _check_achievements(self) -> List[Achievement]:
		"""Check and unlock achievements"""
		unlocked = []
		
		for achievement in self.achievements.values():
			if achievement.unlocked:
				continue
			
			# Check all requirements
			all_met = True
			total_progress = 0.0
			
			for req in achievement.requirements:
				if req.stat not in self.statistics:
					all_met = False
					break
				
				stat_value = self.statistics[req.stat].value
				
				# Check requirement
				if req.comparison == '>=':
					met = stat_value >= req.value
					progress = min(1.0, stat_value / req.value) if req.value > 0 else 0.0
				elif req.comparison == '>':
					met = stat_value > req.value
					progress = min(1.0, stat_value / req.value) if req.value > 0 else 0.0
				elif req.comparison == '==':
					met = stat_value == req.value
					progress = 1.0 if met else 0.0
				elif req.comparison == '<':
					met = stat_value < req.value
					progress = 1.0 if met else 0.0
				elif req.comparison == '<=':
					met = stat_value <= req.value
					progress = 1.0 if met else 0.0
				else:
					met = False
					progress = 0.0
				
				total_progress += progress
				
				if not met:
					all_met = False
			
			# Update progress
			achievement.progress = total_progress / len(achievement.requirements) if achievement.requirements else 0.0
			
			# Unlock if all met
			if all_met:
				achievement.unlocked = True
				achievement.unlock_time = datetime.now().isoformat()
				unlocked.append(achievement)
				
				if self.verbose:
					print(f"🏆 Achievement Unlocked: {achievement.name} (+{achievement.points} points)")
		
		return unlocked
	
	def unlock_achievement(self, achievement_id: int) -> bool:
		"""Manually unlock achievement"""
		if achievement_id not in self.achievements:
			return False
		
		achievement = self.achievements[achievement_id]
		
		if achievement.unlocked:
			return False
		
		achievement.unlocked = True
		achievement.unlock_time = datetime.now().isoformat()
		achievement.progress = 1.0
		
		if self.verbose:
			print(f"🏆 Achievement Unlocked: {achievement.name} (+{achievement.points} points)")
		
		return True
	
	def get_total_points(self) -> int:
		"""Get total achievement points"""
		return sum(ach.points for ach in self.achievements.values() if ach.unlocked)
	
	def get_completion_percent(self) -> float:
		"""Get completion percentage"""
		if not self.achievements:
			return 0.0
		
		unlocked = sum(1 for ach in self.achievements.values() if ach.unlocked)
		return (unlocked / len(self.achievements)) * 100.0
	
	def export_json(self, output_path: Path) -> bool:
		"""Export achievements to JSON"""
		try:
			data = {
				'achievements': [ach.to_dict() for ach in self.achievements.values()],
				'statistics': {k: asdict(v) for k, v in self.statistics.items()},
				'total_points': self.get_total_points(),
				'completion': self.get_completion_percent()
			}
			
			with open(output_path, 'w', encoding='utf-8') as f:
				json.dump(data, f, indent='\t')
			
			if self.verbose:
				print(f"✓ Exported achievements to {output_path}")
			
			return True
		
		except Exception as e:
			print(f"Error exporting achievements: {e}")
			return False
	
	def import_json(self, input_path: Path) -> bool:
		"""Import achievements from JSON"""
		try:
			with open(input_path, 'r', encoding='utf-8') as f:
				data = json.load(f)
			
			# Import achievements
			self.achievements = {}
			for ach_data in data['achievements']:
				ach_data['type'] = AchievementType(ach_data['type'])
				ach_data['rarity'] = Rarity(ach_data['rarity'])
				
				# Convert requirements
				requirements = []
				for req_data in ach_data.get('requirements', []):
					requirements.append(AchievementRequirement(**req_data))
				ach_data['requirements'] = requirements
				
				achievement = Achievement(**ach_data)
				self.achievements[achievement.achievement_id] = achievement
			
			# Import statistics
			for stat_id, stat_data in data.get('statistics', {}).items():
				self.statistics[stat_id] = Statistic(**stat_data)
			
			if self.verbose:
				print(f"✓ Imported achievements from {input_path}")
			
			return True
		
		except Exception as e:
			print(f"Error importing achievements: {e}")
			return False
	
	def print_achievement_list(self, show_hidden: bool = False) -> None:
		"""Print achievement list"""
		print(f"\n=== Achievements ===\n")
		print(f"{'ID':<4} {'Name':<30} {'Type':<12} {'Rarity':<12} {'Points':<8} {'Status':<10}")
		print('-' * 76)
		
		for ach_id, ach in sorted(self.achievements.items()):
			if ach.hidden and not show_hidden and not ach.unlocked:
				continue
			
			status = "✓" if ach.unlocked else f"{ach.progress*100:.0f}%"
			name = ach.name if not (ach.hidden and not ach.unlocked) else "???"
			
			print(f"{ach.achievement_id:<4} {name:<30} {ach.type.value:<12} "
				  f"{ach.rarity.value:<12} {ach.points:<8} {status:<10}")
		
		print(f"\nTotal Points: {self.get_total_points()}")
		print(f"Completion: {self.get_completion_percent():.1f}%")
	
	def print_statistics(self) -> None:
		"""Print statistics"""
		print(f"\n=== Statistics ===\n")
		print(f"{'Stat':<30} {'Value':<15}")
		print('-' * 45)
		
		for stat_id, stat in sorted(self.statistics.items()):
			print(f"{stat.name:<30} {stat.value:<15,}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Achievement System')
	parser.add_argument('--list', action='store_true', help='List achievements')
	parser.add_argument('--show-hidden', action='store_true',
					   help='Show hidden achievements')
	parser.add_argument('--check', type=str, metavar='NAME',
					   help='Check achievement by name')
	parser.add_argument('--unlock', type=int, metavar='ID',
					   help='Unlock achievement by ID')
	parser.add_argument('--progress', action='store_true', help='Show progress')
	parser.add_argument('--statistics', action='store_true', help='Show statistics')
	parser.add_argument('--update-stat', type=str, nargs=2,
					   metavar=('STAT', 'VALUE'), help='Update statistic')
	parser.add_argument('--export', type=str, metavar='OUTPUT',
					   help='Export to JSON')
	parser.add_argument('--import', type=str, dest='import_file',
					   metavar='INPUT', help='Import from JSON')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	system = FFMQAchievementSystem(verbose=args.verbose)
	
	# Import
	if args.import_file:
		system.import_json(Path(args.import_file))
	
	# Update statistic
	if args.update_stat:
		stat_id, value = args.update_stat
		system.update_statistic(stat_id, int(value))
	
	# Unlock achievement
	if args.unlock:
		system.unlock_achievement(args.unlock)
	
	# Export
	if args.export:
		system.export_json(Path(args.export))
		return 0
	
	# Statistics
	if args.statistics:
		system.print_statistics()
		return 0
	
	# List achievements
	if args.list or not any([args.check, args.progress, args.unlock, args.update_stat]):
		system.print_achievement_list(show_hidden=args.show_hidden)
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
