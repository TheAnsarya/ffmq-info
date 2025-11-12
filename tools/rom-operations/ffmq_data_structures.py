"""
FFMQ Data Structures - Living data format classes
==================================================

This module provides code-usable classes for all FFMQ data types.
Each class supports:
- Parsing from ROM binary data
- Serialization to ASM source
- JSON import/export for data files
- Round-trip conversion (binary ↔ JSON ↔ ASM)

Usage:
	# Parse metatile from ROM
	tile_data = rom[0x068000:0x068004]
	metatile = Metatile.from_bytes(tile_data)
	
	# Export to JSON
	json_data = metatile.to_dict()
	
	# Generate ASM source
	asm_code = metatile.to_asm(label="METATILE_00")
	
	# Rebuild binary
	binary = metatile.to_bytes()
"""

import struct
import json
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, field


# ==============================================================================
# Map Tilemap Structures (Bank $06)
# ==============================================================================

@dataclass
class Metatile:
	"""
	16x16 pixel metatile composed of four 8x8 tiles.
	
	Format (4 bytes):
		[0] Top-Left tile index
		[1] Top-Right tile index
		[2] Bottom-Left tile index
		[3] Bottom-Right tile index
	
	Tile indices reference 8x8 graphics in VRAM.
	Special values:
		$fb = Empty/transparent tile
		$9a/$9b = Common padding/filler
	"""
	
	top_left: int  # 0x00-0xff
	top_right: int
	bottom_left: int
	bottom_right: int
	metatile_id: Optional[int] = None  # Optional ID for tracking
	description: str = ""  # Human-readable description
	
	def __post_init__(self):
		"""Validate tile indices are in valid range."""
		for tile in [self.top_left, self.top_right, self.bottom_left, self.bottom_right]:
			if not (0 <= tile <= 0xff):
				raise ValueError(f"Tile index ${tile:02X} out of range (must be $00-$ff)")
	
	@classmethod
	def from_bytes(cls, data: bytes, metatile_id: Optional[int] = None) -> 'Metatile':
		"""
		Parse metatile from 4-byte ROM data.
		
		Args:
			data: 4 bytes of tile data
			metatile_id: Optional ID number for this metatile
			
		Returns:
			Metatile instance
		"""
		if len(data) != 4:
			raise ValueError(f"Metatile requires exactly 4 bytes, got {len(data)}")
		
		return cls(
			top_left=data[0],
			top_right=data[1],
			bottom_left=data[2],
			bottom_right=data[3],
			metatile_id=metatile_id
		)
	
	def to_bytes(self) -> bytes:
		"""Convert metatile to 4-byte binary format."""
		return bytes([self.top_left, self.top_right, self.bottom_left, self.bottom_right])
	
	def to_asm(self, label: Optional[str] = None) -> str:
		"""
		Generate ASM source code.
		
		Args:
			label: Optional label for this metatile
			
		Returns:
			ASM db statement with comment
		"""
		asm = ""
		if label:
			asm += f"{label}:\n"
		
		asm += f"	db ${self.top_left:02X},${self.top_right:02X},${self.bottom_left:02X},${self.bottom_right:02X}"
		
		# Add descriptive comment
		if self.metatile_id is not None:
			asm += f"  ; Metatile ${self.metatile_id:02X}"
		if self.description:
			asm += f": {self.description}"
		else:
			asm += f"  ; TL/TR/BL/BR"
		
		return asm
	
	def to_dict(self) -> Dict[str, Any]:
		"""Export to dictionary for JSON serialization."""
		return {
			"id": self.metatile_id,
			"tiles": {
				"top_left": self.top_left,
				"top_right": self.top_right,
				"bottom_left": self.bottom_left,
				"bottom_right": self.bottom_right
			},
			"description": self.description
		}
	
	@classmethod
	def from_dict(cls, data: Dict[str, Any]) -> 'Metatile':
		"""Import from dictionary (JSON deserialization)."""
		tiles = data["tiles"]
		return cls(
			top_left=tiles["top_left"],
			top_right=tiles["top_right"],
			bottom_left=tiles["bottom_left"],
			bottom_right=tiles["bottom_right"],
			metatile_id=data.get("id"),
			description=data.get("description", "")
		)
	
	def is_empty(self) -> bool:
		"""Check if metatile is empty (all $fb tiles)."""
		return all(tile == 0xfb for tile in [self.top_left, self.top_right, self.bottom_left, self.bottom_right])


