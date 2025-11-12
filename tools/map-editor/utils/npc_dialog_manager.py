"""
NPC Dialog Manager - Links map NPCs to dialog IDs and manages NPC dialog editing

This module provides:
- NPC -> Dialog ID mapping
- Quick dialog editing from map editor
- NPC conversation flow visualization
- Dialog triggers and conditions
"""

import pygame
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, field
from pathlib import Path
import json


@dataclass
class NPCDialog:
	"""Represents an NPC's dialog configuration"""
	npc_id: int
	map_id: int
	position: Tuple[int, int]  # (x, y) on map
	name: str = "NPC"

	# Dialog IDs for different conditions
	default_dialog_id: int = 0x0000
	flag_dialogs: Dict[int, int] = field(default_factory=dict)  # flag_id -> dialog_id
	item_dialogs: Dict[int, int] = field(default_factory=dict)  # item_id -> dialog_id
	event_dialog_id: Optional[int] = None  # For special events

	# Behavior
	repeatable: bool = True  # Can talk to NPC multiple times
	auto_face_player: bool = True  # NPC faces player when talked to
	trigger_distance: int = 1  # How close player must be (in tiles)

	# Metadata
	notes: str = ""

	def get_active_dialog_id(self, flags: set, items: set) -> int:
		"""
		Get the dialog ID that should be shown based on current game state

		Args:
			flags: Set of active flag IDs
			items: Set of items in inventory

		Returns:
			Dialog ID to show
		"""
		# Check flag-based dialogs (highest priority)
		for flag_id, dialog_id in self.flag_dialogs.items():
			if flag_id in flags:
				return dialog_id

		# Check item-based dialogs
		for item_id, dialog_id in self.item_dialogs.items():
			if item_id in items:
				return dialog_id

		# Check event dialog
		if self.event_dialog_id is not None:
			return self.event_dialog_id

		# Default dialog
		return self.default_dialog_id


class NPCDialogManager:
	"""Manages all NPC dialogs in the game"""

	def __init__(self, data_file: str = None):
		"""
		Args:
			data_file: Path to JSON file containing NPC dialog mappings
		"""
		self.npc_dialogs: Dict[Tuple[int, int], NPCDialog] = {}  # (map_id, npc_id) -> NPCDialog
		self.data_file = data_file

		if data_file and Path(data_file).exists():
			self.load(data_file)

	def add_npc(self, npc: NPCDialog):
		"""Add an NPC dialog configuration"""
		key = (npc.map_id, npc.npc_id)
		self.npc_dialogs[key] = npc

	def get_npc(self, map_id: int, npc_id: int) -> Optional[NPCDialog]:
		"""Get NPC dialog configuration"""
		return self.npc_dialogs.get((map_id, npc_id))

	def remove_npc(self, map_id: int, npc_id: int):
		"""Remove NPC dialog configuration"""
		key = (map_id, npc_id)
		if key in self.npc_dialogs:
			del self.npc_dialogs[key]

	def get_npcs_for_map(self, map_id: int) -> List[NPCDialog]:
		"""Get all NPCs on a specific map"""
		return [npc for (mid, _), npc in self.npc_dialogs.items() if mid == map_id]

	def get_npcs_with_dialog(self, dialog_id: int) -> List[NPCDialog]:
		"""Find all NPCs that use a specific dialog ID"""
		npcs = []
		for npc in self.npc_dialogs.values():
			if npc.default_dialog_id == dialog_id:
				npcs.append(npc)
			elif dialog_id in npc.flag_dialogs.values():
				npcs.append(npc)
			elif dialog_id in npc.item_dialogs.values():
				npcs.append(npc)
			elif npc.event_dialog_id == dialog_id:
				npcs.append(npc)
		return npcs

	def save(self, filepath: str = None):
		"""Save NPC dialog mappings to JSON file"""
		filepath = filepath or self.data_file
		if not filepath:
			raise ValueError("No filepath specified")

		data = {
			"npcs": [
				{
					"npc_id": npc.npc_id,
					"map_id": npc.map_id,
					"position": list(npc.position),
					"name": npc.name,
					"default_dialog_id": npc.default_dialog_id,
					"flag_dialogs": {str(k): v for k, v in npc.flag_dialogs.items()},
					"item_dialogs": {str(k): v for k, v in npc.item_dialogs.items()},
					"event_dialog_id": npc.event_dialog_id,
					"repeatable": npc.repeatable,
					"auto_face_player": npc.auto_face_player,
					"trigger_distance": npc.trigger_distance,
					"notes": npc.notes
				}
				for npc in self.npc_dialogs.values()
			]
		}

		with open(filepath, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent=2)

	def load(self, filepath: str):
		"""Load NPC dialog mappings from JSON file"""
		with open(filepath, 'r', encoding='utf-8') as f:
			data = json.load(f)

		self.npc_dialogs.clear()

		for npc_data in data.get("npcs", []):
			npc = NPCDialog(
				npc_id=npc_data["npc_id"],
				map_id=npc_data["map_id"],
				position=tuple(npc_data["position"]),
				name=npc_data.get("name", "NPC"),
				default_dialog_id=npc_data.get("default_dialog_id", 0),
				flag_dialogs={int(k): v for k, v in npc_data.get("flag_dialogs", {}).items()},
				item_dialogs={int(k): v for k, v in npc_data.get("item_dialogs", {}).items()},
				event_dialog_id=npc_data.get("event_dialog_id"),
				repeatable=npc_data.get("repeatable", True),
				auto_face_player=npc_data.get("auto_face_player", True),
				trigger_distance=npc_data.get("trigger_distance", 1),
				notes=npc_data.get("notes", "")
			)
			self.add_npc(npc)

		self.data_file = filepath


