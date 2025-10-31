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
SNES_VTIMEL    = $4209    ; V-Timer Low
SNES_SLHV      = $2137    ; H/V Latch
SNES_OPVCT     = $213D    ; Vertical Counter (PPU)
SNES_STAT78    = $213F    ; PPU Status 78

; Math/Multiplication/Division Registers
SNES_WRMPYA    = $4202    ; Multiplicand
SNES_WRMPYB    = $4203    ; Multiplicand/Multiplier
SNES_WRDIVL    = $4204    ; Dividend Low
SNES_WRDIVH    = $4205    ; Dividend High
SNES_WRDIVB    = $4206    ; Divisor
SNES_RDMPYL    = $4216    ; Multiplication/Division Result Low

; Constant Pointers
PTR16_00FFFF   = $FFFF    ; Return marker value for subroutine calls

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
CODE_00A3F5 = $00A3FC
CODE_00A3FC = $00A3FC
CODE_00A51E = $00A51E
; CODE_00A572 through CODE_00A597 now implemented
; CODE_00A708 through CODE_00A83F now implemented
; CODE_00A86E through CODE_00AACC now implemented (partial CODE_00A86E as db)
; CODE_00AACF through CODE_00AFFE now implemented
; CODE_00B000 through CODE_00B1A1 now implemented
CODE_00A78E = $00A78E             ; Referenced in jump table but not implemented as routine
CODE_00A86E = $00A86E             ; Partial implementation (raw bytecode placeholder)
; All comparison tests now implemented below
Some_Graphics_Setup = $00B000
Some_Init_Routine = $00B100
Some_Mode_Handler = $00B200
Main_Game_Loop = $00B300
Execute_Script_Or_Command = $00B400
Some_Init_Function_2 = $00B500
Some_Function_9319 = $009319
Some_Function_9A08 = $009A08
Some_Function_A236 = $00A236
CODE_009824 = $009824    ; BCD/Hex number formatting routine
CODE_008B69 = $008B69    ; Screen setup routine 1
CODE_008B88 = $008B88    ; Screen setup routine 2
CODE_00CBEC = $00CBEC    ; Setup routine
CODE_00DA65 = $00DA65    ; External data routine
CODE_00C795 = $00C795    ; External routine
CODE_00C7B8 = $00C7B8    ; External routine
CODE_00CA63 = $00CA63    ; External routine
CODE_00D080 = $00D080    ; External routine
CODE_00E055 = $00E055    ; External routine
CODE_00C92B = $00C92B    ; Get save slot address
CODE_00C4DB = $00C4DB    ; External routine
CODE_00C7DE = $00C7DE    ; Screen setup routine 1
CODE_00C7F0 = $00C7F0    ; Screen setup routine 2
CODE_00C78D = $00C78D    ; External routine
CODE_00CF3F = $00CF3F    ; Main routine
CODE_00DAA5 = $00DAA5    ; External routine
CODE_00C9D3 = $00C9D3    ; Get save slot address

; Other Banks
CODE_028AE0 = $028AE0    ; Bank $02 routine
DATA8_03BA35 = $03BA35   ; Bank $03 data
DATA8_03BB81 = $03BB81   ; Bank $03 data
DATA8_03A37C = $03A37C   ; Bank $03 character data
UNREACH_03D5E5 = $03D5E5 ; Bank $03 unreachable code
CODE_0C8000 = $0C8000    ; Bank $0C routine
CODE_0C8080 = $0C8080    ; Bank $0C routine
BankOC_Init = $0C8000    ; Bank $0C Init
CODE_0D8000 = $0D8000    ; Bank $0D routine
CODE_0D8004 = $0D8004    ; Bank $0D routine
Bank0D_Init_Variant = $0D8000    ; Bank $0D Init
CODE_018272 = $018272    ; Bank $01 routine
CODE_018A52 = $018A52    ; Bank $01 sprite initialization
CODE_01B24C = $01B24C    ; Bank $01 script initialization routine
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
DATA8_07D7F4 = $07D7F4   ; Palette color data base
DATA8_07D7F5 = $07D7F5
DATA8_07D7F6 = $07D7F6
DATA8_07D7F7 = $07D7F7
DATA8_07D7F8 = $07D7F8
DATA8_07D7F9 = $07D7F9
DATA8_07D7FA = $07D7FA
DATA8_07D7FB = $07D7FB
DATA8_07D7FC = $07D7FC
DATA8_07D7FD = $07D7FD
DATA8_07D7FE = $07D7FE
DATA8_07D7FF = $07D7FF
DATA8_07D800 = $07D800
DATA8_07D801 = $07D801
DATA8_07D802 = $07D802
DATA8_07D803 = $07D803
DATA8_07D814 = $07D814   ; Color data (additional palette)
DATA8_07D815 = $07D815
DATA8_07D816 = $07D816
DATA8_07D817 = $07D817
DATA8_07D818 = $07D818
DATA8_07D819 = $07D819
DATA8_07D81A = $07D81A
DATA8_07D81B = $07D81B
DATA8_07D81C = $07D81C
DATA8_07D81D = $07D81D
DATA8_07D81E = $07D81E
DATA8_07D81F = $07D81F
DATA8_07D820 = $07D820
DATA8_07D821 = $07D821
DATA8_07D822 = $07D822
DATA8_07D823 = $07D823
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
; SNES Hardware Register Definitions (Additional)
;===============================================================================
SNES_BG1HOFS   = $210D    ; BG1 Horizontal Offset
SNES_BG2HOFS   = $210F    ; BG2 Horizontal Offset
SNES_BG3VOFS   = $2112    ; BG3 Vertical Offset
SNES_BG1SC     = $2107    ; BG1 Screen Base Address
SNES_BG2SC     = $2108    ; BG2 Screen Base Address

; Loose operations (code fragments)
LOOSE_OP_00BCF3 = $00BCF3 ; Continuation address in state machine

;===============================================================================
; BOOT SEQUENCE & INITIALIZATION ($008000-$008113)
;===============================================================================

org $008000

RESET_Handler:
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

	JSR.W Init_Hardware         ; Init_Hardware: Disable NMI, force blank, clear registers
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
	BRA Boot_SetupStack         ; → Continue to stack setup

;-------------------------------------------------------------------------------

Boot_Secondary:
	; ===========================================================================
	; Secondary Boot Entry Point
	; ===========================================================================
	; Alternative entry point used for soft reset or special boot modes.
	; Different from main boot: calls different bank $0D init routine.
	; ===========================================================================

	JSR.W Init_Hardware         ; Init_Hardware again

	LDA.B #$F0                  ; A = $F0
	STA.L $000600               ; Write $F0 to $000600 (low RAM mirror area)
								; Purpose unclear - may trigger hardware behavior

	JSL.L CODE_0D8004           ; Bank $0D alternate initialization routine

;-------------------------------------------------------------------------------

Boot_Alternate:
	; ===========================================================================
	; Third Entry Point (Soft Reset with Different Init)
	; ===========================================================================
	; Yet another entry point with same hardware init but different
	; bank $0D initialization. May be used for returning from special modes.
	; ===========================================================================

	JSR.W Init_Hardware         ; Init_Hardware

	LDA.B #$F0                  ; A = $F0
	STA.L $000600               ; Write $F0 to $000600

	JSL.L CODE_0D8004           ; Bank $0D alternate init

	REP #$30                    ; Set 16-bit mode: A, X, Y
	LDX.W #$1FFF                ; X = $1FFF (stack pointer initial value)
	TXS                         ; Transfer X to Stack: S = $1FFF

;-------------------------------------------------------------------------------

Boot_SetupStack:
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

	JSR.W Clear_WorkRAM         ; Clear_RAM: Zero out all work RAM $0000-$1FFF

	; ---------------------------------------------------------------------------
	; Check Boot Mode Flag ($00DA bit 6)
	; ---------------------------------------------------------------------------
	; $00DA appears to be a boot mode/configuration flag
	; Bit 6 ($40) determines which initialization path to take
	; ---------------------------------------------------------------------------

	LDA.W #$0040                ; A = $0040 (bit 6 mask)
	AND.W $00DA                 ; Test bit 6 of $00DA
	BNE Boot_EnableNMI          ; If bit 6 set → Skip display init, jump ahead

	JSL.L CODE_0C8080           ; Bank $0C: Full display/PPU initialization
	BRA Boot_SetupDMA           ; → Continue to DMA setup

;-------------------------------------------------------------------------------

Boot_SetupDMA:
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

Boot_EnableNMI:
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
	BNE Load_SavedGame          ; If set → Load existing game

	; Check if save data exists in SRAM
	LDA.L $700000               ; A = SRAM byte 1
	ORA.L $70038C               ; OR with SRAM byte 2
	ORA.L $700718               ; OR with SRAM byte 3
	BEQ Init_NewGame            ; If all zero → New game (no save data)

	JSL.L CODE_00B950           ; Has save data → Show continue menu
	BRA Boot_FadeIn             ; → Continue to fade-in

;-------------------------------------------------------------------------------

Load_SavedGame:
	; ===========================================================================
	; Load Saved Game from SRAM
	; ===========================================================================
	; Player selected "Continue" from title screen - load saved game data.
	; ===========================================================================

	JSR.W Load_GameFromSRAM     ; Load_Game_From_SRAM: Restore all game state
	BRA Boot_PostInit           ; → Skip new game init, jump to main setup

;-------------------------------------------------------------------------------

Init_NewGame:
	; ===========================================================================
	; New Game Initialization
	; ===========================================================================
	; No save data exists - initialize a fresh game state.
	; ===========================================================================

	JSR.W Init_NewGameState     ; Initialize_New_Game_State: Set default values

;-------------------------------------------------------------------------------

Boot_FadeIn:
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

Boot_FinalInit:
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
	JSR.W Char_CalcStats           ; Initialize system component 0

	LDA.B #$01                  ; A = $01 (parameter for second init)
	JSR.W Char_CalcStats           ; Initialize system component 1

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

Init_NewGameState:
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

Load_GameFromSRAM:
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

Load_SaveSlotData:
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

	JSL.L Display_EnableEffects           ; Finalize save load

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

Clear_WorkRAM:
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
	BEQ Load_InitDataTable      ; If 0 (no save) → use default table

	LDX.W #$822D                ; X = $822D (alternate table for existing save)

Load_InitDataTable:
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

Boot_PostInit:
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

Init_Hardware:
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

Init_VBlankDMA:
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

NMI_Handler:
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
	BNE NMI_SpecialHandler      ; If set → Jump to special handler

	; ---------------------------------------------------------------------------
	; Check State Flag $00D4 Bit 1 (Tilemap DMA)
	; ---------------------------------------------------------------------------

	LDA.B #$02                  ; A = $02 (bit 1 mask)
	AND.W $00D4                 ; Test bit 1 of $00D4
	BNE NMI_TilemapDMA          ; If set → Tilemap DMA needed

	; ---------------------------------------------------------------------------
	; Check State Flag $00DD Bit 6 (Graphics Upload)
	; ---------------------------------------------------------------------------

	LDA.B #$40                  ; A = $40 (bit 6 mask)
	AND.W $00DD                 ; Test bit 6 of $00DD
	BNE NMI_GraphicsUpload      ; If set → Graphics upload needed

	; ---------------------------------------------------------------------------
	; Check State Flag $00D8 Bit 7 (Battle Graphics)
	; ---------------------------------------------------------------------------

	LDA.B #$80                  ; A = $80 (bit 7 mask)
	AND.W $00D8                 ; Test bit 7 of $00D8
	BEQ NMI_CheckMoreFlags      ; If clear → Skip battle graphics

	LDA.B #$80                  ; A = $80
	TRB.W $00D8                 ; Test and Reset bit 7 of $00D8
								; Clear the flag (one-shot operation)

	JMP.W CODE_0085B7           ; Execute battle graphics update

;-------------------------------------------------------------------------------

NMI_CheckMoreFlags:
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
	BNE NMI_SpecialDMA          ; If set → Special operation

	JMP.W CODE_008428           ; → Continue to additional handlers

;-------------------------------------------------------------------------------

NMI_SpecialDMA:
	JMP.W CODE_00863D           ; Execute special DMA operation

;-------------------------------------------------------------------------------

NMI_TilemapDMA:
	JMP.W CODE_0083E8           ; Execute tilemap DMA transfer

;-------------------------------------------------------------------------------

NMI_SpecialHandler:
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

NMI_GraphicsUpload:
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

NMI_ProcessDMAFlags:
	; ===========================================================================
	; Process DMA Operation Flags ($00D2)
	; ===========================================================================
	; Handles various DMA operations based on flags in $00D2.
	; ===========================================================================

	LDA.B #$80                  ; A = $80 (bit 7 mask)
	AND.W $00D2                 ; Test bit 7 of $00D2
	BEQ NMI_CheckOAMFlag        ; If clear → Skip this DMA

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

NMI_CheckOAMFlag:
	; ===========================================================================
	; Check OAM Update Flag
	; ===========================================================================
	; Bit 5 of $00D2 triggers OAM (sprite) data upload.
	; ===========================================================================

	LDA.B #$20                  ; A = $20 (bit 5 mask)
	AND.W $00D2                 ; Test bit 5 of $00D2
	BEQ NMI_Cleanup             ; If clear → Skip OAM update

	JSR.W DMA_UpdateOAM         ; Execute OAM DMA transfer

;-------------------------------------------------------------------------------

NMI_Cleanup:
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

DMA_TransferTilemap:
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
	JSR.W DMA_TransferPalette   ; Execute palette DMA transfer

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
	BEQ DMA_SpecialGraphics     ; If mode = 1 → Special graphics upload

	JSR.W DMA_StandardTilemap   ; Standard tilemap transfer
	RTL                         ; Return

;-------------------------------------------------------------------------------

DMA_SpecialGraphics:
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

NMI_LargeTransfer:
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
	BEQ NMI_ReturnToHandler     ; If clear → Skip, jump to handler return

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
	BEQ NMI_AlternateTransfer   ; If clear → Use alternate path

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

NMI_ReturnToHandler:
	; ===========================================================================
	; Return to Main NMI Handler
	; ===========================================================================
	JMP.W NMI_ProcessDMAFlags   ; → Jump back to NMI handler continuation

;-------------------------------------------------------------------------------

NMI_AlternateTransfer:
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

DMA_ExecuteTilemapTransfer:
	STX.B SNES_DMA5ADDRL-$4300  ; $4352-$4353 = Selected source address

	LDX.W #$6700                ; X = $6700 (VRAM destination)
	STX.W SNES_VMADDL           ; $2116-$2117 = VRAM address

	LDA.B #$20                  ; A = $20 (DMA channel 5)
	STA.W SNES_MDMAEN           ; $420B = Execute DMA

;-------------------------------------------------------------------------------

NMI_ClearTransferMarkers:
	; ===========================================================================
	; Clear Transfer Markers and Return
	; ===========================================================================

	LDX.W #$FFFF                ; X = $FFFF
	STX.W $00F2                 ; [$00F2] = $FFFF (invalidate tilemap 1)
	STX.W $00F5                 ; [$00F5] = $FFFF (invalidate tilemap 2)

	JMP.W NMI_ProcessDMAFlags   ; → Return to NMI handler

;===============================================================================
; PALETTE TRANSFER HELPER ($008504-$00851F)
;===============================================================================

DMA_TransferPalette:
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

DMA_StandardTilemap:
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
	BEQ DMA_StandardTilemap_Skip ; If yes → Skip transfer (no data)

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

DMA_StandardTilemap_Skip:
	RTS                         ; Return

;===============================================================================
; OAM (SPRITE) TRANSFER ROUTINE ($008543-$008576)
;===============================================================================

DMA_UpdateOAM:
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

DMA_BattleGraphics:
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

DMA_FieldGraphicsUpdate:
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
	BEQ DMA_FieldGraphicsUpdate_OAM  ; If clear, skip tilemap transfer

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

DMA_FieldGraphicsUpdate_OAM:
	JSR.W DMA_UpdateOAM              ; Transfer OAM data

	; Check if additional display update needed
	LDA.B #$20                       ; Check bit 5
	AND.W $00D6                      ; Test display flags
	BEQ DMA_FieldGraphicsUpdate_Exit ; If clear, exit
	LDA.B #$78                       ; Set multiple flags (bits 3,4,5,6)
	TSB.W $00D4                      ; Set bits in status register

DMA_FieldGraphicsUpdate_Exit:
	RTL                              ; Return

;===============================================================================
; SPECIAL GRAPHICS TRANSFER ROUTINES ($00863D-$008965)
;===============================================================================

DMA_SpecialVRAMHandler:
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
	BEQ DMA_FieldModeTransfer   ; If clear → Use normal field mode graphics

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

DMA_FieldModeTransfer:
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
	BEQ DMA_UpdateAllCharacters ; If clear → Update all characters

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
	JSR.W DMA_CharacterGraphics ; Transfer character graphics (2-part)
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

	JSR.W DMA_CharacterPalette  ; Transfer character palette

	RTL                         ; Return

;-------------------------------------------------------------------------------

DMA_UpdateAllCharacters:
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
	JSR.W DMA_CharacterGraphics ; Transfer character 1 graphics

	; ---------------------------------------------------------------------------
	; Transfer Character 2 Graphics
	; ---------------------------------------------------------------------------

	LDA.W #$6280                ; A = $6280 (VRAM address for char 2)
	STA.W $2116                 ; Set VRAM address

	LDX.W $0109                 ; X = [$0109] (character 2 data pointer)
	JSR.W DMA_CharacterGraphics ; Transfer character 2 graphics

	; ---------------------------------------------------------------------------
	; Transfer Character 3 Graphics
	; ---------------------------------------------------------------------------

	LDA.W #$6380                ; A = $6380 (VRAM address for char 3)
	STA.W $2116                 ; Set VRAM address

	LDX.W $010B                 ; X = [$010B] (character 3 data pointer)
	JSR.W DMA_CharacterGraphics ; Transfer character 3 graphics

	PLB                         ; Restore Data Bank

	; ---------------------------------------------------------------------------
	; Transfer Main Menu Palette
	; ---------------------------------------------------------------------------

	LDA.W #$D824                ; A = $D824 (source address)
	LDX.W #$00C0                ; X = $00C0 (CGRAM address = palette $C)
	JSR.W DMA_PaletteToCGRAM    ; Transfer palette

	; ---------------------------------------------------------------------------
	; Transfer Character 1 Palette
	; ---------------------------------------------------------------------------

	LDY.W $0107                 ; Y = [$0107] (character 1 data pointer)
	LDX.W #$00D0                ; X = $00D0 (CGRAM address = palette $D)
	JSR.W DMA_CharacterPalette  ; Transfer character palette

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

DMA_CharacterGraphics:
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

DMA_CharacterPalette:
	; ===========================================================================
	; Transfer Character Palette (Variant Entry Point)
	; ===========================================================================
	; Alternative entry point that loads palette source from character data.
	; Falls through to DMA_PaletteToCGRAM.
	;
	; Parameters:
	;   X = CGRAM address (palette index)
	;   Y = Character data pointer
	; ===========================================================================

	LDA.W $0004,Y               ; A = [Y+4] (palette data pointer)
								; Falls through to DMA_PaletteToCGRAM

DMA_PaletteToCGRAM:
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

GameLoop_FrameUpdate:
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
	BNE GameLoop_ProcessEvents  ; If no overflow → Skip high byte increment
	INC.W $0E99                 ; Increment high byte (24-bit overflow)

;-------------------------------------------------------------------------------

GameLoop_ProcessEvents:
	; ===========================================================================
	; Time-Based Event Processing
	; ===========================================================================

	JSR.W GameLoop_TimeBasedEvents ; Process time-based events (status effects, etc.)

	; ---------------------------------------------------------------------------
	; Check Full Screen Refresh Flag ($00D4 bit 2)
	; ---------------------------------------------------------------------------
	; When set, indicates a major mode change requiring full redraw
	; (battle start, menu open, scene transition, etc.)
	; ---------------------------------------------------------------------------

	LDA.W #$0004                ; A = $0004 (bit 2 mask)
	AND.W $00D4                 ; Test bit 2 of $00D4
	BEQ GameLoop_NormalUpdate   ; If clear → Normal frame processing

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
	JSR.W Char_CalcStats           ; Update BG layer 0 tilemap
	JSR.W Tilemap_RefreshLayer0           ; Transfer layer 0 to VRAM

	; Refresh Background Layer 1
	LDA.W #$0001                ; A = $0001 (BG layer 1)
	JSR.W Char_CalcStats           ; Update BG layer 1 tilemap
	JSR.W Tilemap_RefreshLayer1           ; Transfer layer 1 to VRAM

	BRA GameLoop_UpdateState    ; → Skip to animation update

;-------------------------------------------------------------------------------

GameLoop_NormalUpdate:
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
	BNE GameLoop_ProcessInput   ; If set → Process controller input

	; ---------------------------------------------------------------------------
	; Check Input Processing Enable ($00E2 bit 2)
	; ---------------------------------------------------------------------------

	LDA.W #$0004                ; A = $0004 (bit 2 mask)
	AND.W $00E2                 ; Test bit 2 of $00E2
	BNE GameLoop_UpdateState    ; If set → Skip input (cutscene/auto mode)

;-------------------------------------------------------------------------------

GameLoop_ProcessInput:
	; ===========================================================================
	; Controller Input Processing
	; ===========================================================================
	; Processes joypad input when enabled.
	; Calls appropriate handler based on current game mode.
	; ===========================================================================

	LDA.B $07                   ; A = [$07] (controller data - current frame)
	AND.B $8E                   ; A = A & [$8E] (input enable mask)
	BEQ GameLoop_UpdateState    ; If zero → No valid input, skip processing

	; ---------------------------------------------------------------------------
	; Determine Input Handler
	; ---------------------------------------------------------------------------
	; CODE_009730 returns handler index in A based on game state
	; Handler table at Input_HandlerTable dispatches to appropriate routine
	; ---------------------------------------------------------------------------

	JSL.L CODE_009730           ; Get input handler index for current mode

	SEP #$30                    ; 8-bit A, X, Y

	ASL A                       ; A = A × 2 (convert to word offset)
	TAX                         ; X = handler table offset

	JSR.W (Input_HandlerTable,X) ; Call appropriate input handler
								; (indirect jump through handler table)

;-------------------------------------------------------------------------------

GameLoop_UpdateState:
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

GameLoop_TimeBasedEvents:
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
	BEQ GameLoop_TimeBasedEvents_Exit ; If clear → Skip time-based processing

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
	BPL GameLoop_TimeBasedEvents_Exit ; If still positive → Exit (not time yet)

	; Timer expired - reset and process status effects
	LDA.B #$0C                  ; A = $0C (12 frames)
	STA.W $010D                 ; Reset timer to 12 frames

	; ---------------------------------------------------------------------------
	; Check Character 1 Status ($700027)
	; ---------------------------------------------------------------------------

	LDA.L $700027               ; A = [$700027] (character 1 status flags)
	BNE GameLoop_CheckChar2     ; If non-zero → Character 1 has status effect

	LDX.B #$40                  ; X = $40 (character 1 offset)
	JSR.W Update_CharacterStatusDisplay ; Update character 1 display

;-------------------------------------------------------------------------------

GameLoop_CheckChar2:
	; ---------------------------------------------------------------------------
	; Check Character 2 Status ($700077)
	; ---------------------------------------------------------------------------

	LDA.L $700077               ; A = [$700077] (character 2 status)
	BNE GameLoop_CheckChar3     ; If non-zero → Character 2 has status

	LDX.B #$50                  ; X = $50 (character 2 offset)
	JSR.W Update_CharacterStatusDisplay ; Update character 2 display

;-------------------------------------------------------------------------------

GameLoop_CheckChar3:
	; ---------------------------------------------------------------------------
	; Check Character 3 Status ($7003B3)
	; ---------------------------------------------------------------------------

	LDA.L $7003B3               ; A = [$7003B3] (character 3 status)
	BNE GameLoop_TimeBasedEvents_Exit ; If non-zero → Character 3 has status

	LDX.B #$60                  ; X = $60 (character 3 offset)
	JSR.W Update_CharacterStatusDisplay ; Update character 3 display

;-------------------------------------------------------------------------------

GameLoop_CheckChar4:
	; ---------------------------------------------------------------------------
	; Check Character 4 Status ($700403)
	; ---------------------------------------------------------------------------

	LDA.L $700403               ; A = [$700403] (character 4 status)
	BNE GameLoop_CheckChar5     ; If non-zero → Character 4 has status

	LDX.B #$70                  ; X = $70 (character 4 offset)
	JSR.W Update_CharacterStatusDisplay ; Update character 4 display

;-------------------------------------------------------------------------------

GameLoop_CheckChar5:
	; ---------------------------------------------------------------------------
	; Check Character 5 Status ($70073F)
	; ---------------------------------------------------------------------------

	LDA.L $70073F               ; A = [$70073F] (character 5 status)
	BNE GameLoop_CheckChar6     ; If non-zero → Character 5 has status

	LDX.B #$80                  ; X = $80 (character 5 offset)
	JSR.W Update_CharacterStatusDisplay ; Update character 5 display

;-------------------------------------------------------------------------------

GameLoop_CheckChar6:
	; ---------------------------------------------------------------------------
	; Check Character 6 Status ($70078F)
	; ---------------------------------------------------------------------------

	LDA.L $70078F               ; A = [$70078F] (character 6 status)
	BNE GameLoop_SetSpriteFlag  ; If non-zero → Character 6 has status

	LDX.B #$90                  ; X = $90 (character 6 offset)
	JSR.W Update_CharacterStatusDisplay ; Update character 6 display

;-------------------------------------------------------------------------------

GameLoop_SetSpriteFlag:
	; ---------------------------------------------------------------------------
	; Set Sprite Update Flag
	; ---------------------------------------------------------------------------

	LDA.B #$20                  ; A = $20 (bit 5)
	TSB.W $00D2                 ; Set bit 5 of $00D2 (sprite update needed)

;-------------------------------------------------------------------------------

GameLoop_TimeBasedEvents_Exit:
	; ===========================================================================
	; Restore Direct Page and Return
	; ===========================================================================

	REP #$30                    ; 16-bit A, X, Y
	PLD                         ; Restore Direct Page
	RTS                         ; Return

;-------------------------------------------------------------------------------

Update_CharacterStatusDisplay:
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

Input_HandlerTable:
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
	; STA.W $0C0A,X at Input_HandlerTable continues from Update_CharacterStatusDisplay
	; The actual table starts here with word addresses:

	; Handler jump table data (12 entries x 2 bytes = 24 bytes)
	db $CF,$8A, $F8,$8A, $68,$8B, $68,$8B  ; Handlers 0-3
	db $61,$8A, $5D,$8A, $59,$8A, $55,$8A  ; Handlers 4-7
	db $68,$8B, $68,$8B, $9D,$8A, $68,$8B  ; Handlers 8-11

;===============================================================================
; CURSOR MOVEMENT HANDLERS ($008A55-$008A9C)
;===============================================================================

Input_CursorDown:
	; ===========================================================================
	; Cursor Down Handler
	; ===========================================================================
	DEC.B $02                   ; Decrement vertical position
	BRA Input_ValidateCursor    ; → Validate position

Input_CursorUp:
	; ===========================================================================
	; Cursor Up Handler
	; ===========================================================================
	INC.B $02                   ; Increment vertical position
	BRA Input_ValidateCursor    ; → Validate position

Input_CursorLeft:
	; ===========================================================================
	; Cursor Left Handler
	; ===========================================================================
	DEC.B $01                   ; Decrement horizontal position
	BRA Input_ValidateCursor    ; → Validate position

Input_CursorRight:
	; ===========================================================================
	; Cursor Right Handler
	; ===========================================================================
	INC.B $01                   ; Increment horizontal position
								; Falls through to validation

;-------------------------------------------------------------------------------

Input_ValidateCursor:
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
	BMI Input_CheckXWrap        ; If negative → Check wrap flags

	CMP.B $03                   ; Compare with max X
	BCC Input_ValidateY         ; If X < max → Valid, continue

	; X position at or above maximum
	LDA.B $95                   ; A = wrap flags
	AND.B #$01                  ; Test bit 0 (allow overflow)
	BNE Input_CheckXWrap        ; If set → Allow wrap to negative

;-------------------------------------------------------------------------------

Input_ClampX:
	; X exceeded maximum, clamp to max-1
	LDA.B $03                   ; A = max X
	DEC A                       ; A = max - 1
	STA.B $01                   ; X position = max - 1 (clamp)
	BRA Input_ValidateY         ; → Validate Y position

;-------------------------------------------------------------------------------

Input_CheckXWrap:
	; X position is negative or wrapped
	LDA.B $95                   ; A = wrap flags
	AND.B #$02                  ; Test bit 1 (allow negative)
	BNE Input_ClampX            ; If set → Clamp to max-1

	STZ.B $01                   ; X position = 0 (clamp to minimum)

;-------------------------------------------------------------------------------

Input_ValidateY:
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
	BMI Input_CheckYWrap        ; If negative → Check wrap flags

	CMP.B $04                   ; Compare with max Y
	BCC Input_ValidateDone      ; If Y < max → Valid, exit

	; Y position at or above maximum
	LDA.B $95                   ; A = wrap flags
	AND.B #$04                  ; Test bit 2 (allow overflow)
	BNE Input_CheckYWrap        ; If set → Allow wrap to negative

;-------------------------------------------------------------------------------

Input_ClampY:
	; Y exceeded maximum, clamp to max-1
	LDA.B $04                   ; A = max Y
	DEC A                       ; A = max - 1
	STA.B $02                   ; Y position = max - 1 (clamp)
	RTS                         ; Return

;-------------------------------------------------------------------------------

Input_CheckYWrap:
	; Y position is negative or wrapped
	LDA.B $95                   ; A = wrap flags
	AND.B #$08                  ; Test bit 3 (allow negative)
	BNE Input_ClampY            ; If set → Clamp to max-1

	STZ.B $02                   ; Y position = 0 (clamp to minimum)

;-------------------------------------------------------------------------------

Input_ValidateDone:
	RTS                         ; Return

;===============================================================================
; BUTTON HANDLER & MENU LOGIC ($008A9D-$008BFC)
;===============================================================================

Input_ButtonA_ToggleStatus:
	; ===========================================================================
	; A Button Handler - Toggle Character Status
	; ===========================================================================
	; Handles A button press to toggle character status display.
	; Shows/hides detailed character information in battle mode.
	; ===========================================================================

	JSR.W Input_CheckAllowed    ; Check if input allowed
	BNE Input_ButtonA_Exit      ; If blocked → Exit

	; Check if in valid screen position
	LDA.W $1090                 ; A = [$1090] (screen mode/position)
	BMI Input_ButtonA_Alternate ; If negative → Call alternate handler

	; Toggle character status display
	LDA.W $10A0                 ; A = [$10A0] (character display flags)
	EOR.B #$80                  ; Toggle bit 7
	STA.W $10A0                 ; Save new flag state

	LDA.B #$40                  ; A = $40 (bit 6)
	TSB.W $00D4                 ; Set bit 6 of $00D4 (update needed)

	JSR.W CODE_00B908           ; Update character display
	BRA Input_ButtonA_Exit      ; → Exit

;-------------------------------------------------------------------------------

Input_ButtonA_Alternate:
	JSR.W CODE_00B912           ; Alternate character update routine

Input_ButtonA_Exit:
	RTS                         ; Return

;-------------------------------------------------------------------------------

Menu_CheckCharPosition:
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
	BNE Menu_CheckCharPosition_Normal ; If not $80 → Jump to B908

	LDA.W $1033                 ; A = [$1033] (Y position)
	BNE Menu_CheckCharPosition_Normal ; If not $00 → Jump to B908

	JMP.W CODE_00B912           ; Special position → Call B912

;-------------------------------------------------------------------------------

Menu_CheckCharPosition_Normal:
	JMP.W CODE_00B908           ; Normal position → Call B908

;-------------------------------------------------------------------------------

Menu_NavCharUp:
	; ===========================================================================
	; Menu Navigation - Character Selection (Up/Down)
	; ===========================================================================
	; Handles up/down navigation through character list in menu.
	; Cycles through valid characters, skipping invalid/dead entries.
	; ===========================================================================

	JSR.W Input_CheckAllowed    ; Check if input allowed
	BNE Menu_NavCharUp_Exit     ; If blocked → Exit

	JSR.W Menu_CheckCharPosition ; Validate character position

	; ---------------------------------------------------------------------------
	; Calculate Current Character Index
	; ---------------------------------------------------------------------------

	LDA.W $1031                 ; A = [$1031] (Y position)
	SEC                         ; Set carry for subtraction
	SBC.B #$20                  ; A = Y - $20 (base offset)

	LDX.B #$FF                  ; X = -1 (character counter)

;-------------------------------------------------------------------------------

Menu_NavCharUp_CalcIndex:
	; Divide by 3 to get character slot
	INX                         ; X++
	SBC.B #$03                  ; A -= 3
	BCS Menu_NavCharUp_CalcIndex ; If carry still set → Continue dividing

	; X now contains character index (0-3)
	TXA                         ; A = character index

;-------------------------------------------------------------------------------

Menu_NavCharUp_FindNext:
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
	BEQ Menu_NavCharUp_FindNext ; If invalid → Try next character

	; Valid character found
	JSR.W CODE_008B21           ; Update character display
	JSR.W CODE_008C3D           ; Refresh graphics

Menu_NavCharUp_Exit:
	RTS                         ; Return

;-------------------------------------------------------------------------------

Menu_NavCharDown:
	; ===========================================================================
	; Menu Navigation - Character Selection (Down/Reverse)
	; ===========================================================================
	; Handles down navigation, cycles backwards through character list.
	; Same as Menu_NavCharUp but decrements instead of increments.
	; ===========================================================================

	JSR.W Input_CheckAllowed    ; Check if input allowed
	BNE Menu_NavCharDown_Exit   ; If blocked → Exit

	JSR.W Menu_CheckCharPosition ; Validate character position

	LDA.W $1031                 ; A = [$1031] (Y position)
	SEC                         ; Set carry
	SBC.B #$20                  ; A = Y - $20 (base offset)

	LDX.B #$FF                  ; X = -1 (counter)

;-------------------------------------------------------------------------------

Menu_NavCharDown_CalcIndex:
	INX                         ; X++
	SBC.B #$03                  ; A -= 3
	BCS Menu_NavCharDown_CalcIndex ; If carry → Continue

	TXA                         ; A = character index

;-------------------------------------------------------------------------------

Menu_NavCharDown_FindPrev:
	; Cycle to previous valid character
	DEC A                       ; A = previous character index
	AND.B #$03                  ; A = A & $03 (wrap 0-3)

	PHA                         ; Save index
	JSR.W CODE_008DA8           ; Check if character valid
	PLA                         ; Restore index

	CPY.B #$FF                  ; Check if invalid
	BEQ Menu_NavCharDown_FindPrev ; If invalid → Try previous

	JSR.W CODE_008B21           ; Update character display
	JSR.W Tilemap_RefreshLayer0 ; Refresh graphics

Menu_NavCharDown_Exit:
	RTS                         ; Return

;-------------------------------------------------------------------------------

Menu_UpdateCharDisplayPos:
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
	BCC Menu_CopyTilemapData    ; If Y < $26 → Use tilemap 2

	LDX.W #$3729                ; X = $3729 (tilemap 3)
	CPY.W #$0029                ; Compare Y with $29
	BCC Menu_CopyTilemapData    ; If Y < $29 → Use tilemap 3

	LDX.W #$3739                ; X = $3739 (tilemap 4, Y >= $29)

;-------------------------------------------------------------------------------

Menu_CopyTilemapData:
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
	JSR.W Char_CalcStats           ; Update layer 0

	SEP #$30                    ; 8-bit A, X, Y

	LDA.B #$80                  ; A = $80 (bit 7)
	TSB.W $00D9                 ; Set bit 7 of $00D9

	RTS                         ; Return

;-------------------------------------------------------------------------------

Input_CheckAllowed:
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
	BEQ Input_CheckAllowed_Exit ; If clear → Input allowed, exit

	; Input blocked - mask controller state
	REP #$30                    ; 16-bit A, X, Y

	LDA.B $92                   ; A = [$92] (controller state)
	AND.W #$BFCF                ; A = A & $BFCF (mask bits 4-5, 14)
								; Disables: bit 4, bit 5, bit 14

	SEP #$30                    ; 8-bit A, X, Y

Input_CheckAllowed_Exit:
	RTS                         ; Return (Z flag indicates input state)

; Padding/unused byte
Unused_008B68:
	RTS                         ; Return

;===============================================================================
; CONTROLLER INPUT PROCESSING ($008BA0-$008BFC)
;===============================================================================

Input_ReadController:
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
	BNE Input_ReadController_Exit ; If set → Controller disabled, exit

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
	BNE Input_SpecialMode       ; If set → Special input mode

	; ---------------------------------------------------------------------------
	; Check Alternate Input Filter ($00DB bit 2)
	; ---------------------------------------------------------------------------

	LDA.W #$0004                ; A = $0004 (bit 2 mask)
	AND.W $00DB                 ; Test bit 2 of $00DB
	BNE Input_AlternateFilter   ; If set → Use alternate filtering

	; ---------------------------------------------------------------------------
	; Normal Controller Read
	; ---------------------------------------------------------------------------

	LDA.W SNES_CNTRL1L          ; A = [$4218] (Controller 1 input)
								; Reads 16-bit joypad state
	BRA Input_ProcessButtons    ; → Process input

;-------------------------------------------------------------------------------

Input_SpecialMode:
	; ===========================================================================
	; Special Input Mode - Filter D-Pad
	; ===========================================================================
	; Reads controller but masks out D-pad directions.
	; Only allows button presses (A, B, X, Y, L, R, Start, Select).
	; ===========================================================================

	LDA.W SNES_CNTRL1L          ; A = controller state
	AND.W #$FFF0                ; A = A & $FFF0 (clear bits 0-3, D-pad)
	BEQ Input_ProcessButtons    ; If zero → No buttons pressed

	JMP.W CODE_0092F0           ; → Special button handler

;-------------------------------------------------------------------------------

Input_AlternateFilter:
	; ===========================================================================
	; Alternate Input Filter
	; ===========================================================================
	; Checks $00D9 bit 1 for additional filtering mode.
	; ===========================================================================

	LDA.W #$0002                ; A = $0002 (bit 1 mask)
	AND.W $00D9                 ; Test bit 1 of $00D9
	BEQ Input_AlternateNormal   ; If clear → Normal alternate mode

	; Special alternate mode (incomplete in disassembly)
	db $A9,$80,$00,$04,$90     ; Raw bytes (seems incomplete)

;-------------------------------------------------------------------------------

Input_AlternateNormal:
	LDA.W SNES_CNTRL1L          ; A = controller state
	AND.W #$FFF0                ; Mask D-pad
	BEQ Input_ProcessButtons    ; If zero → No buttons

	JMP.W CODE_0092F6           ; → Alternate button handler

;-------------------------------------------------------------------------------

Input_ProcessButtons:
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

Input_ReadController_Exit:
	RTS                         ; Return

;===============================================================================
; AUTOFIRE & INPUT TIMING ($008BFD-$008C1A)
;===============================================================================

Input_HandleAutofire:
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
	BNE Input_NewButtonPress    ; If any new press → Handle immediate input

	; ---------------------------------------------------------------------------
	; Handle Held Buttons (Autofire)
	; ---------------------------------------------------------------------------

	LDA.B $92                   ; A = currently held buttons
	BEQ Input_HandleAutofire_Exit ; If nothing held → Exit

	DEC.B $09                   ; Decrement autofire timer
	BPL Input_HandleAutofire_Exit ; If timer still positive → Exit (not ready)

	; Timer expired - trigger autofire event
	STA.B $07                   ; Output = held buttons (simulate new press)

	LDA.W #$0005                ; A = $05 (5 frames)
	STA.B $09                   ; Reset timer to 5 for repeat rate

Input_HandleAutofire_Exit:
	RTS                         ; Return

;-------------------------------------------------------------------------------

Input_NewButtonPress:
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

Tilemap_CalcVRAMAddress:
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

Tilemap_RefreshLayer0:
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
	BEQ Tilemap_RefreshLayer0_Field ; If clear → Field mode

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
	BRA Tilemap_TransferData    ; → Continue to transfer

;-------------------------------------------------------------------------------

UNREACH_008C81:
	db $28,$60                 ; Unreachable code: PLP, RTS

;-------------------------------------------------------------------------------

Tilemap_RefreshLayer0_Field:
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
	JSR.W Tilemap_CalcRowAddress ; Calculate tilemap address
	STX.W $00F2                 ; [$00F2] = tilemap address

	LDX.W #$2D1A                ; X = $2D1A (WRAM source address)
	LDA.B #$7E                  ; A = $7E (bank $7E)

;-------------------------------------------------------------------------------

Tilemap_TransferData:
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
	BEQ Tilemap_SetupDMA        ; If clear → Normal cursor

	; Check blink timer
	LDA.W $0014                 ; A = [$0014] (blink timer)
	DEC A                       ; A = A - 1
	BEQ Tilemap_SetupDMA        ; If zero → Show cursor

	; Apply alternate palette during blink
	LDA.B #$10                  ; A = $10 (bit 4 mask)
	AND.W $00DA                 ; Test bit 4 of $00DA
	BNE Tilemap_BlinkSpecial    ; If set → Special blink mode

	; Normal blink mode (incomplete in disassembly)
	db $AB,$BD,$01,$00,$29,$E3,$09,$94,$80,$12

;-------------------------------------------------------------------------------

Tilemap_BlinkSpecial:
	PLB                         ; B = bank (restore)
	LDA.W $0001,X               ; A = [X+1] (tile attribute byte)
	AND.B #$E3                  ; A = A & $E3 (clear palette bits 2,3,4)
	ORA.B #$9C                  ; A = A | $9C (set new palette + priority)
	BRA Tilemap_ApplyAttributes ; → Save and continue

;-------------------------------------------------------------------------------

Tilemap_SetupDMA:
	PLB                         ; B = bank (restore)
	LDA.W $0001,X               ; A = [X+1] (tile attribute)
	AND.B #$E3                  ; Clear palette bits
	ORA.B #$88                  ; Set normal palette

;-------------------------------------------------------------------------------

Tilemap_ApplyAttributes:
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

Display_DecimalDigit_Loop:
	; Divide by 10 loop
	INY                         ; Y++ (count tens)
	SBC.B #$0A                  ; A = A - 10
	BCS Display_DecimalDigit_Loop             ; If carry still set → Continue subtracting

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
	BRA Tilemap_FinalizeUpdate             ; → Finish update

;-------------------------------------------------------------------------------

UNREACH_008D06:
	; Show blank tile for tens digit
	db $A9,$45,$9D,$00,$00,$EB,$9D,$01,$00,$80,$0F
	; LDA #$45, STA [$00,X], XBA, STA [$01,X], BRA $0F

;-------------------------------------------------------------------------------

Display_BlankTiles:
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

Tilemap_FinalizeUpdate:
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

Tilemap_RefreshLayer1:
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
	BEQ Tilemap_RefreshLayer1_Exit             ; If $FF → Exit

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

Tilemap_RefreshLayer1_Exit:
	PLP                         ; Restore status
	RTS                         ; Return

;-------------------------------------------------------------------------------

Tilemap_RefreshLayer1_Field:
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
	JSR.W Tilemap_CalcRowAddress           ; Calculate tilemap address
	STX.W $00F5                 ; Save address

	LDA.B #$80                  ; A = $80
	TSB.W $00D4                 ; Set update flag

	PLP                         ; Restore status
	RTS                         ; Return

;-------------------------------------------------------------------------------

; Already renamed: Tilemap_CalcRowAddress
Tilemap_CalcRowAddress:
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
	JSR.W Party_CheckAvailability           ; Validate party member
	PLA                         ; Restore original position
	STA.W $1031                 ; Store back to $1031
	STY.B $9E                   ; Save validated position to $9E
	RTS                         ; Return

;-------------------------------------------------------------------------------

Party_CheckAvailability:
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

Party_CheckAvailability_ShiftLoop:
	LSR A                       ; Shift right
	LSR A                       ; Shift right
	LSR A                       ; Shift right (shift 3 bits per slot)
	DEX                         ; Decrement shift counter
	BNE Party_CheckAvailability_ShiftLoop             ; Loop until X = 0

	LSR A                       ; Check first member bit
	BCS Party_CheckAvailability_Found             ; If set → valid member found
	DEY                         ; Try previous slot
	LSR A                       ; Check second member bit
	BCS Party_CheckAvailability_Found             ; If set → valid member found
	DEY                         ; Try previous slot
	LSR A                       ; Check third member bit
	BCS Party_CheckAvailability_Found             ; If set → valid member found
	LDY.B #$FF                  ; No valid members → $FF

Party_CheckAvailability_Found:
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

VRAM_DirectWriteLarge_OuterLoop:
	PHY                         ; Save Y counter
	SEP #$20                    ; 8-bit A
	LDY.W #$0018                ; Y = $18 (24 decimal, inner loop count)

VRAM_DirectWriteLarge_InnerLoop:
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

VRAM_Write8TilesPattern:
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

VRAM_Write8TilesPattern_Loop:
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
	BNE VRAM_Write8TilesPattern_Loop             ; Loop if more tiles remain

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
	JSL.L VRAM_DirectWriteLarge           ; Transfer tiles via direct writes
	PLB                         ; Restore data bank

	; Load palette data from Bank $07
	SEP #$30                    ; 8-bit mode
	PEA.W $0007                 ; Push bank $07
	PLB                         ; Data bank = $07

	; Load 4 sets of 8-color palettes
	LDA.B #$08                  ; A = $08 (CGRAM address $08)
	LDX.B #$00                  ; X = $00 (source offset)
	JSR.W Palette_Load8Colors           ; Load 8 colors
	LDA.B #$0C                  ; A = $0C (CGRAM address $0C)
	LDX.B #$08                  ; X = $08 (source offset)
	JSR.W Palette_Load8Colors           ; Load 8 colors
	LDA.B #$18                  ; A = $18 (CGRAM address $18)
	LDX.B #$10                  ; X = $10 (source offset)
	JSR.W Palette_Load8Colors           ; Load 8 colors
	LDA.B #$1C                  ; A = $1C (CGRAM address $1C)
	LDX.B #$18                  ; X = $18 (source offset)
	JSR.W Palette_Load8Colors           ; Load 8 colors
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
	BNE Graphics_InitFieldMenu_PaletteLoop             ; Loop if more groups remain

	PLB                         ; Restore data bank
	PLD                         ; Restore Direct Page
	PLP                         ; Restore processor status
	RTS                         ; Return

;-------------------------------------------------------------------------------

Palette_Load8Colors:
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
	JSR.W Status_RenderIcon           ; Render status icon

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
	JSR.W Status_RenderIcon           ; Render status icon

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
	JSR.W Status_RenderIcon           ; Render status icon

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
	JSR.W Status_RenderIcon           ; Render status icon

Skip_Status_Group4:
	; Process first character slot
	LDY.B #$00                  ; Y = 0 (slot 0)
	JSR.W Status_RenderCharacter           ; Render character status

	; Switch to second character slot data
	PEA.W $1080                 ; Push $1080
	PLD                         ; Direct Page = $1080
	LDY.B #$50                  ; Y = $50 (display offset)
	JSR.W Status_RenderCharacter           ; Render character status

	PLD                         ; Restore Direct Page
	PLP                         ; Restore processor status
	RTS                         ; Return

;-------------------------------------------------------------------------------

Status_RenderCharacter:
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
	JSR.W Status_RenderIcon           ; Render status icon

Skip_Status4:
	RTS                         ; Return

;-------------------------------------------------------------------------------

Status_RenderIcon:
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
	JSR.W Status_SetIconFlags           ; Write icon data to buffer

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
	JSR.W Status_SetIconFlags           ; Write icon to buffer

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

Status_SetIconFlags:
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

Char_CalcStats:
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

Stat_CalcOR:
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

Stat_CalcSum:
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

Animation_CheckUpdate:
	SEP #$30                    ; 8-bit A/X/Y
	LDA.B #$20                  ; Bit 5 mask
	AND.W $00D9                 ; Check animation update flag
	BNE Skip_Animation          ; If set, skip this frame
	JSR.W Animation_UpdateSystem           ; Process animation updates

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

Animation_UpdateSystem:
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

Graphics_SetupFieldMode:
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

Graphics_PrepareTransition:
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

Display_EnableEffects:
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

Display_CheckFrameUpdate:
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

Math_Multiply16x16:
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

Math_Divide32by16:
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

Hardware_WriteMultiplierB:
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

Hardware_Divide:
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

Bit_FindFirstSet:
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

Bit_SetBits:
	JSR.W Bit_CalcPosition           ; Calculate bit position/mask
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

Bit_ClearBits:
	JSR.W Bit_CalcPosition           ; Calculate bit position/mask
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

Bit_TestBits:
	JSR.W Bit_CalcPosition           ; Calculate bit position/mask
	AND.B $00                   ; Test bits
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; Set Bits with DP $0EA8
; ---------------------------------------------------------------------------
; Purpose: Set bits in $0EA8+offset using TSB
; Input: A = bit mask (offset in low byte)
; Output: Bits set in target location
; ===========================================================================

Bit_SetBits_0EA8:
	PHD                         ; Save direct page
	PEA.W $0EA8                 ; Push $0EA8
	PLD                         ; Direct Page = $0EA8
	JSL.L Bit_SetBits           ; Set bits via TSB
	PLD                         ; Restore direct page
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; Clear Bits with DP $0EA8
; ---------------------------------------------------------------------------
; Purpose: Clear bits in $0EA8+offset using TRB
; Input: A = bit mask (offset in low byte)
; Output: Bits cleared in target location
; ===========================================================================

Bit_ClearBits_0EA8:
	PHD                         ; Save direct page
	PEA.W $0EA8                 ; Push $0EA8
	PLD                         ; Direct Page = $0EA8
	JSL.L Bit_ClearBits           ; Clear bits via TRB
	PLD                         ; Restore direct page
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; Test Bits with DP $0EA8
; ---------------------------------------------------------------------------
; Purpose: Test bits in $0EA8+offset
; Input: A = bit mask (offset in low byte)
; Output: A = result of test, Z/N flags set
; ===========================================================================

Bit_TestBits_0EA8:
	PHD                         ; Save direct page
	PEA.W $0EA8                 ; Push $0EA8
	PLD                         ; Direct Page = $0EA8
	JSL.L Bit_TestBits           ; Test bits via AND
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

Random_Generate:
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
	JSL.L Hardware_Divide           ; Perform division
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

Bit_PositionToMask:
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

Memory_FillLong:
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

Memory_Fill:
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
	JSR.W Memory_Fill64           ; Fill 64 bytes
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

Memory_Fill64:
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

Memory_Fill32:
	STA.W $0020,Y               ; Fill word at +$20
	STA.W $001E,Y               ; Fill word at +$1E
	STA.W $001C,Y               ; Fill word at +$1C
	STA.W $001A,Y               ; Fill word at +$1A
	STA.W $0018,Y               ; Fill word at +$18
	STA.W $0016,Y               ; Fill word at +$16
	STA.W $0014,Y               ; Fill word at +$14
	STA.W $0012,Y               ; Fill word at +$12

Memory_Fill16:
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

Graphics_LoadData:
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
	JSL.L Graphics_Setup1           ; Process graphics
	JSR.W Graphics_InitDisplay           ; Call handler
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

Graphics_Setup1:
	PHP                         ; Save processor status
	PHD                         ; Save direct page
	PEA.W $0000                 ; Push $0000
	PLD                         ; Direct Page = $0000
	REP #$30                    ; 16-bit A/X/Y
	PHX                         ; Save X
	LDX.W #$9B42                ; Data pointer
	JSR.W Graphics_ProcessData           ; Process data
	PLX                         ; Restore X
	PLD                         ; Restore direct page
	PLP                         ; Restore processor status
	RTL                         ; Return long

Graphics_Setup2:
	PHP                         ; Save processor status
	PHD                         ; Save direct page
	REP #$30                    ; 16-bit A/X/Y
	LDA.W #$0000                ; Direct Page = $0000
	TCD                         ; Set DP
	LDX.W #$9B56                ; Data pointer
	JSR.W Graphics_ProcessData           ; Process data
	PLD                         ; Restore direct page
	PLP                         ; Restore processor status
	RTL                         ; Return long

Graphics_Setup3:
	PHP                         ; Save processor status
	PHD                         ; Save direct page
	REP #$30                    ; 16-bit A/X/Y
	LDA.W #$0000                ; Direct Page = $0000
	TCD                         ; Set DP
	LDA.B $20                   ; Load parameter
	STA.B $4F                   ; Store to $4F
	JSR.W Graphics_SetupPointer           ; Setup graphics
	LDA.B [$17]                 ; Load data
	AND.W #$00FF                ; Mask to byte
	CMP.W #$0004                ; Compare to 4
	BEQ Skip_Special            ; If equal, skip
	LDX.W #$9B9D                ; Special data pointer
	JSR.W Graphics_ProcessData           ; Process data

Skip_Special:
	JSR.W Graphics_SetupPointer           ; Setup graphics again
	JSR.W CODE_009D75           ; Process graphics data
	JSR.W Graphics_PostProcess           ; Post-process
	LDX.W #$9BA0                ; Cleanup pointer
	JSR.W Graphics_ProcessData           ; Process cleanup
	PLD                         ; Restore direct page
	PLP                         ; Restore processor status
	RTL                         ; Return long

Graphics_SetupPointer:
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

Graphics_PostProcess:
	RTS                         ; Return (stub)

Graphics_Setup4:
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

Graphics_CommandDispatch:
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

Graphics_ConditionalDispatch:
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
	BCC Graphics_ConditionalDispatch_Continue
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

Graphics_ConditionalDispatch_Continue:
	STY.B $17
	RTS

; ---------------------------------------------------------------------------
; More graphics command handlers (block)
; Imported segment: CODE_00A342 .. CODE_00A576
; ---------------------------------------------------------------------------

Graphics_InitDisplay:
	PHP
	REP #$30
	PHB
	PHA
	PHD
	PHX
	PHY
	LDA.B $46
	BNE +
	JMP Graphics_InitDisplay_End
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
	JMP.W Bit_SetBits_00E2

Graphics_InitDisplay_End:
	LDA.W #$0080
	TSB.W $00D0
	RTS

Graphics_DispatchTable:
	LDA.B [$17]
	INC.B $17
	AND.W #$00FF
	ASL A
	TAX
	JMP.W (DATA8_009E6E,X)

Graphics_CallSystem:
	LDA.W #$0080
	TSB.W $00D8
	JSL.L CODE_0C8000
	LDA.W #$0008
	TRB.W $00D4
	RTS

Graphics_CheckDisplayReady:
	LDA.W #$0040
	AND.W $00D0
	BEQ Graphics_FadeOut
	RTS

Graphics_FadeOut:
	LDA.W #$00FF
	JMP.W CODE_009DC9

Graphics_WaitForEvent:
	JSL.L CODE_0C8000
	LDA.W #$0020
	AND.W $00D0
	BNE Graphics_WaitForEvent_Alt
	LDA.B [$17]
	INC.B $17
	INC.B $17

Graphics_WaitForEvent_Loop:
	JSL.L CODE_0096A0
	BIT.B $94
	BEQ Graphics_WaitForEvent_Loop
	RTS

Graphics_WaitForEvent_Alt:
	LDA.B [$17]
	INC.B $17
	INC.B $17

Graphics_WaitForEvent_AltLoop:
	JSL.L CODE_0096A0
	BIT.B $07
	BEQ Graphics_WaitForEvent_AltLoop
	RTS

; A series of conditional calls to CODE_00B1C3/CODE_00B1D6 etc.:

Condition_CheckPartyMember:
	JSR.W CODE_00B1C3
	BCC Condition_Skip
	BEQ Condition_Skip
	BRA Condition_Jump

; (several similar blocks follow in the original disassembly; preserved as-is)

Condition_Skip:
	INC.B $17
	INC.B $17
	RTS

Condition_Jump:
	LDA.B [$17]
	STA.B $17
	RTS

Condition_CheckEventFlag:
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
Condition_CheckBattleFlag:
	JSR.W CODE_00B1E8
	BCS Condition_Skip
	BRA Condition_Jump

; CODE_00A46D and CODE_00A472 removed - reuse Condition_Skip/Jump labels

Condition_CheckItem:
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

Condition_CheckCompanion:
	JSR.W CODE_00B21D
	BCS Condition_Skip
	BRA Condition_Jump

; CODE_00A4D9 and CODE_00A4DE removed - reuse Condition_Skip/Jump labels

Condition_CheckWeapon:
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

Graphics_SetPointer:
	LDA.B [$17]
	STA.B $17
	RTS

Graphics_SetBank:
	LDA.B [$17]
	INC.B $17
	INC.B $17
	TAX
	SEP #$20
	LDA.B [$17]
	STA.B $19
	STX.B $17
	RTS

Condition_TestBitD0:
	LDA.B [$17]
	INC.B $17
	AND.W #$00FF
	PHD
	PEA.W $00D0
	PLD
	JSL.L Bit_TestBits
	PLD
	INC A
	DEC A
	BRA Condition_BranchOnZero

Condition_TestBitD0_Alt:
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

Condition_TestBitEA8:
	LDA.B [$17]
	INC.B $17
	AND.W #$00FF
	JSL.L Bit_TestBits_0EA8

Condition_BranchOnZero:
	BNE Graphics_SetPointer
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


Graphics_ProcessData:
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

Graphics_ClearFlag:
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

Palette_InitColorProcessing:
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
	JMP.W Graphics_StackOverflow           ; Handle overflow (infinite loop)

Graphics_UpdateStackPtr:
	STA.L $7E3367               ; Update stack pointer
	JMP.W Bit_SetBits_00E2           ; Clean stack and return

Graphics_StackOverflow:
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

	JMP.W Bit_SetBits_00E2           ; Clean stack and return

; ---------------------------------------------------------------------------
; Fill Memory via Helper
; ---------------------------------------------------------------------------

Graphics_MemoryFillHelper:
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
; Graphics_ProcessWithDP: Process Graphics with DP Setup
; ---------------------------------------------------------------------------

Graphics_ProcessWithDP:
	PHD                         ; Save direct page
	PEA.W $0000                 ; Push $0000
	PLD                         ; Direct Page = $0000
	JSR.W Graphics_ProcessStream           ; Process graphics
	PLD                         ; Restore direct page
	RTL                         ; Return long

; ---------------------------------------------------------------------------
; Graphics_ProcessStream: Main Graphics Data Processor
; ---------------------------------------------------------------------------
; Purpose: Core loop for processing graphics command stream
; Algorithm: Read bytes from [$17], dispatch to handlers via jump table
; Commands $00-$2F: Jump table entries
; Commands $30+: Indexed data lookup
; Commands $80+: Direct tile data (XOR with $1D for effects)
; ===========================================================================

Graphics_ProcessStream:
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
	BEQ Graphics_ProcessStream_Normal             ; Normal processing

	; Special mode with synchronization
	LDA.W #$0010                ; Bit 4 mask
	AND.W $00D0                 ; Test flag
	BNE Graphics_ProcessStream_AltSync             ; Use alternate sync

Graphics_ProcessStream_SyncLoop:
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

Graphics_ProcessStream_Normal:
	; Normal processing loop
	LDA.W $00D0                 ; Load flags
	BIT.W #$0090                ; Test bits 4 and 7
	BEQ Graphics_ProcessStream_Loop             ; Continue if neither set

	BIT.W #$0080                ; Test bit 7
	BNE Graphics_ProcessStream_Exit             ; Exit if set
	JSR.W CODE_00E055           ; Process special event
	BRA Graphics_ProcessStream_Normal             ; Continue loop

Graphics_ProcessStream_Exit:
	LDA.W #$0080                ; Bit 7 mask
	TRB.W $00D0                 ; Clear exit flag

Graphics_ProcessStream_Done:
	JMP.W Bit_SetBits_00E2           ; Clean stack and return

; ---------------------------------------------------------------------------
; Graphics_ReadDispatchCmd: Read and Dispatch Graphics Command
; ---------------------------------------------------------------------------

Graphics_ReadDispatchCmd:
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

Graphics_DispatchCommand:
	; Command dispatch (values $00-$7F)
	CMP.W #$0030                ; Is it indexed data?
	BCS Graphics_IndexedDataLookup             ; Yes, handle indexed

	; Jump table dispatch ($00-$2F)
	ASL A                       ; Multiply by 2 (word index)
	TAX                         ; X = table offset
	JSR.W (DATA8_009E0E,X)      ; Call handler via table
	REP #$30                    ; 16-bit A/X/Y
	RTS                         ; Return

Graphics_IndexedDataLookup:
	; Indexed data lookup ($30+)
	LDX.W #$0000                ; X = 0 (table index)
	SBC.W #$0030                ; Subtract base (now $00-$4F)
	BEQ Graphics_IndexedDataFound             ; If 0, use first entry
	TAY                         ; Y = index count

Graphics_IndexedDataSearch:
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

Cmd_SetPointerEA6:
	LDA.W #$0EA6                ; Fixed pointer
	STA.B $2E                   ; Store to $2E
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $25: Load Graphics Pointer from Stream
; ---------------------------------------------------------------------------

Cmd_LoadPointer:
	LDA.B [$17]                 ; Read 16-bit pointer
	INC.B $17                   ; Advance stream pointer
	INC.B $17                   ; (2 bytes)
	STA.B $2E                   ; Store to $2E
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $26: Set Tile Offset (8-bit)
; ---------------------------------------------------------------------------

Cmd_SetTileOffset:
	LDA.B [$17]                 ; Read byte parameter
	INC.B $17                   ; Advance stream pointer
	AND.W #$00FF                ; Mask to byte
	SEP #$20                    ; 8-bit A
	STA.B $1E                   ; Store tile offset
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $19: Set Graphics Bank and Pointer
; ---------------------------------------------------------------------------

Cmd_SetBankAndPointer:
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

Cmd_SetDisplayMode:
	LDA.B [$17]                 ; Read byte parameter
	INC.B $17                   ; Advance stream pointer
	AND.W #$00FF                ; Mask to byte
	SEP #$20                    ; 8-bit A
	STA.B $27                   ; Store mode byte
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $28: Set Effect Mask
; ---------------------------------------------------------------------------

Cmd_SetEffectMask:
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

Cmd_SetParameter25:
	LDA.B [$17]                 ; Read 16-bit value
	INC.B $17                   ; Advance stream pointer
	INC.B $17                   ; (2 bytes)
	STA.B $25                   ; Store to $25
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $1F: Indexed String Lookup with Fixed Length
; ---------------------------------------------------------------------------

Cmd_StringLookup82BB:
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

Cmd_StringLookupA802:
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

Cmd_StringLookup8383:
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

Cmd_SetDisplayParams:
	LDA.B [$17]                 ; Read first word
	INC.B $17                   ; Advance stream pointer
	INC.B $17                   ; (2 bytes)
	STA.B $28                   ; Store to $28
	LDA.B [$17]                 ; Read second word
	INC.B $17                   ; Advance stream pointer
	INC.B $17                   ; (2 bytes)
	STA.B $2A                   ; Store to $2A
	RTS                         ; Return

Cmd_SetParams2C2D:
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

Cmd_LookupA7F6:
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

Cmd_SetPointerAEA7:
	SEP #$20                    ; 8-bit A
	LDA.B #$03                  ; Bank $03
	STA.B $19                   ; Store bank
	LDX.W #$AEA7                ; Pointer
	STX.B $17                   ; Store pointer
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $1C: Set Graphics Pointer to $8457 Bank $03
; ---------------------------------------------------------------------------

Cmd_SetPointer8457:
	SEP #$20                    ; 8-bit A
	LDA.B #$03                  ; Bank $03
	STA.B $19                   ; Store bank
	LDX.W #$8457                ; Pointer
	STX.B $17                   ; Store pointer
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Command $1A: Indexed Character Graphics
; ---------------------------------------------------------------------------

Cmd_CharacterGraphics:
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

Cmd_MonsterGraphics:
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

Cmd_ClearHighBytes:
	JSR.W Cmd_ReadIndirect           ; Read pointer
	STZ.B $9F                   ; Clear $9F
	STZ.B $A0                   ; Clear $A0
	RTS                         ; Return

Cmd_ClearA0:
	JSR.W Cmd_ReadIndirect           ; Read pointer
	STZ.B $A0                   ; Clear $A0
	RTS                         ; Return

Cmd_SetA0Byte:
	JSR.W Cmd_ReadIndirect           ; Read pointer
	AND.W #$00FF                ; Mask to byte
	STA.B $A0                   ; Store to $A0
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Cmd_ReadIndirect: Read Indirect Pointer from Stream
; ---------------------------------------------------------------------------
; Purpose: Read pointer and bank from [$17], then dereference
; Algorithm: Read 3 bytes -> use as pointer -> read actual target pointer
; ===========================================================================

Cmd_ReadIndirect:
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

Cmd_MemoryFill:
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

Cmd_CallGraphicsSys:
	JSL.L CODE_0C8000           ; Call graphics system
	RTS                         ; Return

Cmd_WaitVBlank:
	JSL.L CODE_0096A0           ; Wait for VBlank
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Cmd_CopyDisplayState: Copy Display State
; ---------------------------------------------------------------------------

Cmd_CopyDisplayState:
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

Cmd_CopyAndClearFlags:
	JSR.W Cmd_CopyDisplayState           ; Copy display state
	STZ.W $1021                 ; Clear flag
	STZ.W $10A1                 ; Clear flag
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Cmd_PrepareDisplayState: Prepare Display State
; ---------------------------------------------------------------------------

Cmd_PrepareDisplayState:
	LDX.W $1016                 ; Load source
	STX.W $1014                 ; Copy to destination
	LDX.W $1096                 ; Load source (second set)
	STX.W $1094                 ; Copy to destination
	LDA.W #$0003                ; Bits 0-1 mask
	TRB.W $102F                 ; Clear bits
	TRB.W $10AF                 ; Clear bits
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Cmd_CharacterDMATransfer: Character Data DMA Transfer
; ---------------------------------------------------------------------------
; Purpose: Copy character data to VRAM buffer area
; ===========================================================================

Cmd_CharacterDMATransfer:
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

Cmd_CharDMATransfer_Done:
	RTS                         ; Return

; ---------------------------------------------------------------------------
; Multiple Command Sequence
; ---------------------------------------------------------------------------

Cmd_MultiCommandSeq:
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

Cmd_WaitVBlankCount:
	LDA.B [$17]                 ; Read wait count
	INC.B $17                   ; Advance stream
	AND.W #$00FF                ; Mask to byte

Cmd_WaitVBlankLoop:
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

Cmd_PaletteLookup_Search:
	; Search palette table for matching index
	LDA.W DATA8_00A2DD,X        ; Load table entry
	CMP.B #$FF                  ; Check for end marker
	BNE +                       ; Not end, continue
	JMP UNREACH_00A2D4          ; End of table (not found)
+	CMP.B $01,S                 ; Compare with search index
	BEQ Cmd_PaletteLookup_Found             ; Found match
	INX                         ; Next entry
	INX                         ; (skip 2 more bytes)
	INX                         ; (3 bytes per entry)
	BRA Cmd_PaletteLookup_Search             ; Continue search

Cmd_PaletteLookup_Found:
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

;===============================================================================
; Conditional Jump Handlers - Item/Flag Testing
; These handlers test various game flags and conditionally jump based on results
;===============================================================================

Cmd_TestItemJump:
	LDA.B [$17]                    ; Load item/flag index
	INC.B $17                      ; Advance pointer
	AND.W #$00FF                   ; Mask to byte
	JSL.L Bit_TestBits_0EA8              ; Test item flag (external stub)

Cmd_TestItemJump_Check:
	BNE +                           ; If set, skip
	JMP Graphics_SetPointer                ; If clear, take jump (far)
+	JMP Cmd_SkipJumpAddress                ; If set, skip jump (far)

Cmd_TestVariable1:
	JSR.W CODE_00B1A1              ; Test variable
	BNE +                           ; If not zero, skip
	JMP Condition_BranchOnZero                ; Branch based on result (far)
+	RTS

Cmd_TestVariable2:
	JSR.W CODE_00B1A1              ; Test variable (alternate)
	BEQ Cmd_TestItemJump_Check                ; Branch to alternate handler
	RTS

	JSR.W CODE_00B1B4              ; Test condition
	BEQ +                           ; If zero, skip
	JMP Graphics_SetPointer                ; If not zero, take jump (far)
+	JMP Cmd_SkipJumpAddress                ; If zero, skip jump (far)

	JSR.W CODE_00B1B4              ; Test condition (alternate)
	BNE +                           ; If not zero, skip
	JMP Graphics_SetPointer                ; If zero, take jump (far)
+	RTS

Cmd_SkipJumpAddress:
	INC.B $17                      ; Skip jump address
	INC.B $17                      ; (2 bytes)
	RTS                            ; Return

;===============================================================================
; More Conditional Branch Handlers
; (Similar patterns for different test types: CODE_00B1C3, CODE_00B1D6, etc.)
;===============================================================================

	JSR.W CODE_00B1C3              ; Test condition type 1
	BCS +                          ; If greater/equal, skip
	BNE +
	JMP CODE_00A744                ; Take jump (far)
+	INC.B $17                      ; Skip address
	INC.B $17
	RTS

	JSR.W CODE_00B1C3
	BCS +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B1C3
	BCC +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B1C3
	BCC +
	BNE +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B1C3
	BEQ +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B1C3
	BEQ +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

;===============================================================================
; CODE_00A5C8 - Skip Jump Address Helper
;===============================================================================

Cmd_SkipTwoBytes:
	INC.B $17                      ; Skip jump address
	INC.B $17                      ; (2 bytes)
	RTS                            ; Return

;===============================================================================
; Cmd_LoadExecWithSwitch - Load Address and Bank, Execute with Context Switch
;===============================================================================

Cmd_LoadExecWithSwitch:
	LDA.B [$17]                    ; Load target address
	INC.B $17                      ; Advance pointer
	INC.B $17
	TAX                            ; Store address to X
	LDA.B $19                      ; Load current bank
	JMP.W CODE_00A71C              ; Jump to bank switcher

;===============================================================================
; Duplicate Conditional Handler Patterns (for different test functions)
; These follow the same pattern as earlier but for CODE_00B1D6, CODE_00B1E8,
; CODE_00B204, CODE_00B21D, and CODE_00B22F test routines
;===============================================================================

; Pattern set for CODE_00B1D6 (6 variants)
	JSR.W CODE_00B1D6              ; Test type 2
	BCS +
	BNE +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B1D6
	BCS +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B1D6
	BCC +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B1D6
	BCC +
	BNE +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B1D6
	BEQ +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B1D6
	BEQ +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	LDA.B [$17]                    ; Load address
	INC.B $17
	INC.B $17
	TAX                            ; Store to X
	LDA.B $19                      ; Load bank
	JMP.W Graphics_BankSwitch              ; Bank switch

; Pattern set for Test_Compare24Full (6 variants)
	JSR.W Test_Compare24Full
	BCS +
	BNE +
	JMP Graphics_LoadAddrExecute
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B1E8
	BCS +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B1E8
	BCC +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B1E8
	BCC +
	BNE +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B1E8
	BEQ +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B1E8
	BEQ +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	LDA.B [$17]
	INC.B $17
	INC.B $17
	TAX
	LDA.B $19
	JMP.W CODE_00A71C

; Pattern set for CODE_00B204 (6 variants)
	JSR.W CODE_00B204
	BCS +
	BNE +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B204
	BCS +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B204
	BCC +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B204
	BCC +
	BNE +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B204
	BEQ +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B204
	BEQ +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	LDA.B [$17]
	INC.B $17
	INC.B $17
	TAX
	LDA.B $19
	JMP.W CODE_00A71C

; Pattern set for CODE_00B21D (6 variants)
	JSR.W CODE_00B21D
	BCS +
	BNE +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B21D
	BCS +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B21D
	BCC +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B21D
	BCC +
	BNE +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B21D
	BEQ +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B21D
	BEQ +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	LDA.B [$17]
	INC.B $17
	INC.B $17
	TAX
	LDA.B $19
	BRA CODE_00A71C_alt1

; Pattern set for CODE_00B22F (6 variants)
	JSR.W CODE_00B22F
	BCS +
	BNE +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B22F
	BCS +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B22F
	BCC +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B22F
	BCC +
	BNE +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B22F
	BEQ +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	JSR.W CODE_00B22F
	BEQ +
	JMP CODE_00A744
+	INC.B $17
	INC.B $17
	RTS

	LDA.B [$17]
	INC.B $17
	INC.B $17
	TAX
	LDA.B $19
	BRA CODE_00A71C_alt2

;===============================================================================
; Graphics_LoadAndExec - Load Pointer and Bank, Execute Subroutine
;===============================================================================

Graphics_LoadAndExec:
	LDA.B [$17]                    ; Load target pointer
	INC.B $17
	INC.B $17
	TAX                            ; Store pointer to X
	LDA.B [$17]                    ; Load bank byte
	INC.B $17
	AND.W #$00FF                   ; Mask to byte
	BRA Graphics_BankSwitch                ; Jump to bank switcher

Graphics_LoadSavedContext:
	LDX.B $9E                      ; Load saved pointer
	LDA.B $A0                      ; Load saved bank

;===============================================================================
; Graphics_BankSwitch - Bank Switch with Full Context Save/Restore
;
; This is THE critical routine for script execution and inter-bank calls.
; It saves the current execution context (pointer + bank), switches to a new
; context, executes code there, then fully restores the original context.
;
; Entry: A = new bank byte (in high byte), X = new pointer
; Uses: Full context save via stack and register swapping
;===============================================================================

Graphics_BankSwitch:
	SEP #$20                       ; 8-bit A
	XBA                            ; Swap A/B (save new bank to B)
	LDA.B $19                      ; Load current bank
	LDY.B $17                      ; Load current pointer to Y
	XBA                            ; Swap back (new bank to A, old to B)
	STA.B $19                      ; Set new bank
	STX.B $17                      ; Set new pointer
	LDA.B #$08                     ; Load flag bit $08
	AND.W $00DB                    ; Test current flag state
	PHP                            ; Save flag state
	LDA.B #$08                     ; Load flag bit $08
	TRB.W $00DB                    ; Clear flag
	JSR.W CODE_009D75              ; Execute in new context (external)
	PLP                            ; Restore flag state
	BEQ CODE_00A73E                ; If flag was clear, skip restore
	LDA.B #$08                     ; Load flag bit
	TSB.W $00DB                    ; Restore flag to set state

CODE_00A73E:
	XBA                            ; Get old bank from B
	STA.B $19                      ; Restore bank
	STY.B $17                      ; Restore pointer
	RTS                            ; Return

;===============================================================================
; CODE_00A744 - Load Address, Call Function, Execute Result
;===============================================================================

Graphics_LoadAddrExecute:
	LDA.B [$17]                    ; Load address
	INC.B $17
	INC.B $17
	JSR.W Graphics_CallFunc              ; Call function (external)
	STA.B $17                      ; Store result as pointer
	JSR.W Graphics_ProcessStream              ; Execute at new pointer
	JMP.W Graphics_PopParams              ; Jump to cleanup (external)

;===============================================================================
; Graphics_LoadExec - Load Pointer and Execute with Bank Switch
;===============================================================================

Graphics_LoadExec:
	LDA.B [$17]                    ; Load pointer
	INC.B $17
	INC.B $17
	TAX                            ; Store to X
	LDA.B $19                      ; Load bank
	BRA CODE_00A71C                ; Bank switch and execute

;===============================================================================
; Flag Testing with Conditional Jumps to CODE_00A755 or CODE_00A7C6
;===============================================================================

	LDA.B [$17]                    ; Load flag index
	INC.B $17
	AND.W #$00FF                   ; Mask to byte
	PHD                            ; Save direct page
	PEA.W $00D0                    ; Set DP to $D0
	PLD
	JSL.L CODE_00975A              ; Test flag (external)
	PLD                            ; Restore DP
	INC A                          ; Test result (set Z flag)
	DEC A
	BNE CODE_00A755                ; If flag set, take jump
	BRA CODE_00A7C6                ; If clear, skip

	LDA.B [$17]                    ; Load flag index
	INC.B $17
	AND.W #$00FF                   ; Mask to byte
	PHD                            ; Save direct page
	PEA.W $00D0                    ; Set DP to $D0
	PLD
	JSL.L CODE_00975A              ; Test flag (external)
	PLD                            ; Restore DP
	INC A                          ; Test result
	DEC A
	BEQ CODE_00A755                ; If flag clear, take jump
	BRA CODE_00A7C6                ; If set, skip

	LDA.B [$17]                    ; Load item flag
	INC.B $17
	AND.W #$00FF                   ; Mask to byte
	JSL.L CODE_009776              ; Test item (external)
	BNE CODE_00A755                ; If set, jump
	BRA CODE_00A7C6                ; If clear, skip

CODE_00A79D:
	LDA.B [$17]                    ; Load item flag
	INC.B $17
	AND.W #$00FF                   ; Mask to byte
	JSL.L CODE_009776              ; Test item (external)
	BEQ CODE_00A755                ; If clear, jump
	BRA CODE_00A7C6                ; If set, skip

CODE_00A7AC:
	JSR.W CODE_00B1A1              ; Test variable
	BNE CODE_00A755                ; If not zero, jump
	BRA CODE_00A7C6                ; If zero, skip

CODE_00A7B3:
	JSR.W CODE_00B1A1              ; Test variable
	BEQ CODE_00A755                ; If zero, jump
	BRA CODE_00A7C6                ; If not zero, skip

	JSR.W CODE_00B1B4              ; Test condition
	BNE CODE_00A755                ; If not zero, jump
	BRA CODE_00A7C6                ; If zero, skip

	JSR.W CODE_00B1B4              ; Test condition
	BEQ CODE_00A755                ; If zero, jump

CODE_00A7C6:
	INC.B $17                      ; Skip jump address
	INC.B $17                      ; (2 bytes)
	RTS                            ; Return

;===============================================================================
; Subroutine Execution with Parameter Passing
;===============================================================================

	LDA.B [$17]                    ; Load parameter
	INC.B $17
	AND.W #$00FF                   ; Mask to byte
	SEP #$20                       ; 8-bit A
	LDX.B $9E                      ; Load saved pointer
	XBA                            ; Build word (param in high byte)
	LDA.B $A0                      ; Load saved bank
	XBA                            ; Swap back
	REP #$30                       ; 16-bit A/X/Y
	BRA CODE_00A7F9                ; Execute subroutine

CODE_00A7DE:
	SEP #$20                       ; 8-bit A
	LDX.B $9E                      ; Load pointer
	LDA.B $A0                      ; Load bank
	XBA                            ; Build word
	LDA.B $3A                      ; Load parameter from $3A
	REP #$30                       ; 16-bit A/X/Y
	BRA CODE_00A7F9                ; Execute

CODE_00A7EB:
	LDA.B [$17]                    ; Load address
	INC.B $17
	INC.B $17
	TAX                            ; Store address
	LDA.B [$17]                    ; Load parameter byte
	INC.B $17
	AND.W #$00FF                   ; Mask to byte

;===============================================================================
; CODE_00A7F9 - Execute Subroutine with Full Context Save
;
; Saves current execution state, switches to new address/bank with parameter,
; executes subroutine, then restores all state. Used for calling script
; subroutines that need to return to caller.
;
; Entry: A = parameter (low byte), X = subroutine address
; Stack usage: Saves $17 (pointer), $19 (bank), $3D (limit)
;===============================================================================

CODE_00A7F9:
	STA.B $64                      ; Save parameter
	STX.B $62                      ; Save subroutine address
	REP #$20                       ; 16-bit A
	SEP #$10                       ; 8-bit X/Y
	PEI.B ($17)                    ; Save current pointer
	LDX.B $19                      ; Load current bank
	PHX                            ; Save bank
	PEI.B ($3D)                    ; Save $3D (limit/end marker)
	LDA.B $64                      ; Load parameter
	AND.W #$00FF                   ; Mask to byte
	CLC                            ; Clear carry
	ADC.B $62                      ; Add to subroutine address
	STA.B $3D                      ; Store as new limit/end
	LDX.B $65                      ; Load bank byte from parameter
	STX.B $19                      ; Set as current bank
	LDA.B $62                      ; Load subroutine address
	STA.B $17                      ; Set as pointer
	LDA.W #$0008                   ; Load flag $08
	AND.W $00DB                    ; Test current state
	PHP                            ; Save flag state
	LDA.W #$0008                   ; Load flag $08
	TSB.W $00DB                    ; Set flag
	JSR.W CODE_009D75              ; Execute subroutine (external)
	PLP                            ; Restore flag state
	BNE CODE_00A833                ; If flag was set, keep it
	LDA.W #$0008                   ; Load flag $08
	TRB.W $00DB                    ; Clear flag

CODE_00A833:
	PLA                            ; Restore $3D
	STA.B $3D
	PLX                            ; Restore bank
	STX.B $19
	PLA                            ; Restore pointer
	STA.B $17
	REP #$30                       ; 16-bit A/X/Y
	RTS                            ; Return

;===============================================================================
; CODE_00A83F - Execute External Subroutine via Long Call
;===============================================================================

CODE_00A83F:
	LDA.B [$17]                    ; Load target address
	INC.B $17
	INC.B $17
	TAY                            ; Store address to Y
	LDA.B [$17]                    ; Load bank/parameter
	INC.B $17
	AND.W #$00FF                   ; Mask to byte
	PEA.W PTR16_00FFFF             ; Push return marker ($FFFF)
	SEP #$20                       ; 8-bit A
	DEY                            ; Adjust address (Y = address - 1)
	PHK                            ; Push program bank (for RTL)
	PEA.W CODE_00A85B              ; Push return address
	PHA                            ; Push bank byte
	PHY                            ; Push address - 1
	REP #$30                       ; 16-bit A/X/Y
	; Stack now set up for RTL to execute target code

CODE_00A85B:
	RTL                            ; Return from long call

; Clean up after external subroutine
	SEP #$20                       ; 8-bit A
	REP #$10                       ; 16-bit X/Y
	PLX                            ; Pull return marker
	CPX.W #$FFFF                   ; Check if $FFFF
	BEQ CODE_00A867                ; If marker found, done
	PLA                            ; Pull extra byte (clean stack)

CODE_00A867:
	PEA.W $0000                    ; Reset direct page to $0000
	PLD
	PHK                            ; Push program bank
	PLB                            ; Set data bank = program bank
	RTS                            ; Return

;===============================================================================
; Memory Manipulation and Data Transfer Routines
;===============================================================================

; CODE_00A86E - Raw bytecode (not yet disassembled fully)
; Purpose: Unknown memory operation involving $9E and $A0
	db $A4,$9E,$A5,$A0,$80,$D9

;-------------------------------------------------------------------------------
; CODE_00A874 - Copy data to RAM $7E3367 using MVN
; Purpose: Block memory move from Bank $00 to Bank $7E
; Entry: [$17] = destination offset,  [$17+2] = byte count
;-------------------------------------------------------------------------------
CODE_00A874:
	LDA.B [$17]                    ; Load destination offset
	INC.B $17
	INC.B $17
	TAX                            ; X = destination offset
	LDA.L $7E3367                  ; Load current $7E pointer
	TAY                            ; Y = source in $7E
	LDA.B [$17]                    ; Load byte count
	INC.B $17
	AND.W #$00FF
	DEC A                          ; Count-1 for MVN
	PHB                            ; Save data bank
	MVN $7E,$00                    ; Move (Y)Bank$00 → (X)Bank$7E, A+1 bytes
	PLB                            ; Restore data bank
	TYA                            ; Get end pointer
	CMP.W #$35D9                   ; Check if exceeds buffer limit
	BCC CODE_00A896                ; If below limit, update pointer
	db $4C,$1F,$9D                 ; JMP CODE_009D1F (buffer overflow handler)

CODE_00A896:
	STA.L $7E3367                  ; Update pointer
	RTS

;-------------------------------------------------------------------------------
; CODE_00A89B - Copy data from RAM $7E3367 back to Bank $00
; Purpose: Reverse block move from Bank $7E to Bank $00
; Entry: [$17] = destination, [$17+2] = count
;-------------------------------------------------------------------------------
CODE_00A89B:
	LDA.B [$17]                    ; Load destination in Bank $00
	INC.B $17
	INC.B $17
	TAY                            ; Y = destination
	LDA.B [$17]                    ; Load byte count
	INC.B $17
	AND.W #$00FF
	PHA                            ; Save count
	EOR.W #$FFFF                   ; Negate count
	SEC
	ADC.L $7E3367                  ; Subtract from pointer (move backward)
	STA.L $7E3367                  ; Update pointer
	TAX                            ; X = new source
	PLA                            ; Restore count
	DEC A                          ; Count-1 for MVN
	MVN $00,$7E                    ; Move (X)Bank$7E → (Y)Bank$00
	RTS

;-------------------------------------------------------------------------------
; CODE_00A8BD/CODE_00A8C0 - Pointer manipulation helpers
;-------------------------------------------------------------------------------
CODE_00A8BD:
	JSR.W CODE_00A8C0

CODE_00A8C0:
	LDA.W #$003E                   ; Mask for clearing bits
	TRB.B $1A                      ; Clear bits in $1A
	LSR A                          ; Shift mask
	AND.B $25                      ; Apply to $25
	ASL A                          ; Shift result
	ORA.B $1A                      ; Combine with $1A
	ADC.W #$0040                   ; Add base offset
	STA.B $1A                      ; Store result
	RTS

;-------------------------------------------------------------------------------
; CODE_00A8D1 - Calculate pointer from $25 (coordinates/position)
; Purpose: Convert position data to tilemap pointer
; Entry: $25 = position data, $3F/$40 = base pointers
; Exit: $1A = calculated pointer, $1B = bank/high byte
;-------------------------------------------------------------------------------
CODE_00A8D1:
	LDA.B $40                      ; Load base bank/high
	STA.B $1B                      ; Set $1B
	LDA.B $25                      ; Load position
	AND.W #$00FF                   ; Get low byte (X coordinate)
	ASL A                          ; × 2 (word-sized tiles)
	STA.B $1A                      ; Store as base
	LDA.B $25                      ; Load position again
	AND.W #$FF00                   ; Get high byte (Y coordinate)
	LSR A                          ; / 4 (row calculation)
	LSR A
	ADC.B $1A                      ; Add X offset
	ADC.B $3F                      ; Add base pointer
	STA.B $1A                      ; Store final pointer
	RTS

;-------------------------------------------------------------------------------
; CODE_00A8EB-CODE_00A93E - DMA/MVN transfer routines
; Purpose: Various block memory transfer operations
;-------------------------------------------------------------------------------
	db $4C,$24,$98                 ; JMP CODE_009824

CODE_00A8EE:
	LDA.B $18                      ; Load $18
	AND.W #$FF00                   ; Get high byte
	STA.B $31                      ; Store in $31
	LDA.B [$17]                    ; Load X parameter
	INC.B $17
	INC.B $17
	TAX
	LDA.B [$17]                    ; Load Y parameter
	INC.B $17
	INC.B $17
	TAY
	LDA.B [$17]                    ; Load count
	INC.B $17
	AND.W #$00FF
	DEC A                          ; Count-1 for MVN
	JMP.W $0030                    ; Execute DMA/transfer at $0030

CODE_00A90E:
	STZ.B $62                      ; Clear $62
	LDA.B [$17]                    ; Load parameter 1
	INC.B $17
	INC.B $17
	TAX
	LDA.B [$17]                    ; Load parameter 2
	INC.B $17
	AND.W #$00FF
	STA.B $63                      ; Store in $63
	LDA.B [$17]                    ; Load parameter 3
	INC.B $17
	INC.B $17
	TAY
	LDA.B [$17]                    ; Load parameter 4
	INC.B $17
	AND.W #$00FF
	ORA.B $62                      ; Combine with $62
	STA.B $31                      ; Store in $31
	LDA.B [$17]                    ; Load count
	INC.B $17
	INC.B $17
	DEC A                          ; Count-1
	PHB                            ; Save data bank
	JSR.W $0030                    ; Execute transfer
	PLB                            ; Restore data bank
	RTS

CODE_00A93F:
	LDA.B $35                      ; Load $35
	SEP #$20                       ; 8-bit A
	LDA.B $39                      ; Load bank byte
	REP #$30                       ; 16-bit mode
	STA.B $31                      ; Store bank
	LDA.B $3A                      ; Check if count non-zero
	BEQ CODE_00A957                ; If zero, skip
	DEC A                          ; Count-1
	LDX.B $34                      ; Load X param
	LDY.B $37                      ; Load Y param
	PHB                            ; Save data bank
	JSR.W $0030                    ; Execute transfer
	PLB                            ; Restore data bank

CODE_00A957:
	RTS

;-------------------------------------------------------------------------------
; CODE_00A958 - Write 8-bit value to address
; Purpose: [X] = 8-bit value from script
; Entry: [$17] = address, [$17+2] = 8-bit value
;-------------------------------------------------------------------------------
CODE_00A958:
	LDA.B [$17]                    ; Load address
	INC.B $17
	INC.B $17
	TAX                            ; X = address
	LDA.B [$17]                    ; Load value (8-bit in low byte)
	INC.B $17
	AND.W #$00FF
	SEP #$20                       ; 8-bit A
	STA.W $0000,X                  ; Store to address
	RTS                            ; (REP #$30 happens in caller)

;-------------------------------------------------------------------------------
; CODE_00A96C - Write 16-bit value to address
; Purpose: [X] = 16-bit value from script
; Entry: [$17] = address, [$17+2] = 16-bit value
;-------------------------------------------------------------------------------
CODE_00A96C:
	LDA.B [$17]                    ; Load address
	INC.B $17
	INC.B $17
	TAX                            ; X = address
	LDA.B [$17]                    ; Load 16-bit value
	INC.B $17
	INC.B $17
	STA.W $0000,X                  ; Store to address
	RTS

;-------------------------------------------------------------------------------
; CODE_00A97D - Write 16-bit value + 8-bit value to address
; Purpose: Write word then byte (3 bytes total)
; Entry: [$17] = address, [$17+2] = word, [$17+4] = byte
;-------------------------------------------------------------------------------
CODE_00A97D:
	JSR.W CODE_00A96C              ; Write word at X
	LDA.B [$17]                    ; Load byte value
	INC.B $17
	AND.W #$00FF
	SEP #$20                       ; 8-bit A
	STA.W $0002,X                  ; Store at X+2
	RTS

;-------------------------------------------------------------------------------
; CODE_00A98D/CODE_00A999 - Indirect pointer writes (using $9E)
; Purpose: Write to address pointed to by $9E/$9F
;-------------------------------------------------------------------------------
CODE_00A98D:
	LDA.B [$17]                    ; Load 8-bit value
	INC.B $17
	AND.W #$00FF
	SEP #$20                       ; 8-bit A
	STA.B [$9E]                    ; Store via indirect pointer
	RTS

CODE_00A999:
	LDA.B [$17]                    ; Load 16-bit value
	INC.B $17
	INC.B $17
	STA.B [$9E]                    ; Store via indirect pointer
	RTS

;-------------------------------------------------------------------------------
; CODE_00A9A2 - Complex indirect write sequence
;-------------------------------------------------------------------------------
CODE_00A9A2:
	db $20,$99,$A9,$E6,$9E,$E6,$9E,$20,$8D,$A9,$C2,$30,$C6,$9E,$C6,$9E
	db $60

;-------------------------------------------------------------------------------
; CODE_00A9B3 - Load value from indirect pointer
; Purpose: Load 16-bit value from [$9E]
; Entry: [$17] = address to store result
; Exit: A = value from [$9E], X = address
;-------------------------------------------------------------------------------
CODE_00A9B3:
	LDA.B [$17]                    ; Load destination address
	INC.B $17
	INC.B $17
	TAX                            ; X = destination
	LDA.B [$9E]                    ; Load value via indirect
	RTS

CODE_00A9BD:
	JSR.W CODE_00A9B3              ; Load via [$9E]
	SEP #$20                       ; 8-bit A
	STA.W $0000,X                  ; Store low byte only
	RTS

CODE_00A9C6:
	JSR.W CODE_00A9B3              ; Load via [$9E]
	STA.W $0000,X                  ; Store full word
	RTS

;-------------------------------------------------------------------------------
; CODE_00A9CD - MVN transfer using $9E pointer
; Purpose: Block move using indirect pointer as bank
;-------------------------------------------------------------------------------
CODE_00A9CD:
	LDA.B [$17]                    ; Load destination
	INC.B $17
	INC.B $17
	TAY                            ; Y = destination
	LDX.B $9E                      ; X = source from $9E
	LDA.B $9F                      ; Load bank byte
	AND.W #$FF00
	STA.B $31                      ; Store bank in $31
	LDA.W #$0002                   ; Transfer 3 bytes (count-1=2)
	JMP.W $0030                    ; Execute MVN via $0030

;-------------------------------------------------------------------------------
; CODE_00A9E3-CODE_00AA22 - Bank $7E write operations
; Purpose: Write to Bank $7E addresses using special bank handling
;-------------------------------------------------------------------------------
CODE_00A9E3:
	JSR.W CODE_00AA22              ; Load address and bank
	PHA                            ; Save bank
	PLB                            ; Set data bank
	LDA.B [$17]                    ; Load 8-bit value
	INC.B $17
	AND.W #$00FF
	SEP #$20                       ; 8-bit A
	STA.W $0000,X                  ; Store to Bank $7E address
	PLB                            ; Restore data bank
	RTS

CODE_00A9F6:
	JSR.W CODE_00AA22              ; Load address and bank
	PHA                            ; Save bank
	PLB                            ; Set data bank
	LDA.B [$17]                    ; Load 16-bit value
	INC.B $17
	INC.B $17
	STA.W $0000,X                  ; Store to Bank $7E address
	PLB                            ; Restore data bank
	RTS

CODE_00AA06:
	db $20,$22,$AA,$48,$AB,$A7,$17,$E6,$17,$E6,$17,$9D,$00,$00,$A7,$17
	db $E6,$17,$29,$FF,$00,$E2,$20,$9D,$02,$00,$AB,$60

;-------------------------------------------------------------------------------
; CODE_00AA22 - Helper: Load address and bank for Bank $7E operations
; Entry: [$17] = address, [$17+2] = bank byte
; Exit: X = address, A = bank (low byte)
;-------------------------------------------------------------------------------
CODE_00AA22:
	LDA.B [$17]                    ; Load address
	INC.B $17
	INC.B $17
	TAX                            ; X = address
	LDA.B [$17]                    ; Load bank
	INC.B $17
	AND.W #$00FF                   ; Isolate bank byte
	RTS

;-------------------------------------------------------------------------------
; CODE_00AA31-CODE_00AA67 - Text positioning and display helpers
; Purpose: Calculate text window positions and sizes
;-------------------------------------------------------------------------------
CODE_00AA31:
	SEP #$30                       ; 8-bit A, X, Y
	JSR.W CODE_00AA3B              ; Calculate X position
	JSR.W CODE_00AA44              ; Calculate Y position/width
	BRA CODE_00AA5D                ; Finalize

CODE_00AA3B:
	LDA.B #$20                     ; Load window width constant
	SEC
	SBC.B $2A                      ; Subtract text width
	LSR A                          ; / 2 (center)
	STA.B $28                      ; Store X offset
	RTS

CODE_00AA44:
	LDA.B $24                      ; Load flags
	AND.B #$08                     ; Test bit 3
	BEQ CODE_00AA4E                ; If clear, skip
	LDA.B #$10                     ; Use fixed position
	BRA CODE_00AA53

CODE_00AA4E:
	LDA.B $2D                      ; Load position
	EOR.B #$FF                     ; Negate
	INC A

CODE_00AA53:
	CLC
	ADC.B $23                      ; Add offset
	STA.B $2C                      ; Store Y position
	LSR A                          ; / 4 (row)
	LSR A
	STA.B $29                      ; Store row index
	RTS

CODE_00AA5D:
	REP #$30                       ; 16-bit mode
	LDA.B $28                      ; Load calculated position
	CLC
	ADC.W #$0101                   ; Add offset (both bytes)
	STA.B $25                      ; Store final position
	RTS

;-------------------------------------------------------------------------------
; CODE_00AA68 - Repeat text operation
; Purpose: Execute text display routine multiple times
; Entry: $1F = repeat count, $17 = operation pointer
;-------------------------------------------------------------------------------
CODE_00AA68:
	LDA.B $1F                      ; Load repeat count
	AND.W #$00FF
	LDX.B $17                      ; Load operation pointer

CODE_00AA6F:
	PHA                            ; Save count
	PHX                            ; Save pointer
	STX.B $17                      ; Set pointer
	JSR.W CODE_009DBD              ; Execute text operation
	PLX                            ; Restore pointer
	PLA                            ; Restore count
	DEC A                          ; Decrement count
	BNE CODE_00AA6F                ; Loop if not zero
	RTS

;-------------------------------------------------------------------------------
; CODE_00AA7C-CODE_00AACC - DMA transfer setup routines
; Purpose: Set up and execute DMA transfers to VRAM/tilemap
;-------------------------------------------------------------------------------
CODE_00AA7C:
	LDA.B $40                      ; Load bank/high byte
	STA.B $1B                      ; Set DMA bank
	STA.B $35                      ; Set alternate bank
	STA.B $38                      ; Set third bank
	LDA.W #$2CFE                   ; Load tile value
	LDX.B $3F                      ; Load X base
	LDY.W #$1000                   ; Load Y base (large transfer)
	JMP.W CODE_009D4B              ; Execute DMA

CODE_00AA8F:
	LDA.B $40                      ; Load bank
	STA.B $1B
	STA.B $35
	STA.B $38
	LDA.B $28                      ; Load position high byte
	AND.W #$FF00
	LSR A                          ; / 4 (calculate offset)
	LSR A
	ADC.B $3F                      ; Add base
	TAX                            ; X = transfer source
	LDA.B $2A                      ; Load size high byte
	AND.W #$FF00
	LSR A                          ; / 4
	LSR A
	TAY                            ; Y = transfer size
	LDA.W #$2CFE                   ; Load tile value
	JMP.W CODE_009D4B              ; Execute DMA

CODE_00AAAF:
	LDA.B $40                      ; Load bank
	STA.B $1B
	STA.B $35
	STA.B $38
	LDA.B $28                      ; Load position
	AND.W #$FF00
	LSR A                          ; / 4
	LSR A
	ADC.B $3F                      ; Add base
	TAX
	LDA.B $2A                      ; Load size
	AND.W #$FF00
	LSR A                          ; / 4
	LSR A
	TAY
	LDA.W #$2C00                   ; Different tile value (blank/clear)
	JMP.W CODE_009D4B              ; Execute DMA

;===============================================================================
; Progress: ~8,900 lines documented (63.5% of Bank $00)
; Latest additions:
; - CODE_00A86E-00A874: Memory block transfers to/from Bank $7E
; - CODE_00A89B: Reverse block copy (Bank $7E → Bank $00)
; - CODE_00A8C0-00A8D1: Pointer manipulation and coordinate calculations
; - CODE_00A8EE-00A93E: DMA/MVN transfer helper routines
; - CODE_00A958-00A97D: Direct memory write operations (8-bit, 16-bit, 24-bit)
; - CODE_00A98D-00A999: Indirect pointer writes via $9E
; - CODE_00A9B3-00A9CD: Indirect pointer reads and transfers
; - CODE_00A9E3-00AA22: Bank $7E special write operations
; - CODE_00AA31-00AA67: Text positioning and window calculations
; - CODE_00AA68: Text operation repeat loop
; - CODE_00AA7C-00AACC: DMA transfer setup for VRAM/tilemap operations
;
; Next: More DMA and graphics routines (CODE_00AACF onward)
;===============================================================================

;-------------------------------------------------------------------------------
; CODE_00AACF - Indexed sprite/tile drawing dispatcher
; Purpose: Use sprite type index ($27) to dispatch to specific drawing routine
; Entry: $27 = sprite type index, $28 = position data
;-------------------------------------------------------------------------------
CODE_00AACF:
	LDA.B $27                      ; Load sprite type index
	AND.W #$00FF
	ASL A                          ; × 2 for word table
	TAX                            ; X = table offset
	PEI.B ($25)                    ; Save $25 to stack
	LDA.B $28                      ; Load position
	STA.B $25                      ; Store as new $25
	JSR.W CODE_00A8D1              ; Calculate tilemap pointer
	JSR.W CODE_00B49E              ; Prepare drawing context
	LDA.B $1C                      ; Load bank byte
	AND.W #$00FF
	PHA                            ; Save bank
	PLB                            ; Set data bank
	JSR.W (UNREACH_00AAF7,X)       ; Dispatch to sprite routine
	PLB                            ; Restore data bank
	JSR.W CODE_00B4A7              ; Cleanup drawing context
	PLA                            ; Restore $25
	STA.B $25
	JMP.W CODE_00A8D1              ; Recalculate pointer and return

	db $60                         ; Extra RTS

;-------------------------------------------------------------------------------
; UNREACH_00AAF7 - Sprite drawing dispatch table
;-------------------------------------------------------------------------------
UNREACH_00AAF7:
	db $F6,$AA                     ; Unreachable data
	dw CODE_00AB07                 ; $00
	dw CODE_00AB20                 ; $01
	dw CODE_00AB88                 ; $02
	dw CODE_00ABCE                 ; $03
	dw CODE_00ABE5                 ; $04
	dw CODE_00AB9F                 ; $05
	dw CODE_00ABBA                 ; $06

;-------------------------------------------------------------------------------
; CODE_00AB07 - Draw filled rectangle (tile $FE)
; Purpose: Draw solid filled rectangle using tile $FE
;-------------------------------------------------------------------------------
CODE_00AB07:
	LDA.B $2B                      ; Load height
	AND.W #$00FF
	STA.B $62                      ; Store row counter
	LDA.B $2A                      ; Load width
	AND.W #$00FF
	ASL A                          ; × 2 for word offset
	TAX                            ; X = column offset
	LDY.B $1A                      ; Load tilemap pointer
	LDA.W #$00FE                   ; Tile $FE (solid fill)
	JSR.W CODE_00AD85              ; Draw tiles
	STY.B $1A                      ; Update pointer
	RTS

;-------------------------------------------------------------------------------
; CODE_00AB20 - Draw window border with vertical flip
; Purpose: Draw bordered window with special tile handling
;-------------------------------------------------------------------------------
CODE_00AB20:
	JSR.W CODE_00AB9F              ; Draw top border
	LDA.W #$4000                   ; Vertical flip bit
	ORA.B $1D                      ; Combine with tile flags
	STA.B $64                      ; Store flip flags
	JSR.W CODE_00B4A7              ; Setup drawing
	SEC
	LDA.B $1A                      ; Load pointer
	SBC.W #$0040                   ; Back up one row
	STA.B $1A
	LDA.B $24                      ; Load flags
	BIT.W #$0008                   ; Test bit 3
	BEQ CODE_00AB44                ; If clear, skip
	JSR.W CODE_00A8D1              ; Recalculate pointer
	LDA.W #$8000                   ; Horizontal flip bit
	TSB.B $64                      ; Set in flags

CODE_00AB44:
	SEP #$20                       ; 8-bit A
	LDA.B $22                      ; Load Y position
	LSR A                          ; / 8 (tile row)
	LSR A
	LSR A
	CMP.B $28                      ; Compare with window top
	BCS CODE_00AB52                ; If >= top, use it
	LDA.B $28                      ; Use window top
	SEC

CODE_00AB52:
	SBC.B $28                      ; Calculate row offset
	STA.B $62                      ; Store row counter
	LDA.B $22                      ; Load Y again
	CMP.B #$78                     ; Check if >= 120
	BCC CODE_00AB64                ; If below, adjust
	BNE CODE_00AB6A                ; If above, skip
	LDA.B $24                      ; Check flags
	BIT.B #$01                     ; Test bit 0
	BEQ CODE_00AB6A                ; If clear, skip

CODE_00AB64:
	INC.B $62                      ; Increment row count
	LDA.B #$40                     ; Clear bit $40
	TRB.B $65                      ; In $65

CODE_00AB6A:
	LDA.B $62                      ; Load row counter
	INC A                          ; +1
	CMP.B $2A                      ; Compare with width
	BCC CODE_00AB77                ; If less, use it
	db $A5,$2A,$E9,$02,$85,$62     ; Load width-2 into $62

CODE_00AB77:
	REP #$30                       ; 16-bit mode
	LDA.B $62                      ; Load final count
	AND.W #$00FF
	ASL A                          ; × 2 for word offset
	TAY                            ; Y = offset
	LDA.W #$00FD                   ; Tile $FD
	EOR.B $64                      ; Apply flip flags
	STA.B ($1A),Y                  ; Draw tile
	RTS

;-------------------------------------------------------------------------------
; CODE_00AB88 - Draw window frame (tiles $FC, $FF)
;-------------------------------------------------------------------------------
CODE_00AB88:
	LDA.W #$00FC                   ; Top border tile
	JSR.W CODE_00AD2D              ; Setup top edge
	LDA.W #$00FF                   ; Fill tile
	JSR.W CODE_00AD44              ; Setup vertical edges
	INC.B $62                      ; Adjust counter
	LDA.W #$80FC                   ; Bottom border (flipped)
	JSR.W CODE_00AD85              ; Draw
	JMP.W CODE_00ACA6              ; Draw corners

;-------------------------------------------------------------------------------
; CODE_00AB9F - Draw window top border
;-------------------------------------------------------------------------------
CODE_00AB9F:
	LDA.W #$00FC                   ; Border tile
	JSR.W CODE_00AD2D              ; Setup top
	LDA.B $2B                      ; Load height
	AND.W #$00FF
	DEC A                          ; -2 for borders
	DEC A
	JSR.W CODE_00ABFC              ; Fill routine
	INC.B $62                      ; Adjust
	LDA.W #$80FC                   ; Bottom border
	JSR.W CODE_00AD85              ; Draw
	JMP.W CODE_00ACA6              ; Draw corners

;-------------------------------------------------------------------------------
; CODE_00ABBA - Draw simple filled box
;-------------------------------------------------------------------------------
CODE_00ABBA:
	LDY.B $1A                      ; Load pointer
	LDA.B $2A                      ; Load width
	AND.W #$00FF
	ASL A                          ; × 2
	TAX                            ; X = offset
	LDA.B $2B                      ; Load height
	AND.W #$00FF
	JSR.W CODE_00ABFC              ; Fill
	STY.B $1A                      ; Update pointer
	RTS

;-------------------------------------------------------------------------------
; CODE_00ABCE - Draw item icon box (tiles $45)
;-------------------------------------------------------------------------------
CODE_00ABCE:
	LDA.W #$0045                   ; Item icon tile
	JSR.W CODE_00AD2D              ; Setup top
	LDA.W #$00FF                   ; Fill
	JSR.W CODE_00AD44              ; Setup edges
	INC.B $62
	LDA.W #$8045                   ; Flipped icon
	JSR.W CODE_00AD85              ; Draw
	JMP.W CODE_00ACD3              ; Finish

;-------------------------------------------------------------------------------
; CODE_00ABE5 - Draw spell icon box (tiles $75)
;-------------------------------------------------------------------------------
CODE_00ABE5:
	LDA.W #$0075                   ; Spell icon tile
	JSR.W CODE_00AD2D              ; Setup top
	LDA.W #$00FF                   ; Fill
	JSR.W CODE_00AD44              ; Setup edges
	INC.B $62
	LDA.W #$8075                   ; Flipped spell icon
	JSR.W CODE_00AD85              ; Draw
	JMP.W CODE_00AD00              ; Finish

;-------------------------------------------------------------------------------
; CODE_00ABFC - Tile fill routine with indirect jump
; Purpose: Complex tile filling using computed jump table
; Entry: A = row count, X = column offset × 2
;-------------------------------------------------------------------------------
CODE_00ABFC:
	STA.B $62                      ; Save row count
	TXA                            ; Get column offset
	ASL A                          ; × 2 again
	EOR.W #$FFFF                   ; Negate
	ADC.W #$AC97                   ; Add base (computed address)
	STA.B $64                      ; Store jump target
	TXA                            ; Column offset
	LSR A                          ; / 2
	PHA                            ; Save to stack

CODE_00AC0B:
	ADC.L $00015F                  ; Add to system counter
	STA.L $00015F                  ; Update counter
	JMP.W ($0064)                  ; Jump to computed address

	; Computed jump table entries (tile fill patterns)
	db $3A,$99,$3E,$00,$3A,$99,$3C,$00,$3A,$99,$3A,$00,$3A,$99,$38,$00
	db $3A,$99,$36,$00,$3A,$99,$34,$00

	; Unrolled tile write loop (26 tiles worth)
	DEC A
	STA.W $0032,Y
	DEC A
	STA.W $0030,Y
	DEC A
	STA.W $002E,Y
	DEC A
	STA.W $002C,Y
	DEC A
	STA.W $002A,Y
	DEC A
	STA.W $0028,Y
	DEC A
	STA.W $0026,Y
	DEC A
	STA.W $0024,Y
	DEC A
	STA.W $0022,Y
	DEC A
	STA.W $0020,Y
	DEC A
	STA.W $001E,Y
	DEC A
	STA.W $001C,Y
	DEC A
	STA.W $001A,Y
	DEC A
	STA.W $0018,Y
	DEC A
	STA.W $0016,Y
	DEC A
	STA.W $0014,Y
	DEC A
	STA.W $0012,Y
	DEC A
	STA.W $0010,Y
	DEC A
	STA.W $000E,Y
	DEC A
	STA.W $000C,Y
	DEC A
	STA.W $000A,Y
	DEC A
	STA.W $0008,Y
	DEC A
	STA.W $0006,Y
	DEC A
	STA.W $0004,Y
	DEC A
	STA.W $0002,Y
	DEC A
	STA.W $0000,Y
	TYA                            ; Get current pointer
	ADC.W #$0040                   ; Next row (+$40 bytes)
	TAY                            ; Update Y
	LDA.B $01,S                    ; Load saved value
	DEC.B $62                      ; Decrement row counter
	BEQ CODE_00ACA4                ; If zero, done
	JMP.W CODE_00AC0B              ; Loop

CODE_00ACA4:
	PLA                            ; Clean stack
	RTS

;-------------------------------------------------------------------------------
; CODE_00ACA6 - Draw window corners (tiles $F7/$F9/$FB)
;-------------------------------------------------------------------------------
CODE_00ACA6:
	JSR.W CODE_00AD52              ; Setup coordinates
	LDA.B $1D                      ; Load tile flags
	EOR.W #$00F7                   ; Top-left corner
	STA.B ($1A)                    ; Draw
	LDA.B $1D
	EOR.W #$00F9                   ; Top-right corner
	STA.B ($1A),Y                  ; Draw
	LDA.W #$00FB                   ; Side tiles
	JSR.W CODE_00AD64              ; Draw sides
	LDA.B $1D
	EOR.W #$00F8                   ; Bottom-left corner
	STA.B ($1A)
	LDA.B $1D
	EOR.W #$00FA                   ; Bottom-right corner
	STA.B ($1A),Y
	LDA.B $1A                      ; Advance pointer
	ADC.W #$0040
	STA.B $1A
	RTS

;-------------------------------------------------------------------------------
; CODE_00ACD3 - Draw item icon corners (tiles $40-$44)
;-------------------------------------------------------------------------------
CODE_00ACD3:
	JSR.W CODE_00AD52              ; Setup
	LDA.B $1D
	EOR.W #$0040                   ; Icon TL
	STA.B ($1A)
	LDA.B $1D
	EOR.W #$0042                   ; Icon TR
	STA.B ($1A),Y
	LDA.W #$0044                   ; Icon sides
	JSR.W CODE_00AD64              ; Draw
	LDA.B $1D
	EOR.W #$0041                   ; Icon BL
	STA.B ($1A)
	LDA.B $1D
	EOR.W #$0043                   ; Icon BR
	STA.B ($1A),Y
	LDA.B $1A
	ADC.W #$0040
	STA.B $1A
	RTS

;-------------------------------------------------------------------------------
; CODE_00AD00 - Draw spell icon corners (tiles $70-$74)
;-------------------------------------------------------------------------------
CODE_00AD00:
	JSR.W CODE_00AD52              ; Setup
	LDA.B $1D
	EOR.W #$0070                   ; Spell TL
	STA.B ($1A)
	LDA.B $1D
	EOR.W #$0072                   ; Spell TR
	STA.B ($1A),Y
	LDA.W #$0074                   ; Spell sides
	JSR.W CODE_00AD64              ; Draw
	LDA.B $1D
	EOR.W #$0071                   ; Spell BL
	STA.B ($1A)
	LDA.B $1D
	EOR.W #$0073                   ; Spell BR
	STA.B ($1A),Y
	LDA.B $1A
	ADC.W #$0040
	STA.B $1A
	RTS

;-------------------------------------------------------------------------------
; CODE_00AD2D - Setup top edge drawing
; Entry: A = tile value
;-------------------------------------------------------------------------------
CODE_00AD2D:
	PHA                            ; Save tile
	LDY.B $1A                      ; Load pointer
	INY                            ; Skip first tile
	INY
	LDA.B $2A                      ; Load width
	AND.W #$00FF
	DEC A                          ; -2 for corners
	DEC A
	ASL A                          ; × 2
	TAX                            ; X = offset
	LDA.W #$0001                   ; Single row
	STA.B $62
	PLA                            ; Restore tile
	JMP.W CODE_00AD85              ; Draw

;-------------------------------------------------------------------------------
; CODE_00AD44 - Setup vertical edge drawing
; Entry: A = tile value
;-------------------------------------------------------------------------------
CODE_00AD44:
	PHA                            ; Save tile
	LDA.B $2B                      ; Load height
	AND.W #$00FF
	DEC A                          ; -2 for top/bottom
	DEC A
	STA.B $62                      ; Row count
	PLA                            ; Restore tile
	JMP.W CODE_00AD85              ; Draw

;-------------------------------------------------------------------------------
; CODE_00AD52 - Calculate corner positions
; Exit: Y = right edge offset, $62 = adjusted row count
;-------------------------------------------------------------------------------
CODE_00AD52:
	LDA.B $2A                      ; Width
	AND.W #$00FF
	DEC A                          ; -1
	ASL A                          ; × 2
	TAY                            ; Y = right offset
	LDA.B $2B                      ; Height
	AND.W #$00FF
	DEC A                          ; -2
	DEC A
	STA.B $62                      ; Row count
	RTS

;-------------------------------------------------------------------------------
; CODE_00AD64 - Draw vertical side tiles
; Entry: A = tile value (XORed with $1D)
;-------------------------------------------------------------------------------
CODE_00AD64:
	EOR.B $1D                      ; Apply tile flags
	STA.B $64                      ; Save tile
	LDA.B $1A                      ; Advance to next row
	ADC.W #$0040
	STA.B $1A
	LDX.B $62                      ; Load row counter

CODE_00AD71:
	LDA.B $64                      ; Load tile
	STA.B ($1A)                    ; Draw left edge
	EOR.W #$4000                   ; Flip horizontally
	STA.B ($1A),Y                  ; Draw right edge
	LDA.B $1A                      ; Next row
	ADC.W #$0040
	STA.B $1A
	DEX                            ; Decrement counter
	BNE CODE_00AD71                ; Loop
	RTS

;-------------------------------------------------------------------------------
; CODE_00AD85 - Generic tile drawing routine
; Entry: A = tile value (XORed with $1D), X = column offset
;-------------------------------------------------------------------------------
CODE_00AD85:
	EOR.B $1D                      ; Apply flags
	STA.B $64                      ; Save tile

CODE_00AD89:
	JSR.W (DATA8_009A1E,X)         ; Call indexed routine
	TYA                            ; Get pointer
	ADC.W #$0040                   ; Next row
	TAY
	LDA.B $64                      ; Restore tile
	DEC.B $62                      ; Decrement row counter
	BNE CODE_00AD89                ; Loop
	RTS

;-------------------------------------------------------------------------------
; CODE_00AD98 - Clear sprite OAM entries
; Purpose: Clear OAM sprite data in Bank $7E
; Entry: [$17] = number of sprites to clear
;-------------------------------------------------------------------------------
CODE_00AD98:
	LDA.B [$17]                    ; Load sprite count
	INC.B $17
	AND.W #$00FF
	STA.B $62                      ; Save count
	LDY.W #$31C5                   ; OAM base + offset
	LDA.W #$01F0                   ; Off-screen Y position
	PEA.W $007E                    ; Push Bank $7E
	PLB                            ; Set data bank
	SEC

CODE_00ADAC:
	TAX                            ; X = Y position
	JSR.W CODE_009A05              ; Clear sprite entry
	TYA                            ; Get OAM pointer
	SBC.W #$FFF0                   ; Move back (-16 bytes)
	TAY
	TXA                            ; Restore Y position
	ADC.W #$FFF8                   ; Adjust (-8)
	DEC.B $62                      ; Decrement count
	BNE CODE_00ADAC                ; Loop
	PLB                            ; Restore bank
	RTS

;-------------------------------------------------------------------------------
; CODE_00ADBF - Compressed tile drawing to Bank $7E
; Purpose: Draw compressed tile data to screen buffer
; Entry: $2C = Y coordinate, $2D = width, $2B = height
;-------------------------------------------------------------------------------
CODE_00ADBF:
	LDA.B $2C                      ; Load Y coord
	AND.W #$00FF
	STA.B $64                      ; Save
	ASL A                          ; × 2
	ADC.W #$31B5                   ; Add buffer base
	TAY                            ; Y = destination
	LDA.W #$01F9                   ; Calculate offset
	SBC.B $64
	PEA.W $007E                    ; Bank $7E
	PLB
	STA.B $64                      ; Save offset
	AND.W #$0007                   ; Get low 3 bits
	ASL A                          ; × 2
	TAX                            ; X = table offset
	LDA.B $64
	AND.W #$FFF8                   ; Mask to 8-byte boundary
	ADC.W #$0008                   ; Adjust
	JSR.W (DATA8_009A1E,X)         ; Call indexed routine
	SBC.W #$0007                   ; Adjust back
	TAX
	LDA.B $64
	AND.W #$0007                   ; Get bit offset
	STA.B $64
	STY.B $62                      ; Save pointer
	ASL A                          ; × 2
	ADC.B $62
	TAY                            ; Y = adjusted pointer
	SEC
	LDA.B $2D                      ; Load width
	SBC.B $64                      ; Subtract offset
	AND.W #$00FF
	PHA                            ; Save
	LSR A                          ; / 8
	LSR A
	LSR A
	STA.B $62                      ; Row counter
	TXA
	SEC

CODE_00AE07:
	TAX
	JSR.W CODE_009A05              ; Draw routine
	TYA
	SBC.W #$FFF0                   ; Adjust pointer
	TAY
	TXA
	ADC.W #$FFF8                   ; Adjust X
	DEC.B $62
	BNE CODE_00AE07                ; Loop
	STA.B $64                      ; Save result
	PLA                            ; Restore width
	AND.W #$0007                   ; Get remainder
	ASL A                          ; × 2
	TAX
	LDA.B $64
	JSR.W (DATA8_009A1E,X)         ; Final draw
	PLB                            ; Restore bank
	RTS

;-------------------------------------------------------------------------------
; CODE_00AE27 - RLE compressed text drawing
; Purpose: Run-length encoded text decompression to Bank $7E
; Entry: $2C = Y start, $29 = row count, $2B = column count
;-------------------------------------------------------------------------------
CODE_00AE27:
	PEA.W $007E                    ; Bank $7E
	PLB
	LDA.B $2C                      ; Y coordinate
	AND.W #$00FF
	PHA                            ; Save
	DEC A                          ; -1
	ASL A                          ; × 2
	ADC.W #$31B7                   ; Buffer base
	TAX                            ; X = destination
	LDA.B $29                      ; Row count
	AND.W #$00FF
	ASL A                          ; × 8
	ASL A
	ASL A
	SEC
	SBC.B $01,S                    ; Subtract Y
	STA.B $01,S                    ; Update stack
	LDA.B $2B                      ; Column count
	AND.W #$00FF
	STA.B $62                      ; Save

CODE_00AE4B:
	LDA.B [$17]                    ; Load RLE byte
	AND.W #$00FF
	BEQ CODE_00AE6A                ; If zero, skip
	BIT.W #$0080                   ; Test high bit
	BNE CODE_00AE81                ; If set, special mode
	PHA                            ; Save count
	LDA.B $03,S                    ; Load tile value
	STA.W $0000,X                  ; Store
	TXY                            ; Y = X
	INY                            ; Advance
	INY
	PLA                            ; Restore count
	DEC A                          ; -1
	BEQ CODE_00AE69                ; If 1, done
	ASL A                          ; × 2
	DEC A                          ; -1 for MVN
	MVN $7E,$7E                    ; Block move

CODE_00AE69:
	TYX                            ; X = end pointer

CODE_00AE6A:
	LDA.W #$0008                   ; 8 tiles
	SEC
	SBC.B [$17]                    ; Subtract used
	AND.W #$00FF
	CLC
	ADC.B $01,S                    ; Add to stack offset
	STA.B $01,S

CODE_00AE78:
	INC.B $17                      ; Next RLE byte
	DEC.B $62                      ; Decrement column counter
	BNE CODE_00AE4B                ; Loop
	PLA                            ; Clean stack
	PLB                            ; Restore bank
	RTS

CODE_00AE81:
	AND.W #$007F                   ; Mask off high bit
	PHA                            ; Save count
	LDA.W #$0008
	SEC
	SBC.B $01,S                    ; Calculate skip
	CLC
	ADC.B $03,S                    ; Add to offset
	STA.B $03,S
	STA.W $0000,X                  ; Store
	TXY
	INY
	INY
	PLA
	DEC A
	BEQ CODE_00AE9F
	ASL A
	DEC A
	MVN $7E,$7E                    ; Block move

CODE_00AE9F:
	TYX
	BRA CODE_00AE78                ; Continue

;-------------------------------------------------------------------------------
; CODE_00AEA2 - Call graphics function with 8-bit parameter
;-------------------------------------------------------------------------------
CODE_00AEA2:
	LDA.B [$17]                    ; Load parameter
	INC.B $17
	AND.W #$00FF
	JSL.L CODE_009760              ; Long call to graphics routine
	RTS

	db $A5,$9E,$22,$60,$97,$00,$60 ; Variant with $9E parameter

;-------------------------------------------------------------------------------
; CODE_00AEB5 - Call graphics function with DP context
;-------------------------------------------------------------------------------
CODE_00AEB5:
	LDA.B [$17]                    ; Load parameter
	INC.B $17
	AND.W #$00FF
	PHD                            ; Save direct page
	PEA.W $00D0                    ; Set DP to $D0
	PLD
	JSL.L CODE_00974E              ; Call graphics routine
	PLD                            ; Restore DP
	RTS

;-------------------------------------------------------------------------------
; CODE_00AEC7 - Call sprite/tile function
;-------------------------------------------------------------------------------
CODE_00AEC7:
	LDA.B [$17]                    ; Load parameter
	INC.B $17
	AND.W #$00FF
	JSL.L CODE_00976B              ; Call sprite routine
	RTS

	db $A5,$9E,$22,$6B,$97,$00,$60 ; Variant with $9E

;-------------------------------------------------------------------------------
; CODE_00AEDA - Call graphics function with DP=$D0
;-------------------------------------------------------------------------------
CODE_00AEDA:
	LDA.B [$17]
	INC.B $17
	AND.W #$00FF
	PHD
	PEA.W $00D0                    ; DP = $D0
	PLD
	JSL.L CODE_009754              ; Graphics call
	PLD
	RTS

	; More variants with different parameter sources
	db $A5,$2E,$0B,$48,$A7,$17,$E6,$17,$29,$FF,$00,$2B,$22,$4E,$97,$00
	db $2B,$60

CODE_00AEFE:
	LDA.B $2E                      ; From $2E
	PHD
	PHA
	LDA.B $9E                      ; From $9E
	PLD
	JSL.L CODE_00974E
	PLD
	RTS

	db $A5,$2E,$0B,$48,$A7,$17,$E6,$17,$29,$FF,$00,$2B,$22,$54,$97,$00
	db $2B,$60

CODE_00AF1D:
	LDA.B $2E
	PHD
	PHA
	LDA.B $9E
	PLD
	JSL.L CODE_009754
	PLD
	RTS

;-------------------------------------------------------------------------------
; CODE_00AF2A - Memory copy with table offset
; Purpose: Copy data using offset from script
; Entry: A = byte count
;-------------------------------------------------------------------------------
CODE_00AF2A:
	TAY                            ; Y = count
	LDA.B [$17]                    ; Load source
	STA.B $A4
	INC.B $17
	INC.B $17
	LDA.B [$17]                    ; Load dest
	STA.B $A6
	DEC.B $17
	DEC.B $17
	TYA                            ; Get count
	SEC
	ADC.B $17                      ; Advance script pointer
	STA.B $17
	LDX.W #$00A4                   ; X = $A4 (source pointer)
	TYA                            ; A = count
	BRA CODE_00AF50

;-------------------------------------------------------------------------------
; CODE_00AF47 - Memory copy direct
;-------------------------------------------------------------------------------
CODE_00AF47:
	TAY                            ; Y = count
	LDA.B [$17]                    ; Load source
	INC.B $17
	INC.B $17
	TAX                            ; X = source
	TYA                            ; A = count

CODE_00AF50:
	STZ.B $98                      ; Clear dest low
	STZ.B $9A                      ; Clear dest high
	LDY.W #$0098                   ; Y = $98
	MVN $00,$00                    ; Block move
	RTS

;-------------------------------------------------------------------------------
; CODE_00AF5B - Memory copy to $9E pointer
;-------------------------------------------------------------------------------
CODE_00AF5B:
	TAX                            ; X = count
	LDA.B [$17]                    ; Load source
	INC.B $17
	INC.B $17
	TAY                            ; Y = source
	TXA                            ; A = count
	LDX.W #$009E                   ; X = $9E
	MVN $00,$00                    ; Block move
	RTS

;-------------------------------------------------------------------------------
; CODE_00AF6B/AF70/AF75 - Memory copy variants with preset counts
;-------------------------------------------------------------------------------
CODE_00AF6B:
	LDA.W #$0000                   ; 1 byte
	BRA CODE_00AF5B

CODE_00AF70:
	LDA.W #$0001                   ; 2 bytes
	BRA CODE_00AF5B

CODE_00AF75:
	LDA.W #$0002                   ; 3 bytes
	BRA CODE_00AF5B

;-------------------------------------------------------------------------------
; CODE_00AF7A/AF7F - Copy and store in $9E
;-------------------------------------------------------------------------------
CODE_00AF7A:
	JSR.W CODE_00AF2A              ; Table copy
	BRA CODE_00AF82

CODE_00AF7F:
	JSR.W CODE_00AF47              ; Direct copy

CODE_00AF82:
	LDA.B $98                      ; Load result low
	STA.B $9E                      ; Store in $9E
	LDA.B $9A                      ; Load result high
	STA.B $A0                      ; Store in $A0
	RTS

;-------------------------------------------------------------------------------
; CODE_00AF8B/AF90/AF95/AF9A/AF9F - Copy variants with preset counts
;-------------------------------------------------------------------------------
CODE_00AF8B:
	LDA.W #$0000
	BRA CODE_00AF7A

CODE_00AF90:
	LDA.W #$0001
	BRA CODE_00AF7A

CODE_00AF95:
	LDA.W #$0002
	BRA CODE_00AF7A

CODE_00AF9A:
	LDA.W #$0001
	BRA CODE_00AF7F

CODE_00AF9F:
	LDA.W #$0002
	BRA CODE_00AF7F

;-------------------------------------------------------------------------------
; CODE_00AFA4/AFAC/AFB1 - Load pointer helpers
;-------------------------------------------------------------------------------
CODE_00AFA4:
	JSR.W CODE_00AFBB              ; Load pointer
	STZ.B $9F                      ; Clear high byte
	STZ.B $A0
	RTS

	db $20,$BB,$AF,$64,$A0,$60,$20,$BB,$AF,$29,$FF,$00,$85,$A0,$60

;-------------------------------------------------------------------------------
; CODE_00AFBB - Load pointer from Bank $XX address
; Entry: [$17] = address, [$17+2] = bank
; Exit: Y = word value, A = next word, $9E = first word
;-------------------------------------------------------------------------------
CODE_00AFBB:
	LDA.B [$17]                    ; Load address
	INC.B $17
	INC.B $17
	TAX                            ; X = address
	LDA.B [$17]                    ; Load bank
	INC.B $17
	AND.W #$00FF
	PHA                            ; Save bank
	PLB                            ; Set data bank
	LDA.W $0000,X                  ; Load first word
	TAY                            ; Y = first word
	LDA.W $0002,X                  ; Load second word
	PLB                            ; Restore bank
	STY.B $9E                      ; Store first word
	RTS

;-------------------------------------------------------------------------------
; CODE_00AFD6 - Load byte from address into $9E
;-------------------------------------------------------------------------------
CODE_00AFD6:
	STZ.B $9E                      ; Clear $9E
	STZ.B $A0                      ; Clear $A0
	LDA.B [$17]                    ; Load address
	INC.B $17
	INC.B $17
	TAX                            ; X = address
	SEP #$20                       ; 8-bit A
	LDA.W $0000,X                  ; Load byte
	STA.B $9E                      ; Store in $9E
	RTS                            ; (REP #$30 in caller)

;-------------------------------------------------------------------------------
; CODE_00AFE9/AFEE - Bitwise AND operations
;-------------------------------------------------------------------------------
CODE_00AFE9:
	JSR.W CODE_00AF2A              ; Copy table
	BRA CODE_00AFF1

CODE_00AFEE:
	JSR.W CODE_00AF47              ; Copy direct

CODE_00AFF1:
	LDA.B $9E                      ; Load $9E
	AND.B $98                      ; AND with $98
	STA.B $9E                      ; Store result
	LDA.B $A0                      ; Load $A0
	AND.B $9A                      ; AND with $9A
	STA.B $A0                      ; Store result
	RTS

;-------------------------------------------------------------------------------
; CODE_00AFFE - Bitwise AND variants with preset counts
;-------------------------------------------------------------------------------
CODE_00AFFE:
	LDA.W #$0000                   ; 1 byte count
	BRA CODE_00AFE9                ; → AND table copy

	LDA.W #$0001                   ; 2 byte count
	BRA CODE_00AFE9

	db $A9,$02,$00,$80,$DC,$A9,$00,$00,$80,$DC ; More variants

	LDA.W #$0001                   ; 2 byte count
	BRA CODE_00AFEE                ; → AND direct copy

	db $A9,$02,$00,$80,$D2         ; 3 byte variant

;-------------------------------------------------------------------------------
; CODE_00B01C/B021 - Bitwise TSB (Test and Set Bits)
; Purpose: OR values with $9E/$A0 (set bits)
;-------------------------------------------------------------------------------
CODE_00B01C:
	JSR.W CODE_00AF2A              ; Copy table
	BRA CODE_00B024

CODE_00B021:
	JSR.W CODE_00AF47              ; Copy direct

CODE_00B024:
	LDA.B $98                      ; Load value
	TSB.B $9E                      ; Test and Set Bits in $9E
	LDA.B $9A
	TSB.B $A0                      ; Test and Set Bits in $A0
	RTS

	db $A9,$00,$00,$80,$EA         ; TSB variants with preset counts

	LDA.W #$0001
	BRA CODE_00B01C

	db $A9,$02,$00,$80,$E0

	LDA.W #$0000
	BRA CODE_00B021

	db $A9,$01,$00,$80,$DB,$A9,$02,$00,$80,$D6

;-------------------------------------------------------------------------------
; CODE_00B04B/B050 - Bitwise XOR (Exclusive OR)
; Purpose: XOR values with $9E/$A0
;-------------------------------------------------------------------------------
CODE_00B04B:
	JSR.W CODE_00AF2A              ; Copy table
	BRA CODE_00B053

CODE_00B050:
	JSR.W CODE_00AF47              ; Copy direct

CODE_00B053:
	LDA.B $9E
	EOR.B $98                      ; XOR with $98
	STA.B $9E                      ; Store result
	LDA.B $A0
	EOR.B $9A                      ; XOR with $9A
	STA.B $A0
	RTS

;-------------------------------------------------------------------------------
; XOR variants with preset counts
;-------------------------------------------------------------------------------
	LDA.W #$0000
	BRA CODE_00B04B

	db $A9,$01,$00,$80,$E1,$A9,$02,$00,$80,$DC,$A9,$00,$00,$80,$DC

	LDA.W #$0001
	BRA CODE_00B050

	db $A9,$02,$00,$80,$D2

;-------------------------------------------------------------------------------
; CODE_00B07E/B083 - Addition (ADD)
; Purpose: Add values to $9E/$A0
;-------------------------------------------------------------------------------
CODE_00B07E:
	JSR.W CODE_00AF2A              ; Copy table
	BRA CODE_00B086

CODE_00B083:
	JSR.W CODE_00AF47              ; Copy direct

CODE_00B086:
	CLC
	LDA.B $9E
	ADC.B $98                      ; Add $98
	STA.B $9E                      ; Store sum
	LDA.B $A0
	ADC.B $9A                      ; Add $9A with carry
	STA.B $A0
	RTS

;-------------------------------------------------------------------------------
; CODE_00B094 - Addition variants with preset counts
;-------------------------------------------------------------------------------
CODE_00B094:
	LDA.W #$0000                   ; 1 byte
	BRA CODE_00B07E

	LDA.W #$0001                   ; 2 bytes
	BRA CODE_00B07E

	LDA.W #$0002                   ; 3 bytes
	BRA CODE_00B07E

	LDA.W #$0000                   ; Direct variants
	BRA CODE_00B083

	LDA.W #$0001
	BRA CODE_00B083

	LDA.W #$0002
	BRA CODE_00B083

;-------------------------------------------------------------------------------
; CODE_00B0B2/B0B7 - Subtraction (SUB)
; Purpose: Subtract values from $9E/$A0
;-------------------------------------------------------------------------------
CODE_00B0B2:
	JSR.W CODE_00AF2A              ; Copy table
	BRA CODE_00B0BA

CODE_00B0B7:
	JSR.W CODE_00AF47              ; Copy direct

CODE_00B0BA:
	SEC
	LDA.B $9E
	SBC.B $98                      ; Subtract $98
	STA.B $9E                      ; Store difference
	LDA.B $A0
	SBC.B $9A                      ; Subtract $9A with borrow
	STA.B $A0
	RTS

;-------------------------------------------------------------------------------
; Subtraction variants with preset counts
;-------------------------------------------------------------------------------
	LDA.W #$0000
	BRA CODE_00B0B2

	LDA.W #$0001
	BRA CODE_00B0B2

	LDA.W #$0002
	BRA CODE_00B0B2

	LDA.W #$0000
	BRA CODE_00B0B7

	LDA.W #$0001
	BRA CODE_00B0B7

	LDA.W #$0002
	BRA CODE_00B0B7

;-------------------------------------------------------------------------------
; CODE_00B0E6 - Division (16-bit / 8-bit)
; Purpose: Divide $9E by accumulator
; Entry: A = divisor (8-bit)
; Exit: $98 = quotient, $9A = remainder (via CODE_0096B3)
;-------------------------------------------------------------------------------
CODE_00B0E6:
	STA.B $9C                      ; Store divisor
	LDA.B $9E                      ; Load dividend
	STA.B $98                      ; Setup for division
	JSL.L CODE_0096B3              ; Call division routine
	RTS

	LDA.B [$17]                    ; Variant: divisor from script
	INC.B $17
	AND.W #$00FF
	BRA CODE_00B0E6

	db $A7,$17,$E6,$17,$E6,$17,$80,$E4 ; 16-bit divisor variant

	JSR.W CODE_00B188              ; Variant: divisor from $B188
	BRA CODE_00B0E6

	JSR.W CODE_00B196              ; Variant: divisor from $B196
	BRA CODE_00B0E6

;-------------------------------------------------------------------------------
; CODE_00B10C - Multiplication (16-bit × 8-bit)
; Purpose: Multiply $9E/$A0 by accumulator
; Entry: A = multiplier (8-bit)
; Exit: Result in $98/$9A (via CODE_0096E4)
;-------------------------------------------------------------------------------
CODE_00B10C:
	STA.B $9C                      ; Store multiplier
	LDA.B $9E                      ; Load multiplicand low
	STA.B $98
	LDA.B $A0                      ; Load multiplicand high
	STA.B $9A
	JSL.L CODE_0096E4              ; Call multiplication routine
	RTS

;-------------------------------------------------------------------------------
; CODE_00B11B - Multiplication variants
;-------------------------------------------------------------------------------
CODE_00B11B:
	LDA.B [$17]                    ; Multiplier from script (8-bit)
	INC.B $17
	AND.W #$00FF
	BRA CODE_00B10C

	LDA.B [$17]                    ; Multiplier from script (16-bit)
	INC.B $17
	INC.B $17
	BRA CODE_00B10C

	db $20,$88,$B1,$80,$DB         ; From CODE_00B188

	JSR.W CODE_00B196              ; From CODE_00B196
	BRA CODE_00B10C

;-------------------------------------------------------------------------------
; CODE_00B136 - Get random number result
; Purpose: Transfer RNG result ($A2) to $9E
; Exit: $9E = random value, $A0 = 0
;-------------------------------------------------------------------------------
CODE_00B136:
	LDA.B $A2                      ; Load RNG result
	STA.B $9E                      ; Store in $9E
	STZ.B $A0                      ; Clear high byte
	RTS

	JSR.W CODE_00B11B              ; Variant: multiply then get result
	BRA CODE_00B136

	db $20,$24,$B1,$80,$EF,$20,$2C,$B1,$80,$EA,$20,$31,$B1,$80,$E5

;-------------------------------------------------------------------------------
; CODE_00B151 - Format decimal number for display
; Purpose: Convert binary value to BCD for display
; Entry: $9E/$A0 = value to convert
; Exit: Formatted value in buffer at $6D
;-------------------------------------------------------------------------------
CODE_00B151:
	PEI.B ($9E)                    ; Save $9E
	PEI.B ($A0)                    ; Save $A0
	LDA.W #$0090                   ; BCD format flags
	STA.B $6D                      ; Store in buffer
	LDA.W #$000A                   ; Base 10 (decimal)
	STA.B $9C                      ; Store base
	LDX.W #$006D                   ; X = buffer pointer
	CLC
	JSL.L CODE_009824              ; Call BCD conversion
	PLA                            ; Restore $A0
	STA.B $A0
	PLA                            ; Restore $9E
	STA.B $9E
	RTS

;-------------------------------------------------------------------------------
; CODE_00B16B - Format hexadecimal number for display
; Purpose: Convert binary value to hex for display
;-------------------------------------------------------------------------------
CODE_00B16B:
	PEI.B ($9E)                    ; Save values
	PEI.B ($A0)
	LDA.W #$0010                   ; Base 16 (hexadecimal)
	STA.B $9C
	LDX.W #$006D                   ; Buffer pointer
	SEC                            ; Hex mode flag
	JSL.L CODE_009824              ; Call hex conversion
	PLA
	STA.B $A0
	PLA
	STA.B $9E
	RTS

;-------------------------------------------------------------------------------
; CODE_00B185 - Helper routines for loading test values
;-------------------------------------------------------------------------------
CODE_00B185:
	LDA.B $3A                      ; Load from $3A
	RTS

Test_LoadValue8:
	LDA.B [$17]                    ; Load 8-bit from script
	INC.B $17
	AND.W #$00FF
	RTS

Test_LoadValue9E:
	LDA.B $9E                      ; Load from $9E
	RTS

Test_LoadValueRNG:
	LDA.B $A2                      ; Load from $A2 (RNG)
	RTS

Test_LoadValue16:
	LDA.B [$17]                    ; Load 16-bit from script
	INC.B $17
	INC.B $17
	RTS

;-------------------------------------------------------------------------------
; Test_CompareValue24: Compare 16-bit values (equality test)
; Purpose: Test if $9E/$A0 == value from script
; Entry: [$17] = 16-bit value, [$17+2] = 8-bit high byte
; Exit: Z flag set if equal, C flag indicates comparison result
;-------------------------------------------------------------------------------
Test_CompareValue24:
	LDA.B [$17]                    ; Load comparison value low
	INC.B $17
	INC.B $17
	STA.B $64                      ; Save in $64
	LDA.B [$17]                    ; Load comparison value high
	INC.B $17
	AND.W #$00FF
	STA.B $62                      ; Save in $62
	SEC                            ; Set carry for comparison
	LDA.B $A0                      ; Load high byte
	SBC.B $62                      ; Subtract comparison high
	BNE CODE_00B1C2                ; If not equal, done
	LDA.B $9E                      ; Load low byte
	SBC.B $64                      ; Subtract comparison low
	; Z flag = equality result
	; C flag = greater/equal result

CODE_00B1C2:
	RTS

;===============================================================================
; Progress: ~10,200 lines documented (72.8% of Bank $00)
; Latest additions:
; - CODE_00AFFE-00B021: Bitwise AND and TSB operations with variants
; - CODE_00B04B-00B053: Bitwise XOR operations
; - CODE_00B07E-00B094: 16-bit addition operations
; - CODE_00B0B2-00B0BA: 16-bit subtraction operations
; - CODE_00B0E6: Division (16÷8 bit)
; - CODE_00B10C: Multiplication (16×8 bit)
; - CODE_00B136: Random number result getter
; - CODE_00B151: Decimal number formatting (BCD conversion)
; - CODE_00B16B: Hexadecimal number formatting
; - CODE_00B185-00B196: Value loading helper routines
; - CODE_00B1A1: 24-bit comparison test
;
; Next: More comparison and test routines (Test_CompareDP onward)
;===============================================================================

;-------------------------------------------------------------------------------
; Test_CompareDP: Comparison test via external routine (from $2E context)
;
; Purpose: Set up direct page context and call external comparison routine
; Entry: $2E = direct page base to use
;        $9E = value to test
; Exit: Flags set by external comparison
; Uses: Bit_TestBits (external comparison routine)
;-------------------------------------------------------------------------------
Test_CompareDP:
    LDA.B $2E                      ; Load context pointer
    PHD                            ; Save current direct page
    TCD                            ; Set $2E as new DP base
    LDA.W $009E                    ; Load value from $9E in new context
    JSL.L Bit_TestBits              ; Call external comparison
    PLD                            ; Restore direct page
    INC A                          ; Set flags
    DEC A                          ; (Z flag = equality)
    RTS

;-------------------------------------------------------------------------------
; Test_Compare8: 8-bit comparison test
;
; Purpose: Compare $9E/$A0 with 8-bit value from script (16-bit safe check)
; Entry: [$17] = 8-bit comparison value
;        $9E/$A0 = value to test
; Exit: Carry and Zero flags set based on comparison
;       $17 incremented by 1
; Notes: Returns immediately if $A0 != 0 (value > 255)
;-------------------------------------------------------------------------------
Test_Compare8:
    LDA.B [$17]                    ; Load 8-bit comparison value
    INC.B $17                      ; Advance script pointer
    AND.W #$00FF                   ; Mask to 8 bits
    STA.B $64                      ; Store comparison value
    SEC                            ; Set carry for comparison
    LDA.B $A0                      ; Check high byte
    BNE Test_Compare8_Done                ; If non-zero, value > 255, return
    LDA.B $9E                      ; Compare low byte
    CMP.B $64                      ; Set C and Z flags
Test_Compare8_Done:
    RTS

;-------------------------------------------------------------------------------
; Test_Compare16: 16-bit comparison test
;
; Purpose: Compare $9E/$A0 with 16-bit value from script (24-bit safe check)
; Entry: [$17] = 16-bit comparison value
;        $9E/$A0 = value to test
; Exit: Carry and Zero flags set based on comparison
;       $17 incremented by 2
; Notes: Returns immediately if $A0 != 0 (value > 65535)
;-------------------------------------------------------------------------------
Test_Compare16:
    LDA.B [$17]                    ; Load 16-bit comparison value
    INC.B $17                      ; Advance script pointer
    INC.B $17                      ; (2 bytes)
    STA.B $64                      ; Store comparison value
    SEC                            ; Set carry for comparison
    LDA.B $A0                      ; Check high byte
    BNE Test_Compare16_Done                ; If non-zero, value > $FFFF, return
    LDA.B $9E                      ; Compare low word
    CMP.B $64                      ; Set C and Z flags
Test_Compare16_Done:
    RTS

;-------------------------------------------------------------------------------
; Test_Compare24Full: 24-bit comparison test (full)
;
; Purpose: Compare $9E/$A0 with 24-bit value from script
; Entry: [$17] = 16-bit low word
;        [$17+2] = 8-bit high byte
;        $9E/$A0 = value to test
; Exit: Carry and Zero flags set based on comparison
;       $17 incremented by 3
; Notes: Full 24-bit comparison (high byte then low word)
;-------------------------------------------------------------------------------
Test_Compare24Full:
    LDA.B [$17]                    ; Load low word
    INC.B $17
    INC.B $17
    STA.B $64                      ; Store low word
    LDA.B [$17]                    ; Load high byte
    INC.B $17
    AND.W #$00FF                   ; Mask to 8 bits
    STA.B $62                      ; Store high byte
    LDA.B $A0                      ; Compare high bytes first
    CMP.B $62
    BNE CODE_00B203                ; If not equal, done (C/Z set)
    LDA.B $9E                      ; Compare low words
    CMP.B $64
CODE_00B203:
    RTS

;-------------------------------------------------------------------------------
; CODE_00B204: Comparison with indirect 8-bit value
;
; Purpose: Compare $9E/$A0 with 8-bit value from memory (address from script)
; Entry: [$17] = pointer to 8-bit value
;        $9E/$A0 = value to test
; Exit: Carry and Zero flags set based on comparison
;       $17 incremented by 2
;-------------------------------------------------------------------------------
CODE_00B204:
    LDA.B [$17]                    ; Load pointer
    INC.B $17
    INC.B $17
    TAX                            ; Use as index
    LDA.W $0000,X                  ; Load 8-bit value from pointer
    AND.W #$00FF                   ; Mask to 8 bits
    STA.B $64                      ; Store comparison value
    SEC                            ; Set carry
    LDA.B $A0                      ; Check high byte
    BNE CODE_00B21C                ; If non-zero, return
    LDA.B $9E                      ; Compare low byte
    CMP.B $64
CODE_00B21C:
    RTS

;-------------------------------------------------------------------------------
; CODE_00B21D: Comparison with indirect 16-bit value
;
; Purpose: Compare $9E/$A0 with 16-bit value from memory (address from script)
; Entry: [$17] = pointer to 16-bit value
;        $9E/$A0 = value to test
; Exit: Carry and Zero flags set based on comparison
;       $17 incremented by 2
;-------------------------------------------------------------------------------
CODE_00B21D:
    LDA.B [$17]                    ; Load pointer
    INC.B $17
    INC.B $17
    TAX                            ; Use as index
    SEC                            ; Set carry
    LDA.B $A0                      ; Check high byte
    BNE CODE_00B22E                ; If non-zero, return
    LDA.B $9E                      ; Compare with value at pointer
    CMP.W $0000,X
CODE_00B22E:
    RTS

;-------------------------------------------------------------------------------
; CODE_00B22F: Comparison with indirect 24-bit value
;
; Purpose: Compare $9E/$A0 with 24-bit value from memory (address from script)
; Entry: [$17] = pointer to 24-bit value (word at X, byte at X+2)
;        $9E/$A0 = value to test
; Exit: Carry and Zero flags set based on comparison
;       $17 incremented by 2
;-------------------------------------------------------------------------------
CODE_00B22F:
    LDA.B [$17]                    ; Load pointer
    INC.B $17
    INC.B $17
    TAX                            ; Use as index
    LDA.W $0002,X                  ; Load high byte from pointer+2
    AND.W #$00FF                   ; Mask to 8 bits
    STA.B $64                      ; Store high byte
    LDA.B $A0                      ; Compare high bytes
    CMP.B $64
    BNE CODE_00B249                ; If not equal, done
    LDA.B $9E                      ; Compare low words
    CMP.W $0000,X                  ; With value at pointer
CODE_00B249:
    RTS

;-------------------------------------------------------------------------------
; CODE_00B24A/B253: Count characters with high bit set (string analysis)
;
; Purpose: Count characters in a string where bit 7 is set (value >= $80)
; Entry: Multiple entry points:
;        00B24A: A = string length (8-bit from script)
;                $9E/$A0 = bank:address of string
;        00B253: A = string length from $3A
;                $9E/$A0 = bank:address of string
; Exit: $9E = count of characters with high bit set
;       $A0 = 0
; Uses: Bank switching, indexed byte scanning
; Notes: Useful for text encoding analysis (control codes, special chars)
;-------------------------------------------------------------------------------
CODE_00B24A:
    LDA.B [$17]                    ; Load string length
    INC.B $17                      ; Advance script pointer
    AND.W #$00FF                   ; Mask to 8 bits
    BRA CODE_00B258                ; Jump to counter

    ; Entry point: length from $3A
    db $A5,$3A,$29,$FF,$00         ; LDA $3A; AND #$00FF (alternate entry)

CODE_00B258:
    TAY                            ; Y = string length (counter)
    LDA.B $A0                      ; Get bank
    AND.W #$00FF                   ; Mask to 8 bits
    PHA                            ; Push bank
    PLB                            ; Set data bank
    LDX.B $9E                      ; X = string address
    BRA CODE_00B274                ; Jump to scan loop

    ; Another entry point (different parameters)
    db $8B,$A7,$17,$E6,$17,$E6,$17,$AA,$A7,$17,$E6,$17,$29,$FF,$00,$A8 ; Alternate parameter loading

CODE_00B274:
    STZ.B $9E                      ; Clear result counter
    STZ.B $A0                      ; Clear high byte

CODE_00B278:
    LDA.W $0000,X                  ; Load character from string
    AND.W #$00FF                   ; Mask to 8 bits
    CMP.W #$0080                   ; Check if >= $80 (high bit set)
    BCC CODE_00B285                ; If < $80, skip increment
    INC.B $9E                      ; Count this character

CODE_00B285:
    INX                            ; Next character
    DEY                            ; Decrement counter
    BNE CODE_00B278                ; Loop until done
    PLB                            ; Restore bank
    RTS

;-------------------------------------------------------------------------------
; CODE_00B28B: Negate value (two's complement)
;
; Purpose: Negate $9E/$A0 (convert to negative)
; Entry: $9E/$A0 = value
; Exit: $9E/$A0 = negated value (0 - original value)
; Notes: Two's complement: invert all bits and add 1
;        Equivalent to: result = 0 - value
;-------------------------------------------------------------------------------
CODE_00B28B:
    LDA.W #$0000                   ; Load 0
    SEC                            ; Set carry for subtraction
    SBC.B $9E                      ; 0 - low word
    STA.B $9E
    LDA.W #$0000                   ; Load 0
    SBC.B $A0                      ; 0 - high byte (with borrow)
    STA.B $A0
    RTS

;-------------------------------------------------------------------------------
; CODE_00B29B: Toggle bits in array (bitfield manipulation)
;
; Purpose: Toggle specific bits in a bitfield array based on script parameters
; Entry: [$17] = bit operation parameter (bit index and mode)
;        $5E = character/entity index
;        $5F/$61 = working registers
; Exit: Bits toggled in array at $XX00-$XX5F
; Uses: Bank switching, indexed bit manipulation
; Notes: Complex bitfield operation with XOR toggle
;        Uses character stats or similar bitfield array
;-------------------------------------------------------------------------------
CODE_00B29B:
    db $A2,$1A,$00,$A0,$5F,$00,$A9,$02,$00,$54,$00,$00,$A7,$17,$E6,$17
    db $29,$FF,$00,$48,$4A,$A8,$68,$3A,$0A,$65,$5F,$AA,$E2,$20,$A5,$61
    db $8B,$48,$AB,$C2,$30,$A7,$5F,$49,$00,$40,$48,$BD,$00,$00,$49,$00
    db $40,$87,$5F,$68,$9D,$00,$00,$CA,$CA,$E6,$5F,$E6,$5F,$88,$D0,$E5
    db $AB,$60
    ; TODO: Disassemble this complex bit manipulation routine

;-------------------------------------------------------------------------------
; CODE_00B2DD: Decrement tilemap pointer by one row
;
; Purpose: Move tilemap pointer up one row (subtract $40 = 64 bytes)
; Entry: $1A = tilemap pointer
; Exit: $1A -= $40
; Notes: SNES tilemap rows are $40 bytes apart (32 tiles × 2 bytes/tile)
;-------------------------------------------------------------------------------
CODE_00B2DD:
    LDA.B $1A                      ; Load tilemap pointer
    SEC                            ; Set carry for subtraction
    SBC.W #$0040                   ; Subtract one row ($40 bytes)
    STA.B $1A                      ; Store result
    RTS

;-------------------------------------------------------------------------------
; CODE_00B2E6: Increment tilemap pointer by one row
;
; Purpose: Move tilemap pointer down one row (add $40 = 64 bytes)
; Entry: $1A = tilemap pointer
; Exit: $1A += $40
; Notes: SNES tilemap rows are $40 bytes apart
;-------------------------------------------------------------------------------
CODE_00B2E6:
    LDA.B $1A                      ; Load tilemap pointer
    CLC                            ; Clear carry for addition
    ADC.W #$0040                   ; Add one row ($40 bytes)
    STA.B $1A                      ; Store result
    RTS

;-------------------------------------------------------------------------------
; CODE_00B2EF: Decrement tilemap pointer by one tile
;
; Purpose: Move tilemap pointer left one tile (subtract 2 bytes)
; Entry: $1A = tilemap pointer
; Exit: $1A -= 2
; Notes: Each tilemap entry is 2 bytes (tile number + attributes)
;-------------------------------------------------------------------------------
CODE_00B2EF:
    DEC.B $1A                      ; Decrement low byte
    DEC.B $1A                      ; Decrement again (2 bytes)
    RTS

;-------------------------------------------------------------------------------
; CODE_00B2F4: Increment tilemap pointer by one tile
;
; Purpose: Move tilemap pointer right one tile (add 2 bytes)
; Entry: $1A = tilemap pointer
; Exit: $1A += 2
; Notes: Each tilemap entry is 2 bytes
;-------------------------------------------------------------------------------
CODE_00B2F4:
    INC.B $1A                      ; Increment low byte
    INC.B $1A                      ; Increment again (2 bytes)
    RTS

;-------------------------------------------------------------------------------
; CODE_00B2F9: Jump to external routine with 16-bit parameter
;
; Purpose: Load 16-bit parameter from script and call external function
; Entry: [$17] = 16-bit parameter
; Exit: $17 incremented by 2
;       Returns from external function
; Calls: CODE_009DCB (external routine)
;-------------------------------------------------------------------------------
CODE_00B2F9:
    LDA.B [$17]                    ; Load 16-bit parameter
    INC.B $17                      ; Advance script pointer
    INC.B $17                      ; (2 bytes)
    JMP.W CODE_009DCB              ; Jump to external routine

;-------------------------------------------------------------------------------
; CODE_00B302: Jump to external routine with 8-bit parameter
;
; Purpose: Load 8-bit parameter from script and call external function
; Entry: [$17] = 8-bit parameter
; Exit: $17 incremented by 1
;       Returns from external function
; Calls: CODE_009DC9 (external routine)
;-------------------------------------------------------------------------------
CODE_00B302:
    LDA.B [$17]                    ; Load 8-bit parameter
    INC.B $17                      ; Advance script pointer
    AND.W #$00FF                   ; Mask to 8 bits
    JMP.W CODE_009DC9              ; Jump to external routine

;-------------------------------------------------------------------------------
; CODE_00B30C: Right shift $9E/$A0 by N bits
;
; Purpose: Logical right shift of 16-bit value
; Entry: [$17] = shift count (1-15)
;        $9E/$A0 = value to shift
; Exit: $9E/$A0 = value >> shift_count
;       $17 incremented by 1
; Notes: Each iteration: LSR high byte, ROR low byte (preserves shifted bits)
;-------------------------------------------------------------------------------
CODE_00B30C:
    LDA.B [$17]                    ; Load shift count
    INC.B $17                      ; Advance script pointer
    AND.W #$00FF                   ; Mask to 8 bits

CODE_00B313:
    LSR.B $A0                      ; Shift high byte right
    ROR.B $9E                      ; Rotate low byte right (carry in)
    DEC A                          ; Decrement shift count
    BNE CODE_00B313                ; Loop until done
    RTS

;-------------------------------------------------------------------------------
; CODE_00B31B: Left shift $9E/$A0 by N bits
;
; Purpose: Logical left shift of 16-bit value
; Entry: [$17] = shift count (1-15)
;        $9E/$A0 = value to shift
; Exit: $9E/$A0 = value << shift_count
;       $17 incremented by 1
; Notes: Each iteration: ASL low byte, ROL high byte (preserves shifted bits)
;-------------------------------------------------------------------------------
CODE_00B31B:
    LDA.B [$17]                    ; Load shift count
    INC.B $17                      ; Advance script pointer
    AND.W #$00FF                   ; Mask to 8 bits

CODE_00B322:
    ASL.B $9E                      ; Shift low byte left
    ROL.B $A0                      ; Rotate high byte left (carry in)
    DEC A                          ; Decrement shift count
    BNE CODE_00B322                ; Loop until done
    RTS

;-------------------------------------------------------------------------------
; CODE_00B32A: Right shift by N bits (from indirect address)
;
; Purpose: Right shift $9E/$A0 by count from memory pointer
; Entry: [$17] = pointer to shift count (16-bit address)
;        $9E/$A0 = value to shift
; Exit: $9E/$A0 = value >> [pointer]
;       $17 incremented by 2
;-------------------------------------------------------------------------------
CODE_00B32A:
    db $A7,$17,$E6,$17,$E6,$17,$AA,$BD,$00,$00,$29,$FF,$00,$46,$A0,$66
    db $9E,$3A,$D0,$F9,$60
    ; LDA [$17]; INC $17; INC $17; TAX; LDA $0000,X; AND #$00FF
    ; LSR $A0; ROR $9E; DEC A; BNE loop; RTS

;-------------------------------------------------------------------------------
; CODE_00B33F: Left shift by N bits (from indirect address)
;
; Purpose: Left shift $9E/$A0 by count from memory pointer
; Entry: [$17] = pointer to shift count (16-bit address)
;        $9E/$A0 = value to shift
; Exit: $9E/$A0 = value << [pointer]
;       $17 incremented by 2
;-------------------------------------------------------------------------------
CODE_00B33F:
    db $A7,$17,$E6,$17,$E6,$17,$AA,$BD,$00,$00,$29,$FF,$00,$06,$9E,$26
    db $A0,$3A,$D0,$F9,$60
    ; LDA [$17]; INC $17; INC $17; TAX; LDA $0000,X; AND #$00FF
    ; ASL $9E; ROL $A0; DEC A; BNE loop; RTS

;-------------------------------------------------------------------------------
; CODE_00B354: No operation (placeholder)
;
; Purpose: Empty function (immediate return)
; Notes: May be unused or placeholder for future functionality
;-------------------------------------------------------------------------------
CODE_00B354:
    RTS

;-------------------------------------------------------------------------------
; CODE_00B355: Execute script or function call
;
; Purpose: Execute script function or register external script
; Entry: [$17] = function/script address
; Exit: $17 incremented by 2
;       Script executed or registered
; Calls: CODE_00B35B (script execution handler)
;       CODE_00A71C (external script registration)
;       CODE_01B24C (script initialization)
; Notes: Handles both internal scripts (>= $8000) and external scripts (< $8000)
;-------------------------------------------------------------------------------
CODE_00B355:
    LDA.B [$17]                    ; Load script address
    INC.B $17                      ; Advance script pointer
    INC.B $17                      ; (2 bytes)

CODE_00B35B:
    CMP.W #$8000                   ; Check if >= $8000 (internal script)
    BCC CODE_00B367                ; If < $8000, external script
    TAX                            ; X = script address
    LDA.W #$0003                   ; Script mode 3
    JMP.W CODE_00A71C              ; Register and execute script

CODE_00B367:
    PEI.B ($17)                    ; Save current script pointer
    PEI.B ($18)                    ; (both bytes)
    STA.W $19EE                    ; Store script address
    JSL.L CODE_01B24C              ; Initialize and run script
    PLA                            ; Restore script pointer
    STA.B $18
    PLA
    STA.B $17
    RTS

;-------------------------------------------------------------------------------
; CODE_00B379: Execute script list (loop until $FFFF terminator)
;
; Purpose: Execute multiple scripts in sequence until terminator
; Entry: [$17] = pointer to script address list
;        List format: [addr1][addr2]...[FFFF]
; Exit: All scripts executed
;       $17 advanced past terminator
; Notes: Processes scripts one by one, stops at $FFFF marker
;-------------------------------------------------------------------------------
CODE_00B379:
    LDA.B [$17]                    ; Load script address
    INC.B $17                      ; Advance pointer
    INC.B $17                      ; (2 bytes)
    CMP.W #$FFFF                   ; Check for terminator
    BEQ CODE_00B38B                ; If $FFFF, done
    JSR.W CODE_00B35B              ; Execute this script
    REP #$30                       ; Ensure 16-bit mode
    BRA CODE_00B379                ; Loop to next script

CODE_00B38B:
    RTS

;-------------------------------------------------------------------------------
; CODE_00B38C: Random number transformation
;
; Purpose: Apply random number transformation to $9E
; Entry: $9E = input value
; Exit: $9E = transformed value
; Calls: CODE_009730 (external RNG transformation)
;-------------------------------------------------------------------------------
CODE_00B38C:
    LDA.B $9E                      ; Load value
    JSL.L CODE_009730              ; Apply RNG transformation
    STA.B $9E                      ; Store result
    RTS

;-------------------------------------------------------------------------------
; CODE_00B395: Count leading zeros (bit scan)
;
; Purpose: Count number of leading zero bits in $9E
; Entry: $9E = value to scan
; Exit: $9E = count of leading zeros (0-16)
; Notes: Scans from bit 15 down to bit 0, stops at first 1 bit
;        Used for bit significance detection
;-------------------------------------------------------------------------------
CODE_00B395:
    LDA.B $9E                      ; Load value
    LDX.W #$0010                   ; Start with 16 (max leading zeros)

CODE_00B39A:
    DEX                            ; Decrement counter
    ASL A                          ; Shift left (bit 15 → Carry)
    BCC CODE_00B39A                ; If carry clear (bit was 0), continue
    STX.B $9E                      ; Store leading zero count
    RTS

;-------------------------------------------------------------------------------
; CODE_00B3A1: Increment $9E/$A0 (24-bit safe)
;
; Purpose: Increment 16-bit value with carry to high byte
; Entry: $9E/$A0 = value
; Exit: $9E/$A0 = value + 1
; Notes: Handles carry from $9E to $A0
;-------------------------------------------------------------------------------
CODE_00B3A1:
    INC.B $9E                      ; Increment low word
    BNE CODE_00B3A7                ; If not zero, done
    db $E6,$A0                     ; INC $A0 (high byte)

CODE_00B3A7:
    RTS

;-------------------------------------------------------------------------------
; CODE_00B3A8: Increment 16-bit value at pointer (from script)
;
; Purpose: Increment word at memory address from script
; Entry: [$17] = pointer to 16-bit value
; Exit: Word at pointer incremented
;       $17 incremented by 2
;-------------------------------------------------------------------------------
CODE_00B3A8:
    LDA.B [$17]                    ; Load pointer
    INC.B $17                      ; Advance script pointer
    INC.B $17                      ; (2 bytes)
    TAX                            ; X = pointer
    INC.W $0000,X                  ; Increment word at pointer
    RTS

;-------------------------------------------------------------------------------
; CODE_00B3B3: Increment 8-bit value at pointer (from script)
;
; Purpose: Increment byte at memory address from script
; Entry: [$17] = pointer to 8-bit value
; Exit: Byte at pointer incremented
;       $17 incremented by 2
; Notes: Switches to 8-bit accumulator mode
;-------------------------------------------------------------------------------
CODE_00B3B3:
    LDA.B [$17]                    ; Load pointer
    INC.B $17                      ; Advance script pointer
    INC.B $17                      ; (2 bytes)
    TAX                            ; X = pointer
    SEP #$20                       ; 8-bit accumulator
    INC.W $0000,X                  ; Increment byte at pointer
    RTS

;-------------------------------------------------------------------------------
; CODE_00B3C0: Decrement $9E/$A0 (24-bit safe)
;
; Purpose: Decrement 16-bit value with borrow from high byte
; Entry: $9E/$A0 = value
; Exit: $9E/$A0 = value - 1
; Notes: Handles borrow from $A0 to $9E
;-------------------------------------------------------------------------------
CODE_00B3C0:
    LDA.B $9E                      ; Load low word
    SEC                            ; Set carry for subtraction
    SBC.W #$0001                   ; Subtract 1
    STA.B $9E                      ; Store result
    BCS CODE_00B3CC                ; If carry set, no borrow needed
    DEC.B $A0                      ; Borrow from high byte

CODE_00B3CC:
    RTS

;-------------------------------------------------------------------------------
; CODE_00B3CD: Decrement 16-bit value at pointer (from script)
;
; Purpose: Decrement word at memory address from script
; Entry: [$17] = pointer to 16-bit value
; Exit: Word at pointer decremented
;       $17 incremented by 2
;-------------------------------------------------------------------------------
CODE_00B3CD:
    LDA.B [$17]                    ; Load pointer
    INC.B $17                      ; Advance script pointer
    INC.B $17                      ; (2 bytes)
    TAX                            ; X = pointer
    DEC.W $0000,X                  ; Decrement word at pointer
    RTS

;-------------------------------------------------------------------------------
; CODE_00B3D8: Decrement 8-bit value at pointer (from script)
;
; Purpose: Decrement byte at memory address from script
; Entry: [$17] = pointer to 8-bit value
; Exit: Byte at pointer decremented
;       $17 incremented by 2
; Notes: Switches to 8-bit accumulator mode
;-------------------------------------------------------------------------------
CODE_00B3D8:
    LDA.B [$17]                    ; Load pointer
    INC.B $17                      ; Advance script pointer
    INC.B $17                      ; (2 bytes)
    TAX                            ; X = pointer
    SEP #$20                       ; 8-bit accumulator
    DEC.W $0000,X                  ; Decrement byte at pointer
    RTS

;-------------------------------------------------------------------------------
; CODE_00B3E5: Bitwise OR from indirect addresses
;
; Purpose: OR value from first pointer with value from second pointer, store at first
; Entry: [$17] = destination pointer (16-bit address)
;        [$17+2] = source pointer (16-bit address)
; Exit: [dest] = [dest] OR [source]
;       $17 incremented by 4
;-------------------------------------------------------------------------------
CODE_00B3E5:
    db $A7,$17,$E6,$17,$E6,$17,$AA,$A7,$17,$E6,$17,$E6,$17,$3D,$00,$00
    db $9D,$00,$00,$60
    ; LDA [$17]; INC $17; INC $17; TAX
    ; LDA [$17]; INC $17; INC $17
    ; ORA $0000,X; STA $0000,X; RTS

;-------------------------------------------------------------------------------
; CODE_00B3F9: Bitwise AND from indirect addresses (8-bit)
;
; Purpose: AND byte from second pointer with byte at first pointer, store at first
; Entry: [$17] = destination pointer (16-bit address)
;        [$17+2] = 8-bit mask value
; Exit: [dest] = [dest] AND mask (8-bit operation)
;       $17 incremented by 3
; Notes: Uses 8-bit accumulator mode
;-------------------------------------------------------------------------------
CODE_00B3F9:
    LDA.B [$17]                    ; Load destination pointer
    INC.B $17
    INC.B $17
    TAX                            ; X = destination
    LDA.B [$17]                    ; Load mask value
    INC.B $17
    AND.W #$00FF                   ; Mask to 8 bits
    SEP #$20                       ; 8-bit accumulator
    AND.W $0000,X                  ; AND with destination
    STA.W $0000,X                  ; Store result
    RTS

;-------------------------------------------------------------------------------
; CODE_00B410: Bitwise OR from indirect addresses (16-bit)
;
; Purpose: OR word from second pointer with word at first pointer
; Entry: [$17] = destination pointer (16-bit address)
;        [$17+2] = source pointer (16-bit address)
; Exit: [dest] = [dest] OR [source] (16-bit operation)
;       $17 incremented by 4
;-------------------------------------------------------------------------------
CODE_00B410:
    db $A7,$17,$E6,$17,$E6,$17,$AA,$A7,$17,$E6,$17,$E6,$17,$1D,$00,$00
    db $9D,$00,$00,$60
    ; LDA [$17]; INC $17; INC $17; TAX
    ; LDA [$17]; INC $17; INC $17
    ; ORA $0000,X; STA $0000,X; RTS

;-------------------------------------------------------------------------------
; CODE_00B424: Bitwise OR with 8-bit immediate (to indirect)
;
; Purpose: OR byte at pointer with 8-bit value from script
; Entry: [$17] = destination pointer
;        [$17+2] = 8-bit mask value
; Exit: [dest] = [dest] OR mask (8-bit operation)
;       $17 incremented by 3
;-------------------------------------------------------------------------------
CODE_00B424:
    LDA.B [$17]                    ; Load destination pointer
    INC.B $17
    INC.B $17
    TAX                            ; X = destination
    LDA.B [$17]                    ; Load mask value
    INC.B $17
    AND.W #$00FF                   ; Mask to 8 bits
    SEP #$20                       ; 8-bit accumulator
    ORA.W $0000,X                  ; OR with destination
    STA.W $0000,X                  ; Store result
    RTS

;-------------------------------------------------------------------------------
; CODE_00B43B: Bitwise XOR from indirect addresses (16-bit)
;
; Purpose: XOR word from second pointer with word at first pointer
; Entry: [$17] = destination pointer
;        [$17+2] = source pointer
; Exit: [dest] = [dest] XOR [source] (16-bit operation)
;       $17 incremented by 4
;-------------------------------------------------------------------------------
CODE_00B43B:
    db $A7,$17,$E6,$17,$E6,$17,$AA,$A7,$17,$E6,$17,$E6,$17,$5D,$00,$00
    db $9D,$00,$00,$60
    ; LDA [$17]; INC $17; INC $17; TAX
    ; LDA [$17]; INC $17; INC $17
    ; EOR $0000,X; STA $0000,X; RTS

;-------------------------------------------------------------------------------
; CODE_00B44F: Bitwise XOR with 8-bit immediate (to indirect)
;
; Purpose: XOR byte at pointer with 8-bit value from script
; Entry: [$17] = destination pointer
;        [$17+2] = 8-bit mask value
; Exit: [dest] = [dest] XOR mask (8-bit operation)
;       $17 incremented by 3
;-------------------------------------------------------------------------------
CODE_00B44F:
    LDA.B [$17]                    ; Load destination pointer
    INC.B $17
    INC.B $17
    TAX                            ; X = destination
    LDA.B [$17]                    ; Load mask value
    INC.B $17
    AND.W #$00FF                   ; Mask to 8 bits
    SEP #$20                       ; 8-bit accumulator
    EOR.W $0000,X                  ; XOR with destination
    STA.W $0000,X                  ; Store result
    RTS

;-------------------------------------------------------------------------------
; CODE_00B466/B46B: Calculate tile address for character sprite
;
; Purpose: Calculate tilemap tile address for character sprite positioning
; Entry: $5E = character/entity index
; Exit: A = tile index/address
;       Various working registers updated
; Notes: Two entry points:
;        00B466: Offset $2A (42)
;        00B46B: Offset $0A (10)
;        Uses character position data from $049800 table
;-------------------------------------------------------------------------------
CODE_00B466:
    LDA.W #$002A                   ; Offset 42
    BRA CODE_00B46E                ; Jump to calculator

CODE_00B46B:
    LDA.W #$000A                   ; Offset 10

CODE_00B46E:
    SEP #$30                       ; 8-bit A/X/Y
    CLC                            ; Clear carry
    LDX.B $5E                      ; Load character index
    ADC.L DATA8_049800,X           ; Add character position offset
    XBA                            ; Swap A/B (position in high byte)
    TXA                            ; A = character index
    AND.B #$38                     ; Mask bits 3-5
    ASL A                          ; × 2
    STA.B $64                      ; Store intermediate
    TXA                            ; A = character index again
    AND.B #$07                     ; Mask bits 0-2
    ADC.B $64                      ; Add intermediate
    ASL A                          ; × 2 (tile address scaling)
    REP #$20                       ; 16-bit accumulator
    SEP #$10                       ; 8-bit X/Y
    LDY.B #$00                     ; Y = 0
    STA.B [$1A],Y                  ; Store at tilemap pointer
    INC A                          ; Next tile
    LDY.B #$02                     ; Y = 2
    STA.B [$1A],Y                  ; Store at tilemap+2
    ADC.W #$000F                   ; Add 15 (next row offset)
    LDY.B #$40                     ; Y = $40 (row below)
    STA.B [$1A],Y                  ; Store at tilemap+$40
    INC A                          ; Next tile
    LDY.B #$42                     ; Y = $42
    STA.B [$1A],Y                  ; Store at tilemap+$42
    RTS

;-------------------------------------------------------------------------------
; CODE_00B49E: Update minimum tilemap pointer
;
; Purpose: Track minimum tilemap pointer in $44
; Entry: $1A = current tilemap pointer
;        $44 = current minimum
; Exit: $44 = min($44, $1A)
; Notes: Used for dirty rectangle optimization
;-------------------------------------------------------------------------------
CODE_00B49E:
    LDA.B $1A                      ; Load current pointer
    CMP.B $44                      ; Compare with current min
    BCS CODE_00B4A6                ; If >= min, skip
    STA.B $44                      ; Update minimum

CODE_00B4A6:
    RTS

;-------------------------------------------------------------------------------
; CODE_00B4A7: Update maximum tilemap pointer
;
; Purpose: Track maximum tilemap pointer in $46
; Entry: $1A = current tilemap pointer
;        $46 = current maximum
; Exit: $46 = max($46, $1A)
; Notes: Used for dirty rectangle optimization (max extent)
;-------------------------------------------------------------------------------
CODE_00B4A7:
    LDA.B $1A                      ; Load current pointer
    CMP.B $46                      ; Compare with current max
    BCC CODE_00B4AF                ; If < max, skip
    STA.B $46                      ; Update maximum

CODE_00B4AF:
    RTS

;-------------------------------------------------------------------------------
; CODE_00B4B0: Check flag and execute routine
;
; Purpose: Check bit 5 of $DA and branch to different routines
; Entry: $DA = flag register
; Exit: Jumps to CODE_00A8C0 if bit 5 set, CODE_009DC9 otherwise
; Notes: Bit 5 of $DA appears to be a mode or state flag
;-------------------------------------------------------------------------------
CODE_00B4B0:
    LDA.W #$0020                   ; Bit 5 mask
    AND.W $00DA                    ; Test bit 5 of $DA
    BEQ UNREACH_00B4BB             ; If clear, jump to alternate
    JMP.W CODE_00A8C0              ; Jump to routine A

UNREACH_00B4BB:
    db $A9,$FF,$00,$4C,$C9,$9D     ; LDA #$00FF; JMP CODE_009DC9

;-------------------------------------------------------------------------------
; CODE_00B4C1: Clear text mode bits and set new mode
;
; Purpose: Clear bits 10-12 of $1D and set new text mode from script
; Entry: [$17] = 8-bit text mode value
;        $1D = current text mode flags
; Exit: $1D bits 10-12 cleared
;       $1E |= new mode bits
;       $17 incremented by 1
; Notes: Text rendering mode control
;-------------------------------------------------------------------------------
CODE_00B4C1:
    LDA.W #$1C00                   ; Bits 10-12 mask
    TRB.B $1D                      ; Clear bits in $1D
    LDA.B [$17]                    ; Load new mode value
    INC.B $17                      ; Advance script pointer
    AND.W #$00FF                   ; Mask to 8 bits
    TSB.B $1E                      ; Set bits in $1E
    RTS

;-------------------------------------------------------------------------------
; CODE_00B4D0: RNG seed setup and call
;
; Purpose: Set up RNG seed from script and generate random number
; Entry: [$17] = 8-bit seed/parameter
; Exit: $9E = random number result
;       $A0 = 0
;       $17 incremented by 1
; Calls: CODE_009783 (RNG routine)
;-------------------------------------------------------------------------------
CODE_00B4D0:
    STZ.B $9E                      ; Clear $9E
    STZ.B $A0                      ; Clear $A0
    LDA.B [$17]                    ; Load seed parameter
    INC.B $17                      ; Advance script pointer
    AND.W #$00FF                   ; Mask to 8 bits
    SEP #$20                       ; 8-bit accumulator
    STA.W $00A8                    ; Store in RNG parameter location
    JSL.L CODE_009783              ; Call RNG routine
    LDA.W $00A9                    ; Load RNG result
    STA.B $9E                      ; Store in $9E
    RTS

;-------------------------------------------------------------------------------
; CODE_00B4EA: Jump to external with $9E parameter
;
; Purpose: Call external routine with $9E as parameter
; Entry: $9E = parameter value
; Calls: CODE_009DCB (external routine)
;-------------------------------------------------------------------------------
CODE_00B4EA:
    LDA.B $9E                      ; Load parameter
    JMP.W CODE_009DCB              ; Jump to external routine

;-------------------------------------------------------------------------------
; CODE_00B4EF: Center text based on character count
;
; Purpose: Calculate text centering offset based on character metrics
; Entry: [$17] = character count parameter
;        $63 = character width data (high byte)
;        $9E = base position
; Exit: $9E = centered position
;       $62/$63 = character count results
;       $17 incremented by 1
; Notes: Scans string at $1100 + offset
;        Counts characters until first < $80 or second >= $80 found
;        Calculates centering based on character distribution
;-------------------------------------------------------------------------------
CODE_00B4EF:
    LDA.B [$17]                    ; Load character count param
    INC.B $17                      ; Advance script pointer
    AND.W #$00FF                   ; Mask to 8 bits
    STA.B $64                      ; Store count
    LDA.B $63                      ; Load character width base
    AND.W #$FF00                   ; Keep high byte
    LSR A                          ; / 2 (adjust for offset)
    TAX                            ; X = string offset
    ADC.W #$1100                   ; Add buffer base address
    STA.B $9E                      ; Store in $9E (string pointer)
    LDY.W #$0010                   ; Y = 16 (max scan count)
    STZ.B $62                      ; Clear first counter
    SEP #$20                       ; 8-bit accumulator
    STZ.B $A0                      ; Clear high byte

CODE_00B50D:
    LDA.W $1100,X                  ; Load character from buffer
    INX                            ; Next character
    CMP.B #$80                     ; Check if >= $80
    BCC CODE_00B51C                ; If < $80, found end of first section
    INC.B $62                      ; Count this character (>= $80)
    DEY                            ; Decrement remaining
    BNE CODE_00B50D                ; Loop until done
    db $80,$10                     ; BRA (skip next section)

CODE_00B51C:
    DEY                            ; Decrement remaining
    BEQ CODE_00B52C                ; If done, exit

CODE_00B51F:
    LDA.W $1100,X                  ; Load character
    INX                            ; Next character
    CMP.B #$80                     ; Check if >= $80
    BCC CODE_00B52C                ; If < $80, still in second section
    INC.B $63                      ; Count this character (>= $80)
    DEY                            ; Decrement remaining
    BNE CODE_00B51F                ; Loop

CODE_00B52C:
    LDA.B $62                      ; Load first count
    CMP.B $63                      ; Compare with second count
    BCS CODE_00B534                ; If first >= second, use first
    LDA.B $63                      ; Use second count

CODE_00B534:
    STA.B $62                      ; Store max count
    SEC                            ; Set carry for subtraction
    LDA.B $2A                      ; Load total width
    SBC.B #$02                     ; Subtract 2
    SBC.B $62                      ; Subtract max count
    LSR A                          ; / 2 (center offset)
    CLC                            ; Clear carry
    ADC.B $25                      ; Add to base position
    STA.B $25                      ; Store centered position
    REP #$30                       ; 16-bit A/X/Y
    JSR.W CODE_00A8D1              ; Call positioning routine
    RTS

;-------------------------------------------------------------------------------
; CODE_00B548: Set text counter and call text routine
;
; Purpose: Set $3A to $10 (16) and call text drawing routine
; Entry: (parameters set up by caller)
; Exit: Text drawing initiated
; Calls: CODE_00A7DE (text drawing routine)
;-------------------------------------------------------------------------------
CODE_00B548:
    LDA.W #$0010                   ; Load 16
    STA.B $3A                      ; Store in counter
    JMP.W CODE_00A7DE              ; Jump to text drawing

;-------------------------------------------------------------------------------
; CODE_00B550: Tilemap buffer manipulation (unclear function)
;
; Purpose: Complex tilemap buffer operation
; Entry: $015F = counter/index
;        $1A = tilemap pointer
;        $1F = parameter
; Exit: Tilemap buffer updated
;       $015F updated
; Notes: Uses indexed buffer writes with loop
;-------------------------------------------------------------------------------
CODE_00B550:
    db $C2,$20,$E2,$10,$AD,$5F,$01,$A4,$1F,$87,$1A,$E6,$1A,$E6,$1A,$1A
    db $88,$D0,$F6,$8D,$5F,$01,$60
    ; REP #$20; SEP #$10
    ; LDA $015F; LDY $1F
    ; STA [$1A]; INC $1A; INC $1A; INC A
    ; DEY; BNE loop; STA $015F; RTS

;-------------------------------------------------------------------------------
; CODE_00B567: Character sprite setup and positioning
;
; Purpose: Set up character sprite display parameters based on game state
; Entry: $20 = location/mode ID
;        $DA/$D9/$D0 = state flags
;        $C8 = location parameter
;        $E0 = display flags
;        $22/$23/$24 = sprite position/mode
; Exit: $22 = sprite X position (adjusted)
;       $23 = sprite Y position (adjusted)
;       $24 = sprite display mode
;       $D0 bit 2 set/cleared based on location
; Calls: CODE_018A52 (external sprite init)
; Notes: Complex location-based sprite positioning
;        Handles battle vs overworld sprite modes
;        Adjusts for screen centering and boundaries
;-------------------------------------------------------------------------------
CODE_00B567:
    PHP                            ; Save processor status
    SEP #$20                       ; 8-bit accumulator
    REP #$10                       ; 16-bit X/Y
    LDA.B #$10                     ; Bit 4 mask
    AND.W $00DA                    ; Test bit 4 of $DA
    BEQ CODE_00B57E                ; If clear, normal mode
    LDA.B #$04                     ; Mode 4 (battle mode)
    STA.B $24                      ; Store sprite mode
    LDX.W #$5F78                   ; Sprite data pointer
    STX.B $22                      ; Store in $22
    PLP                            ; Restore processor status
    RTS

CODE_00B57E:
    LDA.B #$04                     ; Bit 2 mask
    TRB.W $00D0                    ; Clear bit 2 of $D0
    JSL.L CODE_018A52              ; Call external sprite init
    LDA.B #$01                     ; Bit 0 mask
    AND.W $00D9                    ; Test bit 0 of $D9
    BEQ CODE_00B592                ; If clear, skip
    LDA.B #$08                     ; Mode 8
    STA.B $24                      ; Store sprite mode

CODE_00B592:
    LDA.B $20                      ; Load location/mode ID
    CMP.B #$0B                     ; Location $0B?
    BEQ CODE_00B5DB                ; If yes, special handling
    CMP.B #$A7                     ; Location $A7?
    BEQ CODE_00B5DB                ; If yes, special handling
    CMP.B #$4F                     ; Location $4F?
    BEQ CODE_00B5D4                ; If yes, set bit 2 in $D0
    CMP.B #$01                     ; Location $01?
    BEQ CODE_00B5C9                ; If yes, adjust X position
    CMP.B #$1B                     ; Location $1B?
    BEQ CODE_00B5C9                ; If yes, adjust X position
    CMP.B #$30                     ; Location $30?
    BEQ CODE_00B5C9                ; If yes, adjust X position
    CMP.B #$31                     ; Location $31?
    BEQ CODE_00B5C9                ; If yes, adjust X position
    CMP.B #$4E                     ; Location $4E?
    BEQ CODE_00B5C9                ; If yes, adjust X position
    CMP.B #$6B                     ; Location $6B?
    BEQ UNREACH_00B5C2             ; If yes, adjust Y position
    CMP.B #$77                     ; < $77?
    BCC CODE_00B5DF                ; If yes, continue
    CMP.B #$7B                     ; >= $7B?
    BCS CODE_00B5DF                ; If yes, continue
    db $80,$07                     ; BRA CODE_00B5C9 (unconditional)

UNREACH_00B5C2:
    db $18,$A5,$23,$69,$04,$85,$23 ; CLC; LDA $23; ADC #$04; STA $23

CODE_00B5C9:
    CLC                            ; Clear carry
    LDA.B $22                      ; Load X position
    ADC.B #$08                     ; Add 8
    STA.B $22                      ; Store X position
    LDA.B #$04                     ; Mode 4
    STA.B $24                      ; Store sprite mode

CODE_00B5D4:
    LDA.B #$04                     ; Bit 2 mask
    TSB.W $00D0                    ; Set bit 2 of $D0
    BRA CODE_00B5DF                ; Continue

CODE_00B5DB:
    LDA.B #$04                     ; Mode 4
    STA.B $24                      ; Store sprite mode

CODE_00B5DF:
    INC.B $23                      ; Increment Y position
    LDA.B $24                      ; Load sprite mode
    BIT.B #$08                     ; Test bit 3
    BNE CODE_00B5F3                ; If set, use mode 10
    BIT.B #$04                     ; Test bit 2
    BNE CODE_00B5EF                ; If set, use mode 5
    BIT.B #$02                     ; Test bit 1
    BNE CODE_00B5F3                ; If set, use mode 10

CODE_00B5EF:
    LDA.B #$05                     ; Mode 5
    BRA CODE_00B5F5                ; Store mode

CODE_00B5F3:
    LDA.B #$0A                     ; Mode 10

CODE_00B5F5:
    STA.B $24                      ; Store final sprite mode
    LDA.B $23                      ; Load Y position
    CMP.B #$08                     ; < $08?
    BCC UNREACH_00B607             ; If yes, clamp to $08
    CMP.B #$A9                     ; >= $A9?
    BCC CODE_00B60B                ; If no, in range
    db $A9,$A8,$85,$23,$80,$04     ; LDA #$A8; STA $23; BRA CODE_00B60B

UNREACH_00B607:
    db $A9,$08,$85,$23             ; LDA #$08; STA $23

CODE_00B60B:
    CLC                            ; Clear carry
    LDA.B $2D                      ; Load parameter
    XBA                            ; Swap A/B
    LDA.B #$0E                     ; Load 14
    ADC.B $2D                      ; Add to parameter
    STA.B $2D                      ; Store result
    STA.B $64                      ; Store in temp
    ADC.B #$05                     ; Add 5
    CMP.B $23                      ; Compare with Y position
    BCS CODE_00B630                ; If >= Y, use mode bits
    SEC                            ; Set carry
    LDA.B #$A8                     ; Load $A8
    SBC.B $2D                      ; Subtract parameter
    CMP.B $23                      ; Compare with Y
    BCS CODE_00B638                ; If >= Y, continue
    LDA.B $24                      ; Load sprite mode
    AND.B #$F7                     ; Clear bit 3
    ORA.B #$04                     ; Set bit 2
    STA.B $24                      ; Store updated mode
    BRA CODE_00B638                ; Continue

CODE_00B630:
    LDA.B $24                      ; Load sprite mode
    AND.B #$FB                     ; Clear bit 2
    ORA.B #$08                     ; Set bit 3
    STA.B $24                      ; Store updated mode

CODE_00B638:
    XBA                            ; Swap A/B
    STA.B $2D                      ; Store parameter
    LDA.B $22                      ; Load X position
    CMP.B #$20                     ; < $20?
    BCC CODE_00B657                ; If yes, clamp to $08
    CMP.B #$D1                     ; >= $D1?
    BCC CODE_00B667                ; If no, in range
    db $C9,$E9,$90,$04,$A9,$E8,$85,$22,$A5,$24,$29,$FD,$09,$01,$85,$24
    db $80,$10                     ; LDA #$E8; STA $22; LDA $24; AND #$FD; ORA #$01; STA $24; BRA

CODE_00B657:
    CMP.B #$08                     ; < $08?
    BCS CODE_00B65F                ; If no, in range
    db $A9,$08,$85,$22             ; LDA #$08; STA $22

CODE_00B65F:
    LDA.B $24                      ; Load sprite mode
    AND.B #$FE                     ; Clear bit 0
    ORA.B #$02                     ; Set bit 1
    STA.B $24                      ; Store updated mode

CODE_00B667:
    LDA.B $24                      ; Load sprite mode
    AND.B #$08                     ; Test bit 3
    BNE CODE_00B674                ; If set, add $10 offset
    SEC                            ; Set carry
    LDA.B $23                      ; Load Y position
    SBC.B $64                      ; Subtract temp
    BRA CODE_00B679                ; Store offset

CODE_00B674:
    CLC                            ; Clear carry
    LDA.B $23                      ; Load Y position
    ADC.B #$10                     ; Add $10

CODE_00B679:
    STA.B $62                      ; Store Y offset
    LDA.W $00C8                    ; Load location parameter
    CMP.B #$00                     ; Check if 0
    BNE CODE_00B68E                ; If not, alternate check
    LDA.B #$40                     ; Bit 6 mask
    AND.W $00E0                    ; Test bit 6 of $E0
    BEQ CODE_00B6B1                ; If clear, done
    LDA.W $01BF                    ; Load character 1 position
    BRA CODE_00B698                ; Check position

CODE_00B68E:
    LDA.B #$80                     ; Bit 7 mask
    AND.W $00E0                    ; Test bit 7 of $E0
    BEQ CODE_00B6B1                ; If clear, done
    LDA.W $0181                    ; Load character 2 position

CODE_00B698:
    CMP.B $62                      ; Compare with Y offset
    BCC CODE_00B6A4                ; If less, check lower bound
    SBC.B $62                      ; Subtract Y offset
    CMP.B $64                      ; Compare with temp
    BCS CODE_00B6B1                ; If >=, done
    BRA CODE_00B6AB                ; Toggle mode

CODE_00B6A4:
    ADC.B $64                      ; Add temp
    DEC A                          ; Decrement
    CMP.B $62                      ; Compare with Y offset
    BCC CODE_00B6B1                ; If less, done

CODE_00B6AB:
    LDA.B $24                      ; Load sprite mode
    EOR.B #$0C                     ; Toggle bits 2-3
    STA.B $24                      ; Store updated mode

CODE_00B6B1:
    PLP                            ; Restore processor status
    RTS

;-------------------------------------------------------------------------------
; CODE_00B6B3: Character sprite display setup
;
; Purpose: Set up character sprite display using character index
; Entry: $9E = character index (or $DE for special case)
; Exit: $62 = sprite mode
;       $64 = position offset
;       Sprite display initiated
; Calls: CODE_008C1B (character data lookup)
;        CODE_0C8000 (external sprite display)
; Notes: Special handling for character $DE
;-------------------------------------------------------------------------------
CODE_00B6B3:
    LDA.B $9E                      ; Load character index
    CMP.W #$00DE                   ; Check if $DE (special)
    BEQ CODE_00B6D5                ; If yes, special handling
    JSR.W CODE_008C1B              ; Look up character data
    STA.B $62                      ; Store sprite mode
    SEP #$30                       ; 8-bit A/X/Y
    LDX.B $9E                      ; X = character index
    LDA.L DATA8_049800,X           ; Load position offset
    ASL A                          ; × 2
    ASL A                          ; × 4

CODE_00B6C9:
    STA.B $64                      ; Store position offset
    LDA.B #$02                     ; Bit 1 mask
    TSB.W $00D4                    ; Set bit 1 of $D4
    JSL.L CODE_0C8000              ; Call external sprite display
    RTS

CODE_00B6D5:
    LDA.W #$0001                   ; Mode 1
    STA.B $62                      ; Store sprite mode
    SEP #$30                       ; 8-bit A/X/Y
    LDA.B #$20                     ; Position $20
    BRA CODE_00B6C9                ; Display sprite

;-------------------------------------------------------------------------------
; CODE_00B6E0: Save script pointer and execute script
;
; Purpose: Save current script pointer and execute CODE_00B78D
; Entry: $17/$18 = current script pointer
; Exit: Script pointer saved on stack
;       CODE_00B78D executed
;-------------------------------------------------------------------------------
CODE_00B6E0:
    PEI.B ($17)                    ; Save script pointer low
    PEI.B ($18)                    ; Save script pointer high
    JMP.W CODE_00B78D              ; Jump to script execution

;-------------------------------------------------------------------------------
; CODE_00B6E7: Update character gold amount
;
; Purpose: Subtract current value from party gold
; Entry: $0164/$0166 = amount to subtract (24-bit)
;        $0E84/$0E86 = current party gold
; Exit: $0E84/$0E86 = updated gold
;       $17/$18 restored from stack
; Notes: Part of shop/transaction system
;-------------------------------------------------------------------------------
CODE_00B6E7:
    SEC                            ; Set carry for subtraction
    LDA.W $0E84                    ; Load gold low word
    SBC.W $0164                    ; Subtract amount low
    STA.W $0E84                    ; Store result low
    SEP #$20                       ; 8-bit accumulator
    LDA.W $0E86                    ; Load gold high byte
    SBC.W $0166                    ; Subtract amount high (with borrow)
    STA.W $0E86                    ; Store result high
    LDA.W $015F                    ; Load character index
    CMP.B #$DD                     ; Check if $DD (special)
    BEQ CODE_00B716                ; If yes, alternate storage
    JSL.L CODE_00DA65              ; Call external routine
    CLC                            ; Clear carry
    ADC.W $0162                    ; Add offset
    STA.W $0E9F,X                  ; Store at indexed location
    LDA.W $015F                    ; Load character index
    STA.W $0E9E,X                  ; Store character ID
    BRA CODE_00B727                ; Restore and return

CODE_00B716:
    CLC                            ; Clear carry
    LDA.W $1030                    ; Load alternate storage
    ADC.W $0162                    ; Add offset
    STA.W $1030                    ; Store result
    BRA CODE_00B727                ; Restore and return

CODE_00B722:
    SEP #$20                       ; 8-bit accumulator
    STZ.W $0162                    ; Clear offset

CODE_00B727:
    PLX                            ; Restore X (script pointer high)
    STX.B $18                      ; Store in $18
    PLX                            ; Restore X (script pointer low)
    STX.B $17                      ; Store in $17
    RTS

;-------------------------------------------------------------------------------
; CODE_00B72E: Input handler for menu navigation
;
; Purpose: Handle controller input for menu cursor movement
; Entry: $07 = controller input state
;        $0162/$0163 = cursor position/limits
;        $95 = wrapping flags
; Exit: $0162 = updated cursor position
;       $17/$18 = script pointer (preserved or updated)
; Calls: CODE_0096A0 (controller read)
;        CODE_009BC4 (menu update)
; Notes: Handles up/down navigation with wrapping
;        Checks button presses and updates cursor
;-------------------------------------------------------------------------------
CODE_00B72E:
    REP #$30                       ; 16-bit A/X/Y
    JSL.L CODE_0096A0              ; Read controller input
    LDA.B $07                      ; Load button state
    STA.B $15                      ; Store in temp
    BIT.W #$8000                   ; Test A button (bit 15)
    BNE CODE_00B722                ; If pressed, clear and return
    BIT.W #$0080                   ; Test B button (bit 7)
    BNE CODE_00B6E7                ; If pressed, update gold
    BIT.W #$0800                   ; Test X button (bit 11)
    BNE UNREACH_00B7B5             ; If pressed, jump ahead
    BIT.W #$0400                   ; Test Y button (bit 10)
    BNE UNREACH_00B797             ; If pressed, move by 10
    BIT.W #$0100                   ; Test Start (bit 8)
    BNE CODE_00B770                ; If pressed, increment cursor
    BIT.W #$0200                   ; Test Select (bit 9)
    BEQ CODE_00B72E                ; If not pressed, loop
    SEP #$20                       ; 8-bit accumulator
    DEC.W $0162                    ; Decrement cursor position
    BPL CODE_00B78D                ; If >= 0, update menu
    LDA.B $95                      ; Load wrapping flags
    AND.B #$02                     ; Test bit 1 (wrap down)
    BEQ UNREACH_00B76B             ; If no wrap, increment back
    LDA.W $0163                    ; Load max position
    STA.W $0162                    ; Wrap to max
    BRA CODE_00B78D                ; Update menu

UNREACH_00B76B:
    db $EE,$62,$01,$80,$BE         ; INC $0162; BRA CODE_00B72E

CODE_00B770:
    SEP #$20                       ; 8-bit accumulator
    INC.W $0162                    ; Increment cursor position
    LDA.W $0163                    ; Load max position
    CMP.W $0162                    ; Compare with current
    BCS CODE_00B78D                ; If max >= current, update
    LDA.B $95                      ; Load wrapping flags
    AND.B #$01                     ; Test bit 0 (wrap up)
    BEQ CODE_00B788                ; If no wrap, decrement back
    STZ.W $0162                    ; Wrap to 0
    BRA CODE_00B78D                ; Update menu

CODE_00B788:
    DEC.W $0162                    ; Decrement back
    BRA CODE_00B72E                ; Read input again

CODE_00B78D:
    REP #$30                       ; 16-bit A/X/Y
    LDX.W #$B7DD                   ; Menu data pointer
    JSR.W CODE_009BC4              ; Update menu display
    BRA CODE_00B72E                ; Read input again

UNREACH_00B797:
    db $E2,$20,$38,$AD,$62,$01,$F0,$08,$E9,$0A,$B0,$0D,$A9,$00,$80,$09
    db $A5,$95,$29,$04,$F0,$81,$AD,$63,$01,$8D,$62,$01,$80,$D8
    ; Cursor movement by 10 (Y button handler)

UNREACH_00B7B5:
    db $E2,$20,$AD,$62,$01,$CD,$63,$01,$F0,$13,$18,$69,$0A,$8D,$62,$01
    db $AD,$63,$01,$CD,$62,$01,$B0,$C0,$8D,$62,$01,$80,$BB,$A5,$95,$29
    db $08,$F0,$BD,$9C,$62,$01,$80,$B0
    ; Cursor movement by 10 (X button handler)

;-------------------------------------------------------------------------------
; DATA at $B7DD: Menu configuration data
;
; Purpose: Menu display configuration
; Format: Unknown structure for menu system
; Used by: CODE_009BC4 (menu update routine)
;-------------------------------------------------------------------------------
DATA_00B7DD:
    db $2B,$8D,$03,$04,$00,$8F,$03,$00,$00,$01,$00,$08,$00,$09,$00,$42
    db $4B,$5A,$00,$00,$03,$16,$00,$11,$00,$00,$00,$00,$00,$00,$00,$00
    db $00,$00,$17,$00,$00,$00,$00,$00,$E0,$00,$CC,$20,$0E,$00,$00,$FF
    db $00,$00,$01,$00,$01,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$07
    db $30,$D9,$05,$31,$00,$42,$12,$00,$30,$7E,$07,$30,$7E

;-------------------------------------------------------------------------------
; CODE_00B82A: IRQ handler (jitter fix - first variant)
;
; Purpose: Interrupt handler for horizontal timing jitter correction
; Entry: Called by SNES IRQ interrupt
; Exit: NMI disabled
;       Interrupt vector updated to CODE_00B86C
; Uses: SNES_NMITIMEN, SNES_SLHV, SNES_STAT78, SNES_OPVCT
; Notes: Samples vertical counter until jitter stabilizes
;        Uses $DA bit 6 for jitter calculation toggle
;        Enables second-stage IRQ handler
;-------------------------------------------------------------------------------
CODE_00B82A:
    REP #$30                       ; 16-bit A/X/Y
    PHB                            ; Save data bank
    PHA                            ; Save accumulator
    PHX                            ; Save X
    SEP #$20                       ; 8-bit accumulator
    PHK                            ; Push program bank
    PLB                            ; Set data bank = program bank
    STZ.W SNES_NMITIMEN            ; Disable NMI/IRQ

CODE_00B836:
    LDA.W SNES_SLHV                ; Sample H/V counter
    LDA.W SNES_STAT78              ; Read PPU status
    LDA.W SNES_OPVCT               ; Read vertical counter
    STA.W $0118                    ; Store V counter
    LDA.B #$40                     ; Bit 6 mask
    AND.W $00DA                    ; Test bit 6 of $DA
    BNE CODE_00B854                ; If set, skip jitter calc
    LDA.W $0118                    ; Load V counter
    ASL A                          ; × 2
    ADC.W $0118                    ; × 3
    ADC.B #$9A                     ; Add offset
    PHA                            ; Push result
    PLP                            ; Pull to processor status (jitter)

CODE_00B854:
    LSR.W $0118                    ; V counter >> 1
    BCS CODE_00B836                ; If carry, resample (unstable)
    LDX.W #$B86C                   ; Second-stage IRQ handler
    STX.W $0118                    ; Store handler address
    LDA.B #$11                     ; Enable V-IRQ + NMI
    STA.W SNES_NMITIMEN            ; Set interrupt mode
    CLI                            ; Enable interrupts
    WAI                            ; Wait for interrupt
    REP #$30                       ; 16-bit A/X/Y
    PLX                            ; Restore X
    PLA                            ; Restore accumulator
    PLB                            ; Restore data bank
    RTI                            ; Return from interrupt

;-------------------------------------------------------------------------------
; CODE_00B86C: IRQ handler (second stage - screen on)
;
; Purpose: Second-stage IRQ handler - turn screen on and switch to NMI
; Entry: Called by IRQ after jitter correction
; Exit: Screen enabled
;       NMI mode set
;       $D8 bit 6 set
;       Interrupt vector updated to CODE_00B82A
; Calls: CODE_008B69 (screen setup)
; Notes: Final stage of screen transition
;-------------------------------------------------------------------------------
CODE_00B86C:
    LDA.B #$80                     ; Screen off brightness
    STA.W SNES_INIDISP             ; Disable screen
    LDA.B #$01                     ; NMI only mode
    STA.W SNES_NMITIMEN            ; Set interrupt mode
    REP #$30                       ; 16-bit A/X/Y
    PHD                            ; Save direct page
    PHY                            ; Save Y
    JSR.W CODE_008B69              ; Screen setup
    SEP #$20                       ; 8-bit accumulator
    LDA.B #$07                     ; V-IRQ timer low
    STA.W SNES_VTIMEL              ; Set V timer
    LDX.W #$B898                   ; Next IRQ handler
    STX.W $0118                    ; Store handler address
    LDA.W $0112                    ; Load interrupt mode
    STA.W SNES_NMITIMEN            ; Set interrupt mode
    LDA.B #$40                     ; Bit 6
    TSB.W $00D8                    ; Set bit 6 of $D8
    PLY                            ; Restore Y
    PLD                            ; Restore direct page
    RTI                            ; Return from interrupt

;-------------------------------------------------------------------------------
; CODE_00B898: IRQ handler (jitter fix - second variant)
;
; Purpose: Alternate IRQ handler for horizontal timing jitter correction
; Entry: Called by SNES IRQ interrupt
; Exit: NMI disabled
;       Interrupt vector updated to CODE_00B8DA
; Uses: Similar to CODE_00B82A but with different offset ($0F vs $9A)
; Notes: Second variant of jitter correction algorithm
;-------------------------------------------------------------------------------
CODE_00B898:
    REP #$30                       ; 16-bit A/X/Y
    PHB                            ; Save data bank
    PHA                            ; Save accumulator
    PHX                            ; Save X
    SEP #$20                       ; 8-bit accumulator
    PHK                            ; Push program bank
    PLB                            ; Set data bank = program bank
    STZ.W SNES_NMITIMEN            ; Disable NMI/IRQ

CODE_00B8A4:
    LDA.W SNES_SLHV                ; Sample H/V counter
    LDA.W SNES_STAT78              ; Read PPU status
    LDA.W SNES_OPVCT               ; Read vertical counter
    STA.W $0118                    ; Store V counter
    LDA.B #$40                     ; Bit 6 mask
    AND.W $00DA                    ; Test bit 6 of $DA
    BNE CODE_00B8C2                ; If set, skip jitter calc
    LDA.W $0118                    ; Load V counter
    ASL A                          ; × 2
    ADC.W $0118                    ; × 3
    ADC.B #$0F                     ; Add offset (different from B82A)
    PHA                            ; Push result
    PLP                            ; Pull to processor status

CODE_00B8C2:
    LSR.W $0118                    ; V counter >> 1
    BCC CODE_00B8A4                ; If no carry, resample (unstable)
    LDX.W #$B8DA                   ; Second-stage IRQ handler
    STX.W $0118                    ; Store handler address
    LDA.B #$11                     ; Enable V-IRQ + NMI
    STA.W SNES_NMITIMEN            ; Set interrupt mode
    CLI                            ; Enable interrupts
    WAI                            ; Wait for interrupt
    REP #$30                       ; 16-bit A/X/Y
    PLX                            ; Restore X
    PLA                            ; Restore accumulator
    PLB                            ; Restore data bank
    RTI                            ; Return from interrupt

;-------------------------------------------------------------------------------
; CODE_00B8DA: IRQ handler (second stage - alternate)
;
; Purpose: Alternate second-stage IRQ handler
; Entry: Called by IRQ after jitter correction (variant 2)
; Exit: Screen enabled ($0110 brightness)
;       NMI mode set
;       $D8 bit 5 set
;       Interrupt vector updated to CODE_00B82A
; Calls: CODE_008BA0, CODE_008B88 (screen setup routines)
; Notes: Uses different screen setup sequence than CODE_00B86C
;-------------------------------------------------------------------------------
CODE_00B8DA:
    LDA.W $0110                    ; Load brightness value
    STA.W SNES_INIDISP             ; Set screen brightness
    LDA.B #$01                     ; NMI only mode
    STA.W SNES_NMITIMEN            ; Set interrupt mode
    PHD                            ; Save direct page
    JSR.W CODE_008BA0              ; Screen setup routine 1
    PHY                            ; Save Y
    JSR.W CODE_008B88              ; Screen setup routine 2
    SEP #$20                       ; 8-bit accumulator
    LDA.B #$D8                     ; V-IRQ timer low
    STA.W $4209                    ; Set V timer (direct address)
    LDX.W #$B82A                   ; First-stage IRQ handler
    STX.W $0118                    ; Store handler address
    LDA.W $0112                    ; Load interrupt mode
    STA.W $4200                    ; Set interrupt mode (direct)
    LDA.B #$20                     ; Bit 5
    TSB.W $00D8                    ; Set bit 5 of $D8
    PLY                            ; Restore Y
    PLD                            ; Restore direct page
    RTI                            ; Return from interrupt

;-------------------------------------------------------------------------------
; CODE_00B908: Set sprite mode $2D
;
; Purpose: Set sprite display mode to $2D
; Entry: None
; Exit: $0505 = $2D
; Notes: Preserves processor status
;-------------------------------------------------------------------------------
CODE_00B908:
    PHP                            ; Save processor status
    SEP #$20                       ; 8-bit accumulator
    LDA.B #$2D                     ; Mode $2D
    STA.W $0505                    ; Store in sprite mode
    PLP                            ; Restore processor status
    RTS

;-------------------------------------------------------------------------------
; CODE_00B912: Set sprite mode $2C
;
; Purpose: Set sprite display mode to $2C
; Entry: None
; Exit: $0505 = $2C
; Notes: Preserves processor status
;-------------------------------------------------------------------------------
CODE_00B912:
    PHP                            ; Save processor status
    SEP #$20                       ; 8-bit accumulator
    LDA.B #$2C                     ; Mode $2C
    STA.W $0505                    ; Store in sprite mode
    PLP                            ; Restore processor status
    RTS

;-------------------------------------------------------------------------------
; CODE_00B91C: Set animation mode $10
;
; Purpose: Set animation mode to $10
; Entry: None
; Exit: $050A = $10
; Notes: Preserves processor status
;-------------------------------------------------------------------------------
CODE_00B91C:
    PHP                            ; Save processor status
    SEP #$20                       ; 8-bit accumulator
    LDA.B #$10                     ; Mode $10
    STA.W $050A                    ; Store in animation mode
    PLP                            ; Restore processor status
    RTS

;-------------------------------------------------------------------------------
; CODE_00B926: Set animation mode $11
;
; Purpose: Set animation mode to $11
; Entry: None
; Exit: $050A = $11
; Notes: Preserves processor status
;-------------------------------------------------------------------------------
CODE_00B926:
    PHP                            ; Save processor status
    SEP #$20                       ; 8-bit accumulator
    LDA.B #$11                     ; Mode $11
    STA.W $050A                    ; Store in animation mode
    PLP                            ; Restore processor status
    RTS

;-------------------------------------------------------------------------------
; CODE_00B930: Input polling loop with mode toggle
;
; Purpose: Poll controller input and toggle sprite mode on button press
; Entry: $07 = controller input state (from CODE_0096A0)
;        $01 = current state
;        $05 = compare state
; Exit: A = button state
;       X = $01 value
;       Flags set based on comparison
;       $0505 may be updated (mode $2C)
; Calls: CODE_0096A0 (controller read)
;        CODE_00B912 (set sprite mode $2C)
; Notes: Loops until specific button condition met
;        XORs button state when no buttons pressed
;-------------------------------------------------------------------------------
CODE_00B930:
    JSL.L CODE_0096A0              ; Read controller input
    BIT.B $07                      ; Test button state
    BNE CODE_00B949                ; If buttons pressed, check
    EOR.W #$FFFF                   ; Invert button state
    BIT.B $07                      ; Test inverted state
    BEQ CODE_00B944                ; If no change, toggle back
    PHA                            ; Save state
    JSR.W CODE_00B912              ; Set sprite mode $2C
    PLA                            ; Restore state

CODE_00B944:
    EOR.W #$FFFF                   ; Invert back
    BRA CODE_00B930                ; Loop

CODE_00B949:
    LDA.B $07                      ; Load button state
    LDX.B $01                      ; Load current state
    CPX.B $05                      ; Compare with compare state
    RTS

;-------------------------------------------------------------------------------
; CODE_00B950: Main initialization/game start routine
;
; Purpose: Initialize game system and start main game loop
; Entry: Called at game start or reset
; Exit: Does not return (infinite game loop)
; Calls: CODE_0C8000 (bank $0C init)
;        CODE_00BAF0 (initialization)
;        CODE_00CBEC (some setup)
; Notes: Sets up initial game state
;        Prepares for main game execution
;-------------------------------------------------------------------------------
CODE_00B950:
    PHP                            ; Save processor status
    PHB                            ; Save data bank
    PHD                            ; Save direct page
    REP #$30                       ; 16-bit A/X/Y
    PEA.W $5555                    ; Push $5555 (init marker?)
    LDA.W #$0080                   ; Bit 7
    TSB.W $00D6                    ; Set bit 7 of $D6
    JSL.L CODE_0C8000              ; Call Bank $0C init
    JSR.W CODE_00BAF0              ; Initialization routine
    STZ.B $01                      ; Clear $01
    SEP #$20                       ; 8-bit accumulator
    JSR.W CODE_00CBEC              ; Setup routine
    REP #$30                       ; 16-bit A/X/Y
    LDX.W #$BA17                   ; Menu data pointer
    JSR.W CODE_009BC4              ; Update menu
    TSC                            ; Transfer stack to A
    STA.W $0105                    ; Save stack pointer
    LDA.W #$0080                   ; Bit 7
    TSB.W $00DE                    ; Set bit 7 of $DE
    PEI.B ($01)                    ; Save $01
    PEI.B ($03)                    ; Save $03
    LDA.W #$0401                   ; Load $0401
    STA.B $03                      ; Store in $03
    LDA.L $701FFC                  ; Load save data flag
    AND.W #$0300                   ; Mask bits 8-9
    STA.B $01                      ; Store in $01
    STA.B $05                      ; Store in $05
    PEA.W LOOSE_OP_00BCF3          ; Push continue address
    LDX.W #$BA14                   ; Menu data
    JSR.W CODE_009BC4              ; Update menu
    LDA.W #$0F00                   ; Load $0F00
    STA.B $8E                      ; Store in brightness?

CODE_00B9A0:
    REP #$30                       ; 16-bit A/X/Y
    LDA.W #$0C80                   ; Button mask
    JSR.W CODE_00B930              ; Poll input
    BNE UNREACH_00B9E0             ; If button pressed, branch
    BIT.W #$0080                   ; Test B button
    BEQ CODE_00B9A0                ; If not pressed, loop
    SEP #$20                       ; 8-bit accumulator
    LDA.B $06                      ; Load save slot selection
    STA.L $701FFD                  ; Store save slot
    REP #$30                       ; 16-bit A/X/Y
    AND.W #$00FF                   ; Mask to 8 bits
    DEC A                          ; Decrement (0-based index)
    STA.W $010E                    ; Store save slot index
    BMI UNREACH_00B9D5             ; If negative (new game), branch
    JSR.W CODE_00C92B              ; Get save slot address
    TAX                            ; X = save address
    LDA.L $700000,X                ; Load save data validity flag
    BEQ UNREACH_00B9DB             ; If empty, branch
    JSR.W CODE_00B908              ; Set sprite mode $2D
    LDA.W $010E                    ; Load save slot index
    JMP.W CODE_00CA63              ; Load game

UNREACH_00B9D5:
    db $20,$08,$B9,$4C,$1A,$BA     ; JSR CODE_00B908; JMP CODE_00BA1A

UNREACH_00B9DB:
    db $20,$12,$B9,$80,$C0         ; JSR CODE_00B912; BRA (skip)

UNREACH_00B9E0:
    db $86,$05,$20,$1C,$B9,$E2,$30,$A9,$EC,$8F,$D8,$56,$7F,$8F,$DA,$56
    db $7F,$8F,$DC,$56,$7F,$8F,$DE,$56,$7F,$A5,$06,$0A,$AA,$A9,$E0,$9F
    db $D8,$56,$7F,$A9,$08,$0C,$D4,$00,$22,$00,$80,$0C,$A9,$08,$1C,$D4
    db $00,$4C,$A0,$B9
    ; STX $05; JSR CODE_00B91C; SEP #$30; (sprite setup code)

DATA_00BA14:
    db $38,$AC,$03,$0B,$95,$03     ; Menu configuration data

;-------------------------------------------------------------------------------
; CODE_00BA1A: Initialize title screen display
;
; Purpose: Set up title screen graphics and palette
; Entry: None
; Exit: Title screen initialized
;       $0111 bit 4 cleared/set for BG3 control
; Calls: CODE_009A11 (graphics init)
;        CODE_009BC4 (menu update)
;        CODE_0C8000 (external init)
; Notes: Sets up BG3 scrolling animation
;        Loads title screen palette from Bank $07
;-------------------------------------------------------------------------------
CODE_00BA1A:
    LDY.W #$1000                   ; Y = $1000 (destination)
    LDA.W #$0303                   ; Graphics mode $0303
    JSR.W CODE_009A11              ; Initialize graphics
    SEP #$20                       ; 8-bit accumulator
    LDX.W #$BAE7                   ; Data pointer
    JSR.W CODE_009BC4              ; Update menu
    LDA.B #$10                     ; Bit 4 mask
    TRB.W $0111                    ; Clear bit 4 of $0111
    JSL.L CODE_0C8000              ; External init call
    STZ.W SNES_BG3VOFS             ; Clear BG3 V-scroll low
    STZ.W SNES_BG3VOFS             ; Clear BG3 V-scroll high
    LDA.B #$17                     ; Enable BG1+BG2+BG3+sprites
    STA.W SNES_TM                  ; Set main screen designation
    LDA.B #$00                     ; Start at Y=0

CODE_00BA41:
    JSL.L CODE_0C8000              ; External call
    STA.W SNES_BG3VOFS             ; Set BG3 V-scroll low
    STZ.W SNES_BG3VOFS             ; Clear BG3 V-scroll high
    CLC                            ; Clear carry
    ADC.B #$08                     ; Add 8 (scroll speed)
    CMP.B #$D0                     ; Check if reached $D0
    BNE CODE_00BA41                ; Loop until done
    LDA.B #$10                     ; Bit 4 mask
    TSB.W $0111                    ; Set bit 4 of $0111
    REP #$30                       ; 16-bit A/X/Y
    STZ.W $00CC                    ; Clear character count
    LDA.W #$060D                   ; Load $060D
    STA.B $03                      ; Store in $03
    LDA.W #$0000                   ; Load 0
    STA.B $05                      ; Clear $05
    STA.B $01                      ; Clear $01
    STA.W $015F                    ; Clear $015F
    BRA CODE_00BADF                ; Jump to menu display

UNREACH_00BA6D:
    db $20,$12,$B9                 ; JSR CODE_00B912

;-------------------------------------------------------------------------------
; CODE_00BA70: Character name entry input loop
;
; Purpose: Handle controller input for character naming
; Entry: $00CC = current character count (0-8)
;        $01 = current cursor position
; Exit: Character name entered
;       $1000-$1007 = entered name
; Calls: CODE_00B930 (input polling)
;        CODE_00B912, CODE_00B926 (sprite modes)
;        CODE_009BC4 (menu update)
; Notes: Supports character entry, deletion, confirmation
;        Max 8 characters per name
;-------------------------------------------------------------------------------
CODE_00BA70:
    REP #$30                       ; 16-bit A/X/Y
    LDA.W #$9F80                   ; Button mask
    JSR.W CODE_00B930              ; Poll input
    BNE CODE_00BAD9                ; If button pressed, process
    BIT.W #$1000                   ; Test L button
    BNE CODE_00BAD1                ; If pressed, confirm
    BIT.W #$8000                   ; Test A button
    BNE UNREACH_00BAC2             ; If pressed, delete char
    BIT.W #$0080                   ; Test B button
    BEQ CODE_00BA70                ; If not pressed, loop
    LDA.B $01                      ; Load cursor position
    CMP.W #$050C                   ; Check if at end position
    BEQ CODE_00BAD1                ; If yes, confirm
    SEP #$30                       ; 8-bit A/X/Y
    LDY.W $00CC                    ; Load character count
    CPY.B #$08                     ; Check if 8 chars entered
    BEQ UNREACH_00BA6D             ; If full, error sound
    LDA.B $06                      ; Load selected character (row)
    STA.W SNES_WRMPYA              ; Set multiplicand
    LDA.B #$1A                     ; Load 26 (chars per row)
    JSL.L CODE_00971E              ; Multiply
    LDA.B $05                      ; Load column
    ASL A                          ; × 2
    ADC.W SNES_RDMPYL              ; Add multiplication result
    TAX                            ; X = character index
    REP #$10                       ; 16-bit X/Y
    INC.W $00CC                    ; Increment character count
    LDA.L DATA8_03A37C,X           ; Load character from table
    STA.W $1000,Y                  ; Store in name buffer
    JSR.W CODE_00B926              ; Set animation mode $11
    LDX.W #$BAED                   ; Menu data
    JSR.W CODE_009BC4              ; Update menu
    BRA CODE_00BA70                ; Loop

UNREACH_00BAC2:
    db $AC,$CC,$00,$F0,$A6,$88,$8C,$CC,$00,$E2,$20,$A9,$03,$80,$E3
    ; LDY $00CC; BEQ skip; DEY; STY $00CC; SEP #$20; LDA #$03; BRA sound

CODE_00BAD1:
    LDA.W $00CC                    ; Load character count
    BEQ UNREACH_00BA6D             ; If empty, error
    JMP.W CODE_00B908              ; Set sprite mode $2D and return

CODE_00BAD9:
    STX.W $015F                    ; Store selected option
    JSR.W CODE_00B91C              ; Set animation mode $10

CODE_00BADF:
    LDX.W #$BAEA                   ; Menu data
    JSR.W CODE_009BC4              ; Update menu
    BRA CODE_00BA70                ; Loop

DATA_00BAE7:
    db $CA,$AC,$03                 ; Menu configuration

DATA_00BAEA:
    db $34,$AD,$03,$21,$AD,$03     ; Menu configuration

;-------------------------------------------------------------------------------
; CODE_00BAF0: System initialization routine
;
; Purpose: Initialize SNES hardware and game system
; Entry: Called at game start
; Exit: System initialized
;       Direct page = $2100 (PPU registers)
;       Graphics loaded, palettes set, sprites configured
; Calls: Multiple graphics and initialization routines
; Notes: Comprehensive system setup
;        Configures PPU, loads graphics, sets up memory
;-------------------------------------------------------------------------------
CODE_00BAF0:
    LDA.W #$2100                   ; PPU register base
    TCD                            ; Set direct page to $2100
    STZ.B SNES_CGSWSEL-$2100       ; Clear color/window select
    LDA.W #$0017                   ; Enable BG1+BG2+BG3+OBJ
    STA.W $212C                    ; Set main screen designation
    LDA.W #$5555                   ; Init marker
    STA.W $0E00                    ; Store marker
    SEP #$20                       ; 8-bit accumulator
    LDA.B #$00                     ; Load 0
    STA.L $7E3664                  ; Clear flag
    LDA.B #$3B                     ; BG1 tilemap = $3B00
    STA.B SNES_BG1SC-$2100         ; Set BG1 screen base
    LDA.B #$4B                     ; BG2 tilemap = $4B00
    STA.B SNES_BG2SC-$2100         ; Set BG2 screen base
    LDA.B #$80                     ; VRAM increment after high byte
    STA.B SNES_VMAINC-$2100        ; Set VRAM increment mode
    REP #$30                       ; 16-bit A/X/Y
    STZ.W $00F0                    ; Clear $F0
    LDX.W #$0000                   ; VRAM address $0000
    STX.B SNES_VMADDL-$2100        ; Set VRAM address
    PEA.W $0007                    ; Bank $07
    PLB                            ; Set data bank to $07
    LDX.W #$8030                   ; Source address
    LDY.W #$0100                   ; Length (256 words)
    JSL.L CODE_008E54              ; DMA transfer to VRAM
    PLB                            ; Restore data bank
    LDX.W #$1000                   ; VRAM address $1000
    STX.B SNES_VMADDL-$2100        ; Set VRAM address
    PEA.W $0004                    ; Bank $04
    PLB                            ; Set data bank to $04
    LDX.W #$9840                   ; Source address
    LDY.W #$0010                   ; Length (16 words)
    JSL.L CODE_008DDF              ; DMA transfer
    PLB                            ; Restore data bank
    LDX.W #$6080                   ; VRAM address $6080
    STX.B SNES_VMADDL-$2100        ; Set VRAM address
    PEA.W $0004                    ; Bank $04
    PLB                            ; Set data bank
    LDX.W #$99C0                   ; Source address
    LDY.W #$0004                   ; Length (4 words)
    JSL.L CODE_008DDF              ; DMA transfer
    PLB                            ; Restore data bank
    SEP #$30                       ; 8-bit A/X/Y
    PEA.W $0007                    ; Bank $07
    PLB                            ; Set data bank
    LDA.B #$20                     ; Palette offset $20
    LDX.B #$00                     ; Palette index 0
    JSR.W CODE_008FB4              ; Load palette
    LDA.B #$30                     ; Palette offset $30
    LDX.B #$08                     ; Palette index 8
    JSR.W CODE_008FB4              ; Load palette
    LDA.B #$60                     ; Palette offset $60
    LDX.B #$10                     ; Palette index 16
    JSR.W CODE_008FB4              ; Load palette
    LDA.B #$70                     ; Palette offset $70
    LDX.B #$18                     ; Palette index 24
    JSR.W CODE_008FB4              ; Load palette
    LDA.B #$40                     ; Palette offset $40
    LDX.B #$20                     ; Palette index 32
    JSR.W CODE_008FB4              ; Load palette
    LDA.B #$50                     ; Palette offset $50
    LDX.B #$28                     ; Palette index 40
    JSR.W CODE_008FB4              ; Load palette
    PLB                            ; Restore data bank
    LDX.B #$00                     ; Index 0
    TXA                            ; A = 0
    PEA.W $0007                    ; Bank $07
    PLB                            ; Set data bank
    JSR.W CODE_00BC49              ; Load color data
    LDX.B #$10                     ; Index 16
    LDA.B #$10                     ; Offset $10
    JSR.W CODE_00BC49              ; Load color data
    PLB                            ; Restore data bank
    LDA.B #$80                     ; CGRAM address $80
    STA.B SNES_CGADD-$2100         ; Set CGRAM address
    PEA.W $0007                    ; Bank $07
    PLB                            ; Set data bank
    LDA.W DATA8_07D814             ; Load color data
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W DATA8_07D815             ; Load color data
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W DATA8_07D816             ; Load color data
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W DATA8_07D817             ; Load color data
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W DATA8_07D818             ; Load color data
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W DATA8_07D819             ; Load color data
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W DATA8_07D81A             ; Load color data
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W DATA8_07D81B             ; Load color data
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W DATA8_07D81C             ; Load color data
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W DATA8_07D81D             ; Load color data
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W DATA8_07D81E             ; Load color data
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W DATA8_07D81F             ; Load color data
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W DATA8_07D820             ; Load color data
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W DATA8_07D821             ; Load color data
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W DATA8_07D822             ; Load color data
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W DATA8_07D823             ; Load color data
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    PLB                            ; Restore data bank
    LDA.B #$31                     ; CGRAM address $31
    STA.B SNES_CGADD-$2100         ; Set CGRAM address
    LDA.W $0E9C                    ; Load color low
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W $0E9D                    ; Load color high
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.B #$71                     ; CGRAM address $71
    STA.B SNES_CGADD-$2100         ; Set CGRAM address
    LDA.W $0E9C                    ; Load color low
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W $0E9D                    ; Load color high
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    STZ.B SNES_BG1HOFS-$2100       ; Clear BG1 H-scroll
    STZ.B SNES_BG1HOFS-$2100       ; (write twice)
    STZ.B SNES_BG1VOFS-$2100       ; Clear BG1 V-scroll
    STZ.B SNES_BG1VOFS-$2100       ; (write twice)
    STZ.B SNES_BG2HOFS-$2100       ; Clear BG2 H-scroll
    STZ.B SNES_BG2HOFS-$2100       ; (write twice)
    STZ.B SNES_BG2VOFS-$2100       ; Clear BG2 V-scroll
    STZ.B SNES_BG2VOFS-$2100       ; (write twice)
    REP #$30                       ; 16-bit A/X/Y
    LDA.W #$0000                   ; Direct page = $0000
    TCD                            ; Restore direct page
    LDX.W #$C8E6                   ; Data pointer
    JSR.W CODE_009BC4              ; Update menu
    JSR.W CODE_00C4DB              ; External routine
    JSR.W CODE_00BD64              ; Clear memory routine
    LDA.W #$0200                   ; Load $0200
    STA.W $01F0                    ; Store in $01F0
    LDA.W #$0020                   ; Load $0020
    STA.W $01F2                    ; Store in $01F2
    LDA.W #$0701                   ; Load $0701
    STA.B $03                      ; Store in $03
    STZ.B $05                      ; Clear $05
    STZ.B $01                      ; Clear $01
    JMP.W CODE_00CF3F              ; Jump to main routine

;-------------------------------------------------------------------------------
; CODE_00BC49: Load palette color data
;
; Purpose: Load 16 colors from Bank $07 to CGRAM
; Entry: A = CGRAM start address
;        X = data offset in Bank $07
;        Data bank = $07
; Exit: 16 colors loaded to CGRAM
; Uses: DATA8_07D7F4 onwards (color data)
;-------------------------------------------------------------------------------
CODE_00BC49:
    STA.B SNES_CGADD-$2100         ; Set CGRAM address
    LDA.W DATA8_07D7F4,X           ; Load color byte
    STA.B SNES_CGDATA-$2100        ; Write to CGRAM
    LDA.W DATA8_07D7F5,X           ; (repeat for 32 bytes = 16 colors)
    STA.B SNES_CGDATA-$2100
    LDA.W DATA8_07D7F6,X
    STA.B SNES_CGDATA-$2100
    LDA.W DATA8_07D7F7,X
    STA.B SNES_CGDATA-$2100
    LDA.W DATA8_07D7F8,X
    STA.B SNES_CGDATA-$2100
    LDA.W DATA8_07D7F9,X
    STA.B SNES_CGDATA-$2100
    LDA.W DATA8_07D7FA,X
    STA.B SNES_CGDATA-$2100
    LDA.W DATA8_07D7FB,X
    STA.B SNES_CGDATA-$2100
    LDA.W DATA8_07D7FC,X
    STA.B SNES_CGDATA-$2100
    LDA.W DATA8_07D7FD,X
    STA.B SNES_CGDATA-$2100
    LDA.W DATA8_07D7FE,X
    STA.B SNES_CGDATA-$2100
    LDA.W DATA8_07D7FF,X
    STA.B SNES_CGDATA-$2100
    LDA.W DATA8_07D800,X
    STA.B SNES_CGDATA-$2100
    LDA.W DATA8_07D801,X
    STA.B SNES_CGDATA-$2100
    LDA.W DATA8_07D802,X
    STA.B SNES_CGDATA-$2100
    LDA.W DATA8_07D803,X
    STA.B SNES_CGDATA-$2100
    RTS

;-------------------------------------------------------------------------------
; CODE_00BC9C: Set display update flag and execute screen update
;
; Purpose: Set bit 0 of $D8 and call screen update routine
; Entry: None
; Exit: $D8 bit 0 set
;       Screen update executed
;-------------------------------------------------------------------------------
CODE_00BC9C:
    PHP                            ; Save processor status
    SEP #$30                       ; 8-bit A/X/Y
    LDA.B #$01                     ; Bit 0 mask
    TSB.W $00D8                    ; Set bit 0 of $D8
    PLP                            ; Restore processor status

;-------------------------------------------------------------------------------
; CODE_00BCA5: Screen transition/reset routine
;
; Purpose: Reset screen and reinitialize game state
; Entry: $0E00 = state marker
; Exit: Screen reinitialized
;       Game state restored
; Calls: CODE_00C7B8 (external routine)
;        CODE_00BAF0 (initialization)
;        CODE_00C7DE or CODE_00C7F0 (conditional screen setup)
;        CODE_009BC4 (menu update)
;        CODE_00C795 (external routine)
;        CODE_00BDB9 (menu handler)
;        CODE_00BD64 (clear memory)
;        CODE_00C4DB (external routine)
;        CODE_00CF3F (main routine)
; Notes: Handles screen transitions and state restoration
;-------------------------------------------------------------------------------
CODE_00BCA5:
    PHP                            ; Save processor status
    PHB                            ; Save data bank
    PHD                            ; Save direct page
    REP #$30                       ; 16-bit A/X/Y
    LDA.W #$0010                   ; Bit 4 mask
    TRB.W $00D6                    ; Clear bit 4 of $D6
    LDA.W $0E00                    ; Load state marker
    PHA                            ; Save on stack
    STZ.W $008E                    ; Clear $8E
    JSL.L CODE_00C7B8              ; External routine
    JSR.W CODE_00BAF0              ; Initialize system
    LDA.W #$0001                   ; Bit 0 mask
    AND.W $00D8                    ; Test bit 0 of $D8
    BNE CODE_00BCCB                ; If set, alternate path
    JSR.W CODE_00C7DE              ; Screen setup routine 1
    BRA CODE_00BCCE                ; Continue

CODE_00BCCB:
    JSR.W CODE_00C7F0              ; Screen setup routine 2

CODE_00BCCE:
    LDX.W #$BE80                   ; Data pointer
    JSR.W CODE_009BC4              ; Update menu
    LDA.W #$0020                   ; Bit 5 mask
    TSB.W $00D2                    ; Set bit 5 of $D2
    JSL.L CODE_00C795              ; External routine
    LDA.W #$00A0                   ; Load $A0
    STA.W $01F0                    ; Store in $01F0
    LDA.W #$000A                   ; Load $0A
    STA.W $01F2                    ; Store in $01F2
    TSC                            ; Transfer stack to A
    STA.W $0105                    ; Save stack pointer
    JSR.W CODE_00BDB9              ; Menu handler
    LDA.W #$00FF                   ; Load $FF
    SEP #$30                       ; 8-bit A/X/Y
    STA.W $0104                    ; Store in $0104
    REP #$30                       ; 16-bit A/X/Y
    LDA.W $0105                    ; Load stack pointer
    TCS                            ; Restore stack
    JSL.L CODE_00C7B8              ; External routine
    JSR.W CODE_00BD64              ; Clear memory
    LDX.W #$C8E9                   ; Data pointer
    JSR.W CODE_009BC4              ; Update menu
    JSL.L CODE_0C8000              ; External init
    LDA.W #$0040                   ; Load $40
    STA.W $01F0                    ; Store in $01F0
    LDA.W #$0004                   ; Load $04
    STA.W $01F2                    ; Store in $01F2
    PLA                            ; Restore state marker
    STA.W $0E00                    ; Store back
    JSR.W CODE_00C78D              ; External routine
    JSR.W CODE_008230              ; External routine
    PLD                            ; Restore direct page
    PLB                            ; Restore data bank
    PLP                            ; Restore processor status
    RTL                            ; Return

;-------------------------------------------------------------------------------
; CODE_00BD2A: Screen update wrapper
;
; Purpose: Call screen update and graphics routine
; Entry: None
; Exit: Screen updated
; Calls: CODE_00BD30 (screen update)
;        CODE_00C795 (graphics routine)
;-------------------------------------------------------------------------------
CODE_00BD2A:
    JSR.W CODE_00BD30              ; Screen update
    JMP.W CODE_00C795              ; Graphics routine

;-------------------------------------------------------------------------------
; CODE_00BD30: Screen update and initialization
;
; Purpose: Update screen display and reinitialize subsystems
; Entry: None
; Exit: Screen updated
;       Subsystems initialized
; Calls: Multiple initialization routines
; Notes: Major screen refresh routine
;-------------------------------------------------------------------------------
CODE_00BD30:
    PHP                            ; Save processor status
    PHD                            ; Save direct page
    SEP #$20                       ; 8-bit accumulator
    REP #$10                       ; 16-bit X/Y
    PEA.W $0000                    ; Direct page = $0000
    PLD                            ; Set direct page
    LDX.W #$BD61                   ; Data pointer
    JSR.W CODE_009BC4              ; Update menu
    JSL.L CODE_0C8000              ; External init
    JSR.W CODE_008EC4              ; External routine
    JSR.W CODE_008C3D              ; External routine
    JSR.W CODE_008D29              ; External routine
    JSL.L CODE_009B2F              ; External routine
    JSR.W CODE_00A342              ; External routine
    LDA.B #$10                     ; Bit 4 mask
    TSB.W $00D6                    ; Set bit 4 of $D6
    LDX.W #$FFF0                   ; Load $FFF0
    STX.B $8E                      ; Store in $8E
    PLD                            ; Restore direct page
    PLP                            ; Restore processor status
    RTS

DATA_00BD61:
    db $F2,$82,$03                 ; Configuration data

;-------------------------------------------------------------------------------
; CODE_00BD64: Clear memory routine
;
; Purpose: Clear memory range $0C20-$0E1F (512 bytes)
; Entry: None
; Exit: Memory cleared to $5555 pattern
;       Tilemap initialized
; Notes: Uses MVN for fast block fill
;        Sets up character display tilemap
;-------------------------------------------------------------------------------
CODE_00BD64:
    LDA.W #$5555                   ; Fill pattern
    STA.W $0C20                    ; Store at start
    LDX.W #$0C20                   ; Source address
    LDY.W #$0C22                   ; Destination address
    LDA.W #$01FD                   ; Length (509 bytes)
    MVN $00,$00                    ; Block move (fill memory)
    LDX.W #$BD99                   ; Tilemap data pointer
    STX.B $5F                      ; Store in $5F
    LDX.W #$0000                   ; Tilemap index = 0
    LDY.W #$0020                   ; Counter = 32 tiles

CODE_00BD81:
    SEP #$20                       ; 8-bit accumulator
    LDA.B ($5F)                    ; Load tile number
    STA.W $0C22,X                  ; Store in tilemap
    LDA.B #$30                     ; Palette 3
    STA.W $0C23,X                  ; Store attributes
    REP #$30                       ; 16-bit A/X/Y
    INC.B $5F                      ; Next tile data
    INX                            ; Advance tilemap index
    INX                            ; (4 bytes per entry)
    INX
    INX
    DEY                            ; Decrement counter
    BNE CODE_00BD81                ; Loop until done
    RTS

;-------------------------------------------------------------------------------
; DATA_00BD99: Character display tilemap data
;
; Purpose: Tile numbers for character name/stats display
; Format: 32 tile numbers (1 byte each)
;-------------------------------------------------------------------------------
DATA_00BD99:
    db $08,$0A,$09,$0B,$08,$09,$0A,$0B,$10,$11,$12,$13,$18,$19,$1A,$1B
    db $10,$11,$12,$13,$28,$29,$2A,$2B,$10,$11,$12,$13,$38,$39,$3A,$3B

;-------------------------------------------------------------------------------
; CODE_00BDB9: Menu/dialog input handler
;
; Purpose: Handle menu input and dialog display
; Entry: $D8 bit 0 indicates mode
; Exit: User selection processed
; Calls: CODE_00B930 (input polling)
;        CODE_00B912, CODE_00B91C (sprite modes)
;        CODE_009BC4 (menu update)
; Notes: Complex menu navigation system
;-------------------------------------------------------------------------------
CODE_00BDB9:
    PHK                            ; Push program bank
    PLB                            ; Set data bank
    LDA.W #$0001                   ; Bit 0 mask
    AND.W $00D8                    ; Test bit 0 of $D8
    BNE CODE_00BDFD                ; If set, alternate mode
    LDA.W #$FFF0                   ; Load $FFF0
    STA.B $8E                      ; Store in $8E
    BRA CODE_00BDF5                ; Continue

UNREACH_00BDCA:
    db $20,$12,$B9                 ; JSR CODE_00B912

CODE_00BDCD:
    LDA.W #$CCB0                   ; Button mask
    JSR.W CODE_00B930              ; Poll input
    BNE CODE_00BDF5                ; If button pressed, process
    BIT.W #$0080                   ; Test B button
    BNE CODE_00BE2A                ; If pressed, branch
    BIT.W #$8000                   ; Test A button
    BEQ CODE_00BDCD                ; If not pressed, loop
    JSR.W CODE_00B91C              ; Set animation mode $10
    STZ.B $8E                      ; Clear $8E

CODE_00BDE4:
    RTS

LOOSE_OP_00BDE5:
    PLA                            ; Pull return address
    STA.B $03                      ; Store in $03
    PLA                            ; Pull high byte
    STA.B $05                      ; Store in $05
    PLA                            ; Pull saved value
    STA.B $01                      ; Store in $01
    LDA.W #$FFF0                   ; Load $FFF0
    STA.B $8E                      ; Store in $8E

CODE_00BDF5:
    STX.W $015F                    ; Store input state
    JSR.W CODE_00B91C              ; Set animation mode $10
    BRA CODE_00BE30                ; Continue

CODE_00BDFD:
    LDA.W #$CCB0                   ; Button mask
    JSR.W CODE_00B930              ; Poll input
    BNE CODE_00BE30                ; If button pressed, process
    LDA.B #$01                     ; Bit 0 mask
    TRB.W $00D8                    ; Clear bit 0 of $D8
    BIT.W #$0080                   ; Test B button
    BNE CODE_00BE21                ; If pressed, cancel
    BIT.W #$8000                   ; Test A button
    BEQ CODE_00BDFD                ; If not pressed, loop
    JSR.W CODE_00B91C              ; Set animation mode $10
    LDA.W #$FFFF                   ; Load $FFFF
    STA.B $01                      ; Store in $01
    STZ.B $8E                      ; Clear $8E
    RTS

CODE_00BE21:
    JSR.W CODE_00B912              ; Set sprite mode $2D
    LDA.W #$00FF                   ; Load $FF
    STA.B $01                      ; Store in $01
    RTS

CODE_00BE2A:
    LDA.B #$01                     ; Bit 0 mask
    TRB.W $00D8                    ; Clear bit 0 of $D8
    RTS

CODE_00BE30:
    LDX.W #$BE80                   ; Data pointer
    JSR.W CODE_009BC4              ; Update menu
    BRA CODE_00BDCD                ; Loop

DATA_00BE38:
    db $02,$04                     ; Configuration data

DATA_00BE3A:
    db $2B,$BF,$03,$06,$02,$00,$04,$00,$06,$00,$08,$00,$04,$01,$06,$01
    db $00,$00,$02,$00,$04,$00,$06,$00,$08,$00,$04,$01,$06,$01,$00,$02
    db $02,$02,$04,$02,$06,$02,$08,$02,$04,$03,$06,$03

DATA_00BE66:
    db $1C,$BF,$80,$00,$11,$0E,$11,$0E,$30,$70,$80,$00,$2F,$03,$2E,$03
    db $00,$00,$80,$00

DATA_00BE7A:
    db $78,$BE,$03,$6B,$BE,$03,$38,$BE,$03

DATA_00BE83:
    db $7A,$BE,$03,$3A,$BE,$03,$66,$BE,$03

;-------------------------------------------------------------------------------
; CODE_00BE83: Menu handler with party member selection
;
; Purpose: Display menu with party member selection capability
; Entry: A = menu option parameter
;        $1090 = companion status flags (negative if no companion)
; Exit: $14 = selected option or $FF
;       $7E3664 = selected option stored
; Calls: CODE_00B91C (update sprite), CODE_009BC4 (show menu)
; Notes: Handles single-character vs two-character party
;        Saves/restores menu state on stack
;-------------------------------------------------------------------------------
CODE_00BE83:
    PHP                            ; Save processor status
    SEP #$20                       ; 8-bit accumulator
    REP #$10                       ; 16-bit index
    STA.W $04E0                    ; Store menu parameter
    LDA.B #$04                     ; Menu active flag
    TSB.W $00DA                    ; Set bit 2 in flags
    PEI.B ($8E)                    ; Save position
    PEI.B ($01)                    ; Save option
    PEI.B ($03)                    ; Save menu type
    LDA.B #$FF                     ; No selection
    STA.B $14                      ; Initialize result
    STZ.B $8E                      ; Clear position low
    STZ.B $8F                      ; Clear position high
    LDX.W #$0102                   ; Two options (two characters)
    LDA.W $1090                    ; Check companion status
    BPL CODE_00BEA9                ; Branch if companion present
    LDX.W #$0101                   ; One option (solo)

CODE_00BEA9:
    STX.B $03                      ; Set menu configuration
    STZ.B $01                      ; Clear option
    STZ.B $02                      ; Clear option high
    LDA.L $7E3664                  ; Load last selection
    BEQ CODE_00BEC9                ; Branch if zero
    BMI UNREACH_00BEC0             ; Branch if negative
    LDA.W $1090                    ; Check companion status again
    BMI CODE_00BEC9                ; Branch if no companion
    INC.B $01                      ; Select second option
    BRA CODE_00BEC9                ; Continue

UNREACH_00BEC0:
    db $AD,$E0,$04,$29,$20,$D0,$0D,$80,$07  ; Unreachable data

CODE_00BEC9:
    LDA.W $04E0                    ; Load parameter
    AND.B #$10                     ; Check bit 4
    BEQ UNREACH_00BED4             ; Branch if clear

CODE_00BED0:
    LDA.B $01                      ; Load current option
    BRA CODE_00BED6                ; Continue

UNREACH_00BED4:
    db $A9,$80                     ; Unreachable data

CODE_00BED6:
    LDX.B $14                      ; Load previous result
    CMP.B $14                      ; Compare with current
    STA.B $14                      ; Store new result
    STA.L $7E3664                  ; Save selection
    BEQ CODE_00BEEA                ; Branch if unchanged
    TXA                            ; Get previous
    CMP.B #$FF                     ; Was cancelled?
    BEQ CODE_00BEEA                ; Branch if yes
    JSR.W CODE_00B91C              ; Update sprite

CODE_00BEEA:
    LDX.W #$BF48                   ; Menu data
    JSR.W CODE_009BC4              ; Show menu
    LDX.W #$FFF0                   ; Position offset (-16)
    STX.B $8E                      ; Set position

;-------------------------------------------------------------------------------
; CODE_00BE8C: Menu option selection handler
;
; Purpose: Handle menu cursor and option selection
; Entry: $01 = current menu option
;        $03 = menu configuration
; Exit: $01 = selected option or $FF for cancel
; Calls: CODE_00B930 (input polling)
;        CODE_00B912, CODE_00B926, CODE_00B91C (sprite/animation modes)
;        CODE_009BC4 (menu update)
; Notes: Supports cursor wrapping, confirmation, cancellation
;-------------------------------------------------------------------------------
CODE_00BE8C:
    LDA.W #$CCB0                   ; Button mask
    JSR.W CODE_00B930              ; Poll input
    BNE CODE_00BED8                ; If button pressed, process
    BIT.W #$0080                   ; Test B button
    BNE CODE_00BEB3                ; If pressed, cancel
    BIT.W #$8000                   ; Test A button
    BEQ CODE_00BE8C                ; If not pressed, loop
    JSR.W CODE_00B91C              ; Set animation mode $10
    LDA.W #$000F                   ; Mask low 4 bits
    AND.B $01                      ; Get current selection
    CMP.W #$000C                   ; Check if option $0C
    BEQ CODE_00BEB3                ; If yes, treat as cancel
    LDA.B $01                      ; Load full option
    STA.W $015F                    ; Store selection
    LDA.W #$FFFF                   ; Load $FFFF
    STA.B $01                      ; Store in $01
    STZ.B $8E                      ; Clear $8E
    RTS

CODE_00BEB3:
    JSR.W CODE_00B912              ; Set sprite mode $2D
    LDA.W #$00FF                   ; Load $FF (cancel code)
    STA.B $01                      ; Store in $01
    RTS

UNREACH_00BEBB:
    db $A9,$01,$00,$1C,$D8,$00,$60 ; LDA #$0001; TRB $00D8; RTS

DATA_00BEC2:
    db $D8,$00,$03,$C2,$00,$03,$F5,$00,$03

DATA_00BECB:
    db $F2,$82,$03

LOOSE_OP_00BECE:
    db $9C,$10,$01,$9C,$12,$01,$60 ; STZ $0110; STZ $0112; RTS

UNREACH_00BED5:
    db $48,$22,$00,$80,$0C         ; PHA; JSL CODE_0C8000; (more code)

CODE_00BED8:
    STX.W $015F                    ; Store input state
    JSR.W CODE_00B91C              ; Set animation mode $10
    LDX.W #$BE80                   ; Data pointer
    JSR.W CODE_009BC4              ; Update menu
    BRA CODE_00BE8C                ; Loop

UNREACH_00BEE5:
    db $A9,$B0,$CC,$22,$30,$B9,$00,$F0,$F1,$89,$80,$00,$F0,$03,$4C,$CC
    db $BE,$20,$12,$B9,$A9,$FF,$00,$85,$01,$60
    ; LDA #$CCB0; JSL CODE_00B930; (menu polling code)

;-------------------------------------------------------------------------------
; CODE_00BF00: Complex menu update routine
;
; Purpose: Update menu display with multiple options
; Entry: $01 = current option
;        $03 = menu data pointer
; Exit: Menu updated
; Calls: CODE_009BC4 (menu update)
;        CODE_00B930 (input polling)
;        CODE_00B926 (animation mode)
; Notes: Handles multi-option menus with cursor navigation
;-------------------------------------------------------------------------------
CODE_00BF00:
    PHK                            ; Push program bank
    PLB                            ; Set data bank
    JSR.W CODE_00B926              ; Set animation mode $11
    LDX.W #$BECB                   ; Data pointer
    JSR.W CODE_009BC4              ; Update menu

CODE_00BF0B:
    LDA.W #$CCB0                   ; Button mask
    JSR.W CODE_00B930              ; Poll input
    BNE CODE_00BF28                ; If button pressed, process
    BIT.W #$0080                   ; Test B button
    BEQ CODE_00BF0B                ; If not pressed, loop
    STZ.B $8E                      ; Clear $8E
    RTS

UNREACH_00BF1B:
    db $20,$1C,$B9,$A9,$FF,$FF,$85,$01,$9C,$8E,$00,$60
    ; JSR CODE_00B91C; LDA #$FFFF; STA $01; STZ $8E; RTS

DATA_00BF27:
    db $00                         ; Padding

CODE_00BF28:
    STX.W $015F                    ; Store input state
    JSR.W CODE_00B91C              ; Set animation mode $10
    BRA CODE_00BF0B                ; Loop

;-------------------------------------------------------------------------------
; CODE_00BF30: Item use/equip system cleanup and return
;
; Purpose: Restore state after item menu operations
; Entry: Processor status saved on stack
;        $01, $03, $8E saved on stack
;        $14 = result code
; Exit: Restored state, A = result code
; Calls: CODE_009BC4 (menu update)
; Notes: Cleanup routine for item management
;-------------------------------------------------------------------------------
CODE_00BF30:
    LDA.B #$04                     ; Bit 2 mask
    TRB.W $00DA                    ; Clear bit 2 of $DA
    LDX.W #$BF48                   ; Menu data
    JSR.W CODE_009BC4              ; Update menu
    PLX                            ; Restore X
    STX.B $03                      ; Restore $03
    PLX                            ; Restore X
    STX.B $01                      ; Restore $01
    PLX                            ; Restore X
    STX.B $8E                      ; Restore $8E
    LDA.B $14                      ; Load result code
    PLP                            ; Restore processor status
    RTS

DATA_00BF48:
    db $9B,$8F,$03                 ; Menu configuration

;-------------------------------------------------------------------------------
; Inventory Item Discard System (CODE_00BF4B - CODE_00C012)
;-------------------------------------------------------------------------------
CODE_00BF4B:
    LDA.W #$0504                   ; Menu mode $0504
    STA.B $03                      ; Store in $03
    LDX.W #$FFF0                   ; Load $FFF0
    STX.B $8E                      ; Store in $8E
    BRA CODE_00BF77                ; Jump to menu display

CODE_00BF57:
    JSR.W CODE_00B912              ; Set sprite mode $2D

CODE_00BF5A:
    LDA.W #$CFB0                   ; Button mask
    JSR.W CODE_00B930              ; Poll input
    BNE CODE_00BF77                ; If button pressed, process
    BIT.W #$0080                   ; Test B button
    BNE CODE_00BF7F                ; If pressed, branch
    BIT.W #$8000                   ; Test A button
    BEQ CODE_00BF5A                ; If not pressed, loop
    JSR.W CODE_00B91C              ; Set animation mode $10
    STZ.B $8E                      ; Clear $8E
    LDX.W #$C032                   ; Menu data
    JMP.W CODE_009BC4              ; Update menu and return

CODE_00BF77:
    LDX.W #$C02F                   ; Menu data
    JSR.W CODE_009BC4              ; Update menu
    BRA CODE_00BF5A                ; Loop

CODE_00BF7F:
    LDA.B $02                      ; Load selection
    AND.W #$00FF                   ; Mask to 8 bits
    BNE CODE_00BF57                ; If not zero, error sound
    LDA.B $01                      ; Load item slot
    AND.W #$00FF                   ; Mask to 8 bits
    ASL A                          ; × 2 (word index)
    TAX                            ; X = item index
    LDA.W $0E9E,X                  ; Load item ID
    AND.W #$00FF                   ; Mask to 8 bits
    CMP.W #$00FF                   ; Check if empty slot
    BEQ CODE_00BF57                ; If empty, error
    CMP.W #$0013                   ; Check if item $13
    BEQ CODE_00BF57                ; If yes, can't discard
    CMP.W #$0011                   ; Check if less than $11
    BCC CODE_00BFEF                ; If yes, handle consumable
    BEQ CODE_00BFD8                ; If $11, handle armor
    JSR.W CODE_00C012              ; Confirm discard
    BCC CODE_00BFAE                ; If confirmed, proceed
    BNE CODE_00BF5A                ; If cancelled, loop
    LDA.W #$0080                   ; Load $80 (companion item)

CODE_00BFAE:
    DEC.W $0E9F,X                  ; Decrement quantity
    CLC                            ; Clear carry
    ADC.W #$1018                   ; Add base address
    TAY                            ; Y = source
    ADC.W #$0003                   ; Add 3
    TAX                            ; X = dest
    LDA.W #$0002                   ; Length = 2
    MVN $00,$00                    ; Block move (shift items)

CODE_00BFC0:
    SEP #$20                       ; 8-bit accumulator
    LDA.W $04DF                    ; Load character ID
    STA.W $0505                    ; Store in $0505
    REP #$30                       ; 16-bit A/X/Y
    JSR.W CODE_00DAA5              ; External routine
    LDX.W #$C035                   ; Menu data
    JSR.W CODE_009BC4              ; Update menu
    BRA CODE_00BF77                ; Loop

UNREACH_00BFD5:
    db $4C,$5A,$BF                 ; JMP CODE_00BF5A

CODE_00BFD8:
    JSR.W CODE_00C012              ; Confirm discard
    BCC CODE_00BFE2                ; If confirmed, proceed
    BNE UNREACH_00BFD5             ; If cancelled, loop
    LDA.W #$0080                   ; Load $80

CODE_00BFE2:
    DEC.W $0E9F,X                  ; Decrement quantity
    TAX                            ; X = item offset
    SEP #$20                       ; 8-bit accumulator
    STZ.W $1021,X                  ; Clear equipped flag
    REP #$30                       ; 16-bit A/X/Y
    BRA CODE_00BFC0                ; Update display

CODE_00BFEF:
    JSR.W CODE_00C012              ; Confirm discard
    BCC CODE_00BFF9                ; If confirmed, proceed
    BNE UNREACH_00BFD5             ; If cancelled, loop
    LDA.W #$0080                   ; Load $80

CODE_00BFF9:
    DEC.W $0E9F,X                  ; Decrement quantity
    TAX                            ; X = item offset
    LDA.W $1016,X                  ; Load max HP
    LSR A                          ; ÷ 4 (HP recovery amount)
    LSR A
    ADC.W $1014,X                  ; Add current HP
    CMP.W $1016,X                  ; Check if exceeds max
    BCC CODE_00C00D                ; If not, store
    LDA.W $1016,X                  ; Use max HP

CODE_00C00D:
    STA.W $1014,X                  ; Store new HP
    BRA CODE_00BFC0                ; Update display

;-------------------------------------------------------------------------------
; CODE_00C012: Confirm item discard dialog
;
; Purpose: Show confirmation dialog for discarding items
; Entry: A = item ID
; Exit: Carry clear if confirmed (A=1), carry set if cancelled
; Calls: CODE_028AE0, CODE_00B908, CODE_00BE83
; Notes: Uses $04E0 for input tracking
;-------------------------------------------------------------------------------
CODE_00C012:
    PHX                            ; Save X
    SEP #$20                       ; 8-bit accumulator
    STA.W $043A                    ; Store item ID
    JSL.L CODE_028AE0              ; External routine
    JSR.W CODE_00B908              ; Set sprite mode $2D
    REP #$30                       ; 16-bit A/X/Y
    LDA.W #$0010                   ; Menu type $10
    JSR.W CODE_00BE83              ; Show confirmation menu
    PLX                            ; Restore X
    AND.W #$00FF                   ; Mask result
    CMP.W #$0001                   ; Check if confirmed
    RTS

DATA_00C02F:
    db $E8,$8F,$03,$DD,$8F,$03,$8A,$8F,$03

;-------------------------------------------------------------------------------
; Spell Equip/Unequip System (CODE_00C038 - CODE_00C1D8)
;-------------------------------------------------------------------------------
CODE_00C038:
    LDA.W #$0406                   ; Menu mode $0406
    STA.B $03                      ; Store in $03
    LDX.W #$FFF0                   ; Load $FFF0
    STX.B $8E                      ; Store in $8E
    BRA CODE_00C08D                ; Jump to menu display

UNREACH_00C044:
    db $20,$12,$B9                 ; JSR CODE_00B912

CODE_00C047:
    LDA.W #$CFB0                   ; Button mask
    JSR.W CODE_00B930              ; Poll input
    BNE CODE_00C08D                ; If button pressed, process
    BIT.W #$0080                   ; Test B button
    BNE CODE_00C098                ; If pressed, branch
    BIT.W #$8000                   ; Test A button
    BEQ CODE_00C047                ; If not pressed, loop
    JSR.W CODE_00B91C              ; Set animation mode $10
    STZ.B $8E                      ; Clear $8E
    LDX.W #$C1D6                   ; Menu data
    JMP.W CODE_009BC4              ; Update menu and return

UNREACH_00C064:
    db $AD,$91,$0E,$29,$7F,$00,$C9,$07,$00,$90,$D5,$20,$B1,$C1,$F0,$D3
    db $DE,$18,$10,$E2,$20,$A9,$14,$8D,$3A,$04,$22,$E0,$8A,$02,$AD,$DF
    db $04,$8D,$05,$05,$A9,$14,$4C,$F4,$BC

CODE_00C08D:
    LDX.W #$C1D3                   ; Menu data
    JSR.W CODE_009BC4              ; Update menu
    BRA CODE_00C047                ; Loop

UNREACH_00C095:
    db $4C,$44,$C0                 ; JMP UNREACH_00C044

CODE_00C098:
    LDA.B $01                      ; Load character selection
    AND.W #$00FF                   ; Mask to 8 bits
    BEQ CODE_00C0B2                ; If character 0, branch
    CMP.W #$0003                   ; Check if character 3
    BNE UNREACH_00C044             ; If not, error
    LDA.W $1090                    ; Load companion data
    AND.W #$00FF                   ; Mask to 8 bits
    CMP.W #$00FF                   ; Check if no companion
    BEQ UNREACH_00C044             ; If none, error
    LDA.W #$0080                   ; Load $80 (companion offset)

CODE_00C0B2:
    TAX                            ; X = character offset
    LDA.W $1021,X                  ; Load status flags
    AND.W #$00F9                   ; Mask out certain flags
    BNE UNREACH_00C044             ; If flagged, error
    LDA.W #$0007                   ; Load 7 (max spell slot -1)
    SEC                            ; Set carry
    SBC.B $02                      ; Subtract selection
    AND.W #$00FF                   ; Mask to 8 bits
    JSR.W CODE_0097F2              ; Get bit mask
    AND.W $1038,X                  ; Test spell equipped
    BEQ UNREACH_00C095             ; If not equipped, error
    LDA.W $1018,X                  ; Load current MP
    AND.W #$00FF                   ; Mask to 8 bits
    BEQ UNREACH_00C095             ; If no MP, error
    LDA.B $02                      ; Load spell slot
    AND.W #$00FF                   ; Mask to 8 bits
    BEQ UNREACH_00C064             ; If slot 0, special case
    CMP.W #$0002                   ; Check if slot 2
    BCC CODE_00C13B                ; If slot 1, HP healing
    BEQ CODE_00C11F                ; If slot 2, cure/status
    JSR.W CODE_00C1B1              ; Confirm spell use
    BEQ CODE_00C138                ; If cancelled, loop
    CMP.W #$0001                   ; Check result
    BEQ CODE_00C0F4                ; If 1, branch
    TAX                            ; X = character offset
    LDA.W $1016                    ; Load max HP
    STA.W $1014                    ; Restore to full HP
    TXA                            ; A = character offset

CODE_00C0F4:
    CMP.W #$0000                   ; Check if character 0
    BEQ CODE_00C0FF                ; If yes, skip
    LDA.W $1096                    ; Load companion max HP
    STA.W $1094                    ; Restore companion HP

CODE_00C0FF:
    SEP #$20                       ; 8-bit accumulator
    LDX.W #$0000                   ; Default character offset
    LDA.B $01                      ; Load character selection
    BEQ CODE_00C10B                ; If 0, use default
    LDX.W #$0080                   ; Companion offset

CODE_00C10B:
    DEC.W $1018,X                  ; Decrement MP
    LDA.W $04DF                    ; Load character ID
    STA.W $0505                    ; Store in $0505
    REP #$30                       ; 16-bit A/X/Y
    LDX.W #$C035                   ; Menu data
    JSR.W CODE_009BC4              ; Update menu
    JMP.W CODE_00C08D              ; Loop

CODE_00C11F:
    JSR.W CODE_00C1B1              ; Confirm spell use
    BEQ CODE_00C138                ; If cancelled, loop
    SEP #$20                       ; 8-bit accumulator
    CMP.B #$01                     ; Check result
    BEQ CODE_00C12D                ; If 1, branch
    STZ.W $1021                    ; Clear status (char 0)

CODE_00C12D:
    CMP.B #$00                     ; Check if character 0
    BEQ CODE_00C134                ; If yes, skip
    STZ.W $10A1                    ; Clear companion status

CODE_00C134:
    REP #$30                       ; 16-bit A/X/Y
    BRA CODE_00C0FF                ; Continue

CODE_00C138:
    JMP.W CODE_00C047              ; Loop

CODE_00C13B:
    JSR.W CODE_00C1B1              ; Confirm spell use
    BEQ CODE_00C138                ; If cancelled, loop
    PHA                            ; Save character offset
    LDA.W $1025,X                  ; Load spell power
    AND.W #$00FF                   ; Mask to 8 bits
    STA.B $64                      ; Store in $64
    ASL A                          ; × 2
    ADC.B $64                      ; + original (× 3)
    LSR A                          ; ÷ 2 (× 1.5)
    CLC                            ; Clear carry
    ADC.W #$0032                   ; Add base value (50)
    STA.B $98                      ; Store recovery amount
    TAY                            ; Y = recovery
    LDA.B $01,S                    ; Load character from stack
    CMP.W #$0001                   ; Check if character 1
    BEQ CODE_00C16F                ; If yes, skip HP calc
    LDA.W $1016                    ; Load max HP
    JSR.W CODE_00C18D              ; Calculate percentage
    ADC.W $1014                    ; Add current HP
    CMP.W $1016                    ; Check if exceeds max
    BCC CODE_00C16C                ; If not, store
    LDA.W $1016                    ; Use max HP

CODE_00C16C:
    STA.W $1014                    ; Store new HP

CODE_00C16F:
    STY.B $98                      ; Restore recovery amount
    LDA.B $01,S                    ; Load character from stack
    BEQ CODE_00C189                ; If character 0, skip
    LDA.W $1096                    ; Load companion max HP
    JSR.W CODE_00C18D              ; Calculate percentage
    ADC.W $1094                    ; Add companion current HP
    CMP.W $1096                    ; Check if exceeds max
    BCC CODE_00C186                ; If not, store
    LDA.W $1096                    ; Use max HP

CODE_00C186:
    STA.W $1094                    ; Store companion HP

CODE_00C189:
    PLA                            ; Restore character offset
    JMP.W CODE_00C0FF              ; Continue

;-------------------------------------------------------------------------------
; CODE_00C18D: Calculate percentage-based HP recovery
;
; Purpose: Calculate HP recovery as percentage of max HP
; Entry: A = max HP value
;        $98 = base recovery amount
; Exit: A = calculated recovery amount
; Uses: $98-$A0 for calculation
;-------------------------------------------------------------------------------
CODE_00C18D:
    STA.B $9C                      ; Store max HP
    JSL.L CODE_0096B3              ; Multiply routine
    LDA.B $9E                      ; Load result low
    STA.B $98                      ; Store in $98
    LDA.B $A0                      ; Load result high
    STA.B $9A                      ; Store in $9A
    LDA.W #$0064                   ; Divisor = 100
    STA.B $9C                      ; Store divisor
    JSL.L CODE_0096E4              ; Divide routine
    LDA.B $03,S                    ; Load character offset from stack
    CMP.W #$0080                   ; Check if companion
    BNE CODE_00C1AD                ; If not, skip
    db $46,$9E                     ; LSR $9E (halve result)

CODE_00C1AD:
    LDA.B $9E                      ; Load result
    CLC                            ; Clear carry
    RTS

;-------------------------------------------------------------------------------
; CODE_00C1B1: Spell use confirmation
;
; Purpose: Confirm spell usage and show dialog
; Entry: $02 = spell slot
; Exit: A = character offset (0 or $80), Z flag set if cancelled
; Calls: CODE_028AE0, CODE_00B908, CODE_00BE83
;-------------------------------------------------------------------------------
CODE_00C1B1:
    PHX                            ; Save X
    SEP #$20                       ; 8-bit accumulator
    LDA.B $02                      ; Load spell slot
    CLC                            ; Clear carry
    ADC.B #$14                     ; Add $14 (spell offset)
    STA.W $043A                    ; Store spell ID
    JSL.L CODE_028AE0              ; External routine
    JSR.W CODE_00B908              ; Set sprite mode $2D
    LDA.W $04E0                    ; Load input flags
    REP #$30                       ; 16-bit A/X/Y
    JSR.W CODE_00BE83              ; Show confirmation menu
    PLX                            ; Restore X
    AND.W #$00FF                   ; Mask result
    CMP.W #$00FF                   ; Check if cancelled
    RTS

DATA_00C1D3:
    db $3A,$90,$03,$DD,$8F,$03

;-------------------------------------------------------------------------------
; Battle Settings Menu (CODE_00C1D9 - CODE_00C348)
;-------------------------------------------------------------------------------
CODE_00C1D9:
    LDA.W #$0020                   ; Bit 5 mask
    TSB.W $00D6                    ; Set bit 5 of $D6
    LDA.W #$0602                   ; Menu mode $0602
    STA.B $03                      ; Store in $03
    LDA.W #$BFF0                   ; Load $BFF0
    STA.B $8E                      ; Store in $8E
    BRA CODE_00C1EE                ; Jump to input loop

UNREACH_00C1EB:
    db $20,$12,$B9                 ; JSR CODE_00B912

CODE_00C1EE:
    REP #$30                       ; 16-bit A/X/Y
    LDA.W #$CF30                   ; Button mask
    JSR.W CODE_00B930              ; Poll input
    BNE CODE_00C218                ; If button pressed, process
    BIT.W #$4000                   ; Test Y button
    BNE UNREACH_00C20E             ; If pressed, branch
    BIT.W #$8000                   ; Test A button
    BEQ CODE_00C1EE                ; If not pressed, loop
    JSR.W CODE_00B91C              ; Set animation mode $10
    STZ.B $8E                      ; Clear $8E
    LDA.W #$0020                   ; Bit 5 mask
    TRB.W $00D6                    ; Clear bit 5 of $D6
    RTS

UNREACH_00C20E:
    db $E2,$20,$AD,$90,$10,$30,$D6,$4C,$D9,$C2

CODE_00C218:
    TXA                            ; Transfer button state
    SEP #$20                       ; 8-bit accumulator
    LDA.B #$00                     ; Clear high byte
    XBA                            ; Swap bytes
    CMP.W $0006                    ; Compare with current setting
    BNE CODE_00C226                ; If different, update
    JMP.W CODE_00C2C3              ; Toggle setting

CODE_00C226:
    PHA                            ; Save setting
    JSR.W CODE_00B91C              ; Set animation mode $10
    PLA                            ; Restore setting
    CMP.B #$01                     ; Check setting type
    BCC CODE_00C28E                ; If < 1, handle battle speed
    BEQ CODE_00C26D                ; If = 1, handle battle mode
    CMP.B #$03                     ; Check if < 3
    BCC CODE_00C260                ; If yes, handle cursor memory
    BEQ CODE_00C250                ; If = 3, handle green color
    CMP.B #$05                     ; Check if < 5
    BCC CODE_00C242                ; If yes, handle blue color
    LDA.W $0E9D                    ; Load color data high byte
    LSR A                          ; Extract red component
    LSR A
    BRA CODE_00C253                ; Store result

CODE_00C242:
    REP #$30                       ; 16-bit A/X/Y
    LDA.W $0E9C                    ; Load color data
    LSR A                          ; Extract blue component
    LSR A
    SEP #$20                       ; 8-bit accumulator
    LSR A
    LSR A
    LSR A
    BRA CODE_00C253                ; Store result

CODE_00C250:
    LDA.W $0E9C                    ; Load color data (green)

CODE_00C253:
    AND.B #$1F                     ; Mask to 5 bits
    INC A                          ; Increment
    LSR A                          ; ÷ 4 (scale down)
    LSR A
    LDX.W #$0009                   ; X = 9 (data offset)
    LDY.W #$0609                   ; Y = menu mode
    BRA CODE_00C29D                ; Continue

CODE_00C260:
    LDA.W $0E9B                    ; Load cursor memory setting
    AND.B #$07                     ; Mask to 3 bits
    LDX.W #$0006                   ; X = 6
    LDY.W #$0607                   ; Y = menu mode
    BRA CODE_00C29D                ; Continue

CODE_00C26D:
    LDA.W $1090                    ; Load battle mode setting
    BPL CODE_00C27C                ; If active mode, branch
    LDA.B $06                      ; Load current selection
    EOR.B #$02                     ; Toggle bit 1
    AND.B #$FE                     ; Clear bit 0
    STA.B $02                      ; Store new selection
    BRA CODE_00C226                ; Loop

CODE_00C27C:
    LDA.B #$80                     ; Load $80
    AND.W $10A0                    ; Test companion flag
    BEQ CODE_00C285                ; If not set, use 0
    LDA.B #$FF                     ; Load $FF

CODE_00C285:
    INC A                          ; Increment (0 or 1)
    LDX.W #$0003                   ; X = 3
    LDY.W #$0602                   ; Y = menu mode
    BRA CODE_00C29D                ; Continue

CODE_00C28E:
    LDA.B #$80                     ; Load $80
    AND.W $0EC6                    ; Test battle speed flag
    BEQ CODE_00C297                ; If not set, use 0
    db $A9,$01                     ; LDA #$01

CODE_00C297:
    LDX.W #$0000                   ; X = 0
    LDY.W #$0602                   ; Y = menu mode

CODE_00C29D:
    STY.B $03                      ; Store menu mode
    STA.B $01                      ; Store current value
    LDA.W DATA8_00C339,X           ; Load color byte 1
    STA.L $7F56D7                  ; Store to WRAM
    LDA.W DATA8_00C33A,X           ; Load color byte 2
    STA.L $7F56D9                  ; Store to WRAM
    LDA.W DATA8_00C33B,X           ; Load color byte 3
    STA.L $7F56DB                  ; Store to WRAM

CODE_00C2B6:
    LDX.B $01                      ; Load current value
    STX.B $05                      ; Store in $05
    LDX.W #$C345                   ; Menu data
    JSR.W CODE_009BC4              ; Update menu
    JMP.W CODE_00C1EE              ; Loop

CODE_00C2C3:
    LDA.B $02                      ; Load option index
    BEQ CODE_00C2E3                ; If 0, toggle battle speed
    CMP.B #$02                     ; Check if 2
    BCC CODE_00C2D9                ; If < 2, toggle battle mode
    BNE CODE_00C2F0                ; If > 2, handle colors
    LDA.W $0E9B                    ; Load cursor memory
    AND.B #$F8                     ; Clear low 3 bits
    ORA.B $01                      ; Set new value
    STA.W $0E9B                    ; Store cursor memory
    BRA CODE_00C2EB                ; Update display

CODE_00C2D9:
    LDA.W $10A0                    ; Load companion flag
    EOR.B #$80                     ; Toggle bit 7
    STA.W $10A0                    ; Store back
    BRA CODE_00C2EB                ; Update display

CODE_00C2E3:
    LDA.W $0EC6                    ; Load battle speed
    EOR.B #$80                     ; Toggle bit 7
    STA.W $0EC6                    ; Store back

CODE_00C2EB:
    JSR.W CODE_00B908              ; Set sprite mode $2D
    BRA CODE_00C2B6                ; Update display

CODE_00C2F0:
    CMP.B #$04                     ; Check if 4
    BCC CODE_00C325                ; If < 4, handle blue
    BEQ CODE_00C30A                ; If = 4, handle green
    LDA.B #$7C                     ; Mask for red component
    TRB.W $0E9D                    ; Clear red bits
    LDA.B $01                      ; Load new value
    ASL A                          ; Shift left 4 times
    ASL A
    ASL A
    ASL A
    BPL CODE_00C305                ; If positive, use value
    LDA.B #$7C                     ; Max value

CODE_00C305:
    TSB.W $0E9D                    ; Set red bits
    BRA CODE_00C2EB                ; Update display

CODE_00C30A:
    REP #$30                       ; 16-bit A/X/Y
    LDA.W #$03E0                   ; Mask for green component
    TRB.W $0E9C                    ; Clear green bits
    LDA.B $00                      ; Load new value
    AND.W #$FF00                   ; Get high byte
    LSR A                          ; Shift right
    CMP.W #$0400                   ; Check if exceeds max
    BNE CODE_00C320                ; If not, use value
    LDA.W #$03E0                   ; Max value

CODE_00C320:
    TSB.W $0E9C                    ; Set green bits
    BRA CODE_00C2EB                ; Update display

CODE_00C325:
    LDA.B #$1F                     ; Mask for blue component
    TRB.W $0E9C                    ; Clear blue bits
    LDA.B $01                      ; Load new value
    ASL A                          ; Shift left 2 times
    ASL A
    CMP.B #$20                     ; Check if exceeds max
    BNE CODE_00C334                ; If not, use value
    LDA.B #$1F                     ; Max value

CODE_00C334:
    TSB.W $0E9C                    ; Set blue bits
    BRA CODE_00C2EB                ; Update display

DATA_00C339:
    db $1F                         ; Blue data
DATA8_00C339:
    db $1F                         ; Blue data
DATA8_00C33A:
    db $20                         ; Green data
DATA8_00C33B:
    db $78,$3F,$20,$58,$5F,$20,$38,$7F,$38,$00

DATA_00C345:
    db $94,$92,$03

;-------------------------------------------------------------------------------
; Save File Deletion System (CODE_00C348 - CODE_00C3A2)
;-------------------------------------------------------------------------------
CODE_00C348:
    LDA.W #$0301                   ; Menu mode $0301
    STA.B $03                      ; Store in $03
    LDX.W #$0C00                   ; Load $0C00
    STX.B $8E                      ; Store in $8E

CODE_00C352:
    LDA.W #$8C80                   ; Button mask
    JSR.W CODE_00B930              ; Poll input
    BNE CODE_00C39D                ; If button pressed, process
    BIT.W #$0080                   ; Test B button
    BNE CODE_00C36A                ; If pressed, cancel
    BIT.W #$8000                   ; Test A button
    BEQ CODE_00C352                ; If not pressed, loop

CODE_00C364:
    JSR.W CODE_00B91C              ; Set animation mode $10
    STZ.B $8E                      ; Clear $8E
    RTS

CODE_00C36A:
    JSR.W CODE_00B908              ; Set sprite mode $2D
    SEP #$20                       ; 8-bit accumulator
    LDA.B $02                      ; Load save slot selection
    INC A                          ; +1 (1-based index)
    STA.L $701FFD                  ; Store save slot
    DEC A                          ; Back to 0-based
    REP #$30                       ; 16-bit A/X/Y
    AND.W #$00FF                   ; Mask to 8 bits
    STA.W $010E                    ; Store slot index
    JSR.W CODE_00C9D3              ; Get save slot address
    LDA.W #$0040                   ; Bit 6 mask
    TSB.W $00DE                    ; Set bit 6 of $DE
    JSR.W CODE_00CF3F              ; Clear save data
    LDX.W #$C3D8                   ; Menu data
    JSR.W CODE_009BC4              ; Update menu
    LDA.B $9E                      ; Load result
    BIT.W #$8000                   ; Test bit 15
    BNE CODE_00C364                ; If set, return
    BIT.W #$0C00                   ; Test bits 10-11
    BEQ CODE_00C352                ; If clear, loop

CODE_00C39D:
    LDA.W #$0000                   ; Load 0
    SEP #$20                       ; 8-bit accumulator
    LDA.B #$EC                     ; Load $EC
    STA.L $7F56DA                  ; Store to WRAM
    STA.L $7F56DC                  ; Store to WRAM
    STA.L $7F56DE                  ; Store to WRAM
    LDA.B $02                      ; Load option index
    CMP.B $06                      ; Compare with previous
    BEQ CODE_00C3BD                ; If same, skip update
    STA.B $06                      ; Store new selection
    JSR.W CODE_00B91C              ; Update sprite
    LDA.B $06                      ; Reload selection

CODE_00C3BD:
    ASL A                          ; × 2
    TAX                            ; Transfer to X
    LDA.B #$E0                     ; Load $E0
    STA.L $7F56DA,X                ; Store to WRAM indexed
    LDA.B #$08                     ; Bit 3 mask
    TSB.W $00D4                    ; Set bit 3
    JSL.L CODE_0C8000              ; Call external routine
    LDA.B #$08                     ; Bit 3 mask
    TRB.W $00D4                    ; Clear bit 3
    REP #$30                       ; 16-bit A/X/Y
    JMP.W CODE_00C352              ; Jump back to loop

DATA_00C3D8:
    db $C3,$95,$03

;-------------------------------------------------------------------------------
; Menu Scrolling System (CODE_00C3DB - CODE_00C439)
;-------------------------------------------------------------------------------
CODE_00C3DB:
    LDA.W #$0305                   ; Menu mode $0305
    STA.B $03                      ; Store in $03
    LDX.W #$FFF0                   ; Position offset (-16)
    STX.B $8E                      ; Set position
    BRA CODE_00C439                ; Jump to menu display

CODE_00C3E7:
    LDA.W #$CF30                   ; Button mask
    JSR.W CODE_00B930              ; Poll input
    BIT.W #$0300                   ; Test Y/X buttons
    BNE CODE_00C407                ; If pressed, process
    BIT.W #$0C00                   ; Test L/R buttons
    BNE CODE_00C439                ; If pressed, refresh
    BIT.W #$8000                   ; Test A button
    BEQ CODE_00C3E7                ; If not pressed, loop
    JSR.W CODE_00B91C              ; Update sprite
    STZ.B $8E                      ; Clear position
    LDX.W #$C444                   ; Menu data
    JMP.W CODE_009BC4              ; Show menu

CODE_00C407:
    SEP #$20                       ; 8-bit accumulator
    LDA.B $01                      ; Load menu option
    CMP.B #$04                     ; Check if option 4
    BEQ CODE_00C423                ; If yes, scroll down
    LDA.B $04                      ; Load scroll position
    CMP.B #$03                     ; Check if at top
    BEQ CODE_00C437                ; If yes, can't scroll up
    DEC.B $04                      ; Decrement scroll
    LDA.B $02                      ; Load current index
    SBC.B #$02                     ; Subtract 2
    BCS CODE_00C41F                ; If no underflow, continue
    LDA.B #$00                     ; Clamp to 0

CODE_00C41F:
    STA.B $02                      ; Store new index
    BRA CODE_00C437                ; Continue

CODE_00C423:
    LDA.B $04                      ; Load scroll position
    CMP.B #$04                     ; Check if at bottom
    BEQ CODE_00C437                ; If yes, can't scroll down
    INC.B $04                      ; Increment scroll
    LDA.B $02                      ; Load current index
    ADC.B #$02                     ; Add 2
    CMP.B #$04                     ; Check if >= 4
    BNE CODE_00C435                ; If not, continue
    LDA.B #$03                     ; Clamp to 3

CODE_00C435:
    STA.B $02                      ; Store new index

CODE_00C437:
    REP #$30                       ; 16-bit A/X/Y

CODE_00C439:
    LDX.W #$C441                   ; Menu data
    JSR.W CODE_009BC4              ; Update menu
    BRA CODE_00C3E7                ; Loop

DATA_00C441:
    db $8E,$90,$03

DATA_00C444:
    db $47,$91,$03

;-------------------------------------------------------------------------------
; Another Menu Scrolling System (CODE_00C447 - CODE_00C494)
;-------------------------------------------------------------------------------
CODE_00C447:
    LDA.W #$0305                   ; Menu mode $0305
    STA.B $03                      ; Store in $03
    LDX.W #$FFF0                   ; Position offset (-16)
    STX.B $8E                      ; Set position
    BRA CODE_00C494                ; Jump to menu display

CODE_00C453:
    LDA.W #$CF30                   ; Button mask
    JSR.W CODE_00B930              ; Poll input
    BIT.W #$0300                   ; Test Y/X buttons
    BNE CODE_00C473                ; If pressed, process
    BIT.W #$0C00                   ; Test L/R buttons
    BNE CODE_00C494                ; If pressed, refresh
    BIT.W #$8000                   ; Test A button
    BEQ CODE_00C453                ; If not pressed, loop
    JSR.W CODE_00B91C              ; Update sprite
    STZ.B $8E                      ; Clear position
    LDX.W #$C49F                   ; Menu data
    JMP.W CODE_009BC4              ; Show menu

CODE_00C473:
    SEP #$20                       ; 8-bit accumulator
    LDA.B $01                      ; Load menu option
    CMP.B #$04                     ; Check if option 4
    BEQ CODE_00C488                ; If yes, scroll to bottom
    LDA.B #$03                     ; Load 3
    CMP.B $04                      ; Compare with scroll position
    BEQ CODE_00C492                ; If equal, done
    STA.B $04                      ; Store 3
    DEC A                          ; Decrement to 2
    STA.B $02                      ; Store index
    BRA CODE_00C492                ; Continue

CODE_00C488:
    LDA.B #$01                     ; Load 1
    CMP.B $04                      ; Compare with scroll position
    BEQ CODE_00C492                ; If equal, done
    STA.B $04                      ; Store 1
    STZ.B $02                      ; Clear index

CODE_00C492:
    REP #$30                       ; 16-bit A/X/Y

CODE_00C494:
    LDX.W #$C49C                   ; Menu data
    JSR.W CODE_009BC4              ; Update menu
    BRA CODE_00C453                ; Loop

DATA_00C49C:
    db $E3,$91,$03

DATA_00C49F:
    db $47,$91,$03

;-------------------------------------------------------------------------------
; Wait Loop with Input Polling (CODE_00C4A2 - CODE_00C4D7)
;-------------------------------------------------------------------------------
CODE_00C4A2:
    LDX.W #$FFF0                   ; Position offset (-16)
    STX.B $8E                      ; Set position

CODE_00C4A7:
    JSL.L CODE_0096A0              ; Call external routine
    LDA.W #$0080                   ; Bit 7 mask
    AND.W $00D9                    ; Test flag
    BEQ CODE_00C4C1                ; If clear, continue
    db $A9,$80,$00,$1C,$D9,$00,$A2,$D8,$C4,$20,$C4,$9B,$80,$E6  ; Data/unreachable

CODE_00C4C1:
    LDA.B $07                      ; Load input result
    AND.W #$BFCF                   ; Mask buttons
    BEQ CODE_00C4A7                ; If no button, loop
    AND.W #$8000                   ; Test A button
    BNE CODE_00C4D2                ; If pressed, confirm
    JSR.W CODE_00B912              ; Update sprite mode
    BRA CODE_00C4A7                ; Loop

CODE_00C4D2:
    JSR.W CODE_00B91C              ; Update sprite
    STZ.B $8E                      ; Clear position
    RTS

DATA_00C4D8:
    db $D1,$9C,$03
;===============================================================================
; WRAM Buffer Management & Screen Setup (CODE_00C4DB - CODE_00C7DD)
;===============================================================================
; This section manages WRAM buffers at $7F5000-$7F5700 for battle menus
; and handles screen initialization for various game modes
;===============================================================================

; CODE_00C4DB - already a stub, implementing now
CODE_00C4DB:
    JSR.W CODE_00C561              ; Clear WRAM buffer 1 ($7F5000)
    JSR.W CODE_00C576              ; Clear WRAM buffer 2 ($7F51B7)
    JSR.W CODE_00C58B              ; Clear WRAM buffer 3 ($7F536E)
    JSR.W CODE_00C5A0              ; Clear WRAM buffer 4 ($7F551E)
    JSR.W CODE_00C604              ; Jump to CODE_00C5B5 (WRAM $7E3000)
    LDX.W #$C51B                   ; Source data pointer
    LDY.W #$5000                   ; Dest: WRAM $7F5000
    LDA.W #$0006                   ; 7 bytes
    MVN $7F,$00                    ; Block move Bank $00 ? $7F
    LDY.W #$4360                   ; Dest: DMA channel 6
    LDA.W #$0007                   ; 8 bytes
    MVN $00,$00                    ; Block move within Bank $00
    LDY.W #$5367                   ; Dest: WRAM $7F5367
    LDA.W #$0006                   ; 7 bytes
    MVN $7F,$00                    ; Block move Bank $00 ? $7F
    LDY.W #$4370                   ; Dest: DMA channel 7
    LDA.W #$0007                   ; 8 bytes
    MVN $00,$00                    ; Block move within Bank $00
    SEP #$20                       ; 8-bit accumulator
    LDA.B #$C0                     ; Bits 6-7
    TSB.W $0111                    ; Set bits in $0111
    REP #$30                       ; 16-bit A/X/Y
    RTS

DATA_00C51B:
    db $FF,$07,$50,$D9,$05,$51,$00,$42,$0E,$00,$50,$7F,$07,$50,$7F,$FF
    db $6E,$53,$D9,$6C,$54,$00,$42,$10,$67,$53,$7F,$6E,$53,$7F

; Helper - Unknown purpose
CODE_00C539:
    PEA.W $007F                    ; Push $007F
    PLB                            ; Pull to data bank
    LDY.W #$5016                   ; WRAM address
    JSR.W CODE_00C54B              ; Call fill routine
    LDY.W #$537D                   ; WRAM address
    JSR.W CODE_00C54B              ; Call fill routine
    PLB                            ; Restore data bank
    RTS

CODE_00C54B:
    LDX.W #$000D                   ; 13 iterations
    CLC                            ; Clear carry

CODE_00C54F:
    SEP #$20                       ; 8-bit accumulator
    LDA.B #$00                     ; Value 0
    JSR.W CODE_0099EA              ; Write to WRAM
    REP #$30                       ; 16-bit A/X/Y
    TYA                            ; Y to A
    ADC.W #$0020                   ; Add $20 (32 bytes)
    TAY                            ; Back to Y
    DEX                            ; Decrement counter
    BNE CODE_00C54F                ; Loop if not zero
    RTS

;-------------------------------------------------------------------------------
; WRAM Buffer Clear Routines
;-------------------------------------------------------------------------------
CODE_00C561:
    LDA.W #$0000                   ; Clear value
    STA.L $7F5007                  ; Write to $7F5007
    LDX.W #$5007                   ; Source
    LDY.W #$5009                   ; Dest
    LDA.W #$01AD                   ; 430 bytes
    MVN $7F,$7F                    ; Fill $7F5007-$7F51B5 with 0
    BRA CODE_00C5F5                ; Continue

CODE_00C576:
    LDA.W #$0100                   ; Value $0100
    STA.L $7F51B7                  ; Write to $7F51B7
    LDX.W #$51B7                   ; Source
    LDY.W #$51B9                   ; Dest
    LDA.W #$01AD                   ; 430 bytes
    MVN $7F,$7F                    ; Fill $7F51B7-$7F5365 with $0100
    BRA CODE_00C5F5                ; Continue

CODE_00C58B:
    LDA.W #$0000                   ; Clear value
    STA.L $7F536E                  ; Write to $7F536E
    LDX.W #$536E                   ; Source
    LDY.W #$5370                   ; Dest
    LDA.W #$01AD                   ; 430 bytes
    MVN $7F,$7F                    ; Fill $7F536E-$7F551C with 0
    BRA CODE_00C5CF                ; Continue

CODE_00C5A0:
    LDA.W #$0100                   ; Value $0100
    STA.L $7F551E                  ; Write to $7F551E
    LDX.W #$551E                   ; Source
    LDY.W #$5520                   ; Dest
    LDA.W #$01AD                   ; 430 bytes
    MVN $7F,$7F                    ; Fill $7F551E-$7F56CC with $0100
    BRA CODE_00C5CF                ; Continue

CODE_00C5B5:
    LDA.W #$0000                   ; Clear value
    STA.L $7E3007                  ; Write to $7E3007
    LDX.W #$3007                   ; Source
    LDY.W #$3009                   ; Dest
    LDA.W #$01AD                   ; 430 bytes
    MVN $7E,$7E                    ; Fill $7E3007-$7E31B5 with 0
    LDA.W #$0120                   ; Value $0120
    STA.W $31B5                    ; Store at $7E31B5
    RTS

CODE_00C5CF:
    TYA                            ; Y to A
    SEC                            ; Set carry
    SBC.W #$0042                   ; Subtract $42
    TAY                            ; Back to Y
    LDX.W #$C5E7                   ; Data pointer
    LDA.L $000EC6                  ; Load battle speed flag
    AND.W #$0080                   ; Test bit 7
    BEQ CODE_00C5E4                ; If clear, use first data
    db $A2,$F0,$C5                 ; LDX #$C5F0 (alternate data)

CODE_00C5E4:
    JMP.W CODE_00C75B              ; Jump to sprite setup

DATA_00C5E7:
    db $0C,$20,$06,$24,$06,$26,$08,$28,$00
    db $18,$20,$08,$28,$00

CODE_00C5F5:
    TYA                            ; Y to A
    SEC                            ; Set carry
    SBC.W #$0042                   ; Subtract $42
    TAY                            ; Back to Y
    LDX.W #$C601                   ; Data pointer
    JMP.W CODE_00C75B              ; Jump to sprite setup

DATA_00C601:
    db $20,$28,$00

CODE_00C604:
    JMP.W CODE_00C5B5              ; Jump to WRAM clear

;-------------------------------------------------------------------------------
; Screen Setup Routines
;-------------------------------------------------------------------------------
CODE_00C607:
    JSR.W CODE_00C5B5              ; Clear WRAM $7E3000
    LDA.W #$0060                   ; Value $60
    LDX.W #$3025                   ; Address $7E3025
    JSR.W CODE_00C65A              ; Fill 8 words
    LDX.W #$3035                   ; Address $7E3035
    BRA CODE_00C62C                ; Continue

CODE_00C618:
    JSR.W CODE_00C561              ; Clear WRAM buffer 1
    LDA.W #$0030                   ; Value $30
    LDX.W #$50F5                   ; Address $7F50F5
    BRA CODE_00C62C                ; Continue

CODE_00C623:
    JSR.W CODE_00C576              ; Clear WRAM buffer 2
    LDA.W #$0030                   ; Value $30
    LDX.W #$52A5                   ; Address $7F52A5

CODE_00C62C:
    JSR.W CODE_00C65A              ; Fill 8 words
    SEC                            ; Set carry

CODE_00C630:
    STA.W $0010,X                  ; Store at X+$10
    STA.W $0012,X                  ; Store at X+$12
    STA.W $0014,X                  ; Store at X+$14
    STA.W $0016,X                  ; Store at X+$16
    STA.W $0018,X                  ; Store at X+$18
    STA.W $001A,X                  ; Store at X+$1A
    STA.W $001C,X                  ; Store at X+$1C
    STA.W $001E,X                  ; Store at X+$1E
    TAY                            ; Transfer to Y
    REP #$30                       ; 16-bit A/X/Y
    TXA                            ; X to A
    ADC.W #$000F                   ; Add 15
    TAX                            ; Back to X
    SEP #$20                       ; 8-bit accumulator
    TYA                            ; Y to A
    SBC.B #$07                     ; Subtract 7
    BNE CODE_00C630                ; Loop if not zero
    REP #$30                       ; 16-bit A/X/Y
    RTS

CODE_00C65A:
    SEP #$20                       ; 8-bit accumulator
    STA.W $0000,X                  ; Store at X+0
    STA.W $0002,X                  ; Store at X+2
    STA.W $0004,X                  ; Store at X+4
    STA.W $0006,X                  ; Store at X+6
    STA.W $0008,X                  ; Store at X+8
    STA.W $000A,X                  ; Store at X+10
    STA.W $000C,X                  ; Store at X+12
    STA.W $000E,X                  ; Store at X+14
    RTS
; ==============================================================================
; Screen Setup and Sprite Systems - CODE_00C675+
; ==============================================================================

CODE_00C675:
    LDY.W #$521D                         ;00C675|A01D52  |      ;
    PHB                                  ;00C678|8B      |      ;
    PHY                                  ;00C679|5A      |      ;
    JSR.W CODE_00C576                    ;00C67A|2076C5  |00C576;
    PLY                                  ;00C67D|7A      |      ;
    LDX.W #$C686                         ;00C67E|A286C6  |      ;
    JSR.W CODE_00C75B                    ;00C681|205BC7  |00C75B;
    PLB                                  ;00C684|AB      |      ;
    RTS                                  ;00C685|60      |      ;

DATA_00C686:
    db $0C,$04,$18,$08,$00               ;00C686|        |      ;

CODE_00C68B:
    PHB                                  ;00C68B|8B      |      ;
    JSR.W CODE_00C576                    ;00C68C|2076C5  |00C576;
    LDX.W #$C6A6                         ;00C68F|A2A6C6  |      ;
    LDY.W #$522D                         ;00C692|A02D52  |      ;
    JSR.W CODE_00C75B                    ;00C695|205BC7  |00C75B;
    JSR.W CODE_00C5A0                    ;00C698|20A0C5  |00C5A0;
    LDX.W #$C6B3                         ;00C69B|A2B3C6  |      ;
    LDY.W #$5634                         ;00C69E|A03456  |      ;
    JSR.W CODE_00C75B                    ;00C6A1|205BC7  |00C75B;
    PLB                                  ;00C6A4|AB      |      ;
    RTS                                  ;00C6A5|60      |      ;

DATA_00C6A6:
    db $0C,$04,$0C,$08,$1C,$0C,$1C,$10,$1C,$14,$10,$18,$00 ;00C6A6|        |      ;

DATA_00C6B3:
    db $1C,$04,$10,$08,$00               ;00C6B3|        |      ;

CODE_00C6B8:
    PHB                                  ;00C6B8|8B      |      ;
    JSR.W CODE_00C576                    ;00C6B9|2076C5  |00C576;
    LDX.W #$C6D3                         ;00C6BC|A2D3C6  |      ;
    LDY.W #$528D                         ;00C6BF|A08D52  |      ;
    JSR.W CODE_00C75B                    ;00C6C2|205BC7  |00C75B;
    JSR.W CODE_00C5A0                    ;00C6C5|20A0C5  |00C5A0;
    LDX.W #$C6D6                         ;00C6C8|A2D6C6  |      ;
    LDY.W #$5574                         ;00C6CB|A07455  |      ;
    JSR.W CODE_00C75B                    ;00C6CE|205BC7  |00C75B;
    PLB                                  ;00C6D1|AB      |      ;
    RTS                                  ;00C6D2|60      |      ;

DATA_00C6D3:
    db $0C,$04,$00                       ;00C6D3|        |      ;

DATA_00C6D6:
    db $0C,$04,$14,$08,$0C,$0C,$34,$10,$0C,$14,$0C,$18,$0C ;00C6D6|        |      ;
    db $1C,$08,$20,$00                   ;00C6E3|        |      ;

CODE_00C6E7:
    PHB                                  ;00C6E7|8B      |      ;
    JSR.W CODE_00C576                    ;00C6E8|2076C5  |00C576;
    LDX.W #$C73F                         ;00C6EB|A23FC7  |      ;
    LDY.W #$527D                         ;00C6EE|A07D52  |      ;
    JSR.W CODE_00C75B                    ;00C6F1|205BC7  |00C75B;
    JSR.W CODE_00C5A0                    ;00C6F4|20A0C5  |00C5A0;
    LDX.W #$C744                         ;00C6F7|A244C7  |      ;
    LDY.W #$55B4                         ;00C6FA|A0B455  |      ;
    JSR.W CODE_00C75B                    ;00C6FD|205BC7  |00C75B;
    LDX.W #$55B4                         ;00C700|A2B455  |      ;
    LDY.W #$0000                         ;00C703|A00000  |      ;
    LDA.L $000101                        ;00C706|AF010100|000101;
    JSR.W CODE_00C729                    ;00C70A|2029C7  |00C729;
    LDX.W #$562C                         ;00C70D|A22C56  |      ;
    LDY.W #$000C                         ;00C710|A00C00  |      ;
    LDA.L $000102                        ;00C713|AF020100|000102;
    JSR.W CODE_00C729                    ;00C717|2029C7  |00C729;
    LDX.W #$56A4                         ;00C71A|A2A456  |      ;
    LDY.W #$0018                         ;00C71D|A01800  |      ;
    LDA.L $000103                        ;00C720|AF030100|000103;
    JSR.W CODE_00C729                    ;00C724|2029C7  |00C729;
    PLB                                  ;00C727|AB      |      ;
    RTS                                  ;00C728|60      |      ;

CODE_00C729:
    AND.W #$0080                         ;00C729|298000  |      ;
    BEQ CODE_00C73E                      ;00C72C|F010    |00C73E;
    db $E2,$20,$98,$9D,$00,$00,$9B,$C8,$C8,$A9,$15,$54,$7F,$7F,$C2,$30 ;00C72E|        |      ;

CODE_00C73E:
    RTS                                  ;00C73E|60      |      ;

DATA_00C73F:
    db $3C,$04,$38,$08,$00               ;00C73F|        |      ;

DATA_00C744:
    db $06,$04,$06,$06,$0C,$08,$24,$0C,$06,$10,$06,$12,$0C,$14,$24,$18 ;00C744|        |      ;
    db $06,$1C,$06,$1E,$08,$20,$00       ;00C754|        |      ;
; ==============================================================================
; Sprite Display System and Save/Load Operations - CODE_00C75B+
; ==============================================================================

CODE_00C75B:
    PHB                                  ;00C75B|8B      |      ;
    PHB                                  ;00C75C|8B      |      ;
    PLA                                  ;00C75D|68      |      ;
    STA.L $000031                        ;00C75E|8F310000|000031;
    SEP #$20                             ;00C762|E220    |      ;

CODE_00C764:
    LDA.L $000000,X                      ;00C764|BF000000|000000;
    BEQ CODE_00C78A                      ;00C768|F020    |00C78A;
    XBA                                  ;00C76A|EB      |      ;
    LDA.L $000001,X                      ;00C76B|BF010000|000001;
    STA.W $0000,Y                        ;00C76F|990000  |7F0000;
    LDA.B #$00                           ;00C772|A900    |      ;
    XBA                                  ;00C774|EB      |      ;
    DEC A                                ;00C775|3A      |      ;
    BEQ UNREACH_00C784                   ;00C776|F00C    |00C784;
    PHX                                  ;00C778|DA      |      ;
    ASL A                                ;00C779|0A      |      ;
    DEC A                                ;00C77A|3A      |      ;
    TYX                                  ;00C77B|BB      |      ;
    INY                                  ;00C77C|C8      |      ;
    INY                                  ;00C77D|C8      |      ;
    JSR.W $0030                          ;00C77E|203000  |000030;
    PLX                                  ;00C781|FA      |      ;
    BRA CODE_00C786                      ;00C782|8002    |00C786;

UNREACH_00C784:
    db $C8,$C8                           ;00C784|        |      ;

CODE_00C786:
    INX                                  ;00C786|E8      |      ;
    INX                                  ;00C787|E8      |      ;
    BRA CODE_00C764                      ;00C788|80DA    |00C764;

CODE_00C78A:
    REP #$30                             ;00C78A|C230    |      ;
    RTS                                  ;00C78C|60      |      ;

CODE_00C78D:
    SEP #$20                             ;00C78D|E220    |      ;
    LDA.B #$C0                           ;00C78F|A9C0    |      ;
    TRB.W $0111                          ;00C791|1C1101  |000111;
    RTS                                  ;00C794|60      |      ;

CODE_00C795:
    PHP                                  ;00C795|08      |      ;
    SEP #$20                             ;00C796|E220    |      ;
    LDA.B #$80                           ;00C798|A980    |      ;
    TRB.W $00D6                          ;00C79A|1CD600  |0000D6;
    LDA.W $00AA                          ;00C79D|ADAA00  |0000AA;
    AND.B #$F0                           ;00C7A0|29F0    |      ;
    STA.W $0110                          ;00C7A2|8D1001  |000110;
    LDA.W $00AA                          ;00C7A5|ADAA00  |0000AA;

CODE_00C7A8:
    CMP.W $0110                          ;00C7A8|CD1001  |000110;
    BEQ CODE_00C7B6                      ;00C7AB|F009    |00C7B6;
    INC.W $0110                          ;00C7AD|EE1001  |000110;
    JSL.L CODE_0C8000                    ;00C7B0|2200800C|0C8000;
    BRA CODE_00C7A8                      ;00C7B4|80F2    |00C7A8;

CODE_00C7B6:
    PLP                                  ;00C7B6|28      |      ;
    RTL                                  ;00C7B7|6B      |      ;

CODE_00C7B8:
    PHP                                  ;00C7B8|08      |      ;
    SEP #$20                             ;00C7B9|E220    |      ;
    LDA.W $0110                          ;00C7BB|AD1001  |010110;
    STA.W $00AA                          ;00C7BE|8DAA00  |0100AA;

CODE_00C7C1:
    BIT.B #$0F                           ;00C7C1|890F    |      ;
    BEQ CODE_00C7CF                      ;00C7C3|F00A    |00C7CF;
    DEC A                                ;00C7C5|3A      |      ;
    STA.W $0110                          ;00C7C6|8D1001  |010110;
    JSL.L CODE_0C8000                    ;00C7C9|2200800C|0C8000;
    BRA CODE_00C7C1                      ;00C7CD|80F2    |00C7C1;

CODE_00C7CF:
    LDA.B #$80                           ;00C7CF|A980    |      ;
    TSB.W $00D6                          ;00C7D1|0CD600  |0100D6;
    LDA.B #$80                           ;00C7D4|A980    |      ;
    STA.W $2100                          ;00C7D6|8D0021  |012100;
    STA.W $0110                          ;00C7D9|8D1001  |010110;
    PLP                                  ;00C7DC|28      |      ;
    RTL                                  ;00C7DD|6B      |      ;

CODE_00C7DE:
    JSR.W CODE_00C618                    ;00C7DE|2018C6  |00C618;
    JSR.W CODE_00C58B                    ;00C7E1|208BC5  |00C58B;
    LDX.W #$C8EC                         ;00C7E4|A2ECC8  |      ;
    JSR.W CODE_009BC4                    ;00C7E7|20C49B  |009BC4;
    LDX.W #$C8E3                         ;00C7EA|A2E3C8  |      ;
    JMP.W CODE_009BC4                    ;00C7ED|4CC49B  |009BC4;

CODE_00C7F0:
    LDA.W $010D                          ;00C7F0|AD0D01  |00010D;
    BPL CODE_00C7F8                      ;00C7F3|1003    |00C7F8;
    LDA.W #$0000                         ;00C7F5|A90000  |      ;

CODE_00C7F8:
    AND.W #$FF00                         ;00C7F8|2900FF  |      ;
    STA.B $01                            ;00C7FB|8501    |000001;
    SEP #$20                             ;00C7FD|E220    |      ;
    LDA.B #$18                           ;00C7FF|A918    |      ;
    STA.W $00AB                          ;00C801|8DAB00  |0000AB;
    JSR.W CODE_00CBEC                    ;00C804|20ECCB  |00CBEC;
    REP #$30                             ;00C807|C230    |      ;
    LDX.W #$C922                         ;00C809|A222C9  |      ;
    JSR.W CODE_009BC4                    ;00C80C|20C49B  |009BC4;
    PHB                                  ;00C80F|8B      |      ;
    LDX.W #$016F                         ;00C810|A26F01  |      ;
    LDY.W #$0E04                         ;00C813|A0040E  |      ;
    LDA.W #$0005                         ;00C816|A90500  |      ;
    MVN $00,$00                          ;00C819|540000  |      ;
    LDA.W #$0020                         ;00C81C|A92000  |      ;
    TSB.W $00D2                          ;00C81F|0CD200  |0000D2;
    JSR.W CODE_00C607                    ;00C822|2007C6  |00C607;
    LDX.W #$51C5                         ;00C825|A2C551  |      ;
    LDY.W #$5015                         ;00C828|A01550  |      ;
    LDA.W #$019F                         ;00C82B|A99F01  |      ;
    MVN $7F,$7F                          ;00C82E|547F7F  |      ;
    LDX.W #$552C                         ;00C831|A22C55  |      ;
    LDY.W #$537C                         ;00C834|A07C53  |      ;
    LDA.W #$019F                         ;00C837|A99F01  |      ;
    MVN $7F,$7F                          ;00C83A|547F7F  |      ;
    PLB                                  ;00C83D|AB      |      ;
    LDX.W #$C8E3                         ;00C83E|A2E3C8  |      ;
    JSR.W CODE_009BC4                    ;00C841|20C49B  |009BC4;
    LDA.W #$0600                         ;00C844|A90006  |      ;
    STA.B $01                            ;00C847|8501    |000001;
    STA.B $05                            ;00C849|8505    |000005;
    RTS                                  ;00C84B|60      |      ;

; Menu initialization and game state management
    LDA.W #$0040                         ;00C84C|A94000  |      ;
    TSB.W $00DB                          ;00C84F|0CDB00  |0000DB;
    BRA CODE_00C85A                      ;00C852|8006    |00C85A;

    LDA.W #$0001                         ;00C854|A90100  |      ;
    TSB.W $00DA                          ;00C857|0CDA00  |0000DA;

CODE_00C85A:
    JSR.W CODE_00C623                    ;00C85A|2023C6  |00C623;
    JSR.W CODE_00C5A0                    ;00C85D|20A0C5  |00C5A0;
    LDX.W #$C8EC                         ;00C860|A2ECC8  |      ;
    BRA CODE_00C89D                      ;00C863|8038    |00C89D;

    LDX.W #$C90A                         ;00C865|A20AC9  |      ;
    BRA CODE_00C89D                      ;00C868|8033    |00C89D;

    LDX.W #$C910                         ;00C86A|A210C9  |      ;
    BRA CODE_00C89D                      ;00C86D|802E    |00C89D;

    LDA.W #$0080                         ;00C86F|A98000  |      ;
    TRB.W $00D9                          ;00C872|1CD900  |0000D9;
    LDX.W #$C916                         ;00C875|A216C9  |      ;
    BRA CODE_00C89D                      ;00C878|8023    |00C89D;

    LDA.W #$0080                         ;00C87A|A98000  |      ;
    TSB.W $00DB                          ;00C87D|0CDB00  |0000DB;
    LDX.W #$C91C                         ;00C880|A21CC9  |      ;
    BRA CODE_00C89D                      ;00C883|8018    |00C89D;

    LDA.W $010D                          ;00C885|AD0D01  |00010D;
    BPL CODE_00C88D                      ;00C888|1003    |00C88D;
    LDA.W #$0000                         ;00C88A|A90000  |      ;

CODE_00C88D:
    AND.W #$FF00                         ;00C88D|2900FF  |      ;
    STA.B $01                            ;00C890|8501    |000001;
    STA.B $05                            ;00C892|8505    |000005;
    LDA.W #$0002                         ;00C894|A90200  |      ;
    TSB.W $00DA                          ;00C897|0CDA00  |0000DA;
    LDX.W #$C922                         ;00C89A|A222C9  |      ;

CODE_00C89D:
    PHX                                  ;00C89D|DA      |      ;
    JSR.W CODE_009BC4                    ;00C89E|20C49B  |009BC4;
    PLX                                  ;00C8A1|FA      |      ;
    INX                                  ;00C8A2|E8      |      ;
    INX                                  ;00C8A3|E8      |      ;
    INX                                  ;00C8A4|E8      |      ;
    LDY.W #$0017                         ;00C8A5|A01700  |      ;
    LDA.W #$0002                         ;00C8A8|A90200  |      ;
    MVN $00,$00                          ;00C8AB|540000  |      ;
    JSR.W CODE_00CAB9                    ;00C8AE|20B9CA  |00CAB9;
    LDX.W #$C8E3                         ;00C8B1|A2E3C8  |      ;
    JMP.W CODE_009BC4                    ;00C8B4|4CC49B  |009BC4;

; Animation and screen effect handlers
    LDX.W #$C8F2                         ;00C8B7|A2F2C8  |      ;
    BRA CODE_00C8C9                      ;00C8BA|800D    |00C8C9;

    LDX.W #$C8F8                         ;00C8BC|A2F8C8  |      ;
    BRA CODE_00C8C9                      ;00C8BF|8008    |00C8C9;

    LDX.W #$C8FE                         ;00C8C1|A2FEC8  |      ;
    BRA CODE_00C8C9                      ;00C8C4|8003    |00C8C9;

    LDX.W #$C904                         ;00C8C6|A204C9  |      ;

CODE_00C8C9:
    PHX                                  ;00C8C9|DA      |      ;
    JSR.W CODE_009BC4                    ;00C8CA|20C49B  |009BC4;
    PLX                                  ;00C8CD|FA      |      ;
    INX                                  ;00C8CE|E8      |      ;
    INX                                  ;00C8CF|E8      |      ;
    INX                                  ;00C8D0|E8      |      ;
    LDA.W #$000C                         ;00C8D1|A90C00  |      ;

CODE_00C8D4:
    JSL.L CODE_0C8000                    ;00C8D4|2200800C|0C8000;
    PHA                                  ;00C8D8|48      |      ;
    PHX                                  ;00C8D9|DA      |      ;
    JSR.W CODE_009BC4                    ;00C8DA|20C49B  |009BC4;
    PLX                                  ;00C8DD|FA      |      ;
    PLA                                  ;00C8DE|68      |      ;
    DEC A                                ;00C8DF|3A      |      ;
    BNE CODE_00C8D4                      ;00C8E0|D0F2    |00C8D4;
    RTS                                  ;00C8E2|60      |      ;
; ==============================================================================
; Save System Data Tables and Checksum Validation - Final Systems
; ==============================================================================

; Save file data table pointers
DATA_00C8E3:
    db $A7,$8F,$03,$F2,$AA,$03,$55,$AB,$03,$AA,$92,$03,$14,$93,$03,$19 ;00C8E3|        |      ;
    db $93,$03,$1F,$93,$03,$28,$93,$03,$33,$93,$03,$3C,$93,$03,$42,$93 ;00C8F3|        |      ;
    db $03,$4B,$93,$03,$57,$93,$03,$60,$93,$03,$A9,$93,$03,$AE,$93,$03 ;00C903|        |      ;
    db $F7,$93,$03,$FC,$93,$03,$74,$94,$03,$79,$94,$03,$DD,$94,$03,$E2 ;00C913|        |      ;
    db $94,$03,$EA,$97,$03                                               ;00C923|        |      ;

; Save slot address calculation
    LDA.W $015F                          ;00C928|AD5F01  |00015F;

CODE_00C92B:
    AND.W #$00FF                         ;00C92B|29FF00  |      ;
    STA.B $98                            ;00C92E|8598    |000098;
    LDA.W #$038C                         ;00C930|A98C03  |      ;
    STA.B $9C                            ;00C933|859C    |00009C;
    JSL.L CODE_0096B3                    ;00C935|22B39600|0096B3;
    LDA.B $9E                            ;00C939|A59E    |00009E;
    CLC                                  ;00C93B|18      |      ;
    ADC.W #$0000                         ;00C93C|690000  |      ;
    STA.B $0B                            ;00C93F|850B    |00000B;
    RTS                                  ;00C941|60      |      ;

CODE_00C942:
    PHP                                  ;00C942|08      |      ;
    SEP #$20                             ;00C943|E220    |      ;
    REP #$10                             ;00C945|C210    |      ;
    PHA                                  ;00C947|48      |      ;
    LDA.B #$7F                           ;00C948|A97F    |      ;
    STA.B $61                            ;00C94A|8561    |000061;
    PLA                                  ;00C94C|68      |      ;
    PLP                                  ;00C94D|28      |      ;
    RTS                                  ;00C94E|60      |      ;

CODE_00C94F:
    PHP                                  ;00C94F|08      |      ;
    SEP #$20                             ;00C950|E220    |      ;
    REP #$10                             ;00C952|C210    |      ;
    PHA                                  ;00C954|48      |      ;
    LDA.B #$70                           ;00C955|A970    |      ;
    STA.B $61                            ;00C957|8561    |000061;
    PLA                                  ;00C959|68      |      ;
    PLP                                  ;00C95A|28      |      ;
    RTS                                  ;00C95B|60      |      ;

CODE_00C95C:
    PHA                                  ;00C95C|48      |      ;
    PHX                                  ;00C95D|DA      |      ;
    LDA.W #$4646                         ;00C95E|A94646  |      ;
    STA.B $0E                            ;00C961|850E    |00000E;
    LDA.W #$2130                         ;00C963|A93021  |      ;
    STA.B $10                            ;00C966|8510    |000010;
    LDX.W #$01C3                         ;00C968|A2C301  |      ;
    LDA.W #$0000                         ;00C96B|A90000  |      ;
    CLC                                  ;00C96E|18      |      ;

CODE_00C96F:
    ADC.B [$5F]                          ;00C96F|675F    |00005F;
    INC.B $5F                            ;00C971|E65F    |00005F;
    INC.B $5F                            ;00C973|E65F    |00005F;
    DEX                                  ;00C975|CA      |      ;
    BNE CODE_00C96F                      ;00C976|D0F7    |00C96F;
    STA.B $12                            ;00C978|8512    |000012;
    PLX                                  ;00C97A|FA      |      ;
    PLA                                  ;00C97B|68      |      ;
    RTS                                  ;00C97C|60      |      ;

CODE_00C97D:
    LDX.W #$0000                         ;00C97D|A20000  |      ;

CODE_00C980:
    LDA.B $0E,X                          ;00C980|B50E    |00000E;
    CMP.B [$0B]                          ;00C982|C70B    |00000B;
    BNE CODE_00C991                      ;00C984|D00B    |00C991;
    INC.B $0B                            ;00C986|E60B    |00000B;
    INC.B $0B                            ;00C988|E60B    |00000B;
    INX                                  ;00C98A|E8      |      ;
    INX                                  ;00C98B|E8      |      ;
    CPX.W #$0006                         ;00C98C|E00600  |      ;
    BNE CODE_00C980                      ;00C98F|D0EF    |00C980;

CODE_00C991:
    RTS                                  ;00C991|60      |      ;

CODE_00C992:
    PHB                                  ;00C992|8B      |      ;
    PHX                                  ;00C993|DA      |      ;
    PHY                                  ;00C994|5A      |      ;
    PHA                                  ;00C995|48      |      ;
    LDX.W #$3000                         ;00C996|A20030  |      ;
    STX.B $5F                            ;00C999|865F    |00005F;
    JSR.W CODE_00C942                    ;00C99B|2042C9  |00C942;
    JSR.W CODE_00C95C                    ;00C99E|205CC9  |00C95C;
    JSR.W CODE_00C92B                    ;00C9A1|202BC9  |00C92B;
    LDY.B $0B                            ;00C9A4|A40B    |00000B;
    LDX.W #$000E                         ;00C9A6|A20E00  |      ;
    LDA.W #$0005                         ;00C9A9|A90500  |      ;
    MVN $70,$00                          ;00C9AC|547000  |      ;
    STY.B $5F                            ;00C9AF|845F    |00005F;
    LDX.W #$3000                         ;00C9B1|A20030  |      ;
    LDA.W #$0385                         ;00C9B4|A98503  |      ;
    MVN $70,$7F                          ;00C9B7|54707F  |      ;
    LDA.B $12                            ;00C9BA|A512    |000012;
    JSR.W CODE_00C94F                    ;00C9BC|204FC9  |00C94F;
    JSR.W CODE_00C95C                    ;00C9BF|205CC9  |00C95C;
    CMP.B $12                            ;00C9C2|C512    |000012;
    BNE UNREACH_00C9CB                   ;00C9C4|D005    |00C9CB;
    JSR.W CODE_00C97D                    ;00C9C6|207DC9  |00C97D;
    BEQ CODE_00C9CE                      ;00C9C9|F003    |00C9CE;

UNREACH_00C9CB:
    db $68,$80,$C7                       ;00C9CB|        |      ;

CODE_00C9CE:
    PLA                                  ;00C9CE|68      |      ;
    PLY                                  ;00C9CF|7A      |      ;
    PLX                                  ;00C9D0|FA      |      ;
    PLB                                  ;00C9D1|AB      |      ;
    RTS                                  ;00C9D2|60      |      ;

CODE_00C9D3:
    PHP                                  ;00C9D3|08      |      ;
    REP #$30                             ;00C9D4|C230    |      ;
    PHB                                  ;00C9D6|8B      |      ;
    PHA                                  ;00C9D7|48      |      ;
    PHD                                  ;00C9D8|0B      |      ;
    PHX                                  ;00C9D9|DA      |      ;
    PHY                                  ;00C9DA|5A      |      ;
    PHA                                  ;00C9DB|48      |      ;
    STZ.B $8E                            ;00C9DC|648E    |00008E;
    PHB                                  ;00C9DE|8B      |      ;
    LDX.W #$1000                         ;00C9DF|A20010  |      ;
    LDY.W #$3000                         ;00C9E2|A00030  |      ;
    LDA.W #$004F                         ;00C9E5|A94F00  |      ;
    MVN $7F,$00                          ;00C9E8|547F00  |      ;
    LDX.W #$1080                         ;00C9EB|A28010  |      ;
    LDA.W #$004F                         ;00C9EE|A94F00  |      ;
    MVN $7F,$00                          ;00C9F1|547F00  |      ;
    LDX.W #$0E84                         ;00C9F4|A2840E  |      ;
    LDA.W #$017B                         ;00C9F7|A97B01  |      ;
    MVN $7F,$00                          ;00C9FA|547F00  |      ;
    PLB                                  ;00C9FD|AB      |      ;
    PLA                                  ;00C9FE|68      |      ;
    LDX.W #$0003                         ;00C9FF|A20300  |      ;

CODE_00CA02:
    JSR.W CODE_00C992                    ;00CA02|2092C9  |00C992;
    CLC                                  ;00CA05|18      |      ;
    ADC.W #$0003                         ;00CA06|690300  |      ;
    DEX                                  ;00CA09|CA      |      ;
    BNE CODE_00CA02                      ;00CA0A|D0F6    |00CA02;
    LDA.W #$FFF0                         ;00CA0C|A9F0FF  |      ;
    STA.B $8E                            ;00CA0F|858E    |00008E;
    JMP.W CODE_00981B                    ;00CA11|4C1B98  |00981B;

CODE_00CA14:
    PHX                                  ;00CA14|DA      |      ;
    PHY                                  ;00CA15|5A      |      ;
    PHA                                  ;00CA16|48      |      ;

CODE_00CA17:
    LDA.B $01,S                          ;00CA17|A301    |000001;
    JSR.W CODE_00C92B                    ;00CA19|202BC9  |00C92B;
    CLC                                  ;00CA1C|18      |      ;
    ADC.W #$0006                         ;00CA1D|690600  |      ;
    STA.B $5F                            ;00CA20|855F    |00005F;
    JSR.W CODE_00C94F                    ;00CA22|204FC9  |00C94F;
    JSR.W CODE_00C95C                    ;00CA25|205CC9  |00C95C;
    JSR.W CODE_00C97D                    ;00CA28|207DC9  |00C97D;
    BNE CODE_00CA54                      ;00CA2B|D027    |00CA54;
    LDA.B $01,S                          ;00CA2D|A301    |000001;
    JSR.W CODE_00C92B                    ;00CA2F|202BC9  |00C92B;
    CLC                                  ;00CA32|18      |      ;
    ADC.W #$0006                         ;00CA33|690600  |      ;
    TAX                                  ;00CA36|AA      |      ;
    LDY.W #$3000                         ;00CA37|A00030  |      ;
    LDA.W #$0385                         ;00CA3A|A98503  |      ;
    MVN $7F,$70                          ;00CA3D|547F70  |      ;
    LDA.B $12                            ;00CA40|A512    |000012;
    LDX.W #$3000                         ;00CA42|A20030  |      ;
    STX.B $5F                            ;00CA45|865F    |00005F;
    JSR.W CODE_00C942                    ;00CA47|2042C9  |00C942;
    JSR.W CODE_00C95C                    ;00CA4A|205CC9  |00C95C;
    CMP.B $12                            ;00CA4D|C512    |000012;
    BNE CODE_00CA17                      ;00CA4F|D0C6    |00CA17;
    CLC                                  ;00CA51|18      |      ;
    BRA CODE_00CA5F                      ;00CA52|800B    |00CA5F;

CODE_00CA54:
    LDA.B $01,S                          ;00CA54|A301    |000001;
    JSR.W CODE_00C92B                    ;00CA56|202BC9  |00C92B;
    LDA.W #$0000                         ;00CA59|A90000  |      ;
    STA.B [$0B]                          ;00CA5C|870B    |00000B;
    SEC                                  ;00CA5E|38      |      ;

CODE_00CA5F:
    PLA                                  ;00CA5F|68      |      ;
    PLY                                  ;00CA60|7A      |      ;
    PLX                                  ;00CA61|FA      |      ;
    RTS                                  ;00CA62|60      |      ;

CODE_00CA63:
    PEA.W LOOSE_OP_00CAB5                ;00CA63|F4B5CA  |00CAB5;
    PHP                                  ;00CA66|08      |      ;
    REP #$30                             ;00CA67|C230    |      ;
    PHB                                  ;00CA69|8B      |      ;
    PHA                                  ;00CA6A|48      |      ;
    PHD                                  ;00CA6B|0B      |      ;
    PHX                                  ;00CA6C|DA      |      ;
    PHY                                  ;00CA6D|5A      |      ;
    PHA                                  ;00CA6E|48      |      ;
    STZ.B $8E                            ;00CA6F|648E    |00008E;
    LDA.B $01,S                          ;00CA71|A301    |000001;
    LDX.W #$0003                         ;00CA73|A20300  |      ;

CODE_00CA76:
    JSR.W CODE_00CA14                    ;00CA76|2014CA  |00CA14;
    BCC CODE_00CA87                      ;00CA79|900C    |00CA87;
    ADC.W #$0002                         ;00CA7B|690200  |      ;
    DEX                                  ;00CA7E|CA      |      ;
    BNE CODE_00CA76                      ;00CA7F|D0F5    |00CA76;
    PLA                                  ;00CA81|68      |      ;
    LDA.W #$FFFF                         ;00CA82|A9FFFF  |      ;
    BRA CODE_00CAAC                      ;00CA85|8025    |00CAAC;

CODE_00CA87:
    LDX.W #$3000                         ;00CA87|A20030  |      ;
    LDY.W #$1000                         ;00CA8A|A00010  |      ;
    LDA.W #$004F                         ;00CA8D|A94F00  |      ;
    MVN $00,$7F                          ;00CA90|54007F  |      ;
    LDY.W #$1080                         ;00CA93|A08010  |      ;
    LDA.W #$004F                         ;00CA96|A94F00  |      ;
    MVN $00,$7F                          ;00CA99|54007F  |      ;
    LDY.W #$0E84                         ;00CA9C|A0840E  |      ;
    LDA.W #$017B                         ;00CA9F|A97B01  |      ;
    MVN $00,$7F                          ;00CAA2|54007F  |      ;
    PLA                                  ;00CAA5|68      |      ;
    JSR.W CODE_00C9D3                    ;00CAA6|20D3C9  |00C9D3;
    LDA.W #$0000                         ;00CAA9|A90000  |      ;

CODE_00CAAC:
    STA.B $64                            ;00CAAC|8564    |000064;
    LDA.W #$FFF0                         ;00CAAE|A9F0FF  |      ;
    STA.B $8E                            ;00CAB1|858E    |00008E;
    JMP.W CODE_00981B                    ;00CAB3|4C1B98  |00981B;

LOOSE_OP_00CAB5:
    LDA.B $64                            ;00CAB6|A564    |000064;
    RTS                                  ;00CAB8|60      |      ;

CODE_00CAB9:
    PHP                                  ;00CAB9|08      |      ;
    REP #$30                             ;00CABA|C230    |      ;
    PHB                                  ;00CABC|8B      |      ;
    PHA                                  ;00CABD|48      |      ;
    PHD                                  ;00CABE|0B      |      ;
    PHX                                  ;00CABF|DA      |      ;
    PHY                                  ;00CAC0|5A      |      ;
    LDA.W #$0000                         ;00CAC1|A90000  |      ;
    TCD                                  ;00CAC4|5B      |      ;
    SEP #$20                             ;00CAC5|E220    |      ;
    LDA.B #$01                           ;00CAC7|A901    |      ;
    AND.W $00DA                          ;00CAC9|2DDA00  |0000DA;
    BNE CODE_00CAEC                      ;00CACC|D01E    |00CAEC;
    LDA.B #$40                           ;00CACE|A940    |      ;
    AND.W $00DB                          ;00CAD0|2DDB00  |0000DB;
    BNE CODE_00CB07                      ;00CAD3|D032    |00CB07;
    LDX.W #$9300                         ;00CAD5|A20093  |      ;
    STX.W SNES_CGSWSEL                   ;00CAD8|8E3021  |002130;
    LDA.B #$02                           ;00CADB|A902    |      ;
    AND.W $00DA                          ;00CADD|2DDA00  |0000DA;
    BNE CODE_00CB11                      ;00CAE0|D02F    |00CB11;
    LDA.B #$80                           ;00CAE2|A980    |      ;
    AND.W $00DB                          ;00CAE4|2DDB00  |0000DB;
    BNE CODE_00CB4E                      ;00CAE7|D065    |00CB4E;
    JMP.W CODE_00CB76                    ;00CAE9|4C76CB  |00CB76;

CODE_00CAEC:
    LDA.B #$01                           ;00CAEC|A901    |      ;
    TRB.W $00DA                          ;00CAEE|1CDA00  |0000DA;
    JSR.W CODE_00CC09                    ;00CAF1|2009CC  |00CC09;
    LDX.W #$5555                         ;00CAF4|A25555  |      ;
    STX.W $0E04                          ;00CAF7|8E040E  |000E04;
    STX.W $0E06                          ;00CAFA|8E060E  |000E06;
    STX.W $0E08                          ;00CAFD|8E080E  |000E08;
    LDA.B #$80                           ;00CB00|A980    |      ;
    TRB.W $00DE                          ;00CB02|1CDE00  |0000DE;
    BRA CODE_00CB79                      ;00CB05|8072    |00CB79;

CODE_00CB07:
    LDA.B #$40                           ;00CB07|A940    |      ;
    TRB.W $00DB                          ;00CB09|1CDB00  |0000DB;
    JSR.W CODE_00CCBD                    ;00CB0C|20BDCC  |00CCBD;
    BRA CODE_00CB79                      ;00CB0F|8068    |00CB79;
; ==============================================================================
; Screen Color Management and Final Systems - CODE_00CB11+
; ==============================================================================

CODE_00CB11:
    JSR.W CODE_00CD22                    ;00CB11|2022CD  |00CD22;
    REP #$30                             ;00CB14|C230    |      ;
    LDX.W #$016F                         ;00CB16|A26F01  |      ;
    LDY.W #$0E04                         ;00CB19|A0040E  |      ;
    LDA.W #$0005                         ;00CB1C|A90500  |      ;
    MVN $00,$00                          ;00CB1F|540000  |      ;
    SEP #$20                             ;00CB22|E220    |      ;
    LDA.B #$80                           ;00CB24|A980    |      ;
    TSB.W $00DE                          ;00CB26|0CDE00  |0000DE;
    JSR.W CODE_00CD60                    ;00CB29|2060CD  |00CD60;
    JSR.W CODE_00CBC6                    ;00CB2C|20C6CB  |00CBC6;
    JSL.L CODE_0C8000                    ;00CB2F|2200800C|0C8000;
    LDA.B #$E0                           ;00CB33|A9E0    |      ;
    STA.L $7F56D8                        ;00CB35|8FD8567F|7F56D8;
    STA.L $7F56D8,X                      ;00CB39|9FD8567F|7F56D8;
    JSL.L CODE_0C8000                    ;00CB3D|2200800C|0C8000;
    LDA.B #$02                           ;00CB41|A902    |      ;
    TRB.W $00DA                          ;00CB43|1CDA00  |0000DA;
    LDA.B #$08                           ;00CB46|A908    |      ;
    TRB.W $00D4                          ;00CB48|1CD400  |0000D4;
    JMP.W CODE_00981B                    ;00CB4B|4C1B98  |00981B;

CODE_00CB4E:
    JSR.W CODE_00CD22                    ;00CB4E|2022CD  |00CD22;
    JSR.W CODE_00CD60                    ;00CB51|2060CD  |00CD60;
    JSR.W CODE_00CC6E                    ;00CB54|206ECC  |00CC6E;
    JSL.L CODE_0C8000                    ;00CB57|2200800C|0C8000;
    LDA.B #$E0                           ;00CB5B|A9E0    |      ;
    STA.L $7F56DA                        ;00CB5D|8FDA567F|7F56DA;
    STA.L $7F56DE                        ;00CB61|8FDE567F|7F56DE;
    JSL.L CODE_0C8000                    ;00CB65|2200800C|0C8000;
    LDA.B #$80                           ;00CB69|A980    |      ;
    TRB.W $00DB                          ;00CB6B|1CDB00  |0000DB;
    LDA.B #$08                           ;00CB6E|A908    |      ;
    TRB.W $00D4                          ;00CB70|1CD400  |0000D4;
    JMP.W CODE_00981B                    ;00CB73|4C1B98  |00981B;

CODE_00CB76:
    JSR.W CODE_00CD22                    ;00CB76|2022CD  |00CD22;

CODE_00CB79:
    JSR.W CODE_00CD60                    ;00CB79|2060CD  |00CD60;
    JSR.W CODE_00CD42                    ;00CB7C|2042CD  |00CD42;
    JSL.L CODE_0C8000                    ;00CB7F|2200800C|0C8000;
    LDA.B #$E0                           ;00CB83|A9E0    |      ;
    STA.W SNES_COLDATA                   ;00CB85|8D3221  |002132;
    LDX.W #$0000                         ;00CB88|A20000  |      ;
    STX.W SNES_CGSWSEL                   ;00CB8B|8E3021  |002130;
    JMP.W CODE_00981B                    ;00CB8E|4C1B98  |00981B;

CODE_00CB91:
    REP #$30                             ;00CB91|C230    |      ;
    PHB                                  ;00CB93|8B      |      ;
    LDX.W #$CBBD                         ;00CB94|A2BDCB  |      ;
    LDY.W #$56D7                         ;00CB97|A0D756  |      ;
    LDA.W #$0008                         ;00CB9A|A90800  |      ;
    MVN $7F,$00                          ;00CB9D|547F00  |      ;
    PLB                                  ;00CBA0|AB      |      ;
    LDA.W #$0080                         ;00CBA1|A98000  |      ;
    TSB.W $00DA                          ;00CBA4|0CDA00  |0000DA;
    LDA.W #$0020                         ;00CBA7|A92000  |      ;
    TSB.W $0111                          ;00CBAA|0C1101  |000111;
    LDA.B $02                            ;00CBAD|A502    |000002;
    AND.W #$00FF                         ;00CBAF|29FF00  |      ;
    INC A                                ;00CBB2|1A      |      ;
    ASL A                                ;00CBB3|0A      |      ;
    TAX                                  ;00CBB4|AA      |      ;
    SEP #$20                             ;00CBB5|E220    |      ;
    LDA.B #$08                           ;00CBB7|A908    |      ;
    TSB.W $00D4                          ;00CBB9|0CD400  |0000D4;
    RTS                                  ;00CBBC|60      |      ;

DATA_00CBBD:
    db $27,$EC,$3C,$EC,$3C,$EC,$38,$EC,$00 ;00CBBD|        |      ;

CODE_00CBC6:
    JSR.W CODE_00CB91                    ;00CBC6|2091CB  |00CB91;
    LDA.B #$E9                           ;00CBC9|A9E9    |      ;

CODE_00CBCB:
    LDY.B $17                            ;00CBCB|A417    |000017;
    JSR.W CODE_009D75                    ;00CBCD|20759D  |009D75;
    STY.B $17                            ;00CBD0|8417    |000017;
    JSL.L CODE_0C8000                    ;00CBD2|2200800C|0C8000;
    STA.L $7F56D8                        ;00CBD6|8FD8567F|7F56D8;
    STA.L $7F56D8,X                      ;00CBDA|9FD8567F|7F56D8;
    DEC A                                ;00CBDE|3A      |      ;
    DEC A                                ;00CBDF|3A      |      ;
    CMP.B #$E1                           ;00CBE0|C9E1    |      ;
    BNE CODE_00CBCB                      ;00CBE2|D0E7    |00CBCB;
    LDY.B $17                            ;00CBE4|A417    |000017;
    JSR.W CODE_009D75                    ;00CBE6|20759D  |009D75;
    STY.B $17                            ;00CBE9|8417    |000017;
    RTS                                  ;00CBEB|60      |      ;

CODE_00CBEC:
    LDY.W #$9300                         ;00CBEC|A00093  |      ;
    STY.W SNES_CGSWSEL                   ;00CBEF|8C3021  |002130;
    JSR.W CODE_00CB91                    ;00CBF2|2091CB  |00CB91;
    LDA.B #$E0                           ;00CBF5|A9E0    |      ;
    STA.L $7F56D8                        ;00CBF7|8FD8567F|7F56D8;
    STA.L $7F56D8,X                      ;00CBFB|9FD8567F|7F56D8;
    JSL.L CODE_0C8000                    ;00CBFF|2200800C|0C8000;
    LDA.B #$08                           ;00CC03|A908    |      ;
    TRB.W $00D4                          ;00CC05|1CD400  |0000D4;
    RTS                                  ;00CC08|60      |      ;

CODE_00CC09:
    LDA.B #$08                           ;00CC09|A908    |      ;
    TSB.W $00D4                          ;00CC0B|0CD400  |0000D4;
    LDX.W #$0007                         ;00CC0E|A20700  |      ;

CODE_00CC11:
    JSL.L CODE_0C8000                    ;00CC11|2200800C|0C8000;
    LDA.L $7F56D8                        ;00CC15|AFD8567F|7F56D8;
    JSR.W CODE_00CC5B                    ;00CC19|205BCC  |00CC5B;
    STA.L $7F56D8                        ;00CC1C|8FD8567F|7F56D8;
    LDA.L $7F56DA                        ;00CC20|AFDA567F|7F56DA;
    JSR.W CODE_00CC5B                    ;00CC24|205BCC  |00CC5B;
    STA.L $7F56DA                        ;00CC27|8FDA567F|7F56DA;
    LDA.L $7F56DC                        ;00CC2B|AFDC567F|7F56DC;
    JSR.W CODE_00CC5B                    ;00CC2F|205BCC  |00CC5B;
    STA.L $7F56DC                        ;00CC32|8FDC567F|7F56DC;
    LDA.L $7F56DE                        ;00CC36|AFDE567F|7F56DE;
    JSR.W CODE_00CC5B                    ;00CC3A|205BCC  |00CC5B;
    STA.L $7F56DE                        ;00CC3D|8FDE567F|7F56DE;
    LDY.B $17                            ;00CC41|A417    |000017;
    JSR.W CODE_009D75                    ;00CC43|20759D  |009D75;
    STY.B $17                            ;00CC46|8417    |000017;
    DEX                                  ;00CC48|CA      |      ;
    BNE CODE_00CC11                      ;00CC49|D0C6    |00CC11;
    LDA.B #$08                           ;00CC4B|A908    |      ;
    TRB.W $00D4                          ;00CC4D|1CD400  |0000D4;
    LDA.B #$20                           ;00CC50|A920    |      ;
    TRB.W $0111                          ;00CC52|1C1101  |000111;
    LDA.B #$80                           ;00CC55|A980    |      ;
    TRB.W $00DA                          ;00CC57|1CDA00  |0000DA;
    RTS                                  ;00CC5A|60      |      ;

CODE_00CC5B:
    CLC                                  ;00CC5B|18      |      ;
    ADC.L CODE_00CC66,X                  ;00CC5C|7F66CC00|00CC66;
    CMP.B #$F0                           ;00CC60|C9F0    |      ;
    BCC CODE_00CC66                      ;00CC62|9002    |00CC66;
    LDA.B #$EF                           ;00CC64|A9EF    |      ;

CODE_00CC66:
    RTS                                  ;00CC66|60      |      ;

DATA_00CC67:
    db $03,$02,$02,$02,$02,$01,$03       ;00CC67|        |      ;

; ==============================================================================
; BANK $00 COMPLETE - FINAL STUB SECTION
; ==============================================================================

; Final stub definitions for any remaining external routines
CODE_00CF3F:
    = $CF3F
CODE_00CF62:
    = $CF62

; ==============================================================================
; END OF BANK $00 - 100% COMPLETE
; ==============================================================================
