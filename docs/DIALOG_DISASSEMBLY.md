================================================================================
Dialog System Disassembly Analysis
Final Fantasy Mystic Quest - Control Code Handlers
================================================================================

## Overview

**Dialog Rendering System**:
- Dialog_ReadNextByte: 0x009DBD
- Dialog_WriteCharacter: 0x009DC9
- Dialog_ProcessCommand: 0x009DD2
- Jump Table: 0x009E0E (ROM 0x001E0E)

**Control Code Range**: 0x00-0x2F (48 codes total)

## Jump Table Map

| Code | Name | Handler Address | ROM Offset | First Bytes |
|------|------|-----------------|------------|-------------|
| 0x00 | END | 0x00A378 | 0x002378 | A9 80 00 0C D0 00 60 A7 17 E6 17 29 |
| 0x01 | NEWLINE | 0x00A8C0 | 0x0028C0 | A9 3E 00 14 1A 4A 25 25 0A 05 1A 69 |
| 0x02 | WAIT | 0x00A8BD | 0x0028BD | 20 C0 A8 A9 3E 00 14 1A 4A 25 25 0A |
| 0x03 | ASTERISK / PORTRAIT | 0x00A39C | 0x00239C | A9 40 00 2D D0 00 F0 01 60 A9 FF 00 |
| 0x04 | NAME | 0x00B354 | 0x003354 | 60 A7 17 E6 17 E6 17 C9 00 80 90 07 |
| 0x05 | ITEM | 0x00A37F | 0x00237F | A7 17 E6 17 29 FF 00 0A AA 7C 6E 9E |
| 0x06 | SPACE | 0x00B4B0 | 0x0034B0 | A9 20 00 2D DA 00 F0 03 4C C0 A8 A9 |
| 0x07 | UNKNOWN_07 | 0x00A708 | 0x002708 | A7 17 E6 17 E6 17 AA A7 17 E6 17 29 |
| 0x08 | UNKNOWN_08 (CRITICAL - 500+ uses) | 0x00A755 | 0x002755 | A7 17 E6 17 E6 17 AA A5 19 80 BC A7 |
| 0x09 | UNKNOWN_09 | 0x00A83F | 0x00283F | A7 17 E6 17 E6 17 A8 A7 17 E6 17 29 |
| 0x0A | UNKNOWN_0A | 0x00A519 | 0x002519 | A7 17 85 17 60 A7 17 E6 17 E6 17 AA |
| 0x0B | UNKNOWN_0B | 0x00A3F5 | 0x0023F5 | 20 C3 B1 D0 07 80 0A 20 C3 B1 D0 05 |
| 0x0C | UNKNOWN_0C | 0x00A958 | 0x002958 | A7 17 E6 17 E6 17 AA A7 17 E6 17 29 |
| 0x0D | UNKNOWN_0D | 0x00A96C | 0x00296C | A7 17 E6 17 E6 17 AA A7 17 E6 17 E6 |
| 0x0E | UNKNOWN_0E (FREQUENT - 100+ uses) | 0x00A97D | 0x00297D | 20 6C A9 A7 17 E6 17 29 FF 00 E2 20 |
| 0x0F | UNKNOWN_0F | 0x00AFD6 | 0x002FD6 | 64 9E 64 A0 A7 17 E6 17 E6 17 AA E2 |
| 0x10 | INSERT_ITEM_NAME | 0x00AF9A | 0x002F9A | A9 01 00 80 E0 A9 02 00 80 DB 20 BB |
| 0x11 | INSERT_SPELL_NAME | 0x00AF6B | 0x002F6B | A9 00 00 80 EB A9 01 00 80 E6 A9 02 |
| 0x12 | INSERT_MONSTER_NAME | 0x00AF70 | 0x002F70 | A9 01 00 80 E6 A9 02 00 80 E1 20 2A |
| 0x13 | INSERT_CHARACTER_NAME | 0x00B094 | 0x003094 | A9 00 00 80 E5 A9 01 00 80 E0 A9 02 |
| 0x14 | INSERT_LOCATION_NAME | 0x00AFFE | 0x002FFE | A9 00 00 80 E6 A9 01 00 80 E1 A9 02 |
| 0x15 | INSERT_NUMBER? (UNUSED) | 0x00A0B7 | 0x0020B7 | A7 17 E6 17 E6 17 85 25 60 D4 9E D4 |
| 0x16 | INSERT_OBJECT_NAME | 0x00B2F9 | 0x0032F9 | A7 17 E6 17 E6 17 4C CB 9D A7 17 E6 |
| 0x17 | INSERT_WEAPON_NAME | 0x00AEDA | 0x002EDA | A7 17 E6 17 29 FF 00 0B F4 D0 00 2B |
| 0x18 | INSERT_ARMOR_NAME | 0x00AACF | 0x002ACF | A5 27 29 FF 00 0A AA D4 25 A5 28 85 |
| 0x19 | INSERT_ACCESSORY? (UNUSED) | 0x00A8D1 | 0x0028D1 | A5 40 85 1B A5 25 29 FF 00 0A 85 1A |
| 0x1A | TEXTBOX_BELOW | 0x00A168 | 0x002168 | A7 17 E6 17 29 FF 00 E2 20 85 4F C2 |
| 0x1B | TEXTBOX_ABOVE | 0x00A17E | 0x00217E | A7 17 E6 17 29 FF 00 E2 20 85 4F C2 |
| 0x1C | UNKNOWN_1C | 0x00A15C | 0x00215C | E2 20 A9 03 85 19 A2 57 84 86 17 60 |
| 0x1D | FORMAT_ITEM_E1 | 0x00A13C | 0x00213C | A7 17 E6 17 29 FF 00 85 9E 64 A0 A9 |
| 0x1E | FORMAT_ITEM_E2 | 0x00A0FE | 0x0020FE | D4 9E D4 A0 A7 17 E6 17 29 FF 00 85 |
| 0x1F | CRYSTAL | 0x00A0C0 | 0x0020C0 | D4 9E D4 A0 A7 17 E6 17 29 FF 00 85 |
| 0x20 | UNKNOWN_20 | 0x00A0DF | 0x0020DF | D4 9E D4 A0 A7 17 E6 17 29 FF 00 85 |
| 0x21 | UNKNOWN_21 | 0x00B2F4 | 0x0032F4 | E6 1A E6 1A 60 A7 17 E6 17 E6 17 4C |
| 0x22 | UNKNOWN_22 | 0x00A150 | 0x002150 | E2 20 A9 03 85 19 A2 A7 AE 86 17 60 |
| 0x23 | UNKNOWN_23 | 0x00AEA2 | 0x002EA2 | A7 17 E6 17 29 FF 00 22 60 97 00 60 |
| 0x24 | UNKNOWN_24 | 0x00A11D | 0x00211D | A7 17 E6 17 E6 17 85 28 A7 17 E6 17 |
| 0x25 | UNKNOWN_25 | 0x00A07D | 0x00207D | A7 17 E6 17 29 FF 00 E2 20 85 1E 60 |
| 0x26 | UNKNOWN_26 | 0x00A089 | 0x002089 | A7 17 E6 17 E6 17 85 3F A7 17 E6 17 |
| 0x27 | UNKNOWN_27 | 0x00A09D | 0x00209D | A7 17 E6 17 29 FF 00 E2 20 85 27 60 |
| 0x28 | UNKNOWN_28 | 0x00A0A9 | 0x0020A9 | A7 17 E6 17 29 FF 00 E2 20 C2 10 85 |
| 0x29 | UNKNOWN_29 | 0x00AEB5 | 0x002EB5 | A7 17 E6 17 29 FF 00 0B F4 D0 00 2B |
| 0x2A | UNKNOWN_2A | 0x00B379 | 0x003379 | A7 17 E6 17 E6 17 C9 FF FF F0 07 20 |
| 0x2B | UNKNOWN_2B | 0x00AEC7 | 0x002EC7 | A7 17 E6 17 29 FF 00 22 6B 97 00 60 |
| 0x2C | UNKNOWN_2C | 0x00B355 | 0x003355 | A7 17 E6 17 E6 17 C9 00 80 90 07 AA |
| 0x2D | UNKNOWN_2D | 0x00A074 | 0x002074 | A7 17 E6 17 E6 17 85 2E 60 A7 17 E6 |
| 0x2E | UNKNOWN_2E | 0x00A563 | 0x002563 | A7 17 E6 17 29 FF 00 22 76 97 00 D0 |
| 0x2F | UNKNOWN_2F | 0x00A06E | 0x00206E | A9 A6 0E 85 2E 60 A7 17 E6 17 E6 17 |

