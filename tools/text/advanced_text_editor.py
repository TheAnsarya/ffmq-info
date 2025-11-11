#!/usr/bin/env python3
"""
Advanced Text/Dialog Editor

Comprehensive text editing system for SNES games with rich formatting.
Features include:
- Visual text editor with live preview
- Rich text formatting (color, speed, effects, icons)
- Text variables and dynamic content
- Dialog trees with branching choices
- Speaker portraits and animations
- Text effects (shake, wave, rainbow, typewriter)
- Multiple languages/localization
- Text compression analysis
- Special character support (symbols, icons, emoji)
- Export to multiple formats (JSON, binary, table files)

Text Formatting Codes:
- Color: <c:red>, <c:blue>, <c:yellow>, etc.
- Speed: <s:fast>, <s:slow>, <s:instant>
- Wait: <w:30> (wait N frames)
- Effect: <e:shake>, <e:wave>, <e:rainbow>
- Variables: {player_name}, {gold}, {item}
- Icons: <i:heart>, <i:sword>, <i:potion>
- Clear: <clear> (clear text box)
- Newline: \n or <br>
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple, Any
import pygame
import json
import re


class TextColor(Enum):
	"""Predefined text colors"""
	WHITE = (255, 255, 255)
	BLACK = (0, 0, 0)
	RED = (255, 100, 100)
	BLUE = (100, 150, 255)
	GREEN = (100, 255, 100)
	YELLOW = (255, 255, 100)
	CYAN = (100, 255, 255)
	MAGENTA = (255, 100, 255)
	ORANGE = (255, 180, 100)
	PURPLE = (200, 100, 255)


class TextSpeed(Enum):
	"""Text scroll speed"""
	INSTANT = 0
	FAST = 1
	NORMAL = 2
	SLOW = 4


class TextEffect(Enum):
	"""Text visual effects"""
	NONE = "none"
	SHAKE = "shake"
	WAVE = "wave"
	RAINBOW = "rainbow"
	BOUNCE = "bounce"
	FADE = "fade"


@dataclass
class TextSegment:
	"""Formatted text segment"""
	text: str
	color: Tuple[int, int, int] = (255, 255, 255)
	speed: int = 2
	effect: TextEffect = TextEffect.NONE
	wait_frames: int = 0
	icon: Optional[str] = None

	def apply_effect(self, char_index: int, frame: int) -> Tuple[int, int, Tuple[int, int, int]]:
		"""Apply visual effect to character"""
		x_offset = 0
		y_offset = 0
		color = self.color

		if self.effect == TextEffect.SHAKE:
			import random
			x_offset = random.randint(-2, 2)
			y_offset = random.randint(-2, 2)

		elif self.effect == TextEffect.WAVE:
			import math
			y_offset = int(math.sin(char_index * 0.5 + frame * 0.1) * 3)

		elif self.effect == TextEffect.RAINBOW:
			# Cycle through colors
			hue = (char_index * 30 + frame * 2) % 360
			color = self._hsv_to_rgb(hue, 1.0, 1.0)

		elif self.effect == TextEffect.BOUNCE:
			import math
			offset_time = char_index * 0.2 + frame * 0.15
			y_offset = int(abs(math.sin(offset_time)) * -5)

		elif self.effect == TextEffect.FADE:
			# Fade in based on frame
			alpha = min(255, frame * 5)
			color = tuple(int(c * alpha / 255) for c in self.color)

		return x_offset, y_offset, color

	@staticmethod
	def _hsv_to_rgb(h: float, s: float, v: float) -> Tuple[int, int, int]:
		"""Convert HSV to RGB"""
		import colorsys
		r, g, b = colorsys.hsv_to_rgb(h / 360, s, v)
		return (int(r * 255), int(g * 255), int(b * 255))


@dataclass
class DialogChoice:
	"""Dialog choice option"""
	text: str
	target_dialog: Optional[int] = None
	condition: Optional[str] = None
	result: Optional[str] = None


@dataclass
class DialogEntry:
	"""Single dialog/text entry"""
	dialog_id: int
	speaker: str
	portrait: Optional[str] = None
	text: str = ""
	segments: List[TextSegment] = field(default_factory=list)
	choices: List[DialogChoice] = field(default_factory=list)
	next_dialog: Optional[int] = None
	auto_advance: bool = False

	def parse_text(self):
		"""Parse formatted text into segments"""
		self.segments = []

		# Current state
		current_color = TextColor.WHITE.value
		current_speed = TextSpeed.NORMAL.value
		current_effect = TextEffect.NONE

		# Pattern for formatting codes
		pattern = r'<([^>]+)>|\{([^}]+)\}|([^<{]+)'

		pos = 0
		text_buffer = ""

		for match in re.finditer(pattern, self.text):
			tag = match.group(1)
			var = match.group(2)
			text = match.group(3)

			if tag:
				# Save current text buffer
				if text_buffer:
					self.segments.append(TextSegment(
						text=text_buffer,
						color=current_color,
						speed=current_speed,
						effect=current_effect
					))
					text_buffer = ""

				# Process tag
				if tag.startswith('c:'):
					# Color tag
					color_name = tag[2:].upper()
					if hasattr(TextColor, color_name):
						current_color = getattr(TextColor, color_name).value

				elif tag.startswith('s:'):
					# Speed tag
					speed_name = tag[2:].upper()
					if hasattr(TextSpeed, speed_name):
						current_speed = getattr(TextSpeed, speed_name).value

				elif tag.startswith('e:'):
					# Effect tag
					effect_name = tag[2:].upper()
					if hasattr(TextEffect, effect_name):
						current_effect = getattr(TextEffect, effect_name)

				elif tag.startswith('w:'):
					# Wait tag
					wait_frames = int(tag[2:])
					self.segments.append(TextSegment(
						text="",
						wait_frames=wait_frames
					))

				elif tag.startswith('i:'):
					# Icon tag
					icon_name = tag[2:]
					self.segments.append(TextSegment(
						text="",
						icon=icon_name
					))

				elif tag == 'clear':
					# Clear screen
					self.segments.append(TextSegment(text="\x01CLEAR\x01"))

				elif tag == 'br':
					# Line break
					text_buffer += '\n'

			elif var:
				# Variable substitution
				text_buffer += f"{{{var}}}"

			elif text:
				# Regular text
				text_buffer += text

		# Add remaining text
		if text_buffer:
			self.segments.append(TextSegment(
				text=text_buffer,
				color=current_color,
				speed=current_speed,
				effect=current_effect
			))

	def to_dict(self) -> dict:
		"""Convert to dictionary"""
		return {
			"dialog_id": self.dialog_id,
			"speaker": self.speaker,
			"portrait": self.portrait,
			"text": self.text,
			"choices": [
				{
					"text": c.text,
					"target_dialog": c.target_dialog,
					"condition": c.condition,
					"result": c.result,
				}
				for c in self.choices
			],
			"next_dialog": self.next_dialog,
			"auto_advance": self.auto_advance,
		}

	@staticmethod
	def from_dict(data: dict) -> 'DialogEntry':
		"""Create from dictionary"""
		choices = [
			DialogChoice(
				text=c["text"],
				target_dialog=c.get("target_dialog"),
				condition=c.get("condition"),
				result=c.get("result"),
			)
			for c in data.get("choices", [])
		]

		entry = DialogEntry(
			dialog_id=data["dialog_id"],
			speaker=data["speaker"],
			portrait=data.get("portrait"),
			text=data["text"],
			choices=choices,
			next_dialog=data.get("next_dialog"),
			auto_advance=data.get("auto_advance", False),
		)
		entry.parse_text()
		return entry


@dataclass
class TextProject:
	"""Complete text/dialog project"""
	name: str
	dialogs: Dict[int, DialogEntry] = field(default_factory=dict)
	variables: Dict[str, str] = field(default_factory=dict)
	languages: Dict[str, Dict[int, str]] = field(default_factory=dict)
	current_language: str = "en"

	def add_dialog(self, dialog: DialogEntry):
		"""Add dialog entry"""
		self.dialogs[dialog.dialog_id] = dialog

	def get_dialog(self, dialog_id: int) -> Optional[DialogEntry]:
		"""Get dialog by ID"""
		return self.dialogs.get(dialog_id)

	def export_json(self, filename: str):
		"""Export to JSON"""
		data = {
			"name": self.name,
			"dialogs": {k: v.to_dict() for k, v in self.dialogs.items()},
			"variables": self.variables,
			"languages": self.languages,
		}

		with open(filename, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent=2, ensure_ascii=False)

	@staticmethod
	def from_json(filename: str) -> 'TextProject':
		"""Load from JSON"""
		with open(filename, 'r', encoding='utf-8') as f:
			data = json.load(f)

		project = TextProject(name=data["name"])
		project.variables = data.get("variables", {})
		project.languages = data.get("languages", {})

		for dialog_data in data.get("dialogs", {}).values():
			dialog = DialogEntry.from_dict(dialog_data)
			project.add_dialog(dialog)

		return project


class TextRenderer:
	"""Render formatted text with effects"""

	def __init__(self, font: pygame.font.Font):
		self.font = font
		self.char_width = 8
		self.char_height = 16
		self.frame = 0

	def render_text(
		self,
		surface: pygame.Surface,
		dialog: DialogEntry,
		x: int,
		y: int,
		max_width: int,
		max_chars: Optional[int] = None
	):
		"""Render dialog text with formatting"""
		current_x = x
		current_y = y
		char_count = 0

		for segment in dialog.segments:
			# Handle special segments
			if segment.text.startswith("\x01CLEAR\x01"):
				current_x = x
				current_y = y
				continue

			if segment.icon:
				# Render icon placeholder
				pygame.draw.rect(surface, (100, 100, 200),
								 (current_x, current_y, 16, 16))
				pygame.draw.rect(surface, (255, 255, 255),
								 (current_x, current_y, 16, 16), 1)
				icon_text = self.font.render(segment.icon[0].upper(),
											 True, (255, 255, 255))
				surface.blit(icon_text, (current_x + 4, current_y + 2))
				current_x += 18
				continue

			# Render text characters
			for i, char in enumerate(segment.text):
				if max_chars is not None and char_count >= max_chars:
					return

				if char == '\n':
					current_x = x
					current_y += self.char_height + 4
					continue

				# Apply effect
				x_off, y_off, color = segment.apply_effect(i, self.frame)

				# Render character
				char_surf = self.font.render(char, True, color)
				surface.blit(char_surf,
							 (current_x + x_off, current_y + y_off))

				current_x += self.char_width
				char_count += 1

				# Word wrap
				if current_x > x + max_width - self.char_width:
					current_x = x
					current_y += self.char_height + 4

		self.frame += 1

	def reset_frame(self):
		"""Reset animation frame counter"""
		self.frame = 0


class AdvancedTextEditor:
	"""Main text editor with UI"""

	def __init__(self, width: int = 1400, height: int = 900):
		self.width = width
		self.height = height
		self.running = True

		pygame.init()
		self.screen = pygame.display.set_mode((width, height))
		pygame.display.set_caption("Advanced Text Editor")
		self.clock = pygame.time.Clock()

		self.font = pygame.font.Font(None, 24)
		self.small_font = pygame.font.Font(None, 18)
		self.mono_font = pygame.font.Font(None, 16)

		# Project data
		self.project = TextProject(name="New Project")
		self.current_dialog: Optional[DialogEntry] = None
		self.text_renderer = TextRenderer(self.mono_font)

		# UI state
		self.editing_text = False
		self.text_input = ""
		self.cursor_pos = 0
		self.show_preview = True
		self.show_code_help = True
		self.preview_chars = None  # None = show all

		# Dialog list
		self.dialog_scroll = 0
		self.selected_dialog_id: Optional[int] = None

		# Create sample dialogs
		self._create_sample_dialogs()

	def _create_sample_dialogs(self):
		"""Create sample dialog entries"""
		# Simple greeting
		dialog1 = DialogEntry(
			dialog_id=1,
			speaker="Village Elder",
			portrait="elder",
			text="Welcome to our village, <c:yellow>{player_name}</c:yellow>!"
		)
		dialog1.parse_text()
		self.project.add_dialog(dialog1)

		# Formatted text with effects
		dialog2 = DialogEntry(
			dialog_id=2,
			speaker="Wizard",
			portrait="wizard",
			text="Behold! <e:rainbow>Magic words</e:rainbow> of power!\n<w:30>Did you see that?"
		)
		dialog2.parse_text()
		self.project.add_dialog(dialog2)

		# Dialog with choices
		dialog3 = DialogEntry(
			dialog_id=3,
			speaker="Merchant",
			portrait="merchant",
			text="Would you like to buy something?",
			choices=[
				DialogChoice("Yes, show me your wares", target_dialog=4),
				DialogChoice("No, thank you", target_dialog=5),
			]
		)
		dialog3.parse_text()
		self.project.add_dialog(dialog3)

		# Quest dialog
		dialog4 = DialogEntry(
			dialog_id=4,
			speaker="Knight",
			portrait="knight",
			text="<c:red>Danger!</c:red> <e:shake>Monsters</e:shake> approach!\n<s:slow>Prepare for battle...</s:slow>"
		)
		dialog4.parse_text()
		self.project.add_dialog(dialog4)

		self.current_dialog = dialog1
		self.selected_dialog_id = 1

	def run(self):
		"""Main editor loop"""
		while self.running:
			self._handle_events()
			self._render()
			self.clock.tick(60)

		pygame.quit()

	def _handle_events(self):
		"""Handle input events"""
		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				self.running = False

			elif event.type == pygame.KEYDOWN:
				if self.editing_text:
					self._handle_text_input(event)
				else:
					self._handle_command_input(event)

			elif event.type == pygame.MOUSEBUTTONDOWN:
				self._handle_mouse_click(event.pos, event.button)

			elif event.type == pygame.MOUSEWHEEL:
				self.dialog_scroll = max(0, self.dialog_scroll - event.y * 30)

	def _handle_text_input(self, event):
		"""Handle text editing input"""
		if event.key == pygame.K_ESCAPE:
			self.editing_text = False
			if self.current_dialog:
				self.current_dialog.text = self.text_input
				self.current_dialog.parse_text()
				self.text_renderer.reset_frame()

		elif event.key == pygame.K_RETURN:
			if pygame.key.get_mods() & pygame.KMOD_CTRL:
				self.editing_text = False
				if self.current_dialog:
					self.current_dialog.text = self.text_input
					self.current_dialog.parse_text()
					self.text_renderer.reset_frame()
			else:
				self.text_input = (self.text_input[:self.cursor_pos] +
								   '\n' + self.text_input[self.cursor_pos:])
				self.cursor_pos += 1

		elif event.key == pygame.K_BACKSPACE:
			if self.cursor_pos > 0:
				self.text_input = (self.text_input[:self.cursor_pos - 1] +
								   self.text_input[self.cursor_pos:])
				self.cursor_pos -= 1

		elif event.key == pygame.K_DELETE:
			if self.cursor_pos < len(self.text_input):
				self.text_input = (self.text_input[:self.cursor_pos] +
								   self.text_input[self.cursor_pos + 1:])

		elif event.key == pygame.K_LEFT:
			self.cursor_pos = max(0, self.cursor_pos - 1)

		elif event.key == pygame.K_RIGHT:
			self.cursor_pos = min(len(self.text_input), self.cursor_pos + 1)

		elif event.key == pygame.K_HOME:
			self.cursor_pos = 0

		elif event.key == pygame.K_END:
			self.cursor_pos = len(self.text_input)

		elif event.unicode and event.unicode.isprintable():
			self.text_input = (self.text_input[:self.cursor_pos] +
							   event.unicode + self.text_input[self.cursor_pos:])
			self.cursor_pos += 1

	def _handle_command_input(self, event):
		"""Handle command input"""
		if event.key == pygame.K_ESCAPE:
			self.running = False

		# Edit current dialog
		elif event.key == pygame.K_e:
			if self.current_dialog:
				self.editing_text = True
				self.text_input = self.current_dialog.text
				self.cursor_pos = len(self.text_input)

		# New dialog
		elif event.key == pygame.K_n:
			new_id = max(self.project.dialogs.keys()) + 1 if self.project.dialogs else 1
			dialog = DialogEntry(
				dialog_id=new_id,
				speaker="New Speaker",
				text="Enter text here..."
			)
			dialog.parse_text()
			self.project.add_dialog(dialog)
			self.current_dialog = dialog
			self.selected_dialog_id = new_id

		# Save project
		elif event.key == pygame.K_s and pygame.key.get_mods() & pygame.KMOD_CTRL:
			self.project.export_json("text_project.json")
			print("Project saved to text_project.json")

		# Load project
		elif event.key == pygame.K_o and pygame.key.get_mods() & pygame.KMOD_CTRL:
			try:
				self.project = TextProject.from_json("text_project.json")
				if self.project.dialogs:
					first_id = min(self.project.dialogs.keys())
					self.current_dialog = self.project.dialogs[first_id]
					self.selected_dialog_id = first_id
				print("Project loaded from text_project.json")
			except FileNotFoundError:
				print("No text_project.json file found")

		# Toggle panels
		elif event.key == pygame.K_F1:
			self.show_preview = not self.show_preview
		elif event.key == pygame.K_F2:
			self.show_code_help = not self.show_code_help

	def _handle_mouse_click(self, pos: Tuple[int, int], button: int):
		"""Handle mouse click"""
		x, y = pos

		# Check dialog list
		if x < 250 and button == 1:
			# Calculate which dialog was clicked
			y_offset = 80 - self.dialog_scroll

			for dialog_id in sorted(self.project.dialogs.keys()):
				if y_offset <= y < y_offset + 60:
					self.current_dialog = self.project.dialogs[dialog_id]
					self.selected_dialog_id = dialog_id
					self.text_renderer.reset_frame()
					break
				y_offset += 65

	def _render(self):
		"""Render editor"""
		self.screen.fill((25, 25, 35))

		# Draw dialog list
		self._draw_dialog_list()

		# Draw main editor area
		if self.editing_text:
			self._draw_text_editor()
		else:
			self._draw_dialog_view()

		# Draw preview panel
		if self.show_preview:
			self._draw_preview_panel()

		# Draw code help
		if self.show_code_help:
			self._draw_code_help()

		# Draw toolbar
		self._draw_toolbar()

		pygame.display.flip()

	def _draw_dialog_list(self):
		"""Draw list of dialogs"""
		panel_x = 0
		panel_y = 50
		panel_width = 250
		panel_height = self.height - 100

		# Background
		pygame.draw.rect(self.screen, (35, 35, 45),
						 (panel_x, panel_y, panel_width, panel_height))
		pygame.draw.rect(self.screen, (80, 80, 100),
						 (panel_x, panel_y, panel_width, panel_height), 2)

		# Title
		title = self.font.render("Dialogs", True, (255, 255, 255))
		self.screen.blit(title, (panel_x + 10, panel_y + 10))

		# Dialog entries
		y_offset = panel_y + 50 - self.dialog_scroll

		for dialog_id in sorted(self.project.dialogs.keys()):
			dialog = self.project.dialogs[dialog_id]

			# Skip if off-screen
			if y_offset + 60 < panel_y or y_offset > panel_y + panel_height:
				y_offset += 65
				continue

			# Background
			bg_color = (60, 60, 80) if dialog_id == self.selected_dialog_id else (45, 45, 55)
			pygame.draw.rect(self.screen, bg_color,
							 (panel_x + 5, y_offset, panel_width - 10, 60))
			pygame.draw.rect(self.screen, (100, 100, 120),
							 (panel_x + 5, y_offset, panel_width - 10, 60), 1)

			# Dialog ID
			id_text = self.small_font.render(f"#{dialog_id}", True, (180, 180, 180))
			self.screen.blit(id_text, (panel_x + 10, y_offset + 5))

			# Speaker
			speaker_text = self.small_font.render(dialog.speaker, True, (200, 200, 255))
			self.screen.blit(speaker_text, (panel_x + 10, y_offset + 25))

			# Preview
			preview = dialog.text[:30] + "..." if len(dialog.text) > 30 else dialog.text
			preview = preview.replace('\n', ' ')
			preview_text = self.small_font.render(preview, True, (150, 150, 150))
			self.screen.blit(preview_text, (panel_x + 10, y_offset + 42))

			y_offset += 65

	def _draw_text_editor(self):
		"""Draw text editing area"""
		editor_x = 250
		editor_y = 50
		editor_width = self.width - 250 - (400 if self.show_code_help else 0)
		editor_height = self.height - 100

		# Background
		pygame.draw.rect(self.screen, (35, 35, 45),
						 (editor_x, editor_y, editor_width, editor_height))
		pygame.draw.rect(self.screen, (80, 80, 100),
						 (editor_x, editor_y, editor_width, editor_height), 2)

		# Title
		title = self.font.render("Editing Text", True, (255, 255, 255))
		self.screen.blit(title, (editor_x + 10, editor_y + 10))

		# Text area
		text_y = editor_y + 50

		# Render text with cursor
		display_text = self.text_input[:self.cursor_pos] + '|' + self.text_input[self.cursor_pos:]

		y_offset = text_y
		for line in display_text.split('\n'):
			text_surf = self.mono_font.render(line, True, (255, 255, 255))
			self.screen.blit(text_surf, (editor_x + 10, y_offset))
			y_offset += 20

		# Instructions
		help_text = "Ctrl+Enter:Save | Esc:Cancel"
		help_surf = self.small_font.render(help_text, True, (150, 150, 150))
		self.screen.blit(help_surf, (editor_x + 10, editor_y + editor_height - 25))

	def _draw_dialog_view(self):
		"""Draw dialog view (non-editing)"""
		view_x = 250
		view_y = 50
		view_width = self.width - 250 - (400 if self.show_code_help else 0)
		view_height = self.height - 100 - (250 if self.show_preview else 0)

		# Background
		pygame.draw.rect(self.screen, (35, 35, 45),
						 (view_x, view_y, view_width, view_height))
		pygame.draw.rect(self.screen, (80, 80, 100),
						 (view_x, view_y, view_width, view_height), 2)

		if not self.current_dialog:
			return

		# Title
		title = self.font.render(f"Dialog #{self.current_dialog.dialog_id}",
								 True, (255, 255, 255))
		self.screen.blit(title, (view_x + 10, view_y + 10))

		# Speaker
		speaker = self.font.render(f"Speaker: {self.current_dialog.speaker}",
								   True, (200, 200, 255))
		self.screen.blit(speaker, (view_x + 10, view_y + 40))

		# Raw text
		text_label = self.small_font.render("Text:", True, (180, 180, 180))
		self.screen.blit(text_label, (view_x + 10, view_y + 70))

		y_offset = view_y + 95
		for line in self.current_dialog.text.split('\n'):
			text_surf = self.mono_font.render(line, True, (220, 220, 220))
			self.screen.blit(text_surf, (view_x + 10, y_offset))
			y_offset += 20

		# Choices
		if self.current_dialog.choices:
			y_offset += 10
			choices_label = self.small_font.render("Choices:", True, (180, 180, 180))
			self.screen.blit(choices_label, (view_x + 10, y_offset))
			y_offset += 25

			for i, choice in enumerate(self.current_dialog.choices):
				choice_text = self.mono_font.render(
					f"  {i + 1}. {choice.text}", True, (255, 255, 100))
				self.screen.blit(choice_text, (view_x + 10, y_offset))
				y_offset += 20

	def _draw_preview_panel(self):
		"""Draw live preview of formatted text"""
		panel_x = 250
		panel_y = self.height - 250
		panel_width = self.width - 250 - (400 if self.show_code_help else 0)
		panel_height = 200

		# Background
		pygame.draw.rect(self.screen, (20, 20, 30),
						 (panel_x, panel_y, panel_width, panel_height))
		pygame.draw.rect(self.screen, (80, 80, 100),
						 (panel_x, panel_y, panel_width, panel_height), 2)

		# Title
		title = self.font.render("Preview", True, (255, 255, 255))
		self.screen.blit(title, (panel_x + 10, panel_y + 10))

		if not self.current_dialog:
			return

		# Render formatted text
		self.text_renderer.render_text(
			self.screen,
			self.current_dialog,
			panel_x + 20,
			panel_y + 45,
			panel_width - 40,
			self.preview_chars
		)

	def _draw_code_help(self):
		"""Draw formatting code help panel"""
		panel_x = self.width - 400
		panel_y = 50
		panel_width = 400
		panel_height = self.height - 100

		# Background
		pygame.draw.rect(self.screen, (35, 35, 45),
						 (panel_x, panel_y, panel_width, panel_height))
		pygame.draw.rect(self.screen, (80, 80, 100),
						 (panel_x, panel_y, panel_width, panel_height), 2)

		# Title
		title = self.font.render("Formatting Codes", True, (255, 255, 255))
		self.screen.blit(title, (panel_x + 10, panel_y + 10))

		# Code reference
		codes = [
			("Colors:", ""),
			("  <c:red>", "Red text"),
			("  <c:blue>", "Blue text"),
			("  <c:yellow>", "Yellow text"),
			("  <c:green>", "Green text"),
			("", ""),
			("Speed:", ""),
			("  <s:instant>", "Instant"),
			("  <s:fast>", "Fast"),
			("  <s:slow>", "Slow"),
			("", ""),
			("Effects:", ""),
			("  <e:shake>", "Shake effect"),
			("  <e:wave>", "Wave effect"),
			("  <e:rainbow>", "Rainbow colors"),
			("  <e:bounce>", "Bounce effect"),
			("", ""),
			("Other:", ""),
			("  <w:30>", "Wait 30 frames"),
			("  <i:heart>", "Show icon"),
			("  {player_name}", "Variable"),
			("  <clear>", "Clear text"),
			("  <br>", "Line break"),
		]

		y_offset = panel_y + 45
		for code, desc in codes:
			if code:
				code_surf = self.small_font.render(code, True, (100, 255, 100))
				self.screen.blit(code_surf, (panel_x + 10, y_offset))

				if desc:
					desc_surf = self.small_font.render(desc, True, (180, 180, 180))
					self.screen.blit(desc_surf, (panel_x + 150, y_offset))

			y_offset += 20

			if y_offset > panel_y + panel_height - 30:
				break

	def _draw_toolbar(self):
		"""Draw top toolbar"""
		toolbar_height = 40
		pygame.draw.rect(self.screen, (45, 45, 55),
						 (0, 0, self.width, toolbar_height))
		pygame.draw.rect(self.screen, (80, 80, 100),
						 (0, 0, self.width, toolbar_height), 2)

		# Title
		title = self.font.render(f"Project: {self.project.name}",
								 True, (255, 255, 255))
		self.screen.blit(title, (10, 10))

		# Instructions
		help_text = "E:Edit | N:New Dialog | Ctrl+S:Save | Ctrl+O:Load | F1:Preview | F2:Help"
		help_surf = self.small_font.render(help_text, True, (180, 180, 180))
		self.screen.blit(help_surf, (350, 12))


def main():
	"""Run advanced text editor"""
	editor = AdvancedTextEditor()
	editor.run()


if __name__ == "__main__":
	main()
