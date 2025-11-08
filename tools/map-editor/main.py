#!/usr/bin/env python3
"""
Final Fantasy Mystic Quest - Map Editor
A comprehensive pygame-based map editor for FFMQ overworld, dungeons, and towns

Author: FFMQ Disassembly Project
License: MIT
"""

import sys
import pygame
from pathlib import Path

# Add parent directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

from engine.map_engine import MapEngine
from ui.main_window import MainWindow
from ui.toolbar import Toolbar
from ui.tileset_panel import TilesetPanel
from ui.layer_panel import LayerPanel
from ui.properties_panel import PropertiesPanel
from utils.config import Config
from utils.logger import setup_logger

class FFMQMapEditor:
	"""Main application class for FFMQ Map Editor"""
	
	def __init__(self):
		"""Initialize the map editor application"""
		self.logger = setup_logger("MapEditor")
		self.logger.info("Initializing FFMQ Map Editor...")
		
		# Initialize pygame
		pygame.init()
		
		# Load configuration
		self.config = Config()
		
		# Set up display
		self.screen_width = self.config.get('window_width', 1600)
		self.screen_height = self.config.get('window_height', 900)
		self.screen = pygame.display.set_mode(
			(self.screen_width, self.screen_height),
			pygame.RESIZABLE
		)
		pygame.display.set_caption("FFMQ Map Editor v1.0")
		
		# Set up clock for frame rate control
		self.clock = pygame.time.Clock()
		self.fps = self.config.get('target_fps', 60)
		
		# Initialize components
		self.map_engine = MapEngine(self.config)
		self.main_window = MainWindow(self.screen, self.config)
		self.toolbar = Toolbar(self.screen, self.config)
		self.tileset_panel = TilesetPanel(self.screen, self.config)
		self.layer_panel = LayerPanel(self.screen, self.config)
		self.properties_panel = PropertiesPanel(self.screen, self.config)
		
		# Editor state
		self.running = True
		self.current_tool = 'pencil'
		self.current_tile = 0
		self.current_layer = 0
		self.zoom_level = 1.0
		
		# Mouse state
		self.mouse_pos = (0, 0)
		self.mouse_pressed = [False, False, False]
		self.last_mouse_tile = None
		
		# Keyboard state
		self.keys_pressed = set()
		
		self.logger.info("Map Editor initialized successfully")
	
	def handle_events(self):
		"""Handle all pygame events"""
		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				self.running = False
			
			elif event.type == pygame.VIDEORESIZE:
				self.screen_width = event.w
				self.screen_height = event.h
				self.screen = pygame.display.set_mode(
					(self.screen_width, self.screen_height),
					pygame.RESIZABLE
				)
				self.main_window.resize(event.w, event.h)
			
			elif event.type == pygame.MOUSEBUTTONDOWN:
				self.mouse_pressed[event.button - 1] = True
				self.handle_mouse_click(event.button, event.pos)
			
			elif event.type == pygame.MOUSEBUTTONUP:
				self.mouse_pressed[event.button - 1] = False
			
			elif event.type == pygame.MOUSEMOTION:
				self.mouse_pos = event.pos
				self.handle_mouse_motion(event.pos)
			
			elif event.type == pygame.MOUSEWHEEL:
				self.handle_mouse_wheel(event.y)
			
			elif event.type == pygame.KEYDOWN:
				self.keys_pressed.add(event.key)
				self.handle_key_press(event.key)
			
			elif event.type == pygame.KEYUP:
				self.keys_pressed.discard(event.key)
			
			# Pass events to UI components
			self.toolbar.handle_event(event)
			self.tileset_panel.handle_event(event)
			self.layer_panel.handle_event(event)
			self.properties_panel.handle_event(event)
	
	def handle_mouse_click(self, button: int, pos: tuple):
		"""Handle mouse click events"""
		# Left click - paint/place tile
		if button == 1:
			if self.main_window.contains_point(pos):
				map_pos = self.screen_to_map(pos)
				self.paint_tile(map_pos)
		
		# Right click - pick tile
		elif button == 3:
			if self.main_window.contains_point(pos):
				map_pos = self.screen_to_map(pos)
				self.pick_tile(map_pos)
		
		# Middle click - pan
		elif button == 2:
			pass  # Pan mode handled in motion
	
	def handle_mouse_motion(self, pos: tuple):
		"""Handle mouse motion events"""
		# If left mouse is held and we're in the map area, paint
		if self.mouse_pressed[0] and self.main_window.contains_point(pos):
			map_pos = self.screen_to_map(pos)
			if map_pos != self.last_mouse_tile:
				self.paint_tile(map_pos)
				self.last_mouse_tile = map_pos
		
		# If middle mouse is held, pan the map
		if self.mouse_pressed[1]:
			self.main_window.pan(pos)
	
	def handle_mouse_wheel(self, delta: int):
		"""Handle mouse wheel events (zoom)"""
		if delta > 0:
			self.zoom_in()
		elif delta < 0:
			self.zoom_out()
	
	def handle_key_press(self, key: int):
		"""Handle keyboard events"""
		# Ctrl modifier
		ctrl_held = (pygame.K_LCTRL in self.keys_pressed or 
					 pygame.K_RCTRL in self.keys_pressed)
		
		# File operations
		if ctrl_held:
			if key == pygame.K_n:
				self.new_map()
			elif key == pygame.K_o:
				self.open_map()
			elif key == pygame.K_s:
				self.save_map()
			elif key == pygame.K_z:
				self.undo()
			elif key == pygame.K_y:
				self.redo()
		
		# Tool selection (hotkeys)
		if key == pygame.K_p:
			self.current_tool = 'pencil'
		elif key == pygame.K_b:
			self.current_tool = 'bucket'
		elif key == pygame.K_e:
			self.current_tool = 'eraser'
		elif key == pygame.K_r:
			self.current_tool = 'rectangle'
		elif key == pygame.K_f:
			self.current_tool = 'fill'
		
		# Layer switching
		if key == pygame.K_1:
			self.current_layer = 0
		elif key == pygame.K_2:
			self.current_layer = 1
		elif key == pygame.K_3:
			self.current_layer = 2
		
		# View controls
		if key == pygame.K_PLUS or key == pygame.K_EQUALS:
			self.zoom_in()
		elif key == pygame.K_MINUS:
			self.zoom_out()
		elif key == pygame.K_0:
			self.zoom_reset()
		
		# Grid toggle
		if key == pygame.K_g:
			self.main_window.toggle_grid()
	
	def paint_tile(self, map_pos: tuple):
		"""Paint a tile at the given map position"""
		if self.current_tool == 'pencil':
			self.map_engine.set_tile(
				map_pos[0], map_pos[1],
				self.current_tile,
				self.current_layer
			)
		elif self.current_tool == 'bucket':
			self.map_engine.flood_fill(
				map_pos[0], map_pos[1],
				self.current_tile,
				self.current_layer
			)
		elif self.current_tool == 'eraser':
			self.map_engine.set_tile(
				map_pos[0], map_pos[1],
				0,  # Empty tile
				self.current_layer
			)
	
	def pick_tile(self, map_pos: tuple):
		"""Pick the tile at the given map position"""
		tile = self.map_engine.get_tile(
			map_pos[0], map_pos[1],
			self.current_layer
		)
		if tile is not None:
			self.current_tile = tile
			self.tileset_panel.select_tile(tile)
	
	def screen_to_map(self, screen_pos: tuple) -> tuple:
		"""Convert screen coordinates to map tile coordinates"""
		return self.main_window.screen_to_map(screen_pos)
	
	def zoom_in(self):
		"""Zoom in the map view"""
		self.zoom_level = min(self.zoom_level * 1.2, 4.0)
		self.main_window.set_zoom(self.zoom_level)
	
	def zoom_out(self):
		"""Zoom out the map view"""
		self.zoom_level = max(self.zoom_level / 1.2, 0.25)
		self.main_window.set_zoom(self.zoom_level)
	
	def zoom_reset(self):
		"""Reset zoom to 1:1"""
		self.zoom_level = 1.0
		self.main_window.set_zoom(self.zoom_level)
	
	def new_map(self):
		"""Create a new map"""
		self.logger.info("Creating new map...")
		# TODO: Show new map dialog
		self.map_engine.new_map(64, 64)  # Default 64x64 map
	
	def open_map(self):
		"""Open an existing map"""
		self.logger.info("Opening map...")
		# TODO: Show file open dialog
		pass
	
	def save_map(self):
		"""Save the current map"""
		self.logger.info("Saving map...")
		# TODO: Show file save dialog
		pass
	
	def undo(self):
		"""Undo last action"""
		self.map_engine.undo()
	
	def redo(self):
		"""Redo last undone action"""
		self.map_engine.redo()
	
	def update(self):
		"""Update game state"""
		delta_time = self.clock.get_time() / 1000.0  # Convert to seconds
		
		# Update components
		self.map_engine.update(delta_time)
		self.main_window.update(delta_time)
		self.toolbar.update(delta_time)
		self.tileset_panel.update(delta_time)
		self.layer_panel.update(delta_time)
		self.properties_panel.update(delta_time)
	
	def render(self):
		"""Render the editor"""
		# Clear screen
		self.screen.fill((40, 40, 40))
		
		# Render components in order
		self.main_window.render(self.screen, self.map_engine)
		self.toolbar.render(self.screen)
		self.tileset_panel.render(self.screen)
		self.layer_panel.render(self.screen)
		self.properties_panel.render(self.screen)
		
		# Draw cursor/tool preview if over map
		if self.main_window.contains_point(self.mouse_pos):
			self.draw_cursor()
		
		# Update display
		pygame.display.flip()
	
	def draw_cursor(self):
		"""Draw the tool cursor"""
		# TODO: Draw appropriate cursor based on current tool
		pass
	
	def run(self):
		"""Main application loop"""
		self.logger.info("Starting main loop...")
		
		while self.running:
			# Handle events
			self.handle_events()
			
			# Update state
			self.update()
			
			# Render
			self.render()
			
			# Cap frame rate
			self.clock.tick(self.fps)
		
		self.logger.info("Shutting down...")
		pygame.quit()
		sys.exit(0)


def main():
	"""Entry point for the map editor"""
	try:
		editor = FFMQMapEditor()
		editor.run()
	except Exception as e:
		print(f"Fatal error: {e}", file=sys.stderr)
		import traceback
		traceback.print_exc()
		sys.exit(1)


if __name__ == '__main__':
	main()
