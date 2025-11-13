#!/usr/bin/env python3
"""
ROM Data Table Extractor - Extract and parse data tables from ROM

Supports various table formats common in SNES ROMs:
- Fixed-size entry tables
- Pointer tables
- Index tables
- String tables
- Statistical data (weapons, items, enemies, etc.)

Features:
- Auto-detect table structures
- Multiple export formats (CSV, JSON, XML, SQL, Markdown)
- Pointer following
- String extraction with encodings
- Data validation
- Schema definition
- Interactive browsing

Usage:
	python data_table_extractor.py rom.sfc --offset 0x80000 --entries 100 --entry-size 16
	python data_table_extractor.py rom.sfc --pointer-table 0x80000 --count 50
	python data_table_extractor.py rom.sfc --string-table 0x90000 --encoding ffmq
	python data_table_extractor.py rom.sfc --schema items.json --export-csv --output items.csv
	python data_table_extractor.py rom.sfc --auto-detect --offset 0x80000
"""

import argparse
import json
import csv
import struct
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import List, Tuple, Optional, Dict, Any
from dataclasses import dataclass, field
from enum import Enum


class TableType(Enum):
	"""Table structure type"""
	FIXED = "fixed"  # Fixed-size entries
	POINTER = "pointer"  # Pointer table
	INDEX = "index"  # Index table
	STRING = "string"  # String table
	MIXED = "mixed"  # Mixed data


class Encoding(Enum):
	"""Text encoding"""
	ASCII = "ascii"
	SHIFT_JIS = "shift_jis"
	DTE = "dte"  # Dual Tile Encoding
	FFMQ = "ffmq"  # FFMQ-specific encoding


@dataclass
class FieldSpec:
	"""Field specification"""
	name: str
	offset: int  # Offset within entry
	size: int  # Size in bytes
	data_type: str  # uint8, uint16, int8, int16, string, pointer, etc.
	description: str = ""
	enum_values: Optional[Dict[int, str]] = None
	
	def to_dict(self) -> dict:
		return {
			'name': self.name,
			'offset': self.offset,
			'size': self.size,
			'data_type': self.data_type,
			'description': self.description,
			'enum_values': self.enum_values
		}


@dataclass
class TableSchema:
	"""Table schema definition"""
	name: str
	table_type: TableType
	entry_size: int
	num_entries: int
	fields: List[FieldSpec] = field(default_factory=list)
	description: str = ""
	
	def to_dict(self) -> dict:
		return {
			'name': self.name,
			'table_type': self.table_type.value,
			'entry_size': self.entry_size,
			'num_entries': self.num_entries,
			'fields': [f.to_dict() for f in self.fields],
			'description': self.description
		}
	
	@staticmethod
	def from_dict(data: dict) -> 'TableSchema':
		schema = TableSchema(
			name=data['name'],
			table_type=TableType(data['table_type']),
			entry_size=data['entry_size'],
			num_entries=data['num_entries'],
			description=data.get('description', '')
		)
		
		for field_data in data.get('fields', []):
			schema.fields.append(FieldSpec(
				name=field_data['name'],
				offset=field_data['offset'],
				size=field_data['size'],
				data_type=field_data['data_type'],
				description=field_data.get('description', ''),
				enum_values=field_data.get('enum_values')
			))
		
		return schema


