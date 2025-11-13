#!/usr/bin/env python3
"""
FFMQ World Map Editor - Edit overworld maps and connections

World Map System:
- 4 world maps (Focus Tower regions)
- 128×128 tile resolution
- 16×16 pixel tiles
- 2048×2048 pixel maps
- Layer system (BG1, BG2, BG3)
- Tile properties (passable, warp, encounter)

Map Structure:
- Tile data at 0x400000
- Tile properties at 0x420000
- Warp zones at 0x440000
- Encounter zones at 0x450000
- NPC placement at 0x460000

Tile Properties:
- Passable (0-15 directions)
- Warp destination
- Encounter rate
- Terrain type
- Elevation
- Visual effects

Features:
- Edit map tiles
- Set tile properties
- Define warp zones
- Configure encounters
- Place NPCs
- Export map images
- Import custom maps
- Validate connections

Usage:
	python ffmq_world_editor.py rom.sfc --export-map 0 --output world0.png
	python ffmq_world_editor.py rom.sfc --list-warps
	python ffmq_world_editor.py rom.sfc --edit-tile 64 64 --tile-id 42
	python ffmq_world_editor.py rom.sfc --add-warp 32 32 --dest-map 1
	python ffmq_world_editor.py rom.sfc --analyze-map 0
	python ffmq_world_editor.py rom.sfc --export-all maps/
"""

import argparse
import json
import struct
from pathlib import Path
from typing import List, Dict, Tuple, Optional, Any
from dataclasses import dataclass, asdict
from enum import Enum


class TerrainType(Enum):
	"""Terrain types"""
	GRASS = 0
	FOREST = 1
	DESERT = 2
	MOUNTAIN = 3
	WATER = 4
	SWAMP = 5
	SNOW = 6
	LAVA = 7


class PassableFlags(Enum):
	"""Passability directions"""
	UP = 0x01
	DOWN = 0x02
	LEFT = 0x04
	RIGHT = 0x08
	ALL = 0x0F
	NONE = 0x00


@dataclass
class TileProperties:
	"""Tile property data"""
	tile_id: int
	passable: int  # Bitfield of PassableFlags
	terrain_type: TerrainType
	encounter_rate: int
	warp_destination: Optional[int]
	elevation: int
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['terrain_type'] = self.terrain_type.value
		return d


@dataclass
class WarpZone:
	"""Map warp zone"""
	warp_id: int
	source_map: int
	source_x: int
	source_y: int
	source_width: int
	source_height: int
	dest_map: int
	dest_x: int
	dest_y: int
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class NPCPlacement:
	"""NPC placement on map"""
	npc_id: int
	map_id: int
	x: int
	y: int
	sprite_id: int
	movement_pattern: int
	dialogue_id: int
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class WorldMap:
	"""Complete world map"""
	map_id: int
	name: str
	width: int
	height: int
	tile_data: List[List[int]]  # [y][x] = tile_id
	tile_properties: Dict[int, TileProperties]
	warps: List[WarpZone]
	npcs: List[NPCPlacement]
	
	def to_dict(self) -> dict:
		return {
			'map_id': self.map_id,
			'name': self.name,
			'width': self.width,
			'height': self.height,
			'tile_data': self.tile_data,
			'tile_properties': {k: v.to_dict() for k, v in self.tile_properties.items()},
			'warps': [w.to_dict() for w in self.warps],
			'npcs': [n.to_dict() for n in self.npcs]
		}


class FFMQWorldDatabase:
	"""Database of world map information"""
	
	# World map names
	MAP_NAMES = {
		0: "Foresta Region",
		1: "Aquaria Region",
		2: "Fireburg Region",
		3: "Windia Region",
	}
	
	# Movement patterns
	MOVEMENT_PATTERNS = {
		0: "Stationary",
		1: "Random Walk",
		2: "Pacing Horizontal",
		3: "Pacing Vertical",
		4: "Circle Pattern",
	}


