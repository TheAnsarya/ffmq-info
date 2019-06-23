lorom
arch 65816


; TODO: why is $aa $f4 $55 $0b being written to $7fdc?


;Define Variables
incsrc "ram-variables.asm"

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

incsrc "load-graphics-routines - onlygood.asm"

pullpc



pushpc
org pctosnes($028C80)

; DATA: Background tiles ($058C80)
DataTiles:
	incbin "data\graphics\tiles.dat"

; pc should equal $05F280

pullpc


pushpc
org pctosnes($020000)

; DATA: tiles ($048000)
DataTiles048000:
	incbin "data\graphics\048000-tiles.bin"

; pc should equal $05F280

pullpc



pushpc
org $07B013		; pctosnes($03b013)

; DATA:  ($07B013)
; Data07af3b has 16 bit offset pointers to this data
; TODO: what is all this
; TODO: is size correct?
Data07b013:
	incbin "data\graphics\data07b013.bin"

; pc should equal $07DBFC

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