## Handler Patterns

### Null Handlers (0x0000)

No null handlers found.

### Shared Handlers

No shared handlers found.

### Sequential Handlers

Codes with handlers in sequential memory (likely related):
  0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x0C, 0x0D, 0x0E, 0x11, 0x12, 0x15, 0x16, 0x17, 0x19, 0x1A, 0x1B, 0x1C, 0x1D, 0x1E, 0x1F, 0x20, 0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29, 0x2B, 0x2C, 0x2D, 0x2F

--------------------------------------------------------------------------------
## Detailed Handler Analysis

### Basic Control Codes (0x00-0x06)

**Code 0x00: END**
- Handler Address: 0x00A378
- ROM Offset: 0x002378
- Usage: 117 uses (100% coverage) - Text terminator
- Code: A9 80 00 0C D0 00 60 A7 17 E6 17 29 FF 00 0A AA 7C 6E 9E A9...

**Code 0x01: NEWLINE**
- Handler Address: 0x00A8C0
- ROM Offset: 0x0028C0
- Usage: 153 uses (37.6% coverage) - Line break
- Code: A9 3E 00 14 1A 4A 25 25 0A 05 1A 69 40 00 85 1A 60 A5 40 85...

**Code 0x02: WAIT**
- Handler Address: 0x00A8BD
- ROM Offset: 0x0028BD
- Usage: 36 uses (14.5% coverage) - Wait for input
- Code: 20 C0 A8 A9 3E 00 14 1A 4A 25 25 0A 05 1A 69 40 00 85 1A 60...

