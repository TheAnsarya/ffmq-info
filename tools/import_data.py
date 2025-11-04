#!/usr/bin/env python3
"""
Import game data from JSON/CSV back to binary ROM format.

This tool converts extracted game data (characters, enemies, items, etc.)
back to binary structs for ROM insertion.

Features:
    - JSON/CSV → binary struct conversion
    - Text compression (DTE encoding)
    - Data validation against schemas
    - Pointer handling and nested structures
    - Size validation
"""

import os
import sys
import json
import csv
import struct
from pathlib import Path
from typing import List, Dict, Any, Optional, Tuple
from dataclasses import dataclass

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))


@dataclass
class BinaryStruct:
    """Generic binary data structure."""
    name: str
    data: bytes
    size: int

    def validate_size(self, expected_size: int) -> bool:
        """Validate struct size matches expected size."""
        if len(self.data) != expected_size:
            print(f"ERROR: {self.name} size mismatch: "
                  f"got {len(self.data)}, expected {expected_size}")
            return False
        return True


class DataImporter:
    """Import game data from JSON/CSV to binary format."""

    def __init__(self, schema_dir: Optional[Path] = None):
        """Initialize data importer with optional schema directory."""
        self.schema_dir = schema_dir or Path("data/schemas")
        self.schemas = {}
        if self.schema_dir.exists():
            self._load_schemas()

    def _load_schemas(self):
        """Load JSON schemas for validation."""
        for schema_file in self.schema_dir.glob("*.json"):
            try:
                with open(schema_file, 'r') as f:
                    schema = json.load(f)
                    name = schema_file.stem.replace('_schema', '')
                    self.schemas[name] = schema
                    print(f"[OK] Loaded schema: {name}")
            except Exception as e:
                print(f"[WARN] Failed to load schema {schema_file}: {e}")

    def validate_against_schema(self, data: Dict[str, Any],
                                schema_name: str) -> bool:
        """
        Validate data against JSON schema.

        Args:
            data: Data dictionary to validate
            schema_name: Name of schema (without _schema.json suffix)

        Returns:
            True if valid
        """
        if schema_name not in self.schemas:
            print(f"[WARN] No schema found for '{schema_name}', skipping validation")
            return True

        # Basic validation (can be enhanced with jsonschema library)
        schema = self.schemas[schema_name]
        required_fields = schema.get('required', [])

        for field in required_fields:
            if field not in data:
                print(f"ERROR: Missing required field '{field}' in {schema_name}")
                return False

        print(f"[OK] Schema validation passed: {schema_name}")
        return True

    def json_to_character_binary(self, json_path: Path) -> BinaryStruct:
        """
        Convert character JSON to binary format.

        Character struct format (32 bytes):
        - 00: Character ID
        - 01: Initial level
        - 02-03: Initial HP (word, little-endian)
        - 04: Initial STR
        - 05: Initial DEF
        - 06: Initial SPD
        - 07: Initial MAG
        - 08-09: HP growth rate
        - 0A: STR growth rate
        - 0B: DEF growth rate
        - 0C: SPD growth rate
        - 0D: MAG growth rate
        - 0E-1F: Reserved/equipment slots/etc.
        """
        with open(json_path, 'r') as f:
            data = json.load(f)

        if not self.validate_against_schema(data, 'character'):
            raise ValueError("Character data failed schema validation")

        struct_data = bytearray(32)
        struct_data[0x00] = data.get('id', 0)
        struct_data[0x01] = data.get('initial_level', 1)

        # HP (word)
        hp = data.get('initial_hp', 100)
        struct_data[0x02] = hp & 0xFF
        struct_data[0x03] = (hp >> 8) & 0xFF

        struct_data[0x04] = data.get('initial_str', 10)
        struct_data[0x05] = data.get('initial_def', 10)
        struct_data[0x06] = data.get('initial_spd', 10)
        struct_data[0x07] = data.get('initial_mag', 10)

        # Growth rates (words)
        hp_growth = data.get('hp_growth', 10)
        struct_data[0x08] = hp_growth & 0xFF
        struct_data[0x09] = (hp_growth >> 8) & 0xFF

        struct_data[0x0A] = data.get('str_growth', 1)
        struct_data[0x0B] = data.get('def_growth', 1)
        struct_data[0x0C] = data.get('spd_growth', 1)
        struct_data[0x0D] = data.get('mag_growth', 1)

        return BinaryStruct(
            name=f"character_{data.get('name', 'unknown')}",
            data=bytes(struct_data),
            size=32
        )

    def json_to_enemy_binary(self, json_path: Path) -> BinaryStruct:
        """
        Convert enemy JSON to binary format.

        Enemy struct format (64 bytes - approximate):
        - 00: Enemy ID
        - 01: Enemy type/flags
        - 02-03: HP (word)
        - 04: ATK
        - 05: DEF
        - 06: SPD
        - 07: MAG
        - 08-09: EXP reward (word)
        - 0A-0B: Gold reward (word)
        - 0C-0F: Elemental resistances
        - 10-1F: AI pointers/attack patterns
        - 20-3F: Reserved
        """
        with open(json_path, 'r') as f:
            data = json.load(f)

        if not self.validate_against_schema(data, 'enemy'):
            raise ValueError("Enemy data failed schema validation")

        struct_data = bytearray(64)
        struct_data[0x00] = data.get('id', 0)
        struct_data[0x01] = data.get('type', 0)

        # HP (word)
        hp = data.get('hp', 100)
        struct_data[0x02] = hp & 0xFF
        struct_data[0x03] = (hp >> 8) & 0xFF

        struct_data[0x04] = data.get('atk', 10)
        struct_data[0x05] = data.get('def', 10)
        struct_data[0x06] = data.get('spd', 10)
        struct_data[0x07] = data.get('mag', 10)

        # EXP (word)
        exp = data.get('exp', 0)
        struct_data[0x08] = exp & 0xFF
        struct_data[0x09] = (exp >> 8) & 0xFF

        # Gold (word)
        gold = data.get('gold', 0)
        struct_data[0x0A] = gold & 0xFF
        struct_data[0x0B] = (gold >> 8) & 0xFF

        # Elemental resistances (4 bytes)
        resistances = data.get('elemental_resistances', [0, 0, 0, 0])
        for i, res in enumerate(resistances[:4]):
            struct_data[0x0C + i] = res

        return BinaryStruct(
            name=f"enemy_{data.get('name', 'unknown')}",
            data=bytes(struct_data),
            size=64
        )

    def json_to_item_binary(self, json_path: Path) -> BinaryStruct:
        """
        Convert item JSON to binary format.

        Item struct format (16 bytes - approximate):
        - 00: Item ID
        - 01: Item type (weapon/armor/consumable)
        - 02: ATK bonus
        - 03: DEF bonus
        - 04: MAG bonus
        - 05: SPD bonus
        - 06-07: Price (word)
        - 08-09: Special effects
        - 0A-0F: Reserved
        """
        with open(json_path, 'r') as f:
            data = json.load(f)

        if not self.validate_against_schema(data, 'item'):
            raise ValueError("Item data failed schema validation")

        struct_data = bytearray(16)
        struct_data[0x00] = data.get('id', 0)
        struct_data[0x01] = data.get('type', 0)
        struct_data[0x02] = data.get('atk_bonus', 0)
        struct_data[0x03] = data.get('def_bonus', 0)
        struct_data[0x04] = data.get('mag_bonus', 0)
        struct_data[0x05] = data.get('spd_bonus', 0)

        # Price (word)
        price = data.get('price', 0)
        struct_data[0x06] = price & 0xFF
        struct_data[0x07] = (price >> 8) & 0xFF

        # Special effects (word)
        effects = data.get('special_effects', 0)
        struct_data[0x08] = effects & 0xFF
        struct_data[0x09] = (effects >> 8) & 0xFF

        return BinaryStruct(
            name=f"item_{data.get('name', 'unknown')}",
            data=bytes(struct_data),
            size=16
        )

    def csv_to_binary_table(self, csv_path: Path,
                            struct_converter: callable,
                            struct_size: int) -> bytes:
        """
        Convert CSV table to binary format.

        Args:
            csv_path: Path to CSV file
            struct_converter: Function to convert row dict to bytes
            struct_size: Expected size per struct

        Returns:
            Binary data for all rows
        """
        data = bytearray()

        with open(csv_path, 'r', encoding='utf-8') as f:
            reader = csv.DictReader(f)
            for i, row in enumerate(reader):
                try:
                    struct_data = struct_converter(row)
                    if len(struct_data) != struct_size:
                        print(f"ERROR: Row {i} size mismatch: "
                              f"{len(struct_data)} != {struct_size}")
                        continue
                    data.extend(struct_data)
                except Exception as e:
                    print(f"ERROR: Failed to convert row {i}: {e}")
                    continue

        return bytes(data)

    def compress_text_dte(self, text: str) -> bytes:
        """
        Compress text using Dual Tile Encoding (DTE).

        DTE pairs common character combinations into single bytes.
        This is a simplified implementation - actual FFMQ DTE table
        should be loaded from ROM/documentation.

        Args:
            text: Text to compress

        Returns:
            Compressed text bytes
        """
        # Simplified DTE table (real table should be loaded from ROM)
        dte_table = {
            'th': 0x80, 'he': 0x81, 'in': 0x82, 'er': 0x83,
            'an': 0x84, 're': 0x85, 'on': 0x86, 'at': 0x87,
            'en': 0x88, 'nd': 0x89, 'ti': 0x8A, 'es': 0x8B,
            'or': 0x8C, 'te': 0x8D, 'of': 0x8E, 'ed': 0x8F,
        }

        compressed = bytearray()
        i = 0
        while i < len(text):
            # Try to match 2-char pairs
            if i + 1 < len(text):
                pair = text[i:i+2].lower()
                if pair in dte_table:
                    compressed.append(dte_table[pair])
                    i += 2
                    continue

            # Single character
            compressed.append(ord(text[i]))
            i += 1

        return bytes(compressed)

    def handle_pointers(self, structs: List[BinaryStruct],
                       base_address: int = 0xC00000) -> Tuple[bytes, bytes]:
        """
        Handle pointer table generation for structs.

        Args:
            structs: List of binary structs
            base_address: Base ROM address for pointer table

        Returns:
            Tuple of (pointer_table_bytes, data_bytes)
        """
        pointers = bytearray()
        data = bytearray()

        current_offset = base_address + (len(structs) * 2)  # After pointer table

        for struct in structs:
            # Add pointer (word, little-endian)
            pointers.append(current_offset & 0xFF)
            pointers.append((current_offset >> 8) & 0xFF)

            # Add data
            data.extend(struct.data)
            current_offset += len(struct.data)

        return bytes(pointers), bytes(data)


