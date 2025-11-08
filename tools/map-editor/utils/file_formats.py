#!/usr/bin/env python3
"""
Map file format handlers for FFMQ Map Editor
Supports multiple import/export formats
"""

import json
import struct
from pathlib import Path
from typing import Optional, Dict, Any
import numpy as np


class MapFileFormat:
	"""Base class for map file format handlers"""

	@staticmethod
	def save(filepath: str, map_data: dict) -> bool:
		"""Save map data to file"""
		raise NotImplementedError

	@staticmethod
	def load(filepath: str) -> Optional[dict]:
		"""Load map data from file"""
		raise NotImplementedError


class FFMAPFormat(MapFileFormat):
	"""
	FFMQ native map format (.ffmap)

	File structure:
	- Header (32 bytes)
	- Map properties (JSON)
	- Layer 1 data (compressed)
	- Layer 2 data (compressed)
	- Layer 3 data (compressed)
	- Collision data (compressed)
	"""

	MAGIC = b'FFMAP'
	VERSION = 1

	@staticmethod
	def save(filepath: str, map_data: dict) -> bool:
		"""
		Save map to FFMAP format

		Args:
			filepath: Output file path
			map_data: Map data dictionary

		Returns:
			True if successful
		"""
		try:
			with open(filepath, 'wb') as f:
				# Write header
				f.write(FFMAPFormat.MAGIC)
				f.write(struct.pack('<H', FFMAPFormat.VERSION))
				f.write(bytes(25))  # Reserved

				# Write properties as JSON
				properties = {
					'map_id': map_data.get('map_id', 0),
					'name': map_data.get('name', 'Untitled'),
					'map_type': map_data.get('map_type', 'Town'),
					'width': map_data.get('width', 32),
					'height': map_data.get('height', 32),
					'tileset_id': map_data.get('tileset_id', 0),
					'palette_id': map_data.get('palette_id', 0),
					'music_id': map_data.get('music_id', 0),
					'encounter_rate': map_data.get('encounter_rate', 0),
					'encounter_group': map_data.get('encounter_group', 0),
					'spawn_x': map_data.get('spawn_x', 0),
					'spawn_y': map_data.get('spawn_y', 0)
				}

				properties_json = json.dumps(properties).encode('utf-8')
				f.write(struct.pack('<I', len(properties_json)))
				f.write(properties_json)

				# Write layer data
				for layer_name in ['bg1_tiles', 'bg2_tiles', 'bg3_tiles']:
					layer_data = map_data.get(layer_name)
					if layer_data is not None:
						# Convert numpy array to bytes
						layer_bytes = layer_data.tobytes()
						f.write(struct.pack('<I', len(layer_bytes)))
						f.write(layer_bytes)
					else:
						f.write(struct.pack('<I', 0))

				# Write collision data
				collision_data = map_data.get('collision')
				if collision_data is not None:
					collision_bytes = collision_data.tobytes()
					f.write(struct.pack('<I', len(collision_bytes)))
					f.write(collision_bytes)
				else:
					f.write(struct.pack('<I', 0))

			return True

		except Exception as e:
			print(f"Error saving FFMAP: {e}")
			return False

	@staticmethod
	def load(filepath: str) -> Optional[dict]:
		"""
		Load map from FFMAP format

		Args:
			filepath: Input file path

		Returns:
			Map data dictionary, or None on error
		"""
		try:
			with open(filepath, 'rb') as f:
				# Read and verify header
				magic = f.read(5)
				if magic != FFMAPFormat.MAGIC:
					print("Invalid FFMAP file: bad magic")
					return None

				version = struct.unpack('<H', f.read(2))[0]
				if version != FFMAPFormat.VERSION:
					print(f"Unsupported FFMAP version: {version}")
					return None

				f.read(25)  # Skip reserved bytes

				# Read properties
				props_size = struct.unpack('<I', f.read(4))[0]
				props_json = f.read(props_size).decode('utf-8')
				properties = json.loads(props_json)

				width = properties['width']
				height = properties['height']

				# Read layer data
				map_data = properties.copy()

				for layer_name in ['bg1_tiles', 'bg2_tiles', 'bg3_tiles']:
					layer_size = struct.unpack('<I', f.read(4))[0]
					if layer_size > 0:
						layer_bytes = f.read(layer_size)
						layer_array = np.frombuffer(
							layer_bytes, dtype=np.uint8
						).reshape((height, width))
						map_data[layer_name] = layer_array
					else:
						map_data[layer_name] = np.zeros(
							(height, width), dtype=np.uint8
						)

				# Read collision data
				collision_size = struct.unpack('<I', f.read(4))[0]
				if collision_size > 0:
					collision_bytes = f.read(collision_size)
					map_data['collision'] = np.frombuffer(
						collision_bytes, dtype=np.uint8
					).reshape((height, width))
				else:
					map_data['collision'] = np.zeros(
						(height, width), dtype=np.uint8
					)

			return map_data

		except Exception as e:
			print(f"Error loading FFMAP: {e}")
			return None


