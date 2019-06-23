




;-------------------------------------------------------------------------
pushpc
org $009754


; ROUTINE: Text - TRB value at direct page with mask from DataBitMask[] ($009754)
;		fetch mask from ram DataBitMask[]
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
TRBWithBitMask:
	jsr IncreaseDPAndFetchBitMask
	trb $00				; use A as mask to clear bits on value at $00:directpage
	rtl					; exit routine


; pc should equal $00975a
pullpc;-------------------------------------------------------------------------

pushpc
org $00975a


; ROUTINE: AND value at directpage with value from DataBitMask[] into A ($00975a)
;		increments direct page by top 5 bits of A
;		fetch value from rom DataBitMask[] AND v@ $00:D
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
ANDBitMaskToA:
	jsr IncreaseDPAndFetchBitMask
	and $00			; A => A AND value at $00:directpage
	rtl				; exit routine


; pc should equal $009760
pullpc;-------------------------------------------------------------------------








;-------------------------------------------------------------------------
pushpc
org $00976b


; ROUTINE: TRB With Mask From Table DataBitMask[] To $0ea8[] ($00976b)
;		fetch mask from rom DataBitMask[]
;		clears bits on $0ea8[] using mask
; parameters:
;		A => low byte: aaaaabbb
;			aaaaa - increment direct page by
;			bbb - this value is XOR'ed to flip the bits
;				invert = index to table 
;				invert * 2 = address offset
TRBWithBitMaskTo0ea8:
	phd					; save directpage

	%setDirectpage($0ea8)
	jsl TRBWithBitMask

	pld					; restore directpage
	rtl					; exit routine


; pc should equal $009776
pullpc
;-------------------------------------------------------------------------
pushpc
org $009776


; ROUTINE: AND value at $0ea8[] with value from DataBitMask[] into A ($009776)
;		increments direct page by top 5 bits of A
;		fetch value from rom DataBitMask[] AND ram $0ea8[]
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
ANDBitMaskAnd0ea8ToA:
	phd					; save directpage
	%setDirectpage($0ea8)
	jsl ANDBitMaskToA
	pld					; restore directpage
	inc
	dec
	rtl					; exit routine


; pc should equal $009783
pullpc
;-------------------------------------------------------------------------








;-------------------------------------------------------------------------
pushpc
org $0097da


; ROUTINE: Increase direct page, fetch from DataBitMask[] ($0097da)
;		increments direct page by top 5 bits of A
;		fetch value from rom DataBitMask[]
; parameters:
;		A => low byte: aaaaabbb
;			aaaaa - increment direct page by
;			bbb - this value is XOR'ed to flip the bits
;				invert = index to table 
;				invert * 2 = address offset
;		directpage => 
; returns:
;		A => value from DataBitMask[]
;		directpage => 
IncreaseDPAndFetchBitMask:
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

	; get index into DataBitMask[]
	pla					; restore A
	and #$0007			; only keep bottom 3 bits
	eor #$0007			; invert bottom 3 bits

	plp					; restore processor status
	phx					; save X

	asl a				; offset => index * 2
	tax					; copy A to X

	lda.l DataBitMask,x

	plx					; restore X
	rts					; exit routine


; pc should equal $0097fb
pullpc
;-------------------------------------------------------------------------
pushpc
org $0097fb		;pctosnes ($0017fb)


; DATA:  ($0097fb)
DataBitMask:
	db $01,$00,$02,$00,$04,$00,$08,$00,$10,$00,$20,$00,$40,$00,$80,$00


; pc should equal $00980b
pullpc
;-------------------------------------------------------------------------





