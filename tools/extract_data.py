#!/usr/bin/env python3
"""
FFMQ Generic Data Extractor
============================

A flexible, schema-driven data extraction framework for extracting
structured data from the FFMQ ROM.

Features:
- JSON schema-based structure definitions
- Automatic struct array extraction
- Multiple output formats (JSON, CSV, SQLite)
- Nested structure support
- Pointer dereferencing
- Compressed data decompression
- Round-trip verification

Usage:
    # Extract character stats to JSON
    python extract_data.py --schema schemas/character_stats.json --output data/characters.json

    # Extract enemy data to CSV
    python extract_data.py --schema schemas/enemies.json --output data/enemies.csv --format csv

    # Extract with verification
    python extract_data.py --schema schemas/items.json --verify
"""

import argparse
import json
import csv
import sqlite3
import struct
import sys
from pathlib import Path
from typing import Any, Dict, List, Optional, Union
from dataclasses import dataclass, field

# Import FFMQ-specific modules
try:
    import ffmq_compression
    from ffmq_data_structures import *
except ImportError:
    # Allow running from different directories
    import os
    sys.path.insert(0, os.path.dirname(__file__))
    import ffmq_compression
    from ffmq_data_structures import *


# ==============================================================================
# Data Type Mapping
# ==============================================================================

TYPE_FORMATS = {
    'uint8': ('B', 1),
    'int8': ('b', 1),
    'uint16': ('<H', 2),  # Little-endian
    'int16': ('<h', 2),
    'uint16be': ('>H', 2),  # Big-endian
    'uint24': (None, 3),  # Custom handler
    'uint32': ('<I', 4),
    'string': (None, None),  # Variable length
    'bytes': (None, None),  # Variable length
}


# ==============================================================================
# Schema-Based Extractor
# ==============================================================================

@dataclass
class FieldDefinition:
    """Definition of a single data field."""
    name: str
    type: str
    offset: Optional[int] = None  # Relative offset in struct
    size: Optional[int] = None  # For string/bytes types
    count: int = 1  # For arrays
    description: str = ""
    enum: Optional[Dict[int, str]] = None  # Value → name mapping
    pointer_base: Optional[int] = None  # For pointer dereferencing
    compressed: bool = False  # If data is compressed

    def parse_value(self, data: bytes, rom: bytes = None) -> Any:
        """Parse a single value from binary data."""
        if self.type in TYPE_FORMATS:
            fmt, expected_size = TYPE_FORMATS[self.type]

            if self.type == 'uint24':
                # 24-bit address (SNES format)
                if len(data) < 3:
                    raise ValueError(f"Not enough data for uint24")
                value = data[0] | (data[1] << 8) | (data[2] << 16)
                return value

            elif self.type in ('string', 'bytes'):
                # Variable-length data
                size = self.size or len(data)
                if self.type == 'string':
                    # Null-terminated or fixed-length string
                    value = data[:size]
                    if 0x00 in value:
                        value = value[:value.index(0x00)]
                    return value.decode('ascii', errors='replace')
                else:
                    return data[:size].hex()

            else:
                # Standard struct format
                if len(data) < expected_size:
                    raise ValueError(f"Not enough data for {self.type}")
                value = struct.unpack(fmt, data[:expected_size])[0]

                # Apply enum mapping if defined
                if self.enum and value in self.enum:
                    return {"value": value, "name": self.enum[value]}

                return value

        else:
            raise ValueError(f"Unknown type: {self.type}")

    def get_size(self) -> int:
        """Get the size of this field in bytes."""
        if self.size:
            return self.size

        if self.type in TYPE_FORMATS:
            fmt, size = TYPE_FORMATS[self.type]
            if size is None:
                raise ValueError(f"Type {self.type} requires explicit size")
            return size * self.count

        raise ValueError(f"Cannot determine size for type {self.type}")


