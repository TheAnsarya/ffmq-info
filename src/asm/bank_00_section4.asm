; ===========================================================================
; Continued Bank $00 Disassembly - Section 4
; Lines 1600-2400 (Graphics and VRAM routines)
; ===========================================================================

; ===========================================================================
; Character Sprite Update - Single Buffer Mode
; ===========================================================================
; Purpose: Update character sprite in single buffer rendering mode
; Input: X = character position on map
; Technical Details: Simpler than dual-buffer mode, direct VRAM write
; ===========================================================================

Sprite_UpdateCharacterSingleBuffer:
; Get character tile from map data
	lda.L				   DATA8_049800,x ; Load tile number from map data
	asl					 a; Multiply by 4 (4 bytes per tile)
	asl					 a
	sta.W				   $00f4	 ; Store tile offset

	rep					 #$10		; 16-bit X,Y
	lda.W				   $1031	 ; Get character map position
	jsr.W				   Map_PositionToVRAMAddress ; Convert to VRAM address
	stx.W				   $00f2	 ; Store VRAM address

	ldx.W				   #$2d1a	; Source data pointer
	lda.B				   #$7e	  ; Bank $7e (WRAM)

Sprite_DeterminePalette:
; Determine sprite attributes based on display mode
	pha							   ; Save bank

; Check if special rendering mode
	lda.B				   #$04	  ; Check bit 2
	and.W				   $00da	 ; Test display flags
	beq					 Sprite_PaletteNormal ; If clear, use normal rendering

; Check frame counter for animation
	lda.W				   $0014	 ; Get frame counter
	dec					 a
	beq					 Sprite_PaletteNormal ; If zero, use normal

; Check if battle mode
	lda.B				   #$10	  ; Check bit 4
	and.W				   $00da	 ; Test battle flag
	bne					 Sprite_PaletteBattle ; If set, use battle sprite

; Field sprite attributes (incomplete in original)
PLB_Label:
	lda.W				   $0001,x   ; Get sprite attribute byte
	and.B				   #$e3	  ; Mask palette bits
	ora.B				   #$94	  ; Set field palette
	bra					 Sprite_ApplyAttributes ; Apply attributes

Sprite_PaletteBattle:
; Battle sprite attributes
PLB_Label:
	lda.W				   $0001,x   ; Get sprite attribute byte
	and.B				   #$e3	  ; Mask palette bits
	ora.B				   #$9c	  ; Set battle palette
	bra					 Sprite_ApplyAttributes ; Apply attributes

Sprite_PaletteNormal:
; Normal sprite attributes
PLB_Label:
	lda.W				   $0001,x   ; Get sprite attribute byte
	and.B				   #$e3	  ; Mask palette bits
	ora.B				   #$88	  ; Set normal palette

Sprite_ApplyAttributes:
; Apply sprite attributes
	xba							   ; Swap to high byte

; Check character position range
	lda.L				   $001031   ; Get character position
	cmp.B				   #$29	  ; Compare to boundary
	bcc					 Sprite_StandardDisplay ; If below, use standard display
	cmp.B				   #$2c	  ; Compare to upper boundary
	beq					 Sprite_StandardDisplay ; If equal, use standard

; Special position handling (likely stair/elevation display)
	lda.W				   $0001,x   ; Get attribute byte
	and.B				   #$63	  ; Mask bits
	ora.B				   #$08	  ; Set special bit
	sta.W				   $0001,x   ; Store to OAM +1
	sta.W				   $0003,x   ; Store to OAM +3

; Convert X position to decimal digits for display
	lda.L				   $001030   ; Get X coordinate
	ldy.W				   #$ffff	; Initialize digit counter
	sec							   ; Set carry for subtraction

Sprite_ConvertDigit:
; Divide by 10 to get digits
	iny							   ; Increment digit count
	sbc.B				   #$0a	  ; Subtract 10
	bcs					 Sprite_ConvertDigit ; If still positive, continue

	adc.B				   #$8a	  ; Add tile offset for digits (adjust remainder)
	sta.W				   $0002,x   ; Store ones digit tile

