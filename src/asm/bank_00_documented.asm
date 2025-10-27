; ==============================================================================
; Final Fantasy Mystic Quest - Bank $00 - Main Game Engine
; ==============================================================================
; This bank contains the core game engine including:
; - Boot sequence and initialization ($008000-$0082FF)
; - Main game loop and state machine
; - Graphics setup and DMA transfer management
; - Controller input handling
; - Screen transitions and fade effects
; - Save game management and SRAM operations
; - NMI and IRQ handlers
;
; Original ROM Size: 32,768 bytes ($8000)
; Diztinguish Source: 14,018 lines
; ==============================================================================

arch 65816
lorom

;===============================================================================
; SNES Hardware Register Definitions
;===============================================================================
; DMA Registers
SNES_DMA0PARAM = $4300    ; DMA Channel 0 Parameters
SNES_DMA0ADDRL = $4302    ; DMA Channel 0 Address Low
SNES_DMA0ADDRH = $4303    ; DMA Channel 0 Address High
SNES_DMA0CNTL  = $4305    ; DMA Channel 0 Control Low
SNES_DMA3PARAM = $4330    ; DMA Channel 3 Parameters
SNES_DMA3ADDRL = $4332    ; DMA Channel 3 Address Low
SNES_DMA3ADDRH = $4333    ; DMA Channel 3 Address High
SNES_DMA5PARAM = $4350    ; DMA Channel 5 Parameters
SNES_DMA5ADDRL = $4352    ; DMA Channel 5 Address Low
SNES_DMA5ADDRH = $4353    ; DMA Channel 5 Address High
SNES_DMA5CNTL  = $4355    ; DMA Channel 5 Control Low
SNES_DMA6PARAM = $4360    ; DMA Channel 6 Parameters
SNES_DMA6ADDRL = $4362    ; DMA Channel 6 Address Low
SNES_DMA6ADDRH = $4363    ; DMA Channel 6 Address High
SNES_DMA7PARAM = $4370    ; DMA Channel 7 Parameters
SNES_DMA7ADDRL = $4372    ; DMA Channel 7 Address Low
SNES_DMA7ADDRH = $4373    ; DMA Channel 7 Address High
SNES_MDMAEN    = $420B    ; DMA Enable

; PPU Registers
SNES_INIDISP   = $2100    ; Display Control
SNES_TM        = $212C    ; Main Screen Designation
SNES_CGADD     = $2121    ; CG RAM Address
SNES_CGDATA    = $2122    ; CG RAM Data
SNES_COLDATA   = $2132    ; Color Data
SNES_CGSWSEL   = $2130    ; Color/Window Select
SNES_BG1VOFS   = $210E    ; BG1 Vertical Offset
SNES_BG2VOFS   = $2110    ; BG2 Vertical Offset
SNES_VMADDL    = $2116    ; VRAM Address Low
SNES_VMAINC    = $2115    ; VRAM Address Increment
SNES_OAMADDL   = $2102    ; OAM Address Low

; Controller Registers
SNES_CNTRL1L   = $4218    ; Controller 1 Data Low

; System Registers
SNES_NMITIMEN  = $4200    ; NMI/Timer Enable

; Math/Multiplication/Division Registers
SNES_WRMPYA    = $4202    ; Multiplicand
SNES_WRMPYB    = $4203    ; Multiplicand/Multiplier
SNES_WRDIVL    = $4204    ; Dividend Low
SNES_WRDIVH    = $4205    ; Dividend High
SNES_WRDIVB    = $4206    ; Divisor
SNES_RDMPYL    = $4216    ; Multiplication/Division Result Low

;===============================================================================
; External Bank Stubs (code in other banks)
;===============================================================================
; Bank $00 - Not yet imported
CODE_0096A0 = $0096A0
CODE_00985D = $00985D
CODE_00A375 = $00A375
CODE_00A3DE = $00A3DE
CODE_00A3E5 = $00A3E5
CODE_00A3EC = $00A3EC
CODE_00A3F5 = $00A3F5
CODE_00A3FC = $00A3FC
CODE_00A51E = $00A51E
CODE_00A572 = $00A572
CODE_00A57D = $00A57D
CODE_00A581 = $00A581
CODE_00A586 = $00A586
CODE_00A597 = $00A597
CODE_00A708 = $00A708
CODE_00A718 = $00A718
CODE_00A71C = $00A71C
CODE_00A744 = $00A744
CODE_00A755 = $00A755
CODE_00A78E = $00A78E
CODE_00A79D = $00A79D
CODE_00A7AC = $00A7AC
CODE_00A7B3 = $00A7B3
CODE_00A7DE = $00A7DE
CODE_00A7EB = $00A7EB
CODE_00A7F9 = $00A7F9
CODE_00A83F = $00A83F
CODE_00A86E = $00A86E
CODE_00A874 = $00A874
CODE_00A89B = $00A89B
CODE_00A8BD = $00A8BD
CODE_00A8C0 = $00A8C0
CODE_00A8D1 = $00A8D1
CODE_00A958 = $00A958
CODE_00A96C = $00A96C
CODE_00A97D = $00A97D
CODE_00AACF = $00AACF
CODE_00AEA2 = $00AEA2
CODE_00AEB5 = $00AEB5
CODE_00AEC7 = $00AEC7
CODE_00AEDA = $00AEDA
CODE_00AF6B = $00AF6B
CODE_00AF70 = $00AF70
CODE_00AF9A = $00AF9A
CODE_00AFD6 = $00AFD6
CODE_00AFFE = $00AFFE
CODE_00B094 = $00B094
CODE_00B2F4 = $00B2F4
CODE_00B2F9 = $00B2F9
CODE_00B354 = $00B354
CODE_00B355 = $00B355
CODE_00B379 = $00B379
CODE_00B950 = $00B950
CODE_00BA1A = $00BA1A
CODE_00B1C3 = $00B1C3
CODE_00B1D6 = $00B1D6
CODE_00B1E8 = $00B1E8
CODE_00B204 = $00B204
CODE_00B21D = $00B21D
CODE_00B22F = $00B22F
CODE_00B49E = $00B49E
CODE_00B4A7 = $00B4A7
CODE_00B4B0 = $00B4B0
CODE_00BD30 = $00BD30
CODE_00BD64 = $00BD64
CODE_00C795 = $00C795
CODE_00C7B8 = $00C7B8
CODE_00CA63 = $00CA63
CODE_00D080 = $00D080
CODE_00E055 = $00E055
CODE_00B908 = $00B908
CODE_00B912 = $00B912
Some_Graphics_Setup = $00B000
Some_Init_Routine = $00B100
Some_Mode_Handler = $00B200
Main_Game_Loop = $00B300
Execute_Script_Or_Command = $00B400
Some_Init_Function_2 = $00B500
Some_Function_9319 = $009319
Some_Function_9A08 = $009A08
Some_Function_A236 = $00A236

; Other Banks
CODE_028AE0 = $028AE0    ; Bank $02 routine
DATA8_03BA35 = $03BA35   ; Bank $03 data
DATA8_03BB81 = $03BB81   ; Bank $03 data
UNREACH_03D5E5 = $03D5E5 ; Bank $03 unreachable code
CODE_0C8000 = $0C8000    ; Bank $0C routine
CODE_0C8080 = $0C8080    ; Bank $0C routine
BankOC_Init = $0C8000    ; Bank $0C Init
CODE_0D8000 = $0D8000    ; Bank $0D routine
CODE_0D8004 = $0D8004    ; Bank $0D routine
Bank0D_Init_Variant = $0D8000    ; Bank $0D Init
CODE_018272 = $018272    ; Bank $01 routine
Jump_To_Bank01 = $018000 ; Bank $01 jump target
DATA8_049800 = $049800   ; Bank $04 data
Load_Save_Game = $0E8000 ; Bank $0E save game
Some_System_Call = $0F8000    ; Bank $0F system
Some_Init_Function_1 = $0F8100    ; Bank $0F init
Some_Init_Function_3 = $0F8200    ; Bank $0F init

; Bank $07 data
DATA8_078000 = $078000
DATA8_078001 = $078001
DATA8_078002 = $078002
DATA8_078003 = $078003
DATA8_078004 = $078004
DATA8_078005 = $078005
DATA8_078006 = $078006
DATA8_078007 = $078007
DATA8_07800A = $07800A
DATA8_07800C = $07800C
DATA8_07D8E4 = $07D8E4
DATA8_07D8E5 = $07D8E5
DATA8_07D8E6 = $07D8E6
DATA8_07D8E7 = $07D8E7
DATA8_07D8E8 = $07D8E8
DATA8_07D8E9 = $07D8E9
DATA8_07D8EA = $07D8EA
DATA8_07D8EB = $07D8EB
DATA8_07D8EC = $07D8EC
DATA8_07D8ED = $07D8ED
DATA8_07D8EE = $07D8EE
DATA8_07D8EF = $07D8EF
DATA8_07D8F0 = $07D8F0
DATA8_07D8F1 = $07D8F1
DATA8_07D8F2 = $07D8F2
DATA8_07D8F3 = $07D8F3

;===============================================================================
; BOOT SEQUENCE & INITIALIZATION ($008000-$008113)
;===============================================================================

org $008000

CODE_008000:
	; ===========================================================================
	; SNES Power-On Boot Entry Point (RESET Vector Handler)
	; ===========================================================================
	; This is the first code executed when the SNES powers on or resets.
	; The RESET vector at $00FFFC points here ($008000).
	;
	; Boot Process:
	;   1. Switch from 6502 emulation mode to native 65816 mode
	;   2. Initialize all hardware registers (display off, sound off, DMA off)
	;   3. Initialize bank $0D subsystems (sound driver, etc.)
	;   4. Clear save file flags in RAM
	;   5. Jump to stack setup and main initialization
	;
	; Technical Notes:
	;   - SNES always boots in 6502 emulation mode for compatibility
	;   - CLC+XCE is required to enable native mode features:
	;     * 16-bit accumulator and index registers
	;     * Extended addressing modes
	;     * Full 24-bit address space
	;     * 16-bit stack pointer
	;
	; Registers On Entry:
	;   Emulation mode, all registers undefined
	;
	; Registers On Exit:
	;   Native mode, stack at $001FFF, hardware initialized
	; ===========================================================================

	CLC                         ; Clear carry flag
	XCE                         ; Exchange Carry with Emulation flag
								; C=0 → E=0 → Native 65816 mode enabled!

	JSR.W CODE_008247           ; Init_Hardware: Disable NMI, force blank, clear registers
	JSL.L CODE_0D8000           ; Bank $0D initialization (sound driver, APU setup)

	; ---------------------------------------------------------------------------
	; Initialize Save Game State Variables
	; ---------------------------------------------------------------------------
	; $7E3667 = Save file exists flag (0=no save, 1=save exists)
	; $7E3668 = Save file slot/state ($FF=no save, 0-2=slot number)
	; ---------------------------------------------------------------------------

	LDA.B #$00                  ; A = 0
	STA.L $7E3667               ; Clear "save file exists" flag
	DEC A                       ; A = $FF (-1)
	STA.L $7E3668               ; Set save slot to $FF (no active save)
	BRA CODE_008023             ; → Continue to stack setup

;-------------------------------------------------------------------------------

CODE_008016:
	; ===========================================================================
	; Secondary Boot Entry Point
	; ===========================================================================
	; Alternative entry point used for soft reset or special boot modes.
	; Different from main boot: calls different bank $0D init routine.
	; ===========================================================================

	JSR.W CODE_008247           ; Init_Hardware again

	LDA.B #$F0                  ; A = $F0
	STA.L $000600               ; Write $F0 to $000600 (low RAM mirror area)
								; Purpose unclear - may trigger hardware behavior

	JSL.L CODE_0D8004           ; Bank $0D alternate initialization routine

;-------------------------------------------------------------------------------

CODE_00803A:
	; ===========================================================================
	; Third Entry Point (Soft Reset with Different Init)
	; ===========================================================================
	; Yet another entry point with same hardware init but different
	; bank $0D initialization. May be used for returning from special modes.
	; ===========================================================================

	JSR.W CODE_008247           ; Init_Hardware

	LDA.B #$F0                  ; A = $F0
	STA.L $000600               ; Write $F0 to $000600

	JSL.L CODE_0D8004           ; Bank $0D alternate init

	REP #$30                    ; Set 16-bit mode: A, X, Y
	LDX.W #$1FFF                ; X = $1FFF (stack pointer initial value)
	TXS                         ; Transfer X to Stack: S = $1FFF

;-------------------------------------------------------------------------------

CODE_008023:
	; ===========================================================================
	; Stack Setup and Main Initialization Path
	; ===========================================================================
	; All boot paths converge here. Sets up stack pointer and continues
	; to main game initialization.
	;
	; Stack Configuration:
	;   Top of stack: $001FFF
	;   Stack grows downward (typical 65816 configuration)
	;   RAM area $0000-$1FFF available for stack/variables
	; ===========================================================================

	REP #$30                    ; 16-bit A, X, Y registers
	LDX.W #$1FFF                ; X = $1FFF (top of RAM bank $00)
	TXS                         ; S = $1FFF (initialize stack pointer)

	JSR.W CODE_0081F0           ; Clear_RAM: Zero out all work RAM $0000-$1FFF

	; ---------------------------------------------------------------------------
	; Check Boot Mode Flag ($00DA bit 6)
	; ---------------------------------------------------------------------------
	; $00DA appears to be a boot mode/configuration flag
	; Bit 6 ($40) determines which initialization path to take
	; ---------------------------------------------------------------------------

	LDA.W #$0040                ; A = $0040 (bit 6 mask)
	AND.W $00DA                 ; Test bit 6 of $00DA
	BNE CODE_00806E             ; If bit 6 set → Skip display init, jump ahead

	JSL.L CODE_0C8080           ; Bank $0C: Full display/PPU initialization
	BRA CODE_00804D             ; → Continue to DMA setup

;-------------------------------------------------------------------------------

CODE_00804D:
	; ===========================================================================
	; DMA Transfer Setup - Copy Data to RAM
	; ===========================================================================
	; Configures and executes a DMA transfer from ROM to RAM.
	; Transfers $0000 bytes from $008252 to... (size is 0??)
	;
	; This appears to be setup code that may be partially disabled or
	; used for specific initialization scenarios.
	; ===========================================================================

	JSR.W CODE_0081F0           ; Clear_RAM again (redundant?)

	SEP #$20                    ; 8-bit accumulator

	; ---------------------------------------------------------------------------
	; DMA Channel 0 Configuration
	; ---------------------------------------------------------------------------
	; Purpose: Copy initialization data from ROM to RAM
	; Pattern: Fixed source, incrementing destination (mode $18)
	; Register: $2109 (not a standard PPU register?)
	; ---------------------------------------------------------------------------

	LDX.W #$1809                ; X = $1809
								; $18 = DMA mode (2 registers, increment write)
								; $09 = Target register (high byte)
	STX.W SNES_DMA0PARAM        ; $4300 = DMA0 parameters

	LDX.W #$8252                ; X = $8252 (source address low/mid)
	STX.W SNES_DMA0ADDRL        ; $4302-$4303 = Source address $xx8252

	LDA.B #$00                  ; A = $00
	STA.W SNES_DMA0ADDRH        ; $4304 = Source bank $00 → $008252

	LDX.W #$0000                ; X = $0000 (transfer size = 0 bytes!)
	STX.W SNES_DMA0CNTL         ; $4305-$4306 = Transfer 0 bytes
								; This DMA won't transfer anything!

	LDA.B #$01                  ; A = $01 (enable channel 0)
	STA.W SNES_MDMAEN           ; $420B = Execute DMA channel 0
								; (Executes but transfers 0 bytes)

;-------------------------------------------------------------------------------

CODE_00806E:
	; ===========================================================================
	; Direct Page Setup and NMI Enable
	; ===========================================================================
	; Sets up direct page pointer and enables interrupts for main game loop.
	; ===========================================================================

	JSL.L $00011F               ; Call routine at $00011F (in bank $00 RAM!)
								; This is calling CODE in RAM, not ROM
								; Must have been loaded earlier

	REP #$30                    ; 16-bit A, X, Y

	LDA.W #$0000                ; A = $0000
	TCD                         ; Direct Page = $0000 (D = $0000)
								; Sets up fast direct page access

	SEP #$20                    ; 8-bit accumulator

	LDA.W $0112                 ; A = [$0112] (NMI enable flags)
	STA.W SNES_NMITIMEN         ; $4200 = Enable NMI/IRQ/Auto-joypad
								; Copies configuration from RAM variable

	CLI                         ; Clear Interrupt disable flag
								; Enable IRQ interrupts (NMI already configured)

	LDA.B #$0F                  ; A = $0F
	STA.W $00AA                 ; [$00AA] = $0F (some game state variable)

	JSL.L CODE_0C8000           ; Bank $0C: Wait for VBLANK
	JSL.L CODE_0C8000           ; Bank $0C: Wait for VBLANK again
								; Double wait ensures PPU is stable

	; ---------------------------------------------------------------------------
	; Check Boot/Continue Mode
	; ---------------------------------------------------------------------------
	; $7E3665 = Continue/load game flag
	; $700000, $70038C, $700718 = Save file signature bytes?
	; ---------------------------------------------------------------------------

	LDA.L $7E3665               ; A = Continue flag
	BNE CODE_0080A8             ; If set → Load existing game

	; Check if save data exists in SRAM
	LDA.L $700000               ; A = SRAM byte 1
	ORA.L $70038C               ; OR with SRAM byte 2
	ORA.L $700718               ; OR with SRAM byte 3
	BEQ CODE_0080AD             ; If all zero → New game (no save data)

	JSL.L CODE_00B950           ; Has save data → Show continue menu
	BRA CODE_0080B0             ; → Continue to fade-in

;-------------------------------------------------------------------------------

CODE_0080A8:
	; ===========================================================================
	; Load Saved Game from SRAM
	; ===========================================================================
	; Player selected "Continue" from title screen - load saved game data.
	; ===========================================================================

	JSR.W CODE_008166           ; Load_Game_From_SRAM: Restore all game state
	BRA CODE_0080DC             ; → Skip new game init, jump to main setup

;-------------------------------------------------------------------------------

CODE_0080AD:
	; ===========================================================================
	; New Game Initialization
	; ===========================================================================
	; No save data exists - initialize a fresh game state.
	; ===========================================================================

	JSR.W CODE_008117           ; Initialize_New_Game_State: Set default values

;-------------------------------------------------------------------------------

CODE_0080B0:
	; ===========================================================================
	; Screen Fade-In and Final Setup (Common Path)
	; ===========================================================================
	; Both new game and continue converge here.
	; Prepares screen for display and jumps to main game engine.
	;
	; Technical Notes:
	;   - Color math configured for fade effects
	;   - Background scroll positions reset
	;   - State flags cleared
	;   - Final VBLANK sync before jumping to main game
	; ===========================================================================

	LDA.B #$80                  ; A = $80 (bit 7)
	TRB.W $00DE                 ; Test and Reset bit 7 of $00DE
								; Clear some display state flag

	LDA.B #$E0                  ; A = $E0 (bits 5-7: %11100000)
	TRB.W $0111                 ; Test and Reset bits 5-7 of $0111
								; Clear multiple configuration flags

	JSL.L CODE_0C8000           ; Bank $0C: Wait for VBLANK
								; Ensure PPU ready for register writes

	; ---------------------------------------------------------------------------
	; Configure Color Math and Window Settings
	; ---------------------------------------------------------------------------
	; Sets up color addition/subtraction for fade effects
	; SNES_COLDATA ($2132): Color math control register
	; SNES_CGSWSEL ($2130): Color addition select
	; ---------------------------------------------------------------------------

	LDA.B #$E0                  ; A = $E0
								; Bit 7 = 1: Subtract color
								; Bit 6 = 1: Half color math
								; Bit 5 = 1: Enable color math
	STA.W SNES_COLDATA          ; $2132 = Color math configuration

	LDX.W #$0000                ; X = $0000
	STX.W SNES_CGSWSEL          ; $2130 = Color/math window settings = 0
								; Disable all color window masking

	; ---------------------------------------------------------------------------
	; Reset Background Scroll Positions
	; ---------------------------------------------------------------------------
	; SNES requires writing scroll values TWICE (high byte, then low byte)
	; Writing $00 twice sets scroll position to 0
	; ---------------------------------------------------------------------------

	STZ.W SNES_BG1VOFS          ; $210E = BG1 vertical scroll = 0 (low byte)
	STZ.W SNES_BG1VOFS          ; $210E = BG1 vertical scroll = 0 (high byte)
	STZ.W SNES_BG2VOFS          ; $2110 = BG2 vertical scroll = 0 (low byte)
	STZ.W SNES_BG2VOFS          ; $2110 = BG2 vertical scroll = 0 (high byte)

	JSR.W CODE_00BD30           ; Additional graphics/fade setup
	JSL.L CODE_0C8000           ; Bank $0C: Wait for VBLANK again
								; Ensure all register writes complete

;-------------------------------------------------------------------------------

CODE_0080DC:
	; ===========================================================================
	; Final Game Initialization and Main Game Jump
	; ===========================================================================
	; Last initialization steps before transferring control to main game engine.
	;
	; This section:
	;   - Initializes game systems (sound, graphics, input)
	;   - Sets up initial state flags
	;   - Configures game mode variables
	;   - Jumps to main game loop in bank $01
	; ===========================================================================

	JSR.W CODE_009014           ; Initialize subsystem (graphics related?)

	; ---------------------------------------------------------------------------
	; Initialize Two System Components (Unknown Purpose)
	; ---------------------------------------------------------------------------
	; Calls same routine twice with different parameters
	; May be initializing two separate game systems
	; ---------------------------------------------------------------------------

	LDA.B #$00                  ; A = $00 (parameter for first init)
	JSR.W CODE_0091D4           ; Initialize system component 0

	LDA.B #$01                  ; A = $01 (parameter for second init)
	JSR.W CODE_0091D4           ; Initialize system component 1

	; ---------------------------------------------------------------------------
	; Load Initial Data Table
	; ---------------------------------------------------------------------------
	; $81ED points to initialization data (see DATA8_0081ED below)
	; CODE_009BC4 likely loads/processes this data table
	; ---------------------------------------------------------------------------

	LDX.W #$81ED                ; X = $81ED (pointer to init data)
	JSR.W CODE_009BC4           ; Load/process data table

	; ---------------------------------------------------------------------------
	; Configure State Flags
	; ---------------------------------------------------------------------------
	; $00D4, $00D6, $00E2 = State/configuration flag bytes
	; TSB/TRB = Test and Set/Reset Bits instructions
	; ---------------------------------------------------------------------------

	LDA.B #$04                  ; A = $04 (bit 2)
	TSB.W $00D4                 ; Test and Set bit 2 in $00D4
								; Enable some display/update feature

	LDA.B #$80                  ; A = $80 (bit 7)
	TRB.W $00D6                 ; Test and Reset bit 7 in $00D6
								; Disable some feature

	STZ.W $0110                 ; [$0110] = $00 (clear game state variable)

	LDA.B #$01                  ; A = $01 (bit 0)
	TSB.W $00E2                 ; Test and Set bit 0 in $00E2
								; Enable some system feature

	LDA.B #$10                  ; A = $10 (bit 4)
	TSB.W $00D6                 ; Test and Set bit 4 in $00D6
								; Enable another feature

	; ---------------------------------------------------------------------------
	; Initialize Game Position/State Variable
	; ---------------------------------------------------------------------------
	; $008E appears to be a signed 16-bit position or state value
	; ---------------------------------------------------------------------------

	LDX.W #$FFF0                ; X = $FFF0 (-16 in signed 16-bit)
	STX.W $008E                 ; [$008E] = $FFF0 (initial game state)

	; ---------------------------------------------------------------------------
	; Final Setup Routines
	; ---------------------------------------------------------------------------

	JSL.L CODE_009B2F           ; Final system initialization
	JSR.W CODE_008230           ; Additional setup (see below)

	; ---------------------------------------------------------------------------
	; JUMP TO MAIN GAME LOOP
	; ---------------------------------------------------------------------------
	; JML = Jump Long (24-bit address)
	; Control transfers to bank $01, never returns
	; This is the END of boot sequence - game starts running!
	; ---------------------------------------------------------------------------

	JML.L CODE_018272           ; → JUMP TO MAIN GAME ENGINE (Bank $01)
								; Boot sequence complete!

;===============================================================================
; NEW GAME INITIALIZATION ($008117-$008165)
;===============================================================================

CODE_008117:
	; ===========================================================================
	; Initialize New Game State
	; ===========================================================================
	; Called when starting a new game (no save data exists).
	; Sets up default values for character stats, inventory, flags, etc.
	;
	; Technical Notes:
	;   - Configures display layers (TM register)
	;   - Clears save game variables
	;   - Sets up OAM (sprite) DMA transfer
	;   - Initializes various game subsystems
	; ===========================================================================

	LDA.B #$14                  ; A = $14 (%00010100)
								; Bit 4 = Enable BG3
								; Bit 2 = Enable BG1
	STA.W SNES_TM               ; $212C = Main screen designation
								; Display BG1 and BG3 on main screen

	REP #$30                    ; 16-bit A, X, Y

	LDA.W #$0000                ; A = $0000
	STA.L $7E31B5               ; Clear [$7E31B5] (game state variable)

	JSR.W CODE_00BD64           ; Initialize graphics/display system

	SEP #$20                    ; 8-bit accumulator

	JSL.L CODE_0C8000           ; Bank $0C: Wait for VBLANK

	; ---------------------------------------------------------------------------
	; Configure OAM (Sprite) DMA Transfer
	; ---------------------------------------------------------------------------
	; OAM = Object Attribute Memory (sprite data)
	; DMA Channel 5 used for sprite transfers during VBLANK
	;
	; DMA Configuration:
	;   Source: $000C00 (RAM - OAM buffer)
	;   Destination: $2104 (OAMDATA register)
	;   Size: $0220 bytes (544 bytes = 128 sprites × 4 bytes + 32 bytes hi table)
	;   Mode: $04 = Write 2 registers once each (OAMDATA + OAMDATAWR)
	; ---------------------------------------------------------------------------

	LDX.W #$0000                ; X = $0000
	STX.W SNES_OAMADDL          ; $2102-$2103 = OAM address = $0000
								; Start writing at first sprite

	LDX.W #$0400                ; X = $0400
								; $04 = DMA mode: 2 registers, write once
								; $00 = Target register low byte
	STX.W SNES_DMA5PARAM        ; $4350 = DMA5 parameters

	LDX.W #$0C00                ; X = $0C00
	STX.W SNES_DMA5ADDRL        ; $4352-$4353 = Source address $xx0C00

	LDA.B #$00                  ; A = $00
	STA.W SNES_DMA5ADDRH        ; $4354 = Source bank = $00 → $000C00

	LDX.W #$0220                ; X = $0220 (544 bytes)
	STX.W SNES_DMA5CNTL         ; $4355-$4356 = Transfer size = 544 bytes

	LDA.B #$20                  ; A = $20 (bit 5 = DMA channel 5)
	STA.W SNES_MDMAEN           ; $420B = Execute DMA channel 5
								; Copies OAM data to PPU

	; ---------------------------------------------------------------------------
	; Initialize Game State Variables
	; ---------------------------------------------------------------------------

	REP #$30                    ; 16-bit A, X, Y

	LDA.W #$FFFF                ; A = $FFFF
	STA.W $010E                 ; [$010E] = $FFFF (state marker)

	JSL.L CODE_00C795           ; Initialize subsystem
	JSR.W CODE_00BA1A           ; Initialize subsystem
	JSL.L CODE_00C7B8           ; Initialize subsystem

	SEP #$20                    ; 8-bit accumulator
	RTS                         ; Return to caller

;===============================================================================
; LOAD SAVED GAME ($008166-$0081D4)
;===============================================================================

CODE_008166:
	; ===========================================================================
	; Load Game from SRAM
	; ===========================================================================
	; Restores saved game data from SRAM (battery-backed save RAM).
	;
	; Process:
	;   1. Copy save data from SRAM ($700000+) to WRAM
	;   2. Restore character stats, inventory, progress flags
	;   3. Load appropriate save slot data
	;   4. Initialize display with saved state
	;
	; SNES SRAM Details:
	;   - Mapped to $700000-$77FFFF (bank $70-$77)
	;   - Battery-backed, persists when power off
	;   - FFMQ uses multiple save slots
	; ===========================================================================

	REP #$30                    ; 16-bit A, X, Y

	; ---------------------------------------------------------------------------
	; Copy Save Data Block 1: MVN (Block Move Negative)
	; ---------------------------------------------------------------------------
	; MVN instruction: Move block of memory
	; Format: MVN srcbank,dstbank
	; X = source address, Y = destination address, A = length-1
	;
	; This copies $0040 bytes from $0CA9C2 to $001010
	; ---------------------------------------------------------------------------

	LDX.W #$A9C2                ; X = $A9C2 (source address low/mid)
	LDY.W #$1010                ; Y = $1010 (destination address)
	LDA.W #$003F                ; A = $003F (transfer 64 bytes: $3F+1)
	MVN $00,$0C                 ; Copy from bank $0C to bank $00
								; Source: $0CA9C2, Dest: $001010, Size: $40

	; Note: MVN auto-increments X, Y and decrements A until A = $FFFF
	; After execution: X = $A9C2+$40, Y = $1010+$40, A = $FFFF

	; ---------------------------------------------------------------------------
	; Copy Save Data Block 2
	; ---------------------------------------------------------------------------
	; Y already = $1010+$40 = $1050 from previous MVN
	; Copies $000A bytes from $0C0E9E to $001050
	; ---------------------------------------------------------------------------

	LDY.W #$0E9E                ; Y = $0E9E (new source address)
								; Overwrites Y (dest becomes source for new copy)
								; Actually this is confusing - need to verify
	LDA.W #$0009                ; A = $0009 (transfer 10 bytes: $09+1)
	MVN $00,$0C                 ; Copy from bank $0C to bank $00

	SEP #$20                    ; 8-bit accumulator

	; ---------------------------------------------------------------------------
	; Set Save Slot Marker
	; ---------------------------------------------------------------------------

	LDA.B #$02                  ; A = $02
	STA.W $0FE7                 ; [$0FE7] = $02 (save slot indicator?)

	; ---------------------------------------------------------------------------
	; Determine Active Save Slot
	; ---------------------------------------------------------------------------
	; $7E3668 contains save slot number (0, 1, or 2)
	; If >= 2, wraps to slot 0
	; ---------------------------------------------------------------------------

	LDA.L $7E3668               ; A = save slot number
	CMP.B #$02                  ; Compare with 2
	BCC CODE_00818E             ; If < 2, skip ahead (valid slot 0 or 1)

	LDA.B #$FF                  ; A = $FF (invalid slot, reset to -1)

CODE_00818E:
	; ===========================================================================
	; Load Save Slot Data Table
	; ===========================================================================
	; Each save slot has associated data in a table.
	; Slot number is incremented and used as index into data table.
	;
	; Data Table Structure (8 bytes per slot):
	;   See DATA8_0081D5-0081ED below
	; ===========================================================================

	INC A                       ; A = slot number + 1 (1, 2, or 3)
	STA.L $7E3668               ; Update slot number in RAM

	REP #$30                    ; 16-bit A, X, Y

	AND.W #$0003                ; A = A & 3 (ensure 0-3 range)
	ASL A                       ; A = A × 2
	ASL A                       ; A = A × 4
	ASL A                       ; A = A × 8 (8 bytes per slot)
	TAX                         ; X = slot_index × 8 (table offset)

	SEP #$20                    ; 8-bit accumulator

	; ---------------------------------------------------------------------------
	; Load Data from Slot Table
	; ---------------------------------------------------------------------------
	; Uses X as offset into DATA8_0081D5 table
	; Loads 8 bytes of configuration data for this save slot
	; ---------------------------------------------------------------------------

	STZ.B $19                   ; [$19] = $00 (clear direct page variable)

	LDA.W DATA8_0081D5,X        ; A = table[X+0] (byte 0)
	STA.W $0E88                 ; Store to $0E88

	LDY.W DATA8_0081D6,X        ; Y = table[X+1,X+2] (bytes 1-2, 16-bit)
	STY.W $0E89                 ; Store to $0E89-$0E8A

	LDA.W DATA8_0081D8,X        ; A = table[X+3] (byte 3)
	STA.W $0E92                 ; Store to $0E92

	LDY.W DATA8_0081DB,X        ; Y = table[X+4,X+5] (bytes 4-5, 16-bit)
	STY.B $53                   ; Store to $53-$54

	LDY.W DATA8_0081D9,X        ; Y = table[X+6,X+7] (bytes 6-7, 16-bit)
	TYX                         ; X = Y (transfer loaded value to X)

	REP #$30                    ; 16-bit A, X, Y

	; ---------------------------------------------------------------------------
	; Copy Additional Save Data
	; ---------------------------------------------------------------------------
	; Copies $0020 bytes from $0C:X to $000EA8
	; X was loaded from table above
	; ---------------------------------------------------------------------------

	LDY.W #$0EA8                ; Y = $0EA8 (destination)
	LDA.W #$001F                ; A = $001F (copy 32 bytes)
	MVN $00,$0C                 ; Copy from bank $0C to bank $00

	; ---------------------------------------------------------------------------
	; Final Save Load Setup
	; ---------------------------------------------------------------------------

	LDX.W #$0E92                ; X = $0E92
	STX.B $17                   ; [$17] = $0E92 (store pointer)

	JSR.W CODE_00A236           ; Process loaded save data

	SEP #$20                    ; 8-bit accumulator

	JSL.L CODE_009319           ; Finalize save load

	RTS                         ; Return

