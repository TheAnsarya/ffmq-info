"""
Map Event Editor for FFMQ
Visual editor for placing and configuring map events, triggers, NPCs, and items
"""

import pygame
from typing import Optional, List, Tuple, Dict
from dataclasses import dataclass
from enum import IntEnum


# Colors
COLOR_BG = (30, 35, 40)
COLOR_PANEL = (45, 50, 55)
COLOR_PANEL_LIGHT = (60, 65, 70)
COLOR_BORDER = (90, 95, 100)
COLOR_TEXT = (210, 215, 220)
COLOR_GRID = (70, 75, 80)
COLOR_SELECTED = (90, 130, 200)
COLOR_EVENT_NPC = (100, 200, 100)
COLOR_EVENT_TREASURE = (220, 180, 50)
COLOR_EVENT_WARP = (200, 100, 200)
COLOR_EVENT_TRIGGER = (200, 100, 100)
COLOR_EVENT_SIGN = (150, 150, 220)


class EventType(IntEnum):
	"""Map event types"""
	NPC = 0
	TREASURE = 1
	WARP = 2
	TRIGGER = 3
	SIGN = 4
	DOOR = 5
	CHEST = 6
	SWITCH = 7
	CUTSCENE = 8


class TriggerCondition(IntEnum):
	"""Event trigger conditions"""
	ALWAYS = 0
	ONCE = 1
	FLAG_SET = 2
	FLAG_CLEAR = 3
	ITEM_HAVE = 4
	ITEM_NOT_HAVE = 5
	PARTY_SIZE = 6
	STORY_PROGRESS = 7


@dataclass
class MapEvent:
	"""Map event data"""
	event_id: int
	event_type: EventType
	x: int
	y: int
	sprite_id: int = 0
	dialog_id: int = 0
	item_id: int = 0
	warp_map: int = 0
	warp_x: int = 0
	warp_y: int = 0
	trigger_condition: TriggerCondition = TriggerCondition.ALWAYS
	trigger_flag: int = 0
	trigger_value: int = 0
	script_offset: int = 0
	enabled: bool = True
	name: str = ""

	def get_color(self) -> Tuple[int, int, int]:
		"""Get event color for display"""
		color_map = {
			EventType.NPC: COLOR_EVENT_NPC,
			EventType.TREASURE: COLOR_EVENT_TREASURE,
			EventType.WARP: COLOR_EVENT_WARP,
			EventType.TRIGGER: COLOR_EVENT_TRIGGER,
			EventType.SIGN: COLOR_EVENT_SIGN,
			EventType.DOOR: COLOR_EVENT_WARP,
			EventType.CHEST: COLOR_EVENT_TREASURE,
			EventType.SWITCH: COLOR_EVENT_TRIGGER,
			EventType.CUTSCENE: COLOR_EVENT_TRIGGER,
		}
		return color_map.get(self.event_type, COLOR_TEXT)


