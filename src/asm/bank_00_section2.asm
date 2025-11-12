; ===========================================================================
; Graphics Transfer - Battle Mode
; ===========================================================================
; Purpose: Upload battle graphics to VRAM during battle transitions
; Technical Details: Transfers character tiles and tilemap data
; Registers Used: A, X, Y
; ===========================================================================

Graphics_TransferBattleMode:
; Setup VRAM address for character data
	ldx.W				   #$4400	; VRAM address $4400
	stx.W				   SNES_VMADDL ; Set VRAM write address

; Configure DMA for 2-byte sequential write (VMDATAL/VMDATAH)
	ldx.W				   #$1801	; DMA mode: word write, increment source
	stx.B				   SNES_DMA5PARAM-$4300 ; Set DMA5 parameters

; Transfer character graphics from $7f0480
	ldx.W				   #$0480	; Source: $7f0480
	stx.B				   SNES_DMA5ADDRL-$4300 ; Set source address (low/mid)
	lda.B				   #$7f	  ; Bank $7f (WRAM)
	sta.B				   SNES_DMA5ADDRH-$4300 ; Set source bank
	ldx.W				   #$0280	; Transfer size: $0280 bytes (640 bytes)
	stx.B				   SNES_DMA5CNTL-$4300 ; Set transfer size
	lda.B				   #$20	  ; Trigger DMA channel 5
	sta.W				   SNES_MDMAEN ; Execute transfer

; Transfer tilemap data to VRAM $5820
	ldx.W				   #$5820	; VRAM address $5820
	stx.W				   SNES_VMADDL ; Set VRAM write address
	ldx.W				   #$2040	; Source: $7e2040
	stx.B				   SNES_DMA5ADDRL-$4300 ; Set source address
	lda.B				   #$7e	  ; Bank $7e (WRAM)
	sta.B				   SNES_DMA5ADDRH-$4300 ; Set source bank
	ldx.W				   #$0b00	; Transfer size: $0b00 bytes (2816 bytes)
	stx.B				   SNES_DMA5CNTL-$4300 ; Set transfer size
	lda.B				   #$20	  ; Trigger DMA channel 5
	sta.W				   SNES_MDMAEN ; Execute transfer

; Set flag indicating graphics updated
	lda.B				   #$40	  ; Bit 6 flag
	tsb.W				   $00d2	 ; Set bit in status flags
	jsr.W				   CodeAnalysis ; Transfer OAM data
	rtl							   ; Return from long call

; ===========================================================================
; Graphics Update - Field Mode
; ===========================================================================
; Purpose: Update field/map graphics during gameplay
; Technical Details: Conditional updates based on game state flags
; Side Effects: Updates VRAM, modifies status flags
; ===========================================================================

Graphics_UpdateFieldMode:
; Setup VRAM for vertical increment mode
	lda.B				   #$80	  ; Increment after writing to $2119
	sta.W				   SNES_VMAINC ; Set VRAM increment mode

; Check if battle mode graphics needed
	lda.B				   #$10	  ; Check bit 4 of display flags
	and.W				   $00da	 ; Test against display status
	bne					 Graphics_TransferBattleMode ; If set, do battle graphics transfer

; Field mode graphics update
	ldx.W				   $0042	 ; Get current VRAM address from variable
	stx.W				   SNES_VMADDL ; Set VRAM write address

; Setup DMA for character tile transfer
	ldx.W				   #$1801	; DMA mode: word write, increment
	stx.B				   SNES_DMA5PARAM-$4300 ; Set DMA5 parameters
	ldx.W				   #$0040	; Source: $7f0040
	stx.B				   SNES_DMA5ADDRL-$4300 ; Set source address
	lda.B				   #$7f	  ; Bank $7f (WRAM)
	sta.B				   SNES_DMA5ADDRH-$4300 ; Set source bank
	ldx.W				   #$07c0	; Transfer size: $07c0 bytes (1984 bytes)
	stx.B				   SNES_DMA5CNTL-$4300 ; Set transfer size
	lda.B				   #$20	  ; Trigger DMA channel 5
	sta.W				   SNES_MDMAEN ; Execute transfer

	rep					 #$30		; 16-bit A, X, Y
	clc							   ; Clear carry for addition
	lda.W				   $0042	 ; Get VRAM address
	adc.W				   #$1000	; Add $1000 for next section
	sta.W				   SNES_VMADDL ; Set new VRAM address
	sep					 #$20		; 8-bit A

; Transfer second section of tiles
	ldx.W				   #$1801	; DMA mode: word write
	stx.B				   SNES_DMA5PARAM-$4300 ; Set DMA5 parameters
	ldx.W				   #$1040	; Source: $7f1040
	stx.B				   SNES_DMA5ADDRL-$4300 ; Set source address
	lda.B				   #$7f	  ; Bank $7f (WRAM)
	sta.B				   SNES_DMA5ADDRH-$4300 ; Set source bank
	ldx.W				   #$07c0	; Transfer size: $07c0 bytes
	stx.B				   SNES_DMA5CNTL-$4300 ; Set transfer size
	lda.B				   #$20	  ; Trigger DMA channel 5
	sta.W				   SNES_MDMAEN ; Execute transfer

