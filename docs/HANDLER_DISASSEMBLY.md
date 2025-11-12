================================================================================
Control Code Handler Disassembly
Final Fantasy Mystic Quest - Complete Handler Documentation
================================================================================

## Overview

This document contains the complete disassembled code for all 48 control
code handlers (0x00-0x2F) used in the dialog rendering system.

**Jump Table Location**: 0x009E0E (ROM 0x001E0E)

--------------------------------------------------------------------------------
## Basic Control Codes (0x00-0x06)

### Code 0x00: Dialog_End

**Address**: 0x00A378
**Description**: END - Sets bit to signal dialog end
**Assembly Label**: `Cutscene_ProcessScroll_Finish`

```asm
	lda.W #$0080                         ;00A378|A98000  |      ;
	tsb.W $00d0                          ;00A37B|0CD000  |0000D0;
	rts                                  ;00A37E|60      |      ;
```

**Analysis**:
- Sets/clears bitflags
- Sets bit 0x80 in $00D0 to signal dialog end

### Code 0x01: Dialog_Newline

**Address**: 0x00A8C0
**Description**: NEWLINE - Advance to next line
**Assembly Label**: `Text_CalculateDisplayPosition`

```asm
	lda.W #$003e                         ;00A8C0|A93E00  |      ;
	trb.B $1a                            ;00A8C3|141A    |00001A;
	lsr a;00A8C5|4A      |      ;
	and.B $25                            ;00A8C6|2525    |000025;
	asl a;00A8C8|0A      |      ;
	ora.B $1a                            ;00A8C9|051A    |00001A;
	adc.W #$0040                         ;00A8CB|694000  |      ;
	sta.B $1a                            ;00A8CE|851A    |00001A;
	rts                                  ;00A8D0|60      |      ;
```

**Analysis**:
- Modifies memory/state
- Sets/clears bitflags

### Code 0x02: Dialog_Wait

**Address**: 0x00A8BD
**Description**: WAIT - Wait for user input

```asm
	jsr.W Text_CalculateDisplayPosition                    ;00A8BD|20C0A8  |00A8C0;
;      |        |      ;
```

**Analysis**:
- Calls subroutines - complex operation

### Code 0x03: Dialog_Portrait

**Address**: 0x00A39C
**Description**: ASTERISK/PORTRAIT - Display NPC portrait

```asm
	lda.W #$0040                         ;00A39C|A94000  |      ;
	and.W $00d0                          ;00A39F|2DD000  |0000D0;
	beq Dialog_WritePixelPattern                      ;00A3A2|F001    |00A3A5;
	rts                                  ;00A3A4|60      |      ;
```

**Analysis**:
- Contains conditional logic

### Code 0x04: Dialog_Name

**Address**: 0x00B354
**Description**: NAME - Insert character name

```asm
	rts                                  ;00B354|60      |      ;
```

### Code 0x05: Dialog_Item

**Address**: 0x00A37F
**Description**: ITEM - Insert item name
**Assembly Label**: `Cutscene_ProcessScroll_Finish`

```asm
	lda.B [$17]                          ;00A37F|A717    |000017;
	inc.B $17                            ;00A381|E617    |000017;
	and.W #$00ff                         ;00A383|29FF00  |      ;
	asl a;00A386|0A      |      ;
	tax                                  ;00A387|AA      |      ;
	jmp.W (DATA8_009e6e,x)               ;00A388|7C6E9E  |009E6E;
```

**Analysis**:
- Reads 1 parameter byte(s) from dialog stream

### Code 0x06: Dialog_Space

**Address**: 0x00B4B0
**Description**: SPACE - Insert space character
**Assembly Label**: `Display_ClampMax_Return`

```asm
	lda.W #$0020                         ;00B4B0|A92000  |      ;
	and.W $00da                          ;00B4B3|2DDA00  |0000DA;
	beq UNREACH_00B4BB                   ;00B4B6|F003    |00B4BB;
	jmp.W Text_CalculateDisplayPosition                    ;00B4B8|4CC0A8  |00A8C0;
```

**Analysis**:
- Contains conditional logic

--------------------------------------------------------------------------------
## Unknown Display Codes (0x07-0x0F)

### Code 0x07: Dialog_Unknown07

**Address**: 0x00A708
**Description**: Unknown control code 0x07

```asm
	lda.B [$17]                          ;00A708|A717    |000017;
	inc.B $17                            ;00A70A|E617    |000017;
	inc.B $17                            ;00A70C|E617    |000017;
	tax                                  ;00A70E|AA      |      ;
	lda.B [$17]                          ;00A70F|A717    |000017;
	inc.B $17                            ;00A711|E617    |000017;
	and.W #$00ff                         ;00A713|29FF00  |      ;
	bra Dialog_ExecuteSubroutine                      ;00A716|8004    |00A71C;
;      |        |      ;
	ldx.B $9e                            ;00A718|A69E    |00009E;
	lda.B $a0                            ;00A71A|A5A0    |0000A0;
;      |        |      ;
```

**Analysis**:
- Reads 3 parameter byte(s) from dialog stream

### Code 0x08: Dialog_ExecuteSubroutine_WithPointer

**Address**: 0x00A755
**Description**: SUBROUTINE CALL - Execute dialog subroutine (CRITICAL - 500+ uses)