def main():
    """Command-line interface for data import."""
    import argparse

    parser = argparse.ArgumentParser(
        description="Import game data from JSON/CSV to binary format"
    )
    parser.add_argument('input', help='Input file (JSON or CSV)')
    parser.add_argument('output', help='Output binary file')
    parser.add_argument('--type', choices=['character', 'enemy', 'item', 'text'],
                       required=True, help='Data type')
    parser.add_argument('--schema-dir', help='JSON schema directory',
                       default='data/schemas')
    parser.add_argument('--compress-text', action='store_true',
                       help='Use DTE compression for text')

    args = parser.parse_args()

    importer = DataImporter(schema_dir=Path(args.schema_dir))

    try:
        input_path = Path(args.input)

        if args.type == 'character':
            struct = importer.json_to_character_binary(input_path)
            if not struct.validate_size(32):
                return 1
            data = struct.data

        elif args.type == 'enemy':
            struct = importer.json_to_enemy_binary(input_path)
            if not struct.validate_size(64):
                return 1
            data = struct.data

        elif args.type == 'item':
            struct = importer.json_to_item_binary(input_path)
            if not struct.validate_size(16):
                return 1
            data = struct.data

        elif args.type == 'text':
            with open(input_path, 'r', encoding='utf-8') as f:
                text = f.read()

            if args.compress_text:
                data = importer.compress_text_dte(text)
                print(f"[OK] Compressed: {len(text)} -> {len(data)} bytes "
                      f"({100 * len(data) / len(text):.1f}%)")
            else:
                data = text.encode('utf-8')

        # Write output
        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, 'wb') as f:
            f.write(data)

        print(f"[OK] Saved: {output_path} ({len(data)} bytes)")
        print()
        print("Import successful!")
        return 0

    except Exception as e:
        print(f"ERROR: {e}")
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())
