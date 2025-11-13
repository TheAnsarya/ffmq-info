#!/usr/bin/env python3
"""
FFMQ Custom Menu Designer - Create custom UI menus and layouts

Menu Features:
- Custom menu layouts
- Button mapping
- Color schemes
- Font selection
- Window positioning
- Border styles
- Cursor graphics
- Sound effects

Menu Types:
- Main menu
- Battle menu
- Item menu
- Equipment menu
- Magic menu
- Status screen
- Shop menus
- Dialog boxes

Layout Options:
- Grid layouts (rows/columns)
- List layouts (vertical/horizontal)
- Tabbed layouts
- Nested menus
- Dynamic sizing
- Scrolling regions
- Icons/graphics

Customization:
- Background colors
- Text colors
- Border colors
- Transparency
- Animations
- Transitions
- Hover effects

Features:
- Design menu layouts
- Set button actions
- Customize appearance
- Preview menus
- Export configurations
- Import templates

Usage:
	python ffmq_menu_designer.py create --name "Main Menu" --type main
	python ffmq_menu_designer.py edit --menu main --bg-color blue
	python ffmq_menu_designer.py add-item --menu main --label "New Game" --action start_game
	python ffmq_menu_designer.py preview --menu main
	python ffmq_menu_designer.py export --output menus.json
"""

import argparse
import json
from pathlib import Path
from typing import List, Dict, Tuple, Optional, Any
from dataclasses import dataclass, asdict, field
from enum import Enum


class MenuType(Enum):
	"""Menu categories"""
	MAIN = "main"
	BATTLE = "battle"
	ITEM = "item"
	EQUIPMENT = "equipment"
	MAGIC = "magic"
	STATUS = "status"
	SHOP = "shop"
	DIALOG = "dialog"


class LayoutType(Enum):
	"""Layout styles"""
	GRID = "grid"
	LIST_VERTICAL = "list_vertical"
	LIST_HORIZONTAL = "list_horizontal"
	TABBED = "tabbed"
	CUSTOM = "custom"


class BorderStyle(Enum):
	"""Border styles"""
	NONE = "none"
	SINGLE = "single"
	DOUBLE = "double"
	ROUNDED = "rounded"
	SHADOW = "shadow"


@dataclass
class Color:
	"""RGB color"""
	r: int
	g: int
	b: int
	
	def to_hex(self) -> str:
		return f"#{self.r:02X}{self.g:02X}{self.b:02X}"
	
	@classmethod
	def from_hex(cls, hex_str: str) -> 'Color':
		hex_str = hex_str.lstrip('#')
		r = int(hex_str[0:2], 16)
		g = int(hex_str[2:4], 16)
		b = int(hex_str[4:6], 16)
		return cls(r, g, b)


@dataclass
class MenuItem:
	"""Individual menu item"""
	item_id: int
	label: str
	action: str  # Function/action name
	enabled: bool = True
	hotkey: Optional[str] = None
	icon: Optional[int] = None
	submenu: Optional[str] = None
	
	def to_dict(self) -> dict:
		return asdict(self)


@dataclass
class MenuStyle:
	"""Menu visual style"""
	bg_color: Color
	text_color: Color
	border_color: Color
	border_style: BorderStyle
	transparency: int = 0  # 0-255
	font_id: int = 0
	cursor_sprite: int = 0
	sound_move: int = 0  # Sound effect ID
	sound_select: int = 1
	sound_cancel: int = 2
	
	def to_dict(self) -> dict:
		d = {
			'bg_color': self.bg_color.to_hex(),
			'text_color': self.text_color.to_hex(),
			'border_color': self.border_color.to_hex(),
			'border_style': self.border_style.value,
			'transparency': self.transparency,
			'font_id': self.font_id,
			'cursor_sprite': self.cursor_sprite,
			'sound_move': self.sound_move,
			'sound_select': self.sound_select,
			'sound_cancel': self.sound_cancel
		}
		return d


