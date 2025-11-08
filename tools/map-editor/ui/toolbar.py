#!/usr/bin/env python3
"""
Toolbar component for tool selection
"""

import pygame
from typing import Tuple, List, Optional

class Tool:
	"""Represents a toolbar tool"""
	
	def __init__(self, name: str, icon: str, hotkey: str, tooltip: str):
		"""Initialize tool"""
		self.name = name
		self.icon = icon
		self.hotkey = hotkey
		self.tooltip = tooltip
		self.active = False

class Toolbar:
	"""Toolbar for tool and action selection"""
	
	TOOLS = [
		Tool('pencil', '✏', 'P', 'Pencil - Draw individual tiles'),
		Tool('bucket', '🪣', 'B', 'Bucket - Flood fill'),
		Tool('eraser', '⌫', 'E', 'Eraser - Remove tiles'),
		Tool('rectangle', '▭', 'R', 'Rectangle - Draw filled rectangles'),
		Tool('line', '/', 'L', 'Line - Draw lines'),
		Tool('select', '⬚', 'S', 'Select - Select and move tiles'),
		Tool('eyedropper', '💧', 'I', 'Eyedropper - Pick tile'),
	]
	
	def __init__(self, screen: pygame.Surface, config):
		"""Initialize toolbar"""
		self.screen = screen
		self.config = config
		
		self.height = config.get('toolbar_height', 40)
		self.x = 0
		self.y = 0
		self.width = screen.get_width()
		
		self.tools = self.TOOLS.copy()
		self.current_tool = self.tools[0]  # Default to pencil
		self.current_tool.active = True
		
		# Button size and spacing
		self.button_size = 32
		self.button_spacing = 4
		
		# Colors
		self.bg_color = config.get('ui_bg_color', (50, 50, 50))
		self.border_color = config.get('ui_border_color', (70, 70, 70))
		self.button_color = (60, 60, 60)
		self.button_hover_color = (80, 80, 80)
		self.button_active_color = (100, 150, 255)
		self.text_color = config.get('text_color', (220, 220, 220))
		
		# Font
		pygame.font.init()
		self.font = pygame.font.SysFont('Arial', 20)
		self.small_font = pygame.font.SysFont('Arial', 12)
		
		# Hover state
		self.hover_tool: Optional[Tool] = None
	
	def handle_event(self, event: pygame.event.Event):
		"""Handle pygame events"""
		if event.type == pygame.MOUSEMOTION:
			self.hover_tool = self._get_tool_at_pos(event.pos)
		
		elif event.type == pygame.MOUSEBUTTONDOWN:
			if event.button == 1:  # Left click
				tool = self._get_tool_at_pos(event.pos)
				if tool:
					self.select_tool(tool)
	
	def select_tool(self, tool: Tool):
		"""Select a tool"""
		if self.current_tool:
			self.current_tool.active = False
		self.current_tool = tool
		self.current_tool.active = True
	
	def _get_tool_at_pos(self, pos: Tuple[int, int]) -> Optional[Tool]:
		"""Get tool at mouse position"""
		x, y = pos
		
		if not (self.y <= y < self.y + self.height):
			return None
		
		# Calculate which tool button was clicked
		start_x = 10
		for i, tool in enumerate(self.tools):
			button_x = start_x + i * (self.button_size + self.button_spacing)
			button_y = (self.height - self.button_size) // 2
			
			if (button_x <= x < button_x + self.button_size and
				button_y <= y < button_y + self.button_size):
				return tool
		
		return None
	
	def update(self, delta_time: float):
		"""Update toolbar"""
		pass
	
	def render(self, screen: pygame.Surface):
		"""Render the toolbar"""
		# Draw background
		pygame.draw.rect(screen, self.bg_color,
						(self.x, self.y, self.width, self.height))
		
		# Draw tool buttons
		start_x = 10
		for i, tool in enumerate(self.tools):
			button_x = start_x + i * (self.button_size + self.button_spacing)
			button_y = (self.height - self.button_size) // 2
			
			self._render_tool_button(screen, tool, button_x, button_y)
		
		# Draw separator
		separator_x = start_x + len(self.tools) * (self.button_size + self.button_spacing) + 10
		pygame.draw.line(screen, self.border_color,
						(separator_x, 5), (separator_x, self.height - 5), 2)
		
		# Draw file actions
		action_x = separator_x + 20
		self._render_actions(screen, action_x)
		
		# Draw tooltip if hovering
		if self.hover_tool:
			self._render_tooltip(screen, self.hover_tool)
		
		# Draw border
		pygame.draw.rect(screen, self.border_color,
						(self.x, self.y, self.width, self.height), 1)
	
	def _render_tool_button(self, screen: pygame.Surface, tool: Tool,
						   x: int, y: int):
		"""Render a tool button"""
		# Determine button color
		if tool.active:
			color = self.button_active_color
		elif tool == self.hover_tool:
			color = self.button_hover_color
		else:
			color = self.button_color
		
		# Draw button background
		pygame.draw.rect(screen, color, (x, y, self.button_size, self.button_size))
		pygame.draw.rect(screen, self.border_color,
						(x, y, self.button_size, self.button_size), 1)
		
		# Draw icon (centered)
		icon_surface = self.font.render(tool.icon, True, self.text_color)
		icon_rect = icon_surface.get_rect()
		icon_rect.center = (x + self.button_size // 2, y + self.button_size // 2)
		screen.blit(icon_surface, icon_rect)
		
		# Draw hotkey (bottom right corner)
		if tool.hotkey:
			hotkey_surface = self.small_font.render(tool.hotkey, True, 
													(150, 150, 150))
			screen.blit(hotkey_surface, (x + self.button_size - 15, 
										y + self.button_size - 12))
	
	def _render_actions(self, screen: pygame.Surface, x: int):
		"""Render file action buttons"""
		actions = [
			('New', 'Ctrl+N'),
			('Open', 'Ctrl+O'),
			('Save', 'Ctrl+S'),
		]
		
		for i, (name, hotkey) in enumerate(actions):
			button_x = x + i * 80
			button_y = (self.height - 30) // 2
			
			# Draw button
			pygame.draw.rect(screen, self.button_color,
						   (button_x, button_y, 70, 30))
			pygame.draw.rect(screen, self.border_color,
						   (button_x, button_y, 70, 30), 1)
			
			# Draw text
			text_surface = self.small_font.render(name, True, self.text_color)
			text_rect = text_surface.get_rect()
			text_rect.center = (button_x + 35, button_y + 15)
			screen.blit(text_surface, text_rect)
	
	def _render_tooltip(self, screen: pygame.Surface, tool: Tool):
		"""Render tooltip for hovered tool"""
		mouse_x, mouse_y = pygame.mouse.get_pos()
		
		# Create tooltip surface
		tooltip_text = f"{tool.tooltip} ({tool.hotkey})"
		tooltip_surface = self.small_font.render(tooltip_text, True, 
												self.text_color)
		tooltip_rect = tooltip_surface.get_rect()
		
		# Position below mouse
		tooltip_x = mouse_x + 10
		tooltip_y = mouse_y + 20
		
		# Adjust if would go off screen
		if tooltip_x + tooltip_rect.width > self.width:
			tooltip_x = mouse_x - tooltip_rect.width - 10
		
		# Draw background
		padding = 5
		pygame.draw.rect(screen, (40, 40, 40),
						(tooltip_x - padding, tooltip_y - padding,
						 tooltip_rect.width + padding * 2,
						 tooltip_rect.height + padding * 2))
		pygame.draw.rect(screen, self.border_color,
						(tooltip_x - padding, tooltip_y - padding,
						 tooltip_rect.width + padding * 2,
						 tooltip_rect.height + padding * 2), 1)
		
		# Draw text
		screen.blit(tooltip_surface, (tooltip_x, tooltip_y))