class NPCDialogPanel:
	"""UI panel for editing NPC dialog configuration"""

	def __init__(self, rect: pygame.Rect):
		"""
		Args:
			rect: Rectangle for the panel
		"""
		self.rect = rect
		self.npc: Optional[NPCDialog] = None

		# Colors
		self.bg_color = (40, 40, 50)
		self.text_color = (220, 220, 220)
		self.text_dim_color = (140, 140, 150)
		self.border_color = (60, 60, 70)
		self.highlight_color = (70, 130, 180)

		# Scroll state
		self.scroll_offset = 0
		self.max_scroll = 0

	def set_npc(self, npc: Optional[NPCDialog]):
		"""Set the NPC to edit"""
		self.npc = npc
		self.scroll_offset = 0

	def handle_event(self, event: pygame.event.Event) -> bool:
		"""Handle events"""
		if not self.npc:
			return False

		if event.type == pygame.MOUSEWHEEL:
			if self.rect.collidepoint(pygame.mouse.get_pos()):
				self.scroll_offset -= event.y * 20
				self.scroll_offset = max(0, min(self.scroll_offset, self.max_scroll))
				return True

		return False

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw the panel"""
		# Background
		pygame.draw.rect(surface, self.bg_color, self.rect)
		pygame.draw.rect(surface, self.border_color, self.rect, 1)

		if not self.npc:
			# No NPC selected
			text = font.render("No NPC selected", True, self.text_dim_color)
			text_rect = text.get_rect(center=self.rect.center)
			surface.blit(text, text_rect)
			return

		# Create clipping surface
		content_surface = pygame.Surface((self.rect.width - 20, self.rect.height - 20))
		content_surface.fill(self.bg_color)

		y = -self.scroll_offset

		# Title
		title = font.render(f"NPC Dialog: {self.npc.name}", True, self.text_color)
		content_surface.blit(title, (10, y))
		y += 35

		# NPC Info
		info_lines = [
			f"Map ID: {self.npc.map_id}",
			f"NPC ID: {self.npc.npc_id}",
			f"Position: ({self.npc.position[0]}, {self.npc.position[1]})",
			"",
			"Dialogs:",
			f"  Default: 0x{self.npc.default_dialog_id:04X}",
		]

		# Flag-based dialogs
		if self.npc.flag_dialogs:
			info_lines.append("  Flag-based:")
			for flag_id, dialog_id in self.npc.flag_dialogs.items():
				info_lines.append(f"	Flag {flag_id:04X} → Dialog {dialog_id:04X}")

		# Item-based dialogs
		if self.npc.item_dialogs:
			info_lines.append("  Item-based:")
			for item_id, dialog_id in self.npc.item_dialogs.items():
				info_lines.append(f"	Item {item_id:04X} → Dialog {dialog_id:04X}")

		# Event dialog
		if self.npc.event_dialog_id is not None:
			info_lines.append(f"  Event: 0x{self.npc.event_dialog_id:04X}")

		# Behavior
		info_lines.extend([
			"",
			"Behavior:",
			f"  Repeatable: {self.npc.repeatable}",
			f"  Auto-face: {self.npc.auto_face_player}",
			f"  Trigger distance: {self.npc.trigger_distance} tiles",
		])

		# Notes
		if self.npc.notes:
			info_lines.extend([
				"",
				"Notes:",
				f"  {self.npc.notes}",
			])

		# Draw all lines
		for line in info_lines:
			text = font.render(line, True, self.text_dim_color if line.startswith("  ") else self.text_color)
			content_surface.blit(text, (10, y))
			y += 25

		# Calculate max scroll
		self.max_scroll = max(0, y - (self.rect.height - 20))

		# Blit content surface with clipping
		surface.blit(content_surface, (self.rect.x + 10, self.rect.y + 10))

		# Draw scrollbar if needed
		if self.max_scroll > 0:
			scrollbar_height = max(20, (self.rect.height - 20) * (self.rect.height - 20) // y)
			scrollbar_y = self.rect.y + 10 + (self.rect.height - 20 - scrollbar_height) * self.scroll_offset // self.max_scroll
			scrollbar_rect = pygame.Rect(self.rect.right - 10, scrollbar_y, 6, scrollbar_height)
			pygame.draw.rect(surface, self.highlight_color, scrollbar_rect, border_radius=3)


def demo_npc_dialog_manager():
	"""Demo the NPC dialog manager"""

	# Create manager
	manager = NPCDialogManager()

	# Add some NPCs
	npc1 = NPCDialog(
		npc_id=1,
		map_id=0x01,
		position=(10, 15),
		name="Old Man",
		default_dialog_id=0x0001,
		flag_dialogs={0x10: 0x0002, 0x20: 0x0003},
		repeatable=True,
		notes="Gives info about the Crystal"
	)
	manager.add_npc(npc1)

	npc2 = NPCDialog(
		npc_id=2,
		map_id=0x01,
		position=(20, 15),
		name="Shopkeeper",
		default_dialog_id=0x0010,
		item_dialogs={0x05: 0x0011},
		repeatable=True,
		notes="Sells items"
	)
	manager.add_npc(npc2)

	# Test getting active dialog
	print("Testing NPC dialog selection:")
	print(f"Old Man with no flags: 0x{npc1.get_active_dialog_id(set(), set()):04X}")
	print(f"Old Man with flag 0x10: 0x{npc1.get_active_dialog_id({0x10}, set()):04X}")
	print(f"Old Man with flag 0x20: 0x{npc1.get_active_dialog_id({0x20}, set()):04X}")

	# Test finding NPCs by dialog
	print(f"\nNPCs using dialog 0x0001: {[n.name for n in manager.get_npcs_with_dialog(0x0001)]}")
	print(f"NPCs using dialog 0x0002: {[n.name for n in manager.get_npcs_with_dialog(0x0002)]}")

	# Test save/load
	test_file = "test_npc_dialogs.json"
	manager.save(test_file)
	print(f"\nSaved to {test_file}")

	# Load
	manager2 = NPCDialogManager(test_file)
	print(f"Loaded {len(manager2.npc_dialogs)} NPCs")

	for (map_id, npc_id), npc in manager2.npc_dialogs.items():
		print(f"  {npc.name} (Map {map_id:02X}, NPC {npc_id:02X}): Dialog 0x{npc.default_dialog_id:04X}")


if __name__ == '__main__':
	demo_npc_dialog_manager()