@dataclass
class CollisionData:
	"""
	Collision flags for a single tile.
	
	Format (1 byte bitfield):
		Bit 0: Passable/Blocked (0=passable, 1=blocked)
		Bit 1: Water tile (requires Float)
		Bit 2: Lava tile (damages player)
		Bit 3: Event trigger (door, chest, NPC)
		Bit 4-7: Special properties
	"""
	
	tile_id: int
	flags: int  # 8-bit bitfield
	
	@property
	def is_passable(self) -> bool:
		return (self.flags & 0x01) == 0
	
	@property
	def is_blocked(self) -> bool:
		return (self.flags & 0x01) != 0
	
	@property
	def is_water(self) -> bool:
		return (self.flags & 0x02) != 0
	
	@property
	def is_lava(self) -> bool:
		return (self.flags & 0x04) != 0
	
	@property
	def is_trigger(self) -> bool:
		return (self.flags & 0x08) != 0
	
	@classmethod
	def from_bytes(cls, data: bytes, tile_id: int = 0) -> 'CollisionData':
		"""Parse collision byte."""
		if len(data) != 1:
			raise ValueError(f"CollisionData requires exactly 1 byte, got {len(data)}")
		return cls(tile_id=tile_id, flags=data[0])
	
	def to_bytes(self) -> bytes:
		"""Convert to binary."""
		return bytes([self.flags])
	
	def to_asm(self) -> str:
		"""Generate ASM with descriptive comment."""
		properties = []
		if self.is_blocked:
			properties.append("blocked")
		else:
			properties.append("passable")
		if self.is_water:
			properties.append("water")
		if self.is_lava:
			properties.append("lava")
		if self.is_trigger:
			properties.append("trigger")
		
		props_str = ", ".join(properties)
		return f"	db ${self.flags:02X}  ; Tile ${self.tile_id:02X}: {props_str}"
	
	def to_dict(self) -> Dict[str, Any]:
		"""Export to dictionary."""
		return {
			"tile_id": self.tile_id,
			"flags": self.flags,
			"properties": {
				"passable": self.is_passable,
				"blocked": self.is_blocked,
				"water": self.is_water,
				"lava": self.is_lava,
				"trigger": self.is_trigger
			}
		}
	
	@classmethod
	def from_dict(cls, data: Dict[str, Any]) -> 'CollisionData':
		"""Import from dictionary."""
		return cls(tile_id=data["tile_id"], flags=data["flags"])


# ==============================================================================
# Text/Dialog Structures (Bank $08)
# ==============================================================================

@dataclass
class TextPointer:
	"""
	16-bit pointer to text string (little-endian).
	
	Format (2 bytes):
		[0] Low byte of address
		[1] High byte of address
	
	Address is relative to Bank $08 base ($088000).
	"""
	
	message_id: int  # Index in pointer table
	address: int  # 16-bit address (little-endian)
	
	@classmethod
	def from_bytes(cls, data: bytes, message_id: int = 0) -> 'TextPointer':
		"""Parse 2-byte pointer (little-endian)."""
		if len(data) != 2:
			raise ValueError(f"TextPointer requires exactly 2 bytes, got {len(data)}")
		address = struct.unpack("<H", data)[0]  # Little-endian unsigned short
		return cls(message_id=message_id, address=address)
	
	def to_bytes(self) -> bytes:
		"""Convert to 2-byte little-endian."""
		return struct.pack("<H", self.address)
	
	def to_asm(self) -> str:
		"""Generate ASM pointer."""
		low = self.address & 0xff
		high = (self.address >> 8) & 0xff
		return f"	db ${low:02X},${high:02X}  ; Msg ${self.message_id:02X}: ${self.address:04X}"
	
	def to_dict(self) -> Dict[str, Any]:
		"""Export to dictionary."""
		return {
			"message_id": self.message_id,
			"address": self.address
		}
	
	@classmethod
	def from_dict(cls, data: Dict[str, Any]) -> 'TextPointer':
		"""Import from dictionary."""
		return cls(message_id=data["message_id"], address=data["address"])


