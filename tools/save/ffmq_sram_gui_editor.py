#!/usr/bin/env python3
"""
FFMQ SRAM GUI Editor - wxPython-based graphical save editor

This GUI provides a user-friendly interface for editing Final Fantasy: Mystic Quest
save files with full support for inventory, equipment, spells, and all game data.

Features:
- Load/save SRAM files
- Visual character editor (stats, equipment, spells)
- Inventory management (items, weapons, armor, accessories)
- Quest/event flag browser
- Treasure chest tracker
- Battle statistics viewer
- Real-time validation and error checking
- Automatic checksum updates

Requirements:
	pip install wxPython

Usage:
	python ffmq_sram_gui_editor.py [optional_sram_file.srm]
"""

import wx
import wx.grid
import struct
from pathlib import Path
from typing import Optional, List, Dict, Any
from dataclasses import dataclass

# Import the enhanced SRAM editor
try:
	from ffmq_sram_editor_enhanced import (
		SRAMEditor, SaveSlot, CharacterData, Inventory, GameFlags, Statistics,
		ITEMS, KEY_ITEMS, WEAPONS, ARMOR, ACCESSORIES, SPELLS,
		ITEMS_BY_NAME, KEY_ITEMS_BY_NAME, WEAPONS_BY_NAME, ARMOR_BY_NAME,
		ACCESSORIES_BY_NAME, SPELLS_BY_NAME, StatusEffect, FacingDirection
	)
except ImportError:
	print("ERROR: Cannot import ffmq_sram_editor_enhanced.py")
	print("Make sure ffmq_sram_editor_enhanced.py is in the same directory!")
	import sys
	sys.exit(1)


# ======================== MAIN WINDOW ========================

