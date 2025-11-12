"""
FFMQ Dungeon Map System

Specialized dungeon map handling with enemy encounters, formations,
and encounter rates. Extends the base map system with battle-specific features.
"""

from dataclasses import dataclass, field
from typing import List, Dict, Optional, Tuple, Set
from enum import IntEnum
import struct
import random


class EncounterZone(IntEnum):
	"""Encounter zone types"""
	NONE = 0
	NORMAL = 1
	HIGH_RATE = 2
	BOSS_AREA = 3
	SAFE_ZONE = 4


class TerrainType(IntEnum):
	"""Terrain types affecting encounters"""
	NORMAL = 0
	FOREST = 1
	DESERT = 2
	MOUNTAIN = 3
	CAVE = 4
	WATER = 5
	LAVA = 6
	ICE = 7


@dataclass
class EnemyFormation:
	"""Enemy battle formation"""
	formation_id: int = 0
	enemy_ids: List[int] = field(default_factory=list)  # Up to 6 enemies
	positions: List[Tuple[int, int]] = field(default_factory=list)  # Enemy positions
	is_boss: bool = False
	surprise_rate: int = 0		# Chance of surprise attack (0-100)
	preemptive_rate: int = 0	  # Chance of preemptive strike (0-100)
	can_escape: bool = True
	
	# Rewards
	bonus_exp: int = 0
	bonus_gold: int = 0
	
	# Visual
	background_id: int = 0		# Battle background
	music_id: int = 0			 # Battle music
	
	def to_bytes(self) -> bytes:
		"""Serialize formation to ROM format"""
		data = bytearray()
		
		# Formation ID and enemy count
		data.append(self.formation_id)
		data.append(len(self.enemy_ids))
		
		# Enemy IDs (6 bytes, 0xFF for empty)
		for i in range(6):
			if i < len(self.enemy_ids):
				data.append(self.enemy_ids[i])
			else:
				data.append(0xFF)
		
		# Positions (12 bytes, 2 per enemy)
		for i in range(6):
			if i < len(self.positions):
				data.extend(struct.pack('<BB', self.positions[i][0], self.positions[i][1]))
			else:
				data.extend(b'\xFF\xFF')
		
		# Flags and rates
		flags = (
			(0x01 if self.is_boss else 0) |
			(0x02 if self.can_escape else 0)
		)
		data.extend(struct.pack('<BBBB',
			flags,
			self.surprise_rate,
			self.preemptive_rate,
			0  # Padding
		))
		
		# Bonuses
		data.extend(struct.pack('<HH', self.bonus_exp, self.bonus_gold))
		
		# Visual
		data.extend(struct.pack('<BB', self.background_id, self.music_id))
		
		return bytes(data)
	
	@classmethod
	def from_bytes(cls, data: bytes) -> 'EnemyFormation':
		"""Load formation from ROM bytes"""
		offset = 0
		
		formation_id = data[offset]
		offset += 1
		
		enemy_count = data[offset]
		offset += 1
		
		# Load enemy IDs
		enemy_ids = []
		for i in range(6):
			enemy_id = data[offset]
			offset += 1
			if enemy_id != 0xFF:
				enemy_ids.append(enemy_id)
		
		# Load positions
		positions = []
		for i in range(6):
			x, y = struct.unpack('<BB', data[offset:offset+2])
			offset += 2
			if x != 0xFF:
				positions.append((x, y))
		
		# Flags and rates
		flags, surprise, preemptive, _ = struct.unpack('<BBBB', data[offset:offset+4])
		offset += 4
		
		# Bonuses
		bonus_exp, bonus_gold = struct.unpack('<HH', data[offset:offset+4])
		offset += 4
		
		# Visual
		bg_id, music_id = struct.unpack('<BB', data[offset:offset+2])
		
		return cls(
			formation_id=formation_id,
			enemy_ids=enemy_ids,
			positions=positions,
			is_boss=bool(flags & 0x01),
			can_escape=bool(flags & 0x02),
			surprise_rate=surprise,
			preemptive_rate=preemptive,
			bonus_exp=bonus_exp,
			bonus_gold=bonus_gold,
			background_id=bg_id,
			music_id=music_id
		)
	
	def get_average_level(self, enemy_db) -> float:
		"""Calculate average enemy level in formation"""
		if not self.enemy_ids or not enemy_db:
			return 1.0
		
		total = 0
		count = 0
		for enemy_id in self.enemy_ids:
			enemy = enemy_db.get_enemy(enemy_id)
			if enemy:
				total += enemy.level
				count += 1
		
		return total / count if count > 0 else 1.0