```asm
	lda.B [$17]                          ;00A755|A717    |000017;
	inc.B $17                            ;00A757|E617    |000017;
	inc.B $17                            ;00A759|E617    |000017;
	tax                                  ;00A75B|AA      |      ;
	lda.B $19                            ;00A75C|A519    |000019;
	bra Dialog_ExecuteSubroutine                      ;00A75E|80BC    |00A71C;
;      |        |      ;
	lda.B [$17]                          ;00A760|A717    |000017;
	inc.B $17                            ;00A762|E617    |000017;
	and.W #$00ff                         ;00A764|29FF00  |      ;
	phd                                  ;00A767|0B      |      ;
	pea.W $00d0                          ;00A768|F4D000  |0000D0;
	pld                                  ;00A76B|2B      |      ;
	jsl.L Bitfield_TestBits                    ;00A76C|225A9700|00975A;
	pld                                  ;00A770|2B      |      ;
	inc a;00A771|1A      |      ;
	dec a;00A772|3A      |      ;
	bne Dialog_ExecuteSubroutine_WithPointer                      ;00A773|D0E0    |00A755;
	bra Dialog_ConditionalLoop_SkipOffset                      ;00A775|804F    |00A7C6;
;      |        |      ;
	lda.B [$17]                          ;00A777|A717    |000017;
	inc.B $17                            ;00A779|E617    |000017;
	and.W #$00ff                         ;00A77B|29FF00  |      ;
	phd                                  ;00A77E|0B      |      ;
	pea.W $00d0                          ;00A77F|F4D000  |0000D0;
	pld                                  ;00A782|2B      |      ;
	jsl.L Bitfield_TestBits                    ;00A783|225A9700|00975A;
	pld                                  ;00A787|2B      |      ;
	inc a;00A788|1A      |      ;
	dec a;00A789|3A      |      ;
	beq Dialog_ExecuteSubroutine_WithPointer                      ;00A78A|F0C9    |00A755;
	db $80,$38,$a7,$17,$e6,$17,$29,$ff,$00,$22,$76,$97,$00,$d0,$ba,$80;00A78C|        |00A7C6;
	db $29                               ;00A79C|        |      ;
	lda.B [$17]                          ;00A79D|A717    |000017;
	inc.B $17                            ;00A79F|E617    |000017;
	and.W #$00ff                         ;00A7A1|29FF00  |      ;
	jsl.L Bitfield_TestBits_Entity                    ;00A7A4|22769700|009776;
	beq Dialog_ExecuteSubroutine_WithPointer                      ;00A7A8|F0AB    |00A755;
	db $80,$1a,$20,$a1,$b1,$d0,$a4,$80,$13,$20,$a1,$b1,$f0,$9d,$80,$0c;00A7AA|        |00A7C6;
	db $20,$b4,$b1,$d0,$96,$80,$05,$20,$b4,$b1,$f0,$8f;00A7BA|        |00B1B4;
;      |        |      ;
```

**Analysis**:
- Calls subroutines - complex operation
- Reads 5 parameter byte(s) from dialog stream
- Contains conditional logic
- Reads 16-bit pointer from dialog stream
- Executes nested dialog subroutine at that pointer
- CRITICAL: Used for reusable dialog fragments

### Code 0x09: Dialog_Unknown09

**Address**: 0x00A83F
**Description**: Unknown control code 0x09

```asm
	lda.B [$17]                          ;00A83F|A717    |000017;
	inc.B $17                            ;00A841|E617    |000017;
	inc.B $17                            ;00A843|E617    |000017;
	tay                                  ;00A845|A8      |      ;
	lda.B [$17]                          ;00A846|A717    |000017;
	inc.B $17                            ;00A848|E617    |000017;
	and.W #$00ff                         ;00A84A|29FF00  |      ;
	pea.W PTR16_00FFFF                   ;00A84D|F4FFFF  |00FFFF;
	sep #$20                             ;00A850|E220    |      ;
	dey                                  ;00A852|88      |      ;
	phk                                  ;00A853|4B      |      ;
	pea.W Dialog_ExecuteNestedCall_Return                    ;00A854|F45BA8  |00A85B;
	pha                                  ;00A857|48      |      ;
	phy                                  ;00A858|5A      |      ;
	rep #$30                             ;00A859|C230    |      ;
;      |        |      ;
```

**Analysis**:
- Reads 3 parameter byte(s) from dialog stream

### Code 0x0A: Dialog_Unknown0A

**Address**: 0x00A519
**Description**: Unknown control code 0x0A
**Assembly Label**: `Dialog_JumpToPointer`

```asm
	lda.B [$17]                          ;00A519|A717    |000017;
	sta.B $17                            ;00A51B|8517    |000017;
	rts                                  ;00A51D|60      |      ;
```

**Analysis**:
- Modifies memory/state

### Code 0x0B: Dialog_Unknown0B

**Address**: 0x00A3F5
**Description**: Unknown control code 0x0B

```asm
	jsr.W Conditional_CompareByte                    ;00A3F5|20C3B1  |00B1C3;
	bne Dialog_Conditional_SkipOffset                      ;00A3F8|D007    |00A401;
	bra Dialog_Conditional_Jump                      ;00A3FA|800A    |00A406;
;      |        |      ;
	jsr.W Conditional_CompareByte                    ;00A3FC|20C3B1  |00B1C3;
	bne Dialog_Conditional_Jump                      ;00A3FF|D005    |00A406;
;      |        |      ;
```

