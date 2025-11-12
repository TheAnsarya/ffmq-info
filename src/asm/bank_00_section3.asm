; ===========================================================================
; Character Status Animation (continued from earlier sections)
; ===========================================================================

StatusIcon_CheckCharacterSlot5:
; Check character slot 5
	lda.L				   $70073f   ; Check character 5 in party data
	bne					 StatusIcon_CheckCharacterSlot6 ; If present, skip animation
	ldx.B				   #$80	  ; Animation offset for slot 5
	jsr.W				   AnimateStatusIcon ; Animate status icon

StatusIcon_CheckCharacterSlot6:
; Check character slot 6
	lda.L				   $70078f   ; Check character 6 in party data
	bne					 StatusIcon_SetUpdateFlag ; If present, skip animation
	ldx.B				   #$90	  ; Animation offset for slot 6
	jsr.W				   AnimateStatusIcon ; Animate status icon

StatusIcon_SetUpdateFlag:
; Set update flag and return
	lda.B				   #$20	  ; Bit 5 flag
	tsb.W				   $00d2	 ; Set bit in display flags

StatusIcon_AnimationComplete:
	rep					 #$30		; 16-bit A, X, Y
	pld							   ; Restore direct page
	rts							   ; Return

; ===========================================================================
; Animate Status Icon
; ===========================================================================
; Purpose: Toggle character status icon animation frame
; Input: X = OAM data offset for character slot
; Technical Details: Toggles tile numbers to create animation effect
; ===========================================================================

StatusIcon_ToggleTileFrame:
; Toggle tile animation frame
	lda.B				   $02,x	 ; Get current tile number
	eor.B				   #$04	  ; Toggle bit 2 (animation frame)
	sta.B				   $02,x	 ; Store back to OAM

; Update adjacent sprite tiles
	inc					 a; Next tile
	sta.W				   $0c06,x   ; Store to OAM +4
	inc					 a; Next tile
	sta.W				   $0c0a,x   ; Store to OAM +8
	inc					 a; Next tile
	sta.W				   $0c0e,x   ; Store to OAM +12
	rts							   ; Return

; ===========================================================================
; Input Handler Jump Table
; ===========================================================================
; Purpose: Dispatch table for different input contexts
; Format: Table of 16-bit addresses for input handler functions
; ===========================================================================

Input_Handler_Table:
	dw											 Input_Down  ; $008a3d: Down button handler
	dw											 Input_Up	; $008a3f: Up button handler
	dw											 Input_Action ; $008a41: A/B button handler
	dw											 Input_Action ; $008a43: (duplicate)
	dw											 Input_Left  ; $008a45: Left button handler
	dw											 Input_Right ; $008a47: Right button handler
	dw											 Input_Right ; $008a49: (alternate)
	dw											 Input_Left  ; $008a4b: (alternate)
	dw											 Input_Action ; $008a4d: (action variant)
	dw											 Input_Action ; $008a4f: (action variant)
	dw											 Input_Switch_Character ; $008a51: Character switch
	dw											 Input_Action ; $008a53: (action variant)

; ===========================================================================
; Menu Cursor Movement - Vertical
; ===========================================================================

Input_Left:
	dec.B				   $02	   ; Move cursor left
	bra					 Validate_Cursor_Position ; Check bounds

Input_Right:
	inc.B				   $02	   ; Move cursor right
	bra					 Validate_Cursor_Position ; Check bounds

Input_Up:
	dec.B				   $01	   ; Move cursor up
	bra					 Validate_Cursor_Position ; Check bounds

Input_Down:
	inc.B				   $01	   ; Move cursor down
; Fall through to validation

; ===========================================================================
; Validate Cursor Position
; ===========================================================================
; Purpose: Ensure cursor stays within menu bounds, handle wrapping
; Technical Details: Checks against bounds in $03/$04, handles wrap flags
; ===========================================================================

Validate_Cursor_Position:
; Check vertical bounds
	lda.B				   $01	   ; Get cursor Y position
	bmi					 Cursor_Above_Top ; If negative, handle wrap
	cmp.B				   $03	   ; Compare to max Y
	bcc					 Cursor_Horizontal_Check ; If within bounds, check horizontal

; Cursor below bottom
	lda.B				   $95	   ; Get wrap flags
	and.B				   #$01	  ; Check vertical wrap down flag
	bne					 Cursor_Above_Top ; If set, wrap to top