@dataclass
class EncounterTable:
	"""Encounter table for a dungeon area"""
	table_id: int = 0
	formations: List[int] = field(default_factory=list)  # Formation IDs
	weights: List[int] = field(default_factory=list)	 # Encounter weights
	base_rate: int = 16		  # Base encounter rate (steps between battles)
	rate_variance: int = 8	   # Variance in encounter rate
	
	def to_bytes(self) -> bytes:
		"""Serialize encounter table"""
		data = bytearray()
		
		data.append(self.table_id)
		data.append(len(self.formations))
		data.append(self.base_rate)
		data.append(self.rate_variance)
		
		# Formations and weights (8 max)
		for i in range(8):
			if i < len(self.formations):
				data.append(self.formations[i])
				data.append(self.weights[i])
			else:
				data.extend(b'\xFF\x00')
		
		return bytes(data)
	
	@classmethod
	def from_bytes(cls, data: bytes) -> 'EncounterTable':
		"""Load encounter table from bytes"""
		offset = 0
		
		table_id = data[offset]
		offset += 1
		
		formation_count = data[offset]
		offset += 1
		
		base_rate = data[offset]
		offset += 1
		
		rate_variance = data[offset]
		offset += 1
		
		formations = []
		weights = []
		
		for i in range(8):
			form_id = data[offset]
			offset += 1
			weight = data[offset]
			offset += 1
			
			if form_id != 0xFF:
				formations.append(form_id)
				weights.append(weight)
		
		return cls(
			table_id=table_id,
			formations=formations,
			weights=weights,
			base_rate=base_rate,
			rate_variance=rate_variance
		)
	
	def get_random_formation(self) -> int:
		"""
		Get random formation based on weights
		
		Returns:
			int: Formation ID
		"""
		if not self.formations:
			return 0
		
		total_weight = sum(self.weights)
		if total_weight == 0:
			return self.formations[0]
		
		roll = random.randint(0, total_weight - 1)
		current = 0
		
		for formation_id, weight in zip(self.formations, self.weights):
			current += weight
			if roll < current:
				return formation_id
		
		return self.formations[-1]
	
	def calculate_encounter_steps(self) -> int:
		"""
		Calculate steps until next encounter
		
		Returns:
			int: Number of steps
		"""
		variance = random.randint(-self.rate_variance, self.rate_variance)
		return max(1, self.base_rate + variance)


@dataclass
class DungeonZone:
	"""Dungeon zone with encounter data"""
	zone_id: int = 0
	zone_type: EncounterZone = EncounterZone.NORMAL
	terrain: TerrainType = TerrainType.NORMAL
	encounter_table_id: int = 0
	
	# Zone boundaries (map coordinates)
	min_x: int = 0
	min_y: int = 0
	max_x: int = 0
	max_y: int = 0
	
	# Modifiers
	encounter_rate_modifier: float = 1.0  # Multiplier for encounter rate
	escape_rate_modifier: float = 1.0	# Multiplier for escape chance
	
	def contains_point(self, x: int, y: int) -> bool:
		"""Check if point is in zone"""
		return self.min_x <= x <= self.max_x and self.min_y <= y <= self.max_y
	
	def to_bytes(self) -> bytes:
		"""Serialize zone to ROM format"""
		return struct.pack('<BBBBBBBBHH',
			self.zone_id,
			self.zone_type,
			self.terrain,
			self.encounter_table_id,
			self.min_x,
			self.min_y,
			self.max_x,
			self.max_y,
			int(self.encounter_rate_modifier * 100),
			int(self.escape_rate_modifier * 100)
		)
	
	@classmethod
	def from_bytes(cls, data: bytes) -> 'DungeonZone':
		"""Load zone from ROM bytes"""
		values = struct.unpack('<BBBBBBBBHH', data[:14])
		
		return cls(
			zone_id=values[0],
			zone_type=EncounterZone(values[1]),
			terrain=TerrainType(values[2]),
			encounter_table_id=values[3],
			min_x=values[4],
			min_y=values[5],
			max_x=values[6],
			max_y=values[7],
			encounter_rate_modifier=values[8] / 100.0,
			escape_rate_modifier=values[9] / 100.0
		)


