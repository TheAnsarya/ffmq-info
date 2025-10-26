; ==============================================================================
; Final Fantasy Mystic Quest - Bank $00 - Main Game Engine
; ==============================================================================
; This bank contains the core game engine including:
; - Boot sequence and initialization
; - Main game loop
; - Graphics setup and DMA
; - Controller input handling
; - Screen transitions
; - Save game management
;
; Size: 14,017 lines of disassembly
; Progress: Converting and commenting systematically
; ==============================================================================

arch 65816
lorom

;===============================================================================
; BOOT SEQUENCE & INITIALIZATION ($008000-$0082FF)
;===============================================================================

org $008000

Boot_Entry_Point:
	; ===========================================================================
	; SNES Power-On Boot Sequence
	; ===========================================================================
	; This is the first code executed when the SNES powers on or resets.
	; The RESET vector at $00FFFC points here.
	; 
	; Purpose:
	;   - Switch CPU from 6502 emulation mode to native 65816 mode
	;   - Initialize all hardware registers
	;   - Set up RAM and stack
	;   - Start game initialization
	;
	; Technical Details:
	;   The SNES boots in 6502 emulation mode for backward compatibility.
	;   CLC + XCE switches to native mode, enabling 16-bit registers and
	;   extended addressing modes.
	;
	; Registers After:
	;   CPU in native 65816 mode
	;   All other registers uninitialized (set by Init_Hardware)
	; ===========================================================================
	
	CLC                         ; Clear carry flag (required for mode switch)
	XCE                         ; Exchange carry with emulation flag
								; Carry=0 → Emulation flag=0 → Native mode!
	
	JSR.W Init_Hardware         ; Initialize all SNES hardware registers
	JSL.L Bank0D_Init           ; Initialize subsystems in bank $0D
	
	; ---------------------------------------------------------------------------
	; Initialize Save Game State Flags
	; ---------------------------------------------------------------------------
	; These flags track whether save data exists and what state it's in
	; $7E3667 = Save file exists flag
	; $7E3668 = Save file state/slot number
	; ---------------------------------------------------------------------------
	
	LDA.B #$00                  ; A = 0
	STA.L $7E3667               ; Clear "save file exists" flag
	DEC A                       ; A = $FF (-1)
	STA.L $7E3668               ; Set save state to -1 (no save)
	BRA Setup_Stack_And_Memory  ; Continue to main initialization

;-------------------------------------------------------------------------------

Boot_Secondary_Entry:
	; ===========================================================================
	; Secondary Boot Entry Point  
	; ===========================================================================
	; Alternative entry point, possibly used for:
	;   - Soft reset
	;   - Return from diagnostic mode
	;   - Return from special state
	; ===========================================================================
	
	JSR.W Init_Hardware         ; Re-initialize hardware
	
	LDA.B #$F0                  ; A = $F0
	STA.L $000600               ; Write to low RAM (hardware mirror area)
								; This might trigger some hardware behavior
	
	JSL.L Bank0D_Init_Variant   ; Different initialization routine

;-------------------------------------------------------------------------------

Setup_Stack_And_Memory:
	; ===========================================================================
	; Stack Pointer and Memory Setup
	; ===========================================================================
	; Sets up the CPU stack and prepares memory for game execution
	;
	; Stack Location:
	;   $001FFF (top of bank $00 RAM, grows downward)
	;   SNES typically uses $0000-$1FFF as general purpose RAM
	; ===========================================================================
	
	REP #$30                    ; 16-bit A, X, Y registers
	LDX.W #$1FFF                ; X = $1FFF
	TXS                         ; Stack pointer = $1FFF (top of RAM)
	
	JSR.W Init_Graphics_Registers ; Initialize PPU and graphics registers
	
	; ---------------------------------------------------------------------------
	; Check for Special Button Combination
	; ---------------------------------------------------------------------------
	; Checks if a specific button is held during boot
	; Might enable debug mode, skip intro, etc.
	; ---------------------------------------------------------------------------
	
	LDA.W #$0040                ; A = $0040 (bit 6 = some button?)
	AND.W $00DA                 ; Mask with controller input
	BNE Skip_Normal_Init        ; If button held, skip to alternate path
	
	; Normal initialization path
	JSL.L BankOC_Init           ; Initialize bank $0C systems
	BRA Continue_Init           ; Continue setup

;-------------------------------------------------------------------------------

Boot_Tertiary_Entry:
	; ===========================================================================
	; Tertiary Boot Entry Point
	; ===========================================================================
	; Yet another entry point - FFMQ has multiple boot paths
	; ===========================================================================
	
	JSR.W Init_Hardware         ; Hardware init (again)
	
	LDA.B #$F0
	STA.L $000600               ; Hardware mirror write
	
	JSL.L Bank0D_Init_Variant   ; Subsystem init
	
	REP #$30                    ; 16-bit mode
	LDX.W #$1FFF                ; Reset stack pointer
	TXS

;-------------------------------------------------------------------------------

Continue_Init:
	; ===========================================================================
	; DMA Transfer for Initial Register Setup
	; ===========================================================================
	; Uses DMA channel 0 to quickly initialize multiple hardware registers
	; This is faster than writing to each register individually
	;
	; DMA Configuration:
	;   Source: $008252 (data table in ROM)
	;   Dest: Hardware registers
	;   Size: $0000 (means $10000 = 64KB! But table is smaller)
	; ===========================================================================
	
	JSR.W Init_Graphics_Registers ; More graphics setup
	
	SEP #$20                    ; 8-bit A, 16-bit X/Y
	
	; Configure DMA Channel 0
	LDX.W #$1809                ; DMA parameters
								; $18 = DMA control byte
								; $09 = Target register (probably $2109?)
	STX.W !SNES_DMA0PARAM       ; $4300-4301: DMA control + target
	
	LDX.W #$8252                ; Source address = $008252
	STX.W !SNES_DMA0ADDRL       ; $4302-4303: Source address low/mid
	
	LDA.B #$00                  ; Source bank = $00
	STA.W !SNES_DMA0ADDRH       ; $4304: Source address bank
	
	LDX.W #$0000                ; Size = $0000 (wraps to $10000 = 64KB)
	STX.W !SNES_DMA0CNTL        ; $4305-4306: Transfer size
	
	LDA.B #$01                  ; Enable DMA channel 0
	STA.W !SNES_MDMAEN          ; $420B: Start DMA transfer NOW

;-------------------------------------------------------------------------------

