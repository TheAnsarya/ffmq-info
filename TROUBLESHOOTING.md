# FFMQ Build Troubleshooting Guide

Quick reference for resolving common build issues.

**Last Updated**: November 1, 2025

---

## Quick Diagnostics

### Build Fails Immediately

```powershell
# Check if asar is accessible
asar --version

# Expected: Asar 1.81 or later
# If command not found, add asar to PATH or use full path
```

### Build Succeeds but ROM Doesn't Match

```powershell
# Run round-trip test
.\test-roundtrip.ps1

# Check for first difference
fc /b "roms\ffmq-original.sfc" "ffmq - onlygood.sfc" | Select-Object -First 5
```

### ROM Won't Run in Emulator

```powershell
# Verify ROM format (.sfc, not .smc)
(Get-Item "ffmq - onlygood.sfc").Length
# Should be exactly 1048576 bytes

# Check for SMC header (512 bytes extra = .smc format)
# If 1049088 bytes, remove first 512 bytes
```

---

## Error Messages

### "asar: command not found" / "asar is not recognized"

**Problem**: Asar assembler not in system PATH

**Solutions**:

```powershell
# Option 1: Check if asar exists
where.exe asar

# Option 2: Add to PATH (Windows)
# 1. Extract asar.exe to C:\asar\
# 2. Add C:\asar\ to system PATH:
#    System Properties → Environment Variables → Path → New → C:\asar\

# Option 3: Use full path in build script
C:\asar\asar.exe "ffmq - onlygood.asm"

# Option 4: Copy asar.exe to project directory
Copy-Item "C:\path\to\asar.exe" -Destination "."
```

---

### "unknown command org" or "invalid syntax"

**Problem**: Asar version too old (pre-1.60)

**Solutions**:

```powershell
# Check current version
asar --version

# If older than 1.81:
# 1. Download latest from https://www.smwcentral.net/?p=section&a=details&id=19043
# 2. Replace old asar.exe
# 3. Verify:
asar --version  # Should show 1.81 or later
```

---

### "can't open 'filename.inc'" or "file not found"

**Problem**: Include file path incorrect

**Solutions**:

1. **Check file exists**:
   ```powershell
   Test-Path "src\include\filename.inc"
   ```

2. **Verify include path in .asm**:
   ```asm
   ; Paths are relative to main .asm file location
   incsrc "src/include/filename.inc"  ; CORRECT (forward slashes)
   incsrc "src\include\filename.inc"  ; May fail on some systems
   ```

3. **Case sensitivity**:
   ```asm
   ; Windows is case-insensitive but preserve correct case
   incsrc "src/include/SNES_Registers.inc"  ; If file is uppercase
   ```

4. **Check for typos**:
   ```powershell
   # List all include files
   Get-ChildItem -Recurse -Filter "*.inc"
   ```

---

### "label 'xyz' already defined"

**Problem**: Duplicate label definition

**Solutions**:

1. **Find duplicate labels**:
   ```powershell
   # Search for label in all files
   Get-ChildItem -Recurse -Include *.asm,*.inc | Select-String "^label_name:"
   ```

2. **Use local labels**:
   ```asm
   ; Global label
   main_routine:
       ; code
   .local_loop:     ; Local to main_routine
       ; code
       bra .local_loop
   
   other_routine:
   .local_loop:     ; Different scope, no conflict
       ; code
   ```

3. **Use unique prefixes**:
   ```asm
   ; Bank-specific prefixes
   bank00_routine:
   bank01_routine:
   
   ; System-specific prefixes
   graphics_init:
   battle_init:
   ```

---

### "ROM size mismatch" / "org out of bounds"

**Problem**: Assembly produces wrong ROM size

**Solutions**:

1. **Check org directives**:
   ```asm
   ; LoROM bank layout
   org $008000  ; Bank $00
   ; ...
   org $018000  ; Bank $01 (NOT $010000)
   ; ...
   org $028000  ; Bank $02 (NOT $020000)
   ```

2. **Verify bank boundaries**:
   ```asm
   ; Each bank is 32KB (0x8000 bytes)
   org $008000
   ; ... code up to $00FFFF
   
   org $018000  ; Next bank
   ```

3. **Check for missing fills**:
   ```asm
   ; Fill unused space to maintain ROM size
   org $00FF00
   ; ... some code
   
   ; Fill rest of bank
   pad $010000  ; Fill to end of bank
   ```

4. **Verify ROM size**:
   ```powershell
   (Get-Item "ffmq - onlygood.sfc").Length
   # Should be 1048576 bytes (1 MB)
   ```

---

### "macro 'xyz' not found"

**Problem**: Macro not defined or include missing

**Solutions**:

1. **Check macro definition file is included**:
   ```asm
   incsrc "macros.inc"  ; Must come before macro usage
   
   ; Then use macro
   %SomeM macro()
   ```

2. **Verify macro syntax**:
   ```asm
   ; Definition
   macro DefineMacro(param1, param2)
       lda #<param1>
       sta <param2>
   endmacro
   
   ; Usage
   %DefineMacro($42, $00)
   ```