Clamp_Cursor_Bottom:
	lda.B				   $03	   ; Get max Y
	dec					 a; Subtract 1
	sta.B				   $01	   ; Clamp cursor to bottom
	bra					 Cursor_Horizontal_Check ; Check horizontal

Cursor_Above_Top:
; Cursor above top
	lda.B				   $95	   ; Get wrap flags
	and.B				   #$02	  ; Check vertical wrap up flag
	bne					 Clamp_Cursor_Bottom ; If set, wrap to bottom
	stz.B				   $01	   ; Clamp cursor to top

Cursor_Horizontal_Check:
; Check horizontal bounds
	lda.B				   $02	   ; Get cursor X position
	bmi					 Cursor_Left_Of_Min ; If negative, handle wrap
	cmp.B				   $04	   ; Compare to max X
	bcc					 Cursor_Valid ; If within bounds, done

; Cursor right of maximum
	lda.B				   $95	   ; Get wrap flags
	and.B				   #$04	  ; Check horizontal wrap right flag
	bne					 Cursor_Left_Of_Min ; If set, wrap to left

Clamp_Cursor_Right:
	lda.B				   $04	   ; Get max X
	dec					 a; Subtract 1
	sta.B				   $02	   ; Clamp cursor to right
	rts							   ; Done

Cursor_Left_Of_Min:
; Cursor left of minimum
	lda.B				   $95	   ; Get wrap flags
	and.B				   #$08	  ; Check horizontal wrap left flag
	bne					 Clamp_Cursor_Right ; If set, wrap to right
	stz.B				   $02	   ; Clamp cursor to left

Cursor_Valid:
	rts							   ; Return

; ===========================================================================
; Character Switch Input Handler
; ===========================================================================
; Purpose: Handle character switching in menu/field
; Technical Details: Toggles between Benjamin and Phoebe
; ===========================================================================

Input_Switch_Character:
	jsr.W				   Input_CheckBlocking ; Check if switching allowed
	bne					 Switch_Done ; If not allowed, exit

; Check if character is valid
	lda.W				   $1090	 ; Get character status
	bmi					 Play_Error_Sound ; If invalid, play error

; Toggle character
	lda.W				   $10a0	 ; Get character flags
	eor.B				   #$80	  ; Toggle bit 7 (Benjamin/Phoebe)
	sta.W				   $10a0	 ; Store new character

; Update display
	lda.B				   #$40	  ; Set update flag
	tsb.W				   $00d4	 ; Set in display flags
	jsr.W				   NormalPositionCallB908 ; Update character sprite
	bra					 Switch_Done ; Done

Play_Error_Sound:
	jsr.W				   AlternateCharacterUpdateRoutine ; Play error sound

Switch_Done:
	rts							   ; Return

; ===========================================================================
; Menu Action Validation
; ===========================================================================
; Purpose: Check if menu action at current position is valid
; Technical Details: Validates based on map position and character state
; ===========================================================================

Menu_ValidateAction:
; Check if on valid action tile
	lda.W				   $1032	 ; Get tile X position
	cmp.B				   #$80	  ; Compare to invalid marker
	bne					 Action_Valid ; If not marker, action valid
	lda.W				   $1033	 ; Get tile Y position
	bne					 Action_Valid ; If not zero, action valid
	jmp.W				   AlternateCharacterUpdateRoutine ; Invalid: play error sound

Action_Valid:
	jmp.W				   NormalPositionCallB908 ; Valid: play confirm sound

; ===========================================================================
; Menu Scroll - Down
; ===========================================================================
; Purpose: Scroll menu list downward
; Technical Details: Calculates next visible item, updates display
; ===========================================================================

Scroll_Menu_Down:
	jsr.W				   Input_CheckBlocking ; Check if scrolling allowed
	bne					 Scroll_Down_Done ; If blocked, exit
	jsr.W				   Menu_ValidateAction ; Play appropriate sound

; Calculate current row from pixel position
	lda.W				   $1031	 ; Get Y pixel position
	sec							   ; Set carry for subtraction
	sbc.B				   #$20	  ; Subtract top margin (32 pixels)
	ldx.B				   #$ff	  ; Initialize row counter to -1

Count_Rows_Down:
	inx							   ; Increment row counter
	sbc.B				   #$03	  ; Subtract row height (3 pixels)
	bcs					 Count_Rows_Down ; If still positive, continue counting