**Code 0x03: ASTERISK / PORTRAIT**
- Handler Address: 0x00A39C
- ROM Offset: 0x00239C
- Usage: 23 uses (14.5% coverage) - Portrait/NPC ID
- Code: A9 40 00 2D D0 00 F0 01 60 A9 FF 00 4C C9 9D 22 00 80 0C A9...

**Code 0x04: NAME**
- Handler Address: 0x00B354
- ROM Offset: 0x003354
- Usage: 6 uses (5.1% coverage) - Character name
- Code: 60 A7 17 E6 17 E6 17 C9 00 80 90 07 AA A9 03 00 4C 1C A7 D4...

**Code 0x05: ITEM**
- Handler Address: 0x00A37F
- ROM Offset: 0x00237F
- Usage: 74 uses (44.4% coverage) - Item insertion
- Code: A7 17 E6 17 29 FF 00 0A AA 7C 6E 9E A9 80 00 0C D8 00 22 00...

**Code 0x06: SPACE**
- Handler Address: 0x00B4B0
- ROM Offset: 0x0034B0
- Usage: 16 uses (11.1% coverage) - Space character
- Code: A9 20 00 2D DA 00 F0 03 4C C0 A8 A9 FF 00 4C C9 9D A9 00 1C...

### Unknown Display Codes (0x07-0x0F)

**Code 0x07: UNKNOWN_07**
- Handler Address: 0x00A708
- ROM Offset: 0x002708
- Usage: Unknown usage
- Code: A7 17 E6 17 E6 17 AA A7 17 E6 17 29 FF 00 80 04 A6 9E A5 A0...

**Code 0x08: UNKNOWN_08 (CRITICAL - 500+ uses)**
- Handler Address: 0x00A755
- ROM Offset: 0x002755
- Usage: 28 uses (17.1% coverage) - CRITICAL UNKNOWN
- Code: A7 17 E6 17 E6 17 AA A5 19 80 BC A7 17 E6 17 29 FF 00 0B F4...

**Code 0x09: UNKNOWN_09**
- Handler Address: 0x00A83F
- ROM Offset: 0x00283F
- Usage: 32 uses (15.4% coverage) - Unknown
- Code: A7 17 E6 17 E6 17 A8 A7 17 E6 17 29 FF 00 F4 FF FF E2 20 88...

**Code 0x0A: UNKNOWN_0A**
- Handler Address: 0x00A519
- ROM Offset: 0x002519
- Usage: Unknown usage
- Code: A7 17 85 17 60 A7 17 E6 17 E6 17 AA E2 20 A7 17 85 19 86 17...

**Code 0x0B: UNKNOWN_0B**
- Handler Address: 0x00A3F5
- ROM Offset: 0x0023F5
- Usage: Unknown usage
- Code: 20 C3 B1 D0 07 80 0A 20 C3 B1 D0 05 E6 17 E6 17 60 A7 17 85...

