#!/usr/bin/env python3
"""
File dialog utilities for FFMQ Map Editor
Provides consistent file dialogs for opening, saving, and managing map files
"""

import tkinter as tk
from tkinter import filedialog, messagebox, simpledialog
from pathlib import Path
from typing import Optional, Tuple, List
import json


class FileDialogs:
	"""Handles all file dialog operations for the map editor"""

	def __init__(self, config=None):
		"""
		Initialize file dialog handler

		Args:
			config: Configuration object (optional)
		"""
		self.config = config
		self.last_directory = str(Path.home())

		# Initialize tkinter root (hidden)
		self.root = tk.Tk()
		self.root.withdraw()

		# File type filters
		self.rom_filter = [
			("SNES ROM files", "*.sfc *.smc"),
			("All files", "*.*")
		]

		self.map_filter = [
			("FFMQ Map files", "*.ffmap"),
			("JSON files", "*.json"),
			("All files", "*.*")
		]

		self.export_filter = [
			("PNG images", "*.png"),
			("Binary files", "*.bin"),
			("Text files", "*.txt"),
			("All files", "*.* ")
		]

	def ask_open_rom(self) -> Optional[str]:
		"""
		Show dialog to open a ROM file

		Returns:
			Path to ROM file, or None if cancelled
		"""
		filepath = filedialog.askopenfilename(
			title="Open FFMQ ROM",
			initialdir=self.last_directory,
			filetypes=self.rom_filter
		)

		if filepath:
			self.last_directory = str(Path(filepath).parent)
			if self.config:
				self.config.add_recent_file(filepath)
			return filepath

		return None

	def ask_save_rom(self, default_name: str = "modified.sfc") -> Optional[str]:
		"""
		Show dialog to save a ROM file

		Args:
			default_name: Default filename

		Returns:
			Path to save location, or None if cancelled
		"""
		filepath = filedialog.asksaveasfilename(
			title="Save ROM As",
			initialdir=self.last_directory,
			initialfile=default_name,
			defaultextension=".sfc",
			filetypes=self.rom_filter
		)

		if filepath:
			self.last_directory = str(Path(filepath).parent)
			return filepath

		return None

	def ask_open_map(self) -> Optional[str]:
		"""
		Show dialog to open a map file

		Returns:
			Path to map file, or None if cancelled
		"""
		filepath = filedialog.askopenfilename(
			title="Open Map",
			initialdir=self.last_directory,
			filetypes=self.map_filter
		)

		if filepath:
			self.last_directory = str(Path(filepath).parent)
			if self.config:
				self.config.add_recent_file(filepath)
			return filepath

		return None

	def ask_save_map(self, default_name: str = "untitled.ffmap") -> Optional[str]:
		"""
		Show dialog to save a map file

		Args:
			default_name: Default filename

		Returns:
			Path to save location, or None if cancelled
		"""
		filepath = filedialog.asksaveasfilename(
			title="Save Map As",
			initialdir=self.last_directory,
			initialfile=default_name,
			defaultextension=".ffmap",
			filetypes=self.map_filter
		)

		if filepath:
			self.last_directory = str(Path(filepath).parent)
			return filepath

		return None

	def ask_export_image(self, default_name: str = "map.png") -> Optional[str]:
		"""
		Show dialog to export map as image

		Args:
			default_name: Default filename

		Returns:
			Path to save location, or None if cancelled
		"""
		filepath = filedialog.asksaveasfilename(
			title="Export Map as Image",
			initialdir=self.last_directory,
			initialfile=default_name,
			defaultextension=".png",
			filetypes=[("PNG images", "*.png")]
		)

		if filepath:
			self.last_directory = str(Path(filepath).parent)
			return filepath

		return None

	def ask_import_tileset(self) -> Optional[str]:
		"""
		Show dialog to import tileset

		Returns:
			Path to tileset file, or None if cancelled
		"""
		filepath = filedialog.askopenfilename(
			title="Import Tileset",
			initialdir=self.last_directory,
			filetypes=[
				("Image files", "*.png *.bmp *.gif"),
				("Binary files", "*.bin"),
				("All files", "*.*")
			]
		)

		if filepath:
			self.last_directory = str(Path(filepath).parent)
			return filepath

		return None

	def ask_directory(self, title: str = "Select Directory") -> Optional[str]:
		"""
		Show dialog to select a directory

		Args:
			title: Dialog title

		Returns:
			Path to directory, or None if cancelled
		"""
		dirpath = filedialog.askdirectory(
			title=title,
			initialdir=self.last_directory
		)

		if dirpath:
			self.last_directory = dirpath
			return dirpath

		return None

	def show_error(self, title: str, message: str):
		"""Show error message dialog"""
		messagebox.showerror(title, message)

	def show_warning(self, title: str, message: str):
		"""Show warning message dialog"""
		messagebox.showwarning(title, message)

	def show_info(self, title: str, message: str):
		"""Show info message dialog"""
		messagebox.showinfo(title, message)

	def ask_yes_no(self, title: str, message: str) -> bool:
		"""
		Show yes/no question dialog

		Returns:
			True if yes, False if no
		"""
		return messagebox.askyesno(title, message)

	def ask_ok_cancel(self, title: str, message: str) -> bool:
		"""
		Show OK/Cancel dialog

		Returns:
			True if OK, False if cancel
		"""
		return messagebox.askokcancel(title, message)


