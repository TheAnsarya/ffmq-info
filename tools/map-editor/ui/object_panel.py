#!/usr/bin/env python3
"""
NPC and object placement panel for FFMQ Map Editor
Allows placing NPCs, chests, warps, and other map objects
"""

import pygame
from typing import Optional, Tuple, List, Dict
from enum import IntEnum
from dataclasses import dataclass


class ObjectType(IntEnum):
	"""Map object types"""
	NPC = 0
	CHEST = 1
	WARP = 2
	TRIGGER = 3
	SPAWN_POINT = 4
	SAVE_POINT = 5
	INN = 6
	SHOP = 7


@dataclass
class MapObject:
	"""Represents an object on the map"""
	obj_type: ObjectType
	x: int
	y: int
	id: int = 0
	sprite_id: int = 0
	dialogue_id: int = 0
	item_id: int = 0
	dest_map: int = 0
	dest_x: int = 0
	dest_y: int = 0
	flags: int = 0

	def to_dict(self) -> dict:
		"""Convert to dictionary"""
		return {
			'type': self.obj_type.name,
			'x': self.x,
			'y': self.y,
			'id': self.id,
			'sprite_id': self.sprite_id,
			'dialogue_id': self.dialogue_id,
			'item_id': self.item_id,
			'dest_map': self.dest_map,
			'dest_x': self.dest_x,
			'dest_y': self.dest_y,
			'flags': self.flags
		}

	@staticmethod
	def from_dict(data: dict) -> 'MapObject':
		"""Create from dictionary"""
		return MapObject(
			obj_type=ObjectType[data.get('type', 'NPC')],
			x=data.get('x', 0),
			y=data.get('y', 0),
			id=data.get('id', 0),
			sprite_id=data.get('sprite_id', 0),
			dialogue_id=data.get('dialogue_id', 0),
			item_id=data.get('item_id', 0),
			dest_map=data.get('dest_map', 0),
			dest_x=data.get('dest_x', 0),
			dest_y=data.get('dest_y', 0),
			flags=data.get('flags', 0)
		)


class ObjectPanel:
	"""Panel for placing and editing map objects"""

	def __init__(self, x: int, y: int, width: int, height: int):
		"""
		Initialize object panel

		Args:
			x, y: Panel position
			width, height: Panel dimensions
		"""
		self.rect = pygame.Rect(x, y, width, height)
		self.surface = pygame.Surface((width, height))

		# Colors
		self.bg_color = (45, 45, 45)
		self.border_color = (100, 100, 100)
		self.text_color = (220, 220, 220)
		self.selected_color = (100, 150, 255)
		self.hover_color = (70, 70, 70)

		# Object types
		self.object_types = [
			('NPC', ObjectType.NPC, '👤'),
			('Chest', ObjectType.CHEST, '📦'),
			('Warp', ObjectType.WARP, '🚪'),
			('Trigger', ObjectType.TRIGGER, '⚡'),
			('Spawn', ObjectType.SPAWN_POINT, '🎯'),
			('Save', ObjectType.SAVE_POINT, '💾'),
			('Inn', ObjectType.INN, '🛏️'),
			('Shop', ObjectType.SHOP, '🏪')
		]

		# Selected object type
		self.selected_type: Optional[ObjectType] = ObjectType.NPC

		# Object buttons
		self.buttons: List[pygame.Rect] = []
		self._create_buttons()

		# Hover state
		self.hover_button: Optional[int] = None

		# Selected object for editing
		self.selected_object: Optional[MapObject] = None

	def _create_buttons(self):
		"""Create object type buttons"""
		button_height = 40
		button_padding = 5
		y_offset = 40

		for i, (name, obj_type, icon) in enumerate(self.object_types):
			button_rect = pygame.Rect(
				10,
				y_offset + i * (button_height + button_padding),
				self.rect.width - 20,
				button_height
			)
			self.buttons.append(button_rect)

	def handle_mouse_down(self, pos: Tuple[int, int], button: int) -> bool:
		"""
		Handle mouse down event

		Args:
			pos: Mouse position
			button: Mouse button

		Returns:
			True if event was handled
		"""
		if not self.rect.collidepoint(pos):
			return False

		# Convert to panel-relative coordinates
		rel_pos = (pos[0] - self.rect.x, pos[1] - self.rect.y)

		# Check button clicks
		for i, button_rect in enumerate(self.buttons):
			if button_rect.collidepoint(rel_pos):
				self.selected_type = self.object_types[i][1]
				return True

		return False

	def handle_mouse_motion(self, pos: Tuple[int, int]):
		"""Handle mouse motion event"""
		if not self.rect.collidepoint(pos):
			self.hover_button = None
			return

		# Convert to panel-relative coordinates
		rel_pos = (pos[0] - self.rect.x, pos[1] - self.rect.y)

		# Check button hover
		self.hover_button = None
		for i, button_rect in enumerate(self.buttons):
			if button_rect.collidepoint(rel_pos):
				self.hover_button = i
				break

	def get_selected_type(self) -> Optional[ObjectType]:
		"""Get currently selected object type"""
		return self.selected_type

	def select_object(self, obj: Optional[MapObject]):
		"""Select an object for editing"""
		self.selected_object = obj
		if obj:
			self.selected_type = obj.obj_type

	def render(self, screen: pygame.Surface):
		"""Render object panel"""
		# Clear panel
		self.surface.fill(self.bg_color)

		# Draw title
		font_title = pygame.font.Font(None, 24)
		title = font_title.render("Objects", True, self.text_color)
		self.surface.blit(title, (10, 10))

		# Draw object type buttons
		font_button = pygame.font.Font(None, 20)

		for i, (button_rect, (name, obj_type, icon)) in enumerate(
			zip(self.buttons, self.object_types)
		):
			# Determine button color
			if obj_type == self.selected_type:
				button_color = self.selected_color
			elif i == self.hover_button:
				button_color = self.hover_color
			else:
				button_color = (60, 60, 60)

			# Draw button background
			pygame.draw.rect(self.surface, button_color, button_rect)
			pygame.draw.rect(self.surface, self.border_color, button_rect, 1)

			# Draw icon
			icon_text = font_button.render(icon, True, self.text_color)
			self.surface.blit(icon_text, (button_rect.x + 10, button_rect.y + 10))

			# Draw name
			name_text = font_button.render(name, True, self.text_color)
			self.surface.blit(name_text, (button_rect.x + 40, button_rect.y + 10))

		# Draw selected object properties
		if self.selected_object:
			self._render_properties()

		# Draw border
		pygame.draw.rect(self.surface, self.border_color,
						self.surface.get_rect(), 2)

		# Blit to screen
		screen.blit(self.surface, self.rect)

	def _render_properties(self):
		"""Render properties of selected object"""
		y_offset = len(self.buttons) * 45 + 60

		font = pygame.font.Font(None, 18)

		# Title
		title = font.render("Selected Object:", True, (255, 255, 255))
		self.surface.blit(title, (10, y_offset))
		y_offset += 25

		# Type
		type_text = f"Type: {self.selected_object.obj_type.name}"
		text = font.render(type_text, True, self.text_color)
		self.surface.blit(text, (10, y_offset))
		y_offset += 20

		# Position
		pos_text = f"Position: ({self.selected_object.x}, {self.selected_object.y})"
		text = font.render(pos_text, True, self.text_color)
		self.surface.blit(text, (10, y_offset))
		y_offset += 20

		# Type-specific properties
		if self.selected_object.obj_type == ObjectType.NPC:
			sprite_text = f"Sprite ID: {self.selected_object.sprite_id}"
			text = font.render(sprite_text, True, self.text_color)
			self.surface.blit(text, (10, y_offset))
			y_offset += 20

			dialogue_text = f"Dialogue: {self.selected_object.dialogue_id}"
			text = font.render(dialogue_text, True, self.text_color)
			self.surface.blit(text, (10, y_offset))
			y_offset += 20

		elif self.selected_object.obj_type == ObjectType.CHEST:
			item_text = f"Item ID: {self.selected_object.item_id}"
			text = font.render(item_text, True, self.text_color)
			self.surface.blit(text, (10, y_offset))
			y_offset += 20

		elif self.selected_object.obj_type == ObjectType.WARP:
			dest_text = f"Dest Map: {self.selected_object.dest_map}"
			text = font.render(dest_text, True, self.text_color)
			self.surface.blit(text, (10, y_offset))
			y_offset += 20

			dest_pos = f"Dest Pos: ({self.selected_object.dest_x}, {self.selected_object.dest_y})"
			text = font.render(dest_pos, True, self.text_color)
			self.surface.blit(text, (10, y_offset))
			y_offset += 20

	def contains_point(self, pos: Tuple[int, int]) -> bool:
		"""Check if position is inside panel"""
		return self.rect.collidepoint(pos)


