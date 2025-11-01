# Data Extraction Process

Documentation for extracting game data from Final Fantasy: Mystic Quest ROM.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Extraction Workflow](#extraction-workflow)
- [Extraction Tools](#extraction-tools)
- [Data Type Extraction](#data-type-extraction)
- [Validation Process](#validation-process)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

## Overview

The data extraction process converts binary ROM data into structured JSON format for analysis, modding, and documentation.

### Extraction Goals

- **Accuracy**: Extracted data must match ROM exactly
- **Completeness**: Extract all fields, even if unknown
- **Documentation**: Document structure and usage
- **Validation**: Verify against schemas and ROM build
- **Reversibility**: Support round-trip ROM building

### Extraction Pipeline

```
ROM Binary → Extract Tool → JSON Data → Validate → Commit
							  ↓
						 Update Docs
```

## Prerequisites

### Required Tools

1. **Python 3.8+**: For extraction scripts
2. **Hex Editor**: For ROM analysis (HxD, ImHex, etc.)
3. **Mesen-S**: For debugging and memory inspection
4. **Git**: For version control
5. **JSON Schema Validator**: For data validation

### Required Files

- **ROM File**: Final Fantasy: Mystic Quest (USA) ROM
- **Disassembly**: Source code (src/ directory)
- **Schemas**: JSON schemas (data/schemas/)
- **Documentation**: System documentation (docs/)

### Python Dependencies

```bash
pip install -r requirements.txt
```

Required packages:
- `jsonschema` - JSON validation
- `pillow` - Graphics extraction
- `numpy` - Data processing

## Extraction Workflow

### Step 1: Identify Data Structure

1. **Locate in ROM**:
   - Use disassembly to find data references
   - Use Mesen-S debugger to trace data access
   - Check existing documentation (DATA_STRUCTURES.md)

2. **Determine Structure**:
   - Analyze access patterns in code
   - Identify field sizes and types
   - Document unknowns for later analysis

3. **Document Structure**:
   - Add to DATA_STRUCTURES.md
   - Include ROM addresses
   - List code references

### Step 2: Create/Update Schema

1. **Create JSON Schema** in `data/schemas/`:
   ```json
   {
	 "$schema": "http://json-schema.org/draft-07/schema#",
	 "type": "object",
	 "required": ["version", "data"],
	 "properties": {
	   "version": { "type": "string" },
	   "data": { "type": "array", "items": {...} }
	 }
   }
   ```

2. **Define Fields**:
   - Use descriptive `snake_case` names
   - Add descriptions for all fields
   - Set appropriate types and constraints
   - Include enumerations where applicable

3. **Validate Schema**:
   ```bash
   python tools/validate_schema.py data/schemas/your_schema.json
   ```

### Step 3: Extract Data

1. **Choose Extraction Method**:
   - **Manual**: Small datasets, complex structures
   - **Semi-automated**: Medium datasets with patterns
   - **Fully automated**: Large datasets with clear structure

2. **Run Extraction Tool**:
   ```bash
   python tools/extract_data.py --type enemy --output data/enemies/enemies.json
   ```

3. **Review Output**:
   - Check for missing values
   - Verify field mappings
   - Cross-reference with ROM

### Step 4: Validate Data

1. **Schema Validation**:
   ```bash
   python tools/validate_data.py data/enemies/enemies.json
   ```

2. **ROM Verification**:
   ```bash
   # Re-inject data and build ROM
   make clean
   make
   
   # Compare with original
   python tools/verify_build.py
   ```

3. **Manual Verification**:
   - Test in emulator
   - Check critical values
   - Verify calculations

### Step 5: Document and Commit

1. **Update Documentation**:
   - Update DATA_STRUCTURES.md with findings
   - Update extraction status
   - Add to data/README.md if new file type

2. **Commit Changes**:
   ```bash
   git add data/enemies/enemies.json docs/DATA_STRUCTURES.md
   git commit -m "data: Extract enemy database (100 enemies)
   
   Extracted complete enemy data including:
   - Stats (HP, speed, attack, defense)
   - AI patterns and scripts
   - Drops (EXP, GP, items)
   - Weaknesses and resistances
   
   ROM Address: $0e8000-$0e9900
   Validated against enemy_schema.json"
   ```

## Extraction Tools

### Core Extraction Tools

#### extract_data.py

Generic data extraction tool.

```bash
python tools/extract_data.py \
  --type <data_type> \
  --address <rom_address> \
  --count <entry_count> \
  --size <entry_size> \
  --output <output.json>
```

**Examples**:

```bash
# Extract enemy data
python tools/extract_data.py \
  --type enemy \
  --address 0x0E8000 \
  --count 100 \
  --size 64 \
  --output data/enemies/enemies.json

# Extract item data
python tools/extract_data.py \
  --type item \
  --address 0x0C9000 \
  --count 32 \
  --size 16 \
  --output data/items/weapons.json
```

#### extract_text.py

Extract and decompress text data.

```bash
python tools/extract_text.py \
  --bank <bank> \
  --type <dialog|menu|battle> \
  --output <output.json>
```

**Features**:
- DTE decompression
- Control code parsing
- Encoding table support
- Text statistics

#### extract_graphics.py

Extract tile and sprite graphics.

```bash
python tools/extract_graphics.py \
  --address <rom_address> \
  --size <size_bytes> \
  --bpp <1|2|4> \
  --output <output.bin|output.png>
```

**Features**:
- Multiple BPP formats
- Palette application
- PNG export
- Compression detection

#### extract_maps.py

Extract map data and tilemaps.

```bash
python tools/extract_maps.py \
  --map-id <id> \
  --output data/maps/
```

**Features**:
- Map header extraction
- Metatile extraction
- Collision data
- Event/NPC extraction

### Validation Tools

#### validate_data.py

Validate JSON data against schemas.

```bash
python tools/validate_data.py <data_file.json>
```

**Output**:
```
✓ Schema validation passed
✓ 100 entries validated
✓ No errors found
```

#### verify_build.py

Verify ROM matches original after rebuild.

```bash
python tools/verify_build.py
```

**Checks**:
- ROM size match
- CRC32 checksum
- Byte-by-byte comparison
- Known checksum regions

#### coverage_report.py

Generate extraction coverage report.

```bash
python tools/coverage_report.py --output reports/coverage.md
```

**Features**:
- Per-category progress
- Missing data identification
- Coverage visualization
- Detailed statistics

## Data Type Extraction

### Character Data Extraction

**Location**: Bank $0c, $0c8000 (4 characters × 32 bytes)

**Process**:
1. Extract 4 character entries
2. Parse stat fields (HP, speed, strength, etc.)
3. Extract growth rates
4. Map equipment and magic flags
5. Validate against character_schema.json

**Example**:
```bash
python tools/extract_data.py \
  --type character \
  --address 0x0C8000 \
  --count 4 \
  --size 32 \
  --output data/characters/characters.json
```

**Manual Verification**:
- Check Benjamin starting stats in-game
- Verify level-up stat gains
- Test equipment restrictions

### Enemy Data Extraction

**Location**: Bank $0e, $0e8000 (~100 enemies × 64 bytes)

**Process**:
1. Determine enemy count (scan for $ff terminator)
2. Extract enemy entries
3. Parse AI pattern references
4. Map element/status flags
5. Extract drop tables
6. Validate against enemy_schema.json

**Challenges**:
- Variable enemy count
- Complex AI script pointers
- Bitfield flag parsing

**Example**:
```bash
python tools/extract_data.py \
  --type enemy \
  --address 0x0E8000 \
  --count 100 \
  --size 64 \
  --output data/enemies/enemies.json
```

### Map Data Extraction

**Location**: Bank $06, $068000 (map headers), $068800 (metatiles)

**Process**:
1. Extract map headers (64 maps × 32 bytes)
2. Extract metatiles (256 metatiles × 8 bytes) ✅ DONE
3. Extract tilemap data (variable size per map)
4. Extract collision data
5. Extract events, NPCs, warps
6. Validate against map_schema.json

**Current Status**:
- ✅ Metatile structure extracted (256 entries)
- ⏳ Map headers in progress
- ⏳ Event extraction pending

**Example**:
```bash
python tools/extract_maps.py \
  --map-id 0 \
  --extract-all \
  --output data/maps/
```

### Text Data Extraction

**Location**: Bank $0d, $0d8000-$0dffff

**Process**:
1. Extract encoding table ($0d0000, 256 bytes)
2. Build DTE dictionary
3. Extract pointer table
4. Decompress text entries
5. Parse control codes
6. Validate against text_schema.json

**Challenges**:
- DTE compression
- Variable-length entries
- Control code handling

**Example**:
```bash
python tools/extract_text.py \
  --bank 0D \
  --type dialog \
  --decompress \
  --output data/text/dialog.json
```

### Graphics Data Extraction

**Location**: Banks $04-$07 (various)

**Process**:
1. Identify graphics address
2. Determine format (2bpp/4bpp)
3. Extract tile data
4. Extract associated palette
5. Export as binary + metadata JSON
6. Optionally export PNG

**Example**:
```bash
# Extract tiles
python tools/extract_graphics.py \
  --address 0x048000 \
  --size 8192 \
  --bpp 4 \
  --output data/graphics/tiles/048000-tiles.bin

# Extract palette
python tools/extract_graphics.py \
  --address 0x074000 \
  --type palette \
  --colors 16 \
  --output data/graphics/palettes/000.bin

# Generate metadata
python tools/generate_graphics_metadata.py \
  --input data/graphics/ \
  --output data/graphics/metadata.json
```

## Validation Process

### Schema Validation

All extracted data must validate against JSON schemas:

```python
import json
import jsonschema

# Load schema
with open('data/schemas/enemy_schema.json') as f:
	schema = json.load(f)

# Load data
with open('data/enemies/enemies.json') as f:
	data = json.load(f)

# Validate
try:
	jsonschema.validate(instance=data, schema=schema)
	print("✓ Validation passed")
except jsonschema.ValidationError as e:
	print(f"✗ Validation failed: {e.message}")
```

### ROM Verification

After extraction, verify ROM can be rebuilt:

```bash
# Clean build
make clean

# Build ROM
make

# Verify checksum
python tools/verify_build.py

# Expected output:
# ✓ ROM size matches: 1048576 bytes
# ✓ CRC32 matches: 0x12345678
# ✓ Byte-by-byte comparison: PASS
```

### Data Integrity Checks

Custom validation checks:

```python
# Example: Validate stat ranges
for character in data['characters']:
	assert 1 <= character['starting_level'] <= 41
	assert 0 <= character['base_stats']['hp'] <= 9999
	assert 0 <= character['base_stats']['speed'] <= 255
```

## Best Practices

### Extraction Best Practices

1. **Start Small**: Extract sample entries first
2. **Document Unknowns**: Mark unknown fields clearly
3. **Cross-Reference**: Check code that uses the data
4. **Validate Early**: Run schema validation frequently
5. **Test In-Game**: Verify critical values in emulator

### Data Quality

1. **Accuracy**: Match ROM exactly
2. **Completeness**: Extract all fields, even if unknown
3. **Consistency**: Use same naming across all files
4. **Documentation**: Comment complex structures

### Version Control

1. **Atomic Commits**: One data type per commit
2. **Descriptive Messages**: Explain what was extracted
3. **Update Docs**: Keep DATA_STRUCTURES.md current
4. **Tag Milestones**: Tag major extraction completions

## Troubleshooting

### Common Issues

**Issue**: Schema validation fails with "Additional properties not allowed"

**Solution**: Check schema for `additionalProperties: false`. Either add missing field to schema or remove from data.

---

**Issue**: Extracted data doesn't match in-game values

**Solution**:
1. Verify ROM address is correct
2. Check if data is compressed
3. Verify byte order (little-endian)
4. Check for indirection (pointer to pointer)

---

**Issue**: Build verification fails after data extraction

**Solution**:
1. Ensure extraction is read-only
2. Check if data injection code is correct
3. Verify data structures match exactly
4. Compare hex dumps of original vs rebuilt

---

**Issue**: Graphics extract as garbage

**Solution**:
1. Verify BPP format (2bpp vs 4bpp)
2. Check for compression
3. Verify ROM address alignment
4. Check if interleaved tile format

---

**Issue**: Text extraction produces gibberish

**Solution**:
1. Verify encoding table is correct
2. Check for DTE compression
3. Verify pointer calculations
4. Check for bank boundary issues

### Getting Help

1. **Check Documentation**:
   - DATA_STRUCTURES.md for structure specs
   - System docs (GRAPHICS_SYSTEM.md, etc.) for format details
   - data/README.md for data organization

2. **Use Debugger**:
   - Mesen-S debugger to trace code
   - Memory viewer to inspect runtime values
   - Breakpoints on data access routines

3. **Compare with Disassembly**:
   - Check src/ files for structure definitions
   - Look for equates and constants
   - Find code that reads/writes the data

4. **Ask Community**:
   - ROM hacking forums
   - SNES dev communities
   - Project issues/discussions

## Related Documentation

- **docs/DATA_STRUCTURES.md**: Complete data structure reference
- **data/README.md**: Data organization and usage
- **docs/TOOLS.md**: Tool documentation
- **docs/MODDING_GUIDE.md**: Using extracted data for mods
- **data/schemas/**: JSON Schema definitions

---

*Keep this document updated as new extraction methods and tools are developed.*
