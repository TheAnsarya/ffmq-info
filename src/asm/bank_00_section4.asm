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

CODE_008C83:
														; Get character tile from map data
					   LDA.L				   DATA8_049800,X ; Load tile number from map data
					   ASL					 A		   ; Multiply by 4 (4 bytes per tile)
					   ASL					 A
					   STA.W				   $00F4	 ; Store tile offset

					   REP					 #$10		; 16-bit X,Y
					   LDA.W				   $1031	 ; Get character map position
					   JSR.W				   CODE_008D8A ; Convert to VRAM address
					   STX.W				   $00F2	 ; Store VRAM address

					   LDX.W				   #$2D1A	; Source data pointer
					   LDA.B				   #$7E	  ; Bank $7E (WRAM)

CODE_008C9C:
														; Determine sprite attributes based on display mode
					   PHA							   ; Save bank

														; Check if special rendering mode
					   LDA.B				   #$04	  ; Check bit 2
					   AND.W				   $00DA	 ; Test display flags
					   BEQ					 CODE_008CC5 ; If clear, use normal rendering

														; Check frame counter for animation
					   LDA.W				   $0014	 ; Get frame counter
					   DEC					 A
					   BEQ					 CODE_008CC5 ; If zero, use normal

														; Check if battle mode
					   LDA.B				   #$10	  ; Check bit 4
					   AND.W				   $00DA	 ; Test battle flag
					   BNE					 CODE_008CBB ; If set, use battle sprite

														; Field sprite attributes (incomplete in original)
PLB:
					   LDA.W				   $0001,X   ; Get sprite attribute byte
					   AND.B				   #$E3	  ; Mask palette bits
					   ORA.B				   #$94	  ; Set field palette
					   BRA					 CODE_008CCD ; Apply attributes

CODE_008CBB:
														; Battle sprite attributes
PLB:
					   LDA.W				   $0001,X   ; Get sprite attribute byte
					   AND.B				   #$E3	  ; Mask palette bits
					   ORA.B				   #$9C	  ; Set battle palette
					   BRA					 CODE_008CCD ; Apply attributes

CODE_008CC5:
														; Normal sprite attributes
PLB:
					   LDA.W				   $0001,X   ; Get sprite attribute byte
					   AND.B				   #$E3	  ; Mask palette bits
					   ORA.B				   #$88	  ; Set normal palette

CODE_008CCD:
														; Apply sprite attributes
					   XBA							   ; Swap to high byte

														; Check character position range
					   LDA.L				   $001031   ; Get character position
					   CMP.B				   #$29	  ; Compare to boundary
					   BCC					 CODE_008D11 ; If below, use standard display
					   CMP.B				   #$2C	  ; Compare to upper boundary
					   BEQ					 CODE_008D11 ; If equal, use standard

														; Special position handling (likely stair/elevation display)
					   LDA.W				   $0001,X   ; Get attribute byte
					   AND.B				   #$63	  ; Mask bits
					   ORA.B				   #$08	  ; Set special bit
					   STA.W				   $0001,X   ; Store to OAM +1
					   STA.W				   $0003,X   ; Store to OAM +3

														; Convert X position to decimal digits for display
					   LDA.L				   $001030   ; Get X coordinate
					   LDY.W				   #$FFFF	; Initialize digit counter
					   SEC							   ; Set carry for subtraction

CODE_008CEF:
														; Divide by 10 to get digits
					   INY							   ; Increment digit count
					   SBC.B				   #$0A	  ; Subtract 10
					   BCS					 CODE_008CEF ; If still positive, continue

					   ADC.B				   #$8A	  ; Add tile offset for digits (adjust remainder)
					   STA.W				   $0002,X   ; Store ones digit tile

														; Handle tens digit
					   CPY.W				   #$0000	; Check if any tens
					   BEQ					 UNREACH_008D06 ; If zero, skip tens display

					   TYA							   ; Get tens count
					   ADC.B				   #$7F	  ; Add tile offset for tens
					   STA.W				   $0000,X   ; Store tens digit tile
					   BRA					 CODE_008D20 ; Done

UNREACH_008D06:
														; No tens digit (position < 10)
db											 $A9,$45,$9D,$00,$00,$EB,$9D,$01,$00,$80,$0F ; Unreachable code segment

CODE_008D11:
														; Standard character sprite display
					   XBA							   ; Restore attribute byte
					   STA.W				   $0001,X   ; Store to OAM +1
					   STA.W				   $0003,X   ; Store to OAM +3

					   LDA.B				   #$45	  ; Default tile number
					   STA.W				   $0000,X   ; Store to OAM +0
					   STA.W				   $0002,X   ; Store to OAM +2

