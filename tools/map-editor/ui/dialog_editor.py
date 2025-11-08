#!/usr/bin/env python3
"""
FFMQ Dialog Editor UI
Pygame-based visual editor for dialog text and event scripts
"""

import pygame
from pathlib import Path
from typing import Optional, List, Tuple, Dict, Set
from dataclasses import dataclass
import sys

# Add utils directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'utils'))

from dialog_text import DialogText, DialogMetrics, ControlCode, CONTROL_NAMES
from dialog_database import DialogDatabase, DialogEntry
from event_script import EventScriptEngine, EventScript, CommandCategory


# UI Colors
COLOR_BG = (40, 40, 45)
COLOR_PANEL_BG = (50, 50, 55)
COLOR_TEXT = (220, 220, 220)
COLOR_TEXT_DIM = (140, 140, 140)
COLOR_HIGHLIGHT = (70, 130, 180)
COLOR_SELECTED = (100, 160, 220)
COLOR_BORDER = (80, 80, 85)
COLOR_WARNING = (255, 165, 0)
COLOR_ERROR = (220, 50, 50)
COLOR_SUCCESS = (80, 200, 120)
COLOR_BUTTON = (60, 120, 180)
COLOR_BUTTON_HOVER = (80, 140, 200)
COLOR_INPUT_BG = (35, 35, 40)
COLOR_SCROLLBAR = (70, 70, 75)

# UI Layout
PANEL_MARGIN = 10
PADDING = 5
LINE_HEIGHT = 24
BUTTON_HEIGHT = 32
INPUT_HEIGHT = 28


@dataclass
class UIRect:
	"""Rectangle with collision detection"""
	x: int
	y: int
	width: int
	height: int
	
	def contains(self, x: int, y: int) -> bool:
		"""Check if point is inside rectangle"""
		return (self.x <= x <= self.x + self.width and
			self.y <= y <= self.y + self.height)
	
	def to_pygame(self) -> Tuple[int, int, int, int]:
		"""Convert to pygame rect tuple"""
		return (self.x, self.y, self.width, self.height)


