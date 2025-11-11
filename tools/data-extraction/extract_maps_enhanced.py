#!/usr/bin/env python3
"""
Enhanced Map Extraction Tool for Final Fantasy Mystic Quest
Extracts map data with TMX export for Tiled Map Editor

Features:
- Map tile data extraction
- Tileset integration
- Layer support (terrain, objects, events)
- Collision data
- Event triggers (NPCs, chests, doors, exits)
- Map metadata (music, palette, encounters)
- TMX format export for Tiled editor
- JSON export for custom tools

Author: FFMQ Modding Project
Date: November 2, 2025
"""

import os
import sys
import json
import struct
from dataclasses import dataclass, asdict
from typing import List, Dict, Optional, Tuple
from pathlib import Path
import xml.etree.ElementTree as ET
from xml.dom import minidom

@dataclass
class MapMetadata:
	"""Map metadata structure"""
	map_id: int
	name: str
	width: int
	height: int
	tileset_id: int
	palette_id: int
	music_id: int
	encounter_group: int
	base_address: int

@dataclass
class EventTrigger:
	"""Event trigger structure"""
	x: int
	y: int
	event_type: str  # 'npc', 'chest', 'door', 'exit', 'trigger'
	event_id: int
	properties: Dict[str, any]

@dataclass
class MapLayer:
	"""Map layer data"""
	name: str
	width: int
	height: int
	data: List[int]  # Tile IDs
	visible: bool = True
	opacity: float = 1.0

