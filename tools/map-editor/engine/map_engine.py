#!/usr/bin/env python3
"""
Map Engine for FFMQ Map Editor
Handles map data, tile operations, and undo/redo
"""

import numpy as np
from typing import Optional, Tuple, List
from dataclasses import dataclass
from enum import IntEnum

class MapType(IntEnum):
	"""Map type enumeration"""
	OVERWORLD = 0
	TOWN = 1
	DUNGEON = 2
	BATTLE = 3
	SPECIAL = 4

class LayerType(IntEnum):
	"""Layer type enumeration"""
	BG1_GROUND = 0  # Ground layer (main tiles)
	BG2_UPPER = 1   # Upper layer (roofs, decorations)
	BG3_EVENTS = 2  # Event/collision layer

@dataclass
class MapHeader:
	"""Map header data structure"""
	map_id: int = 0
	map_type: MapType = MapType.OVERWORLD
	width: int = 64
	height: int = 64
	tileset_id: int = 0
	palette_id: int = 0
	music_id: int = 0
	encounter_rate: int = 0
	encounter_group: int = 0
	spawn_x: int = 0
	spawn_y: int = 0
	flags: int = 0

@dataclass
class Tile:
	"""Individual tile data"""
	tile_id: int = 0
	palette: int = 0
	flip_h: bool = False
	flip_v: bool = False
	priority: bool = False
	collision: int = 0

class MapData:
	"""Container for map layer data"""
	
	def __init__(self, width: int, height: int):
		"""Initialize map data with given dimensions"""
		self.width = width
		self.height = height
		
		# Create layers (each is a 2D numpy array of tile IDs)
		self.bg1_tiles = np.zeros((height, width), dtype=np.uint8)
		self.bg2_tiles = np.zeros((height, width), dtype=np.uint8)
		self.bg3_tiles = np.zeros((height, width), dtype=np.uint8)
		
		# Tile attributes (palette, flip, etc.) stored separately
		self.bg1_attrs = np.zeros((height, width), dtype=np.uint8)
		self.bg2_attrs = np.zeros((height, width), dtype=np.uint8)
		self.bg3_attrs = np.zeros((height, width), dtype=np.uint8)
		
		# Collision data
		self.collision = np.zeros((height, width), dtype=np.uint8)
	
	def get_layer(self, layer: LayerType) -> np.ndarray:
		"""Get tile array for specified layer"""
		if layer == LayerType.BG1_GROUND:
			return self.bg1_tiles
		elif layer == LayerType.BG2_UPPER:
			return self.bg2_tiles
		elif layer == LayerType.BG3_EVENTS:
			return self.bg3_tiles
		raise ValueError(f"Invalid layer: {layer}")
	
	def get_attrs(self, layer: LayerType) -> np.ndarray:
		"""Get attribute array for specified layer"""
		if layer == LayerType.BG1_GROUND:
			return self.bg1_attrs
		elif layer == LayerType.BG2_UPPER:
			return self.bg2_attrs
		elif layer == LayerType.BG3_EVENTS:
			return self.bg3_attrs
		raise ValueError(f"Invalid layer: {layer}")

class UndoAction:
	"""Represents an undoable action"""
	
	def __init__(self, action_type: str, layer: LayerType, 
				 tiles: List[Tuple[int, int, int]]):
		"""
		Initialize undo action
		
		Args:
			action_type: Type of action (paint, fill, etc.)
			layer: Layer that was modified
			tiles: List of (x, y, old_tile_id) tuples
		"""
		self.action_type = action_type
		self.layer = layer
		self.tiles = tiles