3. **Check include order**:
   ```asm
   ; Includes must be in correct order
   incsrc "defines.inc"     ; Constants first
   incsrc "macros.inc"      ; Macros second
   incsrc "main_code.asm"   ; Code that uses macros last
   ```

---

## ROM Comparison Issues

### "FC: no differences encountered" but ROM doesn't work

**Problem**: ROM is byte-perfect but has runtime issues

**Possible Causes**:

1. **Emulator cache**: Clear emulator save states and cache
   ```powershell
   # Mesen-S cache location:
   Remove-Item "$env:APPDATA\Mesen-S\SaveStates\*" -Force
   Remove-Item "$env:APPDATA\Mesen-S\Saves\*" -Force
   ```

2. **Wrong ROM region**: Ensure emulator is set to NTSC/USA
   ```
   Mesen → Settings → Region → Auto-detect or NTSC
   ```

3. **Corrupted build**: Try clean rebuild
   ```powershell
   Remove-Item "*.sfc"
   asar "ffmq - onlygood.asm"
   ```

---

### Bytes differ at specific offset

**Problem**: Round-trip test shows mismatches

**Debugging Steps**:

1. **Find offset in source**:
   ```powershell
   # Example: fc shows difference at 0001A3C0
   $offset = 0x1A3C0
   
   # Convert to LoROM bank:address
   $bank = [math]::Floor($offset / 0x8000)
   $addr = ($offset % 0x8000) + 0x8000
   
   Write-Host "Bank: `$$($bank.ToString('X2'))"
   Write-Host "Address: `$$($addr.ToString('X4'))"
   ```

2. **Compare with hex editor**:
   - Open both ROMs in hex editor
   - Navigate to offset
   - Compare surrounding bytes for context

3. **Check source at that location**:
   ```asm
   ; Find corresponding org in source
   org $038000  ; If bank $03, address $A3C0 → org $03A3C0
   ; Check data definition at this point
   ```

4. **Common mismatch causes**:
   ```asm
   ; Wrong data type
   db $1234  ; WRONG: Only stores $34
   dw $1234  ; CORRECT: Stores $34, $12 (little-endian)
   
   ; Missing data
   db $01, $02, $03  ; Missing $04?
   
   ; Wrong endianness
   dw $1234  ; Stores as $34, $12 (little-endian is correct for SNES)
   ```

---

### Size matches but many bytes differ

**Problem**: Fundamental assembly issue

**Likely Causes**:

1. **Wrong base ROM**: Building from different version
   ```powershell
   # Verify original ROM MD5
   (Get-FileHash "roms\ffmq-original.sfc" -Algorithm MD5).Hash
   # USA version: E7B3C4D5... (check actual hash)
   ```

2. **Incorrect compression**: Compressed data differs
   ```asm
   ; Ensure compressed data is extracted and included correctly
   incbin "assets/graphics/compressed_tiles.bin"
   ```

3. **Wrong assembler**: Not using Asar
   ```powershell
   # Verify using Asar
   asar --version
   # Not bass, xkas, or other assemblers
   ```

---

## Build Performance Issues

### Very slow builds (>10 seconds)

**Problem**: Build takes unusually long

**Solutions**:

1. **Check antivirus exclusion**:
   ```
   Add project directory to antivirus exclusion list
   Windows Defender → Settings → Exclusions → Add folder
   ```

2. **Use SSD not HDD**:
   ```powershell
   # Check drive type
   Get-PhysicalDisk | Select-Object FriendlyName, MediaType
   ```

3. **Check for circular includes**:
   ```asm
   ; file1.asm
   incsrc "file2.asm"
   
   ; file2.asm
   incsrc "file1.asm"  ; WRONG: Circular dependency
   ```

4. **Simplify complex macros**:
   ```asm
   ; Instead of deeply nested macro calls
   ; Inline the code or simplify macro logic
   ```

---

### Out of memory errors

**Problem**: Asar runs out of memory during assembly

**Solutions**:

1. **Split large files**:
   ```asm
   ; Instead of one huge file:
   ; bank_00_all.asm (50,000 lines)
   
   ; Split into:
   ; bank_00_main.asm
   incsrc "bank_00_graphics.asm"
   incsrc "bank_00_logic.asm"
   incsrc "bank_00_data.asm"
   ```

2. **Reduce macro complexity**:
   ```asm
   ; Avoid recursive macros or huge expansions
   ```

3. **Update Asar**:
   ```powershell
   # Newer versions have better memory management
   asar --version  # Update if < 1.81
   ```

---

## Runtime Issues

### ROM runs but crashes immediately

**Debugging Steps**:

1. **Check reset vector**:
   ```asm
   ; Reset vector should be at $00FFFC-$00FFFD
   org $00FFFC
   dw reset_routine  ; Ensure correct address
   ```

2. **Verify initialization code**:
   ```asm
   ; First code executed should:
   sei          ; Disable interrupts
   clc
   xce          ; Switch to native mode
   ; ... proper SNES initialization
   ```

3. **Check bank mapping**:
   ```asm
   ; Ensure LoROM banking is correct
   ; Bank $00 code must be at $008000, not $000000
   ```

---

### ROM runs but has graphical glitches

**Common Causes**:

1. **Wrong graphics format**:
   ```asm
   ; Ensure 2bpp or 4bpp format matches original
   incbin "tiles.bin"  ; Check format
   ```

2. **Incorrect palette data**:
   ```asm
   ; SNES uses 15-bit BGR format
   ; $00,$01 → Color: 0bbbbbgggggrrrrr
   ```

3. **Wrong VRAM addresses**:
   ```asm
   ; Check VRAM write addresses in code
   lda #$2000
   sta $2116  ; VMADD low
   lda #$00
   sta $2117  ; VMADD high
   ```

---

### ROM runs but text is garbled

**Common Causes**:

1. **Wrong text encoding**:
   ```asm
   ; FFMQ uses DTE (Dual Tile Encoding)
   ; Ensure text is properly encoded
   ```

2. **Missing font data**:
   ```asm
   ; Verify font tiles are loaded
   incbin "font.bin"
   ```

3. **Incorrect text pointers**:
   ```asm
   ; Text pointer table must point to correct locations
   dw text_string_00
   dw text_string_01
   ```

---

## Advanced Debugging

### Using Mesen-S Debugger

1. **Set breakpoint at mismatch offset**:
   ```
   Debugger → Breakpoints → Add
   Type: Execute
   Address: $038000 (example)
   ```

2. **Compare CPU state**:
   - Run original ROM to breakpoint
   - Note CPU registers (A, X, Y, etc.)
   - Run built ROM to same point
   - Compare states

3. **Memory watch**:
   ```
   Add memory watches for variables that differ
   Track when they change
   ```

### Binary diffing tools

```powershell
# Use binary diff tool for detailed comparison
# Example with WinMerge (if installed)
"C:\Program Files\WinMerge\WinMergeU.exe" `
    "roms\ffmq-original.sfc" "ffmq - onlygood.sfc"
```