; Handle tens digit
	cpy.W				   #$0000	; Check if any tens
	beq					 UNREACH_008D06 ; If zero, skip tens display

	tya							   ; Get tens count
	adc.B				   #$7f	  ; Add tile offset for tens
	sta.W				   $0000,x   ; Store tens digit tile
	bra					 Done ; Done

; ------------------------------------------------------------------------------
; UNREACHABLE CODE ANALYSIS
; ------------------------------------------------------------------------------
; Label: UNREACH_008D06
; Category: 🔴 Truly Unreachable (Dead Code)
; Purpose: Writes $45 to consecutive memory locations indexed by X
; Reachability: No known call sites or branches to this address
; Analysis: Memory initialization routine - writes 16-bit value $45XX
;   - Uses XBA to swap accumulators (8-bit/16-bit context)
;   - Writes to $0000,X and $0001,X (likely indexed table)
;   - Branches forward 17 bytes after completion
; Verified: NOT reachable in normal gameplay
; Notes: May be debug initialization or removed feature
; ------------------------------------------------------------------------------
UNREACH_008D06:
; No tens digit (position < 10)
	lda.B #$45                           ;008D06|A945    |      ; Load immediate $45
	sta.W $0000,X                        ;008D08|9D0000  |000000; Store to $0000 indexed by X
	xba                                  ;008D0B|EB      |      ; Exchange B and A accumulators
	sta.W $0001,X                        ;008D0C|9D0100  |000001; Store to $0001 indexed by X
	bra $+$11                            ;008D0F|800F    |008D20; Branch forward 17 bytes

Sprite_StandardDisplay:
; Standard character sprite display
	xba							   ; Restore attribute byte
	sta.W				   $0001,x   ; Store to OAM +1
	sta.W				   $0003,x   ; Store to OAM +3

	lda.B				   #$45	  ; Default tile number
	sta.W				   $0000,x   ; Store to OAM +0
	sta.W				   $0002,x   ; Store to OAM +2

Sprite_FinalizeUpdate:
; Finalize sprite update
	phk							   ; Push program bank
	plb							   ; Pull to data bank

	lda.B				   #$80	  ; Set update flag
	tsb.W				   $00d4	 ; Set bit in display flags

	plp							   ; Restore processor status
	rts							   ; Return

; ===========================================================================
; Character Sprite Update - Layer 2 (Dual Buffer Mode)
; ===========================================================================
; Purpose: Update character sprite in battle/transition mode with dual buffers
; Technical Details: Updates both WRAM buffers for smooth transitions
; ===========================================================================

Sprite_UpdateCharacterDualBuffer:
	php							   ; Preserve processor status
	sep					 #$30		; 8-bit A,X,Y

; Check if dual buffer mode active
	lda.B				   #$02	  ; Check bit 1
	and.W				   $00d8	 ; Test display mode flags
	beq					 Sprite_UpdateSingleBufferAlt ; If clear, single buffer mode

; Dual buffer mode - get character position
	ldx.W				   $10b1	 ; Get character map position
	cpx.B				   #$ff	  ; Check if valid
	beq					 Sprite_UpdateDone ; If invalid, exit

; Get character tile and calculate buffer address
	lda.L				   DATA8_049800,x ; Get tile number from map
	adc.B				   #$0a	  ; Add animation offset
	xba							   ; Swap to high byte

; Calculate tilemap coordinates
	txa							   ; Position to A
	and.B				   #$38	  ; Get Y coordinate (bits 3-5)
	asl					 a; Multiply by 2
	pha							   ; Save

	txa							   ; Position to A again
	and.B				   #$07	  ; Get X coordinate (bits 0-2)
	ora.B				   $01,s	 ; Combine with Y offset
	plx							   ; Clean stack
	asl					 a; Multiply by 2 for word addressing

	rep					 #$30		; 16-bit mode

