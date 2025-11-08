#!/usr/bin/env python3
"""
Tileset panel for tile selection
"""

import pygame
from typing import Tuple, Optional

class TilesetPanel:
	"""Panel for displaying and selecting tiles from the current tileset"""
	
	def __init__(self, screen: pygame.Surface, config):
		"""Initialize tileset panel"""
		self.screen = screen
		self.config = config
		
		self.width = config.get('tileset_panel_width', 300)
		self.x = 0
		self.y = config.get('toolbar_height', 40)
		self.height = screen.get_height() - self.y
		
		# Tileset display settings
		self.tile_size = 16  # Size to display tiles
		self.tiles_per_row = (self.width - 20) // (self.tile_size + 2)
		self.scroll_offset = 0
		
		# Selection
		self.selected_tile = 0
		self.hover_tile: Optional[int] = None
		
		# Colors
		self.bg_color = config.get('ui_bg_color', (50, 50, 50))
		self.border_color = config.get('ui_border_color', (70, 70, 70))
		self.selection_color = config.get('highlight_color', (100, 150, 255))
		self.text_color = config.get('text_color', (220, 220, 220))
		
		# Font
		pygame.font.init()
		self.font = pygame.font.SysFont('Arial', 14)
		self.title_font = pygame.font.SysFont('Arial', 16, bold=True)
		
		# Tileset data (256 tiles for now)
		self.tileset_size = 256
	
	def handle_event(self, event: pygame.event.Event):
		"""Handle pygame events"""
		if event.type == pygame.MOUSEMOTION:
			if self._is_over_panel(event.pos):
				self.hover_tile = self._get_tile_at_pos(event.pos)
			else:
				self.hover_tile = None
		
		elif event.type == pygame.MOUSEBUTTONDOWN:
			if event.button == 1:  # Left click
				if self._is_over_panel(event.pos):
					tile = self._get_tile_at_pos(event.pos)
					if tile is not None:
						self.select_tile(tile)
			
			elif event.button == 4:  # Scroll up
				if self._is_over_panel(event.pos):
					self.scroll_offset = max(0, self.scroll_offset - 1)
			
			elif event.button == 5:  # Scroll down
				if self._is_over_panel(event.pos):
					max_rows = (self.tileset_size + self.tiles_per_row - 1) // self.tiles_per_row
					visible_rows = (self.height - 60) // (self.tile_size + 2)
					max_scroll = max(0, max_rows - visible_rows)
					self.scroll_offset = min(max_scroll, self.scroll_offset + 1)
	
	def select_tile(self, tile_id: int):
		"""Select a tile"""
		if 0 <= tile_id < self.tileset_size:
			self.selected_tile = tile_id
	
	def _is_over_panel(self, pos: Tuple[int, int]) -> bool:
		"""Check if position is over this panel"""
		x, y = pos
		return (self.x <= x < self.x + self.width and
				self.y <= y < self.y + self.height)
	
	def _get_tile_at_pos(self, pos: Tuple[int, int]) -> Optional[int]:
		"""Get tile ID at mouse position"""
		x, y = pos
		
		# Adjust for panel position and title
		x -= self.x + 10
		y -= self.y + 40
		
		# Adjust for scroll
		y += self.scroll_offset * (self.tile_size + 2)
		
		if x < 0 or y < 0:
			return None
		
		# Calculate tile position
		col = x // (self.tile_size + 2)
		row = y // (self.tile_size + 2)
		
		if col >= self.tiles_per_row:
			return None
		
		tile_id = row * self.tiles_per_row + col
		
		if tile_id >= self.tileset_size:
			return None
		
		return tile_id
	
	def update(self, delta_time: float):
		"""Update tileset panel"""
		pass
	
	def render(self, screen: pygame.Surface):
		"""Render the tileset panel"""
		# Draw background
		pygame.draw.rect(screen, self.bg_color,
						(self.x, self.y, self.width, self.height))
		
		# Draw title
		title = "Tileset"
		title_surface = self.title_font.render(title, True, self.text_color)
		screen.blit(title_surface, (self.x + 10, self.y + 10))
		
		# Draw tiles
		self._render_tiles(screen)
		
		# Draw selected tile info
		self._render_tile_info(screen)
		
		# Draw border
		pygame.draw.rect(screen, self.border_color,
						(self.x, self.y, self.width, self.height), 2)
	
	def _render_tiles(self, screen: pygame.Surface):
		"""Render the tileset grid"""
		start_x = self.x + 10
		start_y = self.y + 40
		
		# Calculate visible range
		visible_rows = (self.height - 60) // (self.tile_size + 2)
		start_row = self.scroll_offset
		end_row = min((self.tileset_size + self.tiles_per_row - 1) // self.tiles_per_row,
					 start_row + visible_rows + 1)
		
		for row in range(start_row, end_row):
			for col in range(self.tiles_per_row):
				tile_id = row * self.tiles_per_row + col
				
				if tile_id >= self.tileset_size:
					break
				
				x = start_x + col * (self.tile_size + 2)
				y = start_y + (row - start_row) * (self.tile_size + 2)
				
				# Draw tile
				self._render_tile(screen, tile_id, x, y)
	
	def _render_tile(self, screen: pygame.Surface, tile_id: int, x: int, y: int):
		"""Render a single tile"""
		# Generate color for tile (placeholder)
		color = self._get_tile_color(tile_id)
		
		# Draw tile background
		pygame.draw.rect(screen, color, (x, y, self.tile_size, self.tile_size))
		
		# Draw selection highlight
		if tile_id == self.selected_tile:
			pygame.draw.rect(screen, self.selection_color,
						   (x, y, self.tile_size, self.tile_size), 2)
		
		# Draw hover highlight
		elif tile_id == self.hover_tile:
			pygame.draw.rect(screen, (150, 150, 150),
						   (x, y, self.tile_size, self.tile_size), 1)
		
		# Draw border
		pygame.draw.rect(screen, (80, 80, 80),
						(x, y, self.tile_size, self.tile_size), 1)
	
	def _get_tile_color(self, tile_id: int) -> Tuple[int, int, int]:
		"""Get placeholder color for a tile"""
		if tile_id == 0:
			return (30, 30, 30)  # Empty tile
		
		# Generate color based on tile ID
		r = (tile_id * 37) % 256
		g = (tile_id * 73) % 256
		b = (tile_id * 109) % 256
		
		return (r, g, b)
	
	def _render_tile_info(self, screen: pygame.Surface):
		"""Render information about selected tile"""
		info_y = self.y + self.height - 60
		
		# Draw separator
		pygame.draw.line(screen, self.border_color,
						(self.x + 5, info_y - 5),
						(self.x + self.width - 5, info_y - 5), 1)
		
		# Draw tile ID
		info_text = f"Tile: #{self.selected_tile:02X} ({self.selected_tile})"
		info_surface = self.font.render(info_text, True, self.text_color)
		screen.blit(info_surface, (self.x + 10, info_y))
		
		# Draw tile preview (larger)
		preview_size = 32
		preview_x = self.x + self.width - preview_size - 10
		preview_y = info_y
		
		color = self._get_tile_color(self.selected_tile)
		pygame.draw.rect(screen, color,
						(preview_x, preview_y, preview_size, preview_size))
		pygame.draw.rect(screen, self.border_color,
						(preview_x, preview_y, preview_size, preview_size), 1)
