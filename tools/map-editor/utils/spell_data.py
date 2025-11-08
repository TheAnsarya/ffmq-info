"""
FFMQ Spell/Magic Data Structures

Comprehensive spell system including damage formulas, MP costs,
animations, targeting, and special effects.
"""

from dataclasses import dataclass, field
from typing import List, Dict, Optional, Set, Tuple
from enum import IntEnum, IntFlag
import struct


class SpellElement(IntEnum):
	"""Spell elemental types"""
	NONE = 0
	FIRE = 1
	WATER = 2
	EARTH = 3
	WIND = 4
	HOLY = 5
	DARK = 6
	CURE = 7      # Healing
	STATUS = 8    # Status effects


class SpellTarget(IntEnum):
	"""Spell targeting modes"""
	SINGLE_ENEMY = 0
	ALL_ENEMIES = 1
	SINGLE_ALLY = 2
	ALL_ALLIES = 3
	SELF = 4
	RANDOM_ENEMY = 5
	RANDOM_ALLY = 6
	ALL = 7


class SpellFlags(IntFlag):
	"""Spell behavior flags"""
	NONE = 0
	OFFENSIVE = 0x01        # Deals damage
	HEALING = 0x02          # Restores HP/MP
	STATUS_EFFECT = 0x04    # Applies status
	REFLECTABLE = 0x08      # Can be reflected
	BLOCKABLE = 0x10        # Can be blocked
	IGNORES_DEFENSE = 0x20  # Ignores magic defense
	DRAINS_HP = 0x40        # Drains HP from target
	DRAINS_MP = 0x80        # Drains MP from target
	REVIVE = 0x100          # Revives KO'd ally
	REMOVE_STATUS = 0x200   # Removes status effects


class StatusEffect(IntFlag):
	"""Status effects that spells can apply"""
	NONE = 0
	POISON = 0x01
	BLIND = 0x02
	SILENCE = 0x04
	SLEEP = 0x08
	PARALYZE = 0x10
	CONFUSE = 0x20
	BERSERK = 0x40
	HASTE = 0x80
	SLOW = 0x100
	PROTECT = 0x200
	SHELL = 0x400
	REGEN = 0x800
	DOOM = 0x1000


class DamageFormula(IntEnum):
	"""Damage calculation formulas"""
	FIXED = 0               # Fixed damage
	MAGIC_BASED = 1         # Based on caster's magic stat
	LEVEL_BASED = 2         # Based on caster's level
	HP_PERCENTAGE = 3       # Percentage of target's HP
	MP_BASED = 4            # Based on caster's MP
	DEFENSE_PIERCE = 5      # Ignores defense
	HYBRID = 6              # Physical + Magic
	RANDOM = 7              # Random damage in range


@dataclass
class AnimationData:
	"""Spell animation data"""
	animation_id: int = 0       # Animation sprite ID
	palette_id: int = 0         # Palette for animation
	duration: int = 60          # Duration in frames
	sound_effect: int = 0       # Sound effect ID
	screen_flash: bool = False  # Screen flash effect
	shake_screen: bool = False  # Screen shake effect
	projectile: bool = False    # Projectile-based
	
	def to_bytes(self) -> bytes:
		"""Convert to ROM bytes"""
		flags = (
			(0x01 if self.screen_flash else 0) |
			(0x02 if self.shake_screen else 0) |
			(0x04 if self.projectile else 0)
		)
		return struct.pack('<HBBBB',
			self.animation_id, self.palette_id, self.duration,
			self.sound_effect, flags
		)
	
	@classmethod
	def from_bytes(cls, data: bytes) -> 'AnimationData':
		"""Load from ROM bytes"""
		anim_id, pal_id, duration, sound, flags = struct.unpack('<HBBBB', data[:6])
		return cls(
			animation_id=anim_id,
			palette_id=pal_id,
			duration=duration,
			sound_effect=sound,
			screen_flash=bool(flags & 0x01),
			shake_screen=bool(flags & 0x02),
			projectile=bool(flags & 0x04)
		)