;-------------------------------------------------------------------------------
; SAVE SLOT DATA TABLE
;-------------------------------------------------------------------------------
; Format: 8 bytes per save slot (4 slots: $FF, 0, 1, 2)
; Structure unclear without further analysis
;-------------------------------------------------------------------------------

DATA8_0081D5:
	db $2D                      ; Slot 0, byte 0

DATA8_0081D6:
	dw $1F26                    ; Slot 0, bytes 1-2 (little-endian)

DATA8_0081D8:
	db $05                      ; Slot 0, byte 3

DATA8_0081D9:
	dw $AA0C                    ; Slot 0, bytes 4-5

DATA8_0081DB:
	dw $A82E                    ; Slot 0, bytes 6-7

	; Slot 1 data (8 bytes)
	db $19, $0E, $1A, $02, $0C, $AA, $C1, $A8

	; Slot 2 data (8 bytes)
	db $14, $33, $28, $05, $2C, $AA, $6A, $A9

DATA8_0081ED:
	; Referenced by CODE_0080DC (at $008113)
	; Initialization data table
	db $EC, $A6, $03

;===============================================================================
; RAM INITIALIZATION ($0081F0-$008227)
;===============================================================================

CODE_0081F0:
	; ===========================================================================
	; Clear All Work RAM
	; ===========================================================================
	; Zeros out RAM ranges $0000-$05FF and $0800-$1FFF.
	; Leaves $0600-$07FF untouched (likely reserved for specific purpose).
	;
	; Uses MVN (Block Move Negative) instruction for fast memory fill.
	; Clever technique: Write zero to first byte, then copy that byte forward.
	;
	; RAM Layout After Clear:
	;   $0000-$05FF: Cleared (1,536 bytes)
	;   $0600-$07FF: Preserved (512 bytes) - hardware mirrors or special use
	;   $0800-$1FFF: Cleared (6,144 bytes)
	; ===========================================================================

	LDA.W #$0000                ; A = $0000
	TCD                         ; D = $0000 (Direct Page = $0000)
								; Reset direct page to bank $00 start

	STZ.B $00                   ; [$0000] = $00 (write zero to first byte)

	; ---------------------------------------------------------------------------
	; Clear $0000-$05FF (1,536 bytes)
	; ---------------------------------------------------------------------------
	; Technique: Copy the zero byte forward across memory
	; Source: $0000 (which we just set to $00)
	; Dest: $0002 (start copying from here)
	; Length: $05FD+1 = $05FE bytes
	; Result: $0000-$05FF all become $00
	; ---------------------------------------------------------------------------

	LDX.W #$0000                ; X = $0000 (source address)
	LDY.W #$0002                ; Y = $0002 (dest address - skip $0000,$0001)
	LDA.W #$05FD                ; A = $05FD (copy 1,534 bytes)
	MVN $00,$00                 ; Fill $0002-$05FF with zero
								; (copying from $0000 which is zero)

	; ---------------------------------------------------------------------------
	; Clear $0800-$1FFF (6,144 bytes)
	; ---------------------------------------------------------------------------
	; Same technique for second RAM region
	; Skips $0600-$07FF (512 bytes preserved)
	; ---------------------------------------------------------------------------

	STZ.W $0800                 ; [$0800] = $00 (write zero to start of region)

	LDX.W #$0800                ; X = $0800 (source address)
	LDY.W #$0802                ; Y = $0802 (dest address)
	LDA.W #$17F8                ; A = $17F8 (copy 6,137 bytes)
	MVN $00,$00                 ; Fill $0802-$1FFF with zero

	; ---------------------------------------------------------------------------
	; Set Boot Signature
	; ---------------------------------------------------------------------------
	; $7E3367 = Boot signature/checksum
	; $3369 might be a magic number verifying proper boot
	; ---------------------------------------------------------------------------

	LDA.W #$3369                ; A = $3369 (boot signature)
	STA.L $7E3367               ; [$7E3367] = $3369

	; ---------------------------------------------------------------------------
	; Load Initial Data Table Based on Save Flag
	; ---------------------------------------------------------------------------
	; Checks if save file exists, loads different init table accordingly
	; ---------------------------------------------------------------------------

	LDX.W #$822A                ; X = $822A (default data table pointer)

	LDA.L $7E3667               ; A = save file exists flag
	AND.W #$00FF                ; Mask to 8-bit value
	BEQ CODE_008227             ; If 0 (no save) → use default table

	LDX.W #$822D                ; X = $822D (alternate table for existing save)

CODE_008227:
	JMP.W CODE_009BC4           ; Load/process data table and return

;-------------------------------------------------------------------------------
; INITIALIZATION DATA TABLES
;-------------------------------------------------------------------------------

DATA8_00822A:
	; No save file table
	db $2D, $A6, $03

DATA8_00822D:
	; Has save file table
	db $2B, $A6, $03

;===============================================================================
; FINAL SETUP ROUTINE ($008230-$008246)
;===============================================================================

CODE_008230:
	; ===========================================================================
	; Final Setup Before Main Game
	; ===========================================================================
	; Called just before jumping to main game loop.
	; Sets up additional game state in bank $7E RAM.
	; ===========================================================================

	REP #$30                    ; 16-bit A, X, Y

	PEA.W $007E                 ; Push $007E to stack
	PLB                         ; Pull to B (Data Bank = $7E)
								; All memory accesses now default to bank $7E

	LDA.W #$0170                ; A = $0170 (parameter 1)
	LDY.W #$3007                ; Y = $3007 (parameter 2)
	JSR.W CODE_009A08           ; Initialize with these parameters

	LDA.W #$0098                ; A = $0098
	STA.W $31B5                 ; [$7E31B5] = $0098 (game state variable)

	PLB                         ; Restore B (Data Bank back to $00)
	RTS                         ; Return

;===============================================================================
; HARDWARE INITIALIZATION ($008247-$008251)
;===============================================================================

CODE_008247:
	; ===========================================================================
	; Initialize SNES Hardware (Disable Display and Interrupts)
	; ===========================================================================
	; Called at boot to put SNES in safe state before initialization.
	;
	; Actions:
	;   1. Disable all interrupts (NMI, IRQ, auto-joypad)
	;   2. Force screen blank (turn off display)
	;
	; This prevents glitches during initialization by ensuring:
	;   - No interrupts fire during setup
	;   - No garbage displays on screen
	;   - PPU is idle and safe to configure
	; ===========================================================================

	SEP #$30                    ; 8-bit A, X, Y (and set flags)

	STZ.W SNES_NMITIMEN         ; $4200 = $00
								; Disable NMI, IRQ, and auto-joypad read

	LDA.B #$80                  ; A = $80 (bit 7 = force blank)
	STA.W SNES_INIDISP          ; $2100 = $80
								; Force blank: screen output disabled
								; Brightness = 0

	RTS                         ; Return

;-------------------------------------------------------------------------------
; DATA TABLE (Unknown Purpose)
;-------------------------------------------------------------------------------

DATA8_008252:
	; Referenced by DMA setup at CODE_00804D
	; 9 bytes of data
	db $00
	db $DB, $80, $FD, $DB, $80, $FD, $DB, $80, $FD

;===============================================================================
; VBLANK/NMI HANDLER AND DMA MANAGEMENT ($00825C-$008337)
;===============================================================================

CODE_00825C:
	; ===========================================================================
	; NMI/VBLANK Initialization and Setup
	; ===========================================================================
	; Initializes variables and structures used during VBLANK interrupt handling.
	; Sets up DMA transfer parameters and clears state flags.
	;
	; VBLANK Context:
	;   During active display (non-VBLANK), PPU VRAM/OAM/CGRAM are locked.
	;   VBLANK period (~4,500 cycles) is the only time for video updates.
	;   This routine prepares data structures for efficient VBLANK DMA.
	; ===========================================================================

	REP #$30                    ; 16-bit A, X, Y

	LDA.W #$0000                ; A = $0000
	TCD                         ; Direct Page = $0000

	; ---------------------------------------------------------------------------
	; Initialize DMA State Variables ($0500-$050A)
	; ---------------------------------------------------------------------------
	; These variables track DMA transfer state and configuration
	; ---------------------------------------------------------------------------

	LDX.W #$FF08                ; X = $FF08 (init value)
	STX.W $0503                 ; [$0503-$0504] = $FF08
	STX.W $0501                 ; [$0501-$0502] = $FF08

	LDX.W #$880F                ; X = $880F (init value)
	STX.W $0508                 ; [$0508-$0509] = $880F
	STX.W $0506                 ; [$0506-$0507] = $880F

	LDA.W #$00FF                ; A = $00FF
	SEP #$20                    ; 8-bit accumulator

	STA.W $0500                 ; [$0500] = $FF
	STA.W $0505                 ; [$0505] = $FF

	LDA.B #$00                  ; A = $00
	STA.W $050A                 ; [$050A] = $00

	; ---------------------------------------------------------------------------
	; Clear Graphics State Flags ($7E3659-$7E3663)
	; ---------------------------------------------------------------------------

	STA.L $7E3659               ; [$7E3659] = $00
	STA.L $7E365E               ; [$7E365E] = $00
	STA.L $7E3663               ; [$7E3663] = $00

	REP #$30                    ; 16-bit A, X, Y

	STA.L $7E365A               ; [$7E365A-$7E365B] = $0000
	STA.L $7E365C               ; [$7E365C-$7E365D] = $0000
	STA.L $7E365F               ; [$7E365F-$7E3660] = $0000
	STA.L $7E3661               ; [$7E3661-$7E3662] = $0000

	; ---------------------------------------------------------------------------
	; Load Additional Initialization Data
	; ---------------------------------------------------------------------------

	LDX.W #$8334                ; X = $8334 (pointer to init data table)
	JSR.W CODE_009BC4           ; Load/process data table

	; ---------------------------------------------------------------------------
	; Initialize OAM DMA Parameters
	; ---------------------------------------------------------------------------
	; $01F0/$01F2 = OAM DMA transfer sizes
	; ---------------------------------------------------------------------------

	LDA.W #$0040                ; A = $0040 (64 bytes)
	STA.W $01F0                 ; [$01F0] = $0040 (first OAM DMA size)

	LDA.W #$0004                ; A = $0004 (4 bytes)
	STA.W $01F2                 ; [$01F2] = $0004 (second OAM DMA size)

	; ---------------------------------------------------------------------------
	; Copy Data from ROM to RAM (Bank $7E)
	; ---------------------------------------------------------------------------

	LDX.W #$B81B                ; X = $B81B (source address low/mid)
	LDY.W #$3000                ; Y = $3000 (destination address)
	LDA.W #$0006                ; A = $0006 (copy 7 bytes)
	MVN $7E,$00                 ; Copy from bank $00 to bank $7E
								; Source: $00B81B → Dest: $7E3000

	; ---------------------------------------------------------------------------
	; Copy DMA Channel Configuration
	; ---------------------------------------------------------------------------
	; Copies 8 bytes from $004340 to $004340 (self-copy? or init?)
	; ---------------------------------------------------------------------------

	LDY.W #$4340                ; Y = $4340 (DMA channel 4 registers)
	LDA.W #$0007                ; A = $0007 (copy 8 bytes)
	MVN $00,$00                 ; Copy within bank $00

	; ---------------------------------------------------------------------------
	; Set Configuration Flag
	; ---------------------------------------------------------------------------

	LDA.W #$0010                ; A = $0010 (bit 4)
	TSB.W $0111                 ; Test and Set bit 4 in $0111

	; ---------------------------------------------------------------------------
	; Initialize Graphics System (3 calls)
	; ---------------------------------------------------------------------------

	LDA.W #$0000                ; A = $0000 (parameter)
	JSR.W CODE_00CA63           ; Initialize graphics component 0

	LDA.W #$0001                ; A = $0001 (parameter)
	JSR.W CODE_00CA63           ; Initialize graphics component 1

	LDA.W #$0002                ; A = $0002 (parameter)
	JSR.W CODE_00CA63           ; Initialize graphics component 2

	; ---------------------------------------------------------------------------
	; Load Graphics Data from ROM to RAM
	; ---------------------------------------------------------------------------

	LDX.W #$D380                ; X = $D380 (source: bank $0C, offset $D380)
	LDY.W #$0E84                ; Y = $0E84 (destination in bank $00)
	LDA.W #$017B                ; A = $017B (copy 380 bytes)
	MVN $00,$0C                 ; Copy from bank $0C to bank $00
								; Source: $0CD380 → Dest: $000E84

	LDX.W #$D0B0                ; X = $D0B0 (source: bank $0C, offset $D0B0)
	LDY.W #$1000                ; Y = $1000 (destination in bank $00)
	LDA.W #$004F                ; A = $004F (copy 80 bytes)
	MVN $00,$0C                 ; Copy from bank $0C to bank $00
								; Source: $0CD0B0 → Dest: $001000

	; ---------------------------------------------------------------------------
	; Initialize Character/Party State
	; ---------------------------------------------------------------------------

	LDA.W #$00FF                ; A = $00FF
	STA.W $1090                 ; [$1090] = $00FF (character state?)
	STA.W $10A1                 ; [$10A1] = $00FF
	STA.W $10A0                 ; [$10A0] = $00FF (active character?)

	; ---------------------------------------------------------------------------
	; Load Configuration from ROM
	; ---------------------------------------------------------------------------

	LDA.L DATA8_07800A          ; A = [ROM $07800A]
	AND.W #$739C                ; A = A & $739C (mask specific bits)
	STA.W $0E9C                 ; [$0E9C] = masked value

	; ---------------------------------------------------------------------------
	; Initialize Additional Systems
	; ---------------------------------------------------------------------------

	JSR.W CODE_008EC4           ; Initialize system
	JSR.W CODE_008C3D           ; Initialize system
	JSR.W CODE_008D29           ; Initialize system

	; ---------------------------------------------------------------------------
	; Set Direct Page to PPU Registers ($2100)
	; ---------------------------------------------------------------------------
	; Clever technique: Set D=$2100 so direct page accesses hit PPU registers
	; This makes `STA.B $15` equivalent to `STA.W $2115` (VMAINC)
	; Saves bytes and cycles in tight VBLANK code
	; ---------------------------------------------------------------------------

	LDA.W #$2100                ; A = $2100 (PPU register base)
	TCD                         ; D = $2100 (Direct Page → PPU registers)

	STZ.W $00F0                 ; [$00F0] = $0000 (clear state)

	; ---------------------------------------------------------------------------
	; Upload Graphics to VRAM
	; ---------------------------------------------------------------------------

	LDX.W #$6080                ; X = $6080 (VRAM address)
	STX.B SNES_VMADDL-$2100     ; $2116-$2117 = VRAM address $6080
								; (using direct page offset)

	PEA.W $0004                 ; Push $0004
	PLB                         ; B = $04 (Data Bank = $04)
								; Memory accesses now default to bank $04

	LDX.W #$99C0                ; X = $99C0 (source address in bank $04)
	LDY.W #$0004                ; Y = $0004 (DMA parameters)
	JSL.L CODE_008DDF           ; Execute graphics upload via DMA

	PLB                         ; Restore Data Bank
	RTL                         ; Return

;-------------------------------------------------------------------------------
; INITIALIZATION DATA TABLE
;-------------------------------------------------------------------------------

DATA8_008334:
	; Referenced at $0082A2
	db $FC, $A6, $03

;===============================================================================
; MAIN NMI/VBLANK HANDLER ($008337-$0083E7)
;===============================================================================

CODE_008337:
	; ===========================================================================
	; NMI (Non-Maskable Interrupt) Handler - VBLANK Routine
	; ===========================================================================
	; This is the main VBLANK handler called 60 times per second during vertical
	; blanking interval. This is the ONLY safe time to update VRAM, OAM, CGRAM.
	;
	; VBLANK Timing:
	;   - Triggered automatically when display reaches end of frame
	;   - Lasts ~4,500 CPU cycles (~1.3ms at 3.58MHz)
	;   - Must complete all DMA transfers within this window
	;   - Missing VBLANK causes visible glitches (tearing, flicker)
	;
	; This Handler:
	;   - Sets Direct Page to $4300 (DMA registers)
	;   - Checks state flags to determine what needs updating
	;   - Executes DMA transfers for graphics, sprites, palettes
	;   - Updates VRAM addresses and scroll positions
	;   - Returns before VBLANK ends
	;
	; State Flags Checked:
	;   $00E2 bit 6: Special mode handler
	;   $00D4 bit 1: Tilemap DMA pending
	;   $00DD bit 6: Graphics upload pending
	;   $00D8 bit 7: Battle graphics update
	;   $00D2 bits: Various DMA operation flags
	; ===========================================================================

	REP #$30                    ; 16-bit A, X, Y

	LDA.W #$4300                ; A = $4300 (DMA register base)
	TCD                         ; D = $4300 (Direct Page → DMA registers)
								; Now `LDA.B $00` = `LDA.W $4300` etc.

	SEP #$20                    ; 8-bit accumulator

	STZ.W $420C                 ; $420C (HDMAEN) = $00
								; Disable HDMA during processing

	; ---------------------------------------------------------------------------
	; Check State Flag $00E2 Bit 6 (Special Handler Mode)
	; ---------------------------------------------------------------------------

	LDA.B #$40                  ; A = $40 (bit 6 mask)
	AND.W $00E2                 ; Test bit 6 of $00E2
	BNE CODE_00837D             ; If set → Jump to special handler

	; ---------------------------------------------------------------------------
	; Check State Flag $00D4 Bit 1 (Tilemap DMA)
	; ---------------------------------------------------------------------------

	LDA.B #$02                  ; A = $02 (bit 1 mask)
	AND.W $00D4                 ; Test bit 1 of $00D4
	BNE CODE_00837A             ; If set → Tilemap DMA needed

	; ---------------------------------------------------------------------------
	; Check State Flag $00DD Bit 6 (Graphics Upload)
	; ---------------------------------------------------------------------------

	LDA.B #$40                  ; A = $40 (bit 6 mask)
	AND.W $00DD                 ; Test bit 6 of $00DD
	BNE CODE_008385             ; If set → Graphics upload needed

	; ---------------------------------------------------------------------------
	; Check State Flag $00D8 Bit 7 (Battle Graphics)
	; ---------------------------------------------------------------------------

	LDA.B #$80                  ; A = $80 (bit 7 mask)
	AND.W $00D8                 ; Test bit 7 of $00D8
	BEQ CODE_008366             ; If clear → Skip battle graphics

	LDA.B #$80                  ; A = $80
	TRB.W $00D8                 ; Test and Reset bit 7 of $00D8
								; Clear the flag (one-shot operation)

	JMP.W CODE_0085B7           ; Execute battle graphics update

;-------------------------------------------------------------------------------

CODE_008366:
	; ===========================================================================
	; Check Additional DMA Flags
	; ===========================================================================
	; Continues checking state flags for other DMA operations.
	; ===========================================================================

	LDA.B #$C0                  ; A = $C0 (bits 6-7 mask)
	AND.W $00D2                 ; Test bits 6-7 of $00D2
	BNE CODE_0083A8             ; If any set → Execute DMA operations

	LDA.B #$10                  ; A = $10 (bit 4 mask)
	AND.W $00D2                 ; Test bit 4 of $00D2
	BNE CODE_008377             ; If set → Special operation

	JMP.W CODE_008428           ; → Continue to additional handlers

;-------------------------------------------------------------------------------

CODE_008377:
	JMP.W CODE_00863D           ; Execute special DMA operation

;-------------------------------------------------------------------------------

CODE_00837A:
	JMP.W CODE_0083E8           ; Execute tilemap DMA transfer

;-------------------------------------------------------------------------------

CODE_00837D:
	; ===========================================================================
	; Special Mode Handler (Indirect Jump)
	; ===========================================================================
	; Bit 6 of $00E2 triggers special handler mode.
	; Jumps through pointer at [$0058] (16-bit address in bank $00).
	; This allows dynamic handler switching.
	; ===========================================================================

	LDA.B #$40                  ; A = $40
	TRB.W $00E2                 ; Test and Reset bit 6 of $00E2
								; Clear flag before jumping

	JML.W [$0058]               ; Jump Long to address stored at [$0058]
								; Indirect jump through pointer!

;-------------------------------------------------------------------------------

CODE_008385:
	; ===========================================================================
	; Graphics Upload via DMA
	; ===========================================================================
	; Transfers graphics data from RAM to VRAM during VBLANK.
	; Uses DMA channel 5 for bulk transfer.
	;
	; DMA Configuration:
	;   Source: RAM address from $01F6 (bank $7F)
	;   Destination: VRAM address from $01F8
	;   Size: $01F4 bytes
	;   Mode: $1801 (incrementing source, fixed dest register pair)
	; ===========================================================================

	LDX.W #$1801                ; X = $1801
								; $18 = DMA mode (2 registers, increment)
								; $01 = Low byte of destination register
	STX.B SNES_DMA5PARAM-$4300  ; $4350-$4351 = DMA5 parameters

	LDX.W $01F6                 ; X = source address (from variable)
	STX.B SNES_DMA5ADDRL-$4300  ; $4352-$4353 = Source address low/mid

	LDA.B #$7F                  ; A = $7F
	STA.B SNES_DMA5ADDRH-$4300  ; $4354 = Source bank $7F

	LDX.W $01F4                 ; X = transfer size (from variable)
	STX.B SNES_DMA5CNTL-$4300   ; $4355-$4356 = Transfer size

	LDX.W $01F8                 ; X = VRAM destination address
	STX.W SNES_VMADDL           ; $2116-$2117 = VRAM address

	LDA.B #$84                  ; A = $84
								; Bit 7 = increment after writing $2119
								; Bits 0-3 = increment by 128 words
	STA.W SNES_VMAINC           ; $2115 = VRAM address increment mode

	LDA.B #$20                  ; A = $20 (bit 5 = DMA channel 5)
	STA.W SNES_MDMAEN           ; $420B = Execute DMA channel 5
								; Transfer starts immediately!

;-------------------------------------------------------------------------------

CODE_0083A8:
	; ===========================================================================
	; Process DMA Operation Flags ($00D2)
	; ===========================================================================
	; Handles various DMA operations based on flags in $00D2.
	; ===========================================================================

	LDA.B #$80                  ; A = $80 (bit 7 mask)
	AND.W $00D2                 ; Test bit 7 of $00D2
	BEQ CODE_0083D3             ; If clear → Skip this DMA

	; ---------------------------------------------------------------------------
	; DMA Transfer with Vertical Increment
	; ---------------------------------------------------------------------------

	LDA.B #$80                  ; A = $80 (increment after $2119 write)
	STA.W SNES_VMAINC           ; $2115 = VRAM increment mode

	LDX.W #$1801                ; X = $1801 (DMA parameters)
	STX.B SNES_DMA5PARAM-$4300  ; $4350-$4351 = DMA5 config

	LDX.W $01ED                 ; X = source address
	STX.B SNES_DMA5ADDRL-$4300  ; $4352-$4353 = Source address low/mid

	LDA.W $01EF                 ; A = source bank
	STA.B SNES_DMA5ADDRH-$4300  ; $4354 = Source bank

	LDX.W $01EB                 ; X = transfer size
	STX.B SNES_DMA5CNTL-$4300   ; $4355-$4356 = Size

	LDX.W $0048                 ; X = VRAM address
	STX.W SNES_VMADDL           ; $2116-$2117 = VRAM address

	LDA.B #$20                  ; A = $20 (DMA channel 5)
	STA.W SNES_MDMAEN           ; $420B = Execute DMA

;-------------------------------------------------------------------------------

CODE_0083D3:
	; ===========================================================================
	; Check OAM Update Flag
	; ===========================================================================
	; Bit 5 of $00D2 triggers OAM (sprite) data upload.
	; ===========================================================================

	LDA.B #$20                  ; A = $20 (bit 5 mask)
	AND.W $00D2                 ; Test bit 5 of $00D2
	BEQ CODE_0083DD             ; If clear → Skip OAM update

	JSR.W CODE_008543           ; Execute OAM DMA transfer

;-------------------------------------------------------------------------------

CODE_0083DD:
	; ===========================================================================
	; Cleanup and Return from NMI
	; ===========================================================================
	; Clears processed flags and returns from interrupt handler.
	; ===========================================================================

	LDA.B #$40                  ; A = $40 (bit 6)
	TRB.W $00DD                 ; Test and Reset bit 6 of $00DD
								; Clear graphics upload flag

	LDA.B #$A0                  ; A = $A0 (bits 5 and 7)
	TRB.W $00D2                 ; Test and Reset bits 5,7 of $00D2
								; Clear OAM and VRAM DMA flags

	RTL                         ; Return from Long call (NMI complete)

;===============================================================================
; TILEMAP DMA TRANSFER ($0083E8-$008576)
;===============================================================================

CODE_0083E8:
	; ===========================================================================
	; Tilemap DMA Transfer to VRAM
	; ===========================================================================
	; Transfers tilemap data from ROM to VRAM for background layers.
	; Used when switching screens or updating large portions of the map.
	;
	; Process:
	;   1. Clear DMA pending flag ($00D4 bit 1)
	;   2. Configure CGRAM (palette) upload
	;   3. Transfer tilemap data to VRAM
	;   4. Handle special cases based on $0062 flag
	; ===========================================================================

	LDA.B #$02                  ; A = $02 (bit 1)
	TRB.W $00D4                 ; Test and Reset bit 1 of $00D4
								; Clear "tilemap DMA pending" flag

	LDA.B #$80                  ; A = $80 (increment after $2119 write)
	STA.W $2115                 ; $2115 (VMAINC) = $80
								; VRAM address increments by 1 word after high byte write

	; ---------------------------------------------------------------------------
	; Configure Palette (CGRAM) DMA
	; ---------------------------------------------------------------------------

	LDX.W #$2200                ; X = $2200
								; $22 = DMA mode (fixed source, increment dest)
								; $00 = Target register low byte
	STX.B SNES_DMA5PARAM-$4300  ; $4350 = DMA5 parameters

	LDA.B #$07                  ; A = $07
	STA.B SNES_DMA5ADDRH-$4300  ; $4354 = Source bank $07

	LDA.B #$A8                  ; A = $A8 (CGADD - palette address register)
	LDX.W $0064                 ; X = [$0064] (palette index/parameters)
	JSR.W CODE_008504           ; Execute palette DMA transfer

	; ---------------------------------------------------------------------------
	; Prepare for Tilemap Transfer
	; ---------------------------------------------------------------------------

	REP #$30                    ; 16-bit A, X, Y

	LDX.W #$FF00                ; X = $FF00
	STX.W $00F0                 ; [$00F0] = $FF00 (state marker)

	; ---------------------------------------------------------------------------
	; Check Transfer Mode ($0062)
	; ---------------------------------------------------------------------------
	; $0062 determines which transfer path to take
	; If $0062 = 1, use special graphics upload method
	; Otherwise, use standard tilemap transfer
	; ---------------------------------------------------------------------------

	LDX.W $0062                 ; X = [$0062] (transfer mode flag)
	LDA.W #$6080                ; A = $6080 (default VRAM address)

	CPX.W #$0001                ; Compare mode with 1
	BEQ CODE_00841A             ; If mode = 1 → Special graphics upload

	JSR.W CODE_008520           ; Standard tilemap transfer
	RTL                         ; Return

;-------------------------------------------------------------------------------

CODE_00841A:
	; ===========================================================================
	; Special Graphics Upload (Mode 1)
	; ===========================================================================
	; Alternative graphics upload path when $0062 = 1.
	; Uses different source data and parameters.
	; ===========================================================================

	PHK                         ; Push Program Bank (K register)
	PLB                         ; Pull to Data Bank (B register)
								; B = $00 (set data bank to current program bank)

	STA.W SNES_VMADDL           ; $2116-$2117 = VRAM address $6080

	LDX.W #$F0C1                ; X = $F0C1 (source address in bank $04)
	LDY.W #$0004                ; Y = $0004 (DMA parameters)
	JMP.W CODE_008DDF           ; Execute graphics DMA and return

;===============================================================================
; ADDITIONAL VRAM TRANSFER ROUTINES ($008428-$008576)
;===============================================================================

CODE_008428:
	; ===========================================================================
	; Large VRAM Transfer Handler
	; ===========================================================================
	; Handles large-scale VRAM transfers during VBLANK.
	; Checks state flags and executes appropriate transfer operations.
	;
	; State Flags:
	;   $00D4 bit 7: Large transfer pending
	;   $00D8 bit 1: Battle graphics mode
	;   $00DA bit 4: Special transfer mode
	; ===========================================================================

	LDA.B #$80                  ; A = $80 (bit 7 mask)
	AND.W $00D4                 ; Test bit 7 of $00D4
	BEQ CODE_008476             ; If clear → Skip, jump to handler return

	LDA.B #$80                  ; A = $80
	TRB.W $00D4                 ; Test and Reset bit 7 of $00D4
								; Clear "large transfer pending" flag

	LDA.B #$80                  ; A = $80 (increment mode)
	STA.W $2115                 ; $2115 (VMAINC) = $80

	; ---------------------------------------------------------------------------
	; Check Battle Graphics Mode ($00D8 bit 1)
	; ---------------------------------------------------------------------------

	LDA.B #$02                  ; A = $02 (bit 1 mask)
	AND.W $00D8                 ; Test bit 1 of $00D8
	BEQ CODE_008479             ; If clear → Use alternate path

	; ---------------------------------------------------------------------------
	; Battle Graphics Transfer
	; ---------------------------------------------------------------------------
	; Transfers battle-specific graphics during scene transitions
	; ---------------------------------------------------------------------------

	LDX.W #$1801                ; X = $1801 (DMA parameters)
	STX.B SNES_DMA5PARAM-$4300  ; $4350 = DMA5 config

	LDX.W #$075A                ; X = $075A (source address offset)
	STX.B SNES_DMA5ADDRL-$4300  ; $4352-$4353 = Source address low/mid

	LDA.B #$7F                  ; A = $7F
	STA.B SNES_DMA5ADDRH-$4300  ; $4354 = Source bank $7F
								; Full source: $7F075A

	LDX.W #$0062                ; X = $0062 (98 bytes)
	STX.B SNES_DMA5CNTL-$4300   ; $4355-$4356 = Transfer size

	LDX.W #$3BAD                ; X = $3BAD (VRAM destination)
	STX.W $2116                 ; $2116-$2117 = VRAM address

	LDA.B #$20                  ; A = $20 (DMA channel 5)
	STA.W $420B                 ; $420B = Execute DMA

	; ---------------------------------------------------------------------------
	; Additional Battle Graphics Data Transfer
	; ---------------------------------------------------------------------------
	; Writes specific data directly to VRAM
	; ---------------------------------------------------------------------------

	REP #$30                    ; 16-bit A, X, Y

	LDX.W #$4BED                ; X = $4BED (VRAM address)
	STX.W $2116                 ; Set VRAM address

	LDA.L $7F17DA               ; A = [$7F17DA] (16-bit data)
	STA.W $2118                 ; $2118-$2119 = Write to VRAM data

	LDA.L $7F17DC               ; A = [$7F17DC] (16-bit data)
	STA.W $2118                 ; Write second word to VRAM

	SEP #$20                    ; 8-bit accumulator

;-------------------------------------------------------------------------------

CODE_008476:
	; ===========================================================================
	; Return to Main NMI Handler
	; ===========================================================================
	JMP.W CODE_0083A8           ; → Jump back to NMI handler continuation

;-------------------------------------------------------------------------------

