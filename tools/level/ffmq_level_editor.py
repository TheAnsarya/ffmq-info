#!/usr/bin/env python3
"""
FFMQ Level Editor - Map and tile editing

Level Features:
- Map data editing
- Tile placement
- Tileset management
- Collision editing
- Event triggers
- NPC placement

Map Structure:
- Map size (width × height)
- Tile layers (background, foreground)
- Collision layer
- Event layer
- NPC layer

Tile Types:
- Floor tiles
- Wall tiles
- Water tiles
- Special tiles
- Animated tiles

Features:
- Load/save map data
- Edit tiles
- Set collision
- Place events
- Place NPCs
- Export to ROM

Usage:
	python ffmq_level_editor.py --map 1 --view
	python ffmq_level_editor.py --map 1 --set-tile 5 10 42
	python ffmq_level_editor.py --map 1 --export map01.bin
	python ffmq_level_editor.py --create "Test Map" --size 32 32
	python ffmq_level_editor.py --map 1 --add-npc "Benjamin" 10 15
"""

import argparse
import json
import struct
from pathlib import Path
from typing import List, Dict, Optional, Tuple
from dataclasses import dataclass, asdict, field
from enum import Enum


class TileType(Enum):
	"""Tile type"""
	FLOOR = "floor"
	WALL = "wall"
	WATER = "water"
	DOOR = "door"
	STAIRS = "stairs"
	CHEST = "chest"
	SPECIAL = "special"


class CollisionType(Enum):
	"""Collision type"""
	NONE = 0
	SOLID = 1
	WATER = 2
	SPECIAL = 3


class EventType(Enum):
	"""Event trigger type"""
	NONE = "none"
	DIALOG = "dialog"
	BATTLE = "battle"
	TREASURE = "treasure"
	SWITCH = "switch"
	TELEPORT = "teleport"
	SCRIPT = "script"


@dataclass
class Tile:
	"""Map tile"""
	tile_id: int
	tile_type: TileType = TileType.FLOOR
	collision: CollisionType = CollisionType.NONE
	animated: bool = False
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['tile_type'] = self.tile_type.value
		d['collision'] = self.collision.value
		return d


@dataclass
class EventTrigger:
	"""Event trigger at position"""
	x: int
	y: int
	event_type: EventType
	event_id: int
	parameters: Dict[str, any] = field(default_factory=dict)
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['event_type'] = self.event_type.value
		return d


@dataclass
class NPC:
	"""Non-player character"""
	npc_id: int
	name: str
	x: int
	y: int
	sprite_id: int = 0
	dialog_id: int = 0
	movement_type: str = "stationary"


@dataclass
class MapLayer:
	"""Map tile layer"""
	width: int
	height: int
	tiles: List[List[Tile]]
	
	@classmethod
	def create_empty(cls, width: int, height: int) -> 'MapLayer':
		"""Create empty layer"""
		tiles = [[Tile(tile_id=0) for _ in range(width)] for _ in range(height)]
		return cls(width=width, height=height, tiles=tiles)


@dataclass
class MapData:
	"""Complete map data"""
	map_id: int
	name: str
	width: int
	height: int
	background_layer: MapLayer
	foreground_layer: Optional[MapLayer] = None
	events: List[EventTrigger] = field(default_factory=list)
	npcs: List[NPC] = field(default_factory=list)
	tileset_id: int = 0
	music_id: int = 0


