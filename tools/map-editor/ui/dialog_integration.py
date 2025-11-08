#!/usr/bin/env python3
"""
FFMQ Map Editor - Dialog Editor Integration
Integrates dialog editing into the main map editor for NPC dialog and event scripting
"""

import pygame
from pathlib import Path
from typing import Optional, List, Tuple, Dict
from dataclasses import dataclass
import sys

# Add directories to path
sys.path.insert(0, str(Path(__file__).parent.parent / 'utils'))
sys.path.insert(0, str(Path(__file__).parent))

from dialog_text import DialogText, DialogMetrics
from dialog_database import DialogDatabase, DialogEntry
from event_script import EventScriptEngine, EventScript
from dialog_editor_enhanced import (
	EnhancedTextEditor,
	FFMQDialogPreview,
	VisualScriptFlowchart,
	SyntaxHighlighter
)


# UI Colors
COLOR_BG = (40, 40, 45)
COLOR_PANEL_BG = (50, 50, 55)
COLOR_TEXT = (220, 220, 220)
COLOR_TEXT_DIM = (140, 140, 140)
COLOR_HIGHLIGHT = (70, 130, 180)
COLOR_BORDER = (80, 80, 85)
COLOR_BUTTON = (60, 120, 180)
COLOR_BUTTON_HOVER = (80, 140, 200)
COLOR_SUCCESS = (80, 200, 120)
COLOR_WARNING = (255, 165, 0)
COLOR_ERROR = (220, 50, 50)


@dataclass
class NPCDialogBinding:
	"""Binding between map NPC and dialog ID"""
	npc_id: int
	map_id: int
	dialog_id: int
	event_script_id: Optional[int] = None
	trigger_type: str = "talk"  # talk, step, auto
	x: int = 0
	y: int = 0


