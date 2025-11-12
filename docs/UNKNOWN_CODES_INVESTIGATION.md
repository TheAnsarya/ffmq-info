================================================================================
Unknown Control Code Investigation Report
Final Fantasy Mystic Quest
================================================================================

## Overview

This report investigates unknown and partially-known control codes
through usage pattern analysis, parameter detection, and comparison
with known codes.

**Investigation Methods**:
1. Usage frequency analysis
2. Parameter pattern detection
3. Context analysis (surrounding bytes)
4. Comparison with known codes
5. Hypothesis generation

--------------------------------------------------------------------------------
## Code 0x07

**Handler Name**: Dialog_Unknown07
**Handler Address**: 0x00A708

**Occurrences**: 4
**Used in Dialogs**: 4

### Parameter Analysis

**Has Parameters**: Yes
**Estimated Param Count**: 0

**Unique Values**: 6
**Value Range**: 0x08 - 0xCD

**Value Distribution**:
- Control codes (0x00-0x2F): 2 values
- Dictionary entries (0x30-0x7F): 1 values
- Extended codes (0xA0-0xFF): 3 values

### Context Samples

Sample occurrences showing surrounding bytes:

1. Dialog #6: [23 02 2B 07 23 CD 00]
2. Dialog #51: [23 02 2B 07 23 CD 00]
3. Dialog #86: [C5 CD F0 07 A5 CB 18]
4. Dialog #107: [FF 05 E6 07 08 5B 85]

### Similarity Analysis

**Similar Usage Patterns**:
- Rarely used (0x0F, 0x1B)

### HYPOTHESIS: Functionality unclear - needs emulator testing

### Recommended Next Steps

1. Create ROM test patch with this code
2. Test in emulator with memory viewer
3. Observe effects on dialog display
4. Check memory changes at common registers

--------------------------------------------------------------------------------
## Code 0x09

**Handler Name**: Dialog_Unknown09
**Handler Address**: 0x00A83F

**Occurrences**: 32
**Used in Dialogs**: 18

### Parameter Analysis

**Has Parameters**: Yes
**Estimated Param Count**: 2

**Unique Values**: 12
**Value Range**: 0x00 - 0xFB

**Value Distribution**:
- Control codes (0x00-0x2F): 2 values
- Character codes (0x80-0x9F): 3 values
- Extended codes (0xA0-0xFF): 7 values

### Context Samples

Sample occurrences showing surrounding bytes:

1. Dialog #3: [13 B1 05 09 DE F5 B4]
2. Dialog #3: [0A F5 B4 09 97 8D 00]
3. Dialog #18: [13 B1 05 09 DE F5 B4]
4. Dialog #18: [0A F5 B4 09 97 8D 00]
5. Dialog #22: [8B 0E 05 09 00]

  ... and 27 more occurrences

### Similarity Analysis

**Similar Usage Patterns**:
- Moderately used (0x02, 0x12)

### HYPOTHESES: Takes 2-byte parameter - possibly address/value

### Recommended Next Steps

1. Create ROM test patch with this code
2. Test in emulator with memory viewer
3. Observe effects on dialog display
4. Check memory changes at common registers

--------------------------------------------------------------------------------
## Code 0x0A

**Handler Name**: Dialog_Unknown0A
**Handler Address**: 0x00A519

**Occurrences**: 33
**Used in Dialogs**: 20

### Parameter Analysis

**Has Parameters**: Yes
**Estimated Param Count**: 2

**Unique Values**: 21
**Value Range**: 0x02 - 0xF5

**Value Distribution**:
- Control codes (0x00-0x2F): 7 values
- Dictionary entries (0x30-0x7F): 1 values
- Character codes (0x80-0x9F): 1 values
- Extended codes (0xA0-0xFF): 12 values

### Context Samples

Sample occurrences showing surrounding bytes:

1. Dialog #3: [11 60 01 0A F5 B4 09]
2. Dialog #5: [AD F6 0A 8D F4 0A]
3. Dialog #5: [0A 8D F4 0A E2 20 A9]
4. Dialog #5: [FF 8D B2 0A 8D B3 0A]
5. Dialog #5: [0A 8D B3 0A 8D B4 0A]

  ... and 28 more occurrences

### Similarity Analysis

**Similar Usage Patterns**:
- Moderately used (0x02, 0x12)

### HYPOTHESES: Takes 2-byte parameter - possibly address/value

### Recommended Next Steps

1. Create ROM test patch with this code
2. Test in emulator with memory viewer
3. Observe effects on dialog display
4. Check memory changes at common registers

--------------------------------------------------------------------------------
## Code 0x0B