class EventPropertyPanel:
	"""Panel for editing event properties"""
	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.event: Optional[MapEvent] = None

	def set_event(self, event: MapEvent):
		"""Set event to edit"""
		self.event = event

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw property panel"""
		pygame.draw.rect(surface, COLOR_PANEL, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 2)

		if not self.event:
			no_event = font.render("No event selected", True, COLOR_TEXT)
			surface.blit(no_event, (self.rect.x + 10, self.rect.y + 10))
			return

		# Title
		title = font.render(f"Event {self.event.event_id}: {self.event.name or 'Unnamed'}", True, COLOR_TEXT)
		surface.blit(title, (self.rect.x + 10, self.rect.y + 10))

		# Properties
		y_offset = self.rect.y + 50
		properties = [
			f"Type: {self.event.event_type.name}",
			f"Position: ({self.event.x}, {self.event.y})",
			f"Sprite ID: {self.event.sprite_id}",
			f"Dialog ID: {self.event.dialog_id}" if self.event.dialog_id else "",
			f"Item ID: {self.event.item_id}" if self.event.item_id else "",
			f"Warp: Map {self.event.warp_map} ({self.event.warp_x}, {self.event.warp_y})" if self.event.warp_map else "",
			f"Trigger: {self.event.trigger_condition.name}",
			f"Flag: {self.event.trigger_flag}" if self.event.trigger_flag else "",
			f"Enabled: {'Yes' if self.event.enabled else 'No'}",
		]

		for prop in properties:
			if prop:  # Skip empty properties
				prop_surf = font.render(prop, True, COLOR_TEXT)
				surface.blit(prop_surf, (self.rect.x + 15, y_offset))
				y_offset += 25


class EventPalette:
	"""Palette of event types to place"""
	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.selected_type = EventType.NPC
		self.event_types = list(EventType)

	def update(self, mouse_pos: Tuple[int, int], mouse_clicked: bool) -> Optional[EventType]:
		"""Update palette, return selected type if clicked"""
		if not self.rect.collidepoint(mouse_pos):
			return None

		if mouse_clicked:
			rel_y = mouse_pos[1] - self.rect.y - 40
			idx = rel_y // 35
			if 0 <= idx < len(self.event_types):
				self.selected_type = self.event_types[idx]
				return self.selected_type

		return None

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw event palette"""
		pygame.draw.rect(surface, COLOR_PANEL, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 2)

		# Title
		title = font.render("Event Types", True, COLOR_TEXT)
		surface.blit(title, (self.rect.x + 10, self.rect.y + 10))

		# Event types
		y_offset = self.rect.y + 40
		for i, event_type in enumerate(self.event_types):
			item_rect = pygame.Rect(self.rect.x + 5, y_offset, self.rect.width - 10, 30)
			
			# Background
			if event_type == self.selected_type:
				pygame.draw.rect(surface, COLOR_SELECTED, item_rect)
			
			pygame.draw.rect(surface, COLOR_BORDER, item_rect, 1)

			# Color indicator
			event = MapEvent(0, event_type, 0, 0)
			color_rect = pygame.Rect(self.rect.x + 10, y_offset + 5, 20, 20)
			pygame.draw.rect(surface, event.get_color(), color_rect)
			pygame.draw.rect(surface, COLOR_BORDER, color_rect, 1)

			# Name
			name_surf = font.render(event_type.name, True, COLOR_TEXT)
			surface.blit(name_surf, (self.rect.x + 40, y_offset + 7))

			y_offset += 35


