# FFMQ Data Format Specifications

This document describes all binary data formats used in Final Fantasy: Mystic Quest.

## Table of Contents
- [Map Tilemap Format (Bank $06)](#map-tilemap-format-bank-06)
- [Collision Data Format](#collision-data-format)
- [Text Pointer Format (Bank $08)](#text-pointer-format-bank-08)
- [Dialog String Format](#dialog-string-format)
- [Palette Format (Bank $05)](#palette-format-bank-05)
- [Sprite Format (Bank $04)](#sprite-format-bank-04)

---

## Map Tilemap Format (Bank $06)

### Overview
Maps are built from 16x16 pixel "metatiles", where each metatile is composed of four 8x8 pixel tiles.

### Metatile Structure
```
Format: 4 bytes per metatile
Byte 0: Top-Left 8x8 tile index
Byte 1: Top-Right 8x8 tile index
Byte 2: Bottom-Left 8x8 tile index
Byte 3: Bottom-Right 8x8 tile index

Visual Layout:
┌─────────┬─────────┐
│ Byte 0  │ Byte 1  │  Top row
├─────────┼─────────┤
│ Byte 2  │ Byte 3  │  Bottom row
└─────────┴─────────┘
```

### Example
```asm
; Grass terrain metatile
db $20,$22,$22,$20
	; TL=$20, TR=$22, BL=$22, BR=$20
	; Creates a grass pattern
```

### Special Tile Values
| Value | Meaning |
|-------|---------|
| `$fb` | Empty/transparent tile |
| `$9a` | Common padding/filler |
| `$9b` | Common padding/filler |
| `$00-$7f` | Standard graphics tiles |
| `$80-$ff` | Extended/special tiles |

### Memory Map
| Address Range | Description |
|---------------|-------------|
| `$068000-$0681ff` | Metatile Set 1 (Overworld/outdoor, 128 metatiles) |
| `$068200-$0683ff` | Metatile Set 2 (Indoor/building, 128 metatiles) |
| `$068400-$0685ff` | Metatile Set 3 (Dungeon/cave, 128 metatiles) |
| `$06a000-$06afff` | Collision data (interleaved with screen layouts) |

### Python Class
```python
from ffmq_data_structures import Metatile

# Parse from ROM
tile_data = rom[0x068000:0x068004]
metatile = Metatile.from_bytes(tile_data, metatile_id=0)

# Generate ASM
asm_code = metatile.to_asm()
# Output: db $20,$22,$22,$20  ; Metatile $00: TL/TR/BL/BR

# Export to JSON
json_data = metatile.to_dict()
```

---

## Collision Data Format

### Overview
Collision data uses 1-byte bitfields to define tile properties.

### Bitfield Structure
```
Bit Layout: 7  6  5  4  3  2  1  0
		   ┌──┬──┬──┬──┬──┬──┬──┬──┐
		   │??│??│??│??│TR│LV│WA│BK│
		   └──┴──┴──┴──┴──┴──┴──┴──┘

Bit 0 (BK): Blocked
	- 0 = Passable (player can walk)
	- 1 = Blocked (impassable)

Bit 1 (WA): Water
	- 0 = Normal terrain
	- 1 = Water tile (requires Float ability)

Bit 2 (LV): Lava
	- 0 = Safe terrain
	- 1 = Lava tile (damages player)

Bit 3 (TR): Trigger
	- 0 = Normal tile
	- 1 = Event trigger (door, chest, NPC interaction)

Bits 4-7: Special properties (varies by map)
```

### Examples
```asm
; Passable grass
db $00  ; All flags clear: passable, normal terrain

; Blocked wall
db $01  ; Bit 0 set: impassable

; Water tile
db $02  ; Bit 1 set: water (requires Float)

; Lava floor
db $04  ; Bit 2 set: lava (damages player)

; Door trigger
db $08  ; Bit 3 set: event trigger

; Blocked water (waterfall)
db $03  ; Bits 0,1 set: impassable water
```

### Python Class
```python
from ffmq_data_structures import CollisionData

# Parse from ROM
collision = CollisionData.from_bytes(rom[0x06A000:0x06A001], tile_id=0)

# Check properties
if collision.is_passable:
	print("Player can walk here")
if collision.is_water:
	print("Requires Float ability")
if collision.is_lava:
	print("Damages player")
if collision.is_trigger:
	print("Event trigger")

# Generate ASM
asm_code = collision.to_asm()
# Output: db $02  ; Tile $00: passable, water
```

---

## Text Pointer Format (Bank $08)

### Overview
Text strings are accessed via pointer tables containing 16-bit addresses.

### Pointer Structure
```
Format: 2 bytes (little-endian)
Byte 0: Low byte of address
Byte 1: High byte of address

Example:
db $2d,$03
	; Address = $032d (little-endian)
	; Points to text string at Bank $08 offset $032d
```

### Address Calculation
```
ROM Address = Bank Base + Pointer Value
Bank Base = $088000 (Bank $08 start)

Example:
Pointer = $032d
ROM Address = $088000 + $032d = $08832d
```

### Python Class
```python
from ffmq_data_structures import TextPointer

# Parse from ROM
pointer_data = rom[0x088000:0x088002]
pointer = TextPointer.from_bytes(pointer_data, message_id=0)

print(f"Message 0 points to ${pointer.address:04X}")

# Generate ASM
asm_code = pointer.to_asm()
# Output: db $2d,$03  ; Msg $00: $032d
```

---

## Dialog String Format

### Overview
Text strings are variable-length with custom encoding and control codes.

### String Structure
```
Format: Variable-length, null-terminated
Encoding: Custom character map (see simple.tbl)
Terminator: $00 (null byte)

Structure:
[text bytes...] [control codes...] $00
```

### Control Codes
| Code | Name | Function |
|------|------|----------|
| `$f0` | END | End message, close dialog box |
| `$f1` | NEWLINE | Start new line within dialog |
| `$f2` | WAIT | Wait for player input before continuing |
| `$f3` | CLEAR | Clear screen, continue dialog |
| `$f4` | VAR | Insert variable (number, stat, etc.) |
| `$f5` | ITEM | Insert item name |
| `$f6` | CHAR | Insert character name |
| `$f7` | NUM | Format number with padding |

### Example
```asm
; "Hello World!" message
DATA8_088400:
	db $48,$65,$6c,$6c,$6f  ; "Hello"
	db $20                   ; Space
	db $57,$6f,$72,$6c,$64  ; "World"
	db $21                   ; "!"
	db $f0                   ; END control code
	db $00                   ; Null terminator

; Multi-line dialog
DATA8_088410:
	db $47,$72,$65,$65,$74,$69,$6e,$67,$73,$21  ; "Greetings!"
	db $f1                   ; NEWLINE
	db $57,$65,$6c,$63,$6f,$6d,$65,$21          ; "Welcome!"
	db $f2                   ; WAIT for input
	db $f0                   ; END
	db $00                   ; Null terminator
```

### Character Encoding
See `simple.tbl` for full character map. Common mappings:
- `$20-$5a`: Standard ASCII letters/numbers
- `$61-$7a`: Lowercase letters
- `$f0-$f7`: Control codes
- `$00`: Null terminator

### Python Class
```python
from ffmq_data_structures import DialogString

# Parse from ROM (until null terminator)
text_data = rom[0x088400:0x088420]
dialog = DialogString.from_bytes(text_data, message_id=0)

print(f"Text: {dialog.text}")
print(f"Control codes at positions: {dialog.control_codes}")

# Generate ASM
asm_code = dialog.to_asm()
# Outputs multi-line db statements with text comment
```

---

## Palette Format (Bank $05)

### Overview
SNES uses RGB555 format for colors (15-bit color depth).

### RGB555 Structure
```
Format: 2 bytes (little-endian)

Bit Layout:
	15 14 13 12 11 10  9  8  7  6  5  4  3  2  1  0
┌──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┬──┐
│ 0│B4│B3│B2│B1│B0│G4│G3│G2│G1│G0│R4│R3│R2│R1│R0│
└──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┴──┘
	└────Blue─────┘ └────Green────┘ └─────Red────┘

Bits  0-4:  Red component (0-31)
Bits  5-9:  Green component (0-31)
Bits 10-14: Blue component (0-31)
Bit  15:    Unused (always 0)
```

### Example
```asm
; Pure red (R=31, G=0, B=0)
db $1f,$00
	; Binary: 00000_00000_11111
	; RGB555: $001f

; Pure green (R=0, G=31, B=0)
db $e0,$03
	; Binary: 00000_11111_00000
	; RGB555: $03e0

; Pure blue (R=0, G=0, B=31)
db $00,$7c
	; Binary: 11111_00000_00000
	; RGB555: $7c00

; White (R=31, G=31, B=31)
db $ff,$7f
	; Binary: 11111_11111_11111
	; RGB555: $7fff

; Black (R=0, G=0, B=0)
db $00,$00
	; Binary: 00000_00000_00000
	; RGB555: $0000
```

### Converting to 8-bit RGB
```
RGB888 = (RGB555 * 255) / 31

Example: R=31 (5-bit)
	R8 = (31 * 255) / 31 = 255
```

### Python Class
```python
from ffmq_data_structures import PaletteEntry

# Parse from ROM
color_data = rom[0x070000:0x070002]
color = PaletteEntry.from_bytes(color_data, palette_id=0, color_index=0)

print(f"RGB555: R={color.red}, G={color.green}, B={color.blue}")
print(f"RGB888: {color.to_rgb888()}")

# Generate ASM
asm_code = color.to_asm()
# Output: db $1f,$00  ; RGB(31, 0, 0)
```

---

## Sprite Format (Bank $04)

### Overview
Sprite graphics use 4bpp (16-color) SNES format.

### Tile Structure
```
Format: 8x8 pixel tile, 4 bits per pixel (4bpp)
Size: 32 bytes per tile

Layout:
Bitplane 0-1: First 16 bytes (2bpp)
Bitplane 2-3: Second 16 bytes (2bpp)

Each row (8 pixels):
	Plane 0: Byte 0 (bits 0-7)
	Plane 1: Byte 1 (bits 0-7)
	Plane 2: Byte 16 (bits 0-7)
	Plane 3: Byte 17 (bits 0-7)

Pixel color index = Bit from P3 P2 P1 P0 (4-bit value 0-15)
```

### Example
```asm
; 8x8 tile (32 bytes)
DATA8_070000:
	; Bitplanes 0-1 (rows 0-7)
	db $00,$00  ; Row 0
	db $18,$18  ; Row 1
	db $24,$24  ; Row 2
	db $42,$42  ; Row 3
	db $42,$42  ; Row 4
	db $24,$24  ; Row 5
	db $18,$18  ; Row 6
	db $00,$00  ; Row 7
	
	; Bitplanes 2-3 (rows 0-7)
	db $00,$00  ; Row 0
	db $00,$00  ; Row 1
	db $00,$00  ; Row 2
	db $00,$00  ; Row 3
	db $00,$00  ; Row 4
	db $00,$00  ; Row 5
	db $00,$00  ; Row 6
	db $00,$00  ; Row 7
```

### Compression
Some graphics use **ExpandSecondHalfWithZeros** compression:
- 3bpp data (24 bytes) expanded to 4bpp (32 bytes)
- 4th bitplane filled with zeros
- See `tools/ffmq_compression.py` for decompressor

---

## Build Pipeline

### Extract Data (ROM → JSON)
```bash
# Extract map tilemaps
python tools/extract_bank06_data.py "~roms/FFMQ.sfc"
# Output: data/map_tilemaps.json

# Extract text data
python tools/extract_bank08_data.py "~roms/FFMQ.sfc"
# Output: data/dialog_strings.json, data/text_pointers.json
```

### Edit Data
```bash
# Edit JSON files in data/ directory
# Use any text editor or custom tools
```

### Rebuild ASM (JSON → ASM)
```bash
# Rebuild map data
python tools/build_asm_from_json.py data/map_tilemaps.json src/asm/bank_06_data.asm

# Rebuild text data
python tools/build_asm_from_json.py data/dialog_strings.json src/asm/bank_08_data.asm
```

### Verify Round-Trip
```bash
# Extract → Rebuild → Compare
python tools/verify_data.py "~roms/FFMQ.sfc" src/asm/
# Should report byte-exact match
```

---

## References

- **ROM Analysis**: `historical/diztinguish-disassembly/`
- **Data Structures**: `tools/ffmq_data_structures.py`
- **Extraction Tools**: `tools/extract_*.py`
- **Build Tools**: `tools/build_*.py`
- **Character Encoding**: `simple.tbl`

---

## Change History

- **2025-01-24**: Initial format documentation
	- Map tilemap format (Bank $06)
	- Collision data bitfield spec
	- Text pointer format (Bank $08)
	- Dialog string control codes
	- Palette RGB555 format (Bank $05)
	- Sprite 4bpp format (Bank $04)
	- Build pipeline documentation
