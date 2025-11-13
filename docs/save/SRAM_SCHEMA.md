# FFMQ SRAM Save File Structure

Complete documentation of Final Fantasy: Mystic Quest SRAM save file format.

**Reference**: [DataCrystal SRAM Map](https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest/SRAM_map)  
**Last Updated**: 2025-11-13  
**Status**: Partial (many fields undocumented)

---

## Overview

### SRAM Layout

- **Total Size**: 8,172 bytes (0x1FEC)
- **Save Slots**: 9 total (3 logical slots × 3 redundant copies)
- **Slot Size**: 908 bytes (0x38C) per slot
- **Redundancy**: Triple-copy system (A, B, C) for data integrity
- **Unknown Trailer**: 20 bytes (0x1FEC-0x1FFF) - undocumented

### Slot Organization

| Slot | Offset Range       | Description          |
|------|-------------------|----------------------|
| 1A   | 0x0000 - 0x038B   | Slot 1, Copy A       |
| 2A   | 0x038C - 0x0717   | Slot 2, Copy A       |
| 3A   | 0x0718 - 0x0AA3   | Slot 3, Copy A       |
| 1B   | 0x0AA4 - 0x0E2F   | Slot 1, Copy B       |
| 2B   | 0x0E30 - 0x11BB   | Slot 2, Copy B       |
| 3B   | 0x11BC - 0x154A   | Slot 3, Copy B       |
| 1C   | 0x154B - 0x18D3   | Slot 1, Copy C       |
| 2C   | 0x18D4 - 0x1C5F   | Slot 2, Copy C       |
| 3C   | 0x1C60 - 0x1FEB   | Slot 3, Copy C       |

The game uses triple redundancy to protect against save corruption. When loading, it checks all three copies and uses the valid one.

---

## Save Slot Structure (908 bytes)

Each save slot contains:

### Header (6 bytes)

| Offset | Size | Field      | Description                          |
|--------|------|------------|--------------------------------------|
| 0x000  | 4    | Signature  | ASCII "FF0!" (0x46 46 30 21)         |
| 0x004  | 2    | Checksum   | 16-bit checksum (little-endian)      |

**Checksum Algorithm**:
```
Sum of all bytes from offset 0x006 onwards (all data after header)
Result masked to 16-bit: checksum = sum(bytes[6:]) & 0xFFFF
```

### Character Data

| Offset      | Size | Field         | Description                     |
|-------------|------|---------------|---------------------------------|
| 0x006-0x055 | 80   | Character 1   | Benjamin/Player character       |
| 0x056-0x0A5 | 80   | Character 2   | Partner character               |

See **Character Structure** below for detailed layout.

### Party Data

| Offset | Size | Field            | Type       | Max Value | Description                    |
|--------|------|------------------|------------|-----------|--------------------------------|
| 0x0A6  | 3    | Gold             | 24-bit LE  | 9,999,999 | Party gold                     |
| 0x0A9  | 2    | Unknown          | -          | -         | ???                            |
| 0x0AB  | 1    | Player X         | uint8      | 255       | Player X coordinate            |
| 0x0AC  | 1    | Player Y         | uint8      | 255       | Player Y coordinate            |
| 0x0AD  | 1    | Player Facing    | uint8      | 3         | Direction: 0=Down, 1=Up, 2=Left, 3=Right |
| 0x0AE  | 5    | Unknown          | -          | -         | ???                            |
| 0x0B3  | 1    | Map ID           | uint8      | 255       | Current map number             |
| 0x0B4  | 5    | Unknown          | -          | -         | ???                            |
| 0x0B9  | 3    | Play Time        | Custom     | -         | Seconds, Minutes, Hours (0xSSMMHH) |
| 0x0BC  | 5    | Unknown          | -          | -         | ???                            |
| 0x0C1  | 1    | Cure Count       | uint8      | 255       | Number of cures used           |
| 0x0C2  | 714  | Unknown          | -          | -         | ??? (Large undocumented block) |

**Play Time Format**:
- Byte 0 (0x0B9): Seconds (0-59)
- Byte 1 (0x0BA): Minutes (0-59)
- Byte 2 (0x0BB): Hours (0-255)

Total play time in seconds: `hours * 3600 + minutes * 60 + seconds`

---

## Character Structure (80 bytes)

Each character occupies 0x50 (80) bytes:

### Basic Info