@dataclass
class Spell:
	"""Complete spell data"""
	spell_id: int = 0
	name: str = "New Spell"
	
	# Costs
	mp_cost: int = 0            # MP cost to cast
	level_required: int = 1     # Minimum level to learn
	
	# Targeting and element
	element: SpellElement = SpellElement.NONE
	target: SpellTarget = SpellTarget.SINGLE_ENEMY
	
	# Flags
	flags: SpellFlags = SpellFlags.NONE
	
	# Damage/healing
	damage_formula: DamageFormula = DamageFormula.MAGIC_BASED
	base_power: int = 0         # Base damage/healing amount
	power_variance: int = 0     # Random variance (±)
	multiplier: float = 1.0     # Damage multiplier
	
	# Status effects
	status_effects: StatusEffect = StatusEffect.NONE
	status_chance: int = 100    # Chance to apply status (0-100%)
	status_duration: int = 3    # Duration in turns
	
	# Accuracy and critical
	accuracy: int = 100         # Hit chance (0-100%)
	critical_rate: int = 0      # Critical hit rate (0-100%)
	
	# Animation
	animation: AnimationData = field(default_factory=AnimationData)
	
	# Metadata
	description: str = ""
	learned_by: List[int] = field(default_factory=list)  # Character IDs
	
	# ROM addresses
	address: int = 0
	pointer: int = 0
	
	# Editor
	modified: bool = False
	notes: str = ""
	
	def to_bytes(self) -> bytes:
		"""
		Serialize spell to ROM format
		
		Returns:
			bytes: Complete spell data block
		"""
		data = bytearray()
		
		# Basic info (12 bytes)
		data.extend(struct.pack('<BBBBBB',
			self.mp_cost,
			self.level_required,
			self.element,
			self.target,
			self.damage_formula,
			self.accuracy
		))
		
		# Power and variance (6 bytes)
		data.extend(struct.pack('<HHH',
			self.base_power,
			self.power_variance,
			int(self.multiplier * 100)  # Store as percentage
		))
		
		# Status (6 bytes)
		data.extend(struct.pack('<HBB',
			self.status_effects,
			self.status_chance,
			self.status_duration
		))
		
		# Flags and critical (4 bytes)
		data.extend(struct.pack('<HBB',
			self.flags,
			self.critical_rate,
			0  # Padding
		))
		
		# Animation (6 bytes)
		data.extend(self.animation.to_bytes())
		
		# Pad to 64 bytes
		while len(data) < 64:
			data.append(0x00)
		
		return bytes(data[:64])
	
	@classmethod
	def from_bytes(cls, spell_id: int, data: bytes, address: int = 0) -> 'Spell':
		"""
		Load spell from ROM bytes
		
		Args:
			spell_id: Spell ID
			data: ROM data bytes
			address: ROM address
		
		Returns:
			Spell: Loaded spell data
		"""
		offset = 0
		
		# Basic info
		mp_cost, level_req, element, target, formula, accuracy = struct.unpack('<BBBBBB', data[offset:offset+6])
		offset += 6
		
		# Power and variance
		base_power, variance, mult_pct = struct.unpack('<HHH', data[offset:offset+6])
		multiplier = mult_pct / 100.0
		offset += 6
		
		# Status
		status_val, status_chance, status_dur = struct.unpack('<HBB', data[offset:offset+4])
		offset += 4
		
		# Flags and critical
		flags_val, crit_rate, _ = struct.unpack('<HBB', data[offset:offset+4])
		offset += 4
		
		# Animation
		animation = AnimationData.from_bytes(data[offset:])
		
		return cls(
			spell_id=spell_id,
			name=f"Spell_{spell_id:03X}",
			mp_cost=mp_cost,
			level_required=level_req,
			element=SpellElement(element),
			target=SpellTarget(target),
			flags=SpellFlags(flags_val),
			damage_formula=DamageFormula(formula),
			base_power=base_power,
			power_variance=variance,
			multiplier=multiplier,
			status_effects=StatusEffect(status_val),
			status_chance=status_chance,
			status_duration=status_dur,
			accuracy=accuracy,
			critical_rate=crit_rate,
			animation=animation,
			address=address,
			modified=False
		)
	
	def calculate_damage(self, caster_magic: int, target_def: int, caster_level: int = 1) -> Tuple[int, int]:
		"""
		Calculate damage range
		
		Args:
			caster_magic: Caster's magic stat
			target_def: Target's magic defense
			caster_level: Caster's level
		
		Returns:
			Tuple of (min_damage, max_damage)
		"""
		if self.damage_formula == DamageFormula.FIXED:
			damage = self.base_power
		
		elif self.damage_formula == DamageFormula.MAGIC_BASED:
			damage = int((caster_magic * self.multiplier) + self.base_power - (target_def * 0.5))
		
		elif self.damage_formula == DamageFormula.LEVEL_BASED:
			damage = int((caster_level * self.multiplier) + self.base_power)
		
		elif self.damage_formula == DamageFormula.HP_PERCENTAGE:
			damage = self.base_power  # Percentage handled by battle system
		
		elif self.damage_formula == DamageFormula.MP_BASED:
			damage = int((caster_magic * 0.5 * self.multiplier) + self.base_power)
		
		elif self.damage_formula == DamageFormula.DEFENSE_PIERCE:
			damage = int((caster_magic * self.multiplier) + self.base_power)
		
		elif self.damage_formula == DamageFormula.HYBRID:
			damage = int((caster_magic * self.multiplier) + self.base_power - (target_def * 0.3))
		
		else:  # RANDOM
			damage = self.base_power
		
		damage = max(0, damage)
		
		min_dmg = max(0, damage - self.power_variance)
		max_dmg = damage + self.power_variance
		
		return (min_dmg, max_dmg)
	
	def get_element_name(self) -> str:
		"""Get element name"""
		return self.element.name.title()
	
	def get_target_description(self) -> str:
		"""Get targeting description"""
		descriptions = {
			SpellTarget.SINGLE_ENEMY: "Single Enemy",
			SpellTarget.ALL_ENEMIES: "All Enemies",
			SpellTarget.SINGLE_ALLY: "Single Ally",
			SpellTarget.ALL_ALLIES: "All Allies",
			SpellTarget.SELF: "Self",
			SpellTarget.RANDOM_ENEMY: "Random Enemy",
			SpellTarget.RANDOM_ALLY: "Random Ally",
			SpellTarget.ALL: "Everyone",
		}
		return descriptions.get(self.target, "Unknown")
	
	def get_spell_type(self) -> str:
		"""Get spell type description"""
		if self.flags & SpellFlags.HEALING:
			return "Healing"
		elif self.flags & SpellFlags.OFFENSIVE:
			return "Offensive"
		elif self.flags & SpellFlags.STATUS_EFFECT:
			return "Status"
		elif self.flags & SpellFlags.REMOVE_STATUS:
			return "Cure"
		elif self.flags & SpellFlags.REVIVE:
			return "Revive"
		else:
			return "Support"
	
	def get_status_list(self) -> List[str]:
		"""Get list of status effects"""
		effects = []
		for status in StatusEffect:
			if status != StatusEffect.NONE and (self.status_effects & status):
				effects.append(status.name.title())
		return effects
	
	def __repr__(self) -> str:
		"""String representation"""
		return (
			f"Spell(id=0x{self.spell_id:03X}, name='{self.name}', "
			f"mp={self.mp_cost}, element={self.get_element_name()}, "
			f"type={self.get_spell_type()})"
		)


