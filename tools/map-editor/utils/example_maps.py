#!/usr/bin/env python3
"""
Example map generator for FFMQ Map Editor
Creates sample maps demonstrating various features and techniques
"""

import numpy as np
from pathlib import Path
import json


class ExampleMapGenerator:
	"""Generates example maps for testing and demonstration"""

	@staticmethod
	def create_simple_town(width: int = 32, height: int = 32) -> dict:
		"""
		Create a simple town map

		Args:
			width, height: Map dimensions

		Returns:
			Map data dictionary
		"""
		map_data = {
			'map_id': 1,
			'name': 'Example Town',
			'map_type': 'Town',
			'width': width,
			'height': height,
			'tileset_id': 0,
			'palette_id': 0,
			'music_id': 1,
			'encounter_rate': 0,
			'encounter_group': 0,
			'spawn_x': width // 2,
			'spawn_y': height // 2
		}

		# Create layers
		bg1 = np.zeros((height, width), dtype=np.uint8)
		bg2 = np.zeros((height, width), dtype=np.uint8)
		bg3 = np.zeros((height, width), dtype=np.uint8)
		collision = np.zeros((height, width), dtype=np.uint8)

		# Fill ground with grass (tile 1)
		bg1.fill(1)

		# Create border walls (tile 10)
		bg1[0, :] = 10
		bg1[-1, :] = 10
		bg1[:, 0] = 10
		bg1[:, -1] = 10
		collision[0, :] = 1
		collision[-1, :] = 1
		collision[:, 0] = 1
		collision[:, -1] = 1

		# Create path down the middle (tile 2)
		path_width = 3
		path_start = width // 2 - path_width // 2
		bg1[:, path_start:path_start + path_width] = 2

		# Add some buildings (tiles 20-25)
		# Building 1 (left side)
		building1_x = 5
		building1_y = 5
		building1_w = 6
		building1_h = 6

		bg2[building1_y:building1_y + building1_h,
			building1_x:building1_x + building1_w] = 20
		collision[building1_y:building1_y + building1_h,
				 building1_x:building1_x + building1_w] = 1

		# Add door (tile 21)
		door_x = building1_x + building1_w // 2
		door_y = building1_y + building1_h - 1
		bg2[door_y, door_x] = 21
		collision[door_y, door_x] = 0

		# Building 2 (right side)
		building2_x = width - 11
		building2_y = 5
		building2_w = 6
		building2_h = 6

		bg2[building2_y:building2_y + building2_h,
			building2_x:building2_x + building2_w] = 20
		collision[building2_y:building2_y + building2_h,
				 building2_x:building2_x + building2_w] = 1

		# Add door
		door_x = building2_x + building2_w // 2
		door_y = building2_y + building2_h - 1
		bg2[door_y, door_x] = 21
		collision[door_y, door_x] = 0

		# Add some decorative flowers (tile 5)
		for i in range(0, width, 4):
			for j in range(0, height, 4):
				if bg2[j, i] == 0 and bg1[j, i] == 1:
					bg2[j, i] = 5

		map_data['bg1_tiles'] = bg1
		map_data['bg2_tiles'] = bg2
		map_data['bg3_tiles'] = bg3
		map_data['collision'] = collision

		return map_data

	@staticmethod
	def create_dungeon_room(width: int = 32, height: int = 32) -> dict:
		"""
		Create a dungeon room map

		Args:
			width, height: Map dimensions

		Returns:
			Map data dictionary
		"""
		map_data = {
			'map_id': 2,
			'name': 'Dungeon Room',
			'map_type': 'Dungeon',
			'width': width,
			'height': height,
			'tileset_id': 1,
			'palette_id': 1,
			'music_id': 5,
			'encounter_rate': 30,
			'encounter_group': 1,
			'spawn_x': width // 2,
			'spawn_y': height - 2
		}

		# Create layers
		bg1 = np.zeros((height, width), dtype=np.uint8)
		bg2 = np.zeros((height, width), dtype=np.uint8)
		bg3 = np.zeros((height, width), dtype=np.uint8)
		collision = np.ones((height, width), dtype=np.uint8)

		# Fill with stone floor (tile 30)
		bg1.fill(30)

		# Create room boundaries
		room_margin = 3
		room_left = room_margin
		room_right = width - room_margin
		room_top = room_margin
		room_bottom = height - room_margin

		# Clear collision in room
		collision[room_top:room_bottom, room_left:room_right] = 0

		# Add walls (tile 31)
		# Top wall
		bg2[room_top, room_left:room_right] = 31
		collision[room_top, room_left:room_right] = 1

		# Bottom wall
		bg2[room_bottom - 1, room_left:room_right] = 31
		collision[room_bottom - 1, room_left:room_right] = 1

		# Left wall
		bg2[room_top:room_bottom, room_left] = 31
		collision[room_top:room_bottom, room_left] = 1

		# Right wall
		bg2[room_top:room_bottom, room_right - 1] = 31
		collision[room_top:room_bottom, room_right - 1] = 1

		# Add doorways
		# South door
		door_x = width // 2
		bg2[room_bottom - 1, door_x] = 32
		collision[room_bottom - 1, door_x] = 0

		# North door
		bg2[room_top, door_x] = 32
		collision[room_top, door_x] = 0

		# Add some pillars (tile 33)
		pillar_positions = [
			(room_left + 5, room_top + 5),
			(room_right - 6, room_top + 5),
			(room_left + 5, room_bottom - 6),
			(room_right - 6, room_bottom - 6)
		]

		for px, py in pillar_positions:
			bg2[py, px] = 33
			collision[py, px] = 1

		# Add treasure chest locations (tile 40)
		chest_x = width // 2
		chest_y = room_top + 3
		bg2[chest_y, chest_x] = 40

		map_data['bg1_tiles'] = bg1
		map_data['bg2_tiles'] = bg2
		map_data['bg3_tiles'] = bg3
		map_data['collision'] = collision

		return map_data

	@staticmethod
	def create_overworld_section(width: int = 64, height: int = 64) -> dict:
		"""
		Create an overworld map section

		Args:
			width, height: Map dimensions

		Returns:
			Map data dictionary
		"""
		map_data = {
			'map_id': 0,
			'name': 'Overworld',
			'map_type': 'Overworld',
			'width': width,
			'height': height,
			'tileset_id': 2,
			'palette_id': 2,
			'music_id': 0,
			'encounter_rate': 15,
			'encounter_group': 0,
			'spawn_x': width // 2,
			'spawn_y': height // 2
		}

		# Create layers
		bg1 = np.zeros((height, width), dtype=np.uint8)
		bg2 = np.zeros((height, width), dtype=np.uint8)
		bg3 = np.zeros((height, width), dtype=np.uint8)
		collision = np.zeros((height, width), dtype=np.uint8)

		# Create terrain using Perlin-like noise simulation
		# Base terrain: grass (tile 50)
		bg1.fill(50)

		# Add water areas (tile 51)
		water_y_start = height // 4
		water_y_end = height // 2
		water_x_start = width // 4
		water_x_end = 3 * width // 4

		bg1[water_y_start:water_y_end, water_x_start:water_x_end] = 51
		collision[water_y_start:water_y_end, water_x_start:water_x_end] = 1

		# Add bridge (tile 52)
		bridge_y = (water_y_start + water_y_end) // 2
		bridge_x_start = water_x_start
		bridge_x_end = water_x_end
		bg2[bridge_y - 1:bridge_y + 2, bridge_x_start:bridge_x_end] = 52
		collision[bridge_y - 1:bridge_y + 2, bridge_x_start:bridge_x_end] = 0

		# Add forest areas (tile 53)
		forest1_x = 5
		forest1_y = 5
		forest1_size = 8

		for y in range(forest1_y, forest1_y + forest1_size):
			for x in range(forest1_x, forest1_x + forest1_size):
				if (x - forest1_x - forest1_size // 2) ** 2 + \
				   (y - forest1_y - forest1_size // 2) ** 2 < (forest1_size // 2) ** 2:
					bg2[y, x] = 53
					collision[y, x] = 1

		# Add mountains (tile 54)
		mountain_y = height - 15
		mountain_x = width - 15
		mountain_size = 10

		for y in range(mountain_y, min(mountain_y + mountain_size, height)):
			for x in range(mountain_x, min(mountain_x + mountain_size, width)):
				bg2[y, x] = 54
				collision[y, x] = 1

		# Add path/road (tile 55)
		path_y = height // 2
		bg1[path_y, :] = 55
		bg1[path_y + 1, :] = 55
		collision[path_y, :] = 0
		collision[path_y + 1, :] = 0

		# Clear path through forest
		path_through_forest_x = forest1_x + forest1_size // 2
		bg2[path_y:path_y + 2, path_through_forest_x - 1:path_through_forest_x + 2] = 0
		collision[path_y:path_y + 2, path_through_forest_x - 1:path_through_forest_x + 2] = 0

		map_data['bg1_tiles'] = bg1
		map_data['bg2_tiles'] = bg2
		map_data['bg3_tiles'] = bg3
		map_data['collision'] = collision

		return map_data

	@staticmethod
	def create_pattern_test_map(width: int = 32, height: int = 32) -> dict:
		"""
		Create a map showcasing various tile patterns

		Args:
			width, height: Map dimensions

		Returns:
			Map data dictionary
		"""
		map_data = {
			'map_id': 99,
			'name': 'Pattern Test',
			'map_type': 'Special',
			'width': width,
			'height': height,
			'tileset_id': 0,
			'palette_id': 0,
			'music_id': 0,
			'encounter_rate': 0,
			'encounter_group': 0,
			'spawn_x': 0,
			'spawn_y': 0
		}

		# Create layers
		bg1 = np.zeros((height, width), dtype=np.uint8)
		bg2 = np.zeros((height, width), dtype=np.uint8)
		bg3 = np.zeros((height, width), dtype=np.uint8)
		collision = np.zeros((height, width), dtype=np.uint8)

		# Pattern 1: Checkerboard
		for y in range(height // 4):
			for x in range(width // 4):
				tile = 1 if (x + y) % 2 == 0 else 2
				bg1[y, x] = tile

		# Pattern 2: Stripes
		for y in range(height // 4, height // 2):
			for x in range(width // 4):
				bg1[y, x] = (x % 4) + 3

		# Pattern 3: Gradient
		for y in range(height // 4):
			for x in range(width // 4, width // 2):
				tile = int((x - width // 4) / (width // 4) * 16) + 10
				bg1[y, x] = tile

		# Pattern 4: Concentric circles
		center_x = 3 * width // 8
		center_y = 3 * height // 8
		for y in range(height // 4, height // 2):
			for x in range(width // 4, width // 2):
				dist = ((x - center_x) ** 2 + (y - center_y) ** 2) ** 0.5
				bg1[y, x] = int(dist % 8) + 30

		# Pattern 5: Random noise
		for y in range(height // 2, 3 * height // 4):
			for x in range(width // 2):
				bg1[y, x] = np.random.randint(0, 16) + 40

		# Pattern 6: Tile ID showcase
		tile_id = 0
		for y in range(3 * height // 4, height):
			for x in range(width):
				if tile_id < 256:
					bg1[y, x] = tile_id
					tile_id += 1

		map_data['bg1_tiles'] = bg1
		map_data['bg2_tiles'] = bg2
		map_data['bg3_tiles'] = bg3
		map_data['collision'] = collision

		return map_data

	@staticmethod
	def save_example_maps(output_dir: str = 'data/examples'):
		"""
		Generate and save all example maps

		Args:
			output_dir: Output directory path
		"""
		from .file_formats import save_map

		output_path = Path(output_dir)
		output_path.mkdir(parents=True, exist_ok=True)

		examples = [
			('simple_town.ffmap', ExampleMapGenerator.create_simple_town()),
			('dungeon_room.ffmap', ExampleMapGenerator.create_dungeon_room()),
			('overworld.ffmap', ExampleMapGenerator.create_overworld_section()),
			('pattern_test.ffmap', ExampleMapGenerator.create_pattern_test_map())
		]

		for filename, map_data in examples:
			filepath = output_path / filename
			if save_map(str(filepath), map_data):
				print(f"Created example map: {filepath}")
			else:
				print(f"Failed to create: {filepath}")

		# Also save as JSON for easy viewing
		for filename, map_data in examples:
			json_filename = filename.replace('.ffmap', '.json')
			filepath = output_path / json_filename

			# Convert numpy arrays to lists for JSON
			json_data = map_data.copy()
			for key in ['bg1_tiles', 'bg2_tiles', 'bg3_tiles', 'collision']:
				if key in json_data and json_data[key] is not None:
					json_data[key] = json_data[key].tolist()

			try:
				with open(filepath, 'w') as f:
					json.dump(json_data, f, indent=2)
				print(f"Created JSON example: {filepath}")
			except Exception as e:
				print(f"Failed to create JSON: {filepath} - {e}")


if __name__ == '__main__':
	# Generate example maps when run directly
	print("Generating example maps...")
	ExampleMapGenerator.save_example_maps()
	print("Done!")
