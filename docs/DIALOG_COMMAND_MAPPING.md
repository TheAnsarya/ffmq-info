# FFMQ Dialog Command Mapping Guide

## Command Reference

This document maps all control codes used in FFMQ dialog system.

### Confirmed Commands

| Byte | Name | Bytes | Function | Evidence |
|------|------|-------|----------|----------|
| 0x00 | END | 1 | End of string | ✓ |
| 0x01 | NEWLINE | 1 | Line break | ✓ |
| 0x02 | WAIT | 1 | Wait for button press | ✓ |
| 0x04 | NAME | 1 | Insert character name | ✓ |
| 0x05 | ITEM | 1 | Insert item name | ✓ |
| 0x06 | SPACE | 1 | Space character | ✓ |
| 0x1A | TEXTBOX_BELOW | 1 | Position dialog box below | ✓ |
| 0x1B | TEXTBOX_ABOVE | 1 | Position dialog box above | ✓ |
| 0x23 | CLEAR | 1 | Clear dialog box | ✓ |
| 0x30 | PARA | 1 | Paragraph break | ✓ |
| 0x36 | PAGE | 1 | New page/dialog box | ✓ |

### Speculative Commands (Need Verification)

| Byte | Name | Bytes | Function | Evidence |
|------|------|-------|----------|----------|
| 0x03 | ASTERISK | 1 | Display asterisk character | Pattern analysis |
| 0x07 | SPEED_SLOW | 1 | Slow text speed | Pattern analysis |
| 0x08 | SPEED_NORM | 1 | Normal text speed | Pattern analysis |
| 0x09 | SPEED_FAST | 1 | Fast text speed | Pattern analysis |
| 0x0A | DELAY | 2 | Delay with parameter | Pattern analysis |
| 0x0D | SET_FLAG | 3 | Set game flag (param1, param2) | Pattern analysis |
| 0x10 | PARAM_10 | 1 | Parameter/event code | Pattern analysis |
| 0x14 | PARAM_14 | 2 | Multi-byte parameter (usually 0x91) | Pattern analysis |
| 0x20 | PARAM_20 | 1 | Parameter/event code | Pattern analysis |
| 0x2A | PARAM_2A | 1 | Parameter/event code | Pattern analysis |
| 0x2C | PARAM_2C | 1 | Parameter/event code | Pattern analysis |
| 0x80 | EXT_80 | 2 | Extended command with param | Pattern analysis |
| 0x81 | EXT_81 | 2 | Extended command with param | Pattern analysis |
| 0x82 | EXT_82 | 2 | Extended command with param | Pattern analysis |
| 0x88 | EXT_88 | 2 | Extended command (followed by 0x10) | Pattern analysis |
| 0x8B | EXT_8B | 2 | Extended command (followed by 0x05) | Pattern analysis |
| 0x8D | EXT_8D | 2 | Extended command with param | Pattern analysis |
| 0x8E | EXT_8E | 2 | Extended command (usually 0x14) | Pattern analysis |
| 0x8F | EXT_8F | 2 | Extended command (usually 0x30) | Pattern analysis |

### Commands Needing Investigation

These commands appear in dialogs but their function is unknown:

