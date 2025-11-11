"""
Warp Connection Editor for Final Fantasy Mystic Quest
Visualizes map-to-map warps with connection lines and interactive editing.
"""

import pygame
import json
from dataclasses import dataclass, asdict
from typing import List, Tuple, Optional
from enum import Enum

# Initialize Pygame
pygame.init()

# Constants
WINDOW_WIDTH = 1800
WINDOW_HEIGHT = 1000
FPS = 60

# Colors
COLOR_BG = (30, 30, 40)
COLOR_PANEL_BG = (45, 45, 55)
COLOR_BORDER = (80, 80, 90)
COLOR_TEXT = (220, 220, 230)
COLOR_HIGHLIGHT = (100, 150, 255)
COLOR_MAP_BG = (50, 50, 60)
COLOR_MAP_BORDER = (100, 100, 120)
COLOR_WARP_SOURCE = (100, 255, 100)
COLOR_WARP_DEST = (255, 100, 100)
COLOR_CONNECTION = (150, 150, 200)
COLOR_SELECTED = (255, 200, 50)
COLOR_HOVER = (200, 200, 255)

# UI Constants
MAP_CELL_SIZE = 150
MAP_PADDING = 20
MAP_COLS = 8
WARP_CIRCLE_RADIUS = 8
CONNECTION_LINE_WIDTH = 2
SELECTED_LINE_WIDTH = 4


class WarpType(Enum):
	"""Types of warps in the game"""
	DOOR = "Door"
	STAIRS_UP = "Stairs Up"
	STAIRS_DOWN = "Stairs Down"
	CAVE_ENTRANCE = "Cave Entrance"
	CAVE_EXIT = "Cave Exit"
	TELEPORT = "Teleport"
	WORLD_MAP = "World Map"
	DUNGEON = "Dungeon"


