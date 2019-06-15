lorom
arch 65816


; TODO: why is $aa $f4 $55 $0b being written to $7fdc?




; Macros!
incsrc "macros.asm"


org $008000
; game entry point (everything starts here)
MainEntryPoint:
	clc
	xce					; set native mode
	jsr BasicInit		; screen off, no interupts, AXY => 8bit








pushpc
org $008247

; ROUTINE: Basic init ($00:8247)
;		Screen off, no interupts, AXY => 8bit
; TODO: maybe relabel?
BasicInit:
	%setAXYto8bit()
	stz $4200			; disable interupts and joypad
	lda #$80
	sta $2100			; turn screen off, set brightness to $0
	rts					; exit routine

; pc should equal $008252

pullpc





; text code

pushpc

incsrc "text-code.asm"

pullpc




; graphics code, like load town tiles and colors

pushpc

incsrc "load-graphics-routines.asm"

pullpc



pushpc
org pctosnes($028C80)

; DATA: Background tiles ($058C80)
DataTiles:
	incbin "data\graphics\tiles.dat"

; pc should equal $05F280

pullpc





; data files at ($063ed0)

pushpc
pushtable
table "simple.tbl",rtl

org pctosnes($063ed0)

incsrc "short-text.asm"
incsrc "data/character-start-stats.asm"

pulltable
pullpc