Skip_Normal_Init:
	; ===========================================================================
	; Post-Initialization Setup
	; ===========================================================================
	; Called after hardware is initialized, regardless of boot path
	; ===========================================================================
	
	JSL.L $00011F               ; Call early routine (what is this?)
	
	REP #$30                    ; 16-bit A, X, Y
	LDA.W #$0000
	TCD                         ; Direct page = $0000 (default)
	
	SEP #$20                    ; 8-bit A
	
	; ---------------------------------------------------------------------------
	; Enable Interrupts (NMI/IRQ)
	; ---------------------------------------------------------------------------
	; NMI (Non-Maskable Interrupt) = VBlank interrupt
	; Fires every frame at vertical blanking
	; Used for graphics updates, timing, etc.
	; ---------------------------------------------------------------------------
	
	LDA.W $0112                 ; Load NMI enable flags
	STA.W !SNES_NMITIMEN        ; $4200: Enable NMI and/or IRQ
	CLI                         ; Clear interrupt disable flag
								; Interrupts now active!
	
	; ---------------------------------------------------------------------------
	; Set Screen Brightness
	; ---------------------------------------------------------------------------
	
	LDA.B #$0F                  ; Full brightness (0-15 scale)
	STA.W $00AA                 ; Store to brightness variable
	
	; Call initialization twice (fade in/out? Double buffer?)
	JSL.L BankOC_Init
	JSL.L BankOC_Init
	
	; ---------------------------------------------------------------------------
	; Check Save Game Status
	; ---------------------------------------------------------------------------
	; Determines whether to load a save or start new game
	; ---------------------------------------------------------------------------
	
	LDA.L $7E3665               ; Load save state flag
	BNE Handle_Existing_Save    ; If non-zero, handle existing save
	
	; ---------------------------------------------------------------------------
	; Check SRAM for Save Data
	; ---------------------------------------------------------------------------
	; SRAM (battery-backed RAM) at $70:0000-$7F:FFFF stores save games
	; Check specific bytes to see if valid save data exists
	; ---------------------------------------------------------------------------
	
	LDA.L $700000               ; SRAM byte 1 (save header?)
	ORA.L $70038C               ; OR with SRAM byte 2
	ORA.L $700718               ; OR with SRAM byte 3
	BEQ Start_New_Game          ; If all zero, no save exists
	
	; Save data exists - load it
	JSL.L Load_Save_Game        ; Load game from SRAM
	BRA Continue_To_Game

;-------------------------------------------------------------------------------

Handle_Existing_Save:
	; ===========================================================================
	; Handle Existing Save State
	; ===========================================================================
	; Called when save state flag indicates save in progress
	; ===========================================================================
	
	JSR.W Some_Save_Handler
	BRA Enter_Main_Loop

;-------------------------------------------------------------------------------

Start_New_Game:
	; ===========================================================================
	; New Game Initialization
	; ===========================================================================
	; Called when no save data exists - starts a fresh game
	; ===========================================================================
	
	JSR.W Init_New_Game

;-------------------------------------------------------------------------------

Continue_To_Game:
	; ===========================================================================
	; Final Setup Before Game Loop
	; ===========================================================================
	; Last minute preparations before entering main game loop
	; ===========================================================================
	
	LDA.B #$80                  ; Bit 7
	TRB.W $00DE                 ; Test and reset bit 7 in game flag
	
	LDA.B #$E0                  ; Bits 5-7
	TRB.W $0111                 ; Test and reset bits 5-7
	
	JSL.L BankOC_Init           ; Another initialization call
	
	; ---------------------------------------------------------------------------
	; Configure Color Math (SNES Special Effects)
	; ---------------------------------------------------------------------------
	; Color math allows adding/subtracting colors for transparency, fades, etc.
	; ---------------------------------------------------------------------------
	
	LDA.B #$E0                  ; Color math: subtract mode?
	STA.W !SNES_COLDATA         ; $2132: Color math configuration
	
	; Reset windowing and color effects
	LDX.W #$0000
	STX.W !SNES_CGSWSEL         ; $2130: Window mask settings
	
	; ---------------------------------------------------------------------------
	; Reset Background Scroll Positions
	; ---------------------------------------------------------------------------
	
	STZ.W !SNES_BG1VOFS         ; $210E: BG1 vertical scroll = 0
	STZ.W !SNES_BG1VOFS         ; Write twice (SNES registers need H+L bytes)
	
	STZ.W !SNES_BG2VOFS         ; $2110: BG2 vertical scroll = 0
	STZ.W !SNES_BG2VOFS
	
	JSR.W Some_Graphics_Setup
	JSL.L BankOC_Init

;-------------------------------------------------------------------------------

Enter_Main_Loop:
	; ===========================================================================
	; MAIN GAME LOOP ENTRY
	; ===========================================================================
	; This is where the actual game begins!
	; From here, execution enters the main game loop
	; ===========================================================================
	
	JSR.W Main_Game_Loop
	
	LDA.B #$00
	JSR.W Some_Mode_Handler
	
	LDA.B #$01
	JSR.W Some_Mode_Handler
	
	LDX.W #$81ED                ; Pointer to some data
	JSR.W Execute_Script_Or_Command
	
	LDA.B #$04
	TSB.W $00D4                 ; Test and set bit 2 in game flag
	
	LDA.B #$80
	TRB.W $00D6                 ; Test and reset bit 7 in flag
	
	STZ.W $0110                 ; Clear some variable
	
	LDA.B #$01
	TSB.W $00E2                 ; Test and set bit 0
	
	LDA.B #$10
	TSB.W $00D6                 ; Test and set bit 4
	
	LDX.W #$FFF0                ; Some value
	STX.W $008E                 ; Store to variable
	
	JSL.L Some_System_Call
	JSR.W Some_Function
	JML.L Jump_To_Bank01        ; Jump to bank $01 code!

;===============================================================================
; HELPER ROUTINES
;===============================================================================

Init_New_Game:
	; ===========================================================================
	; Initialize New Game State
	; ===========================================================================
	; Sets up initial game state for a brand new game:
	; - Character stats
	; - Starting location
	; - Inventory
	; - Flags and variables
	; ===========================================================================
	
	LDA.B #$14                  ; Enable BG1, BG3, BG4?
	STA.W !SNES_TM              ; $212C: Main screen designation
	
	REP #$30                    ; 16-bit mode
	LDA.W #$0000
	STA.L $7E31B5               ; Clear some game variable
	
	JSR.W Some_Init_Routine
	
	SEP #$20                    ; 8-bit A
	JSL.L BankOC_Init
	
	; ---------------------------------------------------------------------------
	; DMA Transfer to OAM (Sprite Attribute Memory)
	; ---------------------------------------------------------------------------
	; OAM holds sprite positions, tiles, and attributes
	; ---------------------------------------------------------------------------
	
	LDX.W #$0000
	STX.W !SNES_OAMADDL         ; $2102: OAM address = 0
	
	; Configure DMA Channel 5 for OAM
	LDX.W #$0400                ; DMA params for OAM
	STX.W !SNES_DMA5PARAM       ; $4350-4351
	
	LDX.W #$0C00                ; Source = $000C00
	STX.W !SNES_DMA5ADDRL       ; $4352-4353
	
	LDA.B #$00                  ; Source bank = $00
	STA.W !SNES_DMA5ADDRH       ; $4354
	
	LDX.W #$0220                ; Transfer size = $0220 = 544 bytes
	STX.W !SNES_DMA5CNTL        ; $4355-4356
	
	LDA.B #$20                  ; Enable DMA channel 5 (bit 5)
	STA.W !SNES_MDMAEN          ; $420B: Start DMA
	
	; ---------------------------------------------------------------------------
	; More Initialization
	; ---------------------------------------------------------------------------
	
	REP #$30                    ; 16-bit mode
	LDA.W #$FFFF
	STA.W $010E                 ; Initialize some variable to -1
	
	JSL.L Some_Init_Function_1
	JSR.W Some_Init_Function_2
	JSL.L Some_Init_Function_3
	
	SEP #$20                    ; 8-bit A
	RTS

