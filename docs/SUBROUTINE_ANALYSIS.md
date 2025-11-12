================================================================================
External Subroutine Analysis Report
Final Fantasy Mystic Quest - Control Code Handlers
================================================================================

## Overview

This report analyzes external subroutines (JSL calls) used by
control code handlers to help identify unknown code functionality.

--------------------------------------------------------------------------------
## Handler 0x08

**JSL Calls**: 3

### Subroutine $00975A

**PC Address**: $00175A
**Instructions**: 4
**Total Bytes**: 6

**Register Usage**:

**Calls Other Subroutines**:
- $97DA

**Disassembly**:
```
$00175A: 20 DA 97     JSR    $97DA
$00175D: 25           ???    
$00175E: 00           ???    
$00175F: 6B           RTL    
```

### Subroutine $00975A

**PC Address**: $00175A
**Instructions**: 4
**Total Bytes**: 6

**Register Usage**:

**Calls Other Subroutines**:
- $97DA

**Disassembly**:
```
$00175A: 20 DA 97     JSR    $97DA
$00175D: 25           ???    
$00175E: 00           ???    
$00175F: 6B           RTL    
```

### Subroutine $009776

**PC Address**: $001776
**Instructions**: 10
**Total Bytes**: 13

**Register Usage**:
- Uses Accumulator (A)

**Calls Other Subroutines**:
- $00975A

**Disassembly**:
```
$001776: 0B           ???    
$001777: F4           ???    
$001778: A8           TAY    
$001779: 0E           ???    
$00177A: 2B           ???    
$00177B: 22 5A 97 00  JSL    $00975A
$00177F: 2B           ???    
$001780: 1A           INC    
$001781: 3A           DEC    
$001782: 6B           RTL    
```

--------------------------------------------------------------------------------
## Handler 0x17

**JSL Calls**: 1

### Subroutine $009754

**PC Address**: $001754
**Instructions**: 4
**Total Bytes**: 6

**Register Usage**:

**Calls Other Subroutines**:
- $97DA

**Disassembly**:
```
$001754: 20 DA 97     JSR    $97DA
$001757: 14           ???    
$001758: 00           ???    
$001759: 6B           RTL    
```

--------------------------------------------------------------------------------
## Handler 0x23

**JSL Calls**: 1

### Subroutine $009760

**PC Address**: $001760
**Instructions**: 8
**Total Bytes**: 11

**Register Usage**:

**Calls Other Subroutines**:
- $00974E

**Disassembly**:
```
$001760: 0B           ???    
$001761: F4           ???    
$001762: A8           TAY    
$001763: 0E           ???    
$001764: 2B           ???    
$001765: 22 4E 97 00  JSL    $00974E
$001769: 2B           ???    
$00176A: 6B           RTL    
```

--------------------------------------------------------------------------------
## Handler 0x29

**JSL Calls**: 1

### Subroutine $00974E

**PC Address**: $00174E
**Instructions**: 4
**Total Bytes**: 6

**Register Usage**:

**Calls Other Subroutines**:
- $97DA

**Disassembly**:
```
$00174E: 20 DA 97     JSR    $97DA
$001751: 04           ???    
$001752: 00           ???    
$001753: 6B           RTL    
```

--------------------------------------------------------------------------------
## Handler 0x2B

**JSL Calls**: 1

### Subroutine $00976B

**PC Address**: $00176B
**Instructions**: 8
**Total Bytes**: 11

**Register Usage**:

**Calls Other Subroutines**:
- $009754

**Disassembly**:
```
$00176B: 0B           ???    
$00176C: F4           ???    
$00176D: A8           TAY    
$00176E: 0E           ???    
$00176F: 2B           ???    
$001770: 22 54 97 00  JSL    $009754
$001774: 2B           ???    
$001775: 6B           RTL    
```

--------------------------------------------------------------------------------
## Handler 0x2E

**JSL Calls**: 1

### Subroutine $009776

**PC Address**: $001776
**Instructions**: 10
**Total Bytes**: 13

**Register Usage**:
- Uses Accumulator (A)

**Calls Other Subroutines**:
- $00975A

**Disassembly**:
```
$001776: 0B           ???    
$001777: F4           ???    
$001778: A8           TAY    
$001779: 0E           ???    
$00177A: 2B           ???    
$00177B: 22 5A 97 00  JSL    $00975A
$00177F: 2B           ???    
$001780: 1A           INC    
$001781: 3A           DEC    
$001782: 6B           RTL    
```

================================================================================
End of Report
================================================================================
