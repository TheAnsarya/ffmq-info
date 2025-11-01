# FFMQ Extraction Schemas

This directory contains JSON schema definitions for extracting structured data from the FFMQ ROM using `tools/extract_data.py`.

## Schema Format

Each schema is a JSON file that defines:
- **Data location** in ROM (offset, size, count)
- **Structure definition** (fields, types, sizes)
- **Field metadata** (descriptions, enums, etc.)

### Example Schema

```json
{
  "name": "CharacterStats",
  "version": "1.0",
  "description": "Character starting statistics",
  "rom_offset": 997760,
  "count": 4,
  "struct_size": 9,
  "fields": [
    {
      "name": "character_id",
      "type": "uint8",
      "description": "Character identifier",
      "enum": {
        "0": "Benjamin",
        "1": "Kaeli"
      }
    },
    {
      "name": "max_hp",
      "type": "uint16",
      "description": "Maximum HP"
    }
  ]
}
```

## Supported Field Types

- `uint8` - 8-bit unsigned integer (1 byte)
- `int8` - 8-bit signed integer (1 byte)
- `uint16` - 16-bit unsigned integer, little-endian (2 bytes)
- `int16` - 16-bit signed integer, little-endian (2 bytes)
- `uint16be` - 16-bit unsigned integer, big-endian (2 bytes)
- `uint24` - 24-bit SNES address (3 bytes)
- `uint32` - 32-bit unsigned integer (4 bytes)
- `string` - Null-terminated or fixed-length ASCII string
- `bytes` - Raw byte array (hex output)

## Field Properties

- `name` - Field identifier (required)
- `type` - Data type (required)
- `offset` - Relative byte offset in struct (optional, auto-calculated)
- `size` - Size in bytes for variable-length types (optional)
- `count` - Array size (optional, default: 1)
- `description` - Human-readable description (optional)
- `enum` - Value-to-name mapping for enums (optional)
- `pointer_base` - Base address for pointer dereferencing (optional)
- `compressed` - Whether data is compressed (optional)

## Schema Properties

- `name` - Schema identifier (required)
- `version` - Schema version (optional, default: "1.0")
- `description` - Human-readable description (optional)
- `rom_offset` - Starting byte offset in ROM (required)
- `rom_size` - Total size of data region (optional)
- `count` - Number of struct instances (required if rom_size not specified)
- `struct_name` - Structure type name (optional, defaults to schema name)
- `struct_size` - Size of each struct in bytes (optional, auto-calculated)
- `pointer_table` - Offset to pointer table for indirect extraction (optional)
- `compressed` - Whether data is compressed (optional)

## Usage

Extract data using the schema:

```bash
# Extract to JSON
python tools/extract_data.py \
  --schema schemas/character_start_stats.json \
  --output data/characters.json

# Extract to CSV
python tools/extract_data.py \
  --schema schemas/bank06_metatiles.json \
  --output data/metatiles.csv \
  --format csv

# Verify extraction
python tools/extract_data.py \
  --schema schemas/character_start_stats.json \
  --output data/characters.json \
  --verify
```

## Available Schemas

- `character_start_stats.json` - Starting stats for the 4 playable characters
- `bank06_metatiles.json` - 256 metatiles (16x16 tile definitions)

## Creating New Schemas

1. Identify the data structure in the ROM
2. Determine the offset and size
3. Define the structure fields
4. Test extraction with `--verbose` flag
5. Verify output format matches expectations

## ROM Offsets

All offsets are for the headerless ROM (512-byte SMC header stripped).
If using a ROM with header, offsets will be automatically adjusted.

### Common Data Locations

- Character stats: `0x0f3a00` (997760)
- Metatiles: `0x068000` (425984)
- Enemy stats: TBD
- Item data: TBD
- Spell data: TBD