| Byte | Uses | Sample Contexts |
|------|------|----------------|
| 0x03 | 15 | D2:cc230300<br>D19:9610053713030506048dab |
| 0x07 | 18 | D1:08080808080700<br>D7:08080808080700 |
| 0x08 | 55 | D1:060536080808080807<br>D1:06053608080808080700 |
| 0x09 | 14 | D20:252c095dd200<br>D36:b56cff461f09d20d5f0102 |
| 0x0A | 36 | D9:070882810acf88101d00<br>D15:070882810acf88101d00 |
| 0x0B | 7 | D25:0d0e549a160b050a559aff<br>D33:250b26ffff1a81 |
| 0x0C | 10 | D58:12380c0c030e00<br>D58:12380c0c030e00 |
| 0x0D | 17 | D23:010db400<br>D25:9affff050d0e549a160b |
| 0x0E | 9 | D25:9affff050d0e549a160b05<br>D57:2c21440f8b0e057c0108db |
| 0x0F | 10 | D21:30910a14910f0100<br>D25:9affff050d0f619a160a05 |
| 0x10 | 25 | D9:82810acf88101d00<br>D15:82810acf88101d00 |
| 0x11 | 14 | D11:051105241a00<br>D38:0f5f01057e115f0114030b |
| 0x12 | 11 | D3:fe05456201121a00<br>D8:2a12272901ffff |
| 0x13 | 7 | D19:9610053713030506048d<br>D34:421302122500 |
| 0x14 | 26 | D21:90057f058e1491057f058e<br>D21:91057f058e14910a309105 |
| 0x15 | 6 | D57:362c11441a15a5bc65564d<br>D57:db2c01451a15a1b8cc6f5b |
| 0x16 | 12 | D25:050d0e549a160b050a559a<br>D25:050d0f619a160a050a629a |
| 0x20 | 15 | D57:4405274546204020431144<br>D57:274546204020431144ffff |
| 0x21 | 8 | D36:622bce2a08211341105043<br>D57:53362bfd2c21440f8b0e05 |
| 0x22 | 4 | D74:428344124322442054b344<br>D112:22052205220a |
| 0x24 | 11 | D5:058b052468011a00<br>D11:051105241a00 |
| 0x25 | 8 | D20:252c095dd200<br>D27:02122500 |
| 0x26 | 3 | D33:250b26ffff1a81a5<br>D65:250b26ffff1a81a5 |
| 0x27 | 7 | D8:2a12272901ffff00<br>D14:2a12272901ffff00 |
| 0x28 | 2 | D91:09fff7b10c2800<br>D96:248d05fd81288d09ed9b00 |
| 0x29 | 2 | D8:2a12272901ffff00<br>D14:2a12272901ffff00 |
| 0x2A | 19 | D8:2a12272901ff<br>D14:2a12272901ff |
| 0x2B | 14 | D36:5f010201622bce2a082113<br>D57:4da66953362bfd2c21440f |
| 0x2C | 22 | D20:252c095dd200<br>D51:252c095dd200 |
| 0x31 | 3 | D54:4b67c0b8533166b7547e3f<br>D110:c74bce362a314611401141 |
| 0x32 | 6 | D54:b05cbfb7d2329abfb4c64d<br>D74:46105a8344324430550245 |
| 0x33 | 2 | D74:2a3346105a8344<br>D74:44d236612a334450542342 |
| 0x34 | 1 | D110:2a1050124434443054ffff |
| 0x35 | 3 | D33:bb76c3d230354d54bf5955<br>D65:bb76c3d230354d54bf5955 |
| 0x37 | 2 | D19:961005371303050604<br>D50:961005371303050604 |
| 0x38 | 4 | D31:382a0527042a<br>D58:12380c0c030e00 |
| 0x3A | 1 | D87:4d3d053a6201106001 |
| 0x3B | 4 | D19:06048dab053b00<br>D50:06048dab053b00 |
| 0x80 | 5 | D69:0206020904800d00<br>D70:461f09d22b8000 |
| 0x81 | 7 | D9:070882810acf88101d<br>D15:070882810acf88101d |
| 0x82 | 4 | D9:070882810acf8810<br>D15:070882810acf8810 |
| 0x83 | 2 | D74:2a3346105a834432443055<br>D74:4450542342834412432244 |
| 0x84 | 1 | D109:3608840808080806 |
| 0x85 | 3 | D57:05e601085b852b6223632b<br>D67:05e601085b852b6223632b |
| 0x86 | 1 | D53:ae862c00 |
| 0x88 | 6 | D9:0882810acf88101d00<br>D15:0882810acf88101d00 |
| 0x89 | 3 | D39:4dc552cf1b89ab52ceffff<br>D71:05e102080c8905eb05fc96 |
| 0x8A | 1 | D97:058a0520052005 |
| 0x8B | 5 | D5:058b052468011a<br>D17:058b052468011a |
| 0x8D | 6 | D19:13030506048dab053b00<br>D50:13030506048dab053b00 |

## Detailed Command Analysis


### 0x00

**Name:** END

**Function:** End of string

**Byte Count:** 1

**Status:** ✓ Confirmed

**Total Uses:** 116

**Sample Contexts:**

```
Dialog   0 pos   9: ...46ffff [00] ...
Dialog   1 pos   9: ...080807 [00] ...
Dialog   2 pos   3: ...cc2303 [00] ...
Dialog   3 pos   7: ...01121a [00] ...
Dialog   4 pos   1: ...02 [00] ...
```

### 0x01

**Name:** NEWLINE

**Function:** Line break

**Byte Count:** 1

**Status:** ✓ Confirmed

**Total Uses:** 70

**Sample Contexts:**

```
Dialog   3 pos   4: ...054562 [01] 121a00...
Dialog   5 pos   5: ...052468 [01] 1a00...
Dialog   8 pos   4: ...122729 [01] ffff00...
Dialog  14 pos   4: ...122729 [01] ffff00...
Dialog  17 pos   5: ...052468 [01] 1a00...
```

### 0x02

**Name:** WAIT

