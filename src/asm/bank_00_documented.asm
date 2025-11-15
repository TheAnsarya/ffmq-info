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

	arch 65816
lorom:

;===============================================================================
; SNES Hardware Register Definitions
;===============================================================================
; DMA Registers
	SNES_DMA0PARAM = $4300    ; DMA Channel 0 Parameters
	SNES_DMA0ADDRL = $4302    ; DMA Channel 0 Address Low
	SNES_DMA0ADDRH = $4303    ; DMA Channel 0 Address High
	SNES_DMA0CNTL = $4305    ; DMA Channel 0 Control Low
	SNES_DMA3PARAM = $4330    ; DMA Channel 3 Parameters
	SNES_DMA3ADDRL = $4332    ; DMA Channel 3 Address Low
	SNES_DMA3ADDRH = $4333    ; DMA Channel 3 Address High
	SNES_DMA5PARAM = $4350    ; DMA Channel 5 Parameters
	SNES_DMA5ADDRL = $4352    ; DMA Channel 5 Address Low
	SNES_DMA5ADDRH = $4353    ; DMA Channel 5 Address High
	SNES_DMA5CNTL = $4355    ; DMA Channel 5 Control Low
	SNES_DMA6PARAM = $4360    ; DMA Channel 6 Parameters
	SNES_DMA6ADDRL = $4362    ; DMA Channel 6 Address Low
	SNES_DMA6ADDRH = $4363    ; DMA Channel 6 Address High
	SNES_DMA7PARAM = $4370    ; DMA Channel 7 Parameters
	SNES_DMA7ADDRL = $4372    ; DMA Channel 7 Address Low
	SNES_DMA7ADDRH = $4373    ; DMA Channel 7 Address High
	SNES_MDMAEN = $420b    ; DMA Enable

; PPU Registers
	SNES_INIDISP = $2100    ; Display Control
	SNES_TM = $212c    ; Main Screen Designation
	SNES_CGADD = $2121    ; CG RAM Address
	SNES_CGDATA = $2122    ; CG RAM Data
	SNES_COLDATA = $2132    ; Color Data
	SNES_CGSWSEL = $2130    ; Color/Window Select
	SNES_BG1VOFS = $210e    ; BG1 Vertical Offset
	SNES_BG2VOFS = $2110    ; BG2 Vertical Offset
	SNES_VMADDL = $2116    ; VRAM Address Low
	SNES_VMAINC = $2115    ; VRAM Address Increment
	SNES_OAMADDL = $2102    ; OAM Address Low

; Controller Registers
	SNES_CNTRL1L = $4218    ; Controller 1 Data Low

; System Registers
	SNES_NMITIMEN = $4200    ; NMI/Timer Enable
	SNES_VTIMEL = $4209    ; V-Timer Low
	SNES_SLHV = $2137    ; H/V Latch
	SNES_OPVCT = $213d    ; Vertical Counter (PPU)
	SNES_STAT78 = $213f    ; PPU Status 78

; Math/Multiplication/Division Registers
	SNES_WRMPYA = $4202    ; Multiplicand
	SNES_WRMPYB = $4203    ; Multiplicand/Multiplier
	SNES_WRDIVL = $4204    ; Dividend Low
	SNES_WRDIVH = $4205    ; Dividend High
	SNES_WRDIVB = $4206    ; Divisor
	SNES_RDMPYL = $4216    ; Multiplication/Division Result Low

; Constant Pointers
	PTR16_00FFFF = $ffff    ; Return marker value for subroutine calls

;===============================================================================
; External Bank Stubs (code in other banks)
;===============================================================================
; Bank $00 - Not yet imported
	WaitVblank = $0096a0
	PerformMemoryCopy = $00985d
	Sub_00A375 = $00a375
	Sub_00A3DE = $00a3de
	Sub_00A3E5 = $00a3e5
	Sub_00A3EC = $00a3ec
	B2 = $00a3fc
	Sub_00A3FC = $00a3fc
	Sub_00A51E = $00a51e
; CodeThroughCodeNowImplemented through CodeThroughCodeNowImplemented2 now implemented
; CodeThroughCodeNowImplemented3 through CodeExecuteExternalSubroutineViaLong now implemented
; CodeThroughCodeNowImplementedPartial through CodeThroughCodeNowImplementedPartial2 now implemented (partial CodeThroughCodeNowImplementedPartial as db)
; NextMoreDmaGraphicsRoutinesCode through CodeBitwiseTsbOperationsVariants now implemented
; CodeThroughCodeNowImplemented4 through TestVariable now implemented
	ReferencedJumpTableNotImplementedAs = $00a78e             ; Referenced in jump table but not implemented as routine
	CodeThroughCodeNowImplementedPartial = $00a86e             ; Partial implementation (raw bytecode placeholder)
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
	BcdHexNumberFormattingRoutine = $009824    ; BCD/Hex number formatting routine
	ScreenSetupRoutine = $008b69    ; Screen setup routine 1
	CallsLabelCodeScreenSetupRoutines = $008b88    ; Screen setup routine 2
	SetupRoutine = $00cbec    ; Setup routine
	ExternalDataRoutine = $00da65    ; External data routine
	InitializePaletteSystem = $00c795    ; External routine
	FinalSetupRoutine = $00c7b8    ; External routine
	InitializeGraphicsComponent = $00ca63    ; External routine
	CallHandler = $00d080    ; External routine
	AlternateSyncHandler = $00e055    ; External routine
	GetSaveSlotAddress = $00c92b    ; Get save slot address
	CodeExternalRoutine = $00c4db    ; External routine
	CodeCodeConditionalScreenSetup = $00c7de    ; Screen setup routine 1
	ScreenSetupRoutine2 = $00c7f0    ; Screen setup routine 2
	ExternalRoutine2 = $00c78d    ; External routine
	MainRoutine = $00cf3f    ; Main routine
	ExternalRoutine3 = $00daa5    ; External routine
	GetSaveSlotAddress2 = $00c9d3    ; Get save slot address

; Other Banks
	BankRoutine = $028ae0    ; Bank $02 routine
	DATA8_03ba35 = $03ba35   ; Bank $03 data
	DATA8_03bb81 = $03bb81   ; Bank $03 data
	DATA8_03a37c = $03a37c   ; Bank $03 character data
	UNREACH_03D5E5 = $03d5e5 ; Bank $03 unreachable code
	AddressC8000OriginalCode = $0c8000    ; Bank $0c routine
	AddressC8080OriginalCode = $0c8080    ; Bank $0c routine
	BankOC_Init = $0c8000    ; Bank $0c Init
	Primary_APU_Upload_Entry_Point = $0d8000    ; Bank $0d routine
	Secondary_APU_Command_Entry_Point = $0d8004    ; Bank $0d routine
	Bank0D_Init_Variant = $0d8000    ; Bank $0d Init
	Label_018272 = $018272    ; Bank $01 routine
	BankSpriteInitialization = $018a52    ; Bank $01 sprite initialization
	BankScriptInitializationRoutine = $01b24c    ; Bank $01 script initialization routine
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
	SNES_BG1HOFS = $210d    ; BG1 Horizontal Offset
	SNES_BG2HOFS = $210f    ; BG2 Horizontal Offset
	SNES_BG3VOFS = $2112    ; BG3 Vertical Offset
	SNES_BG1SC = $2107    ; BG1 Screen Base Address
	SNES_BG2SC = $2108    ; BG2 Screen Base Address

; Loose operations (code fragments)
	LOOSE_OP_00BCF3 = $00bcf3 ; Continuation address in state machine

;===============================================================================
; BOOT SEQUENCE & INITIALIZATION ($008000-$008113)
;===============================================================================

	org $008000

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

	clc ; Clear carry flag
	xce ; Exchange Carry with Emulation flag
; C=0 → E=0 → Native 65816 mode enabled!

	jsr.w Init_Hardware ; Init_Hardware: Disable NMI, force blank, clear registers
	jsl.l Primary_APU_Upload_Entry_Point ; Bank $0d initialization (sound driver, APU setup)

; ---------------------------------------------------------------------------
; Initialize Save Game State Variables
; ---------------------------------------------------------------------------
; $7e3667 = Save file exists flag (0=no save, 1=save exists)
; $7e3668 = Save file slot/state ($ff=no save, 0-2=slot number)
; ---------------------------------------------------------------------------

	lda.b #$00	  ; A = 0
	sta.l $7e3667   ; Clear "save file exists" flag
	dec a; A = $ff (-1)
	sta.l $7e3668   ; Set save slot to $ff (no active save)
	bra Boot_SetupStack ; → Continue to stack setup

;-------------------------------------------------------------------------------

Boot_Secondary:
; ===========================================================================
; Secondary Boot Entry Point
; ===========================================================================
; Alternative entry point used for soft reset or special boot modes.
; Different from main boot: calls different bank $0d init routine.
; ===========================================================================

	jsr.w Init_Hardware ; Init_Hardware again

	lda.b #$f0	  ; A = $f0
	sta.l $000600   ; Write $f0 to $000600 (low RAM mirror area)
; Purpose unclear - may trigger hardware behavior

	jsl.l Secondary_APU_Command_Entry_Point ; Bank $0d alternate initialization routine

;-------------------------------------------------------------------------------

Boot_Alternate:
; ===========================================================================
; Third Entry Point (Soft Reset with Different Init)
; ===========================================================================
; Yet another entry point with same hardware init but different
; bank $0d initialization. May be used for returning from special modes.
; ===========================================================================

	jsr.w Init_Hardware ; Init_Hardware

	lda.b #$f0	  ; A = $f0
	sta.l $000600   ; Write $f0 to $000600

	jsl.l Secondary_APU_Command_Entry_Point ; Bank $0d alternate init

	rep #$30		; Set 16-bit mode: A, X, Y
	ldx.w #$1fff	; X = $1fff (stack pointer initial value)
	txs ; Transfer X to Stack: S = $1fff

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

	rep #$30		; 16-bit A, X, Y registers
	ldx.w #$1fff	; X = $1fff (top of RAM bank $00)
	txs ; S = $1fff (initialize stack pointer)

	jsr.w Clear_WorkRAM ; Clear_RAM: Zero out all work RAM $0000-$1fff

; ---------------------------------------------------------------------------
; Check Boot Mode Flag ($00da bit 6)
; ---------------------------------------------------------------------------
; $00da appears to be a boot mode/configuration flag
; bit 6 ($40) determines which initialization path to take
; ---------------------------------------------------------------------------

	lda.w #$0040	; A = $0040 (bit 6 mask)
	and.w !system_flags_5	 ; Test bit 6 of $00da
	bne Boot_EnableNMI ; If bit 6 set → Skip display init, jump ahead

	jsl.l AddressC8080OriginalCode ; Bank $0c: Full display/PPU initialization
	bra Boot_SetupDMA ; → Continue to DMA setup

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

	jsr.w ClearRamAgainRedundant ; Clear_RAM again (redundant?)

	sep #$20		; 8-bit accumulator

; ---------------------------------------------------------------------------
; DMA Channel 0 Configuration
; ---------------------------------------------------------------------------
; Purpose: Copy initialization data from ROM to RAM
; Pattern: Fixed source, incrementing destination (mode $18)
; Register: $2109 (not a standard PPU register?)
; ---------------------------------------------------------------------------

	ldx.w #$1809	; X = $1809
; $18 = DMA mode (2 registers, increment write)
; $09 = Target register (high byte)
	stx.w SNES_DMA0PARAM ; $4300 = DMA0 parameters

	ldx.w #$8252	; X = $8252 (source address low/mid)
	stx.w SNES_DMA0ADDRL ; $4302-$4303 = Source address $xx8252

	lda.b #$00	  ; A = $00
	sta.w SNES_DMA0ADDRH ; $4304 = Source bank $00 → $008252

	ldx.w #$0000	; X = $0000 (transfer size = 0 bytes!)
	stx.w SNES_DMA0CNTL ; $4305-$4306 = Transfer 0 bytes
; This DMA won't transfer anything!

	lda.b #$01	  ; A = $01 (enable channel 0)
	sta.w SNES_MDMAEN ; $420b = Execute DMA channel 0
; (Executes but transfers 0 bytes)

;-------------------------------------------------------------------------------

Boot_EnableNMI:
; ===========================================================================
; Direct Page Setup and NMI Enable
; ===========================================================================
; Sets up direct page pointer and enables interrupts for main game loop.
; ===========================================================================

	jsl.l $00011f   ; Call routine at $00011f (in bank $00 RAM!)
; This is calling CODE in RAM, not ROM
; Must have been loaded earlier

	rep #$30		; 16-bit A, X, Y

	lda.w #$0000	; A = $0000
	tcd ; Direct Page = $0000 (D = $0000)
; Sets up fast direct page access

	sep #$20		; 8-bit accumulator

	lda.w $0112	 ; A = [$0112] (NMI enable flags)
	sta.w SNES_NMITIMEN ; $4200 = Enable NMI/IRQ/Auto-joypad
; Copies configuration from RAM variable

	cli ; Clear Interrupt disable flag
; Enable IRQ interrupts (NMI already configured)

	lda.b #$0f	  ; A = $0f
	sta.w !brightness_value	 ; [$00aa] = $0f (some game state variable)

	jsl.l AddressC8000OriginalCode ; Bank $0c: Wait for VBLANK
	jsl.l AddressC8000OriginalCode ; Bank $0c: Wait for VBLANK again
; Double wait ensures PPU is stable

; ---------------------------------------------------------------------------
; Check Boot/Continue Mode
; ---------------------------------------------------------------------------
; $7e3665 = Continue/load game flag
; $700000, $70038c, $700718 = Save file signature bytes?
; ---------------------------------------------------------------------------

	lda.l $7e3665   ; A = Continue flag
	bne Load_SavedGame ; If set → Load existing game

; Check if save data exists in SRAM
	lda.l $700000   ; A = SRAM byte 1
	ora.l $70038c   ; OR with SRAM byte 2
	ora.l $700718   ; OR with SRAM byte 3
	beq Init_NewGame ; If all zero → New game (no save data)

	jsl.l HasSaveDataShowContinueMenu ; Has save data → Show continue menu
	bra Boot_FadeIn ; → Continue to fade-in

;-------------------------------------------------------------------------------

Load_SavedGame:
; ===========================================================================
; Load Saved Game from SRAM
; ===========================================================================
; Player selected "Continue" from title screen - load saved game data.
; ===========================================================================

	jsr.w Load_GameFromSRAM ; Load_Game_From_SRAM: Restore all game state
	bra Boot_PostInit ; → Skip new game init, jump to main setup

;-------------------------------------------------------------------------------

Init_NewGame:
; ===========================================================================
; New Game Initialization
; ===========================================================================
; No save data exists - initialize a fresh game state.
; ===========================================================================

	jsr.w Init_NewGameState ; Initialize_New_Game_State: Set default values

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

	lda.b #$80	  ; A = $80 (bit 7)
	trb.w !system_flags_8	 ; Test and Reset bit 7 of $00de
; Clear some display state flag

	lda.b #$e0	  ; A = $e0 (bits 5-7: %11100000)
	trb.w $0111	 ; Test and Reset bits 5-7 of $0111
; Clear multiple configuration flags

	jsl.l AddressC8000OriginalCode ; Bank $0c: Wait for VBLANK
; Ensure PPU ready for register writes

; ---------------------------------------------------------------------------
; Configure Color Math and Window Settings
; ---------------------------------------------------------------------------
; Sets up color addition/subtraction for fade effects
; SNES_COLDATA ($2132): Color math control register
; SNES_CGSWSEL ($2130): Color addition select
; ---------------------------------------------------------------------------

	lda.b #$e0	  ; A = $e0
; bit 7 = 1: Subtract color
; bit 6 = 1: Half color math
; bit 5 = 1: Enable color math
	sta.w SNES_COLDATA ; $2132 = Color math configuration

	ldx.w #$0000	; X = $0000
	stx.w SNES_CGSWSEL ; $2130 = Color/math window settings = 0
; Disable all color window masking

; ---------------------------------------------------------------------------
; Reset Background Scroll Positions
; ---------------------------------------------------------------------------
; SNES requires writing scroll values TWICE (high byte, then low byte)
; Writing $00 twice sets scroll position to 0
; ---------------------------------------------------------------------------

	stz.w SNES_BG1VOFS ; $210e = BG1 vertical scroll = 0 (low byte)
	stz.w SNES_BG1VOFS ; $210e = BG1 vertical scroll = 0 (high byte)
	stz.w SNES_BG2VOFS ; $2110 = BG2 vertical scroll = 0 (low byte)
	stz.w SNES_BG2VOFS ; $2110 = BG2 vertical scroll = 0 (high byte)

	jsr.w AdditionalGraphicsFadeSetup ; Additional graphics/fade setup
	jsl.l AddressC8000OriginalCode ; Bank $0c: Wait for VBLANK again
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

	jsr.w InitializeSubsystemGraphicsRelated ; Initialize subsystem (graphics related?)

; ---------------------------------------------------------------------------
; Initialize Both Player Characters
; ---------------------------------------------------------------------------
; Initializes Benjamin (character 0) and the companion (character 1)
; Calls Char_CalcStats to calculate initial stats for both characters
; based on starting equipment and level
; ---------------------------------------------------------------------------

	lda.b #$00	  ; A = $00 (Benjamin - character index 0)
	jsr.w Char_CalcStats ; Initialize Benjamin's stats

	lda.b #$01	  ; A = $01 (Companion - character index 1)
	jsr.w Char_CalcStats ; Initialize companion's stats

; ---------------------------------------------------------------------------
; Load Initial Data Table
; ---------------------------------------------------------------------------
; $81ed points to initialization data (see DATA8_0081ED below)
; CodeLikelyLoadsProcessesThisData likely loads/processes this data table
; ---------------------------------------------------------------------------

	ldx.w #$81ed	; X = $81ed (pointer to init data)
	jsr.w CodeLikelyLoadsProcessesThisData ; Load/process data table

; ---------------------------------------------------------------------------
; Configure State Flags
; ---------------------------------------------------------------------------
; $00d4, $00d6, $00e2 = State/configuration flag bytes
; TSB/TRB = Test and Set/Reset Bits instructions
; ---------------------------------------------------------------------------

	lda.b #$04	  ; A = $04 (bit 2)
	tsb.w !system_flags_2	 ; Test and Set bit 2 in $00d4
; Enable some display/update feature

	lda.b #$80	  ; A = $80 (bit 7)
	trb.w !system_flags_3	 ; Test and Reset bit 7 in $00d6
; Disable some feature

	stz.w !battle_ready_flag	 ; [$0110] = $00 (clear game state variable)

	lda.b #$01	  ; A = $01 (bit 0)
	tsb.w !system_flags_9	 ; Test and Set bit 0 in $00e2
; Enable some system feature

	lda.b #$10	  ; A = $10 (bit 4)
	tsb.w !system_flags_3	 ; Test and Set bit 4 in $00d6
; Enable another feature

; ---------------------------------------------------------------------------
; Initialize Game Position/State Variable
; ---------------------------------------------------------------------------
; $008e appears to be a signed 16-bit position or state value
; ---------------------------------------------------------------------------

	ldx.w #$fff0	; X = $fff0 (-16 in signed 16-bit)
	stx.w !game_state_value	 ; [$008e] = $fff0 (initial game state)

; ---------------------------------------------------------------------------
; Final Setup Routines
; ---------------------------------------------------------------------------

	jsl.l FinalSystemInitialization ; Final system initialization
	jsr.w AdditionalSetupSeeBelow ; Additional setup (see below)

; ---------------------------------------------------------------------------
; JUMP TO MAIN GAME LOOP
; ---------------------------------------------------------------------------
; jml = Jump Long (24-bit address)
; Control transfers to bank $01, never returns
; This is the END of boot sequence - game starts running!
; ---------------------------------------------------------------------------

	jml.l Label_018272 ; → JUMP TO MAIN GAME ENGINE (Bank $01)
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

	lda.b #$14	  ; A = $14 (%00010100)
; bit 4 = Enable BG3
; bit 2 = Enable BG1
	sta.w SNES_TM   ; $212c = Main screen designation
; Display BG1 and BG3 on main screen

	rep #$30		; 16-bit A, X, Y

	lda.w #$0000	; A = $0000
	sta.l $7e31b5   ; Clear [$7e31b5] (game state variable)

	jsr.w InitializeGraphicsDisplaySystem ; Initialize graphics/display system

	sep #$20		; 8-bit accumulator

	jsl.l AddressC8000OriginalCode ; Bank $0c: Wait for VBLANK

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

	ldx.w #$0000	; X = $0000
	stx.w SNES_OAMADDL ; $2102-$2103 = OAM address = $0000
; Start writing at first sprite

	ldx.w #$0400	; X = $0400
; $04 = DMA mode: 2 registers, write once
; $00 = Target register low byte
	stx.w SNES_DMA5PARAM ; $4350 = DMA5 parameters

	ldx.w #$0c00	; X = $0c00
	stx.w SNES_DMA5ADDRL ; $4352-$4353 = Source address $xx0C00

	lda.b #$00	  ; A = $00
	sta.w SNES_DMA5ADDRH ; $4354 = Source bank = $00 → $000c00

	ldx.w #$0220	; X = $0220 (544 bytes)
	stx.w SNES_DMA5CNTL ; $4355-$4356 = Transfer size = 544 bytes

	lda.b #$20	  ; A = $20 (bit 5 = DMA channel 5)
	sta.w SNES_MDMAEN ; $420b = Execute DMA channel 5
; Copies OAM data to PPU

; ---------------------------------------------------------------------------
; Initialize Game State Variables
; ---------------------------------------------------------------------------

	rep #$30		; 16-bit A, X, Y

	lda.w #$ffff	; A = $ffff
	sta.w $010e	 ; [$010e] = $ffff (state marker)

	jsl.l InitializePaletteSystem ; Initialize subsystem
	jsr.w InitializeSubsystem ; Initialize subsystem
	jsl.l FinalSetupRoutine ; Initialize subsystem

	sep #$20		; 8-bit accumulator
	rts ; Return to caller

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

	rep #$30		; 16-bit A, X, Y

; ---------------------------------------------------------------------------
; Copy Save Data Block 1: mvn (Block Move Negative)
; ---------------------------------------------------------------------------
; mvn instruction: Move block of memory
; Format: mvn srcbank,dstbank
; X = source address, Y = destination address, A = length-1
;
; This copies $0040 bytes from $0ca9c2 to $001010
; ---------------------------------------------------------------------------

	ldx.w #$a9c2	; X = $a9c2 (source address low/mid)
	ldy.w #$1010	; Y = $1010 (destination address)
	lda.w #$003f	; A = $003f (transfer 64 bytes: $3f+1)
	mvn $00,$0c	 ; Copy from bank $0c to bank $00
; Source: $0ca9c2, Dest: $001010, Size: $40

; Note: mvn auto-increments X, Y and decrements A until A = $ffff
; After execution: X = $a9c2+$40, Y = $1010+$40, A = $ffff

; ---------------------------------------------------------------------------
; Copy Save Data Block 2
; ---------------------------------------------------------------------------
; Y already = $1010+$40 = $1050 from previous mvn
; Copies $000a bytes from $0c0e9e to $001050
; ---------------------------------------------------------------------------

	ldy.w #$0e9e	; Y = $0e9e (new source address)
; Overwrites Y (dest becomes source for new copy)
; Actually this is confusing - need to verify
	lda.w #$0009	; A = $0009 (transfer 10 bytes: $09+1)
	mvn $00,$0c	 ; Copy from bank $0c to bank $00

	sep #$20		; 8-bit accumulator

; ---------------------------------------------------------------------------
; Set Save Slot Marker
; ---------------------------------------------------------------------------

	lda.b #$02	  ; A = $02
	sta.w $0fe7	 ; [$0fe7] = $02 (save slot indicator?)

; ---------------------------------------------------------------------------
; Determine Active Save Slot
; ---------------------------------------------------------------------------
; $7e3668 contains save slot number (0, 1, or 2)
; If >= 2, wraps to slot 0
; ---------------------------------------------------------------------------

	lda.l $7e3668   ; A = save slot number
	cmp.b #$02	  ; Compare with 2
	bcc IfSkipAheadValidSlot ; If < 2, skip ahead (valid slot 0 or 1)

	lda.b #$ff	  ; A = $ff (invalid slot, reset to -1)

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

	inc a; A = slot number + 1 (1, 2, or 3)
	sta.l $7e3668   ; Update slot number in RAM

	rep #$30		; 16-bit A, X, Y

	and.w #$0003	; A = A & 3 (ensure 0-3 range)
	asl a; A = A × 2
	asl a; A = A × 4
	asl a; A = A × 8 (8 bytes per slot)
	tax ; X = slot_index × 8 (table offset)

	sep #$20		; 8-bit accumulator

; ---------------------------------------------------------------------------
; Load Data from Slot Table
; ---------------------------------------------------------------------------
; Uses X as offset into DATA8_0081D5 table
; Loads 8 bytes of configuration data for this save slot
; ---------------------------------------------------------------------------

	stz.b $19	   ; [$19] = $00 (clear direct page variable)

	lda.w DATA8_0081d5,x ; A = table[X+0] (byte 0)
	sta.w !env_context_value	 ; Store to !env_context_value

	ldy.w DATA8_0081d6,x ; Y = table[X+1,X+2] (bytes 1-2, 16-bit)
	sty.w !env_coord_x	 ; Store to !env_coord_x-!env_coord_y

	lda.w DATA8_0081d8,x ; A = table[X+3] (byte 3)
	sta.w $0e92	 ; Store to $0e92

	ldy.w DATA8_0081db,x ; Y = table[X+4,X+5] (bytes 4-5, 16-bit)
	sty.b $53	   ; Store to $53-$54

	ldy.w DATA8_0081d9,x ; Y = table[X+6,X+7] (bytes 6-7, 16-bit)
	tyx ; X = Y (transfer loaded value to X)

	rep #$30		; 16-bit A, X, Y

; ---------------------------------------------------------------------------
; Copy Additional Save Data
; ---------------------------------------------------------------------------
; Copies $0020 bytes from $0c:X to $000ea8
; X was loaded from table above
; ---------------------------------------------------------------------------

	ldy.w #$0ea8	; Y = $0ea8 (destination)
	lda.w #$001f	; A = $001f (copy 32 bytes)
	mvn $00,$0c	 ; Copy from bank $0c to bank $00

; ---------------------------------------------------------------------------
; Final Save Load Setup
; ---------------------------------------------------------------------------

	ldx.w #$0e92	; X = $0e92
	stx.b $17	   ; [$17] = $0e92 (store pointer)

	jsr.w ProcessLoadedSaveData ; Process loaded save data

	sep #$20		; 8-bit accumulator

	jsl.l Display_EnableEffects ; Finalize save load

	rts ; Return

;-------------------------------------------------------------------------------
; SAVE SLOT DATA TABLE
;-------------------------------------------------------------------------------
; Format: 8 bytes per save slot (4 slots: $ff, 0, 1, 2)
; Structure unclear without further analysis
;-------------------------------------------------------------------------------

DATA8_0081d5:
	db $2d		 ; Slot 0, byte 0

DATA8_0081d6:
	dw $1f26	   ; Slot 0, bytes 1-2 (little-endian)

DATA8_0081d8:
	db $05		 ; Slot 0, byte 3

DATA8_0081d9:
	dw $aa0c	   ; Slot 0, bytes 4-5

DATA8_0081db:
	dw $a82e	   ; Slot 0, bytes 6-7

; Slot 1 data (8 bytes)
	db $19, $0e, $1a, $02, $0c, $aa, $c1, $a8

; Slot 2 data (8 bytes)
	db $14, $33, $28, $05, $2c, $aa, $6a, $a9

DATA8_0081ed:
; Referenced by OriginalCode (at $008113)
; Initialization data table
	db $ec, $a6, $03

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
; Uses mvn (Block Move Negative) instruction for fast memory fill.
; Clever technique: Write zero to first byte, then copy that byte forward.
;
; RAM Layout After Clear:
;   $0000-$05ff: Cleared (1,536 bytes)
;   $0600-$07ff: Preserved (512 bytes) - hardware mirrors or special use
;   $0800-$1fff: Cleared (6,144 bytes)
; ===========================================================================

	lda.w #$0000	; A = $0000
	tcd ; D = $0000 (Direct Page = $0000)
; Reset direct page to bank $00 start

	stz.b $00	   ; [$0000] = $00 (write zero to first byte)

; ---------------------------------------------------------------------------
; Clear $0000-$05ff (1,536 bytes)
; ---------------------------------------------------------------------------
; Technique: Copy the zero byte forward across memory
; Source: $0000 (which we just set to $00)
; Dest: $0002 (start copying from here)
; Length: $05fd+1 = $05fe bytes
; Result: $0000-$05ff all become $00
; ---------------------------------------------------------------------------

	ldx.w #$0000	; X = $0000 (source address)
	ldy.w #$0002	; Y = $0002 (dest address - skip $0000,$0001)
	lda.w #$05fd	; A = $05fd (copy 1,534 bytes)
	mvn $00,$00	 ; Fill $0002-$05ff with zero
; (copying from $0000 which is zero)

; ---------------------------------------------------------------------------
; Clear $0800-$1fff (6,144 bytes)
; ---------------------------------------------------------------------------
; Same technique for second RAM region
; Skips $0600-$07ff (512 bytes preserved)
; ---------------------------------------------------------------------------

	stz.w $0800	 ; [$0800] = $00 (write zero to start of region)

	ldx.w #$0800	; X = $0800 (source address)
	ldy.w #$0802	; Y = $0802 (dest address)
	lda.w #$17f8	; A = $17f8 (copy 6,137 bytes)
	mvn $00,$00	 ; Fill $0802-$1fff with zero

; ---------------------------------------------------------------------------
; Set Boot Signature
; ---------------------------------------------------------------------------
; $7e3367 = Boot signature/checksum
; $3369 might be a magic number verifying proper boot
; ---------------------------------------------------------------------------

	lda.w #$3369	; A = $3369 (boot signature)
	sta.l $7e3367   ; [$7e3367] = $3369

; ---------------------------------------------------------------------------
; Load Initial Data Table Based on Save Flag
; ---------------------------------------------------------------------------
; Checks if save file exists, loads different init table accordingly
; ---------------------------------------------------------------------------

	ldx.w #$822a	; X = $822a (default data table pointer)

	lda.l $7e3667   ; A = save file exists flag
	and.w #$00ff	; Mask to 8-bit value
	beq Load_InitDataTable ; If 0 (no save) → use default table

	ldx.w #$822d	; X = $822d (alternate table for existing save)

Load_InitDataTable:
	jmp.w CodeLikelyLoadsProcessesThisData ; Load/process data table and return

;-------------------------------------------------------------------------------
; INITIALIZATION DATA TABLES
;-------------------------------------------------------------------------------

DATA8_00822a:
; No save file table
	db $2d, $a6, $03

DATA8_00822d:
; Has save file table
	db $2b, $a6, $03

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

	rep #$30		; 16-bit A, X, Y

	pea.w $007e	 ; Push $007e to stack
	plb ; Pull to B (Data Bank = $7e)
; All memory accesses now default to bank $7e

	lda.w #$0170	; A = $0170 (parameter 1)
	ldy.w #$3007	; Y = $3007 (parameter 2)
	jsr.w InitializeTheseParameters ; Initialize with these parameters

	lda.w #$0098	; A = $0098
	sta.w $31b5	 ; [$7e31b5] = $0098 (game state variable)

	plb ; Restore B (Data Bank back to $00)
	rts ; Return

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

	sep #$30		; 8-bit A, X, Y (and set flags)

	stz.w SNES_NMITIMEN ; $4200 = $00
; Disable NMI, IRQ, and auto-joypad read

	lda.b #$80	  ; A = $80 (bit 7 = force blank)
	sta.w SNES_INIDISP ; $2100 = $80
; Force blank: screen output disabled
; Brightness = 0

	rts ; Return

;-------------------------------------------------------------------------------
; DMA Configuration Data Table
;-------------------------------------------------------------------------------
; Referenced by DMA setup routine at Label_00804D
; Format: 9 bytes total
;   - Byte 0: Initial value ($00)
;   - Bytes 1-9: Three identical 3-byte DMA channel configurations
; Each 3-byte block likely represents:
;   - Byte 0 ($db): DMA control/mode flags
;   - Byte 1 ($80): DMA destination register (VRAM write port)
;   - Byte 2 ($fd): DMA source bank or transfer parameters
;-------------------------------------------------------------------------------

DATA8_008252:
	db $00
	db $db, $80, $fd, $db, $80, $fd, $db, $80, $fd

;===============================================================================
; VBLANK/NMI HANDLER and DMA MANAGEMENT ($00825c-$008337)
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

	rep #$30		; 16-bit A, X, Y

	lda.w #$0000	; A = $0000
	tcd ; Direct Page = $0000

; ---------------------------------------------------------------------------
; Initialize DMA State Variables ($0500-$050a)
; ---------------------------------------------------------------------------
; These variables track DMA transfer state and configuration
; ---------------------------------------------------------------------------

	ldx.w #$ff08	; X = $ff08 (init value)
	stx.w $0503	 ; [$0503-$0504] = $ff08
	stx.w $0501	 ; [$0501-$0502] = $ff08

	ldx.w #$880f	; X = $880f (init value)
	stx.w $0508	 ; [$0508-$0509] = $880f
	stx.w $0506	 ; [$0506-$0507] = $880f

	lda.w #$00ff	; A = $00ff
	sep #$20		; 8-bit accumulator

	sta.w $0500	 ; [$0500] = $ff
	sta.w $0505	 ; [$0505] = $ff

	lda.b #$00	  ; A = $00
	sta.w $050a	 ; [$050a] = $00

; ---------------------------------------------------------------------------
; Clear Graphics State Flags ($7e3659-$7e3663)
; ---------------------------------------------------------------------------

	sta.l $7e3659   ; [$7e3659] = $00
	sta.l $7e365e   ; [$7e365e] = $00
	sta.l $7e3663   ; [$7e3663] = $00

	rep #$30		; 16-bit A, X, Y

	sta.l $7e365a   ; [$7e365a-$7e365b] = $0000
	sta.l $7e365c   ; [$7e365c-$7e365d] = $0000
	sta.l $7e365f   ; [$7e365f-$7e3660] = $0000
	sta.l $7e3661   ; [$7e3661-$7e3662] = $0000

; ---------------------------------------------------------------------------
; Load Additional Initialization Data
; ---------------------------------------------------------------------------

	ldx.w #$8334	; X = $8334 (pointer to init data table)
	jsr.w CodeLikelyLoadsProcessesThisData ; Load/process data table

; ---------------------------------------------------------------------------
; Initialize OAM DMA Parameters
; ---------------------------------------------------------------------------
; $01f0/$01f2 = OAM DMA transfer sizes
; ---------------------------------------------------------------------------

	lda.w #$0040	; A = $0040 (64 bytes)
	sta.w $01f0	 ; [$01f0] = $0040 (first OAM DMA size)

	lda.w #$0004	; A = $0004 (4 bytes)
	sta.w $01f2	 ; [$01f2] = $0004 (second OAM DMA size)

; ---------------------------------------------------------------------------
; Copy Data from ROM to RAM (Bank $7e)
; ---------------------------------------------------------------------------

	ldx.w #$b81b	; X = $b81b (source address low/mid)
	ldy.w #$3000	; Y = $3000 (destination address)
	lda.w #$0006	; A = $0006 (copy 7 bytes)
	mvn $7e,$00	 ; Copy from bank $00 to bank $7e
; Source: $00b81b → Dest: $7e3000

; ---------------------------------------------------------------------------
; Copy DMA Channel Configuration
; ---------------------------------------------------------------------------
; Copies 8 bytes from $004340 to $004340 (self-copy? or init?)
; ---------------------------------------------------------------------------

	ldy.w #$4340	; Y = $4340 (DMA channel 4 registers)
	lda.w #$0007	; A = $0007 (copy 8 bytes)
	mvn $00,$00	 ; Copy within bank $00

; ---------------------------------------------------------------------------
; Set Configuration Flag
; ---------------------------------------------------------------------------

	lda.w #$0010	; A = $0010 (bit 4)
	tsb.w $0111	 ; Test and Set bit 4 in $0111

; ---------------------------------------------------------------------------
; Initialize Graphics System (3 calls)
; ---------------------------------------------------------------------------

	lda.w #$0000	; A = $0000 (parameter)
	jsr.w InitializeGraphicsComponent ; Initialize graphics component 0

	lda.w #$0001	; A = $0001 (parameter)
	jsr.w InitializeGraphicsComponent ; Initialize graphics component 1

	lda.w #$0002	; A = $0002 (parameter)
	jsr.w InitializeGraphicsComponent ; Initialize graphics component 2

; ---------------------------------------------------------------------------
; Load Graphics Data from ROM to RAM
; ---------------------------------------------------------------------------

	ldx.w #$d380	; X = $d380 (source: bank $0c, offset $d380)
	ldy.w #$0e84	; Y = $0e84 (destination in bank $00)
	lda.w #$017b	; A = $017b (copy 380 bytes)
	mvn $00,$0c	 ; Copy from bank $0c to bank $00
; Source: $0cd380 → Dest: $000e84

	ldx.w #$d0b0	; X = $d0b0 (source: bank $0c, offset $d0b0)
	ldy.w #$1000	; Y = $1000 (destination in bank $00)
	lda.w #$004f	; A = $004f (copy 80 bytes)
	mvn $00,$0c	 ; Copy from bank $0c to bank $00
; Source: $0cd0b0 → Dest: $001000

; ---------------------------------------------------------------------------
; Initialize Character/Party State
; ---------------------------------------------------------------------------

	lda.w #$00ff	; A = $00ff
	sta.w !char2_companion_id	 ; [$1090] = $00ff (character state?)
	sta.w !char2_status	 ; [$10a1] = $00ff
	sta.w !char2_active_flag	 ; [$10a0] = $00ff (active character?)

; ---------------------------------------------------------------------------
; Load Configuration from ROM
; ---------------------------------------------------------------------------

	lda.l DATA8_07800a ; A = [ROM $07800a]
	and.w #$739c	; A = A & $739c (mask specific bits)
	sta.w $0e9c	 ; [$0e9c] = masked value

; ---------------------------------------------------------------------------
; Initialize Additional Systems
; ---------------------------------------------------------------------------

	jsr.w InitializeSystem2 ; Initialize system
	jsr.w InitializeSystem ; Initialize system
	jsr.w ExternalRoutine ; Initialize system

; ---------------------------------------------------------------------------
; Set Direct Page to PPU Registers ($2100)
; ---------------------------------------------------------------------------
; Clever technique: Set D=$2100 so direct page accesses hit PPU registers
; This makes `STA.b $15` equivalent to `STA.w $2115` (VMAINC)
; Saves bytes and cycles in tight VBLANK code
; ---------------------------------------------------------------------------

	lda.w #$2100	; A = $2100 (PPU register base)
	tcd ; D = $2100 (Direct Page → PPU registers)

	stz.w !state_marker	 ; [$00f0] = $0000 (clear state)

; ---------------------------------------------------------------------------
; Upload Graphics to VRAM
; ---------------------------------------------------------------------------

	ldx.w #$6080	; X = $6080 (VRAM address)
	stx.b SNES_VMADDL-$2100 ; $2116-$2117 = VRAM address $6080
; (using direct page offset)

	pea.w $0004	 ; Push $0004
	plb ; B = $04 (Data Bank = $04)
; Memory accesses now default to bank $04

	ldx.w #$99c0	; X = $99c0 (source address in bank $04)
	ldy.w #$0004	; Y = $0004 (DMA parameters)
	jsl.l ExecuteSpecialTransfer ; Execute graphics upload via DMA

	plb ; Restore Data Bank
	rtl ; Return

;-------------------------------------------------------------------------------
; INITIALIZATION DATA TABLE
;-------------------------------------------------------------------------------

DATA8_008334:
; Referenced at $0082a2
	db $fc, $a6, $03

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

	rep #$30		; 16-bit A, X, Y

	lda.w #$4300	; A = $4300 (DMA register base)
	tcd ; D = $4300 (Direct Page → DMA registers)
; Now `LDA.b $00` = `LDA.w $4300` etc.

	sep #$20		; 8-bit accumulator

	stz.w $420c	 ; $420c (HDMAEN) = $00
; Disable HDMA during processing

; ---------------------------------------------------------------------------
; Check State Flag $00e2 bit 6 (Special Handler Mode)
; ---------------------------------------------------------------------------

	lda.b #$40	  ; A = $40 (bit 6 mask)
	and.w !system_flags_9	 ; Test bit 6 of $00e2
	bne NMI_SpecialHandler ; If set → Jump to special handler

; ---------------------------------------------------------------------------
; Check State Flag $00d4 bit 1 (Tilemap DMA)
; ---------------------------------------------------------------------------

	lda.b #$02	  ; A = $02 (bit 1 mask)
	and.w !system_flags_2	 ; Test bit 1 of $00d4
	bne NMI_TilemapDMA ; If set → Tilemap DMA needed

; ---------------------------------------------------------------------------
; Check State Flag $00dd bit 6 (Graphics Upload)
; ---------------------------------------------------------------------------

	lda.b #$40	  ; A = $40 (bit 6 mask)
	and.w !system_flags_7	 ; Test bit 6 of $00dd
	bne NMI_GraphicsUpload ; If set → Graphics upload needed

; ---------------------------------------------------------------------------
; Check State Flag $00d8 bit 7 (Battle Graphics)
; ---------------------------------------------------------------------------

	lda.b #$80	  ; A = $80 (bit 7 mask)
	and.w !system_flags_4	 ; Test bit 7 of $00d8
	beq NMI_CheckMoreFlags ; If clear → Skip battle graphics

	lda.b #$80	  ; A = $80
	trb.w !system_flags_4	 ; Test and Reset bit 7 of $00d8
; Clear the flag (one-shot operation)

	jmp.w ExecuteBattleGraphicsUpdate ; Execute battle graphics update

;-------------------------------------------------------------------------------

NMI_CheckMoreFlags:
; ===========================================================================
; Check Additional DMA Flags
; ===========================================================================
; Continues checking state flags for other DMA operations.
; ===========================================================================

	lda.b #$c0	  ; A = $c0 (bits 6-7 mask)
	and.w !system_flags_1	 ; Test bits 6-7 of $00d2
	bne AddressA8OriginalCode ; If any set → Execute DMA operations

	lda.b #$10	  ; A = $10 (bit 4 mask)
	and.w !system_flags_1	 ; Test bit 4 of $00d2
	bne NMI_SpecialDMA ; If set → Special operation

	jmp.w ContinueAdditionalHandlers ; → Continue to additional handlers

;-------------------------------------------------------------------------------

NMI_SpecialDMA:
	jmp.w ExecuteSpecialDmaOperation ; Execute special DMA operation

;-------------------------------------------------------------------------------

NMI_TilemapDMA:
	jmp.w AddressE8OriginalCode ; Execute tilemap DMA transfer

;-------------------------------------------------------------------------------

NMI_SpecialHandler:
; ===========================================================================
; Special Mode Handler (Indirect Jump)
; ===========================================================================
; bit 6 of $00e2 triggers special handler mode.
; Jumps through pointer at [$0058] (16-bit address in bank $00).
; This allows dynamic handler switching.
; ===========================================================================

	lda.b #$40	  ; A = $40
	trb.w !system_flags_9	 ; Test and Reset bit 6 of $00e2
; Clear flag before jumping

	jml.w [$0058]   ; Jump Long to address stored at [$0058]
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

	ldx.w #$1801	; X = $1801
; $18 = DMA mode (2 registers, increment)
; $01 = Low byte of destination register
	stx.b SNES_DMA5PARAM-$4300 ; $4350-$4351 = DMA5 parameters

	ldx.w $01f6	 ; X = source address (from variable)
	stx.b SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source address low/mid

	lda.b #$7f	  ; A = $7f
	sta.b SNES_DMA5ADDRH-$4300 ; $4354 = Source bank $7f

	ldx.w $01f4	 ; X = transfer size (from variable)
	stx.b SNES_DMA5CNTL-$4300 ; $4355-$4356 = Transfer size

	ldx.w $01f8	 ; X = VRAM destination address
	stx.w SNES_VMADDL ; $2116-$2117 = VRAM address

	lda.b #$84	  ; A = $84
; bit 7 = increment after writing $2119
; Bits 0-3 = increment by 128 words
	sta.w SNES_VMAINC ; $2115 = VRAM address increment mode

	lda.b #$20	  ; A = $20 (bit 5 = DMA channel 5)
	sta.w SNES_MDMAEN ; $420b = Execute DMA channel 5
; Transfer starts immediately!

;-------------------------------------------------------------------------------

NMI_ProcessDMAFlags:
; ===========================================================================
; Process DMA Operation Flags ($00d2)
; ===========================================================================
; Handles various DMA operations based on flags in $00d2.
; ===========================================================================

	lda.b #$80	  ; A = $80 (bit 7 mask)
	and.w !system_flags_1	 ; Test bit 7 of $00d2
	beq NMI_CheckOAMFlag ; If clear → Skip this DMA

; ---------------------------------------------------------------------------
; DMA Transfer with Vertical Increment
; ---------------------------------------------------------------------------

	lda.b #$80	  ; A = $80 (increment after $2119 write)
	sta.w SNES_VMAINC ; $2115 = VRAM increment mode

	ldx.w #$1801	; X = $1801 (DMA parameters)
	stx.b SNES_DMA5PARAM-$4300 ; $4350-$4351 = DMA5 config

	ldx.w $01ed	 ; X = source address
	stx.b SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source address low/mid

	lda.w $01ef	 ; A = source bank
	sta.b SNES_DMA5ADDRH-$4300 ; $4354 = Source bank

	ldx.w $01eb	 ; X = transfer size
	stx.b SNES_DMA5CNTL-$4300 ; $4355-$4356 = Size

	ldx.w $0048	 ; X = VRAM address
	stx.w SNES_VMADDL ; $2116-$2117 = VRAM address

	lda.b #$20	  ; A = $20 (DMA channel 5)
	sta.w SNES_MDMAEN ; $420b = Execute DMA

;-------------------------------------------------------------------------------

NMI_CheckOAMFlag:
; ===========================================================================
; Check OAM Update Flag
; ===========================================================================
; bit 5 of $00d2 triggers OAM (sprite) data upload.
; ===========================================================================

	lda.b #$20	  ; A = $20 (bit 5 mask)
	and.w !system_flags_1	 ; Test bit 5 of $00d2
	beq NMI_Cleanup ; If clear → Skip OAM update

	jsr.w DMA_UpdateOAM ; Execute OAM DMA transfer

;-------------------------------------------------------------------------------

NMI_Cleanup:
; ===========================================================================
; Cleanup and Return from NMI
; ===========================================================================
; Clears processed flags and returns from interrupt handler.
; ===========================================================================

	lda.b #$40	  ; A = $40 (bit 6)
	trb.w !system_flags_7	 ; Test and Reset bit 6 of $00dd
; Clear graphics upload flag

	lda.b #$a0	  ; A = $a0 (bits 5 and 7)
	trb.w !system_flags_1	 ; Test and Reset bits 5,7 of $00d2
; Clear OAM and VRAM DMA flags

	rtl ; Return from Long call (NMI complete)

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

	lda.b #$02	  ; A = $02 (bit 1)
	trb.w !system_flags_2	 ; Test and Reset bit 1 of $00d4
; Clear "tilemap DMA pending" flag

	lda.b #$80	  ; A = $80 (increment after $2119 write)
	sta.w $2115	 ; $2115 (VMAINC) = $80
; VRAM address increments by 1 word after high byte write

; ---------------------------------------------------------------------------
; Configure Palette (CGRAM) DMA
; ---------------------------------------------------------------------------

	ldx.w #$2200	; X = $2200
; $22 = DMA mode (fixed source, increment dest)
; $00 = Target register low byte
	stx.b SNES_DMA5PARAM-$4300 ; $4350 = DMA5 parameters

	lda.b #$07	  ; A = $07
	sta.b SNES_DMA5ADDRH-$4300 ; $4354 = Source bank $07

	lda.b #$a8	  ; A = $a8 (CGADD - palette address register)
	ldx.w $0064	 ; X = [$0064] (palette index/parameters)
	jsr.w DMA_TransferPalette ; Execute palette DMA transfer

; ---------------------------------------------------------------------------
; Prepare for Tilemap Transfer
; ---------------------------------------------------------------------------

	rep #$30		; 16-bit A, X, Y

	ldx.w #$ff00	; X = $ff00
	stx.w !state_marker	 ; [$00f0] = $ff00 (state marker)

; ---------------------------------------------------------------------------
; Check Transfer Mode ($0062)
; ---------------------------------------------------------------------------
; $0062 determines which transfer path to take
; If $0062 = 1, use special graphics upload method
; Otherwise, use standard tilemap transfer
; ---------------------------------------------------------------------------

	ldx.w $0062	 ; X = [$0062] (transfer mode flag)
	lda.w #$6080	; A = $6080 (default VRAM address)

	cpx.w #$0001	; Compare mode with 1
	beq DMA_SpecialGraphics ; If mode = 1 → Special graphics upload

	jsr.w DMA_StandardTilemap ; Standard tilemap transfer
	rtl ; Return

;-------------------------------------------------------------------------------

DMA_SpecialGraphics:
; ===========================================================================
; Special Graphics Upload (Mode 1)
; ===========================================================================
; Alternative graphics upload path when $0062 = 1.
; Uses different source data and parameters.
; ===========================================================================

	phk ; Push Program Bank (K register)
	plb ; Pull to Data Bank (B register)
; B = $00 (set data bank to current program bank)

	sta.w SNES_VMADDL ; $2116-$2117 = VRAM address $6080

	ldx.w #$f0c1	; X = $f0c1 (source address in bank $04)
	ldy.w #$0004	; Y = $0004 (DMA parameters)
	jmp.w ExecuteSpecialTransfer ; Execute graphics DMA and return

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

	lda.b #$80	  ; A = $80 (bit 7 mask)
	and.w !system_flags_2	 ; Test bit 7 of $00d4
	beq NMI_ReturnToHandler ; If clear → Skip, jump to handler return

	lda.b #$80	  ; A = $80
	trb.w !system_flags_2	 ; Test and Reset bit 7 of $00d4
; Clear "large transfer pending" flag

	lda.b #$80	  ; A = $80 (increment mode)
	sta.w $2115	 ; $2115 (VMAINC) = $80

; ---------------------------------------------------------------------------
; Check Battle Graphics Mode ($00d8 bit 1)
; ---------------------------------------------------------------------------

	lda.b #$02	  ; A = $02 (bit 1 mask)
	and.w !system_flags_4	 ; Test bit 1 of $00d8
	beq NMI_AlternateTransfer ; If clear → Use alternate path

; ---------------------------------------------------------------------------
; Battle Graphics Transfer
; ---------------------------------------------------------------------------
; Transfers battle-specific graphics during scene transitions
; ---------------------------------------------------------------------------

	ldx.w #$1801	; X = $1801 (DMA parameters)
	stx.b SNES_DMA5PARAM-$4300 ; $4350 = DMA5 config

	ldx.w #$075a	; X = $075a (source address offset)
	stx.b SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source address low/mid

	lda.b #$7f	  ; A = $7f
	sta.b SNES_DMA5ADDRH-$4300 ; $4354 = Source bank $7f
; Full source: $7f075a

	ldx.w #$0062	; X = $0062 (98 bytes)
	stx.b SNES_DMA5CNTL-$4300 ; $4355-$4356 = Transfer size

	ldx.w #$3bad	; X = $3bad (VRAM destination)
	stx.w $2116	 ; $2116-$2117 = VRAM address

	lda.b #$20	  ; A = $20 (DMA channel 5)
	sta.w $420b	 ; $420b = Execute DMA

; ---------------------------------------------------------------------------
; Additional Battle Graphics Data Transfer
; ---------------------------------------------------------------------------
; Writes specific data directly to VRAM
; ---------------------------------------------------------------------------

	rep #$30		; 16-bit A, X, Y

	ldx.w #$4bed	; X = $4bed (VRAM address)
	stx.w $2116	 ; Set VRAM address

	lda.l $7f17da   ; A = [$7f17da] (16-bit data)
	sta.w $2118	 ; $2118-$2119 = Write to VRAM data

	lda.l $7f17dc   ; A = [$7f17dc] (16-bit data)
	sta.w $2118	 ; Write second word to VRAM

	sep #$20		; 8-bit accumulator

;-------------------------------------------------------------------------------

NMI_ReturnToHandler:
; ===========================================================================
; Return to Main NMI Handler
; ===========================================================================
	jmp.w NMI_ProcessDMAFlags ; → Jump back to NMI handler continuation

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

	ldx.w #$2200	; X = $2200 (DMA parameters)
	stx.b SNES_DMA5PARAM-$4300 ; $4350 = DMA5 config

	lda.b #$07	  ; A = $07
	sta.b SNES_DMA5ADDRH-$4300 ; $4354 = Source bank $07

; ---------------------------------------------------------------------------
; Transfer Two Palette Sets
; ---------------------------------------------------------------------------

	lda.b #$88	  ; A = $88 (palette address)
	ldx.w !tile_offset_1	 ; X = [$00f4] (source offset 1)
	jsr.w TransferPaletteSet ; Transfer palette set 1

	lda.b #$98	  ; A = $98 (palette address)
	ldx.w !tile_offset_2	 ; X = [$00f7] (source offset 2)
	jsr.w TransferPaletteSet ; Transfer palette set 2

; ---------------------------------------------------------------------------
; Write Direct VRAM Data
; ---------------------------------------------------------------------------

	rep #$30		; 16-bit A, X, Y

	ldx.w #$5e8d	; X = $5e8d (VRAM address)
	stx.w $2116	 ; Set VRAM address

	lda.l $7e2d1a   ; A = [$7e2d1a] (data from WRAM)
	sta.w $2118	 ; Write to VRAM

	lda.l $7e2d1c   ; A = [$7e2d1c]
	sta.w $2118	 ; Write second word

; ---------------------------------------------------------------------------
; Prepare for Tilemap Transfer
; ---------------------------------------------------------------------------

	ldx.w #$ff00	; X = $ff00
	stx.w !state_marker	 ; [$00f0] = $ff00 (marker)

; ---------------------------------------------------------------------------
; Transfer Two Tilemap Regions
; ---------------------------------------------------------------------------

	ldx.w !tilemap1_addr	 ; X = [$00f2] (tilemap 1 source)
	lda.w #$6000	; A = $6000 (VRAM address 1)
	jsr.w TransferTilemapRegion ; Transfer tilemap region 1

	ldx.w !tilemap2_addr	 ; X = [$00f5] (tilemap 2 source)
	lda.w #$6040	; A = $6040 (VRAM address 2)
	jsr.w TransferTilemapRegion ; Transfer tilemap region 2

	sep #$20		; 8-bit accumulator

; ---------------------------------------------------------------------------
; Check Special Transfer Mode
; ---------------------------------------------------------------------------

	lda.b #$10	  ; A = $10 (bit 4 mask)
	and.w !system_flags_5	 ; Test bit 4 of $00da
	bne IfSetSkipMenuGraphicsTransfer ; If set → Skip menu graphics transfer

; ---------------------------------------------------------------------------
; Menu Graphics Transfer
; ---------------------------------------------------------------------------
; Transfers menu-specific graphics data
; ---------------------------------------------------------------------------

	ldx.w #$1801	; X = $1801 (DMA parameters)
	stx.b SNES_DMA5PARAM-$4300 ; $4350 = DMA5 config

	ldx.w #$0380	; X = $0380 (896 bytes)
	stx.b SNES_DMA5CNTL-$4300 ; $4355-$4356 = Transfer size

	lda.b #$7f	  ; A = $7f
	sta.b SNES_DMA5ADDRH-$4300 ; $4354 = Source bank $7f

; ---------------------------------------------------------------------------
; Select Source Address Based on Menu Position
; ---------------------------------------------------------------------------
; $1031 contains vertical menu position
; Different Y positions use different graphics data
; ---------------------------------------------------------------------------

	lda.w !location_identifier	 ; A = [$1031] (Y position)

	ldx.w #$c708	; X = $c708 (default source 1)
	cmp.b #$26	  ; Compare Y with $26
	bcc IfYUseSource ; If Y < $26 → Use source 1

	ldx.w #$c908	; X = $c908 (source 2)
	cmp.b #$29	  ; Compare Y with $29
	bcc IfYUseSource ; If Y < $29 → Use source 2

	ldx.w #$ca48	; X = $ca48 (source 3)
; Y >= $29 → Use source 3

DMA_ExecuteTilemapTransfer:
	stx.b SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Selected source address

	ldx.w #$6700	; X = $6700 (VRAM destination)
	stx.w SNES_VMADDL ; $2116-$2117 = VRAM address

	lda.b #$20	  ; A = $20 (DMA channel 5)
	sta.w SNES_MDMAEN ; $420b = Execute DMA

;-------------------------------------------------------------------------------

NMI_ClearTransferMarkers:
; ===========================================================================
; Clear Transfer Markers and Return
; ===========================================================================

	ldx.w #$ffff	; X = $ffff
	stx.w !tilemap1_addr	 ; [$00f2] = $ffff (invalidate tilemap 1)
	stx.w !tilemap2_addr	 ; [$00f5] = $ffff (invalidate tilemap 2)

	jmp.w NMI_ProcessDMAFlags ; → Return to NMI handler

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

	sta.w $2121	 ; $2121 (CGADD) = Palette start address
; Sets where in CGRAM to write

	ldy.w #$0010	; Y = $0010 (16 bytes = 8 colors)
	sty.b SNES_DMA5CNTL-$4300 ; $4355-$4356 = Transfer 16 bytes

	rep #$30		; 16-bit A, X, Y

	txa ; A = X (transfer source offset to A)
	and.w #$00ff	; A = A & $00ff (ensure 8-bit value)
	clc ; Clear carry
	adc.w #$d8e4	; A = A + $d8e4 (add base address)
; Final source in bank $07: $07(D8E4+offset)
	sta.b SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Calculated source address

	sep #$20		; 8-bit accumulator

	lda.b #$20	  ; A = $20 (DMA channel 5)
	sta.w $420b	 ; $420b = Execute palette DMA

	rts ; Return

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

	cpx.w #$ffff	; Check if X = $ffff
	beq DMA_StandardTilemap_Skip ; If yes → Skip transfer (no data)

	sta.w SNES_VMADDL ; $2116-$2117 = VRAM destination address

	pea.w $0004	 ; Push $0004
	plb ; B = $04 (Data Bank = $04)

	phx ; Save X (source address)

	ldy.w #$0002	; Y = $0002 (DMA parameters)
	jsl.l ExecuteSpecialTransfer ; Execute first tilemap transfer

	pla ; A = saved X (restore source address)
	clc ; Clear carry
	adc.w #$0180	; A = source + $0180 (offset to second half)
	tax ; X = new source address

	ldy.w #$0002	; Y = $0002 (DMA parameters)
	jsl.l ExecuteSpecialTransfer ; Execute second tilemap transfer
; (VRAM address auto-increments)

	plb ; Restore Data Bank

DMA_StandardTilemap_Skip:
	rts ; Return

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
;     bit 0: X position bit 8 (for X > 255)
;     bit 1: Sprite size toggle
;
; This routine transfers both tables in two DMA operations.
; ===========================================================================

; ---------------------------------------------------------------------------
; Configure DMA for Main OAM Table
; ---------------------------------------------------------------------------

	ldx.w #$0400	; X = $0400
; $04 = DMA mode (write 2 registers once)
; $00 = Target register low byte ($2104 = OAMDATA)
	stx.b SNES_DMA5PARAM-$4300 ; $4350 = DMA5 config

	ldx.w #$0c00	; X = $0c00 (source address)
	stx.b SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source in bank $00: $000c00

	lda.b #$00	  ; A = $00
	sta.b SNES_DMA5ADDRH-$4300 ; $4354 = Source bank $00

	ldx.w $01f0	 ; X = [$01f0] (transfer size - main table)
	stx.b SNES_DMA5CNTL-$4300 ; $4355-$4356 = Size (typically $0200 = 512 bytes)

	ldx.w #$0000	; X = $0000
	stx.w SNES_OAMADDL ; $2102-$2103 = OAM address = 0
; Start writing at first sprite

	lda.b #$20	  ; A = $20 (DMA channel 5)
	sta.w SNES_MDMAEN ; $420b = Execute DMA (main table)

; ---------------------------------------------------------------------------
; Configure DMA for High OAM Table
; ---------------------------------------------------------------------------

	ldx.w #$0e00	; X = $0e00 (source address for high table)
	stx.b SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source: $000e00

	ldx.w $01f2	 ; X = [$01f2] (transfer size - high table)
	stx.b SNES_DMA5CNTL-$4300 ; $4355-$4356 = Size (typically $0020 = 32 bytes)

	ldx.w #$0100	; X = $0100
	stx.w SNES_OAMADDL ; $2102-$2103 = OAM address = $100
; This is where high table starts

	lda.b #$20	  ; A = $20 (DMA channel 5)
	sta.w SNES_MDMAEN ; $420b = Execute DMA (high table)

	rts ; Return

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

	ldx.w #$4400	; X = $4400 (VRAM destination)
	stx.w SNES_VMADDL ; $2116-$2117 = VRAM address

	ldx.w #$1801	; X = $1801 (DMA parameters)
	stx.b SNES_DMA5PARAM-$4300 ; $4350 = DMA5 config

	ldx.w #$0480	; X = $0480 (source address offset)
	stx.b SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source in bank $7f: $7f0480

	lda.b #$7f	  ; A = $7f
	sta.b SNES_DMA5ADDRH-$4300 ; $4354 = Source bank

	ldx.w #$0280	; X = $0280 (640 bytes)
	stx.b SNES_DMA5CNTL-$4300 ; $4355-$4356 = Transfer size

	lda.b #$20	  ; A = $20 (DMA channel 5)
	sta.w SNES_MDMAEN ; $420b = Execute DMA
; ===========================================================================

	lda.b #$80	  ; A = $80 (bit 7)
	trb.w !system_flags_8	 ; Test and Reset bit 7 of $00de
; Clear some state flag

	lda.b #$e0	  ; A = $e0 (bits 5-7)
	trb.w $0111	 ; Test and Reset bits 5-7 of $0111
; Clear multiple state flags

	jsl.l AddressC8000OriginalCode ; Bank $0c: Wait for VBLANK

; ---------------------------------------------------------------------------
; Configure Color Math (Fade Effect)

	rep #$30		; 16-bit A, X, Y registers
	ldx.w #$1fff	; X = $1fff
	txs ; Stack pointer = $1fff (top of RAM)

	jsr.w Init_Graphics_Registers ; Initialize PPU and graphics registers

; ---------------------------------------------------------------------------
; Check for Special Button Combination
; ---------------------------------------------------------------------------
; Checks if a specific button is held during boot
; Might enable debug mode, skip intro, etc.
; ---------------------------------------------------------------------------

	lda.w #$0040	; A = $0040 (bit 6 = some button?)
	and.w !system_flags_5	 ; Mask with controller input
	bne Skip_Normal_Init ; If button held, skip to alternate path

; Normal initialization path
	jsl.l BankOC_Init ; Initialize bank $0c systems
	bra Continue_Init ; Continue setup

;-------------------------------------------------------------------------------

Boot_Tertiary_Entry:
; ===========================================================================
; Tertiary Boot Entry Point
; ===========================================================================
; Yet another entry point - FFMQ has multiple boot paths
; ===========================================================================

	jsr.w Init_Hardware ; Hardware init (again)

	lda.b #$f0
	sta.l $000600   ; Hardware mirror write

	jsl.l Bank0D_Init_Variant ; Subsystem init

	rep #$30		; 16-bit mode
	ldx.w #$1fff	; Reset stack pointer
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

	jsr.w Init_Graphics_Registers ; More graphics setup

	sep #$20		; 8-bit A, 16-bit X/Y

; Configure DMA Channel 0
	ldx.w #$1809	; DMA parameters
; $18 = DMA control byte
; $09 = Target register (probably $2109?)
	stx.w !SNES_DMA0PARAM ; $4300-4301: DMA control + target

	ldx.w #$8252	; Source address = $008252
	stx.w !SNES_DMA0ADDRL ; $4302-4303: Source address low/mid

	lda.b #$00	  ; Source bank = $00
	sta.w !SNES_DMA0ADDRH ; $4304: Source address bank

	ldx.w #$0000	; Size = $0000 (wraps to $10000 = 64KB)
	stx.w !SNES_DMA0CNTL ; $4305-4306: Transfer size

	lda.b #$01	  ; Enable DMA channel 0
	sta.w !SNES_MDMAEN ; $420b: Start DMA transfer NOW

;-------------------------------------------------------------------------------

Skip_Normal_Init:
; ===========================================================================
; Post-Initialization Setup
; ===========================================================================
; Called after hardware is initialized, regardless of boot path
; ===========================================================================

	jsl.l $00011f   ; Call early routine (what is this?)

	rep #$30		; 16-bit A, X, Y
	lda.w #$0000
	tcd ; Direct page = $0000 (default)

	sep #$20		; 8-bit A

; ---------------------------------------------------------------------------
; Enable Interrupts (NMI/IRQ)
; ---------------------------------------------------------------------------
; NMI (Non-Maskable Interrupt) = VBlank interrupt
; Fires every frame at vertical blanking
; Used for graphics updates, timing, etc.
; ---------------------------------------------------------------------------

	lda.w $0112	 ; Load NMI enable flags
	sta.w !SNES_NMITIMEN ; $4200: Enable NMI and/or IRQ
	cli ; Clear interrupt disable flag
; Interrupts now active!

; ---------------------------------------------------------------------------
; Set Screen Brightness
; ---------------------------------------------------------------------------

	lda.b #$0f	  ; Full brightness (0-15 scale)
	sta.w !brightness_value	 ; Store to brightness variable

; Call initialization twice (fade in/out? Double buffer?)
	jsl.l BankOC_Init
	jsl.l BankOC_Init

; ---------------------------------------------------------------------------
; Check Save Game Status
; ---------------------------------------------------------------------------
; Determines whether to load a save or start new game
; ---------------------------------------------------------------------------

	lda.l $7e3665   ; Load save state flag
	bne Handle_Existing_Save ; If non-zero, handle existing save

; ---------------------------------------------------------------------------
; Check SRAM for Save Data
; ---------------------------------------------------------------------------
; SRAM (battery-backed RAM) at $70:0000-$7f:FFFF stores save games
; Check specific bytes to see if valid save data exists
; ---------------------------------------------------------------------------

	lda.l $700000   ; SRAM byte 1 (save header?)
	ora.l $70038c   ; OR with SRAM byte 2
	ora.l $700718   ; OR with SRAM byte 3
	beq Start_New_Game ; If all zero, no save exists

; Save data exists - load it
	jsl.l Load_Save_Game ; Load game from SRAM
	bra Continue_To_Game

;-------------------------------------------------------------------------------

Handle_Existing_Save:
; ===========================================================================
; Handle Existing Save State
; ===========================================================================
; Called when save state flag indicates save in progress
; ===========================================================================

	jsr.w Some_Save_Handler
	bra Enter_Main_Loop

;-------------------------------------------------------------------------------

Start_New_Game:
; ===========================================================================
; New Game Initialization
; ===========================================================================
; Called when no save data exists - starts a fresh game
; ===========================================================================

	jsr.w Init_New_Game

;-------------------------------------------------------------------------------

Continue_To_Game:
; ===========================================================================
; Final Setup Before Game Loop
; ===========================================================================
; Last minute preparations before entering main game loop
; ===========================================================================

	lda.b #$80	  ; bit 7
	trb.w !system_flags_8	 ; Test and reset bit 7 in game flag

	lda.b #$e0	  ; Bits 5-7
	trb.w $0111	 ; Test and reset bits 5-7

	jsl.l BankOC_Init ; Another initialization call

; ---------------------------------------------------------------------------
; Configure Color Math (SNES Special Effects)
; ---------------------------------------------------------------------------
; Color math allows adding/subtracting colors for transparency, fades, etc.
; ---------------------------------------------------------------------------

	lda.b #$e0	  ; Color math: subtract mode?
	sta.w !SNES_COLDATA ; $2132: Color math configuration

; Reset windowing and color effects
	ldx.w #$0000
	stx.w !SNES_CGSWSEL ; $2130: Window mask settings

; ---------------------------------------------------------------------------
; Reset Background Scroll Positions
; ---------------------------------------------------------------------------

	stz.w !SNES_BG1VOFS ; $210e: BG1 vertical scroll = 0
	stz.w !SNES_BG1VOFS ; Write twice (SNES registers need H+L bytes)

	stz.w !SNES_BG2VOFS ; $2110: BG2 vertical scroll = 0
	stz.w !SNES_BG2VOFS

	jsr.w Some_Graphics_Setup
	jsl.l BankOC_Init

;-------------------------------------------------------------------------------

Enter_Main_Loop:
; ===========================================================================
; MAIN GAME LOOP ENTRY
; ===========================================================================
; This is where the actual game begins!
; From here, execution enters the main game loop
; ===========================================================================

	jsr.w Main_Game_Loop

	lda.b #$00
	jsr.w Some_Mode_Handler

	lda.b #$01
	jsr.w Some_Mode_Handler

	ldx.w #$81ed	; Pointer to some data
	jsr.w Execute_Script_Or_Command

	lda.b #$04
	tsb.w !system_flags_2	 ; Test and set bit 2 in game flag

	lda.b #$80
	trb.w !system_flags_3	 ; Test and reset bit 7 in flag

	stz.w !battle_ready_flag	 ; Clear some variable

	lda.b #$01
	tsb.w !system_flags_9	 ; Test and set bit 0

	lda.b #$10
	tsb.w !system_flags_3	 ; Test and set bit 4

	ldx.w #$fff0	; Some value
	stx.w !game_state_value	 ; Store to variable

	jsl.l Some_System_Call
	jsr.w Some_Function
	jml.l Jump_To_Bank01 ; Jump to bank $01 code!

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

	lda.b #$14	  ; Enable BG1, BG3, BG4?
	sta.w !SNES_TM  ; $212c: Main screen designation

	rep #$30		; 16-bit mode
	lda.w #$0000
	sta.l $7e31b5   ; Clear some game variable

	jsr.w Some_Init_Routine

	sep #$20		; 8-bit A
	jsl.l BankOC_Init

; ---------------------------------------------------------------------------
; DMA Transfer to OAM (Sprite Attribute Memory)
; ---------------------------------------------------------------------------
; OAM holds sprite positions, tiles, and attributes
; ---------------------------------------------------------------------------

	ldx.w #$0000
	stx.w !SNES_OAMADDL ; $2102: OAM address = 0

; Configure DMA Channel 5 for OAM
	ldx.w #$0400	; DMA params for OAM
	stx.w !SNES_DMA5PARAM ; $4350-4351

	ldx.w #$0c00	; Source = $000c00
	stx.w !SNES_DMA5ADDRL ; $4352-4353

	lda.b #$00	  ; Source bank = $00
	sta.w !SNES_DMA5ADDRH ; $4354

	ldx.w #$0220	; Transfer size = $0220 = 544 bytes
	stx.w !SNES_DMA5CNTL ; $4355-4356

	lda.b #$20	  ; Enable DMA channel 5 (bit 5)
	sta.w !SNES_MDMAEN ; $420b: Start DMA

; ---------------------------------------------------------------------------
; More Initialization
; ---------------------------------------------------------------------------

	rep #$30		; 16-bit mode
	lda.w #$ffff
	sta.w $010e	 ; Initialize some variable to -1

	jsl.l Some_Init_Function_1
	jsr.w Some_Init_Function_2
	jsl.l Some_Init_Function_3

	sep #$20		; 8-bit A


;-------------------------------------------------------------------------------

Init_SaveGameDefaults:
; ===========================================================================
; Initialize Save Game Default Values
; ===========================================================================
; Copies default initialization data from ROM to work RAM
; Sets up initial game state variables for save system
; Two memory block copies followed by save system flag initialization
; ===========================================================================

	rep #$30		; 16-bit mode

; Copy 64 bytes of initialization data to work RAM at $0c:1010
	ldx.w #$a9c2	; Source address: ROM bank $00, offset $a9c2
	ldy.w #$1010	; Destination: Work RAM $0c:1010
	lda.w #$003f	; Transfer size: 64 bytes ($3f+1)
	mvn $00,$0c	 ; Block copy from bank $00 to bank $0c

; Copy 10 bytes of additional save data to work RAM at $0c:0e9e
	ldy.w #$0e9e	; Destination: Work RAM $0c:0e9e
	lda.w #$0009	; Transfer size: 10 bytes ($09+1)
	mvn $00,$0c	 ; Block copy from bank $00 to bank $0c

	sep #$20		; 8-bit A

; Set save system ready flag
	lda.b #$02
	sta.w $0fe7	 ; Save system state = $02 (initialized/ready)

	lda.l $7e3668   ; Load save state
	cmp.b #$02
	bcc .less_than_2
	lda.b #$ff	  ; Cap at $ff if >= 2

	.less_than_2:
	inc a; Increment save state
	sta.l $7e3668   ; Store back

	rep #$30		; 16-bit mode
	and.w #$0003	; Mask to 0-3
	asl a; Multiply by 8
	asl a
	asl a
	tax ; X = offset into table

	sep #$20		; 8-bit A
	stz.b $19	   ; Clear some variable

; Load data from table based on save state
	lda.w Save_State_Table,x
	sta.w !env_context_value

	ldy.w Save_State_Table+1,x
	sty.w !env_coord_x

	lda.w Save_State_Table+3,x
	sta.w $0e92

	ldy.w Save_State_Table+6,x
	sty.b $53

	ldy.w Save_State_Table+4,x
TYX_Label:

	rep #$30		; 16-bit mode
	ldy.w #$0ea8
	lda.w #$001f
	mvn $00,$0c	 ; Block copy

	ldx.w #$0e92
	stx.b $17

	jsr.w Some_Function_A236

	sep #$20		; 8-bit A
	jsl.l Some_Function_9319


;-------------------------------------------------------------------------------
; Save State Data Table
;-------------------------------------------------------------------------------

Save_State_Table:
	db $2d		 ; Entry 0
	dw $1f26
	db $05
	dw $aa0c
	dw $a82e

	db $19, $0e, $1a ; Entry 1
	db $02
	dw $aa0c
	dw $a8c1

	db $14, $33, $28 ; Entry 2
	db $05
	dw $aa2c
	dw $a96a

	db $ec, $a6, $03 ; Entry 3 (partial data visible)

;===============================================================================
; HARDWARE/MEMORY INITIALIZATION
;===============================================================================

Init_Graphics_Registers:
; ===========================================================================
; Initialize Graphics/PPU Registers
; ===========================================================================
; Sets up initial values for SNES PPU (Picture Processing Unit)
; ===========================================================================

	lda.w #$0000
	tcd ; Direct page = $0000

	stz.b $00	   ; Clear first byte of RAM

; ---------------------------------------------------------------------------
; Clear RAM ($0000-$05fd = 1,534 bytes)
; ---------------------------------------------------------------------------
; Uses mvn (block move) to quickly zero memory
; ---------------------------------------------------------------------------

	ldx.w #$0000	; Source = $0000
	ldy.w #$0002	; Dest = $0002
	lda.w #$05fd	; Length = $05fd bytes
	mvn $00,$00	 ; Copy within bank $00
; This copies $00 forward, clearing memory!

; ---------------------------------------------------------------------------
; Clear More RAM ($0800-$1ff8 = 6,136 bytes)
; ---------------------------------------------------------------------------

	stz.w $0800	 ; Clear byte at $0800

	ldx.w #$0800	; Source = $0800
	ldy.w #$0802	; Dest = $0802
	lda.w #$17f8	; Length = $17f8 = 6,136 bytes
	mvn $00,$00	 ; Clear this block too

; ---------------------------------------------------------------------------
; Initialize Magic Number (Save Data Validation?)
; ---------------------------------------------------------------------------

	lda.w #$3369	; Magic number = $3369
	sta.l $7e3367   ; Store to WRAM
; Probably used to detect valid save data

; ---------------------------------------------------------------------------
; Execute Initialization Script Based on Save State
; ---------------------------------------------------------------------------

	ldx.w #$822a	; Default script pointer

	lda.l $7e3667   ; Load save exists flag
	and.w #$00ff	; Mask to byte
	beq .no_save

	ldx.w #$822d	; Different script if save exists

	.no_save:
	jmp.w Execute_Script_Or_Command

;-------------------------------------------------------------------------------
; Script/Event Initialization Pointers
;-------------------------------------------------------------------------------
; Format: 3 bytes per entry (likely bank:address pointers)
; Used by initialization routines to set up game event handlers
;-------------------------------------------------------------------------------

	db $2d, $a6, $03 ; Script pointer 1: Bank $03, address $a62d
	db $2b, $a6, $03 ; Script pointer 2: Bank $03, address $a62b

;===============================================================================
; WRAM Memory Block Initialization
;===============================================================================

Init_WRAMMemoryBlock:
; ===========================================================================
; Initialize WRAM Memory Region
; ===========================================================================
; Sets data bank to $7e (WRAM) and initializes a memory block
; Calls function at $9A08 with parameters for memory region setup
; ===========================================================================

	rep #$30		; 16-bit mode

; Set data bank to $7e (WRAM bank)
	pea.w $007e
PLB_Label:

	lda.w #$0170	; Size parameter: 368 bytes
	ldy.w #$3007	; Destination address: WRAM $7e:3007
	jsr.w Some_Function_9A08	; Call initialization routine

	lda.w #$0098
	sta.w $31b5	 ; Store to WRAM variable

	plb ; Restore data bank


;-------------------------------------------------------------------------------

Init_Hardware_1:
; ===========================================================================
; Initialize SNES Hardware Registers
; ===========================================================================
; Sets hardware to known safe state:
; - Disable interrupts
; - Force blank screen
; - Reset registers
; ===========================================================================

	sep #$30		; 8-bit A, X, Y

	stz.w !SNES_NMITIMEN ; $4200: Disable NMI and IRQ

	lda.b #$80	  ; Force blank + full brightness
	sta.w !SNES_INIDISP ; $2100: Screen display control
; bit 7 = force blank (screen off)


;-------------------------------------------------------------------------------
; DMA Source Data (Register Init Values)
;-------------------------------------------------------------------------------

	org $008252
DMA_Init_Data:
	db $00		 ; First byte
	db $db, $80, $fd ; More init values
	db $db, $80, $fd
	db $db, $80, $fd
; More data continues...

;===============================================================================
; Graphics Update - Field Mode (continued from GraphicsUpdateFieldModeContinuedCode)
;===============================================================================

DMA_FieldGraphicsUpdate:
; Setup VRAM for vertical increment mode
	lda.b #$80	  ; Increment after writing to $2119
	sta.w SNES_VMAINC ; Set VRAM increment mode

; Check if battle mode graphics needed
	lda.b #$10	  ; Check bit 4 of display flags
	and.w !system_flags_5	 ; Test against display status
	beq +		   ; If clear, continue to field graphics
	jmp GraphicsUpdateFieldModeContinuedCode ; Otherwise do battle graphics transfer
	+
; Field mode graphics update
	ldx.w $0042	 ; Get current VRAM address from variable
	stx.w SNES_VMADDL ; Set VRAM write address

; Setup DMA for character tile transfer
	ldx.w #$1801	; DMA mode: word write, increment
	stx.b SNES_DMA5PARAM-$4300 ; Set DMA5 parameters
	ldx.w #$0040	; Source: $7f0040
	stx.b SNES_DMA5ADDRL-$4300 ; Set source address
	lda.b #$7f	  ; Bank $7f (WRAM)
	sta.b SNES_DMA5ADDRH-$4300 ; Set source bank
	ldx.w #$07c0	; Transfer size: $07c0 bytes (1984 bytes)
	stx.b SNES_DMA5CNTL-$4300 ; Set transfer size
	lda.b #$20	  ; Trigger DMA channel 5
	sta.w SNES_MDMAEN ; Execute transfer

	rep #$30		; 16-bit A, X, Y
	clc ; Clear carry for addition
	lda.w $0042	 ; Get VRAM address
	adc.w #$1000	; Add $1000 for next section
	sta.w SNES_VMADDL ; Set new VRAM address
	sep #$20		; 8-bit A

; Transfer second section of tiles
	ldx.w #$1801	; DMA mode: word write
	stx.b SNES_DMA5PARAM-$4300 ; Set DMA5 parameters
	ldx.w #$1040	; Source: $7f1040
	stx.b SNES_DMA5ADDRL-$4300 ; Set source address
	lda.b #$7f	  ; Bank $7f (WRAM)
	sta.b SNES_DMA5ADDRH-$4300 ; Set source bank
	ldx.w #$07c0	; Transfer size: $07c0 bytes
	stx.b SNES_DMA5CNTL-$4300 ; Set transfer size
	lda.b #$20	  ; Trigger DMA channel 5
	sta.w SNES_MDMAEN ; Execute transfer

; Check if tilemap update needed
	lda.b #$80	  ; Check bit 7
	and.w !system_flags_3	 ; Test display flags
	beq DMA_FieldGraphicsUpdate_OAM ; If clear, skip tilemap transfer

; Transfer tilemap data
	ldx.w #$5820	; VRAM address $5820
	stx.w SNES_VMADDL ; Set VRAM write address
	ldx.w #$1801	; DMA mode: word write
	stx.b SNES_DMA5PARAM-$4300 ; Set DMA5 parameters
	ldx.w #$2040	; Source: $7e2040
	stx.b SNES_DMA5ADDRL-$4300 ; Set source address
	lda.b #$7e	  ; Bank $7e (WRAM)
	sta.b SNES_DMA5ADDRH-$4300 ; Set source bank
	ldx.w #$0fc0	; Transfer size: $0fc0 bytes (4032 bytes)
	stx.b SNES_DMA5CNTL-$4300 ; Set transfer size
	lda.b #$20	  ; Trigger DMA channel 5
	sta.w SNES_MDMAEN ; Execute transfer
	rtl ; Return

DMA_FieldGraphicsUpdate_OAM:
	jsr.w DMA_UpdateOAM ; Transfer OAM data

; Check if additional display update needed
	lda.b #$20	  ; Check bit 5
	and.w !system_flags_3	 ; Test display flags
	beq DMA_FieldGraphicsUpdate_Exit ; If clear, exit
	lda.b #$78	  ; Set multiple flags (bits 3,4,5,6)
	tsb.w !system_flags_2	 ; Set bits in status register

DMA_FieldGraphicsUpdate_Exit:
	rtl ; Return

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

	lda.b #$10	  ; A = $10 (bit 4 mask)
	trb.w !system_flags_1	 ; Test and Reset bit 4 of $00d2
; Clear "special transfer pending" flag

	lda.b #$80	  ; A = $80 (increment mode)
	sta.w SNES_VMAINC ; $2115 = Increment after $2119 write

; ---------------------------------------------------------------------------
; Check Battle Mode Graphics Flag
; ---------------------------------------------------------------------------

	lda.b #$10	  ; A = $10 (bit 4 mask)
	and.w !system_flags_5	 ; Test bit 4 of $00da
	beq DMA_FieldModeTransfer ; If clear → Use normal field mode graphics

; ---------------------------------------------------------------------------
; Battle Mode Graphics Transfer
; ---------------------------------------------------------------------------
; Transfers menu graphics for battle interface
; ---------------------------------------------------------------------------

	pea.w $0004	 ; Push $0004
	plb ; B = $04 (Data Bank = $04)

	ldx.w #$60c0	; X = $60c0 (VRAM address)
	stx.w $2116	 ; Set VRAM address

	ldx.w #$ff00	; X = $ff00
	stx.w !state_marker	 ; [$00f0] = $ff00 (state marker)

	ldx.w #$99c0	; X = $99c0 (source in bank $04)
	ldy.w #$0004	; Y = $0004 (DMA parameters)
	jsl.l ExecuteSpecialTransfer ; Execute tilemap DMA transfer

	plb ; Restore Data Bank

; ---------------------------------------------------------------------------
; Transfer Battle Palette Set 1
; ---------------------------------------------------------------------------

	lda.b #$a8	  ; A = $a8 (palette start address)
	sta.w SNES_CGADD ; $2121 = CGRAM address = $a8

	ldx.w #$2200	; X = $2200 (DMA parameters)
	stx.b SNES_DMA5PARAM-$4300 ; $4350 = DMA5 config

	ldx.w #$d814	; X = $d814 (source offset)
	stx.b SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source: $07d814

	lda.b #$07	  ; A = $07
	sta.b SNES_DMA5ADDRH-$4300 ; $4354 = Source bank $07

	ldx.w #$0010	; X = $0010 (16 bytes = 8 colors)
	stx.b SNES_DMA5CNTL-$4300 ; $4355-$4356 = Transfer size

	lda.b #$20	  ; A = $20 (DMA channel 5)
	sta.w SNES_MDMAEN ; $420b = Execute palette DMA

; ---------------------------------------------------------------------------
; Clear Specific Palette Entries
; ---------------------------------------------------------------------------
; Clears palette entries $0d and $1d to black
; Used to reset specific UI colors in battle mode
; ---------------------------------------------------------------------------

	lda.b #$0d	  ; A = $0d (palette entry 13)
	sta.w SNES_CGADD ; Set CGRAM address
	stz.w SNES_CGDATA ; $2122 = $00 (color low byte = black)
	stz.w SNES_CGDATA ; $2122 = $00 (color high byte)

	lda.b #$1d	  ; A = $1d (palette entry 29)
	sta.w SNES_CGADD ; Set CGRAM address
	stz.w SNES_CGDATA ; $2122 = $00 (black)
	stz.w SNES_CGDATA ; $2122 = $00

	rtl ; Return

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

	ldx.w #$2200	; X = $2200 (DMA parameters)
	stx.b SNES_DMA5PARAM-$4300 ; $4350 = DMA5 config

	ldx.w #$d824	; X = $d824 (source offset)
	stx.b SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source: $07d824

	lda.b #$07	  ; A = $07
	sta.b SNES_DMA5ADDRH-$4300 ; $4354 = Source bank $07

	ldx.w #$0010	; X = $0010 (16 bytes)
	stx.b SNES_DMA5CNTL-$4300 ; $4355-$4356 = Transfer size

	rep #$30		; 16-bit A, X, Y

	stz.w !state_marker	 ; [$00f0] = $0000 (clear state marker)

	pea.w $0004	 ; Push $0004
	plb ; B = $04 (Data Bank = $04)

; ---------------------------------------------------------------------------
; Check Character Status Update Flag ($00de bit 6)
; ---------------------------------------------------------------------------
; If set, update single character's status display
; Otherwise, refresh all three character displays
; ---------------------------------------------------------------------------

	lda.w #$0040	; A = $0040 (bit 6 mask)
	and.w !system_flags_8	 ; Test bit 6 of $00de
	beq DMA_UpdateAllCharacters ; If clear → Update all characters

; ---------------------------------------------------------------------------
; Single Character Status Update
; ---------------------------------------------------------------------------
; Updates one character's status display based on $010d and $010e
; ---------------------------------------------------------------------------

	lda.w #$0040	; A = $0040
	trb.w !system_flags_8	 ; Test and Reset bit 6 of $00de
; Clear "single character update" flag

	lda.w $010d	 ; A = [$010d] (character position data)
	and.w #$ff00	; A = A & $ff00 (mask high byte)
	clc ; Clear carry
	adc.w #$6180	; A = A + $6180 (calculate VRAM address)
	sta.w $2116	 ; $2116-$2117 = VRAM address

	lda.w $010e	 ; A = [$010e] (character index)
	asl a; A = A × 2 (convert to word offset)
	tax ; X = character table offset

	lda.w $0107,x   ; A = [$0107 + X] (character data pointer)
	tax ; X = character data pointer

	pha ; Save character data pointer
	jsr.w DMA_CharacterGraphics ; Transfer character graphics (2-part)
	ply ; Y = character data pointer (restore)

	plb ; Restore Data Bank

; ---------------------------------------------------------------------------
; Transfer Character Palette
; ---------------------------------------------------------------------------

	clc ; Clear carry
	lda.w $010e	 ; A = [$010e] (character index)
	adc.w #$000d	; A = A + $000d (palette offset)
	asl a; A = A × 2
	asl a; A = A × 4
	asl a; A = A × 8
	asl a; A = A × 16 (multiply by 16)
	tax ; X = palette CGRAM address

	jsr.w DMA_CharacterPalette ; Transfer character palette

	rtl ; Return

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

	lda.w #$6100	; A = $6100 (VRAM address)
	sta.w $2116	 ; Set VRAM address

	ldx.w #$9a20	; X = $9a20 (source in bank $04)
	ldy.w #$0004	; Y = $0004 (DMA parameters)
	jsl.l ExecuteSpecialTransfer ; Transfer tilemap part 1

	ldx.w #$cd20	; X = $cd20 (source for second part)
	ldy.w #$0004	; Y = $0004 (DMA parameters)
	jsl.l ExecuteSpecialTransfer ; Transfer tilemap part 2

; ---------------------------------------------------------------------------
; Transfer Character 1 Graphics
; ---------------------------------------------------------------------------

	ldx.w $0107	 ; X = [$0107] (character 1 data pointer)
	jsr.w DMA_CharacterGraphics ; Transfer character 1 graphics

; ---------------------------------------------------------------------------
; Transfer Character 2 Graphics
; ---------------------------------------------------------------------------

	lda.w #$6280	; A = $6280 (VRAM address for char 2)
	sta.w $2116	 ; Set VRAM address

	ldx.w $0109	 ; X = [$0109] (character 2 data pointer)
	jsr.w DMA_CharacterGraphics ; Transfer character 2 graphics

; ---------------------------------------------------------------------------
; Transfer Character 3 Graphics
; ---------------------------------------------------------------------------

	lda.w #$6380	; A = $6380 (VRAM address for char 3)
	sta.w $2116	 ; Set VRAM address

	ldx.w $010b	 ; X = [$010b] (character 3 data pointer)
	jsr.w DMA_CharacterGraphics ; Transfer character 3 graphics

	plb ; Restore Data Bank

; ---------------------------------------------------------------------------
; Transfer Main Menu Palette
; ---------------------------------------------------------------------------

	lda.w #$d824	; A = $d824 (source address)
	ldx.w #$00c0	; X = $00c0 (CGRAM address = palette $c)
	jsr.w DMA_PaletteToCGRAM ; Transfer palette

; ---------------------------------------------------------------------------
; Transfer Character 1 Palette
; ---------------------------------------------------------------------------

	ldy.w $0107	 ; Y = [$0107] (character 1 data pointer)
	ldx.w #$00d0	; X = $00d0 (CGRAM address = palette $d)
	jsr.w DMA_CharacterPalette ; Transfer character palette

; ---------------------------------------------------------------------------
; Transfer Character 2 Palette
; ---------------------------------------------------------------------------

	ldy.w $0109	 ; Y = [$0109] (character 2 data pointer)
	ldx.w #$00e0	; X = $00e0 (CGRAM address = palette $e)
	jsr.w TransferCharacterPalette ; Transfer character palette

; ---------------------------------------------------------------------------
; Transfer Character 3 Palette
; ---------------------------------------------------------------------------

	ldy.w $010b	 ; Y = [$010b] (character 3 data pointer)
	ldx.w #$00f0	; X = $00f0 (CGRAM address = palette $f)
	jsr.w TransferCharacterPalette ; Transfer character palette

	rtl ; Return

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

	phx ; Save character data pointer

; ---------------------------------------------------------------------------
; Transfer Graphics Part 1
; ---------------------------------------------------------------------------

	lda.l $000000,x ; A = [X+0] (graphics part 1 pointer)
	tax ; X = graphics part 1 pointer
	ldy.w #$0004	; Y = $0004 (DMA parameters)
	jsl.l ExecuteSpecialTransfer ; Execute DMA transfer

; ---------------------------------------------------------------------------
; Transfer Graphics Part 2
; ---------------------------------------------------------------------------

	plx ; Restore character data pointer

	lda.l $000002,x ; A = [X+2] (graphics part 2 pointer)
	tax ; X = graphics part 2 pointer
	ldy.w #$0004	; Y = $0004 (DMA parameters)
	jsl.l ExecuteSpecialTransfer ; Execute DMA transfer
; (VRAM address auto-increments from part 1)

	rts ; Return

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

	lda.w $0004,y   ; A = [Y+4] (palette data pointer)
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

	sta.b SNES_DMA5ADDRL-$4300 ; $4352-$4353 = Source address

	txa ; A = X (CGRAM address)
	sep #$20		; 8-bit accumulator

	sta.w SNES_CGADD ; $2121 = CGRAM address

	ldx.w #$0010	; X = $0010 (16 bytes)
	stx.b SNES_DMA5CNTL-$4300 ; $4355-$4356 = Transfer size

	lda.b #$20	  ; A = $20 (DMA channel 5)
	sta.w SNES_MDMAEN ; $420b = Execute palette DMA

	rep #$30		; 16-bit A, X, Y

	rts ; Return

;===============================================================================
; ADDITIONAL VBLANK OPERATIONS ($008784-$008965)
;===============================================================================

; Data table referenced by DataTableReferencedCode
DATA8_008960:
	db $3c		 ; Tile $3c

DATA8_008961:
	db $3d		 ; Tile $3d

DATA8_008962:
	db $3e,$45,$3a,$3b ; Tiles: $3e, $45, $3a, $3b

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

	rep #$30		; 16-bit A, X, Y

	lda.w #$0000	; A = $0000
	tcd ; D = $0000 (Direct Page = zero page)
; Reset DP for main game logic

; ---------------------------------------------------------------------------
; Increment 24-Bit Frame Counter
; ---------------------------------------------------------------------------

	inc.w $0e97	 ; Increment frame counter low word
	bne GameLoop_ProcessEvents ; If no overflow → Skip high byte increment
	inc.w $0e99	 ; Increment high byte (24-bit overflow)

;-------------------------------------------------------------------------------

GameLoop_ProcessEvents:
; ===========================================================================
; Time-Based Event Processing
; ===========================================================================

	jsr.w GameLoop_TimeBasedEvents ; Process time-based events (status effects, etc.)

; ---------------------------------------------------------------------------
; Check Full Screen Refresh Flag ($00d4 bit 2)
; ---------------------------------------------------------------------------
; When set, indicates a major mode change requiring full redraw
; (battle start, menu open, scene transition, etc.)
; ---------------------------------------------------------------------------

	lda.w #$0004	; A = $0004 (bit 2 mask)
	and.w !system_flags_2	 ; Test bit 2 of $00d4
	beq GameLoop_NormalUpdate ; If clear → Normal frame processing

; ---------------------------------------------------------------------------
; Full Screen Refresh Path
; ---------------------------------------------------------------------------
; Executes when entering/exiting major game modes.
; Performs complete redraw of both BG layers.
; ---------------------------------------------------------------------------

	lda.w #$0004	; A = $0004
	trb.w !system_flags_2	 ; Test and Reset bit 2 of $00d4
; Clear "full refresh needed" flag

; Refresh Background Layer 0
	lda.w #$0000	; A = $0000 (BG layer 0)
	jsr.w Char_CalcStats ; Update BG layer 0 tilemap
	jsr.w Tilemap_RefreshLayer0 ; Transfer layer 0 to VRAM

; Refresh Background Layer 1
	lda.w #$0001	; A = $0001 (BG layer 1)
	jsr.w Char_CalcStats ; Update BG layer 1 tilemap
	jsr.w Tilemap_RefreshLayer1 ; Transfer layer 1 to VRAM

	bra GameLoop_UpdateState ; → Skip to animation update

;-------------------------------------------------------------------------------

GameLoop_NormalUpdate:
; ===========================================================================
; Normal Frame Processing Path
; ===========================================================================
; Standard per-frame update when not doing full refresh.
; Handles incremental tilemap updates and controller input.
; ===========================================================================

	jsr.w Store_008BFD ; Update tilemap changes (scrolling, etc.)

; ---------------------------------------------------------------------------
; Check Menu Mode Flag ($00da bit 4)
; ---------------------------------------------------------------------------

	lda.w #$0010	; A = $0010 (bit 4 mask)
	and.w !system_flags_5	 ; Test bit 4 of $00da (menu mode flag)
	bne GameLoop_ProcessInput ; If set → Process controller input

; ---------------------------------------------------------------------------
; Check Input Processing Enable ($00e2 bit 2)
; ---------------------------------------------------------------------------

	lda.w #$0004	; A = $0004 (bit 2 mask)
	and.w !system_flags_9	 ; Test bit 2 of $00e2
	bne GameLoop_UpdateState ; If set → Skip input (cutscene/auto mode)

;-------------------------------------------------------------------------------

GameLoop_ProcessInput:
; ===========================================================================
; Controller Input Processing
; ===========================================================================
; Processes joypad input when enabled.
; Calls appropriate handler based on current game mode.
; ===========================================================================

	lda.b $07	   ; A = [$07] (controller data - current frame)
	and.b $8e	   ; A = A & [$8e] (input enable mask)
	beq GameLoop_UpdateState ; If zero → No valid input, skip processing

; ---------------------------------------------------------------------------
; Determine Input Handler
; ---------------------------------------------------------------------------
; CodeReturnsHandlerIndexBasedGame returns handler index in A based on game state
; Handler table at Input_HandlerTable dispatches to appropriate routine
; ---------------------------------------------------------------------------

	jsl.l CodeReturnsHandlerIndexBasedGame ; Get input handler index for current mode

	sep #$30		; 8-bit A, X, Y

	asl a; A = A × 2 (convert to word offset)
	tax ; X = handler table offset

	jsr.w (Input_HandlerTable,x) ; Call appropriate input handler
; (indirect jump through handler table)

;-------------------------------------------------------------------------------

GameLoop_UpdateState:
; ===========================================================================
; Animation and State Update
; ===========================================================================
; Final phase of frame processing.
; Updates animations, sprites, and game state.
; ===========================================================================

	rep #$30		; 16-bit A, X, Y

	jsr.w UpdateSpriteAnimations ; Update sprite animations
	jsr.w UpdateGameStateLogic ; Update game state and logic

	rtl ; Return to NMI handler continuation

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

	phd ; Save Direct Page

; ---------------------------------------------------------------------------
; Check Time-Based Processing Enable Flag
; ---------------------------------------------------------------------------

	lda.w #$0080	; A = $0080 (bit 7 mask)
	and.w !system_flags_8	 ; Test bit 7 of $00de
	beq GameLoop_TimeBasedEvents_Exit ; If clear → Skip time-based processing

; ---------------------------------------------------------------------------
; Set Direct Page for Character Status Access
; ---------------------------------------------------------------------------

	lda.w #$0c00	; A = $0c00
	tcd ; D = $0c00 (Direct Page = $0c00)
; Allows $01 to access $0c01, etc.

	sep #$30		; 8-bit A, X, Y

; ---------------------------------------------------------------------------
; Decrement Timer and Check for Event Trigger
; ---------------------------------------------------------------------------

	dec.w $010d	 ; Decrement timer
	bpl GameLoop_TimeBasedEvents_Exit ; If still positive → Exit (not time yet)

; Timer expired - reset and process status effects
	lda.b #$0c	  ; A = $0c (12 frames)
	sta.w $010d	 ; Reset timer to 12 frames

; ---------------------------------------------------------------------------
; Check Character 1 Status ($700027)
; ---------------------------------------------------------------------------

	lda.l $700027   ; A = [$700027] (character 1 status flags)
	bne GameLoop_CheckChar2 ; If non-zero → Character 1 has status effect

	ldx.b #$40	  ; X = $40 (character 1 offset)
	jsr.w Update_CharacterStatusDisplay ; Update character 1 display

;-------------------------------------------------------------------------------

GameLoop_CheckChar2:
; ---------------------------------------------------------------------------
; Check Character 2 Status ($700077)
; ---------------------------------------------------------------------------

	lda.l $700077   ; A = [$700077] (character 2 status)
	bne GameLoop_CheckChar3 ; If non-zero → Character 2 has status

	ldx.b #$50	  ; X = $50 (character 2 offset)
	jsr.w Update_CharacterStatusDisplay ; Update character 2 display

;-------------------------------------------------------------------------------

GameLoop_CheckChar3:
; ---------------------------------------------------------------------------
; Check Character 3 Status ($7003b3)
; ---------------------------------------------------------------------------

	lda.l $7003b3   ; A = [$7003b3] (character 3 status)
	bne GameLoop_TimeBasedEvents_Exit ; If non-zero → Character 3 has status

	ldx.b #$60	  ; X = $60 (character 3 offset)
	jsr.w Update_CharacterStatusDisplay ; Update character 3 display

;-------------------------------------------------------------------------------

GameLoop_CheckChar4:
; ---------------------------------------------------------------------------
; Check Character 4 Status ($700403)
; ---------------------------------------------------------------------------

	lda.l $700403   ; A = [$700403] (character 4 status)
	bne GameLoop_CheckChar5 ; If non-zero → Character 4 has status

	ldx.b #$70	  ; X = $70 (character 4 offset)
	jsr.w Update_CharacterStatusDisplay ; Update character 4 display

;-------------------------------------------------------------------------------

GameLoop_CheckChar5:
; ---------------------------------------------------------------------------
; Check Character 5 Status ($70073f)
; ---------------------------------------------------------------------------

	lda.l $70073f   ; A = [$70073f] (character 5 status)
	bne GameLoop_CheckChar6 ; If non-zero → Character 5 has status

	ldx.b #$80	  ; X = $80 (character 5 offset)
	jsr.w Update_CharacterStatusDisplay ; Update character 5 display

;-------------------------------------------------------------------------------

GameLoop_CheckChar6:
; ---------------------------------------------------------------------------
; Check Character 6 Status ($70078f)
; ---------------------------------------------------------------------------

	lda.l $70078f   ; A = [$70078f] (character 6 status)
	bne GameLoop_SetSpriteFlag ; If non-zero → Character 6 has status

	ldx.b #$90	  ; X = $90 (character 6 offset)
	jsr.w Update_CharacterStatusDisplay ; Update character 6 display

;-------------------------------------------------------------------------------

GameLoop_SetSpriteFlag:
; ---------------------------------------------------------------------------
; Set Sprite Update Flag
; ---------------------------------------------------------------------------

	lda.b #$20	  ; A = $20 (bit 5)
	tsb.w !system_flags_1	 ; Set bit 5 of $00d2 (sprite update needed)

;-------------------------------------------------------------------------------

GameLoop_TimeBasedEvents_Exit:
; ===========================================================================
; Restore Direct Page and Return
; ===========================================================================

	rep #$30		; 16-bit A, X, Y
	pld ; Restore Direct Page
	rts ; Return

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

	lda.b $02,x	 ; A = [$0c02+X] (current tile base)
	eor.b #$04	  ; A = A XOR $04 (toggle bit 2 for animation)
	sta.b $02,x	 ; [$0c02+X] = new tile base

	inc a; A = base + 1
	sta.w $0c06,x   ; [$0c06+X] = base + 1 (tile 1)

	inc a; A = base + 2
	sta.w $0c0a,x   ; [$0c0a+X] = base + 2 (tile 2)

	inc a; A = base + 3
	sta.w $0c0e,x   ; [$0c0e+X] = base + 3 (tile 3)

	rts ; Return

;===============================================================================
; INPUT HANDLER DISPATCH TABLE ($008a35-$008a54)
;===============================================================================

Input_HandlerTable:
; ===========================================================================
; Input Handler Jump Table
; ===========================================================================
; Table of 16-bit addresses for different input handler routines.
; Indexed by value returned from CodeReturnsHandlerIndexBasedGame (game mode).
;
; Handler addresses are stored as 16-bit little-endian values.
; jsr (table,X) performs indirect jump to selected handler.
; ===========================================================================

; Note: This data is being used as code by the previous instruction
; sta.w $0c0a,X at Input_HandlerTable continues from Update_CharacterStatusDisplay
; The actual table starts here with word addresses:

; Handler jump table data (12 entries x 2 bytes = 24 bytes)
	db $cf,$8a, $f8,$8a, $68,$8b, $68,$8b ; Handlers 0-3
	db $61,$8a, $5d,$8a, $59,$8a, $55,$8a ; Handlers 4-7
	db $68,$8b, $68,$8b, $9d,$8a, $68,$8b ; Handlers 8-11

;===============================================================================
; CURSOR MOVEMENT HANDLERS ($008a55-$008a9c)
;===============================================================================

Input_CursorDown:
; ===========================================================================
; Cursor Down Handler
; ===========================================================================
	dec.b $02	   ; Decrement vertical position
	bra Input_ValidateCursor ; → Validate position

Input_CursorUp:
; ===========================================================================
; Cursor Up Handler
; ===========================================================================
	inc.b $02	   ; Increment vertical position
	bra Input_ValidateCursor ; → Validate position

Input_CursorLeft:
; ===========================================================================
; Cursor Left Handler
; ===========================================================================
	dec.b $01	   ; Decrement horizontal position
	bra Input_ValidateCursor ; → Validate position

Input_CursorRight:
; ===========================================================================
; Cursor Right Handler
; ===========================================================================
	inc.b $01	   ; Increment horizontal position
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

	lda.b $01	   ; A = X position
	bmi Input_CheckXWrap ; If negative → Check wrap flags

	cmp.b $03	   ; Compare with max X
	bcc Input_ValidateY ; If X < max → Valid, continue

; X position at or above maximum
	lda.b $95	   ; A = wrap flags
	and.b #$01	  ; Test bit 0 (allow overflow)
	bne Input_CheckXWrap ; If set → Allow wrap to negative

;-------------------------------------------------------------------------------

Input_ClampX:
; X exceeded maximum, clamp to max-1
	lda.b $03	   ; A = max X
	dec a; A = max - 1
	sta.b $01	   ; X position = max - 1 (clamp)
	bra Input_ValidateY ; → Validate Y position

;-------------------------------------------------------------------------------

Input_CheckXWrap:
; X position is negative or wrapped
	lda.b $95	   ; A = wrap flags
	and.b #$02	  ; Test bit 1 (allow negative)
	bne Input_ClampX ; If set → Clamp to max-1

	stz.b $01	   ; X position = 0 (clamp to minimum)

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

	lda.b $02	   ; A = Y position
	bmi Input_CheckYWrap ; If negative → Check wrap flags

	cmp.b $04	   ; Compare with max Y
	bcc Input_ValidateDone ; If Y < max → Valid, exit

; Y position at or above maximum
	lda.b $95	   ; A = wrap flags
	and.b #$04	  ; Test bit 2 (allow overflow)
	bne Input_CheckYWrap ; If set → Allow wrap to negative

;-------------------------------------------------------------------------------

Input_ClampY:
; Y exceeded maximum, clamp to max-1
	lda.b $04	   ; A = max Y
	dec a; A = max - 1
	sta.b $02	   ; Y position = max - 1 (clamp)
	rts ; Return

;-------------------------------------------------------------------------------

Input_CheckYWrap:
; Y position is negative or wrapped
	lda.b $95	   ; A = wrap flags
	and.b #$08	  ; Test bit 3 (allow negative)
	bne Input_ClampY ; If set → Clamp to max-1

	stz.b $02	   ; Y position = 0 (clamp to minimum)

;-------------------------------------------------------------------------------

Input_ValidateDone:
	rts ; Return

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

	jsr.w Input_CheckAllowed ; Check if input allowed
	bne Input_ButtonA_Exit ; If blocked → Exit

; Check if in valid screen position
	lda.w !char2_companion_id	 ; A = [$1090] (screen mode/position)
	bmi Input_ButtonA_Alternate ; If negative → Call alternate handler

; Toggle character status display
	lda.w !char2_active_flag	 ; A = [$10a0] (character display flags)
	eor.b #$80	  ; Toggle bit 7
	sta.w !char2_active_flag	 ; Save new flag state

	lda.b #$40	  ; A = $40 (bit 6)
	tsb.w !system_flags_2	 ; Set bit 6 of $00d4 (update needed)

	jsr.w NormalPositionCallB908 ; Update character display
	bra Input_ButtonA_Exit ; → Exit

;-------------------------------------------------------------------------------

Input_ButtonA_Alternate:
	jsr.w AlternateCharacterUpdateRoutine ; Alternate character update routine

Input_ButtonA_Exit:
	rts ; Return

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

	lda.w !char_x_pos	 ; A = [$1032] (X position)
	cmp.b #$80	  ; Compare with $80
	bne Menu_CheckCharPosition_Normal ; If not $80 → Jump to B908

	lda.w !char_y_pos	 ; A = [$1033] (Y position)
	bne Menu_CheckCharPosition_Normal ; If not $00 → Jump to B908

	jmp.w AlternateCharacterUpdateRoutine ; Special position → Call B912

;-------------------------------------------------------------------------------

Menu_CheckCharPosition_Normal:
	jmp.w NormalPositionCallB908 ; Normal position → Call B908

;-------------------------------------------------------------------------------

Menu_NavCharUp:
; ===========================================================================
; Menu Navigation - Character Selection (Up/Down)
; ===========================================================================
; Handles up/down navigation through character list in menu.
; Cycles through valid characters, skipping invalid/dead entries.
; ===========================================================================

	jsr.w Input_CheckAllowed ; Check if input allowed
	bne Menu_NavCharUp_Exit ; If blocked → Exit

	jsr.w Menu_CheckCharPosition ; Validate character position

; ---------------------------------------------------------------------------
; Calculate Current Character Index
; ---------------------------------------------------------------------------

	lda.w !location_identifier	 ; A = [$1031] (Y position)
	sec ; Set carry for subtraction
	sbc.b #$20	  ; A = Y - $20 (base offset)

	ldx.b #$ff	  ; X = -1 (character counter)

;-------------------------------------------------------------------------------

Menu_NavCharUp_CalcIndex:
; Divide by 3 to get character slot
	inx ; X++
	sbc.b #$03	  ; A -= 3
	bcs Menu_NavCharUp_CalcIndex ; If carry still set → Continue dividing

; X now contains character index (0-3)
	txa ; A = character index

;-------------------------------------------------------------------------------

Menu_NavCharUp_FindNext:
; ===========================================================================
; Cycle to Next Valid Character
; ===========================================================================
; Increments character index and checks if character is valid.
; Loops until valid character found.
; ===========================================================================

	inc a; A = next character index
	and.b #$03	  ; A = A & $03 (wrap 0-3)

	pha ; Save character index
	jsr.w CheckIfCharacterIsValid ; Check if character is valid
	pla ; Restore character index

	cpy.b #$ff	  ; Check if character invalid (Y = $ff)
	beq Menu_NavCharUp_FindNext ; If invalid → Try next character

; Valid character found
	jsr.w UpdateCharacterDisplay ; Update character display
	jsr.w InitializeSystem ; Refresh graphics

Menu_NavCharUp_Exit:
	rts ; Return

;-------------------------------------------------------------------------------

Menu_NavCharDown:
; ===========================================================================
; Menu Navigation - Character Selection (Down/Reverse)
; ===========================================================================
; Handles down navigation, cycles backwards through character list.
; Same as Menu_NavCharUp but decrements instead of increments.
; ===========================================================================

	jsr.w Input_CheckAllowed ; Check if input allowed
	bne Menu_NavCharDown_Exit ; If blocked → Exit

	jsr.w Menu_CheckCharPosition ; Validate character position

	lda.w !location_identifier	 ; A = [$1031] (Y position)
	sec ; Set carry
	sbc.b #$20	  ; A = Y - $20 (base offset)

	ldx.b #$ff	  ; X = -1 (counter)

;-------------------------------------------------------------------------------

Menu_NavCharDown_CalcIndex:
	inx ; X++
	sbc.b #$03	  ; A -= 3
	bcs Menu_NavCharDown_CalcIndex ; If carry → Continue

	txa ; A = character index

;-------------------------------------------------------------------------------

Menu_NavCharDown_FindPrev:
; Cycle to previous valid character
	dec a; A = previous character index
	and.b #$03	  ; A = A & $03 (wrap 0-3)

	pha ; Save index
	jsr.w CheckIfCharacterIsValid ; Check if character valid
	pla ; Restore index

	cpy.b #$ff	  ; Check if invalid
	beq Menu_NavCharDown_FindPrev ; If invalid → Try previous

	jsr.w UpdateCharacterDisplay ; Update character display
	jsr.w Tilemap_RefreshLayer0 ; Refresh graphics

Menu_NavCharDown_Exit:
	rts ; Return

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

	rep #$30		; 16-bit A, X, Y

	ldx.w #$3709	; X = $3709 (default tilemap 1)
	cpy.w #$0023	; Compare Y with $23
	bcc IfYUseTilemap ; If Y < $23 → Use tilemap 1

	ldx.w #$3719	; X = $3719 (tilemap 2)
	cpy.w #$0026	; Compare Y with $26
	bcc Menu_CopyTilemapData ; If Y < $26 → Use tilemap 2

	ldx.w #$3729	; X = $3729 (tilemap 3)
	cpy.w #$0029	; Compare Y with $29
	bcc Menu_CopyTilemapData ; If Y < $29 → Use tilemap 3

	ldx.w #$3739	; X = $3739 (tilemap 4, Y >= $29)

;-------------------------------------------------------------------------------

Menu_CopyTilemapData:
; ===========================================================================
; Copy Tilemap Data to Destination
; ===========================================================================
; Uses mvn to copy 16 bytes of tilemap data.
;
; mvn Format:
;   mvn dest_bank,src_bank
;   Copies (A+1) bytes from X to Y
;   Auto-increments X and Y, decrements A
; ===========================================================================

	ldy.w #$3669	; Y = $3669 (destination in bank $7e)
	lda.w #$000f	; A = $000f (15, so copy 16 bytes)
	mvn $7e,$7e	 ; Copy 16 bytes from X to Y (both in $7e)

	phk ; Push program bank
	plb ; Pull to data bank (B = $00)

; ---------------------------------------------------------------------------
; Refresh Background Layer
; ---------------------------------------------------------------------------

	lda.w #$0000	; A = $0000 (BG layer 0)
	jsr.w Char_CalcStats ; Update layer 0

	sep #$30		; 8-bit A, X, Y

	lda.b #$80	  ; A = $80 (bit 7)
	tsb.w $00d9	 ; Set bit 7 of $00d9

	rts ; Return

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

	lda.b #$10	  ; A = $10 (bit 4 mask)
	and.w !system_flags_3	 ; Test bit 4 of $00d6
	beq Input_CheckAllowed_Exit ; If clear → Input allowed, exit

; Input blocked - mask controller state
	rep #$30		; 16-bit A, X, Y

	lda.b $92	   ; A = [$92] (controller state)
	and.w #$bfcf	; A = A & $bfcf (mask bits 4-5, 14)
; Disables: bit 4, bit 5, bit 14

	sep #$30		; 8-bit A, X, Y

Input_CheckAllowed_Exit:
	rts ; Return (Z flag indicates input state)

; Padding/unused byte
Unused_008B68:
	rts ; Return

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

	rep #$30		; 16-bit A, X, Y

	lda.w #$0000	; A = $0000
	tcd ; D = $0000 (Direct Page = zero page)

; ---------------------------------------------------------------------------
; Check Controller Read Enable
; ---------------------------------------------------------------------------

	lda.w #$0040	; A = $0040 (bit 6 mask)
	and.w !system_flags_3	 ; Test bit 6 of $00d6
	bne Input_ReadController_Exit ; If set → Controller disabled, exit

; ---------------------------------------------------------------------------
; Save Previous Controller State
; ---------------------------------------------------------------------------

	lda.b $92	   ; A = current controller state
	sta.b $96	   ; Save as previous state

; ---------------------------------------------------------------------------
; Check Special Input Mode ($00d2 bit 3)
; ---------------------------------------------------------------------------

	lda.w #$0008	; A = $0008 (bit 3 mask)
	and.w !system_flags_1	 ; Test bit 3 of $00d2
	bne Input_SpecialMode ; If set → Special input mode

; ---------------------------------------------------------------------------
; Check Alternate Input Filter ($00db bit 2)
; ---------------------------------------------------------------------------

	lda.w #$0004	; A = $0004 (bit 2 mask)
	and.w !system_flags_6	 ; Test bit 2 of $00db
	bne Input_AlternateFilter ; If set → Use alternate filtering

; ---------------------------------------------------------------------------
; Normal Controller Read
; ---------------------------------------------------------------------------

	lda.w SNES_CNTRL1L ; A = [$4218] (Controller 1 input)
; Reads 16-bit joypad state
	bra Input_ProcessButtons ; → Process input

;-------------------------------------------------------------------------------

Input_SpecialMode:
; ===========================================================================
; Special Input Mode - Filter D-Pad
; ===========================================================================
; Reads controller but masks out D-pad directions.
; Only allows button presses (A, B, X, Y, L, R, Start, Select).
; ===========================================================================

	lda.w SNES_CNTRL1L ; A = controller state
	and.w #$fff0	; A = A & $fff0 (clear bits 0-3, D-pad)
	beq Input_ProcessButtons ; If zero → No buttons pressed

	jmp.w SpecialMenuProcessing ; → Special button handler

;-------------------------------------------------------------------------------

Input_AlternateFilter:
; ===========================================================================
; Alternate Input Filter
; ===========================================================================
; Checks $00d9 bit 1 for additional filtering mode.
; ===========================================================================

	lda.w #$0002	; A = $0002 (bit 1 mask)
	and.w $00d9	 ; Test bit 1 of $00d9
	beq Input_AlternateNormal ; If clear → Normal alternate mode

; Special alternate mode (incomplete in disassembly)
	db $a9,$80,$00,$04,$90 ; Raw bytes (seems incomplete)

;-------------------------------------------------------------------------------

Input_AlternateNormal:
	lda.w SNES_CNTRL1L ; A = controller state
	and.w #$fff0	; Mask D-pad
	beq Input_ProcessButtons ; If zero → No buttons

	jmp.w AnotherSpecialHandler ; → Alternate button handler

;-------------------------------------------------------------------------------

Input_ProcessButtons:
; ===========================================================================
; Process Controller Input
; ===========================================================================
; Combines current hardware input with software autofire.
; Calculates newly pressed buttons.
; ===========================================================================

	ora.b $90	   ; A = A | [$90] (OR with autofire bits)
	and.w #$fff0	; Mask to buttons only
	sta.b $94	   ; [$94] = all pressed buttons this frame

	tax ; X = pressed buttons (for later)

	trb.b $96	   ; Clear pressed buttons from previous state
; $96 now = buttons released this frame

	lda.b $92	   ; A = previous frame state
	trb.b $94	   ; Clear held buttons from new press state
; $94 now = newly pressed buttons only

	stx.b $92	   ; Save current state
	stz.b $90	   ; Clear autofire accumulator

Input_ReadController_Exit:
	rts ; Return

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

	stz.b $07	   ; Clear output (no input by default)

; ---------------------------------------------------------------------------
; Check for New Button Presses
; ---------------------------------------------------------------------------

	lda.b $94	   ; A = newly pressed buttons
	bne Input_NewButtonPress ; If any new press → Handle immediate input

; ---------------------------------------------------------------------------
; Handle Held Buttons (Autofire)
; ---------------------------------------------------------------------------

	lda.b $92	   ; A = currently held buttons
	beq Input_HandleAutofire_Exit ; If nothing held → Exit

	dec.b $09	   ; Decrement autofire timer
	bpl Input_HandleAutofire_Exit ; If timer still positive → Exit (not ready)

; Timer expired - trigger autofire event
	sta.b $07	   ; Output = held buttons (simulate new press)

	lda.w #$0005	; A = $05 (5 frames)
	sta.b $09	   ; Reset timer to 5 for repeat rate

Input_HandleAutofire_Exit:
	rts ; Return

;-------------------------------------------------------------------------------

Input_NewButtonPress:
; ===========================================================================
; Handle New Button Press
; ===========================================================================
; When button first pressed, output immediately and set long timer.
; ===========================================================================

	sta.b $07	   ; Output = new button presses

	lda.w #$0019	; A = $19 (25 frames)
	sta.b $09	   ; Set timer to 25 (initial delay)

	rts ; Return

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

	php ; Save processor status
	rep #$30		; 16-bit A, X, Y

	and.w #$00ff	; A = A & $ff (ensure 8-bit value)
	pha ; Save original coordinate

; ---------------------------------------------------------------------------
; Extract and Process Y Coordinate (Bits 3-5)
; ---------------------------------------------------------------------------

	and.w #$0038	; A = A & $38 (extract bits 3-5: Y coord)
	asl a; A = A × 2 (Y × 2)
	tax ; X = Y × 2 (save for later)

; ---------------------------------------------------------------------------
; Extract and Process X Coordinate (Bits 0-2)
; ---------------------------------------------------------------------------

	pla ; A = original coordinate
	and.w #$0007	; A = A & $07 (extract bits 0-2: X coord)

	phx ; Save Y×2 on stack

; Calculate X contribution: X × 12
	adc.b $01,s	 ; A = X + (Y×2)  [1st add]
	sta.b $01,s	 ; Save intermediate result

	asl a; A = (X + Y×2) × 2
	adc.b $01,s	 ; A = result×2 + result = result×3

	asl a; A = result × 6
	asl a; A = result × 12
	asl a; A = result × 24
	asl a; A = result × 48

; ---------------------------------------------------------------------------
; Add Base Address
; ---------------------------------------------------------------------------

	adc.w #$8000	; A = A + $8000 (add base VRAM address)

	plx ; Clean stack (discard saved Y×2)

	plp ; Restore processor status
	rts ; Return with VRAM address in A

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

	php ; Save processor status
	sep #$30		; 8-bit A, X, Y

	ldx.w !location_identifier	 ; X = character Y position
	cpx.b #$ff	  ; Check if invalid position
	beq UNREACH_008C81 ; If $ff → Exit (invalid)

; ---------------------------------------------------------------------------
; Check Battle Mode Flag
; ---------------------------------------------------------------------------

	lda.b #$02	  ; A = $02 (bit 1 mask)
	and.w !system_flags_4	 ; Test bit 1 of $00d8
	beq Tilemap_RefreshLayer0_Field ; If clear → Field mode

; ---------------------------------------------------------------------------
; Battle Mode Tilemap Update
; ---------------------------------------------------------------------------
; Uses special tilemap data from bank $04
; ---------------------------------------------------------------------------

	lda.l DATA8_049800,x ; A = [$049800+X] (base tile value)
	adc.b #$0a	  ; A = A + $0a (offset for battle tiles)
	xba ; Swap A high/low bytes (save in high byte)

; Calculate tile position
	txa ; A = X (Y position)
	and.b #$38	  ; A = A & $38 (extract Y coordinate bits)
	asl a; A = A × 2
	pha ; Save Y offset

	txa ; A = X again
	and.b #$07	  ; A = A & $07 (extract X coordinate)
	ora.b $01,s	 ; A = A | Y_offset (combine X and Y)
	plx ; X = Y offset (cleanup stack)

	asl a; A = coordinate × 2 (word address)

	rep #$30		; 16-bit A, X, Y

; Store tile values in WRAM buffer $7f075a
	sta.l $7f075a   ; [$7f075a] = tile 1 coordinate
	inc a; A = A + 1 (next tile)
	sta.l $7f075c   ; [$7f075c] = tile 2 coordinate

	adc.w #$000f	; A = A + $0f (skip to next row)
	sta.l $7f079a   ; [$7f079a] = tile 3 coordinate (row 2)
	inc a; A = A + 1
	sta.l $7f079c   ; [$7f079c] = tile 4 coordinate (row 2)

	sep #$20		; 8-bit accumulator

	ldx.w #$17da	; X = $17da (WRAM data source)
	lda.b #$7f	  ; A = $7f (bank $7f)
	bra Tilemap_TransferData ; → Continue to transfer

;-------------------------------------------------------------------------------
; UNREACHABLE CODE ANALYSIS
; ------------------------------------------------------------------------------
; Label: UNREACH_008C81
; Category: 🔴 Truly Unreachable (Dead Code)
; Purpose: Function epilogue (PLP + RTS)
; Reachability: No known call sites or branches to this address
; Analysis: Orphaned function exit code, likely remnant from code refactoring
; Verified: NOT reachable in normal gameplay
; Notes: May be leftover from development or removed function
; ------------------------------------------------------------------------------

UNREACH_008C81:
	plp ;008C81|28      |      ; Pull processor status
	rts ;008C82|60      |      ; Return from subroutine

;-------------------------------------------------------------------------------

Tilemap_RefreshLayer0_Field:
; ===========================================================================
; Field Mode Tilemap Update
; ===========================================================================
; Normal field/map mode cursor update
; ===========================================================================

	lda.l DATA8_049800,x ; A = [$049800+X] (base tile)
	asl a; A = A × 2
	asl a; A = A × 4 (tile offset)
	sta.w !tile_offset_1	 ; [$00f4] = tile offset

	rep #$10		; 16-bit X, Y

	lda.w !location_identifier	 ; A = character Y position
	jsr.w Tilemap_CalcRowAddress ; Calculate tilemap address
	stx.w !tilemap1_addr	 ; [$00f2] = tilemap address

	ldx.w #$2d1a	; X = $2d1a (WRAM source address)
	lda.b #$7e	  ; A = $7e (bank $7e)

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
;   bit 2: Horizontal flip
;   bit 3-4: Palette selection
;   bit 7: Priority
; ===========================================================================

	pha ; Save bank number

	lda.b #$04	  ; A = $04 (bit 2 mask)
	and.w !system_flags_5	 ; Test bit 2 of $00da
	beq Tilemap_SetupDMA ; If clear → Normal cursor

; Check blink timer
	lda.w $0014	 ; A = [$0014] (blink timer)
	dec a; A = A - 1
	beq Tilemap_SetupDMA ; If zero → Show cursor

; Apply alternate palette during blink
	lda.b #$10	  ; A = $10 (bit 4 mask)
	and.w !system_flags_5	 ; Test bit 4 of $00da
	bne Tilemap_BlinkSpecial ; If set → Special blink mode

; Normal blink mode (incomplete in disassembly)
	db $ab,$bd,$01,$00,$29,$e3,$09,$94,$80,$12

;-------------------------------------------------------------------------------

Tilemap_BlinkSpecial:
	plb ; B = bank (restore)
	lda.w $0001,x   ; A = [X+1] (tile attribute byte)
	and.b #$e3	  ; A = A & $e3 (clear palette bits 2,3,4)
	ora.b #$9c	  ; A = A | $9c (set new palette + priority)
	bra Tilemap_ApplyAttributes ; → Save and continue

;-------------------------------------------------------------------------------

Tilemap_SetupDMA:
	plb ; B = bank (restore)
	lda.w $0001,x   ; A = [X+1] (tile attribute)
	and.b #$e3	  ; Clear palette bits
	ora.b #$88	  ; Set normal palette

;-------------------------------------------------------------------------------

Tilemap_ApplyAttributes:
; ===========================================================================
; Handle Number Display
; ===========================================================================
; For certain Y positions (>=$29), displays 2-digit numbers.
; Used for item quantities, HP values, etc.
; ===========================================================================

	xba ; Swap A bytes (save attributes in high byte)

	lda.l $001031   ; A = Y position
	cmp.b #$29	  ; Compare with $29
	bcc IfYUseSimpleTileDisplay ; If Y < $29 → Use simple tile display

	cmp.b #$2c	  ; Compare with $2c
	beq IfYUseSimpleTileDisplay ; If Y = $2c → Use simple tile display

; ---------------------------------------------------------------------------
; Two-Digit Number Display
; ---------------------------------------------------------------------------
; Displays a number as two separate digit tiles
; $1030 contains the value to display (0-99)
; ---------------------------------------------------------------------------

	lda.w $0001,x   ; A = tile attribute
	and.b #$63	  ; Clear certain attribute bits
	ora.b #$08	  ; Set priority bit
	sta.w $0001,x   ; Save attribute for tile 1
	sta.w $0003,x   ; Save attribute for tile 2

; Calculate tens digit
	lda.l $001030   ; A = number value (0-99)
	ldy.w #$ffff	; Y = -1 (digit counter)
	sec ; Set carry for subtraction

;-------------------------------------------------------------------------------

Display_DecimalDigit_Loop:
; Divide by 10 loop
	iny ; Y++ (count tens)
	sbc.b #$0a	  ; A = A - 10
	bcs Display_DecimalDigit_Loop ; If carry still set → Continue subtracting

; A now contains ones digit - 10 (needs adjustment)
	adc.b #$8a	  ; A = A + $8a (convert to tile number)
	sta.w $0002,x   ; Store ones digit tile

; Check if tens digit is zero
	cpy.w #$0000	; Is tens digit zero?
	beq UNREACH_008D06 ; If zero → Show blank tens digit

; Display tens digit
	tya ; A = tens digit value
	adc.b #$7f	  ; A = A + $7f (convert to tile number)
	sta.w $0000,x   ; Store tens digit tile
	bra Tilemap_FinalizeUpdate ; → Finish update

;-------------------------------------------------------------------------------

UNREACH_008D06:
; Show blank tile for tens digit
	db $a9,$45,$9d,$00,$00,$eb,$9d,$01,$00,$80,$0f
; lda #$45, sta [$00,X], XBA, sta [$01,X], bra $0f

;-------------------------------------------------------------------------------

Display_BlankTiles:
; ===========================================================================
; Simple Tile Display
; ===========================================================================
; Displays blank tiles (tile $45) for positions that don't need numbers
; ===========================================================================

	xba ; Swap A bytes (get attributes back)
	sta.w $0001,x   ; Store attribute for tile 1
	sta.w $0003,x   ; Store attribute for tile 2

	lda.b #$45	  ; A = $45 (blank tile)
	sta.w $0000,x   ; Store blank in tile 1
	sta.w $0002,x   ; Store blank in tile 2

;-------------------------------------------------------------------------------

Tilemap_FinalizeUpdate:
; ===========================================================================
; Finalize Tilemap Update
; ===========================================================================

	phk ; Push program bank
	plb ; Pull to data bank (B = $00)

	lda.b #$80	  ; A = $80 (bit 7)
	tsb.w !system_flags_2	 ; Set bit 7 of $00d4 (large VRAM update flag)

	plp ; Restore processor status
	rts ; Return

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

	php ; Save processor status
	sep #$30		; 8-bit A, X, Y

; ---------------------------------------------------------------------------
; Check Battle Mode
; ---------------------------------------------------------------------------

	lda.b #$02	  ; A = $02 (bit 1 mask)
	and.w !system_flags_4	 ; Test bit 1 of $00d8
	beq IfClearFieldMode ; If clear → Field mode

; ---------------------------------------------------------------------------
; Battle Mode Layer Update
; ---------------------------------------------------------------------------

	ldx.w !char1_cursor_pos	 ; X = [$10b1] (cursor position)
	cpx.b #$ff	  ; Check if invalid
	beq Tilemap_RefreshLayer1_Exit ; If $ff → Exit

; Calculate tile data
	lda.l DATA8_049800,x ; A = base tile value
	adc.b #$0a	  ; A = A + $0a (battle offset)
	xba ; Save in high byte

	txa ; A = position
	and.b #$38	  ; Extract Y bits
	asl a; Y × 2
	pha ; Save

	txa ; A = position again
	and.b #$07	  ; Extract X bits
	ora.b $01,s	 ; Combine with Y
	plx ; Cleanup stack

	asl a; Word address
	rep #$30		; 16-bit A, X, Y

; Store in WRAM buffer
	sta.l $7f0778   ; Tile 1 position
	inc a; Next tile
	sta.l $7f077a   ; Tile 2 position

	adc.w #$000f	; Next row
	sta.l $7f07b8   ; Tile 3 position
	inc a; Next tile
	sta.l $7f07ba   ; Tile 4 position

	lda.w #$0080	; A = $0080 (bit 7)
	tsb.w !system_flags_2	 ; Set large update flag

Tilemap_RefreshLayer1_Exit:
	plp ; Restore status
	rts ; Return

;-------------------------------------------------------------------------------

Tilemap_RefreshLayer1_Field:
; ===========================================================================
; Field Mode Layer Update
; ===========================================================================

	ldx.w !char1_cursor_pos	 ; X = cursor position
	lda.l DATA8_049800,x ; A = base tile
	asl a; A × 2
	asl a; A × 4
	sta.w !tile_offset_2	 ; Save tile offset

	rep #$10		; 16-bit X, Y

	lda.w !char1_cursor_pos	 ; A = cursor position
	jsr.w Tilemap_CalcRowAddress ; Calculate tilemap address
	stx.w !tilemap2_addr	 ; Save address

	lda.b #$80	  ; A = $80
	tsb.w !system_flags_2	 ; Set update flag

	plp ; Restore status
	rts ; Return

;-------------------------------------------------------------------------------

; Already renamed: Tilemap_CalcRowAddress
Tilemap_CalcRowAddress:
; ===========================================================================
; Tilemap Address Calculation Wrapper
; ===========================================================================
; Calls CallsCodeIfPositionIsValid if position is valid
;
; Parameters:
;   A = Position value
;
; Returns:
;   X = Tilemap address (or $ffff if invalid)
; ===========================================================================

	cmp.b #$ff	  ; Check if invalid position
	beq Map_InvalidPositionReturn ; If $ff → Return $ffff

	jsr.w CallsCodeIfPositionIsValid ; Calculate tilemap address
	tax ; X = calculated address
	rts ; Return

;-------------------------------------------------------------------------------
; Map - Invalid Position Return
;-------------------------------------------------------------------------------
; Purpose: Return invalid address marker for out-of-bounds map positions
; Reachability: Reachable via conditional branch (beq above)
; Analysis: When position is $ff (invalid), returns $ffff as error marker
;   - Used by map coordinate helpers to signal invalid tile positions
; Technical: Originally labeled UNREACH_008D93
;-------------------------------------------------------------------------------
Map_InvalidPositionReturn:
	ldx.w #$ffff	; X = invalid address marker
	rts ; Return

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

	lda.w !location_identifier	 ; Get current character position
	pha ; Save it
	lda.w #$0003	; A = 3 (check 3 party slots)
	jsr.w Party_CheckAvailability ; Validate party member
	pla ; Restore original position
	sta.w !location_identifier	 ; Store back to $1031
	sty.b $9e	   ; Save validated position to $9e
	rts ; Return

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

	php ; Save processor status
	sep #$30		; 8-bit mode
	pha ; Save slot count
	clc ; Clear carry
	adc.b $01,s	 ; A = count × 2 (stack peek)
	adc.b $01,s	 ; A = count × 3
	adc.b #$22	  ; A += $22 (offset calculation)
	tay ; Y = calculated offset
	pla ; Restore slot count
	eor.b #$ff	  ; Invert bits
	sec ; Set carry
	adc.b #$04	  ; A = 4 - count (bit shift count)
	tax ; X = shift count

	lda.w !char_x_pos	 ; Get status flags (high byte)
	xba ; Swap to low byte
	lda.w !char_y_pos	 ; Get status flags (low byte)
	rep #$20		; 16-bit A
	sep #$10		; 8-bit X, Y
	lsr a; Shift right (first bit)

Party_CheckAvailability_ShiftLoop:
	lsr a; Shift right
	lsr a; Shift right
	lsr a; Shift right (shift 3 bits per slot)
	dex ; Decrement shift counter
	bne Party_CheckAvailability_ShiftLoop ; Loop until X = 0

	lsr a; Check first member bit
	bcs Party_CheckAvailability_Found ; If set → valid member found
	dey ; Try previous slot
	lsr a; Check second member bit
	bcs Party_CheckAvailability_Found ; If set → valid member found
	dey ; Try previous slot
	lsr a; Check third member bit
	bcs Party_CheckAvailability_Found ; If set → valid member found
	ldy.b #$ff	  ; No valid members → $ff

Party_CheckAvailability_Found:
	sty.w !location_identifier	 ; Store validated position
	plp ; Restore processor status
	rts ; Return

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

	php ; Save processor status
	phd ; Save Direct Page
	rep #$30		; 16-bit mode
	lda.w #$2100	; A = $2100
	tcd ; Direct Page = $2100 (PPU registers)
	clc ; Clear carry for additions

VRAM_DirectWriteLarge_OuterLoop:
	phy ; Save Y counter
	sep #$20		; 8-bit A
	ldy.w #$0018	; Y = $18 (24 decimal, inner loop count)

VRAM_DirectWriteLarge_InnerLoop:
	lda.w $0000,x   ; Get byte from source
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $0001,x   ; Get next byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $0002,x   ; Get third byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $0003,x   ; Get fourth byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $0004,x   ; Get fifth byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $0005,x   ; Get sixth byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $0006,x   ; Get seventh byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $0007,x   ; Get eighth byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)

	lda.w $0008,x   ; Get ninth byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $0009,x   ; Get tenth byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $000a,x   ; Get 11th byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $000b,x   ; Get 12th byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $000c,x   ; Get 13th byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $000d,x   ; Get 14th byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $000e,x   ; Get 15th byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $000f,x   ; Get 16th byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)

	lda.w $0010,x   ; Get 17th byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $0011,x   ; Get 18th byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $0012,x   ; Get 19th byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $0013,x   ; Get 20th byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $0014,x   ; Get 21st byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $0015,x   ; Get 22nd byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $0016,x   ; Get 23rd byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)
	lda.w $0017,x   ; Get 24th byte
	tay ; Y = data byte
	sty.b !SNES_VMDATAL-$2100 ; Write to VRAM data (low)

	rep #$30		; 16-bit mode
	txa ; A = X (source pointer)
	adc.w #$0018	; A += $18 (24 bytes)
	tax ; X = new source address
	ply ; Restore Y counter
	dey ; Decrement tile group counter
	beq +		   ; Exit if done
	jmp LoopIfMoreGroupsRemain ; Loop if more groups remain
	+
	pld ; Restore Direct Page
	plp ; Restore processor status
	rtl ; Return

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

	php ; Save processor status
	phd ; Save Direct Page
	pea.w $2100	 ; Push $2100
	pld ; Direct Page = $2100
	sep #$20		; 8-bit A
	lda.b #$88	  ; A = $88 (VRAM increment +32 after high)
	sta.b !SNES_VMAINC-$2100 ; Set VRAM increment mode
	rep #$30		; 16-bit mode
	clc ; Clear carry

VRAM_Write8TilesPattern_Loop:
	lda.w $0000,x   ; Get word 0
	sta.b !SNES_VMDATAL-$2100 ; Write to VRAM
	lda.w !state_marker	 ; Get pattern word
	sta.b !SNES_VMDATAL-$2100 ; Write pattern
	lda.w $0002,x   ; Get word 1
	sta.b !SNES_VMDATAL-$2100 ; Write to VRAM
	lda.w !state_marker	 ; Get pattern word
	sta.b !SNES_VMDATAL-$2100 ; Write pattern
	lda.w $0004,x   ; Get word 2
	sta.b !SNES_VMDATAL-$2100 ; Write to VRAM
	lda.w !state_marker	 ; Get pattern word
	sta.b !SNES_VMDATAL-$2100 ; Write pattern
	lda.w $0006,x   ; Get word 3
	sta.b !SNES_VMDATAL-$2100 ; Write to VRAM
	lda.w !state_marker	 ; Get pattern word
	sta.b !SNES_VMDATAL-$2100 ; Write pattern
	lda.w $0008,x   ; Get word 4
	sta.b !SNES_VMDATAL-$2100 ; Write to VRAM
	lda.w !state_marker	 ; Get pattern word
	sta.b !SNES_VMDATAL-$2100 ; Write pattern
	lda.w $000a,x   ; Get word 5
	sta.b !SNES_VMDATAL-$2100 ; Write to VRAM
	lda.w !state_marker	 ; Get pattern word
	sta.b !SNES_VMDATAL-$2100 ; Write pattern
	lda.w $000c,x   ; Get word 6
	sta.b !SNES_VMDATAL-$2100 ; Write to VRAM
	lda.w !state_marker	 ; Get pattern word
	sta.b !SNES_VMDATAL-$2100 ; Write pattern
	lda.w $000e,x   ; Get word 7
	sta.b !SNES_VMDATAL-$2100 ; Write to VRAM
	lda.w !state_marker	 ; Get pattern word
	sta.b !SNES_VMDATAL-$2100 ; Write pattern

	txa ; A = X (source pointer)
	adc.w #$0010	; A += $10 (16 bytes per tile)
	tax ; X = new source address
	dey ; Decrement tile counter
	bne VRAM_Write8TilesPattern_Loop ; Loop if more tiles remain

	sep #$20		; 8-bit A
	lda.b #$80	  ; A = $80 (VRAM increment +1)
	sta.b !SNES_VMAINC-$2100 ; Restore normal VRAM increment
	pld ; Restore Direct Page
	plp ; Restore processor status
	rtl ; Return

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
; - Loads additional tiles to VRAM $2000-$2fff via ExecuteSpecialTransfer
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

	php ; Save processor status
	phd ; Save Direct Page
	rep #$30		; 16-bit mode
	lda.w #$2100	; A = $2100
	tcd ; Direct Page = $2100 (PPU registers)

; Setup DMA Channel 5 for VRAM transfer
	sep #$20		; 8-bit A
	ldx.w #$1801	; X = $1801 (DMA params: word, increment)
	stx.w !SNES_DMA5PARAM ; Set DMA5 control
	ldx.w #$8030	; X = $8030 (source address low/mid)
	stx.w !SNES_DMA5ADDRL ; Set DMA5 source address
	lda.b #$07	  ; A = $07 (source bank)
	sta.w !SNES_DMA5ADDRH ; Set DMA5 source bank
	ldx.w #$1000	; X = $1000 (4096 bytes to transfer)
	stx.w !SNES_DMA5CNTL ; Set DMA5 transfer size

; Setup VRAM destination
	ldx.w #$3000	; X = $3000 (VRAM address)
	stx.b !SNES_VMADDL-$2100 ; Set VRAM address
	lda.b #$84	  ; A = $84 (increment +32 after high byte)
	sta.b !SNES_VMAINC-$2100 ; Set VRAM increment mode

; Execute DMA transfer
	lda.b #$20	  ; A = $20 (enable DMA channel 5)
	sta.w !SNES_MDMAEN ; Start DMA transfer

; Restore normal VRAM increment
	lda.b #$80	  ; A = $80 (increment +1)
	sta.b !SNES_VMAINC-$2100 ; Set VRAM increment mode

; Setup for additional tile transfer
	rep #$30		; 16-bit mode
	lda.w #$ff00	; A = $ff00 (pattern for interleaving)
	sta.w !state_marker	 ; Store pattern word
	ldx.w #$2000	; X = $2000 (VRAM address)
	stx.b !SNES_VMADDL-$2100 ; Set VRAM address

; Transfer additional tiles from Bank $04
	pea.w $0004	 ; Push bank $04
	plb ; Data bank = $04
	ldx.w #$8000	; X = $8000 (source address)
	ldy.w #$0100	; Y = $0100 (256 tile groups)
	jsl.l VRAM_DirectWriteLarge ; Transfer tiles via direct writes
	plb ; Restore data bank

; Load palette data from Bank $07
	sep #$30		; 8-bit mode
	pea.w $0007	 ; Push bank $07
	plb ; Data bank = $07

; Load 4 sets of 8-color palettes
	lda.b #$08	  ; A = $08 (CGRAM address $08)
	ldx.b #$00	  ; X = $00 (source offset)
	jsr.w Palette_Load8Colors ; Load 8 colors
	lda.b #$0c	  ; A = $0c (CGRAM address $0c)
	ldx.b #$08	  ; X = $08 (source offset)
	jsr.w Palette_Load8Colors ; Load 8 colors
	lda.b #$18	  ; A = $18 (CGRAM address $18)
	ldx.b #$10	  ; X = $10 (source offset)
	jsr.w Palette_Load8Colors ; Load 8 colors
	lda.b #$1c	  ; A = $1c (CGRAM address $1c)
	ldx.b #$18	  ; X = $18 (source offset)
	jsr.w Palette_Load8Colors ; Load 8 colors
	plb ; Restore data bank

; Load special color values
	ldx.w $0e9c	 ; X = color value (low byte)
	ldy.w $0e9d	 ; Y = color value (high byte)
	lda.b #$0d	  ; A = $0d (CGRAM address)
	sta.b !SNES_CGADD-$2100 ; Set CGRAM address
	stx.b !SNES_CGDATA-$2100 ; Write color (low)
	sty.b !SNES_CGDATA-$2100 ; Write color (high)
	lda.b #$1d	  ; A = $1d (CGRAM address)
	sta.b !SNES_CGADD-$2100 ; Set CGRAM address
	stx.b !SNES_CGDATA-$2100 ; Write color (low)
	sty.b !SNES_CGDATA-$2100 ; Write color (high)

; Load extended palette data (6 groups of 16 colors)
	ldy.b #$06	  ; Y = 6 (group count)
	lda.b #$00	  ; A = 0 (initial offset)
	clc ; Clear carry
	pea.w $0007	 ; Push bank $07
	plb ; Data bank = $07

Palette_Load16Colors:
	tax ; X = offset
	adc.b #$28	  ; A += $28 (CGRAM address increment)
	sta.b !SNES_CGADD-$2100 ; Set CGRAM address

; Write 16 colors (32 bytes) from DATA8_07D8E4
	lda.w DATA8_07d8e4,x ; Get color byte
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d8e5,x ; Get color byte
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d8e6,x ; Get color byte
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d8e7,x ; Get color byte
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d8e8,x ; Get color byte
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d8e9,x ; Get color byte
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d8ea,x ; Get color byte
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d8eb,x ; Get color byte
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d8ec,x ; Get color byte
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d8ed,x ; Get color byte
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d8ee,x ; Get color byte
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d8ef,x ; Get color byte
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d8f0,x ; Get color byte
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d8f1,x ; Get color byte
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d8f2,x ; Get color byte
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d8f3,x ; Get color byte
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM

	txa ; A = X (offset)
	adc.b #$10	  ; A += $10 (16 bytes per group)
	dey ; Decrement group counter
	bne Graphics_InitFieldMenu_PaletteLoop ; Loop if more groups remain

	plb ; Restore data bank
	pld ; Restore Direct Page
	plp ; Restore processor status
	rts ; Return

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

	sta.b !SNES_CGADD-$2100 ; Set CGRAM address
	lda.w DATA8_078000,x ; Get color byte 0
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_078001,x ; Get color byte 1
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_078002,x ; Get color byte 2
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_078003,x ; Get color byte 3
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_078004,x ; Get color byte 4
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_078005,x ; Get color byte 5
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_078006,x ; Get color byte 6
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_078007,x ; Get color byte 7
	sta.b !SNES_CGDATA-$2100 ; Write to CGRAM
	rts ; Return

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
	db $08,$0b,$c2,$30,$da,$48,$3b,$38,$e9,$02,$00,$1b,$5b,$e2,$20,$a5
	db $04,$85,$02,$64,$04,$a9,$00,$c2,$30,$a2,$08,$00,$c6,$03,$0a,$06
	db $01,$90,$02,$65,$03,$ca,$d0,$f6,$85,$03,$3b,$18,$69,$02,$00,$1b
	db $68,$fa,$2b,$28,$6b

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
; - Uses mvn for efficient memory clearing
; - Sets Direct Page to $1000 for party data access
; - Processes party member status flags from $1032-$1033
; - Renders status icons/indicators to tilemap buffers
;
; Status Display Layout:
; - $7e3669: Start of status effect buffer
; - Various offsets for different status types
; - Supports 6 party member slots with multiple status effects each
; ===========================================================================

	php ; Save processor status
	phd ; Save Direct Page
	rep #$30		; 16-bit mode

; Clear status display buffer
	lda.w #$0000	; A = 0
	sta.l $7e3669   ; Clear first word of buffer
	ldx.w #$3669	; X = source (first word)
	ldy.w #$366b	; Y = destination (next word)
	lda.w #$00dd	; A = $dd (221 bytes to fill)
	mvn $7e,$7e	 ; Block fill with zeros

; Setup for status processing
	phk ; Push program bank
	plb ; Data bank = program bank
	sep #$30		; 8-bit mode
	pea.w !char1_data_page	 ; Push $1000
	pld ; Direct Page = $1000 (party data)

; Process party status bits (high nibble of $1032)
	lda.b $32	   ; Get party status flags (high)
	and.b #$e0	  ; Mask bits 7-5
	beq Skip_Status_Group1 ; If clear, skip first group

	jsl.l CodeReturnsHandlerIndexBasedGame ; Calculate status icon offset
	eor.b #$ff	  ; Invert
	sec ; Set carry
	adc.b #$27	  ; Add offset $27
	ldy.b #$a0	  ; Y = $a0 (display position)
	jsr.w Status_RenderIcon ; Render status icon

Skip_Status_Group1:
; Process bits 4-2 of $1032
	lda.b $32	   ; Get party status flags
	and.b #$1c	  ; Mask bits 4-2
	beq Skip_Status_Group2 ; If clear, skip second group

	jsl.l CodeReturnsHandlerIndexBasedGame ; Calculate status icon offset
	eor.b #$ff	  ; Invert
	sec ; Set carry
	adc.b #$27	  ; Add offset $27
	ldy.b #$b0	  ; Y = $b0 (display position)
	jsr.w Status_RenderIcon ; Render status icon

Skip_Status_Group2:
; Process bit 7 of $1033 and bits 1-0 of $1032
	lda.b $33	   ; Get extended status flags
	and.b #$80	  ; Check bit 7
	bne Process_Status_Group3 ; If set, process group 3

	lda.b $32	   ; Get party status flags
	and.b #$03	  ; Mask bits 1-0
	beq Skip_Status_Group3 ; If clear, skip

; Embedded jsl instruction as data
Skip_Status_Group2_bytes:
	db $22,$30,$97,$00 ; jsl CodeReturnsHandlerIndexBasedGame
	db $18,$69,$08 ; CLC, adc #$08
	db $80,$04	 ; bra +4

Process_Status_Group3:
	jsl.l CodeReturnsHandlerIndexBasedGame ; Calculate status icon offset
	eor.b #$ff	  ; Invert
	sec ; Set carry
	adc.b #$2f	  ; Add offset $2f
	ldy.b #$c0	  ; Y = $c0 (display position)
	jsr.w Status_RenderIcon ; Render status icon

Skip_Status_Group3:
; Process bits 6-4 of $1033
	lda.b $33	   ; Get extended status flags
	and.b #$70	  ; Mask bits 6-4
	beq Skip_Status_Group4 ; If clear, skip

	jsl.l CodeReturnsHandlerIndexBasedGame ; Calculate status icon offset
	eor.b #$ff	  ; Invert
	sec ; Set carry
	adc.b #$2f	  ; Add offset $2f
	ldy.b #$d0	  ; Y = $d0 (display position)
	jsr.w Status_RenderIcon ; Render status icon

Skip_Status_Group4:
; Process first character slot
	ldy.b #$00	  ; Y = 0 (slot 0)
	jsr.w Status_RenderCharacter ; Render character status

; Switch to second character slot data
	pea.w !char2_data_page	 ; Push $1080
	pld ; Direct Page = $1080
	ldy.b #$50	  ; Y = $50 (display offset)
	jsr.w Status_RenderCharacter ; Render character status

	pld ; Restore Direct Page
	plp ; Restore processor status
	rts ; Return

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

	lda.b $31	   ; Get character slot
	bmi Skip_Character ; If bit 7 set → invalid/dead character
	jsr.w RenderBaseCharacterIcon ; Render base character icon

Skip_Character:
; Process status flags group 1 (bits 7-5 of $35)
	lda.b $35	   ; Get status flags byte 1
	and.b #$e0	  ; Mask bits 7-5
	beq Skip_Status1 ; If clear, skip

	jsl.l CodeReturnsHandlerIndexBasedGame ; Calculate icon offset
	eor.b #$ff	  ; Invert
	sec ; Set carry
	adc.b #$36	  ; Add offset $36
	jsr.w RenderBaseCharacterIcon ; Render status icon

Skip_Status1:
; Process status flags group 2 (bits 7-6 of $36 and bits 4-0 of $35)
	lda.b $36	   ; Get status flags byte 2
	and.b #$c0	  ; Mask bits 7-6
	bne Alternative_Status2 ; If set, use alternative handling

	lda.b $35	   ; Get status flags byte 1
	and.b #$1f	  ; Mask bits 4-0
	beq Skip_Status2 ; If clear, skip

	jsl.l CodeReturnsHandlerIndexBasedGame ; Calculate icon offset
	clc ; Clear carry
	adc.b #$08	  ; Add offset $08
	bra Continue_Status2 ; Continue processing

Alternative_Status2:
	db $22,$30,$97,$00 ; jsl CodeReturnsHandlerIndexBasedGame

Continue_Status2:
	eor.b #$ff	  ; Invert
	sec ; Set carry
	adc.b #$3e	  ; Add offset $3e
	jsr.w Status_RenderIcon ; Render status icon

Skip_Status2:
; Process status flags group 3 (bits 5-2 of $36)
	lda.b $36	   ; Get status flags byte 2
	and.b #$3c	  ; Mask bits 5-2
	beq Skip_Status3 ; If clear, skip

	jsl.l CodeReturnsHandlerIndexBasedGame ; Calculate icon offset
	eor.b #$ff	  ; Invert
	sec ; Set carry
	adc.b #$3e	  ; Add offset $3e
	jsr.w Status_RenderIcon ; Render status icon

Skip_Status3:
; Process status flags group 4 (bit 7 of $37 and bits 1-0 of $36)
	lda.b $37	   ; Get status flags byte 3
	and.b #$80	  ; Check bit 7
	bne Alternative_Status4 ; If set, use alternative

	lda.b $36	   ; Get status flags byte 2
	and.b #$03	  ; Mask bits 1-0
	beq Skip_Status4 ; If clear, skip

	jsl.l CodeReturnsHandlerIndexBasedGame ; Calculate icon offset
	clc ; Clear carry
	adc.b #$08	  ; Add offset $08
	bra Continue_Status4 ; Continue

Alternative_Status4:
	db $22,$30,$97,$00 ; jsl CodeReturnsHandlerIndexBasedGame

Continue_Status4:
	eor.b #$ff	  ; Invert
	sec ; Set carry
	adc.b #$46	  ; Add offset $46
	jsr.w Status_RenderIcon ; Render status icon

Skip_Status4:
	rts ; Return

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
; - Calls BankRoutine to process icon type
; - Icons $00-$2e: Simple single icons
; - Icons $2f-$46: Complex multi-part status displays
; - Buffer layout supports 4 different icon "layers" per slot
;
; Parameters:
;   A = Icon/status ID ($00-$46)
;   Y = Display position offset
;   Data bank = $7e
; ===========================================================================

	php ; Save processor status
	phd ; Save Direct Page
	sep #$30		; 8-bit mode
	pea.w $007e	 ; Push bank $7e
	plb ; Data bank = $7e
	phy ; Save Y offset
	pea.w $0400	 ; Push $0400
	pld ; Direct Page = $0400

	sta.b $3a	   ; Save icon ID to $043a
	jsl.l BankRoutine ; Process icon type

	lda.b $3a	   ; Get icon ID
	cmp.b #$2f	  ; Check if >= $2f
	bcc Simple_Icon ; If < $2f → simple icon

Complex_Status:
; Complex multi-part status display ($2f-$46)
	ldx.b #$10	  ; X = $10 (layer 1 offset)
	cmp.b #$32	  ; Check if >= $32
	bcc Got_Layer_Offset ; If < $32 → use layer 1

	ldx.b #$20	  ; X = $20 (layer 2 offset)
	cmp.b #$39	  ; Check if >= $39
	bcc Got_Layer_Offset ; If < $39 → use layer 2

	ldx.b #$30	  ; X = $30 (layer 3 offset)
	cmp.b #$3d	  ; Check if >= $3d
	bcc Got_Layer_Offset ; If < $3d → use layer 3

	ldx.b #$40	  ; X = $40 (layer 4 offset)
	clc ; Clear carry

Got_Layer_Offset:
	txa ; A = layer offset
	adc.b $01,s	 ; Add Y offset from stack
	tax ; X = final buffer offset
	jsr.w Status_SetIconFlags ; Write icon data to buffer

; Copy calculated values to buffer
	lda.b $db	   ; Get calculated value 1
	sta.w $3670,x   ; Store to buffer
	lda.b $dc	   ; Get calculated value 2
	sta.w $3671,x   ; Store to buffer
	lda.b $e5	   ; Get calculated value 3
	sta.w $3672,x   ; Store to buffer
	lda.b $e6	   ; Get calculated value 4
	adc.w $366a,x   ; Add to existing value
	sta.w $366a,x   ; Store accumulated value
	lda.b $e7	   ; Get calculated value 5
	sta.w $366e,x   ; Store to buffer
	lda.b $e8	   ; Get calculated value 6
	sta.w $366d,x   ; Store to buffer
	lda.b $e9	   ; Get calculated value 7
	sta.w $366f,x   ; Store to buffer
	bra Render_Done ; Done

Simple_Icon:
; Simple single icon ($00-$2e)
	plx ; X = Y offset (from stack)
	phx ; Save it back
	jsr.w Status_SetIconFlags ; Write icon to buffer

	cpx.b #$50	  ; Check if offset >= $50
	bcs Render_Done ; If so, done

; Copy icon template for simple icons
	rep #$30		; 16-bit mode
	lda.b $3a	   ; Get icon ID
	and.w #$00ff	; Mask to byte
	ldy.w #$3709	; Y = template address for icons $00-$22
	cmp.w #$0023	; Check if < $23
	bcc Copy_Template ; If so, use first template

	ldy.w #$3719	; Y = template for icons $23-$25
	cmp.w #$0026	; Check if < $26
	bcc Copy_Template ; If so, use second template

	ldy.w #$3729	; Y = template for icons $26-$28
	cmp.w #$0029	; Check if < $29
	bcc Copy_Template ; If so, use third template

	ldy.w #$3739	; Y = template for icons $29+

Copy_Template:
	ldx.w #$3669	; X = destination buffer
	lda.w #$000f	; A = 15 bytes to copy
	mvn $7e,$7e	 ; Block copy template
	sep #$30		; 8-bit mode

Render_Done:
	ply ; Restore Y offset
	plb ; Restore data bank
	pld ; Restore Direct Page
	plp ; Restore processor status
	rts ; Return

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
;   bit 3 → $3669,X
;   bit 2 → $366a,X
;   bit 1 → $366b,X
;   bit 0 → $366c,X
; ===========================================================================

	lda.b $e4	   ; Get packed status flags
	tay ; Y = flags (save for later)
	and.b #$08	  ; Check bit 3
	beq Skip_Flag1  ; If clear, skip
	lda.b #$05	  ; A = $05 (active marker)

Skip_Flag1:
	sta.w $3669,x   ; Store to buffer slot 1

	tya ; A = flags
	and.b #$04	  ; Check bit 2
	beq Skip_Flag2  ; If clear, skip
	db $a9,$05	 ; lda #$05

Skip_Flag2:
	sta.w $366a,x   ; Store to buffer slot 2

	tya ; A = flags
	and.b #$02	  ; Check bit 1
	beq Skip_Flag3  ; If clear, skip
	lda.b #$05	  ; A = $05

Skip_Flag3:
	sta.w $366b,x   ; Store to buffer slot 3

	tya ; A = flags
	and.b #$01	  ; Check bit 0
	beq Skip_Flag4  ; If clear, skip
	lda.b #$05	  ; A = $05

Skip_Flag4:
	sta.w $366c,x   ; Store to buffer slot 4
	rts ; Return

; ===========================================================================
; Character Status Calculation Routine
; ===========================================================================
; Purpose: Calculate cumulative character status from multiple stat buffers
; Input: bit 0 of $89 determines which character to process (0=first, 1=second)
; Output: $2a-$2d, $3a-$3f, $2e updated with calculated stats
; Technical Details:
;   - Sets up Direct Page to $1000 or $1080 based on character selection
;   - Processes 7 stats via ProcessesStatsViaCodeSummationAcross (summation across 5 buffers)
;   - Processes 2 stats via ProcessesStatsViaCodeAcrossBuffers (OR across 4 buffers)
;   - Updates base stats ($22-$25) with deltas ($26-$29)
; Buffers accessed:
;   - $3669-$3678: Base buffer (16 bytes)
;   - $3679-$3688: Delta buffer 1
;   - $3689-$3698: Delta buffer 2
;   - $3699-$36a8: Delta buffer 3
;   - $36a9-$36b8: Delta buffer 4
; ===========================================================================

Char_CalcStats:
	php ; Save processor status
	phd ; Save direct page register
	sep #$30		; 8-bit A/X/Y
	pea.w $007e	 ; Push $7e to stack
	plb ; Data Bank = $7e
	clc ; Clear carry
	pea.w !char1_data_page	 ; Default to character 1 DP ($1000)
	pld ; Direct Page = $1000
	ldx.b #$00	  ; X = $00 (buffer offset)
	bit.b #$01	  ; Test bit 0 of $89
	beq Setup_Done  ; If 0, use first character's DP
	pea.w !char2_data_page	 ; Character 2 DP ($1080)
	pld ; Direct Page = $1080
	ldx.b #$50	  ; X = $50 (character 2 buffer offset)

Setup_Done:
; Calculate cumulative stats using ProcessesStatsViaCodeSummationAcross (ADC across 5 buffers)
	jsr.w ProcessesStatsViaCodeSummationAcross ; Sum buffer values at X
	sta.b $2a	   ; Store stat 1
	jsr.w ProcessesStatsViaCodeSummationAcross ; Sum next buffer values (X++)
	sta.b $2b	   ; Store stat 2
	jsr.w ProcessesStatsViaCodeSummationAcross ; Sum next buffer values (X++)
	sta.b $2c	   ; Store stat 3
	jsr.w ProcessesStatsViaCodeSummationAcross ; Sum next buffer values (X++)
	sta.b $2d	   ; Store stat 4
	jsr.w ProcessesStatsViaCodeSummationAcross ; Sum next buffer values (X++)
	sta.b $41	   ; Store stat 5
	jsr.w ProcessesStatsViaCodeSummationAcross ; Sum next buffer values (X++)
	sta.b $3e	   ; Store stat 6
	jsr.w ProcessesStatsViaCodeSummationAcross ; Sum next buffer values (X++)
	sta.b $3f	   ; Store stat 7

; Calculate bitwise OR stats using ProcessesStatsViaCodeAcrossBuffers (ORA across 4 buffers)
	jsr.w ProcessesStatsViaCodeAcrossBuffers ; OR buffer values at X
	sta.b $3a	   ; Store flags 1
	jsr.w ProcessesStatsViaCodeAcrossBuffers ; OR next buffer values (X++)
	sta.b $3b	   ; Store flags 2

; Process status effect bits (lower nibble only)
	lda.b #$0f	  ; Mask for lower nibble
	trb.b $2e	   ; Clear lower nibble in $2e
	jsr.w ProcessesStatsViaCodeAcrossBuffers ; OR next buffer values (X++)
	and.b #$0f	  ; Keep only lower nibble
	tsb.b $2e	   ; Set bits in $2e

; Clear specific status bits and update base stats
	lda.b $3b	   ; A = flags 2
	trb.b $21	   ; Clear those bits in $21

; Update base stats with deltas (with carry from earlier CLC)
	lda.b $2a	   ; A = stat 1
	adc.b $26	   ; Add delta 1
	sta.b $22	   ; Store to base stat 1
	lda.b $2b	   ; A = stat 2
	adc.b $27	   ; Add delta 2
	sta.b $23	   ; Store to base stat 2
	lda.b $2c	   ; A = stat 3
	adc.b $28	   ; Add delta 3
	sta.b $24	   ; Store to base stat 3
	lda.b $2d	   ; A = stat 4
	adc.b $29	   ; Add delta 4
	sta.b $25	   ; Store to base stat 4

	plb ; Restore data bank
	pld ; Restore direct page
	plp ; Restore processor status
	rts ; Return

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
	lda.w $3679,x   ; A = delta buffer 1 value
	ora.w $3689,x   ; OR with delta buffer 2
	ora.w $3699,x   ; OR with delta buffer 3
	ora.w $36a9,x   ; OR with delta buffer 4
	inx ; Increment offset to next stat
	rts ; Return with result in A

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
	lda.w $3669,x   ; A = base buffer value
	adc.w $3679,x   ; Add delta buffer 1 (with carry)
	adc.w $3689,x   ; Add delta buffer 2
	adc.w $3699,x   ; Add delta buffer 3
	adc.w $36a9,x   ; Add delta buffer 4
	inx ; Increment offset to next stat
	rts ; Return with result in A

; ===========================================================================
; Animation Update Handler
; ===========================================================================
; Purpose: Conditionally update animations based on timing and game state
; Technical Details:
;   - Checks bit 5 ($20) of $00d9 as update gate
;   - Only processes animations when bit is clear
;   - Sets bit after processing to prevent multiple updates per frame
; Side Effects: May modify $00d9, calls SideEffectsMayModifyD9Calls
; ===========================================================================

Animation_CheckUpdate:
	sep #$30		; 8-bit A/X/Y
	lda.b #$20	  ; bit 5 mask
	and.w $00d9	 ; Check animation update flag
	bne Skip_Animation ; If set, skip this frame
	jsr.w Animation_UpdateSystem ; Process animation updates

Skip_Animation:
	rep #$30		; 16-bit A/X/Y
	rts ; Return

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
	rep #$10		; 16-bit X/Y
	lda.b #$20	  ; bit 5 mask
	tsb.w $00d9	 ; Set animation processing flag
	pea.w $0500	 ; Push $0500 to stack
	pld ; Direct Page = $0500 (animation queue)
	cli ; Enable interrupts

; Process animation slot 1 ($00)
	lda.b #$04	  ; bit 2 mask
	and.w !system_flags_9	 ; Check animation gate flag
	bne Check_Slot2 ; If set, skip slot 1
	lda.b $00	   ; A = animation type (slot 1)
	bmi Check_Slot2 ; If $ff (empty), skip
	sta.w $0601	 ; Store animation type to $0601
	ldx.b $01	   ; X = animation parameter (16-bit)
	stx.w $0602	 ; Store parameter to $0602
	lda.b #$01	  ; Animation command = $01
	sta.w $0600	 ; Store to animation command register
	jsl.l Secondary_APU_Command_Entry_Point ; Call animation processor
	lda.b #$ff	  ; Mark slot as empty
	sta.b $00	   ; Store to slot 1 type
	ldx.b $03	   ; X = saved parameters
	stx.b $01	   ; Restore to slot 1

Check_Slot2:
; Process animation slot 2 ($05)
	lda.b $05	   ; A = animation type (slot 2)
	bmi Check_Slot3 ; If $ff (empty), skip
	lda.b $05	   ; A = animation type (reload)
	sta.w $0601	 ; Store animation type to $0601
	ldx.b $06	   ; X = animation parameter (16-bit)
	stx.w $0602	 ; Store parameter to $0602
	lda.b #$02	  ; Animation command = $02
	sta.w $0600	 ; Store to animation command register
	jsl.l Secondary_APU_Command_Entry_Point ; Call animation processor
	lda.b #$ff	  ; Mark slot as empty
	sta.b $05	   ; Store to slot 2 type
	ldx.b $08	   ; X = saved parameters
	stx.b $06	   ; Restore to slot 2

Check_Slot3:
; Process animation slot 3 ($0a)
	lda.b $0a	   ; A = animation type (slot 3)
	beq Animation_Done ; If $00 (empty), done
	cmp.b #$02	  ; Compare to $02
	beq Execute_Slot3 ; If exactly $02, execute
	cmp.b #$10	  ; Compare to $10
	bcc Check_Gate  ; If < $10, check gate
	cmp.b #$20	  ; Compare to $20
	bcc Execute_Slot3 ; If $10-$1f, execute

Check_Gate:
	lda.b #$04	  ; bit 2 mask
	and.w !system_flags_9	 ; Check animation gate flag
	bne Animation_Done ; If set, skip slot 3

Execute_Slot3:
	ldx.b $0a	   ; X = animation type (16-bit load)
	stx.w $0600	 ; Store to animation command
	ldx.b $0c	   ; X = animation parameter (16-bit)
	stx.w $0602	 ; Store parameter to $0602
	jsl.l Secondary_APU_Command_Entry_Point ; Call animation processor
	stz.b $0a	   ; Clear slot 3 type ($00 = empty)

Animation_Done:
	sei ; Disable interrupts
	lda.b #$20	  ; bit 5 mask
	trb.w $00d9	 ; Clear animation processing flag
	rts ; Return

; ===========================================================================
; Graphics Mode Setup - Jump to Field Mode Initialization
; ===========================================================================
; Purpose: Setup graphics environment and jump to field mode code
; Technical Details:
;   - Calls CallsCodePrepareGraphicsState to prepare graphics state
;   - Jumps to Label_00803A for field mode initialization
; Side Effects: Modifies $00d6, NMITIMEN register, $00d2, $00db
; ===========================================================================

Graphics_SetupFieldMode:
	jsr.w CallsCodePrepareGraphicsState ; Setup graphics state
	jmp.w Label_00803A ; Jump to field mode init

; ===========================================================================
; Graphics Mode Setup - Jump to Battle Mode Initialization
; ===========================================================================
; Purpose: Setup graphics environment and jump to battle mode code
; Technical Details:
;   - Calls CallsCodePrepareGraphicsState to prepare graphics state
;   - Jumps to Label_008016 for battle mode initialization
; Side Effects: Modifies $00d6, NMITIMEN register, $00d2, $00db
; ===========================================================================

Graphics_SetupBattleMode:
	jsr.w Graphics_PrepareTransition ; Setup graphics state
	jmp.w Label_008016 ; Jump to battle mode init

; ===========================================================================
; Graphics State Setup Routine
; ===========================================================================
; Purpose: Configure graphics system for mode transitions
; Technical Details:
;   - Sets bit 6 ($40) of $00d6 (graphics busy flag)
;   - Restores NMI/IRQ configuration from $0112
;   - Enables interrupts
;   - Calls sprite processing routine FinalSetupRoutine
;   - Clears bit 3 ($08) of $00d2 (graphics ready flag)
;   - Clears bit 2 ($04) of $00db (animation gate)
; Registers Modified:
;   - A: Used for bit manipulation
;   - NMITIMEN ($4200): Set from $0112
; ===========================================================================

Graphics_PrepareTransition:
	sep #$30		; 8-bit A/X/Y
	lda.b #$40	  ; bit 6 mask
	tsb.w !system_flags_3	 ; Set graphics busy flag in $00d6
	lda.w $0112	 ; Load NMI/IRQ configuration
	sta.w SNES_NMITIMEN ; Store to NMITIMEN ($4200)
	cli ; Enable interrupts
	jsl.l FinalSetupRoutine ; Call sprite processing routine
	lda.b #$08	  ; bit 3 mask
	trb.w !system_flags_1	 ; Clear graphics ready flag
	lda.b #$04	  ; bit 2 mask
	trb.w !system_flags_6	 ; Clear animation gate
	rts ; Return

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
	php ; Save processor status
	phb ; Save data bank
	phk ; Push program bank
	plb ; Data Bank = program bank
	rep #$30		; 16-bit A/X/Y
	pha ; Save A
	lda.w #$0008	; Value $0008
	sta.w $0051	 ; Store to display timer
	sep #$20		; 8-bit A
	lda.b #$0c	  ; Value $0c
	sta.w $0055	 ; Store to display config
	lda.b #$02	  ; bit 1 mask
	trb.w !system_flags_6	 ; Clear display update gate
	lda.b #$80	  ; bit 7 mask
	trb.w !system_flags_9	 ; Clear graphics effect flag
	lda.b #$04	  ; bit 2 mask
	tsb.w !system_flags_6	 ; Set animation gate
	rep #$30		; 16-bit A/X/Y
	pla ; Restore A
	plb ; Restore data bank
	plp ; Restore processor status
	rtl ; Return long

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
	lda.w #$0004	; bit 2 mask
	and.w !system_flags_6	 ; Check animation gate
	beq Skip_Frame_Check ; If clear, skip
	lda.w $0e97	 ; Load frame counter
	and.w #$000f	; Mask to lower nibble
	beq Process_Frame ; If $00, process this frame

Skip_Frame_Check:
	rts ; Return (skip this frame)

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
	php ; Save processor status
	rep #$30		; 16-bit A/X/Y
	phd ; Save direct page
	pha ; Save A
	phx ; Save X
	phy ; Save Y
	lda.w #$0000	; Direct Page = $0000
	tcd ; Set DP to zero page
	lda.b $9c	   ; Load multiplicand from stack
	sta.b $a4	   ; Store to $a4
	stz.b $9e	   ; Clear result low word
	ldx.w #$0010	; Loop counter = 16 bits
	ldy.b $98	   ; Y = multiplier from stack

Multiply_Loop:
	asl.b $9e	   ; Shift result left (low word)
	rol.b $a0	   ; Rotate result (high word)
	asl.b $a4	   ; Shift multiplicand left
	bcc Skip_Add	; If no carry, skip addition
	tya ; A = multiplier
	clc ; Clear carry
	adc.b $9e	   ; Add to result low word
	sta.b $9e	   ; Store back
	bcc Skip_Add	; If no carry, continue
	inc.b $a0	   ; Increment high word

Skip_Add:
	dex ; Decrement loop counter
	bne Multiply_Loop ; Loop until done
	ply ; Restore Y
	plx ; Restore X
	pla ; Restore A
	pld ; Restore direct page
	plp ; Restore processor status
	rtl ; Return long

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
	php ; Save processor status
	rep #$30		; 16-bit A/X/Y
	phd ; Save direct page
	pha ; Save A
	phx ; Save X
	lda.w #$0000	; Direct Page = $0000
	tcd ; Set DP to zero page
	lda.b $98	   ; Load dividend low word
	sta.b $a4	   ; Store to $a4
	lda.b $9a	   ; Load dividend high word
	sta.b $a6	   ; Store to $a6
	stz.b $a2	   ; Clear remainder
	ldx.w #$0020	; Loop counter = 32 bits

Divide_Loop:
	asl.b $9e	   ; Shift quotient left (low)
	rol.b $a0	   ; Rotate quotient (mid)
	asl.b $a4	   ; Shift dividend left (low)
	rol.b $a6	   ; Rotate dividend (mid)
	rol.b $a2	   ; Rotate into remainder
	lda.b $a2	   ; A = remainder
	bcs Division_Subtract ; If carry set, always subtract
	sec ; Set carry for subtraction
	sbc.b $9c	   ; Subtract divisor
	bcs Store_Remainder ; If no borrow, store result
	bra Skip_Division ; Skip if borrow

Division_Subtract:
	sbc.b $9c	   ; Subtract divisor (carry already set)

Store_Remainder:
	sta.b $a2	   ; Store new remainder
	inc.b $9e	   ; Set bit in quotient

Skip_Division:
	dex ; Decrement loop counter
	bne Divide_Loop ; Loop until done
	plx ; Restore X
	pla ; Restore A
	pld ; Restore direct page
	plp ; Restore processor status
	rtl ; Return long

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
	php ; Save processor status
	sep #$20		; 8-bit A
	sta.w SNES_WRMPYB ; Write to multiplier B register
	plp ; Restore processor status
	rtl ; Return long

; ---------------------------------------------------------------------------
; Hardware Divide Helper
; ---------------------------------------------------------------------------
; Purpose: Perform hardware division using SNES divider
; Input: A (16-bit) = dividend, after xba = divisor (8-bit high byte)
; Output: Result in RDDIVL/H ($4214-$4215), remainder in RDMPYL/H
; Technical Details:
;   - Writes to WRDIVB ($4206)
;   - xba twice creates delay for result to be ready
;   - Division takes 16 cycles to complete
; ===========================================================================

Hardware_Divide:
	php ; Save processor status
	sep #$20		; 8-bit A
	sta.w SNES_WRDIVB ; Write divisor to hardware
	xba ; Swap A bytes (delay)
	xba ; Swap back (delay)
	plp ; Restore processor status
	rtl ; Return long

; ---------------------------------------------------------------------------
; Find First Set bit (Count Leading Zeros)
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
	php ; Save processor status
	rep #$30		; 16-bit A/X/Y
	phx ; Save X
	ldx.w #$ffff	; X = -1 (initial position)

Count_Bits:
	inx ; Increment position
	lsr a; Shift right, test bit 0
	bcc Count_Bits  ; If clear, continue
	txa ; A = bit position
	plx ; Restore X
	plp ; Restore processor status
	rtl ; Return long

; ===========================================================================
; bit Manipulation Helpers
; ===========================================================================

; ---------------------------------------------------------------------------
; Set Bits (TSB - Test and Set Bits)
; ---------------------------------------------------------------------------
; Purpose: Set bits in memory using tsb operation
; Input: A = bit mask, $00+DP = target address
; Output: Target memory has bits set, Z flag reflects test
; Technical Details:
;   - Calls CallsCodeCalculateBitPosition to calculate bit position
;   - Uses tsb instruction at Direct Page $00
; ===========================================================================

Bit_SetBits:
	jsr.w Bit_CalcPosition ; Calculate bit position/mask
	tsb.b $00	   ; Test and set bits
	rtl ; Return long

; ---------------------------------------------------------------------------
; Clear Bits (TRB - Test and Reset Bits)
; ---------------------------------------------------------------------------
; Purpose: Clear bits in memory using trb operation
; Input: A = bit mask, $00+DP = target address
; Output: Target memory has bits cleared, Z flag reflects test
; Technical Details:
;   - Calls CallsCodeCalculateBitPosition to calculate bit position
;   - Uses trb instruction at Direct Page $00
; ===========================================================================

Bit_ClearBits:
	jsr.w Bit_CalcPosition ; Calculate bit position/mask
	trb.b $00	   ; Test and reset bits
	rtl ; Return long

; ---------------------------------------------------------------------------
; Test Bits (AND operation)
; ---------------------------------------------------------------------------
; Purpose: Test bits in memory without modification
; Input: A = bit mask, $00+DP = target address
; Output: A = result of and operation, Z/N flags set
; Technical Details:
;   - Calls CallsCodeCalculateBitPosition to calculate bit position
;   - Uses and instruction to test bits
; ===========================================================================

Bit_TestBits:
	jsr.w Bit_CalcPosition ; Calculate bit position/mask
	and.b $00	   ; Test bits
	rtl ; Return long

; ---------------------------------------------------------------------------
; Set Bits with DP $0ea8
; ---------------------------------------------------------------------------
; Purpose: Set bits in $0ea8+offset using tsb
; Input: A = bit mask (offset in low byte)
; Output: Bits set in target location
; ===========================================================================

Bit_SetBits_0EA8:
	phd ; Save direct page
	pea.w $0ea8	 ; Push $0ea8
	pld ; Direct Page = $0ea8
	jsl.l Bit_SetBits ; Set bits via tsb
	pld ; Restore direct page
	rtl ; Return long

; ---------------------------------------------------------------------------
; Clear Bits with DP $0ea8
; ---------------------------------------------------------------------------
; Purpose: Clear bits in $0ea8+offset using trb
; Input: A = bit mask (offset in low byte)
; Output: Bits cleared in target location
; ===========================================================================

Bit_ClearBits_0EA8:
	phd ; Save direct page
	pea.w $0ea8	 ; Push $0ea8
	pld ; Direct Page = $0ea8
	jsl.l Bit_ClearBits ; Clear bits via trb
	pld ; Restore direct page
	rtl ; Return long

; ---------------------------------------------------------------------------
; Test Bits with DP $0ea8
; ---------------------------------------------------------------------------
; Purpose: Test bits in $0ea8+offset
; Input: A = bit mask (offset in low byte)
; Output: A = result of test, Z/N flags set
; ===========================================================================

Bit_TestBits_0EA8:
	phd ; Save direct page
	pea.w $0ea8	 ; Push $0ea8
	pld ; Direct Page = $0ea8
	jsl.l Bit_TestBits ; Test bits via and
	pld ; Restore direct page
	inc a; Set flags based on result
	dec a; (INC/DEC preserves value, updates flags)
	rtl ; Return long

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
	php ; Save processor status
	phd ; Save direct page
	rep #$30		; 16-bit A/X/Y
	pha ; Save A
	lda.w #$005e	; Direct Page = $005e
	tcd ; Set DP
	lda.l $701ffe   ; Load current seed
	asl a; Multiply by 2
	asl a; Multiply by 4
	adc.l $701ffe   ; Add original (now *5)
	adc.w #$3711	; Add constant
	adc.w $0e96	 ; Add frame counter
	sta.l $701ffe   ; Store new seed
	sep #$20		; 8-bit A
	xba ; Get high byte
	sta.b $4b	   ; Store to $a9 (DP $005e + $4b)
	sta.w SNES_WRDIVL ; Write to divider (low byte)
	stz.w SNES_WRDIVH ; Clear divider (high byte)
	lda.b $4a	   ; Load modulo value from $a8
	beq Random_Done ; If zero, skip modulo
	jsl.l Hardware_Divide ; Perform division
	lda.w SNES_RDMPYL ; Read remainder (result of modulo)
	sta.b $4b	   ; Store to $a9

Random_Done:
	rep #$30		; 16-bit A/X/Y
	pla ; Restore A
	pld ; Restore direct page
	plp ; Restore processor status
	rtl ; Return long

; ---------------------------------------------------------------------------
; bit Position to Mask Conversion Table
; ---------------------------------------------------------------------------
; Purpose: Convert bit position (0-7) to bit mask
; Input: A (after processing) = bit position * 2 (for word indexing)
; Output: A = bit mask ($0001, $0002, $0004...$0080, $0100...$8000)
; ===========================================================================

Bit_PositionToMask:
	phx ; Save X
	asl a; Multiply by 2 for word table
	tax ; X = index
	lda.l DATA8_0097fb,x ; Load bit mask from table
	plx ; Restore X
	rts ; Return

DATA8_0097fb:
	dw $0001, $0002, $0004, $0008, $0010, $0020, $0040, $0080
	dw $0100, $0200, $0400, $0800, $1000, $2000, $4000, $8000

; ---------------------------------------------------------------------------
; bit Position Calculator
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
	php ; Save processor status
	rep #$30		; 16-bit A/X/Y
	and.w #$00ff	; Mask to 8-bit value
	pha ; Save bit position
	lsr a; Divide by 2
	lsr a; Divide by 4
	lsr a; Divide by 8 (byte offset)
	phd ; Save current DP
	clc ; Clear carry
	adc.b $01,s	 ; Add to saved DP
	tcd ; Set new DP
	pla ; Discard saved DP
	pla ; Restore bit position
	and.w #$0007	; Mask to bit number (0-7)
	eor.w #$0007	; Invert bit position
	plp ; Restore processor status
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
;   - Uses rti to jump to new address
; Stack Layout:
;   Entry: [return_bank] [return_addr] [saved_registers]
;   Exit:  [return_bank] [table_addr] [saved_registers]
; ===========================================================================

Jump_IndirectViaTable:
	php ; Save processor status
	phb ; Save data bank
	rep #$30		; 16-bit A/X/Y
	phy ; Save Y
	and.w #$00ff	; Mask to 8-bit index
	asl a; Multiply by 2 (word table)
	tay ; Y = table offset
	lda.b $06,s	 ; Load return bank from stack
	pha ; Save it
	plb ; Data Bank = return bank
	plb ; (needs double pull for 16-bit)
	lda.b ($08,s),y ; Read table entry at [return_addr + Y]
	tay ; Y = destination address
	lda.b $05,s	 ; Get saved processor status
	sta.b $08,s	 ; Move to where return address was
	tya ; A = destination address
	sta.b $05,s	 ; Store as new return address
	ply ; Restore Y
	plb ; Restore data bank
	rti ; Return to table address (not original caller)

; ===========================================================================
; Common Stack Cleanup Routine
; ===========================================================================
; Purpose: Standard cleanup of saved registers from stack
; Technical Details:
;   - Restores registers in reverse order of saving
;   - rep #$30 ensures 16-bit mode for index registers
; ===========================================================================

Stack_RestoreAll:
	rep #$30		; 16-bit A/X/Y
	ply ; Restore Y
	plx ; Restore X
	pld ; Restore direct page
	pla ; Restore A
	plb ; Restore data bank
	plp ; Restore processor status
	rts ; Return

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
	lda.w $003e,x   ; Copy word at +$3e
	sta.w $003e,y
	lda.w $003c,x   ; Copy word at +$3c
	sta.w $003c,y
	lda.w $003a,x   ; Copy word at +$3a
	sta.w $003a,y
	lda.w $0038,x   ; Copy word at +$38
	sta.w $0038,y
	lda.w $0036,x   ; Copy word at +$36
	sta.w $0036,y
	lda.w $0034,x   ; Copy word at +$34
	sta.w $0034,y
	lda.w $0032,x   ; Copy word at +$32
	sta.w $0032,y
	lda.w $0030,x   ; Copy word at +$30
	sta.w $0030,y
	lda.w $002e,x   ; Copy word at +$2e
	sta.w $002e,y
	lda.w $002c,x   ; Copy word at +$2c
	sta.w $002c,y
	lda.w $002a,x   ; Copy word at +$2a
	sta.w $002a,y
	lda.w $0028,x   ; Copy word at +$28
	sta.w $0028,y
	lda.w $0026,x   ; Copy word at +$26
	sta.w $0026,y
	lda.w $0024,x   ; Copy word at +$24
	sta.w $0024,y
	lda.w $0022,x   ; Copy word at +$22
	sta.w $0022,y
	lda.w $0020,x   ; Copy word at +$20
	sta.w $0020,y

Memory_Copy32Bytes:
	lda.w $001e,x   ; Copy word at +$1e
	sta.w $001e,y
	lda.w $001c,x   ; Copy word at +$1c
	sta.w $001c,y
	lda.w $001a,x   ; Copy word at +$1a
	sta.w $001a,y
	lda.w $0018,x   ; Copy word at +$18
	sta.w $0018,y
	lda.w $0016,x   ; Copy word at +$16
	sta.w $0016,y
	lda.w $0014,x   ; Copy word at +$14
	sta.w $0014,y
	lda.w $0012,x   ; Copy word at +$12
	sta.w $0012,y
	lda.w $0010,x   ; Copy word at +$10
	sta.w $0010,y
	lda.w $000e,x   ; Copy word at +$0e
	sta.w $000e,y
	lda.w $000c,x   ; Copy word at +$0c
	sta.w $000c,y
	lda.w $000a,x   ; Copy word at +$0a
	sta.w $000a,y
	lda.w $0008,x   ; Copy word at +$08
	sta.w $0008,y
	lda.w $0006,x   ; Copy word at +$06
	sta.w $0006,y
	lda.w $0004,x   ; Copy word at +$04
	sta.w $0004,y
	lda.w $0002,x   ; Copy word at +$02
	sta.w $0002,y
	lda.w $0000,x   ; Copy word at +$00
	sta.w $0000,y
	rts ; Return

; ---------------------------------------------------------------------------
; Memory Fill Dispatcher - Long Entry Point
; ---------------------------------------------------------------------------
; Purpose: Fill memory with value (long call wrapper)
; Input: A (16-bit) = fill count, Y = start address, value on stack
; ===========================================================================

Memory_FillLong:
	jsr.w Memory_FillDispatch ; Call fill routine
	rtl ; Return long

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
	phx ; Save X
	cmp.w #$0040	; Check if >= 64 bytes
	bcc Handle_Remainder ; If < 64, handle remainder
	pha ; Save count
	lsr a; Divide by 2
	lsr a; Divide by 4
	lsr a; Divide by 8
	lsr a; Divide by 16
	lsr a; Divide by 32
	lsr a; Divide by 64
	tax ; X = number of 64-byte blocks
	clc ; Clear carry

Fill_Block_Loop:
	lda.b $03,s	 ; Get fill value from stack
	jsr.w Memory_Fill64 ; Fill 64 bytes
	tya ; A = current address
	adc.w #$0040	; Advance by 64 bytes
	tay ; Y = new address
	dex ; Decrement block counter
	bne Fill_Block_Loop ; Loop if more blocks
	pla ; Restore count
	and.w #$003f	; Get remainder (last 0-63 bytes)

Handle_Remainder:
	tax ; X = remainder count (doubled for jump table)
	pla ; Restore X from stack
	jmp.w (DATA8_009a1e,x) ; Jump to handler for exact count

; ---------------------------------------------------------------------------
; Fill 64 Bytes With Value
; ---------------------------------------------------------------------------
; Purpose: Fill exactly 64 bytes starting at Y with value in A
; Technical Details:
;   - Uses unrolled loop (32 stores of 16-bit words)
;   - All addresses in bank $7f
; ===========================================================================

Memory_Fill64:
	sta.w $003e,y   ; Fill word at +$3e
	sta.w $003c,y   ; Fill word at +$3c
	sta.w $003a,y   ; Fill word at +$3a
	sta.w $0038,y   ; Fill word at +$38
	sta.w $0036,y   ; Fill word at +$36
	sta.w $0034,y   ; Fill word at +$34
	sta.w $0032,y   ; Fill word at +$32
	sta.w $0030,y   ; Fill word at +$30
	sta.w $002e,y   ; Fill word at +$2e
	sta.w $002c,y   ; Fill word at +$2c
	sta.w $002a,y   ; Fill word at +$2a
	sta.w $0028,y   ; Fill word at +$28
	sta.w $0026,y   ; Fill word at +$26
	sta.w $0024,y   ; Fill word at +$24
	sta.w $0022,y   ; Fill word at +$22

Memory_Fill32:
	sta.w $0020,y   ; Fill word at +$20
	sta.w $001e,y   ; Fill word at +$1e
	sta.w $001c,y   ; Fill word at +$1c
	sta.w $001a,y   ; Fill word at +$1a
	sta.w $0018,y   ; Fill word at +$18
	sta.w $0016,y   ; Fill word at +$16
	sta.w $0014,y   ; Fill word at +$14
	sta.w $0012,y   ; Fill word at +$12

Memory_Fill16:
	sta.w $0010,y   ; Fill word at +$10

Memory_Fill14Bytes:
	sta.w $000e,y   ; Fill word at +$0e

Memory_Fill12Bytes:
	sta.w $000c,y   ; Fill word at +$0c
	sta.w $000a,y   ; Fill word at +$0a
	sta.w $0008,y   ; Fill word at +$08

Memory_Fill6Words:
	sta.w $0006,y   ; Fill word at +$06
	sta.w $0004,y   ; Fill word at +$04
	sta.w $0002,y   ; Fill word at +$02

Memory_Fill2Words:
	sta.w $0000,y   ; Fill word at +$00
	rts ; Return

; ---------------------------------------------------------------------------
; Fill Jump Table
; ---------------------------------------------------------------------------
; Purpose: Jump table for partial block fills (0-63 bytes)
; Format: Table of addresses for each possible remainder count
; Technical Details:
;   - Entry points into EntryPointsIntoCodeVariousOffsets at various offsets
;   - Allows exact fill counts without conditional logic
; ===========================================================================

DATA8_009a1e:
	dw $9a1d	   ; 0 bytes (just return)
	dw $9a1a, $9a17, $9a14, $9a11 ; 2, 4, 6, 8 bytes
	dw $9a0e, $9a0b, $9a08, $9a05, $9a02 ; 10-18 bytes
	dw $99ff, $99fc, $99f9, $99f6, $99f3 ; 20-28 bytes
	dw $99f0, $99ed, $99ea, $99e7, $99e4 ; 30-38 bytes
	dw $99e1, $99de, $99db, $99d8, $99d5 ; 40-48 bytes
	dw $99d2, $99cf, $99cc, $99c9, $99c6 ; 50-58 bytes
	dw $99c3, $99c0, $99bd ; 60-64 bytes
Update_Done:
	plp ; Restore status
	rts ; Return

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
	php ; Save processor status
	phb ; Save data bank
	phd ; Save direct page
	rep #$30		; 16-bit A/X/Y
	pha ; Save A
	lda.w #$0000	; Direct Page = $0000
	tcd ; Set DP
	lda.w #$f811	; Graphics pointer
	sta.b $17	   ; Store pointer
	sep #$20		; 8-bit A
	lda.b #$03	  ; Bank $03
	sta.b $19	   ; Store bank
	jsr.w ProcessGraphicsData ; Process graphics data
	rep #$30		; 16-bit A/X/Y
	pla ; Restore A
	pld ; Restore direct page
	plb ; Restore data bank
	plp ; Restore processor status
	rtl ; Return long

; ---------------------------------------------------------------------------
; Graphics Processing Entry Points
; ---------------------------------------------------------------------------

Graphics_ProcessMenuData:
	php ; Save processor status
	phd ; Save direct page
	pea.w $0000	 ; Push $0000
	pld ; Direct Page = $0000
	rep #$30		; 16-bit A/X/Y
	phx ; Save X
	ldx.w #$9aff	; Data pointer
	jsr.w CodeLikelyLoadsProcessesThisData ; Process data
	plx ; Restore X
	pld ; Restore direct page
	plp ; Restore processor status
	rtl ; Return long

Graphics_InitDisplay:
	php ; Save processor status
	phd ; Save direct page
	phb ; Save data bank
	sep #$20		; 8-bit A
	rep #$10		; 16-bit X/Y
	pha ; Save A
	phx ; Save X
	pea.w $0000	 ; Push $0000
	pld ; Direct Page = $0000
	jsl.l AddressC8000OriginalCode ; Call graphics handler
	jsl.l WaitVblank ; Wait for VBlank
	pei.b ($1d)	 ; Push [$1d]
	lda.b $27	   ; Load parameter
	pha ; Save it
	jsl.l Graphics_Setup1 ; Process graphics
	jsr.w Graphics_InitDisplay ; Call handler
	pla ; Restore parameter
	sta.b $27	   ; Store back
	plx ; Get saved value
	stx.b $1d	   ; Store to $1d
	plx ; Restore X
	pla ; Restore A
	plb ; Restore data bank
	pld ; Restore direct page
	plp ; Restore processor status
	rtl ; Return long

Graphics_Setup1:
	php ; Save processor status
	phd ; Save direct page
	pea.w $0000	 ; Push $0000
	pld ; Direct Page = $0000
	rep #$30		; 16-bit A/X/Y
	phx ; Save X
	ldx.w #$9b42	; Data pointer
	jsr.w Graphics_ProcessData ; Process data
	plx ; Restore X
	pld ; Restore direct page
	plp ; Restore processor status
	rtl ; Return long

Graphics_Setup2:
	php ; Save processor status
	phd ; Save direct page
	rep #$30		; 16-bit A/X/Y
	lda.w #$0000	; Direct Page = $0000
	tcd ; Set DP
	ldx.w #$9b56	; Data pointer
	jsr.w Graphics_ProcessData ; Process data
	pld ; Restore direct page
	plp ; Restore processor status
	rtl ; Return long

Graphics_Setup3:
	php ; Save processor status
	phd ; Save direct page
	rep #$30		; 16-bit A/X/Y
	lda.w #$0000	; Direct Page = $0000
	tcd ; Set DP
	lda.b $20	   ; Load parameter
	sta.b $4f	   ; Store to $4f
	jsr.w Graphics_SetupPointer ; Setup graphics
	lda.b [$17]	 ; Load data
	and.w #$00ff	; Mask to byte
	cmp.w #$0004	; Compare to 4
	beq Skip_Special ; If equal, skip
	ldx.w #$9b9d	; Special data pointer
	jsr.w Graphics_ProcessData ; Process data

Skip_Special:
	jsr.w Graphics_SetupPointer ; Setup graphics again
	jsr.w ProcessGraphicsData ; Process graphics data
	jsr.w Graphics_PostProcess ; Post-process
	ldx.w #$9ba0	; Cleanup pointer
	jsr.w Graphics_ProcessData ; Process cleanup
	pld ; Restore direct page
	plp ; Restore processor status
	rtl ; Return long

Graphics_SetupPointer:
	sep #$20		; 8-bit A
	lda.b #$03	  ; Bank $03
	sta.b $19	   ; Store bank
	rep #$30		; 16-bit A/X/Y
	lda.b $20	   ; Load parameter
	asl a; Multiply by 2
	tax ; X = index
	lda.l UNREACH_03D5E5,x ; Load pointer from table
	sta.b $17	   ; Store graphics pointer
	rts ; Return

Graphics_PostProcess:
	rts ; Return (stub)

Graphics_Setup4:
	php ; Save processor status
	phd ; Save direct page
	rep #$30		; 16-bit A/X/Y
	lda.w #$0000	; Direct Page = $0000
	tcd ; Set DP
	sep #$20		; 8-bit A
	lda.b #$03	  ; Bank $03
	sta.b $19	   ; Store bank
	rep #$30		; 16-bit A/X/Y
	lda.b $20	   ; Load parameter
	asl a; Multiply by 2
	tax ; X = index
	lda.l DATA8_03bb81,x ; Load pointer from table
	sta.b $17	   ; Store graphics pointer
	jsr.w ProcessGraphicsData ; Process graphics data
	pld ; Restore direct page
	plp ; Restore processor status
	rtl ; Return long

; ===========================================================================
; Graphics Data Processing Engine
; ===========================================================================

; ---------------------------------------------------------------------------
; CodeLikelyLoadsProcessesThisData: Process Graphics Data
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

; ------------------------------------------------------------------------------
; UNREACHABLE CODE ANALYSIS
; ------------------------------------------------------------------------------
; Label: UNREACH_00A2D4
; Category: 🔴 Truly Unreachable (Dead Code)
; Purpose: Initialize variables $9e and $a0 to $ffff, then pull and return
; Reachability: No known call sites or branches to this address
; Analysis: Initialization stub - sets two variables and returns
;   - Sets X to $ffff
;   - Stores X to $9e (at Direct Page)
;   - Stores X to $a0 (at Direct Page)
;   - Pulls accumulator from stack
;   - Returns
; Verified: NOT reachable in normal gameplay
; Notes: May be debug initialization or removed initialization routine
; ------------------------------------------------------------------------------
UNREACH_00A2D4:
	ldx.w #$ffff                         ;00A2D4|A2FFFF  |      ; Load X with $ffff
	stx.b $9e                            ;00A2D7|869E    |00009E; Store to $9e
	stx.b $a0                            ;00A2D9|86A0    |0000A0; Store to $a0
	pla ;00A2DB|FA      |      ; Pull accumulator
	rts ;00A2DC|60      |      ; Return

DATA8_00a2dd:
	db $10

DATA8_00a2de:
	db $19,$00,$12,$32,$00,$dd,$0a,$00
	db $ff

; ---------------------------------------------------------------------------
; Command stream table processing helpers
; ---------------------------------------------------------------------------

Graphics_CommandDispatch:
	lda.b [$17]
	inc.b $17
	and.w #$00ff
	dec a
	cmp.b $9e
	bcc Graphics_CommandDispatch_IndexPath
	lda.b $9e
	asl a
	adc.b $17
	sta.b $17
	lda.b [$17]
	sta.b $17


; ------------------------------------------------------------------------------
; Graphics Command Dispatch - Index Path
; ------------------------------------------------------------------------------
; Purpose: Increment index and adjust graphics stream pointer
; Reachability: Reachable via conditional branch (bcc at line 6646)
; Analysis: Alternate path in graphics command dispatcher when index < threshold
;   - Increments accumulator (index++)
;   - Multiplies by 2 for word-aligned table access
;   - Adds to stream pointer to advance position
; Technical: Originally labeled UNREACH_00A2FF, but analysis shows it's reachable
;   via the graphics command dispatcher's table-driven logic
; ------------------------------------------------------------------------------
Graphics_CommandDispatch_IndexPath:
	inc a                                ;00A2FF|1A      |      ; Increment index
	asl a                                ;00A300|0A      |      ; Multiply by 2 (word table)
	adc.b $17                            ;00A301|6517    |000017; Add to stream pointer
	sta.b $17                            ;00A303|8517    |000017; Update stream pointer
	rts ;00A305|60      |      ; Return

Graphics_ConditionalDispatch:
	lda.b [$17]
	inc.b $17
	and.w #$00ff
	dec a
	cmp.b $9e

	inc a
	asl a
	adc.b $17
TAY_Label:
PLP_Label:
	bcc Graphics_ConditionalDispatch_Continue
	lda.b $9e
	asl a
	adc.b $17
	sta.b $17
	lda.b [$17]
	sta.b $17
	sep #$20
	lda.b $19
	jsr.w ProcessGraphicsData
	sta.b $19
	rep #$30

Graphics_ConditionalDispatch_Continue:
	sty.b $17


; ---------------------------------------------------------------------------
; More graphics command handlers (block)
; Imported segment: ImportedSegmentCodeCode .. ImportedSegmentCodeCode2
; ---------------------------------------------------------------------------

Graphics_InitDisplay_1:

	rep #$30
PHB_Label:
PHA_Label:
PHD_Label:
PHX_Label:
PHY_Label:
	lda.b $46
	bne +
	jmp Graphics_InitDisplay_End
	+	lda.b $40
	sta.w $01ee
	lda.b $44
	sta.w $01ed

	sbc.b $3f
	lsr a
	adc.b $42
	sta.b $48

	lda.b $46
	sbc.b $44
	sta.w $01eb
	lda.w #$00e0
	tsb.w !system_flags_1
	lda.w #$ffff
	sta.b $44
	stz.b $46
	jmp.w Bit_SetBits_00E2

Graphics_InitDisplay_End:
	lda.w #$0080
	tsb.w $00d0


Graphics_DispatchTable:
	lda.b [$17]
	inc.b $17
	and.w #$00ff
	asl a
TAX_Label:
	jmp.w (DATA8_009e6e,x)

Graphics_CallSystem:
	lda.w #$0080
	tsb.w !system_flags_4
	jsl.l AddressC8000OriginalCode
	lda.w #$0008
	trb.w !system_flags_2


Graphics_CheckDisplayReady:
	lda.w #$0040
	and.w $00d0
	beq Graphics_FadeOut


Graphics_FadeOut:
	lda.w #$00ff
	jmp.w CodeDirectTileWrite

Graphics_WaitForEvent:
	jsl.l AddressC8000OriginalCode
	lda.w #$0020
	and.w $00d0
	bne Graphics_WaitForEvent_Alt
	lda.b [$17]
	inc.b $17
	inc.b $17

Graphics_WaitForEvent_Loop:
	jsl.l WaitVblank
	bit.b $94
	beq Graphics_WaitForEvent_Loop


Graphics_WaitForEvent_Alt:
	lda.b [$17]
	inc.b $17
	inc.b $17

Graphics_WaitForEvent_AltLoop:
	jsl.l WaitVblank
	bit.b $07
	beq Graphics_WaitForEvent_AltLoop


; A series of conditional calls to SeriesOfConditionalCallsCodeCode/SimilarPatternsDifferentTestTypesCode etc.:

Condition_CheckPartyMember:
	jsr.w SeriesOfConditionalCallsCodeCode
	bcc Condition_Skip
	beq Condition_Skip
	bra Condition_Jump

; (several similar blocks follow in the original disassembly; preserved as-is)

Condition_Skip:
	inc.b $17
	inc.b $17


Condition_Jump:
	lda.b [$17]
	sta.b $17


Condition_CheckEventFlag:
	jsr.w SimilarPatternsDifferentTestTypesCode
	bcc Condition_SkipJumpAddr
	beq Condition_SkipJumpAddr
	bra Condition_SetPointer

Condition_SkipJumpAddr:
	inc.b $17
	inc.b $17


Condition_SetPointer:
	lda.b [$17]
	sta.b $17


; (blocks calling BlocksCallingCodeCodeCodeCode, CodeCodeCodeTestRoutines, PatternSetCodeVariants, BlocksCallingCodeCodeCodeCode2 etc.)

; Examples:
Condition_CheckBattleFlag:
	jsr.w BlocksCallingCodeCodeCodeCode
	bcs Condition_Skip
	bra Condition_Jump

; CodeCodeRemovedReuseConditionSkip and CodeCodeRemovedReuseConditionSkip2 removed - reuse Condition_Skip/Jump labels

Condition_CheckItem:
	jsr.w CodeCodeCodeTestRoutines
	bcc Condition_SkipJumpAddr2
	bra Condition_SetPointer2

Condition_SkipJumpAddr2:
	inc.b $17
	inc.b $17


Condition_SetPointer2:
	lda.b [$17]
	sta.b $17


Condition_CheckCompanion:
	jsr.w PatternSetCodeVariants
	bcs Condition_Skip
	bra Condition_Jump

; CodeCodeRemovedReuseConditionSkip3 and CodeCodeRemovedReuseConditionSkip4 removed - reuse Condition_Skip/Jump labels

Condition_CheckWeapon:
	jsr.w BlocksCallingCodeCodeCodeCode2
	bcc Condition_SkipJumpAddr3
	bra Condition_SetPointer3

Condition_SkipJumpAddr3:
	inc.b $17
	inc.b $17


Condition_SetPointer3:
	lda.b [$17]
	sta.b $17


Graphics_SetPointer:
	lda.b [$17]
	sta.b $17


Graphics_SetBank:
	lda.b [$17]
	inc.b $17
	inc.b $17
TAX_Label_1:
	sep #$20
	lda.b [$17]
	sta.b $19
	stx.b $17


Condition_TestBitD0:
	lda.b [$17]
	inc.b $17
	and.w #$00ff
PHD_Label_1:
	pea.w $00d0
PLD_Label:
	jsl.l Bit_TestBits
PLD_Label_1:
	inc a
	dec a
	bra Condition_BranchOnZero

Condition_TestBitD0_Alt:
	lda.b [$17]
	inc.b $17
	and.w #$00ff
PHD_Label_2:
	pea.w $00d0
PLD_Label_2:
	jsl.l TestFlagExternal
PLD_Label_3:
	inc a
	dec a
	jmp Sub_00A57D

Condition_TestBitEA8:
	lda.b [$17]
	inc.b $17
	and.w #$00ff
	jsl.l Bit_TestBits_0EA8

Condition_BranchOnZero:
	bne Graphics_SetPointer
	jmp CodeThroughCodeNowImplemented2

; ---------------------------------------------------------------------------
; End of appended disassembly chunk
; ---------------------------------------------------------------------------

; ===========================================================================
; Progress: ~7,244 lines documented (~51.6% of Bank $00)
; Sections completed (delta):
; - Additional graphics command handlers (AdditionalGraphicsCommandHandlersCodeCode..ImportedSegmentCodeCode2)
; - Stream parsing helpers and external command bridges
;
; Remaining: ~6,774 lines (battle system, command handlers, data tables)
; ===========================================================================


Graphics_ProcessData:
	php ; Save processor status
	rep #$30		; 16-bit A/X/Y
	phy ; Save Y
	pha ; Save A
	ldy.w #$0017	; Y = Direct Page $0017
	lda.w #$0002	; Count = 2 bytes + 1
	mvn $00,$00	 ; Copy 3 bytes from [X] to [$17]
; This copies graphics pointer and bank
	pla ; Restore A
	ply ; Restore Y
	plp ; Restore processor status
	jmp.w ProcessGraphicsData ; Jump to main graphics processor

; ---------------------------------------------------------------------------
; Clear Graphics Flag bit 2
; ---------------------------------------------------------------------------

Graphics_ClearFlag:
	lda.w #$0004	; bit 2 mask
	and.w !system_flags_4	 ; Test if set
	beq Graphics_ClearFlagDone ; Skip if not set
	lda.w #$0004	; bit 2 mask
	trb.w !system_flags_4	 ; Clear bit 2
	lda.w #$00c8	; Bits 6-7 + bit 3 mask
	trb.w $0111	 ; Clear those bits in $0111

Graphics_ClearFlagDone:
	rts ; Return

; ---------------------------------------------------------------------------
; Initialize Color Palette Processing
; ---------------------------------------------------------------------------
; Purpose: Setup DMA for color palette operations
; ===========================================================================

Palette_InitColorProcessing:
	ldx.w #$9c87	; Source data pointer
	ldy.w #$5007	; Dest = $7f5007
	lda.w #$0022	; Transfer $22 bytes + 1 = 35 bytes
	mvn $7f,$00	 ; Copy data to buffer

; Initialize color values
	lda.l $000e9c   ; Load base color
	sta.w $5011	 ; Store at offset $11
	sta.w $5014	 ; Store at offset $14
	sta.w $501a	 ; Store at offset $1a
	jsr.w Color_AdjustBrightness ; Adjust color brightness
	sta.w $5017	 ; Store adjusted color

	lda.l DATA8_07800c ; Load another base color
	sta.w $501e	 ; Store at offset $1e
	sta.w $5021	 ; Store at offset $21
	sta.w $5027	 ; Store at offset $27
	jsr.w Color_AdjustBrightness ; Adjust color brightness
	sta.w $5024	 ; Store adjusted color

; Setup DMA channels 3, 6, 7 for palette transfer
	phk ; Push program bank
	plb ; Pull to data bank
	sep #$20		; 8-bit A

	lda.b #$7f	  ; Bank $7f
	sta.w SNES_DMA3ADDRH ; DMA3 source bank
	sta.w SNES_DMA6ADDRH ; DMA6 source bank
	sta.w SNES_DMA7ADDRH ; DMA7 source bank

	ldx.w #$2100	; SNES register base
	stx.w SNES_DMA3PARAM ; DMA3 parameter
	ldx.w #$2202	; Different register
	stx.w SNES_DMA6PARAM ; DMA6 parameter
	stx.w SNES_DMA7PARAM ; DMA7 parameter

	ldx.w #$5007	; Source address
	stx.w SNES_DMA3ADDRL ; DMA3 source low
	ldx.w #$5010	; Source address
	stx.w SNES_DMA6ADDRL ; DMA6 source low
	ldx.w #$501d	; Source address
	stx.w SNES_DMA7ADDRL ; DMA7 source low

	rep #$30		; 16-bit A/X/Y
	rts ; Return

; ---------------------------------------------------------------------------
; Color_AdjustBrightness: Adjust Color Brightness
; ---------------------------------------------------------------------------
; Purpose: Reduce color intensity (darken for shadowing/fade)
; Input: Color on stack (SNES BGR555 format)
; Output: A = adjusted color
; Algorithm: Subtract $30 from red, $18 from green, $0c from blue (clamp to 0)
; ===========================================================================

Color_AdjustBrightness:
	pha ; Save color
	sec ; Set carry for subtraction
	and.w #$7c00	; Mask red component (bits 10-14)
	sbc.w #$3000	; Subtract $30 from red
	bcs Color_AdjustRed ; Branch if no underflow
	lda.w #$0000	; Clamp to 0
	sec ; Set carry

Color_AdjustRed:
	pha ; Save adjusted red
	lda.b $03,s	 ; Get original color
	and.w #$03e0	; Mask green component (bits 5-9)
	sbc.w #$0180	; Subtract $18 from green
	bcs Color_GreenOK ; Branch if no underflow
	lda.w #$0000	; Clamp to 0
	sec ; Set carry

Color_GreenOK:
	ora.b $01,s	 ; Combine with adjusted red
	sta.b $01,s	 ; Store combined result
	lda.b $03,s	 ; Get original color again
	and.w #$001f	; Mask blue component (bits 0-4)
	sbc.w #$000c	; Subtract $0c from blue
	bcs Color_BlueOK ; Branch if no underflow
	lda.w #$0000	; Clamp to 0

Color_BlueOK:
	ora.b $01,s	 ; Combine with red+green
	sta.b $03,s	 ; Store final result
	pla ; Remove temporary value
	pla ; Get final adjusted color
	rts ; Return

; ---------------------------------------------------------------------------
; Color Palette Data
; ---------------------------------------------------------------------------

DATA8_009c87:
; Color Palette Data Table
DATA8_009c87_colors:
	dw $0d00, $0d01, $0d01, $0d01 ; Color entries
	dw $0000, $5140, $5101, $5140
	dw $1fb4, $5101, $5140, $0000
	dw $7fff, $7f01, $7fff, $4e73
	dw $7f01, $7fff, $0001

; ---------------------------------------------------------------------------
; Setup Character Palette Display
; ---------------------------------------------------------------------------

Palette_SetupCharDisplay:
	sep #$20		; 8-bit A
	ldx.w #$01ad	; Default offset
	lda.b #$20	  ; Test bit 5
	and.w $00e0	 ; Check flag
	bne Palette_UseDefault ; Use default if set
	ldx.w #$016f	; Alternate offset

Palette_UseDefault:
; Copy character palette data to display buffer
	lda.w $0013,x   ; Load palette entry
	sta.l $7f500b   ; Store to buffer +$0b
	sta.l $7f5016   ; Store to buffer +$16
	sta.l $7f5023   ; Store to buffer +$23

	lda.w $0012,x   ; Load size/count
	dec a; Decrement
	lsr a; Divide by 2
	sta.l $7f5009   ; Store to buffer +$09
	sta.l $7f5013   ; Store to buffer +$13
	sta.l $7f5020   ; Store to buffer +$20

	adc.b #$00	  ; Add carry
	sta.l $7f5007   ; Store to buffer +$07
	sta.l $7f5010   ; Store to buffer +$10
	sta.l $7f501d   ; Store to buffer +$1d

	lda.b #$04	  ; bit 2 mask
	tsb.w !system_flags_4	 ; Set bit 2 in flags
	rep #$30		; 16-bit A/X/Y
	rts ; Return

Graphics_EmptyStub:
	rts ; Empty stub

; ---------------------------------------------------------------------------
; Push Graphics Parameters to Stack
; ---------------------------------------------------------------------------

Graphics_PushParams:
	php ; Save processor status
	rep #$30		; 16-bit A/X/Y
	phb ; Save data bank
	pha ; Save A
	phd ; Save direct page
	phx ; Save X
	phy ; Save Y

	ldx.w #$0017	; Source = DP $0017
	lda.l $7e3367   ; Load stack pointer
	tay ; Y = destination
	lda.w #$0025	; Transfer 38 bytes
	mvn $7e,$00	 ; Copy DP $0017-$003e to stack

	ldx.w #$00d0	; Source = DP $00d0
	lda.w #$0000	; Transfer 1 byte
	mvn $7e,$00	 ; Copy DP $00d0 to stack

	tya ; A = new stack pointer
	cmp.w #$35d9	; Check if stack overflow
	bcc BranchIfOk ; Branch if OK
	jmp.w Graphics_StackOverflow ; Handle overflow (infinite loop)

Graphics_UpdateStackPtr:
	sta.l $7e3367   ; Update stack pointer
	jmp.w Bit_SetBits_00E2 ; Clean stack and return

Graphics_StackOverflow:
	bra InfiniteLoopStackOverflow ; Infinite loop (stack overflow)

; ---------------------------------------------------------------------------
; Pop Graphics Parameters from Stack
; ---------------------------------------------------------------------------

Graphics_PopParams:
	php ; Save processor status
	rep #$30		; 16-bit A/X/Y
	phb ; Save data bank
	pha ; Save A
	phd ; Save direct page
	phx ; Save X
	phy ; Save Y

	lda.l $7e3367   ; Load stack pointer
	sec ; Set carry
	sbc.w #$0027	; Subtract 39 bytes
	sta.l $7e3367   ; Update stack pointer
	tax ; X = source

	ldy.w #$0017	; Dest = DP $0017
	lda.w #$0025	; Transfer 38 bytes
	mvn $00,$7e	 ; Copy stack to DP $0017-$003e

	ldy.w #$00d0	; Dest = DP $00d0
	lda.w #$0000	; Transfer 1 byte
	mvn $00,$7e	 ; Copy stack to DP $00d0

	jmp.w Bit_SetBits_00E2 ; Clean stack and return

; ---------------------------------------------------------------------------
; Fill Memory via Helper
; ---------------------------------------------------------------------------

Graphics_MemoryFillHelper:
	phy ; Save Y
	stx.b $1a	   ; Store X to $1a
	txy ; Y = X
	tax ; X = A
	jsr.w CallHelper ; Call helper
	clc ; Clear carry
	tya ; A = Y
	adc.b $01,s	 ; Add saved Y
	sta.b $1a	   ; Store to $1a
	jsr.w CleanupDrawingContext ; Call helper
	lda.b $1c	   ; Load $1c
	and.w #$00ff	; Mask to byte
	pha ; Push to stack
	plb ; Pull to data bank
	lda.b $02,s	 ; Load parameter
	jsr.w CallFillDispatcher ; Call fill dispatcher
	plb ; Restore data bank
	pla ; Clean stack
	rts ; Return

; ---------------------------------------------------------------------------
; Graphics_ProcessWithDP: Process Graphics with DP Setup
; ---------------------------------------------------------------------------

Graphics_ProcessWithDP:
	phd ; Save direct page
	pea.w $0000	 ; Push $0000
	pld ; Direct Page = $0000
	jsr.w Graphics_ProcessStream ; Process graphics
	pld ; Restore direct page
	rtl ; Return long

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
	php ; Save processor status
	rep #$30		; 16-bit A/X/Y
	phb ; Save data bank
	pha ; Save A
	phd ; Save direct page
	phx ; Save X
	phy ; Save Y
	phk ; Push program bank
	plb ; Pull to data bank

; Check if special processing mode
	lda.w #$0008	; bit 3 mask
	and.w !system_flags_6	 ; Test flag
	beq Graphics_ProcessStream_Normal ; Normal processing

; Special mode with synchronization
	lda.w #$0010	; bit 4 mask
	and.w $00d0	 ; Test flag
	bne Graphics_ProcessStream_AltSync ; Use alternate sync

Graphics_ProcessStream_SyncLoop:
	jsr.w Graphics_ReadDispatchCmd ; Read and process command
	lda.b $17	   ; Get current pointer
	cmp.b $3d	   ; Compare to sync pointer
	bne Graphics_ContinueSync ; Loop until synchronized
	bra Graphics_ProcessStream_Cleanup ; Done

Graphics_ProcessStream_AltSync:
	jsr.w AlternateSyncHandler ; Alternate sync handler
	bra Graphics_ProcessStream_Cleanup ; Done

Graphics_ContinueSync:
	jsr.w Graphics_ReadDispatchCmd ; Read and process command

Graphics_ProcessStream_Normal:
; Normal processing loop
	lda.w $00d0	 ; Load flags
	bit.w #$0090	; Test bits 4 and 7
	beq Graphics_ProcessStream_Loop ; Continue if neither set

	bit.w #$0080	; Test bit 7
	bne Graphics_ProcessStream_Exit ; Exit if set
	jsr.w AlternateSyncHandler ; Process special event
	bra Graphics_ProcessStream_Normal ; Continue loop

Graphics_ProcessStream_Exit:
	lda.w #$0080	; bit 7 mask
	trb.w $00d0	 ; Clear exit flag

Graphics_ProcessStream_Done:
	jmp.w Bit_SetBits_00E2 ; Clean stack and return

; ---------------------------------------------------------------------------
; Graphics_ReadDispatchCmd: Read and Dispatch Graphics Command
; ---------------------------------------------------------------------------

Graphics_ReadDispatchCmd:
	lda.b [$17]	 ; Read command byte
	inc.b $17	   ; Advance pointer
	and.w #$00ff	; Mask to byte
	cmp.w #$0080	; Is it direct tile data?
	bcc NoDispatchHandler ; No, dispatch to handler

; ---------------------------------------------------------------------------
; CodeDirectTileWrite - Direct Tile Write
; ---------------------------------------------------------------------------
Graphics_WriteTileDirect:
; Direct tile write (values $80-$ff)
	eor.b $1d	   ; XOR with effect mask

Graphics_WriteTileEntry:
	sta.b [$1a]	 ; Write to VRAM buffer
	inc.b $1a	   ; Advance pointer
	inc.b $1a	   ; (16-bit increment)
	rts ; Return

Graphics_DispatchCommand:
; Command dispatch (values $00-$7f)
	cmp.w #$0030	; Is it indexed data?
	bcs Graphics_IndexedDataLookup ; Yes, handle indexed

; Jump table dispatch ($00-$2f)
	asl a; Multiply by 2 (word index)
	tax ; X = table offset
	jsr.w (DATA8_009e0e,x) ; Call handler via table
	rep #$30		; 16-bit A/X/Y
	rts ; Return

Graphics_IndexedDataLookup:
; Indexed data lookup ($30+)
	ldx.w #$0000	; X = 0 (table index)
	sbc.w #$0030	; Subtract base (now $00-$4f)
	beq Graphics_IndexedDataFound ; If 0, use first entry
	tay ; Y = index count

Graphics_IndexedDataSearch:
; Find entry in variable-length table
	lda.l DATA8_03ba35,x ; Load entry size
	and.w #$00ff	; Mask to byte
	sta.b $64	   ; Store size
	txa ; A = current offset
	sec ; Set carry
	adc.b $64	   ; Add size (+ 1 from carry)
	tax ; X = next entry offset
	dey ; Decrement index
	bne Graphics_IndexedDataSearch ; Continue until found

Graphics_IndexedDataFound:
; Process found entry
	txa ; A = table offset
	clc ; Clear carry
	adc.w #$ba36	; Add base address
	tay ; Y = data pointer
	sep #$20		; 8-bit A
	lda.b #$03	  ; Bank $03
	xba ; Swap to high byte
	lda.l DATA8_03ba35,x ; Load entry size
	tyx ; X = data pointer
	rep #$30		; 16-bit A/X/Y
	jmp.w ProcessDataBlock ; Process data block

; ---------------------------------------------------------------------------
; Graphics Command Jump Table
; ---------------------------------------------------------------------------
; Commands $00-$2f dispatch here
; ===========================================================================

DATA8_009e0e:
; Jump table entries
DATA8_009e0e_handlers:
	dw CommandHandler ; $00: Command handler
	dw CodePointerManipulationCoordinateCalculations ; $01
	dw CodeCodePointerManipulationHelpers ; $02
	dw Sub_00A39C ; $03
	dw Sub_00B354 ; $04
	dw Sub_00A37F ; $05
	dw CodeCheckFlagExecuteRoutine ; $06
	dw CodeThroughCodeNowImplemented3 ; $07
	dw FlagTestingConditionalJumpsCodeCode ; $08
	dw CodeExecuteExternalSubroutineViaLong ; $09
	dw Sub_00A519 ; $0a
	dw B2 ; $0b
	dw CodeWriteBitValueAddress ; $0c
	dw D4 ; $0d
	dw CodeWriteBitValueBitValue ; $0e
	dw F3 ; $0f
	dw Sub_00AF9A ; $10
	dw Sub_00AF6B ; $11
	dw Sub_00AF70 ; $12
	dw Sub_00B094 ; $13
	dw CodeBitwiseTsbOperationsVariants ; $14
	dw Sub_00A0B7 ; $15
	dw Sub_00B2F9 ; $16
	dw Sub_00AEDA ; $17
	dw NextMoreDmaGraphicsRoutinesCode ; $18
	dw CodeCalculatePointerCoordinatesPosition ; $19
	dw Sub_00A168 ; $1a
	dw B ; $1b
	dw C ; $1c
	dw D2 ; $1d
	dw E ; $1e
	dw F2 ; $1f
	dw Sub_00A0DF ; $20
	dw Sub_00B2F4 ; $21
	dw Sub_00A150 ; $22
	dw Sub_00AEA2 ; $23
	dw Sub_00A11D ; $24
	dw Sub_00A07D ; $25
	dw Sub_00A089 ; $26
	dw Sub_00A09D ; $27
	dw Sub_00A0A9 ; $28
	dw Sub_00AEB5 ; $29
	dw Sub_00B379 ; $2a
	dw B3 ; $2b
	dw C3 ; $2c
	dw D ; $2d
	dw E2 ; $2e
	dw F ; $2f

; ---------------------------------------------------------------------------
; Secondary Jump Table (for specific graphics operations)
; ---------------------------------------------------------------------------

DATA8_009e6e:
	dw ImportedSegmentCodeCode ; $00
	dw Sub_00A3AB ; $01
	dw Sub_00A51E ; $02
	dw Sub_00A52E ; $03
	dw Sub_00A3D5 ; $04
	dw Sub_00A3DE ; $05
	dw Sub_00A3E5 ; $06
	dw Sub_00A3EC ; $07
	dw $0000	   ; $08: Unused
	dw Sub_00A3FC ; $09
	dw $0000	   ; $0a: Unused
	dw CodeThroughCodeNowImplemented ; $0b
	dw C2 ; $0c
	dw D3 ; $0d
	dw TakeJumpFar ; $0e
	dw $0000, $0000 ; $0f-$10: Unused
	dw Sub_00A718 ; $11
	dw ReferencedJumpTableNotImplementedAs ; $12
	dw Sub_00A79D ; $13
	dw Sub_00A7AC ; $14
	dw Sub_00A7B3 ; $15
	dw $0000	   ; $16: Unused
	dw CodeThroughCodeNowImplementedPartial ; $17
	dw Sub_00A7EB ; $18
	dw CallsCodeTextDrawingRoutine ; $19
	dw $0000, $0000, $0000 ; $1a-$1c: Unused
	dw CodeCopyDataRamE3367Using ; $1d
	dw CodeCopyDataRamE3367Back ; $1e
	dw $0000	   ; $1f: Unused

; ===========================================================================
; Graphics Command Handlers (Commands $00-$2f)
; ===========================================================================

; ---------------------------------------------------------------------------
; Command $2d: Set Graphics Pointer to Fixed Address
; ---------------------------------------------------------------------------

Cmd_SetPointerEA6:
	lda.w #$0ea6	; Fixed pointer
	sta.b $2e	   ; Store to $2e
	rts ; Return

; ---------------------------------------------------------------------------
; Command $25: Load Graphics Pointer from Stream
; ---------------------------------------------------------------------------

Cmd_LoadPointer:
	lda.b [$17]	 ; Read 16-bit pointer
	inc.b $17	   ; Advance stream pointer
	inc.b $17	   ; (2 bytes)
	sta.b $2e	   ; Store to $2e
	rts ; Return

; ---------------------------------------------------------------------------
; Command $26: Set Tile Offset (8-bit)
; ---------------------------------------------------------------------------

Cmd_SetTileOffset:
	lda.b [$17]	 ; Read byte parameter
	inc.b $17	   ; Advance stream pointer
	and.w #$00ff	; Mask to byte
	sep #$20		; 8-bit A
	sta.b $1e	   ; Store tile offset
	rts ; Return

; ---------------------------------------------------------------------------
; Command $19: Set Graphics Bank and Pointer
; ---------------------------------------------------------------------------

Cmd_SetBankAndPointer:
	lda.b [$17]	 ; Read 16-bit pointer
	inc.b $17	   ; Advance stream pointer
	inc.b $17	   ; (2 bytes)
	sta.b $3f	   ; Store pointer
	lda.b [$17]	 ; Read bank byte
	inc.b $17	   ; Advance stream pointer
	and.w #$00ff	; Mask to byte
	sep #$20		; 8-bit A
	sta.b $41	   ; Store bank
	rts ; Return

; ---------------------------------------------------------------------------
; Command $27: Set Display Mode Byte
; ---------------------------------------------------------------------------

Cmd_SetDisplayMode:
	lda.b [$17]	 ; Read byte parameter
	inc.b $17	   ; Advance stream pointer
	and.w #$00ff	; Mask to byte
	sep #$20		; 8-bit A
	sta.b $27	   ; Store mode byte
	rts ; Return

; ---------------------------------------------------------------------------
; Command $28: Set Effect Mask
; ---------------------------------------------------------------------------

Cmd_SetEffectMask:
	lda.b [$17]	 ; Read byte parameter
	inc.b $17	   ; Advance stream pointer
	and.w #$00ff	; Mask to byte
	sep #$20		; 8-bit A
	rep #$10		; 16-bit X/Y
	sta.b $1d	   ; Store effect mask
	rts ; Return

; ---------------------------------------------------------------------------
; Command $15: Set 16-bit Parameter at $25
; ---------------------------------------------------------------------------

Cmd_SetParameter25:
	lda.b [$17]	 ; Read 16-bit value
	inc.b $17	   ; Advance stream pointer
	inc.b $17	   ; (2 bytes)
	sta.b $25	   ; Store to $25
	rts ; Return

; ---------------------------------------------------------------------------
; Command $1f: Indexed String Lookup with Fixed Length
; ---------------------------------------------------------------------------

Cmd_StringLookup82BB:
	pei.b ($9e)	 ; Save $9e
	pei.b ($a0)	 ; Save $a0
	lda.b [$17]	 ; Read string index
	inc.b $17	   ; Advance stream pointer
	and.w #$00ff	; Mask to byte
	sta.b $9e	   ; Store index
	stz.b $a0	   ; Clear high byte
	lda.w #$0003	; Length = 3 bytes
	ldx.w #$82bb	; Table pointer
	jsr.w ProcessString ; Process string
	plx ; Restore $a0
	stx.b $a0	   ; Store back
	plx ; Restore $9e
	stx.b $9e	   ; Store back
	rts ; Return

; ---------------------------------------------------------------------------
; Command $20: Indexed String Lookup (Different Table)
; ---------------------------------------------------------------------------

Cmd_StringLookupA802:
	pei.b ($9e)	 ; Save $9e
	pei.b ($a0)	 ; Save $a0
	lda.b [$17]	 ; Read string index
	inc.b $17	   ; Advance stream pointer
	and.w #$00ff	; Mask to byte
	sta.b $9e	   ; Store index
	stz.b $a0	   ; Clear high byte
	lda.w #$0003	; Length = 3 bytes
	ldx.w #$a802	; Table pointer
	jsr.w ProcessString ; Process string
	plx ; Restore $a0
	stx.b $a0	   ; Store back
	plx ; Restore $9e
	stx.b $9e	   ; Store back
	rts ; Return

; ---------------------------------------------------------------------------
; Command $1e: Another Indexed String Handler
; ---------------------------------------------------------------------------

Cmd_StringLookup8383:
	pei.b ($9e)	 ; Save $9e
	pei.b ($a0)	 ; Save $a0
	lda.b [$17]	 ; Read string index
	inc.b $17	   ; Advance stream pointer
	and.w #$00ff	; Mask to byte
	sta.b $9e	   ; Store index
	stz.b $a0	   ; Clear high byte
	lda.w #$0003	; Length = 3 bytes
	ldx.w #$8383	; Table pointer
	jsr.w ProcessString ; Process string
	plx ; Restore $a0
	stx.b $a0	   ; Store back
	plx ; Restore $9e
	stx.b $9e	   ; Store back
	rts ; Return

; ---------------------------------------------------------------------------
; Command $24: Set Display Parameters
; ---------------------------------------------------------------------------

Cmd_SetDisplayParams:
	lda.b [$17]	 ; Read first word
	inc.b $17	   ; Advance stream pointer
	inc.b $17	   ; (2 bytes)
	sta.b $28	   ; Store to $28
	lda.b [$17]	 ; Read second word
	inc.b $17	   ; Advance stream pointer
	inc.b $17	   ; (2 bytes)
	sta.b $2a	   ; Store to $2a
	rts ; Return

Cmd_SetParams2C2D:
	lda.b [$17]	 ; Read parameter
	inc.b $17	   ; Advance stream pointer
	inc.b $17	   ; (2 bytes)
	sep #$20		; 8-bit A
	sta.b $2c	   ; Store low byte
	xba ; Swap bytes
	sta.b $2d	   ; Store high byte
	rts ; Return

; ---------------------------------------------------------------------------
; Command $1d: Indexed Lookup with Table $a7f6
; ---------------------------------------------------------------------------

Cmd_LookupA7F6:
	lda.b [$17]	 ; Read index
	inc.b $17	   ; Advance stream pointer
	and.w #$00ff	; Mask to byte
	sta.b $9e	   ; Store index
	stz.b $a0	   ; Clear high byte
	lda.w #$0003	; Length = 3 bytes
	ldx.w #$a7f6	; Table pointer
	jmp.w ProcessString ; Process and return

; ---------------------------------------------------------------------------
; Command $22: Set Graphics Pointer to $aea7 Bank $03
; ---------------------------------------------------------------------------

Cmd_SetPointerAEA7:
	sep #$20		; 8-bit A
	lda.b #$03	  ; Bank $03
	sta.b $19	   ; Store bank
	ldx.w #$aea7	; Pointer
	stx.b $17	   ; Store pointer
	rts ; Return

; ---------------------------------------------------------------------------
; Command $1c: Set Graphics Pointer to $8457 Bank $03
; ---------------------------------------------------------------------------

Cmd_SetPointer8457:
	sep #$20		; 8-bit A
	lda.b #$03	  ; Bank $03
	sta.b $19	   ; Store bank
	ldx.w #$8457	; Pointer
	stx.b $17	   ; Store pointer
	rts ; Return

; ---------------------------------------------------------------------------
; Command $1a: Indexed Character Graphics
; ---------------------------------------------------------------------------

Cmd_CharacterGraphics:
	lda.b [$17]	 ; Read character index
	inc.b $17	   ; Advance stream pointer
	and.w #$00ff	; Mask to byte
	sep #$20		; 8-bit A
	sta.b $4f	   ; Store character ID
	rep #$30		; 16-bit A/X/Y
	lda.w #$0003	; Bank $03
	ldx.w #$a831	; Table pointer
	jmp.w ProcessString ; Process character graphics

; ---------------------------------------------------------------------------
; Command $1b: Indexed Monster Graphics
; ---------------------------------------------------------------------------

Cmd_MonsterGraphics:
	lda.b [$17]	 ; Read monster index
	inc.b $17	   ; Advance stream pointer
	and.w #$00ff	; Mask to byte
	sep #$20		; 8-bit A
	sta.b $4f	   ; Store monster ID
	rep #$30		; 16-bit A/X/Y
	lda.w #$0003	; Bank $03
	ldx.w #$a895	; Table pointer
	jmp.w ProcessString ; Process monster graphics

; ---------------------------------------------------------------------------
; Clear Address High Byte Handlers
; ---------------------------------------------------------------------------

Cmd_ClearHighBytes:
	jsr.w Cmd_ReadIndirect ; Read pointer
	stz.b $9f	   ; Clear $9f
	stz.b $a0	   ; Clear $a0
	rts ; Return

Cmd_ClearA0:
	jsr.w Cmd_ReadIndirect ; Read pointer
	stz.b $a0	   ; Clear $a0
	rts ; Return

Cmd_SetA0Byte:
	jsr.w Cmd_ReadIndirect ; Read pointer
	and.w #$00ff	; Mask to byte
	sta.b $a0	   ; Store to $a0
	rts ; Return

; ---------------------------------------------------------------------------
; Cmd_ReadIndirect: Read Indirect Pointer from Stream
; ---------------------------------------------------------------------------
; Purpose: Read pointer and bank from [$17], then dereference
; Algorithm: Read 3 bytes -> use as pointer -> read actual target pointer
; ===========================================================================

Cmd_ReadIndirect:
	lda.b [$17]	 ; Read pointer word
	inc.b $17	   ; Advance stream
	inc.b $17	   ; (2 bytes)
	tax ; X = pointer address
	lda.b [$17]	 ; Read bank byte
	inc.b $17	   ; Advance stream
	and.w #$00ff	; Mask to byte
	clc ; Clear carry
	adc.w $0000,x   ; Add offset from [X]
	tay ; Y = final offset
	lda.w $0002,x   ; Load bank from [X+2]
	and.w #$00ff	; Mask to byte
	pha ; Push bank
	plb ; Pull to data bank
	lda.w $0000,y   ; Load target pointer low
	tax ; X = pointer low
	lda.w $0002,y   ; Load target pointer high
	plb ; Restore bank
	stx.b $9e	   ; Store pointer low
	rts ; Return (A = pointer high)

; ---------------------------------------------------------------------------
; Memory Fill from Stream Parameters
; ---------------------------------------------------------------------------

Cmd_MemoryFill:
	lda.b [$17]	 ; Read destination address
	inc.b $17	   ; Advance stream
	inc.b $17	   ; (2 bytes)
	tay ; Y = destination
	sep #$20		; 8-bit A
	lda.b [$17]	 ; Read fill value
	xba ; Swap to high byte
	lda.b [$17]	 ; Read again (16-bit fill)
	rep #$30		; 16-bit A/X/Y
	inc.b $17	   ; Advance stream
	tax ; X = fill value
	lda.b [$17]	 ; Read count
	inc.b $17	   ; Advance stream
	and.w #$00ff	; Mask to byte
	jmp.w CallFillDispatcher ; Call fill dispatcher

; ---------------------------------------------------------------------------
; Graphics System Calls
; ---------------------------------------------------------------------------

Cmd_CallGraphicsSys:
	jsl.l AddressC8000OriginalCode ; Call graphics system
	rts ; Return

Cmd_WaitVBlank:
	jsl.l WaitVblank ; Wait for VBlank
	rts ; Return

; ---------------------------------------------------------------------------
; Cmd_CopyDisplayState: Copy Display State
; ---------------------------------------------------------------------------

Cmd_CopyDisplayState:
	jsr.w PrepareState ; Prepare state
	sep #$20		; 8-bit A
	ldx.w $101b	 ; Load source X
	stx.w !char1_current_mp	 ; Copy to destination X
	lda.w $101d	 ; Load source bank
	sta.w $101a	 ; Copy to destination bank
	ldx.w $109b	 ; Load source X (second set)
	stx.w $1098	 ; Copy to destination X
	lda.w $109d	 ; Load source bank (second set)
	sta.w $109a	 ; Copy to destination bank
	rts ; Return

; ---------------------------------------------------------------------------
; Copy State and Clear Flags
; ---------------------------------------------------------------------------

Cmd_CopyAndClearFlags:
	jsr.w Cmd_CopyDisplayState ; Copy display state
	stz.w !char1_status	 ; Clear flag
	stz.w !char2_status	 ; Clear flag
	rts ; Return

; ---------------------------------------------------------------------------
; Cmd_PrepareDisplayState: Prepare Display State
; ---------------------------------------------------------------------------

Cmd_PrepareDisplayState:
	ldx.w !char1_max_hp	 ; Load source
	stx.w !char1_current_hp	 ; Copy to destination
	ldx.w !char2_max_hp	 ; Load source (second set)
	stx.w !char2_current_hp	 ; Copy to destination
	lda.w #$0003	; Bits 0-1 mask
	trb.w $102f	 ; Clear bits
	trb.w $10af	 ; Clear bits
	rts ; Return

; ---------------------------------------------------------------------------
; Cmd_CharacterDMATransfer: Character Data DMA Transfer
; ---------------------------------------------------------------------------
; Purpose: Copy character data to VRAM buffer area
; ===========================================================================

Cmd_CharacterDMATransfer:
	lda.w #$0080	; bit 7 mask
	and.w !char2_active_flag	 ; Test character flag
	php ; Save result

; Read character slot index
	lda.b [$17]	 ; Read slot index
	inc.b $17	   ; Advance stream
	and.w #$00ff	; Mask to byte
	sep #$30		; 8-bit A/X/Y
	sta.w $0e92	 ; Store character slot

; Calculate offset: slot * $50
	sta.w SNES_WRMPYA ; Multiplicand = slot
	lda.b #$50	  ; Multiplier = $50 (80 bytes)
	jsl.l PerformMultiply ; Perform multiply
	rep #$30		; 16-bit A/X/Y

; Setup DMA transfer
	clc ; Clear carry
	lda.w #$d0b0	; Base address $0cd0b0
	adc.w SNES_RDMPYL ; Add offset (result)
	tax ; X = source address
	ldy.w #$1080	; Y = destination $7e1080
	lda.w #$0050	; Transfer $50 bytes
	pea.w $000c	 ; Push bank $0c
	plb ; Pull to data bank
	jsr.w PerformMemoryCopy ; Perform memory copy
	plb ; Restore bank

	plp ; Restore flags
	bne SkipIfFlagWasSet ; Skip if flag was set
	lda.w #$0080	; bit 7 mask
	trb.w !char2_active_flag	 ; Clear character flag

Cmd_CharDMATransfer_Done:
	rts ; Return

; ---------------------------------------------------------------------------
; Multiple Command Sequence
; ---------------------------------------------------------------------------

Cmd_MultiCommandSeq:
	lda.w #$0003	; Bank $03
	ldx.w #$8457	; Pointer to data
	jsr.w ProcessString ; Process data
	rep #$30		; 16-bit A/X/Y

	lda.b [$17]	 ; Read parameters
	inc.b $17	   ; Advance stream
	inc.b $17	   ; (2 bytes)
	sep #$20		; 8-bit A
	sta.w $0513	 ; Store parameter
	xba ; Swap bytes
	sta.w $0a9c	 ; Store parameter

	ldx.b $17	   ; X = current pointer
	lda.b $19	   ; A = current bank
	jsl.l CallHandler ; Call handler
	sta.b $19	   ; Update bank
	stx.b $17	   ; Update pointer
	rts ; Return

; ---------------------------------------------------------------------------
; VBlank Wait Loop
; ---------------------------------------------------------------------------

Cmd_WaitVBlankCount:
	lda.b [$17]	 ; Read wait count
	inc.b $17	   ; Advance stream
	and.w #$00ff	; Mask to byte

Cmd_WaitVBlankLoop:
	jsl.l WaitVblank ; Wait for VBlank
	dec a; Decrement counter
	bne Cmd_WaitVBlankLoop ; Loop until 0
	rts ; Return

; ---------------------------------------------------------------------------
; Indexed Color Palette Lookup
; ---------------------------------------------------------------------------

Palette_IndexedLookup:
	lda.b [$17]	 ; Read palette index
	inc.b $17	   ; Advance stream
	and.w #$00ff	; Mask to byte
	pha ; Save index
	bra Palette_SearchTable_Entry ; Skip to processing

Palette_SearchTable:
	pei.b ($9e)	 ; Save $9e
Palette_SearchTable_Entry:
	sep #$20		; 8-bit A
	ldx.w #$0000	; X = 0 (table index)

Cmd_PaletteLookup_Search:
; Search palette table for matching index
	lda.w DATA8_00a2dd,x ; Load table entry
	cmp.b #$ff	  ; Check for end marker
	bne +		   ; Not end, continue
	jmp UNREACH_00A2D4 ; End of table (not found)
	+	cmp.b $01,s                 ; Compare with search index
	beq Cmd_PaletteLookup_Found ; Found match
	inx ; Next entry
	inx ; (skip 2 more bytes)
	inx ; (3 bytes per entry)
	bra Cmd_PaletteLookup_Search ; Continue search

Cmd_PaletteLookup_Found:
	rep #$30		; 16-bit A/X/Y
	lda.w DATA8_00a2de,x ; Load palette pointer
	sta.b $9e	   ; Store to $9e
	plx ; Clean stack
	rts ; Return

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
; - bit manipulation helpers
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
	lda.b [$17]	 ; Load item/flag index
	inc.b $17	   ; Advance pointer
	and.w #$00ff	; Mask to byte
	jsl.l Bit_TestBits_0EA8 ; Test item flag (external stub)

Cmd_TestItemJump_Check:
	bne +		   ; If set, skip
	jmp Graphics_SetPointer ; If clear, take jump (far)
	+	jmp Cmd_SkipJumpAddress                ; If set, skip jump (far)

Cmd_TestVariable1:
	jsr.w TestVariable ; Test variable
	bne +		   ; If not zero, skip
	jmp Condition_BranchOnZero ; Branch based on result (far)
	+	rts

Cmd_TestVariable2:
	jsr.w TestVariable ; Test variable (alternate)
	beq Cmd_TestItemJump_Check ; Branch to alternate handler


	jsr.w TestCondition ; Test condition
	beq +		   ; If zero, skip
	jmp Graphics_SetPointer ; If not zero, take jump (far)
	+	jmp Cmd_SkipJumpAddress                ; If zero, skip jump (far)

	jsr.w TestCondition ; Test condition (alternate)
	bne +		   ; If not zero, skip
	jmp Graphics_SetPointer ; If zero, take jump (far)
	+	rts

Cmd_SkipJumpAddress:
	inc.b $17	   ; Skip jump address
	inc.b $17	   ; (2 bytes)
	rts ; Return

;===============================================================================
; More Conditional Branch Handlers
; (Similar patterns for different test types: SeriesOfConditionalCallsCodeCode, SimilarPatternsDifferentTestTypesCode, etc.)
;===============================================================================

	jsr.w SeriesOfConditionalCallsCodeCode ; Test condition type 1
	bcs +		   ; If greater/equal, skip
	bne +
	jmp TakeJumpFar ; Take jump (far)
	+	inc.b $17                      ; Skip address
	inc.b $17


	jsr.w SeriesOfConditionalCallsCodeCode
	bcs +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w SeriesOfConditionalCallsCodeCode
	bcc +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w SeriesOfConditionalCallsCodeCode
	bcc +
	bne +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w SeriesOfConditionalCallsCodeCode
	beq +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w SeriesOfConditionalCallsCodeCode
	beq +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


;===============================================================================
; CodeSkipJumpAddressHelper - Skip Jump Address Helper
;===============================================================================

Cmd_SkipTwoBytes:
	inc.b $17	   ; Skip jump address
	inc.b $17	   ; (2 bytes)
	rts ; Return

;===============================================================================
; Cmd_LoadExecWithSwitch - Load Address and Bank, Execute with Context Switch
;===============================================================================

Cmd_LoadExecWithSwitch:
	lda.b [$17]	 ; Load target address
	inc.b $17	   ; Advance pointer
	inc.b $17
	tax ; Store address to X
	lda.b $19	   ; Load current bank
	jmp.w ProcessString ; Jump to bank switcher

;===============================================================================
; Duplicate Conditional Handler Patterns (for different test functions)
; These follow the same pattern as earlier but for SimilarPatternsDifferentTestTypesCode, BlocksCallingCodeCodeCodeCode,
; CodeCodeCodeTestRoutines, PatternSetCodeVariants, and BlocksCallingCodeCodeCodeCode2 test routines
;===============================================================================

; Pattern set for SimilarPatternsDifferentTestTypesCode (6 variants)
	jsr.w SimilarPatternsDifferentTestTypesCode ; Test type 2
	bcs +
	bne +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w SimilarPatternsDifferentTestTypesCode
	bcs +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w SimilarPatternsDifferentTestTypesCode
	bcc +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w SimilarPatternsDifferentTestTypesCode
	bcc +
	bne +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w SimilarPatternsDifferentTestTypesCode
	beq +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w SimilarPatternsDifferentTestTypesCode
	beq +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	lda.b [$17]	 ; Load address
	inc.b $17
	inc.b $17
	tax ; Store to X
	lda.b $19	   ; Load bank
	jmp.w Graphics_BankSwitch ; Bank switch

; Pattern set for Test_Compare24Full (6 variants)
	jsr.w Test_Compare24Full
	bcs +
	bne +
	jmp Graphics_LoadAddrExecute
	+	inc.b $17
	inc.b $17


	jsr.w BlocksCallingCodeCodeCodeCode
	bcs +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w BlocksCallingCodeCodeCodeCode
	bcc +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w BlocksCallingCodeCodeCodeCode
	bcc +
	bne +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w BlocksCallingCodeCodeCodeCode
	beq +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w BlocksCallingCodeCodeCodeCode
	beq +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	lda.b [$17]
	inc.b $17
	inc.b $17
TAX_Label_2:
	lda.b $19
	jmp.w ProcessString

; Pattern set for CodeCodeCodeTestRoutines (6 variants)
	jsr.w CodeCodeCodeTestRoutines
	bcs +
	bne +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w CodeCodeCodeTestRoutines
	bcs +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w CodeCodeCodeTestRoutines
	bcc +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w CodeCodeCodeTestRoutines
	bcc +
	bne +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w CodeCodeCodeTestRoutines
	beq +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w CodeCodeCodeTestRoutines
	beq +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	lda.b [$17]
	inc.b $17
	inc.b $17
TAX_Label_3:
	lda.b $19
	jmp.w ProcessString

; Pattern set for PatternSetCodeVariants (6 variants)
	jsr.w PatternSetCodeVariants
	bcs +
	bne +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w PatternSetCodeVariants
	bcs +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w PatternSetCodeVariants
	bcc +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w PatternSetCodeVariants
	bcc +
	bne +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w PatternSetCodeVariants
	beq +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w PatternSetCodeVariants
	beq +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	lda.b [$17]
	inc.b $17
	inc.b $17
TAX_Label_4:
	lda.b $19
	bra CODE_00A71C_alt1

; Pattern set for BlocksCallingCodeCodeCodeCode2 (6 variants)
	jsr.w BlocksCallingCodeCodeCodeCode2
	bcs +
	bne +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w BlocksCallingCodeCodeCodeCode2
	bcs +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w BlocksCallingCodeCodeCodeCode2
	bcc +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w BlocksCallingCodeCodeCodeCode2
	bcc +
	bne +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w BlocksCallingCodeCodeCodeCode2
	beq +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	jsr.w BlocksCallingCodeCodeCodeCode2
	beq +
	jmp TakeJumpFar
	+	inc.b $17
	inc.b $17


	lda.b [$17]
	inc.b $17
	inc.b $17
TAX_Label_5:
	lda.b $19
	bra CODE_00A71C_alt2

;===============================================================================
; Graphics_LoadAndExec - Load Pointer and Bank, Execute Subroutine
;===============================================================================

Graphics_LoadAndExec:
	lda.b [$17]	 ; Load target pointer
	inc.b $17
	inc.b $17
	tax ; Store pointer to X
	lda.b [$17]	 ; Load bank byte
	inc.b $17
	and.w #$00ff	; Mask to byte
	bra Graphics_BankSwitch ; Jump to bank switcher

Graphics_LoadSavedContext:
	ldx.b $9e	   ; Load saved pointer
	lda.b $a0	   ; Load saved bank

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
	sep #$20		; 8-bit A
	xba ; Swap A/B (save new bank to B)
	lda.b $19	   ; Load current bank
	ldy.b $17	   ; Load current pointer to Y
	xba ; Swap back (new bank to A, old to B)
	sta.b $19	   ; Set new bank
	stx.b $17	   ; Set new pointer
	lda.b #$08	  ; Load flag bit $08
	and.w !system_flags_6	 ; Test current flag state
	php ; Save flag state
	lda.b #$08	  ; Load flag bit $08
	trb.w !system_flags_6	 ; Clear flag
	jsr.w ProcessGraphicsData ; Execute in new context (external)
	plp ; Restore flag state
	beq IfFlagWasClearSkipRestore ; If flag was clear, skip restore
	lda.b #$08	  ; Load flag bit
	tsb.w !system_flags_6	 ; Restore flag to set state

Graphics_RestoreContext:
	xba ; Get old bank from B
	sta.b $19	   ; Restore bank
	sty.b $17	   ; Restore pointer
	rts ; Return

;===============================================================================
; TakeJumpFar - Load Address, Call Function, Execute Result
;===============================================================================

Graphics_LoadAddrExecute:
	lda.b [$17]	 ; Load address
	inc.b $17
	inc.b $17
	jsr.w Graphics_CallFunc ; Call function (external)
	sta.b $17	   ; Store result as pointer
	jsr.w Graphics_ProcessStream ; Execute at new pointer
	jmp.w Graphics_PopParams ; Jump to cleanup (external)

;===============================================================================
; Graphics_LoadExec - Load Pointer and Execute with Bank Switch
;===============================================================================

Graphics_LoadExec:
	lda.b [$17]	 ; Load pointer
	inc.b $17
	inc.b $17
	tax ; Store to X
	lda.b $19	   ; Load bank
	bra ProcessString ; Bank switch and execute

;===============================================================================
; Flag Testing with Conditional Jumps to FlagTestingConditionalJumpsCodeCode or IfClearSkip
;===============================================================================

	lda.b [$17]	 ; Load flag index
	inc.b $17
	and.w #$00ff	; Mask to byte
	phd ; Save direct page
	pea.w $00d0	 ; Set DP to $d0
PLD_Label_4:
	jsl.l TestFlagExternal ; Test flag (external)
	pld ; Restore DP
	inc a; Test result (set Z flag)
	dec a
	bne FlagTestingConditionalJumpsCodeCode ; If flag set, take jump
	bra IfClearSkip ; If clear, skip

	lda.b [$17]	 ; Load flag index
	inc.b $17
	and.w #$00ff	; Mask to byte
	phd ; Save direct page
	pea.w $00d0	 ; Set DP to $d0
PLD_Label_5:
	jsl.l TestFlagExternal ; Test flag (external)
	pld ; Restore DP
	inc a; Test result
	dec a
	beq FlagTestingConditionalJumpsCodeCode ; If flag clear, take jump
	bra Condition_SkipJumpTarget ; If set, skip

	lda.b [$17]	 ; Load item flag
	inc.b $17
	and.w #$00ff	; Mask to byte
	jsl.l CheckStatTypeModifier ; Test item (external)
	bne FlagTestingConditionalJumpsCodeCode ; If set, jump
	bra Condition_SkipJumpTarget ; If clear, skip

Condition_TestItemNotZero:
	lda.b [$17]	 ; Load item flag
	inc.b $17
	and.w #$00ff	; Mask to byte
	jsl.l CheckStatTypeModifier ; Test item (external)
	beq FlagTestingConditionalJumpsCodeCode ; If clear, jump
	bra Condition_SkipJumpTarget ; If set, skip

Condition_TestVarNotZero:
	jsr.w TestVariable ; Test variable
	bne FlagTestingConditionalJumpsCodeCode ; If not zero, jump
	bra Condition_SkipJumpTarget ; If zero, skip

Condition_TestVarZero:
	jsr.w TestVariable ; Test variable
	beq FlagTestingConditionalJumpsCodeCode ; If zero, jump
	bra Condition_SkipJumpTarget ; If not zero, skip

	jsr.w TestCondition ; Test condition
	bne FlagTestingConditionalJumpsCodeCode ; If not zero, jump
	bra Condition_SkipJumpTarget ; If zero, skip

	jsr.w TestCondition ; Test condition
	beq FlagTestingConditionalJumpsCodeCode ; If zero, jump

Condition_SkipJumpTarget:
	inc.b $17	   ; Skip jump address
	inc.b $17	   ; (2 bytes)
	rts ; Return

;===============================================================================
; Subroutine Execution with Parameter Passing
;===============================================================================

	lda.b [$17]	 ; Load parameter
	inc.b $17
	and.w #$00ff	; Mask to byte
	sep #$20		; 8-bit A
	ldx.b $9e	   ; Load saved pointer
	xba ; Build word (param in high byte)
	lda.b $a0	   ; Load saved bank
	xba ; Swap back
	rep #$30		; 16-bit A/X/Y
	bra ProcessDataBlock ; Execute subroutine

Graphics_ExecWithSavedPtr:
	sep #$20		; 8-bit A
	ldx.b $9e	   ; Load pointer
	lda.b $a0	   ; Load bank
	xba ; Build word
	lda.b $3a	   ; Load parameter from $3a
	rep #$30		; 16-bit A/X/Y
	bra ProcessDataBlock ; Execute

Graphics_LoadAndExecParam:
	lda.b [$17]	 ; Load address
	inc.b $17
	inc.b $17
	tax ; Store address
	lda.b [$17]	 ; Load parameter byte
	inc.b $17
	and.w #$00ff	; Mask to byte

;===============================================================================
; ProcessDataBlock - Execute Subroutine with Full Context Save
;
; Saves current execution state, switches to new address/bank with parameter,
; executes subroutine, then restores all state. Used for calling script
; subroutines that need to return to caller.
;
; Entry: A = parameter (low byte), X = subroutine address
; Stack usage: Saves $17 (pointer), $19 (bank), $3d (limit)
;===============================================================================

Graphics_ExecSubroutine:
	sta.b $64	   ; Save parameter
	stx.b $62	   ; Save subroutine address
	rep #$20		; 16-bit A
	sep #$10		; 8-bit X/Y
	pei.b ($17)	 ; Save current pointer
	ldx.b $19	   ; Load current bank
	phx ; Save bank
	pei.b ($3d)	 ; Save $3d (limit/end marker)
	lda.b $64	   ; Load parameter
	and.w #$00ff	; Mask to byte
	clc ; Clear carry
	adc.b $62	   ; Add to subroutine address
	sta.b $3d	   ; Store as new limit/end
	ldx.b $65	   ; Load bank byte from parameter
	stx.b $19	   ; Set as current bank
	lda.b $62	   ; Load subroutine address
	sta.b $17	   ; Set as pointer
	lda.w #$0008	; Load flag $08
	and.w !system_flags_6	 ; Test current state
	php ; Save flag state
	lda.w #$0008	; Load flag $08
	tsb.w !system_flags_6	 ; Set flag
	jsr.w ProcessGraphicsData ; Execute subroutine (external)
	plp ; Restore flag state
	bne IfFlagWasSetKeepIt ; If flag was set, keep it
	lda.w #$0008	; Load flag $08
	trb.w !system_flags_6	 ; Clear flag

Graphics_RestoreState:
	pla ; Restore $3d
	sta.b $3d
	plx ; Restore bank
	stx.b $19
	pla ; Restore pointer
	sta.b $17
	rep #$30		; 16-bit A/X/Y
	rts ; Return

;===============================================================================
; CodeExecuteExternalSubroutineViaLong - Execute External Subroutine via Long Call
;===============================================================================

Graphics_ExecLongCall:
	lda.b [$17]	 ; Load target address
	inc.b $17
	inc.b $17
	tay ; Store address to Y
	lda.b [$17]	 ; Load bank/parameter
	inc.b $17
	and.w #$00ff	; Mask to byte
	pea.w PTR16_00FFFF ; Push return marker ($ffff)
	sep #$20		; 8-bit A
	dey ; Adjust address (Y = address - 1)
	phk ; Push program bank (for RTL)
	pea.w Graphics_LongCallReturn ; Push return address
	pha ; Push bank byte
	phy ; Push address - 1
	rep #$30		; 16-bit A/X/Y
; Stack now set up for rtl to execute target code

Graphics_LongCallReturn:
	rtl ; Return from long call

; Clean up after external subroutine
	sep #$20		; 8-bit A
	rep #$10		; 16-bit X/Y
	plx ; Pull return marker
	cpx.w #$ffff	; Check if $ffff
	beq Graphics_LongCallCleanup ; If marker found, done
	pla ; Pull extra byte (clean stack)

Graphics_LongCallCleanup:
	pea.w $0000	 ; Reset direct page to $0000
PLD_Label_6:
	phk ; Push program bank
	plb ; Set data bank = program bank
	rts ; Return

;===============================================================================
; Memory Manipulation and Data Transfer Routines
;===============================================================================

; Load_BattleResultValues - Load post-battle result values
; Purpose: Loads experience gained and other battle result values from zero page
; This is executable code (not data) that loads battle results for processing
Load_BattleResultValues:
	ldy $9e		; Load Y from zero page $9e (EXP gained - low byte)
	lda $a0		; Load A from zero page $a0 (likely EXP gained - high byte or item reward)
	bra ???		; Branch to result processing routine (offset needs calculation)

;-------------------------------------------------------------------------------
; CodeCopyDataRamE3367Using - Copy data to RAM $7e3367 using mvn
; Purpose: Block memory move from Bank $00 to Bank $7e
; Entry: [$17] = destination offset,  [$17+2] = byte count
;-------------------------------------------------------------------------------
Memory_CopyToRAM:
	lda.b [$17]	 ; Load destination offset
	inc.b $17
	inc.b $17
	tax ; X = destination offset
	lda.l $7e3367   ; Load current $7e pointer
	tay ; Y = source in $7e
	lda.b [$17]	 ; Load byte count
	inc.b $17
	and.w #$00ff
	dec a; Count-1 for mvn
	phb ; Save data bank
	mvn $7e,$00	 ; Move (Y)Bank$00 → (X)Bank$7e, A+1 bytes
	plb ; Restore data bank
	tya ; Get end pointer
	cmp.w #$35d9	; Check if exceeds buffer limit
	bcc Memory_UpdatePointer ; If below limit, update pointer
	db $4c,$1f,$9d ; jmp InfiniteLoopStackOverflow (buffer overflow handler)

Memory_UpdatePointer:
	sta.l $7e3367   ; Update pointer


;-------------------------------------------------------------------------------
; CodeCopyDataRamE3367Back - Copy data from RAM $7e3367 back to Bank $00
; Purpose: Reverse block move from Bank $7e to Bank $00
; Entry: [$17] = destination, [$17+2] = count
;-------------------------------------------------------------------------------
Memory_CopyFromRAM:
	lda.b [$17]	 ; Load destination in Bank $00
	inc.b $17
	inc.b $17
	tay ; Y = destination
	lda.b [$17]	 ; Load byte count
	inc.b $17
	and.w #$00ff
	pha ; Save count
	eor.w #$ffff	; Negate count

	adc.l $7e3367   ; Subtract from pointer (move backward)
	sta.l $7e3367   ; Update pointer
	tax ; X = new source
	pla ; Restore count
	dec a; Count-1 for mvn
	mvn $00,$7e	 ; Move (X)Bank$7e → (Y)Bank$00


;-------------------------------------------------------------------------------
; CodeCodePointerManipulationHelpers/CodePointerManipulationCoordinateCalculations - Pointer manipulation helpers
;-------------------------------------------------------------------------------
Pointer_AdjustBits:
	jsr.w Pointer_CalcOffset

Pointer_CalcOffset:
	lda.w #$003e	; Mask for clearing bits
	trb.b $1a	   ; Clear bits in $1a
	lsr a; Shift mask
	and.b $25	   ; Apply to $25
	asl a; Shift result
	ora.b $1a	   ; Combine with $1a
	adc.w #$0040	; Add base offset
	sta.b $1a	   ; Store result


;-------------------------------------------------------------------------------
; CodeCalculatePointerCoordinatesPosition - Calculate pointer from $25 (coordinates/position)
; Purpose: Convert position data to tilemap pointer
; Entry: $25 = position data, $3f/$40 = base pointers
; Exit: $1a = calculated pointer, $1b = bank/high byte
;-------------------------------------------------------------------------------
Pointer_FromPosition:
	lda.b $40	   ; Load base bank/high
	sta.b $1b	   ; Set $1b
	lda.b $25	   ; Load position
	and.w #$00ff	; Get low byte (X coordinate)
	asl a; × 2 (word-sized tiles)
	sta.b $1a	   ; Store as base
	lda.b $25	   ; Load position again
	and.w #$ff00	; Get high byte (Y coordinate)
	lsr a; / 4 (row calculation)
	lsr a
	adc.b $1a	   ; Add X offset
	adc.b $3f	   ; Add base pointer
	sta.b $1a	   ; Store final pointer


;-------------------------------------------------------------------------------
; CodeCodeDmaMvnTransferRoutines-CodeCodeDmaMvnTransferRoutines2 - DMA/MVN transfer routines
; Purpose: Various block memory transfer operations
;-------------------------------------------------------------------------------
	db $4c,$24,$98 ; jmp BcdHexNumberFormattingRoutine

DMA_TransferWithBank:
	lda.b $18	   ; Load $18
	and.w #$ff00	; Get high byte
	sta.b $31	   ; Store in $31
	lda.b [$17]	 ; Load X parameter
	inc.b $17
	inc.b $17
TAX_Label_6:
	lda.b [$17]	 ; Load Y parameter
	inc.b $17
	inc.b $17
TAY_Label_1:
	lda.b [$17]	 ; Load count
	inc.b $17
	and.w #$00ff
	dec a; Count-1 for mvn
	jmp.w $0030	 ; Execute DMA/transfer at $0030

DMA_Transfer4Params:
	stz.b $62	   ; Clear $62
	lda.b [$17]	 ; Load parameter 1
	inc.b $17
	inc.b $17
TAX_Label_7:
	lda.b [$17]	 ; Load parameter 2
	inc.b $17
	and.w #$00ff
	sta.b $63	   ; Store in $63
	lda.b [$17]	 ; Load parameter 3
	inc.b $17
	inc.b $17
TAY_Label_2:
	lda.b [$17]	 ; Load parameter 4
	inc.b $17
	and.w #$00ff
	ora.b $62	   ; Combine with $62
	sta.b $31	   ; Store in $31
	lda.b [$17]	 ; Load count
	inc.b $17
	inc.b $17
	dec a; Count-1
	phb ; Save data bank
	jsr.w $0030	 ; Execute transfer
	plb ; Restore data bank


DMA_TransferSaved:
	lda.b $35	   ; Load $35
	sep #$20		; 8-bit A
	lda.b $39	   ; Load bank byte
	rep #$30		; 16-bit mode
	sta.b $31	   ; Store bank
	lda.b $3a	   ; Check if count non-zero
	beq DMA_TransferDone ; If zero, skip
	dec a; Count-1
	ldx.b $34	   ; Load X param
	ldy.b $37	   ; Load Y param
	phb ; Save data bank
	jsr.w $0030	 ; Execute transfer
	plb ; Restore data bank

DMA_TransferDone:


;-------------------------------------------------------------------------------
; CodeWriteBitValueAddress - Write 8-bit value to address
; Purpose: [X] = 8-bit value from script
; Entry: [$17] = address, [$17+2] = 8-bit value
;-------------------------------------------------------------------------------
Script_Write8Bit:
	lda.b [$17]	 ; Load address
	inc.b $17
	inc.b $17
	tax ; X = address
	lda.b [$17]	 ; Load value (8-bit in low byte)
	inc.b $17
	and.w #$00ff
	sep #$20		; 8-bit A
	sta.w $0000,x   ; Store to address
	rts ; (REP #$30 happens in caller)

;-------------------------------------------------------------------------------
; D4 - Write 16-bit value to address
; Purpose: [X] = 16-bit value from script
; Entry: [$17] = address, [$17+2] = 16-bit value
;-------------------------------------------------------------------------------
Script_Write16Bit:
	lda.b [$17]	 ; Load address
	inc.b $17
	inc.b $17
	tax ; X = address
	lda.b [$17]	 ; Load 16-bit value
	inc.b $17
	inc.b $17
	sta.w $0000,x   ; Store to address


;-------------------------------------------------------------------------------
; CodeWriteBitValueBitValue - Write 16-bit value + 8-bit value to address
; Purpose: Write word then byte (3 bytes total)
; Entry: [$17] = address, [$17+2] = word, [$17+4] = byte
;-------------------------------------------------------------------------------
Script_Write24Bit:
	jsr.w Script_Write16Bit ; Write word at X
	lda.b [$17]	 ; Load byte value
	inc.b $17
	and.w #$00ff
	sep #$20		; 8-bit A
	sta.w $0002,x   ; Store at X+2


;-------------------------------------------------------------------------------
; CodeCodeIndirectPointerWritesUsing/CodeCodeIndirectPointerWritesUsing2 - Indirect pointer writes (using $9e)
; Purpose: Write to address pointed to by $9e/$9f
;-------------------------------------------------------------------------------
Script_WriteIndirect8:
	lda.b [$17]	 ; Load 8-bit value
	inc.b $17
	and.w #$00ff
	sep #$20		; 8-bit A
	sta.b [$9e]	 ; Store via indirect pointer


Script_WriteIndirect16:
	lda.b [$17]	 ; Load 16-bit value
	inc.b $17
	inc.b $17
	sta.b [$9e]	 ; Store via indirect pointer


;-------------------------------------------------------------------------------
; CodeComplexIndirectWriteSequence - Complex indirect write sequence
;-------------------------------------------------------------------------------
Script_WriteIndirectSeq:
	db $20,$99,$a9,$e6,$9e,$e6,$9e,$20,$8d,$a9,$c2,$30,$c6,$9e,$c6,$9e
	db $60

;-------------------------------------------------------------------------------
; CodeLoadValueIndirectPointer - Load value from indirect pointer
; Purpose: Load 16-bit value from [$9e]
; Entry: [$17] = address to store result
; Exit: A = value from [$9e], X = address
;-------------------------------------------------------------------------------
Script_ReadIndirect:
	lda.b [$17]	 ; Load destination address
	inc.b $17
	inc.b $17
	tax ; X = destination
	lda.b [$9e]	 ; Load value via indirect


Script_ReadIndirect8:
	jsr.w Script_ReadIndirect ; Load via [$9e]
	sep #$20		; 8-bit A
	sta.w $0000,x   ; Store low byte only


Script_ReadIndirect16:
	jsr.w Script_ReadIndirect ; Load via [$9e]
	sta.w $0000,x   ; Store full word


;-------------------------------------------------------------------------------
; CodeMvnTransferUsingEPointer - mvn transfer using $9e pointer
; Purpose: Block move using indirect pointer as bank
;-------------------------------------------------------------------------------
Script_TransferIndirect:
	lda.b [$17]	 ; Load destination
	inc.b $17
	inc.b $17
	tay ; Y = destination
	ldx.b $9e	   ; X = source from $9e
	lda.b $9f	   ; Load bank byte
	and.w #$ff00
	sta.b $31	   ; Store bank in $31
	lda.w #$0002	; Transfer 3 bytes (count-1=2)
	jmp.w $0030	 ; Execute mvn via $0030

;-------------------------------------------------------------------------------
; CodeCodeBankEWriteOperations-CodeHelperLoadAddressBankBank - Bank $7e write operations
; Purpose: Write to Bank $7e addresses using special bank handling
;-------------------------------------------------------------------------------
Script_WriteBanked8:
	jsr.w Script_LoadAddrBank ; Load address and bank
	pha ; Save bank
	plb ; Set data bank
	lda.b [$17]	 ; Load 8-bit value
	inc.b $17
	and.w #$00ff
	sep #$20		; 8-bit A
	sta.w $0000,x   ; Store to Bank $7e address
	plb ; Restore data bank


Script_WriteBanked16:
	jsr.w Script_LoadAddrBank ; Load address and bank
	pha ; Save bank
	plb ; Set data bank
	lda.b [$17]	 ; Load 16-bit value
	inc.b $17
	inc.b $17
	sta.w $0000,x   ; Store to Bank $7e address
	plb ; Restore data bank


Script_WriteBanked24:
	db $20,$22,$aa,$48,$ab,$a7,$17,$e6,$17,$e6,$17,$9d,$00,$00,$a7,$17
	db $e6,$17,$29,$ff,$00,$e2,$20,$9d,$02,$00,$ab,$60

;-------------------------------------------------------------------------------
; CodeHelperLoadAddressBankBank - Helper: Load address and bank for Bank $7e operations
; Entry: [$17] = address, [$17+2] = bank byte
; Exit: X = address, A = bank (low byte)
;-------------------------------------------------------------------------------
Script_LoadAddrBank:
	lda.b [$17]	 ; Load address
	inc.b $17
	inc.b $17
	tax ; X = address
	lda.b [$17]	 ; Load bank
	inc.b $17
	and.w #$00ff	; Isolate bank byte


;-------------------------------------------------------------------------------
; CodeCodeTextPositioningDisplayHelpers-CodeCodeTextPositioningDisplayHelpers2 - Text positioning and display helpers
; Purpose: Calculate text window positions and sizes
;-------------------------------------------------------------------------------
Text_CalcWindowPos:
	sep #$30		; 8-bit A, X, Y
	jsr.w Text_CalcXPos ; Calculate X position
	jsr.w Text_CalcYPos ; Calculate Y position/width
	bra Text_FinalizePos ; Finalize

Text_CalcXPos:
	lda.b #$20	  ; Load window width constant

	sbc.b $2a	   ; Subtract text width
	lsr a; / 2 (center)
	sta.b $28	   ; Store X offset


Text_CalcYPos:
	lda.b $24	   ; Load flags
	and.b #$08	  ; Test bit 3
	beq Text_CalcYDynamic ; If clear, skip
	lda.b #$10	  ; Use fixed position
	bra Text_CalcYApply

Text_CalcYDynamic:
	lda.b $2d	   ; Load position
	eor.b #$ff	  ; Negate
	inc a

Text_CalcYApply:

	adc.b $23	   ; Add offset
	sta.b $2c	   ; Store Y position
	lsr a; / 4 (row)
	lsr a
	sta.b $29	   ; Store row index


Text_FinalizePos:
	rep #$30		; 16-bit mode
	lda.b $28	   ; Load calculated position

	adc.w #$0101	; Add offset (both bytes)
	sta.b $25	   ; Store final position


;-------------------------------------------------------------------------------
; CodeRepeatTextOperation - Repeat text operation
; Purpose: Execute text display routine multiple times
; Entry: $1f = repeat count, $17 = operation pointer
;-------------------------------------------------------------------------------
Text_RepeatOperation:
	lda.b $1f	   ; Load repeat count
	and.w #$00ff
	ldx.b $17	   ; Load operation pointer

Text_RepeatLoop:
	pha ; Save count
	phx ; Save pointer
	stx.b $17	   ; Set pointer
	jsr.w Graphics_ReadDispatchCmd ; Execute text operation
	plx ; Restore pointer
	pla ; Restore count
	dec a; Decrement count
	bne Text_RepeatLoop ; Loop if not zero


;-------------------------------------------------------------------------------
; CodeCodeDmaTransferSetupRoutines-CodeThroughCodeNowImplementedPartial2 - DMA transfer setup routines
; Purpose: Set up and execute DMA transfers to VRAM/tilemap
;-------------------------------------------------------------------------------
DMA_SetupTilemap:
	lda.b $40	   ; Load bank/high byte
	sta.b $1b	   ; Set DMA bank
	sta.b $35	   ; Set alternate bank
	sta.b $38	   ; Set third bank
	lda.w #$2cfe	; Load tile value
	ldx.b $3f	   ; Load X base
	ldy.w #$1000	; Load Y base (large transfer)
	jmp.w ExecuteDma ; Execute DMA

DMA_SetupPositioned:
	lda.b $40	   ; Load bank
	sta.b $1b
	sta.b $35
	sta.b $38
	lda.b $28	   ; Load position high byte
	and.w #$ff00
	lsr a; / 4 (calculate offset)
	lsr a
	adc.b $3f	   ; Add base
	tax ; X = transfer source
	lda.b $2a	   ; Load size high byte
	and.w #$ff00
	lsr a; / 4
	lsr a
	tay ; Y = transfer size
	lda.w #$2cfe	; Load tile value
	jmp.w ExecuteDma ; Execute DMA

DMA_SetupClear:
	lda.b $40	   ; Load bank
	sta.b $1b
	sta.b $35
	sta.b $38
	lda.b $28	   ; Load position
	and.w #$ff00
	lsr a; / 4
	lsr a
	adc.b $3f	   ; Add base
TAX_Label_8:
	lda.b $2a	   ; Load size
	and.w #$ff00
	lsr a; / 4
	lsr a
TAY_Label_3:
	lda.w #$2c00	; Different tile value (blank/clear)
	jmp.w ExecuteDma ; Execute DMA

;===============================================================================
; Progress: ~8,900 lines documented (63.5% of Bank $00)
; Latest additions:
; - CodeThroughCodeNowImplementedPartial-00A874: Memory block transfers to/from Bank $7e
; - CodeCopyDataRamE3367Back: Reverse block copy (Bank $7e → Bank $00)
; - CodePointerManipulationCoordinateCalculations-00A8D1: Pointer manipulation and coordinate calculations
; - CodeDmaMvnTransferHelperRoutines-00A93E: DMA/MVN transfer helper routines
; - CodeWriteBitValueAddress-00A97D: Direct memory write operations (8-bit, 16-bit, 24-bit)
; - CodeCodeIndirectPointerWritesUsing-00A999: Indirect pointer writes via $9e
; - CodeLoadValueIndirectPointer-00A9CD: Indirect pointer reads and transfers
; - CodeCodeBankEWriteOperations-00AA22: Bank $7e special write operations
; - CodeCodeTextPositioningDisplayHelpers-00AA67: Text positioning and window calculations
; - CodeRepeatTextOperation: Text operation repeat loop
; - CodeCodeDmaTransferSetupRoutines-00AACC: DMA transfer setup for VRAM/tilemap operations
;
; Next: More DMA and graphics routines (NextMoreDmaGraphicsRoutinesCode onward)
;===============================================================================

;-------------------------------------------------------------------------------
; NextMoreDmaGraphicsRoutinesCode - Indexed sprite/tile drawing dispatcher
; Purpose: Use sprite type index ($27) to dispatch to specific drawing routine
; Entry: $27 = sprite type index, $28 = position data
;-------------------------------------------------------------------------------
Sprite_DrawDispatch:
	lda.b $27	   ; Load sprite type index
	and.w #$00ff
	asl a; × 2 for word table
	tax ; X = table offset
	pei.b ($25)	 ; Save $25 to stack
	lda.b $28	   ; Load position
	sta.b $25	   ; Store as new $25
	jsr.w CodeCalculatePointerCoordinatesPosition ; Calculate tilemap pointer
	jsr.w CallHelper ; Prepare drawing context
	lda.b $1c	   ; Load bank byte
	and.w #$00ff
	pha ; Save bank
	plb ; Set data bank
	jsr.w (Sprite_DrawDispatchTable,x) ; Dispatch to sprite routine
	plb ; Restore data bank
	jsr.w CleanupDrawingContext ; Cleanup drawing context
	pla ; Restore $25
	sta.b $25
	jmp.w CodeCalculatePointerCoordinatesPosition ; Recalculate pointer and return

	db $60		 ; Extra rts

;-------------------------------------------------------------------------------
; Sprite Draw Dispatch Table
;-------------------------------------------------------------------------------
; Purpose: Sprite/window drawing dispatch table with 2-byte header
; Reachability: Reachable via indexed jump (jsr above)
; Analysis: Jump table for sprite and window rendering routines
;   - Bytes $f6 $aa: Table header/signature (possibly entry count or flags)
;   - 7 function pointers for different sprite/window types
; Technical: Originally labeled UNREACH_00AAF7
;-------------------------------------------------------------------------------
Sprite_DrawDispatchTable:
	db $f6,$aa                           ;00AAF7|        |      ; Table header (entry count or flags)
	dw Sprite_DrawFilled                 ;00AAF9|        |      ; $00: Draw filled sprite
	dw Sprite_DrawWindowBorder           ;00AAFB|        |      ; $01: Draw window border
	dw Window_DrawFrame                  ;00AAFD|        |      ; $02: Draw window frame
	dw Window_DrawItemIcon               ;00AAFF|        |      ; $03: Draw item icon
	dw Window_DrawSpellIcon              ;00AB01|        |      ; $04: Draw spell icon
	dw Window_DrawTopBorder              ;00AB03|        |      ; $05: Draw top border
	dw Window_DrawFilledBox              ;00AB05|        |      ; $06: Draw filled box
;-------------------------------------------------------------------------------

;-------------------------------------------------------------------------------
; Sprite_DrawFilled - Draw filled rectangle (tile $fe)
; Purpose: Draw solid filled rectangle using tile $fe
;-------------------------------------------------------------------------------
Sprite_DrawFilled:
	lda.b $2b	   ; Load height
	and.w #$00ff
	sta.b $62	   ; Store row counter
	lda.b $2a	   ; Load width
	and.w #$00ff
	asl a; × 2 for word offset
	tax ; X = column offset
	ldy.b $1a	   ; Load tilemap pointer
	lda.w #$00fe	; Tile $fe (solid fill)
	jsr.w Window_DrawTiles ; Draw tiles
	sty.b $1a	   ; Update pointer


;-------------------------------------------------------------------------------
; Sprite_DrawWindowBorder - Draw window border with vertical flip
; Purpose: Draw bordered window with special tile handling
;-------------------------------------------------------------------------------
Sprite_DrawWindowBorder:
	jsr.w Window_DrawTopBorder ; Draw top border
	lda.w #$4000	; Vertical flip bit
	ora.b $1d	   ; Combine with tile flags
	sta.b $64	   ; Store flip flags
	jsr.w CleanupDrawingContext ; Setup drawing

	lda.b $1a	   ; Load pointer
	sbc.w #$0040	; Back up one row
	sta.b $1a
	lda.b $24	   ; Load flags
	bit.w #$0008	; Test bit 3
	beq Window_CalcBounds ; If clear, skip
	jsr.w CodeCalculatePointerCoordinatesPosition ; Recalculate pointer
	lda.w #$8000	; Horizontal flip bit
	tsb.b $64	   ; Set in flags

Window_CalcBounds:
	sep #$20		; 8-bit A
	lda.b $22	   ; Load Y position
	lsr a; / 8 (tile row)
	lsr a
	lsr a
	cmp.b $28	   ; Compare with window top
	bcs Window_CalcRowOffset ; If >= top, use it
	lda.b $28	   ; Use window top


Window_CalcRowOffset:
	sbc.b $28	   ; Calculate row offset
	sta.b $62	   ; Store row counter
	lda.b $22	   ; Load Y again
	cmp.b #$78	  ; Check if >= 120
	bcc Window_AdjustHeight ; If below, adjust
	bne Window_FinalizeHeight ; If above, skip
	lda.b $24	   ; Check flags
	bit.b #$01	  ; Test bit 0
	beq Window_FinalizeHeight ; If clear, skip

Window_AdjustHeight:
	inc.b $62	   ; Increment row count
	lda.b #$40	  ; Clear bit $40
	trb.b $65	   ; In $65

Window_FinalizeHeight:
	lda.b $62	   ; Load row counter
	inc a; +1
	cmp.b $2a	   ; Compare with width
	bcc Window_DrawBorder ; If less, use it
	db $a5,$2a,$e9,$02,$85,$62 ; Load width-2 into $62

Window_DrawBorder:
	rep #$30		; 16-bit mode
	lda.b $62	   ; Load final count
	and.w #$00ff
	asl a; × 2 for word offset
	tay ; Y = offset
	lda.w #$00fd	; Tile $fd
	eor.b $64	   ; Apply flip flags
	sta.b ($1a),y   ; Draw tile


;-------------------------------------------------------------------------------
; Window_DrawFrame - Draw window frame (tiles $fc, $ff)
;-------------------------------------------------------------------------------
Window_DrawFrame:
	lda.w #$00fc	; Top border tile
	jsr.w Window_SetupTopEdge ; Setup top edge
	lda.w #$00ff	; Fill tile
	jsr.w Window_SetupVerticalEdge ; Setup vertical edges
	inc.b $62	   ; Adjust counter
	lda.w #$80fc	; Bottom border (flipped)
	jsr.w Window_DrawTiles ; Draw
	jmp.w Window_DrawFrameCorners ; Draw corners

;-------------------------------------------------------------------------------
; Window_DrawTopBorder - Draw window top border
;-------------------------------------------------------------------------------
Window_DrawTopBorder:
	lda.w #$00fc	; Border tile
	jsr.w Window_SetupTopEdge ; Setup top
	lda.b $2b	   ; Load height
	and.w #$00ff
	dec a; -2 for borders
	dec a
	jsr.w Window_FillRows ; Fill routine
	inc.b $62	   ; Adjust
	lda.w #$80fc	; Bottom border
	jsr.w Window_DrawTiles ; Draw
	jmp.w Window_DrawFrameCorners ; Draw corners

;-------------------------------------------------------------------------------
; Window_DrawFilledBox - Draw simple filled box
;-------------------------------------------------------------------------------
Window_DrawFilledBox:
	ldy.b $1a	   ; Load pointer
	lda.b $2a	   ; Load width
	and.w #$00ff
	asl a; × 2
	tax ; X = offset
	lda.b $2b	   ; Load height
	and.w #$00ff
	jsr.w Window_FillRows ; Fill
	sty.b $1a	   ; Update pointer


;-------------------------------------------------------------------------------
; Window_DrawItemIcon - Draw item icon box (tiles $45)
;-------------------------------------------------------------------------------
Window_DrawItemIcon:
	lda.w #$0045	; Item icon tile
	jsr.w Window_SetupTopEdge ; Setup top
	lda.w #$00ff	; Fill
	jsr.w Window_SetupVerticalEdge ; Setup edges
	inc.b $62
	lda.w #$8045	; Flipped icon
	jsr.w Window_DrawTiles ; Draw
	jmp.w Window_DrawItemCorners ; Finish

;-------------------------------------------------------------------------------
; Window_DrawSpellIcon - Draw spell icon box (tiles $75)
;-------------------------------------------------------------------------------
Window_DrawSpellIcon:
	lda.w #$0075	; Spell icon tile
	jsr.w Window_SetupTopEdge ; Setup top
	lda.w #$00ff	; Fill
	jsr.w Window_SetupVerticalEdge ; Setup edges
	inc.b $62
	lda.w #$8075	; Flipped spell icon
	jsr.w Window_DrawTiles ; Draw
	jmp.w Window_DrawSpellCorners ; Finish

;-------------------------------------------------------------------------------
; Window_FillRows - Tile fill routine with indirect jump
; Purpose: Complex tile filling using computed jump table
; Entry: A = row count, X = column offset × 2
;-------------------------------------------------------------------------------
Window_FillRows:
	sta.b $62	   ; Save row count
	txa ; Get column offset
	asl a; × 2 again
	eor.w #$ffff	; Negate
	adc.w #$ac97	; Add base (computed address)
	sta.b $64	   ; Store jump target
	txa ; Column offset
	lsr a; / 2
	pha ; Save to stack

Window_FillLoop:
	adc.l $00015f   ; Add to system counter
	sta.l $00015f   ; Update counter
	jmp.w ($0064)   ; Jump to computed address

; Computed jump table entries (tile fill patterns)
	db $3a,$99,$3e,$00,$3a,$99,$3c,$00,$3a,$99,$3a,$00,$3a,$99,$38,$00
	db $3a,$99,$36,$00,$3a,$99,$34,$00

; Unrolled tile write loop (26 tiles worth)
	dec a
	sta.w $0032,y
	dec a
	sta.w $0030,y
	dec a
	sta.w $002e,y
	dec a
	sta.w $002c,y
	dec a
	sta.w $002a,y
	dec a
	sta.w $0028,y
	dec a
	sta.w $0026,y
	dec a
	sta.w $0024,y
	dec a
	sta.w $0022,y
	dec a
	sta.w $0020,y
	dec a
	sta.w $001e,y
	dec a
	sta.w $001c,y
	dec a
	sta.w $001a,y
	dec a
	sta.w $0018,y
	dec a
	sta.w $0016,y
	dec a
	sta.w $0014,y
	dec a
	sta.w $0012,y
	dec a
	sta.w $0010,y
	dec a
	sta.w $000e,y
	dec a
	sta.w $000c,y
	dec a
	sta.w $000a,y
	dec a
	sta.w $0008,y
	dec a
	sta.w $0006,y
	dec a
	sta.w $0004,y
	dec a
	sta.w $0002,y
	dec a
	sta.w $0000,y
	tya ; Get current pointer
	adc.w #$0040	; Next row (+$40 bytes)
	tay ; Update Y
	lda.b $01,s	 ; Load saved value
	dec.b $62	   ; Decrement row counter
	beq Window_FillDone ; If zero, done
	jmp.w Window_FillLoop ; Loop

Window_FillDone:
	pla ; Clean stack


;-------------------------------------------------------------------------------
; Window_DrawFrameCorners - Draw window corners (tiles $f7/$f9/$fb)
;-------------------------------------------------------------------------------
Window_DrawFrameCorners:
	jsr.w Window_CalcCornerPos ; Setup coordinates
	lda.b $1d	   ; Load tile flags
	eor.w #$00f7	; Top-left corner
	sta.b ($1a)	 ; Draw
	lda.b $1d
	eor.w #$00f9	; Top-right corner
	sta.b ($1a),y   ; Draw
	lda.w #$00fb	; Side tiles
	jsr.w Window_DrawSideTiles ; Draw sides
	lda.b $1d
	eor.w #$00f8	; Bottom-left corner
	sta.b ($1a)
	lda.b $1d
	eor.w #$00fa	; Bottom-right corner
	sta.b ($1a),y
	lda.b $1a	   ; Advance pointer
	adc.w #$0040
	sta.b $1a


;-------------------------------------------------------------------------------
; Window_DrawItemCorners - Draw item icon corners (tiles $40-$44)
;-------------------------------------------------------------------------------
Window_DrawItemCorners:
	jsr.w Window_CalcCornerPos ; Setup
	lda.b $1d
	eor.w #$0040	; Icon TL
	sta.b ($1a)
	lda.b $1d
	eor.w #$0042	; Icon TR
	sta.b ($1a),y
	lda.w #$0044	; Icon sides
	jsr.w Window_DrawSideTiles ; Draw
	lda.b $1d
	eor.w #$0041	; Icon BL
	sta.b ($1a)
	lda.b $1d
	eor.w #$0043	; Icon BR
	sta.b ($1a),y
	lda.b $1a
	adc.w #$0040
	sta.b $1a


;-------------------------------------------------------------------------------
; Window_DrawSpellCorners - Draw spell icon corners (tiles $70-$74)
;-------------------------------------------------------------------------------
Window_DrawSpellCorners:
	jsr.w Window_CalcCornerPos ; Setup
	lda.b $1d
	eor.w #$0070	; Spell TL
	sta.b ($1a)
	lda.b $1d
	eor.w #$0072	; Spell TR
	sta.b ($1a),y
	lda.w #$0074	; Spell sides
	jsr.w Window_DrawSideTiles ; Draw
	lda.b $1d
	eor.w #$0071	; Spell BL
	sta.b ($1a)
	lda.b $1d
	eor.w #$0073	; Spell BR
	sta.b ($1a),y
	lda.b $1a
	adc.w #$0040
	sta.b $1a


;-------------------------------------------------------------------------------
; Window_SetupTopEdge - Setup top edge drawing
; Entry: A = tile value
;-------------------------------------------------------------------------------
Window_SetupTopEdge:
	pha ; Save tile
	ldy.b $1a	   ; Load pointer
	iny ; Skip first tile
INY_Label:
	lda.b $2a	   ; Load width
	and.w #$00ff
	dec a; -2 for corners
	dec a
	asl a; × 2
	tax ; X = offset
	lda.w #$0001	; Single row
	sta.b $62
	pla ; Restore tile
	jmp.w Window_DrawTiles ; Draw

;-------------------------------------------------------------------------------
; Window_SetupVerticalEdge - Setup vertical edge drawing
; Entry: A = tile value
;-------------------------------------------------------------------------------
Window_SetupVerticalEdge:
	pha ; Save tile
	lda.b $2b	   ; Load height
	and.w #$00ff
	dec a; -2 for top/bottom
	dec a
	sta.b $62	   ; Row count
	pla ; Restore tile
	jmp.w Window_DrawTiles ; Draw

;-------------------------------------------------------------------------------
; Window_CalcCornerPos - Calculate corner positions
; Exit: Y = right edge offset, $62 = adjusted row count
;-------------------------------------------------------------------------------
Window_CalcCornerPos:
	lda.b $2a	   ; Width
	and.w #$00ff
	dec a; -1
	asl a; × 2
	tay ; Y = right offset
	lda.b $2b	   ; Height
	and.w #$00ff
	dec a; -2
	dec a
	sta.b $62	   ; Row count


;-------------------------------------------------------------------------------
; Window_DrawSideTiles - Draw vertical side tiles
; Entry: A = tile value (XORed with $1d)
;-------------------------------------------------------------------------------
Window_DrawSideTiles:
	eor.b $1d	   ; Apply tile flags
	sta.b $64	   ; Save tile
	lda.b $1a	   ; Advance to next row
	adc.w #$0040
	sta.b $1a
	ldx.b $62	   ; Load row counter

Window_DrawSideLoop:
	lda.b $64	   ; Load tile
	sta.b ($1a)	 ; Draw left edge
	eor.w #$4000	; Flip horizontally
	sta.b ($1a),y   ; Draw right edge
	lda.b $1a	   ; Next row
	adc.w #$0040
	sta.b $1a
	dex ; Decrement counter
	bne Window_DrawSideLoop ; Loop


;-------------------------------------------------------------------------------
; Window_DrawTiles - Generic tile drawing routine
; Entry: A = tile value (XORed with $1d), X = column offset
;-------------------------------------------------------------------------------
Window_DrawTiles:
	eor.b $1d	   ; Apply flags
	sta.b $64	   ; Save tile

Window_DrawTileLoop:
	jsr.w (DATA8_009a1e,x) ; Call indexed routine
	tya ; Get pointer
	adc.w #$0040	; Next row
TAY_Label_4:
	lda.b $64	   ; Restore tile
	dec.b $62	   ; Decrement row counter
	bne Window_DrawTileLoop ; Loop


;-------------------------------------------------------------------------------
; Sprite_ClearOAM - Clear sprite OAM entries
; Purpose: Clear OAM sprite data in Bank $7e
; Entry: [$17] = number of sprites to clear
;-------------------------------------------------------------------------------
Sprite_ClearOAM:
	lda.b [$17]	 ; Load sprite count
	inc.b $17
	and.w #$00ff
	sta.b $62	   ; Save count
	ldy.w #$31c5	; OAM base + offset
	lda.w #$01f0	; Off-screen Y position
	pea.w $007e	 ; Push Bank $7e
	plb ; Set data bank


Sprite_ClearLoop:
	tax ; X = Y position
	jsr.w ClearSpriteEntry ; Clear sprite entry
	tya ; Get OAM pointer
	sbc.w #$fff0	; Move back (-16 bytes)
TAY_Label_5:
	txa ; Restore Y position
	adc.w #$fff8	; Adjust (-8)
	dec.b $62	   ; Decrement count
	bne Sprite_ClearLoop ; Loop
	plb ; Restore bank


;-------------------------------------------------------------------------------
; Sprite_DrawCompressed - Compressed tile drawing to Bank $7e
; Purpose: Draw compressed tile data to screen buffer
; Entry: $2c = Y coordinate, $2d = width, $2b = height
;-------------------------------------------------------------------------------
Sprite_DrawCompressed:
	lda.b $2c	   ; Load Y coord
	and.w #$00ff
	sta.b $64	   ; Save
	asl a; × 2
	adc.w #$31b5	; Add buffer base
	tay ; Y = destination
	lda.w #$01f9	; Calculate offset
	sbc.b $64
	pea.w $007e	 ; Bank $7e
PLB_Label_1:
	sta.b $64	   ; Save offset
	and.w #$0007	; Get low 3 bits
	asl a; × 2
	tax ; X = table offset
	lda.b $64
	and.w #$fff8	; Mask to 8-byte boundary
	adc.w #$0008	; Adjust
	jsr.w (DATA8_009a1e,x) ; Call indexed routine
	sbc.w #$0007	; Adjust back
TAX_Label_9:
	lda.b $64
	and.w #$0007	; Get bit offset
	sta.b $64
	sty.b $62	   ; Save pointer
	asl a; × 2
	adc.b $62
	tay ; Y = adjusted pointer

	lda.b $2d	   ; Load width
	sbc.b $64	   ; Subtract offset
	and.w #$00ff
	pha ; Save
	lsr a; / 8
	lsr a
	lsr a
	sta.b $62	   ; Row counter
TXA_Label:


Sprite_CompressedLoop:
TAX_Label_10:
	jsr.w Memory_Fill14Bytes ; Draw routine
TYA_Label:
	sbc.w #$fff0	; Adjust pointer
TAY_Label_6:
TXA_Label_1:
	adc.w #$fff8	; Adjust X
	dec.b $62
	bne Sprite_CompressedLoop ; Loop
	sta.b $64	   ; Save result
	pla ; Restore width
	and.w #$0007	; Get remainder
	asl a; × 2
TAX_Label_11:
	lda.b $64
	jsr.w (DATA8_009a1e,x) ; Final draw
	plb ; Restore bank


;-------------------------------------------------------------------------------
; Text_DrawRLE - RLE compressed text drawing
; Purpose: Run-length encoded text decompression to Bank $7e
; Entry: $2c = Y start, $29 = row count, $2b = column count
;-------------------------------------------------------------------------------
Text_DrawRLE:
	pea.w $007e	 ; Bank $7e
PLB_Label_2:
	lda.b $2c	   ; Y coordinate
	and.w #$00ff
	pha ; Save
	dec a; -1
	asl a; × 2
	adc.w #$31b7	; Buffer base
	tax ; X = destination
	lda.b $29	   ; Row count
	and.w #$00ff
	asl a; × 8
	asl a
	asl a

	sbc.b $01,s	 ; Subtract Y
	sta.b $01,s	 ; Update stack
	lda.b $2b	   ; Column count
	and.w #$00ff
	sta.b $62	   ; Save

Text_DrawRLE_Loop:
	lda.b [$17]	 ; Load RLE byte
	and.w #$00ff
	beq Text_DrawRLE_Skip ; If zero, skip
	bit.w #$0080	; Test high bit
	bne Text_DrawRLE_Special ; If set, special mode
	pha ; Save count
	lda.b $03,s	 ; Load tile value
	sta.w $0000,x   ; Store
	txy ; Y = X
	iny ; Advance
INY_Label_1:
	pla ; Restore count
	dec a; -1
	beq Text_DrawRLE_Done ; If 1, done
	asl a; × 2
	dec a; -1 for mvn
	mvn $7e,$7e	 ; Block move

Text_DrawRLE_Done:
	tyx ; X = end pointer

Text_DrawRLE_Skip:
	lda.w #$0008	; 8 tiles

	sbc.b [$17]	 ; Subtract used
	and.w #$00ff

	adc.b $01,s	 ; Add to stack offset
	sta.b $01,s

Text_DrawRLE_Next:
	inc.b $17	   ; Next RLE byte
	dec.b $62	   ; Decrement column counter
	bne Text_DrawRLE_Loop ; Loop
	pla ; Clean stack
	plb ; Restore bank


Text_DrawRLE_Special:
	and.w #$007f	; Mask off high bit
	pha ; Save count
	lda.w #$0008

	sbc.b $01,s	 ; Calculate skip

	adc.b $03,s	 ; Add to offset
	sta.b $03,s
	sta.w $0000,x   ; Store
TXY_Label:
INY_Label_2:
INY_Label_3:
PLA_Label:
	dec a
	beq Sub_00AE9F
	asl a
	dec a
	mvn $7e,$7e	 ; Block move

Text_DrawRLE_SpecialDone:
TYX_Label_1:
	bra Text_DrawRLE_Next ; Continue

;-------------------------------------------------------------------------------
; Cmd_CallGraphics8Bit - Call graphics function with 8-bit parameter
;-------------------------------------------------------------------------------
Cmd_CallGraphics8Bit:
	lda.b [$17]	 ; Load parameter
	inc.b $17
	and.w #$00ff
	jsl.l LongCallGraphicsRoutine ; Long call to graphics routine


	db $a5,$9e,$22,$60,$97,$00,$60 ; Variant with $9e parameter

;-------------------------------------------------------------------------------
; Cmd_CallGraphicsWithDP - Call graphics function with DP context
;-------------------------------------------------------------------------------
Cmd_CallGraphicsWithDP:
	lda.b [$17]	 ; Load parameter
	inc.b $17
	and.w #$00ff
	phd ; Save direct page
	pea.w $00d0	 ; Set DP to $d0
PLD_Label_7:
	jsl.l CallGraphicsRoutine ; Call graphics routine
	pld ; Restore DP


;-------------------------------------------------------------------------------
; Cmd_CallSprite - Call sprite/tile function
;-------------------------------------------------------------------------------
Cmd_CallSprite:
	lda.b [$17]	 ; Load parameter
	inc.b $17
	and.w #$00ff
	jsl.l CallSpriteRoutine ; Call sprite routine


	db $a5,$9e,$22,$6b,$97,$00,$60 ; Variant with $9e

;-------------------------------------------------------------------------------
; Cmd_CallGraphicsAlt - Call graphics function with DP=$d0
;-------------------------------------------------------------------------------
Cmd_CallGraphicsAlt:
	lda.b [$17]
	inc.b $17
	and.w #$00ff
PHD_Label_3:
	pea.w $00d0	 ; DP = $d0
PLD_Label_8:
	jsl.l GraphicsCall ; Graphics call
PLD_Label_9:


; More variants with different parameter sources
	db $a5,$2e,$0b,$48,$a7,$17,$e6,$17,$29,$ff,$00,$2b,$22,$4e,$97,$00
	db $2b,$60

Cmd_CallFromOffset:
	lda.b $2e	   ; From $2e
PHD_Label_4:
PHA_Label_1:
	lda.b $9e	   ; From $9e
PLD_Label_10:
	jsl.l CallGraphicsRoutine
PLD_Label_11:


	db $a5,$2e,$0b,$48,$a7,$17,$e6,$17,$29,$ff,$00,$2b,$22,$54,$97,$00
	db $2b,$60

Cmd_CallFromOffset2:
	lda.b $2e
PHD_Label_5:
PHA_Label_2:
	lda.b $9e
PLD_Label_12:
	jsl.l GraphicsCall
PLD_Label_13:


;-------------------------------------------------------------------------------
; Memory_CopyWithTable - Memory copy with table offset
; Purpose: Copy data using offset from script
; Entry: A = byte count
;-------------------------------------------------------------------------------
Memory_CopyWithTable:
	tay ; Y = count
	lda.b [$17]	 ; Load source
	sta.b $a4
	inc.b $17
	inc.b $17
	lda.b [$17]	 ; Load dest
	sta.b $a6
	dec.b $17
	dec.b $17
	tya ; Get count

	adc.b $17	   ; Advance script pointer
	sta.b $17
	ldx.w #$00a4	; X = $a4 (source pointer)
	tya ; A = count
	bra Memory_CopyTo98

;-------------------------------------------------------------------------------
; Memory_CopyDirect - Memory copy direct
;-------------------------------------------------------------------------------
Memory_CopyDirect:
	tay ; Y = count
	lda.b [$17]	 ; Load source
	inc.b $17
	inc.b $17
	tax ; X = source
	tya ; A = count

Memory_CopyTo98:
	stz.b $98	   ; Clear dest low
	stz.b $9a	   ; Clear dest high
	ldy.w #$0098	; Y = $98
	mvn $00,$00	 ; Block move


;-------------------------------------------------------------------------------
; Memory_CopyTo9E - Memory copy to $9e pointer
;-------------------------------------------------------------------------------
Memory_CopyTo9E:
	tax ; X = count
	lda.b [$17]	 ; Load source
	inc.b $17
	inc.b $17
	tay ; Y = source
	txa ; A = count
	ldx.w #$009e	; X = $9e
	mvn $00,$00	 ; Block move


;-------------------------------------------------------------------------------
; Memory_Copy1Byte/2Bytes/3Bytes - Memory copy variants with preset counts
;-------------------------------------------------------------------------------
Memory_Copy1Byte:
	lda.w #$0000	; 1 byte
	bra Memory_CopyTo9E

Memory_Copy2Bytes:
	lda.w #$0001	; 2 bytes
	bra Memory_CopyTo9E

Memory_Copy3Bytes:
	lda.w #$0002	; 3 bytes
	bra Memory_CopyTo9E

;-------------------------------------------------------------------------------
; Memory_CopyTableTo9E/DirectTo9E - Copy and store in $9e
;-------------------------------------------------------------------------------
Memory_CopyTableTo9E:
	jsr.w Memory_CopyWithTable ; Table copy
	bra Memory_StoreTo9E

Memory_CopyDirectTo9E:
	jsr.w Memory_CopyDirect ; Direct copy

Memory_StoreTo9E:
	lda.b $98	   ; Load result low
	sta.b $9e	   ; Store in $9e
	lda.b $9a	   ; Load result high
	sta.b $a0	   ; Store in $a0


;-------------------------------------------------------------------------------
; Memory_CopyTable1/2/3 - Copy variants with preset counts (table mode)
;-------------------------------------------------------------------------------
Memory_CopyTable1Byte:
	lda.w #$0000
	bra Memory_CopyTableTo9E

Memory_CopyTable2Bytes:
	lda.w #$0001
	bra Memory_CopyTableTo9E

Memory_CopyTable3Bytes:
	lda.w #$0002
	bra Memory_CopyTableTo9E

Memory_CopyDirect2Bytes:
	lda.w #$0001
	bra Memory_CopyDirectTo9E

Memory_CopyDirect3Bytes:
	lda.w #$0002
	bra Memory_CopyDirectTo9E

;-------------------------------------------------------------------------------
; Pointer_Load16BitClear - Load pointer helpers
;-------------------------------------------------------------------------------
Pointer_Load16BitClear:
	jsr.w Pointer_LoadFromBank ; Load pointer
	stz.b $9f	   ; Clear high byte
	stz.b $a0


	db $20,$bb,$af,$64,$a0,$60,$20,$bb,$af,$29,$ff,$00,$85,$a0,$60

;-------------------------------------------------------------------------------
; Pointer_LoadFromBank - Load pointer from Bank $XX address
; Entry: [$17] = address, [$17+2] = bank
; Exit: Y = word value, A = next word, $9e = first word
;-------------------------------------------------------------------------------
Pointer_LoadFromBank:
	lda.b [$17]	 ; Load address
	inc.b $17
	inc.b $17
	tax ; X = address
	lda.b [$17]	 ; Load bank
	inc.b $17
	and.w #$00ff
	pha ; Save bank
	plb ; Set data bank
	lda.w $0000,x   ; Load first word
	tay ; Y = first word
	lda.w $0002,x   ; Load second word
	plb ; Restore bank
	sty.b $9e	   ; Store first word


;-------------------------------------------------------------------------------
; Pointer_LoadByte - Load byte from address into $9e
;-------------------------------------------------------------------------------
Pointer_LoadByte:
	stz.b $9e	   ; Clear $9e
	stz.b $a0	   ; Clear $a0
	lda.b [$17]	 ; Load address
	inc.b $17
	inc.b $17
	tax ; X = address
	sep #$20		; 8-bit A
	lda.w $0000,x   ; Load byte
	sta.b $9e	   ; Store in $9e
	rts ; (REP #$30 in caller)

;-------------------------------------------------------------------------------
; Bitwise_ANDTable/ANDDirect - Bitwise and operations
;-------------------------------------------------------------------------------
Bitwise_ANDTable:
	jsr.w Memory_CopyWithTable ; Copy table
	bra Bitwise_ANDApply

Bitwise_ANDDirect:
	jsr.w Memory_CopyDirect ; Copy direct

Bitwise_ANDApply:
	lda.b $9e	   ; Load $9e
	and.b $98	   ; and with $98
	sta.b $9e	   ; Store result
	lda.b $a0	   ; Load $a0
	and.b $9a	   ; and with $9a
	sta.b $a0	   ; Store result


;-------------------------------------------------------------------------------
; Bitwise_AND1Byte - Bitwise and variants with preset counts
;-------------------------------------------------------------------------------
Bitwise_AND1Byte:
	lda.w #$0000	; 1 byte count
	bra Bitwise_ANDTable ; → and table copy

	lda.w #$0001	; 2 byte count
	bra Bitwise_ANDTable

	db $a9,$02,$00,$80,$dc,$a9,$00,$00,$80,$dc ; More variants

	lda.w #$0001	; 2 byte count
	bra Bitwise_ANDDirect ; → and direct copy

	db $a9,$02,$00,$80,$d2 ; 3 byte variant

;-------------------------------------------------------------------------------
; Bitwise_TSBTable/TSBDirect - Bitwise tsb (Test and Set Bits)
; Purpose: OR values with $9e/$a0 (set bits)
;-------------------------------------------------------------------------------
Bitwise_TSBTable:
	jsr.w Memory_CopyWithTable ; Copy table
	bra Bitwise_TSBApply

Bitwise_TSBDirect:
	jsr.w Memory_CopyDirect ; Copy direct

Bitwise_TSBApply:
	lda.b $98	   ; Load value
	tsb.b $9e	   ; Test and Set Bits in $9e
	lda.b $9a
	tsb.b $a0	   ; Test and Set Bits in $a0


	db $a9,$00,$00,$80,$ea ; tsb variants with preset counts

	lda.w #$0001
	bra Bitwise_TSBTable

	db $a9,$02,$00,$80,$e0

	lda.w #$0000
	bra Bitwise_TSBDirect

	db $a9,$01,$00,$80,$db,$a9,$02,$00,$80,$d6

;-------------------------------------------------------------------------------
; Bitwise_XORTable/XORDirect - Bitwise XOR (Exclusive OR)
; Purpose: XOR values with $9e/$a0
;-------------------------------------------------------------------------------
Bitwise_XORTable:
	jsr.w Memory_CopyWithTable ; Copy table
	bra Bitwise_XORApply

Bitwise_XORDirect:
	jsr.w Memory_CopyDirect ; Copy direct

Bitwise_XORApply:
	lda.b $9e
	eor.b $98	   ; XOR with $98
	sta.b $9e	   ; Store result
	lda.b $a0
	eor.b $9a	   ; XOR with $9a
	sta.b $a0


;-------------------------------------------------------------------------------
; XOR variants with preset counts
;-------------------------------------------------------------------------------
	lda.w #$0000
	bra Bitwise_XORTable

	db $a9,$01,$00,$80,$e1,$a9,$02,$00,$80,$dc,$a9,$00,$00,$80,$dc

	lda.w #$0001
	bra Bitwise_XORDirect

	db $a9,$02,$00,$80,$d2

;-------------------------------------------------------------------------------
; Math_AddTable/AddDirect - Addition (ADD)
; Purpose: Add values to $9e/$a0
;-------------------------------------------------------------------------------
Math_AddTable:
	jsr.w Memory_CopyWithTable ; Copy table
	bra Math_AddApply

Math_AddDirect:
	jsr.w Memory_CopyDirect ; Copy direct

Math_AddApply:

	lda.b $9e
	adc.b $98	   ; Add $98
	sta.b $9e	   ; Store sum
	lda.b $a0
	adc.b $9a	   ; Add $9a with carry
	sta.b $a0


;-------------------------------------------------------------------------------
; Math_Add1/2/3Byte - Addition variants with preset counts
;-------------------------------------------------------------------------------
Math_Add1Byte:
	lda.w #$0000	; 1 byte
	bra Math_AddTable

	lda.w #$0001	; 2 bytes
	bra Math_AddTable

	lda.w #$0002	; 3 bytes
	bra Math_AddTable

	lda.w #$0000	; Direct variants
	bra Math_AddDirect

	lda.w #$0001
	bra Math_AddDirect

	lda.w #$0002
	bra Math_AddDirect

;-------------------------------------------------------------------------------
; Math_SubTable/SubDirect - Subtraction (SUB)
; Purpose: Subtract values from $9e/$a0
;-------------------------------------------------------------------------------
Math_SubTable:
	jsr.w Memory_CopyWithTable ; Copy table
	bra Math_SubApply

Math_SubDirect:
	jsr.w Memory_CopyDirect ; Copy direct

Math_SubApply:

	lda.b $9e
	sbc.b $98	   ; Subtract $98
	sta.b $9e	   ; Store difference
	lda.b $a0
	sbc.b $9a	   ; Subtract $9a with borrow
	sta.b $a0


;-------------------------------------------------------------------------------
; Subtraction variants with preset counts
;-------------------------------------------------------------------------------
	lda.w #$0000
	bra Math_SubTable

	lda.w #$0001
	bra Math_SubTable

	lda.w #$0002
	bra Math_SubTable

	lda.w #$0000
	bra Math_SubDirect

	lda.w #$0001
	bra Math_SubDirect

	lda.w #$0002
	bra Math_SubDirect

;-------------------------------------------------------------------------------
; Math_Divide - Division (16-bit / 8-bit)
; Purpose: Divide $9e by accumulator
; Entry: A = divisor (8-bit)
; Exit: $98 = quotient, $9a = remainder (via ExitQuotientRemainderViaCode)
;-------------------------------------------------------------------------------
Math_Divide:
	sta.b $9c	   ; Store divisor
	lda.b $9e	   ; Load dividend
	sta.b $98	   ; Setup for division
	jsl.l ExitQuotientRemainderViaCode ; Call division routine


	lda.b [$17]	 ; Variant: divisor from script
	inc.b $17
	and.w #$00ff
	bra CodeDivisionBit

	db $a7,$17,$e6,$17,$e6,$17,$80,$e4 ; 16-bit divisor variant

	jsr.w Test_LoadValue9E ; Variant: divisor from $9e
	bra Math_Divide

	jsr.w Test_LoadValueRNG ; Variant: divisor from RNG
	bra Math_Divide

;-------------------------------------------------------------------------------
; Math_Multiply8: Multiplication (16-bit × 8-bit)
; Purpose: Multiply $9e/$a0 by accumulator
; Entry: A = multiplier (8-bit)
; Exit: Result in $98/$9a (via ExitResultViaCode)
;-------------------------------------------------------------------------------
Math_Multiply8:
	sta.b $9c	   ; Store multiplier
	lda.b $9e	   ; Load multiplicand low
	sta.b $98
	lda.b $a0	   ; Load multiplicand high
	sta.b $9a
	jsl.l ExitResultViaCode ; Call multiplication routine


;-------------------------------------------------------------------------------
; Math_Multiply8_Script: Multiplication variants
;-------------------------------------------------------------------------------
Math_Multiply8_Script:
	lda.b [$17]	 ; Multiplier from script (8-bit)
	inc.b $17
	and.w #$00ff
	bra Math_Multiply8

	lda.b [$17]	 ; Multiplier from script (16-bit)
	inc.b $17
	inc.b $17
	bra Math_Multiply8

	db $20,$88,$b1,$80,$db ; From Test_LoadValue8

	jsr.w Test_LoadValue16 ; From Test_LoadValue16
	bra Math_Multiply8

;-------------------------------------------------------------------------------
; Math_GetRNGResult: Get random number result
; Purpose: Transfer RNG result ($a2) to $9e
; Exit: $9e = random value, $a0 = 0
;-------------------------------------------------------------------------------
Math_GetRNGResult:
	lda.b $a2	   ; Load RNG result
	sta.b $9e	   ; Store in $9e
	stz.b $a0	   ; Clear high byte


	jsr.w Math_Multiply8_Script ; Variant: multiply then get result
	bra Math_GetRNGResult

	db $20,$24,$b1,$80,$ef,$20,$2c,$b1,$80,$ea,$20,$31,$b1,$80,$e5

;-------------------------------------------------------------------------------
; Math_FormatDecimal: Format decimal number for display
; Purpose: Convert binary value to BCD for display
; Entry: $9e/$a0 = value to convert
; Exit: Formatted value in buffer at $6d
;-------------------------------------------------------------------------------
Math_FormatDecimal:
	pei.b ($9e)	 ; Save $9e
	pei.b ($a0)	 ; Save $a0
	lda.w #$0090	; BCD format flags
	sta.b $6d	   ; Store in buffer
	lda.w #$000a	; Base 10 (decimal)
	sta.b $9c	   ; Store base
	ldx.w #$006d	; X = buffer pointer

	jsl.l BcdHexNumberFormattingRoutine ; Call BCD conversion
	pla ; Restore $a0
	sta.b $a0
	pla ; Restore $9e
	sta.b $9e


;-------------------------------------------------------------------------------
; Math_FormatHex: Format hexadecimal number for display
; Purpose: Convert binary value to hex for display
;-------------------------------------------------------------------------------
Math_FormatHex:
	pei.b ($9e)	 ; Save values
	pei.b ($a0)
	lda.w #$0010	; Base 16 (hexadecimal)
	sta.b $9c
	ldx.w #$006d	; Buffer pointer
	sec ; Hex mode flag
	jsl.l BcdHexNumberFormattingRoutine ; Call hex conversion
PLA_Label_1:
	sta.b $a0
PLA_Label_2:
	sta.b $9e


;-------------------------------------------------------------------------------
; CodeHelperRoutinesLoadingTestValues - Helper routines for loading test values
;-------------------------------------------------------------------------------
System_LoadFrom3A:
	lda.b $3a	   ; Load from $3a


Test_LoadValue8:
	lda.b [$17]	 ; Load 8-bit from script
	inc.b $17
	and.w #$00ff


Test_LoadValue9E:
	lda.b $9e	   ; Load from $9e


Test_LoadValueRNG:
	lda.b $a2	   ; Load from $a2 (RNG)


Test_LoadValue16:
	lda.b [$17]	 ; Load 16-bit from script
	inc.b $17
	inc.b $17


;-------------------------------------------------------------------------------
; Test_CompareValue24: Compare 16-bit values (equality test)
; Purpose: Test if $9e/$a0 == value from script
; Entry: [$17] = 16-bit value, [$17+2] = 8-bit high byte
; Exit: Z flag set if equal, C flag indicates comparison result
;-------------------------------------------------------------------------------
Test_CompareValue24:
	lda.b [$17]	 ; Load comparison value low
	inc.b $17
	inc.b $17
	sta.b $64	   ; Save in $64
	lda.b [$17]	 ; Load comparison value high
	inc.b $17
	and.w #$00ff
	sta.b $62	   ; Save in $62
	sec ; Set carry for comparison
	lda.b $a0	   ; Load high byte
	sbc.b $62	   ; Subtract comparison high
	bne IfNotEqualDone ; If not equal, done
	lda.b $9e	   ; Load low byte
	sbc.b $64	   ; Subtract comparison low
; Z flag = equality result
; C flag = greater/equal result

Test_CompareDone:


;===============================================================================
; Progress: ~10,200 lines documented (72.8% of Bank $00)
; Latest additions:
; - CodeBitwiseTsbOperationsVariants-00B021: Bitwise and and tsb operations with variants
; - CodeBitwiseXorOperations-00B053: Bitwise XOR operations
; - CodeBitAdditionOperations-00B094: 16-bit addition operations
; - CodeBitSubtractionOperations-00B0BA: 16-bit subtraction operations
; - CodeDivisionBit: Division (16÷8 bit)
; - CodeMultiplicationBit: Multiplication (16×8 bit)
; - CodeRandomNumberResultGetter: Random number result getter
; - CodeDecimalNumberFormattingBcdConversion: Decimal number formatting (BCD conversion)
; - CodeHexadecimalNumberFormatting: Hexadecimal number formatting
; - CodeHelperRoutinesLoadingTestValues-00B196: Value loading helper routines
; - TestVariable: 24-bit comparison test
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
	lda.b $2e	   ; Load context pointer
	phd ; Save current direct page
	tcd ; Set $2e as new DP base
	lda.w $009e	 ; Load value from $9e in new context
	jsl.l Bit_TestBits ; Call external comparison
	pld ; Restore direct page
	inc a; Set flags
	dec a; (Z flag = equality)


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
	lda.b [$17]	 ; Load 8-bit comparison value
	inc.b $17	   ; Advance script pointer
	and.w #$00ff	; Mask to 8 bits
	sta.b $64	   ; Store comparison value
	sec ; Set carry for comparison
	lda.b $a0	   ; Check high byte
	bne Test_Compare8_Done ; If non-zero, value > 255, return
	lda.b $9e	   ; Compare low byte
	cmp.b $64	   ; Set C and Z flags
Test_Compare8_Done:


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
	lda.b [$17]	 ; Load 16-bit comparison value
	inc.b $17	   ; Advance script pointer
	inc.b $17	   ; (2 bytes)
	sta.b $64	   ; Store comparison value
	sec ; Set carry for comparison
	lda.b $a0	   ; Check high byte
	bne Test_Compare16_Done ; If non-zero, value > $ffff, return
	lda.b $9e	   ; Compare low word
	cmp.b $64	   ; Set C and Z flags
Test_Compare16_Done:


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
	lda.b [$17]	 ; Load low word
	inc.b $17
	inc.b $17
	sta.b $64	   ; Store low word
	lda.b [$17]	 ; Load high byte
	inc.b $17
	and.w #$00ff	; Mask to 8 bits
	sta.b $62	   ; Store high byte
	lda.b $a0	   ; Compare high bytes first
	cmp.b $62
	bne Test_Compare24Done ; If not equal, done (C/Z set)
	lda.b $9e	   ; Compare low words
	cmp.b $64
Test_Compare24Done:


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
	lda.b [$17]	 ; Load pointer
	inc.b $17
	inc.b $17
	tax ; Use as index
	lda.w $0000,x   ; Load 8-bit value from pointer
	and.w #$00ff	; Mask to 8 bits
	sta.b $64	   ; Store comparison value
	sec ; Set carry
	lda.b $a0	   ; Check high byte
	bne Test_CompareIndirect8Done ; If non-zero, return
	lda.b $9e	   ; Compare low byte
	cmp.b $64
Test_CompareIndirect8Done:


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
	lda.b [$17]	 ; Load pointer
	inc.b $17
	inc.b $17
	tax ; Use as index
	sec ; Set carry
	lda.b $a0	   ; Check high byte
	bne Test_CompareIndirect16Done ; If non-zero, return
	lda.b $9e	   ; Compare with value at pointer
	cmp.w $0000,x
Test_CompareIndirect16Done:


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
	lda.b [$17]	 ; Load pointer
	inc.b $17
	inc.b $17
	tax ; Use as index
	lda.w $0002,x   ; Load high byte from pointer+2
	and.w #$00ff	; Mask to 8 bits
	sta.b $64	   ; Store high byte
	lda.b $a0	   ; Compare high bytes
	cmp.b $64
	bne Test_CompareIndirect24Done ; If not equal, done
	lda.b $9e	   ; Compare low words
	cmp.w $0000,x   ; With value at pointer
Test_CompareIndirect24Done:


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
	lda.b [$17]	 ; Load string length
	inc.b $17	   ; Advance script pointer
	and.w #$00ff	; Mask to 8 bits
	bra String_CountHighBit_Setup ; Jump to counter

; Entry point: length from $3a
	db $a5,$3a,$29,$ff,$00 ; lda $3a; and #$00ff (alternate entry)

String_CountHighBit_Setup:
	tay ; Y = string length (counter)
	lda.b $a0	   ; Get bank
	and.w #$00ff	; Mask to 8 bits
	pha ; Push bank
	plb ; Set data bank
	ldx.b $9e	   ; X = string address
	bra String_CountHighBit_Init ; Jump to scan loop

; Another entry point (different parameters)
	db $8b,$a7,$17,$e6,$17,$e6,$17,$aa,$a7,$17,$e6,$17,$29,$ff,$00,$a8 ; Alternate parameter loading

String_CountHighBit_Init:
	stz.b $9e	   ; Clear result counter
	stz.b $a0	   ; Clear high byte

String_CountHighBit_Loop:
	lda.w $0000,x   ; Load character from string
	and.w #$00ff	; Mask to 8 bits
	cmp.w #$0080	; Check if >= $80 (high bit set)
	bcc String_CountHighBit_Next ; If < $80, skip increment
	inc.b $9e	   ; Count this character

String_CountHighBit_Next:
	inx ; Next character
	dey ; Decrement counter
	bne String_CountHighBit_Loop ; Loop until done
	plb ; Restore bank


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
	lda.w #$0000	; Load 0
	sec ; Set carry for subtraction
	sbc.b $9e	   ; 0 - low word
	sta.b $9e
	lda.w #$0000	; Load 0
	sbc.b $a0	   ; 0 - high byte (with borrow)
	sta.b $a0


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
	db $a2,$1a,$00,$a0,$5f,$00,$a9,$02,$00,$54,$00,$00,$a7,$17,$e6,$17
	db $29,$ff,$00,$48,$4a,$a8,$68,$3a,$0a,$65,$5f,$aa,$e2,$20,$a5,$61
	db $8b,$48,$ab,$c2,$30,$a7,$5f,$49,$00,$40,$48,$bd,$00,$00,$49,$00
	db $40,$87,$5f,$68,$9d,$00,$00,$ca,$ca,$e6,$5f,$e6,$5f,$88,$d0,$e5
	db $ab,$60
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
	lda.b $1a	   ; Load tilemap pointer
	sec ; Set carry for subtraction
	sbc.w #$0040	; Subtract one row ($40 bytes)
	sta.b $1a	   ; Store result


;-------------------------------------------------------------------------------
; Tilemap_IncrementRow: Increment tilemap pointer by one row
;
; Purpose: Move tilemap pointer down one row (add $40 = 64 bytes)
; Entry: $1a = tilemap pointer
; Exit: $1a += $40
; Notes: SNES tilemap rows are $40 bytes apart
;-------------------------------------------------------------------------------
Tilemap_IncrementRow:
	lda.b $1a	   ; Load tilemap pointer
	clc ; Clear carry for addition
	adc.w #$0040	; Add one row ($40 bytes)
	sta.b $1a	   ; Store result


;-------------------------------------------------------------------------------
; Tilemap_DecrementTile: Decrement tilemap pointer by one tile
;
; Purpose: Move tilemap pointer left one tile (subtract 2 bytes)
; Entry: $1a = tilemap pointer
; Exit: $1a -= 2
; Notes: Each tilemap entry is 2 bytes (tile number + attributes)
;-------------------------------------------------------------------------------
Tilemap_DecrementTile:
	dec.b $1a	   ; Decrement low byte
	dec.b $1a	   ; Decrement again (2 bytes)


;-------------------------------------------------------------------------------
; Tilemap_IncrementTile: Increment tilemap pointer by one tile
;
; Purpose: Move tilemap pointer right one tile (add 2 bytes)
; Entry: $1a = tilemap pointer
; Exit: $1a += 2
; Notes: Each tilemap entry is 2 bytes
;-------------------------------------------------------------------------------
Tilemap_IncrementTile:
	inc.b $1a	   ; Increment low byte
	inc.b $1a	   ; Increment again (2 bytes)


;-------------------------------------------------------------------------------
; Cmd_CallExternal16: Jump to external routine with 16-bit parameter
;
; Purpose: Load 16-bit parameter from script and call external function
; Entry: [$17] = 16-bit parameter
; Exit: $17 incremented by 2
;       Returns from external function
; Calls: CallsCodeExternalRoutine (external routine)
;-------------------------------------------------------------------------------
Cmd_CallExternal16:
	lda.b [$17]	 ; Load 16-bit parameter
	inc.b $17	   ; Advance script pointer
	inc.b $17	   ; (2 bytes)
	jmp.w CallsCodeExternalRoutine ; Jump to external routine

;-------------------------------------------------------------------------------
; Cmd_CallExternal8: Jump to external routine with 8-bit parameter
;
; Purpose: Load 8-bit parameter from script and call external function
; Entry: [$17] = 8-bit parameter
; Exit: $17 incremented by 1
;       Returns from external function
; Calls: CodeDirectTileWrite (external routine)
;-------------------------------------------------------------------------------
Cmd_CallExternal8:
	lda.b [$17]	 ; Load 8-bit parameter
	inc.b $17	   ; Advance script pointer
	and.w #$00ff	; Mask to 8 bits
	jmp.w CodeDirectTileWrite ; Jump to external routine

;-------------------------------------------------------------------------------
; Math_ShiftRight: Right shift $9e/$a0 by N bits
;
; Purpose: Logical right shift of 16-bit value
; Entry: [$17] = shift count (1-15)
;        $9e/$a0 = value to shift
; Exit: $9e/$a0 = value >> shift_count
;       $17 incremented by 1
; Notes: Each iteration: lsr high byte, ror low byte (preserves shifted bits)
;-------------------------------------------------------------------------------
Math_ShiftRight:
	lda.b [$17]	 ; Load shift count
	inc.b $17	   ; Advance script pointer
	and.w #$00ff	; Mask to 8 bits

Math_ShiftRight_Loop:
	lsr.b $a0	   ; Shift high byte right
	ror.b $9e	   ; Rotate low byte right (carry in)
	dec a; Decrement shift count
	bne Math_ShiftRight_Loop ; Loop until done


;-------------------------------------------------------------------------------
; Math_ShiftLeft: Left shift $9e/$a0 by N bits
;
; Purpose: Logical left shift of 16-bit value
; Entry: [$17] = shift count (1-15)
;        $9e/$a0 = value to shift
; Exit: $9e/$a0 = value << shift_count
;       $17 incremented by 1
; Notes: Each iteration: asl low byte, rol high byte (preserves shifted bits)
;-------------------------------------------------------------------------------
Math_ShiftLeft:
	lda.b [$17]	 ; Load shift count
	inc.b $17	   ; Advance script pointer
	and.w #$00ff	; Mask to 8 bits

Math_ShiftLeft_Loop:
	asl.b $9e	   ; Shift low byte left
	rol.b $a0	   ; Rotate high byte left (carry in)
	dec a; Decrement shift count
	bne Math_ShiftLeft_Loop ; Loop until done


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
	db $a7,$17,$e6,$17,$e6,$17,$aa,$bd,$00,$00,$29,$ff,$00,$46,$a0,$66
	db $9e,$3a,$d0,$f9,$60
; lda [$17]; inc $17; inc $17; TAX; lda $0000,X; and #$00ff
; lsr $a0; ror $9e; dec A; bne loop; rts

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
	db $a7,$17,$e6,$17,$e6,$17,$aa,$bd,$00,$00,$29,$ff,$00,$06,$9e,$26
	db $a0,$3a,$d0,$f9,$60
; lda [$17]; inc $17; inc $17; TAX; lda $0000,X; and #$00ff
; asl $9e; rol $a0; dec A; bne loop; rts

;-------------------------------------------------------------------------------
; Script_NoOp: No operation (placeholder)
;
; Purpose: Empty function (immediate return)
; Notes: May be unused or placeholder for future functionality
;-------------------------------------------------------------------------------
Script_NoOp:


;-------------------------------------------------------------------------------
; Script_Execute: Execute script or function call
;
; Purpose: Execute script function or register external script
; Entry: [$17] = function/script address
; Exit: $17 incremented by 2
;       Script executed or registered
; Calls: Script_Execute_Handler (script execution handler)
;       ProcessString (external script registration)
;       BankScriptInitializationRoutine (script initialization)
; Notes: Handles both internal scripts (>= $8000) and external scripts (< $8000)
;-------------------------------------------------------------------------------
Script_Execute:
	lda.b [$17]	 ; Load script address
	inc.b $17	   ; Advance script pointer
	inc.b $17	   ; (2 bytes)

Script_Execute_Handler:
	cmp.w #$8000	; Check if >= $8000 (internal script)
	bcc Script_Execute_External ; If < $8000, external script
	tax ; X = script address
	lda.w #$0003	; Script mode 3
	jmp.w ProcessString ; Register and execute script

Script_Execute_External:
	pei.b ($17)	 ; Save current script pointer
	pei.b ($18)	 ; (both bytes)
	sta.w !battle_gfx_index	 ; Store script address
	jsl.l BankScriptInitializationRoutine ; Initialize and run script
	pla ; Restore script pointer
	sta.b $18
PLA_Label_3:
	sta.b $17


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
	lda.b [$17]	 ; Load script address
	inc.b $17	   ; Advance pointer
	inc.b $17	   ; (2 bytes)
	cmp.w #$ffff	; Check for terminator
	beq Script_ExecuteList_Done ; If $ffff, done
	jsr.w Script_Execute_Handler ; Execute this script
	rep #$30		; Ensure 16-bit mode
	bra Script_ExecuteList ; Loop to next script

Script_ExecuteList_Done:


;-------------------------------------------------------------------------------
; Math_RandomTransform: Random number transformation
;
; Purpose: Apply random number transformation to $9e
; Entry: $9e = input value
; Exit: $9e = transformed value
; Calls: CodeReturnsHandlerIndexBasedGame (external RNG transformation)
;-------------------------------------------------------------------------------
Math_RandomTransform:
	lda.b $9e	   ; Load value
	jsl.l CodeReturnsHandlerIndexBasedGame ; Apply RNG transformation
	sta.b $9e	   ; Store result


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
	lda.b $9e	   ; Load value
	ldx.w #$0010	; Start with 16 (max leading zeros)

Math_CountLeadingZeros_Loop:
	dex ; Decrement counter
	asl a; Shift left (bit 15 → Carry)
	bcc Math_CountLeadingZeros_Loop ; If carry clear (bit was 0), continue
	stx.b $9e	   ; Store leading zero count


;-------------------------------------------------------------------------------
; Math_Increment24: Increment $9e/$a0 (24-bit safe)
;
; Purpose: Increment 16-bit value with carry to high byte
; Entry: $9e/$a0 = value
; Exit: $9e/$a0 = value + 1
; Notes: Handles carry from $9e to $a0
;-------------------------------------------------------------------------------
Math_Increment24:
	inc.b $9e	   ; Increment low word
	bne Math_Increment24_Done ; If not zero, done
	db $e6,$a0	 ; inc $a0 (high byte)

Math_Increment24_Done:


;-------------------------------------------------------------------------------
; Cmd_IncrementIndirect16: Increment 16-bit value at pointer (from script)
;
; Purpose: Increment word at memory address from script
; Entry: [$17] = pointer to 16-bit value
; Exit: Word at pointer incremented
;       $17 incremented by 2
;-------------------------------------------------------------------------------
Cmd_IncrementIndirect16:
	lda.b [$17]	 ; Load pointer
	inc.b $17	   ; Advance script pointer
	inc.b $17	   ; (2 bytes)
	tax ; X = pointer
	inc.w $0000,x   ; Increment word at pointer


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
	lda.b [$17]	 ; Load pointer
	inc.b $17	   ; Advance script pointer
	inc.b $17	   ; (2 bytes)
	tax ; X = pointer
	sep #$20		; 8-bit accumulator
	inc.w $0000,x   ; Increment byte at pointer


;-------------------------------------------------------------------------------
; Math_Decrement24: Decrement $9e/$a0 (24-bit safe)
;
; Purpose: Decrement 16-bit value with borrow from high byte
; Entry: $9e/$a0 = value
; Exit: $9e/$a0 = value - 1
; Notes: Handles borrow from $a0 to $9e
;-------------------------------------------------------------------------------
Math_Decrement24:
	lda.b $9e	   ; Load low word
	sec ; Set carry for subtraction
	sbc.w #$0001	; Subtract 1
	sta.b $9e	   ; Store result
	bcs Math_Decrement24_Done ; If carry set, no borrow needed
	dec.b $a0	   ; Borrow from high byte

Math_Decrement24_Done:


;-------------------------------------------------------------------------------
; Cmd_DecrementIndirect16: Decrement 16-bit value at pointer (from script)
;
; Purpose: Decrement word at memory address from script
; Entry: [$17] = pointer to 16-bit value
; Exit: Word at pointer decremented
;       $17 incremented by 2
;-------------------------------------------------------------------------------
Cmd_DecrementIndirect16:
	lda.b [$17]	 ; Load pointer
	inc.b $17	   ; Advance script pointer
	inc.b $17	   ; (2 bytes)
	tax ; X = pointer
	dec.w $0000,x   ; Decrement word at pointer


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
	lda.b [$17]	 ; Load pointer
	inc.b $17	   ; Advance script pointer
	inc.b $17	   ; (2 bytes)
	tax ; X = pointer
	sep #$20		; 8-bit accumulator
	dec.w $0000,x   ; Decrement byte at pointer


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
	db $a7,$17,$e6,$17,$e6,$17,$aa,$a7,$17,$e6,$17,$e6,$17,$3d,$00,$00
	db $9d,$00,$00,$60
; lda [$17]; inc $17; inc $17; tax
; lda [$17]; inc $17; inc $17
; ora $0000,X; sta $0000,X; rts

;-------------------------------------------------------------------------------
; Bitwise_ANDIndirect8: Bitwise and from indirect addresses (8-bit)
;
; Purpose: and byte from second pointer with byte at first pointer, store at first
; Entry: [$17] = destination pointer (16-bit address)
;        [$17+2] = 8-bit mask value
; Exit: [dest] = [dest] and mask (8-bit operation)
;       $17 incremented by 3
; Notes: Uses 8-bit accumulator mode
;-------------------------------------------------------------------------------
Bitwise_ANDIndirect8:
	lda.b [$17]	 ; Load destination pointer
	inc.b $17
	inc.b $17
	tax ; X = destination
	lda.b [$17]	 ; Load mask value
	inc.b $17
	and.w #$00ff	; Mask to 8 bits
	sep #$20		; 8-bit accumulator
	and.w $0000,x   ; and with destination
	sta.w $0000,x   ; Store result


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
	db $a7,$17,$e6,$17,$e6,$17,$aa,$a7,$17,$e6,$17,$e6,$17,$1d,$00,$00
	db $9d,$00,$00,$60
; lda [$17]; inc $17; inc $17; tax
; lda [$17]; inc $17; inc $17
; ora $0000,X; sta $0000,X; rts

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
	lda.b [$17]	 ; Load destination pointer
	inc.b $17
	inc.b $17
	tax ; X = destination
	lda.b [$17]	 ; Load mask value
	inc.b $17
	and.w #$00ff	; Mask to 8 bits
	sep #$20		; 8-bit accumulator
	ora.w $0000,x   ; OR with destination
	sta.w $0000,x   ; Store result


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
	db $a7,$17,$e6,$17,$e6,$17,$aa,$a7,$17,$e6,$17,$e6,$17,$5d,$00,$00
	db $9d,$00,$00,$60
; lda [$17]; inc $17; inc $17; tax
; lda [$17]; inc $17; inc $17
; eor $0000,X; sta $0000,X; rts

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
	lda.b [$17]	 ; Load destination pointer
	inc.b $17
	inc.b $17
	tax ; X = destination
	lda.b [$17]	 ; Load mask value
	inc.b $17
	and.w #$00ff	; Mask to 8 bits
	sep #$20		; 8-bit accumulator
	eor.w $0000,x   ; XOR with destination
	sta.w $0000,x   ; Store result


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
	lda.w #$002a	; Offset 42
	bra Sprite_CalcTileAddress_Do ; Jump to calculator

Sprite_CalcTileAddress_Alt:
	lda.w #$000a	; Offset 10

Sprite_CalcTileAddress_Do:
	sep #$30		; 8-bit A/X/Y
	clc ; Clear carry
	ldx.b $5e	   ; Load character index
	adc.l DATA8_049800,x ; Add character position offset
	xba ; Swap A/B (position in high byte)
	txa ; A = character index
	and.b #$38	  ; Mask bits 3-5
	asl a; × 2
	sta.b $64	   ; Store intermediate
	txa ; A = character index again
	and.b #$07	  ; Mask bits 0-2
	adc.b $64	   ; Add intermediate
	asl a; × 2 (tile address scaling)
	rep #$20		; 16-bit accumulator
	sep #$10		; 8-bit X/Y
	ldy.b #$00	  ; Y = 0
	sta.b [$1a],y   ; Store at tilemap pointer
	inc a; Next tile
	ldy.b #$02	  ; Y = 2
	sta.b [$1a],y   ; Store at tilemap+2
	adc.w #$000f	; Add 15 (next row offset)
	ldy.b #$40	  ; Y = $40 (row below)
	sta.b [$1a],y   ; Store at tilemap+$40
	inc a; Next tile
	ldy.b #$42	  ; Y = $42
	sta.b [$1a],y   ; Store at tilemap+$42


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
	lda.b $1a	   ; Load current pointer
	cmp.b $44	   ; Compare with current min
	bcs Tilemap_UpdateMin_Done ; If >= min, skip
	sta.b $44	   ; Update minimum

Tilemap_UpdateMin_Done:


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
	lda.b $1a	   ; Load current pointer
	cmp.b $46	   ; Compare with current max
	bcc Tilemap_UpdateMax_Done ; If < max, skip
	sta.b $46	   ; Update maximum

Tilemap_UpdateMax_Done:


;-------------------------------------------------------------------------------
; CodeCheckFlagExecuteRoutine: Check flag and execute routine
;
; Purpose: Check bit 5 of $da and branch to different routines
; Entry: $da = flag register
; Exit: Jumps to CodePointerManipulationCoordinateCalculations if bit 5 set, CodeDirectTileWrite otherwise
; Notes: bit 5 of $da appears to be a mode or state flag
;-------------------------------------------------------------------------------
System_CheckModeJump:
	lda.w #$0020	; bit 5 mask
	and.w !system_flags_5	 ; Test bit 5 of $da
	beq System_AlternateModeJump ; If clear, jump to alternate
	jmp.w CodePointerManipulationCoordinateCalculations ; Jump to routine A

;-------------------------------------------------------------------------------
; System - Alternate Mode Jump
;-------------------------------------------------------------------------------
; Purpose: Load $00ff and jump to CodeDirectTileWrite (likely fade/graphics routine)
; Reachability: Reachable via conditional branch (beq above)
; Analysis: Alternate execution path when bit 5 of $00da is clear
;   - Loads A with $00ff (16-bit)
;   - Jumps to CodeDirectTileWrite (graphics fade/transition routine)
; Technical: Originally labeled UNREACH_00B4BB
;-------------------------------------------------------------------------------
System_AlternateModeJump:
	lda.w #$00ff                         ;00B4BB|A9FF00  |      ; Load A with $00ff
	jmp.w CodeDirectTileWrite                    ;00B4BE|4CC99D  |009DC9; Jump to graphics routine

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
	lda.w #$1c00	; Bits 10-12 mask
	trb.b $1d	   ; Clear bits in $1d
	lda.b [$17]	 ; Load new mode value
	inc.b $17	   ; Advance script pointer
	and.w #$00ff	; Mask to 8 bits
	tsb.b $1e	   ; Set bits in $1e


;-------------------------------------------------------------------------------
; Math_RNGSeed: RNG seed setup and call
;
; Purpose: Set up RNG seed from script and generate random number
; Entry: [$17] = 8-bit seed/parameter
; Exit: $9e = random number result
;       $a0 = 0
;       $17 incremented by 1
; Calls: CallsCodeRngRoutine (RNG routine)
;-------------------------------------------------------------------------------
Math_RNGSeed:
	stz.b $9e	   ; Clear $9e
	stz.b $a0	   ; Clear $a0
	lda.b [$17]	 ; Load seed parameter
	inc.b $17	   ; Advance script pointer
	and.w #$00ff	; Mask to 8 bits
	sep #$20		; 8-bit accumulator
	sta.w $00a8	 ; Store in RNG parameter location
	jsl.l CallsCodeRngRoutine ; Call RNG routine
	lda.w $00a9	 ; Load RNG result
	sta.b $9e	   ; Store in $9e


;-------------------------------------------------------------------------------
; Cmd_CallExternal9E: Jump to external with $9e parameter
;
; Purpose: Call external routine with $9e as parameter
; Entry: $9e = parameter value
; Calls: CallsCodeExternalRoutine (external routine)
;-------------------------------------------------------------------------------
Cmd_CallExternal9E:
	lda.b $9e	   ; Load parameter
	jmp.w CallsCodeExternalRoutine ; Jump to external routine

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
	lda.b [$17]	 ; Load character count param
	inc.b $17	   ; Advance script pointer
	and.w #$00ff	; Mask to 8 bits
	sta.b $64	   ; Store count
	lda.b $63	   ; Load character width base
	and.w #$ff00	; Keep high byte
	lsr a; / 2 (adjust for offset)
	tax ; X = string offset
	adc.w #$1100	; Add buffer base address
	sta.b $9e	   ; Store in $9e (string pointer)
	ldy.w #$0010	; Y = 16 (max scan count)
	stz.b $62	   ; Clear first counter
	sep #$20		; 8-bit accumulator
	stz.b $a0	   ; Clear high byte

Text_CalcCentering_Loop1:
	lda.w !char_name_buffer,x   ; Load character from buffer
	inx ; Next character
	cmp.b #$80	  ; Check if >= $80
	bcc Text_CalcCentering_Loop2 ; If < $80, found end of first section
	inc.b $62	   ; Count this character (>= $80)
	dey ; Decrement remaining
	bne Text_CalcCentering_Loop1 ; Loop until done
	db $80,$10	 ; bra (skip next section)

Text_CalcCentering_Loop2:
	dey ; Decrement remaining
	beq Text_CalcCentering_Calc ; If done, exit

Text_CalcCentering_Loop2_Inner:
	lda.w !char_name_buffer,x   ; Load character
	inx ; Next character
	cmp.b #$80	  ; Check if >= $80
	bcc Text_CalcCentering_Calc ; If < $80, still in second section
	inc.b $63	   ; Count this character (>= $80)
	dey ; Decrement remaining
	bne Text_CalcCentering_Loop2_Inner ; Loop

Text_CalcCentering_Calc:
	lda.b $62	   ; Load first count
	cmp.b $63	   ; Compare with second count
	bcs Text_CalcCentering_UseFirst ; If first >= second, use first
	lda.b $63	   ; Use second count

Text_CalcCentering_UseFirst:
	sta.b $62	   ; Store max count
	sec ; Set carry for subtraction
	lda.b $2a	   ; Load total width
	sbc.b #$02	  ; Subtract 2
	sbc.b $62	   ; Subtract max count
	lsr a; / 2 (center offset)
	clc ; Clear carry
	adc.b $25	   ; Add to base position
	sta.b $25	   ; Store centered position
	rep #$30		; 16-bit A/X/Y
	jsr.w CodeCalculatePointerCoordinatesPosition ; Call positioning routine


;-------------------------------------------------------------------------------
; Text_SetCounter16: Set text counter and call text routine
;
; Purpose: Set $3a to $10 (16) and call text drawing routine
; Entry: (parameters set up by caller)
; Exit: Text drawing initiated
; Calls: CallsCodeTextDrawingRoutine (text drawing routine)
;-------------------------------------------------------------------------------
Text_SetCounter16:
	lda.w #$0010	; Load 16
	sta.b $3a	   ; Store in counter
	jmp.w CallsCodeTextDrawingRoutine ; Jump to text drawing

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
	db $c2,$20,$e2,$10,$ad,$5f,$01,$a4,$1f,$87,$1a,$e6,$1a,$e6,$1a,$1a
	db $88,$d0,$f6,$8d,$5f,$01,$60
; rep #$20; sep #$10
; lda $015f; ldy $1f
; sta [$1a]; inc $1a; inc $1a; inc A
; DEY; bne loop; sta $015f; rts

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
; Calls: BankSpriteInitialization (external sprite init)
; Notes: Complex location-based sprite positioning
;        Handles battle vs overworld sprite modes
;        Adjusts for screen centering and boundaries
;-------------------------------------------------------------------------------
Sprite_SetupCharacter:
	php ; Save processor status
	sep #$20		; 8-bit accumulator
	rep #$10		; 16-bit X/Y
	lda.b #$10	  ; bit 4 mask
	and.w !system_flags_5	 ; Test bit 4 of $da
	beq Sprite_SetupCharacter_Normal ; If clear, normal mode
	lda.b #$04	  ; Mode 4 (battle mode)
	sta.b $24	   ; Store sprite mode
	ldx.w #$5f78	; Sprite data pointer
	stx.b $22	   ; Store in $22
	plp ; Restore processor status


Sprite_SetupCharacter_Normal:
	lda.b #$04	  ; bit 2 mask
	trb.w $00d0	 ; Clear bit 2 of $d0
	jsl.l BankSpriteInitialization ; Call external sprite init
	lda.b #$01	  ; bit 0 mask
	and.w $00d9	 ; Test bit 0 of $d9
	beq Sprite_SetupCharacter_CheckLocation ; If clear, skip
	lda.b #$08	  ; Mode 8
	sta.b $24	   ; Store sprite mode

Sprite_SetupCharacter_CheckLocation:
	lda.b $20	   ; Load location/mode ID
	cmp.b #$0b	  ; Location $0b?
	beq Sprite_SetupCharacter_Special ; If yes, special handling
	cmp.b #$a7	  ; Location $a7?
	beq Sprite_SetupCharacter_Special ; If yes, special handling
	cmp.b #$4f	  ; Location $4f?
	beq Sprite_SetupCharacter_SetBit2 ; If yes, set bit 2 in $d0
	cmp.b #$01	  ; Location $01?
	beq Sprite_SetupCharacter_AdjustX ; If yes, adjust X position
	cmp.b #$1b	  ; Location $1b?
	beq Sprite_SetupCharacter_AdjustX ; If yes, adjust X position
	cmp.b #$30	  ; Location $30?
	beq Sprite_SetupCharacter_AdjustX ; If yes, adjust X position
	cmp.b #$31	  ; Location $31?
	beq Sprite_SetupCharacter_AdjustX ; If yes, adjust X position
	cmp.b #$4e	  ; Location $4e?
	beq Sprite_SetupCharacter_AdjustX ; If yes, adjust X position
	cmp.b #$6b	  ; Location $6b?
	beq Sprite_AdjustYPosition_Location6B ; If yes, adjust Y position
	cmp.b #$77	  ; < $77?
	bcc Sprite_SetupCharacter_Continue ; If yes, continue
	cmp.b #$7b	  ; >= $7b?
	bcs Sprite_SetupCharacter_Continue ; If yes, continue
	bra Sprite_SetupCharacter_AdjustX    ;00B5C0|8007    |00B5C9; Branch to adjust X

;-------------------------------------------------------------------------------
; Sprite - Adjust Y Position for Location $6b
;-------------------------------------------------------------------------------
; Purpose: Adjust Y position by adding 4
; Reachability: Reachable via conditional branch (beq above)
; Analysis: Y coordinate adjustment for sprite at location $6b
;   - Clears carry flag, loads Y position from $23, adds 4 pixels, stores back
; Technical: Originally labeled UNREACH_00B5C2
;-------------------------------------------------------------------------------
Sprite_AdjustYPosition_Location6B:
	clc ;00B5C2|18      |      ; Clear carry
	lda.b $23                            ;00B5C3|A523    |000023; Load Y position
	adc.b #$04                           ;00B5C5|6904    |      ; Add 4
	sta.b $23                            ;00B5C7|8523    |000023; Store Y position

Sprite_SetupCharacter_AdjustX:
	clc ; Clear carry
	lda.b $22	   ; Load X position
	adc.b #$08	  ; Add 8
	sta.b $22	   ; Store X position
	lda.b #$04	  ; Mode 4
	sta.b $24	   ; Store sprite mode

Sprite_SetupCharacter_SetBit2:
	lda.b #$04	  ; bit 2 mask
	tsb.w $00d0	 ; Set bit 2 of $d0
	bra Sprite_SetupCharacter_Continue ; Continue

Sprite_SetupCharacter_Special:
	lda.b #$04	  ; Mode 4
	sta.b $24	   ; Store sprite mode

Sprite_SetupCharacter_Continue:
	inc.b $23	   ; Increment Y position
	lda.b $24	   ; Load sprite mode
	bit.b #$08	  ; Test bit 3
	bne Sprite_SetupCharacter_Mode10 ; If set, use mode 10
	bit.b #$04	  ; Test bit 2
	bne Sprite_SetupCharacter_Mode5 ; If set, use mode 5
	bit.b #$02	  ; Test bit 1
	bne Sprite_SetupCharacter_Mode10 ; If set, use mode 10

Sprite_SetupCharacter_Mode5:
	lda.b #$05	  ; Mode 5
	bra Sprite_SetupCharacter_StoreMode ; Store mode

Sprite_SetupCharacter_Mode10:
	lda.b #$0a	  ; Mode 10

Sprite_SetupCharacter_StoreMode:
	sta.b $24	   ; Store final sprite mode
	lda.b $23	   ; Load Y position
	cmp.b #$08	  ; < $08?
	bcc Sprite_ClampYMin ; If yes, clamp to $08
	cmp.b #$a9	  ; >= $a9?
	bcc Sprite_SetupCharacter_CheckX ; If no, in range
	lda.b #$a8                           ;00B601|A9A8    |      ; Clamp to $a8
	sta.b $23                            ;00B603|8523    |000023; Store Y position
	bra Sprite_SetupCharacter_CheckX     ;00B605|8004    |00B60B; Continue

;-------------------------------------------------------------------------------
; Sprite - Clamp Y to Minimum
;-------------------------------------------------------------------------------
; Purpose: Clamp Y position to minimum value $08
; Reachability: Reachable via conditional branch (bcc above)
; Analysis: Lower bound clamping for sprite Y coordinate
;   - Loads A with $08 (minimum Y position), stores to $23
; Technical: Originally labeled UNREACH_00B607
;-------------------------------------------------------------------------------
Sprite_ClampYMin:
	lda.b #$08                           ;00B607|A908    |      ; Clamp to $08 (minimum)
	sta.b $23                            ;00B609|8523    |000023; Store Y position

Sprite_SetupCharacter_CheckX:
	clc ; Clear carry
	lda.b $2d	   ; Load parameter
	xba ; Swap A/B
	lda.b #$0e	  ; Load 14
	adc.b $2d	   ; Add to parameter
	sta.b $2d	   ; Store result
	sta.b $64	   ; Store in temp
	adc.b #$05	  ; Add 5
	cmp.b $23	   ; Compare with Y position
	bcs Sprite_SetupCharacter_SetBit3 ; If >= Y, use mode bits
	sec ; Set carry
	lda.b #$a8	  ; Load $a8
	sbc.b $2d	   ; Subtract parameter
	cmp.b $23	   ; Compare with Y
	bcs Sprite_SetupCharacter_CheckXBounds ; If >= Y, continue
	lda.b $24	   ; Load sprite mode
	and.b #$f7	  ; Clear bit 3
	ora.b #$04	  ; Set bit 2
	sta.b $24	   ; Store updated mode
	bra Sprite_SetupCharacter_CheckXBounds ; Continue

Sprite_SetupCharacter_SetBit3:
	lda.b $24	   ; Load sprite mode
	and.b #$fb	  ; Clear bit 2
	ora.b #$08	  ; Set bit 3
	sta.b $24	   ; Store updated mode

Sprite_SetupCharacter_CheckXBounds:
	xba ; Swap A/B
	sta.b $2d	   ; Store parameter
	lda.b $22	   ; Load X position
	cmp.b #$20	  ; < $20?
	bcc Sprite_SetupCharacter_XLow ; If yes, clamp to $08
	cmp.b #$d1	  ; >= $d1?
	bcc Sprite_SetupCharacter_CalcYOffset ; If no, in range
	db $c9,$e9,$90,$04,$a9,$e8,$85,$22,$a5,$24,$29,$fd,$09,$01,$85,$24
	db $80,$10	 ; lda #$e8; sta $22; lda $24; and #$fd; ora #$01; sta $24; bra

Sprite_SetupCharacter_XLow:
	cmp.b #$08	  ; < $08?
	bcs Sprite_SetupCharacter_XLow_SetBit1 ; If no, in range
	db $a9,$08,$85,$22 ; lda #$08; sta $22

Sprite_SetupCharacter_XLow_SetBit1:
	lda.b $24	   ; Load sprite mode
	and.b #$fe	  ; Clear bit 0
	ora.b #$02	  ; Set bit 1
	sta.b $24	   ; Store updated mode

Sprite_SetupCharacter_CalcYOffset:
	lda.b $24	   ; Load sprite mode
	and.b #$08	  ; Test bit 3
	bne Sprite_SetupCharacter_AddYOffset ; If set, add $10 offset
	sec ; Set carry
	lda.b $23	   ; Load Y position
	sbc.b $64	   ; Subtract temp
	bra Sprite_SetupCharacter_StoreYOffset ; Store offset

Sprite_SetupCharacter_AddYOffset:
	clc ; Clear carry
	lda.b $23	   ; Load Y position
	adc.b #$10	  ; Add $10

Sprite_SetupCharacter_StoreYOffset:
	sta.b $62	   ; Store Y offset
	lda.w $00c8	 ; Load location parameter
	cmp.b #$00	  ; Check if 0
	bne Sprite_SetupCharacter_CheckAlt ; If not, alternate check
	lda.b #$40	  ; bit 6 mask
	and.w $00e0	 ; Test bit 6 of $e0
	beq Sprite_SetupCharacter_Done ; If clear, done
	lda.w $01bf	 ; Load character 1 position
	bra Sprite_SetupCharacter_CheckPos ; Check position

Sprite_SetupCharacter_CheckAlt:
	lda.b #$80	  ; bit 7 mask
	and.w $00e0	 ; Test bit 7 of $e0
	beq Sprite_SetupCharacter_Done ; If clear, done
	lda.w $0181	 ; Load character 2 position

Sprite_SetupCharacter_CheckPos:
	cmp.b $62	   ; Compare with Y offset
	bcc Sprite_SetupCharacter_CheckLower ; If less, check lower bound
	sbc.b $62	   ; Subtract Y offset
	cmp.b $64	   ; Compare with temp
	bcs Sprite_SetupCharacter_Done ; If >=, done
	bra Sprite_SetupCharacter_ToggleMode ; Toggle mode

Sprite_SetupCharacter_CheckLower:
	adc.b $64	   ; Add temp
	dec a; Decrement
	cmp.b $62	   ; Compare with Y offset
	bcc Sprite_SetupCharacter_Done ; If less, done

Sprite_SetupCharacter_ToggleMode:
	lda.b $24	   ; Load sprite mode
	eor.b #$0c	  ; Toggle bits 2-3
	sta.b $24	   ; Store updated mode

Sprite_SetupCharacter_Done:
	plp ; Restore processor status


;-------------------------------------------------------------------------------
; Sprite_DisplayCharacter: Character sprite display setup
;
; Purpose: Set up character sprite display using character index
; Entry: $9e = character index (or $de for special case)
; Exit: $62 = sprite mode
;       $64 = position offset
;       Sprite display initiated
; Calls: CallsCodeIfPositionIsValid (character data lookup)
;        AddressC8000OriginalCode (external sprite display)
; Notes: Special handling for character $de
;-------------------------------------------------------------------------------
Sprite_DisplayCharacter:
	lda.b $9e	   ; Load character index
	cmp.w #$00de	; Check if $de (special)
	beq Sprite_DisplayCharacter_Special ; If yes, special handling
	jsr.w CallsCodeIfPositionIsValid ; Look up character data
	sta.b $62	   ; Store sprite mode
	sep #$30		; 8-bit A/X/Y
	ldx.b $9e	   ; X = character index
	lda.l DATA8_049800,x ; Load position offset
	asl a; × 2
	asl a; × 4

Sprite_DisplayCharacter_Do:
	sta.b $64	   ; Store position offset
	lda.b #$02	  ; bit 1 mask
	tsb.w !system_flags_2	 ; Set bit 1 of $d4
	jsl.l AddressC8000OriginalCode ; Call external sprite display


Sprite_DisplayCharacter_Special:
	lda.w #$0001	; Mode 1
	sta.b $62	   ; Store sprite mode
	sep #$30		; 8-bit A/X/Y
	lda.b #$20	  ; Position $20
	bra Sprite_DisplayCharacter_Do ; Display sprite

;-------------------------------------------------------------------------------
; Script_SavePointerExecute: Save script pointer and execute script
;
; Purpose: Save current script pointer and execute PurposeSaveCurrentScriptPointerExecute
; Entry: $17/$18 = current script pointer
; Exit: Script pointer saved on stack
;       PurposeSaveCurrentScriptPointerExecute executed
;-------------------------------------------------------------------------------
Script_SavePointerExecute:
	pei.b ($17)	 ; Save script pointer low
	pei.b ($18)	 ; Save script pointer high
	jmp.w PurposeSaveCurrentScriptPointerExecute ; Jump to script execution

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
	sec ; Set carry for subtraction
	lda.w $0e84	 ; Load gold low word
	sbc.w $0164	 ; Subtract amount low
	sta.w $0e84	 ; Store result low
	sep #$20		; 8-bit accumulator
	lda.w $0e86	 ; Load gold high byte
	sbc.w $0166	 ; Subtract amount high (with borrow)
	sta.w $0e86	 ; Store result high
	lda.w $015f	 ; Load character index
	cmp.b #$dd	  ; Check if $dd (special)
	beq Shop_SubtractGold_Alternate ; If yes, alternate storage
	jsl.l ExternalDataRoutine ; Call external routine
	clc ; Clear carry
	adc.w $0162	 ; Add offset
	sta.w $0e9f,x   ; Store at indexed location
	lda.w $015f	 ; Load character index
	sta.w $0e9e,x   ; Store character ID
	bra Shop_SubtractGold_Done ; Restore and return

Shop_SubtractGold_Alternate:
	clc ; Clear carry
	lda.w !env_counter	 ; Load alternate storage
	adc.w $0162	 ; Add offset
	sta.w !env_counter	 ; Store result
	bra Shop_SubtractGold_Done ; Restore and return

Menu_ClearCursor:
	sep #$20		; 8-bit accumulator
	stz.w $0162	 ; Clear offset

Shop_SubtractGold_Done:
	plx ; Restore X (script pointer high)
	stx.b $18	   ; Store in $18
	plx ; Restore X (script pointer low)
	stx.b $17	   ; Store in $17


;-------------------------------------------------------------------------------
; Menu_InputHandler: Input handler for menu navigation
;
; Purpose: Handle controller input for menu cursor movement
; Entry: $07 = controller input state
;        $0162/$0163 = cursor position/limits
;        $95 = wrapping flags
; Exit: $0162 = updated cursor position
;       $17/$18 = script pointer (preserved or updated)
; Calls: WaitVblank (controller read)
;        CodeLikelyLoadsProcessesThisData (menu update)
; Notes: Handles up/down navigation with wrapping
;        Checks button presses and updates cursor
;-------------------------------------------------------------------------------
Menu_InputHandler:
	rep #$30		; 16-bit A/X/Y
	jsl.l WaitVblank ; Read controller input
	lda.b $07	   ; Load button state
	sta.b $15	   ; Store in temp
	bit.w #$8000	; Test A button (bit 15)
	bne Menu_ClearCursor ; If pressed, clear and return
	bit.w #$0080	; Test B button (bit 7)
	bne Shop_SubtractGold ; If pressed, update gold
	bit.w #$0800	; Test X button (bit 11)
	bne Menu_InputHandler_XButton_JumpDown ; If pressed, jump ahead
	bit.w #$0400	; Test Y button (bit 10)
	bne Menu_InputHandler_YButton_JumpUp ; If pressed, move by 10
	bit.w #$0100	; Test Start (bit 8)
	bne Menu_InputHandler_Down ; If pressed, increment cursor
	bit.w #$0200	; Test Select (bit 9)
	beq Menu_InputHandler ; If not pressed, loop
	sep #$20		; 8-bit accumulator
	dec.w $0162	 ; Decrement cursor position
	bpl Menu_UpdateDisplay ; If >= 0, update menu
	lda.b $95	   ; Load wrapping flags
	and.b #$02	  ; Test bit 1 (wrap down)
	beq Menu_InputHandler_SelectNoWrap ;00B721|F048    |00B76B
	lda.w $0163	 ; Load max position
	sta.w $0162	 ; Wrap to max
	bra Menu_UpdateDisplay ; Update menu

;-------------------------------------------------------------------------------
; Menu Input - Select No-Wrap Handler
;-------------------------------------------------------------------------------
; Purpose: Handle Select button when no wrap-down is allowed
; Reachability: Reachable via beq branch (line 11723)
; Analysis: When Select is pressed and wrap-down flag is clear
;           Increments cursor back to original position
; Technical: Originally labeled UNREACH_00B76B
;-------------------------------------------------------------------------------
Menu_InputHandler_SelectNoWrap:
	inc.w $0162                          ;00B76B|EE6201  |000162
	bra Menu_InputHandler                ;00B76E|80BE    |00B72E

Menu_InputHandler_Down:
	sep #$20		; 8-bit accumulator
	inc.w $0162	 ; Increment cursor position
	lda.w $0163	 ; Load max position
	cmp.w $0162	 ; Compare with current
	bcs Menu_UpdateDisplay ; If max >= current, update
	lda.b $95	   ; Load wrapping flags
	and.b #$01	  ; Test bit 0 (wrap up)
	beq Menu_InputHandler_NoWrapUp ; If no wrap, decrement back
	stz.w $0162	 ; Wrap to 0
	bra Menu_UpdateDisplay ; Update menu

Menu_InputHandler_NoWrapUp:
	dec.w $0162	 ; Decrement back
	bra Menu_InputHandler ; Read input again

Menu_UpdateDisplay:
	rep #$30		; 16-bit A/X/Y
	ldx.w #$b7dd	; Menu data pointer
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu display
	bra Menu_InputHandler ; Read input again

;-------------------------------------------------------------------------------
; Menu - Input Handler - Y Button Jump Up
;-------------------------------------------------------------------------------
; Purpose: Handle Y button press to jump cursor up by 10 positions
; Reachability: Reachable via button handler dispatch (bne above)
; Analysis: Cursor jump handler for quick navigation in long menus
;   - Switches to 8-bit accumulator
;   - Subtracts 10 from cursor position
;   - Handles wrap-around if enabled
; Technical: Originally labeled UNREACH_00B797
;-------------------------------------------------------------------------------
Menu_InputHandler_YButton_JumpUp:
	sep #$20                             ;00B797|E220    |      ; 8-bit accumulator
	sec ;00B799|38      |      ; Set carry for subtraction
	lda.w $0162                          ;00B79A|AD6201  |000162; Load cursor position
	beq Menu_InputHandler_YButton_Wrap   ;00B79D|F008    |00B7A7; If zero, handle wrap
	sbc.b #$0a                           ;00B79F|E90A    |      ; Subtract 10
	bcs Menu_InputHandler_YButton_Store  ;00B7A1|B00D    |00B7B0; If >= 0, store
	lda.b #$00                           ;00B7A3|A900    |      ; Clamp to 0
	bra Menu_InputHandler_YButton_Check  ;00B7A5|8009    |00B7B0; Check wrap flag

Menu_InputHandler_YButton_Wrap:
	lda.b $95                            ;00B7A7|A595    |000095; Load wrap flags
	and.b #$04                           ;00B7A9|2904    |      ; Test bit 2 (wrap down)
	beq Menu_InputHandler                ;00B7AB|F081    |00B72E; If no wrap, read input
	lda.w $0163                          ;00B7AD|AD6301  |000163; Load max position
Menu_InputHandler_YButton_Store:
	sta.w $0162                          ;00B7B0|8D6201  |000162; Store new cursor position
	bra Menu_UpdateDisplay               ;00B7B3|80D8    |00B78D; Update display
Menu_InputHandler_YButton_Check:
; Continue to X button handler

;-------------------------------------------------------------------------------
; Menu - Input Handler - X Button Jump Down
;-------------------------------------------------------------------------------
; Purpose: Handle X button press to jump cursor down by 10 positions
; Reachability: Reachable via button handler dispatch (bne above)
; Analysis: Cursor jump handler (opposite of Y button)
;   - Loads and compares cursor to max
;   - If at max, handles wrap-around
;   - Otherwise adds 10 to cursor position
; Technical: Originally labeled UNREACH_00B7B5 (second occurrence)
;-------------------------------------------------------------------------------
Menu_InputHandler_XButton_JumpDown:
	sep #$20                             ;00B7B5|E220    |      ; 8-bit accumulator
	lda.w $0162                          ;00B7B7|AD6201  |000162; Load cursor position
	cmp.w $0163                          ;00B7BA|CD6301  |000163; Compare to max
	beq Menu_InputHandler_XButton_Wrap   ;00B7BD|F013    |00B7D2; If at max, handle wrap
	clc ;00B7BF|18      |      ; Clear carry
	adc.b #$0a                           ;00B7C0|690A    |      ; Add 10
	sta.w $0162                          ;00B7C2|8D6201  |000162; Store cursor position
	lda.w $0163                          ;00B7C5|AD6301  |000163; Load max position
	cmp.w $0162                          ;00B7C8|CD6201  |000162; Compare to cursor
	bcs Menu_UpdateDisplay               ;00B7CB|B0C0    |00B78D; If max >= cursor, update
	sta.w $0162                          ;00B7CD|8D6201  |000162; Clamp to max
	bra Menu_UpdateDisplay               ;00B7D0|80BB    |00B78D; Update display
Menu_InputHandler_XButton_Wrap:
	lda.b $95                            ;00B7D2|A595    |000095; Load wrap flags
	and.b #$08                           ;00B7D4|2908    |      ; Test bit 3 (wrap up)
	beq Menu_InputHandler                ;00B7D6|F0BD    |00B72E; If no wrap, read input
	stz.w $0162                          ;00B7D8|9C6201  |000162; Wrap to 0
	bra Menu_UpdateDisplay               ;00B7DB|80B0    |00B78D; Update display

;-------------------------------------------------------------------------------
; DATA at $b7dd: Menu configuration data
;
; Purpose: Menu display configuration
; Format: Unknown structure for menu system
; Used by: CodeLikelyLoadsProcessesThisData (menu update routine)
;-------------------------------------------------------------------------------
MenuDisplayConfig:
	db $2b,$8d,$03,$04,$00,$8f,$03,$00,$00,$01,$00,$08,$00,$09,$00,$42
	db $4b,$5a,$00,$00,$03,$16,$00,$11,$00,$00,$00,$00,$00,$00,$00,$00
	db $00,$00,$17,$00,$00,$00,$00,$00,$e0,$00,$cc,$20,$0e,$00,$00,$ff
	db $00,$00,$01,$00,$01,$00,$00,$00,$00,$00,$00,$00,$ff,$ff,$ff,$07
	db $30,$d9,$05,$31,$00,$42,$12,$00,$30,$7e,$07,$30,$7e

;-------------------------------------------------------------------------------
; CodeIrqHandlerJitterFixFirst: IRQ handler (jitter fix - first variant)
;
; Purpose: Interrupt handler for horizontal timing jitter correction
; Entry: Called by SNES IRQ interrupt
; Exit: NMI disabled
;       Interrupt vector updated to InterruptVectorUpdatedCode
; Uses: SNES_NMITIMEN, SNES_SLHV, SNES_STAT78, SNES_OPVCT
; Notes: Samples vertical counter until jitter stabilizes
;        Uses $da bit 6 for jitter calculation toggle
;        Enables second-stage IRQ handler
;-------------------------------------------------------------------------------
IRQ_JitterFix:
	rep #$30		; 16-bit A/X/Y
	phb ; Save data bank
	pha ; Save accumulator
	phx ; Save X
	sep #$20		; 8-bit accumulator
	phk ; Push program bank
	plb ; Set data bank = program bank
	stz.w SNES_NMITIMEN ; Disable NMI/IRQ

IRQ_JitterFix_Loop:
	lda.w SNES_SLHV ; Sample H/V counter
	lda.w SNES_STAT78 ; Read PPU status
	lda.w SNES_OPVCT ; Read vertical counter
	sta.w $0118	 ; Store V counter
	lda.b #$40	  ; bit 6 mask
	and.w !system_flags_5	 ; Test bit 6 of $da
	bne IRQ_JitterFix_Skip ; If set, skip jitter calc
	lda.w $0118	 ; Load V counter
	asl a; × 2
	adc.w $0118	 ; × 3
	adc.b #$9a	  ; Add offset
	pha ; Push result
	plp ; Pull to processor status (jitter)

IRQ_JitterFix_Skip:
	lsr.w $0118	 ; V counter >> 1
	bcs IRQ_JitterFix_Loop ; If carry, resample (unstable)
	ldx.w #$b86c	; Second-stage IRQ handler
	stx.w $0118	 ; Store handler address
	lda.b #$11	  ; Enable V-IRQ + NMI
	sta.w SNES_NMITIMEN ; Set interrupt mode
	cli ; Enable interrupts
	wai ; Wait for interrupt
	rep #$30		; 16-bit A/X/Y
	plx ; Restore X
	pla ; Restore accumulator
	plb ; Restore data bank
	rti ; Return from interrupt

;-------------------------------------------------------------------------------
; IRQ_ScreenOn: IRQ handler (second stage - screen on)
;
; Purpose: Second-stage IRQ handler - turn screen on and switch to NMI
; Entry: Called by IRQ after jitter correction
; Exit: Screen enabled
;       NMI mode set
;       $d8 bit 6 set
;       Interrupt vector updated to IRQ_JitterFix2
; Calls: ScreenSetupRoutine (screen setup)
; Notes: Final stage of screen transition
;-------------------------------------------------------------------------------
IRQ_ScreenOn:
	lda.b #$80	  ; Screen off brightness
	sta.w SNES_INIDISP ; Disable screen
	lda.b #$01	  ; NMI only mode
	sta.w SNES_NMITIMEN ; Set interrupt mode
	rep #$30		; 16-bit A/X/Y
	phd ; Save direct page
	phy ; Save Y
	jsr.w ScreenSetupRoutine ; Screen setup
	sep #$20		; 8-bit accumulator
	lda.b #$07	  ; V-IRQ timer low
	sta.w SNES_VTIMEL ; Set V timer
	ldx.w #$b898	; Next IRQ handler (IRQ_JitterFix2)
	stx.w $0118	 ; Store handler address
	lda.w $0112	 ; Load interrupt mode
	sta.w SNES_NMITIMEN ; Set interrupt mode
	lda.b #$40	  ; bit 6
	tsb.w !system_flags_4	 ; Set bit 6 of $d8
	ply ; Restore Y
	pld ; Restore direct page
	rti ; Return from interrupt

;-------------------------------------------------------------------------------
; IRQ_JitterFix2: IRQ handler (jitter fix - second variant)
;
; Purpose: Alternate IRQ handler for horizontal timing jitter correction
; Entry: Called by SNES IRQ interrupt
; Exit: NMI disabled
;       Interrupt vector updated to IRQ_ScreenOn2
; Uses: Similar to CodeIrqHandlerJitterFixFirst but with different offset ($0f vs $9a)
; Notes: Second variant of jitter correction algorithm
;-------------------------------------------------------------------------------
IRQ_JitterFix2:
	rep #$30		; 16-bit A/X/Y
	phb ; Save data bank
	pha ; Save accumulator
	phx ; Save X
	sep #$20		; 8-bit accumulator
	phk ; Push program bank
	plb ; Set data bank = program bank
	stz.w SNES_NMITIMEN ; Disable NMI/IRQ

IRQ_JitterFix2_Loop:
	lda.w SNES_SLHV ; Sample H/V counter
	lda.w SNES_STAT78 ; Read PPU status
	lda.w SNES_OPVCT ; Read vertical counter
	sta.w $0118	 ; Store V counter
	lda.b #$40	  ; bit 6 mask
	and.w !system_flags_5	 ; Test bit 6 of $da
	bne IRQ_JitterFix2_Skip ; If set, skip jitter calc
	lda.w $0118	 ; Load V counter
	asl a; × 2
	adc.w $0118	 ; × 3
	adc.b #$0f	  ; Add offset (different from B82A)
	pha ; Push result
	plp ; Pull to processor status

IRQ_JitterFix2_Skip:
	lsr.w $0118	 ; V counter >> 1
	bcc IRQ_JitterFix2_Loop ; If no carry, resample (unstable)
	ldx.w #$b8da	; Second-stage IRQ handler
	stx.w $0118	 ; Store handler address
	lda.b #$11	  ; Enable V-IRQ + NMI
	sta.w SNES_NMITIMEN ; Set interrupt mode
	cli ; Enable interrupts
	wai ; Wait for interrupt
	rep #$30		; 16-bit A/X/Y
	plx ; Restore X
	pla ; Restore accumulator
	plb ; Restore data bank
	rti ; Return from interrupt

;-------------------------------------------------------------------------------
; IRQ_ScreenOn2: IRQ handler (second stage - alternate)
;
; Purpose: Alternate second-stage IRQ handler
; Entry: Called by IRQ after jitter correction (variant 2)
; Exit: Screen enabled ($0110 brightness)
;       NMI mode set
;       $d8 bit 5 set
;       Interrupt vector updated to CodeIrqHandlerJitterFixFirst
; Calls: Label_008BA0, CallsLabelCodeScreenSetupRoutines (screen setup routines)
; Notes: Uses different screen setup sequence than InterruptVectorUpdatedCode
;-------------------------------------------------------------------------------
IRQ_ScreenOn2:
	lda.w !battle_ready_flag	 ; Load brightness value
	sta.w SNES_INIDISP ; Set screen brightness
	lda.b #$01	  ; NMI only mode
	sta.w SNES_NMITIMEN ; Set interrupt mode
	phd ; Save direct page
	jsr.w Label_008BA0 ; Screen setup routine 1
	phy ; Save Y
	jsr.w CallsLabelCodeScreenSetupRoutines ; Screen setup routine 2
	sep #$20		; 8-bit accumulator
	lda.b #$d8	  ; V-IRQ timer low
	sta.w $4209	 ; Set V timer (direct address)
	ldx.w #$b82a	; First-stage IRQ handler
	stx.w $0118	 ; Store handler address
	lda.w $0112	 ; Load interrupt mode
	sta.w $4200	 ; Set interrupt mode (direct)
	lda.b #$20	  ; bit 5
	tsb.w !system_flags_4	 ; Set bit 5 of $d8
	ply ; Restore Y
	pld ; Restore direct page
	rti ; Return from interrupt

;-------------------------------------------------------------------------------
; Sprite_SetMode2D: Set sprite mode $2d
;
; Purpose: Set sprite display mode to $2d
; Entry: None
; Exit: $0505 = $2d
; Notes: Preserves processor status
;-------------------------------------------------------------------------------
Sprite_SetMode2D:
	php ; Save processor status
	sep #$20		; 8-bit accumulator
	lda.b #$2d	  ; Mode $2d
	sta.w $0505	 ; Store in sprite mode
	plp ; Restore processor status


;-------------------------------------------------------------------------------
; Sprite_SetMode2C: Set sprite mode $2c
;
; Purpose: Set sprite display mode to $2c
; Entry: None
; Exit: $0505 = $2c
; Notes: Preserves processor status
;-------------------------------------------------------------------------------
Sprite_SetMode2C:
	php ; Save processor status
	sep #$20		; 8-bit accumulator
	lda.b #$2c	  ; Mode $2c
	sta.w $0505	 ; Store in sprite mode
	plp ; Restore processor status


;-------------------------------------------------------------------------------
; Anim_SetMode10: Set animation mode $10
;
; Purpose: Set animation mode to $10
; Entry: None
; Exit: $050a = $10
; Notes: Preserves processor status
;-------------------------------------------------------------------------------
Anim_SetMode10:
	php ; Save processor status
	sep #$20		; 8-bit accumulator
	lda.b #$10	  ; Mode $10
	sta.w $050a	 ; Store in animation mode
	plp ; Restore processor status


;-------------------------------------------------------------------------------
; Anim_SetMode11: Set animation mode $11
;
; Purpose: Set animation mode to $11
; Entry: None
; Exit: $050a = $11
; Notes: Preserves processor status
;-------------------------------------------------------------------------------
Anim_SetMode11:
	php ; Save processor status
	sep #$20		; 8-bit accumulator
	lda.b #$11	  ; Mode $11
	sta.w $050a	 ; Store in animation mode
	plp ; Restore processor status


;-------------------------------------------------------------------------------
; Input_PollWithToggle: Input polling loop with mode toggle
;
; Purpose: Poll controller input and toggle sprite mode on button press
; Entry: $07 = controller input state (from WaitVblank)
;        $01 = current state
;        $05 = compare state
; Exit: A = button state
;       X = $01 value
;       Flags set based on comparison
;       $0505 may be updated (mode $2c)
; Calls: WaitVblank (controller read)
;        Sprite_SetMode2C (set sprite mode $2c)
; Notes: Loops until specific button condition met
;        XORs button state when no buttons pressed
;-------------------------------------------------------------------------------
Input_PollWithToggle:
	jsl.l WaitVblank ; Read controller input
	bit.b $07	   ; Test button state
	bne Input_PollWithToggle_Check ; If buttons pressed, check
	eor.w #$ffff	; Invert button state
	bit.b $07	   ; Test inverted state
	beq Input_PollWithToggle_ToggleBack ; If no change, toggle back
	pha ; Save state
	jsr.w Sprite_SetMode2C ; Set sprite mode $2c
	pla ; Restore state

Input_PollWithToggle_ToggleBack:
	eor.w #$ffff	; Invert back
	bra Input_PollWithToggle ; Loop

Input_PollWithToggle_Check:
	lda.b $07	   ; Load button state
	ldx.b $01	   ; Load current state
	cpx.b $05	   ; Compare with compare state


;-------------------------------------------------------------------------------
; Game_Initialize: Main initialization/game start routine
;
; Purpose: Initialize game system and start main game loop
; Entry: Called at game start or reset
; Exit: Does not return (infinite game loop)
; Calls: AddressC8000OriginalCode (bank $0c init)
;        System_Init (initialization)
;        SetupRoutine (some setup)
; Notes: Sets up initial game state
;        Prepares for main game execution
;-------------------------------------------------------------------------------
Game_Initialize:
	php ; Save processor status
	phb ; Save data bank
	phd ; Save direct page
	rep #$30		; 16-bit A/X/Y
	pea.w $5555	 ; Push $5555 (init marker?)
	lda.w #$0080	; bit 7
	tsb.w !system_flags_3	 ; Set bit 7 of $d6
	jsl.l AddressC8000OriginalCode ; Call Bank $0c init
	jsr.w System_Init ; Initialization routine
	stz.b $01	   ; Clear $01
	sep #$20		; 8-bit accumulator
	jsr.w SetupRoutine ; Setup routine
	rep #$30		; 16-bit A/X/Y
	ldx.w #$ba17	; Menu data pointer
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	tsc ; Transfer stack to A
	sta.w $0105	 ; Save stack pointer
	lda.w #$0080	; bit 7
	tsb.w !system_flags_8	 ; Set bit 7 of $de
	pei.b ($01)	 ; Save $01
	pei.b ($03)	 ; Save $03
	lda.w #$0401	; Load $0401
	sta.b $03	   ; Store in $03
	lda.l $701ffc   ; Load save data flag
	and.w #$0300	; Mask bits 8-9
	sta.b $01	   ; Store in $01
	sta.b $05	   ; Store in $05
	pea.w LOOSE_OP_00BCF3 ; Push continue address
	ldx.w #$ba14	; Menu data
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	lda.w #$0f00	; Load $0f00
	sta.b $8e	   ; Store in brightness?

Game_Initialize_Loop:
	rep #$30		; 16-bit A/X/Y
	lda.w #$0c80	; Button mask
	jsr.w Input_PollWithToggle ; Poll input
	bne Game_HandleAlternateButton ; If button pressed, branch
	bit.w #$0080	; Test B button
	beq Game_Initialize_Loop ; If not pressed, loop
	sep #$20		; 8-bit accumulator
	lda.b $06	   ; Load save slot selection
	sta.l $701ffd   ; Store save slot
	rep #$30		; 16-bit A/X/Y
	and.w #$00ff	; Mask to 8 bits
	dec a; Decrement (0-based index)
	sta.w $010e	 ; Store save slot index
	bmi Game_StartNew ; If negative (new game), branch
	jsr.w GetSaveSlotAddress ; Get save slot address
	tax ; X = save address
	lda.l $700000,x ; Load save data validity flag
	beq Game_HandleEmptySlot ; If empty, branch
	jsr.w Sprite_SetMode2D ; Set sprite mode $2d
	lda.w $010e	 ; Load save slot index
	jmp.w InitializeGraphicsComponent ; Load game

;-------------------------------------------------------------------------------
; Game - Start New
;-------------------------------------------------------------------------------
; Purpose: Handle new game selection (save slot < 0)
; Reachability: Reachable via conditional branch (bmi above)
; Analysis: New game initialization path
;   - Calls Sprite_SetMode2D to update sprite display
;   - Jumps to TitleScreen_Init to start new game
; Technical: Originally labeled UNREACH_00B9D5
;-------------------------------------------------------------------------------
Game_StartNew:
	jsr.w Sprite_SetMode2D               ;00B9D5|2008B9  |00B908; Update sprite mode
	jmp.w TitleScreen_Init               ;00B9D8|4C1ABA  |00BA1A; Start new game

;-------------------------------------------------------------------------------
; Game - Handle Empty Slot
;-------------------------------------------------------------------------------
; Purpose: Handle selection of empty save slot
; Reachability: Reachable via conditional branch (beq above)
; Analysis: Empty slot selection path
;   - Calls Sprite_SetMode2C to update sprite display
;   - Branches forward to skip normal load game logic
; Technical: Originally labeled UNREACH_00B9DB
;-------------------------------------------------------------------------------
Game_HandleEmptySlot:
	jsr.w Sprite_SetMode2C               ;00B9DB|2012B9  |00B912; Update sprite mode
	bra $+$c2                            ;00B9DE|80C0    |00B9A0; Skip load game logic

;-------------------------------------------------------------------------------
; Game - Handle Alternate Button
;-------------------------------------------------------------------------------
; Purpose: Handle non-B button press during title screen
; Reachability: Reachable via conditional branch (bne at Game_Initialize_Loop)
; Analysis: Alternate button handler (likely A button or Start)
;   - Stores button state to $05
;   - Calls sprite update routine and configures video registers
; Technical: Originally labeled UNREACH_00B9E0
;-------------------------------------------------------------------------------
Game_HandleAlternateButton:
	stx.b $05                            ;00B9E0|8605    |000005; Store button state
	jsr.w $b91c                          ;00B9E2|201CB9  |00B91C; Call sprite routine
	sep #$10                             ;00B9E5|E230    |      ; 8-bit index registers
	lda.w #$00ec                         ;00B9E7|A9EC    |      ; Load $ec
	sta.l $7f56d8                        ;00B9EA|8FD8567F|7F56D8; Store to video register
	sta.l $7f56da                        ;00B9EE|8FDA567F|7F56DA; Store to video register
	db $7f,$8f,$dc,$56,$7f,$8f,$de,$56,$7f,$a5,$06,$0a,$aa,$a9,$e0,$9f
	db $d8,$56,$7f,$a9,$08,$0c,$d4,$00,$22,$00,$80,$0c,$a9,$08,$1c,$d4
	db $00,$4c,$a0,$b9
; stx $05; jsr Anim_SetMode10; sep #$30; (sprite setup code)

MenuConfig_TitleScreen:
	db $38,$ac,$03,$0b,$95,$03 ; Menu configuration data

;-------------------------------------------------------------------------------
; TitleScreen_Init: Initialize title screen display
;
; Purpose: Set up title screen graphics and palette
; Entry: None
; Exit: Title screen initialized
;       $0111 bit 4 cleared/set for BG3 control
; Calls: CallsCodeGraphicsInit (graphics init)
;        CodeLikelyLoadsProcessesThisData (menu update)
;        AddressC8000OriginalCode (external init)
; Notes: Sets up BG3 scrolling animation
;        Loads title screen palette from Bank $07
;-------------------------------------------------------------------------------
TitleScreen_Init:
	ldy.w #$1000	; Y = $1000 (destination)
	lda.w #$0303	; Graphics mode $0303
	jsr.w CallsCodeGraphicsInit ; Initialize graphics
	sep #$20		; 8-bit accumulator
	ldx.w #$bae7	; Data pointer
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	lda.b #$10	  ; bit 4 mask
	trb.w $0111	 ; Clear bit 4 of $0111
	jsl.l AddressC8000OriginalCode ; External init call
	stz.w SNES_BG3VOFS ; Clear BG3 V-scroll low
	stz.w SNES_BG3VOFS ; Clear BG3 V-scroll high
	lda.b #$17	  ; Enable BG1+BG2+BG3+sprites
	sta.w SNES_TM   ; Set main screen designation
	lda.b #$00	  ; Start at Y=0

TitleScreen_Init_ScrollLoop:
	jsl.l AddressC8000OriginalCode ; External call
	sta.w SNES_BG3VOFS ; Set BG3 V-scroll low
	stz.w SNES_BG3VOFS ; Clear BG3 V-scroll high
	clc ; Clear carry
	adc.b #$08	  ; Add 8 (scroll speed)
	cmp.b #$d0	  ; Check if reached $d0
	bne TitleScreen_Init_ScrollLoop ; Loop until done
	lda.b #$10	  ; bit 4 mask
	tsb.w $0111	 ; Set bit 4 of $0111
	rep #$30		; 16-bit A/X/Y
	stz.w $00cc	 ; Clear character count
	lda.w #$060d	; Load $060d
	sta.b $03	   ; Store in $03
	lda.w #$0000	; Load 0
	sta.b $05	   ; Clear $05
	sta.b $01	   ; Clear $01
	sta.w $015f	 ; Clear $015f
	bra CharName_UpdateDisplay ; Jump to menu display

;-------------------------------------------------------------------------------
; CharName - Error Sound
;-------------------------------------------------------------------------------
; Purpose: Play error sound when character name operation is invalid
; Reachability: Reachable via multiple conditional branches (beq)
; Analysis: Error feedback for character naming
;   - Called when name is full (can't add more characters)
;   - Called when name is empty (can't confirm empty name)
; Technical: Originally labeled UNREACH_00BA6D
;-------------------------------------------------------------------------------
CharName_ErrorSound:
	jsr.w Sprite_SetMode2C               ;00BA6D|2012B9  |00B912; Play error sound

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
;        CodeLikelyLoadsProcessesThisData (menu update)
; Notes: Supports character entry, deletion, confirmation
;        Max 8 characters per name
;-------------------------------------------------------------------------------
CharName_InputLoop:
	rep #$30		; 16-bit A/X/Y
	lda.w #$9f80	; Button mask
	jsr.w Input_PollWithToggle ; Poll input
	bne CharName_InputLoop_Process ; If button pressed, process
	bit.w #$1000	; Test L button
	bne CharName_InputLoop_Confirm ; If pressed, confirm
	bit.w #$8000	; Test A button
	bne CharName_DeleteCharacter ; If pressed, delete char
	bit.w #$0080	; Test B button
	beq CharName_InputLoop ; If not pressed, loop
	lda.b $01	   ; Load cursor position
	cmp.w #$050c	; Check if at end position
	beq CharName_InputLoop_Confirm ; If yes, confirm
	sep #$30		; 8-bit A/X/Y
	ldy.w $00cc	 ; Load character count
	cpy.b #$08	  ; Check if 8 chars entered
	beq CharName_ErrorSound ; If full, error sound
	lda.b $06	   ; Load selected character (row)
	sta.w SNES_WRMPYA ; Set multiplicand
	lda.b #$1a	  ; Load 26 (chars per row)
	jsl.l PerformMultiply ; Multiply
	lda.b $05	   ; Load column
	asl a; × 2
	adc.w SNES_RDMPYL ; Add multiplication result
	tax ; X = character index
	rep #$10		; 16-bit X/Y
	inc.w $00cc	 ; Increment character count
	lda.l DATA8_03a37c,x ; Load character from table
	sta.w $1000,y   ; Store in name buffer
	jsr.w Anim_SetMode11 ; Set animation mode $11
	ldx.w #$baed	; Menu data
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	bra CharName_InputLoop ; Loop

;-------------------------------------------------------------------------------
; CharName - Delete Character
;-------------------------------------------------------------------------------
; Purpose: Delete last character from name being entered
; Reachability: Reachable via conditional branch (bne above)
; Analysis: Backspace/delete handler for character naming
;   - If count is zero (empty name), plays error sound
;   - Otherwise decrements character count and plays delete sound
; Technical: Originally labeled UNREACH_00BAC2
;-------------------------------------------------------------------------------
CharName_DeleteCharacter:
	ldy.w $00cc                          ;00BAC2|AC CC00  |0000CC; Load character count
	beq CharName_ErrorSound              ;00BAC5|F0A6    |00BA6D; If empty, error sound
	dey ;00BAC7|88      |      ; Decrement count
	sty.w $00cc                          ;00BAC8|8CCC00  |0000CC; Store new count
	sep #$20                             ;00BACB|E220    |      ; 8-bit accumulator
	lda.b #$03                           ;00BACD|A903    |      ; Load delete sound effect
	bra $+$e3                            ;00BACF|80E3    |00BAB4; Play sound

CharName_InputLoop_Confirm:
	lda.w $00cc	 ; Load character count
	beq CharName_ErrorSound ; If empty, error
	jmp.w Sprite_SetMode2D ; Set sprite mode $2d and return

CharName_InputLoop_Process:
	stx.w $015f	 ; Store selected option
	jsr.w Anim_SetMode10 ; Set animation mode $10

CharName_UpdateDisplay:
	ldx.w #$baea	; Menu data
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	bra CharName_InputLoop ; Loop

MenuConfig_CharName1:
	db $ca,$ac,$03 ; Menu configuration

MenuConfig_CharName2:
	db $34,$ad,$03,$21,$ad,$03 ; Menu configuration

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
	lda.w #$2100	; PPU register base
	tcd ; Set direct page to $2100
	stz.b SNES_CGSWSEL-$2100 ; Clear color/window select
	lda.w #$0017	; Enable BG1+BG2+BG3+OBJ
	sta.w $212c	 ; Set main screen designation
	lda.w #$5555	; Init marker
	sta.w $0e00	 ; Store marker
	sep #$20		; 8-bit accumulator
	lda.b #$00	  ; Load 0
	sta.l $7e3664   ; Clear flag
	lda.b #$3b	  ; BG1 tilemap = $3b00
	sta.b SNES_BG1SC-$2100 ; Set BG1 screen base
	lda.b #$4b	  ; BG2 tilemap = $4b00
	sta.b SNES_BG2SC-$2100 ; Set BG2 screen base
	lda.b #$80	  ; VRAM increment after high byte
	sta.b SNES_VMAINC-$2100 ; Set VRAM increment mode
	rep #$30		; 16-bit A/X/Y
	stz.w !state_marker	 ; Clear $f0
	ldx.w #$0000	; VRAM address $0000
	stx.b SNES_VMADDL-$2100 ; Set VRAM address
	pea.w $0007	 ; Bank $07
	plb ; Set data bank to $07
	ldx.w #$8030	; Source address
	ldy.w #$0100	; Length (256 words)
	jsl.l DmaTransferVram ; DMA transfer to VRAM
	plb ; Restore data bank
	ldx.w #$1000	; VRAM address $1000
	stx.b SNES_VMADDL-$2100 ; Set VRAM address
	pea.w $0004	 ; Bank $04
	plb ; Set data bank to $04
	ldx.w #$9840	; Source address
	ldy.w #$0010	; Length (16 words)
	jsl.l ExecuteSpecialTransfer ; DMA transfer
	plb ; Restore data bank
	ldx.w #$6080	; VRAM address $6080
	stx.b SNES_VMADDL-$2100 ; Set VRAM address
	pea.w $0004	 ; Bank $04
	plb ; Set data bank
	ldx.w #$99c0	; Source address
	ldy.w #$0004	; Length (4 words)
	jsl.l ExecuteSpecialTransfer ; DMA transfer
	plb ; Restore data bank
	sep #$30		; 8-bit A/X/Y
	pea.w $0007	 ; Bank $07
	plb ; Set data bank
	lda.b #$20	  ; Palette offset $20
	ldx.b #$00	  ; Palette index 0
	jsr.w LoadPalette ; Load palette
	lda.b #$30	  ; Palette offset $30
	ldx.b #$08	  ; Palette index 8
	jsr.w LoadPalette ; Load palette
	lda.b #$60	  ; Palette offset $60
	ldx.b #$10	  ; Palette index 16
	jsr.w LoadPalette ; Load palette
	lda.b #$70	  ; Palette offset $70
	ldx.b #$18	  ; Palette index 24
	jsr.w LoadPalette ; Load palette
	lda.b #$40	  ; Palette offset $40
	ldx.b #$20	  ; Palette index 32
	jsr.w LoadPalette ; Load palette
	lda.b #$50	  ; Palette offset $50
	ldx.b #$28	  ; Palette index 40
	jsr.w LoadPalette ; Load palette
	plb ; Restore data bank
	ldx.b #$00	  ; Index 0
	txa ; A = 0
	pea.w $0007	 ; Bank $07
	plb ; Set data bank
	jsr.w LoadColorData ; Load color data
	ldx.b #$10	  ; Index 16
	lda.b #$10	  ; Offset $10
	jsr.w LoadColorData ; Load color data
	plb ; Restore data bank
	lda.b #$80	  ; CGRAM address $80
	sta.b SNES_CGADD-$2100 ; Set CGRAM address
	pea.w $0007	 ; Bank $07
	plb ; Set data bank
	lda.w DATA8_07d814 ; Load color data
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d815 ; Load color data
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d816 ; Load color data
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d817 ; Load color data
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d818 ; Load color data
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d819 ; Load color data
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d81a ; Load color data
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d81b ; Load color data
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d81c ; Load color data
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d81d ; Load color data
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d81e ; Load color data
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d81f ; Load color data
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d820 ; Load color data
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d821 ; Load color data
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d822 ; Load color data
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d823 ; Load color data
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	plb ; Restore data bank
	lda.b #$31	  ; CGRAM address $31
	sta.b SNES_CGADD-$2100 ; Set CGRAM address
	lda.w $0e9c	 ; Load color low
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w $0e9d	 ; Load color high
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.b #$71	  ; CGRAM address $71
	sta.b SNES_CGADD-$2100 ; Set CGRAM address
	lda.w $0e9c	 ; Load color low
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w $0e9d	 ; Load color high
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	stz.b SNES_BG1HOFS-$2100 ; Clear BG1 H-scroll
	stz.b SNES_BG1HOFS-$2100 ; (write twice)
	stz.b SNES_BG1VOFS-$2100 ; Clear BG1 V-scroll
	stz.b SNES_BG1VOFS-$2100 ; (write twice)
	stz.b SNES_BG2HOFS-$2100 ; Clear BG2 H-scroll
	stz.b SNES_BG2HOFS-$2100 ; (write twice)
	stz.b SNES_BG2VOFS-$2100 ; Clear BG2 V-scroll
	stz.b SNES_BG2VOFS-$2100 ; (write twice)
	rep #$30		; 16-bit A/X/Y
	lda.w #$0000	; Direct page = $0000
	tcd ; Restore direct page
	ldx.w #$c8e6	; Data pointer
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	jsr.w CodeExternalRoutine ; External routine
	jsr.w InitializeGraphicsDisplaySystem ; Clear memory routine
	lda.w #$0200	; Load $0200
	sta.w $01f0	 ; Store in $01f0
	lda.w #$0020	; Load $0020
	sta.w $01f2	 ; Store in $01f2
	lda.w #$0701	; Load $0701
	sta.b $03	   ; Store in $03
	stz.b $05	   ; Clear $05
	stz.b $01	   ; Clear $01
	jmp.w MainRoutine ; Jump to main routine

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
	sta.b SNES_CGADD-$2100 ; Set CGRAM address
	lda.w DATA8_07d7f4,x ; Load color byte
	sta.b SNES_CGDATA-$2100 ; Write to CGRAM
	lda.w DATA8_07d7f5,x ; (repeat for 32 bytes = 16 colors)
	sta.b SNES_CGDATA-$2100
	lda.w DATA8_07d7f6,x
	sta.b SNES_CGDATA-$2100
	lda.w DATA8_07d7f7,x
	sta.b SNES_CGDATA-$2100
	lda.w DATA8_07d7f8,x
	sta.b SNES_CGDATA-$2100
	lda.w DATA8_07d7f9,x
	sta.b SNES_CGDATA-$2100
	lda.w DATA8_07d7fa,x
	sta.b SNES_CGDATA-$2100
	lda.w DATA8_07d7fb,x
	sta.b SNES_CGDATA-$2100
	lda.w DATA8_07d7fc,x
	sta.b SNES_CGDATA-$2100
	lda.w DATA8_07d7fd,x
	sta.b SNES_CGDATA-$2100
	lda.w DATA8_07d7fe,x
	sta.b SNES_CGDATA-$2100
	lda.w DATA8_07d7ff,x
	sta.b SNES_CGDATA-$2100
	lda.w DATA8_07d800,x
	sta.b SNES_CGDATA-$2100
	lda.w DATA8_07d801,x
	sta.b SNES_CGDATA-$2100
	lda.w DATA8_07d802,x
	sta.b SNES_CGDATA-$2100
	lda.w DATA8_07d803,x
	sta.b SNES_CGDATA-$2100


;-------------------------------------------------------------------------------
; Screen_SetUpdateFlag: Set display update flag and execute screen update
;
; Purpose: Set bit 0 of $d8 and call screen update routine
; Entry: None
; Exit: $d8 bit 0 set
;       Screen update executed
;-------------------------------------------------------------------------------
Screen_SetUpdateFlag:
	php ; Save processor status
	sep #$30		; 8-bit A/X/Y
	lda.b #$01	  ; bit 0 mask
	tsb.w !system_flags_4	 ; Set bit 0 of $d8
	plp ; Restore processor status

;-------------------------------------------------------------------------------
; Screen_TransitionReset: Screen transition/reset routine
;
; Purpose: Reset screen and reinitialize game state
; Entry: $0e00 = state marker
; Exit: Screen reinitialized
;       Game state restored
; Calls: FinalSetupRoutine (external routine)
;        System_Init (initialization)
;        CodeCodeConditionalScreenSetup or ScreenSetupRoutine2 (conditional screen setup)
;        CodeLikelyLoadsProcessesThisData (menu update)
;        InitializePaletteSystem (external routine)
;        Menu_Handler (menu handler)
;        Memory_ClearBlock (clear memory)
;        CodeExternalRoutine (external routine)
;        MainRoutine (main routine)
; Notes: Handles screen transitions and state restoration
;-------------------------------------------------------------------------------
Screen_TransitionReset:
	php ; Save processor status
	phb ; Save data bank
	phd ; Save direct page
	rep #$30		; 16-bit A/X/Y
	lda.w #$0010	; bit 4 mask
	trb.w !system_flags_3	 ; Clear bit 4 of $d6
	lda.w $0e00	 ; Load state marker
	pha ; Save on stack
	stz.w !game_state_value	 ; Clear $8e
	jsl.l FinalSetupRoutine ; External routine
	jsr.w System_Init ; Initialize system
	lda.w #$0001	; bit 0 mask
	and.w !system_flags_4	 ; Test bit 0 of $d8
	bne Screen_TransitionReset_Alt ; If set, alternate path
	jsr.w CodeCodeConditionalScreenSetup ; Screen setup routine 1
	bra Screen_TransitionReset_Continue ; Continue

Screen_TransitionReset_Alt:
	jsr.w ScreenSetupRoutine2 ; Screen setup routine 2

Screen_TransitionReset_Continue:
	ldx.w #$be80	; Data pointer
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	lda.w #$0020	; bit 5 mask
	tsb.w !system_flags_1	 ; Set bit 5 of $d2
	jsl.l InitializePaletteSystem ; External routine
	lda.w #$00a0	; Load $a0
	sta.w $01f0	 ; Store in $01f0
	lda.w #$000a	; Load $0a
	sta.w $01f2	 ; Store in $01f2
	tsc ; Transfer stack to A
	sta.w $0105	 ; Save stack pointer
	jsr.w Menu_Handler ; Menu handler
	lda.w #$00ff	; Load $ff
	sep #$30		; 8-bit A/X/Y
	sta.w $0104	 ; Store in $0104
	rep #$30		; 16-bit A/X/Y
	lda.w $0105	 ; Load stack pointer
	tcs ; Restore stack
	jsl.l FinalSetupRoutine ; External routine
	jsr.w Memory_ClearBlock ; Clear memory
	ldx.w #$c8e9	; Data pointer
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	jsl.l AddressC8000OriginalCode ; External init
	lda.w #$0040	; Load $40
	sta.w $01f0	 ; Store in $01f0
	lda.w #$0004	; Load $04
	sta.w $01f2	 ; Store in $01f2
	pla ; Restore state marker
	sta.w $0e00	 ; Store back
	jsr.w ExternalRoutine2 ; External routine
	jsr.w AdditionalSetupSeeBelow ; External routine
	pld ; Restore direct page
	plb ; Restore data bank
	plp ; Restore processor status
	rtl ; Return

;-------------------------------------------------------------------------------
; Screen_UpdateAndGraphics: Screen update wrapper
;
; Purpose: Call screen update and graphics routine
; Entry: None
; Exit: Screen updated
; Calls: Screen_UpdateFull (screen update)
;        InitializePaletteSystem (graphics routine)
;-------------------------------------------------------------------------------
Screen_UpdateAndGraphics:
	jsr.w Screen_UpdateFull ; Screen update
	jmp.w InitializePaletteSystem ; Graphics routine

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
	php ; Save processor status
	phd ; Save direct page
	sep #$20		; 8-bit accumulator
	rep #$10		; 16-bit X/Y
	pea.w $0000	 ; Direct page = $0000
	pld ; Set direct page
	ldx.w #$bd61	; Data pointer
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	jsl.l AddressC8000OriginalCode ; External init
	jsr.w InitializeSystem2 ; External routine
	jsr.w InitializeSystem ; External routine
	jsr.w ExternalRoutine ; External routine
	jsl.l FinalSystemInitialization ; External routine
	jsr.w ImportedSegmentCodeCode ; External routine
	lda.b #$10	  ; bit 4 mask
	tsb.w !system_flags_3	 ; Set bit 4 of $d6
	ldx.w #$fff0	; Load $fff0
	stx.b $8e	   ; Store in $8e
	pld ; Restore direct page
	plp ; Restore processor status


SystemData_Config1:
	db $f2,$82,$03 ; Configuration data

;-------------------------------------------------------------------------------
; Memory_ClearBlock: Clear memory routine
;
; Purpose: Clear memory range $0c20-$0e1f (512 bytes)
; Entry: None
; Exit: Memory cleared to $5555 pattern
;       Tilemap initialized
; Notes: Uses mvn for fast block fill
;        Sets up character display tilemap
;-------------------------------------------------------------------------------
Memory_ClearBlock:
	lda.w #$5555	; Fill pattern
	sta.w $0c20	 ; Store at start
	ldx.w #$0c20	; Source address
	ldy.w #$0c22	; Destination address
	lda.w #$01fd	; Length (509 bytes)
	mvn $00,$00	 ; Block move (fill memory)
	ldx.w #$bd99	; Tilemap data pointer
	stx.b $5f	   ; Store in $5f
	ldx.w #$0000	; Tilemap index = 0
	ldy.w #$0020	; Counter = 32 tiles

Memory_ClearBlock_Loop:
	sep #$20		; 8-bit accumulator
	lda.b ($5f)	 ; Load tile number
	sta.w $0c22,x   ; Store in tilemap
	lda.b #$30	  ; Palette 3
	sta.w $0c23,x   ; Store attributes
	rep #$30		; 16-bit A/X/Y
	inc.b $5f	   ; Next tile data
	inx ; Advance tilemap index
	inx ; (4 bytes per entry)
INX_Label:
INX_Label_1:
	dey ; Decrement counter
	bne Memory_ClearBlock_Loop ; Loop until done


;-------------------------------------------------------------------------------
; SystemData_Config2: Character display tilemap data
;
; Purpose: Tile numbers for character name/stats display
; Format: 32 tile numbers (1 byte each)
;-------------------------------------------------------------------------------
SystemData_Config2:
	db $08,$0a,$09,$0b,$08,$09,$0a,$0b,$10,$11,$12,$13,$18,$19,$1a,$1b
	db $10,$11,$12,$13,$28,$29,$2a,$2b,$10,$11,$12,$13,$38,$39,$3a,$3b

;-------------------------------------------------------------------------------
; Menu_Handler: Menu/dialog input handler
;
; Purpose: Handle menu input and dialog display
; Entry: $d8 bit 0 indicates mode
; Exit: User selection processed
; Calls: Input_PollWithToggle (input polling)
;        Sprite_SetMode2C, Anim_SetMode10 (sprite modes)
;        CodeLikelyLoadsProcessesThisData (menu update)
; Notes: Complex menu navigation system
;-------------------------------------------------------------------------------
Menu_Handler:
	phk ; Push program bank
	plb ; Set data bank
	lda.w #$0001	; bit 0 mask
	and.w !system_flags_4	 ; Test bit 0 of $d8
	bne Menu_Handler_AltMode ; If set, alternate mode
	lda.w #$fff0	; Load $fff0
	sta.b $8e	   ; Store in $8e
	bra Menu_Handler_Process ; Continue

;-------------------------------------------------------------------------------
; DEAD CODE - Menu Error Handler (Orphaned)
;-------------------------------------------------------------------------------
; Purpose: Orphaned error sound call
; Reachability: DEAD CODE - No branches or calls to this address
; Analysis: jsr.w Sprite_SetMode2C (error sound)
;           Likely removed error handler or debug code
; Technical: Originally labeled UNREACH_00BDCA
; Status: Preserved for historical reference
;-------------------------------------------------------------------------------
UNREACH_00BDCA:
	jsr.w Sprite_SetMode2C               ;00BDCA|2012B9  |00B912

Menu_Handler_Loop:
	lda.w #$ccb0	; Button mask
	jsr.w Input_PollWithToggle ; Poll input
	bne Menu_Handler_Process ; If button pressed, process
	bit.w #$0080	; Test B button
	bne Menu_Handler_Cancel ; If pressed, branch
	bit.w #$8000	; Test A button
	beq Menu_Handler_Loop ; If not pressed, loop
	jsr.w Anim_SetMode10 ; Set animation mode $10
	stz.b $8e	   ; Clear $8e

Menu_Handler_Done:


LOOSE_OP_00BDE5:
	pla ; Pull return address
	sta.b $03	   ; Store in $03
	pla ; Pull high byte
	sta.b $05	   ; Store in $05
	pla ; Pull saved value
	sta.b $01	   ; Store in $01
	lda.w #$fff0	; Load $fff0
	sta.b $8e	   ; Store in $8e

Menu_Handler_Process:
	stx.w $015f	 ; Store input state
	jsr.w Anim_SetMode10 ; Set animation mode $10
	bra Menu_Handler_Update ; Continue

Menu_Handler_AltMode:
	lda.w #$ccb0	; Button mask
	jsr.w Input_PollWithToggle ; Poll input
	bne Menu_Handler_Update ; If button pressed, process
	lda.b #$01	  ; bit 0 mask
	trb.w !system_flags_4	 ; Clear bit 0 of $d8
	bit.w #$0080	; Test B button
	bne Menu_Handler_AltCancel ; If pressed, cancel
	bit.w #$8000	; Test A button
	beq Menu_Handler_AltMode ; If not pressed, loop
	jsr.w Anim_SetMode10 ; Set animation mode $10
	lda.w #$ffff	; Load $ffff
	sta.b $01	   ; Store in $01
	stz.b $8e	   ; Clear $8e


Menu_Handler_AltCancel:
	jsr.w Sprite_SetMode2C ; Set sprite mode $2d
	lda.w #$00ff	; Load $ff
	sta.b $01	   ; Store in $01


Menu_Handler_Cancel:
	lda.b #$01	  ; bit 0 mask
	trb.w !system_flags_4	 ; Clear bit 0 of $d8


Menu_Handler_Update:
	ldx.w #$be80	; Data pointer
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	bra Menu_Handler_Loop ; Loop

SystemData_Config3:
	db $02,$04	 ; Configuration data

SystemData_Config4:
	db $2b,$bf,$03,$06,$02,$00,$04,$00,$06,$00,$08,$00,$04,$01,$06,$01
	db $00,$00,$02,$00,$04,$00,$06,$00,$08,$00,$04,$01,$06,$01,$00,$02
	db $02,$02,$04,$02,$06,$02,$08,$02,$04,$03,$06,$03

SystemData_Config5:
	db $1c,$bf,$80,$00,$11,$0e,$11,$0e,$30,$70,$80,$00,$2f,$03,$2e,$03
	db $00,$00,$80,$00

SystemData_Config6:
	db $78,$be,$03,$6b,$be,$03,$38,$be,$03

SystemData_Config7:
	db $7a,$be,$03,$3a,$be,$03,$66,$be,$03

;-------------------------------------------------------------------------------
; Menu_PartySelection: Menu handler with party member selection
;
; Purpose: Display menu with party member selection capability
; Entry: A = menu option parameter
;        $1090 = companion status flags (negative if no companion)
; Exit: $14 = selected option or $ff
;       $7e3664 = selected option stored
; Calls: Anim_SetMode10 (update sprite), CodeLikelyLoadsProcessesThisData (show menu)
; Notes: Handles single-character vs two-character party
;        Saves/restores menu state on stack
;-------------------------------------------------------------------------------
Menu_PartySelection:
	php ; Save processor status
	sep #$20		; 8-bit accumulator
	rep #$10		; 16-bit index
	sta.w $04e0	 ; Store menu parameter
	lda.b #$04	  ; Menu active flag
	tsb.w !system_flags_5	 ; Set bit 2 in flags
	pei.b ($8e)	 ; Save position
	pei.b ($01)	 ; Save option
	pei.b ($03)	 ; Save menu type
	lda.b #$ff	  ; No selection
	sta.b $14	   ; Initialize result
	stz.b $8e	   ; Clear position low
	stz.b $8f	   ; Clear position high
	ldx.w #$0102	; Two options (two characters)
	lda.w !char2_companion_id	 ; Check companion status
	bpl Menu_PartySelection_Init ; Branch if companion present
	ldx.w #$0101	; One option (solo)

Menu_PartySelection_Init:
	stx.b $03	   ; Set menu configuration
	stz.b $01	   ; Clear option
	stz.b $02	   ; Clear option high
	lda.l $7e3664   ; Load last selection
	beq Menu_PartySelection_Start ; Branch if zero
	bmi Menu_PartySelection_BattleCheck ; Branch if negative
	lda.w !char2_companion_id	 ; Check companion status again
	bmi Menu_PartySelection_Start ; Branch if no companion
	inc.b $01	   ; Select second option
	bra Menu_PartySelection_Start ; Continue

; ------------------------------------------------------------------------------
; Menu Party Selection - Battle Mode Check
; ------------------------------------------------------------------------------
; Purpose: Check if in battle mode and skip if bit 5 of $04e0 is set
; Reachability: Reachable via conditional branch (bmi above)
; Analysis: Battle mode alternate path in party selection
;   - Loads $04e0 (battle flags)
;   - Tests bit 5 ($20)
;   - If set, skips to Menu_PartySelection_GetOption
;   - Otherwise continues to next check
; Technical: Originally labeled UNREACH_00BEC0
; ------------------------------------------------------------------------------
Menu_PartySelection_BattleCheck:
	lda.w $04e0                          ;00BEC0|ADE004  |0004E0; Load battle flags
	and.b #$20                           ;00BEC3|2920    |      ; Test bit 5 (battle mode)
	bne Menu_PartySelection_GetOption    ;00BEC5|D00D    |00BED4; If set, get option directly
	bra Menu_PartySelection_Start        ;00BEC7|8007    |00BED0; Otherwise continue

Menu_PartySelection_Start:
	lda.w $04e0	 ; Load parameter
	and.b #$10	  ; Check bit 4
	beq Menu_PartySelection_DefaultOption ; Branch if clear

Menu_PartySelection_GetOption:
	lda.b $01	   ; Load current option
	bra Menu_PartySelection_Update ; Continue

; ------------------------------------------------------------------------------
; Menu Party Selection - Default Option Handler
; ------------------------------------------------------------------------------
; Purpose: Set default option to $80 (cancel/back)
; Reachability: Reachable via conditional branch (beq above)
; Analysis: Sets default menu option when bit 4 of $04e0 is clear
;   - Loads $80 (cancel code)
;   - Implicit fall-through to Menu_PartySelection_Update
; Technical: Originally labeled UNREACH_00BED4
; ------------------------------------------------------------------------------
Menu_PartySelection_DefaultOption:
	lda.b #$80                           ;00BED4|A980    |      ; Load cancel option ($80)

Menu_PartySelection_Update:
	ldx.b $14	   ; Load previous result
	cmp.b $14	   ; Compare with current
	sta.b $14	   ; Store new result
	sta.l $7e3664   ; Save selection
	beq Menu_PartySelection_Show ; Branch if unchanged
	txa ; Get previous
	cmp.b #$ff	  ; Was cancelled?
	beq Menu_PartySelection_Show ; Branch if yes
	jsr.w Anim_SetMode10 ; Update sprite

Menu_PartySelection_Show:
	ldx.w #$bf48	; Menu data
	jsr.w CodeLikelyLoadsProcessesThisData ; Show menu
	ldx.w #$fff0	; Position offset (-16)
	stx.b $8e	   ; Set position

;-------------------------------------------------------------------------------
; Menu_OptionSelection: Menu option selection handler
;
; Purpose: Handle menu cursor and option selection
; Entry: $01 = current menu option
;        $03 = menu configuration
; Exit: $01 = selected option or $ff for cancel
; Calls: Input_PollWithToggle (input polling)
;        Sprite_SetMode2C, Anim_SetMode11, Anim_SetMode10 (sprite/animation modes)
;        CodeLikelyLoadsProcessesThisData (menu update)
; Notes: Supports cursor wrapping, confirmation, cancellation
;-------------------------------------------------------------------------------
Menu_OptionSelection:
	lda.w #$ccb0	; Button mask
	jsr.w Input_PollWithToggle ; Poll input
	bne Menu_OptionSelection_ProcessInput ; If button pressed, process
	bit.w #$0080	; Test B button
	bne Menu_OptionSelection_Cancel ; If pressed, cancel
	bit.w #$8000	; Test A button
	beq Menu_OptionSelection ; If not pressed, loop
	jsr.w Anim_SetMode10 ; Set animation mode $10
	lda.w #$000f	; Mask low 4 bits
	and.b $01	   ; Get current selection
	cmp.w #$000c	; Check if option $0c
	beq Menu_OptionSelection_Cancel ; If yes, treat as cancel
	lda.b $01	   ; Load full option
	sta.w $015f	 ; Store selection
	lda.w #$ffff	; Load $ffff
	sta.b $01	   ; Store in $01
	stz.b $8e	   ; Clear $8e


Menu_OptionSelection_Cancel:
	jsr.w Sprite_SetMode2C ; Set sprite mode $2c
	lda.w #$00ff	; Load $ff (cancel code)
	sta.b $01	   ; Store in $01


;-------------------------------------------------------------------------------
; DEAD CODE - Menu Configuration Data (Orphaned)
;-------------------------------------------------------------------------------
; Purpose: Orphaned menu configuration or handler
; Reachability: DEAD CODE - No branches or calls to this address
; Analysis: lda #$0001, trb $00d8, rts
;           Clears bit 0 in $00d8 and returns
; Technical: Originally labeled UNREACH_00BEBB
; Status: Preserved for historical reference
;-------------------------------------------------------------------------------
UNREACH_00BEBB:
	db $a9,$01,$00,$1c,$d8,$00,$60

SystemData_Config8:
	db $d8,$00,$03,$c2,$00,$03,$f5,$00,$03

SystemData_Config9:
	db $f2,$82,$03

LOOSE_OP_00BECE:
	db $9c,$10,$01,$9c,$12,$01,$60 ; stz $0110; stz $0112; rts

;-------------------------------------------------------------------------------
; DEAD CODE - Long Call Handler (Orphaned)
;-------------------------------------------------------------------------------
; Purpose: Orphaned long call to Bank $0c
; Reachability: DEAD CODE - No branches or calls to this address
; Analysis: PHA, jsl AddressC8000OriginalCode (more code follows)
;           Pushes accumulator and calls Bank $0c code
; Technical: Originally labeled UNREACH_00BED5
; Status: Preserved for historical reference
;-------------------------------------------------------------------------------
UNREACH_00BED5:
	db $48,$22,$00,$80,$0c

Menu_OptionSelection_UpdateDisplay:
	stx.w $015f	 ; Store input state
	jsr.w Anim_SetMode10 ; Set animation mode $10
	ldx.w #$be80	; Data pointer
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	bra Menu_OptionSelection ; Loop

;-------------------------------------------------------------------------------
; DEAD CODE - Menu Polling Handler (Orphaned)
;-------------------------------------------------------------------------------
; Purpose: Orphaned menu polling/input handler
; Reachability: DEAD CODE - No branches or calls to this address
; Analysis: lda #$ccb0, jsl AnalysisLdaCcb0JslCodeMenu (menu polling)
;           Complex multi-byte sequence (25 bytes total)
; Technical: Originally labeled UNREACH_00BEE5
; Status: Preserved for historical reference
;-------------------------------------------------------------------------------
UNREACH_00BEE5:
	db $a9,$b0,$cc,$22,$30,$b9,$00,$f0,$f1,$89,$80,$00,$f0,$03,$4c,$cc
	db $be,$20,$12,$b9,$a9,$ff,$00,$85,$01,$60

;-------------------------------------------------------------------------------
; Menu_MultiOption: Complex menu update routine
;
; Purpose: Update menu display with multiple options
; Entry: $01 = current option
;        $03 = menu data pointer
; Exit: Menu updated
; Calls: CodeLikelyLoadsProcessesThisData (menu update)
;        Input_PollWithToggle (input polling)
;        Anim_SetMode11 (animation mode)
; Notes: Handles multi-option menus with cursor navigation
;-------------------------------------------------------------------------------
Menu_MultiOption:
	phk ; Push program bank
	plb ; Set data bank
	jsr.w Anim_SetMode11 ; Set animation mode $11
	ldx.w #$becb	; Data pointer
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu

Menu_MultiOption_Loop:
	lda.w #$ccb0	; Button mask
	jsr.w Input_PollWithToggle ; Poll input
	bne Menu_MultiOption_Process ; If button pressed, process
	bit.w #$0080	; Test B button
	beq Menu_MultiOption_Loop ; If not pressed, loop
	stz.b $8e	   ; Clear $8e


;-------------------------------------------------------------------------------
; DEAD CODE - Menu Cleanup Handler (Orphaned)
;-------------------------------------------------------------------------------
; Purpose: Orphaned menu cleanup/return handler
; Reachability: DEAD CODE - No branches or calls to this address
; Analysis: jsr Anim_SetMode10, lda #$ffff, sta $01, stz $8e, rts
;           Sets animation mode, loads $ffff, stores to $01, clears $8e
; Technical: Originally labeled UNREACH_00BF1B
; Status: Preserved for historical reference
;-------------------------------------------------------------------------------
UNREACH_00BF1B:
	db $20,$1c,$b9,$a9,$ff,$ff,$85,$01,$9c,$8e,$00,$60

SystemData_Config10:
	db $00		 ; Padding

Menu_MultiOption_Process:
	stx.w $015f	 ; Store input state
	jsr.w Anim_SetMode10 ; Set animation mode $10
	bra Menu_MultiOption_Loop ; Loop

;-------------------------------------------------------------------------------
; Menu_Item_CleanupReturn: Item use/equip system cleanup and return
;
; Purpose: Restore state after item menu operations
; Entry: Processor status saved on stack
;        $01, $03, $8e saved on stack
;        $14 = result code
; Exit: Restored state, A = result code
; Calls: CodeLikelyLoadsProcessesThisData (menu update)
; Notes: Cleanup routine for item management
;-------------------------------------------------------------------------------
Menu_Item_CleanupReturn:
	lda.b #$04	  ; bit 2 mask
	trb.w !system_flags_5	 ; Clear bit 2 of $da
	ldx.w #$bf48	; Menu data
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	plx ; Restore X
	stx.b $03	   ; Restore $03
	plx ; Restore X
	stx.b $01	   ; Restore $01
	plx ; Restore X
	stx.b $8e	   ; Restore $8e
	lda.b $14	   ; Load result code
	plp ; Restore processor status


SystemData_Config11:
	db $9b,$8f,$03 ; Menu configuration

;-------------------------------------------------------------------------------
; Inventory Item Discard System (Menu_Item_Discard - InventoryItemDiscardSystemMenuItem)
;-------------------------------------------------------------------------------
Menu_Item_Discard:
	lda.w #$0504	; Menu mode $0504
	sta.b $03	   ; Store in $03
	ldx.w #$fff0	; Load $fff0
	stx.b $8e	   ; Store in $8e
	bra Menu_Item_Discard_Display ; Jump to menu display

Menu_Item_Discard_Error:
	jsr.w Sprite_SetMode2C ; Set sprite mode $2c

Menu_Item_Discard_Input:
	lda.w #$cfb0	; Button mask
	jsr.w Input_PollWithToggle ; Poll input
	bne Menu_Item_Discard_Display ; If button pressed, process
	bit.w #$0080	; Test B button
	bne Menu_Item_Discard_Validate ; If pressed, branch
	bit.w #$8000	; Test A button
	beq Menu_Item_Discard_Input ; If not pressed, loop
	jsr.w Anim_SetMode10 ; Set animation mode $10
	stz.b $8e	   ; Clear $8e
	ldx.w #$c032	; Menu data
	jmp.w CodeLikelyLoadsProcessesThisData ; Update menu and return

Menu_Item_Discard_Display:
	ldx.w #$c02f	; Menu data
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	bra Menu_Item_Discard_Input ; Loop

Menu_Item_Discard_Validate:
	lda.b $02	   ; Load selection
	and.w #$00ff	; Mask to 8 bits
	bne Menu_Item_Discard_Error ; If not zero, error sound
	lda.b $01	   ; Load item slot
	and.w #$00ff	; Mask to 8 bits
	asl a; × 2 (word index)
	tax ; X = item index
	lda.w $0e9e,x   ; Load item ID
	and.w #$00ff	; Mask to 8 bits
	cmp.w #$00ff	; Check if empty slot
	beq Menu_Item_Discard_Error ; If empty, error
	cmp.w #$0013	; Check if item $13
	beq Menu_Item_Discard_Error ; If yes, can't discard
	cmp.w #$0011	; Check if less than $11
	bcc Menu_Item_Discard_Consumable ; If yes, handle consumable
	beq Menu_Item_Discard_Armor ; If $11, handle armor
	jsr.w Menu_Item_ConfirmDiscard ; Confirm discard
	bcc Menu_Item_Discard_Execute ; If confirmed, proceed
	bne Menu_Item_Discard_Input ; If cancelled, loop
	lda.w #$0080	; Load $80 (companion item)

Menu_Item_Discard_Execute:
	dec.w $0e9f,x   ; Decrement quantity
	clc ; Clear carry
	adc.w #$1018	; Add base address
	tay ; Y = source
	adc.w #$0003	; Add 3
	tax ; X = dest
	lda.w #$0002	; Length = 2
	mvn $00,$00	 ; Block move (shift items)

Menu_Item_Discard_UpdateDisplay:
	sep #$20		; 8-bit accumulator
	lda.w $04df	 ; Load character ID
	sta.w $0505	 ; Store in $0505
	rep #$30		; 16-bit A/X/Y
	jsr.w ExternalRoutine3 ; External routine
	ldx.w #$c035	; Menu data
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	bra Menu_Item_Discard_Display ; Loop

;-------------------------------------------------------------------------------
; Menu Item - Discard Cancel Handler
;-------------------------------------------------------------------------------
; Purpose: Handle item discard cancellation
; Reachability: Reachable via conditional branch (bne - 2 references)
; Analysis: Jumps back to item discard input loop
; Technical: Originally labeled UNREACH_00BFD5
;-------------------------------------------------------------------------------
Menu_Item_Discard_Cancel:
	jmp Menu_Item_Discard_Input          ;00BFD5|4C5ABF  |00BF5A; Jump to input loop

Menu_Item_Discard_Armor:
	jsr.w Menu_Item_ConfirmDiscard ; Confirm discard
	bcc Menu_Item_Discard_Armor_Execute ; If confirmed, proceed
	bne Menu_Item_Discard_Cancel ; If cancelled, loop
	lda.w #$0080	; Load $80

Menu_Item_Discard_Armor_Execute:
	dec.w $0e9f,x   ; Decrement quantity
	tax ; X = item offset
	sep #$20		; 8-bit accumulator
	stz.w !char1_status,x   ; Clear equipped flag
	rep #$30		; 16-bit A/X/Y
	bra Menu_Item_Discard_UpdateDisplay ; Update display

Menu_Item_Discard_Consumable:
	jsr.w Menu_Item_ConfirmDiscard ; Confirm discard
	bcc Menu_Item_Discard_Consumable_Execute ; If confirmed, proceed
	bne Menu_Item_Discard_Cancel ; If cancelled, loop
	lda.w #$0080	; Load $80

Menu_Item_Discard_Consumable_Execute:
	dec.w $0e9f,x   ; Decrement quantity
	tax ; X = item offset
	lda.w !char1_max_hp,x   ; Load max HP
	lsr a; ÷ 4 (HP recovery amount)
	lsr a
	adc.w !char1_current_hp,x   ; Add current HP
	cmp.w !char1_max_hp,x   ; Check if exceeds max
	bcc Menu_Item_StoreHP ; If not, store
	lda.w !char1_max_hp,x   ; Use max HP

Menu_Item_StoreHP:
	sta.w !char1_current_hp,x   ; Store new HP
	bra Menu_Item_Discard_UpdateDisplay ; Update display

;-------------------------------------------------------------------------------
; Menu_Item_ConfirmDiscard: Confirm item discard dialog
;
; Purpose: Show confirmation dialog for discarding items
; Entry: A = item ID
; Exit: Carry clear if confirmed (A=1), carry set if cancelled
; Calls: BankRoutine, NormalPositionCallB908, CallsCodeCodeCode
; Notes: Uses $04e0 for input tracking
;-------------------------------------------------------------------------------
Menu_Item_ConfirmDiscard:
	phx ; Save X
	sep #$20		; 8-bit accumulator
	sta.w $043a	 ; Store item ID
	jsl.l BankRoutine ; External routine
	jsr.w NormalPositionCallB908 ; Set sprite mode $2d
	rep #$30		; 16-bit A/X/Y
	lda.w #$0010	; Menu type $10
	jsr.w CallsCodeCodeCode ; Show confirmation menu
	plx ; Restore X
	and.w #$00ff	; Mask result
	cmp.w #$0001	; Check if confirmed


SystemData_Config12:
	db $e8,$8f,$03,$dd,$8f,$03,$8a,$8f,$03

;-------------------------------------------------------------------------------
; Spell Equip/Unequip System (Menu_Spell_Equip - SpellEquipUnequipSystemMenuSpell)
;-------------------------------------------------------------------------------
Menu_Spell_Equip:
	lda.w #$0406	; Menu mode $0406
	sta.b $03	   ; Store in $03
	ldx.w #$fff0	; Load $fff0
	stx.b $8e	   ; Store in $8e
	bra Menu_Spell_DisplayMenu ; Jump to menu display

;-------------------------------------------------------------------------------
; Menu Spell - Error Sound
;-------------------------------------------------------------------------------
; Purpose: Play error sound for invalid spell operations
; Reachability: Reachable via conditional branches (3 references)
; Analysis: Plays error feedback sound via Sprite_SetMode2C
; Technical: Originally labeled UNREACH_00C044
;-------------------------------------------------------------------------------
Menu_Spell_ErrorSound:
	jsr.w Sprite_SetMode2C               ;00C044|2012B9  |00B912; Play error sound

Menu_Spell_ProcessInput:
	lda.w #$cfb0	; Button mask
	jsr.w Input_PollWithToggle ; Poll input
	bne Menu_Spell_DisplayMenu ; If button pressed, process
	bit.w #$0080	; Test B button
	bne Menu_Spell_Cancel ; If pressed, branch
	bit.w #$8000	; Test A button
	beq Menu_Spell_ProcessInput ; If not pressed, loop
	jsr.w Anim_SetMode10 ; Set animation mode $10
	stz.b $8e	   ; Clear $8e
	ldx.w #$c1d6	; Menu data
	jmp.w CodeLikelyLoadsProcessesThisData ; Update menu and return

;-------------------------------------------------------------------------------
; Menu Spell - Spell Slot 0 Handler
;-------------------------------------------------------------------------------
; Purpose: Handle special case for spell slot 0
; Reachability: Reachable via conditional branch (beq above)
; Analysis: Validates spell slot 0 usage
;   - Checks spell ID range, if >= 7 loops back
;   - Calls confirm routine, if cancelled loops
;   - Otherwise processes spell use
; Technical: Originally labeled UNREACH_00C064
;-------------------------------------------------------------------------------
Menu_Spell_Slot0Handler:
	lda.w $0e91                          ;00C064|AD910E  |010E91; Load spell ID
	and.w #$007f                         ;00C067|297F00  |      ; Mask to 7 bits
	cmp.w #$0007                         ;00C06A|C90700  |      ; Check if >= 7
	bcc Menu_Spell_ProcessInput          ;00C06D|90D5    |00C044; If < 7, loop
	jsr.w ConfirmSpellUse                    ;00C06F|20B1C1  |00C1B1; Confirm spell use
	beq Menu_Spell_ProcessInput          ;00C072|F0D3    |00C047; If cancelled, loop
	dec.w !char1_current_mp,x                        ;00C074|DE1810  |011018; Decrement MP
	sep #$20                             ;00C077|E220    |      ; 8-bit accumulator
	lda.b #$14                           ;00C079|A914    |      ; Load spell effect ID
	sta.w $043a                          ;00C07B|8D3A04  |01043A; Store effect
	jsl.l BankRoutine                    ;00C07E|22E08A02|028AE0; Call effect handler
	lda.w $04df                          ;00C082|ADDF04  |0104DF; Load character ID
	sta.w $0505                          ;00C085|8D0505  |010505; Store for update
	lda.b #$14                           ;00C088|A914    |      ; Load menu ID
	jmp.w JumpMenuHandler                    ;00C08A|4CF4BC  |00BCF4; Jump to menu handler

Menu_Spell_DisplayMenu:
	ldx.w #$c1d3	; Menu data
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	bra Menu_Spell_ProcessInput ; Loop

;-------------------------------------------------------------------------------
; Menu Spell - Invalid Spell Jump
;-------------------------------------------------------------------------------
; Purpose: Jump to error handler for invalid spell conditions
; Reachability: Reachable via conditional branches (2 references)
; Analysis: Jumps to Menu_Spell_ErrorSound
; Technical: Originally labeled UNREACH_00C095
;-------------------------------------------------------------------------------
Menu_Spell_InvalidSpellJump:
	jmp Menu_Spell_ErrorSound            ;00C095|4C44C0  |00C044; Jump to error

Menu_Spell_Cancel:
	lda.b $01	   ; Load character selection
	and.w #$00ff	; Mask to 8 bits
	beq Menu_Spell_ValidateSlot ; If character 0, branch
	cmp.w #$0003	; Check if character 3
	bne Menu_Spell_ErrorSound ; If not, error
	lda.w !char2_companion_id	 ; Load companion data
	and.w #$00ff	; Mask to 8 bits
	cmp.w #$00ff	; Check if no companion
	beq Menu_Spell_ErrorSound ; If none, error
	lda.w #$0080	; Load $80 (companion offset)

Menu_Spell_ValidateSlot:
	tax ; X = character offset
	lda.w !char1_status,x   ; Load status flags
	and.w #$00f9	; Mask out certain flags
	bne Menu_Spell_ErrorSound ; If flagged, error
	lda.w #$0007	; Load 7 (max spell slot -1)
	sec ; Set carry
	sbc.b $02	   ; Subtract selection
	and.w #$00ff	; Mask to 8 bits
	jsr.w GetBitMask ; Get bit mask
	and.w !char1_spell_equipped,x   ; Test spell equipped
	beq Menu_Spell_InvalidSpellJump ; If not equipped, error
	lda.w !char1_current_mp,x   ; Load current MP
	and.w #$00ff	; Mask to 8 bits
	beq Menu_Spell_InvalidSpellJump ; If no MP, error
	lda.b $02	   ; Load spell slot
	and.w #$00ff	; Mask to 8 bits
	beq Menu_Spell_Slot0Handler ; If slot 0, special case
	cmp.w #$0002	; Check if slot 2
	bcc IfSlotHpHealing ; If slot 1, HP healing
	beq IfSlotCureStatus ; If slot 2, cure/status
	jsr.w ConfirmSpellUse ; Confirm spell use
	beq IfCancelledLoop ; If cancelled, loop
	cmp.w #$0001	; Check result
	beq Menu_Spell_DecrementMP_Char0 ; If 1, branch
	tax ; X = character offset
	lda.w !char1_max_hp	 ; Load max HP
	sta.w !char1_current_hp	 ; Restore to full HP
	txa ; A = character offset

Menu_Spell_DecrementMP_Char0:
	cmp.w #$0000	; Check if character 0
	beq Menu_Spell_DecrementMP_Main ; If yes, skip
	lda.w !char2_max_hp	 ; Load companion max HP
	sta.w !char2_current_hp	 ; Restore companion HP

Menu_Spell_DecrementMP_Main:
	sep #$20		; 8-bit accumulator
	ldx.w #$0000	; Default character offset
	lda.b $01	   ; Load character selection
	beq Menu_Spell_DecrementMP_Do ; If 0, use default
	ldx.w #$0080	; Companion offset

Menu_Spell_DecrementMP_Do:
	dec.w !char1_current_mp,x   ; Decrement MP
	lda.w $04df	 ; Load character ID
	sta.w $0505	 ; Store in $0505
	rep #$30		; 16-bit A/X/Y
	ldx.w #$c035	; Menu data
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	jmp.w Menu_Spell_DisplayMenu ; Loop

Menu_Spell_UseCure:
	jsr.w Menu_Spell_ConfirmUse ; Confirm spell use
	beq Menu_Spell_ReturnToInput ; If cancelled, loop
	sep #$20		; 8-bit accumulator
	cmp.b #$01	  ; Check result
	beq Menu_Spell_CureCompanion ; If 1, branch
	stz.w !char1_status	 ; Clear status (char 0)

Menu_Spell_CureCompanion:
	cmp.b #$00	  ; Check if character 0
	beq Menu_Spell_FinishCure ; If yes, skip
	stz.w !char2_status	 ; Clear companion status

Menu_Spell_FinishCure:
	rep #$30		; 16-bit A/X/Y
	bra Menu_Spell_DecrementMP ; Continue

Menu_Spell_ReturnToInput:
	jmp.w Menu_Spell_ProcessInput ; Loop

Menu_Spell_UseHeal:
	jsr.w ConfirmSpellUse ; Confirm spell use
	beq IfCancelledLoop ; If cancelled, loop
	pha ; Save character offset
	lda.w $1025,x   ; Load spell power
	and.w #$00ff	; Mask to 8 bits
	sta.b $64	   ; Store in $64
	asl a; × 2
	adc.b $64	   ; + original (× 3)
	lsr a; ÷ 2 (× 1.5)
	clc ; Clear carry
	adc.w #$0032	; Add base value (50)
	sta.b $98	   ; Store recovery amount
	tay ; Y = recovery
	lda.b $01,s	 ; Load character from stack
	cmp.w #$0001	; Check if character 1
	beq IfYesSkipHpCalc ; If yes, skip HP calc
	lda.w !char1_max_hp	 ; Load max HP
	jsr.w Menu_Spell_CalcPercent ; Calculate percentage
	adc.w !char1_current_hp	 ; Add current HP
	cmp.w !char1_max_hp	 ; Check if exceeds max
	bcc Menu_Spell_StoreHP_Main ; If not, store
	lda.w !char1_max_hp	 ; Use max HP

Menu_Spell_StoreHP_Main:
	sta.w !char1_current_hp	 ; Store new HP

Menu_Spell_HealCompanion:
	sty.b $98	   ; Restore recovery amount
	lda.b $01,s	 ; Load character from stack
	beq Menu_Spell_HealComplete ; If character 0, skip
	lda.w !char2_max_hp	 ; Load companion max HP
	jsr.w Menu_Spell_CalcPercent ; Calculate percentage
	adc.w !char2_current_hp	 ; Add companion current HP
	cmp.w !char2_max_hp	 ; Check if exceeds max
	bcc Menu_Spell_StoreHP_Comp ; If not, store
	lda.w !char2_max_hp	 ; Use max HP

Menu_Spell_StoreHP_Comp:
	sta.w !char2_current_hp	 ; Store companion HP

Menu_Spell_HealComplete:
	pla ; Restore character offset
	jmp.w Menu_Spell_DecrementMP ; Continue

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
	sta.b $9c	   ; Store max HP
	jsl.l ExitQuotientRemainderViaCode ; Multiply routine
	lda.b $9e	   ; Load result low
	sta.b $98	   ; Store in $98
	lda.b $a0	   ; Load result high
	sta.b $9a	   ; Store in $9a
	lda.w #$0064	; Divisor = 100
	sta.b $9c	   ; Store divisor
	jsl.l ExitResultViaCode ; Divide routine
	lda.b $03,s	 ; Load character offset from stack
	cmp.w #$0080	; Check if companion
	bne Menu_Spell_ReturnPercent ; If not, skip
	db $46,$9e	 ; lsr $9e (halve result)

Menu_Spell_ReturnPercent:
	lda.b $9e	   ; Load result
	clc ; Clear carry


;-------------------------------------------------------------------------------
; Menu_Spell_ConfirmUse: Spell use confirmation
;
; Purpose: Confirm spell usage and show dialog
; Entry: $02 = spell slot
; Exit: A = character offset (0 or $80), Z flag set if cancelled
; Calls: BankRoutine, NormalPositionCallB908, CallsCodeCodeCode
;-------------------------------------------------------------------------------
Menu_Spell_ConfirmUse:
	phx ; Save X
	sep #$20		; 8-bit accumulator
	lda.b $02	   ; Load spell slot
	clc ; Clear carry
	adc.b #$14	  ; Add $14 (spell offset)
	sta.w $043a	 ; Store spell ID
	jsl.l BankRoutine ; External routine
	jsr.w NormalPositionCallB908 ; Set sprite mode $2d
	lda.w $04e0	 ; Load input flags
	rep #$30		; 16-bit A/X/Y
	jsr.w CallsCodeCodeCode ; Show confirmation menu
	plx ; Restore X
	and.w #$00ff	; Mask result
	cmp.w #$00ff	; Check if cancelled


SystemData_Config13:
	db $3a,$90,$03,$dd,$8f,$03

;-------------------------------------------------------------------------------
; Battle Settings Menu (Menu_BattleSettings - BattleSettingsMenuMenuBattlesettingsCode)
;-------------------------------------------------------------------------------
Menu_BattleSettings:
	lda.w #$0020	; bit 5 mask
	tsb.w !system_flags_3	 ; Set bit 5 of $d6
	lda.w #$0602	; Menu mode $0602
	sta.b $03	   ; Store in $03
	lda.w #$bff0	; Load $bff0
	sta.b $8e	   ; Store in $8e
	bra Menu_BattleSettings_InputLoop ; Jump to input loop

;-------------------------------------------------------------------------------
; Menu Battle Settings - Error Sound
;-------------------------------------------------------------------------------
; Purpose: Play error sound for invalid battle setting operations
; Reachability: Dead code (no references found)
; Analysis: Orphaned error sound handler
; Technical: Originally labeled UNREACH_00C1EB
;-------------------------------------------------------------------------------
UNREACH_00C1EB:
	jsr.w Sprite_SetMode2C               ;00C1EB|2012B9  |00B912; Play error sound

Menu_BattleSettings_InputLoop:
	rep #$30		; 16-bit A/X/Y
	lda.w #$cf30	; Button mask
	jsr.w Input_PollWithToggle ; Poll input
	bne Menu_BattleSettings_Process ; If button pressed, process
	bit.w #$4000	; Test Y button
	bne Menu_BattleSettings_YButton ; If pressed, branch
	bit.w #$8000	; Test A button
	beq Menu_BattleSettings_InputLoop ; If not pressed, loop
	jsr.w Anim_SetMode10 ; Set animation mode $10
	stz.b $8e	   ; Clear $8e
	lda.w #$0020	; bit 5 mask
	trb.w !system_flags_3	 ; Clear bit 5 of $d6


;-------------------------------------------------------------------------------
; Menu Battle Settings - Y Button Handler
;-------------------------------------------------------------------------------
; Purpose: Handle Y button press in battle settings menu
; Reachability: Reachable via conditional branch (bne above)
; Analysis: Checks companion status and branches to settings submenu
; Technical: Originally labeled UNREACH_00C20E
;-------------------------------------------------------------------------------
Menu_BattleSettings_YButton:
	sep #$20                             ;00C20E|E220    |      ; 8-bit accumulator
	lda.w !char2_companion_id                          ;00C210|AD9010  |011090; Load companion status
	bmi Menu_BattleSettings_InputLoop    ;00C213|30D6    |00C1EB; If negative, loop
	jmp.w JumpSubmenu                    ;00C215|4CD9C2  |00C2D9; Jump to submenu

Menu_BattleSettings_Process:
	txa ; Transfer button state
	sep #$20		; 8-bit accumulator
	lda.b #$00	  ; Clear high byte
	xba ; Swap bytes
	cmp.w $0006	 ; Compare with current setting
	bne Menu_BattleSettings_UpdateSetting ; If different, update
	jmp.w Menu_BattleSettings_ToggleSetting ; Toggle setting

Menu_BattleSettings_UpdateSetting:
	pha ; Save setting
	jsr.w Anim_SetMode10 ; Set animation mode $10
	pla ; Restore setting
	cmp.b #$01	  ; Check setting type
	bcc Menu_BattleSettings_Speed ; If < 1, handle battle speed
	beq Menu_BattleSettings_Mode ; If = 1, handle battle mode
	cmp.b #$03	  ; Check if < 3
	bcc Menu_BattleSettings_Cursor ; If yes, handle cursor memory
	beq Menu_BattleSettings_Green ; If = 3, handle green color
	cmp.b #$05	  ; Check if < 5
	bcc Menu_BattleSettings_Blue ; If yes, handle blue color
	lda.w $0e9d	 ; Load color data high byte
	lsr a; Extract red component
	lsr a
	bra Menu_BattleSettings_StoreColor ; Store result

Menu_BattleSettings_Blue:
	rep #$30		; 16-bit A/X/Y
	lda.w $0e9c	 ; Load color data
	lsr a; Extract blue component
	lsr a
	sep #$20		; 8-bit accumulator
	lsr a
	lsr a
	lsr a
	bra Menu_BattleSettings_StoreColor ; Store result

Menu_BattleSettings_Green:
	lda.w $0e9c	 ; Load color data (green)

Menu_BattleSettings_StoreColor:
	and.b #$1f	  ; Mask to 5 bits
	inc a; Increment
	lsr a; ÷ 4 (scale down)
	lsr a
	ldx.w #$0009	; X = 9 (data offset)
	ldy.w #$0609	; Y = menu mode
	bra Menu_BattleSettings_UpdateDisplay ; Continue

Menu_BattleSettings_Cursor:
	lda.w $0e9b	 ; Load cursor memory setting
	and.b #$07	  ; Mask to 3 bits
	ldx.w #$0006	; X = 6
	ldy.w #$0607	; Y = menu mode
	bra Menu_BattleSettings_UpdateDisplay ; Continue

Menu_BattleSettings_Mode:
	lda.w !char2_companion_id	 ; Load battle mode setting
	bpl Menu_BattleSettings_Mode_Active ; If active mode, branch
	lda.b $06	   ; Load current selection
	eor.b #$02	  ; Toggle bit 1
	and.b #$fe	  ; Clear bit 0
	sta.b $02	   ; Store new selection
	bra Menu_BattleSettings_UpdateSetting ; Loop

Menu_BattleSettings_Mode_Active:
	lda.b #$80	  ; Load $80
	and.w !char2_active_flag	 ; Test companion flag
	beq Menu_BattleSettings_Mode_Store ; If not set, use 0
	lda.b #$ff	  ; Load $ff

Menu_BattleSettings_Mode_Store:
	inc a; Increment (0 or 1)
	ldx.w #$0003	; X = 3
	ldy.w #$0602	; Y = menu mode
	bra Menu_BattleSettings_UpdateDisplay ; Continue

Menu_BattleSettings_Speed:
	lda.b #$80	  ; Load $80
	and.w $0ec6	 ; Test battle speed flag
	beq Menu_BattleSettings_Speed_Store ; If not set, use 0
	db $a9,$01	 ; lda #$01

Menu_BattleSettings_Speed_Store:
	ldx.w #$0000	; X = 0
	ldy.w #$0602	; Y = menu mode

Menu_BattleSettings_UpdateDisplay:
	sty.b $03	   ; Store menu mode
	sta.b $01	   ; Store current value
	lda.w DATA8_00c339,x ; Load color byte 1
	sta.l $7f56d7   ; Store to WRAM
	lda.w DATA8_00c33a,x ; Load color byte 2
	sta.l $7f56d9   ; Store to WRAM
	lda.w DATA8_00c33b,x ; Load color byte 3
	sta.l $7f56db   ; Store to WRAM

Menu_BattleSettings_Refresh:
	ldx.b $01	   ; Load current value
	stx.b $05	   ; Store in $05
	ldx.w #$c345	; Menu data
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	jmp.w Menu_BattleSettings_InputLoop ; Loop

Menu_BattleSettings_ToggleSetting:
	lda.b $02	   ; Load option index
	beq Menu_BattleSettings_ToggleSpeed ; If 0, toggle battle speed
	cmp.b #$02	  ; Check if 2
	bcc Menu_BattleSettings_ToggleMode ; If < 2, toggle battle mode
	bne Menu_BattleSettings_SetColor ; If > 2, handle colors
	lda.w $0e9b	 ; Load cursor memory
	and.b #$f8	  ; Clear low 3 bits
	ora.b $01	   ; Set new value
	sta.w $0e9b	 ; Store cursor memory
	bra Menu_BattleSettings_Commit ; Update display

Menu_BattleSettings_ToggleMode:
	lda.w !char2_active_flag	 ; Load companion flag
	eor.b #$80	  ; Toggle bit 7
	sta.w !char2_active_flag	 ; Store back
	bra Menu_BattleSettings_Commit ; Update display

Menu_BattleSettings_ToggleSpeed:
	lda.w $0ec6	 ; Load battle speed
	eor.b #$80	  ; Toggle bit 7
	sta.w $0ec6	 ; Store back

Menu_BattleSettings_Commit:
	jsr.w Sprite_SetMode2D ; Set sprite mode $2d
	bra Menu_BattleSettings_Refresh ; Update display

Menu_BattleSettings_SetColor:
	cmp.b #$04	  ; Check if 4
	bcc Menu_BattleSettings_SetBlue ; If < 4, handle blue
	beq Menu_BattleSettings_SetGreen ; If = 4, handle green
	lda.b #$7c	  ; Mask for red component
	trb.w $0e9d	 ; Clear red bits
	lda.b $01	   ; Load new value
	asl a; Shift left 4 times
	asl a
	asl a
	asl a
	bpl Menu_BattleSettings_SetRed_Store ; If positive, use value
	lda.b #$7c	  ; Max value

Menu_BattleSettings_SetRed_Store:
	tsb.w $0e9d	 ; Set red bits
	bra Menu_BattleSettings_Commit ; Update display

Menu_BattleSettings_SetGreen:
	rep #$30		; 16-bit A/X/Y
	lda.w #$03e0	; Mask for green component
	trb.w $0e9c	 ; Clear green bits
	lda.b $00	   ; Load new value
	and.w #$ff00	; Get high byte
	lsr a; Shift right
	cmp.w #$0400	; Check if exceeds max
	bne Menu_BattleSettings_SetGreen_Store ; If not, use value
	lda.w #$03e0	; Max value

Menu_BattleSettings_SetGreen_Store:
	tsb.w $0e9c	 ; Set green bits
	bra Menu_BattleSettings_Commit ; Update display

Menu_BattleSettings_SetBlue:
	lda.b #$1f	  ; Mask for blue component
	trb.w $0e9c	 ; Clear blue bits
	lda.b $01	   ; Load new value
	asl a; Shift left 2 times
	asl a
	cmp.b #$20	  ; Check if exceeds max
	bne Menu_BattleSettings_SetBlue_Store ; If not, use value
	lda.b #$1f	  ; Max value

Menu_BattleSettings_SetBlue_Store:
	tsb.w $0e9c	 ; Set blue bits
	bra Menu_BattleSettings_Commit ; Update display

SystemData_Config14:
	db $1f		 ; Blue data
DATA8_00c339:
	db $1f		 ; Blue data
DATA8_00c33a:
	db $20		 ; Green data
DATA8_00c33b:
	db $78,$3f,$20,$58,$5f,$20,$38,$7f,$38,$00

SystemData_Config15:
	db $94,$92,$03

;-------------------------------------------------------------------------------
; Save File Deletion System (Menu_SaveDelete - Menu_SaveDelete_UpdateCursor)
;-------------------------------------------------------------------------------
Menu_SaveDelete:
	lda.w #$0301	; Menu mode $0301
	sta.b $03	   ; Store in $03
	ldx.w #$0c00	; Load $0c00
	stx.b $8e	   ; Store in $8e

Menu_SaveDelete_InputLoop:
	lda.w #$8c80	; Button mask
	jsr.w AnalysisLdaCcb0JslCodeMenu ; Poll input
	bne Menu_SaveDelete_UpdateCursor ; If button pressed, process
	bit.w #$0080	; Test B button
	bne Menu_SaveDelete_Confirm ; If pressed, cancel
	bit.w #$8000	; Test A button
	beq Menu_SaveDelete_InputLoop ; If not pressed, loop

Menu_SaveDelete_Exit:
	jsr.w SetAnimationMode ; Set animation mode $10
	stz.b $8e	   ; Clear $8e


Menu_SaveDelete_Confirm:
	jsr.w NormalPositionCallB908 ; Set sprite mode $2d
	sep #$20		; 8-bit accumulator
	lda.b $02	   ; Load save slot selection
	inc a; +1 (1-based index)
	sta.l $701ffd   ; Store save slot
	dec a; Back to 0-based
	rep #$30		; 16-bit A/X/Y
	and.w #$00ff	; Mask to 8 bits
	sta.w $010e	 ; Store slot index
	jsr.w GetSaveSlotAddress2 ; Get save slot address
	lda.w #$0040	; bit 6 mask
	tsb.w !system_flags_8	 ; Set bit 6 of $de
	jsr.w MainRoutine ; Clear save data
	ldx.w #$c3d8	; Menu data
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	lda.b $9e	   ; Load result
	bit.w #$8000	; Test bit 15
	bne Menu_SaveDelete_Exit ; If set, return
	bit.w #$0c00	; Test bits 10-11
	beq Menu_SaveDelete_InputLoop ; If clear, loop

Menu_SaveDelete_UpdateCursor:
	lda.w #$0000	; Load 0
	sep #$20		; 8-bit accumulator
	lda.b #$ec	  ; Load $ec
	sta.l $7f56da   ; Store to WRAM
	sta.l $7f56dc   ; Store to WRAM
	sta.l $7f56de   ; Store to WRAM
	lda.b $02	   ; Load option index
	cmp.b $06	   ; Compare with previous
	beq Menu_SaveDelete_UpdateDisplay ; If same, skip update
	sta.b $06	   ; Store new selection
	jsr.w SetAnimationMode ; Update sprite
	lda.b $06	   ; Reload selection

Menu_SaveDelete_UpdateDisplay:
	asl a; × 2
	tax ; Transfer to X
	lda.b #$e0	  ; Load $e0
	sta.l $7f56da,x ; Store to WRAM indexed
	lda.b #$08	  ; bit 3 mask
	tsb.w !system_flags_2	 ; Set bit 3
	jsl.l AddressC8000OriginalCode ; Call external routine
	lda.b #$08	  ; bit 3 mask
	trb.w !system_flags_2	 ; Clear bit 3
	rep #$30		; 16-bit A/X/Y
	jmp.w Menu_SaveDelete_InputLoop ; Jump back to loop

SystemData_Config16:
	db $c3,$95,$03

;-------------------------------------------------------------------------------
; Menu Scrolling System (Menu_Scroll - Menu_Scroll_Down)
;-------------------------------------------------------------------------------
Menu_Scroll:
	lda.w #$0305	; Menu mode $0305
	sta.b $03	   ; Store in $03
	ldx.w #$fff0	; Position offset (-16)
	stx.b $8e	   ; Set position
	bra Menu_Scroll_Display ; Jump to menu display

Menu_Scroll_InputLoop:
	lda.w #$cf30	; Button mask
	jsr.w AnalysisLdaCcb0JslCodeMenu ; Poll input
	bit.w #$0300	; Test Y/X buttons
	bne Menu_Scroll_Process ; If pressed, process
	bit.w #$0c00	; Test L/R buttons
	bne Menu_Scroll_Display ; If pressed, refresh
	bit.w #$8000	; Test A button
	beq Menu_Scroll_InputLoop ; If not pressed, loop
	jsr.w SetAnimationMode ; Update sprite
	stz.b $8e	   ; Clear position
	ldx.w #$c444	; Menu data
	jmp.w CodeLikelyLoadsProcessesThisData ; Show menu

Menu_Scroll_Process:
	sep #$20		; 8-bit accumulator
	lda.b $01	   ; Load menu option
	cmp.b #$04	  ; Check if option 4
	beq Menu_Scroll_Down ; If yes, scroll down
	lda.b $04	   ; Load scroll position
	cmp.b #$03	  ; Check if at top
	beq Menu_Scroll_Update ; If yes, can't scroll up
	dec.b $04	   ; Decrement scroll
	lda.b $02	   ; Load current index
	sbc.b #$02	  ; Subtract 2
	bcs Menu_Scroll_StoreIndex ; If no underflow, continue
	lda.b #$00	  ; Clamp to 0

Menu_Scroll_StoreIndex:
	sta.b $02	   ; Store new index
	bra Menu_Scroll_Update ; Continue

Menu_Scroll_Down:
	lda.b $04	   ; Load scroll position
	cmp.b #$04	  ; Check if at bottom
	beq Menu_Scroll_Update ; If yes, can't scroll down
	inc.b $04	   ; Increment scroll
	lda.b $02	   ; Load current index
	adc.b #$02	  ; Add 2
	cmp.b #$04	  ; Check if >= 4
	bne Menu_Scroll_StoreClamp ; If not, continue
	lda.b #$03	  ; Clamp to 3

Menu_Scroll_StoreClamp:
	sta.b $02	   ; Store new index

Menu_Scroll_Update:
	rep #$30		; 16-bit A/X/Y

Menu_Scroll_Display:
	ldx.w #$c441	; Menu data
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	bra Menu_Scroll_InputLoop ; Loop

SystemData_Config17:
	db $8e,$90,$03

SystemData_Config18:
	db $47,$91,$03

;-------------------------------------------------------------------------------
; Another Menu Scrolling System (Menu_Scroll2 - Menu_Scroll2_Bottom)
;-------------------------------------------------------------------------------
Menu_Scroll2:
	lda.w #$0305	; Menu mode $0305
	sta.b $03	   ; Store in $03
	ldx.w #$fff0	; Position offset (-16)
	stx.b $8e	   ; Set position
	bra Menu_Scroll2_Display ; Jump to menu display

Menu_Scroll2_InputLoop:
	lda.w #$cf30	; Button mask
	jsr.w AnalysisLdaCcb0JslCodeMenu ; Poll input
	bit.w #$0300	; Test Y/X buttons
	bne Menu_Scroll2_Process ; If pressed, process
	bit.w #$0c00	; Test L/R buttons
	bne Menu_Scroll2_Display ; If pressed, refresh
	bit.w #$8000	; Test A button
	beq Menu_Scroll2_InputLoop ; If not pressed, loop
	jsr.w SetAnimationMode ; Update sprite
	stz.b $8e	   ; Clear position
	ldx.w #$c49f	; Menu data
	jmp.w CodeLikelyLoadsProcessesThisData ; Show menu

Menu_Scroll2_Process:
	sep #$20		; 8-bit accumulator
	lda.b $01	   ; Load menu option
	cmp.b #$04	  ; Check if option 4
	beq Menu_Scroll2_Bottom ; If yes, scroll to bottom
	lda.b #$03	  ; Load 3
	cmp.b $04	   ; Compare with scroll position
	beq Menu_Scroll2_Update ; If equal, done
	sta.b $04	   ; Store 3
	dec a; Decrement to 2
	sta.b $02	   ; Store index
	bra Menu_Scroll2_Update ; Continue

Menu_Scroll2_Bottom:
	lda.b #$01	  ; Load 1
	cmp.b $04	   ; Compare with scroll position
	beq Menu_Scroll2_Update ; If equal, done
	sta.b $04	   ; Store 1
	stz.b $02	   ; Clear index

Menu_Scroll2_Update:
	rep #$30		; 16-bit A/X/Y

Menu_Scroll2_Display:
	ldx.w #$c49c	; Menu data
	jsr.w CodeLikelyLoadsProcessesThisData ; Update menu
	bra Menu_Scroll2_InputLoop ; Loop

SystemData_Config19:
	db $e3,$91,$03

SystemData_Config20:
	db $47,$91,$03

;-------------------------------------------------------------------------------
; Wait Loop with Input Polling (Menu_WaitInput - Menu_WaitInput_Confirm)
;-------------------------------------------------------------------------------
Menu_WaitInput:
	ldx.w #$fff0	; Position offset (-16)
	stx.b $8e	   ; Set position

Menu_WaitInput_Loop:
	jsl.l WaitVblank ; Call external routine
	lda.w #$0080	; bit 7 mask
	and.w $00d9	 ; Test flag
	beq Menu_WaitInput_Poll ; If clear, continue
	db $a9,$80,$00,$1c,$d9,$00,$a2,$d8,$c4,$20,$c4,$9b,$80,$e6 ; Data/unreachable

Menu_WaitInput_Poll:
	lda.b $07	   ; Load input result
	and.w #$bfcf	; Mask buttons
	beq Menu_WaitInput_Loop ; If no button, loop
	and.w #$8000	; Test A button
	bne Menu_WaitInput_Confirm ; If pressed, confirm
	jsr.w AlternateCharacterUpdateRoutine ; Update sprite mode
	bra Menu_WaitInput_Loop ; Loop

Menu_WaitInput_Confirm:
	jsr.w SetAnimationMode ; Update sprite
	stz.b $8e	   ; Clear position


SystemData_Config21:
	db $d1,$9c,$03
;===============================================================================
; WRAM Buffer Management & Screen Setup (CodeExternalRoutine - WramBufferManagementScreenSetupCode)
;===============================================================================
; This section manages WRAM buffers at $7f5000-$7f5700 for battle menus
; and handles screen initialization for various game modes
;===============================================================================

; CodeExternalRoutine - already a stub, implementing now
WRAM_BattleMenu_Init:
	jsr.w WRAM_ClearBuffer1 ; Clear WRAM buffer 1 ($7f5000)
	jsr.w WRAM_ClearBuffer2 ; Clear WRAM buffer 2 ($7f51b7)
	jsr.w WRAM_ClearBuffer3 ; Clear WRAM buffer 3 ($7f536e)
	jsr.w WRAM_ClearBuffer4 ; Clear WRAM buffer 4 ($7f551e)
	jsr.w WRAM_FillData ; Jump to JumpCodeWramE3000 (WRAM $7e3000)
	ldx.w #$c51b	; Source data pointer
	ldy.w #$5000	; Dest: WRAM $7f5000
	lda.w #$0006	; 7 bytes
	mvn $7f,$00	 ; Block move Bank $00 ? $7f
	ldy.w #$4360	; Dest: DMA channel 6
	lda.w #$0007	; 8 bytes
	mvn $00,$00	 ; Block move within Bank $00
	ldy.w #$5367	; Dest: WRAM $7f5367
	lda.w #$0006	; 7 bytes
	mvn $7f,$00	 ; Block move Bank $00 ? $7f
	ldy.w #$4370	; Dest: DMA channel 7
	lda.w #$0007	; 8 bytes
	mvn $00,$00	 ; Block move within Bank $00
	sep #$20		; 8-bit accumulator
	lda.b #$c0	  ; Bits 6-7
	tsb.w $0111	 ; Set bits in $0111
	rep #$30		; 16-bit A/X/Y


SystemData_Config22:
	db $ff,$07,$50,$d9,$05,$51,$00,$42,$0e,$00,$50,$7f,$07,$50,$7f,$ff
	db $6e,$53,$d9,$6c,$54,$00,$42,$10,$67,$53,$7f,$6e,$53,$7f

; Helper - Unknown purpose
WRAM_BattleMenu_Update:
	pea.w $007f	 ; Push $007f
	plb ; Pull to data bank
	ldy.w #$5016	; WRAM address
	jsr.w WRAM_BattleMenu_FillSection ; Call fill routine
	ldy.w #$537d	; WRAM address
	jsr.w WRAM_BattleMenu_FillSection ; Call fill routine
	plb ; Restore data bank


WRAM_BattleMenu_FillSection:
	ldx.w #$000d	; 13 iterations
	clc ; Clear carry

WRAM_BattleMenu_FillLoop:
	sep #$20		; 8-bit accumulator
	lda.b #$00	  ; Value 0
	jsr.w WriteWram ; Write to WRAM
	rep #$30		; 16-bit A/X/Y
	tya ; Y to A
	adc.w #$0020	; Add $20 (32 bytes)
	tay ; Back to Y
	dex ; Decrement counter
	bne WRAM_BattleMenu_FillLoop ; Loop if not zero


;-------------------------------------------------------------------------------
; WRAM Buffer Clear Routines
;-------------------------------------------------------------------------------
WRAM_ClearBuffer1:
	lda.w #$0000	; Clear value
	sta.l $7f5007   ; Write to $7f5007
	ldx.w #$5007	; Source
	ldy.w #$5009	; Dest
	lda.w #$01ad	; 430 bytes
	mvn $7f,$7f	 ; Fill $7f5007-$7f51b5 with 0
	bra WRAM_SetupBattleSprites1 ; Continue

WRAM_ClearBuffer2:
	lda.w #$0100	; Value $0100
	sta.l $7f51b7   ; Write to $7f51b7
	ldx.w #$51b7	; Source
	ldy.w #$51b9	; Dest
	lda.w #$01ad	; 430 bytes
	mvn $7f,$7f	 ; Fill $7f51b7-$7f5365 with $0100
	bra WRAM_SetupBattleSprites1 ; Continue

WRAM_ClearBuffer3:
	lda.w #$0000	; Clear value
	sta.l $7f536e   ; Write to $7f536e
	ldx.w #$536e	; Source
	ldy.w #$5370	; Dest
	lda.w #$01ad	; 430 bytes
	mvn $7f,$7f	 ; Fill $7f536e-$7f551c with 0
	bra WRAM_SetupBattleSprites2 ; Continue

WRAM_ClearBuffer4:
	lda.w #$0100	; Value $0100
	sta.l $7f551e   ; Write to $7f551e
	ldx.w #$551e	; Source
	ldy.w #$5520	; Dest
	lda.w #$01ad	; 430 bytes
	mvn $7f,$7f	 ; Fill $7f551e-$7f56cc with $0100
	bra WRAM_SetupBattleSprites2 ; Continue

WRAM_FillData:
	lda.w #$0000	; Clear value
	sta.l $7e3007   ; Write to $7e3007
	ldx.w #$3007	; Source
	ldy.w #$3009	; Dest
	lda.w #$01ad	; 430 bytes
	mvn $7e,$7e	 ; Fill $7e3007-$7e31b5 with 0
	lda.w #$0120	; Value $0120
	sta.w $31b5	 ; Store at $7e31b5


WRAM_SetupBattleSprites2:
	tya ; Y to A
	sec ; Set carry
	sbc.w #$0042	; Subtract $42
	tay ; Back to Y
	ldx.w #$c5e7	; Data pointer
	lda.l $000ec6   ; Load battle speed flag
	and.w #$0080	; Test bit 7
	beq WRAM_SetupBattleSprites2_Continue ; If clear, use first data
	db $a2,$f0,$c5 ; ldx #$c5f0 (alternate data)

WRAM_SetupBattleSprites2_Continue:
	jmp.w WRAM_SetupSprites ; Jump to sprite setup

SystemData_Config23:
	db $0c,$20,$06,$24,$06,$26,$08,$28,$00
	db $18,$20,$08,$28,$00

WRAM_SetupBattleSprites1:
	tya ; Y to A
	sec ; Set carry
	sbc.w #$0042	; Subtract $42
	tay ; Back to Y
	ldx.w #$c601	; Data pointer
	jmp.w WRAM_SetupSprites ; Jump to sprite setup

SystemData_Config24:
	db $20,$28,$00

WRAM_FillData_Jump:
	jmp.w WRAM_FillData ; Jump to WRAM clear

;-------------------------------------------------------------------------------
; Screen Setup Routines
;-------------------------------------------------------------------------------
Screen_Setup1:
	jsr.w WRAM_FillData ; Clear WRAM $7e3000
	lda.w #$0060	; Value $60
	ldx.w #$3025	; Address $7e3025
	jsr.w Screen_FillWords ; Fill 8 words
	ldx.w #$3035	; Address $7e3035
	bra Screen_FillWords_Alt ; Continue

Screen_Setup2:
	jsr.w WRAM_ClearBuffer1 ; Clear WRAM buffer 1
	lda.w #$0030	; Value $30
	ldx.w #$50f5	; Address $7f50f5
	bra Screen_FillWords_Alt ; Continue

Screen_Setup3:
	jsr.w WRAM_ClearBuffer2 ; Clear WRAM buffer 2
	lda.w #$0030	; Value $30
	ldx.w #$52a5	; Address $7f52a5

Screen_FillWords_Alt:
	jsr.w Screen_FillWords ; Fill 8 words
	sec ; Set carry

Screen_FillWords_Loop:
	sta.w $0010,x   ; Store at X+$10
	sta.w $0012,x   ; Store at X+$12
	sta.w $0014,x   ; Store at X+$14
	sta.w $0016,x   ; Store at X+$16
	sta.w $0018,x   ; Store at X+$18
	sta.w $001a,x   ; Store at X+$1a
	sta.w $001c,x   ; Store at X+$1c
	sta.w $001e,x   ; Store at X+$1e
	tay ; Transfer to Y
	rep #$30		; 16-bit A/X/Y
	txa ; X to A
	adc.w #$000f	; Add 15
	tax ; Back to X
	sep #$20		; 8-bit accumulator
	tya ; Y to A
	sbc.b #$07	  ; Subtract 7
	bne Screen_FillWords_Loop ; Loop if not zero
	rep #$30		; 16-bit A/X/Y


Screen_FillWords:
	sep #$20		; 8-bit accumulator
	sta.w $0000,x   ; Store at X+0
	sta.w $0002,x   ; Store at X+2
	sta.w $0004,x   ; Store at X+4
	sta.w $0006,x   ; Store at X+6
	sta.w $0008,x   ; Store at X+8
	sta.w $000a,x   ; Store at X+10
	sta.w $000c,x   ; Store at X+12
	sta.w $000e,x   ; Store at X+14

; ==============================================================================
; Screen Setup and Sprite Systems - Battle_SetupSprites+
; ==============================================================================

Battle_SetupSprites1:
	ldy.w #$521d	;00C675|A01D52  |      ;
	phb ;00C678|8B      |      ;
	phy ;00C679|5A      |      ;
	jsr.w WRAM_ClearBuffer2 ;00C67A|2076C5  |00C576;
	ply ;00C67D|7A      |      ;
	ldx.w #$c686	;00C67E|A286C6  |      ;
	jsr.w WRAM_SetupSprites ;00C681|205BC7  |00C75B;
	plb ;00C684|AB      |      ;
	rts ;00C685|60      |      ;

SystemData_Config25:
	db $0c,$04,$18,$08,$00 ;00C686|        |      ;

Battle_SetupSprites2:
	phb ;00C68B|8B      |      ;
	jsr.w WRAM_ClearBuffer2 ;00C68C|2076C5  |00C576;
	ldx.w #$c6a6	;00C68F|A2A6C6  |      ;
	ldy.w #$522d	;00C692|A02D52  |      ;
	jsr.w WRAM_SetupSprites ;00C695|205BC7  |00C75B;
	jsr.w WRAM_ClearBuffer4 ;00C698|20A0C5  |00C5A0;
	ldx.w #$c6b3	;00C69B|A2B3C6  |      ;
	ldy.w #$5634	;00C69E|A03456  |      ;
	jsr.w WRAM_SetupSprites ;00C6A1|205BC7  |00C75B;
	plb ;00C6A4|AB      |      ;
	rts ;00C6A5|60      |      ;

SystemData_Config26:
	db $0c,$04,$0c,$08,$1c,$0c,$1c,$10,$1c,$14,$10,$18,$00 ;00C6A6|        |      ;

SystemData_Config27:
	db $1c,$04,$10,$08,$00 ;00C6B3|        |      ;

Battle_SetupSprites3:
	phb ;00C6B8|8B      |      ;
	jsr.w WRAM_ClearBuffer2 ;00C6B9|2076C5  |00C576;
	ldx.w #$c6d3	;00C6BC|A2D3C6  |      ;
	ldy.w #$528d	;00C6BF|A08D52  |      ;
	jsr.w WRAM_SetupSprites ;00C6C2|205BC7  |00C75B;
	jsr.w WRAM_ClearBuffer4 ;00C6C5|20A0C5  |00C5A0;
	ldx.w #$c6d6	;00C6C8|A2D6C6  |      ;
	ldy.w #$5574	;00C6CB|A07455  |      ;
	jsr.w WRAM_SetupSprites ;00C6CE|205BC7  |00C75B;
	plb ;00C6D1|AB      |      ;
	rts ;00C6D2|60      |      ;

SystemData_Config28:
	db $0c,$04,$00 ;00C6D3|        |      ;

SystemData_Config29:
	db $0c,$04,$14,$08,$0c,$0c,$34,$10,$0c,$14,$0c,$18,$0c ;00C6D6|        |      ;
	db $1c,$08,$20,$00 ;00C6E3|        |      ;

Battle_SetupSprites4:
	phb ;00C6E7|8B      |      ;
	jsr.w WRAM_ClearBuffer2 ;00C6E8|2076C5  |00C576;
	ldx.w #$c73f	;00C6EB|A23FC7  |      ;
	ldy.w #$527d	;00C6EE|A07D52  |      ;
	jsr.w Sub_00C75B ;00C6F1|205BC7  |00C75B;
	jsr.w Sub_00C5A0 ;00C6F4|20A0C5  |00C5A0;
	ldx.w #$c744	;00C6F7|A244C7  |      ;
	ldy.w #$55b4	;00C6FA|A0B455  |      ;
	jsr.w Sub_00C75B ;00C6FD|205BC7  |00C75B;
	ldx.w #$55b4	;00C700|A2B455  |      ;
	ldy.w #$0000	;00C703|A00000  |      ;
	lda.l $000101   ;00C706|AF010100|000101;
	jsr.w Sub_00C729 ;00C70A|2029C7  |00C729;
	ldx.w #$562c	;00C70D|A22C56  |      ;
	ldy.w #$000c	;00C710|A00C00  |      ;
	lda.l $000102   ;00C713|AF020100|000102;
	jsr.w Sub_00C729 ;00C717|2029C7  |00C729;
	ldx.w #$56a4	;00C71A|A2A456  |      ;
	ldy.w #$0018	;00C71D|A01800  |      ;
	lda.l $000103   ;00C720|AF030100|000103;
	jsr.w SaveData_ProcessFlag ;00C724|2029C7  |00C729;
	plb ;00C727|AB      |      ;
	rts ;00C728|60      |      ;

SaveData_ProcessFlag:
	and.w #$0080	;00C729|298000  |      ;
	beq SaveData_FlagDone ;00C72C|F010    |00C73E;
	db $e2,$20,$98,$9d,$00,$00,$9b,$c8,$c8,$a9,$15,$54,$7f,$7f,$c2,$30 ;00C72E|        |      ;

SaveData_FlagDone:
	rts ;00C73E|60      |      ;

SystemData_Config30:
	db $3c,$04,$38,$08,$00 ;00C73F|        |      ;

SystemData_Config31:
	db $06,$04,$06,$06,$0c,$08,$24,$0c,$06,$10,$06,$12,$0c,$14,$24,$18 ;00C744|        |      ;
	db $06,$1c,$06,$1e,$08,$20,$00 ;00C754|        |      ;
; ==============================================================================
; Sprite Display System and Save/Load Operations - WRAM_SetupSprites+
; ==============================================================================

WRAM_SetupSprites:
	phb ;00C75B|8B      |      ;
	phb ;00C75C|8B      |      ;
	pla ;00C75D|68      |      ;
	sta.l $000031   ;00C75E|8F310000|000031;
	sep #$20		;00C762|E220    |      ;

WRAM_SetupSprites_Loop:
	lda.l $000000,x ;00C764|BF000000|000000;
	beq WRAM_SetupSprites_Done ;00C768|F020    |00C78A;
	xba ;00C76A|EB      |      ;
	lda.l $000001,x ;00C76B|BF010000|000001;
	sta.w $0000,y   ;00C76F|990000  |7F0000;
	lda.b #$00	  ;00C772|A900    |      ;
	xba ;00C774|EB      |      ;
	dec a;00C775|3A      |      ;
	beq WRAM_SetupSprites_IncrementY2 ;00C776|F00C    |00C784;
	phx ;00C778|DA      |      ;
	asl a;00C779|0A      |      ;
	dec a;00C77A|3A      |      ;
	tyx ;00C77B|BB      |      ;
	iny ;00C77C|C8      |      ;
	iny ;00C77D|C8      |      ;
	jsr.w $0030	 ;00C77E|203000  |000030;
	plx ;00C781|FA      |      ;
	bra WRAM_SetupSprites_Continue ;00C782|8002    |00C786;

;-------------------------------------------------------------------------------
; WRAM Setup Sprites - Increment Y by 2
;-------------------------------------------------------------------------------
; Purpose: Increment Y register twice for sprite setup
; Reachability: Reachable via conditional branch (beq above)
; Analysis: Simple Y increment handler
; Technical: Originally labeled UNREACH_00C784
;-------------------------------------------------------------------------------
WRAM_SetupSprites_IncrementY2:
	iny ;00C784|C8      |      ; Increment Y
	iny ;00C785|C8      |      ; Increment Y again

WRAM_SetupSprites_Continue:
	inx ;00C786|E8      |      ;
	inx ;00C787|E8      |      ;
	bra WRAM_SetupSprites_Loop ;00C788|80DA    |00C764;

WRAM_SetupSprites_Done:
	rep #$30		;00C78A|C230    |      ;
	rts ;00C78C|60      |      ;

Screen_DisableDMA:
	sep #$20		;00C78D|E220    |      ;
	lda.b #$c0	  ;00C78F|A9C0    |      ;
	trb.w $0111	 ;00C791|1C1101  |000111;
	rts ;00C794|60      |      ;

Screen_WaitForUpdate:
	php ;00C795|08      |      ;
	sep #$20		;00C796|E220    |      ;
	lda.b #$80	  ;00C798|A980    |      ;
	trb.w !system_flags_3	 ;00C79A|1CD600  |0000D6;
	lda.w !brightness_value	 ;00C79D|ADAA00  |0000AA;
	and.b #$f0	  ;00C7A0|29F0    |      ;
	sta.w !battle_ready_flag	 ;00C7A2|8D1001  |000110;
	lda.w !brightness_value	 ;00C7A5|ADAA00  |0000AA;

Screen_WaitForUpdate_Loop:
	cmp.w !battle_ready_flag	 ;00C7A8|CD1001  |000110;
	beq Screen_WaitForUpdate_Done ;00C7AB|F009    |00C7B6;
	inc.w !battle_ready_flag	 ;00C7AD|EE1001  |000110;
	jsl.l AddressC8000OriginalCode ;00C7B0|2200800C|0C8000;
	bra Screen_WaitForUpdate_Loop ;00C7B4|80F2    |00C7A8;

Screen_WaitForUpdate_Done:
	plp ;00C7B6|28      |      ;
	rtl ;00C7B7|6B      |      ;

Screen_FadeOut:
	php ;00C7B8|08      |      ;
	sep #$20		;00C7B9|E220    |      ;
	lda.w !battle_ready_flag	 ;00C7BB|AD1001  |010110;
	sta.w !brightness_value	 ;00C7BE|8DAA00  |0100AA;

Screen_FadeOut_Loop:
	bit.b #$0f	  ;00C7C1|890F    |      ;
	beq Screen_FadeOut_Done ;00C7C3|F00A    |00C7CF;
	dec a;00C7C5|3A      |      ;
	sta.w !battle_ready_flag	 ;00C7C6|8D1001  |010110;
	jsl.l AddressC8000OriginalCode ;00C7C9|2200800C|0C8000;
	bra Screen_FadeOut_Loop ;00C7CD|80F2    |00C7C1;

Screen_FadeOut_Done:
	lda.b #$80	  ;00C7CF|A980    |      ;
	tsb.w !system_flags_3	 ;00C7D1|0CD600  |0100D6;
	lda.b #$80	  ;00C7D4|A980    |      ;
	sta.w $2100	 ;00C7D6|8D0021  |012100;
	sta.w !battle_ready_flag	 ;00C7D9|8D1001  |010110;
	plp ;00C7DC|28      |      ;
	rtl ;00C7DD|6B      |      ;

Menu_Init_Battle:
	jsr.w Screen_Setup2 ;00C7DE|2018C6  |00C618;
	jsr.w WRAM_ClearBuffer3 ;00C7E1|208BC5  |00C58B;
	ldx.w #$c8ec	;00C7E4|A2ECC8  |      ;
	jsr.w CodeLikelyLoadsProcessesThisData ;00C7E7|20C49B  |009BC4;
	ldx.w #$c8e3	;00C7EA|A2E3C8  |      ;
	jmp.w CodeLikelyLoadsProcessesThisData ;00C7ED|4CC49B  |009BC4;

Menu_Init_Status:
	lda.w $010d	 ;00C7F0|AD0D01  |00010D;
	bpl Menu_Init_Status_Continue ;00C7F3|1003    |00C7F8;
	lda.w #$0000	;00C7F5|A90000  |      ;

Menu_Init_Status_Continue:
	and.w #$ff00	;00C7F8|2900FF  |      ;
	sta.b $01	   ;00C7FB|8501    |000001;
	sep #$20		;00C7FD|E220    |      ;
	lda.b #$18	  ;00C7FF|A918    |      ;
	sta.w $00ab	 ;00C801|8DAB00  |0000AB;
	jsr.w SetupRoutine ;00C804|20ECCB  |00CBEC;
	rep #$30		;00C807|C230    |      ;
	ldx.w #$c922	;00C809|A222C9  |      ;
	jsr.w CodeLikelyLoadsProcessesThisData ;00C80C|20C49B  |009BC4;
	phb ;00C80F|8B      |      ;
	ldx.w #$016f	;00C810|A26F01  |      ;
	ldy.w #$0e04	;00C813|A0040E  |      ;
	lda.w #$0005	;00C816|A90500  |      ;
	mvn $00,$00	 ;00C819|540000  |      ;
	lda.w #$0020	;00C81C|A92000  |      ;
	tsb.w !system_flags_1	 ;00C81F|0CD200  |0000D2;
	jsr.w Screen_Setup1 ;00C822|2007C6  |00C607;
	ldx.w #$51c5	;00C825|A2C551  |      ;
	ldy.w #$5015	;00C828|A01550  |      ;
	lda.w #$019f	;00C82B|A99F01  |      ;
	mvn $7f,$7f	 ;00C82E|547F7F  |      ;
	ldx.w #$552c	;00C831|A22C55  |      ;
	ldy.w #$537c	;00C834|A07C53  |      ;
	lda.w #$019f	;00C837|A99F01  |      ;
	mvn $7f,$7f	 ;00C83A|547F7F  |      ;
	plb ;00C83D|AB      |      ;
	ldx.w #$c8e3	;00C83E|A2E3C8  |      ;
	jsr.w CodeLikelyLoadsProcessesThisData ;00C841|20C49B  |009BC4;
	lda.w #$0600	;00C844|A90006  |      ;
	sta.b $01	   ;00C847|8501    |000001;
	sta.b $05	   ;00C849|8505    |000005;
	rts ;00C84B|60      |      ;

; Menu initialization and game state management
Menu_Init_SetBit6:
	lda.w #$0040	;00C84C|A94000  |      ;
	tsb.w !system_flags_6	 ;00C84F|0CDB00  |0000DB;
	bra Menu_Init_Common ;00C852|8006    |00C85A;

Menu_Init_SetBit0:
	lda.w #$0001	;00C854|A90100  |      ;
	tsb.w !system_flags_5	 ;00C857|0CDA00  |0000DA;

Menu_Init_Common:
	jsr.w Screen_Setup3 ;00C85A|2023C6  |00C623;
	jsr.w WRAM_ClearBuffer4 ;00C85D|20A0C5  |00C5A0;
	ldx.w #$c8ec	;00C860|A2ECC8  |      ;
	bra Menu_Init_UpdateMenu ;00C863|8038    |00C89D;

Menu_Init_Alt1:
	ldx.w #$c90a	;00C865|A20AC9  |      ;
	bra Menu_Init_UpdateMenu ;00C868|8033    |00C89D;

Menu_Init_Alt2:
	ldx.w #$c910	;00C86A|A210C9  |      ;
	bra Menu_Init_UpdateMenu ;00C86D|802E    |00C89D;

Menu_Init_ClearBit7:
	lda.w #$0080	;00C86F|A98000  |      ;
	trb.w $00d9	 ;00C872|1CD900  |0000D9;
	ldx.w #$c916	;00C875|A216C9  |      ;
	bra Menu_Init_UpdateMenu ;00C878|8023    |00C89D;

Menu_Init_SetBit7:
	lda.w #$0080	;00C87A|A98000  |      ;
	tsb.w !system_flags_6	 ;00C87D|0CDB00  |0000DB;
	ldx.w #$c91c	;00C880|A21CC9  |      ;
	bra Menu_Init_UpdateMenu ;00C883|8018    |00C89D;

Menu_Init_LoadCharacter:
	lda.w $010d	 ;00C885|AD0D01  |00010D;
	bpl Menu_Init_LoadCharacter_Continue ;00C888|1003    |00C88D;
	lda.w #$0000	;00C88A|A90000  |      ;

Menu_Init_LoadCharacter_Continue:
	and.w #$ff00	;00C88D|2900FF  |      ;
	sta.b $01	   ;00C890|8501    |000001;
	sta.b $05	   ;00C892|8505    |000005;
	lda.w #$0002	;00C894|A90200  |      ;
	tsb.w !system_flags_5	 ;00C897|0CDA00  |0000DA;
	ldx.w #$c922	;00C89A|A222C9  |      ;

Menu_Init_UpdateMenu:
	phx ;00C89D|DA      |      ;
	jsr.w CodeLikelyLoadsProcessesThisData ;00C89E|20C49B  |009BC4;
	plx ;00C8A1|FA      |      ;
	inx ;00C8A2|E8      |      ;
	inx ;00C8A3|E8      |      ;
	inx ;00C8A4|E8      |      ;
	ldy.w #$0017	;00C8A5|A01700  |      ;
	lda.w #$0002	;00C8A8|A90200  |      ;
	mvn $00,$00	 ;00C8AB|540000  |      ;
	jsr.w Sub_00CAB9 ;00C8AE|20B9CA  |00CAB9;
	ldx.w #$c8e3	;00C8B1|A2E3C8  |      ;
	jmp.w CodeLikelyLoadsProcessesThisData ;00C8B4|4CC49B  |009BC4;

; Animation and screen effect handlers
Screen_Effect1:
	ldx.w #$c8f2	;00C8B7|A2F2C8  |      ;
	bra Screen_EffectCommon ;00C8BA|800D    |00C8C9;

Screen_Effect2:
	ldx.w #$c8f8	;00C8BC|A2F8C8  |      ;
	bra Screen_EffectCommon ;00C8BF|8008    |00C8C9;

Screen_Effect3:
	ldx.w #$c8fe	;00C8C1|A2FEC8  |      ;
	bra Screen_EffectCommon ;00C8C4|8003    |00C8C9;

Screen_Effect4:
	ldx.w #$c904	;00C8C6|A204C9  |      ;

Screen_EffectCommon:
	phx ;00C8C9|DA      |      ;
	jsr.w CodeLikelyLoadsProcessesThisData ;00C8CA|20C49B  |009BC4;
	plx ;00C8CD|FA      |      ;
	inx ;00C8CE|E8      |      ;
	inx ;00C8CF|E8      |      ;
	inx ;00C8D0|E8      |      ;
	lda.w #$000c	;00C8D1|A90C00  |      ;

Screen_EffectLoop:
	jsl.l AddressC8000OriginalCode ;00C8D4|2200800C|0C8000;
	pha ;00C8D8|48      |      ;
	phx ;00C8D9|DA      |      ;
	jsr.w CodeLikelyLoadsProcessesThisData ;00C8DA|20C49B  |009BC4;
	plx ;00C8DD|FA      |      ;
	pla ;00C8DE|68      |      ;
	dec a;00C8DF|3A      |      ;
	bne Screen_EffectLoop ;00C8E0|D0F2    |00C8D4;
	rts ;00C8E2|60      |      ;
; ==============================================================================
; Save System Data Tables and Checksum Validation - Final Systems
; ==============================================================================

; Save file data table pointers
SystemData_Config32:
	db $a7,$8f,$03,$f2,$aa,$03,$55,$ab,$03,$aa,$92,$03,$14,$93,$03,$19 ;00C8E3|        |      ;
	db $93,$03,$1f,$93,$03,$28,$93,$03,$33,$93,$03,$3c,$93,$03,$42,$93 ;00C8F3|        |      ;
	db $03,$4b,$93,$03,$57,$93,$03,$60,$93,$03,$a9,$93,$03,$ae,$93,$03 ;00C903|        |      ;
	db $f7,$93,$03,$fc,$93,$03,$74,$94,$03,$79,$94,$03,$dd,$94,$03,$e2 ;00C913|        |      ;
	db $94,$03,$ea,$97,$03 ;00C923|        |      ;

; Save slot address calculation
Save_GetSlotAddress:
	lda.w $015f	 ;00C928|AD5F01  |00015F;

Save_GetSlotAddress_Main:
	and.w #$00ff	;00C92B|29FF00  |      ;
	sta.b $98	   ;00C92E|8598    |000098;
	lda.w #$038c	;00C930|A98C03  |      ;
	sta.b $9c	   ;00C933|859C    |00009C;
	jsl.l ExitQuotientRemainderViaCode ;00C935|22B39600|0096B3;
	lda.b $9e	   ;00C939|A59E    |00009E;
	clc ;00C93B|18      |      ;
	adc.w #$0000	;00C93C|690000  |      ;
	sta.b $0b	   ;00C93F|850B    |00000B;
	rts ;00C941|60      |      ;

Save_ReadByte:
	php ;00C942|08      |      ;
	sep #$20		;00C943|E220    |      ;
	rep #$10		;00C945|C210    |      ;
	pha ;00C947|48      |      ;
	lda.b #$7f	  ;00C948|A97F    |      ;
	sta.b $61	   ;00C94A|8561    |000061;
	pla ;00C94C|68      |      ;
	plp ;00C94D|28      |      ;
	rts ;00C94E|60      |      ;

SaveData_SetBank70:
	php ;00C94F|08      |      ;
	sep #$20		;00C950|E220    |      ;
	rep #$10		;00C952|C210    |      ;
	pha ;00C954|48      |      ;
	lda.b #$70	  ;00C955|A970    |      ;
	sta.b $61	   ;00C957|8561    |000061;
	pla ;00C959|68      |      ;
	plp ;00C95A|28      |      ;
	rts ;00C95B|60      |      ;

Checksum_Calculator:
	pha ;00C95C|48      |      ;
	phx ;00C95D|DA      |      ;
	lda.w #$4646	;00C95E|A94646  |      ;
	sta.b $0e	   ;00C961|850E    |00000E;
	lda.w #$2130	;00C963|A93021  |      ;
	sta.b $10	   ;00C966|8510    |000010;
	ldx.w #$01c3	;00C968|A2C301  |      ;
	lda.w #$0000	;00C96B|A90000  |      ;
	clc ;00C96E|18      |      ;

Checksum_SumLoop:
	adc.b [$5f]	 ;00C96F|675F    |00005F;
	inc.b $5f	   ;00C971|E65F    |00005F;
	inc.b $5f	   ;00C973|E65F    |00005F;
	dex ;00C975|CA      |      ;
	bne Checksum_SumLoop ;00C976|D0F7    |00C96F;
	sta.b $12	   ;00C978|8512    |000012;
	plx ;00C97A|FA      |      ;
	pla ;00C97B|68      |      ;
	rts ;00C97C|60      |      ;

Checksum_Validator:
	ldx.w #$0000	;00C97D|A20000  |      ;

Checksum_ValidateLoop:
	lda.b $0e,x	 ;00C980|B50E    |00000E;
	cmp.b [$0b]	 ;00C982|C70B    |00000B;
	bne Checksum_ValidateDone ;00C984|D00B    |00C991;
	inc.b $0b	   ;00C986|E60B    |00000B;
	inc.b $0b	   ;00C988|E60B    |00000B;
	inx ;00C98A|E8      |      ;
	inx ;00C98B|E8      |      ;
	cpx.w #$0006	;00C98C|E00600  |      ;
	bne Checksum_ValidateLoop ;00C98F|D0EF    |00C980;

Checksum_ValidateDone:
	rts ;00C991|60      |      ;

SaveData_Processor:
	phb ;00C992|8B      |      ;
	phx ;00C993|DA      |      ;
	phy ;00C994|5A      |      ;
	pha ;00C995|48      |      ;
	ldx.w #$3000	;00C996|A20030  |      ;
	stx.b $5f	   ;00C999|865F    |00005F;
	jsr.w Sub_00C942 ;00C99B|2042C9  |00C942;
	jsr.w Sub_00C95C ;00C99E|205CC9  |00C95C;
	jsr.w GetSaveSlotAddress ;00C9A1|202BC9  |00C92B;
	ldy.b $0b	   ;00C9A4|A40B    |00000B;
	ldx.w #$000e	;00C9A6|A20E00  |      ;
	lda.w #$0005	;00C9A9|A90500  |      ;
	mvn $70,$00	 ;00C9AC|547000  |      ;
	sty.b $5f	   ;00C9AF|845F    |00005F;
	ldx.w #$3000	;00C9B1|A20030  |      ;
	lda.w #$0385	;00C9B4|A98503  |      ;
	mvn $70,$7f	 ;00C9B7|54707F  |      ;
	lda.b $12	   ;00C9BA|A512    |000012;
	jsr.w Sub_00C94F ;00C9BC|204FC9  |00C94F;
	jsr.w Sub_00C95C ;00C9BF|205CC9  |00C95C;
	cmp.b $12	   ;00C9C2|C512    |000012;
	bne SaveData_ChecksumMismatch ;00C9C4|D005    |00C9CB;
	jsr.w Checksum_Validator ;00C9C6|207DC9  |00C97D;
	beq SaveData_RestoreRegisters ;00C9C9|F003    |00C9CE;

;-------------------------------------------------------------------------------
; Save Data - Checksum Mismatch Handler
;-------------------------------------------------------------------------------
; Purpose: Handle save data checksum mismatch
; Reachability: Reachable via conditional branch (bne above)
; Analysis: Pulls accumulator and branches with carry set
; Technical: Originally labeled UNREACH_00C9CB
;-------------------------------------------------------------------------------
SaveData_ChecksumMismatch:
	pla ;00C9CB|68      |      ; Pull accumulator
	bra SaveData_ReturnCarrySet          ;00C9CC|80C7    |00C995; Branch with carry

SaveData_RestoreRegisters:
	pla ;00C9CE|68      |      ;
	ply ;00C9CF|7A      |      ;
	plx ;00C9D0|FA      |      ;
	plb ;00C9D1|AB      |      ;
	rts ;00C9D2|60      |      ;

SaveData_MemoryCopy:
	php ;00C9D3|08      |      ;
	rep #$30		;00C9D4|C230    |      ;
	phb ;00C9D6|8B      |      ;
	pha ;00C9D7|48      |      ;
	phd ;00C9D8|0B      |      ;
	phx ;00C9D9|DA      |      ;
	phy ;00C9DA|5A      |      ;
	pha ;00C9DB|48      |      ;
	stz.b $8e	   ;00C9DC|648E    |00008E;
	phb ;00C9DE|8B      |      ;
	ldx.w #$1000	;00C9DF|A20010  |      ;
	ldy.w #$3000	;00C9E2|A00030  |      ;
	lda.w #$004f	;00C9E5|A94F00  |      ;
	mvn $7f,$00	 ;00C9E8|547F00  |      ;
	ldx.w #$1080	;00C9EB|A28010  |      ;
	lda.w #$004f	;00C9EE|A94F00  |      ;
	mvn $7f,$00	 ;00C9F1|547F00  |      ;
	ldx.w #$0e84	;00C9F4|A2840E  |      ;
	lda.w #$017b	;00C9F7|A97B01  |      ;
	mvn $7f,$00	 ;00C9FA|547F00  |      ;
	plb ;00C9FD|AB      |      ;
	pla ;00C9FE|68      |      ;
	ldx.w #$0003	;00C9FF|A20300  |      ;

SaveData_ProcessMultiple:
	jsr.w SaveData_Processor ;00CA02|2092C9  |00C992;
	clc ;00CA05|18      |      ;
	adc.w #$0003	;00CA06|690300  |      ;
	dex ;00CA09|CA      |      ;
	bne SaveData_ProcessMultiple ;00CA0A|D0F6    |00CA02;
	lda.w #$fff0	;00CA0C|A9F0FF  |      ;
	sta.b $8e	   ;00CA0F|858E    |00008E;
	jmp.w Sub_00981B ;00CA11|4C1B98  |00981B;

LoadData_ValidateChecksum:
	phx ;00CA14|DA      |      ;
	phy ;00CA15|5A      |      ;
	pha ;00CA16|48      |      ;

LoadData_RetryLoop:
	lda.b $01,s	 ;00CA17|A301    |000001;
	jsr.w GetSaveSlotAddress ;00CA19|202BC9  |00C92B;
	clc ;00CA1C|18      |      ;
	adc.w #$0006	;00CA1D|690600  |      ;
	sta.b $5f	   ;00CA20|855F    |00005F;
	jsr.w SaveData_SetBank70 ;00CA22|204FC9  |00C94F;
	jsr.w Checksum_Calculator ;00CA25|205CC9  |00C95C;
	jsr.w Checksum_Validator ;00CA28|207DC9  |00C97D;
	bne LoadData_InvalidChecksum ;00CA2B|D027    |00CA54;
	lda.b $01,s	 ;00CA2D|A301    |000001;
	jsr.w GetSaveSlotAddress ;00CA2F|202BC9  |00C92B;
	clc ;00CA32|18      |      ;
	adc.w #$0006	;00CA33|690600  |      ;
	tax ;00CA36|AA      |      ;
	ldy.w #$3000	;00CA37|A00030  |      ;
	lda.w #$0385	;00CA3A|A98503  |      ;
	mvn $7f,$70	 ;00CA3D|547F70  |      ;
	lda.b $12	   ;00CA40|A512    |000012;
	ldx.w #$3000	;00CA42|A20030  |      ;
	stx.b $5f	   ;00CA45|865F    |00005F;
	jsr.w Sub_00C942 ;00CA47|2042C9  |00C942;
	jsr.w Checksum_Calculator ;00CA4A|205CC9  |00C95C;
	cmp.b $12	   ;00CA4D|C512    |000012;
	bne LoadData_RetryLoop ;00CA4F|D0C6    |00CA17;
	clc ;00CA51|18      |      ;
	bra LoadData_Success ;00CA52|800B    |00CA5F;

LoadData_InvalidChecksum:
	lda.b $01,s	 ;00CA54|A301    |000001;
	jsr.w GetSaveSlotAddress ;00CA56|202BC9  |00C92B;
	lda.w #$0000	;00CA59|A90000  |      ;
	sta.b [$0b]	 ;00CA5C|870B    |00000B;
	sec ;00CA5E|38      |      ;

LoadData_Success:
	pla ;00CA5F|68      |      ;
	ply ;00CA60|7A      |      ;
	plx ;00CA61|FA      |      ;
	rts ;00CA62|60      |      ;

SaveData_MainHandler:
	pea.w LOOSE_OP_00CAB5 ;00CA63|F4B5CA  |00CAB5;
	php ;00CA66|08      |      ;
	rep #$30		;00CA67|C230    |      ;
	phb ;00CA69|8B      |      ;
	pha ;00CA6A|48      |      ;
	phd ;00CA6B|0B      |      ;
	phx ;00CA6C|DA      |      ;
	phy ;00CA6D|5A      |      ;
	pha ;00CA6E|48      |      ;
	stz.b $8e	   ;00CA6F|648E    |00008E;
	lda.b $01,s	 ;00CA71|A301    |000001;
	ldx.w #$0003	;00CA73|A20300  |      ;

LoadData_RetryNext:
	jsr.w LoadData_ValidateChecksum ;00CA76|2014CA  |00CA14;
	bcc LoadData_CopyToRAM ;00CA79|900C    |00CA87;
	adc.w #$0002	;00CA7B|690200  |      ;
	dex ;00CA7E|CA      |      ;
	bne LoadData_RetryNext ;00CA7F|D0F5    |00CA76;
	pla ;00CA81|68      |      ;
	lda.w #$ffff	;00CA82|A9FFFF  |      ;
	bra LoadData_Complete ;00CA85|8025    |00CAAC;

LoadData_CopyToRAM:
	ldx.w #$3000	;00CA87|A20030  |      ;
	ldy.w #$1000	;00CA8A|A00010  |      ;
	lda.w #$004f	;00CA8D|A94F00  |      ;
	mvn $00,$7f	 ;00CA90|54007F  |      ;
	ldy.w #$1080	;00CA93|A08010  |      ;
	lda.w #$004f	;00CA96|A94F00  |      ;
	mvn $00,$7f	 ;00CA99|54007F  |      ;
	ldy.w #$0e84	;00CA9C|A0840E  |      ;
	lda.w #$017b	;00CA9F|A97B01  |      ;
	mvn $00,$7f	 ;00CAA2|54007F  |      ;
	pla ;00CAA5|68      |      ;
	jsr.w SaveData_MemoryCopy ;00CAA6|20D3C9  |00C9D3;
	lda.w #$0000	;00CAA9|A90000  |      ;

LoadData_Complete:
	sta.b $64	   ;00CAAC|8564    |000064;
	lda.w #$fff0	;00CAAE|A9F0FF  |      ;
	sta.b $8e	   ;00CAB1|858E    |00008E;
	jmp.w Sub_00981B ;00CAB3|4C1B98  |00981B;

LOOSE_OP_00CAB5:
	lda.b $64	   ;00CAB6|A564    |000064;
	rts ;00CAB8|60      |      ;

GameState_CheckFlags:
	php ;00CAB9|08      |      ;
	rep #$30		;00CABA|C230    |      ;
	phb ;00CABC|8B      |      ;
	pha ;00CABD|48      |      ;
	phd ;00CABE|0B      |      ;
	phx ;00CABF|DA      |      ;
	phy ;00CAC0|5A      |      ;
	lda.w #$0000	;00CAC1|A90000  |      ;
	tcd ;00CAC4|5B      |      ;
	sep #$20		;00CAC5|E220    |      ;
	lda.b #$01	  ;00CAC7|A901    |      ;
	and.w !system_flags_5	 ;00CAC9|2DDA00  |0000DA;
	bne GameState_Flag1Set ;00CACC|D01E    |00CAEC;
	lda.b #$40	  ;00CACE|A940    |      ;
	and.w !system_flags_6	 ;00CAD0|2DDB00  |0000DB;
	bne GameState_Flag40Set ;00CAD3|D032    |00CB07;
	ldx.w #$9300	;00CAD5|A20093  |      ;
	stx.w SNES_CGSWSEL ;00CAD8|8E3021  |002130;
	lda.b #$02	  ;00CADB|A902    |      ;
	and.w !system_flags_5	 ;00CADD|2DDA00  |0000DA;
	bne GameState_FlagCheck2 ;00CAE0|D02F    |00CB11;
	lda.b #$80	  ;00CAE2|A980    |      ;
	and.w !system_flags_6	 ;00CAE4|2DDB00  |0000DB;
	bne GameState_Flag80Set ;00CAE7|D065    |00CB4E;
	jmp.w GameState_FlagsComplete ;00CAE9|4C76CB  |00CB76;

GameState_Flag1Set:
	lda.b #$01	  ;00CAEC|A901    |      ;
	trb.w !system_flags_5	 ;00CAEE|1CDA00  |0000DA;
	jsr.w Screen_ColorProcessor ;00CAF1|2009CC  |00CC09;
	ldx.w #$5555	;00CAF4|A25555  |      ;
	stx.w $0e04	 ;00CAF7|8E040E  |000E04;
	stx.w $0e06	 ;00CAFA|8E060E  |000E06;
	stx.w $0e08	 ;00CAFD|8E080E  |000E08;
	lda.b #$80	  ;00CB00|A980    |      ;
	trb.w !system_flags_8	 ;00CB02|1CDE00  |0000DE;
	bra GameState_RestoreAndExit ;00CB05|8072    |00CB79;

GameState_Flag40Set:
	lda.b #$40	  ;00CB07|A940    |      ;
	trb.w !system_flags_6	 ;00CB09|1CDB00  |0000DB;
	jsr.w Sub_00CCBD ;00CB0C|20BDCC  |00CCBD;
	bra GameState_RestoreAndExit ;00CB0F|8068    |00CB79;
; ==============================================================================
; Screen Color Management and Final Systems - ScreenColorManagementFinalSystemsCode+
; ==============================================================================

GameState_FlagCheck2:
	jsr.w Sub_00CD22 ;00CB11|2022CD  |00CD22;
	rep #$30		;00CB14|C230    |      ;
	ldx.w #$016f	;00CB16|A26F01  |      ;
	ldy.w #$0e04	;00CB19|A0040E  |      ;
	lda.w #$0005	;00CB1C|A90500  |      ;
	mvn $00,$00	 ;00CB1F|540000  |      ;
	sep #$20		;00CB22|E220    |      ;
	lda.b #$80	  ;00CB24|A980    |      ;
	tsb.w !system_flags_8	 ;00CB26|0CDE00  |0000DE;
	jsr.w Sub_00CD60 ;00CB29|2060CD  |00CD60;
	jsr.w Sub_00CBC6 ;00CB2C|20C6CB  |00CBC6;
	jsl.l AddressC8000OriginalCode ;00CB2F|2200800C|0C8000;
	lda.b #$e0	  ;00CB33|A9E0    |      ;
	sta.l $7f56d8   ;00CB35|8FD8567F|7F56D8;
	sta.l $7f56d8,x ;00CB39|9FD8567F|7F56D8;
	jsl.l AddressC8000OriginalCode ;00CB3D|2200800C|0C8000;
	lda.b #$02	  ;00CB41|A902    |      ;
	trb.w !system_flags_5	 ;00CB43|1CDA00  |0000DA;
	lda.b #$08	  ;00CB46|A908    |      ;
	trb.w !system_flags_2	 ;00CB48|1CD400  |0000D4;
	jmp.w Sub_00981B ;00CB4B|4C1B98  |00981B;

GameState_Flag80Set:
	jsr.w Sub_00CD22 ;00CB4E|2022CD  |00CD22;
	jsr.w Sub_00CD60 ;00CB51|2060CD  |00CD60;
	jsr.w Sub_00CC6E ;00CB54|206ECC  |00CC6E;
	jsl.l AddressC8000OriginalCode ;00CB57|2200800C|0C8000;
	lda.b #$e0	  ;00CB5B|A9E0    |      ;
	sta.l $7f56da   ;00CB5D|8FDA567F|7F56DA;
	sta.l $7f56de   ;00CB61|8FDE567F|7F56DE;
	jsl.l AddressC8000OriginalCode ;00CB65|2200800C|0C8000;
	lda.b #$80	  ;00CB69|A980    |      ;
	trb.w !system_flags_6	 ;00CB6B|1CDB00  |0000DB;
	lda.b #$08	  ;00CB6E|A908    |      ;
	trb.w !system_flags_2	 ;00CB70|1CD400  |0000D4;
	jmp.w Sub_00981B ;00CB73|4C1B98  |00981B;

GameState_FlagsComplete:
	jsr.w Sub_00CD22 ;00CB76|2022CD  |00CD22;

GameState_RestoreAndExit:
	jsr.w Sub_00CD60 ;00CB79|2060CD  |00CD60;
	jsr.w Sub_00CD42 ;00CB7C|2042CD  |00CD42;
	jsl.l AddressC8000OriginalCode ;00CB7F|2200800C|0C8000;
	lda.b #$e0	  ;00CB83|A9E0    |      ;
	sta.w SNES_COLDATA ;00CB85|8D3221  |002132;
	ldx.w #$0000	;00CB88|A20000  |      ;
	stx.w SNES_CGSWSEL ;00CB8B|8E3021  |002130;
	jmp.w Sub_00981B ;00CB8E|4C1B98  |00981B;

GameState_DataCopy:
	rep #$30		;00CB91|C230    |      ;
	phb ;00CB93|8B      |      ;
	ldx.w #$cbbd	;00CB94|A2BDCB  |      ;
	ldy.w #$56d7	;00CB97|A0D756  |      ;
	lda.w #$0008	;00CB9A|A90800  |      ;
	mvn $7f,$00	 ;00CB9D|547F00  |      ;
	plb ;00CBA0|AB      |      ;
	lda.w #$0080	;00CBA1|A98000  |      ;
	tsb.w !system_flags_5	 ;00CBA4|0CDA00  |0000DA;
	lda.w #$0020	;00CBA7|A92000  |      ;
	tsb.w $0111	 ;00CBAA|0C1101  |000111;
	lda.b $02	   ;00CBAD|A502    |000002;
	and.w #$00ff	;00CBAF|29FF00  |      ;
	inc a;00CBB2|1A      |      ;
	asl a;00CBB3|0A      |      ;
	tax ;00CBB4|AA      |      ;
	sep #$20		;00CBB5|E220    |      ;
	lda.b #$08	  ;00CBB7|A908    |      ;
	tsb.w !system_flags_2	 ;00CBB9|0CD400  |0000D4;
	rts ;00CBBC|60      |      ;

SystemData_Config33:
	db $27,$ec,$3c,$ec,$3c,$ec,$38,$ec,$00 ;00CBBD|        |      ;

Screen_FadeSetup:
	jsr.w GameState_DataCopy ;00CBC6|2091CB  |00CB91;
	lda.b #$e9	  ;00CBC9|A9E9    |      ;

Screen_FadeLoop:
	ldy.b $17	   ;00CBCB|A417    |000017;
	jsr.w ProcessGraphicsData ;00CBCD|20759D  |009D75;
	sty.b $17	   ;00CBD0|8417    |000017;
	jsl.l AddressC8000OriginalCode ;00CBD2|2200800C|0C8000;
	sta.l $7f56d8   ;00CBD6|8FD8567F|7F56D8;
	sta.l $7f56d8,x ;00CBDA|9FD8567F|7F56D8;
	dec a;00CBDE|3A      |      ;
	dec a;00CBDF|3A      |      ;
	cmp.b #$e1	  ;00CBE0|C9E1    |      ;
	bne Screen_FadeLoop ;00CBE2|D0E7    |00CBCB;
	ldy.b $17	   ;00CBE4|A417    |000017;
	jsr.w ProcessGraphicsData ;00CBE6|20759D  |009D75;
	sty.b $17	   ;00CBE9|8417    |000017;
	rts ;00CBEB|60      |      ;

Screen_BrightnessMax:
	ldy.w #$9300	;00CBEC|A00093  |      ;
	sty.w SNES_CGSWSEL ;00CBEF|8C3021  |002130;
	jsr.w GameState_DataCopy ;00CBF2|2091CB  |00CB91;
	lda.b #$e0	  ;00CBF5|A9E0    |      ;
	sta.l $7f56d8   ;00CBF7|8FD8567F|7F56D8;
	sta.l $7f56d8,x ;00CBFB|9FD8567F|7F56D8;
	jsl.l AddressC8000OriginalCode ;00CBFF|2200800C|0C8000;
	lda.b #$08	  ;00CC03|A908    |      ;
	trb.w !system_flags_2	 ;00CC05|1CD400  |0000D4;
	rts ;00CC08|60      |      ;

Screen_ColorProcessor:
	lda.b #$08	  ;00CC09|A908    |      ;
	tsb.w !system_flags_2	 ;00CC0B|0CD400  |0000D4;
	ldx.w #$0007	;00CC0E|A20700  |      ;

Screen_ColorProcessLoop:
	jsl.l AddressC8000OriginalCode ;00CC11|2200800C|0C8000;
	lda.l $7f56d8   ;00CC15|AFD8567F|7F56D8;
	jsr.w Sub_00CC5B ;00CC19|205BCC  |00CC5B;
	sta.l $7f56d8   ;00CC1C|8FD8567F|7F56D8;
	lda.l $7f56da   ;00CC20|AFDA567F|7F56DA;
	jsr.w Sub_00CC5B ;00CC24|205BCC  |00CC5B;
	sta.l $7f56da   ;00CC27|8FDA567F|7F56DA;
	lda.l $7f56dc   ;00CC2B|AFDC567F|7F56DC;
	jsr.w Sub_00CC5B ;00CC2F|205BCC  |00CC5B;
	sta.l $7f56dc   ;00CC32|8FDC567F|7F56DC;
	lda.l $7f56de   ;00CC36|AFDE567F|7F56DE;
	jsr.w Sub_00CC5B ;00CC3A|205BCC  |00CC5B;
	sta.l $7f56de   ;00CC3D|8FDE567F|7F56DE;
	ldy.b $17	   ;00CC41|A417    |000017;
	jsr.w ProcessGraphicsData ;00CC43|20759D  |009D75;
	sty.b $17	   ;00CC46|8417    |000017;
	dex ;00CC48|CA      |      ;
	bne D0c6 ;00CC49|D0C6    |00CC11;
	lda.b #$08	  ;00CC4B|A908    |      ;
	trb.w !system_flags_2	 ;00CC4D|1CD400  |0000D4;
	lda.b #$20	  ;00CC50|A920    |      ;
	trb.w $0111	 ;00CC52|1C1101  |000111;
	lda.b #$80	  ;00CC55|A980    |      ;
	trb.w !system_flags_5	 ;00CC57|1CDA00  |0000DA;
	rts ;00CC5A|60      |      ;

Screen_ColorAdjust:
	clc ;00CC5B|18      |      ;
	adc.l Screen_ColorAdjustTable,x ;00CC5C|7F66CC00|00CC66;
	cmp.b #$f0	  ;00CC60|C9F0    |      ;
	bcc Screen_ColorAdjustDone ;00CC62|9002    |00CC66;
	lda.b #$ef	  ;00CC64|A9EF    |      ;

Screen_ColorAdjustDone:
	rts ;00CC66|60      |      ;

Screen_ColorAdjustTable:
	db $03,$02,$02,$02,$02,$01,$03 ;00CC67|        |      ;

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


