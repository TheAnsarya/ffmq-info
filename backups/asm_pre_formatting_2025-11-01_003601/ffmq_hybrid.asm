; Final Fantasy Mystic Quest (SNES) - Hybrid Assembly
; Combines: Historical working code + Diztinguish structure + Modern organization
; Assembler: asar 1.91
; Date: 2025-10-25
;
; Strategy: Use historical assembly as base (known to work)
;           Integrate Diztinguish labels and structure
;           Add modern extracted assets

lorom
arch 65816

;==============================================================================
; Include Files
;==============================================================================

; RAM Variables (from historical - working)
incsrc "../include/ffmq_ram_variables_historical.inc"

; Macros (from historical - working)  
incsrc "../include/ffmq_macros_original.inc"

; SNES Register Definitions (modern - fixed)
incsrc "../include/snes_registers.inc"

;==============================================================================
; Main Entry Point
;==============================================================================

org $008000
; Game entry point - everything starts here
MainEntryPoint:
	clc
	xce					; Set native mode (65816)
	jsr BasicInit		; Screen off, no interrupts, AXY => 8bit

;==============================================================================
; Core Routines (Historical - Known Working)
;==============================================================================

pushpc
org $008247

; ROUTINE: Basic init ($008247)
;		Screen off, no interrupts, AXY => 8bit
BasicInit:
	sep #$30			; Set A, X, Y to 8-bit mode
	stz $4200			; Disable interrupts and joypad
	lda #$80
	sta $2100			; Turn screen off, set brightness to $0
	rts					; Exit routine

pullpc

;==============================================================================
; Text Engine (Historical - Working)
;==============================================================================

pushpc
incsrc "text_engine_historical.asm"
pullpc

;==============================================================================
; Graphics Engine (Historical - Working)
;==============================================================================

pushpc
incsrc "graphics_engine_historical.asm"
pullpc

;==============================================================================
; Data Sections - Using Extracted Assets
;==============================================================================

; Background Tiles
pushpc
org pctosnes($028C80)
DataBackgroundTiles:
	incbin "data\graphics\tiles.bin"
pullpc

; Additional Tiles
pushpc
org pctosnes($020000)
DataTiles048000:
	incbin "data\graphics\048000-tiles.bin"
pullpc

; Title Screen Graphics
pushpc
org $07B013
DataTitleScreenWords:
	incbin "data\graphics\title-screen-words.bin"
pullpc

pushpc
org $04E220
DataTitleScreenCrystals01:
	incbin "data\graphics\title-screen-crystals-01.bin"
pullpc

pushpc
org $04E280
DataTitleScreenCrystals02:
	incbin "data\graphics\title-screen-crystals-02.bin"
pullpc

pushpc
org $04E2E0
DataTitleScreenCrystals03:
	incbin "data\graphics\title-screen-crystals-03.bin"
pullpc

;==============================================================================
; Text Data - Using Modern Extracted Assets
;==============================================================================

; Use extracted text instead of embedded
; This allows easy editing via assets/text/*.txt files

pushpc
org $0642A0  ; Weapon names location

; NOTE: For now, use original data
; Later: Generate from assets/text/weapon_names.txt
; incsrc "../data/text/weapon-names.asm"

pullpc

;==============================================================================
; Enemy Data - Using Modern Extracted Assets
;==============================================================================

pushpc
org $04F800  ; Enemy data location (approximate)

; NOTE: For now, use original data  
; Later: Generate from assets/data/enemies.asm
; incsrc "../../assets/data/enemies.asm"

pullpc

;==============================================================================
; Character Data
;==============================================================================

pushpc
incsrc "../data/character-start-stats.asm"
pullpc

;==============================================================================
; End of ROM
;==============================================================================

; Pad to correct ROM size if needed
; org $0FFFFF
; db $00
