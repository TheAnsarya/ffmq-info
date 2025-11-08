# ROM Operations Tools

This directory contains tools for direct ROM manipulation, analysis, and validation.

## Core ROM Tools

### ROM Comparison
- **rom_compare.py** - Compare two ROMs byte-by-byte
  - Detailed diff output
  - Highlights changed regions
  - Identifies shifted data
  - Visual comparison
  - Usage: `python tools/rom-operations/rom_compare.py <rom1.smc> <rom2.smc> [--output diff.txt]`

- **rom_diff.py** - Advanced ROM diffing
  - Semantic diff (understands data structures)
  - Bank-by-bank comparison
  - Change categorization
  - Diff export (JSON/HTML)
  - Usage: `python tools/rom-operations/rom_diff.py <rom1.smc> <rom2.smc> [--format html]`

### ROM Extraction
- **rom_extractor.py** - Extract data from ROM
  - Extract arbitrary address ranges
  - Multiple format support (binary, hex, asm)
  - Batch extraction
  - Metadata generation
  - Usage: `python tools/rom-operations/rom_extractor.py --rom <file.smc> --address <hex> --length <n> [--format bin|hex|asm]`

### ROM Integrity
- **rom_integrity.py** - Validate ROM integrity
  - Checksum validation
  - Header verification
  - Structure checking
  - Corruption detection
  - Usage: `python tools/rom-operations/rom_integrity.py <rom.smc> [--fix-checksums]`

- **check_rom_data.py** - Check specific ROM data
  - Validate data structures
  - Check pointer validity
  - Verify data ranges
  - Report inconsistencies
  - Usage: `python tools/rom-operations/check_rom_data.py <rom.smc> --type <enemies|items|spells>`

### ROM Setup
- **setup_rom.py** - Initial ROM setup
  - Extracts header information
  - Creates directory structure
  - Generates config files
  - Sets up build environment
  - Usage: `python tools/rom-operations/setup_rom.py <rom.smc> --project-dir <dir>`

### Integration
- **mesen_integration.py** - Mesen emulator integration
  - Launch ROM in Mesen
  - Set breakpoints
  - Export traces
  - Debug integration
  - Usage: `python tools/rom-operations/mesen_integration.py --rom <file.smc> [--breakpoint <addr>]`

## FFMQ-Specific Tools

### Compression
- **ffmq_compression.py** ⭐ - FFMQ compression/decompression
  - Decompress FFMQ compressed data
  - Compress data for ROM
  - Multiple compression formats
  - Optimization
  - Usage: 
    ```python
    from tools.rom_operations.ffmq_compression import decompress, compress
    data = decompress(compressed_bytes)
    compressed = compress(data, format='lz77')
    ```

### Data Structures
- **ffmq_data_structures.py** ⭐ - FFMQ data structure definitions
  - Enemy data format
  - Item data format
  - Spell data format
  - Map data format
  - Battle data format
  - Usage: Import as module for data parsing

## Common Workflows

### Compare ROM Versions
```bash
# Basic comparison
python tools/rom-operations/rom_compare.py roms/v1.0.smc roms/v1.1.smc

# Detailed diff with HTML output
python tools/rom-operations/rom_diff.py roms/v1.0.smc roms/v1.1.smc --format html --output rom_diff.html

# Bank-specific comparison
python tools/rom-operations/rom_diff.py roms/v1.0.smc roms/v1.1.smc --bank 02 --output bank02_diff.txt
```

### Extract ROM Data
```bash
# Extract binary data
python tools/rom-operations/rom_extractor.py --rom original.smc --address 0x1A0000 --length 256 --format bin --output enemy_data.bin

# Extract as hex dump
python tools/rom-operations/rom_extractor.py --rom original.smc --address 0x0C8000 --length 1024 --format hex

# Extract multiple ranges
python tools/rom-operations/rom_extractor.py --rom original.smc --ranges ranges.json --output extracted/
```

### Validate ROM
```bash
# Basic integrity check
python tools/rom-operations/rom_integrity.py original.smc

# Fix checksums
python tools/rom-operations/rom_integrity.py modified.smc --fix-checksums

# Validate specific data
python tools/rom-operations/check_rom_data.py original.smc --type enemies --verbose
python tools/rom-operations/check_rom_data.py original.smc --type all --output validation_report.txt
```

