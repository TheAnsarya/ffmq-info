"""
FFMQ Enemy/Monster Data Structures

Comprehensive data classes for enemy stats, AI, drops, and battle data.
Supports full enemy editing including stats, resistances, AI patterns,
item drops, and sprite information.
"""

from dataclasses import dataclass, field
from typing import List, Dict, Optional, Tuple
from enum import IntEnum, IntFlag
import struct


class ElementType(IntEnum):
	"""Elemental damage types"""
	NONE = 0
	FIRE = 1
	WATER = 2
	EARTH = 3
	WIND = 4
	HOLY = 5
	DARK = 6
	POISON = 7


class EnemyFlags(IntFlag):
	"""Enemy behavior flags"""
	NONE = 0
	BOSS = 0x01
	UNDEAD = 0x02
	FLYING = 0x04
	COUNTER_ATTACKS = 0x08
	IMMUNE_TO_SLEEP = 0x10
	IMMUNE_TO_PARALYZE = 0x20
	IMMUNE_TO_CONFUSE = 0x40
	IMMUNE_TO_BLIND = 0x80
	IMMUNE_TO_POISON = 0x100
	REGENERATES = 0x200
	ABSORBS_PHYSICAL = 0x400
	ABSORBS_MAGIC = 0x800


class AIBehavior(IntEnum):
	"""Enemy AI behavior patterns"""
	NORMAL = 0		  # Standard attack pattern
	AGGRESSIVE = 1	  # Attacks more frequently
	DEFENSIVE = 2	   # Uses defensive spells
	SUPPORT = 3		 # Buffs allies
	HEALER = 4		  # Heals allies
	RANDOM = 5		  # Random actions
	SCRIPTED = 6		# Follows script
	CONDITIONAL = 7	 # HP-based behavior changes


class DropType(IntEnum):
	"""Item drop types"""
	NONE = 0
	CONSUMABLE = 1
	EQUIPMENT = 2
	KEY_ITEM = 3
	GOLD = 4


@dataclass
class ResistanceData:
	"""Enemy elemental resistances"""
	fire: int = 100		# Percentage (0-255, 100=normal, 0=immune, 200=2x damage)
	water: int = 100
	earth: int = 100
	wind: int = 100
	holy: int = 100
	dark: int = 100
	poison: int = 100
	physical: int = 100	# Physical damage resistance
	magical: int = 100	 # Magic damage resistance
	
	def to_bytes(self) -> bytes:
		"""Convert to ROM bytes"""
		return struct.pack('<9B',
			self.fire, self.water, self.earth, self.wind,
			self.holy, self.dark, self.poison,
			self.physical, self.magical
		)
	
	@classmethod
	def from_bytes(cls, data: bytes) -> 'ResistanceData':
		"""Load from ROM bytes"""
		values = struct.unpack('<9B', data[:9])
		return cls(
			fire=values[0], water=values[1], earth=values[2], wind=values[3],
			holy=values[4], dark=values[5], poison=values[6],
			physical=values[7], magical=values[8]
		)


@dataclass
class ItemDrop:
	"""Enemy item drop data"""
	item_id: int = 0		  # Item ID
	drop_rate: int = 0		# Drop rate (0-255, 128=50%)
	drop_type: DropType = DropType.NONE
	rare: bool = False		# Rare drop flag
	
	def to_bytes(self) -> bytes:
		"""Convert to ROM bytes"""
		flags = (self.drop_type & 0x0F) | (0x80 if self.rare else 0)
		return struct.pack('<BBB', self.item_id, self.drop_rate, flags)
	
	@classmethod
	def from_bytes(cls, data: bytes) -> 'ItemDrop':
		"""Load from ROM bytes"""
		item_id, drop_rate, flags = struct.unpack('<BBB', data[:3])
		return cls(
			item_id=item_id,
			drop_rate=drop_rate,
			drop_type=DropType(flags & 0x0F),
			rare=bool(flags & 0x80)
		)


@dataclass
class AIAction:
	"""Single AI action/spell"""
	action_type: int = 0	  # 0=attack, 1=spell, 2=special
	target_id: int = 0		# Spell/ability ID
	condition: int = 0		# HP threshold or condition
	priority: int = 0		 # Action priority (0-255)
	probability: int = 100	# Chance to use (0-100%)
	
	def to_bytes(self) -> bytes:
		"""Convert to ROM bytes"""
		return struct.pack('<5B',
			self.action_type, self.target_id, self.condition,
			self.priority, self.probability
		)
	
	@classmethod
	def from_bytes(cls, data: bytes) -> 'AIAction':
		"""Load from ROM bytes"""
		values = struct.unpack('<5B', data[:5])
		return cls(
			action_type=values[0],
			target_id=values[1],
			condition=values[2],
			priority=values[3],
			probability=values[4]
		)