class DialogEditorPanel:
	"""Dialog editor panel integrated into map editor"""

	def __init__(self, x: int, y: int, width: int, height: int):
		"""Initialize dialog editor panel"""
		self.x = x
		self.y = y
		self.width = width
		self.height = height

		# Data
		self.dialog_text = DialogText()
		self.database = DialogDatabase()
		self.current_dialog: Optional[DialogEntry] = None
		self.current_npc_binding: Optional[NPCDialogBinding] = None

		# UI components
		panel_height = height // 2
		self.text_editor = EnhancedTextEditor(
			x=x + 10,
			y=y + 50,
			width=width - 220,
			height=panel_height - 60
		)

		self.preview = FFMQDialogPreview(
			x=x + 10,
			y=y + panel_height + 10,
			width=width - 220,
			height=160
		)

		# Side panel for controls
		self.side_panel_x = x + width - 200
		self.side_panel_y = y + 50
		self.side_panel_width = 190

		# Buttons
		self.buttons = {
			'save': pygame.Rect(self.side_panel_x, self.side_panel_y, 180, 30),
			'revert': pygame.Rect(self.side_panel_x, self.side_panel_y + 40, 180, 30),
			'preview': pygame.Rect(self.side_panel_x, self.side_panel_y + 80, 180, 30),
			'next': pygame.Rect(self.side_panel_x, self.side_panel_y + 120, 85, 30),
			'prev': pygame.Rect(self.side_panel_x + 95, self.side_panel_y + 120, 85, 30),
		}
		self.button_hover = None

		# State
		self.modified = False
		self.show_preview = False
		self.metrics: Optional[DialogMetrics] = None

	def set_npc_dialog(self, binding: NPCDialogBinding):
		"""
		Set dialog for NPC

		Args:
			binding: NPC dialog binding
		"""
		self.current_npc_binding = binding

		# Load dialog from database
		if binding.dialog_id in self.database.dialogs:
			self.current_dialog = self.database.dialogs[binding.dialog_id]
			self.text_editor.text = self.current_dialog.text
			self.text_editor.cursor_pos = 0
			self._update_metrics()
		else:
			# Create new dialog
			self.current_dialog = DialogEntry(
				id=binding.dialog_id,
				text="",
				raw_bytes=bytearray(),
				pointer=0,
				address=0,
				length=0
			)
			self.text_editor.text = ""

		self.modified = False

	def set_dialog_by_id(self, dialog_id: int):
		"""
		Set dialog by ID (for standalone editing)

		Args:
			dialog_id: Dialog ID to edit
		"""
		if dialog_id in self.database.dialogs:
			self.current_dialog = self.database.dialogs[dialog_id]
			self.text_editor.text = self.current_dialog.text
			self.text_editor.cursor_pos = 0
			self.current_npc_binding = None
			self.modified = False
			self._update_metrics()

	def _update_metrics(self):
		"""Update dialog metrics"""
		if self.text_editor.text:
			self.metrics = self.dialog_text.calculate_metrics(self.text_editor.text)
		else:
			self.metrics = None

	def _save_dialog(self):
		"""Save current dialog"""
		if not self.current_dialog:
			return

		text = self.text_editor.text

		# Validate
		is_valid, messages = self.dialog_text.validate(text)
		if not is_valid:
			print(f"Validation errors: {messages}")
			return

		# Encode
		try:
			encoded = self.dialog_text.encode(text)

			# Update dialog
			self.current_dialog.text = text
			self.current_dialog.raw_bytes = encoded
			self.current_dialog.length = len(encoded)
			self.current_dialog.modified = True

			self.modified = False
			self._update_metrics()

			print(f"✓ Dialog #{self.current_dialog.id:04X} saved")
		except Exception as e:
			print(f"✗ Error encoding dialog: {e}")

	def _revert_dialog(self):
		"""Revert to original dialog"""
		if self.current_dialog:
			self.text_editor.text = self.current_dialog.text
			self.text_editor.cursor_pos = 0
			self.modified = False
			self._update_metrics()

	def _toggle_preview(self):
		"""Toggle preview mode"""
		self.show_preview = not self.show_preview
		if self.show_preview:
			self.preview.set_text(self.text_editor.text)

	def _navigate_dialog(self, direction: int):
		"""Navigate to next/previous dialog"""
		if not self.current_dialog:
			return

		all_ids = sorted(self.database.dialogs.keys())
		try:
			current_index = all_ids.index(self.current_dialog.id)
			new_index = (current_index + direction) % len(all_ids)
			self.set_dialog_by_id(all_ids[new_index])
		except ValueError:
			pass

	def handle_event(self, event: pygame.event.Event) -> bool:
		"""
		Handle pygame event

		Args:
			event: Pygame event

		Returns:
			True if event was handled
		"""
		if event.type == pygame.MOUSEBUTTONDOWN:
			mouse_pos = event.pos

			# Check buttons
			if self.buttons['save'].collidepoint(mouse_pos):
				self._save_dialog()
				return True
			elif self.buttons['revert'].collidepoint(mouse_pos):
				self._revert_dialog()
				return True
			elif self.buttons['preview'].collidepoint(mouse_pos):
				self._toggle_preview()
				return True
			elif self.buttons['next'].collidepoint(mouse_pos):
				self._navigate_dialog(1)
				return True
			elif self.buttons['prev'].collidepoint(mouse_pos):
				self._navigate_dialog(-1)
				return True

			# Pass to text editor
			if self.text_editor.handle_click(mouse_pos):
				return True

		elif event.type == pygame.KEYDOWN:
			old_text = self.text_editor.text
			self.text_editor.handle_key(event)

			# Check if modified
			if self.text_editor.text != old_text:
				self.modified = True
				self._update_metrics()

			# Keyboard shortcuts
			if event.mod & pygame.KMOD_CTRL:
				if event.key == pygame.K_s:  # Ctrl+S to save
					self._save_dialog()
					return True
				elif event.key == pygame.K_p:  # Ctrl+P to preview
					self._toggle_preview()
					return True

			return True

		return False

	def update(self, dt: float):
		"""
		Update panel state

		Args:
			dt: Delta time in seconds
		"""
		# Update preview animation
		if self.show_preview:
			self.preview.update(dt)

		# Update button hover states
		mouse_pos = pygame.mouse.get_pos()
		self.button_hover = None
		for name, rect in self.buttons.items():
			if rect.collidepoint(mouse_pos):
				self.button_hover = name
				break

	def draw(self, surface: pygame.Surface, font: pygame.font.Font, small_font: pygame.font.Font):
		"""
		Draw dialog editor panel

		Args:
			surface: Surface to draw on
			font: Main font
			small_font: Small font for details
		"""
		# Background
		pygame.draw.rect(surface, COLOR_PANEL_BG, (self.x, self.y, self.width, self.height))
		pygame.draw.rect(surface, COLOR_BORDER, (self.x, self.y, self.width, self.height), width=1)

		# Title
		if self.current_dialog:
			title = f"Dialog Editor - #{self.current_dialog.id:04X}"
			if self.current_npc_binding:
				title += f" (NPC {self.current_npc_binding.npc_id} @ Map {self.current_npc_binding.map_id})"
		else:
			title = "Dialog Editor - No Dialog Selected"

		title_surf = font.render(title, True, COLOR_TEXT)
		surface.blit(title_surf, (self.x + 10, self.y + 10))

		# Modified indicator
		if self.modified:
			mod_surf = font.render("*", True, COLOR_WARNING)
			surface.blit(mod_surf, (self.x + 10 + title_surf.get_width() + 5, self.y + 10))

		# Draw text editor
		self.text_editor.draw(surface, font)

		# Draw preview if enabled
		if self.show_preview:
			self.preview.draw(surface, font)

		# Draw side panel
		self._draw_side_panel(surface, font, small_font)

	def _draw_side_panel(self, surface: pygame.Surface, font: pygame.font.Font, small_font: pygame.font.Font):
		"""Draw side panel with controls and metrics"""
		x = self.side_panel_x
		y = self.side_panel_y

		# Draw buttons
		for name, rect in self.buttons.items():
			color = COLOR_BUTTON_HOVER if name == self.button_hover else COLOR_BUTTON
			pygame.draw.rect(surface, color, rect, border_radius=4)
			pygame.draw.rect(surface, COLOR_BORDER, rect, width=1, border_radius=4)

			# Button text
			button_text = {
				'save': 'Save',
				'revert': 'Revert',
				'preview': 'Preview' if not self.show_preview else 'Edit',
				'next': '→',
				'prev': '←'
			}
			text_surf = font.render(button_text[name], True, COLOR_TEXT)
			text_rect = text_surf.get_rect(center=rect.center)
			surface.blit(text_surf, text_rect)

		# Draw metrics
		y += 170

		if self.metrics:
			pygame.draw.line(surface, COLOR_BORDER, (x, y), (x + self.side_panel_width, y))
			y += 10

			metrics_title = small_font.render("Metrics", True, COLOR_TEXT)
			surface.blit(metrics_title, (x, y))
			y += 20

			metrics_lines = [
				f"Bytes: {self.metrics.byte_count}/{DialogText.MAX_DIALOG_LENGTH}",
				f"Chars: {self.metrics.char_count}",
				f"Lines: {self.metrics.line_count}",
				f"Time: ~{self.metrics.estimated_time:.1f}s"
			]

			for line in metrics_lines:
				line_surf = small_font.render(line, True, COLOR_TEXT_DIM)
				surface.blit(line_surf, (x, y))
				y += 18

			# Byte usage bar
			y += 5
			bar_width = self.side_panel_width
			bar_height = 8
			usage_ratio = self.metrics.byte_count / DialogText.MAX_DIALOG_LENGTH

			# Background
			pygame.draw.rect(surface, (60, 60, 65), (x, y, bar_width, bar_height), border_radius=4)

			# Usage
			bar_color = COLOR_SUCCESS if usage_ratio < 0.8 else (COLOR_WARNING if usage_ratio < 1.0 else COLOR_ERROR)
			usage_width = int(bar_width * min(usage_ratio, 1.0))
			if usage_width > 0:
				pygame.draw.rect(surface, bar_color, (x, y, usage_width, bar_height), border_radius=4)

			y += 20

			# Warnings
			if self.metrics.warnings:
				pygame.draw.line(surface, COLOR_BORDER, (x, y), (x + self.side_panel_width, y))
				y += 10

				warn_title = small_font.render("Warnings", True, COLOR_WARNING)
				surface.blit(warn_title, (x, y))
				y += 20

				for warning in self.metrics.warnings[:3]:  # Show max 3
					# Truncate long warnings
					warn_text = warning[:25] + "..." if len(warning) > 25 else warning
					warn_surf = small_font.render(warn_text, True, COLOR_WARNING)
					surface.blit(warn_surf, (x, y))
					y += 16