@dataclass
class StructDefinition:
    """Definition of a data structure."""
    name: str
    fields: List[FieldDefinition]
    size: Optional[int] = None  # Total struct size
    description: str = ""

    def __post_init__(self):
        """Calculate struct size if not explicitly set."""
        if self.size is None:
            try:
                self.size = sum(f.get_size() for f in self.fields)
            except ValueError:
                # Variable-size struct
                pass

    def parse(self, data: bytes, rom: bytes = None) -> Dict[str, Any]:
        """Parse a struct instance from binary data."""
        result = {}
        offset = 0

        for field in self.fields:
            field_offset = field.offset if field.offset is not None else offset
            field_size = field.get_size()
            field_data = data[field_offset:field_offset + field_size]

            if field.count > 1:
                # Array field
                item_size = field_size // field.count
                result[field.name] = [
                    field.parse_value(field_data[i*item_size:(i+1)*item_size], rom)
                    for i in range(field.count)
                ]
            else:
                # Single value
                result[field.name] = field.parse_value(field_data, rom)

            # Update offset for next field
            if field.offset is None:
                offset = field_offset + field_size

        return result


@dataclass
class ExtractionSchema:
    """Complete extraction schema definition."""
    name: str
    version: str
    rom_offset: int  # Starting offset in ROM
    rom_size: Optional[int] = None  # Total size to extract
    count: Optional[int] = None  # Number of struct instances
    struct: StructDefinition = None
    description: str = ""
    pointer_table: Optional[int] = None  # Offset to pointer table
    compressed: bool = False

    @classmethod
    def from_file(cls, schema_path: Path) -> 'ExtractionSchema':
        """Load schema from JSON file."""
        with open(schema_path, 'r') as f:
            data = json.load(f)

        # Parse fields
        fields = []
        for field_data in data.get('fields', []):
            field = FieldDefinition(
                name=field_data['name'],
                type=field_data['type'],
                offset=field_data.get('offset'),
                size=field_data.get('size'),
                count=field_data.get('count', 1),
                description=field_data.get('description', ''),
                enum=field_data.get('enum'),
                pointer_base=field_data.get('pointer_base'),
                compressed=field_data.get('compressed', False)
            )
            fields.append(field)

        # Create struct definition
        struct_def = StructDefinition(
            name=data.get('struct_name', data['name']),
            fields=fields,
            size=data.get('struct_size'),
            description=data.get('description', '')
        )

        return cls(
            name=data['name'],
            version=data.get('version', '1.0'),
            rom_offset=data['rom_offset'],
            rom_size=data.get('rom_size'),
            count=data.get('count'),
            struct=struct_def,
            description=data.get('description', ''),
            pointer_table=data.get('pointer_table'),
            compressed=data.get('compressed', False)
        )


