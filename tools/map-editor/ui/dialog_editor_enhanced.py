#!/usr/bin/env python3
"""
FFMQ Dialog Editor - Enhanced Features
Advanced features: syntax highlighting, autocomplete, visual scripting, FFMQ dialog preview
"""

import pygame
import re
from pathlib import Path
from typing import Optional, List, Tuple, Dict, Set
from dataclasses import dataclass, field
from enum import Enum
import sys

# Add utils directory to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'utils'))

from dialog_text import DialogText, DialogMetrics, ControlCode, CONTROL_NAMES, CONTROL_STRINGS
from dialog_database import DialogDatabase, DialogEntry
from event_script import EventScriptEngine, EventScript, CommandCategory


# Syntax highlighting colors
COLOR_CONTROL_CODE = (100, 180, 255)	# Blue for control codes like [WAIT]
COLOR_STRING_CONTENT = (220, 220, 220)	# White for regular text
COLOR_KEYWORD = (200, 100, 255)			# Purple for event script keywords
COLOR_NUMBER = (255, 180, 100)			# Orange for numbers
COLOR_COMMENT = (100, 150, 100)			# Green for comments
COLOR_ERROR = (255, 100, 100)			# Red for errors
COLOR_SPECIAL_CHAR = (255, 200, 100)	# Gold for special characters


class TokenType(Enum):
	"""Token types for syntax highlighting"""
	TEXT = 1
	CONTROL_CODE = 2
	COMMAND = 3
	NUMBER = 4
	COMMENT = 5
	ERROR = 6
	SPECIAL_CHAR = 7


@dataclass
class Token:
	"""Syntax token for highlighting"""
	type: TokenType
	text: str
	start: int
	end: int
	color: Tuple[int, int, int]


class SyntaxHighlighter:
	"""Syntax highlighter for FFMQ dialog text"""

	def __init__(self):
		"""Initialize syntax highlighter"""
		self.control_code_pattern = re.compile(r'\[([A-Z_]+)(?::([0-9A-F]{2}))?\]')
		self.special_chars = set('!?,.\'":-&')

	def tokenize(self, text: str) -> List[Token]:
		"""
		Tokenize text for syntax highlighting

		Args:
			text: Dialog text to tokenize

		Returns:
			List of tokens with type and color information
		"""
		tokens = []
		i = 0

		while i < len(text):
			# Check for control codes
			if text[i] == '[':
				match = self.control_code_pattern.match(text, i)
				if match:
					# Valid control code
					tokens.append(Token(
						type=TokenType.CONTROL_CODE,
						text=match.group(0),
						start=i,
						end=match.end(),
						color=COLOR_CONTROL_CODE
					))
					i = match.end()
					continue
				else:
					# Invalid/incomplete control code
					end = text.find(']', i)
					if end == -1:
						end = len(text)
					else:
						end += 1
					tokens.append(Token(
						type=TokenType.ERROR,
						text=text[i:end],
						start=i,
						end=end,
						color=COLOR_ERROR
					))
					i = end
					continue

			# Check for special characters
			if text[i] in self.special_chars:
				tokens.append(Token(
					type=TokenType.SPECIAL_CHAR,
					text=text[i],
					start=i,
					end=i + 1,
					color=COLOR_SPECIAL_CHAR
				))
				i += 1
				continue

			# Regular text - find next special character
			start = i
			while i < len(text) and text[i] not in ('[' + ''.join(self.special_chars)):
				i += 1

			if i > start:
				tokens.append(Token(
					type=TokenType.TEXT,
					text=text[start:i],
					start=start,
					end=i,
					color=COLOR_STRING_CONTENT
				))

		return tokens