class JSONFormat(MapFileFormat):
	"""
	JSON map format (.json)

	Human-readable format for easy editing and version control
	"""

	@staticmethod
	def save(filepath: str, map_data: dict) -> bool:
		"""
		Save map to JSON format

		Args:
			filepath: Output file path
			map_data: Map data dictionary

		Returns:
			True if successful
		"""
		try:
			# Convert numpy arrays to lists
			export_data = {
				'map_id': map_data.get('map_id', 0),
				'name': map_data.get('name', 'Untitled'),
				'map_type': map_data.get('map_type', 'Town'),
				'width': map_data.get('width', 32),
				'height': map_data.get('height', 32),
				'tileset_id': map_data.get('tileset_id', 0),
				'palette_id': map_data.get('palette_id', 0),
				'music_id': map_data.get('music_id', 0),
				'encounter_rate': map_data.get('encounter_rate', 0),
				'encounter_group': map_data.get('encounter_group', 0),
				'spawn_x': map_data.get('spawn_x', 0),
				'spawn_y': map_data.get('spawn_y', 0),
				'layers': {}
			}

			# Convert layers to lists
			for layer_name in ['bg1_tiles', 'bg2_tiles', 'bg3_tiles']:
				layer_data = map_data.get(layer_name)
				if layer_data is not None:
					export_data['layers'][layer_name] = layer_data.tolist()

			# Convert collision to list
			collision = map_data.get('collision')
			if collision is not None:
				export_data['collision'] = collision.tolist()

			with open(filepath, 'w') as f:
				json.dump(export_data, f, indent=2)

			return True

		except Exception as e:
			print(f"Error saving JSON: {e}")
			return False

	@staticmethod
	def load(filepath: str) -> Optional[dict]:
		"""
		Load map from JSON format

		Args:
			filepath: Input file path

		Returns:
			Map data dictionary, or None on error
		"""
		try:
			with open(filepath, 'r') as f:
				data = json.load(f)

			# Convert lists back to numpy arrays
			map_data = {
				'map_id': data.get('map_id', 0),
				'name': data.get('name', 'Untitled'),
				'map_type': data.get('map_type', 'Town'),
				'width': data.get('width', 32),
				'height': data.get('height', 32),
				'tileset_id': data.get('tileset_id', 0),
				'palette_id': data.get('palette_id', 0),
				'music_id': data.get('music_id', 0),
				'encounter_rate': data.get('encounter_rate', 0),
				'encounter_group': data.get('encounter_group', 0),
				'spawn_x': data.get('spawn_x', 0),
				'spawn_y': data.get('spawn_y', 0)
			}

			layers = data.get('layers', {})
			for layer_name in ['bg1_tiles', 'bg2_tiles', 'bg3_tiles']:
				layer_list = layers.get(layer_name)
				if layer_list:
					map_data[layer_name] = np.array(
						layer_list, dtype=np.uint8
					)

			collision_list = data.get('collision')
			if collision_list:
				map_data['collision'] = np.array(
					collision_list, dtype=np.uint8
				)

			return map_data

		except Exception as e:
			print(f"Error loading JSON: {e}")
			return None