**Code 0x0C: UNKNOWN_0C**
- Handler Address: 0x00A958
- ROM Offset: 0x002958
- Usage: Unknown usage
- Code: A7 17 E6 17 E6 17 AA A7 17 E6 17 29 FF 00 E2 20 9D 00 00 60...

**Code 0x0D: UNKNOWN_0D**
- Handler Address: 0x00A96C
- ROM Offset: 0x00296C
- Usage: Unknown usage
- Code: A7 17 E6 17 E6 17 AA A7 17 E6 17 E6 17 9D 00 00 60 20 6C A9...

**Code 0x0E: UNKNOWN_0E (FREQUENT - 100+ uses)**
- Handler Address: 0x00A97D
- ROM Offset: 0x00297D
- Usage: 9 uses (7.7% coverage) - Frequent unknown
- Code: 20 6C A9 A7 17 E6 17 29 FF 00 E2 20 9D 02 00 60 A7 17 E6 17...

**Code 0x0F: UNKNOWN_0F**
- Handler Address: 0x00AFD6
- ROM Offset: 0x002FD6
- Usage: Unknown usage
- Code: 64 9E 64 A0 A7 17 E6 17 E6 17 AA E2 20 BD 00 00 85 9E 60 20...

### Dynamic Insertion Codes (0x10-0x1F)

**Code 0x10: INSERT_ITEM_NAME**
- Handler Address: 0x00AF9A
- ROM Offset: 0x002F9A
- Usage: 55 uses (30.8% coverage) - Item name insertion
- Code: A9 01 00 80 E0 A9 02 00 80 DB 20 BB AF 64 9F 64 A0 60 20 BB...

**Code 0x11: INSERT_SPELL_NAME**
- Handler Address: 0x00AF6B
- ROM Offset: 0x002F6B
- Usage: 27 uses (12.8% coverage) - Spell name insertion
- Code: A9 00 00 80 EB A9 01 00 80 E6 A9 02 00 80 E1 20 2A AF 80 03...

**Code 0x12: INSERT_MONSTER_NAME**
- Handler Address: 0x00AF70
- ROM Offset: 0x002F70
- Usage: 19 uses (13.7% coverage) - Monster name insertion
- Code: A9 01 00 80 E6 A9 02 00 80 E1 20 2A AF 80 03 20 47 AF A5 98...

**Code 0x13: INSERT_CHARACTER_NAME**
- Handler Address: 0x00B094
- ROM Offset: 0x003094
- Usage: 17 uses (14.5% coverage) - Character name insertion
- Code: A9 00 00 80 E5 A9 01 00 80 E0 A9 02 00 80 DB A9 00 00 80 DB...

**Code 0x14: INSERT_LOCATION_NAME**
- Handler Address: 0x00AFFE
- ROM Offset: 0x002FFE
- Usage: 8 uses (6.8% coverage) - Location name insertion
- Code: A9 00 00 80 E6 A9 01 00 80 E1 A9 02 00 80 DC A9 00 00 80 DC...

**Code 0x15: INSERT_NUMBER? (UNUSED)**
- Handler Address: 0x00A0B7
- ROM Offset: 0x0020B7
- Usage: Unknown usage
- Code: A7 17 E6 17 E6 17 85 25 60 D4 9E D4 A0 A7 17 E6 17 29 FF 00...

**Code 0x16: INSERT_OBJECT_NAME**
- Handler Address: 0x00B2F9
- ROM Offset: 0x0032F9
- Usage: 12 uses (6.0% coverage) - Object name insertion
- Code: A7 17 E6 17 E6 17 4C CB 9D A7 17 E6 17 29 FF 00 4C C9 9D A7...

**Code 0x17: INSERT_WEAPON_NAME**
- Handler Address: 0x00AEDA
- ROM Offset: 0x002EDA
- Usage: 1 use (0.9% coverage) - Weapon name insertion
- Code: A7 17 E6 17 29 FF 00 0B F4 D0 00 2B 22 54 97 00 2B 60 A5 2E...

**Code 0x18: INSERT_ARMOR_NAME**
- Handler Address: 0x00AACF
- ROM Offset: 0x002ACF
- Usage: 20 uses (15.4% coverage) - Armor name insertion
- Code: A5 27 29 FF 00 0A AA D4 25 A5 28 85 25 20 D1 A8 20 9E B4 A5...

