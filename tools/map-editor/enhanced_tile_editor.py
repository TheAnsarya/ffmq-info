"""
Enhanced Tile Editor with Copy/Paste
Advanced tile editing with clipboard, transformations, and pattern fill
"""

import pygame
from typing import Optional, Tuple, List
from copy import deepcopy
from utils.graphics_data import Tile, Palette, Color, create_blank_tile
from utils.graphics_database import GraphicsDatabase


# Colors
COLOR_BG = (45, 45, 50)
COLOR_PANEL = (60, 60, 70)
COLOR_PANEL_LIGHT = (75, 75, 85)
COLOR_BORDER = (100, 100, 110)
COLOR_TEXT = (220, 220, 230)
COLOR_GRID = (80, 80, 90)
COLOR_SELECTED = (100, 150, 220)
COLOR_BUTTON = (70, 70, 85)
COLOR_BUTTON_HOVER = (90, 90, 110)


class TileClipboard:
	"""Clipboard for tile operations"""
	def __init__(self):
		self.tile_data: List[List[int]] = []  # 8x8 grid of color indices
		self.has_data = False

	def copy_tile(self, tile: Tile):
		"""Copy tile to clipboard"""
		self.tile_data = [[tile.get_pixel(x, y) for x in range(8)] for y in range(8)]
		self.has_data = True

	def paste_to_tile(self, tile: Tile):
		"""Paste clipboard data to tile"""
		if not self.has_data:
			return
		for y in range(8):
			for x in range(8):
				tile.set_pixel(x, y, self.tile_data[y][x])

	def copy_region(self, tile: Tile, x1: int, y1: int, x2: int, y2: int):
		"""Copy a region from tile"""
		min_x, max_x = min(x1, x2), max(x1, x2)
		min_y, max_y = min(y1, y2), max(y1, y2)

		self.tile_data = []
		for y in range(min_y, max_y + 1):
			row = []
			for x in range(min_x, max_x + 1):
				if 0 <= x < 8 and 0 <= y < 8:
					row.append(tile.get_pixel(x, y))
				else:
					row.append(0)
			self.tile_data.append(row)
		self.has_data = True

	def paste_region(self, tile: Tile, start_x: int, start_y: int):
		"""Paste clipboard region to tile at position"""
		if not self.has_data:
			return

		for y, row in enumerate(self.tile_data):
			for x, color_idx in enumerate(row):
				px, py = start_x + x, start_y + y
				if 0 <= px < 8 and 0 <= py < 8:
					tile.set_pixel(px, py, color_idx)


class Tool:
	"""Drawing tool types"""
	PENCIL = "pencil"
	FILL = "fill"
	LINE = "line"
	RECTANGLE = "rectangle"
	CIRCLE = "circle"
	SELECT = "select"