| Offset | Size | Field      | Type      | Max Value | Description                    |
|--------|------|------------|-----------|-----------|--------------------------------|
| 0x00   | 8    | Name       | ASCII     | -         | Character name (null-terminated) |
| 0x08   | 8    | Unknown    | -         | -         | ???                            |
| 0x10   | 1    | Level      | uint8     | 99        | Character level                |
| 0x11   | 3    | Experience | 24-bit LE | 9,999,999 | Total experience points        |
| 0x14   | 2    | Current HP | 16-bit LE | 65535     | Current hit points             |
| 0x16   | 2    | Max HP     | 16-bit LE | 65535     | Maximum hit points             |
| 0x18   | 9    | Unknown    | -         | -         | ???                            |
| 0x21   | 1    | Status     | Bitfield  | -         | Status effect flags            |

### Stats

| Offset | Size | Field           | Type  | Max Value | Description                    |
|--------|------|-----------------|-------|-----------|--------------------------------|
| 0x22   | 1    | Current Attack  | uint8 | 99        | Current attack stat            |
| 0x23   | 1    | Current Defense | uint8 | 99        | Current defense stat           |
| 0x24   | 1    | Current Speed   | uint8 | 99        | Current speed stat             |
| 0x25   | 1    | Current Magic   | uint8 | 99        | Current magic stat             |
| 0x26   | 1    | Base Attack     | uint8 | 99        | Base attack (no equipment)     |
| 0x27   | 1    | Base Defense    | uint8 | 99        | Base defense (no equipment)    |
| 0x28   | 1    | Base Speed      | uint8 | 99        | Base speed (no equipment)      |
| 0x29   | 1    | Base Magic      | uint8 | 99        | Base magic (no equipment)      |

**Current vs Base**: Current stats include equipment bonuses, base stats are character-only.

### Equipment

| Offset | Size | Field        | Type  | Description                    |
|--------|------|--------------|-------|--------------------------------|
| 0x30   | 1    | Weapon Count | uint8 | Number of weapons equipped     |
| 0x31   | 1    | Weapon ID    | uint8 | Current weapon type            |
| 0x32   | 30   | Unknown      | -     | ??? (Equipment data?)          |

---

## Status Effect Flags

Offset 0x21 in character data - bitfield:

| Bit | Value | Status Effect | Description                     |
|-----|-------|---------------|---------------------------------|
| 0   | 0x01  | Poison        | Character is poisoned           |
| 1   | 0x02  | Dark          | Character is blinded            |
| 2   | 0x04  | Moogle        | Character is moogle-morphed     |
| 3   | 0x08  | Mini          | Character is mini-sized         |
| 4   | 0x10  | Confusion     | Character is confused           |
| 5   | 0x20  | Paralyze      | Character is paralyzed          |
| 6   | 0x40  | Petrify       | Character is petrified          |
| 7   | 0x80  | Fatal         | Character is KO'd/dead          |

