"""
Interactive SFX Editor for FFMQ
Draggable sliders for pitch, pan, volume with real-time preview and SFX management
"""

import pygame
from typing import Optional, Tuple, List
from utils.music_data import SoundEffect, SoundEffectType, DEFAULT_SFX_NAMES
from utils.music_database import MusicDatabase


# Color constants
COLOR_BG = (35, 35, 45)
COLOR_PANEL = (50, 50, 65)
COLOR_PANEL_DARK = (40, 40, 55)
COLOR_BORDER = (90, 90, 110)
COLOR_TEXT = (220, 220, 230)
COLOR_SELECTED = (80, 120, 200)
COLOR_SLIDER_TRACK = (60, 60, 75)
COLOR_SLIDER_FILL = (100, 150, 230)
COLOR_SLIDER_HANDLE = (150, 180, 250)
COLOR_BUTTON = (70, 70, 90)
COLOR_BUTTON_HOVER = (90, 90, 120)


class DraggableSlider:
	"""Interactive slider with drag support and visual feedback"""
	def __init__(self, x: int, y: int, width: int, height: int, min_val: int, max_val: int,
				value: int, label: str, show_center: bool = False):
		self.rect = pygame.Rect(x, y, width, height)
		self.min_val = min_val
		self.max_val = max_val
		self.value = value
		self.label = label
		self.show_center = show_center  # Show center line (for pan)
		self.dragging = False
		self.hover = False

	def update(self, mouse_pos: Tuple[int, int], mouse_down: bool) -> Optional[int]:
		"""Update slider, return new value if changed"""
		self.hover = self.rect.collidepoint(mouse_pos)

		# Start dragging
		if mouse_down and self.hover and not self.dragging:
			self.dragging = True

		# Stop dragging
		if not mouse_down and self.dragging:
			self.dragging = False

		# Update value while dragging
		if self.dragging:
			rel_x = mouse_pos[0] - self.rect.x
			rel_x = max(0, min(rel_x, self.rect.width))
			ratio = rel_x / self.rect.width
			new_value = int(self.min_val + ratio * (self.max_val - self.min_val))

			if new_value != self.value:
				self.value = new_value
				return new_value

		return None

	def set_value(self, value: int):
		"""Set slider value"""
		self.value = max(self.min_val, min(self.max_val, value))

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw the slider"""
		# Background track
		track_color = COLOR_PANEL if not self.hover else COLOR_PANEL_DARK
		pygame.draw.rect(surface, track_color, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 1)

		# Calculate fill position
		ratio = (self.value - self.min_val) / (self.max_val - self.min_val)
		fill_width = int(self.rect.width * ratio)

		# Draw filled portion
		fill_rect = pygame.Rect(self.rect.x, self.rect.y, fill_width, self.rect.height)
		pygame.draw.rect(surface, COLOR_SLIDER_FILL, fill_rect)

		# Draw center line if needed (for pan slider)
		if self.show_center:
			center_x = self.rect.x + self.rect.width // 2
			pygame.draw.line(surface, COLOR_TEXT, 
							(center_x, self.rect.y), 
							(center_x, self.rect.bottom), 2)

		# Draw handle
		handle_x = self.rect.x + fill_width
		handle_rect = pygame.Rect(handle_x - 4, self.rect.y - 3, 8, self.rect.height + 6)
		pygame.draw.rect(surface, COLOR_SLIDER_HANDLE, handle_rect)
		pygame.draw.rect(surface, COLOR_BORDER, handle_rect, 2)

		# Draw label and value
		if self.show_center:
			# For pan, show L/C/R
			if self.value < 48:
				pan_text = f"L{64 - self.value}"
			elif self.value > 80:
				pan_text = f"R{self.value - 64}"
			else:
				pan_text = "Center"
			label_text = f"{self.label}: {self.value} ({pan_text})"
		else:
			label_text = f"{self.label}: {self.value}"

		text_surf = font.render(label_text, True, COLOR_TEXT)
		surface.blit(text_surf, (self.rect.x, self.rect.y - 25))


class SFXListItem:
	"""Single SFX list item"""
	def __init__(self, x: int, y: int, width: int, height: int, sfx: SoundEffect):
		self.rect = pygame.Rect(x, y, width, height)
		self.sfx = sfx
		self.selected = False
		self.hover = False

	def update(self, mouse_pos: Tuple[int, int], mouse_clicked: bool) -> bool:
		"""Update item, return True if clicked"""
		self.hover = self.rect.collidepoint(mouse_pos)
		if self.hover and mouse_clicked:
			return True
		return False

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw list item"""
		# Background
		if self.selected:
			bg_color = COLOR_SELECTED
		elif self.hover:
			bg_color = COLOR_BUTTON_HOVER
		else:
			bg_color = COLOR_BUTTON

		pygame.draw.rect(surface, bg_color, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 1)

		# SFX name
		name_text = f"{self.sfx.sfx_id:02X}: {self.sfx.name}"
		text_surf = font.render(name_text, True, COLOR_TEXT)
		surface.blit(text_surf, (self.rect.x + 5, self.rect.y + 5))


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
		bg_color = COLOR_BUTTON_HOVER if self.hover else COLOR_BUTTON
		pygame.draw.rect(surface, bg_color, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 2)

		text_surf = font.render(self.text, True, COLOR_TEXT)
		text_rect = text_surf.get_rect(center=self.rect.center)
		surface.blit(text_surf, text_rect)