@dataclass
class AIScript:
	"""Enemy AI script"""
	behavior: AIBehavior = AIBehavior.NORMAL
	actions: List[AIAction] = field(default_factory=list)
	counter_action: Optional[AIAction] = None
	death_action: Optional[AIAction] = None
	
	# HP threshold actions
	hp_75_action: Optional[AIAction] = None
	hp_50_action: Optional[AIAction] = None
	hp_25_action: Optional[AIAction] = None
	
	def to_bytes(self) -> bytes:
		"""Convert to ROM bytes"""
		data = bytearray()
		data.append(self.behavior)
		data.append(len(self.actions))
		
		for action in self.actions:
			data.extend(action.to_bytes())
		
		# Optional actions
		if self.counter_action:
			data.extend(self.counter_action.to_bytes())
		else:
			data.extend(b'\x00' * 5)
		
		if self.death_action:
			data.extend(self.death_action.to_bytes())
		else:
			data.extend(b'\x00' * 5)
		
		# HP threshold actions
		for threshold_action in [self.hp_75_action, self.hp_50_action, self.hp_25_action]:
			if threshold_action:
				data.extend(threshold_action.to_bytes())
			else:
				data.extend(b'\x00' * 5)
		
		return bytes(data)
	
	@classmethod
	def from_bytes(cls, data: bytes) -> 'AIScript':
		"""Load from ROM bytes"""
		offset = 0
		behavior = AIBehavior(data[offset])
		offset += 1
		
		action_count = data[offset]
		offset += 1
		
		actions = []
		for _ in range(action_count):
			actions.append(AIAction.from_bytes(data[offset:]))
			offset += 5
		
		counter_action = AIAction.from_bytes(data[offset:])
		offset += 5
		if counter_action.action_type == 0:
			counter_action = None
		
		death_action = AIAction.from_bytes(data[offset:])
		offset += 5
		if death_action.action_type == 0:
			death_action = None
		
		hp_75 = AIAction.from_bytes(data[offset:])
		offset += 5
		hp_75_action = hp_75 if hp_75.action_type != 0 else None
		
		hp_50 = AIAction.from_bytes(data[offset:])
		offset += 5
		hp_50_action = hp_50 if hp_50.action_type != 0 else None
		
		hp_25 = AIAction.from_bytes(data[offset:])
		hp_25_action = hp_25 if hp_25.action_type != 0 else None
		
		return cls(
			behavior=behavior,
			actions=actions,
			counter_action=counter_action,
			death_action=death_action,
			hp_75_action=hp_75_action,
			hp_50_action=hp_50_action,
			hp_25_action=hp_25_action
		)


@dataclass
class SpriteInfo:
	"""Enemy sprite/graphics information"""
	sprite_id: int = 0		   # Sprite sheet ID
	palette_id: int = 0		  # Palette ID
	tile_offset: int = 0		 # Tile offset in VRAM
	width: int = 16			  # Width in pixels
	height: int = 16			 # Height in pixels
	animation_frames: int = 1	# Number of animation frames
	animation_speed: int = 8	 # Frames between animation updates
	
	def to_bytes(self) -> bytes:
		"""Convert to ROM bytes"""
		return struct.pack('<7B',
			self.sprite_id, self.palette_id, self.tile_offset,
			self.width // 8, self.height // 8,
			self.animation_frames, self.animation_speed
		)
	
	@classmethod
	def from_bytes(cls, data: bytes) -> 'SpriteInfo':
		"""Load from ROM bytes"""
		values = struct.unpack('<7B', data[:7])
		return cls(
			sprite_id=values[0],
			palette_id=values[1],
			tile_offset=values[2],
			width=values[3] * 8,
			height=values[4] * 8,
			animation_frames=values[5],
			animation_speed=values[6]
		)


