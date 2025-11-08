#!/usr/bin/env python3
"""
Properties panel for map and tile properties
"""

import pygame
from typing import Tuple, Optional, Dict, Any

class PropertiesPanel:
	"""Panel for displaying and editing properties"""
	
	def __init__(self, screen: pygame.Surface, config):
		"""Initialize properties panel"""
		self.screen = screen
		self.config = config
		
		toolbar_height = config.get('toolbar_height', 40)
		layer_width = config.get('layer_panel_width', 200)
		
		self.width = config.get('properties_panel_width', 250)
		self.x = screen.get_width() - layer_width - self.width
		self.y = toolbar_height
		self.height = 300  # Fixed height at top
		
		# Colors
		self.bg_color = config.get('ui_bg_color', (50, 50, 50))
		self.border_color = config.get('ui_border_color', (70, 70, 70))
		self.text_color = config.get('text_color', (220, 220, 220))
		self.label_color = (180, 180, 180)
		
		# Font
		pygame.font.init()
		self.font = pygame.font.SysFont('Arial', 12)
		self.title_font = pygame.font.SysFont('Arial', 14, bold=True)
		
		# Property data
		self.map_properties: Dict[str, Any] = {}
		self.tile_properties: Dict[str, Any] = {}
	
	def set_map_properties(self, properties: Dict[str, Any]):
		"""Set map properties to display"""
		self.map_properties = properties
	
	def set_tile_properties(self, properties: Dict[str, Any]):
		"""Set tile properties to display"""
		self.tile_properties = properties
	
	def handle_event(self, event: pygame.event.Event):
		"""Handle pygame events"""
		# TODO: Add property editing functionality
		pass
	
	def update(self, delta_time: float):
		"""Update properties panel"""
		pass
	
	def render(self, screen: pygame.Surface):
		"""Render the properties panel"""
		# Draw background
		pygame.draw.rect(screen, self.bg_color,
						(self.x, self.y, self.width, self.height))
		
		# Draw title
		title = "Properties"
		title_surface = self.title_font.render(title, True, self.text_color)
		screen.blit(title_surface, (self.x + 10, self.y + 10))
		
		# Draw map properties
		y_offset = self.y + 35
		y_offset = self._render_section(screen, "Map", self.map_properties, y_offset)
		
		# Draw separator
		pygame.draw.line(screen, self.border_color,
						(self.x + 10, y_offset),
						(self.x + self.width - 10, y_offset), 1)
		y_offset += 10
		
		# Draw tile properties
		self._render_section(screen, "Tile", self.tile_properties, y_offset)
		
		# Draw border
		pygame.draw.rect(screen, self.border_color,
						(self.x, self.y, self.width, self.height), 2)
	
	def _render_section(self, screen: pygame.Surface, title: str,
					   properties: Dict[str, Any], y_offset: int) -> int:
		"""Render a property section"""
		# Section title
		section_surface = self.title_font.render(title, True, self.text_color)
		screen.blit(section_surface, (self.x + 10, y_offset))
		y_offset += 25
		
		# Properties
		if not properties:
			no_data = self.font.render("No data", True, self.label_color)
			screen.blit(no_data, (self.x + 15, y_offset))
			y_offset += 20
		else:
			for key, value in properties.items():
				y_offset = self._render_property(screen, key, value, y_offset)
		
		return y_offset + 10
	
	def _render_property(self, screen: pygame.Surface, key: str, value: Any,
						y_offset: int) -> int:
		"""Render a single property"""
		# Key (label)
		key_surface = self.font.render(f"{key}:", True, self.label_color)
		screen.blit(key_surface, (self.x + 15, y_offset))
		
		# Value
		value_str = str(value)
		value_surface = self.font.render(value_str, True, self.text_color)
		screen.blit(value_surface, (self.x + 120, y_offset))
		
		return y_offset + 18
