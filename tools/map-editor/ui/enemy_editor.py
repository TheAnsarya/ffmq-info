"""
FFMQ Enemy Editor UI

Comprehensive enemy editor with stats, AI, drops, resistances, and sprite preview.
Provides a complete interface for editing all enemy data.
"""

import pygame
from typing import Optional, List, Tuple, Dict, Any
from dataclasses import asdict

import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))

from utils.enemy_data import (
	Enemy, EnemyStats, EnemyFlags, ResistanceData, ItemDrop, AIScript,
	SpriteInfo, ElementType, AIBehavior
)
from utils.enemy_database import EnemyDatabase


# Colors
COLOR_BG = (30, 30, 40)
COLOR_PANEL = (45, 45, 55)
COLOR_BORDER = (70, 70, 80)
COLOR_TEXT = (220, 220, 220)
COLOR_LABEL = (150, 150, 160)
COLOR_HIGHLIGHT = (80, 120, 200)
COLOR_BUTTON = (60, 100, 180)
COLOR_BUTTON_HOVER = (80, 130, 220)
COLOR_WARNING = (255, 165, 0)
COLOR_ERROR = (255, 80, 80)
COLOR_SUCCESS = (80, 255, 120)

# Element colors
ELEMENT_COLORS = {
	ElementType.FIRE: (255, 80, 40),
	ElementType.WATER: (40, 120, 255),
	ElementType.EARTH: (160, 100, 40),
	ElementType.WIND: (120, 255, 120),
	ElementType.HOLY: (255, 255, 120),
	ElementType.DARK: (120, 40, 160),
	ElementType.POISON: (160, 40, 200),
}


class NumericInput:
	"""Numeric input field with increment/decrement buttons"""
	
	def __init__(self, x: int, y: int, width: int, min_val: int = 0, max_val: int = 9999):
		self.rect = pygame.Rect(x, y, width, 30)
		self.value = 0
		self.min_val = min_val
		self.max_val = max_val
		self.active = False
		self.text = "0"
		
		# Buttons
		self.dec_btn = pygame.Rect(x, y, 25, 30)
		self.inc_btn = pygame.Rect(x + width - 25, y, 25, 30)
		self.input_rect = pygame.Rect(x + 30, y, width - 60, 30)
	
	def handle_event(self, event: pygame.event.Event) -> bool:
		"""Handle input events"""
		if event.type == pygame.MOUSEBUTTONDOWN:
			if self.dec_btn.collidepoint(event.pos):
				self.value = max(self.min_val, self.value - 1)
				self.text = str(self.value)
				return True
			elif self.inc_btn.collidepoint(event.pos):
				self.value = min(self.max_val, self.value + 1)
				self.text = str(self.value)
				return True
			elif self.input_rect.collidepoint(event.pos):
				self.active = True
				return True
			else:
				self.active = False
		
		elif event.type == pygame.KEYDOWN and self.active:
			if event.key == pygame.K_BACKSPACE:
				self.text = self.text[:-1] if self.text else ""
			elif event.key == pygame.K_RETURN:
				try:
					self.value = max(self.min_val, min(self.max_val, int(self.text or "0")))
					self.text = str(self.value)
				except ValueError:
					self.text = str(self.value)
				self.active = False
				return True
			elif event.unicode.isdigit():
				self.text += event.unicode
		
		return False
	
	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw the numeric input"""
		# Dec button
		pygame.draw.rect(surface, COLOR_BUTTON, self.dec_btn)
		pygame.draw.rect(surface, COLOR_BORDER, self.dec_btn, 1)
		text_surf = font.render("-", True, COLOR_TEXT)
		surface.blit(text_surf, (self.dec_btn.centerx - text_surf.get_width()//2,
									self.dec_btn.centery - text_surf.get_height()//2))
		
		# Inc button
		pygame.draw.rect(surface, COLOR_BUTTON, self.inc_btn)
		pygame.draw.rect(surface, COLOR_BORDER, self.inc_btn, 1)
		text_surf = font.render("+", True, COLOR_TEXT)
		surface.blit(text_surf, (self.inc_btn.centerx - text_surf.get_width()//2,
									self.inc_btn.centery - text_surf.get_height()//2))
		
		# Input field
		color = COLOR_HIGHLIGHT if self.active else COLOR_PANEL
		pygame.draw.rect(surface, color, self.input_rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.input_rect, 1)
		text_surf = font.render(self.text, True, COLOR_TEXT)
		surface.blit(text_surf, (self.input_rect.x + 5, self.input_rect.y + 7))


class CheckboxFlag:
	"""Checkbox for boolean flags"""
	
	def __init__(self, x: int, y: int, label: str):
		self.rect = pygame.Rect(x, y, 20, 20)
		self.label = label
		self.checked = False
		self.label_rect = pygame.Rect(x + 25, y, 200, 20)
	
	def handle_event(self, event: pygame.event.Event) -> bool:
		"""Handle input events"""
		if event.type == pygame.MOUSEBUTTONDOWN:
			if self.rect.collidepoint(event.pos) or self.label_rect.collidepoint(event.pos):
				self.checked = not self.checked
				return True
		return False
	
	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw the checkbox"""
		pygame.draw.rect(surface, COLOR_PANEL, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 1)
		
		if self.checked:
			pygame.draw.line(surface, COLOR_SUCCESS, 
							(self.rect.x + 3, self.rect.y + 10),
							(self.rect.x + 8, self.rect.y + 15), 2)
			pygame.draw.line(surface, COLOR_SUCCESS,
							(self.rect.x + 8, self.rect.y + 15),
							(self.rect.x + 17, self.rect.y + 5), 2)
		
		text_surf = font.render(self.label, True, COLOR_TEXT)
		surface.blit(text_surf, (self.label_rect.x, self.label_rect.y))


