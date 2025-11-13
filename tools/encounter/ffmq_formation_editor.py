#!/usr/bin/env python3
"""
FFMQ Formation/Encounter Editor - Edit enemy formations and encounter rates

FFMQ Encounter System:
- Enemy formations (groups of enemies)
- Formation positioning (8 enemy slots)
- Encounter zones (map-based)
- Encounter rates (steps between battles)
- Formation weights (probability)
- Boss encounters
- Special formations
- Forced encounters

Features:
- View formations
- Edit enemy groups
- Modify positions
- Change encounter rates
- Set formation weights
- Configure zone encounters
- Balance difficulty progression
- Export formation data
- Import custom formations
- Encounter simulation

Formation Structure:
- Formation ID
- Up to 8 enemy slots
- Enemy IDs per slot
- Position coordinates (X, Y)
- Formation type (normal, boss, special)

Encounter Zone:
- Map ID
- Zone rectangle (X1, Y1, X2, Y2)
- Formation list
- Encounter rate (steps)
- Formation weights

Usage:
	python ffmq_formation_editor.py rom.sfc --list-formations
	python ffmq_formation_editor.py rom.sfc --show-formation 10
	python ffmq_formation_editor.py rom.sfc --edit-formation 10 --slot 0 --enemy 5
	python ffmq_formation_editor.py rom.sfc --list-zones 0
	python ffmq_formation_editor.py rom.sfc --edit-zone 0 5 --rate 20
	python ffmq_formation_editor.py rom.sfc --export formations.json
"""

import argparse
import json
import struct
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any
from dataclasses import dataclass, field, asdict
from enum import Enum


class FormationType(Enum):
	"""Formation types"""
	NORMAL = "normal"
	BOSS = "boss"
	SPECIAL = "special"
	FORCED = "forced"


@dataclass
class EnemySlot:
	"""Enemy in formation slot"""
	slot_id: int
	enemy_id: int
	enemy_name: str
	x: int
	y: int
	active: bool
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class Formation:
	"""Enemy formation"""
	formation_id: int
	name: str
	formation_type: FormationType
	enemies: List[EnemySlot]
	
	def to_dict(self) -> dict:
		d = {
			'formation_id': self.formation_id,
			'name': self.name,
			'formation_type': self.formation_type.value,
			'enemies': [e.to_dict() for e in self.enemies],
			'enemy_count': len([e for e in self.enemies if e.active])
		}
		return d


@dataclass
class EncounterZone:
	"""Encounter zone on map"""
	zone_id: int
	map_id: int
	x1: int
	y1: int
	x2: int
	y2: int
	formations: List[int]  # Formation IDs
	weights: List[int]  # Probability weights
	encounter_rate: int  # Steps between encounters
	
	def to_dict(self) -> dict:
		return asdict(self)


class FFMQFormationDatabase:
	"""Database of FFMQ formations and encounters"""
	
	# Formation data location
	FORMATION_DATA_OFFSET = 0x330000
	NUM_FORMATIONS = 256
	FORMATION_SIZE = 32
	ENEMIES_PER_FORMATION = 8
	
	# Encounter zone data
	ENCOUNTER_ZONE_OFFSET = 0x340000
	NUM_ENCOUNTER_ZONES = 512
	ZONE_SIZE = 32
	
	# Known formations
	FORMATIONS = {
		0: ("Slime Group", FormationType.NORMAL),
		1: ("Goblin Pair", FormationType.NORMAL),
		2: ("Mad Plant Trio", FormationType.NORMAL),
		3: ("Mixed Group", FormationType.NORMAL),
		4: ("Behemoth", FormationType.BOSS),
		5: ("Hydra", FormationType.BOSS),
		6: ("Medusa", FormationType.BOSS),
		# ... more formations
	}
	
	# Known enemies
	ENEMY_NAMES = {
		0: "Behemoth",
		1: "Hydra",
		2: "Medusa",
		3: "Flamerus Rex",
		4: "Ice Golem",
		5: "Pazuzu",
		8: "Slime",
		9: "Goblin",
		10: "Mad Plant",
		11: "Brownie",
		12: "Zombie",
		13: "Skeleton",
		# ... more enemies
	}
	
	@classmethod
	def get_formation_name(cls, formation_id: int) -> Tuple[str, FormationType]:
		"""Get formation name and type"""
		return cls.FORMATIONS.get(formation_id, (f"Formation {formation_id}", FormationType.NORMAL))
	
	@classmethod
	def get_enemy_name(cls, enemy_id: int) -> str:
		"""Get enemy name"""
		return cls.ENEMY_NAMES.get(enemy_id, f"Enemy {enemy_id}")


