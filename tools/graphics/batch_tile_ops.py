"""
Batch Tile Operations for Final Fantasy Mystic Quest
Batch processing, transformations, and pattern generation for tiles.
"""

import pygame
import json
from dataclasses import dataclass
from typing import List, Tuple, Optional, Set
from copy import deepcopy

# Initialize Pygame
pygame.init()

# Constants
WINDOW_WIDTH = 1600
WINDOW_HEIGHT = 900
FPS = 60
TILE_SIZE = 8  # 8x8 pixels
DISPLAY_SCALE = 6  # Display tiles at 48x48

# Colors
COLOR_BG = (30, 30, 40)
COLOR_PANEL_BG = (45, 45, 55)
COLOR_BORDER = (80, 80, 90)
COLOR_TEXT = (220, 220, 230)
COLOR_HIGHLIGHT = (100, 150, 255)
COLOR_SUCCESS = (100, 255, 100)
COLOR_WARNING = (255, 200, 100)
COLOR_ERROR = (255, 100, 100)
COLOR_SELECTED = (255, 200, 50)
COLOR_GRID = (60, 60, 70)


@dataclass
class Tile:
	"""8x8 tile with 4bpp color indices"""
	pixels: List[List[int]]  # 8x8 grid of color indices (0-15)

	def __post_init__(self):
		# Ensure 8x8
		self.pixels = [row[:8] + [0] * (8 - len(row[:8])) for row in self.pixels[:8]]
		while len(self.pixels) < 8:
			self.pixels.append([0] * 8)

	def copy(self) -> 'Tile':
		"""Create deep copy"""
		return Tile(deepcopy(self.pixels))

	def flip_horizontal(self) -> 'Tile':
		"""Flip tile horizontally"""
		new_pixels = [row[::-1] for row in self.pixels]
		return Tile(new_pixels)

	def flip_vertical(self) -> 'Tile':
		"""Flip tile vertically"""
		return Tile(self.pixels[::-1])

	def rotate_cw(self) -> 'Tile':
		"""Rotate 90° clockwise"""
		new_pixels = [[self.pixels[7-col][row] for col in range(8)] for row in range(8)]
		return Tile(new_pixels)

	def rotate_ccw(self) -> 'Tile':
		"""Rotate 90° counter-clockwise"""
		new_pixels = [[self.pixels[col][7-row] for col in range(8)] for row in range(8)]
		return Tile(new_pixels)

	def invert_colors(self, max_color: int = 15) -> 'Tile':
		"""Invert color indices"""
		new_pixels = [[max_color - pixel for pixel in row] for row in self.pixels]
		return Tile(new_pixels)

	def remap_colors(self, color_map: dict) -> 'Tile':
		"""Remap colors using a dictionary"""
		new_pixels = [[color_map.get(pixel, pixel) for pixel in row] for row in self.pixels]
		return Tile(new_pixels)

	def replace_color(self, old_color: int, new_color: int) -> 'Tile':
		"""Replace all instances of one color with another"""
		new_pixels = [[new_color if pixel == old_color else pixel for pixel in row] for row in self.pixels]
		return Tile(new_pixels)

	def shift_colors(self, amount: int) -> 'Tile':
		"""Shift all color indices by amount (wrapping at 16)"""
		new_pixels = [[(pixel + amount) % 16 for pixel in row] for row in self.pixels]
		return Tile(new_pixels)

	def is_identical(self, other: 'Tile') -> bool:
		"""Check if two tiles are identical"""
		return self.pixels == other.pixels

	def count_colors(self) -> int:
		"""Count unique colors used"""
		colors = set()
		for row in self.pixels:
			colors.update(row)
		return len(colors)

	def get_used_colors(self) -> Set[int]:
		"""Get set of used color indices"""
		colors = set()
		for row in self.pixels:
			colors.update(row)
		return colors