**Analysis**:
- Calls subroutines - complex operation
- Contains conditional logic

### Code 0x0C: Dialog_Unknown0C

**Address**: 0x00A958
**Description**: Unknown control code 0x0C
**Assembly Label**: `Text_RenderCustom_Return`

```asm
	lda.B [$17]                          ;00A958|A717    |000017;
	inc.B $17                            ;00A95A|E617    |000017;
	inc.B $17                            ;00A95C|E617    |000017;
	tax                                  ;00A95E|AA      |      ;
	lda.B [$17]                          ;00A95F|A717    |000017;
	inc.B $17                            ;00A961|E617    |000017;
	and.W #$00ff                         ;00A963|29FF00  |      ;
	sep #$20                             ;00A966|E220    |      ;
	sta.W $0000,x                        ;00A968|9D0000  |000000;
	rts                                  ;00A96B|60      |      ;
```

**Analysis**:
- Reads 3 parameter byte(s) from dialog stream
- Modifies memory/state

### Code 0x0D: Dialog_Unknown0D

**Address**: 0x00A96C
**Description**: Unknown control code 0x0D
**Assembly Label**: `Memory_WriteWordToAddress`

```asm
	lda.B [$17]                          ;00A96C|A717    |000017;
	inc.B $17                            ;00A96E|E617    |000017;
	inc.B $17                            ;00A970|E617    |000017;
	tax                                  ;00A972|AA      |      ;
	lda.B [$17]                          ;00A973|A717    |000017;
	inc.B $17                            ;00A975|E617    |000017;
	inc.B $17                            ;00A977|E617    |000017;
	sta.W $0000,x                        ;00A979|9D0000  |000000;
	rts                                  ;00A97C|60      |      ;
```

**Analysis**:
- Reads 4 parameter byte(s) from dialog stream
- Modifies memory/state

### Code 0x0E: Dialog_Unknown0E

**Address**: 0x00A97D
**Description**: Unknown control code 0x0E (FREQUENT - 100+ uses)

```asm
	jsr.W Memory_WriteWordToAddress                    ;00A97D|206CA9  |00A96C;
	lda.B [$17]                          ;00A980|A717    |000017;
	inc.B $17                            ;00A982|E617    |000017;
	and.W #$00ff                         ;00A984|29FF00  |      ;
	sep #$20                             ;00A987|E220    |      ;
	sta.W $0002,x                        ;00A989|9D0200  |000002;
	rts                                  ;00A98C|60      |      ;
```

**Analysis**:
- Calls subroutines - complex operation
- Reads 1 parameter byte(s) from dialog stream
- Modifies memory/state

### Code 0x0F: Dialog_Unknown0F

**Address**: 0x00AFD6
**Description**: Unknown control code 0x0F

```asm
	stz.B $9e                            ;00AFD6|649E    |00009E;
	stz.B $a0                            ;00AFD8|64A0    |0000A0;
	lda.B [$17]                          ;00AFDA|A717    |000017;
	inc.B $17                            ;00AFDC|E617    |000017;
	inc.B $17                            ;00AFDE|E617    |000017;
	tax                                  ;00AFE0|AA      |      ;
	sep #$20                             ;00AFE1|E220    |      ;
	lda.W $0000,x                        ;00AFE3|BD0000  |000000;
	sta.B $9e                            ;00AFE6|859E    |00009E;
	rts                                  ;00AFE8|60      |      ;
```

**Analysis**:
- Reads 2 parameter byte(s) from dialog stream
- Modifies memory/state

--------------------------------------------------------------------------------
## Dynamic Insertion Codes (0x10-0x1F)

### Code 0x10: Dialog_InsertItemName

**Address**: 0x00AF9A
**Description**: INSERT_ITEM_NAME - Dynamic item name

```asm
	lda.W #$0001                         ;00AF9A|A90100  |      ;
	bra Memory_BlockCopy_ToPointer_Direct                      ;00AF9D|80E0    |00AF7F;
;      |        |      ;
	lda.W #$0002                         ;00AF9F|A90200  |      ;
	bra Memory_BlockCopy_ToPointer_Direct                      ;00AFA2|80DB    |00AF7F;
;      |        |      ;
	jsr.W Memory_ReadPointerFromTable                    ;00AFA4|20BBAF  |00AFBB;
	stz.B $9f                            ;00AFA7|649F    |00009F;
	stz.B $a0                            ;00AFA9|64A0    |0000A0;
	rts                                  ;00AFAB|60      |      ;
```

**Analysis**:
- Calls subroutines - complex operation
- Dynamic text insertion - reads index, looks up name in table

### Code 0x11: Dialog_InsertSpellName

**Address**: 0x00AF6B
**Description**: INSERT_SPELL_NAME - Dynamic spell name

```asm
	lda.W #$0000                         ;00AF6B|A90000  |      ;
	bra Memory_BlockCopy_ToPointer                      ;00AF6E|80EB    |00AF5B;
;      |        |      ;
	lda.W #$0001                         ;00AF70|A90100  |      ;
	bra Memory_BlockCopy_ToPointer                      ;00AF73|80E6    |00AF5B;
;      |        |      ;
	lda.W #$0002                         ;00AF75|A90200  |      ;
	bra Memory_BlockCopy_ToPointer                      ;00AF78|80E1    |00AF5B;
;      |        |      ;
;      |        |      ;
```