@dataclass
class DialogString:
	"""
	Variable-length text string with control codes.
	
	Format:
		- Variable length, null-terminated ($00)
		- Control codes:
			$f0 = End message
			$f1 = Newline
			$f2 = Wait for input
			$f3 = Clear screen
			$f4 = Variable insertion
			$f5 = Item name
			$f6 = Character name
			$f7 = Number formatting
		- Text uses custom character encoding (see simple.tbl)
	"""
	
	message_id: int
	raw_bytes: bytes  # Raw encoded text
	text: str = ""  # Decoded text (if available)
	control_codes: List[int] = field(default_factory=list)  # Control code positions
	
	@classmethod
	def from_bytes(cls, data: bytes, message_id: int = 0, encoding_table: Optional[Dict[int, str]] = None) -> 'DialogString':
		"""
		Parse dialog string from ROM.
		
		Args:
			data: Raw bytes (until null terminator or max length)
			message_id: Message ID
			encoding_table: Optional character encoding map
		"""
		# Find null terminator
		null_pos = data.find(b'\x00')
		if null_pos != -1:
			data = data[:null_pos]
		
		# Extract control codes
		control_codes = [i for i, b in enumerate(data) if 0xf0 <= b <= 0xf7]
		
		# Decode text if encoding table provided
		text = ""
		if encoding_table:
			for byte in data:
				if byte in encoding_table:
					text += encoding_table[byte]
				elif 0xf0 <= byte <= 0xf7:
					text += f"<{byte:02X}>"  # Control code placeholder
				else:
					text += f"[{byte:02X}]"  # Unknown byte
		
		return cls(
			message_id=message_id,
			raw_bytes=data,
			text=text,
			control_codes=control_codes
		)
	
	def to_bytes(self) -> bytes:
		"""Convert to binary with null terminator."""
		return self.raw_bytes + b'\x00'
	
	def to_asm(self) -> str:
		"""Generate ASM with hex dump and text comment."""
		# Format as db statements (16 bytes per line max)
		hex_bytes = [f"${b:02X}" for b in self.raw_bytes]
		
		lines = []
		for i in range(0, len(hex_bytes), 16):
			chunk = ",".join(hex_bytes[i:i+16])
			line = f"	db {chunk}"
			
			# Add text comment on first line
			if i == 0 and self.text:
				line += f'  ; Msg ${self.message_id:02X}: "{self.text[:30]}"'
			
			lines.append(line)
		
		# Add null terminator
		lines.append(f"	db $00  ; End of message ${self.message_id:02X}")
		
		return "\n".join(lines)
	
	def to_dict(self) -> Dict[str, Any]:
		"""Export to dictionary."""
		return {
			"message_id": self.message_id,
			"raw_bytes": list(self.raw_bytes),  # Convert to list for JSON
			"text": self.text,
			"control_codes": self.control_codes,
			"length": len(self.raw_bytes)
		}
	
	@classmethod
	def from_dict(cls, data: Dict[str, Any]) -> 'DialogString':
		"""Import from dictionary."""
		return cls(
			message_id=data["message_id"],
			raw_bytes=bytes(data["raw_bytes"]),
			text=data.get("text", ""),
			control_codes=data.get("control_codes", [])
		)


# ==============================================================================
# Palette/Color Structures (Bank $05)
# ==============================================================================

