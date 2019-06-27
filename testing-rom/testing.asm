lorom
arch 65816

incsrc "register.inc"
incsrc "snes-init-macro.asm"
incsrc "header.inc"


org $008000
; game entry point
MainEntryPoint:
	clc
	xce					; set native mode
	%SnesInit()

	jsr TestDMAToVRAM

forever:
	jmp forever

incsrc "snes-init.asm"


TestDMAToVRAM:

	; fill ram $00-$ff with $01 $02 $03 ... $fe $ff $00
	rep #$30			; AXY => 16bit
	lda #$0201
	ldx #$0000
	ldy #$0000

	.Loop {
		sta $0000,y

		clc
		adc #$0202
		iny
		iny
		inx
		cpx #$0080
		bne .Loop
	}
	; output:
;x	; 01 02 03 04 05 06 07 08 09 0a 0b 0c 0d 0e 0f 10
	; 11 12 13 14 15 16 17 18 19 1a 1b 1c 1d 1e 1f 20
	; 21 22 23 24 25 26 27 28 29 2a 2b 2c 2d 2e 2f 30
	; 31 32 33 34 35 36 37 38 39 3a 3b 3c 3d 3e 3f 40
	; 41 42 43 44 45 46 47 48 49 4a 4b 4c 4d 4e 4f 50
	; 51 52 53 54 55 56 57 58 59 5a 5b 5c 5d 5e 5f 60
	; 61 62 63 64 65 66 67 68 69 6a 6b 6c 6d 6e 6f 70
	; 71 72 73 74 75 76 77 78 79 7a 7b 7c 7d 7e 7f 80
	; 81 82 83 84 85 86 87 88 89 8a 8b 8c 8d 8e 8f 90
	; 91 92 93 94 95 96 97 98 99 9a 9b 9c 9d 9e 9f a0
	; a1 a2 a3 a4 a5 a6 a7 a8 a9 aa ab ac ad ae af b0
	; b1 b2 b3 b4 b5 b6 b7 b8 b9 ba bb bc bd be bf c0
	; c1 c2 c3 c4 c5 c6 c7 c8 c9 ca cb cc cd ce cf d0
	; d1 d2 d3 d4 d5 d6 d7 d8 d9 da db dc dd de df e0
	; e1 e2 e3 e4 e5 e6 e7 e8 e9 ea eb ec ed ee ef f0
	; f1 f2 f3 f4 f5 f6 f7 f8 f9 fa fb fc fd fe ff 00


	sep #$20			; A => 8bit

	; #$1804 - 4 addresses: LHLH - Does not work with vram


	lda #$00			; auto increment by 1 word on write low
	ldx #$0080			; destination => $0100
	ldy #$1800			; vram, $00 is increment, 1 address write twice: LH
	jsr DmaTestRun
	; output:
;x	; 81 00 82 00 83 00 84 00 85 00 86 00 87 00 88 00
	; 89 00 8a 00 8b 00 8c 00 8d 00 8e 00 8f 00 90 00
	; 91 00 92 00 93 00 94 00 95 00 96 00 97 00 98 00
	; 99 00 9a 00 9b 00 9c 00 9d 00 9e 00 9f 00 a0 00


	lda #$00			; auto increment by 1 word on write low
	ldx #$0100			; destination => $0200
	ldy #$1801			; vram, $01 is increment, 2 addresses: LH
	jsr DmaTestRun
	; output:
;x	; 81 00 83 82 85 84 87 86 89 88 8b 8a 8d 8c 8f 8e
	; 91 90 93 92 95 94 97 96 99 98 9b 9a 9d 9c 9f 9e
	; 00 a0 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00


	lda #$00			; auto increment by 1 word on write low
	ldx #$0180			; destination => $0300
	ldy #$1802			; vram, $02 is increment, 1 address write once
	jsr DmaTestRun
	; output:
;x	; 81 00 82 00 83 00 84 00 85 00 86 00 87 00 88 00
	; 89 00 8a 00 8b 00 8c 00 8d 00 8e 00 8f 00 90 00
	; 91 00 92 00 93 00 94 00 95 00 96 00 97 00 98 00
	; 99 00 9a 00 9b 00 9c 00 9d 00 9e 00 9f 00 a0 00


	lda #$00			; auto increment by 1 word on write low
	ldx #$0200			; destination => $0400
	ldy #$1803			; vram, $03 is increment, 2 addresses write twice: LLHH
	jsr DmaTestRun
	; output:
;x	; 81 00 82 00 85 84 86 00 89 88 8a 00 8d 8c 8e 00
	; 91 90 92 00 95 94 96 00 99 98 9a 00 9d 9c 9e 00
	; 00 a0 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00


	; #$1804 - 4 addresses: LHLH - Does not work with vram


	lda #$00			; auto increment by 1 word on write low
	ldx #$0200			; destination => $0400
	ldy #$1805			; vram, $03 is increment, 2 addresses write twice: LLHH
	jsr DmaTestRun
	; output:
;x	; 


	lda #$00			; auto increment by 1 word on write low
	ldx #$0200			; destination => $0400
	ldy #$1806			; vram, $03 is increment, 2 addresses write twice: LLHH
	jsr DmaTestRun
	; output:
;x	; 


	lda #$00			; auto increment by 1 word on write low
	ldx #$0200			; destination => $0400
	ldy #$1807			; vram, $03 is increment, 2 addresses write twice: LLHH
	jsr DmaTestRun
	; output:
;x	; 


	lda #$00			; auto increment by 1 word on write low
	ldx #$0480			; destination => $0500
	ldy #$1808			; vram, $08 is fixed, 1 address write twice: LH
	jsr DmaTestRun
	; output:
;x	; 81 00 81 00 81 00 81 00 81 00 81 00 81 00 81 00
	; 81 00 81 00 81 00 81 00 81 00 81 00 81 00 81 00
	; 81 00 81 00 81 00 81 00 81 00 81 00 81 00 81 00
	; 81 00 81 00 81 00 81 00 81 00 81 00 81 00 81 00


	lda #$00			; auto increment by 1 word on write low
	ldx #$0500			; destination => $0600
	ldy #$1809			; vram, $09 is fixed, 2 addresses: LH
	jsr DmaTestRun
	; output:
;x	; 81 00 81 81 81 81 81 81 81 81 81 81 81 81 81 81
	; 81 81 81 81 81 81 81 81 81 81 81 81 81 81 81 81
	; 00 81 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00


	lda #$00			; auto increment by 1 word on write low
	ldx #$0580			; destination => $0700
	ldy #$180a			; vram, $0a is fixed, 1 address write once
	jsr DmaTestRun
	; output:
;x	; 81 00 81 00 81 00 81 00 81 00 81 00 81 00 81 00
	; 81 00 81 00 81 00 81 00 81 00 81 00 81 00 81 00
	; 81 00 81 00 81 00 81 00 81 00 81 00 81 00 81 00
	; 81 00 81 00 81 00 81 00 81 00 81 00 81 00 81 00


	lda #$00			; auto increment by 1 word on write low
	ldx #$0600			; destination => $0800
	ldy #$180b			; vram, $0b is fixed, 2 addresses write twice: LLHH
	jsr DmaTestRun
	; output:
;x	; 81 00 81 00 81 81 81 00 81 81 81 00 81 81 81 00
	; 81 81 81 00 81 81 81 00 81 81 81 00 81 81 81 00
	; 00 81 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00


;-----------------------------------------------------


	lda #$80			; auto increment by 1 word on write high
	ldx #$0280			; destination => $0900
	ldy #$1800			; vram, $00 is increment, 1 address write twice: LH
	jsr DmaTestRun
	; output:
;x	; a0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00


	lda #$80			; auto increment by 1 word on write high
	ldx #$0300			; destination => $0a00
	ldy #$1801			; vram, $01 is increment, 2 addresses: LH
	jsr DmaTestRun
	; output:
;x	; 81 82 83 84 85 86 87 88 89 8a 8b 8c 8d 8e 8f 90
	; 91 92 93 94 95 96 97 98 99 9a 9b 9c 9d 9e 9f a0
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00


	lda #$80			; auto increment by 1 word on write high
	ldx #$0380			; destination => $0b00
	ldy #$1802			; vram, $02 is increment, 1 address write once
	jsr DmaTestRun
	; output:
;x	; a0 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00


	lda #$80			; auto increment by 1 word on write high
	ldx #$0400			; destination => $0c00
	ldy #$1803			; vram, $03 is increment, 2 addresses write twice: LLHH
	jsr DmaTestRun
	; output:
;x	; 82 83 00 84 86 87 00 88 8a 8b 00 8c 8e 8f 00 90
	; 92 93 00 94 96 97 00 98 9a 9b 00 9c 9e 9f 00 a0
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00


	lda #$80			; auto increment by 1 word on write high
	ldx #$0680			; destination => $0d00
	ldy #$1808			; vram, $08 is fixed, 1 address write twice: LH
	jsr DmaTestRun
	; output:
;x	; 81 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00


	lda #$80			; auto increment by 1 word on write high
	ldx #$0700			; destination => $0e00
	ldy #$1809			; vram, $09 is fixed, 2 addresses: LH
	jsr DmaTestRun
	; output:
;x	; 81 81 81 81 81 81 81 81 81 81 81 81 81 81 81 81
	; 81 81 81 81 81 81 81 81 81 81 81 81 81 81 81 81
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00


	lda #$80			; auto increment by 1 word on write high
	ldx #$0780			; destination => $0f00
	ldy #$180a			; vram, $0a is fixed, 1 address write once
	jsr DmaTestRun
	; output:
;x	; 81 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00


	lda #$80			; auto increment by 1 word on write high
	ldx #$0800			; destination => $1000
	ldy #$180b			; vram, $0b is fixed, 2 addresses write twice: LLHH
	jsr DmaTestRun
	; output:
;x	; 81 81 00 81 81 81 00 81 81 81 00 81 81 81 00 81
	; 81 81 00 81 81 81 00 81 81 81 00 81 81 81 00 81
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	; 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00


	;ldy #$1808			; $18 is vram, $08 is fixed souce, write twice

	rts



DmaTestRun:
	sta $2115			; vram control => A
	stx $2116			; destination address => X
	sty $4300			; dma control and destination => Y
	ldx #$0080
	stx $4302			; source offset => $0080
	lda #$00
	sta $4304			; source bank => $00
	ldx #$0020
	stx $4305			; transfer size $20
	lda #$01
	sta $420b			; start dma transfer on channel 0
	nop
	nop
	rts					; exit routine



org $0ffffe
	brk