; Check if tilemap update needed
	lda.B				   #$80	  ; Check bit 7
	and.W				   $00d6	 ; Test display flags
	beq					 Graphics_TransferFieldTilemap_Skip ; If clear, skip tilemap transfer

; Transfer tilemap data
	ldx.W				   #$5820	; VRAM address $5820
	stx.W				   SNES_VMADDL ; Set VRAM write address
	ldx.W				   #$1801	; DMA mode: word write
	stx.B				   SNES_DMA5PARAM-$4300 ; Set DMA5 parameters
	ldx.W				   #$2040	; Source: $7e2040
	stx.B				   SNES_DMA5ADDRL-$4300 ; Set source address
	lda.B				   #$7e	  ; Bank $7e (WRAM)
	sta.B				   SNES_DMA5ADDRH-$4300 ; Set source bank
	ldx.W				   #$0fc0	; Transfer size: $0fc0 bytes (4032 bytes)
	stx.B				   SNES_DMA5CNTL-$4300 ; Set transfer size
	lda.B				   #$20	  ; Trigger DMA channel 5
	sta.W				   SNES_MDMAEN ; Execute transfer
	rtl							   ; Return

Graphics_TransferFieldTilemap_Skip:
	jsr.W				   CodeAnalysis ; Transfer OAM data

; Check if additional display update needed
	lda.B				   #$20	  ; Check bit 5
	and.W				   $00d6	 ; Test display flags
	beq					 Graphics_TransferFieldMode_Exit ; If clear, exit
	lda.B				   #$78	  ; Set multiple flags (bits 3,4,5,6)
	tsb.W				   $00d4	 ; Set bits in status register

Graphics_TransferFieldMode_Exit:
	rtl							   ; Return

; ===========================================================================
; Main Game Loop - Frame Update
; ===========================================================================
; Purpose: Main game logic executed every frame
; Technical Details: Increments frame counter, processes game state
; ===========================================================================

GameLoop_FrameUpdate:
	rep					 #$30		; 16-bit A, X, Y
	lda.W				   #$0000	; Zero accumulator
	tcd							   ; Transfer to direct page (DP = $0000)

; Increment frame counter (24-bit value)
	inc.W				   $0e97	 ; Increment low word
	bne					 Skip_High_Increment ; If no overflow, skip high word
	inc.W				   $0e99	 ; Increment high word (24-bit counter)

Skip_High_Increment:
	jsr.W				   GameLoop_ProcessTimeEvents ; Process time-based events

; Check if full screen refresh needed
	lda.W				   #$0004	; Check bit 2
	and.W				   $00d4	 ; Test display flags
	beq					 Normal_Frame_Update ; If clear, do normal update

; Full screen refresh (mode change)
	lda.W				   #$0004	; Bit 2
	trb.W				   $00d4	 ; Clear bit in flags

; Redraw layer 1
	lda.W				   #$0000	; Layer 1 index
	jsr.W				   RedrawLayerRoutine ; Redraw layer routine
	jsr.W				   InitializeSystem ; Additional layer 1 processing

; Redraw layer 2
	lda.W				   #$0001	; Layer 2 index
	jsr.W				   RedrawLayerRoutine ; Redraw layer routine
	jsr.W				   ExternalRoutine ; Additional layer 2 processing
	bra					 Frame_Update_Done ; Skip normal update

Normal_Frame_Update:
	jsr.W				   Store_008BFD ; Normal frame processing

; Check if input processing allowed
	lda.W				   #$0010	; Check bit 4
	and.W				   $00da	 ; Test input flags
	bne					 Process_Input ; If set, process input

; Check alternate input enable flag
	lda.W				   #$0004	; Check bit 2
	and.W				   $00e2	 ; Test alternate flags
	bne					 Frame_Update_Done ; If set, skip input

Process_Input:
; Process controller input
	lda.B				   $07	   ; Get joypad state
	and.B				   $8e	   ; Mask with enabled buttons
	beq					 Frame_Update_Done ; If no buttons pressed, done

; Execute input handler
	jsl.L				   CodeReturnsHandlerIndexBasedGame ; Get input handler function
	sep					 #$30		; 8-bit A, X, Y
	asl					 a; Multiply by 2 (word pointer)
	tax							   ; Transfer to X
	jsr.W				   (CallInputHandlerViaTable,x) ; Call input handler via table

Frame_Update_Done:
	rep					 #$30		; 16-bit A, X, Y
	jsr.W				   UpdateSpriteAnimations ; Update sprites
	jsr.W				   UpdateGameStateLogic ; Update animations
	rtl							   ; Return to caller

; ===========================================================================
; Time-Based Event Processor
; ===========================================================================
; Purpose: Process events that occur at specific time intervals
; Technical Details: Checks status flags for various timed events
; ===========================================================================

GameLoop_ProcessTimeEvents:
	phd							   ; Preserve direct page

; Check if character status animation active
	lda.W				   #$0080	; Check bit 7
	and.W				   $00de	 ; Test animation flags
	beq					 Time_Events_Done ; If clear, no status animation

