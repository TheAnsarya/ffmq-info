"""
FFMQ Music Editor

Visual editor for music tracks and sound effects.
"""

import pygame
from typing import Optional, List
from utils.music_data import MusicTrack, SoundEffect, MusicType, SoundEffectType, note_to_pitch, pitch_to_note
from utils.music_database import MusicDatabase


# Colors
WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
GRAY = (128, 128, 128)
LIGHT_GRAY = (192, 192, 192)
DARK_GRAY = (64, 64, 64)
BLUE = (0, 120, 215)
RED = (255, 0, 0)
GREEN = (0, 200, 0)
YELLOW = (255, 255, 0)


class TrackListPanel:
	"""Panel for listing and selecting music tracks"""

	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.database: Optional[MusicDatabase] = None
		self.selected_track_id: Optional[int] = None
		self.scroll_offset = 0
		self.item_height = 30

	def set_database(self, database: MusicDatabase):
		"""Set music database"""
		self.database = database
		self.selected_track_id = None
		self.scroll_offset = 0

	def handle_event(self, event: pygame.event.Event) -> Optional[int]:
		"""Handle input events, returns selected track ID"""
		if self.database is None:
			return None

		if event.type == pygame.MOUSEBUTTONDOWN:
			if event.button == 1:  # Left click
				mouse_x, mouse_y = event.pos
				if self.rect.collidepoint(mouse_x, mouse_y):
					rel_y = mouse_y - self.rect.y - 40 + self.scroll_offset
					idx = rel_y // self.item_height

					track_ids = sorted(self.database.tracks.keys())
					if 0 <= idx < len(track_ids):
						self.selected_track_id = track_ids[idx]
						return self.selected_track_id

			elif event.button == 4:  # Mouse wheel up
				self.scroll_offset = max(0, self.scroll_offset - 20)

			elif event.button == 5:  # Mouse wheel down
				max_scroll = max(0, len(self.database.tracks) * self.item_height - self.rect.height + 60)
				self.scroll_offset = min(max_scroll, self.scroll_offset + 20)

		return None

	def render(self, screen: pygame.Surface, font: pygame.font.Font):
		"""Render track list"""
		# Background
		pygame.draw.rect(screen, WHITE, self.rect)
		pygame.draw.rect(screen, BLACK, self.rect, 2)

		# Title
		title = font.render("Music Tracks", True, BLACK)
		screen.blit(title, (self.rect.x + 10, self.rect.y + 10))

		if self.database is None:
			return

		# Create clipping region
		clip_rect = pygame.Rect(self.rect.x + 10, self.rect.y + 40,
								self.rect.width - 20, self.rect.height - 50)
		screen.set_clip(clip_rect)

		# Draw tracks
		track_ids = sorted(self.database.tracks.keys())
		for idx, track_id in enumerate(track_ids):
			track = self.database.tracks[track_id]
			y = self.rect.y + 40 + idx * self.item_height - self.scroll_offset

			# Skip if not visible
			if y + self.item_height < self.rect.y + 40 or y > self.rect.y + self.rect.height:
				continue

			# Highlight if selected
			if track_id == self.selected_track_id:
				highlight_rect = pygame.Rect(self.rect.x + 10, y, self.rect.width - 20, self.item_height - 2)
				pygame.draw.rect(screen, BLUE, highlight_rect)

			# Draw track info
			text_color = WHITE if track_id == self.selected_track_id else BLACK
			text = font.render(f"{track_id:02X}: {track.name}", True, text_color)
			screen.blit(text, (self.rect.x + 15, y + 5))

		# Clear clipping
		screen.set_clip(None)