**Function:** Wait for button press

**Byte Count:** 1

**Status:** ✓ Confirmed

**Total Uses:** 17

**Sample Contexts:**

```
Dialog   4 pos   0: ... [02] 00...
Dialog  27 pos   0: ... [02] 122500...
Dialog  34 pos   2: ...4213 [02] 122500...
Dialog  36 pos   4: ...5a411e [02] ff5f7b...
Dialog  36 pos  36: ...0d5f01 [02] 01622b...
```

### 0x03

**Name:** ASTERISK

**Function:** Display asterisk character

**Byte Count:** 1

**Status:** ? Speculative

**Total Uses:** 15

**Sample Contexts:**

```
Dialog   2 pos   2: ...cc23 [03] 00...
Dialog  19 pos   5: ...053713 [03] 050604...
Dialog  38 pos  11: ...5f0114 [03] 0b00...
Dialog  50 pos   5: ...053713 [03] 050604...
Dialog  58 pos   4: ...380c0c [03] 0e00...
```

### 0x04

**Name:** NAME

**Function:** Insert character name

**Byte Count:** 1

**Status:** ✓ Confirmed

**Total Uses:** 7

**Sample Contexts:**

```
Dialog  19 pos   8: ...030506 [04] 8dab05...
Dialog  31 pos   4: ...2a0527 [04] 2affff...
Dialog  50 pos   8: ...030506 [04] 8dab05...
Dialog  63 pos  18: ...f7e7f7 [04] 05e4c1...
Dialog  69 pos  10: ...060209 [04] 800d00...
```

### 0x05

**Name:** ITEM

**Function:** Insert item name

**Byte Count:** 1

**Status:** ✓ Confirmed

**Total Uses:** 150

**Sample Contexts:**

```
Dialog   1 pos   1: ...06 [05] 360808...
Dialog   3 pos   1: ...fe [05] 456201...
Dialog   5 pos   0: ... [05] 8b0524...
Dialog   5 pos   2: ...058b [05] 246801...
Dialog   7 pos   1: ...06 [05] 360808...
```

### 0x06

**Name:** SPACE

**Function:** Space character

**Byte Count:** 1

**Status:** ✓ Confirmed

**Total Uses:** 16

**Sample Contexts:**

```
Dialog   1 pos   0: ... [06] 053608...
Dialog   7 pos   0: ... [06] 053608...
Dialog  13 pos   0: ... [06] 053608...
Dialog  19 pos   7: ...130305 [06] 048dab...
Dialog  44 pos   0: ... [06] 053608...
```

### 0x07

**Name:** SPEED_SLOW

**Function:** Slow text speed

**Byte Count:** 1

**Status:** ? Speculative

**Total Uses:** 18

**Sample Contexts:**

```
Dialog   1 pos   8: ...080808 [07] 00...
Dialog   7 pos   8: ...080808 [07] 00...
Dialog   9 pos   0: ... [07] 088281...
Dialog  13 pos   8: ...080808 [07] 00...
Dialog  15 pos   0: ... [07] 088281...
```

### 0x08

**Name:** SPEED_NORM

**Function:** Normal text speed

**Byte Count:** 1

**Status:** ? Speculative

**Total Uses:** 55

**Sample Contexts:**

```
Dialog   1 pos   3: ...060536 [08] 080808...
Dialog   1 pos   4: ...053608 [08] 080808...
Dialog   1 pos   5: ...360808 [08] 080807...
Dialog   1 pos   6: ...080808 [08] 080700...
Dialog   1 pos   7: ...080808 [08] 0700...
```

### 0x09

**Name:** SPEED_FAST

**Function:** Fast text speed

**Byte Count:** 1

**Status:** ? Speculative

**Total Uses:** 14

**Sample Contexts:**

```
Dialog  20 pos   2: ...252c [09] 5dd200...
Dialog  36 pos  31: ...ff461f [09] d20d5f...
Dialog  51 pos   2: ...252c [09] 5dd200...
Dialog  60 pos   2: ...252c [09] 5dd200...
Dialog  69 pos   9: ...020602 [09] 04800d...
```

### 0x0A

**Name:** DELAY

**Function:** Delay with parameter

**Byte Count:** 2

**Status:** ? Speculative

**Total Uses:** 36

**Sample Contexts:**

```
Dialog   9 pos   4: ...088281 [0A] cf8810...
Dialog  15 pos   4: ...088281 [0A] cf8810...
Dialog  21 pos   1: ...91 [0A] dc9008...
Dialog  21 pos  23: ...8e1491 [0A] 309105...
Dialog  21 pos  38: ...8f3091 [0A] 149108...
```

