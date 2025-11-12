; ==============================================================================
; Final Fantasy Mystic Quest (SNES) - Complete Disassembly
; ==============================================================================
;
; THIS IS A REAL REBUILD - NOT A PATCHED ROM!
;
; Build Strategy:
; - Start from NOTHING (no ROM copying!)
; - Build entire ROM from disassembled code
; - Fill all graphics/data from extracted assets
; - Result: 100% assembled from source
;
; Current Status:
; - Code: Being disassembled and commented
; - Graphics: Extracted, needs incbin integration
; - Palettes: Extracted, needs data integration
; - Text: Extracted, needs assembly data structures
; - Maps: Not yet extracted
; - Audio: Not yet extracted
;
; Real Progress: ~5% (honest assessment)
; - We have the code skeleton from Diztinguish
; - Graphics/palettes extracted but not integrated into build
; - Text extracted but not integrated
; - Most code is uncommented raw disassembly
;
; ==============================================================================

	arch 65816
	lorom

;===============================================================================
; SNES Header (Required for valid ROM)
;===============================================================================

	org $00ffc0
	db "FFMQ DISASSEMBLY    "  ; ROM name (21 bytes)

	org $00ffd5
	db $20          ; Map mode ($20 = LoROM)

	org $00ffd6
	db $00          ; Cartridge type (ROM only)

	org $00ffd7
	db $09          ; ROM size (512KB = 2^9)

	org $00ffd8
	db $00          ; RAM size (none)

	org $00ffd9
	db $01          ; Country code (USA)

	org $00ffda
	db $33          ; Publisher code

	org $00ffdb
	db $00          ; Version number

	org $00ffdc
	dw $0000        ; Checksum complement (calculated by asar)

	org $00ffde
	dw $0000        ; Checksum (calculated by asar)

;===============================================================================
; Interrupt Vectors (Native Mode)
;===============================================================================

	org $00ffe4
	dw $0000        ; COP vector
	dw $0000        ; BRK vector
	dw $0000        ; ABORT vector
	dw Label_008000  ; NMI vector
	dw $0000        ; RESET (unused in native mode)
	dw $0000        ; IRQ vector

;===============================================================================
; Interrupt Vectors (Emulation Mode)
;===============================================================================

	org $00fff4
	dw $0000        ; COP vector
	dw $0000        ; Reserved
	dw $0000        ; ABORT vector
	dw Label_008000  ; NMI vector
	dw Label_008000  ; RESET vector (boot entry point!)
	dw $0000        ; IRQ/BRK vector

;===============================================================================
; SNES Register Definitions
;===============================================================================

	incsrc "../include/snes_registers.inc"

;===============================================================================
; RAM Variable Definitions
;===============================================================================

; TODO: Include RAM map once converted from Diztinguish labels
; incsrc "../include/ram_variables.inc"

;===============================================================================
; Bank $00 - Main Game Engine
;===============================================================================

	org $008000

Label_008000:
; ===========================================================================
; Boot Sequence - SNES Initialization
; ===========================================================================
; This is the entry point when the SNES powers on or resets.
; First instruction executed after the RESET vector is triggered.
;
; Purpose:
;   - Switch from 6502 emulation mode to native 65816 mode
;   - Initialize hardware registers
;   - Set up memory banks and stack
;   - Start game initialization
;
; Technical Details:
;   CLC + XCE = Clear carry, then exchange carry with emulation flag
;   This switches the CPU from 6502 emulation (power-on default)
;   to native 65816 mode, enabling 16-bit registers and extended addressing
;
; Register State After:
;   - CPU in native mode (65816)
;   - All registers uninitialized (will be set up by called routines)
;   - Stack pointer uninitialized (will be set to $1fff)
; ===========================================================================

	clc                     ; Clear carry flag
	xce                     ; Exchange carry with emulation flag
; → CPU now in native 65816 mode

	jsr.W InitializeHardwareRegisters       ; Initialize hardware registers
	jsl.L Primary_APU_Upload_Entry_Point       ; Initialize subsystem (Bank $0d)

; ===========================================================================
; Initialize Save Game State
; ===========================================================================
; Sets up flags that indicate whether a save file exists and its state
; ===========================================================================

	lda.B #$00              ; A = 0
	sta.L $7e3667           ; Clear save file state flag 1
	dec a; A = $ff (-1)
	sta.L $7e3668           ; Set save file state flag 2 to $ff
	bra Label_008023         ; Skip to main initialization

Label_008016:
; ===========================================================================
; Secondary Boot Path (called from somewhere else)
; ===========================================================================

	jsr.W InitializeHardwareRegisters       ; Initialize hardware registers
	lda.B #$f0              ; A = $f0
	sta.L $000600           ; Store to low RAM (hardware mirror area)
	jsl.L Secondary_APU_Command_Entry_Point       ; Initialize subsystem variant

Label_008023:
; ===========================================================================
; Stack and Memory Setup
; ===========================================================================
; Sets up the stack pointer and prepares the system for game execution
; ===========================================================================

	rep #$30                ; Set A and X/Y to 16-bit mode
	ldx.W #$1fff            ; X = $1fff
	txs                     ; Set stack pointer to $1fff (top of RAM bank $00)

	jsr.W InitializeMoreHardwareDetailsTbd       ; Initialize more hardware (details TBD)