class AutocompleteEngine:
	"""Autocomplete suggestions for dialog editing"""

	def __init__(self):
		"""Initialize autocomplete engine"""
		self.control_codes = list(CONTROL_NAMES.values())
		self.common_words = [
			"the ", "you", "that ", "with ", "have ", "from ", "will ",
			"your ", "here ", "there ", "what ", "when ", "where ",
			"Crystal", "Rainbow Road", "again", "monster", "prophecy"
		]
		self.event_commands = [
			"IF", "ELSE", "ENDIF", "GOTO", "LABEL", "CALL", "RETURN",
			"SET_FLAG", "CHECK_FLAG", "GIVE_ITEM", "CHECK_ITEM",
			"SHOW_DIALOG", "CLOSE_DIALOG", "WAIT", "SOUND_EFFECT"
		]

	def get_suggestions(self, text: str, cursor_pos: int) -> List[Tuple[str, str]]:
		"""
		Get autocomplete suggestions at cursor position

		Args:
			text: Current text
			cursor_pos: Cursor position in text

		Returns:
			List of (suggestion, description) tuples
		"""
		suggestions = []

		# Check if we're in a control code
		if cursor_pos > 0 and text[cursor_pos - 1:cursor_pos + 1].find('[') != -1:
			# Suggest control codes
			prefix = ""
			start = text.rfind('[', 0, cursor_pos)
			if start != -1:
				prefix = text[start + 1:cursor_pos].upper()

			for code in self.control_codes:
				code_name = code.strip('[]')
				if code_name.startswith(prefix):
					suggestions.append((code_name + ']', "Control code"))

		# Check if we're starting a word
		elif cursor_pos == 0 or text[cursor_pos - 1] in ' \n':
			# Get word before cursor
			word_start = cursor_pos
			while word_start > 0 and text[word_start - 1] not in ' \n[]':
				word_start -= 1

			prefix = text[word_start:cursor_pos].lower()

			# Suggest common words
			for word in self.common_words:
				if word.lower().startswith(prefix):
					suggestions.append((word, "Common phrase"))

		return suggestions[:10]  # Limit to 10 suggestions


