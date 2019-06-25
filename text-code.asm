




;--------------------------------------------------------------------
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
pullpc;--------------------------------------------------------------------

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
pullpc;--------------------------------------------------------------------








;--------------------------------------------------------------------
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
;--------------------------------------------------------------------
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
;--------------------------------------------------------------------








;--------------------------------------------------------------------
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
;--------------------------------------------------------------------
pushpc
org $0097fb		;pctosnes ($0017fb)


; DATA:  ($0097fb)
DataBitMask:
	db $01,$00,$02,$00,$04,$00,$08,$00,$10,$00,$20,$00,$40,$00,$80,$00


; pc should equal $00980b
pullpc
;--------------------------------------------------------------------








;--------------------------------------------------------------------
pushpc
org $009891


; ROUTINE: Copy by words ($009891)
;		copies up to $20 words ($40 bytes)
; parameters:
;		X => source offset
;		Y => destination offset
CopyByWords:
	.x20
		lda $003e,x
		sta $003e,y
		lda $003c,x
		sta $003c,y
		lda $003a,x
		sta $003a,y
		lda $0038,x
		sta $0038,y
		lda $0036,x
		sta $0036,y
		lda $0034,x
		sta $0034,y
		lda $0032,x
		sta $0032,y
		lda $0030,x
		sta $0030,y
		lda $002e,x
		sta $002e,y
		lda $002c,x
		sta $002c,y
		lda $002a,x
		sta $002a,y
		lda $0028,x
		sta $0028,y
		lda $0026,x
		sta $0026,y
		lda $0024,x
		sta $0024,y
		lda $0022,x
		sta $0022,y
		lda $0020,x
		sta $0020,y
	.x10
		lda $001e,x
		sta $001e,y
		lda $001c,x
		sta $001c,y
		lda $001a,x
		sta $001a,y
		lda $0018,x
		sta $0018,y
		lda $0016,x
		sta $0016,y
		lda $0014,x
		sta $0014,y
		lda $0012,x
		sta $0012,y
		lda $0010,x
		sta $0010,y
		lda $000e,x
		sta $000e,y
		lda $000c,x
		sta $000c,y
		lda $000a,x
		sta $000a,y
		lda $0008,x
		sta $0008,y
		lda $0006,x
		sta $0006,y
		lda $0004,x
		sta $0004,y
		lda $0002,x
		sta $0002,y
		lda $0000,x
		sta $0000,y

	rts					; exit routine


; pc should equal $009952
pullpc
;--------------------------------------------------------------------













;--------------------------------------------------------------------
pushpc
org $009994


; ROUTINE: FillSectionWithA_LongJump ($009994)
;		entry point for long jumps to FillSectionWithA
; parameters:
;		see FillSectionWithA
; AXY => 16bit
FillSectionWithA_LongJump:
	jsr FillSectionWithA
	rtl					; exit routine


; pc should equal $009998
pullpc
;--------------------------------------------------------------------
pushpc
org $009998


; ROUTINE: FillSectionWithA ($009998)
;		fills a section of memory with A
; parameters:
;		A => not exactly the number of words to fill with A
;			upper $A bits => fill size, number of $20 word chunks to fill
;			lower $6 bits => offset into JumpTableFillWithA[]
;				this is the remainder except $04 only fills $03 and $12 only fills $11
;		X => fill value
;		Y => fill destination
; AXY => 16bit
FillSectionWithA:
	phx					; save fill value
	cmp #$0040			; skip when A < $0040 (fill size = $0000)
	bcc .Skip

	pha					; save A
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	lsr a
	tax					; loop counter => A / $40 (throw away lower 6 bts)
	clc

	.Loop {
		lda $03,s			; A => fill value from stack
		jsr FillWithA_x20

		tya
		adc #$0040
		tay					; destination += $40
		dex					; decrement counter
		bne .Loop
	}

	pla					; restore A
	and #$003f			; lower 6 bits

	.Skip

	tax					; jump table offset => A
	pla					; A => fill value
	jmp (JumpTableFillWithA,x)


; pc should equal $009a1e
pullpc
;--------------------------------------------------------------------
pushpc
org $0099bd