class MapCanvas:
	"""Interactive map canvas for placing events"""
	def __init__(self, x: int, y: int, width: int, height: int, map_width: int = 32, map_height: int = 32):
		self.rect = pygame.Rect(x, y, width, height)
		self.map_width = map_width
		self.map_height = map_height
		self.tile_size = 20
		self.scroll_x = 0
		self.scroll_y = 0
		self.events: List[MapEvent] = []
		self.selected_event: Optional[MapEvent] = None
		self.hover_pos: Optional[Tuple[int, int]] = None

	def add_event(self, event: MapEvent):
		"""Add event to map"""
		self.events.append(event)

	def remove_event(self, event: MapEvent):
		"""Remove event from map"""
		if event in self.events:
			self.events.remove(event)

	def get_event_at(self, x: int, y: int) -> Optional[MapEvent]:
		"""Get event at position"""
		for event in self.events:
			if event.x == x and event.y == y:
				return event
		return None

	def update(self, mouse_pos: Tuple[int, int], mouse_clicked: bool, mouse_right: bool,
			  current_event_type: EventType) -> Optional[MapEvent]:
		"""Update canvas, return selected event"""
		if not self.rect.collidepoint(mouse_pos):
			self.hover_pos = None
			return None

		# Calculate map coordinates
		rel_x = mouse_pos[0] - self.rect.x + self.scroll_x
		rel_y = mouse_pos[1] - self.rect.y + self.scroll_y
		map_x = rel_x // self.tile_size
		map_y = rel_y // self.tile_size

		if 0 <= map_x < self.map_width and 0 <= map_y < self.map_height:
			self.hover_pos = (map_x, map_y)

			# Left click - place/select event
			if mouse_clicked:
				existing = self.get_event_at(map_x, map_y)
				if existing:
					self.selected_event = existing
					return existing
				else:
					# Place new event
					event_id = len(self.events)
					new_event = MapEvent(
						event_id=event_id,
						event_type=current_event_type,
						x=map_x,
						y=map_y,
						name=f"{current_event_type.name} {event_id}"
					)
					self.add_event(new_event)
					self.selected_event = new_event
					return new_event

			# Right click - remove event
			elif mouse_right:
				existing = self.get_event_at(map_x, map_y)
				if existing:
					self.remove_event(existing)
					if self.selected_event == existing:
						self.selected_event = None

		return None

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw map canvas"""
		pygame.draw.rect(surface, COLOR_PANEL_LIGHT, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 2)

		# Create clipping region
		clip_rect = surface.get_clip()
		surface.set_clip(self.rect)

		# Draw grid
		for y in range(self.map_height):
			for x in range(self.map_width):
				screen_x = self.rect.x + x * self.tile_size - self.scroll_x
				screen_y = self.rect.y + y * self.tile_size - self.scroll_y

				if (self.rect.left <= screen_x < self.rect.right and 
					self.rect.top <= screen_y < self.rect.bottom):
					
					cell_rect = pygame.Rect(screen_x, screen_y, self.tile_size, self.tile_size)
					pygame.draw.rect(surface, COLOR_GRID, cell_rect, 1)

		# Draw events
		for event in self.events:
			screen_x = self.rect.x + event.x * self.tile_size - self.scroll_x
			screen_y = self.rect.y + event.y * self.tile_size - self.scroll_y

			if (self.rect.left <= screen_x < self.rect.right and 
				self.rect.top <= screen_y < self.rect.bottom):
				
				event_rect = pygame.Rect(screen_x + 2, screen_y + 2, 
										self.tile_size - 4, self.tile_size - 4)
				
				# Event color
				pygame.draw.rect(surface, event.get_color(), event_rect)
				
				# Selection border
				if event == self.selected_event:
					pygame.draw.rect(surface, COLOR_SELECTED, event_rect, 3)
				else:
					pygame.draw.rect(surface, COLOR_BORDER, event_rect, 1)

				# Event ID
				if self.tile_size >= 20:
					id_surf = pygame.font.Font(None, 14).render(str(event.event_id), True, (0, 0, 0))
					id_rect = id_surf.get_rect(center=event_rect.center)
					surface.blit(id_surf, id_rect)

		# Draw hover indicator
		if self.hover_pos:
			hx, hy = self.hover_pos
			screen_x = self.rect.x + hx * self.tile_size - self.scroll_x
			screen_y = self.rect.y + hy * self.tile_size - self.scroll_y
			hover_rect = pygame.Rect(screen_x, screen_y, self.tile_size, self.tile_size)
			pygame.draw.rect(surface, (255, 255, 255, 128), hover_rect, 2)

		surface.set_clip(clip_rect)


class Button:
	"""Simple button"""
	def __init__(self, x: int, y: int, width: int, height: int, text: str):
		self.rect = pygame.Rect(x, y, width, height)
		self.text = text
		self.hover = False

	def update(self, mouse_pos: Tuple[int, int], mouse_clicked: bool) -> bool:
		"""Update button, return True if clicked"""
		self.hover = self.rect.collidepoint(mouse_pos)
		return self.hover and mouse_clicked

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw button"""
		bg_color = COLOR_PANEL_LIGHT if self.hover else COLOR_PANEL
		pygame.draw.rect(surface, bg_color, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 2)

		text_surf = font.render(self.text, True, COLOR_TEXT)
		text_rect = text_surf.get_rect(center=self.rect.center)
		surface.blit(text_surf, text_rect)


