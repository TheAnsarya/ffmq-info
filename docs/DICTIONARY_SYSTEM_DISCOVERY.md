# CRITICAL FINDING: FFMQ Dialog System Architecture

**Date**: 2025-01-24  
**Discovery**: Dialog text uses a DICTIONARY system, not simple DTE compression

---

## Summary

The garbled dialog output was caused by **fundamental misunderstanding of the text compression system**. FFMQ does NOT use simple Dual-Tile Encoding (DTE). Instead, it uses a **dictionary-based compression system** where bytes 0x30-0x7F reference pre-stored strings.

---

## Dialog Byte Structure (CONFIRMED)

Based on assembly analysis of `Dialog_WriteCharacter` at `$00:9DC1-9DD2`:

```asm
cmp.W #$0080           ; Compare byte with 0x80
bcc Dialog_ProcessCommand  ; If < 0x80, process as command
; else: fall through to write as character (>= 0x80)

Dialog_ProcessCommand:
cmp.W #$0030           ; Compare with 0x30
bcs Dialog_ProcessCommand_TextReference  ; If >= 0x30, it's dictionary reference
; else: direct command code (< 0x30)
```

### Byte Ranges

| Range | Type | Handler | Description |
|-------|------|---------|-------------|
| **0x00-0x2F** | Control Codes | Jump table at `$00:9E0E` | Direct commands (END, WAIT, NEWLINE, etc.) |
| **0x30-0x7F** | Dictionary References | `DATA8_03ba35` lookup | String substitution from bank $03 dictionary |
| **0x80-0xFF** | Direct Characters | Write to screen buffer | Single characters (letters, punctuation, space=0xFF) |

---

## Dictionary System

### Dictionary Location

**SNES Address**: `$03:BA35`  
**PC Address**: `0x01BA35`  
**Format**: Length-prefixed strings (1 byte length + N bytes encoded text)

### Dictionary Entry Format

```
[LENGTH] [BYTE1] [BYTE2] ... [BYTEN]
```

- `LENGTH`: Number of bytes in string (1-255)
- `BYTE1-N`: Encoded characters using:
  - 0x00-0x2F: Control codes
  - 0x30-0x7F: **Recursive dictionary references** (!)
  - 0x80-0xFF: Direct characters

**CRITICAL**: Dictionary strings can contain OTHER dictionary references, requiring recursive expansion!

### Example Dictionary Entries

From PC 0x01BA35:
```
03 08 0E A8     = Length 3: bytes [08, 0E, A8]
03 08 E7 83     = Length 3: bytes [08, E7, 83]
0A 0D 44 00 FF FF 0D 46 00 00 00 = Length 10: [0D, 44, 00, FF, FF, 0D, 46, 00, 00, 00]
```

---

## Assembly Code Analysis

### Dialog_ProcessCommand_TextReference (0x009DDF)

```asm
Dialog_ProcessCommand_TextReference:
	ldx.W #$0000
	sbc.W #$0030              ; Subtract 0x30 to get dictionary index
	beq Dialog_ProcessCommand_TextReference_Jump
	tay
Dialog_ProcessCommand_TextReference_Loop:
	lda.L DATA8_03ba35,x      ; Read length byte from dictionary
	and.W #$00ff
	sta.B $64
	txa
	sec
	adc.B $64                 ; Advance by length+1 (skip to next entry)
	tax
	dey
	bne Dialog_ProcessCommand_TextReference_Loop
Dialog_ProcessCommand_TextReference_Jump:
	txa
	clc
	adc.W #$ba36              ; Add base + 1 (skip past length byte)
	tay
	sep #$20
	lda.B #$03                ; Bank $03
	xba
	lda.L DATA8_03ba35,x      ; Get length
	tyx
	rep #$30
	jmp.W Dialog_ExecuteNestedCall
```

**What this does**:
1. Subtract 0x30 from byte value to get dictionary index (0-79 for bytes 0x30-0x7F)
2. Walk through dictionary table to find Nth entry (each entry = length + data)
3. Execute the dictionary entry's bytes (which may contain more references!)

---

## Why complex.tbl Was Wrong

The `complex.tbl` file attempted to map bytes 0x30-0x7F to text strings directly:

```
40=e 
41=the 
42=t 
4C=he
```

This was **GUESSING** based on English text patterns. But these bytes don't directly represent text - they're **indices into a dictionary table** that must be looked up and expanded.

**Correct Process**:
1. Read byte 0x40 from dialog
2. Subtract 0x30 → index 0x10 (16 decimal)
3. Look up entry #16 in dictionary at $03:BA35
4. Expand that entry (which may recursively reference other dictionary entries)
5. Decode final bytes as characters (0x80-0xFF) from simple.tbl

---

## Simple.tbl vs Dictionary

### simple.tbl (CORRECT)

Maps bytes 0x80-0xFF to single characters:

```
91=1
9A=A
9B=B
A6=a
A8=c
B4=r
B5=y
B6=s
B7=t
B8=n
B9=d
...
FF= (space)
```

**These mappings are VERIFIED and CORRECT** - simple text (items, spells, monsters) decodes perfectly.

### Dictionary (NEEDS EXTRACTION)

Maps bytes 0x30-0x7F to compressed strings stored at $03:BA35. Each entry can contain:
- Control codes (0x00-0x2F)
- Other dictionary references (0x30-0x7F) - **recursive!**
- Direct characters (0x80-0xFF)

---

## Next Steps

1. **Extract Dictionary Table**:
   - Parse all 80 entries (0x30-0x7F) from PC 0x01BA35
   - Decode each entry recursively
   - Generate correct mapping table

2. **Update Decoder**:
   - Implement recursive dictionary expansion
   - Handle mixed control codes + text + dictionary references
   - Validate against known dialogs

3. **Generate complex.tbl**:
   - Replace current guesswork with actual dictionary contents
   - Document which entries are text vs commands vs recursive

4. **Verify**:
   - Test dialog 0x59: "For years Mac's been studying a Prophecy"
   - Validate all 117 dialogs decode correctly

---

## Impact

This discovery explains:
- ✅ Why dialog output was garbled (wrong byte → text mapping)
- ✅ Why DataCrystal updates didn't help (they also guessed)
- ✅ Why byte frequency analysis gave weird results (mixing dictionary indices with direct chars)
- ✅ Why 0xFF appears 290 times (it's space, most common character)
- ✅ Why some text decoded correctly (direct characters 0x80+ from simple.tbl)

**This completely changes the approach to todo #3 (DTE table reverse-engineering)**. We don't need to fix "DTE mappings" - we need to **extract the dictionary table** from ROM and implement **recursive expansion**.

---

## Files to Update

- [ ] `tools/extraction/extract_text.py` - Add dictionary expansion
- [ ] `complex.tbl` - Replace with actual dictionary contents (or remove entirely)
- [ ] `docs/TEXT_SYSTEMS_ANALYSIS.md` - Document dictionary system
- [ ] `tools/analysis/analyze_dialog_bytes.py` - Update to use dictionary
- [ ] `verify_dte_table.py` - Rename to `verify_dictionary.py`, implement recursive decoder
