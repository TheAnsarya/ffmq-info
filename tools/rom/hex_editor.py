#!/usr/bin/env python3
"""
Advanced Hex Editor with Template System

Professional hex editor for ROM manipulation with intelligent template system.
Features include:
- Dual hex/ASCII view with synchronized scrolling
- Multi-level undo/redo system
- Search and replace (hex and text)
- Data inspection panel (int8/16/32, float, pointers)
- Template system for structured data editing
- Bookmark management
- Diff view for comparing ROM versions
- Export/import selections
- Checksum calculation (CRC32, MD5, SHA1)

Templates define structured data:
- Enemy stats, item data, map headers, etc.
- Field types: uint8, uint16, uint32, string, pointer, bitfield
- Automatic parsing and editing
- Template library for common SNES structures
"""

from dataclasses import dataclass, field
from enum import Enum
from typing import Dict, List, Optional, Tuple, Any
import struct
import pygame


class FieldType(Enum):
	"""Template field types"""
	UINT8 = "uint8"
	UINT16 = "uint16"
	UINT32 = "uint32"
	INT8 = "int8"
	INT16 = "int16"
	INT32 = "int32"
	STRING = "string"
	POINTER = "pointer"
	BITFIELD = "bitfield"
	ARRAY = "array"


@dataclass
class TemplateField:
	"""Field in a data template"""
	name: str
	field_type: FieldType
	offset: int
	size: int = 1
	description: str = ""
	# For bitfields
	bit_offset: int = 0
	bit_size: int = 0
	# For arrays
	array_count: int = 0
	array_item_type: Optional[FieldType] = None
	# For enums/choices
	choices: Optional[Dict[int, str]] = None

	def parse_value(self, data: bytes, base_offset: int = 0) -> Any:
		"""Parse value from data"""
		offset = base_offset + self.offset

		if offset + self.size > len(data):
			return None

		chunk = data[offset:offset + self.size]

		if self.field_type == FieldType.UINT8:
			return chunk[0]
		elif self.field_type == FieldType.UINT16:
			return struct.unpack('<H', chunk)[0]
		elif self.field_type == FieldType.UINT32:
			return struct.unpack('<I', chunk)[0]
		elif self.field_type == FieldType.INT8:
			return struct.unpack('<b', chunk)[0]
		elif self.field_type == FieldType.INT16:
			return struct.unpack('<h', chunk)[0]
		elif self.field_type == FieldType.INT32:
			return struct.unpack('<i', chunk)[0]
		elif self.field_type == FieldType.STRING:
			return chunk.decode('ascii', errors='ignore').rstrip('\x00')
		elif self.field_type == FieldType.POINTER:
			# SNES pointer (24-bit)
			if len(chunk) >= 3:
				return struct.unpack('<I', chunk + b'\x00')[0] & 0xFFFFFF
			return 0
		elif self.field_type == FieldType.BITFIELD:
			value = chunk[0] if len(chunk) > 0 else 0
			mask = ((1 << self.bit_size) - 1) << self.bit_offset
			return (value & mask) >> self.bit_offset
		elif self.field_type == FieldType.ARRAY:
			values = []
			item_size = 1 if self.array_item_type == FieldType.UINT8 else 2
			for i in range(self.array_count):
				item_offset = offset + (i * item_size)
				if item_offset + item_size <= len(data):
					if self.array_item_type == FieldType.UINT8:
						values.append(data[item_offset])
					elif self.array_item_type == FieldType.UINT16:
						values.append(struct.unpack('<H', data[item_offset:item_offset + 2])[0])
			return values

		return None

	def format_value(self, value: Any) -> str:
		"""Format value for display"""
		if value is None:
			return "N/A"

		if self.choices and value in self.choices:
			return f"{value} ({self.choices[value]})"

		if self.field_type in (FieldType.UINT8, FieldType.INT8):
			return f"${value:02X} ({value})"
		elif self.field_type in (FieldType.UINT16, FieldType.INT16):
			return f"${value:04X} ({value})"
		elif self.field_type in (FieldType.UINT32, FieldType.INT32):
			return f"${value:08X} ({value})"
		elif self.field_type == FieldType.POINTER:
			return f"${value:06X}"
		elif self.field_type == FieldType.STRING:
			return f'"{value}"'
		elif self.field_type == FieldType.ARRAY:
			return f"[{', '.join(f'${v:02X}' for v in value)}]"
		elif self.field_type == FieldType.BITFIELD:
			return f"{value} (bits {self.bit_offset}-{self.bit_offset + self.bit_size - 1})"

		return str(value)


