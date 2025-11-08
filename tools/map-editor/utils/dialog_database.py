#!/usr/bin/env python3
"""
FFMQ Dialog Database
Manages dialog pointer table, dialog entries, and ROM operations
"""

from dataclasses import dataclass, field
from typing import Dict, List, Tuple, Optional, Set
from pathlib import Path
import struct
import json

from dialog_text import DialogText, CharacterTable, ControlCode


@dataclass
class DialogEntry:
	"""Represents a single dialog entry in the ROM"""
	id: int                           # Dialog ID (index in pointer table)
	text: str                         # Decoded text with control codes
	raw_bytes: bytearray              # Original ROM bytes
	pointer: int                      # Pointer value (SNES address)
	address: int                      # Actual ROM address (PC)
	length: int                       # Length in bytes
	references: List[str] = field(default_factory=list)  # NPCs/events using this
	tags: Set[str] = field(default_factory=set)          # User tags
	notes: str = ""                   # User notes
	modified: bool = False            # Has been edited

	def __str__(self) -> str:
		"""String representation"""
		preview = self.text[:40] + "..." if len(self.text) > 40 else self.text
		return f"Dialog #{self.id:03d}: {preview}"

	def to_dict(self) -> dict:
		"""Convert to dictionary for JSON export"""
		return {
			'id': self.id,
			'text': self.text,
			'bytes': ','.join(f'0x{b:02X}' for b in self.raw_bytes),
			'length': self.length,
			'pointer': f'0x{self.pointer:04X}',
			'address': f'0x{self.address:06X}',
			'references': self.references,
			'tags': list(self.tags),
			'notes': self.notes,
			'modified': self.modified
		}

	@staticmethod
	def from_dict(data: dict) -> 'DialogEntry':
		"""Create from dictionary (JSON import)"""
		# Parse bytes
		if 'bytes' in data and data['bytes']:
			byte_strs = data['bytes'].split(',')
			raw_bytes = bytearray(int(b.strip(), 16) for b in byte_strs)
		else:
			raw_bytes = bytearray()

		return DialogEntry(
			id=data['id'],
			text=data.get('text', ''),
			raw_bytes=raw_bytes,
			pointer=int(data.get('pointer', '0x0'), 16),
			address=int(data.get('address', '0x0'), 16),
			length=data.get('length', len(raw_bytes)),
			references=data.get('references', []),
			tags=set(data.get('tags', [])),
			notes=data.get('notes', ''),
			modified=data.get('modified', False)
		)