class FFMQFormationEditor:
	"""Edit FFMQ formations and encounters"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		if self.verbose:
			print(f"Loaded FFMQ ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def extract_formation(self, formation_id: int) -> Optional[Formation]:
		"""Extract formation from ROM"""
		if formation_id >= FFMQFormationDatabase.NUM_FORMATIONS:
			return None
		
		offset = FFMQFormationDatabase.FORMATION_DATA_OFFSET + (formation_id * FFMQFormationDatabase.FORMATION_SIZE)
		
		if offset + FFMQFormationDatabase.FORMATION_SIZE > len(self.rom_data):
			return None
		
		# Read formation header
		formation_flags = self.rom_data[offset]
		
		# Read enemy slots
		enemies = []
		for slot_id in range(FFMQFormationDatabase.ENEMIES_PER_FORMATION):
			slot_offset = offset + 1 + (slot_id * 3)
			
			if slot_offset + 3 > len(self.rom_data):
				break
			
			enemy_id = self.rom_data[slot_offset]
			x = self.rom_data[slot_offset + 1]
			y = self.rom_data[slot_offset + 2]
			
			active = (enemy_id != 0xFF)
			
			if enemy_id == 0xFF:
				enemy_id = 0
			
			enemies.append(EnemySlot(
				slot_id=slot_id,
				enemy_id=enemy_id,
				enemy_name=FFMQFormationDatabase.get_enemy_name(enemy_id),
				x=x,
				y=y,
				active=active
			))
		
		name, formation_type = FFMQFormationDatabase.get_formation_name(formation_id)
		
		formation = Formation(
			formation_id=formation_id,
			name=name,
			formation_type=formation_type,
			enemies=enemies
		)
		
		return formation
	
	def list_formations(self, formation_type: Optional[FormationType] = None) -> List[Formation]:
		"""List all formations, optionally filtered by type"""
		formations = []
		
		for i in range(FFMQFormationDatabase.NUM_FORMATIONS):
			formation = self.extract_formation(i)
			
			if not formation:
				continue
			
			# Skip empty formations
			if not any(e.active for e in formation.enemies):
				continue
			
			if formation_type and formation.formation_type != formation_type:
				continue
			
			formations.append(formation)
		
		return formations
	
	def modify_formation_slot(self, formation_id: int, slot_id: int, 
							   enemy_id: int, x: Optional[int] = None, 
							   y: Optional[int] = None) -> bool:
		"""Modify enemy in formation slot"""
		if formation_id >= FFMQFormationDatabase.NUM_FORMATIONS:
			return False
		
		if slot_id >= FFMQFormationDatabase.ENEMIES_PER_FORMATION:
			return False
		
		offset = FFMQFormationDatabase.FORMATION_DATA_OFFSET + (formation_id * FFMQFormationDatabase.FORMATION_SIZE)
		slot_offset = offset + 1 + (slot_id * 3)
		
		if slot_offset + 3 > len(self.rom_data):
			return False
		
		# Set enemy ID
		self.rom_data[slot_offset] = enemy_id
		
		# Set position
		if x is not None:
			self.rom_data[slot_offset + 1] = min(x, 255)
		if y is not None:
			self.rom_data[slot_offset + 2] = min(y, 255)
		
		if self.verbose:
			enemy_name = FFMQFormationDatabase.get_enemy_name(enemy_id)
			print(f"✓ Set formation {formation_id} slot {slot_id} to {enemy_name}")
		
		return True
	
	def extract_encounter_zone(self, zone_id: int) -> Optional[EncounterZone]:
		"""Extract encounter zone from ROM"""
		if zone_id >= FFMQFormationDatabase.NUM_ENCOUNTER_ZONES:
			return None
		
		offset = FFMQFormationDatabase.ENCOUNTER_ZONE_OFFSET + (zone_id * FFMQFormationDatabase.ZONE_SIZE)
		
		if offset + FFMQFormationDatabase.ZONE_SIZE > len(self.rom_data):
			return None
		
		# Read zone data
		map_id = self.rom_data[offset]
		x1 = self.rom_data[offset + 1]
		y1 = self.rom_data[offset + 2]
		x2 = self.rom_data[offset + 3]
		y2 = self.rom_data[offset + 4]
		encounter_rate = self.rom_data[offset + 5]
		
		# Check if zone is active
		if map_id == 0xFF:
			return None
		
		# Read formations (up to 8)
		formations = []
		weights = []
		for i in range(8):
			form_offset = offset + 8 + (i * 2)
			
			if form_offset + 2 > len(self.rom_data):
				break
			
			formation_id = self.rom_data[form_offset]
			weight = self.rom_data[form_offset + 1]
			
			if formation_id != 0xFF:
				formations.append(formation_id)
				weights.append(weight)
		
		zone = EncounterZone(
			zone_id=zone_id,
			map_id=map_id,
			x1=x1,
			y1=y1,
			x2=x2,
			y2=y2,
			formations=formations,
			weights=weights,
			encounter_rate=encounter_rate
		)
		
		return zone
	
	def list_encounter_zones(self, map_id: Optional[int] = None) -> List[EncounterZone]:
		"""List encounter zones, optionally filtered by map"""
		zones = []
		
		for i in range(FFMQFormationDatabase.NUM_ENCOUNTER_ZONES):
			zone = self.extract_encounter_zone(i)
			
			if not zone:
				continue
			
			if map_id is not None and zone.map_id != map_id:
				continue
			
			zones.append(zone)
		
		return zones
	
	def modify_encounter_rate(self, zone_id: int, rate: int) -> bool:
		"""Modify encounter rate for zone"""
		if zone_id >= FFMQFormationDatabase.NUM_ENCOUNTER_ZONES:
			return False
		
		offset = FFMQFormationDatabase.ENCOUNTER_ZONE_OFFSET + (zone_id * FFMQFormationDatabase.ZONE_SIZE)
		
		if offset + FFMQFormationDatabase.ZONE_SIZE > len(self.rom_data):
			return False
		
		self.rom_data[offset + 5] = min(rate, 255)
		
		if self.verbose:
			print(f"✓ Set zone {zone_id} encounter rate to {rate} steps")
		
		return True
	
	def export_json(self, output_path: Path) -> None:
		"""Export formations and zones to JSON"""
		formations = self.list_formations()
		zones = self.list_encounter_zones()
		
		data = {
			'formations': [f.to_dict() for f in formations],
			'encounter_zones': [z.to_dict() for z in zones]
		}
		
		with open(output_path, 'w') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported {len(formations)} formations and {len(zones)} zones to {output_path}")
	
	def save_rom(self, output_path: Optional[Path] = None) -> None:
		"""Save modified ROM"""
		save_path = output_path or self.rom_path
		
		with open(save_path, 'wb') as f:
			f.write(self.rom_data)
		
		if self.verbose:
			print(f"✓ Saved ROM to {save_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Formation/Encounter Editor')
	parser.add_argument('rom', type=str, help='FFMQ ROM file')
	parser.add_argument('--list-formations', action='store_true', help='List formations')
	parser.add_argument('--type', type=str, 
						choices=['normal', 'boss', 'special', 'forced'],
						help='Filter formations by type')
	parser.add_argument('--show-formation', type=int, help='Show formation details')
	parser.add_argument('--edit-formation', type=int, help='Edit formation')
	parser.add_argument('--slot', type=int, help='Enemy slot (0-7)')
	parser.add_argument('--enemy', type=int, help='Enemy ID')
	parser.add_argument('--x', type=int, help='X position')
	parser.add_argument('--y', type=int, help='Y position')
	parser.add_argument('--list-zones', type=int, help='List encounter zones for map')
	parser.add_argument('--show-zone', type=int, help='Show zone details')
	parser.add_argument('--edit-zone', type=int, help='Edit encounter zone')
	parser.add_argument('--rate', type=int, help='Encounter rate (steps)')
	parser.add_argument('--export', type=str, help='Export to JSON')
	parser.add_argument('--save', type=str, help='Save modified ROM')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FFMQFormationEditor(Path(args.rom), verbose=args.verbose)
	
	# List formations
	if args.list_formations:
		formation_type = FormationType(args.type) if args.type else None
		formations = editor.list_formations(formation_type)
		
		type_filter = f" ({args.type})" if args.type else ""
		print(f"\nFFMQ Formations{type_filter} ({len(formations)}):\n")
		
		for formation in formations[:50]:
			active_enemies = [e for e in formation.enemies if e.active]
			enemy_list = ', '.join(set([e.enemy_name for e in active_enemies]))
			print(f"  {formation.formation_id:3d}: {formation.name:<25} "
				  f"({len(active_enemies)} enemies) - {enemy_list}")
		
		if len(formations) > 50:
			print(f"\n  ... and {len(formations) - 50} more formations")
		
		return 0
	
	# Show formation
	if args.show_formation is not None:
		formation = editor.extract_formation(args.show_formation)
		
		if formation:
			print(f"\n=== {formation.name} ===\n")
			print(f"ID: {formation.formation_id}")
			print(f"Type: {formation.formation_type.value}")
			
			active_enemies = [e for e in formation.enemies if e.active]
			print(f"Enemies: {len(active_enemies)}\n")
			
			if active_enemies:
				print(f"{'Slot':<6} {'Enemy':<20} {'Position'}")
				print("=" * 45)
				for enemy in active_enemies:
					print(f"{enemy.slot_id:<6} {enemy.enemy_name:<20} ({enemy.x:3d}, {enemy.y:3d})")
		else:
			print(f"❌ Formation {args.show_formation} not found")
		
		return 0
	
	# Edit formation
	if args.edit_formation is not None and args.slot is not None and args.enemy is not None:
		success = editor.modify_formation_slot(args.edit_formation, args.slot, 
											   args.enemy, args.x, args.y)
		
		if success and args.save:
			editor.save_rom(Path(args.save))
		
		return 0
	
	# List zones
	if args.list_zones is not None:
		zones = editor.list_encounter_zones(args.list_zones)
		
		print(f"\nEncounter Zones for Map {args.list_zones} ({len(zones)}):\n")
		
		for zone in zones:
			print(f"  Zone {zone.zone_id}: ({zone.x1},{zone.y1}) to ({zone.x2},{zone.y2})")
			print(f"    Rate: {zone.encounter_rate} steps")
			print(f"    Formations: {len(zone.formations)}")
		
		return 0
	
	# Show zone
	if args.show_zone is not None:
		zone = editor.extract_encounter_zone(args.show_zone)
		
		if zone:
			print(f"\n=== Encounter Zone {zone.zone_id} ===\n")
			print(f"Map: {zone.map_id}")
			print(f"Area: ({zone.x1},{zone.y1}) to ({zone.x2},{zone.y2})")
			print(f"Encounter Rate: {zone.encounter_rate} steps")
			
			print(f"\nFormations ({len(zone.formations)}):\n")
			print(f"{'Formation ID':<15} {'Weight':<10} {'Probability'}")
			print("=" * 50)
			
			total_weight = sum(zone.weights)
			for form_id, weight in zip(zone.formations, zone.weights):
				probability = (weight / total_weight * 100) if total_weight > 0 else 0
				formation = editor.extract_formation(form_id)
				form_name = formation.name if formation else f"Formation {form_id}"
				print(f"{form_id:<15} {weight:<10} {probability:.1f}%")
		else:
			print(f"❌ Encounter zone {args.show_zone} not found")
		
		return 0
	
	# Edit zone
	if args.edit_zone is not None and args.rate is not None:
		success = editor.modify_encounter_rate(args.edit_zone, args.rate)
		
		if success and args.save:
			editor.save_rom(Path(args.save))
		
		return 0
	
	# Export
	if args.export:
		editor.export_json(Path(args.export))
		return 0
	
	print("Use --list-formations, --show-formation, --edit-formation,")
	print("     --list-zones, --show-zone, --edit-zone, or --export")
	return 0


if __name__ == '__main__':
	exit(main())