; ROUTINE: Fill with A ($0099bd)
;		fills $20 or $40 bytes with A starting at Y
;		if 16bit, $20 words
;		if 8bit, $20 bytes
; parameters:
;		A => fill value
;		Y => destination
; A can be 8bit or 16bit
FillWithA:
	.x20					; $99bd
		sta $003e,y
	.x1f					; $99c0
		sta $003c,y
	.x1e					; $99c3
		sta $003a,y
	.x1d					; $99c6
		sta $0038,y
	.x1c					; $99c9
		sta $0036,y
	.x1b					; $99cc
		sta $0034,y
	.x1a					; $99cf
		sta $0032,y
	.x19					; $99d2
		sta $0030,y
	.x18					; $99d5
		sta $002e,y
	.x17					; $99d8
		sta $002c,y
	.x16					; $99db
		sta $002a,y
	.x15					; $99de
		sta $0028,y
	.x14					; $99e1
		sta $0026,y
	.x13					; $99e4
		sta $0024,y
		sta $0022,y
	.x11					; $99ea
		sta $0020,y
	.x10					; $99ed
		sta $001e,y
	.x0f					; $99f0
		sta $001c,y
	.x0e					; $99f3
		sta $001a,y
	.x0d					; $99f6
		sta $0018,y
	.x0c					; $99f9
		sta $0016,y
	.x0b					; $99fc
		sta $0014,y
	.x0a					; $99ff
		sta $0012,y
	.x09					; $9a02
		sta $0010,y
	.x08					; $9a05
		sta $000e,y
	.x07					; $9a08
		sta $000c,y
	.x06					; $9a0b
		sta $000a,y
	.x05					; $9a0e
		sta $0008,y
		sta $0006,y
	.x03					; $9a14
		sta $0004,y
	.x02					; $9a17
		sta $0002,y
	.x01					; $9a1a
		sta $0000,y
	.Nothing					; $9a1d
		rts					; exit routine


; pc should equal $009a1e
pullpc
;--------------------------------------------------------------------
pushpc
org $009a1e


; JUMP: Entry points into the FillWithA routine ($009a1e)
;		$009a1e-$009a5f (in file = $001a1e-$001a5f)
JumpTableFillWithA:
	dw FillWithA_Nothing		; $9A1D
	dw FillWithA_x01			; $9A1A
	dw FillWithA_x02			; $9A17
	dw FillWithA_x03			; $9A14
	dw FillWithA_x03			; $9A14		there is no x04
	dw FillWithA_x05			; $9A0E
	dw FillWithA_x06			; $9A0B
	dw FillWithA_x07			; $9A08
	dw FillWithA_x08			; $9A05
	dw FillWithA_x09			; $9A02
	dw FillWithA_x0a			; $99FF
	dw FillWithA_x0b			; $99FC
	dw FillWithA_x0c			; $99F9
	dw FillWithA_x0d			; $99F6
	dw FillWithA_x0e			; $99F3
	dw FillWithA_x0f			; $99F0
	dw FillWithA_x10			; $99ED
	dw FillWithA_x11			; $99EA
	dw FillWithA_x11			; $99EA		there is no x12
	dw FillWithA_x13			; $99E4
	dw FillWithA_x14			; $99E1
	dw FillWithA_x15			; $99DE
	dw FillWithA_x16			; $99DB
	dw FillWithA_x17			; $99D8
	dw FillWithA_x18			; $99D5
	dw FillWithA_x19			; $99D2
	dw FillWithA_x1a			; $99CF
	dw FillWithA_x1b			; $99CC
	dw FillWithA_x1c			; $99C9
	dw FillWithA_x1d			; $99C6
	dw FillWithA_x1e			; $99C3
	dw FillWithA_x1f			; $99C0
	dw FillWithA_x20			; $99bd


; pc should equal $009a60
pullpc
;--------------------------------------------------------------------

















;--------------------------------------------------------------------
;						BANK $0c
;--------------------------------------------------------------------


;--------------------------------------------------------------------
pushpc
org $0c8000

