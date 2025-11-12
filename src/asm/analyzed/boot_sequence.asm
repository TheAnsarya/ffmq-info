; ============================================================================
; FFMQ Boot Sequence Analysis
; ============================================================================
; Analyzed from Diztinguish disassembly bank_00.asm
; Original addresses: $008000-$0080ff
;
; This file contains the enhanced analysis of the game's boot sequence
; with meaningful labels, detailed comments, and cross-references.
; ============================================================================

; Entry point after SNES reset vector
; This is the first code executed when the game starts
BootEntry:	; Original: Label_008000
	clc                             ; Clear carry flag
	xce                             ; Switch to native 65816 mode (not emulation)
	jsr.W InitializeHardware        ; Initialize SNES hardware registers
	jsl.L InitializeGameState       ; Initialize game state ($0d8000)

; Initialize boot flags
	lda.B #$00
	sta.L $7e3667                   ; Boot flag 1 = 0
	dec a; A = $ff
	sta.L $7e3668                   ; Boot flag 2 = $ff
	bra ContinueBootSequence

; Alternative entry point (NMI/Reset handler?)
AlternateEntry:	; Original: Label_008016
	jsr.W InitializeHardware
	lda.B #$f0
	sta.L $000600                   ; Set interrupt vector?
	jsl.L InitializeInterrupts      ; Setup interrupts ($0d8004)

ContinueBootSequence:	; Original: Label_008023
	rep #$30                        ; Set A and X/Y to 16-bit mode
	ldx.W #$1fff                    ; Stack pointer = $1fff (top of RAM)
	txs                             ; Transfer X to Stack pointer
	jsr.W ClearMemory               ; Clear work RAM

; Check for specific hardware flag
	lda.W #$0040                    ; Bit 6 flag
	and.W $00da                     ; Check flag in zero page
	bne SkipDMAFill                 ; If set, skip DMA fill

; Perform DMA fill operation
	jsl.L MenuSystemInit            ; Initialize menu system ($0c8080)
	bra SetupComplete

; Third entry point for warm boot
WarmBootEntry:	; Original: Label_00803A
	jsr.W InitializeHardware
	lda.B #$f0
	sta.L $000600                   ; Interrupt vector
	jsl.L InitializeInterrupts      ; Setup interrupts
	rep #$30                        ; 16-bit mode
	ldx.W #$1fff                    ; Reset stack
	txs

SetupComplete:	; Original: Label_00804D
	jsr.W ClearMemory               ; Clear RAM again
	sep #$20                        ; 8-bit accumulator

; Setup DMA to clear screen
	ldx.W #$1809                    ; DMA parameters: A->B, auto-increment
	stx.W SNES_DMA0PARAM            ; DMA channel 0 control
	ldx.W #$8252                    ; Source address low/mid
	stx.W SNES_DMA0ADDRL            ; DMA source address
	lda.B #$00                      ; Source bank
	sta.W SNES_DMA0ADDRH            ; DMA source bank
	ldx.W #$0000                    ; Transfer size = 64KB
	stx.W SNES_DMA0CNTL             ; DMA transfer size
	lda.B #$01                      ; Enable channel 0
	sta.W SNES_MDMAEN               ; Start DMA transfer

SkipDMAFill:	; Original: Label_00806E
	jsl.L $00011f                   ; Call unknown routine (BIOS?)
	rep #$30                        ; 16-bit mode
	lda.W #$0000
	tcd                             ; Set direct page to $0000
	sep #$20                        ; 8-bit accumulator

; Enable interrupts
	lda.W $0112                     ; Load saved interrupt flags
	sta.W SNES_NMITIMEN             ; Enable NMI/IRQ
	cli                             ; Clear interrupt disable flag

; Initialize game brightness
	lda.B #$0f                      ; Full brightness
	sta.W $00aa                     ; Store brightness value

; Main initialization sequence
	jsl.L WaitForVBlank             ; Wait for vertical blank ($0c8000)
	jsl.L WaitForVBlank             ; Wait again for safety

; Check save data
	lda.L $7e3665                   ; Check save data flag
	bne LoadSaveData                ; If save exists, load it

; Check for continue data
	lda.L $700000                   ; SRAM slot 1
	ora.L $70038c                   ; SRAM slot 2
	ora.L $700718                   ; SRAM slot 3
	beq StartNewGame                ; If all empty, new game

; Continue from save
	jsl.L ContinueGame              ; Load continue data ($00b950)
	bra EnterMainLoop

LoadSaveData:	; Original: Label_0080A8
	jsr.W LoadSaveGameData
	bra MainGameLoop

StartNewGame:	; Original: Label_0080AD
	jsr.W InitializeNewGame

EnterMainLoop:	; Original: Load_0080B0
; Clear various flags
	lda.B #$80
	trb.W $00de                     ; Clear bit 7 of flags
	lda.B #$e0
	trb.W $0111                     ; Clear bits 5-7

	jsl.L WaitForVBlank

; Setup color math
	lda.B #$e0                      ; Color math: all layers
	sta.W SNES_COLDATA              ; Set color data
	ldx.W #$0000
	stx.W SNES_CGSWSEL              ; Clear color window

; Reset scroll positions
	stz.W SNES_BG1VOFS              ; BG1 vertical scroll = 0
	stz.W SNES_BG1VOFS              ; Write twice for 16-bit

MainGameLoop:	; Original: OriginalCode
; Main game loop continues...
; [Additional code would be analyzed here]

; ============================================================================
; Subroutines
; ============================================================================

InitializeHardware:	; Original: AddressOriginalCode
; Initialize all SNES hardware registers
; [Implementation at $008247 in bank_00.asm]
	rts

ClearMemory:	; Original: ClearRamAgainRedundant
; Clear work RAM ($7e0000-$7fffff)
; [Implementation at $0081f0 in bank_00.asm]
	rts

LoadSaveGameData:	; Original: CallRoutine
; Load save game from SRAM
; [Implementation at $008166 in bank_00.asm]
	rts

InitializeNewGame:	; Original: NewGameInitialization
; Initialize new game state
; [Implementation at $008117 in bank_00.asm]
	rts

; ============================================================================
; External Routines Referenced
; ============================================================================
; $0d8000 - InitializeGameState - Initialize main game state variables
; $0d8004 - InitializeInterrupts - Setup NMI/IRQ handlers
; $0c8080 - MenuSystemInit - Initialize menu system
; $0c8000 - WaitForVBlank - Wait for vertical blank
; $00b950 - ContinueGame - Load continue data
; ============================================================================

; ============================================================================
; RAM Variables Referenced
; ============================================================================
; $7e3665 - Save data present flag
; $7e3667 - Boot flag 1
; $7e3668 - Boot flag 2
; $000600 - Interrupt vector storage
; $0112   - Saved interrupt enable flags
; $00aa   - Screen brightness value
; $00da   - Hardware configuration flags
; $00de   - General flags byte 1
; $0111   - General flags byte 2
;
; SRAM Locations:
; $700000 - Save slot 1 data
; $70038c - Save slot 2 data
; $700718 - Save slot 3 data
; ============================================================================