class NPCPropertiesDialog:
	"""Dialog for editing NPC properties including dialog assignment"""

	def __init__(self, npc_id: int, x: int = 0, y: int = 0):
		"""
		Initialize NPC properties dialog

		Args:
			npc_id: NPC ID
			x: NPC X position
			y: NPC Y position
		"""
		self.npc_id = npc_id
		self.x = x
		self.y = y

		# Properties
		self.dialog_id: Optional[int] = None
		self.event_script_id: Optional[int] = None
		self.trigger_type = "talk"
		self.sprite_id = 0
		self.name = f"NPC {npc_id}"

		# UI state
		self.visible = False
		self.rect = pygame.Rect(200, 150, 400, 300)

	def show(self):
		"""Show dialog"""
		self.visible = True

	def hide(self):
		"""Hide dialog"""
		self.visible = False

	def handle_event(self, event: pygame.event.Event) -> bool:
		"""Handle pygame event"""
		if not self.visible:
			return False

		# TODO: Implement property editing UI
		# For now, just handle close
		if event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
			self.hide()
			return True

		return False

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw properties dialog"""
		if not self.visible:
			return

		# Semi-transparent background
		overlay = pygame.Surface((surface.get_width(), surface.get_height()))
		overlay.set_alpha(128)
		overlay.fill((0, 0, 0))
		surface.blit(overlay, (0, 0))

		# Dialog box
		pygame.draw.rect(surface, COLOR_PANEL_BG, self.rect, border_radius=8)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, width=2, border_radius=8)

		# Title
		title = f"NPC Properties - {self.name}"
		title_surf = font.render(title, True, COLOR_TEXT)
		surface.blit(title_surf, (self.rect.x + 10, self.rect.y + 10))

		# Properties
		y = self.rect.y + 50

		props = [
			f"ID: {self.npc_id}",
			f"Position: ({self.x}, {self.y})",
			f"Dialog ID: {self.dialog_id:04X}" if self.dialog_id is not None else "Dialog ID: None",
			f"Event Script: {self.event_script_id:04X}" if self.event_script_id is not None else "Event Script: None",
			f"Trigger: {self.trigger_type}",
			f"Sprite: {self.sprite_id}",
		]

		for prop in props:
			prop_surf = font.render(prop, True, COLOR_TEXT_DIM)
			surface.blit(prop_surf, (self.rect.x + 20, y))
			y += 25

		# Instructions
		y = self.rect.y + self.rect.height - 30
		inst_surf = font.render("Press ESC to close", True, COLOR_TEXT_DIM)
		surface.blit(inst_surf, (self.rect.x + 10, y))


class MapEditorDialogIntegration:
	"""Integration layer between map editor and dialog editor"""

	def __init__(self, map_editor):
		"""
		Initialize integration

		Args:
			map_editor: Main map editor instance
		"""
		self.map_editor = map_editor
		self.database = DialogDatabase()
		self.dialog_text = DialogText()

		# NPC dialog bindings (map_id -> npc_id -> binding)
		self.npc_bindings: Dict[int, Dict[int, NPCDialogBinding]] = {}

		# Current editing
		self.current_binding: Optional[NPCDialogBinding] = None

	def load_npc_dialogs_for_map(self, map_id: int):
		"""
		Load NPC dialog bindings for a map

		Args:
			map_id: Map ID
		"""
		# TODO: Load from ROM based on map data
		# For now, create placeholder bindings
		if map_id not in self.npc_bindings:
			self.npc_binogs[map_id] = {}

	def get_npc_dialog(self, map_id: int, npc_id: int) -> Optional[NPCDialogBinding]:
		"""
		Get dialog binding for NPC

		Args:
			map_id: Map ID
			npc_id: NPC ID

		Returns:
			Dialog binding or None
		"""
		return self.npc_bindings.get(map_id, {}).get(npc_id)

	def set_npc_dialog(self, map_id: int, npc_id: int, dialog_id: int,
					   x: int = 0, y: int = 0, event_script_id: Optional[int] = None):
		"""
		Set dialog for NPC

		Args:
			map_id: Map ID
			npc_id: NPC ID
			dialog_id: Dialog ID
			x: NPC X position
			y: NPC Y position
			event_script_id: Event script ID (optional)
		"""
		if map_id not in self.npc_bindings:
			self.npc_bindings[map_id] = {}

		binding = NPCDialogBinding(
			npc_id=npc_id,
			map_id=map_id,
			dialog_id=dialog_id,
			event_script_id=event_script_id,
			x=x,
			y=y
		)

		self.npc_bindings[map_id][npc_id] = binding
		return binding

	def edit_npc_dialog(self, map_id: int, npc_id: int) -> Optional[NPCDialogBinding]:
		"""
		Open dialog editor for NPC

		Args:
			map_id: Map ID
			npc_id: NPC ID

		Returns:
			Dialog binding
		"""
		binding = self.get_npc_dialog(map_id, npc_id)
		if binding:
			self.current_binding = binding
			return binding
		return None

	def save_all_modifications(self, output_rom: Path):
		"""
		Save all dialog modifications to ROM

		Args:
			output_rom: Output ROM path
		"""
		# Save modified dialogs
		self.database.save_to_rom(output_rom)

		# TODO: Save NPC dialog bindings to ROM map data

		print(f"✓ Saved {self.database.get_modified_count()} modified dialogs")


# Export integration class
__all__ = [
	'DialogEditorPanel',
	'NPCPropertiesDialog',
	'NPCDialogBinding',
	'MapEditorDialogIntegration'
]