class Button:
	"""Simple button widget"""
	
	def __init__(self, x: int, y: int, width: int, height: int, text: str, callback=None):
		self.rect = UIRect(x, y, width, height)
		self.text = text
		self.callback = callback
		self.hovered = False
		self.enabled = True
	
	def update(self, mouse_pos: Tuple[int, int]):
		"""Update hover state"""
		self.hovered = self.rect.contains(*mouse_pos) and self.enabled
	
	def handle_click(self, mouse_pos: Tuple[int, int]) -> bool:
		"""Handle click event"""
		if self.enabled and self.rect.contains(*mouse_pos):
			if self.callback:
				self.callback()
			return True
		return False
	
	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw button"""
		color = COLOR_BUTTON_HOVER if self.hovered else COLOR_BUTTON
		if not self.enabled:
			color = COLOR_BORDER
		
		pygame.draw.rect(surface, color, self.rect.to_pygame(), border_radius=4)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect.to_pygame(), width=1, border_radius=4)
		
		text_surf = font.render(self.text, True, COLOR_TEXT if self.enabled else COLOR_TEXT_DIM)
		text_rect = text_surf.get_rect(center=(self.rect.x + self.rect.width // 2,
			self.rect.y + self.rect.height // 2))
		surface.blit(text_surf, text_rect)


class TextInput:
	"""Text input widget"""
	
	def __init__(self, x: int, y: int, width: int, height: int, placeholder: str = ""):
		self.rect = UIRect(x, y, width, height)
		self.text = ""
		self.placeholder = placeholder
		self.focused = False
		self.cursor_pos = 0
		self.cursor_visible = True
		self.cursor_timer = 0
	
	def handle_click(self, mouse_pos: Tuple[int, int]) -> bool:
		"""Handle click event"""
		self.focused = self.rect.contains(*mouse_pos)
		return self.focused
	
	def handle_key(self, event: pygame.event.Event):
		"""Handle keyboard event"""
		if not self.focused:
			return
		
		if event.type == pygame.KEYDOWN:
			if event.key == pygame.K_BACKSPACE:
				if self.cursor_pos > 0:
					self.text = self.text[:self.cursor_pos - 1] + self.text[self.cursor_pos:]
					self.cursor_pos -= 1
			elif event.key == pygame.K_DELETE:
				if self.cursor_pos < len(self.text):
					self.text = self.text[:self.cursor_pos] + self.text[self.cursor_pos + 1:]
			elif event.key == pygame.K_LEFT:
				self.cursor_pos = max(0, self.cursor_pos - 1)
			elif event.key == pygame.K_RIGHT:
				self.cursor_pos = min(len(self.text), self.cursor_pos + 1)
			elif event.key == pygame.K_HOME:
				self.cursor_pos = 0
			elif event.key == pygame.K_END:
				self.cursor_pos = len(self.text)
			elif event.unicode:
				self.text = self.text[:self.cursor_pos] + event.unicode + self.text[self.cursor_pos:]
				self.cursor_pos += 1
	
	def update(self, dt: float):
		"""Update cursor blink"""
		self.cursor_timer += dt
		if self.cursor_timer >= 0.5:
			self.cursor_visible = not self.cursor_visible
			self.cursor_timer = 0
	
	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw text input"""
		# Background
		pygame.draw.rect(surface, COLOR_INPUT_BG, self.rect.to_pygame(), border_radius=3)
		
		# Border
		border_color = COLOR_HIGHLIGHT if self.focused else COLOR_BORDER
		pygame.draw.rect(surface, border_color, self.rect.to_pygame(), width=2, border_radius=3)
		
		# Text
		display_text = self.text if self.text else self.placeholder
		text_color = COLOR_TEXT if self.text else COLOR_TEXT_DIM
		
		text_surf = font.render(display_text, True, text_color)
		text_rect = text_surf.get_rect(midleft=(self.rect.x + PADDING, self.rect.y + self.rect.height // 2))
		
		# Clip text to input bounds
		clip_rect = pygame.Rect(self.rect.x + PADDING, self.rect.y,
			self.rect.width - 2 * PADDING, self.rect.height)
		surface.set_clip(clip_rect)
		surface.blit(text_surf, text_rect)
		surface.set_clip(None)
		
		# Cursor
		if self.focused and self.cursor_visible:
			cursor_x = self.rect.x + PADDING
			if self.cursor_pos > 0:
				cursor_text = self.text[:self.cursor_pos]
				cursor_surf = font.render(cursor_text, True, COLOR_TEXT)
				cursor_x += cursor_surf.get_width()
			
			pygame.draw.line(surface, COLOR_TEXT,
				(cursor_x, self.rect.y + 4),
				(cursor_x, self.rect.y + self.rect.height - 4), 2)


class DialogListPanel:
	"""Panel showing list of dialogs"""
	
	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = UIRect(x, y, width, height)
		self.dialogs: List[DialogEntry] = []
		self.filtered_dialogs: List[DialogEntry] = []
		self.selected_index: Optional[int] = None
		self.scroll_offset = 0
		self.item_height = LINE_HEIGHT
		
		# Search box
		self.search_input = TextInput(x + PADDING, y + PADDING, width - 2 * PADDING, INPUT_HEIGHT, "Search...")
	
	def set_dialogs(self, dialogs: List[DialogEntry]):
		"""Set dialog list"""
		self.dialogs = sorted(dialogs, key=lambda d: d.id)
		self.filtered_dialogs = self.dialogs.copy()
	
	def filter_dialogs(self, query: str):
		"""Filter dialogs by search query"""
		if not query:
			self.filtered_dialogs = self.dialogs.copy()
		else:
			query_lower = query.lower()
			self.filtered_dialogs = [
				d for d in self.dialogs
				if query_lower in d.text.lower() or
				query_lower in ' '.join(d.tags).lower()
			]
	
	def get_selected_dialog(self) -> Optional[DialogEntry]:
		"""Get currently selected dialog"""
		if self.selected_index is not None and 0 <= self.selected_index < len(self.filtered_dialogs):
			return self.filtered_dialogs[self.selected_index]
		return None
	
	def handle_click(self, mouse_pos: Tuple[int, int]) -> Optional[DialogEntry]:
		"""Handle click event"""
		# Check search box
		if self.search_input.handle_click(mouse_pos):
			return None
		
		# Check dialog list
		x, y = mouse_pos
		if not self.rect.contains(x, y):
			return None
		
		# Calculate which item was clicked
		list_y = self.rect.y + PADDING + INPUT_HEIGHT + PADDING
		relative_y = y - list_y + self.scroll_offset
		
		item_index = int(relative_y / self.item_height)
		
		if 0 <= item_index < len(self.filtered_dialogs):
			self.selected_index = item_index
			return self.filtered_dialogs[item_index]
		
		return None
	
	def handle_key(self, event: pygame.event.Event):
		"""Handle keyboard event"""
		self.search_input.handle_key(event)
		
		# Update filter when search text changes
		if event.type == pygame.KEYDOWN and self.search_input.focused:
			self.filter_dialogs(self.search_input.text)
	
	def handle_scroll(self, amount: int):
		"""Handle mouse wheel scroll"""
		self.scroll_offset = max(0, self.scroll_offset - amount * 3)
	
	def update(self, dt: float):
		"""Update animations"""
		self.search_input.update(dt)
	
	def draw(self, surface: pygame.Surface, font: pygame.font.Font, font_small: pygame.font.Font):
		"""Draw dialog list panel"""
		# Background
		pygame.draw.rect(surface, COLOR_PANEL_BG, self.rect.to_pygame())
		pygame.draw.rect(surface, COLOR_BORDER, self.rect.to_pygame(), width=1)
		
		# Title
		title = font.render("Dialogs", True, COLOR_TEXT)
		surface.blit(title, (self.rect.x + PADDING, self.rect.y + PADDING))
		
		# Search box
		self.search_input.draw(surface, font_small)
		
		# Dialog list
		list_y = self.rect.y + PADDING + INPUT_HEIGHT + PADDING + LINE_HEIGHT
		list_height = self.rect.height - (INPUT_HEIGHT + LINE_HEIGHT + 3 * PADDING)
		
		# Clip to list area
		clip_rect = pygame.Rect(self.rect.x, list_y, self.rect.width, list_height)
		surface.set_clip(clip_rect)
		
		y = list_y - self.scroll_offset
		
		for i, dialog in enumerate(self.filtered_dialogs):
			# Check if visible
			if y + self.item_height < list_y or y > list_y + list_height:
				y += self.item_height
				continue
			
			# Background for selected
			if i == self.selected_index:
				pygame.draw.rect(surface, COLOR_SELECTED,
					(self.rect.x + PADDING, y, self.rect.width - 2 * PADDING, self.item_height))
			
			# Dialog text
			preview = dialog.text[:40].replace('\n', ' ').replace('[NEWLINE]', ' ')
			if len(dialog.text) > 40:
				preview += "..."
			
			text = f"#{dialog.id:03d} {preview}"
			text_surf = font_small.render(text, True, COLOR_TEXT)
			surface.blit(text_surf, (self.rect.x + PADDING * 2, y + 2))
			
			y += self.item_height
		
		surface.set_clip(None)
		
		# Scrollbar
		if len(self.filtered_dialogs) * self.item_height > list_height:
			scrollbar_height = max(20, int(list_height * list_height / (len(self.filtered_dialogs) * self.item_height)))
			scrollbar_y = list_y + int(self.scroll_offset * list_height / (len(self.filtered_dialogs) * self.item_height))
			
			pygame.draw.rect(surface, COLOR_SCROLLBAR,
				(self.rect.x + self.rect.width - 8, scrollbar_y, 6, scrollbar_height), border_radius=3)


class DialogEditorPanel:
	"""Panel for editing dialog text"""
	
	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = UIRect(x, y, width, height)
		self.dialog: Optional[DialogEntry] = None
		self.dialog_text = DialogText()
		self.text_lines: List[str] = []
		self.cursor_line = 0
		self.cursor_col = 0
		self.scroll_offset = 0
		self.modified = False
		
		# Control code buttons
		self.control_buttons: List[Button] = []
		self._create_control_buttons()
	
	def _create_control_buttons(self):
		"""Create buttons for inserting control codes"""
		btn_width = 80
		btn_height = 26
		btn_spacing = 5
		
		codes = [
			(ControlCode.NEWLINE, "Newline"),
			(ControlCode.WAIT, "Wait"),
			(ControlCode.CLEAR, "Clear"),
			(ControlCode.NAME, "Name"),
			(ControlCode.ITEM, "Item"),
		]
		
		x = self.rect.x + PADDING
		y = self.rect.y + self.rect.height - btn_height - PADDING
		
		for code, label in codes:
			btn = Button(x, y, btn_width, btn_height, label,
				callback=lambda c=code: self._insert_control_code(c))
			self.control_buttons.append(btn)
			x += btn_width + btn_spacing
	
	def set_dialog(self, dialog: Optional[DialogEntry]):
		"""Set dialog to edit"""
		self.dialog = dialog
		self.modified = False
		
		if dialog:
			self.text_lines = dialog.text.split('\n')
		else:
			self.text_lines = []
		
		self.cursor_line = 0
		self.cursor_col = 0
		self.scroll_offset = 0
	
	def _insert_control_code(self, code: ControlCode):
		"""Insert control code at cursor"""
		if not self.dialog:
			return
		
		tag = CONTROL_NAMES.get(code, f'[{code:02X}]')
		
		if self.cursor_line < len(self.text_lines):
			line = self.text_lines[self.cursor_line]
			new_line = line[:self.cursor_col] + tag + line[self.cursor_col:]
			self.text_lines[self.cursor_line] = new_line
			self.cursor_col += len(tag)
			self.modified = True
	
	def get_text(self) -> str:
		"""Get current text"""
		return '\n'.join(self.text_lines)
	
	def handle_click(self, mouse_pos: Tuple[int, int]) -> bool:
		"""Handle click event"""
		# Check control buttons
		for btn in self.control_buttons:
			if btn.handle_click(mouse_pos):
				return True
		
		return False
	
	def handle_key(self, event: pygame.event.Event):
		"""Handle keyboard event"""
		if not self.dialog or event.type != pygame.KEYDOWN:
			return
		
		if event.key == pygame.K_BACKSPACE:
			if self.cursor_col > 0:
				line = self.text_lines[self.cursor_line]
				self.text_lines[self.cursor_line] = line[:self.cursor_col - 1] + line[self.cursor_col:]
				self.cursor_col -= 1
				self.modified = True
		elif event.key == pygame.K_RETURN:
			line = self.text_lines[self.cursor_line]
			self.text_lines[self.cursor_line] = line[:self.cursor_col]
			self.text_lines.insert(self.cursor_line + 1, line[self.cursor_col:])
			self.cursor_line += 1
			self.cursor_col = 0
			self.modified = True
		elif event.key == pygame.K_UP:
			self.cursor_line = max(0, self.cursor_line - 1)
		elif event.key == pygame.K_DOWN:
			self.cursor_line = min(len(self.text_lines) - 1, self.cursor_line + 1)
		elif event.unicode and event.unicode.isprintable():
			line = self.text_lines[self.cursor_line]
			self.text_lines[self.cursor_line] = line[:self.cursor_col] + event.unicode + line[self.cursor_col:]
			self.cursor_col += 1
			self.modified = True
	
	def update(self, dt: float, mouse_pos: Tuple[int, int]):
		"""Update hover states"""
		for btn in self.control_buttons:
			btn.update(mouse_pos)
	
	def draw(self, surface: pygame.Surface, font: pygame.font.Font, font_small: pygame.font.Font):
		"""Draw editor panel"""
		# Background
		pygame.draw.rect(surface, COLOR_PANEL_BG, self.rect.to_pygame())
		pygame.draw.rect(surface, COLOR_BORDER, self.rect.to_pygame(), width=1)
		
		if not self.dialog:
			# No dialog selected
			no_dialog = font.render("No dialog selected", True, COLOR_TEXT_DIM)
			no_dialog_rect = no_dialog.get_rect(center=(self.rect.x + self.rect.width // 2,
				self.rect.y + self.rect.height // 2))
			surface.blit(no_dialog, no_dialog_rect)
			return
		
		# Title
		title_text = f"Dialog #{self.dialog.id:03d}"
		if self.modified:
			title_text += " *"
		title = font.render(title_text, True, COLOR_TEXT)
		surface.blit(title, (self.rect.x + PADDING, self.rect.y + PADDING))
		
		# Text editor area
		editor_y = self.rect.y + PADDING + LINE_HEIGHT + PADDING
		editor_height = self.rect.height - (LINE_HEIGHT + 100 + 3 * PADDING)
		
		# Draw text lines
		clip_rect = pygame.Rect(self.rect.x + PADDING, editor_y,
			self.rect.width - 2 * PADDING, editor_height)
		surface.set_clip(clip_rect)
		
		y = editor_y - self.scroll_offset
		
		for i, line in enumerate(self.text_lines):
			# Highlight current line
			if i == self.cursor_line:
				pygame.draw.rect(surface, COLOR_INPUT_BG,
					(self.rect.x + PADDING, y, self.rect.width - 2 * PADDING, LINE_HEIGHT))
			
			# Render line
			text_surf = font_small.render(line if line else " ", True, COLOR_TEXT)
			surface.blit(text_surf, (self.rect.x + PADDING * 2, y + 2))
			
			y += LINE_HEIGHT
		
		surface.set_clip(None)
		
		# Metrics
		metrics = self.dialog_text.calculate_metrics(self.get_text())
		metrics_y = self.rect.y + self.rect.height - 70
		
		metrics_text = f"{metrics.byte_count}/512 bytes | {metrics.char_count} chars | ~{metrics.estimated_time:.1f}s"
		metrics_surf = font_small.render(metrics_text, True, COLOR_TEXT_DIM)
		surface.blit(metrics_surf, (self.rect.x + PADDING, metrics_y))
		
		# Warnings
		if metrics.warnings:
			warning_y = metrics_y + LINE_HEIGHT
			for warning in metrics.warnings[:2]:  # Show first 2 warnings
				warning_surf = font_small.render(f"⚠ {warning}", True, COLOR_WARNING)
				surface.blit(warning_surf, (self.rect.x + PADDING, warning_y))
				warning_y += LINE_HEIGHT - 4
		
		# Control buttons
		for btn in self.control_buttons:
			btn.draw(surface, font_small)


class DialogEditor:
	"""Main dialog editor application"""
	
	def __init__(self, width: int = 1400, height: int = 900):
		"""Initialize dialog editor"""
		pygame.init()
		
		self.width = width
		self.height = height
		self.screen = pygame.display.set_mode((width, height), pygame.RESIZABLE)
		pygame.display.set_caption("FFMQ Dialog Editor")
		
		self.clock = pygame.time.Clock()
		self.running = True
		
		# Fonts
		self.font = pygame.font.Font(None, 24)
		self.font_small = pygame.font.Font(None, 20)
		self.font_large = pygame.font.Font(None, 32)
		
		# UI Panels
		list_width = 350
		self.dialog_list = DialogListPanel(PANEL_MARGIN, PANEL_MARGIN,
			list_width, height - 2 * PANEL_MARGIN)
		
		self.dialog_editor = DialogEditorPanel(
			list_width + 2 * PANEL_MARGIN, PANEL_MARGIN,
			width - list_width - 3 * PANEL_MARGIN, height - 2 * PANEL_MARGIN)
		
		# Database
		self.database: Optional[DialogDatabase] = None
		
		# Buttons
		self.save_button = Button(width - 120, 10, 100, BUTTON_HEIGHT, "Save", self.save_rom)
	
	def load_rom(self, rom_path: Path) -> bool:
		"""Load ROM and extract dialogs"""
		self.database = DialogDatabase(rom_path)
		dialogs = self.database.extract_all_dialogs()
		
		if dialogs:
			self.dialog_list.set_dialogs(list(dialogs.values()))
			return True
		return False
	
	def save_rom(self):
		"""Save modified dialogs to ROM"""
		if not self.database:
			return
		
		# Apply current edits
		if self.dialog_editor.modified and self.dialog_editor.dialog:
			text = self.dialog_editor.get_text()
			self.database.update_dialog(self.dialog_editor.dialog.id, text)
		
		# Save ROM
		self.database.save_rom()
		self.dialog_editor.modified = False
	
	def handle_events(self):
		"""Handle pygame events"""
		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				self.running = False
			
			elif event.type == pygame.MOUSEBUTTONDOWN:
				mouse_pos = pygame.mouse.get_pos()
				
				if event.button == 1:  # Left click
					# Check dialog list
					selected = self.dialog_list.handle_click(mouse_pos)
					if selected:
						self.dialog_editor.set_dialog(selected)
					
					# Check editor
					self.dialog_editor.handle_click(mouse_pos)
					
					# Check buttons
					self.save_button.handle_click(mouse_pos)
				
				elif event.button == 4:  # Scroll up
					self.dialog_list.handle_scroll(10)
				elif event.button == 5:  # Scroll down
					self.dialog_list.handle_scroll(-10)
			
			elif event.type == pygame.KEYDOWN:
				self.dialog_list.handle_key(event)
				self.dialog_editor.handle_key(event)
	
	def update(self, dt: float):
		"""Update application state"""
		mouse_pos = pygame.mouse.get_pos()
		
		self.dialog_list.update(dt)
		self.dialog_editor.update(dt, mouse_pos)
		self.save_button.update(mouse_pos)
	
	def draw(self):
		"""Draw application"""
		self.screen.fill(COLOR_BG)
		
		# Draw panels
		self.dialog_list.draw(self.screen, self.font, self.font_small)
		self.dialog_editor.draw(self.screen, self.font, self.font_small)
		
		# Draw buttons
		self.save_button.draw(self.screen, self.font_small)
		
		pygame.display.flip()
	
	def run(self):
		"""Main application loop"""
		while self.running:
			dt = self.clock.tick(60) / 1000.0  # Delta time in seconds
			
			self.handle_events()
			self.update(dt)
			self.draw()
		
		pygame.quit()


# Main entry point
if __name__ == '__main__':
	import sys
	
	editor = DialogEditor()
	
	if len(sys.argv) > 1:
		rom_path = Path(sys.argv[1])
		if editor.load_rom(rom_path):
			print(f"Loaded ROM: {rom_path}")
		else:
			print(f"Failed to load ROM: {rom_path}")
	
	editor.run()
