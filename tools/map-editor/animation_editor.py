"""
Tile Animation Editor for FFMQ
Allows creating and editing animated tile sequences with frame timing and preview
"""

import pygame
from typing import List, Optional, Tuple
from dataclasses import dataclass
from utils.graphics_data import Animation, AnimationFrame, AnimationType, Tile, Palette
from utils.graphics_database import GraphicsDatabase


# Color constants
COLOR_BG = (40, 40, 40)
COLOR_PANEL = (60, 60, 60)
COLOR_BORDER = (80, 80, 80)
COLOR_TEXT = (220, 220, 220)
COLOR_BUTTON = (70, 70, 70)
COLOR_BUTTON_HOVER = (90, 90, 90)
COLOR_SELECTED = (100, 150, 200)
COLOR_TIMELINE = (50, 50, 50)
COLOR_FRAME_MARKER = (150, 150, 150)
COLOR_PLAYHEAD = (255, 100, 100)


class Button:
	"""Simple button widget"""
	def __init__(self, x: int, y: int, width: int, height: int, text: str):
		self.rect = pygame.Rect(x, y, width, height)
		self.text = text
		self.hovered = False
		self.clicked = False

	def update(self, mouse_pos: Tuple[int, int], mouse_clicked: bool) -> bool:
		"""Update button state, return True if clicked"""
		self.hovered = self.rect.collidepoint(mouse_pos)
		if self.hovered and mouse_clicked:
			self.clicked = True
			return True
		return False

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw button"""
		color = COLOR_BUTTON_HOVER if self.hovered else COLOR_BUTTON
		pygame.draw.rect(surface, color, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 1)

		text_surf = font.render(self.text, True, COLOR_TEXT)
		text_rect = text_surf.get_rect(center=self.rect.center)
		surface.blit(text_surf, text_rect)


class Slider:
	"""Draggable slider widget"""
	def __init__(self, x: int, y: int, width: int, height: int, min_val: int, max_val: int, value: int, label: str):
		self.rect = pygame.Rect(x, y, width, height)
		self.min_val = min_val
		self.max_val = max_val
		self.value = value
		self.label = label
		self.dragging = False

	def update(self, mouse_pos: Tuple[int, int], mouse_down: bool) -> bool:
		"""Update slider, return True if value changed"""
		if mouse_down and self.rect.collidepoint(mouse_pos):
			self.dragging = True
		elif not mouse_down:
			self.dragging = False

		if self.dragging:
			# Calculate value from mouse position
			slider_x = mouse_pos[0] - self.rect.x
			slider_x = max(0, min(slider_x, self.rect.width))
			ratio = slider_x / self.rect.width
			new_value = int(self.min_val + ratio * (self.max_val - self.min_val))
			if new_value != self.value:
				self.value = new_value
				return True
		return False

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw slider"""
		# Background track
		pygame.draw.rect(surface, COLOR_TIMELINE, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 1)

		# Filled portion
		ratio = (self.value - self.min_val) / (self.max_val - self.min_val)
		fill_width = int(self.rect.width * ratio)
		fill_rect = pygame.Rect(self.rect.x, self.rect.y, fill_width, self.rect.height)
		pygame.draw.rect(surface, COLOR_SELECTED, fill_rect)

		# Handle
		handle_x = self.rect.x + fill_width
		handle_rect = pygame.Rect(handle_x - 3, self.rect.y - 2, 6, self.rect.height + 4)
		pygame.draw.rect(surface, COLOR_FRAME_MARKER, handle_rect)
		pygame.draw.rect(surface, COLOR_BORDER, handle_rect, 1)

		# Label and value
		label_text = f"{self.label}: {self.value}"
		text_surf = font.render(label_text, True, COLOR_TEXT)
		surface.blit(text_surf, (self.rect.x, self.rect.y - 20))


