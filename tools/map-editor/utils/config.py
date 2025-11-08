#!/usr/bin/env python3
"""
Configuration management for FFMQ Map Editor
"""

import json
from pathlib import Path
from typing import Any, Dict, Optional

class Config:
	"""Configuration manager for the map editor"""
	
	DEFAULT_CONFIG = {
		# Window settings
		'window_width': 1600,
		'window_height': 900,
		'target_fps': 60,
		
		# Map view settings
		'tile_size': 16,  # Base tile size in pixels
		'grid_enabled': True,
		'grid_color': (100, 100, 100),
		'grid_thickness': 1,
		
		# UI layout
		'toolbar_height': 40,
		'tileset_panel_width': 300,
		'layer_panel_width': 200,
		'properties_panel_width': 250,
		
		# Colors
		'bg_color': (40, 40, 40),
		'ui_bg_color': (50, 50, 50),
		'ui_border_color': (70, 70, 70),
		'text_color': (220, 220, 220),
		'highlight_color': (100, 150, 255),
		
		# Paths
		'rom_path': '',
		'last_project_dir': '',
		'export_dir': 'data/exported_maps',
		'tileset_cache_dir': 'data/tilesets',
		
		# Editor settings
		'show_collision': True,
		'show_events': True,
		'show_npcs': True,
		'show_grid': True,
		'auto_save': True,
		'auto_save_interval': 300,  # seconds
		
		# Map defaults
		'default_map_width': 64,
		'default_map_height': 64,
		'default_tileset': 0,
		
		# Recent files
		'recent_files': [],
		'max_recent_files': 10,
	}
	
	def __init__(self, config_path: Optional[str] = None):
		"""Initialize configuration"""
		if config_path is None:
			config_path = Path(__file__).parent.parent / 'config.json'
		
		self.config_path = Path(config_path)
		self.config: Dict[str, Any] = self.DEFAULT_CONFIG.copy()
		
		# Load existing config if it exists
		if self.config_path.exists():
			self.load()
	
	def get(self, key: str, default: Any = None) -> Any:
		"""Get a configuration value"""
		return self.config.get(key, default)
	
	def set(self, key: str, value: Any) -> None:
		"""Set a configuration value"""
		self.config[key] = value
	
	def load(self) -> bool:
		"""Load configuration from file"""
		try:
			with open(self.config_path, 'r') as f:
				loaded = json.load(f)
				# Merge with defaults (in case new keys were added)
				self.config = {**self.DEFAULT_CONFIG, **loaded}
			return True
		except Exception as e:
			print(f"Warning: Could not load config: {e}")
			return False
	
	def save(self) -> bool:
		"""Save configuration to file"""
		try:
			self.config_path.parent.mkdir(parents=True, exist_ok=True)
			with open(self.config_path, 'w') as f:
				json.dump(self.config, f, indent=2)
			return True
		except Exception as e:
			print(f"Error saving config: {e}")
			return False
	
	def add_recent_file(self, filepath: str) -> None:
		"""Add a file to recent files list"""
		recent = self.config['recent_files']
		
		# Remove if already in list
		if filepath in recent:
			recent.remove(filepath)
		
		# Add to front
		recent.insert(0, filepath)
		
		# Trim to max size
		max_files = self.config['max_recent_files']
		self.config['recent_files'] = recent[:max_files]
		
		self.save()
	
	def get_recent_files(self) -> list:
		"""Get list of recent files"""
		return self.config['recent_files']