@dataclass
class DungeonMap:
	"""Complete dungeon map with encounters"""
	map_id: int = 0
	name: str = "Dungeon"
	
	# Map data (inherited from base Map class)
	width: int = 32
	height: int = 32
	tileset_id: int = 0
	
	# Encounter data
	zones: List[DungeonZone] = field(default_factory=list)
	encounter_tables: Dict[int, EncounterTable] = field(default_factory=dict)
	formations: Dict[int, EnemyFormation] = field(default_factory=dict)
	
	# Special encounters
	boss_formation_id: Optional[int] = None
	boss_x: int = 0
	boss_y: int = 0
	
	# Flags
	random_encounters_enabled: bool = True
	can_save: bool = True
	can_escape_dungeon: bool = True
	
	def get_zone_at(self, x: int, y: int) -> Optional[DungeonZone]:
		"""Get dungeon zone at coordinates"""
		for zone in self.zones:
			if zone.contains_point(x, y):
				return zone
		return None
	
	def get_encounter_table(self, x: int, y: int) -> Optional[EncounterTable]:
		"""Get encounter table for position"""
		zone = self.get_zone_at(x, y)
		if zone:
			return self.encounter_tables.get(zone.encounter_table_id)
		return None
	
	def trigger_encounter(self, x: int, y: int) -> Optional[EnemyFormation]:
		"""
		Trigger random encounter at position
		
		Args:
			x: X coordinate
			y: Y coordinate
		
		Returns:
			EnemyFormation or None
		"""
		if not self.random_encounters_enabled:
			return None
		
		# Check for boss encounter
		if self.boss_formation_id and x == self.boss_x and y == self.boss_y:
			return self.formations.get(self.boss_formation_id)
		
		# Get encounter table for this zone
		table = self.get_encounter_table(x, y)
		if not table:
			return None
		
		# Get random formation
		formation_id = table.get_random_formation()
		return self.formations.get(formation_id)
	
	def add_zone(self, zone: DungeonZone):
		"""Add encounter zone"""
		self.zones.append(zone)
	
	def add_encounter_table(self, table: EncounterTable):
		"""Add encounter table"""
		self.encounter_tables[table.table_id] = table
	
	def add_formation(self, formation: EnemyFormation):
		"""Add enemy formation"""
		self.formations[formation.formation_id] = formation
	
	def get_statistics(self) -> Dict[str, any]:
		"""Get dungeon statistics"""
		return {
			'name': self.name,
			'zones': len(self.zones),
			'encounter_tables': len(self.encounter_tables),
			'formations': len(self.formations),
			'total_unique_enemies': len(set(
				enemy_id 
				for formation in self.formations.values()
				for enemy_id in formation.enemy_ids
			)),
			'has_boss': self.boss_formation_id is not None,
			'random_encounters': self.random_encounters_enabled
		}


class DungeonMapDatabase:
	"""Database of all dungeon maps"""
	
	def __init__(self):
		self.dungeons: Dict[int, DungeonMap] = {}
	
	def load_from_rom(self, rom_path: str):
		"""Load all dungeon maps from ROM"""
		# Implementation would load from ROM
		# For now, create sample data
		pass
	
	def save_to_rom(self, output_path: str):
		"""Save all dungeon maps to ROM"""
		# Implementation would save to ROM
		pass
	
	def get_dungeon(self, map_id: int) -> Optional[DungeonMap]:
		"""Get dungeon by ID"""
		return self.dungeons.get(map_id)
	
	def add_dungeon(self, dungeon: DungeonMap):
		"""Add dungeon to database"""
		self.dungeons[dungeon.map_id] = dungeon
	
	def export_encounter_data(self, output_path: str):
		"""Export encounter data to JSON"""
		import json
		
		data = {}
		for map_id, dungeon in self.dungeons.items():
			data[f'0x{map_id:02X}'] = {
				'name': dungeon.name,
				'zones': [
					{
						'id': z.zone_id,
						'type': z.zone_type.name,
						'terrain': z.terrain.name,
						'bounds': [z.min_x, z.min_y, z.max_x, z.max_y]
					}
					for z in dungeon.zones
				],
				'formations': [
					{
						'id': f.formation_id,
						'enemies': f.enemy_ids,
						'is_boss': f.is_boss
					}
					for f in dungeon.formations.values()
				]
			}
		
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent=2)


# Sample dungeon creation
def create_sample_dungeon() -> DungeonMap:
	"""Create a sample dungeon for testing"""
	dungeon = DungeonMap(map_id=1, name="Sample Cave")
	
	# Create encounter zones
	zone1 = DungeonZone(
		zone_id=0,
		zone_type=EncounterZone.NORMAL,
		terrain=TerrainType.CAVE,
		encounter_table_id=0,
		min_x=0, min_y=0, max_x=15, max_y=15
	)
	dungeon.add_zone(zone1)
	
	zone2 = DungeonZone(
		zone_id=1,
		zone_type=EncounterZone.HIGH_RATE,
		terrain=TerrainType.CAVE,
		encounter_table_id=1,
		min_x=16, min_y=0, max_x=31, max_y=15,
		encounter_rate_modifier=2.0
	)
	dungeon.add_zone(zone2)
	
	# Create formations
	formation1 = EnemyFormation(
		formation_id=0,
		enemy_ids=[0x00, 0x00, 0x01],  # 2 Goblins, 1 Basilisk
		positions=[(32, 64), (96, 64), (64, 80)],
		background_id=0,
		music_id=0
	)
	dungeon.add_formation(formation1)
	
	formation2 = EnemyFormation(
		formation_id=1,
		enemy_ids=[0x02, 0x02],  # 2 Minotaurs
		positions=[(48, 64), (80, 64)],
		background_id=0,
		music_id=0
	)
	dungeon.add_formation(formation2)
	
	# Create encounter tables
	table1 = EncounterTable(
		table_id=0,
		formations=[0, 1],
		weights=[70, 30],
		base_rate=16,
		rate_variance=8
	)
	dungeon.add_encounter_table(table1)
	
	table2 = EncounterTable(
		table_id=1,
		formations=[1],
		weights=[100],
		base_rate=8,
		rate_variance=4
	)
	dungeon.add_encounter_table(table2)
	
	return dungeon
