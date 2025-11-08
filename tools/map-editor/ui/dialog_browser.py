#!/usr/bin/env python3
"""
FFMQ Dialog Database Browser
Full-featured browser for viewing, searching, and editing all dialogs in ROM
"""

import pygame
from pathlib import Path
from typing import Optional, List, Tuple, Dict, Set
from dataclasses import dataclass, field
from enum import Enum
import sys

# Add utils directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'utils'))

from dialog_text import DialogText, DialogMetrics, ControlCode
from dialog_database import DialogDatabase, DialogEntry
from event_script import EventScriptEngine


# UI Colors
COLOR_BG = (40, 40, 45)
COLOR_PANEL_BG = (50, 50, 55)
COLOR_TEXT = (220, 220, 220)
COLOR_TEXT_DIM = (140, 140, 140)
COLOR_HIGHLIGHT = (70, 130, 180)
COLOR_SELECTED = (100, 160, 220)
COLOR_BORDER = (80, 80, 85)
COLOR_MODIFIED = (255, 200, 100)
COLOR_ERROR = (220, 50, 50)
COLOR_SUCCESS = (80, 200, 120)
COLOR_WARNING = (255, 165, 0)


class SortMode(Enum):
	"""Sort modes for dialog list"""
	ID = "ID"
	ADDRESS = "Address"
	LENGTH = "Length"
	TEXT = "Text"
	MODIFIED = "Modified"


class FilterMode(Enum):
	"""Filter modes for dialog list"""
	ALL = "All Dialogs"
	MODIFIED = "Modified Only"
	ERRORS = "Errors Only"
	EMPTY = "Empty Dialogs"
	LONG = "Long Dialogs (>256 bytes)"


@dataclass
class DialogBrowserState:
	"""State for dialog browser"""
	rom_path: Optional[Path] = None
	database: DialogDatabase = field(default_factory=DialogDatabase)
	dialog_text: DialogText = field(default_factory=DialogText)

	# UI state
	selected_dialog_id: Optional[int] = None
	search_query: str = ""
	sort_mode: SortMode = SortMode.ID
	filter_mode: FilterMode = FilterMode.ALL
	scroll_offset: int = 0

	# Statistics
	total_dialogs: int = 0
	modified_count: int = 0
	error_count: int = 0


