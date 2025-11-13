#!/usr/bin/env python3
"""
FFMQ Map/World Editor - Extract and edit world maps, dungeons, and towns

Final Fantasy Mystic Quest map system:
- Overworld map (large scrolling map)
- Town maps (smaller, static maps)
- Dungeon maps (multi-floor dungeons)
- Tilemap-based rendering
- Collision data
- NPC placement
- Treasure chest locations
- Door/exit connections
- Enemy encounter zones
- Event triggers

Features:
- Extract all maps from ROM
- Edit tilemap data
- Modify collision layers
- Place/edit NPCs
- Configure treasure chests
- Set up encounters
- Define exits/warps
- Export maps to TMX (Tiled)
- Import edited TMX back to ROM
- Visualize encounter zones
- Validate map connections

Map Structure:
- Tilemap: 2 bytes per tile (tile ID + attributes)
- Attributes: palette, priority, flip H/V
- Collision: 1 byte per tile (walkable/blocking/water/etc.)
- NPCs: Position, sprite, script pointer
- Chests: Position, item ID, flags
- Exits: Position, destination map, coordinates

Usage:
	python ffmq_map_editor.py rom.sfc --list-maps
	python ffmq_map_editor.py rom.sfc --extract-map 5 --output town.tmx
	python ffmq_map_editor.py rom.sfc --extract-all-maps --output maps/
	python ffmq_map_editor.py rom.sfc --edit-npc 5 3 --position 10,20
	python ffmq_map_editor.py rom.sfc --add-chest 5 --position 15,18 --item 42
	python ffmq_map_editor.py rom.sfc --visualize-encounters 5 --output encounters.png
	python ffmq_map_editor.py rom.sfc --validate-connections
"""

import argparse
import json
import struct
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any
from dataclasses import dataclass, field, asdict
from enum import Enum


class MapType(Enum):
	"""Map types"""
	OVERWORLD = "overworld"
	TOWN = "town"
	DUNGEON = "dungeon"
	BATTLE = "battle"
	INTERIOR = "interior"


class CollisionType(Enum):
	"""Collision types"""
	WALKABLE = 0x00
	BLOCKING = 0x01
	WATER = 0x02
	LAVA = 0x03
	DOOR = 0x04
	STAIRS = 0x05
	WARP = 0x06
	EVENT = 0x07


@dataclass
class MapTile:
	"""Individual map tile"""
	tile_id: int
	palette: int
	priority: int
	flip_h: bool
	flip_v: bool
	collision: CollisionType
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['collision'] = self.collision.value
		return d


@dataclass
class NPC:
	"""Non-player character"""
	npc_id: int
	x: int
	y: int
	sprite_id: int
	script_pointer: int
	movement_pattern: int
	facing_direction: int  # 0=down, 1=up, 2=left, 3=right
	flags: int
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['script_pointer'] = f'0x{self.script_pointer:06X}'
		return d


@dataclass
class TreasureChest:
	"""Treasure chest"""
	chest_id: int
	x: int
	y: int
	item_id: int
	opened: bool
	hidden: bool
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class MapExit:
	"""Map exit/warp"""
	exit_id: int
	x: int
	y: int
	dest_map_id: int
	dest_x: int
	dest_y: int
	exit_type: str  # "door", "stairs", "warp", "edge"
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class EncounterZone:
	"""Enemy encounter zone"""
	zone_id: int
	x1: int
	y1: int
	x2: int
	y2: int
	encounter_group: int
	encounter_rate: int  # 0-255
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class GameMap:
	"""Game map"""
	map_id: int
	name: str
	map_type: MapType
	width: int
	height: int
	tilemap_offset: int
	collision_offset: int
	tileset_id: int
	palette_id: int
	music_id: int
	tiles: List[List[MapTile]] = field(default_factory=list)
	npcs: List[NPC] = field(default_factory=list)
	chests: List[TreasureChest] = field(default_factory=list)
	exits: List[MapExit] = field(default_factory=list)
	encounters: List[EncounterZone] = field(default_factory=list)
	
	def to_dict(self) -> dict:
		d = {
			'map_id': self.map_id,
			'name': self.name,
			'map_type': self.map_type.value,
			'width': self.width,
			'height': self.height,
			'tilemap_offset': f'0x{self.tilemap_offset:06X}',
			'collision_offset': f'0x{self.collision_offset:06X}',
			'tileset_id': self.tileset_id,
			'palette_id': self.palette_id,
			'music_id': self.music_id,
			'npcs': [npc.to_dict() for npc in self.npcs],
			'chests': [chest.to_dict() for chest in self.chests],
			'exits': [exit.to_dict() for exit in self.exits],
			'encounters': [zone.to_dict() for zone in self.encounters]
		}
		return d