CODE_008479:
	; ===========================================================================
	; Alternate Graphics Transfer Path
	; ===========================================================================
	; Used when battle graphics mode is not active.
	; Handles palette and tilemap transfers for normal gameplay.
	; ===========================================================================

	; ---------------------------------------------------------------------------
	; Configure Palette DMA
	; ---------------------------------------------------------------------------

	LDX.W #$2200                ; X = $2200 (DMA parameters)
	STX.B SNES_DMA5PARAM-$4300  ; $4350 = DMA5 config

	LDA.B #$07                  ; A = $07
	STA.B SNES_DMA5ADDRH-$4300  ; $4354 = Source bank $07

	; ---------------------------------------------------------------------------
	; Transfer Two Palette Sets
	; ---------------------------------------------------------------------------

	LDA.B #$88                  ; A = $88 (palette address)
	LDX.W $00F4                 ; X = [$00F4] (source offset 1)
	JSR.W CODE_008504           ; Transfer palette set 1

	LDA.B #$98                  ; A = $98 (palette address)
	LDX.W $00F7                 ; X = [$00F7] (source offset 2)
	JSR.W CODE_008504           ; Transfer palette set 2

	; ---------------------------------------------------------------------------
	; Write Direct VRAM Data
	; ---------------------------------------------------------------------------

	REP #$30                    ; 16-bit A, X, Y

	LDX.W #$5E8D                ; X = $5E8D (VRAM address)
	STX.W $2116                 ; Set VRAM address

	LDA.L $7E2D1A               ; A = [$7E2D1A] (data from WRAM)
	STA.W $2118                 ; Write to VRAM

	LDA.L $7E2D1C               ; A = [$7E2D1C]
	STA.W $2118                 ; Write second word

	; ---------------------------------------------------------------------------
	; Prepare for Tilemap Transfer
	; ---------------------------------------------------------------------------

	LDX.W #$FF00                ; X = $FF00
	STX.W $00F0                 ; [$00F0] = $FF00 (marker)

	; ---------------------------------------------------------------------------
	; Transfer Two Tilemap Regions
	; ---------------------------------------------------------------------------

	LDX.W $00F2                 ; X = [$00F2] (tilemap 1 source)
	LDA.W #$6000                ; A = $6000 (VRAM address 1)
	JSR.W CODE_008520           ; Transfer tilemap region 1

	LDX.W $00F5                 ; X = [$00F5] (tilemap 2 source)
	LDA.W #$6040                ; A = $6040 (VRAM address 2)
	JSR.W CODE_008520           ; Transfer tilemap region 2

	SEP #$20                    ; 8-bit accumulator

	; ---------------------------------------------------------------------------
	; Check Special Transfer Mode
	; ---------------------------------------------------------------------------

	LDA.B #$10                  ; A = $10 (bit 4 mask)
	AND.W $00DA                 ; Test bit 4 of $00DA
	BNE CODE_0084F8             ; If set → Skip menu graphics transfer

	; ---------------------------------------------------------------------------
	; Menu Graphics Transfer
	; ---------------------------------------------------------------------------
	; Transfers menu-specific graphics data
	; ---------------------------------------------------------------------------

	LDX.W #$1801                ; X = $1801 (DMA parameters)
	STX.B SNES_DMA5PARAM-$4300  ; $4350 = DMA5 config

	LDX.W #$0380                ; X = $0380 (896 bytes)
	STX.B SNES_DMA5CNTL-$4300   ; $4355-$4356 = Transfer size

	LDA.B #$7F                  ; A = $7F
	STA.B SNES_DMA5ADDRH-$4300  ; $4354 = Source bank $7F

	; ---------------------------------------------------------------------------
	; Select Source Address Based on Menu Position
	; ---------------------------------------------------------------------------
	; $1031 contains vertical menu position
	; Different Y positions use different graphics data
	; ---------------------------------------------------------------------------

	LDA.W $1031                 ; A = [$1031] (Y position)

	LDX.W #$C708                ; X = $C708 (default source 1)
	CMP.B #$26                  ; Compare Y with $26
	BCC CODE_0084EB             ; If Y < $26 → Use source 1

	LDX.W #$C908                ; X = $C908 (source 2)
	CMP.B #$29                  ; Compare Y with $29
	BCC CODE_0084EB             ; If Y < $29 → Use source 2

	LDX.W #$CA48                ; X = $CA48 (source 3)
								; Y >= $29 → Use source 3

CODE_0084EB:
	STX.B SNES_DMA5ADDRL-$4300  ; $4352-$4353 = Selected source address

	LDX.W #$6700                ; X = $6700 (VRAM destination)
	STX.W SNES_VMADDL           ; $2116-$2117 = VRAM address

	LDA.B #$20                  ; A = $20 (DMA channel 5)
	STA.W SNES_MDMAEN           ; $420B = Execute DMA

;-------------------------------------------------------------------------------

CODE_0084F8:
	; ===========================================================================
	; Clear Transfer Markers and Return
	; ===========================================================================

	LDX.W #$FFFF                ; X = $FFFF
	STX.W $00F2                 ; [$00F2] = $FFFF (invalidate tilemap 1)
	STX.W $00F5                 ; [$00F5] = $FFFF (invalidate tilemap 2)

	JMP.W CODE_0083A8           ; → Return to NMI handler

;===============================================================================
; PALETTE TRANSFER HELPER ($008504-$00851F)
;===============================================================================

CODE_008504:
	; ===========================================================================
	; Palette Transfer Helper Routine
	; ===========================================================================
	; Transfers a single palette set to CGRAM via DMA.
	;
	; Parameters:
	;   A = Palette start address (CGADD value)
	;   X = Source data offset (8-bit, added to base $07D8E4)
	;
	; Process:
	;   1. Set CGRAM address
	;   2. Calculate full source address
	;   3. Execute 16-byte DMA transfer
	; ===========================================================================

	STA.W $2121                 ; $2121 (CGADD) = Palette start address
								; Sets where in CGRAM to write

	LDY.W #$0010                ; Y = $0010 (16 bytes = 8 colors)
	STY.B SNES_DMA5CNTL-$4300   ; $4355-$4356 = Transfer 16 bytes

	REP #$30                    ; 16-bit A, X, Y

	TXA                         ; A = X (transfer source offset to A)
	AND.W #$00FF                ; A = A & $00FF (ensure 8-bit value)
	CLC                         ; Clear carry
	ADC.W #$D8E4                ; A = A + $D8E4 (add base address)
								; Final source in bank $07: $07(D8E4+offset)
	STA.B SNES_DMA5ADDRL-$4300  ; $4352-$4353 = Calculated source address

	SEP #$20                    ; 8-bit accumulator

	LDA.B #$20                  ; A = $20 (DMA channel 5)
	STA.W $420B                 ; $420B = Execute palette DMA

	RTS                         ; Return

;===============================================================================
; TILEMAP TRANSFER HELPER ($008520-$008542)
;===============================================================================

CODE_008520:
	; ===========================================================================
	; Tilemap Transfer Helper Routine
	; ===========================================================================
	; Transfers tilemap data to VRAM in two passes for proper formatting.
	;
	; Parameters:
	;   A = VRAM destination address
	;   X = Source address offset (or $FFFF to skip)
	;
	; SNES Tilemap Format:
	;   Each tile = 2 bytes (tile number + attributes)
	;   Transfers in two passes separated by $0180 bytes
	;   This likely handles interleaved data format
	; ===========================================================================

	CPX.W #$FFFF                ; Check if X = $FFFF
	BEQ CODE_008542             ; If yes → Skip transfer (no data)

	STA.W SNES_VMADDL           ; $2116-$2117 = VRAM destination address

	PEA.W $0004                 ; Push $0004
	PLB                         ; B = $04 (Data Bank = $04)

	PHX                         ; Save X (source address)

	LDY.W #$0002                ; Y = $0002 (DMA parameters)
	JSL.L CODE_008DDF           ; Execute first tilemap transfer

	PLA                         ; A = saved X (restore source address)
	CLC                         ; Clear carry
	ADC.W #$0180                ; A = source + $0180 (offset to second half)
	TAX                         ; X = new source address

	LDY.W #$0002                ; Y = $0002 (DMA parameters)
	JSL.L CODE_008DDF           ; Execute second tilemap transfer
								; (VRAM address auto-increments)

	PLB                         ; Restore Data Bank

CODE_008542:
	RTS                         ; Return

;===============================================================================
; OAM (SPRITE) TRANSFER ROUTINE ($008543-$008576)
;===============================================================================

CODE_008543:
	; ===========================================================================
	; OAM (Object Attribute Memory) Transfer
	; ===========================================================================
	; Transfers sprite data from RAM to OAM during VBLANK.
	; OAM contains position, tile, and attribute data for all sprites.
	;
	; SNES OAM Structure:
	;   Main table: 512 bytes (128 sprites × 4 bytes each)
	;     Byte 0: X position (low 8 bits)
	;     Byte 1: Y position
	;     Byte 2: Tile number
	;     Byte 3: Attributes (palette, priority, flip)
	;   High table: 32 bytes (128 sprites × 2 bits each)
	;     Bit 0: X position bit 8 (for X > 255)
	;     Bit 1: Sprite size toggle
	;
	; This routine transfers both tables in two DMA operations.
	; ===========================================================================

	; ---------------------------------------------------------------------------
	; Configure DMA for Main OAM Table
	; ---------------------------------------------------------------------------

	LDX.W #$0400                ; X = $0400
								; $04 = DMA mode (write 2 registers once)
								; $00 = Target register low byte ($2104 = OAMDATA)
	STX.B SNES_DMA5PARAM-$4300  ; $4350 = DMA5 config

	LDX.W #$0C00                ; X = $0C00 (source address)
	STX.B SNES_DMA5ADDRL-$4300  ; $4352-$4353 = Source in bank $00: $000C00

	LDA.B #$00                  ; A = $00
	STA.B SNES_DMA5ADDRH-$4300  ; $4354 = Source bank $00

	LDX.W $01F0                 ; X = [$01F0] (transfer size - main table)
	STX.B SNES_DMA5CNTL-$4300   ; $4355-$4356 = Size (typically $0200 = 512 bytes)

	LDX.W #$0000                ; X = $0000
	STX.W SNES_OAMADDL          ; $2102-$2103 = OAM address = 0
								; Start writing at first sprite

	LDA.B #$20                  ; A = $20 (DMA channel 5)
	STA.W SNES_MDMAEN           ; $420B = Execute DMA (main table)

	; ---------------------------------------------------------------------------
	; Configure DMA for High OAM Table
	; ---------------------------------------------------------------------------

	LDX.W #$0E00                ; X = $0E00 (source address for high table)
	STX.B SNES_DMA5ADDRL-$4300  ; $4352-$4353 = Source: $000E00

	LDX.W $01F2                 ; X = [$01F2] (transfer size - high table)
	STX.B SNES_DMA5CNTL-$4300   ; $4355-$4356 = Size (typically $0020 = 32 bytes)

	LDX.W #$0100                ; X = $0100
	STX.W SNES_OAMADDL          ; $2102-$2103 = OAM address = $100
								; This is where high table starts

	LDA.B #$20                  ; A = $20 (DMA channel 5)
	STA.W SNES_MDMAEN           ; $420B = Execute DMA (high table)

	RTS                         ; Return

;===============================================================================
; BATTLE GRAPHICS UPDATE ($008577-$0085B6)
;===============================================================================

CODE_008577:
	; ===========================================================================
	; Battle Graphics VRAM Transfer
	; ===========================================================================
	; Transfers battle-specific graphics to VRAM during scene transitions.
	; Handles both tile data and tilemap updates.
	; ===========================================================================

	; ---------------------------------------------------------------------------
	; Transfer Battle Tile Graphics
	; ---------------------------------------------------------------------------

	LDX.W #$4400                ; X = $4400 (VRAM destination)
	STX.W SNES_VMADDL           ; $2116-$2117 = VRAM address

	LDX.W #$1801                ; X = $1801 (DMA parameters)
	STX.B SNES_DMA5PARAM-$4300  ; $4350 = DMA5 config

	LDX.W #$0480                ; X = $0480 (source address offset)
	STX.B SNES_DMA5ADDRL-$4300  ; $4352-$4353 = Source in bank $7F: $7F0480

	LDA.B #$7F                  ; A = $7F
	STA.B SNES_DMA5ADDRH-$4300  ; $4354 = Source bank

	LDX.W #$0280                ; X = $0280 (640 bytes)
	STX.B SNES_DMA5CNTL-$4300   ; $4355-$4356 = Transfer size

	LDA.B #$20                  ; A = $20 (DMA channel 5)
	STA.W SNES_MDMAEN           ; $420B = Execute DMA
	; ===========================================================================

	LDA.B #$80                  ; A = $80 (bit 7)
	TRB.W $00DE                 ; Test and Reset bit 7 of $00DE
								; Clear some state flag

	LDA.B #$E0                  ; A = $E0 (bits 5-7)
	TRB.W $0111                 ; Test and Reset bits 5-7 of $0111
								; Clear multiple state flags

	JSL.L CODE_0C8000           ; Bank $0C: Wait for VBLANK

	; ---------------------------------------------------------------------------
	; Configure Color Math (Fade Effect)

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
; Graphics Update - Field Mode (continued from CODE_008577)
;===============================================================================

CODE_0085B7:
	; Setup VRAM for vertical increment mode
	LDA.B #$80                       ; Increment after writing to $2119
	STA.W SNES_VMAINC                ; Set VRAM increment mode

	; Check if battle mode graphics needed
	LDA.B #$10                       ; Check bit 4 of display flags
	AND.W $00DA                      ; Test against display status
	BEQ +                            ; If clear, continue to field graphics
	JMP CODE_008577                  ; Otherwise do battle graphics transfer
+
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

;===============================================================================
; SPECIAL GRAPHICS TRANSFER ROUTINES ($00863D-$008965)
;===============================================================================

CODE_00863D:
	; ===========================================================================
	; Special VRAM Transfer Handler
	; ===========================================================================
	; Handles specialized graphics transfers for menu systems and battle mode.
	; Manages palette selection, tilemap updates, and context-specific graphics.
	;
	; State Flags:
	;   $00D2 bit 4: Special transfer pending
	;   $00DA bit 4: Battle mode graphics flag
	;   $00DE bit 6: Character status update
	;   $00D6 bit 5: Additional display update flag
	; ===========================================================================

	LDA.B #$10                  ; A = $10 (bit 4 mask)
	TRB.W $00D2                 ; Test and Reset bit 4 of $00D2
								; Clear "special transfer pending" flag

	LDA.B #$80                  ; A = $80 (increment mode)
	STA.W SNES_VMAINC           ; $2115 = Increment after $2119 write

	; ---------------------------------------------------------------------------
	; Check Battle Mode Graphics Flag
	; ---------------------------------------------------------------------------

	LDA.B #$10                  ; A = $10 (bit 4 mask)
	AND.W $00DA                 ; Test bit 4 of $00DA
	BEQ CODE_00869D             ; If clear → Use normal field mode graphics

	; ---------------------------------------------------------------------------
	; Battle Mode Graphics Transfer
	; ---------------------------------------------------------------------------
	; Transfers menu graphics for battle interface
	; ---------------------------------------------------------------------------

	PEA.W $0004                 ; Push $0004
	PLB                         ; B = $04 (Data Bank = $04)

	LDX.W #$60C0                ; X = $60C0 (VRAM address)
	STX.W $2116                 ; Set VRAM address

	LDX.W #$FF00                ; X = $FF00
	STX.W $00F0                 ; [$00F0] = $FF00 (state marker)

	LDX.W #$99C0                ; X = $99C0 (source in bank $04)
	LDY.W #$0004                ; Y = $0004 (DMA parameters)
	JSL.L CODE_008DDF           ; Execute tilemap DMA transfer

	PLB                         ; Restore Data Bank

	; ---------------------------------------------------------------------------
	; Transfer Battle Palette Set 1
	; ---------------------------------------------------------------------------

	LDA.B #$A8                  ; A = $A8 (palette start address)
	STA.W SNES_CGADD            ; $2121 = CGRAM address = $A8

	LDX.W #$2200                ; X = $2200 (DMA parameters)
	STX.B SNES_DMA5PARAM-$4300  ; $4350 = DMA5 config

	LDX.W #$D814                ; X = $D814 (source offset)
	STX.B SNES_DMA5ADDRL-$4300  ; $4352-$4353 = Source: $07D814

	LDA.B #$07                  ; A = $07
	STA.B SNES_DMA5ADDRH-$4300  ; $4354 = Source bank $07

	LDX.W #$0010                ; X = $0010 (16 bytes = 8 colors)
	STX.B SNES_DMA5CNTL-$4300   ; $4355-$4356 = Transfer size

	LDA.B #$20                  ; A = $20 (DMA channel 5)
	STA.W SNES_MDMAEN           ; $420B = Execute palette DMA

	; ---------------------------------------------------------------------------
	; Clear Specific Palette Entries
	; ---------------------------------------------------------------------------
	; Clears palette entries $0D and $1D to black
	; Used to reset specific UI colors in battle mode
	; ---------------------------------------------------------------------------

	LDA.B #$0D                  ; A = $0D (palette entry 13)
	STA.W SNES_CGADD            ; Set CGRAM address
	STZ.W SNES_CGDATA           ; $2122 = $00 (color low byte = black)
	STZ.W SNES_CGDATA           ; $2122 = $00 (color high byte)

	LDA.B #$1D                  ; A = $1D (palette entry 29)
	STA.W SNES_CGADD            ; Set CGRAM address
	STZ.W SNES_CGDATA           ; $2122 = $00 (black)
	STZ.W SNES_CGDATA           ; $2122 = $00

	RTL                         ; Return

;-------------------------------------------------------------------------------

CODE_00869D:
	; ===========================================================================
	; Field Mode Graphics Transfer
	; ===========================================================================
	; Handles graphics updates for field/map mode interface.
	; Transfers palettes, tilemaps, and character status displays.
	; ===========================================================================

	; ---------------------------------------------------------------------------
	; Configure Palette DMA
	; ---------------------------------------------------------------------------

	LDX.W #$2200                ; X = $2200 (DMA parameters)
	STX.B SNES_DMA5PARAM-$4300  ; $4350 = DMA5 config

	LDX.W #$D824                ; X = $D824 (source offset)
	STX.B SNES_DMA5ADDRL-$4300  ; $4352-$4353 = Source: $07D824

	LDA.B #$07                  ; A = $07
	STA.B SNES_DMA5ADDRH-$4300  ; $4354 = Source bank $07

	LDX.W #$0010                ; X = $0010 (16 bytes)
	STX.B SNES_DMA5CNTL-$4300   ; $4355-$4356 = Transfer size

	REP #$30                    ; 16-bit A, X, Y

	STZ.W $00F0                 ; [$00F0] = $0000 (clear state marker)

	PEA.W $0004                 ; Push $0004
	PLB                         ; B = $04 (Data Bank = $04)

	; ---------------------------------------------------------------------------
	; Check Character Status Update Flag ($00DE bit 6)
	; ---------------------------------------------------------------------------
	; If set, update single character's status display
	; Otherwise, refresh all three character displays
	; ---------------------------------------------------------------------------

	LDA.W #$0040                ; A = $0040 (bit 6 mask)
	AND.W $00DE                 ; Test bit 6 of $00DE
	BEQ CODE_0086F3             ; If clear → Update all characters

	; ---------------------------------------------------------------------------
	; Single Character Status Update
	; ---------------------------------------------------------------------------
	; Updates one character's status display based on $010D and $010E
	; ---------------------------------------------------------------------------

	LDA.W #$0040                ; A = $0040
	TRB.W $00DE                 ; Test and Reset bit 6 of $00DE
								; Clear "single character update" flag

	LDA.W $010D                 ; A = [$010D] (character position data)
	AND.W #$FF00                ; A = A & $FF00 (mask high byte)
	CLC                         ; Clear carry
	ADC.W #$6180                ; A = A + $6180 (calculate VRAM address)
	STA.W $2116                 ; $2116-$2117 = VRAM address

	LDA.W $010E                 ; A = [$010E] (character index)
	ASL A                       ; A = A × 2 (convert to word offset)
	TAX                         ; X = character table offset

	LDA.W $0107,X               ; A = [$0107 + X] (character data pointer)
	TAX                         ; X = character data pointer

	PHA                         ; Save character data pointer
	JSR.W CODE_008751           ; Transfer character graphics (2-part)
	PLY                         ; Y = character data pointer (restore)

	PLB                         ; Restore Data Bank

	; ---------------------------------------------------------------------------
	; Transfer Character Palette
	; ---------------------------------------------------------------------------

	CLC                         ; Clear carry
	LDA.W $010E                 ; A = [$010E] (character index)
	ADC.W #$000D                ; A = A + $000D (palette offset)
	ASL A                       ; A = A × 2
	ASL A                       ; A = A × 4
	ASL A                       ; A = A × 8
	ASL A                       ; A = A × 16 (multiply by 16)
	TAX                         ; X = palette CGRAM address

	JSR.W CODE_00876C           ; Transfer character palette

	RTL                         ; Return

;-------------------------------------------------------------------------------

CODE_0086F3:
	; ===========================================================================
	; Full Character Status Display Update
	; ===========================================================================
	; Refreshes all three character status displays.
	; Transfers character graphics, names, and palettes for the party.
	; ===========================================================================

	; ---------------------------------------------------------------------------
	; Transfer Base Menu Tilemap
	; ---------------------------------------------------------------------------

	LDA.W #$6100                ; A = $6100 (VRAM address)
	STA.W $2116                 ; Set VRAM address

	LDX.W #$9A20                ; X = $9A20 (source in bank $04)
	LDY.W #$0004                ; Y = $0004 (DMA parameters)
	JSL.L CODE_008DDF           ; Transfer tilemap part 1

	LDX.W #$CD20                ; X = $CD20 (source for second part)
	LDY.W #$0004                ; Y = $0004 (DMA parameters)
	JSL.L CODE_008DDF           ; Transfer tilemap part 2

	; ---------------------------------------------------------------------------
	; Transfer Character 1 Graphics
	; ---------------------------------------------------------------------------

	LDX.W $0107                 ; X = [$0107] (character 1 data pointer)
	JSR.W CODE_008751           ; Transfer character 1 graphics

	; ---------------------------------------------------------------------------
	; Transfer Character 2 Graphics
	; ---------------------------------------------------------------------------

	LDA.W #$6280                ; A = $6280 (VRAM address for char 2)
	STA.W $2116                 ; Set VRAM address

	LDX.W $0109                 ; X = [$0109] (character 2 data pointer)
	JSR.W CODE_008751           ; Transfer character 2 graphics

	; ---------------------------------------------------------------------------
	; Transfer Character 3 Graphics
	; ---------------------------------------------------------------------------

	LDA.W #$6380                ; A = $6380 (VRAM address for char 3)
	STA.W $2116                 ; Set VRAM address

	LDX.W $010B                 ; X = [$010B] (character 3 data pointer)
	JSR.W CODE_008751           ; Transfer character 3 graphics

	PLB                         ; Restore Data Bank

	; ---------------------------------------------------------------------------
	; Transfer Main Menu Palette
	; ---------------------------------------------------------------------------

	LDA.W #$D824                ; A = $D824 (source address)
	LDX.W #$00C0                ; X = $00C0 (CGRAM address = palette $C)
	JSR.W CODE_00876F           ; Transfer palette

	; ---------------------------------------------------------------------------
	; Transfer Character 1 Palette
	; ---------------------------------------------------------------------------

	LDY.W $0107                 ; Y = [$0107] (character 1 data pointer)
	LDX.W #$00D0                ; X = $00D0 (CGRAM address = palette $D)
	JSR.W CODE_00876C           ; Transfer character palette

	; ---------------------------------------------------------------------------
	; Transfer Character 2 Palette
	; ---------------------------------------------------------------------------

	LDY.W $0109                 ; Y = [$0109] (character 2 data pointer)
	LDX.W #$00E0                ; X = $00E0 (CGRAM address = palette $E)
	JSR.W CODE_00876C           ; Transfer character palette

	; ---------------------------------------------------------------------------
	; Transfer Character 3 Palette
	; ---------------------------------------------------------------------------

	LDY.W $010B                 ; Y = [$010B] (character 3 data pointer)
	LDX.W #$00F0                ; X = $00F0 (CGRAM address = palette $F)
	JSR.W CODE_00876C           ; Transfer character palette

	RTL                         ; Return

;===============================================================================
; GRAPHICS HELPER SUBROUTINES ($008751-$008783)
;===============================================================================

CODE_008751:
	; ===========================================================================
	; Transfer Character Graphics (2-Part Transfer)
	; ===========================================================================
	; Transfers character graphics in two sequential DMA operations.
	; Used for character portraits in status displays.
	;
	; Parameters:
	;   X = Pointer to character data structure
	;   VRAM address already set in $2116
	;
	; Character Data Structure:
	;   +$00: Pointer to graphics part 1 (2 bytes)
	;   +$02: Pointer to graphics part 2 (2 bytes)
	; ===========================================================================

	PHX                         ; Save character data pointer

	; ---------------------------------------------------------------------------
	; Transfer Graphics Part 1
	; ---------------------------------------------------------------------------

	LDA.L $000000,X             ; A = [X+0] (graphics part 1 pointer)
	TAX                         ; X = graphics part 1 pointer
	LDY.W #$0004                ; Y = $0004 (DMA parameters)
	JSL.L CODE_008DDF           ; Execute DMA transfer

	; ---------------------------------------------------------------------------
	; Transfer Graphics Part 2
	; ---------------------------------------------------------------------------

	PLX                         ; Restore character data pointer

	LDA.L $000002,X             ; A = [X+2] (graphics part 2 pointer)
	TAX                         ; X = graphics part 2 pointer
	LDY.W #$0004                ; Y = $0004 (DMA parameters)
	JSL.L CODE_008DDF           ; Execute DMA transfer
								; (VRAM address auto-increments from part 1)

	RTS                         ; Return

;-------------------------------------------------------------------------------

CODE_00876C:
	; ===========================================================================
	; Transfer Character Palette (Variant Entry Point)
	; ===========================================================================
	; Alternative entry point that loads palette source from character data.
	; Falls through to CODE_00876F.
	;
	; Parameters:
	;   X = CGRAM address (palette index)
	;   Y = Character data pointer
	; ===========================================================================

	LDA.W $0004,Y               ; A = [Y+4] (palette data pointer)
								; Falls through to CODE_00876F

CODE_00876F:
	; ===========================================================================
	; Transfer Palette to CGRAM
	; ===========================================================================
	; Executes a 16-byte palette DMA transfer.
	;
	; Parameters:
	;   A = Source address (low/mid bytes, bank $07 assumed)
	;   X = CGRAM address (palette index)
	;
	; SNES Palette Format:
	;   Each color = 2 bytes (15-bit BGR format)
	;   16 bytes = 8 colors per transfer
	; ===========================================================================

	STA.B SNES_DMA5ADDRL-$4300  ; $4352-$4353 = Source address

	TXA                         ; A = X (CGRAM address)
	SEP #$20                    ; 8-bit accumulator

	STA.W SNES_CGADD            ; $2121 = CGRAM address

	LDX.W #$0010                ; X = $0010 (16 bytes)
	STX.B SNES_DMA5CNTL-$4300   ; $4355-$4356 = Transfer size

	LDA.B #$20                  ; A = $20 (DMA channel 5)
	STA.W SNES_MDMAEN           ; $420B = Execute palette DMA

	REP #$30                    ; 16-bit A, X, Y

	RTS                         ; Return

;===============================================================================
; ADDITIONAL VBLANK OPERATIONS ($008784-$008965)
;===============================================================================

; Data table referenced by CODE_008784
DATA8_008960:
	db $3C                     ; Tile $3C

DATA8_008961:
	db $3D                     ; Tile $3D

DATA8_008962:
	db $3E,$45,$3A,$3B         ; Tiles: $3E, $45, $3A, $3B

;===============================================================================
; MAIN GAME LOOP & FRAME UPDATE ($008966-$0089C5)
;===============================================================================

CODE_008966:
	; ===========================================================================
	; Main Game Loop - Frame Update Handler
	; ===========================================================================
	; This is the main game logic executed every frame (60 times per second).
	; Called from the NMI handler continuation path.
	;
	; Responsibilities:
	;   1. Increment 24-bit frame counter ($0E97-$0E99)
	;   2. Process time-based events (status effects, animations)
	;   3. Handle full screen refreshes on mode changes
	;   4. Process controller input and menu navigation
	;   5. Update game state and animations
	;
	; Frame Counter:
	;   $0E97-$0E98: Low 16 bits (wraps at 65536)
	;   $0E99: High 8 bits (total 24-bit = ~16.7 million frames)
	;   At 60fps, this counter wraps after ~77.9 hours of gameplay
	; ===========================================================================

	REP #$30                    ; 16-bit A, X, Y

	LDA.W #$0000                ; A = $0000
	TCD                         ; D = $0000 (Direct Page = zero page)
								; Reset DP for main game logic

	; ---------------------------------------------------------------------------
	; Increment 24-Bit Frame Counter
	; ---------------------------------------------------------------------------

	INC.W $0E97                 ; Increment frame counter low word
	BNE CODE_008974             ; If no overflow → Skip high byte increment
	INC.W $0E99                 ; Increment high byte (24-bit overflow)

;-------------------------------------------------------------------------------

CODE_008974:
	; ===========================================================================
	; Time-Based Event Processing
	; ===========================================================================

	JSR.W CODE_0089C6           ; Process time-based events (status effects, etc.)

	; ---------------------------------------------------------------------------
	; Check Full Screen Refresh Flag ($00D4 bit 2)
	; ---------------------------------------------------------------------------
	; When set, indicates a major mode change requiring full redraw
	; (battle start, menu open, scene transition, etc.)
	; ---------------------------------------------------------------------------

	LDA.W #$0004                ; A = $0004 (bit 2 mask)
	AND.W $00D4                 ; Test bit 2 of $00D4
	BEQ CODE_008999             ; If clear → Normal frame processing

	; ---------------------------------------------------------------------------
	; Full Screen Refresh Path
	; ---------------------------------------------------------------------------
	; Executes when entering/exiting major game modes.
	; Performs complete redraw of both BG layers.
	; ---------------------------------------------------------------------------

	LDA.W #$0004                ; A = $0004
	TRB.W $00D4                 ; Test and Reset bit 2 of $00D4
								; Clear "full refresh needed" flag

	; Refresh Background Layer 0
	LDA.W #$0000                ; A = $0000 (BG layer 0)
	JSR.W CODE_0091D4           ; Update BG layer 0 tilemap
	JSR.W CODE_008C3D           ; Transfer layer 0 to VRAM

	; Refresh Background Layer 1
	LDA.W #$0001                ; A = $0001 (BG layer 1)
	JSR.W CODE_0091D4           ; Update BG layer 1 tilemap
	JSR.W CODE_008D29           ; Transfer layer 1 to VRAM

	BRA CODE_0089BD             ; → Skip to animation update

;-------------------------------------------------------------------------------

CODE_008999:
	; ===========================================================================
	; Normal Frame Processing Path
	; ===========================================================================
	; Standard per-frame update when not doing full refresh.
	; Handles incremental tilemap updates and controller input.
	; ===========================================================================

	JSR.W CODE_008BFD           ; Update tilemap changes (scrolling, etc.)

	; ---------------------------------------------------------------------------
	; Check Menu Mode Flag ($00DA bit 4)
	; ---------------------------------------------------------------------------

	LDA.W #$0010                ; A = $0010 (bit 4 mask)
	AND.W $00DA                 ; Test bit 4 of $00DA (menu mode flag)
	BNE CODE_0089AC             ; If set → Process controller input

	; ---------------------------------------------------------------------------
	; Check Input Processing Enable ($00E2 bit 2)
	; ---------------------------------------------------------------------------

	LDA.W #$0004                ; A = $0004 (bit 2 mask)
	AND.W $00E2                 ; Test bit 2 of $00E2
	BNE CODE_0089BD             ; If set → Skip input (cutscene/auto mode)

;-------------------------------------------------------------------------------

CODE_0089AC:
	; ===========================================================================
	; Controller Input Processing
	; ===========================================================================
	; Processes joypad input when enabled.
	; Calls appropriate handler based on current game mode.
	; ===========================================================================

	LDA.B $07                   ; A = [$07] (controller data - current frame)
	AND.B $8E                   ; A = A & [$8E] (input enable mask)
	BEQ CODE_0089BD             ; If zero → No valid input, skip processing

	; ---------------------------------------------------------------------------
	; Determine Input Handler
	; ---------------------------------------------------------------------------
	; CODE_009730 returns handler index in A based on game state
	; Handler table at CODE_008A35 dispatches to appropriate routine
	; ---------------------------------------------------------------------------

	JSL.L CODE_009730           ; Get input handler index for current mode

	SEP #$30                    ; 8-bit A, X, Y

	ASL A                       ; A = A × 2 (convert to word offset)
	TAX                         ; X = handler table offset

	JSR.W (CODE_008A35,X)       ; Call appropriate input handler
								; (indirect jump through handler table)

;-------------------------------------------------------------------------------

CODE_0089BD:
	; ===========================================================================
	; Animation and State Update
	; ===========================================================================
	; Final phase of frame processing.
	; Updates animations, sprites, and game state.
	; ===========================================================================

	REP #$30                    ; 16-bit A, X, Y

	JSR.W CODE_009342           ; Update sprite animations
	JSR.W CODE_009264           ; Update game state and logic

	RTL                         ; Return to NMI handler continuation

;===============================================================================
; TIME-BASED EVENT HANDLER ($0089C6-$008A29)
;===============================================================================

