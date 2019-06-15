
; set A => 8bit
; example: %setAto8bit()
macro setAto8bit()
	sep #$20
endmacro

; set A => 16bit
; example: %setAto16bit()
macro setAto16bit()
	rep #$20
endmacro

; set A,X,Y => 8bit
; example: %setAXYto8bit()
macro setAXYto8bit()
	sep #$30
endmacro

; set A,X,Y => 16bit
; example: %setAXYto16bit()
macro setAXYto16bit()
	rep #$30
endmacro

; set databank (use two digit)
; example: %setDatabank(07)
macro setDatabank(bank)
	pea $00<bank>
	plb
endmacro

; set databank using A as a temp (use two digit)
; example: %setDatabankA(05)
macro setDatabankA(bank)
	lda #$<bank>
	pha
	plb
endmacro

; set directpage
; example: %setDirectpage($2100)
macro setDirectpage(address)
	pea <address>
	pld
endmacro