class VisualScriptFlowchart:
	"""Visual flowchart for event scripts"""

	@dataclass
	class Node:
		"""Flowchart node"""
		id: int
		type: str		# 'command', 'branch', 'label', 'end'
		text: str
		x: int = 0
		y: int = 0
		width: int = 120
		height: int = 40
		children: List[int] = field(default_factory=list)
		parent: Optional[int] = None

	def __init__(self, width: int, height: int):
		"""Initialize flowchart"""
		self.width = width
		self.height = height
		self.nodes: Dict[int, VisualScriptFlowchart.Node] = {}
		self.next_id = 0

	def build_from_script(self, script: EventScript):
		"""
		Build flowchart from event script

		Args:
			script: EventScript to visualize
		"""
		self.nodes.clear()
		self.next_id = 0

		# Parse script commands
		current_node = None
		branch_stack = []

		for cmd in script.commands:
			# Create node for command
			node = self.Node(
				id=self.next_id,
				type='command',
				text=cmd.name
			)
			self.next_id += 1

			# Handle branching
			if cmd.name in ['IF', 'CHECK_FLAG', 'CHECK_ITEM']:
				node.type = 'branch'
				branch_stack.append(node.id)
			elif cmd.name in ['ELSE', 'ENDIF']:
				if branch_stack:
					parent_id = branch_stack[-1]
					node.parent = parent_id
					self.nodes[parent_id].children.append(node.id)
					if cmd.name == 'ENDIF':
						branch_stack.pop()
			elif cmd.name == 'LABEL':
				node.type = 'label'
			elif cmd.name == 'END_SCRIPT':
				node.type = 'end'

			self.nodes[node.id] = node

			# Link to previous node
			if current_node is not None:
				current_node.children.append(node.id)
				node.parent = current_node.id

			current_node = node

		# Layout nodes
		self._layout_nodes()

	def _layout_nodes(self):
		"""Layout nodes in flowchart"""
		if not self.nodes:
			return

		# Simple top-to-bottom layout
		y = 20
		x_center = self.width // 2

		for node in self.nodes.values():
			node.x = x_center - node.width // 2
			node.y = y
			y += node.height + 30

			# Indent branches
			if node.type == 'branch':
				y += 20

	def draw(self, surface: pygame.Surface, font: pygame.font.Font, scroll_y: int = 0):
		"""
		Draw flowchart

		Args:
			surface: Surface to draw on
			font: Font for text
			scroll_y: Vertical scroll offset
		"""
		# Draw connections first
		for node in self.nodes.values():
			for child_id in node.children:
				child = self.nodes[child_id]

				# Draw line from node to child
				start_x = node.x + node.width // 2
				start_y = node.y + node.height - scroll_y
				end_x = child.x + child.width // 2
				end_y = child.y - scroll_y

				pygame.draw.line(surface, (100, 100, 100), (start_x, start_y), (end_x, end_y), 2)

				# Draw arrow
				arrow_size = 8
				pygame.draw.polygon(surface, (100, 100, 100), [
					(end_x, end_y),
					(end_x - arrow_size, end_y - arrow_size),
					(end_x + arrow_size, end_y - arrow_size)
				])

		# Draw nodes
		for node in self.nodes.values():
			y = node.y - scroll_y

			# Skip if offscreen
			if y + node.height < 0 or y > surface.get_height():
				continue

			# Choose color based on node type
			if node.type == 'branch':
				bg_color = (100, 150, 200)
			elif node.type == 'label':
				bg_color = (200, 150, 100)
			elif node.type == 'end':
				bg_color = (200, 100, 100)
			else:
				bg_color = (80, 120, 180)

			# Draw node box
			rect = (node.x, y, node.width, node.height)
			pygame.draw.rect(surface, bg_color, rect, border_radius=5)
			pygame.draw.rect(surface, (200, 200, 200), rect, width=2, border_radius=5)

			# Draw text
			text_surf = font.render(node.text, True, (255, 255, 255))
			text_rect = text_surf.get_rect(center=(node.x + node.width // 2, y + node.height // 2))
			surface.blit(text_surf, text_rect)


class FFMQDialogPreview:
	"""Preview dialog with FFMQ-style dialog box"""

	def __init__(self, x: int, y: int, width: int = 480, height: int = 160):
		"""Initialize dialog preview"""
		self.x = x
		self.y = y
		self.width = width
		self.height = height
		self.text = ""
		self.displayed_text = ""
		self.char_index = 0
		self.text_speed = 0.05  # seconds per character
		self.timer = 0
		self.paused = False
		self.lines: List[str] = []
		self.max_lines = 4
		self.chars_per_line = 32

	def set_text(self, text: str):
		"""
		Set text to display

		Args:
			text: Dialog text with control codes
		"""
		self.text = text
		self.displayed_text = ""
		self.char_index = 0
		self.timer = 0
		self.paused = False
		self._process_text()

	def _process_text(self):
		"""Process text and handle control codes"""
		# Split into lines
		self.lines = []
		current_line = ""

		i = 0
		while i < len(self.text):
			# Check for control codes
			if self.text[i] == '[':
				end = self.text.find(']', i)
				if end != -1:
					code = self.text[i:end + 1]
					# Handle control codes
					if code == '[NEWLINE]' or self.text[i] == '\n':
						self.lines.append(current_line)
						current_line = ""
					# Skip other control codes for display
					i = end + 1
					continue

			# Handle newline
			if self.text[i] == '\n':
				self.lines.append(current_line)
				current_line = ""
				i += 1
				continue

			# Add character
			current_line += self.text[i]

			# Auto-wrap at line limit
			if len(current_line) >= self.chars_per_line:
				self.lines.append(current_line)
				current_line = ""

			i += 1

		if current_line:
			self.lines.append(current_line)

	def update(self, dt: float):
		"""
		Update text animation

		Args:
			dt: Delta time in seconds
		"""
		if self.paused or self.char_index >= len(self.displayed_text):
			return

		self.timer += dt
		if self.timer >= self.text_speed:
			# Add next character
			if self.char_index < len(self.text):
				# Skip control codes in display
				while self.char_index < len(self.text):
					if self.text[self.char_index] == '[':
						end = self.text.find(']', self.char_index)
						if end != -1:
							code = self.text[self.char_index:end + 1]
							if code == '[WAIT]':
								self.paused = True
							self.char_index = end + 1
							continue

					self.displayed_text += self.text[self.char_index]
					self.char_index += 1
					break

			self.timer = 0

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""
		Draw FFMQ-style dialog box

		Args:
			surface: Surface to draw on
			font: Font for text
		"""
		# Draw outer box (dark blue)
		outer_rect = (self.x, self.y, self.width, self.height)
		pygame.draw.rect(surface, (20, 30, 60), outer_rect, border_radius=8)

		# Draw border (white)
		pygame.draw.rect(surface, (220, 220, 220), outer_rect, width=4, border_radius=8)

		# Draw inner box (darker blue)
		inner_rect = (self.x + 12, self.y + 12, self.width - 24, self.height - 24)
		pygame.draw.rect(surface, (10, 20, 50), inner_rect)

		# Draw text
		line_y = self.y + 20
		displayed_lines = self.displayed_text.split('\n')

		for i, line in enumerate(displayed_lines[-self.max_lines:]):
			text_surf = font.render(line, True, (255, 255, 255))
			surface.blit(text_surf, (self.x + 20, line_y))
			line_y += 32

		# Draw continue indicator if paused
		if self.paused:
			# Blinking triangle
			indicator_x = self.x + self.width - 30
			indicator_y = self.y + self.height - 25
			pygame.draw.polygon(surface, (255, 255, 255), [
				(indicator_x, indicator_y),
				(indicator_x + 15, indicator_y + 7),
				(indicator_x, indicator_y + 14)
			])


class EnhancedTextEditor:
	"""Enhanced text editor with syntax highlighting and autocomplete"""

	def __init__(self, x: int, y: int, width: int, height: int):
		"""Initialize enhanced text editor"""
		self.x = x
		self.y = y
		self.width = width
		self.height = height
		self.text = ""
		self.cursor_pos = 0
		self.scroll_y = 0
		self.focused = False

		self.highlighter = SyntaxHighlighter()
		self.autocomplete = AutocompleteEngine()

		self.show_autocomplete = False
		self.autocomplete_suggestions: List[Tuple[str, str]] = []
		self.autocomplete_index = 0

		self.line_height = 24
		self.char_width = 10  # Approximate monospace width

	def handle_click(self, mouse_pos: Tuple[int, int]) -> bool:
		"""Handle mouse click"""
		if (self.x <= mouse_pos[0] <= self.x + self.width and
			self.y <= mouse_pos[1] <= self.y + self.height):
			self.focused = True
			# Calculate cursor position from mouse
			self._update_cursor_from_mouse(mouse_pos)
			return True
		else:
			self.focused = False
			self.show_autocomplete = False
			return False

	def _update_cursor_from_mouse(self, mouse_pos: Tuple[int, int]):
		"""Update cursor position from mouse click"""
		rel_y = mouse_pos[1] - self.y + self.scroll_y
		line_num = int(rel_y / self.line_height)

		lines = self.text.split('\n')
		if line_num >= len(lines):
			line_num = len(lines) - 1

		if line_num < 0:
			self.cursor_pos = 0
			return

		# Find position in text
		pos = sum(len(line) + 1 for line in lines[:line_num])

		# Add position within line
		rel_x = mouse_pos[0] - self.x
		char_offset = int(rel_x / self.char_width)
		char_offset = min(char_offset, len(lines[line_num]))

		self.cursor_pos = pos + char_offset

	def handle_key(self, event: pygame.event.Event):
		"""Handle keyboard input"""
		if not self.focused:
			return

		if event.type == pygame.KEYDOWN:
			# Autocomplete navigation
			if self.show_autocomplete:
				if event.key == pygame.K_DOWN:
					self.autocomplete_index = (self.autocomplete_index + 1) % len(self.autocomplete_suggestions)
					return
				elif event.key == pygame.K_UP:
					self.autocomplete_index = (self.autocomplete_index - 1) % len(self.autocomplete_suggestions)
					return
				elif event.key == pygame.K_RETURN or event.key == pygame.K_TAB:
					# Accept suggestion
					if self.autocomplete_suggestions:
						suggestion = self.autocomplete_suggestions[self.autocomplete_index][0]
						self._insert_text(suggestion)
						self.show_autocomplete = False
					return
				elif event.key == pygame.K_ESCAPE:
					self.show_autocomplete = False
					return

			# Regular editing
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
			elif event.key == pygame.K_UP:
				self._move_cursor_up()
			elif event.key == pygame.K_DOWN:
				self._move_cursor_down()
			elif event.key == pygame.K_HOME:
				self._move_cursor_line_start()
			elif event.key == pygame.K_END:
				self._move_cursor_line_end()
			elif event.key == pygame.K_RETURN:
				self._insert_text('\n')
			elif event.key == pygame.K_TAB:
				# Trigger autocomplete
				self._update_autocomplete()
				self.show_autocomplete = True
			elif event.unicode:
				self._insert_text(event.unicode)

	def _insert_text(self, text: str):
		"""Insert text at cursor position"""
		self.text = self.text[:self.cursor_pos] + text + self.text[self.cursor_pos:]
		self.cursor_pos += len(text)

		# Update autocomplete
		if text not in '\n\r\t':
			self._update_autocomplete()

	def _update_autocomplete(self):
		"""Update autocomplete suggestions"""
		self.autocomplete_suggestions = self.autocomplete.get_suggestions(self.text, self.cursor_pos)
		self.autocomplete_index = 0
		self.show_autocomplete = len(self.autocomplete_suggestions) > 0

	def _move_cursor_up(self):
		"""Move cursor up one line"""
		lines = self.text.split('\n')
		pos = 0
		line_num = 0
		col = 0

		for i, line in enumerate(lines):
			if pos + len(line) + 1 > self.cursor_pos:
				line_num = i
				col = self.cursor_pos - pos
				break
			pos += len(line) + 1

		if line_num > 0:
			target_line = lines[line_num - 1]
			col = min(col, len(target_line))
			self.cursor_pos = sum(len(l) + 1 for l in lines[:line_num - 1]) + col

	def _move_cursor_down(self):
		"""Move cursor down one line"""
		lines = self.text.split('\n')
		pos = 0
		line_num = 0
		col = 0

		for i, line in enumerate(lines):
			if pos + len(line) + 1 > self.cursor_pos:
				line_num = i
				col = self.cursor_pos - pos
				break
			pos += len(line) + 1

		if line_num < len(lines) - 1:
			target_line = lines[line_num + 1]
			col = min(col, len(target_line))
			self.cursor_pos = sum(len(l) + 1 for l in lines[:line_num + 1]) + col

	def _move_cursor_line_start(self):
		"""Move cursor to start of line"""
		lines = self.text.split('\n')
		pos = 0

		for line in lines:
			if pos + len(line) + 1 > self.cursor_pos:
				self.cursor_pos = pos
				return
			pos += len(line) + 1

	def _move_cursor_line_end(self):
		"""Move cursor to end of line"""
		lines = self.text.split('\n')
		pos = 0

		for line in lines:
			if pos + len(line) + 1 > self.cursor_pos:
				self.cursor_pos = pos + len(line)
				return
			pos += len(line) + 1

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw enhanced text editor"""
		# Background
		bg_rect = (self.x, self.y, self.width, self.height)
		pygame.draw.rect(surface, (35, 35, 40), bg_rect)
		pygame.draw.rect(surface, (80, 80, 85), bg_rect, width=1)

		# Set clip rect
		surface.set_clip(bg_rect)

		# Draw syntax highlighted text
		tokens = self.highlighter.tokenize(self.text)
		y = self.y + 5 - self.scroll_y
		x = self.x + 5
		line_start_x = x

		for token in tokens:
			# Handle newlines
			if '\n' in token.text:
				parts = token.text.split('\n')
				for i, part in enumerate(parts):
					if part:
						text_surf = font.render(part, True, token.color)
						surface.blit(text_surf, (x, y))
						x += text_surf.get_width()
					if i < len(parts) - 1:
						y += self.line_height
						x = line_start_x
			else:
				text_surf = font.render(token.text, True, token.color)
				surface.blit(text_surf, (x, y))
				x += text_surf.get_width()

		# Draw cursor
		if self.focused:
			cursor_x, cursor_y = self._get_cursor_position()
			pygame.draw.line(surface, (255, 255, 255),
				(cursor_x, cursor_y),
				(cursor_x, cursor_y + self.line_height - 2), 2)

		surface.set_clip(None)

		# Draw autocomplete popup
		if self.show_autocomplete and self.autocomplete_suggestions:
			self._draw_autocomplete(surface, font)

	def _get_cursor_position(self) -> Tuple[int, int]:
		"""Get cursor screen position"""
		# Count characters before cursor on each line
		text_before = self.text[:self.cursor_pos]
		lines = text_before.split('\n')

		line_num = len(lines) - 1
		col = len(lines[-1])

		x = self.x + 5 + col * self.char_width
		y = self.y + 5 + line_num * self.line_height - self.scroll_y

		return (x, y)

	def _draw_autocomplete(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw autocomplete popup"""
		cursor_x, cursor_y = self._get_cursor_position()

		# Calculate popup size
		popup_width = 300
		popup_height = min(len(self.autocomplete_suggestions) * 30 + 10, 200)

		# Position below cursor
		popup_x = cursor_x
		popup_y = cursor_y + self.line_height + 5

		# Adjust if off screen
		if popup_x + popup_width > surface.get_width():
			popup_x = surface.get_width() - popup_width - 10
		if popup_y + popup_height > surface.get_height():
			popup_y = cursor_y - popup_height - 5

		# Draw popup background
		popup_rect = (popup_x, popup_y, popup_width, popup_height)
		pygame.draw.rect(surface, (50, 50, 55), popup_rect, border_radius=5)
		pygame.draw.rect(surface, (100, 130, 180), popup_rect, width=2, border_radius=5)

		# Draw suggestions
		y = popup_y + 5
		for i, (suggestion, description) in enumerate(self.autocomplete_suggestions):
			# Highlight selected
			if i == self.autocomplete_index:
				highlight_rect = (popup_x + 2, y - 2, popup_width - 4, 26)
				pygame.draw.rect(surface, (70, 130, 180), highlight_rect, border_radius=3)

			# Draw suggestion text
			text_surf = font.render(suggestion, True, (220, 220, 220))
			surface.blit(text_surf, (popup_x + 5, y))

			# Draw description
			desc_surf = font.render(description, True, (140, 140, 140))
			surface.blit(desc_surf, (popup_x + 150, y))

			y += 30
			if y > popup_y + popup_height - 10:
				break


# Export all enhanced components
__all__ = [
	'SyntaxHighlighter',
	'AutocompleteEngine',
	'VisualScriptFlowchart',
	'FFMQDialogPreview',
	'EnhancedTextEditor',
	'TokenType',
	'Token'
]