class TiledFormat(MapFileFormat):
	"""
	Tiled TMX format (.tmx)

	Compatible with Tiled Map Editor for collaboration
	"""

	@staticmethod
	def save(filepath: str, map_data: dict) -> bool:
		"""
		Save map to TMX format

		Args:
			filepath: Output file path
			map_data: Map data dictionary

		Returns:
			True if successful
		"""
		try:
			width = map_data.get('width', 32)
			height = map_data.get('height', 32)
			tileset_id = map_data.get('tileset_id', 0)

			# Build TMX XML
			tmx = ['<?xml version="1.0" encoding="UTF-8"?>']
			tmx.append(f'<map version="1.0" orientation="orthogonal" '
					  f'renderorder="right-down" width="{width}" height="{height}" '
					  f'tilewidth="16" tileheight="16">')

			# Tileset reference
			tmx.append(f'  <tileset firstgid="1" name="tileset_{tileset_id}" '
					  f'tilewidth="16" tileheight="16" tilecount="256">')
			tmx.append(f'    <image source="tileset_{tileset_id}.png" '
					  f'width="128" height="128"/>')
			tmx.append('  </tileset>')

			# Layers
			for layer_idx, layer_name in enumerate(
				['bg1_tiles', 'bg2_tiles', 'bg3_tiles']
			):
				layer_data = map_data.get(layer_name)
				if layer_data is None:
					continue

				layer_display_name = ['Ground', 'Upper', 'Events'][layer_idx]
				tmx.append(f'  <layer name="{layer_display_name}" '
						  f'width="{width}" height="{height}">')
				tmx.append('    <data encoding="csv">')

				# Write tile data as CSV
				for y in range(height):
					row = []
					for x in range(width):
						tile_id = int(layer_data[y, x])
						row.append(str(tile_id + 1))  # +1 for Tiled GID
					tmx.append('      ' + ','.join(row) +
							  (',' if y < height - 1 else ''))

				tmx.append('    </data>')
				tmx.append('  </layer>')

			tmx.append('</map>')

			with open(filepath, 'w') as f:
				f.write('\n'.join(tmx))

			return True

		except Exception as e:
			print(f"Error saving TMX: {e}")
			return False

	@staticmethod
	def load(filepath: str) -> Optional[dict]:
		"""
		Load map from TMX format

		Note: Basic implementation - may not support all TMX features

		Args:
			filepath: Input file path

		Returns:
			Map data dictionary, or None on error
		"""
		# TODO: Implement TMX parsing
		# Would require XML parsing library
		print("TMX import not yet implemented")
		return None


class BinaryFormat(MapFileFormat):
	"""
	Raw binary format (.bin)

	Minimal format for direct ROM insertion
	"""

	@staticmethod
	def save(filepath: str, map_data: dict) -> bool:
		"""
		Save map to binary format

		Args:
			filepath: Output file path
			map_data: Map data dictionary

		Returns:
			True if successful
		"""
		try:
			width = map_data.get('width', 32)
			height = map_data.get('height', 32)

			with open(filepath, 'wb') as f:
				# Write dimensions
				f.write(struct.pack('<HH', width, height))

				# Write layer data
				for layer_name in ['bg1_tiles', 'bg2_tiles', 'bg3_tiles']:
					layer_data = map_data.get(layer_name)
					if layer_data is not None:
						f.write(layer_data.tobytes())
					else:
						f.write(bytes(width * height))

				# Write collision
				collision = map_data.get('collision')
				if collision is not None:
					f.write(collision.tobytes())
				else:
					f.write(bytes(width * height))

			return True

		except Exception as e:
			print(f"Error saving binary: {e}")
			return False

	@staticmethod
	def load(filepath: str) -> Optional[dict]:
		"""
		Load map from binary format

		Args:
			filepath: Input file path

		Returns:
			Map data dictionary, or None on error
		"""
		try:
			with open(filepath, 'rb') as f:
				# Read dimensions
				width, height = struct.unpack('<HH', f.read(4))

				layer_size = width * height
				map_data = {
					'width': width,
					'height': height
				}

				# Read layers
				for layer_name in ['bg1_tiles', 'bg2_tiles', 'bg3_tiles']:
					layer_bytes = f.read(layer_size)
					map_data[layer_name] = np.frombuffer(
						layer_bytes, dtype=np.uint8
					).reshape((height, width))

				# Read collision
				collision_bytes = f.read(layer_size)
				if len(collision_bytes) == layer_size:
					map_data['collision'] = np.frombuffer(
						collision_bytes, dtype=np.uint8
					).reshape((height, width))

			return map_data

		except Exception as e:
			print(f"Error loading binary: {e}")
			return None


def save_map(filepath: str, map_data: dict) -> bool:
	"""
	Save map in appropriate format based on file extension

	Args:
		filepath: Output file path
		map_data: Map data dictionary

	Returns:
		True if successful
	"""
	ext = Path(filepath).suffix.lower()

	if ext == '.ffmap':
		return FFMAPFormat.save(filepath, map_data)
	elif ext == '.json':
		return JSONFormat.save(filepath, map_data)
	elif ext == '.tmx':
		return TiledFormat.save(filepath, map_data)
	elif ext == '.bin':
		return BinaryFormat.save(filepath, map_data)
	else:
		print(f"Unknown format: {ext}")
		return False


def load_map(filepath: str) -> Optional[dict]:
	"""
	Load map from file, detecting format from extension

	Args:
		filepath: Input file path

	Returns:
		Map data dictionary, or None on error
	"""
	ext = Path(filepath).suffix.lower()

	if ext == '.ffmap':
		return FFMAPFormat.load(filepath)
	elif ext == '.json':
		return JSONFormat.load(filepath)
	elif ext == '.tmx':
		return TiledFormat.load(filepath)
	elif ext == '.bin':
		return BinaryFormat.load(filepath)
	else:
		print(f"Unknown format: {ext}")
		return None
