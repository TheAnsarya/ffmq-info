#!/usr/bin/env python3
"""
Advanced Event System Editor

Comprehensive visual event editor for SNES games with node-based scripting.
Features include:
- Visual node-based event editing
- Event triggers (touch, interact, auto, timer, conditional)
- Event actions (dialog, item, battle, teleport, animation, sound, flag)
- Event flow control (if/else, loops, wait, parallel)
- Variable and flag management
- Event chains and dependencies
- Real-time preview and validation
- Template library for common events
- Export to multiple formats (JSON, binary, assembly)

Event Types:
- NPC Dialog: Conversation trees with choices
- Treasure Chests: Items with conditions
- Doors/Warps: Teleportation with animations
- Cutscenes: Scripted sequences
- Triggers: Area-based events
- Battles: Enemy encounters with conditions
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple, Any
import pygame
import json


class TriggerType(Enum):
	"""Event trigger conditions"""
	ON_TOUCH = "on_touch"
	ON_INTERACT = "on_interact"
	ON_AUTO = "on_auto"
	ON_ENTER = "on_enter"
	ON_EXIT = "on_exit"
	ON_TIMER = "on_timer"
	ON_FLAG = "on_flag"
	ON_ITEM = "on_item"
	ON_LEVEL = "on_level"


class ActionType(Enum):
	"""Event action types"""
	SHOW_DIALOG = "show_dialog"
	GIVE_ITEM = "give_item"
	TAKE_ITEM = "take_item"
	START_BATTLE = "start_battle"
	TELEPORT = "teleport"
	PLAY_SOUND = "play_sound"
	PLAY_MUSIC = "play_music"
	SET_FLAG = "set_flag"
	CLEAR_FLAG = "clear_flag"
	ADD_GOLD = "add_gold"
	REMOVE_GOLD = "remove_gold"
	FADE_OUT = "fade_out"
	FADE_IN = "fade_in"
	SHAKE_SCREEN = "shake_screen"
	SHOW_ANIMATION = "show_animation"
	MOVE_NPC = "move_npc"
	SHOW_SPRITE = "show_sprite"
	HIDE_SPRITE = "hide_sprite"
	WAIT = "wait"
	CAMERA_MOVE = "camera_move"
	WEATHER = "weather"


class ConditionType(Enum):
	"""Conditional check types"""
	FLAG_SET = "flag_set"
	FLAG_CLEAR = "flag_clear"
	HAS_ITEM = "has_item"
	GOLD_GREATER = "gold_greater"
	GOLD_LESS = "gold_less"
	LEVEL_GREATER = "level_greater"
	LEVEL_LESS = "level_less"
	PARTY_SIZE = "party_size"
	TIME_OF_DAY = "time_of_day"
	RANDOM = "random"


@dataclass
class EventNode:
	"""Single node in event graph"""
	node_id: int
	node_type: str  # "trigger", "action", "condition", "branch"
	position: Tuple[int, int]
	parameters: Dict[str, Any] = field(default_factory=dict)
	next_nodes: List[int] = field(default_factory=list)
	true_branch: Optional[int] = None  # For conditions
	false_branch: Optional[int] = None

	def get_color(self) -> Tuple[int, int, int]:
		"""Get node color by type"""
		colors = {
			"trigger": (100, 200, 100),
			"action": (100, 150, 255),
			"condition": (255, 200, 100),
			"branch": (200, 100, 200),
			"end": (255, 100, 100),
		}
		return colors.get(self.node_type, (150, 150, 150))


@dataclass
class EventTemplate:
	"""Reusable event template"""
	name: str
	description: str
	category: str
	nodes: List[EventNode]

	def instantiate(self, start_id: int) -> List[EventNode]:
		"""Create instances of template nodes with new IDs"""
		id_map = {}
		new_nodes = []

		for i, node in enumerate(self.nodes):
			new_id = start_id + i
			id_map[node.node_id] = new_id

			new_node = EventNode(
				node_id=new_id,
				node_type=node.node_type,
				position=node.position,
				parameters=node.parameters.copy(),
				next_nodes=[],
				true_branch=node.true_branch,
				false_branch=node.false_branch
			)
			new_nodes.append(new_node)

		# Remap node references
		for new_node, old_node in zip(new_nodes, self.nodes):
			new_node.next_nodes = [id_map[n] for n in old_node.next_nodes if n in id_map]
			if old_node.true_branch is not None and old_node.true_branch in id_map:
				new_node.true_branch = id_map[old_node.true_branch]
			if old_node.false_branch is not None and old_node.false_branch in id_map:
				new_node.false_branch = id_map[old_node.false_branch]

		return new_nodes


@dataclass
class GameEvent:
	"""Complete event definition"""
	event_id: int
	name: str
	trigger: TriggerType
	nodes: List[EventNode]
	variables: Dict[str, Any] = field(default_factory=dict)
	enabled: bool = True
	one_time: bool = False
	priority: int = 0

	def to_dict(self) -> dict:
		"""Convert to dictionary"""
		return {
			"event_id": self.event_id,
			"name": self.name,
			"trigger": self.trigger.value,
			"nodes": [
				{
					"node_id": n.node_id,
					"node_type": n.node_type,
					"position": n.position,
					"parameters": n.parameters,
					"next_nodes": n.next_nodes,
					"true_branch": n.true_branch,
					"false_branch": n.false_branch,
				}
				for n in self.nodes
			],
			"variables": self.variables,
			"enabled": self.enabled,
			"one_time": self.one_time,
			"priority": self.priority,
		}

	@staticmethod
	def from_dict(data: dict) -> 'GameEvent':
		"""Create from dictionary"""
		nodes = [
			EventNode(
				node_id=n["node_id"],
				node_type=n["node_type"],
				position=tuple(n["position"]),
				parameters=n["parameters"],
				next_nodes=n["next_nodes"],
				true_branch=n.get("true_branch"),
				false_branch=n.get("false_branch"),
			)
			for n in data["nodes"]
		]

		return GameEvent(
			event_id=data["event_id"],
			name=data["name"],
			trigger=TriggerType(data["trigger"]),
			nodes=nodes,
			variables=data.get("variables", {}),
			enabled=data.get("enabled", True),
			one_time=data.get("one_time", False),
			priority=data.get("priority", 0),
		)


class TemplateLibrary:
	"""Library of event templates"""

	def __init__(self):
		self.templates: Dict[str, List[EventTemplate]] = {}
		self._init_templates()

	def _init_templates(self):
		"""Initialize default templates"""
		# Simple dialog template
		dialog_nodes = [
			EventNode(0, "trigger", (100, 100), {"type": "on_interact"}),
			EventNode(1, "action", (300, 100), {
				"type": "show_dialog",
				"text": "Hello, traveler!",
				"speaker": "NPC"
			}, next_nodes=[2]),
			EventNode(2, "end", (500, 100), {}),
		]

		self.add_template(EventTemplate(
			name="Simple Dialog",
			description="Basic NPC conversation",
			category="Dialog",
			nodes=dialog_nodes
		))

		# Treasure chest template
		chest_nodes = [
			EventNode(0, "trigger", (100, 100), {"type": "on_interact"}),
			EventNode(1, "condition", (300, 100), {
				"type": "flag_clear",
				"flag": "chest_opened"
			}, true_branch=2, false_branch=4),
			EventNode(2, "action", (500, 50), {
				"type": "give_item",
				"item_id": 1,
				"quantity": 1
			}, next_nodes=[3]),
			EventNode(3, "action", (700, 50), {
				"type": "set_flag",
				"flag": "chest_opened"
			}, next_nodes=[5]),
			EventNode(4, "action", (500, 150), {
				"type": "show_dialog",
				"text": "The chest is empty."
			}, next_nodes=[5]),
			EventNode(5, "end", (900, 100), {}),
		]

		self.add_template(EventTemplate(
			name="Treasure Chest",
			description="Chest with one-time item",
			category="Items",
			nodes=chest_nodes
		))

		# Door/Warp template
		warp_nodes = [
			EventNode(0, "trigger", (100, 100), {"type": "on_touch"}),
			EventNode(1, "action", (300, 100), {
				"type": "fade_out",
				"duration": 30
			}, next_nodes=[2]),
			EventNode(2, "action", (500, 100), {
				"type": "teleport",
				"map_id": 1,
				"x": 10,
				"y": 10
			}, next_nodes=[3]),
			EventNode(3, "action", (700, 100), {
				"type": "fade_in",
				"duration": 30
			}, next_nodes=[4]),
			EventNode(4, "end", (900, 100), {}),
		]

		self.add_template(EventTemplate(
			name="Door Warp",
			description="Teleport to another map",
			category="Movement",
			nodes=warp_nodes
		))

		# Battle encounter template
		battle_nodes = [
			EventNode(0, "trigger", (100, 100), {"type": "on_touch"}),
			EventNode(1, "condition", (300, 100), {
				"type": "random",
				"chance": 30
			}, true_branch=2, false_branch=5),
			EventNode(2, "action", (500, 50), {
				"type": "fade_out",
				"duration": 15
			}, next_nodes=[3]),
			EventNode(3, "action", (700, 50), {
				"type": "start_battle",
				"formation_id": 1
			}, next_nodes=[4]),
			EventNode(4, "action", (900, 50), {
				"type": "fade_in",
				"duration": 15
			}, next_nodes=[5]),
			EventNode(5, "end", (1100, 100), {}),
		]

		self.add_template(EventTemplate(
			name="Random Battle",
			description="Random encounter trigger",
			category="Battle",
			nodes=battle_nodes
		))

		# Shop template
		shop_nodes = [
			EventNode(0, "trigger", (100, 100), {"type": "on_interact"}),
			EventNode(1, "action", (300, 100), {
				"type": "show_dialog",
				"text": "Welcome to my shop!",
				"speaker": "Shopkeeper"
			}, next_nodes=[2]),
			EventNode(2, "action", (500, 100), {
				"type": "open_shop",
				"shop_id": 1
			}, next_nodes=[3]),
			EventNode(3, "action", (700, 100), {
				"type": "show_dialog",
				"text": "Thank you! Come again!",
				"speaker": "Shopkeeper"
			}, next_nodes=[4]),
			EventNode(4, "end", (900, 100), {}),
		]

		self.add_template(EventTemplate(
			name="Shop NPC",
			description="Shopkeeper with dialog",
			category="Dialog",
			nodes=shop_nodes
		))

		# Quest giver template
		quest_nodes = [
			EventNode(0, "trigger", (100, 100), {"type": "on_interact"}),
			EventNode(1, "condition", (300, 100), {
				"type": "flag_clear",
				"flag": "quest_accepted"
			}, true_branch=2, false_branch=5),
			EventNode(2, "action", (500, 50), {
				"type": "show_dialog",
				"text": "I need your help! Will you assist me?",
				"choices": ["Yes", "No"]
			}, next_nodes=[3, 4]),
			EventNode(3, "action", (700, 30), {
				"type": "set_flag",
				"flag": "quest_accepted"
			}, next_nodes=[8]),
			EventNode(4, "action", (700, 70), {
				"type": "show_dialog",
				"text": "Please reconsider!"
			}, next_nodes=[8]),
			EventNode(5, "condition", (500, 150), {
				"type": "flag_set",
				"flag": "quest_complete"
			}, true_branch=6, false_branch=7),
			EventNode(6, "action", (700, 130), {
				"type": "show_dialog",
				"text": "Thank you for your help!"
			}, next_nodes=[8]),
			EventNode(7, "action", (700, 170), {
				"type": "show_dialog",
				"text": "Please complete the quest!"
			}, next_nodes=[8]),
			EventNode(8, "end", (900, 100), {}),
		]

		self.add_template(EventTemplate(
			name="Quest Giver",
			description="NPC offering a quest",
			category="Quest",
			nodes=quest_nodes
		))

	def add_template(self, template: EventTemplate):
		"""Add template to library"""
		if template.category not in self.templates:
			self.templates[template.category] = []
		self.templates[template.category].append(template)

	def get_categories(self) -> List[str]:
		"""Get all template categories"""
		return sorted(self.templates.keys())

	def get_templates(self, category: str) -> List[EventTemplate]:
		"""Get templates in category"""
		return self.templates.get(category, [])


class EventSystemEditor:
	"""Main event system editor with UI"""

	def __init__(self, width: int = 1600, height: int = 900):
		self.width = width
		self.height = height
		self.running = True

		pygame.init()
		self.screen = pygame.display.set_mode((width, height))
		pygame.display.set_caption("Event System Editor")
		self.clock = pygame.time.Clock()

		self.font = pygame.font.Font(None, 20)
		self.small_font = pygame.font.Font(None, 16)

		# Event data
		self.events: List[GameEvent] = []
		self.current_event: Optional[GameEvent] = None
		self.template_library = TemplateLibrary()

		# View state
		self.camera_x = 0
		self.camera_y = 0
		self.zoom = 1.0
		self.selected_node: Optional[EventNode] = None
		self.dragging_node: Optional[EventNode] = None
		self.drag_offset = (0, 0)
		self.connecting_from: Optional[EventNode] = None

		# UI panels
		self.show_template_panel = True
		self.show_properties_panel = True
		self.selected_template: Optional[EventTemplate] = None

		# Node counter
		self.next_node_id = 0

		# Create sample event
		self._create_sample_event()

	def _create_sample_event(self):
		"""Create a sample event for demonstration"""
		nodes = [
			EventNode(0, "trigger", (100, 100), {"type": "on_interact"}),
			EventNode(1, "action", (300, 100), {
				"type": "show_dialog",
				"text": "Hello, adventurer!"
			}, next_nodes=[2]),
			EventNode(2, "end", (500, 100), {}),
		]

		event = GameEvent(
			event_id=1,
			name="Sample NPC",
			trigger=TriggerType.ON_INTERACT,
			nodes=nodes
		)

		self.events.append(event)
		self.current_event = event
		self.next_node_id = 3

	def run(self):
		"""Main editor loop"""
		while self.running:
			self._handle_events()
			self._render()
			self.clock.tick(60)

		pygame.quit()

	def _handle_events(self):
		"""Handle input events"""
		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				self.running = False

			elif event.type == pygame.KEYDOWN:
				if event.key == pygame.K_ESCAPE:
					self.running = False

				# Save/Load
				elif event.key == pygame.K_s and pygame.key.get_mods() & pygame.KMOD_CTRL:
					self._save_events()
				elif event.key == pygame.K_o and pygame.key.get_mods() & pygame.KMOD_CTRL:
					self._load_events()

				# Delete selected node
				elif event.key == pygame.K_DELETE:
					if self.selected_node and self.current_event:
						self.current_event.nodes.remove(self.selected_node)
						self.selected_node = None

				# Add node
				elif event.key == pygame.K_a:
					self._add_node("action", (400, 300))
				elif event.key == pygame.K_c:
					self._add_node("condition", (400, 300))

			elif event.type == pygame.MOUSEBUTTONDOWN:
				if event.button == 1:  # Left click
					self._handle_left_click(event.pos)
				elif event.button == 3:  # Right click
					self._handle_right_click(event.pos)
				elif event.button == 2:  # Middle click
					self.dragging_camera = True
					self.camera_drag_start = event.pos

			elif event.type == pygame.MOUSEBUTTONUP:
				if event.button == 1:
					self.dragging_node = None
					self.connecting_from = None
				elif event.button == 2:
					self.dragging_camera = False

			elif event.type == pygame.MOUSEMOTION:
				if self.dragging_node:
					self._handle_node_drag(event.pos)

	def _handle_left_click(self, pos: Tuple[int, int]):
		"""Handle left mouse click"""
		x, y = pos

		# Check template panel
		if self.show_template_panel and x < 250:
			self._handle_template_click(pos)
			return

		# Check node click
		if self.current_event:
			for node in self.current_event.nodes:
				node_x = node.position[0] - self.camera_x
				node_y = node.position[1] - self.camera_y

				# Check if clicking on node
				if (node_x - 40 < x < node_x + 40 and
						node_y - 25 < y < node_y + 25):

					# If shift held, start connection
					if pygame.key.get_mods() & pygame.KMOD_SHIFT:
						self.connecting_from = node
					else:
						self.selected_node = node
						self.dragging_node = node
						self.drag_offset = (x - node_x, y - node_y)
					return

		# Deselect
		self.selected_node = None

	def _handle_right_click(self, pos: Tuple[int, int]):
		"""Handle right mouse click"""
		if self.connecting_from and self.current_event:
			# Try to connect to a node
			x, y = pos
			for node in self.current_event.nodes:
				node_x = node.position[0] - self.camera_x
				node_y = node.position[1] - self.camera_y

				if (node_x - 40 < x < node_x + 40 and
						node_y - 25 < y < node_y + 25):

					# Add connection
					if node.node_id not in self.connecting_from.next_nodes:
						self.connecting_from.next_nodes.append(node.node_id)

					self.connecting_from = None
					return

	def _handle_template_click(self, pos: Tuple[int, int]):
		"""Handle template panel click"""
		x, y = pos

		# Check category/template selection
		categories = self.template_library.get_categories()
		y_offset = 100

		for category in categories:
			templates = self.template_library.get_templates(category)

			# Category header
			if y_offset < y < y_offset + 25:
				return
			y_offset += 30

			# Templates
			for template in templates:
				if y_offset < y < y_offset + 20:
					self.selected_template = template
					# Instantiate template
					if self.current_event:
						new_nodes = template.instantiate(self.next_node_id)
						self.current_event.nodes.extend(new_nodes)
						self.next_node_id += len(new_nodes)
					return
				y_offset += 25

	def _handle_node_drag(self, pos: Tuple[int, int]):
		"""Handle node dragging"""
		if self.dragging_node:
			x, y = pos
			new_x = x - self.drag_offset[0] + self.camera_x
			new_y = y - self.drag_offset[1] + self.camera_y
			self.dragging_node.position = (new_x, new_y)

	def _add_node(self, node_type: str, position: Tuple[int, int]):
		"""Add new node to current event"""
		if not self.current_event:
			return

		node = EventNode(
			node_id=self.next_node_id,
			node_type=node_type,
			position=position,
			parameters={}
		)

		self.current_event.nodes.append(node)
		self.next_node_id += 1
		self.selected_node = node

	def _save_events(self):
		"""Save events to JSON"""
		data = {
			"events": [event.to_dict() for event in self.events]
		}

		with open("events.json", 'w') as f:
			json.dump(data, f, indent=2)

		print("Events saved to events.json")

	def _load_events(self):
		"""Load events from JSON"""
		try:
			with open("events.json", 'r') as f:
				data = json.load(f)

			self.events = [GameEvent.from_dict(e) for e in data["events"]]
			if self.events:
				self.current_event = self.events[0]

			print("Events loaded from events.json")
		except FileNotFoundError:
			print("No events.json file found")

	def _render(self):
		"""Render editor"""
		self.screen.fill((25, 25, 35))

		# Draw template panel
		if self.show_template_panel:
			self._draw_template_panel()

		# Draw event graph
		self._draw_event_graph()

		# Draw properties panel
		if self.show_properties_panel:
			self._draw_properties_panel()

		# Draw toolbar
		self._draw_toolbar()

		pygame.display.flip()

	def _draw_template_panel(self):
		"""Draw template library panel"""
		panel_x = 0
		panel_y = 50
		panel_width = 250
		panel_height = self.height - 100

		# Background
		pygame.draw.rect(self.screen, (35, 35, 45),
						 (panel_x, panel_y, panel_width, panel_height))
		pygame.draw.rect(self.screen, (80, 80, 100),
						 (panel_x, panel_y, panel_width, panel_height), 2)

		# Title
		title = self.font.render("Templates", True, (255, 255, 255))
		self.screen.blit(title, (panel_x + 10, panel_y + 10))

		# Categories and templates
		y_offset = panel_y + 50
		categories = self.template_library.get_categories()

		for category in categories:
			# Category header
			cat_text = self.font.render(category, True, (200, 200, 255))
			self.screen.blit(cat_text, (panel_x + 10, y_offset))
			y_offset += 30

			# Templates
			templates = self.template_library.get_templates(category)
			for template in templates:
				color = (255, 255, 100) if template == self.selected_template else (180, 180, 180)
				temp_text = self.small_font.render(f"  • {template.name}",
													True, color)
				self.screen.blit(temp_text, (panel_x + 10, y_offset))
				y_offset += 25

	def _draw_event_graph(self):
		"""Draw event node graph"""
		if not self.current_event:
			return

		graph_x = 250 if self.show_template_panel else 0
		graph_width = self.width - graph_x - \
			(350 if self.show_properties_panel else 0)

		# Draw connections first
		for node in self.current_event.nodes:
			node_x = node.position[0] - self.camera_x
			node_y = node.position[1] - self.camera_y

			# Draw connections to next nodes
			for next_id in node.next_nodes:
				next_node = next(
					(n for n in self.current_event.nodes if n.node_id == next_id), None)
				if next_node:
					next_x = next_node.position[0] - self.camera_x
					next_y = next_node.position[1] - self.camera_y
					pygame.draw.line(self.screen, (100, 100, 150),
									 (node_x, node_y), (next_x, next_y), 2)

			# Draw true/false branches
			if node.true_branch is not None:
				true_node = next(
					(n for n in self.current_event.nodes if n.node_id == node.true_branch), None)
				if true_node:
					true_x = true_node.position[0] - self.camera_x
					true_y = true_node.position[1] - self.camera_y
					pygame.draw.line(self.screen, (100, 255, 100),
									 (node_x, node_y), (true_x, true_y), 2)

			if node.false_branch is not None:
				false_node = next(
					(n for n in self.current_event.nodes if n.node_id == node.false_branch), None)
				if false_node:
					false_x = false_node.position[0] - self.camera_x
					false_y = false_node.position[1] - self.camera_y
					pygame.draw.line(self.screen, (255, 100, 100),
									 (node_x, node_y), (false_x, false_y), 2)

		# Draw nodes
		for node in self.current_event.nodes:
			node_x = node.position[0] - self.camera_x
			node_y = node.position[1] - self.camera_y

			# Skip if off-screen
			if node_x < graph_x - 100 or node_x > graph_x + graph_width + 100:
				continue

			color = node.get_color()

			# Highlight selected
			if node == self.selected_node:
				pygame.draw.rect(self.screen, (255, 255, 100),
								 (node_x - 42, node_y - 27, 84, 54), 3)

			# Node box
			pygame.draw.rect(self.screen, color,
							 (node_x - 40, node_y - 25, 80, 50))
			pygame.draw.rect(self.screen, (255, 255, 255),
							 (node_x - 40, node_y - 25, 80, 50), 2)

			# Node type
			type_text = self.small_font.render(
				node.node_type, True, (0, 0, 0))
			text_rect = type_text.get_rect(center=(node_x, node_y - 5))
			self.screen.blit(type_text, text_rect)

			# Node ID
			id_text = self.small_font.render(
				f"#{node.node_id}", True, (0, 0, 0))
			id_rect = id_text.get_rect(center=(node_x, node_y + 10))
			self.screen.blit(id_text, id_rect)

	def _draw_properties_panel(self):
		"""Draw properties panel for selected node"""
		panel_x = self.width - 350
		panel_y = 50
		panel_width = 350
		panel_height = self.height - 100

		# Background
		pygame.draw.rect(self.screen, (35, 35, 45),
						 (panel_x, panel_y, panel_width, panel_height))
		pygame.draw.rect(self.screen, (80, 80, 100),
						 (panel_x, panel_y, panel_width, panel_height), 2)

		# Title
		title = self.font.render("Properties", True, (255, 255, 255))
		self.screen.blit(title, (panel_x + 10, panel_y + 10))

		if not self.selected_node:
			hint = self.small_font.render(
				"Select a node to view properties", True, (150, 150, 150))
			self.screen.blit(hint, (panel_x + 10, panel_y + 50))
			return

		# Node properties
		y_offset = panel_y + 50

		props = [
			f"Node ID: {self.selected_node.node_id}",
			f"Type: {self.selected_node.node_type}",
			f"Position: {self.selected_node.position}",
			f"Next Nodes: {self.selected_node.next_nodes}",
		]

		if self.selected_node.parameters:
			props.append("Parameters:")
			for key, value in self.selected_node.parameters.items():
				props.append(f"  {key}: {value}")

		for prop in props:
			text = self.small_font.render(prop, True, (200, 200, 200))
			self.screen.blit(text, (panel_x + 10, y_offset))
			y_offset += 20

	def _draw_toolbar(self):
		"""Draw top toolbar"""
		toolbar_height = 40
		pygame.draw.rect(self.screen, (45, 45, 55),
						 (0, 0, self.width, toolbar_height))
		pygame.draw.rect(self.screen, (80, 80, 100),
						 (0, 0, self.width, toolbar_height), 2)

		# Title
		if self.current_event:
			title = self.font.render(
				f"Event: {self.current_event.name}", True, (255, 255, 255))
			self.screen.blit(title, (10, 10))

		# Instructions
		help_text = "A:Add Action | C:Add Condition | Shift+Click:Connect | Del:Delete | Ctrl+S:Save"
		help_surf = self.small_font.render(
			help_text, True, (180, 180, 180))
		self.screen.blit(help_surf, (400, 12))


def main():
	"""Run event system editor"""
	editor = EventSystemEditor()
	editor.run()


if __name__ == "__main__":
	main()
