"""
FFMQ Dialog Suite - Comprehensive dialog editing application

Integrates all dialog editing tools into a single application:
- Dialog browser and editor
- Character table optimizer and editor
- NPC dialog manager
- Search and replace
- Translation tools
- Batch editing
- Flow visualization
"""

import pygame
import sys
from pathlib import Path
from typing import Optional

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from ui.tab_system import TabbedPanel, Tab
from ui.dialog_browser import DialogBrowser
from ui.character_table_editor import CharacterTableEditor
from utils.dialog_database import DialogDatabase
from utils.npc_dialog_manager import NPCDialogManager
from utils.dialog_search import DialogSearchEngine
from utils.translation_helper import TranslationProject
from utils.batch_dialog_editor import BatchDialogEditor
from utils.character_table_optimizer import CharacterTableOptimizer


# Colors
COLOR_BG = (25, 25, 35)
COLOR_PANEL = (35, 35, 45)
COLOR_TEXT = (220, 220, 220)
COLOR_TEXT_DIM = (140, 140, 150)
COLOR_ACCENT = (70, 130, 180)


class WelcomePanel:
	"""Welcome screen with quick actions"""

	def __init__(self, rect: pygame.Rect):
		self.rect = rect
		self.bg_color = COLOR_PANEL
		self.text_color = COLOR_TEXT

	def handle_event(self, event: pygame.event.Event) -> bool:
		return False

	def update(self, dt: float):
		pass

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		# Background
		pygame.draw.rect(surface, self.bg_color, self.rect)

		# Title
		title_font = pygame.font.Font(None, 48)
		title = title_font.render("FFMQ Dialog Suite", True, COLOR_ACCENT)
		title_rect = title.get_rect(centerx=self.rect.centerx, top=self.rect.y + 50)
		surface.blit(title, title_rect)

		# Subtitle
		subtitle = font.render("Professional Dialog Editing for Final Fantasy Mystic Quest", True, self.text_color)
		subtitle_rect = subtitle.get_rect(centerx=self.rect.centerx, top=title_rect.bottom + 10)
		surface.blit(subtitle, subtitle_rect)

		# Feature list
		y = subtitle_rect.bottom + 50
		features = [
			"📝 Browse and Edit Dialogs",
			"🔤 Optimize Character Table Compression",
			"👥 Manage NPC Conversations",
			"🔍 Advanced Search and Replace",
			"🌍 Translation Tools and Memory",
			"⚙️  Batch Editing Operations",
			"📊 Visualize Conversation Flow",
			"📈 Text Statistics and Analysis",
		]

		for feature in features:
			text = font.render(feature, True, self.text_color)
			text_rect = text.get_rect(centerx=self.rect.centerx, top=y)
			surface.blit(text, text_rect)
			y += 35

		# Instructions
		y += 30
		instructions = [
			"Use Ctrl+1-7 to switch tabs",
			"Press F1 for help",
			"Press F11 for fullscreen",
		]

		for instruction in instructions:
			text = font.render(instruction, True, COLOR_TEXT_DIM)
			text_rect = text.get_rect(centerx=self.rect.centerx, top=y)
			surface.blit(text, text_rect)
			y += 25


class StatisticsPanel:
	"""Statistics and analysis panel"""

	def __init__(self, rect: pygame.Rect, batch_editor: BatchDialogEditor, dialog_db: DialogDatabase):
		self.rect = rect
		self.batch_editor = batch_editor
		self.dialog_db = dialog_db
		self.bg_color = COLOR_PANEL
		self.stats = None
		self.errors = None

	def refresh_stats(self):
		"""Refresh statistics"""
		if self.dialog_db and self.dialog_db.dialogs:
			self.stats = self.batch_editor.analyze_text_statistics(self.dialog_db.dialogs)
			self.errors = self.batch_editor.find_potential_errors(self.dialog_db.dialogs)

	def handle_event(self, event: pygame.event.Event) -> bool:
		if event.type == pygame.KEYDOWN:
			if event.key == pygame.K_F5:  # Refresh
				self.refresh_stats()
				return True
		return False

	def update(self, dt: float):
		pass

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		# Background
		pygame.draw.rect(surface, self.bg_color, self.rect)

		if not self.stats:
			self.refresh_stats()

		if not self.stats:
			text = font.render("No dialogs loaded", True, COLOR_TEXT_DIM)
			text_rect = text.get_rect(center=self.rect.center)
			surface.blit(text, text_rect)
			return

		# Title
		title = font.render("Dialog Statistics", True, COLOR_TEXT)
		surface.blit(title, (self.rect.x + 20, self.rect.y + 20))

		# Statistics
		y = self.rect.y + 60
		stats_lines = [
			f"Total Dialogs: {self.stats['total_dialogs']}",
			f"Total Characters: {self.stats['total_characters']}",
			f"Total Words: {self.stats['total_words']}",
			f"Average Length: {self.stats['average_length']:.1f} chars",
			f"Average Words: {self.stats['average_words']:.1f}",
			f"Min Length: {self.stats['min_length']} chars",
			f"Max Length: {self.stats['max_length']} chars",
			f"Unique Words: {self.stats['unique_words']}",
			"",
			"Most Common Words:",
		]

		for line in stats_lines:
			text = font.render(line, True, self.text_color)
			surface.blit(text, (self.rect.x + 30, y))
			y += 25

		# Top words
		for word, count in self.stats['most_common_words'][:10]:
			text = font.render(f"  {word}: {count}", True, COLOR_TEXT_DIM)
			surface.blit(text, (self.rect.x + 40, y))
			y += 22

		# Errors
		y += 20
		error_title = font.render(f"Potential Errors: {len(self.errors)}", True, (220, 80, 80) if self.errors else (80, 200, 120))
		surface.blit(error_title, (self.rect.x + 30, y))
		y += 30

		if self.errors:
			shown = 0
			for dialog_id, issues in sorted(self.errors.items())[:10]:
				text = font.render(f"Dialog 0x{dialog_id:04X}:", True, self.text_color)
				surface.blit(text, (self.rect.x + 40, y))
				y += 22

				for issue in issues[:3]:  # Show max 3 issues per dialog
					text = font.render(f"  • {issue}", True, COLOR_TEXT_DIM)
					surface.blit(text, (self.rect.x + 50, y))
					y += 20

				shown += 1
				if shown >= 5:  # Show max 5 dialogs
					break

		# Refresh hint
		hint = font.render("Press F5 to refresh", True, COLOR_TEXT_DIM)
		surface.blit(hint, (self.rect.x + 30, self.rect.bottom - 40))


