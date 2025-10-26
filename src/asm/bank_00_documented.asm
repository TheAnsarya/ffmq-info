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
; Next sections to tackle:
; - Main game loop
; - Controller input
; - Graphics updates
; - Battle system calls
; - Menu system
; - Save/load
; - Screen transitions
; ==============================================================================