; ROUTINE: Idle until interrupt $d8 ($)
;		loops until bit 6 of !flags_d8 is set by an interrupt
IdleUntilInterruptD8
	php					; save processor status
	%setAto8bit()
	pha					; save A
	lda #$40
	trb !flags_d8			; clear bit 6 of !flags_d8
	.Loop {
		lda #$40
		and !flags_d8			; loop until bit 6 of !flags_d8 is set
		beq .Loop
	}

	pla					; restore A
	plp					; restore processor status
	rtl					; exit routine


; pc should equal $0c8013
pullpc
;--------------------------------------------------------------------







;--------------------------------------------------------------------
pushpc
org $0c9247


; ROUTINE: Reverse word arrays ($0c9247)
;		for bytes $7f0000-$7f0eb9 (size = $3c0)
;		reverses the contents of $3c arrays of $8 words ($10 bytes) each
;		each array stays in place, the words inside reverse order
; AXY => 16bit
ReverseWordArrays:
	pea $7f00
	plb
	plb					; databank => $7f

	clc
	lda #$001e
	sta !loop_counter_62	; counter => $1e

	ldx #$0000			; source offset => $0000
	.Loop {
		jsr ReverseWordArray
		jsr ReverseWordArray

		dec !loop_counter_62	; decrement counter
		bne .Loop				; loop until counter = 0
	}

	rts					; exit routine


; pc should equal $0c9260
pullpc
;--------------------------------------------------------------------
pushpc
org $0c9260


; ROUTINE: Reverse word array ($0c9260)
;		reverses the order of an array of $8 words ($10 bytes)
;		the bytes are not reversed, just words
; parameters:
;		X => address offset
; returns:
;		X => X + $10 (offset is incremented)
; AXY => 16bit
ReverseWordArray:
	lda $0000,x
	tay
	lda $000e,x
	sta $0000,x
	tya
	sta $000e,x
	lda $0002,x
	tay
	lda $000c,x
	sta $0002,x
	tya
	sta $000c,x
	lda $0004,x
	tay
	lda $000a,x
	sta $0004,x
	tya
	sta $000a,x
	lda $0006,x
	tay
	lda $0008,x
	sta $0006,x
	tya
	sta $0008,x
	txa
	adc #$0010			; increase offset
	tax
	rts					; exit routine


; pc should equal $0c929e
pullpc
;--------------------------------------------------------------------
pushpc
org $0c929e


; ROUTINE: Reverse bits and shift left section ($0c929e)
;		for bytes $7f0000-$7f0eb9 (size = $3c0)
;		reverse and shift first $10 bytes
;		then reverse and shift $8 more times skipping every other byte
; XY => 16bit
ReverseBitsAndShiftLeftSection:
	pea $7f00
	plb
	plb					; databank => $7f

	ldy #$001e			; loop counter => $1e
	ldx #$0000			; X => $0000
	.Loop {
		phy					; save counter

		ldy #$0010			; loop 2 counter => $10
		.Loop2 {
			jsr ReverseBitsAndShiftLeft
			dey					; decrement counter #2
			bne .Loop2
		}

		ldy #$0008			; loop 3 counter => $8
		.Loop3 {
			jsr ReverseBitsAndShiftLeft
			inx					; increment offset (skip one byte)
			dey					; decrement counter #3
			bne .Loop3
		}

		ply					; restore counter
		dey					; decrement counter
		bne .Loop
	}

	rts					; exit routine


; pc should equal $0c92c2
pullpc
;--------------------------------------------------------------------
pushpc
org $0c92c2