;-------------------------------------------------------------------------------

Some_Save_Handler:
	; ===========================================================================
	; Handle Save Game Loading/Management
	; ===========================================================================
	; TODO: Analyze what this actually does
	; ===========================================================================
	
	REP #$30                    ; 16-bit mode
	
	; MVN = Block move negative (copy memory blocks)
	LDX.W #$A9C2                ; Source
	LDY.W #$1010                ; Destination
	LDA.W #$003F                ; Length-1
	MVN $00,$0C                 ; Copy from bank $00 to bank $0C
	
	LDY.W #$0E9E                ; Another destination
	LDA.W #$0009                ; Length-1
	MVN $00,$0C                 ; Another block copy
	
	SEP #$20                    ; 8-bit A
	
	LDA.B #$02
	STA.W $0FE7                 ; Store some value
	
	LDA.L $7E3668               ; Load save state
	CMP.B #$02
	BCC .less_than_2
	LDA.B #$FF                  ; Cap at $FF if >= 2
	
.less_than_2:
	INC A                       ; Increment save state
	STA.L $7E3668               ; Store back
	
	REP #$30                    ; 16-bit mode
	AND.W #$0003                ; Mask to 0-3
	ASL A                       ; Multiply by 8
	ASL A
	ASL A
	TAX                         ; X = offset into table
	
	SEP #$20                    ; 8-bit A
	STZ.B $19                   ; Clear some variable
	
	; Load data from table based on save state
	LDA.W Save_State_Table,X
	STA.W $0E88
	
	LDY.W Save_State_Table+1,X
	STY.W $0E89
	
	LDA.W Save_State_Table+3,X
	STA.W $0E92
	
	LDY.W Save_State_Table+6,X
	STY.B $53
	
	LDY.W Save_State_Table+4,X
	TYX
	
	REP #$30                    ; 16-bit mode
	LDY.W #$0EA8
	LDA.W #$001F
	MVN $00,$0C                 ; Block copy
	
	LDX.W #$0E92
	STX.B $17
	
	JSR.W Some_Function_A236
	
	SEP #$20                    ; 8-bit A
	JSL.L Some_Function_9319
	RTS

;-------------------------------------------------------------------------------
; Save State Data Table
;-------------------------------------------------------------------------------

Save_State_Table:
	db $2D                      ; Entry 0
	dw $1F26
	db $05
	dw $AA0C
	dw $A82E
	
	db $19, $0E, $1A            ; Entry 1
	db $02
	dw $AA0C
	dw $A8C1
	
	db $14, $33, $28            ; Entry 2
	db $05
	dw $AA2C
	dw $A96A
	
	db $EC, $A6, $03            ; Entry 3 (partial data visible)

;===============================================================================
; HARDWARE/MEMORY INITIALIZATION
;===============================================================================

Init_Graphics_Registers:
	; ===========================================================================
	; Initialize Graphics/PPU Registers
	; ===========================================================================
	; Sets up initial values for SNES PPU (Picture Processing Unit)
	; ===========================================================================
	
	LDA.W #$0000
	TCD                         ; Direct page = $0000
	
	STZ.B $00                   ; Clear first byte of RAM
	
	; ---------------------------------------------------------------------------
	; Clear RAM ($0000-$05FD = 1,534 bytes)
	; ---------------------------------------------------------------------------
	; Uses MVN (block move) to quickly zero memory
	; ---------------------------------------------------------------------------
	
	LDX.W #$0000                ; Source = $0000
	LDY.W #$0002                ; Dest = $0002
	LDA.W #$05FD                ; Length = $05FD bytes
	MVN $00,$00                 ; Copy within bank $00
								; This copies $00 forward, clearing memory!
	
	; ---------------------------------------------------------------------------
	; Clear More RAM ($0800-$1FF8 = 6,136 bytes)
	; ---------------------------------------------------------------------------
	
	STZ.W $0800                 ; Clear byte at $0800
	
	LDX.W #$0800                ; Source = $0800
	LDY.W #$0802                ; Dest = $0802
	LDA.W #$17F8                ; Length = $17F8 = 6,136 bytes
	MVN $00,$00                 ; Clear this block too
	
	; ---------------------------------------------------------------------------
	; Initialize Magic Number (Save Data Validation?)
	; ---------------------------------------------------------------------------
	
	LDA.W #$3369                ; Magic number = $3369
	STA.L $7E3367               ; Store to WRAM
								; Probably used to detect valid save data
	
	; ---------------------------------------------------------------------------
	; Execute Initialization Script Based on Save State
	; ---------------------------------------------------------------------------
	
	LDX.W #$822A                ; Default script pointer
	
	LDA.L $7E3667               ; Load save exists flag
	AND.W #$00FF                ; Mask to byte
	BEQ .no_save
	
	LDX.W #$822D                ; Different script if save exists
	
.no_save:
	JMP.W Execute_Script_Or_Command

;-------------------------------------------------------------------------------
; Initialization Script Pointers
;-------------------------------------------------------------------------------

	db $2D, $A6, $03            ; Script data (TODO: decode format)
	db $2B, $A6, $03

;===============================================================================
; MORE INITIALIZATION FUNCTIONS
;===============================================================================

Some_Function:
	; ===========================================================================
	; TODO: Analyze and document this function
	; ===========================================================================
	
	REP #$30                    ; 16-bit mode
	
	; Set data bank to $7E (WRAM)
	PEA.W $007E
	PLB
	
	LDA.W #$0170
	LDY.W #$3007
	JSR.W Some_Function_9A08
	
	LDA.W #$0098
	STA.W $31B5                 ; Store to WRAM variable
	
	PLB                         ; Restore data bank
	RTS

;-------------------------------------------------------------------------------