### Hex editor comparison

1. Open both ROMs in hex editor (HxD recommended)
2. Use Compare function
3. Find first difference
4. Look for patterns in differences
5. Cross-reference with source code

---

## Preventive Measures

### Before Making Changes

```powershell
# 1. Ensure current build is clean
.\test-roundtrip.ps1

# 2. Create backup
Copy-Item "ffmq - onlygood.asm" "ffmq - onlygood.asm.bak"

# 3. Note current state
git status
git diff
```

### After Making Changes

```powershell
# 1. Rebuild
asar "ffmq - onlygood.asm"

# 2. Test
.\test-roundtrip.ps1

# 3. If tests pass, commit
git add .
git commit -m "Description of changes"
```

### Regular Validation

```powershell
# Run full test suite periodically
# 1. Round-trip test
.\test-roundtrip.ps1

# 2. Verify all banks assembled
# 3. Check ROM header
# 4. Test in emulator
```

---

## Getting Help

### Information to Provide

When seeking help, include:

1. **Asar version**: `asar --version`
2. **Error message**: Full text of error
3. **File sizes**: Original vs built ROM sizes
4. **Offset of difference**: From `fc` or hex editor
5. **Relevant source code**: Lines around the problematic area
6. **What you've tried**: Steps already attempted

### Useful Commands for Diagnostics

```powershell
# System info
$PSVersionTable
Get-ComputerInfo | Select-Object WindowsVersion

# Asar info
asar --version
where.exe asar

# File info
Get-Item "*.sfc" | Select-Object Name, Length, LastWriteTime
Get-FileHash "ffmq - onlygood.sfc" -Algorithm MD5

# Difference location
fc /b "roms\ffmq-original.sfc" "ffmq - onlygood.sfc" | Select-Object -First 20
```

---

## Common Modifications and Their Pitfalls

### Changing Text

**Pitfall**: Text longer than original won't fit

**Solution**:
```asm
; Check original text length
; Original: "Hi" (2 bytes + terminator)
; New: "Hello" (5 bytes + terminator)
; Won't fit in same space!

; Option 1: Shorten text
"Hi!" (3 bytes)

; Option 2: Move to free space
org $03F800  ; Free space in bank $03
NewText:
    db "Hello", $00
; Update pointer to NewText
```

### Changing Graphics

**Pitfall**: Wrong tile format

**Solution**:
```asm
; SNES tiles can be 2bpp (4 colors) or 4bpp (16 colors)
; Check original format before replacing
; 2bpp: 16 bytes per 8x8 tile
; 4bpp: 32 bytes per 8x8 tile
```

### Adding New Code

**Pitfall**: Overwriting existing data

**Solution**:
```asm
; Check if area is free first
; Use pad to ensure you don't exceed bank
org $00F000  ; Start of new code
NewRoutine:
    ; code
pad $010000  ; Ensure we don't exceed bank boundary
```

---

## Related Documentation

- **BUILD_GUIDE.md**: Complete build system documentation
- **README.md**: Project overview
- **docs/ARCHITECTURE.md**: System architecture
- **test-roundtrip.ps1**: Automated testing script

---

*Last Updated: November 1, 2025*