class FFMQMapExtractor:
	"""Enhanced map extractor for FFMQ with Tiled TMX export"""

	# SNES ROM addresses for map data
	MAP_HEADER_BASE = 0x0E8000  # Map headers start
	MAP_DATA_BASE = 0x0F0000    # Map tile data start
	MAP_EVENT_BASE = 0x0F8000   # Event data start

	# Map definitions (ID, Name, Size, Addresses)
	MAPS = [
		# Starting area
		{'id': 0x00, 'name': 'Hill of Destiny', 'width': 32, 'height': 32, 'tileset': 0},
		{'id': 0x01, 'name': 'Foresta', 'width': 32, 'height': 32, 'tileset': 1},
		{'id': 0x02, 'name': 'Foresta House 1', 'width': 16, 'height': 16, 'tileset': 3},
		{'id': 0x03, 'name': 'Foresta House 2', 'width': 16, 'height': 16, 'tileset': 3},

		# Libra region
		{'id': 0x04, 'name': 'Libra Temple', 'width': 32, 'height': 32, 'tileset': 2},
		{'id': 0x05, 'name': 'Sand Temple', 'width': 32, 'height': 32, 'tileset': 2},
		{'id': 0x06, 'name': 'Bone Dungeon', 'width': 32, 'height': 32, 'tileset': 2},

		# Aquaria region
		{'id': 0x07, 'name': 'Aquaria', 'width': 32, 'height': 32, 'tileset': 1},
		{'id': 0x08, 'name': 'Wintry Cave', 'width': 32, 'height': 32, 'tileset': 2},
		{'id': 0x09, 'name': 'Life Temple', 'width': 32, 'height': 32, 'tileset': 2},

		# Fireburg region
		{'id': 0x0A, 'name': 'Fireburg', 'width': 32, 'height': 32, 'tileset': 1},
		{'id': 0x0B, 'name': 'Mine', 'width': 32, 'height': 32, 'tileset': 2},
		{'id': 0x0C, 'name': 'Sealed Temple', 'width': 32, 'height': 32, 'tileset': 2},

		# Spencer region
		{'id': 0x0D, 'name': 'Spencer Cave', 'width': 32, 'height': 32, 'tileset': 2},
		{'id': 0x0E, 'name': 'Windia', 'width': 32, 'height': 32, 'tileset': 1},
		{'id': 0x0F, 'name': 'Pazuzu Tower', 'width': 32, 'height': 32, 'tileset': 2},

		# Focus Tower
		{'id': 0x10, 'name': 'Focus Tower B1', 'width': 32, 'height': 32, 'tileset': 2},
		{'id': 0x11, 'name': 'Focus Tower B2', 'width': 32, 'height': 32, 'tileset': 2},
		{'id': 0x12, 'name': 'Focus Tower B3', 'width': 32, 'height': 32, 'tileset': 2},
		{'id': 0x13, 'name': 'Focus Tower B4', 'width': 32, 'height': 32, 'tileset': 2},
	]

	# Event type definitions
	EVENT_TYPES = {
		0x00: 'none',
		0x01: 'npc',
		0x02: 'chest',
		0x03: 'door',
		0x04: 'exit',
		0x05: 'trigger',
		0x06: 'enemy',
		0x07: 'switch',
	}

	# Collision flags
	COLLISION_NONE = 0x00
	COLLISION_SOLID = 0x01
	COLLISION_WATER = 0x02
	COLLISION_DAMAGE = 0x04

	def __init__(self, rom_path: str):
		"""Initialize map extractor"""
		self.rom_path = rom_path
		self.rom_data = None
		self.has_header = False

	def load_rom(self) -> bool:
		"""Load ROM file"""
		try:
			with open(self.rom_path, 'rb') as f:
				self.rom_data = bytearray(f.read())

			# Check for SMC header
			rom_size = len(self.rom_data)
			if rom_size % 1024 == 512:
				self.has_header = True
				print("Detected 512-byte SMC header")

			return True

		except Exception as e:
			print(f"Error loading ROM: {e}")
			return False

	def snes_to_pc(self, address: int) -> int:
		"""Convert SNES address to PC file offset"""
		# Handle LoROM mapping
		if address >= 0x800000:
			address -= 0x800000

		bank = (address >> 16) & 0xFF
		offset = address & 0xFFFF

		if offset >= 0x8000:
			pc_addr = (bank * 0x8000) + (offset - 0x8000)
		else:
			pc_addr = address

		# Add header offset if present
		if self.has_header:
			pc_addr += 0x200

		return pc_addr

	def read_byte(self, address: int) -> int:
		"""Read byte from SNES address"""
		pc_addr = self.snes_to_pc(address)
		if 0 <= pc_addr < len(self.rom_data):
			return self.rom_data[pc_addr]
		return 0

	def read_word(self, address: int) -> int:
		"""Read 16-bit word from SNES address (little-endian)"""
		return self.read_byte(address) | (self.read_byte(address + 1) << 8)

	def extract_map_header(self, map_id: int) -> Optional[MapMetadata]:
		"""Extract map header/metadata"""
		if map_id >= len(self.MAPS):
			return None

		map_info = self.MAPS[map_id]
		header_addr = self.MAP_HEADER_BASE + (map_id * 16)

		# Read header data (16 bytes per map)
		tileset_id = self.read_byte(header_addr + 0)
		palette_id = self.read_byte(header_addr + 1)
		music_id = self.read_byte(header_addr + 2)
		encounter_group = self.read_byte(header_addr + 3)
		# Bytes 4-15 contain various flags and properties

		metadata = MapMetadata(
			map_id=map_id,
			name=map_info['name'],
			width=map_info['width'],
			height=map_info['height'],
			tileset_id=tileset_id,
			palette_id=palette_id,
			music_id=music_id,
			encounter_group=encounter_group,
			base_address=header_addr
		)

		return metadata

	def extract_map_layer(self, map_id: int, layer_name: str = "Terrain") -> Optional[MapLayer]:
		"""Extract map tile layer data"""
		if map_id >= len(self.MAPS):
			return None

		map_info = self.MAPS[map_id]
		width = map_info['width']
		height = map_info['height']

		# Calculate map data address (simplified - actual addressing is complex)
		data_addr = self.MAP_DATA_BASE + (map_id * width * height * 2)

		# Read tile data
		tiles = []
		for y in range(height):
			for x in range(width):
				# Each tile is 2 bytes in SNES format
				tile_word = self.read_word(data_addr + ((y * width + x) * 2))

				# Extract tile ID and properties
				tile_id = tile_word & 0x3FF      # Bits 0-9: tile index
				palette = (tile_word >> 10) & 0x7  # Bits 10-12: palette
				priority = (tile_word >> 13) & 0x1  # Bit 13: priority
				flip_x = (tile_word >> 14) & 0x1    # Bit 14: horizontal flip
				flip_y = (tile_word >> 15) & 0x1    # Bit 15: vertical flip

				# For TMX, we'll use GID format
				gid = tile_id + 1  # TMX uses 1-based indexing

				# Apply flip flags (TMX format)
				if flip_x:
					gid |= 0x80000000
				if flip_y:
					gid |= 0x40000000

				tiles.append(gid)

		layer = MapLayer(
			name=layer_name,
			width=width,
			height=height,
			data=tiles
		)

		return layer

	def extract_collision_layer(self, map_id: int) -> Optional[MapLayer]:
		"""Extract collision/walkability layer"""
		if map_id >= len(self.MAPS):
			return None

		map_info = self.MAPS[map_id]
		width = map_info['width']
		height = map_info['height']

		# Collision data is typically stored separately
		# This is a simplified extraction
		collision_addr = self.MAP_DATA_BASE + 0x10000 + (map_id * width * height)

		tiles = []
		for y in range(height):
			for x in range(width):
				collision_byte = self.read_byte(collision_addr + (y * width + x))

				# Convert collision flags to tile ID
				# 0 = passable, 1 = solid, 2 = water, etc.
				if collision_byte & self.COLLISION_SOLID:
					tile_id = 1
				elif collision_byte & self.COLLISION_WATER:
					tile_id = 2
				elif collision_byte & self.COLLISION_DAMAGE:
					tile_id = 3
				else:
					tile_id = 0

				tiles.append(tile_id)

		layer = MapLayer(
			name="Collision",
			width=width,
			height=height,
			data=tiles,
			opacity=0.5
		)

		return layer

	def extract_events(self, map_id: int) -> List[EventTrigger]:
		"""Extract event triggers (NPCs, chests, doors, etc.)"""
		events = []

		# Event data address (simplified)
		event_addr = self.MAP_EVENT_BASE + (map_id * 256)

		# Read events (up to 32 per map)
		for i in range(32):
			event_offset = event_addr + (i * 8)

			event_type = self.read_byte(event_offset + 0)
			if event_type == 0:
				continue  # No event

			x = self.read_byte(event_offset + 1)
			y = self.read_byte(event_offset + 2)
			event_id = self.read_byte(event_offset + 3)
			param1 = self.read_byte(event_offset + 4)
			param2 = self.read_byte(event_offset + 5)
			param3 = self.read_word(event_offset + 6)

			# Build properties based on event type
			properties = {
				'event_id': event_id,
				'param1': param1,
				'param2': param2,
				'param3': param3
			}

			event_type_name = self.EVENT_TYPES.get(event_type, 'unknown')

			# Add type-specific properties
			if event_type_name == 'npc':
				properties['npc_id'] = event_id
				properties['dialogue_id'] = param3
			elif event_type_name == 'chest':
				properties['item_id'] = param1
				properties['opened'] = param2
			elif event_type_name == 'door':
				properties['destination_map'] = param1
				properties['destination_x'] = param2
				properties['destination_y'] = param3 & 0xFF
			elif event_type_name == 'exit':
				properties['exit_map'] = param1
				properties['exit_x'] = param2
				properties['exit_y'] = param3 & 0xFF

			event = EventTrigger(
				x=x,
				y=y,
				event_type=event_type_name,
				event_id=event_id,
				properties=properties
			)

			events.append(event)

		return events

	def save_tmx(self, map_id: int, output_dir: str):
		"""Export map in Tiled TMX format"""
		metadata = self.extract_map_header(map_id)
		if not metadata:
			return

		terrain_layer = self.extract_map_layer(map_id, "Terrain")
		collision_layer = self.extract_collision_layer(map_id)
		events = self.extract_events(map_id)

		# Create TMX XML structure
		map_elem = ET.Element('map', {
			'version': '1.10',
			'tiledversion': '1.10.2',
			'orientation': 'orthogonal',
			'renderorder': 'right-down',
			'width': str(metadata.width),
			'height': str(metadata.height),
			'tilewidth': '16',
			'tileheight': '16',
			'infinite': '0',
			'nextlayerid': '4',
			'nextobjectid': str(len(events) + 1)
		})

		# Add tileset reference
		tileset_elem = ET.SubElement(map_elem, 'tileset', {
			'firstgid': '1',
			'name': f'tileset_{metadata.tileset_id:02d}',
			'tilewidth': '16',
			'tileheight': '16',
			'tilecount': '256',
			'columns': '16'
		})

		# Reference tileset image (will be extracted separately)
		image_elem = ET.SubElement(tileset_elem, 'image', {
			'source': f'../tilesets/tileset_{metadata.tileset_id:02d}.png',
			'width': '256',
			'height': '256'
		})

		# Add terrain layer
		if terrain_layer:
			layer_elem = ET.SubElement(map_elem, 'layer', {
				'id': '1',
				'name': terrain_layer.name,
				'width': str(terrain_layer.width),
				'height': str(terrain_layer.height)
			})

			data_elem = ET.SubElement(layer_elem, 'data', {'encoding': 'csv'})
			data_elem.text = '\n' + ',\n'.join(
				','.join(str(tile) for tile in terrain_layer.data[i:i+terrain_layer.width])
				for i in range(0, len(terrain_layer.data), terrain_layer.width)
			) + '\n'

		# Add collision layer
		if collision_layer:
			layer_elem = ET.SubElement(map_elem, 'layer', {
				'id': '2',
				'name': collision_layer.name,
				'width': str(collision_layer.width),
				'height': str(collision_layer.height),
				'opacity': str(collision_layer.opacity)
			})

			data_elem = ET.SubElement(layer_elem, 'data', {'encoding': 'csv'})
			data_elem.text = '\n' + ',\n'.join(
				','.join(str(tile) for tile in collision_layer.data[i:i+collision_layer.width])
				for i in range(0, len(collision_layer.data), collision_layer.width)
			) + '\n'

		# Add object layer for events
		if events:
			object_layer = ET.SubElement(map_elem, 'objectgroup', {
				'id': '3',
				'name': 'Events'
			})

			for idx, event in enumerate(events):
				obj_elem = ET.SubElement(object_layer, 'object', {
					'id': str(idx + 1),
					'name': event.event_type,
					'type': event.event_type,
					'x': str(event.x * 16),
					'y': str(event.y * 16),
					'width': '16',
					'height': '16'
				})

				# Add properties
				if event.properties:
					props_elem = ET.SubElement(obj_elem, 'properties')
					for key, value in event.properties.items():
						ET.SubElement(props_elem, 'property', {
							'name': key,
							'type': 'int' if isinstance(value, int) else 'string',
							'value': str(value)
						})

		# Add map properties
		props_elem = ET.SubElement(map_elem, 'properties')
		ET.SubElement(props_elem, 'property', {
			'name': 'map_id',
			'type': 'int',
			'value': str(metadata.map_id)
		})
		ET.SubElement(props_elem, 'property', {
			'name': 'music_id',
			'type': 'int',
			'value': str(metadata.music_id)
		})
		ET.SubElement(props_elem, 'property', {
			'name': 'encounter_group',
			'type': 'int',
			'value': str(metadata.encounter_group)
		})
		ET.SubElement(props_elem, 'property', {
			'name': 'palette_id',
			'type': 'int',
			'value': str(metadata.palette_id)
		})

		# Pretty print XML
		xml_str = ET.tostring(map_elem, encoding='unicode')
		dom = minidom.parseString(xml_str)
		pretty_xml = dom.toprettyxml(indent='  ')

		# Remove extra blank lines
		pretty_xml = '\n'.join([line for line in pretty_xml.split('\n') if line.strip()])

		# Save TMX file
		map_dir = Path(output_dir) / 'maps'
		map_dir.mkdir(parents=True, exist_ok=True)

		tmx_path = map_dir / f'{metadata.map_id:02d}_{metadata.name.replace(" ", "_")}.tmx'
		with open(tmx_path, 'w', encoding='utf-8') as f:
			f.write(pretty_xml)

		print(f"  Saved TMX: {tmx_path}")

	def save_json(self, map_id: int, output_dir: str):
		"""Export map data in JSON format"""
		metadata = self.extract_map_header(map_id)
		if not metadata:
			return

		terrain_layer = self.extract_map_layer(map_id, "Terrain")
		collision_layer = self.extract_collision_layer(map_id)
		events = self.extract_events(map_id)

		# Build JSON structure
		map_data = {
			'metadata': asdict(metadata),
			'layers': {},
			'events': [asdict(event) for event in events]
		}

		if terrain_layer:
			map_data['layers']['terrain'] = asdict(terrain_layer)

		if collision_layer:
			map_data['layers']['collision'] = asdict(collision_layer)

		# Save JSON
		map_dir = Path(output_dir) / 'maps'
		map_dir.mkdir(parents=True, exist_ok=True)

		json_path = map_dir / f'{metadata.map_id:02d}_{metadata.name.replace(" ", "_")}.json'
		with open(json_path, 'w', encoding='utf-8') as f:
			json.dump(map_data, f, indent=2)

		print(f"  Saved JSON: {json_path}")

	def extract_all_maps(self, output_dir: str, formats: List[str] = ['tmx', 'json']):
		"""Extract all maps in specified formats"""
		print(f"\n=== Extracting FFMQ Maps ===")
		print(f"Output directory: {output_dir}")
		print(f"Formats: {', '.join(formats)}")
		print()

		for map_info in self.MAPS:
			map_id = map_info['id']
			map_name = map_info['name']

			print(f"Extracting Map {map_id:02d}: {map_name}")

			if 'tmx' in formats:
				self.save_tmx(map_id, output_dir)

			if 'json' in formats:
				self.save_json(map_id, output_dir)

		print(f"\n✓ Extracted {len(self.MAPS)} maps")

		# Save extraction summary
		summary_path = Path(output_dir) / 'extraction_summary.txt'
		with open(summary_path, 'w') as f:
			f.write("FFMQ Map Extraction Summary\n")
			f.write("=" * 50 + "\n\n")
			f.write(f"Total maps extracted: {len(self.MAPS)}\n")
			f.write(f"Output formats: {', '.join(formats)}\n\n")
			f.write("Maps:\n")
			for map_info in self.MAPS:
				f.write(f"  {map_info['id']:02d}: {map_info['name']}\n")

		print(f"✓ Saved summary: {summary_path}")