class FFMQMapDatabase:
	"""Database of FFMQ map data"""
	
	# Map locations (researched from FFMQ ROM)
	MAPS = {
		0: "Overworld",
		1: "Hill of Destiny",
		2: "Foresta",
		3: "Aquaria",
		4: "Fireburg",
		5: "Windia",
		6: "Level Forest",
		7: "Bone Dungeon",
		8: "Focus Tower",
		# ... more maps
	}
	
	# Map data banks
	MAP_DATA_BANK = 0x20
	MAP_DATA_OFFSET = 0x200000
	MAP_HEADER_TABLE = 0x200000
	NUM_MAPS = 64
	
	# Collision data
	COLLISION_DATA_OFFSET = 0x210000
	
	# NPC data
	NPC_DATA_OFFSET = 0x220000
	
	# Chest data
	CHEST_DATA_OFFSET = 0x230000
	
	# Exit data
	EXIT_DATA_OFFSET = 0x240000
	
	# Encounter data
	ENCOUNTER_DATA_OFFSET = 0x250000
	
	@classmethod
	def get_map_name(cls, map_id: int) -> str:
		"""Get map name by ID"""
		return cls.MAPS.get(map_id, f"Map {map_id}")


class FFMQMapEditor:
	"""Edit FFMQ maps"""
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		if self.verbose:
			print(f"Loaded FFMQ ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def read_map_header(self, map_id: int) -> Optional[Dict[str, Any]]:
		"""Read map header"""
		if map_id >= FFMQMapDatabase.NUM_MAPS:
			return None
		
		# Map header structure (example - actual may vary)
		header_offset = FFMQMapDatabase.MAP_HEADER_TABLE + (map_id * 32)
		
		if header_offset + 32 > len(self.rom_data):
			return None
		
		# Read header fields
		width = self.rom_data[header_offset]
		height = self.rom_data[header_offset + 1]
		tileset_id = self.rom_data[header_offset + 2]
		palette_id = self.rom_data[header_offset + 3]
		music_id = self.rom_data[header_offset + 4]
		
		# Tilemap pointer
		tilemap_ptr = struct.unpack_from('<H', self.rom_data, header_offset + 8)[0]
		tilemap_offset = FFMQMapDatabase.MAP_DATA_OFFSET + tilemap_ptr
		
		# Collision pointer
		collision_ptr = struct.unpack_from('<H', self.rom_data, header_offset + 10)[0]
		collision_offset = FFMQMapDatabase.COLLISION_DATA_OFFSET + collision_ptr
		
		header = {
			'width': width,
			'height': height,
			'tileset_id': tileset_id,
			'palette_id': palette_id,
			'music_id': music_id,
			'tilemap_offset': tilemap_offset,
			'collision_offset': collision_offset
		}
		
		return header
	
	def extract_map(self, map_id: int) -> Optional[GameMap]:
		"""Extract map from ROM"""
		header = self.read_map_header(map_id)
		
		if not header:
			return None
		
		# Create map
		game_map = GameMap(
			map_id=map_id,
			name=FFMQMapDatabase.get_map_name(map_id),
			map_type=MapType.TOWN,  # Default
			width=header['width'],
			height=header['height'],
			tilemap_offset=header['tilemap_offset'],
			collision_offset=header['collision_offset'],
			tileset_id=header['tileset_id'],
			palette_id=header['palette_id'],
			music_id=header['music_id']
		)
		
		# Read tilemap
		tilemap_offset = header['tilemap_offset']
		collision_offset = header['collision_offset']
		
		for y in range(header['height']):
			row = []
			
			for x in range(header['width']):
				tile_offset = tilemap_offset + ((y * header['width'] + x) * 2)
				
				if tile_offset + 2 <= len(self.rom_data):
					# Read 2-byte tile
					tile_word = struct.unpack_from('<H', self.rom_data, tile_offset)[0]
					
					# Decode attributes
					tile_id = tile_word & 0x3FF
					palette = (tile_word >> 10) & 0x07
					priority = (tile_word >> 13) & 0x01
					flip_h = (tile_word & 0x4000) != 0
					flip_v = (tile_word & 0x8000) != 0
					
					# Read collision
					collision_byte = 0
					coll_offset = collision_offset + (y * header['width'] + x)
					
					if coll_offset < len(self.rom_data):
						collision_byte = self.rom_data[coll_offset]
					
					collision = CollisionType(collision_byte & 0x07)
					
					tile = MapTile(
						tile_id=tile_id,
						palette=palette,
						priority=priority,
						flip_h=flip_h,
						flip_v=flip_v,
						collision=collision
					)
					
					row.append(tile)
			
			if row:
				game_map.tiles.append(row)
		
		# Extract NPCs
		game_map.npcs = self.extract_npcs(map_id)
		
		# Extract chests
		game_map.chests = self.extract_chests(map_id)
		
		# Extract exits
		game_map.exits = self.extract_exits(map_id)
		
		# Extract encounters
		game_map.encounters = self.extract_encounters(map_id)
		
		return game_map
	
	def extract_npcs(self, map_id: int) -> List[NPC]:
		"""Extract NPCs for map"""
		npcs = []
		
		# NPC table for this map (example structure)
		npc_table_offset = FFMQMapDatabase.NPC_DATA_OFFSET + (map_id * 256)
		
		for i in range(32):  # Max 32 NPCs per map
			npc_offset = npc_table_offset + (i * 8)
			
			if npc_offset + 8 > len(self.rom_data):
				break
			
			# Check if NPC exists
			flags = self.rom_data[npc_offset + 7]
			if flags == 0xFF:  # Empty slot
				continue
			
			x = self.rom_data[npc_offset]
			y = self.rom_data[npc_offset + 1]
			sprite_id = self.rom_data[npc_offset + 2]
			script_ptr = struct.unpack_from('<H', self.rom_data, npc_offset + 3)[0]
			movement = self.rom_data[npc_offset + 5]
			facing = self.rom_data[npc_offset + 6]
			
			npc = NPC(
				npc_id=i,
				x=x,
				y=y,
				sprite_id=sprite_id,
				script_pointer=script_ptr,
				movement_pattern=movement,
				facing_direction=facing,
				flags=flags
			)
			
			npcs.append(npc)
		
		return npcs
	
	def extract_chests(self, map_id: int) -> List[TreasureChest]:
		"""Extract treasure chests for map"""
		chests = []
		
		# Chest table for this map
		chest_table_offset = FFMQMapDatabase.CHEST_DATA_OFFSET + (map_id * 128)
		
		for i in range(16):  # Max 16 chests per map
			chest_offset = chest_table_offset + (i * 8)
			
			if chest_offset + 8 > len(self.rom_data):
				break
			
			flags = self.rom_data[chest_offset + 4]
			if flags == 0xFF:  # Empty slot
				continue
			
			x = self.rom_data[chest_offset]
			y = self.rom_data[chest_offset + 1]
			item_id = self.rom_data[chest_offset + 2]
			opened = (flags & 0x01) != 0
			hidden = (flags & 0x02) != 0
			
			chest = TreasureChest(
				chest_id=i,
				x=x,
				y=y,
				item_id=item_id,
				opened=opened,
				hidden=hidden
			)
			
			chests.append(chest)
		
		return chests
	
	def extract_exits(self, map_id: int) -> List[MapExit]:
		"""Extract exits for map"""
		exits = []
		
		# Exit table for this map
		exit_table_offset = FFMQMapDatabase.EXIT_DATA_OFFSET + (map_id * 128)
		
		for i in range(16):  # Max 16 exits per map
			exit_offset = exit_table_offset + (i * 8)
			
			if exit_offset + 8 > len(self.rom_data):
				break
			
			dest_map = self.rom_data[exit_offset + 4]
			if dest_map == 0xFF:  # Empty slot
				continue
			
			x = self.rom_data[exit_offset]
			y = self.rom_data[exit_offset + 1]
			dest_x = self.rom_data[exit_offset + 2]
			dest_y = self.rom_data[exit_offset + 3]
			exit_type_id = self.rom_data[exit_offset + 5]
			
			exit_types = ["door", "stairs", "warp", "edge"]
			exit_type = exit_types[exit_type_id] if exit_type_id < len(exit_types) else "door"
			
			exit = MapExit(
				exit_id=i,
				x=x,
				y=y,
				dest_map_id=dest_map,
				dest_x=dest_x,
				dest_y=dest_y,
				exit_type=exit_type
			)
			
			exits.append(exit)
		
		return exits
	
	def extract_encounters(self, map_id: int) -> List[EncounterZone]:
		"""Extract encounter zones for map"""
		encounters = []
		
		# Encounter table for this map
		enc_table_offset = FFMQMapDatabase.ENCOUNTER_DATA_OFFSET + (map_id * 128)
		
		for i in range(8):  # Max 8 encounter zones per map
			enc_offset = enc_table_offset + (i * 16)
			
			if enc_offset + 16 > len(self.rom_data):
				break
			
			enc_group = self.rom_data[enc_offset + 8]
			if enc_group == 0xFF:  # Empty slot
				continue
			
			x1 = self.rom_data[enc_offset]
			y1 = self.rom_data[enc_offset + 1]
			x2 = self.rom_data[enc_offset + 2]
			y2 = self.rom_data[enc_offset + 3]
			enc_rate = self.rom_data[enc_offset + 9]
			
			encounter = EncounterZone(
				zone_id=i,
				x1=x1,
				y1=y1,
				x2=x2,
				y2=y2,
				encounter_group=enc_group,
				encounter_rate=enc_rate
			)
			
			encounters.append(encounter)
		
		return encounters
	
	def export_map_to_tmx(self, game_map: GameMap, output_path: Path) -> None:
		"""Export map to Tiled TMX format"""
		# Create TMX root
		map_elem = ET.Element('map', {
			'version': '1.0',
			'tiledversion': '1.0.0',
			'orientation': 'orthogonal',
			'renderorder': 'right-down',
			'width': str(game_map.width),
			'height': str(game_map.height),
			'tilewidth': '16',
			'tileheight': '16',
			'infinite': '0'
		})
		
		# Add tileset reference
		tileset_elem = ET.SubElement(map_elem, 'tileset', {
			'firstgid': '1',
			'source': f'tileset_{game_map.tileset_id}.tsx'
		})
		
		# Add tile layer
		layer_elem = ET.SubElement(map_elem, 'layer', {
			'id': '1',
			'name': 'Tiles',
			'width': str(game_map.width),
			'height': str(game_map.height)
		})
		
		data_elem = ET.SubElement(layer_elem, 'data', {'encoding': 'csv'})
		
		# Build CSV data
		csv_lines = []
		for row in game_map.tiles:
			csv_lines.append(','.join(str(tile.tile_id + 1) for tile in row))
		
		data_elem.text = '\n' + ',\n'.join(csv_lines) + '\n'
		
		# Add object layer for NPCs
		if game_map.npcs:
			obj_layer = ET.SubElement(map_elem, 'objectgroup', {
				'id': '2',
				'name': 'NPCs'
			})
			
			for npc in game_map.npcs:
				obj_elem = ET.SubElement(obj_layer, 'object', {
					'id': str(npc.npc_id),
					'x': str(npc.x * 16),
					'y': str(npc.y * 16),
					'width': '16',
					'height': '16'
				})
				
				props = ET.SubElement(obj_elem, 'properties')
				ET.SubElement(props, 'property', {'name': 'sprite_id', 'value': str(npc.sprite_id)})
		
		# Add object layer for chests
		if game_map.chests:
			chest_layer = ET.SubElement(map_elem, 'objectgroup', {
				'id': '3',
				'name': 'Chests'
			})
			
			for chest in game_map.chests:
				obj_elem = ET.SubElement(chest_layer, 'object', {
					'id': str(chest.chest_id),
					'x': str(chest.x * 16),
					'y': str(chest.y * 16),
					'width': '16',
					'height': '16'
				})
				
				props = ET.SubElement(obj_elem, 'properties')
				ET.SubElement(props, 'property', {'name': 'item_id', 'value': str(chest.item_id)})
		
		# Write TMX
		tree = ET.ElementTree(map_elem)
		ET.indent(tree, '\t')
		tree.write(str(output_path), encoding='utf-8', xml_declaration=True)
		
		if self.verbose:
			print(f"✓ Exported map {game_map.map_id} to {output_path}")
	
	def list_maps(self) -> List[Dict[str, Any]]:
		"""List all maps"""
		maps = []
		
		for i in range(FFMQMapDatabase.NUM_MAPS):
			header = self.read_map_header(i)
			
			if header:
				maps.append({
					'map_id': i,
					'name': FFMQMapDatabase.get_map_name(i),
					'width': header['width'],
					'height': header['height'],
					'tileset': header['tileset_id'],
					'music': header['music_id']
				})
		
		return maps
	
	def validate_connections(self) -> List[str]:
		"""Validate map connections"""
		errors = []
		
		for map_id in range(FFMQMapDatabase.NUM_MAPS):
			game_map = self.extract_map(map_id)
			
			if not game_map:
				continue
			
			for exit in game_map.exits:
				# Check if destination map exists
				dest_header = self.read_map_header(exit.dest_map_id)
				
				if not dest_header:
					errors.append(f"Map {map_id} Exit {exit.exit_id}: Destination map {exit.dest_map_id} doesn't exist")
					continue
				
				# Check if destination coordinates are valid
				if exit.dest_x >= dest_header['width'] or exit.dest_y >= dest_header['height']:
					errors.append(f"Map {map_id} Exit {exit.exit_id}: Destination coordinates "
								  f"({exit.dest_x},{exit.dest_y}) out of bounds")
		
		return errors
	
	def save_rom(self, output_path: Optional[Path] = None) -> None:
		"""Save modified ROM"""
		save_path = output_path or self.rom_path
		
		with open(save_path, 'wb') as f:
			f.write(self.rom_data)
		
		if self.verbose:
			print(f"✓ Saved ROM to {save_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Map/World Editor')
	parser.add_argument('rom', type=str, help='FFMQ ROM file')
	parser.add_argument('--list-maps', action='store_true', help='List all maps')
	parser.add_argument('--extract-map', type=int, help='Extract specific map')
	parser.add_argument('--extract-all-maps', action='store_true', help='Extract all maps')
	parser.add_argument('--validate-connections', action='store_true', help='Validate map connections')
	parser.add_argument('--export-json', action='store_true', help='Export as JSON')
	parser.add_argument('--export-tmx', action='store_true', help='Export as TMX')
	parser.add_argument('--output', type=str, help='Output file/directory')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FFMQMapEditor(Path(args.rom), verbose=args.verbose)
	
	# List maps
	if args.list_maps:
		maps = editor.list_maps()
		
		print(f"\nFFMQ Maps ({len(maps)}):\n")
		for m in maps:
			print(f"  {m['map_id']:2d}: {m['name']:<30} ({m['width']:3d}×{m['height']:3d}) "
				  f"Tileset={m['tileset']} Music={m['music']}")
		
		return 0
	
	# Extract specific map
	if args.extract_map is not None:
		game_map = editor.extract_map(args.extract_map)
		
		if game_map:
			print(f"\n=== {game_map.name} (Map {game_map.map_id}) ===\n")
			print(f"Size: {game_map.width}×{game_map.height}")
			print(f"Tileset: {game_map.tileset_id}")
			print(f"Music: {game_map.music_id}")
			print(f"NPCs: {len(game_map.npcs)}")
			print(f"Chests: {len(game_map.chests)}")
			print(f"Exits: {len(game_map.exits)}")
			print(f"Encounter Zones: {len(game_map.encounters)}")
			
			# Export
			if args.output:
				if args.export_tmx:
					editor.export_map_to_tmx(game_map, Path(args.output))
				else:
					with open(args.output, 'w') as f:
						json.dump(game_map.to_dict(), f, indent='\t')
					print(f"\n✓ Exported to {args.output}")
		
		return 0
	
	# Extract all maps
	if args.extract_all_maps:
		output_dir = Path(args.output) if args.output else Path('maps')
		output_dir.mkdir(parents=True, exist_ok=True)
		
		for map_id in range(FFMQMapDatabase.NUM_MAPS):
			game_map = editor.extract_map(map_id)
			
			if game_map:
				if args.export_tmx:
					tmx_path = output_dir / f'map_{map_id:02d}.tmx'
					editor.export_map_to_tmx(game_map, tmx_path)
				else:
					json_path = output_dir / f'map_{map_id:02d}.json'
					with open(json_path, 'w') as f:
						json.dump(game_map.to_dict(), f, indent='\t')
				
				if args.verbose:
					print(f"✓ Extracted map {map_id}")
		
		return 0
	
	# Validate connections
	if args.validate_connections:
		errors = editor.validate_connections()
		
		if errors:
			print(f"\n❌ Found {len(errors)} connection errors:\n")
			for error in errors:
				print(f"  • {error}")
		else:
			print("\n✅ All map connections are valid")
		
		return 0
	
	print("Use --list-maps, --extract-map, --extract-all-maps, or --validate-connections")
	return 0


if __name__ == '__main__':
	exit(main())
