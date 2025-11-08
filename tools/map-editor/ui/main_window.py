#!/usr/bin/env python3
"""
Main window component for map editing
"""

import pygame
from typing import Tuple, Optional
from engine.map_engine import MapEngine, LayerType

class MainWindow:
	"""Main map editing window"""
	
	def __init__(self, screen: pygame.Surface, config):
		"""Initialize main window"""
		self.screen = screen
		self.config = config
		
		# Calculate window area (excluding UI panels)
		self.update_bounds()
		
		# View state
		self.camera_x = 0
		self.camera_y = 0
		self.zoom = 1.0
		self.tile_size = config.get('tile_size', 16)
		
		# Grid settings
		self.show_grid = config.get('show_grid', True)
		self.grid_color = config.get('grid_color', (100, 100, 100))
		
		# Pan state
		self.panning = False
		self.pan_start = (0, 0)
		self.pan_camera_start = (0, 0)
	
	def update_bounds(self):
		"""Update window bounds based on screen size and UI panels"""
		toolbar_height = self.config.get('toolbar_height', 40)
		tileset_width = self.config.get('tileset_panel_width', 300)
		layer_width = self.config.get('layer_panel_width', 200)
		
		self.x = tileset_width
		self.y = toolbar_height
		self.width = self.screen.get_width() - tileset_width - layer_width
		self.height = self.screen.get_height() - toolbar_height
	
	def resize(self, width: int, height: int):
		"""Handle window resize"""
		self.update_bounds()
	
	def contains_point(self, pos: Tuple[int, int]) -> bool:
		"""Check if point is within main window"""
		x, y = pos
		return (self.x <= x < self.x + self.width and
				self.y <= y < self.y + self.height)
	
	def screen_to_map(self, screen_pos: Tuple[int, int]) -> Tuple[int, int]:
		"""Convert screen coordinates to map tile coordinates"""
		x, y = screen_pos
		
		# Adjust for window offset
		x -= self.x
		y -= self.y
		
		# Adjust for camera and zoom
		tile_size = self.tile_size * self.zoom
		map_x = int((x / tile_size) + self.camera_x)
		map_y = int((y / tile_size) + self.camera_y)
		
		return (map_x, map_y)
	
	def map_to_screen(self, map_pos: Tuple[int, int]) -> Tuple[int, int]:
		"""Convert map tile coordinates to screen coordinates"""
		map_x, map_y = map_pos
		
		tile_size = self.tile_size * self.zoom
		x = int((map_x - self.camera_x) * tile_size) + self.x
		y = int((map_y - self.camera_y) * tile_size) + self.y
		
		return (x, y)
	
	def set_zoom(self, zoom: float):
		"""Set zoom level"""
		self.zoom = max(0.25, min(4.0, zoom))
	
	def pan(self, screen_pos: Tuple[int, int]):
		"""Pan the camera"""
		if not self.panning:
			self.panning = True
			self.pan_start = screen_pos
			self.pan_camera_start = (self.camera_x, self.camera_y)
		else:
			dx = screen_pos[0] - self.pan_start[0]
			dy = screen_pos[1] - self.pan_start[1]
			
			tile_size = self.tile_size * self.zoom
			self.camera_x = self.pan_camera_start[0] - (dx / tile_size)
			self.camera_y = self.pan_camera_start[1] - (dy / tile_size)
	
	def end_pan(self):
		"""End panning"""
		self.panning = False
	
	def toggle_grid(self):
		"""Toggle grid display"""
		self.show_grid = not self.show_grid
	
	def update(self, delta_time: float):
		"""Update main window"""
		pass
	
	def render(self, screen: pygame.Surface, map_engine: MapEngine):
		"""Render the main map view"""
		# Draw background
		bg_color = self.config.get('bg_color', (40, 40, 40))
		pygame.draw.rect(screen, bg_color, 
						(self.x, self.y, self.width, self.height))
		
		# Draw map if available
		if map_engine.map_data is not None:
			self._render_map(screen, map_engine)
		
		# Draw border
		border_color = self.config.get('ui_border_color', (70, 70, 70))
		pygame.draw.rect(screen, border_color,
						(self.x, self.y, self.width, self.height), 1)
	
	def _render_map(self, screen: pygame.Surface, map_engine: MapEngine):
		"""Render the map layers"""
		tile_size = int(self.tile_size * self.zoom)
		
		# Calculate visible tile range
		start_x = max(0, int(self.camera_x))
		start_y = max(0, int(self.camera_y))
		end_x = min(map_engine.header.width, 
				   int(self.camera_x + self.width / tile_size) + 2)
		end_y = min(map_engine.header.height,
				   int(self.camera_y + self.height / tile_size) + 2)
		
		# Render each layer
		for layer in [LayerType.BG1_GROUND, LayerType.BG2_UPPER, 
					 LayerType.BG3_EVENTS]:
			self._render_layer(screen, map_engine, layer, 
							 start_x, start_y, end_x, end_y, tile_size)
		
		# Render grid
		if self.show_grid:
			self._render_grid(screen, start_x, start_y, end_x, end_y, tile_size)
	
	def _render_layer(self, screen: pygame.Surface, map_engine: MapEngine,
					 layer: LayerType, start_x: int, start_y: int,
					 end_x: int, end_y: int, tile_size: int):
		"""Render a single map layer"""
		layer_data = map_engine.map_data.get_layer(layer)
		
		# For now, render tiles as colored rectangles
		# TODO: Load and render actual tileset graphics
		for y in range(start_y, end_y):
			for x in range(start_x, end_x):
				tile_id = layer_data[y, x]
				
				if tile_id == 0 and layer != LayerType.BG1_GROUND:
					continue  # Skip empty tiles on upper layers
				
				screen_x, screen_y = self.map_to_screen((x, y))
				
				# Simple color coding by tile ID
				color = self._get_tile_color(tile_id, layer)
				
				pygame.draw.rect(screen, color,
							   (screen_x, screen_y, tile_size, tile_size))
	
	def _get_tile_color(self, tile_id: int, layer: LayerType) -> Tuple[int, int, int]:
		"""Get a color for a tile (placeholder for actual graphics)"""
		if tile_id == 0:
			return (30, 30, 30)  # Empty tile
		
		# Generate color based on tile ID
		r = (tile_id * 37) % 256
		g = (tile_id * 73) % 256
		b = (tile_id * 109) % 256
		
		# Adjust brightness based on layer
		if layer == LayerType.BG2_UPPER:
			r = min(255, r + 40)
			g = min(255, g + 40)
			b = min(255, b + 40)
		elif layer == LayerType.BG3_EVENTS:
			# Events layer - more transparent/faded
			r = r // 2
			g = g // 2
			b = b // 2
		
		return (r, g, b)
	
	def _render_grid(self, screen: pygame.Surface, start_x: int, start_y: int,
					end_x: int, end_y: int, tile_size: int):
		"""Render the grid overlay"""
		# Draw vertical lines
		for x in range(start_x, end_x + 1):
			screen_x, screen_y1 = self.map_to_screen((x, start_y))
			_, screen_y2 = self.map_to_screen((x, end_y))
			pygame.draw.line(screen, self.grid_color,
						   (screen_x, screen_y1),
						   (screen_x, screen_y2), 1)
		
		# Draw horizontal lines
		for y in range(start_y, end_y + 1):
			screen_x1, screen_y = self.map_to_screen((start_x, y))
			screen_x2, _ = self.map_to_screen((end_x, y))
			pygame.draw.line(screen, self.grid_color,
						   (screen_x1, screen_y),
						   (screen_x2, screen_y), 1)
