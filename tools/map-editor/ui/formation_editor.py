"""
FFMQ Enemy Formation Editor

Visual editor for creating and editing enemy battle formations.
Allows placement of enemies on battle screen, setting positions,
and configuring formation parameters.
"""

import pygame
from typing import List, Optional, Tuple, Dict
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent.parent))

from utils.dungeon_map import EnemyFormation, EncounterTable
from utils.enemy_database import EnemyDatabase


# Colors
COLOR_BG = (20, 20, 30)
COLOR_PANEL = (35, 35, 45)
COLOR_BORDER = (55, 55, 65)
COLOR_TEXT = (220, 220, 220)
COLOR_LABEL = (140, 140, 150)
COLOR_HIGHLIGHT = (70, 110, 190)
COLOR_ENEMY = (200, 80, 80)
COLOR_ENEMY_SELECTED = (255, 120, 120)
COLOR_GRID = (40, 40, 50)
COLOR_BUTTON = (60, 100, 180)
COLOR_BUTTON_HOVER = (80, 130, 220)


class EnemySprite:
	"""Visual representation of enemy in formation"""
	
	def __init__(self, x: int, y: int, enemy_id: int, index: int):
		self.x = x
		self.y = y
		self.enemy_id = enemy_id
		self.index = index
		self.rect = pygame.Rect(x - 16, y - 16, 32, 32)
		self.selected = False
		self.dragging = False
		self.name = f"Enemy {enemy_id:02X}"
	
	def update_position(self, x: int, y: int):
		"""Update sprite position"""
		self.x = x
		self.y = y
		self.rect.x = x - 16
		self.rect.y = y - 16
	
	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw enemy sprite"""
		# Draw enemy as colored circle
		color = COLOR_ENEMY_SELECTED if self.selected else COLOR_ENEMY
		pygame.draw.circle(surface, color, (self.x, self.y), 16)
		pygame.draw.circle(surface, COLOR_BORDER, (self.x, self.y), 16, 2)
		
		# Draw index number
		index_surf = font.render(str(self.index + 1), True, COLOR_TEXT)
		surface.blit(index_surf, (self.x - index_surf.get_width() // 2,
									self.y - index_surf.get_height() // 2))
		
		# Draw name below if selected
		if self.selected:
			name_surf = font.render(self.name, True, COLOR_TEXT)
			surface.blit(name_surf, (self.x - name_surf.get_width() // 2, self.y + 20))


class BattleScreen:
	"""Battle screen preview area"""
	
	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.enemy_sprites: List[EnemySprite] = []
		self.selected_sprite: Optional[EnemySprite] = None
		self.grid_size = 16
	
	def add_enemy(self, enemy_id: int, x: int = None, y: int = None) -> EnemySprite:
		"""Add enemy to formation"""
		if x is None:
			x = self.rect.centerx
		if y is None:
			y = self.rect.centery
		
		sprite = EnemySprite(x, y, enemy_id, len(self.enemy_sprites))
		self.enemy_sprites.append(sprite)
		return sprite
	
	def remove_selected(self):
		"""Remove selected enemy"""
		if self.selected_sprite:
			self.enemy_sprites.remove(self.selected_sprite)
			# Reindex
			for i, sprite in enumerate(self.enemy_sprites):
				sprite.index = i
			self.selected_sprite = None
	
	def clear_all(self):
		"""Clear all enemies"""
		self.enemy_sprites.clear()
		self.selected_sprite = None
	
	def handle_event(self, event: pygame.event.Event) -> bool:
		"""Handle input events"""
		if event.type == pygame.MOUSEBUTTONDOWN:
			if self.rect.collidepoint(event.pos):
				# Check if clicked on sprite
				for sprite in reversed(self.enemy_sprites):
					if sprite.rect.collidepoint(event.pos):
						# Select this sprite
						if self.selected_sprite:
							self.selected_sprite.selected = False
						sprite.selected = True
						sprite.dragging = True
						self.selected_sprite = sprite
						return True
				
				# Clicked empty space - deselect
				if self.selected_sprite:
					self.selected_sprite.selected = False
					self.selected_sprite = None
					return True
		
		elif event.type == pygame.MOUSEBUTTONUP:
			# Stop dragging
			for sprite in self.enemy_sprites:
				sprite.dragging = False
		
		elif event.type == pygame.MOUSEMOTION:
			# Drag sprite
			for sprite in self.enemy_sprites:
				if sprite.dragging:
					# Snap to grid
					rel_x = event.pos[0] - self.rect.x
					rel_y = event.pos[1] - self.rect.y
					
					# Keep within bounds
					rel_x = max(20, min(self.rect.width - 20, rel_x))
					rel_y = max(20, min(self.rect.height - 20, rel_y))
					
					# Snap to grid
					grid_x = (rel_x // self.grid_size) * self.grid_size
					grid_y = (rel_y // self.grid_size) * self.grid_size
					
					sprite.update_position(
						self.rect.x + grid_x,
						self.rect.y + grid_y
					)
					return True
		
		elif event.type == pygame.KEYDOWN:
			if event.key == pygame.K_DELETE:
				self.remove_selected()
				return True
		
		return False
	
	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw battle screen"""
		# Background
		pygame.draw.rect(surface, COLOR_BG, self.rect)
		
		# Grid
		for x in range(0, self.rect.width, self.grid_size):
			pygame.draw.line(surface, COLOR_GRID,
							(self.rect.x + x, self.rect.y),
							(self.rect.x + x, self.rect.bottom))
		
		for y in range(0, self.rect.height, self.grid_size):
			pygame.draw.line(surface, COLOR_GRID,
							(self.rect.x, self.rect.y + y),
							(self.rect.right, self.rect.y + y))
		
		# Border
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 2)
		
		# Enemy sprites
		for sprite in self.enemy_sprites:
			sprite.draw(surface, font)
		
		# Instructions
		if not self.enemy_sprites:
			text_surf = font.render("Click 'Add Enemy' to place enemies", True, COLOR_LABEL)
			surface.blit(text_surf, (
				self.rect.centerx - text_surf.get_width() // 2,
				self.rect.centery - text_surf.get_height() // 2
			))