**Handler Name**: Dialog_Unknown0B
**Handler Address**: 0x00A3F5

**Occurrences**: 27
**Used in Dialogs**: 26

### Parameter Analysis

**Has Parameters**: Yes
**Estimated Param Count**: 2

**Unique Values**: 16
**Value Range**: 0x00 - 0xFF

**Value Distribution**:
- Control codes (0x00-0x2F): 5 values
- Dictionary entries (0x30-0x7F): 3 values
- Character codes (0x80-0x9F): 1 values
- Extended codes (0xA0-0xFF): 7 values

### Context Samples

Sample occurrences showing surrounding bytes:

1. Dialog #3: [0B FF DA B4]
2. Dialog #4: [01 85 8B 0B 20 22 8F]
3. Dialog #9: [A0 68 C9 0B 90 02 A9]
4. Dialog #10: [14 10 0B 00]
5. Dialog #11: [28 60 08 0B F4 00]

  ... and 22 more occurrences

### Similarity Analysis

**Similar Usage Patterns**:
- Moderately used (0x02, 0x12)

### HYPOTHESES: Takes 2-byte parameter - possibly address/value

### Recommended Next Steps

1. Create ROM test patch with this code
2. Test in emulator with memory viewer
3. Observe effects on dialog display
4. Check memory changes at common registers

--------------------------------------------------------------------------------
## Code 0x0C

**Handler Name**: Dialog_Unknown0C
**Handler Address**: 0x00A958

**Occurrences**: 13
**Used in Dialogs**: 11

### Parameter Analysis

**Has Parameters**: Yes
**Estimated Param Count**: 0

**Unique Values**: 12
**Value Range**: 0x00 - 0xD2

**Value Distribution**:
- Control codes (0x00-0x2F): 8 values
- Dictionary entries (0x30-0x7F): 2 values
- Extended codes (0xA0-0xFF): 2 values

### Context Samples

Sample occurrences showing surrounding bytes:

1. Dialog #1: [05 35 1A 0C 0D 00]
2. Dialog #7: [46 41 1F 0C D2 36 2C]
3. Dialog #16: [41 18 C6 0C 00]
4. Dialog #23: [42 18 C6 0C 00]
5. Dialog #31: [41 18 C6 0C 00]

  ... and 8 more occurrences

### Similarity Analysis

**Similar Usage Patterns**:
- Moderately used (0x02, 0x12)

### HYPOTHESIS: Functionality unclear - needs emulator testing

### Recommended Next Steps

1. Create ROM test patch with this code
2. Test in emulator with memory viewer
3. Observe effects on dialog display
4. Check memory changes at common registers

--------------------------------------------------------------------------------
## Code 0x0D

**Handler Name**: Dialog_Unknown0D
**Handler Address**: 0x00A96C

**Occurrences**: 8
**Used in Dialogs**: 7

### Parameter Analysis

**Has Parameters**: Yes
**Estimated Param Count**: 0

**Unique Values**: 9
**Value Range**: 0x00 - 0xDF

**Value Distribution**:
- Control codes (0x00-0x2F): 5 values
- Dictionary entries (0x30-0x7F): 2 values
- Extended codes (0xA0-0xFF): 2 values

### Context Samples

Sample occurrences showing surrounding bytes:

1. Dialog #1: [35 1A 0C 0D 00]
2. Dialog #52: [2F 05 0D 04 DF C2]
3. Dialog #56: [B8 B7 D2 0D 5F 01 00]
4. Dialog #60: [B8 B7 D2 0D 5F 01 00]
5. Dialog #62: [0D B4 00]

  ... and 3 more occurrences

### Similarity Analysis

**Similar Usage Patterns**:
- Rarely used (0x0F, 0x1B)

### HYPOTHESIS: Functionality unclear - needs emulator testing

### Recommended Next Steps

1. Create ROM test patch with this code
2. Test in emulator with memory viewer
3. Observe effects on dialog display
4. Check memory changes at common registers

================================================================================
## Investigation Summary

**Unknown Codes Investigated**: 6
**Codes With Usage**: 6
**Unused Codes**: 0

### Priority Investigation List

Based on usage frequency, prioritize investigation in this order:

1. Code 0x0A: 33 occurrences - HIGH PRIORITY
2. Code 0x09: 32 occurrences - HIGH PRIORITY
3. Code 0x0B: 27 occurrences - HIGH PRIORITY
4. Code 0x0C: 13 occurrences - HIGH PRIORITY
5. Code 0x0D: 8 occurrences - HIGH PRIORITY
6. Code 0x07: 4 occurrences - HIGH PRIORITY

================================================================================
End of Report
================================================================================