class Button:
	"""Interactive button"""
	def __init__(self, x: int, y: int, width: int, height: int, text: str, tooltip: str = ""):
		self.rect = pygame.Rect(x, y, width, height)
		self.text = text
		self.tooltip = tooltip
		self.hover = False
		self.enabled = True

	def update(self, mouse_pos: Tuple[int, int], mouse_clicked: bool) -> bool:
		"""Update button, return True if clicked"""
		if not self.enabled:
			return False
		self.hover = self.rect.collidepoint(mouse_pos)
		return self.hover and mouse_clicked

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw button"""
		if not self.enabled:
			bg_color = COLOR_PANEL
			text_color = COLOR_GRID
		else:
			bg_color = COLOR_BUTTON_HOVER if self.hover else COLOR_BUTTON
			text_color = COLOR_TEXT

		pygame.draw.rect(surface, bg_color, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 2)

		text_surf = font.render(self.text, True, text_color)
		text_rect = text_surf.get_rect(center=self.rect.center)
		surface.blit(text_surf, text_rect)


class EnhancedTileEditor:
	"""Advanced tile editor with copy/paste and tools"""
	def __init__(self, width: int = 1400, height: int = 900):
		pygame.init()
		self.width = width
		self.height = height
		self.screen = pygame.display.set_mode((width, height))
		pygame.display.set_caption("FFMQ Enhanced Tile Editor")

		self.clock = pygame.time.Clock()
		self.font = pygame.font.Font(None, 20)
		self.title_font = pygame.font.Font(None, 32)
		self.small_font = pygame.font.Font(None, 16)

		# Database
		self.database = GraphicsDatabase()
		self.rom_path = ""

		# Current state
		self.current_tile: Optional[Tile] = None
		self.current_palette: Optional[Palette] = None
		self.selected_color = 0
		self.current_tool = Tool.PENCIL

		# Clipboard
		self.clipboard = TileClipboard()
		self.undo_stack: List[Tile] = []
		self.redo_stack: List[Tile] = []

		# Canvas
		self.canvas_x = 50
		self.canvas_y = 150
		self.pixel_size = 48
		self.drawing = False
		self.line_start: Optional[Tuple[int, int]] = None
		self.selection_start: Optional[Tuple[int, int]] = None
		self.selection_end: Optional[Tuple[int, int]] = None

		# Palette swatches
		self.swatch_size = 32
		self.swatch_x = 600
		self.swatch_y = 150

		# Tool buttons
		self._create_buttons()

		# Running
		self.running = True
		self.modified = False

	def _create_buttons(self):
		"""Create toolbar buttons"""
		btn_y = 80
		btn_x = 50
		btn_width = 80
		btn_height = 30
		spacing = 10

		self.tool_buttons = {
			Tool.PENCIL: Button(btn_x, btn_y, btn_width, btn_height, "Pencil", "Draw pixels"),
			Tool.FILL: Button(btn_x + (btn_width + spacing), btn_y, btn_width, btn_height, "Fill", "Fill area"),
			Tool.LINE: Button(btn_x + 2 * (btn_width + spacing), btn_y, btn_width, btn_height, "Line", "Draw line"),
			Tool.RECTANGLE: Button(btn_x + 3 * (btn_width + spacing), btn_y, btn_width, btn_height, "Rect", "Draw rectangle"),
			Tool.SELECT: Button(btn_x + 4 * (btn_width + spacing), btn_y, btn_width, btn_height, "Select", "Select region"),
		}

		# Edit buttons
		edit_x = 700
		self.copy_button = Button(edit_x, btn_y, 70, btn_height, "Copy", "Copy tile (Ctrl+C)")
		self.paste_button = Button(edit_x + 80, btn_y, 70, btn_height, "Paste", "Paste tile (Ctrl+V)")
		self.undo_button = Button(edit_x + 160, btn_y, 70, btn_height, "Undo", "Undo (Ctrl+Z)")
		self.redo_button = Button(edit_x + 240, btn_y, 70, btn_height, "Redo", "Redo (Ctrl+Y)")

		# Transform buttons
		trans_y = btn_y + 40
		self.flip_h_button = Button(edit_x, trans_y, 70, btn_height, "Flip H", "Flip horizontal")
		self.flip_v_button = Button(edit_x + 80, trans_y, 70, btn_height, "Flip V", "Flip vertical")
		self.rotate_cw_button = Button(edit_x + 160, trans_y, 70, btn_height, "Rot R", "Rotate right")
		self.rotate_ccw_button = Button(edit_x + 240, trans_y, 70, btn_height, "Rot L", "Rotate left")

		# File buttons
		file_y = 20
		self.save_button = Button(1250, file_y, 100, 40, "Save", "Save to ROM (Ctrl+S)")
		self.clear_button = Button(1130, file_y, 100, 40, "Clear", "Clear tile")

	def load_rom(self, rom_path: str):
		"""Load ROM file"""
		self.rom_path = rom_path
		try:
			self.database.load_from_rom(rom_path)
			if self.database.palettes:
				self.current_palette = self.database.palettes.get(0)
			if self.database.tilesets:
				tileset = self.database.tilesets.get(0)
				if tileset and tileset.tiles:
					self.current_tile = deepcopy(tileset.tiles[0])
					self._save_undo()
			print(f"Loaded ROM: {rom_path}")
		except Exception as e:
			print(f"Error loading ROM: {e}")

	def _save_undo(self):
		"""Save current tile state to undo stack"""
		if self.current_tile:
			self.undo_stack.append(deepcopy(self.current_tile))
			if len(self.undo_stack) > 50:  # Limit undo stack
				self.undo_stack.pop(0)
			self.redo_stack.clear()

	def _undo(self):
		"""Undo last action"""
		if self.undo_stack:
			self.redo_stack.append(deepcopy(self.current_tile))
			self.current_tile = self.undo_stack.pop()
			self.modified = True

	def _redo(self):
		"""Redo last undone action"""
		if self.redo_stack:
			self.undo_stack.append(deepcopy(self.current_tile))
			self.current_tile = self.redo_stack.pop()
			self.modified = True

	def _get_pixel_coords(self, mouse_pos: Tuple[int, int]) -> Optional[Tuple[int, int]]:
		"""Get pixel coordinates from mouse position"""
		mx, my = mouse_pos
		px = (mx - self.canvas_x) // self.pixel_size
		py = (my - self.canvas_y) // self.pixel_size
		if 0 <= px < 8 and 0 <= py < 8:
			return (px, py)
		return None

	def _draw_pixel(self, x: int, y: int):
		"""Draw single pixel"""
		if self.current_tile and 0 <= x < 8 and 0 <= y < 8:
			self.current_tile.set_pixel(x, y, self.selected_color)

	def _flood_fill(self, x: int, y: int):
		"""Flood fill from position"""
		if not self.current_tile or not (0 <= x < 8 and 0 <= y < 8):
			return

		target_color = self.current_tile.get_pixel(x, y)
		if target_color == self.selected_color:
			return

		stack = [(x, y)]
		while stack:
			cx, cy = stack.pop()
			if not (0 <= cx < 8 and 0 <= cy < 8):
				continue
			if self.current_tile.get_pixel(cx, cy) != target_color:
				continue

			self.current_tile.set_pixel(cx, cy, self.selected_color)

			stack.extend([(cx+1, cy), (cx-1, cy), (cx, cy+1), (cx, cy-1)])

	def _draw_line(self, x1: int, y1: int, x2: int, y2: int):
		"""Draw line using Bresenham's algorithm"""
		dx = abs(x2 - x1)
		dy = abs(y2 - y1)
		sx = 1 if x1 < x2 else -1
		sy = 1 if y1 < y2 else -1
		err = dx - dy

		while True:
			self._draw_pixel(x1, y1)
			if x1 == x2 and y1 == y2:
				break
			e2 = 2 * err
			if e2 > -dy:
				err -= dy
				x1 += sx
			if e2 < dx:
				err += dx
				y1 += sy

	def _draw_rectangle(self, x1: int, y1: int, x2: int, y2: int, filled: bool = False):
		"""Draw rectangle"""
		min_x, max_x = min(x1, x2), max(x1, x2)
		min_y, max_y = min(y1, y2), max(y1, y2)

		if filled:
			for y in range(min_y, max_y + 1):
				for x in range(min_x, max_x + 1):
					self._draw_pixel(x, y)
		else:
			for x in range(min_x, max_x + 1):
				self._draw_pixel(x, min_y)
				self._draw_pixel(x, max_y)
			for y in range(min_y, max_y + 1):
				self._draw_pixel(min_x, y)
				self._draw_pixel(max_x, y)

	def _flip_horizontal(self):
		"""Flip tile horizontally"""
		if not self.current_tile:
			return
		self._save_undo()
		for y in range(8):
			for x in range(4):
				c1 = self.current_tile.get_pixel(x, y)
				c2 = self.current_tile.get_pixel(7 - x, y)
				self.current_tile.set_pixel(x, y, c2)
				self.current_tile.set_pixel(7 - x, y, c1)
		self.modified = True

	def _flip_vertical(self):
		"""Flip tile vertically"""
		if not self.current_tile:
			return
		self._save_undo()
		for y in range(4):
			for x in range(8):
				c1 = self.current_tile.get_pixel(x, y)
				c2 = self.current_tile.get_pixel(x, 7 - y)
				self.current_tile.set_pixel(x, y, c2)
				self.current_tile.set_pixel(x, 7 - y, c1)
		self.modified = True

	def _rotate_cw(self):
		"""Rotate tile clockwise"""
		if not self.current_tile:
			return
		self._save_undo()
		new_data = [[0 for _ in range(8)] for _ in range(8)]
		for y in range(8):
			for x in range(8):
				new_data[x][7 - y] = self.current_tile.get_pixel(x, y)
		for y in range(8):
			for x in range(8):
				self.current_tile.set_pixel(x, y, new_data[y][x])
		self.modified = True

	def _rotate_ccw(self):
		"""Rotate tile counter-clockwise"""
		if not self.current_tile:
			return
		self._save_undo()
		new_data = [[0 for _ in range(8)] for _ in range(8)]
		for y in range(8):
			for x in range(8):
				new_data[7 - x][y] = self.current_tile.get_pixel(x, y)
		for y in range(8):
			for x in range(8):
				self.current_tile.set_pixel(x, y, new_data[y][x])
		self.modified = True

	def handle_events(self):
		"""Handle pygame events"""
		mouse_pos = pygame.mouse.get_pos()
		mouse_clicked = False
		mouse_down = pygame.mouse.get_pressed()[0]
		mouse_right = pygame.mouse.get_pressed()[2]

		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				self.running = False

			elif event.type == pygame.KEYDOWN:
				if event.key == pygame.K_ESCAPE:
					self.running = False
				elif event.key == pygame.K_c and (event.mod & pygame.KMOD_CTRL):
					self.clipboard.copy_tile(self.current_tile)
					print("Copied tile")
				elif event.key == pygame.K_v and (event.mod & pygame.KMOD_CTRL):
					self._save_undo()
					self.clipboard.paste_to_tile(self.current_tile)
					self.modified = True
					print("Pasted tile")
				elif event.key == pygame.K_z and (event.mod & pygame.KMOD_CTRL):
					self._undo()
				elif event.key == pygame.K_y and (event.mod & pygame.KMOD_CTRL):
					self._redo()
				elif event.key == pygame.K_s and (event.mod & pygame.KMOD_CTRL):
					self.save()

			elif event.type == pygame.MOUSEBUTTONDOWN:
				if event.button == 1:
					mouse_clicked = True
					coords = self._get_pixel_coords(mouse_pos)
					if coords:
						if self.current_tool == Tool.PENCIL:
							self._save_undo()
							self.drawing = True
							self._draw_pixel(*coords)
						elif self.current_tool == Tool.FILL:
							self._save_undo()
							self._flood_fill(*coords)
						elif self.current_tool in [Tool.LINE, Tool.RECTANGLE, Tool.SELECT]:
							self.line_start = coords

			elif event.type == pygame.MOUSEMOTION:
				if self.drawing and self.current_tool == Tool.PENCIL:
					coords = self._get_pixel_coords(mouse_pos)
					if coords:
						self._draw_pixel(*coords)
						self.modified = True

			elif event.type == pygame.MOUSEBUTTONUP:
				if event.button == 1:
					self.drawing = False
					coords = self._get_pixel_coords(mouse_pos)
					if coords and self.line_start:
						self._save_undo()
						if self.current_tool == Tool.LINE:
							self._draw_line(*self.line_start, *coords)
						elif self.current_tool == Tool.RECTANGLE:
							self._draw_rectangle(*self.line_start, *coords, filled=False)
						elif self.current_tool == Tool.SELECT:
							self.selection_start = self.line_start
							self.selection_end = coords
						self.modified = True
					self.line_start = None

		# Update palette swatches
		for i in range(16):
			row = i // 8
			col = i % 8
			sx = self.swatch_x + col * (self.swatch_size + 2)
			sy = self.swatch_y + row * (self.swatch_size + 2)
			swatch_rect = pygame.Rect(sx, sy, self.swatch_size, self.swatch_size)
			if swatch_rect.collidepoint(mouse_pos) and mouse_clicked:
				self.selected_color = i

		# Update tool buttons
		for tool, button in self.tool_buttons.items():
			if button.update(mouse_pos, mouse_clicked):
				self.current_tool = tool

		# Update edit buttons
		if self.copy_button.update(mouse_pos, mouse_clicked):
			self.clipboard.copy_tile(self.current_tile)

		if self.paste_button.update(mouse_pos, mouse_clicked):
			self._save_undo()
			self.clipboard.paste_to_tile(self.current_tile)
			self.modified = True

		if self.undo_button.update(mouse_pos, mouse_clicked):
			self._undo()

		if self.redo_button.update(mouse_pos, mouse_clicked):
			self._redo()

		# Transform buttons
		if self.flip_h_button.update(mouse_pos, mouse_clicked):
			self._flip_horizontal()

		if self.flip_v_button.update(mouse_pos, mouse_clicked):
			self._flip_vertical()

		if self.rotate_cw_button.update(mouse_pos, mouse_clicked):
			self._rotate_cw()

		if self.rotate_ccw_button.update(mouse_pos, mouse_clicked):
			self._rotate_ccw()

		# File buttons
		if self.save_button.update(mouse_pos, mouse_clicked):
			self.save()

		if self.clear_button.update(mouse_pos, mouse_clicked):
			self._save_undo()
			if self.current_tile:
				for y in range(8):
					for x in range(8):
						self.current_tile.set_pixel(x, y, 0)
			self.modified = True

	def save(self):
		"""Save tile to ROM"""
		if self.rom_path and self.current_tile:
			print("Saved (not implemented - would save to ROM)")
			self.modified = False

	def draw(self):
		"""Draw editor"""
		self.screen.fill(COLOR_BG)

		# Title
		title_text = "FFMQ Enhanced Tile Editor"
		if self.modified:
			title_text += " *"
		title = self.title_font.render(title_text, True, COLOR_TEXT)
		self.screen.blit(title, (20, 20))

		# Tool buttons
		for tool, button in self.tool_buttons.items():
			# Highlight current tool
			if tool == self.current_tool:
				highlight = pygame.Rect(button.rect.x - 2, button.rect.y - 2,
									   button.rect.width + 4, button.rect.height + 4)
				pygame.draw.rect(self.screen, COLOR_SELECTED, highlight, 3)
			button.draw(self.screen, self.font)

		# Edit buttons
		self.copy_button.draw(self.screen, self.font)
		self.paste_button.draw(self.screen, self.font)
		self.undo_button.draw(self.screen, self.font)
		self.redo_button.draw(self.screen, self.font)

		# Transform buttons
		self.flip_h_button.draw(self.screen, self.font)
		self.flip_v_button.draw(self.screen, self.font)
		self.rotate_cw_button.draw(self.screen, self.font)
		self.rotate_ccw_button.draw(self.screen, self.font)

		# File buttons
		self.save_button.draw(self.screen, self.font)
		self.clear_button.draw(self.screen, self.font)

		# Draw tile canvas
		if self.current_tile and self.current_palette:
			for y in range(8):
				for x in range(8):
					color_idx = self.current_tile.get_pixel(x, y)
					color = self.current_palette.colors[color_idx]
					r, g, b = color.to_rgb888()

					px = self.canvas_x + x * self.pixel_size
					py = self.canvas_y + y * self.pixel_size
					pixel_rect = pygame.Rect(px, py, self.pixel_size, self.pixel_size)

					pygame.draw.rect(self.screen, (r, g, b), pixel_rect)
					pygame.draw.rect(self.screen, COLOR_GRID, pixel_rect, 1)

			# Canvas border
			canvas_rect = pygame.Rect(self.canvas_x, self.canvas_y, 8 * self.pixel_size, 8 * self.pixel_size)
			pygame.draw.rect(self.screen, COLOR_BORDER, canvas_rect, 3)

		# Draw palette
		if self.current_palette:
			palette_label = self.font.render("Palette", True, COLOR_TEXT)
			self.screen.blit(palette_label, (self.swatch_x, self.swatch_y - 30))

			for i in range(16):
				row = i // 8
				col = i % 8
				sx = self.swatch_x + col * (self.swatch_size + 2)
				sy = self.swatch_y + row * (self.swatch_size + 2)

				color = self.current_palette.colors[i]
				r, g, b = color.to_rgb888()

				swatch_rect = pygame.Rect(sx, sy, self.swatch_size, self.swatch_size)
				pygame.draw.rect(self.screen, (r, g, b), swatch_rect)

				border_color = COLOR_SELECTED if i == self.selected_color else COLOR_BORDER
				border_width = 3 if i == self.selected_color else 1
				pygame.draw.rect(self.screen, border_color, swatch_rect, border_width)

		# Instructions
		inst_x = 1050
		inst_y = 180
		instructions = [
			"Keyboard Shortcuts:",
			"Ctrl+C: Copy tile",
			"Ctrl+V: Paste tile",
			"Ctrl+Z: Undo",
			"Ctrl+Y: Redo",
			"Ctrl+S: Save",
			"ESC: Quit",
			"",
			"Tools:",
			"Pencil: Draw pixels",
			"Fill: Flood fill",
			"Line: Draw lines",
			"Rect: Draw rectangles",
			"Select: Select region",
		]

		for i, text in enumerate(instructions):
			color = COLOR_TEXT if text.endswith(":") else (180, 180, 190)
			text_surf = self.small_font.render(text, True, color)
			self.screen.blit(text_surf, (inst_x, inst_y + i * 20))

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
	import sys

	editor = EnhancedTileEditor()

	if len(sys.argv) > 1:
		editor.load_rom(sys.argv[1])
	else:
		print("Usage: python enhanced_tile_editor.py <rom_path>")
		print("Starting editor without ROM...")

	editor.run()


if __name__ == "__main__":
	main()
