"""
FFMQ Comprehensive Game Editor

Unified editor bringing together all game data editing:
- Maps and Tilesets
- Dialogs and Events
- Enemies and Formations
- Spells and Magic
- Items and Equipment
- Dungeon Encounters

Provides a complete, professional-grade editing suite.
"""

import pygame
import sys
from pathlib import Path
from typing import Optional, Dict, List, Tuple, Any

# Add parent to path
sys.path.insert(0, str(Path(__file__).parent))

from utils.dialog_database import DialogDatabase
from utils.enemy_database import EnemyDatabase
from utils.spell_database import SpellDatabase
from utils.item_database import ItemDatabase
from utils.dungeon_map import DungeonMapDatabase

# UI panels (would import these)
# from ui.enemy_editor import EnemyEditorPanel
# from ui.dialog_editor import DialogEditorPanel
# etc.


# Colors
COLOR_BG = (25, 25, 35)
COLOR_PANEL = (40, 40, 50)
COLOR_BORDER = (60, 60, 70)
COLOR_TEXT = (220, 220, 220)
COLOR_LABEL = (140, 140, 150)
COLOR_HIGHLIGHT = (70, 110, 190)
COLOR_TAB_ACTIVE = (60, 100, 180)
COLOR_TAB_INACTIVE = (45, 45, 55)
COLOR_BUTTON = (60, 100, 180)
COLOR_BUTTON_HOVER = (80, 130, 220)
COLOR_SUCCESS = (80, 255, 120)
COLOR_WARNING = (255, 165, 0)
COLOR_ERROR = (255, 80, 80)