Init_Hardware:
	; ===========================================================================
	; Initialize SNES Hardware Registers
	; ===========================================================================
	; Sets hardware to known safe state:
	; - Disable interrupts
	; - Force blank screen
	; - Reset registers
	; ===========================================================================
	
	SEP #$30                    ; 8-bit A, X, Y
	
	STZ.W !SNES_NMITIMEN        ; $4200: Disable NMI and IRQ
	
	LDA.B #$80                  ; Force blank + full brightness
	STA.W !SNES_INIDISP         ; $2100: Screen display control
								; Bit 7 = force blank (screen off)
	RTS

;-------------------------------------------------------------------------------
; DMA Source Data (Register Init Values)
;-------------------------------------------------------------------------------

org $008252
DMA_Init_Data:
	db $00                      ; First byte
	db $DB, $80, $FD            ; More init values
	db $DB, $80, $FD
	db $DB, $80, $FD
	; More data continues...

;===============================================================================
; TODO: Continue converting and documenting rest of bank $00
;===============================================================================
; Remaining ~13,600 lines to analyze and comment!
;
; ===========================================================================
; DMA OAM Transfer Routines
; ===========================================================================
; Purpose: Transfer sprite (OAM) data from RAM to PPU via DMA
; Technical Details: Uses DMA channel 5 to upload sprite positions and attributes
; ===========================================================================

CODE_008543:
	; Setup DMA Channel 5 for OAM transfer
	LDX.W #$0400                     ; DMA mode: A→B, fixed source, word-length
	STX.B SNES_DMA5PARAM-$4300       ; Store to DMA5 control register
	LDX.W #$0C00                     ; Source address: $000C00 in RAM
	STX.B SNES_DMA5ADDRL-$4300       ; Set DMA5 source address (low/mid bytes)
	LDA.B #$00                       ; Bank $00
	STA.B SNES_DMA5ADDRH-$4300       ; Set DMA5 source bank
	
	; Transfer main OAM data (512 bytes)
	LDX.W $01F0                      ; Get OAM data size from variable
	STX.B SNES_DMA5CNTL-$4300        ; Set DMA5 transfer size
	LDX.W #$0000                     ; Start at OAM address $0000
	STX.W SNES_OAMADDL               ; Set OAM write address
	LDA.B #$20                       ; Trigger DMA channel 5
	STA.W SNES_MDMAEN                ; Execute DMA transfer
	
	; Transfer high table OAM data (32 bytes)
	LDX.W #$0E00                     ; Source address: $000E00 in RAM
	STX.B SNES_DMA5ADDRL-$4300       ; Update DMA5 source address
	LDX.W $01F2                      ; Get high table size from variable
	STX.B SNES_DMA5CNTL-$4300        ; Set DMA5 transfer size
	LDX.W #$0100                     ; High table starts at OAM $0100
	STX.W SNES_OAMADDL               ; Set OAM write address
	LDA.B #$20                       ; Trigger DMA channel 5
	STA.W SNES_MDMAEN                ; Execute DMA transfer
	RTS
; Next sections to tackle:
; - Main game loop
; - Controller input
; - Graphics updates
; - Battle system calls
; - Menu system
; - Save/load
; - Screen transitions
; ==============================================================================

; ===========================================================================
; Graphics Transfer - Battle Mode
; ===========================================================================
; Purpose: Upload battle graphics to VRAM during battle transitions
; Technical Details: Transfers character tiles and tilemap data
; Registers Used: A, X, Y
; ===========================================================================

CODE_008577:
	; Setup VRAM address for character data
	LDX.W #$4400                     ; VRAM address $4400
	STX.W SNES_VMADDL                ; Set VRAM write address
	
	; Configure DMA for 2-byte sequential write (VMDATAL/VMDATAH)
	LDX.W #$1801                     ; DMA mode: word write, increment source
	STX.B SNES_DMA5PARAM-$4300       ; Set DMA5 parameters
	
	; Transfer character graphics from $7F0480
	LDX.W #$0480                     ; Source: $7F0480
	STX.B SNES_DMA5ADDRL-$4300       ; Set source address (low/mid)
	LDA.B #$7F                       ; Bank $7F (WRAM)
	STA.B SNES_DMA5ADDRH-$4300       ; Set source bank
	LDX.W #$0280                     ; Transfer size: $0280 bytes (640 bytes)
	STX.B SNES_DMA5CNTL-$4300        ; Set transfer size
	LDA.B #$20                       ; Trigger DMA channel 5
	STA.W SNES_MDMAEN                ; Execute transfer
	
	; Transfer tilemap data to VRAM $5820
	LDX.W #$5820                     ; VRAM address $5820
	STX.W SNES_VMADDL                ; Set VRAM write address
	LDX.W #$2040                     ; Source: $7E2040
	STX.B SNES_DMA5ADDRL-$4300       ; Set source address
	LDA.B #$7E                       ; Bank $7E (WRAM)
	STA.B SNES_DMA5ADDRH-$4300       ; Set source bank
	LDX.W #$0B00                     ; Transfer size: $0B00 bytes (2816 bytes)
	STX.B SNES_DMA5CNTL-$4300        ; Set transfer size
	LDA.B #$20                       ; Trigger DMA channel 5
	STA.W SNES_MDMAEN                ; Execute transfer
	
	; Set flag indicating graphics updated
	LDA.B #$40                       ; Bit 6 flag
	TSB.W $00D2                      ; Set bit in status flags
	JSR.W CODE_008543                ; Transfer OAM data
	RTL                              ; Return from long call

; ===========================================================================
; Graphics Update - Field Mode
; ===========================================================================
; Purpose: Update field/map graphics during gameplay
; Technical Details: Conditional updates based on game state flags
; Side Effects: Updates VRAM, modifies status flags
; ===========================================================================

