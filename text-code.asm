
pushpc
org $009754

; ROUTINE: Text - TRB value at direct page with mask from $0097fb[] ($00:9754)
;		fetch mask from ram $97fb[]
;		clears bits on $00:directpage using mask
; parameters:
;		A => low byte: aaaaabbb
;			aaaaa - increment direct page by
;			bbb - this value is XOR'ed to flip the bits
;				invert = index to table 
;				invert * 2 = address offset
;		directpage => base of destination address
; returns:
;		ram $00:directpage => 
; notes:
;		always PHD before calling and PLD after
TRBWithMaskFromTable97fb:
	jsr IncreaseDPAndFetchFromTable97fb
	trb $00				; use A as mask to clear bits on value at $00:directpage
	rtl					; exit routine

; pc should equal $00975a

pullpc
pushpc
org $00975a

; ROUTINE: AND value at directpage with value from $0097fb[] into A ($00:975a)
;		increments direct page by top 5 bits of A
;		fetch value from rom $97fb[] AND v@ $00:D
; parameters:
;		A => low byte: aaaaabbb
;			aaaaa - increment direct page by
;			bbb - this value is XOR'ed to flip the bits
;				invert = index to table 
;				invert * 2 = address offset
; returns:
;		A => 
; notes:
;		always PHD before calling and PLD after
ANDFromTable97fbToA:
	jsr IncreaseDPAndFetchFromTable97fb
	and $00			; A => A AND value at $00:directpage
	rtl				; exit routine

; pc should equal $009760

pullpc








pushpc
org $00976b

; ROUTINE: TRB With Mask From Table $97fb[] To $0ea8[] ($00:976b)
;		fetch mask from rom $97fb[]
;		clears bits on $0ea8[] using mask
; parameters:
;		A => low byte: aaaaabbb
;			aaaaa - increment direct page by
;			bbb - this value is XOR'ed to flip the bits
;				invert = index to table 
;				invert * 2 = address offset
TRBWithMaskFromTable97fbTo0ea8:
	phd					; save directpage

	%setDirectpage($0ea8)
	jsl TRBWithMaskFromTable97fb

	pld					; restore directpage
	rtl					; exit routine

; pc should equal $009776

pullpc
pushpc

org $009776

; ROUTINE: AND value at $0ea8[] with value from $0097fb[] into A ($00:9776)
;		increments direct page by top 5 bits of A
;		fetch value from rom $97fb[] AND ram $0ea8[]
; parameters:
;		A => low byte: aaaaabbb
;			aaaaa - increment direct page by
;			bbb - this value is XOR'ed to flip the bits
;				invert = index to table 
;				invert * 2 = address offset
; returns:
;		A => 
; notes:
;		always PHD before calling and PLD after
ANDFromTable97fbAnd0ea8ToA:
	phd					; save directpage
	%setDirectpage($0ea8)
	jsl ANDFromTable97fbToA
	pld					; restore directpage
	inc
	dec
	rtl					; exit routine

; pc should equal $009783

pullpc








pushpc
org $0097da

; ROUTINE: Increase direct page, fetch from $0097fb[] ($00:97da)
;		increments direct page by top 5 bits of A
;		fetch value from rom $97fb[]
; parameters:
;		A => low byte: aaaaabbb
;			aaaaa - increment direct page by
;			bbb - this value is XOR'ed to flip the bits
;				invert = index to table 
;				invert * 2 = address offset
;		directpage => 
; returns:
;		A => value from $97fb[]
;		directpage => 
IncreaseDPAndFetchFromTable97fb:
	php					; save processor status
	%setAXYto16bit()

	and #$00ff			; ignore upper byte of A
	pha					; save A
	lsr a				;
	lsr a				; A >> 3
	lsr a				; get upper 5 bits

	; add A to direct page
	phd					; get dp
	clc
	adc $01,s			; value at stack+$01 is dp
	tcd					; set dp
	pla					; throw away temp value (old dp)

	; get index into $97fb[]
	pla					; restore A
	and #$0007			; only keep bottom 3 bits
	eor #$0007			; invert bottom 3 bits

	plp					; restore processor status
	phx					; save X

	asl a				; offset => index * 2
	tax					; copy A to X

	lda Data0097fb,x		; fetch value

	plx					; restore X
	rts					; exit routine

; pc should equal $0097fb

pullpc








pushpc
org pctosnes($0017FB)

; DATA:  ($0097fb)
Data0097fb:
	db $01,$00,$02,$00,$04,$00,$08,$00,$10,$00,$20,$00,$40,$00,$80,$00

; pc should equal $00980b


pullpc