**Code 0x19: INSERT_ACCESSORY? (UNUSED)**
- Handler Address: 0x00A8D1
- ROM Offset: 0x0028D1
- Usage: Unknown usage
- Code: A5 40 85 1B A5 25 29 FF 00 0A 85 1A A5 25 29 00 FF 4A 4A 65...

**Code 0x1A: TEXTBOX_BELOW**
- Handler Address: 0x00A168
- ROM Offset: 0x002168
- Usage: 24 uses (18.8% coverage) - Textbox below
- Code: A7 17 E6 17 29 FF 00 E2 20 85 4F C2 30 A9 03 00 A2 31 A8 4C...

**Code 0x1B: TEXTBOX_ABOVE**
- Handler Address: 0x00A17E
- ROM Offset: 0x00217E
- Usage: 7 uses (6.0% coverage) - Textbox above
- Code: A7 17 E6 17 29 FF 00 E2 20 85 4F C2 30 A9 03 00 A2 95 A8 4C...

**Code 0x1C: UNKNOWN_1C**
- Handler Address: 0x00A15C
- ROM Offset: 0x00215C
- Usage: 3 uses (2.6% coverage) - Unknown
- Code: E2 20 A9 03 85 19 A2 57 84 86 17 60 A7 17 E6 17 29 FF 00 E2...

**Code 0x1D: FORMAT_ITEM_E1**
- Handler Address: 0x00A13C
- ROM Offset: 0x00213C
- Usage: 25 uses (17.9% coverage) - Format item E1 (dict 0x50)
- Code: A7 17 E6 17 29 FF 00 85 9E 64 A0 A9 03 00 A2 F6 A7 4C 1C A7...

**Code 0x1E: FORMAT_ITEM_E2**
- Handler Address: 0x00A0FE
- ROM Offset: 0x0020FE
- Usage: 10 uses (8.5% coverage) - Format item E2 (dict 0x51)
- Code: D4 9E D4 A0 A7 17 E6 17 29 FF 00 85 9E 64 A0 A9 03 00 A2 83...

**Code 0x1F: CRYSTAL**
- Handler Address: 0x00A0C0
- ROM Offset: 0x0020C0
- Usage: 2 uses (0.9% coverage) - Crystal reference
- Code: D4 9E D4 A0 A7 17 E6 17 29 FF 00 85 9E 64 A0 A9 03 00 A2 BB...

### Advanced Codes (0x20-0x2F)

**Code 0x20: UNKNOWN_20**
- Handler Address: 0x00A0DF
- ROM Offset: 0x0020DF
- Usage: Unknown usage
- Code: D4 9E D4 A0 A7 17 E6 17 29 FF 00 85 9E 64 A0 A9 03 00 A2 02...

**Code 0x21: UNKNOWN_21**
- Handler Address: 0x00B2F4
- ROM Offset: 0x0032F4
- Usage: Unknown usage
- Code: E6 1A E6 1A 60 A7 17 E6 17 E6 17 4C CB 9D A7 17 E6 17 29 FF...

**Code 0x22: UNKNOWN_22**
- Handler Address: 0x00A150
- ROM Offset: 0x002150
- Usage: Unknown usage
- Code: E2 20 A9 03 85 19 A2 A7 AE 86 17 60 E2 20 A9 03 85 19 A2 57...

**Code 0x23: UNKNOWN_23**
- Handler Address: 0x00AEA2
- ROM Offset: 0x002EA2
- Usage: Unknown usage
- Code: A7 17 E6 17 29 FF 00 22 60 97 00 60 A5 9E 22 60 97 00 60 A7...

**Code 0x24: UNKNOWN_24**
- Handler Address: 0x00A11D
- ROM Offset: 0x00211D
- Usage: Unknown usage
- Code: A7 17 E6 17 E6 17 85 28 A7 17 E6 17 E6 17 85 2A 60 A7 17 E6...

**Code 0x25: UNKNOWN_25**
- Handler Address: 0x00A07D
- ROM Offset: 0x00207D
- Usage: Unknown usage
- Code: A7 17 E6 17 29 FF 00 E2 20 85 1E 60 A7 17 E6 17 E6 17 85 3F...

**Code 0x26: UNKNOWN_26**
- Handler Address: 0x00A089
- ROM Offset: 0x002089
- Usage: Unknown usage
- Code: A7 17 E6 17 E6 17 85 3F A7 17 E6 17 29 FF 00 E2 20 85 41 60...