### Set Up New Project
```bash
# Initialize from ROM
python tools/rom-operations/setup_rom.py original.smc --project-dir ffmq-project/

# This creates:
# ffmq-project/
#   roms/original.smc
#   src/
#   build/
#   data/
#   docs/
#   config.json
```

### Emulator Integration
```bash
# Launch in Mesen
python tools/rom-operations/mesen_integration.py --rom build/ffmq.smc

# Launch with breakpoint
python tools/rom-operations/mesen_integration.py --rom build/ffmq.smc --breakpoint 0x8000

# Export trace log
python tools/rom-operations/mesen_integration.py --rom build/ffmq.smc --trace --output trace.log
```

### Work with Compressed Data
```python
# Decompress FFMQ data
from tools.rom_operations.ffmq_compression import decompress, compress

# Read compressed data from ROM
with open('original.smc', 'rb') as f:
    f.seek(0x0C8000)
    compressed = f.read(2048)

# Decompress
decompressed = decompress(compressed)

# Modify data
# ... modify decompressed data ...

# Recompress
recompressed = compress(decompressed)

# Write back to ROM
with open('modified.smc', 'r+b') as f:
    f.seek(0x0C8000)
    f.write(recompressed)
```

### Parse FFMQ Data Structures
```python
from tools.rom_operations.ffmq_data_structures import EnemyData, ItemData, SpellData

# Parse enemy data
with open('original.smc', 'rb') as f:
    f.seek(0x1A0000)
    enemy_bytes = f.read(32)  # Enemy data is 32 bytes

enemy = EnemyData.parse(enemy_bytes)
print(f"Enemy: {enemy.name}")
print(f"HP: {enemy.hp}")
print(f"Attack: {enemy.attack}")

# Modify and rebuild
enemy.hp = 9999
modified_bytes = enemy.build()
```

## ROM Mapping

### SNES Memory Mapping
```
LoROM Mapping (FFMQ uses this):
$00-$3F:$8000-$FFFF → ROM $00000-$1FFFF (Bank 0)
$40-$7F:$8000-$FFFF → ROM $20000-$3FFFF (Bank 1)
$80-$BF:$8000-$FFFF → ROM $00000-$1FFFF (Bank 0 mirror)
$C0-$FF:$8000-$FFFF → ROM $20000-$3FFFF (Bank 1 mirror)

HiROM Mapping (not used by FFMQ):
$C0-$FF:$0000-$FFFF → ROM $00000-$3FFFF
```

### FFMQ ROM Layout
```
$00000-$007FF : SNES Header (internal)
$00800-$0FFFF : Bank $00 - Core engine
$10000-$1FFFF : Bank $01 - Graphics/DMA
$20000-$2FFFF : Bank $02 - Game logic
$30000-$3FFFF : Bank $03 - Battle system
...
$C0000-$CFFFF : Bank $0C - Graphics data
...
$1A0000-$1AFFFF : Bank $1A - Enemy data
```

See `docs/technical/ROM_MAP.md` for complete layout.

## ROM Header Format

### Internal ROM Header (at $00:FFB0)
```
Offset  Size  Description
+$00    21    Game title (ASCII, space-padded)
+$15    1     ROM makeup byte
+$16    1     ROM type
+$17    1     ROM size
+$18    1     RAM size
+$19    1     Country code
+$1A    1     Developer ID
+$1B    1     Version number
+$1C    2     Checksum complement
+$1E    2     Checksum
```

### Reading ROM Header
```python
from tools.rom_operations.rom_integrity import read_header

with open('original.smc', 'rb') as f:
    header = read_header(f)
    print(f"Title: {header['title']}")
    print(f"ROM Size: {header['rom_size']} KB")
    print(f"Checksum: {header['checksum']:04X}")
```

## Checksum Calculation

### SNES Checksum Algorithm
```python
def calculate_checksum(rom_data):
    """Calculate SNES ROM checksum"""
    checksum = 0
    for byte in rom_data:
        checksum = (checksum + byte) & 0xFFFF
    return checksum

def calculate_complement(checksum):
    """Calculate checksum complement"""
    return checksum ^ 0xFFFF
```