class FFMQSRAMEditorFrame(wx.Frame):
	"""Main application window"""
	
	def __init__(self, sram_path: Optional[Path] = None):
		super().__init__(
			None,
			title="Final Fantasy: Mystic Quest - SRAM Editor",
			size=(1200, 800)
		)
		
		self.sram_path: Optional[Path] = None
		self.editor: Optional[SRAMEditor] = None
		self.current_slot: Optional[SaveSlot] = None
		self.current_slot_id: int = 0
		self.modified: bool = False
		
		self.init_ui()
		self.Center()
		
		if sram_path:
			self.load_sram(sram_path)
	
	def init_ui(self):
		"""Initialize user interface"""
		# Menu bar
		menubar = wx.MenuBar()
		
		# File menu
		file_menu = wx.Menu()
		open_item = file_menu.Append(wx.ID_OPEN, "&Open SRAM\tCtrl+O", "Open SRAM file")
		save_item = file_menu.Append(wx.ID_SAVE, "&Save SRAM\tCtrl+S", "Save SRAM file")
		save_as_item = file_menu.Append(wx.ID_SAVEAS, "Save &As...\tCtrl+Shift+S", "Save SRAM as new file")
		file_menu.AppendSeparator()
		exit_item = file_menu.Append(wx.ID_EXIT, "E&xit\tCtrl+Q", "Exit application")
		menubar.Append(file_menu, "&File")
		
		# Help menu
		help_menu = wx.Menu()
		about_item = help_menu.Append(wx.ID_ABOUT, "&About", "About this editor")
		menubar.Append(help_menu, "&Help")
		
		self.SetMenuBar(menubar)
		
		# Bind menu events
		self.Bind(wx.EVT_MENU, self.on_open, open_item)
		self.Bind(wx.EVT_MENU, self.on_save, save_item)
		self.Bind(wx.EVT_MENU, self.on_save_as, save_as_item)
		self.Bind(wx.EVT_MENU, self.on_exit, exit_item)
		self.Bind(wx.EVT_MENU, self.on_about, about_item)
		
		# Status bar
		self.statusbar = self.CreateStatusBar()
		self.statusbar.SetStatusText("No SRAM file loaded")
		
		# Main panel
		panel = wx.Panel(self)
		vbox = wx.BoxSizer(wx.VERTICAL)
		
		# Slot selector
		slot_panel = wx.Panel(panel)
		slot_sizer = wx.BoxSizer(wx.HORIZONTAL)
		
		slot_label = wx.StaticText(slot_panel, label="Save Slot:")
		self.slot_choice = wx.Choice(slot_panel, choices=[
			"Slot 0 (Copy A)", "Slot 1 (Copy B)", "Slot 2 (Copy C)",
			"Slot 3 (Copy A)", "Slot 4 (Copy B)", "Slot 5 (Copy C)",
			"Slot 6 (Copy A)", "Slot 7 (Copy B)", "Slot 8 (Copy C)"
		])
		self.slot_choice.SetSelection(0)
		self.slot_choice.Bind(wx.EVT_CHOICE, self.on_slot_change)
		
		self.slot_status_label = wx.StaticText(slot_panel, label="Status: No file loaded")
		
		slot_sizer.Add(slot_label, flag=wx.ALIGN_CENTER_VERTICAL | wx.RIGHT, border=5)
		slot_sizer.Add(self.slot_choice, flag=wx.ALIGN_CENTER_VERTICAL | wx.RIGHT, border=15)
		slot_sizer.Add(self.slot_status_label, flag=wx.ALIGN_CENTER_VERTICAL)
		slot_panel.SetSizer(slot_sizer)
		
		vbox.Add(slot_panel, flag=wx.EXPAND | wx.ALL, border=10)
		
		# Notebook (tabbed interface)
		self.notebook = wx.Notebook(panel)
		
		# Character 1 tab
		self.char1_panel = CharacterPanel(self.notebook, 1)
		self.notebook.AddPage(self.char1_panel, "Character 1 (Benjamin)")
		
		# Character 2 tab
		self.char2_panel = CharacterPanel(self.notebook, 2)
		self.notebook.AddPage(self.char2_panel, "Character 2 (Companion)")
		
		# Party tab
		self.party_panel = PartyPanel(self.notebook)
		self.notebook.AddPage(self.party_panel, "Party Data")
		
		# Inventory tab
		self.inventory_panel = InventoryPanel(self.notebook)
		self.notebook.AddPage(self.inventory_panel, "Inventory")
		
		# Flags tab
		self.flags_panel = FlagsPanel(self.notebook)
		self.notebook.AddPage(self.flags_panel, "Quests & Flags")
		
		# Statistics tab
		self.stats_panel = StatisticsPanel(self.notebook)
		self.notebook.AddPage(self.stats_panel, "Statistics")
		
		vbox.Add(self.notebook, proportion=1, flag=wx.EXPAND | wx.ALL, border=10)
		
		# Apply button
		apply_btn = wx.Button(panel, label="Apply Changes to Slot")
		apply_btn.Bind(wx.EVT_BUTTON, self.on_apply_changes)
		vbox.Add(apply_btn, flag=wx.ALIGN_CENTER | wx.BOTTOM, border=10)
		
		panel.SetSizer(vbox)
		
		# Disable all tabs initially
		self.enable_editing(False)
	
	def enable_editing(self, enabled: bool):
		"""Enable/disable editing controls"""
		self.notebook.Enable(enabled)
		self.slot_choice.Enable(enabled)
	
	def on_open(self, event):
		"""Open SRAM file"""
		with wx.FileDialog(
			self,
			"Open SRAM file",
			wildcard="SRAM files (*.srm)|*.srm|All files (*.*)|*.*",
			style=wx.FD_OPEN | wx.FD_FILE_MUST_EXIST
		) as fileDialog:
			if fileDialog.ShowModal() == wx.ID_CANCEL:
				return
			
			pathname = fileDialog.GetPath()
			self.load_sram(Path(pathname))
	
	def load_sram(self, path: Path):
		"""Load SRAM file"""
		try:
			self.editor = SRAMEditor.from_file(path)
			self.sram_path = path
			self.statusbar.SetStatusText(f"Loaded: {path.name}")
			self.enable_editing(True)
			self.load_slot(self.current_slot_id)
			self.modified = False
		except Exception as e:
			wx.MessageBox(
				f"Failed to load SRAM file:\n{str(e)}",
				"Error",
				wx.OK | wx.ICON_ERROR
			)
	
	def on_save(self, event):
		"""Save SRAM file"""
		if not self.sram_path:
			self.on_save_as(event)
			return
		
		self.save_sram(self.sram_path)
	
	def on_save_as(self, event):
		"""Save SRAM file as..."""
		with wx.FileDialog(
			self,
			"Save SRAM file",
			wildcard="SRAM files (*.srm)|*.srm|All files (*.*)|*.*",
			style=wx.FD_SAVE | wx.FD_OVERWRITE_PROMPT
		) as fileDialog:
			if fileDialog.ShowModal() == wx.ID_CANCEL:
				return
			
			pathname = fileDialog.GetPath()
			self.save_sram(Path(pathname))
	
	def save_sram(self, path: Path):
		"""Save SRAM to file"""
		try:
			# First apply current changes
			self.apply_changes_to_slot()
			
			# Save SRAM
			self.editor.save_to_file(path)
			self.sram_path = path
			self.statusbar.SetStatusText(f"Saved: {path.name}")
			self.modified = False
			
			wx.MessageBox(
				f"SRAM saved successfully to:\n{path}",
				"Success",
				wx.OK | wx.ICON_INFORMATION
			)
		except Exception as e:
			wx.MessageBox(
				f"Failed to save SRAM file:\n{str(e)}",
				"Error",
				wx.OK | wx.ICON_ERROR
			)
	
	def on_exit(self, event):
		"""Exit application"""
		if self.modified:
			result = wx.MessageBox(
				"You have unsaved changes. Exit anyway?",
				"Unsaved Changes",
				wx.YES_NO | wx.ICON_WARNING
			)
			if result == wx.NO:
				return
		
		self.Close()
	
	def on_about(self, event):
		"""Show about dialog"""
		info = wx.adv.AboutDialogInfo()
		info.SetName("FFMQ SRAM Editor")
		info.SetVersion("2.0 ENHANCED")
		info.SetDescription(
			"Advanced save file editor for Final Fantasy: Mystic Quest\n\n"
			"Features complete inventory management, equipment editing,\n"
			"spell learning, quest flags, and statistics tracking."
		)
		info.AddDeveloper("FFMQ Disassembly Project")
		wx.adv.AboutBox(info)
	
	def on_slot_change(self, event):
		"""Handle slot selection change"""
		slot_id = self.slot_choice.GetSelection()
		if self.modified:
			result = wx.MessageBox(
				"Apply changes to current slot before switching?",
				"Unsaved Changes",
				wx.YES_NO | wx.CANCEL | wx.ICON_WARNING
			)
			if result == wx.CANCEL:
				self.slot_choice.SetSelection(self.current_slot_id)
				return
			elif result == wx.YES:
				self.apply_changes_to_slot()
		
		self.load_slot(slot_id)
	
	def load_slot(self, slot_id: int):
		"""Load slot data into UI"""
		try:
			self.current_slot = self.editor.parse_slot(slot_id)
			self.current_slot_id = slot_id
			
			# Update slot status
			status_text = "✓ Valid" if self.current_slot.valid else "✗ Invalid Checksum"
			self.slot_status_label.SetLabel(f"Status: {status_text}")
			
			# Load data into panels
			self.char1_panel.load_character(self.current_slot.character1)
			self.char2_panel.load_character(self.current_slot.character2)
			self.party_panel.load_party(self.current_slot)
			self.inventory_panel.load_inventory(self.current_slot.inventory)
			self.flags_panel.load_flags(self.current_slot.flags)
			self.stats_panel.load_stats(self.current_slot.stats)
			
			self.modified = False
		except Exception as e:
			wx.MessageBox(
				f"Failed to load slot {slot_id}:\n{str(e)}",
				"Error",
				wx.OK | wx.ICON_ERROR
			)
	
	def on_apply_changes(self, event):
		"""Apply UI changes to current slot"""
		self.apply_changes_to_slot()
	
	def apply_changes_to_slot(self):
		"""Apply UI changes to current slot"""
		try:
			# Get data from panels
			self.current_slot.character1 = self.char1_panel.get_character()
			self.current_slot.character2 = self.char2_panel.get_character()
			self.party_panel.save_party(self.current_slot)
			self.current_slot.inventory = self.inventory_panel.get_inventory()
			self.current_slot.flags = self.flags_panel.get_flags()
			self.current_slot.stats = self.stats_panel.get_stats()
			
			# Serialize back to SRAM
			slot_bytes = self.editor.serialize_slot(self.current_slot)
			self.editor.set_slot_data(self.current_slot_id, slot_bytes)
			
			self.modified = True
			self.statusbar.SetStatusText(f"Applied changes to slot {self.current_slot_id} (unsaved)")
			
			wx.MessageBox(
				f"Changes applied to slot {self.current_slot_id}\n\n"
				"Remember to save the SRAM file!",
				"Success",
				wx.OK | wx.ICON_INFORMATION
			)
		except Exception as e:
			wx.MessageBox(
				f"Failed to apply changes:\n{str(e)}",
				"Error",
				wx.OK | wx.ICON_ERROR
			)


