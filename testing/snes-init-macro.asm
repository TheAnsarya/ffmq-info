; Source: http://en.wikibooks.org/wiki/Super_NES_Programming

macro SnesInit()
	sei					; Disabled interrupts
	clc					; clear carry to switch to native mode
	xce					; Xchange carry & emulation bit. native mode
	rep #$18			; Binary mode (decimal mode off), X/Y 16 bit
	ldx #$1FFF			; set stack to $1FFF
	txs

	jsr Init
endmacro
