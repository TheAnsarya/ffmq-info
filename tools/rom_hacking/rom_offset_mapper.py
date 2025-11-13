#!/usr/bin/env python3
"""
ROM Offset Mapper - Automatic dialog ID to ROM offset mapping
Maps dialog IDs to absolute ROM offsets with LoROM bank/offset notation

Features:
- Scans ROM for event script data patterns
- Identifies dialog entry points automatically
- Supports multiple ROM versions and hacks
- LoROM bank/offset format (0xBB/OOOO)
- Exports mapping database (JSON/CSV)
- Handles pointer tables and direct addressing
- Validates mappings against known patterns
- Cross-references with existing documentation

Usage:
	python rom_offset_mapper.py --rom game.sfc
	python rom_offset_mapper.py --rom game.sfc --export-csv mappings.csv
	python rom_offset_mapper.py --rom game.sfc --pointer-table 0x0E/8000
	python rom_offset_mapper.py --rom game.sfc --validate docs/known_mappings.json
"""

import argparse
import hashlib
import json
import csv
import re
import struct
from pathlib import Path
from typing import Dict, List, Tuple, Optional, Set
from dataclasses import dataclass, asdict
from enum import Enum


class PointerType(Enum):
	"""Types of pointer structures found in ROM"""
	DIRECT = "direct"  # Direct absolute offset
	RELATIVE = "relative"  # Relative to base address
	INDEXED = "indexed"  # Index into pointer table
	BANK_OFFSET = "bank_offset"  # Separate bank and offset bytes


class DialogType(Enum):
	"""Types of dialog/event scripts"""
	NPC_DIALOG = "npc_dialog"
	ITEM_DESCRIPTION = "item_description"
	SYSTEM_MESSAGE = "system_message"
	BATTLE_TEXT = "battle_text"
	EVENT_SCRIPT = "event_script"
	MENU_TEXT = "menu_text"
	UNKNOWN = "unknown"


@dataclass
class DialogMapping:
	"""Mapping of a dialog ID to its ROM location"""
	dialog_id: str
	rom_offset: int
	bank: int
	bank_offset: int
	lorom_notation: str
	size: int
	dialog_type: DialogType
	pointer_type: PointerType
	confidence: float  # 0.0-1.0, how confident we are in this mapping
	notes: str = ""
	
	def to_dict(self) -> dict:
		"""Convert to dictionary for JSON export"""
		d = asdict(self)
		d['dialog_type'] = self.dialog_type.value
		d['pointer_type'] = self.pointer_type.value
		return d


@dataclass
class PointerTable:
	"""Pointer table structure in ROM"""
	rom_offset: int
	entry_count: int
	entry_size: int  # Bytes per entry
	pointer_type: PointerType
	base_address: int  # For relative pointers
	entries: List[int]  # Actual pointer values


@dataclass
class MappingDatabase:
	"""Complete database of dialog mappings"""
	rom_file: str
	rom_checksum: str
	rom_size: int
	mapping_count: int
	pointer_tables: List[PointerTable]
	mappings: List[DialogMapping]
	
	def to_dict(self) -> dict:
		"""Convert to dictionary for JSON export"""
		return {
			'rom_file': self.rom_file,
			'rom_checksum': self.rom_checksum,
			'rom_size': self.rom_size,
			'mapping_count': self.mapping_count,
			'pointer_tables': [self._pointer_table_to_dict(pt) for pt in self.pointer_tables],
			'mappings': [m.to_dict() for m in self.mappings]
		}
	
	def _pointer_table_to_dict(self, pt: PointerTable) -> dict:
		"""Convert pointer table to dictionary"""
		return {
			'rom_offset': pt.rom_offset,
			'entry_count': pt.entry_count,
			'entry_size': pt.entry_size,
			'pointer_type': pt.pointer_type.value,
			'base_address': pt.base_address,
			'entries': pt.entries[:20]  # First 20 entries for preview
		}