class OptimizerPanel:
	"""Character table optimizer panel"""

	def __init__(self, rect: pygame.Rect, optimizer: CharacterTableOptimizer, dialog_db: DialogDatabase):
		self.rect = rect
		self.optimizer = optimizer
		self.dialog_db = dialog_db
		self.bg_color = COLOR_PANEL
		self.candidates = []
		self.scroll_offset = 0
		self.max_scroll = 0

	def run_optimization(self):
		"""Run optimization on loaded dialogs"""
		if not self.dialog_db or not self.dialog_db.dialogs:
			return

		# Extract dialog texts
		texts = [dialog.text for dialog in self.dialog_db.dialogs.values()]

		# Run optimizer
		self.candidates = self.optimizer.analyze_corpus(texts)
		self.max_scroll = max(0, len(self.candidates) * 25 - (self.rect.height - 100))

	def handle_event(self, event: pygame.event.Event) -> bool:
		if event.type == pygame.KEYDOWN:
			if event.key == pygame.K_F5:  # Run optimization
				self.run_optimization()
				return True

		if event.type == pygame.MOUSEWHEEL:
			if self.rect.collidepoint(pygame.mouse.get_pos()):
				self.scroll_offset -= event.y * 20
				self.scroll_offset = max(0, min(self.scroll_offset, self.max_scroll))
				return True

		return False

	def update(self, dt: float):
		pass

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		# Background
		pygame.draw.rect(surface, self.bg_color, self.rect)

		# Title
		title = font.render("Character Table Optimizer", True, COLOR_TEXT)
		surface.blit(title, (self.rect.x + 20, self.rect.y + 20))

		if not self.candidates:
			hint = font.render("Press F5 to run optimization", True, COLOR_TEXT_DIM)
			hint_rect = hint.get_rect(center=self.rect.center)
			surface.blit(hint, hint_rect)
			return

		# Results
		y = self.rect.y + 60 - self.scroll_offset
		result_text = font.render(f"Found {len(self.candidates)} candidates", True, COLOR_ACCENT)
		surface.blit(result_text, (self.rect.x + 30, self.rect.y + 60))

		y = self.rect.y + 90

		# Create clipping surface
		clip_rect = pygame.Rect(self.rect.x, y, self.rect.width, self.rect.height - 90)
		surface.set_clip(clip_rect)

		y -= self.scroll_offset

		# List candidates
		for i, candidate in enumerate(self.candidates[:50], 1):
			seq_display = candidate.sequence.replace(' ', '·').replace('\n', '\\n')
			text = font.render(
				f"{i:2}. '{seq_display}' - {candidate.byte_savings} bytes saved (freq: {candidate.frequency})",
				True,
				self.text_color
			)
			surface.blit(text, (self.rect.x + 40, y))
			y += 25

		surface.set_clip(None)

		# Scrollbar
		if self.max_scroll > 0:
			scrollbar_height = max(20, (self.rect.height - 100) * (self.rect.height - 100) // (len(self.candidates) * 25))
			scrollbar_y = self.rect.y + 90 + (self.rect.height - 100 - scrollbar_height) * self.scroll_offset // self.max_scroll
			scrollbar_rect = pygame.Rect(self.rect.right - 10, scrollbar_y, 6, scrollbar_height)
			pygame.draw.rect(surface, COLOR_ACCENT, scrollbar_rect, border_radius=3)


class DialogSuiteApp:
	"""Main dialog suite application"""

	def __init__(self):
		pygame.init()

		# Window setup
		self.width = 1600
		self.height = 900
		self.screen = pygame.display.set_mode((self.width, self.height), pygame.RESIZABLE)
		pygame.display.set_caption("FFMQ Dialog Suite")

		self.clock = pygame.time.Clock()
		self.running = True
		self.fullscreen = False

		# Fonts
		self.font = pygame.font.Font(None, 24)
		self.font_small = pygame.font.Font(None, 20)

		# Initialize components
		self.dialog_db = DialogDatabase()
		self.npc_manager = NPCDialogManager()
		self.search_engine = DialogSearchEngine()
		self.translation_project = TranslationProject()
		self.batch_editor = BatchDialogEditor()
		self.optimizer = CharacterTableOptimizer()

		# Create tabbed interface
		self.create_tabs()

	def create_tabs(self):
		"""Create the tabbed interface"""
		panel_rect = pygame.Rect(0, 0, self.width, self.height)
		self.tabbed_panel = TabbedPanel(panel_rect, tab_height=45)

		# Create panels
		content_rect = self.tabbed_panel.content_rect

		welcome_panel = WelcomePanel(content_rect)
		stats_panel = StatisticsPanel(content_rect, self.batch_editor, self.dialog_db)
		optimizer_panel = OptimizerPanel(content_rect, self.optimizer, self.dialog_db)

		# Add tabs
		self.tabbed_panel.add_tab(
			Tab("welcome", "Welcome", "🏠", True, "Welcome screen"),
			welcome_panel
		)

		self.tabbed_panel.add_tab(
			Tab("browse", "Browser", "📖", True, "Browse and search dialogs"),
			None  # DialogBrowser would go here
		)

		self.tabbed_panel.add_tab(
			Tab("stats", "Statistics", "📊", True, "Text statistics and analysis"),
			stats_panel
		)

		self.tabbed_panel.add_tab(
			Tab("optimizer", "Optimizer", "🔤", True, "Character table optimization"),
			optimizer_panel
		)

		self.tabbed_panel.add_tab(
			Tab("npc", "NPCs", "👥", True, "NPC dialog management"),
			None  # NPCDialogPanel would go here
		)

		self.tabbed_panel.add_tab(
			Tab("translate", "Translation", "🌍", True, "Translation tools"),
			None  # Translation panel would go here
		)

		self.tabbed_panel.add_tab(
			Tab("flow", "Flow", "📈", True, "Dialog flow visualization"),
			None  # Flow visualizer would go here
		)

	def handle_events(self):
		"""Handle pygame events"""
		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				self.running = False

			elif event.type == pygame.VIDEORESIZE:
				self.width = event.w
				self.height = event.h
				self.create_tabs()  # Recreate with new size

			elif event.type == pygame.KEYDOWN:
				if event.key == pygame.K_F11:
					# Toggle fullscreen
					self.fullscreen = not self.fullscreen
					if self.fullscreen:
						self.screen = pygame.display.set_mode((0, 0), pygame.FULLSCREEN)
						self.width = self.screen.get_width()
						self.height = self.screen.get_height()
					else:
						self.screen = pygame.display.set_mode((1600, 900), pygame.RESIZABLE)
						self.width = 1600
						self.height = 900
					self.create_tabs()

				elif event.key == pygame.K_ESCAPE and self.fullscreen:
					# Exit fullscreen
					self.fullscreen = False
					self.screen = pygame.display.set_mode((1600, 900), pygame.RESIZABLE)
					self.width = 1600
					self.height = 900
					self.create_tabs()

			# Let tabbed panel handle events
			self.tabbed_panel.handle_event(event)

	def update(self, dt: float):
		"""Update game state"""
		self.tabbed_panel.update(dt)

	def draw(self):
		"""Draw everything"""
		self.screen.fill(COLOR_BG)

		# Draw tabbed panel
		self.tabbed_panel.draw(self.screen, self.font)

		# Draw status bar at bottom
		self.draw_status_bar()

		pygame.display.flip()

	def draw_status_bar(self):
		"""Draw status bar at bottom"""
		status_height = 30
		status_rect = pygame.Rect(0, self.height - status_height, self.width, status_height)
		pygame.draw.rect(self.screen, (20, 20, 30), status_rect)
		pygame.draw.line(self.screen, (60, 60, 70),
						 (0, self.height - status_height),
						 (self.width, self.height - status_height))

		# Active tab
		active_tab = self.tabbed_panel.tab_bar.get_active_tab()
		status_text = f"Active: {active_tab.title}"

		# Dialog count
		if self.dialog_db and self.dialog_db.dialogs:
			status_text += f" | Dialogs: {len(self.dialog_db.dialogs)}"

		# FPS
		fps = int(self.clock.get_fps())
		status_text += f" | FPS: {fps}"

		text = self.font_small.render(status_text, True, COLOR_TEXT_DIM)
		self.screen.blit(text, (10, self.height - 25))

		# Version
		version_text = "FFMQ Dialog Suite v1.0"
		version = self.font_small.render(version_text, True, COLOR_TEXT_DIM)
		version_rect = version.get_rect(right=self.width - 10, centery=self.height - 15)
		self.screen.blit(version, version_rect)

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
	app = DialogSuiteApp()
	app.run()


if __name__ == '__main__':
	main()
