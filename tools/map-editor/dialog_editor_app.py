#!/usr/bin/env python3
"""
FFMQ Dialog Editor - Complete Example Application
Demonstrates the full dialog editing system with all features
"""

import pygame
import sys
from pathlib import Path
from typing import Optional, List

# Add utils to path
sys.path.insert(0, str(Path(__file__).parent / 'utils'))
sys.path.insert(0, str(Path(__file__).parent / 'ui'))

from dialog_text import DialogText, ControlCode
from dialog_database import DialogDatabase, DialogEntry
from event_script import EventScriptEngine, EventScript, CommandCategory
from dialog_editor_enhanced import (
	EnhancedTextEditor,
	FFMQDialogPreview,
	VisualScriptFlowchart,
	AutocompleteEngine,
	SyntaxHighlighter
)
from dialog_browser import (
	DialogBrowser,
	DialogListView,
	DialogDetailView,
	DialogSearchPanel
)
from dialog_integration import (
	DialogEditorPanel,
	NPCPropertiesDialog,
	NPCDialogBinding,
	MapEditorDialogIntegration
)


# UI Configuration
WINDOW_WIDTH = 1400
WINDOW_HEIGHT = 900
FPS = 60

COLOR_BG = (40, 40, 45)
COLOR_PANEL_BG = (50, 50, 55)
COLOR_TEXT = (220, 220, 220)
COLOR_HIGHLIGHT = (70, 130, 180)
COLOR_BORDER = (80, 80, 85)


class Tab:
	"""Tab in tabbed interface"""
	def __init__(self, name: str, content):
		self.name = name
		self.content = content
		self.active = False