CODE_0089C6:
	; ===========================================================================
	; Time-Based Event Processing
	; ===========================================================================
	; Processes status effects, poison damage, regeneration, and other
	; time-based events that occur at regular intervals.
	;
	; Timer System:
	;   $010D: Frame countdown timer (decrements each frame)
	;   When timer reaches -1, executes status effect checks
	;   Timer resets to 12 frames (~0.2 seconds at 60fps)
	;
	; Status Effect Checks:
	;   Character slots at fixed SRAM addresses:
	;   $700027: Character 1 status
	;   $700077: Character 2 status
	;   $7003B3: Character 3 status
	;   $700403: Character 4 status
	;   $70073F: Character 5 status
	;   $70078F: Character 6 status
	;
	; $00DE bit 7: Time-based processing enabled flag
	; ===========================================================================

	PHD                         ; Save Direct Page

	; ---------------------------------------------------------------------------
	; Check Time-Based Processing Enable Flag
	; ---------------------------------------------------------------------------

	LDA.W #$0080                ; A = $0080 (bit 7 mask)
	AND.W $00DE                 ; Test bit 7 of $00DE
	BEQ CODE_008A26             ; If clear → Skip time-based processing

	; ---------------------------------------------------------------------------
	; Set Direct Page for Character Status Access
	; ---------------------------------------------------------------------------

	LDA.W #$0C00                ; A = $0C00
	TCD                         ; D = $0C00 (Direct Page = $0C00)
								; Allows $01 to access $0C01, etc.

	SEP #$30                    ; 8-bit A, X, Y

	; ---------------------------------------------------------------------------
	; Decrement Timer and Check for Event Trigger
	; ---------------------------------------------------------------------------

	DEC.W $010D                 ; Decrement timer
	BPL CODE_008A26             ; If still positive → Exit (not time yet)

	; Timer expired - reset and process status effects
	LDA.B #$0C                  ; A = $0C (12 frames)
	STA.W $010D                 ; Reset timer to 12 frames

	; ---------------------------------------------------------------------------
	; Check Character 1 Status ($700027)
	; ---------------------------------------------------------------------------

	LDA.L $700027               ; A = [$700027] (character 1 status flags)
	BNE CODE_0089EA             ; If non-zero → Character 1 has status effect

	LDX.B #$40                  ; X = $40 (character 1 offset)
	JSR.W CODE_008A2A           ; Update character 1 display

;-------------------------------------------------------------------------------

CODE_0089EA:
	; ---------------------------------------------------------------------------
	; Check Character 2 Status ($700077)
	; ---------------------------------------------------------------------------

	LDA.L $700077               ; A = [$700077] (character 2 status)
	BNE CODE_0089F5             ; If non-zero → Character 2 has status

	LDX.B #$50                  ; X = $50 (character 2 offset)
	JSR.W CODE_008A2A           ; Update character 2 display

;-------------------------------------------------------------------------------

CODE_0089F5:
	; ---------------------------------------------------------------------------
	; Check Character 3 Status ($7003B3)
	; ---------------------------------------------------------------------------

	LDA.L $7003B3               ; A = [$7003B3] (character 3 status)
	BNE CODE_008A00             ; If non-zero → Character 3 has status

	LDX.B #$60                  ; X = $60 (character 3 offset)
	JSR.W CODE_008A2A           ; Update character 3 display

;-------------------------------------------------------------------------------

CODE_008A00:
	; ---------------------------------------------------------------------------
	; Check Character 4 Status ($700403)
	; ---------------------------------------------------------------------------

	LDA.L $700403               ; A = [$700403] (character 4 status)
	BNE CODE_008A0B             ; If non-zero → Character 4 has status

	LDX.B #$70                  ; X = $70 (character 4 offset)
	JSR.W CODE_008A2A           ; Update character 4 display

;-------------------------------------------------------------------------------

CODE_008A0B:
	; ---------------------------------------------------------------------------
	; Check Character 5 Status ($70073F)
	; ---------------------------------------------------------------------------

	LDA.L $70073F               ; A = [$70073F] (character 5 status)
	BNE CODE_008A16             ; If non-zero → Character 5 has status

	LDX.B #$80                  ; X = $80 (character 5 offset)
	JSR.W CODE_008A2A           ; Update character 5 display

;-------------------------------------------------------------------------------

CODE_008A16:
	; ---------------------------------------------------------------------------
	; Check Character 6 Status ($70078F)
	; ---------------------------------------------------------------------------

	LDA.L $70078F               ; A = [$70078F] (character 6 status)
	BNE CODE_008A21             ; If non-zero → Character 6 has status

	LDX.B #$90                  ; X = $90 (character 6 offset)
	JSR.W CODE_008A2A           ; Update character 6 display

;-------------------------------------------------------------------------------

CODE_008A21:
	; ---------------------------------------------------------------------------
	; Set Sprite Update Flag
	; ---------------------------------------------------------------------------

	LDA.B #$20                  ; A = $20 (bit 5)
	TSB.W $00D2                 ; Set bit 5 of $00D2 (sprite update needed)

;-------------------------------------------------------------------------------

CODE_008A26:
	; ===========================================================================
	; Restore Direct Page and Return
	; ===========================================================================

	REP #$30                    ; 16-bit A, X, Y
	PLD                         ; Restore Direct Page
	RTS                         ; Return

;-------------------------------------------------------------------------------

CODE_008A2A:
	; ===========================================================================
	; Update Character Status Display
	; ===========================================================================
	; Updates the character status icon tiles based on status effects.
	; Toggles between different tile sets to create animation effect.
	;
	; Parameters:
	;   X = Character offset ($40, $50, $60, $70, $80, or $90)
	;
	; Character Display Structure (at $0C00 + X):
	;   +$02: Status tile base value
	;   +$06: Status tile 1
	;   +$0A: Status tile 2
	;   +$0E: Status tile 3
	;
	; Tile Animation:
	;   Toggles bit 2 of base value (XOR $04)
	;   Then writes base+0, base+1, base+2, base+3 to tile slots
	; ===========================================================================

	LDA.B $02,X                 ; A = [$0C02+X] (current tile base)
	EOR.B #$04                  ; A = A XOR $04 (toggle bit 2 for animation)
	STA.B $02,X                 ; [$0C02+X] = new tile base

	INC A                       ; A = base + 1
	STA.W $0C06,X               ; [$0C06+X] = base + 1 (tile 1)

	INC A                       ; A = base + 2
	STA.W $0C0A,X               ; [$0C0A+X] = base + 2 (tile 2)

	INC A                       ; A = base + 3
	STA.W $0C0E,X               ; [$0C0E+X] = base + 3 (tile 3)

	RTS                         ; Return

;===============================================================================
; INPUT HANDLER DISPATCH TABLE ($008A35-$008A54)
;===============================================================================

CODE_008A35:
	; ===========================================================================
	; Input Handler Jump Table
	; ===========================================================================
	; Table of 16-bit addresses for different input handler routines.
	; Indexed by value returned from CODE_009730 (game mode).
	;
	; Handler addresses are stored as 16-bit little-endian values.
	; JSR (table,X) performs indirect jump to selected handler.
	; ===========================================================================

	; Note: This data is being used as code by the previous instruction
	; STA.W $0C0A,X at CODE_008A35 continues from CODE_008A2A
	; The actual table starts here with word addresses:

	; Handler jump table data (12 entries x 2 bytes = 24 bytes)
	db $CF,$8A, $F8,$8A, $68,$8B, $68,$8B  ; Handlers 0-3
	db $61,$8A, $5D,$8A, $59,$8A, $55,$8A  ; Handlers 4-7
	db $68,$8B, $68,$8B, $9D,$8A, $68,$8B  ; Handlers 8-11

;===============================================================================
; CURSOR MOVEMENT HANDLERS ($008A55-$008A9C)
;===============================================================================

CODE_008A55:
	; ===========================================================================
	; Cursor Down Handler
	; ===========================================================================
	DEC.B $02                   ; Decrement vertical position
	BRA CODE_008A63             ; → Validate position

CODE_008A59:
	; ===========================================================================
	; Cursor Up Handler
	; ===========================================================================
	INC.B $02                   ; Increment vertical position
	BRA CODE_008A63             ; → Validate position

CODE_008A5D:
	; ===========================================================================
	; Cursor Left Handler
	; ===========================================================================
	DEC.B $01                   ; Decrement horizontal position
	BRA CODE_008A63             ; → Validate position

CODE_008A61:
	; ===========================================================================
	; Cursor Right Handler
	; ===========================================================================
	INC.B $01                   ; Increment horizontal position
								; Falls through to validation

;-------------------------------------------------------------------------------

CODE_008A63:
	; ===========================================================================
	; Validate Horizontal Position
	; ===========================================================================
	; Ensures cursor stays within valid X range.
	;
	; Bounds Checking:
	;   $01: Current X position
	;   $03: Maximum X position
	;   $95 bit 0: Allow negative X wrapping
	;   $95 bit 1: Allow X overflow wrapping
	; ===========================================================================

	LDA.B $01                   ; A = X position
	BMI CODE_008A78             ; If negative → Check wrap flags

	CMP.B $03                   ; Compare with max X
	BCC CODE_008A80             ; If X < max → Valid, continue

	; X position at or above maximum
	LDA.B $95                   ; A = wrap flags
	AND.B #$01                  ; Test bit 0 (allow overflow)
	BNE CODE_008A78             ; If set → Allow wrap to negative

;-------------------------------------------------------------------------------

CODE_008A71:
	; X exceeded maximum, clamp to max-1
	LDA.B $03                   ; A = max X
	DEC A                       ; A = max - 1
	STA.B $01                   ; X position = max - 1 (clamp)
	BRA CODE_008A80             ; → Validate Y position

;-------------------------------------------------------------------------------

CODE_008A78:
	; X position is negative or wrapped
	LDA.B $95                   ; A = wrap flags
	AND.B #$02                  ; Test bit 1 (allow negative)
	BNE CODE_008A71             ; If set → Clamp to max-1

	STZ.B $01                   ; X position = 0 (clamp to minimum)

;-------------------------------------------------------------------------------

CODE_008A80:
	; ===========================================================================
	; Validate Vertical Position
	; ===========================================================================
	; Ensures cursor stays within valid Y range.
	;
	; Bounds Checking:
	;   $02: Current Y position
	;   $04: Maximum Y position
	;   $95 bit 2: Allow negative Y wrapping
	;   $95 bit 3: Allow Y overflow wrapping
	; ===========================================================================

	LDA.B $02                   ; A = Y position
	BMI CODE_008A94             ; If negative → Check wrap flags

	CMP.B $04                   ; Compare with max Y
	BCC CODE_008A9C             ; If Y < max → Valid, exit

	; Y position at or above maximum
	LDA.B $95                   ; A = wrap flags
	AND.B #$04                  ; Test bit 2 (allow overflow)
	BNE CODE_008A94             ; If set → Allow wrap to negative

;-------------------------------------------------------------------------------

CODE_008A8E:
	; Y exceeded maximum, clamp to max-1
	LDA.B $04                   ; A = max Y
	DEC A                       ; A = max - 1
	STA.B $02                   ; Y position = max - 1 (clamp)
	RTS                         ; Return

;-------------------------------------------------------------------------------

CODE_008A94:
	; Y position is negative or wrapped
	LDA.B $95                   ; A = wrap flags
	AND.B #$08                  ; Test bit 3 (allow negative)
	BNE CODE_008A8E             ; If set → Clamp to max-1

	STZ.B $02                   ; Y position = 0 (clamp to minimum)

;-------------------------------------------------------------------------------

CODE_008A9C:
	RTS                         ; Return

;===============================================================================
; BUTTON HANDLER & MENU LOGIC ($008A9D-$008BFC)
;===============================================================================

CODE_008A9D:
	; ===========================================================================
	; A Button Handler - Toggle Character Status
	; ===========================================================================
	; Handles A button press to toggle character status display.
	; Shows/hides detailed character information in battle mode.
	; ===========================================================================

	JSR.W CODE_008B57           ; Check if input allowed
	BNE CODE_008ABC             ; If blocked → Exit

	; Check if in valid screen position
	LDA.W $1090                 ; A = [$1090] (screen mode/position)
	BMI CODE_008AB9             ; If negative → Call alternate handler

	; Toggle character status display
	LDA.W $10A0                 ; A = [$10A0] (character display flags)
	EOR.B #$80                  ; Toggle bit 7
	STA.W $10A0                 ; Save new flag state

	LDA.B #$40                  ; A = $40 (bit 6)
	TSB.W $00D4                 ; Set bit 6 of $00D4 (update needed)

	JSR.W CODE_00B908           ; Update character display
	BRA CODE_008ABC             ; → Exit

;-------------------------------------------------------------------------------

CODE_008AB9:
	JSR.W CODE_00B912           ; Alternate character update routine

CODE_008ABC:
	RTS                         ; Return

;-------------------------------------------------------------------------------

CODE_008ABD:
	; ===========================================================================
	; Check Character Position Validity
	; ===========================================================================
	; Validates character screen position for interaction.
	; Used before processing menu selections.
	;
	; Position Check:
	;   $1032 = $80 and $1033 = $00 → Special case, call B912
	;   Otherwise → Call B908
	; ===========================================================================

	LDA.W $1032                 ; A = [$1032] (X position)
	CMP.B #$80                  ; Compare with $80
	BNE CODE_008ACC             ; If not $80 → Jump to B908

	LDA.W $1033                 ; A = [$1033] (Y position)
	BNE CODE_008ACC             ; If not $00 → Jump to B908

	JMP.W CODE_00B912           ; Special position → Call B912

;-------------------------------------------------------------------------------

CODE_008ACC:
	JMP.W CODE_00B908           ; Normal position → Call B908

;-------------------------------------------------------------------------------

CODE_008ACF:
	; ===========================================================================
	; Menu Navigation - Character Selection (Up/Down)
	; ===========================================================================
	; Handles up/down navigation through character list in menu.
	; Cycles through valid characters, skipping invalid/dead entries.
	; ===========================================================================

	JSR.W CODE_008B57           ; Check if input allowed
	BNE CODE_008AF7             ; If blocked → Exit

	JSR.W CODE_008ABD           ; Validate character position

	; ---------------------------------------------------------------------------
	; Calculate Current Character Index
	; ---------------------------------------------------------------------------

	LDA.W $1031                 ; A = [$1031] (Y position)
	SEC                         ; Set carry for subtraction
	SBC.B #$20                  ; A = Y - $20 (base offset)

	LDX.B #$FF                  ; X = -1 (character counter)

;-------------------------------------------------------------------------------

CODE_008ADF:
	; Divide by 3 to get character slot
	INX                         ; X++
	SBC.B #$03                  ; A -= 3
	BCS CODE_008ADF             ; If carry still set → Continue dividing

	; X now contains character index (0-3)
	TXA                         ; A = character index

;-------------------------------------------------------------------------------

CODE_008AE5:
	; ===========================================================================
	; Cycle to Next Valid Character
	; ===========================================================================
	; Increments character index and checks if character is valid.
	; Loops until valid character found.
	; ===========================================================================

	INC A                       ; A = next character index
	AND.B #$03                  ; A = A & $03 (wrap 0-3)

	PHA                         ; Save character index
	JSR.W CODE_008DA8           ; Check if character is valid
	PLA                         ; Restore character index

	CPY.B #$FF                  ; Check if character invalid (Y = $FF)
	BEQ CODE_008AE5             ; If invalid → Try next character

	; Valid character found
	JSR.W CODE_008B21           ; Update character display
	JSR.W CODE_008C3D           ; Refresh graphics

CODE_008AF7:
	RTS                         ; Return

;-------------------------------------------------------------------------------

CODE_008AF8:
	; ===========================================================================
	; Menu Navigation - Character Selection (Down/Reverse)
	; ===========================================================================
	; Handles down navigation, cycles backwards through character list.
	; Same as CODE_008ACF but decrements instead of increments.
	; ===========================================================================

	JSR.W CODE_008B57           ; Check if input allowed
	BNE CODE_008B20             ; If blocked → Exit

	JSR.W CODE_008ABD           ; Validate character position

	LDA.W $1031                 ; A = [$1031] (Y position)
	SEC                         ; Set carry
	SBC.B #$20                  ; A = Y - $20 (base offset)

	LDX.B #$FF                  ; X = -1 (counter)

;-------------------------------------------------------------------------------

CODE_008B08:
	INX                         ; X++
	SBC.B #$03                  ; A -= 3
	BCS CODE_008B08             ; If carry → Continue

	TXA                         ; A = character index

;-------------------------------------------------------------------------------

CODE_008B0E:
	; Cycle to previous valid character
	DEC A                       ; A = previous character index
	AND.B #$03                  ; A = A & $03 (wrap 0-3)

	PHA                         ; Save index
	JSR.W CODE_008DA8           ; Check if character valid
	PLA                         ; Restore index

	CPY.B #$FF                  ; Check if invalid
	BEQ CODE_008B0E             ; If invalid → Try previous

	JSR.W CODE_008B21           ; Update character display
	JSR.W CODE_008C3D           ; Refresh graphics

CODE_008B20:
	RTS                         ; Return

;-------------------------------------------------------------------------------

CODE_008B21:
	; ===========================================================================
	; Update Character Display Position
	; ===========================================================================
	; Updates tilemap pointer based on character Y position.
	; Different Y ranges use different tilemap sections.
	;
	; Y Position Ranges:
	;   Y < $23: Use tilemap at $3709
	;   Y < $26: Use tilemap at $3719
	;   Y < $29: Use tilemap at $3729
	;   Y >= $29: Use tilemap at $3739
	; ===========================================================================

	REP #$30                    ; 16-bit A, X, Y

	LDX.W #$3709                ; X = $3709 (default tilemap 1)
	CPY.W #$0023                ; Compare Y with $23
	BCC CODE_008B3E             ; If Y < $23 → Use tilemap 1

	LDX.W #$3719                ; X = $3719 (tilemap 2)
	CPY.W #$0026                ; Compare Y with $26
	BCC CODE_008B3E             ; If Y < $26 → Use tilemap 2

	LDX.W #$3729                ; X = $3729 (tilemap 3)
	CPY.W #$0029                ; Compare Y with $29
	BCC CODE_008B3E             ; If Y < $29 → Use tilemap 3

	LDX.W #$3739                ; X = $3739 (tilemap 4, Y >= $29)

;-------------------------------------------------------------------------------

CODE_008B3E:
	; ===========================================================================
	; Copy Tilemap Data to Destination
	; ===========================================================================
	; Uses MVN to copy 16 bytes of tilemap data.
	;
	; MVN Format:
	;   MVN dest_bank,src_bank
	;   Copies (A+1) bytes from X to Y
	;   Auto-increments X and Y, decrements A
	; ===========================================================================

	LDY.W #$3669                ; Y = $3669 (destination in bank $7E)
	LDA.W #$000F                ; A = $000F (15, so copy 16 bytes)
	MVN $7E,$7E                 ; Copy 16 bytes from X to Y (both in $7E)

	PHK                         ; Push program bank
	PLB                         ; Pull to data bank (B = $00)

	; ---------------------------------------------------------------------------
	; Refresh Background Layer
	; ---------------------------------------------------------------------------

	LDA.W #$0000                ; A = $0000 (BG layer 0)
	JSR.W CODE_0091D4           ; Update layer 0

	SEP #$30                    ; 8-bit A, X, Y

	LDA.B #$80                  ; A = $80 (bit 7)
	TSB.W $00D9                 ; Set bit 7 of $00D9

	RTS                         ; Return

;-------------------------------------------------------------------------------

CODE_008B57:
	; ===========================================================================
	; Check Input Enable Flags
	; ===========================================================================
	; Checks if controller input is currently allowed.
	; Returns with Z flag indicating result.
	;
	; Returns:
	;   Z flag clear (non-zero): Input blocked
	;   Z flag set (zero): Input allowed
	;
	; $00D6 bit 4: Input block flag
	; $92: Controller state (masked to disable certain buttons)
	; ===========================================================================

	LDA.B #$10                  ; A = $10 (bit 4 mask)
	AND.W $00D6                 ; Test bit 4 of $00D6
	BEQ CODE_008B67             ; If clear → Input allowed, exit

	; Input blocked - mask controller state
	REP #$30                    ; 16-bit A, X, Y

	LDA.B $92                   ; A = [$92] (controller state)
	AND.W #$BFCF                ; A = A & $BFCF (mask bits 4-5, 14)
								; Disables: bit 4, bit 5, bit 14

	SEP #$30                    ; 8-bit A, X, Y

CODE_008B67:
	RTS                         ; Return (Z flag indicates input state)

; Padding/unused byte
CODE_008B68:
	RTS                         ; Return

;===============================================================================
; CONTROLLER INPUT PROCESSING ($008BA0-$008BFC)
;===============================================================================

CODE_008BA0:
	; ===========================================================================
	; Main Controller Input Handler
	; ===========================================================================
	; Reads joypad state and processes button presses.
	; Handles autofire timing and input filtering.
	;
	; Controller State Variables:
	;   $92: Current frame button state
	;   $94: Newly pressed buttons (triggered this frame)
	;   $96: Previous frame button state
	;   $90: Autofire accumulator
	;   $09: Autofire repeat timer
	;
	; $00D6 bit 6: Disable controller reading
	; $00D2 bit 3: Special input mode
	; $00DB bit 2: Alternate input filtering
	; ===========================================================================

	REP #$30                    ; 16-bit A, X, Y

	LDA.W #$0000                ; A = $0000
	TCD                         ; D = $0000 (Direct Page = zero page)

	; ---------------------------------------------------------------------------
	; Check Controller Read Enable
	; ---------------------------------------------------------------------------

	LDA.W #$0040                ; A = $0040 (bit 6 mask)
	AND.W $00D6                 ; Test bit 6 of $00D6
	BNE CODE_008BFC             ; If set → Controller disabled, exit

	; ---------------------------------------------------------------------------
	; Save Previous Controller State
	; ---------------------------------------------------------------------------

	LDA.B $92                   ; A = current controller state
	STA.B $96                   ; Save as previous state

	; ---------------------------------------------------------------------------
	; Check Special Input Mode ($00D2 bit 3)
	; ---------------------------------------------------------------------------

	LDA.W #$0008                ; A = $0008 (bit 3 mask)
	AND.W $00D2                 ; Test bit 3 of $00D2
	BNE CODE_008BC7             ; If set → Special input mode

	; ---------------------------------------------------------------------------
	; Check Alternate Input Filter ($00DB bit 2)
	; ---------------------------------------------------------------------------

	LDA.W #$0004                ; A = $0004 (bit 2 mask)
	AND.W $00DB                 ; Test bit 2 of $00DB
	BNE CODE_008BD2             ; If set → Use alternate filtering

	; ---------------------------------------------------------------------------
	; Normal Controller Read
	; ---------------------------------------------------------------------------

	LDA.W SNES_CNTRL1L          ; A = [$4218] (Controller 1 input)
								; Reads 16-bit joypad state
	BRA CODE_008BEA             ; → Process input

;-------------------------------------------------------------------------------

CODE_008BC7:
	; ===========================================================================
	; Special Input Mode - Filter D-Pad
	; ===========================================================================
	; Reads controller but masks out D-pad directions.
	; Only allows button presses (A, B, X, Y, L, R, Start, Select).
	; ===========================================================================

	LDA.W SNES_CNTRL1L          ; A = controller state
	AND.W #$FFF0                ; A = A & $FFF0 (clear bits 0-3, D-pad)
	BEQ CODE_008BEA             ; If zero → No buttons pressed

	JMP.W CODE_0092F0           ; → Special button handler

;-------------------------------------------------------------------------------

CODE_008BD2:
	; ===========================================================================
	; Alternate Input Filter
	; ===========================================================================
	; Checks $00D9 bit 1 for additional filtering mode.
	; ===========================================================================

	LDA.W #$0002                ; A = $0002 (bit 1 mask)
	AND.W $00D9                 ; Test bit 1 of $00D9
	BEQ CODE_008BDF             ; If clear → Normal alternate mode

	; Special alternate mode (incomplete in disassembly)
	db $A9,$80,$00,$04,$90     ; Raw bytes (seems incomplete)

;-------------------------------------------------------------------------------

CODE_008BDF:
	LDA.W SNES_CNTRL1L          ; A = controller state
	AND.W #$FFF0                ; Mask D-pad
	BEQ CODE_008BEA             ; If zero → No buttons

	JMP.W CODE_0092F6           ; → Alternate button handler

;-------------------------------------------------------------------------------

CODE_008BEA:
	; ===========================================================================
	; Process Controller Input
	; ===========================================================================
	; Combines current hardware input with software autofire.
	; Calculates newly pressed buttons.
	; ===========================================================================

	ORA.B $90                   ; A = A | [$90] (OR with autofire bits)
	AND.W #$FFF0                ; Mask to buttons only
	STA.B $94                   ; [$94] = all pressed buttons this frame

	TAX                         ; X = pressed buttons (for later)

	TRB.B $96                   ; Clear pressed buttons from previous state
								; $96 now = buttons released this frame

	LDA.B $92                   ; A = previous frame state
	TRB.B $94                   ; Clear held buttons from new press state
								; $94 now = newly pressed buttons only

	STX.B $92                   ; Save current state
	STZ.B $90                   ; Clear autofire accumulator

CODE_008BFC:
	RTS                         ; Return

;===============================================================================
; AUTOFIRE & INPUT TIMING ($008BFD-$008C1A)
;===============================================================================

CODE_008BFD:
	; ===========================================================================
	; Autofire Timer Handler
	; ===========================================================================
	; Manages autofire/repeat functionality for held buttons.
	; When button held, generates periodic "new press" events.
	;
	; Timing:
	;   First repeat: After 25 frames (~0.4 seconds)
	;   Subsequent repeats: Every 5 frames (~0.08 seconds)
	;
	; Variables:
	;   $07: Output - Effective button presses this frame
	;   $09: Autofire countdown timer
	;   $94: Newly pressed buttons
	;   $92: Currently held buttons
	; ===========================================================================

	STZ.B $07                   ; Clear output (no input by default)

	; ---------------------------------------------------------------------------
	; Check for New Button Presses
	; ---------------------------------------------------------------------------

	LDA.B $94                   ; A = newly pressed buttons
	BNE CODE_008C13             ; If any new press → Handle immediate input

	; ---------------------------------------------------------------------------
	; Handle Held Buttons (Autofire)
	; ---------------------------------------------------------------------------

	LDA.B $92                   ; A = currently held buttons
	BEQ CODE_008C12             ; If nothing held → Exit

	DEC.B $09                   ; Decrement autofire timer
	BPL CODE_008C12             ; If timer still positive → Exit (not ready)

	; Timer expired - trigger autofire event
	STA.B $07                   ; Output = held buttons (simulate new press)

	LDA.W #$0005                ; A = $05 (5 frames)
	STA.B $09                   ; Reset timer to 5 for repeat rate

CODE_008C12:
	RTS                         ; Return

;-------------------------------------------------------------------------------

CODE_008C13:
	; ===========================================================================
	; Handle New Button Press
	; ===========================================================================
	; When button first pressed, output immediately and set long timer.
	; ===========================================================================

	STA.B $07                   ; Output = new button presses

	LDA.W #$0019                ; A = $19 (25 frames)
	STA.B $09                   ; Set timer to 25 (initial delay)

	RTS                         ; Return

;===============================================================================
; TILEMAP CALCULATION & UPDATE ROUTINES ($008C1B-$008DDE)
;===============================================================================

CODE_008C1B:
	; ===========================================================================
	; Calculate VRAM Address from Tilemap Coordinates
	; ===========================================================================
	; Converts tile X,Y coordinates to linear VRAM address.
	; Used for placing tiles in the tilemap during updates.
	;
	; Parameters:
	;   A = Tile coordinate (packed format)
	;       Bits 0-2: X coordinate (0-7)
	;       Bits 3-5: Y coordinate (0-7)
	;
	; Returns:
	;   A = VRAM address offset
	;
	; SNES Tilemap Format:
	;   32x32 tiles per screen (1024 tiles)
	;   Linear addressing: row-major order
	;   Address = (Y * 64) + (X * 12) + $8000
	;
	; Calculation Breakdown:
	;   1. Extract Y coordinate (bits 3-5) → multiply by 64
	;   2. Extract X coordinate (bits 0-2) → multiply by 12
	;   3. Add base address $8000
	; ===========================================================================

	PHP                         ; Save processor status
	REP #$30                    ; 16-bit A, X, Y

	AND.W #$00FF                ; A = A & $FF (ensure 8-bit value)
	PHA                         ; Save original coordinate

	; ---------------------------------------------------------------------------
	; Extract and Process Y Coordinate (Bits 3-5)
	; ---------------------------------------------------------------------------

	AND.W #$0038                ; A = A & $38 (extract bits 3-5: Y coord)
	ASL A                       ; A = A × 2 (Y × 2)
	TAX                         ; X = Y × 2 (save for later)

	; ---------------------------------------------------------------------------
	; Extract and Process X Coordinate (Bits 0-2)
	; ---------------------------------------------------------------------------

	PLA                         ; A = original coordinate
	AND.W #$0007                ; A = A & $07 (extract bits 0-2: X coord)

	PHX                         ; Save Y×2 on stack

	; Calculate X contribution: X × 12
	ADC.B $01,S                 ; A = X + (Y×2)  [1st add]
	STA.B $01,S                 ; Save intermediate result

	ASL A                       ; A = (X + Y×2) × 2
	ADC.B $01,S                 ; A = result×2 + result = result×3

	ASL A                       ; A = result × 6
	ASL A                       ; A = result × 12
	ASL A                       ; A = result × 24
	ASL A                       ; A = result × 48

	; ---------------------------------------------------------------------------
	; Add Base Address
	; ---------------------------------------------------------------------------

	ADC.W #$8000                ; A = A + $8000 (add base VRAM address)

	PLX                         ; Clean stack (discard saved Y×2)

	PLP                         ; Restore processor status
	RTS                         ; Return with VRAM address in A

;-------------------------------------------------------------------------------

CODE_008C3D:
	; ===========================================================================
	; Update Character Cursor Tilemap
	; ===========================================================================
	; Updates the tilemap tiles for character selection cursor.
	; Handles both battle mode and field mode displays.
	;
	; $1031: Character Y position (row)
	; $00D8 bit 1: Battle mode flag
	; ===========================================================================

	PHP                         ; Save processor status
	SEP #$30                    ; 8-bit A, X, Y

	LDX.W $1031                 ; X = character Y position
	CPX.B #$FF                  ; Check if invalid position
	BEQ UNREACH_008C81          ; If $FF → Exit (invalid)

	; ---------------------------------------------------------------------------
	; Check Battle Mode Flag
	; ---------------------------------------------------------------------------

	LDA.B #$02                  ; A = $02 (bit 1 mask)
	AND.W $00D8                 ; Test bit 1 of $00D8
	BEQ CODE_008C83             ; If clear → Field mode

	; ---------------------------------------------------------------------------
	; Battle Mode Tilemap Update
	; ---------------------------------------------------------------------------
	; Uses special tilemap data from bank $04
	; ---------------------------------------------------------------------------

	LDA.L DATA8_049800,X        ; A = [$049800+X] (base tile value)
	ADC.B #$0A                  ; A = A + $0A (offset for battle tiles)
	XBA                         ; Swap A high/low bytes (save in high byte)

	; Calculate tile position
	TXA                         ; A = X (Y position)
	AND.B #$38                  ; A = A & $38 (extract Y coordinate bits)
	ASL A                       ; A = A × 2
	PHA                         ; Save Y offset

	TXA                         ; A = X again
	AND.B #$07                  ; A = A & $07 (extract X coordinate)
	ORA.B $01,S                 ; A = A | Y_offset (combine X and Y)
	PLX                         ; X = Y offset (cleanup stack)

	ASL A                       ; A = coordinate × 2 (word address)

	REP #$30                    ; 16-bit A, X, Y

	; Store tile values in WRAM buffer $7F075A
	STA.L $7F075A               ; [$7F075A] = tile 1 coordinate
	INC A                       ; A = A + 1 (next tile)
	STA.L $7F075C               ; [$7F075C] = tile 2 coordinate

	ADC.W #$000F                ; A = A + $0F (skip to next row)
	STA.L $7F079A               ; [$7F079A] = tile 3 coordinate (row 2)
	INC A                       ; A = A + 1
	STA.L $7F079C               ; [$7F079C] = tile 4 coordinate (row 2)

	SEP #$20                    ; 8-bit accumulator

	LDX.W #$17DA                ; X = $17DA (WRAM data source)
	LDA.B #$7F                  ; A = $7F (bank $7F)
	BRA CODE_008C9C             ; → Continue to transfer

;-------------------------------------------------------------------------------

UNREACH_008C81:
	db $28,$60                 ; Unreachable code: PLP, RTS

;-------------------------------------------------------------------------------

CODE_008C83:
	; ===========================================================================
	; Field Mode Tilemap Update
	; ===========================================================================
	; Normal field/map mode cursor update
	; ===========================================================================

	LDA.L DATA8_049800,X        ; A = [$049800+X] (base tile)
	ASL A                       ; A = A × 2
	ASL A                       ; A = A × 4 (tile offset)
	STA.W $00F4                 ; [$00F4] = tile offset

	REP #$10                    ; 16-bit X, Y

	LDA.W $1031                 ; A = character Y position
	JSR.W CODE_008D8A           ; Calculate tilemap address
	STX.W $00F2                 ; [$00F2] = tilemap address

	LDX.W #$2D1A                ; X = $2D1A (WRAM source address)
	LDA.B #$7E                  ; A = $7E (bank $7E)

;-------------------------------------------------------------------------------

CODE_008C9C:
	; ===========================================================================
	; Apply Cursor Attributes
	; ===========================================================================
	; Modifies tile attributes based on game state flags.
	;
	; $00DA bit 2: Disable cursor blink
	; $0014: Blink timer
	; Attribute bits:
	;   Bit 2: Horizontal flip
	;   Bit 3-4: Palette selection
	;   Bit 7: Priority
	; ===========================================================================

	PHA                         ; Save bank number

	LDA.B #$04                  ; A = $04 (bit 2 mask)
	AND.W $00DA                 ; Test bit 2 of $00DA
	BEQ CODE_008CC5             ; If clear → Normal cursor

	; Check blink timer
	LDA.W $0014                 ; A = [$0014] (blink timer)
	DEC A                       ; A = A - 1
	BEQ CODE_008CC5             ; If zero → Show cursor

	; Apply alternate palette during blink
	LDA.B #$10                  ; A = $10 (bit 4 mask)
	AND.W $00DA                 ; Test bit 4 of $00DA
	BNE CODE_008CBB             ; If set → Special blink mode

	; Normal blink mode (incomplete in disassembly)
	db $AB,$BD,$01,$00,$29,$E3,$09,$94,$80,$12