class TileDisplay:
	"""Display a tile with optional selection"""
	def __init__(self, x, y, tile: Tile, tile_id: int, palette: List[Tuple[int, int, int]]):
		self.rect = pygame.Rect(x, y, TILE_SIZE * DISPLAY_SCALE + 2, TILE_SIZE * DISPLAY_SCALE + 2)
		self.tile = tile
		self.tile_id = tile_id
		self.palette = palette
		self.selected = False
		self.hovered = False

	def draw(self, screen):
		# Border
		border_color = COLOR_SELECTED if self.selected else (COLOR_HIGHLIGHT if self.hovered else COLOR_BORDER)
		border_width = 3 if self.selected else 2
		pygame.draw.rect(screen, border_color, self.rect, border_width)

		# Draw tile pixels
		for y in range(TILE_SIZE):
			for x in range(TILE_SIZE):
				color_idx = self.tile.pixels[y][x]
				color = self.palette[color_idx]

				pixel_x = self.rect.x + 1 + x * DISPLAY_SCALE
				pixel_y = self.rect.y + 1 + y * DISPLAY_SCALE
				pixel_rect = pygame.Rect(pixel_x, pixel_y, DISPLAY_SCALE, DISPLAY_SCALE)

				pygame.draw.rect(screen, color, pixel_rect)

	def contains_point(self, pos) -> bool:
		return self.rect.collidepoint(pos)


class Button:
	"""Interactive button"""
	def __init__(self, x, y, width, height, text, callback, enabled=True):
		self.rect = pygame.Rect(x, y, width, height)
		self.text = text
		self.callback = callback
		self.enabled = enabled
		self.hovered = False

	def draw(self, screen, font):
		if not self.enabled:
			color = (60, 60, 70)
			text_color = (100, 100, 110)
		else:
			color = COLOR_HIGHLIGHT if self.hovered else COLOR_BORDER
			text_color = COLOR_TEXT

		pygame.draw.rect(screen, COLOR_PANEL_BG, self.rect)
		pygame.draw.rect(screen, color, self.rect, 2)

		text_surf = font.render(self.text, True, text_color)
		text_rect = text_surf.get_rect(center=self.rect.center)
		screen.blit(text_surf, text_rect)

	def handle_event(self, event):
		if not self.enabled:
			return False

		if event.type == pygame.MOUSEMOTION:
			self.hovered = self.rect.collidepoint(event.pos)
		elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
			if self.rect.collidepoint(event.pos):
				self.callback()
				return True
		return False


