; FFMQ Minimal Working Build - Proof of Concept
; Goal: Get FIRST successful build to establish baseline
; Strategy: Minimal changes, verify toolchain works

lorom
arch 65816

;==============================================================================
; Minimal Patch - Just prove we can build
;==============================================================================

org $008000
; Game entry point
MainEntryPoint:
	clc
	xce					; Set native mode
	sep #$30			; A/X/Y = 8-bit
	stz $4200			; Disable interrupts
	lda #$80
	sta $2100			; Screen off
	; Jump to original code
	jml $008010

;==============================================================================
; That's it! Minimal patch to verify toolchain
;==============================================================================

; The rest of the ROM remains unchanged
; This proves:
; 1. asar works
; 2. We can patch the ROM
; 3. Build system functions
; 4. We can compare results

; Next step: Gradually add more code sections