class DialogListView:
	"""List view showing all dialogs"""

	def __init__(self, x: int, y: int, width: int, height: int):
		"""Initialize dialog list view"""
		self.x = x
		self.y = y
		self.width = width
		self.height = height
		self.scroll_y = 0
		self.item_height = 60
		self.items: List[DialogEntry] = []
		self.selected_index: Optional[int] = None
		self.hovered_index: Optional[int] = None

	def set_dialogs(self, dialogs: List[DialogEntry]):
		"""Set dialog list"""
		self.items = dialogs
		self.scroll_y = 0

	def handle_click(self, mouse_pos: Tuple[int, int]) -> Optional[int]:
		"""Handle mouse click, return selected dialog ID"""
		if not (self.x <= mouse_pos[0] <= self.x + self.width and
				self.y <= mouse_pos[1] <= self.y + self.height):
			return None

		# Calculate clicked item
		rel_y = mouse_pos[1] - self.y + self.scroll_y
		index = int(rel_y / self.item_height)

		if 0 <= index < len(self.items):
			self.selected_index = index
			return self.items[index].id

		return None

	def handle_scroll(self, amount: int):
		"""Handle scroll wheel"""
		self.scroll_y = max(0, self.scroll_y + amount * 30)
		max_scroll = max(0, len(self.items) * self.item_height - self.height)
		self.scroll_y = min(self.scroll_y, max_scroll)

	def update(self, mouse_pos: Tuple[int, int]):
		"""Update hover state"""
		if not (self.x <= mouse_pos[0] <= self.x + self.width and
				self.y <= mouse_pos[1] <= self.y + self.height):
			self.hovered_index = None
			return

		rel_y = mouse_pos[1] - self.y + self.scroll_y
		index = int(rel_y / self.item_height)
		self.hovered_index = index if 0 <= index < len(self.items) else None

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw dialog list"""
		# Background
		pygame.draw.rect(surface, COLOR_PANEL_BG, (self.x, self.y, self.width, self.height))
		pygame.draw.rect(surface, COLOR_BORDER, (self.x, self.y, self.width, self.height), width=1)

		# Set clip rect
		clip_rect = pygame.Rect(self.x, self.y, self.width, self.height)
		surface.set_clip(clip_rect)

		# Draw items
		y = self.y - self.scroll_y
		for i, dialog in enumerate(self.items):
			if y + self.item_height < self.y:
				y += self.item_height
				continue
			if y > self.y + self.height:
				break

			# Item background
			item_rect = (self.x, y, self.width, self.item_height)

			# Highlight selected/hovered
			if i == self.selected_index:
				pygame.draw.rect(surface, COLOR_SELECTED, item_rect)
			elif i == self.hovered_index:
				pygame.draw.rect(surface, COLOR_HIGHLIGHT, item_rect)

			# Draw separator
			pygame.draw.line(surface, COLOR_BORDER,
				(self.x, y + self.item_height),
				(self.x + self.width, y + self.item_height))

			# Draw dialog info
			text_x = self.x + 10
			text_y = y + 5

			# ID and address
			id_text = f"#{dialog.id:04X}"
			addr_text = f"${dialog.address:06X}"

			id_surf = font.render(id_text, True, COLOR_TEXT)
			surface.blit(id_surf, (text_x, text_y))

			addr_surf = font.render(addr_text, True, COLOR_TEXT_DIM)
			surface.blit(addr_surf, (text_x + 80, text_y))

			# Length
			len_text = f"{dialog.length} bytes"
			len_surf = font.render(len_text, True, COLOR_TEXT_DIM)
			surface.blit(len_surf, (text_x + 200, text_y))

			# Modified indicator
			if dialog.modified:
				mod_surf = font.render("*", True, COLOR_MODIFIED)
				surface.blit(mod_surf, (text_x + self.width - 40, text_y))

			# Dialog text preview (truncated)
			preview = dialog.text.replace('\n', ' ')[:50]
			if len(dialog.text) > 50:
				preview += "..."

			preview_surf = font.render(preview, True, COLOR_TEXT)
			surface.blit(preview_surf, (text_x, text_y + 25))

			y += self.item_height

		surface.set_clip(None)

		# Draw scrollbar
		if len(self.items) * self.item_height > self.height:
			self._draw_scrollbar(surface)

	def _draw_scrollbar(self, surface: pygame.Surface):
		"""Draw scrollbar"""
		scrollbar_width = 8
		scrollbar_x = self.x + self.width - scrollbar_width - 2
		scrollbar_height = self.height - 4

		# Track
		pygame.draw.rect(surface, (60, 60, 65),
			(scrollbar_x, self.y + 2, scrollbar_width, scrollbar_height),
			border_radius=4)

		# Thumb
		total_height = len(self.items) * self.item_height
		visible_ratio = self.height / total_height
		thumb_height = max(20, int(scrollbar_height * visible_ratio))

		scroll_ratio = self.scroll_y / max(1, total_height - self.height)
		thumb_y = self.y + 2 + int((scrollbar_height - thumb_height) * scroll_ratio)

		pygame.draw.rect(surface, (100, 130, 180),
			(scrollbar_x, thumb_y, scrollbar_width, thumb_height),
			border_radius=4)


class DialogDetailView:
	"""Detailed view of selected dialog"""

	def __init__(self, x: int, y: int, width: int, height: int):
		"""Initialize detail view"""
		self.x = x
		self.y = y
		self.width = width
		self.height = height
		self.dialog: Optional[DialogEntry] = None
		self.metrics: Optional[DialogMetrics] = None

	def set_dialog(self, dialog: Optional[DialogEntry], dialog_text: DialogText):
		"""Set dialog to display"""
		self.dialog = dialog
		if dialog:
			self.metrics = dialog_text.calculate_metrics(dialog.text)
		else:
			self.metrics = None

	def draw(self, surface: pygame.Surface, font: pygame.font.Font, small_font: pygame.font.Font):
		"""Draw dialog detail view"""
		# Background
		pygame.draw.rect(surface, COLOR_PANEL_BG, (self.x, self.y, self.width, self.height))
		pygame.draw.rect(surface, COLOR_BORDER, (self.x, self.y, self.width, self.height), width=1)

		if not self.dialog:
			# Show "no selection" message
			no_sel_surf = font.render("Select a dialog to view details", True, COLOR_TEXT_DIM)
			no_sel_rect = no_sel_surf.get_rect(center=(self.x + self.width // 2, self.y + self.height // 2))
			surface.blit(no_sel_surf, no_sel_rect)
			return

		# Draw dialog details
		y = self.y + 10
		x = self.x + 10

		# Title
		title_surf = font.render(f"Dialog #{self.dialog.id:04X}", True, COLOR_TEXT)
		surface.blit(title_surf, (x, y))
		y += 30

		# Metadata
		metadata = [
			f"Address: ${self.dialog.address:06X} (SNES: ${self.dialog.snes_bank:02X}:{self.dialog.snes_address:04X})",
			f"Pointer: ${self.dialog.pointer:06X}",
			f"Length: {self.dialog.length} bytes",
			f"Modified: {'Yes' if self.dialog.modified else 'No'}",
		]

		for line in metadata:
			line_surf = small_font.render(line, True, COLOR_TEXT_DIM)
			surface.blit(line_surf, (x, y))
			y += 20

		y += 10

		# Metrics
		if self.metrics:
			pygame.draw.line(surface, COLOR_BORDER, (x, y), (x + self.width - 20, y))
			y += 10

			metrics_surf = font.render("Metrics", True, COLOR_TEXT)
			surface.blit(metrics_surf, (x, y))
			y += 25

			metrics_lines = [
				f"Characters: {self.metrics.char_count}",
				f"Lines: {self.metrics.line_count}",
				f"Max line length: {self.metrics.max_line_length}",
				f"Estimated time: {self.metrics.estimated_time:.1f}s",
			]

			for line in metrics_lines:
				line_surf = small_font.render(line, True, COLOR_TEXT_DIM)
				surface.blit(line_surf, (x, y))
				y += 20

			# Control codes used
			if self.metrics.control_codes:
				y += 10
				codes_surf = font.render("Control Codes:", True, COLOR_TEXT)
				surface.blit(codes_surf, (x, y))
				y += 25

				for code, count in self.metrics.control_codes.items():
					code_line = f"  {code}: {count}"
					code_surf = small_font.render(code_line, True, COLOR_TEXT_DIM)
					surface.blit(code_surf, (x, y))
					y += 20

			# Warnings
			if self.metrics.warnings:
				y += 10
				pygame.draw.line(surface, COLOR_BORDER, (x, y), (x + self.width - 20, y))
				y += 10

				warn_surf = font.render("Warnings", True, COLOR_WARNING)
				surface.blit(warn_surf, (x, y))
				y += 25

				for warning in self.metrics.warnings:
					warn_line_surf = small_font.render(f"⚠ {warning}", True, COLOR_WARNING)
					surface.blit(warn_line_surf, (x, y))
					y += 20

		# Hex dump
		y += 20
		if y < self.y + self.height - 100:
			pygame.draw.line(surface, COLOR_BORDER, (x, y), (x + self.width - 20, y))
			y += 10

			hex_surf = font.render("Raw Bytes", True, COLOR_TEXT)
			surface.blit(hex_surf, (x, y))
			y += 25

			# Show first 64 bytes
			hex_str = ' '.join(f'{b:02X}' for b in self.dialog.raw_bytes[:64])
			if len(self.dialog.raw_bytes) > 64:
				hex_str += " ..."

			# Wrap hex string
			hex_lines = []
			for i in range(0, len(hex_str), 60):
				hex_lines.append(hex_str[i:i+60])

			for line in hex_lines[:3]:  # Max 3 lines
				hex_line_surf = small_font.render(line, True, COLOR_TEXT_DIM)
				surface.blit(hex_line_surf, (x, y))
				y += 18


class DialogSearchPanel:
	"""Search and filter panel"""

	def __init__(self, x: int, y: int, width: int, height: int):
		"""Initialize search panel"""
		self.x = x
		self.y = y
		self.width = width
		self.height = height
		self.search_text = ""
		self.search_focused = False
		self.cursor_visible = True
		self.cursor_timer = 0

	def handle_click(self, mouse_pos: Tuple[int, int]) -> bool:
		"""Handle mouse click"""
		search_rect = (self.x + 10, self.y + 10, self.width - 20, 30)
		self.search_focused = (
			search_rect[0] <= mouse_pos[0] <= search_rect[0] + search_rect[2] and
			search_rect[1] <= mouse_pos[1] <= search_rect[1] + search_rect[3]
		)
		return self.search_focused

	def handle_key(self, event: pygame.event.Event) -> bool:
		"""Handle keyboard input, return True if search changed"""
		if not self.search_focused:
			return False

		if event.type == pygame.KEYDOWN:
			if event.key == pygame.K_BACKSPACE:
				if self.search_text:
					self.search_text = self.search_text[:-1]
					return True
			elif event.key == pygame.K_ESCAPE:
				self.search_focused = False
			elif event.unicode and len(self.search_text) < 50:
				self.search_text += event.unicode
				return True

		return False

	def update(self, dt: float):
		"""Update cursor blink"""
		self.cursor_timer += dt
		if self.cursor_timer >= 0.5:
			self.cursor_visible = not self.cursor_visible
			self.cursor_timer = 0

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw search panel"""
		# Background
		pygame.draw.rect(surface, COLOR_PANEL_BG, (self.x, self.y, self.width, self.height))
		pygame.draw.rect(surface, COLOR_BORDER, (self.x, self.y, self.width, self.height), width=1)

		# Search input
		input_rect = (self.x + 10, self.y + 10, self.width - 20, 30)
		bg_color = (35, 35, 40)
		border_color = COLOR_HIGHLIGHT if self.search_focused else COLOR_BORDER

		pygame.draw.rect(surface, bg_color, input_rect, border_radius=3)
		pygame.draw.rect(surface, border_color, input_rect, width=2, border_radius=3)

		# Search text
		display_text = self.search_text if self.search_text else "Search dialogs..."
		text_color = COLOR_TEXT if self.search_text else COLOR_TEXT_DIM

		text_surf = font.render(display_text, True, text_color)
		text_rect = text_surf.get_rect(midleft=(self.x + 20, self.y + 25))
		surface.blit(text_surf, text_rect)

		# Cursor
		if self.search_focused and self.cursor_visible and self.search_text:
			cursor_x = self.x + 20 + text_surf.get_width() + 2
			pygame.draw.line(surface, COLOR_TEXT,
				(cursor_x, self.y + 15),
				(cursor_x, self.y + 35), 2)


