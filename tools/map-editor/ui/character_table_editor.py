"""
Character Table Editor - Visual editor for FFMQ character table (.tbl file)

Allows editing single-character and multi-character sequence mappings.
Features:
- Visual list of all character table entries
- Add/edit/delete entries
- Auto-suggest multi-character sequences from dialog corpus
- Import/export character table files
- Validation and duplicate detection
"""

import pygame
import sys
from pathlib import Path
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent.parent))

from utils.dialog_text import CharacterTable
from utils.character_table_optimizer import CharacterTableOptimizer, CompressionCandidate


# Colors
COLOR_BG = (30, 30, 40)
COLOR_PANEL = (45, 45, 55)
COLOR_BORDER = (60, 60, 70)
COLOR_TEXT = (220, 220, 220)
COLOR_TEXT_DIM = (140, 140, 150)
COLOR_HIGHLIGHT = (70, 130, 180)
COLOR_SELECTED = (90, 150, 200)
COLOR_BUTTON = (60, 120, 160)
COLOR_BUTTON_HOVER = (80, 140, 180)
COLOR_SUCCESS = (80, 200, 120)
COLOR_WARNING = (255, 165, 0)
COLOR_ERROR = (220, 80, 80)
COLOR_MULTI_CHAR = (180, 130, 255)  # Purple for multi-char entries


@dataclass
class TableEntry:
	"""Represents a single character table entry"""
	byte_value: int
	sequence: str
	is_multi_char: bool
	is_control_code: bool = False
	
	def __repr__(self):
		ctrl = " [CTRL]" if self.is_control_code else ""
		multi = " [MULTI]" if self.is_multi_char else ""
		return f"0x{self.byte_value:02X} = '{self.sequence}'{ctrl}{multi}"


class Button:
	"""Simple button widget"""
	def __init__(self, rect: pygame.Rect, text: str, color=COLOR_BUTTON):
		self.rect = rect
		self.text = text
		self.color = color
		self.hover_color = COLOR_BUTTON_HOVER
		self.is_hovered = False
		self.enabled = True
	
	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		color = self.hover_color if self.is_hovered else self.color
		if not self.enabled:
			color = COLOR_BORDER
		
		pygame.draw.rect(surface, color, self.rect, border_radius=4)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 1, border_radius=4)
		
		text_color = COLOR_TEXT if self.enabled else COLOR_TEXT_DIM
		text_surf = font.render(self.text, True, text_color)
		text_rect = text_surf.get_rect(center=self.rect.center)
		surface.blit(text_surf, text_rect)
	
	def handle_event(self, event: pygame.event.Event) -> bool:
		if not self.enabled:
			return False
		
		if event.type == pygame.MOUSEMOTION:
			self.is_hovered = self.rect.collidepoint(event.pos)
		elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
			if self.rect.collidepoint(event.pos):
				return True
		return False


class TextInput:
	"""Text input widget"""
	def __init__(self, rect: pygame.Rect, placeholder: str = ""):
		self.rect = rect
		self.text = ""
		self.placeholder = placeholder
		self.active = False
		self.cursor_visible = True
		self.cursor_timer = 0
	
	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		# Background
		bg_color = COLOR_PANEL if self.active else COLOR_BG
		pygame.draw.rect(surface, bg_color, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER if not self.active else COLOR_HIGHLIGHT, 
		                 self.rect, 2)
		
		# Text or placeholder
		display_text = self.text if self.text else self.placeholder
		text_color = COLOR_TEXT if self.text else COLOR_TEXT_DIM
		
		text_surf = font.render(display_text, True, text_color)
		text_rect = text_surf.get_rect(midleft=(self.rect.x + 8, self.rect.centery))
		surface.blit(text_surf, text_rect)
		
		# Cursor
		if self.active and self.cursor_visible:
			cursor_x = text_rect.right + 2
			cursor_y1 = self.rect.y + 8
			cursor_y2 = self.rect.bottom - 8
			pygame.draw.line(surface, COLOR_TEXT, (cursor_x, cursor_y1), (cursor_x, cursor_y2), 2)
	
	def update(self, dt: float):
		if self.active:
			self.cursor_timer += dt
			if self.cursor_timer >= 0.5:
				self.cursor_visible = not self.cursor_visible
				self.cursor_timer = 0
	
	def handle_event(self, event: pygame.event.Event) -> bool:
		if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
			self.active = self.rect.collidepoint(event.pos)
			return self.active
		
		if self.active and event.type == pygame.KEYDOWN:
			if event.key == pygame.K_BACKSPACE:
				self.text = self.text[:-1]
			elif event.key == pygame.K_RETURN:
				self.active = False
				return True
			elif event.key == pygame.K_ESCAPE:
				self.active = False
			elif event.unicode and ord(event.unicode) >= 32:
				self.text += event.unicode
		
		return False


