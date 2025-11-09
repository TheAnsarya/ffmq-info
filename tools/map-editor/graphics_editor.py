"""
FFMQ Graphics Editor

Visual editor for sprites, palettes, and tilesets.
"""

import pygame
from typing import Optional, List, Tuple
from utils.graphics_data import (
	Tile, Palette, Color, Tileset, SpriteSize,
	PaletteType, create_blank_tile, create_solid_tile
)
from utils.graphics_database import GraphicsDatabase


# Colors
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
GRAY = (128, 128, 128)
LIGHT_GRAY = (192, 192, 192)
DARK_GRAY = (64, 64, 64)
BLUE = (0, 120, 215)
RED = (255, 0, 0)
GREEN = (0, 255, 0)


class PaletteEditorPanel:
	"""Editor panel for palettes"""

	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.palette: Optional[Palette] = None
		self.selected_color_idx: int = 0
		self.color_size = 32  # Size of each color swatch

	def set_palette(self, palette: Palette):
		"""Set active palette"""
		self.palette = palette
		self.selected_color_idx = 0

	def handle_event(self, event: pygame.event.Event) -> bool:
		"""Handle input events"""
		if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
			mouse_x, mouse_y = event.pos
			if self.rect.collidepoint(mouse_x, mouse_y):
				# Check if clicked on color swatch
				rel_x = mouse_x - self.rect.x - 10
				rel_y = mouse_y - self.rect.y - 40

				if 0 <= rel_y < self.color_size * 2:  # 2 rows
					col = rel_x // self.color_size
					row = rel_y // self.color_size
					idx = row * 8 + col

					if 0 <= idx < 16 and 0 <= col < 8:
						self.selected_color_idx = idx
						return True

		return False

	def render(self, screen: pygame.Surface, font: pygame.font.Font):
		"""Render palette editor"""
		# Background
		pygame.draw.rect(screen, LIGHT_GRAY, self.rect)
		pygame.draw.rect(screen, BLACK, self.rect, 2)

		if self.palette is None:
			text = font.render("No palette loaded", True, BLACK)
			screen.blit(text, (self.rect.x + 10, self.rect.y + 10))
			return

		# Title
		title = font.render(f"Palette: {self.palette.name}", True, BLACK)
		screen.blit(title, (self.rect.x + 10, self.rect.y + 10))

		# Draw color swatches (2 rows of 8)
		for i in range(16):
			row = i // 8
			col = i % 8

			x = self.rect.x + 10 + col * self.color_size
			y = self.rect.y + 40 + row * self.color_size

			color = self.palette.get_color(i)
			r, g, b = color.to_rgb888()

			# Draw swatch
			swatch_rect = pygame.Rect(x, y, self.color_size - 2, self.color_size - 2)
			pygame.draw.rect(screen, (r, g, b), swatch_rect)

			# Draw border (highlight if selected)
			border_color = RED if i == self.selected_color_idx else BLACK
			border_width = 3 if i == self.selected_color_idx else 1
			pygame.draw.rect(screen, border_color, swatch_rect, border_width)

		# Draw selected color info
		selected_color = self.palette.get_color(self.selected_color_idx)
		r, g, b = selected_color.to_rgb888()

		info_y = self.rect.y + 40 + 2 * self.color_size + 10
		info_text = f"Color {self.selected_color_idx}: RGB({r}, {g}, {b}) BGR555({selected_color.red}, {selected_color.green}, {selected_color.blue})"
		text = font.render(info_text, True, BLACK)
		screen.blit(text, (self.rect.x + 10, info_y))

		# Color adjustment sliders
		slider_y = info_y + 30
		self._render_color_slider(screen, font, "R", r, self.rect.x + 10, slider_y)
		self._render_color_slider(screen, font, "G", g, self.rect.x + 10, slider_y + 25)
		self._render_color_slider(screen, font, "B", b, self.rect.x + 10, slider_y + 50)

	def _render_color_slider(self, screen: pygame.Surface, font: pygame.font.Font, label: str, value: int, x: int, y: int):
		"""Render a color adjustment slider"""
		label_text = font.render(f"{label}:", True, BLACK)
		screen.blit(label_text, (x, y))

		# Draw slider bar
		slider_rect = pygame.Rect(x + 30, y, 200, 20)
		pygame.draw.rect(screen, WHITE, slider_rect)
		pygame.draw.rect(screen, BLACK, slider_rect, 1)

		# Draw value indicator
		indicator_x = x + 30 + int((value / 255) * 200)
		pygame.draw.line(screen, RED, (indicator_x, y), (indicator_x, y + 20), 2)

		# Draw value text
		value_text = font.render(str(value), True, BLACK)
		screen.blit(value_text, (x + 240, y))