class MapEngine:
	"""Core map engine for editing maps"""
	
	def __init__(self, config):
		"""Initialize map engine"""
		self.config = config
		
		# Map data
		self.header = MapHeader()
		self.map_data: Optional[MapData] = None
		
		# Undo/redo stacks
		self.undo_stack: List[UndoAction] = []
		self.redo_stack: List[UndoAction] = []
		self.max_undo = 100
		
		# Modified flag
		self.modified = False
	
	def new_map(self, width: int, height: int, 
				map_type: MapType = MapType.OVERWORLD) -> None:
		"""Create a new map"""
		self.header = MapHeader(
			width=width,
			height=height,
			map_type=map_type
		)
		self.map_data = MapData(width, height)
		self.undo_stack.clear()
		self.redo_stack.clear()
		self.modified = False
	
	def load_map(self, filepath: str) -> bool:
		"""Load a map from file"""
		# TODO: Implement map loading from FFMQ format
		return False
	
	def save_map(self, filepath: str) -> bool:
		"""Save map to file"""
		# TODO: Implement map saving to FFMQ format
		return False
	
	def get_tile(self, x: int, y: int, layer: LayerType) -> Optional[int]:
		"""Get tile ID at position"""
		if self.map_data is None:
			return None
		
		if not self._is_valid_pos(x, y):
			return None
		
		layer_data = self.map_data.get_layer(layer)
		return int(layer_data[y, x])
	
	def set_tile(self, x: int, y: int, tile_id: int, 
				 layer: LayerType) -> bool:
		"""Set tile at position"""
		if self.map_data is None:
			return False
		
		if not self._is_valid_pos(x, y):
			return False
		
		layer_data = self.map_data.get_layer(layer)
		old_tile = int(layer_data[y, x])
		
		if old_tile != tile_id:
			# Record for undo
			self._record_undo('paint', layer, [(x, y, old_tile)])
			
			# Set new tile
			layer_data[y, x] = tile_id
			self.modified = True
		
		return True
	
	def flood_fill(self, x: int, y: int, tile_id: int, 
				   layer: LayerType) -> bool:
		"""Flood fill from position"""
		if self.map_data is None:
			return False
		
		if not self._is_valid_pos(x, y):
			return False
		
		layer_data = self.map_data.get_layer(layer)
		target_tile = int(layer_data[y, x])
		
		if target_tile == tile_id:
			return False  # Already the right tile
		
		# Perform flood fill and record changed tiles
		changed_tiles = []
		self._flood_fill_recursive(x, y, target_tile, tile_id, 
								   layer_data, changed_tiles)
		
		if changed_tiles:
			self._record_undo('fill', layer, changed_tiles)
			self.modified = True
		
		return True
	
	def _flood_fill_recursive(self, x: int, y: int, target: int, 
							 replacement: int, layer_data: np.ndarray,
							 changed_tiles: List[Tuple[int, int, int]]) -> None:
		"""Recursive flood fill helper"""
		if not self._is_valid_pos(x, y):
			return
		
		if layer_data[y, x] != target:
			return
		
		# Record old tile and set new one
		changed_tiles.append((x, y, target))
		layer_data[y, x] = replacement
		
		# Recursively fill neighbors
		self._flood_fill_recursive(x + 1, y, target, replacement, 
								   layer_data, changed_tiles)
		self._flood_fill_recursive(x - 1, y, target, replacement, 
								   layer_data, changed_tiles)
		self._flood_fill_recursive(x, y + 1, target, replacement, 
								   layer_data, changed_tiles)
		self._flood_fill_recursive(x, y - 1, target, replacement, 
								   layer_data, changed_tiles)
	
	def paint_rectangle(self, x1: int, y1: int, x2: int, y2: int,
					   tile_id: int, layer: LayerType) -> bool:
		"""Paint a rectangle of tiles"""
		if self.map_data is None:
			return False
		
		# Ensure coordinates are in bounds
		x1 = max(0, min(x1, self.header.width - 1))
		x2 = max(0, min(x2, self.header.width - 1))
		y1 = max(0, min(y1, self.header.height - 1))
		y2 = max(0, min(y2, self.header.height - 1))
		
		# Ensure x1 <= x2 and y1 <= y2
		if x1 > x2:
			x1, x2 = x2, x1
		if y1 > y2:
			y1, y2 = y2, y1
		
		layer_data = self.map_data.get_layer(layer)
		changed_tiles = []
		
		# Fill rectangle
		for y in range(y1, y2 + 1):
			for x in range(x1, x2 + 1):
				old_tile = int(layer_data[y, x])
				if old_tile != tile_id:
					changed_tiles.append((x, y, old_tile))
					layer_data[y, x] = tile_id
		
		if changed_tiles:
			self._record_undo('rectangle', layer, changed_tiles)
			self.modified = True
		
		return True
	
	def undo(self) -> bool:
		"""Undo last action"""
		if not self.undo_stack:
			return False
		
		action = self.undo_stack.pop()
		layer_data = self.map_data.get_layer(action.layer)
		
		# Record current state for redo
		redo_tiles = []
		for x, y, old_tile in action.tiles:
			current_tile = int(layer_data[y, x])
			redo_tiles.append((x, y, current_tile))
			layer_data[y, x] = old_tile
		
		# Add to redo stack
		redo_action = UndoAction(action.action_type, action.layer, redo_tiles)
		self.redo_stack.append(redo_action)
		
		return True
	
	def redo(self) -> bool:
		"""Redo last undone action"""
		if not self.redo_stack:
			return False
		
		action = self.redo_stack.pop()
		layer_data = self.map_data.get_layer(action.layer)
		
		# Record current state for undo
		undo_tiles = []
		for x, y, old_tile in action.tiles:
			current_tile = int(layer_data[y, x])
			undo_tiles.append((x, y, current_tile))
			layer_data[y, x] = old_tile
		
		# Add back to undo stack
		undo_action = UndoAction(action.action_type, action.layer, undo_tiles)
		self.undo_stack.append(undo_action)
		
		return True
	
	def _record_undo(self, action_type: str, layer: LayerType,
					tiles: List[Tuple[int, int, int]]) -> None:
		"""Record an action for undo"""
		action = UndoAction(action_type, layer, tiles)
		self.undo_stack.append(action)
		
		# Trim undo stack if too large
		if len(self.undo_stack) > self.max_undo:
			self.undo_stack.pop(0)
		
		# Clear redo stack when new action is performed
		self.redo_stack.clear()
	
	def _is_valid_pos(self, x: int, y: int) -> bool:
		"""Check if position is within map bounds"""
		if self.map_data is None:
			return False
		return 0 <= x < self.header.width and 0 <= y < self.header.height
	
	def update(self, delta_time: float) -> None:
		"""Update map engine state"""
		# TODO: Add any time-based updates if needed
		pass
	
	def get_map_size(self) -> Tuple[int, int]:
		"""Get current map dimensions"""
		if self.header:
			return (self.header.width, self.header.height)
		return (0, 0)
	
	def is_modified(self) -> bool:
		"""Check if map has been modified"""
		return self.modified
	
	def clear_modified(self) -> None:
		"""Clear the modified flag"""
		self.modified = False