CODE_0085B7:
	; Setup VRAM for vertical increment mode
	LDA.B #$80                       ; Increment after writing to $2119
	STA.W SNES_VMAINC                ; Set VRAM increment mode
	
	; Check if battle mode graphics needed
	LDA.B #$10                       ; Check bit 4 of display flags
	AND.W $00DA                      ; Test against display status
	BNE CODE_008577                  ; If set, do battle graphics transfer
	
	; Field mode graphics update
	LDX.W $0042                      ; Get current VRAM address from variable
	STX.W SNES_VMADDL                ; Set VRAM write address
	
	; Setup DMA for character tile transfer
	LDX.W #$1801                     ; DMA mode: word write, increment
	STX.B SNES_DMA5PARAM-$4300       ; Set DMA5 parameters
	LDX.W #$0040                     ; Source: $7F0040
	STX.B SNES_DMA5ADDRL-$4300       ; Set source address
	LDA.B #$7F                       ; Bank $7F (WRAM)
	STA.B SNES_DMA5ADDRH-$4300       ; Set source bank
	LDX.W #$07C0                     ; Transfer size: $07C0 bytes (1984 bytes)
	STX.B SNES_DMA5CNTL-$4300        ; Set transfer size
	LDA.B #$20                       ; Trigger DMA channel 5
	STA.W SNES_MDMAEN                ; Execute transfer
	
	REP #$30                         ; 16-bit A, X, Y
	CLC                              ; Clear carry for addition
	LDA.W $0042                      ; Get VRAM address
	ADC.W #$1000                     ; Add $1000 for next section
	STA.W SNES_VMADDL                ; Set new VRAM address
	SEP #$20                         ; 8-bit A
	
	; Transfer second section of tiles
	LDX.W #$1801                     ; DMA mode: word write
	STX.B SNES_DMA5PARAM-$4300       ; Set DMA5 parameters
	LDX.W #$1040                     ; Source: $7F1040
	STX.B SNES_DMA5ADDRL-$4300       ; Set source address
	LDA.B #$7F                       ; Bank $7F (WRAM)
	STA.B SNES_DMA5ADDRH-$4300       ; Set source bank
	LDX.W #$07C0                     ; Transfer size: $07C0 bytes
	STX.B SNES_DMA5CNTL-$4300        ; Set transfer size
	LDA.B #$20                       ; Trigger DMA channel 5
	STA.W SNES_MDMAEN                ; Execute transfer
	
	; Check if tilemap update needed
	LDA.B #$80                       ; Check bit 7
	AND.W $00D6                      ; Test display flags
	BEQ CODE_00862D                  ; If clear, skip tilemap transfer
	
	; Transfer tilemap data
	LDX.W #$5820                     ; VRAM address $5820
	STX.W SNES_VMADDL                ; Set VRAM write address
	LDX.W #$1801                     ; DMA mode: word write
	STX.B SNES_DMA5PARAM-$4300       ; Set DMA5 parameters
	LDX.W #$2040                     ; Source: $7E2040
	STX.B SNES_DMA5ADDRL-$4300       ; Set source address
	LDA.B #$7E                       ; Bank $7E (WRAM)
	STA.B SNES_DMA5ADDRH-$4300       ; Set source bank
	LDX.W #$0FC0                     ; Transfer size: $0FC0 bytes (4032 bytes)
	STX.B SNES_DMA5CNTL-$4300        ; Set transfer size
	LDA.B #$20                       ; Trigger DMA channel 5
	STA.W SNES_MDMAEN                ; Execute transfer
	RTL                              ; Return

CODE_00862D:
	JSR.W CODE_008543                ; Transfer OAM data
	
	; Check if additional display update needed
	LDA.B #$20                       ; Check bit 5
	AND.W $00D6                      ; Test display flags
	BEQ CODE_00863C                  ; If clear, exit
	LDA.B #$78                       ; Set multiple flags (bits 3,4,5,6)
	TSB.W $00D4                      ; Set bits in status register
	
CODE_00863C:
	RTL                              ; Return

; ===========================================================================
; Main Game Loop - Frame Update
; ===========================================================================
; Purpose: Main game logic executed every frame
; Technical Details: Increments frame counter, processes game state
; ===========================================================================

CODE_008966:
	REP #$30                         ; 16-bit A, X, Y
	LDA.W #$0000                     ; Zero accumulator
	TCD                              ; Transfer to direct page (DP = $0000)
	
	; Increment frame counter (24-bit value)
	INC.W $0E97                      ; Increment low word
	BNE Skip_High_Increment          ; If no overflow, skip high word
	INC.W $0E99                      ; Increment high word (24-bit counter)

Skip_High_Increment:
	JSR.W CODE_0089C6                ; Process time-based events
	
	; Check if full screen refresh needed
	LDA.W #$0004                     ; Check bit 2
	AND.W $00D4                      ; Test display flags
	BEQ Normal_Frame_Update          ; If clear, do normal update
	
	; Full screen refresh (mode change)
	LDA.W #$0004                     ; Bit 2
	TRB.W $00D4                      ; Clear bit in flags
	
	; Redraw layer 1
	LDA.W #$0000                     ; Layer 1 index
	JSR.W CODE_0091D4                ; Redraw layer routine
	JSR.W CODE_008C3D                ; Additional layer 1 processing
	
	; Redraw layer 2
	LDA.W #$0001                     ; Layer 2 index
	JSR.W CODE_0091D4                ; Redraw layer routine
	JSR.W CODE_008D29                ; Additional layer 2 processing
	BRA Frame_Update_Done            ; Skip normal update

Normal_Frame_Update:
	JSR.W CODE_008BFD                ; Normal frame processing
	
	; Check if input processing allowed
	LDA.W #$0010                     ; Check bit 4
	AND.W $00DA                      ; Test input flags
	BNE Process_Input                ; If set, process input
	
	; Check alternate input enable flag
	LDA.W #$0004                     ; Check bit 2
	AND.W $00E2                      ; Test alternate flags
	BNE Frame_Update_Done            ; If set, skip input

Process_Input:
	; Process controller input
	LDA.B $07                        ; Get joypad state
	AND.B $8E                        ; Mask with enabled buttons
	BEQ Frame_Update_Done            ; If no buttons pressed, done
	
	; Execute input handler
	JSL.L CODE_009730                ; Get input handler function
	SEP #$30                         ; 8-bit A, X, Y
	ASL A                            ; Multiply by 2 (word pointer)
	TAX                              ; Transfer to X
	JSR.W (CODE_008A35,X)            ; Call input handler via table

Frame_Update_Done:
	REP #$30                         ; 16-bit A, X, Y
	JSR.W CODE_009342                ; Update sprites
	JSR.W CODE_009264                ; Update animations
	RTL                              ; Return to caller

; ===========================================================================
; Time-Based Event Processor
; ===========================================================================
; Purpose: Process events that occur at specific time intervals
; Technical Details: Checks status flags for various timed events
; ===========================================================================

CODE_0089C6:
	PHD                              ; Preserve direct page
	
	; Check if character status animation active
	LDA.W #$0080                     ; Check bit 7
	AND.W $00DE                      ; Test animation flags
	BEQ Time_Events_Done             ; If clear, no status animation
	
	; Process character status animation
	LDA.W #$0C00                     ; Direct page = $0C00
	TCD                              ; Set DP to character data area
	
	SEP #$30                         ; 8-bit A, X, Y
	
	; Decrement animation timer
	DEC.W $010D                      ; Decrement timer
	BPL Time_Events_Done             ; If still positive, done
	
	; Timer expired, reset and check character slots
	LDA.B #$0C                       ; Reset timer to 12 frames
	STA.W $010D                      ; Store timer
	
	; Check character slot 1 (Reuben/Kaeli)
	LDA.L $700027                    ; Check character 1 in party
	BNE Check_Slot_2                 ; If present, skip animation
	LDX.B #$40                       ; Animation offset for slot 1
	JSR.W CODE_008A2A                ; Animate status icon

