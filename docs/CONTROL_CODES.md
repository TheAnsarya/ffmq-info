# FFMQ Control Codes Reference

**Date**: November 11, 2025  
**Status**: Research in progress - some codes confirmed, others hypothesized

---

## Overview

Final Fantasy Mystic Quest uses control codes embedded in dialog text to:
- Control text display (speed, positioning, pauses)
- Trigger game events (screen shake, music changes, character movement)
- Insert dynamic content (character names, item names)
- Control dialog flow (wait for input, clear box, new page)

This document catalogs all known and hypothesized control codes based on:
- Assembly source analysis (`src/asm/*.asm`)
- Dialog data analysis (`assets/text/dialog.asm`)
- DataCrystal/TCRF documentation
- ROM byte pattern analysis

---

## Control Code Ranges

| Range | Purpose | Count |
|-------|---------|-------|
| 0x00-0x0F | Basic text control | 16 codes |
| 0x10-0x3B | Event parameters | 44 codes |
| 0x3D-0x7E | DTE compression (not control codes) | 66 sequences |
| 0x80-0x8F | Extended control codes | 16 codes |
| 0x90-0xCD | Single characters (not control codes) | 62 chars |
| 0xCE-0xFF | Punctuation and special | 50 chars |

---

## Basic Text Control (0x00-0x0F)

### Confirmed Codes

| Code | Name | Function | Bytes | Usage Count* |
|------|------|----------|-------|--------------|
| 0x00 | [END] | String terminator | 1 | 245 |
| 0x01 | {newline} | Line break | 1 | 37 |
| 0x02 | [WAIT] | Wait for button press | 1 | 62 |
| 0x03 | [ASTERISK] | Special marker/asterisk | 1 | 60 |
| 0x04 | [NAME] | Insert character name | 1 | 24 |
| 0x05 | [ITEM] | Insert item name | 1 | 33 |
| 0x06 | [SPACE] | Space character/underscore | 1 | 40 |

*Usage count from `assets/text/dialog.asm` analysis

### Hypothesized Codes

| Code | Name | Hypothesized Function | Evidence |
|------|------|----------------------|----------|
| 0x07 | [SPEED_SLOW] | Slow text speed | complex.tbl definition |
| 0x08 | [SPEED_NORM] | Normal text speed | complex.tbl definition |
| 0x09 | [SPEED_FAST] | Fast text speed | complex.tbl definition |
| 0x0A | [DELAY] | Pause for N frames | complex.tbl definition |
| 0x0B | [UNK_0B] | Unknown | Rare in dialogs |
| 0x0C | [UNK_0C] | Unknown | Rare in dialogs |
| 0x0D | [UNK_0D] | Possibly SET_FLAG (multi-byte) | map_dialog_commands.py |
| 0x0E | [UNK_0E] | Unknown | Rare in dialogs |
| 0x0F | [UNK_0F] | Unknown | Rare in dialogs |

---

## Event Parameters (0x10-0x3B)

These codes appear to pass parameters to event handlers. Analysis shows they often appear in specific dialog contexts.

### Dialog Box Positioning

| Code | Name | Function | Confirmed | Source |
|------|------|----------|-----------|--------|
| 0x1A | [TEXTBOX_BELOW] | Position dialog box below character | ✅ | DataCrystal |
| 0x1B | [TEXTBOX_ABOVE] | Position dialog box above character | ✅ | DataCrystal |

### Special Insertions

| Code | Name | Function | Confirmed | Source |
|------|------|----------|-----------|--------|
| 0x1D | [P1D] | Character name (context-dependent) | ⚠️ | DataCrystal |
| 0x1E | [P1E] | Item name (context-dependent) | ⚠️ | DataCrystal |
| 0x1F | [CRYSTAL] | Insert "Crystal" location name | ✅ | complex.tbl |

### Dialog Flow

| Code | Name | Function | Confirmed | Source |
|------|------|----------|-----------|--------|
| 0x23 | [CLEAR] | Clear dialog box | ✅ | complex.tbl, high usage |
| 0x30 | [PARA] | Paragraph break | ✅ | complex.tbl |
| 0x36 | [PAGE] | New page/dialog box | ✅ | complex.tbl |