class TileEditorPanel:
	"""Editor panel for tiles"""

	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.tile: Optional[Tile] = None
		self.palette: Optional[Palette] = None
		self.selected_color_idx: int = 0
		self.pixel_size = 32  # Size of each pixel in editor
		self.grid_offset_x = 10
		self.grid_offset_y = 40
		self.drawing = False

	def set_tile(self, tile: Tile):
		"""Set active tile"""
		self.tile = tile

	def set_palette(self, palette: Palette):
		"""Set palette for rendering"""
		self.palette = palette

	def set_selected_color(self, color_idx: int):
		"""Set selected color for drawing"""
		self.selected_color_idx = color_idx

	def handle_event(self, event: pygame.event.Event) -> bool:
		"""Handle input events"""
		if self.tile is None or self.palette is None:
			return False

		if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
			self.drawing = True
			return self._paint_pixel(event.pos)

		elif event.type == pygame.MOUSEMOTION and self.drawing:
			return self._paint_pixel(event.pos)

		elif event.type == pygame.MOUSEBUTTONUP and event.button == 1:
			self.drawing = False

		return False

	def _paint_pixel(self, mouse_pos: Tuple[int, int]) -> bool:
		"""Paint a pixel at mouse position"""
		mouse_x, mouse_y = mouse_pos

		# Check if in grid area
		grid_x = self.rect.x + self.grid_offset_x
		grid_y = self.rect.y + self.grid_offset_y
		grid_size = 8 * self.pixel_size

		if not (grid_x <= mouse_x < grid_x + grid_size and
				grid_y <= mouse_y < grid_y + grid_size):
			return False

		# Calculate pixel coordinates
		px = (mouse_x - grid_x) // self.pixel_size
		py = (mouse_y - grid_y) // self.pixel_size

		if 0 <= px < 8 and 0 <= py < 8:
			self.tile.set_pixel(px, py, self.selected_color_idx)
			return True

		return False

	def render(self, screen: pygame.Surface, font: pygame.font.Font):
		"""Render tile editor"""
		# Background
		pygame.draw.rect(screen, LIGHT_GRAY, self.rect)
		pygame.draw.rect(screen, BLACK, self.rect, 2)

		if self.tile is None or self.palette is None:
			text = font.render("No tile loaded", True, BLACK)
			screen.blit(text, (self.rect.x + 10, self.rect.y + 10))
			return

		# Title
		title = font.render(f"Tile Editor (ID: {self.tile.tile_id})", True, BLACK)
		screen.blit(title, (self.rect.x + 10, self.rect.y + 10))

		# Draw tile grid
		grid_x = self.rect.x + self.grid_offset_x
		grid_y = self.rect.y + self.grid_offset_y

		for y in range(8):
			for x in range(8):
				color_idx = self.tile.get_pixel(x, y)
				color = self.palette.get_color(color_idx)
				r, g, b = color.to_rgb888()

				px = grid_x + x * self.pixel_size
				py = grid_y + y * self.pixel_size

				pixel_rect = pygame.Rect(px, py, self.pixel_size, self.pixel_size)
				pygame.draw.rect(screen, (r, g, b), pixel_rect)
				pygame.draw.rect(screen, DARK_GRAY, pixel_rect, 1)

		# Draw tools info
		tools_y = grid_y + 8 * self.pixel_size + 20
		tool_text = f"Selected Color: {self.selected_color_idx}"
		text = font.render(tool_text, True, BLACK)
		screen.blit(text, (self.rect.x + 10, tools_y))

		# Draw preview (actual size)
		preview_x = self.rect.x + self.rect.width - 100
		preview_y = self.rect.y + 40

		preview_label = font.render("Preview:", True, BLACK)
		screen.blit(preview_label, (preview_x, preview_y - 20))

		for y in range(8):
			for x in range(8):
				color_idx = self.tile.get_pixel(x, y)
				color = self.palette.get_color(color_idx)
				r, g, b = color.to_rgb888()

				px = preview_x + x * 4
				py = preview_y + y * 4

				pixel_rect = pygame.Rect(px, py, 4, 4)
				pygame.draw.rect(screen, (r, g, b), pixel_rect)


