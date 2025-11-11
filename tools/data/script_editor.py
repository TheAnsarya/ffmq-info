"""
Advanced Script and Dialog Editor for FFMQ
Edit game scripts, dialog, event triggers with visual flow.
"""

import pygame
import json
from dataclasses import dataclass, field
from typing import List, Tuple, Optional, Dict
from enum import Enum


class CommandType(Enum):
	"""Script command types"""
	TEXT = "text"
	CHOICE = "choice"
	JUMP = "jump"
	CALL = "call"
	SET_FLAG = "set_flag"
	CHECK_FLAG = "check_flag"
	GIVE_ITEM = "give_item"
	TAKE_ITEM = "take_item"
	BATTLE = "battle"
	MUSIC = "music"
	SOUND = "sound"
	WAIT = "wait"
	FADE = "fade"
	WARP = "warp"
	ANIMATION = "animation"
	CAMERA = "camera"
	PARTY = "party"
	SHOP = "shop"
	INN = "inn"
	SAVE = "save"


class ConditionType(Enum):
	"""Conditional types"""
	FLAG = "flag"
	ITEM = "item"
	PARTY_SIZE = "party_size"
	GOLD = "gold"
	LEVEL = "level"
	LOCATION = "location"
	TIME = "time"


@dataclass
class ScriptCommand:
	"""Single script command"""
	command_id: int
	command_type: CommandType
	params: Dict[str, any] = field(default_factory=dict)
	condition: Optional[Tuple[ConditionType, str, any]] = None
	next_id: Optional[int] = None  # For flow control

	def to_dict(self):
		return {
			'command_id': self.command_id,
			'command_type': self.command_type.value,
			'params': self.params,
			'condition': {
				'type': self.condition[0].value,
				'param': self.condition[1],
				'value': self.condition[2]
			} if self.condition else None,
			'next_id': self.next_id
		}

	def get_display_text(self) -> str:
		"""Get text for display"""
		if self.command_type == CommandType.TEXT:
			return f"TEXT: {self.params.get('text', '')[:30]}..."
		elif self.command_type == CommandType.CHOICE:
			options = self.params.get('options', [])
			return f"CHOICE: {len(options)} options"
		elif self.command_type == CommandType.JUMP:
			return f"JUMP to {self.params.get('target', '?')}"
		elif self.command_type == CommandType.GIVE_ITEM:
			return f"GIVE {self.params.get('item', '?')} x{
				self.params.get('count', 1)}"
		elif self.command_type == CommandType.BATTLE:
			return f"BATTLE: {self.params.get('enemy_group', '?')}"
		elif self.command_type == CommandType.MUSIC:
			return f"MUSIC: {self.params.get('track', '?')}"
		elif self.command_type == CommandType.WARP:
			return f"WARP to {self.params.get('map', '?')}"
		else:
			return f"{self.command_type.value.upper()}"


@dataclass
class DialogLine:
	"""Single line of dialog"""
	speaker: str
	text: str
	portrait: Optional[int] = None
	emotion: str = "normal"
	voice_id: Optional[int] = None

	def to_dict(self):
		return {
			'speaker': self.speaker,
			'text': self.text,
			'portrait': self.portrait,
			'emotion': self.emotion,
			'voice_id': self.voice_id
		}


@dataclass
class Script:
	"""Complete script/event"""
	script_id: int
	name: str
	trigger: str  # "on_interact", "on_enter", "auto", etc.
	commands: List[ScriptCommand] = field(default_factory=list)
	dialogs: List[DialogLine] = field(default_factory=list)
	variables: Dict[str, any] = field(default_factory=dict)

	def to_dict(self):
		return {
			'script_id': self.script_id,
			'name': self.name,
			'trigger': self.trigger,
			'commands': [cmd.to_dict() for cmd in self.commands],
			'dialogs': [d.to_dict() for d in self.dialogs],
			'variables': self.variables
		}