class TileSelectorPanel:
	"""Panel for selecting tiles from tileset"""
	def __init__(self, x: int, y: int, width: int, height: int, database: GraphicsDatabase):
		self.rect = pygame.Rect(x, y, width, height)
		self.database = database
		self.selected_tile_id = 0
		self.scroll_offset = 0
		self.tiles_per_row = 8
		self.tile_display_size = 32
		self.palette = None

	def set_palette(self, palette: Palette):
		"""Set palette for tile rendering"""
		self.palette = palette

	def update(self, mouse_pos: Tuple[int, int], mouse_clicked: bool, scroll: int) -> Optional[int]:
		"""Update panel, return selected tile ID if changed"""
		if not self.rect.collidepoint(mouse_pos):
			return None

		# Handle scroll
		self.scroll_offset = max(0, self.scroll_offset - scroll * 20)

		# Handle click
		if mouse_clicked:
			rel_x = mouse_pos[0] - self.rect.x
			rel_y = mouse_pos[1] - self.rect.y + self.scroll_offset

			tile_x = rel_x // (self.tile_display_size + 4)
			tile_y = rel_y // (self.tile_display_size + 4)

			tile_id = tile_y * self.tiles_per_row + tile_x

			# Check if valid tile
			if 0 <= tile_id < 256:  # Assuming character tileset
				self.selected_tile_id = tile_id
				return tile_id

		return None

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw tile selector"""
		pygame.draw.rect(surface, COLOR_PANEL, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 2)

		if not self.palette or not self.database.tilesets:
			return

		# Create clipping rect
		clip_rect = surface.get_clip()
		surface.set_clip(self.rect)

		# Get tileset
		tileset = self.database.tilesets.get(0)  # Character tileset
		if not tileset:
			surface.set_clip(clip_rect)
			return

		# Draw tiles in grid
		y_offset = self.rect.y - self.scroll_offset
		for i, tile in enumerate(tileset.tiles[:256]):
			row = i // self.tiles_per_row
			col = i % self.tiles_per_row

			x = self.rect.x + col * (self.tile_display_size + 4) + 2
			y = y_offset + row * (self.tile_display_size + 4) + 2

			# Skip if out of view
			if y + self.tile_display_size < self.rect.y or y > self.rect.bottom:
				continue

			# Draw tile scaled up
			tile_surf = self._render_tile(tile)
			if tile_surf:
				tile_surf = pygame.transform.scale(tile_surf, (self.tile_display_size, self.tile_display_size))
				surface.blit(tile_surf, (x, y))

			# Highlight if selected
			if i == self.selected_tile_id:
				tile_rect = pygame.Rect(x - 1, y - 1, self.tile_display_size + 2, self.tile_display_size + 2)
				pygame.draw.rect(surface, COLOR_SELECTED, tile_rect, 2)

		surface.set_clip(clip_rect)

		# Draw title
		title = font.render("Tile Selector", True, COLOR_TEXT)
		surface.blit(title, (self.rect.x + 5, self.rect.y + 5))

	def _render_tile(self, tile: Tile) -> Optional[pygame.Surface]:
		"""Render tile to surface"""
		if not self.palette:
			return None

		surf = pygame.Surface((8, 8))
		for y in range(8):
			for x in range(8):
				color_idx = tile.get_pixel(x, y)
				if 0 <= color_idx < len(self.palette.colors):
					color = self.palette.colors[color_idx]
					r, g, b = color.to_rgb888()
					surf.set_at((x, y), (r, g, b))
		return surf


class AnimationTimelinePanel:
	"""Panel showing animation frames in timeline"""
	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.animation = None
		self.selected_frame_idx = 0
		self.playhead_position = 0  # Current frame being previewed
		self.frame_width = 60

	def set_animation(self, animation: Animation):
		"""Set animation to display"""
		self.animation = animation
		self.selected_frame_idx = 0
		self.playhead_position = 0

	def update(self, mouse_pos: Tuple[int, int], mouse_clicked: bool) -> Optional[int]:
		"""Update timeline, return selected frame index if changed"""
		if not self.animation or not self.rect.collidepoint(mouse_pos):
			return None

		if mouse_clicked:
			rel_x = mouse_pos[0] - self.rect.x - 10
			frame_idx = rel_x // (self.frame_width + 5)

			if 0 <= frame_idx < len(self.animation.frames):
				self.selected_frame_idx = frame_idx
				return frame_idx

		return None

	def advance_playhead(self):
		"""Advance playhead for animation preview"""
		if not self.animation or not self.animation.frames:
			self.playhead_position = 0
			return

		# Simple frame counter
		self.playhead_position += 1

		# Calculate total frames
		total_frames = sum(frame.duration for frame in self.animation.frames)
		if total_frames > 0 and self.animation.loop:
			self.playhead_position %= total_frames

	def get_current_frame_idx(self) -> int:
		"""Get which frame should be displayed based on playhead"""
		if not self.animation or not self.animation.frames:
			return 0

		frame_counter = 0
		for i, frame in enumerate(self.animation.frames):
			frame_counter += frame.duration
			if self.playhead_position < frame_counter:
				return i

		return len(self.animation.frames) - 1 if self.animation.frames else 0

	def draw(self, surface: pygame.Surface, font: pygame.font.Font, database: GraphicsDatabase, palette: Palette):
		"""Draw timeline"""
		pygame.draw.rect(surface, COLOR_TIMELINE, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 2)

		if not self.animation:
			no_anim = font.render("No animation selected", True, COLOR_TEXT)
			surface.blit(no_anim, (self.rect.x + 10, self.rect.y + 10))
			return

		# Draw title
		title = font.render(f"Timeline: {self.animation.name} ({len(self.animation.frames)} frames)", True, COLOR_TEXT)
		surface.blit(title, (self.rect.x + 5, self.rect.y + 5))

		# Draw frames
		x_offset = self.rect.x + 10
		y_offset = self.rect.y + 30

		tileset = database.tilesets.get(0) if database.tilesets else None

		for i, frame in enumerate(self.animation.frames):
			frame_x = x_offset + i * (self.frame_width + 5)
			frame_rect = pygame.Rect(frame_x, y_offset, self.frame_width, self.frame_width + 20)

			# Background
			bg_color = COLOR_SELECTED if i == self.selected_frame_idx else COLOR_PANEL
			pygame.draw.rect(surface, bg_color, frame_rect)
			pygame.draw.rect(surface, COLOR_BORDER, frame_rect, 2)

			# Draw tile preview (using sprite_id as tile_id for now)
			if tileset and 0 <= frame.sprite_id < len(tileset.tiles):
				tile = tileset.tiles[frame.sprite_id]
				tile_surf = self._render_tile(tile, palette)
				if tile_surf:
					tile_surf = pygame.transform.scale(tile_surf, (self.frame_width - 4, self.frame_width - 4))
					surface.blit(tile_surf, (frame_x + 2, y_offset + 2))

			# Duration label
			duration_text = font.render(f"{frame.duration}f", True, COLOR_TEXT)
			surface.blit(duration_text, (frame_x + 2, y_offset + self.frame_width + 2))

		# Draw playhead indicator
		current_frame_idx = self.get_current_frame_idx()
		playhead_x = x_offset + current_frame_idx * (self.frame_width + 5) + self.frame_width // 2
		pygame.draw.line(surface, COLOR_PLAYHEAD,
						(playhead_x, y_offset - 5),
						(playhead_x, y_offset + self.frame_width + 20), 3)

	def _render_tile(self, tile: Tile, palette: Palette) -> Optional[pygame.Surface]:
		"""Render tile to surface"""
		if not palette:
			return None

		surf = pygame.Surface((8, 8))
		for y in range(8):
			for x in range(8):
				color_idx = tile.get_pixel(x, y)
				if 0 <= color_idx < len(palette.colors):
					color = palette.colors[color_idx]
					r, g, b = color.to_rgb888()
					surf.set_at((x, y), (r, g, b))
		return surf


class AnimationPreviewPanel:
	"""Panel showing animation preview"""
	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.animation = None

	def set_animation(self, animation: Animation):
		"""Set animation to preview"""
		self.animation = animation

	def draw(self, surface: pygame.Surface, font: pygame.font.Font, database: GraphicsDatabase,
			palette: Palette, current_frame_idx: int):
		"""Draw animation preview"""
		pygame.draw.rect(surface, COLOR_PANEL, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 2)

		# Title
		title = font.render("Preview", True, COLOR_TEXT)
		surface.blit(title, (self.rect.x + 5, self.rect.y + 5))

		if not self.animation or not self.animation.frames:
			return

		# Get current frame
		if 0 <= current_frame_idx < len(self.animation.frames):
			frame = self.animation.frames[current_frame_idx]

			# Get tileset
			tileset = database.tilesets.get(0) if database.tilesets else None
			if tileset and 0 <= frame.sprite_id < len(tileset.tiles):
				tile = tileset.tiles[frame.sprite_id]
				tile_surf = self._render_tile(tile, palette)
				if tile_surf:
					# Scale up for preview (16x)
					preview_size = 128
					tile_surf = pygame.transform.scale(tile_surf, (preview_size, preview_size))

					# Center in panel
					preview_x = self.rect.centerx - preview_size // 2
					preview_y = self.rect.centery - preview_size // 2
					surface.blit(tile_surf, (preview_x, preview_y))

					# Frame info
					info_text = f"Frame {current_frame_idx + 1}/{len(self.animation.frames)}"
					info_surf = font.render(info_text, True, COLOR_TEXT)
					surface.blit(info_surf, (self.rect.x + 10, self.rect.bottom - 25))

	def _render_tile(self, tile: Tile, palette: Palette) -> Optional[pygame.Surface]:
		"""Render tile to surface"""
		if not palette:
			return None

		surf = pygame.Surface((8, 8))
		for y in range(8):
			for x in range(8):
				color_idx = tile.get_pixel(x, y)
				if 0 <= color_idx < len(palette.colors):
					color = palette.colors[color_idx]
					r, g, b = color.to_rgb888()
					surf.set_at((x, y), (r, g, b))
		return surf


class AnimationEditor:
	"""Main animation editor application"""
	def __init__(self, rom_path: str = ""):
		pygame.init()
		self.width = 1400
		self.height = 900
		self.screen = pygame.display.set_mode((self.width, self.height))
		pygame.display.set_caption("FFMQ Animation Editor")

		self.clock = pygame.time.Clock()
		self.font = pygame.font.Font(None, 20)
		self.title_font = pygame.font.Font(None, 28)

		# Database
		self.database = GraphicsDatabase()
		self.rom_path = rom_path
		if rom_path:
			try:
				self.database.load_from_rom(rom_path)
			except Exception as e:
				print(f"Error loading ROM: {e}")

		# Current state
		self.animations: List[Animation] = []
		self.current_animation: Optional[Animation] = None
		self.current_palette = self.database.palettes.get(0) if self.database.palettes else None

		# Create test animation
		self._create_test_animation()

		# UI Panels
		self.tile_selector = TileSelectorPanel(10, 50, 350, 700, self.database)
		self.tile_selector.set_palette(self.current_palette)

		self.timeline = AnimationTimelinePanel(370, 550, 1020, 150)
		if self.current_animation:
			self.timeline.set_animation(self.current_animation)

		self.preview = AnimationPreviewPanel(370, 50, 400, 480)
		if self.current_animation:
			self.preview.set_animation(self.current_animation)

		# Controls
		self.add_frame_button = Button(780, 60, 120, 30, "Add Frame")
		self.remove_frame_button = Button(910, 60, 120, 30, "Remove Frame")
		self.play_button = Button(1040, 60, 100, 30, "Play")
		self.stop_button = Button(1150, 60, 100, 30, "Stop")
		self.new_anim_button = Button(780, 100, 150, 30, "New Animation")
		self.save_button = Button(940, 100, 100, 30, "Save")

		# Frame duration slider
		self.duration_slider = Slider(780, 150, 470, 25, 1, 120, 10, "Frame Duration")

		# State
		self.playing = False
		self.running = True

	def _create_test_animation(self):
		"""Create a test animation"""
		anim = Animation(
			animation_id=0,
			animation_type=AnimationType.IDLE,
			name="Test Animation",
			loop=True
		)
		# Add some test frames
		for i in range(4):
			anim.add_frame(i, duration=15)

		self.animations.append(anim)
		self.current_animation = anim

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
				elif event.key == pygame.K_SPACE:
					self.playing = not self.playing
				elif event.key == pygame.K_s and (event.mod & pygame.KMOD_CTRL):
					self.save_animation()
			elif event.type == pygame.MOUSEBUTTONDOWN:
				if event.button == 1:  # Left click
					mouse_clicked = True
			elif event.type == pygame.MOUSEWHEEL:
				scroll = event.y

		# Update UI components
		tile_id = self.tile_selector.update(mouse_pos, mouse_clicked, scroll)

		frame_idx = self.timeline.update(mouse_pos, mouse_clicked)

		# Update duration slider
		if self.duration_slider.update(mouse_pos, mouse_down):
			# Duration changed, update current frame if one is selected
			if self.current_animation and 0 <= self.timeline.selected_frame_idx < len(self.current_animation.frames):
				self.current_animation.frames[self.timeline.selected_frame_idx].duration = self.duration_slider.value

		# Update buttons
		if self.add_frame_button.update(mouse_pos, mouse_clicked):
			self.add_frame()

		if self.remove_frame_button.update(mouse_pos, mouse_clicked):
			self.remove_frame()

		if self.play_button.update(mouse_pos, mouse_clicked):
			self.playing = True

		if self.stop_button.update(mouse_pos, mouse_clicked):
			self.playing = False
			self.timeline.playhead_position = 0

		if self.new_anim_button.update(mouse_pos, mouse_clicked):
			self.create_new_animation()

		if self.save_button.update(mouse_pos, mouse_clicked):
			self.save_animation()

	def add_frame(self):
		"""Add frame to current animation"""
		if not self.current_animation:
			return

		tile_id = self.tile_selector.selected_tile_id
		duration = self.duration_slider.value

		self.current_animation.add_frame(tile_id, duration)
		print(f"Added frame: tile {tile_id}, duration {duration}")

	def remove_frame(self):
		"""Remove selected frame from animation"""
		if not self.current_animation:
			return

		idx = self.timeline.selected_frame_idx
		if 0 <= idx < len(self.current_animation.frames):
			del self.current_animation.frames[idx]
			self.timeline.selected_frame_idx = max(0, idx - 1)
			print(f"Removed frame {idx}")

	def create_new_animation(self):
		"""Create new animation"""
		anim_id = len(self.animations)
		anim = Animation(
			animation_id=anim_id,
			animation_type=AnimationType.IDLE,
			name=f"Animation {anim_id}",
			loop=True
		)
		self.animations.append(anim)
		self.current_animation = anim
		self.timeline.set_animation(anim)
		self.preview.set_animation(anim)
		print(f"Created new animation: {anim.name}")

	def save_animation(self):
		"""Save animation data"""
		if not self.current_animation:
			return

		print(f"Saving animation: {self.current_animation.name}")
		print(f"  Frames: {len(self.current_animation.frames)}")
		print(f"  Total duration: {self.current_animation.get_total_duration()} frames")
		# TODO: Implement actual save to ROM

	def update(self):
		"""Update game state"""
		if self.playing:
			self.timeline.advance_playhead()

	def draw(self):
		"""Draw everything"""
		self.screen.fill(COLOR_BG)

		# Draw title
		title = self.title_font.render("FFMQ Tile Animation Editor", True, COLOR_TEXT)
		self.screen.blit(title, (10, 10))

		# Draw panels
		self.tile_selector.draw(self.screen, self.font)
		self.timeline.draw(self.screen, self.font, self.database, self.current_palette)

		current_frame_idx = self.timeline.get_current_frame_idx()
		self.preview.draw(self.screen, self.font, self.database, self.current_palette, current_frame_idx)

		# Draw controls
		self.add_frame_button.draw(self.screen, self.font)
		self.remove_frame_button.draw(self.screen, self.font)
		self.play_button.draw(self.screen, self.font)
		self.stop_button.draw(self.screen, self.font)
		self.new_anim_button.draw(self.screen, self.font)
		self.save_button.draw(self.screen, self.font)

		self.duration_slider.draw(self.screen, self.font)

		# Draw info
		if self.current_animation:
			info_y = 720
			info_texts = [
				f"Animation: {self.current_animation.name}",
				f"Frames: {len(self.current_animation.frames)}",
				f"Total Duration: {self.current_animation.get_total_duration()} frames ({self.current_animation.get_total_duration() / 60:.2f}s)",
				f"Loop: {'Yes' if self.current_animation.loop else 'No'}",
				f"Playing: {'Yes' if self.playing else 'No'}",
			]

			for i, text in enumerate(info_texts):
				surf = self.font.render(text, True, COLOR_TEXT)
				self.screen.blit(surf, (10, info_y + i * 25))

		# Draw instructions
		instructions = [
			"Space: Play/Pause",
			"Ctrl+S: Save",
			"ESC: Quit",
		]
		inst_y = 820
		for i, text in enumerate(instructions):
			surf = self.font.render(text, True, (150, 150, 150))
			self.screen.blit(surf, (10, inst_y + i * 20))

		pygame.display.flip()

	def run(self):
		"""Main loop"""
		while self.running:
			self.handle_events()
			self.update()
			self.draw()
			self.clock.tick(60)

		pygame.quit()


def main():
	"""Entry point"""
	import sys
	rom_path = sys.argv[1] if len(sys.argv) > 1 else ""
	editor = AnimationEditor(rom_path)
	editor.run()


if __name__ == "__main__":
	main()