@dataclass
class Menu:
	"""Complete menu definition"""
	menu_id: int
	name: str
	menu_type: MenuType
	layout: LayoutType
	position_x: int
	position_y: int
	width: int
	height: int
	items: List[MenuItem]
	style: MenuStyle
	rows: int = 1
	columns: int = 1
	spacing: int = 8
	
	def to_dict(self) -> dict:
		d = asdict(self)
		d['menu_type'] = self.menu_type.value
		d['layout'] = self.layout.value
		d['items'] = [item.to_dict() for item in self.items]
		d['style'] = self.style.to_dict()
		return d


class FFMQMenuDesigner:
	"""Custom menu designer"""
	
	# Default color schemes
	COLOR_SCHEMES = {
		'classic': {
			'bg': Color(0, 0, 128),
			'text': Color(255, 255, 255),
			'border': Color(255, 255, 0)
		},
		'dark': {
			'bg': Color(32, 32, 32),
			'text': Color(200, 200, 200),
			'border': Color(128, 128, 128)
		},
		'light': {
			'bg': Color(240, 240, 240),
			'text': Color(0, 0, 0),
			'border': Color(100, 100, 100)
		},
		'forest': {
			'bg': Color(34, 139, 34),
			'text': Color(255, 255, 255),
			'border': Color(0, 100, 0)
		}
	}
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.menus: List[Menu] = []
		self.next_id = 1
	
	def create_menu(self, name: str, menu_type: MenuType,
				   layout: LayoutType = LayoutType.LIST_VERTICAL,
				   position: Tuple[int, int] = (16, 16),
				   size: Tuple[int, int] = (192, 128),
				   color_scheme: str = 'classic') -> Menu:
		"""Create new menu"""
		# Get color scheme
		scheme = self.COLOR_SCHEMES.get(color_scheme, self.COLOR_SCHEMES['classic'])
		
		# Create style
		style = MenuStyle(
			bg_color=scheme['bg'],
			text_color=scheme['text'],
			border_color=scheme['border'],
			border_style=BorderStyle.SINGLE
		)
		
		menu = Menu(
			menu_id=self.next_id,
			name=name,
			menu_type=menu_type,
			layout=layout,
			position_x=position[0],
			position_y=position[1],
			width=size[0],
			height=size[1],
			items=[],
			style=style
		)
		
		self.menus.append(menu)
		self.next_id += 1
		
		if self.verbose:
			print(f"✓ Created menu: {name}")
		
		return menu
	
	def add_menu_item(self, menu: Menu, label: str, action: str,
					 enabled: bool = True, hotkey: Optional[str] = None,
					 icon: Optional[int] = None) -> MenuItem:
		"""Add item to menu"""
		item = MenuItem(
			item_id=len(menu.items),
			label=label,
			action=action,
			enabled=enabled,
			hotkey=hotkey,
			icon=icon
		)
		
		menu.items.append(item)
		
		if self.verbose:
			print(f"✓ Added menu item: {label}")
		
		return item
	
	def set_layout_grid(self, menu: Menu, rows: int, columns: int, spacing: int = 8) -> None:
		"""Set grid layout"""
		menu.layout = LayoutType.GRID
		menu.rows = rows
		menu.columns = columns
		menu.spacing = spacing
		
		if self.verbose:
			print(f"✓ Set grid layout: {rows}×{columns}")
	
	def set_color_scheme(self, menu: Menu, scheme_name: str) -> None:
		"""Apply color scheme"""
		if scheme_name not in self.COLOR_SCHEMES:
			if self.verbose:
				print(f"Unknown color scheme: {scheme_name}")
			return
		
		scheme = self.COLOR_SCHEMES[scheme_name]
		menu.style.bg_color = scheme['bg']
		menu.style.text_color = scheme['text']
		menu.style.border_color = scheme['border']
		
		if self.verbose:
			print(f"✓ Applied color scheme: {scheme_name}")
	
	def set_border_style(self, menu: Menu, border_style: BorderStyle) -> None:
		"""Set border style"""
		menu.style.border_style = border_style
		
		if self.verbose:
			print(f"✓ Set border style: {border_style.value}")
	
	def generate_template_main_menu(self) -> Menu:
		"""Generate main menu template"""
		menu = self.create_menu(
			name="Main Menu",
			menu_type=MenuType.MAIN,
			layout=LayoutType.LIST_VERTICAL,
			position=(64, 48),
			size=(128, 96),
			color_scheme='classic'
		)
		
		self.add_menu_item(menu, "New Game", "start_new_game", hotkey="A")
		self.add_menu_item(menu, "Continue", "load_game", hotkey="B")
		self.add_menu_item(menu, "Options", "open_options", hotkey="X")
		
		return menu
	
	def generate_template_battle_menu(self) -> Menu:
		"""Generate battle menu template"""
		menu = self.create_menu(
			name="Battle Menu",
			menu_type=MenuType.BATTLE,
			layout=LayoutType.GRID,
			position=(16, 144),
			size=(224, 64),
			color_scheme='dark'
		)
		
		menu.rows = 2
		menu.columns = 2
		
		self.add_menu_item(menu, "Attack", "battle_attack", icon=1)
		self.add_menu_item(menu, "Magic", "battle_magic", icon=2)
		self.add_menu_item(menu, "Item", "battle_item", icon=3)
		self.add_menu_item(menu, "Defend", "battle_defend", icon=4)
		
		return menu
	
	def preview_ascii(self, menu: Menu) -> str:
		"""Generate ASCII preview"""
		lines = []
		
		# Top border
		if menu.style.border_style != BorderStyle.NONE:
			border_char = "═" if menu.style.border_style == BorderStyle.DOUBLE else "─"
			lines.append("┌" + border_char * (menu.width // 4) + "┐")
		
		# Title
		lines.append(f"│ {menu.name:<{menu.width // 4 - 2}} │")
		
		# Separator
		if menu.style.border_style != BorderStyle.NONE:
			lines.append("├" + "─" * (menu.width // 4) + "┤")
		
		# Items
		if menu.layout == LayoutType.LIST_VERTICAL:
			for item in menu.items:
				cursor = ">" if item == menu.items[0] else " "
				label = item.label
				if not item.enabled:
					label = f"[{label}]"
				lines.append(f"│ {cursor} {label:<{menu.width // 4 - 4}} │")
		
		elif menu.layout == LayoutType.GRID:
			for row in range(menu.rows):
				row_items = menu.items[row * menu.columns:(row + 1) * menu.columns]
				row_text = "│ "
				for i, item in enumerate(row_items):
					cursor = ">" if item == menu.items[0] else " "
					row_text += f"{cursor}{item.label:<12} "
				row_text += "│"
				lines.append(row_text)
		
		# Bottom border
		if menu.style.border_style != BorderStyle.NONE:
			lines.append("└" + "─" * (menu.width // 4) + "┘")
		
		return "\n".join(lines)
	
	def export_menus(self, output_path: Path) -> None:
		"""Export menus to JSON"""
		data = {
			'menus': [m.to_dict() for m in self.menus],
			'total_count': len(self.menus)
		}
		
		with open(output_path, 'w') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported {len(self.menus)} menus to {output_path}")
	
	def import_menus(self, input_path: Path) -> None:
		"""Import menus from JSON"""
		with open(input_path, 'r') as f:
			data = json.load(f)
		
		self.menus = []
		for menu_dict in data['menus']:
			menu_dict['menu_type'] = MenuType(menu_dict['menu_type'])
			menu_dict['layout'] = LayoutType(menu_dict['layout'])
			
			# Rebuild style
			style_dict = menu_dict['style']
			style_dict['bg_color'] = Color.from_hex(style_dict['bg_color'])
			style_dict['text_color'] = Color.from_hex(style_dict['text_color'])
			style_dict['border_color'] = Color.from_hex(style_dict['border_color'])
			style_dict['border_style'] = BorderStyle(style_dict['border_style'])
			menu_dict['style'] = MenuStyle(**style_dict)
			
			# Rebuild items
			items = []
			for item_dict in menu_dict['items']:
				items.append(MenuItem(**item_dict))
			menu_dict['items'] = items
			
			menu = Menu(**menu_dict)
			self.menus.append(menu)
		
		if self.verbose:
			print(f"✓ Imported {len(self.menus)} menus from {input_path}")


def main():
	parser = argparse.ArgumentParser(description='FFMQ Custom Menu Designer')
	parser.add_argument('command', choices=['create', 'list', 'add-item', 'preview', 'export', 'import'],
					   help='Command to execute')
	parser.add_argument('--name', type=str, help='Menu name')
	parser.add_argument('--type', type=str, choices=[t.value for t in MenuType],
					   help='Menu type')
	parser.add_argument('--layout', type=str, choices=[l.value for l in LayoutType],
					   default='list_vertical', help='Layout type')
	parser.add_argument('--menu', type=str, help='Menu name to edit')
	parser.add_argument('--label', type=str, help='Menu item label')
	parser.add_argument('--action', type=str, help='Menu item action')
	parser.add_argument('--scheme', type=str, help='Color scheme')
	parser.add_argument('--template', type=str, choices=['main', 'battle'],
					   help='Menu template')
	parser.add_argument('--output', type=str, help='Output file')
	parser.add_argument('--input', type=str, help='Input file')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	designer = FFMQMenuDesigner(verbose=args.verbose)
	
	# Create menu
	if args.command == 'create':
		if not all([args.name, args.type]):
			print("Error: --name and --type required")
			return 1
		
		if args.template:
			if args.template == 'main':
				menu = designer.generate_template_main_menu()
			elif args.template == 'battle':
				menu = designer.generate_template_battle_menu()
		else:
			menu = designer.create_menu(
				name=args.name,
				menu_type=MenuType(args.type),
				layout=LayoutType(args.layout),
				color_scheme=args.scheme or 'classic'
			)
		
		if args.output:
			designer.export_menus(Path(args.output))
		
		return 0
	
	# List menus
	elif args.command == 'list':
		# Generate templates
		designer.generate_template_main_menu()
		designer.generate_template_battle_menu()
		
		print(f"\n=== Menus ({len(designer.menus)} total) ===\n")
		
		for menu in designer.menus:
			print(f"📋 {menu.name}")
			print(f"   Type: {menu.menu_type.value}")
			print(f"   Layout: {menu.layout.value}")
			print(f"   Position: ({menu.position_x}, {menu.position_y})")
			print(f"   Size: {menu.width}×{menu.height}")
			print(f"   Items: {len(menu.items)}")
			print()
		
		return 0
	
	# Preview menu
	elif args.command == 'preview':
		if not args.menu:
			print("Error: --menu required")
			return 1
		
		# Generate templates
		if args.menu == 'main':
			menu = designer.generate_template_main_menu()
		elif args.menu == 'battle':
			menu = designer.generate_template_battle_menu()
		else:
			print(f"Unknown menu: {args.menu}")
			return 1
		
		preview = designer.preview_ascii(menu)
		print("\n" + preview + "\n")
		
		return 0
	
	# Export
	elif args.command == 'export':
		if not args.output:
			print("Error: --output required")
			return 1
		
		# Generate templates if none exist
		if not designer.menus:
			designer.generate_template_main_menu()
			designer.generate_template_battle_menu()
		
		designer.export_menus(Path(args.output))
		return 0
	
	# Import
	elif args.command == 'import':
		if not args.input:
			print("Error: --input required")
			return 1
		
		designer.import_menus(Path(args.input))
		return 0
	
	return 0


if __name__ == '__main__':
	exit(main())