class EnemyListPanel:
	"""Panel showing available enemies"""
	
	def __init__(self, x: int, y: int, width: int, height: int):
		self.rect = pygame.Rect(x, y, width, height)
		self.enemies: List[Tuple[int, str]] = []
		self.selected_index = 0
		self.scroll_offset = 0
		self.item_height = 30
	
	def set_enemies(self, enemy_db: EnemyDatabase):
		"""Set enemy list from database"""
		self.enemies = [
			(enemy_id, enemy.name)
			for enemy_id, enemy in sorted(enemy_db.enemies.items())
		]
	
	def get_selected_enemy_id(self) -> Optional[int]:
		"""Get currently selected enemy ID"""
		if 0 <= self.selected_index < len(self.enemies):
			return self.enemies[self.selected_index][0]
		return None
	
	def handle_event(self, event: pygame.event.Event) -> bool:
		"""Handle input events"""
		if event.type == pygame.MOUSEBUTTONDOWN:
			if self.rect.collidepoint(event.pos):
				rel_y = event.pos[1] - self.rect.y
				clicked_index = (rel_y // self.item_height) + self.scroll_offset
				
				if 0 <= clicked_index < len(self.enemies):
					self.selected_index = clicked_index
					return True
		
		elif event.type == pygame.MOUSEWHEEL:
			if self.rect.collidepoint(pygame.mouse.get_pos()):
				visible_count = self.rect.height // self.item_height
				max_scroll = max(0, len(self.enemies) - visible_count)
				self.scroll_offset = max(0, min(max_scroll, self.scroll_offset - event.y))
				return True
		
		return False
	
	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw enemy list"""
		pygame.draw.rect(surface, COLOR_PANEL, self.rect)
		pygame.draw.rect(surface, COLOR_BORDER, self.rect, 2)
		
		visible_count = self.rect.height // self.item_height
		for i in range(visible_count):
			index = i + self.scroll_offset
			if index >= len(self.enemies):
				break
			
			enemy_id, enemy_name = self.enemies[index]
			y = self.rect.y + (i * self.item_height)
			
			# Background
			if index == self.selected_index:
				pygame.draw.rect(surface, COLOR_HIGHLIGHT,
								pygame.Rect(self.rect.x, y, self.rect.width, self.item_height))
			
			# Enemy ID and name
			id_text = f"0x{enemy_id:02X}"
			id_surf = font.render(id_text, True, COLOR_LABEL)
			surface.blit(id_surf, (self.rect.x + 5, y + 5))
			
			name_surf = font.render(enemy_name, True, COLOR_TEXT)
			surface.blit(name_surf, (self.rect.x + 60, y + 5))


class FormationEditor:
	"""Main formation editor application"""
	
	def __init__(self, width: int = 1200, height: int = 700):
		pygame.init()
		
		self.screen = pygame.display.set_mode((width, height))
		pygame.display.set_caption("FFMQ Formation Editor")
		
		self.clock = pygame.time.Clock()
		self.running = True
		
		self.font = pygame.font.Font(None, 20)
		self.title_font = pygame.font.Font(None, 28)
		
		# Enemy database
		self.enemy_db = EnemyDatabase()
		
		# Current formation
		self.formation: Optional[EnemyFormation] = None
		
		# UI components
		self.battle_screen = BattleScreen(300, 80, 640, 480)
		self.enemy_list = EnemyListPanel(10, 80, 280, 480)
		
		# Buttons
		self.add_button = self._create_button(10, 570, 130, 30, "Add Enemy")
		self.remove_button = self._create_button(150, 570, 130, 30, "Remove")
		self.clear_button = self._create_button(10, 610, 130, 30, "Clear All")
		self.save_button = self._create_button(150, 610, 130, 30, "Save")
		
		# Status
		self.status_message = ""
		self.status_timer = 0
	
	def _create_button(self, x, y, w, h, text):
		"""Helper to create button dict"""
		return {
			'rect': pygame.Rect(x, y, w, h),
			'text': text,
			'hover': False
		}
	
	def load_enemies(self, rom_path: str):
		"""Load enemy database"""
		try:
			self.enemy_db.load_from_rom(rom_path)
			self.enemy_list.set_enemies(self.enemy_db)
			self.set_status(f"Loaded {len(self.enemy_db.enemies)} enemies")
		except Exception as e:
			self.set_status(f"Error: {e}")
	
	def set_status(self, message: str):
		"""Set status message"""
		self.status_message = message
		self.status_timer = 180
	
	def handle_button(self, button, event):
		"""Handle button event"""
		if event.type == pygame.MOUSEMOTION:
			button['hover'] = button['rect'].collidepoint(event.pos)
		elif event.type == pygame.MOUSEBUTTONDOWN:
			if button['rect'].collidepoint(event.pos):
				return True
		return False
	
	def draw_button(self, button):
		"""Draw a button"""
		color = COLOR_BUTTON_HOVER if button['hover'] else COLOR_BUTTON
		pygame.draw.rect(self.screen, color, button['rect'])
		pygame.draw.rect(self.screen, COLOR_BORDER, button['rect'], 1)
		
		text_surf = self.font.render(button['text'], True, COLOR_TEXT)
		text_x = button['rect'].x + (button['rect'].width - text_surf.get_width()) // 2
		text_y = button['rect'].y + (button['rect'].height - text_surf.get_height()) // 2
		self.screen.blit(text_surf, (text_x, text_y))
	
	def handle_events(self):
		"""Handle all events"""
		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				self.running = False
			
			# Battle screen
			self.battle_screen.handle_event(event)
			
			# Enemy list
			self.enemy_list.handle_event(event)
			
			# Buttons
			if self.handle_button(self.add_button, event):
				enemy_id = self.enemy_list.get_selected_enemy_id()
				if enemy_id is not None:
					self.battle_screen.add_enemy(enemy_id)
					self.set_status(f"Added enemy 0x{enemy_id:02X}")
			
			if self.handle_button(self.remove_button, event):
				self.battle_screen.remove_selected()
				self.set_status("Removed enemy")
			
			if self.handle_button(self.clear_button, event):
				self.battle_screen.clear_all()
				self.set_status("Cleared formation")
			
			if self.handle_button(self.save_button, event):
				self.save_formation()
	
	def save_formation(self):
		"""Save current formation"""
		enemy_ids = [sprite.enemy_id for sprite in self.battle_screen.enemy_sprites]
		positions = [(sprite.x, sprite.y) for sprite in self.battle_screen.enemy_sprites]
		
		self.formation = EnemyFormation(
			formation_id=0,
			enemy_ids=enemy_ids,
			positions=positions
		)
		
		self.set_status(f"Saved formation with {len(enemy_ids)} enemies")
	
	def update(self):
		"""Update game state"""
		if self.status_timer > 0:
			self.status_timer -= 1
	
	def draw(self):
		"""Draw everything"""
		self.screen.fill(COLOR_BG)
		
		# Title
		title_surf = self.title_font.render("Formation Editor", True, COLOR_TEXT)
		self.screen.blit(title_surf, (10, 10))
		
		# Info
		info_text = f"Enemies: {len(self.battle_screen.enemy_sprites)}/6"
		info_surf = self.font.render(info_text, True, COLOR_LABEL)
		self.screen.blit(info_surf, (10, 45))
		
		# Enemy list
		self.enemy_list.draw(self.screen, self.font)
		
		# Battle screen
		self.battle_screen.draw(self.screen, self.font)
		
		# Buttons
		for button in [self.add_button, self.remove_button, self.clear_button, self.save_button]:
			self.draw_button(button)
		
		# Status
		if self.status_timer > 0:
			status_surf = self.font.render(self.status_message, True, COLOR_TEXT)
			self.screen.blit(status_surf, (300, self.screen.get_height() - 30))
		
		# Instructions
		help_text = "Drag enemies to position | Delete: Remove selected | Double-click: Select enemy type"
		help_surf = self.font.render(help_text, True, COLOR_LABEL)
		self.screen.blit(help_surf, (300, self.screen.get_height() - 60))
		
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
	
	editor = FormationEditor()
	
	# Load ROM if provided
	if len(sys.argv) > 1:
		editor.load_enemies(sys.argv[1])
	
	editor.run()


if __name__ == '__main__':
	main()