class DialogEditorApp:
	"""Complete dialog editor application"""

	def __init__(self):
		"""Initialize application"""
		pygame.init()

		# Window setup
		self.screen = pygame.display.set_mode((WINDOW_WIDTH, WINDOW_HEIGHT))
		pygame.display.set_caption("FFMQ Dialog Editor - Complete Edition")

		# Fonts
		self.font = pygame.font.SysFont('consolas', 14)
		self.small_font = pygame.font.SysFont('consolas', 12)
		self.title_font = pygame.font.SysFont('consolas', 18, bold=True)
		self.large_font = pygame.font.SysFont('consolas', 24, bold=True)

		# Core systems
		self.dialog_text = DialogText()
		self.database = DialogDatabase()
		self.script_engine = EventScriptEngine()

		# UI Components
		self._setup_ui()

		# State
		self.running = True
		self.clock = pygame.time.Clock()
		self.current_tab = 0

		# Load sample data
		self._load_sample_data()

	def _setup_ui(self):
		"""Setup UI components"""
		# Tab bar
		self.tab_height = 40
		self.tab_area = pygame.Rect(0, 0, WINDOW_WIDTH, self.tab_height)

		# Content area
		content_y = self.tab_height
		content_height = WINDOW_HEIGHT - self.tab_height - 30  # 30 for status bar

		# Create tabs
		self.tabs = [
			Tab("Browser", self._create_browser_tab(content_y, content_height)),
			Tab("Editor", self._create_editor_tab(content_y, content_height)),
			Tab("Scripts", self._create_scripts_tab(content_y, content_height)),
			Tab("Preview", self._create_preview_tab(content_y, content_height)),
			Tab("Export", self._create_export_tab(content_y, content_height)),
		]
		self.tabs[0].active = True

	def _create_browser_tab(self, y: int, height: int):
		"""Create dialog browser tab"""
		return {
			'search_panel': DialogSearchPanel(10, y + 10, 400, 50),
			'list_view': DialogListView(10, y + 70, 400, height - 80),
			'detail_view': DialogDetailView(420, y + 10, WINDOW_WIDTH - 430, height - 20)
		}

	def _create_editor_tab(self, y: int, height: int):
		"""Create dialog editor tab"""
		return {
			'panel': DialogEditorPanel(10, y + 10, WINDOW_WIDTH - 20, height - 20)
		}

	def _create_scripts_tab(self, y: int, height: int):
		"""Create event scripts tab"""
		return {
			'editor': EnhancedTextEditor(10, y + 10, 600, height - 20),
			'flowchart': VisualScriptFlowchart(620, height),
			'script': None  # Current script object
		}

	def _create_preview_tab(self, y: int, height: int):
		"""Create preview tab"""
		return {
			'preview': FFMQDialogPreview(
				x=(WINDOW_WIDTH - 480) // 2,
				y=y + 100,
				width=480,
				height=160
			),
			'controls': pygame.Rect(WINDOW_WIDTH // 2 - 100, y + 300, 200, 40),
			'playing': False
		}

	def _create_export_tab(self, y: int, height: int):
		"""Create export/import tab"""
		return {
			'info_area': pygame.Rect(10, y + 10, WINDOW_WIDTH - 20, height - 20),
			'buttons': {
				'export_json': pygame.Rect(50, y + 100, 180, 40),
				'export_csv': pygame.Rect(250, y + 100, 180, 40),
				'export_po': pygame.Rect(450, y + 100, 180, 40),
				'import': pygame.Rect(50, y + 200, 180, 40),
				'validate': pygame.Rect(250, y + 200, 180, 40),
			},
			'status': ""
		}

	def _load_sample_data(self):
		"""Load sample dialog data"""
		# Create sample dialogs
		sample_dialogs = [
			(0x0001, "Welcome to Foresta!\nYour adventure begins."),
			(0x0002, "The prophecy speaks of a hero...[WAIT]\nAre you that hero?"),
			(0x0003, "[YELLOW]Crystal[WHITE] found!\n[SLOW]The world is saved..."),
			(0x0004, "Shop: [WAIT]\nBuy, sell, or leave?"),
			(0x0005, "I'm an NPC.\nI have generic dialog."),
			(0x0006, "The [YELLOW]Rainbow Road[WHITE] leads to the Focus Tower."),
			(0x0007, "Beware the monsters ahead![WAIT]"),
			(0x0008, "Thank you for saving us!"),
			(0x0009, "[NAME], you must find all four Crystals!"),
			(0x000A, "This is a very long dialog that demonstrates how the system handles longer text. It continues for quite a while to show wrapping and length validation.[WAIT]\nSecond paragraph here."),
		]

		for dialog_id, text in sample_dialogs:
			encoded = self.dialog_text.encode(text)
			entry = DialogEntry(
				id=dialog_id,
				text=text,
				raw_bytes=encoded,
				pointer=0x8000 + dialog_id * 0x100,
				address=0x018000 + dialog_id * 0x100,
				length=len(encoded)
			)
			self.database.dialogs[dialog_id] = entry

		# Update browser
		browser = self.tabs[0].content
		all_dialogs = list(self.database.dialogs.values())
		browser['list_view'].set_dialogs(all_dialogs)

		# Set initial dialog in editor
		editor_tab = self.tabs[1].content
		editor_tab['panel'].database = self.database
		editor_tab['panel'].set_dialog_by_id(0x0001)

	def run(self):
		"""Main application loop"""
		while self.running:
			dt = self.clock.tick(FPS) / 1000.0

			# Handle events
			for event in pygame.event.get():
				if event.type == pygame.QUIT:
					self.running = False

				self._handle_event(event)

			# Update
			self._update(dt)

			# Draw
			self._draw()

			pygame.display.flip()

		pygame.quit()

	def _handle_event(self, event: pygame.event.Event):
		"""Handle pygame event"""
		# Tab switching
		if event.type == pygame.KEYDOWN:
			if event.mod & pygame.KMOD_CTRL:
				if event.key == pygame.K_1:
					self._switch_tab(0)
				elif event.key == pygame.K_2:
					self._switch_tab(1)
				elif event.key == pygame.K_3:
					self._switch_tab(2)
				elif event.key == pygame.K_4:
					self._switch_tab(3)
				elif event.key == pygame.K_5:
					self._switch_tab(4)

		# Tab bar clicks
		if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
			if self.tab_area.collidepoint(event.pos):
				self._handle_tab_click(event.pos)
				return

		# Pass to active tab
		active_tab = self.tabs[self.current_tab]

		if active_tab.name == "Browser":
			self._handle_browser_event(event, active_tab.content)
		elif active_tab.name == "Editor":
			self._handle_editor_event(event, active_tab.content)
		elif active_tab.name == "Scripts":
			self._handle_scripts_event(event, active_tab.content)
		elif active_tab.name == "Preview":
			self._handle_preview_event(event, active_tab.content)
		elif active_tab.name == "Export":
			self._handle_export_event(event, active_tab.content)

	def _handle_tab_click(self, pos: tuple):
		"""Handle tab bar click"""
		tab_width = 150
		tab_x = 10

		for i, tab in enumerate(self.tabs):
			tab_rect = pygame.Rect(tab_x, 5, tab_width, 30)
			if tab_rect.collidepoint(pos):
				self._switch_tab(i)
				break
			tab_x += tab_width + 10

	def _switch_tab(self, index: int):
		"""Switch to tab"""
		if 0 <= index < len(self.tabs):
			for tab in self.tabs:
				tab.active = False
			self.tabs[index].active = True
			self.current_tab = index

	def _handle_browser_event(self, event: pygame.event.Event, content: dict):
		"""Handle browser tab events"""
		if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
			# Check list view
			selected_id = content['list_view'].handle_click(event.pos)
			if selected_id is not None:
				dialog = self.database.dialogs.get(selected_id)
				content['detail_view'].set_dialog(dialog, self.dialog_text)

		elif event.type == pygame.MOUSEBUTTONDOWN and event.button in (4, 5):
			# Scroll
			direction = -1 if event.button == 4 else 1
			content['list_view'].handle_scroll(direction)

		elif event.type == pygame.KEYDOWN:
			if content['search_panel'].handle_key(event):
				# Update search results
				query = content['search_panel'].search_text
				if query:
					results = self.database.search_dialogs(query)
					content['list_view'].set_dialogs(results)
				else:
					all_dialogs = list(self.database.dialogs.values())
					content['list_view'].set_dialogs(all_dialogs)

	def _handle_editor_event(self, event: pygame.event.Event, content: dict):
		"""Handle editor tab events"""
		content['panel'].handle_event(event)

	def _handle_scripts_event(self, event: pygame.event.Event, content: dict):
		"""Handle scripts tab events"""
		# Handle script editor
		content['editor'].handle_key(event)

		# Ctrl+B to build flowchart
		if event.type == pygame.KEYDOWN:
			if event.mod & pygame.KMOD_CTRL and event.key == pygame.K_b:
				try:
					script = self.script_engine.parse(content['editor'].text)
					content['script'] = script
					content['flowchart'].build_from_script(script)
				except Exception as e:
					print(f"Script parse error: {e}")

	def _handle_preview_event(self, event: pygame.event.Event, content: dict):
		"""Handle preview tab events"""
		if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
			if content['controls'].collidepoint(event.pos):
				# Get current dialog from editor
				editor = self.tabs[1].content['panel']
				if editor.current_dialog:
					content['preview'].set_text(editor.current_dialog.text)
					content['playing'] = True

	def _handle_export_event(self, event: pygame.event.Event, content: dict):
		"""Handle export tab events"""
		if event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
			for name, rect in content['buttons'].items():
				if rect.collidepoint(event.pos):
					self._handle_export_action(name, content)
					break

	def _handle_export_action(self, action: str, content: dict):
		"""Handle export/import action"""
		from dialog_export import DialogExporter, DialogImporter

		if action == 'export_json':
			exporter = DialogExporter(self.database, self.dialog_text)
			count = exporter.export_to_json(Path("dialogs_export.json"), pretty=True)
			content['status'] = f"✓ Exported {count} dialogs to dialogs_export.json"

		elif action == 'export_csv':
			exporter = DialogExporter(self.database, self.dialog_text)
			count = exporter.export_to_csv(Path("dialogs_export.csv"))
			content['status'] = f"✓ Exported {count} dialogs to dialogs_export.csv"

		elif action == 'export_po':
			exporter = DialogExporter(self.database, self.dialog_text)
			count = exporter.export_to_po(Path("dialogs_export.po"))
			content['status'] = f"✓ Exported {count} dialogs to dialogs_export.po"

		elif action == 'import':
			# TODO: File picker dialog
			content['status'] = "Import feature: Select file (not implemented in demo)"

		elif action == 'validate':
			# Validate all dialogs
			errors = []
			for dialog in self.database.dialogs.values():
				is_valid, messages = self.dialog_text.validate(dialog.text)
				if not is_valid:
					errors.extend([f"Dialog {dialog.id:04X}: {msg}" for msg in messages])

			if errors:
				content['status'] = f"✗ Found {len(errors)} validation errors"
			else:
				content['status'] = f"✓ All {len(self.database.dialogs)} dialogs valid!"

	def _update(self, dt: float):
		"""Update application state"""
		# Update active tab
		active_tab = self.tabs[self.current_tab]

		if active_tab.name == "Browser":
			content = active_tab.content
			mouse_pos = pygame.mouse.get_pos()
			content['search_panel'].update(dt)
			content['list_view'].update(mouse_pos)

		elif active_tab.name == "Editor":
			content = active_tab.content
			content['panel'].update(dt)

		elif active_tab.name == "Preview":
			content = active_tab.content
			if content['playing']:
				content['preview'].update(dt)

	def _draw(self):
		"""Draw application"""
		# Background
		self.screen.fill(COLOR_BG)

		# Draw tab bar
		self._draw_tab_bar()

		# Draw active tab content
		active_tab = self.tabs[self.current_tab]

		if active_tab.name == "Browser":
			self._draw_browser_tab(active_tab.content)
		elif active_tab.name == "Editor":
			self._draw_editor_tab(active_tab.content)
		elif active_tab.name == "Scripts":
			self._draw_scripts_tab(active_tab.content)
		elif active_tab.name == "Preview":
			self._draw_preview_tab(active_tab.content)
		elif active_tab.name == "Export":
			self._draw_export_tab(active_tab.content)

		# Draw status bar
		self._draw_status_bar()

	def _draw_tab_bar(self):
		"""Draw tab bar"""
		# Background
		pygame.draw.rect(self.screen, COLOR_PANEL_BG, self.tab_area)
		pygame.draw.line(self.screen, COLOR_BORDER,
			(0, self.tab_height - 1),
			(WINDOW_WIDTH, self.tab_height - 1), 2)

		# Draw tabs
		tab_width = 150
		tab_x = 10

		for i, tab in enumerate(self.tabs):
			tab_rect = pygame.Rect(tab_x, 5, tab_width, 30)

			if tab.active:
				color = COLOR_HIGHLIGHT
			else:
				color = (60, 60, 65)

			pygame.draw.rect(self.screen, color, tab_rect, border_radius=5)
			pygame.draw.rect(self.screen, COLOR_BORDER, tab_rect, width=1, border_radius=5)

			# Tab text
			text_color = COLOR_TEXT if tab.active else (140, 140, 140)
			text_surf = self.font.render(tab.name, True, text_color)
			text_rect = text_surf.get_rect(center=tab_rect.center)
			self.screen.blit(text_surf, text_rect)

			# Keyboard shortcut hint
			shortcut = f"Ctrl+{i+1}"
			shortcut_surf = self.small_font.render(shortcut, True, (100, 100, 100))
			self.screen.blit(shortcut_surf, (tab_x + 5, 5))

			tab_x += tab_width + 10

	def _draw_browser_tab(self, content: dict):
		"""Draw browser tab"""
		content['search_panel'].draw(self.screen, self.font)
		content['list_view'].draw(self.screen, self.font)
		content['detail_view'].draw(self.screen, self.font, self.small_font)

	def _draw_editor_tab(self, content: dict):
		"""Draw editor tab"""
		content['panel'].draw(self.screen, self.font, self.small_font)

	def _draw_scripts_tab(self, content: dict):
		"""Draw scripts tab"""
		# Editor
		content['editor'].draw(self.screen, self.font)

		# Flowchart
		if content['script']:
			content['flowchart'].draw(self.screen, self.small_font)

		# Instructions
		inst_y = WINDOW_HEIGHT - 100
		instructions = [
			"Event Script Editor",
			"Type script commands on the left",
			"Press Ctrl+B to build flowchart",
			"See DIALOG_EDITOR_GUIDE.md for command reference"
		]

		for i, inst in enumerate(instructions):
			inst_surf = self.small_font.render(inst, True, (140, 140, 140))
			self.screen.blit(inst_surf, (20, inst_y + i * 18))

	def _draw_preview_tab(self, content: dict):
		"""Draw preview tab"""
		# Title
		title = "Dialog Preview"
		title_surf = self.large_font.render(title, True, COLOR_TEXT)
		title_rect = title_surf.get_rect(center=(WINDOW_WIDTH // 2, 80))
		self.screen.blit(title_surf, title_rect)

		# Preview
		content['preview'].draw(self.screen, self.font)

		# Play button
		button_rect = content['controls']
		button_text = "Replay" if content['playing'] else "Play"

		pygame.draw.rect(self.screen, (60, 120, 180), button_rect, border_radius=5)
		pygame.draw.rect(self.screen, COLOR_BORDER, button_rect, width=2, border_radius=5)

		btn_surf = self.font.render(button_text, True, COLOR_TEXT)
		btn_rect = btn_surf.get_rect(center=button_rect.center)
		self.screen.blit(btn_surf, btn_rect)

		# Instructions
		inst = "Click Play to preview the current dialog from the Editor tab"
		inst_surf = self.small_font.render(inst, True, (140, 140, 140))
		inst_rect = inst_surf.get_rect(center=(WINDOW_WIDTH // 2, button_rect.bottom + 30))
		self.screen.blit(inst_surf, inst_rect)

	def _draw_export_tab(self, content: dict):
		"""Draw export tab"""
		# Title
		title = "Export / Import Tools"
		title_surf = self.title_font.render(title, True, COLOR_TEXT)
		self.screen.blit(title_surf, (50, 50))

		# Buttons
		mouse_pos = pygame.mouse.get_pos()

		button_labels = {
			'export_json': 'Export JSON',
			'export_csv': 'Export CSV',
			'export_po': 'Export PO',
			'import': 'Import',
			'validate': 'Validate All'
		}

		for name, rect in content['buttons'].items():
			hovered = rect.collidepoint(mouse_pos)
			color = (80, 140, 200) if hovered else (60, 120, 180)

			pygame.draw.rect(self.screen, color, rect, border_radius=5)
			pygame.draw.rect(self.screen, COLOR_BORDER, rect, width=2, border_radius=5)

			btn_surf = self.font.render(button_labels[name], True, COLOR_TEXT)
			btn_rect = btn_surf.get_rect(center=rect.center)
			self.screen.blit(btn_surf, btn_rect)

		# Status
		if content['status']:
			status_surf = self.font.render(content['status'], True, COLOR_TEXT)
			self.screen.blit(status_surf, (50, 300))

		# Info
		info_lines = [
			"Export formats:",
			"  • JSON - Best for version control and detailed editing",
			"  • CSV - Excel-compatible spreadsheet format",
			"  • PO - Gettext format for translation tools",
			"",
			"Export creates files in the current directory.",
			"See DIALOG_EDITOR_GUIDE.md for complete documentation."
		]

		y = 400
		for line in info_lines:
			line_surf = self.small_font.render(line, True, (140, 140, 140))
			self.screen.blit(line_surf, (50, y))
			y += 20

	def _draw_status_bar(self):
		"""Draw status bar"""
		status_y = WINDOW_HEIGHT - 25
		pygame.draw.rect(self.screen, COLOR_PANEL_BG, (0, status_y, WINDOW_WIDTH, 25))
		pygame.draw.line(self.screen, COLOR_BORDER, (0, status_y), (WINDOW_WIDTH, status_y))

		# Status text
		total_dialogs = len(self.database.dialogs)
		modified = self.database.get_modified_count()

		status_text = f"Total Dialogs: {total_dialogs} | Modified: {modified} | Tab: {self.tabs[self.current_tab].name}"
		status_surf = self.small_font.render(status_text, True, COLOR_TEXT)
		self.screen.blit(status_surf, (10, status_y + 6))

		# FPS
		fps_text = f"FPS: {int(self.clock.get_fps())}"
		fps_surf = self.small_font.render(fps_text, True, (100, 100, 100))
		self.screen.blit(fps_surf, (WINDOW_WIDTH - 80, status_y + 6))


def main():
	"""Main entry point"""
	print("="* 60)
	print("FFMQ Dialog Editor - Complete Example Application")
	print("=" * 60)
	print()
	print("Controls:")
	print("  Ctrl+1-5: Switch tabs")
	print("  Ctrl+S: Save (in Editor tab)")
	print("  Ctrl+P: Preview (in Editor tab)")
	print("  Ctrl+B: Build flowchart (in Scripts tab)")
	print("  Tab: Autocomplete (in text editors)")
	print()
	print("Tabs:")
	print("  1. Browser - Browse and search all dialogs")
	print("  2. Editor - Edit dialog text with syntax highlighting")
	print("  3. Scripts - Write and visualize event scripts")
	print("  4. Preview - Preview dialogs with FFMQ-style box")
	print("  5. Export - Export/import for translation")
	print()
	print("Starting application...")
	print("=" * 60)
	print()

	try:
		app = DialogEditorApp()
		app.run()
	except Exception as e:
		print(f"Error: {e}")
		import traceback
		traceback.print_exc()

	print()
	print("Application closed.")


if __name__ == '__main__':
	main()