CODE_008D20:
														; Finalize sprite update
					   PHK							   ; Push program bank
					   PLB							   ; Pull to data bank

					   LDA.B				   #$80	  ; Set update flag
					   TSB.W				   $00D4	 ; Set bit in display flags

					   PLP							   ; Restore processor status
					   RTS							   ; Return

														; ===========================================================================
														; Character Sprite Update - Layer 2 (Dual Buffer Mode)
														; ===========================================================================
														; Purpose: Update character sprite in battle/transition mode with dual buffers
														; Technical Details: Updates both WRAM buffers for smooth transitions
														; ===========================================================================

CODE_008D29:
					   PHP							   ; Preserve processor status
					   SEP					 #$30		; 8-bit A,X,Y

														; Check if dual buffer mode active
					   LDA.B				   #$02	  ; Check bit 1
					   AND.W				   $00D8	 ; Test display mode flags
					   BEQ					 CODE_008D6C ; If clear, single buffer mode

														; Dual buffer mode - get character position
					   LDX.W				   $10B1	 ; Get character map position
					   CPX.B				   #$FF	  ; Check if valid
					   BEQ					 CODE_008D6A ; If invalid, exit

														; Get character tile and calculate buffer address
					   LDA.L				   DATA8_049800,X ; Get tile number from map
					   ADC.B				   #$0A	  ; Add animation offset
					   XBA							   ; Swap to high byte

														; Calculate tilemap coordinates
					   TXA							   ; Position to A
					   AND.B				   #$38	  ; Get Y coordinate (bits 3-5)
					   ASL					 A		   ; Multiply by 2
					   PHA							   ; Save

					   TXA							   ; Position to A again
					   AND.B				   #$07	  ; Get X coordinate (bits 0-2)
					   ORA.B				   $01,S	 ; Combine with Y offset
					   PLX							   ; Clean stack
					   ASL					 A		   ; Multiply by 2 for word addressing

					   REP					 #$30		; 16-bit mode

														; Update both WRAM buffers
					   STA.L				   $7F0778   ; Buffer 1 - tile 1
					   INC					 A
					   STA.L				   $7F077A   ; Buffer 1 - tile 2
					   ADC.W				   #$000F	; Next row offset
					   STA.L				   $7F07B8   ; Buffer 1 - tile 3
					   INC					 A
					   STA.L				   $7F07BA   ; Buffer 1 - tile 4

														; Set update flag
					   LDA.W				   #$0080	; Bit 7
					   TSB.W				   $00D4	 ; Set in display flags

CODE_008D6A:
					   PLP							   ; Restore processor status
					   RTS							   ; Return

CODE_008D6C:
														; Single buffer mode path
					   LDX.W				   $10B1	 ; Get character position
					   LDA.L				   DATA8_049800,X ; Get tile number
					   ASL					 A		   ; Multiply by 4
					   ASL					 A
					   STA.W				   $00F7	 ; Store tile offset

					   REP					 #$10		; 16-bit X,Y
					   LDA.W				   $10B1	 ; Get position
					   JSR.W				   CODE_008D8A ; Convert to VRAM address
					   STX.W				   $00F5	 ; Store VRAM address

					   LDA.B				   #$80	  ; Set update flag
					   TSB.W				   $00D4	 ; Set in display flags

					   PLP							   ; Restore processor status
					   RTS							   ; Return

														; ===========================================================================
														; Convert Map Position to VRAM Address
														; ===========================================================================
														; Purpose: Convert 8x8 tile position to VRAM word address
														; Input: A = tile position (bits 0-2: X, bits 3-5: Y)
														; Output: X = VRAM word address
														; ===========================================================================

CODE_008D8A:
					   CMP.B				   #$FF	  ; Check if invalid position
					   BEQ					 UNREACH_008D93 ; If invalid, return $FFFF

					   JSR.W				   CODE_008C1B ; Calculate VRAM address
					   TAX							   ; Transfer to X
					   RTS							   ; Return

UNREACH_008D93:
db											 $A2,$FF,$FF,$60 ; Unreachable: LDX #$FFFF, RTS

														; ===========================================================================
														; Get Adjacent Tile Information
														; ===========================================================================
														; Purpose: Get information about tile adjacent to character
														; Used for: Collision detection, interaction checks
														; ===========================================================================