### 0x0B

**Total Uses:** 7

**Sample Contexts:**

```
Dialog  25 pos   9: ...549a16 [0B] 050a55...
Dialog  33 pos   1: ...25 [0B] 26ffff...
Dialog  38 pos  12: ...011403 [0B] 00...
Dialog  39 pos  20: ...72411f [0B] ce362a...
Dialog  62 pos   1: ...05 [0B] 46edfc...
```

### 0x0C

**Total Uses:** 10

**Sample Contexts:**

```
Dialog  58 pos   2: ...1238 [0C] 0c030e...
Dialog  58 pos   3: ...12380c [0C] 030e00...
Dialog  59 pos   0: ... [0C] 00...
Dialog  68 pos   2: ...1238 [0C] 0c030e...
Dialog  68 pos   3: ...12380c [0C] 030e00...
```

### 0x0D

**Name:** SET_FLAG

**Function:** Set game flag (param1, param2)

**Byte Count:** 3

**Status:** ? Speculative

**Total Uses:** 17

**Sample Contexts:**

```
Dialog  23 pos   1: ...01 [0D] b400...
Dialog  25 pos   4: ...ffff05 [0D] 0e549a...
Dialog  25 pos  17: ...ffff05 [0D] 0f619a...
Dialog  36 pos  33: ...1f09d2 [0D] 5f0102...
Dialog  69 pos  12: ...090480 [0D] 00...
```

### 0x0E

**Total Uses:** 9

**Sample Contexts:**

```
Dialog  25 pos   5: ...ff050d [0E] 549a16...
Dialog  57 pos  41: ...440f8b [0E] 057c01...
Dialog  57 pos 147: ...0513fd [0E] db2c41...
Dialog  58 pos   5: ...0c0c03 [0E] 00...
Dialog  63 pos  22: ...05e4c1 [0E] 230a2b...
```

### 0x0F

**Total Uses:** 10

**Sample Contexts:**

```
Dialog  21 pos  63: ...0a1491 [0F] 0100...
Dialog  25 pos  18: ...ff050d [0F] 619a16...
Dialog  38 pos   2: ...05dd [0F] 5f0105...
Dialog  52 pos  63: ...0a1491 [0F] 0100...
Dialog  57 pos  39: ...2c2144 [0F] 8b0e05...
```

### 0x10

**Name:** PARAM_10

**Function:** Parameter/event code

**Byte Count:** 1

**Status:** ? Speculative

**Total Uses:** 25

**Sample Contexts:**

```
Dialog   9 pos   7: ...0acf88 [10] 1d00...
Dialog  15 pos   7: ...0acf88 [10] 1d00...
Dialog  19 pos   1: ...96 [10] 053713...
Dialog  33 pos 296: ...463054 [10] 44ffff...
Dialog  36 pos  46: ...211341 [10] 504346...
```

### 0x11

**Total Uses:** 14

**Sample Contexts:**

```
Dialog  11 pos   1: ...05 [11] 05241a...
Dialog  38 pos   7: ...01057e [11] 5f0114...
Dialog  42 pos   1: ...05 [11] 05241a...
Dialog  57 pos  21: ...ce362c [11] 441a15...
Dialog  57 pos 109: ...d2362a [11] 432140...
```

### 0x12

**Total Uses:** 11

**Sample Contexts:**

```
Dialog   3 pos   5: ...456201 [12] 1a00...
Dialog   8 pos   1: ...2a [12] 272901...
Dialog  14 pos   1: ...2a [12] 272901...
Dialog  27 pos   1: ...02 [12] 2500...
Dialog  29 pos   1: ...14 [12] 4a00...
```

### 0x13

**Total Uses:** 7

**Sample Contexts:**

```
Dialog  19 pos   4: ...100537 [13] 030506...
Dialog  34 pos   1: ...42 [13] 021225...
Dialog  36 pos  44: ...2a0821 [13] 411050...
Dialog  50 pos   4: ...100537 [13] 030506...
Dialog  57 pos 145: ...214205 [13] fd0edb...
```

### 0x14

**Name:** PARAM_14

**Function:** Multi-byte parameter (usually 0x91)

**Byte Count:** 2

**Status:** ? Speculative

**Total Uses:** 26

**Sample Contexts:**

```
Dialog  21 pos  15: ...7f058e [14] 91057f...
Dialog  21 pos  21: ...7f058e [14] 910a30...
Dialog  21 pos  39: ...30910a [14] 910801...
Dialog  21 pos  46: ...91058e [14] 91057f...
Dialog  21 pos  52: ...7f058e [14] 91057f...
```

### 0x15

**Total Uses:** 6