; ===========================================================================
; Check Controller State
; ===========================================================================
; Checks if specific button combination is held (diagnostic mode?)
; ===========================================================================

	lda.W #$0040            ; A = $0040 (bit 6 = some button?)
	and.W $00da             ; Mask with controller input at $00da
	bne Label_00806E         ; If button pressed, skip to alternate path

	jsl.L CodeScreenInitialization       ; Call routine in bank $0c
	bra Label_00804D         ; Continue to main setup

Label_00803A:
; ===========================================================================
; Another Entry Point (possibly soft reset?)
; ===========================================================================

	jsr.W InitializeHardwareRegisters       ; Initialize hardware registers
	lda.B #$f0              ; A = $f0
	sta.L $000600           ; Store to hardware mirror
	jsl.L Secondary_APU_Command_Entry_Point       ; Initialize subsystem

	rep #$30                ; 16-bit A, X, Y
	ldx.W #$1fff            ; Reset stack pointer
	txs

Label_00804D:
; ===========================================================================
; DMA Setup for Initial Data Transfer
; ===========================================================================
; Uses DMA channel 0 to transfer data to hardware registers
; This is a fast way to initialize multiple registers at once
; ===========================================================================

	jsr.W InitializeMoreHardwareDetailsTbd       ; Hardware init

	sep #$20                ; 8-bit A, 16-bit X/Y

; Configure DMA Channel 0
	ldx.W #$1809            ; DMA parameters
	stx.W SNES_DMA0PARAM    ; $4300: DMA control + target register

	ldx.W #$8252            ; Source address (low/mid bytes)
	stx.W SNES_DMA0ADDRL    ; $4302-4303: Source address low/mid

	lda.B #$00              ; Source bank = $00
	sta.W SNES_DMA0ADDRH    ; $4304: Source address bank

	ldx.W #$0000            ; Transfer size = $0000 (means $10000 = 64KB!)
	stx.W SNES_DMA0CNTL     ; $4305-4306: Transfer size

	lda.B #$01              ; Enable DMA channel 0
	sta.W SNES_MDMAEN       ; $420b: DMA enable register

Label_00806E:
; ===========================================================================
; Main Game Initialization Continues
; ===========================================================================

	jsl.L $00011f           ; Call routine (bank $00, address $011f)

	rep #$30                ; 16-bit A, X, Y
	lda.W #$0000            ; A = 0
	tcd                     ; Set direct page to $0000

	sep #$20                ; 8-bit A

; Enable interrupts (NMI/IRQ)
	lda.W $0112             ; Load interrupt enable flags
	sta.W SNES_NMITIMEN     ; $4200: Enable NMI/IRQ
	cli                     ; Clear interrupt disable flag

; Set screen brightness
	lda.B #$0f              ; Full brightness
	sta.W $00aa             ; Store to game variable

; Call initialization routine twice (why?)
	jsl.L CWaitTimingRoutine       ; Bank $0c initialization
	jsl.L CWaitTimingRoutine       ; Called again (loading screens? fade?)

; Check save file state
	lda.L $7e3665           ; Load save state flag
	bne Label_0080A8         ; If not zero, handle differently

; Check if save data exists in SRAM
	lda.L $700000           ; SRAM byte 1
	ora.L $70038c           ; OR with SRAM byte 2
	ora.L $700718           ; OR with SRAM byte 3
	beq Label_0080AD         ; If all zero, no save exists

; Save data exists - load it
	jsl.L LoadSaveGame       ; Load save game
	bra Load_0080B0         ; Continue

Label_0080A8:
; Handle different save state
	jsr.W CallRoutine       ; Call routine
	bra SkipDifferentPath         ; Skip to different path

Label_0080AD:
; No save data - start new game
	jsr.W NewGameInitialization       ; New game initialization

Load_0080B0:
; ===========================================================================
; Graphics Setup - Screen Initialization
; ===========================================================================

	lda.B #$80              ; Bit 7
	trb.W $00de             ; Test and reset bit in game flag

	lda.B #$e0              ; Bits 5-7
	trb.W $0111             ; Test and reset bits

	jsl.L CWaitTimingRoutine       ; Call init routine

; Set color math to subtract mode
	lda.B #$e0              ; Color math control
	sta.W SNES_COLDATA      ; $2132: Color math settings

; Reset windowing and color effects
	ldx.W #$0000
	stx.W SNES_CGSWSEL      ; $2130: Window mask + color math enable

; Reset BG1 vertical scroll
	stz.W SNES_BG1VOFS      ; $210e: BG1 V-scroll low byte
	stz.W SNES_BG1VOFS      ; $210e: BG1 V-scroll high byte

; ===========================================================================
; TODO: Continue disassembling and commenting the rest of bank_00.asm
; ===========================================================================
; This is where the REAL work begins:
; - Analyze each routine's purpose
; - Document inputs, outputs, side effects
; - Give meaningful labels to CODE_XXXXXX
; - Integrate extracted data (graphics, text, etc.)
; ===========================================================================

; For now, include the rest of the uncommented disassembly
; This will be progressively replaced with documented code

; Placeholder: Include remaining bank_00 code
; (In real implementation, we'd convert and comment all 14,018 lines)