class TilesetViewerPanel:
	"""Panel for viewing and selecting tiles from tileset"""

	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.tileset: Optional[Tileset] = None
		self.palette: Optional[Palette] = None
		self.selected_tile_idx: int = 0
		self.tile_size = 16  # Display size for each tile
		self.tiles_per_row = 16
		self.scroll_offset = 0

	def set_tileset(self, tileset: Tileset):
		"""Set active tileset"""
		self.tileset = tileset
		self.selected_tile_idx = 0
		self.scroll_offset = 0

	def set_palette(self, palette: Palette):
		"""Set palette for rendering"""
		self.palette = palette
		if self.tileset:
			self.tileset.palette = palette

	def handle_event(self, event: pygame.event.Event) -> Optional[Tile]:
		"""Handle input events, returns selected tile if clicked"""
		if self.tileset is None:
			return None

		if event.type == pygame.MOUSEBUTTONDOWN:
			if event.button == 1:  # Left click
				mouse_x, mouse_y = event.pos
				if self.rect.collidepoint(mouse_x, mouse_y):
					rel_x = mouse_x - self.rect.x - 10
					rel_y = mouse_y - self.rect.y - 40 + self.scroll_offset

					col = rel_x // self.tile_size
					row = rel_y // self.tile_size
					idx = row * self.tiles_per_row + col

					if 0 <= idx < len(self.tileset.tiles) and 0 <= col < self.tiles_per_row:
						self.selected_tile_idx = idx
						return self.tileset.tiles[idx]

			elif event.button == 4:  # Mouse wheel up
				self.scroll_offset = max(0, self.scroll_offset - 20)

			elif event.button == 5:  # Mouse wheel down
				max_scroll = max(0, (len(self.tileset.tiles) // self.tiles_per_row) * self.tile_size - self.rect.height + 60)
				self.scroll_offset = min(max_scroll, self.scroll_offset + 20)

		return None

	def render(self, screen: pygame.Surface, font: pygame.font.Font):
		"""Render tileset viewer"""
		# Background
		pygame.draw.rect(screen, WHITE, self.rect)
		pygame.draw.rect(screen, BLACK, self.rect, 2)

		if self.tileset is None or self.palette is None:
			text = font.render("No tileset loaded", True, BLACK)
			screen.blit(text, (self.rect.x + 10, self.rect.y + 10))
			return

		# Title
		title = font.render(f"Tileset: {self.tileset.name} ({len(self.tileset.tiles)} tiles)", True, BLACK)
		screen.blit(title, (self.rect.x + 10, self.rect.y + 10))

		# Create clipping region
		clip_rect = pygame.Rect(self.rect.x + 10, self.rect.y + 40,
								self.rect.width - 20, self.rect.height - 50)
		screen.set_clip(clip_rect)

		# Draw tiles
		for idx, tile in enumerate(self.tileset.tiles):
			row = idx // self.tiles_per_row
			col = idx % self.tiles_per_row

			x = self.rect.x + 10 + col * self.tile_size
			y = self.rect.y + 40 + row * self.tile_size - self.scroll_offset

			# Skip if not visible
			if y + self.tile_size < self.rect.y + 40 or y > self.rect.y + self.rect.height:
				continue

			# Draw tile
			for ty in range(8):
				for tx in range(8):
					color_idx = tile.get_pixel(tx, ty)
					color = self.palette.get_color(color_idx)
					r, g, b = color.to_rgb888()

					px = x + tx * 2
					py = y + ty * 2

					pixel_rect = pygame.Rect(px, py, 2, 2)
					pygame.draw.rect(screen, (r, g, b), pixel_rect)

			# Draw selection border
			if idx == self.selected_tile_idx:
				tile_rect = pygame.Rect(x, y, self.tile_size, self.tile_size)
				pygame.draw.rect(screen, RED, tile_rect, 2)

		# Clear clipping
		screen.set_clip(None)


class GraphicsEditor:
	"""Main graphics editor application"""

	def __init__(self, width: int = 1400, height: int = 800):
		pygame.init()
		self.screen = pygame.display.set_mode((width, height))
		pygame.display.set_caption("FFMQ Graphics Editor")

		self.font = pygame.font.Font(None, 24)
		self.small_font = pygame.font.Font(None, 18)

		self.database = GraphicsDatabase()
		self.running = True
		self.clock = pygame.time.Clock()

		# Create editor panels
		self.palette_panel = PaletteEditorPanel(10, 10, 600, 300)
		self.tile_panel = TileEditorPanel(620, 10, 400, 400)
		self.tileset_panel = TilesetViewerPanel(10, 320, 600, 470)

		# State
		self.current_tileset_id = 0
		self.current_palette_id = 0
		self.modified = False

	def load_rom(self, rom_path: str):
		"""Load ROM file"""
		try:
			self.database.load_from_rom(rom_path)

			# Set initial palette and tileset
			if 0 in self.database.palettes:
				palette = self.database.palettes[0]
				self.palette_panel.set_palette(palette)
				self.tile_panel.set_palette(palette)
				self.tileset_panel.set_palette(palette)

			if 0 in self.database.tilesets:
				tileset = self.database.tilesets[0]
				self.tileset_panel.set_tileset(tileset)
				if tileset.tiles:
					self.tile_panel.set_tile(tileset.tiles[0])

			print(f"Loaded ROM: {rom_path}")

		except Exception as e:
			print(f"Error loading ROM: {e}")

	def handle_events(self):
		"""Handle pygame events"""
		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				self.running = False

			elif event.type == pygame.KEYDOWN:
				if event.key == pygame.K_ESCAPE:
					self.running = False

				elif event.key == pygame.K_s and pygame.key.get_mods() & pygame.KMOD_CTRL:
					self.save_rom()

			# Panel events
			if self.palette_panel.handle_event(event):
				# Update tile panel with selected color
				self.tile_panel.set_selected_color(self.palette_panel.selected_color_idx)
				self.modified = True

			if self.tile_panel.handle_event(event):
				self.modified = True

			selected_tile = self.tileset_panel.handle_event(event)
			if selected_tile:
				self.tile_panel.set_tile(selected_tile)

	def save_rom(self):
		"""Save changes to ROM"""
		if self.database.rom_path and self.modified:
			try:
				self.database.save_to_rom()
				self.modified = False
				print("ROM saved successfully")
			except Exception as e:
				print(f"Error saving ROM: {e}")

	def render(self):
		"""Render the editor"""
		self.screen.fill(DARK_GRAY)

		# Render panels
		self.palette_panel.render(self.screen, self.font)
		self.tile_panel.render(self.screen, self.font)
		self.tileset_panel.render(self.screen, self.font)

		# Render status bar
		status_y = self.screen.get_height() - 30
		pygame.draw.rect(self.screen, LIGHT_GRAY, (0, status_y, self.screen.get_width(), 30))

		status_text = f"ROM: {self.database.rom_path or 'None'} | "
		status_text += f"Tileset: {self.current_tileset_id} | "
		status_text += f"Palette: {self.current_palette_id} | "
		status_text += f"{'MODIFIED' if self.modified else 'Saved'} | "
		status_text += f"Ctrl+S: Save | ESC: Quit"

		text = self.small_font.render(status_text, True, BLACK)
		self.screen.blit(text, (10, status_y + 5))

		pygame.display.flip()

	def run(self):
		"""Main editor loop"""
		while self.running:
			self.handle_events()
			self.render()
			self.clock.tick(60)

		pygame.quit()


def main():
	"""Main entry point"""
	import sys

	editor = GraphicsEditor()

	if len(sys.argv) > 1:
		editor.load_rom(sys.argv[1])

	editor.run()


if __name__ == "__main__":
	main()