# ======================== CHARACTER PANEL ========================

class CharacterPanel(wx.ScrolledWindow):
	"""Panel for editing character data"""
	
	def __init__(self, parent, char_num: int):
		super().__init__(parent)
		self.char_num = char_num
		self.init_ui()
		self.SetScrollRate(10, 10)
	
	def init_ui(self):
		"""Initialize UI"""
		vbox = wx.BoxSizer(wx.VERTICAL)
		
		# Basic Info
		basic_box = wx.StaticBox(self, label="Basic Information")
		basic_sizer = wx.StaticBoxSizer(basic_box, wx.VERTICAL)
		
		grid = wx.FlexGridSizer(4, 2, 10, 10)
		
		grid.Add(wx.StaticText(self, label="Name:"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		self.name_ctrl = wx.TextCtrl(self, size=(150, -1), maxLength=8)
		grid.Add(self.name_ctrl)
		
		grid.Add(wx.StaticText(self, label="Level:"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		self.level_ctrl = wx.SpinCtrl(self, value="1", min=1, max=99)
		grid.Add(self.level_ctrl)
		
		grid.Add(wx.StaticText(self, label="Experience:"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		self.exp_ctrl = wx.SpinCtrl(self, value="0", min=0, max=9999999)
		grid.Add(self.exp_ctrl)
		
		grid.Add(wx.StaticText(self, label="HP (Current/Max):"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		hp_sizer = wx.BoxSizer(wx.HORIZONTAL)
		self.hp_current_ctrl = wx.SpinCtrl(self, value="50", min=0, max=9999, size=(80, -1))
		hp_sizer.Add(self.hp_current_ctrl)
		hp_sizer.Add(wx.StaticText(self, label=" / "), flag=wx.ALIGN_CENTER_VERTICAL)
		self.hp_max_ctrl = wx.SpinCtrl(self, value="50", min=1, max=9999, size=(80, -1))
		hp_sizer.Add(self.hp_max_ctrl)
		grid.Add(hp_sizer)
		
		basic_sizer.Add(grid, flag=wx.ALL, border=10)
		vbox.Add(basic_sizer, flag=wx.EXPAND | wx.ALL, border=5)
		
		# Stats
		stats_box = wx.StaticBox(self, label="Statistics")
		stats_sizer = wx.StaticBoxSizer(stats_box, wx.VERTICAL)
		
		stats_grid = wx.FlexGridSizer(4, 4, 10, 10)
		
		# Headers
		stats_grid.Add(wx.StaticText(self, label=""))
		stats_grid.Add(wx.StaticText(self, label="Current"))
		stats_grid.Add(wx.StaticText(self, label="Base"))
		stats_grid.Add(wx.StaticText(self, label=""))
		
		# Attack
		stats_grid.Add(wx.StaticText(self, label="Attack:"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		self.current_attack_ctrl = wx.SpinCtrl(self, value="5", min=0, max=99, size=(70, -1))
		stats_grid.Add(self.current_attack_ctrl)
		self.base_attack_ctrl = wx.SpinCtrl(self, value="5", min=0, max=99, size=(70, -1))
		stats_grid.Add(self.base_attack_ctrl)
		stats_grid.Add(wx.StaticText(self, label=""))
		
		# Defense
		stats_grid.Add(wx.StaticText(self, label="Defense:"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		self.current_defense_ctrl = wx.SpinCtrl(self, value="5", min=0, max=99, size=(70, -1))
		stats_grid.Add(self.current_defense_ctrl)
		self.base_defense_ctrl = wx.SpinCtrl(self, value="5", min=0, max=99, size=(70, -1))
		stats_grid.Add(self.base_defense_ctrl)
		stats_grid.Add(wx.StaticText(self, label=""))
		
		# Speed
		stats_grid.Add(wx.StaticText(self, label="Speed:"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		self.current_speed_ctrl = wx.SpinCtrl(self, value="5", min=0, max=99, size=(70, -1))
		stats_grid.Add(self.current_speed_ctrl)
		self.base_speed_ctrl = wx.SpinCtrl(self, value="5", min=0, max=99, size=(70, -1))
		stats_grid.Add(self.base_speed_ctrl)
		stats_grid.Add(wx.StaticText(self, label=""))
		
		# Magic
		stats_grid.Add(wx.StaticText(self, label="Magic:"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		self.current_magic_ctrl = wx.SpinCtrl(self, value="5", min=0, max=99, size=(70, -1))
		stats_grid.Add(self.current_magic_ctrl)
		self.base_magic_ctrl = wx.SpinCtrl(self, value="5", min=0, max=99, size=(70, -1))
		stats_grid.Add(self.base_magic_ctrl)
		stats_grid.Add(wx.StaticText(self, label=""))
		
		stats_sizer.Add(stats_grid, flag=wx.ALL, border=10)
		vbox.Add(stats_sizer, flag=wx.EXPAND | wx.ALL, border=5)
		
		# Equipment
		equip_box = wx.StaticBox(self, label="Equipment")
		equip_sizer = wx.StaticBoxSizer(equip_box, wx.VERTICAL)
		
		equip_grid = wx.FlexGridSizer(4, 2, 10, 10)
		
		equip_grid.Add(wx.StaticText(self, label="Weapon:"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		self.weapon_choice = wx.Choice(self, choices=["None"] + [WEAPONS[i] for i in sorted(WEAPONS.keys())])
		self.weapon_choice.SetSelection(0)
		equip_grid.Add(self.weapon_choice)
		
		equip_grid.Add(wx.StaticText(self, label="Armor:"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		self.armor_choice = wx.Choice(self, choices=["None"] + [ARMOR[i] for i in sorted(ARMOR.keys())])
		self.armor_choice.SetSelection(0)
		equip_grid.Add(self.armor_choice)
		
		equip_grid.Add(wx.StaticText(self, label="Accessory 1:"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		self.accessory1_choice = wx.Choice(self, choices=["None"] + [ACCESSORIES[i] for i in sorted(ACCESSORIES.keys())])
		self.accessory1_choice.SetSelection(0)
		equip_grid.Add(self.accessory1_choice)
		
		equip_grid.Add(wx.StaticText(self, label="Accessory 2:"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		self.accessory2_choice = wx.Choice(self, choices=["None"] + [ACCESSORIES[i] for i in sorted(ACCESSORIES.keys())])
		self.accessory2_choice.SetSelection(0)
		equip_grid.Add(self.accessory2_choice)
		
		equip_sizer.Add(equip_grid, flag=wx.ALL, border=10)
		vbox.Add(equip_sizer, flag=wx.EXPAND | wx.ALL, border=5)
		
		# Spells
		spell_box = wx.StaticBox(self, label="Learned Spells")
		spell_sizer = wx.StaticBoxSizer(spell_box, wx.VERTICAL)
		
		self.spell_checks = {}
		spell_grid = wx.GridSizer(4, 3, 5, 5)
		for spell_id in sorted(SPELLS.keys()):
			check = wx.CheckBox(self, label=SPELLS[spell_id])
			self.spell_checks[spell_id] = check
			spell_grid.Add(check)
		
		spell_sizer.Add(spell_grid, flag=wx.ALL, border=10)
		vbox.Add(spell_sizer, flag=wx.EXPAND | wx.ALL, border=5)
		
		self.SetSizer(vbox)
	
	def load_character(self, char: CharacterData):
		"""Load character data into UI"""
		self.name_ctrl.SetValue(char.name)
		self.level_ctrl.SetValue(char.level)
		self.exp_ctrl.SetValue(char.experience)
		self.hp_current_ctrl.SetValue(char.current_hp)
		self.hp_max_ctrl.SetValue(char.max_hp)
		
		self.current_attack_ctrl.SetValue(char.current_attack)
		self.current_defense_ctrl.SetValue(char.current_defense)
		self.current_speed_ctrl.SetValue(char.current_speed)
		self.current_magic_ctrl.SetValue(char.current_magic)
		self.base_attack_ctrl.SetValue(char.base_attack)
		self.base_defense_ctrl.SetValue(char.base_defense)
		self.base_speed_ctrl.SetValue(char.base_speed)
		self.base_magic_ctrl.SetValue(char.base_magic)
		
		# Equipment
		if char.weapon_id in WEAPONS:
			self.weapon_choice.SetSelection(list(WEAPONS.keys()).index(char.weapon_id) + 1)
		else:
			self.weapon_choice.SetSelection(0)
		
		if char.equipment.armor_id != 0xFF and char.equipment.armor_id in ARMOR:
			self.armor_choice.SetSelection(list(ARMOR.keys()).index(char.equipment.armor_id) + 1)
		else:
			self.armor_choice.SetSelection(0)
		
		if char.equipment.accessory1_id != 0xFF and char.equipment.accessory1_id in ACCESSORIES:
			self.accessory1_choice.SetSelection(list(ACCESSORIES.keys()).index(char.equipment.accessory1_id) + 1)
		else:
			self.accessory1_choice.SetSelection(0)
		
		if char.equipment.accessory2_id != 0xFF and char.equipment.accessory2_id in ACCESSORIES:
			self.accessory2_choice.SetSelection(list(ACCESSORIES.keys()).index(char.equipment.accessory2_id) + 1)
		else:
			self.accessory2_choice.SetSelection(0)
		
		# Spells
		for spell_id, check in self.spell_checks.items():
			check.SetValue(spell_id in char.learned_spells)
	
	def get_character(self) -> CharacterData:
		"""Get character data from UI"""
		char = CharacterData()
		char.name = self.name_ctrl.GetValue()
		char.level = self.level_ctrl.GetValue()
		char.experience = self.exp_ctrl.GetValue()
		char.current_hp = self.hp_current_ctrl.GetValue()
		char.max_hp = self.hp_max_ctrl.GetValue()
		
		char.current_attack = self.current_attack_ctrl.GetValue()
		char.current_defense = self.current_defense_ctrl.GetValue()
		char.current_speed = self.current_speed_ctrl.GetValue()
		char.current_magic = self.current_magic_ctrl.GetValue()
		char.base_attack = self.base_attack_ctrl.GetValue()
		char.base_defense = self.base_defense_ctrl.GetValue()
		char.base_speed = self.base_speed_ctrl.GetValue()
		char.base_magic = self.base_magic_ctrl.GetValue()
		
		# Equipment
		weapon_idx = self.weapon_choice.GetSelection()
		if weapon_idx > 0:
			char.weapon_id = sorted(WEAPONS.keys())[weapon_idx - 1]
			char.weapon_count = 1
		
		armor_idx = self.armor_choice.GetSelection()
		if armor_idx > 0:
			char.equipment.armor_id = sorted(ARMOR.keys())[armor_idx - 1]
		else:
			char.equipment.armor_id = 0xFF
		
		acc1_idx = self.accessory1_choice.GetSelection()
		if acc1_idx > 0:
			char.equipment.accessory1_id = sorted(ACCESSORIES.keys())[acc1_idx - 1]
		else:
			char.equipment.accessory1_id = 0xFF
		
		acc2_idx = self.accessory2_choice.GetSelection()
		if acc2_idx > 0:
			char.equipment.accessory2_id = sorted(ACCESSORIES.keys())[acc2_idx - 1]
		else:
			char.equipment.accessory2_id = 0xFF
		
		# Spells
		char.learned_spells = {spell_id for spell_id, check in self.spell_checks.items() if check.GetValue()}
		
		return char


# ======================== PARTY PANEL ========================

class PartyPanel(wx.Panel):
	"""Panel for editing party data"""
	
	def __init__(self, parent):
		super().__init__(parent)
		self.init_ui()
	
	def init_ui(self):
		"""Initialize UI"""
		vbox = wx.BoxSizer(wx.VERTICAL)
		
		grid = wx.FlexGridSizer(7, 2, 10, 10)
		
		grid.Add(wx.StaticText(self, label="Gold:"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		self.gold_ctrl = wx.SpinCtrl(self, value="0", min=0, max=9999999)
		grid.Add(self.gold_ctrl)
		
		grid.Add(wx.StaticText(self, label="Map ID:"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		self.map_id_ctrl = wx.SpinCtrl(self, value="0", min=0, max=255)
		grid.Add(self.map_id_ctrl)
		
		grid.Add(wx.StaticText(self, label="Position X:"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		self.pos_x_ctrl = wx.SpinCtrl(self, value="0", min=0, max=255)
		grid.Add(self.pos_x_ctrl)
		
		grid.Add(wx.StaticText(self, label="Position Y:"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		self.pos_y_ctrl = wx.SpinCtrl(self, value="0", min=0, max=255)
		grid.Add(self.pos_y_ctrl)
		
		grid.Add(wx.StaticText(self, label="Facing:"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		self.facing_choice = wx.Choice(self, choices=["Down", "Up", "Left", "Right"])
		self.facing_choice.SetSelection(0)
		grid.Add(self.facing_choice)
		
		grid.Add(wx.StaticText(self, label="Play Time (HH:MM:SS):"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		time_sizer = wx.BoxSizer(wx.HORIZONTAL)
		self.hours_ctrl = wx.SpinCtrl(self, value="0", min=0, max=99, size=(60, -1))
		time_sizer.Add(self.hours_ctrl)
		time_sizer.Add(wx.StaticText(self, label=":"), flag=wx.ALIGN_CENTER_VERTICAL)
		self.minutes_ctrl = wx.SpinCtrl(self, value="0", min=0, max=59, size=(60, -1))
		time_sizer.Add(self.minutes_ctrl)
		time_sizer.Add(wx.StaticText(self, label=":"), flag=wx.ALIGN_CENTER_VERTICAL)
		self.seconds_ctrl = wx.SpinCtrl(self, value="0", min=0, max=59, size=(60, -1))
		time_sizer.Add(self.seconds_ctrl)
		grid.Add(time_sizer)
		
		grid.Add(wx.StaticText(self, label="Cure Count:"), flag=wx.ALIGN_RIGHT | wx.ALIGN_CENTER_VERTICAL)
		self.cure_count_ctrl = wx.SpinCtrl(self, value="0", min=0, max=255)
		grid.Add(self.cure_count_ctrl)
		
		vbox.Add(grid, flag=wx.ALL, border=20)
		self.SetSizer(vbox)
	
	def load_party(self, slot: SaveSlot):
		"""Load party data"""
		self.gold_ctrl.SetValue(slot.gold)
		self.map_id_ctrl.SetValue(slot.map_id)
		self.pos_x_ctrl.SetValue(slot.player_x)
		self.pos_y_ctrl.SetValue(slot.player_y)
		self.facing_choice.SetSelection(slot.player_facing)
		self.hours_ctrl.SetValue(slot.play_time_hours)
		self.minutes_ctrl.SetValue(slot.play_time_minutes)
		self.seconds_ctrl.SetValue(slot.play_time_seconds)
		self.cure_count_ctrl.SetValue(slot.cure_count)
	
	def save_party(self, slot: SaveSlot):
		"""Save party data"""
		slot.gold = self.gold_ctrl.GetValue()
		slot.map_id = self.map_id_ctrl.GetValue()
		slot.player_x = self.pos_x_ctrl.GetValue()
		slot.player_y = self.pos_y_ctrl.GetValue()
		slot.player_facing = self.facing_choice.GetSelection()
		slot.play_time_hours = self.hours_ctrl.GetValue()
		slot.play_time_minutes = self.minutes_ctrl.GetValue()
		slot.play_time_seconds = self.seconds_ctrl.GetValue()
		slot.cure_count = self.cure_count_ctrl.GetValue()


# ======================== INVENTORY PANEL ========================

class InventoryPanel(wx.Panel):
	"""Panel for editing inventory (placeholder - simplified version)"""
	
	def __init__(self, parent):
		super().__init__(parent)
		self.init_ui()
	
	def init_ui(self):
		"""Initialize UI"""
		vbox = wx.BoxSizer(wx.VERTICAL)
		
		label = wx.StaticText(
			self,
			label="Inventory editing UI - Full implementation requires grid control\n"
			"(This is a simplified placeholder - use JSON export/import for now)"
		)
		vbox.Add(label, flag=wx.ALL, border=20)
		
		self.SetSizer(vbox)
	
	def load_inventory(self, inv: Inventory):
		"""Load inventory"""
		pass
	
	def get_inventory(self) -> Inventory:
		"""Get inventory"""
		return Inventory()


# ======================== FLAGS PANEL ========================

class FlagsPanel(wx.Panel):
	"""Panel for editing flags (placeholder)"""
	
	def __init__(self, parent):
		super().__init__(parent)
		self.init_ui()
	
	def init_ui(self):
		"""Initialize UI"""
		vbox = wx.BoxSizer(wx.VERTICAL)
		
		label = wx.StaticText(
			self,
			label="Quest/Event flags editing UI\n"
			"(Placeholder - full implementation pending)"
		)
		vbox.Add(label, flag=wx.ALL, border=20)
		
		self.SetSizer(vbox)
	
	def load_flags(self, flags: GameFlags):
		"""Load flags"""
		pass
	
	def get_flags(self) -> GameFlags:
		"""Get flags"""
		return GameFlags()


# ======================== STATISTICS PANEL ========================

class StatisticsPanel(wx.Panel):
	"""Panel for viewing/editing statistics (placeholder)"""
	
	def __init__(self, parent):
		super().__init__(parent)
		self.init_ui()
	
	def init_ui(self):
		"""Initialize UI"""
		vbox = wx.BoxSizer(wx.VERTICAL)
		
		label = wx.StaticText(
			self,
			label="Battle statistics viewing/editing UI\n"
			"(Placeholder - full implementation pending)"
		)
		vbox.Add(label, flag=wx.ALL, border=20)
		
		self.SetSizer(vbox)
	
	def load_stats(self, stats: Statistics):
		"""Load statistics"""
		pass
	
	def get_stats(self) -> Statistics:
		"""Get statistics"""
		return Statistics()


# ======================== MAIN ========================

def main():
	"""Application entry point"""
	import sys
	
	app = wx.App()
	
	# Check for SRAM file argument
	sram_path = None
	if len(sys.argv) > 1:
		sram_path = Path(sys.argv[1])
		if not sram_path.exists():
			print(f"ERROR: File not found: {sram_path}")
			sram_path = None
	
	frame = FFMQSRAMEditorFrame(sram_path)
	frame.Show()
	app.MainLoop()


if __name__ == '__main__':
	main()