### Unknown Event Parameters

These codes are defined in `complex.tbl` but their exact function is unknown:

```
0x10 = [P10]  0x11 = [P11]  0x12 = [P12]  0x13 = [P13]  0x14 = [P14]
0x15 = [P15]  0x16 = [P16]  0x17 = [P17]  0x18 = [P18]  0x19 = [P19]
0x1C = [P1C]  0x20 = [P20]  0x21 = [P21]  0x22 = [P22]  0x24 = [P24]
0x25 = [P25]  0x26 = [P26]  0x27 = [P27]  0x28 = [P28]  0x29 = [P29]
0x2A = [P2A]  0x2B = [P2B]  0x2C = [P2C]  0x2D = [P2D]  0x2E = [P2E]
0x2F = [P2F]  0x31 = [P31]  0x32 = [P32]  0x33 = [P33]  0x34 = [P34]
0x35 = [P35]  0x37 = [P37]  0x38 = [P38]  0x39 = [P39]  0x3A = [P3A]
0x3B = [P3B]
```

**Hypotheses** (from event_script.py and script_editor.py analysis):
- Some may trigger character movement
- Some may control music/sound effects
- Some may trigger battle encounters
- Some may control screen effects (fade, shake, scroll)
- Some may control menu displays (shop, inn, yes/no)

---

## Extended Control Codes (0x80-0x8F)

These appear to be multi-byte commands or extended functionality codes.

| Code | Name | Hypothesized Function | Evidence |
|------|------|----------------------|----------|
| 0x80 | [C80] | Unknown extended control | Used in dialogs |
| 0x81 | [C81] | Unknown extended control | Used in dialogs |
| 0x82 | [C82] | Unknown extended control | Used in dialogs |
| 0x83 | [C83] | Unknown extended control | Used in dialogs |
| 0x84 | [C84] | Unknown extended control | Rare |
| 0x85 | [C85] | Unknown extended control | Used in dialogs |
| 0x86 | [C86] | Unknown extended control | Rare |
| 0x87 | [C87] | Unknown extended control | Rare |
| 0x88 | [C88] | Unknown extended control | Used in dialogs |
| 0x89 | [C89] | Unknown extended control | Rare |
| 0x8A | [C8A] | Unknown extended control | Used in dialogs |
| 0x8B | [C8B] | Unknown extended control | Used in dialogs |
| 0x8C | [C8C] | Unknown extended control | Used in dialogs |
| 0x8D | [C8D] | Unknown extended control | Used in dialogs |
| 0x8E | [C8E] | Unknown extended control | Used in dialogs |
| 0x8F | [C8F] | Unknown extended control | Used in dialogs |

---

## Assembly Source Evidence

### Bank $00 - Game Loop and Events

From `src/asm/bank_00_section2.asm`:
```asm
GameLoop_ProcessTimeEvents:
	; Process events that occur at specific time intervals
	; Checks status flags for various timed events
```

From `src/asm/bank_00_documented.asm`:
```asm
Execute_Script_Or_Command = $00b400
CODE_01B24C = $01b24c    ; Bank $01 script initialization routine
```

### Bank $08 - Text Engine

From `src/asm/bank_08_documented.asm`:
```asm
; CONTROL CODES DOCUMENTED:
; $f0 = END_STRING (most frequent, terminates all text)
; $f1 = NEWLINE (line breaks with spacing parameter)
; $f2 = CLEAR_WINDOW (clear box or scroll content)
; $f3 = SCROLL_TEXT (scroll with speed/distance parameter)
; $f4 = WAIT (pause for duration or player input)
; $f5 = COLOR/EFFECT (text color change, emphasis)
```

**Note**: Bank $08 uses different control code values (0xF0-0xF5) than dialog text (0x00-0x3B). This suggests:
- Bank $08 codes may be internal engine codes
- Dialog codes (0x00-0x3B) may be translated to engine codes
- Need to find the translation table in ROM