class DialogDatabase:
	"""Manages all dialog entries and ROM operations"""

	# ROM offsets (PC addresses)
	POINTER_TABLE_ADDR = 0x00D636    # Dialog pointer table
	DIALOG_BANK = 0x03               # Dialog stored in bank $03
	DIALOG_DATA_START = 0x018000     # Bank $03 start (PC)
	DIALOG_DATA_END = 0x01FFFF       # Bank $03 end (PC)
	MAX_DIALOGS = 256                # Maximum dialog entries

	def __init__(self, rom_path: Optional[Path] = None):
		"""
		Initialize dialog database

		Args:
			rom_path: Path to ROM file (optional, can load later)
		"""
		self.rom_path = rom_path
		self.rom_data: Optional[bytearray] = None
		self.rom_size = 0

		self.dialogs: Dict[int, DialogEntry] = {}
		self.dialog_text = DialogText()
		self.modified = False

		# Free space tracking
		self.free_regions: List[Tuple[int, int]] = []  # (start, end) tuples
		self.used_regions: List[Tuple[int, int]] = []

		if rom_path:
			self.load_rom(rom_path)

	def load_rom(self, rom_path: Path) -> bool:
		"""
		Load ROM file

		Args:
			rom_path: Path to ROM file

		Returns:
			True if successful
		"""
		if not rom_path.exists():
			print(f"ERROR: ROM not found: {rom_path}")
			return False

		try:
			with open(rom_path, 'rb') as f:
				self.rom_data = bytearray(f.read())

			self.rom_size = len(self.rom_data)
			self.rom_path = rom_path

			print(f"Loaded ROM: {rom_path.name} ({self.rom_size} bytes)")
			return True
		except Exception as e:
			print(f"ERROR loading ROM: {e}")
			return False

	def save_rom(self, output_path: Optional[Path] = None) -> bool:
		"""
		Save modified ROM

		Args:
			output_path: Output path (uses original if None)

		Returns:
			True if successful
		"""
		if not self.rom_data:
			print("ERROR: No ROM data loaded")
			return False

		save_path = output_path or self.rom_path
		if not save_path:
			print("ERROR: No output path specified")
			return False

		try:
			# Create backup if overwriting
			if save_path.exists() and save_path == self.rom_path:
				backup_path = save_path.with_suffix('.bak')
				if not backup_path.exists():
					save_path.rename(backup_path)
					print(f"Created backup: {backup_path}")

			# Write ROM
			with open(save_path, 'wb') as f:
				f.write(self.rom_data)

			self.modified = False
			print(f"Saved ROM: {save_path}")
			return True
		except Exception as e:
			print(f"ERROR saving ROM: {e}")
			return False

	def read_pointer_table(self) -> List[int]:
		"""
		Read dialog pointer table from ROM

		Returns:
			List of SNES pointers
		"""
		if not self.rom_data:
			return []

		pointers = []

		for i in range(self.MAX_DIALOGS):
			offset = self.POINTER_TABLE_ADDR + (i * 2)

			if offset + 2 > self.rom_size:
				break

			# Read 16-bit little-endian pointer
			ptr_low = self.rom_data[offset]
			ptr_high = self.rom_data[offset + 1]
			pointer = (ptr_high << 8) | ptr_low

			pointers.append(pointer)

		return pointers

	def write_pointer_table(self, pointers: List[int]) -> bool:
		"""
		Write dialog pointer table to ROM

		Args:
			pointers: List of SNES pointers

		Returns:
			True if successful
		"""
		if not self.rom_data:
			return False

		for i, pointer in enumerate(pointers[:self.MAX_DIALOGS]):
			offset = self.POINTER_TABLE_ADDR + (i * 2)

			if offset + 2 > self.rom_size:
				break

			# Write 16-bit little-endian pointer
			self.rom_data[offset] = pointer & 0xFF
			self.rom_data[offset + 1] = (pointer >> 8) & 0xFF

		self.modified = True
		return True

	def snes_to_pc(self, snes_addr: int, bank: int = DIALOG_BANK) -> int:
		"""
		Convert SNES address to PC address

		Args:
			snes_addr: SNES address (16-bit)
			bank: SNES bank number

		Returns:
			PC address
		"""
		# LoROM mapping: Bank $03, $8000-$FFFF → PC $018000-$01FFFF
		# Formula: PC = (bank * 0x8000) + (snes_addr - 0x8000)
		pc_addr = (bank * 0x8000) + (snes_addr - 0x8000)
		return pc_addr
	
	def pc_to_snes(self, pc_addr: int) -> Tuple[int, int]:
		"""
		Convert PC address to SNES address

		Args:
			pc_addr: PC address

		Returns:
			Tuple of (bank, snes_address)
		"""
		# Assuming dialog bank ($03)
		bank = 0x03
		offset = pc_addr - self.DIALOG_DATA_START
		snes_addr = 0x8000 + offset
		return bank, snes_addr

	def read_dialog_data(self, pc_addr: int, max_length: int = 512) -> bytearray:
		"""
		Read dialog data from ROM

		Args:
			pc_addr: PC address of dialog data
			max_length: Maximum bytes to read

		Returns:
			Dialog bytes (up to terminator)
		"""
		if not self.rom_data or pc_addr >= self.rom_size:
			return bytearray()

		data = bytearray()

		for i in range(max_length):
			if pc_addr + i >= self.rom_size:
				break

			byte = self.rom_data[pc_addr + i]
			data.append(byte)

			# Stop at terminator
			if byte == ControlCode.END:
				break

		return data

	def write_dialog_data(self, pc_addr: int, data: bytearray) -> bool:
		"""
		Write dialog data to ROM

		Args:
			pc_addr: PC address to write to
			data: Dialog bytes to write

		Returns:
			True if successful
		"""
		if not self.rom_data:
			return False

		if pc_addr + len(data) > self.rom_size:
			print(f"ERROR: Dialog data exceeds ROM size")
			return False

		# Write data
		for i, byte in enumerate(data):
			self.rom_data[pc_addr + i] = byte

		self.modified = True
		return True

	def extract_all_dialogs(self) -> Dict[int, DialogEntry]:
		"""
		Extract all dialogs from ROM

		Returns:
			Dictionary of dialog entries (id → entry)
		"""
		if not self.rom_data:
			print("ERROR: No ROM loaded")
			return {}

		print("Extracting dialogs from ROM...")

		# Read pointer table
		pointers = self.read_pointer_table()

		dialogs = {}

		for dialog_id, pointer in enumerate(pointers):
			# Convert to PC address
			pc_addr = self.snes_to_pc(pointer)

			# Bounds check
			if pc_addr < self.DIALOG_DATA_START or pc_addr > self.DIALOG_DATA_END:
				continue

			# Read dialog data
			raw_bytes = self.read_dialog_data(pc_addr)

			if not raw_bytes:
				continue

			# Decode text
			text = self.dialog_text.decode(raw_bytes)

			# Skip empty dialogs
			if not text.strip():
				continue

			# Create entry
			entry = DialogEntry(
				id=dialog_id,
				text=text,
				raw_bytes=raw_bytes,
				pointer=pointer,
				address=pc_addr,
				length=len(raw_bytes)
			)

			dialogs[dialog_id] = entry

		self.dialogs = dialogs
		print(f"Extracted {len(dialogs)} dialogs")

		return dialogs

	def get_dialog(self, dialog_id: int) -> Optional[DialogEntry]:
		"""Get dialog by ID"""
		return self.dialogs.get(dialog_id)

	def update_dialog(self, dialog_id: int, new_text: str) -> bool:
		"""
		Update dialog text

		Args:
			dialog_id: Dialog ID to update
			new_text: New dialog text

		Returns:
			True if successful
		"""
		if dialog_id not in self.dialogs:
			print(f"ERROR: Dialog {dialog_id} not found")
			return False

		entry = self.dialogs[dialog_id]

		# Validate new text
		is_valid, messages = self.dialog_text.validate(new_text)
		if not is_valid:
			print(f"ERROR: Invalid dialog text:")
			for msg in messages:
				print(f"  - {msg}")
			return False

		# Encode new text
		new_bytes = self.dialog_text.encode(new_text)

		# Check if it fits in original space
		if len(new_bytes) <= entry.length:
			# Can overwrite in place
			self.write_dialog_data(entry.address, new_bytes)

			# Pad with zeros if shorter
			if len(new_bytes) < entry.length:
				padding = bytearray([0x00] * (entry.length - len(new_bytes)))
				self.write_dialog_data(entry.address + len(new_bytes), padding)
		else:
			# Need to relocate - find free space
			new_addr = self.find_free_space(len(new_bytes))

			if new_addr is None:
				print(f"ERROR: Not enough free space for dialog (need {len(new_bytes)} bytes)")
				return False

			# Write to new location
			self.write_dialog_data(new_addr, new_bytes)

			# Update pointer
			bank, snes_addr = self.pc_to_snes(new_addr)
			pointers = self.read_pointer_table()
			pointers[dialog_id] = snes_addr
			self.write_pointer_table(pointers)

			entry.address = new_addr
			entry.pointer = snes_addr

		# Update entry
		entry.text = new_text
		entry.raw_bytes = new_bytes
		entry.length = len(new_bytes)
		entry.modified = True

		self.modified = True
		return True

	def find_free_space(self, size: int) -> Optional[int]:
		"""
		Find free space in dialog bank for new data

		Args:
			size: Required size in bytes

		Returns:
			PC address of free space, or None if not found
		"""
		# Build list of used regions
		self.update_used_regions()

		# Find gaps in used regions
		self.free_regions = []

		current = self.DIALOG_DATA_START

		for start, end in sorted(self.used_regions):
			if current < start:
				# Found a gap
				gap_size = start - current
				if gap_size >= size:
					return current
				self.free_regions.append((current, start))
			current = max(current, end)

		# Check space after last used region
		if current + size <= self.DIALOG_DATA_END:
			return current

		return None

	def update_used_regions(self):
		"""Update list of used memory regions"""
		self.used_regions = []

		for entry in self.dialogs.values():
			self.used_regions.append((entry.address, entry.address + entry.length))

	def search_dialogs(self, query: str, search_tags: bool = True, search_notes: bool = True) -> List[DialogEntry]:
		"""
		Search dialogs by text, tags, or notes

		Args:
			query: Search query
			search_tags: Include tags in search
			search_notes: Include notes in search

		Returns:
			List of matching dialog entries
		"""
		query_lower = query.lower()
		results = []

		for entry in self.dialogs.values():
			# Search text
			if query_lower in entry.text.lower():
				results.append(entry)
				continue

			# Search tags
			if search_tags:
				for tag in entry.tags:
					if query_lower in tag.lower():
						results.append(entry)
						break

			# Search notes
			if search_notes and query_lower in entry.notes.lower():
				results.append(entry)

		return results

	def export_json(self, output_path: Path) -> bool:
		"""
		Export all dialogs to JSON

		Args:
			output_path: Output JSON file path

		Returns:
			True if successful
		"""
		try:
			data = {
				'version': '1.0',
				'rom': self.rom_path.name if self.rom_path else 'unknown',
				'dialog_count': len(self.dialogs),
				'dialogs': [entry.to_dict() for entry in sorted(self.dialogs.values(), key=lambda e: e.id)]
			}

			with open(output_path, 'w', encoding='utf-8') as f:
				json.dump(data, f, indent=2, ensure_ascii=False)

			print(f"Exported {len(self.dialogs)} dialogs to {output_path}")
			return True
		except Exception as e:
			print(f"ERROR exporting dialogs: {e}")
			return False

	def import_json(self, input_path: Path) -> bool:
		"""
		Import dialogs from JSON

		Args:
			input_path: Input JSON file path

		Returns:
			True if successful
		"""
		try:
			with open(input_path, 'r', encoding='utf-8') as f:
				data = json.load(f)

			imported = 0

			for dialog_data in data.get('dialogs', []):
				entry = DialogEntry.from_dict(dialog_data)

				# If dialog exists, update it
				if entry.id in self.dialogs:
					self.update_dialog(entry.id, entry.text)

					# Update metadata
					existing = self.dialogs[entry.id]
					existing.tags = entry.tags
					existing.notes = entry.notes
					existing.references = entry.references

					imported += 1

			print(f"Imported {imported} dialogs from {input_path}")
			return True
		except Exception as e:
			print(f"ERROR importing dialogs: {e}")
			return False

	def get_statistics(self) -> dict:
		"""Get database statistics"""
		if not self.dialogs:
			return {}

		total_bytes = sum(entry.length for entry in self.dialogs.values())
		avg_length = total_bytes / len(self.dialogs)

		modified_count = sum(1 for entry in self.dialogs.values() if entry.modified)
		tagged_count = sum(1 for entry in self.dialogs.values() if entry.tags)

		# Count control codes
		control_code_usage = {}
		for entry in self.dialogs.values():
			metrics = self.dialog_text.calculate_metrics(entry.text)
			for code, count in metrics.control_codes.items():
				control_code_usage[code] = control_code_usage.get(code, 0) + count

		return {
			'total_dialogs': len(self.dialogs),
			'total_bytes': total_bytes,
			'average_length': avg_length,
			'modified_count': modified_count,
			'tagged_count': tagged_count,
			'control_code_usage': control_code_usage,
			'free_space': self.DIALOG_DATA_END - self.DIALOG_DATA_START - total_bytes
		}


# Example usage
if __name__ == '__main__':
	import sys

	if len(sys.argv) < 2:
		print("Usage: python dialog_database.py <rom_file> [output_json]")
		sys.exit(1)

	rom_file = Path(sys.argv[1])

	# Create database
	db = DialogDatabase(rom_file)

	# Extract all dialogs
	dialogs = db.extract_all_dialogs()

	# Show statistics
	stats = db.get_statistics()
	print("\nDialog Database Statistics:")
	print(f"  Total dialogs: {stats['total_dialogs']}")
	print(f"  Total bytes: {stats['total_bytes']}")
	print(f"  Average length: {stats['average_length']:.1f} bytes")
	print(f"  Free space: {stats['free_space']} bytes")
	print()

	# Show first 10 dialogs
	print("First 10 dialogs:")
	for i in range(min(10, len(dialogs))):
		if i in dialogs:
			entry = dialogs[i]
			print(f"  {entry}")
	print()

	# Export to JSON if specified
	if len(sys.argv) >= 3:
		output_file = Path(sys.argv[2])
		db.export_json(output_file)
