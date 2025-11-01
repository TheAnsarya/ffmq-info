														; ===========================================================================
														; Graphics Transfer - Battle Mode
														; ===========================================================================
														; Purpose: Upload battle graphics to VRAM during battle transitions
														; Technical Details: Transfers character tiles and tilemap data
														; Registers Used: A, X, Y
														; ===========================================================================

CODE_008577:
														; Setup VRAM address for character data
					   LDX.W				   #$4400	; VRAM address $4400
					   STX.W				   SNES_VMADDL ; Set VRAM write address

														; Configure DMA for 2-byte sequential write (VMDATAL/VMDATAH)
					   LDX.W				   #$1801	; DMA mode: word write, increment source
					   STX.B				   SNES_DMA5PARAM-$4300 ; Set DMA5 parameters

														; Transfer character graphics from $7F0480
					   LDX.W				   #$0480	; Source: $7F0480
					   STX.B				   SNES_DMA5ADDRL-$4300 ; Set source address (low/mid)
					   LDA.B				   #$7F	  ; Bank $7F (WRAM)
					   STA.B				   SNES_DMA5ADDRH-$4300 ; Set source bank
					   LDX.W				   #$0280	; Transfer size: $0280 bytes (640 bytes)
					   STX.B				   SNES_DMA5CNTL-$4300 ; Set transfer size
					   LDA.B				   #$20	  ; Trigger DMA channel 5
					   STA.W				   SNES_MDMAEN ; Execute transfer

														; Transfer tilemap data to VRAM $5820
					   LDX.W				   #$5820	; VRAM address $5820
					   STX.W				   SNES_VMADDL ; Set VRAM write address
					   LDX.W				   #$2040	; Source: $7E2040
					   STX.B				   SNES_DMA5ADDRL-$4300 ; Set source address
					   LDA.B				   #$7E	  ; Bank $7E (WRAM)
					   STA.B				   SNES_DMA5ADDRH-$4300 ; Set source bank
					   LDX.W				   #$0B00	; Transfer size: $0B00 bytes (2816 bytes)
					   STX.B				   SNES_DMA5CNTL-$4300 ; Set transfer size
					   LDA.B				   #$20	  ; Trigger DMA channel 5
					   STA.W				   SNES_MDMAEN ; Execute transfer

														; Set flag indicating graphics updated
					   LDA.B				   #$40	  ; Bit 6 flag
					   TSB.W				   $00D2	 ; Set bit in status flags
					   JSR.W				   CODE_008543 ; Transfer OAM data
					   RTL							   ; Return from long call

														; ===========================================================================
														; Graphics Update - Field Mode
														; ===========================================================================
														; Purpose: Update field/map graphics during gameplay
														; Technical Details: Conditional updates based on game state flags
														; Side Effects: Updates VRAM, modifies status flags
														; ===========================================================================

CODE_0085B7:
														; Setup VRAM for vertical increment mode
					   LDA.B				   #$80	  ; Increment after writing to $2119
					   STA.W				   SNES_VMAINC ; Set VRAM increment mode

														; Check if battle mode graphics needed
					   LDA.B				   #$10	  ; Check bit 4 of display flags
					   AND.W				   $00DA	 ; Test against display status
					   BNE					 CODE_008577 ; If set, do battle graphics transfer

														; Field mode graphics update
					   LDX.W				   $0042	 ; Get current VRAM address from variable
					   STX.W				   SNES_VMADDL ; Set VRAM write address

														; Setup DMA for character tile transfer
					   LDX.W				   #$1801	; DMA mode: word write, increment
					   STX.B				   SNES_DMA5PARAM-$4300 ; Set DMA5 parameters
					   LDX.W				   #$0040	; Source: $7F0040
					   STX.B				   SNES_DMA5ADDRL-$4300 ; Set source address
					   LDA.B				   #$7F	  ; Bank $7F (WRAM)
					   STA.B				   SNES_DMA5ADDRH-$4300 ; Set source bank
					   LDX.W				   #$07C0	; Transfer size: $07C0 bytes (1984 bytes)
					   STX.B				   SNES_DMA5CNTL-$4300 ; Set transfer size
					   LDA.B				   #$20	  ; Trigger DMA channel 5
					   STA.W				   SNES_MDMAEN ; Execute transfer

					   REP					 #$30		; 16-bit A, X, Y
					   CLC							   ; Clear carry for addition
					   LDA.W				   $0042	 ; Get VRAM address
					   ADC.W				   #$1000	; Add $1000 for next section
					   STA.W				   SNES_VMADDL ; Set new VRAM address
					   SEP					 #$20		; 8-bit A

														; Transfer second section of tiles
					   LDX.W				   #$1801	; DMA mode: word write
					   STX.B				   SNES_DMA5PARAM-$4300 ; Set DMA5 parameters
					   LDX.W				   #$1040	; Source: $7F1040
					   STX.B				   SNES_DMA5ADDRL-$4300 ; Set source address
					   LDA.B				   #$7F	  ; Bank $7F (WRAM)
					   STA.B				   SNES_DMA5ADDRH-$4300 ; Set source bank
					   LDX.W				   #$07C0	; Transfer size: $07C0 bytes
					   STX.B				   SNES_DMA5CNTL-$4300 ; Set transfer size
					   LDA.B				   #$20	  ; Trigger DMA channel 5
					   STA.W				   SNES_MDMAEN ; Execute transfer

														; Check if tilemap update needed
					   LDA.B				   #$80	  ; Check bit 7
					   AND.W				   $00D6	 ; Test display flags
					   BEQ					 CODE_00862D ; If clear, skip tilemap transfer

														; Transfer tilemap data
					   LDX.W				   #$5820	; VRAM address $5820
					   STX.W				   SNES_VMADDL ; Set VRAM write address
					   LDX.W				   #$1801	; DMA mode: word write
					   STX.B				   SNES_DMA5PARAM-$4300 ; Set DMA5 parameters
					   LDX.W				   #$2040	; Source: $7E2040
					   STX.B				   SNES_DMA5ADDRL-$4300 ; Set source address
					   LDA.B				   #$7E	  ; Bank $7E (WRAM)
					   STA.B				   SNES_DMA5ADDRH-$4300 ; Set source bank
					   LDX.W				   #$0FC0	; Transfer size: $0FC0 bytes (4032 bytes)
					   STX.B				   SNES_DMA5CNTL-$4300 ; Set transfer size
					   LDA.B				   #$20	  ; Trigger DMA channel 5
					   STA.W				   SNES_MDMAEN ; Execute transfer
					   RTL							   ; Return