**Analysis**:
- Dynamic text insertion - reads index, looks up name in table

### Code 0x12: Dialog_InsertMonsterName

**Address**: 0x00AF70
**Description**: INSERT_MONSTER_NAME - Dynamic monster name

```asm
	lda.W #$0001                         ;00AF70|A90100  |      ;
	bra Memory_BlockCopy_ToPointer                      ;00AF73|80E6    |00AF5B;
;      |        |      ;
	lda.W #$0002                         ;00AF75|A90200  |      ;
	bra Memory_BlockCopy_ToPointer                      ;00AF78|80E1    |00AF5B;
;      |        |      ;
;      |        |      ;
```

**Analysis**:
- Dynamic text insertion - reads index, looks up name in table

### Code 0x13: Dialog_InsertCharacterName

**Address**: 0x00B094
**Description**: INSERT_CHARACTER_NAME - Dynamic character name

```asm
	lda.W #$0000                         ;00B094|A90000  |      ;
	bra Math_Add_Indirect                      ;00B097|80E5    |00B07E;
;      |        |      ;
	lda.W #$0001                         ;00B099|A90100  |      ;
	bra Math_Add_Indirect                      ;00B09C|80E0    |00B07E;
;      |        |      ;
	lda.W #$0002                         ;00B09E|A90200  |      ;
	bra Math_Add_Indirect                      ;00B0A1|80DB    |00B07E;
;      |        |      ;
	lda.W #$0000                         ;00B0A3|A90000  |      ;
	bra Math_Add_Direct                      ;00B0A6|80DB    |00B083;
;      |        |      ;
	lda.W #$0001                         ;00B0A8|A90100  |      ;
	bra Math_Add_Direct                      ;00B0AB|80D6    |00B083;
;      |        |      ;
	lda.W #$0002                         ;00B0AD|A90200  |      ;
	bra Math_Add_Direct                      ;00B0B0|80D1    |00B083;
;      |        |      ;
;      |        |      ;
```

**Analysis**:
- Dynamic text insertion - reads index, looks up name in table

### Code 0x14: Dialog_InsertLocationName

**Address**: 0x00AFFE
**Description**: INSERT_LOCATION_NAME - Dynamic location name
**Assembly Label**: `Bitwise_AND_Store`

```asm
	lda.W #$0000                         ;00AFFE|A90000  |      ;
	bra Bitwise_AND_Indirect                      ;00B001|80E6    |00AFE9;
;      |        |      ;
	lda.W #$0001                         ;00B003|A90100  |      ;
	bra Bitwise_AND_Indirect                      ;00B006|80E1    |00AFE9;
;      |        |      ;
	db $a9,$02,$00,$80,$dc,$a9,$00,$00,$80,$dc;00B008|        |      ;
	lda.W #$0001                         ;00B012|A90100  |      ;
	bra Bitwise_AND_Direct                      ;00B015|80D7    |00AFEE;
;      |        |      ;
	db $a9,$02,$00,$80,$d2               ;00B017|        |      ;
;      |        |      ;
```

**Analysis**:
- Dynamic text insertion - reads index, looks up name in table

### Code 0x15: Dialog_InsertNumber

**Address**: 0x00A0B7
**Description**: INSERT_NUMBER? - Unused/number insertion

```asm
	lda.B [$17]                          ;00A0B7|A717    |000017;
	inc.B $17                            ;00A0B9|E617    |000017;
	inc.B $17                            ;00A0BB|E617    |000017;
	sta.B $25                            ;00A0BD|8525    |000025;
	rts                                  ;00A0BF|60      |      ;
```

**Analysis**:
- Reads 2 parameter byte(s) from dialog stream
- Modifies memory/state
- Dynamic text insertion - reads index, looks up name in table

### Code 0x16: Dialog_InsertObjectName

**Address**: 0x00B2F9
**Description**: INSERT_OBJECT_NAME - Dynamic object name

```asm
	lda.B [$17]                          ;00B2F9|A717    |000017;
	inc.B $17                            ;00B2FB|E617    |000017;
	inc.B $17                            ;00B2FD|E617    |000017;
	jmp.W Dialog_WriteCharacter_Store                    ;00B2FF|4CCB9D  |009DCB;
```

**Analysis**:
- Reads 2 parameter byte(s) from dialog stream
- Dynamic text insertion - reads index, looks up name in table

### Code 0x17: Dialog_InsertWeaponName

**Address**: 0x00AEDA
**Description**: INSERT_WEAPON_NAME - Dynamic weapon name

```asm
	lda.B [$17]                          ;00AEDA|A717    |000017;
	inc.B $17                            ;00AEDC|E617    |000017;
	and.W #$00ff                         ;00AEDE|29FF00  |      ;
	phd                                  ;00AEE1|0B      |      ;
	pea.W $00d0                          ;00AEE2|F4D000  |0000D0;
	pld                                  ;00AEE5|2B      |      ;
	jsl.L Bitfield_ClearBits                    ;00AEE6|22549700|009754;
	pld                                  ;00AEEA|2B      |      ;
	rts                                  ;00AEEB|60      |      ;
```