@dataclass
class EnemyStats:
	"""Enemy battle statistics"""
	hp: int = 100				# Hit points
	attack: int = 10			 # Physical attack power
	defense: int = 10			# Physical defense
	magic: int = 10			  # Magic power
	magic_defense: int = 10	  # Magic defense
	speed: int = 10			  # Speed/agility
	evade: int = 0			   # Evade percentage (0-100)
	critical: int = 5			# Critical hit rate (0-100)
	
	# Experience/money rewards
	exp: int = 10				# Experience points
	gold: int = 10			   # Gold reward
	
	def to_bytes(self) -> bytes:
		"""Convert to ROM bytes"""
		return struct.pack('<10H',
			self.hp, self.attack, self.defense, self.magic,
			self.magic_defense, self.speed, self.evade, self.critical,
			self.exp, self.gold
		)
	
	@classmethod
	def from_bytes(cls, data: bytes) -> 'EnemyStats':
		"""Load from ROM bytes"""
		values = struct.unpack('<10H', data[:20])
		return cls(
			hp=values[0], attack=values[1], defense=values[2],
			magic=values[3], magic_defense=values[4], speed=values[5],
			evade=values[6], critical=values[7], exp=values[8], gold=values[9]
		)


@dataclass
class Enemy:
	"""Complete enemy data"""
	enemy_id: int = 0
	name: str = "New Enemy"
	
	# Core stats
	stats: EnemyStats = field(default_factory=EnemyStats)
	
	# Resistances
	resistances: ResistanceData = field(default_factory=ResistanceData)
	
	# Flags and properties
	flags: EnemyFlags = EnemyFlags.NONE
	level: int = 1
	
	# AI and behavior
	ai_script: AIScript = field(default_factory=AIScript)
	
	# Drops
	common_drop: ItemDrop = field(default_factory=ItemDrop)
	rare_drop: ItemDrop = field(default_factory=ItemDrop)
	
	# Graphics
	sprite: SpriteInfo = field(default_factory=SpriteInfo)
	
	# ROM addresses
	address: int = 0			 # Base address in ROM
	pointer: int = 0			 # SNES pointer
	
	# Editor metadata
	modified: bool = False
	notes: str = ""
	
	def to_bytes(self) -> bytes:
		"""
		Serialize enemy to ROM format
		
		Returns:
			bytes: Complete enemy data block
		"""
		data = bytearray()
		
		# Write stats (20 bytes)
		data.extend(self.stats.to_bytes())
		
		# Write resistances (9 bytes)
		data.extend(self.resistances.to_bytes())
		
		# Write flags and level (3 bytes)
		data.extend(struct.pack('<HB', self.flags, self.level))
		
		# Write drops (6 bytes)
		data.extend(self.common_drop.to_bytes())
		data.extend(self.rare_drop.to_bytes())
		
		# Write sprite info (7 bytes)
		data.extend(self.sprite.to_bytes())
		
		# Write AI script (variable length, max 128 bytes)
		ai_data = self.ai_script.to_bytes()
		data.extend(ai_data[:128])  # Truncate if too long
		
		# Pad to fixed size if needed (can be adjusted)
		while len(data) < 256:
			data.append(0x00)
		
		return bytes(data[:256])  # Fixed 256 byte enemy block
	
	@classmethod
	def from_bytes(cls, enemy_id: int, data: bytes, address: int = 0) -> 'Enemy':
		"""
		Load enemy from ROM bytes
		
		Args:
			enemy_id: Enemy ID number
			data: ROM data bytes
			address: ROM address of enemy data
		
		Returns:
			Enemy: Loaded enemy data
		"""
		offset = 0
		
		# Load stats (20 bytes)
		stats = EnemyStats.from_bytes(data[offset:])
		offset += 20
		
		# Load resistances (9 bytes)
		resistances = ResistanceData.from_bytes(data[offset:])
		offset += 9
		
		# Load flags and level (3 bytes)
		flags_val, level = struct.unpack('<HB', data[offset:offset+3])
		flags = EnemyFlags(flags_val)
		offset += 3
		
		# Load drops (6 bytes)
		common_drop = ItemDrop.from_bytes(data[offset:])
		offset += 3
		rare_drop = ItemDrop.from_bytes(data[offset:])
		offset += 3
		
		# Load sprite (7 bytes)
		sprite = SpriteInfo.from_bytes(data[offset:])
		offset += 7
		
		# Load AI script (remaining bytes up to 128)
		ai_script = AIScript.from_bytes(data[offset:offset+128])
		
		return cls(
			enemy_id=enemy_id,
			name=f"Enemy_{enemy_id:03X}",
			stats=stats,
			resistances=resistances,
			flags=flags,
			level=level,
			ai_script=ai_script,
			common_drop=common_drop,
			rare_drop=rare_drop,
			sprite=sprite,
			address=address,
			pointer=0,
			modified=False
		)
	
	def calculate_difficulty(self) -> float:
		"""
		Calculate relative difficulty rating
		
		Returns:
			float: Difficulty score (higher = harder)
		"""
		# Base calculation from stats
		difficulty = (
			self.stats.hp * 0.1 +
			self.stats.attack * 2 +
			self.stats.defense * 1.5 +
			self.stats.magic * 1.8 +
			self.stats.magic_defense * 1.2 +
			self.stats.speed * 1.0
		)
		
		# Adjust for special abilities
		if self.flags & EnemyFlags.BOSS:
			difficulty *= 2.0
		if self.flags & EnemyFlags.REGENERATES:
			difficulty *= 1.3
		if self.flags & EnemyFlags.COUNTER_ATTACKS:
			difficulty *= 1.2
		
		# Adjust for immunities
		immunity_count = sum([
			bool(self.flags & EnemyFlags.IMMUNE_TO_SLEEP),
			bool(self.flags & EnemyFlags.IMMUNE_TO_PARALYZE),
			bool(self.flags & EnemyFlags.IMMUNE_TO_CONFUSE),
			bool(self.flags & EnemyFlags.IMMUNE_TO_BLIND),
			bool(self.flags & EnemyFlags.IMMUNE_TO_POISON),
		])
		difficulty *= (1.0 + immunity_count * 0.1)
		
		return difficulty
	
	def get_weaknesses(self) -> List[ElementType]:
		"""
		Get list of elemental weaknesses
		
		Returns:
			List of elements enemy is weak to (>100% damage)
		"""
		weaknesses = []
		
		if self.resistances.fire > 100:
			weaknesses.append(ElementType.FIRE)
		if self.resistances.water > 100:
			weaknesses.append(ElementType.WATER)
		if self.resistances.earth > 100:
			weaknesses.append(ElementType.EARTH)
		if self.resistances.wind > 100:
			weaknesses.append(ElementType.WIND)
		if self.resistances.holy > 100:
			weaknesses.append(ElementType.HOLY)
		if self.resistances.dark > 100:
			weaknesses.append(ElementType.DARK)
		
		return weaknesses
	
	def get_resistances(self) -> List[ElementType]:
		"""
		Get list of elemental resistances
		
		Returns:
			List of elements enemy resists (<100% damage)
		"""
		resistances = []
		
		if 0 < self.resistances.fire < 100:
			resistances.append(ElementType.FIRE)
		if 0 < self.resistances.water < 100:
			resistances.append(ElementType.WATER)
		if 0 < self.resistances.earth < 100:
			resistances.append(ElementType.EARTH)
		if 0 < self.resistances.wind < 100:
			resistances.append(ElementType.WIND)
		if 0 < self.resistances.holy < 100:
			resistances.append(ElementType.HOLY)
		if 0 < self.resistances.dark < 100:
			resistances.append(ElementType.DARK)
		
		return resistances
	
	def get_immunities(self) -> List[ElementType]:
		"""
		Get list of elemental immunities
		
		Returns:
			List of elements enemy is immune to (0% damage)
		"""
		immunities = []
		
		if self.resistances.fire == 0:
			immunities.append(ElementType.FIRE)
		if self.resistances.water == 0:
			immunities.append(ElementType.WATER)
		if self.resistances.earth == 0:
			immunities.append(ElementType.EARTH)
		if self.resistances.wind == 0:
			immunities.append(ElementType.WIND)
		if self.resistances.holy == 0:
			immunities.append(ElementType.HOLY)
		if self.resistances.dark == 0:
			immunities.append(ElementType.DARK)
		
		return immunities
	
	def __repr__(self) -> str:
		"""String representation"""
		return (
			f"Enemy(id=0x{self.enemy_id:03X}, name='{self.name}', "
			f"level={self.level}, hp={self.stats.hp}, "
			f"difficulty={self.calculate_difficulty():.1f})"
		)


# Enemy name database (will be loaded from ROM)
ENEMY_NAMES: Dict[int, str] = {
	0x00: "Goblin",
	0x01: "Basilisk",
	0x02: "Minotaur",
	0x03: "Hydra",
	0x04: "Red Dragon",
	0x05: "Behemoth",
	# ... more enemies would be loaded from ROM
}


def get_enemy_name(enemy_id: int) -> str:
	"""
	Get enemy name by ID
	
	Args:
		enemy_id: Enemy ID
	
	Returns:
		str: Enemy name or default
	"""
	return ENEMY_NAMES.get(enemy_id, f"Enemy_{enemy_id:03X}")