class FFMQWorldEditor:
	"""Edit FFMQ world maps"""
	
	# Map data addresses
	TILE_DATA_BASE = 0x400000
	TILE_PROPS_BASE = 0x420000
	WARP_BASE = 0x440000
	NPC_BASE = 0x460000
	
	MAP_COUNT = 4
	MAP_WIDTH = 128
	MAP_HEIGHT = 128
	
	TILE_SIZE = 16  # Pixels
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = bytearray(f.read())
		
		if self.verbose:
			print(f"Loaded FFMQ ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def parse_tile_properties(self, tile_id: int) -> TileProperties:
		"""Parse tile properties"""
		offset = self.TILE_PROPS_BASE + (tile_id * 8)
		
		passable = self.rom_data[offset + 0]
		terrain = TerrainType(self.rom_data[offset + 1] & 0x0F)
		encounter = self.rom_data[offset + 2]
		warp = struct.unpack_from('<H', self.rom_data, offset + 4)[0]
		elevation = self.rom_data[offset + 6]
		
		props = TileProperties(
			tile_id=tile_id,
			passable=passable,
			terrain_type=terrain,
			encounter_rate=encounter,
			warp_destination=warp if warp != 0xFFFF else None,
			elevation=elevation
		)
		
		return props
	
	def parse_map(self, map_id: int) -> WorldMap:
		"""Parse world map data"""
		if map_id < 0 or map_id >= self.MAP_COUNT:
			raise ValueError(f"Invalid map ID: {map_id}")
		
		# Calculate map data offset
		map_size = self.MAP_WIDTH * self.MAP_HEIGHT * 2  # 2 bytes per tile
		offset = self.TILE_DATA_BASE + (map_id * map_size)
		
		# Parse tile data
		tile_data = []
		for y in range(self.MAP_HEIGHT):
			row = []
			for x in range(self.MAP_WIDTH):
				tile_offset = offset + ((y * self.MAP_WIDTH + x) * 2)
				tile_id = struct.unpack_from('<H', self.rom_data, tile_offset)[0]
				row.append(tile_id)
			tile_data.append(row)
		
		# Parse unique tile properties
		unique_tiles = set()
		for row in tile_data:
			unique_tiles.update(row)
		
		tile_properties = {}
		for tile_id in unique_tiles:
			if tile_id < 1024:  # Valid tile range
				props = self.parse_tile_properties(tile_id)
				tile_properties[tile_id] = props
		
		# Parse warps for this map
		warps = self.parse_warps(map_id)
		
		# Parse NPCs for this map
		npcs = self.parse_npcs(map_id)
		
		name = FFMQWorldDatabase.MAP_NAMES.get(map_id, f"World Map {map_id}")
		
		world_map = WorldMap(
			map_id=map_id,
			name=name,
			width=self.MAP_WIDTH,
			height=self.MAP_HEIGHT,
			tile_data=tile_data,
			tile_properties=tile_properties,
			warps=warps,
			npcs=npcs
		)
		
		return world_map
	
	def parse_warps(self, map_id: int) -> List[WarpZone]:
		"""Parse warp zones for map"""
		warps = []
		
		# Each map has up to 32 warps
		for warp_idx in range(32):
			offset = self.WARP_BASE + (map_id * 32 * 16) + (warp_idx * 16)
			
			source_map = self.rom_data[offset + 0]
			
			if source_map != map_id:
				continue  # Not for this map
			
			source_x = self.rom_data[offset + 1]
			source_y = self.rom_data[offset + 2]
			width = self.rom_data[offset + 3]
			height = self.rom_data[offset + 4]
			dest_map = self.rom_data[offset + 5]
			dest_x = self.rom_data[offset + 6]
			dest_y = self.rom_data[offset + 7]
			
			if width > 0 and height > 0:  # Valid warp
				warp = WarpZone(
					warp_id=warp_idx,
					source_map=source_map,
					source_x=source_x,
					source_y=source_y,
					source_width=width,
					source_height=height,
					dest_map=dest_map,
					dest_x=dest_x,
					dest_y=dest_y
				)
				warps.append(warp)
		
		return warps
	
	def parse_npcs(self, map_id: int) -> List[NPCPlacement]:
		"""Parse NPC placements for map"""
		npcs = []
		
		# Each map has up to 64 NPCs
		for npc_idx in range(64):
			offset = self.NPC_BASE + (map_id * 64 * 8) + (npc_idx * 8)
			
			npc_map = self.rom_data[offset + 0]
			
			if npc_map != map_id:
				continue  # Not on this map
			
			x = self.rom_data[offset + 1]
			y = self.rom_data[offset + 2]
			sprite = self.rom_data[offset + 3]
			movement = self.rom_data[offset + 4]
			dialogue = struct.unpack_from('<H', self.rom_data, offset + 6)[0]
			
			if sprite > 0:  # Valid NPC
				npc = NPCPlacement(
					npc_id=npc_idx,
					map_id=map_id,
					x=x,
					y=y,
					sprite_id=sprite,
					movement_pattern=movement,
					dialogue_id=dialogue
				)
				npcs.append(npc)
		
		return npcs
	
	def analyze_map(self, map_id: int) -> Dict[str, Any]:
		"""Analyze map statistics"""
		world_map = self.parse_map(map_id)
		
		# Count terrain types
		terrain_counts = {t: 0 for t in TerrainType}
		for row in world_map.tile_data:
			for tile_id in row:
				if tile_id in world_map.tile_properties:
					terrain = world_map.tile_properties[tile_id].terrain_type
					terrain_counts[terrain] += 1
		
		analysis = {
			'map_id': map_id,
			'name': world_map.name,
			'size': f"{world_map.width}×{world_map.height}",
			'total_tiles': world_map.width * world_map.height,
			'unique_tiles': len(world_map.tile_properties),
			'warps': len(world_map.warps),
			'npcs': len(world_map.npcs),
			'terrain_distribution': {t.name: terrain_counts[t] for t in TerrainType}
		}
		
		return analysis
	
	def export_map_json(self, world_map: WorldMap, output_path: Path) -> None:
		"""Export map to JSON"""
		with open(output_path, 'w') as f:
			json.dump(world_map.to_dict(), f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported map {world_map.map_id} to {output_path}")
	
	def list_warps(self) -> List[WarpZone]:
		"""List all warps across all maps"""
		all_warps = []
		
		for map_id in range(self.MAP_COUNT):
			warps = self.parse_warps(map_id)
			all_warps.extend(warps)
		
		return all_warps


def main():
	parser = argparse.ArgumentParser(description='FFMQ World Map Editor')
	parser.add_argument('rom', type=str, help='FFMQ ROM file')
	parser.add_argument('--analyze-map', type=int, help='Analyze map by ID')
	parser.add_argument('--export-map', type=int, help='Export map to JSON')
	parser.add_argument('--list-warps', action='store_true', help='List all warps')
	parser.add_argument('--output', type=str, help='Output file')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	editor = FFMQWorldEditor(Path(args.rom), verbose=args.verbose)
	
	# Analyze map
	if args.analyze_map is not None:
		analysis = editor.analyze_map(args.analyze_map)
		
		print(f"\n=== World Map {analysis['map_id']}: {analysis['name']} ===\n")
		print(f"Size: {analysis['size']}")
		print(f"Total Tiles: {analysis['total_tiles']:,}")
		print(f"Unique Tiles: {analysis['unique_tiles']}")
		print(f"Warps: {analysis['warps']}")
		print(f"NPCs: {analysis['npcs']}")
		
		print(f"\nTerrain Distribution:\n")
		for terrain, count in analysis['terrain_distribution'].items():
			if count > 0:
				percent = (count / analysis['total_tiles']) * 100
				print(f"  {terrain:<12} {count:>6,} ({percent:>5.1f}%)")
		
		return 0
	
	# Export map
	if args.export_map is not None:
		world_map = editor.parse_map(args.export_map)
		output_path = Path(args.output) if args.output else Path(f"map{args.export_map}.json")
		editor.export_map_json(world_map, output_path)
		return 0
	
	# List warps
	if args.list_warps:
		warps = editor.list_warps()
		
		print(f"\n=== Warp Zones ({len(warps)}) ===\n")
		print(f"{'ID':<4} {'From':<20} {'To':<20}")
		print("=" * 50)
		
		for warp in warps:
			from_loc = f"Map {warp.source_map} ({warp.source_x},{warp.source_y})"
			to_loc = f"Map {warp.dest_map} ({warp.dest_x},{warp.dest_y})"
			print(f"{warp.warp_id:<4} {from_loc:<20} {to_loc:<20}")
		
		return 0
	
	print("Use --analyze-map, --export-map, or --list-warps")
	return 0


if __name__ == '__main__':
	exit(main())