class CharacterTableEditor:
	"""Main character table editor application"""
	
	def __init__(self, table_path: str = None):
		pygame.init()
		
		self.width = 1200
		self.height = 800
		self.screen = pygame.display.set_mode((self.width, self.height))
		pygame.display.set_caption("FFMQ Character Table Editor")
		
		self.clock = pygame.time.Clock()
		self.running = True
		
		# Fonts
		self.font = pygame.font.Font(None, 24)
		self.font_small = pygame.font.Font(None, 20)
		self.font_large = pygame.font.Font(None, 28)
		
		# Load character table
		self.table_path = table_path or str(Path(__file__).parent.parent.parent / "complex.tbl")
		self.char_table = CharacterTable(self.table_path)
		self.entries: List[TableEntry] = []
		self._load_entries()
		
		# UI State
		self.selected_index: Optional[int] = None
		self.scroll_offset = 0
		self.max_scroll = 0
		
		# Editing
		self.edit_byte_input = TextInput(pygame.Rect(850, 150, 100, 35), "Hex (00-FF)")
		self.edit_seq_input = TextInput(pygame.Rect(850, 200, 300, 35), "Text sequence")
		
		# Buttons
		self.btn_add = Button(pygame.Rect(850, 250, 100, 35), "Add")
		self.btn_update = Button(pygame.Rect(960, 250, 100, 35), "Update")
		self.btn_delete = Button(pygame.Rect(1070, 250, 100, 35), "Delete")
		self.btn_save = Button(pygame.Rect(850, 300, 100, 35), "Save", COLOR_SUCCESS)
		self.btn_optimize = Button(pygame.Rect(960, 300, 210, 35), "Auto-Optimize", COLOR_WARNING)
		
		# Optimization results
		self.candidates: List[CompressionCandidate] = []
		self.show_candidates = False
		
		# Status message
		self.status_message = ""
		self.status_timer = 0
		self.status_color = COLOR_TEXT
	
	def _load_entries(self):
		"""Load entries from character table"""
		self.entries.clear()
		
		# Load single-char entries
		for byte_val, char in self.char_table.byte_to_char.items():
			is_control = byte_val <= 0x0F  # Control codes are typically 0x00-0x0F
			is_multi = len(char) > 1
			entry = TableEntry(byte_val, char, is_multi, is_control)
			self.entries.append(entry)
		
		# Load multi-char entries
		for seq, byte_val in self.char_table.multi_char_to_byte.items():
			# Skip if already added (shouldn't happen, but just in case)
			if any(e.byte_value == byte_val and e.sequence == seq for e in self.entries):
				continue
			entry = TableEntry(byte_val, seq, True, False)
			self.entries.append(entry)
		
		# Sort by byte value
		self.entries.sort(key=lambda e: e.byte_value)
		
		self.max_scroll = max(0, len(self.entries) * 30 - 600)
	
	def _save_entries(self):
		"""Save entries to character table file"""
		try:
			with open(self.table_path, 'w', encoding='utf-8') as f:
				for entry in sorted(self.entries, key=lambda e: e.byte_value):
					# Escape special characters
					seq = entry.sequence
					seq = seq.replace('\n', '{newline}')
					seq = seq.replace('\t', '{tab}')
					
					f.write(f"{entry.byte_value:02X}={seq}\n")
			
			# Reload table
			self.char_table = CharacterTable(self.table_path)
			self._load_entries()
			
			self._show_status("Character table saved successfully!", COLOR_SUCCESS)
			return True
			
		except Exception as e:
			self._show_status(f"Error saving: {e}", COLOR_ERROR)
			return False
	
	def _show_status(self, message: str, color=COLOR_TEXT):
		"""Show a status message"""
		self.status_message = message
		self.status_color = color
		self.status_timer = 3.0  # Show for 3 seconds
	
	def _add_entry(self):
		"""Add a new entry"""
		try:
			# Parse byte value
			byte_str = self.edit_byte_input.text.strip().upper()
			if byte_str.startswith('0X'):
				byte_str = byte_str[2:]
			byte_val = int(byte_str, 16)
			
			if byte_val < 0 or byte_val > 0xFF:
				self._show_status("Byte value must be 00-FF", COLOR_ERROR)
				return
			
			# Get sequence
			sequence = self.edit_seq_input.text
			if not sequence:
				self._show_status("Sequence cannot be empty", COLOR_ERROR)
				return
			
			# Check for duplicates
			if any(e.byte_value == byte_val for e in self.entries):
				self._show_status(f"Byte 0x{byte_val:02X} already exists", COLOR_ERROR)
				return
			
			# Add entry
			is_multi = len(sequence) > 1
			entry = TableEntry(byte_val, sequence, is_multi, False)
			self.entries.append(entry)
			self.entries.sort(key=lambda e: e.byte_value)
			
			# Clear inputs
			self.edit_byte_input.text = ""
			self.edit_seq_input.text = ""
			
			self._show_status(f"Added 0x{byte_val:02X} = '{sequence}'", COLOR_SUCCESS)
			
		except ValueError:
			self._show_status("Invalid byte value (use hex: 00-FF)", COLOR_ERROR)
	
	def _update_entry(self):
		"""Update selected entry"""
		if self.selected_index is None:
			self._show_status("No entry selected", COLOR_WARNING)
			return
		
		try:
			# Parse byte value
			byte_str = self.edit_byte_input.text.strip().upper()
			if byte_str.startswith('0X'):
				byte_str = byte_str[2:]
			byte_val = int(byte_str, 16)
			
			# Get sequence
			sequence = self.edit_seq_input.text
			if not sequence:
				self._show_status("Sequence cannot be empty", COLOR_ERROR)
				return
			
			# Update entry
			entry = self.entries[self.selected_index]
			entry.byte_value = byte_val
			entry.sequence = sequence
			entry.is_multi_char = len(sequence) > 1
			
			# Re-sort
			self.entries.sort(key=lambda e: e.byte_value)
			
			self._show_status(f"Updated to 0x{byte_val:02X} = '{sequence}'", COLOR_SUCCESS)
			
		except ValueError:
			self._show_status("Invalid byte value (use hex: 00-FF)", COLOR_ERROR)
	
	def _delete_entry(self):
		"""Delete selected entry"""
		if self.selected_index is None:
			self._show_status("No entry selected", COLOR_WARNING)
			return
		
		entry = self.entries[self.selected_index]
		self.entries.pop(self.selected_index)
		self.selected_index = None
		
		self._show_status(f"Deleted 0x{entry.byte_value:02X}", COLOR_SUCCESS)
	
	def _optimize_table(self):
		"""Run auto-optimization on character table"""
		# This would analyze all dialogs in the ROM and suggest optimal entries
		# For now, just show a demo
		self._show_status("Analyzing dialogs for optimization...", COLOR_WARNING)
		
		# TODO: Load actual dialogs from ROM
		sample_dialogs = [
			"Welcome to the world of Final Fantasy!",
			"The Crystal of Light awaits you.",
			"You must save the world from darkness.",
			"The prophecy speaks of a hero.",
		]
		
		optimizer = CharacterTableOptimizer(min_length=2, max_length=15)
		
		# Get existing sequences
		existing = {e.sequence for e in self.entries if e.is_multi_char}
		
		# Analyze
		self.candidates = optimizer.analyze_corpus(sample_dialogs, existing)
		self.show_candidates = True
		
		self._show_status(f"Found {len(self.candidates)} optimization candidates", COLOR_SUCCESS)
	
	def handle_events(self):
		"""Handle pygame events"""
		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				self.running = False
			
			# Handle text inputs
			self.edit_byte_input.handle_event(event)
			self.edit_seq_input.handle_event(event)
			
			# Handle buttons
			if self.btn_add.handle_event(event):
				self._add_entry()
			if self.btn_update.handle_event(event):
				self._update_entry()
			if self.btn_delete.handle_event(event):
				self._delete_entry()
			if self.btn_save.handle_event(event):
				self._save_entries()
			if self.btn_optimize.handle_event(event):
				self._optimize_table()
			
			# Handle entry list
			if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
				# Check if clicked in list area
				list_rect = pygame.Rect(20, 100, 800, 680)
				if list_rect.collidepoint(event.pos):
					# Calculate which entry was clicked
					y_offset = event.pos[1] - list_rect.y + self.scroll_offset
					index = y_offset // 30
					if 0 <= index < len(self.entries):
						self.selected_index = index
						entry = self.entries[index]
						self.edit_byte_input.text = f"{entry.byte_value:02X}"
						self.edit_seq_input.text = entry.sequence
			
			# Handle scrolling
			if event.type == pygame.MOUSEWHEEL:
				self.scroll_offset -= event.y * 30
				self.scroll_offset = max(0, min(self.scroll_offset, self.max_scroll))
	
	def update(self, dt: float):
		"""Update game state"""
		self.edit_byte_input.update(dt)
		self.edit_seq_input.update(dt)
		
		# Update status timer
		if self.status_timer > 0:
			self.status_timer -= dt
			if self.status_timer <= 0:
				self.status_message = ""
	
	def draw(self):
		"""Draw everything"""
		self.screen.fill(COLOR_BG)
		
		# Title
		title = self.font_large.render("Character Table Editor", True, COLOR_TEXT)
		self.screen.blit(title, (20, 20))
		
		# Table path
		path_text = self.font_small.render(f"File: {self.table_path}", True, COLOR_TEXT_DIM)
		self.screen.blit(path_text, (20, 55))
		
		# Entry count
		count_text = self.font_small.render(f"Entries: {len(self.entries)}", True, COLOR_TEXT_DIM)
		self.screen.blit(count_text, (20, 75))
		
		# Draw entry list
		self._draw_entry_list()
		
		# Draw editor panel
		self._draw_editor_panel()
		
		# Draw status
		if self.status_message:
			status_surf = self.font.render(self.status_message, True, self.status_color)
			self.screen.blit(status_surf, (20, self.height - 40))
		
		pygame.display.flip()
	
	def _draw_entry_list(self):
		"""Draw the list of character table entries"""
		# Background
		list_rect = pygame.Rect(20, 100, 800, 680)
		pygame.draw.rect(self.screen, COLOR_PANEL, list_rect)
		pygame.draw.rect(self.screen, COLOR_BORDER, list_rect, 1)
		
		# Create a surface for clipping
		list_surface = pygame.Surface((list_rect.width - 4, list_rect.height - 4))
		list_surface.fill(COLOR_PANEL)
		
		# Draw entries
		y = -self.scroll_offset
		for i, entry in enumerate(self.entries):
			if y + 30 < 0 or y > list_rect.height:
				y += 30
				continue
			
			# Background for selected
			if i == self.selected_index:
				entry_rect = pygame.Rect(0, y, list_rect.width - 4, 28)
				pygame.draw.rect(list_surface, COLOR_SELECTED, entry_rect)
			
			# Byte value
			byte_color = COLOR_WARNING if entry.is_control_code else COLOR_TEXT
			byte_text = self.font.render(f"0x{entry.byte_value:02X}", True, byte_color)
			list_surface.blit(byte_text, (10, y + 5))
			
			# Sequence
			seq_display = entry.sequence.replace('\n', '\\n').replace('\t', '\\t')
			if len(seq_display) > 40:
				seq_display = seq_display[:37] + "..."
			
			seq_color = COLOR_MULTI_CHAR if entry.is_multi_char else COLOR_TEXT
			seq_text = self.font.render(f"= \"{seq_display}\"", True, seq_color)
			list_surface.blit(seq_text, (120, y + 5))
			
			# Tags
			tag_x = 550
			if entry.is_control_code:
				tag = self.font_small.render("[CTRL]", True, COLOR_WARNING)
				list_surface.blit(tag, (tag_x, y + 7))
				tag_x += 70
			if entry.is_multi_char:
				tag = self.font_small.render("[MULTI]", True, COLOR_MULTI_CHAR)
				list_surface.blit(tag, (tag_x, y + 7))
			
			y += 30
		
		# Blit to main screen
		self.screen.blit(list_surface, (list_rect.x + 2, list_rect.y + 2))
		
		# Draw scrollbar
		if self.max_scroll > 0:
			scrollbar_height = max(20, 680 * 680 // (len(self.entries) * 30))
			scrollbar_y = 100 + (680 - scrollbar_height) * self.scroll_offset // self.max_scroll
			scrollbar_rect = pygame.Rect(818, scrollbar_y, 6, scrollbar_height)
			pygame.draw.rect(self.screen, COLOR_HIGHLIGHT, scrollbar_rect, border_radius=3)
	
	def _draw_editor_panel(self):
		"""Draw the editor panel"""
		# Title
		title = self.font.render("Edit Entry", True, COLOR_TEXT)
		self.screen.blit(title, (850, 100))
		
		# Labels
		label1 = self.font_small.render("Byte Value:", True, COLOR_TEXT_DIM)
		self.screen.blit(label1, (850, 130))
		
		label2 = self.font_small.render("Sequence:", True, COLOR_TEXT_DIM)
		self.screen.blit(label2, (850, 180))
		
		# Text inputs
		self.edit_byte_input.draw(self.screen, self.font)
		self.edit_seq_input.draw(self.screen, self.font)
		
		# Buttons
		self.btn_add.draw(self.screen, self.font)
		self.btn_update.draw(self.screen, self.font)
		self.btn_delete.draw(self.screen, self.font)
		self.btn_save.draw(self.screen, self.font)
		self.btn_optimize.draw(self.screen, self.font)
		
		# Help text
		help_y = 360
		help_texts = [
			"Click an entry to edit it",
			"Add: Create new entry",
			"Update: Modify selected entry",
			"Delete: Remove selected entry",
			"Save: Write changes to file",
			"",
			"Multi-char sequences (purple) are",
			"encoded as single bytes for",
			"better compression.",
		]
		
		for text in help_texts:
			help_surf = self.font_small.render(text, True, COLOR_TEXT_DIM)
			self.screen.blit(help_surf, (850, help_y))
			help_y += 22
	
	def run(self):
		"""Main game loop"""
		while self.running:
			dt = self.clock.tick(60) / 1000.0  # Delta time in seconds
			
			self.handle_events()
			self.update(dt)
			self.draw()
		
		pygame.quit()


def main():
	"""Entry point"""
	editor = CharacterTableEditor()
	editor.run()


if __name__ == '__main__':
	main()