class MapEventEditor:
	"""Main map event editor"""
	def __init__(self, width: int = 1600, height: int = 900):
		pygame.init()
		self.width = width
		self.height = height
		self.screen = pygame.display.set_mode((width, height))
		pygame.display.set_caption("FFMQ Map Event Editor")

		self.clock = pygame.time.Clock()
		self.font = pygame.font.Font(None, 20)
		self.title_font = pygame.font.Font(None, 32)
		self.small_font = pygame.font.Font(None, 16)

		# UI Components
		self.map_canvas = MapCanvas(20, 80, 1100, 750)
		self.event_palette = EventPalette(1140, 80, 250, 400)
		self.property_panel = EventPropertyPanel(1140, 500, 440, 330)

		# Buttons
		self.save_button = Button(1400, 80, 180, 40, "Save Events")
		self.clear_button = Button(1400, 130, 180, 40, "Clear All")
		self.export_button = Button(1400, 180, 180, 40, "Export JSON")

		# Test events
		self._create_test_events()

		# Running
		self.running = True
		self.modified = False

	def _create_test_events(self):
		"""Create some test events"""
		test_events = [
			MapEvent(0, EventType.NPC, 5, 5, sprite_id=1, dialog_id=1, name="Village Elder"),
			MapEvent(1, EventType.TREASURE, 10, 8, item_id=42, name="Treasure Chest"),
			MapEvent(2, EventType.WARP, 15, 15, warp_map=2, warp_x=5, warp_y=5, name="Cave Entrance"),
			MapEvent(3, EventType.SIGN, 7, 3, dialog_id=10, name="Town Sign"),
		]
		for event in test_events:
			self.map_canvas.add_event(event)

	def handle_events(self):
		"""Handle pygame events"""
		mouse_pos = pygame.mouse.get_pos()
		mouse_clicked = False
		mouse_right = False
		scroll = 0

		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				self.running = False

			elif event.type == pygame.KEYDOWN:
				if event.key == pygame.K_ESCAPE:
					self.running = False
				elif event.key == pygame.K_s and (event.mod & pygame.KMOD_CTRL):
					self.save_events()
				elif event.key == pygame.K_DELETE:
					if self.map_canvas.selected_event:
						self.map_canvas.remove_event(self.map_canvas.selected_event)
						self.map_canvas.selected_event = None
						self.modified = True

			elif event.type == pygame.MOUSEBUTTONDOWN:
				if event.button == 1:
					mouse_clicked = True
				elif event.button == 3:
					mouse_right = True

			elif event.type == pygame.MOUSEWHEEL:
				scroll = event.y

		# Update event palette
		selected_type = self.event_palette.update(mouse_pos, mouse_clicked)

		# Update map canvas
		selected_event = self.map_canvas.update(mouse_pos, mouse_clicked, mouse_right, 
											   self.event_palette.selected_type)
		if selected_event:
			self.property_panel.set_event(selected_event)
			self.modified = True

		# Handle scroll
		if scroll != 0 and self.map_canvas.rect.collidepoint(mouse_pos):
			self.map_canvas.scroll_y = max(0, self.map_canvas.scroll_y - scroll * 30)

		# Update buttons
		if self.save_button.update(mouse_pos, mouse_clicked):
			self.save_events()

		if self.clear_button.update(mouse_pos, mouse_clicked):
			self.map_canvas.events.clear()
			self.map_canvas.selected_event = None
			self.property_panel.set_event(None)
			self.modified = True

		if self.export_button.update(mouse_pos, mouse_clicked):
			self.export_events()

	def save_events(self):
		"""Save events"""
		print(f"Saving {len(self.map_canvas.events)} events...")
		self.modified = False

	def export_events(self):
		"""Export events to JSON"""
		import json
		events_data = []
		for event in self.map_canvas.events:
			events_data.append({
				'id': event.event_id,
				'type': event.event_type.name,
				'x': event.x,
				'y': event.y,
				'name': event.name,
				'sprite_id': event.sprite_id,
				'dialog_id': event.dialog_id,
				'item_id': event.item_id,
				'warp_map': event.warp_map,
				'warp_x': event.warp_x,
				'warp_y': event.warp_y,
			})
		
		json_str = json.dumps(events_data, indent=2)
		print("Exported events:")
		print(json_str)

	def draw(self):
		"""Draw editor"""
		self.screen.fill(COLOR_BG)

		# Title
		title_text = "FFMQ Map Event Editor"
		if self.modified:
			title_text += " *"
		title = self.title_font.render(title_text, True, COLOR_TEXT)
		self.screen.blit(title, (20, 20))

		# Event count
		count_text = f"Events: {len(self.map_canvas.events)}"
		count_surf = self.font.render(count_text, True, COLOR_TEXT)
		self.screen.blit(count_surf, (20, 850))

		# Draw components
		self.map_canvas.draw(self.screen, self.font)
		self.event_palette.draw(self.screen, self.font)
		self.property_panel.draw(self.screen, self.font)

		# Draw buttons
		self.save_button.draw(self.screen, self.font)
		self.clear_button.draw(self.screen, self.font)
		self.export_button.draw(self.screen, self.font)

		# Instructions
		inst_x = 1140
		inst_y = 240
		instructions = [
			"Controls:",
			"Left Click: Place/Select event",
			"Right Click: Remove event",
			"Mouse Wheel: Scroll map",
			"Delete: Remove selected",
			"Ctrl+S: Save",
			"ESC: Quit",
		]

		inst_title = self.font.render("Instructions", True, COLOR_TEXT)
		self.screen.blit(inst_title, (inst_x, inst_y))
		
		for i, text in enumerate(instructions[1:]):
			inst_surf = self.small_font.render(text, True, (180, 185, 190))
			self.screen.blit(inst_surf, (inst_x + 5, inst_y + 30 + i * 18))

		pygame.display.flip()

	def run(self):
		"""Main loop"""
		while self.running:
			self.handle_events()
			self.draw()
			self.clock.tick(60)

		pygame.quit()


def main():
	"""Entry point"""
	editor = MapEventEditor()
	editor.run()


if __name__ == "__main__":
	main()