**Sample Contexts:**

```
Dialog  57 pos  24: ...11441a [15] a5bc65...
Dialog  57 pos  51: ...01451a [15] a1b8cc...
Dialog  57 pos 128: ...ffff1a [15] 9d547e...
Dialog  67 pos  24: ...11441a [15] a5bc65...
Dialog  67 pos  51: ...01451a [15] a1b8cc...
```

### 0x16

**Total Uses:** 12

**Sample Contexts:**

```
Dialog  25 pos   8: ...0e549a [16] 0b050a...
Dialog  25 pos  21: ...0f619a [16] 0a050a...
Dialog  88 pos   4: ...06ec99 [16] 06010a...
Dialog  88 pos  17: ...07f999 [16] 07050a...
Dialog  94 pos  12: ...07f999 [16] 07050a...
```

### 0x17

**Total Uses:** 1

**Sample Contexts:**

```
Dialog  66 pos   7: ...2a2727 [17] 265346...
```

### 0x18

**Total Uses:** 1

**Sample Contexts:**

```
Dialog  76 pos  35: ...c65323 [18] 00...
```

### 0x1A

**Name:** TEXTBOX_BELOW

**Function:** Position dialog box below

**Byte Count:** 1

**Status:** ✓ Confirmed

**Total Uses:** 29

**Sample Contexts:**

```
Dialog   3 pos   6: ...620112 [1A] 00...
Dialog   5 pos   6: ...246801 [1A] 00...
Dialog  11 pos   4: ...110524 [1A] 00...
Dialog  17 pos   6: ...246801 [1A] 00...
Dialog  33 pos   5: ...26ffff [1A] 81a5c2...
```

### 0x1B

**Name:** TEXTBOX_ABOVE

**Function:** Position dialog box above

**Byte Count:** 1

**Status:** ✓ Confirmed

**Total Uses:** 4

**Sample Contexts:**

```
Dialog  39 pos   9: ...c552cf [1B] 89ab52...
Dialog  56 pos   5: ...c152ce [1B] 00...
Dialog  85 pos  22: ...c356cf [1B] 00...
Dialog  89 pos  12: ...5cb8ce [1B] 329f5c...
```

### 0x1C

**Total Uses:** 1

**Sample Contexts:**

```
Dialog 112 pos   6: ...05220a [1C] 99051e...
```

### 0x1D

**Total Uses:** 6

**Sample Contexts:**

```
Dialog   9 pos   8: ...cf8810 [1D] 00...
Dialog  15 pos   8: ...cf8810 [1D] 00...
Dialog  40 pos   8: ...cf8810 [1D] 00...
Dialog  46 pos   8: ...cf8810 [1D] 00...
Dialog  57 pos   3: ...b4be40 [1D] 01ff4f...
```

### 0x1E

**Total Uses:** 5

**Sample Contexts:**

```
Dialog  36 pos   3: ...425a41 [1E] 02ff5f...
Dialog  57 pos  59: ...5bb442 [1E] 01ffbf...
Dialog  67 pos  59: ...5bb442 [1E] 01ffbf...
Dialog  76 pos  15: ...42bb5f [1E] 08ce30...
Dialog 112 pos   9: ...1c9905 [1E] 1a00...
```

### 0x1F

**Total Uses:** 11

**Sample Contexts:**

```
Dialog  33 pos  23: ...c74e41 [1F] 014d54...
Dialog  33 pos 171: ...455a41 [1F] 01ff4f...
Dialog  36 pos  30: ...6cff46 [1F] 09d20d...
Dialog  39 pos  19: ...ad7241 [1F] 0bce36...
Dialog  65 pos  23: ...c74e41 [1F] 014d54...
```

### 0x20

**Name:** PARAM_20

**Function:** Parameter/event code

**Byte Count:** 1

**Status:** ? Speculative

**Total Uses:** 15

**Sample Contexts:**

```
Dialog  57 pos 119: ...274546 [20] 402043...
Dialog  57 pos 121: ...462040 [20] 431144...
Dialog  57 pos 153: ...41462c [20] 4405e6...
Dialog  66 pos  11: ...265346 [20] 443045...
Dialog  66 pos  15: ...443045 [20] 5400...
```

### 0x21

**Total Uses:** 8

**Sample Contexts:**

```
Dialog  36 pos  43: ...ce2a08 [21] 134110...
Dialog  57 pos  37: ...2bfd2c [21] 440f8b...
Dialog  57 pos 111: ...2a1143 [21] 404144...
Dialog  57 pos 142: ...d2362c [21] 420513...
Dialog  67 pos  37: ...2bfd2c [21] 440f8b...
```