CODE_00862D:
					   JSR.W				   CODE_008543 ; Transfer OAM data

														; Check if additional display update needed
					   LDA.B				   #$20	  ; Check bit 5
					   AND.W				   $00D6	 ; Test display flags
					   BEQ					 CODE_00863C ; If clear, exit
					   LDA.B				   #$78	  ; Set multiple flags (bits 3,4,5,6)
					   TSB.W				   $00D4	 ; Set bits in status register

CODE_00863C:
					   RTL							   ; Return

														; ===========================================================================
														; Main Game Loop - Frame Update
														; ===========================================================================
														; Purpose: Main game logic executed every frame
														; Technical Details: Increments frame counter, processes game state
														; ===========================================================================

CODE_008966:
					   REP					 #$30		; 16-bit A, X, Y
					   LDA.W				   #$0000	; Zero accumulator
					   TCD							   ; Transfer to direct page (DP = $0000)

														; Increment frame counter (24-bit value)
					   INC.W				   $0E97	 ; Increment low word
					   BNE					 Skip_High_Increment ; If no overflow, skip high word
					   INC.W				   $0E99	 ; Increment high word (24-bit counter)

Skip_High_Increment:
					   JSR.W				   CODE_0089C6 ; Process time-based events

														; Check if full screen refresh needed
					   LDA.W				   #$0004	; Check bit 2
					   AND.W				   $00D4	 ; Test display flags
					   BEQ					 Normal_Frame_Update ; If clear, do normal update

														; Full screen refresh (mode change)
					   LDA.W				   #$0004	; Bit 2
					   TRB.W				   $00D4	 ; Clear bit in flags

														; Redraw layer 1
					   LDA.W				   #$0000	; Layer 1 index
					   JSR.W				   CODE_0091D4 ; Redraw layer routine
					   JSR.W				   CODE_008C3D ; Additional layer 1 processing

														; Redraw layer 2
					   LDA.W				   #$0001	; Layer 2 index
					   JSR.W				   CODE_0091D4 ; Redraw layer routine
					   JSR.W				   CODE_008D29 ; Additional layer 2 processing
					   BRA					 Frame_Update_Done ; Skip normal update

Normal_Frame_Update:
					   JSR.W				   CODE_008BFD ; Normal frame processing

														; Check if input processing allowed
					   LDA.W				   #$0010	; Check bit 4
					   AND.W				   $00DA	 ; Test input flags
					   BNE					 Process_Input ; If set, process input

														; Check alternate input enable flag
					   LDA.W				   #$0004	; Check bit 2
					   AND.W				   $00E2	 ; Test alternate flags
					   BNE					 Frame_Update_Done ; If set, skip input

Process_Input:
														; Process controller input
					   LDA.B				   $07	   ; Get joypad state
					   AND.B				   $8E	   ; Mask with enabled buttons
					   BEQ					 Frame_Update_Done ; If no buttons pressed, done

														; Execute input handler
					   JSL.L				   CODE_009730 ; Get input handler function
					   SEP					 #$30		; 8-bit A, X, Y
					   ASL					 A		   ; Multiply by 2 (word pointer)
					   TAX							   ; Transfer to X
					   JSR.W				   (CODE_008A35,X) ; Call input handler via table

Frame_Update_Done:
					   REP					 #$30		; 16-bit A, X, Y
					   JSR.W				   CODE_009342 ; Update sprites
					   JSR.W				   CODE_009264 ; Update animations
					   RTL							   ; Return to caller

														; ===========================================================================
														; Time-Based Event Processor
														; ===========================================================================
														; Purpose: Process events that occur at specific time intervals
														; Technical Details: Checks status flags for various timed events
														; ===========================================================================