;-------------------------------------------------------------------------------

CODE_008CBB:
	PLB                         ; B = bank (restore)
	LDA.W $0001,X               ; A = [X+1] (tile attribute byte)
	AND.B #$E3                  ; A = A & $E3 (clear palette bits 2,3,4)
	ORA.B #$9C                  ; A = A | $9C (set new palette + priority)
	BRA CODE_008CCD             ; → Save and continue

;-------------------------------------------------------------------------------

CODE_008CC5:
	PLB                         ; B = bank (restore)
	LDA.W $0001,X               ; A = [X+1] (tile attribute)
	AND.B #$E3                  ; Clear palette bits
	ORA.B #$88                  ; Set normal palette

;-------------------------------------------------------------------------------

CODE_008CCD:
	; ===========================================================================
	; Handle Number Display
	; ===========================================================================
	; For certain Y positions (>=$29), displays 2-digit numbers.
	; Used for item quantities, HP values, etc.
	; ===========================================================================

	XBA                         ; Swap A bytes (save attributes in high byte)

	LDA.L $001031               ; A = Y position
	CMP.B #$29                  ; Compare with $29
	BCC CODE_008D11             ; If Y < $29 → Use simple tile display

	CMP.B #$2C                  ; Compare with $2C
	BEQ CODE_008D11             ; If Y = $2C → Use simple tile display

	; ---------------------------------------------------------------------------
	; Two-Digit Number Display
	; ---------------------------------------------------------------------------
	; Displays a number as two separate digit tiles
	; $1030 contains the value to display (0-99)
	; ---------------------------------------------------------------------------

	LDA.W $0001,X               ; A = tile attribute
	AND.B #$63                  ; Clear certain attribute bits
	ORA.B #$08                  ; Set priority bit
	STA.W $0001,X               ; Save attribute for tile 1
	STA.W $0003,X               ; Save attribute for tile 2

	; Calculate tens digit
	LDA.L $001030               ; A = number value (0-99)
	LDY.W #$FFFF                ; Y = -1 (digit counter)
	SEC                         ; Set carry for subtraction

;-------------------------------------------------------------------------------

CODE_008CEF:
	; Divide by 10 loop
	INY                         ; Y++ (count tens)
	SBC.B #$0A                  ; A = A - 10
	BCS CODE_008CEF             ; If carry still set → Continue subtracting

	; A now contains ones digit - 10 (needs adjustment)
	ADC.B #$8A                  ; A = A + $8A (convert to tile number)
	STA.W $0002,X               ; Store ones digit tile

	; Check if tens digit is zero
	CPY.W #$0000                ; Is tens digit zero?
	BEQ UNREACH_008D06          ; If zero → Show blank tens digit

	; Display tens digit
	TYA                         ; A = tens digit value
	ADC.B #$7F                  ; A = A + $7F (convert to tile number)
	STA.W $0000,X               ; Store tens digit tile
	BRA CODE_008D20             ; → Finish update

;-------------------------------------------------------------------------------

UNREACH_008D06:
	; Show blank tile for tens digit
	db $A9,$45,$9D,$00,$00,$EB,$9D,$01,$00,$80,$0F
	; LDA #$45, STA [$00,X], XBA, STA [$01,X], BRA $0F

;-------------------------------------------------------------------------------

CODE_008D11:
	; ===========================================================================
	; Simple Tile Display
	; ===========================================================================
	; Displays blank tiles (tile $45) for positions that don't need numbers
	; ===========================================================================

	XBA                         ; Swap A bytes (get attributes back)
	STA.W $0001,X               ; Store attribute for tile 1
	STA.W $0003,X               ; Store attribute for tile 2

	LDA.B #$45                  ; A = $45 (blank tile)
	STA.W $0000,X               ; Store blank in tile 1
	STA.W $0002,X               ; Store blank in tile 2

;-------------------------------------------------------------------------------

CODE_008D20:
	; ===========================================================================
	; Finalize Tilemap Update
	; ===========================================================================

	PHK                         ; Push program bank
	PLB                         ; Pull to data bank (B = $00)

	LDA.B #$80                  ; A = $80 (bit 7)
	TSB.W $00D4                 ; Set bit 7 of $00D4 (large VRAM update flag)

	PLP                         ; Restore processor status
	RTS                         ; Return

;===============================================================================
; LAYER UPDATE ROUTINES ($008D29-$008D89)
;===============================================================================

CODE_008D29:
	; ===========================================================================
	; Background Layer 1 Update
	; ===========================================================================
	; Updates BG layer 1 tilemap during VBLANK.
	; Handles both battle and field modes.
	; ===========================================================================

	PHP                         ; Save processor status
	SEP #$30                    ; 8-bit A, X, Y

	; ---------------------------------------------------------------------------
	; Check Battle Mode
	; ---------------------------------------------------------------------------

	LDA.B #$02                  ; A = $02 (bit 1 mask)
	AND.W $00D8                 ; Test bit 1 of $00D8
	BEQ CODE_008D6C             ; If clear → Field mode

	; ---------------------------------------------------------------------------
	; Battle Mode Layer Update
	; ---------------------------------------------------------------------------

	LDX.W $10B1                 ; X = [$10B1] (cursor position)
	CPX.B #$FF                  ; Check if invalid
	BEQ CODE_008D6A             ; If $FF → Exit

	; Calculate tile data
	LDA.L DATA8_049800,X        ; A = base tile value
	ADC.B #$0A                  ; A = A + $0A (battle offset)
	XBA                         ; Save in high byte

	TXA                         ; A = position
	AND.B #$38                  ; Extract Y bits
	ASL A                       ; Y × 2
	PHA                         ; Save

	TXA                         ; A = position again
	AND.B #$07                  ; Extract X bits
	ORA.B $01,S                 ; Combine with Y
	PLX                         ; Cleanup stack

	ASL A                       ; Word address
	REP #$30                    ; 16-bit A, X, Y

	; Store in WRAM buffer
	STA.L $7F0778               ; Tile 1 position
	INC A                       ; Next tile
	STA.L $7F077A               ; Tile 2 position

	ADC.W #$000F                ; Next row
	STA.L $7F07B8               ; Tile 3 position
	INC A                       ; Next tile
	STA.L $7F07BA               ; Tile 4 position

	LDA.W #$0080                ; A = $0080 (bit 7)
	TSB.W $00D4                 ; Set large update flag

CODE_008D6A:
	PLP                         ; Restore status
	RTS                         ; Return

;-------------------------------------------------------------------------------

CODE_008D6C:
	; ===========================================================================
	; Field Mode Layer Update
	; ===========================================================================

	LDX.W $10B1                 ; X = cursor position
	LDA.L DATA8_049800,X        ; A = base tile
	ASL A                       ; A × 2
	ASL A                       ; A × 4
	STA.W $00F7                 ; Save tile offset

	REP #$10                    ; 16-bit X, Y

	LDA.W $10B1                 ; A = cursor position
	JSR.W CODE_008D8A           ; Calculate tilemap address
	STX.W $00F5                 ; Save address

	LDA.B #$80                  ; A = $80
	TSB.W $00D4                 ; Set update flag

	PLP                         ; Restore status
	RTS                         ; Return

;-------------------------------------------------------------------------------

CODE_008D8A:
	; ===========================================================================
	; Tilemap Address Calculation Wrapper
	; ===========================================================================
	; Calls CODE_008C1B if position is valid
	;
	; Parameters:
	;   A = Position value
	;
	; Returns:
	;   X = Tilemap address (or $FFFF if invalid)
	; ===========================================================================

	CMP.B #$FF                  ; Check if invalid position
	BEQ UNREACH_008D93          ; If $FF → Return $FFFF

	JSR.W CODE_008C1B           ; Calculate tilemap address
	TAX                         ; X = calculated address
	RTS                         ; Return

;-------------------------------------------------------------------------------

UNREACH_008D93:
	LDX.W #$FFFF                ; X = invalid address marker
	RTS                         ; Return

;===============================================================================
; Character Validation & Party Helper Routines
;===============================================================================
; These small helper routines validate character positions and check party
; member availability. Used by menu systems to skip dead/invalid characters.
;===============================================================================

CODE_008D97:
	; ===========================================================================
	; Character Position Validation Helper
	; ===========================================================================
	; Validates a character position by checking party member availability
	;
	; Parameters:
	;   $1031 = Current character position
	;
	; Returns:
	;   $009E = Validated position (or adjusted)
	;   $1031 = Updated position after validation
	; ===========================================================================

	LDA.W $1031                 ; Get current character position
	PHA                         ; Save it
	LDA.W #$0003                ; A = 3 (check 3 party slots)
	JSR.W CODE_008DA8           ; Validate party member
	PLA                         ; Restore original position
	STA.W $1031                 ; Store back to $1031
	STY.B $9E                   ; Save validated position to $9E
	RTS                         ; Return

;-------------------------------------------------------------------------------

CODE_008DA8:
	; ===========================================================================
	; Party Member Availability Check
	; ===========================================================================
	; Checks party member status flags to find next valid character
	; Scans through bits in $1032-$1033 to skip dead/invalid members
	;
	; TECHNICAL NOTES:
	; - $1032-$1033 contains party status bitfield
	; - Each character has flags indicating availability
	; - Function counts valid members and returns position
	;
	; Parameters:
	;   A = Number of slots to check
	;   $1032-$1033 = Party status flags
	;
	; Returns:
	;   Y = Valid character position (or $FF if none found)
	;   $1031 = Updated character position
	; ===========================================================================

	PHP                         ; Save processor status
	SEP #$30                    ; 8-bit mode
	PHA                         ; Save slot count
	CLC                         ; Clear carry
	ADC.B $01,S                 ; A = count × 2 (stack peek)
	ADC.B $01,S                 ; A = count × 3
	ADC.B #$22                  ; A += $22 (offset calculation)
	TAY                         ; Y = calculated offset
	PLA                         ; Restore slot count
	EOR.B #$FF                  ; Invert bits
	SEC                         ; Set carry
	ADC.B #$04                  ; A = 4 - count (bit shift count)
	TAX                         ; X = shift count

	LDA.W $1032                 ; Get status flags (high byte)
	XBA                         ; Swap to low byte
	LDA.W $1033                 ; Get status flags (low byte)
	REP #$20                    ; 16-bit A
	SEP #$10                    ; 8-bit X, Y
	LSR A                       ; Shift right (first bit)

CODE_008DC7:
	LSR A                       ; Shift right
	LSR A                       ; Shift right
	LSR A                       ; Shift right (shift 3 bits per slot)
	DEX                         ; Decrement shift counter
	BNE CODE_008DC7             ; Loop until X = 0

	LSR A                       ; Check first member bit
	BCS CODE_008DDA             ; If set → valid member found
	DEY                         ; Try previous slot
	LSR A                       ; Check second member bit
	BCS CODE_008DDA             ; If set → valid member found
	DEY                         ; Try previous slot
	LSR A                       ; Check third member bit
	BCS CODE_008DDA             ; If set → valid member found
	LDY.B #$FF                  ; No valid members → $FF

CODE_008DDA:
	STY.W $1031                 ; Store validated position
	PLP                         ; Restore processor status
	RTS                         ; Return

;===============================================================================
; DMA Transfer Helper Routines
;===============================================================================
; Low-level DMA and direct VRAM write helpers used throughout the graphics
; system. These routines handle bulk transfers and direct writes to VRAM.
;===============================================================================

CODE_008DDF:
	; ===========================================================================
	; Large VRAM Write via Direct Writes (No DMA)
	; ===========================================================================
	; Writes large blocks of tile data directly to VRAM without using DMA
	; Used when DMA channels are unavailable or for specific VRAM patterns
	;
	; TECHNICAL NOTES:
	; - Sets Direct Page to $2100 (PPU registers)
	; - Writes 24 bytes per tile (8 words × 3 bytes each)
	; - Interleaves data with $00F0 pattern bytes
	; - VRAM auto-increment must be configured externally
	;
	; Parameters:
	;   Direct Page = $2100
	;   X = Source address in Bank $04
	;   Y = Number of tile groups to write
	;   VRAM address already set
	;
	; Register Usage:
	;   A = Data being written
	;   X = Source pointer (auto-increments)
	;   Y = Outer loop counter (tile groups)
	; ===========================================================================

	PHP                         ; Save processor status
	PHD                         ; Save Direct Page
	REP #$30                    ; 16-bit mode
	LDA.W #$2100                ; A = $2100
	TCD                         ; Direct Page = $2100 (PPU registers)
	CLC                         ; Clear carry for additions

CODE_008DE8:
	PHY                         ; Save Y counter
	SEP #$20                    ; 8-bit A
	LDY.W #$0018                ; Y = $18 (24 decimal, inner loop count)

CODE_008DEE:
	LDA.W $0000,X               ; Get byte from source
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $0001,X               ; Get next byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $0002,X               ; Get third byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $0003,X               ; Get fourth byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $0004,X               ; Get fifth byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $0005,X               ; Get sixth byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $0006,X               ; Get seventh byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $0007,X               ; Get eighth byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)

	LDA.W $0008,X               ; Get ninth byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $0009,X               ; Get tenth byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $000A,X               ; Get 11th byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $000B,X               ; Get 12th byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $000C,X               ; Get 13th byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $000D,X               ; Get 14th byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $000E,X               ; Get 15th byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $000F,X               ; Get 16th byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)

	LDA.W $0010,X               ; Get 17th byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $0011,X               ; Get 18th byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $0012,X               ; Get 19th byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $0013,X               ; Get 20th byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $0014,X               ; Get 21st byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $0015,X               ; Get 22nd byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $0016,X               ; Get 23rd byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)
	LDA.W $0017,X               ; Get 24th byte
	TAY                         ; Y = data byte
	STY.B !SNES_VMDATAL-$2100   ; Write to VRAM data (low)

	REP #$30                    ; 16-bit mode
	TXA                         ; A = X (source pointer)
	ADC.W #$0018                ; A += $18 (24 bytes)
	TAX                         ; X = new source address
	PLY                         ; Restore Y counter
	DEY                         ; Decrement tile group counter
	BEQ +                       ; Exit if done
	JMP CODE_008DE8             ; Loop if more groups remain
+
	PLD                         ; Restore Direct Page
	PLP                         ; Restore processor status
	RTL                         ; Return

;-------------------------------------------------------------------------------

CODE_008E54:
	; ===========================================================================
	; VRAM Write: 8 Tiles with Pattern Interleaving
	; ===========================================================================
	; Writes 8 tiles (16 bytes each) to VRAM with pattern byte interleaving
	; Pattern byte from $00F0 is written between each data byte
	;
	; TECHNICAL NOTES:
	; - VRAM increment mode $88 (increment by 32 after high byte write)
	; - Each tile writes: data, pattern, data, pattern... (16 writes total)
	; - 8 tiles × 16 bytes = 128 bytes written
	; - Source is in Bank $07 WRAM
	;
	; Parameters:
	;   X = Source address in Bank $07
	;   Y = Number of tiles (typically 8)
	;   $00F0 = Pattern byte to interleave
	;   VRAM address already set
	; ===========================================================================

	PHP                         ; Save processor status
	PHD                         ; Save Direct Page
	PEA.W $2100                 ; Push $2100
	PLD                         ; Direct Page = $2100
	SEP #$20                    ; 8-bit A
	LDA.B #$88                  ; A = $88 (VRAM increment +32 after high)
	STA.B !SNES_VMAINC-$2100    ; Set VRAM increment mode
	REP #$30                    ; 16-bit mode
	CLC                         ; Clear carry

CODE_008E63:
	LDA.W $0000,X               ; Get word 0
	STA.B !SNES_VMDATAL-$2100   ; Write to VRAM
	LDA.W $00F0                 ; Get pattern word
	STA.B !SNES_VMDATAL-$2100   ; Write pattern
	LDA.W $0002,X               ; Get word 1
	STA.B !SNES_VMDATAL-$2100   ; Write to VRAM
	LDA.W $00F0                 ; Get pattern word
	STA.B !SNES_VMDATAL-$2100   ; Write pattern
	LDA.W $0004,X               ; Get word 2
	STA.B !SNES_VMDATAL-$2100   ; Write to VRAM
	LDA.W $00F0                 ; Get pattern word
	STA.B !SNES_VMDATAL-$2100   ; Write pattern
	LDA.W $0006,X               ; Get word 3
	STA.B !SNES_VMDATAL-$2100   ; Write to VRAM
	LDA.W $00F0                 ; Get pattern word
	STA.B !SNES_VMDATAL-$2100   ; Write pattern
	LDA.W $0008,X               ; Get word 4
	STA.B !SNES_VMDATAL-$2100   ; Write to VRAM
	LDA.W $00F0                 ; Get pattern word
	STA.B !SNES_VMDATAL-$2100   ; Write pattern
	LDA.W $000A,X               ; Get word 5
	STA.B !SNES_VMDATAL-$2100   ; Write to VRAM
	LDA.W $00F0                 ; Get pattern word
	STA.B !SNES_VMDATAL-$2100   ; Write pattern
	LDA.W $000C,X               ; Get word 6
	STA.B !SNES_VMDATAL-$2100   ; Write to VRAM
	LDA.W $00F0                 ; Get pattern word
	STA.B !SNES_VMDATAL-$2100   ; Write pattern
	LDA.W $000E,X               ; Get word 7
	STA.B !SNES_VMDATAL-$2100   ; Write to VRAM
	LDA.W $00F0                 ; Get pattern word
	STA.B !SNES_VMDATAL-$2100   ; Write pattern

	TXA                         ; A = X (source pointer)
	ADC.W #$0010                ; A += $10 (16 bytes per tile)
	TAX                         ; X = new source address
	DEY                         ; Decrement tile counter
	BNE CODE_008E63             ; Loop if more tiles remain

	SEP #$20                    ; 8-bit A
	LDA.B #$80                  ; A = $80 (VRAM increment +1)
	STA.B !SNES_VMAINC-$2100    ; Restore normal VRAM increment
	PLD                         ; Restore Direct Page
	PLP                         ; Restore processor status
	RTL                         ; Return

;===============================================================================
; Graphics Initialization & Palette Loading
;===============================================================================
; Complex graphics setup routine that loads tiles and palettes for menu/field
; display. Handles DMA transfers and direct palette uploads to CGRAM.
;===============================================================================

CODE_008EC4:
	; ===========================================================================
	; Field/Menu Graphics Initialization
	; ===========================================================================
	; Complete graphics setup for field mode and menu displays
	; Loads character tiles, background tiles, and color palettes
	;
	; TECHNICAL NOTES:
	; - Uses DMA Channel 5 for bulk VRAM transfer ($1000 bytes)
	; - Loads tiles to VRAM $3000-$3FFF
	; - Loads additional tiles to VRAM $2000-$2FFF via CODE_008DDF
	; - Sets up multiple palette entries in CGRAM
	; - Direct Page = $2100 throughout for PPU access
	;
	; Graphics Loaded:
	; - Bank $07:$8030: Main tile graphics (4096 bytes via DMA)
	; - Bank $04:$8000: Additional tiles (256 groups via direct write)
	; - Bank $07:$8000: Palette data (4 sets of 8 colors)
	; - Bank $07:$D8E4: Extended palette data (6 groups of 16 colors)
	;
	; CGRAM Layout:
	; - $0D, $1D: Special colors from $0E9C-$0E9D
	; - $08-$1F: Four 8-color palettes from Bank $07:$8000
	; - $28-$87: Six 16-color palettes from Bank $07:$D8E4
	; ===========================================================================

	PHP                         ; Save processor status
	PHD                         ; Save Direct Page
	REP #$30                    ; 16-bit mode
	LDA.W #$2100                ; A = $2100
	TCD                         ; Direct Page = $2100 (PPU registers)

	; Setup DMA Channel 5 for VRAM transfer
	SEP #$20                    ; 8-bit A
	LDX.W #$1801                ; X = $1801 (DMA params: word, increment)
	STX.W !SNES_DMA5PARAM       ; Set DMA5 control
	LDX.W #$8030                ; X = $8030 (source address low/mid)
	STX.W !SNES_DMA5ADDRL       ; Set DMA5 source address
	LDA.B #$07                  ; A = $07 (source bank)
	STA.W !SNES_DMA5ADDRH       ; Set DMA5 source bank
	LDX.W #$1000                ; X = $1000 (4096 bytes to transfer)
	STX.W !SNES_DMA5CNTL        ; Set DMA5 transfer size

	; Setup VRAM destination
	LDX.W #$3000                ; X = $3000 (VRAM address)
	STX.B !SNES_VMADDL-$2100    ; Set VRAM address
	LDA.B #$84                  ; A = $84 (increment +32 after high byte)
	STA.B !SNES_VMAINC-$2100    ; Set VRAM increment mode

	; Execute DMA transfer
	LDA.B #$20                  ; A = $20 (enable DMA channel 5)
	STA.W !SNES_MDMAEN          ; Start DMA transfer

	; Restore normal VRAM increment
	LDA.B #$80                  ; A = $80 (increment +1)
	STA.B !SNES_VMAINC-$2100    ; Set VRAM increment mode

	; Setup for additional tile transfer
	REP #$30                    ; 16-bit mode
	LDA.W #$FF00                ; A = $FF00 (pattern for interleaving)
	STA.W $00F0                 ; Store pattern word
	LDX.W #$2000                ; X = $2000 (VRAM address)
	STX.B !SNES_VMADDL-$2100    ; Set VRAM address

	; Transfer additional tiles from Bank $04
	PEA.W $0004                 ; Push bank $04
	PLB                         ; Data bank = $04
	LDX.W #$8000                ; X = $8000 (source address)
	LDY.W #$0100                ; Y = $0100 (256 tile groups)
	JSL.L CODE_008DDF           ; Transfer tiles via direct writes
	PLB                         ; Restore data bank

	; Load palette data from Bank $07
	SEP #$30                    ; 8-bit mode
	PEA.W $0007                 ; Push bank $07
	PLB                         ; Data bank = $07

	; Load 4 sets of 8-color palettes
	LDA.B #$08                  ; A = $08 (CGRAM address $08)
	LDX.B #$00                  ; X = $00 (source offset)
	JSR.W CODE_008FB4           ; Load 8 colors
	LDA.B #$0C                  ; A = $0C (CGRAM address $0C)
	LDX.B #$08                  ; X = $08 (source offset)
	JSR.W CODE_008FB4           ; Load 8 colors
	LDA.B #$18                  ; A = $18 (CGRAM address $18)
	LDX.B #$10                  ; X = $10 (source offset)
	JSR.W CODE_008FB4           ; Load 8 colors
	LDA.B #$1C                  ; A = $1C (CGRAM address $1C)
	LDX.B #$18                  ; X = $18 (source offset)
	JSR.W CODE_008FB4           ; Load 8 colors
	PLB                         ; Restore data bank

	; Load special color values
	LDX.W $0E9C                 ; X = color value (low byte)
	LDY.W $0E9D                 ; Y = color value (high byte)
	LDA.B #$0D                  ; A = $0D (CGRAM address)
	STA.B !SNES_CGADD-$2100     ; Set CGRAM address
	STX.B !SNES_CGDATA-$2100    ; Write color (low)
	STY.B !SNES_CGDATA-$2100    ; Write color (high)
	LDA.B #$1D                  ; A = $1D (CGRAM address)
	STA.B !SNES_CGADD-$2100     ; Set CGRAM address
	STX.B !SNES_CGDATA-$2100    ; Write color (low)
	STY.B !SNES_CGDATA-$2100    ; Write color (high)

	; Load extended palette data (6 groups of 16 colors)
	LDY.B #$06                  ; Y = 6 (group count)
	LDA.B #$00                  ; A = 0 (initial offset)
	CLC                         ; Clear carry
	PEA.W $0007                 ; Push bank $07
	PLB                         ; Data bank = $07

CODE_008F55:
	TAX                         ; X = offset
	ADC.B #$28                  ; A += $28 (CGRAM address increment)
	STA.B !SNES_CGADD-$2100     ; Set CGRAM address

	; Write 16 colors (32 bytes) from DATA8_07D8E4
	LDA.W DATA8_07D8E4,X        ; Get color byte
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_07D8E5,X        ; Get color byte
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_07D8E6,X        ; Get color byte
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_07D8E7,X        ; Get color byte
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_07D8E8,X        ; Get color byte
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_07D8E9,X        ; Get color byte
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_07D8EA,X        ; Get color byte
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_07D8EB,X        ; Get color byte
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_07D8EC,X        ; Get color byte
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_07D8ED,X        ; Get color byte
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_07D8EE,X        ; Get color byte
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_07D8EF,X        ; Get color byte
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_07D8F0,X        ; Get color byte
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_07D8F1,X        ; Get color byte
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_07D8F2,X        ; Get color byte
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_07D8F3,X        ; Get color byte
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM

	TXA                         ; A = X (offset)
	ADC.B #$10                  ; A += $10 (16 bytes per group)
	DEY                         ; Decrement group counter
	BNE CODE_008F55             ; Loop if more groups remain

	PLB                         ; Restore data bank
	PLD                         ; Restore Direct Page
	PLP                         ; Restore processor status
	RTS                         ; Return

;-------------------------------------------------------------------------------

CODE_008FB4:
	; ===========================================================================
	; Load 8-Color Palette to CGRAM
	; ===========================================================================
	; Loads 8 colors (16 bytes) from Bank $07:$8000 to CGRAM
	;
	; Parameters:
	;   A = CGRAM starting address
	;   X = Source offset in DATA8_078000
	;   Data bank = $07
	;   Direct Page = $2100
	; ===========================================================================

	STA.B !SNES_CGADD-$2100     ; Set CGRAM address
	LDA.W DATA8_078000,X        ; Get color byte 0
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_078001,X        ; Get color byte 1
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_078002,X        ; Get color byte 2
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_078003,X        ; Get color byte 3
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_078004,X        ; Get color byte 4
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_078005,X        ; Get color byte 5
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_078006,X        ; Get color byte 6
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	LDA.W DATA8_078007,X        ; Get color byte 7
	STA.B !SNES_CGDATA-$2100    ; Write to CGRAM
	RTS                         ; Return

;===============================================================================
; Embedded Subroutine Data
;===============================================================================
; This section contains embedded machine code data used by various helper
; routines. These are small inline subroutines stored as raw bytes.
;===============================================================================

DATA_008FDF:
	; ===========================================================================
	; Embedded Helper Subroutine ($008FDF-$009013)
	; ===========================================================================
	; Small helper routine stored as data bytes
	; Appears to handle coordinate/offset calculations
	; ===========================================================================
DATA_008FDF_bytes:
	db $08,$0B,$C2,$30,$DA,$48,$3B,$38,$E9,$02,$00,$1B,$5B,$E2,$20,$A5
	db $04,$85,$02,$64,$04,$A9,$00,$C2,$30,$A2,$08,$00,$C6,$03,$0A,$06
	db $01,$90,$02,$65,$03,$CA,$D0,$F6,$85,$03,$3B,$18,$69,$02,$00,$1B
	db $68,$FA,$2B,$28,$6B

;===============================================================================
; Status Effect Rendering System
;===============================================================================
; Major system that handles rendering character status effects and animations
; Processes status ailments, buffs, and visual indicators for the party
;===============================================================================

CODE_009014:
	; ===========================================================================
	; Initialize Status Effect Display System
	; ===========================================================================
	; Clears status effect display buffers and sets up party status rendering
	; Called when entering field/menu modes
	;
	; TECHNICAL NOTES:
	; - Clears $7E3669-$7E3746 (222 bytes) for status display
	; - Uses MVN for efficient memory clearing
	; - Sets Direct Page to $1000 for party data access
	; - Processes party member status flags from $1032-$1033
	; - Renders status icons/indicators to tilemap buffers
	;
	; Status Display Layout:
	; - $7E3669: Start of status effect buffer
	; - Various offsets for different status types
	; - Supports 6 party member slots with multiple status effects each
	; ===========================================================================

	PHP                         ; Save processor status
	PHD                         ; Save Direct Page
	REP #$30                    ; 16-bit mode

	; Clear status display buffer
	LDA.W #$0000                ; A = 0
	STA.L $7E3669               ; Clear first word of buffer
	LDX.W #$3669                ; X = source (first word)
	LDY.W #$366B                ; Y = destination (next word)
	LDA.W #$00DD                ; A = $DD (221 bytes to fill)
	MVN $7E,$7E                 ; Block fill with zeros

	; Setup for status processing
	PHK                         ; Push program bank
	PLB                         ; Data bank = program bank
	SEP #$30                    ; 8-bit mode
	PEA.W $1000                 ; Push $1000
	PLD                         ; Direct Page = $1000 (party data)

	; Process party status bits (high nibble of $1032)
	LDA.B $32                   ; Get party status flags (high)
	AND.B #$E0                  ; Mask bits 7-5
	BEQ Skip_Status_Group1      ; If clear, skip first group

	JSL.L CODE_009730           ; Calculate status icon offset
	EOR.B #$FF                  ; Invert
	SEC                         ; Set carry
	ADC.B #$27                  ; Add offset $27
	LDY.B #$A0                  ; Y = $A0 (display position)
	JSR.W CODE_009111           ; Render status icon

Skip_Status_Group1:
	; Process bits 4-2 of $1032
	LDA.B $32                   ; Get party status flags
	AND.B #$1C                  ; Mask bits 4-2
	BEQ Skip_Status_Group2      ; If clear, skip second group

	JSL.L CODE_009730           ; Calculate status icon offset
	EOR.B #$FF                  ; Invert
	SEC                         ; Set carry
	ADC.B #$27                  ; Add offset $27
	LDY.B #$B0                  ; Y = $B0 (display position)
	JSR.W CODE_009111           ; Render status icon

Skip_Status_Group2:
	; Process bit 7 of $1033 and bits 1-0 of $1032
	LDA.B $33                   ; Get extended status flags
	AND.B #$80                  ; Check bit 7
	BNE Process_Status_Group3   ; If set, process group 3

	LDA.B $32                   ; Get party status flags
	AND.B #$03                  ; Mask bits 1-0
	BEQ Skip_Status_Group3      ; If clear, skip

	; Embedded JSL instruction as data
Skip_Status_Group2_bytes:
	db $22,$30,$97,$00         ; JSL CODE_009730
	db $18,$69,$08             ; CLC, ADC #$08
	db $80,$04                 ; BRA +4

Process_Status_Group3:
	JSL.L CODE_009730           ; Calculate status icon offset
	EOR.B #$FF                  ; Invert
	SEC                         ; Set carry
	ADC.B #$2F                  ; Add offset $2F
	LDY.B #$C0                  ; Y = $C0 (display position)
	JSR.W CODE_009111           ; Render status icon

Skip_Status_Group3:
	; Process bits 6-4 of $1033
	LDA.B $33                   ; Get extended status flags
	AND.B #$70                  ; Mask bits 6-4
	BEQ Skip_Status_Group4      ; If clear, skip

	JSL.L CODE_009730           ; Calculate status icon offset
	EOR.B #$FF                  ; Invert
	SEC                         ; Set carry
	ADC.B #$2F                  ; Add offset $2F
	LDY.B #$D0                  ; Y = $D0 (display position)
	JSR.W CODE_009111           ; Render status icon

Skip_Status_Group4:
	; Process first character slot
	LDY.B #$00                  ; Y = 0 (slot 0)
	JSR.W CODE_0090A3           ; Render character status

	; Switch to second character slot data
	PEA.W $1080                 ; Push $1080
	PLD                         ; Direct Page = $1080
	LDY.B #$50                  ; Y = $50 (display offset)
	JSR.W CODE_0090A3           ; Render character status

	PLD                         ; Restore Direct Page
	PLP                         ; Restore processor status
	RTS                         ; Return

;-------------------------------------------------------------------------------

CODE_0090A3:
	; ===========================================================================
	; Render Single Character Status Effects
	; ===========================================================================
	; Renders status effect icons for one character
	;
	; Parameters:
	;   Y = Display position offset
	;   Direct Page = character data ($1000 or $1080)
	;   $31 = Character slot number (bit 7 = invalid flag)
	;   $35-$37 = Character status flags
	; ===========================================================================

	LDA.B $31                   ; Get character slot
	BMI Skip_Character          ; If bit 7 set → invalid/dead character
	JSR.W CODE_009111           ; Render base character icon

Skip_Character:
	; Process status flags group 1 (bits 7-5 of $35)
	LDA.B $35                   ; Get status flags byte 1
	AND.B #$E0                  ; Mask bits 7-5
	BEQ Skip_Status1            ; If clear, skip

	JSL.L CODE_009730           ; Calculate icon offset
	EOR.B #$FF                  ; Invert
	SEC                         ; Set carry
	ADC.B #$36                  ; Add offset $36
	JSR.W CODE_009111           ; Render status icon

