lorom
arch 65816


org $008000
; game entry point (everything starts here)
MainEntryPoint:
	clc
	xce				; set native mode
	jsr $8247		; call routine "Screen off, no interupts, AXY => 8bit ($00:8247)"








; data files at ($063ed0)

pushpc
pushtable
table "simple.tbl",rtl

org pctosnes($063ed0)

incsrc "short-text.asm"
incsrc "data/character-start-stats.asm"

pulltable
pullpc