**Analysis**:
- Calls subroutines - complex operation
- Reads 1 parameter byte(s) from dialog stream
- Dynamic text insertion - reads index, looks up name in table

### Code 0x18: Dialog_InsertArmorName

**Address**: 0x00AACF
**Description**: INSERT_ARMOR_NAME - Dynamic armor name

```asm
	lda.B $27                            ;00AACF|A527    |000027;
	and.W #$00ff                         ;00AAD1|29FF00  |      ;
	asl a;00AAD4|0A      |      ;
	tax                                  ;00AAD5|AA      |      ;
	pei.B ($25)                          ;00AAD6|D425    |000025;
	lda.B $28                            ;00AAD8|A528    |000028;
	sta.B $25                            ;00AADA|8525    |000025;
	jsr.W Text_CalculateScreenPosition                    ;00AADC|20D1A8  |00A8D1;
	jsr.W Display_ClampMin                    ;00AADF|209EB4  |00B49E;
	lda.B $1c                            ;00AAE2|A51C    |00001C;
	and.W #$00ff                         ;00AAE4|29FF00  |      ;
	pha                                  ;00AAE7|48      |      ;
	plb                                  ;00AAE8|AB      |      ;
	jsr.W (UNREACH_00AAF7,x)             ;00AAE9|FCF7AA  |00AAF7;
	plb                                  ;00AAEC|AB      |      ;
	jsr.W Display_ClampMax                    ;00AAED|20A7B4  |00B4A7;
	pla                                  ;00AAF0|68      |      ;
	sta.B $25                            ;00AAF1|8525    |000025;
	jmp.W Text_CalculateScreenPosition                    ;00AAF3|4CD1A8  |00A8D1;
```

**Analysis**:
- Calls subroutines - complex operation
- Modifies memory/state
- Dynamic text insertion - reads index, looks up name in table

### Code 0x19: Dialog_InsertAccessory

**Address**: 0x00A8D1
**Description**: INSERT_ACCESSORY? - Unused/accessory name
**Assembly Label**: `Text_CalculateScreenPosition`

```asm
	lda.B $40                            ;00A8D1|A540    |000040;
	sta.B $1b                            ;00A8D3|851B    |00001B;
	lda.B $25                            ;00A8D5|A525    |000025;
	and.W #$00ff                         ;00A8D7|29FF00  |      ;
	asl a;00A8DA|0A      |      ;
	sta.B $1a                            ;00A8DB|851A    |00001A;
	lda.B $25                            ;00A8DD|A525    |000025;
	and.W #$ff00                         ;00A8DF|2900FF  |      ;
	lsr a;00A8E2|4A      |      ;
	lsr a;00A8E3|4A      |      ;
	adc.B $1a                            ;00A8E4|651A    |00001A;
	adc.B $3f                            ;00A8E6|653F    |00003F;
	sta.B $1a                            ;00A8E8|851A    |00001A;
	rts                                  ;00A8EA|60      |      ;
```

**Analysis**:
- Modifies memory/state

### Code 0x1A: Dialog_TextboxBelow

**Address**: 0x00A168
**Description**: TEXTBOX_BELOW - Position textbox below

```asm
	lda.B [$17]                          ;00A168|A717    |000017;
	inc.B $17                            ;00A16A|E617    |000017;
	and.W #$00ff                         ;00A16C|29FF00  |      ;
	sep #$20                             ;00A16F|E220    |      ;
	sta.B $4f                            ;00A171|854F    |00004F;
	rep #$30                             ;00A173|C230    |      ;
	lda.W #$0003                         ;00A175|A90300  |      ;
	ldx.W #$a831                         ;00A178|A231A8  |      ;
	jmp.W Dialog_ExecuteSubroutine                    ;00A17B|4C1CA7  |00A71C;
```

**Analysis**:
- Reads 1 parameter byte(s) from dialog stream
- Modifies memory/state

### Code 0x1B: Dialog_TextboxAbove

**Address**: 0x00A17E
**Description**: TEXTBOX_ABOVE - Position textbox above

```asm
	lda.B [$17]                          ;00A17E|A717    |000017;
	inc.B $17                            ;00A180|E617    |000017;
	and.W #$00ff                         ;00A182|29FF00  |      ;
	sep #$20                             ;00A185|E220    |      ;
	sta.B $4f                            ;00A187|854F    |00004F;
	rep #$30                             ;00A189|C230    |      ;
	lda.W #$0003                         ;00A18B|A90300  |      ;
	ldx.W #$a895                         ;00A18E|A295A8  |      ;
	jmp.W Dialog_ExecuteSubroutine                    ;00A191|4C1CA7  |00A71C;
```

**Analysis**:
- Reads 1 parameter byte(s) from dialog stream
- Modifies memory/state

### Code 0x1C: Dialog_Unknown1C

**Address**: 0x00A15C
**Description**: Unknown control code 0x1C

```asm
	sep #$20                             ;00A15C|E220    |      ;
	lda.B #$03                           ;00A15E|A903    |      ;
	sta.B $19                            ;00A160|8519    |000019;
	ldx.W #$8457                         ;00A162|A25784  |      ;
	stx.B $17                            ;00A165|8617    |000017;
	rts                                  ;00A167|60      |      ;
```