Check_Slot_2:
	; Check character slot 2 (Phoebe)
	LDA.L $700077                    ; Check character 2 in party
	BNE Check_Slot_3                 ; If present, skip animation
	LDX.B #$50                       ; Animation offset for slot 2
	JSR.W CODE_008A2A                ; Animate status icon

Check_Slot_3:
	; Check character slot 3 (Tristam)
	LDA.L $7003B3                    ; Check character 3 in party
	BNE Check_Slot_4                 ; If present, skip animation
	LDX.B #$60                       ; Animation offset for slot 3
	JSR.W CODE_008A2A                ; Animate status icon

Check_Slot_4:
	; Check character slot 4 (Enemy/Guest)
	LDA.L $700403                    ; Check character 4 in party
	BNE Time_Events_Done             ; If present, skip animation
	LDX.B #$70                       ; Animation offset for slot 4
	JSR.W CODE_008A2A                ; Animate status icon

Time_Events_Done:
	PLD                              ; Restore direct page
	RTS                              ; Return

; ===========================================================================
; Character Status Icon Animation
; ===========================================================================
; Purpose: Animate status icons for inactive/KO'd characters
; Input: X = OAM offset for character slot
; ===========================================================================

CODE_008A2A:
	; TODO: Document status icon animation logic
	; Cycles through animation frames for defeated/inactive characters
	RTS

; ===========================================================================
; Input Handler Jump Table
; ===========================================================================

CODE_008A35:
	; TODO: Document input handler addresses
	; Table of function pointers for different game modes
	dw Input_Handler_Field
	dw Input_Handler_Battle
	dw Input_Handler_Menu
	; ... more handlers

; ===========================================================================
; VBlank Main Handler
; ===========================================================================
; Purpose: Main VBlank routine that processes display updates
; Technical Details: Called every frame during VBlank period
; Side Effects: Updates VRAM, OAM, palettes based on flags
; ===========================================================================

VBlank_Main_Handler:
	SEP #$20                         ; 8-bit A
	REP #$10                         ; 16-bit X, Y
	
	; Check if text window updates needed
	LDA.B #$20                       ; Check bit 5
	AND.W $00D4                      ; Test display flags
	BEQ Skip_Window_Update           ; If clear, skip window update
	
	; Update text window tiles
	LDA.B #$20                       ; Bit 5
	TRB.W $00D4                      ; Clear bit in flags
	
	; Setup source/dest for MVN block move
	LDX.W #$54F4                     ; Source address (bank will be set)
	LDY.W #$54F6                     ; Destination address
	REP #$30                         ; 16-bit A, X, Y
	
	; Check game mode for window type
	LDA.W #$0080                     ; Check bit 7
	AND.W $0EC6                      ; Test game mode flags
	BNE Alternate_Window             ; If set, use alternate window
	
	; Standard text window
	LDA.W #$0024                     ; Tile value $24 (window border?)
	STA.L $7F54F4                    ; Store to WRAM buffer
	LDA.W #$000B                     ; Move $000B bytes
	MVN $7F,$7F                      ; Block move within bank $7F
	LDA.W #$0026                     ; Tile value $26 (different border)
	STA.W $5500                      ; Store to WRAM
	LDA.W #$0009                     ; Move $0009 bytes
	MVN $7F,$7F                      ; Block move
	BRA Window_Updated               ; Done

Alternate_Window:
	; Alternate text window (battle/menu?)
	LDA.W #$0020                     ; Tile value $20
	STA.L $7F54F4                    ; Store to WRAM buffer
	LDA.W #$0015                     ; Move $0015 bytes (21 bytes)
	MVN $7F,$7F                      ; Block move
	
Window_Updated:
	SEP #$20                         ; 8-bit A

Skip_Window_Update:
	PHK                              ; Push program bank
	PLB                              ; Pull to data bank (set DB = PB)
	
	; Apply HDMA channel enable settings
	LDA.W $0111                      ; Get HDMA channel mask
	STA.W SNES_HDMAEN                ; Write to HDMA enable register
	
	RTL                              ; Return from VBlank handler

;===============================================================================
; Progress: ~1,200 lines documented (8.6% of Bank $00)
; Remaining: ~12,800 lines
;===============================================================================
; ===========================================================================
; Character Status Animation (continued from earlier sections)
; ===========================================================================

CODE_008A0B:
	; Check character slot 5
	LDA.L $70073F                    ; Check character 5 in party data
	BNE CODE_008A16                  ; If present, skip animation
	LDX.B #$80                       ; Animation offset for slot 5
	JSR.W CODE_008A2A                ; Animate status icon

CODE_008A16:
	; Check character slot 6
	LDA.L $70078F                    ; Check character 6 in party data
	BNE CODE_008A21                  ; If present, skip animation
	LDX.B #$90                       ; Animation offset for slot 6
	JSR.W CODE_008A2A                ; Animate status icon

CODE_008A21:
	; Set update flag and return
	LDA.B #$20                       ; Bit 5 flag
	TSB.W $00D2                      ; Set bit in display flags

CODE_008A26:
	REP #$30                         ; 16-bit A, X, Y
	PLD                              ; Restore direct page
	RTS                              ; Return

; ===========================================================================
; Animate Status Icon
; ===========================================================================
; Purpose: Toggle character status icon animation frame
; Input: X = OAM data offset for character slot
; Technical Details: Toggles tile numbers to create animation effect
; ===========================================================================

CODE_008A2A:
	; Toggle tile animation frame
	LDA.B $02,X                      ; Get current tile number
	EOR.B #$04                       ; Toggle bit 2 (animation frame)
	STA.B $02,X                      ; Store back to OAM
	
	; Update adjacent sprite tiles
	INC A                            ; Next tile
	STA.W $0C06,X                    ; Store to OAM +4
	INC A                            ; Next tile
	STA.W $0C0A,X                    ; Store to OAM +8
	INC A                            ; Next tile
	STA.W $0C0E,X                    ; Store to OAM +12
	RTS                              ; Return

; ===========================================================================
; Input Handler Jump Table
; ===========================================================================
; Purpose: Dispatch table for different input contexts
; Format: Table of 16-bit addresses for input handler functions
; ===========================================================================

Input_Handler_Table:
	dw Input_Down                    ; $008A3D: Down button handler
	dw Input_Up                      ; $008A3F: Up button handler
	dw Input_Action                  ; $008A41: A/B button handler
	dw Input_Action                  ; $008A43: (duplicate)
	dw Input_Left                    ; $008A45: Left button handler
	dw Input_Right                   ; $008A47: Right button handler
	dw Input_Right                   ; $008A49: (alternate)
	dw Input_Left                    ; $008A4B: (alternate)
	dw Input_Action                  ; $008A4D: (action variant)
	dw Input_Action                  ; $008A4F: (action variant)
	dw Input_Switch_Character        ; $008A51: Character switch
	dw Input_Action                  ; $008A53: (action variant)