class TileGrid:
	"""Grid of tiles for selection and display"""
	def __init__(self, x, y, width, height, tiles_per_row: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.tiles_per_row = tiles_per_row
		self.tile_displays: List[TileDisplay] = []
		self.selected_tiles: Set[int] = set()
		self.scroll_y = 0

	def set_tiles(self, tiles: List[Tile], palette: List[Tuple[int, int, int]]):
		"""Update displayed tiles"""
		self.tile_displays = []

		tile_size = TILE_SIZE * DISPLAY_SCALE + 2
		margin = 10

		for i, tile in enumerate(tiles):
			row = i // self.tiles_per_row
			col = i % self.tiles_per_row

			x = self.rect.x + margin + col * (tile_size + margin)
			y = self.rect.y + 50 + margin + row * (tile_size + margin)

			display = TileDisplay(x, y, tile, i, palette)
			self.tile_displays.append(display)

	def draw(self, screen, font, small_font):
		# Background
		pygame.draw.rect(screen, COLOR_PANEL_BG, self.rect)
		pygame.draw.rect(screen, COLOR_BORDER, self.rect, 2)

		# Title
		title = font.render("Tile Set", True, COLOR_TEXT)
		screen.blit(title, (self.rect.x + 10, self.rect.y + 10))

		# Count
		count_text = small_font.render(
			f"{len(self.tile_displays)} tiles | {len(self.selected_tiles)} selected",
			True, (180, 180, 200)
		)
		screen.blit(count_text, (self.rect.x + 10, self.rect.y + 32))

		# Clip to grid area
		clip_rect = pygame.Rect(self.rect.x, self.rect.y + 50, self.rect.width, self.rect.height - 50)
		screen.set_clip(clip_rect)

		# Draw tiles with scroll
		for display in self.tile_displays:
			original_y = display.rect.y
			display.rect.y += self.scroll_y

			if display.rect.bottom > self.rect.y + 50 and display.rect.top < self.rect.bottom:
				display.draw(screen)

			display.rect.y = original_y

		screen.set_clip(None)

	def handle_click(self, pos, multi_select: bool = False):
		"""Handle click in grid"""
		adjusted_pos = (pos[0], pos[1] - self.scroll_y)

		for display in self.tile_displays:
			if display.contains_point(adjusted_pos):
				if multi_select:
					# Toggle selection
					if display.tile_id in self.selected_tiles:
						self.selected_tiles.remove(display.tile_id)
						display.selected = False
					else:
						self.selected_tiles.add(display.tile_id)
						display.selected = True
				else:
					# Single selection
					for d in self.tile_displays:
						d.selected = False
					self.selected_tiles.clear()

					display.selected = True
					self.selected_tiles.add(display.tile_id)

				return True

		return False

	def handle_hover(self, pos):
		"""Handle mouse hover"""
		adjusted_pos = (pos[0], pos[1] - self.scroll_y)

		for display in self.tile_displays:
			display.hovered = display.contains_point(adjusted_pos)

	def scroll(self, amount):
		"""Scroll the grid"""
		self.scroll_y += amount
		# Calculate max scroll based on content height
		tiles_rows = (len(self.tile_displays) + self.tiles_per_row - 1) // self.tiles_per_row
		content_height = tiles_rows * (TILE_SIZE * DISPLAY_SCALE + 2 + 10) + 50
		max_scroll = max(0, content_height - self.rect.height)
		self.scroll_y = max(-max_scroll, min(0, self.scroll_y))

	def select_all(self):
		"""Select all tiles"""
		self.selected_tiles = {d.tile_id for d in self.tile_displays}
		for d in self.tile_displays:
			d.selected = True

	def clear_selection(self):
		"""Clear all selections"""
		self.selected_tiles.clear()
		for d in self.tile_displays:
			d.selected = False


class OperationsPanel:
	"""Panel with batch operation buttons and info"""
	def __init__(self, x, y, width, height):
		self.rect = pygame.Rect(x, y, width, height)

	def draw(self, screen, font, small_font):
		# Background
		pygame.draw.rect(screen, COLOR_PANEL_BG, self.rect)
		pygame.draw.rect(screen, COLOR_BORDER, self.rect, 2)

		# Title
		title = font.render("Batch Operations", True, COLOR_TEXT)
		screen.blit(title, (self.rect.x + 10, self.rect.y + 10))

		# Instructions
		instructions = [
			"Select tiles and apply operations:",
			"",
			"• Click to select single tile",
			"• Ctrl+Click for multi-select",
			"• Transformations affect selected",
			"• Color ops modify palette usage",
		]

		y = self.rect.y + 50
		for line in instructions:
			text = small_font.render(line, True, (180, 180, 200))
			screen.blit(text, (self.rect.x + 10, y))
			y += 22


class BatchTileTool:
	"""Main batch tile operations tool"""
	def __init__(self):
		self.screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
		pygame.display.set_caption("FFMQ Batch Tile Operations")
		self.clock = pygame.time.Clock()
		self.running = True

		# Fonts
		self.font = pygame.font.Font(None, 28)
		self.small_font = pygame.font.Font(None, 20)
		self.title_font = pygame.font.Font(None, 36)

		# Test palette (grayscale for now)
		self.palette = [(i * 17, i * 17, i * 17) for i in range(16)]

		# Tiles
		self.tiles: List[Tile] = self._generate_test_tiles()
		self.undo_stack: List[List[Tile]] = []
		self.max_undo = 20

		# UI Components
		self.tile_grid = TileGrid(10, 80, 950, 810, 10)
		self.tile_grid.set_tiles(self.tiles, self.palette)

		self.operations_panel = OperationsPanel(980, 80, 610, 200)

		# Buttons - Transformations
		transform_x = 980
		transform_y = 300
		transform_buttons = [
			Button(transform_x, transform_y, 145, 35, "Flip H", lambda: self.apply_op("flip_h")),
			Button(transform_x + 155, transform_y, 145, 35, "Flip V", lambda: self.apply_op("flip_v")),
			Button(transform_x + 310, transform_y, 145, 35, "Rotate CW", lambda: self.apply_op("rotate_cw")),
			Button(transform_x + 465, transform_y, 145, 35, "Rotate CCW", lambda: self.apply_op("rotate_ccw")),
		]

		# Color operations
		color_y = transform_y + 50
		color_buttons = [
			Button(transform_x, color_y, 145, 35, "Invert Colors", lambda: self.apply_op("invert")),
			Button(transform_x + 155, color_y, 145, 35, "Shift +1", lambda: self.apply_op("shift_1")),
			Button(transform_x + 310, color_y, 145, 35, "Shift -1", lambda: self.apply_op("shift_n1")),
			Button(transform_x + 465, color_y, 145, 35, "Grayscale", lambda: self.apply_op("grayscale")),
		]

		# Utility operations
		utility_y = color_y + 50
		utility_buttons = [
			Button(transform_x, utility_y, 200, 35, "Select All", self.select_all),
			Button(transform_x + 210, utility_y, 200, 35, "Clear Selection", self.clear_selection),
			Button(transform_x + 420, utility_y, 185, 35, "Remove Duplicates", self.remove_duplicates),
		]

		# Analysis operations
		analysis_y = utility_y + 50
		analysis_buttons = [
			Button(transform_x, analysis_y, 200, 35, "Find Similar", self.find_similar),
			Button(transform_x + 210, analysis_y, 200, 35, "Analyze Colors", self.analyze_colors),
			Button(transform_x + 420, analysis_y, 185, 35, "Generate Variants", self.generate_variants),
		]

		# File operations
		file_y = analysis_y + 50
		file_buttons = [
			Button(transform_x, file_y, 200, 35, "Undo", self.undo),
			Button(transform_x + 210, file_y, 200, 35, "Export JSON", self.export_json),
			Button(transform_x + 420, file_y, 185, 35, "Save to ROM", self.save_rom),
		]

		self.buttons = transform_buttons + color_buttons + utility_buttons + analysis_buttons + file_buttons

		# Status message
		self.status_message = ""
		self.status_color = COLOR_TEXT
		self.status_timer = 0

	def _generate_test_tiles(self) -> List[Tile]:
		"""Generate some test tiles"""
		tiles = []

		# Solid colors
		for color in range(16):
			pixels = [[color] * 8 for _ in range(8)]
			tiles.append(Tile(pixels))

		# Checkerboard patterns
		for i in range(4):
			c1, c2 = i * 2, i * 2 + 1
			pixels = [[(c1 if (x + y) % 2 == 0 else c2) for x in range(8)] for y in range(8)]
			tiles.append(Tile(pixels))

		# Gradients
		for direction in range(4):
			if direction == 0:  # Horizontal
				pixels = [[x * 2 for x in range(8)] for _ in range(8)]
			elif direction == 1:  # Vertical
				pixels = [[y * 2 for _ in range(8)] for y in range(8)]
			elif direction == 2:  # Diagonal
				pixels = [[(x + y) % 16 for x in range(8)] for y in range(8)]
			else:  # Center
				pixels = [[min(abs(x - 4) + abs(y - 4), 15) for x in range(8)] for y in range(8)]
			tiles.append(Tile(pixels))

		# Border pattern
		border_pixels = [[0] * 8 for _ in range(8)]
		for x in range(8):
			border_pixels[0][x] = 15
			border_pixels[7][x] = 15
		for y in range(8):
			border_pixels[y][0] = 15
			border_pixels[y][7] = 15
		tiles.append(Tile(border_pixels))

		# Cross pattern
		cross_pixels = [[0] * 8 for _ in range(8)]
		for i in range(8):
			cross_pixels[i][i] = 10
			cross_pixels[i][7-i] = 10
		tiles.append(Tile(cross_pixels))

		# Circle pattern
		circle_pixels = [[0] * 8 for _ in range(8)]
		center = 3.5
		radius = 3
		for y in range(8):
			for x in range(8):
				dist = ((x - center)**2 + (y - center)**2)**0.5
				if abs(dist - radius) < 0.8:
					circle_pixels[y][x] = 12
		tiles.append(Tile(circle_pixels))

		return tiles

	def save_undo(self):
		"""Save current state to undo stack"""
		self.undo_stack.append([tile.copy() for tile in self.tiles])
		if len(self.undo_stack) > self.max_undo:
			self.undo_stack.pop(0)

	def undo(self):
		"""Undo last operation"""
		if self.undo_stack:
			self.tiles = self.undo_stack.pop()
			self.tile_grid.set_tiles(self.tiles, self.palette)
			self.show_status("Undone", COLOR_SUCCESS)
		else:
			self.show_status("Nothing to undo", COLOR_WARNING)

	def apply_op(self, operation: str):
		"""Apply operation to selected tiles"""
		if not self.tile_grid.selected_tiles:
			self.show_status("No tiles selected", COLOR_WARNING)
			return

		self.save_undo()

		count = 0
		for tile_id in self.tile_grid.selected_tiles:
			if tile_id < len(self.tiles):
				tile = self.tiles[tile_id]

				if operation == "flip_h":
					self.tiles[tile_id] = tile.flip_horizontal()
				elif operation == "flip_v":
					self.tiles[tile_id] = tile.flip_vertical()
				elif operation == "rotate_cw":
					self.tiles[tile_id] = tile.rotate_cw()
				elif operation == "rotate_ccw":
					self.tiles[tile_id] = tile.rotate_ccw()
				elif operation == "invert":
					self.tiles[tile_id] = tile.invert_colors()
				elif operation == "shift_1":
					self.tiles[tile_id] = tile.shift_colors(1)
				elif operation == "shift_n1":
					self.tiles[tile_id] = tile.shift_colors(-1)
				elif operation == "grayscale":
					# Simple grayscale: average all color indices to mid-range
					avg = sum(sum(row) for row in tile.pixels) // 64
					new_pixels = [[avg] * 8 for _ in range(8)]
					self.tiles[tile_id] = Tile(new_pixels)

				count += 1

		self.tile_grid.set_tiles(self.tiles, self.palette)
		self.show_status(f"Applied {operation} to {count} tiles", COLOR_SUCCESS)

	def select_all(self):
		"""Select all tiles"""
		self.tile_grid.select_all()
		self.show_status(f"Selected all {len(self.tiles)} tiles", COLOR_SUCCESS)

	def clear_selection(self):
		"""Clear selection"""
		self.tile_grid.clear_selection()
		self.show_status("Selection cleared", COLOR_SUCCESS)

	def remove_duplicates(self):
		"""Remove duplicate tiles"""
		self.save_undo()

		unique_tiles = []
		seen_tiles = []
		removed = 0

		for tile in self.tiles:
			is_duplicate = False
			for seen in seen_tiles:
				if tile.is_identical(seen):
					is_duplicate = True
					removed += 1
					break

			if not is_duplicate:
				unique_tiles.append(tile)
				seen_tiles.append(tile)

		self.tiles = unique_tiles
		self.tile_grid.set_tiles(self.tiles, self.palette)
		self.tile_grid.clear_selection()

		self.show_status(f"Removed {removed} duplicate tiles", COLOR_SUCCESS)

	def find_similar(self):
		"""Find tiles similar to selected (simple matching by color count)"""
		if not self.tile_grid.selected_tiles:
			self.show_status("Select a tile to find similar", COLOR_WARNING)
			return

		# Get first selected tile as reference
		ref_id = min(self.tile_grid.selected_tiles)
		ref_tile = self.tiles[ref_id]
		ref_colors = ref_tile.count_colors()

		# Find tiles with same color count
		similar = []
		for i, tile in enumerate(self.tiles):
			if i != ref_id and tile.count_colors() == ref_colors:
				similar.append(i)

		# Select similar tiles
		self.tile_grid.clear_selection()
		self.tile_grid.selected_tiles = set(similar + [ref_id])
		for display in self.tile_grid.tile_displays:
			display.selected = display.tile_id in self.tile_grid.selected_tiles

		self.show_status(f"Found {len(similar)} similar tiles", COLOR_SUCCESS)

	def analyze_colors(self):
		"""Analyze color usage across selected tiles"""
		if not self.tile_grid.selected_tiles:
			self.show_status("No tiles selected", COLOR_WARNING)
			return

		all_colors = set()
		for tile_id in self.tile_grid.selected_tiles:
			if tile_id < len(self.tiles):
				all_colors.update(self.tiles[tile_id].get_used_colors())

		self.show_status(f"Selected tiles use {len(all_colors)} unique colors", COLOR_SUCCESS)
		print(f"Colors used: {sorted(all_colors)}")

	def generate_variants(self):
		"""Generate color-shifted variants of selected tiles"""
		if not self.tile_grid.selected_tiles:
			self.show_status("No tiles selected", COLOR_WARNING)
			return

		self.save_undo()

		variants = []
		for tile_id in self.tile_grid.selected_tiles:
			if tile_id < len(self.tiles):
				original = self.tiles[tile_id]
				# Generate 3 color-shifted variants
				for shift in [4, 8, 12]:
					variants.append(original.shift_colors(shift))

		self.tiles.extend(variants)
		self.tile_grid.set_tiles(self.tiles, self.palette)
		self.show_status(f"Generated {len(variants)} variants", COLOR_SUCCESS)

	def export_json(self):
		"""Export tiles to JSON"""
		data = {
			'tiles': [
				{
					'id': i,
					'pixels': tile.pixels,
					'colors_used': tile.count_colors()
				}
				for i, tile in enumerate(self.tiles)
			]
		}

		filename = 'tiles_export.json'
		with open(filename, 'w') as f:
			json.dump(data, f, indent=2)

		self.show_status(f"Exported {len(self.tiles)} tiles to {filename}", COLOR_SUCCESS)

	def save_rom(self):
		"""Save tiles to ROM (placeholder)"""
		print(f"Would save {len(self.tiles)} tiles to ROM")
		self.show_status(f"Saved {len(self.tiles)} tiles to ROM", COLOR_SUCCESS)

	def show_status(self, message: str, color):
		"""Show status message"""
		self.status_message = message
		self.status_color = color
		self.status_timer = FPS * 3  # 3 seconds

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
					if self.tile_grid.rect.collidepoint(event.pos):
						multi_select = pygame.key.get_mods() & pygame.KMOD_CTRL
						self.tile_grid.handle_click(event.pos, multi_select)

				elif event.button == 4:  # Scroll up
					if self.tile_grid.rect.collidepoint(event.pos):
						self.tile_grid.scroll(30)
				elif event.button == 5:  # Scroll down
					if self.tile_grid.rect.collidepoint(event.pos):
						self.tile_grid.scroll(-30)

			elif event.type == pygame.MOUSEMOTION:
				if self.tile_grid.rect.collidepoint(event.pos):
					self.tile_grid.handle_hover(event.pos)

			# Keyboard shortcuts
			elif event.type == pygame.KEYDOWN:
				if event.key == pygame.K_ESCAPE:
					self.running = False
				elif event.key == pygame.K_a and (event.mod & pygame.KMOD_CTRL):
					self.select_all()
				elif event.key == pygame.K_z and (event.mod & pygame.KMOD_CTRL):
					self.undo()
				elif event.key == pygame.K_e and (event.mod & pygame.KMOD_CTRL):
					self.export_json()

	def draw(self):
		"""Draw the tool"""
		self.screen.fill(COLOR_BG)

		# Title bar
		title_bg = pygame.Rect(0, 0, WINDOW_WIDTH, 70)
		pygame.draw.rect(self.screen, COLOR_PANEL_BG, title_bg)
		pygame.draw.line(self.screen, COLOR_BORDER, (0, 70), (WINDOW_WIDTH, 70), 2)

		title = self.title_font.render("Batch Tile Operations", True, COLOR_TEXT)
		self.screen.blit(title, (20, 20))

		# Status message
		if self.status_timer > 0:
			status_text = self.small_font.render(self.status_message, True, self.status_color)
			self.screen.blit(status_text, (WINDOW_WIDTH - status_text.get_width() - 20, 25))
			self.status_timer -= 1

		# Draw components
		self.tile_grid.draw(self.screen, self.font, self.small_font)
		self.operations_panel.draw(self.screen, self.font, self.small_font)

		# Draw buttons
		for button in self.buttons:
			button.draw(self.screen, self.small_font)

		pygame.display.flip()

	def run(self):
		"""Main loop"""
		while self.running:
			self.handle_events()
			self.draw()
			self.clock.tick(FPS)

		pygame.quit()


def main():
	"""Entry point"""
	tool = BatchTileTool()
	tool.run()


if __name__ == '__main__':
	main()