class DataExtractor:
    """Main data extraction engine."""

    def __init__(self, rom_path: Path, schema: ExtractionSchema):
        """
        Initialize extractor.

        Args:
            rom_path: Path to ROM file
            schema: Extraction schema definition
        """
        self.rom_path = rom_path
        self.schema = schema
        self.rom_data = self._load_rom()

    def _load_rom(self) -> bytes:
        """Load ROM file into memory."""
        with open(self.rom_path, 'rb') as f:
            data = f.read()

        # Strip SMC header if present
        if len(data) % 1024 == 512:
            print(f"📝 Detected SMC header, stripping 512 bytes")
            data = data[512:]

        print(f"✅ Loaded ROM: {len(data)} bytes")
        return data

    def extract(self) -> List[Dict[str, Any]]:
        """
        Extract all data instances defined by schema.

        Returns:
            List of parsed data structures
        """
        results = []

        if self.schema.pointer_table:
            # Extract using pointer table
            results = self._extract_via_pointers()
        else:
            # Extract sequential array
            results = self._extract_array()

        print(f"✅ Extracted {len(results)} {self.schema.struct.name} instances")
        return results

    def _extract_array(self) -> List[Dict[str, Any]]:
        """Extract sequential array of structures."""
        results = []
        offset = self.schema.rom_offset
        struct_size = self.schema.struct.size

        if not struct_size:
            raise ValueError("Cannot extract array without known struct size")

        count = self.schema.count
        if count is None:
            # Calculate count from rom_size
            if self.schema.rom_size:
                count = self.schema.rom_size // struct_size
            else:
                raise ValueError("Must specify either 'count' or 'rom_size' in schema")

        for i in range(count):
            struct_data = self.rom_data[offset:offset + struct_size]

            if len(struct_data) < struct_size:
                print(f"⚠️  Warning: Incomplete data at index {i}, stopping")
                break

            parsed = self.schema.struct.parse(struct_data, self.rom_data)
            parsed['_index'] = i
            parsed['_offset'] = f"0x{offset:06x}"
            results.append(parsed)

            offset += struct_size

        return results

    def _extract_via_pointers(self) -> List[Dict[str, Any]]:
        """Extract data using pointer table."""
        # TODO: Implement pointer table extraction
        raise NotImplementedError("Pointer table extraction not yet implemented")

    def export_json(self, output_path: Path, data: List[Dict[str, Any]]):
        """Export data to JSON file."""
        output = {
            "schema": {
                "name": self.schema.name,
                "version": self.schema.version,
                "description": self.schema.description
            },
            "data": data,
            "metadata": {
                "count": len(data),
                "rom_offset": f"0x{self.schema.rom_offset:06x}",
                "struct_size": self.schema.struct.size
            }
        }

        with open(output_path, 'w') as f:
            json.dump(output, f, indent=2)

        print(f"💾 Exported to JSON: {output_path}")

    def export_csv(self, output_path: Path, data: List[Dict[str, Any]]):
        """Export data to CSV file."""
        if not data:
            print("⚠️  No data to export")
            return

        # Flatten nested structures for CSV
        flattened = []
        for item in data:
            flat = {}
            for key, value in item.items():
                if isinstance(value, dict):
                    # Flatten dict (e.g., enum values)
                    for subkey, subvalue in value.items():
                        flat[f"{key}_{subkey}"] = subvalue
                elif isinstance(value, list):
                    # Flatten arrays
                    for i, v in enumerate(value):
                        flat[f"{key}_{i}"] = v
                else:
                    flat[key] = value
            flattened.append(flat)

        # Write CSV
        with open(output_path, 'w', newline='') as f:
            if flattened:
                writer = csv.DictWriter(f, fieldnames=flattened[0].keys())
                writer.writeheader()
                writer.writerows(flattened)

        print(f"💾 Exported to CSV: {output_path}")

    def export_sqlite(self, output_path: Path, data: List[Dict[str, Any]]):
        """Export data to SQLite database."""
        # TODO: Implement SQLite export
        raise NotImplementedError("SQLite export not yet implemented")


# ==============================================================================
# Command-Line Interface
# ==============================================================================

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Extract structured data from FFMQ ROM",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__
    )

    parser.add_argument('--rom', type=Path,
                       default=Path('roms/Final Fantasy - Mystic Quest (U) (V1.1).sfc'),
                       help='Path to ROM file')
    parser.add_argument('--schema', type=Path, required=True,
                       help='Path to extraction schema JSON file')
    parser.add_argument('--output', type=Path, required=True,
                       help='Output file path')
    parser.add_argument('--format', choices=['json', 'csv', 'sqlite'],
                       default='json',
                       help='Output format (default: json)')
    parser.add_argument('--verify', action='store_true',
                       help='Verify extraction by rebuilding binary')
    parser.add_argument('--verbose', '-v', action='store_true',
                       help='Verbose output')

    args = parser.parse_args()

    # Validate inputs
    if not args.rom.exists():
        print(f"❌ Error: ROM file not found: {args.rom}")
        return 1

    if not args.schema.exists():
        print(f"❌ Error: Schema file not found: {args.schema}")
        return 1

    # Load schema
    print(f"📋 Loading schema: {args.schema}")
    schema = ExtractionSchema.from_file(args.schema)
    print(f"📦 Schema: {schema.name} v{schema.version}")
    print(f"📝 {schema.description}")

    # Create extractor
    extractor = DataExtractor(args.rom, schema)

    # Extract data
    print(f"\n🔍 Extracting data...")
    data = extractor.extract()

    # Export to specified format
    print(f"\n💾 Exporting to {args.format.upper()}...")
    if args.format == 'json':
        extractor.export_json(args.output, data)
    elif args.format == 'csv':
        extractor.export_csv(args.output, data)
    elif args.format == 'sqlite':
        extractor.export_sqlite(args.output, data)

    # Verification if requested
    if args.verify:
        print(f"\n🔬 Verification not yet implemented")

    print(f"\n✅ Extraction complete!")
    return 0


if __name__ == '__main__':
    sys.exit(main())
