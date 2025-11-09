"""
Sprite Composition Editor for FFMQ
Multi-tile sprite builder with visual tile selection and arrangement
"""

import pygame
from typing import Optional, List, Tuple, Dict
from dataclasses import dataclass
from utils.graphics_data import Sprite, SpriteSize, Tile, Palette, Tileset
from utils.graphics_database import GraphicsDatabase


# Color constants
COLOR_BG = (40, 45, 50)
COLOR_PANEL = (55, 60, 65)
COLOR_PANEL_LIGHT = (70, 75, 80)
COLOR_BORDER = (100, 105, 110)
COLOR_TEXT = (220, 225, 230)
COLOR_SELECTED = (90, 140, 210)
COLOR_GRID = (80, 85, 90)
COLOR_HOVER = (110, 150, 220)
COLOR_TILE_BG = (50, 50, 50)


@dataclass
class TilePosition:
	"""Tile position in sprite"""
	tile_id: int
	x: int  # Position in sprite grid (0-3)
	y: int  # Position in sprite grid (0-7)


class TileGridCell:
	"""Single cell in tile selection grid"""
	def __init__(self, x: int, y: int, size: int, tile_id: int):
		self.rect = pygame.Rect(x, y, size, size)
		self.tile_id = tile_id
		self.hover = False
		self.selected = False

	def update(self, mouse_pos: Tuple[int, int], mouse_clicked: bool) -> bool:
		"""Update cell, return True if clicked"""
		self.hover = self.rect.collidepoint(mouse_pos)
		return self.hover and mouse_clicked

	def draw(self, surface: pygame.Surface, tile_surf: Optional[pygame.Surface]):
		"""Draw grid cell"""
		# Background
		bg_color = COLOR_SELECTED if self.selected else (COLOR_HOVER if self.hover else COLOR_TILE_BG)
		pygame.draw.rect(surface, bg_color, self.rect)

		# Tile image
		if tile_surf:
			scaled = pygame.transform.scale(tile_surf, (self.rect.width - 4, self.rect.height - 4))
			surface.blit(scaled, (self.rect.x + 2, self.rect.y + 2))

		# Border
		border_color = COLOR_SELECTED if self.selected else COLOR_BORDER
		border_width = 2 if self.selected else 1
		pygame.draw.rect(surface, border_color, self.rect, border_width)