class TrackEditorPanel:
	"""Panel for editing track properties"""

	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.track: Optional[MusicTrack] = None
		self.editing_field: Optional[str] = None

	def set_track(self, track: MusicTrack):
		"""Set track to edit"""
		self.track = track

	def handle_event(self, event: pygame.event.Event) -> bool:
		"""Handle input events"""
		if self.track is None:
			return False

		if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
			mouse_x, mouse_y = event.pos
			if self.rect.collidepoint(mouse_x, mouse_y):
				# Check if clicked on editable field
				# (Would implement field detection here)
				return True

		elif event.type == pygame.KEYDOWN:
			if self.editing_field:
				# Handle text input
				# (Would implement text editing here)
				return True

		return False

	def render(self, screen: pygame.Surface, font: pygame.font.Font, small_font: pygame.font.Font):
		"""Render track editor"""
		# Background
		pygame.draw.rect(screen, LIGHT_GRAY, self.rect)
		pygame.draw.rect(screen, BLACK, self.rect, 2)

		if self.track is None:
			text = font.render("No track selected", True, BLACK)
			screen.blit(text, (self.rect.x + 10, self.rect.y + 10))
			return

		# Title
		title = font.render(f"Track {self.track.track_id:02X}: {self.track.name}", True, BLACK)
		screen.blit(title, (self.rect.x + 10, self.rect.y + 10))

		y = self.rect.y + 50

		# Track properties
		properties = [
			("Type", self.track.music_type.name),
			("Tempo", f"{self.track.tempo} BPM"),
			("Volume", f"{self.track.volume}/127"),
			("Channels", f"{bin(self.track.channels_used)[2:].zfill(8)}"),
			("Loop Start", f"{self.track.loop_start}"),
			("Loop End", f"{self.track.loop_end}"),
			("Data Offset", f"${self.track.data_offset:06X}"),
			("Data Size", f"{self.track.data_size} bytes"),
			("Duration", f"{self.track.get_duration_seconds():.1f}s"),
		]

		for label, value in properties:
			text = small_font.render(f"{label}: {value}", True, BLACK)
			screen.blit(text, (self.rect.x + 20, y))
			y += 25

		# Channel visualization
		y += 20
		channel_label = font.render("Active Channels:", True, BLACK)
		screen.blit(channel_label, (self.rect.x + 20, y))
		y += 30

		for i in range(8):
			active = (self.track.channels_used >> i) & 1
			color = GREEN if active else DARK_GRAY

			channel_rect = pygame.Rect(self.rect.x + 20 + i * 40, y, 30, 20)
			pygame.draw.rect(screen, color, channel_rect)
			pygame.draw.rect(screen, BLACK, channel_rect, 1)

			ch_text = small_font.render(str(i), True, BLACK)
			screen.blit(ch_text, (channel_rect.x + 10, channel_rect.y + 2))