Multiple effects can be active simultaneously (OR'd together).

---

## Undocumented Fields

### High-Priority Unknown Fields

These fields are particularly important to reverse engineer:

1. **Character Unknown Block (0x32-0x4F, 30 bytes)**
	- Likely contains: Armor, accessory, inventory
	- Could include: Learned spells, abilities
	- May contain: Quest/event flags per character

2. **Party Unknown Block (0x0C2-0x38B, 714 bytes)**
	- Likely contains: Full inventory (items, spells, weapons, armor)
	- Could include: Quest flags, story progress
	- May contain: Battle records, monster book
	- Possibly: Treasure chest states, NPC flags

3. **Character Unknown Block (0x08-0x0F, 8 bytes)**
	- Unknown purpose
	- Possibly: Additional character flags or padding

4. **Small Unknown Blocks**
	- 0x0A9-0x0AA (2 bytes)
	- 0x0AE-0x0B2 (5 bytes)
	- 0x0B4-0x0B8 (5 bytes)
	- 0x0BC-0x0C0 (5 bytes)
	- May be: Individual item counts, flags, or padding

### Research Methods

To document unknown fields:

1. **Save State Comparison**
	- Make minimal changes in-game
	- Save and compare SRAM dumps
	- Identify changed bytes
	- Correlate with game state changes

2. **Hex Editor Testing**
	- Modify suspected fields
	- Test in emulator
	- Document effects

3. **Disassembly Analysis**
	- Trace save/load routines in ROM
	- Identify what reads/writes each offset
	- Document data structures

4. **Community Databases**
	- Cross-reference with other FF games
	- Check similar SNES RPG formats
	- Review existing documentation

---

## Data Types

### Number Formats

- **uint8**: Unsigned 8-bit integer (0-255)
- **16-bit LE**: 16-bit little-endian unsigned integer
- **24-bit LE**: 24-bit little-endian unsigned integer (3 bytes)

### String Format

- **ASCII**: Standard ASCII encoding
- **Null-terminated**: Strings end with 0x00 byte
- **Padding**: Unused bytes filled with 0x00

### Special Formats

- **Bitfield**: Multiple boolean flags packed into single byte
- **BCD**: Some values may use Binary-Coded Decimal (unconfirmed)

---

## Value Limits

| Field                | Maximum    | Storage  | Notes                           |
|----------------------|------------|----------|---------------------------------|
| Level                | 99         | 1 byte   | Single byte, 0-99               |
| Experience           | 9,999,999  | 3 bytes  | 24-bit value                    |
| HP                   | 65,535     | 2 bytes  | 16-bit value (unlikely to reach)|
| Attack/Defense/Speed/Magic | 99   | 1 byte   | Capped at 99                    |
| Gold                 | 9,999,999  | 3 bytes  | 24-bit value                    |
| Play Time Hours      | 255        | 1 byte   | Can overflow (255:59:59 max)    |

---

## Usage Examples

### Reading Character Name

```python
# Character 1 at offset 0x006 within slot
name_bytes = slot_data[0x006:0x00E]  # 8 bytes
name = name_bytes.split(b'\x00')[0].decode('ascii')
```

### Reading Gold

```python
# Gold at offset 0x0A6 within slot (3 bytes, little-endian)
gold_bytes = slot_data[0x0A6:0x0A9]
gold = int.from_bytes(gold_bytes, 'little')
```

### Reading Play Time

```python
# Play time at offset 0x0B9 (3 bytes: SSMMHH)
seconds = slot_data[0x0B9]
minutes = slot_data[0x0BA]
hours = slot_data[0x0BB]
total_seconds = hours * 3600 + minutes * 60 + seconds
```

### Calculating Checksum

```python
# Checksum is sum of all bytes after header
slot_data = sram[slot_offset:slot_offset + 0x38C]
checksum = sum(slot_data[6:]) & 0xFFFF
```

### Verifying Save

```python
# Check signature
if slot_data[0:4] != b'FF0!':
	print("Invalid save slot")
	
# Verify checksum
stored_checksum = int.from_bytes(slot_data[4:6], 'little')
calculated_checksum = sum(slot_data[6:]) & 0xFFFF

if stored_checksum == calculated_checksum:
	print("Checksum valid")
else:
	print("Checksum mismatch!")
```

---

## Tool Support

### FFMQ SRAM Editor

The `ffmq_sram_editor.py` tool provides:

- Load/save .srm files
- Extract individual slots to JSON
- Insert modified slots from JSON
- Verify/fix checksums
- List all slots with status
- Backup functionality
- Comprehensive CLI interface

See tool documentation for usage examples.

---

## Future Work

### High Priority

1. **Document Inventory System**
	- Item storage format
	- Spell lists
	- Equipment storage
	- Consumable counts

2. **Quest/Event Flags**
	- Story progress markers
	- Completed dungeons
	- NPC interactions
	- Treasure chests opened

3. **Map Data**
	- Full map ID list
	- Spawn point coordinates
	- Map state flags

### Medium Priority

4. **Battle Statistics**
	- Monster book completion
	- Kill counts
	- Battle records

5. **Weapon/Armor IDs**
	- Complete equipment list
	- Weapon type enumeration
	- Armor type enumeration

### Low Priority

6. **Character Extended Data**
	- Additional character-specific flags
	- Learned abilities tracking
	- Equipment bonuses calculation

7. **SRAM Trailer**
	- Document 20-byte trailer (0x1FEC-0x1FFF)
	- Determine if used or padding

---

## References

- [DataCrystal SRAM Map](https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest/SRAM_map)
- [TCRF: Final Fantasy Mystic Quest](https://tcrf.net/Final_Fantasy:_Mystic_Quest)
- [SNES Development Wiki](https://wiki.superfamicom.org/)

---

## Changelog

### 2025-11-13
- Initial comprehensive documentation
- Added detailed offset tables
- Documented all known fields
- Added usage examples
- Created research methodology section
- Identified high-priority unknown fields

---

## License

This documentation is provided for educational and preservation purposes.

Final Fantasy: Mystic Quest © Square (now Square Enix)