; ===========================================================================
; Menu Cursor Movement - Vertical
; ===========================================================================

Input_Left:
	DEC.B $02                        ; Move cursor left
	BRA Validate_Cursor_Position     ; Check bounds

Input_Right:
	INC.B $02                        ; Move cursor right
	BRA Validate_Cursor_Position     ; Check bounds

Input_Up:
	DEC.B $01                        ; Move cursor up
	BRA Validate_Cursor_Position     ; Check bounds

Input_Down:
	INC.B $01                        ; Move cursor down
	; Fall through to validation

; ===========================================================================
; Validate Cursor Position
; ===========================================================================
; Purpose: Ensure cursor stays within menu bounds, handle wrapping
; Technical Details: Checks against bounds in $03/$04, handles wrap flags
; ===========================================================================

Validate_Cursor_Position:
	; Check vertical bounds
	LDA.B $01                        ; Get cursor Y position
	BMI Cursor_Above_Top             ; If negative, handle wrap
	CMP.B $03                        ; Compare to max Y
	BCC Cursor_Horizontal_Check      ; If within bounds, check horizontal
	
	; Cursor below bottom
	LDA.B $95                        ; Get wrap flags
	AND.B #$01                       ; Check vertical wrap down flag
	BNE Cursor_Above_Top             ; If set, wrap to top
	
Clamp_Cursor_Bottom:
	LDA.B $03                        ; Get max Y
	DEC A                            ; Subtract 1
	STA.B $01                        ; Clamp cursor to bottom
	BRA Cursor_Horizontal_Check      ; Check horizontal

Cursor_Above_Top:
	; Cursor above top
	LDA.B $95                        ; Get wrap flags
	AND.B #$02                       ; Check vertical wrap up flag
	BNE Clamp_Cursor_Bottom          ; If set, wrap to bottom
	STZ.B $01                        ; Clamp cursor to top

Cursor_Horizontal_Check:
	; Check horizontal bounds
	LDA.B $02                        ; Get cursor X position
	BMI Cursor_Left_Of_Min           ; If negative, handle wrap
	CMP.B $04                        ; Compare to max X
	BCC Cursor_Valid                 ; If within bounds, done
	
	; Cursor right of maximum
	LDA.B $95                        ; Get wrap flags
	AND.B #$04                       ; Check horizontal wrap right flag
	BNE Cursor_Left_Of_Min           ; If set, wrap to left

Clamp_Cursor_Right:
	LDA.B $04                        ; Get max X
	DEC A                            ; Subtract 1
	STA.B $02                        ; Clamp cursor to right
	RTS                              ; Done

Cursor_Left_Of_Min:
	; Cursor left of minimum
	LDA.B $95                        ; Get wrap flags
	AND.B #$08                       ; Check horizontal wrap left flag
	BNE Clamp_Cursor_Right           ; If set, wrap to right
	STZ.B $02                        ; Clamp cursor to left

Cursor_Valid:
	RTS                              ; Return

; ===========================================================================
; Character Switch Input Handler
; ===========================================================================
; Purpose: Handle character switching in menu/field
; Technical Details: Toggles between Benjamin and Phoebe
; ===========================================================================

Input_Switch_Character:
	JSR.W CODE_008B57                ; Check if switching allowed
	BNE Switch_Done                  ; If not allowed, exit
	
	; Check if character is valid
	LDA.W $1090                      ; Get character status
	BMI Play_Error_Sound             ; If invalid, play error
	
	; Toggle character
	LDA.W $10A0                      ; Get character flags
	EOR.B #$80                       ; Toggle bit 7 (Benjamin/Phoebe)
	STA.W $10A0                      ; Store new character
	
	; Update display
	LDA.B #$40                       ; Set update flag
	TSB.W $00D4                      ; Set in display flags
	JSR.W CODE_00B908                ; Update character sprite
	BRA Switch_Done                  ; Done

Play_Error_Sound:
	JSR.W CODE_00B912                ; Play error sound

Switch_Done:
	RTS                              ; Return

; ===========================================================================
; Menu Action Validation
; ===========================================================================
; Purpose: Check if menu action at current position is valid
; Technical Details: Validates based on map position and character state
; ===========================================================================

CODE_008ABD:
	; Check if on valid action tile
	LDA.W $1032                      ; Get tile X position
	CMP.B #$80                       ; Compare to invalid marker
	BNE Action_Valid                 ; If not marker, action valid
	LDA.W $1033                      ; Get tile Y position
	BNE Action_Valid                 ; If not zero, action valid
	JMP.W CODE_00B912                ; Invalid: play error sound

Action_Valid:
	JMP.W CODE_00B908                ; Valid: play confirm sound

; ===========================================================================
; Menu Scroll - Down
; ===========================================================================
; Purpose: Scroll menu list downward
; Technical Details: Calculates next visible item, updates display
; ===========================================================================

Scroll_Menu_Down:
	JSR.W CODE_008B57                ; Check if scrolling allowed
	BNE Scroll_Down_Done             ; If blocked, exit
	JSR.W CODE_008ABD                ; Play appropriate sound
	
	; Calculate current row from pixel position
	LDA.W $1031                      ; Get Y pixel position
	SEC                              ; Set carry for subtraction
	SBC.B #$20                       ; Subtract top margin (32 pixels)
	LDX.B #$FF                       ; Initialize row counter to -1

Count_Rows_Down:
	INX                              ; Increment row counter
	SBC.B #$03                       ; Subtract row height (3 pixels)
	BCS Count_Rows_Down              ; If still positive, continue counting
	
	; TXA now contains current row number
	TXA                              ; Transfer row to A

Find_Next_Valid_Row:
	INC A                            ; Next row
	AND.B #$03                       ; Wrap to 0-3 range
	PHA                              ; Save row number
	JSR.W CODE_008DA8                ; Check if row has valid item
	PLA                              ; Restore row number
	CPY.B #$FF                       ; Check if item valid
	BEQ Find_Next_Valid_Row          ; If invalid, try next row
	
	; Update display with new row
	JSR.W CODE_008B21                ; Update menu display
	JSR.W CODE_008C3D                ; Update graphics

Scroll_Down_Done:
	RTS                              ; Return

; ===========================================================================
; Menu Scroll - Up
; ===========================================================================
; Purpose: Scroll menu list upward
; Technical Details: Similar to down scroll but decrements
; ===========================================================================

Scroll_Menu_Up:
	JSR.W CODE_008B57                ; Check if scrolling allowed
	BNE Scroll_Up_Done               ; If blocked, exit
	JSR.W CODE_008ABD                ; Play appropriate sound
	
	; Calculate current row
	LDA.W $1031                      ; Get Y pixel position
	SEC                              ; Set carry
	SBC.B #$20                       ; Subtract top margin
	LDX.B #$FF                       ; Initialize counter