### 0x22

**Total Uses:** 4

**Sample Contexts:**

```
Dialog  74 pos  77: ...441243 [22] 442054...
Dialog 112 pos   0: ... [22] 052205...
Dialog 112 pos   2: ...2205 [22] 05220a...
Dialog 112 pos   4: ...052205 [22] 0a1c99...
```

### 0x23

**Name:** CLEAR

**Function:** Clear dialog box

**Byte Count:** 1

**Status:** ✓ Confirmed

**Total Uses:** 14

**Sample Contexts:**

```
Dialog   2 pos   1: ...cc [23] 0300...
Dialog  16 pos   0: ... [23] 00...
Dialog  39 pos  30: ...46ffff [23] 71234d...
Dialog  39 pos  32: ...ff2371 [23] 4d00...
Dialog  47 pos   0: ... [23] 00...
```

### 0x24

**Total Uses:** 11

**Sample Contexts:**

```
Dialog   5 pos   3: ...058b05 [24] 68011a...
Dialog  11 pos   3: ...051105 [24] 1a00...
Dialog  17 pos   3: ...058b05 [24] 68011a...
Dialog  42 pos   3: ...051105 [24] 1a00...
Dialog  48 pos   3: ...058b05 [24] 68011a...
```

### 0x25

**Total Uses:** 8

**Sample Contexts:**

```
Dialog  20 pos   0: ... [25] 2c095d...
Dialog  27 pos   2: ...0212 [25] 00...
Dialog  33 pos   0: ... [25] 0b26ff...
Dialog  34 pos   4: ...130212 [25] 00...
Dialog  51 pos   0: ... [25] 2c095d...
```

### 0x26

**Total Uses:** 3

**Sample Contexts:**

```
Dialog  33 pos   2: ...250b [26] ffff1a...
Dialog  65 pos   2: ...250b [26] ffff1a...
Dialog  66 pos   8: ...272717 [26] 534620...
```

### 0x27

**Total Uses:** 7

**Sample Contexts:**

```
Dialog   8 pos   2: ...2a12 [27] 2901ff...
Dialog  14 pos   2: ...2a12 [27] 2901ff...
Dialog  31 pos   3: ...382a05 [27] 042aff...
Dialog  57 pos 116: ...414405 [27] 454620...
Dialog  66 pos   5: ...53362a [27] 271726...
```

### 0x28

**Total Uses:** 2

**Sample Contexts:**

```
Dialog  91 pos   9: ...f7b10c [28] 00...
Dialog  96 pos   8: ...05fd81 [28] 8d09ed...
```

### 0x29

**Total Uses:** 2

**Sample Contexts:**

```
Dialog   8 pos   3: ...2a1227 [29] 01ffff...
Dialog  14 pos   3: ...2a1227 [29] 01ffff...
```

### 0x2A

**Name:** PARAM_2A

**Function:** Parameter/event code

**Byte Count:** 1

**Status:** ? Speculative

**Total Uses:** 19

**Sample Contexts:**

```
Dialog   8 pos   0: ... [2A] 122729...
Dialog  14 pos   0: ... [2A] 122729...
Dialog  31 pos   1: ...38 [2A] 052704...
Dialog  31 pos   5: ...052704 [2A] ffff00...
Dialog  33 pos 287: ...b7d236 [2A] 3059a0...
```

### 0x2B

**Total Uses:** 14

**Sample Contexts:**

```
Dialog  36 pos  39: ...020162 [2B] ce2a08...
Dialog  57 pos  34: ...695336 [2B] fd2c21...
Dialog  57 pos 161: ...085b85 [2B] 622363...
Dialog  57 pos 165: ...622363 [2B] 6c00...
Dialog  63 pos  25: ...0e230a [2B] 0e2c50...
```

### 0x2C

**Name:** PARAM_2C

**Function:** Parameter/event code

**Byte Count:** 1

**Status:** ? Speculative

**Total Uses:** 22

**Sample Contexts:**

```
Dialog  20 pos   1: ...25 [2C] 095dd2...
Dialog  51 pos   1: ...25 [2C] 095dd2...
Dialog  53 pos   2: ...ae86 [2C] 00...
Dialog  57 pos  20: ...c6ce36 [2C] 11441a...
Dialog  57 pos  36: ...362bfd [2C] 21440f...
```

### 0x30

**Name:** PARA

**Function:** Paragraph break

**Byte Count:** 1

**Status:** ✓ Confirmed

**Total Uses:** 44

**Sample Contexts:**