class ResistanceBar:
	"""Visual resistance bar (0-255, 100=normal)"""
	
	def __init__(self, x: int, y: int, width: int, element: ElementType):
		self.rect = pygame.Rect(x, y, width, 25)
		self.element = element
		self.value = 100  # Normal resistance
		self.dragging = False
	
	def handle_event(self, event: pygame.event.Event) -> bool:
		"""Handle input events"""
		if event.type == pygame.MOUSEBUTTONDOWN:
			if self.rect.collidepoint(event.pos):
				self.dragging = True
				self._update_from_mouse(event.pos)
				return True
		elif event.type == pygame.MOUSEBUTTONUP:
			self.dragging = False
		elif event.type == pygame.MOUSEMOTION and self.dragging:
			self._update_from_mouse(event.pos)
			return True
		return False
	
	def _update_from_mouse(self, pos: Tuple[int, int]):
		"""Update value from mouse position"""
		rel_x = pos[0] - self.rect.x
		percent = max(0, min(1, rel_x / self.rect.width))
		self.value = int(percent * 255)
	
	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw the resistance bar"""
		# Background
		pygame.draw.rect(surface, COLOR_PANEL, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 1)
		
		# Filled portion
		fill_width = int((self.value / 255) * self.rect.width)
		if fill_width > 0:
			# Color based on value (red=weak, green=resist, blue=immune)
			if self.value > 100:
				color = (255, 100, 100)  # Weak (red)
			elif self.value < 100:
				color = (100, 255, 100)  # Resist (green)
			else:
				color = (150, 150, 150)  # Normal (gray)
			
			if self.value == 0:
				color = (100, 100, 255)  # Immune (blue)
			
			fill_rect = pygame.Rect(self.rect.x, self.rect.y, fill_width, self.rect.height)
			pygame.draw.rect(surface, color, fill_rect)
		
		# Center line (100% mark)
		center_x = self.rect.x + int(self.rect.width * 100 / 255)
		pygame.draw.line(surface, COLOR_TEXT, (center_x, self.rect.y),
						(center_x, self.rect.bottom), 1)
		
		# Value text
		text = f"{self.value}%"
		text_surf = font.render(text, True, COLOR_TEXT)
		surface.blit(text_surf, (self.rect.centerx - text_surf.get_width()//2,
								self.rect.centery - text_surf.get_height()//2))


class EnemyListPanel:
	"""Enemy list with search and filtering"""
	
	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.enemies: List[Enemy] = []
		self.filtered_enemies: List[Enemy] = []
		self.selected_index = 0
		self.scroll_offset = 0
		self.item_height = 40
		
		# Search
		self.search_text = ""
		self.search_active = False
	
	def set_enemies(self, enemies: List[Enemy]):
		"""Set enemy list"""
		self.enemies = enemies
		self.filtered_enemies = enemies.copy()
		self.selected_index = 0
		self.scroll_offset = 0
	
	def filter_enemies(self, query: str):
		"""Filter enemies by name"""
		if not query:
			self.filtered_enemies = self.enemies.copy()
		else:
			query_lower = query.lower()
			self.filtered_enemies = [
				e for e in self.enemies
				if query_lower in e.name.lower()
			]
		self.selected_index = 0
		self.scroll_offset = 0
	
	def get_selected_enemy(self) -> Optional[Enemy]:
		"""Get currently selected enemy"""
		if 0 <= self.selected_index < len(self.filtered_enemies):
			return self.filtered_enemies[self.selected_index]
		return None
	
	def handle_event(self, event: pygame.event.Event) -> bool:
		"""Handle input events"""
		if event.type == pygame.MOUSEBUTTONDOWN:
			if self.rect.collidepoint(event.pos):
				# Calculate clicked item
				rel_y = event.pos[1] - self.rect.y
				clicked_index = (rel_y // self.item_height) + self.scroll_offset
				
				if 0 <= clicked_index < len(self.filtered_enemies):
					self.selected_index = clicked_index
					return True
		
		elif event.type == pygame.MOUSEWHEEL:
			if self.rect.collidepoint(pygame.mouse.get_pos()):
				self.scroll_offset = max(0, min(
					len(self.filtered_enemies) - (self.rect.height // self.item_height),
					self.scroll_offset - event.y
				))
				return True
		
		elif event.type == pygame.KEYDOWN:
			if event.key == pygame.K_UP:
				self.selected_index = max(0, self.selected_index - 1)
				return True
			elif event.key == pygame.K_DOWN:
				self.selected_index = min(len(self.filtered_enemies) - 1, self.selected_index + 1)
				return True
		
		return False
	
	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw the enemy list"""
		pygame.draw.rect(surface, COLOR_PANEL, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 2)
		
		# Draw visible items
		visible_count = self.rect.height // self.item_height
		for i in range(visible_count):
			index = i + self.scroll_offset
			if index >= len(self.filtered_enemies):
				break
			
			enemy = self.filtered_enemies[index]
			y = self.rect.y + (i * self.item_height)
			
			# Background
			if index == self.selected_index:
				pygame.draw.rect(surface, COLOR_HIGHLIGHT, 
								pygame.Rect(self.rect.x, y, self.rect.width, self.item_height))
			
			# Enemy ID and name
			id_text = f"0x{enemy.enemy_id:03X}"
			id_surf = font.render(id_text, True, COLOR_LABEL)
			surface.blit(id_surf, (self.rect.x + 5, y + 5))
			
			name_surf = font.render(enemy.name, True, COLOR_TEXT)
			surface.blit(name_surf, (self.rect.x + 70, y + 5))
			
			# Level and HP
			info_text = f"Lv{enemy.level} HP:{enemy.stats.hp}"
			info_surf = font.render(info_text, True, COLOR_LABEL)
			surface.blit(info_surf, (self.rect.x + 5, y + 22))