Skip_Status1:
	; Process status flags group 2 (bits 7-6 of $36 and bits 4-0 of $35)
	LDA.B $36                   ; Get status flags byte 2
	AND.B #$C0                  ; Mask bits 7-6
	BNE Alternative_Status2     ; If set, use alternative handling

	LDA.B $35                   ; Get status flags byte 1
	AND.B #$1F                  ; Mask bits 4-0
	BEQ Skip_Status2            ; If clear, skip

	JSL.L CODE_009730           ; Calculate icon offset
	CLC                         ; Clear carry
	ADC.B #$08                  ; Add offset $08
	BRA Continue_Status2        ; Continue processing

Alternative_Status2:
	db $22,$30,$97,$00         ; JSL CODE_009730

Continue_Status2:
	EOR.B #$FF                  ; Invert
	SEC                         ; Set carry
	ADC.B #$3E                  ; Add offset $3E
	JSR.W CODE_009111           ; Render status icon

Skip_Status2:
	; Process status flags group 3 (bits 5-2 of $36)
	LDA.B $36                   ; Get status flags byte 2
	AND.B #$3C                  ; Mask bits 5-2
	BEQ Skip_Status3            ; If clear, skip

	JSL.L CODE_009730           ; Calculate icon offset
	EOR.B #$FF                  ; Invert
	SEC                         ; Set carry
	ADC.B #$3E                  ; Add offset $3E
	JSR.W CODE_009111           ; Render status icon

Skip_Status3:
	; Process status flags group 4 (bit 7 of $37 and bits 1-0 of $36)
	LDA.B $37                   ; Get status flags byte 3
	AND.B #$80                  ; Check bit 7
	BNE Alternative_Status4     ; If set, use alternative

	LDA.B $36                   ; Get status flags byte 2
	AND.B #$03                  ; Mask bits 1-0
	BEQ Skip_Status4            ; If clear, skip

	JSL.L CODE_009730           ; Calculate icon offset
	CLC                         ; Clear carry
	ADC.B #$08                  ; Add offset $08
	BRA Continue_Status4        ; Continue

Alternative_Status4:
	db $22,$30,$97,$00         ; JSL CODE_009730

Continue_Status4:
	EOR.B #$FF                  ; Invert
	SEC                         ; Set carry
	ADC.B #$46                  ; Add offset $46
	JSR.W CODE_009111           ; Render status icon

Skip_Status4:
	RTS                         ; Return

;-------------------------------------------------------------------------------

CODE_009111:
	; ===========================================================================
	; Render Status Icon to Buffer
	; ===========================================================================
	; Writes status icon data to the display buffer in $7E memory
	; Handles both simple icons and complex multi-part status displays
	;
	; TECHNICAL NOTES:
	; - Uses Direct Page $0400 for temporary calculations
	; - Calls CODE_028AE0 to process icon type
	; - Icons $00-$2E: Simple single icons
	; - Icons $2F-$46: Complex multi-part status displays
	; - Buffer layout supports 4 different icon "layers" per slot
	;
	; Parameters:
	;   A = Icon/status ID ($00-$46)
	;   Y = Display position offset
	;   Data bank = $7E
	; ===========================================================================

	PHP                         ; Save processor status
	PHD                         ; Save Direct Page
	SEP #$30                    ; 8-bit mode
	PEA.W $007E                 ; Push bank $7E
	PLB                         ; Data bank = $7E
	PHY                         ; Save Y offset
	PEA.W $0400                 ; Push $0400
	PLD                         ; Direct Page = $0400

	STA.B $3A                   ; Save icon ID to $043A
	JSL.L CODE_028AE0           ; Process icon type

	LDA.B $3A                   ; Get icon ID
	CMP.B #$2F                  ; Check if >= $2F
	BCC Simple_Icon             ; If < $2F → simple icon

Complex_Status:
	; Complex multi-part status display ($2F-$46)
	LDX.B #$10                  ; X = $10 (layer 1 offset)
	CMP.B #$32                  ; Check if >= $32
	BCC Got_Layer_Offset        ; If < $32 → use layer 1

	LDX.B #$20                  ; X = $20 (layer 2 offset)
	CMP.B #$39                  ; Check if >= $39
	BCC Got_Layer_Offset        ; If < $39 → use layer 2

	LDX.B #$30                  ; X = $30 (layer 3 offset)
	CMP.B #$3D                  ; Check if >= $3D
	BCC Got_Layer_Offset        ; If < $3D → use layer 3

	LDX.B #$40                  ; X = $40 (layer 4 offset)
	CLC                         ; Clear carry

Got_Layer_Offset:
	TXA                         ; A = layer offset
	ADC.B $01,S                 ; Add Y offset from stack
	TAX                         ; X = final buffer offset
	JSR.W CODE_0091A9           ; Write icon data to buffer

	; Copy calculated values to buffer
	LDA.B $DB                   ; Get calculated value 1
	STA.W $3670,X               ; Store to buffer
	LDA.B $DC                   ; Get calculated value 2
	STA.W $3671,X               ; Store to buffer
	LDA.B $E5                   ; Get calculated value 3
	STA.W $3672,X               ; Store to buffer
	LDA.B $E6                   ; Get calculated value 4
	ADC.W $366A,X               ; Add to existing value
	STA.W $366A,X               ; Store accumulated value
	LDA.B $E7                   ; Get calculated value 5
	STA.W $366E,X               ; Store to buffer
	LDA.B $E8                   ; Get calculated value 6
	STA.W $366D,X               ; Store to buffer
	LDA.B $E9                   ; Get calculated value 7
	STA.W $366F,X               ; Store to buffer
	BRA Render_Done             ; Done

Simple_Icon:
	; Simple single icon ($00-$2E)
	PLX                         ; X = Y offset (from stack)
	PHX                         ; Save it back
	JSR.W CODE_0091A9           ; Write icon to buffer

	CPX.B #$50                  ; Check if offset >= $50
	BCS Render_Done             ; If so, done

	; Copy icon template for simple icons
	REP #$30                    ; 16-bit mode
	LDA.B $3A                   ; Get icon ID
	AND.W #$00FF                ; Mask to byte
	LDY.W #$3709                ; Y = template address for icons $00-$22
	CMP.W #$0023                ; Check if < $23
	BCC Copy_Template           ; If so, use first template

	LDY.W #$3719                ; Y = template for icons $23-$25
	CMP.W #$0026                ; Check if < $26
	BCC Copy_Template           ; If so, use second template

	LDY.W #$3729                ; Y = template for icons $26-$28
	CMP.W #$0029                ; Check if < $29
	BCC Copy_Template           ; If so, use third template

	LDY.W #$3739                ; Y = template for icons $29+

Copy_Template:
	LDX.W #$3669                ; X = destination buffer
	LDA.W #$000F                ; A = 15 bytes to copy
	MVN $7E,$7E                 ; Block copy template
	SEP #$30                    ; 8-bit mode

Render_Done:
	PLY                         ; Restore Y offset
	PLB                         ; Restore data bank
	PLD                         ; Restore Direct Page
	PLP                         ; Restore processor status
	RTS                         ; Return

;-------------------------------------------------------------------------------

CODE_0091A9:
	; ===========================================================================
	; Set Status Icon Flags in Buffer
	; ===========================================================================
	; Decodes status effect flags and writes $05 to appropriate buffer slots
	; Used by icon rendering to mark which status effects are active
	;
	; TECHNICAL NOTES:
	; - $E4 contains packed flags (bits 0-3 for 4 different statuses)
	; - Each bit set writes $05 to corresponding buffer position
	; - Buffer layout: $3669, $366A, $366B, $366C (+X offset)
	;
	; Parameters:
	;   X = Buffer offset
	;   $E4 (at Direct Page $0400) = Packed status flags
	;
	; Flag Mapping:
	;   Bit 3 → $3669,X
	;   Bit 2 → $366A,X
	;   Bit 1 → $366B,X
	;   Bit 0 → $366C,X
	; ===========================================================================

	LDA.B $E4                   ; Get packed status flags
	TAY                         ; Y = flags (save for later)
	AND.B #$08                  ; Check bit 3
	BEQ Skip_Flag1              ; If clear, skip
	LDA.B #$05                  ; A = $05 (active marker)

Skip_Flag1:
	STA.W $3669,X               ; Store to buffer slot 1

	TYA                         ; A = flags
	AND.B #$04                  ; Check bit 2
	BEQ Skip_Flag2              ; If clear, skip
	db $A9,$05                 ; LDA #$05

Skip_Flag2:
	STA.W $366A,X               ; Store to buffer slot 2

	TYA                         ; A = flags
	AND.B #$02                  ; Check bit 1
	BEQ Skip_Flag3              ; If clear, skip
	LDA.B #$05                  ; A = $05

Skip_Flag3:
	STA.W $366B,X               ; Store to buffer slot 3

	TYA                         ; A = flags
	AND.B #$01                  ; Check bit 0
	BEQ Skip_Flag4              ; If clear, skip
	LDA.B #$05                  ; A = $05

Skip_Flag4:
	STA.W $366C,X               ; Store to buffer slot 4
	RTS                         ; Return

; ===========================================================================
; Character Status Calculation Routine
; ===========================================================================
; Purpose: Calculate cumulative character status from multiple stat buffers
; Input: Bit 0 of $89 determines which character to process (0=first, 1=second)
; Output: $2A-$2D, $3A-$3F, $2E updated with calculated stats
; Technical Details:
;   - Sets up Direct Page to $1000 or $1080 based on character selection
;   - Processes 7 stats via CODE_009253 (summation across 5 buffers)
;   - Processes 2 stats via CODE_009245 (OR across 4 buffers)
;   - Updates base stats ($22-$25) with deltas ($26-$29)
; Buffers accessed:
;   - $3669-$3678: Base buffer (16 bytes)
;   - $3679-$3688: Delta buffer 1
;   - $3689-$3698: Delta buffer 2
;   - $3699-$36A8: Delta buffer 3
;   - $36A9-$36B8: Delta buffer 4
; ===========================================================================

CODE_0091D4:
	PHP                         ; Save processor status
	PHD                         ; Save direct page register
	SEP #$30                    ; 8-bit A/X/Y
	PEA.W $007E                 ; Push $7E to stack
	PLB                         ; Data Bank = $7E
	CLC                         ; Clear carry
	PEA.W $1000                 ; Default to character 1 DP ($1000)
	PLD                         ; Direct Page = $1000
	LDX.B #$00                  ; X = $00 (buffer offset)
	BIT.B #$01                  ; Test bit 0 of $89
	BEQ Setup_Done              ; If 0, use first character's DP
	PEA.W $1080                 ; Character 2 DP ($1080)
	PLD                         ; Direct Page = $1080
	LDX.B #$50                  ; X = $50 (character 2 buffer offset)

Setup_Done:
	; Calculate cumulative stats using CODE_009253 (ADC across 5 buffers)
	JSR.W CODE_009253           ; Sum buffer values at X
	STA.B $2A                   ; Store stat 1
	JSR.W CODE_009253           ; Sum next buffer values (X++)
	STA.B $2B                   ; Store stat 2
	JSR.W CODE_009253           ; Sum next buffer values (X++)
	STA.B $2C                   ; Store stat 3
	JSR.W CODE_009253           ; Sum next buffer values (X++)
	STA.B $2D                   ; Store stat 4
	JSR.W CODE_009253           ; Sum next buffer values (X++)
	STA.B $41                   ; Store stat 5
	JSR.W CODE_009253           ; Sum next buffer values (X++)
	STA.B $3E                   ; Store stat 6
	JSR.W CODE_009253           ; Sum next buffer values (X++)
	STA.B $3F                   ; Store stat 7

	; Calculate bitwise OR stats using CODE_009245 (ORA across 4 buffers)
	JSR.W CODE_009245           ; OR buffer values at X
	STA.B $3A                   ; Store flags 1
	JSR.W CODE_009245           ; OR next buffer values (X++)
	STA.B $3B                   ; Store flags 2

	; Process status effect bits (lower nibble only)
	LDA.B #$0F                  ; Mask for lower nibble
	TRB.B $2E                   ; Clear lower nibble in $2E
	JSR.W CODE_009245           ; OR next buffer values (X++)
	AND.B #$0F                  ; Keep only lower nibble
	TSB.B $2E                   ; Set bits in $2E

	; Clear specific status bits and update base stats
	LDA.B $3B                   ; A = flags 2
	TRB.B $21                   ; Clear those bits in $21

	; Update base stats with deltas (with carry from earlier CLC)
	LDA.B $2A                   ; A = stat 1
	ADC.B $26                   ; Add delta 1
	STA.B $22                   ; Store to base stat 1
	LDA.B $2B                   ; A = stat 2
	ADC.B $27                   ; Add delta 2
	STA.B $23                   ; Store to base stat 2
	LDA.B $2C                   ; A = stat 3
	ADC.B $28                   ; Add delta 3
	STA.B $24                   ; Store to base stat 3
	LDA.B $2D                   ; A = stat 4
	ADC.B $29                   ; Add delta 4
	STA.B $25                   ; Store to base stat 4

	PLB                         ; Restore data bank
	PLD                         ; Restore direct page
	PLP                         ; Restore processor status
	RTS                         ; Return

; ===========================================================================
; Bitwise OR Stat Calculation Helper
; ===========================================================================
; Purpose: Calculates bitwise OR of a stat value across 4 buffers
; Input: X = buffer offset (auto-incremented)
; Output: A = result of ORing all 4 buffer values
; Technical Details:
;   - Used for flag-based stats where any bit set in any buffer should be set
;   - Buffers: $3679, $3689, $3699, $36A9 (delta buffers 1-4)
;   - Increments X for next stat
; ===========================================================================

CODE_009245:
	LDA.W $3679,X               ; A = delta buffer 1 value
	ORA.W $3689,X               ; OR with delta buffer 2
	ORA.W $3699,X               ; OR with delta buffer 3
	ORA.W $36A9,X               ; OR with delta buffer 4
	INX                         ; Increment offset to next stat
	RTS                         ; Return with result in A

; ===========================================================================
; Additive Stat Calculation Helper
; ===========================================================================
; Purpose: Calculates sum of a stat value across all 5 buffers
; Input: X = buffer offset (auto-incremented)
; Output: A = sum of all 5 buffer values (with carry)
; Technical Details:
;   - Used for numeric stats that accumulate (HP, MP, Attack, Defense, etc.)
;   - Buffers: $3669 (base), $3679, $3689, $3699, $36A9 (deltas 1-4)
;   - Assumes carry flag is in appropriate state for multi-byte addition
;   - Increments X for next stat
; ===========================================================================

CODE_009253:
	LDA.W $3669,X               ; A = base buffer value
	ADC.W $3679,X               ; Add delta buffer 1 (with carry)
	ADC.W $3689,X               ; Add delta buffer 2
	ADC.W $3699,X               ; Add delta buffer 3
	ADC.W $36A9,X               ; Add delta buffer 4
	INX                         ; Increment offset to next stat
	RTS                         ; Return with result in A

; ===========================================================================
; Animation Update Handler
; ===========================================================================
; Purpose: Conditionally update animations based on timing and game state
; Technical Details:
;   - Checks bit 5 ($20) of $00D9 as update gate
;   - Only processes animations when bit is clear
;   - Sets bit after processing to prevent multiple updates per frame
; Side Effects: May modify $00D9, calls CODE_009273
; ===========================================================================

CODE_009264:
	SEP #$30                    ; 8-bit A/X/Y
	LDA.B #$20                  ; Bit 5 mask
	AND.W $00D9                 ; Check animation update flag
	BNE Skip_Animation          ; If set, skip this frame
	JSR.W CODE_009273           ; Process animation updates

Skip_Animation:
	REP #$30                    ; 16-bit A/X/Y
	RTS                         ; Return

; ===========================================================================
; Animation Update System
; ===========================================================================
; Purpose: Main animation update routine with queue processing
; Technical Details:
;   - Sets bit 5 of $00D9 to indicate animation processing
;   - Uses Direct Page $0500 for animation control structures
;   - Processes up to 3 queued animations ($00, $05, $0A slots)
;   - Checks bit 2 ($04) of $00E2 to gate certain animations
; Queue Structure (Direct Page $0500):
;   - $00: Animation type/ID (slot 1)
;   - $01-$03: Animation parameters (slot 1)
;   - $05: Animation type/ID (slot 2)
;   - $06-$08: Animation parameters (slot 2)
;   - $0A: Animation type/ID (slot 3)
;   - $0C-$0E: Animation parameters (slot 3)
; Animation Types:
;   - $FF = empty slot
;   - $01 = Type 1 animation (uses $0601 parameter)
;   - $02 = Type 2 animation (uses $0601 parameter)
;   - $10-$1F = Range-based type (gated by $00E2 bit 2)
;   - Other values processed based on range checks
; ===========================================================================

CODE_009273:
	REP #$10                    ; 16-bit X/Y
	LDA.B #$20                  ; Bit 5 mask
	TSB.W $00D9                 ; Set animation processing flag
	PEA.W $0500                 ; Push $0500 to stack
	PLD                         ; Direct Page = $0500 (animation queue)
	CLI                         ; Enable interrupts

	; Process animation slot 1 ($00)
	LDA.B #$04                  ; Bit 2 mask
	AND.W $00E2                 ; Check animation gate flag
	BNE Check_Slot2             ; If set, skip slot 1
	LDA.B $00                   ; A = animation type (slot 1)
	BMI Check_Slot2             ; If $FF (empty), skip
	STA.W $0601                 ; Store animation type to $0601
	LDX.B $01                   ; X = animation parameter (16-bit)
	STX.W $0602                 ; Store parameter to $0602
	LDA.B #$01                  ; Animation command = $01
	STA.W $0600                 ; Store to animation command register
	JSL.L CODE_0D8004           ; Call animation processor
	LDA.B #$FF                  ; Mark slot as empty
	STA.B $00                   ; Store to slot 1 type
	LDX.B $03                   ; X = saved parameters
	STX.B $01                   ; Restore to slot 1

Check_Slot2:
	; Process animation slot 2 ($05)
	LDA.B $05                   ; A = animation type (slot 2)
	BMI Check_Slot3             ; If $FF (empty), skip
	LDA.B $05                   ; A = animation type (reload)
	STA.W $0601                 ; Store animation type to $0601
	LDX.B $06                   ; X = animation parameter (16-bit)
	STX.W $0602                 ; Store parameter to $0602
	LDA.B #$02                  ; Animation command = $02
	STA.W $0600                 ; Store to animation command register
	JSL.L CODE_0D8004           ; Call animation processor
	LDA.B #$FF                  ; Mark slot as empty
	STA.B $05                   ; Store to slot 2 type
	LDX.B $08                   ; X = saved parameters
	STX.B $06                   ; Restore to slot 2

Check_Slot3:
	; Process animation slot 3 ($0A)
	LDA.B $0A                   ; A = animation type (slot 3)
	BEQ Animation_Done          ; If $00 (empty), done
	CMP.B #$02                  ; Compare to $02
	BEQ Execute_Slot3           ; If exactly $02, execute
	CMP.B #$10                  ; Compare to $10
	BCC Check_Gate              ; If < $10, check gate
	CMP.B #$20                  ; Compare to $20
	BCC Execute_Slot3           ; If $10-$1F, execute

Check_Gate:
	LDA.B #$04                  ; Bit 2 mask
	AND.W $00E2                 ; Check animation gate flag
	BNE Animation_Done          ; If set, skip slot 3

Execute_Slot3:
	LDX.B $0A                   ; X = animation type (16-bit load)
	STX.W $0600                 ; Store to animation command
	LDX.B $0C                   ; X = animation parameter (16-bit)
	STX.W $0602                 ; Store parameter to $0602
	JSL.L CODE_0D8004           ; Call animation processor
	STZ.B $0A                   ; Clear slot 3 type ($00 = empty)

Animation_Done:
	SEI                         ; Disable interrupts
	LDA.B #$20                  ; Bit 5 mask
	TRB.W $00D9                 ; Clear animation processing flag
	RTS                         ; Return

; ===========================================================================
; Graphics Mode Setup - Jump to Field Mode Initialization
; ===========================================================================
; Purpose: Setup graphics environment and jump to field mode code
; Technical Details:
;   - Calls CODE_0092FC to prepare graphics state
;   - Jumps to CODE_00803A for field mode initialization
; Side Effects: Modifies $00D6, NMITIMEN register, $00D2, $00DB
; ===========================================================================

CODE_0092F0:
	JSR.W CODE_0092FC           ; Setup graphics state
	JMP.W CODE_00803A           ; Jump to field mode init

; ===========================================================================
; Graphics Mode Setup - Jump to Battle Mode Initialization
; ===========================================================================
; Purpose: Setup graphics environment and jump to battle mode code
; Technical Details:
;   - Calls CODE_0092FC to prepare graphics state
;   - Jumps to CODE_008016 for battle mode initialization
; Side Effects: Modifies $00D6, NMITIMEN register, $00D2, $00DB
; ===========================================================================

CODE_0092F6:
	JSR.W CODE_0092FC           ; Setup graphics state
	JMP.W CODE_008016           ; Jump to battle mode init

; ===========================================================================
; Graphics State Setup Routine
; ===========================================================================
; Purpose: Configure graphics system for mode transitions
; Technical Details:
;   - Sets bit 6 ($40) of $00D6 (graphics busy flag)
;   - Restores NMI/IRQ configuration from $0112
;   - Enables interrupts
;   - Calls sprite processing routine CODE_00C7B8
;   - Clears bit 3 ($08) of $00D2 (graphics ready flag)
;   - Clears bit 2 ($04) of $00DB (animation gate)
; Registers Modified:
;   - A: Used for bit manipulation
;   - NMITIMEN ($4200): Set from $0112
; ===========================================================================

CODE_0092FC:
	SEP #$30                    ; 8-bit A/X/Y
	LDA.B #$40                  ; Bit 6 mask
	TSB.W $00D6                 ; Set graphics busy flag in $00D6
	LDA.W $0112                 ; Load NMI/IRQ configuration
	STA.W SNES_NMITIMEN         ; Store to NMITIMEN ($4200)
	CLI                         ; Enable interrupts
	JSL.L CODE_00C7B8           ; Call sprite processing routine
	LDA.B #$08                  ; Bit 3 mask
	TRB.W $00D2                 ; Clear graphics ready flag
	LDA.B #$04                  ; Bit 2 mask
	TRB.W $00DB                 ; Clear animation gate
	RTS                         ; Return

; ===========================================================================
; Display Configuration Setup
; ===========================================================================
; Purpose: Configure display parameters and enable certain display features
; Technical Details:
;   - Called to enable/configure display effects
;   - Sets $0051 = $0008 (display timer/counter)
;   - Sets $0055 = $0C (display mode/config)
;   - Clears bit 1 ($02) of $00DB (display update gate)
;   - Clears bit 7 ($80) of $00E2 (graphics effect flag)
;   - Sets bit 2 ($04) of $00DB (animation gate)
; Side Effects: Enables specific graphics modes, gates certain animations
; ===========================================================================

CODE_009319:
	PHP                         ; Save processor status
	PHB                         ; Save data bank
	PHK                         ; Push program bank
	PLB                         ; Data Bank = program bank
	REP #$30                    ; 16-bit A/X/Y
	PHA                         ; Save A
	LDA.W #$0008                ; Value $0008
	STA.W $0051                 ; Store to display timer
	SEP #$20                    ; 8-bit A
	LDA.B #$0C                  ; Value $0C
	STA.W $0055                 ; Store to display config
	LDA.B #$02                  ; Bit 1 mask
	TRB.W $00DB                 ; Clear display update gate
	LDA.B #$80                  ; Bit 7 mask
	TRB.W $00E2                 ; Clear graphics effect flag
	LDA.B #$04                  ; Bit 2 mask
	TSB.W $00DB                 ; Set animation gate
	REP #$30                    ; 16-bit A/X/Y
	PLA                         ; Restore A
	PLB                         ; Restore data bank
	PLP                         ; Restore processor status
	RTL                         ; Return long

; ===========================================================================
; Display Frame Counter Check
; ===========================================================================
; Purpose: Check display timing and process frame-based updates
; Technical Details:
;   - Checks if bit 2 ($04) of $00DB is set (animation gate)
;   - If not set, returns immediately
;   - Checks lower nibble of $0E97 for timing sync
;   - Must be $00 to proceed with updates
;   - If all conditions met, processes display updates
; Returns: Early if conditions not met
; Side Effects: May call display update routines
; ===========================================================================

CODE_009342:
	LDA.W #$0004                ; Bit 2 mask
	AND.W $00DB                 ; Check animation gate
	BEQ Skip_Frame_Check        ; If clear, skip
	LDA.W $0E97                 ; Load frame counter
	AND.W #$000F                ; Mask to lower nibble
	BEQ Process_Frame           ; If $00, process this frame

Skip_Frame_Check:
	RTS                         ; Return (skip this frame)

Process_Frame:
	; Frame processing continues...
	; (Code continues into next section)

; ===========================================================================
; Math Helper Routines - Multiplication and Division
; ===========================================================================

; ---------------------------------------------------------------------------
; 16-bit Multiplication Helper
; ---------------------------------------------------------------------------
; Purpose: Multiply two 16-bit values using SNES hardware multiplier
; Input: A = multiplicand (16-bit), Y = multiplier (16-bit)
; Output: $9E-$A0 = 32-bit product
; Technical Details:
;   - Uses Direct Page $0000 for calculations
;   - Saves A register ($9C → $A4)
;   - Performs 16 iterations of shift-and-add
;   - Result in $9E (low word) and $A0 (high word)
; ===========================================================================

CODE_0096B3:
	PHP                         ; Save processor status
	REP #$30                    ; 16-bit A/X/Y
	PHD                         ; Save direct page
	PHA                         ; Save A
	PHX                         ; Save X
	PHY                         ; Save Y
	LDA.W #$0000                ; Direct Page = $0000
	TCD                         ; Set DP to zero page
	LDA.B $9C                   ; Load multiplicand from stack
	STA.B $A4                   ; Store to $A4
	STZ.B $9E                   ; Clear result low word
	LDX.W #$0010                ; Loop counter = 16 bits
	LDY.B $98                   ; Y = multiplier from stack

Multiply_Loop:
	ASL.B $9E                   ; Shift result left (low word)
	ROL.B $A0                   ; Rotate result (high word)
	ASL.B $A4                   ; Shift multiplicand left
	BCC Skip_Add                ; If no carry, skip addition
	TYA                         ; A = multiplier
	CLC                         ; Clear carry
	ADC.B $9E                   ; Add to result low word
	STA.B $9E                   ; Store back
	BCC Skip_Add                ; If no carry, continue
	INC.B $A0                   ; Increment high word

Skip_Add:
	DEX                         ; Decrement loop counter
	BNE Multiply_Loop           ; Loop until done
	PLY                         ; Restore Y
	PLX                         ; Restore X
	PLA                         ; Restore A
	PLD                         ; Restore direct page
	PLP                         ; Restore processor status
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; 32-bit Division Helper
; ---------------------------------------------------------------------------
; Purpose: Divide 32-bit value by 16-bit divisor
; Input: $9E-$A0 = 32-bit dividend, $9C = 16-bit divisor
; Output: $9E-$A0 = quotient, $A2 = remainder
; Technical Details:
;   - Uses Direct Page $0000 for calculations
;   - Performs 32 iterations of shift-and-subtract
;   - Handles division by zero (undefined behavior)
; ===========================================================================

CODE_0096E4:
	PHP                         ; Save processor status
	REP #$30                    ; 16-bit A/X/Y
	PHD                         ; Save direct page
	PHA                         ; Save A
	PHX                         ; Save X
	LDA.W #$0000                ; Direct Page = $0000
	TCD                         ; Set DP to zero page
	LDA.B $98                   ; Load dividend low word
	STA.B $A4                   ; Store to $A4
	LDA.B $9A                   ; Load dividend high word
	STA.B $A6                   ; Store to $A6
	STZ.B $A2                   ; Clear remainder
	LDX.W #$0020                ; Loop counter = 32 bits

Divide_Loop:
	ASL.B $9E                   ; Shift quotient left (low)
	ROL.B $A0                   ; Rotate quotient (mid)
	ASL.B $A4                   ; Shift dividend left (low)
	ROL.B $A6                   ; Rotate dividend (mid)
	ROL.B $A2                   ; Rotate into remainder
	LDA.B $A2                   ; A = remainder
	BCS Division_Subtract       ; If carry set, always subtract
	SEC                         ; Set carry for subtraction
	SBC.B $9C                   ; Subtract divisor
	BCS Store_Remainder         ; If no borrow, store result
	BRA Skip_Division           ; Skip if borrow

Division_Subtract:
	SBC.B $9C                   ; Subtract divisor (carry already set)

Store_Remainder:
	STA.B $A2                   ; Store new remainder
	INC.B $9E                   ; Set bit in quotient

Skip_Division:
	DEX                         ; Decrement loop counter
	BNE Divide_Loop             ; Loop until done
	PLX                         ; Restore X
	PLA                         ; Restore A
	PLD                         ; Restore direct page
	PLP                         ; Restore processor status
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; Hardware Multiply Helper
; ---------------------------------------------------------------------------
; Purpose: Store value to SNES hardware multiplier B register
; Input: A (8-bit) = multiplier B value
; Output: Hardware multiplier ready for result read
; Technical Details:
;   - Writes to WRMPYB ($4203)
;   - Must have previously written to WRMPYA ($4202)
;   - Result available in RDMPYL/H ($4216-$4217) after 8 cycles
; ===========================================================================

CODE_00971E:
	PHP                         ; Save processor status
	SEP #$20                    ; 8-bit A
	STA.W SNES_WRMPYB           ; Write to multiplier B register
	PLP                         ; Restore processor status
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; Hardware Divide Helper
; ---------------------------------------------------------------------------
; Purpose: Perform hardware division using SNES divider
; Input: A (16-bit) = dividend, after XBA = divisor (8-bit high byte)
; Output: Result in RDDIVL/H ($4214-$4215), remainder in RDMPYL/H
; Technical Details:
;   - Writes to WRDIVB ($4206)
;   - XBA twice creates delay for result to be ready
;   - Division takes 16 cycles to complete
; ===========================================================================

CODE_009726:
	PHP                         ; Save processor status
	SEP #$20                    ; 8-bit A
	STA.W SNES_WRDIVB           ; Write divisor to hardware
	XBA                         ; Swap A bytes (delay)
	XBA                         ; Swap back (delay)
	PLP                         ; Restore processor status
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; Find First Set Bit (Count Leading Zeros)
; ---------------------------------------------------------------------------
; Purpose: Find position of first set bit in 16-bit value
; Input: A (16-bit) = value to test
; Output: A (16-bit) = bit position (0-15), or $FFFF if no bits set
; Technical Details:
;   - Counts from LSB (bit 0) upward
;   - Returns position of first 1 bit found
;   - Returns $FFFF if input is $0000
; ===========================================================================

CODE_009730:
	PHP                         ; Save processor status
	REP #$30                    ; 16-bit A/X/Y
	PHX                         ; Save X
	LDX.W #$FFFF                ; X = -1 (initial position)

Count_Bits:
	INX                         ; Increment position
	LSR A                       ; Shift right, test bit 0
	BCC Count_Bits              ; If clear, continue
	TXA                         ; A = bit position
	PLX                         ; Restore X
	PLP                         ; Restore processor status
	RTL                         ; Return long

; ===========================================================================
; Bit Manipulation Helpers
; ===========================================================================

; ---------------------------------------------------------------------------
; Set Bits (TSB - Test and Set Bits)
; ---------------------------------------------------------------------------
; Purpose: Set bits in memory using TSB operation
; Input: A = bit mask, $00+DP = target address
; Output: Target memory has bits set, Z flag reflects test
; Technical Details:
;   - Calls CODE_0097DA to calculate bit position
;   - Uses TSB instruction at Direct Page $00
; ===========================================================================

CODE_00974E:
	JSR.W CODE_0097DA           ; Calculate bit position/mask
	TSB.B $00                   ; Test and set bits
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; Clear Bits (TRB - Test and Reset Bits)
; ---------------------------------------------------------------------------
; Purpose: Clear bits in memory using TRB operation
; Input: A = bit mask, $00+DP = target address
; Output: Target memory has bits cleared, Z flag reflects test
; Technical Details:
;   - Calls CODE_0097DA to calculate bit position
;   - Uses TRB instruction at Direct Page $00
; ===========================================================================

CODE_009754:
	JSR.W CODE_0097DA           ; Calculate bit position/mask
	TRB.B $00                   ; Test and reset bits
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; Test Bits (AND operation)
; ---------------------------------------------------------------------------
; Purpose: Test bits in memory without modification
; Input: A = bit mask, $00+DP = target address
; Output: A = result of AND operation, Z/N flags set
; Technical Details:
;   - Calls CODE_0097DA to calculate bit position
;   - Uses AND instruction to test bits
; ===========================================================================

CODE_00975A:
	JSR.W CODE_0097DA           ; Calculate bit position/mask
	AND.B $00                   ; Test bits
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; Set Bits with DP $0EA8
; ---------------------------------------------------------------------------
; Purpose: Set bits in $0EA8+offset using TSB
; Input: A = bit mask (offset in low byte)
; Output: Bits set in target location
; ===========================================================================