class DialogBrowser:
	"""Main dialog browser window"""

	def __init__(self, width: int = 1200, height: int = 800):
		"""Initialize dialog browser"""
		pygame.init()
		self.width = width
		self.height = height
		self.screen = pygame.display.set_mode((width, height))
		pygame.display.set_caption("FFMQ Dialog Browser")

		self.font = pygame.font.SysFont('consolas', 14)
		self.small_font = pygame.font.SysFont('consolas', 12)
		self.title_font = pygame.font.SysFont('consolas', 18, bold=True)

		self.state = DialogBrowserState()
		self.running = True
		self.clock = pygame.time.Clock()

		# UI components
		self.search_panel = DialogSearchPanel(10, 10, 400, 50)
		self.list_view = DialogListView(10, 70, 400, height - 80)
		self.detail_view = DialogDetailView(420, 10, width - 430, height - 20)

		# Load dialogs (placeholder - would load from ROM)
		self._create_sample_dialogs()

	def _create_sample_dialogs(self):
		"""Create sample dialogs for testing"""
		dialog_text = DialogText()

		sample_texts = [
			"Welcome to Foresta!\nThis is your adventure.",
			"The prophecy speaks of a hero...[WAIT]",
			"Find the Crystals to save the world![NEWLINE]Good luck!",
			"I am an NPC.[WAIT]\nI have generic dialog.",
			"Shop: Buy? Sell? Leave?",
		]

		for i, text in enumerate(sample_texts):
			encoded = dialog_text.encode(text)
			entry = DialogEntry(
				id=i,
				text=text,
				raw_bytes=encoded,
				pointer=0x8000 + i * 0x100,
				address=0x018000 + i * 0x100,
				length=len(encoded)
			)
			self.state.database.dialogs[i] = entry

		self.state.total_dialogs = len(sample_texts)
		self._update_filtered_list()

	def _update_filtered_list(self):
		"""Update filtered dialog list based on search/filter"""
		all_dialogs = list(self.state.database.dialogs.values())

		# Apply search filter
		if self.search_panel.search_text:
			query = self.search_panel.search_text.lower()
			all_dialogs = [
				d for d in all_dialogs
				if query in d.text.lower() or query in f"{d.id:04X}"
			]

		# Apply filter mode
		if self.state.filter_mode == FilterMode.MODIFIED:
			all_dialogs = [d for d in all_dialogs if d.modified]
		elif self.state.filter_mode == FilterMode.EMPTY:
			all_dialogs = [d for d in all_dialogs if not d.text.strip()]
		elif self.state.filter_mode == FilterMode.LONG:
			all_dialogs = [d for d in all_dialogs if d.length > 256]

		# Apply sort
		if self.state.sort_mode == SortMode.ID:
			all_dialogs.sort(key=lambda d: d.id)
		elif self.state.sort_mode == SortMode.ADDRESS:
			all_dialogs.sort(key=lambda d: d.address)
		elif self.state.sort_mode == SortMode.LENGTH:
			all_dialogs.sort(key=lambda d: d.length, reverse=True)
		elif self.state.sort_mode == SortMode.TEXT:
			all_dialogs.sort(key=lambda d: d.text)
		elif self.state.sort_mode == SortMode.MODIFIED:
			all_dialogs.sort(key=lambda d: d.modified, reverse=True)

		self.list_view.set_dialogs(all_dialogs)

	def run(self):
		"""Main loop"""
		while self.running:
			dt = self.clock.tick(60) / 1000.0  # Delta time in seconds

			# Handle events
			mouse_pos = pygame.mouse.get_pos()

			for event in pygame.event.get():
				if event.type == pygame.QUIT:
					self.running = False

				elif event.type == pygame.MOUSEBUTTONDOWN:
					if event.button == 1:  # Left click
						# Check search panel
						self.search_panel.handle_click(mouse_pos)

						# Check list view
						selected_id = self.list_view.handle_click(mouse_pos)
						if selected_id is not None:
							self.state.selected_dialog_id = selected_id
							dialog = self.state.database.dialogs.get(selected_id)
							self.detail_view.set_dialog(dialog, self.state.dialog_text)

					elif event.button == 4:  # Scroll up
						self.list_view.handle_scroll(-1)
					elif event.button == 5:  # Scroll down
						self.list_view.handle_scroll(1)

				elif event.type == pygame.KEYDOWN:
					if self.search_panel.handle_key(event):
						self._update_filtered_list()

			# Update
			self.search_panel.update(dt)
			self.list_view.update(mouse_pos)

			# Draw
			self.screen.fill(COLOR_BG)

			self.search_panel.draw(self.screen, self.font)
			self.list_view.draw(self.screen, self.font)
			self.detail_view.draw(self.screen, self.font, self.small_font)

			# Status bar
			status_text = f"{len(self.list_view.items)} dialogs | {self.state.modified_count} modified"
			status_surf = self.small_font.render(status_text, True, COLOR_TEXT_DIM)
			self.screen.blit(status_surf, (10, self.height - 20))

			pygame.display.flip()

		pygame.quit()


# Main entry point
if __name__ == '__main__':
	browser = DialogBrowser()
	browser.run()