; TXA now contains current row number
	txa							   ; Transfer row to A

Find_Next_Valid_Row:
	inc					 a; Next row
	and.B				   #$03	  ; Wrap to 0-3 range
	pha							   ; Save row number
	jsr.W				   CheckIfCharacterIsValid ; Check if row has valid item
	pla							   ; Restore row number
	cpy.B				   #$ff	  ; Check if item valid
	beq					 Find_Next_Valid_Row ; If invalid, try next row

; Update display with new row
	jsr.W				   Menu_UpdateDisplay ; Update menu display
	jsr.W				   Menu_UpdateCharacterTile ; Update graphics

Scroll_Down_Done:
	rts							   ; Return

; ===========================================================================
; Menu Scroll - Up
; ===========================================================================
; Purpose: Scroll menu list upward
; Technical Details: Similar to down scroll but decrements
; ===========================================================================

Scroll_Menu_Up:
	jsr.W				   Input_CheckBlocking ; Check if scrolling allowed
	bne					 Scroll_Up_Done ; If blocked, exit
	jsr.W				   Menu_ValidateAction ; Play appropriate sound

; Calculate current row
	lda.W				   $1031	 ; Get Y pixel position
	sec							   ; Set carry
	sbc.B				   #$20	  ; Subtract top margin
	ldx.B				   #$ff	  ; Initialize counter

Count_Rows_Up:
	inx							   ; Increment counter
	sbc.B				   #$03	  ; Subtract row height
	bcs					 Count_Rows_Up ; Continue counting

	txa							   ; Transfer row to A

Find_Previous_Valid_Row:
	dec					 a; Previous row
	and.B				   #$03	  ; Wrap to 0-3 range
	pha							   ; Save row number
	jsr.W				   CheckIfCharacterIsValid ; Check if row has valid item
	pla							   ; Restore row number
	cpy.B				   #$ff	  ; Check if valid
	beq					 Find_Previous_Valid_Row ; If invalid, try previous

; Update display
	jsr.W				   Menu_UpdateDisplay ; Update menu display
	jsr.W				   Menu_UpdateCharacterTile ; Update graphics

Scroll_Up_Done:
	rts							   ; Return

; ===========================================================================
; Update Menu Display
; ===========================================================================
; Purpose: Update menu tilemap based on current selection
; Technical Details: Copies appropriate tile data to WRAM buffer
; ===========================================================================

Menu_UpdateDisplay:
	rep					 #$30		; 16-bit A, X, Y

; Determine source tilemap based on Y position
	ldx.W				   #$3709	; Default source (rows 0-2)
	cpy.W				   #$0023	; Check if Y < $23
	bcc					 Copy_Menu_Tiles ; If yes, use default

	ldx.W				   #$3719	; Source for rows 3-5
	cpy.W				   #$0026	; Check if Y < $26
	bcc					 Copy_Menu_Tiles ; If yes, use this source

	ldx.W				   #$3729	; Source for rows 6-8
	cpy.W				   #$0029	; Check if Y < $29
	bcc					 Copy_Menu_Tiles ; If yes, use this source

	ldx.W				   #$3739	; Source for rows 9+

Copy_Menu_Tiles:
	ldy.W				   #$3669	; Destination in WRAM
	lda.W				   #$000f	; Copy 16 bytes
	mvn					 $7e,$7e	 ; Block move within bank $7e

; Restore state and redraw layer
	phk							   ; Push program bank
	plb							   ; Pull to data bank
	lda.W				   #$0000	; Layer 0
	jsr.W				   RedrawLayerRoutine ; Redraw layer

	sep					 #$30		; 8-bit A, X, Y
	lda.B				   #$80	  ; Set update flag
	tsb.W				   $00d9	 ; Set in status flags
	rts							   ; Return

; ===========================================================================
; Check Input Blocking Flags
; ===========================================================================
; Purpose: Determine if input should be blocked
; Output: Z flag set if input blocked
; ===========================================================================

Input_CheckBlocking:
	lda.B				   #$10	  ; Check bit 4
	and.W				   $00d6	 ; Test blocking flags
	beq					 Input_Not_Blocked ; If clear, input allowed