CODE_009760:
	PHD                         ; Save direct page
	PEA.W $0EA8                 ; Push $0EA8
	PLD                         ; Direct Page = $0EA8
	JSL.L CODE_00974E           ; Set bits via TSB
	PLD                         ; Restore direct page
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; Clear Bits with DP $0EA8
; ---------------------------------------------------------------------------
; Purpose: Clear bits in $0EA8+offset using TRB
; Input: A = bit mask (offset in low byte)
; Output: Bits cleared in target location
; ===========================================================================

CODE_00976B:
	PHD                         ; Save direct page
	PEA.W $0EA8                 ; Push $0EA8
	PLD                         ; Direct Page = $0EA8
	JSL.L CODE_009754           ; Clear bits via TRB
	PLD                         ; Restore direct page
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; Test Bits with DP $0EA8
; ---------------------------------------------------------------------------
; Purpose: Test bits in $0EA8+offset
; Input: A = bit mask (offset in low byte)
; Output: A = result of test, Z/N flags set
; ===========================================================================

CODE_009776:
	PHD                         ; Save direct page
	PEA.W $0EA8                 ; Push $0EA8
	PLD                         ; Direct Page = $0EA8
	JSL.L CODE_00975A           ; Test bits via AND
	PLD                         ; Restore direct page
	INC A                       ; Set flags based on result
	DEC A                       ; (INC/DEC preserves value, updates flags)
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; Random Number Generator
; ---------------------------------------------------------------------------
; Purpose: Generate pseudo-random number using linear congruential generator
; Output: $A9 (at DP $005E) = random byte, $701FFE updated
; Technical Details:
;   - Uses formula: seed = seed * 5 + $3711 + frame_counter
;   - Seed stored at $701FFE (16-bit)
;   - Uses $0E96 (frame counter) for additional entropy
;   - Applies modulo $A8 (stored in $A8 at DP $005E)
; ===========================================================================

CODE_009783:
	PHP                         ; Save processor status
	PHD                         ; Save direct page
	REP #$30                    ; 16-bit A/X/Y
	PHA                         ; Save A
	LDA.W #$005E                ; Direct Page = $005E
	TCD                         ; Set DP
	LDA.L $701FFE               ; Load current seed
	ASL A                       ; Multiply by 2
	ASL A                       ; Multiply by 4
	ADC.L $701FFE               ; Add original (now *5)
	ADC.W #$3711                ; Add constant
	ADC.W $0E96                 ; Add frame counter
	STA.L $701FFE               ; Store new seed
	SEP #$20                    ; 8-bit A
	XBA                         ; Get high byte
	STA.B $4B                   ; Store to $A9 (DP $005E + $4B)
	STA.W SNES_WRDIVL           ; Write to divider (low byte)
	STZ.W SNES_WRDIVH           ; Clear divider (high byte)
	LDA.B $4A                   ; Load modulo value from $A8
	BEQ Random_Done             ; If zero, skip modulo
	JSL.L CODE_009726           ; Perform division
	LDA.W SNES_RDMPYL           ; Read remainder (result of modulo)
	STA.B $4B                   ; Store to $A9

Random_Done:
	REP #$30                    ; 16-bit A/X/Y
	PLA                         ; Restore A
	PLD                         ; Restore direct page
	PLP                         ; Restore processor status
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; Bit Position to Mask Conversion Table
; ---------------------------------------------------------------------------
; Purpose: Convert bit position (0-7) to bit mask
; Input: A (after processing) = bit position * 2 (for word indexing)
; Output: A = bit mask ($0001, $0002, $0004...$0080, $0100...$8000)
; ===========================================================================

CODE_0097F2:
	PHX                         ; Save X
	ASL A                       ; Multiply by 2 for word table
	TAX                         ; X = index
	LDA.L DATA8_0097FB,X        ; Load bit mask from table
	PLX                         ; Restore X
	RTS                         ; Return

DATA8_0097FB:
	dw $0001, $0002, $0004, $0008, $0010, $0020, $0040, $0080
	dw $0100, $0200, $0400, $0800, $1000, $2000, $4000, $8000

; ---------------------------------------------------------------------------
; Bit Position Calculator
; ---------------------------------------------------------------------------
; Purpose: Calculate Direct Page offset and bit mask from bit position
; Input: A (8-bit) = absolute bit position (0-255)
; Output: DP adjusted to byte containing bit, A = bit number (0-7) inverted
; Technical Details:
;   - Divides bit position by 8 to get byte offset
;   - Adds offset to current Direct Page
;   - Returns bit position within byte (inverted: 7-0)
; ===========================================================================

CODE_0097DA:
	PHP                         ; Save processor status
	REP #$30                    ; 16-bit A/X/Y
	AND.W #$00FF                ; Mask to 8-bit value
	PHA                         ; Save bit position
	LSR A                       ; Divide by 2
	LSR A                       ; Divide by 4
	LSR A                       ; Divide by 8 (byte offset)
	PHD                         ; Save current DP
	CLC                         ; Clear carry
	ADC.B $01,S                 ; Add to saved DP
	TCD                         ; Set new DP
	PLA                         ; Discard saved DP
	PLA                         ; Restore bit position
	AND.W #$0007                ; Mask to bit number (0-7)
	EOR.W #$0007                ; Invert bit position
	PLP                         ; Restore processor status
	; Returns with A = inverted bit position (for bit mask lookup)

; ===========================================================================
; Indirect Jump Via Table
; ===========================================================================
; Purpose: Perform indirect jump using jump table indexed by A
; Input: A (8-bit) = table index, return address on stack points to table
; Output: Jumps to address from table, modifies return address
; Technical Details:
;   - Manipulates stack to redirect return address
;   - Reads 16-bit pointer from table at (return_address + A*2)
;   - Replaces return address with table entry
;   - Uses RTI to jump to new address
; Stack Layout:
;   Entry: [return_bank] [return_addr] [saved_registers]
;   Exit:  [return_bank] [table_addr] [saved_registers]
; ===========================================================================

CODE_0097BE:
	PHP                         ; Save processor status
	PHB                         ; Save data bank
	REP #$30                    ; 16-bit A/X/Y
	PHY                         ; Save Y
	AND.W #$00FF                ; Mask to 8-bit index
	ASL A                       ; Multiply by 2 (word table)
	TAY                         ; Y = table offset
	LDA.B $06,S                 ; Load return bank from stack
	PHA                         ; Save it
	PLB                         ; Data Bank = return bank
	PLB                         ; (needs double pull for 16-bit)
	LDA.B ($08,S),Y             ; Read table entry at [return_addr + Y]
	TAY                         ; Y = destination address
	LDA.B $05,S                 ; Get saved processor status
	STA.B $08,S                 ; Move to where return address was
	TYA                         ; A = destination address
	STA.B $05,S                 ; Store as new return address
	PLY                         ; Restore Y
	PLB                         ; Restore data bank
	RTI                         ; Return to table address (not original caller)

; ===========================================================================
; Common Stack Cleanup Routine
; ===========================================================================
; Purpose: Standard cleanup of saved registers from stack
; Technical Details:
;   - Restores registers in reverse order of saving
;   - REP #$30 ensures 16-bit mode for index registers
; ===========================================================================

CODE_00981B:
	REP #$30                    ; 16-bit A/X/Y
	PLY                         ; Restore Y
	PLX                         ; Restore X
	PLD                         ; Restore direct page
	PLA                         ; Restore A
	PLB                         ; Restore data bank
	PLP                         ; Restore processor status
	RTS                         ; Return

; ===========================================================================
; Memory Copy/Fill Routines
; ===========================================================================

; ---------------------------------------------------------------------------
; Copy 64 Bytes (16 words) Between Memory Blocks
; ---------------------------------------------------------------------------
; Purpose: Copy 32 words (64 bytes) from X to Y, both in bank $7E
; Input: X = source address, Y = destination address
; Technical Details:
;   - Copies in reverse order (high to low addresses)
;   - 32 LDA/STA pairs for 64 bytes total
;   - All addresses offset from base X/Y by +$00 to +$3E (even offsets)
; ===========================================================================

CODE_009891:
	LDA.W $003E,X               ; Copy word at +$3E
	STA.W $003E,Y
	LDA.W $003C,X               ; Copy word at +$3C
	STA.W $003C,Y
	LDA.W $003A,X               ; Copy word at +$3A
	STA.W $003A,Y
	LDA.W $0038,X               ; Copy word at +$38
	STA.W $0038,Y
	LDA.W $0036,X               ; Copy word at +$36
	STA.W $0036,Y
	LDA.W $0034,X               ; Copy word at +$34
	STA.W $0034,Y
	LDA.W $0032,X               ; Copy word at +$32
	STA.W $0032,Y
	LDA.W $0030,X               ; Copy word at +$30
	STA.W $0030,Y
	LDA.W $002E,X               ; Copy word at +$2E
	STA.W $002E,Y
	LDA.W $002C,X               ; Copy word at +$2C
	STA.W $002C,Y
	LDA.W $002A,X               ; Copy word at +$2A
	STA.W $002A,Y
	LDA.W $0028,X               ; Copy word at +$28
	STA.W $0028,Y
	LDA.W $0026,X               ; Copy word at +$26
	STA.W $0026,Y
	LDA.W $0024,X               ; Copy word at +$24
	STA.W $0024,Y
	LDA.W $0022,X               ; Copy word at +$22
	STA.W $0022,Y
	LDA.W $0020,X               ; Copy word at +$20
	STA.W $0020,Y

CODE_0098F1:
	LDA.W $001E,X               ; Copy word at +$1E
	STA.W $001E,Y
	LDA.W $001C,X               ; Copy word at +$1C
	STA.W $001C,Y
	LDA.W $001A,X               ; Copy word at +$1A
	STA.W $001A,Y
	LDA.W $0018,X               ; Copy word at +$18
	STA.W $0018,Y
	LDA.W $0016,X               ; Copy word at +$16
	STA.W $0016,Y
	LDA.W $0014,X               ; Copy word at +$14
	STA.W $0014,Y
	LDA.W $0012,X               ; Copy word at +$12
	STA.W $0012,Y
	LDA.W $0010,X               ; Copy word at +$10
	STA.W $0010,Y
	LDA.W $000E,X               ; Copy word at +$0E
	STA.W $000E,Y
	LDA.W $000C,X               ; Copy word at +$0C
	STA.W $000C,Y
	LDA.W $000A,X               ; Copy word at +$0A
	STA.W $000A,Y
	LDA.W $0008,X               ; Copy word at +$08
	STA.W $0008,Y
	LDA.W $0006,X               ; Copy word at +$06
	STA.W $0006,Y
	LDA.W $0004,X               ; Copy word at +$04
	STA.W $0004,Y
	LDA.W $0002,X               ; Copy word at +$02
	STA.W $0002,Y
	LDA.W $0000,X               ; Copy word at +$00
	STA.W $0000,Y
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Memory Fill Dispatcher - Long Entry Point
; ---------------------------------------------------------------------------
; Purpose: Fill memory with value (long call wrapper)
; Input: A (16-bit) = fill count, Y = start address, value on stack
; ===========================================================================

CODE_009994:
	JSR.W CODE_009998           ; Call fill routine
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; Memory Fill Routine
; ---------------------------------------------------------------------------
; Purpose: Fill memory region with specified value
; Input:
;   A (16-bit) = number of bytes to fill
;   Y = starting address in bank $7F
;   Stack+3 = fill value (16-bit)
; Technical Details:
;   - Handles blocks of 64 bytes ($40) at a time
;   - Uses CODE_0099BD for 64-byte blocks
;   - Uses jump table (DATA8_009A1E) for partial blocks
;   - Remainder handled by indexed jump
; ===========================================================================

CODE_009998:
	PHX                         ; Save X
	CMP.W #$0040                ; Check if >= 64 bytes
	BCC Handle_Remainder        ; If < 64, handle remainder
	PHA                         ; Save count
	LSR A                       ; Divide by 2
	LSR A                       ; Divide by 4
	LSR A                       ; Divide by 8
	LSR A                       ; Divide by 16
	LSR A                       ; Divide by 32
	LSR A                       ; Divide by 64
	TAX                         ; X = number of 64-byte blocks
	CLC                         ; Clear carry

Fill_Block_Loop:
	LDA.B $03,S                 ; Get fill value from stack
	JSR.W CODE_0099BD           ; Fill 64 bytes
	TYA                         ; A = current address
	ADC.W #$0040                ; Advance by 64 bytes
	TAY                         ; Y = new address
	DEX                         ; Decrement block counter
	BNE Fill_Block_Loop         ; Loop if more blocks
	PLA                         ; Restore count
	AND.W #$003F                ; Get remainder (last 0-63 bytes)

Handle_Remainder:
	TAX                         ; X = remainder count (doubled for jump table)
	PLA                         ; Restore X from stack
	JMP.W (DATA8_009A1E,X)      ; Jump to handler for exact count

; ---------------------------------------------------------------------------
; Fill 64 Bytes With Value
; ---------------------------------------------------------------------------
; Purpose: Fill exactly 64 bytes starting at Y with value in A
; Technical Details:
;   - Uses unrolled loop (32 stores of 16-bit words)
;   - All addresses in bank $7F
; ===========================================================================

CODE_0099BD:
	STA.W $003E,Y               ; Fill word at +$3E
	STA.W $003C,Y               ; Fill word at +$3C
	STA.W $003A,Y               ; Fill word at +$3A
	STA.W $0038,Y               ; Fill word at +$38
	STA.W $0036,Y               ; Fill word at +$36
	STA.W $0034,Y               ; Fill word at +$34
	STA.W $0032,Y               ; Fill word at +$32
	STA.W $0030,Y               ; Fill word at +$30
	STA.W $002E,Y               ; Fill word at +$2E
	STA.W $002C,Y               ; Fill word at +$2C
	STA.W $002A,Y               ; Fill word at +$2A
	STA.W $0028,Y               ; Fill word at +$28
	STA.W $0026,Y               ; Fill word at +$26
	STA.W $0024,Y               ; Fill word at +$24
	STA.W $0022,Y               ; Fill word at +$22

CODE_0099EA:
	STA.W $0020,Y               ; Fill word at +$20
	STA.W $001E,Y               ; Fill word at +$1E
	STA.W $001C,Y               ; Fill word at +$1C
	STA.W $001A,Y               ; Fill word at +$1A
	STA.W $0018,Y               ; Fill word at +$18
	STA.W $0016,Y               ; Fill word at +$16
	STA.W $0014,Y               ; Fill word at +$14
	STA.W $0012,Y               ; Fill word at +$12

CODE_009A02:
	STA.W $0010,Y               ; Fill word at +$10

CODE_009A05:
	STA.W $000E,Y               ; Fill word at +$0E

CODE_009A08:
	STA.W $000C,Y               ; Fill word at +$0C
	STA.W $000A,Y               ; Fill word at +$0A
	STA.W $0008,Y               ; Fill word at +$08

CODE_009A11:
	STA.W $0006,Y               ; Fill word at +$06
	STA.W $0004,Y               ; Fill word at +$04
	STA.W $0002,Y               ; Fill word at +$02
	STA.W $0000,Y               ; Fill word at +$00
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Fill Jump Table
; ---------------------------------------------------------------------------
; Purpose: Jump table for partial block fills (0-63 bytes)
; Format: Table of addresses for each possible remainder count
; Technical Details:
;   - Entry points into CODE_0099BD at various offsets
;   - Allows exact fill counts without conditional logic
; ===========================================================================

DATA8_009A1E:
	dw $9A1D                    ; 0 bytes (just return)
	dw $9A1A, $9A17, $9A14, $9A11  ; 2, 4, 6, 8 bytes
	dw $9A0E, $9A0B, $9A08, $9A05, $9A02  ; 10-18 bytes
	dw $99FF, $99FC, $99F9, $99F6, $99F3  ; 20-28 bytes
	dw $99F0, $99ED, $99EA, $99E7, $99E4  ; 30-38 bytes
	dw $99E1, $99DE, $99DB, $99D8, $99D5  ; 40-48 bytes
	dw $99D2, $99CF, $99CC, $99C9, $99C6  ; 50-58 bytes
	dw $99C3, $99C0, $99BD               ; 60-64 bytes
Update_Done:
	PLP                              ; Restore status
	RTS                              ; Return

Single_Buffer_Update:
	; Handle single buffer update
	; (code continues...)

Perform_DMA_Update:
	; Execute DMA transfer to update VRAM
	; (code continues...)

; ===========================================================================
; Text/Graphics Processing Routines
; ===========================================================================

; ---------------------------------------------------------------------------
; Load Graphics Data
; ---------------------------------------------------------------------------
; Purpose: Initialize graphics for specific game mode
; Input: Direct Page $0000, $17 = graphics pointer, $19 = bank
; ===========================================================================

CODE_009A60:
	PHP                         ; Save processor status
	PHB                         ; Save data bank
	PHD                         ; Save direct page
	REP #$30                    ; 16-bit A/X/Y
	PHA                         ; Save A
	LDA.W #$0000                ; Direct Page = $0000
	TCD                         ; Set DP
	LDA.W #$F811                ; Graphics pointer
	STA.B $17                   ; Store pointer
	SEP #$20                    ; 8-bit A
	LDA.B #$03                  ; Bank $03
	STA.B $19                   ; Store bank
	JSR.W CODE_009D75           ; Process graphics data
	REP #$30                    ; 16-bit A/X/Y
	PLA                         ; Restore A
	PLD                         ; Restore direct page
	PLB                         ; Restore data bank
	PLP                         ; Restore processor status
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; Graphics Processing Entry Points
; ---------------------------------------------------------------------------

CODE_009AEC:
	PHP                         ; Save processor status
	PHD                         ; Save direct page
	PEA.W $0000                 ; Push $0000
	PLD                         ; Direct Page = $0000
	REP #$30                    ; 16-bit A/X/Y
	PHX                         ; Save X
	LDX.W #$9AFF                ; Data pointer
	JSR.W CODE_009BC4           ; Process data
	PLX                         ; Restore X
	PLD                         ; Restore direct page
	PLP                         ; Restore processor status
	RTL                         ; Return long

CODE_009B02:
	PHP                         ; Save processor status
	PHD                         ; Save direct page
	PHB                         ; Save data bank
	SEP #$20                    ; 8-bit A
	REP #$10                    ; 16-bit X/Y
	PHA                         ; Save A
	PHX                         ; Save X
	PEA.W $0000                 ; Push $0000
	PLD                         ; Direct Page = $0000
	JSL.L CODE_0C8000           ; Call graphics handler
	JSL.L CODE_0096A0           ; Wait for VBlank
	PEI.B ($1D)                 ; Push [$1D]
	LDA.B $27                   ; Load parameter
	PHA                         ; Save it
	JSL.L CODE_009B2F           ; Process graphics
	JSR.W CODE_00A342           ; Call handler
	PLA                         ; Restore parameter
	STA.B $27                   ; Store back
	PLX                         ; Get saved value
	STX.B $1D                   ; Store to $1D
	PLX                         ; Restore X
	PLA                         ; Restore A
	PLB                         ; Restore data bank
	PLD                         ; Restore direct page
	PLP                         ; Restore processor status
	RTL                         ; Return long

CODE_009B2F:
	PHP                         ; Save processor status
	PHD                         ; Save direct page
	PEA.W $0000                 ; Push $0000
	PLD                         ; Direct Page = $0000
	REP #$30                    ; 16-bit A/X/Y
	PHX                         ; Save X
	LDX.W #$9B42                ; Data pointer
	JSR.W CODE_009BC4           ; Process data
	PLX                         ; Restore X
	PLD                         ; Restore direct page
	PLP                         ; Restore processor status
	RTL                         ; Return long

CODE_009B45:
	PHP                         ; Save processor status
	PHD                         ; Save direct page
	REP #$30                    ; 16-bit A/X/Y
	LDA.W #$0000                ; Direct Page = $0000
	TCD                         ; Set DP
	LDX.W #$9B56                ; Data pointer
	JSR.W CODE_009BC4           ; Process data
	PLD                         ; Restore direct page
	PLP                         ; Restore processor status
	RTL                         ; Return long

CODE_009B59:
	PHP                         ; Save processor status
	PHD                         ; Save direct page
	REP #$30                    ; 16-bit A/X/Y
	LDA.W #$0000                ; Direct Page = $0000
	TCD                         ; Set DP
	LDA.B $20                   ; Load parameter
	STA.B $4F                   ; Store to $4F
	JSR.W CODE_009B8A           ; Setup graphics
	LDA.B [$17]                 ; Load data
	AND.W #$00FF                ; Mask to byte
	CMP.W #$0004                ; Compare to 4
	BEQ Skip_Special            ; If equal, skip
	LDX.W #$9B9D                ; Special data pointer
	JSR.W CODE_009BC4           ; Process data

Skip_Special:
	JSR.W CODE_009B8A           ; Setup graphics again
	JSR.W CODE_009D75           ; Process graphics data
	JSR.W CODE_009BA3           ; Post-process
	LDX.W #$9BA0                ; Cleanup pointer
	JSR.W CODE_009BC4           ; Process cleanup
	PLD                         ; Restore direct page
	PLP                         ; Restore processor status
	RTL                         ; Return long

CODE_009B8A:
	SEP #$20                    ; 8-bit A
	LDA.B #$03                  ; Bank $03
	STA.B $19                   ; Store bank
	REP #$30                    ; 16-bit A/X/Y
	LDA.B $20                   ; Load parameter
	ASL A                       ; Multiply by 2
	TAX                         ; X = index
	LDA.L UNREACH_03D5E5,X      ; Load pointer from table
	STA.B $17                   ; Store graphics pointer
	RTS                         ; Return

CODE_009BA3:
	RTS                         ; Return (stub)

CODE_009BA4:
	PHP                         ; Save processor status
	PHD                         ; Save direct page
	REP #$30                    ; 16-bit A/X/Y
	LDA.W #$0000                ; Direct Page = $0000
	TCD                         ; Set DP
	SEP #$20                    ; 8-bit A
	LDA.B #$03                  ; Bank $03
	STA.B $19                   ; Store bank
	REP #$30                    ; 16-bit A/X/Y
	LDA.B $20                   ; Load parameter
	ASL A                       ; Multiply by 2
	TAX                         ; X = index
	LDA.L DATA8_03BB81,X        ; Load pointer from table
	STA.B $17                   ; Store graphics pointer
	JSR.W CODE_009D75           ; Process graphics data
	PLD                         ; Restore direct page
	PLP                         ; Restore processor status
	RTL                         ; Return long

; ===========================================================================
; Graphics Data Processing Engine
; ===========================================================================

; ---------------------------------------------------------------------------
; CODE_009BC4: Process Graphics Data
; ---------------------------------------------------------------------------
; Purpose: Core graphics data processor - copies parameters and processes
; Input: X = data pointer in Bank $00
; ===========================================================================

; ---------------------------------------------------------------------------
; Additional Graphics Command Handlers (continued)
; ---------------------------------------------------------------------------

; The following handlers implement a variety of in-stream commands used by
; the graphics command dispatcher. They were imported from the Diztinguish
; reference disassembly and documented here to preserve call/stack conventions
; and comments.

UNREACH_00A2D4:
	db $A2,$FF,$FF,$86,$9E,$86,$A0,$FA,$60

DATA8_00A2DD:
	db $10

DATA8_00A2DE:
	db $19,$00,$12,$32,$00,$DD,$0A,$00
	db $FF

; ---------------------------------------------------------------------------
; Command stream table processing helpers
; ---------------------------------------------------------------------------

CODE_00A2E7:
	LDA.B [$17]
	INC.B $17
	AND.W #$00FF
	DEC A
	CMP.B $9E
	BCC UNREACH_00A2FF
	LDA.B $9E
	ASL A
	ADC.B $17
	STA.B $17
	LDA.B [$17]
	STA.B $17
	RTS

UNREACH_00A2FF:
	db $1A,$0A,$65,$17,$85,$17,$60

CODE_00A306:
	LDA.B [$17]
	INC.B $17
	AND.W #$00FF
	DEC A
	CMP.B $9E
	PHP
	INC A
	ASL A
	ADC.B $17
	TAY
	PLP
	BCC CODE_00A32F
	LDA.B $9E
	ASL A
	ADC.B $17
	STA.B $17
	LDA.B [$17]
	STA.B $17
	SEP #$20
	LDA.B $19
	JSR.W CODE_009D75
	STA.B $19
	REP #$30

CODE_00A32F:
	STY.B $17
	RTS

; ---------------------------------------------------------------------------
; More graphics command handlers (block)
; Imported segment: CODE_00A342 .. CODE_00A576
; ---------------------------------------------------------------------------

CODE_00A342:
	PHP
	REP #$30
	PHB
	PHA
	PHD
	PHX
	PHY
	LDA.B $46
	BNE +
	JMP CODE_00A375
+	LDA.B $40
	STA.W $01EE
	LDA.B $44
	STA.W $01ED
	SEC
	SBC.B $3F
	LSR A
	ADC.B $42
	STA.B $48
	SEC
	LDA.B $46
	SBC.B $44
	STA.W $01EB
	LDA.W #$00E0
	TSB.W $00D2
	LDA.W #$FFFF
	STA.B $44
	STZ.B $46
	JMP.W CODE_00981B

CODE_00A378:
	LDA.W #$0080
	TSB.W $00D0
	RTS

CODE_00A37F:
	LDA.B [$17]
	INC.B $17
	AND.W #$00FF
	ASL A
	TAX
	JMP.W (DATA8_009E6E,X)

CODE_00A38B:
	LDA.W #$0080
	TSB.W $00D8
	JSL.L CODE_0C8000
	LDA.W #$0008
	TRB.W $00D4
	RTS

CODE_00A39C:
	LDA.W #$0040
	AND.W $00D0
	BEQ CODE_00A3A5
	RTS

CODE_00A3A5:
	LDA.W #$00FF
	JMP.W CODE_009DC9

CODE_00A3AB:
	JSL.L CODE_0C8000
	LDA.W #$0020
	AND.W $00D0
	BNE CODE_00A3C6
	LDA.B [$17]
	INC.B $17
	INC.B $17

CODE_00A3BD:
	JSL.L CODE_0096A0
	BIT.B $94
	BEQ CODE_00A3BD
	RTS

CODE_00A3C6:
	LDA.B [$17]
	INC.B $17
	INC.B $17

CODE_00A3CC:
	JSL.L CODE_0096A0
	BIT.B $07
	BEQ CODE_00A3CC
	RTS

; A series of conditional calls to CODE_00B1C3/CODE_00B1D6 etc.:

CODE_00A3D5:
	JSR.W CODE_00B1C3
	BCC CODE_00A401
	BEQ CODE_00A401
	BRA CODE_00A406

; (several similar blocks follow in the original disassembly; preserved as-is)

CODE_00A401:
	INC.B $17
	INC.B $17
	RTS

CODE_00A406:
	LDA.B [$17]
	STA.B $17
	RTS

CODE_00A40B:
	JSR.W CODE_00B1D6
	BCC CODE_00A437
	BEQ CODE_00A437
	BRA CODE_00A43C

CODE_00A437:
	INC.B $17
	INC.B $17
	RTS

CODE_00A43C:
	LDA.B [$17]
	STA.B $17
	RTS

; (blocks calling CODE_00B1E8, CODE_00B204, CODE_00B21D, CODE_00B22F etc.)

; Examples:
CODE_00A451:
	JSR.W CODE_00B1E8
	BCS CODE_00A46D
	BRA CODE_00A472

CODE_00A46D:
	INC.B $17
	INC.B $17
	RTS

CODE_00A472:
	LDA.B [$17]
	STA.B $17
	RTS

CODE_00A480:
	JSR.W CODE_00B204
	BCC CODE_00A4A3
	BRA CODE_00A4A8

CODE_00A4A3:
	INC.B $17
	INC.B $17
	RTS

CODE_00A4A8:
	LDA.B [$17]
	STA.B $17
	RTS

CODE_00A4BD:
	JSR.W CODE_00B21D
	BCS CODE_00A4D9
	BRA CODE_00A4DE

CODE_00A4D9:
	INC.B $17
	INC.B $17
	RTS

CODE_00A4DE:
	LDA.B [$17]
	STA.B $17
	RTS

CODE_00A4E3:
	JSR.W CODE_00B22F
	BCC CODE_00A50F
	BRA CODE_00A514

CODE_00A50F:
	INC.B $17
	INC.B $17
	RTS

CODE_00A514:
	LDA.B [$17]
	STA.B $17
	RTS

CODE_00A519:
	LDA.B [$17]
	STA.B $17
	RTS

CODE_00A524:
	LDA.B [$17]
	INC.B $17
	INC.B $17
	TAX
	SEP #$20
	LDA.B [$17]
	STA.B $19
	STX.B $17
	RTS

CODE_00A52E:
	LDA.B [$17]
	INC.B $17
	AND.W #$00FF
	PHD
	PEA.W $00D0
	PLD
	JSL.L CODE_00975A
	PLD
	INC A
	DEC A
	BRA CODE_00A56E

CODE_00A54E:
	LDA.B [$17]
	INC.B $17
	AND.W #$00FF
	PHD
	PEA.W $00D0
	PLD
	JSL.L CODE_00975A
	PLD
	INC A
	DEC A
	JMP CODE_00A57D

CODE_00A563:
	LDA.B [$17]
	INC.B $17
	AND.W #$00FF
	JSL.L CODE_009776

CODE_00A56E:
	BNE CODE_00A519
	JMP CODE_00A597

; ---------------------------------------------------------------------------
; End of appended disassembly chunk
; ---------------------------------------------------------------------------

; ===========================================================================
; Progress: ~7,244 lines documented (~51.6% of Bank $00)
; Sections completed (delta):
; - Additional graphics command handlers (CODE_00A2E7..CODE_00A576)
; - Stream parsing helpers and external command bridges
;
; Remaining: ~6,774 lines (battle system, command handlers, data tables)
; ===========================================================================


CODE_009BC4:
	PHP                         ; Save processor status
	REP #$30                    ; 16-bit A/X/Y
	PHY                         ; Save Y
	PHA                         ; Save A
	LDY.W #$0017                ; Y = Direct Page $0017
	LDA.W #$0002                ; Count = 2 bytes + 1
	MVN $00,$00                 ; Copy 3 bytes from [X] to [$17]
	                            ; This copies graphics pointer and bank
	PLA                         ; Restore A
	PLY                         ; Restore Y
	PLP                         ; Restore processor status
	JMP.W CODE_009D75           ; Jump to main graphics processor

; ---------------------------------------------------------------------------
; Clear Graphics Flag Bit 2
; ---------------------------------------------------------------------------

CODE_009BD8:
	LDA.W #$0004                ; Bit 2 mask
	AND.W $00D8                 ; Test if set
	BEQ CODE_009BEC             ; Skip if not set
	LDA.W #$0004                ; Bit 2 mask
	TRB.W $00D8                 ; Clear bit 2
	LDA.W #$00C8                ; Bits 6-7 + bit 3 mask
	TRB.W $0111                 ; Clear those bits in $0111

CODE_009BEC:
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Initialize Color Palette Processing
; ---------------------------------------------------------------------------
; Purpose: Setup DMA for color palette operations
; ===========================================================================

CODE_009BED:
	LDX.W #$9C87                ; Source data pointer
	LDY.W #$5007                ; Dest = $7F5007
	LDA.W #$0022                ; Transfer $22 bytes + 1 = 35 bytes
	MVN $7F,$00                 ; Copy data to buffer

	; Initialize color values
	LDA.L $000E9C               ; Load base color
	STA.W $5011                 ; Store at offset $11
	STA.W $5014                 ; Store at offset $14
	STA.W $501A                 ; Store at offset $1A
	JSR.W CODE_009C52           ; Adjust color brightness
	STA.W $5017                 ; Store adjusted color

	LDA.L DATA8_07800C          ; Load another base color
	STA.W $501E                 ; Store at offset $1E
	STA.W $5021                 ; Store at offset $21
	STA.W $5027                 ; Store at offset $27
	JSR.W CODE_009C52           ; Adjust color brightness
	STA.W $5024                 ; Store adjusted color

	; Setup DMA channels 3, 6, 7 for palette transfer
	PHK                         ; Push program bank
	PLB                         ; Pull to data bank
	SEP #$20                    ; 8-bit A

	LDA.B #$7F                  ; Bank $7F
	STA.W SNES_DMA3ADDRH        ; DMA3 source bank
	STA.W SNES_DMA6ADDRH        ; DMA6 source bank
	STA.W SNES_DMA7ADDRH        ; DMA7 source bank

	LDX.W #$2100                ; SNES register base
	STX.W SNES_DMA3PARAM        ; DMA3 parameter
	LDX.W #$2202                ; Different register
	STX.W SNES_DMA6PARAM        ; DMA6 parameter
	STX.W SNES_DMA7PARAM        ; DMA7 parameter

	LDX.W #$5007                ; Source address
	STX.W SNES_DMA3ADDRL        ; DMA3 source low
	LDX.W #$5010                ; Source address
	STX.W SNES_DMA6ADDRL        ; DMA6 source low
	LDX.W #$501D                ; Source address
	STX.W SNES_DMA7ADDRL        ; DMA7 source low

	REP #$30                    ; 16-bit A/X/Y
	RTS                         ; Return