**Analysis**:
- Modifies memory/state

### Code 0x1D: Dialog_FormatItemE1

**Address**: 0x00A13C
**Description**: FORMAT_ITEM_E1 - Dictionary 0x50 formatting

```asm
	lda.B [$17]                          ;00A13C|A717    |000017;
	inc.B $17                            ;00A13E|E617    |000017;
	and.W #$00ff                         ;00A140|29FF00  |      ;
	sta.B $9e                            ;00A143|859E    |00009E;
	stz.B $a0                            ;00A145|64A0    |0000A0;
	lda.W #$0003                         ;00A147|A90300  |      ;
	ldx.W #$a7f6                         ;00A14A|A2F6A7  |      ;
	jmp.W Dialog_ExecuteSubroutine                    ;00A14D|4C1CA7  |00A71C;
```

**Analysis**:
- Reads 1 parameter byte(s) from dialog stream
- Modifies memory/state
- Special formatting for dictionary entries 0x50/0x51
- Related to equipment name display formatting

### Code 0x1E: Dialog_FormatItemE2

**Address**: 0x00A0FE
**Description**: FORMAT_ITEM_E2 - Dictionary 0x51 formatting

```asm
	pei.B ($9e)                          ;00A0FE|D49E    |00009E;
	pei.B ($a0)                          ;00A100|D4A0    |0000A0;
	lda.B [$17]                          ;00A102|A717    |000017;
	inc.B $17                            ;00A104|E617    |000017;
	and.W #$00ff                         ;00A106|29FF00  |      ;
	sta.B $9e                            ;00A109|859E    |00009E;
	stz.B $a0                            ;00A10B|64A0    |0000A0;
	lda.W #$0003                         ;00A10D|A90300  |      ;
	ldx.W #$8383                         ;00A110|A28383  |      ;
	jsr.W Dialog_ExecuteSubroutine                    ;00A113|201CA7  |00A71C;
	plx                                  ;00A116|FA      |      ;
	stx.B $a0                            ;00A117|86A0    |0000A0;
	plx                                  ;00A119|FA      |      ;
	stx.B $9e                            ;00A11A|869E    |00009E;
	rts                                  ;00A11C|60      |      ;
```

**Analysis**:
- Calls subroutines - complex operation
- Reads 1 parameter byte(s) from dialog stream
- Modifies memory/state
- Special formatting for dictionary entries 0x50/0x51
- Related to equipment name display formatting

### Code 0x1F: Dialog_Crystal

**Address**: 0x00A0C0
**Description**: CRYSTAL - Crystal reference

```asm
	pei.B ($9e)                          ;00A0C0|D49E    |00009E;
	pei.B ($a0)                          ;00A0C2|D4A0    |0000A0;
	lda.B [$17]                          ;00A0C4|A717    |000017;
	inc.B $17                            ;00A0C6|E617    |000017;
	and.W #$00ff                         ;00A0C8|29FF00  |      ;
	sta.B $9e                            ;00A0CB|859E    |00009E;
	stz.B $a0                            ;00A0CD|64A0    |0000A0;
	lda.W #$0003                         ;00A0CF|A90300  |      ;
	ldx.W #$82bb                         ;00A0D2|A2BB82  |      ;
	jsr.W Dialog_ExecuteSubroutine                    ;00A0D5|201CA7  |00A71C;
	plx                                  ;00A0D8|FA      |      ;
	stx.B $a0                            ;00A0D9|86A0    |0000A0;
	plx                                  ;00A0DB|FA      |      ;
	stx.B $9e                            ;00A0DC|869E    |00009E;
	rts                                  ;00A0DE|60      |      ;
```

**Analysis**:
- Calls subroutines - complex operation
- Reads 1 parameter byte(s) from dialog stream
- Modifies memory/state

--------------------------------------------------------------------------------
## Advanced Codes (0x20-0x2F)

### Code 0x20: Dialog_Unknown20

**Address**: 0x00A0DF
**Description**: Unknown control code 0x20

```asm
	db $d4,$9e,$d4,$a0,$a7,$17,$e6,$17,$29,$ff,$00,$85,$9e,$64,$a0,$a9;00A0DF|        |00009E;
	db $03,$00,$a2,$02,$a8,$20,$1c,$a7,$fa,$86,$a0,$fa,$86,$9e,$60;00A0EF|        |000000;
	pei.B ($9e)                          ;00A0FE|D49E    |00009E;
	pei.B ($a0)                          ;00A100|D4A0    |0000A0;
	lda.B [$17]                          ;00A102|A717    |000017;
	inc.B $17                            ;00A104|E617    |000017;
	and.W #$00ff                         ;00A106|29FF00  |      ;
	sta.B $9e                            ;00A109|859E    |00009E;
	stz.B $a0                            ;00A10B|64A0    |0000A0;
	lda.W #$0003                         ;00A10D|A90300  |      ;
	ldx.W #$8383                         ;00A110|A28383  |      ;
	jsr.W Dialog_ExecuteSubroutine                    ;00A113|201CA7  |00A71C;
	plx                                  ;00A116|FA      |      ;
	stx.B $a0                            ;00A117|86A0    |0000A0;
	plx                                  ;00A119|FA      |      ;
	stx.B $9e                            ;00A11A|869E    |00009E;
	rts                                  ;00A11C|60      |      ;
```