def main():
	"""Main entry point"""
	if len(sys.argv) < 3:
		print("Usage: python extract_maps_enhanced.py <rom_file> <output_dir> [formats]")
		print("  formats: comma-separated list (tmx,json) - default: both")
		print("\nExample:")
		print("  python extract_maps_enhanced.py roms/FFMQ.sfc data/extracted/maps")
		print("  python extract_maps_enhanced.py roms/FFMQ.sfc data/extracted/maps tmx")
		sys.exit(1)

	rom_path = sys.argv[1]
	output_dir = sys.argv[2]
	formats = sys.argv[3].split(',') if len(sys.argv) > 3 else ['tmx', 'json']

	# Validate ROM file
	if not os.path.exists(rom_path):
		print(f"Error: ROM file not found: {rom_path}")
		sys.exit(1)

	# Create extractor
	extractor = FFMQMapExtractor(rom_path)

	# Load ROM
	if not extractor.load_rom():
		print("Failed to load ROM")
		sys.exit(1)

	# Extract all maps
	extractor.extract_all_maps(output_dir, formats)

	print("\n✓ Map extraction complete!")
	print(f"\nTo edit maps:")
	print(f"  1. Open TMX files in Tiled Map Editor")
	print(f"  2. Edit terrain, collision, events")
	print(f"  3. Save TMX file")
	print(f"  4. Use import_maps.py to write back to ROM")

if __name__ == '__main__':
	main()