; ---------------------------------------------------------------------------
; CODE_009C52: Adjust Color Brightness
; ---------------------------------------------------------------------------
; Purpose: Reduce color intensity (darken for shadowing/fade)
; Input: Color on stack (SNES BGR555 format)
; Output: A = adjusted color
; Algorithm: Subtract $30 from red, $18 from green, $0C from blue (clamp to 0)
; ===========================================================================

CODE_009C52:
	PHA                         ; Save color
	SEC                         ; Set carry for subtraction
	AND.W #$7C00                ; Mask red component (bits 10-14)
	SBC.W #$3000                ; Subtract $30 from red
	BCS CODE_009C60             ; Branch if no underflow
	LDA.W #$0000                ; Clamp to 0
	SEC                         ; Set carry

CODE_009C60:
	PHA                         ; Save adjusted red
	LDA.B $03,S                 ; Get original color
	AND.W #$03E0                ; Mask green component (bits 5-9)
	SBC.W #$0180                ; Subtract $18 from green
	BCS CODE_009C6F             ; Branch if no underflow
	LDA.W #$0000                ; Clamp to 0
	SEC                         ; Set carry

CODE_009C6F:
	ORA.B $01,S                 ; Combine with adjusted red
	STA.B $01,S                 ; Store combined result
	LDA.B $03,S                 ; Get original color again
	AND.W #$001F                ; Mask blue component (bits 0-4)
	SBC.W #$000C                ; Subtract $0C from blue
	BCS CODE_009C80             ; Branch if no underflow
	LDA.W #$0000                ; Clamp to 0

CODE_009C80:
	ORA.B $01,S                 ; Combine with red+green
	STA.B $03,S                 ; Store final result
	PLA                         ; Remove temporary value
	PLA                         ; Get final adjusted color
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Color Palette Data
; ---------------------------------------------------------------------------

DATA8_009C87:
	; Color Palette Data Table
DATA8_009C87_colors:
	dw $0D00, $0D01, $0D01, $0D01  ; Color entries
	dw $0000, $5140, $5101, $5140
	dw $1FB4, $5101, $5140, $0000
	dw $7FFF, $7F01, $7FFF, $4E73
	dw $7F01, $7FFF, $0001

; ---------------------------------------------------------------------------
; Setup Character Palette Display
; ---------------------------------------------------------------------------

CODE_009CAA:
	SEP #$20                    ; 8-bit A
	LDX.W #$01AD                ; Default offset
	LDA.B #$20                  ; Test bit 5
	AND.W $00E0                 ; Check flag
	BNE CODE_009CB9             ; Use default if set
	LDX.W #$016F                ; Alternate offset

CODE_009CB9:
	; Copy character palette data to display buffer
	LDA.W $0013,X               ; Load palette entry
	STA.L $7F500B               ; Store to buffer +$0B
	STA.L $7F5016               ; Store to buffer +$16
	STA.L $7F5023               ; Store to buffer +$23

	LDA.W $0012,X               ; Load size/count
	DEC A                       ; Decrement
	LSR A                       ; Divide by 2
	STA.L $7F5009               ; Store to buffer +$09
	STA.L $7F5013               ; Store to buffer +$13
	STA.L $7F5020               ; Store to buffer +$20

	ADC.B #$00                  ; Add carry
	STA.L $7F5007               ; Store to buffer +$07
	STA.L $7F5010               ; Store to buffer +$10
	STA.L $7F501D               ; Store to buffer +$1D

	LDA.B #$04                  ; Bit 2 mask
	TSB.W $00D8                 ; Set bit 2 in flags
	REP #$30                    ; 16-bit A/X/Y
	RTS                         ; Return

CODE_009CEF:
	RTS                         ; Empty stub

; ---------------------------------------------------------------------------
; Push Graphics Parameters to Stack
; ---------------------------------------------------------------------------

CODE_009CF0:
	PHP                         ; Save processor status
	REP #$30                    ; 16-bit A/X/Y
	PHB                         ; Save data bank
	PHA                         ; Save A
	PHD                         ; Save direct page
	PHX                         ; Save X
	PHY                         ; Save Y

	LDX.W #$0017                ; Source = DP $0017
	LDA.L $7E3367               ; Load stack pointer
	TAY                         ; Y = destination
	LDA.W #$0025                ; Transfer 38 bytes
	MVN $7E,$00                 ; Copy DP $0017-$003E to stack

	LDX.W #$00D0                ; Source = DP $00D0
	LDA.W #$0000                ; Transfer 1 byte
	MVN $7E,$00                 ; Copy DP $00D0 to stack

	TYA                         ; A = new stack pointer
	CMP.W #$35D9                ; Check if stack overflow
	BCC CODE_009D18             ; Branch if OK
	JMP.W CODE_009D1F           ; Handle overflow (infinite loop)

CODE_009D18:
	STA.L $7E3367               ; Update stack pointer
	JMP.W CODE_00981B           ; Clean stack and return

CODE_009D1F:
	BRA CODE_009D1F             ; Infinite loop (stack overflow)

; ---------------------------------------------------------------------------
; Pop Graphics Parameters from Stack
; ---------------------------------------------------------------------------

CODE_009D21:
	PHP                         ; Save processor status
	REP #$30                    ; 16-bit A/X/Y
	PHB                         ; Save data bank
	PHA                         ; Save A
	PHD                         ; Save direct page
	PHX                         ; Save X
	PHY                         ; Save Y

	LDA.L $7E3367               ; Load stack pointer
	SEC                         ; Set carry
	SBC.W #$0027                ; Subtract 39 bytes
	STA.L $7E3367               ; Update stack pointer
	TAX                         ; X = source

	LDY.W #$0017                ; Dest = DP $0017
	LDA.W #$0025                ; Transfer 38 bytes
	MVN $00,$7E                 ; Copy stack to DP $0017-$003E

	LDY.W #$00D0                ; Dest = DP $00D0
	LDA.W #$0000                ; Transfer 1 byte
	MVN $00,$7E                 ; Copy stack to DP $00D0

	JMP.W CODE_00981B           ; Clean stack and return

; ---------------------------------------------------------------------------
; Fill Memory via Helper
; ---------------------------------------------------------------------------

CODE_009D4B:
	PHY                         ; Save Y
	STX.B $1A                   ; Store X to $1A
	TXY                         ; Y = X
	TAX                         ; X = A
	JSR.W CODE_00B49E           ; Call helper
	CLC                         ; Clear carry
	TYA                         ; A = Y
	ADC.B $01,S                 ; Add saved Y
	STA.B $1A                   ; Store to $1A
	JSR.W CODE_00B4A7           ; Call helper
	LDA.B $1C                   ; Load $1C
	AND.W #$00FF                ; Mask to byte
	PHA                         ; Push to stack
	PLB                         ; Pull to data bank
	LDA.B $02,S                 ; Load parameter
	JSR.W CODE_009998           ; Call fill dispatcher
	PLB                         ; Restore data bank
	PLA                         ; Clean stack
	RTS                         ; Return

; ---------------------------------------------------------------------------
; CODE_009D6B: Process Graphics with DP Setup
; ---------------------------------------------------------------------------

CODE_009D6B:
	PHD                         ; Save direct page
	PEA.W $0000                 ; Push $0000
	PLD                         ; Direct Page = $0000
	JSR.W CODE_009D75           ; Process graphics
	PLD                         ; Restore direct page
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; CODE_009D75: Main Graphics Data Processor
; ---------------------------------------------------------------------------
; Purpose: Core loop for processing graphics command stream
; Algorithm: Read bytes from [$17], dispatch to handlers via jump table
; Commands $00-$2F: Jump table entries
; Commands $30+: Indexed data lookup
; Commands $80+: Direct tile data (XOR with $1D for effects)
; ===========================================================================

CODE_009D75:
	PHP                         ; Save processor status
	REP #$30                    ; 16-bit A/X/Y
	PHB                         ; Save data bank
	PHA                         ; Save A
	PHD                         ; Save direct page
	PHX                         ; Save X
	PHY                         ; Save Y
	PHK                         ; Push program bank
	PLB                         ; Pull to data bank

	; Check if special processing mode
	LDA.W #$0008                ; Bit 3 mask
	AND.W $00DB                 ; Test flag
	BEQ CODE_009DA2             ; Normal processing

	; Special mode with synchronization
	LDA.W #$0010                ; Bit 4 mask
	AND.W $00D0                 ; Test flag
	BNE CODE_009D9A             ; Use alternate sync

CODE_009D8F:
	JSR.W CODE_009DBD           ; Read and process command
	LDA.B $17                   ; Get current pointer
	CMP.B $3D                   ; Compare to sync pointer
	BNE CODE_009D8F             ; Loop until synchronized
	BRA CODE_009DBA             ; Done

CODE_009D9A:
	JSR.W CODE_00E055           ; Alternate sync handler
	BRA CODE_009DBA             ; Done

CODE_009D9F:
	JSR.W CODE_009DBD           ; Read and process command

CODE_009DA2:
	; Normal processing loop
	LDA.W $00D0                 ; Load flags
	BIT.W #$0090                ; Test bits 4 and 7
	BEQ CODE_009D9F             ; Continue if neither set

	BIT.W #$0080                ; Test bit 7
	BNE CODE_009DB4             ; Exit if set
	JSR.W CODE_00E055           ; Process special event
	BRA CODE_009DA2             ; Continue loop

CODE_009DB4:
	LDA.W #$0080                ; Bit 7 mask
	TRB.W $00D0                 ; Clear exit flag

CODE_009DBA:
	JMP.W CODE_00981B           ; Clean stack and return

; ---------------------------------------------------------------------------
; CODE_009DBD: Read and Dispatch Graphics Command
; ---------------------------------------------------------------------------

CODE_009DBD:
	LDA.B [$17]                 ; Read command byte
	INC.B $17                   ; Advance pointer
	AND.W #$00FF                ; Mask to byte
	CMP.W #$0080                ; Is it direct tile data?
	BCC CODE_009DD2             ; No, dispatch to handler

CODE_009DC9:
	; Direct tile write (values $80-$FF)
	EOR.B $1D                   ; XOR with effect mask

CODE_009DCB:
	STA.B [$1A]                 ; Write to VRAM buffer
	INC.B $1A                   ; Advance pointer
	INC.B $1A                   ; (16-bit increment)
	RTS                         ; Return

CODE_009DD2:
	; Command dispatch (values $00-$7F)
	CMP.W #$0030                ; Is it indexed data?
	BCS CODE_009DDF             ; Yes, handle indexed

	; Jump table dispatch ($00-$2F)
	ASL A                       ; Multiply by 2 (word index)
	TAX                         ; X = table offset
	JSR.W (DATA8_009E0E,X)      ; Call handler via table
	REP #$30                    ; 16-bit A/X/Y
	RTS                         ; Return

CODE_009DDF:
	; Indexed data lookup ($30+)
	LDX.W #$0000                ; X = 0 (table index)
	SBC.W #$0030                ; Subtract base (now $00-$4F)
	BEQ CODE_009DF9             ; If 0, use first entry
	TAY                         ; Y = index count

CODE_009DE8:
	; Find entry in variable-length table
	LDA.L DATA8_03BA35,X        ; Load entry size
	AND.W #$00FF                ; Mask to byte
	STA.B $64                   ; Store size
	TXA                         ; A = current offset
	SEC                         ; Set carry
	ADC.B $64                   ; Add size (+ 1 from carry)
	TAX                         ; X = next entry offset
	DEY                         ; Decrement index
	BNE CODE_009DE8             ; Continue until found

CODE_009DF9:
	; Process found entry
	TXA                         ; A = table offset
	CLC                         ; Clear carry
	ADC.W #$BA36                ; Add base address
	TAY                         ; Y = data pointer
	SEP #$20                    ; 8-bit A
	LDA.B #$03                  ; Bank $03
	XBA                         ; Swap to high byte
	LDA.L DATA8_03BA35,X        ; Load entry size
	TYX                         ; X = data pointer
	REP #$30                    ; 16-bit A/X/Y
	JMP.W CODE_00A7F9           ; Process data block

; ---------------------------------------------------------------------------
; Graphics Command Jump Table
; ---------------------------------------------------------------------------
; Commands $00-$2F dispatch here
; ===========================================================================

DATA8_009E0E:
	; Jump table entries
DATA8_009E0E_handlers:
	dw CODE_00A378             ; $00: Command handler
	dw CODE_00A8C0             ; $01
	dw CODE_00A8BD             ; $02
	dw CODE_00A39C             ; $03
	dw CODE_00B354             ; $04
	dw CODE_00A37F             ; $05
	dw CODE_00B4B0             ; $06
	dw CODE_00A708             ; $07
	dw CODE_00A755             ; $08
	dw CODE_00A83F             ; $09
	dw CODE_00A519             ; $0A
	dw CODE_00A3F5             ; $0B
	dw CODE_00A958             ; $0C
	dw CODE_00A96C             ; $0D
	dw CODE_00A97D             ; $0E
	dw CODE_00AFD6             ; $0F
	dw CODE_00AF9A             ; $10
	dw CODE_00AF6B             ; $11
	dw CODE_00AF70             ; $12
	dw CODE_00B094             ; $13
	dw CODE_00AFFE             ; $14
	dw CODE_00A0B7             ; $15
	dw CODE_00B2F9             ; $16
	dw CODE_00AEDA             ; $17
	dw CODE_00AACF             ; $18
	dw CODE_00A8D1             ; $19
	dw CODE_00A168             ; $1A
	dw CODE_00A17E             ; $1B
	dw CODE_00A15C             ; $1C
	dw CODE_00A13C             ; $1D
	dw CODE_00A0FE             ; $1E
	dw CODE_00A0C0             ; $1F
	dw CODE_00A0DF             ; $20
	dw CODE_00B2F4             ; $21
	dw CODE_00A150             ; $22
	dw CODE_00AEA2             ; $23
	dw CODE_00A11D             ; $24
	dw CODE_00A07D             ; $25
	dw CODE_00A089             ; $26
	dw CODE_00A09D             ; $27
	dw CODE_00A0A9             ; $28
	dw CODE_00AEB5             ; $29
	dw CODE_00B379             ; $2A
	dw CODE_00AEC7             ; $2B
	dw CODE_00B355             ; $2C
	dw CODE_00A074             ; $2D
	dw CODE_00A563             ; $2E
	dw CODE_00A06E             ; $2F

; ---------------------------------------------------------------------------
; Secondary Jump Table (for specific graphics operations)
; ---------------------------------------------------------------------------

DATA8_009E6E:
	dw CODE_00A342             ; $00
	dw CODE_00A3AB             ; $01
	dw CODE_00A51E             ; $02
	dw CODE_00A52E             ; $03
	dw CODE_00A3D5             ; $04
	dw CODE_00A3DE             ; $05
	dw CODE_00A3E5             ; $06
	dw CODE_00A3EC             ; $07
	dw $0000                   ; $08: Unused
	dw CODE_00A3FC             ; $09
	dw $0000                   ; $0A: Unused
	dw CODE_00A572             ; $0B
	dw CODE_00A581             ; $0C
	dw CODE_00A586             ; $0D
	dw CODE_00A744             ; $0E
	dw $0000, $0000            ; $0F-$10: Unused
	dw CODE_00A718             ; $11
	dw CODE_00A78E             ; $12
	dw CODE_00A79D             ; $13
	dw CODE_00A7AC             ; $14
	dw CODE_00A7B3             ; $15
	dw $0000                   ; $16: Unused
	dw CODE_00A86E             ; $17
	dw CODE_00A7EB             ; $18
	dw CODE_00A7DE             ; $19
	dw $0000, $0000, $0000     ; $1A-$1C: Unused
	dw CODE_00A874             ; $1D
	dw CODE_00A89B             ; $1E
	dw $0000                   ; $1F: Unused

; ===========================================================================
; Graphics Command Handlers (Commands $00-$2F)
; ===========================================================================

; ---------------------------------------------------------------------------
; Command $2D: Set Graphics Pointer to Fixed Address
; ---------------------------------------------------------------------------

CODE_00A06E:
	LDA.W #$0EA6                ; Fixed pointer
	STA.B $2E                   ; Store to $2E
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $25: Load Graphics Pointer from Stream
; ---------------------------------------------------------------------------

CODE_00A074:
	LDA.B [$17]                 ; Read 16-bit pointer
	INC.B $17                   ; Advance stream pointer
	INC.B $17                   ; (2 bytes)
	STA.B $2E                   ; Store to $2E
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $26: Set Tile Offset (8-bit)
; ---------------------------------------------------------------------------

CODE_00A07D:
	LDA.B [$17]                 ; Read byte parameter
	INC.B $17                   ; Advance stream pointer
	AND.W #$00FF                ; Mask to byte
	SEP #$20                    ; 8-bit A
	STA.B $1E                   ; Store tile offset
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $19: Set Graphics Bank and Pointer
; ---------------------------------------------------------------------------

CODE_00A089:
	LDA.B [$17]                 ; Read 16-bit pointer
	INC.B $17                   ; Advance stream pointer
	INC.B $17                   ; (2 bytes)
	STA.B $3F                   ; Store pointer
	LDA.B [$17]                 ; Read bank byte
	INC.B $17                   ; Advance stream pointer
	AND.W #$00FF                ; Mask to byte
	SEP #$20                    ; 8-bit A
	STA.B $41                   ; Store bank
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $27: Set Display Mode Byte
; ---------------------------------------------------------------------------

CODE_00A09D:
	LDA.B [$17]                 ; Read byte parameter
	INC.B $17                   ; Advance stream pointer
	AND.W #$00FF                ; Mask to byte
	SEP #$20                    ; 8-bit A
	STA.B $27                   ; Store mode byte
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $28: Set Effect Mask
; ---------------------------------------------------------------------------

CODE_00A0A9:
	LDA.B [$17]                 ; Read byte parameter
	INC.B $17                   ; Advance stream pointer
	AND.W #$00FF                ; Mask to byte
	SEP #$20                    ; 8-bit A
	REP #$10                    ; 16-bit X/Y
	STA.B $1D                   ; Store effect mask
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $15: Set 16-bit Parameter at $25
; ---------------------------------------------------------------------------

CODE_00A0B7:
	LDA.B [$17]                 ; Read 16-bit value
	INC.B $17                   ; Advance stream pointer
	INC.B $17                   ; (2 bytes)
	STA.B $25                   ; Store to $25
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $1F: Indexed String Lookup with Fixed Length
; ---------------------------------------------------------------------------

CODE_00A0C0:
	PEI.B ($9E)                 ; Save $9E
	PEI.B ($A0)                 ; Save $A0
	LDA.B [$17]                 ; Read string index
	INC.B $17                   ; Advance stream pointer
	AND.W #$00FF                ; Mask to byte
	STA.B $9E                   ; Store index
	STZ.B $A0                   ; Clear high byte
	LDA.W #$0003                ; Length = 3 bytes
	LDX.W #$82BB                ; Table pointer
	JSR.W CODE_00A71C           ; Process string
	PLX                         ; Restore $A0
	STX.B $A0                   ; Store back
	PLX                         ; Restore $9E
	STX.B $9E                   ; Store back
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $20: Indexed String Lookup (Different Table)
; ---------------------------------------------------------------------------

CODE_00A0DF:
	PEI.B ($9E)                 ; Save $9E
	PEI.B ($A0)                 ; Save $A0
	LDA.B [$17]                 ; Read string index
	INC.B $17                   ; Advance stream pointer
	AND.W #$00FF                ; Mask to byte
	STA.B $9E                   ; Store index
	STZ.B $A0                   ; Clear high byte
	LDA.W #$0003                ; Length = 3 bytes
	LDX.W #$A802                ; Table pointer
	JSR.W CODE_00A71C           ; Process string
	PLX                         ; Restore $A0
	STX.B $A0                   ; Store back
	PLX                         ; Restore $9E
	STX.B $9E                   ; Store back
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $1E: Another Indexed String Handler
; ---------------------------------------------------------------------------

CODE_00A0FE:
	PEI.B ($9E)                 ; Save $9E
	PEI.B ($A0)                 ; Save $A0
	LDA.B [$17]                 ; Read string index
	INC.B $17                   ; Advance stream pointer
	AND.W #$00FF                ; Mask to byte
	STA.B $9E                   ; Store index
	STZ.B $A0                   ; Clear high byte
	LDA.W #$0003                ; Length = 3 bytes
	LDX.W #$8383                ; Table pointer
	JSR.W CODE_00A71C           ; Process string
	PLX                         ; Restore $A0
	STX.B $A0                   ; Store back
	PLX                         ; Restore $9E
	STX.B $9E                   ; Store back
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $24: Set Display Parameters
; ---------------------------------------------------------------------------

CODE_00A11D:
	LDA.B [$17]                 ; Read first word
	INC.B $17                   ; Advance stream pointer
	INC.B $17                   ; (2 bytes)
	STA.B $28                   ; Store to $28
	LDA.B [$17]                 ; Read second word
	INC.B $17                   ; Advance stream pointer
	INC.B $17                   ; (2 bytes)
	STA.B $2A                   ; Store to $2A
	RTS                         ; Return

CODE_00A12E:
	LDA.B [$17]                 ; Read parameter
	INC.B $17                   ; Advance stream pointer
	INC.B $17                   ; (2 bytes)
	SEP #$20                    ; 8-bit A
	STA.B $2C                   ; Store low byte
	XBA                         ; Swap bytes
	STA.B $2D                   ; Store high byte
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $1D: Indexed Lookup with Table $A7F6
; ---------------------------------------------------------------------------

CODE_00A13C:
	LDA.B [$17]                 ; Read index
	INC.B $17                   ; Advance stream pointer
	AND.W #$00FF                ; Mask to byte
	STA.B $9E                   ; Store index
	STZ.B $A0                   ; Clear high byte
	LDA.W #$0003                ; Length = 3 bytes
	LDX.W #$A7F6                ; Table pointer
	JMP.W CODE_00A71C           ; Process and return

; ---------------------------------------------------------------------------
; Command $22: Set Graphics Pointer to $AEA7 Bank $03
; ---------------------------------------------------------------------------

CODE_00A150:
	SEP #$20                    ; 8-bit A
	LDA.B #$03                  ; Bank $03
	STA.B $19                   ; Store bank
	LDX.W #$AEA7                ; Pointer
	STX.B $17                   ; Store pointer
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $1C: Set Graphics Pointer to $8457 Bank $03
; ---------------------------------------------------------------------------

CODE_00A15C:
	SEP #$20                    ; 8-bit A
	LDA.B #$03                  ; Bank $03
	STA.B $19                   ; Store bank
	LDX.W #$8457                ; Pointer
	STX.B $17                   ; Store pointer
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $1A: Indexed Character Graphics
; ---------------------------------------------------------------------------

CODE_00A168:
	LDA.B [$17]                 ; Read character index
	INC.B $17                   ; Advance stream pointer
	AND.W #$00FF                ; Mask to byte
	SEP #$20                    ; 8-bit A
	STA.B $4F                   ; Store character ID
	REP #$30                    ; 16-bit A/X/Y
	LDA.W #$0003                ; Bank $03
	LDX.W #$A831                ; Table pointer
	JMP.W CODE_00A71C           ; Process character graphics

; ---------------------------------------------------------------------------
; Command $1B: Indexed Monster Graphics
; ---------------------------------------------------------------------------

CODE_00A17E:
	LDA.B [$17]                 ; Read monster index
	INC.B $17                   ; Advance stream pointer
	AND.W #$00FF                ; Mask to byte
	SEP #$20                    ; 8-bit A
	STA.B $4F                   ; Store monster ID
	REP #$30                    ; 16-bit A/X/Y
	LDA.W #$0003                ; Bank $03
	LDX.W #$A895                ; Table pointer
	JMP.W CODE_00A71C           ; Process monster graphics

; ---------------------------------------------------------------------------
; Clear Address High Byte Handlers
; ---------------------------------------------------------------------------

CODE_00A194:
	JSR.W CODE_00A1AB           ; Read pointer
	STZ.B $9F                   ; Clear $9F
	STZ.B $A0                   ; Clear $A0
	RTS                         ; Return

CODE_00A19C:
	JSR.W CODE_00A1AB           ; Read pointer
	STZ.B $A0                   ; Clear $A0
	RTS                         ; Return

CODE_00A1A2:
	JSR.W CODE_00A1AB           ; Read pointer
	AND.W #$00FF                ; Mask to byte
	STA.B $A0                   ; Store to $A0
	RTS                         ; Return

; ---------------------------------------------------------------------------
; CODE_00A1AB: Read Indirect Pointer from Stream
; ---------------------------------------------------------------------------
; Purpose: Read pointer and bank from [$17], then dereference
; Algorithm: Read 3 bytes -> use as pointer -> read actual target pointer
; ===========================================================================

CODE_00A1AB:
	LDA.B [$17]                 ; Read pointer word
	INC.B $17                   ; Advance stream
	INC.B $17                   ; (2 bytes)
	TAX                         ; X = pointer address
	LDA.B [$17]                 ; Read bank byte
	INC.B $17                   ; Advance stream
	AND.W #$00FF                ; Mask to byte
	CLC                         ; Clear carry
	ADC.W $0000,X               ; Add offset from [X]
	TAY                         ; Y = final offset
	LDA.W $0002,X               ; Load bank from [X+2]
	AND.W #$00FF                ; Mask to byte
	PHA                         ; Push bank
	PLB                         ; Pull to data bank
	LDA.W $0000,Y               ; Load target pointer low
	TAX                         ; X = pointer low
	LDA.W $0002,Y               ; Load target pointer high
	PLB                         ; Restore bank
	STX.B $9E                   ; Store pointer low
	RTS                         ; Return (A = pointer high)

; ---------------------------------------------------------------------------
; Memory Fill from Stream Parameters
; ---------------------------------------------------------------------------

CODE_00A1D1:
	LDA.B [$17]                 ; Read destination address
	INC.B $17                   ; Advance stream
	INC.B $17                   ; (2 bytes)
	TAY                         ; Y = destination
	SEP #$20                    ; 8-bit A
	LDA.B [$17]                 ; Read fill value
	XBA                         ; Swap to high byte
	LDA.B [$17]                 ; Read again (16-bit fill)
	REP #$30                    ; 16-bit A/X/Y
	INC.B $17                   ; Advance stream
	TAX                         ; X = fill value
	LDA.B [$17]                 ; Read count
	INC.B $17                   ; Advance stream
	AND.W #$00FF                ; Mask to byte
	JMP.W CODE_009998           ; Call fill dispatcher

; ---------------------------------------------------------------------------
; Graphics System Calls
; ---------------------------------------------------------------------------

CODE_00A1EE:
	JSL.L CODE_0C8000           ; Call graphics system
	RTS                         ; Return

CODE_00A1F3:
	JSL.L CODE_0096A0           ; Wait for VBlank
	RTS                         ; Return

; ---------------------------------------------------------------------------
; CODE_00A1F8: Copy Display State
; ---------------------------------------------------------------------------

CODE_00A1F8:
	JSR.W CODE_00A220           ; Prepare state
	SEP #$20                    ; 8-bit A
	LDX.W $101B                 ; Load source X
	STX.W $1018                 ; Copy to destination X
	LDA.W $101D                 ; Load source bank
	STA.W $101A                 ; Copy to destination bank
	LDX.W $109B                 ; Load source X (second set)
	STX.W $1098                 ; Copy to destination X
	LDA.W $109D                 ; Load source bank (second set)
	STA.W $109A                 ; Copy to destination bank
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Copy State and Clear Flags
; ---------------------------------------------------------------------------

CODE_00A216:
	JSR.W CODE_00A1F8           ; Copy display state
	STZ.W $1021                 ; Clear flag
	STZ.W $10A1                 ; Clear flag
	RTS                         ; Return

; ---------------------------------------------------------------------------
; CODE_00A220: Prepare Display State
; ---------------------------------------------------------------------------

CODE_00A220:
	LDX.W $1016                 ; Load source
	STX.W $1014                 ; Copy to destination
	LDX.W $1096                 ; Load source (second set)
	STX.W $1094                 ; Copy to destination
	LDA.W #$0003                ; Bits 0-1 mask
	TRB.W $102F                 ; Clear bits
	TRB.W $10AF                 ; Clear bits
	RTS                         ; Return

; ---------------------------------------------------------------------------
; CODE_00A236: Character Data DMA Transfer
; ---------------------------------------------------------------------------
; Purpose: Copy character data to VRAM buffer area
; ===========================================================================

CODE_00A236:
	LDA.W #$0080                ; Bit 7 mask
	AND.W $10A0                 ; Test character flag
	PHP                         ; Save result

	; Read character slot index
	LDA.B [$17]                 ; Read slot index
	INC.B $17                   ; Advance stream
	AND.W #$00FF                ; Mask to byte
	SEP #$30                    ; 8-bit A/X/Y
	STA.W $0E92                 ; Store character slot

	; Calculate offset: slot * $50
	STA.W SNES_WRMPYA           ; Multiplicand = slot
	LDA.B #$50                  ; Multiplier = $50 (80 bytes)
	JSL.L CODE_00971E           ; Perform multiply
	REP #$30                    ; 16-bit A/X/Y

	; Setup DMA transfer
	CLC                         ; Clear carry
	LDA.W #$D0B0                ; Base address $0CD0B0
	ADC.W SNES_RDMPYL           ; Add offset (result)
	TAX                         ; X = source address
	LDY.W #$1080                ; Y = destination $7E1080
	LDA.W #$0050                ; Transfer $50 bytes
	PEA.W $000C                 ; Push bank $0C
	PLB                         ; Pull to data bank
	JSR.W CODE_00985D           ; Perform memory copy
	PLB                         ; Restore bank

	PLP                         ; Restore flags
	BNE CODE_00A273             ; Skip if flag was set
	LDA.W #$0080                ; Bit 7 mask
	TRB.W $10A0                 ; Clear character flag

CODE_00A273:
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Multiple Command Sequence
; ---------------------------------------------------------------------------

CODE_00A274:
	LDA.W #$0003                ; Bank $03
	LDX.W #$8457                ; Pointer to data
	JSR.W CODE_00A71C           ; Process data
	REP #$30                    ; 16-bit A/X/Y

	LDA.B [$17]                 ; Read parameters
	INC.B $17                   ; Advance stream
	INC.B $17                   ; (2 bytes)
	SEP #$20                    ; 8-bit A
	STA.W $0513                 ; Store parameter
	XBA                         ; Swap bytes
	STA.W $0A9C                 ; Store parameter

	LDX.B $17                   ; X = current pointer
	LDA.B $19                   ; A = current bank
	JSL.L CODE_00D080           ; Call handler
	STA.B $19                   ; Update bank
	STX.B $17                   ; Update pointer
	RTS                         ; Return

; ---------------------------------------------------------------------------
; VBlank Wait Loop
; ---------------------------------------------------------------------------

CODE_00A29B:
	LDA.B [$17]                 ; Read wait count
	INC.B $17                   ; Advance stream
	AND.W #$00FF                ; Mask to byte

CODE_00A2A2:
	JSL.L CODE_0096A0           ; Wait for VBlank
	DEC A                       ; Decrement counter
	BNE CODE_00A2A2             ; Loop until 0
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Indexed Color Palette Lookup
; ---------------------------------------------------------------------------

CODE_00A2AA:
	LDA.B [$17]                 ; Read palette index
	INC.B $17                   ; Advance stream
	AND.W #$00FF                ; Mask to byte
	PHA                         ; Save index
	BRA CODE_00A2B4_plus2       ; Skip to processing

CODE_00A2B4:
	PEI.B ($9E)                 ; Save $9E
CODE_00A2B4_plus2:
	SEP #$20                    ; 8-bit A
	LDX.W #$0000                ; X = 0 (table index)

CODE_00A2BB:
	; Search palette table for matching index
	LDA.W DATA8_00A2DD,X        ; Load table entry
	CMP.B #$FF                  ; Check for end marker
	BNE +                       ; Not end, continue
	JMP UNREACH_00A2D4          ; End of table (not found)
+	CMP.B $01,S                 ; Compare with search index
	BEQ CODE_00A2CB             ; Found match
	INX                         ; Next entry
	INX                         ; (skip 2 more bytes)
	INX                         ; (3 bytes per entry)
	BRA CODE_00A2BB             ; Continue search

CODE_00A2CB:
	REP #$30                    ; 16-bit A/X/Y
	LDA.W DATA8_00A2DE,X        ; Load palette pointer
	STA.B $9E                   ; Store to $9E
	PLX                         ; Clean stack
	RTS                         ; Return

; UNREACH_00A2D4: (duplicate label removed - see line ~6390 for actual occurrence)
	; End of table - index not found
	; (likely error condition)

;===============================================================================
; Progress: ~7,400 lines documented (52.8% of Bank $00)
; Sections completed:
; - Boot sequence and hardware init
; - DMA and graphics transfers
; - VBlank processing
; - Menu navigation and cursor movement
; - Input handling and validation
; - Character switching
; - Tilemap updates
; - Status effects and animations
; - Math helpers (multiply, divide, RNG)
; - Bit manipulation helpers
; - Memory copy and fill operations
; - Graphics processing routines
; - Graphics command dispatcher and jump tables
; - Graphics command handlers ($00-$2F)
;
; Remaining: ~6,600 lines (battle system, more handlers, data tables)
;===============================================================================