### Update Checksums
```bash
# Fix checksums after ROM modification
python tools/rom-operations/rom_integrity.py modified.smc --fix-checksums
```

## Compression Formats

### FFMQ Compression Types

**LZ77 Variant**
- Used for graphics data
- Sliding window compression
- Lookback references

**RLE (Run-Length Encoding)**
- Used for solid color areas
- Simple repeated byte compression

**Hybrid**
- Combines LZ77 and RLE
- Used for map data

See `ffmq_compression.py` for implementation details.

## Dependencies

- Python 3.7+
- **struct** (standard library) - Binary data handling
- **mesen** (optional) - For emulator integration
- ROM access (read/write binary files)

## See Also

- **tools/build/** - For building ROMs from source
- **tools/data-extraction/** - For extracting specific data types
- **tools/validation/** - For validating ROM data
- **docs/technical/ROM_MAP.md** - Complete ROM memory map
- **docs/technical/DATA_FORMATS.md** - Data structure specifications

## Tips and Best Practices

### ROM Manipulation Safety
- **Always** work on copies, never original ROM
- Validate checksums after modifications
- Test in emulator before committing changes
- Keep backups of working versions
- Version control modified ROMs

### Data Extraction
- Extract to raw binary first
- Parse using known data structures
- Validate extracted data
- Document format assumptions
- Cross-reference with community documentation

### Comparison
- Compare against known-good version
- Document all differences
- Categorize changes (code vs data)
- Track modification history
- Generate visual diffs for review

### Compression
- Test decompression on original data first
- Verify round-trip (decompress→compress→decompress)
- Check compressed size vs original
- Optimize for size when possible
- Document compression format

## Troubleshooting

**Issue: Checksum validation fails**
- Solution: ROM may be modified, use --fix-checksums

**Issue: Decompression produces garbage**
- Solution: Verify compression format, check start address

**Issue: ROM comparison shows no changes**
- Solution: Check file paths, verify ROMs are different

**Issue: Extracted data seems corrupted**
- Solution: Verify address and length, check data format

**Issue: Mesen integration fails**
- Solution: Check Mesen installation, verify path

## Advanced Topics

### Custom Compression
Implement custom compression for space optimization:
```python
from tools.rom_operations.ffmq_compression import BaseCompressor

class CustomCompressor(BaseCompressor):
    def compress(self, data):
        # Custom compression logic
        pass
    
    def decompress(self, data):
        # Custom decompression logic
        pass
```

### ROM Patching
Apply IPS/BPS patches:
```python
from tools.rom_operations.rom_patcher import apply_patch

apply_patch('original.smc', 'hack.ips', 'patched.smc')
```

### Memory Viewer
Real-time ROM memory viewing:
```python
from tools.rom_operations.memory_viewer import MemoryViewer

viewer = MemoryViewer('build/ffmq.smc')
viewer.view_range(0x1A0000, 256, format='hex')
```

## Data Structure Reference

### Enemy Data (32 bytes)
```
Offset  Size  Description
+$00    2     HP
+$02    1     Attack
+$03    1     Defense
+$04    1     Magic
+$05    1     Speed
+$06    2     EXP
+$08    2     GP
+$0A    1     Element
+$0B    1     Weaknesses
+$0C    1     Resistances
+$0D    1     Immunities
+$0E    2     Status
+$10    8     Attack pattern
+$18    8     Drop table
```

See `ffmq_data_structures.py` for complete definitions.

## Contributing

When adding ROM operation tools:
1. Never modify original ROM without backup
2. Validate all operations
3. Handle errors gracefully
4. Document data formats
5. Add comprehensive tests
6. Support batch operations
7. Update this README

## Future Development

Planned additions:
- [ ] IPS/UPS/BPS patch support
- [ ] Real-time memory editing
- [ ] ROM expansion tools
- [ ] Bank reorganization
- [ ] Free space finder
- [ ] Automated data relocation
- [ ] ROM optimizer (remove unused data)
- [ ] Visual ROM browser