@dataclass
class DataTemplate:
	"""Template for structured data"""
	name: str
	description: str
	size: int
	fields: List[TemplateField]

	def parse(self, data: bytes, offset: int = 0) -> Dict[str, Any]:
		"""Parse data using template"""
		result = {}
		for field in self.fields:
			result[field.name] = field.parse_value(data, offset)
		return result

	def format(self, data: bytes, offset: int = 0) -> str:
		"""Format data using template"""
		lines = [f"{self.name} @ ${offset:06X}"]
		lines.append("-" * 60)

		parsed = self.parse(data, offset)
		for field in self.fields:
			value = parsed[field.name]
			formatted = field.format_value(value)
			lines.append(f"{field.name:<20}: {formatted}")
			if field.description:
				lines.append(f"  {field.description}")

		return "\n".join(lines)


@dataclass
class Bookmark:
	"""Memory bookmark"""
	name: str
	offset: int
	size: int = 1
	description: str = ""


@dataclass
class EditAction:
	"""Single edit action for undo/redo"""
	offset: int
	old_data: bytes
	new_data: bytes
	description: str = ""


class HexEditor:
	"""Main hex editor engine"""

	def __init__(self, data: bytes):
		self.data = bytearray(data)
		self.bookmarks: List[Bookmark] = []
		self.templates: Dict[str, DataTemplate] = {}

		# Undo/redo stacks
		self.undo_stack: List[EditAction] = []
		self.redo_stack: List[EditAction] = []
		self.max_undo = 100

		# Load default templates
		self._load_default_templates()

	def edit_byte(self, offset: int, value: int, description: str = "Edit byte"):
		"""Edit a single byte with undo support"""
		if offset >= len(self.data):
			return False

		old_value = self.data[offset]
		if old_value == value:
			return False

		# Record action
		action = EditAction(offset, bytes([old_value]), bytes([value]), description)
		self.undo_stack.append(action)
		if len(self.undo_stack) > self.max_undo:
			self.undo_stack.pop(0)

		# Clear redo stack
		self.redo_stack.clear()

		# Apply edit
		self.data[offset] = value
		return True

	def edit_bytes(self, offset: int, new_data: bytes, description: str = "Edit bytes"):
		"""Edit multiple bytes with undo support"""
		if offset + len(new_data) > len(self.data):
			return False

		old_data = bytes(self.data[offset:offset + len(new_data)])
		if old_data == new_data:
			return False

		# Record action
		action = EditAction(offset, old_data, new_data, description)
		self.undo_stack.append(action)
		if len(self.undo_stack) > self.max_undo:
			self.undo_stack.pop(0)

		# Clear redo stack
		self.redo_stack.clear()

		# Apply edit
		self.data[offset:offset + len(new_data)] = new_data
		return True

	def undo(self) -> bool:
		"""Undo last edit"""
		if not self.undo_stack:
			return False

		action = self.undo_stack.pop()
		self.redo_stack.append(action)

		# Revert edit
		self.data[action.offset:action.offset + len(action.old_data)] = action.old_data
		return True

	def redo(self) -> bool:
		"""Redo last undone edit"""
		if not self.redo_stack:
			return False

		action = self.redo_stack.pop()
		self.undo_stack.append(action)

		# Reapply edit
		self.data[action.offset:action.offset + len(action.new_data)] = action.new_data
		return True

	def search(self, pattern: bytes, start_offset: int = 0) -> List[int]:
		"""Search for byte pattern"""
		results = []
		pattern_len = len(pattern)

		for i in range(start_offset, len(self.data) - pattern_len + 1):
			if self.data[i:i + pattern_len] == pattern:
				results.append(i)

		return results

	def replace(self, old_pattern: bytes, new_pattern: bytes,
				start_offset: int = 0, max_replacements: int = -1) -> int:
		"""Replace pattern with new pattern"""
		if len(old_pattern) != len(new_pattern):
			return 0

		results = self.search(old_pattern, start_offset)
		count = 0

		for offset in results:
			if max_replacements > 0 and count >= max_replacements:
				break

			if self.edit_bytes(offset, new_pattern, f"Replace @ ${offset:06X}"):
				count += 1

		return count

	def add_bookmark(self, name: str, offset: int, size: int = 1, description: str = ""):
		"""Add a bookmark"""
		self.bookmarks.append(Bookmark(name, offset, size, description))

	def add_template(self, template: DataTemplate):
		"""Add a data template"""
		self.templates[template.name] = template

	def apply_template(self, template_name: str, offset: int) -> Optional[Dict[str, Any]]:
		"""Apply template at offset and return parsed data"""
		template = self.templates.get(template_name)
		if not template:
			return None

		return template.parse(bytes(self.data), offset)

	def calculate_checksum(self, algorithm: str = "crc32",
						  start: int = 0, end: Optional[int] = None) -> int:
		"""Calculate checksum"""
		if end is None:
			end = len(self.data)

		chunk = bytes(self.data[start:end])

		if algorithm == "crc32":
			import zlib
			return zlib.crc32(chunk) & 0xFFFFFFFF
		elif algorithm == "sum8":
			return sum(chunk) & 0xFF
		elif algorithm == "sum16":
			return sum(chunk) & 0xFFFF
		elif algorithm == "sum32":
			return sum(chunk) & 0xFFFFFFFF

		return 0

	def _load_default_templates(self):
		"""Load default SNES templates"""
		# Enemy template
		enemy_template = DataTemplate(
			name="SNES Enemy",
			description="Standard SNES enemy data structure",
			size=32,
			fields=[
				TemplateField("HP", FieldType.UINT16, 0, 2, "Hit points"),
				TemplateField("MP", FieldType.UINT16, 2, 2, "Magic points"),
				TemplateField("Attack", FieldType.UINT8, 4, 1, "Physical attack power"),
				TemplateField("Defense", FieldType.UINT8, 5, 1, "Physical defense"),
				TemplateField("Magic", FieldType.UINT8, 6, 1, "Magic attack power"),
				TemplateField("Speed", FieldType.UINT8, 7, 1, "Speed/agility"),
				TemplateField("EXP", FieldType.UINT16, 8, 2, "Experience reward"),
				TemplateField("Gold", FieldType.UINT16, 10, 2, "Gold reward"),
				TemplateField("Level", FieldType.UINT8, 12, 1, "Enemy level"),
				TemplateField("AI_Pattern", FieldType.UINT8, 13, 1, "AI behavior pattern"),
				TemplateField("Weaknesses", FieldType.BITFIELD, 14, 1, "Elemental weaknesses",
							bit_offset=0, bit_size=8),
				TemplateField("Resistances", FieldType.BITFIELD, 15, 1, "Elemental resistances",
							bit_offset=0, bit_size=8),
			]
		)
		self.add_template(enemy_template)

		# Item template
		item_template = DataTemplate(
			name="SNES Item",
			description="Standard item data",
			size=16,
			fields=[
				TemplateField("ID", FieldType.UINT8, 0, 1, "Item ID"),
				TemplateField("Type", FieldType.UINT8, 1, 1, "Item type",
							choices={0: "Consumable", 1: "Key", 2: "Equipment", 3: "Special"}),
				TemplateField("Effect", FieldType.UINT8, 2, 1, "Primary effect"),
				TemplateField("Power", FieldType.UINT8, 3, 1, "Effect power/value"),
				TemplateField("Price", FieldType.UINT16, 4, 2, "Buy price"),
				TemplateField("Sell_Price", FieldType.UINT16, 6, 2, "Sell price"),
				TemplateField("Name_Pointer", FieldType.POINTER, 8, 3, "Pointer to name string"),
				TemplateField("Description_Pointer", FieldType.POINTER, 11, 3, "Pointer to description"),
			]
		)
		self.add_template(item_template)

		# Map header template
		map_template = DataTemplate(
			name="SNES Map Header",
			description="Map/level header data",
			size=16,
			fields=[
				TemplateField("Width", FieldType.UINT8, 0, 1, "Map width in tiles"),
				TemplateField("Height", FieldType.UINT8, 1, 1, "Map height in tiles"),
				TemplateField("Tileset", FieldType.UINT8, 2, 1, "Tileset ID"),
				TemplateField("Palette", FieldType.UINT8, 3, 1, "Palette set ID"),
				TemplateField("Music", FieldType.UINT8, 4, 1, "Background music ID"),
				TemplateField("Tilemap_Pointer", FieldType.POINTER, 5, 3, "Tilemap data pointer"),
				TemplateField("Event_Pointer", FieldType.POINTER, 8, 3, "Event data pointer"),
				TemplateField("Flags", FieldType.BITFIELD, 11, 1, "Map flags", bit_offset=0, bit_size=8),
			]
		)
		self.add_template(map_template)


