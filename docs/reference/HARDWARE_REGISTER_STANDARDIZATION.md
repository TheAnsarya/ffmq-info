# SNES Hardware Register Name Standardization
**Issue**: #7  
**Date**: November 2, 2025  
**Status**: 🔄 IN PROGRESS

---

## 📋 OVERVIEW

This document tracks the standardization of all SNES hardware register references to use symbolic names instead of numeric addresses.

**Goal**: Replace all `$21xx`, `$42xx`, `$43xx` numeric references with `SNES_REGISTERNAME` symbolic constants.

---

## 🎯 REGISTER MAPPINGS

### PPU Registers ($2100-$213F)

| Address | Current | Standard Name | Description |
|---------|---------|---------------|-------------|
| $2100 | ✅ SNES_INIDISP | SNES_INIDISP | Display control |
| $2101 | ❌ $2101 | SNES_OBSEL | OBJ size & chr base |
| $2102 | ❌ $2102 | SNES_OAMADDL | OAM address low |
| $2103 | ❌ $2103 | SNES_OAMADDH | OAM address high |
| $2104 | - | SNES_OAMDATA | OAM data write |
| $2105 | - | SNES_BGMODE | BG mode & chr size |
| $2106 | ❌ $2106 | SNES_MOSAIC | Mosaic control |
| $2107 | ❌ $2107 | SNES_BG1SC | BG1 tilemap address |
| $2108 | ❌ $2108 | SNES_BG2SC | BG2 tilemap address |
| $2109 | - | SNES_BG3SC | BG3 tilemap address |
| $210A | - | SNES_BG4SC | BG4 tilemap address |
| $210B | - | SNES_BG12NBA | BG1/2 chr address |
| $210C | - | SNES_BG34NBA | BG3/4 chr address |
| $210D | - | SNES_BG1HOFS | BG1 H scroll |
| $210E | - | SNES_BG1VOFS | BG1 V scroll |
| $210F | ❌ $210F | SNES_BG2HOFS | BG2 H scroll |
| $2110 | - | SNES_BG2VOFS | BG2 V scroll |
| $2111 | - | SNES_BG3HOFS | BG3 H scroll |
| $2112 | - | SNES_BG3VOFS | BG3 V scroll |
| $2113 | - | SNES_BG4HOFS | BG4 H scroll |
| $2114 | - | SNES_BG4VOFS | BG4 V scroll |
| $2115 | ❌ $2115 | SNES_VMAIN | VRAM inc mode |
| $2116 | ❌ $2116 | SNES_VMADDL | VRAM address low |
| $2117 | - | SNES_VMADDH | VRAM address high |
| $2118 | ❌ $2118 | SNES_VMDATAL | VRAM data write low |
| $2119 | ❌ $2119 | SNES_VMDATAH | VRAM data write high |
| $211A | - | SNES_M7SEL | Mode 7 settings |
| $211B | ❌ $211B | SNES_M7A | Mode 7 matrix A |
| $211C | ❌ $211C | SNES_M7B | Mode 7 matrix B |
| $211D | - | SNES_M7C | Mode 7 matrix C |
| $211E | - | SNES_M7D | Mode 7 matrix D |
| $211F | - | SNES_M7X | Mode 7 center X |
| $2120 | - | SNES_M7Y | Mode 7 center Y |
| $2121 | ❌ $2121 | SNES_CGADD | CGRAM address |
| $2122 | ❌ $2122 | SNES_CGDATA | CGRAM data write |
| $2123 | ❌ $2123 | SNES_W12SEL | Window 1/2 mask BG1/2 |
| $2124 | ❌ $2124 | SNES_W34SEL | Window 3/4 mask BG3/4 |
| $2125 | ❌ $2125 | SNES_WOBJSEL | Window mask OBJ/color |
| $2126 | - | SNES_WH0 | Window 1 left |
| $2127 | ❌ $2127 | SNES_WH1 | Window 1 right |
| $2128 | - | SNES_WH2 | Window 2 left |
| $2129 | ❌ $2129 | SNES_WH3 | Window 2 right |
| $212A | - | SNES_WBGLOG | Window mask logic BG |
| $212B | - | SNES_WOBJLOG | Window mask logic OBJ |
| $212C | ❌ $212C | SNES_TM | Main screen enable |
| $212D | ❌ $212D | SNES_TS | Subscreen enable |
| $212E | - | SNES_TMW | Window main enable |
| $212F | - | SNES_TSW | Window sub enable |
| $2130 | ❌ $2130 | SNES_CGWSEL | Color math control |
| $2131 | ❌ $2131 | SNES_CGADSUB | Color math enable |
| $2132 | - | SNES_COLDATA | Fixed color data |
| $2133 | - | SNES_SETINI | Screen mode select |

### WRAM Registers ($2180-$2183)