class ObjectRenderer:
	"""Renders map objects on the main map view"""

	# Object colors (for placeholder rendering)
	OBJECT_COLORS = {
		ObjectType.NPC: (100, 150, 255),
		ObjectType.CHEST: (255, 215, 0),
		ObjectType.WARP: (255, 100, 255),
		ObjectType.TRIGGER: (255, 165, 0),
		ObjectType.SPAWN_POINT: (0, 255, 0),
		ObjectType.SAVE_POINT: (0, 255, 255),
		ObjectType.INN: (255, 192, 203),
		ObjectType.SHOP: (160, 82, 45)
	}

	@staticmethod
	def render_object(screen: pygame.Surface, obj: MapObject,
					 screen_x: int, screen_y: int, tile_size: int,
					 selected: bool = False):
		"""
		Render a map object

		Args:
			screen: Target surface
			obj: Map object to render
			screen_x, screen_y: Screen coordinates
			tile_size: Size of tile in pixels
			selected: Whether object is selected
		"""
		# Get object color
		color = ObjectRenderer.OBJECT_COLORS.get(obj.obj_type, (255, 255, 255))

		# Draw object circle
		center_x = screen_x + tile_size // 2
		center_y = screen_y + tile_size // 2
		radius = tile_size // 3

		pygame.draw.circle(screen, color, (center_x, center_y), radius)

		# Draw border
		border_color = (255, 255, 0) if selected else (0, 0, 0)
		pygame.draw.circle(screen, border_color, (center_x, center_y), radius, 2)

		# Draw type indicator (first letter)
		font = pygame.font.Font(None, max(12, tile_size // 2))
		type_char = obj.obj_type.name[0]
		text = font.render(type_char, True, (0, 0, 0))
		text_rect = text.get_rect(center=(center_x, center_y))
		screen.blit(text, text_rect)

	@staticmethod
	def get_object_at_pos(objects: List[MapObject], map_x: int, map_y: int) -> Optional[MapObject]:
		"""
		Find object at map position

		Args:
			objects: List of map objects
			map_x, map_y: Map coordinates

		Returns:
			Object at position, or None
		"""
		for obj in objects:
			if obj.x == map_x and obj.y == map_y:
				return obj
		return None