; Update both WRAM buffers
	sta.L				   $7f0778   ; Buffer 1 - tile 1
	inc					 a
	sta.L				   $7f077a   ; Buffer 1 - tile 2
	adc.W				   #$000f	; Next row offset
	sta.L				   $7f07b8   ; Buffer 1 - tile 3
	inc					 a
	sta.L				   $7f07ba   ; Buffer 1 - tile 4

; Set update flag
	lda.W				   #$0080	; Bit 7
	tsb.W				   $00d4	 ; Set in display flags

Sprite_UpdateDone:
	plp							   ; Restore processor status
	rts							   ; Return

Sprite_UpdateSingleBufferAlt:
; Single buffer mode path
	ldx.W				   $10b1	 ; Get character position
	lda.L				   DATA8_049800,x ; Get tile number
	asl					 a; Multiply by 4
	asl					 a
	sta.W				   $00f7	 ; Store tile offset

	rep					 #$10		; 16-bit X,Y
	lda.W				   $10b1	 ; Get position
	jsr.W				   Map_PositionToVRAMAddress ; Convert to VRAM address
	stx.W				   $00f5	 ; Store VRAM address

	lda.B				   #$80	  ; Set update flag
	tsb.W				   $00d4	 ; Set in display flags

	plp							   ; Restore processor status
	rts							   ; Return

; ===========================================================================
; Convert Map Position to VRAM Address
; ===========================================================================
; Purpose: Convert 8x8 tile position to VRAM word address
; Input: A = tile position (bits 0-2: X, bits 3-5: Y)
; Output: X = VRAM word address
; ===========================================================================

Map_PositionToVRAMAddress:
	cmp.B				   #$ff	  ; Check if invalid position
	beq					 UNREACH_008D93 ; If invalid, return $ffff

	jsr.W				   Map_TilePositionToVRAM ; Calculate VRAM address
	tax							   ; Transfer to X
	rts							   ; Return

; ------------------------------------------------------------------------------
; UNREACHABLE CODE ANALYSIS
; ------------------------------------------------------------------------------
; Label: UNREACH_008D93
; Category: 🟡 Conditionally Reachable (Error Handler)
; Purpose: Error return - sets X to $FFFF and returns
; Reachability: REACHABLE via conditional branch at line 239 (beq)
; Analysis: Error handler for invalid tile position ($FF)
;   - Sets X register to $FFFF (invalid VRAM address marker)
;   - Returns immediately
;   - Triggered when Map_PositionToVRAMAddress receives $FF input
; Verified: Reachable when invalid tile position passed as parameter
; Notes: Should be renamed to something like Map_InvalidPositionReturn
;        This is NOT truly unreachable - it's an error path
; ------------------------------------------------------------------------------
UNREACH_008D93:
	ldx.W #$ffff                         ;008D93|A2FFFF  |      ; Load X with $FFFF (error marker)
	rts                                  ;008D96|60      |      ; Return from subroutine

; ===========================================================================
; Get Adjacent Tile Information
; ===========================================================================
; Purpose: Get information about tile adjacent to character
; Used for: Collision detection, interaction checks
; ===========================================================================

Map_GetAdjacentTileInfo:
	lda.W				   $1031	 ; Get current character position
	pha							   ; Save it

	lda.W				   #$0003	; Direction = right
	jsr.W				   Map_GetTileByDirection ; Get adjacent tile info

	pla							   ; Restore original position
	sta.W				   $1031	 ; Write back
	sty.B				   $9e	   ; Store result
	rts							   ; Return

; ===========================================================================
; Get Tile Information by Direction
; ===========================================================================
; Purpose: Get tile at position offset by direction
; Input: A = direction (0=up, 1=down, 2=left, 3=right)
; Output: Y = tile data, $1031 = new position
; ===========================================================================

Map_GetTileByDirection:
	php							   ; Preserve processor status
	sep					 #$30		; 8-bit A,X,Y

	pha							   ; Save direction