class InteractiveSFXEditor:
	"""Full-featured interactive SFX editor"""
	def __init__(self, width: int = 1400, height: int = 900):
		pygame.init()
		self.width = width
		self.height = height
		self.screen = pygame.display.set_mode((width, height))
		pygame.display.set_caption("FFMQ Interactive SFX Editor")

		self.clock = pygame.time.Clock()
		self.font = pygame.font.Font(None, 20)
		self.title_font = pygame.font.Font(None, 32)
		self.small_font = pygame.font.Font(None, 16)

		# Database
		self.database = MusicDatabase()
		self.rom_path = ""

		# Current state
		self.current_sfx: Optional[SoundEffect] = None
		self.selected_sfx_id = 0
		self.modified = False

		# UI Components
		self.sfx_list_items: List[SFXListItem] = []
		self.scroll_offset = 0
		self.list_rect = pygame.Rect(20, 80, 400, 750)

		# Sliders
		self.volume_slider = DraggableSlider(500, 200, 600, 35, 0, 127, 127, "Volume")
		self.pitch_slider = DraggableSlider(500, 280, 600, 35, 0, 127, 64, "Pitch")
		self.pan_slider = DraggableSlider(500, 360, 600, 35, 0, 127, 64, "Pan", show_center=True)
		self.priority_slider = DraggableSlider(500, 440, 600, 35, 0, 127, 64, "Priority")

		# Buttons
		self.save_button = Button(500, 600, 120, 40, "Save")
		self.reset_button = Button(630, 600, 120, 40, "Reset")
		self.test_button = Button(760, 600, 120, 40, "Test SFX")

		# Running state
		self.running = True

	def load_rom(self, rom_path: str):
		"""Load ROM file"""
		self.rom_path = rom_path
		try:
			self.database.load_from_rom(rom_path)
			self._populate_sfx_list()
			if self.database.sound_effects:
				self.load_sfx(0)
			print(f"Loaded {len(self.database.sound_effects)} sound effects from ROM")
		except Exception as e:
			print(f"Error loading ROM: {e}")

	def _populate_sfx_list(self):
		"""Populate SFX list items"""
		self.sfx_list_items.clear()
		item_height = 30
		y = self.list_rect.y + 5

		for sfx_id in sorted(self.database.sound_effects.keys()):
			sfx = self.database.sound_effects[sfx_id]
			item = SFXListItem(self.list_rect.x + 5, y, self.list_rect.width - 10, item_height - 2, sfx)
			self.sfx_list_items.append(item)
			y += item_height

	def load_sfx(self, sfx_id: int):
		"""Load SFX for editing"""
		if sfx_id in self.database.sound_effects:
			self.current_sfx = self.database.sound_effects[sfx_id]
			self.selected_sfx_id = sfx_id
			self._update_ui_from_sfx()
			self.modified = False
			print(f"Loaded SFX {sfx_id:02X}: {self.current_sfx.name}")

	def _update_ui_from_sfx(self):
		"""Update UI components from current SFX"""
		if not self.current_sfx:
			return

		# Update sliders
		self.volume_slider.set_value(self.current_sfx.volume)
		self.pitch_slider.set_value(self.current_sfx.pitch)
		self.pan_slider.set_value(self.current_sfx.pan)
		self.priority_slider.set_value(self.current_sfx.priority)

		# Update list selection
		for item in self.sfx_list_items:
			item.selected = (item.sfx.sfx_id == self.selected_sfx_id)

	def _update_sfx_from_sliders(self):
		"""Update SFX from slider values"""
		if not self.current_sfx:
			return

		self.current_sfx.volume = self.volume_slider.value
		self.current_sfx.pitch = self.pitch_slider.value
		self.current_sfx.pan = self.pan_slider.value
		self.current_sfx.priority = self.priority_slider.value
		self.modified = True

	def handle_events(self):
		"""Handle pygame events"""
		mouse_pos = pygame.mouse.get_pos()
		mouse_clicked = False
		mouse_down = pygame.mouse.get_pressed()[0]
		scroll = 0

		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				self.running = False

			elif event.type == pygame.KEYDOWN:
				if event.key == pygame.K_ESCAPE:
					self.running = False
				elif event.key == pygame.K_s and (event.mod & pygame.KMOD_CTRL):
					self.save_sfx()
				elif event.key == pygame.K_UP:
					prev_id = max(0, self.selected_sfx_id - 1)
					if prev_id in self.database.sound_effects:
						self.load_sfx(prev_id)
				elif event.key == pygame.K_DOWN:
					next_id = min(63, self.selected_sfx_id + 1)
					if next_id in self.database.sound_effects:
						self.load_sfx(next_id)

			elif event.type == pygame.MOUSEBUTTONDOWN:
				if event.button == 1:
					mouse_clicked = True

			elif event.type == pygame.MOUSEWHEEL:
				if self.list_rect.collidepoint(mouse_pos):
					scroll = event.y

		# Handle scroll
		if scroll != 0:
			self.scroll_offset = max(0, self.scroll_offset - scroll * 30)

		# Update SFX list
		for item in self.sfx_list_items:
			# Adjust position based on scroll
			item.rect.y = self.list_rect.y + 5 + (item.sfx.sfx_id * 30) - self.scroll_offset

			# Check if visible
			if self.list_rect.collidepoint(item.rect.topleft):
				if item.update(mouse_pos, mouse_clicked):
					self.load_sfx(item.sfx.sfx_id)

		# Update sliders
		for slider in [self.volume_slider, self.pitch_slider, self.pan_slider, self.priority_slider]:
			if slider.update(mouse_pos, mouse_down) is not None:
				self._update_sfx_from_sliders()

		# Update buttons
		if self.save_button.update(mouse_pos, mouse_clicked):
			self.save_sfx()

		if self.reset_button.update(mouse_pos, mouse_clicked):
			self._update_ui_from_sfx()
			self.modified = False

		if self.test_button.update(mouse_pos, mouse_clicked):
			print(f"Testing SFX {self.selected_sfx_id:02X} (not implemented)")

	def save_sfx(self):
		"""Save current SFX to ROM"""
		if not self.rom_path or not self.current_sfx:
			print("No ROM loaded or no SFX selected")
			return

		try:
			self.database.save_to_rom(self.rom_path)
			self.modified = False
			print(f"Saved SFX {self.current_sfx.sfx_id:02X} to ROM")
		except Exception as e:
			print(f"Error saving: {e}")

	def draw(self):
		"""Draw the editor"""
		self.screen.fill(COLOR_BG)

		# Title
		title_text = f"FFMQ Interactive SFX Editor"
		if self.current_sfx:
			title_text += f" - SFX {self.current_sfx.sfx_id:02X}: {self.current_sfx.name}"
		if self.modified:
			title_text += " *"

		title = self.title_font.render(title_text, True, COLOR_TEXT)
		self.screen.blit(title, (20, 20))

		# Draw SFX list panel
		pygame.draw.rect(self.screen, COLOR_PANEL_DARK, self.list_rect)
		pygame.draw.rect(self.screen, COLOR_BORDER, self.list_rect, 2)

		# Draw list title
		list_title = self.font.render("Sound Effects", True, COLOR_TEXT)
		self.screen.blit(list_title, (self.list_rect.x + 5, self.list_rect.y - 25))

		# Create clipping region for list
		clip_rect = self.screen.get_clip()
		self.screen.set_clip(self.list_rect)

		# Draw list items
		for item in self.sfx_list_items:
			if self.list_rect.top <= item.rect.bottom and item.rect.top <= self.list_rect.bottom:
				item.draw(self.screen, self.font)

		self.screen.set_clip(clip_rect)

		# Draw sliders section
		slider_title = self.font.render("SFX Parameters (Drag sliders to adjust)", True, COLOR_TEXT)
		self.screen.blit(slider_title, (500, 150))

		self.volume_slider.draw(self.screen, self.font)
		self.pitch_slider.draw(self.screen, self.font)
		self.pan_slider.draw(self.screen, self.font)
		self.priority_slider.draw(self.screen, self.font)

		# Draw parameter info
		if self.current_sfx:
			info_x = 500
			info_y = 520
			info_texts = [
				f"Type: {self.current_sfx.sfx_type.name}",
				f"Data Offset: 0x{self.current_sfx.data_offset:06X}",
				f"Data Size: {self.current_sfx.data_size} bytes",
			]

			for i, text in enumerate(info_texts):
				text_surf = self.small_font.render(text, True, (180, 180, 190))
				self.screen.blit(text_surf, (info_x, info_y + i * 20))

		# Draw buttons
		self.save_button.draw(self.screen, self.font)
		self.reset_button.draw(self.screen, self.font)
		self.test_button.draw(self.screen, self.font)

		# Draw visual meters
		if self.current_sfx:
			self._draw_visual_meters(900, 650)

		# Draw instructions
		instructions = [
			"Controls:",
			"Up/Down Arrow: Navigate SFX",
			"Ctrl+S: Save to ROM",
			"Drag sliders to adjust parameters",
			"Volume: 0 (silent) - 127 (max)",
			"Pitch: 0 (low) - 64 (normal) - 127 (high)",
			"Pan: 0 (left) - 64 (center) - 127 (right)",
			"Priority: Higher = more important",
			"ESC: Quit",
		]

		inst_x = 450
		inst_y = 700
		for i, text in enumerate(instructions):
			color = COLOR_TEXT if i == 0 else (160, 160, 170)
			inst_surf = self.small_font.render(text, True, color)
			self.screen.blit(inst_surf, (inst_x, inst_y + i * 18))

		pygame.display.flip()

	def _draw_visual_meters(self, x: int, y: int):
		"""Draw visual representation of parameters"""
		# Volume meter
		vol_width = 200
		vol_height = 30
		vol_rect = pygame.Rect(x, y, vol_width, vol_height)
		pygame.draw.rect(self.screen, COLOR_SLIDER_TRACK, vol_rect)
		pygame.draw.rect(self.screen, COLOR_BORDER, vol_rect, 1)

		vol_fill = int((self.current_sfx.volume / 127) * vol_width)
		vol_fill_rect = pygame.Rect(x, y, vol_fill, vol_height)
		pygame.draw.rect(self.screen, COLOR_SLIDER_FILL, vol_fill_rect)

		vol_label = self.small_font.render("Volume Meter", True, COLOR_TEXT)
		self.screen.blit(vol_label, (x, y - 20))

		# Pitch indicator (centered)
		pitch_y = y + 60
		pitch_width = 200
		pitch_rect = pygame.Rect(x, pitch_y, pitch_width, 20)
		pygame.draw.rect(self.screen, COLOR_SLIDER_TRACK, pitch_rect)
		pygame.draw.rect(self.screen, COLOR_BORDER, pitch_rect, 1)

		# Center line
		center_x = x + pitch_width // 2
		pygame.draw.line(self.screen, COLOR_TEXT, (center_x, pitch_y), (center_x, pitch_y + 20), 2)

		# Pitch indicator
		pitch_pos = int((self.current_sfx.pitch / 127) * pitch_width)
		pygame.draw.circle(self.screen, COLOR_SLIDER_HANDLE, (x + pitch_pos, pitch_y + 10), 8)

		pitch_label = self.small_font.render("Pitch Indicator", True, COLOR_TEXT)
		self.screen.blit(pitch_label, (x, pitch_y - 20))

		# Pan visualization
		pan_y = y + 110
		pan_width = 200
		pan_rect = pygame.Rect(x, pan_y, pan_width, 20)
		pygame.draw.rect(self.screen, COLOR_SLIDER_TRACK, pan_rect)
		pygame.draw.rect(self.screen, COLOR_BORDER, pan_rect, 1)

		# L/R labels
		l_label = self.small_font.render("L", True, COLOR_TEXT)
		r_label = self.small_font.render("R", True, COLOR_TEXT)
		self.screen.blit(l_label, (x - 15, pan_y))
		self.screen.blit(r_label, (x + pan_width + 5, pan_y))

		# Pan position
		pan_pos = int((self.current_sfx.pan / 127) * pan_width)
		pygame.draw.circle(self.screen, COLOR_SLIDER_HANDLE, (x + pan_pos, pan_y + 10), 8)

		pan_label = self.small_font.render("Pan Position", True, COLOR_TEXT)
		self.screen.blit(pan_label, (x, pan_y - 20))

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

	editor = InteractiveSFXEditor()

	if len(sys.argv) > 1:
		editor.load_rom(sys.argv[1])
	else:
		print("Usage: python interactive_sfx_editor.py <rom_path>")
		print("Starting editor without ROM...")

	editor.run()


if __name__ == "__main__":
	main()
