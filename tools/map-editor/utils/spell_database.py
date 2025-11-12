"""
FFMQ Spell Database Manager

Manages the complete spell/magic database including loading from ROM,
saving to ROM, searching, and spell learning data.
"""

from typing import Dict, List, Optional, Tuple
from pathlib import Path
import struct
import json

from spell_data import Spell, SpellElement, SpellTarget, SpellFlags, SPELL_NAMES


# ROM addresses for spell data
SPELL_DATA_BASE = 0x0E0000  # Base address for spell data
SPELL_COUNT = 128		   # Total number of spells
SPELL_SIZE = 64			 # Size of each spell data block


class SpellDatabase:
	"""
	Manages the complete FFMQ spell database
	
	Handles loading spells from ROM, editing, and saving back to ROM.
	"""
	
	def __init__(self):
		"""Initialize empty spell database"""
		self.spells: Dict[int, Spell] = {}
		self.rom_data: Optional[bytes] = None
		self.rom_path: Optional[Path] = None
	
	def load_from_rom(self, rom_path: str):
		"""
		Load all spells from ROM
		
		Args:
			rom_path: Path to FFMQ ROM file
		"""
		rom_path_obj = Path(rom_path)
		if not rom_path_obj.exists():
			raise FileNotFoundError(f"ROM not found: {rom_path}")
		
		with open(rom_path_obj, 'rb') as f:
			self.rom_data = f.read()
		
		self.rom_path = rom_path_obj
		self.spells.clear()
		
		# Load each spell
		for spell_id in range(SPELL_COUNT):
			address = SPELL_DATA_BASE + (spell_id * SPELL_SIZE)
			
			if address + SPELL_SIZE > len(self.rom_data):
				break
			
			spell_bytes = self.rom_data[address:address + SPELL_SIZE]
			spell = Spell.from_bytes(spell_id, spell_bytes, address)
			
			# Set name from database if available
			if spell_id in SPELL_NAMES:
				spell.name = SPELL_NAMES[spell_id]
			
			self.spells[spell_id] = spell
		
		print(f"Loaded {len(self.spells)} spells from ROM")
	
	def save_to_rom(self, output_path: str):
		"""
		Save all spells to ROM
		
		Args:
			output_path: Output ROM file path
		"""
		if not self.rom_data:
			raise RuntimeError("No ROM data loaded")
		
		# Create copy of ROM data
		new_rom = bytearray(self.rom_data)
		
		# Write each modified spell
		modified_count = 0
		for spell_id, spell in self.spells.items():
			if spell.modified:
				address = SPELL_DATA_BASE + (spell_id * SPELL_SIZE)
				spell_bytes = spell.to_bytes()
				new_rom[address:address + len(spell_bytes)] = spell_bytes
				modified_count += 1
		
		# Write to file
		with open(output_path, 'wb') as f:
			f.write(new_rom)
		
		print(f"Saved {modified_count} modified spells to {output_path}")
	
	def get_spell(self, spell_id: int) -> Optional[Spell]:
		"""
		Get spell by ID
		
		Args:
			spell_id: Spell ID
		
		Returns:
			Spell or None if not found
		"""
		return self.spells.get(spell_id)
	
	def search_spells(self, query: str, case_sensitive: bool = False) -> List[Spell]:
		"""
		Search spells by name
		
		Args:
			query: Search query
			case_sensitive: Whether to use case-sensitive search
		
		Returns:
			List of matching spells
		"""
		if not case_sensitive:
			query = query.lower()
		
		results = []
		for spell in self.spells.values():
			name = spell.name if case_sensitive else spell.name.lower()
			if query in name:
				results.append(spell)
		
		return results
	
	def filter_by_element(self, element: SpellElement) -> List[Spell]:
		"""
		Filter spells by element
		
		Args:
			element: Element type
		
		Returns:
			List of spells with matching element
		"""
		return [
			spell for spell in self.spells.values()
			if spell.element == element
		]
	
	def filter_by_target(self, target: SpellTarget) -> List[Spell]:
		"""
		Filter spells by targeting mode
		
		Args:
			target: Targeting mode
		
		Returns:
			List of spells with matching target
		"""
		return [
			spell for spell in self.spells.values()
			if spell.target == target
		]
	
	def filter_by_flags(self, flags: SpellFlags) -> List[Spell]:
		"""
		Filter spells by flags
		
		Args:
			flags: Flags to filter by
		
		Returns:
			List of spells with matching flags
		"""
		return [
			spell for spell in self.spells.values()
			if spell.flags & flags
		]
	
	def get_healing_spells(self) -> List[Spell]:
		"""Get all healing spells"""
		return self.filter_by_flags(SpellFlags.HEALING)
	
	def get_offensive_spells(self) -> List[Spell]:
		"""Get all offensive spells"""
		return self.filter_by_flags(SpellFlags.OFFENSIVE)
	
	def get_status_spells(self) -> List[Spell]:
		"""Get all status effect spells"""
		return self.filter_by_flags(SpellFlags.STATUS_EFFECT)
	
	def get_by_mp_cost(self, ascending: bool = True) -> List[Spell]:
		"""
		Get spells sorted by MP cost
		
		Args:
			ascending: Sort ascending (cheapest first) or descending
		
		Returns:
			List of spells sorted by MP cost
		"""
		return sorted(
			self.spells.values(),
			key=lambda s: s.mp_cost,
			reverse=not ascending
		)
	
	def get_by_power(self, ascending: bool = False) -> List[Spell]:
		"""
		Get spells sorted by power
		
		Args:
			ascending: Sort ascending (weakest first) or descending
		
		Returns:
			List of spells sorted by power
		"""
		return sorted(
			self.spells.values(),
			key=lambda s: s.base_power,
			reverse=not ascending
		)
	
	def get_statistics(self) -> Dict[str, any]:
		"""
		Get database statistics
		
		Returns:
			Dictionary of statistics
		"""
		if not self.spells:
			return {}
		
		total = len(self.spells)
		modified = sum(1 for s in self.spells.values() if s.modified)
		
		# Count by type
		offensive = len(self.get_offensive_spells())
		healing = len(self.get_healing_spells())
		status = len(self.get_status_spells())
		
		# Calculate averages
		avg_mp = sum(s.mp_cost for s in self.spells.values()) / total
		avg_power = sum(s.base_power for s in self.spells.values()) / total
		
		# Find extremes
		most_expensive = max(self.spells.values(), key=lambda s: s.mp_cost)
		most_powerful = max(self.spells.values(), key=lambda s: s.base_power)
		
		# Count by element
		element_counts = {}
		for spell in self.spells.values():
			elem_name = spell.get_element_name()
			element_counts[elem_name] = element_counts.get(elem_name, 0) + 1
		
		return {
			'total': total,
			'modified': modified,
			'offensive': offensive,
			'healing': healing,
			'status': status,
			'avg_mp_cost': avg_mp,
			'avg_power': avg_power,
			'most_expensive': most_expensive,
			'most_powerful': most_powerful,
			'element_counts': element_counts
		}
	
	def clone_spell(self, source_id: int, new_id: int) -> Optional[Spell]:
		"""
		Clone a spell to a new ID
		
		Args:
			source_id: Source spell ID
			new_id: New spell ID
		
		Returns:
			Cloned spell or None if source not found
		"""
		source = self.spells.get(source_id)
		if not source:
			return None
		
		from copy import deepcopy
		clone = deepcopy(source)
		clone.spell_id = new_id
		clone.name = f"{source.name} (Clone)"
		clone.modified = True
		
		self.spells[new_id] = clone
		return clone
	
	def batch_scale_power(self, spell_ids: List[int], scale_factor: float):
		"""
		Batch scale spell power
		
		Args:
			spell_ids: List of spell IDs to scale
			scale_factor: Scaling factor (1.0 = no change, 2.0 = double)
		"""
		for spell_id in spell_ids:
			spell = self.spells.get(spell_id)
			if spell:
				spell.base_power = int(spell.base_power * scale_factor)
				spell.power_variance = int(spell.power_variance * scale_factor)
				spell.modified = True
	
	def batch_scale_mp_cost(self, spell_ids: List[int], scale_factor: float):
		"""
		Batch scale MP costs
		
		Args:
			spell_ids: List of spell IDs to scale
			scale_factor: Scaling factor
		"""
		for spell_id in spell_ids:
			spell = self.spells.get(spell_id)
			if spell:
				spell.mp_cost = int(spell.mp_cost * scale_factor)
				spell.modified = True
	
	def export_to_csv(self, output_path: str):
		"""
		Export spell database to CSV
		
		Args:
			output_path: Output CSV file path
		"""
		import csv
		
		with open(output_path, 'w', newline='', encoding='utf-8') as f:
			writer = csv.writer(f)
			
			# Header
			writer.writerow([
				'ID', 'Name', 'MP Cost', 'Element', 'Target', 'Type',
				'Power', 'Variance', 'Accuracy', 'Level Required',
				'Status Effects'
			])
			
			# Data
			for spell_id, spell in sorted(self.spells.items()):
				writer.writerow([
					f'0x{spell_id:03X}',
					spell.name,
					spell.mp_cost,
					spell.get_element_name(),
					spell.get_target_description(),
					spell.get_spell_type(),
					spell.base_power,
					spell.power_variance,
					spell.accuracy,
					spell.level_required,
					', '.join(spell.get_status_list())
				])
	
	def export_to_json(self, output_path: str, pretty: bool = True):
		"""
		Export spell database to JSON
		
		Args:
			output_path: Output JSON file path
			pretty: Pretty-print JSON
		"""
		from dataclasses import asdict
		
		data = {}
		for spell_id, spell in self.spells.items():
			# Convert to dictionary
			spell_dict = {
				'id': spell_id,
				'name': spell.name,
				'mp_cost': spell.mp_cost,
				'level_required': spell.level_required,
				'element': spell.get_element_name(),
				'target': spell.get_target_description(),
				'type': spell.get_spell_type(),
				'base_power': spell.base_power,
				'power_variance': spell.power_variance,
				'multiplier': spell.multiplier,
				'accuracy': spell.accuracy,
				'critical_rate': spell.critical_rate,
				'status_effects': spell.get_status_list(),
				'status_chance': spell.status_chance,
				'status_duration': spell.status_duration,
				'animation': asdict(spell.animation),
				'flags': spell.flags.value,
			}
			data[f'0x{spell_id:03X}'] = spell_dict
		
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent=2 if pretty else None)
	
	def create_spell_progression(self, base_spell_id: int, tier_count: int = 3,
								power_scale: float = 1.5, mp_scale: float = 1.3) -> List[int]:
		"""
		Create a progression of spells (e.g., Fire -> Fira -> Firaga)
		
		Args:
			base_spell_id: Base spell ID
			tier_count: Number of tiers to create
			power_scale: Power multiplier per tier
			mp_scale: MP cost multiplier per tier
		
		Returns:
			List of created spell IDs
		"""
		base_spell = self.spells.get(base_spell_id)
		if not base_spell:
			return []
		
		created_ids = [base_spell_id]
		
		for tier in range(1, tier_count):
			# Find next available ID
			new_id = base_spell_id + tier
			while new_id in self.spells:
				new_id += 1
			
			# Clone and scale
			clone = self.clone_spell(base_spell_id, new_id)
			if clone:
				tier_suffix = ['', 'ra', 'ga', 'ja'][min(tier, 3)]
				clone.name = f"{base_spell.name}{tier_suffix}"
				clone.base_power = int(base_spell.base_power * (power_scale ** tier))
				clone.power_variance = int(base_spell.power_variance * (power_scale ** tier))
				clone.mp_cost = int(base_spell.mp_cost * (mp_scale ** tier))
				clone.level_required = base_spell.level_required + (tier * 5)
				created_ids.append(new_id)
		
		return created_ids