**Analysis**:
- Calls subroutines - complex operation
- Reads 1 parameter byte(s) from dialog stream
- Modifies memory/state

### Code 0x21: Dialog_Unknown21

**Address**: 0x00B2F4
**Description**: Unknown control code 0x21

```asm
	inc.B $1a                            ;00B2F4|E61A    |00001A;
	inc.B $1a                            ;00B2F6|E61A    |00001A;
	rts                                  ;00B2F8|60      |      ;
```

### Code 0x22: Dialog_Unknown22

**Address**: 0x00A150
**Description**: Unknown control code 0x22

```asm
	sep #$20                             ;00A150|E220    |      ;
	lda.B #$03                           ;00A152|A903    |      ;
	sta.B $19                            ;00A154|8519    |000019;
	ldx.W #$aea7                         ;00A156|A2A7AE  |      ;
	stx.B $17                            ;00A159|8617    |000017;
	rts                                  ;00A15B|60      |      ;
```

**Analysis**:
- Modifies memory/state

### Code 0x23: Dialog_Unknown23

**Address**: 0x00AEA2
**Description**: Unknown control code 0x23
**Assembly Label**: `Menu_RenderText_CopyNext`

```asm
	lda.B [$17]                          ;00AEA2|A717    |000017;
	inc.B $17                            ;00AEA4|E617    |000017;
	and.W #$00ff                         ;00AEA6|29FF00  |      ;
	jsl.L Bitfield_SetBits_Entity                    ;00AEA9|22609700|009760;
	rts                                  ;00AEAD|60      |      ;
```

**Analysis**:
- Calls subroutines - complex operation
- Reads 1 parameter byte(s) from dialog stream

### Code 0x24: Dialog_Unknown24

**Address**: 0x00A11D
**Description**: Unknown control code 0x24

```asm
	lda.B [$17]                          ;00A11D|A717    |000017;
	inc.B $17                            ;00A11F|E617    |000017;
	inc.B $17                            ;00A121|E617    |000017;
	sta.B $28                            ;00A123|8528    |000028;
	lda.B [$17]                          ;00A125|A717    |000017;
	inc.B $17                            ;00A127|E617    |000017;
	inc.B $17                            ;00A129|E617    |000017;
	sta.B $2a                            ;00A12B|852A    |00002A;
	rts                                  ;00A12D|60      |      ;
```

**Analysis**:
- Reads 4 parameter byte(s) from dialog stream
- Modifies memory/state

### Code 0x25: Dialog_Unknown25

**Address**: 0x00A07D
**Description**: Unknown control code 0x25

```asm
	lda.B [$17]                          ;00A07D|A717    |000017;
	inc.B $17                            ;00A07F|E617    |000017;
	and.W #$00ff                         ;00A081|29FF00  |      ;
	sep #$20                             ;00A084|E220    |      ;
	sta.B $1e                            ;00A086|851E    |00001E;
	rts                                  ;00A088|60      |      ;
```

**Analysis**:
- Reads 1 parameter byte(s) from dialog stream
- Modifies memory/state

### Code 0x26: Dialog_Unknown26

**Address**: 0x00A089
**Description**: Unknown control code 0x26

```asm
	lda.B [$17]                          ;00A089|A717    |000017;
	inc.B $17                            ;00A08B|E617    |000017;
	inc.B $17                            ;00A08D|E617    |000017;
	sta.B $3f                            ;00A08F|853F    |00003F;
	lda.B [$17]                          ;00A091|A717    |000017;
	inc.B $17                            ;00A093|E617    |000017;
	and.W #$00ff                         ;00A095|29FF00  |      ;
	sep #$20                             ;00A098|E220    |      ;
	sta.B $41                            ;00A09A|8541    |000041;
	rts                                  ;00A09C|60      |      ;
```

**Analysis**:
- Reads 3 parameter byte(s) from dialog stream
- Modifies memory/state

### Code 0x27: Dialog_Unknown27

**Address**: 0x00A09D
**Description**: Unknown control code 0x27

```asm
	lda.B [$17]                          ;00A09D|A717    |000017;
	inc.B $17                            ;00A09F|E617    |000017;
	and.W #$00ff                         ;00A0A1|29FF00  |      ;
	sep #$20                             ;00A0A4|E220    |      ;
	sta.B $27                            ;00A0A6|8527    |000027;
	rts                                  ;00A0A8|60      |      ;
```

**Analysis**:
- Reads 1 parameter byte(s) from dialog stream
- Modifies memory/state

### Code 0x28: Dialog_Unknown28

**Address**: 0x00A0A9
**Description**: Unknown control code 0x28

```asm
	lda.B [$17]                          ;00A0A9|A717    |000017;
	inc.B $17                            ;00A0AB|E617    |000017;
	and.W #$00ff                         ;00A0AD|29FF00  |      ;
	sep #$20                             ;00A0B0|E220    |      ;
	rep #$10                             ;00A0B2|C210    |      ;
	sta.B $1d                            ;00A0B4|851D    |00001D;
	rts                                  ;00A0B6|60      |      ;
```

**Analysis**:
- Reads 1 parameter byte(s) from dialog stream
- Modifies memory/state

### Code 0x29: Dialog_Unknown29

**Address**: 0x00AEB5
**Description**: Unknown control code 0x29