class EnemyEditorPanel:
	"""Main enemy editor panel"""
	
	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.enemy: Optional[Enemy] = None
		self.scroll_offset = 0
		
		# Create input controls
		self._create_controls()
	
	def _create_controls(self):
		"""Create all input controls"""
		x = self.rect.x + 10
		y_offset = 40
		
		# Stats inputs
		self.hp_input = NumericInput(x + 150, y_offset, 150, 0, 65535)
		y_offset += 35
		self.attack_input = NumericInput(x + 150, y_offset, 150, 0, 255)
		y_offset += 35
		self.defense_input = NumericInput(x + 150, y_offset, 150, 0, 255)
		y_offset += 35
		self.magic_input = NumericInput(x + 150, y_offset, 150, 0, 255)
		y_offset += 35
		self.magic_def_input = NumericInput(x + 150, y_offset, 150, 0, 255)
		y_offset += 35
		self.speed_input = NumericInput(x + 150, y_offset, 150, 0, 255)
		y_offset += 35
		self.level_input = NumericInput(x + 150, y_offset, 150, 1, 99)
		y_offset += 35
		self.exp_input = NumericInput(x + 150, y_offset, 150, 0, 65535)
		y_offset += 35
		self.gold_input = NumericInput(x + 150, y_offset, 150, 0, 65535)
		
		# Resistance bars
		y_offset += 50
		self.fire_resist = ResistanceBar(x + 150, y_offset, 200, ElementType.FIRE)
		y_offset += 30
		self.water_resist = ResistanceBar(x + 150, y_offset, 200, ElementType.WATER)
		y_offset += 30
		self.earth_resist = ResistanceBar(x + 150, y_offset, 200, ElementType.EARTH)
		y_offset += 30
		self.wind_resist = ResistanceBar(x + 150, y_offset, 200, ElementType.WIND)
		
		# Flag checkboxes
		y_offset += 50
		self.boss_flag = CheckboxFlag(x, y_offset, "Boss")
		y_offset += 25
		self.undead_flag = CheckboxFlag(x, y_offset, "Undead")
		y_offset += 25
		self.flying_flag = CheckboxFlag(x, y_offset, "Flying")
		y_offset += 25
		self.regen_flag = CheckboxFlag(x, y_offset, "Regenerates")
	
	def set_enemy(self, enemy: Optional[Enemy]):
		"""Set enemy to edit"""
		self.enemy = enemy
		
		if enemy:
			# Update all controls
			self.hp_input.value = enemy.stats.hp
			self.hp_input.text = str(enemy.stats.hp)
			
			self.attack_input.value = enemy.stats.attack
			self.attack_input.text = str(enemy.stats.attack)
			
			self.defense_input.value = enemy.stats.defense
			self.defense_input.text = str(enemy.stats.defense)
			
			self.magic_input.value = enemy.stats.magic
			self.magic_input.text = str(enemy.stats.magic)
			
			self.magic_def_input.value = enemy.stats.magic_defense
			self.magic_def_input.text = str(enemy.stats.magic_defense)
			
			self.speed_input.value = enemy.stats.speed
			self.speed_input.text = str(enemy.stats.speed)
			
			self.level_input.value = enemy.level
			self.level_input.text = str(enemy.level)
			
			self.exp_input.value = enemy.stats.exp
			self.exp_input.text = str(enemy.stats.exp)
			
			self.gold_input.value = enemy.stats.gold
			self.gold_input.text = str(enemy.stats.gold)
			
			# Resistances
			self.fire_resist.value = enemy.resistances.fire
			self.water_resist.value = enemy.resistances.water
			self.earth_resist.value = enemy.resistances.earth
			self.wind_resist.value = enemy.resistances.wind
			
			# Flags
			self.boss_flag.checked = bool(enemy.flags & EnemyFlags.BOSS)
			self.undead_flag.checked = bool(enemy.flags & EnemyFlags.UNDEAD)
			self.flying_flag.checked = bool(enemy.flags & EnemyFlags.FLYING)
			self.regen_flag.checked = bool(enemy.flags & EnemyFlags.REGENERATES)
	
	def save_changes(self):
		"""Save changes back to enemy"""
		if not self.enemy:
			return
		
		# Update stats
		self.enemy.stats.hp = self.hp_input.value
		self.enemy.stats.attack = self.attack_input.value
		self.enemy.stats.defense = self.defense_input.value
		self.enemy.stats.magic = self.magic_input.value
		self.enemy.stats.magic_defense = self.magic_def_input.value
		self.enemy.stats.speed = self.speed_input.value
		self.enemy.level = self.level_input.value
		self.enemy.stats.exp = self.exp_input.value
		self.enemy.stats.gold = self.gold_input.value
		
		# Update resistances
		self.enemy.resistances.fire = self.fire_resist.value
		self.enemy.resistances.water = self.water_resist.value
		self.enemy.resistances.earth = self.earth_resist.value
		self.enemy.resistances.wind = self.wind_resist.value
		
		# Update flags
		flags = EnemyFlags.NONE
		if self.boss_flag.checked:
			flags |= EnemyFlags.BOSS
		if self.undead_flag.checked:
			flags |= EnemyFlags.UNDEAD
		if self.flying_flag.checked:
			flags |= EnemyFlags.FLYING
		if self.regen_flag.checked:
			flags |= EnemyFlags.REGENERATES
		
		self.enemy.flags = flags
		self.enemy.modified = True
	
	def handle_event(self, event: pygame.event.Event) -> bool:
		"""Handle input events"""
		if not self.enemy:
			return False
		
		# Check all controls
		controls = [
			self.hp_input, self.attack_input, self.defense_input,
			self.magic_input, self.magic_def_input, self.speed_input,
			self.level_input, self.exp_input, self.gold_input,
			self.fire_resist, self.water_resist, self.earth_resist, self.wind_resist,
			self.boss_flag, self.undead_flag, self.flying_flag, self.regen_flag
		]
		
		for control in controls:
			if control.handle_event(event):
				self.save_changes()
				return True
		
		return False
	
	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw the editor panel"""
		pygame.draw.rect(surface, COLOR_PANEL, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 2)
		
		if not self.enemy:
			text_surf = font.render("No enemy selected", True, COLOR_LABEL)
			surface.blit(text_surf, (self.rect.centerx - text_surf.get_width()//2,
									self.rect.centery - text_surf.get_height()//2))
			return
		
		x = self.rect.x + 10
		y = self.rect.y + 10
		
		# Enemy header
		header_text = f"{self.enemy.name} (0x{self.enemy.enemy_id:03X})"
		header_surf = font.render(header_text, True, COLOR_TEXT)
		surface.blit(header_surf, (x, y))
		
		y += 30
		
		# Stats section
		labels = ["HP:", "Attack:", "Defense:", "Magic:", "Magic Def:", "Speed:", 
				 "Level:", "EXP:", "Gold:"]
		inputs = [self.hp_input, self.attack_input, self.defense_input,
				 self.magic_input, self.magic_def_input, self.speed_input,
				 self.level_input, self.exp_input, self.gold_input]
		
		for label, input_widget in zip(labels, inputs):
			label_surf = font.render(label, True, COLOR_LABEL)
			surface.blit(label_surf, (x, y + 5))
			input_widget.draw(surface, font)
			y += 35
		
		# Resistances section
		y += 15
		resist_title = font.render("Resistances:", True, COLOR_TEXT)
		surface.blit(resist_title, (x, y))
		y += 25
		
		resist_labels = ["Fire:", "Water:", "Earth:", "Wind:"]
		resist_bars = [self.fire_resist, self.water_resist, self.earth_resist, self.wind_resist]
		
		for label, bar in zip(resist_labels, resist_bars):
			label_surf = font.render(label, True, COLOR_LABEL)
			surface.blit(label_surf, (x, y + 5))
			bar.draw(surface, font)
			y += 30
		
		# Flags section
		y += 15
		flags_title = font.render("Flags:", True, COLOR_TEXT)
		surface.blit(flags_title, (x, y))
		y += 25
		
		for flag in [self.boss_flag, self.undead_flag, self.flying_flag, self.regen_flag]:
			flag.draw(surface, font)
			y += 25
		
		# Difficulty rating
		y += 10
		difficulty = self.enemy.calculate_difficulty()
		diff_text = f"Difficulty: {difficulty:.1f}"
		diff_surf = font.render(diff_text, True, COLOR_WARNING)
		surface.blit(diff_surf, (x, y))


class EnemyEditor:
	"""Main enemy editor application"""
	
	def __init__(self, width: int = 1200, height: int = 800):
		pygame.init()
		self.screen = pygame.display.set_mode((width, height))
		pygame.display.set_caption("FFMQ Enemy Editor")
		
		self.clock = pygame.time.Clock()
		self.running = True
		
		self.font = pygame.font.Font(None, 20)
		self.title_font = pygame.font.Font(None, 28)
		
		# Create database
		self.database = EnemyDatabase()
		
		# Create UI panels
		self.enemy_list = EnemyListPanel(10, 50, 300, height - 60)
		self.editor_panel = EnemyEditorPanel(320, 50, width - 330, height - 60)
		
		# Status message
		self.status_message = ""
		self.status_timer = 0
	
	def load_rom(self, rom_path: str):
		"""Load ROM file"""
		try:
			self.database.load_from_rom(rom_path)
			enemies = list(self.database.enemies.values())
			enemies.sort(key=lambda e: e.enemy_id)
			self.enemy_list.set_enemies(enemies)
			self.set_status(f"Loaded {len(enemies)} enemies", COLOR_SUCCESS)
		except Exception as e:
			self.set_status(f"Error loading ROM: {e}", COLOR_ERROR)
	
	def save_rom(self, output_path: str):
		"""Save ROM file"""
		try:
			self.database.save_to_rom(output_path)
			self.set_status("ROM saved successfully", COLOR_SUCCESS)
		except Exception as e:
			self.set_status(f"Error saving ROM: {e}", COLOR_ERROR)
	
	def set_status(self, message: str, color: Tuple[int, int, int] = COLOR_TEXT):
		"""Set status message"""
		self.status_message = message
		self.status_color = color
		self.status_timer = 180  # 3 seconds at 60 FPS
	
	def handle_events(self):
		"""Handle all events"""
		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				self.running = False
			
			# Pass to panels
			if self.enemy_list.handle_event(event):
				# Selection changed
				enemy = self.enemy_list.get_selected_enemy()
				self.editor_panel.set_enemy(enemy)
			
			self.editor_panel.handle_event(event)
			
			# Keyboard shortcuts
			if event.type == pygame.KEYDOWN:
				if event.key == pygame.K_s and pygame.key.get_mods() & pygame.KMOD_CTRL:
					self.save_rom("ffmq_modified.smc")
	
	def update(self):
		"""Update game state"""
		if self.status_timer > 0:
			self.status_timer -= 1
	
	def draw(self):
		"""Draw everything"""
		self.screen.fill(COLOR_BG)
		
		# Title
		title_surf = self.title_font.render("FFMQ Enemy Editor", True, COLOR_TEXT)
		self.screen.blit(title_surf, (10, 10))
		
		# Draw panels
		self.enemy_list.draw(self.screen, self.font)
		self.editor_panel.draw(self.screen, self.font)
		
		# Status message
		if self.status_timer > 0:
			status_surf = self.font.render(self.status_message, True, self.status_color)
			self.screen.blit(status_surf, (self.screen.get_width() - status_surf.get_width() - 10,
										  self.screen.get_height() - 30))
		
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
	
	editor = EnemyEditor()
	
	# Load ROM if provided
	if len(sys.argv) > 1:
		editor.load_rom(sys.argv[1])
	
	editor.run()


if __name__ == '__main__':
	main()