class SFXListPanel:
	"""Panel for listing sound effects"""

	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.database: Optional[MusicDatabase] = None
		self.selected_sfx_id: Optional[int] = None
		self.scroll_offset = 0
		self.item_height = 25

	def set_database(self, database: MusicDatabase):
		"""Set music database"""
		self.database = database
		self.selected_sfx_id = None
		self.scroll_offset = 0

	def handle_event(self, event: pygame.event.Event) -> Optional[int]:
		"""Handle input events, returns selected SFX ID"""
		if self.database is None:
			return None

		if event.type == pygame.MOUSEBUTTONDOWN:
			if event.button == 1:
				mouse_x, mouse_y = event.pos
				if self.rect.collidepoint(mouse_x, mouse_y):
					rel_y = mouse_y - self.rect.y - 40 + self.scroll_offset
					idx = rel_y // self.item_height

					sfx_ids = sorted(self.database.sfx.keys())
					if 0 <= idx < len(sfx_ids):
						self.selected_sfx_id = sfx_ids[idx]
						return self.selected_sfx_id

			elif event.button == 4:
				self.scroll_offset = max(0, self.scroll_offset - 20)

			elif event.button == 5:
				max_scroll = max(0, len(self.database.sfx) * self.item_height - self.rect.height + 60)
				self.scroll_offset = min(max_scroll, self.scroll_offset + 20)

		return None

	def render(self, screen: pygame.Surface, font: pygame.font.Font, small_font: pygame.font.Font):
		"""Render SFX list"""
		# Background
		pygame.draw.rect(screen, WHITE, self.rect)
		pygame.draw.rect(screen, BLACK, self.rect, 2)

		# Title
		title = font.render("Sound Effects", True, BLACK)
		screen.blit(title, (self.rect.x + 10, self.rect.y + 10))

		if self.database is None:
			return

		# Create clipping region
		clip_rect = pygame.Rect(self.rect.x + 10, self.rect.y + 40,
								self.rect.width - 20, self.rect.height - 50)
		screen.set_clip(clip_rect)

		# Draw SFX
		sfx_ids = sorted(self.database.sfx.keys())
		for idx, sfx_id in enumerate(sfx_ids):
			sfx = self.database.sfx[sfx_id]
			y = self.rect.y + 40 + idx * self.item_height - self.scroll_offset

			if y + self.item_height < self.rect.y + 40 or y > self.rect.y + self.rect.height:
				continue

			# Highlight if selected
			if sfx_id == self.selected_sfx_id:
				highlight_rect = pygame.Rect(self.rect.x + 10, y, self.rect.width - 20, self.item_height - 2)
				pygame.draw.rect(screen, BLUE, highlight_rect)

			# Draw SFX info
			text_color = WHITE if sfx_id == self.selected_sfx_id else BLACK
			text = small_font.render(f"{sfx_id:02X}: {sfx.name}", True, text_color)
			screen.blit(text, (self.rect.x + 15, y + 3))

		screen.set_clip(None)


class SFXEditorPanel:
	"""Panel for editing sound effect properties"""

	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.sfx: Optional[SoundEffect] = None

	def set_sfx(self, sfx: SoundEffect):
		"""Set SFX to edit"""
		self.sfx = sfx

	def render(self, screen: pygame.Surface, font: pygame.font.Font, small_font: pygame.font.Font):
		"""Render SFX editor"""
		# Background
		pygame.draw.rect(screen, LIGHT_GRAY, self.rect)
		pygame.draw.rect(screen, BLACK, self.rect, 2)

		if self.sfx is None:
			text = font.render("No SFX selected", True, BLACK)
			screen.blit(text, (self.rect.x + 10, self.rect.y + 10))
			return

		# Title
		title = font.render(f"SFX {self.sfx.sfx_id:02X}: {self.sfx.name}", True, BLACK)
		screen.blit(title, (self.rect.x + 10, self.rect.y + 10))

		y = self.rect.y + 50

		# SFX properties
		properties = [
			("Type", self.sfx.sfx_type.name),
			("Priority", f"{self.sfx.priority}/127"),
			("Volume", f"{self.sfx.volume}/127"),
			("Pitch", f"{self.sfx.pitch}/127 ({pitch_to_note(self.sfx.pitch * 32)})"),
			("Pan", f"{self.sfx.pan}/127 ({'L' if self.sfx.pan < 50 else 'C' if self.sfx.pan < 78 else 'R'})"),
			("Data Offset", f"${self.sfx.data_offset:06X}"),
			("Data Size", f"{self.sfx.data_size} bytes"),
		]

		for label, value in properties:
			text = small_font.render(f"{label}: {value}", True, BLACK)
			screen.blit(text, (self.rect.x + 20, y))
			y += 25

		# Visual sliders
		y += 20
		self._render_slider(screen, small_font, "Volume", self.sfx.volume, 127, self.rect.x + 20, y)
		y += 30
		self._render_slider(screen, small_font, "Pitch", self.sfx.pitch, 127, self.rect.x + 20, y)
		y += 30
		self._render_slider(screen, small_font, "Pan", self.sfx.pan, 127, self.rect.x + 20, y, show_center=True)

	def _render_slider(self, screen: pygame.Surface, font: pygame.font.Font, label: str, value: int, max_value: int, x: int, y: int, show_center: bool = False):
		"""Render a slider"""
		label_text = font.render(f"{label}:", True, BLACK)
		screen.blit(label_text, (x, y))

		slider_rect = pygame.Rect(x + 80, y, 200, 20)
		pygame.draw.rect(screen, WHITE, slider_rect)
		pygame.draw.rect(screen, BLACK, slider_rect, 1)

		# Center line for pan
		if show_center:
			center_x = x + 80 + 100
			pygame.draw.line(screen, GRAY, (center_x, y), (center_x, y + 20), 1)

		# Value indicator
		indicator_x = x + 80 + int((value / max_value) * 200)
		pygame.draw.line(screen, RED, (indicator_x, y), (indicator_x, y + 20), 3)

		value_text = font.render(str(value), True, BLACK)
		screen.blit(value_text, (x + 290, y))