CODE_008D97:
					   LDA.W				   $1031	 ; Get current character position
					   PHA							   ; Save it

					   LDA.W				   #$0003	; Direction = right
					   JSR.W				   CODE_008DA8 ; Get adjacent tile info

					   PLA							   ; Restore original position
					   STA.W				   $1031	 ; Write back
					   STY.B				   $9E	   ; Store result
					   RTS							   ; Return

														; ===========================================================================
														; Get Tile Information by Direction
														; ===========================================================================
														; Purpose: Get tile at position offset by direction
														; Input: A = direction (0=up, 1=down, 2=left, 3=right)
														; Output: Y = tile data, $1031 = new position
														; ===========================================================================

CODE_008DA8:
					   PHP							   ; Preserve processor status
					   SEP					 #$30		; 8-bit A,X,Y

					   PHA							   ; Save direction

														; Calculate offset (direction * 3 + base)
CLC:
					   ADC.B				   $01,S	 ; Add direction again (x2)
					   ADC.B				   $01,S	 ; Add direction again (x3)
					   ADC.B				   #$22	  ; Add base offset
					   TAY							   ; Transfer to Y (lookup index)

					   PLA							   ; Restore direction

														; Calculate inverse direction for position adjustment
					   EOR.B				   #$FF	  ; Invert bits
					   SEC							   ; Set carry
					   ADC.B				   #$04	  ; Add 4 (creates -direction)
					   TAX							   ; Transfer to X (shift count)

														; Get character coordinates
					   LDA.W				   $1032	 ; Get X coordinate
					   XBA							   ; Swap to high byte
					   LDA.W				   $1033	 ; Get Y coordinate

					   REP					 #$20		; 16-bit A
					   SEP					 #$10		; 8-bit X,Y

					   LSR					 A		   ; Start bit shifting

CODE_008DC7:
														; Shift coordinates based on direction
					   LSR					 A		   ; Shift right 3 times per iteration
					   LSR					 A
					   LSR					 A
					   DEX							   ; Decrement shift counter
					   BNE					 CODE_008DC7 ; Continue shifting

														; Check collision bits
					   LSR					 A		   ; Shift out bit
					   BCS					 CODE_008DDA ; If carry set, tile exists

					   DEY							   ; Try next tile
					   LSR					 A		   ; Shift out next bit
					   BCS					 CODE_008DDA ; If carry set, tile exists

					   DEY							   ; Try next tile
					   LSR					 A		   ; Shift out next bit
					   BCS					 CODE_008DDA ; If carry set, tile exists

					   LDY.B				   #$FF	  ; No valid tile found

CODE_008DDA:
					   STY.W				   $1031	 ; Store result position
					   PLP							   ; Restore processor status
					   RTS							   ; Return

														; ===========================================================================
														; VRAM Tile Transfer Loop
														; ===========================================================================
														; Purpose: Transfer multiple tiles to VRAM using optimized loop
														; Input: X = source address, Y = tile count
														; Technical Details: Uses direct page at $2100 for fast register access
														; ===========================================================================

CODE_008DDF:
					   PHP							   ; Preserve processor status
					   PHD							   ; Preserve direct page

					   REP					 #$30		; 16-bit A,X,Y
					   LDA.W				   #$2100	; PPU register base
					   TCD							   ; Set as direct page (fast access!)

					   CLC							   ; Clear carry for loops

CODE_008DE8:
														; Transfer 8 words (16 bytes) per iteration
					   PHY							   ; Save tile count

														; Word 1
					   LDA.W				   $0000,X   ; Load source word
					   STA.B				   SNES_VMDATAL-$2100 ; Write to VRAM data (via direct page)

														; Word 2
					   LDA.W				   $0002,X
					   STA.B				   SNES_VMDATAL-$2100

														; Word 3
					   LDA.W				   $0004,X
					   STA.B				   SNES_VMDATAL-$2100

														; Word 4
					   LDA.W				   $0006,X
					   STA.B				   SNES_VMDATAL-$2100

														; Word 5
					   LDA.W				   $0008,X
					   STA.B				   SNES_VMDATAL-$2100

														; Word 6
					   LDA.W				   $000A,X
					   STA.B				   SNES_VMDATAL-$2100

														; Word 7
					   LDA.W				   $000C,X
					   STA.B				   SNES_VMDATAL-$2100

														; Word 8
					   LDA.W				   $000E,X
					   STA.B				   SNES_VMDATAL-$2100

														; Handle extra bytes (likely for 3bpp bitplane)
					   LDA.W				   $00F0	 ; Get extra data flag
					   SEP					 #$20		; 8-bit A for byte writes

														; Write 8 extra bytes
					   LDA.W				   $0010,X