```
Dialog  21 pos  24: ...14910a [30] 91057f...
Dialog  21 pos  30: ...7f058f [30] 91057f...
Dialog  21 pos  36: ...7f058f [30] 910a14...
Dialog  21 pos  58: ...7f058f [30] 910a14...
Dialog  33 pos  41: ...bfb7d2 [30] 9ac1ff...
```

### 0x31

**Total Uses:** 3

**Sample Contexts:**

```
Dialog  54 pos  18: ...c0b853 [31] 66b754...
Dialog 110 pos  99: ...ce362a [31] 461140...
Dialog 110 pos 150: ...501044 [31] 441054...
```

### 0x32

**Total Uses:** 6

**Sample Contexts:**

```
Dialog  54 pos  52: ...bfb7d2 [32] 9abfb4...
Dialog  74 pos   7: ...5a8344 [32] 443055...
Dialog  74 pos  89: ...434346 [32] 441054...
Dialog  89 pos  13: ...b8ce1b [32] 9f5cff...
Dialog  89 pos 116: ...30551a [32] 9bc842...
```

### 0x33

**Total Uses:** 2

**Sample Contexts:**

```
Dialog  74 pos   1: ...2a [33] 46105a...
Dialog  74 pos  67: ...36612a [33] 445054...
```

### 0x34

**Total Uses:** 1

**Sample Contexts:**

```
Dialog 110 pos   9: ...501244 [34] 443054...
```

### 0x35

**Total Uses:** 3

**Sample Contexts:**

```
Dialog  33 pos 263: ...c3d230 [35] 4d54bf...
Dialog  65 pos 263: ...c3d230 [35] 4d54bf...
Dialog  74 pos  97: ...ff1a60 [35] 4d55c1...
```

### 0x36

**Name:** PAGE

**Function:** New page/dialog box

**Byte Count:** 1

**Status:** ✓ Confirmed

**Total Uses:** 29

**Sample Contexts:**

```
Dialog   1 pos   2: ...0605 [36] 080808...
Dialog   7 pos   2: ...0605 [36] 080808...
Dialog  13 pos   2: ...0605 [36] 080808...
Dialog  33 pos 286: ...bfb7d2 [36] 2a3059...
Dialog  39 pos  22: ...1f0bce [36] 2a1043...
```

### 0x37

**Total Uses:** 2

**Sample Contexts:**

```
Dialog  19 pos   3: ...961005 [37] 130305...
Dialog  50 pos   3: ...961005 [37] 130305...
```

### 0x38

**Total Uses:** 4

**Sample Contexts:**

```
Dialog  31 pos   0: ... [38] 2a0527...
Dialog  58 pos   1: ...12 [38] 0c0c03...
Dialog  64 pos   2: ...7f08 [38] 2400...
Dialog  68 pos   1: ...12 [38] 0c0c03...
```

### 0x3A

**Total Uses:** 1

**Sample Contexts:**

```
Dialog  87 pos   3: ...4d3d05 [3A] 620110...
```

### 0x3B

**Total Uses:** 4

**Sample Contexts:**

```
Dialog  19 pos  12: ...8dab05 [3B] 00...
Dialog  50 pos  12: ...8dab05 [3B] 00...
Dialog  87 pos  27: ...309c05 [3B] 00...
Dialog 111 pos  18: ...309c05 [3B] 00...
```

### 0x80

**Name:** EXT_80

**Function:** Extended command with param

**Byte Count:** 2

**Status:** ? Speculative

**Total Uses:** 5

**Sample Contexts:**

```
Dialog  69 pos  11: ...020904 [80] 0d00...
Dialog  70 pos  20: ...09d22b [80] 00...
Dialog  92 pos   6: ...09d22b [80] 00...
Dialog  96 pos   2: ...05fc [80] 248d05...
Dialog 113 pos  11: ...531050 [80] 531050...
```

### 0x81

**Name:** EXT_81

**Function:** Extended command with param

**Byte Count:** 2

**Status:** ? Speculative

**Total Uses:** 7

**Sample Contexts:**

```
Dialog   9 pos   3: ...070882 [81] 0acf88...
Dialog  15 pos   3: ...070882 [81] 0acf88...
Dialog  33 pos   6: ...ffff1a [81] a5c2c2...
Dialog  40 pos   3: ...070882 [81] 0acf88...
Dialog  46 pos   3: ...070882 [81] 0acf88...
```

### 0x82

**Name:** EXT_82

**Function:** Extended command with param

**Byte Count:** 2

**Status:** ? Speculative

**Total Uses:** 4

**Sample Contexts:**

```
Dialog   9 pos   2: ...0708 [82] 810acf...
Dialog  15 pos   2: ...0708 [82] 810acf...
Dialog  40 pos   2: ...0708 [82] 810acf...
Dialog  46 pos   2: ...0708 [82] 810acf...
```

