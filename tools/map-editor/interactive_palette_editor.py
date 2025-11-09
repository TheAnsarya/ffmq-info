"""
Interactive Palette Editor for FFMQ
Draggable RGB sliders with live color preview and palette management
"""

import pygame
from typing import Optional, Tuple, List
from utils.graphics_data import Palette, Color, PaletteType
from utils.graphics_database import GraphicsDatabase


# Color constants
COLOR_BG = (40, 40, 40)
COLOR_PANEL = (60, 60, 60)
COLOR_PANEL_LIGHT = (80, 80, 80)
COLOR_BORDER = (100, 100, 100)
COLOR_TEXT = (220, 220, 220)
COLOR_SELECTED = (100, 150, 200)
COLOR_SWATCH_BORDER = (200, 200, 200)


class ColorSlider:
	"""Interactive color slider with drag support"""
	def __init__(self, x: int, y: int, width: int, height: int, channel: str, color_index: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.channel = channel  # 'R', 'G', or 'B'
		self.color_index = color_index
		self.value = 0
		self.dragging = False
		self.hover = False

	def update(self, mouse_pos: Tuple[int, int], mouse_down: bool) -> Optional[int]:
		"""Update slider state, return new value if changed"""
		self.hover = self.rect.collidepoint(mouse_pos)

		# Handle dragging
		if mouse_down and self.hover:
			self.dragging = True
		elif not mouse_down:
			self.dragging = False

		if self.dragging:
			# Calculate value from mouse X position
			rel_x = mouse_pos[0] - self.rect.x
			rel_x = max(0, min(rel_x, self.rect.width))
			new_value = int((rel_x / self.rect.width) * 255)

			if new_value != self.value:
				self.value = new_value
				return new_value

		return None

	def set_value(self, value: int):
		"""Set slider value"""
		self.value = max(0, min(255, value))

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw the slider"""
		# Background track
		track_color = COLOR_PANEL_LIGHT if self.hover else COLOR_PANEL
		pygame.draw.rect(surface, track_color, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 1)

		# Gradient fill based on channel
		for i in range(self.rect.width):
			ratio = i / self.rect.width
			value = int(ratio * 255)

			# Create color based on channel
			if self.channel == 'R':
				color = (value, 0, 0)
			elif self.channel == 'G':
				color = (0, value, 0)
			else:  # 'B'
				color = (0, 0, value)

			line_rect = pygame.Rect(self.rect.x + i, self.rect.y, 1, self.rect.height)
			pygame.draw.rect(surface, color, line_rect)

		# Current value indicator
		indicator_x = self.rect.x + int((self.value / 255) * self.rect.width)
		indicator_height = self.rect.height + 6
		indicator_rect = pygame.Rect(indicator_x - 3, self.rect.y - 3, 6, indicator_height)

		# Draw handle
		pygame.draw.rect(surface, COLOR_SWATCH_BORDER, indicator_rect)
		pygame.draw.rect(surface, COLOR_BORDER, indicator_rect, 2)

		# Label
		label_text = f"{self.channel}: {self.value:3d}"
		label_surf = font.render(label_text, True, COLOR_TEXT)
		surface.blit(label_surf, (self.rect.x - 50, self.rect.y + 2))


class PaletteSwatch:
	"""Interactive color swatch"""
	def __init__(self, x: int, y: int, size: int, color_index: int):
		self.rect = pygame.Rect(x, y, size, size)
		self.color_index = color_index
		self.color = Color(0, 0, 0)
		self.selected = False
		self.hover = False

	def update(self, mouse_pos: Tuple[int, int], mouse_clicked: bool) -> bool:
		"""Update swatch, return True if clicked"""
		self.hover = self.rect.collidepoint(mouse_pos)
		if self.hover and mouse_clicked:
			return True
		return False

	def set_color(self, color: Color):
		"""Set swatch color"""
		self.color = color

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw the swatch"""
		# Get RGB values
		r, g, b = self.color.to_rgb888()

		# Draw color
		pygame.draw.rect(surface, (r, g, b), self.rect)

		# Draw border
		border_color = COLOR_SELECTED if self.selected else (COLOR_SWATCH_BORDER if self.hover else COLOR_BORDER)
		border_width = 3 if self.selected else (2 if self.hover else 1)
		pygame.draw.rect(surface, border_color, self.rect, border_width)

		# Draw index
		if self.rect.width >= 32:
			idx_text = font.render(str(self.color_index), True, (255, 255, 255) if (r + g + b) < 384 else (0, 0, 0))
			idx_rect = idx_text.get_rect(center=self.rect.center)
			surface.blit(idx_text, idx_rect)


class InteractivePaletteEditor:
	"""Full-featured interactive palette editor"""
	def __init__(self, width: int = 1200, height: int = 800):
		pygame.init()
		self.width = width
		self.height = height
		self.screen = pygame.display.set_mode((width, height))
		pygame.display.set_caption("FFMQ Interactive Palette Editor")

		self.clock = pygame.time.Clock()
		self.font = pygame.font.Font(None, 20)
		self.title_font = pygame.font.Font(None, 32)

		# Database
		self.database = GraphicsDatabase()
		self.rom_path = ""

		# Current state
		self.current_palette: Optional[Palette] = None
		self.current_palette_id = 0
		self.selected_color_idx = 0
		self.modified = False

		# UI Components
		self.swatches: List[PaletteSwatch] = []
		self.sliders: List[ColorSlider] = []
		self._create_ui()

		# Running state
		self.running = True

	def _create_ui(self):
		"""Create UI components"""
		# Create color swatches (16 colors in 2 rows)
		swatch_size = 60
		swatch_start_x = 50
		swatch_start_y = 100

		for i in range(16):
			row = i // 8
			col = i % 8
			x = swatch_start_x + col * (swatch_size + 10)
			y = swatch_start_y + row * (swatch_size + 10)
			swatch = PaletteSwatch(x, y, swatch_size, i)
			self.swatches.append(swatch)

		# Create RGB sliders
		slider_x = 650
		slider_y = 150
		slider_width = 400
		slider_height = 30

		self.sliders = [
			ColorSlider(slider_x, slider_y, slider_width, slider_height, 'R', 0),
			ColorSlider(slider_x, slider_y + 50, slider_width, slider_height, 'G', 1),
			ColorSlider(slider_x, slider_y + 100, slider_width, slider_height, 'B', 2),
		]

	def load_rom(self, rom_path: str):
		"""Load ROM file"""
		self.rom_path = rom_path
		try:
			self.database.load_from_rom(rom_path)
			if self.database.palettes:
				self.load_palette(0)
			print(f"Loaded {len(self.database.palettes)} palettes from ROM")
		except Exception as e:
			print(f"Error loading ROM: {e}")

	def load_palette(self, palette_id: int):
		"""Load a palette for editing"""
		if palette_id in self.database.palettes:
			self.current_palette = self.database.palettes[palette_id]
			self.current_palette_id = palette_id
			self.selected_color_idx = 0
			self._update_ui_from_palette()
			self.modified = False
			print(f"Loaded palette {palette_id}: {self.current_palette.name}")

	def _update_ui_from_palette(self):
		"""Update UI components from current palette"""
		if not self.current_palette:
			return

		# Update swatches
		for i, swatch in enumerate(self.swatches):
			if i < len(self.current_palette.colors):
				swatch.set_color(self.current_palette.colors[i])
			swatch.selected = (i == self.selected_color_idx)

		# Update sliders with selected color
		if 0 <= self.selected_color_idx < len(self.current_palette.colors):
			color = self.current_palette.colors[self.selected_color_idx]
			r, g, b = color.to_rgb888()
			self.sliders[0].set_value(r)
			self.sliders[1].set_value(g)
			self.sliders[2].set_value(b)

	def _update_palette_from_sliders(self):
		"""Update palette color from slider values"""
		if not self.current_palette:
			return

		r = self.sliders[0].value
		g = self.sliders[1].value
		b = self.sliders[2].value

		# Create new color and update palette
		new_color = Color.from_rgb888(r, g, b)
		if 0 <= self.selected_color_idx < len(self.current_palette.colors):
			self.current_palette.colors[self.selected_color_idx] = new_color
			self.swatches[self.selected_color_idx].set_color(new_color)
			self.modified = True

	def handle_events(self):
		"""Handle pygame events"""
		mouse_pos = pygame.mouse.get_pos()
		mouse_clicked = False
		mouse_down = pygame.mouse.get_pressed()[0]

		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				self.running = False

			elif event.type == pygame.KEYDOWN:
				if event.key == pygame.K_ESCAPE:
					self.running = False
				elif event.key == pygame.K_s and (event.mod & pygame.KMOD_CTRL):
					self.save_palette()
				elif event.key == pygame.K_LEFT:
					self.load_palette((self.current_palette_id - 1) % len(self.database.palettes))
				elif event.key == pygame.K_RIGHT:
					self.load_palette((self.current_palette_id + 1) % len(self.database.palettes))
				elif event.key == pygame.K_1:
					self.copy_color()
				elif event.key == pygame.K_2:
					self.paste_color()

			elif event.type == pygame.MOUSEBUTTONDOWN:
				if event.button == 1:
					mouse_clicked = True

		# Update swatches
		for i, swatch in enumerate(self.swatches):
			if swatch.update(mouse_pos, mouse_clicked):
				self.selected_color_idx = i
				self._update_ui_from_palette()

		# Update sliders
		for slider in self.sliders:
			new_value = slider.update(mouse_pos, mouse_down)
			if new_value is not None:
				self._update_palette_from_sliders()

	def save_palette(self):
		"""Save current palette to ROM"""
		if not self.rom_path or not self.current_palette:
			print("No ROM loaded or no palette selected")
			return

		try:
			self.database.save_to_rom(self.rom_path)
			self.modified = False
			print(f"Saved palette {self.current_palette_id} to ROM")
		except Exception as e:
			print(f"Error saving: {e}")

	def copy_color(self):
		"""Copy selected color"""
		if self.current_palette and 0 <= self.selected_color_idx < len(self.current_palette.colors):
			self.clipboard_color = self.current_palette.colors[self.selected_color_idx]
			print(f"Copied color {self.selected_color_idx}")

	def paste_color(self):
		"""Paste copied color"""
		if hasattr(self, 'clipboard_color') and self.current_palette:
			if 0 <= self.selected_color_idx < len(self.current_palette.colors):
				self.current_palette.colors[self.selected_color_idx] = self.clipboard_color
				self._update_ui_from_palette()
				self.modified = True
				print(f"Pasted color to {self.selected_color_idx}")

	def draw(self):
		"""Draw the editor"""
		self.screen.fill(COLOR_BG)

		# Title
		title_text = f"FFMQ Interactive Palette Editor"
		if self.current_palette:
			title_text += f" - Palette {self.current_palette_id}: {self.current_palette.name}"
		if self.modified:
			title_text += " *"

		title = self.title_font.render(title_text, True, COLOR_TEXT)
		self.screen.blit(title, (20, 20))

		# Draw swatches
		for swatch in self.swatches:
			swatch.draw(self.screen, self.font)

		# Draw sliders section
		slider_title = self.font.render("RGB Color Sliders (Drag to adjust)", True, COLOR_TEXT)
		self.screen.blit(slider_title, (600, 110))

		for slider in self.sliders:
			slider.draw(self.screen, self.font)

		# Draw color preview
		if self.current_palette and 0 <= self.selected_color_idx < len(self.current_palette.colors):
			preview_x = 650
			preview_y = 320
			preview_size = 150

			# Large preview swatch
			color = self.current_palette.colors[self.selected_color_idx]
			r, g, b = color.to_rgb888()

			preview_rect = pygame.Rect(preview_x, preview_y, preview_size, preview_size)
			pygame.draw.rect(self.screen, (r, g, b), preview_rect)
			pygame.draw.rect(self.screen, COLOR_SWATCH_BORDER, preview_rect, 3)

			# Color info
			info_y = preview_y + preview_size + 20
			info_texts = [
				f"Color Index: {self.selected_color_idx}",
				f"RGB888: ({r}, {g}, {b})",
				f"BGR555: ({color.red}, {color.green}, {color.blue})",
				f"Hex: #{r:02X}{g:02X}{b:02X}",
			]

			for i, text in enumerate(info_texts):
				text_surf = self.font.render(text, True, COLOR_TEXT)
				self.screen.blit(text_surf, (preview_x, info_y + i * 25))

		# Draw palette list
		list_x = 50
		list_y = 280
		list_title = self.font.render("Palettes:", True, COLOR_TEXT)
		self.screen.blit(list_title, (list_x, list_y))

		for i in range(min(8, len(self.database.palettes))):
			pal_id = i
			if pal_id in self.database.palettes:
				pal = self.database.palettes[pal_id]
				pal_name = f"{pal_id}: {pal.name}"
				color = COLOR_SELECTED if pal_id == self.current_palette_id else COLOR_TEXT
				pal_text = self.font.render(pal_name, True, color)
				self.screen.blit(pal_text, (list_x, list_y + 30 + i * 25))

		# Draw instructions
		instructions = [
			"Controls:",
			"Left/Right Arrow: Previous/Next palette",
			"Ctrl+S: Save to ROM",
			"1: Copy color",
			"2: Paste color",
			"Click swatches to select color",
			"Drag sliders to adjust RGB values",
			"ESC: Quit",
		]

		inst_x = 50
		inst_y = 550
		for i, text in enumerate(instructions):
			color = COLOR_TEXT if i == 0 else (180, 180, 180)
			inst_surf = self.font.render(text, True, color)
			self.screen.blit(inst_surf, (inst_x, inst_y + i * 22))

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

	editor = InteractivePaletteEditor()

	if len(sys.argv) > 1:
		editor.load_rom(sys.argv[1])
	else:
		print("Usage: python interactive_palette_editor.py <rom_path>")
		print("Starting editor without ROM...")

	editor.run()


if __name__ == "__main__":
	main()
