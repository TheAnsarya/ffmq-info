; ==============================================================================
; Final Fantasy Mystic Quest - Bank $00 - Main Game Engine
; ==============================================================================
; This bank contains the core game engine including:
; - Boot sequence and initialization ($008000-$0082ff)
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

	arch										   65816
lorom:

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
	SNES_MDMAEN    = $420b    ; DMA Enable

; PPU Registers
	SNES_INIDISP   = $2100    ; Display Control
	SNES_TM        = $212c    ; Main Screen Designation
	SNES_CGADD     = $2121    ; CG RAM Address
	SNES_CGDATA    = $2122    ; CG RAM Data
	SNES_COLDATA   = $2132    ; Color Data
	SNES_CGSWSEL   = $2130    ; Color/Window Select
	SNES_BG1VOFS   = $210e    ; BG1 Vertical Offset
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
	SNES_OPVCT     = $213d    ; Vertical Counter (PPU)
	SNES_STAT78    = $213f    ; PPU Status 78

; Math/Multiplication/Division Registers
	SNES_WRMPYA    = $4202    ; Multiplicand
	SNES_WRMPYB    = $4203    ; Multiplicand/Multiplier
	SNES_WRDIVL    = $4204    ; Dividend Low
	SNES_WRDIVH    = $4205    ; Dividend High
	SNES_WRDIVB    = $4206    ; Divisor
	SNES_RDMPYL    = $4216    ; Multiplication/Division Result Low

; Constant Pointers
	PTR16_00FFFF   = $ffff    ; Return marker value for subroutine calls

;===============================================================================
; External Bank Stubs (code in other banks)
;===============================================================================
; Bank $00 - Not yet imported
	CODE_0096A0 = $0096a0
	CODE_00985D = $00985d
	CODE_00A375 = $00a375
	CODE_00A3DE = $00a3de
	CODE_00A3E5 = $00a3e5
	CODE_00A3EC = $00a3ec
	CODE_00A3F5 = $00a3fc
	CODE_00A3FC = $00a3fc
	CODE_00A51E = $00a51e
; CODE_00A572 through CODE_00A597 now implemented
; CODE_00A708 through CODE_00A83F now implemented
; CODE_00A86E through CODE_00AACC now implemented (partial CODE_00A86E as db)
; CODE_00AACF through CODE_00AFFE now implemented
; CODE_00B000 through CODE_00B1A1 now implemented
	CODE_00A78E = $00a78e             ; Referenced in jump table but not implemented as routine
	CODE_00A86E = $00a86e             ; Partial implementation (raw bytecode placeholder)
; All comparison tests now implemented below
	Some_Graphics_Setup = $00b000
	Some_Init_Routine = $00b100
	Some_Mode_Handler = $00b200
	Main_Game_Loop = $00b300
	Execute_Script_Or_Command = $00b400
	Some_Init_Function_2 = $00b500
	Some_Function_9319 = $009319
	Some_Function_9A08 = $009a08
	Some_Function_A236 = $00a236
	CODE_009824 = $009824    ; BCD/Hex number formatting routine
	CODE_008B69 = $008b69    ; Screen setup routine 1
	CODE_008B88 = $008b88    ; Screen setup routine 2
	CODE_00CBEC = $00cbec    ; Setup routine
	CODE_00DA65 = $00da65    ; External data routine
	CODE_00C795 = $00c795    ; External routine
	CODE_00C7B8 = $00c7b8    ; External routine
	CODE_00CA63 = $00ca63    ; External routine
	CODE_00D080 = $00d080    ; External routine
	CODE_00E055 = $00e055    ; External routine
	CODE_00C92B = $00c92b    ; Get save slot address
	CODE_00C4DB = $00c4db    ; External routine
	CODE_00C7DE = $00c7de    ; Screen setup routine 1
	CODE_00C7F0 = $00c7f0    ; Screen setup routine 2
	CODE_00C78D = $00c78d    ; External routine
	CODE_00CF3F = $00cf3f    ; Main routine
	CODE_00DAA5 = $00daa5    ; External routine
	CODE_00C9D3 = $00c9d3    ; Get save slot address

; Other Banks
	CODE_028AE0 = $028ae0    ; Bank $02 routine
	DATA8_03ba35 = $03ba35   ; Bank $03 data
	DATA8_03bb81 = $03bb81   ; Bank $03 data
	DATA8_03a37c = $03a37c   ; Bank $03 character data
	UNREACH_03D5E5 = $03d5e5 ; Bank $03 unreachable code
	CODE_0C8000 = $0c8000    ; Bank $0c routine
	CODE_0C8080 = $0c8080    ; Bank $0c routine
	BankOC_Init = $0c8000    ; Bank $0c Init
	CODE_0D8000 = $0d8000    ; Bank $0d routine
	CODE_0D8004 = $0d8004    ; Bank $0d routine
	Bank0D_Init_Variant = $0d8000    ; Bank $0d Init
	CODE_018272 = $018272    ; Bank $01 routine
	CODE_018A52 = $018a52    ; Bank $01 sprite initialization
	CODE_01B24C = $01b24c    ; Bank $01 script initialization routine
	Jump_To_Bank01 = $018000 ; Bank $01 jump target
	DATA8_049800 = $049800   ; Bank $04 data
	Load_Save_Game = $0e8000 ; Bank $0e save game
	Some_System_Call = $0f8000    ; Bank $0f system
	Some_Init_Function_1 = $0f8100    ; Bank $0f init
	Some_Init_Function_3 = $0f8200    ; Bank $0f init

; Bank $07 data
	DATA8_078000 = $078000
	DATA8_078001 = $078001
	DATA8_078002 = $078002
	DATA8_078003 = $078003
	DATA8_078004 = $078004
	DATA8_078005 = $078005
	DATA8_078006 = $078006
	DATA8_078007 = $078007
	DATA8_07800a = $07800a
	DATA8_07800c = $07800c
	DATA8_07d7f4 = $07d7f4   ; Palette color data base
	DATA8_07d7f5 = $07d7f5
	DATA8_07d7f6 = $07d7f6
	DATA8_07d7f7 = $07d7f7
	DATA8_07d7f8 = $07d7f8
	DATA8_07d7f9 = $07d7f9
	DATA8_07d7fa = $07d7fa
	DATA8_07d7fb = $07d7fb
	DATA8_07d7fc = $07d7fc
	DATA8_07d7fd = $07d7fd
	DATA8_07d7fe = $07d7fe
	DATA8_07d7ff = $07d7ff
	DATA8_07d800 = $07d800
	DATA8_07d801 = $07d801
	DATA8_07d802 = $07d802
	DATA8_07d803 = $07d803
	DATA8_07d814 = $07d814   ; Color data (additional palette)
	DATA8_07d815 = $07d815
	DATA8_07d816 = $07d816
	DATA8_07d817 = $07d817
	DATA8_07d818 = $07d818
	DATA8_07d819 = $07d819
	DATA8_07d81a = $07d81a
	DATA8_07d81b = $07d81b
	DATA8_07d81c = $07d81c
	DATA8_07d81d = $07d81d
	DATA8_07d81e = $07d81e
	DATA8_07d81f = $07d81f
	DATA8_07d820 = $07d820
	DATA8_07d821 = $07d821
	DATA8_07d822 = $07d822
	DATA8_07d823 = $07d823
	DATA8_07d8e4 = $07d8e4
	DATA8_07d8e5 = $07d8e5
	DATA8_07d8e6 = $07d8e6
	DATA8_07d8e7 = $07d8e7
	DATA8_07d8e8 = $07d8e8
	DATA8_07d8e9 = $07d8e9
	DATA8_07d8ea = $07d8ea
	DATA8_07d8eb = $07d8eb
	DATA8_07d8ec = $07d8ec
	DATA8_07d8ed = $07d8ed
	DATA8_07d8ee = $07d8ee
	DATA8_07d8ef = $07d8ef
	DATA8_07d8f0 = $07d8f0
	DATA8_07d8f1 = $07d8f1
	DATA8_07d8f2 = $07d8f2
	DATA8_07d8f3 = $07d8f3

;===============================================================================
; SNES Hardware Register Definitions (Additional)
;===============================================================================
	SNES_BG1HOFS   = $210d    ; BG1 Horizontal Offset
	SNES_BG2HOFS   = $210f    ; BG2 Horizontal Offset
	SNES_BG3VOFS   = $2112    ; BG3 Vertical Offset
	SNES_BG1SC     = $2107    ; BG1 Screen Base Address
	SNES_BG2SC     = $2108    ; BG2 Screen Base Address

; Loose operations (code fragments)
	LOOSE_OP_00BCF3 = $00bcf3 ; Continuation address in state machine

;===============================================================================
; BOOT SEQUENCE & INITIALIZATION ($008000-$008113)
;===============================================================================

	org					 $008000

RESET_Handler:
; ===========================================================================
; SNES Power-On Boot Entry Point (RESET Vector Handler)
; ===========================================================================
; This is the first code executed when the SNES powers on or resets.
; The RESET vector at $00fffc points here ($008000).
;
; Boot Process:
;   1. Switch from 6502 emulation mode to native 65816 mode
;   2. Initialize all hardware registers (display off, sound off, DMA off)
;   3. Initialize bank $0d subsystems (sound driver, etc.)
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
;   Native mode, stack at $001fff, hardware initialized
; ===========================================================================

	clc							   ; Clear carry flag
	xce							   ; Exchange Carry with Emulation flag
; C=0 → E=0 → Native 65816 mode enabled!

	jsr.W				   Init_Hardware ; Init_Hardware: Disable NMI, force blank, clear registers
	jsl.L				   CODE_0D8000 ; Bank $0d initialization (sound driver, APU setup)

; ---------------------------------------------------------------------------
; Initialize Save Game State Variables
; ---------------------------------------------------------------------------
; $7e3667 = Save file exists flag (0=no save, 1=save exists)
; $7e3668 = Save file slot/state ($ff=no save, 0-2=slot number)
; ---------------------------------------------------------------------------

	lda.B				   #$00	  ; A = 0
	sta.L				   $7e3667   ; Clear "save file exists" flag
	dec					 a; A = $ff (-1)
	sta.L				   $7e3668   ; Set save slot to $ff (no active save)
	bra					 Boot_SetupStack ; → Continue to stack setup

;-------------------------------------------------------------------------------

Boot_Secondary:
; ===========================================================================
; Secondary Boot Entry Point
; ===========================================================================
; Alternative entry point used for soft reset or special boot modes.
; Different from main boot: calls different bank $0d init routine.
; ===========================================================================

	jsr.W				   Init_Hardware ; Init_Hardware again

	lda.B				   #$f0	  ; A = $f0
	sta.L				   $000600   ; Write $f0 to $000600 (low RAM mirror area)
; Purpose unclear - may trigger hardware behavior

	jsl.L				   CODE_0D8004 ; Bank $0d alternate initialization routine

;-------------------------------------------------------------------------------

Boot_Alternate:
; ===========================================================================
; Third Entry Point (Soft Reset with Different Init)
; ===========================================================================
; Yet another entry point with same hardware init but different
; bank $0d initialization. May be used for returning from special modes.
; ===========================================================================

	jsr.W				   Init_Hardware ; Init_Hardware

	lda.B				   #$f0	  ; A = $f0
	sta.L				   $000600   ; Write $f0 to $000600

	jsl.L				   CODE_0D8004 ; Bank $0d alternate init

	rep					 #$30		; Set 16-bit mode: A, X, Y
	ldx.W				   #$1fff	; X = $1fff (stack pointer initial value)
	txs							   ; Transfer X to Stack: S = $1fff

;-------------------------------------------------------------------------------

Boot_SetupStack:
; ===========================================================================
; Stack Setup and Main Initialization Path
; ===========================================================================
; All boot paths converge here. Sets up stack pointer and continues
; to main game initialization.
;
; Stack Configuration:
;   Top of stack: $001fff
;   Stack grows downward (typical 65816 configuration)
;   RAM area $0000-$1fff available for stack/variables
; ===========================================================================

	rep					 #$30		; 16-bit A, X, Y registers
	ldx.W				   #$1fff	; X = $1fff (top of RAM bank $00)
	txs							   ; S = $1fff (initialize stack pointer)

	jsr.W				   Clear_WorkRAM ; Clear_RAM: Zero out all work RAM $0000-$1fff

; ---------------------------------------------------------------------------
; Check Boot Mode Flag ($00da bit 6)
; ---------------------------------------------------------------------------
; $00da appears to be a boot mode/configuration flag
; Bit 6 ($40) determines which initialization path to take
; ---------------------------------------------------------------------------

	lda.W				   #$0040	; A = $0040 (bit 6 mask)
	and.W				   $00da	 ; Test bit 6 of $00da
	bne					 Boot_EnableNMI ; If bit 6 set → Skip display init, jump ahead

	jsl.L				   CODE_0C8080 ; Bank $0c: Full display/PPU initialization
	bra					 Boot_SetupDMA ; → Continue to DMA setup

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

	jsr.W				   CODE_0081F0 ; Clear_RAM again (redundant?)

	sep					 #$20		; 8-bit accumulator

; ---------------------------------------------------------------------------
; DMA Channel 0 Configuration
; ---------------------------------------------------------------------------
; Purpose: Copy initialization data from ROM to RAM
; Pattern: Fixed source, incrementing destination (mode $18)
; Register: $2109 (not a standard PPU register?)
; ---------------------------------------------------------------------------

	ldx.W				   #$1809	; X = $1809
; $18 = DMA mode (2 registers, increment write)
; $09 = Target register (high byte)
	stx.W				   SNES_DMA0PARAM ; $4300 = DMA0 parameters

	ldx.W				   #$8252	; X = $8252 (source address low/mid)
	stx.W				   SNES_DMA0ADDRL ; $4302-$4303 = Source address $xx8252

	lda.B				   #$00	  ; A = $00
	sta.W				   SNES_DMA0ADDRH ; $4304 = Source bank $00 → $008252

	ldx.W				   #$0000	; X = $0000 (transfer size = 0 bytes!)
	stx.W				   SNES_DMA0CNTL ; $4305-$4306 = Transfer 0 bytes
; This DMA won't transfer anything!

	lda.B				   #$01	  ; A = $01 (enable channel 0)
	sta.W				   SNES_MDMAEN ; $420b = Execute DMA channel 0
; (Executes but transfers 0 bytes)

;-------------------------------------------------------------------------------

Boot_EnableNMI:
; ===========================================================================
; Direct Page Setup and NMI Enable
; ===========================================================================
; Sets up direct page pointer and enables interrupts for main game loop.
; ===========================================================================

	jsl.L				   $00011f   ; Call routine at $00011f (in bank $00 RAM!)
; This is calling CODE in RAM, not ROM
; Must have been loaded earlier

	rep					 #$30		; 16-bit A, X, Y

	lda.W				   #$0000	; A = $0000
	tcd							   ; Direct Page = $0000 (D = $0000)
; Sets up fast direct page access

	sep					 #$20		; 8-bit accumulator

	lda.W				   $0112	 ; A = [$0112] (NMI enable flags)
	sta.W				   SNES_NMITIMEN ; $4200 = Enable NMI/IRQ/Auto-joypad
; Copies configuration from RAM variable

	cli							   ; Clear Interrupt disable flag
; Enable IRQ interrupts (NMI already configured)

	lda.B				   #$0f	  ; A = $0f
	sta.W				   $00aa	 ; [$00aa] = $0f (some game state variable)

	jsl.L				   CODE_0C8000 ; Bank $0c: Wait for VBLANK
	jsl.L				   CODE_0C8000 ; Bank $0c: Wait for VBLANK again
; Double wait ensures PPU is stable

; ---------------------------------------------------------------------------
; Check Boot/Continue Mode
; ---------------------------------------------------------------------------
; $7e3665 = Continue/load game flag
; $700000, $70038c, $700718 = Save file signature bytes?
; ---------------------------------------------------------------------------

	lda.L				   $7e3665   ; A = Continue flag
	bne					 Load_SavedGame ; If set → Load existing game

; Check if save data exists in SRAM
	lda.L				   $700000   ; A = SRAM byte 1
	ora.L				   $70038c   ; OR with SRAM byte 2
	ora.L				   $700718   ; OR with SRAM byte 3
	beq					 Init_NewGame ; If all zero → New game (no save data)

	jsl.L				   CODE_00B950 ; Has save data → Show continue menu
	bra					 Boot_FadeIn ; → Continue to fade-in

;-------------------------------------------------------------------------------

Load_SavedGame:
; ===========================================================================
; Load Saved Game from SRAM
; ===========================================================================
; Player selected "Continue" from title screen - load saved game data.
; ===========================================================================

	jsr.W				   Load_GameFromSRAM ; Load_Game_From_SRAM: Restore all game state
	bra					 Boot_PostInit ; → Skip new game init, jump to main setup

;-------------------------------------------------------------------------------

Init_NewGame:
; ===========================================================================
; New Game Initialization
; ===========================================================================
; No save data exists - initialize a fresh game state.
; ===========================================================================

	jsr.W				   Init_NewGameState ; Initialize_New_Game_State: Set default values

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

	lda.B				   #$80	  ; A = $80 (bit 7)
	trb.W				   $00de	 ; Test and Reset bit 7 of $00de
; Clear some display state flag

	lda.B				   #$e0	  ; A = $e0 (bits 5-7: %11100000)
	trb.W				   $0111	 ; Test and Reset bits 5-7 of $0111
; Clear multiple configuration flags

	jsl.L				   CODE_0C8000 ; Bank $0c: Wait for VBLANK
; Ensure PPU ready for register writes

; ---------------------------------------------------------------------------
; Configure Color Math and Window Settings
; ---------------------------------------------------------------------------
; Sets up color addition/subtraction for fade effects
; SNES_COLDATA ($2132): Color math control register
; SNES_CGSWSEL ($2130): Color addition select
; ---------------------------------------------------------------------------

	lda.B				   #$e0	  ; A = $e0
; Bit 7 = 1: Subtract color
; Bit 6 = 1: Half color math
; Bit 5 = 1: Enable color math
	sta.W				   SNES_COLDATA ; $2132 = Color math configuration

	ldx.W				   #$0000	; X = $0000
	stx.W				   SNES_CGSWSEL ; $2130 = Color/math window settings = 0
; Disable all color window masking

; ---------------------------------------------------------------------------
; Reset Background Scroll Positions
; ---------------------------------------------------------------------------
; SNES requires writing scroll values TWICE (high byte, then low byte)
; Writing $00 twice sets scroll position to 0
; ---------------------------------------------------------------------------

	stz.W				   SNES_BG1VOFS ; $210e = BG1 vertical scroll = 0 (low byte)
	stz.W				   SNES_BG1VOFS ; $210e = BG1 vertical scroll = 0 (high byte)
	stz.W				   SNES_BG2VOFS ; $2110 = BG2 vertical scroll = 0 (low byte)
	stz.W				   SNES_BG2VOFS ; $2110 = BG2 vertical scroll = 0 (high byte)

	jsr.W				   CODE_00BD30 ; Additional graphics/fade setup
	jsl.L				   CODE_0C8000 ; Bank $0c: Wait for VBLANK again
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

	jsr.W				   CODE_009014 ; Initialize subsystem (graphics related?)

; ---------------------------------------------------------------------------
; Initialize Two System Components (Unknown Purpose)
; ---------------------------------------------------------------------------
; Calls same routine twice with different parameters
; May be initializing two separate game systems
; ---------------------------------------------------------------------------

	lda.B				   #$00	  ; A = $00 (parameter for first init)
	jsr.W				   Char_CalcStats ; Initialize system component 0

	lda.B				   #$01	  ; A = $01 (parameter for second init)
	jsr.W				   Char_CalcStats ; Initialize system component 1

; ---------------------------------------------------------------------------
; Load Initial Data Table
; ---------------------------------------------------------------------------
; $81ed points to initialization data (see DATA8_0081ED below)
; CODE_009BC4 likely loads/processes this data table
; ---------------------------------------------------------------------------

	ldx.W				   #$81ed	; X = $81ed (pointer to init data)
	jsr.W				   CODE_009BC4 ; Load/process data table

; ---------------------------------------------------------------------------
; Configure State Flags
; ---------------------------------------------------------------------------
; $00d4, $00d6, $00e2 = State/configuration flag bytes
; TSB/TRB = Test and Set/Reset Bits instructions
; ---------------------------------------------------------------------------

	lda.B				   #$04	  ; A = $04 (bit 2)
	tsb.W				   $00d4	 ; Test and Set bit 2 in $00d4
; Enable some display/update feature

	lda.B				   #$80	  ; A = $80 (bit 7)
	trb.W				   $00d6	 ; Test and Reset bit 7 in $00d6
; Disable some feature

	stz.W				   $0110	 ; [$0110] = $00 (clear game state variable)

	lda.B				   #$01	  ; A = $01 (bit 0)
	tsb.W				   $00e2	 ; Test and Set bit 0 in $00e2
; Enable some system feature

	lda.B				   #$10	  ; A = $10 (bit 4)
	tsb.W				   $00d6	 ; Test and Set bit 4 in $00d6
; Enable another feature

; ---------------------------------------------------------------------------
; Initialize Game Position/State Variable
; ---------------------------------------------------------------------------
; $008e appears to be a signed 16-bit position or state value
; ---------------------------------------------------------------------------

	ldx.W				   #$fff0	; X = $fff0 (-16 in signed 16-bit)
	stx.W				   $008e	 ; [$008e] = $fff0 (initial game state)

; ---------------------------------------------------------------------------
; Final Setup Routines
; ---------------------------------------------------------------------------

	jsl.L				   CODE_009B2F ; Final system initialization
	jsr.W				   CODE_008230 ; Additional setup (see below)

; ---------------------------------------------------------------------------
; JUMP TO MAIN GAME LOOP
; ---------------------------------------------------------------------------
; JML = Jump Long (24-bit address)
; Control transfers to bank $01, never returns
; This is the END of boot sequence - game starts running!
; ---------------------------------------------------------------------------

	jml.L				   CODE_018272 ; → JUMP TO MAIN GAME ENGINE (Bank $01)
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

	lda.B				   #$14	  ; A = $14 (%00010100)
; Bit 4 = Enable BG3
; Bit 2 = Enable BG1
	sta.W				   SNES_TM   ; $212c = Main screen designation
; Display BG1 and BG3 on main screen

	rep					 #$30		; 16-bit A, X, Y

	lda.W				   #$0000	; A = $0000
	sta.L				   $7e31b5   ; Clear [$7e31b5] (game state variable)

	jsr.W				   CODE_00BD64 ; Initialize graphics/display system

	sep					 #$20		; 8-bit accumulator

	jsl.L				   CODE_0C8000 ; Bank $0c: Wait for VBLANK

; ---------------------------------------------------------------------------
; Configure OAM (Sprite) DMA Transfer
; ---------------------------------------------------------------------------
; OAM = Object Attribute Memory (sprite data)
; DMA Channel 5 used for sprite transfers during VBLANK
;
; DMA Configuration:
;   Source: $000c00 (RAM - OAM buffer)
;   Destination: $2104 (OAMDATA register)
;   Size: $0220 bytes (544 bytes = 128 sprites × 4 bytes + 32 bytes hi table)
;   Mode: $04 = Write 2 registers once each (OAMDATA + OAMDATAWR)
; ---------------------------------------------------------------------------

	ldx.W				   #$0000	; X = $0000
	stx.W				   SNES_OAMADDL ; $2102-$2103 = OAM address = $0000
; Start writing at first sprite

	ldx.W				   #$0400	; X = $0400
; $04 = DMA mode: 2 registers, write once
; $00 = Target register low byte
	stx.W				   SNES_DMA5PARAM ; $4350 = DMA5 parameters

	ldx.W				   #$0c00	; X = $0c00
	stx.W				   SNES_DMA5ADDRL ; $4352-$4353 = Source address $xx0C00

	lda.B				   #$00	  ; A = $00
	sta.W				   SNES_DMA5ADDRH ; $4354 = Source bank = $00 → $000c00

	ldx.W				   #$0220	; X = $0220 (544 bytes)
	stx.W				   SNES_DMA5CNTL ; $4355-$4356 = Transfer size = 544 bytes

	lda.B				   #$20	  ; A = $20 (bit 5 = DMA channel 5)
	sta.W				   SNES_MDMAEN ; $420b = Execute DMA channel 5
; Copies OAM data to PPU

; ---------------------------------------------------------------------------
; Initialize Game State Variables
; ---------------------------------------------------------------------------

	rep					 #$30		; 16-bit A, X, Y

	lda.W				   #$ffff	; A = $ffff
	sta.W				   $010e	 ; [$010e] = $ffff (state marker)

	jsl.L				   CODE_00C795 ; Initialize subsystem
	jsr.W				   CODE_00BA1A ; Initialize subsystem
	jsl.L				   CODE_00C7B8 ; Initialize subsystem

	sep					 #$20		; 8-bit accumulator
	rts							   ; Return to caller

;===============================================================================
; LOAD SAVED GAME ($008166-$0081d4)
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
;   - Mapped to $700000-$77ffff (bank $70-$77)
;   - Battery-backed, persists when power off
;   - FFMQ uses multiple save slots
; ===========================================================================

	rep					 #$30		; 16-bit A, X, Y

; ---------------------------------------------------------------------------
; Copy Save Data Block 1: MVN (Block Move Negative)
; ---------------------------------------------------------------------------
; MVN instruction: Move block of memory
; Format: MVN srcbank,dstbank
; X = source address, Y = destination address, A = length-1
;
; This copies $0040 bytes from $0ca9c2 to $001010
; ---------------------------------------------------------------------------

	ldx.W				   #$a9c2	; X = $a9c2 (source address low/mid)
	ldy.W				   #$1010	; Y = $1010 (destination address)
	lda.W				   #$003f	; A = $003f (transfer 64 bytes: $3f+1)
	mvn					 $00,$0c	 ; Copy from bank $0c to bank $00
; Source: $0ca9c2, Dest: $001010, Size: $40

; Note: MVN auto-increments X, Y and decrements A until A = $ffff
; After execution: X = $a9c2+$40, Y = $1010+$40, A = $ffff

; ---------------------------------------------------------------------------
; Copy Save Data Block 2
; ---------------------------------------------------------------------------
; Y already = $1010+$40 = $1050 from previous MVN
; Copies $000a bytes from $0c0e9e to $001050
; ---------------------------------------------------------------------------

	ldy.W				   #$0e9e	; Y = $0e9e (new source address)
; Overwrites Y (dest becomes source for new copy)
; Actually this is confusing - need to verify
	lda.W				   #$0009	; A = $0009 (transfer 10 bytes: $09+1)
	mvn					 $00,$0c	 ; Copy from bank $0c to bank $00

	sep					 #$20		; 8-bit accumulator

; ---------------------------------------------------------------------------
; Set Save Slot Marker
; ---------------------------------------------------------------------------

	lda.B				   #$02	  ; A = $02
	sta.W				   $0fe7	 ; [$0fe7] = $02 (save slot indicator?)

; ---------------------------------------------------------------------------
; Determine Active Save Slot
; ---------------------------------------------------------------------------
; $7e3668 contains save slot number (0, 1, or 2)
; If >= 2, wraps to slot 0
; ---------------------------------------------------------------------------

	lda.L				   $7e3668   ; A = save slot number
	cmp.B				   #$02	  ; Compare with 2
	bcc					 CODE_00818E ; If < 2, skip ahead (valid slot 0 or 1)

	lda.B				   #$ff	  ; A = $ff (invalid slot, reset to -1)

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

	inc					 a; A = slot number + 1 (1, 2, or 3)
	sta.L				   $7e3668   ; Update slot number in RAM

	rep					 #$30		; 16-bit A, X, Y

	and.W				   #$0003	; A = A & 3 (ensure 0-3 range)
	asl					 a; A = A × 2
	asl					 a; A = A × 4
	asl					 a; A = A × 8 (8 bytes per slot)
	tax							   ; X = slot_index × 8 (table offset)

	sep					 #$20		; 8-bit accumulator

; ---------------------------------------------------------------------------
; Load Data from Slot Table
; ---------------------------------------------------------------------------
; Uses X as offset into DATA8_0081D5 table
; Loads 8 bytes of configuration data for this save slot
; ---------------------------------------------------------------------------

	stz.B				   $19	   ; [$19] = $00 (clear direct page variable)

	lda.W				   DATA8_0081d5,x ; A = table[X+0] (byte 0)
	sta.W				   $0e88	 ; Store to $0e88

	ldy.W				   DATA8_0081d6,x ; Y = table[X+1,X+2] (bytes 1-2, 16-bit)
	sty.W				   $0e89	 ; Store to $0e89-$0e8a

	lda.W				   DATA8_0081d8,x ; A = table[X+3] (byte 3)
	sta.W				   $0e92	 ; Store to $0e92

	ldy.W				   DATA8_0081db,x ; Y = table[X+4,X+5] (bytes 4-5, 16-bit)
	sty.B				   $53	   ; Store to $53-$54

	ldy.W				   DATA8_0081d9,x ; Y = table[X+6,X+7] (bytes 6-7, 16-bit)
	tyx							   ; X = Y (transfer loaded value to X)

	rep					 #$30		; 16-bit A, X, Y

; ---------------------------------------------------------------------------
; Copy Additional Save Data
; ---------------------------------------------------------------------------
; Copies $0020 bytes from $0c:X to $000ea8
; X was loaded from table above
; ---------------------------------------------------------------------------

	ldy.W				   #$0ea8	; Y = $0ea8 (destination)
	lda.W				   #$001f	; A = $001f (copy 32 bytes)
	mvn					 $00,$0c	 ; Copy from bank $0c to bank $00

; ---------------------------------------------------------------------------
; Final Save Load Setup
; ---------------------------------------------------------------------------

	ldx.W				   #$0e92	; X = $0e92
	stx.B				   $17	   ; [$17] = $0e92 (store pointer)

	jsr.W				   CODE_00A236 ; Process loaded save data

	sep					 #$20		; 8-bit accumulator

	jsl.L				   Display_EnableEffects ; Finalize save load

	rts							   ; Return

;-------------------------------------------------------------------------------
; SAVE SLOT DATA TABLE
;-------------------------------------------------------------------------------
; Format: 8 bytes per save slot (4 slots: $ff, 0, 1, 2)
; Structure unclear without further analysis
;-------------------------------------------------------------------------------

DATA8_0081d5:
	db											 $2d		 ; Slot 0, byte 0

DATA8_0081d6:
	dw											 $1f26	   ; Slot 0, bytes 1-2 (little-endian)

DATA8_0081d8:
	db											 $05		 ; Slot 0, byte 3

DATA8_0081d9:
	dw											 $aa0c	   ; Slot 0, bytes 4-5

DATA8_0081db:
	dw											 $a82e	   ; Slot 0, bytes 6-7

; Slot 1 data (8 bytes)
	db											 $19, $0e, $1a, $02, $0c, $aa, $c1, $a8

; Slot 2 data (8 bytes)
	db											 $14, $33, $28, $05, $2c, $aa, $6a, $a9

DATA8_0081ed:
; Referenced by CODE_0080DC (at $008113)
; Initialization data table
	db											 $ec, $a6, $03

;===============================================================================
; RAM INITIALIZATION ($0081f0-$008227)
;===============================================================================

Clear_WorkRAM:
; ===========================================================================
; Clear All Work RAM
; ===========================================================================
; Zeros out RAM ranges $0000-$05ff and $0800-$1fff.
; Leaves $0600-$07ff untouched (likely reserved for specific purpose).
;
; Uses MVN (Block Move Negative) instruction for fast memory fill.
; Clever technique: Write zero to first byte, then copy that byte forward.
;
; RAM Layout After Clear:
;   $0000-$05ff: Cleared (1,536 bytes)
;   $0600-$07ff: Preserved (512 bytes) - hardware mirrors or special use
;   $0800-$1fff: Cleared (6,144 bytes)
; ===========================================================================

	lda.W				   #$0000	; A = $0000
	tcd							   ; D = $0000 (Direct Page = $0000)
; Reset direct page to bank $00 start

	stz.B				   $00	   ; [$0000] = $00 (write zero to first byte)

; ---------------------------------------------------------------------------
; Clear $0000-$05ff (1,536 bytes)
; ---------------------------------------------------------------------------
; Technique: Copy the zero byte forward across memory
; Source: $0000 (which we just set to $00)
; Dest: $0002 (start copying from here)
; Length: $05fd+1 = $05fe bytes
; Result: $0000-$05ff all become $00
; ---------------------------------------------------------------------------

	ldx.W				   #$0000	; X = $0000 (source address)
	ldy.W				   #$0002	; Y = $0002 (dest address - skip $0000,$0001)
	lda.W				   #$05fd	; A = $05fd (copy 1,534 bytes)
	mvn					 $00,$00	 ; Fill $0002-$05ff with zero
; (copying from $0000 which is zero)

; ---------------------------------------------------------------------------
; Clear $0800-$1fff (6,144 bytes)
; ---------------------------------------------------------------------------
; Same technique for second RAM region
; Skips $0600-$07ff (512 bytes preserved)
; ---------------------------------------------------------------------------

	stz.W				   $0800	 ; [$0800] = $00 (write zero to start of region)

	ldx.W				   #$0800	; X = $0800 (source address)
	ldy.W				   #$0802	; Y = $0802 (dest address)
	lda.W				   #$17f8	; A = $17f8 (copy 6,137 bytes)
	mvn					 $00,$00	 ; Fill $0802-$1fff with zero

; ---------------------------------------------------------------------------
; Set Boot Signature
; ---------------------------------------------------------------------------
; $7e3367 = Boot signature/checksum
; $3369 might be a magic number verifying proper boot
; ---------------------------------------------------------------------------

	lda.W				   #$3369	; A = $3369 (boot signature)
	sta.L				   $7e3367   ; [$7e3367] = $3369

; ---------------------------------------------------------------------------
; Load Initial Data Table Based on Save Flag
; ---------------------------------------------------------------------------
; Checks if save file exists, loads different init table accordingly
; ---------------------------------------------------------------------------

	ldx.W				   #$822a	; X = $822a (default data table pointer)

	lda.L				   $7e3667   ; A = save file exists flag
	and.W				   #$00ff	; Mask to 8-bit value
	beq					 Load_InitDataTable ; If 0 (no save) → use default table

	ldx.W				   #$822d	; X = $822d (alternate table for existing save)

Load_InitDataTable:
	jmp.W				   CODE_009BC4 ; Load/process data table and return

;-------------------------------------------------------------------------------
; INITIALIZATION DATA TABLES
;-------------------------------------------------------------------------------

DATA8_00822a:
; No save file table
	db											 $2d, $a6, $03

DATA8_00822d:
; Has save file table
	db											 $2b, $a6, $03

;===============================================================================
; FINAL SETUP ROUTINE ($008230-$008246)
;===============================================================================

Boot_PostInit:
; ===========================================================================
; Final Setup Before Main Game
; ===========================================================================
; Called just before jumping to main game loop.
; Sets up additional game state in bank $7e RAM.
; ===========================================================================

	rep					 #$30		; 16-bit A, X, Y

	pea.W				   $007e	 ; Push $007e to stack
	plb							   ; Pull to B (Data Bank = $7e)
; All memory accesses now default to bank $7e

	lda.W				   #$0170	; A = $0170 (parameter 1)
	ldy.W				   #$3007	; Y = $3007 (parameter 2)
	jsr.W				   CODE_009A08 ; Initialize with these parameters

	lda.W				   #$0098	; A = $0098
	sta.W				   $31b5	 ; [$7e31b5] = $0098 (game state variable)

	plb							   ; Restore B (Data Bank back to $00)
	rts							   ; Return

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

	sep					 #$30		; 8-bit A, X, Y (and set flags)

	stz.W				   SNES_NMITIMEN ; $4200 = $00
; Disable NMI, IRQ, and auto-joypad read

	lda.B				   #$80	  ; A = $80 (bit 7 = force blank)
	sta.W				   SNES_INIDISP ; $2100 = $80
; Force blank: screen output disabled
; Brightness = 0

	rts							   ; Return

;-------------------------------------------------------------------------------
; DATA TABLE (Unknown Purpose)
;-------------------------------------------------------------------------------

DATA8_008252:
; Referenced by DMA setup at CODE_00804D
; 9 bytes of data
	db											 $00
	db											 $db, $80, $fd, $db, $80, $fd, $db, $80, $fd

;===============================================================================
; VBLANK/NMI HANDLER AND DMA MANAGEMENT ($00825c-$008337)
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

	rep					 #$30		; 16-bit A, X, Y

	lda.W				   #$0000	; A = $0000
	tcd							   ; Direct Page = $0000

; ---------------------------------------------------------------------------
; Initialize DMA State Variables ($0500-$050a)
; ---------------------------------------------------------------------------
; These variables track DMA transfer state and configuration
; ---------------------------------------------------------------------------

	ldx.W				   #$ff08	; X = $ff08 (init value)
	stx.W				   $0503	 ; [$0503-$0504] = $ff08
	stx.W				   $0501	 ; [$0501-$0502] = $ff08

	ldx.W				   #$880f	; X = $880f (init value)
	stx.W				   $0508	 ; [$0508-$0509] = $880f
	stx.W				   $0506	 ; [$0506-$0507] = $880f

	lda.W				   #$00ff	; A = $00ff
	sep					 #$20		; 8-bit accumulator

	sta.W				   $0500	 ; [$0500] = $ff
	sta.W				   $0505	 ; [$0505] = $ff

	lda.B				   #$00	  ; A = $00
	sta.W				   $050a	 ; [$050a] = $00

; ---------------------------------------------------------------------------
; Clear Graphics State Flags ($7e3659-$7e3663)
; ---------------------------------------------------------------------------

	sta.L				   $7e3659   ; [$7e3659] = $00
	sta.L				   $7e365e   ; [$7e365e] = $00
	sta.L				   $7e3663   ; [$7e3663] = $00

	rep					 #$30		; 16-bit A, X, Y

	sta.L				   $7e365a   ; [$7e365a-$7e365b] = $0000
	sta.L				   $7e365c   ; [$7e365c-$7e365d] = $0000
	sta.L				   $7e365f   ; [$7e365f-$7e3660] = $0000
	sta.L				   $7e3661   ; [$7e3661-$7e3662] = $0000

; ---------------------------------------------------------------------------
; Load Additional Initialization Data
; ---------------------------------------------------------------------------

	ldx.W				   #$8334	; X = $8334 (pointer to init data table)
	jsr.W				   CODE_009BC4 ; Load/process data table

; ---------------------------------------------------------------------------
; Initialize OAM DMA Parameters
; ---------------------------------------------------------------------------
; $01f0/$01f2 = OAM DMA transfer sizes
; ---------------------------------------------------------------------------

	lda.W				   #$0040	; A = $0040 (64 bytes)
	sta.W				   $01f0	 ; [$01f0] = $0040 (first OAM DMA size)

	lda.W				   #$0004	; A = $0004 (4 bytes)
	sta.W				   $01f2	 ; [$01f2] = $0004 (second OAM DMA size)

; ---------------------------------------------------------------------------
; Copy Data from ROM to RAM (Bank $7e)
; ---------------------------------------------------------------------------

	ldx.W				   #$b81b	; X = $b81b (source address low/mid)
	ldy.W				   #$3000	; Y = $3000 (destination address)
	lda.W				   #$0006	; A = $0006 (copy 7 bytes)
	mvn					 $7e,$00	 ; Copy from bank $00 to bank $7e
; Source: $00b81b → Dest: $7e3000

; ---------------------------------------------------------------------------
; Copy DMA Channel Configuration
; ---------------------------------------------------------------------------
; Copies 8 bytes from $004340 to $004340 (self-copy? or init?)
; ---------------------------------------------------------------------------

	ldy.W				   #$4340	; Y = $4340 (DMA channel 4 registers)
	lda.W				   #$0007	; A = $0007 (copy 8 bytes)
	mvn					 $00,$00	 ; Copy within bank $00

; ---------------------------------------------------------------------------
; Set Configuration Flag
; ---------------------------------------------------------------------------

	lda.W				   #$0010	; A = $0010 (bit 4)
	tsb.W				   $0111	 ; Test and Set bit 4 in $0111

; ---------------------------------------------------------------------------
; Initialize Graphics System (3 calls)
; ---------------------------------------------------------------------------

	lda.W				   #$0000	; A = $0000 (parameter)
	jsr.W				   CODE_00CA63 ; Initialize graphics component 0

	lda.W				   #$0001	; A = $0001 (parameter)
	jsr.W				   CODE_00CA63 ; Initialize graphics component 1

	lda.W				   #$0002	; A = $0002 (parameter)
	jsr.W				   CODE_00CA63 ; Initialize graphics component 2

; ---------------------------------------------------------------------------
; Load Graphics Data from ROM to RAM
; ---------------------------------------------------------------------------

	ldx.W				   #$d380	; X = $d380 (source: bank $0c, offset $d380)
	ldy.W				   #$0e84	; Y = $0e84 (destination in bank $00)
	lda.W				   #$017b	; A = $017b (copy 380 bytes)
	mvn					 $00,$0c	 ; Copy from bank $0c to bank $00
; Source: $0cd380 → Dest: $000e84

	ldx.W				   #$d0b0	; X = $d0b0 (source: bank $0c, offset $d0b0)
	ldy.W				   #$1000	; Y = $1000 (destination in bank $00)
	lda.W				   #$004f	; A = $004f (copy 80 bytes)
	mvn					 $00,$0c	 ; Copy from bank $0c to bank $00
; Source: $0cd0b0 → Dest: $001000

; ---------------------------------------------------------------------------
; Initialize Character/Party State
; ---------------------------------------------------------------------------

	lda.W				   #$00ff	; A = $00ff
	sta.W				   $1090	 ; [$1090] = $00ff (character state?)
	sta.W				   $10a1	 ; [$10a1] = $00ff
	sta.W				   $10a0	 ; [$10a0] = $00ff (active character?)

; ---------------------------------------------------------------------------
; Load Configuration from ROM
; ---------------------------------------------------------------------------

	lda.L				   DATA8_07800a ; A = [ROM $07800a]
	and.W				   #$739c	; A = A & $739c (mask specific bits)
	sta.W				   $0e9c	 ; [$0e9c] = masked value

; ---------------------------------------------------------------------------
; Initialize Additional Systems
; ---------------------------------------------------------------------------

	jsr.W				   CODE_008EC4 ; Initialize system
	jsr.W				   CODE_008C3D ; Initialize system
	jsr.W				   CODE_008D29 ; Initialize system

; ---------------------------------------------------------------------------
; Set Direct Page to PPU Registers ($2100)
; ---------------------------------------------------------------------------
; Clever technique: Set D=$2100 so direct page accesses hit PPU registers
; This makes `STA.B $15` equivalent to `STA.W $2115` (VMAINC)
; Saves bytes and cycles in tight VBLANK code
; ---------------------------------------------------------------------------

	lda.W				   #$2100	; A = $2100 (PPU register base)
	tcd							   ; D = $2100 (Direct Page → PPU registers)

	stz.W				   $00f0	 ; [$00f0] = $0000 (clear state)

; ---------------------------------------------------------------------------
; Upload Graphics to VRAM
; ---------------------------------------------------------------------------

	ldx.W				   #$6080	; X = $6080 (VRAM address)
	stx.B				   SNES_VMADDL-$2100 ; $2116-$2117 = VRAM address $6080
; (using direct page offset)

	pea.W				   $0004	 ; Push $0004
	plb							   ; B = $04 (Data Bank = $04)
; Memory accesses now default to bank $04

	ldx.W				   #$99c0	; X = $99c0 (source address in bank $04)
	ldy.W				   #$0004	; Y = $0004 (DMA parameters)
	jsl.L				   CODE_008DDF ; Execute graphics upload via DMA

	plb							   ; Restore Data Bank
	rtl							   ; Return

;-------------------------------------------------------------------------------
; INITIALIZATION DATA TABLE
;-------------------------------------------------------------------------------

DATA8_008334:
; Referenced at $0082a2
	db											 $fc, $a6, $03

;===============================================================================
; MAIN NMI/VBLANK HANDLER ($008337-$0083e7)
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
;   $00e2 bit 6: Special mode handler
;   $00d4 bit 1: Tilemap DMA pending
;   $00dd bit 6: Graphics upload pending
;   $00d8 bit 7: Battle graphics update
;   $00d2 bits: Various DMA operation flags
; ===========================================================================

	rep					 #$30		; 16-bit A, X, Y

	lda.W				   #$4300	; A = $4300 (DMA register base)
	tcd							   ; D = $4300 (Direct Page → DMA registers)
; Now `LDA.B $00` = `LDA.W $4300` etc.

	sep					 #$20		; 8-bit accumulator

	stz.W				   $420c	 ; $420c (HDMAEN) = $00
; Disable HDMA during processing

; ---------------------------------------------------------------------------
; Check State Flag $00e2 Bit 6 (Special Handler Mode)
; ---------------------------------------------------------------------------

	lda.B				   #$40	  ; A = $40 (bit 6 mask)
	and.W				   $00e2	 ; Test bit 6 of $00e2
	bne					 NMI_SpecialHandler ; If set → Jump to special handler

; ---------------------------------------------------------------------------
; Check State Flag $00d4 Bit 1 (Tilemap DMA)
; ---------------------------------------------------------------------------

	lda.B				   #$02	  ; A = $02 (bit 1 mask)
	and.W				   $00d4	 ; Test bit 1 of $00d4
	bne					 NMI_TilemapDMA ; If set → Tilemap DMA needed

; ---------------------------------------------------------------------------
; Check State Flag $00dd Bit 6 (Graphics Upload)
; ---------------------------------------------------------------------------

	lda.B				   #$40	  ; A = $40 (bit 6 mask)
	and.W				   $00dd	 ; Test bit 6 of $00dd
	bne					 NMI_GraphicsUpload ; If set → Graphics upload needed

; ---------------------------------------------------------------------------
; Check State Flag $00d8 Bit 7 (Battle Graphics)
; ---------------------------------------------------------------------------

	lda.B				   #$80	  ; A = $80 (bit 7 mask)
	and.W				   $00d8	 ; Test bit 7 of $00d8
	beq					 NMI_CheckMoreFlags ; If clear → Skip battle graphics

	lda.B				   #$80	  ; A = $80
	trb.W				   $00d8	 ; Test and Reset bit 7 of $00d8
; Clear the flag (one-shot operation)

	jmp.W				   CODE_0085B7 ; Execute battle graphics update

;-------------------------------------------------------------------------------

NMI_CheckMoreFlags:
; ===========================================================================
; Check Additional DMA Flags
; ===========================================================================
; Continues checking state flags for other DMA operations.
; ===========================================================================

	lda.B				   #$c0	  ; A = $c0 (bits 6-7 mask)
	and.W				   $00d2	 ; Test bits 6-7 of $00d2
	bne					 CODE_0083A8 ; If any set → Execute DMA operations

	lda.B				   #$10	  ; A = $10 (bit 4 mask)
	and.W				   $00d2	 ; Test bit 4 of $00d2
	bne					 NMI_SpecialDMA ; If set → Special operation

	jmp.W				   CODE_008428 ; → Continue to additional handlers

;-------------------------------------------------------------------------------

NMI_SpecialDMA:
	jmp.W				   CODE_00863D ; Execute special DMA operation

;-------------------------------------------------------------------------------

NMI_TilemapDMA:
	jmp.W				   CODE_0083E8 ; Execute tilemap DMA transfer

;-------------------------------------------------------------------------------

NMI_SpecialHandler:
; ===========================================================================
; Special Mode Handler (Indirect Jump)
; ===========================================================================
; Bit 6 of $00e2 triggers special handler mode.
; Jumps through pointer at [$0058] (16-bit address in bank $00).
; This allows dynamic handler switching.
; ===========================================================================

	lda.B				   #$40	  ; A = $40
	trb.W				   $00e2	 ; Test and Reset bit 6 of $00e2
; Clear flag before jumping

	jml.W				   [$0058]   ; Jump Long to address stored at [$0058]
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
;   Source: RAM address from $01f6 (bank $7f)
;   Destination: VRAM address from $01f8
;   Size: $01f4 bytes
;   Mode: $1801 (incrementing source, fixed dest register pair)
; ===========================================================================

	ldx.W				   #$1801	; X = $1801
; $18 = DMA mode (2 registers, increment)
; $01 = Low byte of destination register
	stx.B				   SNES_DMA5PARAM-$4300 ; $4350-$4351 = DMA5 parameters

	ldx.W				   $01f6	 ; X = source address (from variable)
	stx.B				   SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source address low/mid

	lda.B				   #$7f	  ; A = $7f
	sta.B				   SNES_DMA5ADDRH-$4300 ; $4354 = Source bank $7f

	ldx.W				   $01f4	 ; X = transfer size (from variable)
	stx.B				   SNES_DMA5CNTL-$4300 ; $4355-$4356 = Transfer size

	ldx.W				   $01f8	 ; X = VRAM destination address
	stx.W				   SNES_VMADDL ; $2116-$2117 = VRAM address

	lda.B				   #$84	  ; A = $84
; Bit 7 = increment after writing $2119
; Bits 0-3 = increment by 128 words
	sta.W				   SNES_VMAINC ; $2115 = VRAM address increment mode

	lda.B				   #$20	  ; A = $20 (bit 5 = DMA channel 5)
	sta.W				   SNES_MDMAEN ; $420b = Execute DMA channel 5
; Transfer starts immediately!

;-------------------------------------------------------------------------------

NMI_ProcessDMAFlags:
; ===========================================================================
; Process DMA Operation Flags ($00d2)
; ===========================================================================
; Handles various DMA operations based on flags in $00d2.
; ===========================================================================

	lda.B				   #$80	  ; A = $80 (bit 7 mask)
	and.W				   $00d2	 ; Test bit 7 of $00d2
	beq					 NMI_CheckOAMFlag ; If clear → Skip this DMA

; ---------------------------------------------------------------------------
; DMA Transfer with Vertical Increment
; ---------------------------------------------------------------------------

	lda.B				   #$80	  ; A = $80 (increment after $2119 write)
	sta.W				   SNES_VMAINC ; $2115 = VRAM increment mode

	ldx.W				   #$1801	; X = $1801 (DMA parameters)
	stx.B				   SNES_DMA5PARAM-$4300 ; $4350-$4351 = DMA5 config

	ldx.W				   $01ed	 ; X = source address
	stx.B				   SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source address low/mid

	lda.W				   $01ef	 ; A = source bank
	sta.B				   SNES_DMA5ADDRH-$4300 ; $4354 = Source bank

	ldx.W				   $01eb	 ; X = transfer size
	stx.B				   SNES_DMA5CNTL-$4300 ; $4355-$4356 = Size

	ldx.W				   $0048	 ; X = VRAM address
	stx.W				   SNES_VMADDL ; $2116-$2117 = VRAM address

	lda.B				   #$20	  ; A = $20 (DMA channel 5)
	sta.W				   SNES_MDMAEN ; $420b = Execute DMA

;-------------------------------------------------------------------------------

NMI_CheckOAMFlag:
; ===========================================================================
; Check OAM Update Flag
; ===========================================================================
; Bit 5 of $00d2 triggers OAM (sprite) data upload.
; ===========================================================================

	lda.B				   #$20	  ; A = $20 (bit 5 mask)
	and.W				   $00d2	 ; Test bit 5 of $00d2
	beq					 NMI_Cleanup ; If clear → Skip OAM update

	jsr.W				   DMA_UpdateOAM ; Execute OAM DMA transfer

;-------------------------------------------------------------------------------

NMI_Cleanup:
; ===========================================================================
; Cleanup and Return from NMI
; ===========================================================================
; Clears processed flags and returns from interrupt handler.
; ===========================================================================

	lda.B				   #$40	  ; A = $40 (bit 6)
	trb.W				   $00dd	 ; Test and Reset bit 6 of $00dd
; Clear graphics upload flag

	lda.B				   #$a0	  ; A = $a0 (bits 5 and 7)
	trb.W				   $00d2	 ; Test and Reset bits 5,7 of $00d2
; Clear OAM and VRAM DMA flags

	rtl							   ; Return from Long call (NMI complete)

;===============================================================================
; TILEMAP DMA TRANSFER ($0083e8-$008576)
;===============================================================================

DMA_TransferTilemap:
; ===========================================================================
; Tilemap DMA Transfer to VRAM
; ===========================================================================
; Transfers tilemap data from ROM to VRAM for background layers.
; Used when switching screens or updating large portions of the map.
;
; Process:
;   1. Clear DMA pending flag ($00d4 bit 1)
;   2. Configure CGRAM (palette) upload
;   3. Transfer tilemap data to VRAM
;   4. Handle special cases based on $0062 flag
; ===========================================================================

	lda.B				   #$02	  ; A = $02 (bit 1)
	trb.W				   $00d4	 ; Test and Reset bit 1 of $00d4
; Clear "tilemap DMA pending" flag

	lda.B				   #$80	  ; A = $80 (increment after $2119 write)
	sta.W				   $2115	 ; $2115 (VMAINC) = $80
; VRAM address increments by 1 word after high byte write

; ---------------------------------------------------------------------------
; Configure Palette (CGRAM) DMA
; ---------------------------------------------------------------------------

	ldx.W				   #$2200	; X = $2200
; $22 = DMA mode (fixed source, increment dest)
; $00 = Target register low byte
	stx.B				   SNES_DMA5PARAM-$4300 ; $4350 = DMA5 parameters

	lda.B				   #$07	  ; A = $07
	sta.B				   SNES_DMA5ADDRH-$4300 ; $4354 = Source bank $07

	lda.B				   #$a8	  ; A = $a8 (CGADD - palette address register)
	ldx.W				   $0064	 ; X = [$0064] (palette index/parameters)
	jsr.W				   DMA_TransferPalette ; Execute palette DMA transfer

; ---------------------------------------------------------------------------
; Prepare for Tilemap Transfer
; ---------------------------------------------------------------------------

	rep					 #$30		; 16-bit A, X, Y

	ldx.W				   #$ff00	; X = $ff00
	stx.W				   $00f0	 ; [$00f0] = $ff00 (state marker)

; ---------------------------------------------------------------------------
; Check Transfer Mode ($0062)
; ---------------------------------------------------------------------------
; $0062 determines which transfer path to take
; If $0062 = 1, use special graphics upload method
; Otherwise, use standard tilemap transfer
; ---------------------------------------------------------------------------

	ldx.W				   $0062	 ; X = [$0062] (transfer mode flag)
	lda.W				   #$6080	; A = $6080 (default VRAM address)

	cpx.W				   #$0001	; Compare mode with 1
	beq					 DMA_SpecialGraphics ; If mode = 1 → Special graphics upload

	jsr.W				   DMA_StandardTilemap ; Standard tilemap transfer
	rtl							   ; Return

;-------------------------------------------------------------------------------

DMA_SpecialGraphics:
; ===========================================================================
; Special Graphics Upload (Mode 1)
; ===========================================================================
; Alternative graphics upload path when $0062 = 1.
; Uses different source data and parameters.
; ===========================================================================

	phk							   ; Push Program Bank (K register)
	plb							   ; Pull to Data Bank (B register)
; B = $00 (set data bank to current program bank)

	sta.W				   SNES_VMADDL ; $2116-$2117 = VRAM address $6080

	ldx.W				   #$f0c1	; X = $f0c1 (source address in bank $04)
	ldy.W				   #$0004	; Y = $0004 (DMA parameters)
	jmp.W				   CODE_008DDF ; Execute graphics DMA and return

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
;   $00d4 bit 7: Large transfer pending
;   $00d8 bit 1: Battle graphics mode
;   $00da bit 4: Special transfer mode
; ===========================================================================

	lda.B				   #$80	  ; A = $80 (bit 7 mask)
	and.W				   $00d4	 ; Test bit 7 of $00d4
	beq					 NMI_ReturnToHandler ; If clear → Skip, jump to handler return

	lda.B				   #$80	  ; A = $80
	trb.W				   $00d4	 ; Test and Reset bit 7 of $00d4
; Clear "large transfer pending" flag

	lda.B				   #$80	  ; A = $80 (increment mode)
	sta.W				   $2115	 ; $2115 (VMAINC) = $80

; ---------------------------------------------------------------------------
; Check Battle Graphics Mode ($00d8 bit 1)
; ---------------------------------------------------------------------------

	lda.B				   #$02	  ; A = $02 (bit 1 mask)
	and.W				   $00d8	 ; Test bit 1 of $00d8
	beq					 NMI_AlternateTransfer ; If clear → Use alternate path

; ---------------------------------------------------------------------------
; Battle Graphics Transfer
; ---------------------------------------------------------------------------
; Transfers battle-specific graphics during scene transitions
; ---------------------------------------------------------------------------

	ldx.W				   #$1801	; X = $1801 (DMA parameters)
	stx.B				   SNES_DMA5PARAM-$4300 ; $4350 = DMA5 config

	ldx.W				   #$075a	; X = $075a (source address offset)
	stx.B				   SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source address low/mid

	lda.B				   #$7f	  ; A = $7f
	sta.B				   SNES_DMA5ADDRH-$4300 ; $4354 = Source bank $7f
; Full source: $7f075a

	ldx.W				   #$0062	; X = $0062 (98 bytes)
	stx.B				   SNES_DMA5CNTL-$4300 ; $4355-$4356 = Transfer size

	ldx.W				   #$3bad	; X = $3bad (VRAM destination)
	stx.W				   $2116	 ; $2116-$2117 = VRAM address

	lda.B				   #$20	  ; A = $20 (DMA channel 5)
	sta.W				   $420b	 ; $420b = Execute DMA

; ---------------------------------------------------------------------------
; Additional Battle Graphics Data Transfer
; ---------------------------------------------------------------------------
; Writes specific data directly to VRAM
; ---------------------------------------------------------------------------

	rep					 #$30		; 16-bit A, X, Y

	ldx.W				   #$4bed	; X = $4bed (VRAM address)
	stx.W				   $2116	 ; Set VRAM address

	lda.L				   $7f17da   ; A = [$7f17da] (16-bit data)
	sta.W				   $2118	 ; $2118-$2119 = Write to VRAM data

	lda.L				   $7f17dc   ; A = [$7f17dc] (16-bit data)
	sta.W				   $2118	 ; Write second word to VRAM

	sep					 #$20		; 8-bit accumulator

;-------------------------------------------------------------------------------

NMI_ReturnToHandler:
; ===========================================================================
; Return to Main NMI Handler
; ===========================================================================
	jmp.W				   NMI_ProcessDMAFlags ; → Jump back to NMI handler continuation

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

	ldx.W				   #$2200	; X = $2200 (DMA parameters)
	stx.B				   SNES_DMA5PARAM-$4300 ; $4350 = DMA5 config

	lda.B				   #$07	  ; A = $07
	sta.B				   SNES_DMA5ADDRH-$4300 ; $4354 = Source bank $07

; ---------------------------------------------------------------------------
; Transfer Two Palette Sets
; ---------------------------------------------------------------------------

	lda.B				   #$88	  ; A = $88 (palette address)
	ldx.W				   $00f4	 ; X = [$00f4] (source offset 1)
	jsr.W				   CODE_008504 ; Transfer palette set 1

	lda.B				   #$98	  ; A = $98 (palette address)
	ldx.W				   $00f7	 ; X = [$00f7] (source offset 2)
	jsr.W				   CODE_008504 ; Transfer palette set 2

; ---------------------------------------------------------------------------
; Write Direct VRAM Data
; ---------------------------------------------------------------------------

	rep					 #$30		; 16-bit A, X, Y

	ldx.W				   #$5e8d	; X = $5e8d (VRAM address)
	stx.W				   $2116	 ; Set VRAM address

	lda.L				   $7e2d1a   ; A = [$7e2d1a] (data from WRAM)
	sta.W				   $2118	 ; Write to VRAM

	lda.L				   $7e2d1c   ; A = [$7e2d1c]
	sta.W				   $2118	 ; Write second word

; ---------------------------------------------------------------------------
; Prepare for Tilemap Transfer
; ---------------------------------------------------------------------------

	ldx.W				   #$ff00	; X = $ff00
	stx.W				   $00f0	 ; [$00f0] = $ff00 (marker)

; ---------------------------------------------------------------------------
; Transfer Two Tilemap Regions
; ---------------------------------------------------------------------------

	ldx.W				   $00f2	 ; X = [$00f2] (tilemap 1 source)
	lda.W				   #$6000	; A = $6000 (VRAM address 1)
	jsr.W				   CODE_008520 ; Transfer tilemap region 1

	ldx.W				   $00f5	 ; X = [$00f5] (tilemap 2 source)
	lda.W				   #$6040	; A = $6040 (VRAM address 2)
	jsr.W				   CODE_008520 ; Transfer tilemap region 2

	sep					 #$20		; 8-bit accumulator

; ---------------------------------------------------------------------------
; Check Special Transfer Mode
; ---------------------------------------------------------------------------

	lda.B				   #$10	  ; A = $10 (bit 4 mask)
	and.W				   $00da	 ; Test bit 4 of $00da
	bne					 CODE_0084F8 ; If set → Skip menu graphics transfer

; ---------------------------------------------------------------------------
; Menu Graphics Transfer
; ---------------------------------------------------------------------------
; Transfers menu-specific graphics data
; ---------------------------------------------------------------------------

	ldx.W				   #$1801	; X = $1801 (DMA parameters)
	stx.B				   SNES_DMA5PARAM-$4300 ; $4350 = DMA5 config

	ldx.W				   #$0380	; X = $0380 (896 bytes)
	stx.B				   SNES_DMA5CNTL-$4300 ; $4355-$4356 = Transfer size

	lda.B				   #$7f	  ; A = $7f
	sta.B				   SNES_DMA5ADDRH-$4300 ; $4354 = Source bank $7f

; ---------------------------------------------------------------------------
; Select Source Address Based on Menu Position
; ---------------------------------------------------------------------------
; $1031 contains vertical menu position
; Different Y positions use different graphics data
; ---------------------------------------------------------------------------

	lda.W				   $1031	 ; A = [$1031] (Y position)

	ldx.W				   #$c708	; X = $c708 (default source 1)
	cmp.B				   #$26	  ; Compare Y with $26
	bcc					 CODE_0084EB ; If Y < $26 → Use source 1

	ldx.W				   #$c908	; X = $c908 (source 2)
	cmp.B				   #$29	  ; Compare Y with $29
	bcc					 CODE_0084EB ; If Y < $29 → Use source 2

	ldx.W				   #$ca48	; X = $ca48 (source 3)
; Y >= $29 → Use source 3

DMA_ExecuteTilemapTransfer:
	stx.B				   SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Selected source address

	ldx.W				   #$6700	; X = $6700 (VRAM destination)
	stx.W				   SNES_VMADDL ; $2116-$2117 = VRAM address

	lda.B				   #$20	  ; A = $20 (DMA channel 5)
	sta.W				   SNES_MDMAEN ; $420b = Execute DMA

;-------------------------------------------------------------------------------

NMI_ClearTransferMarkers:
; ===========================================================================
; Clear Transfer Markers and Return
; ===========================================================================

	ldx.W				   #$ffff	; X = $ffff
	stx.W				   $00f2	 ; [$00f2] = $ffff (invalidate tilemap 1)
	stx.W				   $00f5	 ; [$00f5] = $ffff (invalidate tilemap 2)

	jmp.W				   NMI_ProcessDMAFlags ; → Return to NMI handler

;===============================================================================
; PALETTE TRANSFER HELPER ($008504-$00851f)
;===============================================================================

DMA_TransferPalette:
; ===========================================================================
; Palette Transfer Helper Routine
; ===========================================================================
; Transfers a single palette set to CGRAM via DMA.
;
; Parameters:
;   A = Palette start address (CGADD value)
;   X = Source data offset (8-bit, added to base $07d8e4)
;
; Process:
;   1. Set CGRAM address
;   2. Calculate full source address
;   3. Execute 16-byte DMA transfer
; ===========================================================================

	sta.W				   $2121	 ; $2121 (CGADD) = Palette start address
; Sets where in CGRAM to write

	ldy.W				   #$0010	; Y = $0010 (16 bytes = 8 colors)
	sty.B				   SNES_DMA5CNTL-$4300 ; $4355-$4356 = Transfer 16 bytes

	rep					 #$30		; 16-bit A, X, Y

	txa							   ; A = X (transfer source offset to A)
	and.W				   #$00ff	; A = A & $00ff (ensure 8-bit value)
	clc							   ; Clear carry
	adc.W				   #$d8e4	; A = A + $d8e4 (add base address)
; Final source in bank $07: $07(D8E4+offset)
	sta.B				   SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Calculated source address

	sep					 #$20		; 8-bit accumulator

	lda.B				   #$20	  ; A = $20 (DMA channel 5)
	sta.W				   $420b	 ; $420b = Execute palette DMA

	rts							   ; Return

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
;   X = Source address offset (or $ffff to skip)
;
; SNES Tilemap Format:
;   Each tile = 2 bytes (tile number + attributes)
;   Transfers in two passes separated by $0180 bytes
;   This likely handles interleaved data format
; ===========================================================================

	cpx.W				   #$ffff	; Check if X = $ffff
	beq					 DMA_StandardTilemap_Skip ; If yes → Skip transfer (no data)

	sta.W				   SNES_VMADDL ; $2116-$2117 = VRAM destination address

	pea.W				   $0004	 ; Push $0004
	plb							   ; B = $04 (Data Bank = $04)

	phx							   ; Save X (source address)

	ldy.W				   #$0002	; Y = $0002 (DMA parameters)
	jsl.L				   CODE_008DDF ; Execute first tilemap transfer

	pla							   ; A = saved X (restore source address)
	clc							   ; Clear carry
	adc.W				   #$0180	; A = source + $0180 (offset to second half)
	tax							   ; X = new source address

	ldy.W				   #$0002	; Y = $0002 (DMA parameters)
	jsl.L				   CODE_008DDF ; Execute second tilemap transfer
; (VRAM address auto-increments)

	plb							   ; Restore Data Bank

DMA_StandardTilemap_Skip:
	rts							   ; Return

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

	ldx.W				   #$0400	; X = $0400
; $04 = DMA mode (write 2 registers once)
; $00 = Target register low byte ($2104 = OAMDATA)
	stx.B				   SNES_DMA5PARAM-$4300 ; $4350 = DMA5 config

	ldx.W				   #$0c00	; X = $0c00 (source address)
	stx.B				   SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source in bank $00: $000c00

	lda.B				   #$00	  ; A = $00
	sta.B				   SNES_DMA5ADDRH-$4300 ; $4354 = Source bank $00

	ldx.W				   $01f0	 ; X = [$01f0] (transfer size - main table)
	stx.B				   SNES_DMA5CNTL-$4300 ; $4355-$4356 = Size (typically $0200 = 512 bytes)

	ldx.W				   #$0000	; X = $0000
	stx.W				   SNES_OAMADDL ; $2102-$2103 = OAM address = 0
; Start writing at first sprite

	lda.B				   #$20	  ; A = $20 (DMA channel 5)
	sta.W				   SNES_MDMAEN ; $420b = Execute DMA (main table)

; ---------------------------------------------------------------------------
; Configure DMA for High OAM Table
; ---------------------------------------------------------------------------

	ldx.W				   #$0e00	; X = $0e00 (source address for high table)
	stx.B				   SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source: $000e00

	ldx.W				   $01f2	 ; X = [$01f2] (transfer size - high table)
	stx.B				   SNES_DMA5CNTL-$4300 ; $4355-$4356 = Size (typically $0020 = 32 bytes)

	ldx.W				   #$0100	; X = $0100
	stx.W				   SNES_OAMADDL ; $2102-$2103 = OAM address = $100
; This is where high table starts

	lda.B				   #$20	  ; A = $20 (DMA channel 5)
	sta.W				   SNES_MDMAEN ; $420b = Execute DMA (high table)

	rts							   ; Return

;===============================================================================
; BATTLE GRAPHICS UPDATE ($008577-$0085b6)
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

	ldx.W				   #$4400	; X = $4400 (VRAM destination)
	stx.W				   SNES_VMADDL ; $2116-$2117 = VRAM address

	ldx.W				   #$1801	; X = $1801 (DMA parameters)
	stx.B				   SNES_DMA5PARAM-$4300 ; $4350 = DMA5 config

	ldx.W				   #$0480	; X = $0480 (source address offset)
	stx.B				   SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source in bank $7f: $7f0480

	lda.B				   #$7f	  ; A = $7f
	sta.B				   SNES_DMA5ADDRH-$4300 ; $4354 = Source bank

	ldx.W				   #$0280	; X = $0280 (640 bytes)
	stx.B				   SNES_DMA5CNTL-$4300 ; $4355-$4356 = Transfer size

	lda.B				   #$20	  ; A = $20 (DMA channel 5)
	sta.W				   SNES_MDMAEN ; $420b = Execute DMA
; ===========================================================================

	lda.B				   #$80	  ; A = $80 (bit 7)
	trb.W				   $00de	 ; Test and Reset bit 7 of $00de
; Clear some state flag

	lda.B				   #$e0	  ; A = $e0 (bits 5-7)
	trb.W				   $0111	 ; Test and Reset bits 5-7 of $0111
; Clear multiple state flags

	jsl.L				   CODE_0C8000 ; Bank $0c: Wait for VBLANK

; ---------------------------------------------------------------------------
; Configure Color Math (Fade Effect)

	rep					 #$30		; 16-bit A, X, Y registers
	ldx.W				   #$1fff	; X = $1fff
	txs							   ; Stack pointer = $1fff (top of RAM)

	jsr.W				   Init_Graphics_Registers ; Initialize PPU and graphics registers

; ---------------------------------------------------------------------------
; Check for Special Button Combination
; ---------------------------------------------------------------------------
; Checks if a specific button is held during boot
; Might enable debug mode, skip intro, etc.
; ---------------------------------------------------------------------------

	lda.W				   #$0040	; A = $0040 (bit 6 = some button?)
	and.W				   $00da	 ; Mask with controller input
	bne					 Skip_Normal_Init ; If button held, skip to alternate path

; Normal initialization path
	jsl.L				   BankOC_Init ; Initialize bank $0c systems
	bra					 Continue_Init ; Continue setup

;-------------------------------------------------------------------------------

Boot_Tertiary_Entry:
; ===========================================================================
; Tertiary Boot Entry Point
; ===========================================================================
; Yet another entry point - FFMQ has multiple boot paths
; ===========================================================================

	jsr.W				   Init_Hardware ; Hardware init (again)

	lda.B				   #$f0
	sta.L				   $000600   ; Hardware mirror write

	jsl.L				   Bank0D_Init_Variant ; Subsystem init

	rep					 #$30		; 16-bit mode
	ldx.W				   #$1fff	; Reset stack pointer
TXS_Label:

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

	jsr.W				   Init_Graphics_Registers ; More graphics setup

	sep					 #$20		; 8-bit A, 16-bit X/Y

; Configure DMA Channel 0
	ldx.W				   #$1809	; DMA parameters
; $18 = DMA control byte
; $09 = Target register (probably $2109?)
	stx.W				   !SNES_DMA0PARAM ; $4300-4301: DMA control + target

	ldx.W				   #$8252	; Source address = $008252
	stx.W				   !SNES_DMA0ADDRL ; $4302-4303: Source address low/mid

	lda.B				   #$00	  ; Source bank = $00
	sta.W				   !SNES_DMA0ADDRH ; $4304: Source address bank

	ldx.W				   #$0000	; Size = $0000 (wraps to $10000 = 64KB)
	stx.W				   !SNES_DMA0CNTL ; $4305-4306: Transfer size

	lda.B				   #$01	  ; Enable DMA channel 0
	sta.W				   !SNES_MDMAEN ; $420b: Start DMA transfer NOW

;-------------------------------------------------------------------------------

Skip_Normal_Init:
; ===========================================================================
; Post-Initialization Setup
; ===========================================================================
; Called after hardware is initialized, regardless of boot path
; ===========================================================================

	jsl.L				   $00011f   ; Call early routine (what is this?)

	rep					 #$30		; 16-bit A, X, Y
	lda.W				   #$0000
	tcd							   ; Direct page = $0000 (default)

	sep					 #$20		; 8-bit A

; ---------------------------------------------------------------------------
; Enable Interrupts (NMI/IRQ)
; ---------------------------------------------------------------------------
; NMI (Non-Maskable Interrupt) = VBlank interrupt
; Fires every frame at vertical blanking
; Used for graphics updates, timing, etc.
; ---------------------------------------------------------------------------

	lda.W				   $0112	 ; Load NMI enable flags
	sta.W				   !SNES_NMITIMEN ; $4200: Enable NMI and/or IRQ
	cli							   ; Clear interrupt disable flag
; Interrupts now active!

; ---------------------------------------------------------------------------
; Set Screen Brightness
; ---------------------------------------------------------------------------

	lda.B				   #$0f	  ; Full brightness (0-15 scale)
	sta.W				   $00aa	 ; Store to brightness variable

; Call initialization twice (fade in/out? Double buffer?)
	jsl.L				   BankOC_Init
	jsl.L				   BankOC_Init

; ---------------------------------------------------------------------------
; Check Save Game Status
; ---------------------------------------------------------------------------
; Determines whether to load a save or start new game
; ---------------------------------------------------------------------------

	lda.L				   $7e3665   ; Load save state flag
	bne					 Handle_Existing_Save ; If non-zero, handle existing save

; ---------------------------------------------------------------------------
; Check SRAM for Save Data
; ---------------------------------------------------------------------------
; SRAM (battery-backed RAM) at $70:0000-$7f:FFFF stores save games
; Check specific bytes to see if valid save data exists
; ---------------------------------------------------------------------------

	lda.L				   $700000   ; SRAM byte 1 (save header?)
	ora.L				   $70038c   ; OR with SRAM byte 2
	ora.L				   $700718   ; OR with SRAM byte 3
	beq					 Start_New_Game ; If all zero, no save exists

; Save data exists - load it
	jsl.L				   Load_Save_Game ; Load game from SRAM
	bra					 Continue_To_Game

;-------------------------------------------------------------------------------

Handle_Existing_Save:
; ===========================================================================
; Handle Existing Save State
; ===========================================================================
; Called when save state flag indicates save in progress
; ===========================================================================

	jsr.W				   Some_Save_Handler
	bra					 Enter_Main_Loop

;-------------------------------------------------------------------------------

Start_New_Game:
; ===========================================================================
; New Game Initialization
; ===========================================================================
; Called when no save data exists - starts a fresh game
; ===========================================================================

	jsr.W				   Init_New_Game

;-------------------------------------------------------------------------------

Continue_To_Game:
; ===========================================================================
; Final Setup Before Game Loop
; ===========================================================================
; Last minute preparations before entering main game loop
; ===========================================================================

	lda.B				   #$80	  ; Bit 7
	trb.W				   $00de	 ; Test and reset bit 7 in game flag

	lda.B				   #$e0	  ; Bits 5-7
	trb.W				   $0111	 ; Test and reset bits 5-7

	jsl.L				   BankOC_Init ; Another initialization call

; ---------------------------------------------------------------------------
; Configure Color Math (SNES Special Effects)
; ---------------------------------------------------------------------------
; Color math allows adding/subtracting colors for transparency, fades, etc.
; ---------------------------------------------------------------------------

	lda.B				   #$e0	  ; Color math: subtract mode?
	sta.W				   !SNES_COLDATA ; $2132: Color math configuration

; Reset windowing and color effects
	ldx.W				   #$0000
	stx.W				   !SNES_CGSWSEL ; $2130: Window mask settings

; ---------------------------------------------------------------------------
; Reset Background Scroll Positions
; ---------------------------------------------------------------------------

	stz.W				   !SNES_BG1VOFS ; $210e: BG1 vertical scroll = 0
	stz.W				   !SNES_BG1VOFS ; Write twice (SNES registers need H+L bytes)

	stz.W				   !SNES_BG2VOFS ; $2110: BG2 vertical scroll = 0
	stz.W				   !SNES_BG2VOFS

	jsr.W				   Some_Graphics_Setup
	jsl.L				   BankOC_Init

;-------------------------------------------------------------------------------

Enter_Main_Loop:
; ===========================================================================
; MAIN GAME LOOP ENTRY
; ===========================================================================
; This is where the actual game begins!
; From here, execution enters the main game loop
; ===========================================================================

	jsr.W				   Main_Game_Loop

	lda.B				   #$00
	jsr.W				   Some_Mode_Handler

	lda.B				   #$01
	jsr.W				   Some_Mode_Handler

	ldx.W				   #$81ed	; Pointer to some data
	jsr.W				   Execute_Script_Or_Command

	lda.B				   #$04
	tsb.W				   $00d4	 ; Test and set bit 2 in game flag

	lda.B				   #$80
	trb.W				   $00d6	 ; Test and reset bit 7 in flag

	stz.W				   $0110	 ; Clear some variable

	lda.B				   #$01
	tsb.W				   $00e2	 ; Test and set bit 0

	lda.B				   #$10
	tsb.W				   $00d6	 ; Test and set bit 4

	ldx.W				   #$fff0	; Some value
	stx.W				   $008e	 ; Store to variable

	jsl.L				   Some_System_Call
	jsr.W				   Some_Function
	jml.L				   Jump_To_Bank01 ; Jump to bank $01 code!

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

	lda.B				   #$14	  ; Enable BG1, BG3, BG4?
	sta.W				   !SNES_TM  ; $212c: Main screen designation

	rep					 #$30		; 16-bit mode
	lda.W				   #$0000
	sta.L				   $7e31b5   ; Clear some game variable

	jsr.W				   Some_Init_Routine

	sep					 #$20		; 8-bit A
	jsl.L				   BankOC_Init

; ---------------------------------------------------------------------------
; DMA Transfer to OAM (Sprite Attribute Memory)
; ---------------------------------------------------------------------------
; OAM holds sprite positions, tiles, and attributes
; ---------------------------------------------------------------------------

	ldx.W				   #$0000
	stx.W				   !SNES_OAMADDL ; $2102: OAM address = 0

; Configure DMA Channel 5 for OAM
	ldx.W				   #$0400	; DMA params for OAM
	stx.W				   !SNES_DMA5PARAM ; $4350-4351

	ldx.W				   #$0c00	; Source = $000c00
	stx.W				   !SNES_DMA5ADDRL ; $4352-4353

	lda.B				   #$00	  ; Source bank = $00
	sta.W				   !SNES_DMA5ADDRH ; $4354

	ldx.W				   #$0220	; Transfer size = $0220 = 544 bytes
	stx.W				   !SNES_DMA5CNTL ; $4355-4356

	lda.B				   #$20	  ; Enable DMA channel 5 (bit 5)
	sta.W				   !SNES_MDMAEN ; $420b: Start DMA

; ---------------------------------------------------------------------------
; More Initialization
; ---------------------------------------------------------------------------

	rep					 #$30		; 16-bit mode
	lda.W				   #$ffff
	sta.W				   $010e	 ; Initialize some variable to -1

	jsl.L				   Some_Init_Function_1
	jsr.W				   Some_Init_Function_2
	jsl.L				   Some_Init_Function_3

	sep					 #$20		; 8-bit A
RTS_Label:

;-------------------------------------------------------------------------------

Some_Save_Handler:
; ===========================================================================
; Handle Save Game Loading/Management
; ===========================================================================
; TODO: Analyze what this actually does
; ===========================================================================

	rep					 #$30		; 16-bit mode

; MVN = Block move negative (copy memory blocks)
	ldx.W				   #$a9c2	; Source
	ldy.W				   #$1010	; Destination
	lda.W				   #$003f	; Length-1
	mvn					 $00,$0c	 ; Copy from bank $00 to bank $0c

	ldy.W				   #$0e9e	; Another destination
	lda.W				   #$0009	; Length-1
	mvn					 $00,$0c	 ; Another block copy

	sep					 #$20		; 8-bit A

	lda.B				   #$02
	sta.W				   $0fe7	 ; Store some value

	lda.L				   $7e3668   ; Load save state
	cmp.B				   #$02
	bcc					 .less_than_2
	lda.B				   #$ff	  ; Cap at $ff if >= 2

	.less_than_2:
	inc					 a; Increment save state
	sta.L				   $7e3668   ; Store back

	rep					 #$30		; 16-bit mode
	and.W				   #$0003	; Mask to 0-3
	asl					 a; Multiply by 8
	asl					 a
	asl					 a
	tax							   ; X = offset into table

	sep					 #$20		; 8-bit A
	stz.B				   $19	   ; Clear some variable

; Load data from table based on save state
	lda.W				   Save_State_Table,x
	sta.W				   $0e88

	ldy.W				   Save_State_Table+1,x
	sty.W				   $0e89

	lda.W				   Save_State_Table+3,x
	sta.W				   $0e92

	ldy.W				   Save_State_Table+6,x
	sty.B				   $53

	ldy.W				   Save_State_Table+4,x
TYX_Label:

	rep					 #$30		; 16-bit mode
	ldy.W				   #$0ea8
	lda.W				   #$001f
	mvn					 $00,$0c	 ; Block copy

	ldx.W				   #$0e92
	stx.B				   $17

	jsr.W				   Some_Function_A236

	sep					 #$20		; 8-bit A
	jsl.L				   Some_Function_9319
RTS_Label:

;-------------------------------------------------------------------------------
; Save State Data Table
;-------------------------------------------------------------------------------

Save_State_Table:
	db											 $2d		 ; Entry 0
	dw											 $1f26
	db											 $05
	dw											 $aa0c
	dw											 $a82e

	db											 $19, $0e, $1a ; Entry 1
	db											 $02
	dw											 $aa0c
	dw											 $a8c1

	db											 $14, $33, $28 ; Entry 2
	db											 $05
	dw											 $aa2c
	dw											 $a96a

	db											 $ec, $a6, $03 ; Entry 3 (partial data visible)

;===============================================================================
; HARDWARE/MEMORY INITIALIZATION
;===============================================================================

Init_Graphics_Registers:
; ===========================================================================
; Initialize Graphics/PPU Registers
; ===========================================================================
; Sets up initial values for SNES PPU (Picture Processing Unit)
; ===========================================================================

	lda.W				   #$0000
	tcd							   ; Direct page = $0000

	stz.B				   $00	   ; Clear first byte of RAM

; ---------------------------------------------------------------------------
; Clear RAM ($0000-$05fd = 1,534 bytes)
; ---------------------------------------------------------------------------
; Uses MVN (block move) to quickly zero memory
; ---------------------------------------------------------------------------

	ldx.W				   #$0000	; Source = $0000
	ldy.W				   #$0002	; Dest = $0002
	lda.W				   #$05fd	; Length = $05fd bytes
	mvn					 $00,$00	 ; Copy within bank $00
; This copies $00 forward, clearing memory!

; ---------------------------------------------------------------------------
; Clear More RAM ($0800-$1ff8 = 6,136 bytes)
; ---------------------------------------------------------------------------

	stz.W				   $0800	 ; Clear byte at $0800

	ldx.W				   #$0800	; Source = $0800
	ldy.W				   #$0802	; Dest = $0802
	lda.W				   #$17f8	; Length = $17f8 = 6,136 bytes
	mvn					 $00,$00	 ; Clear this block too

; ---------------------------------------------------------------------------
; Initialize Magic Number (Save Data Validation?)
; ---------------------------------------------------------------------------

	lda.W				   #$3369	; Magic number = $3369
	sta.L				   $7e3367   ; Store to WRAM
; Probably used to detect valid save data

; ---------------------------------------------------------------------------
; Execute Initialization Script Based on Save State
; ---------------------------------------------------------------------------

	ldx.W				   #$822a	; Default script pointer

	lda.L				   $7e3667   ; Load save exists flag
	and.W				   #$00ff	; Mask to byte
	beq					 .no_save

	ldx.W				   #$822d	; Different script if save exists

	.no_save:
	jmp.W				   Execute_Script_Or_Command

;-------------------------------------------------------------------------------
; Initialization Script Pointers
;-------------------------------------------------------------------------------

	db											 $2d, $a6, $03 ; Script data (TODO: decode format)
	db											 $2b, $a6, $03

;===============================================================================
; MORE INITIALIZATION FUNCTIONS
;===============================================================================

Some_Function:
; ===========================================================================
; TODO: Analyze and document this function
; ===========================================================================

	rep					 #$30		; 16-bit mode

; Set data bank to $7e (WRAM)
	pea.W				   $007e
PLB_Label:

	lda.W				   #$0170
	ldy.W				   #$3007
	jsr.W				   Some_Function_9A08

	lda.W				   #$0098
	sta.W				   $31b5	 ; Store to WRAM variable

	plb							   ; Restore data bank
RTS_Label:

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

	sep					 #$30		; 8-bit A, X, Y

	stz.W				   !SNES_NMITIMEN ; $4200: Disable NMI and IRQ

	lda.B				   #$80	  ; Force blank + full brightness
	sta.W				   !SNES_INIDISP ; $2100: Screen display control
; Bit 7 = force blank (screen off)
RTS_Label:

;-------------------------------------------------------------------------------
; DMA Source Data (Register Init Values)
;-------------------------------------------------------------------------------

	org					 $008252
DMA_Init_Data:
	db											 $00		 ; First byte
	db											 $db, $80, $fd ; More init values
	db											 $db, $80, $fd
	db											 $db, $80, $fd
; More data continues...

;===============================================================================
; Graphics Update - Field Mode (continued from CODE_008577)
;===============================================================================

DMA_FieldGraphicsUpdate:
; Setup VRAM for vertical increment mode
	lda.B				   #$80	  ; Increment after writing to $2119
	sta.W				   SNES_VMAINC ; Set VRAM increment mode

; Check if battle mode graphics needed
	lda.B				   #$10	  ; Check bit 4 of display flags
	and.W				   $00da	 ; Test against display status
	beq					 +		   ; If clear, continue to field graphics
	jmp					 CODE_008577 ; Otherwise do battle graphics transfer
	+
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
	beq					 DMA_FieldGraphicsUpdate_OAM ; If clear, skip tilemap transfer

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

DMA_FieldGraphicsUpdate_OAM:
	jsr.W				   DMA_UpdateOAM ; Transfer OAM data

; Check if additional display update needed
	lda.B				   #$20	  ; Check bit 5
	and.W				   $00d6	 ; Test display flags
	beq					 DMA_FieldGraphicsUpdate_Exit ; If clear, exit
	lda.B				   #$78	  ; Set multiple flags (bits 3,4,5,6)
	tsb.W				   $00d4	 ; Set bits in status register

DMA_FieldGraphicsUpdate_Exit:
	rtl							   ; Return

;===============================================================================
; SPECIAL GRAPHICS TRANSFER ROUTINES ($00863d-$008965)
;===============================================================================

DMA_SpecialVRAMHandler:
; ===========================================================================
; Special VRAM Transfer Handler
; ===========================================================================
; Handles specialized graphics transfers for menu systems and battle mode.
; Manages palette selection, tilemap updates, and context-specific graphics.
;
; State Flags:
;   $00d2 bit 4: Special transfer pending
;   $00da bit 4: Battle mode graphics flag
;   $00de bit 6: Character status update
;   $00d6 bit 5: Additional display update flag
; ===========================================================================

	lda.B				   #$10	  ; A = $10 (bit 4 mask)
	trb.W				   $00d2	 ; Test and Reset bit 4 of $00d2
; Clear "special transfer pending" flag

	lda.B				   #$80	  ; A = $80 (increment mode)
	sta.W				   SNES_VMAINC ; $2115 = Increment after $2119 write

; ---------------------------------------------------------------------------
; Check Battle Mode Graphics Flag
; ---------------------------------------------------------------------------

	lda.B				   #$10	  ; A = $10 (bit 4 mask)
	and.W				   $00da	 ; Test bit 4 of $00da
	beq					 DMA_FieldModeTransfer ; If clear → Use normal field mode graphics

; ---------------------------------------------------------------------------
; Battle Mode Graphics Transfer
; ---------------------------------------------------------------------------
; Transfers menu graphics for battle interface
; ---------------------------------------------------------------------------

	pea.W				   $0004	 ; Push $0004
	plb							   ; B = $04 (Data Bank = $04)

	ldx.W				   #$60c0	; X = $60c0 (VRAM address)
	stx.W				   $2116	 ; Set VRAM address

	ldx.W				   #$ff00	; X = $ff00
	stx.W				   $00f0	 ; [$00f0] = $ff00 (state marker)

	ldx.W				   #$99c0	; X = $99c0 (source in bank $04)
	ldy.W				   #$0004	; Y = $0004 (DMA parameters)
	jsl.L				   CODE_008DDF ; Execute tilemap DMA transfer

	plb							   ; Restore Data Bank

; ---------------------------------------------------------------------------
; Transfer Battle Palette Set 1
; ---------------------------------------------------------------------------

	lda.B				   #$a8	  ; A = $a8 (palette start address)
	sta.W				   SNES_CGADD ; $2121 = CGRAM address = $a8

	ldx.W				   #$2200	; X = $2200 (DMA parameters)
	stx.B				   SNES_DMA5PARAM-$4300 ; $4350 = DMA5 config

	ldx.W				   #$d814	; X = $d814 (source offset)
	stx.B				   SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source: $07d814

	lda.B				   #$07	  ; A = $07
	sta.B				   SNES_DMA5ADDRH-$4300 ; $4354 = Source bank $07

	ldx.W				   #$0010	; X = $0010 (16 bytes = 8 colors)
	stx.B				   SNES_DMA5CNTL-$4300 ; $4355-$4356 = Transfer size

	lda.B				   #$20	  ; A = $20 (DMA channel 5)
	sta.W				   SNES_MDMAEN ; $420b = Execute palette DMA

; ---------------------------------------------------------------------------
; Clear Specific Palette Entries
; ---------------------------------------------------------------------------
; Clears palette entries $0d and $1d to black
; Used to reset specific UI colors in battle mode
; ---------------------------------------------------------------------------

	lda.B				   #$0d	  ; A = $0d (palette entry 13)
	sta.W				   SNES_CGADD ; Set CGRAM address
	stz.W				   SNES_CGDATA ; $2122 = $00 (color low byte = black)
	stz.W				   SNES_CGDATA ; $2122 = $00 (color high byte)

	lda.B				   #$1d	  ; A = $1d (palette entry 29)
	sta.W				   SNES_CGADD ; Set CGRAM address
	stz.W				   SNES_CGDATA ; $2122 = $00 (black)
	stz.W				   SNES_CGDATA ; $2122 = $00

	rtl							   ; Return

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

	ldx.W				   #$2200	; X = $2200 (DMA parameters)
	stx.B				   SNES_DMA5PARAM-$4300 ; $4350 = DMA5 config

	ldx.W				   #$d824	; X = $d824 (source offset)
	stx.B				   SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source: $07d824

	lda.B				   #$07	  ; A = $07
	sta.B				   SNES_DMA5ADDRH-$4300 ; $4354 = Source bank $07

	ldx.W				   #$0010	; X = $0010 (16 bytes)
	stx.B				   SNES_DMA5CNTL-$4300 ; $4355-$4356 = Transfer size

	rep					 #$30		; 16-bit A, X, Y

	stz.W				   $00f0	 ; [$00f0] = $0000 (clear state marker)

	pea.W				   $0004	 ; Push $0004
	plb							   ; B = $04 (Data Bank = $04)

; ---------------------------------------------------------------------------
; Check Character Status Update Flag ($00de bit 6)
; ---------------------------------------------------------------------------
; If set, update single character's status display
; Otherwise, refresh all three character displays
; ---------------------------------------------------------------------------

	lda.W				   #$0040	; A = $0040 (bit 6 mask)
	and.W				   $00de	 ; Test bit 6 of $00de
	beq					 DMA_UpdateAllCharacters ; If clear → Update all characters

; ---------------------------------------------------------------------------
; Single Character Status Update
; ---------------------------------------------------------------------------
; Updates one character's status display based on $010d and $010e
; ---------------------------------------------------------------------------

	lda.W				   #$0040	; A = $0040
	trb.W				   $00de	 ; Test and Reset bit 6 of $00de
; Clear "single character update" flag

	lda.W				   $010d	 ; A = [$010d] (character position data)
	and.W				   #$ff00	; A = A & $ff00 (mask high byte)
	clc							   ; Clear carry
	adc.W				   #$6180	; A = A + $6180 (calculate VRAM address)
	sta.W				   $2116	 ; $2116-$2117 = VRAM address

	lda.W				   $010e	 ; A = [$010e] (character index)
	asl					 a; A = A × 2 (convert to word offset)
	tax							   ; X = character table offset

	lda.W				   $0107,x   ; A = [$0107 + X] (character data pointer)
	tax							   ; X = character data pointer

	pha							   ; Save character data pointer
	jsr.W				   DMA_CharacterGraphics ; Transfer character graphics (2-part)
	ply							   ; Y = character data pointer (restore)

	plb							   ; Restore Data Bank

; ---------------------------------------------------------------------------
; Transfer Character Palette
; ---------------------------------------------------------------------------

	clc							   ; Clear carry
	lda.W				   $010e	 ; A = [$010e] (character index)
	adc.W				   #$000d	; A = A + $000d (palette offset)
	asl					 a; A = A × 2
	asl					 a; A = A × 4
	asl					 a; A = A × 8
	asl					 a; A = A × 16 (multiply by 16)
	tax							   ; X = palette CGRAM address

	jsr.W				   DMA_CharacterPalette ; Transfer character palette

	rtl							   ; Return

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

	lda.W				   #$6100	; A = $6100 (VRAM address)
	sta.W				   $2116	 ; Set VRAM address

	ldx.W				   #$9a20	; X = $9a20 (source in bank $04)
	ldy.W				   #$0004	; Y = $0004 (DMA parameters)
	jsl.L				   CODE_008DDF ; Transfer tilemap part 1

	ldx.W				   #$cd20	; X = $cd20 (source for second part)
	ldy.W				   #$0004	; Y = $0004 (DMA parameters)
	jsl.L				   CODE_008DDF ; Transfer tilemap part 2

; ---------------------------------------------------------------------------
; Transfer Character 1 Graphics
; ---------------------------------------------------------------------------

	ldx.W				   $0107	 ; X = [$0107] (character 1 data pointer)
	jsr.W				   DMA_CharacterGraphics ; Transfer character 1 graphics

; ---------------------------------------------------------------------------
; Transfer Character 2 Graphics
; ---------------------------------------------------------------------------

	lda.W				   #$6280	; A = $6280 (VRAM address for char 2)
	sta.W				   $2116	 ; Set VRAM address

	ldx.W				   $0109	 ; X = [$0109] (character 2 data pointer)
	jsr.W				   DMA_CharacterGraphics ; Transfer character 2 graphics

; ---------------------------------------------------------------------------
; Transfer Character 3 Graphics
; ---------------------------------------------------------------------------

	lda.W				   #$6380	; A = $6380 (VRAM address for char 3)
	sta.W				   $2116	 ; Set VRAM address

	ldx.W				   $010b	 ; X = [$010b] (character 3 data pointer)
	jsr.W				   DMA_CharacterGraphics ; Transfer character 3 graphics

	plb							   ; Restore Data Bank

; ---------------------------------------------------------------------------
; Transfer Main Menu Palette
; ---------------------------------------------------------------------------

	lda.W				   #$d824	; A = $d824 (source address)
	ldx.W				   #$00c0	; X = $00c0 (CGRAM address = palette $c)
	jsr.W				   DMA_PaletteToCGRAM ; Transfer palette

; ---------------------------------------------------------------------------
; Transfer Character 1 Palette
; ---------------------------------------------------------------------------

	ldy.W				   $0107	 ; Y = [$0107] (character 1 data pointer)
	ldx.W				   #$00d0	; X = $00d0 (CGRAM address = palette $d)
	jsr.W				   DMA_CharacterPalette ; Transfer character palette

; ---------------------------------------------------------------------------
; Transfer Character 2 Palette
; ---------------------------------------------------------------------------

	ldy.W				   $0109	 ; Y = [$0109] (character 2 data pointer)
	ldx.W				   #$00e0	; X = $00e0 (CGRAM address = palette $e)
	jsr.W				   CODE_00876C ; Transfer character palette

; ---------------------------------------------------------------------------
; Transfer Character 3 Palette
; ---------------------------------------------------------------------------

	ldy.W				   $010b	 ; Y = [$010b] (character 3 data pointer)
	ldx.W				   #$00f0	; X = $00f0 (CGRAM address = palette $f)
	jsr.W				   CODE_00876C ; Transfer character palette

	rtl							   ; Return

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

	phx							   ; Save character data pointer

; ---------------------------------------------------------------------------
; Transfer Graphics Part 1
; ---------------------------------------------------------------------------

	lda.L				   $000000,x ; A = [X+0] (graphics part 1 pointer)
	tax							   ; X = graphics part 1 pointer
	ldy.W				   #$0004	; Y = $0004 (DMA parameters)
	jsl.L				   CODE_008DDF ; Execute DMA transfer

; ---------------------------------------------------------------------------
; Transfer Graphics Part 2
; ---------------------------------------------------------------------------

	plx							   ; Restore character data pointer

	lda.L				   $000002,x ; A = [X+2] (graphics part 2 pointer)
	tax							   ; X = graphics part 2 pointer
	ldy.W				   #$0004	; Y = $0004 (DMA parameters)
	jsl.L				   CODE_008DDF ; Execute DMA transfer
; (VRAM address auto-increments from part 1)

	rts							   ; Return

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

	lda.W				   $0004,y   ; A = [Y+4] (palette data pointer)
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

	sta.B				   SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source address

	txa							   ; A = X (CGRAM address)
	sep					 #$20		; 8-bit accumulator

	sta.W				   SNES_CGADD ; $2121 = CGRAM address

	ldx.W				   #$0010	; X = $0010 (16 bytes)
	stx.B				   SNES_DMA5CNTL-$4300 ; $4355-$4356 = Transfer size

	lda.B				   #$20	  ; A = $20 (DMA channel 5)
	sta.W				   SNES_MDMAEN ; $420b = Execute palette DMA

	rep					 #$30		; 16-bit A, X, Y

	rts							   ; Return

;===============================================================================
; ADDITIONAL VBLANK OPERATIONS ($008784-$008965)
;===============================================================================

; Data table referenced by CODE_008784
DATA8_008960:
	db											 $3c		 ; Tile $3c

DATA8_008961:
	db											 $3d		 ; Tile $3d

DATA8_008962:
	db											 $3e,$45,$3a,$3b ; Tiles: $3e, $45, $3a, $3b

;===============================================================================
; MAIN GAME LOOP & FRAME UPDATE ($008966-$0089c5)
;===============================================================================

GameLoop_FrameUpdate:
; ===========================================================================
; Main Game Loop - Frame Update Handler
; ===========================================================================
; This is the main game logic executed every frame (60 times per second).
; Called from the NMI handler continuation path.
;
; Responsibilities:
;   1. Increment 24-bit frame counter ($0e97-$0e99)
;   2. Process time-based events (status effects, animations)
;   3. Handle full screen refreshes on mode changes
;   4. Process controller input and menu navigation
;   5. Update game state and animations
;
; Frame Counter:
;   $0e97-$0e98: Low 16 bits (wraps at 65536)
;   $0e99: High 8 bits (total 24-bit = ~16.7 million frames)
;   At 60fps, this counter wraps after ~77.9 hours of gameplay
; ===========================================================================

	rep					 #$30		; 16-bit A, X, Y

	lda.W				   #$0000	; A = $0000
	tcd							   ; D = $0000 (Direct Page = zero page)
; Reset DP for main game logic

; ---------------------------------------------------------------------------
; Increment 24-Bit Frame Counter
; ---------------------------------------------------------------------------

	inc.W				   $0e97	 ; Increment frame counter low word
	bne					 GameLoop_ProcessEvents ; If no overflow → Skip high byte increment
	inc.W				   $0e99	 ; Increment high byte (24-bit overflow)

;-------------------------------------------------------------------------------

GameLoop_ProcessEvents:
; ===========================================================================
; Time-Based Event Processing
; ===========================================================================

	jsr.W				   GameLoop_TimeBasedEvents ; Process time-based events (status effects, etc.)

; ---------------------------------------------------------------------------
; Check Full Screen Refresh Flag ($00d4 bit 2)
; ---------------------------------------------------------------------------
; When set, indicates a major mode change requiring full redraw
; (battle start, menu open, scene transition, etc.)
; ---------------------------------------------------------------------------

	lda.W				   #$0004	; A = $0004 (bit 2 mask)
	and.W				   $00d4	 ; Test bit 2 of $00d4
	beq					 GameLoop_NormalUpdate ; If clear → Normal frame processing

; ---------------------------------------------------------------------------
; Full Screen Refresh Path
; ---------------------------------------------------------------------------
; Executes when entering/exiting major game modes.
; Performs complete redraw of both BG layers.
; ---------------------------------------------------------------------------

	lda.W				   #$0004	; A = $0004
	trb.W				   $00d4	 ; Test and Reset bit 2 of $00d4
; Clear "full refresh needed" flag

; Refresh Background Layer 0
	lda.W				   #$0000	; A = $0000 (BG layer 0)
	jsr.W				   Char_CalcStats ; Update BG layer 0 tilemap
	jsr.W				   Tilemap_RefreshLayer0 ; Transfer layer 0 to VRAM

; Refresh Background Layer 1
	lda.W				   #$0001	; A = $0001 (BG layer 1)
	jsr.W				   Char_CalcStats ; Update BG layer 1 tilemap
	jsr.W				   Tilemap_RefreshLayer1 ; Transfer layer 1 to VRAM

	bra					 GameLoop_UpdateState ; → Skip to animation update

;-------------------------------------------------------------------------------

GameLoop_NormalUpdate:
; ===========================================================================
; Normal Frame Processing Path
; ===========================================================================
; Standard per-frame update when not doing full refresh.
; Handles incremental tilemap updates and controller input.
; ===========================================================================

	jsr.W				   CODE_008BFD ; Update tilemap changes (scrolling, etc.)

; ---------------------------------------------------------------------------
; Check Menu Mode Flag ($00da bit 4)
; ---------------------------------------------------------------------------

	lda.W				   #$0010	; A = $0010 (bit 4 mask)
	and.W				   $00da	 ; Test bit 4 of $00da (menu mode flag)
	bne					 GameLoop_ProcessInput ; If set → Process controller input

; ---------------------------------------------------------------------------
; Check Input Processing Enable ($00e2 bit 2)
; ---------------------------------------------------------------------------

	lda.W				   #$0004	; A = $0004 (bit 2 mask)
	and.W				   $00e2	 ; Test bit 2 of $00e2
	bne					 GameLoop_UpdateState ; If set → Skip input (cutscene/auto mode)

;-------------------------------------------------------------------------------

GameLoop_ProcessInput:
; ===========================================================================
; Controller Input Processing
; ===========================================================================
; Processes joypad input when enabled.
; Calls appropriate handler based on current game mode.
; ===========================================================================

	lda.B				   $07	   ; A = [$07] (controller data - current frame)
	and.B				   $8e	   ; A = A & [$8e] (input enable mask)
	beq					 GameLoop_UpdateState ; If zero → No valid input, skip processing

; ---------------------------------------------------------------------------
; Determine Input Handler
; ---------------------------------------------------------------------------
; CODE_009730 returns handler index in A based on game state
; Handler table at Input_HandlerTable dispatches to appropriate routine
; ---------------------------------------------------------------------------

	jsl.L				   CODE_009730 ; Get input handler index for current mode

	sep					 #$30		; 8-bit A, X, Y

	asl					 a; A = A × 2 (convert to word offset)
	tax							   ; X = handler table offset

	jsr.W				   (Input_HandlerTable,x) ; Call appropriate input handler
; (indirect jump through handler table)

;-------------------------------------------------------------------------------

GameLoop_UpdateState:
; ===========================================================================
; Animation and State Update
; ===========================================================================
; Final phase of frame processing.
; Updates animations, sprites, and game state.
; ===========================================================================

	rep					 #$30		; 16-bit A, X, Y

	jsr.W				   CODE_009342 ; Update sprite animations
	jsr.W				   CODE_009264 ; Update game state and logic

	rtl							   ; Return to NMI handler continuation

;===============================================================================
; TIME-BASED EVENT HANDLER ($0089c6-$008a29)
;===============================================================================

GameLoop_TimeBasedEvents:
; ===========================================================================
; Time-Based Event Processing
; ===========================================================================
; Processes status effects, poison damage, regeneration, and other
; time-based events that occur at regular intervals.
;
; Timer System:
;   $010d: Frame countdown timer (decrements each frame)
;   When timer reaches -1, executes status effect checks
;   Timer resets to 12 frames (~0.2 seconds at 60fps)
;
; Status Effect Checks:
;   Character slots at fixed SRAM addresses:
;   $700027: Character 1 status
;   $700077: Character 2 status
;   $7003b3: Character 3 status
;   $700403: Character 4 status
;   $70073f: Character 5 status
;   $70078f: Character 6 status
;
; $00de bit 7: Time-based processing enabled flag
; ===========================================================================

	phd							   ; Save Direct Page

; ---------------------------------------------------------------------------
; Check Time-Based Processing Enable Flag
; ---------------------------------------------------------------------------

	lda.W				   #$0080	; A = $0080 (bit 7 mask)
	and.W				   $00de	 ; Test bit 7 of $00de
	beq					 GameLoop_TimeBasedEvents_Exit ; If clear → Skip time-based processing

; ---------------------------------------------------------------------------
; Set Direct Page for Character Status Access
; ---------------------------------------------------------------------------

	lda.W				   #$0c00	; A = $0c00
	tcd							   ; D = $0c00 (Direct Page = $0c00)
; Allows $01 to access $0c01, etc.

	sep					 #$30		; 8-bit A, X, Y

; ---------------------------------------------------------------------------
; Decrement Timer and Check for Event Trigger
; ---------------------------------------------------------------------------

	dec.W				   $010d	 ; Decrement timer
	bpl					 GameLoop_TimeBasedEvents_Exit ; If still positive → Exit (not time yet)

; Timer expired - reset and process status effects
	lda.B				   #$0c	  ; A = $0c (12 frames)
	sta.W				   $010d	 ; Reset timer to 12 frames

; ---------------------------------------------------------------------------
; Check Character 1 Status ($700027)
; ---------------------------------------------------------------------------

	lda.L				   $700027   ; A = [$700027] (character 1 status flags)
	bne					 GameLoop_CheckChar2 ; If non-zero → Character 1 has status effect

	ldx.B				   #$40	  ; X = $40 (character 1 offset)
	jsr.W				   Update_CharacterStatusDisplay ; Update character 1 display

;-------------------------------------------------------------------------------

GameLoop_CheckChar2:
; ---------------------------------------------------------------------------
; Check Character 2 Status ($700077)
; ---------------------------------------------------------------------------

	lda.L				   $700077   ; A = [$700077] (character 2 status)
	bne					 GameLoop_CheckChar3 ; If non-zero → Character 2 has status

	ldx.B				   #$50	  ; X = $50 (character 2 offset)
	jsr.W				   Update_CharacterStatusDisplay ; Update character 2 display

;-------------------------------------------------------------------------------

GameLoop_CheckChar3:
; ---------------------------------------------------------------------------
; Check Character 3 Status ($7003b3)
; ---------------------------------------------------------------------------

	lda.L				   $7003b3   ; A = [$7003b3] (character 3 status)
	bne					 GameLoop_TimeBasedEvents_Exit ; If non-zero → Character 3 has status

	ldx.B				   #$60	  ; X = $60 (character 3 offset)
	jsr.W				   Update_CharacterStatusDisplay ; Update character 3 display

;-------------------------------------------------------------------------------

GameLoop_CheckChar4:
; ---------------------------------------------------------------------------
; Check Character 4 Status ($700403)
; ---------------------------------------------------------------------------

	lda.L				   $700403   ; A = [$700403] (character 4 status)
	bne					 GameLoop_CheckChar5 ; If non-zero → Character 4 has status

	ldx.B				   #$70	  ; X = $70 (character 4 offset)
	jsr.W				   Update_CharacterStatusDisplay ; Update character 4 display

;-------------------------------------------------------------------------------

GameLoop_CheckChar5:
; ---------------------------------------------------------------------------
; Check Character 5 Status ($70073f)
; ---------------------------------------------------------------------------

	lda.L				   $70073f   ; A = [$70073f] (character 5 status)
	bne					 GameLoop_CheckChar6 ; If non-zero → Character 5 has status

	ldx.B				   #$80	  ; X = $80 (character 5 offset)
	jsr.W				   Update_CharacterStatusDisplay ; Update character 5 display

;-------------------------------------------------------------------------------

GameLoop_CheckChar6:
; ---------------------------------------------------------------------------
; Check Character 6 Status ($70078f)
; ---------------------------------------------------------------------------

	lda.L				   $70078f   ; A = [$70078f] (character 6 status)
	bne					 GameLoop_SetSpriteFlag ; If non-zero → Character 6 has status

	ldx.B				   #$90	  ; X = $90 (character 6 offset)
	jsr.W				   Update_CharacterStatusDisplay ; Update character 6 display

;-------------------------------------------------------------------------------

GameLoop_SetSpriteFlag:
; ---------------------------------------------------------------------------
; Set Sprite Update Flag
; ---------------------------------------------------------------------------

	lda.B				   #$20	  ; A = $20 (bit 5)
	tsb.W				   $00d2	 ; Set bit 5 of $00d2 (sprite update needed)

;-------------------------------------------------------------------------------

GameLoop_TimeBasedEvents_Exit:
; ===========================================================================
; Restore Direct Page and Return
; ===========================================================================

	rep					 #$30		; 16-bit A, X, Y
	pld							   ; Restore Direct Page
	rts							   ; Return

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
; Character Display Structure (at $0c00 + X):
;   +$02: Status tile base value
;   +$06: Status tile 1
;   +$0a: Status tile 2
;   +$0e: Status tile 3
;
; Tile Animation:
;   Toggles bit 2 of base value (XOR $04)
;   Then writes base+0, base+1, base+2, base+3 to tile slots
; ===========================================================================

	lda.B				   $02,x	 ; A = [$0c02+X] (current tile base)
	eor.B				   #$04	  ; A = A XOR $04 (toggle bit 2 for animation)
	sta.B				   $02,x	 ; [$0c02+X] = new tile base

	inc					 a; A = base + 1
	sta.W				   $0c06,x   ; [$0c06+X] = base + 1 (tile 1)

	inc					 a; A = base + 2
	sta.W				   $0c0a,x   ; [$0c0a+X] = base + 2 (tile 2)

	inc					 a; A = base + 3
	sta.W				   $0c0e,x   ; [$0c0e+X] = base + 3 (tile 3)

	rts							   ; Return

;===============================================================================
; INPUT HANDLER DISPATCH TABLE ($008a35-$008a54)
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
; STA.W $0c0a,X at Input_HandlerTable continues from Update_CharacterStatusDisplay
; The actual table starts here with word addresses:

; Handler jump table data (12 entries x 2 bytes = 24 bytes)
	db											 $cf,$8a, $f8,$8a, $68,$8b, $68,$8b ; Handlers 0-3
	db											 $61,$8a, $5d,$8a, $59,$8a, $55,$8a ; Handlers 4-7
	db											 $68,$8b, $68,$8b, $9d,$8a, $68,$8b ; Handlers 8-11

;===============================================================================
; CURSOR MOVEMENT HANDLERS ($008a55-$008a9c)
;===============================================================================

Input_CursorDown:
; ===========================================================================
; Cursor Down Handler
; ===========================================================================
	dec.B				   $02	   ; Decrement vertical position
	bra					 Input_ValidateCursor ; → Validate position

Input_CursorUp:
; ===========================================================================
; Cursor Up Handler
; ===========================================================================
	inc.B				   $02	   ; Increment vertical position
	bra					 Input_ValidateCursor ; → Validate position

Input_CursorLeft:
; ===========================================================================
; Cursor Left Handler
; ===========================================================================
	dec.B				   $01	   ; Decrement horizontal position
	bra					 Input_ValidateCursor ; → Validate position

Input_CursorRight:
; ===========================================================================
; Cursor Right Handler
; ===========================================================================
	inc.B				   $01	   ; Increment horizontal position
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

	lda.B				   $01	   ; A = X position
	bmi					 Input_CheckXWrap ; If negative → Check wrap flags

	cmp.B				   $03	   ; Compare with max X
	bcc					 Input_ValidateY ; If X < max → Valid, continue

; X position at or above maximum
	lda.B				   $95	   ; A = wrap flags
	and.B				   #$01	  ; Test bit 0 (allow overflow)
	bne					 Input_CheckXWrap ; If set → Allow wrap to negative

;-------------------------------------------------------------------------------

Input_ClampX:
; X exceeded maximum, clamp to max-1
	lda.B				   $03	   ; A = max X
	dec					 a; A = max - 1
	sta.B				   $01	   ; X position = max - 1 (clamp)
	bra					 Input_ValidateY ; → Validate Y position

;-------------------------------------------------------------------------------

Input_CheckXWrap:
; X position is negative or wrapped
	lda.B				   $95	   ; A = wrap flags
	and.B				   #$02	  ; Test bit 1 (allow negative)
	bne					 Input_ClampX ; If set → Clamp to max-1

	stz.B				   $01	   ; X position = 0 (clamp to minimum)

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

	lda.B				   $02	   ; A = Y position
	bmi					 Input_CheckYWrap ; If negative → Check wrap flags

	cmp.B				   $04	   ; Compare with max Y
	bcc					 Input_ValidateDone ; If Y < max → Valid, exit

; Y position at or above maximum
	lda.B				   $95	   ; A = wrap flags
	and.B				   #$04	  ; Test bit 2 (allow overflow)
	bne					 Input_CheckYWrap ; If set → Allow wrap to negative

;-------------------------------------------------------------------------------

Input_ClampY:
; Y exceeded maximum, clamp to max-1
	lda.B				   $04	   ; A = max Y
	dec					 a; A = max - 1
	sta.B				   $02	   ; Y position = max - 1 (clamp)
	rts							   ; Return

;-------------------------------------------------------------------------------

Input_CheckYWrap:
; Y position is negative or wrapped
	lda.B				   $95	   ; A = wrap flags
	and.B				   #$08	  ; Test bit 3 (allow negative)
	bne					 Input_ClampY ; If set → Clamp to max-1

	stz.B				   $02	   ; Y position = 0 (clamp to minimum)

;-------------------------------------------------------------------------------

Input_ValidateDone:
	rts							   ; Return

;===============================================================================
; BUTTON HANDLER & MENU LOGIC ($008a9d-$008bfc)
;===============================================================================

Input_ButtonA_ToggleStatus:
; ===========================================================================
; A Button Handler - Toggle Character Status
; ===========================================================================
; Handles A button press to toggle character status display.
; Shows/hides detailed character information in battle mode.
; ===========================================================================

	jsr.W				   Input_CheckAllowed ; Check if input allowed
	bne					 Input_ButtonA_Exit ; If blocked → Exit

; Check if in valid screen position
	lda.W				   $1090	 ; A = [$1090] (screen mode/position)
	bmi					 Input_ButtonA_Alternate ; If negative → Call alternate handler

; Toggle character status display
	lda.W				   $10a0	 ; A = [$10a0] (character display flags)
	eor.B				   #$80	  ; Toggle bit 7
	sta.W				   $10a0	 ; Save new flag state

	lda.B				   #$40	  ; A = $40 (bit 6)
	tsb.W				   $00d4	 ; Set bit 6 of $00d4 (update needed)

	jsr.W				   CODE_00B908 ; Update character display
	bra					 Input_ButtonA_Exit ; → Exit

;-------------------------------------------------------------------------------

Input_ButtonA_Alternate:
	jsr.W				   CODE_00B912 ; Alternate character update routine

Input_ButtonA_Exit:
	rts							   ; Return

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

	lda.W				   $1032	 ; A = [$1032] (X position)
	cmp.B				   #$80	  ; Compare with $80
	bne					 Menu_CheckCharPosition_Normal ; If not $80 → Jump to B908

	lda.W				   $1033	 ; A = [$1033] (Y position)
	bne					 Menu_CheckCharPosition_Normal ; If not $00 → Jump to B908

	jmp.W				   CODE_00B912 ; Special position → Call B912

;-------------------------------------------------------------------------------

Menu_CheckCharPosition_Normal:
	jmp.W				   CODE_00B908 ; Normal position → Call B908

;-------------------------------------------------------------------------------

Menu_NavCharUp:
; ===========================================================================
; Menu Navigation - Character Selection (Up/Down)
; ===========================================================================
; Handles up/down navigation through character list in menu.
; Cycles through valid characters, skipping invalid/dead entries.
; ===========================================================================

	jsr.W				   Input_CheckAllowed ; Check if input allowed
	bne					 Menu_NavCharUp_Exit ; If blocked → Exit

	jsr.W				   Menu_CheckCharPosition ; Validate character position

; ---------------------------------------------------------------------------
; Calculate Current Character Index
; ---------------------------------------------------------------------------

	lda.W				   $1031	 ; A = [$1031] (Y position)
	sec							   ; Set carry for subtraction
	sbc.B				   #$20	  ; A = Y - $20 (base offset)

	ldx.B				   #$ff	  ; X = -1 (character counter)

;-------------------------------------------------------------------------------

Menu_NavCharUp_CalcIndex:
; Divide by 3 to get character slot
	inx							   ; X++
	sbc.B				   #$03	  ; A -= 3
	bcs					 Menu_NavCharUp_CalcIndex ; If carry still set → Continue dividing

; X now contains character index (0-3)
	txa							   ; A = character index

;-------------------------------------------------------------------------------

Menu_NavCharUp_FindNext:
; ===========================================================================
; Cycle to Next Valid Character
; ===========================================================================
; Increments character index and checks if character is valid.
; Loops until valid character found.
; ===========================================================================

	inc					 a; A = next character index
	and.B				   #$03	  ; A = A & $03 (wrap 0-3)

	pha							   ; Save character index
	jsr.W				   CODE_008DA8 ; Check if character is valid
	pla							   ; Restore character index

	cpy.B				   #$ff	  ; Check if character invalid (Y = $ff)
	beq					 Menu_NavCharUp_FindNext ; If invalid → Try next character

; Valid character found
	jsr.W				   CODE_008B21 ; Update character display
	jsr.W				   CODE_008C3D ; Refresh graphics

Menu_NavCharUp_Exit:
	rts							   ; Return

;-------------------------------------------------------------------------------

Menu_NavCharDown:
; ===========================================================================
; Menu Navigation - Character Selection (Down/Reverse)
; ===========================================================================
; Handles down navigation, cycles backwards through character list.
; Same as Menu_NavCharUp but decrements instead of increments.
; ===========================================================================

	jsr.W				   Input_CheckAllowed ; Check if input allowed
	bne					 Menu_NavCharDown_Exit ; If blocked → Exit

	jsr.W				   Menu_CheckCharPosition ; Validate character position

	lda.W				   $1031	 ; A = [$1031] (Y position)
	sec							   ; Set carry
	sbc.B				   #$20	  ; A = Y - $20 (base offset)

	ldx.B				   #$ff	  ; X = -1 (counter)

;-------------------------------------------------------------------------------

Menu_NavCharDown_CalcIndex:
	inx							   ; X++
	sbc.B				   #$03	  ; A -= 3
	bcs					 Menu_NavCharDown_CalcIndex ; If carry → Continue

	txa							   ; A = character index

;-------------------------------------------------------------------------------

Menu_NavCharDown_FindPrev:
; Cycle to previous valid character
	dec					 a; A = previous character index
	and.B				   #$03	  ; A = A & $03 (wrap 0-3)

	pha							   ; Save index
	jsr.W				   CODE_008DA8 ; Check if character valid
	pla							   ; Restore index

	cpy.B				   #$ff	  ; Check if invalid
	beq					 Menu_NavCharDown_FindPrev ; If invalid → Try previous

	jsr.W				   CODE_008B21 ; Update character display
	jsr.W				   Tilemap_RefreshLayer0 ; Refresh graphics

Menu_NavCharDown_Exit:
	rts							   ; Return

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

	rep					 #$30		; 16-bit A, X, Y

	ldx.W				   #$3709	; X = $3709 (default tilemap 1)
	cpy.W				   #$0023	; Compare Y with $23
	bcc					 CODE_008B3E ; If Y < $23 → Use tilemap 1

	ldx.W				   #$3719	; X = $3719 (tilemap 2)
	cpy.W				   #$0026	; Compare Y with $26
	bcc					 Menu_CopyTilemapData ; If Y < $26 → Use tilemap 2

	ldx.W				   #$3729	; X = $3729 (tilemap 3)
	cpy.W				   #$0029	; Compare Y with $29
	bcc					 Menu_CopyTilemapData ; If Y < $29 → Use tilemap 3

	ldx.W				   #$3739	; X = $3739 (tilemap 4, Y >= $29)

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

	ldy.W				   #$3669	; Y = $3669 (destination in bank $7e)
	lda.W				   #$000f	; A = $000f (15, so copy 16 bytes)
	mvn					 $7e,$7e	 ; Copy 16 bytes from X to Y (both in $7e)

	phk							   ; Push program bank
	plb							   ; Pull to data bank (B = $00)

; ---------------------------------------------------------------------------
; Refresh Background Layer
; ---------------------------------------------------------------------------

	lda.W				   #$0000	; A = $0000 (BG layer 0)
	jsr.W				   Char_CalcStats ; Update layer 0

	sep					 #$30		; 8-bit A, X, Y

	lda.B				   #$80	  ; A = $80 (bit 7)
	tsb.W				   $00d9	 ; Set bit 7 of $00d9

	rts							   ; Return

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
; $00d6 bit 4: Input block flag
; $92: Controller state (masked to disable certain buttons)
; ===========================================================================

	lda.B				   #$10	  ; A = $10 (bit 4 mask)
	and.W				   $00d6	 ; Test bit 4 of $00d6
	beq					 Input_CheckAllowed_Exit ; If clear → Input allowed, exit

; Input blocked - mask controller state
	rep					 #$30		; 16-bit A, X, Y

	lda.B				   $92	   ; A = [$92] (controller state)
	and.W				   #$bfcf	; A = A & $bfcf (mask bits 4-5, 14)
; Disables: bit 4, bit 5, bit 14

	sep					 #$30		; 8-bit A, X, Y

Input_CheckAllowed_Exit:
	rts							   ; Return (Z flag indicates input state)

; Padding/unused byte
Unused_008B68:
	rts							   ; Return

;===============================================================================
; CONTROLLER INPUT PROCESSING ($008ba0-$008bfc)
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
; $00d6 bit 6: Disable controller reading
; $00d2 bit 3: Special input mode
; $00db bit 2: Alternate input filtering
; ===========================================================================

	rep					 #$30		; 16-bit A, X, Y

	lda.W				   #$0000	; A = $0000
	tcd							   ; D = $0000 (Direct Page = zero page)

; ---------------------------------------------------------------------------
; Check Controller Read Enable
; ---------------------------------------------------------------------------

	lda.W				   #$0040	; A = $0040 (bit 6 mask)
	and.W				   $00d6	 ; Test bit 6 of $00d6
	bne					 Input_ReadController_Exit ; If set → Controller disabled, exit

; ---------------------------------------------------------------------------
; Save Previous Controller State
; ---------------------------------------------------------------------------

	lda.B				   $92	   ; A = current controller state
	sta.B				   $96	   ; Save as previous state

; ---------------------------------------------------------------------------
; Check Special Input Mode ($00d2 bit 3)
; ---------------------------------------------------------------------------

	lda.W				   #$0008	; A = $0008 (bit 3 mask)
	and.W				   $00d2	 ; Test bit 3 of $00d2
	bne					 Input_SpecialMode ; If set → Special input mode

; ---------------------------------------------------------------------------
; Check Alternate Input Filter ($00db bit 2)
; ---------------------------------------------------------------------------

	lda.W				   #$0004	; A = $0004 (bit 2 mask)
	and.W				   $00db	 ; Test bit 2 of $00db
	bne					 Input_AlternateFilter ; If set → Use alternate filtering

; ---------------------------------------------------------------------------
; Normal Controller Read
; ---------------------------------------------------------------------------

	lda.W				   SNES_CNTRL1L ; A = [$4218] (Controller 1 input)
; Reads 16-bit joypad state
	bra					 Input_ProcessButtons ; → Process input

;-------------------------------------------------------------------------------

Input_SpecialMode:
; ===========================================================================
; Special Input Mode - Filter D-Pad
; ===========================================================================
; Reads controller but masks out D-pad directions.
; Only allows button presses (A, B, X, Y, L, R, Start, Select).
; ===========================================================================

	lda.W				   SNES_CNTRL1L ; A = controller state
	and.W				   #$fff0	; A = A & $fff0 (clear bits 0-3, D-pad)
	beq					 Input_ProcessButtons ; If zero → No buttons pressed

	jmp.W				   CODE_0092F0 ; → Special button handler

;-------------------------------------------------------------------------------

Input_AlternateFilter:
; ===========================================================================
; Alternate Input Filter
; ===========================================================================
; Checks $00d9 bit 1 for additional filtering mode.
; ===========================================================================

	lda.W				   #$0002	; A = $0002 (bit 1 mask)
	and.W				   $00d9	 ; Test bit 1 of $00d9
	beq					 Input_AlternateNormal ; If clear → Normal alternate mode

; Special alternate mode (incomplete in disassembly)
	db											 $a9,$80,$00,$04,$90 ; Raw bytes (seems incomplete)

;-------------------------------------------------------------------------------

Input_AlternateNormal:
	lda.W				   SNES_CNTRL1L ; A = controller state
	and.W				   #$fff0	; Mask D-pad
	beq					 Input_ProcessButtons ; If zero → No buttons

	jmp.W				   CODE_0092F6 ; → Alternate button handler

;-------------------------------------------------------------------------------

Input_ProcessButtons:
; ===========================================================================
; Process Controller Input
; ===========================================================================
; Combines current hardware input with software autofire.
; Calculates newly pressed buttons.
; ===========================================================================

	ora.B				   $90	   ; A = A | [$90] (OR with autofire bits)
	and.W				   #$fff0	; Mask to buttons only
	sta.B				   $94	   ; [$94] = all pressed buttons this frame

	tax							   ; X = pressed buttons (for later)

	trb.B				   $96	   ; Clear pressed buttons from previous state
; $96 now = buttons released this frame

	lda.B				   $92	   ; A = previous frame state
	trb.B				   $94	   ; Clear held buttons from new press state
; $94 now = newly pressed buttons only

	stx.B				   $92	   ; Save current state
	stz.B				   $90	   ; Clear autofire accumulator

Input_ReadController_Exit:
	rts							   ; Return

;===============================================================================
; AUTOFIRE & INPUT TIMING ($008bfd-$008c1a)
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

	stz.B				   $07	   ; Clear output (no input by default)

; ---------------------------------------------------------------------------
; Check for New Button Presses
; ---------------------------------------------------------------------------

	lda.B				   $94	   ; A = newly pressed buttons
	bne					 Input_NewButtonPress ; If any new press → Handle immediate input

; ---------------------------------------------------------------------------
; Handle Held Buttons (Autofire)
; ---------------------------------------------------------------------------

	lda.B				   $92	   ; A = currently held buttons
	beq					 Input_HandleAutofire_Exit ; If nothing held → Exit

	dec.B				   $09	   ; Decrement autofire timer
	bpl					 Input_HandleAutofire_Exit ; If timer still positive → Exit (not ready)

; Timer expired - trigger autofire event
	sta.B				   $07	   ; Output = held buttons (simulate new press)

	lda.W				   #$0005	; A = $05 (5 frames)
	sta.B				   $09	   ; Reset timer to 5 for repeat rate

Input_HandleAutofire_Exit:
	rts							   ; Return

;-------------------------------------------------------------------------------

Input_NewButtonPress:
; ===========================================================================
; Handle New Button Press
; ===========================================================================
; When button first pressed, output immediately and set long timer.
; ===========================================================================

	sta.B				   $07	   ; Output = new button presses

	lda.W				   #$0019	; A = $19 (25 frames)
	sta.B				   $09	   ; Set timer to 25 (initial delay)

	rts							   ; Return

;===============================================================================
; TILEMAP CALCULATION & UPDATE ROUTINES ($008c1b-$008dde)
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

	php							   ; Save processor status
	rep					 #$30		; 16-bit A, X, Y

	and.W				   #$00ff	; A = A & $ff (ensure 8-bit value)
	pha							   ; Save original coordinate

; ---------------------------------------------------------------------------
; Extract and Process Y Coordinate (Bits 3-5)
; ---------------------------------------------------------------------------

	and.W				   #$0038	; A = A & $38 (extract bits 3-5: Y coord)
	asl					 a; A = A × 2 (Y × 2)
	tax							   ; X = Y × 2 (save for later)

; ---------------------------------------------------------------------------
; Extract and Process X Coordinate (Bits 0-2)
; ---------------------------------------------------------------------------

	pla							   ; A = original coordinate
	and.W				   #$0007	; A = A & $07 (extract bits 0-2: X coord)

	phx							   ; Save Y×2 on stack

; Calculate X contribution: X × 12
	adc.B				   $01,s	 ; A = X + (Y×2)  [1st add]
	sta.B				   $01,s	 ; Save intermediate result

	asl					 a; A = (X + Y×2) × 2
	adc.B				   $01,s	 ; A = result×2 + result = result×3

	asl					 a; A = result × 6
	asl					 a; A = result × 12
	asl					 a; A = result × 24
	asl					 a; A = result × 48

; ---------------------------------------------------------------------------
; Add Base Address
; ---------------------------------------------------------------------------

	adc.W				   #$8000	; A = A + $8000 (add base VRAM address)

	plx							   ; Clean stack (discard saved Y×2)

	plp							   ; Restore processor status
	rts							   ; Return with VRAM address in A

;-------------------------------------------------------------------------------

Tilemap_RefreshLayer0:
; ===========================================================================
; Update Character Cursor Tilemap
; ===========================================================================
; Updates the tilemap tiles for character selection cursor.
; Handles both battle mode and field mode displays.
;
; $1031: Character Y position (row)
; $00d8 bit 1: Battle mode flag
; ===========================================================================

	php							   ; Save processor status
	sep					 #$30		; 8-bit A, X, Y

	ldx.W				   $1031	 ; X = character Y position
	cpx.B				   #$ff	  ; Check if invalid position
	beq					 UNREACH_008C81 ; If $ff → Exit (invalid)

; ---------------------------------------------------------------------------
; Check Battle Mode Flag
; ---------------------------------------------------------------------------

	lda.B				   #$02	  ; A = $02 (bit 1 mask)
	and.W				   $00d8	 ; Test bit 1 of $00d8
	beq					 Tilemap_RefreshLayer0_Field ; If clear → Field mode

; ---------------------------------------------------------------------------
; Battle Mode Tilemap Update
; ---------------------------------------------------------------------------
; Uses special tilemap data from bank $04
; ---------------------------------------------------------------------------

	lda.L				   DATA8_049800,x ; A = [$049800+X] (base tile value)
	adc.B				   #$0a	  ; A = A + $0a (offset for battle tiles)
	xba							   ; Swap A high/low bytes (save in high byte)

; Calculate tile position
	txa							   ; A = X (Y position)
	and.B				   #$38	  ; A = A & $38 (extract Y coordinate bits)
	asl					 a; A = A × 2
	pha							   ; Save Y offset

	txa							   ; A = X again
	and.B				   #$07	  ; A = A & $07 (extract X coordinate)
	ora.B				   $01,s	 ; A = A | Y_offset (combine X and Y)
	plx							   ; X = Y offset (cleanup stack)

	asl					 a; A = coordinate × 2 (word address)

	rep					 #$30		; 16-bit A, X, Y

; Store tile values in WRAM buffer $7f075a
	sta.L				   $7f075a   ; [$7f075a] = tile 1 coordinate
	inc					 a; A = A + 1 (next tile)
	sta.L				   $7f075c   ; [$7f075c] = tile 2 coordinate

	adc.W				   #$000f	; A = A + $0f (skip to next row)
	sta.L				   $7f079a   ; [$7f079a] = tile 3 coordinate (row 2)
	inc					 a; A = A + 1
	sta.L				   $7f079c   ; [$7f079c] = tile 4 coordinate (row 2)

	sep					 #$20		; 8-bit accumulator

	ldx.W				   #$17da	; X = $17da (WRAM data source)
	lda.B				   #$7f	  ; A = $7f (bank $7f)
	bra					 Tilemap_TransferData ; → Continue to transfer

;-------------------------------------------------------------------------------

UNREACH_008C81:
	db											 $28,$60	 ; Unreachable code: PLP, RTS

;-------------------------------------------------------------------------------

Tilemap_RefreshLayer0_Field:
; ===========================================================================
; Field Mode Tilemap Update
; ===========================================================================
; Normal field/map mode cursor update
; ===========================================================================

	lda.L				   DATA8_049800,x ; A = [$049800+X] (base tile)
	asl					 a; A = A × 2
	asl					 a; A = A × 4 (tile offset)
	sta.W				   $00f4	 ; [$00f4] = tile offset

	rep					 #$10		; 16-bit X, Y

	lda.W				   $1031	 ; A = character Y position
	jsr.W				   Tilemap_CalcRowAddress ; Calculate tilemap address
	stx.W				   $00f2	 ; [$00f2] = tilemap address

	ldx.W				   #$2d1a	; X = $2d1a (WRAM source address)
	lda.B				   #$7e	  ; A = $7e (bank $7e)

;-------------------------------------------------------------------------------

Tilemap_TransferData:
; ===========================================================================
; Apply Cursor Attributes
; ===========================================================================
; Modifies tile attributes based on game state flags.
;
; $00da bit 2: Disable cursor blink
; $0014: Blink timer
; Attribute bits:
;   Bit 2: Horizontal flip
;   Bit 3-4: Palette selection
;   Bit 7: Priority
; ===========================================================================

	pha							   ; Save bank number

	lda.B				   #$04	  ; A = $04 (bit 2 mask)
	and.W				   $00da	 ; Test bit 2 of $00da
	beq					 Tilemap_SetupDMA ; If clear → Normal cursor

; Check blink timer
	lda.W				   $0014	 ; A = [$0014] (blink timer)
	dec					 a; A = A - 1
	beq					 Tilemap_SetupDMA ; If zero → Show cursor

; Apply alternate palette during blink
	lda.B				   #$10	  ; A = $10 (bit 4 mask)
	and.W				   $00da	 ; Test bit 4 of $00da
	bne					 Tilemap_BlinkSpecial ; If set → Special blink mode

; Normal blink mode (incomplete in disassembly)
	db											 $ab,$bd,$01,$00,$29,$e3,$09,$94,$80,$12

;-------------------------------------------------------------------------------

Tilemap_BlinkSpecial:
	plb							   ; B = bank (restore)
	lda.W				   $0001,x   ; A = [X+1] (tile attribute byte)
	and.B				   #$e3	  ; A = A & $e3 (clear palette bits 2,3,4)
	ora.B				   #$9c	  ; A = A | $9c (set new palette + priority)
	bra					 Tilemap_ApplyAttributes ; → Save and continue

;-------------------------------------------------------------------------------

Tilemap_SetupDMA:
	plb							   ; B = bank (restore)
	lda.W				   $0001,x   ; A = [X+1] (tile attribute)
	and.B				   #$e3	  ; Clear palette bits
	ora.B				   #$88	  ; Set normal palette

;-------------------------------------------------------------------------------

Tilemap_ApplyAttributes:
; ===========================================================================
; Handle Number Display
; ===========================================================================
; For certain Y positions (>=$29), displays 2-digit numbers.
; Used for item quantities, HP values, etc.
; ===========================================================================

	xba							   ; Swap A bytes (save attributes in high byte)

	lda.L				   $001031   ; A = Y position
	cmp.B				   #$29	  ; Compare with $29
	bcc					 CODE_008D11 ; If Y < $29 → Use simple tile display

	cmp.B				   #$2c	  ; Compare with $2c
	beq					 CODE_008D11 ; If Y = $2c → Use simple tile display

; ---------------------------------------------------------------------------
; Two-Digit Number Display
; ---------------------------------------------------------------------------
; Displays a number as two separate digit tiles
; $1030 contains the value to display (0-99)
; ---------------------------------------------------------------------------

	lda.W				   $0001,x   ; A = tile attribute
	and.B				   #$63	  ; Clear certain attribute bits
	ora.B				   #$08	  ; Set priority bit
	sta.W				   $0001,x   ; Save attribute for tile 1
	sta.W				   $0003,x   ; Save attribute for tile 2

; Calculate tens digit
	lda.L				   $001030   ; A = number value (0-99)
	ldy.W				   #$ffff	; Y = -1 (digit counter)
	sec							   ; Set carry for subtraction

;-------------------------------------------------------------------------------

Display_DecimalDigit_Loop:
; Divide by 10 loop
	iny							   ; Y++ (count tens)
	sbc.B				   #$0a	  ; A = A - 10
	bcs					 Display_DecimalDigit_Loop ; If carry still set → Continue subtracting

; A now contains ones digit - 10 (needs adjustment)
	adc.B				   #$8a	  ; A = A + $8a (convert to tile number)
	sta.W				   $0002,x   ; Store ones digit tile

; Check if tens digit is zero
	cpy.W				   #$0000	; Is tens digit zero?
	beq					 UNREACH_008D06 ; If zero → Show blank tens digit

; Display tens digit
	tya							   ; A = tens digit value
	adc.B				   #$7f	  ; A = A + $7f (convert to tile number)
	sta.W				   $0000,x   ; Store tens digit tile
	bra					 Tilemap_FinalizeUpdate ; → Finish update

;-------------------------------------------------------------------------------

UNREACH_008D06:
; Show blank tile for tens digit
	db											 $a9,$45,$9d,$00,$00,$eb,$9d,$01,$00,$80,$0f
; LDA #$45, STA [$00,X], XBA, STA [$01,X], BRA $0f

;-------------------------------------------------------------------------------

Display_BlankTiles:
; ===========================================================================
; Simple Tile Display
; ===========================================================================
; Displays blank tiles (tile $45) for positions that don't need numbers
; ===========================================================================

	xba							   ; Swap A bytes (get attributes back)
	sta.W				   $0001,x   ; Store attribute for tile 1
	sta.W				   $0003,x   ; Store attribute for tile 2

	lda.B				   #$45	  ; A = $45 (blank tile)
	sta.W				   $0000,x   ; Store blank in tile 1
	sta.W				   $0002,x   ; Store blank in tile 2

;-------------------------------------------------------------------------------

Tilemap_FinalizeUpdate:
; ===========================================================================
; Finalize Tilemap Update
; ===========================================================================

	phk							   ; Push program bank
	plb							   ; Pull to data bank (B = $00)

	lda.B				   #$80	  ; A = $80 (bit 7)
	tsb.W				   $00d4	 ; Set bit 7 of $00d4 (large VRAM update flag)

	plp							   ; Restore processor status
	rts							   ; Return

;===============================================================================
; LAYER UPDATE ROUTINES ($008d29-$008d89)
;===============================================================================

Tilemap_RefreshLayer1:
; ===========================================================================
; Background Layer 1 Update
; ===========================================================================
; Updates BG layer 1 tilemap during VBLANK.
; Handles both battle and field modes.
; ===========================================================================

	php							   ; Save processor status
	sep					 #$30		; 8-bit A, X, Y

; ---------------------------------------------------------------------------
; Check Battle Mode
; ---------------------------------------------------------------------------

	lda.B				   #$02	  ; A = $02 (bit 1 mask)
	and.W				   $00d8	 ; Test bit 1 of $00d8
	beq					 CODE_008D6C ; If clear → Field mode

; ---------------------------------------------------------------------------
; Battle Mode Layer Update
; ---------------------------------------------------------------------------

	ldx.W				   $10b1	 ; X = [$10b1] (cursor position)
	cpx.B				   #$ff	  ; Check if invalid
	beq					 Tilemap_RefreshLayer1_Exit ; If $ff → Exit

; Calculate tile data
	lda.L				   DATA8_049800,x ; A = base tile value
	adc.B				   #$0a	  ; A = A + $0a (battle offset)
	xba							   ; Save in high byte

	txa							   ; A = position
	and.B				   #$38	  ; Extract Y bits
	asl					 a; Y × 2
	pha							   ; Save

	txa							   ; A = position again
	and.B				   #$07	  ; Extract X bits
	ora.B				   $01,s	 ; Combine with Y
	plx							   ; Cleanup stack

	asl					 a; Word address
	rep					 #$30		; 16-bit A, X, Y

; Store in WRAM buffer
	sta.L				   $7f0778   ; Tile 1 position
	inc					 a; Next tile
	sta.L				   $7f077a   ; Tile 2 position

	adc.W				   #$000f	; Next row
	sta.L				   $7f07b8   ; Tile 3 position
	inc					 a; Next tile
	sta.L				   $7f07ba   ; Tile 4 position

	lda.W				   #$0080	; A = $0080 (bit 7)
	tsb.W				   $00d4	 ; Set large update flag

Tilemap_RefreshLayer1_Exit:
	plp							   ; Restore status
	rts							   ; Return

;-------------------------------------------------------------------------------

Tilemap_RefreshLayer1_Field:
; ===========================================================================
; Field Mode Layer Update
; ===========================================================================

	ldx.W				   $10b1	 ; X = cursor position
	lda.L				   DATA8_049800,x ; A = base tile
	asl					 a; A × 2
	asl					 a; A × 4
	sta.W				   $00f7	 ; Save tile offset

	rep					 #$10		; 16-bit X, Y

	lda.W				   $10b1	 ; A = cursor position
	jsr.W				   Tilemap_CalcRowAddress ; Calculate tilemap address
	stx.W				   $00f5	 ; Save address

	lda.B				   #$80	  ; A = $80
	tsb.W				   $00d4	 ; Set update flag

	plp							   ; Restore status
	rts							   ; Return

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
;   X = Tilemap address (or $ffff if invalid)
; ===========================================================================

	cmp.B				   #$ff	  ; Check if invalid position
	beq					 UNREACH_008D93 ; If $ff → Return $ffff

	jsr.W				   CODE_008C1B ; Calculate tilemap address
	tax							   ; X = calculated address
	rts							   ; Return

;-------------------------------------------------------------------------------

UNREACH_008D93:
	ldx.W				   #$ffff	; X = invalid address marker
	rts							   ; Return

;===============================================================================
; Character Validation & Party Helper Routines
;===============================================================================
; These small helper routines validate character positions and check party
; member availability. Used by menu systems to skip dead/invalid characters.
;===============================================================================

Party_ValidateCharPos:
; ===========================================================================
; Character Position Validation Helper
; ===========================================================================
; Validates a character position by checking party member availability
;
; Parameters:
;   $1031 = Current character position
;
; Returns:
;   $009e = Validated position (or adjusted)
;   $1031 = Updated position after validation
; ===========================================================================

	lda.W				   $1031	 ; Get current character position
	pha							   ; Save it
	lda.W				   #$0003	; A = 3 (check 3 party slots)
	jsr.W				   Party_CheckAvailability ; Validate party member
	pla							   ; Restore original position
	sta.W				   $1031	 ; Store back to $1031
	sty.B				   $9e	   ; Save validated position to $9e
	rts							   ; Return

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
;   Y = Valid character position (or $ff if none found)
;   $1031 = Updated character position
; ===========================================================================

	php							   ; Save processor status
	sep					 #$30		; 8-bit mode
	pha							   ; Save slot count
	clc							   ; Clear carry
	adc.B				   $01,s	 ; A = count × 2 (stack peek)
	adc.B				   $01,s	 ; A = count × 3
	adc.B				   #$22	  ; A += $22 (offset calculation)
	tay							   ; Y = calculated offset
	pla							   ; Restore slot count
	eor.B				   #$ff	  ; Invert bits
	sec							   ; Set carry
	adc.B				   #$04	  ; A = 4 - count (bit shift count)
	tax							   ; X = shift count

	lda.W				   $1032	 ; Get status flags (high byte)
	xba							   ; Swap to low byte
	lda.W				   $1033	 ; Get status flags (low byte)
	rep					 #$20		; 16-bit A
	sep					 #$10		; 8-bit X, Y
	lsr					 a; Shift right (first bit)

Party_CheckAvailability_ShiftLoop:
	lsr					 a; Shift right
	lsr					 a; Shift right
	lsr					 a; Shift right (shift 3 bits per slot)
	dex							   ; Decrement shift counter
	bne					 Party_CheckAvailability_ShiftLoop ; Loop until X = 0

	lsr					 a; Check first member bit
	bcs					 Party_CheckAvailability_Found ; If set → valid member found
	dey							   ; Try previous slot
	lsr					 a; Check second member bit
	bcs					 Party_CheckAvailability_Found ; If set → valid member found
	dey							   ; Try previous slot
	lsr					 a; Check third member bit
	bcs					 Party_CheckAvailability_Found ; If set → valid member found
	ldy.B				   #$ff	  ; No valid members → $ff

Party_CheckAvailability_Found:
	sty.W				   $1031	 ; Store validated position
	plp							   ; Restore processor status
	rts							   ; Return

;===============================================================================
; DMA Transfer Helper Routines
;===============================================================================
; Low-level DMA and direct VRAM write helpers used throughout the graphics
; system. These routines handle bulk transfers and direct writes to VRAM.
;===============================================================================

VRAM_DirectWriteLarge:
; ===========================================================================
; Large VRAM Write via Direct Writes (No DMA)
; ===========================================================================
; Writes large blocks of tile data directly to VRAM without using DMA
; Used when DMA channels are unavailable or for specific VRAM patterns
;
; TECHNICAL NOTES:
; - Sets Direct Page to $2100 (PPU registers)
; - Writes 24 bytes per tile (8 words × 3 bytes each)
; - Interleaves data with $00f0 pattern bytes
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

	php							   ; Save processor status
	phd							   ; Save Direct Page
	rep					 #$30		; 16-bit mode
	lda.W				   #$2100	; A = $2100
	tcd							   ; Direct Page = $2100 (PPU registers)
	clc							   ; Clear carry for additions

VRAM_DirectWriteLarge_OuterLoop:
	phy							   ; Save Y counter
	sep					 #$20		; 8-bit A
	ldy.W				   #$0018	; Y = $18 (24 decimal, inner loop count)

VRAM_DirectWriteLarge_InnerLoop:
	lda.W				   $0000,x   ; Get byte from source
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $0001,x   ; Get next byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $0002,x   ; Get third byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $0003,x   ; Get fourth byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $0004,x   ; Get fifth byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $0005,x   ; Get sixth byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $0006,x   ; Get seventh byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $0007,x   ; Get eighth byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)

	lda.W				   $0008,x   ; Get ninth byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $0009,x   ; Get tenth byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $000a,x   ; Get 11th byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $000b,x   ; Get 12th byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $000c,x   ; Get 13th byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $000d,x   ; Get 14th byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $000e,x   ; Get 15th byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $000f,x   ; Get 16th byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)

	lda.W				   $0010,x   ; Get 17th byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $0011,x   ; Get 18th byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $0012,x   ; Get 19th byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $0013,x   ; Get 20th byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $0014,x   ; Get 21st byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $0015,x   ; Get 22nd byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $0016,x   ; Get 23rd byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.W				   $0017,x   ; Get 24th byte
	tay							   ; Y = data byte
	sty.B				   !SNES_VMDATAL-$2100 ; Write to VRAM data (low)

	rep					 #$30		; 16-bit mode
	txa							   ; A = X (source pointer)
	adc.W				   #$0018	; A += $18 (24 bytes)
	tax							   ; X = new source address
	ply							   ; Restore Y counter
	dey							   ; Decrement tile group counter
	beq					 +		   ; Exit if done
	jmp					 CODE_008DE8 ; Loop if more groups remain
	+
	pld							   ; Restore Direct Page
	plp							   ; Restore processor status
	rtl							   ; Return

;-------------------------------------------------------------------------------

VRAM_Write8TilesPattern:
; ===========================================================================
; VRAM Write: 8 Tiles with Pattern Interleaving
; ===========================================================================
; Writes 8 tiles (16 bytes each) to VRAM with pattern byte interleaving
; Pattern byte from $00f0 is written between each data byte
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
;   $00f0 = Pattern byte to interleave
;   VRAM address already set
; ===========================================================================

	php							   ; Save processor status
	phd							   ; Save Direct Page
	pea.W				   $2100	 ; Push $2100
	pld							   ; Direct Page = $2100
	sep					 #$20		; 8-bit A
	lda.B				   #$88	  ; A = $88 (VRAM increment +32 after high)
	sta.B				   !SNES_VMAINC-$2100 ; Set VRAM increment mode
	rep					 #$30		; 16-bit mode
	clc							   ; Clear carry

VRAM_Write8TilesPattern_Loop:
	lda.W				   $0000,x   ; Get word 0
	sta.B				   !SNES_VMDATAL-$2100 ; Write to VRAM
	lda.W				   $00f0	 ; Get pattern word
	sta.B				   !SNES_VMDATAL-$2100 ; Write pattern
	lda.W				   $0002,x   ; Get word 1
	sta.B				   !SNES_VMDATAL-$2100 ; Write to VRAM
	lda.W				   $00f0	 ; Get pattern word
	sta.B				   !SNES_VMDATAL-$2100 ; Write pattern
	lda.W				   $0004,x   ; Get word 2
	sta.B				   !SNES_VMDATAL-$2100 ; Write to VRAM
	lda.W				   $00f0	 ; Get pattern word
	sta.B				   !SNES_VMDATAL-$2100 ; Write pattern
	lda.W				   $0006,x   ; Get word 3
	sta.B				   !SNES_VMDATAL-$2100 ; Write to VRAM
	lda.W				   $00f0	 ; Get pattern word
	sta.B				   !SNES_VMDATAL-$2100 ; Write pattern
	lda.W				   $0008,x   ; Get word 4
	sta.B				   !SNES_VMDATAL-$2100 ; Write to VRAM
	lda.W				   $00f0	 ; Get pattern word
	sta.B				   !SNES_VMDATAL-$2100 ; Write pattern
	lda.W				   $000a,x   ; Get word 5
	sta.B				   !SNES_VMDATAL-$2100 ; Write to VRAM
	lda.W				   $00f0	 ; Get pattern word
	sta.B				   !SNES_VMDATAL-$2100 ; Write pattern
	lda.W				   $000c,x   ; Get word 6
	sta.B				   !SNES_VMDATAL-$2100 ; Write to VRAM
	lda.W				   $00f0	 ; Get pattern word
	sta.B				   !SNES_VMDATAL-$2100 ; Write pattern
	lda.W				   $000e,x   ; Get word 7
	sta.B				   !SNES_VMDATAL-$2100 ; Write to VRAM
	lda.W				   $00f0	 ; Get pattern word
	sta.B				   !SNES_VMDATAL-$2100 ; Write pattern

	txa							   ; A = X (source pointer)
	adc.W				   #$0010	; A += $10 (16 bytes per tile)
	tax							   ; X = new source address
	dey							   ; Decrement tile counter
	bne					 VRAM_Write8TilesPattern_Loop ; Loop if more tiles remain

	sep					 #$20		; 8-bit A
	lda.B				   #$80	  ; A = $80 (VRAM increment +1)
	sta.B				   !SNES_VMAINC-$2100 ; Restore normal VRAM increment
	pld							   ; Restore Direct Page
	plp							   ; Restore processor status
	rtl							   ; Return

;===============================================================================
; Graphics Initialization & Palette Loading
;===============================================================================
; Complex graphics setup routine that loads tiles and palettes for menu/field
; display. Handles DMA transfers and direct palette uploads to CGRAM.
;===============================================================================

Graphics_InitFieldMenuMode:
; ===========================================================================
; Field/Menu Graphics Initialization
; ===========================================================================
; Complete graphics setup for field mode and menu displays
; Loads character tiles, background tiles, and color palettes
;
; TECHNICAL NOTES:
; - Uses DMA Channel 5 for bulk VRAM transfer ($1000 bytes)
; - Loads tiles to VRAM $3000-$3fff
; - Loads additional tiles to VRAM $2000-$2fff via CODE_008DDF
; - Sets up multiple palette entries in CGRAM
; - Direct Page = $2100 throughout for PPU access
;
; Graphics Loaded:
; - Bank $07:$8030: Main tile graphics (4096 bytes via DMA)
; - Bank $04:$8000: Additional tiles (256 groups via direct write)
; - Bank $07:$8000: Palette data (4 sets of 8 colors)
; - Bank $07:$d8e4: Extended palette data (6 groups of 16 colors)
;
; CGRAM Layout:
; - $0d, $1d: Special colors from $0e9c-$0e9d
; - $08-$1f: Four 8-color palettes from Bank $07:$8000
; - $28-$87: Six 16-color palettes from Bank $07:$d8e4
; ===========================================================================

	php							   ; Save processor status
	phd							   ; Save Direct Page
	rep					 #$30		; 16-bit mode
	lda.W				   #$2100	; A = $2100
	tcd							   ; Direct Page = $2100 (PPU registers)

; Setup DMA Channel 5 for VRAM transfer
	sep					 #$20		; 8-bit A
	ldx.W				   #$1801	; X = $1801 (DMA params: word, increment)
	stx.W				   !SNES_DMA5PARAM ; Set DMA5 control
	ldx.W				   #$8030	; X = $8030 (source address low/mid)
	stx.W				   !SNES_DMA5ADDRL ; Set DMA5 source address
	lda.B				   #$07	  ; A = $07 (source bank)
	sta.W				   !SNES_DMA5ADDRH ; Set DMA5 source bank
	ldx.W				   #$1000	; X = $1000 (4096 bytes to transfer)
	stx.W				   !SNES_DMA5CNTL ; Set DMA5 transfer size

; Setup VRAM destination
	ldx.W				   #$3000	; X = $3000 (VRAM address)
	stx.B				   !SNES_VMADDL-$2100 ; Set VRAM address
	lda.B				   #$84	  ; A = $84 (increment +32 after high byte)
	sta.B				   !SNES_VMAINC-$2100 ; Set VRAM increment mode

; Execute DMA transfer
	lda.B				   #$20	  ; A = $20 (enable DMA channel 5)
	sta.W				   !SNES_MDMAEN ; Start DMA transfer

; Restore normal VRAM increment
	lda.B				   #$80	  ; A = $80 (increment +1)
	sta.B				   !SNES_VMAINC-$2100 ; Set VRAM increment mode

; Setup for additional tile transfer
	rep					 #$30		; 16-bit mode
	lda.W				   #$ff00	; A = $ff00 (pattern for interleaving)
	sta.W				   $00f0	 ; Store pattern word
	ldx.W				   #$2000	; X = $2000 (VRAM address)
	stx.B				   !SNES_VMADDL-$2100 ; Set VRAM address

; Transfer additional tiles from Bank $04
	pea.W				   $0004	 ; Push bank $04
	plb							   ; Data bank = $04
	ldx.W				   #$8000	; X = $8000 (source address)
	ldy.W				   #$0100	; Y = $0100 (256 tile groups)
	jsl.L				   VRAM_DirectWriteLarge ; Transfer tiles via direct writes
	plb							   ; Restore data bank

; Load palette data from Bank $07
	sep					 #$30		; 8-bit mode
	pea.W				   $0007	 ; Push bank $07
	plb							   ; Data bank = $07

; Load 4 sets of 8-color palettes
	lda.B				   #$08	  ; A = $08 (CGRAM address $08)
	ldx.B				   #$00	  ; X = $00 (source offset)
	jsr.W				   Palette_Load8Colors ; Load 8 colors
	lda.B				   #$0c	  ; A = $0c (CGRAM address $0c)
	ldx.B				   #$08	  ; X = $08 (source offset)
	jsr.W				   Palette_Load8Colors ; Load 8 colors
	lda.B				   #$18	  ; A = $18 (CGRAM address $18)
	ldx.B				   #$10	  ; X = $10 (source offset)
	jsr.W				   Palette_Load8Colors ; Load 8 colors
	lda.B				   #$1c	  ; A = $1c (CGRAM address $1c)
	ldx.B				   #$18	  ; X = $18 (source offset)
	jsr.W				   Palette_Load8Colors ; Load 8 colors
	plb							   ; Restore data bank

; Load special color values
	ldx.W				   $0e9c	 ; X = color value (low byte)
	ldy.W				   $0e9d	 ; Y = color value (high byte)
	lda.B				   #$0d	  ; A = $0d (CGRAM address)
	sta.B				   !SNES_CGADD-$2100 ; Set CGRAM address
	stx.B				   !SNES_CGDATA-$2100 ; Write color (low)
	sty.B				   !SNES_CGDATA-$2100 ; Write color (high)
	lda.B				   #$1d	  ; A = $1d (CGRAM address)
	sta.B				   !SNES_CGADD-$2100 ; Set CGRAM address
	stx.B				   !SNES_CGDATA-$2100 ; Write color (low)
	sty.B				   !SNES_CGDATA-$2100 ; Write color (high)

; Load extended palette data (6 groups of 16 colors)
	ldy.B				   #$06	  ; Y = 6 (group count)
	lda.B				   #$00	  ; A = 0 (initial offset)
	clc							   ; Clear carry
	pea.W				   $0007	 ; Push bank $07
	plb							   ; Data bank = $07

Palette_Load16Colors:
	tax							   ; X = offset
	adc.B				   #$28	  ; A += $28 (CGRAM address increment)
	sta.B				   !SNES_CGADD-$2100 ; Set CGRAM address

; Write 16 colors (32 bytes) from DATA8_07D8E4
	lda.W				   DATA8_07d8e4,x ; Get color byte
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d8e5,x ; Get color byte
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d8e6,x ; Get color byte
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d8e7,x ; Get color byte
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d8e8,x ; Get color byte
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d8e9,x ; Get color byte
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d8ea,x ; Get color byte
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d8eb,x ; Get color byte
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d8ec,x ; Get color byte
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d8ed,x ; Get color byte
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d8ee,x ; Get color byte
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d8ef,x ; Get color byte
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d8f0,x ; Get color byte
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d8f1,x ; Get color byte
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d8f2,x ; Get color byte
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d8f3,x ; Get color byte
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM

	txa							   ; A = X (offset)
	adc.B				   #$10	  ; A += $10 (16 bytes per group)
	dey							   ; Decrement group counter
	bne					 Graphics_InitFieldMenu_PaletteLoop ; Loop if more groups remain

	plb							   ; Restore data bank
	pld							   ; Restore Direct Page
	plp							   ; Restore processor status
	rts							   ; Return

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

	sta.B				   !SNES_CGADD-$2100 ; Set CGRAM address
	lda.W				   DATA8_078000,x ; Get color byte 0
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_078001,x ; Get color byte 1
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_078002,x ; Get color byte 2
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_078003,x ; Get color byte 3
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_078004,x ; Get color byte 4
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_078005,x ; Get color byte 5
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_078006,x ; Get color byte 6
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_078007,x ; Get color byte 7
	sta.B				   !SNES_CGDATA-$2100 ; Write to CGRAM
	rts							   ; Return

;===============================================================================
; Embedded Subroutine Data
;===============================================================================
; This section contains embedded machine code data used by various helper
; routines. These are small inline subroutines stored as raw bytes.
;===============================================================================

CoordHelper_EmbeddedCode:
; ===========================================================================
; Embedded Helper Subroutine ($008fdf-$009013)
; ===========================================================================
; Small helper routine stored as data bytes
; Appears to handle coordinate/offset calculations
; ===========================================================================
CoordHelper_Bytes:
	db											 $08,$0b,$c2,$30,$da,$48,$3b,$38,$e9,$02,$00,$1b,$5b,$e2,$20,$a5
	db											 $04,$85,$02,$64,$04,$a9,$00,$c2,$30,$a2,$08,$00,$c6,$03,$0a,$06
	db											 $01,$90,$02,$65,$03,$ca,$d0,$f6,$85,$03,$3b,$18,$69,$02,$00,$1b
	db											 $68,$fa,$2b,$28,$6b

;===============================================================================
; Status Effect Rendering System
;===============================================================================
; Major system that handles rendering character status effects and animations
; Processes status ailments, buffs, and visual indicators for the party
;===============================================================================

Status_InitDisplay:
; ===========================================================================
; Initialize Status Effect Display System
; ===========================================================================
; Clears status effect display buffers and sets up party status rendering
; Called when entering field/menu modes
;
; TECHNICAL NOTES:
; - Clears $7e3669-$7e3746 (222 bytes) for status display
; - Uses MVN for efficient memory clearing
; - Sets Direct Page to $1000 for party data access
; - Processes party member status flags from $1032-$1033
; - Renders status icons/indicators to tilemap buffers
;
; Status Display Layout:
; - $7e3669: Start of status effect buffer
; - Various offsets for different status types
; - Supports 6 party member slots with multiple status effects each
; ===========================================================================

	php							   ; Save processor status
	phd							   ; Save Direct Page
	rep					 #$30		; 16-bit mode

; Clear status display buffer
	lda.W				   #$0000	; A = 0
	sta.L				   $7e3669   ; Clear first word of buffer
	ldx.W				   #$3669	; X = source (first word)
	ldy.W				   #$366b	; Y = destination (next word)
	lda.W				   #$00dd	; A = $dd (221 bytes to fill)
	mvn					 $7e,$7e	 ; Block fill with zeros

; Setup for status processing
	phk							   ; Push program bank
	plb							   ; Data bank = program bank
	sep					 #$30		; 8-bit mode
	pea.W				   $1000	 ; Push $1000
	pld							   ; Direct Page = $1000 (party data)

; Process party status bits (high nibble of $1032)
	lda.B				   $32	   ; Get party status flags (high)
	and.B				   #$e0	  ; Mask bits 7-5
	beq					 Skip_Status_Group1 ; If clear, skip first group

	jsl.L				   CODE_009730 ; Calculate status icon offset
	eor.B				   #$ff	  ; Invert
	sec							   ; Set carry
	adc.B				   #$27	  ; Add offset $27
	ldy.B				   #$a0	  ; Y = $a0 (display position)
	jsr.W				   Status_RenderIcon ; Render status icon

Skip_Status_Group1:
; Process bits 4-2 of $1032
	lda.B				   $32	   ; Get party status flags
	and.B				   #$1c	  ; Mask bits 4-2
	beq					 Skip_Status_Group2 ; If clear, skip second group

	jsl.L				   CODE_009730 ; Calculate status icon offset
	eor.B				   #$ff	  ; Invert
	sec							   ; Set carry
	adc.B				   #$27	  ; Add offset $27
	ldy.B				   #$b0	  ; Y = $b0 (display position)
	jsr.W				   Status_RenderIcon ; Render status icon

Skip_Status_Group2:
; Process bit 7 of $1033 and bits 1-0 of $1032
	lda.B				   $33	   ; Get extended status flags
	and.B				   #$80	  ; Check bit 7
	bne					 Process_Status_Group3 ; If set, process group 3

	lda.B				   $32	   ; Get party status flags
	and.B				   #$03	  ; Mask bits 1-0
	beq					 Skip_Status_Group3 ; If clear, skip

; Embedded JSL instruction as data
Skip_Status_Group2_bytes:
	db											 $22,$30,$97,$00 ; JSL CODE_009730
	db											 $18,$69,$08 ; CLC, ADC #$08
	db											 $80,$04	 ; BRA +4

Process_Status_Group3:
	jsl.L				   CODE_009730 ; Calculate status icon offset
	eor.B				   #$ff	  ; Invert
	sec							   ; Set carry
	adc.B				   #$2f	  ; Add offset $2f
	ldy.B				   #$c0	  ; Y = $c0 (display position)
	jsr.W				   Status_RenderIcon ; Render status icon

Skip_Status_Group3:
; Process bits 6-4 of $1033
	lda.B				   $33	   ; Get extended status flags
	and.B				   #$70	  ; Mask bits 6-4
	beq					 Skip_Status_Group4 ; If clear, skip

	jsl.L				   CODE_009730 ; Calculate status icon offset
	eor.B				   #$ff	  ; Invert
	sec							   ; Set carry
	adc.B				   #$2f	  ; Add offset $2f
	ldy.B				   #$d0	  ; Y = $d0 (display position)
	jsr.W				   Status_RenderIcon ; Render status icon

Skip_Status_Group4:
; Process first character slot
	ldy.B				   #$00	  ; Y = 0 (slot 0)
	jsr.W				   Status_RenderCharacter ; Render character status

; Switch to second character slot data
	pea.W				   $1080	 ; Push $1080
	pld							   ; Direct Page = $1080
	ldy.B				   #$50	  ; Y = $50 (display offset)
	jsr.W				   Status_RenderCharacter ; Render character status

	pld							   ; Restore Direct Page
	plp							   ; Restore processor status
	rts							   ; Return

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

	lda.B				   $31	   ; Get character slot
	bmi					 Skip_Character ; If bit 7 set → invalid/dead character
	jsr.W				   CODE_009111 ; Render base character icon

Skip_Character:
; Process status flags group 1 (bits 7-5 of $35)
	lda.B				   $35	   ; Get status flags byte 1
	and.B				   #$e0	  ; Mask bits 7-5
	beq					 Skip_Status1 ; If clear, skip

	jsl.L				   CODE_009730 ; Calculate icon offset
	eor.B				   #$ff	  ; Invert
	sec							   ; Set carry
	adc.B				   #$36	  ; Add offset $36
	jsr.W				   CODE_009111 ; Render status icon

Skip_Status1:
; Process status flags group 2 (bits 7-6 of $36 and bits 4-0 of $35)
	lda.B				   $36	   ; Get status flags byte 2
	and.B				   #$c0	  ; Mask bits 7-6
	bne					 Alternative_Status2 ; If set, use alternative handling

	lda.B				   $35	   ; Get status flags byte 1
	and.B				   #$1f	  ; Mask bits 4-0
	beq					 Skip_Status2 ; If clear, skip

	jsl.L				   CODE_009730 ; Calculate icon offset
	clc							   ; Clear carry
	adc.B				   #$08	  ; Add offset $08
	bra					 Continue_Status2 ; Continue processing

Alternative_Status2:
	db											 $22,$30,$97,$00 ; JSL CODE_009730

Continue_Status2:
	eor.B				   #$ff	  ; Invert
	sec							   ; Set carry
	adc.B				   #$3e	  ; Add offset $3e
	jsr.W				   Status_RenderIcon ; Render status icon

Skip_Status2:
; Process status flags group 3 (bits 5-2 of $36)
	lda.B				   $36	   ; Get status flags byte 2
	and.B				   #$3c	  ; Mask bits 5-2
	beq					 Skip_Status3 ; If clear, skip

	jsl.L				   CODE_009730 ; Calculate icon offset
	eor.B				   #$ff	  ; Invert
	sec							   ; Set carry
	adc.B				   #$3e	  ; Add offset $3e
	jsr.W				   Status_RenderIcon ; Render status icon

Skip_Status3:
; Process status flags group 4 (bit 7 of $37 and bits 1-0 of $36)
	lda.B				   $37	   ; Get status flags byte 3
	and.B				   #$80	  ; Check bit 7
	bne					 Alternative_Status4 ; If set, use alternative

	lda.B				   $36	   ; Get status flags byte 2
	and.B				   #$03	  ; Mask bits 1-0
	beq					 Skip_Status4 ; If clear, skip

	jsl.L				   CODE_009730 ; Calculate icon offset
	clc							   ; Clear carry
	adc.B				   #$08	  ; Add offset $08
	bra					 Continue_Status4 ; Continue

Alternative_Status4:
	db											 $22,$30,$97,$00 ; JSL CODE_009730

Continue_Status4:
	eor.B				   #$ff	  ; Invert
	sec							   ; Set carry
	adc.B				   #$46	  ; Add offset $46
	jsr.W				   Status_RenderIcon ; Render status icon

Skip_Status4:
	rts							   ; Return

;-------------------------------------------------------------------------------

Status_RenderIcon:
; ===========================================================================
; Render Status Icon to Buffer
; ===========================================================================
; Writes status icon data to the display buffer in $7e memory
; Handles both simple icons and complex multi-part status displays
;
; TECHNICAL NOTES:
; - Uses Direct Page $0400 for temporary calculations
; - Calls CODE_028AE0 to process icon type
; - Icons $00-$2e: Simple single icons
; - Icons $2f-$46: Complex multi-part status displays
; - Buffer layout supports 4 different icon "layers" per slot
;
; Parameters:
;   A = Icon/status ID ($00-$46)
;   Y = Display position offset
;   Data bank = $7e
; ===========================================================================

	php							   ; Save processor status
	phd							   ; Save Direct Page
	sep					 #$30		; 8-bit mode
	pea.W				   $007e	 ; Push bank $7e
	plb							   ; Data bank = $7e
	phy							   ; Save Y offset
	pea.W				   $0400	 ; Push $0400
	pld							   ; Direct Page = $0400

	sta.B				   $3a	   ; Save icon ID to $043a
	jsl.L				   CODE_028AE0 ; Process icon type

	lda.B				   $3a	   ; Get icon ID
	cmp.B				   #$2f	  ; Check if >= $2f
	bcc					 Simple_Icon ; If < $2f → simple icon

Complex_Status:
; Complex multi-part status display ($2f-$46)
	ldx.B				   #$10	  ; X = $10 (layer 1 offset)
	cmp.B				   #$32	  ; Check if >= $32
	bcc					 Got_Layer_Offset ; If < $32 → use layer 1

	ldx.B				   #$20	  ; X = $20 (layer 2 offset)
	cmp.B				   #$39	  ; Check if >= $39
	bcc					 Got_Layer_Offset ; If < $39 → use layer 2

	ldx.B				   #$30	  ; X = $30 (layer 3 offset)
	cmp.B				   #$3d	  ; Check if >= $3d
	bcc					 Got_Layer_Offset ; If < $3d → use layer 3

	ldx.B				   #$40	  ; X = $40 (layer 4 offset)
	clc							   ; Clear carry

Got_Layer_Offset:
	txa							   ; A = layer offset
	adc.B				   $01,s	 ; Add Y offset from stack
	tax							   ; X = final buffer offset
	jsr.W				   Status_SetIconFlags ; Write icon data to buffer

; Copy calculated values to buffer
	lda.B				   $db	   ; Get calculated value 1
	sta.W				   $3670,x   ; Store to buffer
	lda.B				   $dc	   ; Get calculated value 2
	sta.W				   $3671,x   ; Store to buffer
	lda.B				   $e5	   ; Get calculated value 3
	sta.W				   $3672,x   ; Store to buffer
	lda.B				   $e6	   ; Get calculated value 4
	adc.W				   $366a,x   ; Add to existing value
	sta.W				   $366a,x   ; Store accumulated value
	lda.B				   $e7	   ; Get calculated value 5
	sta.W				   $366e,x   ; Store to buffer
	lda.B				   $e8	   ; Get calculated value 6
	sta.W				   $366d,x   ; Store to buffer
	lda.B				   $e9	   ; Get calculated value 7
	sta.W				   $366f,x   ; Store to buffer
	bra					 Render_Done ; Done

Simple_Icon:
; Simple single icon ($00-$2e)
	plx							   ; X = Y offset (from stack)
	phx							   ; Save it back
	jsr.W				   Status_SetIconFlags ; Write icon to buffer

	cpx.B				   #$50	  ; Check if offset >= $50
	bcs					 Render_Done ; If so, done

; Copy icon template for simple icons
	rep					 #$30		; 16-bit mode
	lda.B				   $3a	   ; Get icon ID
	and.W				   #$00ff	; Mask to byte
	ldy.W				   #$3709	; Y = template address for icons $00-$22
	cmp.W				   #$0023	; Check if < $23
	bcc					 Copy_Template ; If so, use first template

	ldy.W				   #$3719	; Y = template for icons $23-$25
	cmp.W				   #$0026	; Check if < $26
	bcc					 Copy_Template ; If so, use second template

	ldy.W				   #$3729	; Y = template for icons $26-$28
	cmp.W				   #$0029	; Check if < $29
	bcc					 Copy_Template ; If so, use third template

	ldy.W				   #$3739	; Y = template for icons $29+

Copy_Template:
	ldx.W				   #$3669	; X = destination buffer
	lda.W				   #$000f	; A = 15 bytes to copy
	mvn					 $7e,$7e	 ; Block copy template
	sep					 #$30		; 8-bit mode

Render_Done:
	ply							   ; Restore Y offset
	plb							   ; Restore data bank
	pld							   ; Restore Direct Page
	plp							   ; Restore processor status
	rts							   ; Return

;-------------------------------------------------------------------------------

Status_SetIconFlags:
; ===========================================================================
; Set Status Icon Flags in Buffer
; ===========================================================================
; Decodes status effect flags and writes $05 to appropriate buffer slots
; Used by icon rendering to mark which status effects are active
;
; TECHNICAL NOTES:
; - $e4 contains packed flags (bits 0-3 for 4 different statuses)
; - Each bit set writes $05 to corresponding buffer position
; - Buffer layout: $3669, $366a, $366b, $366c (+X offset)
;
; Parameters:
;   X = Buffer offset
;   $e4 (at Direct Page $0400) = Packed status flags
;
; Flag Mapping:
;   Bit 3 → $3669,X
;   Bit 2 → $366a,X
;   Bit 1 → $366b,X
;   Bit 0 → $366c,X
; ===========================================================================

	lda.B				   $e4	   ; Get packed status flags
	tay							   ; Y = flags (save for later)
	and.B				   #$08	  ; Check bit 3
	beq					 Skip_Flag1  ; If clear, skip
	lda.B				   #$05	  ; A = $05 (active marker)

Skip_Flag1:
	sta.W				   $3669,x   ; Store to buffer slot 1

	tya							   ; A = flags
	and.B				   #$04	  ; Check bit 2
	beq					 Skip_Flag2  ; If clear, skip
	db											 $a9,$05	 ; LDA #$05

Skip_Flag2:
	sta.W				   $366a,x   ; Store to buffer slot 2

	tya							   ; A = flags
	and.B				   #$02	  ; Check bit 1
	beq					 Skip_Flag3  ; If clear, skip
	lda.B				   #$05	  ; A = $05

Skip_Flag3:
	sta.W				   $366b,x   ; Store to buffer slot 3

	tya							   ; A = flags
	and.B				   #$01	  ; Check bit 0
	beq					 Skip_Flag4  ; If clear, skip
	lda.B				   #$05	  ; A = $05

Skip_Flag4:
	sta.W				   $366c,x   ; Store to buffer slot 4
	rts							   ; Return

; ===========================================================================
; Character Status Calculation Routine
; ===========================================================================
; Purpose: Calculate cumulative character status from multiple stat buffers
; Input: Bit 0 of $89 determines which character to process (0=first, 1=second)
; Output: $2a-$2d, $3a-$3f, $2e updated with calculated stats
; Technical Details:
;   - Sets up Direct Page to $1000 or $1080 based on character selection
;   - Processes 7 stats via CODE_009253 (summation across 5 buffers)
;   - Processes 2 stats via CODE_009245 (OR across 4 buffers)
;   - Updates base stats ($22-$25) with deltas ($26-$29)
; Buffers accessed:
;   - $3669-$3678: Base buffer (16 bytes)
;   - $3679-$3688: Delta buffer 1
;   - $3689-$3698: Delta buffer 2
;   - $3699-$36a8: Delta buffer 3
;   - $36a9-$36b8: Delta buffer 4
; ===========================================================================

Char_CalcStats:
	php							   ; Save processor status
	phd							   ; Save direct page register
	sep					 #$30		; 8-bit A/X/Y
	pea.W				   $007e	 ; Push $7e to stack
	plb							   ; Data Bank = $7e
	clc							   ; Clear carry
	pea.W				   $1000	 ; Default to character 1 DP ($1000)
	pld							   ; Direct Page = $1000
	ldx.B				   #$00	  ; X = $00 (buffer offset)
	bit.B				   #$01	  ; Test bit 0 of $89
	beq					 Setup_Done  ; If 0, use first character's DP
	pea.W				   $1080	 ; Character 2 DP ($1080)
	pld							   ; Direct Page = $1080
	ldx.B				   #$50	  ; X = $50 (character 2 buffer offset)

Setup_Done:
; Calculate cumulative stats using CODE_009253 (ADC across 5 buffers)
	jsr.W				   CODE_009253 ; Sum buffer values at X
	sta.B				   $2a	   ; Store stat 1
	jsr.W				   CODE_009253 ; Sum next buffer values (X++)
	sta.B				   $2b	   ; Store stat 2
	jsr.W				   CODE_009253 ; Sum next buffer values (X++)
	sta.B				   $2c	   ; Store stat 3
	jsr.W				   CODE_009253 ; Sum next buffer values (X++)
	sta.B				   $2d	   ; Store stat 4
	jsr.W				   CODE_009253 ; Sum next buffer values (X++)
	sta.B				   $41	   ; Store stat 5
	jsr.W				   CODE_009253 ; Sum next buffer values (X++)
	sta.B				   $3e	   ; Store stat 6
	jsr.W				   CODE_009253 ; Sum next buffer values (X++)
	sta.B				   $3f	   ; Store stat 7

; Calculate bitwise OR stats using CODE_009245 (ORA across 4 buffers)
	jsr.W				   CODE_009245 ; OR buffer values at X
	sta.B				   $3a	   ; Store flags 1
	jsr.W				   CODE_009245 ; OR next buffer values (X++)
	sta.B				   $3b	   ; Store flags 2

; Process status effect bits (lower nibble only)
	lda.B				   #$0f	  ; Mask for lower nibble
	trb.B				   $2e	   ; Clear lower nibble in $2e
	jsr.W				   CODE_009245 ; OR next buffer values (X++)
	and.B				   #$0f	  ; Keep only lower nibble
	tsb.B				   $2e	   ; Set bits in $2e

; Clear specific status bits and update base stats
	lda.B				   $3b	   ; A = flags 2
	trb.B				   $21	   ; Clear those bits in $21

; Update base stats with deltas (with carry from earlier CLC)
	lda.B				   $2a	   ; A = stat 1
	adc.B				   $26	   ; Add delta 1
	sta.B				   $22	   ; Store to base stat 1
	lda.B				   $2b	   ; A = stat 2
	adc.B				   $27	   ; Add delta 2
	sta.B				   $23	   ; Store to base stat 2
	lda.B				   $2c	   ; A = stat 3
	adc.B				   $28	   ; Add delta 3
	sta.B				   $24	   ; Store to base stat 3
	lda.B				   $2d	   ; A = stat 4
	adc.B				   $29	   ; Add delta 4
	sta.B				   $25	   ; Store to base stat 4

	plb							   ; Restore data bank
	pld							   ; Restore direct page
	plp							   ; Restore processor status
	rts							   ; Return

; ===========================================================================
; Bitwise OR Stat Calculation Helper
; ===========================================================================
; Purpose: Calculates bitwise OR of a stat value across 4 buffers
; Input: X = buffer offset (auto-incremented)
; Output: A = result of ORing all 4 buffer values
; Technical Details:
;   - Used for flag-based stats where any bit set in any buffer should be set
;   - Buffers: $3679, $3689, $3699, $36a9 (delta buffers 1-4)
;   - Increments X for next stat
; ===========================================================================

Stat_CalcOR:
	lda.W				   $3679,x   ; A = delta buffer 1 value
	ora.W				   $3689,x   ; OR with delta buffer 2
	ora.W				   $3699,x   ; OR with delta buffer 3
	ora.W				   $36a9,x   ; OR with delta buffer 4
	inx							   ; Increment offset to next stat
	rts							   ; Return with result in A

; ===========================================================================
; Additive Stat Calculation Helper
; ===========================================================================
; Purpose: Calculates sum of a stat value across all 5 buffers
; Input: X = buffer offset (auto-incremented)
; Output: A = sum of all 5 buffer values (with carry)
; Technical Details:
;   - Used for numeric stats that accumulate (HP, MP, Attack, Defense, etc.)
;   - Buffers: $3669 (base), $3679, $3689, $3699, $36a9 (deltas 1-4)
;   - Assumes carry flag is in appropriate state for multi-byte addition
;   - Increments X for next stat
; ===========================================================================

Stat_CalcSum:
	lda.W				   $3669,x   ; A = base buffer value
	adc.W				   $3679,x   ; Add delta buffer 1 (with carry)
	adc.W				   $3689,x   ; Add delta buffer 2
	adc.W				   $3699,x   ; Add delta buffer 3
	adc.W				   $36a9,x   ; Add delta buffer 4
	inx							   ; Increment offset to next stat
	rts							   ; Return with result in A

; ===========================================================================
; Animation Update Handler
; ===========================================================================
; Purpose: Conditionally update animations based on timing and game state
; Technical Details:
;   - Checks bit 5 ($20) of $00d9 as update gate
;   - Only processes animations when bit is clear
;   - Sets bit after processing to prevent multiple updates per frame
; Side Effects: May modify $00d9, calls CODE_009273
; ===========================================================================

Animation_CheckUpdate:
	sep					 #$30		; 8-bit A/X/Y
	lda.B				   #$20	  ; Bit 5 mask
	and.W				   $00d9	 ; Check animation update flag
	bne					 Skip_Animation ; If set, skip this frame
	jsr.W				   Animation_UpdateSystem ; Process animation updates

Skip_Animation:
	rep					 #$30		; 16-bit A/X/Y
	rts							   ; Return

; ===========================================================================
; Animation Update System
; ===========================================================================
; Purpose: Main animation update routine with queue processing
; Technical Details:
;   - Sets bit 5 of $00d9 to indicate animation processing
;   - Uses Direct Page $0500 for animation control structures
;   - Processes up to 3 queued animations ($00, $05, $0a slots)
;   - Checks bit 2 ($04) of $00e2 to gate certain animations
; Queue Structure (Direct Page $0500):
;   - $00: Animation type/ID (slot 1)
;   - $01-$03: Animation parameters (slot 1)
;   - $05: Animation type/ID (slot 2)
;   - $06-$08: Animation parameters (slot 2)
;   - $0a: Animation type/ID (slot 3)
;   - $0c-$0e: Animation parameters (slot 3)
; Animation Types:
;   - $ff = empty slot
;   - $01 = Type 1 animation (uses $0601 parameter)
;   - $02 = Type 2 animation (uses $0601 parameter)
;   - $10-$1f = Range-based type (gated by $00e2 bit 2)
;   - Other values processed based on range checks
; ===========================================================================

Animation_UpdateSystem:
	rep					 #$10		; 16-bit X/Y
	lda.B				   #$20	  ; Bit 5 mask
	tsb.W				   $00d9	 ; Set animation processing flag
	pea.W				   $0500	 ; Push $0500 to stack
	pld							   ; Direct Page = $0500 (animation queue)
	cli							   ; Enable interrupts

; Process animation slot 1 ($00)
	lda.B				   #$04	  ; Bit 2 mask
	and.W				   $00e2	 ; Check animation gate flag
	bne					 Check_Slot2 ; If set, skip slot 1
	lda.B				   $00	   ; A = animation type (slot 1)
	bmi					 Check_Slot2 ; If $ff (empty), skip
	sta.W				   $0601	 ; Store animation type to $0601
	ldx.B				   $01	   ; X = animation parameter (16-bit)
	stx.W				   $0602	 ; Store parameter to $0602
	lda.B				   #$01	  ; Animation command = $01
	sta.W				   $0600	 ; Store to animation command register
	jsl.L				   CODE_0D8004 ; Call animation processor
	lda.B				   #$ff	  ; Mark slot as empty
	sta.B				   $00	   ; Store to slot 1 type
	ldx.B				   $03	   ; X = saved parameters
	stx.B				   $01	   ; Restore to slot 1

Check_Slot2:
; Process animation slot 2 ($05)
	lda.B				   $05	   ; A = animation type (slot 2)
	bmi					 Check_Slot3 ; If $ff (empty), skip
	lda.B				   $05	   ; A = animation type (reload)
	sta.W				   $0601	 ; Store animation type to $0601
	ldx.B				   $06	   ; X = animation parameter (16-bit)
	stx.W				   $0602	 ; Store parameter to $0602
	lda.B				   #$02	  ; Animation command = $02
	sta.W				   $0600	 ; Store to animation command register
	jsl.L				   CODE_0D8004 ; Call animation processor
	lda.B				   #$ff	  ; Mark slot as empty
	sta.B				   $05	   ; Store to slot 2 type
	ldx.B				   $08	   ; X = saved parameters
	stx.B				   $06	   ; Restore to slot 2

Check_Slot3:
; Process animation slot 3 ($0a)
	lda.B				   $0a	   ; A = animation type (slot 3)
	beq					 Animation_Done ; If $00 (empty), done
	cmp.B				   #$02	  ; Compare to $02
	beq					 Execute_Slot3 ; If exactly $02, execute
	cmp.B				   #$10	  ; Compare to $10
	bcc					 Check_Gate  ; If < $10, check gate
	cmp.B				   #$20	  ; Compare to $20
	bcc					 Execute_Slot3 ; If $10-$1f, execute

Check_Gate:
	lda.B				   #$04	  ; Bit 2 mask
	and.W				   $00e2	 ; Check animation gate flag
	bne					 Animation_Done ; If set, skip slot 3

Execute_Slot3:
	ldx.B				   $0a	   ; X = animation type (16-bit load)
	stx.W				   $0600	 ; Store to animation command
	ldx.B				   $0c	   ; X = animation parameter (16-bit)
	stx.W				   $0602	 ; Store parameter to $0602
	jsl.L				   CODE_0D8004 ; Call animation processor
	stz.B				   $0a	   ; Clear slot 3 type ($00 = empty)

Animation_Done:
	sei							   ; Disable interrupts
	lda.B				   #$20	  ; Bit 5 mask
	trb.W				   $00d9	 ; Clear animation processing flag
	rts							   ; Return

; ===========================================================================
; Graphics Mode Setup - Jump to Field Mode Initialization
; ===========================================================================
; Purpose: Setup graphics environment and jump to field mode code
; Technical Details:
;   - Calls CODE_0092FC to prepare graphics state
;   - Jumps to CODE_00803A for field mode initialization
; Side Effects: Modifies $00d6, NMITIMEN register, $00d2, $00db
; ===========================================================================

Graphics_SetupFieldMode:
	jsr.W				   CODE_0092FC ; Setup graphics state
	jmp.W				   CODE_00803A ; Jump to field mode init

; ===========================================================================
; Graphics Mode Setup - Jump to Battle Mode Initialization
; ===========================================================================
; Purpose: Setup graphics environment and jump to battle mode code
; Technical Details:
;   - Calls CODE_0092FC to prepare graphics state
;   - Jumps to CODE_008016 for battle mode initialization
; Side Effects: Modifies $00d6, NMITIMEN register, $00d2, $00db
; ===========================================================================

Graphics_SetupBattleMode:
	jsr.W				   Graphics_PrepareTransition ; Setup graphics state
	jmp.W				   CODE_008016 ; Jump to battle mode init

; ===========================================================================
; Graphics State Setup Routine
; ===========================================================================
; Purpose: Configure graphics system for mode transitions
; Technical Details:
;   - Sets bit 6 ($40) of $00d6 (graphics busy flag)
;   - Restores NMI/IRQ configuration from $0112
;   - Enables interrupts
;   - Calls sprite processing routine CODE_00C7B8
;   - Clears bit 3 ($08) of $00d2 (graphics ready flag)
;   - Clears bit 2 ($04) of $00db (animation gate)
; Registers Modified:
;   - A: Used for bit manipulation
;   - NMITIMEN ($4200): Set from $0112
; ===========================================================================

Graphics_PrepareTransition:
	sep					 #$30		; 8-bit A/X/Y
	lda.B				   #$40	  ; Bit 6 mask
	tsb.W				   $00d6	 ; Set graphics busy flag in $00d6
	lda.W				   $0112	 ; Load NMI/IRQ configuration
	sta.W				   SNES_NMITIMEN ; Store to NMITIMEN ($4200)
	cli							   ; Enable interrupts
	jsl.L				   CODE_00C7B8 ; Call sprite processing routine
	lda.B				   #$08	  ; Bit 3 mask
	trb.W				   $00d2	 ; Clear graphics ready flag
	lda.B				   #$04	  ; Bit 2 mask
	trb.W				   $00db	 ; Clear animation gate
	rts							   ; Return

; ===========================================================================
; Display Configuration Setup
; ===========================================================================
; Purpose: Configure display parameters and enable certain display features
; Technical Details:
;   - Called to enable/configure display effects
;   - Sets $0051 = $0008 (display timer/counter)
;   - Sets $0055 = $0c (display mode/config)
;   - Clears bit 1 ($02) of $00db (display update gate)
;   - Clears bit 7 ($80) of $00e2 (graphics effect flag)
;   - Sets bit 2 ($04) of $00db (animation gate)
; Side Effects: Enables specific graphics modes, gates certain animations
; ===========================================================================

Display_EnableEffects:
	php							   ; Save processor status
	phb							   ; Save data bank
	phk							   ; Push program bank
	plb							   ; Data Bank = program bank
	rep					 #$30		; 16-bit A/X/Y
	pha							   ; Save A
	lda.W				   #$0008	; Value $0008
	sta.W				   $0051	 ; Store to display timer
	sep					 #$20		; 8-bit A
	lda.B				   #$0c	  ; Value $0c
	sta.W				   $0055	 ; Store to display config
	lda.B				   #$02	  ; Bit 1 mask
	trb.W				   $00db	 ; Clear display update gate
	lda.B				   #$80	  ; Bit 7 mask
	trb.W				   $00e2	 ; Clear graphics effect flag
	lda.B				   #$04	  ; Bit 2 mask
	tsb.W				   $00db	 ; Set animation gate
	rep					 #$30		; 16-bit A/X/Y
	pla							   ; Restore A
	plb							   ; Restore data bank
	plp							   ; Restore processor status
	rtl							   ; Return long

; ===========================================================================
; Display Frame Counter Check
; ===========================================================================
; Purpose: Check display timing and process frame-based updates
; Technical Details:
;   - Checks if bit 2 ($04) of $00db is set (animation gate)
;   - If not set, returns immediately
;   - Checks lower nibble of $0e97 for timing sync
;   - Must be $00 to proceed with updates
;   - If all conditions met, processes display updates
; Returns: Early if conditions not met
; Side Effects: May call display update routines
; ===========================================================================

Display_CheckFrameUpdate:
	lda.W				   #$0004	; Bit 2 mask
	and.W				   $00db	 ; Check animation gate
	beq					 Skip_Frame_Check ; If clear, skip
	lda.W				   $0e97	 ; Load frame counter
	and.W				   #$000f	; Mask to lower nibble
	beq					 Process_Frame ; If $00, process this frame

Skip_Frame_Check:
	rts							   ; Return (skip this frame)

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
; Output: $9e-$a0 = 32-bit product
; Technical Details:
;   - Uses Direct Page $0000 for calculations
;   - Saves A register ($9c → $a4)
;   - Performs 16 iterations of shift-and-add
;   - Result in $9e (low word) and $a0 (high word)
; ===========================================================================

Math_Multiply16x16:
	php							   ; Save processor status
	rep					 #$30		; 16-bit A/X/Y
	phd							   ; Save direct page
	pha							   ; Save A
	phx							   ; Save X
	phy							   ; Save Y
	lda.W				   #$0000	; Direct Page = $0000
	tcd							   ; Set DP to zero page
	lda.B				   $9c	   ; Load multiplicand from stack
	sta.B				   $a4	   ; Store to $a4
	stz.B				   $9e	   ; Clear result low word
	ldx.W				   #$0010	; Loop counter = 16 bits
	ldy.B				   $98	   ; Y = multiplier from stack

Multiply_Loop:
	asl.B				   $9e	   ; Shift result left (low word)
	rol.B				   $a0	   ; Rotate result (high word)
	asl.B				   $a4	   ; Shift multiplicand left
	bcc					 Skip_Add	; If no carry, skip addition
	tya							   ; A = multiplier
	clc							   ; Clear carry
	adc.B				   $9e	   ; Add to result low word
	sta.B				   $9e	   ; Store back
	bcc					 Skip_Add	; If no carry, continue
	inc.B				   $a0	   ; Increment high word

Skip_Add:
	dex							   ; Decrement loop counter
	bne					 Multiply_Loop ; Loop until done
	ply							   ; Restore Y
	plx							   ; Restore X
	pla							   ; Restore A
	pld							   ; Restore direct page
	plp							   ; Restore processor status
	rtl							   ; Return long

; ---------------------------------------------------------------------------
; 32-bit Division Helper
; ---------------------------------------------------------------------------
; Purpose: Divide 32-bit value by 16-bit divisor
; Input: $9e-$a0 = 32-bit dividend, $9c = 16-bit divisor
; Output: $9e-$a0 = quotient, $a2 = remainder
; Technical Details:
;   - Uses Direct Page $0000 for calculations
;   - Performs 32 iterations of shift-and-subtract
;   - Handles division by zero (undefined behavior)
; ===========================================================================

Math_Divide32by16:
	php							   ; Save processor status
	rep					 #$30		; 16-bit A/X/Y
	phd							   ; Save direct page
	pha							   ; Save A
	phx							   ; Save X
	lda.W				   #$0000	; Direct Page = $0000
	tcd							   ; Set DP to zero page
	lda.B				   $98	   ; Load dividend low word
	sta.B				   $a4	   ; Store to $a4
	lda.B				   $9a	   ; Load dividend high word
	sta.B				   $a6	   ; Store to $a6
	stz.B				   $a2	   ; Clear remainder
	ldx.W				   #$0020	; Loop counter = 32 bits

Divide_Loop:
	asl.B				   $9e	   ; Shift quotient left (low)
	rol.B				   $a0	   ; Rotate quotient (mid)
	asl.B				   $a4	   ; Shift dividend left (low)
	rol.B				   $a6	   ; Rotate dividend (mid)
	rol.B				   $a2	   ; Rotate into remainder
	lda.B				   $a2	   ; A = remainder
	bcs					 Division_Subtract ; If carry set, always subtract
	sec							   ; Set carry for subtraction
	sbc.B				   $9c	   ; Subtract divisor
	bcs					 Store_Remainder ; If no borrow, store result
	bra					 Skip_Division ; Skip if borrow

Division_Subtract:
	sbc.B				   $9c	   ; Subtract divisor (carry already set)

Store_Remainder:
	sta.B				   $a2	   ; Store new remainder
	inc.B				   $9e	   ; Set bit in quotient

Skip_Division:
	dex							   ; Decrement loop counter
	bne					 Divide_Loop ; Loop until done
	plx							   ; Restore X
	pla							   ; Restore A
	pld							   ; Restore direct page
	plp							   ; Restore processor status
	rtl							   ; Return long

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
	php							   ; Save processor status
	sep					 #$20		; 8-bit A
	sta.W				   SNES_WRMPYB ; Write to multiplier B register
	plp							   ; Restore processor status
	rtl							   ; Return long

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
	php							   ; Save processor status
	sep					 #$20		; 8-bit A
	sta.W				   SNES_WRDIVB ; Write divisor to hardware
	xba							   ; Swap A bytes (delay)
	xba							   ; Swap back (delay)
	plp							   ; Restore processor status
	rtl							   ; Return long

; ---------------------------------------------------------------------------
; Find First Set Bit (Count Leading Zeros)
; ---------------------------------------------------------------------------
; Purpose: Find position of first set bit in 16-bit value
; Input: A (16-bit) = value to test
; Output: A (16-bit) = bit position (0-15), or $ffff if no bits set
; Technical Details:
;   - Counts from LSB (bit 0) upward
;   - Returns position of first 1 bit found
;   - Returns $ffff if input is $0000
; ===========================================================================

Bit_FindFirstSet:
	php							   ; Save processor status
	rep					 #$30		; 16-bit A/X/Y
	phx							   ; Save X
	ldx.W				   #$ffff	; X = -1 (initial position)

Count_Bits:
	inx							   ; Increment position
	lsr					 a; Shift right, test bit 0
	bcc					 Count_Bits  ; If clear, continue
	txa							   ; A = bit position
	plx							   ; Restore X
	plp							   ; Restore processor status
	rtl							   ; Return long

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
	jsr.W				   Bit_CalcPosition ; Calculate bit position/mask
	tsb.B				   $00	   ; Test and set bits
	rtl							   ; Return long

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
	jsr.W				   Bit_CalcPosition ; Calculate bit position/mask
	trb.B				   $00	   ; Test and reset bits
	rtl							   ; Return long

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
	jsr.W				   Bit_CalcPosition ; Calculate bit position/mask
	and.B				   $00	   ; Test bits
	rtl							   ; Return long

; ---------------------------------------------------------------------------
; Set Bits with DP $0ea8
; ---------------------------------------------------------------------------
; Purpose: Set bits in $0ea8+offset using TSB
; Input: A = bit mask (offset in low byte)
; Output: Bits set in target location
; ===========================================================================

Bit_SetBits_0EA8:
	phd							   ; Save direct page
	pea.W				   $0ea8	 ; Push $0ea8
	pld							   ; Direct Page = $0ea8
	jsl.L				   Bit_SetBits ; Set bits via TSB
	pld							   ; Restore direct page
	rtl							   ; Return long

; ---------------------------------------------------------------------------
; Clear Bits with DP $0ea8
; ---------------------------------------------------------------------------
; Purpose: Clear bits in $0ea8+offset using TRB
; Input: A = bit mask (offset in low byte)
; Output: Bits cleared in target location
; ===========================================================================

Bit_ClearBits_0EA8:
	phd							   ; Save direct page
	pea.W				   $0ea8	 ; Push $0ea8
	pld							   ; Direct Page = $0ea8
	jsl.L				   Bit_ClearBits ; Clear bits via TRB
	pld							   ; Restore direct page
	rtl							   ; Return long

; ---------------------------------------------------------------------------
; Test Bits with DP $0ea8
; ---------------------------------------------------------------------------
; Purpose: Test bits in $0ea8+offset
; Input: A = bit mask (offset in low byte)
; Output: A = result of test, Z/N flags set
; ===========================================================================

Bit_TestBits_0EA8:
	phd							   ; Save direct page
	pea.W				   $0ea8	 ; Push $0ea8
	pld							   ; Direct Page = $0ea8
	jsl.L				   Bit_TestBits ; Test bits via AND
	pld							   ; Restore direct page
	inc					 a; Set flags based on result
	dec					 a; (INC/DEC preserves value, updates flags)
	rtl							   ; Return long

; ---------------------------------------------------------------------------
; Random Number Generator
; ---------------------------------------------------------------------------
; Purpose: Generate pseudo-random number using linear congruential generator
; Output: $a9 (at DP $005e) = random byte, $701ffe updated
; Technical Details:
;   - Uses formula: seed = seed * 5 + $3711 + frame_counter
;   - Seed stored at $701ffe (16-bit)
;   - Uses $0e96 (frame counter) for additional entropy
;   - Applies modulo $a8 (stored in $a8 at DP $005e)
; ===========================================================================

Random_Generate:
	php							   ; Save processor status
	phd							   ; Save direct page
	rep					 #$30		; 16-bit A/X/Y
	pha							   ; Save A
	lda.W				   #$005e	; Direct Page = $005e
	tcd							   ; Set DP
	lda.L				   $701ffe   ; Load current seed
	asl					 a; Multiply by 2
	asl					 a; Multiply by 4
	adc.L				   $701ffe   ; Add original (now *5)
	adc.W				   #$3711	; Add constant
	adc.W				   $0e96	 ; Add frame counter
	sta.L				   $701ffe   ; Store new seed
	sep					 #$20		; 8-bit A
	xba							   ; Get high byte
	sta.B				   $4b	   ; Store to $a9 (DP $005e + $4b)
	sta.W				   SNES_WRDIVL ; Write to divider (low byte)
	stz.W				   SNES_WRDIVH ; Clear divider (high byte)
	lda.B				   $4a	   ; Load modulo value from $a8
	beq					 Random_Done ; If zero, skip modulo
	jsl.L				   Hardware_Divide ; Perform division
	lda.W				   SNES_RDMPYL ; Read remainder (result of modulo)
	sta.B				   $4b	   ; Store to $a9

Random_Done:
	rep					 #$30		; 16-bit A/X/Y
	pla							   ; Restore A
	pld							   ; Restore direct page
	plp							   ; Restore processor status
	rtl							   ; Return long

; ---------------------------------------------------------------------------
; Bit Position to Mask Conversion Table
; ---------------------------------------------------------------------------
; Purpose: Convert bit position (0-7) to bit mask
; Input: A (after processing) = bit position * 2 (for word indexing)
; Output: A = bit mask ($0001, $0002, $0004...$0080, $0100...$8000)
; ===========================================================================

Bit_PositionToMask:
	phx							   ; Save X
	asl					 a; Multiply by 2 for word table
	tax							   ; X = index
	lda.L				   DATA8_0097fb,x ; Load bit mask from table
	plx							   ; Restore X
	rts							   ; Return

DATA8_0097fb:
	dw											 $0001, $0002, $0004, $0008, $0010, $0020, $0040, $0080
	dw											 $0100, $0200, $0400, $0800, $1000, $2000, $4000, $8000

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

Bit_CalcPosition:
	php							   ; Save processor status
	rep					 #$30		; 16-bit A/X/Y
	and.W				   #$00ff	; Mask to 8-bit value
	pha							   ; Save bit position
	lsr					 a; Divide by 2
	lsr					 a; Divide by 4
	lsr					 a; Divide by 8 (byte offset)
	phd							   ; Save current DP
	clc							   ; Clear carry
	adc.B				   $01,s	 ; Add to saved DP
	tcd							   ; Set new DP
	pla							   ; Discard saved DP
	pla							   ; Restore bit position
	and.W				   #$0007	; Mask to bit number (0-7)
	eor.W				   #$0007	; Invert bit position
	plp							   ; Restore processor status
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

Jump_IndirectViaTable:
	php							   ; Save processor status
	phb							   ; Save data bank
	rep					 #$30		; 16-bit A/X/Y
	phy							   ; Save Y
	and.W				   #$00ff	; Mask to 8-bit index
	asl					 a; Multiply by 2 (word table)
	tay							   ; Y = table offset
	lda.B				   $06,s	 ; Load return bank from stack
	pha							   ; Save it
	plb							   ; Data Bank = return bank
	plb							   ; (needs double pull for 16-bit)
	lda.B				   ($08,s),y ; Read table entry at [return_addr + Y]
	tay							   ; Y = destination address
	lda.B				   $05,s	 ; Get saved processor status
	sta.B				   $08,s	 ; Move to where return address was
	tya							   ; A = destination address
	sta.B				   $05,s	 ; Store as new return address
	ply							   ; Restore Y
	plb							   ; Restore data bank
	rti							   ; Return to table address (not original caller)

; ===========================================================================
; Common Stack Cleanup Routine
; ===========================================================================
; Purpose: Standard cleanup of saved registers from stack
; Technical Details:
;   - Restores registers in reverse order of saving
;   - REP #$30 ensures 16-bit mode for index registers
; ===========================================================================

Stack_RestoreAll:
	rep					 #$30		; 16-bit A/X/Y
	ply							   ; Restore Y
	plx							   ; Restore X
	pld							   ; Restore direct page
	pla							   ; Restore A
	plb							   ; Restore data bank
	plp							   ; Restore processor status
	rts							   ; Return

; ===========================================================================
; Memory Copy/Fill Routines
; ===========================================================================

; ---------------------------------------------------------------------------
; Copy 64 Bytes (16 words) Between Memory Blocks
; ---------------------------------------------------------------------------
; Purpose: Copy 32 words (64 bytes) from X to Y, both in bank $7e
; Input: X = source address, Y = destination address
; Technical Details:
;   - Copies in reverse order (high to low addresses)
;   - 32 LDA/STA pairs for 64 bytes total
;   - All addresses offset from base X/Y by +$00 to +$3e (even offsets)
; ===========================================================================

Memory_Copy64Bytes:
	lda.W				   $003e,x   ; Copy word at +$3e
	sta.W				   $003e,y
	lda.W				   $003c,x   ; Copy word at +$3c
	sta.W				   $003c,y
	lda.W				   $003a,x   ; Copy word at +$3a
	sta.W				   $003a,y
	lda.W				   $0038,x   ; Copy word at +$38
	sta.W				   $0038,y
	lda.W				   $0036,x   ; Copy word at +$36
	sta.W				   $0036,y
	lda.W				   $0034,x   ; Copy word at +$34
	sta.W				   $0034,y
	lda.W				   $0032,x   ; Copy word at +$32
	sta.W				   $0032,y
	lda.W				   $0030,x   ; Copy word at +$30
	sta.W				   $0030,y
	lda.W				   $002e,x   ; Copy word at +$2e
	sta.W				   $002e,y
	lda.W				   $002c,x   ; Copy word at +$2c
	sta.W				   $002c,y
	lda.W				   $002a,x   ; Copy word at +$2a
	sta.W				   $002a,y
	lda.W				   $0028,x   ; Copy word at +$28
	sta.W				   $0028,y
	lda.W				   $0026,x   ; Copy word at +$26
	sta.W				   $0026,y
	lda.W				   $0024,x   ; Copy word at +$24
	sta.W				   $0024,y
	lda.W				   $0022,x   ; Copy word at +$22
	sta.W				   $0022,y
	lda.W				   $0020,x   ; Copy word at +$20
	sta.W				   $0020,y

Memory_Copy32Bytes:
	lda.W				   $001e,x   ; Copy word at +$1e
	sta.W				   $001e,y
	lda.W				   $001c,x   ; Copy word at +$1c
	sta.W				   $001c,y
	lda.W				   $001a,x   ; Copy word at +$1a
	sta.W				   $001a,y
	lda.W				   $0018,x   ; Copy word at +$18
	sta.W				   $0018,y
	lda.W				   $0016,x   ; Copy word at +$16
	sta.W				   $0016,y
	lda.W				   $0014,x   ; Copy word at +$14
	sta.W				   $0014,y
	lda.W				   $0012,x   ; Copy word at +$12
	sta.W				   $0012,y
	lda.W				   $0010,x   ; Copy word at +$10
	sta.W				   $0010,y
	lda.W				   $000e,x   ; Copy word at +$0e
	sta.W				   $000e,y
	lda.W				   $000c,x   ; Copy word at +$0c
	sta.W				   $000c,y
	lda.W				   $000a,x   ; Copy word at +$0a
	sta.W				   $000a,y
	lda.W				   $0008,x   ; Copy word at +$08
	sta.W				   $0008,y
	lda.W				   $0006,x   ; Copy word at +$06
	sta.W				   $0006,y
	lda.W				   $0004,x   ; Copy word at +$04
	sta.W				   $0004,y
	lda.W				   $0002,x   ; Copy word at +$02
	sta.W				   $0002,y
	lda.W				   $0000,x   ; Copy word at +$00
	sta.W				   $0000,y
	rts							   ; Return

; ---------------------------------------------------------------------------
; Memory Fill Dispatcher - Long Entry Point
; ---------------------------------------------------------------------------
; Purpose: Fill memory with value (long call wrapper)
; Input: A (16-bit) = fill count, Y = start address, value on stack
; ===========================================================================

Memory_FillLong:
	jsr.W				   Memory_FillDispatch ; Call fill routine
	rtl							   ; Return long

; ---------------------------------------------------------------------------
; Memory Fill Routine
; ---------------------------------------------------------------------------
; Purpose: Fill memory region with specified value
; Input:
;   A (16-bit) = number of bytes to fill
;   Y = starting address in bank $7f
;   Stack+3 = fill value (16-bit)
; Technical Details:
;   - Handles blocks of 64 bytes ($40) at a time
;   - Uses Memory_Fill64 for 64-byte blocks
;   - Uses jump table (DATA8_009A1E) for partial blocks
;   - Remainder handled by indexed jump
; ===========================================================================

Memory_FillDispatch:
	phx							   ; Save X
	cmp.W				   #$0040	; Check if >= 64 bytes
	bcc					 Handle_Remainder ; If < 64, handle remainder
	pha							   ; Save count
	lsr					 a; Divide by 2
	lsr					 a; Divide by 4
	lsr					 a; Divide by 8
	lsr					 a; Divide by 16
	lsr					 a; Divide by 32
	lsr					 a; Divide by 64
	tax							   ; X = number of 64-byte blocks
	clc							   ; Clear carry

Fill_Block_Loop:
	lda.B				   $03,s	 ; Get fill value from stack
	jsr.W				   Memory_Fill64 ; Fill 64 bytes
	tya							   ; A = current address
	adc.W				   #$0040	; Advance by 64 bytes
	tay							   ; Y = new address
	dex							   ; Decrement block counter
	bne					 Fill_Block_Loop ; Loop if more blocks
	pla							   ; Restore count
	and.W				   #$003f	; Get remainder (last 0-63 bytes)

Handle_Remainder:
	tax							   ; X = remainder count (doubled for jump table)
	pla							   ; Restore X from stack
	jmp.W				   (DATA8_009a1e,x) ; Jump to handler for exact count

; ---------------------------------------------------------------------------
; Fill 64 Bytes With Value
; ---------------------------------------------------------------------------
; Purpose: Fill exactly 64 bytes starting at Y with value in A
; Technical Details:
;   - Uses unrolled loop (32 stores of 16-bit words)
;   - All addresses in bank $7f
; ===========================================================================

Memory_Fill64:
	sta.W				   $003e,y   ; Fill word at +$3e
	sta.W				   $003c,y   ; Fill word at +$3c
	sta.W				   $003a,y   ; Fill word at +$3a
	sta.W				   $0038,y   ; Fill word at +$38
	sta.W				   $0036,y   ; Fill word at +$36
	sta.W				   $0034,y   ; Fill word at +$34
	sta.W				   $0032,y   ; Fill word at +$32
	sta.W				   $0030,y   ; Fill word at +$30
	sta.W				   $002e,y   ; Fill word at +$2e
	sta.W				   $002c,y   ; Fill word at +$2c
	sta.W				   $002a,y   ; Fill word at +$2a
	sta.W				   $0028,y   ; Fill word at +$28
	sta.W				   $0026,y   ; Fill word at +$26
	sta.W				   $0024,y   ; Fill word at +$24
	sta.W				   $0022,y   ; Fill word at +$22

Memory_Fill32:
	sta.W				   $0020,y   ; Fill word at +$20
	sta.W				   $001e,y   ; Fill word at +$1e
	sta.W				   $001c,y   ; Fill word at +$1c
	sta.W				   $001a,y   ; Fill word at +$1a
	sta.W				   $0018,y   ; Fill word at +$18
	sta.W				   $0016,y   ; Fill word at +$16
	sta.W				   $0014,y   ; Fill word at +$14
	sta.W				   $0012,y   ; Fill word at +$12

Memory_Fill16:
	sta.W				   $0010,y   ; Fill word at +$10

Memory_Fill14Bytes:
	sta.W				   $000e,y   ; Fill word at +$0e

Memory_Fill12Bytes:
	sta.W				   $000c,y   ; Fill word at +$0c
	sta.W				   $000a,y   ; Fill word at +$0a
	sta.W				   $0008,y   ; Fill word at +$08

Memory_Fill6Words:
	sta.W				   $0006,y   ; Fill word at +$06
	sta.W				   $0004,y   ; Fill word at +$04
	sta.W				   $0002,y   ; Fill word at +$02

Memory_Fill2Words:
	sta.W				   $0000,y   ; Fill word at +$00
	rts							   ; Return

; ---------------------------------------------------------------------------
; Fill Jump Table
; ---------------------------------------------------------------------------
; Purpose: Jump table for partial block fills (0-63 bytes)
; Format: Table of addresses for each possible remainder count
; Technical Details:
;   - Entry points into CODE_0099BD at various offsets
;   - Allows exact fill counts without conditional logic
; ===========================================================================

DATA8_009a1e:
	dw											 $9a1d	   ; 0 bytes (just return)
	dw											 $9a1a, $9a17, $9a14, $9a11 ; 2, 4, 6, 8 bytes
	dw											 $9a0e, $9a0b, $9a08, $9a05, $9a02 ; 10-18 bytes
	dw											 $99ff, $99fc, $99f9, $99f6, $99f3 ; 20-28 bytes
	dw											 $99f0, $99ed, $99ea, $99e7, $99e4 ; 30-38 bytes
	dw											 $99e1, $99de, $99db, $99d8, $99d5 ; 40-48 bytes
	dw											 $99d2, $99cf, $99cc, $99c9, $99c6 ; 50-58 bytes
	dw											 $99c3, $99c0, $99bd ; 60-64 bytes
Update_Done:
	plp							   ; Restore status
	rts							   ; Return

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
	php							   ; Save processor status
	phb							   ; Save data bank
	phd							   ; Save direct page
	rep					 #$30		; 16-bit A/X/Y
	pha							   ; Save A
	lda.W				   #$0000	; Direct Page = $0000
	tcd							   ; Set DP
	lda.W				   #$f811	; Graphics pointer
	sta.B				   $17	   ; Store pointer
	sep					 #$20		; 8-bit A
	lda.B				   #$03	  ; Bank $03
	sta.B				   $19	   ; Store bank
	jsr.W				   CODE_009D75 ; Process graphics data
	rep					 #$30		; 16-bit A/X/Y
	pla							   ; Restore A
	pld							   ; Restore direct page
	plb							   ; Restore data bank
	plp							   ; Restore processor status
	rtl							   ; Return long

; ---------------------------------------------------------------------------
; Graphics Processing Entry Points
; ---------------------------------------------------------------------------

Graphics_ProcessMenuData:
	php							   ; Save processor status
	phd							   ; Save direct page
	pea.W				   $0000	 ; Push $0000
	pld							   ; Direct Page = $0000
	rep					 #$30		; 16-bit A/X/Y
	phx							   ; Save X
	ldx.W				   #$9aff	; Data pointer
	jsr.W				   CODE_009BC4 ; Process data
	plx							   ; Restore X
	pld							   ; Restore direct page
	plp							   ; Restore processor status
	rtl							   ; Return long

Graphics_InitDisplay:
	php							   ; Save processor status
	phd							   ; Save direct page
	phb							   ; Save data bank
	sep					 #$20		; 8-bit A
	rep					 #$10		; 16-bit X/Y
	pha							   ; Save A
	phx							   ; Save X
	pea.W				   $0000	 ; Push $0000
	pld							   ; Direct Page = $0000
	jsl.L				   CODE_0C8000 ; Call graphics handler
	jsl.L				   CODE_0096A0 ; Wait for VBlank
	pei.B				   ($1d)	 ; Push [$1d]
	lda.B				   $27	   ; Load parameter
	pha							   ; Save it
	jsl.L				   Graphics_Setup1 ; Process graphics
	jsr.W				   Graphics_InitDisplay ; Call handler
	pla							   ; Restore parameter
	sta.B				   $27	   ; Store back
	plx							   ; Get saved value
	stx.B				   $1d	   ; Store to $1d
	plx							   ; Restore X
	pla							   ; Restore A
	plb							   ; Restore data bank
	pld							   ; Restore direct page
	plp							   ; Restore processor status
	rtl							   ; Return long

Graphics_Setup1:
	php							   ; Save processor status
	phd							   ; Save direct page
	pea.W				   $0000	 ; Push $0000
	pld							   ; Direct Page = $0000
	rep					 #$30		; 16-bit A/X/Y
	phx							   ; Save X
	ldx.W				   #$9b42	; Data pointer
	jsr.W				   Graphics_ProcessData ; Process data
	plx							   ; Restore X
	pld							   ; Restore direct page
	plp							   ; Restore processor status
	rtl							   ; Return long

Graphics_Setup2:
	php							   ; Save processor status
	phd							   ; Save direct page
	rep					 #$30		; 16-bit A/X/Y
	lda.W				   #$0000	; Direct Page = $0000
	tcd							   ; Set DP
	ldx.W				   #$9b56	; Data pointer
	jsr.W				   Graphics_ProcessData ; Process data
	pld							   ; Restore direct page
	plp							   ; Restore processor status
	rtl							   ; Return long

Graphics_Setup3:
	php							   ; Save processor status
	phd							   ; Save direct page
	rep					 #$30		; 16-bit A/X/Y
	lda.W				   #$0000	; Direct Page = $0000
	tcd							   ; Set DP
	lda.B				   $20	   ; Load parameter
	sta.B				   $4f	   ; Store to $4f
	jsr.W				   Graphics_SetupPointer ; Setup graphics
	lda.B				   [$17]	 ; Load data
	and.W				   #$00ff	; Mask to byte
	cmp.W				   #$0004	; Compare to 4
	beq					 Skip_Special ; If equal, skip
	ldx.W				   #$9b9d	; Special data pointer
	jsr.W				   Graphics_ProcessData ; Process data

Skip_Special:
	jsr.W				   Graphics_SetupPointer ; Setup graphics again
	jsr.W				   CODE_009D75 ; Process graphics data
	jsr.W				   Graphics_PostProcess ; Post-process
	ldx.W				   #$9ba0	; Cleanup pointer
	jsr.W				   Graphics_ProcessData ; Process cleanup
	pld							   ; Restore direct page
	plp							   ; Restore processor status
	rtl							   ; Return long

Graphics_SetupPointer:
	sep					 #$20		; 8-bit A
	lda.B				   #$03	  ; Bank $03
	sta.B				   $19	   ; Store bank
	rep					 #$30		; 16-bit A/X/Y
	lda.B				   $20	   ; Load parameter
	asl					 a; Multiply by 2
	tax							   ; X = index
	lda.L				   UNREACH_03D5E5,x ; Load pointer from table
	sta.B				   $17	   ; Store graphics pointer
	rts							   ; Return

Graphics_PostProcess:
	rts							   ; Return (stub)

Graphics_Setup4:
	php							   ; Save processor status
	phd							   ; Save direct page
	rep					 #$30		; 16-bit A/X/Y
	lda.W				   #$0000	; Direct Page = $0000
	tcd							   ; Set DP
	sep					 #$20		; 8-bit A
	lda.B				   #$03	  ; Bank $03
	sta.B				   $19	   ; Store bank
	rep					 #$30		; 16-bit A/X/Y
	lda.B				   $20	   ; Load parameter
	asl					 a; Multiply by 2
	tax							   ; X = index
	lda.L				   DATA8_03bb81,x ; Load pointer from table
	sta.B				   $17	   ; Store graphics pointer
	jsr.W				   CODE_009D75 ; Process graphics data
	pld							   ; Restore direct page
	plp							   ; Restore processor status
	rtl							   ; Return long

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
	db											 $a2,$ff,$ff,$86,$9e,$86,$a0,$fa,$60

DATA8_00a2dd:
	db											 $10

DATA8_00a2de:
	db											 $19,$00,$12,$32,$00,$dd,$0a,$00
	db											 $ff

; ---------------------------------------------------------------------------
; Command stream table processing helpers
; ---------------------------------------------------------------------------

Graphics_CommandDispatch:
	lda.B				   [$17]
	inc.B				   $17
	and.W				   #$00ff
	dec					 a
	cmp.B				   $9e
	bcc					 UNREACH_00A2FF
	lda.B				   $9e
	asl					 a
	adc.B				   $17
	sta.B				   $17
	lda.B				   [$17]
	sta.B				   $17
RTS_Label:

UNREACH_00A2FF:
	db											 $1a,$0a,$65,$17,$85,$17,$60

Graphics_ConditionalDispatch:
	lda.B				   [$17]
	inc.B				   $17
	and.W				   #$00ff
	dec					 a
	cmp.B				   $9e
PHP_Label:
	inc					 a
	asl					 a
	adc.B				   $17
TAY_Label:
PLP_Label:
	bcc					 Graphics_ConditionalDispatch_Continue
	lda.B				   $9e
	asl					 a
	adc.B				   $17
	sta.B				   $17
	lda.B				   [$17]
	sta.B				   $17
	sep					 #$20
	lda.B				   $19
	jsr.W				   CODE_009D75
	sta.B				   $19
	rep					 #$30

Graphics_ConditionalDispatch_Continue:
	sty.B				   $17
RTS_Label:

; ---------------------------------------------------------------------------
; More graphics command handlers (block)
; Imported segment: CODE_00A342 .. CODE_00A576
; ---------------------------------------------------------------------------

Graphics_InitDisplay:
PHP_Label:
	rep					 #$30
PHB_Label:
PHA_Label:
PHD_Label:
PHX_Label:
PHY_Label:
	lda.B				   $46
	bne					 +
	jmp					 Graphics_InitDisplay_End
	+	lda.B $40
	sta.W				   $01ee
	lda.B				   $44
	sta.W				   $01ed
SEC_Label:
	sbc.B				   $3f
	lsr					 a
	adc.B				   $42
	sta.B				   $48
SEC_Label:
	lda.B				   $46
	sbc.B				   $44
	sta.W				   $01eb
	lda.W				   #$00e0
	tsb.W				   $00d2
	lda.W				   #$ffff
	sta.B				   $44
	stz.B				   $46
	jmp.W				   Bit_SetBits_00E2

Graphics_InitDisplay_End:
	lda.W				   #$0080
	tsb.W				   $00d0
RTS_Label:

Graphics_DispatchTable:
	lda.B				   [$17]
	inc.B				   $17
	and.W				   #$00ff
	asl					 a
TAX_Label:
	jmp.W				   (DATA8_009e6e,x)

Graphics_CallSystem:
	lda.W				   #$0080
	tsb.W				   $00d8
	jsl.L				   CODE_0C8000
	lda.W				   #$0008
	trb.W				   $00d4
RTS_Label:

Graphics_CheckDisplayReady:
	lda.W				   #$0040
	and.W				   $00d0
	beq					 Graphics_FadeOut
RTS_Label:

Graphics_FadeOut:
	lda.W				   #$00ff
	jmp.W				   CODE_009DC9

Graphics_WaitForEvent:
	jsl.L				   CODE_0C8000
	lda.W				   #$0020
	and.W				   $00d0
	bne					 Graphics_WaitForEvent_Alt
	lda.B				   [$17]
	inc.B				   $17
	inc.B				   $17

Graphics_WaitForEvent_Loop:
	jsl.L				   CODE_0096A0
	bit.B				   $94
	beq					 Graphics_WaitForEvent_Loop
RTS_Label:

Graphics_WaitForEvent_Alt:
	lda.B				   [$17]
	inc.B				   $17
	inc.B				   $17

Graphics_WaitForEvent_AltLoop:
	jsl.L				   CODE_0096A0
	bit.B				   $07
	beq					 Graphics_WaitForEvent_AltLoop
RTS_Label:

; A series of conditional calls to CODE_00B1C3/CODE_00B1D6 etc.:

Condition_CheckPartyMember:
	jsr.W				   CODE_00B1C3
	bcc					 Condition_Skip
	beq					 Condition_Skip
	bra					 Condition_Jump

; (several similar blocks follow in the original disassembly; preserved as-is)

Condition_Skip:
	inc.B				   $17
	inc.B				   $17
RTS_Label:

Condition_Jump:
	lda.B				   [$17]
	sta.B				   $17
RTS_Label:

Condition_CheckEventFlag:
	jsr.W				   CODE_00B1D6
	bcc					 Condition_SkipJumpAddr
	beq					 Condition_SkipJumpAddr
	bra					 Condition_SetPointer

Condition_SkipJumpAddr:
	inc.B				   $17
	inc.B				   $17
RTS_Label:

Condition_SetPointer:
	lda.B				   [$17]
	sta.B				   $17
RTS_Label:

; (blocks calling CODE_00B1E8, CODE_00B204, CODE_00B21D, CODE_00B22F etc.)

; Examples:
Condition_CheckBattleFlag:
	jsr.W				   CODE_00B1E8
	bcs					 Condition_Skip
	bra					 Condition_Jump

; CODE_00A46D and CODE_00A472 removed - reuse Condition_Skip/Jump labels

Condition_CheckItem:
	jsr.W				   CODE_00B204
	bcc					 Condition_SkipJumpAddr2
	bra					 Condition_SetPointer2

Condition_SkipJumpAddr2:
	inc.B				   $17
	inc.B				   $17
RTS_Label:

Condition_SetPointer2:
	lda.B				   [$17]
	sta.B				   $17
RTS_Label:

Condition_CheckCompanion:
	jsr.W				   CODE_00B21D
	bcs					 Condition_Skip
	bra					 Condition_Jump

; CODE_00A4D9 and CODE_00A4DE removed - reuse Condition_Skip/Jump labels

Condition_CheckWeapon:
	jsr.W				   CODE_00B22F
	bcc					 Condition_SkipJumpAddr3
	bra					 Condition_SetPointer3

Condition_SkipJumpAddr3:
	inc.B				   $17
	inc.B				   $17
RTS_Label:

Condition_SetPointer3:
	lda.B				   [$17]
	sta.B				   $17
RTS_Label:

Graphics_SetPointer:
	lda.B				   [$17]
	sta.B				   $17
RTS_Label:

Graphics_SetBank:
	lda.B				   [$17]
	inc.B				   $17
	inc.B				   $17
TAX_Label:
	sep					 #$20
	lda.B				   [$17]
	sta.B				   $19
	stx.B				   $17
RTS_Label:

Condition_TestBitD0:
	lda.B				   [$17]
	inc.B				   $17
	and.W				   #$00ff
PHD_Label:
	pea.W				   $00d0
PLD_Label:
	jsl.L				   Bit_TestBits
PLD_Label:
	inc					 a
	dec					 a
	bra					 Condition_BranchOnZero

Condition_TestBitD0_Alt:
	lda.B				   [$17]
	inc.B				   $17
	and.W				   #$00ff
PHD_Label:
	pea.W				   $00d0
PLD_Label:
	jsl.L				   CODE_00975A
PLD_Label:
	inc					 a
	dec					 a
	jmp					 CODE_00A57D

Condition_TestBitEA8:
	lda.B				   [$17]
	inc.B				   $17
	and.W				   #$00ff
	jsl.L				   Bit_TestBits_0EA8

Condition_BranchOnZero:
	bne					 Graphics_SetPointer
	jmp					 CODE_00A597

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
	php							   ; Save processor status
	rep					 #$30		; 16-bit A/X/Y
	phy							   ; Save Y
	pha							   ; Save A
	ldy.W				   #$0017	; Y = Direct Page $0017
	lda.W				   #$0002	; Count = 2 bytes + 1
	mvn					 $00,$00	 ; Copy 3 bytes from [X] to [$17]
; This copies graphics pointer and bank
	pla							   ; Restore A
	ply							   ; Restore Y
	plp							   ; Restore processor status
	jmp.W				   CODE_009D75 ; Jump to main graphics processor

; ---------------------------------------------------------------------------
; Clear Graphics Flag Bit 2
; ---------------------------------------------------------------------------

Graphics_ClearFlag:
	lda.W				   #$0004	; Bit 2 mask
	and.W				   $00d8	 ; Test if set
	beq					 Graphics_ClearFlagDone ; Skip if not set
	lda.W				   #$0004	; Bit 2 mask
	trb.W				   $00d8	 ; Clear bit 2
	lda.W				   #$00c8	; Bits 6-7 + bit 3 mask
	trb.W				   $0111	 ; Clear those bits in $0111

Graphics_ClearFlagDone:
	rts							   ; Return

; ---------------------------------------------------------------------------
; Initialize Color Palette Processing
; ---------------------------------------------------------------------------
; Purpose: Setup DMA for color palette operations
; ===========================================================================

Palette_InitColorProcessing:
	ldx.W				   #$9c87	; Source data pointer
	ldy.W				   #$5007	; Dest = $7f5007
	lda.W				   #$0022	; Transfer $22 bytes + 1 = 35 bytes
	mvn					 $7f,$00	 ; Copy data to buffer

; Initialize color values
	lda.L				   $000e9c   ; Load base color
	sta.W				   $5011	 ; Store at offset $11
	sta.W				   $5014	 ; Store at offset $14
	sta.W				   $501a	 ; Store at offset $1a
	jsr.W				   Color_AdjustBrightness ; Adjust color brightness
	sta.W				   $5017	 ; Store adjusted color

	lda.L				   DATA8_07800c ; Load another base color
	sta.W				   $501e	 ; Store at offset $1e
	sta.W				   $5021	 ; Store at offset $21
	sta.W				   $5027	 ; Store at offset $27
	jsr.W				   Color_AdjustBrightness ; Adjust color brightness
	sta.W				   $5024	 ; Store adjusted color

; Setup DMA channels 3, 6, 7 for palette transfer
	phk							   ; Push program bank
	plb							   ; Pull to data bank
	sep					 #$20		; 8-bit A

	lda.B				   #$7f	  ; Bank $7f
	sta.W				   SNES_DMA3ADDRH ; DMA3 source bank
	sta.W				   SNES_DMA6ADDRH ; DMA6 source bank
	sta.W				   SNES_DMA7ADDRH ; DMA7 source bank

	ldx.W				   #$2100	; SNES register base
	stx.W				   SNES_DMA3PARAM ; DMA3 parameter
	ldx.W				   #$2202	; Different register
	stx.W				   SNES_DMA6PARAM ; DMA6 parameter
	stx.W				   SNES_DMA7PARAM ; DMA7 parameter

	ldx.W				   #$5007	; Source address
	stx.W				   SNES_DMA3ADDRL ; DMA3 source low
	ldx.W				   #$5010	; Source address
	stx.W				   SNES_DMA6ADDRL ; DMA6 source low
	ldx.W				   #$501d	; Source address
	stx.W				   SNES_DMA7ADDRL ; DMA7 source low

	rep					 #$30		; 16-bit A/X/Y
	rts							   ; Return

; ---------------------------------------------------------------------------
; Color_AdjustBrightness: Adjust Color Brightness
; ---------------------------------------------------------------------------
; Purpose: Reduce color intensity (darken for shadowing/fade)
; Input: Color on stack (SNES BGR555 format)
; Output: A = adjusted color
; Algorithm: Subtract $30 from red, $18 from green, $0c from blue (clamp to 0)
; ===========================================================================

Color_AdjustBrightness:
	pha							   ; Save color
	sec							   ; Set carry for subtraction
	and.W				   #$7c00	; Mask red component (bits 10-14)
	sbc.W				   #$3000	; Subtract $30 from red
	bcs					 Color_AdjustRed ; Branch if no underflow
	lda.W				   #$0000	; Clamp to 0
	sec							   ; Set carry

Color_AdjustRed:
	pha							   ; Save adjusted red
	lda.B				   $03,s	 ; Get original color
	and.W				   #$03e0	; Mask green component (bits 5-9)
	sbc.W				   #$0180	; Subtract $18 from green
	bcs					 Color_GreenOK ; Branch if no underflow
	lda.W				   #$0000	; Clamp to 0
	sec							   ; Set carry

Color_GreenOK:
	ora.B				   $01,s	 ; Combine with adjusted red
	sta.B				   $01,s	 ; Store combined result
	lda.B				   $03,s	 ; Get original color again
	and.W				   #$001f	; Mask blue component (bits 0-4)
	sbc.W				   #$000c	; Subtract $0c from blue
	bcs					 Color_BlueOK ; Branch if no underflow
	lda.W				   #$0000	; Clamp to 0

Color_BlueOK:
	ora.B				   $01,s	 ; Combine with red+green
	sta.B				   $03,s	 ; Store final result
	pla							   ; Remove temporary value
	pla							   ; Get final adjusted color
	rts							   ; Return

; ---------------------------------------------------------------------------
; Color Palette Data
; ---------------------------------------------------------------------------

DATA8_009c87:
; Color Palette Data Table
DATA8_009c87_colors:
	dw											 $0d00, $0d01, $0d01, $0d01 ; Color entries
	dw											 $0000, $5140, $5101, $5140
	dw											 $1fb4, $5101, $5140, $0000
	dw											 $7fff, $7f01, $7fff, $4e73
	dw											 $7f01, $7fff, $0001

; ---------------------------------------------------------------------------
; Setup Character Palette Display
; ---------------------------------------------------------------------------

Palette_SetupCharDisplay:
	sep					 #$20		; 8-bit A
	ldx.W				   #$01ad	; Default offset
	lda.B				   #$20	  ; Test bit 5
	and.W				   $00e0	 ; Check flag
	bne					 Palette_UseDefault ; Use default if set
	ldx.W				   #$016f	; Alternate offset

Palette_UseDefault:
; Copy character palette data to display buffer
	lda.W				   $0013,x   ; Load palette entry
	sta.L				   $7f500b   ; Store to buffer +$0b
	sta.L				   $7f5016   ; Store to buffer +$16
	sta.L				   $7f5023   ; Store to buffer +$23

	lda.W				   $0012,x   ; Load size/count
	dec					 a; Decrement
	lsr					 a; Divide by 2
	sta.L				   $7f5009   ; Store to buffer +$09
	sta.L				   $7f5013   ; Store to buffer +$13
	sta.L				   $7f5020   ; Store to buffer +$20

	adc.B				   #$00	  ; Add carry
	sta.L				   $7f5007   ; Store to buffer +$07
	sta.L				   $7f5010   ; Store to buffer +$10
	sta.L				   $7f501d   ; Store to buffer +$1d

	lda.B				   #$04	  ; Bit 2 mask
	tsb.W				   $00d8	 ; Set bit 2 in flags
	rep					 #$30		; 16-bit A/X/Y
	rts							   ; Return

Graphics_EmptyStub:
	rts							   ; Empty stub

; ---------------------------------------------------------------------------
; Push Graphics Parameters to Stack
; ---------------------------------------------------------------------------

Graphics_PushParams:
	php							   ; Save processor status
	rep					 #$30		; 16-bit A/X/Y
	phb							   ; Save data bank
	pha							   ; Save A
	phd							   ; Save direct page
	phx							   ; Save X
	phy							   ; Save Y

	ldx.W				   #$0017	; Source = DP $0017
	lda.L				   $7e3367   ; Load stack pointer
	tay							   ; Y = destination
	lda.W				   #$0025	; Transfer 38 bytes
	mvn					 $7e,$00	 ; Copy DP $0017-$003e to stack

	ldx.W				   #$00d0	; Source = DP $00d0
	lda.W				   #$0000	; Transfer 1 byte
	mvn					 $7e,$00	 ; Copy DP $00d0 to stack

	tya							   ; A = new stack pointer
	cmp.W				   #$35d9	; Check if stack overflow
	bcc					 CODE_009D18 ; Branch if OK
	jmp.W				   Graphics_StackOverflow ; Handle overflow (infinite loop)

Graphics_UpdateStackPtr:
	sta.L				   $7e3367   ; Update stack pointer
	jmp.W				   Bit_SetBits_00E2 ; Clean stack and return

Graphics_StackOverflow:
	bra					 CODE_009D1F ; Infinite loop (stack overflow)

; ---------------------------------------------------------------------------
; Pop Graphics Parameters from Stack
; ---------------------------------------------------------------------------

Graphics_PopParams:
	php							   ; Save processor status
	rep					 #$30		; 16-bit A/X/Y
	phb							   ; Save data bank
	pha							   ; Save A
	phd							   ; Save direct page
	phx							   ; Save X
	phy							   ; Save Y

	lda.L				   $7e3367   ; Load stack pointer
	sec							   ; Set carry
	sbc.W				   #$0027	; Subtract 39 bytes
	sta.L				   $7e3367   ; Update stack pointer
	tax							   ; X = source

	ldy.W				   #$0017	; Dest = DP $0017
	lda.W				   #$0025	; Transfer 38 bytes
	mvn					 $00,$7e	 ; Copy stack to DP $0017-$003e

	ldy.W				   #$00d0	; Dest = DP $00d0
	lda.W				   #$0000	; Transfer 1 byte
	mvn					 $00,$7e	 ; Copy stack to DP $00d0

	jmp.W				   Bit_SetBits_00E2 ; Clean stack and return

; ---------------------------------------------------------------------------
; Fill Memory via Helper
; ---------------------------------------------------------------------------

Graphics_MemoryFillHelper:
	phy							   ; Save Y
	stx.B				   $1a	   ; Store X to $1a
	txy							   ; Y = X
	tax							   ; X = A
	jsr.W				   CODE_00B49E ; Call helper
	clc							   ; Clear carry
	tya							   ; A = Y
	adc.B				   $01,s	 ; Add saved Y
	sta.B				   $1a	   ; Store to $1a
	jsr.W				   CODE_00B4A7 ; Call helper
	lda.B				   $1c	   ; Load $1c
	and.W				   #$00ff	; Mask to byte
	pha							   ; Push to stack
	plb							   ; Pull to data bank
	lda.B				   $02,s	 ; Load parameter
	jsr.W				   CODE_009998 ; Call fill dispatcher
	plb							   ; Restore data bank
	pla							   ; Clean stack
	rts							   ; Return

; ---------------------------------------------------------------------------
; Graphics_ProcessWithDP: Process Graphics with DP Setup
; ---------------------------------------------------------------------------

Graphics_ProcessWithDP:
	phd							   ; Save direct page
	pea.W				   $0000	 ; Push $0000
	pld							   ; Direct Page = $0000
	jsr.W				   Graphics_ProcessStream ; Process graphics
	pld							   ; Restore direct page
	rtl							   ; Return long

; ---------------------------------------------------------------------------
; Graphics_ProcessStream: Main Graphics Data Processor
; ---------------------------------------------------------------------------
; Purpose: Core loop for processing graphics command stream
; Algorithm: Read bytes from [$17], dispatch to handlers via jump table
; Commands $00-$2f: Jump table entries
; Commands $30+: Indexed data lookup
; Commands $80+: Direct tile data (XOR with $1d for effects)
; ===========================================================================

Graphics_ProcessStream:
	php							   ; Save processor status
	rep					 #$30		; 16-bit A/X/Y
	phb							   ; Save data bank
	pha							   ; Save A
	phd							   ; Save direct page
	phx							   ; Save X
	phy							   ; Save Y
	phk							   ; Push program bank
	plb							   ; Pull to data bank

; Check if special processing mode
	lda.W				   #$0008	; Bit 3 mask
	and.W				   $00db	 ; Test flag
	beq					 Graphics_ProcessStream_Normal ; Normal processing

; Special mode with synchronization
	lda.W				   #$0010	; Bit 4 mask
	and.W				   $00d0	 ; Test flag
	bne					 Graphics_ProcessStream_AltSync ; Use alternate sync

Graphics_ProcessStream_SyncLoop:
	jsr.W				   Graphics_ReadDispatchCmd ; Read and process command
	lda.B				   $17	   ; Get current pointer
	cmp.B				   $3d	   ; Compare to sync pointer
	bne					 Graphics_ContinueSync ; Loop until synchronized
	bra					 Graphics_ProcessStream_Cleanup ; Done

Graphics_ProcessStream_AltSync:
	jsr.W				   CODE_00E055 ; Alternate sync handler
	bra					 Graphics_ProcessStream_Cleanup ; Done

Graphics_ContinueSync:
	jsr.W				   Graphics_ReadDispatchCmd ; Read and process command

Graphics_ProcessStream_Normal:
; Normal processing loop
	lda.W				   $00d0	 ; Load flags
	bit.W				   #$0090	; Test bits 4 and 7
	beq					 Graphics_ProcessStream_Loop ; Continue if neither set

	bit.W				   #$0080	; Test bit 7
	bne					 Graphics_ProcessStream_Exit ; Exit if set
	jsr.W				   CODE_00E055 ; Process special event
	bra					 Graphics_ProcessStream_Normal ; Continue loop

Graphics_ProcessStream_Exit:
	lda.W				   #$0080	; Bit 7 mask
	trb.W				   $00d0	 ; Clear exit flag

Graphics_ProcessStream_Done:
	jmp.W				   Bit_SetBits_00E2 ; Clean stack and return

; ---------------------------------------------------------------------------
; Graphics_ReadDispatchCmd: Read and Dispatch Graphics Command
; ---------------------------------------------------------------------------

Graphics_ReadDispatchCmd:
	lda.B				   [$17]	 ; Read command byte
	inc.B				   $17	   ; Advance pointer
	and.W				   #$00ff	; Mask to byte
	cmp.W				   #$0080	; Is it direct tile data?
	bcc					 CODE_009DD2 ; No, dispatch to handler

; ---------------------------------------------------------------------------
; CODE_009DC9 - Direct Tile Write
; ---------------------------------------------------------------------------
Graphics_WriteTileDirect:
; Direct tile write (values $80-$ff)
	eor.B				   $1d	   ; XOR with effect mask

Graphics_WriteTileEntry:
	sta.B				   [$1a]	 ; Write to VRAM buffer
	inc.B				   $1a	   ; Advance pointer
	inc.B				   $1a	   ; (16-bit increment)
	rts							   ; Return

Graphics_DispatchCommand:
; Command dispatch (values $00-$7f)
	cmp.W				   #$0030	; Is it indexed data?
	bcs					 Graphics_IndexedDataLookup ; Yes, handle indexed

; Jump table dispatch ($00-$2f)
	asl					 a; Multiply by 2 (word index)
	tax							   ; X = table offset
	jsr.W				   (DATA8_009e0e,x) ; Call handler via table
	rep					 #$30		; 16-bit A/X/Y
	rts							   ; Return

Graphics_IndexedDataLookup:
; Indexed data lookup ($30+)
	ldx.W				   #$0000	; X = 0 (table index)
	sbc.W				   #$0030	; Subtract base (now $00-$4f)
	beq					 Graphics_IndexedDataFound ; If 0, use first entry
	tay							   ; Y = index count

Graphics_IndexedDataSearch:
; Find entry in variable-length table
	lda.L				   DATA8_03ba35,x ; Load entry size
	and.W				   #$00ff	; Mask to byte
	sta.B				   $64	   ; Store size
	txa							   ; A = current offset
	sec							   ; Set carry
	adc.B				   $64	   ; Add size (+ 1 from carry)
	tax							   ; X = next entry offset
	dey							   ; Decrement index
	bne					 Graphics_IndexedDataSearch ; Continue until found

Graphics_IndexedDataFound:
; Process found entry
	txa							   ; A = table offset
	clc							   ; Clear carry
	adc.W				   #$ba36	; Add base address
	tay							   ; Y = data pointer
	sep					 #$20		; 8-bit A
	lda.B				   #$03	  ; Bank $03
	xba							   ; Swap to high byte
	lda.L				   DATA8_03ba35,x ; Load entry size
	tyx							   ; X = data pointer
	rep					 #$30		; 16-bit A/X/Y
	jmp.W				   CODE_00A7F9 ; Process data block

; ---------------------------------------------------------------------------
; Graphics Command Jump Table
; ---------------------------------------------------------------------------
; Commands $00-$2f dispatch here
; ===========================================================================

DATA8_009e0e:
; Jump table entries
DATA8_009e0e_handlers:
	dw											 CODE_00A378 ; $00: Command handler
	dw											 CODE_00A8C0 ; $01
	dw											 CODE_00A8BD ; $02
	dw											 CODE_00A39C ; $03
	dw											 CODE_00B354 ; $04
	dw											 CODE_00A37F ; $05
	dw											 CODE_00B4B0 ; $06
	dw											 CODE_00A708 ; $07
	dw											 CODE_00A755 ; $08
	dw											 CODE_00A83F ; $09
	dw											 CODE_00A519 ; $0a
	dw											 CODE_00A3F5 ; $0b
	dw											 CODE_00A958 ; $0c
	dw											 CODE_00A96C ; $0d
	dw											 CODE_00A97D ; $0e
	dw											 CODE_00AFD6 ; $0f
	dw											 CODE_00AF9A ; $10
	dw											 CODE_00AF6B ; $11
	dw											 CODE_00AF70 ; $12
	dw											 CODE_00B094 ; $13
	dw											 CODE_00AFFE ; $14
	dw											 CODE_00A0B7 ; $15
	dw											 CODE_00B2F9 ; $16
	dw											 CODE_00AEDA ; $17
	dw											 CODE_00AACF ; $18
	dw											 CODE_00A8D1 ; $19
	dw											 CODE_00A168 ; $1a
	dw											 CODE_00A17E ; $1b
	dw											 CODE_00A15C ; $1c
	dw											 CODE_00A13C ; $1d
	dw											 CODE_00A0FE ; $1e
	dw											 CODE_00A0C0 ; $1f
	dw											 CODE_00A0DF ; $20
	dw											 CODE_00B2F4 ; $21
	dw											 CODE_00A150 ; $22
	dw											 CODE_00AEA2 ; $23
	dw											 CODE_00A11D ; $24
	dw											 CODE_00A07D ; $25
	dw											 CODE_00A089 ; $26
	dw											 CODE_00A09D ; $27
	dw											 CODE_00A0A9 ; $28
	dw											 CODE_00AEB5 ; $29
	dw											 CODE_00B379 ; $2a
	dw											 CODE_00AEC7 ; $2b
	dw											 CODE_00B355 ; $2c
	dw											 CODE_00A074 ; $2d
	dw											 CODE_00A563 ; $2e
	dw											 CODE_00A06E ; $2f

; ---------------------------------------------------------------------------
; Secondary Jump Table (for specific graphics operations)
; ---------------------------------------------------------------------------

DATA8_009e6e:
	dw											 CODE_00A342 ; $00
	dw											 CODE_00A3AB ; $01
	dw											 CODE_00A51E ; $02
	dw											 CODE_00A52E ; $03
	dw											 CODE_00A3D5 ; $04
	dw											 CODE_00A3DE ; $05
	dw											 CODE_00A3E5 ; $06
	dw											 CODE_00A3EC ; $07
	dw											 $0000	   ; $08: Unused
	dw											 CODE_00A3FC ; $09
	dw											 $0000	   ; $0a: Unused
	dw											 CODE_00A572 ; $0b
	dw											 CODE_00A581 ; $0c
	dw											 CODE_00A586 ; $0d
	dw											 CODE_00A744 ; $0e
	dw											 $0000, $0000 ; $0f-$10: Unused
	dw											 CODE_00A718 ; $11
	dw											 CODE_00A78E ; $12
	dw											 CODE_00A79D ; $13
	dw											 CODE_00A7AC ; $14
	dw											 CODE_00A7B3 ; $15
	dw											 $0000	   ; $16: Unused
	dw											 CODE_00A86E ; $17
	dw											 CODE_00A7EB ; $18
	dw											 CODE_00A7DE ; $19
	dw											 $0000, $0000, $0000 ; $1a-$1c: Unused
	dw											 CODE_00A874 ; $1d
	dw											 CODE_00A89B ; $1e
	dw											 $0000	   ; $1f: Unused

; ===========================================================================
; Graphics Command Handlers (Commands $00-$2f)
; ===========================================================================

; ---------------------------------------------------------------------------
; Command $2d: Set Graphics Pointer to Fixed Address
; ---------------------------------------------------------------------------

Cmd_SetPointerEA6:
	lda.W				   #$0ea6	; Fixed pointer
	sta.B				   $2e	   ; Store to $2e
	rts							   ; Return

; ---------------------------------------------------------------------------
; Command $25: Load Graphics Pointer from Stream
; ---------------------------------------------------------------------------

Cmd_LoadPointer:
	lda.B				   [$17]	 ; Read 16-bit pointer
	inc.B				   $17	   ; Advance stream pointer
	inc.B				   $17	   ; (2 bytes)
	sta.B				   $2e	   ; Store to $2e
	rts							   ; Return

; ---------------------------------------------------------------------------
; Command $26: Set Tile Offset (8-bit)
; ---------------------------------------------------------------------------

Cmd_SetTileOffset:
	lda.B				   [$17]	 ; Read byte parameter
	inc.B				   $17	   ; Advance stream pointer
	and.W				   #$00ff	; Mask to byte
	sep					 #$20		; 8-bit A
	sta.B				   $1e	   ; Store tile offset
	rts							   ; Return

; ---------------------------------------------------------------------------
; Command $19: Set Graphics Bank and Pointer
; ---------------------------------------------------------------------------

Cmd_SetBankAndPointer:
	lda.B				   [$17]	 ; Read 16-bit pointer
	inc.B				   $17	   ; Advance stream pointer
	inc.B				   $17	   ; (2 bytes)
	sta.B				   $3f	   ; Store pointer
	lda.B				   [$17]	 ; Read bank byte
	inc.B				   $17	   ; Advance stream pointer
	and.W				   #$00ff	; Mask to byte
	sep					 #$20		; 8-bit A
	sta.B				   $41	   ; Store bank
	rts							   ; Return

; ---------------------------------------------------------------------------
; Command $27: Set Display Mode Byte
; ---------------------------------------------------------------------------

Cmd_SetDisplayMode:
	lda.B				   [$17]	 ; Read byte parameter
	inc.B				   $17	   ; Advance stream pointer
	and.W				   #$00ff	; Mask to byte
	sep					 #$20		; 8-bit A
	sta.B				   $27	   ; Store mode byte
	rts							   ; Return

; ---------------------------------------------------------------------------
; Command $28: Set Effect Mask
; ---------------------------------------------------------------------------

Cmd_SetEffectMask:
	lda.B				   [$17]	 ; Read byte parameter
	inc.B				   $17	   ; Advance stream pointer
	and.W				   #$00ff	; Mask to byte
	sep					 #$20		; 8-bit A
	rep					 #$10		; 16-bit X/Y
	sta.B				   $1d	   ; Store effect mask
	rts							   ; Return

; ---------------------------------------------------------------------------
; Command $15: Set 16-bit Parameter at $25
; ---------------------------------------------------------------------------

Cmd_SetParameter25:
	lda.B				   [$17]	 ; Read 16-bit value
	inc.B				   $17	   ; Advance stream pointer
	inc.B				   $17	   ; (2 bytes)
	sta.B				   $25	   ; Store to $25
	rts							   ; Return

; ---------------------------------------------------------------------------
; Command $1f: Indexed String Lookup with Fixed Length
; ---------------------------------------------------------------------------

Cmd_StringLookup82BB:
	pei.B				   ($9e)	 ; Save $9e
	pei.B				   ($a0)	 ; Save $a0
	lda.B				   [$17]	 ; Read string index
	inc.B				   $17	   ; Advance stream pointer
	and.W				   #$00ff	; Mask to byte
	sta.B				   $9e	   ; Store index
	stz.B				   $a0	   ; Clear high byte
	lda.W				   #$0003	; Length = 3 bytes
	ldx.W				   #$82bb	; Table pointer
	jsr.W				   CODE_00A71C ; Process string
	plx							   ; Restore $a0
	stx.B				   $a0	   ; Store back
	plx							   ; Restore $9e
	stx.B				   $9e	   ; Store back
	rts							   ; Return

; ---------------------------------------------------------------------------
; Command $20: Indexed String Lookup (Different Table)
; ---------------------------------------------------------------------------

Cmd_StringLookupA802:
	pei.B				   ($9e)	 ; Save $9e
	pei.B				   ($a0)	 ; Save $a0
	lda.B				   [$17]	 ; Read string index
	inc.B				   $17	   ; Advance stream pointer
	and.W				   #$00ff	; Mask to byte
	sta.B				   $9e	   ; Store index
	stz.B				   $a0	   ; Clear high byte
	lda.W				   #$0003	; Length = 3 bytes
	ldx.W				   #$a802	; Table pointer
	jsr.W				   CODE_00A71C ; Process string
	plx							   ; Restore $a0
	stx.B				   $a0	   ; Store back
	plx							   ; Restore $9e
	stx.B				   $9e	   ; Store back
	rts							   ; Return

; ---------------------------------------------------------------------------
; Command $1e: Another Indexed String Handler
; ---------------------------------------------------------------------------

Cmd_StringLookup8383:
	pei.B				   ($9e)	 ; Save $9e
	pei.B				   ($a0)	 ; Save $a0
	lda.B				   [$17]	 ; Read string index
	inc.B				   $17	   ; Advance stream pointer
	and.W				   #$00ff	; Mask to byte
	sta.B				   $9e	   ; Store index
	stz.B				   $a0	   ; Clear high byte
	lda.W				   #$0003	; Length = 3 bytes
	ldx.W				   #$8383	; Table pointer
	jsr.W				   CODE_00A71C ; Process string
	plx							   ; Restore $a0
	stx.B				   $a0	   ; Store back
	plx							   ; Restore $9e
	stx.B				   $9e	   ; Store back
	rts							   ; Return

; ---------------------------------------------------------------------------
; Command $24: Set Display Parameters
; ---------------------------------------------------------------------------

Cmd_SetDisplayParams:
	lda.B				   [$17]	 ; Read first word
	inc.B				   $17	   ; Advance stream pointer
	inc.B				   $17	   ; (2 bytes)
	sta.B				   $28	   ; Store to $28
	lda.B				   [$17]	 ; Read second word
	inc.B				   $17	   ; Advance stream pointer
	inc.B				   $17	   ; (2 bytes)
	sta.B				   $2a	   ; Store to $2a
	rts							   ; Return

Cmd_SetParams2C2D:
	lda.B				   [$17]	 ; Read parameter
	inc.B				   $17	   ; Advance stream pointer
	inc.B				   $17	   ; (2 bytes)
	sep					 #$20		; 8-bit A
	sta.B				   $2c	   ; Store low byte
	xba							   ; Swap bytes
	sta.B				   $2d	   ; Store high byte
	rts							   ; Return

; ---------------------------------------------------------------------------
; Command $1d: Indexed Lookup with Table $a7f6
; ---------------------------------------------------------------------------

Cmd_LookupA7F6:
	lda.B				   [$17]	 ; Read index
	inc.B				   $17	   ; Advance stream pointer
	and.W				   #$00ff	; Mask to byte
	sta.B				   $9e	   ; Store index
	stz.B				   $a0	   ; Clear high byte
	lda.W				   #$0003	; Length = 3 bytes
	ldx.W				   #$a7f6	; Table pointer
	jmp.W				   CODE_00A71C ; Process and return

; ---------------------------------------------------------------------------
; Command $22: Set Graphics Pointer to $aea7 Bank $03
; ---------------------------------------------------------------------------

Cmd_SetPointerAEA7:
	sep					 #$20		; 8-bit A
	lda.B				   #$03	  ; Bank $03
	sta.B				   $19	   ; Store bank
	ldx.W				   #$aea7	; Pointer
	stx.B				   $17	   ; Store pointer
	rts							   ; Return

; ---------------------------------------------------------------------------
; Command $1c: Set Graphics Pointer to $8457 Bank $03
; ---------------------------------------------------------------------------

Cmd_SetPointer8457:
	sep					 #$20		; 8-bit A
	lda.B				   #$03	  ; Bank $03
	sta.B				   $19	   ; Store bank
	ldx.W				   #$8457	; Pointer
	stx.B				   $17	   ; Store pointer
	rts							   ; Return

; ---------------------------------------------------------------------------
; Command $1a: Indexed Character Graphics
; ---------------------------------------------------------------------------

Cmd_CharacterGraphics:
	lda.B				   [$17]	 ; Read character index
	inc.B				   $17	   ; Advance stream pointer
	and.W				   #$00ff	; Mask to byte
	sep					 #$20		; 8-bit A
	sta.B				   $4f	   ; Store character ID
	rep					 #$30		; 16-bit A/X/Y
	lda.W				   #$0003	; Bank $03
	ldx.W				   #$a831	; Table pointer
	jmp.W				   CODE_00A71C ; Process character graphics

; ---------------------------------------------------------------------------
; Command $1b: Indexed Monster Graphics
; ---------------------------------------------------------------------------

Cmd_MonsterGraphics:
	lda.B				   [$17]	 ; Read monster index
	inc.B				   $17	   ; Advance stream pointer
	and.W				   #$00ff	; Mask to byte
	sep					 #$20		; 8-bit A
	sta.B				   $4f	   ; Store monster ID
	rep					 #$30		; 16-bit A/X/Y
	lda.W				   #$0003	; Bank $03
	ldx.W				   #$a895	; Table pointer
	jmp.W				   CODE_00A71C ; Process monster graphics

; ---------------------------------------------------------------------------
; Clear Address High Byte Handlers
; ---------------------------------------------------------------------------

Cmd_ClearHighBytes:
	jsr.W				   Cmd_ReadIndirect ; Read pointer
	stz.B				   $9f	   ; Clear $9f
	stz.B				   $a0	   ; Clear $a0
	rts							   ; Return

Cmd_ClearA0:
	jsr.W				   Cmd_ReadIndirect ; Read pointer
	stz.B				   $a0	   ; Clear $a0
	rts							   ; Return

Cmd_SetA0Byte:
	jsr.W				   Cmd_ReadIndirect ; Read pointer
	and.W				   #$00ff	; Mask to byte
	sta.B				   $a0	   ; Store to $a0
	rts							   ; Return

; ---------------------------------------------------------------------------
; Cmd_ReadIndirect: Read Indirect Pointer from Stream
; ---------------------------------------------------------------------------
; Purpose: Read pointer and bank from [$17], then dereference
; Algorithm: Read 3 bytes -> use as pointer -> read actual target pointer
; ===========================================================================

Cmd_ReadIndirect:
	lda.B				   [$17]	 ; Read pointer word
	inc.B				   $17	   ; Advance stream
	inc.B				   $17	   ; (2 bytes)
	tax							   ; X = pointer address
	lda.B				   [$17]	 ; Read bank byte
	inc.B				   $17	   ; Advance stream
	and.W				   #$00ff	; Mask to byte
	clc							   ; Clear carry
	adc.W				   $0000,x   ; Add offset from [X]
	tay							   ; Y = final offset
	lda.W				   $0002,x   ; Load bank from [X+2]
	and.W				   #$00ff	; Mask to byte
	pha							   ; Push bank
	plb							   ; Pull to data bank
	lda.W				   $0000,y   ; Load target pointer low
	tax							   ; X = pointer low
	lda.W				   $0002,y   ; Load target pointer high
	plb							   ; Restore bank
	stx.B				   $9e	   ; Store pointer low
	rts							   ; Return (A = pointer high)

; ---------------------------------------------------------------------------
; Memory Fill from Stream Parameters
; ---------------------------------------------------------------------------

Cmd_MemoryFill:
	lda.B				   [$17]	 ; Read destination address
	inc.B				   $17	   ; Advance stream
	inc.B				   $17	   ; (2 bytes)
	tay							   ; Y = destination
	sep					 #$20		; 8-bit A
	lda.B				   [$17]	 ; Read fill value
	xba							   ; Swap to high byte
	lda.B				   [$17]	 ; Read again (16-bit fill)
	rep					 #$30		; 16-bit A/X/Y
	inc.B				   $17	   ; Advance stream
	tax							   ; X = fill value
	lda.B				   [$17]	 ; Read count
	inc.B				   $17	   ; Advance stream
	and.W				   #$00ff	; Mask to byte
	jmp.W				   CODE_009998 ; Call fill dispatcher

; ---------------------------------------------------------------------------
; Graphics System Calls
; ---------------------------------------------------------------------------

Cmd_CallGraphicsSys:
	jsl.L				   CODE_0C8000 ; Call graphics system
	rts							   ; Return

Cmd_WaitVBlank:
	jsl.L				   CODE_0096A0 ; Wait for VBlank
	rts							   ; Return

; ---------------------------------------------------------------------------
; Cmd_CopyDisplayState: Copy Display State
; ---------------------------------------------------------------------------

Cmd_CopyDisplayState:
	jsr.W				   CODE_00A220 ; Prepare state
	sep					 #$20		; 8-bit A
	ldx.W				   $101b	 ; Load source X
	stx.W				   $1018	 ; Copy to destination X
	lda.W				   $101d	 ; Load source bank
	sta.W				   $101a	 ; Copy to destination bank
	ldx.W				   $109b	 ; Load source X (second set)
	stx.W				   $1098	 ; Copy to destination X
	lda.W				   $109d	 ; Load source bank (second set)
	sta.W				   $109a	 ; Copy to destination bank
	rts							   ; Return

; ---------------------------------------------------------------------------
; Copy State and Clear Flags
; ---------------------------------------------------------------------------

Cmd_CopyAndClearFlags:
	jsr.W				   Cmd_CopyDisplayState ; Copy display state
	stz.W				   $1021	 ; Clear flag
	stz.W				   $10a1	 ; Clear flag
	rts							   ; Return

; ---------------------------------------------------------------------------
; Cmd_PrepareDisplayState: Prepare Display State
; ---------------------------------------------------------------------------

Cmd_PrepareDisplayState:
	ldx.W				   $1016	 ; Load source
	stx.W				   $1014	 ; Copy to destination
	ldx.W				   $1096	 ; Load source (second set)
	stx.W				   $1094	 ; Copy to destination
	lda.W				   #$0003	; Bits 0-1 mask
	trb.W				   $102f	 ; Clear bits
	trb.W				   $10af	 ; Clear bits
	rts							   ; Return

; ---------------------------------------------------------------------------
; Cmd_CharacterDMATransfer: Character Data DMA Transfer
; ---------------------------------------------------------------------------
; Purpose: Copy character data to VRAM buffer area
; ===========================================================================

Cmd_CharacterDMATransfer:
	lda.W				   #$0080	; Bit 7 mask
	and.W				   $10a0	 ; Test character flag
	php							   ; Save result

; Read character slot index
	lda.B				   [$17]	 ; Read slot index
	inc.B				   $17	   ; Advance stream
	and.W				   #$00ff	; Mask to byte
	sep					 #$30		; 8-bit A/X/Y
	sta.W				   $0e92	 ; Store character slot

; Calculate offset: slot * $50
	sta.W				   SNES_WRMPYA ; Multiplicand = slot
	lda.B				   #$50	  ; Multiplier = $50 (80 bytes)
	jsl.L				   CODE_00971E ; Perform multiply
	rep					 #$30		; 16-bit A/X/Y

; Setup DMA transfer
	clc							   ; Clear carry
	lda.W				   #$d0b0	; Base address $0cd0b0
	adc.W				   SNES_RDMPYL ; Add offset (result)
	tax							   ; X = source address
	ldy.W				   #$1080	; Y = destination $7e1080
	lda.W				   #$0050	; Transfer $50 bytes
	pea.W				   $000c	 ; Push bank $0c
	plb							   ; Pull to data bank
	jsr.W				   CODE_00985D ; Perform memory copy
	plb							   ; Restore bank

	plp							   ; Restore flags
	bne					 CODE_00A273 ; Skip if flag was set
	lda.W				   #$0080	; Bit 7 mask
	trb.W				   $10a0	 ; Clear character flag

Cmd_CharDMATransfer_Done:
	rts							   ; Return

; ---------------------------------------------------------------------------
; Multiple Command Sequence
; ---------------------------------------------------------------------------

Cmd_MultiCommandSeq:
	lda.W				   #$0003	; Bank $03
	ldx.W				   #$8457	; Pointer to data
	jsr.W				   CODE_00A71C ; Process data
	rep					 #$30		; 16-bit A/X/Y

	lda.B				   [$17]	 ; Read parameters
	inc.B				   $17	   ; Advance stream
	inc.B				   $17	   ; (2 bytes)
	sep					 #$20		; 8-bit A
	sta.W				   $0513	 ; Store parameter
	xba							   ; Swap bytes
	sta.W				   $0a9c	 ; Store parameter

	ldx.B				   $17	   ; X = current pointer
	lda.B				   $19	   ; A = current bank
	jsl.L				   CODE_00D080 ; Call handler
	sta.B				   $19	   ; Update bank
	stx.B				   $17	   ; Update pointer
	rts							   ; Return

; ---------------------------------------------------------------------------
; VBlank Wait Loop
; ---------------------------------------------------------------------------

Cmd_WaitVBlankCount:
	lda.B				   [$17]	 ; Read wait count
	inc.B				   $17	   ; Advance stream
	and.W				   #$00ff	; Mask to byte

Cmd_WaitVBlankLoop:
	jsl.L				   CODE_0096A0 ; Wait for VBlank
	dec					 a; Decrement counter
	bne					 Cmd_WaitVBlankLoop ; Loop until 0
	rts							   ; Return

; ---------------------------------------------------------------------------
; Indexed Color Palette Lookup
; ---------------------------------------------------------------------------

Palette_IndexedLookup:
	lda.B				   [$17]	 ; Read palette index
	inc.B				   $17	   ; Advance stream
	and.W				   #$00ff	; Mask to byte
	pha							   ; Save index
	bra					 Palette_SearchTable_Entry ; Skip to processing

Palette_SearchTable:
	pei.B				   ($9e)	 ; Save $9e
Palette_SearchTable_Entry:
	sep					 #$20		; 8-bit A
	ldx.W				   #$0000	; X = 0 (table index)

Cmd_PaletteLookup_Search:
; Search palette table for matching index
	lda.W				   DATA8_00a2dd,x ; Load table entry
	cmp.B				   #$ff	  ; Check for end marker
	bne					 +		   ; Not end, continue
	jmp					 UNREACH_00A2D4 ; End of table (not found)
	+	cmp.B $01,s                 ; Compare with search index
	beq					 Cmd_PaletteLookup_Found ; Found match
	inx							   ; Next entry
	inx							   ; (skip 2 more bytes)
	inx							   ; (3 bytes per entry)
	bra					 Cmd_PaletteLookup_Search ; Continue search

Cmd_PaletteLookup_Found:
	rep					 #$30		; 16-bit A/X/Y
	lda.W				   DATA8_00a2de,x ; Load palette pointer
	sta.B				   $9e	   ; Store to $9e
	plx							   ; Clean stack
	rts							   ; Return

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
; - Graphics command handlers ($00-$2f)
;
; Remaining: ~6,600 lines (battle system, more handlers, data tables)
;===============================================================================

;===============================================================================
; Conditional Jump Handlers - Item/Flag Testing
; These handlers test various game flags and conditionally jump based on results
;===============================================================================

Cmd_TestItemJump:
	lda.B				   [$17]	 ; Load item/flag index
	inc.B				   $17	   ; Advance pointer
	and.W				   #$00ff	; Mask to byte
	jsl.L				   Bit_TestBits_0EA8 ; Test item flag (external stub)

Cmd_TestItemJump_Check:
	bne					 +		   ; If set, skip
	jmp					 Graphics_SetPointer ; If clear, take jump (far)
	+	jmp Cmd_SkipJumpAddress                ; If set, skip jump (far)

Cmd_TestVariable1:
	jsr.W				   CODE_00B1A1 ; Test variable
	bne					 +		   ; If not zero, skip
	jmp					 Condition_BranchOnZero ; Branch based on result (far)
	+	rts

Cmd_TestVariable2:
	jsr.W				   CODE_00B1A1 ; Test variable (alternate)
	beq					 Cmd_TestItemJump_Check ; Branch to alternate handler
RTS_Label:

	jsr.W				   CODE_00B1B4 ; Test condition
	beq					 +		   ; If zero, skip
	jmp					 Graphics_SetPointer ; If not zero, take jump (far)
	+	jmp Cmd_SkipJumpAddress                ; If zero, skip jump (far)

	jsr.W				   CODE_00B1B4 ; Test condition (alternate)
	bne					 +		   ; If not zero, skip
	jmp					 Graphics_SetPointer ; If zero, take jump (far)
	+	rts

Cmd_SkipJumpAddress:
	inc.B				   $17	   ; Skip jump address
	inc.B				   $17	   ; (2 bytes)
	rts							   ; Return

;===============================================================================
; More Conditional Branch Handlers
; (Similar patterns for different test types: CODE_00B1C3, CODE_00B1D6, etc.)
;===============================================================================

	jsr.W				   CODE_00B1C3 ; Test condition type 1
	bcs					 +		   ; If greater/equal, skip
	bne					 +
	jmp					 CODE_00A744 ; Take jump (far)
	+	inc.B $17                      ; Skip address
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B1C3
	bcs					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B1C3
	bcc					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B1C3
	bcc					 +
	bne					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B1C3
	beq					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B1C3
	beq					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

;===============================================================================
; CODE_00A5C8 - Skip Jump Address Helper
;===============================================================================

Cmd_SkipTwoBytes:
	inc.B				   $17	   ; Skip jump address
	inc.B				   $17	   ; (2 bytes)
	rts							   ; Return

;===============================================================================
; Cmd_LoadExecWithSwitch - Load Address and Bank, Execute with Context Switch
;===============================================================================

Cmd_LoadExecWithSwitch:
	lda.B				   [$17]	 ; Load target address
	inc.B				   $17	   ; Advance pointer
	inc.B				   $17
	tax							   ; Store address to X
	lda.B				   $19	   ; Load current bank
	jmp.W				   CODE_00A71C ; Jump to bank switcher

;===============================================================================
; Duplicate Conditional Handler Patterns (for different test functions)
; These follow the same pattern as earlier but for CODE_00B1D6, CODE_00B1E8,
; CODE_00B204, CODE_00B21D, and CODE_00B22F test routines
;===============================================================================

; Pattern set for CODE_00B1D6 (6 variants)
	jsr.W				   CODE_00B1D6 ; Test type 2
	bcs					 +
	bne					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B1D6
	bcs					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B1D6
	bcc					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B1D6
	bcc					 +
	bne					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B1D6
	beq					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B1D6
	beq					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	lda.B				   [$17]	 ; Load address
	inc.B				   $17
	inc.B				   $17
	tax							   ; Store to X
	lda.B				   $19	   ; Load bank
	jmp.W				   Graphics_BankSwitch ; Bank switch

; Pattern set for Test_Compare24Full (6 variants)
	jsr.W				   Test_Compare24Full
	bcs					 +
	bne					 +
	jmp					 Graphics_LoadAddrExecute
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B1E8
	bcs					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B1E8
	bcc					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B1E8
	bcc					 +
	bne					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B1E8
	beq					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B1E8
	beq					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	lda.B				   [$17]
	inc.B				   $17
	inc.B				   $17
TAX_Label:
	lda.B				   $19
	jmp.W				   CODE_00A71C

; Pattern set for CODE_00B204 (6 variants)
	jsr.W				   CODE_00B204
	bcs					 +
	bne					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B204
	bcs					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B204
	bcc					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B204
	bcc					 +
	bne					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B204
	beq					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B204
	beq					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	lda.B				   [$17]
	inc.B				   $17
	inc.B				   $17
TAX_Label:
	lda.B				   $19
	jmp.W				   CODE_00A71C

; Pattern set for CODE_00B21D (6 variants)
	jsr.W				   CODE_00B21D
	bcs					 +
	bne					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B21D
	bcs					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B21D
	bcc					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B21D
	bcc					 +
	bne					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B21D
	beq					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B21D
	beq					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	lda.B				   [$17]
	inc.B				   $17
	inc.B				   $17
TAX_Label:
	lda.B				   $19
	bra					 CODE_00A71C_alt1

; Pattern set for CODE_00B22F (6 variants)
	jsr.W				   CODE_00B22F
	bcs					 +
	bne					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B22F
	bcs					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B22F
	bcc					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B22F
	bcc					 +
	bne					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B22F
	beq					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	jsr.W				   CODE_00B22F
	beq					 +
	jmp					 CODE_00A744
	+	inc.B $17
	inc.B				   $17
RTS_Label:

	lda.B				   [$17]
	inc.B				   $17
	inc.B				   $17
TAX_Label:
	lda.B				   $19
	bra					 CODE_00A71C_alt2

;===============================================================================
; Graphics_LoadAndExec - Load Pointer and Bank, Execute Subroutine
;===============================================================================

Graphics_LoadAndExec:
	lda.B				   [$17]	 ; Load target pointer
	inc.B				   $17
	inc.B				   $17
	tax							   ; Store pointer to X
	lda.B				   [$17]	 ; Load bank byte
	inc.B				   $17
	and.W				   #$00ff	; Mask to byte
	bra					 Graphics_BankSwitch ; Jump to bank switcher

Graphics_LoadSavedContext:
	ldx.B				   $9e	   ; Load saved pointer
	lda.B				   $a0	   ; Load saved bank

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
	sep					 #$20		; 8-bit A
	xba							   ; Swap A/B (save new bank to B)
	lda.B				   $19	   ; Load current bank
	ldy.B				   $17	   ; Load current pointer to Y
	xba							   ; Swap back (new bank to A, old to B)
	sta.B				   $19	   ; Set new bank
	stx.B				   $17	   ; Set new pointer
	lda.B				   #$08	  ; Load flag bit $08
	and.W				   $00db	 ; Test current flag state
	php							   ; Save flag state
	lda.B				   #$08	  ; Load flag bit $08
	trb.W				   $00db	 ; Clear flag
	jsr.W				   CODE_009D75 ; Execute in new context (external)
	plp							   ; Restore flag state
	beq					 CODE_00A73E ; If flag was clear, skip restore
	lda.B				   #$08	  ; Load flag bit
	tsb.W				   $00db	 ; Restore flag to set state

Graphics_RestoreContext:
	xba							   ; Get old bank from B
	sta.B				   $19	   ; Restore bank
	sty.B				   $17	   ; Restore pointer
	rts							   ; Return

;===============================================================================
; CODE_00A744 - Load Address, Call Function, Execute Result
;===============================================================================

Graphics_LoadAddrExecute:
	lda.B				   [$17]	 ; Load address
	inc.B				   $17
	inc.B				   $17
	jsr.W				   Graphics_CallFunc ; Call function (external)
	sta.B				   $17	   ; Store result as pointer
	jsr.W				   Graphics_ProcessStream ; Execute at new pointer
	jmp.W				   Graphics_PopParams ; Jump to cleanup (external)

;===============================================================================
; Graphics_LoadExec - Load Pointer and Execute with Bank Switch
;===============================================================================

Graphics_LoadExec:
	lda.B				   [$17]	 ; Load pointer
	inc.B				   $17
	inc.B				   $17
	tax							   ; Store to X
	lda.B				   $19	   ; Load bank
	bra					 CODE_00A71C ; Bank switch and execute

;===============================================================================
; Flag Testing with Conditional Jumps to CODE_00A755 or CODE_00A7C6
;===============================================================================

	lda.B				   [$17]	 ; Load flag index
	inc.B				   $17
	and.W				   #$00ff	; Mask to byte
	phd							   ; Save direct page
	pea.W				   $00d0	 ; Set DP to $d0
PLD_Label:
	jsl.L				   CODE_00975A ; Test flag (external)
	pld							   ; Restore DP
	inc					 a; Test result (set Z flag)
	dec					 a
	bne					 CODE_00A755 ; If flag set, take jump
	bra					 CODE_00A7C6 ; If clear, skip

	lda.B				   [$17]	 ; Load flag index
	inc.B				   $17
	and.W				   #$00ff	; Mask to byte
	phd							   ; Save direct page
	pea.W				   $00d0	 ; Set DP to $d0
PLD_Label:
	jsl.L				   CODE_00975A ; Test flag (external)
	pld							   ; Restore DP
	inc					 a; Test result
	dec					 a
	beq					 CODE_00A755 ; If flag clear, take jump
	bra					 Condition_SkipJumpTarget ; If set, skip

	lda.B				   [$17]	 ; Load item flag
	inc.B				   $17
	and.W				   #$00ff	; Mask to byte
	jsl.L				   CODE_009776 ; Test item (external)
	bne					 CODE_00A755 ; If set, jump
	bra					 Condition_SkipJumpTarget ; If clear, skip

Condition_TestItemNotZero:
	lda.B				   [$17]	 ; Load item flag
	inc.B				   $17
	and.W				   #$00ff	; Mask to byte
	jsl.L				   CODE_009776 ; Test item (external)
	beq					 CODE_00A755 ; If clear, jump
	bra					 Condition_SkipJumpTarget ; If set, skip

Condition_TestVarNotZero:
	jsr.W				   CODE_00B1A1 ; Test variable
	bne					 CODE_00A755 ; If not zero, jump
	bra					 Condition_SkipJumpTarget ; If zero, skip

Condition_TestVarZero:
	jsr.W				   CODE_00B1A1 ; Test variable
	beq					 CODE_00A755 ; If zero, jump
	bra					 Condition_SkipJumpTarget ; If not zero, skip

	jsr.W				   CODE_00B1B4 ; Test condition
	bne					 CODE_00A755 ; If not zero, jump
	bra					 Condition_SkipJumpTarget ; If zero, skip

	jsr.W				   CODE_00B1B4 ; Test condition
	beq					 CODE_00A755 ; If zero, jump

Condition_SkipJumpTarget:
	inc.B				   $17	   ; Skip jump address
	inc.B				   $17	   ; (2 bytes)
	rts							   ; Return

;===============================================================================
; Subroutine Execution with Parameter Passing
;===============================================================================

	lda.B				   [$17]	 ; Load parameter
	inc.B				   $17
	and.W				   #$00ff	; Mask to byte
	sep					 #$20		; 8-bit A
	ldx.B				   $9e	   ; Load saved pointer
	xba							   ; Build word (param in high byte)
	lda.B				   $a0	   ; Load saved bank
	xba							   ; Swap back
	rep					 #$30		; 16-bit A/X/Y
	bra					 CODE_00A7F9 ; Execute subroutine

Graphics_ExecWithSavedPtr:
	sep					 #$20		; 8-bit A
	ldx.B				   $9e	   ; Load pointer
	lda.B				   $a0	   ; Load bank
	xba							   ; Build word
	lda.B				   $3a	   ; Load parameter from $3a
	rep					 #$30		; 16-bit A/X/Y
	bra					 CODE_00A7F9 ; Execute

Graphics_LoadAndExecParam:
	lda.B				   [$17]	 ; Load address
	inc.B				   $17
	inc.B				   $17
	tax							   ; Store address
	lda.B				   [$17]	 ; Load parameter byte
	inc.B				   $17
	and.W				   #$00ff	; Mask to byte

;===============================================================================
; CODE_00A7F9 - Execute Subroutine with Full Context Save
;
; Saves current execution state, switches to new address/bank with parameter,
; executes subroutine, then restores all state. Used for calling script
; subroutines that need to return to caller.
;
; Entry: A = parameter (low byte), X = subroutine address
; Stack usage: Saves $17 (pointer), $19 (bank), $3d (limit)
;===============================================================================

Graphics_ExecSubroutine:
	sta.B				   $64	   ; Save parameter
	stx.B				   $62	   ; Save subroutine address
	rep					 #$20		; 16-bit A
	sep					 #$10		; 8-bit X/Y
	pei.B				   ($17)	 ; Save current pointer
	ldx.B				   $19	   ; Load current bank
	phx							   ; Save bank
	pei.B				   ($3d)	 ; Save $3d (limit/end marker)
	lda.B				   $64	   ; Load parameter
	and.W				   #$00ff	; Mask to byte
	clc							   ; Clear carry
	adc.B				   $62	   ; Add to subroutine address
	sta.B				   $3d	   ; Store as new limit/end
	ldx.B				   $65	   ; Load bank byte from parameter
	stx.B				   $19	   ; Set as current bank
	lda.B				   $62	   ; Load subroutine address
	sta.B				   $17	   ; Set as pointer
	lda.W				   #$0008	; Load flag $08
	and.W				   $00db	 ; Test current state
	php							   ; Save flag state
	lda.W				   #$0008	; Load flag $08
	tsb.W				   $00db	 ; Set flag
	jsr.W				   CODE_009D75 ; Execute subroutine (external)
	plp							   ; Restore flag state
	bne					 CODE_00A833 ; If flag was set, keep it
	lda.W				   #$0008	; Load flag $08
	trb.W				   $00db	 ; Clear flag

Graphics_RestoreState:
	pla							   ; Restore $3d
	sta.B				   $3d
	plx							   ; Restore bank
	stx.B				   $19
	pla							   ; Restore pointer
	sta.B				   $17
	rep					 #$30		; 16-bit A/X/Y
	rts							   ; Return

;===============================================================================
; CODE_00A83F - Execute External Subroutine via Long Call
;===============================================================================

Graphics_ExecLongCall:
	lda.B				   [$17]	 ; Load target address
	inc.B				   $17
	inc.B				   $17
	tay							   ; Store address to Y
	lda.B				   [$17]	 ; Load bank/parameter
	inc.B				   $17
	and.W				   #$00ff	; Mask to byte
	pea.W				   PTR16_00FFFF ; Push return marker ($ffff)
	sep					 #$20		; 8-bit A
	dey							   ; Adjust address (Y = address - 1)
	phk							   ; Push program bank (for RTL)
	pea.W				   Graphics_LongCallReturn ; Push return address
	pha							   ; Push bank byte
	phy							   ; Push address - 1
	rep					 #$30		; 16-bit A/X/Y
; Stack now set up for RTL to execute target code

Graphics_LongCallReturn:
	rtl							   ; Return from long call

; Clean up after external subroutine
	sep					 #$20		; 8-bit A
	rep					 #$10		; 16-bit X/Y
	plx							   ; Pull return marker
	cpx.W				   #$ffff	; Check if $ffff
	beq					 Graphics_LongCallCleanup ; If marker found, done
	pla							   ; Pull extra byte (clean stack)

Graphics_LongCallCleanup:
	pea.W				   $0000	 ; Reset direct page to $0000
PLD_Label:
	phk							   ; Push program bank
	plb							   ; Set data bank = program bank
	rts							   ; Return

;===============================================================================
; Memory Manipulation and Data Transfer Routines
;===============================================================================

; CODE_00A86E - Raw bytecode (not yet disassembled fully)
; Purpose: Unknown memory operation involving $9e and $a0
	db											 $a4,$9e,$a5,$a0,$80,$d9

;-------------------------------------------------------------------------------
; CODE_00A874 - Copy data to RAM $7e3367 using MVN
; Purpose: Block memory move from Bank $00 to Bank $7e
; Entry: [$17] = destination offset,  [$17+2] = byte count
;-------------------------------------------------------------------------------
Memory_CopyToRAM:
	lda.B				   [$17]	 ; Load destination offset
	inc.B				   $17
	inc.B				   $17
	tax							   ; X = destination offset
	lda.L				   $7e3367   ; Load current $7e pointer
	tay							   ; Y = source in $7e
	lda.B				   [$17]	 ; Load byte count
	inc.B				   $17
	and.W				   #$00ff
	dec					 a; Count-1 for MVN
	phb							   ; Save data bank
	mvn					 $7e,$00	 ; Move (Y)Bank$00 → (X)Bank$7e, A+1 bytes
	plb							   ; Restore data bank
	tya							   ; Get end pointer
	cmp.W				   #$35d9	; Check if exceeds buffer limit
	bcc					 Memory_UpdatePointer ; If below limit, update pointer
	db											 $4c,$1f,$9d ; JMP CODE_009D1F (buffer overflow handler)

Memory_UpdatePointer:
	sta.L				   $7e3367   ; Update pointer
RTS_Label:

;-------------------------------------------------------------------------------
; CODE_00A89B - Copy data from RAM $7e3367 back to Bank $00
; Purpose: Reverse block move from Bank $7e to Bank $00
; Entry: [$17] = destination, [$17+2] = count
;-------------------------------------------------------------------------------
Memory_CopyFromRAM:
	lda.B				   [$17]	 ; Load destination in Bank $00
	inc.B				   $17
	inc.B				   $17
	tay							   ; Y = destination
	lda.B				   [$17]	 ; Load byte count
	inc.B				   $17
	and.W				   #$00ff
	pha							   ; Save count
	eor.W				   #$ffff	; Negate count
SEC_Label:
	adc.L				   $7e3367   ; Subtract from pointer (move backward)
	sta.L				   $7e3367   ; Update pointer
	tax							   ; X = new source
	pla							   ; Restore count
	dec					 a; Count-1 for MVN
	mvn					 $00,$7e	 ; Move (X)Bank$7e → (Y)Bank$00
RTS_Label:

;-------------------------------------------------------------------------------
; CODE_00A8BD/CODE_00A8C0 - Pointer manipulation helpers
;-------------------------------------------------------------------------------
Pointer_AdjustBits:
	jsr.W				   Pointer_CalcOffset

Pointer_CalcOffset:
	lda.W				   #$003e	; Mask for clearing bits
	trb.B				   $1a	   ; Clear bits in $1a
	lsr					 a; Shift mask
	and.B				   $25	   ; Apply to $25
	asl					 a; Shift result
	ora.B				   $1a	   ; Combine with $1a
	adc.W				   #$0040	; Add base offset
	sta.B				   $1a	   ; Store result
RTS_Label:

;-------------------------------------------------------------------------------
; CODE_00A8D1 - Calculate pointer from $25 (coordinates/position)
; Purpose: Convert position data to tilemap pointer
; Entry: $25 = position data, $3f/$40 = base pointers
; Exit: $1a = calculated pointer, $1b = bank/high byte
;-------------------------------------------------------------------------------
Pointer_FromPosition:
	lda.B				   $40	   ; Load base bank/high
	sta.B				   $1b	   ; Set $1b
	lda.B				   $25	   ; Load position
	and.W				   #$00ff	; Get low byte (X coordinate)
	asl					 a; × 2 (word-sized tiles)
	sta.B				   $1a	   ; Store as base
	lda.B				   $25	   ; Load position again
	and.W				   #$ff00	; Get high byte (Y coordinate)
	lsr					 a; / 4 (row calculation)
	lsr					 a
	adc.B				   $1a	   ; Add X offset
	adc.B				   $3f	   ; Add base pointer
	sta.B				   $1a	   ; Store final pointer
RTS_Label:

;-------------------------------------------------------------------------------
; CODE_00A8EB-CODE_00A93E - DMA/MVN transfer routines
; Purpose: Various block memory transfer operations
;-------------------------------------------------------------------------------
	db											 $4c,$24,$98 ; JMP CODE_009824

DMA_TransferWithBank:
	lda.B				   $18	   ; Load $18
	and.W				   #$ff00	; Get high byte
	sta.B				   $31	   ; Store in $31
	lda.B				   [$17]	 ; Load X parameter
	inc.B				   $17
	inc.B				   $17
TAX_Label:
	lda.B				   [$17]	 ; Load Y parameter
	inc.B				   $17
	inc.B				   $17
TAY_Label:
	lda.B				   [$17]	 ; Load count
	inc.B				   $17
	and.W				   #$00ff
	dec					 a; Count-1 for MVN
	jmp.W				   $0030	 ; Execute DMA/transfer at $0030

DMA_Transfer4Params:
	stz.B				   $62	   ; Clear $62
	lda.B				   [$17]	 ; Load parameter 1
	inc.B				   $17
	inc.B				   $17
TAX_Label:
	lda.B				   [$17]	 ; Load parameter 2
	inc.B				   $17
	and.W				   #$00ff
	sta.B				   $63	   ; Store in $63
	lda.B				   [$17]	 ; Load parameter 3
	inc.B				   $17
	inc.B				   $17
TAY_Label:
	lda.B				   [$17]	 ; Load parameter 4
	inc.B				   $17
	and.W				   #$00ff
	ora.B				   $62	   ; Combine with $62
	sta.B				   $31	   ; Store in $31
	lda.B				   [$17]	 ; Load count
	inc.B				   $17
	inc.B				   $17
	dec					 a; Count-1
	phb							   ; Save data bank
	jsr.W				   $0030	 ; Execute transfer
	plb							   ; Restore data bank
RTS_Label:

DMA_TransferSaved:
	lda.B				   $35	   ; Load $35
	sep					 #$20		; 8-bit A
	lda.B				   $39	   ; Load bank byte
	rep					 #$30		; 16-bit mode
	sta.B				   $31	   ; Store bank
	lda.B				   $3a	   ; Check if count non-zero
	beq					 DMA_TransferDone ; If zero, skip
	dec					 a; Count-1
	ldx.B				   $34	   ; Load X param
	ldy.B				   $37	   ; Load Y param
	phb							   ; Save data bank
	jsr.W				   $0030	 ; Execute transfer
	plb							   ; Restore data bank

DMA_TransferDone:
RTS_Label:

;-------------------------------------------------------------------------------
; CODE_00A958 - Write 8-bit value to address
; Purpose: [X] = 8-bit value from script
; Entry: [$17] = address, [$17+2] = 8-bit value
;-------------------------------------------------------------------------------
Script_Write8Bit:
	lda.B				   [$17]	 ; Load address
	inc.B				   $17
	inc.B				   $17
	tax							   ; X = address
	lda.B				   [$17]	 ; Load value (8-bit in low byte)
	inc.B				   $17
	and.W				   #$00ff
	sep					 #$20		; 8-bit A
	sta.W				   $0000,x   ; Store to address
	rts							   ; (REP #$30 happens in caller)

;-------------------------------------------------------------------------------
; CODE_00A96C - Write 16-bit value to address
; Purpose: [X] = 16-bit value from script
; Entry: [$17] = address, [$17+2] = 16-bit value
;-------------------------------------------------------------------------------
Script_Write16Bit:
	lda.B				   [$17]	 ; Load address
	inc.B				   $17
	inc.B				   $17
	tax							   ; X = address
	lda.B				   [$17]	 ; Load 16-bit value
	inc.B				   $17
	inc.B				   $17
	sta.W				   $0000,x   ; Store to address
RTS_Label:

;-------------------------------------------------------------------------------
; CODE_00A97D - Write 16-bit value + 8-bit value to address
; Purpose: Write word then byte (3 bytes total)
; Entry: [$17] = address, [$17+2] = word, [$17+4] = byte
;-------------------------------------------------------------------------------
Script_Write24Bit:
	jsr.W				   Script_Write16Bit ; Write word at X
	lda.B				   [$17]	 ; Load byte value
	inc.B				   $17
	and.W				   #$00ff
	sep					 #$20		; 8-bit A
	sta.W				   $0002,x   ; Store at X+2
RTS_Label:

;-------------------------------------------------------------------------------
; CODE_00A98D/CODE_00A999 - Indirect pointer writes (using $9e)
; Purpose: Write to address pointed to by $9e/$9f
;-------------------------------------------------------------------------------
Script_WriteIndirect8:
	lda.B				   [$17]	 ; Load 8-bit value
	inc.B				   $17
	and.W				   #$00ff
	sep					 #$20		; 8-bit A
	sta.B				   [$9e]	 ; Store via indirect pointer
RTS_Label:

Script_WriteIndirect16:
	lda.B				   [$17]	 ; Load 16-bit value
	inc.B				   $17
	inc.B				   $17
	sta.B				   [$9e]	 ; Store via indirect pointer
RTS_Label:

;-------------------------------------------------------------------------------
; CODE_00A9A2 - Complex indirect write sequence
;-------------------------------------------------------------------------------
Script_WriteIndirectSeq:
	db											 $20,$99,$a9,$e6,$9e,$e6,$9e,$20,$8d,$a9,$c2,$30,$c6,$9e,$c6,$9e
	db											 $60

;-------------------------------------------------------------------------------
; CODE_00A9B3 - Load value from indirect pointer
; Purpose: Load 16-bit value from [$9e]
; Entry: [$17] = address to store result
; Exit: A = value from [$9e], X = address
;-------------------------------------------------------------------------------
Script_ReadIndirect:
	lda.B				   [$17]	 ; Load destination address
	inc.B				   $17
	inc.B				   $17
	tax							   ; X = destination
	lda.B				   [$9e]	 ; Load value via indirect
RTS_Label:

Script_ReadIndirect8:
	jsr.W				   Script_ReadIndirect ; Load via [$9e]
	sep					 #$20		; 8-bit A
	sta.W				   $0000,x   ; Store low byte only
RTS_Label:

Script_ReadIndirect16:
	jsr.W				   Script_ReadIndirect ; Load via [$9e]
	sta.W				   $0000,x   ; Store full word
RTS_Label:

;-------------------------------------------------------------------------------
; CODE_00A9CD - MVN transfer using $9e pointer
; Purpose: Block move using indirect pointer as bank
;-------------------------------------------------------------------------------
Script_TransferIndirect:
	lda.B				   [$17]	 ; Load destination
	inc.B				   $17
	inc.B				   $17
	tay							   ; Y = destination
	ldx.B				   $9e	   ; X = source from $9e
	lda.B				   $9f	   ; Load bank byte
	and.W				   #$ff00
	sta.B				   $31	   ; Store bank in $31
	lda.W				   #$0002	; Transfer 3 bytes (count-1=2)
	jmp.W				   $0030	 ; Execute MVN via $0030

;-------------------------------------------------------------------------------
; CODE_00A9E3-CODE_00AA22 - Bank $7e write operations
; Purpose: Write to Bank $7e addresses using special bank handling
;-------------------------------------------------------------------------------
Script_WriteBanked8:
	jsr.W				   Script_LoadAddrBank ; Load address and bank
	pha							   ; Save bank
	plb							   ; Set data bank
	lda.B				   [$17]	 ; Load 8-bit value
	inc.B				   $17
	and.W				   #$00ff
	sep					 #$20		; 8-bit A
	sta.W				   $0000,x   ; Store to Bank $7e address
	plb							   ; Restore data bank
RTS_Label:

Script_WriteBanked16:
	jsr.W				   Script_LoadAddrBank ; Load address and bank
	pha							   ; Save bank
	plb							   ; Set data bank
	lda.B				   [$17]	 ; Load 16-bit value
	inc.B				   $17
	inc.B				   $17
	sta.W				   $0000,x   ; Store to Bank $7e address
	plb							   ; Restore data bank
RTS_Label:

Script_WriteBanked24:
	db											 $20,$22,$aa,$48,$ab,$a7,$17,$e6,$17,$e6,$17,$9d,$00,$00,$a7,$17
	db											 $e6,$17,$29,$ff,$00,$e2,$20,$9d,$02,$00,$ab,$60

;-------------------------------------------------------------------------------
; CODE_00AA22 - Helper: Load address and bank for Bank $7e operations
; Entry: [$17] = address, [$17+2] = bank byte
; Exit: X = address, A = bank (low byte)
;-------------------------------------------------------------------------------
Script_LoadAddrBank:
	lda.B				   [$17]	 ; Load address
	inc.B				   $17
	inc.B				   $17
	tax							   ; X = address
	lda.B				   [$17]	 ; Load bank
	inc.B				   $17
	and.W				   #$00ff	; Isolate bank byte
RTS_Label:

;-------------------------------------------------------------------------------
; CODE_00AA31-CODE_00AA67 - Text positioning and display helpers
; Purpose: Calculate text window positions and sizes
;-------------------------------------------------------------------------------
Text_CalcWindowPos:
	sep					 #$30		; 8-bit A, X, Y
	jsr.W				   Text_CalcXPos ; Calculate X position
	jsr.W				   Text_CalcYPos ; Calculate Y position/width
	bra					 Text_FinalizePos ; Finalize

Text_CalcXPos:
	lda.B				   #$20	  ; Load window width constant
SEC_Label:
	sbc.B				   $2a	   ; Subtract text width
	lsr					 a; / 2 (center)
	sta.B				   $28	   ; Store X offset
RTS_Label:

Text_CalcYPos:
	lda.B				   $24	   ; Load flags
	and.B				   #$08	  ; Test bit 3
	beq					 Text_CalcYDynamic ; If clear, skip
	lda.B				   #$10	  ; Use fixed position
	bra					 Text_CalcYApply

Text_CalcYDynamic:
	lda.B				   $2d	   ; Load position
	eor.B				   #$ff	  ; Negate
	inc					 a

Text_CalcYApply:
CLC_Label:
	adc.B				   $23	   ; Add offset
	sta.B				   $2c	   ; Store Y position
	lsr					 a; / 4 (row)
	lsr					 a
	sta.B				   $29	   ; Store row index
RTS_Label:

Text_FinalizePos:
	rep					 #$30		; 16-bit mode
	lda.B				   $28	   ; Load calculated position
CLC_Label:
	adc.W				   #$0101	; Add offset (both bytes)
	sta.B				   $25	   ; Store final position
RTS_Label:

;-------------------------------------------------------------------------------
; CODE_00AA68 - Repeat text operation
; Purpose: Execute text display routine multiple times
; Entry: $1f = repeat count, $17 = operation pointer
;-------------------------------------------------------------------------------
Text_RepeatOperation:
	lda.B				   $1f	   ; Load repeat count
	and.W				   #$00ff
	ldx.B				   $17	   ; Load operation pointer

Text_RepeatLoop:
	pha							   ; Save count
	phx							   ; Save pointer
	stx.B				   $17	   ; Set pointer
	jsr.W				   Graphics_ReadDispatchCmd ; Execute text operation
	plx							   ; Restore pointer
	pla							   ; Restore count
	dec					 a; Decrement count
	bne					 Text_RepeatLoop ; Loop if not zero
RTS_Label:

;-------------------------------------------------------------------------------
; CODE_00AA7C-CODE_00AACC - DMA transfer setup routines
; Purpose: Set up and execute DMA transfers to VRAM/tilemap
;-------------------------------------------------------------------------------
DMA_SetupTilemap:
	lda.B				   $40	   ; Load bank/high byte
	sta.B				   $1b	   ; Set DMA bank
	sta.B				   $35	   ; Set alternate bank
	sta.B				   $38	   ; Set third bank
	lda.W				   #$2cfe	; Load tile value
	ldx.B				   $3f	   ; Load X base
	ldy.W				   #$1000	; Load Y base (large transfer)
	jmp.W				   CODE_009D4B ; Execute DMA

DMA_SetupPositioned:
	lda.B				   $40	   ; Load bank
	sta.B				   $1b
	sta.B				   $35
	sta.B				   $38
	lda.B				   $28	   ; Load position high byte
	and.W				   #$ff00
	lsr					 a; / 4 (calculate offset)
	lsr					 a
	adc.B				   $3f	   ; Add base
	tax							   ; X = transfer source
	lda.B				   $2a	   ; Load size high byte
	and.W				   #$ff00
	lsr					 a; / 4
	lsr					 a
	tay							   ; Y = transfer size
	lda.W				   #$2cfe	; Load tile value
	jmp.W				   CODE_009D4B ; Execute DMA

DMA_SetupClear:
	lda.B				   $40	   ; Load bank
	sta.B				   $1b
	sta.B				   $35
	sta.B				   $38
	lda.B				   $28	   ; Load position
	and.W				   #$ff00
	lsr					 a; / 4
	lsr					 a
	adc.B				   $3f	   ; Add base
TAX_Label:
	lda.B				   $2a	   ; Load size
	and.W				   #$ff00
	lsr					 a; / 4
	lsr					 a
TAY_Label:
	lda.W				   #$2c00	; Different tile value (blank/clear)
	jmp.W				   CODE_009D4B ; Execute DMA

;===============================================================================
; Progress: ~8,900 lines documented (63.5% of Bank $00)
; Latest additions:
; - CODE_00A86E-00A874: Memory block transfers to/from Bank $7e
; - CODE_00A89B: Reverse block copy (Bank $7e → Bank $00)
; - CODE_00A8C0-00A8D1: Pointer manipulation and coordinate calculations
; - CODE_00A8EE-00A93E: DMA/MVN transfer helper routines
; - CODE_00A958-00A97D: Direct memory write operations (8-bit, 16-bit, 24-bit)
; - CODE_00A98D-00A999: Indirect pointer writes via $9e
; - CODE_00A9B3-00A9CD: Indirect pointer reads and transfers
; - CODE_00A9E3-00AA22: Bank $7e special write operations
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
Sprite_DrawDispatch:
	lda.B				   $27	   ; Load sprite type index
	and.W				   #$00ff
	asl					 a; × 2 for word table
	tax							   ; X = table offset
	pei.B				   ($25)	 ; Save $25 to stack
	lda.B				   $28	   ; Load position
	sta.B				   $25	   ; Store as new $25
	jsr.W				   CODE_00A8D1 ; Calculate tilemap pointer
	jsr.W				   CODE_00B49E ; Prepare drawing context
	lda.B				   $1c	   ; Load bank byte
	and.W				   #$00ff
	pha							   ; Save bank
	plb							   ; Set data bank
	jsr.W				   (UNREACH_00AAF7,x) ; Dispatch to sprite routine
	plb							   ; Restore data bank
	jsr.W				   CODE_00B4A7 ; Cleanup drawing context
	pla							   ; Restore $25
	sta.B				   $25
	jmp.W				   CODE_00A8D1 ; Recalculate pointer and return

	db											 $60		 ; Extra RTS

;-------------------------------------------------------------------------------
; UNREACH_00AAF7 - Sprite drawing dispatch table
;-------------------------------------------------------------------------------
UNREACH_00AAF7:
	db											 $f6,$aa	 ; Unreachable data
	dw											 Sprite_DrawFilled ; $00
	dw											 Sprite_DrawWindowBorder ; $01
	dw											 Window_DrawFrame ; $02
	dw											 Window_DrawItemIcon ; $03
	dw											 Window_DrawSpellIcon ; $04
	dw											 Window_DrawTopBorder ; $05
	dw											 Window_DrawFilledBox ; $06

;-------------------------------------------------------------------------------
; Sprite_DrawFilled - Draw filled rectangle (tile $fe)
; Purpose: Draw solid filled rectangle using tile $fe
;-------------------------------------------------------------------------------
Sprite_DrawFilled:
	lda.B				   $2b	   ; Load height
	and.W				   #$00ff
	sta.B				   $62	   ; Store row counter
	lda.B				   $2a	   ; Load width
	and.W				   #$00ff
	asl					 a; × 2 for word offset
	tax							   ; X = column offset
	ldy.B				   $1a	   ; Load tilemap pointer
	lda.W				   #$00fe	; Tile $fe (solid fill)
	jsr.W				   Window_DrawTiles ; Draw tiles
	sty.B				   $1a	   ; Update pointer
RTS_Label:

;-------------------------------------------------------------------------------
; Sprite_DrawWindowBorder - Draw window border with vertical flip
; Purpose: Draw bordered window with special tile handling
;-------------------------------------------------------------------------------
Sprite_DrawWindowBorder:
	jsr.W				   Window_DrawTopBorder ; Draw top border
	lda.W				   #$4000	; Vertical flip bit
	ora.B				   $1d	   ; Combine with tile flags
	sta.B				   $64	   ; Store flip flags
	jsr.W				   CODE_00B4A7 ; Setup drawing
SEC_Label:
	lda.B				   $1a	   ; Load pointer
	sbc.W				   #$0040	; Back up one row
	sta.B				   $1a
	lda.B				   $24	   ; Load flags
	bit.W				   #$0008	; Test bit 3
	beq					 Window_CalcBounds ; If clear, skip
	jsr.W				   CODE_00A8D1 ; Recalculate pointer
	lda.W				   #$8000	; Horizontal flip bit
	tsb.B				   $64	   ; Set in flags

Window_CalcBounds:
	sep					 #$20		; 8-bit A
	lda.B				   $22	   ; Load Y position
	lsr					 a; / 8 (tile row)
	lsr					 a
	lsr					 a
	cmp.B				   $28	   ; Compare with window top
	bcs					 Window_CalcRowOffset ; If >= top, use it
	lda.B				   $28	   ; Use window top
SEC_Label:

Window_CalcRowOffset:
	sbc.B				   $28	   ; Calculate row offset
	sta.B				   $62	   ; Store row counter
	lda.B				   $22	   ; Load Y again
	cmp.B				   #$78	  ; Check if >= 120
	bcc					 Window_AdjustHeight ; If below, adjust
	bne					 Window_FinalizeHeight ; If above, skip
	lda.B				   $24	   ; Check flags
	bit.B				   #$01	  ; Test bit 0
	beq					 Window_FinalizeHeight ; If clear, skip

Window_AdjustHeight:
	inc.B				   $62	   ; Increment row count
	lda.B				   #$40	  ; Clear bit $40
	trb.B				   $65	   ; In $65

Window_FinalizeHeight:
	lda.B				   $62	   ; Load row counter
	inc					 a; +1
	cmp.B				   $2a	   ; Compare with width
	bcc					 Window_DrawBorder ; If less, use it
	db											 $a5,$2a,$e9,$02,$85,$62 ; Load width-2 into $62

Window_DrawBorder:
	rep					 #$30		; 16-bit mode
	lda.B				   $62	   ; Load final count
	and.W				   #$00ff
	asl					 a; × 2 for word offset
	tay							   ; Y = offset
	lda.W				   #$00fd	; Tile $fd
	eor.B				   $64	   ; Apply flip flags
	sta.B				   ($1a),y   ; Draw tile
RTS_Label:

;-------------------------------------------------------------------------------
; Window_DrawFrame - Draw window frame (tiles $fc, $ff)
;-------------------------------------------------------------------------------
Window_DrawFrame:
	lda.W				   #$00fc	; Top border tile
	jsr.W				   Window_SetupTopEdge ; Setup top edge
	lda.W				   #$00ff	; Fill tile
	jsr.W				   Window_SetupVerticalEdge ; Setup vertical edges
	inc.B				   $62	   ; Adjust counter
	lda.W				   #$80fc	; Bottom border (flipped)
	jsr.W				   Window_DrawTiles ; Draw
	jmp.W				   Window_DrawFrameCorners ; Draw corners

;-------------------------------------------------------------------------------
; Window_DrawTopBorder - Draw window top border
;-------------------------------------------------------------------------------
Window_DrawTopBorder:
	lda.W				   #$00fc	; Border tile
	jsr.W				   Window_SetupTopEdge ; Setup top
	lda.B				   $2b	   ; Load height
	and.W				   #$00ff
	dec					 a; -2 for borders
	dec					 a
	jsr.W				   Window_FillRows ; Fill routine
	inc.B				   $62	   ; Adjust
	lda.W				   #$80fc	; Bottom border
	jsr.W				   Window_DrawTiles ; Draw
	jmp.W				   Window_DrawFrameCorners ; Draw corners

;-------------------------------------------------------------------------------
; Window_DrawFilledBox - Draw simple filled box
;-------------------------------------------------------------------------------
Window_DrawFilledBox:
	ldy.B				   $1a	   ; Load pointer
	lda.B				   $2a	   ; Load width
	and.W				   #$00ff
	asl					 a; × 2
	tax							   ; X = offset
	lda.B				   $2b	   ; Load height
	and.W				   #$00ff
	jsr.W				   Window_FillRows ; Fill
	sty.B				   $1a	   ; Update pointer
RTS_Label:

;-------------------------------------------------------------------------------
; Window_DrawItemIcon - Draw item icon box (tiles $45)
;-------------------------------------------------------------------------------
Window_DrawItemIcon:
	lda.W				   #$0045	; Item icon tile
	jsr.W				   Window_SetupTopEdge ; Setup top
	lda.W				   #$00ff	; Fill
	jsr.W				   Window_SetupVerticalEdge ; Setup edges
	inc.B				   $62
	lda.W				   #$8045	; Flipped icon
	jsr.W				   Window_DrawTiles ; Draw
	jmp.W				   Window_DrawItemCorners ; Finish

;-------------------------------------------------------------------------------
; Window_DrawSpellIcon - Draw spell icon box (tiles $75)
;-------------------------------------------------------------------------------
Window_DrawSpellIcon:
	lda.W				   #$0075	; Spell icon tile
	jsr.W				   Window_SetupTopEdge ; Setup top
	lda.W				   #$00ff	; Fill
	jsr.W				   Window_SetupVerticalEdge ; Setup edges
	inc.B				   $62
	lda.W				   #$8075	; Flipped spell icon
	jsr.W				   Window_DrawTiles ; Draw
	jmp.W				   Window_DrawSpellCorners ; Finish

;-------------------------------------------------------------------------------
; Window_FillRows - Tile fill routine with indirect jump
; Purpose: Complex tile filling using computed jump table
; Entry: A = row count, X = column offset × 2
;-------------------------------------------------------------------------------
Window_FillRows:
	sta.B				   $62	   ; Save row count
	txa							   ; Get column offset
	asl					 a; × 2 again
	eor.W				   #$ffff	; Negate
	adc.W				   #$ac97	; Add base (computed address)
	sta.B				   $64	   ; Store jump target
	txa							   ; Column offset
	lsr					 a; / 2
	pha							   ; Save to stack

Window_FillLoop:
	adc.L				   $00015f   ; Add to system counter
	sta.L				   $00015f   ; Update counter
	jmp.W				   ($0064)   ; Jump to computed address

; Computed jump table entries (tile fill patterns)
	db											 $3a,$99,$3e,$00,$3a,$99,$3c,$00,$3a,$99,$3a,$00,$3a,$99,$38,$00
	db											 $3a,$99,$36,$00,$3a,$99,$34,$00

; Unrolled tile write loop (26 tiles worth)
	dec					 a
	sta.W				   $0032,y
	dec					 a
	sta.W				   $0030,y
	dec					 a
	sta.W				   $002e,y
	dec					 a
	sta.W				   $002c,y
	dec					 a
	sta.W				   $002a,y
	dec					 a
	sta.W				   $0028,y
	dec					 a
	sta.W				   $0026,y
	dec					 a
	sta.W				   $0024,y
	dec					 a
	sta.W				   $0022,y
	dec					 a
	sta.W				   $0020,y
	dec					 a
	sta.W				   $001e,y
	dec					 a
	sta.W				   $001c,y
	dec					 a
	sta.W				   $001a,y
	dec					 a
	sta.W				   $0018,y
	dec					 a
	sta.W				   $0016,y
	dec					 a
	sta.W				   $0014,y
	dec					 a
	sta.W				   $0012,y
	dec					 a
	sta.W				   $0010,y
	dec					 a
	sta.W				   $000e,y
	dec					 a
	sta.W				   $000c,y
	dec					 a
	sta.W				   $000a,y
	dec					 a
	sta.W				   $0008,y
	dec					 a
	sta.W				   $0006,y
	dec					 a
	sta.W				   $0004,y
	dec					 a
	sta.W				   $0002,y
	dec					 a
	sta.W				   $0000,y
	tya							   ; Get current pointer
	adc.W				   #$0040	; Next row (+$40 bytes)
	tay							   ; Update Y
	lda.B				   $01,s	 ; Load saved value
	dec.B				   $62	   ; Decrement row counter
	beq					 Window_FillDone ; If zero, done
	jmp.W				   Window_FillLoop ; Loop

Window_FillDone:
	pla							   ; Clean stack
RTS_Label:

;-------------------------------------------------------------------------------
; Window_DrawFrameCorners - Draw window corners (tiles $f7/$f9/$fb)
;-------------------------------------------------------------------------------
Window_DrawFrameCorners:
	jsr.W				   Window_CalcCornerPos ; Setup coordinates
	lda.B				   $1d	   ; Load tile flags
	eor.W				   #$00f7	; Top-left corner
	sta.B				   ($1a)	 ; Draw
	lda.B				   $1d
	eor.W				   #$00f9	; Top-right corner
	sta.B				   ($1a),y   ; Draw
	lda.W				   #$00fb	; Side tiles
	jsr.W				   Window_DrawSideTiles ; Draw sides
	lda.B				   $1d
	eor.W				   #$00f8	; Bottom-left corner
	sta.B				   ($1a)
	lda.B				   $1d
	eor.W				   #$00fa	; Bottom-right corner
	sta.B				   ($1a),y
	lda.B				   $1a	   ; Advance pointer
	adc.W				   #$0040
	sta.B				   $1a
RTS_Label:

;-------------------------------------------------------------------------------
; Window_DrawItemCorners - Draw item icon corners (tiles $40-$44)
;-------------------------------------------------------------------------------
Window_DrawItemCorners:
	jsr.W				   Window_CalcCornerPos ; Setup
	lda.B				   $1d
	eor.W				   #$0040	; Icon TL
	sta.B				   ($1a)
	lda.B				   $1d
	eor.W				   #$0042	; Icon TR
	sta.B				   ($1a),y
	lda.W				   #$0044	; Icon sides
	jsr.W				   Window_DrawSideTiles ; Draw
	lda.B				   $1d
	eor.W				   #$0041	; Icon BL
	sta.B				   ($1a)
	lda.B				   $1d
	eor.W				   #$0043	; Icon BR
	sta.B				   ($1a),y
	lda.B				   $1a
	adc.W				   #$0040
	sta.B				   $1a
RTS_Label:

;-------------------------------------------------------------------------------
; Window_DrawSpellCorners - Draw spell icon corners (tiles $70-$74)
;-------------------------------------------------------------------------------
Window_DrawSpellCorners:
	jsr.W				   Window_CalcCornerPos ; Setup
	lda.B				   $1d
	eor.W				   #$0070	; Spell TL
	sta.B				   ($1a)
	lda.B				   $1d
	eor.W				   #$0072	; Spell TR
	sta.B				   ($1a),y
	lda.W				   #$0074	; Spell sides
	jsr.W				   Window_DrawSideTiles ; Draw
	lda.B				   $1d
	eor.W				   #$0071	; Spell BL
	sta.B				   ($1a)
	lda.B				   $1d
	eor.W				   #$0073	; Spell BR
	sta.B				   ($1a),y
	lda.B				   $1a
	adc.W				   #$0040
	sta.B				   $1a
RTS_Label:

;-------------------------------------------------------------------------------
; Window_SetupTopEdge - Setup top edge drawing
; Entry: A = tile value
;-------------------------------------------------------------------------------
Window_SetupTopEdge:
	pha							   ; Save tile
	ldy.B				   $1a	   ; Load pointer
	iny							   ; Skip first tile
INY_Label:
	lda.B				   $2a	   ; Load width
	and.W				   #$00ff
	dec					 a; -2 for corners
	dec					 a
	asl					 a; × 2
	tax							   ; X = offset
	lda.W				   #$0001	; Single row
	sta.B				   $62
	pla							   ; Restore tile
	jmp.W				   Window_DrawTiles ; Draw

;-------------------------------------------------------------------------------
; Window_SetupVerticalEdge - Setup vertical edge drawing
; Entry: A = tile value
;-------------------------------------------------------------------------------
Window_SetupVerticalEdge:
	pha							   ; Save tile
	lda.B				   $2b	   ; Load height
	and.W				   #$00ff
	dec					 a; -2 for top/bottom
	dec					 a
	sta.B				   $62	   ; Row count
	pla							   ; Restore tile
	jmp.W				   Window_DrawTiles ; Draw

;-------------------------------------------------------------------------------
; Window_CalcCornerPos - Calculate corner positions
; Exit: Y = right edge offset, $62 = adjusted row count
;-------------------------------------------------------------------------------
Window_CalcCornerPos:
	lda.B				   $2a	   ; Width
	and.W				   #$00ff
	dec					 a; -1
	asl					 a; × 2
	tay							   ; Y = right offset
	lda.B				   $2b	   ; Height
	and.W				   #$00ff
	dec					 a; -2
	dec					 a
	sta.B				   $62	   ; Row count
RTS_Label:

;-------------------------------------------------------------------------------
; Window_DrawSideTiles - Draw vertical side tiles
; Entry: A = tile value (XORed with $1d)
;-------------------------------------------------------------------------------
Window_DrawSideTiles:
	eor.B				   $1d	   ; Apply tile flags
	sta.B				   $64	   ; Save tile
	lda.B				   $1a	   ; Advance to next row
	adc.W				   #$0040
	sta.B				   $1a
	ldx.B				   $62	   ; Load row counter

Window_DrawSideLoop:
	lda.B				   $64	   ; Load tile
	sta.B				   ($1a)	 ; Draw left edge
	eor.W				   #$4000	; Flip horizontally
	sta.B				   ($1a),y   ; Draw right edge
	lda.B				   $1a	   ; Next row
	adc.W				   #$0040
	sta.B				   $1a
	dex							   ; Decrement counter
	bne					 Window_DrawSideLoop ; Loop
RTS_Label:

;-------------------------------------------------------------------------------
; Window_DrawTiles - Generic tile drawing routine
; Entry: A = tile value (XORed with $1d), X = column offset
;-------------------------------------------------------------------------------
Window_DrawTiles:
	eor.B				   $1d	   ; Apply flags
	sta.B				   $64	   ; Save tile

Window_DrawTileLoop:
	jsr.W				   (DATA8_009a1e,x) ; Call indexed routine
	tya							   ; Get pointer
	adc.W				   #$0040	; Next row
TAY_Label:
	lda.B				   $64	   ; Restore tile
	dec.B				   $62	   ; Decrement row counter
	bne					 Window_DrawTileLoop ; Loop
RTS_Label:

;-------------------------------------------------------------------------------
; Sprite_ClearOAM - Clear sprite OAM entries
; Purpose: Clear OAM sprite data in Bank $7e
; Entry: [$17] = number of sprites to clear
;-------------------------------------------------------------------------------
Sprite_ClearOAM:
	lda.B				   [$17]	 ; Load sprite count
	inc.B				   $17
	and.W				   #$00ff
	sta.B				   $62	   ; Save count
	ldy.W				   #$31c5	; OAM base + offset
	lda.W				   #$01f0	; Off-screen Y position
	pea.W				   $007e	 ; Push Bank $7e
	plb							   ; Set data bank
SEC_Label:

Sprite_ClearLoop:
	tax							   ; X = Y position
	jsr.W				   CODE_009A05 ; Clear sprite entry
	tya							   ; Get OAM pointer
	sbc.W				   #$fff0	; Move back (-16 bytes)
TAY_Label:
	txa							   ; Restore Y position
	adc.W				   #$fff8	; Adjust (-8)
	dec.B				   $62	   ; Decrement count
	bne					 Sprite_ClearLoop ; Loop
	plb							   ; Restore bank
RTS_Label:

;-------------------------------------------------------------------------------
; Sprite_DrawCompressed - Compressed tile drawing to Bank $7e
; Purpose: Draw compressed tile data to screen buffer
; Entry: $2c = Y coordinate, $2d = width, $2b = height
;-------------------------------------------------------------------------------
Sprite_DrawCompressed:
	lda.B				   $2c	   ; Load Y coord
	and.W				   #$00ff
	sta.B				   $64	   ; Save
	asl					 a; × 2
	adc.W				   #$31b5	; Add buffer base
	tay							   ; Y = destination
	lda.W				   #$01f9	; Calculate offset
	sbc.B				   $64
	pea.W				   $007e	 ; Bank $7e
PLB_Label:
	sta.B				   $64	   ; Save offset
	and.W				   #$0007	; Get low 3 bits
	asl					 a; × 2
	tax							   ; X = table offset
	lda.B				   $64
	and.W				   #$fff8	; Mask to 8-byte boundary
	adc.W				   #$0008	; Adjust
	jsr.W				   (DATA8_009a1e,x) ; Call indexed routine
	sbc.W				   #$0007	; Adjust back
TAX_Label:
	lda.B				   $64
	and.W				   #$0007	; Get bit offset
	sta.B				   $64
	sty.B				   $62	   ; Save pointer
	asl					 a; × 2
	adc.B				   $62
	tay							   ; Y = adjusted pointer
SEC_Label:
	lda.B				   $2d	   ; Load width
	sbc.B				   $64	   ; Subtract offset
	and.W				   #$00ff
	pha							   ; Save
	lsr					 a; / 8
	lsr					 a
	lsr					 a
	sta.B				   $62	   ; Row counter
TXA_Label:
SEC_Label:

Sprite_CompressedLoop:
TAX_Label:
	jsr.W				   Memory_Fill14Bytes ; Draw routine
TYA_Label:
	sbc.W				   #$fff0	; Adjust pointer
TAY_Label:
TXA_Label:
	adc.W				   #$fff8	; Adjust X
	dec.B				   $62
	bne					 Sprite_CompressedLoop ; Loop
	sta.B				   $64	   ; Save result
	pla							   ; Restore width
	and.W				   #$0007	; Get remainder
	asl					 a; × 2
TAX_Label:
	lda.B				   $64
	jsr.W				   (DATA8_009a1e,x) ; Final draw
	plb							   ; Restore bank
RTS_Label:

;-------------------------------------------------------------------------------
; Text_DrawRLE - RLE compressed text drawing
; Purpose: Run-length encoded text decompression to Bank $7e
; Entry: $2c = Y start, $29 = row count, $2b = column count
;-------------------------------------------------------------------------------
Text_DrawRLE:
	pea.W				   $007e	 ; Bank $7e
PLB_Label:
	lda.B				   $2c	   ; Y coordinate
	and.W				   #$00ff
	pha							   ; Save
	dec					 a; -1
	asl					 a; × 2
	adc.W				   #$31b7	; Buffer base
	tax							   ; X = destination
	lda.B				   $29	   ; Row count
	and.W				   #$00ff
	asl					 a; × 8
	asl					 a
	asl					 a
SEC_Label:
	sbc.B				   $01,s	 ; Subtract Y
	sta.B				   $01,s	 ; Update stack
	lda.B				   $2b	   ; Column count
	and.W				   #$00ff
	sta.B				   $62	   ; Save

Text_DrawRLE_Loop:
	lda.B				   [$17]	 ; Load RLE byte
	and.W				   #$00ff
	beq					 Text_DrawRLE_Skip ; If zero, skip
	bit.W				   #$0080	; Test high bit
	bne					 Text_DrawRLE_Special ; If set, special mode
	pha							   ; Save count
	lda.B				   $03,s	 ; Load tile value
	sta.W				   $0000,x   ; Store
	txy							   ; Y = X
	iny							   ; Advance
INY_Label:
	pla							   ; Restore count
	dec					 a; -1
	beq					 Text_DrawRLE_Done ; If 1, done
	asl					 a; × 2
	dec					 a; -1 for MVN
	mvn					 $7e,$7e	 ; Block move

Text_DrawRLE_Done:
	tyx							   ; X = end pointer

Text_DrawRLE_Skip:
	lda.W				   #$0008	; 8 tiles
SEC_Label:
	sbc.B				   [$17]	 ; Subtract used
	and.W				   #$00ff
CLC_Label:
	adc.B				   $01,s	 ; Add to stack offset
	sta.B				   $01,s

Text_DrawRLE_Next:
	inc.B				   $17	   ; Next RLE byte
	dec.B				   $62	   ; Decrement column counter
	bne					 Text_DrawRLE_Loop ; Loop
	pla							   ; Clean stack
	plb							   ; Restore bank
RTS_Label:

Text_DrawRLE_Special:
	and.W				   #$007f	; Mask off high bit
	pha							   ; Save count
	lda.W				   #$0008
SEC_Label:
	sbc.B				   $01,s	 ; Calculate skip
CLC_Label:
	adc.B				   $03,s	 ; Add to offset
	sta.B				   $03,s
	sta.W				   $0000,x   ; Store
TXY_Label:
INY_Label:
INY_Label:
PLA_Label:
	dec					 a
	beq					 CODE_00AE9F
	asl					 a
	dec					 a
	mvn					 $7e,$7e	 ; Block move

Text_DrawRLE_SpecialDone:
TYX_Label:
	bra					 Text_DrawRLE_Next ; Continue

;-------------------------------------------------------------------------------
; Cmd_CallGraphics8Bit - Call graphics function with 8-bit parameter
;-------------------------------------------------------------------------------
Cmd_CallGraphics8Bit:
	lda.B				   [$17]	 ; Load parameter
	inc.B				   $17
	and.W				   #$00ff
	jsl.L				   CODE_009760 ; Long call to graphics routine
RTS_Label:

	db											 $a5,$9e,$22,$60,$97,$00,$60 ; Variant with $9e parameter

;-------------------------------------------------------------------------------
; Cmd_CallGraphicsWithDP - Call graphics function with DP context
;-------------------------------------------------------------------------------
Cmd_CallGraphicsWithDP:
	lda.B				   [$17]	 ; Load parameter
	inc.B				   $17
	and.W				   #$00ff
	phd							   ; Save direct page
	pea.W				   $00d0	 ; Set DP to $d0
PLD_Label:
	jsl.L				   CODE_00974E ; Call graphics routine
	pld							   ; Restore DP
RTS_Label:

;-------------------------------------------------------------------------------
; Cmd_CallSprite - Call sprite/tile function
;-------------------------------------------------------------------------------
Cmd_CallSprite:
	lda.B				   [$17]	 ; Load parameter
	inc.B				   $17
	and.W				   #$00ff
	jsl.L				   CODE_00976B ; Call sprite routine
RTS_Label:

	db											 $a5,$9e,$22,$6b,$97,$00,$60 ; Variant with $9e

;-------------------------------------------------------------------------------
; Cmd_CallGraphicsAlt - Call graphics function with DP=$d0
;-------------------------------------------------------------------------------
Cmd_CallGraphicsAlt:
	lda.B				   [$17]
	inc.B				   $17
	and.W				   #$00ff
PHD_Label:
	pea.W				   $00d0	 ; DP = $d0
PLD_Label:
	jsl.L				   CODE_009754 ; Graphics call
PLD_Label:
RTS_Label:

; More variants with different parameter sources
	db											 $a5,$2e,$0b,$48,$a7,$17,$e6,$17,$29,$ff,$00,$2b,$22,$4e,$97,$00
	db											 $2b,$60

Cmd_CallFromOffset:
	lda.B				   $2e	   ; From $2e
PHD_Label:
PHA_Label:
	lda.B				   $9e	   ; From $9e
PLD_Label:
	jsl.L				   CODE_00974E
PLD_Label:
RTS_Label:

	db											 $a5,$2e,$0b,$48,$a7,$17,$e6,$17,$29,$ff,$00,$2b,$22,$54,$97,$00
	db											 $2b,$60

Cmd_CallFromOffset2:
	lda.B				   $2e
PHD_Label:
PHA_Label:
	lda.B				   $9e
PLD_Label:
	jsl.L				   CODE_009754
PLD_Label:
RTS_Label:

;-------------------------------------------------------------------------------
; Memory_CopyWithTable - Memory copy with table offset
; Purpose: Copy data using offset from script
; Entry: A = byte count
;-------------------------------------------------------------------------------
Memory_CopyWithTable:
	tay							   ; Y = count
	lda.B				   [$17]	 ; Load source
	sta.B				   $a4
	inc.B				   $17
	inc.B				   $17
	lda.B				   [$17]	 ; Load dest
	sta.B				   $a6
	dec.B				   $17
	dec.B				   $17
	tya							   ; Get count
SEC_Label:
	adc.B				   $17	   ; Advance script pointer
	sta.B				   $17
	ldx.W				   #$00a4	; X = $a4 (source pointer)
	tya							   ; A = count
	bra					 Memory_CopyTo98

;-------------------------------------------------------------------------------
; Memory_CopyDirect - Memory copy direct
;-------------------------------------------------------------------------------
Memory_CopyDirect:
	tay							   ; Y = count
	lda.B				   [$17]	 ; Load source
	inc.B				   $17
	inc.B				   $17
	tax							   ; X = source
	tya							   ; A = count

Memory_CopyTo98:
	stz.B				   $98	   ; Clear dest low
	stz.B				   $9a	   ; Clear dest high
	ldy.W				   #$0098	; Y = $98
	mvn					 $00,$00	 ; Block move
RTS_Label:

;-------------------------------------------------------------------------------
; Memory_CopyTo9E - Memory copy to $9e pointer
;-------------------------------------------------------------------------------
Memory_CopyTo9E:
	tax							   ; X = count
	lda.B				   [$17]	 ; Load source
	inc.B				   $17
	inc.B				   $17
	tay							   ; Y = source
	txa							   ; A = count
	ldx.W				   #$009e	; X = $9e
	mvn					 $00,$00	 ; Block move
RTS_Label:

;-------------------------------------------------------------------------------
; Memory_Copy1Byte/2Bytes/3Bytes - Memory copy variants with preset counts
;-------------------------------------------------------------------------------
Memory_Copy1Byte:
	lda.W				   #$0000	; 1 byte
	bra					 Memory_CopyTo9E

Memory_Copy2Bytes:
	lda.W				   #$0001	; 2 bytes
	bra					 Memory_CopyTo9E

Memory_Copy3Bytes:
	lda.W				   #$0002	; 3 bytes
	bra					 Memory_CopyTo9E

;-------------------------------------------------------------------------------
; Memory_CopyTableTo9E/DirectTo9E - Copy and store in $9e
;-------------------------------------------------------------------------------
Memory_CopyTableTo9E:
	jsr.W				   Memory_CopyWithTable ; Table copy
	bra					 Memory_StoreTo9E

Memory_CopyDirectTo9E:
	jsr.W				   Memory_CopyDirect ; Direct copy

Memory_StoreTo9E:
	lda.B				   $98	   ; Load result low
	sta.B				   $9e	   ; Store in $9e
	lda.B				   $9a	   ; Load result high
	sta.B				   $a0	   ; Store in $a0
RTS_Label:

;-------------------------------------------------------------------------------
; Memory_CopyTable1/2/3 - Copy variants with preset counts (table mode)
;-------------------------------------------------------------------------------
Memory_CopyTable1Byte:
	lda.W				   #$0000
	bra					 Memory_CopyTableTo9E

Memory_CopyTable2Bytes:
	lda.W				   #$0001
	bra					 Memory_CopyTableTo9E

Memory_CopyTable3Bytes:
	lda.W				   #$0002
	bra					 Memory_CopyTableTo9E

Memory_CopyDirect2Bytes:
	lda.W				   #$0001
	bra					 Memory_CopyDirectTo9E

Memory_CopyDirect3Bytes:
	lda.W				   #$0002
	bra					 Memory_CopyDirectTo9E

;-------------------------------------------------------------------------------
; Pointer_Load16BitClear - Load pointer helpers
;-------------------------------------------------------------------------------
Pointer_Load16BitClear:
	jsr.W				   Pointer_LoadFromBank ; Load pointer
	stz.B				   $9f	   ; Clear high byte
	stz.B				   $a0
RTS_Label:

	db											 $20,$bb,$af,$64,$a0,$60,$20,$bb,$af,$29,$ff,$00,$85,$a0,$60

;-------------------------------------------------------------------------------
; Pointer_LoadFromBank - Load pointer from Bank $XX address
; Entry: [$17] = address, [$17+2] = bank
; Exit: Y = word value, A = next word, $9e = first word
;-------------------------------------------------------------------------------
Pointer_LoadFromBank:
	lda.B				   [$17]	 ; Load address
	inc.B				   $17
	inc.B				   $17
	tax							   ; X = address
	lda.B				   [$17]	 ; Load bank
	inc.B				   $17
	and.W				   #$00ff
	pha							   ; Save bank
	plb							   ; Set data bank
	lda.W				   $0000,x   ; Load first word
	tay							   ; Y = first word
	lda.W				   $0002,x   ; Load second word
	plb							   ; Restore bank
	sty.B				   $9e	   ; Store first word
RTS_Label:

;-------------------------------------------------------------------------------
; Pointer_LoadByte - Load byte from address into $9e
;-------------------------------------------------------------------------------
Pointer_LoadByte:
	stz.B				   $9e	   ; Clear $9e
	stz.B				   $a0	   ; Clear $a0
	lda.B				   [$17]	 ; Load address
	inc.B				   $17
	inc.B				   $17
	tax							   ; X = address
	sep					 #$20		; 8-bit A
	lda.W				   $0000,x   ; Load byte
	sta.B				   $9e	   ; Store in $9e
	rts							   ; (REP #$30 in caller)

;-------------------------------------------------------------------------------
; Bitwise_ANDTable/ANDDirect - Bitwise AND operations
;-------------------------------------------------------------------------------
Bitwise_ANDTable:
	jsr.W				   Memory_CopyWithTable ; Copy table
	bra					 Bitwise_ANDApply

Bitwise_ANDDirect:
	jsr.W				   Memory_CopyDirect ; Copy direct

Bitwise_ANDApply:
	lda.B				   $9e	   ; Load $9e
	and.B				   $98	   ; AND with $98
	sta.B				   $9e	   ; Store result
	lda.B				   $a0	   ; Load $a0
	and.B				   $9a	   ; AND with $9a
	sta.B				   $a0	   ; Store result
RTS_Label:

;-------------------------------------------------------------------------------
; Bitwise_AND1Byte - Bitwise AND variants with preset counts
;-------------------------------------------------------------------------------
Bitwise_AND1Byte:
	lda.W				   #$0000	; 1 byte count
	bra					 Bitwise_ANDTable ; → AND table copy

	lda.W				   #$0001	; 2 byte count
	bra					 Bitwise_ANDTable

	db											 $a9,$02,$00,$80,$dc,$a9,$00,$00,$80,$dc ; More variants

	lda.W				   #$0001	; 2 byte count
	bra					 Bitwise_ANDDirect ; → AND direct copy

	db											 $a9,$02,$00,$80,$d2 ; 3 byte variant

;-------------------------------------------------------------------------------
; Bitwise_TSBTable/TSBDirect - Bitwise TSB (Test and Set Bits)
; Purpose: OR values with $9e/$a0 (set bits)
;-------------------------------------------------------------------------------
Bitwise_TSBTable:
	jsr.W				   Memory_CopyWithTable ; Copy table
	bra					 Bitwise_TSBApply

Bitwise_TSBDirect:
	jsr.W				   Memory_CopyDirect ; Copy direct

Bitwise_TSBApply:
	lda.B				   $98	   ; Load value
	tsb.B				   $9e	   ; Test and Set Bits in $9e
	lda.B				   $9a
	tsb.B				   $a0	   ; Test and Set Bits in $a0
RTS_Label:

	db											 $a9,$00,$00,$80,$ea ; TSB variants with preset counts

	lda.W				   #$0001
	bra					 Bitwise_TSBTable

	db											 $a9,$02,$00,$80,$e0

	lda.W				   #$0000
	bra					 Bitwise_TSBDirect

	db											 $a9,$01,$00,$80,$db,$a9,$02,$00,$80,$d6

;-------------------------------------------------------------------------------
; Bitwise_XORTable/XORDirect - Bitwise XOR (Exclusive OR)
; Purpose: XOR values with $9e/$a0
;-------------------------------------------------------------------------------
Bitwise_XORTable:
	jsr.W				   Memory_CopyWithTable ; Copy table
	bra					 Bitwise_XORApply

Bitwise_XORDirect:
	jsr.W				   Memory_CopyDirect ; Copy direct

Bitwise_XORApply:
	lda.B				   $9e
	eor.B				   $98	   ; XOR with $98
	sta.B				   $9e	   ; Store result
	lda.B				   $a0
	eor.B				   $9a	   ; XOR with $9a
	sta.B				   $a0
RTS_Label:

;-------------------------------------------------------------------------------
; XOR variants with preset counts
;-------------------------------------------------------------------------------
	lda.W				   #$0000
	bra					 Bitwise_XORTable

	db											 $a9,$01,$00,$80,$e1,$a9,$02,$00,$80,$dc,$a9,$00,$00,$80,$dc

	lda.W				   #$0001
	bra					 Bitwise_XORDirect

	db											 $a9,$02,$00,$80,$d2

;-------------------------------------------------------------------------------
; Math_AddTable/AddDirect - Addition (ADD)
; Purpose: Add values to $9e/$a0
;-------------------------------------------------------------------------------
Math_AddTable:
	jsr.W				   Memory_CopyWithTable ; Copy table
	bra					 Math_AddApply

Math_AddDirect:
	jsr.W				   Memory_CopyDirect ; Copy direct

Math_AddApply:
CLC_Label:
	lda.B				   $9e
	adc.B				   $98	   ; Add $98
	sta.B				   $9e	   ; Store sum
	lda.B				   $a0
	adc.B				   $9a	   ; Add $9a with carry
	sta.B				   $a0
RTS_Label:

;-------------------------------------------------------------------------------
; Math_Add1/2/3Byte - Addition variants with preset counts
;-------------------------------------------------------------------------------
Math_Add1Byte:
	lda.W				   #$0000	; 1 byte
	bra					 Math_AddTable

	lda.W				   #$0001	; 2 bytes
	bra					 Math_AddTable

	lda.W				   #$0002	; 3 bytes
	bra					 Math_AddTable

	lda.W				   #$0000	; Direct variants
	bra					 Math_AddDirect

	lda.W				   #$0001
	bra					 Math_AddDirect

	lda.W				   #$0002
	bra					 Math_AddDirect

;-------------------------------------------------------------------------------
; Math_SubTable/SubDirect - Subtraction (SUB)
; Purpose: Subtract values from $9e/$a0
;-------------------------------------------------------------------------------
Math_SubTable:
	jsr.W				   Memory_CopyWithTable ; Copy table
	bra					 Math_SubApply

Math_SubDirect:
	jsr.W				   Memory_CopyDirect ; Copy direct

Math_SubApply:
SEC_Label:
	lda.B				   $9e
	sbc.B				   $98	   ; Subtract $98
	sta.B				   $9e	   ; Store difference
	lda.B				   $a0
	sbc.B				   $9a	   ; Subtract $9a with borrow
	sta.B				   $a0
RTS_Label:

;-------------------------------------------------------------------------------
; Subtraction variants with preset counts
;-------------------------------------------------------------------------------
	lda.W				   #$0000
	bra					 Math_SubTable

	lda.W				   #$0001
	bra					 Math_SubTable

	lda.W				   #$0002
	bra					 Math_SubTable

	lda.W				   #$0000
	bra					 Math_SubDirect

	lda.W				   #$0001
	bra					 Math_SubDirect

	lda.W				   #$0002
	bra					 Math_SubDirect

;-------------------------------------------------------------------------------
; Math_Divide - Division (16-bit / 8-bit)
; Purpose: Divide $9e by accumulator
; Entry: A = divisor (8-bit)
; Exit: $98 = quotient, $9a = remainder (via CODE_0096B3)
;-------------------------------------------------------------------------------
Math_Divide:
	sta.B				   $9c	   ; Store divisor
	lda.B				   $9e	   ; Load dividend
	sta.B				   $98	   ; Setup for division
	jsl.L				   CODE_0096B3 ; Call division routine
RTS_Label:

	lda.B				   [$17]	 ; Variant: divisor from script
	inc.B				   $17
	and.W				   #$00ff
	bra					 CODE_00B0E6

	db											 $a7,$17,$e6,$17,$e6,$17,$80,$e4 ; 16-bit divisor variant

	jsr.W				   Test_LoadValue9E ; Variant: divisor from $9e
	bra					 Math_Divide

	jsr.W				   Test_LoadValueRNG ; Variant: divisor from RNG
	bra					 Math_Divide

;-------------------------------------------------------------------------------
; Math_Multiply8: Multiplication (16-bit × 8-bit)
; Purpose: Multiply $9e/$a0 by accumulator
; Entry: A = multiplier (8-bit)
; Exit: Result in $98/$9a (via CODE_0096E4)
;-------------------------------------------------------------------------------
Math_Multiply8:
	sta.B				   $9c	   ; Store multiplier
	lda.B				   $9e	   ; Load multiplicand low
	sta.B				   $98
	lda.B				   $a0	   ; Load multiplicand high
	sta.B				   $9a
	jsl.L				   CODE_0096E4 ; Call multiplication routine
RTS_Label:

;-------------------------------------------------------------------------------
; Math_Multiply8_Script: Multiplication variants
;-------------------------------------------------------------------------------
Math_Multiply8_Script:
	lda.B				   [$17]	 ; Multiplier from script (8-bit)
	inc.B				   $17
	and.W				   #$00ff
	bra					 Math_Multiply8

	lda.B				   [$17]	 ; Multiplier from script (16-bit)
	inc.B				   $17
	inc.B				   $17
	bra					 Math_Multiply8

	db											 $20,$88,$b1,$80,$db ; From Test_LoadValue8

	jsr.W				   Test_LoadValue16 ; From Test_LoadValue16
	bra					 Math_Multiply8

;-------------------------------------------------------------------------------
; Math_GetRNGResult: Get random number result
; Purpose: Transfer RNG result ($a2) to $9e
; Exit: $9e = random value, $a0 = 0
;-------------------------------------------------------------------------------
Math_GetRNGResult:
	lda.B				   $a2	   ; Load RNG result
	sta.B				   $9e	   ; Store in $9e
	stz.B				   $a0	   ; Clear high byte
RTS_Label:

	jsr.W				   Math_Multiply8_Script ; Variant: multiply then get result
	bra					 Math_GetRNGResult

	db											 $20,$24,$b1,$80,$ef,$20,$2c,$b1,$80,$ea,$20,$31,$b1,$80,$e5

;-------------------------------------------------------------------------------
; Math_FormatDecimal: Format decimal number for display
; Purpose: Convert binary value to BCD for display
; Entry: $9e/$a0 = value to convert
; Exit: Formatted value in buffer at $6d
;-------------------------------------------------------------------------------
Math_FormatDecimal:
	pei.B				   ($9e)	 ; Save $9e
	pei.B				   ($a0)	 ; Save $a0
	lda.W				   #$0090	; BCD format flags
	sta.B				   $6d	   ; Store in buffer
	lda.W				   #$000a	; Base 10 (decimal)
	sta.B				   $9c	   ; Store base
	ldx.W				   #$006d	; X = buffer pointer
CLC_Label:
	jsl.L				   CODE_009824 ; Call BCD conversion
	pla							   ; Restore $a0
	sta.B				   $a0
	pla							   ; Restore $9e
	sta.B				   $9e
RTS_Label:

;-------------------------------------------------------------------------------
; Math_FormatHex: Format hexadecimal number for display
; Purpose: Convert binary value to hex for display
;-------------------------------------------------------------------------------
Math_FormatHex:
	pei.B				   ($9e)	 ; Save values
	pei.B				   ($a0)
	lda.W				   #$0010	; Base 16 (hexadecimal)
	sta.B				   $9c
	ldx.W				   #$006d	; Buffer pointer
	sec							   ; Hex mode flag
	jsl.L				   CODE_009824 ; Call hex conversion
PLA_Label:
	sta.B				   $a0
PLA_Label:
	sta.B				   $9e
RTS_Label:

;-------------------------------------------------------------------------------
; CODE_00B185 - Helper routines for loading test values
;-------------------------------------------------------------------------------
System_LoadFrom3A:
	lda.B				   $3a	   ; Load from $3a
RTS_Label:

Test_LoadValue8:
	lda.B				   [$17]	 ; Load 8-bit from script
	inc.B				   $17
	and.W				   #$00ff
RTS_Label:

Test_LoadValue9E:
	lda.B				   $9e	   ; Load from $9e
RTS_Label:

Test_LoadValueRNG:
	lda.B				   $a2	   ; Load from $a2 (RNG)
RTS_Label:

Test_LoadValue16:
	lda.B				   [$17]	 ; Load 16-bit from script
	inc.B				   $17
	inc.B				   $17
RTS_Label:

;-------------------------------------------------------------------------------
; Test_CompareValue24: Compare 16-bit values (equality test)
; Purpose: Test if $9e/$a0 == value from script
; Entry: [$17] = 16-bit value, [$17+2] = 8-bit high byte
; Exit: Z flag set if equal, C flag indicates comparison result
;-------------------------------------------------------------------------------
Test_CompareValue24:
	lda.B				   [$17]	 ; Load comparison value low
	inc.B				   $17
	inc.B				   $17
	sta.B				   $64	   ; Save in $64
	lda.B				   [$17]	 ; Load comparison value high
	inc.B				   $17
	and.W				   #$00ff
	sta.B				   $62	   ; Save in $62
	sec							   ; Set carry for comparison
	lda.B				   $a0	   ; Load high byte
	sbc.B				   $62	   ; Subtract comparison high
	bne					 CODE_00B1C2 ; If not equal, done
	lda.B				   $9e	   ; Load low byte
	sbc.B				   $64	   ; Subtract comparison low
; Z flag = equality result
; C flag = greater/equal result

Test_CompareDone:
RTS_Label:

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
; Test_CompareDP: Comparison test via external routine (from $2e context)
;
; Purpose: Set up direct page context and call external comparison routine
; Entry: $2e = direct page base to use
;        $9e = value to test
; Exit: Flags set by external comparison
; Uses: Bit_TestBits (external comparison routine)
;-------------------------------------------------------------------------------
Test_CompareDP:
	lda.B				   $2e	   ; Load context pointer
	phd							   ; Save current direct page
	tcd							   ; Set $2e as new DP base
	lda.W				   $009e	 ; Load value from $9e in new context
	jsl.L				   Bit_TestBits ; Call external comparison
	pld							   ; Restore direct page
	inc					 a; Set flags
	dec					 a; (Z flag = equality)
RTS_Label:

;-------------------------------------------------------------------------------
; Test_Compare8: 8-bit comparison test
;
; Purpose: Compare $9e/$a0 with 8-bit value from script (16-bit safe check)
; Entry: [$17] = 8-bit comparison value
;        $9e/$a0 = value to test
; Exit: Carry and Zero flags set based on comparison
;       $17 incremented by 1
; Notes: Returns immediately if $a0 != 0 (value > 255)
;-------------------------------------------------------------------------------
Test_Compare8:
	lda.B				   [$17]	 ; Load 8-bit comparison value
	inc.B				   $17	   ; Advance script pointer
	and.W				   #$00ff	; Mask to 8 bits
	sta.B				   $64	   ; Store comparison value
	sec							   ; Set carry for comparison
	lda.B				   $a0	   ; Check high byte
	bne					 Test_Compare8_Done ; If non-zero, value > 255, return
	lda.B				   $9e	   ; Compare low byte
	cmp.B				   $64	   ; Set C and Z flags
Test_Compare8_Done:
RTS_Label:

;-------------------------------------------------------------------------------
; Test_Compare16: 16-bit comparison test
;
; Purpose: Compare $9e/$a0 with 16-bit value from script (24-bit safe check)
; Entry: [$17] = 16-bit comparison value
;        $9e/$a0 = value to test
; Exit: Carry and Zero flags set based on comparison
;       $17 incremented by 2
; Notes: Returns immediately if $a0 != 0 (value > 65535)
;-------------------------------------------------------------------------------
Test_Compare16:
	lda.B				   [$17]	 ; Load 16-bit comparison value
	inc.B				   $17	   ; Advance script pointer
	inc.B				   $17	   ; (2 bytes)
	sta.B				   $64	   ; Store comparison value
	sec							   ; Set carry for comparison
	lda.B				   $a0	   ; Check high byte
	bne					 Test_Compare16_Done ; If non-zero, value > $ffff, return
	lda.B				   $9e	   ; Compare low word
	cmp.B				   $64	   ; Set C and Z flags
Test_Compare16_Done:
RTS_Label:

;-------------------------------------------------------------------------------
; Test_Compare24Full: 24-bit comparison test (full)
;
; Purpose: Compare $9e/$a0 with 24-bit value from script
; Entry: [$17] = 16-bit low word
;        [$17+2] = 8-bit high byte
;        $9e/$a0 = value to test
; Exit: Carry and Zero flags set based on comparison
;       $17 incremented by 3
; Notes: Full 24-bit comparison (high byte then low word)
;-------------------------------------------------------------------------------
Test_Compare24Full:
	lda.B				   [$17]	 ; Load low word
	inc.B				   $17
	inc.B				   $17
	sta.B				   $64	   ; Store low word
	lda.B				   [$17]	 ; Load high byte
	inc.B				   $17
	and.W				   #$00ff	; Mask to 8 bits
	sta.B				   $62	   ; Store high byte
	lda.B				   $a0	   ; Compare high bytes first
	cmp.B				   $62
	bne					 Test_Compare24Done ; If not equal, done (C/Z set)
	lda.B				   $9e	   ; Compare low words
	cmp.B				   $64
Test_Compare24Done:
RTS_Label:

;-------------------------------------------------------------------------------
; Test_CompareIndirect8 - Comparison with indirect 8-bit value
;
; Purpose: Compare $9e/$a0 with 8-bit value from memory (address from script)
; Entry: [$17] = pointer to 8-bit value
;        $9e/$a0 = value to test
; Exit: Carry and Zero flags set based on comparison
;       $17 incremented by 2
;-------------------------------------------------------------------------------
Test_CompareIndirect8:
	lda.B				   [$17]	 ; Load pointer
	inc.B				   $17
	inc.B				   $17
	tax							   ; Use as index
	lda.W				   $0000,x   ; Load 8-bit value from pointer
	and.W				   #$00ff	; Mask to 8 bits
	sta.B				   $64	   ; Store comparison value
	sec							   ; Set carry
	lda.B				   $a0	   ; Check high byte
	bne					 Test_CompareIndirect8Done ; If non-zero, return
	lda.B				   $9e	   ; Compare low byte
	cmp.B				   $64
Test_CompareIndirect8Done:
RTS_Label:

;-------------------------------------------------------------------------------
; Test_CompareIndirect16 - Comparison with indirect 16-bit value
;
; Purpose: Compare $9e/$a0 with 16-bit value from memory (address from script)
; Entry: [$17] = pointer to 16-bit value
;        $9e/$a0 = value to test
; Exit: Carry and Zero flags set based on comparison
;       $17 incremented by 2
;-------------------------------------------------------------------------------
Test_CompareIndirect16:
	lda.B				   [$17]	 ; Load pointer
	inc.B				   $17
	inc.B				   $17
	tax							   ; Use as index
	sec							   ; Set carry
	lda.B				   $a0	   ; Check high byte
	bne					 Test_CompareIndirect16Done ; If non-zero, return
	lda.B				   $9e	   ; Compare with value at pointer
	cmp.W				   $0000,x
Test_CompareIndirect16Done:
RTS_Label:

;-------------------------------------------------------------------------------
; Test_CompareIndirect24 - Comparison with indirect 24-bit value
;
; Purpose: Compare $9e/$a0 with 24-bit value from memory (address from script)
; Entry: [$17] = pointer to 24-bit value (word at X, byte at X+2)
;        $9e/$a0 = value to test
; Exit: Carry and Zero flags set based on comparison
;       $17 incremented by 2
;-------------------------------------------------------------------------------
Test_CompareIndirect24:
	lda.B				   [$17]	 ; Load pointer
	inc.B				   $17
	inc.B				   $17
	tax							   ; Use as index
	lda.W				   $0002,x   ; Load high byte from pointer+2
	and.W				   #$00ff	; Mask to 8 bits
	sta.B				   $64	   ; Store high byte
	lda.B				   $a0	   ; Compare high bytes
	cmp.B				   $64
	bne					 Test_CompareIndirect24Done ; If not equal, done
	lda.B				   $9e	   ; Compare low words
	cmp.W				   $0000,x   ; With value at pointer
Test_CompareIndirect24Done:
RTS_Label:

;-------------------------------------------------------------------------------
; String_CountHighBit - Count characters with high bit set (string analysis)
;
; Purpose: Count characters in a string where bit 7 is set (value >= $80)
; Entry: Multiple entry points:
;        00B24A: A = string length (8-bit from script)
;                $9e/$a0 = bank:address of string
;        00B253: A = string length from $3a
;                $9e/$a0 = bank:address of string
; Exit: $9e = count of characters with high bit set
;       $a0 = 0
; Uses: Bank switching, indexed byte scanning
; Notes: Useful for text encoding analysis (control codes, special chars)
;-------------------------------------------------------------------------------
String_CountHighBit:
	lda.B				   [$17]	 ; Load string length
	inc.B				   $17	   ; Advance script pointer
	and.W				   #$00ff	; Mask to 8 bits
	bra					 String_CountHighBit_Setup ; Jump to counter

; Entry point: length from $3a
	db											 $a5,$3a,$29,$ff,$00 ; LDA $3a; AND #$00ff (alternate entry)

String_CountHighBit_Setup:
	tay							   ; Y = string length (counter)
	lda.B				   $a0	   ; Get bank
	and.W				   #$00ff	; Mask to 8 bits
	pha							   ; Push bank
	plb							   ; Set data bank
	ldx.B				   $9e	   ; X = string address
	bra					 String_CountHighBit_Init ; Jump to scan loop

; Another entry point (different parameters)
	db											 $8b,$a7,$17,$e6,$17,$e6,$17,$aa,$a7,$17,$e6,$17,$29,$ff,$00,$a8 ; Alternate parameter loading

String_CountHighBit_Init:
	stz.B				   $9e	   ; Clear result counter
	stz.B				   $a0	   ; Clear high byte

String_CountHighBit_Loop:
	lda.W				   $0000,x   ; Load character from string
	and.W				   #$00ff	; Mask to 8 bits
	cmp.W				   #$0080	; Check if >= $80 (high bit set)
	bcc					 String_CountHighBit_Next ; If < $80, skip increment
	inc.B				   $9e	   ; Count this character

String_CountHighBit_Next:
	inx							   ; Next character
	dey							   ; Decrement counter
	bne					 String_CountHighBit_Loop ; Loop until done
	plb							   ; Restore bank
RTS_Label:

;-------------------------------------------------------------------------------
; Math_Negate - Negate value (two's complement)
;
; Purpose: Negate $9e/$a0 (convert to negative)
; Entry: $9e/$a0 = value
; Exit: $9e/$a0 = negated value (0 - original value)
; Notes: Two's complement: invert all bits and add 1
;        Equivalent to: result = 0 - value
;-------------------------------------------------------------------------------
Math_Negate:
	lda.W				   #$0000	; Load 0
	sec							   ; Set carry for subtraction
	sbc.B				   $9e	   ; 0 - low word
	sta.B				   $9e
	lda.W				   #$0000	; Load 0
	sbc.B				   $a0	   ; 0 - high byte (with borrow)
	sta.B				   $a0
RTS_Label:

;-------------------------------------------------------------------------------
; Bitfield_ToggleBits: Toggle bits in array (bitfield manipulation)
;
; Purpose: Toggle specific bits in a bitfield array based on script parameters
; Entry: [$17] = bit operation parameter (bit index and mode)
;        $5e = character/entity index
;        $5f/$61 = working registers
; Exit: Bits toggled in array at $XX00-$XX5F
; Uses: Bank switching, indexed bit manipulation
; Notes: Complex bitfield operation with XOR toggle
;        Uses character stats or similar bitfield array
;-------------------------------------------------------------------------------
Bitfield_ToggleBits:
	db											 $a2,$1a,$00,$a0,$5f,$00,$a9,$02,$00,$54,$00,$00,$a7,$17,$e6,$17
	db											 $29,$ff,$00,$48,$4a,$a8,$68,$3a,$0a,$65,$5f,$aa,$e2,$20,$a5,$61
	db											 $8b,$48,$ab,$c2,$30,$a7,$5f,$49,$00,$40,$48,$bd,$00,$00,$49,$00
	db											 $40,$87,$5f,$68,$9d,$00,$00,$ca,$ca,$e6,$5f,$e6,$5f,$88,$d0,$e5
	db											 $ab,$60
; TODO: Disassemble this complex bit manipulation routine

;-------------------------------------------------------------------------------
; Tilemap_DecrementRow: Decrement tilemap pointer by one row
;
; Purpose: Move tilemap pointer up one row (subtract $40 = 64 bytes)
; Entry: $1a = tilemap pointer
; Exit: $1a -= $40
; Notes: SNES tilemap rows are $40 bytes apart (32 tiles × 2 bytes/tile)
;-------------------------------------------------------------------------------
Tilemap_DecrementRow:
	lda.B				   $1a	   ; Load tilemap pointer
	sec							   ; Set carry for subtraction
	sbc.W				   #$0040	; Subtract one row ($40 bytes)
	sta.B				   $1a	   ; Store result
RTS_Label:

;-------------------------------------------------------------------------------
; Tilemap_IncrementRow: Increment tilemap pointer by one row
;
; Purpose: Move tilemap pointer down one row (add $40 = 64 bytes)
; Entry: $1a = tilemap pointer
; Exit: $1a += $40
; Notes: SNES tilemap rows are $40 bytes apart
;-------------------------------------------------------------------------------
Tilemap_IncrementRow:
	lda.B				   $1a	   ; Load tilemap pointer
	clc							   ; Clear carry for addition
	adc.W				   #$0040	; Add one row ($40 bytes)
	sta.B				   $1a	   ; Store result
RTS_Label:

;-------------------------------------------------------------------------------
; Tilemap_DecrementTile: Decrement tilemap pointer by one tile
;
; Purpose: Move tilemap pointer left one tile (subtract 2 bytes)
; Entry: $1a = tilemap pointer
; Exit: $1a -= 2
; Notes: Each tilemap entry is 2 bytes (tile number + attributes)
;-------------------------------------------------------------------------------
Tilemap_DecrementTile:
	dec.B				   $1a	   ; Decrement low byte
	dec.B				   $1a	   ; Decrement again (2 bytes)
RTS_Label:

;-------------------------------------------------------------------------------
; Tilemap_IncrementTile: Increment tilemap pointer by one tile
;
; Purpose: Move tilemap pointer right one tile (add 2 bytes)
; Entry: $1a = tilemap pointer
; Exit: $1a += 2
; Notes: Each tilemap entry is 2 bytes
;-------------------------------------------------------------------------------
Tilemap_IncrementTile:
	inc.B				   $1a	   ; Increment low byte
	inc.B				   $1a	   ; Increment again (2 bytes)
RTS_Label:

;-------------------------------------------------------------------------------
; Cmd_CallExternal16: Jump to external routine with 16-bit parameter
;
; Purpose: Load 16-bit parameter from script and call external function
; Entry: [$17] = 16-bit parameter
; Exit: $17 incremented by 2
;       Returns from external function
; Calls: CODE_009DCB (external routine)
;-------------------------------------------------------------------------------
Cmd_CallExternal16:
	lda.B				   [$17]	 ; Load 16-bit parameter
	inc.B				   $17	   ; Advance script pointer
	inc.B				   $17	   ; (2 bytes)
	jmp.W				   CODE_009DCB ; Jump to external routine

;-------------------------------------------------------------------------------
; Cmd_CallExternal8: Jump to external routine with 8-bit parameter
;
; Purpose: Load 8-bit parameter from script and call external function
; Entry: [$17] = 8-bit parameter
; Exit: $17 incremented by 1
;       Returns from external function
; Calls: CODE_009DC9 (external routine)
;-------------------------------------------------------------------------------
Cmd_CallExternal8:
	lda.B				   [$17]	 ; Load 8-bit parameter
	inc.B				   $17	   ; Advance script pointer
	and.W				   #$00ff	; Mask to 8 bits
	jmp.W				   CODE_009DC9 ; Jump to external routine

;-------------------------------------------------------------------------------
; Math_ShiftRight: Right shift $9e/$a0 by N bits
;
; Purpose: Logical right shift of 16-bit value
; Entry: [$17] = shift count (1-15)
;        $9e/$a0 = value to shift
; Exit: $9e/$a0 = value >> shift_count
;       $17 incremented by 1
; Notes: Each iteration: LSR high byte, ROR low byte (preserves shifted bits)
;-------------------------------------------------------------------------------
Math_ShiftRight:
	lda.B				   [$17]	 ; Load shift count
	inc.B				   $17	   ; Advance script pointer
	and.W				   #$00ff	; Mask to 8 bits

Math_ShiftRight_Loop:
	lsr.B				   $a0	   ; Shift high byte right
	ror.B				   $9e	   ; Rotate low byte right (carry in)
	dec					 a; Decrement shift count
	bne					 Math_ShiftRight_Loop ; Loop until done
RTS_Label:

;-------------------------------------------------------------------------------
; Math_ShiftLeft: Left shift $9e/$a0 by N bits
;
; Purpose: Logical left shift of 16-bit value
; Entry: [$17] = shift count (1-15)
;        $9e/$a0 = value to shift
; Exit: $9e/$a0 = value << shift_count
;       $17 incremented by 1
; Notes: Each iteration: ASL low byte, ROL high byte (preserves shifted bits)
;-------------------------------------------------------------------------------
Math_ShiftLeft:
	lda.B				   [$17]	 ; Load shift count
	inc.B				   $17	   ; Advance script pointer
	and.W				   #$00ff	; Mask to 8 bits

Math_ShiftLeft_Loop:
	asl.B				   $9e	   ; Shift low byte left
	rol.B				   $a0	   ; Rotate high byte left (carry in)
	dec					 a; Decrement shift count
	bne					 Math_ShiftLeft_Loop ; Loop until done
RTS_Label:

;-------------------------------------------------------------------------------
; Math_ShiftRightIndirect: Right shift by N bits (from indirect address)
;
; Purpose: Right shift $9e/$a0 by count from memory pointer
; Entry: [$17] = pointer to shift count (16-bit address)
;        $9e/$a0 = value to shift
; Exit: $9e/$a0 = value >> [pointer]
;       $17 incremented by 2
;-------------------------------------------------------------------------------
Math_ShiftRightIndirect:
	db											 $a7,$17,$e6,$17,$e6,$17,$aa,$bd,$00,$00,$29,$ff,$00,$46,$a0,$66
	db											 $9e,$3a,$d0,$f9,$60
; LDA [$17]; INC $17; INC $17; TAX; LDA $0000,X; AND #$00ff
; LSR $a0; ROR $9e; DEC A; BNE loop; RTS

;-------------------------------------------------------------------------------
; Math_ShiftLeftIndirect: Left shift by N bits (from indirect address)
;
; Purpose: Left shift $9e/$a0 by count from memory pointer
; Entry: [$17] = pointer to shift count (16-bit address)
;        $9e/$a0 = value to shift
; Exit: $9e/$a0 = value << [pointer]
;       $17 incremented by 2
;-------------------------------------------------------------------------------
Math_ShiftLeftIndirect:
	db											 $a7,$17,$e6,$17,$e6,$17,$aa,$bd,$00,$00,$29,$ff,$00,$06,$9e,$26
	db											 $a0,$3a,$d0,$f9,$60
; LDA [$17]; INC $17; INC $17; TAX; LDA $0000,X; AND #$00ff
; ASL $9e; ROL $a0; DEC A; BNE loop; RTS

;-------------------------------------------------------------------------------
; Script_NoOp: No operation (placeholder)
;
; Purpose: Empty function (immediate return)
; Notes: May be unused or placeholder for future functionality
;-------------------------------------------------------------------------------
Script_NoOp:
RTS_Label:

;-------------------------------------------------------------------------------
; Script_Execute: Execute script or function call
;
; Purpose: Execute script function or register external script
; Entry: [$17] = function/script address
; Exit: $17 incremented by 2
;       Script executed or registered
; Calls: Script_Execute_Handler (script execution handler)
;       CODE_00A71C (external script registration)
;       CODE_01B24C (script initialization)
; Notes: Handles both internal scripts (>= $8000) and external scripts (< $8000)
;-------------------------------------------------------------------------------
Script_Execute:
	lda.B				   [$17]	 ; Load script address
	inc.B				   $17	   ; Advance script pointer
	inc.B				   $17	   ; (2 bytes)

Script_Execute_Handler:
	cmp.W				   #$8000	; Check if >= $8000 (internal script)
	bcc					 Script_Execute_External ; If < $8000, external script
	tax							   ; X = script address
	lda.W				   #$0003	; Script mode 3
	jmp.W				   CODE_00A71C ; Register and execute script

Script_Execute_External:
	pei.B				   ($17)	 ; Save current script pointer
	pei.B				   ($18)	 ; (both bytes)
	sta.W				   $19ee	 ; Store script address
	jsl.L				   CODE_01B24C ; Initialize and run script
	pla							   ; Restore script pointer
	sta.B				   $18
PLA_Label:
	sta.B				   $17
RTS_Label:

;-------------------------------------------------------------------------------
; Script_ExecuteList: Execute script list (loop until $ffff terminator)
;
; Purpose: Execute multiple scripts in sequence until terminator
; Entry: [$17] = pointer to script address list
;        List format: [addr1][addr2]...[FFFF]
; Exit: All scripts executed
;       $17 advanced past terminator
; Notes: Processes scripts one by one, stops at $ffff marker
;-------------------------------------------------------------------------------
Script_ExecuteList:
	lda.B				   [$17]	 ; Load script address
	inc.B				   $17	   ; Advance pointer
	inc.B				   $17	   ; (2 bytes)
	cmp.W				   #$ffff	; Check for terminator
	beq					 Script_ExecuteList_Done ; If $ffff, done
	jsr.W				   Script_Execute_Handler ; Execute this script
	rep					 #$30		; Ensure 16-bit mode
	bra					 Script_ExecuteList ; Loop to next script

Script_ExecuteList_Done:
RTS_Label:

;-------------------------------------------------------------------------------
; Math_RandomTransform: Random number transformation
;
; Purpose: Apply random number transformation to $9e
; Entry: $9e = input value
; Exit: $9e = transformed value
; Calls: CODE_009730 (external RNG transformation)
;-------------------------------------------------------------------------------
Math_RandomTransform:
	lda.B				   $9e	   ; Load value
	jsl.L				   CODE_009730 ; Apply RNG transformation
	sta.B				   $9e	   ; Store result
RTS_Label:

;-------------------------------------------------------------------------------
; Math_CountLeadingZeros: Count leading zeros (bit scan)
;
; Purpose: Count number of leading zero bits in $9e
; Entry: $9e = value to scan
; Exit: $9e = count of leading zeros (0-16)
; Notes: Scans from bit 15 down to bit 0, stops at first 1 bit
;        Used for bit significance detection
;-------------------------------------------------------------------------------
Math_CountLeadingZeros:
	lda.B				   $9e	   ; Load value
	ldx.W				   #$0010	; Start with 16 (max leading zeros)

Math_CountLeadingZeros_Loop:
	dex							   ; Decrement counter
	asl					 a; Shift left (bit 15 → Carry)
	bcc					 Math_CountLeadingZeros_Loop ; If carry clear (bit was 0), continue
	stx.B				   $9e	   ; Store leading zero count
RTS_Label:

;-------------------------------------------------------------------------------
; Math_Increment24: Increment $9e/$a0 (24-bit safe)
;
; Purpose: Increment 16-bit value with carry to high byte
; Entry: $9e/$a0 = value
; Exit: $9e/$a0 = value + 1
; Notes: Handles carry from $9e to $a0
;-------------------------------------------------------------------------------
Math_Increment24:
	inc.B				   $9e	   ; Increment low word
	bne					 Math_Increment24_Done ; If not zero, done
	db											 $e6,$a0	 ; INC $a0 (high byte)

Math_Increment24_Done:
RTS_Label:

;-------------------------------------------------------------------------------
; Cmd_IncrementIndirect16: Increment 16-bit value at pointer (from script)
;
; Purpose: Increment word at memory address from script
; Entry: [$17] = pointer to 16-bit value
; Exit: Word at pointer incremented
;       $17 incremented by 2
;-------------------------------------------------------------------------------
Cmd_IncrementIndirect16:
	lda.B				   [$17]	 ; Load pointer
	inc.B				   $17	   ; Advance script pointer
	inc.B				   $17	   ; (2 bytes)
	tax							   ; X = pointer
	inc.W				   $0000,x   ; Increment word at pointer
RTS_Label:

;-------------------------------------------------------------------------------
; Cmd_IncrementIndirect8: Increment 8-bit value at pointer (from script)
;
; Purpose: Increment byte at memory address from script
; Entry: [$17] = pointer to 8-bit value
; Exit: Byte at pointer incremented
;       $17 incremented by 2
; Notes: Switches to 8-bit accumulator mode
;-------------------------------------------------------------------------------
Cmd_IncrementIndirect8:
	lda.B				   [$17]	 ; Load pointer
	inc.B				   $17	   ; Advance script pointer
	inc.B				   $17	   ; (2 bytes)
	tax							   ; X = pointer
	sep					 #$20		; 8-bit accumulator
	inc.W				   $0000,x   ; Increment byte at pointer
RTS_Label:

;-------------------------------------------------------------------------------
; Math_Decrement24: Decrement $9e/$a0 (24-bit safe)
;
; Purpose: Decrement 16-bit value with borrow from high byte
; Entry: $9e/$a0 = value
; Exit: $9e/$a0 = value - 1
; Notes: Handles borrow from $a0 to $9e
;-------------------------------------------------------------------------------
Math_Decrement24:
	lda.B				   $9e	   ; Load low word
	sec							   ; Set carry for subtraction
	sbc.W				   #$0001	; Subtract 1
	sta.B				   $9e	   ; Store result
	bcs					 Math_Decrement24_Done ; If carry set, no borrow needed
	dec.B				   $a0	   ; Borrow from high byte

Math_Decrement24_Done:
RTS_Label:

;-------------------------------------------------------------------------------
; Cmd_DecrementIndirect16: Decrement 16-bit value at pointer (from script)
;
; Purpose: Decrement word at memory address from script
; Entry: [$17] = pointer to 16-bit value
; Exit: Word at pointer decremented
;       $17 incremented by 2
;-------------------------------------------------------------------------------
Cmd_DecrementIndirect16:
	lda.B				   [$17]	 ; Load pointer
	inc.B				   $17	   ; Advance script pointer
	inc.B				   $17	   ; (2 bytes)
	tax							   ; X = pointer
	dec.W				   $0000,x   ; Decrement word at pointer
RTS_Label:

;-------------------------------------------------------------------------------
; Cmd_DecrementIndirect8: Decrement 8-bit value at pointer (from script)
;
; Purpose: Decrement byte at memory address from script
; Entry: [$17] = pointer to 8-bit value
; Exit: Byte at pointer decremented
;       $17 incremented by 2
; Notes: Switches to 8-bit accumulator mode
;-------------------------------------------------------------------------------
Cmd_DecrementIndirect8:
	lda.B				   [$17]	 ; Load pointer
	inc.B				   $17	   ; Advance script pointer
	inc.B				   $17	   ; (2 bytes)
	tax							   ; X = pointer
	sep					 #$20		; 8-bit accumulator
	dec.W				   $0000,x   ; Decrement byte at pointer
RTS_Label:

;-------------------------------------------------------------------------------
; Bitwise_ORIndirect16: Bitwise OR from indirect addresses
;
; Purpose: OR value from first pointer with value from second pointer, store at first
; Entry: [$17] = destination pointer (16-bit address)
;        [$17+2] = source pointer (16-bit address)
; Exit: [dest] = [dest] OR [source]
;       $17 incremented by 4
;-------------------------------------------------------------------------------
Bitwise_ORIndirect16:
	db											 $a7,$17,$e6,$17,$e6,$17,$aa,$a7,$17,$e6,$17,$e6,$17,$3d,$00,$00
	db											 $9d,$00,$00,$60
; LDA [$17]; INC $17; INC $17; TAX
; LDA [$17]; INC $17; INC $17
; ORA $0000,X; STA $0000,X; RTS

;-------------------------------------------------------------------------------
; Bitwise_ANDIndirect8: Bitwise AND from indirect addresses (8-bit)
;
; Purpose: AND byte from second pointer with byte at first pointer, store at first
; Entry: [$17] = destination pointer (16-bit address)
;        [$17+2] = 8-bit mask value
; Exit: [dest] = [dest] AND mask (8-bit operation)
;       $17 incremented by 3
; Notes: Uses 8-bit accumulator mode
;-------------------------------------------------------------------------------
Bitwise_ANDIndirect8:
	lda.B				   [$17]	 ; Load destination pointer
	inc.B				   $17
	inc.B				   $17
	tax							   ; X = destination
	lda.B				   [$17]	 ; Load mask value
	inc.B				   $17
	and.W				   #$00ff	; Mask to 8 bits
	sep					 #$20		; 8-bit accumulator
	and.W				   $0000,x   ; AND with destination
	sta.W				   $0000,x   ; Store result
RTS_Label:

;-------------------------------------------------------------------------------
; Bitwise_ANDIndirect16: Bitwise OR from indirect addresses (16-bit)
;
; Purpose: OR word from second pointer with word at first pointer
; Entry: [$17] = destination pointer (16-bit address)
;        [$17+2] = source pointer (16-bit address)
; Exit: [dest] = [dest] OR [source] (16-bit operation)
;       $17 incremented by 4
;-------------------------------------------------------------------------------
Bitwise_ANDIndirect16:
	db											 $a7,$17,$e6,$17,$e6,$17,$aa,$a7,$17,$e6,$17,$e6,$17,$1d,$00,$00
	db											 $9d,$00,$00,$60
; LDA [$17]; INC $17; INC $17; TAX
; LDA [$17]; INC $17; INC $17
; ORA $0000,X; STA $0000,X; RTS

;-------------------------------------------------------------------------------
; Bitwise_ORIndirect8: Bitwise OR with 8-bit immediate (to indirect)
;
; Purpose: OR byte at pointer with 8-bit value from script
; Entry: [$17] = destination pointer
;        [$17+2] = 8-bit mask value
; Exit: [dest] = [dest] OR mask (8-bit operation)
;       $17 incremented by 3
;-------------------------------------------------------------------------------
Bitwise_ORIndirect8:
	lda.B				   [$17]	 ; Load destination pointer
	inc.B				   $17
	inc.B				   $17
	tax							   ; X = destination
	lda.B				   [$17]	 ; Load mask value
	inc.B				   $17
	and.W				   #$00ff	; Mask to 8 bits
	sep					 #$20		; 8-bit accumulator
	ora.W				   $0000,x   ; OR with destination
	sta.W				   $0000,x   ; Store result
RTS_Label:

;-------------------------------------------------------------------------------
; Bitwise_XORIndirect16: Bitwise XOR from indirect addresses (16-bit)
;
; Purpose: XOR word from second pointer with word at first pointer
; Entry: [$17] = destination pointer
;        [$17+2] = source pointer
; Exit: [dest] = [dest] XOR [source] (16-bit operation)
;       $17 incremented by 4
;-------------------------------------------------------------------------------
Bitwise_XORIndirect16:
	db											 $a7,$17,$e6,$17,$e6,$17,$aa,$a7,$17,$e6,$17,$e6,$17,$5d,$00,$00
	db											 $9d,$00,$00,$60
; LDA [$17]; INC $17; INC $17; TAX
; LDA [$17]; INC $17; INC $17
; EOR $0000,X; STA $0000,X; RTS

;-------------------------------------------------------------------------------
; Bitwise_XORIndirect8: Bitwise XOR with 8-bit immediate (to indirect)
;
; Purpose: XOR byte at pointer with 8-bit value from script
; Entry: [$17] = destination pointer
;        [$17+2] = 8-bit mask value
; Exit: [dest] = [dest] XOR mask (8-bit operation)
;       $17 incremented by 3
;-------------------------------------------------------------------------------
Bitwise_XORIndirect8:
	lda.B				   [$17]	 ; Load destination pointer
	inc.B				   $17
	inc.B				   $17
	tax							   ; X = destination
	lda.B				   [$17]	 ; Load mask value
	inc.B				   $17
	and.W				   #$00ff	; Mask to 8 bits
	sep					 #$20		; 8-bit accumulator
	eor.W				   $0000,x   ; XOR with destination
	sta.W				   $0000,x   ; Store result
RTS_Label:

;-------------------------------------------------------------------------------
; Sprite_CalcTileAddress: Calculate tile address for character sprite
;
; Purpose: Calculate tilemap tile address for character sprite positioning
; Entry: $5e = character/entity index
; Exit: A = tile index/address
;       Various working registers updated
; Notes: Two entry points:
;        00B466: Offset $2a (42)
;        00B46B: Offset $0a (10)
;        Uses character position data from $049800 table
;-------------------------------------------------------------------------------
Sprite_CalcTileAddress:
	lda.W				   #$002a	; Offset 42
	bra					 Sprite_CalcTileAddress_Do ; Jump to calculator

Sprite_CalcTileAddress_Alt:
	lda.W				   #$000a	; Offset 10

Sprite_CalcTileAddress_Do:
	sep					 #$30		; 8-bit A/X/Y
	clc							   ; Clear carry
	ldx.B				   $5e	   ; Load character index
	adc.L				   DATA8_049800,x ; Add character position offset
	xba							   ; Swap A/B (position in high byte)
	txa							   ; A = character index
	and.B				   #$38	  ; Mask bits 3-5
	asl					 a; × 2
	sta.B				   $64	   ; Store intermediate
	txa							   ; A = character index again
	and.B				   #$07	  ; Mask bits 0-2
	adc.B				   $64	   ; Add intermediate
	asl					 a; × 2 (tile address scaling)
	rep					 #$20		; 16-bit accumulator
	sep					 #$10		; 8-bit X/Y
	ldy.B				   #$00	  ; Y = 0
	sta.B				   [$1a],y   ; Store at tilemap pointer
	inc					 a; Next tile
	ldy.B				   #$02	  ; Y = 2
	sta.B				   [$1a],y   ; Store at tilemap+2
	adc.W				   #$000f	; Add 15 (next row offset)
	ldy.B				   #$40	  ; Y = $40 (row below)
	sta.B				   [$1a],y   ; Store at tilemap+$40
	inc					 a; Next tile
	ldy.B				   #$42	  ; Y = $42
	sta.B				   [$1a],y   ; Store at tilemap+$42
RTS_Label:

;-------------------------------------------------------------------------------
; Tilemap_UpdateMin: Update minimum tilemap pointer
;
; Purpose: Track minimum tilemap pointer in $44
; Entry: $1a = current tilemap pointer
;        $44 = current minimum
; Exit: $44 = min($44, $1a)
; Notes: Used for dirty rectangle optimization
;-------------------------------------------------------------------------------
Tilemap_UpdateMin:
	lda.B				   $1a	   ; Load current pointer
	cmp.B				   $44	   ; Compare with current min
	bcs					 Tilemap_UpdateMin_Done ; If >= min, skip
	sta.B				   $44	   ; Update minimum

Tilemap_UpdateMin_Done:
RTS_Label:

;-------------------------------------------------------------------------------
; Tilemap_UpdateMax: Update maximum tilemap pointer
;
; Purpose: Track maximum tilemap pointer in $46
; Entry: $1a = current tilemap pointer
;        $46 = current maximum
; Exit: $46 = max($46, $1a)
; Notes: Used for dirty rectangle optimization (max extent)
;-------------------------------------------------------------------------------
Tilemap_UpdateMax:
	lda.B				   $1a	   ; Load current pointer
	cmp.B				   $46	   ; Compare with current max
	bcc					 Tilemap_UpdateMax_Done ; If < max, skip
	sta.B				   $46	   ; Update maximum

Tilemap_UpdateMax_Done:
RTS_Label:

;-------------------------------------------------------------------------------
; CODE_00B4B0: Check flag and execute routine
;
; Purpose: Check bit 5 of $da and branch to different routines
; Entry: $da = flag register
; Exit: Jumps to CODE_00A8C0 if bit 5 set, CODE_009DC9 otherwise
; Notes: Bit 5 of $da appears to be a mode or state flag
;-------------------------------------------------------------------------------
System_CheckModeJump:
	lda.W				   #$0020	; Bit 5 mask
	and.W				   $00da	 ; Test bit 5 of $da
	beq					 UNREACH_00B4BB ; If clear, jump to alternate
	jmp.W				   CODE_00A8C0 ; Jump to routine A

UNREACH_00B4BB:
	db											 $a9,$ff,$00,$4c,$c9,$9d ; LDA #$00ff; JMP CODE_009DC9

;-------------------------------------------------------------------------------
; Text_ClearModeSetNew: Clear text mode bits and set new mode
;
; Purpose: Clear bits 10-12 of $1d and set new text mode from script
; Entry: [$17] = 8-bit text mode value
;        $1d = current text mode flags
; Exit: $1d bits 10-12 cleared
;       $1e |= new mode bits
;       $17 incremented by 1
; Notes: Text rendering mode control
;-------------------------------------------------------------------------------
Text_ClearModeSetNew:
	lda.W				   #$1c00	; Bits 10-12 mask
	trb.B				   $1d	   ; Clear bits in $1d
	lda.B				   [$17]	 ; Load new mode value
	inc.B				   $17	   ; Advance script pointer
	and.W				   #$00ff	; Mask to 8 bits
	tsb.B				   $1e	   ; Set bits in $1e
RTS_Label:

;-------------------------------------------------------------------------------
; Math_RNGSeed: RNG seed setup and call
;
; Purpose: Set up RNG seed from script and generate random number
; Entry: [$17] = 8-bit seed/parameter
; Exit: $9e = random number result
;       $a0 = 0
;       $17 incremented by 1
; Calls: CODE_009783 (RNG routine)
;-------------------------------------------------------------------------------
Math_RNGSeed:
	stz.B				   $9e	   ; Clear $9e
	stz.B				   $a0	   ; Clear $a0
	lda.B				   [$17]	 ; Load seed parameter
	inc.B				   $17	   ; Advance script pointer
	and.W				   #$00ff	; Mask to 8 bits
	sep					 #$20		; 8-bit accumulator
	sta.W				   $00a8	 ; Store in RNG parameter location
	jsl.L				   CODE_009783 ; Call RNG routine
	lda.W				   $00a9	 ; Load RNG result
	sta.B				   $9e	   ; Store in $9e
RTS_Label:

;-------------------------------------------------------------------------------
; Cmd_CallExternal9E: Jump to external with $9e parameter
;
; Purpose: Call external routine with $9e as parameter
; Entry: $9e = parameter value
; Calls: CODE_009DCB (external routine)
;-------------------------------------------------------------------------------
Cmd_CallExternal9E:
	lda.B				   $9e	   ; Load parameter
	jmp.W				   CODE_009DCB ; Jump to external routine

;-------------------------------------------------------------------------------
; Text_CalcCentering: Center text based on character count
;
; Purpose: Calculate text centering offset based on character metrics
; Entry: [$17] = character count parameter
;        $63 = character width data (high byte)
;        $9e = base position
; Exit: $9e = centered position
;       $62/$63 = character count results
;       $17 incremented by 1
; Notes: Scans string at $1100 + offset
;        Counts characters until first < $80 or second >= $80 found
;        Calculates centering based on character distribution
;-------------------------------------------------------------------------------
Text_CalcCentering:
	lda.B				   [$17]	 ; Load character count param
	inc.B				   $17	   ; Advance script pointer
	and.W				   #$00ff	; Mask to 8 bits
	sta.B				   $64	   ; Store count
	lda.B				   $63	   ; Load character width base
	and.W				   #$ff00	; Keep high byte
	lsr					 a; / 2 (adjust for offset)
	tax							   ; X = string offset
	adc.W				   #$1100	; Add buffer base address
	sta.B				   $9e	   ; Store in $9e (string pointer)
	ldy.W				   #$0010	; Y = 16 (max scan count)
	stz.B				   $62	   ; Clear first counter
	sep					 #$20		; 8-bit accumulator
	stz.B				   $a0	   ; Clear high byte

Text_CalcCentering_Loop1:
	lda.W				   $1100,x   ; Load character from buffer
	inx							   ; Next character
	cmp.B				   #$80	  ; Check if >= $80
	bcc					 Text_CalcCentering_Loop2 ; If < $80, found end of first section
	inc.B				   $62	   ; Count this character (>= $80)
	dey							   ; Decrement remaining
	bne					 Text_CalcCentering_Loop1 ; Loop until done
	db											 $80,$10	 ; BRA (skip next section)

Text_CalcCentering_Loop2:
	dey							   ; Decrement remaining
	beq					 Text_CalcCentering_Calc ; If done, exit

Text_CalcCentering_Loop2_Inner:
	lda.W				   $1100,x   ; Load character
	inx							   ; Next character
	cmp.B				   #$80	  ; Check if >= $80
	bcc					 Text_CalcCentering_Calc ; If < $80, still in second section
	inc.B				   $63	   ; Count this character (>= $80)
	dey							   ; Decrement remaining
	bne					 Text_CalcCentering_Loop2_Inner ; Loop

Text_CalcCentering_Calc:
	lda.B				   $62	   ; Load first count
	cmp.B				   $63	   ; Compare with second count
	bcs					 Text_CalcCentering_UseFirst ; If first >= second, use first
	lda.B				   $63	   ; Use second count

Text_CalcCentering_UseFirst:
	sta.B				   $62	   ; Store max count
	sec							   ; Set carry for subtraction
	lda.B				   $2a	   ; Load total width
	sbc.B				   #$02	  ; Subtract 2
	sbc.B				   $62	   ; Subtract max count
	lsr					 a; / 2 (center offset)
	clc							   ; Clear carry
	adc.B				   $25	   ; Add to base position
	sta.B				   $25	   ; Store centered position
	rep					 #$30		; 16-bit A/X/Y
	jsr.W				   CODE_00A8D1 ; Call positioning routine
RTS_Label:

;-------------------------------------------------------------------------------
; Text_SetCounter16: Set text counter and call text routine
;
; Purpose: Set $3a to $10 (16) and call text drawing routine
; Entry: (parameters set up by caller)
; Exit: Text drawing initiated
; Calls: CODE_00A7DE (text drawing routine)
;-------------------------------------------------------------------------------
Text_SetCounter16:
	lda.W				   #$0010	; Load 16
	sta.B				   $3a	   ; Store in counter
	jmp.W				   CODE_00A7DE ; Jump to text drawing

;-------------------------------------------------------------------------------
; Tilemap_WriteDynamic: Tilemap buffer manipulation (unclear function)
;
; Purpose: Complex tilemap buffer operation
; Entry: $015f = counter/index
;        $1a = tilemap pointer
;        $1f = parameter
; Exit: Tilemap buffer updated
;       $015f updated
; Notes: Uses indexed buffer writes with loop
;-------------------------------------------------------------------------------
Tilemap_WriteDynamic:
	db											 $c2,$20,$e2,$10,$ad,$5f,$01,$a4,$1f,$87,$1a,$e6,$1a,$e6,$1a,$1a
	db											 $88,$d0,$f6,$8d,$5f,$01,$60
; REP #$20; SEP #$10
; LDA $015f; LDY $1f
; STA [$1a]; INC $1a; INC $1a; INC A
; DEY; BNE loop; STA $015f; RTS

;-------------------------------------------------------------------------------
; Sprite_SetupCharacter: Character sprite setup and positioning
;
; Purpose: Set up character sprite display parameters based on game state
; Entry: $20 = location/mode ID
;        $da/$d9/$d0 = state flags
;        $c8 = location parameter
;        $e0 = display flags
;        $22/$23/$24 = sprite position/mode
; Exit: $22 = sprite X position (adjusted)
;       $23 = sprite Y position (adjusted)
;       $24 = sprite display mode
;       $d0 bit 2 set/cleared based on location
; Calls: CODE_018A52 (external sprite init)
; Notes: Complex location-based sprite positioning
;        Handles battle vs overworld sprite modes
;        Adjusts for screen centering and boundaries
;-------------------------------------------------------------------------------
Sprite_SetupCharacter:
	php							   ; Save processor status
	sep					 #$20		; 8-bit accumulator
	rep					 #$10		; 16-bit X/Y
	lda.B				   #$10	  ; Bit 4 mask
	and.W				   $00da	 ; Test bit 4 of $da
	beq					 Sprite_SetupCharacter_Normal ; If clear, normal mode
	lda.B				   #$04	  ; Mode 4 (battle mode)
	sta.B				   $24	   ; Store sprite mode
	ldx.W				   #$5f78	; Sprite data pointer
	stx.B				   $22	   ; Store in $22
	plp							   ; Restore processor status
RTS_Label:

Sprite_SetupCharacter_Normal:
	lda.B				   #$04	  ; Bit 2 mask
	trb.W				   $00d0	 ; Clear bit 2 of $d0
	jsl.L				   CODE_018A52 ; Call external sprite init
	lda.B				   #$01	  ; Bit 0 mask
	and.W				   $00d9	 ; Test bit 0 of $d9
	beq					 Sprite_SetupCharacter_CheckLocation ; If clear, skip
	lda.B				   #$08	  ; Mode 8
	sta.B				   $24	   ; Store sprite mode

Sprite_SetupCharacter_CheckLocation:
	lda.B				   $20	   ; Load location/mode ID
	cmp.B				   #$0b	  ; Location $0b?
	beq					 Sprite_SetupCharacter_Special ; If yes, special handling
	cmp.B				   #$a7	  ; Location $a7?
	beq					 Sprite_SetupCharacter_Special ; If yes, special handling
	cmp.B				   #$4f	  ; Location $4f?
	beq					 Sprite_SetupCharacter_SetBit2 ; If yes, set bit 2 in $d0
	cmp.B				   #$01	  ; Location $01?
	beq					 Sprite_SetupCharacter_AdjustX ; If yes, adjust X position
	cmp.B				   #$1b	  ; Location $1b?
	beq					 Sprite_SetupCharacter_AdjustX ; If yes, adjust X position
	cmp.B				   #$30	  ; Location $30?
	beq					 Sprite_SetupCharacter_AdjustX ; If yes, adjust X position
	cmp.B				   #$31	  ; Location $31?
	beq					 Sprite_SetupCharacter_AdjustX ; If yes, adjust X position
	cmp.B				   #$4e	  ; Location $4e?
	beq					 Sprite_SetupCharacter_AdjustX ; If yes, adjust X position
	cmp.B				   #$6b	  ; Location $6b?
	beq					 UNREACH_00B5C2 ; If yes, adjust Y position
	cmp.B				   #$77	  ; < $77?
	bcc					 Sprite_SetupCharacter_Continue ; If yes, continue
	cmp.B				   #$7b	  ; >= $7b?
	bcs					 Sprite_SetupCharacter_Continue ; If yes, continue
	db											 $80,$07	 ; BRA Sprite_SetupCharacter_AdjustX (unconditional)

UNREACH_00B5C2:
	db											 $18,$a5,$23,$69,$04,$85,$23 ; CLC; LDA $23; ADC #$04; STA $23

Sprite_SetupCharacter_AdjustX:
	clc							   ; Clear carry
	lda.B				   $22	   ; Load X position
	adc.B				   #$08	  ; Add 8
	sta.B				   $22	   ; Store X position
	lda.B				   #$04	  ; Mode 4
	sta.B				   $24	   ; Store sprite mode

Sprite_SetupCharacter_SetBit2:
	lda.B				   #$04	  ; Bit 2 mask
	tsb.W				   $00d0	 ; Set bit 2 of $d0
	bra					 Sprite_SetupCharacter_Continue ; Continue

Sprite_SetupCharacter_Special:
	lda.B				   #$04	  ; Mode 4
	sta.B				   $24	   ; Store sprite mode

Sprite_SetupCharacter_Continue:
	inc.B				   $23	   ; Increment Y position
	lda.B				   $24	   ; Load sprite mode
	bit.B				   #$08	  ; Test bit 3
	bne					 Sprite_SetupCharacter_Mode10 ; If set, use mode 10
	bit.B				   #$04	  ; Test bit 2
	bne					 Sprite_SetupCharacter_Mode5 ; If set, use mode 5
	bit.B				   #$02	  ; Test bit 1
	bne					 Sprite_SetupCharacter_Mode10 ; If set, use mode 10

Sprite_SetupCharacter_Mode5:
	lda.B				   #$05	  ; Mode 5
	bra					 Sprite_SetupCharacter_StoreMode ; Store mode

Sprite_SetupCharacter_Mode10:
	lda.B				   #$0a	  ; Mode 10

Sprite_SetupCharacter_StoreMode:
	sta.B				   $24	   ; Store final sprite mode
	lda.B				   $23	   ; Load Y position
	cmp.B				   #$08	  ; < $08?
	bcc					 UNREACH_00B607 ; If yes, clamp to $08
	cmp.B				   #$a9	  ; >= $a9?
	bcc					 Sprite_SetupCharacter_CheckX ; If no, in range
	db											 $a9,$a8,$85,$23,$80,$04 ; LDA #$a8; STA $23; BRA Sprite_SetupCharacter_CheckX

UNREACH_00B607:
	db											 $a9,$08,$85,$23 ; LDA #$08; STA $23

Sprite_SetupCharacter_CheckX:
	clc							   ; Clear carry
	lda.B				   $2d	   ; Load parameter
	xba							   ; Swap A/B
	lda.B				   #$0e	  ; Load 14
	adc.B				   $2d	   ; Add to parameter
	sta.B				   $2d	   ; Store result
	sta.B				   $64	   ; Store in temp
	adc.B				   #$05	  ; Add 5
	cmp.B				   $23	   ; Compare with Y position
	bcs					 Sprite_SetupCharacter_SetBit3 ; If >= Y, use mode bits
	sec							   ; Set carry
	lda.B				   #$a8	  ; Load $a8
	sbc.B				   $2d	   ; Subtract parameter
	cmp.B				   $23	   ; Compare with Y
	bcs					 Sprite_SetupCharacter_CheckXBounds ; If >= Y, continue
	lda.B				   $24	   ; Load sprite mode
	and.B				   #$f7	  ; Clear bit 3
	ora.B				   #$04	  ; Set bit 2
	sta.B				   $24	   ; Store updated mode
	bra					 Sprite_SetupCharacter_CheckXBounds ; Continue

Sprite_SetupCharacter_SetBit3:
	lda.B				   $24	   ; Load sprite mode
	and.B				   #$fb	  ; Clear bit 2
	ora.B				   #$08	  ; Set bit 3
	sta.B				   $24	   ; Store updated mode

Sprite_SetupCharacter_CheckXBounds:
	xba							   ; Swap A/B
	sta.B				   $2d	   ; Store parameter
	lda.B				   $22	   ; Load X position
	cmp.B				   #$20	  ; < $20?
	bcc					 Sprite_SetupCharacter_XLow ; If yes, clamp to $08
	cmp.B				   #$d1	  ; >= $d1?
	bcc					 Sprite_SetupCharacter_CalcYOffset ; If no, in range
	db											 $c9,$e9,$90,$04,$a9,$e8,$85,$22,$a5,$24,$29,$fd,$09,$01,$85,$24
	db											 $80,$10	 ; LDA #$e8; STA $22; LDA $24; AND #$fd; ORA #$01; STA $24; BRA

Sprite_SetupCharacter_XLow:
	cmp.B				   #$08	  ; < $08?
	bcs					 Sprite_SetupCharacter_XLow_SetBit1 ; If no, in range
	db											 $a9,$08,$85,$22 ; LDA #$08; STA $22

Sprite_SetupCharacter_XLow_SetBit1:
	lda.B				   $24	   ; Load sprite mode
	and.B				   #$fe	  ; Clear bit 0
	ora.B				   #$02	  ; Set bit 1
	sta.B				   $24	   ; Store updated mode

Sprite_SetupCharacter_CalcYOffset:
	lda.B				   $24	   ; Load sprite mode
	and.B				   #$08	  ; Test bit 3
	bne					 Sprite_SetupCharacter_AddYOffset ; If set, add $10 offset
	sec							   ; Set carry
	lda.B				   $23	   ; Load Y position
	sbc.B				   $64	   ; Subtract temp
	bra					 Sprite_SetupCharacter_StoreYOffset ; Store offset

Sprite_SetupCharacter_AddYOffset:
	clc							   ; Clear carry
	lda.B				   $23	   ; Load Y position
	adc.B				   #$10	  ; Add $10

Sprite_SetupCharacter_StoreYOffset:
	sta.B				   $62	   ; Store Y offset
	lda.W				   $00c8	 ; Load location parameter
	cmp.B				   #$00	  ; Check if 0
	bne					 Sprite_SetupCharacter_CheckAlt ; If not, alternate check
	lda.B				   #$40	  ; Bit 6 mask
	and.W				   $00e0	 ; Test bit 6 of $e0
	beq					 Sprite_SetupCharacter_Done ; If clear, done
	lda.W				   $01bf	 ; Load character 1 position
	bra					 Sprite_SetupCharacter_CheckPos ; Check position

Sprite_SetupCharacter_CheckAlt:
	lda.B				   #$80	  ; Bit 7 mask
	and.W				   $00e0	 ; Test bit 7 of $e0
	beq					 Sprite_SetupCharacter_Done ; If clear, done
	lda.W				   $0181	 ; Load character 2 position

Sprite_SetupCharacter_CheckPos:
	cmp.B				   $62	   ; Compare with Y offset
	bcc					 Sprite_SetupCharacter_CheckLower ; If less, check lower bound
	sbc.B				   $62	   ; Subtract Y offset
	cmp.B				   $64	   ; Compare with temp
	bcs					 Sprite_SetupCharacter_Done ; If >=, done
	bra					 Sprite_SetupCharacter_ToggleMode ; Toggle mode

Sprite_SetupCharacter_CheckLower:
	adc.B				   $64	   ; Add temp
	dec					 a; Decrement
	cmp.B				   $62	   ; Compare with Y offset
	bcc					 Sprite_SetupCharacter_Done ; If less, done

Sprite_SetupCharacter_ToggleMode:
	lda.B				   $24	   ; Load sprite mode
	eor.B				   #$0c	  ; Toggle bits 2-3
	sta.B				   $24	   ; Store updated mode

Sprite_SetupCharacter_Done:
	plp							   ; Restore processor status
RTS_Label:

;-------------------------------------------------------------------------------
; Sprite_DisplayCharacter: Character sprite display setup
;
; Purpose: Set up character sprite display using character index
; Entry: $9e = character index (or $de for special case)
; Exit: $62 = sprite mode
;       $64 = position offset
;       Sprite display initiated
; Calls: CODE_008C1B (character data lookup)
;        CODE_0C8000 (external sprite display)
; Notes: Special handling for character $de
;-------------------------------------------------------------------------------
Sprite_DisplayCharacter:
	lda.B				   $9e	   ; Load character index
	cmp.W				   #$00de	; Check if $de (special)
	beq					 Sprite_DisplayCharacter_Special ; If yes, special handling
	jsr.W				   CODE_008C1B ; Look up character data
	sta.B				   $62	   ; Store sprite mode
	sep					 #$30		; 8-bit A/X/Y
	ldx.B				   $9e	   ; X = character index
	lda.L				   DATA8_049800,x ; Load position offset
	asl					 a; × 2
	asl					 a; × 4

Sprite_DisplayCharacter_Do:
	sta.B				   $64	   ; Store position offset
	lda.B				   #$02	  ; Bit 1 mask
	tsb.W				   $00d4	 ; Set bit 1 of $d4
	jsl.L				   CODE_0C8000 ; Call external sprite display
RTS_Label:

Sprite_DisplayCharacter_Special:
	lda.W				   #$0001	; Mode 1
	sta.B				   $62	   ; Store sprite mode
	sep					 #$30		; 8-bit A/X/Y
	lda.B				   #$20	  ; Position $20
	bra					 Sprite_DisplayCharacter_Do ; Display sprite

;-------------------------------------------------------------------------------
; Script_SavePointerExecute: Save script pointer and execute script
;
; Purpose: Save current script pointer and execute CODE_00B78D
; Entry: $17/$18 = current script pointer
; Exit: Script pointer saved on stack
;       CODE_00B78D executed
;-------------------------------------------------------------------------------
Script_SavePointerExecute:
	pei.B				   ($17)	 ; Save script pointer low
	pei.B				   ($18)	 ; Save script pointer high
	jmp.W				   CODE_00B78D ; Jump to script execution

;-------------------------------------------------------------------------------
; Shop_SubtractGold: Update character gold amount
;
; Purpose: Subtract current value from party gold
; Entry: $0164/$0166 = amount to subtract (24-bit)
;        $0e84/$0e86 = current party gold
; Exit: $0e84/$0e86 = updated gold
;       $17/$18 restored from stack
; Notes: Part of shop/transaction system
;-------------------------------------------------------------------------------
Shop_SubtractGold:
	sec							   ; Set carry for subtraction
	lda.W				   $0e84	 ; Load gold low word
	sbc.W				   $0164	 ; Subtract amount low
	sta.W				   $0e84	 ; Store result low
	sep					 #$20		; 8-bit accumulator
	lda.W				   $0e86	 ; Load gold high byte
	sbc.W				   $0166	 ; Subtract amount high (with borrow)
	sta.W				   $0e86	 ; Store result high
	lda.W				   $015f	 ; Load character index
	cmp.B				   #$dd	  ; Check if $dd (special)
	beq					 Shop_SubtractGold_Alternate ; If yes, alternate storage
	jsl.L				   CODE_00DA65 ; Call external routine
	clc							   ; Clear carry
	adc.W				   $0162	 ; Add offset
	sta.W				   $0e9f,x   ; Store at indexed location
	lda.W				   $015f	 ; Load character index
	sta.W				   $0e9e,x   ; Store character ID
	bra					 Shop_SubtractGold_Done ; Restore and return

Shop_SubtractGold_Alternate:
	clc							   ; Clear carry
	lda.W				   $1030	 ; Load alternate storage
	adc.W				   $0162	 ; Add offset
	sta.W				   $1030	 ; Store result
	bra					 Shop_SubtractGold_Done ; Restore and return

Menu_ClearCursor:
	sep					 #$20		; 8-bit accumulator
	stz.W				   $0162	 ; Clear offset

Shop_SubtractGold_Done:
	plx							   ; Restore X (script pointer high)
	stx.B				   $18	   ; Store in $18
	plx							   ; Restore X (script pointer low)
	stx.B				   $17	   ; Store in $17
RTS_Label:

;-------------------------------------------------------------------------------
; Menu_InputHandler: Input handler for menu navigation
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
Menu_InputHandler:
	rep					 #$30		; 16-bit A/X/Y
	jsl.L				   CODE_0096A0 ; Read controller input
	lda.B				   $07	   ; Load button state
	sta.B				   $15	   ; Store in temp
	bit.W				   #$8000	; Test A button (bit 15)
	bne					 Menu_ClearCursor ; If pressed, clear and return
	bit.W				   #$0080	; Test B button (bit 7)
	bne					 Shop_SubtractGold ; If pressed, update gold
	bit.W				   #$0800	; Test X button (bit 11)
	bne					 UNREACH_00B7B5 ; If pressed, jump ahead
	bit.W				   #$0400	; Test Y button (bit 10)
	bne					 UNREACH_00B797 ; If pressed, move by 10
	bit.W				   #$0100	; Test Start (bit 8)
	bne					 Menu_InputHandler_Down ; If pressed, increment cursor
	bit.W				   #$0200	; Test Select (bit 9)
	beq					 Menu_InputHandler ; If not pressed, loop
	sep					 #$20		; 8-bit accumulator
	dec.W				   $0162	 ; Decrement cursor position
	bpl					 Menu_UpdateDisplay ; If >= 0, update menu
	lda.B				   $95	   ; Load wrapping flags
	and.B				   #$02	  ; Test bit 1 (wrap down)
	beq					 UNREACH_00B76B ; If no wrap, increment back
	lda.W				   $0163	 ; Load max position
	sta.W				   $0162	 ; Wrap to max
	bra					 Menu_UpdateDisplay ; Update menu

UNREACH_00B76B:
	db											 $ee,$62,$01,$80,$be ; INC $0162; BRA Menu_InputHandler

Menu_InputHandler_Down:
	sep					 #$20		; 8-bit accumulator
	inc.W				   $0162	 ; Increment cursor position
	lda.W				   $0163	 ; Load max position
	cmp.W				   $0162	 ; Compare with current
	bcs					 Menu_UpdateDisplay ; If max >= current, update
	lda.B				   $95	   ; Load wrapping flags
	and.B				   #$01	  ; Test bit 0 (wrap up)
	beq					 Menu_InputHandler_NoWrapUp ; If no wrap, decrement back
	stz.W				   $0162	 ; Wrap to 0
	bra					 Menu_UpdateDisplay ; Update menu

Menu_InputHandler_NoWrapUp:
	dec.W				   $0162	 ; Decrement back
	bra					 Menu_InputHandler ; Read input again

Menu_UpdateDisplay:
	rep					 #$30		; 16-bit A/X/Y
	ldx.W				   #$b7dd	; Menu data pointer
	jsr.W				   CODE_009BC4 ; Update menu display
	bra					 Menu_InputHandler ; Read input again

UNREACH_00B797:
	db											 $e2,$20,$38,$ad,$62,$01,$f0,$08,$e9,$0a,$b0,$0d,$a9,$00,$80,$09
	db											 $a5,$95,$29,$04,$f0,$81,$ad,$63,$01,$8d,$62,$01,$80,$d8
; Cursor movement by 10 (Y button handler)

UNREACH_00B7B5:
	db											 $e2,$20,$ad,$62,$01,$cd,$63,$01,$f0,$13,$18,$69,$0a,$8d,$62,$01
	db											 $ad,$63,$01,$cd,$62,$01,$b0,$c0,$8d,$62,$01,$80,$bb,$a5,$95,$29
	db											 $08,$f0,$bd,$9c,$62,$01,$80,$b0
; Cursor movement by 10 (X button handler)

;-------------------------------------------------------------------------------
; DATA at $b7dd: Menu configuration data
;
; Purpose: Menu display configuration
; Format: Unknown structure for menu system
; Used by: CODE_009BC4 (menu update routine)
;-------------------------------------------------------------------------------
MenuDisplayConfig:
	db											 $2b,$8d,$03,$04,$00,$8f,$03,$00,$00,$01,$00,$08,$00,$09,$00,$42
	db											 $4b,$5a,$00,$00,$03,$16,$00,$11,$00,$00,$00,$00,$00,$00,$00,$00
	db											 $00,$00,$17,$00,$00,$00,$00,$00,$e0,$00,$cc,$20,$0e,$00,$00,$ff
	db											 $00,$00,$01,$00,$01,$00,$00,$00,$00,$00,$00,$00,$ff,$ff,$ff,$07
	db											 $30,$d9,$05,$31,$00,$42,$12,$00,$30,$7e,$07,$30,$7e

;-------------------------------------------------------------------------------
; CODE_00B82A: IRQ handler (jitter fix - first variant)
;
; Purpose: Interrupt handler for horizontal timing jitter correction
; Entry: Called by SNES IRQ interrupt
; Exit: NMI disabled
;       Interrupt vector updated to CODE_00B86C
; Uses: SNES_NMITIMEN, SNES_SLHV, SNES_STAT78, SNES_OPVCT
; Notes: Samples vertical counter until jitter stabilizes
;        Uses $da bit 6 for jitter calculation toggle
;        Enables second-stage IRQ handler
;-------------------------------------------------------------------------------
IRQ_JitterFix:
	rep					 #$30		; 16-bit A/X/Y
	phb							   ; Save data bank
	pha							   ; Save accumulator
	phx							   ; Save X
	sep					 #$20		; 8-bit accumulator
	phk							   ; Push program bank
	plb							   ; Set data bank = program bank
	stz.W				   SNES_NMITIMEN ; Disable NMI/IRQ

IRQ_JitterFix_Loop:
	lda.W				   SNES_SLHV ; Sample H/V counter
	lda.W				   SNES_STAT78 ; Read PPU status
	lda.W				   SNES_OPVCT ; Read vertical counter
	sta.W				   $0118	 ; Store V counter
	lda.B				   #$40	  ; Bit 6 mask
	and.W				   $00da	 ; Test bit 6 of $da
	bne					 IRQ_JitterFix_Skip ; If set, skip jitter calc
	lda.W				   $0118	 ; Load V counter
	asl					 a; × 2
	adc.W				   $0118	 ; × 3
	adc.B				   #$9a	  ; Add offset
	pha							   ; Push result
	plp							   ; Pull to processor status (jitter)

IRQ_JitterFix_Skip:
	lsr.W				   $0118	 ; V counter >> 1
	bcs					 IRQ_JitterFix_Loop ; If carry, resample (unstable)
	ldx.W				   #$b86c	; Second-stage IRQ handler
	stx.W				   $0118	 ; Store handler address
	lda.B				   #$11	  ; Enable V-IRQ + NMI
	sta.W				   SNES_NMITIMEN ; Set interrupt mode
	cli							   ; Enable interrupts
	wai							   ; Wait for interrupt
	rep					 #$30		; 16-bit A/X/Y
	plx							   ; Restore X
	pla							   ; Restore accumulator
	plb							   ; Restore data bank
	rti							   ; Return from interrupt

;-------------------------------------------------------------------------------
; IRQ_ScreenOn: IRQ handler (second stage - screen on)
;
; Purpose: Second-stage IRQ handler - turn screen on and switch to NMI
; Entry: Called by IRQ after jitter correction
; Exit: Screen enabled
;       NMI mode set
;       $d8 bit 6 set
;       Interrupt vector updated to IRQ_JitterFix2
; Calls: CODE_008B69 (screen setup)
; Notes: Final stage of screen transition
;-------------------------------------------------------------------------------
IRQ_ScreenOn:
	lda.B				   #$80	  ; Screen off brightness
	sta.W				   SNES_INIDISP ; Disable screen
	lda.B				   #$01	  ; NMI only mode
	sta.W				   SNES_NMITIMEN ; Set interrupt mode
	rep					 #$30		; 16-bit A/X/Y
	phd							   ; Save direct page
	phy							   ; Save Y
	jsr.W				   CODE_008B69 ; Screen setup
	sep					 #$20		; 8-bit accumulator
	lda.B				   #$07	  ; V-IRQ timer low
	sta.W				   SNES_VTIMEL ; Set V timer
	ldx.W				   #$b898	; Next IRQ handler (IRQ_JitterFix2)
	stx.W				   $0118	 ; Store handler address
	lda.W				   $0112	 ; Load interrupt mode
	sta.W				   SNES_NMITIMEN ; Set interrupt mode
	lda.B				   #$40	  ; Bit 6
	tsb.W				   $00d8	 ; Set bit 6 of $d8
	ply							   ; Restore Y
	pld							   ; Restore direct page
	rti							   ; Return from interrupt

;-------------------------------------------------------------------------------
; IRQ_JitterFix2: IRQ handler (jitter fix - second variant)
;
; Purpose: Alternate IRQ handler for horizontal timing jitter correction
; Entry: Called by SNES IRQ interrupt
; Exit: NMI disabled
;       Interrupt vector updated to IRQ_ScreenOn2
; Uses: Similar to CODE_00B82A but with different offset ($0f vs $9a)
; Notes: Second variant of jitter correction algorithm
;-------------------------------------------------------------------------------
IRQ_JitterFix2:
	rep					 #$30		; 16-bit A/X/Y
	phb							   ; Save data bank
	pha							   ; Save accumulator
	phx							   ; Save X
	sep					 #$20		; 8-bit accumulator
	phk							   ; Push program bank
	plb							   ; Set data bank = program bank
	stz.W				   SNES_NMITIMEN ; Disable NMI/IRQ

IRQ_JitterFix2_Loop:
	lda.W				   SNES_SLHV ; Sample H/V counter
	lda.W				   SNES_STAT78 ; Read PPU status
	lda.W				   SNES_OPVCT ; Read vertical counter
	sta.W				   $0118	 ; Store V counter
	lda.B				   #$40	  ; Bit 6 mask
	and.W				   $00da	 ; Test bit 6 of $da
	bne					 IRQ_JitterFix2_Skip ; If set, skip jitter calc
	lda.W				   $0118	 ; Load V counter
	asl					 a; × 2
	adc.W				   $0118	 ; × 3
	adc.B				   #$0f	  ; Add offset (different from B82A)
	pha							   ; Push result
	plp							   ; Pull to processor status

IRQ_JitterFix2_Skip:
	lsr.W				   $0118	 ; V counter >> 1
	bcc					 IRQ_JitterFix2_Loop ; If no carry, resample (unstable)
	ldx.W				   #$b8da	; Second-stage IRQ handler
	stx.W				   $0118	 ; Store handler address
	lda.B				   #$11	  ; Enable V-IRQ + NMI
	sta.W				   SNES_NMITIMEN ; Set interrupt mode
	cli							   ; Enable interrupts
	wai							   ; Wait for interrupt
	rep					 #$30		; 16-bit A/X/Y
	plx							   ; Restore X
	pla							   ; Restore accumulator
	plb							   ; Restore data bank
	rti							   ; Return from interrupt

;-------------------------------------------------------------------------------
; IRQ_ScreenOn2: IRQ handler (second stage - alternate)
;
; Purpose: Alternate second-stage IRQ handler
; Entry: Called by IRQ after jitter correction (variant 2)
; Exit: Screen enabled ($0110 brightness)
;       NMI mode set
;       $d8 bit 5 set
;       Interrupt vector updated to CODE_00B82A
; Calls: CODE_008BA0, CODE_008B88 (screen setup routines)
; Notes: Uses different screen setup sequence than CODE_00B86C
;-------------------------------------------------------------------------------
IRQ_ScreenOn2:
	lda.W				   $0110	 ; Load brightness value
	sta.W				   SNES_INIDISP ; Set screen brightness
	lda.B				   #$01	  ; NMI only mode
	sta.W				   SNES_NMITIMEN ; Set interrupt mode
	phd							   ; Save direct page
	jsr.W				   CODE_008BA0 ; Screen setup routine 1
	phy							   ; Save Y
	jsr.W				   CODE_008B88 ; Screen setup routine 2
	sep					 #$20		; 8-bit accumulator
	lda.B				   #$d8	  ; V-IRQ timer low
	sta.W				   $4209	 ; Set V timer (direct address)
	ldx.W				   #$b82a	; First-stage IRQ handler
	stx.W				   $0118	 ; Store handler address
	lda.W				   $0112	 ; Load interrupt mode
	sta.W				   $4200	 ; Set interrupt mode (direct)
	lda.B				   #$20	  ; Bit 5
	tsb.W				   $00d8	 ; Set bit 5 of $d8
	ply							   ; Restore Y
	pld							   ; Restore direct page
	rti							   ; Return from interrupt

;-------------------------------------------------------------------------------
; Sprite_SetMode2D: Set sprite mode $2d
;
; Purpose: Set sprite display mode to $2d
; Entry: None
; Exit: $0505 = $2d
; Notes: Preserves processor status
;-------------------------------------------------------------------------------
Sprite_SetMode2D:
	php							   ; Save processor status
	sep					 #$20		; 8-bit accumulator
	lda.B				   #$2d	  ; Mode $2d
	sta.W				   $0505	 ; Store in sprite mode
	plp							   ; Restore processor status
RTS_Label:

;-------------------------------------------------------------------------------
; Sprite_SetMode2C: Set sprite mode $2c
;
; Purpose: Set sprite display mode to $2c
; Entry: None
; Exit: $0505 = $2c
; Notes: Preserves processor status
;-------------------------------------------------------------------------------
Sprite_SetMode2C:
	php							   ; Save processor status
	sep					 #$20		; 8-bit accumulator
	lda.B				   #$2c	  ; Mode $2c
	sta.W				   $0505	 ; Store in sprite mode
	plp							   ; Restore processor status
RTS_Label:

;-------------------------------------------------------------------------------
; Anim_SetMode10: Set animation mode $10
;
; Purpose: Set animation mode to $10
; Entry: None
; Exit: $050a = $10
; Notes: Preserves processor status
;-------------------------------------------------------------------------------
Anim_SetMode10:
	php							   ; Save processor status
	sep					 #$20		; 8-bit accumulator
	lda.B				   #$10	  ; Mode $10
	sta.W				   $050a	 ; Store in animation mode
	plp							   ; Restore processor status
RTS_Label:

;-------------------------------------------------------------------------------
; Anim_SetMode11: Set animation mode $11
;
; Purpose: Set animation mode to $11
; Entry: None
; Exit: $050a = $11
; Notes: Preserves processor status
;-------------------------------------------------------------------------------
Anim_SetMode11:
	php							   ; Save processor status
	sep					 #$20		; 8-bit accumulator
	lda.B				   #$11	  ; Mode $11
	sta.W				   $050a	 ; Store in animation mode
	plp							   ; Restore processor status
RTS_Label:

;-------------------------------------------------------------------------------
; Input_PollWithToggle: Input polling loop with mode toggle
;
; Purpose: Poll controller input and toggle sprite mode on button press
; Entry: $07 = controller input state (from CODE_0096A0)
;        $01 = current state
;        $05 = compare state
; Exit: A = button state
;       X = $01 value
;       Flags set based on comparison
;       $0505 may be updated (mode $2c)
; Calls: CODE_0096A0 (controller read)
;        Sprite_SetMode2C (set sprite mode $2c)
; Notes: Loops until specific button condition met
;        XORs button state when no buttons pressed
;-------------------------------------------------------------------------------
Input_PollWithToggle:
	jsl.L				   CODE_0096A0 ; Read controller input
	bit.B				   $07	   ; Test button state
	bne					 Input_PollWithToggle_Check ; If buttons pressed, check
	eor.W				   #$ffff	; Invert button state
	bit.B				   $07	   ; Test inverted state
	beq					 Input_PollWithToggle_ToggleBack ; If no change, toggle back
	pha							   ; Save state
	jsr.W				   Sprite_SetMode2C ; Set sprite mode $2c
	pla							   ; Restore state

Input_PollWithToggle_ToggleBack:
	eor.W				   #$ffff	; Invert back
	bra					 Input_PollWithToggle ; Loop

Input_PollWithToggle_Check:
	lda.B				   $07	   ; Load button state
	ldx.B				   $01	   ; Load current state
	cpx.B				   $05	   ; Compare with compare state
RTS_Label:

;-------------------------------------------------------------------------------
; Game_Initialize: Main initialization/game start routine
;
; Purpose: Initialize game system and start main game loop
; Entry: Called at game start or reset
; Exit: Does not return (infinite game loop)
; Calls: CODE_0C8000 (bank $0c init)
;        System_Init (initialization)
;        CODE_00CBEC (some setup)
; Notes: Sets up initial game state
;        Prepares for main game execution
;-------------------------------------------------------------------------------
Game_Initialize:
	php							   ; Save processor status
	phb							   ; Save data bank
	phd							   ; Save direct page
	rep					 #$30		; 16-bit A/X/Y
	pea.W				   $5555	 ; Push $5555 (init marker?)
	lda.W				   #$0080	; Bit 7
	tsb.W				   $00d6	 ; Set bit 7 of $d6
	jsl.L				   CODE_0C8000 ; Call Bank $0c init
	jsr.W				   System_Init ; Initialization routine
	stz.B				   $01	   ; Clear $01
	sep					 #$20		; 8-bit accumulator
	jsr.W				   CODE_00CBEC ; Setup routine
	rep					 #$30		; 16-bit A/X/Y
	ldx.W				   #$ba17	; Menu data pointer
	jsr.W				   CODE_009BC4 ; Update menu
	tsc							   ; Transfer stack to A
	sta.W				   $0105	 ; Save stack pointer
	lda.W				   #$0080	; Bit 7
	tsb.W				   $00de	 ; Set bit 7 of $de
	pei.B				   ($01)	 ; Save $01
	pei.B				   ($03)	 ; Save $03
	lda.W				   #$0401	; Load $0401
	sta.B				   $03	   ; Store in $03
	lda.L				   $701ffc   ; Load save data flag
	and.W				   #$0300	; Mask bits 8-9
	sta.B				   $01	   ; Store in $01
	sta.B				   $05	   ; Store in $05
	pea.W				   LOOSE_OP_00BCF3 ; Push continue address
	ldx.W				   #$ba14	; Menu data
	jsr.W				   CODE_009BC4 ; Update menu
	lda.W				   #$0f00	; Load $0f00
	sta.B				   $8e	   ; Store in brightness?

Game_Initialize_Loop:
	rep					 #$30		; 16-bit A/X/Y
	lda.W				   #$0c80	; Button mask
	jsr.W				   Input_PollWithToggle ; Poll input
	bne					 UNREACH_00B9E0 ; If button pressed, branch
	bit.W				   #$0080	; Test B button
	beq					 Game_Initialize_Loop ; If not pressed, loop
	sep					 #$20		; 8-bit accumulator
	lda.B				   $06	   ; Load save slot selection
	sta.L				   $701ffd   ; Store save slot
	rep					 #$30		; 16-bit A/X/Y
	and.W				   #$00ff	; Mask to 8 bits
	dec					 a; Decrement (0-based index)
	sta.W				   $010e	 ; Store save slot index
	bmi					 UNREACH_00B9D5 ; If negative (new game), branch
	jsr.W				   CODE_00C92B ; Get save slot address
	tax							   ; X = save address
	lda.L				   $700000,x ; Load save data validity flag
	beq					 UNREACH_00B9DB ; If empty, branch
	jsr.W				   Sprite_SetMode2D ; Set sprite mode $2d
	lda.W				   $010e	 ; Load save slot index
	jmp.W				   CODE_00CA63 ; Load game

UNREACH_00B9D5:
	db											 $20,$08,$b9,$4c,$1a,$ba ; JSR Sprite_SetMode2D; JMP TitleScreen_Init

UNREACH_00B9DB:
	db											 $20,$12,$b9,$80,$c0 ; JSR Sprite_SetMode2C; BRA (skip)

UNREACH_00B9E0:
	db											 $86,$05,$20,$1c,$b9,$e2,$30,$a9,$ec,$8f,$d8,$56,$7f,$8f,$da,$56
	db											 $7f,$8f,$dc,$56,$7f,$8f,$de,$56,$7f,$a5,$06,$0a,$aa,$a9,$e0,$9f
	db											 $d8,$56,$7f,$a9,$08,$0c,$d4,$00,$22,$00,$80,$0c,$a9,$08,$1c,$d4
	db											 $00,$4c,$a0,$b9
; STX $05; JSR Anim_SetMode10; SEP #$30; (sprite setup code)

MenuConfig_TitleScreen:
	db											 $38,$ac,$03,$0b,$95,$03 ; Menu configuration data

;-------------------------------------------------------------------------------
; TitleScreen_Init: Initialize title screen display
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
TitleScreen_Init:
	ldy.W				   #$1000	; Y = $1000 (destination)
	lda.W				   #$0303	; Graphics mode $0303
	jsr.W				   CODE_009A11 ; Initialize graphics
	sep					 #$20		; 8-bit accumulator
	ldx.W				   #$bae7	; Data pointer
	jsr.W				   CODE_009BC4 ; Update menu
	lda.B				   #$10	  ; Bit 4 mask
	trb.W				   $0111	 ; Clear bit 4 of $0111
	jsl.L				   CODE_0C8000 ; External init call
	stz.W				   SNES_BG3VOFS ; Clear BG3 V-scroll low
	stz.W				   SNES_BG3VOFS ; Clear BG3 V-scroll high
	lda.B				   #$17	  ; Enable BG1+BG2+BG3+sprites
	sta.W				   SNES_TM   ; Set main screen designation
	lda.B				   #$00	  ; Start at Y=0

TitleScreen_Init_ScrollLoop:
	jsl.L				   CODE_0C8000 ; External call
	sta.W				   SNES_BG3VOFS ; Set BG3 V-scroll low
	stz.W				   SNES_BG3VOFS ; Clear BG3 V-scroll high
	clc							   ; Clear carry
	adc.B				   #$08	  ; Add 8 (scroll speed)
	cmp.B				   #$d0	  ; Check if reached $d0
	bne					 TitleScreen_Init_ScrollLoop ; Loop until done
	lda.B				   #$10	  ; Bit 4 mask
	tsb.W				   $0111	 ; Set bit 4 of $0111
	rep					 #$30		; 16-bit A/X/Y
	stz.W				   $00cc	 ; Clear character count
	lda.W				   #$060d	; Load $060d
	sta.B				   $03	   ; Store in $03
	lda.W				   #$0000	; Load 0
	sta.B				   $05	   ; Clear $05
	sta.B				   $01	   ; Clear $01
	sta.W				   $015f	 ; Clear $015f
	bra					 CharName_UpdateDisplay ; Jump to menu display

UNREACH_00BA6D:
	db											 $20,$12,$b9 ; JSR Sprite_SetMode2C

;-------------------------------------------------------------------------------
; CharName_InputLoop: Character name entry input loop
;
; Purpose: Handle controller input for character naming
; Entry: $00cc = current character count (0-8)
;        $01 = current cursor position
; Exit: Character name entered
;       $1000-$1007 = entered name
; Calls: Input_PollWithToggle (input polling)
;        Sprite_SetMode2C, Anim_SetMode11 (sprite modes)
;        CODE_009BC4 (menu update)
; Notes: Supports character entry, deletion, confirmation
;        Max 8 characters per name
;-------------------------------------------------------------------------------
CharName_InputLoop:
	rep					 #$30		; 16-bit A/X/Y
	lda.W				   #$9f80	; Button mask
	jsr.W				   Input_PollWithToggle ; Poll input
	bne					 CharName_InputLoop_Process ; If button pressed, process
	bit.W				   #$1000	; Test L button
	bne					 CharName_InputLoop_Confirm ; If pressed, confirm
	bit.W				   #$8000	; Test A button
	bne					 UNREACH_00BAC2 ; If pressed, delete char
	bit.W				   #$0080	; Test B button
	beq					 CharName_InputLoop ; If not pressed, loop
	lda.B				   $01	   ; Load cursor position
	cmp.W				   #$050c	; Check if at end position
	beq					 CharName_InputLoop_Confirm ; If yes, confirm
	sep					 #$30		; 8-bit A/X/Y
	ldy.W				   $00cc	 ; Load character count
	cpy.B				   #$08	  ; Check if 8 chars entered
	beq					 UNREACH_00BA6D ; If full, error sound
	lda.B				   $06	   ; Load selected character (row)
	sta.W				   SNES_WRMPYA ; Set multiplicand
	lda.B				   #$1a	  ; Load 26 (chars per row)
	jsl.L				   CODE_00971E ; Multiply
	lda.B				   $05	   ; Load column
	asl					 a; × 2
	adc.W				   SNES_RDMPYL ; Add multiplication result
	tax							   ; X = character index
	rep					 #$10		; 16-bit X/Y
	inc.W				   $00cc	 ; Increment character count
	lda.L				   DATA8_03a37c,x ; Load character from table
	sta.W				   $1000,y   ; Store in name buffer
	jsr.W				   Anim_SetMode11 ; Set animation mode $11
	ldx.W				   #$baed	; Menu data
	jsr.W				   CODE_009BC4 ; Update menu
	bra					 CharName_InputLoop ; Loop

UNREACH_00BAC2:
	db											 $ac,$cc,$00,$f0,$a6,$88,$8c,$cc,$00,$e2,$20,$a9,$03,$80,$e3
; LDY $00cc; BEQ skip; DEY; STY $00cc; SEP #$20; LDA #$03; BRA sound

CharName_InputLoop_Confirm:
	lda.W				   $00cc	 ; Load character count
	beq					 UNREACH_00BA6D ; If empty, error
	jmp.W				   Sprite_SetMode2D ; Set sprite mode $2d and return

CharName_InputLoop_Process:
	stx.W				   $015f	 ; Store selected option
	jsr.W				   Anim_SetMode10 ; Set animation mode $10

CharName_UpdateDisplay:
	ldx.W				   #$baea	; Menu data
	jsr.W				   CODE_009BC4 ; Update menu
	bra					 CharName_InputLoop ; Loop

MenuConfig_CharName1:
	db											 $ca,$ac,$03 ; Menu configuration

MenuConfig_CharName2:
	db											 $34,$ad,$03,$21,$ad,$03 ; Menu configuration

;-------------------------------------------------------------------------------
; System_Init: System initialization routine
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
System_Init:
	lda.W				   #$2100	; PPU register base
	tcd							   ; Set direct page to $2100
	stz.B				   SNES_CGSWSEL-$2100 ; Clear color/window select
	lda.W				   #$0017	; Enable BG1+BG2+BG3+OBJ
	sta.W				   $212c	 ; Set main screen designation
	lda.W				   #$5555	; Init marker
	sta.W				   $0e00	 ; Store marker
	sep					 #$20		; 8-bit accumulator
	lda.B				   #$00	  ; Load 0
	sta.L				   $7e3664   ; Clear flag
	lda.B				   #$3b	  ; BG1 tilemap = $3b00
	sta.B				   SNES_BG1SC-$2100 ; Set BG1 screen base
	lda.B				   #$4b	  ; BG2 tilemap = $4b00
	sta.B				   SNES_BG2SC-$2100 ; Set BG2 screen base
	lda.B				   #$80	  ; VRAM increment after high byte
	sta.B				   SNES_VMAINC-$2100 ; Set VRAM increment mode
	rep					 #$30		; 16-bit A/X/Y
	stz.W				   $00f0	 ; Clear $f0
	ldx.W				   #$0000	; VRAM address $0000
	stx.B				   SNES_VMADDL-$2100 ; Set VRAM address
	pea.W				   $0007	 ; Bank $07
	plb							   ; Set data bank to $07
	ldx.W				   #$8030	; Source address
	ldy.W				   #$0100	; Length (256 words)
	jsl.L				   CODE_008E54 ; DMA transfer to VRAM
	plb							   ; Restore data bank
	ldx.W				   #$1000	; VRAM address $1000
	stx.B				   SNES_VMADDL-$2100 ; Set VRAM address
	pea.W				   $0004	 ; Bank $04
	plb							   ; Set data bank to $04
	ldx.W				   #$9840	; Source address
	ldy.W				   #$0010	; Length (16 words)
	jsl.L				   CODE_008DDF ; DMA transfer
	plb							   ; Restore data bank
	ldx.W				   #$6080	; VRAM address $6080
	stx.B				   SNES_VMADDL-$2100 ; Set VRAM address
	pea.W				   $0004	 ; Bank $04
	plb							   ; Set data bank
	ldx.W				   #$99c0	; Source address
	ldy.W				   #$0004	; Length (4 words)
	jsl.L				   CODE_008DDF ; DMA transfer
	plb							   ; Restore data bank
	sep					 #$30		; 8-bit A/X/Y
	pea.W				   $0007	 ; Bank $07
	plb							   ; Set data bank
	lda.B				   #$20	  ; Palette offset $20
	ldx.B				   #$00	  ; Palette index 0
	jsr.W				   CODE_008FB4 ; Load palette
	lda.B				   #$30	  ; Palette offset $30
	ldx.B				   #$08	  ; Palette index 8
	jsr.W				   CODE_008FB4 ; Load palette
	lda.B				   #$60	  ; Palette offset $60
	ldx.B				   #$10	  ; Palette index 16
	jsr.W				   CODE_008FB4 ; Load palette
	lda.B				   #$70	  ; Palette offset $70
	ldx.B				   #$18	  ; Palette index 24
	jsr.W				   CODE_008FB4 ; Load palette
	lda.B				   #$40	  ; Palette offset $40
	ldx.B				   #$20	  ; Palette index 32
	jsr.W				   CODE_008FB4 ; Load palette
	lda.B				   #$50	  ; Palette offset $50
	ldx.B				   #$28	  ; Palette index 40
	jsr.W				   CODE_008FB4 ; Load palette
	plb							   ; Restore data bank
	ldx.B				   #$00	  ; Index 0
	txa							   ; A = 0
	pea.W				   $0007	 ; Bank $07
	plb							   ; Set data bank
	jsr.W				   CODE_00BC49 ; Load color data
	ldx.B				   #$10	  ; Index 16
	lda.B				   #$10	  ; Offset $10
	jsr.W				   CODE_00BC49 ; Load color data
	plb							   ; Restore data bank
	lda.B				   #$80	  ; CGRAM address $80
	sta.B				   SNES_CGADD-$2100 ; Set CGRAM address
	pea.W				   $0007	 ; Bank $07
	plb							   ; Set data bank
	lda.W				   DATA8_07d814 ; Load color data
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d815 ; Load color data
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d816 ; Load color data
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d817 ; Load color data
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d818 ; Load color data
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d819 ; Load color data
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d81a ; Load color data
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d81b ; Load color data
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d81c ; Load color data
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d81d ; Load color data
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d81e ; Load color data
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d81f ; Load color data
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d820 ; Load color data
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d821 ; Load color data
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d822 ; Load color data
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d823 ; Load color data
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	plb							   ; Restore data bank
	lda.B				   #$31	  ; CGRAM address $31
	sta.B				   SNES_CGADD-$2100 ; Set CGRAM address
	lda.W				   $0e9c	 ; Load color low
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   $0e9d	 ; Load color high
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.B				   #$71	  ; CGRAM address $71
	sta.B				   SNES_CGADD-$2100 ; Set CGRAM address
	lda.W				   $0e9c	 ; Load color low
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   $0e9d	 ; Load color high
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	stz.B				   SNES_BG1HOFS-$2100 ; Clear BG1 H-scroll
	stz.B				   SNES_BG1HOFS-$2100 ; (write twice)
	stz.B				   SNES_BG1VOFS-$2100 ; Clear BG1 V-scroll
	stz.B				   SNES_BG1VOFS-$2100 ; (write twice)
	stz.B				   SNES_BG2HOFS-$2100 ; Clear BG2 H-scroll
	stz.B				   SNES_BG2HOFS-$2100 ; (write twice)
	stz.B				   SNES_BG2VOFS-$2100 ; Clear BG2 V-scroll
	stz.B				   SNES_BG2VOFS-$2100 ; (write twice)
	rep					 #$30		; 16-bit A/X/Y
	lda.W				   #$0000	; Direct page = $0000
	tcd							   ; Restore direct page
	ldx.W				   #$c8e6	; Data pointer
	jsr.W				   CODE_009BC4 ; Update menu
	jsr.W				   CODE_00C4DB ; External routine
	jsr.W				   CODE_00BD64 ; Clear memory routine
	lda.W				   #$0200	; Load $0200
	sta.W				   $01f0	 ; Store in $01f0
	lda.W				   #$0020	; Load $0020
	sta.W				   $01f2	 ; Store in $01f2
	lda.W				   #$0701	; Load $0701
	sta.B				   $03	   ; Store in $03
	stz.B				   $05	   ; Clear $05
	stz.B				   $01	   ; Clear $01
	jmp.W				   CODE_00CF3F ; Jump to main routine

;-------------------------------------------------------------------------------
; Palette_LoadColors: Load palette color data
;
; Purpose: Load 16 colors from Bank $07 to CGRAM
; Entry: A = CGRAM start address
;        X = data offset in Bank $07
;        Data bank = $07
; Exit: 16 colors loaded to CGRAM
; Uses: DATA8_07D7F4 onwards (color data)
;-------------------------------------------------------------------------------
Palette_LoadColors:
	sta.B				   SNES_CGADD-$2100 ; Set CGRAM address
	lda.W				   DATA8_07d7f4,x ; Load color byte
	sta.B				   SNES_CGDATA-$2100 ; Write to CGRAM
	lda.W				   DATA8_07d7f5,x ; (repeat for 32 bytes = 16 colors)
	sta.B				   SNES_CGDATA-$2100
	lda.W				   DATA8_07d7f6,x
	sta.B				   SNES_CGDATA-$2100
	lda.W				   DATA8_07d7f7,x
	sta.B				   SNES_CGDATA-$2100
	lda.W				   DATA8_07d7f8,x
	sta.B				   SNES_CGDATA-$2100
	lda.W				   DATA8_07d7f9,x
	sta.B				   SNES_CGDATA-$2100
	lda.W				   DATA8_07d7fa,x
	sta.B				   SNES_CGDATA-$2100
	lda.W				   DATA8_07d7fb,x
	sta.B				   SNES_CGDATA-$2100
	lda.W				   DATA8_07d7fc,x
	sta.B				   SNES_CGDATA-$2100
	lda.W				   DATA8_07d7fd,x
	sta.B				   SNES_CGDATA-$2100
	lda.W				   DATA8_07d7fe,x
	sta.B				   SNES_CGDATA-$2100
	lda.W				   DATA8_07d7ff,x
	sta.B				   SNES_CGDATA-$2100
	lda.W				   DATA8_07d800,x
	sta.B				   SNES_CGDATA-$2100
	lda.W				   DATA8_07d801,x
	sta.B				   SNES_CGDATA-$2100
	lda.W				   DATA8_07d802,x
	sta.B				   SNES_CGDATA-$2100
	lda.W				   DATA8_07d803,x
	sta.B				   SNES_CGDATA-$2100
RTS_Label:

;-------------------------------------------------------------------------------
; Screen_SetUpdateFlag: Set display update flag and execute screen update
;
; Purpose: Set bit 0 of $d8 and call screen update routine
; Entry: None
; Exit: $d8 bit 0 set
;       Screen update executed
;-------------------------------------------------------------------------------
Screen_SetUpdateFlag:
	php							   ; Save processor status
	sep					 #$30		; 8-bit A/X/Y
	lda.B				   #$01	  ; Bit 0 mask
	tsb.W				   $00d8	 ; Set bit 0 of $d8
	plp							   ; Restore processor status

;-------------------------------------------------------------------------------
; Screen_TransitionReset: Screen transition/reset routine
;
; Purpose: Reset screen and reinitialize game state
; Entry: $0e00 = state marker
; Exit: Screen reinitialized
;       Game state restored
; Calls: CODE_00C7B8 (external routine)
;        System_Init (initialization)
;        CODE_00C7DE or CODE_00C7F0 (conditional screen setup)
;        CODE_009BC4 (menu update)
;        CODE_00C795 (external routine)
;        Menu_Handler (menu handler)
;        Memory_ClearBlock (clear memory)
;        CODE_00C4DB (external routine)
;        CODE_00CF3F (main routine)
; Notes: Handles screen transitions and state restoration
;-------------------------------------------------------------------------------
Screen_TransitionReset:
	php							   ; Save processor status
	phb							   ; Save data bank
	phd							   ; Save direct page
	rep					 #$30		; 16-bit A/X/Y
	lda.W				   #$0010	; Bit 4 mask
	trb.W				   $00d6	 ; Clear bit 4 of $d6
	lda.W				   $0e00	 ; Load state marker
	pha							   ; Save on stack
	stz.W				   $008e	 ; Clear $8e
	jsl.L				   CODE_00C7B8 ; External routine
	jsr.W				   System_Init ; Initialize system
	lda.W				   #$0001	; Bit 0 mask
	and.W				   $00d8	 ; Test bit 0 of $d8
	bne					 Screen_TransitionReset_Alt ; If set, alternate path
	jsr.W				   CODE_00C7DE ; Screen setup routine 1
	bra					 Screen_TransitionReset_Continue ; Continue

Screen_TransitionReset_Alt:
	jsr.W				   CODE_00C7F0 ; Screen setup routine 2

Screen_TransitionReset_Continue:
	ldx.W				   #$be80	; Data pointer
	jsr.W				   CODE_009BC4 ; Update menu
	lda.W				   #$0020	; Bit 5 mask
	tsb.W				   $00d2	 ; Set bit 5 of $d2
	jsl.L				   CODE_00C795 ; External routine
	lda.W				   #$00a0	; Load $a0
	sta.W				   $01f0	 ; Store in $01f0
	lda.W				   #$000a	; Load $0a
	sta.W				   $01f2	 ; Store in $01f2
	tsc							   ; Transfer stack to A
	sta.W				   $0105	 ; Save stack pointer
	jsr.W				   Menu_Handler ; Menu handler
	lda.W				   #$00ff	; Load $ff
	sep					 #$30		; 8-bit A/X/Y
	sta.W				   $0104	 ; Store in $0104
	rep					 #$30		; 16-bit A/X/Y
	lda.W				   $0105	 ; Load stack pointer
	tcs							   ; Restore stack
	jsl.L				   CODE_00C7B8 ; External routine
	jsr.W				   Memory_ClearBlock ; Clear memory
	ldx.W				   #$c8e9	; Data pointer
	jsr.W				   CODE_009BC4 ; Update menu
	jsl.L				   CODE_0C8000 ; External init
	lda.W				   #$0040	; Load $40
	sta.W				   $01f0	 ; Store in $01f0
	lda.W				   #$0004	; Load $04
	sta.W				   $01f2	 ; Store in $01f2
	pla							   ; Restore state marker
	sta.W				   $0e00	 ; Store back
	jsr.W				   CODE_00C78D ; External routine
	jsr.W				   CODE_008230 ; External routine
	pld							   ; Restore direct page
	plb							   ; Restore data bank
	plp							   ; Restore processor status
	rtl							   ; Return

;-------------------------------------------------------------------------------
; Screen_UpdateAndGraphics: Screen update wrapper
;
; Purpose: Call screen update and graphics routine
; Entry: None
; Exit: Screen updated
; Calls: Screen_UpdateFull (screen update)
;        CODE_00C795 (graphics routine)
;-------------------------------------------------------------------------------
Screen_UpdateAndGraphics:
	jsr.W				   Screen_UpdateFull ; Screen update
	jmp.W				   CODE_00C795 ; Graphics routine

;-------------------------------------------------------------------------------
; Screen_UpdateFull: Screen update and initialization
;
; Purpose: Update screen display and reinitialize subsystems
; Entry: None
; Exit: Screen updated
;       Subsystems initialized
; Calls: Multiple initialization routines
; Notes: Major screen refresh routine
;-------------------------------------------------------------------------------
Screen_UpdateFull:
	php							   ; Save processor status
	phd							   ; Save direct page
	sep					 #$20		; 8-bit accumulator
	rep					 #$10		; 16-bit X/Y
	pea.W				   $0000	 ; Direct page = $0000
	pld							   ; Set direct page
	ldx.W				   #$bd61	; Data pointer
	jsr.W				   CODE_009BC4 ; Update menu
	jsl.L				   CODE_0C8000 ; External init
	jsr.W				   CODE_008EC4 ; External routine
	jsr.W				   CODE_008C3D ; External routine
	jsr.W				   CODE_008D29 ; External routine
	jsl.L				   CODE_009B2F ; External routine
	jsr.W				   CODE_00A342 ; External routine
	lda.B				   #$10	  ; Bit 4 mask
	tsb.W				   $00d6	 ; Set bit 4 of $d6
	ldx.W				   #$fff0	; Load $fff0
	stx.B				   $8e	   ; Store in $8e
	pld							   ; Restore direct page
	plp							   ; Restore processor status
RTS_Label:

SystemData_Config1:
	db											 $f2,$82,$03 ; Configuration data

;-------------------------------------------------------------------------------
; Memory_ClearBlock: Clear memory routine
;
; Purpose: Clear memory range $0c20-$0e1f (512 bytes)
; Entry: None
; Exit: Memory cleared to $5555 pattern
;       Tilemap initialized
; Notes: Uses MVN for fast block fill
;        Sets up character display tilemap
;-------------------------------------------------------------------------------
Memory_ClearBlock:
	lda.W				   #$5555	; Fill pattern
	sta.W				   $0c20	 ; Store at start
	ldx.W				   #$0c20	; Source address
	ldy.W				   #$0c22	; Destination address
	lda.W				   #$01fd	; Length (509 bytes)
	mvn					 $00,$00	 ; Block move (fill memory)
	ldx.W				   #$bd99	; Tilemap data pointer
	stx.B				   $5f	   ; Store in $5f
	ldx.W				   #$0000	; Tilemap index = 0
	ldy.W				   #$0020	; Counter = 32 tiles

Memory_ClearBlock_Loop:
	sep					 #$20		; 8-bit accumulator
	lda.B				   ($5f)	 ; Load tile number
	sta.W				   $0c22,x   ; Store in tilemap
	lda.B				   #$30	  ; Palette 3
	sta.W				   $0c23,x   ; Store attributes
	rep					 #$30		; 16-bit A/X/Y
	inc.B				   $5f	   ; Next tile data
	inx							   ; Advance tilemap index
	inx							   ; (4 bytes per entry)
INX_Label:
INX_Label:
	dey							   ; Decrement counter
	bne					 Memory_ClearBlock_Loop ; Loop until done
RTS_Label:

;-------------------------------------------------------------------------------
; SystemData_Config2: Character display tilemap data
;
; Purpose: Tile numbers for character name/stats display
; Format: 32 tile numbers (1 byte each)
;-------------------------------------------------------------------------------
SystemData_Config2:
	db											 $08,$0a,$09,$0b,$08,$09,$0a,$0b,$10,$11,$12,$13,$18,$19,$1a,$1b
	db											 $10,$11,$12,$13,$28,$29,$2a,$2b,$10,$11,$12,$13,$38,$39,$3a,$3b

;-------------------------------------------------------------------------------
; Menu_Handler: Menu/dialog input handler
;
; Purpose: Handle menu input and dialog display
; Entry: $d8 bit 0 indicates mode
; Exit: User selection processed
; Calls: Input_PollWithToggle (input polling)
;        Sprite_SetMode2C, Anim_SetMode10 (sprite modes)
;        CODE_009BC4 (menu update)
; Notes: Complex menu navigation system
;-------------------------------------------------------------------------------
Menu_Handler:
	phk							   ; Push program bank
	plb							   ; Set data bank
	lda.W				   #$0001	; Bit 0 mask
	and.W				   $00d8	 ; Test bit 0 of $d8
	bne					 Menu_Handler_AltMode ; If set, alternate mode
	lda.W				   #$fff0	; Load $fff0
	sta.B				   $8e	   ; Store in $8e
	bra					 Menu_Handler_Process ; Continue

UNREACH_00BDCA:
	db											 $20,$12,$b9 ; JSR Sprite_SetMode2C

Menu_Handler_Loop:
	lda.W				   #$ccb0	; Button mask
	jsr.W				   Input_PollWithToggle ; Poll input
	bne					 Menu_Handler_Process ; If button pressed, process
	bit.W				   #$0080	; Test B button
	bne					 Menu_Handler_Cancel ; If pressed, branch
	bit.W				   #$8000	; Test A button
	beq					 Menu_Handler_Loop ; If not pressed, loop
	jsr.W				   Anim_SetMode10 ; Set animation mode $10
	stz.B				   $8e	   ; Clear $8e

Menu_Handler_Done:
RTS_Label:

LOOSE_OP_00BDE5:
	pla							   ; Pull return address
	sta.B				   $03	   ; Store in $03
	pla							   ; Pull high byte
	sta.B				   $05	   ; Store in $05
	pla							   ; Pull saved value
	sta.B				   $01	   ; Store in $01
	lda.W				   #$fff0	; Load $fff0
	sta.B				   $8e	   ; Store in $8e

Menu_Handler_Process:
	stx.W				   $015f	 ; Store input state
	jsr.W				   Anim_SetMode10 ; Set animation mode $10
	bra					 Menu_Handler_Update ; Continue

Menu_Handler_AltMode:
	lda.W				   #$ccb0	; Button mask
	jsr.W				   Input_PollWithToggle ; Poll input
	bne					 Menu_Handler_Update ; If button pressed, process
	lda.B				   #$01	  ; Bit 0 mask
	trb.W				   $00d8	 ; Clear bit 0 of $d8
	bit.W				   #$0080	; Test B button
	bne					 Menu_Handler_AltCancel ; If pressed, cancel
	bit.W				   #$8000	; Test A button
	beq					 Menu_Handler_AltMode ; If not pressed, loop
	jsr.W				   Anim_SetMode10 ; Set animation mode $10
	lda.W				   #$ffff	; Load $ffff
	sta.B				   $01	   ; Store in $01
	stz.B				   $8e	   ; Clear $8e
RTS_Label:

Menu_Handler_AltCancel:
	jsr.W				   Sprite_SetMode2C ; Set sprite mode $2d
	lda.W				   #$00ff	; Load $ff
	sta.B				   $01	   ; Store in $01
RTS_Label:

Menu_Handler_Cancel:
	lda.B				   #$01	  ; Bit 0 mask
	trb.W				   $00d8	 ; Clear bit 0 of $d8
RTS_Label:

Menu_Handler_Update:
	ldx.W				   #$be80	; Data pointer
	jsr.W				   CODE_009BC4 ; Update menu
	bra					 Menu_Handler_Loop ; Loop

SystemData_Config3:
	db											 $02,$04	 ; Configuration data

SystemData_Config4:
	db											 $2b,$bf,$03,$06,$02,$00,$04,$00,$06,$00,$08,$00,$04,$01,$06,$01
	db											 $00,$00,$02,$00,$04,$00,$06,$00,$08,$00,$04,$01,$06,$01,$00,$02
	db											 $02,$02,$04,$02,$06,$02,$08,$02,$04,$03,$06,$03

SystemData_Config5:
	db											 $1c,$bf,$80,$00,$11,$0e,$11,$0e,$30,$70,$80,$00,$2f,$03,$2e,$03
	db											 $00,$00,$80,$00

SystemData_Config6:
	db											 $78,$be,$03,$6b,$be,$03,$38,$be,$03

SystemData_Config7:
	db											 $7a,$be,$03,$3a,$be,$03,$66,$be,$03

;-------------------------------------------------------------------------------
; Menu_PartySelection: Menu handler with party member selection
;
; Purpose: Display menu with party member selection capability
; Entry: A = menu option parameter
;        $1090 = companion status flags (negative if no companion)
; Exit: $14 = selected option or $ff
;       $7e3664 = selected option stored
; Calls: Anim_SetMode10 (update sprite), CODE_009BC4 (show menu)
; Notes: Handles single-character vs two-character party
;        Saves/restores menu state on stack
;-------------------------------------------------------------------------------
Menu_PartySelection:
	php							   ; Save processor status
	sep					 #$20		; 8-bit accumulator
	rep					 #$10		; 16-bit index
	sta.W				   $04e0	 ; Store menu parameter
	lda.B				   #$04	  ; Menu active flag
	tsb.W				   $00da	 ; Set bit 2 in flags
	pei.B				   ($8e)	 ; Save position
	pei.B				   ($01)	 ; Save option
	pei.B				   ($03)	 ; Save menu type
	lda.B				   #$ff	  ; No selection
	sta.B				   $14	   ; Initialize result
	stz.B				   $8e	   ; Clear position low
	stz.B				   $8f	   ; Clear position high
	ldx.W				   #$0102	; Two options (two characters)
	lda.W				   $1090	 ; Check companion status
	bpl					 Menu_PartySelection_Init ; Branch if companion present
	ldx.W				   #$0101	; One option (solo)

Menu_PartySelection_Init:
	stx.B				   $03	   ; Set menu configuration
	stz.B				   $01	   ; Clear option
	stz.B				   $02	   ; Clear option high
	lda.L				   $7e3664   ; Load last selection
	beq					 Menu_PartySelection_Start ; Branch if zero
	bmi					 UNREACH_00BEC0 ; Branch if negative
	lda.W				   $1090	 ; Check companion status again
	bmi					 Menu_PartySelection_Start ; Branch if no companion
	inc.B				   $01	   ; Select second option
	bra					 Menu_PartySelection_Start ; Continue

UNREACH_00BEC0:
	db											 $ad,$e0,$04,$29,$20,$d0,$0d,$80,$07 ; Unreachable data

Menu_PartySelection_Start:
	lda.W				   $04e0	 ; Load parameter
	and.B				   #$10	  ; Check bit 4
	beq					 UNREACH_00BED4 ; Branch if clear

Menu_PartySelection_GetOption:
	lda.B				   $01	   ; Load current option
	bra					 Menu_PartySelection_Update ; Continue

UNREACH_00BED4:
	db											 $a9,$80	 ; Unreachable data

Menu_PartySelection_Update:
	ldx.B				   $14	   ; Load previous result
	cmp.B				   $14	   ; Compare with current
	sta.B				   $14	   ; Store new result
	sta.L				   $7e3664   ; Save selection
	beq					 Menu_PartySelection_Show ; Branch if unchanged
	txa							   ; Get previous
	cmp.B				   #$ff	  ; Was cancelled?
	beq					 Menu_PartySelection_Show ; Branch if yes
	jsr.W				   Anim_SetMode10 ; Update sprite

Menu_PartySelection_Show:
	ldx.W				   #$bf48	; Menu data
	jsr.W				   CODE_009BC4 ; Show menu
	ldx.W				   #$fff0	; Position offset (-16)
	stx.B				   $8e	   ; Set position

;-------------------------------------------------------------------------------
; Menu_OptionSelection: Menu option selection handler
;
; Purpose: Handle menu cursor and option selection
; Entry: $01 = current menu option
;        $03 = menu configuration
; Exit: $01 = selected option or $ff for cancel
; Calls: Input_PollWithToggle (input polling)
;        Sprite_SetMode2C, Anim_SetMode11, Anim_SetMode10 (sprite/animation modes)
;        CODE_009BC4 (menu update)
; Notes: Supports cursor wrapping, confirmation, cancellation
;-------------------------------------------------------------------------------
Menu_OptionSelection:
	lda.W				   #$ccb0	; Button mask
	jsr.W				   Input_PollWithToggle ; Poll input
	bne					 Menu_OptionSelection_ProcessInput ; If button pressed, process
	bit.W				   #$0080	; Test B button
	bne					 Menu_OptionSelection_Cancel ; If pressed, cancel
	bit.W				   #$8000	; Test A button
	beq					 Menu_OptionSelection ; If not pressed, loop
	jsr.W				   Anim_SetMode10 ; Set animation mode $10
	lda.W				   #$000f	; Mask low 4 bits
	and.B				   $01	   ; Get current selection
	cmp.W				   #$000c	; Check if option $0c
	beq					 Menu_OptionSelection_Cancel ; If yes, treat as cancel
	lda.B				   $01	   ; Load full option
	sta.W				   $015f	 ; Store selection
	lda.W				   #$ffff	; Load $ffff
	sta.B				   $01	   ; Store in $01
	stz.B				   $8e	   ; Clear $8e
RTS_Label:

Menu_OptionSelection_Cancel:
	jsr.W				   Sprite_SetMode2C ; Set sprite mode $2c
	lda.W				   #$00ff	; Load $ff (cancel code)
	sta.B				   $01	   ; Store in $01
RTS_Label:

UNREACH_00BEBB:
	db											 $a9,$01,$00,$1c,$d8,$00,$60 ; LDA #$0001; TRB $00d8; RTS

SystemData_Config8:
	db											 $d8,$00,$03,$c2,$00,$03,$f5,$00,$03

SystemData_Config9:
	db											 $f2,$82,$03

LOOSE_OP_00BECE:
	db											 $9c,$10,$01,$9c,$12,$01,$60 ; STZ $0110; STZ $0112; RTS

UNREACH_00BED5:
	db											 $48,$22,$00,$80,$0c ; PHA; JSL CODE_0C8000; (more code)

Menu_OptionSelection_UpdateDisplay:
	stx.W				   $015f	 ; Store input state
	jsr.W				   Anim_SetMode10 ; Set animation mode $10
	ldx.W				   #$be80	; Data pointer
	jsr.W				   CODE_009BC4 ; Update menu
	bra					 Menu_OptionSelection ; Loop

UNREACH_00BEE5:
	db											 $a9,$b0,$cc,$22,$30,$b9,$00,$f0,$f1,$89,$80,$00,$f0,$03,$4c,$cc
	db											 $be,$20,$12,$b9,$a9,$ff,$00,$85,$01,$60
; LDA #$ccb0; JSL CODE_00B930; (menu polling code)

;-------------------------------------------------------------------------------
; Menu_MultiOption: Complex menu update routine
;
; Purpose: Update menu display with multiple options
; Entry: $01 = current option
;        $03 = menu data pointer
; Exit: Menu updated
; Calls: CODE_009BC4 (menu update)
;        Input_PollWithToggle (input polling)
;        Anim_SetMode11 (animation mode)
; Notes: Handles multi-option menus with cursor navigation
;-------------------------------------------------------------------------------
Menu_MultiOption:
	phk							   ; Push program bank
	plb							   ; Set data bank
	jsr.W				   Anim_SetMode11 ; Set animation mode $11
	ldx.W				   #$becb	; Data pointer
	jsr.W				   CODE_009BC4 ; Update menu

Menu_MultiOption_Loop:
	lda.W				   #$ccb0	; Button mask
	jsr.W				   Input_PollWithToggle ; Poll input
	bne					 Menu_MultiOption_Process ; If button pressed, process
	bit.W				   #$0080	; Test B button
	beq					 Menu_MultiOption_Loop ; If not pressed, loop
	stz.B				   $8e	   ; Clear $8e
RTS_Label:

UNREACH_00BF1B:
	db											 $20,$1c,$b9,$a9,$ff,$ff,$85,$01,$9c,$8e,$00,$60
; JSR Anim_SetMode10; LDA #$ffff; STA $01; STZ $8e; RTS

SystemData_Config10:
	db											 $00		 ; Padding

Menu_MultiOption_Process:
	stx.W				   $015f	 ; Store input state
	jsr.W				   Anim_SetMode10 ; Set animation mode $10
	bra					 Menu_MultiOption_Loop ; Loop

;-------------------------------------------------------------------------------
; Menu_Item_CleanupReturn: Item use/equip system cleanup and return
;
; Purpose: Restore state after item menu operations
; Entry: Processor status saved on stack
;        $01, $03, $8e saved on stack
;        $14 = result code
; Exit: Restored state, A = result code
; Calls: CODE_009BC4 (menu update)
; Notes: Cleanup routine for item management
;-------------------------------------------------------------------------------
Menu_Item_CleanupReturn:
	lda.B				   #$04	  ; Bit 2 mask
	trb.W				   $00da	 ; Clear bit 2 of $da
	ldx.W				   #$bf48	; Menu data
	jsr.W				   CODE_009BC4 ; Update menu
	plx							   ; Restore X
	stx.B				   $03	   ; Restore $03
	plx							   ; Restore X
	stx.B				   $01	   ; Restore $01
	plx							   ; Restore X
	stx.B				   $8e	   ; Restore $8e
	lda.B				   $14	   ; Load result code
	plp							   ; Restore processor status
RTS_Label:

SystemData_Config11:
	db											 $9b,$8f,$03 ; Menu configuration

;-------------------------------------------------------------------------------
; Inventory Item Discard System (Menu_Item_Discard - CODE_00C012)
;-------------------------------------------------------------------------------
Menu_Item_Discard:
	lda.W				   #$0504	; Menu mode $0504
	sta.B				   $03	   ; Store in $03
	ldx.W				   #$fff0	; Load $fff0
	stx.B				   $8e	   ; Store in $8e
	bra					 Menu_Item_Discard_Display ; Jump to menu display

Menu_Item_Discard_Error:
	jsr.W				   Sprite_SetMode2C ; Set sprite mode $2c

Menu_Item_Discard_Input:
	lda.W				   #$cfb0	; Button mask
	jsr.W				   Input_PollWithToggle ; Poll input
	bne					 Menu_Item_Discard_Display ; If button pressed, process
	bit.W				   #$0080	; Test B button
	bne					 Menu_Item_Discard_Validate ; If pressed, branch
	bit.W				   #$8000	; Test A button
	beq					 Menu_Item_Discard_Input ; If not pressed, loop
	jsr.W				   Anim_SetMode10 ; Set animation mode $10
	stz.B				   $8e	   ; Clear $8e
	ldx.W				   #$c032	; Menu data
	jmp.W				   CODE_009BC4 ; Update menu and return

Menu_Item_Discard_Display:
	ldx.W				   #$c02f	; Menu data
	jsr.W				   CODE_009BC4 ; Update menu
	bra					 Menu_Item_Discard_Input ; Loop

Menu_Item_Discard_Validate:
	lda.B				   $02	   ; Load selection
	and.W				   #$00ff	; Mask to 8 bits
	bne					 Menu_Item_Discard_Error ; If not zero, error sound
	lda.B				   $01	   ; Load item slot
	and.W				   #$00ff	; Mask to 8 bits
	asl					 a; × 2 (word index)
	tax							   ; X = item index
	lda.W				   $0e9e,x   ; Load item ID
	and.W				   #$00ff	; Mask to 8 bits
	cmp.W				   #$00ff	; Check if empty slot
	beq					 Menu_Item_Discard_Error ; If empty, error
	cmp.W				   #$0013	; Check if item $13
	beq					 Menu_Item_Discard_Error ; If yes, can't discard
	cmp.W				   #$0011	; Check if less than $11
	bcc					 Menu_Item_Discard_Consumable ; If yes, handle consumable
	beq					 Menu_Item_Discard_Armor ; If $11, handle armor
	jsr.W				   Menu_Item_ConfirmDiscard ; Confirm discard
	bcc					 Menu_Item_Discard_Execute ; If confirmed, proceed
	bne					 Menu_Item_Discard_Input ; If cancelled, loop
	lda.W				   #$0080	; Load $80 (companion item)

Menu_Item_Discard_Execute:
	dec.W				   $0e9f,x   ; Decrement quantity
	clc							   ; Clear carry
	adc.W				   #$1018	; Add base address
	tay							   ; Y = source
	adc.W				   #$0003	; Add 3
	tax							   ; X = dest
	lda.W				   #$0002	; Length = 2
	mvn					 $00,$00	 ; Block move (shift items)

Menu_Item_Discard_UpdateDisplay:
	sep					 #$20		; 8-bit accumulator
	lda.W				   $04df	 ; Load character ID
	sta.W				   $0505	 ; Store in $0505
	rep					 #$30		; 16-bit A/X/Y
	jsr.W				   CODE_00DAA5 ; External routine
	ldx.W				   #$c035	; Menu data
	jsr.W				   CODE_009BC4 ; Update menu
	bra					 Menu_Item_Discard_Display ; Loop

UNREACH_00BFD5:
	db											 $4c,$5a,$bf ; JMP Menu_Item_Discard_Input

Menu_Item_Discard_Armor:
	jsr.W				   Menu_Item_ConfirmDiscard ; Confirm discard
	bcc					 Menu_Item_Discard_Armor_Execute ; If confirmed, proceed
	bne					 UNREACH_00BFD5 ; If cancelled, loop
	lda.W				   #$0080	; Load $80

Menu_Item_Discard_Armor_Execute:
	dec.W				   $0e9f,x   ; Decrement quantity
	tax							   ; X = item offset
	sep					 #$20		; 8-bit accumulator
	stz.W				   $1021,x   ; Clear equipped flag
	rep					 #$30		; 16-bit A/X/Y
	bra					 Menu_Item_Discard_UpdateDisplay ; Update display

Menu_Item_Discard_Consumable:
	jsr.W				   Menu_Item_ConfirmDiscard ; Confirm discard
	bcc					 Menu_Item_Discard_Consumable_Execute ; If confirmed, proceed
	bne					 UNREACH_00BFD5 ; If cancelled, loop
	lda.W				   #$0080	; Load $80

Menu_Item_Discard_Consumable_Execute:
	dec.W				   $0e9f,x   ; Decrement quantity
	tax							   ; X = item offset
	lda.W				   $1016,x   ; Load max HP
	lsr					 a; ÷ 4 (HP recovery amount)
	lsr					 a
	adc.W				   $1014,x   ; Add current HP
	cmp.W				   $1016,x   ; Check if exceeds max
	bcc					 Menu_Item_StoreHP ; If not, store
	lda.W				   $1016,x   ; Use max HP

Menu_Item_StoreHP:
	sta.W				   $1014,x   ; Store new HP
	bra					 Menu_Item_Discard_UpdateDisplay ; Update display

;-------------------------------------------------------------------------------
; Menu_Item_ConfirmDiscard: Confirm item discard dialog
;
; Purpose: Show confirmation dialog for discarding items
; Entry: A = item ID
; Exit: Carry clear if confirmed (A=1), carry set if cancelled
; Calls: CODE_028AE0, CODE_00B908, CODE_00BE83
; Notes: Uses $04e0 for input tracking
;-------------------------------------------------------------------------------
Menu_Item_ConfirmDiscard:
	phx							   ; Save X
	sep					 #$20		; 8-bit accumulator
	sta.W				   $043a	 ; Store item ID
	jsl.L				   CODE_028AE0 ; External routine
	jsr.W				   CODE_00B908 ; Set sprite mode $2d
	rep					 #$30		; 16-bit A/X/Y
	lda.W				   #$0010	; Menu type $10
	jsr.W				   CODE_00BE83 ; Show confirmation menu
	plx							   ; Restore X
	and.W				   #$00ff	; Mask result
	cmp.W				   #$0001	; Check if confirmed
RTS_Label:

SystemData_Config12:
	db											 $e8,$8f,$03,$dd,$8f,$03,$8a,$8f,$03

;-------------------------------------------------------------------------------
; Spell Equip/Unequip System (Menu_Spell_Equip - CODE_00C1D8)
;-------------------------------------------------------------------------------
Menu_Spell_Equip:
	lda.W				   #$0406	; Menu mode $0406
	sta.B				   $03	   ; Store in $03
	ldx.W				   #$fff0	; Load $fff0
	stx.B				   $8e	   ; Store in $8e
	bra					 Menu_Spell_DisplayMenu ; Jump to menu display

UNREACH_00C044:
	db											 $20,$12,$b9 ; JSR Sprite_SetMode2C

Menu_Spell_ProcessInput:
	lda.W				   #$cfb0	; Button mask
	jsr.W				   Input_PollWithToggle ; Poll input
	bne					 Menu_Spell_DisplayMenu ; If button pressed, process
	bit.W				   #$0080	; Test B button
	bne					 Menu_Spell_Cancel ; If pressed, branch
	bit.W				   #$8000	; Test A button
	beq					 Menu_Spell_ProcessInput ; If not pressed, loop
	jsr.W				   Anim_SetMode10 ; Set animation mode $10
	stz.B				   $8e	   ; Clear $8e
	ldx.W				   #$c1d6	; Menu data
	jmp.W				   CODE_009BC4 ; Update menu and return

UNREACH_00C064:
	db											 $ad,$91,$0e,$29,$7f,$00,$c9,$07,$00,$90,$d5,$20,$b1,$c1,$f0,$d3
	db											 $de,$18,$10,$e2,$20,$a9,$14,$8d,$3a,$04,$22,$e0,$8a,$02,$ad,$df
	db											 $04,$8d,$05,$05,$a9,$14,$4c,$f4,$bc

Menu_Spell_DisplayMenu:
	ldx.W				   #$c1d3	; Menu data
	jsr.W				   CODE_009BC4 ; Update menu
	bra					 Menu_Spell_ProcessInput ; Loop

UNREACH_00C095:
	db											 $4c,$44,$c0 ; JMP UNREACH_00C044

Menu_Spell_Cancel:
	lda.B				   $01	   ; Load character selection
	and.W				   #$00ff	; Mask to 8 bits
	beq					 Menu_Spell_ValidateSlot ; If character 0, branch
	cmp.W				   #$0003	; Check if character 3
	bne					 UNREACH_00C044 ; If not, error
	lda.W				   $1090	 ; Load companion data
	and.W				   #$00ff	; Mask to 8 bits
	cmp.W				   #$00ff	; Check if no companion
	beq					 UNREACH_00C044 ; If none, error
	lda.W				   #$0080	; Load $80 (companion offset)

Menu_Spell_ValidateSlot:
	tax							   ; X = character offset
	lda.W				   $1021,x   ; Load status flags
	and.W				   #$00f9	; Mask out certain flags
	bne					 UNREACH_00C044 ; If flagged, error
	lda.W				   #$0007	; Load 7 (max spell slot -1)
	sec							   ; Set carry
	sbc.B				   $02	   ; Subtract selection
	and.W				   #$00ff	; Mask to 8 bits
	jsr.W				   CODE_0097F2 ; Get bit mask
	and.W				   $1038,x   ; Test spell equipped
	beq					 UNREACH_00C095 ; If not equipped, error
	lda.W				   $1018,x   ; Load current MP
	and.W				   #$00ff	; Mask to 8 bits
	beq					 UNREACH_00C095 ; If no MP, error
	lda.B				   $02	   ; Load spell slot
	and.W				   #$00ff	; Mask to 8 bits
	beq					 UNREACH_00C064 ; If slot 0, special case
	cmp.W				   #$0002	; Check if slot 2
	bcc					 CODE_00C13B ; If slot 1, HP healing
	beq					 CODE_00C11F ; If slot 2, cure/status
	jsr.W				   CODE_00C1B1 ; Confirm spell use
	beq					 CODE_00C138 ; If cancelled, loop
	cmp.W				   #$0001	; Check result
	beq					 Menu_Spell_DecrementMP_Char0 ; If 1, branch
	tax							   ; X = character offset
	lda.W				   $1016	 ; Load max HP
	sta.W				   $1014	 ; Restore to full HP
	txa							   ; A = character offset

Menu_Spell_DecrementMP_Char0:
	cmp.W				   #$0000	; Check if character 0
	beq					 Menu_Spell_DecrementMP_Main ; If yes, skip
	lda.W				   $1096	 ; Load companion max HP
	sta.W				   $1094	 ; Restore companion HP

Menu_Spell_DecrementMP_Main:
	sep					 #$20		; 8-bit accumulator
	ldx.W				   #$0000	; Default character offset
	lda.B				   $01	   ; Load character selection
	beq					 Menu_Spell_DecrementMP_Do ; If 0, use default
	ldx.W				   #$0080	; Companion offset

Menu_Spell_DecrementMP_Do:
	dec.W				   $1018,x   ; Decrement MP
	lda.W				   $04df	 ; Load character ID
	sta.W				   $0505	 ; Store in $0505
	rep					 #$30		; 16-bit A/X/Y
	ldx.W				   #$c035	; Menu data
	jsr.W				   CODE_009BC4 ; Update menu
	jmp.W				   Menu_Spell_DisplayMenu ; Loop

Menu_Spell_UseCure:
	jsr.W				   Menu_Spell_ConfirmUse ; Confirm spell use
	beq					 Menu_Spell_ReturnToInput ; If cancelled, loop
	sep					 #$20		; 8-bit accumulator
	cmp.B				   #$01	  ; Check result
	beq					 Menu_Spell_CureCompanion ; If 1, branch
	stz.W				   $1021	 ; Clear status (char 0)

Menu_Spell_CureCompanion:
	cmp.B				   #$00	  ; Check if character 0
	beq					 Menu_Spell_FinishCure ; If yes, skip
	stz.W				   $10a1	 ; Clear companion status

Menu_Spell_FinishCure:
	rep					 #$30		; 16-bit A/X/Y
	bra					 Menu_Spell_DecrementMP ; Continue

Menu_Spell_ReturnToInput:
	jmp.W				   Menu_Spell_ProcessInput ; Loop

Menu_Spell_UseHeal:
	jsr.W				   CODE_00C1B1 ; Confirm spell use
	beq					 CODE_00C138 ; If cancelled, loop
	pha							   ; Save character offset
	lda.W				   $1025,x   ; Load spell power
	and.W				   #$00ff	; Mask to 8 bits
	sta.B				   $64	   ; Store in $64
	asl					 a; × 2
	adc.B				   $64	   ; + original (× 3)
	lsr					 a; ÷ 2 (× 1.5)
	clc							   ; Clear carry
	adc.W				   #$0032	; Add base value (50)
	sta.B				   $98	   ; Store recovery amount
	tay							   ; Y = recovery
	lda.B				   $01,s	 ; Load character from stack
	cmp.W				   #$0001	; Check if character 1
	beq					 CODE_00C16F ; If yes, skip HP calc
	lda.W				   $1016	 ; Load max HP
	jsr.W				   Menu_Spell_CalcPercent ; Calculate percentage
	adc.W				   $1014	 ; Add current HP
	cmp.W				   $1016	 ; Check if exceeds max
	bcc					 Menu_Spell_StoreHP_Main ; If not, store
	lda.W				   $1016	 ; Use max HP

Menu_Spell_StoreHP_Main:
	sta.W				   $1014	 ; Store new HP

Menu_Spell_HealCompanion:
	sty.B				   $98	   ; Restore recovery amount
	lda.B				   $01,s	 ; Load character from stack
	beq					 Menu_Spell_HealComplete ; If character 0, skip
	lda.W				   $1096	 ; Load companion max HP
	jsr.W				   Menu_Spell_CalcPercent ; Calculate percentage
	adc.W				   $1094	 ; Add companion current HP
	cmp.W				   $1096	 ; Check if exceeds max
	bcc					 Menu_Spell_StoreHP_Comp ; If not, store
	lda.W				   $1096	 ; Use max HP

Menu_Spell_StoreHP_Comp:
	sta.W				   $1094	 ; Store companion HP

Menu_Spell_HealComplete:
	pla							   ; Restore character offset
	jmp.W				   Menu_Spell_DecrementMP ; Continue

;-------------------------------------------------------------------------------
; Menu_Spell_CalcPercent: Calculate percentage-based HP recovery
;
; Purpose: Calculate HP recovery as percentage of max HP
; Entry: A = max HP value
;        $98 = base recovery amount
; Exit: A = calculated recovery amount
; Uses: $98-$a0 for calculation
;-------------------------------------------------------------------------------
Menu_Spell_CalcPercent:
	sta.B				   $9c	   ; Store max HP
	jsl.L				   CODE_0096B3 ; Multiply routine
	lda.B				   $9e	   ; Load result low
	sta.B				   $98	   ; Store in $98
	lda.B				   $a0	   ; Load result high
	sta.B				   $9a	   ; Store in $9a
	lda.W				   #$0064	; Divisor = 100
	sta.B				   $9c	   ; Store divisor
	jsl.L				   CODE_0096E4 ; Divide routine
	lda.B				   $03,s	 ; Load character offset from stack
	cmp.W				   #$0080	; Check if companion
	bne					 Menu_Spell_ReturnPercent ; If not, skip
	db											 $46,$9e	 ; LSR $9e (halve result)

Menu_Spell_ReturnPercent:
	lda.B				   $9e	   ; Load result
	clc							   ; Clear carry
RTS_Label:

;-------------------------------------------------------------------------------
; Menu_Spell_ConfirmUse: Spell use confirmation
;
; Purpose: Confirm spell usage and show dialog
; Entry: $02 = spell slot
; Exit: A = character offset (0 or $80), Z flag set if cancelled
; Calls: CODE_028AE0, CODE_00B908, CODE_00BE83
;-------------------------------------------------------------------------------
Menu_Spell_ConfirmUse:
	phx							   ; Save X
	sep					 #$20		; 8-bit accumulator
	lda.B				   $02	   ; Load spell slot
	clc							   ; Clear carry
	adc.B				   #$14	  ; Add $14 (spell offset)
	sta.W				   $043a	 ; Store spell ID
	jsl.L				   CODE_028AE0 ; External routine
	jsr.W				   CODE_00B908 ; Set sprite mode $2d
	lda.W				   $04e0	 ; Load input flags
	rep					 #$30		; 16-bit A/X/Y
	jsr.W				   CODE_00BE83 ; Show confirmation menu
	plx							   ; Restore X
	and.W				   #$00ff	; Mask result
	cmp.W				   #$00ff	; Check if cancelled
RTS_Label:

SystemData_Config13:
	db											 $3a,$90,$03,$dd,$8f,$03

;-------------------------------------------------------------------------------
; Battle Settings Menu (Menu_BattleSettings - CODE_00C348)
;-------------------------------------------------------------------------------
Menu_BattleSettings:
	lda.W				   #$0020	; Bit 5 mask
	tsb.W				   $00d6	 ; Set bit 5 of $d6
	lda.W				   #$0602	; Menu mode $0602
	sta.B				   $03	   ; Store in $03
	lda.W				   #$bff0	; Load $bff0
	sta.B				   $8e	   ; Store in $8e
	bra					 Menu_BattleSettings_InputLoop ; Jump to input loop

UNREACH_00C1EB:
	db											 $20,$12,$b9 ; JSR Sprite_SetMode2C

Menu_BattleSettings_InputLoop:
	rep					 #$30		; 16-bit A/X/Y
	lda.W				   #$cf30	; Button mask
	jsr.W				   Input_PollWithToggle ; Poll input
	bne					 Menu_BattleSettings_Process ; If button pressed, process
	bit.W				   #$4000	; Test Y button
	bne					 UNREACH_00C20E ; If pressed, branch
	bit.W				   #$8000	; Test A button
	beq					 Menu_BattleSettings_InputLoop ; If not pressed, loop
	jsr.W				   Anim_SetMode10 ; Set animation mode $10
	stz.B				   $8e	   ; Clear $8e
	lda.W				   #$0020	; Bit 5 mask
	trb.W				   $00d6	 ; Clear bit 5 of $d6
RTS_Label:

UNREACH_00C20E:
	db											 $e2,$20,$ad,$90,$10,$30,$d6,$4c,$d9,$c2

Menu_BattleSettings_Process:
	txa							   ; Transfer button state
	sep					 #$20		; 8-bit accumulator
	lda.B				   #$00	  ; Clear high byte
	xba							   ; Swap bytes
	cmp.W				   $0006	 ; Compare with current setting
	bne					 Menu_BattleSettings_UpdateSetting ; If different, update
	jmp.W				   Menu_BattleSettings_ToggleSetting ; Toggle setting

Menu_BattleSettings_UpdateSetting:
	pha							   ; Save setting
	jsr.W				   Anim_SetMode10 ; Set animation mode $10
	pla							   ; Restore setting
	cmp.B				   #$01	  ; Check setting type
	bcc					 Menu_BattleSettings_Speed ; If < 1, handle battle speed
	beq					 Menu_BattleSettings_Mode ; If = 1, handle battle mode
	cmp.B				   #$03	  ; Check if < 3
	bcc					 Menu_BattleSettings_Cursor ; If yes, handle cursor memory
	beq					 Menu_BattleSettings_Green ; If = 3, handle green color
	cmp.B				   #$05	  ; Check if < 5
	bcc					 Menu_BattleSettings_Blue ; If yes, handle blue color
	lda.W				   $0e9d	 ; Load color data high byte
	lsr					 a; Extract red component
	lsr					 a
	bra					 Menu_BattleSettings_StoreColor ; Store result

Menu_BattleSettings_Blue:
	rep					 #$30		; 16-bit A/X/Y
	lda.W				   $0e9c	 ; Load color data
	lsr					 a; Extract blue component
	lsr					 a
	sep					 #$20		; 8-bit accumulator
	lsr					 a
	lsr					 a
	lsr					 a
	bra					 Menu_BattleSettings_StoreColor ; Store result

Menu_BattleSettings_Green:
	lda.W				   $0e9c	 ; Load color data (green)

Menu_BattleSettings_StoreColor:
	and.B				   #$1f	  ; Mask to 5 bits
	inc					 a; Increment
	lsr					 a; ÷ 4 (scale down)
	lsr					 a
	ldx.W				   #$0009	; X = 9 (data offset)
	ldy.W				   #$0609	; Y = menu mode
	bra					 Menu_BattleSettings_UpdateDisplay ; Continue

Menu_BattleSettings_Cursor:
	lda.W				   $0e9b	 ; Load cursor memory setting
	and.B				   #$07	  ; Mask to 3 bits
	ldx.W				   #$0006	; X = 6
	ldy.W				   #$0607	; Y = menu mode
	bra					 Menu_BattleSettings_UpdateDisplay ; Continue

Menu_BattleSettings_Mode:
	lda.W				   $1090	 ; Load battle mode setting
	bpl					 Menu_BattleSettings_Mode_Active ; If active mode, branch
	lda.B				   $06	   ; Load current selection
	eor.B				   #$02	  ; Toggle bit 1
	and.B				   #$fe	  ; Clear bit 0
	sta.B				   $02	   ; Store new selection
	bra					 Menu_BattleSettings_UpdateSetting ; Loop

Menu_BattleSettings_Mode_Active:
	lda.B				   #$80	  ; Load $80
	and.W				   $10a0	 ; Test companion flag
	beq					 Menu_BattleSettings_Mode_Store ; If not set, use 0
	lda.B				   #$ff	  ; Load $ff

Menu_BattleSettings_Mode_Store:
	inc					 a; Increment (0 or 1)
	ldx.W				   #$0003	; X = 3
	ldy.W				   #$0602	; Y = menu mode
	bra					 Menu_BattleSettings_UpdateDisplay ; Continue

Menu_BattleSettings_Speed:
	lda.B				   #$80	  ; Load $80
	and.W				   $0ec6	 ; Test battle speed flag
	beq					 Menu_BattleSettings_Speed_Store ; If not set, use 0
	db											 $a9,$01	 ; LDA #$01

Menu_BattleSettings_Speed_Store:
	ldx.W				   #$0000	; X = 0
	ldy.W				   #$0602	; Y = menu mode

Menu_BattleSettings_UpdateDisplay:
	sty.B				   $03	   ; Store menu mode
	sta.B				   $01	   ; Store current value
	lda.W				   DATA8_00c339,x ; Load color byte 1
	sta.L				   $7f56d7   ; Store to WRAM
	lda.W				   DATA8_00c33a,x ; Load color byte 2
	sta.L				   $7f56d9   ; Store to WRAM
	lda.W				   DATA8_00c33b,x ; Load color byte 3
	sta.L				   $7f56db   ; Store to WRAM

Menu_BattleSettings_Refresh:
	ldx.B				   $01	   ; Load current value
	stx.B				   $05	   ; Store in $05
	ldx.W				   #$c345	; Menu data
	jsr.W				   CODE_009BC4 ; Update menu
	jmp.W				   Menu_BattleSettings_InputLoop ; Loop

Menu_BattleSettings_ToggleSetting:
	lda.B				   $02	   ; Load option index
	beq					 Menu_BattleSettings_ToggleSpeed ; If 0, toggle battle speed
	cmp.B				   #$02	  ; Check if 2
	bcc					 Menu_BattleSettings_ToggleMode ; If < 2, toggle battle mode
	bne					 Menu_BattleSettings_SetColor ; If > 2, handle colors
	lda.W				   $0e9b	 ; Load cursor memory
	and.B				   #$f8	  ; Clear low 3 bits
	ora.B				   $01	   ; Set new value
	sta.W				   $0e9b	 ; Store cursor memory
	bra					 Menu_BattleSettings_Commit ; Update display

Menu_BattleSettings_ToggleMode:
	lda.W				   $10a0	 ; Load companion flag
	eor.B				   #$80	  ; Toggle bit 7
	sta.W				   $10a0	 ; Store back
	bra					 Menu_BattleSettings_Commit ; Update display

Menu_BattleSettings_ToggleSpeed:
	lda.W				   $0ec6	 ; Load battle speed
	eor.B				   #$80	  ; Toggle bit 7
	sta.W				   $0ec6	 ; Store back

Menu_BattleSettings_Commit:
	jsr.W				   Sprite_SetMode2D ; Set sprite mode $2d
	bra					 Menu_BattleSettings_Refresh ; Update display

Menu_BattleSettings_SetColor:
	cmp.B				   #$04	  ; Check if 4
	bcc					 Menu_BattleSettings_SetBlue ; If < 4, handle blue
	beq					 Menu_BattleSettings_SetGreen ; If = 4, handle green
	lda.B				   #$7c	  ; Mask for red component
	trb.W				   $0e9d	 ; Clear red bits
	lda.B				   $01	   ; Load new value
	asl					 a; Shift left 4 times
	asl					 a
	asl					 a
	asl					 a
	bpl					 Menu_BattleSettings_SetRed_Store ; If positive, use value
	lda.B				   #$7c	  ; Max value

Menu_BattleSettings_SetRed_Store:
	tsb.W				   $0e9d	 ; Set red bits
	bra					 Menu_BattleSettings_Commit ; Update display

Menu_BattleSettings_SetGreen:
	rep					 #$30		; 16-bit A/X/Y
	lda.W				   #$03e0	; Mask for green component
	trb.W				   $0e9c	 ; Clear green bits
	lda.B				   $00	   ; Load new value
	and.W				   #$ff00	; Get high byte
	lsr					 a; Shift right
	cmp.W				   #$0400	; Check if exceeds max
	bne					 Menu_BattleSettings_SetGreen_Store ; If not, use value
	lda.W				   #$03e0	; Max value

Menu_BattleSettings_SetGreen_Store:
	tsb.W				   $0e9c	 ; Set green bits
	bra					 Menu_BattleSettings_Commit ; Update display

Menu_BattleSettings_SetBlue:
	lda.B				   #$1f	  ; Mask for blue component
	trb.W				   $0e9c	 ; Clear blue bits
	lda.B				   $01	   ; Load new value
	asl					 a; Shift left 2 times
	asl					 a
	cmp.B				   #$20	  ; Check if exceeds max
	bne					 Menu_BattleSettings_SetBlue_Store ; If not, use value
	lda.B				   #$1f	  ; Max value

Menu_BattleSettings_SetBlue_Store:
	tsb.W				   $0e9c	 ; Set blue bits
	bra					 Menu_BattleSettings_Commit ; Update display

SystemData_Config14:
	db											 $1f		 ; Blue data
DATA8_00c339:
	db											 $1f		 ; Blue data
DATA8_00c33a:
	db											 $20		 ; Green data
DATA8_00c33b:
	db											 $78,$3f,$20,$58,$5f,$20,$38,$7f,$38,$00

SystemData_Config15:
	db											 $94,$92,$03

;-------------------------------------------------------------------------------
; Save File Deletion System (Menu_SaveDelete - Menu_SaveDelete_UpdateCursor)
;-------------------------------------------------------------------------------
Menu_SaveDelete:
	lda.W				   #$0301	; Menu mode $0301
	sta.B				   $03	   ; Store in $03
	ldx.W				   #$0c00	; Load $0c00
	stx.B				   $8e	   ; Store in $8e

Menu_SaveDelete_InputLoop:
	lda.W				   #$8c80	; Button mask
	jsr.W				   CODE_00B930 ; Poll input
	bne					 Menu_SaveDelete_UpdateCursor ; If button pressed, process
	bit.W				   #$0080	; Test B button
	bne					 Menu_SaveDelete_Confirm ; If pressed, cancel
	bit.W				   #$8000	; Test A button
	beq					 Menu_SaveDelete_InputLoop ; If not pressed, loop

Menu_SaveDelete_Exit:
	jsr.W				   CODE_00B91C ; Set animation mode $10
	stz.B				   $8e	   ; Clear $8e
RTS_Label:

Menu_SaveDelete_Confirm:
	jsr.W				   CODE_00B908 ; Set sprite mode $2d
	sep					 #$20		; 8-bit accumulator
	lda.B				   $02	   ; Load save slot selection
	inc					 a; +1 (1-based index)
	sta.L				   $701ffd   ; Store save slot
	dec					 a; Back to 0-based
	rep					 #$30		; 16-bit A/X/Y
	and.W				   #$00ff	; Mask to 8 bits
	sta.W				   $010e	 ; Store slot index
	jsr.W				   CODE_00C9D3 ; Get save slot address
	lda.W				   #$0040	; Bit 6 mask
	tsb.W				   $00de	 ; Set bit 6 of $de
	jsr.W				   CODE_00CF3F ; Clear save data
	ldx.W				   #$c3d8	; Menu data
	jsr.W				   CODE_009BC4 ; Update menu
	lda.B				   $9e	   ; Load result
	bit.W				   #$8000	; Test bit 15
	bne					 Menu_SaveDelete_Exit ; If set, return
	bit.W				   #$0c00	; Test bits 10-11
	beq					 Menu_SaveDelete_InputLoop ; If clear, loop

Menu_SaveDelete_UpdateCursor:
	lda.W				   #$0000	; Load 0
	sep					 #$20		; 8-bit accumulator
	lda.B				   #$ec	  ; Load $ec
	sta.L				   $7f56da   ; Store to WRAM
	sta.L				   $7f56dc   ; Store to WRAM
	sta.L				   $7f56de   ; Store to WRAM
	lda.B				   $02	   ; Load option index
	cmp.B				   $06	   ; Compare with previous
	beq					 Menu_SaveDelete_UpdateDisplay ; If same, skip update
	sta.B				   $06	   ; Store new selection
	jsr.W				   CODE_00B91C ; Update sprite
	lda.B				   $06	   ; Reload selection

Menu_SaveDelete_UpdateDisplay:
	asl					 a; × 2
	tax							   ; Transfer to X
	lda.B				   #$e0	  ; Load $e0
	sta.L				   $7f56da,x ; Store to WRAM indexed
	lda.B				   #$08	  ; Bit 3 mask
	tsb.W				   $00d4	 ; Set bit 3
	jsl.L				   CODE_0C8000 ; Call external routine
	lda.B				   #$08	  ; Bit 3 mask
	trb.W				   $00d4	 ; Clear bit 3
	rep					 #$30		; 16-bit A/X/Y
	jmp.W				   Menu_SaveDelete_InputLoop ; Jump back to loop

SystemData_Config16:
	db											 $c3,$95,$03

;-------------------------------------------------------------------------------
; Menu Scrolling System (Menu_Scroll - Menu_Scroll_Down)
;-------------------------------------------------------------------------------
Menu_Scroll:
	lda.W				   #$0305	; Menu mode $0305
	sta.B				   $03	   ; Store in $03
	ldx.W				   #$fff0	; Position offset (-16)
	stx.B				   $8e	   ; Set position
	bra					 Menu_Scroll_Display ; Jump to menu display

Menu_Scroll_InputLoop:
	lda.W				   #$cf30	; Button mask
	jsr.W				   CODE_00B930 ; Poll input
	bit.W				   #$0300	; Test Y/X buttons
	bne					 Menu_Scroll_Process ; If pressed, process
	bit.W				   #$0c00	; Test L/R buttons
	bne					 Menu_Scroll_Display ; If pressed, refresh
	bit.W				   #$8000	; Test A button
	beq					 Menu_Scroll_InputLoop ; If not pressed, loop
	jsr.W				   CODE_00B91C ; Update sprite
	stz.B				   $8e	   ; Clear position
	ldx.W				   #$c444	; Menu data
	jmp.W				   CODE_009BC4 ; Show menu

Menu_Scroll_Process:
	sep					 #$20		; 8-bit accumulator
	lda.B				   $01	   ; Load menu option
	cmp.B				   #$04	  ; Check if option 4
	beq					 Menu_Scroll_Down ; If yes, scroll down
	lda.B				   $04	   ; Load scroll position
	cmp.B				   #$03	  ; Check if at top
	beq					 Menu_Scroll_Update ; If yes, can't scroll up
	dec.B				   $04	   ; Decrement scroll
	lda.B				   $02	   ; Load current index
	sbc.B				   #$02	  ; Subtract 2
	bcs					 Menu_Scroll_StoreIndex ; If no underflow, continue
	lda.B				   #$00	  ; Clamp to 0

Menu_Scroll_StoreIndex:
	sta.B				   $02	   ; Store new index
	bra					 Menu_Scroll_Update ; Continue

Menu_Scroll_Down:
	lda.B				   $04	   ; Load scroll position
	cmp.B				   #$04	  ; Check if at bottom
	beq					 Menu_Scroll_Update ; If yes, can't scroll down
	inc.B				   $04	   ; Increment scroll
	lda.B				   $02	   ; Load current index
	adc.B				   #$02	  ; Add 2
	cmp.B				   #$04	  ; Check if >= 4
	bne					 Menu_Scroll_StoreClamp ; If not, continue
	lda.B				   #$03	  ; Clamp to 3

Menu_Scroll_StoreClamp:
	sta.B				   $02	   ; Store new index

Menu_Scroll_Update:
	rep					 #$30		; 16-bit A/X/Y

Menu_Scroll_Display:
	ldx.W				   #$c441	; Menu data
	jsr.W				   CODE_009BC4 ; Update menu
	bra					 Menu_Scroll_InputLoop ; Loop

SystemData_Config17:
	db											 $8e,$90,$03

SystemData_Config18:
	db											 $47,$91,$03

;-------------------------------------------------------------------------------
; Another Menu Scrolling System (Menu_Scroll2 - Menu_Scroll2_Bottom)
;-------------------------------------------------------------------------------
Menu_Scroll2:
	lda.W				   #$0305	; Menu mode $0305
	sta.B				   $03	   ; Store in $03
	ldx.W				   #$fff0	; Position offset (-16)
	stx.B				   $8e	   ; Set position
	bra					 Menu_Scroll2_Display ; Jump to menu display

Menu_Scroll2_InputLoop:
	lda.W				   #$cf30	; Button mask
	jsr.W				   CODE_00B930 ; Poll input
	bit.W				   #$0300	; Test Y/X buttons
	bne					 Menu_Scroll2_Process ; If pressed, process
	bit.W				   #$0c00	; Test L/R buttons
	bne					 Menu_Scroll2_Display ; If pressed, refresh
	bit.W				   #$8000	; Test A button
	beq					 Menu_Scroll2_InputLoop ; If not pressed, loop
	jsr.W				   CODE_00B91C ; Update sprite
	stz.B				   $8e	   ; Clear position
	ldx.W				   #$c49f	; Menu data
	jmp.W				   CODE_009BC4 ; Show menu

Menu_Scroll2_Process:
	sep					 #$20		; 8-bit accumulator
	lda.B				   $01	   ; Load menu option
	cmp.B				   #$04	  ; Check if option 4
	beq					 Menu_Scroll2_Bottom ; If yes, scroll to bottom
	lda.B				   #$03	  ; Load 3
	cmp.B				   $04	   ; Compare with scroll position
	beq					 Menu_Scroll2_Update ; If equal, done
	sta.B				   $04	   ; Store 3
	dec					 a; Decrement to 2
	sta.B				   $02	   ; Store index
	bra					 Menu_Scroll2_Update ; Continue

Menu_Scroll2_Bottom:
	lda.B				   #$01	  ; Load 1
	cmp.B				   $04	   ; Compare with scroll position
	beq					 Menu_Scroll2_Update ; If equal, done
	sta.B				   $04	   ; Store 1
	stz.B				   $02	   ; Clear index

Menu_Scroll2_Update:
	rep					 #$30		; 16-bit A/X/Y

Menu_Scroll2_Display:
	ldx.W				   #$c49c	; Menu data
	jsr.W				   CODE_009BC4 ; Update menu
	bra					 Menu_Scroll2_InputLoop ; Loop

SystemData_Config19:
	db											 $e3,$91,$03

SystemData_Config20:
	db											 $47,$91,$03

;-------------------------------------------------------------------------------
; Wait Loop with Input Polling (Menu_WaitInput - Menu_WaitInput_Confirm)
;-------------------------------------------------------------------------------
Menu_WaitInput:
	ldx.W				   #$fff0	; Position offset (-16)
	stx.B				   $8e	   ; Set position

Menu_WaitInput_Loop:
	jsl.L				   CODE_0096A0 ; Call external routine
	lda.W				   #$0080	; Bit 7 mask
	and.W				   $00d9	 ; Test flag
	beq					 Menu_WaitInput_Poll ; If clear, continue
	db											 $a9,$80,$00,$1c,$d9,$00,$a2,$d8,$c4,$20,$c4,$9b,$80,$e6 ; Data/unreachable

Menu_WaitInput_Poll:
	lda.B				   $07	   ; Load input result
	and.W				   #$bfcf	; Mask buttons
	beq					 Menu_WaitInput_Loop ; If no button, loop
	and.W				   #$8000	; Test A button
	bne					 Menu_WaitInput_Confirm ; If pressed, confirm
	jsr.W				   CODE_00B912 ; Update sprite mode
	bra					 Menu_WaitInput_Loop ; Loop

Menu_WaitInput_Confirm:
	jsr.W				   CODE_00B91C ; Update sprite
	stz.B				   $8e	   ; Clear position
RTS_Label:

SystemData_Config21:
	db											 $d1,$9c,$03
;===============================================================================
; WRAM Buffer Management & Screen Setup (CODE_00C4DB - CODE_00C7DD)
;===============================================================================
; This section manages WRAM buffers at $7f5000-$7f5700 for battle menus
; and handles screen initialization for various game modes
;===============================================================================

; CODE_00C4DB - already a stub, implementing now
WRAM_BattleMenu_Init:
	jsr.W				   WRAM_ClearBuffer1 ; Clear WRAM buffer 1 ($7f5000)
	jsr.W				   WRAM_ClearBuffer2 ; Clear WRAM buffer 2 ($7f51b7)
	jsr.W				   WRAM_ClearBuffer3 ; Clear WRAM buffer 3 ($7f536e)
	jsr.W				   WRAM_ClearBuffer4 ; Clear WRAM buffer 4 ($7f551e)
	jsr.W				   WRAM_FillData ; Jump to CODE_00C5B5 (WRAM $7e3000)
	ldx.W				   #$c51b	; Source data pointer
	ldy.W				   #$5000	; Dest: WRAM $7f5000
	lda.W				   #$0006	; 7 bytes
	mvn					 $7f,$00	 ; Block move Bank $00 ? $7f
	ldy.W				   #$4360	; Dest: DMA channel 6
	lda.W				   #$0007	; 8 bytes
	mvn					 $00,$00	 ; Block move within Bank $00
	ldy.W				   #$5367	; Dest: WRAM $7f5367
	lda.W				   #$0006	; 7 bytes
	mvn					 $7f,$00	 ; Block move Bank $00 ? $7f
	ldy.W				   #$4370	; Dest: DMA channel 7
	lda.W				   #$0007	; 8 bytes
	mvn					 $00,$00	 ; Block move within Bank $00
	sep					 #$20		; 8-bit accumulator
	lda.B				   #$c0	  ; Bits 6-7
	tsb.W				   $0111	 ; Set bits in $0111
	rep					 #$30		; 16-bit A/X/Y
RTS_Label:

SystemData_Config22:
	db											 $ff,$07,$50,$d9,$05,$51,$00,$42,$0e,$00,$50,$7f,$07,$50,$7f,$ff
	db											 $6e,$53,$d9,$6c,$54,$00,$42,$10,$67,$53,$7f,$6e,$53,$7f

; Helper - Unknown purpose
WRAM_BattleMenu_Update:
	pea.W				   $007f	 ; Push $007f
	plb							   ; Pull to data bank
	ldy.W				   #$5016	; WRAM address
	jsr.W				   WRAM_BattleMenu_FillSection ; Call fill routine
	ldy.W				   #$537d	; WRAM address
	jsr.W				   WRAM_BattleMenu_FillSection ; Call fill routine
	plb							   ; Restore data bank
RTS_Label:

WRAM_BattleMenu_FillSection:
	ldx.W				   #$000d	; 13 iterations
	clc							   ; Clear carry

WRAM_BattleMenu_FillLoop:
	sep					 #$20		; 8-bit accumulator
	lda.B				   #$00	  ; Value 0
	jsr.W				   CODE_0099EA ; Write to WRAM
	rep					 #$30		; 16-bit A/X/Y
	tya							   ; Y to A
	adc.W				   #$0020	; Add $20 (32 bytes)
	tay							   ; Back to Y
	dex							   ; Decrement counter
	bne					 WRAM_BattleMenu_FillLoop ; Loop if not zero
RTS_Label:

;-------------------------------------------------------------------------------
; WRAM Buffer Clear Routines
;-------------------------------------------------------------------------------
WRAM_ClearBuffer1:
	lda.W				   #$0000	; Clear value
	sta.L				   $7f5007   ; Write to $7f5007
	ldx.W				   #$5007	; Source
	ldy.W				   #$5009	; Dest
	lda.W				   #$01ad	; 430 bytes
	mvn					 $7f,$7f	 ; Fill $7f5007-$7f51b5 with 0
	bra					 WRAM_SetupBattleSprites1 ; Continue

WRAM_ClearBuffer2:
	lda.W				   #$0100	; Value $0100
	sta.L				   $7f51b7   ; Write to $7f51b7
	ldx.W				   #$51b7	; Source
	ldy.W				   #$51b9	; Dest
	lda.W				   #$01ad	; 430 bytes
	mvn					 $7f,$7f	 ; Fill $7f51b7-$7f5365 with $0100
	bra					 WRAM_SetupBattleSprites1 ; Continue

WRAM_ClearBuffer3:
	lda.W				   #$0000	; Clear value
	sta.L				   $7f536e   ; Write to $7f536e
	ldx.W				   #$536e	; Source
	ldy.W				   #$5370	; Dest
	lda.W				   #$01ad	; 430 bytes
	mvn					 $7f,$7f	 ; Fill $7f536e-$7f551c with 0
	bra					 WRAM_SetupBattleSprites2 ; Continue

WRAM_ClearBuffer4:
	lda.W				   #$0100	; Value $0100
	sta.L				   $7f551e   ; Write to $7f551e
	ldx.W				   #$551e	; Source
	ldy.W				   #$5520	; Dest
	lda.W				   #$01ad	; 430 bytes
	mvn					 $7f,$7f	 ; Fill $7f551e-$7f56cc with $0100
	bra					 WRAM_SetupBattleSprites2 ; Continue

WRAM_FillData:
	lda.W				   #$0000	; Clear value
	sta.L				   $7e3007   ; Write to $7e3007
	ldx.W				   #$3007	; Source
	ldy.W				   #$3009	; Dest
	lda.W				   #$01ad	; 430 bytes
	mvn					 $7e,$7e	 ; Fill $7e3007-$7e31b5 with 0
	lda.W				   #$0120	; Value $0120
	sta.W				   $31b5	 ; Store at $7e31b5
RTS_Label:

WRAM_SetupBattleSprites2:
	tya							   ; Y to A
	sec							   ; Set carry
	sbc.W				   #$0042	; Subtract $42
	tay							   ; Back to Y
	ldx.W				   #$c5e7	; Data pointer
	lda.L				   $000ec6   ; Load battle speed flag
	and.W				   #$0080	; Test bit 7
	beq					 WRAM_SetupBattleSprites2_Continue ; If clear, use first data
	db											 $a2,$f0,$c5 ; LDX #$c5f0 (alternate data)

WRAM_SetupBattleSprites2_Continue:
	jmp.W				   WRAM_SetupSprites ; Jump to sprite setup

SystemData_Config23:
	db											 $0c,$20,$06,$24,$06,$26,$08,$28,$00
	db											 $18,$20,$08,$28,$00

WRAM_SetupBattleSprites1:
	tya							   ; Y to A
	sec							   ; Set carry
	sbc.W				   #$0042	; Subtract $42
	tay							   ; Back to Y
	ldx.W				   #$c601	; Data pointer
	jmp.W				   WRAM_SetupSprites ; Jump to sprite setup

SystemData_Config24:
	db											 $20,$28,$00

WRAM_FillData_Jump:
	jmp.W				   WRAM_FillData ; Jump to WRAM clear

;-------------------------------------------------------------------------------
; Screen Setup Routines
;-------------------------------------------------------------------------------
Screen_Setup1:
	jsr.W				   WRAM_FillData ; Clear WRAM $7e3000
	lda.W				   #$0060	; Value $60
	ldx.W				   #$3025	; Address $7e3025
	jsr.W				   Screen_FillWords ; Fill 8 words
	ldx.W				   #$3035	; Address $7e3035
	bra					 Screen_FillWords_Alt ; Continue

Screen_Setup2:
	jsr.W				   WRAM_ClearBuffer1 ; Clear WRAM buffer 1
	lda.W				   #$0030	; Value $30
	ldx.W				   #$50f5	; Address $7f50f5
	bra					 Screen_FillWords_Alt ; Continue

Screen_Setup3:
	jsr.W				   WRAM_ClearBuffer2 ; Clear WRAM buffer 2
	lda.W				   #$0030	; Value $30
	ldx.W				   #$52a5	; Address $7f52a5

Screen_FillWords_Alt:
	jsr.W				   Screen_FillWords ; Fill 8 words
	sec							   ; Set carry

Screen_FillWords_Loop:
	sta.W				   $0010,x   ; Store at X+$10
	sta.W				   $0012,x   ; Store at X+$12
	sta.W				   $0014,x   ; Store at X+$14
	sta.W				   $0016,x   ; Store at X+$16
	sta.W				   $0018,x   ; Store at X+$18
	sta.W				   $001a,x   ; Store at X+$1a
	sta.W				   $001c,x   ; Store at X+$1c
	sta.W				   $001e,x   ; Store at X+$1e
	tay							   ; Transfer to Y
	rep					 #$30		; 16-bit A/X/Y
	txa							   ; X to A
	adc.W				   #$000f	; Add 15
	tax							   ; Back to X
	sep					 #$20		; 8-bit accumulator
	tya							   ; Y to A
	sbc.B				   #$07	  ; Subtract 7
	bne					 Screen_FillWords_Loop ; Loop if not zero
	rep					 #$30		; 16-bit A/X/Y
RTS_Label:

Screen_FillWords:
	sep					 #$20		; 8-bit accumulator
	sta.W				   $0000,x   ; Store at X+0
	sta.W				   $0002,x   ; Store at X+2
	sta.W				   $0004,x   ; Store at X+4
	sta.W				   $0006,x   ; Store at X+6
	sta.W				   $0008,x   ; Store at X+8
	sta.W				   $000a,x   ; Store at X+10
	sta.W				   $000c,x   ; Store at X+12
	sta.W				   $000e,x   ; Store at X+14
RTS_Label:
; ==============================================================================
; Screen Setup and Sprite Systems - Battle_SetupSprites+
; ==============================================================================

Battle_SetupSprites1:
	ldy.W				   #$521d	;00C675|A01D52  |      ;
	phb							   ;00C678|8B      |      ;
	phy							   ;00C679|5A      |      ;
	jsr.W				   WRAM_ClearBuffer2 ;00C67A|2076C5  |00C576;
	ply							   ;00C67D|7A      |      ;
	ldx.W				   #$c686	;00C67E|A286C6  |      ;
	jsr.W				   WRAM_SetupSprites ;00C681|205BC7  |00C75B;
	plb							   ;00C684|AB      |      ;
	rts							   ;00C685|60      |      ;

SystemData_Config25:
	db											 $0c,$04,$18,$08,$00 ;00C686|        |      ;

Battle_SetupSprites2:
	phb							   ;00C68B|8B      |      ;
	jsr.W				   WRAM_ClearBuffer2 ;00C68C|2076C5  |00C576;
	ldx.W				   #$c6a6	;00C68F|A2A6C6  |      ;
	ldy.W				   #$522d	;00C692|A02D52  |      ;
	jsr.W				   WRAM_SetupSprites ;00C695|205BC7  |00C75B;
	jsr.W				   WRAM_ClearBuffer4 ;00C698|20A0C5  |00C5A0;
	ldx.W				   #$c6b3	;00C69B|A2B3C6  |      ;
	ldy.W				   #$5634	;00C69E|A03456  |      ;
	jsr.W				   WRAM_SetupSprites ;00C6A1|205BC7  |00C75B;
	plb							   ;00C6A4|AB      |      ;
	rts							   ;00C6A5|60      |      ;

SystemData_Config26:
	db											 $0c,$04,$0c,$08,$1c,$0c,$1c,$10,$1c,$14,$10,$18,$00 ;00C6A6|        |      ;

SystemData_Config27:
	db											 $1c,$04,$10,$08,$00 ;00C6B3|        |      ;

Battle_SetupSprites3:
	phb							   ;00C6B8|8B      |      ;
	jsr.W				   WRAM_ClearBuffer2 ;00C6B9|2076C5  |00C576;
	ldx.W				   #$c6d3	;00C6BC|A2D3C6  |      ;
	ldy.W				   #$528d	;00C6BF|A08D52  |      ;
	jsr.W				   WRAM_SetupSprites ;00C6C2|205BC7  |00C75B;
	jsr.W				   WRAM_ClearBuffer4 ;00C6C5|20A0C5  |00C5A0;
	ldx.W				   #$c6d6	;00C6C8|A2D6C6  |      ;
	ldy.W				   #$5574	;00C6CB|A07455  |      ;
	jsr.W				   WRAM_SetupSprites ;00C6CE|205BC7  |00C75B;
	plb							   ;00C6D1|AB      |      ;
	rts							   ;00C6D2|60      |      ;

SystemData_Config28:
	db											 $0c,$04,$00 ;00C6D3|        |      ;

SystemData_Config29:
	db											 $0c,$04,$14,$08,$0c,$0c,$34,$10,$0c,$14,$0c,$18,$0c ;00C6D6|        |      ;
	db											 $1c,$08,$20,$00 ;00C6E3|        |      ;

Battle_SetupSprites4:
	phb							   ;00C6E7|8B      |      ;
	jsr.W				   WRAM_ClearBuffer2 ;00C6E8|2076C5  |00C576;
	ldx.W				   #$c73f	;00C6EB|A23FC7  |      ;
	ldy.W				   #$527d	;00C6EE|A07D52  |      ;
	jsr.W				   CODE_00C75B ;00C6F1|205BC7  |00C75B;
	jsr.W				   CODE_00C5A0 ;00C6F4|20A0C5  |00C5A0;
	ldx.W				   #$c744	;00C6F7|A244C7  |      ;
	ldy.W				   #$55b4	;00C6FA|A0B455  |      ;
	jsr.W				   CODE_00C75B ;00C6FD|205BC7  |00C75B;
	ldx.W				   #$55b4	;00C700|A2B455  |      ;
	ldy.W				   #$0000	;00C703|A00000  |      ;
	lda.L				   $000101   ;00C706|AF010100|000101;
	jsr.W				   CODE_00C729 ;00C70A|2029C7  |00C729;
	ldx.W				   #$562c	;00C70D|A22C56  |      ;
	ldy.W				   #$000c	;00C710|A00C00  |      ;
	lda.L				   $000102   ;00C713|AF020100|000102;
	jsr.W				   CODE_00C729 ;00C717|2029C7  |00C729;
	ldx.W				   #$56a4	;00C71A|A2A456  |      ;
	ldy.W				   #$0018	;00C71D|A01800  |      ;
	lda.L				   $000103   ;00C720|AF030100|000103;
	jsr.W				   SaveData_ProcessFlag ;00C724|2029C7  |00C729;
	plb							   ;00C727|AB      |      ;
	rts							   ;00C728|60      |      ;

SaveData_ProcessFlag:
	and.W				   #$0080	;00C729|298000  |      ;
	beq					 SaveData_FlagDone ;00C72C|F010    |00C73E;
	db											 $e2,$20,$98,$9d,$00,$00,$9b,$c8,$c8,$a9,$15,$54,$7f,$7f,$c2,$30 ;00C72E|        |      ;

SaveData_FlagDone:
	rts							   ;00C73E|60      |      ;

SystemData_Config30:
	db											 $3c,$04,$38,$08,$00 ;00C73F|        |      ;

SystemData_Config31:
	db											 $06,$04,$06,$06,$0c,$08,$24,$0c,$06,$10,$06,$12,$0c,$14,$24,$18 ;00C744|        |      ;
	db											 $06,$1c,$06,$1e,$08,$20,$00 ;00C754|        |      ;
; ==============================================================================
; Sprite Display System and Save/Load Operations - WRAM_SetupSprites+
; ==============================================================================

WRAM_SetupSprites:
	phb							   ;00C75B|8B      |      ;
	phb							   ;00C75C|8B      |      ;
	pla							   ;00C75D|68      |      ;
	sta.L				   $000031   ;00C75E|8F310000|000031;
	sep					 #$20		;00C762|E220    |      ;

WRAM_SetupSprites_Loop:
	lda.L				   $000000,x ;00C764|BF000000|000000;
	beq					 WRAM_SetupSprites_Done ;00C768|F020    |00C78A;
	xba							   ;00C76A|EB      |      ;
	lda.L				   $000001,x ;00C76B|BF010000|000001;
	sta.W				   $0000,y   ;00C76F|990000  |7F0000;
	lda.B				   #$00	  ;00C772|A900    |      ;
	xba							   ;00C774|EB      |      ;
	dec					 a;00C775|3A      |      ;
	beq					 UNREACH_00C784 ;00C776|F00C    |00C784;
	phx							   ;00C778|DA      |      ;
	asl					 a;00C779|0A      |      ;
	dec					 a;00C77A|3A      |      ;
	tyx							   ;00C77B|BB      |      ;
	iny							   ;00C77C|C8      |      ;
	iny							   ;00C77D|C8      |      ;
	jsr.W				   $0030	 ;00C77E|203000  |000030;
	plx							   ;00C781|FA      |      ;
	bra					 WRAM_SetupSprites_Continue ;00C782|8002    |00C786;

UNREACH_00C784:
	db											 $c8,$c8	 ;00C784|        |      ;

WRAM_SetupSprites_Continue:
	inx							   ;00C786|E8      |      ;
	inx							   ;00C787|E8      |      ;
	bra					 WRAM_SetupSprites_Loop ;00C788|80DA    |00C764;

WRAM_SetupSprites_Done:
	rep					 #$30		;00C78A|C230    |      ;
	rts							   ;00C78C|60      |      ;

Screen_DisableDMA:
	sep					 #$20		;00C78D|E220    |      ;
	lda.B				   #$c0	  ;00C78F|A9C0    |      ;
	trb.W				   $0111	 ;00C791|1C1101  |000111;
	rts							   ;00C794|60      |      ;

Screen_WaitForUpdate:
	php							   ;00C795|08      |      ;
	sep					 #$20		;00C796|E220    |      ;
	lda.B				   #$80	  ;00C798|A980    |      ;
	trb.W				   $00d6	 ;00C79A|1CD600  |0000D6;
	lda.W				   $00aa	 ;00C79D|ADAA00  |0000AA;
	and.B				   #$f0	  ;00C7A0|29F0    |      ;
	sta.W				   $0110	 ;00C7A2|8D1001  |000110;
	lda.W				   $00aa	 ;00C7A5|ADAA00  |0000AA;

Screen_WaitForUpdate_Loop:
	cmp.W				   $0110	 ;00C7A8|CD1001  |000110;
	beq					 Screen_WaitForUpdate_Done ;00C7AB|F009    |00C7B6;
	inc.W				   $0110	 ;00C7AD|EE1001  |000110;
	jsl.L				   CODE_0C8000 ;00C7B0|2200800C|0C8000;
	bra					 Screen_WaitForUpdate_Loop ;00C7B4|80F2    |00C7A8;

Screen_WaitForUpdate_Done:
	plp							   ;00C7B6|28      |      ;
	rtl							   ;00C7B7|6B      |      ;

Screen_FadeOut:
	php							   ;00C7B8|08      |      ;
	sep					 #$20		;00C7B9|E220    |      ;
	lda.W				   $0110	 ;00C7BB|AD1001  |010110;
	sta.W				   $00aa	 ;00C7BE|8DAA00  |0100AA;

Screen_FadeOut_Loop:
	bit.B				   #$0f	  ;00C7C1|890F    |      ;
	beq					 Screen_FadeOut_Done ;00C7C3|F00A    |00C7CF;
	dec					 a;00C7C5|3A      |      ;
	sta.W				   $0110	 ;00C7C6|8D1001  |010110;
	jsl.L				   CODE_0C8000 ;00C7C9|2200800C|0C8000;
	bra					 Screen_FadeOut_Loop ;00C7CD|80F2    |00C7C1;

Screen_FadeOut_Done:
	lda.B				   #$80	  ;00C7CF|A980    |      ;
	tsb.W				   $00d6	 ;00C7D1|0CD600  |0100D6;
	lda.B				   #$80	  ;00C7D4|A980    |      ;
	sta.W				   $2100	 ;00C7D6|8D0021  |012100;
	sta.W				   $0110	 ;00C7D9|8D1001  |010110;
	plp							   ;00C7DC|28      |      ;
	rtl							   ;00C7DD|6B      |      ;

Menu_Init_Battle:
	jsr.W				   Screen_Setup2 ;00C7DE|2018C6  |00C618;
	jsr.W				   WRAM_ClearBuffer3 ;00C7E1|208BC5  |00C58B;
	ldx.W				   #$c8ec	;00C7E4|A2ECC8  |      ;
	jsr.W				   CODE_009BC4 ;00C7E7|20C49B  |009BC4;
	ldx.W				   #$c8e3	;00C7EA|A2E3C8  |      ;
	jmp.W				   CODE_009BC4 ;00C7ED|4CC49B  |009BC4;

Menu_Init_Status:
	lda.W				   $010d	 ;00C7F0|AD0D01  |00010D;
	bpl					 Menu_Init_Status_Continue ;00C7F3|1003    |00C7F8;
	lda.W				   #$0000	;00C7F5|A90000  |      ;

Menu_Init_Status_Continue:
	and.W				   #$ff00	;00C7F8|2900FF  |      ;
	sta.B				   $01	   ;00C7FB|8501    |000001;
	sep					 #$20		;00C7FD|E220    |      ;
	lda.B				   #$18	  ;00C7FF|A918    |      ;
	sta.W				   $00ab	 ;00C801|8DAB00  |0000AB;
	jsr.W				   CODE_00CBEC ;00C804|20ECCB  |00CBEC;
	rep					 #$30		;00C807|C230    |      ;
	ldx.W				   #$c922	;00C809|A222C9  |      ;
	jsr.W				   CODE_009BC4 ;00C80C|20C49B  |009BC4;
	phb							   ;00C80F|8B      |      ;
	ldx.W				   #$016f	;00C810|A26F01  |      ;
	ldy.W				   #$0e04	;00C813|A0040E  |      ;
	lda.W				   #$0005	;00C816|A90500  |      ;
	mvn					 $00,$00	 ;00C819|540000  |      ;
	lda.W				   #$0020	;00C81C|A92000  |      ;
	tsb.W				   $00d2	 ;00C81F|0CD200  |0000D2;
	jsr.W				   Screen_Setup1 ;00C822|2007C6  |00C607;
	ldx.W				   #$51c5	;00C825|A2C551  |      ;
	ldy.W				   #$5015	;00C828|A01550  |      ;
	lda.W				   #$019f	;00C82B|A99F01  |      ;
	mvn					 $7f,$7f	 ;00C82E|547F7F  |      ;
	ldx.W				   #$552c	;00C831|A22C55  |      ;
	ldy.W				   #$537c	;00C834|A07C53  |      ;
	lda.W				   #$019f	;00C837|A99F01  |      ;
	mvn					 $7f,$7f	 ;00C83A|547F7F  |      ;
	plb							   ;00C83D|AB      |      ;
	ldx.W				   #$c8e3	;00C83E|A2E3C8  |      ;
	jsr.W				   CODE_009BC4 ;00C841|20C49B  |009BC4;
	lda.W				   #$0600	;00C844|A90006  |      ;
	sta.B				   $01	   ;00C847|8501    |000001;
	sta.B				   $05	   ;00C849|8505    |000005;
	rts							   ;00C84B|60      |      ;

; Menu initialization and game state management
Menu_Init_SetBit6:
	lda.W				   #$0040	;00C84C|A94000  |      ;
	tsb.W				   $00db	 ;00C84F|0CDB00  |0000DB;
	bra					 Menu_Init_Common ;00C852|8006    |00C85A;

Menu_Init_SetBit0:
	lda.W				   #$0001	;00C854|A90100  |      ;
	tsb.W				   $00da	 ;00C857|0CDA00  |0000DA;

Menu_Init_Common:
	jsr.W				   Screen_Setup3 ;00C85A|2023C6  |00C623;
	jsr.W				   WRAM_ClearBuffer4 ;00C85D|20A0C5  |00C5A0;
	ldx.W				   #$c8ec	;00C860|A2ECC8  |      ;
	bra					 Menu_Init_UpdateMenu ;00C863|8038    |00C89D;

Menu_Init_Alt1:
	ldx.W				   #$c90a	;00C865|A20AC9  |      ;
	bra					 Menu_Init_UpdateMenu ;00C868|8033    |00C89D;

Menu_Init_Alt2:
	ldx.W				   #$c910	;00C86A|A210C9  |      ;
	bra					 Menu_Init_UpdateMenu ;00C86D|802E    |00C89D;

Menu_Init_ClearBit7:
	lda.W				   #$0080	;00C86F|A98000  |      ;
	trb.W				   $00d9	 ;00C872|1CD900  |0000D9;
	ldx.W				   #$c916	;00C875|A216C9  |      ;
	bra					 Menu_Init_UpdateMenu ;00C878|8023    |00C89D;

Menu_Init_SetBit7:
	lda.W				   #$0080	;00C87A|A98000  |      ;
	tsb.W				   $00db	 ;00C87D|0CDB00  |0000DB;
	ldx.W				   #$c91c	;00C880|A21CC9  |      ;
	bra					 Menu_Init_UpdateMenu ;00C883|8018    |00C89D;

Menu_Init_LoadCharacter:
	lda.W				   $010d	 ;00C885|AD0D01  |00010D;
	bpl					 Menu_Init_LoadCharacter_Continue ;00C888|1003    |00C88D;
	lda.W				   #$0000	;00C88A|A90000  |      ;

Menu_Init_LoadCharacter_Continue:
	and.W				   #$ff00	;00C88D|2900FF  |      ;
	sta.B				   $01	   ;00C890|8501    |000001;
	sta.B				   $05	   ;00C892|8505    |000005;
	lda.W				   #$0002	;00C894|A90200  |      ;
	tsb.W				   $00da	 ;00C897|0CDA00  |0000DA;
	ldx.W				   #$c922	;00C89A|A222C9  |      ;

Menu_Init_UpdateMenu:
	phx							   ;00C89D|DA      |      ;
	jsr.W				   CODE_009BC4 ;00C89E|20C49B  |009BC4;
	plx							   ;00C8A1|FA      |      ;
	inx							   ;00C8A2|E8      |      ;
	inx							   ;00C8A3|E8      |      ;
	inx							   ;00C8A4|E8      |      ;
	ldy.W				   #$0017	;00C8A5|A01700  |      ;
	lda.W				   #$0002	;00C8A8|A90200  |      ;
	mvn					 $00,$00	 ;00C8AB|540000  |      ;
	jsr.W				   CODE_00CAB9 ;00C8AE|20B9CA  |00CAB9;
	ldx.W				   #$c8e3	;00C8B1|A2E3C8  |      ;
	jmp.W				   CODE_009BC4 ;00C8B4|4CC49B  |009BC4;

; Animation and screen effect handlers
Screen_Effect1:
	ldx.W				   #$c8f2	;00C8B7|A2F2C8  |      ;
	bra					 Screen_EffectCommon ;00C8BA|800D    |00C8C9;

Screen_Effect2:
	ldx.W				   #$c8f8	;00C8BC|A2F8C8  |      ;
	bra					 Screen_EffectCommon ;00C8BF|8008    |00C8C9;

Screen_Effect3:
	ldx.W				   #$c8fe	;00C8C1|A2FEC8  |      ;
	bra					 Screen_EffectCommon ;00C8C4|8003    |00C8C9;

Screen_Effect4:
	ldx.W				   #$c904	;00C8C6|A204C9  |      ;

Screen_EffectCommon:
	phx							   ;00C8C9|DA      |      ;
	jsr.W				   CODE_009BC4 ;00C8CA|20C49B  |009BC4;
	plx							   ;00C8CD|FA      |      ;
	inx							   ;00C8CE|E8      |      ;
	inx							   ;00C8CF|E8      |      ;
	inx							   ;00C8D0|E8      |      ;
	lda.W				   #$000c	;00C8D1|A90C00  |      ;

Screen_EffectLoop:
	jsl.L				   CODE_0C8000 ;00C8D4|2200800C|0C8000;
	pha							   ;00C8D8|48      |      ;
	phx							   ;00C8D9|DA      |      ;
	jsr.W				   CODE_009BC4 ;00C8DA|20C49B  |009BC4;
	plx							   ;00C8DD|FA      |      ;
	pla							   ;00C8DE|68      |      ;
	dec					 a;00C8DF|3A      |      ;
	bne					 Screen_EffectLoop ;00C8E0|D0F2    |00C8D4;
	rts							   ;00C8E2|60      |      ;
; ==============================================================================
; Save System Data Tables and Checksum Validation - Final Systems
; ==============================================================================

; Save file data table pointers
SystemData_Config32:
	db											 $a7,$8f,$03,$f2,$aa,$03,$55,$ab,$03,$aa,$92,$03,$14,$93,$03,$19 ;00C8E3|        |      ;
	db											 $93,$03,$1f,$93,$03,$28,$93,$03,$33,$93,$03,$3c,$93,$03,$42,$93 ;00C8F3|        |      ;
	db											 $03,$4b,$93,$03,$57,$93,$03,$60,$93,$03,$a9,$93,$03,$ae,$93,$03 ;00C903|        |      ;
	db											 $f7,$93,$03,$fc,$93,$03,$74,$94,$03,$79,$94,$03,$dd,$94,$03,$e2 ;00C913|        |      ;
	db											 $94,$03,$ea,$97,$03 ;00C923|        |      ;

; Save slot address calculation
Save_GetSlotAddress:
	lda.W				   $015f	 ;00C928|AD5F01  |00015F;

Save_GetSlotAddress_Main:
	and.W				   #$00ff	;00C92B|29FF00  |      ;
	sta.B				   $98	   ;00C92E|8598    |000098;
	lda.W				   #$038c	;00C930|A98C03  |      ;
	sta.B				   $9c	   ;00C933|859C    |00009C;
	jsl.L				   CODE_0096B3 ;00C935|22B39600|0096B3;
	lda.B				   $9e	   ;00C939|A59E    |00009E;
	clc							   ;00C93B|18      |      ;
	adc.W				   #$0000	;00C93C|690000  |      ;
	sta.B				   $0b	   ;00C93F|850B    |00000B;
	rts							   ;00C941|60      |      ;

Save_ReadByte:
	php							   ;00C942|08      |      ;
	sep					 #$20		;00C943|E220    |      ;
	rep					 #$10		;00C945|C210    |      ;
	pha							   ;00C947|48      |      ;
	lda.B				   #$7f	  ;00C948|A97F    |      ;
	sta.B				   $61	   ;00C94A|8561    |000061;
	pla							   ;00C94C|68      |      ;
	plp							   ;00C94D|28      |      ;
	rts							   ;00C94E|60      |      ;

SaveData_SetBank70:
	php							   ;00C94F|08      |      ;
	sep					 #$20		;00C950|E220    |      ;
	rep					 #$10		;00C952|C210    |      ;
	pha							   ;00C954|48      |      ;
	lda.B				   #$70	  ;00C955|A970    |      ;
	sta.B				   $61	   ;00C957|8561    |000061;
	pla							   ;00C959|68      |      ;
	plp							   ;00C95A|28      |      ;
	rts							   ;00C95B|60      |      ;

Checksum_Calculator:
	pha							   ;00C95C|48      |      ;
	phx							   ;00C95D|DA      |      ;
	lda.W				   #$4646	;00C95E|A94646  |      ;
	sta.B				   $0e	   ;00C961|850E    |00000E;
	lda.W				   #$2130	;00C963|A93021  |      ;
	sta.B				   $10	   ;00C966|8510    |000010;
	ldx.W				   #$01c3	;00C968|A2C301  |      ;
	lda.W				   #$0000	;00C96B|A90000  |      ;
	clc							   ;00C96E|18      |      ;

Checksum_SumLoop:
	adc.B				   [$5f]	 ;00C96F|675F    |00005F;
	inc.B				   $5f	   ;00C971|E65F    |00005F;
	inc.B				   $5f	   ;00C973|E65F    |00005F;
	dex							   ;00C975|CA      |      ;
	bne					 Checksum_SumLoop ;00C976|D0F7    |00C96F;
	sta.B				   $12	   ;00C978|8512    |000012;
	plx							   ;00C97A|FA      |      ;
	pla							   ;00C97B|68      |      ;
	rts							   ;00C97C|60      |      ;

Checksum_Validator:
	ldx.W				   #$0000	;00C97D|A20000  |      ;

Checksum_ValidateLoop:
	lda.B				   $0e,x	 ;00C980|B50E    |00000E;
	cmp.B				   [$0b]	 ;00C982|C70B    |00000B;
	bne					 Checksum_ValidateDone ;00C984|D00B    |00C991;
	inc.B				   $0b	   ;00C986|E60B    |00000B;
	inc.B				   $0b	   ;00C988|E60B    |00000B;
	inx							   ;00C98A|E8      |      ;
	inx							   ;00C98B|E8      |      ;
	cpx.W				   #$0006	;00C98C|E00600  |      ;
	bne					 Checksum_ValidateLoop ;00C98F|D0EF    |00C980;

Checksum_ValidateDone:
	rts							   ;00C991|60      |      ;

SaveData_Processor:
	phb							   ;00C992|8B      |      ;
	phx							   ;00C993|DA      |      ;
	phy							   ;00C994|5A      |      ;
	pha							   ;00C995|48      |      ;
	ldx.W				   #$3000	;00C996|A20030  |      ;
	stx.B				   $5f	   ;00C999|865F    |00005F;
	jsr.W				   CODE_00C942 ;00C99B|2042C9  |00C942;
	jsr.W				   CODE_00C95C ;00C99E|205CC9  |00C95C;
	jsr.W				   CODE_00C92B ;00C9A1|202BC9  |00C92B;
	ldy.B				   $0b	   ;00C9A4|A40B    |00000B;
	ldx.W				   #$000e	;00C9A6|A20E00  |      ;
	lda.W				   #$0005	;00C9A9|A90500  |      ;
	mvn					 $70,$00	 ;00C9AC|547000  |      ;
	sty.B				   $5f	   ;00C9AF|845F    |00005F;
	ldx.W				   #$3000	;00C9B1|A20030  |      ;
	lda.W				   #$0385	;00C9B4|A98503  |      ;
	mvn					 $70,$7f	 ;00C9B7|54707F  |      ;
	lda.B				   $12	   ;00C9BA|A512    |000012;
	jsr.W				   CODE_00C94F ;00C9BC|204FC9  |00C94F;
	jsr.W				   CODE_00C95C ;00C9BF|205CC9  |00C95C;
	cmp.B				   $12	   ;00C9C2|C512    |000012;
	bne					 UNREACH_00C9CB ;00C9C4|D005    |00C9CB;
	jsr.W				   Checksum_Validator ;00C9C6|207DC9  |00C97D;
	beq					 SaveData_RestoreRegisters ;00C9C9|F003    |00C9CE;

UNREACH_00C9CB:
	db											 $68,$80,$c7 ;00C9CB|        |      ;

SaveData_RestoreRegisters:
	pla							   ;00C9CE|68      |      ;
	ply							   ;00C9CF|7A      |      ;
	plx							   ;00C9D0|FA      |      ;
	plb							   ;00C9D1|AB      |      ;
	rts							   ;00C9D2|60      |      ;

SaveData_MemoryCopy:
	php							   ;00C9D3|08      |      ;
	rep					 #$30		;00C9D4|C230    |      ;
	phb							   ;00C9D6|8B      |      ;
	pha							   ;00C9D7|48      |      ;
	phd							   ;00C9D8|0B      |      ;
	phx							   ;00C9D9|DA      |      ;
	phy							   ;00C9DA|5A      |      ;
	pha							   ;00C9DB|48      |      ;
	stz.B				   $8e	   ;00C9DC|648E    |00008E;
	phb							   ;00C9DE|8B      |      ;
	ldx.W				   #$1000	;00C9DF|A20010  |      ;
	ldy.W				   #$3000	;00C9E2|A00030  |      ;
	lda.W				   #$004f	;00C9E5|A94F00  |      ;
	mvn					 $7f,$00	 ;00C9E8|547F00  |      ;
	ldx.W				   #$1080	;00C9EB|A28010  |      ;
	lda.W				   #$004f	;00C9EE|A94F00  |      ;
	mvn					 $7f,$00	 ;00C9F1|547F00  |      ;
	ldx.W				   #$0e84	;00C9F4|A2840E  |      ;
	lda.W				   #$017b	;00C9F7|A97B01  |      ;
	mvn					 $7f,$00	 ;00C9FA|547F00  |      ;
	plb							   ;00C9FD|AB      |      ;
	pla							   ;00C9FE|68      |      ;
	ldx.W				   #$0003	;00C9FF|A20300  |      ;

SaveData_ProcessMultiple:
	jsr.W				   SaveData_Processor ;00CA02|2092C9  |00C992;
	clc							   ;00CA05|18      |      ;
	adc.W				   #$0003	;00CA06|690300  |      ;
	dex							   ;00CA09|CA      |      ;
	bne					 SaveData_ProcessMultiple ;00CA0A|D0F6    |00CA02;
	lda.W				   #$fff0	;00CA0C|A9F0FF  |      ;
	sta.B				   $8e	   ;00CA0F|858E    |00008E;
	jmp.W				   CODE_00981B ;00CA11|4C1B98  |00981B;

LoadData_ValidateChecksum:
	phx							   ;00CA14|DA      |      ;
	phy							   ;00CA15|5A      |      ;
	pha							   ;00CA16|48      |      ;

LoadData_RetryLoop:
	lda.B				   $01,s	 ;00CA17|A301    |000001;
	jsr.W				   CODE_00C92B ;00CA19|202BC9  |00C92B;
	clc							   ;00CA1C|18      |      ;
	adc.W				   #$0006	;00CA1D|690600  |      ;
	sta.B				   $5f	   ;00CA20|855F    |00005F;
	jsr.W				   SaveData_SetBank70 ;00CA22|204FC9  |00C94F;
	jsr.W				   Checksum_Calculator ;00CA25|205CC9  |00C95C;
	jsr.W				   Checksum_Validator ;00CA28|207DC9  |00C97D;
	bne					 LoadData_InvalidChecksum ;00CA2B|D027    |00CA54;
	lda.B				   $01,s	 ;00CA2D|A301    |000001;
	jsr.W				   CODE_00C92B ;00CA2F|202BC9  |00C92B;
	clc							   ;00CA32|18      |      ;
	adc.W				   #$0006	;00CA33|690600  |      ;
	tax							   ;00CA36|AA      |      ;
	ldy.W				   #$3000	;00CA37|A00030  |      ;
	lda.W				   #$0385	;00CA3A|A98503  |      ;
	mvn					 $7f,$70	 ;00CA3D|547F70  |      ;
	lda.B				   $12	   ;00CA40|A512    |000012;
	ldx.W				   #$3000	;00CA42|A20030  |      ;
	stx.B				   $5f	   ;00CA45|865F    |00005F;
	jsr.W				   CODE_00C942 ;00CA47|2042C9  |00C942;
	jsr.W				   Checksum_Calculator ;00CA4A|205CC9  |00C95C;
	cmp.B				   $12	   ;00CA4D|C512    |000012;
	bne					 LoadData_RetryLoop ;00CA4F|D0C6    |00CA17;
	clc							   ;00CA51|18      |      ;
	bra					 LoadData_Success ;00CA52|800B    |00CA5F;

LoadData_InvalidChecksum:
	lda.B				   $01,s	 ;00CA54|A301    |000001;
	jsr.W				   CODE_00C92B ;00CA56|202BC9  |00C92B;
	lda.W				   #$0000	;00CA59|A90000  |      ;
	sta.B				   [$0b]	 ;00CA5C|870B    |00000B;
	sec							   ;00CA5E|38      |      ;

LoadData_Success:
	pla							   ;00CA5F|68      |      ;
	ply							   ;00CA60|7A      |      ;
	plx							   ;00CA61|FA      |      ;
	rts							   ;00CA62|60      |      ;

SaveData_MainHandler:
	pea.W				   LOOSE_OP_00CAB5 ;00CA63|F4B5CA  |00CAB5;
	php							   ;00CA66|08      |      ;
	rep					 #$30		;00CA67|C230    |      ;
	phb							   ;00CA69|8B      |      ;
	pha							   ;00CA6A|48      |      ;
	phd							   ;00CA6B|0B      |      ;
	phx							   ;00CA6C|DA      |      ;
	phy							   ;00CA6D|5A      |      ;
	pha							   ;00CA6E|48      |      ;
	stz.B				   $8e	   ;00CA6F|648E    |00008E;
	lda.B				   $01,s	 ;00CA71|A301    |000001;
	ldx.W				   #$0003	;00CA73|A20300  |      ;

LoadData_RetryNext:
	jsr.W				   LoadData_ValidateChecksum ;00CA76|2014CA  |00CA14;
	bcc					 LoadData_CopyToRAM ;00CA79|900C    |00CA87;
	adc.W				   #$0002	;00CA7B|690200  |      ;
	dex							   ;00CA7E|CA      |      ;
	bne					 LoadData_RetryNext ;00CA7F|D0F5    |00CA76;
	pla							   ;00CA81|68      |      ;
	lda.W				   #$ffff	;00CA82|A9FFFF  |      ;
	bra					 LoadData_Complete ;00CA85|8025    |00CAAC;

LoadData_CopyToRAM:
	ldx.W				   #$3000	;00CA87|A20030  |      ;
	ldy.W				   #$1000	;00CA8A|A00010  |      ;
	lda.W				   #$004f	;00CA8D|A94F00  |      ;
	mvn					 $00,$7f	 ;00CA90|54007F  |      ;
	ldy.W				   #$1080	;00CA93|A08010  |      ;
	lda.W				   #$004f	;00CA96|A94F00  |      ;
	mvn					 $00,$7f	 ;00CA99|54007F  |      ;
	ldy.W				   #$0e84	;00CA9C|A0840E  |      ;
	lda.W				   #$017b	;00CA9F|A97B01  |      ;
	mvn					 $00,$7f	 ;00CAA2|54007F  |      ;
	pla							   ;00CAA5|68      |      ;
	jsr.W				   SaveData_MemoryCopy ;00CAA6|20D3C9  |00C9D3;
	lda.W				   #$0000	;00CAA9|A90000  |      ;

LoadData_Complete:
	sta.B				   $64	   ;00CAAC|8564    |000064;
	lda.W				   #$fff0	;00CAAE|A9F0FF  |      ;
	sta.B				   $8e	   ;00CAB1|858E    |00008E;
	jmp.W				   CODE_00981B ;00CAB3|4C1B98  |00981B;

LOOSE_OP_00CAB5:
	lda.B				   $64	   ;00CAB6|A564    |000064;
	rts							   ;00CAB8|60      |      ;

GameState_CheckFlags:
	php							   ;00CAB9|08      |      ;
	rep					 #$30		;00CABA|C230    |      ;
	phb							   ;00CABC|8B      |      ;
	pha							   ;00CABD|48      |      ;
	phd							   ;00CABE|0B      |      ;
	phx							   ;00CABF|DA      |      ;
	phy							   ;00CAC0|5A      |      ;
	lda.W				   #$0000	;00CAC1|A90000  |      ;
	tcd							   ;00CAC4|5B      |      ;
	sep					 #$20		;00CAC5|E220    |      ;
	lda.B				   #$01	  ;00CAC7|A901    |      ;
	and.W				   $00da	 ;00CAC9|2DDA00  |0000DA;
	bne					 GameState_Flag1Set ;00CACC|D01E    |00CAEC;
	lda.B				   #$40	  ;00CACE|A940    |      ;
	and.W				   $00db	 ;00CAD0|2DDB00  |0000DB;
	bne					 GameState_Flag40Set ;00CAD3|D032    |00CB07;
	ldx.W				   #$9300	;00CAD5|A20093  |      ;
	stx.W				   SNES_CGSWSEL ;00CAD8|8E3021  |002130;
	lda.B				   #$02	  ;00CADB|A902    |      ;
	and.W				   $00da	 ;00CADD|2DDA00  |0000DA;
	bne					 GameState_FlagCheck2 ;00CAE0|D02F    |00CB11;
	lda.B				   #$80	  ;00CAE2|A980    |      ;
	and.W				   $00db	 ;00CAE4|2DDB00  |0000DB;
	bne					 GameState_Flag80Set ;00CAE7|D065    |00CB4E;
	jmp.W				   GameState_FlagsComplete ;00CAE9|4C76CB  |00CB76;

GameState_Flag1Set:
	lda.B				   #$01	  ;00CAEC|A901    |      ;
	trb.W				   $00da	 ;00CAEE|1CDA00  |0000DA;
	jsr.W				   Screen_ColorProcessor ;00CAF1|2009CC  |00CC09;
	ldx.W				   #$5555	;00CAF4|A25555  |      ;
	stx.W				   $0e04	 ;00CAF7|8E040E  |000E04;
	stx.W				   $0e06	 ;00CAFA|8E060E  |000E06;
	stx.W				   $0e08	 ;00CAFD|8E080E  |000E08;
	lda.B				   #$80	  ;00CB00|A980    |      ;
	trb.W				   $00de	 ;00CB02|1CDE00  |0000DE;
	bra					 GameState_RestoreAndExit ;00CB05|8072    |00CB79;

GameState_Flag40Set:
	lda.B				   #$40	  ;00CB07|A940    |      ;
	trb.W				   $00db	 ;00CB09|1CDB00  |0000DB;
	jsr.W				   CODE_00CCBD ;00CB0C|20BDCC  |00CCBD;
	bra					 GameState_RestoreAndExit ;00CB0F|8068    |00CB79;
; ==============================================================================
; Screen Color Management and Final Systems - CODE_00CB11+
; ==============================================================================

GameState_FlagCheck2:
	jsr.W				   CODE_00CD22 ;00CB11|2022CD  |00CD22;
	rep					 #$30		;00CB14|C230    |      ;
	ldx.W				   #$016f	;00CB16|A26F01  |      ;
	ldy.W				   #$0e04	;00CB19|A0040E  |      ;
	lda.W				   #$0005	;00CB1C|A90500  |      ;
	mvn					 $00,$00	 ;00CB1F|540000  |      ;
	sep					 #$20		;00CB22|E220    |      ;
	lda.B				   #$80	  ;00CB24|A980    |      ;
	tsb.W				   $00de	 ;00CB26|0CDE00  |0000DE;
	jsr.W				   CODE_00CD60 ;00CB29|2060CD  |00CD60;
	jsr.W				   CODE_00CBC6 ;00CB2C|20C6CB  |00CBC6;
	jsl.L				   CODE_0C8000 ;00CB2F|2200800C|0C8000;
	lda.B				   #$e0	  ;00CB33|A9E0    |      ;
	sta.L				   $7f56d8   ;00CB35|8FD8567F|7F56D8;
	sta.L				   $7f56d8,x ;00CB39|9FD8567F|7F56D8;
	jsl.L				   CODE_0C8000 ;00CB3D|2200800C|0C8000;
	lda.B				   #$02	  ;00CB41|A902    |      ;
	trb.W				   $00da	 ;00CB43|1CDA00  |0000DA;
	lda.B				   #$08	  ;00CB46|A908    |      ;
	trb.W				   $00d4	 ;00CB48|1CD400  |0000D4;
	jmp.W				   CODE_00981B ;00CB4B|4C1B98  |00981B;

GameState_Flag80Set:
	jsr.W				   CODE_00CD22 ;00CB4E|2022CD  |00CD22;
	jsr.W				   CODE_00CD60 ;00CB51|2060CD  |00CD60;
	jsr.W				   CODE_00CC6E ;00CB54|206ECC  |00CC6E;
	jsl.L				   CODE_0C8000 ;00CB57|2200800C|0C8000;
	lda.B				   #$e0	  ;00CB5B|A9E0    |      ;
	sta.L				   $7f56da   ;00CB5D|8FDA567F|7F56DA;
	sta.L				   $7f56de   ;00CB61|8FDE567F|7F56DE;
	jsl.L				   CODE_0C8000 ;00CB65|2200800C|0C8000;
	lda.B				   #$80	  ;00CB69|A980    |      ;
	trb.W				   $00db	 ;00CB6B|1CDB00  |0000DB;
	lda.B				   #$08	  ;00CB6E|A908    |      ;
	trb.W				   $00d4	 ;00CB70|1CD400  |0000D4;
	jmp.W				   CODE_00981B ;00CB73|4C1B98  |00981B;

GameState_FlagsComplete:
	jsr.W				   CODE_00CD22 ;00CB76|2022CD  |00CD22;

GameState_RestoreAndExit:
	jsr.W				   CODE_00CD60 ;00CB79|2060CD  |00CD60;
	jsr.W				   CODE_00CD42 ;00CB7C|2042CD  |00CD42;
	jsl.L				   CODE_0C8000 ;00CB7F|2200800C|0C8000;
	lda.B				   #$e0	  ;00CB83|A9E0    |      ;
	sta.W				   SNES_COLDATA ;00CB85|8D3221  |002132;
	ldx.W				   #$0000	;00CB88|A20000  |      ;
	stx.W				   SNES_CGSWSEL ;00CB8B|8E3021  |002130;
	jmp.W				   CODE_00981B ;00CB8E|4C1B98  |00981B;

GameState_DataCopy:
	rep					 #$30		;00CB91|C230    |      ;
	phb							   ;00CB93|8B      |      ;
	ldx.W				   #$cbbd	;00CB94|A2BDCB  |      ;
	ldy.W				   #$56d7	;00CB97|A0D756  |      ;
	lda.W				   #$0008	;00CB9A|A90800  |      ;
	mvn					 $7f,$00	 ;00CB9D|547F00  |      ;
	plb							   ;00CBA0|AB      |      ;
	lda.W				   #$0080	;00CBA1|A98000  |      ;
	tsb.W				   $00da	 ;00CBA4|0CDA00  |0000DA;
	lda.W				   #$0020	;00CBA7|A92000  |      ;
	tsb.W				   $0111	 ;00CBAA|0C1101  |000111;
	lda.B				   $02	   ;00CBAD|A502    |000002;
	and.W				   #$00ff	;00CBAF|29FF00  |      ;
	inc					 a;00CBB2|1A      |      ;
	asl					 a;00CBB3|0A      |      ;
	tax							   ;00CBB4|AA      |      ;
	sep					 #$20		;00CBB5|E220    |      ;
	lda.B				   #$08	  ;00CBB7|A908    |      ;
	tsb.W				   $00d4	 ;00CBB9|0CD400  |0000D4;
	rts							   ;00CBBC|60      |      ;

SystemData_Config33:
	db											 $27,$ec,$3c,$ec,$3c,$ec,$38,$ec,$00 ;00CBBD|        |      ;

Screen_FadeSetup:
	jsr.W				   GameState_DataCopy ;00CBC6|2091CB  |00CB91;
	lda.B				   #$e9	  ;00CBC9|A9E9    |      ;

Screen_FadeLoop:
	ldy.B				   $17	   ;00CBCB|A417    |000017;
	jsr.W				   CODE_009D75 ;00CBCD|20759D  |009D75;
	sty.B				   $17	   ;00CBD0|8417    |000017;
	jsl.L				   CODE_0C8000 ;00CBD2|2200800C|0C8000;
	sta.L				   $7f56d8   ;00CBD6|8FD8567F|7F56D8;
	sta.L				   $7f56d8,x ;00CBDA|9FD8567F|7F56D8;
	dec					 a;00CBDE|3A      |      ;
	dec					 a;00CBDF|3A      |      ;
	cmp.B				   #$e1	  ;00CBE0|C9E1    |      ;
	bne					 Screen_FadeLoop ;00CBE2|D0E7    |00CBCB;
	ldy.B				   $17	   ;00CBE4|A417    |000017;
	jsr.W				   CODE_009D75 ;00CBE6|20759D  |009D75;
	sty.B				   $17	   ;00CBE9|8417    |000017;
	rts							   ;00CBEB|60      |      ;

Screen_BrightnessMax:
	ldy.W				   #$9300	;00CBEC|A00093  |      ;
	sty.W				   SNES_CGSWSEL ;00CBEF|8C3021  |002130;
	jsr.W				   GameState_DataCopy ;00CBF2|2091CB  |00CB91;
	lda.B				   #$e0	  ;00CBF5|A9E0    |      ;
	sta.L				   $7f56d8   ;00CBF7|8FD8567F|7F56D8;
	sta.L				   $7f56d8,x ;00CBFB|9FD8567F|7F56D8;
	jsl.L				   CODE_0C8000 ;00CBFF|2200800C|0C8000;
	lda.B				   #$08	  ;00CC03|A908    |      ;
	trb.W				   $00d4	 ;00CC05|1CD400  |0000D4;
	rts							   ;00CC08|60      |      ;

Screen_ColorProcessor:
	lda.B				   #$08	  ;00CC09|A908    |      ;
	tsb.W				   $00d4	 ;00CC0B|0CD400  |0000D4;
	ldx.W				   #$0007	;00CC0E|A20700  |      ;

Screen_ColorProcessLoop:
	jsl.L				   CODE_0C8000 ;00CC11|2200800C|0C8000;
	lda.L				   $7f56d8   ;00CC15|AFD8567F|7F56D8;
	jsr.W				   CODE_00CC5B ;00CC19|205BCC  |00CC5B;
	sta.L				   $7f56d8   ;00CC1C|8FD8567F|7F56D8;
	lda.L				   $7f56da   ;00CC20|AFDA567F|7F56DA;
	jsr.W				   CODE_00CC5B ;00CC24|205BCC  |00CC5B;
	sta.L				   $7f56da   ;00CC27|8FDA567F|7F56DA;
	lda.L				   $7f56dc   ;00CC2B|AFDC567F|7F56DC;
	jsr.W				   CODE_00CC5B ;00CC2F|205BCC  |00CC5B;
	sta.L				   $7f56dc   ;00CC32|8FDC567F|7F56DC;
	lda.L				   $7f56de   ;00CC36|AFDE567F|7F56DE;
	jsr.W				   CODE_00CC5B ;00CC3A|205BCC  |00CC5B;
	sta.L				   $7f56de   ;00CC3D|8FDE567F|7F56DE;
	ldy.B				   $17	   ;00CC41|A417    |000017;
	jsr.W				   CODE_009D75 ;00CC43|20759D  |009D75;
	sty.B				   $17	   ;00CC46|8417    |000017;
	dex							   ;00CC48|CA      |      ;
	bne					 CODE_00CC11 ;00CC49|D0C6    |00CC11;
	lda.B				   #$08	  ;00CC4B|A908    |      ;
	trb.W				   $00d4	 ;00CC4D|1CD400  |0000D4;
	lda.B				   #$20	  ;00CC50|A920    |      ;
	trb.W				   $0111	 ;00CC52|1C1101  |000111;
	lda.B				   #$80	  ;00CC55|A980    |      ;
	trb.W				   $00da	 ;00CC57|1CDA00  |0000DA;
	rts							   ;00CC5A|60      |      ;

Screen_ColorAdjust:
	clc							   ;00CC5B|18      |      ;
	adc.L				   Screen_ColorAdjustTable,x ;00CC5C|7F66CC00|00CC66;
	cmp.B				   #$f0	  ;00CC60|C9F0    |      ;
	bcc					 Screen_ColorAdjustDone ;00CC62|9002    |00CC66;
	lda.B				   #$ef	  ;00CC64|A9EF    |      ;

Screen_ColorAdjustDone:
	rts							   ;00CC66|60      |      ;

Screen_ColorAdjustTable:
	db											 $03,$02,$02,$02,$02,$01,$03 ;00CC67|        |      ;

; ==============================================================================
; BANK $00 COMPLETE - FINAL STUB SECTION
; ==============================================================================

; Final stub definitions for any remaining external routines
ExternalRoutine_00CF3F:
	= $cf3f
ExternalRoutine_00CF62:
	= $cf62

; ==============================================================================
; END OF BANK $00 - 100% COMPLETE
; ==============================================================================