; Calculate offset (direction * 3 + base)
CLC_Label:
	adc.B				   $01,s	 ; Add direction again (x2)
	adc.B				   $01,s	 ; Add direction again (x3)
	adc.B				   #$22	  ; Add base offset
	tay							   ; Transfer to Y (lookup index)

	pla							   ; Restore direction

; Calculate inverse direction for position adjustment
	eor.B				   #$ff	  ; Invert bits
	sec							   ; Set carry
	adc.B				   #$04	  ; Add 4 (creates -direction)
	tax							   ; Transfer to X (shift count)

; Get character coordinates
	lda.W				   $1032	 ; Get X coordinate
	xba							   ; Swap to high byte
	lda.W				   $1033	 ; Get Y coordinate

	rep					 #$20		; 16-bit A
	sep					 #$10		; 8-bit X,Y

	lsr					 a; Start bit shifting

Map_ShiftCoordinates:
; Shift coordinates based on direction
	lsr					 a; Shift right 3 times per iteration
	lsr					 a
	lsr					 a
	dex							   ; Decrement shift counter
	bne					 Map_ShiftCoordinates ; Continue shifting

; Check collision bits
	lsr					 a; Shift out bit
	bcs					 Map_TileFound ; If carry set, tile exists

	dey							   ; Try next tile
	lsr					 a; Shift out next bit
	bcs					 Map_TileFound ; If carry set, tile exists

	dey							   ; Try next tile
	lsr					 a; Shift out next bit
	bcs					 Map_TileFound ; If carry set, tile exists

	ldy.B				   #$ff	  ; No valid tile found

Map_TileFound:
	sty.W				   $1031	 ; Store result position
	plp							   ; Restore processor status
	rts							   ; Return

; ===========================================================================
; VRAM Tile Transfer Loop
; ===========================================================================
; Purpose: Transfer multiple tiles to VRAM using optimized loop
; Input: X = source address, Y = tile count
; Technical Details: Uses direct page at $2100 for fast register access
; ===========================================================================

VRAM_TransferTileLoop:
	php							   ; Preserve processor status
	phd							   ; Preserve direct page

	rep					 #$30		; 16-bit A,X,Y
	lda.W				   #$2100	; PPU register base
	tcd							   ; Set as direct page (fast access!)

	clc							   ; Clear carry for loops

VRAM_TransferTile:
; Transfer 8 words (16 bytes) per iteration
	phy							   ; Save tile count

; Word 1
	lda.W				   $0000,x   ; Load source word
	sta.B				   SNES_VMDATAL-$2100 ; Write to VRAM data (via direct page)

; Word 2
	lda.W				   $0002,x
	sta.B				   SNES_VMDATAL-$2100

; Word 3
	lda.W				   $0004,x
	sta.B				   SNES_VMDATAL-$2100

; Word 4
	lda.W				   $0006,x
	sta.B				   SNES_VMDATAL-$2100

; Word 5
	lda.W				   $0008,x
	sta.B				   SNES_VMDATAL-$2100

; Word 6
	lda.W				   $000a,x
	sta.B				   SNES_VMDATAL-$2100

; Word 7
	lda.W				   $000c,x
	sta.B				   SNES_VMDATAL-$2100

; Word 8
	lda.W				   $000e,x
	sta.B				   SNES_VMDATAL-$2100

; Handle extra bytes (likely for 3bpp bitplane)
	lda.W				   $00f0	 ; Get extra data flag
	sep					 #$20		; 8-bit A for byte writes

; Write 8 extra bytes
	lda.W				   $0010,x
TAY_Label:
	sty.B				   SNES_VMDATAL-$2100

	lda.W				   $0011,x
TAY_Label:
	sty.B				   SNES_VMDATAL-$2100

	lda.W				   $0012,x
TAY_Label:
	sty.B				   SNES_VMDATAL-$2100

	lda.W				   $0013,x