```asm
	lda.B [$17]                          ;00AEB5|A717    |000017;
	inc.B $17                            ;00AEB7|E617    |000017;
	and.W #$00ff                         ;00AEB9|29FF00  |      ;
	phd                                  ;00AEBC|0B      |      ;
	pea.W $00d0                          ;00AEBD|F4D000  |0000D0;
	pld                                  ;00AEC0|2B      |      ;
	jsl.L Bitfield_SetBits                    ;00AEC1|224E9700|00974E;
	pld                                  ;00AEC5|2B      |      ;
	rts                                  ;00AEC6|60      |      ;
```

**Analysis**:
- Calls subroutines - complex operation
- Reads 1 parameter byte(s) from dialog stream

### Code 0x2A: Dialog_Unknown2A

**Address**: 0x00B379
**Description**: Unknown control code 0x2A
**Assembly Label**: `Dialog_ProcessLoop`

```asm
	lda.B [$17]                          ;00B379|A717    |000017;
	inc.B $17                            ;00B37B|E617    |000017;
	inc.B $17                            ;00B37D|E617    |000017;
	cmp.W #$ffff                         ;00B37F|C9FFFF  |      ;
	beq Dialog_LoopDone                      ;00B382|F007    |00B38B;
	jsr.W Dialog_ExecuteOrRoute                    ;00B384|205BB3  |00B35B;
	rep #$30                             ;00B387|C230    |      ;
	bra Dialog_ProcessLoop                      ;00B389|80EE    |00B379;
;      |        |      ;
;      |        |      ;
```

**Analysis**:
- Calls subroutines - complex operation
- Reads 2 parameter byte(s) from dialog stream
- Contains conditional logic

### Code 0x2B: Dialog_Unknown2B

**Address**: 0x00AEC7
**Description**: Unknown control code 0x2B

```asm
	lda.B [$17]                          ;00AEC7|A717    |000017;
	inc.B $17                            ;00AEC9|E617    |000017;
	and.W #$00ff                         ;00AECB|29FF00  |      ;
	jsl.L Bitfield_ClearBits_Entity                    ;00AECE|226B9700|00976B;
	rts                                  ;00AED2|60      |      ;
```

**Analysis**:
- Calls subroutines - complex operation
- Reads 1 parameter byte(s) from dialog stream

### Code 0x2C: Dialog_Unknown2C

**Address**: 0x00B355
**Description**: Unknown control code 0x2C

```asm
	lda.B [$17]                          ;00B355|A717    |000017;
	inc.B $17                            ;00B357|E617    |000017;
	inc.B $17                            ;00B359|E617    |000017;
;      |        |      ;
```

**Analysis**:
- Reads 2 parameter byte(s) from dialog stream

### Code 0x2D: Dialog_Unknown2D

**Address**: 0x00A074
**Description**: Unknown control code 0x2D

```asm
	lda.B [$17]                          ;00A074|A717    |000017;
	inc.B $17                            ;00A076|E617    |000017;
	inc.B $17                            ;00A078|E617    |000017;
	sta.B $2e                            ;00A07A|852E    |00002E;
	rts                                  ;00A07C|60      |      ;
```

**Analysis**:
- Reads 2 parameter byte(s) from dialog stream
- Modifies memory/state

### Code 0x2E: Dialog_Unknown2E

**Address**: 0x00A563
**Description**: Unknown control code 0x2E

```asm
	lda.B [$17]                          ;00A563|A717    |000017;
	inc.B $17                            ;00A565|E617    |000017;
	and.W #$00ff                         ;00A567|29FF00  |      ;
	jsl.L Bitfield_TestBits_Entity                    ;00A56A|22769700|009776;
;      |        |      ;
```

**Analysis**:
- Calls subroutines - complex operation
- Reads 1 parameter byte(s) from dialog stream

### Code 0x2F: Dialog_Unknown2F

**Address**: 0x00A06E
**Description**: Unknown control code 0x2F

```asm
	lda.W #$0ea6                         ;00A06E|A9A60E  |      ;
	sta.B $2e                            ;00A071|852E    |00002E;
	rts                                  ;00A073|60      |      ;
```

**Analysis**:
- Modifies memory/state

--------------------------------------------------------------------------------
## Handler Summary

### Critical Handlers

- **0x00**: `Dialog_End` (0x00A378) - END - Text terminator (117 uses = 100% coverage)
- **0x08**: `Dialog_ExecuteSubroutine_WithPointer` (0x00A755) - SUBROUTINE CALL - Execute dialog subroutine (500+ uses)
- **0x0E**: `Dialog_Unknown0E` (0x00A97D) - Unknown frequent operation (100+ uses)
- **0x10**: `Dialog_InsertItemName` (0x00AF9A) - INSERT_ITEM_NAME - Most common dynamic code (55 uses)

### Handler Groups

**Basic Operations**: 0x00 (END), 0x01 (NEWLINE), 0x02 (WAIT)

**Dynamic Insertion**: 0x10-0x18 (Item, Spell, Monster, etc.)

**Formatting**: 0x1D (FORMAT_ITEM_E1), 0x1E (FORMAT_ITEM_E2)

**Textbox Control**: 0x1A (BELOW), 0x1B (ABOVE)

================================================================================
End of Documentation
================================================================================