### Bank $03 - Text Box Positioning

From `~historical/temp_cycles/temp_bank03_cycle02.asm`:
```asm
; Text box positioning data with screen coordinates
; Format: [Box_Type] [X_Pos] [Y_Pos] [Width] [Height] [Flags]
db $03,$05,$E9,$07,$05,$44,$5F,$01,$08,$50,$86,$05,$18,$80,$10,$08
```

This shows dialog boxes have:
- X/Y screen coordinates
- Width/Height parameters
- Type flags (above/below/center)

---

## ROM Analysis Data

### Top Control Code Usage (from dialog.asm)

| Rank | Code | Count | % of Total | Likely Function |
|------|------|-------|------------|-----------------|
| 1 | 0x00 | 245 | 48.9% | [END] - String terminator |
| 2 | 0x02 | 62 | 12.4% | [WAIT] - Button press |
| 3 | 0x03 | 60 | 12.0% | [ASTERISK] - Special marker |
| 4 | 0x06 | 40 | 8.0% | [SPACE] - Space/underscore |
| 5 | 0x01 | 37 | 7.4% | {newline} - Line break |
| 6 | 0x05 | 33 | 6.6% | [ITEM] - Item name insert |
| 7 | 0x04 | 24 | 4.8% | [NAME] - Character name |

Total analyzed: 501 control code instances across 245 dialogs

### Context Patterns

**0x02 [WAIT] often appears**:
- At end of dialog sentences before [END]
- Before dialog box clears
- After important story revelations

**0x03 [ASTERISK] often appears**:
- In repeated patterns (likely dialog box drawing)
- Mixed with 0xFE bytes (placeholder characters)

**0x05 [ITEM] and 0x04 [NAME]**:
- Surrounded by normal text bytes
- Often near the middle of dialogs
- Example: `...text [NAME] more text...`

---

## Reverse Engineering Priorities

### HIGH Priority (Common & Critical)

1. **0x23 [CLEAR]** - Very common, affects dialog flow
2. **0x30 [PARA]** - Common, affects text layout
3. **0x36 [PAGE]** - Common, controls multi-page dialogs
4. **0x1A/0x1B** - Dialog positioning, user-visible

### MEDIUM Priority (Functional but Less Common)

5. **0x1D/0x1E/0x1F** - Variable text insertion
6. **0x07-0x0A** - Text speed/delay (UX feature)
7. **0x10-0x22** - Event parameters (gameplay)

### LOW Priority (Rare or Unknown)

8. **0x80-0x8F** - Extended codes (rare usage)
9. **0x0B-0x0F** - Unknown codes (very rare)
10. **0x24-0x3B** - Unused or rare parameters

---

## Hypothesized Multi-Byte Commands

Some control codes may require following parameter bytes.

### Evidence from ROM

**Pattern**: Control code followed by consistent byte values

```
0x1A [TEXTBOX_BELOW] → often followed by 0x00 or 0x81
0x1B [TEXTBOX_ABOVE] → often followed by 0x81 or position byte
0x0D [possible SET_FLAG] → followed by 2 parameter bytes
```

### Suggested Format

```
Single-byte:
[0x00] = END (no parameters)
[0x02] = WAIT (no parameters)

Multi-byte (1 param):
[0x1A][param] = TEXTBOX_BELOW with position param

Multi-byte (2 params):
[0x0D][param1][param2] = SET_FLAG flag_id, flag_value
```

---

## Menu and Event Integration

### Shop/Inn/Save Menus

**Hypothesis**: Some parameter codes trigger menus.

Candidates:
- **0x20-0x2F** range - May include shop/inn triggers
- **0x32-0x35** range - May include yes/no prompts

Evidence needed:
- Analyze shop dialog IDs
- Find inn dialog IDs
- Look for prompt patterns in ROM

### Character Movement

**Hypothesis**: 0x36 [PAGE] may also trigger movement.