TAY_Label:
	sty.B				   SNES_VMDATAL-$2100

	lda.W				   $0014,x
TAY_Label:
	sty.B				   SNES_VMDATAL-$2100

	lda.W				   $0015,x
TAY_Label:
	sty.B				   SNES_VMDATAL-$2100

	lda.W				   $0016,x
TAY_Label:
	sty.B				   SNES_VMDATAL-$2100

	lda.W				   $0017,x
TAY_Label:
	sty.B				   SNES_VMDATAL-$2100

	rep					 #$30		; Back to 16-bit

; Advance source pointer
TXA_Label:
	adc.W				   #$0018	; Add $18 bytes (24 bytes = one tile)
TAX_Label:

	ply							   ; Restore tile count
	dey							   ; Decrement
	bne					 VRAM_TransferTile ; Continue loop

	pld							   ; Restore direct page
	plp							   ; Restore processor status
	rtl							   ; Return from long call

; ===========================================================================
; VRAM Interleaved Write (Column Mode)
; ===========================================================================
; Purpose: Write tiles in column order with interleaved data
; Input: X = source, Y = count
; Technical Details: Writes data then $ff00, used for specific tile layouts
; ===========================================================================

VRAM_InterleavedWrite:
	php							   ; Preserve processor status
	phd							   ; Preserve direct page

	pea.W				   $2100	 ; Push PPU base
	pld							   ; Set as direct page

	sep					 #$20		; 8-bit A
	lda.B				   #$88	  ; VRAM increment after high byte write, column mode
	sta.B				   SNES_VMAINC-$2100 ; Set VRAM increment mode

	rep					 #$30		; 16-bit A,X,Y
	clc							   ; Clear carry

VRAM_InterleavedWriteLoop:
; Write data word, then $ff00, repeatedly
; This creates striped patterns in VRAM

	lda.W				   $0000,x
	sta.B				   SNES_VMDATAL-$2100
	lda.W				   $00f0	 ; Load filler value ($ff00)
	sta.B				   SNES_VMDATAL-$2100

	lda.W				   $0002,x
	sta.B				   SNES_VMDATAL-$2100
	lda.W				   $00f0
	sta.B				   SNES_VMDATAL-$2100

	lda.W				   $0004,x
	sta.B				   SNES_VMDATAL-$2100
	lda.W				   $00f0
	sta.B				   SNES_VMDATAL-$2100

	lda.W				   $0006,x
	sta.B				   SNES_VMDATAL-$2100
	lda.W				   $00f0
	sta.B				   SNES_VMDATAL-$2100

	lda.W				   $0008,x
	sta.B				   SNES_VMDATAL-$2100
	lda.W				   $00f0
	sta.B				   SNES_VMDATAL-$2100

	lda.W				   $000a,x
	sta.B				   SNES_VMDATAL-$2100
	lda.W				   $00f0
	sta.B				   SNES_VMDATAL-$2100

	lda.W				   $000c,x
	sta.B				   SNES_VMDATAL-$2100
	lda.W				   $00f0
	sta.B				   SNES_VMDATAL-$2100

	lda.W				   $000e,x
	sta.B				   SNES_VMDATAL-$2100
	lda.W				   $00f0
	sta.B				   SNES_VMDATAL-$2100

; Advance source pointer
TXA_Label:
	adc.W				   #$0010	; Add $10 bytes
TAX_Label:

	dey							   ; Decrement count
	bne					 VRAM_InterleavedWriteLoop ; Continue loop

	sep					 #$20		; 8-bit A
	lda.B				   #$80	  ; Reset to normal increment mode
	sta.B				   SNES_VMAINC-$2100

	pld							   ; Restore direct page
	plp							   ; Restore processor status
	rtl							   ; Return

;===============================================================================
; Progress: Continued documentation of Bank $00
; Lines documented: ~1,900 / 14,017 (13.5%)
; Total progress: ~2,300 / 74,682 (3.1%)
;===============================================================================