class SpriteCanvas:
	"""Canvas for arranging tiles into sprite"""
	def __init__(self, x: int, y: int, sprite_size: SpriteSize):
		self.x = x
		self.y = y
		self.sprite_size = sprite_size
		self.tile_positions: List[TilePosition] = []
		self.grid_size = 64  # Size of each 8x8 tile cell
		self.selected_position: Optional[TilePosition] = None

	def set_sprite_size(self, sprite_size: SpriteSize):
		"""Change sprite size"""
		self.sprite_size = sprite_size
		# Clear positions that don't fit
		width, height = self._get_dimensions()
		self.tile_positions = [pos for pos in self.tile_positions 
								if pos.x < width // 8 and pos.y < height // 8]

	def _get_dimensions(self) -> Tuple[int, int]:
		"""Get sprite dimensions in pixels"""
		size_map = {
			SpriteSize.SIZE_8x8: (8, 8),
			SpriteSize.SIZE_16x16: (16, 16),
			SpriteSize.SIZE_24x24: (24, 24),
			SpriteSize.SIZE_32x32: (32, 32),
			SpriteSize.SIZE_16x32: (16, 32),
			SpriteSize.SIZE_32x64: (32, 64),
		}
		return size_map.get(self.sprite_size, (16, 16))

	def add_tile(self, tile_id: int, grid_x: int, grid_y: int):
		"""Add tile at grid position"""
		# Remove existing tile at position
		self.tile_positions = [pos for pos in self.tile_positions 
								if not (pos.x == grid_x and pos.y == grid_y)]
		# Add new tile
		self.tile_positions.append(TilePosition(tile_id, grid_x, grid_y))

	def remove_tile(self, grid_x: int, grid_y: int):
		"""Remove tile at grid position"""
		self.tile_positions = [pos for pos in self.tile_positions 
								if not (pos.x == grid_x and pos.y == grid_y)]

	def get_tile_at(self, grid_x: int, grid_y: int) -> Optional[int]:
		"""Get tile ID at grid position"""
		for pos in self.tile_positions:
			if pos.x == grid_x and pos.y == grid_y:
				return pos.tile_id
		return None

	def update(self, mouse_pos: Tuple[int, int], mouse_clicked: bool, current_tile: Optional[int]) -> bool:
		"""Update canvas, return True if modified"""
		width, height = self._get_dimensions()
		grid_width = width // 8
		grid_height = height // 8

		# Calculate mouse grid position
		rel_x = mouse_pos[0] - self.x
		rel_y = mouse_pos[1] - self.y

		if 0 <= rel_x < grid_width * self.grid_size and 0 <= rel_y < grid_height * self.grid_size:
			grid_x = rel_x // self.grid_size
			grid_y = rel_y // self.grid_size

			if mouse_clicked:
				if current_tile is not None:
					self.add_tile(current_tile, grid_x, grid_y)
					return True
				else:
					# Right click or no tile selected = remove
					self.remove_tile(grid_x, grid_y)
					return True

		return False

	def draw(self, surface: pygame.Surface, font: pygame.font.Font, tileset: Optional[Tileset], 
			palette: Optional[Palette]):
		"""Draw sprite canvas"""
		width, height = self._get_dimensions()
		grid_width = width // 8
		grid_height = height // 8

		# Draw grid
		for gy in range(grid_height):
			for gx in range(grid_width):
				cell_x = self.x + gx * self.grid_size
				cell_y = self.y + gy * self.grid_size
				cell_rect = pygame.Rect(cell_x, cell_y, self.grid_size, self.grid_size)

				# Background
				pygame.draw.rect(surface, COLOR_PANEL, cell_rect)

				# Draw tile if present
				tile_id = self.get_tile_at(gx, gy)
				if tile_id is not None and tileset and palette:
					if 0 <= tile_id < len(tileset.tiles):
						tile = tileset.tiles[tile_id]
						tile_surf = self._render_tile(tile, palette)
						if tile_surf:
							scaled = pygame.transform.scale(tile_surf, (self.grid_size - 4, self.grid_size - 4))
							surface.blit(scaled, (cell_x + 2, cell_y + 2))

				# Grid lines
				pygame.draw.rect(surface, COLOR_GRID, cell_rect, 1)

		# Border
		canvas_rect = pygame.Rect(self.x, self.y, grid_width * self.grid_size, grid_height * self.grid_size)
		pygame.draw.rect(surface, COLOR_BORDER, canvas_rect, 3)

	def _render_tile(self, tile: Tile, palette: Palette) -> Optional[pygame.Surface]:
		"""Render tile to surface"""
		surf = pygame.Surface((8, 8))
		for y in range(8):
			for x in range(8):
				color_idx = tile.get_pixel(x, y)
				if 0 <= color_idx < len(palette.colors):
					color = palette.colors[color_idx]
					r, g, b = color.to_rgb888()
					surf.set_at((x, y), (r, g, b))
		return surf

	def to_sprite(self, sprite_id: int, palette_id: int, name: str = "") -> Sprite:
		"""Convert canvas to Sprite object"""
		tiles = [pos.tile_id for pos in sorted(self.tile_positions, key=lambda p: (p.y, p.x))]
		return Sprite(
			sprite_id=sprite_id,
			size=self.sprite_size,
			tiles=tiles,
			palette_id=palette_id,
			name=name
		)


class Button:
	"""Simple button"""
	def __init__(self, x: int, y: int, width: int, height: int, text: str):
		self.rect = pygame.Rect(x, y, width, height)
		self.text = text
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
			bg_color = COLOR_PANEL_LIGHT if self.hover else COLOR_PANEL
			text_color = COLOR_TEXT

		pygame.draw.rect(surface, bg_color, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 2)

		text_surf = font.render(self.text, True, text_color)
		text_rect = text_surf.get_rect(center=self.rect.center)
		surface.blit(text_surf, text_rect)


class SpriteCompositionEditor:
	"""Main sprite composition editor"""
	def __init__(self, width: int = 1600, height: int = 900):
		pygame.init()
		self.width = width
		self.height = height
		self.screen = pygame.display.set_mode((width, height))
		pygame.display.set_caption("FFMQ Sprite Composition Editor")

		self.clock = pygame.time.Clock()
		self.font = pygame.font.Font(None, 20)
		self.title_font = pygame.font.Font(None, 32)
		self.small_font = pygame.font.Font(None, 16)

		# Database
		self.database = GraphicsDatabase()
		self.rom_path = ""

		# Current state
		self.current_tileset: Optional[Tileset] = None
		self.current_palette: Optional[Palette] = None
		self.selected_tile_id: Optional[int] = None
		self.sprites: List[Sprite] = []
		self.current_sprite_size = SpriteSize.SIZE_16x16

		# UI Components
		self.tile_grid_cells: List[TileGridCell] = []
		self.tile_grid_scroll = 0
		self.tile_grid_rect = pygame.Rect(20, 80, 600, 750)
		self.tile_cell_size = 48

		self.sprite_canvas = SpriteCanvas(700, 150, self.current_sprite_size)

		# Size selection buttons
		self.size_buttons: Dict[SpriteSize, Button] = {}
		sizes = [SpriteSize.SIZE_8x8, SpriteSize.SIZE_16x16, SpriteSize.SIZE_24x24, 
				SpriteSize.SIZE_32x32, SpriteSize.SIZE_16x32, SpriteSize.SIZE_32x64]
		for i, size in enumerate(sizes):
			btn = Button(700 + (i % 3) * 140, 80 + (i // 3) * 35, 130, 30, size.name.replace('SIZE_', ''))
			self.size_buttons[size] = btn

		# Action buttons
		self.clear_button = Button(1100, 80, 120, 35, "Clear")
		self.save_button = Button(1230, 80, 120, 35, "Save Sprite")
		self.new_button = Button(1360, 80, 120, 35, "New Sprite")

		# Initialize
		self._create_tile_grid()

		# Running state
		self.running = True
		self.modified = False

	def _create_tile_grid(self):
		"""Create tile selection grid"""
		self.tile_grid_cells.clear()
		tiles_per_row = 12
		y_offset = 0

		for i in range(256):  # Character tileset
			row = i // tiles_per_row
			col = i % tiles_per_row
			x = self.tile_grid_rect.x + 5 + col * (self.tile_cell_size + 2)
			y = self.tile_grid_rect.y + 5 + row * (self.tile_cell_size + 2) + y_offset
			cell = TileGridCell(x, y, self.tile_cell_size, i)
			self.tile_grid_cells.append(cell)

	def load_rom(self, rom_path: str):
		"""Load ROM file"""
		self.rom_path = rom_path
		try:
			self.database.load_from_rom(rom_path)
			if self.database.tilesets:
				self.current_tileset = self.database.tilesets.get(0)  # Character tileset
			if self.database.palettes:
				self.current_palette = self.database.palettes.get(0)
			print(f"Loaded tileset with {len(self.current_tileset.tiles)} tiles")
		except Exception as e:
			print(f"Error loading ROM: {e}")

	def handle_events(self):
		"""Handle pygame events"""
		mouse_pos = pygame.mouse.get_pos()
		mouse_clicked = False
		mouse_down = pygame.mouse.get_pressed()[0]
		mouse_right = pygame.mouse.get_pressed()[2]
		scroll = 0

		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				self.running = False

			elif event.type == pygame.KEYDOWN:
				if event.key == pygame.K_ESCAPE:
					self.running = False
				elif event.key == pygame.K_s and (event.mod & pygame.KMOD_CTRL):
					self.save_sprite()
				elif event.key == pygame.K_c:
					self.clear_canvas()

			elif event.type == pygame.MOUSEBUTTONDOWN:
				if event.button == 1:
					mouse_clicked = True

			elif event.type == pygame.MOUSEWHEEL:
				if self.tile_grid_rect.collidepoint(mouse_pos):
					scroll = event.y

		# Handle scroll
		if scroll != 0:
			self.tile_grid_scroll = max(0, self.tile_grid_scroll - scroll * 50)
			self._update_tile_grid_positions()

		# Update tile grid
		for cell in self.tile_grid_cells:
			if self.tile_grid_rect.collidepoint(cell.rect.center):
				if cell.update(mouse_pos, mouse_clicked):
					self.selected_tile_id = cell.tile_id
					# Update selection
					for c in self.tile_grid_cells:
						c.selected = (c.tile_id == self.selected_tile_id)

		# Update size buttons
		for size, button in self.size_buttons.items():
			button.enabled = True
			if button.update(mouse_pos, mouse_clicked):
				self.current_sprite_size = size
				self.sprite_canvas.set_sprite_size(size)
				self.modified = True

		# Update canvas (left or right click)
		if mouse_down or mouse_right:
			current_tile = self.selected_tile_id if mouse_down else None
			if self.sprite_canvas.update(mouse_pos, mouse_down or mouse_right, current_tile):
				self.modified = True

		# Update action buttons
		if self.clear_button.update(mouse_pos, mouse_clicked):
			self.clear_canvas()

		if self.save_button.update(mouse_pos, mouse_clicked):
			self.save_sprite()

		if self.new_button.update(mouse_pos, mouse_clicked):
			self.new_sprite()

	def _update_tile_grid_positions(self):
		"""Update tile grid cell positions based on scroll"""
		tiles_per_row = 12
		for i, cell in enumerate(self.tile_grid_cells):
			row = i // tiles_per_row
			col = i % tiles_per_row
			x = self.tile_grid_rect.x + 5 + col * (self.tile_cell_size + 2)
			y = self.tile_grid_rect.y + 5 + row * (self.tile_cell_size + 2) - self.tile_grid_scroll
			cell.rect.topleft = (x, y)

	def clear_canvas(self):
		"""Clear sprite canvas"""
		self.sprite_canvas.tile_positions.clear()
		self.modified = False

	def save_sprite(self):
		"""Save current sprite"""
		sprite = self.sprite_canvas.to_sprite(
			sprite_id=len(self.sprites),
			palette_id=0,
			name=f"Sprite {len(self.sprites)}"
		)
		self.sprites.append(sprite)
		print(f"Saved sprite: {sprite.name} ({sprite.size.name}, {len(sprite.tiles)} tiles)")
		self.modified = False

	def new_sprite(self):
		"""Start new sprite"""
		if self.modified:
			print("Warning: Unsaved changes will be lost")
		self.clear_canvas()

	def draw(self):
		"""Draw editor"""
		self.screen.fill(COLOR_BG)

		# Title
		title_text = "FFMQ Sprite Composition Editor"
		if self.modified:
			title_text += " *"
		title = self.title_font.render(title_text, True, COLOR_TEXT)
		self.screen.blit(title, (20, 20))

		# Tile grid panel
		pygame.draw.rect(self.screen, COLOR_PANEL, self.tile_grid_rect)
		pygame.draw.rect(self.screen, COLOR_BORDER, self.tile_grid_rect, 2)

		# Tile grid title
		grid_title = self.font.render("Tile Selector", True, COLOR_TEXT)
		self.screen.blit(grid_title, (self.tile_grid_rect.x + 5, self.tile_grid_rect.y - 25))

		# Clip and draw tiles
		clip_rect = self.screen.get_clip()
		self.screen.set_clip(self.tile_grid_rect)

		for cell in self.tile_grid_cells:
			if self.tile_grid_rect.top <= cell.rect.bottom and cell.rect.top <= self.tile_grid_rect.bottom:
				tile_surf = None
				if self.current_tileset and 0 <= cell.tile_id < len(self.current_tileset.tiles):
					tile = self.current_tileset.tiles[cell.tile_id]
					tile_surf = self._render_tile(tile)
				cell.draw(self.screen, tile_surf)

		self.screen.set_clip(clip_rect)

		# Canvas section
		canvas_title = self.font.render(f"Sprite Canvas - {self.current_sprite_size.name.replace('SIZE_', '')}", 
										True, COLOR_TEXT)
		self.screen.blit(canvas_title, (700, 120))

		self.sprite_canvas.draw(self.screen, self.font, self.current_tileset, self.current_palette)

		# Size buttons
		size_label = self.font.render("Sprite Size:", True, COLOR_TEXT)
		self.screen.blit(size_label, (700, 55))

		for size, button in self.size_buttons.items():
			# Highlight current size
			if size == self.current_sprite_size:
				highlight_rect = pygame.Rect(button.rect.x - 2, button.rect.y - 2, 
											button.rect.width + 4, button.rect.height + 4)
				pygame.draw.rect(self.screen, COLOR_SELECTED, highlight_rect, 3)
			button.draw(self.screen, self.font)

		# Action buttons
		self.clear_button.draw(self.screen, self.font)
		self.save_button.draw(self.screen, self.font)
		self.new_button.draw(self.screen, self.font)

		# Info panel
		info_x = 1100
		info_y = 150
		info_title = self.font.render("Sprite Info", True, COLOR_TEXT)
		self.screen.blit(info_title, (info_x, info_y))

		info_texts = [
			f"Tiles placed: {len(self.sprite_canvas.tile_positions)}",
			f"Sprite size: {self.current_sprite_size.name.replace('SIZE_', '')}",
			f"Sprites created: {len(self.sprites)}",
			f"Selected tile: {self.selected_tile_id if self.selected_tile_id is not None else 'None'}",
		]

		for i, text in enumerate(info_texts):
			text_surf = self.small_font.render(text, True, COLOR_TEXT)
			self.screen.blit(text_surf, (info_x, info_y + 30 + i * 20))

		# Saved sprites list
		sprites_y = info_y + 150
		sprites_title = self.font.render("Saved Sprites:", True, COLOR_TEXT)
		self.screen.blit(sprites_title, (info_x, sprites_y))

		for i, sprite in enumerate(self.sprites[-10:]):  # Show last 10
			sprite_text = f"{sprite.sprite_id}: {sprite.name} ({sprite.size.name.replace('SIZE_', '')})"
			text_surf = self.small_font.render(sprite_text, True, COLOR_TEXT)
			self.screen.blit(text_surf, (info_x, sprites_y + 30 + i * 20))

		# Instructions
		instructions = [
			"Instructions:",
			"• Click tiles to select",
			"• Left click canvas to place tile",
			"• Right click canvas to remove tile",
			"• Mouse wheel to scroll tiles",
			"• Select sprite size before building",
			"• Ctrl+S: Save sprite",
			"• C: Clear canvas",
			"• ESC: Quit",
		]

		inst_x = 1100
		inst_y = 600
		for i, text in enumerate(instructions):
			color = COLOR_TEXT if i == 0 else (180, 185, 190)
			inst_surf = self.small_font.render(text, True, color)
			self.screen.blit(inst_surf, (inst_x, inst_y + i * 20))

		pygame.display.flip()

	def _render_tile(self, tile: Tile) -> Optional[pygame.Surface]:
		"""Render tile to surface"""
		if not self.current_palette:
			return None

		surf = pygame.Surface((8, 8))
		for y in range(8):
			for x in range(8):
				color_idx = tile.get_pixel(x, y)
				if 0 <= color_idx < len(self.current_palette.colors):
					color = self.current_palette.colors[color_idx]
					r, g, b = color.to_rgb888()
					surf.set_at((x, y), (r, g, b))
		return surf

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

	editor = SpriteCompositionEditor()

	if len(sys.argv) > 1:
		editor.load_rom(sys.argv[1])
	else:
		print("Usage: python sprite_editor.py <rom_path>")
		print("Starting editor without ROM...")

	editor.run()


if __name__ == "__main__":
	main()
