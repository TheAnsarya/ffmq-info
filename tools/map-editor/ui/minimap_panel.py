#!/usr/bin/env python3
"""
Minimap panel for FFMQ Map Editor
Provides zoomed-out overview of entire map with viewport indicator
"""

import pygame
from typing import Optional, Tuple


class MinimapPanel:
	"""Minimap panel showing entire map overview"""

	def __init__(self, x: int, y: int, width: int, height: int):
		"""
		Initialize minimap panel

		Args:
			x, y: Panel position
			width, height: Panel dimensions
		"""
		self.rect = pygame.Rect(x, y, width, height)
		self.surface = pygame.Surface((width, height))

		# Colors
		self.bg_color = (40, 40, 40)
		self.border_color = (100, 100, 100)
		self.viewport_color = (255, 255, 0)
		self.grid_color = (60, 60, 60)

		# Minimap settings
		self.scale = 1.0  # Pixels per tile in minimap
		self.show_viewport = True
		self.show_grid = False

		# Map cache
		self.map_surface: Optional[pygame.Surface] = None
		self.map_width = 0
		self.map_height = 0

		# Interaction
		self.dragging = False

	def update_map(self, map_engine, tileset_manager=None):
		"""
		Update minimap from map engine

		Args:
			map_engine: MapEngine instance
			tileset_manager: TilesetManager instance (optional)
		"""
		if map_engine.current_map is None:
			self.map_surface = None
			return

		self.map_width = map_engine.current_map.width
		self.map_height = map_engine.current_map.height

		# Calculate scale to fit map in panel
		padding = 20
		available_width = self.rect.width - padding * 2
		available_height = self.rect.height - padding * 2

		scale_x = available_width / self.map_width
		scale_y = available_height / self.map_height
		self.scale = min(scale_x, scale_y, 4.0)  # Max 4 pixels per tile

		# Create minimap surface
		mini_width = int(self.map_width * self.scale)
		mini_height = int(self.map_height * self.scale)
		self.map_surface = pygame.Surface((mini_width, mini_height))

		# Render map
		for y in range(self.map_height):
			for x in range(self.map_width):
				# Get tile from all layers
				color = (0, 0, 0)

				# Check BG3 (events) first
				tile_id = map_engine.current_map.bg3_tiles[y, x]
				if tile_id > 0:
					color = self._get_tile_color(tile_id, 3)
				else:
					# Check BG2 (upper)
					tile_id = map_engine.current_map.bg2_tiles[y, x]
					if tile_id > 0:
						color = self._get_tile_color(tile_id, 2)
					else:
						# Use BG1 (ground)
						tile_id = map_engine.current_map.bg1_tiles[y, x]
						color = self._get_tile_color(tile_id, 1)

				# Draw tile (1 pixel or scaled)
				tile_rect = pygame.Rect(
					int(x * self.scale),
					int(y * self.scale),
					max(1, int(self.scale)),
					max(1, int(self.scale))
				)
				pygame.draw.rect(self.map_surface, color, tile_rect)

	def _get_tile_color(self, tile_id: int, layer: int) -> Tuple[int, int, int]:
		"""Get color for tile in minimap"""
		if tile_id == 0:
			return (0, 0, 0)

		# Simple color coding based on tile ID and layer
		base_r = (tile_id * 37) % 256
		base_g = (tile_id * 73) % 256
		base_b = (tile_id * 109) % 256

		# Adjust brightness by layer
		brightness = [0.6, 0.8, 1.0][layer - 1]

		r = int(base_r * brightness)
		g = int(base_g * brightness)
		b = int(base_b * brightness)

		return (r, g, b)

	def handle_mouse_down(self, pos: Tuple[int, int], button: int) -> Optional[Tuple[int, int]]:
		"""
		Handle mouse down event

		Args:
			pos: Mouse position
			button: Mouse button

		Returns:
			Map coordinates to center viewport on, or None
		"""
		if not self.rect.collidepoint(pos):
			return None

		if button == 1:  # Left click
			self.dragging = True
			return self._pos_to_map(pos)

		return None

	def handle_mouse_up(self, pos: Tuple[int, int], button: int):
		"""Handle mouse up event"""
		if button == 1:
			self.dragging = False

	def handle_mouse_motion(self, pos: Tuple[int, int]) -> Optional[Tuple[int, int]]:
		"""
		Handle mouse motion event

		Args:
			pos: Mouse position

		Returns:
			Map coordinates to center viewport on, or None
		"""
		if self.dragging:
			return self._pos_to_map(pos)
		return None

	def _pos_to_map(self, pos: Tuple[int, int]) -> Optional[Tuple[int, int]]:
		"""Convert screen position to map coordinates"""
		if self.map_surface is None:
			return None

		# Get position relative to panel
		rel_x = pos[0] - self.rect.x
		rel_y = pos[1] - self.rect.y

		# Center map in panel
		padding = 20
		map_offset_x = padding + (self.rect.width - padding * 2 -
								  self.map_surface.get_width()) // 2
		map_offset_y = padding + (self.rect.height - padding * 2 -
								  self.map_surface.get_height()) // 2

		# Convert to map coordinates
		map_x = (rel_x - map_offset_x) / self.scale
		map_y = (rel_y - map_offset_y) / self.scale

		# Clamp to map bounds
		map_x = max(0, min(self.map_width - 1, map_x))
		map_y = max(0, min(self.map_height - 1, map_y))

		return (int(map_x), int(map_y))

	def render(self, screen: pygame.Surface, viewport_rect: Optional[pygame.Rect] = None):
		"""
		Render minimap

		Args:
			screen: Target surface
			viewport_rect: Current viewport in map coordinates
		"""
		# Clear panel
		self.surface.fill(self.bg_color)

		# Draw map if available
		if self.map_surface:
			# Center map in panel
			padding = 20
			map_x = padding + (self.rect.width - padding * 2 -
							  self.map_surface.get_width()) // 2
			map_y = padding + (self.rect.height - padding * 2 -
							  self.map_surface.get_height()) // 2

			self.surface.blit(self.map_surface, (map_x, map_y))

			# Draw grid if enabled
			if self.show_grid and self.scale >= 2:
				self._draw_grid(map_x, map_y)

			# Draw viewport indicator
			if self.show_viewport and viewport_rect:
				self._draw_viewport(map_x, map_y, viewport_rect)

		# Draw border
		pygame.draw.rect(self.surface, self.border_color,
						self.surface.get_rect(), 2)

		# Draw title
		font = pygame.font.Font(None, 20)
		title = font.render("Minimap", True, (200, 200, 200))
		self.surface.blit(title, (10, 5))

		# Blit to screen
		screen.blit(self.surface, self.rect)

	def _draw_grid(self, offset_x: int, offset_y: int):
		"""Draw grid over minimap"""
		if self.map_surface is None:
			return

		# Draw vertical lines
		for x in range(self.map_width + 1):
			line_x = offset_x + int(x * self.scale)
			pygame.draw.line(
				self.surface, self.grid_color,
				(line_x, offset_y),
				(line_x, offset_y + self.map_surface.get_height())
			)

		# Draw horizontal lines
		for y in range(self.map_height + 1):
			line_y = offset_y + int(y * self.scale)
			pygame.draw.line(
				self.surface, self.grid_color,
				(offset_x, line_y),
				(offset_x + self.map_surface.get_width(), line_y)
			)

	def _draw_viewport(self, offset_x: int, offset_y: int,
					  viewport_rect: pygame.Rect):
		"""Draw viewport indicator"""
		if self.map_surface is None:
			return

		# Convert viewport to minimap coordinates
		vp_x = offset_x + int(viewport_rect.x * self.scale)
		vp_y = offset_y + int(viewport_rect.y * self.scale)
		vp_w = int(viewport_rect.width * self.scale)
		vp_h = int(viewport_rect.height * self.scale)

		# Draw viewport rectangle
		vp_rect = pygame.Rect(vp_x, vp_y, vp_w, vp_h)
		pygame.draw.rect(self.surface, self.viewport_color, vp_rect, 2)

		# Draw corner handles
		corner_size = 4
		corners = [
			(vp_x, vp_y),  # Top-left
			(vp_x + vp_w, vp_y),  # Top-right
			(vp_x, vp_y + vp_h),  # Bottom-left
			(vp_x + vp_w, vp_y + vp_h)  # Bottom-right
		]

		for corner in corners:
			corner_rect = pygame.Rect(
				corner[0] - corner_size // 2,
				corner[1] - corner_size // 2,
				corner_size, corner_size
			)
			pygame.draw.rect(self.surface, self.viewport_color, corner_rect)

	def contains_point(self, pos: Tuple[int, int]) -> bool:
		"""Check if position is inside panel"""
		return self.rect.collidepoint(pos)

	def toggle_viewport(self):
		"""Toggle viewport indicator visibility"""
		self.show_viewport = not self.show_viewport

	def toggle_grid(self):
		"""Toggle grid visibility"""
		self.show_grid = not self.show_grid