# Spell name database (loaded from ROM)
SPELL_NAMES: Dict[int, str] = {
	0x00: "Fire",
	0x01: "Blizzard",
	0x02: "Thunder",
	0x03: "Aero",
	0x04: "White",
	0x05: "Cure",
	0x06: "Life",
	0x07: "Quake",
	0x08: "Meteor",
	0x09: "Flare",
	# White magic
	0x10: "Cure",
	0x11: "Heal",
	0x12: "Life",
	0x13: "Refresh",
	0x14: "Cleanse",
	0x15: "Exit",
	# Black magic
	0x20: "Fire",
	0x21: "Fira",
	0x22: "Firaga",
	0x23: "Blizzard",
	0x24: "Blizzara",
	0x25: "Blizzaga",
	# Wizardry
	0x30: "Thunder",
	0x31: "Thundara",
	0x32: "Thundaga",
	0x33: "Aero",
	0x34: "Aerora",
	0x35: "Aeroga",
	# ...more spells
}


def get_spell_name(spell_id: int) -> str:
	"""
	Get spell name by ID
	
	Args:
		spell_id: Spell ID
	
	Returns:
		str: Spell name or default
	"""
	return SPELL_NAMES.get(spell_id, f"Spell_{spell_id:03X}")


# Spell learning data (which characters can learn which spells)
SPELL_LEARNING: Dict[int, Dict[str, any]] = {
	# Benjamin
	0x00: {
		'spells': [0x00, 0x01, 0x02, 0x03],  # Fire, Blizzard, Thunder, Aero
		'levels': [5, 10, 15, 20]
	},
	# Kaeli
	0x01: {
		'spells': [0x10, 0x11, 0x12],  # Cure, Heal, Life
		'levels': [3, 8, 15]
	},
	# Phoebe
	0x02: {
		'spells': [0x20, 0x21, 0x22],  # Fire, Fira, Firaga
		'levels': [5, 12, 20]
	},
	# Reuben
	0x03: {
		'spells': [0x30, 0x31, 0x32],  # Thunder, Thundara, Thundaga
		'levels': [5, 12, 20]
	},
}