class MusicEditor:
	"""Main music editor application"""

	def __init__(self, width: int = 1200, height: int = 800):
		pygame.init()
		self.screen = pygame.display.set_mode((width, height))
		pygame.display.set_caption("FFMQ Music Editor")

		self.font = pygame.font.Font(None, 24)
		self.small_font = pygame.font.Font(None, 18)

		self.database = MusicDatabase()
		self.running = True
		self.clock = pygame.time.Clock()

		# Create panels
		self.track_list_panel = TrackListPanel(10, 10, 350, 400)
		self.track_editor_panel = TrackEditorPanel(370, 10, 400, 400)
		self.sfx_list_panel = SFXListPanel(10, 420, 350, 370)
		self.sfx_editor_panel = SFXEditorPanel(370, 420, 400, 370)

		# State
		self.modified = False

	def load_rom(self, rom_path: str):
		"""Load ROM file"""
		try:
			self.database.load_from_rom(rom_path)

			# Set panels
			self.track_list_panel.set_database(self.database)
			self.sfx_list_panel.set_database(self.database)

			# Select first track
			if self.database.tracks:
				first_id = sorted(self.database.tracks.keys())[0]
				self.track_list_panel.selected_track_id = first_id
				self.track_editor_panel.set_track(self.database.tracks[first_id])

			# Select first SFX
			if self.database.sfx:
				first_id = sorted(self.database.sfx.keys())[0]
				self.sfx_list_panel.selected_sfx_id = first_id
				self.sfx_editor_panel.set_sfx(self.database.sfx[first_id])

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

			# Track list
			selected_track = self.track_list_panel.handle_event(event)
			if selected_track is not None:
				track = self.database.get_track(selected_track)
				if track:
					self.track_editor_panel.set_track(track)

			# SFX list
			selected_sfx = self.sfx_list_panel.handle_event(event)
			if selected_sfx is not None:
				sfx = self.database.get_sfx(selected_sfx)
				if sfx:
					self.sfx_editor_panel.set_sfx(sfx)

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
		self.track_list_panel.render(self.screen, self.font)
		self.track_editor_panel.render(self.screen, self.font, self.small_font)
		self.sfx_list_panel.render(self.screen, self.font, self.small_font)
		self.sfx_editor_panel.render(self.screen, self.font, self.small_font)

		# Status bar
		stats = self.database.get_statistics()
		status_text = f"Tracks: {stats['total_tracks']} | SFX: {stats['total_sfx']} | Samples: {stats['total_samples']} | "
		status_text += f"{'MODIFIED' if self.modified else 'Saved'} | Ctrl+S: Save | ESC: Quit"

		status_surface = self.small_font.render(status_text, True, WHITE)
		self.screen.blit(status_surface, (10, self.screen.get_height() - 25))

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

	editor = MusicEditor()

	if len(sys.argv) > 1:
		editor.load_rom(sys.argv[1])

	editor.run()


if __name__ == "__main__":
	main()