class FFMQLevelEditor:
	"""Level and map editor"""
	
	# Map ROM addresses (example)
	MAP_DATA_BASE = 0x100000
	MAP_SIZE = 0x1000  # Size per map
	
	# Default tilesets
	TILESETS = {
		0: "Foresta Village",
		1: "Hill of Destiny",
		2: "Aquaria",
		3: "Fireburg",
		4: "Dungeon",
		5: "Cave",
		6: "Tower"
	}
	
	# Tile definitions
	TILES = {
		0: ("Empty", TileType.FLOOR, CollisionType.NONE),
		1: ("Grass", TileType.FLOOR, CollisionType.NONE),
		2: ("Dirt", TileType.FLOOR, CollisionType.NONE),
		3: ("Stone", TileType.FLOOR, CollisionType.NONE),
		10: ("Tree", TileType.WALL, CollisionType.SOLID),
		11: ("Rock", TileType.WALL, CollisionType.SOLID),
		12: ("Wall", TileType.WALL, CollisionType.SOLID),
		20: ("Water", TileType.WATER, CollisionType.WATER),
		21: ("Lava", TileType.WATER, CollisionType.WATER),
		30: ("Door", TileType.DOOR, CollisionType.SPECIAL),
		31: ("Stairs Up", TileType.STAIRS, CollisionType.SPECIAL),
		32: ("Stairs Down", TileType.STAIRS, CollisionType.SPECIAL),
		40: ("Chest", TileType.CHEST, CollisionType.SPECIAL),
	}
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.maps: Dict[int, MapData] = {}
		self._create_sample_maps()
	
	def _create_sample_maps(self) -> None:
		"""Create sample maps for testing"""
		# Map 1: Simple village
		bg_layer = MapLayer.create_empty(32, 32)
		
		# Fill with grass
		for y in range(32):
			for x in range(32):
				bg_layer.tiles[y][x] = Tile(tile_id=1, tile_type=TileType.FLOOR)
		
		# Add some walls
		for x in range(32):
			bg_layer.tiles[0][x] = Tile(tile_id=10, tile_type=TileType.WALL, 
										collision=CollisionType.SOLID)
			bg_layer.tiles[31][x] = Tile(tile_id=10, tile_type=TileType.WALL,
										 collision=CollisionType.SOLID)
		
		for y in range(32):
			bg_layer.tiles[y][0] = Tile(tile_id=10, tile_type=TileType.WALL,
									   collision=CollisionType.SOLID)
			bg_layer.tiles[y][31] = Tile(tile_id=10, tile_type=TileType.WALL,
										collision=CollisionType.SOLID)
		
		# Add water
		for y in range(8, 12):
			for x in range(10, 22):
				bg_layer.tiles[y][x] = Tile(tile_id=20, tile_type=TileType.WATER,
										   collision=CollisionType.WATER)
		
		# Create map
		map1 = MapData(
			map_id=1,
			name="Foresta Village",
			width=32,
			height=32,
			background_layer=bg_layer,
			tileset_id=0,
			music_id=1
		)
		
		# Add NPCs
		map1.npcs.append(NPC(npc_id=1, name="Old Man", x=16, y=16, sprite_id=1, dialog_id=1))
		map1.npcs.append(NPC(npc_id=2, name="Merchant", x=20, y=18, sprite_id=2, dialog_id=2))
		
		# Add events
		map1.events.append(EventTrigger(
			x=15, y=15,
			event_type=EventType.DIALOG,
			event_id=1,
			parameters={'text': 'Welcome to Foresta!'}
		))
		
		map1.events.append(EventTrigger(
			x=25, y=25,
			event_type=EventType.TREASURE,
			event_id=1,
			parameters={'item_id': 1, 'quantity': 1}
		))
		
		self.maps[1] = map1
	
	def create_map(self, map_id: int, name: str, width: int, height: int,
				   tileset_id: int = 0) -> MapData:
		"""Create new map"""
		bg_layer = MapLayer.create_empty(width, height)
		
		map_data = MapData(
			map_id=map_id,
			name=name,
			width=width,
			height=height,
			background_layer=bg_layer,
			tileset_id=tileset_id
		)
		
		self.maps[map_id] = map_data
		
		if self.verbose:
			print(f"✓ Created map {map_id}: {name} ({width}×{height})")
		
		return map_data
	
	def get_map(self, map_id: int) -> Optional[MapData]:
		"""Get map by ID"""
		return self.maps.get(map_id)
	
	def set_tile(self, map_id: int, x: int, y: int, tile_id: int,
				 layer: str = "background") -> bool:
		"""Set tile at position"""
		map_data = self.get_map(map_id)
		
		if not map_data:
			print(f"Error: Map {map_id} not found")
			return False
		
		# Get layer
		if layer == "background":
			target_layer = map_data.background_layer
		elif layer == "foreground" and map_data.foreground_layer:
			target_layer = map_data.foreground_layer
		else:
			print(f"Error: Invalid layer: {layer}")
			return False
		
		# Check bounds
		if not (0 <= x < target_layer.width and 0 <= y < target_layer.height):
			print(f"Error: Position ({x}, {y}) out of bounds")
			return False
		
		# Get tile info
		if tile_id in self.TILES:
			name, tile_type, collision = self.TILES[tile_id]
			tile = Tile(tile_id=tile_id, tile_type=tile_type, collision=collision)
		else:
			tile = Tile(tile_id=tile_id)
		
		target_layer.tiles[y][x] = tile
		
		if self.verbose:
			print(f"✓ Set tile at ({x}, {y}) to {tile_id}")
		
		return True
	
	def get_tile(self, map_id: int, x: int, y: int,
				 layer: str = "background") -> Optional[Tile]:
		"""Get tile at position"""
		map_data = self.get_map(map_id)
		
		if not map_data:
			return None
		
		if layer == "background":
			target_layer = map_data.background_layer
		elif layer == "foreground" and map_data.foreground_layer:
			target_layer = map_data.foreground_layer
		else:
			return None
		
		if not (0 <= x < target_layer.width and 0 <= y < target_layer.height):
			return None
		
		return target_layer.tiles[y][x]
	
	def fill_rect(self, map_id: int, x1: int, y1: int, x2: int, y2: int,
				  tile_id: int, layer: str = "background") -> bool:
		"""Fill rectangle with tile"""
		for y in range(y1, y2 + 1):
			for x in range(x1, x2 + 1):
				if not self.set_tile(map_id, x, y, tile_id, layer):
					return False
		
		if self.verbose:
			print(f"✓ Filled rectangle ({x1},{y1}) to ({x2},{y2}) with tile {tile_id}")
		
		return True
	
	def add_event(self, map_id: int, x: int, y: int, event_type: EventType,
				  event_id: int, **parameters) -> bool:
		"""Add event trigger"""
		map_data = self.get_map(map_id)
		
		if not map_data:
			return False
		
		event = EventTrigger(
			x=x, y=y,
			event_type=event_type,
			event_id=event_id,
			parameters=parameters
		)
		
		map_data.events.append(event)
		
		if self.verbose:
			print(f"✓ Added {event_type.value} event at ({x}, {y})")
		
		return True
	
	def add_npc(self, map_id: int, npc_id: int, name: str, x: int, y: int,
				sprite_id: int = 0, dialog_id: int = 0) -> bool:
		"""Add NPC"""
		map_data = self.get_map(map_id)
		
		if not map_data:
			return False
		
		npc = NPC(
			npc_id=npc_id,
			name=name,
			x=x, y=y,
			sprite_id=sprite_id,
			dialog_id=dialog_id
		)
		
		map_data.npcs.append(npc)
		
		if self.verbose:
			print(f"✓ Added NPC '{name}' at ({x}, {y})")
		
		return True
	
	def export_binary(self, map_id: int, output_path: Path) -> bool:
		"""Export map to binary format"""
		map_data = self.get_map(map_id)
		
		if not map_data:
			return False
		
		with open(output_path, 'wb') as f:
			# Header
			f.write(struct.pack('<H', map_data.map_id))
			f.write(struct.pack('<H', map_data.width))
			f.write(struct.pack('<H', map_data.height))
			f.write(struct.pack('<H', map_data.tileset_id))
			f.write(struct.pack('<H', map_data.music_id))
			
			# Background layer
			for y in range(map_data.height):
				for x in range(map_data.width):
					tile = map_data.background_layer.tiles[y][x]
					f.write(struct.pack('<H', tile.tile_id))
			
			# Collision data
			for y in range(map_data.height):
				for x in range(map_data.width):
					tile = map_data.background_layer.tiles[y][x]
					f.write(struct.pack('<B', tile.collision.value))
			
			# Event count and data
			f.write(struct.pack('<H', len(map_data.events)))
			for event in map_data.events:
				f.write(struct.pack('<H', event.x))
				f.write(struct.pack('<H', event.y))
				f.write(struct.pack('<H', event.event_id))
			
			# NPC count and data
			f.write(struct.pack('<H', len(map_data.npcs)))
			for npc in map_data.npcs:
				f.write(struct.pack('<H', npc.npc_id))
				f.write(struct.pack('<H', npc.x))
				f.write(struct.pack('<H', npc.y))
				f.write(struct.pack('<H', npc.sprite_id))
		
		if self.verbose:
			print(f"✓ Exported map {map_id} to {output_path}")
		
		return True
	
	def export_json(self, map_id: int, output_path: Path) -> bool:
		"""Export map to JSON"""
		map_data = self.get_map(map_id)
		
		if not map_data:
			return False
		
		data = {
			'map_id': map_data.map_id,
			'name': map_data.name,
			'width': map_data.width,
			'height': map_data.height,
			'tileset_id': map_data.tileset_id,
			'music_id': map_data.music_id,
			'tiles': [[tile.to_dict() for tile in row] 
					 for row in map_data.background_layer.tiles],
			'events': [event.to_dict() for event in map_data.events],
			'npcs': [asdict(npc) for npc in map_data.npcs]
		}
		
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported map {map_id} to {output_path}")
		
		return True
	
	def view_map_ascii(self, map_id: int) -> str:
		"""Render map as ASCII"""
		map_data = self.get_map(map_id)
		
		if not map_data:
			return "Map not found"
		
		# Tile characters
		tile_chars = {
			TileType.FLOOR: '.',
			TileType.WALL: '#',
			TileType.WATER: '~',
			TileType.DOOR: 'D',
			TileType.STAIRS: 'S',
			TileType.CHEST: 'C',
			TileType.SPECIAL: '*'
		}
		
		lines = []
		lines.append(f"Map {map_id}: {map_data.name}")
		lines.append(f"Size: {map_data.width}×{map_data.height}")
		lines.append(f"Tileset: {self.TILESETS.get(map_data.tileset_id, 'Unknown')}")
		lines.append('')
		
		# Render tiles
		for y in range(map_data.height):
			row = []
			for x in range(map_data.width):
				tile = map_data.background_layer.tiles[y][x]
				
				# Check for NPC
				npc_here = any(npc.x == x and npc.y == y for npc in map_data.npcs)
				if npc_here:
					row.append('@')
					continue
				
				# Check for event
				event_here = any(e.x == x and e.y == y for e in map_data.events)
				if event_here:
					row.append('!')
					continue
				
				# Regular tile
				char = tile_chars.get(tile.tile_type, '?')
				row.append(char)
			
			lines.append(''.join(row))
		
		lines.append('')
		lines.append(f"NPCs: {len(map_data.npcs)}")
		for npc in map_data.npcs:
			lines.append(f"  {npc.name} @ ({npc.x}, {npc.y})")
		
		lines.append(f"\nEvents: {len(map_data.events)}")
		for event in map_data.events:
			lines.append(f"  {event.event_type.value} @ ({event.x}, {event.y})")
		
		return '\n'.join(lines)