TAY:
					   STY.B				   SNES_VMDATAL-$2100

					   LDA.W				   $0011,X
TAY:
					   STY.B				   SNES_VMDATAL-$2100

					   LDA.W				   $0012,X
TAY:
					   STY.B				   SNES_VMDATAL-$2100

					   LDA.W				   $0013,X
TAY:
					   STY.B				   SNES_VMDATAL-$2100

					   LDA.W				   $0014,X
TAY:
					   STY.B				   SNES_VMDATAL-$2100

					   LDA.W				   $0015,X
TAY:
					   STY.B				   SNES_VMDATAL-$2100

					   LDA.W				   $0016,X
TAY:
					   STY.B				   SNES_VMDATAL-$2100

					   LDA.W				   $0017,X
TAY:
					   STY.B				   SNES_VMDATAL-$2100

					   REP					 #$30		; Back to 16-bit

														; Advance source pointer
TXA:
					   ADC.W				   #$0018	; Add $18 bytes (24 bytes = one tile)
TAX:

					   PLY							   ; Restore tile count
					   DEY							   ; Decrement
					   BNE					 CODE_008DE8 ; Continue loop

					   PLD							   ; Restore direct page
					   PLP							   ; Restore processor status
					   RTL							   ; Return from long call

														; ===========================================================================
														; VRAM Interleaved Write (Column Mode)
														; ===========================================================================
														; Purpose: Write tiles in column order with interleaved data
														; Input: X = source, Y = count
														; Technical Details: Writes data then $FF00, used for specific tile layouts
														; ===========================================================================

CODE_008E54:
					   PHP							   ; Preserve processor status
					   PHD							   ; Preserve direct page

					   PEA.W				   $2100	 ; Push PPU base
					   PLD							   ; Set as direct page

					   SEP					 #$20		; 8-bit A
					   LDA.B				   #$88	  ; VRAM increment after high byte write, column mode
					   STA.B				   SNES_VMAINC-$2100 ; Set VRAM increment mode

					   REP					 #$30		; 16-bit A,X,Y
					   CLC							   ; Clear carry

CODE_008E63:
														; Write data word, then $FF00, repeatedly
														; This creates striped patterns in VRAM

					   LDA.W				   $0000,X
					   STA.B				   SNES_VMDATAL-$2100
					   LDA.W				   $00F0	 ; Load filler value ($FF00)
					   STA.B				   SNES_VMDATAL-$2100

					   LDA.W				   $0002,X
					   STA.B				   SNES_VMDATAL-$2100
					   LDA.W				   $00F0
					   STA.B				   SNES_VMDATAL-$2100

					   LDA.W				   $0004,X
					   STA.B				   SNES_VMDATAL-$2100
					   LDA.W				   $00F0
					   STA.B				   SNES_VMDATAL-$2100

					   LDA.W				   $0006,X
					   STA.B				   SNES_VMDATAL-$2100
					   LDA.W				   $00F0
					   STA.B				   SNES_VMDATAL-$2100

					   LDA.W				   $0008,X
					   STA.B				   SNES_VMDATAL-$2100
					   LDA.W				   $00F0
					   STA.B				   SNES_VMDATAL-$2100

					   LDA.W				   $000A,X
					   STA.B				   SNES_VMDATAL-$2100
					   LDA.W				   $00F0
					   STA.B				   SNES_VMDATAL-$2100

					   LDA.W				   $000C,X
					   STA.B				   SNES_VMDATAL-$2100
					   LDA.W				   $00F0
					   STA.B				   SNES_VMDATAL-$2100

					   LDA.W				   $000E,X
					   STA.B				   SNES_VMDATAL-$2100
					   LDA.W				   $00F0
					   STA.B				   SNES_VMDATAL-$2100

														; Advance source pointer
TXA:
					   ADC.W				   #$0010	; Add $10 bytes
TAX:

					   DEY							   ; Decrement count
					   BNE					 CODE_008E63 ; Continue loop

					   SEP					 #$20		; 8-bit A
					   LDA.B				   #$80	  ; Reset to normal increment mode
					   STA.B				   SNES_VMAINC-$2100

					   PLD							   ; Restore direct page
					   PLP							   ; Restore processor status
					   RTL							   ; Return

														;===============================================================================
														; Progress: Continued documentation of Bank $00
														; Lines documented: ~1,900 / 14,017 (13.5%)
														; Total progress: ~2,300 / 74,682 (3.1%)
														;===============================================================================