Count_Rows_Up:
	INX                              ; Increment counter
	SBC.B #$03                       ; Subtract row height
	BCS Count_Rows_Up                ; Continue counting
	
	TXA                              ; Transfer row to A

Find_Previous_Valid_Row:
	DEC A                            ; Previous row
	AND.B #$03                       ; Wrap to 0-3 range
	PHA                              ; Save row number
	JSR.W CODE_008DA8                ; Check if row has valid item
	PLA                              ; Restore row number
	CPY.B #$FF                       ; Check if valid
	BEQ Find_Previous_Valid_Row      ; If invalid, try previous
	
	; Update display
	JSR.W CODE_008B21                ; Update menu display
	JSR.W CODE_008C3D                ; Update graphics

Scroll_Up_Done:
	RTS                              ; Return

; ===========================================================================
; Update Menu Display
; ===========================================================================
; Purpose: Update menu tilemap based on current selection
; Technical Details: Copies appropriate tile data to WRAM buffer
; ===========================================================================

CODE_008B21:
	REP #$30                         ; 16-bit A, X, Y
	
	; Determine source tilemap based on Y position
	LDX.W #$3709                     ; Default source (rows 0-2)
	CPY.W #$0023                     ; Check if Y < $23
	BCC Copy_Menu_Tiles              ; If yes, use default
	
	LDX.W #$3719                     ; Source for rows 3-5
	CPY.W #$0026                     ; Check if Y < $26
	BCC Copy_Menu_Tiles              ; If yes, use this source
	
	LDX.W #$3729                     ; Source for rows 6-8
	CPY.W #$0029                     ; Check if Y < $29
	BCC Copy_Menu_Tiles              ; If yes, use this source
	
	LDX.W #$3739                     ; Source for rows 9+

Copy_Menu_Tiles:
	LDY.W #$3669                     ; Destination in WRAM
	LDA.W #$000F                     ; Copy 16 bytes
	MVN $7E,$7E                      ; Block move within bank $7E
	
	; Restore state and redraw layer
	PHK                              ; Push program bank
	PLB                              ; Pull to data bank
	LDA.W #$0000                     ; Layer 0
	JSR.W CODE_0091D4                ; Redraw layer
	
	SEP #$30                         ; 8-bit A, X, Y
	LDA.B #$80                       ; Set update flag
	TSB.W $00D9                      ; Set in status flags
	RTS                              ; Return

; ===========================================================================
; Check Input Blocking Flags
; ===========================================================================
; Purpose: Determine if input should be blocked
; Output: Z flag set if input blocked
; ===========================================================================

CODE_008B57:
	LDA.B #$10                       ; Check bit 4
	AND.W $00D6                      ; Test blocking flags
	BEQ Input_Not_Blocked            ; If clear, input allowed
	
	; Input is blocked, clear certain button flags
	REP #$30                         ; 16-bit A, X, Y
	LDA.B $92                        ; Get current joypad state
	AND.W #$BFCF                     ; Clear bits 4,5,14 (A,B,X buttons?)
	SEP #$30                         ; 8-bit A, X, Y

Input_Not_Blocked:
	RTS                              ; Return (Z flag indicates status)

; ===========================================================================
; Tile Position to VRAM Address Calculation
; ===========================================================================
; Purpose: Convert tile coordinates to VRAM address
; Input: A = tile position (3 bits Y, 3 bits X in bits 0-5)
; Output: A = VRAM address
; ===========================================================================

CODE_008C1B:
	PHP                              ; Preserve processor status
	REP #$30                         ; 16-bit A, X, Y
	AND.W #$00FF                     ; Clear high byte
	PHA                              ; Save original value
	
	; Extract Y coordinate (bits 3-5)
	AND.W #$0038                     ; Mask to get bits 3-5 (Y * 8)
	ASL A                            ; Multiply by 2 (Y * 16)
	TAX                              ; Save Y offset in X
	
	; Extract X coordinate (bits 0-2)
	PLA                              ; Restore original value
	AND.W #$0007                     ; Mask to get bits 0-2 (X)
	PHX                              ; Save Y offset
	ADC.B $01,S                      ; Add Y offset
	STA.B $01,S                      ; Store back
	
	; Calculate final VRAM address
	ASL A                            ; Multiply by 2
	ADC.B $01,S                      ; Add previous result (x3)
	ASL A                            ; Multiply by 16 (shift left 4)
	ASL A
	ASL A
	ASL A
	ADC.W #$8000                     ; Add VRAM base address
	
	PLX                              ; Clean up stack
	PLP                              ; Restore processor status
	RTS                              ; Return

; ===========================================================================
; Update Character Tile on Map
; ===========================================================================
; Purpose: Update character sprite tile in dual buffer mode
; Technical Details: Updates both WRAM buffers for seamless display
; ===========================================================================

CODE_008C3D:
	PHP                              ; Preserve processor status
	SEP #$30                         ; 8-bit A, X, Y
	
	LDX.W $1031                      ; Get character map position
	CPX.B #$FF                       ; Check if valid position
	BEQ Update_Done                  ; If invalid, exit
	
	; Check if dual buffer mode active (battle/transition)
	LDA.B #$02                       ; Check bit 1
	AND.W $00D8                      ; Test display mode flags
	BEQ Single_Buffer_Update         ; If clear, single buffer only
	
	; Dual buffer mode - update both WRAM buffers
	LDA.L DATA8_049800,X             ; Get character tile number
	ADC.B #$0A                       ; Add offset for animation frame
	XBA                              ; Swap to high byte
	
	; Calculate tilemap address
	TXA                              ; Position to A
	AND.B #$38                       ; Get Y coordinate (bits 3-5)
	ASL A                            ; Multiply by 2
	PHA                              ; Save
	TXA                              ; Position to A again
	AND.B #$07                       ; Get X coordinate (bits 0-2)
	ORA.B $01,S                      ; Combine with Y offset
	PLX                              ; Clean stack
	ASL A                            ; Multiply by 2
	REP #$30                         ; 16-bit mode
	
	; Store to both buffers
	STA.L $7F075A                    ; Buffer 1 - tile 1
	INC A
	STA.L $7F075C                    ; Buffer 1 - tile 2
	ADC.W #$000F                     ; Next row offset
	STA.L $7F079A                    ; Buffer 1 - tile 3
	INC A
	STA.L $7F079C                    ; Buffer 1 - tile 4
	
	SEP #$20                         ; 8-bit A
	LDX.W #$17DA                     ; Source data pointer
	LDA.B #$7F                       ; Bank $7F
	BRA Perform_DMA_Update           ; Do DMA transfer

Update_Done:
	PLP                              ; Restore status
	RTS                              ; Return

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