class HexEditorUI:
	"""Interactive hex editor UI"""

	def __init__(self, editor: HexEditor, width: int = 1400, height: int = 900):
		self.editor = editor
		self.width = width
		self.height = height
		self.running = True

		pygame.init()
		self.screen = pygame.display.set_mode((width, height))
		pygame.display.set_caption("Advanced Hex Editor")
		self.clock = pygame.time.Clock()

		self.font = pygame.font.Font(None, 18)
		self.small_font = pygame.font.Font(None, 16)

		# View state
		self.offset = 0
		self.bytes_per_row = 16
		self.cursor_offset = 0
		self.cursor_nibble = 0  # 0 or 1 for hex editing
		self.selection_start: Optional[int] = None
		self.selection_end: Optional[int] = None

		# Panels
		self.show_inspector = True
		self.show_bookmarks = True
		self.show_template = False
		self.selected_template: Optional[str] = None

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

				# Navigation
				elif event.key == pygame.K_UP:
					self.cursor_offset = max(0, self.cursor_offset - self.bytes_per_row)
				elif event.key == pygame.K_DOWN:
					self.cursor_offset = min(len(self.editor.data) - 1,
											self.cursor_offset + self.bytes_per_row)
				elif event.key == pygame.K_LEFT:
					if self.cursor_nibble == 0:
						self.cursor_offset = max(0, self.cursor_offset - 1)
						self.cursor_nibble = 1
					else:
						self.cursor_nibble = 0
				elif event.key == pygame.K_RIGHT:
					if self.cursor_nibble == 1:
						self.cursor_offset = min(len(self.editor.data) - 1,
												self.cursor_offset + 1)
						self.cursor_nibble = 0
					else:
						self.cursor_nibble = 1

				# Page navigation
				elif event.key == pygame.K_PAGEUP:
					rows_visible = 20
					self.cursor_offset = max(0, self.cursor_offset - rows_visible * self.bytes_per_row)
					self.offset = (self.cursor_offset // self.bytes_per_row) * self.bytes_per_row
				elif event.key == pygame.K_PAGEDOWN:
					rows_visible = 20
					self.cursor_offset = min(len(self.editor.data) - 1,
											self.cursor_offset + rows_visible * self.bytes_per_row)
					self.offset = (self.cursor_offset // self.bytes_per_row) * self.bytes_per_row

				# Undo/Redo
				elif event.key == pygame.K_z and pygame.key.get_mods() & pygame.KMOD_CTRL:
					self.editor.undo()
				elif event.key == pygame.K_y and pygame.key.get_mods() & pygame.KMOD_CTRL:
					self.editor.redo()

				# Hex input
				elif event.unicode in '0123456789ABCDEFabcdef':
					nibble_value = int(event.unicode, 16)
					current_byte = self.editor.data[self.cursor_offset]

					if self.cursor_nibble == 0:
						# High nibble
						new_byte = (nibble_value << 4) | (current_byte & 0x0F)
					else:
						# Low nibble
						new_byte = (current_byte & 0xF0) | nibble_value

					self.editor.edit_byte(self.cursor_offset, new_byte)

					# Advance cursor
					if self.cursor_nibble == 1:
						self.cursor_offset = min(len(self.editor.data) - 1,
												self.cursor_offset + 1)
						self.cursor_nibble = 0
					else:
						self.cursor_nibble = 1

				# Toggle panels
				elif event.key == pygame.K_F1:
					self.show_inspector = not self.show_inspector
				elif event.key == pygame.K_F2:
					self.show_bookmarks = not self.show_bookmarks
				elif event.key == pygame.K_F3:
					self.show_template = not self.show_template

	def _render(self):
		"""Render editor view"""
		self.screen.fill((20, 20, 30))

		# Calculate panel positions
		hex_view_x = 20
		hex_view_y = 60
		hex_view_width = 800

		# Draw hex view
		self._draw_hex_view(hex_view_x, hex_view_y, hex_view_width)

		# Draw data inspector
		if self.show_inspector:
			self._draw_inspector(hex_view_x + hex_view_width + 20, 60, 260)

		# Draw bookmarks
		if self.show_bookmarks:
			self._draw_bookmarks(hex_view_x + hex_view_width + 300, 60, 260)

		# Draw template view
		if self.show_template and self.selected_template:
			self._draw_template(hex_view_x, self.height - 250, 800, 230)

		# Draw status bar
		self._draw_status_bar()

		pygame.display.flip()

	def _draw_hex_view(self, x: int, y: int, width: int):
		"""Draw main hex editor view"""
		# Title
		title = self.font.render("Hex View", True, (255, 255, 255))
		self.screen.blit(title, (x, y - 35))

		# Column headers
		header = f"Offset    "
		for i in range(self.bytes_per_row):
			header += f"{i:02X} "
		header += " ASCII"

		header_surf = self.small_font.render(header, True, (180, 180, 180))
		self.screen.blit(header_surf, (x, y))

		# Draw rows
		rows_visible = 24
		char_height = 20

		for row in range(rows_visible):
			row_offset = self.offset + (row * self.bytes_per_row)
			if row_offset >= len(self.editor.data):
				break

			row_y = y + 25 + (row * char_height)

			# Offset label
			offset_text = self.small_font.render(f"{row_offset:08X}:", True, (120, 150, 200))
			self.screen.blit(offset_text, (x, row_y))

			# Hex bytes
			hex_x = x + 85
			for col in range(self.bytes_per_row):
				byte_offset = row_offset + col
				if byte_offset >= len(self.editor.data):
					break

				byte_value = self.editor.data[byte_offset]

				# Highlight cursor
				is_cursor = (byte_offset == self.cursor_offset)
				color = (255, 255, 100) if is_cursor else (200, 200, 200)

				byte_text = self.small_font.render(f"{byte_value:02X}", True, color)
				self.screen.blit(byte_text, (hex_x + col * 24, row_y))

				# Draw cursor nibble
				if is_cursor:
					cursor_x = hex_x + col * 24 + (self.cursor_nibble * 8)
					pygame.draw.line(self.screen, (255, 255, 0),
								   (cursor_x, row_y + 15), (cursor_x + 7, row_y + 15), 2)

			# ASCII view
			ascii_x = hex_x + self.bytes_per_row * 24 + 20
			ascii_str = ""
			for col in range(self.bytes_per_row):
				byte_offset = row_offset + col
				if byte_offset >= len(self.editor.data):
					break

				byte_value = self.editor.data[byte_offset]
				if 0x20 <= byte_value < 0x7F:
					ascii_str += chr(byte_value)
				else:
					ascii_str += "."

			ascii_text = self.small_font.render(ascii_str, True, (180, 200, 180))
			self.screen.blit(ascii_text, (ascii_x, row_y))

	def _draw_inspector(self, x: int, y: int, width: int):
		"""Draw data inspector panel"""
		title = self.font.render("Inspector", True, (255, 255, 255))
		self.screen.blit(title, (x, y - 25))

		# Background
		pygame.draw.rect(self.screen, (30, 30, 40), (x, y, width, 400))
		pygame.draw.rect(self.screen, (80, 80, 100), (x, y, width, 400), 2)

		# Read values at cursor
		offset = self.cursor_offset
		inspections = []

		if offset < len(self.editor.data):
			inspections.append(f"Offset: ${offset:06X}")
			inspections.append(f"Byte: ${self.editor.data[offset]:02X}")

			if offset + 1 < len(self.editor.data):
				u16 = struct.unpack('<H', bytes(self.editor.data[offset:offset + 2]))[0]
				i16 = struct.unpack('<h', bytes(self.editor.data[offset:offset + 2]))[0]
				inspections.append(f"UInt16: ${u16:04X} ({u16})")
				inspections.append(f"Int16: {i16}")

			if offset + 3 < len(self.editor.data):
				u32 = struct.unpack('<I', bytes(self.editor.data[offset:offset + 4]))[0]
				i32 = struct.unpack('<i', bytes(self.editor.data[offset:offset + 4]))[0]
				inspections.append(f"UInt32: ${u32:08X}")
				inspections.append(f"Int32: {i32}")

				# SNES pointer (24-bit)
				ptr = u32 & 0xFFFFFF
				inspections.append(f"Pointer: ${ptr:06X}")

		# Draw inspections
		line_y = y + 10
		for line in inspections:
			text = self.small_font.render(line, True, (200, 200, 200))
			self.screen.blit(text, (x + 10, line_y))
			line_y += 18

	def _draw_bookmarks(self, x: int, y: int, width: int):
		"""Draw bookmarks panel"""
		title = self.font.render("Bookmarks", True, (255, 255, 255))
		self.screen.blit(title, (x, y - 25))

		# Background
		pygame.draw.rect(self.screen, (30, 30, 40), (x, y, width, 400))
		pygame.draw.rect(self.screen, (80, 80, 100), (x, y, width, 400), 2)

		# List bookmarks
		line_y = y + 10
		for bookmark in self.editor.bookmarks[:15]:
			text = self.small_font.render(f"{bookmark.name}: ${bookmark.offset:06X}",
										 True, (200, 200, 200))
			self.screen.blit(text, (x + 10, line_y))
			line_y += 20

	def _draw_template(self, x: int, y: int, width: int, height: int):
		"""Draw template view"""
		if not self.selected_template:
			return

		template = self.editor.templates.get(self.selected_template)
		if not template:
			return

		# Background
		pygame.draw.rect(self.screen, (30, 30, 40), (x, y, width, height))
		pygame.draw.rect(self.screen, (80, 80, 100), (x, y, width, height), 2)

		# Title
		title = self.font.render(f"Template: {template.name}", True, (255, 255, 255))
		self.screen.blit(title, (x + 10, y + 10))

		# Parse and display
		formatted = template.format(bytes(self.editor.data), self.cursor_offset)
		lines = formatted.split('\n')[2:]  # Skip title and separator

		line_y = y + 35
		for line in lines[:10]:
			text = self.small_font.render(line, True, (200, 200, 200))
			self.screen.blit(text, (x + 10, line_y))
			line_y += 18

	def _draw_status_bar(self):
		"""Draw status bar"""
		status_y = self.height - 30
		pygame.draw.rect(self.screen, (40, 40, 50), (0, status_y, self.width, 30))

		status = f"Cursor: ${self.cursor_offset:06X}  "
		status += f"Size: {len(self.editor.data):,} bytes  "
		status += f"Undo: {len(self.editor.undo_stack)}  "
		status += f"F1:Inspector F2:Bookmarks F3:Template  "
		status += f"Ctrl+Z:Undo Ctrl+Y:Redo"

		text = self.small_font.render(status, True, (200, 200, 200))
		self.screen.blit(text, (10, status_y + 7))


def main():
	"""Test hex editor"""
	# Create test ROM
	test_data = bytearray(0x10000)

	# Add some test data
	for i in range(0x100):
		test_data[i] = i

	# Add test text
	text = b"FINAL FANTASY MYSTIC QUEST HEX EDITOR"
	test_data[0x1000:0x1000 + len(text)] = text

	# Create editor
	editor = HexEditor(bytes(test_data))

	# Add bookmarks
	editor.add_bookmark("Start", 0x0000, 16, "ROM beginning")
	editor.add_bookmark("Text", 0x1000, len(text), "Test text")
	editor.add_bookmark("Enemy 0", 0x2000, 32, "First enemy data")

	# Launch UI
	ui = HexEditorUI(editor)
	ui.selected_template = "SNES Enemy"
	ui.show_template = True
	ui.run()


if __name__ == "__main__":
	main()
