"""
Tab System for Map Editor - Provides tabbed interface for different editing modes

Tabs:
- Map Editor (default)
- Dialog Editor
- Event Script Editor
- Properties
"""

import pygame
from typing import List, Callable, Optional
from dataclasses import dataclass


@dataclass
class Tab:
	"""Represents a single tab"""
	id: str
	title: str
	icon: Optional[str] = None  # Optional icon character
	enabled: bool = True
	tooltip: str = ""


class TabBar:
	"""Tab bar widget for switching between different editing modes"""

	def __init__(self, rect: pygame.Rect, tabs: List[Tab]):
		"""
		Args:
			rect: Rectangle for the tab bar
			tabs: List of Tab objects
		"""
		self.rect = rect
		self.tabs = tabs
		self.active_index = 0
		self.hovered_index: Optional[int] = None

		# Styling
		self.bg_color = (40, 40, 50)
		self.tab_color = (50, 50, 60)
		self.tab_active_color = (70, 130, 180)
		self.tab_hover_color = (60, 60, 70)
		self.text_color = (220, 220, 220)
		self.text_dim_color = (140, 140, 150)
		self.border_color = (60, 60, 70)

		# Layout
		self.tab_height = rect.height
		self.tab_width = rect.width // max(1, len(tabs))

		# Callbacks
		self.on_tab_changed: Optional[Callable[[int, str], None]] = None

	def get_active_tab(self) -> Tab:
		"""Get the currently active tab"""
		return self.tabs[self.active_index]

	def set_active_tab(self, index: int):
		"""Set the active tab by index"""
		if 0 <= index < len(self.tabs) and self.tabs[index].enabled:
			old_index = self.active_index
			self.active_index = index

			# Call callback
			if self.on_tab_changed and old_index != index:
				self.on_tab_changed(index, self.tabs[index].id)

	def set_active_tab_by_id(self, tab_id: str):
		"""Set the active tab by ID"""
		for i, tab in enumerate(self.tabs):
			if tab.id == tab_id:
				self.set_active_tab(i)
				return

	def handle_event(self, event: pygame.event.Event) -> bool:
		"""
		Handle pygame events

		Returns:
			True if event was handled
		"""
		if event.type == pygame.MOUSEMOTION:
			# Check which tab is hovered
			if self.rect.collidepoint(event.pos):
				rel_x = event.pos[0] - self.rect.x
				tab_index = rel_x // self.tab_width
				if 0 <= tab_index < len(self.tabs):
					self.hovered_index = tab_index
				else:
					self.hovered_index = None
			else:
				self.hovered_index = None

		elif event.type == pygame.MOUSEBUTTONDOWN and event.button == 1:
			# Check if clicked on a tab
			if self.rect.collidepoint(event.pos):
				rel_x = event.pos[0] - self.rect.x
				tab_index = rel_x // self.tab_width
				if 0 <= tab_index < len(self.tabs):
					self.set_active_tab(tab_index)
					return True

		elif event.type == pygame.KEYDOWN:
			# Keyboard shortcuts: Ctrl+1-9 for tabs
			if event.mod & pygame.KMOD_CTRL:
				if pygame.K_1 <= event.key <= pygame.K_9:
					tab_num = event.key - pygame.K_1
					if tab_num < len(self.tabs):
						self.set_active_tab(tab_num)
						return True

		return False

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw the tab bar"""
		# Background
		pygame.draw.rect(surface, self.bg_color, self.rect)

		# Draw tabs
		for i, tab in enumerate(self.tabs):
			tab_rect = pygame.Rect(
				self.rect.x + i * self.tab_width,
				self.rect.y,
				self.tab_width,
				self.tab_height
			)

			# Determine tab color
			if i == self.active_index:
				color = self.tab_active_color
			elif i == self.hovered_index and tab.enabled:
				color = self.tab_hover_color
			else:
				color = self.tab_color

			# Draw tab background
			pygame.draw.rect(surface, color, tab_rect)

			# Draw border
			pygame.draw.rect(surface, self.border_color, tab_rect, 1)

			# Draw active indicator
			if i == self.active_index:
				indicator_rect = pygame.Rect(
					tab_rect.x,
					tab_rect.bottom - 3,
					tab_rect.width,
					3
				)
				pygame.draw.rect(surface, (100, 180, 220), indicator_rect)

			# Draw text
			text_color = self.text_color if tab.enabled else self.text_dim_color

			# Icon + text
			text = tab.title
			if tab.icon:
				text = f"{tab.icon}  {text}"

			text_surf = font.render(text, True, text_color)
			text_rect = text_surf.get_rect(center=tab_rect.center)
			surface.blit(text_surf, text_rect)

			# Keyboard shortcut hint
			if i < 9:
				shortcut_text = f"Ctrl+{i+1}"
				shortcut_surf = font.render(shortcut_text, True, self.text_dim_color)
				shortcut_surf.set_alpha(128)
				shortcut_rect = shortcut_surf.get_rect(
					centerx=tab_rect.centerx,
					bottom=tab_rect.bottom - 3
				)
				surface.blit(shortcut_surf, shortcut_rect)


class TabbedPanel:
	"""Container for tabbed content panels"""

	def __init__(self, rect: pygame.Rect, tab_height: int = 40):
		"""
		Args:
			rect: Rectangle for the entire tabbed panel (including tab bar)
			tab_height: Height of the tab bar
		"""
		self.rect = rect
		self.tab_height = tab_height

		# Create tab bar at the top
		tab_bar_rect = pygame.Rect(rect.x, rect.y, rect.width, tab_height)
		self.tab_bar = TabBar(tab_bar_rect, [])

		# Content area (below tab bar)
		self.content_rect = pygame.Rect(
			rect.x,
			rect.y + tab_height,
			rect.width,
			rect.height - tab_height
		)

		# Content panels (keyed by tab ID)
		self.panels = {}

		# Current active panel
		self.active_panel = None

	def add_tab(self, tab: Tab, panel_object=None):
		"""
		Add a tab and its associated panel

		Args:
			tab: Tab object
			panel_object: Object that will be drawn/updated for this tab
		"""
		self.tab_bar.tabs.append(tab)
		self.panels[tab.id] = panel_object

		# Recalculate tab widths
		self.tab_bar.tab_width = self.tab_bar.rect.width // max(1, len(self.tab_bar.tabs))

		# Set first tab as active
		if len(self.tab_bar.tabs) == 1:
			self.tab_bar.set_active_tab(0)
			self.active_panel = panel_object

	def handle_event(self, event: pygame.event.Event) -> bool:
		"""Handle events for tab bar and active panel"""
		# Tab bar handles its own events
		if self.tab_bar.handle_event(event):
			# Tab changed
			active_tab = self.tab_bar.get_active_tab()
			self.active_panel = self.panels.get(active_tab.id)
			return True

		# Pass events to active panel if it has a handle_event method
		if self.active_panel and hasattr(self.active_panel, 'handle_event'):
			return self.active_panel.handle_event(event)

		return False

	def update(self, dt: float):
		"""Update active panel"""
		if self.active_panel and hasattr(self.active_panel, 'update'):
			self.active_panel.update(dt)

	def draw(self, surface: pygame.Surface, font: pygame.font.Font):
		"""Draw tab bar and active panel"""
		# Draw tab bar
		self.tab_bar.draw(surface, font)

		# Draw active panel
		if self.active_panel:
			if hasattr(self.active_panel, 'draw'):
				self.active_panel.draw(surface, font)
			elif hasattr(self.active_panel, 'render'):
				self.active_panel.render(surface, self.content_rect)


# Example usage
if __name__ == '__main__':
	pygame.init()

	screen = pygame.display.set_mode((1000, 700))
	pygame.display.set_caption("Tab System Demo")
	clock = pygame.time.Clock()
	font = pygame.font.Font(None, 24)

	# Create tabbed panel
	panel_rect = pygame.Rect(50, 50, 900, 600)
	tabbed_panel = TabbedPanel(panel_rect, tab_height=50)

	# Add tabs
	tabbed_panel.add_tab(Tab("map", "Map Editor", "🗺", True, "Edit map tiles"))
	tabbed_panel.add_tab(Tab("dialog", "Dialogs", "💬", True, "Edit dialog text"))
	tabbed_panel.add_tab(Tab("events", "Events", "⚡", True, "Edit event scripts"))
	tabbed_panel.add_tab(Tab("props", "Properties", "⚙", True, "Edit properties"))

	running = True
	while running:
		dt = clock.tick(60) / 1000.0

		for event in pygame.event.get():
			if event.type == pygame.QUIT:
				running = False
			tabbed_panel.handle_event(event)

		screen.fill((30, 30, 40))
		tabbed_panel.draw(screen, font)

		# Show active tab name in content area
		active_tab = tabbed_panel.tab_bar.get_active_tab()
		text = font.render(f"Active: {active_tab.title}", True, (220, 220, 220))
		text_rect = text.get_rect(center=tabbed_panel.content_rect.center)
		screen.blit(text, text_rect)

		pygame.display.flip()

	pygame.quit()
