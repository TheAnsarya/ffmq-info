# Battle Data Pipeline - Quick Reference

## Overview

Complete pipeline for extracting, modifying, and rebuilding battle data (enemies, attacks, attack links).

```
ROM → JSON (extract) → EDIT JSON → ASM (convert) → ROM (build)
```

## Pipeline Commands

### 1. Extract Data from ROM

```bash
# Extract all battle data
make extract-data
```

This runs:
- `tools/extraction/extract_enemies.py` → `data/extracted/enemies/enemies.json`
- (Attack and link data already extracted)

### 2. Edit JSON Data

Edit the JSON files directly:
- `data/extracted/enemies/enemies.json` - Enemy stats, resistances, weaknesses
- `data/extracted/attacks/attacks.json` - Attack power, type, sound
- `data/extracted/enemy_attack_links/enemy_attack_links.json` - Enemy→attack mappings

### 3. Convert JSON to ASM

```bash
# Convert all JSON data to ASM
make convert-data
```

This runs:
- `tools/conversion/convert_all.py` which calls:
  - `convert_enemies.py` → `enemies_stats.asm`, `enemies_level.asm`
  - `convert_attacks.py` → `attacks_data.asm`
  - `convert_enemy_attack_links.py` → `enemy_attack_links.asm`

### 4. Build ROM with Converted Data

```bash
# Include converted data in ROM build
make rom
```

The build system includes `src/asm/battle_data.asm` which pulls in all converted ASM files.

### Full Pipeline

```bash
# Extract → Convert
make data-pipeline
```

## File Structure

```
data/
├── extracted/              # JSON data from ROM
│   ├── enemies/
│   │   ├── enemies.json    # Enemy stats with decoded elements
│   │   └── enemies.csv     # Spreadsheet format
│   ├── attacks/
│   │   └── attacks.json    # Attack data
│   └── enemy_attack_links/
│       └── enemy_attack_links.json
│
└── converted/              # ASM files for ROM build
    ├── enemies/
    │   ├── enemies_stats.asm      # 14 bytes × 83 enemies
    │   └── enemies_level.asm      # 3 bytes × 83 enemies
    └── attacks/
        ├── attacks_data.asm        # 7 bytes × 169 attacks
        └── enemy_attack_links.asm  # 6 bytes × 82 enemies
```

## Data Formats

### Enemy Stats (14 bytes)
```
Bytes 0-1:  HP (16-bit little-endian)
Byte 2:     Attack
Byte 3:     Defense
Byte 4:     Speed
Byte 5:     Magic
Bytes 6-7:  Resistances (16-bit bitfield)
Byte 8:     Magic Defense
Byte 9:     Magic Evade
Byte 10:    Accuracy
Byte 11:    Evade
Bytes 12-13: Weaknesses (16-bit bitfield)
```

### Element Bitfield
```
0x0001: Silence    0x0002: Blind      0x0004: Poison    0x0008: Confusion
0x0010: Sleep      0x0020: Paralysis  0x0040: Stone     0x0080: Doom
0x0100: Projectile 0x0200: Bomb       0x0400: Axe       0x0800: Zombie
0x1000: Air        0x2000: Fire       0x4000: Water     0x8000: Earth
```

### Attack Data (7 bytes)
```
Byte 0: Unknown1 (targeting?)
Byte 1: Unknown2
Byte 2: Power
Byte 3: Attack Type (action routine)
Byte 4: Attack Sound
Byte 5: Unknown3
Byte 6: Attack Target Animation
```

## Example: Modifying Enemy Data

1. **Extract data**:
   ```bash
   make extract-data
   ```

2. **Edit JSON** - Make Brownie stronger:
   ```json
   {
     "id": 0,
     "name": "Brownie",
     "hp": 100,           // Was 50
     "attack": 10,        // Was 3
     "resistances": 8192, // 0x2000 = Fire resistant
     "weaknesses": 16384  // 0x4000 = Weak to Water
   }
   ```

3. **Convert to ASM**:
   ```bash
   make convert-data
   ```

4. **Build ROM**:
   ```bash
   make rom
   ```

5. **Test** - Brownie now has 100 HP, resists Fire, weak to Water!

## Verification

```bash
# Verify round-trip conversion (TODO: create this tool)
python tools/verify_data_roundtrip.py
```

## ROM Addresses

| Data Type | Bank | ROM Address | File Offset | Size |
|-----------|------|-------------|-------------|------|
| Enemy Stats | $02 | $C275 | 0x014275 | 14 × 83 |
| Enemy Levels | $02 | $C17C | 0x01417C | 3 × 83 |
| Attacks | $02 | $BC78 | 0x013C78 | 7 × 169 |
| Attack Links | $02 | $BE94 | 0x013E94 | 6 × 82 |

## Troubleshooting

**Problem**: JSON file not found  
**Solution**: Run extraction first: `make extract-data`

**Problem**: ASM file has wrong data  
**Solution**: Re-extract and convert: `make data-pipeline`

**Problem**: ROM build fails  
**Solution**: Check that ASM files are in `data/converted/` and paths in `src/asm/battle_data.asm` are correct

**Problem**: Resistances/weaknesses not decoded  
**Solution**: Use `resistances_decoded` and `weaknesses_decoded` fields in JSON, or check hex values

## Advanced Usage

### Extract Only
```bash
python tools/extraction/extract_enemies.py
```

### Convert Only
```bash
python tools/conversion/convert_all.py
# OR individual converters:
python tools/conversion/convert_enemies.py
python tools/conversion/convert_attacks.py
python tools/conversion/convert_enemy_attack_links.py
```

### View Extracted Data
```bash
# Pretty-print enemy data
python -m json.tool data/extracted/enemies/enemies.json | less

# Open CSV in Excel/LibreOffice
open data/extracted/enemies/enemies.csv
```

## References

### GameFAQs Guides

- **Main FFMQ Page**: https://gamefaqs.gamespot.com/snes/532476-final-fantasy-mystic-quest/faqs
  - Comprehensive collection of guides, FAQs, and walkthroughs

- **Enemies FAQ by DrProctor**: https://gamefaqs.gamespot.com/snes/532476-final-fantasy-mystic-quest/faqs/23095
  - Enemy HP values, experience, and gold drops
  - Used to verify extraction accuracy
  - Note: Some boss encounters may have different HP values than regular enemies
  - Verification: `python tools/verify_gamefaqs_data.py`

### ROM Documentation

- **FFMQ Randomizer Source**: https://github.com/Alchav/FFMQRando
  - Element type definitions and bitfield mappings
  - Data structure specifications
  - ROM address reference

### Data Verification

Our extracted enemy HP data has been verified against the GameFAQs Enemies FAQ:
- ✅ 40 enemies match exactly (Brownie, Flazzard, Mad Toad, etc.)
- ⚠️ 10 enemies show discrepancies (likely bosses with multiple encounters)
- ℹ️ 33 enemies not documented in GameFAQs (boss phases, quest variants)

Run verification: `python tools/verify_gamefaqs_data.py`

## Next Steps

1. ✅ Extract and convert working
2. ⏳ Integrate into build system
3. ⏳ Create verification tool
4. ⏳ Document complete workflow
5. ⏳ Test round-trip conversion
