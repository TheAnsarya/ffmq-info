#!/usr/bin/env python3
"""
Advanced tool implementations for FFMQ Map Editor
Includes selection, copy/paste, line drawing, and pattern tools
"""

import pygame
import numpy as np
from typing import Optional, Tuple, List, Set
from dataclasses import dataclass
from enum import IntEnum


class SelectionMode(IntEnum):
	"""Selection modes"""
	RECTANGLE = 0
	FREEHAND = 1
	MAGIC_WAND = 2


@dataclass
class Selection:
	"""Represents a selection area"""
	tiles: Set[Tuple[int, int]]  # Set of (x, y) coordinates
	bounds: pygame.Rect  # Bounding rectangle
	mode: SelectionMode

	def contains(self, x: int, y: int) -> bool:
		"""Check if coordinates are in selection"""
		return (x, y) in self.tiles

	def clear(self):
		"""Clear selection"""
		self.tiles.clear()
		self.bounds = pygame.Rect(0, 0, 0, 0)

	def is_empty(self) -> bool:
		"""Check if selection is empty"""
		return len(self.tiles) == 0

	def add_tile(self, x: int, y: int):
		"""Add tile to selection"""
		self.tiles.add((x, y))
		self._update_bounds()

	def remove_tile(self, x: int, y: int):
		"""Remove tile from selection"""
		self.tiles.discard((x, y))
		self._update_bounds()

	def _update_bounds(self):
		"""Update bounding rectangle"""
		if not self.tiles:
			self.bounds = pygame.Rect(0, 0, 0, 0)
			return

		min_x = min(x for x, y in self.tiles)
		max_x = max(x for x, y in self.tiles)
		min_y = min(y for x, y in self.tiles)
		max_y = max(y for x, y in self.tiles)

		self.bounds = pygame.Rect(
			min_x, min_y,
			max_x - min_x + 1,
			max_y - min_y + 1
		)