; Process character status animation
	lda.W				   #$0c00	; Direct page = $0c00
	tcd							   ; Set DP to character data area

	sep					 #$30		; 8-bit A, X, Y

; Decrement animation timer
	dec.W				   $010d	 ; Decrement timer
	bpl					 Time_Events_Done ; If still positive, done

; Timer expired, reset and check character slots
	lda.B				   #$0c	  ; Reset timer to 12 frames
	sta.W				   $010d	 ; Store timer

; Check character slot 1 (Reuben/Kaeli)
	lda.L				   $700027   ; Check character 1 in party
	bne					 Check_Slot_2 ; If present, skip animation
	ldx.B				   #$40	  ; Animation offset for slot 1
	jsr.W				   StatusIcon_AnimateCharacter ; Animate status icon

Check_Slot_2:
; Check character slot 2 (Phoebe)
	lda.L				   $700077   ; Check character 2 in party
	bne					 Check_Slot_3 ; If present, skip animation
	ldx.B				   #$50	  ; Animation offset for slot 2
	jsr.W				   StatusIcon_AnimateCharacter ; Animate status icon

Check_Slot_3:
; Check character slot 3 (Tristam)
	lda.L				   $7003b3   ; Check character 3 in party
	bne					 Check_Slot_4 ; If present, skip animation
	ldx.B				   #$60	  ; Animation offset for slot 3
	jsr.W				   StatusIcon_AnimateCharacter ; Animate status icon

Check_Slot_4:
; Check character slot 4 (Enemy/Guest)
	lda.L				   $700403   ; Check character 4 in party
	bne					 Time_Events_Done ; If present, skip animation
	ldx.B				   #$70	  ; Animation offset for slot 4
	jsr.W				   StatusIcon_AnimateCharacter ; Animate status icon

Time_Events_Done:
	pld							   ; Restore direct page
	rts							   ; Return

; ===========================================================================
; Character Status Icon Animation
; ===========================================================================
; Purpose: Animate status icons for inactive/KO'd characters
; Input: X = OAM offset for character slot
; ===========================================================================

StatusIcon_AnimateCharacter:
; TODO: Document status icon animation logic
; Cycles through animation frames for defeated/inactive characters
RTS_Label:

; ===========================================================================
; Input Handler Jump Table
; ===========================================================================

InputHandler_JumpTable:
; TODO: Document input handler addresses
; Table of function pointers for different game modes
	dw											 Input_Handler_Field
	dw											 Input_Handler_Battle
	dw											 Input_Handler_Menu
; ... more handlers

; ===========================================================================
; VBlank Main Handler
; ===========================================================================
; Purpose: Main VBlank routine that processes display updates
; Technical Details: Called every frame during VBlank period
; Side Effects: Updates VRAM, OAM, palettes based on flags
; ===========================================================================

VBlank_Main_Handler:
	sep					 #$20		; 8-bit A
	rep					 #$10		; 16-bit X, Y

; Check if text window updates needed
	lda.B				   #$20	  ; Check bit 5
	and.W				   $00d4	 ; Test display flags
	beq					 Skip_Window_Update ; If clear, skip window update

; Update text window tiles
	lda.B				   #$20	  ; Bit 5
	trb.W				   $00d4	 ; Clear bit in flags

; Setup source/dest for MVN block move
	ldx.W				   #$54f4	; Source address (bank will be set)
	ldy.W				   #$54f6	; Destination address
	rep					 #$30		; 16-bit A, X, Y

; Check game mode for window type
	lda.W				   #$0080	; Check bit 7
	and.W				   $0ec6	 ; Test game mode flags
	bne					 Alternate_Window ; If set, use alternate window

; Standard text window
	lda.W				   #$0024	; Tile value $24 (window border?)
	sta.L				   $7f54f4   ; Store to WRAM buffer
	lda.W				   #$000b	; Move $000b bytes
	mvn					 $7f,$7f	 ; Block move within bank $7f
	lda.W				   #$0026	; Tile value $26 (different border)
	sta.W				   $5500	 ; Store to WRAM
	lda.W				   #$0009	; Move $0009 bytes
	mvn					 $7f,$7f	 ; Block move
	bra					 Window_Updated ; Done

Alternate_Window:
; Alternate text window (battle/menu?)
	lda.W				   #$0020	; Tile value $20
	sta.L				   $7f54f4   ; Store to WRAM buffer
	lda.W				   #$0015	; Move $0015 bytes (21 bytes)
	mvn					 $7f,$7f	 ; Block move

Window_Updated:
	sep					 #$20		; 8-bit A

Skip_Window_Update:
	phk							   ; Push program bank
	plb							   ; Pull to data bank (set DB = PB)

; Apply HDMA channel enable settings
	lda.W				   $0111	 ; Get HDMA channel mask
	sta.W				   SNES_HDMAEN ; Write to HDMA enable register

	rtl							   ; Return from VBlank handler

;===============================================================================
; Progress: ~1,200 lines documented (8.6% of Bank $00)
; Remaining: ~12,800 lines
;===============================================================================