Evidence:
- `event_script.py` defines movement commands
- `script_editor.py` shows character position control
- Assembly shows movement linked to dialog events

Candidates:
- **0x36** - Dual purpose (page + movement trigger?)
- **0x10-0x1F** - Position/direction parameters?

### Screen Effects

**Hypothesis**: Some codes trigger visual effects.

From `event_script.py`:
```python
0x53: "FLASH_SCREEN" (color, duration)
0x54: "SHAKE_SCREEN" (duration)
0x55: "FADE_OUT"
0x56: "FADE_IN"
```

These engine commands may be triggered by dialog codes in 0x10-0x3B range.

---

## Next Steps for Research

### 1. ROM Disassembly Analysis

**Target**: Find the control code dispatch table

```asm
; Expected pattern (from bank $00 or $08):
ControlCodeTable:
	.dw Handler_00  ; END
	.dw Handler_01  ; NEWLINE
	.dw Handler_02  ; WAIT
	; ... etc
```

**Tools**:
- IDA Pro / Ghidra disassembly
- Search for pointer tables in bank $00/$08
- Look for JSR/JMP indirect instructions

### 2. Dialog Context Extraction

**Create tool** to extract control code contexts:
```python
# For each control code:
#   - Which dialogs use it?
#   - What text surrounds it?
#   - What byte patterns follow it?
#   - How often in same dialog?
```

**Output**: `reports/control_code_contexts.md`

### 3. Event Script Correlation

**Cross-reference**:
- Dialog IDs with event scripts
- Map events with dialogs containing specific codes
- Find event triggers (battle, shop, movement)

### 4. ROM Patching Tests

**Method**: Modify control code values and observe effects

```
Test 1: Change 0x1A parameter → Does box position change?
Test 2: Change 0x36 usage → Does movement trigger?
Test 3: Remove 0x23 → Does box stay displayed?
```

### 5. Emulator Debugging

**Use**: Mesen2 / BSNES debugger

**Steps**:
1. Set breakpoint on text engine
2. Step through control code handling
3. Watch registers for parameter reads
4. Trace function calls

---

## References

- **Assembly Sources**: `src/asm/*.asm` (annotated disassembly)
- **Dialog Data**: `assets/text/dialog.asm` (extracted dialog bytes)
- **Analysis Reports**: `reports/dialog_asm_analysis.md`
- **DataCrystal**: https://datacrystal.tcrf.net/wiki/Final_Fantasy:_Mystic_Quest/TBL
- **TCRF**: https://tcrf.net/Final_Fantasy:_Mystic_Quest
- **Character Table**: `complex.tbl` (control code definitions)
- **Python Tools**: `tools/map-editor/utils/dialog_text.py`
- **Event Engine**: `tools/map-editor/utils/event_script.py`

---

## Confirmed vs Hypothesized Summary

| Status | Count | Percentage |
|--------|-------|------------|
| ✅ Confirmed | 13 | 14.9% |
| ⚠️ Likely | 8 | 9.2% |
| ❓ Unknown | 66 | 75.9% |
| **Total Control Codes** | **87** | **100%** |

**Progress**: Basic text control is well-understood. Event parameters need significant research.

---

## Appendix: Assembly Code Snippets

### Text Processing Loop (Bank $00)

```asm
Text_ProcessControlCode:
	and.W   #$000f  ; Mask to nibble
	cmp.W   #$0004  ; Compare to threshold
	bcs     Text_LoadCharacter ; If >= 4, process as text code
	; Check for special control codes (0-3)
	; ... code continues
```

### Dialog Box Setup (Bank $03)

```asm
; Text box configuration data:
; $03             = Box type $03 (dialog window)
; $05,$E9,$07     = SET position variable[$E9] = $07
; $05,$44,$5F,$01 = SET box width[$44][$5F] = $01
; $08,$50,$86     = CALL text routine $5086
```

---

**Last Updated**: November 11, 2025  
**Contributors**: Analysis from assembly disassembly, DataCrystal/TCRF documentation, automated ROM analysis

**Status**: Living document - will be updated as research progresses
