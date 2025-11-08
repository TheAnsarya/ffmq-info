"""
FFMQ Enemy Database Manager

Manages the complete enemy database including loading from ROM,
saving to ROM, searching, and bulk operations.
"""

from typing import Dict, List, Optional, Tuple
from pathlib import Path
import struct

from enemy_data import Enemy, EnemyFlags, ENEMY_NAMES


# ROM addresses for enemy data (these are example addresses - adjust for actual ROM)
ENEMY_DATA_BASE = 0x0D0000  # Base address for enemy stats
ENEMY_COUNT = 256           # Total number of enemies in FFMQ
ENEMY_SIZE = 256            # Size of each enemy data block


class EnemyDatabase:
	"""
	Manages the complete FFMQ enemy database
	
	Handles loading enemies from ROM, editing, and saving back to ROM.
	"""
	
	def __init__(self):
		"""Initialize empty enemy database"""
		self.enemies: Dict[int, Enemy] = {}
		self.rom_data: Optional[bytes] = None
		self.rom_path: Optional[Path] = None
	
	def load_from_rom(self, rom_path: str):
		"""
		Load all enemies from ROM
		
		Args:
			rom_path: Path to FFMQ ROM file
		"""
		rom_path_obj = Path(rom_path)
		if not rom_path_obj.exists():
			raise FileNotFoundError(f"ROM not found: {rom_path}")
		
		with open(rom_path_obj, 'rb') as f:
			self.rom_data = f.read()
		
		self.rom_path = rom_path_obj
		self.enemies.clear()
		
		# Load each enemy
		for enemy_id in range(ENEMY_COUNT):
			address = ENEMY_DATA_BASE + (enemy_id * ENEMY_SIZE)
			
			if address + ENEMY_SIZE > len(self.rom_data):
				break
			
			enemy_bytes = self.rom_data[address:address + ENEMY_SIZE]
			enemy = Enemy.from_bytes(enemy_id, enemy_bytes, address)
			
			# Set name from database if available
			if enemy_id in ENEMY_NAMES:
				enemy.name = ENEMY_NAMES[enemy_id]
			
			self.enemies[enemy_id] = enemy
		
		print(f"Loaded {len(self.enemies)} enemies from ROM")
	
	def save_to_rom(self, output_path: str):
		"""
		Save all enemies to ROM
		
		Args:
			output_path: Output ROM file path
		"""
		if not self.rom_data:
			raise RuntimeError("No ROM data loaded")
		
		# Create copy of ROM data
		new_rom = bytearray(self.rom_data)
		
		# Write each modified enemy
		modified_count = 0
		for enemy_id, enemy in self.enemies.items():
			if enemy.modified:
				address = ENEMY_DATA_BASE + (enemy_id * ENEMY_SIZE)
				enemy_bytes = enemy.to_bytes()
				new_rom[address:address + len(enemy_bytes)] = enemy_bytes
				modified_count += 1
		
		# Write to file
		with open(output_path, 'wb') as f:
			f.write(new_rom)
		
		print(f"Saved {modified_count} modified enemies to {output_path}")
	
	def get_enemy(self, enemy_id: int) -> Optional[Enemy]:
		"""
		Get enemy by ID
		
		Args:
			enemy_id: Enemy ID
		
		Returns:
			Enemy or None if not found
		"""
		return self.enemies.get(enemy_id)
	
	def search_enemies(self, query: str, case_sensitive: bool = False) -> List[Enemy]:
		"""
		Search enemies by name
		
		Args:
			query: Search query
			case_sensitive: Whether to use case-sensitive search
		
		Returns:
			List of matching enemies
		"""
		if not case_sensitive:
			query = query.lower()
		
		results = []
		for enemy in self.enemies.values():
			name = enemy.name if case_sensitive else enemy.name.lower()
			if query in name:
				results.append(enemy)
		
		return results
	
	def filter_by_level(self, min_level: int = 0, max_level: int = 99) -> List[Enemy]:
		"""
		Filter enemies by level range
		
		Args:
			min_level: Minimum level
			max_level: Maximum level
		
		Returns:
			List of enemies in level range
		"""
		return [
			enemy for enemy in self.enemies.values()
			if min_level <= enemy.level <= max_level
		]
	
	def filter_by_flags(self, flags: EnemyFlags) -> List[Enemy]:
		"""
		Filter enemies by flags
		
		Args:
			flags: Flags to filter by
		
		Returns:
			List of enemies with matching flags
		"""
		return [
			enemy for enemy in self.enemies.values()
			if enemy.flags & flags
		]
	
	def get_bosses(self) -> List[Enemy]:
		"""
		Get all boss enemies
		
		Returns:
			List of boss enemies
		"""
		return self.filter_by_flags(EnemyFlags.BOSS)
	
	def get_by_difficulty(self, ascending: bool = True) -> List[Enemy]:
		"""
		Get enemies sorted by difficulty
		
		Args:
			ascending: Sort ascending (easiest first) or descending
		
		Returns:
			List of enemies sorted by difficulty
		"""
		return sorted(
			self.enemies.values(),
			key=lambda e: e.calculate_difficulty(),
			reverse=not ascending
		)
	
	def get_statistics(self) -> Dict[str, any]:
		"""
		Get database statistics
		
		Returns:
			Dictionary of statistics
		"""
		if not self.enemies:
			return {}
		
		total = len(self.enemies)
		modified = sum(1 for e in self.enemies.values() if e.modified)
		bosses = len(self.get_bosses())
		
		# Calculate averages
		avg_hp = sum(e.stats.hp for e in self.enemies.values()) / total
		avg_level = sum(e.level for e in self.enemies.values()) / total
		avg_exp = sum(e.stats.exp for e in self.enemies.values()) / total
		avg_gold = sum(e.stats.gold for e in self.enemies.values()) / total
		
		# Find extremes
		strongest = max(self.enemies.values(), key=lambda e: e.calculate_difficulty())
		weakest = min(self.enemies.values(), key=lambda e: e.calculate_difficulty())
		most_hp = max(self.enemies.values(), key=lambda e: e.stats.hp)
		highest_level = max(self.enemies.values(), key=lambda e: e.level)
		
		return {
			'total': total,
			'modified': modified,
			'bosses': bosses,
			'avg_hp': avg_hp,
			'avg_level': avg_level,
			'avg_exp': avg_exp,
			'avg_gold': avg_gold,
			'strongest': strongest,
			'weakest': weakest,
			'most_hp': most_hp,
			'highest_level': highest_level
		}
	
	def clone_enemy(self, source_id: int, new_id: int) -> Optional[Enemy]:
		"""
		Clone an enemy to a new ID
		
		Args:
			source_id: Source enemy ID
			new_id: New enemy ID
		
		Returns:
			Cloned enemy or None if source not found
		"""
		source = self.enemies.get(source_id)
		if not source:
			return None
		
		# Create new enemy with copied data
		clone = Enemy(
			enemy_id=new_id,
			name=f"{source.name} (Clone)",
			stats=EnemyStats(**vars(source.stats)),
			resistances=ResistanceData(**vars(source.resistances)),
			flags=source.flags,
			level=source.level,
			ai_script=source.ai_script,  # AI scripts can be shared
			common_drop=ItemDrop(**vars(source.common_drop)),
			rare_drop=ItemDrop(**vars(source.rare_drop)),
			sprite=SpriteInfo(**vars(source.sprite)),
			modified=True
		)
		
		self.enemies[new_id] = clone
		return clone
	
	def batch_scale_stats(self, enemy_ids: List[int], scale_factor: float):
		"""
		Batch scale enemy stats
		
		Args:
			enemy_ids: List of enemy IDs to scale
			scale_factor: Scaling factor (1.0 = no change, 2.0 = double)
		"""
		for enemy_id in enemy_ids:
			enemy = self.enemies.get(enemy_id)
			if enemy:
				enemy.stats.hp = int(enemy.stats.hp * scale_factor)
				enemy.stats.attack = int(enemy.stats.attack * scale_factor)
				enemy.stats.defense = int(enemy.stats.defense * scale_factor)
				enemy.stats.magic = int(enemy.stats.magic * scale_factor)
				enemy.stats.magic_defense = int(enemy.stats.magic_defense * scale_factor)
				enemy.stats.exp = int(enemy.stats.exp * scale_factor)
				enemy.stats.gold = int(enemy.stats.gold * scale_factor)
				enemy.modified = True
	
	def export_to_csv(self, output_path: str):
		"""
		Export enemy database to CSV
		
		Args:
			output_path: Output CSV file path
		"""
		import csv
		
		with open(output_path, 'w', newline='', encoding='utf-8') as f:
			writer = csv.writer(f)
			
			# Header
			writer.writerow([
				'ID', 'Name', 'Level', 'HP', 'Attack', 'Defense', 'Magic',
				'Magic Defense', 'Speed', 'Evade', 'Critical', 'EXP', 'Gold',
				'Flags', 'Difficulty'
			])
			
			# Data
			for enemy_id, enemy in sorted(self.enemies.items()):
				writer.writerow([
					f'0x{enemy_id:03X}',
					enemy.name,
					enemy.level,
					enemy.stats.hp,
					enemy.stats.attack,
					enemy.stats.defense,
					enemy.stats.magic,
					enemy.stats.magic_defense,
					enemy.stats.speed,
					enemy.stats.evade,
					enemy.stats.critical,
					enemy.stats.exp,
					enemy.stats.gold,
					enemy.flags.name,
					f'{enemy.calculate_difficulty():.1f}'
				])
	
	def export_to_json(self, output_path: str, pretty: bool = True):
		"""
		Export enemy database to JSON
		
		Args:
			output_path: Output JSON file path
			pretty: Pretty-print JSON
		"""
		import json
		from dataclasses import asdict
		
		data = {}
		for enemy_id, enemy in self.enemies.items():
			# Convert to dictionary
			enemy_dict = {
				'id': enemy_id,
				'name': enemy.name,
				'level': enemy.level,
				'stats': asdict(enemy.stats),
				'resistances': asdict(enemy.resistances),
				'flags': enemy.flags.value,
				'common_drop': asdict(enemy.common_drop),
				'rare_drop': asdict(enemy.rare_drop),
				'sprite': asdict(enemy.sprite),
				'difficulty': enemy.calculate_difficulty(),
				'weaknesses': [e.name for e in enemy.get_weaknesses()],
				'resistances_list': [e.name for e in enemy.get_resistances()],
				'immunities': [e.name for e in enemy.get_immunities()],
			}
			data[f'0x{enemy_id:03X}'] = enemy_dict
		
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent=2 if pretty else None)


# Import these from enemy_data.py
from enemy_data import EnemyStats, ResistanceData, ItemDrop, SpriteInfo