; Input is blocked, clear certain button flags
	rep					 #$30		; 16-bit A, X, Y
	lda.B				   $92	   ; Get current joypad state
	and.W				   #$bfcf	; Clear bits 4,5,14 (A,B,X buttons?)
	sep					 #$30		; 8-bit A, X, Y

Input_Not_Blocked:
	rts							   ; Return (Z flag indicates status)

; ===========================================================================
; Tile Position to VRAM Address Calculation
; ===========================================================================
; Purpose: Convert tile coordinates to VRAM address
; Input: A = tile position (3 bits Y, 3 bits X in bits 0-5)
; Output: A = VRAM address
; ===========================================================================

Map_TilePositionToVRAM:
	php							   ; Preserve processor status
	rep					 #$30		; 16-bit A, X, Y
	and.W				   #$00ff	; Clear high byte
	pha							   ; Save original value

; Extract Y coordinate (bits 3-5)
	and.W				   #$0038	; Mask to get bits 3-5 (Y * 8)
	asl					 a; Multiply by 2 (Y * 16)
	tax							   ; Save Y offset in X

; Extract X coordinate (bits 0-2)
	pla							   ; Restore original value
	and.W				   #$0007	; Mask to get bits 0-2 (X)
	phx							   ; Save Y offset
	adc.B				   $01,s	 ; Add Y offset
	sta.B				   $01,s	 ; Store back

; Calculate final VRAM address
	asl					 a; Multiply by 2
	adc.B				   $01,s	 ; Add previous result (x3)
	asl					 a; Multiply by 16 (shift left 4)
	asl					 a
	asl					 a
	asl					 a
	adc.W				   #$8000	; Add VRAM base address

	plx							   ; Clean up stack
	plp							   ; Restore processor status
	rts							   ; Return

; ===========================================================================
; Update Character Tile on Map
; ===========================================================================
; Purpose: Update character sprite tile in dual buffer mode
; Technical Details: Updates both WRAM buffers for seamless display
; ===========================================================================

Menu_UpdateCharacterTile:
	php							   ; Preserve processor status
	sep					 #$30		; 8-bit A, X, Y

	ldx.W				   $1031	 ; Get character map position
	cpx.B				   #$ff	  ; Check if valid position
	beq					 Update_Done ; If invalid, exit

; Check if dual buffer mode active (battle/transition)
	lda.B				   #$02	  ; Check bit 1
	and.W				   $00d8	 ; Test display mode flags
	beq					 Single_Buffer_Update ; If clear, single buffer only

; Dual buffer mode - update both WRAM buffers
	lda.L				   DATA8_049800,x ; Get character tile number
	adc.B				   #$0a	  ; Add offset for animation frame
	xba							   ; Swap to high byte

; Calculate tilemap address
	txa							   ; Position to A
	and.B				   #$38	  ; Get Y coordinate (bits 3-5)
	asl					 a; Multiply by 2
	pha							   ; Save
	txa							   ; Position to A again
	and.B				   #$07	  ; Get X coordinate (bits 0-2)
	ora.B				   $01,s	 ; Combine with Y offset
	plx							   ; Clean stack
	asl					 a; Multiply by 2
	rep					 #$30		; 16-bit mode

; Store to both buffers
	sta.L				   $7f075a   ; Buffer 1 - tile 1
	inc					 a
	sta.L				   $7f075c   ; Buffer 1 - tile 2
	adc.W				   #$000f	; Next row offset
	sta.L				   $7f079a   ; Buffer 1 - tile 3
	inc					 a
	sta.L				   $7f079c   ; Buffer 1 - tile 4

	sep					 #$20		; 8-bit A
	ldx.W				   #$17da	; Source data pointer
	lda.B				   #$7f	  ; Bank $7f
	bra					 Perform_DMA_Update ; Do DMA transfer

Update_Done:
	plp							   ; Restore status
	rts							   ; Return

Single_Buffer_Update:
; Handle single buffer update
; (code continues...)

Perform_DMA_Update:
; Execute DMA transfer to update VRAM
; (code continues...)

;===============================================================================
; Progress: ~1,500 lines documented (10.7% of Bank $00)
; Sections completed:
; - Boot sequence and hardware init
; - DMA and graphics transfers
; - VBlank processing
; - Menu navigation and cursor movement
; - Input handling and validation
; - Character switching
; - Tilemap updates
;
; Remaining: ~12,500 lines (battle system, map scrolling, more menus, etc.)
;===============================================================================