class Tab:
	"""Tab button"""
	
	def __init__(self, x: int, y: int, width: int, height: int, text: str, tab_id: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.text = text
		self.tab_id = tab_id
		self.active = False
		self.hover = False
	
	def handle_event(self, event: pygame.event.Event) -> bool:
		"""Handle input events"""
		if event.type == pygame.MOUSEMOTION:
			self.hover = self.rect.collidepoint(event.pos)
		elif event.type == pygame.MOUSEBUTTONDOWN:
			if self.rect.collidepoint(event.pos):
				return True
		return False
	
	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw the tab"""
		if self.active:
			color = COLOR_TAB_ACTIVE
			text_color = COLOR_TEXT
		elif self.hover:
			color = COLOR_BUTTON_HOVER
			text_color = COLOR_TEXT
		else:
			color = COLOR_TAB_INACTIVE
			text_color = COLOR_LABEL
		
		pygame.draw.rect(surface, color, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 1)
		
		text_surf = font.render(self.text, True, text_color)
		text_x = self.rect.x + (self.rect.width - text_surf.get_width()) // 2
		text_y = self.rect.y + (self.rect.height - text_surf.get_height()) // 2
		surface.blit(text_surf, (text_x, text_y))


class Button:
	"""Simple button"""
	
	def __init__(self, x: int, y: int, width: int, height: int, text: str):
		self.rect = pygame.Rect(x, y, width, height)
		self.text = text
		self.hover = False
		self.enabled = True
	
	def handle_event(self, event: pygame.event.Event) -> bool:
		"""Handle input events"""
		if not self.enabled:
			return False
		
		if event.type == pygame.MOUSEMOTION:
			self.hover = self.rect.collidepoint(event.pos)
		elif event.type == pygame.MOUSEBUTTONDOWN:
			if self.rect.collidepoint(event.pos):
				return True
		return False
	
	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw the button"""
		if not self.enabled:
			color = (40, 40, 40)
			text_color = (80, 80, 80)
		elif self.hover:
			color = COLOR_BUTTON_HOVER
			text_color = COLOR_TEXT
		else:
			color = COLOR_BUTTON
			text_color = COLOR_TEXT
		
		pygame.draw.rect(surface, color, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 1)
		
		text_surf = font.render(self.text, True, text_color)
		text_x = self.rect.x + (self.rect.width - text_surf.get_width()) // 2
		text_y = self.rect.y + (self.rect.height - text_surf.get_height()) // 2
		surface.blit(text_surf, (text_x, text_y))


class StatusBar:
	"""Status bar at bottom of window"""
	
	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.message = "Ready"
		self.message_color = COLOR_TEXT
		self.timer = 0
	
	def set_message(self, message: str, color: Tuple[int, int, int] = COLOR_TEXT, duration: int = 180):
		"""Set status message"""
		self.message = message
		self.message_color = color
		self.timer = duration
	
	def update(self):
		"""Update status bar"""
		if self.timer > 0:
			self.timer -= 1
			if self.timer == 0:
				self.message = "Ready"
				self.message_color = COLOR_TEXT
	
	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw status bar"""
		pygame.draw.rect(surface, COLOR_PANEL, self.rect)
		pygame.draw.line(surface, COLOR_BORDER, 
						(self.rect.x, self.rect.y),
						(self.rect.right, self.rect.y), 2)
		
		text_surf = font.render(self.message, True, self.message_color)
		surface.blit(text_surf, (self.rect.x + 10, self.rect.y + 10))


class GameEditor:
	"""
	Comprehensive FFMQ Game Editor
	
	Provides unified interface for editing all game data.
	"""
	
	def __init__(self, width: int = 1400, height: int = 900):
		"""Initialize the game editor"""
		pygame.init()
		
		self.screen = pygame.display.set_mode((width, height))
		pygame.display.set_caption("FFMQ Comprehensive Game Editor")
		
		self.width = width
		self.height = height
		self.clock = pygame.time.Clock()
		self.running = True
		
		# Fonts
		self.font = pygame.font.Font(None, 20)
		self.title_font = pygame.font.Font(None, 32)
		self.small_font = pygame.font.Font(None, 16)
		
		# ROM path
		self.rom_path: Optional[str] = None
		self.rom_loaded = False
		
		# Databases
		self.dialog_db = DialogDatabase()
		self.enemy_db = EnemyDatabase()
		self.spell_db = SpellDatabase()
		self.item_db = ItemDatabase()
		self.dungeon_db = DungeonMapDatabase()
		
		# Current tab
		self.current_tab = 0
		
		# Create tabs
		tab_width = 120
		tab_height = 40
		tab_y = 50
		self.tabs: List[Tab] = []
		
		tab_names = [
			"Maps",
			"Dialogs",
			"Enemies",
			"Spells",
			"Items",
			"Dungeons",
			"Events",
			"Settings"
		]
		
		for i, name in enumerate(tab_names):
			tab = Tab(10 + i * (tab_width + 5), tab_y, tab_width, tab_height, name, i)
			if i == 0:
				tab.active = True
			self.tabs.append(tab)
		
		# Content area
		self.content_rect = pygame.Rect(10, 100, width - 20, height - 170)
		
		# Toolbar buttons
		button_y = 10
		self.load_button = Button(10, button_y, 100, 30, "Load ROM")
		self.save_button = Button(120, button_y, 100, 30, "Save ROM")
		self.export_button = Button(230, button_y, 100, 30, "Export")
		self.import_button = Button(340, button_y, 100, 30, "Import")
		
		self.save_button.enabled = False
		self.export_button.enabled = False
		self.import_button.enabled = False
		
		# Status bar
		self.status_bar = StatusBar(0, height - 60, width, 60)
		
		# Stats display
		self.show_stats = True
		self.stats_data: Dict[str, Any] = {}
	
	def load_rom(self, rom_path: str):
		"""Load ROM file and all databases"""
		try:
			self.rom_path = rom_path
			
			# Load all databases
			self.status_bar.set_message("Loading dialogs...", COLOR_TEXT)
			self.dialog_db.load_from_rom(rom_path)
			
			self.status_bar.set_message("Loading enemies...", COLOR_TEXT)
			self.enemy_db.load_from_rom(rom_path)
			
			self.status_bar.set_message("Loading spells...", COLOR_TEXT)
			self.spell_db.load_from_rom(rom_path)
			
			self.status_bar.set_message("Loading items...", COLOR_TEXT)
			self.item_db.load_from_rom(rom_path)
			
			self.status_bar.set_message("Loading dungeons...", COLOR_TEXT)
			self.dungeon_db.load_from_rom(rom_path)
			
			self.rom_loaded = True
			self.save_button.enabled = True
			self.export_button.enabled = True
			self.import_button.enabled = True
			
			# Update stats
			self.update_stats()
			
			self.status_bar.set_message(f"ROM loaded: {Path(rom_path).name}", COLOR_SUCCESS)
			
		except Exception as e:
			self.status_bar.set_message(f"Error loading ROM: {e}", COLOR_ERROR, 300)
			self.rom_loaded = False
	
	def save_rom(self):
		"""Save all changes to ROM"""
		if not self.rom_path:
			self.status_bar.set_message("No ROM loaded", COLOR_ERROR)
			return
		
		try:
			output_path = str(Path(self.rom_path).with_stem(Path(self.rom_path).stem + "_modified"))
			
			# Save all databases
			self.status_bar.set_message("Saving dialogs...", COLOR_TEXT)
			self.dialog_db.save_to_rom(output_path)
			
			self.status_bar.set_message("Saving enemies...", COLOR_TEXT)
			self.enemy_db.save_to_rom(output_path)
			
			self.status_bar.set_message("Saving spells...", COLOR_TEXT)
			self.spell_db.save_to_rom(output_path)
			
			self.status_bar.set_message("Saving items...", COLOR_TEXT)
			self.item_db.save_to_rom(output_path)
			
			self.status_bar.set_message(f"ROM saved: {Path(output_path).name}", COLOR_SUCCESS)
			
		except Exception as e:
			self.status_bar.set_message(f"Error saving ROM: {e}", COLOR_ERROR, 300)
	
	def update_stats(self):
		"""Update statistics display"""
		self.stats_data = {
			'dialogs': len(self.dialog_db.dialogs),
			'enemies': len(self.enemy_db.enemies),
			'spells': len(self.spell_db.spells),
			'items': len(self.item_db.items),
			'dungeons': len(self.dungeon_db.dungeons),
		}
	
	def handle_events(self):
		"""Handle all events"""
		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				self.running = False
			
			# Toolbar buttons
			if self.load_button.handle_event(event):
				# In real implementation, would open file dialog
				# For now, use hardcoded path
				test_rom = "ffmq.smc"
				if Path(test_rom).exists():
					self.load_rom(test_rom)
				else:
					self.status_bar.set_message("ROM not found: " + test_rom, COLOR_ERROR)
			
			if self.save_button.handle_event(event):
				self.save_rom()
			
			if self.export_button.handle_event(event):
				self.export_data()
			
			if self.import_button.handle_event(event):
				self.import_data()
			
			# Tabs
			for tab in self.tabs:
				if tab.handle_event(event):
					# Switch tab
					for t in self.tabs:
						t.active = False
					tab.active = True
					self.current_tab = tab.tab_id
			
			# Keyboard shortcuts
			if event.type == pygame.KEYDOWN:
				if event.key == pygame.K_s and pygame.key.get_mods() & pygame.KMOD_CTRL:
					self.save_rom()
				elif event.key == pygame.K_o and pygame.key.get_mods() & pygame.KMOD_CTRL:
					pass  # Open ROM
				elif event.key == pygame.K_F1:
					self.show_stats = not self.show_stats
				# Tab switching with Ctrl+1-8
				elif event.key in range(pygame.K_1, pygame.K_9):
					if pygame.key.get_mods() & pygame.KMOD_CTRL:
						tab_num = event.key - pygame.K_1
						if tab_num < len(self.tabs):
							for t in self.tabs:
								t.active = False
							self.tabs[tab_num].active = True
							self.current_tab = tab_num
	
	def export_data(self):
		"""Export current tab data"""
		try:
			if self.current_tab == 1:  # Dialogs
				self.dialog_db.export_to_json("export_dialogs.json")
				self.status_bar.set_message("Dialogs exported to export_dialogs.json", COLOR_SUCCESS)
			elif self.current_tab == 2:  # Enemies
				self.enemy_db.export_to_json("export_enemies.json")
				self.status_bar.set_message("Enemies exported to export_enemies.json", COLOR_SUCCESS)
			elif self.current_tab == 3:  # Spells
				self.spell_db.export_to_json("export_spells.json")
				self.status_bar.set_message("Spells exported to export_spells.json", COLOR_SUCCESS)
			elif self.current_tab == 4:  # Items
				self.item_db.export_to_json("export_items.json")
				self.status_bar.set_message("Items exported to export_items.json", COLOR_SUCCESS)
			else:
				self.status_bar.set_message("Export not available for this tab", COLOR_WARNING)
		except Exception as e:
			self.status_bar.set_message(f"Export error: {e}", COLOR_ERROR, 300)
	
	def import_data(self):
		"""Import data"""
		self.status_bar.set_message("Import not yet implemented", COLOR_WARNING)
	
	def update(self):
		"""Update game state"""
		self.status_bar.update()
	
	def draw_content(self):
		"""Draw current tab content"""
		# Draw content area background
		pygame.draw.rect(self.screen, COLOR_PANEL, self.content_rect)
		pygame.draw.rect(self.screen, COLOR_BORDER, self.content_rect, 2)
		
		# Draw tab-specific content
		tab_title = self.tabs[self.current_tab].text
		title_surf = self.title_font.render(f"{tab_title} Editor", True, COLOR_TEXT)
		self.screen.blit(title_surf, (self.content_rect.x + 20, self.content_rect.y + 20))
		
		# Draw stats if enabled
		if self.show_stats and self.rom_loaded:
			y = self.content_rect.y + 70
			
			stats_to_show = []
			if self.current_tab == 1:  # Dialogs
				stats_to_show = [
					f"Total Dialogs: {self.stats_data.get('dialogs', 0)}",
					f"Modified: {sum(1 for d in self.dialog_db.dialogs.values() if d.modified)}"
				]
			elif self.current_tab == 2:  # Enemies
				stats_to_show = [
					f"Total Enemies: {self.stats_data.get('enemies', 0)}",
					f"Bosses: {len(self.enemy_db.get_bosses())}",
					f"Modified: {sum(1 for e in self.enemy_db.enemies.values() if e.modified)}"
				]
			elif self.current_tab == 3:  # Spells
				stats_to_show = [
					f"Total Spells: {self.stats_data.get('spells', 0)}",
					f"Offensive: {len(self.spell_db.get_offensive_spells())}",
					f"Healing: {len(self.spell_db.get_healing_spells())}",
					f"Modified: {sum(1 for s in self.spell_db.spells.values() if s.modified)}"
				]
			elif self.current_tab == 4:  # Items
				stats_to_show = [
					f"Total Items: {self.stats_data.get('items', 0)}",
					f"Weapons: {len(self.item_db.get_weapons())}",
					f"Armor: {len(self.item_db.get_armor())}",
					f"Consumables: {len(self.item_db.get_consumables())}",
					f"Modified: {sum(1 for i in self.item_db.items.values() if i.modified)}"
				]
			
			for stat_line in stats_to_show:
				stat_surf = self.font.render(stat_line, True, COLOR_LABEL)
				self.screen.blit(stat_surf, (self.content_rect.x + 30, y))
				y += 25
		
		# Draw placeholder text
		if not self.rom_loaded:
			text_surf = self.font.render("Load a ROM to begin editing", True, COLOR_LABEL)
			self.screen.blit(text_surf, (
				self.content_rect.centerx - text_surf.get_width() // 2,
				self.content_rect.centery - text_surf.get_height() // 2
			))
	
	def draw(self):
		"""Draw everything"""
		self.screen.fill(COLOR_BG)
		
		# Draw toolbar buttons
		self.load_button.draw(self.screen, self.font)
		self.save_button.draw(self.screen, self.font)
		self.export_button.draw(self.screen, self.font)
		self.import_button.draw(self.screen, self.font)
		
		# Draw ROM name
		if self.rom_path:
			rom_text = f"ROM: {Path(self.rom_path).name}"
			rom_surf = self.small_font.render(rom_text, True, COLOR_LABEL)
			self.screen.blit(rom_surf, (self.width - rom_surf.get_width() - 10, 15))
		
		# Draw tabs
		for tab in self.tabs:
			tab.draw(self.screen, self.font)
		
		# Draw content
		self.draw_content()
		
		# Draw status bar
		self.status_bar.draw(self.screen, self.font)
		
		# Draw keyboard hints
		hint_text = "F1: Toggle Stats | Ctrl+S: Save | Ctrl+1-8: Switch Tabs"
		hint_surf = self.small_font.render(hint_text, True, COLOR_LABEL)
		self.screen.blit(hint_surf, (10, self.height - 75))
		
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
	"""Main entry point"""
	import sys
	
	editor = GameEditor()
	
	# Load ROM if provided as argument
	if len(sys.argv) > 1:
		editor.load_rom(sys.argv[1])
	
	editor.run()


if __name__ == '__main__':
	main()
