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
	
	sep #$20			; A => 8bit


	stz $2115			; vram control => $00, auto increment by 1 word on write low
	ldx #$0100
	stx $2116			; destination address => $0100
	;ldx #$1808			; $18 is vram, $08 is fixed souce, write twice
	ldx #$1800			; $18 is vram, $00 is increment, write twice
	stx $4300
	ldx #$0080
	stx $4302			; source offset => $0080
	lda #$00
	sta $4304			; source bank => $00
	ldx #$0020
	stx $4305			; transfer size $20
	lda #$01
	sta $420b
	nop
	nop


	stz $2115			; vram control => $00, auto increment by 1 word on write low
	ldx #$0100
	stx $2116			; destination address => $0100
	;ldx #$1808			; $18 is vram, $08 is fixed souce, write twice
	ldx #$1800			; $18 is vram, $00 is increment, write twice
	stx $4300
	ldx #$0080
	stx $4302			; source offset => $0080
	lda #$00
	sta $4304			; source bank => $00
	ldx #$0020
	stx $4305			; transfer size $20
	lda #$01
	sta $420b
	nop
	nop


	stz $2115			; vram control => $00, auto increment by 1 word on write low
	ldx #$0100
	stx $2116			; destination address => $0100
	;ldx #$1808			; $18 is vram, $08 is fixed souce, write twice
	ldx #$1800			; $18 is vram, $00 is increment, write twice
	stx $4300
	ldx #$0080
	stx $4302			; source offset => $0080
	lda #$00
	sta $4304			; source bank => $00
	ldx #$0020
	stx $4305			; transfer size $20
	lda #$01
	sta $420b
	nop
	nop


	rts



org $0ffffe
	brk