class ScriptFlowVisualizer:
	"""Visual flow diagram for scripts"""

	def __init__(self, width: int = 1000, height: int = 700):
		self.width = width
		self.height = height
		self.nodes = {}  # command_id -> (x, y)
		self.connections = []  # [(from_id, to_id)]

	def layout_commands(self, commands: List[ScriptCommand]):
		"""Calculate layout positions"""
		if not commands:
			return

		# Simple vertical layout
		spacing = 80
		start_x = self.width // 2
		start_y = 50

		for i, cmd in enumerate(commands):
			self.nodes[cmd.command_id] = (start_x, start_y + i * spacing)

			# Track connections
			if cmd.next_id is not None:
				self.connections.append((cmd.command_id, cmd.next_id))

		# Add choice branches
		for cmd in commands:
			if cmd.command_type == CommandType.CHOICE:
				options = cmd.params.get('options', [])
				for j, option in enumerate(options):
					target_id = option.get('target_id')
					if target_id:
						self.connections.append((cmd.command_id, target_id))

	def draw(self, surface: pygame.Surface, commands: List[ScriptCommand],
			 selected_id: Optional[int] = None):
		"""Draw flow diagram"""
		font = pygame.font.Font(None, 20)

		# Draw connections first
		for from_id, to_id in self.connections:
			if from_id in self.nodes and to_id in self.nodes:
				start = self.nodes[from_id]
				end = self.nodes[to_id]

				# Draw arrow
				pygame.draw.line(surface, (100, 100, 100), start, end, 2)

				# Draw arrowhead
				dx = end[0] - start[0]
				dy = end[1] - start[1]
				if dy != 0:
					angle = 3.14159 / 6  # 30 degrees
					arrow_len = 10

					# Simple vertical arrow
					pygame.draw.polygon(surface, (100, 100, 100), [
						end,
						(end[0] - arrow_len // 2, end[1] - arrow_len),
						(end[0] + arrow_len // 2, end[1] - arrow_len)
					])

		# Draw nodes
		for cmd in commands:
			if cmd.command_id not in self.nodes:
				continue

			x, y = self.nodes[cmd.command_id]

			# Node color based on type
			if cmd.command_type == CommandType.TEXT:
				color = (100, 150, 255)
			elif cmd.command_type == CommandType.CHOICE:
				color = (255, 200, 100)
			elif cmd.command_type == CommandType.BATTLE:
				color = (255, 100, 100)
			elif cmd.command_type in (CommandType.JUMP, CommandType.CALL):
				color = (150, 100, 255)
			else:
				color = (150, 150, 150)

			# Highlight selected
			if cmd.command_id == selected_id:
				pygame.draw.rect(surface, (255, 255, 0),
								 (x - 102, y - 22, 204, 44), 3)

			# Draw node box
			pygame.draw.rect(surface, color, (x - 100, y - 20, 200, 40))
			pygame.draw.rect(surface, (0, 0, 0), (x - 100, y - 20, 200, 40), 2)

			# Draw text
			text = cmd.get_display_text()
			text_surf = font.render(text, True, (255, 255, 255))
			text_rect = text_surf.get_rect(center=(x, y))
			surface.blit(text_surf, text_rect)


class ScriptEditor:
	"""Interactive script editor"""

	def __init__(self):
		pygame.init()
		self.screen = pygame.display.set_mode((1200, 800))
		pygame.display.set_caption("FFMQ Script Editor")
		self.clock = pygame.time.Clock()

		self.font = pygame.font.Font(None, 24)
		self.small_font = pygame.font.Font(None, 20)

		self.current_script = self._create_sample_script()
		self.selected_command = None
		self.editing_field = None
		self.text_input = ""

		self.flow_visualizer = ScriptFlowVisualizer(800, 700)
		self.flow_visualizer.layout_commands(self.current_script.commands)

		self.scroll_offset = 0

	def _create_sample_script(self) -> Script:
		"""Create sample script"""
		script = Script(
			script_id=1,
			name="Village Elder Dialog",
			trigger="on_interact"
		)

		# Commands
		script.commands = [
			ScriptCommand(0, CommandType.TEXT, {
				'text': "Welcome, brave warrior!",
				'speaker': "Village Elder"
			}, next_id=1),

			ScriptCommand(1, CommandType.TEXT, {
				'text': "The Focus Tower has been causing trouble...",
				'speaker': "Village Elder"
			}, next_id=2),

			ScriptCommand(2, CommandType.CHOICE, {
				'text': "Will you help us?",
				'options': [
					{'text': "Yes", 'target_id': 3},
					{'text': "No", 'target_id': 5},
					{'text': "Tell me more", 'target_id': 6}
				]
			}),

			ScriptCommand(3, CommandType.TEXT, {
				'text': "Thank you! Take this sword.",
				'speaker': "Village Elder"
			}, next_id=4),

			ScriptCommand(4, CommandType.GIVE_ITEM, {
				'item': "Steel Sword",
				'count': 1
			}, next_id=7),

			ScriptCommand(5, CommandType.TEXT, {
				'text': "I understand. Come back when you're ready.",
				'speaker': "Village Elder"
			}, next_id=7),

			ScriptCommand(6, CommandType.TEXT, {
				'text': "The Focus Tower controls the crystal energy...",
				'speaker': "Village Elder"
			}, next_id=2),

			ScriptCommand(7, CommandType.SET_FLAG, {
				'flag': "elder_quest_started",
				'value': True
			})
		]

		return script

	def draw_property_panel(self):
		"""Draw command property editor"""
		panel_rect = pygame.Rect(820, 50, 360, 700)
		pygame.draw.rect(self.screen, (50, 50, 50), panel_rect)
		pygame.draw.rect(self.screen, (200, 200, 200), panel_rect, 2)

		if self.selected_command is None:
			text = self.font.render("Select a command", True, (255, 255, 255))
			self.screen.blit(text, (840, 100))
			return

		y = 70

		# Command type
		text = self.font.render(
			f"Type: {self.selected_command.command_type.value}",
			True, (255, 255, 255)
		)
		self.screen.blit(text, (840, y))
		y += 40

		# Parameters
		text = self.small_font.render("Parameters:", True, (200, 200, 200))
		self.screen.blit(text, (840, y))
		y += 30

		for key, value in self.selected_command.params.items():
			param_text = f"{key}: {value}"
			if len(param_text) > 30:
				param_text = param_text[:27] + "..."

			text = self.small_font.render(param_text, True, (255, 255, 255))
			self.screen.blit(text, (860, y))
			y += 25

		# Condition
		if self.selected_command.condition:
			y += 10
			text = self.small_font.render("Condition:", True, (200, 200, 200))
			self.screen.blit(text, (840, y))
			y += 25

			cond_type, param, value = self.selected_command.condition
			cond_text = f"{cond_type.value}: {param} == {value}"
			text = self.small_font.render(cond_text, True, (255, 200, 100))
			self.screen.blit(text, (860, y))

	def draw_command_list(self):
		"""Draw command list sidebar"""
		list_rect = pygame.Rect(20, 50, 250, 700)
		pygame.draw.rect(self.screen, (40, 40, 40), list_rect)
		pygame.draw.rect(self.screen, (200, 200, 200), list_rect, 2)

		y = 60
		for i, cmd in enumerate(self.current_script.commands):
			item_rect = pygame.Rect(30, y, 230, 30)

			# Highlight selected
			if cmd == self.selected_command:
				pygame.draw.rect(self.screen, (80, 80, 150), item_rect)

			# Command text
			cmd_text = f"{i}: {cmd.command_type.value}"
			text = self.small_font.render(cmd_text, True, (255, 255, 255))
			self.screen.blit(text, (40, y + 5))

			y += 35

	def handle_click(self, pos: Tuple[int, int]):
		"""Handle mouse click"""
		x, y = pos

		# Command list click
		if 20 <= x <= 270 and 50 <= y <= 750:
			idx = (y - 60) // 35
			if 0 <= idx < len(self.current_script.commands):
				self.selected_command = self.current_script.commands[idx]
				return

		# Flow diagram click
		if 290 <= x <= 790:
			# Find clicked node
			for cmd in self.current_script.commands:
				if cmd.command_id in self.flow_visualizer.nodes:
					nx, ny = self.flow_visualizer.nodes[cmd.command_id]
					nx += 290  # Offset for panel
					if abs(x - nx) <= 100 and abs(y - ny) <= 20:
						self.selected_command = cmd
						return

	def run(self):
		"""Main editor loop"""
		running = True

		while running:
			for event in pygame.event.get():
				if event.type == pygame.QUIT:
					running = False

				elif event.type == pygame.MOUSEBUTTONDOWN:
					if event.button == 1:  # Left click
						self.handle_click(event.pos)

				elif event.type == pygame.KEYDOWN:
					if event.key == pygame.K_ESCAPE:
						running = False

					elif event.key == pygame.K_s and (
							pygame.key.get_mods() & pygame.KMOD_CTRL):
						# Save script
						self.save_script("test_script.json")
						print("Script saved!")

					elif event.key == pygame.K_n and (
							pygame.key.get_mods() & pygame.KMOD_CTRL):
						# New command
						new_cmd = ScriptCommand(
							len(self.current_script.commands),
							CommandType.TEXT,
							{'text': "New dialog", 'speaker': "NPC"}
						)
						self.current_script.commands.append(new_cmd)
						self.flow_visualizer.layout_commands(
							self.current_script.commands
						)

			# Draw
			self.screen.fill((30, 30, 30))

			# Title
			title = self.font.render(
				f"Script: {self.current_script.name}",
				True, (255, 255, 255)
			)
			self.screen.blit(title, (20, 10))

			# Draw components
			self.draw_command_list()

			# Flow diagram
			flow_surface = pygame.Surface((800, 700))
			flow_surface.fill((30, 30, 30))
			self.flow_visualizer.draw(
				flow_surface,
				self.current_script.commands,
				self.selected_command.command_id if self.selected_command else None
			)
			self.screen.blit(flow_surface, (290, 50))

			self.draw_property_panel()

			# Instructions
			inst_text = "Ctrl+S: Save | Ctrl+N: New Command | ESC: Quit"
			inst = self.small_font.render(inst_text, True, (150, 150, 150))
			self.screen.blit(inst, (20, 770))

			pygame.display.flip()
			self.clock.tick(60)

		pygame.quit()

	def save_script(self, filepath: str):
		"""Save script to JSON"""
		with open(filepath, 'w') as f:
			json.dump(self.current_script.to_dict(), f, indent=2)


def main():
	"""Run script editor"""
	editor = ScriptEditor()
	editor.run()


if __name__ == '__main__':
	main()