@dataclass
class PaletteEntry:
	"""
	SNES RGB555 color value (2 bytes, little-endian).
	
	Format:
		Bit 0-4:   Red (0-31)
		Bit 5-9:   Green (0-31)
		Bit 10-14: Blue (0-31)
		Bit 15:	Unused
	
	SNES RGB555: 0BBBBBGG GGGRRRRR (little-endian)
	"""
	
	red: int  # 0-31
	green: int  # 0-31
	blue: int  # 0-31
	palette_id: Optional[int] = None
	color_index: Optional[int] = None
	
	def __post_init__(self):
		"""Validate color ranges."""
		for component, name in [(self.red, "red"), (self.green, "green"), (self.blue, "blue")]:
			if not (0 <= component <= 31):
				raise ValueError(f"{name} component {component} out of range (must be 0-31)")
	
	@classmethod
	def from_bytes(cls, data: bytes, palette_id: int = 0, color_index: int = 0) -> 'PaletteEntry':
		"""Parse RGB555 from 2-byte little-endian."""
		if len(data) != 2:
			raise ValueError(f"PaletteEntry requires exactly 2 bytes, got {len(data)}")
		
		rgb555 = struct.unpack("<H", data)[0]
		
		red = rgb555 & 0x1f
		green = (rgb555 >> 5) & 0x1f
		blue = (rgb555 >> 10) & 0x1f
		
		return cls(red=red, green=green, blue=blue, palette_id=palette_id, color_index=color_index)
	
	def to_bytes(self) -> bytes:
		"""Convert to 2-byte RGB555 little-endian."""
		rgb555 = (self.red & 0x1f) | ((self.green & 0x1f) << 5) | ((self.blue & 0x1f) << 10)
		return struct.pack("<H", rgb555)
	
	def to_asm(self) -> str:
		"""Generate ASM with RGB values in comment."""
		data = self.to_bytes()
		return f"	db ${data[0]:02X},${data[1]:02X}  ; RGB({self.red:2d},{self.green:2d},{self.blue:2d})"
	
	def to_dict(self) -> Dict[str, Any]:
		"""Export to dictionary."""
		return {
			"palette_id": self.palette_id,
			"color_index": self.color_index,
			"rgb": {
				"red": self.red,
				"green": self.green,
				"blue": self.blue
			},
			"rgb555": self.to_rgb555()
		}
	
	@classmethod
	def from_dict(cls, data: Dict[str, Any]) -> 'PaletteEntry':
		"""Import from dictionary."""
		rgb = data["rgb"]
		return cls(
			red=rgb["red"],
			green=rgb["green"],
			blue=rgb["blue"],
			palette_id=data.get("palette_id"),
			color_index=data.get("color_index")
		)
	
	def to_rgb555(self) -> int:
		"""Get RGB555 value as integer."""
		return (self.red & 0x1f) | ((self.green & 0x1f) << 5) | ((self.blue & 0x1f) << 10)
	
	def to_rgb888(self) -> tuple[int, int, int]:
		"""Convert to 8-bit RGB (for display/editing)."""
		r = (self.red * 255) // 31
		g = (self.green * 255) // 31
		b = (self.blue * 255) // 31
		return (r, g, b)


# ==============================================================================
# Utility Functions
# ==============================================================================

def save_to_json(data: List[Any], filepath: str, indent: int = 2):
	"""Save list of data structures to JSON file."""
	json_data = [item.to_dict() for item in data]
	with open(filepath, 'w', encoding='utf-8') as f:
		json.dump(json_data, f, indent=indent)


def load_from_json(filepath: str, data_class: type) -> List[Any]:
	"""Load list of data structures from JSON file."""
	with open(filepath, 'r', encoding='utf-8') as f:
		json_data = json.load(f)
	return [data_class.from_dict(item) for item in json_data]


if __name__ == "__main__":
	# Example usage
	print("FFMQ Data Structures - Example Usage\n")
	
	# Example 1: Metatile
	print("Example 1: Metatile")
	tile_data = bytes([0x20, 0x22, 0x22, 0x20])  # Grass metatile
	metatile = Metatile.from_bytes(tile_data, metatile_id=0)
	metatile.description = "Grass pattern"
	print(metatile.to_asm(label="METATILE_00"))
	print()
	
	# Example 2: Collision
	print("Example 2: Collision Data")
	collision = CollisionData(tile_id=0x05, flags=0x02)  # Water tile
	print(collision.to_asm())
	print(f"Is water: {collision.is_water}")
	print()
	
	# Example 3: Text Pointer
	print("Example 3: Text Pointer")
	pointer = TextPointer(message_id=0, address=0x8400)
	print(pointer.to_asm())
	print()
	
	# Example 4: Palette
	print("Example 4: Palette Entry")
	color = PaletteEntry(red=31, green=15, blue=0, palette_id=0, color_index=0)
	print(color.to_asm())
	print(f"RGB888: {color.to_rgb888()}")