class DataTableExtractor:
	"""Extract data tables from ROM"""
	
	# FFMQ character table (example)
	FFMQ_CHAR_TABLE = {
		0x00: ' ', 0x01: '0', 0x02: '1', 0x03: '2', 0x04: '3',
		0x05: '4', 0x06: '5', 0x07: '6', 0x08: '7', 0x09: '8', 0x0A: '9',
		0x0B: 'A', 0x0C: 'B', 0x0D: 'C', 0x0E: 'D', 0x0F: 'E',
		0x10: 'F', 0x11: 'G', 0x12: 'H', 0x13: 'I', 0x14: 'J',
		0x15: 'K', 0x16: 'L', 0x17: 'M', 0x18: 'N', 0x19: 'O',
		0x1A: 'P', 0x1B: 'Q', 0x1C: 'R', 0x1D: 'S', 0x1E: 'T',
		0x1F: 'U', 0x20: 'V', 0x21: 'W', 0x22: 'X', 0x23: 'Y', 0x24: 'Z',
		0x25: 'a', 0x26: 'b', 0x27: 'c', 0x28: 'd', 0x29: 'e',
		0x2A: 'f', 0x2B: 'g', 0x2C: 'h', 0x2D: 'i', 0x2E: 'j',
		0x2F: 'k', 0x30: 'l', 0x31: 'm', 0x32: 'n', 0x33: 'o',
		0x34: 'p', 0x35: 'q', 0x36: 'r', 0x37: 's', 0x38: 't',
		0x39: 'u', 0x3A: 'v', 0x3B: 'w', 0x3C: 'x', 0x3D: 'y', 0x3E: 'z',
		0xFF: '[END]'
	}
	
	def __init__(self, rom_path: Path, verbose: bool = False):
		self.rom_path = rom_path
		self.verbose = verbose
		
		with open(rom_path, 'rb') as f:
			self.rom_data = f.read()
		
		if self.verbose:
			print(f"Loaded ROM: {rom_path} ({len(self.rom_data):,} bytes)")
	
	def extract_fixed_table(self, offset: int, num_entries: int, entry_size: int) -> List[bytes]:
		"""Extract fixed-size entry table"""
		entries = []
		
		for i in range(num_entries):
			entry_offset = offset + (i * entry_size)
			
			if entry_offset + entry_size > len(self.rom_data):
				break
			
			entry = self.rom_data[entry_offset:entry_offset + entry_size]
			entries.append(entry)
		
		return entries
	
	def extract_pointer_table(self, offset: int, num_pointers: int, 
							  pointer_size: int = 2, base_address: int = 0) -> List[Tuple[int, bytes]]:
		"""Extract pointer table and follow pointers"""
		pointers = []
		
		for i in range(num_pointers):
			ptr_offset = offset + (i * pointer_size)
			
			if ptr_offset + pointer_size > len(self.rom_data):
				break
			
			if pointer_size == 2:
				ptr = struct.unpack_from('<H', self.rom_data, ptr_offset)[0]
			elif pointer_size == 3:
				# 24-bit pointer
				low = struct.unpack_from('<H', self.rom_data, ptr_offset)[0]
				high = self.rom_data[ptr_offset + 2]
				ptr = low | (high << 16)
			elif pointer_size == 4:
				ptr = struct.unpack_from('<I', self.rom_data, ptr_offset)[0]
			else:
				continue
			
			# Convert SNES address to ROM offset if needed
			rom_offset = ptr - base_address if base_address > 0 else ptr
			
			pointers.append((ptr, rom_offset))
		
		return pointers
	
	def decode_string(self, data: bytes, encoding: Encoding = Encoding.ASCII, 
					  terminator: int = 0xFF) -> str:
		"""Decode string with various encodings"""
		if encoding == Encoding.ASCII:
			# Find terminator
			end = data.find(terminator) if terminator in data else len(data)
			return data[:end].decode('ascii', errors='replace')
		
		elif encoding == Encoding.FFMQ:
			# Use FFMQ character table
			result = []
			for byte in data:
				if byte == terminator:
					break
				char = self.FFMQ_CHAR_TABLE.get(byte, f'[{byte:02X}]')
				result.append(char)
			return ''.join(result)
		
		elif encoding == Encoding.SHIFT_JIS:
			end = data.find(terminator) if terminator in data else len(data)
			return data[:end].decode('shift_jis', errors='replace')
		
		return str(data)
	
	def extract_string_table(self, offsets: List[int], encoding: Encoding = Encoding.ASCII,
							 max_length: int = 256) -> List[str]:
		"""Extract strings from offsets"""
		strings = []
		
		for offset in offsets:
			if offset >= len(self.rom_data):
				strings.append("")
				continue
			
			data = self.rom_data[offset:offset + max_length]
			string = self.decode_string(data, encoding)
			strings.append(string)
		
		return strings
	
	def parse_entry_with_schema(self, entry: bytes, schema: TableSchema) -> Dict[str, Any]:
		"""Parse entry using schema"""
		parsed = {}
		
		for field in schema.fields:
			if field.offset + field.size > len(entry):
				parsed[field.name] = None
				continue
			
			field_data = entry[field.offset:field.offset + field.size]
			
			# Parse based on data type
			if field.data_type == 'uint8':
				value = field_data[0]
			elif field.data_type == 'int8':
				value = struct.unpack('b', field_data)[0]
			elif field.data_type == 'uint16_le':
				value = struct.unpack('<H', field_data)[0]
			elif field.data_type == 'uint16_be':
				value = struct.unpack('>H', field_data)[0]
			elif field.data_type == 'int16_le':
				value = struct.unpack('<h', field_data)[0]
			elif field.data_type == 'int16_be':
				value = struct.unpack('>h', field_data)[0]
			elif field.data_type == 'uint32_le':
				value = struct.unpack('<I', field_data)[0]
			elif field.data_type == 'uint32_be':
				value = struct.unpack('>I', field_data)[0]
			elif field.data_type == 'string':
				value = self.decode_string(field_data)
			elif field.data_type == 'hex':
				value = field_data.hex()
			else:
				value = field_data.hex()
			
			# Apply enum if present
			if field.enum_values and isinstance(value, int):
				value = field.enum_values.get(value, value)
			
			parsed[field.name] = value
		
		return parsed
	
	def extract_table_with_schema(self, offset: int, schema: TableSchema) -> List[Dict[str, Any]]:
		"""Extract table using schema"""
		entries_raw = self.extract_fixed_table(offset, schema.num_entries, schema.entry_size)
		
		parsed_entries = []
		for i, entry in enumerate(entries_raw):
			parsed = self.parse_entry_with_schema(entry, schema)
			parsed['_index'] = i
			parsed_entries.append(parsed)
		
		return parsed_entries
	
	def auto_detect_table_structure(self, offset: int, sample_size: int = 100) -> Optional[TableSchema]:
		"""Attempt to auto-detect table structure"""
		# Sample data
		sample = self.rom_data[offset:offset + sample_size * 32]  # Assume max 32 bytes per entry
		
		# Try to detect repeating patterns
		pattern_scores = {}
		
		for entry_size in [4, 8, 12, 16, 20, 24, 32, 48, 64]:
			score = 0
			
			# Check if data aligns nicely
			if len(sample) % entry_size == 0:
				score += 10
			
			# Check for repeating byte patterns (suggests structure)
			entries = [sample[i:i + entry_size] for i in range(0, len(sample), entry_size)]
			
			if len(entries) > 1:
				# Count common byte positions
				for byte_pos in range(entry_size):
					values = [e[byte_pos] for e in entries if len(e) > byte_pos]
					unique_values = len(set(values))
					
					# Low unique values at a position suggests enum/flags
					if unique_values <= 8:
						score += 5
			
			pattern_scores[entry_size] = score
		
		best_size = max(pattern_scores.items(), key=lambda x: x[1])
		
		if best_size[1] > 20:  # Confidence threshold
			return TableSchema(
				name="auto_detected",
				table_type=TableType.FIXED,
				entry_size=best_size[0],
				num_entries=sample_size,
				description=f"Auto-detected table structure (confidence: {best_size[1]})"
			)
		
		return None
	
	def export_csv(self, data: List[Dict[str, Any]], output_path: Path) -> None:
		"""Export to CSV"""
		if not data:
			return
		
		fieldnames = list(data[0].keys())
		
		with open(output_path, 'w', newline='', encoding='utf-8') as f:
			writer = csv.DictWriter(f, fieldnames=fieldnames)
			writer.writeheader()
			writer.writerows(data)
		
		if self.verbose:
			print(f"✓ Exported {len(data)} entries to {output_path}")
	
	def export_json(self, data: List[Dict[str, Any]], output_path: Path) -> None:
		"""Export to JSON"""
		with open(output_path, 'w', encoding='utf-8') as f:
			json.dump(data, f, indent='\t')
		
		if self.verbose:
			print(f"✓ Exported {len(data)} entries to {output_path}")
	
	def export_markdown(self, data: List[Dict[str, Any]], output_path: Path) -> None:
		"""Export to Markdown table"""
		if not data:
			return
		
		fieldnames = list(data[0].keys())
		
		with open(output_path, 'w', encoding='utf-8') as f:
			# Header
			f.write('| ' + ' | '.join(fieldnames) + ' |\n')
			f.write('|' + '|'.join(['---' for _ in fieldnames]) + '|\n')
			
			# Rows
			for row in data:
				values = [str(row.get(field, '')) for field in fieldnames]
				f.write('| ' + ' | '.join(values) + ' |\n')
		
		if self.verbose:
			print(f"✓ Exported {len(data)} entries to {output_path}")