| Address | Current | Standard Name | Description |
|---------|---------|---------------|-------------|
| $2180 | ❌ $2180 | SNES_WMDATA | WRAM data |
| $2181 | ❌ $2181 | SNES_WMADDL | WRAM address low |
| $2182 | - | SNES_WMADDM | WRAM address mid |
| $2183 | ❌ $2183 | SNES_WMADDH | WRAM address high |

### DMA Registers ($4300-$437F)

| Address | Current | Standard Name | Description |
|---------|---------|---------------|-------------|
| $4300 | - | SNES_DMAP0 | DMA0 control |
| $4301 | - | SNES_BBAD0 | DMA0 dest address |
| $4302 | - | SNES_A1T0L | DMA0 source low |
| $4303 | - | SNES_A1T0H | DMA0 source high |
| $4304 | - | SNES_A1B0 | DMA0 source bank |
| $4305 | - | SNES_DAS0L | DMA0 size low |
| $4306 | - | SNES_DAS0H | DMA0 size high |
| ... | - | (repeat for channels 1-7) | |

---

## 📊 ANALYSIS RESULTS

### Found Numeric References

**Bank 02** (bank_02.asm):
- $2121 (CGRAM address) - 3 occurrences
- $2122 (CGRAM data) - 6 occurrences  
- $2183 (WRAM address high) - 4 occurrences
- $2180 (WRAM data) - 7 occurrences
- $2181 (WRAM address low) - 1 occurrence
- $2127 (Window) - 1 occurrence
- $2129 (Window) - 1 occurrence
- $2123-$2125 (Window masks) - 3 occurrences
- $2130 (Color math) - 1 occurrence
- $2106 (Mosaic) - 1 occurrence
- $2101 (OBJ select) - 1 occurrence
- $2116 (VRAM address) - 2 occurrences
- $2115 (VRAM mode) - 2 occurrences
- $2103 (OAM address high) - 1 occurrence
- $2102 (OAM address low) - 1 occurrence
- $210F (BG2 H scroll) - 1 occurrence

**Bank 0B** (bank_0B.asm):
- $211B (Mode 7 matrix A) - 6 occurrences
- $211C (Mode 7 matrix B) - 5 occurrences
- $2107 (BG1 tilemap) - 1 occurrence
- $2108 (BG2 tilemap) - 1 occurrence
- $212C (Main screen) - 1 occurrence
- $212D (Subscreen) - 1 occurrence
- $2130 (Color math control) - 1 occurrence
- $2131 (Color math enable) - 1 occurrence

**Bank 0C** (bank_0C.asm):
- $2119 (VRAM data high) - 1 occurrence
- $2118 (VRAM data low) - 1 occurrence
- $2115 (VRAM mode) - 1 occurrence

**Total Found**: ~50+ numeric references across banks

---

## 🛠️ IMPLEMENTATION PLAN

### Step 1: Create Hardware Register Definitions File ✅

Create `src/asm/includes/hardware.inc` with all SNES register definitions.

### Step 2: Include in Main Assembly File

Add to `src/asm/ffmq_working.asm`:
```asm
incsrc "includes/hardware.inc"
```

### Step 3: Create Replacement Script

PowerShell script to replace numeric addresses with symbolic names:

```powershell
# tools/standardize_registers.ps1
$mappings = @{
    'sta.W $2101' = 'sta.W SNES_OBSEL'
    'sta.W $2102' = 'sta.W SNES_OAMADDL'
    'sta.W $2103' = 'sta.W SNES_OAMADDH'
    # ... (all mappings)
}
```

### Step 4: Apply to Each Bank

- Apply to bank_02.asm first (most references)
- Verify ROM match
- Apply to bank_0B.asm
- Verify ROM match
- Apply to bank_0C.asm
- Verify ROM match
- Apply to remaining banks

### Step 5: Commit

Individual commits per bank with verification.

---

## ✅ PROGRESS TRACKING

- [ ] Create hardware.inc definitions file
- [ ] Add include to main assembly
- [ ] Create replacement script
- [ ] Apply to bank_02.asm (36 replacements)
- [ ] Verify build after bank_02
- [ ] Apply to bank_0B.asm (16 replacements)
- [ ] Verify build after bank_0B
- [ ] Apply to bank_0C.asm (3 replacements)
- [ ] Verify build after bank_0C
- [ ] Scan remaining banks for numeric references
- [ ] Final build verification
- [ ] Update documentation

---

## 📝 NOTES

- Most registers already use symbolic names (SNES_INIDISP, etc.)
- Only a subset needs conversion (~50-100 references total)
- Critical: Must preserve exact byte output for ROM match
- Some addresses may be intentionally numeric (data tables, etc.)
- Focus on instruction operands, not data/comments

**Last Updated**: November 2, 2025  
**Status**: Ready to implement