class NewMapDialog:
	"""Dialog for creating a new map"""

	def __init__(self, parent=None):
		"""Initialize new map dialog"""
		self.result = None

		# Create dialog window
		self.dialog = tk.Toplevel(parent) if parent else tk.Tk()
		self.dialog.title("New Map")
		self.dialog.geometry("400x300")
		self.dialog.resizable(False, False)

		# Center window
		self.dialog.update_idletasks()
		x = (self.dialog.winfo_screenwidth() // 2) - (400 // 2)
		y = (self.dialog.winfo_screenheight() // 2) - (300 // 2)
		self.dialog.geometry(f"+{x}+{y}")

		self._create_widgets()

	def _create_widgets(self):
		"""Create dialog widgets"""
		# Map name
		tk.Label(self.dialog, text="Map Name:").grid(
			row=0, column=0, padx=10, pady=5, sticky='w'
		)
		self.name_var = tk.StringVar(value="Untitled Map")
		tk.Entry(self.dialog, textvariable=self.name_var, width=30).grid(
			row=0, column=1, padx=10, pady=5
		)

		# Map type
		tk.Label(self.dialog, text="Map Type:").grid(
			row=1, column=0, padx=10, pady=5, sticky='w'
		)
		self.type_var = tk.StringVar(value="Town")
		type_menu = tk.OptionMenu(
			self.dialog, self.type_var,
			"Overworld", "Town", "Dungeon", "Battle", "Special"
		)
		type_menu.grid(row=1, column=1, padx=10, pady=5, sticky='w')

		# Width
		tk.Label(self.dialog, text="Width (tiles):").grid(
			row=2, column=0, padx=10, pady=5, sticky='w'
		)
		self.width_var = tk.IntVar(value=32)
		width_spinbox = tk.Spinbox(
			self.dialog, from_=16, to=256, textvariable=self.width_var, width=10
		)
		width_spinbox.grid(row=2, column=1, padx=10, pady=5, sticky='w')

		# Height
		tk.Label(self.dialog, text="Height (tiles):").grid(
			row=3, column=0, padx=10, pady=5, sticky='w'
		)
		self.height_var = tk.IntVar(value=32)
		height_spinbox = tk.Spinbox(
			self.dialog, from_=16, to=256, textvariable=self.height_var, width=10
		)
		height_spinbox.grid(row=3, column=1, padx=10, pady=5, sticky='w')

		# Tileset
		tk.Label(self.dialog, text="Tileset:").grid(
			row=4, column=0, padx=10, pady=5, sticky='w'
		)
		self.tileset_var = tk.IntVar(value=0)
		tileset_spinbox = tk.Spinbox(
			self.dialog, from_=0, to=15, textvariable=self.tileset_var, width=10
		)
		tileset_spinbox.grid(row=4, column=1, padx=10, pady=5, sticky='w')

		# Palette
		tk.Label(self.dialog, text="Palette:").grid(
			row=5, column=0, padx=10, pady=5, sticky='w'
		)
		self.palette_var = tk.IntVar(value=0)
		palette_spinbox = tk.Spinbox(
			self.dialog, from_=0, to=15, textvariable=self.palette_var, width=10
		)
		palette_spinbox.grid(row=5, column=1, padx=10, pady=5, sticky='w')

		# Buttons
		button_frame = tk.Frame(self.dialog)
		button_frame.grid(row=6, column=0, columnspan=2, pady=20)

		tk.Button(
			button_frame, text="Create", command=self._on_create, width=10
		).pack(side='left', padx=5)

		tk.Button(
			button_frame, text="Cancel", command=self._on_cancel, width=10
		).pack(side='left', padx=5)

	def _on_create(self):
		"""Handle create button"""
		self.result = {
			'name': self.name_var.get(),
			'type': self.type_var.get(),
			'width': self.width_var.get(),
			'height': self.height_var.get(),
			'tileset': self.tileset_var.get(),
			'palette': self.palette_var.get()
		}
		self.dialog.destroy()

	def _on_cancel(self):
		"""Handle cancel button"""
		self.result = None
		self.dialog.destroy()

	def show(self) -> Optional[dict]:
		"""
		Show dialog and wait for result

		Returns:
			Dictionary with map parameters, or None if cancelled
		"""
		self.dialog.wait_window()
		return self.result


class MapPropertiesDialog:
	"""Dialog for editing map properties"""

	def __init__(self, properties: dict, parent=None):
		"""
		Initialize map properties dialog

		Args:
			properties: Current map properties
			parent: Parent window
		"""
		self.properties = properties.copy()
		self.result = None

		# Create dialog window
		self.dialog = tk.Toplevel(parent) if parent else tk.Tk()
		self.dialog.title("Map Properties")
		self.dialog.geometry("450x400")
		self.dialog.resizable(False, False)

		# Center window
		self.dialog.update_idletasks()
		x = (self.dialog.winfo_screenwidth() // 2) - (450 // 2)
		y = (self.dialog.winfo_screenheight() // 2) - (400 // 2)
		self.dialog.geometry(f"+{x}+{y}")

		self._create_widgets()

	def _create_widgets(self):
		"""Create dialog widgets"""
		row = 0

		# Map ID
		tk.Label(self.dialog, text="Map ID:").grid(
			row=row, column=0, padx=10, pady=5, sticky='w'
		)
		self.id_var = tk.IntVar(value=self.properties.get('map_id', 0))
		tk.Spinbox(
			self.dialog, from_=0, to=127, textvariable=self.id_var, width=10
		).grid(row=row, column=1, padx=10, pady=5, sticky='w')
		row += 1

		# Map name
		tk.Label(self.dialog, text="Map Name:").grid(
			row=row, column=0, padx=10, pady=5, sticky='w'
		)
		self.name_var = tk.StringVar(value=self.properties.get('name', 'Untitled'))
		tk.Entry(self.dialog, textvariable=self.name_var, width=30).grid(
			row=row, column=1, padx=10, pady=5
		)
		row += 1

		# Map type
		tk.Label(self.dialog, text="Map Type:").grid(
			row=row, column=0, padx=10, pady=5, sticky='w'
		)
		self.type_var = tk.StringVar(
			value=self.properties.get('map_type', 'Town')
		)
		tk.OptionMenu(
			self.dialog, self.type_var,
			"Overworld", "Town", "Dungeon", "Battle", "Special"
		).grid(row=row, column=1, padx=10, pady=5, sticky='w')
		row += 1

		# Dimensions
		tk.Label(self.dialog, text="Width:").grid(
			row=row, column=0, padx=10, pady=5, sticky='w'
		)
		self.width_var = tk.IntVar(value=self.properties.get('width', 32))
		tk.Spinbox(
			self.dialog, from_=16, to=256, textvariable=self.width_var, width=10
		).grid(row=row, column=1, padx=10, pady=5, sticky='w')
		row += 1

		tk.Label(self.dialog, text="Height:").grid(
			row=row, column=0, padx=10, pady=5, sticky='w'
		)
		self.height_var = tk.IntVar(value=self.properties.get('height', 32))
		tk.Spinbox(
			self.dialog, from_=16, to=256, textvariable=self.height_var, width=10
		).grid(row=row, column=1, padx=10, pady=5, sticky='w')
		row += 1

		# Tileset
		tk.Label(self.dialog, text="Tileset ID:").grid(
			row=row, column=0, padx=10, pady=5, sticky='w'
		)
		self.tileset_var = tk.IntVar(
			value=self.properties.get('tileset_id', 0)
		)
		tk.Spinbox(
			self.dialog, from_=0, to=15, textvariable=self.tileset_var, width=10
		).grid(row=row, column=1, padx=10, pady=5, sticky='w')
		row += 1

		# Palette
		tk.Label(self.dialog, text="Palette ID:").grid(
			row=row, column=0, padx=10, pady=5, sticky='w'
		)
		self.palette_var = tk.IntVar(
			value=self.properties.get('palette_id', 0)
		)
		tk.Spinbox(
			self.dialog, from_=0, to=15, textvariable=self.palette_var, width=10
		).grid(row=row, column=1, padx=10, pady=5, sticky='w')
		row += 1

		# Music
		tk.Label(self.dialog, text="Music ID:").grid(
			row=row, column=0, padx=10, pady=5, sticky='w'
		)
		self.music_var = tk.IntVar(value=self.properties.get('music_id', 0))
		tk.Spinbox(
			self.dialog, from_=0, to=255, textvariable=self.music_var, width=10
		).grid(row=row, column=1, padx=10, pady=5, sticky='w')
		row += 1

		# Encounter rate
		tk.Label(self.dialog, text="Encounter Rate:").grid(
			row=row, column=0, padx=10, pady=5, sticky='w'
		)
		self.encounter_rate_var = tk.IntVar(
			value=self.properties.get('encounter_rate', 0)
		)
		tk.Spinbox(
			self.dialog, from_=0, to=255,
			textvariable=self.encounter_rate_var, width=10
		).grid(row=row, column=1, padx=10, pady=5, sticky='w')
		row += 1

		# Encounter group
		tk.Label(self.dialog, text="Encounter Group:").grid(
			row=row, column=0, padx=10, pady=5, sticky='w'
		)
		self.encounter_group_var = tk.IntVar(
			value=self.properties.get('encounter_group', 0)
		)
		tk.Spinbox(
			self.dialog, from_=0, to=255,
			textvariable=self.encounter_group_var, width=10
		).grid(row=row, column=1, padx=10, pady=5, sticky='w')
		row += 1

		# Spawn position
		tk.Label(self.dialog, text="Spawn X:").grid(
			row=row, column=0, padx=10, pady=5, sticky='w'
		)
		self.spawn_x_var = tk.IntVar(value=self.properties.get('spawn_x', 0))
		tk.Spinbox(
			self.dialog, from_=0, to=255,
			textvariable=self.spawn_x_var, width=10
		).grid(row=row, column=1, padx=10, pady=5, sticky='w')
		row += 1

		tk.Label(self.dialog, text="Spawn Y:").grid(
			row=row, column=0, padx=10, pady=5, sticky='w'
		)
		self.spawn_y_var = tk.IntVar(value=self.properties.get('spawn_y', 0))
		tk.Spinbox(
			self.dialog, from_=0, to=255,
			textvariable=self.spawn_y_var, width=10
		).grid(row=row, column=1, padx=10, pady=5, sticky='w')
		row += 1

		# Buttons
		button_frame = tk.Frame(self.dialog)
		button_frame.grid(row=row, column=0, columnspan=2, pady=20)

		tk.Button(
			button_frame, text="OK", command=self._on_ok, width=10
		).pack(side='left', padx=5)

		tk.Button(
			button_frame, text="Cancel", command=self._on_cancel, width=10
		).pack(side='left', padx=5)

	def _on_ok(self):
		"""Handle OK button"""
		self.result = {
			'map_id': self.id_var.get(),
			'name': self.name_var.get(),
			'map_type': self.type_var.get(),
			'width': self.width_var.get(),
			'height': self.height_var.get(),
			'tileset_id': self.tileset_var.get(),
			'palette_id': self.palette_var.get(),
			'music_id': self.music_var.get(),
			'encounter_rate': self.encounter_rate_var.get(),
			'encounter_group': self.encounter_group_var.get(),
			'spawn_x': self.spawn_x_var.get(),
			'spawn_y': self.spawn_y_var.get()
		}
		self.dialog.destroy()

	def _on_cancel(self):
		"""Handle cancel button"""
		self.result = None
		self.dialog.destroy()

	def show(self) -> Optional[dict]:
		"""
		Show dialog and wait for result

		Returns:
			Dictionary with updated properties, or None if cancelled
		"""
		self.dialog.wait_window()
		return self.result