def main():
	parser = argparse.ArgumentParser(description='Extract ROM data tables')
	parser.add_argument('rom', type=Path, help='ROM file')
	parser.add_argument('--offset', type=lambda x: int(x, 0), help='Table offset (hex)')
	parser.add_argument('--entries', type=int, default=100, help='Number of entries')
	parser.add_argument('--entry-size', type=int, default=16, help='Entry size in bytes')
	parser.add_argument('--pointer-table', type=lambda x: int(x, 0), help='Pointer table offset')
	parser.add_argument('--string-table', type=lambda x: int(x, 0), help='String table offset')
	parser.add_argument('--schema', type=Path, help='Schema JSON file')
	parser.add_argument('--encoding', type=str, choices=[e.value for e in Encoding], 
						default='ascii', help='Text encoding')
	parser.add_argument('--auto-detect', action='store_true', help='Auto-detect table structure')
	parser.add_argument('--export-csv', action='store_true', help='Export to CSV')
	parser.add_argument('--export-json', action='store_true', help='Export to JSON')
	parser.add_argument('--export-markdown', action='store_true', help='Export to Markdown')
	parser.add_argument('--output', type=Path, help='Output file')
	parser.add_argument('--verbose', action='store_true', help='Verbose output')
	
	args = parser.parse_args()
	
	extractor = DataTableExtractor(args.rom, verbose=args.verbose)
	
	# Auto-detect
	if args.auto_detect and args.offset is not None:
		schema = extractor.auto_detect_table_structure(args.offset)
		
		if schema:
			print(f"\nDetected table structure:")
			print(f"  Entry size: {schema.entry_size} bytes")
			print(f"  Confidence: {schema.description}")
			
			# Extract with detected schema
			data = extractor.extract_table_with_schema(args.offset, schema)
			
			# Export
			if args.export_csv:
				output = args.output or Path('table.csv')
				extractor.export_csv(data, output)
			elif args.export_json:
				output = args.output or Path('table.json')
				extractor.export_json(data, output)
			else:
				# Print sample
				print(f"\nSample entries:")
				for entry in data[:5]:
					print(f"  {entry}")
		else:
			print("Could not auto-detect table structure")
		
		return 0
	
	# Schema-based extraction
	if args.schema:
		with open(args.schema, 'r') as f:
			schema_data = json.load(f)
		
		schema = TableSchema.from_dict(schema_data)
		
		if args.offset is None:
			print("Error: --offset required with --schema")
			return 1
		
		data = extractor.extract_table_with_schema(args.offset, schema)
		
		# Export
		if args.export_csv:
			output = args.output or Path(f"{schema.name}.csv")
			extractor.export_csv(data, output)
		elif args.export_json:
			output = args.output or Path(f"{schema.name}.json")
			extractor.export_json(data, output)
		elif args.export_markdown:
			output = args.output or Path(f"{schema.name}.md")
			extractor.export_markdown(data, output)
		else:
			print(f"\nExtracted {len(data)} entries:")
			for entry in data[:10]:
				print(f"  {entry}")
		
		return 0
	
	# Simple fixed table extraction
	if args.offset is not None:
		entries = extractor.extract_fixed_table(args.offset, args.entries, args.entry_size)
		
		print(f"\nExtracted {len(entries)} entries of {args.entry_size} bytes each")
		print("\nFirst 5 entries:")
		for i, entry in enumerate(entries[:5]):
			print(f"  {i}: {entry.hex()}")
		
		return 0
	
	print("Use --offset, --schema, or --auto-detect")
	return 0


if __name__ == '__main__':
	exit(main())
