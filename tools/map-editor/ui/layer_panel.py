#!/usr/bin/env python3
"""
Layer panel for layer selection and visibility control
"""

import pygame
from typing import Tuple, Optional
from engine.map_engine import LayerType

class Layer:
	"""Represents a map layer"""
	
	def __init__(self, layer_type: LayerType, name: str, visible: bool = True):
		"""Initialize layer"""
		self.layer_type = layer_type
		self.name = name
		self.visible = visible
		self.locked = False

class LayerPanel:
	"""Panel for layer management"""
	
	def __init__(self, screen: pygame.Surface, config):
		"""Initialize layer panel"""
		self.screen = screen
		self.config = config
		
		toolbar_height = config.get('toolbar_height', 40)
		tileset_width = config.get('tileset_panel_width', 300)
		
		self.width = config.get('layer_panel_width', 200)
		self.x = screen.get_width() - self.width
		self.y = toolbar_height
		self.height = screen.get_height() - toolbar_height
		
		# Layers
		self.layers = [
			Layer(LayerType.BG1_GROUND, "Ground (BG1)", True),
			Layer(LayerType.BG2_UPPER, "Upper (BG2)", True),
			Layer(LayerType.BG3_EVENTS, "Events (BG3)", True),
		]
		self.current_layer = self.layers[0]
		
		# Colors
		self.bg_color = config.get('ui_bg_color', (50, 50, 50))
		self.border_color = config.get('ui_border_color', (70, 70, 70))
		self.selection_color = config.get('highlight_color', (100, 150, 255))
		self.text_color = config.get('text_color', (220, 220, 220))
		
		# Font
		pygame.font.init()
		self.font = pygame.font.SysFont('Arial', 14)
		self.title_font = pygame.font.SysFont('Arial', 16, bold=True)
		
		# UI elements
		self.layer_height = 40
		self.hover_layer: Optional[Layer] = None
	
	def handle_event(self, event: pygame.event.Event):
		"""Handle pygame events"""
		if event.type == pygame.MOUSEMOTION:
			if self._is_over_panel(event.pos):
				self.hover_layer = self._get_layer_at_pos(event.pos)
			else:
				self.hover_layer = None
		
		elif event.type == pygame.MOUSEBUTTONDOWN:
			if event.button == 1:  # Left click
				if self._is_over_panel(event.pos):
					layer = self._get_layer_at_pos(event.pos)
					if layer:
						# Check if clicked on visibility toggle
						if self._is_over_visibility_button(event.pos, layer):
							layer.visible = not layer.visible
						# Check if clicked on lock button
						elif self._is_over_lock_button(event.pos, layer):
							layer.locked = not layer.locked
						else:
							self.select_layer(layer)
	
	def select_layer(self, layer: Layer):
		"""Select a layer"""
		self.current_layer = layer
	
	def get_current_layer_type(self) -> LayerType:
		"""Get the currently selected layer type"""
		return self.current_layer.layer_type
	
	def _is_over_panel(self, pos: Tuple[int, int]) -> bool:
		"""Check if position is over this panel"""
		x, y = pos
		return (self.x <= x < self.x + self.width and
				self.y <= y < self.y + self.height)
	
	def _get_layer_at_pos(self, pos: Tuple[int, int]) -> Optional[Layer]:
		"""Get layer at mouse position"""
		x, y = pos
		
		# Adjust for panel position and title
		y -= self.y + 40
		
		if y < 0:
			return None
		
		layer_index = y // self.layer_height
		
		if layer_index >= len(self.layers):
			return None
		
		return self.layers[layer_index]
	
	def _is_over_visibility_button(self, pos: Tuple[int, int], 
								   layer: Layer) -> bool:
		"""Check if mouse is over visibility button"""
		layer_index = self.layers.index(layer)
		button_x = self.x + self.width - 60
		button_y = self.y + 40 + layer_index * self.layer_height + 10
		
		x, y = pos
		return (button_x <= x < button_x + 20 and
				button_y <= y < button_y + 20)
	
	def _is_over_lock_button(self, pos: Tuple[int, int], layer: Layer) -> bool:
		"""Check if mouse is over lock button"""
		layer_index = self.layers.index(layer)
		button_x = self.x + self.width - 35
		button_y = self.y + 40 + layer_index * self.layer_height + 10
		
		x, y = pos
		return (button_x <= x < button_x + 20 and
				button_y <= y < button_y + 20)
	
	def update(self, delta_time: float):
		"""Update layer panel"""
		pass
	
	def render(self, screen: pygame.Surface):
		"""Render the layer panel"""
		# Draw background
		pygame.draw.rect(screen, self.bg_color,
						(self.x, self.y, self.width, self.height))
		
		# Draw title
		title = "Layers"
		title_surface = self.title_font.render(title, True, self.text_color)
		screen.blit(title_surface, (self.x + 10, self.y + 10))
		
		# Draw layers
		for i, layer in enumerate(self.layers):
			self._render_layer(screen, layer, i)
		
		# Draw border
		pygame.draw.rect(screen, self.border_color,
						(self.x, self.y, self.width, self.height), 2)
	
	def _render_layer(self, screen: pygame.Surface, layer: Layer, index: int):
		"""Render a single layer entry"""
		y = self.y + 40 + index * self.layer_height
		
		# Draw background (highlight if selected or hovered)
		if layer == self.current_layer:
			bg_color = self.selection_color
		elif layer == self.hover_layer:
			bg_color = (70, 70, 70)
		else:
			bg_color = (60, 60, 60)
		
		pygame.draw.rect(screen, bg_color,
						(self.x + 5, y, self.width - 10, self.layer_height - 2))
		
		# Draw layer name
		name_surface = self.font.render(layer.name, True, self.text_color)
		screen.blit(name_surface, (self.x + 10, y + 12))
		
		# Draw visibility button (eye icon)
		vis_x = self.x + self.width - 60
		vis_y = y + 10
		self._render_button(screen, vis_x, vis_y, 
						  '👁' if layer.visible else '⚫',
						  layer.visible)
		
		# Draw lock button
		lock_x = self.x + self.width - 35
		lock_y = y + 10
		self._render_button(screen, lock_x, lock_y,
						  '🔒' if layer.locked else '🔓',
						  not layer.locked)
		
		# Draw border
		pygame.draw.rect(screen, self.border_color,
						(self.x + 5, y, self.width - 10, self.layer_height - 2), 1)
	
	def _render_button(self, screen: pygame.Surface, x: int, y: int,
					  icon: str, active: bool):
		"""Render a small button"""
		size = 20
		
		# Draw button background
		color = (80, 80, 80) if active else (50, 50, 50)
		pygame.draw.rect(screen, color, (x, y, size, size))
		pygame.draw.rect(screen, self.border_color, (x, y, size, size), 1)
		
		# Draw icon
		icon_surface = self.font.render(icon, True, self.text_color)
		icon_rect = icon_surface.get_rect()
		icon_rect.center = (x + size // 2, y + size // 2)
		screen.blit(icon_surface, icon_rect)