@dataclass
class MapInfo:
	"""Information about a game map"""
	map_id: int
	name: str
	area: str  # "Overworld", "Town", "Dungeon", etc.
	grid_x: int  # Position in editor grid
	grid_y: int
	rom_offset: int = 0
	width: int = 32
	height: int = 32

	def get_screen_pos(self) -> Tuple[int, int]:
		"""Get screen position for this map"""
		x = MAP_PADDING + self.grid_x * (MAP_CELL_SIZE + MAP_PADDING)
		y = 100 + self.grid_y * (MAP_CELL_SIZE + MAP_PADDING)
		return (x, y)

	def get_center_pos(self) -> Tuple[int, int]:
		"""Get center position of map cell"""
		x, y = self.get_screen_pos()
		return (x + MAP_CELL_SIZE // 2, y + MAP_CELL_SIZE // 2)


@dataclass
class Warp:
	"""A warp point on a map"""
	warp_id: int
	source_map_id: int
	source_x: int  # Position on source map (tile coordinates)
	source_y: int
	dest_map_id: int
	dest_x: int  # Position on destination map
	dest_y: int
	warp_type: WarpType
	name: str = ""
	enabled: bool = True

	def to_dict(self):
		"""Convert to dictionary for JSON export"""
		d = asdict(self)
		d['warp_type'] = self.warp_type.value
		return d


class Button:
	"""Interactive button"""
	def __init__(self, x, y, width, height, text, callback):
		self.rect = pygame.Rect(x, y, width, height)
		self.text = text
		self.callback = callback
		self.hovered = False

	def draw(self, screen, font):
		color = COLOR_HIGHLIGHT if self.hovered else COLOR_BORDER
		pygame.draw.rect(screen, color, self.rect, 2)
		pygame.draw.rect(screen, COLOR_PANEL_BG, self.rect)
		pygame.draw.rect(screen, color, self.rect, 2)

		text_surf = font.render(self.text, True, COLOR_TEXT)
		text_rect = text_surf.get_rect(center=self.rect.center)
		screen.blit(text_surf, text_rect)

	def handle_event(self, event):
		if event.type == pygame.MOUSEMOTION:
			self.hovered = self.rect.collidepoint(event.pos)
		elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
			if self.rect.collidepoint(event.pos):
				self.callback()
				return True
		return False


class MapCell:
	"""Visual representation of a map in the grid"""
	def __init__(self, map_info: MapInfo):
		self.map_info = map_info
		x, y = map_info.get_screen_pos()
		self.rect = pygame.Rect(x, y, MAP_CELL_SIZE, MAP_CELL_SIZE)
		self.hovered = False
		self.selected = False

	def draw(self, screen, font, small_font):
		# Background
		bg_color = COLOR_SELECTED if self.selected else (COLOR_HOVER if self.hovered else COLOR_MAP_BG)
		pygame.draw.rect(screen, bg_color, self.rect)

		# Border
		border_color = COLOR_SELECTED if self.selected else COLOR_MAP_BORDER
		border_width = 3 if self.selected else 1
		pygame.draw.rect(screen, border_color, self.rect, border_width)

		# Map ID
		id_text = small_font.render(f"ID: {self.map_info.map_id:02X}", True, COLOR_TEXT)
		screen.blit(id_text, (self.rect.x + 5, self.rect.y + 5))

		# Map name (wrapped)
		name_lines = self._wrap_text(self.map_info.name, MAP_CELL_SIZE - 10, small_font)
		y_offset = self.rect.y + 30
		for line in name_lines[:3]:  # Max 3 lines
			name_surf = small_font.render(line, True, COLOR_TEXT)
			screen.blit(name_surf, (self.rect.x + 5, y_offset))
			y_offset += 18

		# Area tag
		area_surf = small_font.render(self.map_info.area, True, (150, 150, 170))
		area_rect = area_surf.get_rect(bottomleft=(self.rect.x + 5, self.rect.bottom - 5))
		screen.blit(area_surf, area_rect)

	def _wrap_text(self, text, max_width, font):
		"""Wrap text to fit width"""
		words = text.split()
		lines = []
		current_line = []

		for word in words:
			test_line = ' '.join(current_line + [word])
			if font.size(test_line)[0] <= max_width:
				current_line.append(word)
			else:
				if current_line:
					lines.append(' '.join(current_line))
				current_line = [word]

		if current_line:
			lines.append(' '.join(current_line))

		return lines

	def contains_point(self, pos):
		return self.rect.collidepoint(pos)


class WarpVisual:
	"""Visual representation of a warp"""
	def __init__(self, warp: Warp, source_cell: MapCell, dest_cell: Optional[MapCell]):
		self.warp = warp
		self.source_cell = source_cell
		self.dest_cell = dest_cell
		self.selected = False
		self.hovered = False

		# Calculate warp position on source map
		# Scale tile position to map cell
		map_w = source_cell.map_info.width
		map_h = source_cell.map_info.height
		cell_x = source_cell.rect.x + (warp.source_x / map_w) * MAP_CELL_SIZE
		cell_y = source_cell.rect.y + (warp.source_y / map_h) * MAP_CELL_SIZE
		self.source_pos = (int(cell_x), int(cell_y))

		# Calculate destination position if we have the map
		if dest_cell:
			dest_w = dest_cell.map_info.width
			dest_h = dest_cell.map_info.height
			dest_x = dest_cell.rect.x + (warp.dest_x / dest_w) * MAP_CELL_SIZE
			dest_y = dest_cell.rect.y + (warp.dest_y / dest_h) * MAP_CELL_SIZE
			self.dest_pos = (int(dest_x), int(dest_y))
		else:
			self.dest_pos = None

	def draw(self, screen, font):
		# Draw connection line if we have a destination
		if self.dest_pos:
			line_color = COLOR_SELECTED if self.selected else (COLOR_HOVER if self.hovered else COLOR_CONNECTION)
			line_width = SELECTED_LINE_WIDTH if self.selected else CONNECTION_LINE_WIDTH

			# Draw arrow line
			pygame.draw.line(screen, line_color, self.source_pos, self.dest_pos, line_width)

			# Draw arrowhead at destination
			self._draw_arrowhead(screen, line_color)

		# Draw source warp circle
		source_color = COLOR_SELECTED if self.selected else COLOR_WARP_SOURCE
		pygame.draw.circle(screen, source_color, self.source_pos, WARP_CIRCLE_RADIUS)
		pygame.draw.circle(screen, COLOR_BORDER, self.source_pos, WARP_CIRCLE_RADIUS, 1)

		# Draw destination warp circle
		if self.dest_pos:
			dest_color = COLOR_SELECTED if self.selected else COLOR_WARP_DEST
			pygame.draw.circle(screen, dest_color, self.dest_pos, WARP_CIRCLE_RADIUS)
			pygame.draw.circle(screen, COLOR_BORDER, self.dest_pos, WARP_CIRCLE_RADIUS, 1)

	def _draw_arrowhead(self, screen, color):
		"""Draw arrowhead pointing at destination"""
		if not self.dest_pos:
			return

		import math

		# Calculate angle
		dx = self.dest_pos[0] - self.source_pos[0]
		dy = self.dest_pos[1] - self.source_pos[1]
		angle = math.atan2(dy, dx)

		# Arrowhead size
		size = 12
		angle_offset = math.pi / 6  # 30 degrees

		# Calculate arrowhead points
		p1 = self.dest_pos
		p2_x = p1[0] - size * math.cos(angle - angle_offset)
		p2_y = p1[1] - size * math.sin(angle - angle_offset)
		p3_x = p1[0] - size * math.cos(angle + angle_offset)
		p3_y = p1[1] - size * math.sin(angle + angle_offset)

		points = [p1, (p2_x, p2_y), (p3_x, p3_y)]
		pygame.draw.polygon(screen, color, points)

	def contains_point(self, pos):
		"""Check if point is near source or destination"""
		sx, sy = self.source_pos
		if ((pos[0] - sx) ** 2 + (pos[1] - sy) ** 2) <= (WARP_CIRCLE_RADIUS + 5) ** 2:
			return True

		if self.dest_pos:
			dx, dy = self.dest_pos
			if ((pos[0] - dx) ** 2 + (pos[1] - dy) ** 2) <= (WARP_CIRCLE_RADIUS + 5) ** 2:
				return True

		return False


class WarpPropertyPanel:
	"""Panel showing properties of selected warp"""
	def __init__(self, x, y, width, height):
		self.rect = pygame.Rect(x, y, width, height)
		self.warp: Optional[WarpVisual] = None

	def set_warp(self, warp: Optional[WarpVisual]):
		self.warp = warp

	def draw(self, screen, font, small_font):
		# Background
		pygame.draw.rect(screen, COLOR_PANEL_BG, self.rect)
		pygame.draw.rect(screen, COLOR_BORDER, self.rect, 2)

		# Title
		title = font.render("Warp Properties", True, COLOR_TEXT)
		screen.blit(title, (self.rect.x + 10, self.rect.y + 10))

		if not self.warp:
			no_sel = small_font.render("No warp selected", True, (150, 150, 150))
			screen.blit(no_sel, (self.rect.x + 10, self.rect.y + 50))
			return

		# Warp details
		y = self.rect.y + 50
		line_height = 22

		details = [
			f"Warp ID: {self.warp.warp.warp_id:03d}",
			f"Name: {self.warp.warp.name or '(unnamed)'}",
			f"Type: {self.warp.warp.warp_type.value}",
			"",
			f"Source Map: {self.warp.warp.source_map_id:02X}",
			f"Source Pos: ({self.warp.warp.source_x}, {self.warp.warp.source_y})",
			"",
			f"Dest Map: {self.warp.warp.dest_map_id:02X}",
			f"Dest Pos: ({self.warp.warp.dest_x}, {self.warp.warp.dest_y})",
			"",
			f"Enabled: {'Yes' if self.warp.warp.enabled else 'No'}",
		]

		for line in details:
			if line:
				text = small_font.render(line, True, COLOR_TEXT)
			else:
				text = small_font.render("", True, COLOR_TEXT)
			screen.blit(text, (self.rect.x + 10, y))
			y += line_height


class WarpConnectionEditor:
	"""Main warp connection editor application"""
	def __init__(self):
		self.screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
		pygame.display.set_caption("FFMQ Warp Connection Editor")
		self.clock = pygame.time.Clock()
		self.running = True

		# Fonts
		self.font = pygame.font.Font(None, 28)
		self.small_font = pygame.font.Font(None, 20)
		self.title_font = pygame.font.Font(None, 36)

		# Test map data (sample FFMQ maps)
		self.maps: List[MapInfo] = self._create_test_maps()
		self.map_cells: List[MapCell] = [MapCell(m) for m in self.maps]

		# Test warp data
		self.warps: List[Warp] = self._create_test_warps()
		self.warp_visuals: List[WarpVisual] = self._create_warp_visuals()

		# Selection state
		self.selected_warp: Optional[WarpVisual] = None
		self.selected_map: Optional[MapCell] = None
		self.hovered_warp: Optional[WarpVisual] = None

		# Scroll offset
		self.scroll_y = 0

		# UI panels
		self.property_panel = WarpPropertyPanel(
			WINDOW_WIDTH - 350, 80, 340, 400
		)

		# Buttons
		self.buttons = [
			Button(WINDOW_WIDTH - 350, 500, 160, 40, "Save Warps", self.save_warps),
			Button(WINDOW_WIDTH - 180, 500, 160, 40, "Export JSON", self.export_json),
			Button(WINDOW_WIDTH - 350, 550, 160, 40, "New Warp", self.new_warp),
			Button(WINDOW_WIDTH - 180, 550, 160, 40, "Delete Warp", self.delete_warp),
			Button(WINDOW_WIDTH - 350, 600, 340, 40, "Toggle Selected", self.toggle_selected),
		]

		# Filter controls
		self.show_all_warps = True
		self.filter_map_id: Optional[int] = None

	def _create_test_maps(self) -> List[MapInfo]:
		"""Create test map data"""
		maps = [
			MapInfo(0x00, "Hill of Destiny", "Overworld", 0, 0, 0x100000),
			MapInfo(0x01, "Foresta", "Town", 1, 0, 0x101000),
			MapInfo(0x02, "Foresta House 1", "Building", 2, 0, 0x102000),
			MapInfo(0x03, "Foresta House 2", "Building", 3, 0, 0x103000),
			MapInfo(0x04, "Sand Temple", "Dungeon", 0, 1, 0x104000),
			MapInfo(0x05, "Sand Temple B1", "Dungeon", 1, 1, 0x105000),
			MapInfo(0x06, "Sand Temple B2", "Dungeon", 2, 1, 0x106000),
			MapInfo(0x07, "Aquaria", "Town", 3, 1, 0x107000),
			MapInfo(0x08, "Fireburg", "Town", 0, 2, 0x108000),
			MapInfo(0x09, "Mine", "Dungeon", 1, 2, 0x109000),
			MapInfo(0x0A, "Mine B1", "Dungeon", 2, 2, 0x10A000),
			MapInfo(0x0B, "Windia", "Town", 3, 2, 0x10B000),
			MapInfo(0x0C, "Focus Tower 1F", "Dungeon", 0, 3, 0x10C000),
			MapInfo(0x0D, "Focus Tower 2F", "Dungeon", 1, 3, 0x10D000),
			MapInfo(0x0E, "Focus Tower 3F", "Dungeon", 2, 3, 0x10E000),
			MapInfo(0x0F, "Pazuzu's Tower", "Dungeon", 3, 3, 0x10F000),
		]
		return maps

	def _create_test_warps(self) -> List[Warp]:
		"""Create test warp connections"""
		warps = [
			# Foresta connections
			Warp(0, 0x01, 15, 28, 0x00, 10, 15, WarpType.DOOR, "Foresta to Overworld"),
			Warp(1, 0x01, 8, 12, 0x02, 4, 6, WarpType.DOOR, "Foresta to House 1"),
			Warp(2, 0x02, 4, 6, 0x01, 8, 12, WarpType.DOOR, "House 1 to Foresta"),
			Warp(3, 0x01, 20, 12, 0x03, 4, 6, WarpType.DOOR, "Foresta to House 2"),
			Warp(4, 0x03, 4, 6, 0x01, 20, 12, WarpType.DOOR, "House 2 to Foresta"),

			# Sand Temple connections
			Warp(5, 0x04, 16, 28, 0x00, 25, 20, WarpType.CAVE_EXIT, "Temple to Overworld"),
			Warp(6, 0x04, 16, 4, 0x05, 16, 28, WarpType.STAIRS_DOWN, "Temple 1F to B1"),
			Warp(7, 0x05, 16, 28, 0x04, 16, 4, WarpType.STAIRS_UP, "Temple B1 to 1F"),
			Warp(8, 0x05, 4, 4, 0x06, 28, 28, WarpType.STAIRS_DOWN, "Temple B1 to B2"),
			Warp(9, 0x06, 28, 28, 0x05, 4, 4, WarpType.STAIRS_UP, "Temple B2 to B1"),

			# Aquaria connections
			Warp(10, 0x07, 16, 30, 0x00, 15, 25, WarpType.DOOR, "Aquaria to Overworld"),

			# Fireburg and Mine
			Warp(11, 0x08, 16, 30, 0x00, 20, 10, WarpType.DOOR, "Fireburg to Overworld"),
			Warp(12, 0x08, 8, 8, 0x09, 16, 28, WarpType.CAVE_ENTRANCE, "Fireburg to Mine"),
			Warp(13, 0x09, 16, 28, 0x08, 8, 8, WarpType.CAVE_EXIT, "Mine to Fireburg"),
			Warp(14, 0x09, 4, 4, 0x0A, 28, 28, WarpType.STAIRS_DOWN, "Mine to Mine B1"),
			Warp(15, 0x0A, 28, 28, 0x09, 4, 4, WarpType.STAIRS_UP, "Mine B1 to Mine"),

			# Windia
			Warp(16, 0x0B, 16, 30, 0x00, 10, 5, WarpType.DOOR, "Windia to Overworld"),

			# Focus Tower
			Warp(17, 0x0C, 16, 28, 0x00, 30, 15, WarpType.CAVE_EXIT, "Focus Tower to Overworld"),
			Warp(18, 0x0C, 16, 4, 0x0D, 16, 28, WarpType.STAIRS_UP, "Tower 1F to 2F"),
			Warp(19, 0x0D, 16, 28, 0x0C, 16, 4, WarpType.STAIRS_DOWN, "Tower 2F to 1F"),
			Warp(20, 0x0D, 16, 4, 0x0E, 16, 28, WarpType.STAIRS_UP, "Tower 2F to 3F"),
			Warp(21, 0x0E, 16, 28, 0x0D, 16, 4, WarpType.STAIRS_DOWN, "Tower 3F to 2F"),

			# Pazuzu's Tower
			Warp(22, 0x0F, 16, 28, 0x00, 28, 28, WarpType.TELEPORT, "Pazuzu Tower to Overworld"),
		]
		return warps

	def _create_warp_visuals(self) -> List[WarpVisual]:
		"""Create visual representations of warps"""
		visuals = []

		# Create map lookup
		map_lookup = {m.map_id: cell for m, cell in zip(self.maps, self.map_cells)}

		for warp in self.warps:
			source_cell = map_lookup.get(warp.source_map_id)
			dest_cell = map_lookup.get(warp.dest_map_id)

			if source_cell:  # Only create visual if source map exists
				visual = WarpVisual(warp, source_cell, dest_cell)
				visuals.append(visual)

		return visuals

	def save_warps(self):
		"""Save warps to ROM (placeholder)"""
		print("Saving warps to ROM...")
		# TODO: Implement ROM writing

	def export_json(self):
		"""Export warps to JSON file"""
		data = {
			'maps': [asdict(m) for m in self.maps],
			'warps': [w.to_dict() for w in self.warps]
		}

		with open('warps_export.json', 'w') as f:
			json.dump(data, f, indent=2)

		print("Exported warps to warps_export.json")

	def new_warp(self):
		"""Create a new warp"""
		# Create default warp
		new_id = max([w.warp_id for w in self.warps], default=-1) + 1
		new_warp = Warp(
			warp_id=new_id,
			source_map_id=0x00,
			source_x=16,
			source_y=16,
			dest_map_id=0x01,
			dest_x=16,
			dest_y=16,
			warp_type=WarpType.DOOR,
			name=f"New Warp {new_id}"
		)
		self.warps.append(new_warp)
		self.warp_visuals = self._create_warp_visuals()
		print(f"Created new warp {new_id}")

	def delete_warp(self):
		"""Delete selected warp"""
		if self.selected_warp:
			self.warps.remove(self.selected_warp.warp)
			self.warp_visuals.remove(self.selected_warp)
			self.selected_warp = None
			self.property_panel.set_warp(None)
			print("Deleted warp")

	def toggle_selected(self):
		"""Toggle enabled state of selected warp"""
		if self.selected_warp:
			self.selected_warp.warp.enabled = not self.selected_warp.warp.enabled
			print(f"Warp {self.selected_warp.warp.warp_id} enabled: {self.selected_warp.warp.enabled}")

	def handle_events(self):
		"""Handle input events"""
		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				self.running = False

			# Handle buttons
			for button in self.buttons:
				if button.handle_event(event):
					continue

			# Mouse events
			if event.type == pygame.MOUSEBUTTONDOWN:
				if event.button == 1:  # Left click
					# Check warp selection
					clicked_warp = None
					for warp_visual in reversed(self.warp_visuals):  # Check top-most first
						if warp_visual.contains_point(event.pos):
							clicked_warp = warp_visual
							break

					if clicked_warp:
						# Select warp
						if self.selected_warp:
							self.selected_warp.selected = False
						self.selected_warp = clicked_warp
						clicked_warp.selected = True
						self.property_panel.set_warp(clicked_warp)
					else:
						# Check map selection
						clicked_map = None
						for map_cell in self.map_cells:
							if map_cell.contains_point(event.pos):
								clicked_map = map_cell
								break

						if clicked_map:
							if self.selected_map:
								self.selected_map.selected = False
							self.selected_map = clicked_map
							clicked_map.selected = True
						else:
							# Deselect
							if self.selected_warp:
								self.selected_warp.selected = False
								self.selected_warp = None
								self.property_panel.set_warp(None)
							if self.selected_map:
								self.selected_map.selected = False
								self.selected_map = None

				elif event.button == 4:  # Scroll up
					self.scroll_y = min(self.scroll_y + 20, 0)
				elif event.button == 5:  # Scroll down
					self.scroll_y -= 20

			elif event.type == pygame.MOUSEMOTION:
				# Update hover state
				self.hovered_warp = None
				for warp_visual in reversed(self.warp_visuals):
					if warp_visual.contains_point(event.pos):
						self.hovered_warp = warp_visual
						warp_visual.hovered = True
					else:
						warp_visual.hovered = False

				# Update map hover
				for map_cell in self.map_cells:
					map_cell.hovered = map_cell.contains_point(event.pos)

			# Keyboard shortcuts
			elif event.type == pygame.KEYDOWN:
				if event.key == pygame.K_ESCAPE:
					self.running = False
				elif event.key == pygame.K_DELETE:
					self.delete_warp()
				elif event.key == pygame.K_n and (event.mod & pygame.KMOD_CTRL):
					self.new_warp()
				elif event.key == pygame.K_s and (event.mod & pygame.KMOD_CTRL):
					self.save_warps()
				elif event.key == pygame.K_e and (event.mod & pygame.KMOD_CTRL):
					self.export_json()

	def draw(self):
		"""Draw the editor"""
		self.screen.fill(COLOR_BG)

		# Title bar
		title_bg = pygame.Rect(0, 0, WINDOW_WIDTH, 70)
		pygame.draw.rect(self.screen, COLOR_PANEL_BG, title_bg)
		pygame.draw.line(self.screen, COLOR_BORDER, (0, 70), (WINDOW_WIDTH, 70), 2)

		title = self.title_font.render("Warp Connection Editor", True, COLOR_TEXT)
		self.screen.blit(title, (20, 20))

		# Stats
		stats = self.small_font.render(
			f"Maps: {len(self.maps)} | Warps: {len(self.warps)} | "
			f"Selected: {self.selected_warp.warp.name if self.selected_warp else 'None'}",
			True, (180, 180, 200)
		)
		self.screen.blit(stats, (20, 50))

		# Save scroll position and apply
		save_clip = self.screen.get_clip()
		map_area = pygame.Rect(0, 80, WINDOW_WIDTH - 360, WINDOW_HEIGHT - 80)
		self.screen.set_clip(map_area)

		# Apply scroll offset (create temporary surface for scrolling)
		# For simplicity, we'll just offset the drawing
		# In production, use a proper scrolling system

		# Draw map cells
		for map_cell in self.map_cells:
			map_cell.draw(self.screen, self.font, self.small_font)

		# Draw warp connections
		for warp_visual in self.warp_visuals:
			if warp_visual.warp.enabled:
				warp_visual.draw(self.screen, self.small_font)

		# Restore clip
		self.screen.set_clip(save_clip)

		# Draw UI panels
		self.property_panel.draw(self.screen, self.font, self.small_font)

		# Draw buttons
		for button in self.buttons:
			button.draw(self.screen, self.small_font)

		# Draw legend
		self._draw_legend()

		# Draw instructions
		self._draw_instructions()

		pygame.display.flip()

	def _draw_legend(self):
		"""Draw color legend"""
		legend_x = WINDOW_WIDTH - 350
		legend_y = 670

		legend_bg = pygame.Rect(legend_x, legend_y, 340, 120)
		pygame.draw.rect(self.screen, COLOR_PANEL_BG, legend_bg)
		pygame.draw.rect(self.screen, COLOR_BORDER, legend_bg, 2)

		title = self.font.render("Legend", True, COLOR_TEXT)
		self.screen.blit(title, (legend_x + 10, legend_y + 10))

		items = [
			(COLOR_WARP_SOURCE, "Source Warp"),
			(COLOR_WARP_DEST, "Destination Warp"),
			(COLOR_CONNECTION, "Connection Line"),
			(COLOR_SELECTED, "Selected"),
		]

		y = legend_y + 45
		for color, label in items:
			pygame.draw.circle(self.screen, color, (legend_x + 20, y), 6)
			text = self.small_font.render(label, True, COLOR_TEXT)
			self.screen.blit(text, (legend_x + 35, y - 8))
			y += 22

	def _draw_instructions(self):
		"""Draw keyboard instructions"""
		inst_x = WINDOW_WIDTH - 350
		inst_y = 810

		inst_bg = pygame.Rect(inst_x, inst_y, 340, 180)
		pygame.draw.rect(self.screen, COLOR_PANEL_BG, inst_bg)
		pygame.draw.rect(self.screen, COLOR_BORDER, inst_bg, 2)

		title = self.font.render("Controls", True, COLOR_TEXT)
		self.screen.blit(title, (inst_x + 10, inst_y + 10))

		controls = [
			"Click warp/map to select",
			"Delete: Remove selected warp",
			"Ctrl+N: New warp",
			"Ctrl+S: Save to ROM",
			"Ctrl+E: Export JSON",
			"ESC: Exit editor",
		]

		y = inst_y + 45
		for control in controls:
			text = self.small_font.render(control, True, (200, 200, 210))
			self.screen.blit(text, (inst_x + 10, y))
			y += 22

	def run(self):
		"""Main editor loop"""
		while self.running:
			self.handle_events()
			self.draw()
			self.clock.tick(FPS)

		pygame.quit()


def main():
	"""Entry point"""
	editor = WarpConnectionEditor()
	editor.run()


if __name__ == '__main__':
	main()