CODE_0089C6:
					   PHD							   ; Preserve direct page

														; Check if character status animation active
					   LDA.W				   #$0080	; Check bit 7
					   AND.W				   $00DE	 ; Test animation flags
					   BEQ					 Time_Events_Done ; If clear, no status animation

														; Process character status animation
					   LDA.W				   #$0C00	; Direct page = $0C00
					   TCD							   ; Set DP to character data area

					   SEP					 #$30		; 8-bit A, X, Y

														; Decrement animation timer
					   DEC.W				   $010D	 ; Decrement timer
					   BPL					 Time_Events_Done ; If still positive, done

														; Timer expired, reset and check character slots
					   LDA.B				   #$0C	  ; Reset timer to 12 frames
					   STA.W				   $010D	 ; Store timer

														; Check character slot 1 (Reuben/Kaeli)
					   LDA.L				   $700027   ; Check character 1 in party
					   BNE					 Check_Slot_2 ; If present, skip animation
					   LDX.B				   #$40	  ; Animation offset for slot 1
					   JSR.W				   CODE_008A2A ; Animate status icon

Check_Slot_2:
														; Check character slot 2 (Phoebe)
					   LDA.L				   $700077   ; Check character 2 in party
					   BNE					 Check_Slot_3 ; If present, skip animation
					   LDX.B				   #$50	  ; Animation offset for slot 2
					   JSR.W				   CODE_008A2A ; Animate status icon

Check_Slot_3:
														; Check character slot 3 (Tristam)
					   LDA.L				   $7003B3   ; Check character 3 in party
					   BNE					 Check_Slot_4 ; If present, skip animation
					   LDX.B				   #$60	  ; Animation offset for slot 3
					   JSR.W				   CODE_008A2A ; Animate status icon

Check_Slot_4:
														; Check character slot 4 (Enemy/Guest)
					   LDA.L				   $700403   ; Check character 4 in party
					   BNE					 Time_Events_Done ; If present, skip animation
					   LDX.B				   #$70	  ; Animation offset for slot 4
					   JSR.W				   CODE_008A2A ; Animate status icon

Time_Events_Done:
					   PLD							   ; Restore direct page
					   RTS							   ; Return

														; ===========================================================================
														; Character Status Icon Animation
														; ===========================================================================
														; Purpose: Animate status icons for inactive/KO'd characters
														; Input: X = OAM offset for character slot
														; ===========================================================================

CODE_008A2A:
														; TODO: Document status icon animation logic
														; Cycles through animation frames for defeated/inactive characters
RTS:

														; ===========================================================================
														; Input Handler Jump Table
														; ===========================================================================

CODE_008A35:
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
					   SEP					 #$20		; 8-bit A
					   REP					 #$10		; 16-bit X, Y

														; Check if text window updates needed
					   LDA.B				   #$20	  ; Check bit 5
					   AND.W				   $00D4	 ; Test display flags
					   BEQ					 Skip_Window_Update ; If clear, skip window update

														; Update text window tiles
					   LDA.B				   #$20	  ; Bit 5
					   TRB.W				   $00D4	 ; Clear bit in flags

														; Setup source/dest for MVN block move
					   LDX.W				   #$54F4	; Source address (bank will be set)
					   LDY.W				   #$54F6	; Destination address
					   REP					 #$30		; 16-bit A, X, Y

														; Check game mode for window type
					   LDA.W				   #$0080	; Check bit 7
					   AND.W				   $0EC6	 ; Test game mode flags
					   BNE					 Alternate_Window ; If set, use alternate window

														; Standard text window
					   LDA.W				   #$0024	; Tile value $24 (window border?)
					   STA.L				   $7F54F4   ; Store to WRAM buffer
					   LDA.W				   #$000B	; Move $000B bytes
					   MVN					 $7F,$7F	 ; Block move within bank $7F
					   LDA.W				   #$0026	; Tile value $26 (different border)
					   STA.W				   $5500	 ; Store to WRAM
					   LDA.W				   #$0009	; Move $0009 bytes
					   MVN					 $7F,$7F	 ; Block move
					   BRA					 Window_Updated ; Done

Alternate_Window:
														; Alternate text window (battle/menu?)
					   LDA.W				   #$0020	; Tile value $20
					   STA.L				   $7F54F4   ; Store to WRAM buffer
					   LDA.W				   #$0015	; Move $0015 bytes (21 bytes)
					   MVN					 $7F,$7F	 ; Block move

Window_Updated:
					   SEP					 #$20		; 8-bit A

Skip_Window_Update:
					   PHK							   ; Push program bank
					   PLB							   ; Pull to data bank (set DB = PB)

														; Apply HDMA channel enable settings
					   LDA.W				   $0111	 ; Get HDMA channel mask
					   STA.W				   SNES_HDMAEN ; Write to HDMA enable register

					   RTL							   ; Return from VBlank handler

														;===============================================================================
														; Progress: ~1,200 lines documented (8.6% of Bank $00)
														; Remaining: ~12,800 lines
														;===============================================================================