### 0x83

**Total Uses:** 2

**Sample Contexts:**

```
Dialog  74 pos   5: ...46105a [83] 443244...
Dialog  74 pos  73: ...542342 [83] 441243...
```

### 0x84

**Total Uses:** 1

**Sample Contexts:**

```
Dialog 109 pos   2: ...3608 [84] 080808...
```

### 0x85

**Total Uses:** 3

**Sample Contexts:**

```
Dialog  57 pos 160: ...01085b [85] 2b6223...
Dialog  67 pos 160: ...01085b [85] 2b6223...
Dialog  74 pos 149: ...07085b [85] 2b7e2b...
```

### 0x86

**Total Uses:** 1

**Sample Contexts:**

```
Dialog  53 pos   1: ...ae [86] 2c00...
```

### 0x88

**Name:** EXT_88

**Function:** Extended command (followed by 0x10)

**Byte Count:** 2

**Status:** ? Speculative

**Total Uses:** 6

**Sample Contexts:**

```
Dialog   9 pos   6: ...810acf [88] 101d00...
Dialog  15 pos   6: ...810acf [88] 101d00...
Dialog  40 pos   6: ...810acf [88] 101d00...
Dialog  46 pos   6: ...810acf [88] 101d00...
Dialog  71 pos   0: ... [88] 05eb05...
```

### 0x89

**Total Uses:** 3

**Sample Contexts:**

```
Dialog  39 pos  10: ...52cf1b [89] ab52ce...
Dialog  71 pos   8: ...02080c [89] 05eb05...
Dialog  71 pos  21: ...020823 [89] 05eb05...
```

### 0x8A

**Total Uses:** 1

**Sample Contexts:**

```
Dialog  97 pos   1: ...05 [8A] 052005...
```

### 0x8B

**Name:** EXT_8B

**Function:** Extended command (followed by 0x05)

**Byte Count:** 2

**Status:** ? Speculative

**Total Uses:** 5

**Sample Contexts:**

```
Dialog   5 pos   1: ...05 [8B] 052468...
Dialog  17 pos   1: ...05 [8B] 052468...
Dialog  48 pos   1: ...05 [8B] 052468...
Dialog  57 pos  40: ...21440f [8B] 0e057c...
Dialog  67 pos  40: ...21440f [8B] 0e057c...
```

### 0x8D

**Name:** EXT_8D

**Function:** Extended command with param

**Byte Count:** 2

**Status:** ? Speculative

**Total Uses:** 6

**Sample Contexts:**

```
Dialog  19 pos   9: ...050604 [8D] ab053b...
Dialog  50 pos   9: ...050604 [8D] ab053b...
Dialog  90 pos   5: ...0308ac [8D] 500509...
Dialog  96 pos   4: ...fc8024 [8D] 05fd81...
Dialog  96 pos   9: ...fd8128 [8D] 09ed9b...
```

### 0x8E

**Name:** EXT_8E

**Function:** Extended command (usually 0x14)

**Byte Count:** 2

**Status:** ? Speculative

**Total Uses:** 17

**Sample Contexts:**

```
Dialog  21 pos  14: ...057f05 [8E] 149105...
Dialog  21 pos  20: ...057f05 [8E] 14910a...
Dialog  21 pos  45: ...019105 [8E] 149105...
Dialog  21 pos  51: ...057f05 [8E] 149105...
Dialog  52 pos  14: ...057f05 [8E] 149105...
```

### 0x8F

**Name:** EXT_8F

**Function:** Extended command (usually 0x30)

**Byte Count:** 2

**Status:** ? Speculative

**Total Uses:** 16

**Sample Contexts:**

```
Dialog  21 pos   8: ...019105 [8F] dc9005...
Dialog  21 pos  29: ...057f05 [8F] 309105...
Dialog  21 pos  35: ...057f05 [8F] 30910a...
Dialog  21 pos  57: ...057f05 [8F] 30910a...
Dialog  52 pos   8: ...019105 [8F] dc9005...
```

## Research Notes

### Menu Commands

User mentioned dialog contains commands for:
- Shop menu
- Inn menu
- Yes/No prompts

**Action Required:** Analyze game code to find these specific commands.

### Character Movement

Dialog can trigger character movement/positioning.

**Candidates:**
- 0x36 (PAGE) - might also trigger movement
- 0x10-0x3B range - likely event parameters

### Dialog Box Positioning

**Confirmed from DataCrystal:**
- 0x1A: Position textbox below
- 0x1B: Position textbox above