class ROMOffsetMapper:
	"""Maps dialog IDs to ROM offsets automatically"""
	
	# SNES LoROM constants
	LOROM_BANK_SIZE = 0x10000
	LOROM_OFFSET_MASK = 0x7FFF
	LOROM_BANK_THRESHOLD = 0xC0
	
	# Event script command signatures
	EVENT_COMMANDS = {
		0x00: "END",
		0x01: "WAIT",
		0x02: "NEWLINE",
		0x03: "SET_FLAG",
		0x04: "CLEAR_FLAG",
		0x05: "CHECK_FLAG",
		0x10: "CALL_SUBROUTINE",
		0x20: "MEMORY_WRITE",
		0xFF: "RETURN"
	}
	
	# Common text control codes
	TEXT_CONTROL_CODES = {
		0xF0, 0xF1, 0xF2, 0xF3, 0xF4, 0xF5, 0xF6, 0xF7,
		0xF8, 0xF9, 0xFA, 0xFB, 0xFC, 0xFD, 0xFE, 0xFF
	}
	
	# ASCII-like character ranges (simplified)
	PRINTABLE_RANGE = range(0x20, 0xE0)
	
	def __init__(self, verbose: bool = False):
		self.verbose = verbose
		self.rom_data: bytes = b""
		self.rom_size: int = 0
		self.rom_checksum: str = ""
		self.mappings: List[DialogMapping] = []
		self.pointer_tables: List[PointerTable] = []
	
	def load_rom(self, rom_path: Path) -> None:
		"""Load ROM file and calculate checksum"""
		if self.verbose:
			print(f"Loading ROM: {rom_path}")
		
		with open(rom_path, 'rb') as f:
			self.rom_data = f.read()
		
		self.rom_size = len(self.rom_data)
		self.rom_checksum = hashlib.sha256(self.rom_data).hexdigest()
		
		if self.verbose:
			print(f"ROM size: {self.rom_size} bytes ({self.rom_size // 1024}KB)")
			print(f"SHA-256: {self.rom_checksum[:16]}...")
	
	def offset_to_lorom(self, offset: int) -> Tuple[int, int, str]:
		"""
		Convert absolute ROM offset to LoROM bank/offset notation
		
		Args:
			offset: Absolute ROM offset
		
		Returns:
			Tuple of (bank, bank_offset, lorom_notation)
		"""
		# Determine if in upper or lower ROM half
		if offset >= 0x200000:
			# Upper half: banks $C0-$FF
			bank = 0xC0 + ((offset - 0x200000) // 0x8000)
			bank_offset = 0x8000 + ((offset - 0x200000) % 0x8000)
		else:
			# Lower half: banks $00-$3F (or $80-$BF mirror)
			bank = (offset // 0x8000) % 0x40
			bank_offset = 0x8000 + (offset % 0x8000)
		
		lorom_notation = f"0x{bank:02X}/{bank_offset:04X}"
		return bank, bank_offset, lorom_notation
	
	def lorom_to_offset(self, bank: int, bank_offset: int) -> int:
		"""
		Convert LoROM bank/offset to absolute ROM offset
		
		Args:
			bank: LoROM bank number
			bank_offset: Offset within bank
		
		Returns:
			Absolute ROM offset
		"""
		if bank >= 0xC0:
			# Upper ROM half
			return 0x200000 + ((bank - 0xC0) * 0x8000) + (bank_offset - 0x8000)
		else:
			# Lower ROM half
			return (bank % 0x40) * 0x8000 + (bank_offset - 0x8000)
	
	def read_pointer_table(self, offset: int, entry_count: int, 
	                       entry_size: int = 2, pointer_type: PointerType = PointerType.DIRECT,
	                       base_address: int = 0) -> PointerTable:
		"""
		Read a pointer table from ROM
		
		Args:
			offset: ROM offset of pointer table
			entry_count: Number of entries
			entry_size: Bytes per entry (2 or 3 typically)
			pointer_type: How to interpret pointer values
			base_address: Base address for relative pointers
		
		Returns:
			PointerTable object
		"""
		entries = []
		for i in range(entry_count):
			ptr_offset = offset + (i * entry_size)
			if ptr_offset + entry_size > self.rom_size:
				break
			
			if entry_size == 2:
				ptr_value = struct.unpack_from('<H', self.rom_data, ptr_offset)[0]
			elif entry_size == 3:
				ptr_value = struct.unpack_from('<I', self.rom_data + b'\x00', ptr_offset)[0] & 0xFFFFFF
			else:
				ptr_value = struct.unpack_from('<I', self.rom_data + b'\x00' * 4, ptr_offset)[0]
			
			entries.append(ptr_value)
		
		return PointerTable(
			rom_offset=offset,
			entry_count=len(entries),
			entry_size=entry_size,
			pointer_type=pointer_type,
			base_address=base_address,
			entries=entries
		)
	
	def detect_pointer_tables(self, min_entries: int = 10, max_entries: int = 1000) -> List[PointerTable]:
		"""
		Scan ROM for pointer table patterns
		
		Args:
			min_entries: Minimum entries to consider valid table
			max_entries: Maximum entries to scan
		
		Returns:
			List of detected pointer tables
		"""
		tables = []
		
		if self.verbose:
			print(f"\nScanning for pointer tables (min={min_entries}, max={max_entries})...")
		
		# Scan ROM in chunks
		for offset in range(0, self.rom_size - 0x100, 0x10):
			# Look for sequences of 16-bit pointers
			if offset + (max_entries * 2) > self.rom_size:
				continue
			
			# Check if this looks like a pointer table
			# Heuristic: pointers should be in ascending order and within ROM bounds
			pointers = []
			for i in range(max_entries):
				ptr_offset = offset + (i * 2)
				if ptr_offset + 2 > self.rom_size:
					break
				ptr = struct.unpack_from('<H', self.rom_data, ptr_offset)[0]
				
				# Sanity checks
				if ptr < 0x8000 or ptr >= 0xFFFF:
					break
				if pointers and ptr < pointers[-1]:
					break
				
				pointers.append(ptr)
				
				# Stop if we have enough
				if len(pointers) >= max_entries:
					break
			
			# Valid table?
			if len(pointers) >= min_entries:
				table = PointerTable(
					rom_offset=offset,
					entry_count=len(pointers),
					entry_size=2,
					pointer_type=PointerType.INDEXED,
					base_address=0x8000,
					entries=pointers
				)
				tables.append(table)
				if self.verbose:
					print(f"  Found table at 0x{offset:06X} with {len(pointers)} entries")
		
		return tables
	
	def is_event_script(self, offset: int, max_check: int = 50) -> Tuple[bool, float]:
		"""
		Check if data at offset looks like an event script
		
		Args:
			offset: ROM offset to check
			max_check: Maximum bytes to scan
		
		Returns:
			Tuple of (is_script, confidence)
		"""
		if offset >= self.rom_size - max_check:
			return False, 0.0
		
		data = self.rom_data[offset:offset + max_check]
		confidence = 0.0
		
		# Check for event commands
		command_count = 0
		for i, byte in enumerate(data):
			if byte in self.EVENT_COMMANDS:
				command_count += 1
				confidence += 0.1
			
			# END command is strong indicator
			if byte == 0x00:
				confidence += 0.3
				break
		
		# Check for control flow patterns
		if command_count >= 3:
			confidence += 0.2
		
		return confidence >= 0.5, min(confidence, 1.0)
	
	def is_text_data(self, offset: int, min_length: int = 10) -> Tuple[bool, float]:
		"""
		Check if data at offset looks like text
		
		Args:
			offset: ROM offset to check
			min_length: Minimum printable characters
		
		Returns:
			Tuple of (is_text, confidence)
		"""
		if offset >= self.rom_size - min_length:
			return False, 0.0
		
		data = self.rom_data[offset:offset + 100]
		printable_count = 0
		control_count = 0
		
		for byte in data:
			if byte in self.PRINTABLE_RANGE:
				printable_count += 1
			elif byte in self.TEXT_CONTROL_CODES:
				control_count += 1
			elif byte == 0x00:  # End of text
				break
		
		if printable_count < min_length:
			return False, 0.0
		
		ratio = printable_count / (printable_count + control_count + 1)
		confidence = min(ratio, 1.0)
		
		return confidence >= 0.6, confidence
	
	def scan_for_dialogs(self, start_offset: int = 0, end_offset: Optional[int] = None,
	                     scan_step: int = 16) -> List[DialogMapping]:
		"""
		Scan ROM for dialog/event script patterns
		
		Args:
			start_offset: Starting ROM offset
			end_offset: Ending ROM offset (None = end of ROM)
			scan_step: Bytes to skip between scans
		
		Returns:
			List of detected dialog mappings
		"""
		if end_offset is None:
			end_offset = self.rom_size
		
		mappings = []
		
		if self.verbose:
			print(f"\nScanning ROM from 0x{start_offset:06X} to 0x{end_offset:06X}")
		
		for offset in range(start_offset, end_offset, scan_step):
			# Check for event script
			is_script, script_conf = self.is_event_script(offset)
			if is_script:
				bank, bank_offset, lorom = self.offset_to_lorom(offset)
				size = self._calculate_script_size(offset)
				
				mapping = DialogMapping(
					dialog_id=f"EVENT_{offset:06X}",
					rom_offset=offset,
					bank=bank,
					bank_offset=bank_offset,
					lorom_notation=lorom,
					size=size,
					dialog_type=DialogType.EVENT_SCRIPT,
					pointer_type=PointerType.DIRECT,
					confidence=script_conf,
					notes=f"Auto-detected at ROM offset 0x{offset:06X}"
				)
				mappings.append(mapping)
				continue
			
			# Check for text data
			is_text, text_conf = self.is_text_data(offset)
			if is_text:
				bank, bank_offset, lorom = self.offset_to_lorom(offset)
				size = self._calculate_text_size(offset)
				
				mapping = DialogMapping(
					dialog_id=f"TEXT_{offset:06X}",
					rom_offset=offset,
					bank=bank,
					bank_offset=bank_offset,
					lorom_notation=lorom,
					size=size,
					dialog_type=DialogType.NPC_DIALOG,
					pointer_type=PointerType.DIRECT,
					confidence=text_conf,
					notes=f"Auto-detected text at ROM offset 0x{offset:06X}"
				)
				mappings.append(mapping)
		
		return mappings
	
	def _calculate_script_size(self, offset: int) -> int:
		"""Calculate size of event script starting at offset"""
		size = 0
		max_size = 1024  # Sanity limit
		
		while size < max_size and offset + size < self.rom_size:
			byte = self.rom_data[offset + size]
			size += 1
			
			# END command
			if byte == 0x00:
				break
			
			# Commands with parameters
			if byte == 0x10:  # CALL_SUBROUTINE
				size += 2
			elif byte == 0x20:  # MEMORY_WRITE
				size += 3
		
		return size
	
	def _calculate_text_size(self, offset: int) -> int:
		"""Calculate size of text data starting at offset"""
		size = 0
		max_size = 512
		
		while size < max_size and offset + size < self.rom_size:
			byte = self.rom_data[offset + size]
			size += 1
			
			# NULL terminator
			if byte == 0x00:
				break
		
		return size
	
	def map_from_pointer_table(self, table: PointerTable, dialog_id_prefix: str = "PTR") -> List[DialogMapping]:
		"""
		Create mappings from a pointer table
		
		Args:
			table: PointerTable to process
			dialog_id_prefix: Prefix for generated dialog IDs
		
		Returns:
			List of dialog mappings
		"""
		mappings = []
		
		for i, ptr in enumerate(table.entries):
			# Convert pointer to ROM offset
			if table.pointer_type == PointerType.INDEXED:
				rom_offset = self.lorom_to_offset(ptr >> 16, ptr & 0xFFFF)
			elif table.pointer_type == PointerType.RELATIVE:
				rom_offset = table.base_address + ptr
			else:
				rom_offset = ptr
			
			# Skip invalid offsets
			if rom_offset >= self.rom_size:
				continue
			
			bank, bank_offset, lorom = self.offset_to_lorom(rom_offset)
			
			# Determine dialog type
			is_script, script_conf = self.is_event_script(rom_offset)
			is_text, text_conf = self.is_text_data(rom_offset)
			
			if is_script:
				dialog_type = DialogType.EVENT_SCRIPT
				confidence = script_conf
				size = self._calculate_script_size(rom_offset)
			elif is_text:
				dialog_type = DialogType.NPC_DIALOG
				confidence = text_conf
				size = self._calculate_text_size(rom_offset)
			else:
				dialog_type = DialogType.UNKNOWN
				confidence = 0.3
				size = 0
			
			mapping = DialogMapping(
				dialog_id=f"{dialog_id_prefix}_{i:04d}",
				rom_offset=rom_offset,
				bank=bank,
				bank_offset=bank_offset,
				lorom_notation=lorom,
				size=size,
				dialog_type=dialog_type,
				pointer_type=table.pointer_type,
				confidence=confidence,
				notes=f"From pointer table at 0x{table.rom_offset:06X}, entry {i}"
			)
			mappings.append(mapping)
		
		return mappings
	
	def validate_against_known(self, known_mappings: Dict[str, str]) -> None:
		"""
		Validate detected mappings against known good mappings
		
		Args:
			known_mappings: Dictionary of dialog_id -> expected_offset
		"""
		if self.verbose:
			print(f"\nValidating against {len(known_mappings)} known mappings...")
		
		matches = 0
		mismatches = 0
		missing = 0
		
		for dialog_id, expected_offset in known_mappings.items():
			# Find our mapping
			found = None
			for mapping in self.mappings:
				if mapping.dialog_id == dialog_id:
					found = mapping
					break
			
			if found is None:
				missing += 1
				if self.verbose:
					print(f"  MISSING: {dialog_id} (expected at {expected_offset})")
			elif found.lorom_notation == expected_offset or f"0x{found.rom_offset:06X}" == expected_offset:
				matches += 1
				found.confidence = 1.0  # Confirmed by known mapping
			else:
				mismatches += 1
				if self.verbose:
					print(f"  MISMATCH: {dialog_id} - found {found.lorom_notation}, expected {expected_offset}")
		
		if self.verbose:
			print(f"\nValidation Results:")
			print(f"  Matches: {matches}")
			print(f"  Mismatches: {mismatches}")
			print(f"  Missing: {missing}")
	
	def export_json(self, output_path: Path, rom_file: str) -> None:
		"""Export mappings to JSON file"""
		db = MappingDatabase(
			rom_file=rom_file,
			rom_checksum=self.rom_checksum,
			rom_size=self.rom_size,
			mapping_count=len(self.mappings),
			pointer_tables=self.pointer_tables,
			mappings=self.mappings
		)
		
		with open(output_path, 'w') as f:
			json.dump(db.to_dict(), f, indent=2)
		
		if self.verbose:
			print(f"\nExported {len(self.mappings)} mappings to {output_path}")
	
	def export_csv(self, output_path: Path) -> None:
		"""Export mappings to CSV file"""
		with open(output_path, 'w', newline='') as f:
			writer = csv.writer(f)
			writer.writerow(['Dialog ID', 'ROM Offset', 'LoROM Notation', 'Size', 'Type', 'Confidence', 'Notes'])
			
			for mapping in self.mappings:
				writer.writerow([
					mapping.dialog_id,
					f"0x{mapping.rom_offset:06X}",
					mapping.lorom_notation,
					mapping.size,
					mapping.dialog_type.value,
					f"{mapping.confidence:.2f}",
					mapping.notes
				])
		
		if self.verbose:
			print(f"\nExported {len(self.mappings)} mappings to {output_path}")
	
	def generate_report(self) -> str:
		"""Generate human-readable report"""
		lines = [
			"# ROM Offset Mapping Report",
			"",
			"## ROM Information",
			f"- **Size**: {self.rom_size:,} bytes ({self.rom_size // 1024}KB)",
			f"- **SHA-256**: {self.rom_checksum}",
			"",
			"## Summary",
			f"- **Total Mappings**: {len(self.mappings)}",
			f"- **Pointer Tables**: {len(self.pointer_tables)}",
			""
		]
		
		# Group by dialog type
		by_type = {}
		for mapping in self.mappings:
			dtype = mapping.dialog_type.value
			if dtype not in by_type:
				by_type[dtype] = []
			by_type[dtype].append(mapping)
		
		lines.append("### By Dialog Type")
		for dtype, mappings in sorted(by_type.items()):
			avg_conf = sum(m.confidence for m in mappings) / len(mappings)
			lines.append(f"- **{dtype}**: {len(mappings)} entries (avg confidence: {avg_conf:.2f})")
		
		lines.append("")
		lines.append("## Pointer Tables Detected")
		for i, table in enumerate(self.pointer_tables):
			bank, offset, lorom = self.offset_to_lorom(table.rom_offset)
			lines.append(f"### Table {i + 1}")
			lines.append(f"- **Location**: {lorom} (0x{table.rom_offset:06X})")
			lines.append(f"- **Entries**: {table.entry_count}")
			lines.append(f"- **Entry Size**: {table.entry_size} bytes")
			lines.append(f"- **Type**: {table.pointer_type.value}")
			lines.append("")
		
		# High confidence mappings
		high_conf = [m for m in self.mappings if m.confidence >= 0.8]
		if high_conf:
			lines.append("## High Confidence Mappings")
			lines.append(f"Found {len(high_conf)} high-confidence mappings (≥0.8):")
			lines.append("")
			lines.append("| Dialog ID | LoROM | Size | Type | Confidence |")
			lines.append("|-----------|-------|------|------|------------|")
			for m in sorted(high_conf, key=lambda x: x.rom_offset)[:50]:
				lines.append(f"| {m.dialog_id} | {m.lorom_notation} | {m.size} | {m.dialog_type.value} | {m.confidence:.2f} |")
		
		return "\n".join(lines)


def main():
	parser = argparse.ArgumentParser(description='Map dialog IDs to ROM offsets automatically')
	parser.add_argument('--rom', type=Path, required=True, help='ROM file to analyze')
	parser.add_argument('--export-json', type=Path, help='Export mappings to JSON file')
	parser.add_argument('--export-csv', type=Path, help='Export mappings to CSV file')
	parser.add_argument('--report', type=Path, help='Generate Markdown report')
	parser.add_argument('--pointer-table', type=str, help='Pointer table address (0xBB/OOOO format)')
	parser.add_argument('--validate', type=Path, help='Validate against known mappings (JSON file)')
	parser.add_argument('--scan-start', type=lambda x: int(x, 0), default=0, help='Start offset for ROM scan')
	parser.add_argument('--scan-end', type=lambda x: int(x, 0), help='End offset for ROM scan')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	mapper = ROMOffsetMapper(verbose=args.verbose)
	
	# Load ROM
	mapper.load_rom(args.rom)
	
	# Process pointer table if specified
	if args.pointer_table:
		match = re.match(r'0x([0-9A-Fa-f]{2})/([0-9A-Fa-f]{4})', args.pointer_table)
		if match:
			bank = int(match.group(1), 16)
			offset = int(match.group(2), 16)
			rom_offset = mapper.lorom_to_offset(bank, offset)
			table = mapper.read_pointer_table(rom_offset, entry_count=256)
			mapper.pointer_tables.append(table)
			mapper.mappings.extend(mapper.map_from_pointer_table(table))
		else:
			print(f"Invalid pointer table format: {args.pointer_table}")
			return 1
	
	# Scan ROM for patterns
	mapper.mappings.extend(mapper.scan_for_dialogs(args.scan_start, args.scan_end))
	
	# Validate against known mappings
	if args.validate:
		with open(args.validate) as f:
			known = json.load(f)
		mapper.validate_against_known(known)
	
	# Export results
	if args.export_json:
		mapper.export_json(args.export_json, str(args.rom))
	
	if args.export_csv:
		mapper.export_csv(args.export_csv)
	
	if args.report:
		report = mapper.generate_report()
		with open(args.report, 'w') as f:
			f.write(report)
		if args.verbose:
			print(f"\nReport saved to {args.report}")
	
	# Print summary
	print(f"\n✓ Found {len(mapper.mappings)} dialog mappings in ROM")
	print(f"  ROM: {args.rom} ({mapper.rom_size:,} bytes)")
	print(f"  SHA-256: {mapper.rom_checksum[:16]}...")
	
	return 0


if __name__ == '__main__':
	exit(main())