; ROUTINE: Reverse bits in byte and shift left ($0c92c2)
;		turns 12345678 into 76543210
;		carry contains 8 at end
; parameters:
;		X => address offset
ReverseBitsAndShiftLeft:
	%setAto8bit()
	lda $0000,x			; A => 12345678, c => ?, out => 12345678
	lsr a				; A => 01234567, c => 8, out => 12345678
	lsr a				; A => 00123456, c => 7, out => 12345678
	rol $0000,x			; A => 00123456, c => 1, out => 23456787
	lsr a				; A => 00012345, c => 6, out => 23456787
	rol $0000,x			; A => 00012345, c => 2, out => 34567876
	lsr a				; A => 00001234, c => 5, out => 34567876
	rol $0000,x			; A => 00001234, c => 3, out => 45678765
	lsr a				; A => 00000123, c => 4, out => 45678765
	rol $0000,x			; A => 00000123, c => 4, out => 56787654
	lsr a				; A => 00000012, c => 3, out => 56787654
	rol $0000,x			; A => 00000012, c => 5, out => 67876543
	lsr a				; A => 00000001, c => 2, out => 67876543
	rol $0000,x			; A => 00000001, c => 6, out => 78765432
	lsr a				; A => 00000000, c => 1, out => 78765432
	rol $0000,x			; A => 00000000, c => 7, out => 87654321
	asl $0000,x			; A => 00000000, c => 8, out => 76543210
	inx					; increment address offset
	%setAXYto16bit()
	rts					; exit routine


; pc should equal $0c92eb
pullpc
;--------------------------------------------------------------------
pushpc
org $0c92eb


; ROUTINE: Expand second half with zeros ($0c92eb)
;		for bytes $7f0000-$7f0eb9 (size = $3c0)
;		for $20 byte chunks, skip first $10
;		then expand next $8 with zeros between bytes
;		so:			----------------abcdefgh--------
;		becomes:	----------------a0b0c0d0e0f0g0h0
; AXY => 16bit
; direct page => $0000
ExpandSecondHalfWithZeros:
	clc
	lda #$001e
	sta !loop_counter_62		; loop counter => $1e
	lda #$0000					; A => $0000
	.Loop {
		adc #$0018			; A += $18
		tax					; X => A
		adc #$0008			; A += $8
		tay					; Y => A
		pha					; save A

		lda #$0008
		sta !loop_counter_64		; loop counter #2 => $8
		.Loop2 {
			dex						; X -= 1
			dey
			dey						; Y => Y - 2
			lda $0000,x
			and #$00ff
			sta $0000,y				; word at Y => $00(lower byte at X)
			dec !loop_counter_64		; decrement counter #2
			bne .Loop2
		}

		pla						; restore A
		dec !loop_counter_62		; decrement counter
		bne .Loop
	}

	rts					; exit routine


; pc should equal $0c9318
pullpc
;--------------------------------------------------------------------
pushpc
org $0c9318


; ROUTINE: CopyABunch0c9318 ($0c9318)
;		sources =>
;			$04e220-$04e27f, in file $026220-$02627f, $60 bytes
;			$04e490-$‭04e51f, in file $026490-$0‭2651f, $90 bytes
;			$04fcc0-$0‭4fe9f‬, in file $027cc0-$0‭27e9f, $1E0 bytes
;		destination => $7f0000-$7f0eb9
;			size => $3c0, chunk size => $20, number of chunks => $1e
;		copies $18 bytes then skips $8 bytes each chunk
; AXY => 16bit
; direct page => $0000
; TODO: rename routine!!
CopyABunch0c9318:
	clc
	ldx #$e220			; source offset => $e220 (in file => $026220)
	ldy #$0000			; destination offset => $0000
	lda #$0004			; times to loop => $4 ($60 bytes)
	jsr CopyABunch0c9318_Entry
	ldx #$e490			; source offset => $e490 (in file => $026490)
	lda #$0006			; times to loop => $6 ($90 bytes)
	jsr CopyABunch0c9318_Entry
	ldx #$fcc0			; source offset => $fcc0 (in file => $027cc0)
	lda #$0014			; times to loop => $14 ($1E0 bytes)

CopyABunch0c9318_Entry:
	; source offset => X, increases $18 each loop
	; destination offset => Y, increases $20 each loop
	sta !loop_counter_62
	.Loop {
		lda #$0017				; bytes to copy => $18
		mvn $04,$7f				; copy $18 bytes from $04:X[] to $7f:Y[]
		tya
		adc #$0008
		tay						; Y += $8, skip $8 bytes
		dec !loop_counter_62		; decrement counter
		bne .Loop
	}

	rts				; exit routine


; pc should equal $0c9346
pullpc
;--------------------------------------------------------------------