def main():
	parser = argparse.ArgumentParser(description='FFMQ Level Editor')
	parser.add_argument('--map', type=int, help='Map ID')
	parser.add_argument('--create', type=str, help='Create new map with name')
	parser.add_argument('--size', type=int, nargs=2, metavar=('WIDTH', 'HEIGHT'),
					   help='Map size for new map')
	parser.add_argument('--view', action='store_true', help='View map')
	parser.add_argument('--set-tile', type=int, nargs=3, 
					   metavar=('X', 'Y', 'TILE_ID'), help='Set tile')
	parser.add_argument('--fill', type=int, nargs=5,
					   metavar=('X1', 'Y1', 'X2', 'Y2', 'TILE_ID'),
					   help='Fill rectangle')
	parser.add_argument('--add-npc', type=str, nargs=3,
					   metavar=('NAME', 'X', 'Y'), help='Add NPC')
	parser.add_argument('--export', type=str, help='Export to file')
	parser.add_argument('--format', type=str, choices=['binary', 'json'],
					   default='json', help='Export format')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FFMQLevelEditor(verbose=args.verbose)
	
	# Create map
	if args.create and args.size:
		map_id = args.map or 99
		editor.create_map(map_id, args.create, args.size[0], args.size[1])
	
	# Set tile
	if args.map and args.set_tile:
		x, y, tile_id = args.set_tile
		editor.set_tile(args.map, x, y, tile_id)
	
	# Fill rectangle
	if args.map and args.fill:
		x1, y1, x2, y2, tile_id = args.fill
		editor.fill_rect(args.map, x1, y1, x2, y2, tile_id)
	
	# Add NPC
	if args.map and args.add_npc:
		name, x, y = args.add_npc
		npc_id = len(editor.get_map(args.map).npcs) + 1
		editor.add_npc(args.map, npc_id, name, int(x), int(y))
	
	# Export
	if args.map and args.export:
		if args.format == 'binary':
			editor.export_binary(args.map, Path(args.export))
		else:
			editor.export_json(args.map, Path(args.export))
	
	# View
	if args.map and (args.view or not any([args.set_tile, args.fill, args.add_npc, args.export])):
		print(editor.view_map_ascii(args.map))
		return 0
	
	# Default: show available maps
	if not args.map and not args.create:
		print("\n=== FFMQ Level Editor ===\n")
		print(f"Available maps: {len(editor.maps)}\n")
		
		for map_id, map_data in editor.maps.items():
			print(f"Map {map_id}: {map_data.name} ({map_data.width}×{map_data.height})")
		
		print("\nUse --map <id> --view to view a map")
	
	return 0


if __name__ == '__main__':
	exit(main())