**Code 0x27: UNKNOWN_27**
- Handler Address: 0x00A09D
- ROM Offset: 0x00209D
- Usage: Unknown usage
- Code: A7 17 E6 17 29 FF 00 E2 20 85 27 60 A7 17 E6 17 29 FF 00 E2...

**Code 0x28: UNKNOWN_28**
- Handler Address: 0x00A0A9
- ROM Offset: 0x0020A9
- Usage: Unknown usage
- Code: A7 17 E6 17 29 FF 00 E2 20 C2 10 85 1D 60 A7 17 E6 17 E6 17...

**Code 0x29: UNKNOWN_29**
- Handler Address: 0x00AEB5
- ROM Offset: 0x002EB5
- Usage: Unknown usage
- Code: A7 17 E6 17 29 FF 00 0B F4 D0 00 2B 22 4E 97 00 2B 60 A7 17...

**Code 0x2A: UNKNOWN_2A**
- Handler Address: 0x00B379
- ROM Offset: 0x003379
- Usage: Unknown usage
- Code: A7 17 E6 17 E6 17 C9 FF FF F0 07 20 5B B3 C2 30 80 EE 60 A5...

**Code 0x2B: UNKNOWN_2B**
- Handler Address: 0x00AEC7
- ROM Offset: 0x002EC7
- Usage: Unknown usage
- Code: A7 17 E6 17 29 FF 00 22 6B 97 00 60 A5 9E 22 6B 97 00 60 A7...

**Code 0x2C: UNKNOWN_2C**
- Handler Address: 0x00B355
- ROM Offset: 0x003355
- Usage: Unknown usage
- Code: A7 17 E6 17 E6 17 C9 00 80 90 07 AA A9 03 00 4C 1C A7 D4 17...

**Code 0x2D: UNKNOWN_2D**
- Handler Address: 0x00A074
- ROM Offset: 0x002074
- Usage: Unknown usage
- Code: A7 17 E6 17 E6 17 85 2E 60 A7 17 E6 17 29 FF 00 E2 20 85 1E...

**Code 0x2E: UNKNOWN_2E**
- Handler Address: 0x00A563
- ROM Offset: 0x002563
- Usage: Unknown usage
- Code: A7 17 E6 17 29 FF 00 22 76 97 00 D0 A9 80 25 A7 17 E6 17 29...

**Code 0x2F: UNKNOWN_2F**
- Handler Address: 0x00A06E
- ROM Offset: 0x00206E
- Usage: Unknown usage
- Code: A9 A6 0E 85 2E 60 A7 17 E6 17 E6 17 85 2E 60 A7 17 E6 17 29...

--------------------------------------------------------------------------------
## Assembly Code Reference

### Dialog_ReadNextByte (0x009DBD)
```asm
Dialog_ReadNextByte:
    lda.B [$17]         ; Read byte from dialog pointer
    inc.B $17           ; Increment pointer
    and.W #$00FF        ; Mask to 8-bit
    cmp.W #$0080        ; Compare to 0x80
    bcc ProcessCommand  ; < 0x80 → control code or dictionary
```

### Dialog_WriteCharacter (0x009DC9)
```asm
Dialog_WriteCharacter:
    eor.B $1D           ; XOR with font table selector?
    sta.B [$1A]         ; Store to output buffer
    inc.B $1A           ; Increment buffer pointer (x2)
    inc.B $1A
    rts
```

### Dialog_ProcessCommand (0x009DD2)
```asm
Dialog_ProcessCommand:
    cmp.W #$0030        ; Compare to 0x30
    bcs TextReference   ; >= 0x30 → dictionary entry
    asl                 ; Multiply by 2 (word size)
    tax                 ; Use as index
    jsr.W (JumpTable,x) ; Jump to handler via table
    rep #$30            ; Return to 16-bit mode
    rts
```

--------------------------------------------------------------------------------
## Next Steps

### Priority 1: Disassemble High-Use Handlers
1. **Code 0x08** (500+ uses) - CRITICAL
2. **Code 0x0E** (100+ uses) - Frequent
3. **Codes 0x10-0x1E** (Dynamic insertion)

### Priority 2: Validate Hypotheses
1. Test codes 0x1D vs 0x1E behavior
2. Verify equipment slot detection (0x10 vs 0x17 vs 0x18)
3. Identify table references in handler code

### Priority 3: Document All Handlers
1. Create detailed disassembly for each handler
2. Identify subroutines called by handlers
3. Map data tables used by handlers

================================================================================
End of Report
================================================================================