class SelectionTool:
	"""Selection tool implementation"""

	def __init__(self):
		"""Initialize selection tool"""
		self.selection = Selection(
			tiles=set(),
			bounds=pygame.Rect(0, 0, 0, 0),
			mode=SelectionMode.RECTANGLE
		)
		self.start_pos: Optional[Tuple[int, int]] = None
		self.dragging = False
		self.additive = False  # Shift key for adding to selection

	def start_selection(self, x: int, y: int, additive: bool = False):
		"""Start new selection"""
		self.start_pos = (x, y)
		self.dragging = True
		self.additive = additive

		if not additive:
			self.selection.clear()

	def update_selection(self, x: int, y: int):
		"""Update selection while dragging"""
		if not self.dragging or self.start_pos is None:
			return

		if self.selection.mode == SelectionMode.RECTANGLE:
			self._select_rectangle(self.start_pos[0], self.start_pos[1], x, y)

	def end_selection(self):
		"""End selection"""
		self.dragging = False
		self.start_pos = None

	def _select_rectangle(self, x1: int, y1: int, x2: int, y2: int):
		"""Select rectangular area"""
		if not self.additive:
			self.selection.clear()

		min_x = min(x1, x2)
		max_x = max(x1, x2)
		min_y = min(y1, y2)
		max_y = max(y1, y2)

		for y in range(min_y, max_y + 1):
			for x in range(min_x, max_x + 1):
				self.selection.add_tile(x, y)

	def magic_wand_select(self, x: int, y: int, map_data: np.ndarray,
						 tolerance: int = 0):
		"""
		Select contiguous area of similar tiles

		Args:
			x, y: Starting position
			map_data: Map layer data
			tolerance: Tile ID tolerance for matching
		"""
		if not (0 <= y < map_data.shape[0] and 0 <= x < map_data.shape[1]):
			return

		target_tile = map_data[y, x]
		visited = set()
		to_visit = [(x, y)]

		while to_visit:
			cx, cy = to_visit.pop()

			if (cx, cy) in visited:
				continue

			if not (0 <= cy < map_data.shape[0] and 0 <= cx < map_data.shape[1]):
				continue

			current_tile = map_data[cy, cx]
			if abs(int(current_tile) - int(target_tile)) > tolerance:
				continue

			visited.add((cx, cy))
			self.selection.add_tile(cx, cy)

			# Check neighbors
			to_visit.extend([
				(cx + 1, cy),
				(cx - 1, cy),
				(cx, cy + 1),
				(cx, cy - 1)
			])

	def render_selection(self, screen: pygame.Surface,
						map_to_screen_func, tile_size: int):
		"""Render selection overlay"""
		if self.selection.is_empty():
			return

		# Create selection overlay
		overlay = pygame.Surface(screen.get_size(), pygame.SRCALPHA)

		for x, y in self.selection.tiles:
			screen_pos = map_to_screen_func((x, y))
			if screen_pos:
				sx, sy = screen_pos

				# Draw semi-transparent blue overlay
				rect = pygame.Rect(sx, sy, tile_size, tile_size)
				pygame.draw.rect(overlay, (100, 150, 255, 100), rect)

				# Draw border
				pygame.draw.rect(overlay, (255, 255, 0, 200), rect, 1)

		# Animated marching ants border
		if not self.selection.is_empty():
			import time
			offset = int(time.time() * 10) % 8

			bounds_screen = self._get_screen_bounds(
				self.selection.bounds, map_to_screen_func, tile_size
			)

			if bounds_screen:
				self._draw_marching_ants(overlay, bounds_screen, offset)

		screen.blit(overlay, (0, 0))

	def _get_screen_bounds(self, map_bounds: pygame.Rect,
						  map_to_screen_func, tile_size: int) -> Optional[pygame.Rect]:
		"""Convert map bounds to screen bounds"""
		top_left = map_to_screen_func((map_bounds.x, map_bounds.y))
		if not top_left:
			return None

		return pygame.Rect(
			top_left[0], top_left[1],
			map_bounds.width * tile_size,
			map_bounds.height * tile_size
		)

	def _draw_marching_ants(self, surface: pygame.Surface,
						   rect: pygame.Rect, offset: int):
		"""Draw animated marching ants border"""
		dash_length = 4
		color1 = (255, 255, 255, 255)
		color2 = (0, 0, 0, 255)

		# Top edge
		for i in range(0, rect.width, dash_length * 2):
			color = color1 if ((i + offset) // dash_length) % 2 == 0 else color2
			pygame.draw.line(
				surface, color,
				(rect.x + i, rect.y),
				(rect.x + min(i + dash_length, rect.width), rect.y)
			)

		# Bottom edge
		for i in range(0, rect.width, dash_length * 2):
			color = color1 if ((i + offset) // dash_length) % 2 == 0 else color2
			pygame.draw.line(
				surface, color,
				(rect.x + i, rect.y + rect.height - 1),
				(rect.x + min(i + dash_length, rect.width), rect.y + rect.height - 1)
			)

		# Left edge
		for i in range(0, rect.height, dash_length * 2):
			color = color1 if ((i + offset) // dash_length) % 2 == 0 else color2
			pygame.draw.line(
				surface, color,
				(rect.x, rect.y + i),
				(rect.x, rect.y + min(i + dash_length, rect.height))
			)

		# Right edge
		for i in range(0, rect.height, dash_length * 2):
			color = color1 if ((i + offset) // dash_length) % 2 == 0 else color2
			pygame.draw.line(
				surface, color,
				(rect.x + rect.width - 1, rect.y + i),
				(rect.x + rect.width - 1, rect.y + min(i + dash_length, rect.height))
			)


class LineTool:
	"""Line drawing tool implementation"""

	def __init__(self):
		"""Initialize line tool"""
		self.start_pos: Optional[Tuple[int, int]] = None
		self.end_pos: Optional[Tuple[int, int]] = None
		self.preview_tiles: List[Tuple[int, int]] = []

	def start_line(self, x: int, y: int):
		"""Start drawing line"""
		self.start_pos = (x, y)
		self.end_pos = (x, y)
		self.preview_tiles = [(x, y)]

	def update_line(self, x: int, y: int):
		"""Update line endpoint"""
		self.end_pos = (x, y)
		if self.start_pos:
			self.preview_tiles = self._bresenham_line(
				self.start_pos[0], self.start_pos[1],
				x, y
			)

	def end_line(self) -> List[Tuple[int, int]]:
		"""End line drawing and return tiles"""
		tiles = self.preview_tiles.copy()
		self.start_pos = None
		self.end_pos = None
		self.preview_tiles = []
		return tiles

	def _bresenham_line(self, x1: int, y1: int, x2: int, y2: int) -> List[Tuple[int, int]]:
		"""
		Bresenham's line algorithm

		Args:
			x1, y1: Start coordinates
			x2, y2: End coordinates

		Returns:
			List of (x, y) coordinates along line
		"""
		tiles = []

		dx = abs(x2 - x1)
		dy = abs(y2 - y1)
		sx = 1 if x1 < x2 else -1
		sy = 1 if y1 < y2 else -1
		err = dx - dy

		x, y = x1, y1

		while True:
			tiles.append((x, y))

			if x == x2 and y == y2:
				break

			e2 = 2 * err

			if e2 > -dy:
				err -= dy
				x += sx

			if e2 < dx:
				err += dx
				y += sy

		return tiles

	def render_preview(self, screen: pygame.Surface,
					  map_to_screen_func, tile_size: int, tile_id: int):
		"""Render line preview"""
		if not self.preview_tiles:
			return

		# Create preview overlay
		overlay = pygame.Surface(screen.get_size(), pygame.SRCALPHA)

		for x, y in self.preview_tiles:
			screen_pos = map_to_screen_func((x, y))
			if screen_pos:
				sx, sy = screen_pos

				# Draw semi-transparent overlay
				rect = pygame.Rect(sx, sy, tile_size, tile_size)
				pygame.draw.rect(overlay, (255, 255, 100, 150), rect)
				pygame.draw.rect(overlay, (255, 255, 0, 255), rect, 1)

		screen.blit(overlay, (0, 0))


class StampTool:
	"""Multi-tile stamp/brush tool"""

	def __init__(self):
		"""Initialize stamp tool"""
		self.stamp_data: Optional[np.ndarray] = None
		self.stamp_width = 0
		self.stamp_height = 0
		self.preview_pos: Optional[Tuple[int, int]] = None

	def create_stamp_from_selection(self, map_data: np.ndarray,
									selection: Selection):
		"""
		Create stamp from selection

		Args:
			map_data: Map layer data
			selection: Current selection
		"""
		if selection.is_empty():
			return

		bounds = selection.bounds
		self.stamp_width = bounds.width
		self.stamp_height = bounds.height
		self.stamp_data = np.zeros(
			(self.stamp_height, self.stamp_width), dtype=np.uint8
		)

		for x, y in selection.tiles:
			if (0 <= y < map_data.shape[0] and 0 <= x < map_data.shape[1]):
				stamp_x = x - bounds.x
				stamp_y = y - bounds.y
				self.stamp_data[stamp_y, stamp_x] = map_data[y, x]

	def set_stamp(self, data: np.ndarray):
		"""Set stamp data directly"""
		self.stamp_data = data.copy()
		self.stamp_height, self.stamp_width = data.shape

	def update_preview(self, x: int, y: int):
		"""Update stamp preview position"""
		self.preview_pos = (x, y)

	def clear_preview(self):
		"""Clear stamp preview"""
		self.preview_pos = None

	def apply_stamp(self, x: int, y: int, map_data: np.ndarray) -> bool:
		"""
		Apply stamp to map

		Args:
			x, y: Top-left position to place stamp
			map_data: Map layer data to modify

		Returns:
			True if applied successfully
		"""
		if self.stamp_data is None:
			return False

		# Apply stamp
		for sy in range(self.stamp_height):
			for sx in range(self.stamp_width):
				map_y = y + sy
				map_x = x + sx

				if (0 <= map_y < map_data.shape[0] and
					0 <= map_x < map_data.shape[1]):
					map_data[map_y, map_x] = self.stamp_data[sy, sx]

		return True

	def render_preview(self, screen: pygame.Surface,
					  map_to_screen_func, tile_size: int):
		"""Render stamp preview"""
		if self.stamp_data is None or self.preview_pos is None:
			return

		x, y = self.preview_pos
		overlay = pygame.Surface(screen.get_size(), pygame.SRCALPHA)

		for sy in range(self.stamp_height):
			for sx in range(self.stamp_width):
				tile_id = self.stamp_data[sy, sx]

				screen_pos = map_to_screen_func((x + sx, y + sy))
				if screen_pos:
					px, py = screen_pos

					# Draw preview tile
					# Get color based on tile ID (placeholder)
					r = (tile_id * 37) % 256
					g = (tile_id * 73) % 256
					b = (tile_id * 109) % 256
					color = (r, g, b, 150)

					rect = pygame.Rect(px, py, tile_size, tile_size)
					pygame.draw.rect(overlay, color, rect)
					pygame.draw.rect(overlay, (255, 255, 255, 200), rect, 1)

		screen.blit(overlay, (0, 0))


class ClipboardManager:
	"""Manages copy/paste operations"""

	def __init__(self):
		"""Initialize clipboard manager"""
		self.clipboard_data: Optional[np.ndarray] = None
		self.clipboard_width = 0
		self.clipboard_height = 0

	def copy(self, map_data: np.ndarray, selection: Selection):
		"""
		Copy selection to clipboard

		Args:
			map_data: Map layer data
			selection: Current selection
		"""
		if selection.is_empty():
			return

		bounds = selection.bounds
		self.clipboard_width = bounds.width
		self.clipboard_height = bounds.height
		self.clipboard_data = np.zeros(
			(self.clipboard_height, self.clipboard_width), dtype=np.uint8
		)

		for x, y in selection.tiles:
			if (0 <= y < map_data.shape[0] and 0 <= x < map_data.shape[1]):
				clip_x = x - bounds.x
				clip_y = y - bounds.y
				self.clipboard_data[clip_y, clip_x] = map_data[y, x]

	def cut(self, map_data: np.ndarray, selection: Selection):
		"""
		Cut selection to clipboard

		Args:
			map_data: Map layer data
			selection: Current selection
		"""
		self.copy(map_data, selection)

		# Clear selected tiles
		for x, y in selection.tiles:
			if (0 <= y < map_data.shape[0] and 0 <= x < map_data.shape[1]):
				map_data[y, x] = 0

	def paste(self, x: int, y: int, map_data: np.ndarray) -> bool:
		"""
		Paste clipboard contents

		Args:
			x, y: Top-left position to paste
			map_data: Map layer data to modify

		Returns:
			True if pasted successfully
		"""
		if self.clipboard_data is None:
			return False

		for cy in range(self.clipboard_height):
			for cx in range(self.clipboard_width):
				map_y = y + cy
				map_x = x + cx

				if (0 <= map_y < map_data.shape[0] and
					0 <= map_x < map_data.shape[1]):
					map_data[map_y, map_x] = self.clipboard_data[cy, cx]

		return True

	def has_data(self) -> bool:
		"""Check if clipboard has data"""
		return self.clipboard_data is not None
