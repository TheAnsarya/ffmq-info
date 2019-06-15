






pushpc
org $008ddf

; ROUTINE: Copy tiles to VRAM (00:8ddf)
;		loops Y times, writing one tile to VRAM each time
;			copies $10 bytes to vram, then copies $8 bytes as the low byte using the same high byte loaded from $00f0-$00f1
;			so if data for last $8 bytes is = $AA $BB $CC... and $00f0 = $5500, then the second part would write as $55AA $55BB $55CC...
; parameters:
;		databank => source address bank
;		X => source address offset
;		Y => number of times to loop
;		ram $00f0 => high byte (which is at $00f1) will be used as high byte for second half of copies
; $2115-$2117 should be set up with vram options and vram destination address
CopyTilesToVRAM:
	php				; save processor status to stack
	phd				; save direct page to stack
	%setAXYto16bit()
	lda #$2100		;
	tcd				; set direct page => $2100 so writes are to registers
	clc				; clear carry

	; write a tile to vram Y times {
	.Loop {
		phy				; save counter to stack

		; copy $10 bytes to vram
		!counter = 0
		while !counter < $10
			lda $0000+!counter,x
			sta $18
			
			!counter #= !counter+2
		endif

		lda $00f0			; high byte loaded here will be kept for these next $8 writes
		%setAto8bit()

		; read $8 bytes, write $10 bytes to vram
		!counter = 0
		while !counter < $8
			lda $0010+!counter,x
			tay				; copy 16bit version of A to Y
			sty $18			; write 2 bytes to vram $2118
			
			!counter #= !counter+1
		endif

		%setAXYto16bit()

		txa				; set A => source address offset
		adc #$0018		; increment by $18 (one tile's worth of data)
		tax				; set source address offset => A

		ply				; resore counter from stack
		dey				; decrement counter
		bne .Loop
	}
	pld				; restore direct page from stack
	plp				; restore processor status from stack
	rtl				; exit routine

; pc should equal $008e54

pullpc
















pushpc
org $008ec4

; ROUTINE:         (00:8ec4)
; TODO: what are we actually loading? overworld? city? title?
; TODO: finish code/comment cleanup
; TODO: Better label name
				; setup
LoadTilesAndColors:
	php					; save processor status to stack
	phd					; save direct page to stack
	%setAXYto16bit()
	lda #$2100			; 
	tcd					; set direct page => $2100, so direct mode writes are to the registers
	%setAto8bit()

	; 
	; TODO: address translation in vram write, 8bit mode. lda #$84 / sta $15. tile data or map data?
	ldx #$1801			; $01 means write 2 bytes each time
						; $18 means destination is $2118 VRAM register  
	stx $4350			; write dma control and destination registers
						; setup source => $07:8030
	ldx #$8030				; 
	stx $4352				; set source address offset => $8030
	lda #$07				; 
	sta $4354				; set source address bank => $07
	ldx #$1000			; 
	stx $4355			; set DMA transfer size to $1000 bytes
	ldx #$3000			; 
	stx $16				; set vram destination address => $3000
	lda #$84			; $84 means 													; TODO: 
	sta $15				; set video port control [VMAIN]
	lda #$20			; bitmask for DMA channel 5
	sta $420b			; start DMA transfer on channel 5

	; load $100 tiles from $04:8000 ($18 bytes each) to vram address $2000 ($20 bytes each)
	lda #$80			; $80 means increment destination address by 1 word (2 bytes) on write
	sta $15				; set video port control [VMAIN]
	%setAXYto16bit()
	lda #$ff00			; 
	sta $00f0			; set high byte for second half of tile => $ff
	ldx #$2000			; 
	stx $16				; set vram destination address => $2000
						; setup source => $04:8000
	%setDatabank(04)
	ldx #$8000			; set source address offset => $8000
	ldy #$0100			; going to copy $100 tiles
	jsl CopyTilesToVRAM
	plb					; restore databank from stack

	; load $10 colors ($4 colors * $4 times)
	; writes the second half of palettes $0-$1
	; TODO: what colors are these?
	%setAXYto8bit()
	%setDatabank(07)
	lda #$08			; set starting color index => $08
	ldx #$00			; set source address offset => $00
	jsr Copy4ColorsToCGRAM
	lda #$0c			; set starting color index => $0c
	ldx #$08			; set source address offset => $08
	jsr Copy4ColorsToCGRAM
	lda #$18			; set starting color index => $18
	ldx #$10			; set source address offset => $10
	jsr Copy4ColorsToCGRAM
	lda #$1c			; set starting color index => $1c
	ldx #$18			; set source address offset => $18
	jsr Copy4ColorsToCGRAM
	plb				; restore databank from stack

	; Load the menu background color into indexes $0d and $1e
	; ram $0e9c-$0e9d - 2 bytes - menu background color (chosen by player in the menu)
	ldx $0e9c
	ldy $0e9d
	lda #$0d
	sta $21
	stx $22
	sty $22
	lda #$1d
	sta $21
	stx $22
	sty $22

	; load $18 colors ($8 colors * $6 times)
	; TODO: what colors are these?
	; writes the second half of palettes $2-$7
	; source data offset and color index increase by $10 each loop
	; so source data is contiguous but index skips $8 every loop
	ldy #$06			; loop counter
	lda #$00			; start color index and source data offset at $00
	clc
	%setDatabank(07)
	.Loop {
		tax					; set source offset => 
		adc #$28			; color indexes start at $28
		sta $21				; set starting color index

		; write 16 bytes to CGRAM
		!counter = 0
		while !counter < 16
			lda $d8e4+!counter,x
			sta $22
			
			!counter #= !counter+1
		endif

		txa					; retrieve source offset
		adc #$10				; advance by the $10 bytes we wrote
		dey					; decrement counter
		bne .Loop
	}

	plb				; restore databank
	pld				; restore direct page from stack
	plp				; restore processor status from stack
	rts				; exit routine

; pc should equal $008fb4

pullpc














pushpc
org $008fb4

; ROUTINE: Copy $4 colors to CGRAM ($008fb4)
; parameters:
;		A => the starting color index
;		X => source address offset
; called with:
;		all known calls use databank => $07 but don't have to
; AXY are 8bit
; D is $2100 so the writes are to registers
Copy4ColorsToCGRAM:
	sta $21			; set CGRAM address $2121
	
	; write 8 bytes to CGRAM
	!counter = 0
	while !counter < 8
		lda $8000+!counter,x
		sta $22
		
		!counter #= !counter+1
	endif
	
	rts				; exit routine

; pc should equal $008fdf

pullpc





pushpc
org $01914c

; ROUTINE:  ($01914c)
01914c jsr $8b75		; jump to the "Clear bits in 2 byte value at $008e using mask of $4030" routine
	jsl Something
019153 jsr $c839
019156 jsr $af55
019159 jsl $0b87b9
01915d jsl $0b836a
	jsr CopyTileDataToWRAM
019164 jsl $0b83b8
019168 jsl $0b83f2
01916c jsr $81db
01916f jsr $fe0b
019172 jsl $0b84fb
019176 ldy $0e89
019179 jsr $fd50
01917c sty $0e89
01917f jsl $0b8223
019183 jsl $0b8560
019187 jsr $c750
01918a ldx #$0000		; clear X
01918d stx $1908
019190 stx $190a
019193 ldx #$0008
019196 stx $1900
019199 ldx #$00f8
01919c stx $1902
01919f php				; save processor status to stack
0191a0 jsr $9fae
0191a3 plp
0191a4 jsr $a226
0191a7 ldx #$ffff
0191aa stx $195f
0191ad jsr $a403
0191b0 jsr $e76a
0191b3 jsr $ab5c
0191b6 jsr $ab5c
0191b9 jsr $ab5c
0191bc jsr $c8a8
0191bf jsl $0b82aa
0191c3 lda $1cc2
0191c6 beq $91d8


;MISSING


0191d8 jsr $94cc
0191db jsr $e61c
0191de jsr $a08a

0191e1 jsl $0c8000
0191e5 lda $0110
0191e8 bpl $91e1

0191ea lda $0111
0191ed pha
0191ee stz $0111
0191f1 stz $420c
0191f4 jsl $0b841d
0191f8 jsr $8435		; jump to "Copy $2000 bytes from WRAM $7fd274 to VRAM $0000 through DMA (channel 0)" routine
0191fb jsr $845d
0191fe jsr $8492
019201 jsr $84b8
019204 jsr $836c
019207 jsr $fe6b
01920a jsr $8672
01920d jsr $84e0
019210 lda $1916
019213 and #$1f
019215 sta $19ee
019218 sta $19f5
01921b lda #$26
01921d sta $19ef
019220 jsl $01b24b
019224 lda $19f6
019227 beq $9233


;MISSING



019233 pla
019234 sta $0111
019237 stz $1a46
01923a stz $19ac
01923d lda $0e91
019240 cmp #$05
019242 beq .Exit

019244 lda #$02
019246 sta $1a45

019249 jsl $0c8000
01924d lda $1a45
019250 bne $9249

019252 ldx #$0000
019255 stx $0015
019258 stz $19a5
01925b jsr $8b82
01925e lda $0e91
019261 beq .Exit

019263 jsl $009aec

	.Exit
	rts				; exit routine

; pc should equal $019268

pullpc




01c839 lda #$00
01c83b xba
01c83c lda $0e91
01c83f tax
01c840 lda $06be77,x
	bmi .Exit
01c846 asl a
01c847 tax
01c848 php				; save processor status to stack
01c849 rep #$30			; set A,X,Y => 16bit
01c84b lda $06bee3,x
01c84f tax
01c850 plp
	.Loop {
01c851 lda $06bf15,x
01c855 cmp #$ff
01c857 beq $c882
01c859 jsl $009776
01c85d beq $c87d
01c85f lda $06bf16,x
01c863 sta $19ee
01c866 lda $06bf17,x
01c86a sta $19ef
01c86d cmp #$24
01c86f beq $c883
01c871 cmp #$28
01c873 beq $c88b
01c875 ldy $19ee
01c878 cpy #$2500
01c87b beq $c8a2
01c87d inx
01c87e inx
01c87f inx
		bra .Loop
	}

	.Exit
		rts				; exit routine

; pc should equal $01c883


; TODO: there is more to this routine, get additional code


pullpc











pushpc
org $01e90c

; ROUTINE: Copy one tile to WRAM ($01:e90c)
;		$18 bytes from source => $20 bytes destination
;		Copy the first $10 bytes, then copy each of the next $8 bytes followed by a zero byte (so AABBCC... becomes AA00BB00CC00...)
; parameters:
;		Y => source address offset
; $2181-$2183 - should be set to wram destination address
CopyOneTileToWRAM:
	phd					; save directpage to stack
	phx					; save X to stack

	; make so writing to $80 is $2180 [WMDATA]
	%setDirectpage($2100)

	; copy first ten bytes
	ldx #$0010			; loop counter
	.Loop {
		lda $0000,y			; load the source byte
		iny					; increment source address
		sta $80				; write byte
		dex					; decrement counter
		bne .Loop
	}

	; copy last $8 bytes mixed with zeros
	ldx #$0008			; loop counter
	.LoopB {
		lda $0000,y			; load the source byte
		iny					; increment source address
		sta $80				; write byte
		stz $80				; write $00
		dex					; decrement counter
		bne .LoopB
	}

	plx				; restore X 
	pld				; restore directpage
	rts				; exit routine

; pc should equal $01e92f

pullpc








pushpc
org $01e946

; ROUTINE: Clear $20 bytes of WRAM ($01:e946)
; 
; $2181-$2183 - should be set to wram destination address
Clear32bytesOfWRAM:
	phd					; save directpage
	phx					; save X

	; make so writing to $80 is $2180 [WMDATA]
	%setDirectpage($2100)
	
	; clear $20 bytes ($4 bytes * $8 times)
	ldx #$0008			; loop counter
	.Loop
		stz $80				; Clear 4 bytes
		stz $80
		stz $80
		stz $80
		dex					; decrement counter
		bne .Loop
	}

	plx					; restore X
	pld					; restore directpage
	rts					; exit routine

; pc should equal $01e95d

pullpc













pushpc
org $01fd7b

; ROUTINE: Copy tile data to WRAM ($01:fd7b)
;		Copies two sets of tiles into WRAM
;			1. destination => $7f:d274-‭$7f:f273‬ in $400 byte chunks
;				when @var-control is negative, the chunk is all $00
;				else, copy tiles from source address offset => $05:8c80 + ($0300 * @var-control)
;			2. destination => $7f:f274-$7f:f373 in $20 byte chunks
;				source address offset => $05:f280 + (@var-control * $10)
;				bottom 3 bits of each source nibble (low then high) becomes output byte
;					so $42 => $02 $04
;					and $CA => $02 $04
;				TODO: are these tiles?
;		(for certain maps, like first map "Level Forest") TODO: what all calls this?
; parameters:
;		ram $191a-1921 => values for @var-control
; A is 8bit
; TODO: better label?
CopyTileDataToWRAM:
	phb					; save program bank to stack
	%setDatabankA(05)

	; setup destination address (WRAM)
	ldx #$d274
	stx $2181			; set destination offset to $d274
	lda #$7f
	sta $2183			; set destination bank to $7f

	; copy $8 blocks of $400 bytes: either copy $20 tiles or clear bytes
	ldx #$0000			; loop counter
	.Loop {
		lda $191a,x			; variable: @var-control, get value from $191a+x (lowram) TODO: trace this ram value
		bpl .CopyTiles		; if positive => copy tiles, else => clear $400 bytes

		; clear $400 bytes of wram
		ldy #$0020			; loop counter
		.LoopA
			jsr Clear32bytesOfWRAM
			dey				; decrement counter
			bne .LoopA
		}

		bra .LoopEnd

		.CopyTiles
			; determine source address offset
			xba					; save @var-control
			stz $211b
			lda #$03
			sta $211b			; set [M7A] = $0300
			xba					; swap @var-control back in
			sta $211c			; set [M7B] = @var-control

			%setAto16bit()
			lda #$8c80			; source address base (label DataTiles)
			clc
			adc $2134			; source address offset => $8c80 + ($0300 * @var-control)
			tay					; set source address offset
			%setAto8bit()

			; copy $20 tiles to WRAM
			phx					; save loop counter
			ldx #$0020			; loop counter
			.LoopB
				jsr CopyOneTileToWRAM
				dex					; decrement counter
				bne .LoopB
			}
			plx				; restore loop counter

		.LoopEnd
			inx				; increment counter
			cpx #$0008		; loop until counter = $8
			bne .Loop
	}

	%setDatabankA(05)

	ldx #$f274
	stx $2181			; set destination offset to $f274

	; write $8 * $20 = $100 bytes
	ldx #$0000			; loop counter
	.LoopC {
		lda $191a,x			; variable: @var-control, get value from $191a+x (lowram) TODO: trace this ram value
		phx					; save loop counter

		; determine source address offset
		sta $211b
		stz $211b			; set [M7A] = $00(@var-control)
		lda #$10
		sta $211c			; set [M7B] = $10
		ldy $2134			; source address offset => @var-control * $10

		; read $10 bytes, write $20 bytes
		; split upper and lower nibbles into individual bytes
		ldx #$0010			; loop counter
		.LoopD {
			; write lower nibble
			lda $f280,y
			and #$07			; bits 0-2
			sta $2180

			; write upper nibble
			lda $f280,y
			and #$70			; bits 4-6
			lsr a
			lsr a				; shift right
			lsr a				; so upper nibble
			lsr a				; becomes lower nibble
			sta $2180

			iny					; increment source address offset
			dex					; decrement counter
			bne .LoopD
		}

		plx					; restore loop counter
		inx					; increment counter
		cpx #$0008			; loop until counter = $8
		bne .LoopC
	}

	plb					; restore program bank
	rts					; exit routine

; pc should equal $01fe0b

pullpc






pushpc
org $0b8149

; ROUTINE:  ($0b:8149)
;
; A is 8bit, XY is 16bit
; TODO: rename!!!
Something:
	; setup variables
	stz $19f6			; @var-19f6 => $00
	lda #$80
	sta $19a5			; @var-19a5 => $80
	lda #$01
	sta $1a45			; @var-1a45 => $01
	ldx $19f1			; load @var-19f1
	stx $0e89			; @var-0e89 => @var-19f1
	lda $19f0			; load @var-19f0
	sta $0e91			; @var-0e91 => @var-19f0
	bne .IsZero			; if @var-19f0 is $0000

	lda #$f2
	jsl TRBWithMaskFromTable97fbTo0ea8		; set @var-0ec6 => 

	stz $1a5b			; @var-1a5b => $00

	lda $0e88			; load @var-0e88
	%setAto16bit()
	and #$00ff			; ignore upper byte

	asl a
	tax
	lda Data07f7c3,x
	sta $0e89			; @var-0e89 => 
	%setAto8bit()
	lda #$f3
	jsl ANDFromTable97fbAnd0ea8ToA
	bne .IsZero 
	lda #$02
	sta $0e8b			; @var-0e89 => $02

	; clear $0ec8-$0ee7 and $0f28-$0f47
	ldx #$0000
	lda #$20			; loop counter
	.Loop {
		stz $0ec8,x			; @var-0ec8[x] => $00
		stz $0f28,x			; @var-0f28[x] => $00
		inx					; increment destination offset
		dec					; decrement counter
		bne .Loop
	}

	; clear $0ee8-$0f17
	lda #$30			; loop counter
	.LoopB {
		stz $0ec8,x			; @var-0ec8[x] => $00
		inx					; increment destination offset
		dec					; decrement counter
		bne .LoopB
	}

	.IsZero

	; 
	lda $0e91			; load @var-0e91
	%setAto16bit()
	and #$00ff			; ignore upper byte
	asl a
	tax					; source offset => @var-0e91 * 2
	lda Data07af3b,x
	tax					; source offset => Data07af3b[@var-0e91 * 2]
	%setAto8bit()
	stx $19b5			; @var-19b5 => source offset

	; 
	ldy #$0000			; loop counter
	.LoopC {
		lda Data07B013,x	; 
		sta $1910,y			; @var-1910[y] => Data07B013[x]
		inx					; increment source offset
		iny					; increment counter
		cpy #$0007			; loop until counter = $7
		bne .LoopC
	}

	; determine source address offset
	; @var-1911 is source address index
	lda #$0a
	sta $211b
	stz $211b			; set [M7A] => $000a
	lda $1911
	sta $211c			; set [M7B] => @var-1911
	ldx $2134
	stx $19b7			; source address offset => @var-1911 * $0a

	; copy $a bytes into @var-1918[]
	ldy #$0000			; loop counter
	.LoopD {
		lda DataTilesets,x
		sta $1918,y			; @var-1918[y] => DataTilesets[x]
		inx					; increment source offset
		iny					; increment counter
		cpy #$000a			; loop until counter = $a
		bne .LoopD
	}

	ldx #$ffff			; default @var-19b9 value is $FFFF
	lda $1912
	cmp #$ff
	beq .Skip			; skip ahead if @var-1912 is $FF

	%setAto16bit()
	and #$00ff			; ignore upper byte
	asl a				; A => A * 2
	tax					; source address offset => @var-1912 * 2
	lda Data0b8892,x
	tax
	%setAto8bit()

	.Skip
	stx $19b9			; @var-19b9 => X

	lda $1916			; load @var-1916
	and #$e0			; bits 5-7
	lsr a
	lsr a				; A => A / 8
	lsr a
	sta $1a55			; @var-1a55 => A

	lda $1915			; load @var-1915
	and #$e0			; bits 5-7
	ora $1a55			; combine with other 3 bits
	lsr a
	lsr a				; A => A / 4
	sta $1a55			; @var-1a55 => byte made of: two 0 bits, top three bits of @var-1915, top three bits of @var-1916

	rtl					; exit routine

; pc should equal $0b8223

pullpc






pushpc
org pctosnes($058892)

; DATA:  ($0b8892)
Data0b8892:



; pc should equal $

pullpc





pushpc
org pctosnes($058CD9)

; DATA:  ($0b8cd9)
;		accessed in $a byte chunks
;		bytes $00-$01 are ??? TODO: what are these
;		bytes $2-$9 of each are indexes into tile graphics data (label = DataTiles)
;			values $00-$21 are indexes, $FF means clear section
;		ends up in $1918-$1921
DataTilesets:
	db $B0,$16,$1E,$1F,$20,$21,$FF,$FF,$FF,$FF
	db $B0,$17,$1E,$1F,$20,$21,$FF,$FF,$FF,$FF
	db $52,$11,$00,$01,$02,$03,$04,$05,$06,$07
	db $73,$01,$00,$01,$02,$03,$04,$05,$06,$07
	db $94,$04,$08,$09,$0A,$0B,$0C,$05,$06,$07
	db $52,$03,$00,$01,$02,$03,$04,$05,$06,$07
	db $75,$19,$08,$09,$0A,$0B,$0C,$1C,$15,$07
	db $F1,$11,$00,$01,$02,$09,$06,$07,$11,$13
	db $F6,$0A,$18,$1B,$1C,$1D,$04,$07,$FF,$FF
	db $FD,$0B,$08,$09,$0A,$03,$04,$18,$12,$13
	db $BE,$07,$08,$09,$0A,$0B,$0C,$0D,$04,$1D
	db $6E,$07,$08,$09,$0A,$0B,$0C,$0D,$04,$1D
	db $74,$07,$08,$09,$0A,$0B,$0C,$0D,$15,$07
	db $F9,$09,$1A,$1B,$0A,$10,$0C,$FF,$FF,$FF
	db $F9,$09,$1A,$1B,$0A,$10,$0C,$FF,$FF,$FF
	db $51,$0E,$00,$01,$02,$09,$06,$07,$11,$13
	db $FE,$07,$08,$09,$0A,$0B,$0C,$0D,$15,$07
	db $DF,$08,$18,$19,$1A,$11,$04,$FF,$FF,$07
	db $FF,$08,$18,$19,$1A,$11,$04,$FF,$FF,$07
	db $F5,$06,$16,$17,$18,$01,$07,$FF,$FF,$FF
	db $F6,$0A,$18,$1B,$1C,$1D,$04,$07,$FF,$FF
	db $B6,$0A,$18,$1B,$1C,$1D,$04,$07,$FF,$FF
	db $7D,$0B,$08,$09,$0A,$03,$04,$18,$12,$13
	db $F7,$0C,$18,$1D,$02,$03,$04,$12,$13,$07
	db $77,$0C,$18,$1D,$02,$03,$04,$12,$13,$07
	db $F8,$0D,$04,$06,$14,$15,$11,$18,$1D,$07
	db $F8,$0D,$04,$06,$14,$15,$11,$18,$1D,$07
	db $FB,$14,$13,$01,$02,$03,$04,$06,$18,$09
	db $51,$0E,$00,$01,$02,$09,$06,$07,$11,$13
	db $5A,$0F,$00,$01,$02,$18,$04,$13,$06,$07
	db $FC,$05,$0E,$0F,$10,$11,$15,$05,$FF,$FF
	db $FB,$12,$13,$01,$02,$03,$04,$06,$18,$11
	db $EC,$05,$0E,$0F,$10,$11,$15,$05,$FF,$FF
	db $F7,$13,$16,$18,$02,$03,$04,$FF,$13,$07
	db $F8,$0D,$04,$06,$14,$15,$11,$18,$1D,$07
	db $A6,$0A,$18,$1B,$1C,$1D,$04,$07,$FF,$FF
	db $A7,$0C,$18,$1D,$02,$03,$04,$12,$13,$07
	db $A8,$0D,$04,$06,$14,$15,$11,$18,$1D,$07
	db $58,$10,$04,$06,$14,$15,$11,$18,$1D,$07
	db $5D,$10,$0D,$06,$14,$15,$1B,$18,$1D,$07
	db $54,$04,$08,$09,$0A,$0B,$0C,$05,$06,$07
	db $5D,$10,$0D,$06,$14,$15,$1B,$18,$1D,$07
	db $5E,$07,$08,$09,$0A,$0B,$0C,$0D,$04,$1D
	db $51,$0E,$00,$01,$02,$09,$06,$07,$11,$13

; pc should equal $0B8E91

pullpc








pushpc
org pctosnes($03af3b)

; DATA:  ($07af3b)
;		table of 16bit offset pointers into $07b013[]
; TODO: what is this?
; TODO: does it actually consist of all $200 bytes?
; TODO: another table starts at $07b013, so cut off data there?
Data07af3b:
	db $00,$00,$00,$00,$09,$00,$09,$00,$09,$00,$09,$00,$12,$00,$68,$00
	db $0B,$01,$29,$01,$7F,$01,$C7,$01,$D7,$01,$34,$02,$B4,$02,$3B,$03
	db $83,$03,$B6,$03,$0C,$04,$2A,$04,$AA,$04,$4D,$05,$D4,$05,$46,$06
	db $5D,$06,$90,$06,$CA,$06,$EF,$06,$37,$07,$D3,$07,$61,$08,$B7,$08
	db $1B,$09,$47,$09,$C7,$09,$63,$0A,$06,$0B,$A9,$0B,$4C,$0C,$E1,$0C
	db $3E,$0D,$3E,$0D,$63,$0D,$A4,$0D,$BB,$0D,$E7,$0D,$05,$0E,$38,$0E
	db $79,$0E,$9E,$0E,$25,$0F,$BA,$0F,$5D,$10,$AC,$10,$D1,$10,$4A,$11
	db $CA,$11,$12,$12,$A7,$12,$4A,$13,$D8,$13,$6D,$14,$02,$15,$97,$15
	db $D8,$15,$43,$16,$5A,$16,$86,$16,$29,$17,$CC,$17,$6F,$18,$B0,$18
	db $53,$19,$BE,$19,$61,$1A,$B0,$1A,$1B,$1B,$2B,$1B,$49,$1B,$59,$1B
	db $FC,$1B,$9F,$1C,$42,$1D,$C9,$1D,$5E,$1E,$F3,$1E,$96,$1F,$32,$20
	db $C7,$20,$5C,$21,$FF,$21,$1D,$22,$3B,$22,$59,$22,$77,$22,$95,$22
	db $B3,$22,$D8,$22,$82,$23,$1E,$24,$C1,$24,$25,$25,$2E,$25,$C3,$25
	db $51,$26,$ED,$26,$F6,$26,$84,$27

; pc should equal $07B013

pullpc

pushpc
org pctosnes($03b013)

; DATA:  ($07B013)
; Data07af3b has 16 bit offset pointers to this data
; TODO: what is all this
; TODO: is size correct?
Data07B013:
	db $00,$00,$00,$DF,$20,$60,$E5,$00,$FF,$28,$28,$00,$EF,$00,$00,$19
	db $00,$FF,$1C,$1C,$34,$01,$60,$40,$59,$21,$F4,$AC,$8F,$8E,$4A,$03
	db $30,$FE,$AD,$90,$8F,$2A,$03,$40,$F4,$AE,$90,$8E,$0C,$03,$50,$F4
	db $AF,$92,$4E,$4A,$03,$4C,$F4,$B0,$90,$90,$6A,$03,$54,$F4,$B1,$91
	db $8E,$6A,$03,$58,$F4,$B2,$93,$0E,$6A,$03,$5C,$F4,$B3,$93,$10,$8A
	db $03,$28,$F4,$B4,$92,$D0,$8A,$03,$2C,$F4,$B5,$91,$90,$8A,$03,$6C
	db $F4,$B6,$05,$CF,$A7,$01,$48,$FF,$21,$21,$01,$00,$46,$42,$0C,$E4
	db $0E,$01,$16,$17,$0E,$03,$2C,$0E,$01,$16,$18,$0F,$03,$2C,$0E,$01
	db $17,$17,$10,$03,$2C,$0E,$01,$17,$18,$11,$03,$2C,$00,$BE,$1B,$04
	db $2A,$0B,$6A,$00,$BE,$0F,$13,$2A,$0B,$6A,$00,$BF,$17,$2C,$2B,$0B
	db $79,$00,$BF,$22,$25,$2B,$0B,$79,$00,$C0,$16,$1D,$4B,$0B,$78,$00
	db $C0,$2A,$1E,$4B,$0B,$78,$A9,$00,$68,$1E,$A6,$13,$24,$AA,$01,$68
	db $21,$A6,$13,$24,$00,$1E,$5F,$1E,$A6,$11,$26,$00,$1F,$56,$13,$A6
	db $13,$26,$00,$00,$53,$2A,$86,$9B,$28,$00,$01,$54,$13,$86,$9B,$28
	db $00,$02,$53,$1D,$86,$9B,$28,$00,$03,$53,$24,$86,$9B,$28,$00,$04
	db $4A,$20,$86,$99,$28,$00,$05,$52,$10,$86,$99,$28,$00,$06,$5A,$2D
	db $86,$99,$28,$00,$07,$5E,$17,$86,$99,$28,$FF,$21,$21,$02,$00,$00
	db $01,$0B,$01,$CB,$02,$2D,$27,$26,$03,$40,$CB,$1B,$2E,$27,$29,$23
	db $44,$00,$20,$78,$26,$A6,$13,$26,$FF,$22,$22,$03,$00,$00,$0B,$0B
	db $01,$CC,$07,$0D,$96,$06,$02,$30,$CC,$1B,$0E,$16,$09,$22,$34,$30
	db $03,$13,$0A,$3C,$00,$28,$31,$04,$13,$10,$5D,$00,$28,$32,$05,$13
	db $16,$7E,$02,$28,$33,$06,$18,$10,$9F,$02,$28,$2C,$08,$13,$4A,$3C
	db $3A,$28,$2D,$09,$13,$50,$5D,$3A,$28,$2E,$0A,$13,$56,$7E,$3A,$28
	db $2F,$0B,$18,$50,$9F,$3A,$28,$00,$21,$57,$0A,$A6,$12,$26,$FF,$22
	db $22,$02,$00,$00,$0C,$0B,$01,$CD,$08,$2F,$38,$26,$01,$40,$CD,$1B
	db $30,$38,$29,$21,$44,$20,$0C,$6F,$36,$86,$DB,$28,$21,$DD,$74,$2F
	db $86,$DB,$28,$20,$0D,$70,$76,$86,$59,$28,$21,$DE,$75,$6F,$86,$59
	db $28,$AB,$02,$6E,$28,$A6,$11,$24,$AC,$03,$70,$2C,$A6,$16,$24,$AD
	db $7B,$64,$35,$A6,$02,$24,$FF,$22,$22,$02,$00,$00,$0D,$0B,$01,$00
	db $22,$74,$0A,$A6,$12,$26,$FF,$86,$06,$02,$00,$42,$80,$97,$02,$00
	db $81,$16,$8F,$26,$03,$40,$00,$1B,$17,$0F,$29,$03,$44,$FE,$7F,$08
	db $17,$E1,$03,$04,$FE,$0E,$09,$17,$6B,$0B,$79,$00,$0F,$42,$16,$49
	db $18,$2C,$00,$10,$42,$57,$49,$18,$2C,$00,$11,$43,$96,$49,$18,$2C
	db $00,$12,$43,$D7,$49,$18,$2C,$00,$13,$44,$16,$48,$18,$2C,$00,$14
	db $44,$57,$48,$18,$2C,$00,$15,$45,$16,$47,$18,$2B,$00,$16,$45,$57
	db $47,$18,$2B,$FF,$07,$07,$04,$00,$14,$00,$0D,$03,$6C,$09,$15,$AF
	db $06,$03,$30,$6C,$1B,$16,$2F,$09,$23,$34,$00,$0A,$91,$B4,$2D,$03
	db $48,$34,$17,$4F,$34,$46,$5B,$28,$00,$15,$09,$27,$6B,$0B,$60,$00
	db $15,$08,$38,$6B,$0B,$60,$00,$15,$19,$23,$6B,$0B,$60,$00,$16,$0C
	db $2F,$8C,$0B,$62,$00,$15,$10,$2D,$6B,$0B,$60,$00,$16,$09,$35,$8C
	db $0B,$62,$00,$16,$0F,$2A,$8C,$0B,$62,$00,$16,$10,$26,$8C,$0B,$62
	db $00,$23,$46,$24,$A6,$13,$26,$00,$24,$47,$3B,$A6,$13,$26,$00,$25
	db $4F,$30,$A6,$13,$26,$00,$26,$5B,$23,$A6,$13,$26,$00,$27,$5B,$36
	db $A6,$13,$26,$FF,$07,$07,$05,$06,$34,$00,$0D,$03,$FE,$82,$06,$2F
	db $21,$03,$30,$FE,$83,$0C,$2F,$21,$03,$40,$FE,$0B,$05,$2F,$4B,$03
	db $78,$FE,$82,$18,$2E,$21,$03,$30,$00,$15,$09,$27,$4B,$0B,$60,$00
	db $15,$08,$38,$4B,$0B,$60,$00,$15,$19,$23,$4B,$0B,$60,$00,$16,$0C
	db $2F,$6C,$0B,$62,$00,$15,$10,$2D,$4B,$0B,$60,$00,$16,$09,$35,$6C
	db $0B,$62,$00,$16,$0F,$2A,$6C,$0B,$62,$00,$16,$10,$26,$6C,$0B,$62
	db $00,$28,$46,$24,$A6,$13,$26,$00,$29,$47,$3B,$A6,$13,$26,$00,$2A
	db $4F,$30,$A6,$13,$26,$00,$2B,$5B,$23,$A6,$13,$26,$00,$2C,$5B,$36
	db $A6,$13,$26,$34,$18,$4F,$34,$86,$5B,$28,$FF,$02,$02,$04,$00,$40
	db $00,$30,$04,$06,$0C,$10,$90,$22,$03,$4C,$06,$0D,$12,$10,$25,$03
	db $48,$06,$0E,$11,$85,$22,$03,$4C,$06,$0F,$09,$87,$25,$03,$48,$01
	db $10,$10,$90,$21,$03,$54,$01,$11,$12,$10,$21,$03,$50,$01,$12,$11
	db $85,$20,$03,$5C,$01,$13,$09,$87,$20,$03,$58,$00,$2D,$5F,$1B,$A6
	db $13,$26,$FF,$20,$20,$31,$01,$60,$40,$F0,$05,$00,$14,$8E,$CD,$2A
	db $03,$40,$62,$15,$8E,$4B,$2A,$03,$30,$7D,$16,$85,$8D,$2A,$03,$30
	db $F4,$A9,$8F,$0C,$4A,$03,$50,$00,$2E,$45,$0B,$A6,$13,$26,$62,$19
	db $4B,$0A,$86,$1F,$28,$FF,$20,$20,$31,$01,$60,$40,$F0,$04,$13,$17
	db $24,$A3,$45,$03,$60,$00,$18,$08,$A1,$41,$03,$6C,$00,$19,$08,$A8
	db $41,$03,$68,$AE,$05,$5D,$25,$A6,$13,$24,$00,$2F,$45,$26,$A6,$13
	db $26,$00,$30,$5F,$0F,$A6,$13,$26,$00,$31,$64,$0F,$A6,$13,$26,$00
	db $32,$73,$0A,$A6,$13,$26,$00,$33,$7A,$1A,$A6,$13,$26,$00,$1A,$5E
	db $23,$7A,$5B,$2A,$00,$1B,$5F,$23,$7A,$5B,$2A,$FF,$1F,$1F,$07,$01
	db $20,$00,$0E,$06,$FE,$84,$0E,$36,$01,$03,$30,$5A,$1A,$46,$39,$26
	db $03,$24,$00,$34,$5F,$0F,$26,$11,$26,$FF,$13,$13,$06,$43,$6C,$0B
	db $C6,$07,$00,$18,$31,$0C,$4C,$0B,$63,$00,$18,$31,$12,$4C,$0B,$63
	db $00,$18,$32,$14,$4C,$0B,$63,$00,$18,$35,$14,$4C,$0B,$63,$00,$18
	db $39,$14,$4C,$0B,$63,$00,$19,$39,$05,$4B,$0B,$64,$00,$19,$35,$05
	db $4B,$0B,$64,$00,$19,$32,$06,$4B,$0B,$64,$00,$19,$31,$0E,$4B,$0B
	db $64,$00,$19,$39,$11,$4B,$0B,$64,$00,$1A,$33,$02,$8B,$0B,$65,$00
	db $1A,$30,$08,$8B,$0B,$65,$00,$1A,$30,$11,$8B,$0B,$65,$00,$1A,$33
	db $17,$8B,$0B,$65,$00,$35,$71,$02,$A6,$13,$26,$00,$36,$71,$0D,$A6
	db $13,$26,$00,$37,$71,$17,$A6,$13,$26,$FF,$13,$13,$07,$43,$6C,$21
	db $06,$07,$FE,$85,$2D,$1B,$01,$03,$30,$00,$1B,$23,$2A,$AC,$0B,$67
	db $00,$1B,$1D,$28,$AC,$0B,$67,$00,$1B,$27,$28,$AC,$0B,$67,$00,$1B
	db $2B,$23,$AC,$0B,$67,$00,$1B,$2B,$2A,$AC,$0B,$67,$00,$1C,$23,$24
	db $6B,$0B,$65,$00,$1C,$27,$21,$6B,$0B,$65,$00,$1D,$23,$20,$8B,$0B
	db $66,$00,$1D,$27,$2C,$8B,$0B,$66,$AF,$06,$63,$34,$26,$13,$24,$00
	db $38,$5E,$24,$26,$13,$26,$00,$39,$5E,$10,$26,$13,$26,$00,$1C,$70
	db $37,$46,$3B,$28,$00,$1D,$72,$37,$46,$3B,$28,$00,$1E,$74,$37,$46
	db $3B,$28,$00,$1F,$63,$07,$46,$3B,$28,$00,$20,$63,$09,$46,$3B,$28
	db $00,$21,$63,$0B,$46,$3B,$28,$00,$22,$63,$0D,$46,$3B,$28,$00,$23
	db $63,$0F,$46,$3B,$28,$00,$24,$61,$0F,$46,$3B,$28,$FF,$13,$13,$06
	db $43,$6C,$02,$E6,$07,$00,$1E,$0F,$01,$0B,$0B,$79,$00,$1E,$05,$0D
	db $0B,$0B,$79,$00,$1E,$1A,$15,$0B,$0B,$79,$00,$20,$03,$1A,$2B,$0B
	db $78,$00,$20,$06,$2C,$2B,$0B,$78,$00,$20,$0F,$2E,$2B,$0B,$78,$00
	db $20,$15,$2C,$2B,$0B,$78,$00,$1F,$10,$04,$6B,$0B,$66,$00,$1F,$11
	db $0C,$6B,$0B,$66,$00,$1F,$05,$10,$6B,$0B,$66,$00,$1F,$10,$2B,$6B
	db $0B,$66,$00,$1F,$0D,$31,$6B,$0B,$66,$00,$1F,$15,$34,$6B,$0B,$66
	db $B0,$07,$57,$3B,$A6,$13,$24,$00,$3A,$53,$03,$A6,$13,$26,$00,$3B
	db $5A,$18,$A6,$13,$26,$00,$3C,$55,$29,$A6,$13,$26,$00,$3D,$46,$3C
	db $A6,$13,$26,$FF,$13,$13,$08,$43,$6C,$22,$06,$07,$FE,$86,$13,$1D
	db $01,$03,$30,$06,$1B,$11,$1D,$2E,$03,$2C,$06,$1B,$11,$1E,$2F,$03
	db $2C,$06,$1B,$12,$1D,$30,$03,$2C,$06,$1B,$12,$1E,$31,$03,$2C,$DB
	db $1B,$51,$16,$A6,$03,$24,$B1,$08,$51,$24,$A6,$13,$24,$00,$3E,$50
	db $16,$A6,$13,$26,$00,$3F,$52,$16,$A6,$13,$26,$00,$26,$55,$1D,$66
	db $3B,$28,$00,$27,$57,$18,$66,$9B,$28,$00,$28,$57,$23,$66,$9B,$28
	db $01,$2A,$50,$1D,$8A,$1B,$29,$01,$29,$11,$1D,$FA,$3B,$5C,$FE,$86
	db $17,$9D,$01,$03,$30,$FF,$1F,$1F,$02,$01,$20,$00,$0E,$08,$4E,$1C
	db $84,$8B,$0A,$03,$30,$00,$40,$44,$0A,$A6,$13,$26,$FF,$03,$03,$09
	db $00,$40,$40,$72,$09,$FE,$87,$0F,$10,$01,$03,$30,$00,$1D,$14,$87
	db $41,$03,$68,$00,$1E,$06,$89,$41,$03,$6C,$00,$1F,$04,$92,$40,$01
	db $70,$00,$2B,$4E,$10,$86,$1B,$28,$00,$2C,$4F,$1A,$66,$1F,$2A,$FF
	db $03,$03,$09,$20,$40,$00,$4F,$09,$FE,$88,$0E,$A8,$01,$01,$30,$00
	db $20,$14,$87,$41,$03,$68,$00,$21,$06,$A9,$41,$03,$6C,$00,$22,$04
	db $92,$40,$00,$70,$00,$23,$17,$30,$42,$03,$64,$00,$24,$08,$B8,$40
	db $03,$74,$00,$2D,$4F,$3A,$66,$1F,$2A,$FF,$1E,$1E,$09,$01,$60,$40
	db $B2,$0A,$FE,$89,$0B,$1D,$01,$03,$30,$5E,$25,$85,$55,$0A,$03,$30
	db $D9,$26,$85,$96,$2A,$03,$40,$00,$41,$47,$19,$A6,$13,$26,$FF,$1E
	db $1E,$09,$01,$60,$40,$B2,$09,$07,$27,$A7,$AB,$4B,$03,$64,$07,$28
	db $04,$8E,$40,$03,$74,$00,$29,$05,$05,$41,$03,$6C,$00,$2A,$AA,$F7
	db $4A,$03,$68,$00,$2B,$A7,$B1,$4D,$03,$60,$00,$2B,$28,$31,$16,$03
	db $2C,$00,$2C,$A7,$B3,$4A,$03,$68,$00,$2C,$28,$33,$16,$03,$2C,$00
	db $42,$43,$0C,$A6,$13,$26,$FF,$08,$08,$0A,$00,$50,$4B,$87,$0B,$FE
	db $8A,$2B,$2C,$01,$03,$30,$00,$45,$77,$1F,$A6,$13,$26,$00,$25,$39
	db $1E,$2A,$0B,$6C,$00,$22,$34,$05,$4B,$0B,$73,$00,$22,$31,$13,$4B
	db $0B,$73,$00,$22,$2E,$22,$4B,$09,$73,$00,$22,$39,$2F,$4B,$0B,$73
	db $00,$22,$38,$35,$4B,$0B,$73,$00,$23,$2D,$0A,$8C,$0B,$75,$00,$23
	db $3B,$10,$8C,$09,$75,$00,$23,$27,$20,$8C,$0B,$75,$00,$23,$3A,$2C
	db $8C,$0B,$75,$00,$23,$24,$39,$8C,$0B,$75,$00,$24,$2D,$1E,$6B,$0B
	db $65,$00,$24,$1A,$30,$6B,$0B,$65,$00,$24,$22,$32,$6B,$0B,$65,$00
	db $25,$18,$32,$2A,$0B,$6C,$00,$25,$1C,$25,$2A,$0B,$6C,$00,$43,$58
	db $34,$A6,$13,$26,$00,$44,$6C,$32,$A6,$13,$26,$00,$46,$7B,$2A,$A6
	db $13,$26,$FF,$08,$08,$0B,$00,$10,$0C,$07,$0B,$00,$26,$03,$39,$8C
	db $0B,$75,$00,$26,$10,$25,$8C,$0B,$75,$00,$26,$09,$30,$8C,$0B,$75
	db $00,$26,$0B,$30,$8C,$0B,$75,$00,$27,$05,$35,$6B,$0B,$65,$00,$27
	db $0B,$23,$6B,$0B,$65,$00,$27,$0E,$25,$6B,$0B,$65,$00,$27,$0D,$33
	db $6B,$0B,$65,$00,$28,$07,$25,$2A,$0B,$6C,$00,$28,$09,$2E,$2A,$0B
	db $6C,$00,$28,$0D,$31,$2A,$0B,$6C,$00,$28,$0B,$35,$2A,$0B,$6C,$00
	db $29,$07,$29,$6B,$0B,$72,$00,$29,$10,$27,$6B,$0B,$72,$00,$29,$0C
	db $25,$6B,$0B,$72,$00,$47,$4D,$27,$A6,$13,$26,$00,$48,$4F,$29,$A6
	db $13,$26,$00,$49,$4F,$37,$A6,$13,$26,$00,$4A,$4F,$38,$A6,$13,$26
	db $FF,$08,$08,$0B,$00,$10,$8D,$07,$0B,$24,$DA,$08,$0D,$2B,$1F,$7A
	db $00,$2A,$06,$15,$6B,$0B,$65,$00,$2A,$06,$0A,$6B,$0B,$65,$00,$2B
	db $04,$0A,$2A,$0B,$6C,$00,$2B,$04,$10,$2A,$0B,$6C,$00,$2C,$04,$0C
	db $6B,$0B,$72,$00,$2C,$04,$0E,$6B,$0B,$72,$00,$2D,$04,$08,$4C,$0B
	db $67,$00,$2D,$03,$0F,$4C,$0B,$67,$00,$4B,$44,$0D,$A6,$13,$26,$00
	db $4C,$43,$0B,$A6,$13,$26,$FF,$08,$08,$0B,$00,$10,$8D,$27,$0B,$FE
	db $8B,$1B,$0D,$01,$03,$30,$24,$2D,$1A,$0D,$2B,$03,$7A,$00,$30,$22
	db $06,$4C,$0B,$67,$00,$30,$20,$08,$4C,$0B,$67,$00,$30,$21,$10,$4C
	db $0B,$67,$00,$30,$21,$12,$4C,$0B,$67,$00,$2F,$20,$0A,$6B,$0B,$72
	db $00,$2F,$22,$08,$6B,$0B,$72,$00,$2F,$20,$10,$6B,$0B,$72,$00,$2E
	db $20,$0B,$2A,$0B,$6C,$00,$2E,$20,$0D,$2A,$0B,$6C,$B2,$09,$5A,$0D
	db $A6,$13,$24,$00,$4D,$60,$0C,$A6,$13,$26,$FF,$1F,$1F,$02,$01,$20
	db $00,$0E,$0C,$CE,$2E,$2B,$89,$26,$03,$40,$CE,$1B,$2C,$09,$29,$23
	db $44,$FE,$8C,$37,$03,$01,$03,$30,$FE,$46,$2C,$09,$01,$03,$30,$00
	db $4E,$68,$0A,$A6,$13,$26,$FF,$1D,$1D,$0C,$00,$03,$00,$0A,$0D,$00
	db $30,$56,$0F,$86,$DB,$28,$00,$32,$56,$0B,$86,$DB,$28,$00,$34,$58
	db $16,$86,$DB,$28,$00,$31,$57,$4F,$86,$59,$28,$00,$33,$57,$4B,$86
	db $59,$28,$00,$35,$59,$56,$86,$59,$28,$FE,$8D,$06,$11,$01,$04,$30
	db $25,$2F,$06,$11,$4C,$04,$7B,$FE,$8D,$19,$0F,$01,$01,$30,$00,$33
	db $17,$0A,$2B,$09,$76,$00,$33,$19,$17,$2B,$09,$76,$00,$33,$02,$16
	db $2B,$0C,$76,$00,$32,$04,$05,$4B,$0B,$69,$00,$32,$11,$05,$4B,$0B
	db $69,$00,$32,$0F,$1A,$4B,$0B,$69,$B3,$0A,$4A,$0E,$A6,$14,$24,$00
	db $4F,$42,$1A,$A6,$14,$26,$FF,$15,$15,$0D,$00,$10,$81,$47,$0E,$50
	db $30,$03,$32,$6E,$03,$2C,$50,$30,$03,$33,$6F,$03,$2C,$50,$30,$04
	db $32,$74,$03,$2C,$50,$30,$04,$33,$75,$03,$2C,$00,$35,$0D,$30,$4B
	db $0B,$E9,$00,$35,$0C,$31,$4B,$0B,$E9,$00,$35,$0D,$34,$4B,$0B,$E9
	db $00,$36,$10,$31,$4B,$0B,$E9,$00,$36,$10,$33,$4B,$0B,$E9,$00,$36
	db $0F,$34,$4B,$0B,$E9,$00,$37,$0E,$31,$2B,$0B,$F6,$00,$37,$0D,$32
	db $2B,$0B,$F6,$00,$37,$0E,$33,$2B,$0B,$F6,$00,$37,$0F,$32,$2B,$0B
	db $F6,$00,$38,$07,$2B,$2B,$09,$76,$00,$38,$0F,$30,$2B,$0B,$F6,$00
	db $38,$0C,$33,$2B,$0B,$F6,$B4,$0B,$50,$32,$A6,$13,$24,$00,$50,$4E
	db $30,$A6,$13,$26,$00,$51,$4C,$32,$A6,$13,$26,$00,$52,$4E,$34,$A6
	db $13,$26,$FF,$14,$14,$0D,$05,$32,$4B,$C7,$0E,$FE,$8E,$20,$15,$81
	db $03,$30,$00,$39,$18,$0D,$4B,$0B,$E9,$00,$39,$18,$0A,$4B,$0B,$E9
	db $00,$39,$07,$13,$4B,$0B,$E9,$00,$39,$18,$01,$4B,$0B,$E9,$00,$39
	db $15,$24,$4B,$0B,$E9,$00,$39,$1B,$29,$4B,$0B,$E9,$00,$3A,$0C,$0D
	db $2B,$0B,$F6,$00,$3A,$0B,$14,$2B,$0B,$F6,$00,$3A,$03,$13,$2B,$0B
	db $F6,$00,$3B,$08,$03,$2B,$0B,$F6,$00,$3B,$07,$1B,$2B,$0B,$F6,$00
	db $3B,$1B,$2F,$2B,$0B,$F6,$00,$3C,$1E,$03,$0C,$0B,$F1,$00,$3C,$12
	db $0B,$0C,$0B,$F1,$00,$3C,$13,$19,$0C,$0B,$F1,$00,$3C,$04,$1F,$0C
	db $0B,$F1,$00,$3C,$0C,$22,$0C,$0B,$F1,$B6,$0D,$5B,$36,$A6,$13,$24
	db $00,$53,$52,$24,$A6,$13,$26,$00,$54,$66,$05,$A6,$13,$26,$00,$55
	db $66,$06,$A6,$13,$26,$FF,$15,$15,$0E,$05,$32,$4C,$C7,$0E,$00,$3D
	db $0C,$11,$2B,$0B,$F6,$00,$3D,$0A,$18,$2B,$0B,$F6,$00,$3D,$15,$08
	db $2B,$0B,$F6,$00,$3D,$12,$0A,$2B,$0B,$F6,$00,$3E,$06,$13,$0C,$0B
	db $F1,$00,$3E,$1C,$08,$0C,$0B,$F1,$00,$3E,$17,$0B,$0C,$0B,$F1,$00
	db $3E,$15,$0E,$0C,$0B,$F1,$00,$3F,$02,$1A,$4C,$0B,$ED,$00,$3F,$1C
	db $0E,$4C,$0B,$ED,$00,$3F,$17,$11,$4C,$0B,$ED,$00,$3F,$19,$14,$4C
	db $0B,$ED,$00,$40,$04,$0A,$6B,$0B,$FA,$00,$40,$0A,$0C,$6B,$0B,$FA
	db $00,$40,$19,$17,$6B,$0B,$FA,$00,$40,$1C,$1A,$6B,$0B,$FA,$00,$56
	db $4F,$0D,$A6,$13,$26,$00,$57,$4E,$09,$A6,$13,$26,$00,$58,$40,$1A
	db $A6,$13,$26,$00,$59,$4C,$20,$A6,$13,$26,$00,$5A,$44,$0D,$A6,$13
	db $26,$00,$5B,$57,$21,$A6,$13,$26,$FF,$14,$14,$0F,$05,$32,$4D,$C7
	db $0E,$00,$41,$2B,$0D,$4B,$0B,$E9,$00,$41,$2A,$17,$4B,$0B,$E9,$00
	db $41,$3B,$0D,$4B,$0B,$E9,$00,$42,$31,$08,$2C,$0B,$ED,$00,$42,$2B
	db $1B,$2C,$0B,$ED,$00,$42,$3E,$1D,$2C,$0B,$ED,$00,$42,$34,$1A,$2C
	db $0B,$ED,$00,$42,$3A,$0F,$2C,$0B,$ED,$00,$43,$35,$0D,$2B,$0B,$EF
	db $00,$43,$2B,$21,$2B,$0B,$EF,$00,$43,$3E,$1F,$2B,$0B,$EF,$00,$43
	db $3A,$1A,$2B,$0B,$EF,$00,$44,$39,$08,$6C,$0B,$FB,$00,$44,$39,$21
	db $6C,$0B,$FB,$00,$44,$30,$20,$6C,$0B,$FB,$00,$44,$3A,$16,$6C,$0B
	db $FB,$00,$5C,$71,$10,$A6,$13,$26,$00,$5D,$73,$10,$A6,$13,$26,$00
	db $5E,$78,$13,$A6,$13,$26,$00,$5F,$78,$15,$A6,$13,$26,$00,$60,$6F
	db $1F,$A6,$13,$26,$00,$61,$7C,$21,$A6,$13,$26,$FF,$14,$14,$0F,$05
	db $32,$4E,$C7,$0E,$00,$45,$0E,$2E,$0C,$0B,$F1,$00,$45,$0E,$30,$0C
	db $0B,$F1,$00,$45,$04,$2A,$0C,$0B,$F1,$00,$46,$0D,$2D,$2B,$0B,$EF
	db $00,$46,$0D,$2F,$2B,$0B,$EF,$00,$46,$0D,$31,$2B,$0B,$EF,$00,$47
	db $16,$3E,$0B,$0B,$EB,$00,$47,$0E,$38,$0B,$0B,$EB,$00,$47,$0E,$3A
	db $0B,$0B,$EB,$00,$48,$0D,$37,$8B,$0B,$FA,$00,$48,$0D,$39,$8B,$0B
	db $FA,$00,$48,$0D,$3B,$8B,$0B,$FA,$B5,$0C,$48,$38,$A6,$13,$24,$00
	db $62,$48,$2E,$A6,$13,$26,$00,$63,$4D,$2E,$A6,$13,$26,$00,$64,$4D
	db $30,$A6,$13,$26,$00,$65,$51,$32,$A6,$13,$26,$00,$66,$51,$36,$A6
	db $13,$26,$00,$67,$4D,$38,$A6,$13,$26,$00,$68,$4D,$3A,$A6,$13,$26
	db $FF,$14,$14,$0F,$05,$72,$4F,$C7,$0E,$00,$49,$3C,$39,$2C,$0B,$ED
	db $00,$4A,$36,$31,$2B,$0B,$EF,$00,$4B,$3C,$30,$0B,$0B,$EB,$00,$4B
	db $36,$2D,$0B,$0B,$EB,$00,$4C,$37,$25,$6C,$0B,$FB,$00,$4C,$34,$2F
	db $6C,$0B,$FB,$00,$69,$6F,$26,$A6,$13,$26,$00,$6A,$75,$25,$A6,$13
	db $26,$00,$6B,$7C,$29,$A6,$13,$26,$00,$6C,$7C,$2B,$A6,$13,$26,$00
	db $6D,$6F,$28,$A6,$13,$26,$00,$6E,$6E,$30,$A6,$13,$26,$FF,$14,$14
	db $0F,$00,$10,$00,$07,$0E,$00,$4D,$39,$03,$2B,$0B,$6F,$00,$4D,$39
	db $05,$2B,$0B,$6F,$00,$4E,$38,$04,$0B,$0B,$6B,$00,$4E,$2F,$04,$0B
	db $09,$6B,$FF,$14,$14,$11,$00,$52,$40,$C7,$0E,$FE,$8E,$20,$F5,$01
	db $03,$30,$07,$31,$1E,$35,$6E,$03,$AC,$07,$31,$1E,$36,$6F,$03,$AC
	db $07,$31,$1F,$35,$74,$03,$AC,$07,$31,$1F,$36,$75,$03,$AC,$B7,$0E
	db $5E,$34,$A6,$13,$24,$02,$37,$5D,$36,$8A,$1F,$29,$02,$36,$1E,$36
	db $FA,$3B,$28,$FF,$1B,$1B,$10,$C0,$40,$00,$AA,$0F,$FE,$7C,$37,$30
	db $21,$07,$40,$F4,$AA,$B8,$B0,$6A,$02,$2C,$FF,$1B,$1B,$10,$C0,$40
	db $00,$AE,$0F,$52,$32,$B1,$D7,$6A,$02,$2C,$FE,$8F,$31,$56,$81,$02
	db $30,$FE,$90,$2A,$90,$21,$02,$40,$FE,$A4,$B8,$0F,$0C,$04,$50,$00
	db $6F,$6F,$1B,$A6,$12,$26,$FF,$1F,$1F,$10,$C1,$60,$40,$2E,$0F,$FE
	db $A5,$9C,$E8,$0C,$03,$50,$B8,$0F,$44,$12,$A6,$13,$24,$00,$DD,$5C
	db $24,$46,$3B,$28,$FF,$1F,$1F,$02,$01,$20,$00,$0E,$10,$C6,$33,$17
	db $82,$26,$03,$40,$C6,$1B,$18,$02,$29,$23,$44,$00,$70,$57,$07,$A6
	db $13,$26,$00,$71,$56,$09,$A6,$13,$26,$00,$72,$5D,$0D,$A6,$13,$26
	db $00,$73,$5B,$10,$A6,$13,$26,$FF,$05,$05,$12,$5C,$60,$00,$71,$11
	db $00,$35,$19,$0F,$42,$03,$64,$00,$36,$08,$90,$45,$03,$60,$00,$37
	db $10,$58,$41,$03,$6C,$00,$38,$0D,$C7,$41,$03,$68,$DE,$F0,$52,$0C
	db $66,$39,$2A,$00,$74,$5B,$18,$86,$11,$26,$00,$38,$86,$13,$A8,$1F
	db $28,$00,$39,$86,$54,$A8,$1F,$28,$FF,$1E,$1E,$12,$01,$60,$60,$11
	db $12,$00,$39,$A8,$62,$4A,$03,$6C,$5F,$3A,$A7,$A3,$0C,$03,$30,$37
	db $3B,$A6,$9B,$2A,$03,$40,$00,$75,$67,$24,$86,$13,$26,$FF,$1E,$1E
	db $13,$01,$60,$60,$11,$11,$00,$3C,$B6,$FA,$2A,$03,$50,$53,$3D,$AC
	db $CA,$0A,$03,$30,$80,$3E,$AE,$4D,$0A,$03,$30,$80,$3F,$AE,$CF,$2A
	db $03,$54,$F4,$AB,$A7,$8F,$AC,$04,$40,$00,$40,$04,$86,$41,$03,$6C
	db $00,$41,$B2,$89,$4A,$03,$6C,$00,$41,$33,$09,$16,$07,$5C,$00,$42
	db $B1,$97,$4A,$03,$68,$00,$43,$AE,$13,$4B,$03,$64,$00,$44,$A8,$8E
	db $4A,$03,$6C,$00,$3B,$24,$0F,$77,$1C,$29,$00,$3C,$65,$0F,$72,$1C
	db $29,$00,$3D,$65,$10,$73,$1C,$29,$00,$3E,$25,$0E,$78,$1C,$29,$00
	db $3F,$25,$11,$79,$1C,$29,$00,$40,$66,$0E,$74,$1C,$29,$00,$41,$66
	db $11,$75,$1C,$29,$FF,$09,$09,$14,$72,$6D,$20,$2A,$13,$00,$48,$09
	db $21,$9B,$07,$28,$00,$49,$20,$0B,$9B,$07,$28,$00,$4A,$26,$23,$9B
	db $07,$28,$00,$4B,$2A,$3B,$9B,$07,$28,$00,$42,$0E,$1F,$9A,$1F,$29
	db $00,$43,$25,$09,$9A,$1F,$29,$00,$44,$29,$21,$9A,$1F,$29,$00,$45
	db $2F,$39,$9A,$1F,$29,$26,$47,$1E,$3A,$0C,$03,$7C,$00,$50,$18,$16
	db $2B,$0B,$68,$00,$50,$1A,$20,$2B,$0B,$68,$00,$50,$26,$28,$2B,$0B
	db $68,$00,$50,$2E,$08,$2B,$0B,$68,$00,$50,$34,$1B,$2B,$0B,$68,$00
	db $51,$0F,$0A,$4B,$0B,$66,$00,$51,$10,$1D,$4B,$0B,$66,$00,$51,$14
	db $38,$4B,$0B,$66,$00,$51,$0C,$33,$4B,$0B,$66,$00,$51,$19,$33,$4B
	db $0B,$66,$00,$51,$10,$1B,$4B,$0B,$66,$FF,$21,$21,$15,$72,$26,$00
	db $0A,$13,$00,$53,$2F,$04,$0B,$09,$64,$00,$53,$2F,$09,$0B,$09,$64
	db $00,$53,$3B,$15,$0B,$09,$64,$00,$53,$12,$32,$0B,$0B,$64,$00,$53
	db $13,$3B,$0B,$0B,$64,$00,$54,$32,$04,$0B,$09,$60,$00,$54,$32,$09
	db $0B,$09,$60,$00,$54,$3B,$18,$0B,$09,$60,$00,$54,$0F,$30,$0B,$0B
	db $60,$00,$54,$11,$3C,$0B,$0B,$60,$00,$55,$35,$04,$2B,$09,$68,$00
	db $55,$35,$09,$2B,$09,$68,$00,$55,$38,$1A,$2B,$09,$68,$00,$55,$06
	db $3C,$2B,$0B,$68,$00,$56,$38,$04,$4B,$09,$66,$00,$56,$38,$09,$4B
	db $09,$66,$00,$56,$2E,$17,$4B,$09,$66,$00,$56,$08,$37,$4B,$09,$66
	db $B9,$10,$6E,$14,$A6,$11,$24,$00,$76,$45,$3E,$A6,$13,$26,$00,$77
	db $7A,$04,$A6,$11,$26,$00,$78,$7A,$09,$A6,$11,$26,$FF,$0A,$0A,$12
	db $70,$00,$60,$8A,$13,$FE,$91,$07,$CF,$04,$03,$30,$DF,$92,$86,$D3
	db $2A,$03,$40,$00,$79,$47,$08,$86,$13,$26,$00,$7A,$45,$0C,$86,$13
	db $26,$00,$7B,$45,$0E,$86,$13,$26,$00,$7C,$48,$0D,$86,$13,$26,$36
	db $46,$46,$15,$60,$1B,$2C,$36,$47,$46,$16,$64,$1B,$2C,$36,$48,$47
	db $16,$65,$1B,$2C,$36,$49,$47,$15,$61,$1B,$2C,$FF,$1F,$1F,$02,$01
	db $20,$00,$0E,$14,$C7,$4C,$26,$B9,$26,$03,$40,$C7,$1B,$27,$39,$29
	db $23,$44,$00,$7D,$63,$35,$A6,$13,$26,$00,$7E,$63,$3C,$A6,$13,$26
	db $FF,$0B,$0B,$16,$90,$04,$60,$88,$15,$00,$57,$10,$2B,$8B,$0B,$66
	db $00,$57,$0B,$10,$8B,$0B,$66,$00,$57,$08,$20,$8B,$09,$66,$00,$58
	db $15,$12,$2C,$09,$6E,$00,$58,$0B,$14,$2C,$0B,$6E,$00,$58,$0D,$23
	db $2C,$09,$6E,$00,$59,$0F,$05,$6A,$09,$6C,$00,$59,$06,$14,$6A,$0B
	db $6C,$00,$59,$0A,$25,$6A,$0B,$6C,$00,$5A,$0C,$05,$0B,$09,$74,$00
	db $5A,$08,$1A,$0B,$09,$74,$00,$5A,$14,$2B,$0B,$0B,$74,$BA,$11,$4A
	db $12,$A6,$11,$24,$00,$7F,$49,$05,$A6,$11,$26,$00,$80,$57,$24,$A6
	db $13,$26,$00,$81,$57,$26,$A6,$13,$26,$FF,$0A,$0A,$16,$90,$04,$60
	db $88,$15,$27,$4D,$06,$2C,$4A,$03,$7D,$00,$5B,$15,$25,$2C,$09,$6E
	db $00,$5B,$06,$2F,$2C,$0B,$6E,$00,$5B,$11,$32,$2C,$0B,$6E,$00,$5B
	db $17,$34,$2C,$09,$6E,$00,$5C,$0C,$21,$6A,$09,$6C,$00,$5C,$06,$29
	db $6A,$0B,$6C,$00,$5C,$0E,$33,$6A,$0B,$6C,$00,$5C,$14,$36,$6A,$09
	db $6C,$00,$5D,$11,$25,$0B,$0B,$74,$00,$5D,$0C,$2B,$0B,$0B,$74,$00
	db $5D,$0B,$34,$0B,$0B,$74,$00,$5D,$10,$36,$0B,$09,$74,$BB,$12,$4E
	db $24,$A6,$13,$24,$00,$82,$4A,$24,$A6,$11,$26,$00,$83,$49,$34,$A6
	db $13,$26,$00,$84,$4B,$37,$A6,$11,$26,$FF,$8A,$0A,$17,$90,$45,$20
	db $48,$15,$00,$5F,$19,$08,$6A,$0B,$6C,$00,$5F,$27,$05,$6A,$09,$6C
	db $00,$5F,$21,$28,$6A,$0B,$6C,$00,$60,$1F,$0B,$2B,$09,$74,$00,$60
	db $20,$37,$2B,$09,$74,$00,$60,$25,$2B,$2B,$09,$74,$00,$85,$5A,$12
	db $A6,$13,$26,$00,$86,$62,$2D,$A6,$13,$26,$00,$87,$61,$31,$A6,$11
	db $26,$FF,$16,$16,$33,$82,$65,$20,$68,$16,$00,$61,$06,$26,$2C,$0B
	db $6D,$00,$61,$06,$12,$2C,$0B,$6D,$00,$61,$18,$1A,$2C,$08,$6D,$00
	db $61,$18,$29,$2C,$0B,$6D,$00,$62,$0A,$2D,$8A,$0B,$6A,$00,$62,$0D
	db $0B,$8A,$0B,$6A,$00,$62,$0E,$19,$8A,$0B,$6A,$00,$62,$0A,$00,$8A
	db $0B,$6A,$00,$63,$12,$26,$6B,$0B,$77,$00,$63,$11,$06,$6B,$0B,$77
	db $00,$63,$15,$11,$6B,$0B,$77,$00,$63,$06,$3B,$6B,$0B,$77,$00,$64
	db $0D,$20,$0C,$0B,$7C,$00,$64,$18,$05,$0C,$0B,$7C,$00,$64,$06,$35
	db $0C,$0B,$7C,$00,$64,$16,$23,$0C,$0B,$7C,$00,$88,$5A,$0F,$A6,$13
	db $26,$00,$89,$56,$2E,$A6,$13,$26,$00,$8A,$4C,$21,$A6,$13,$26,$00
	db $8B,$5A,$30,$A6,$13,$26,$FF,$18,$18,$18,$82,$66,$20,$88,$16,$00
	db $6E,$0C,$24,$0C,$0B,$6D,$00,$6E,$0F,$32,$0C,$09,$6D,$00,$6E,$04
	db $28,$0C,$0B,$6D,$00,$6E,$0C,$2D,$0C,$0B,$6D,$00,$6D,$1C,$30,$2A
	db $09,$6A,$00,$6D,$08,$3A,$2A,$0B,$6A,$00,$6D,$0F,$20,$2A,$09,$6A
	db $00,$6D,$11,$39,$2A,$0B,$6A,$00,$6F,$14,$30,$4B,$09,$64,$00,$6F
	db $1B,$27,$4B,$0B,$64,$00,$6F,$14,$28,$4B,$0B,$64,$00,$6F,$17,$34
	db $4B,$0B,$64,$00,$8C,$4C,$22,$A6,$13,$26,$00,$F6,$5B,$2C,$A6,$13
	db $26,$00,$F7,$46,$38,$A6,$11,$26,$00,$F8,$4F,$2D,$A6,$11,$26,$00
	db $F9,$55,$2F,$A6,$11,$26,$00,$FA,$5C,$2F,$A6,$11,$26,$00,$51,$4A
	db $36,$8C,$19,$2A,$00,$52,$4A,$37,$8C,$19,$2A,$00,$53,$4F,$2B,$8C
	db $19,$2A,$00,$54,$54,$38,$8C,$19,$2A,$FF,$18,$18,$19,$82,$66,$20
	db $88,$16,$00,$78,$0D,$04,$4B,$0B,$72,$00,$78,$19,$08,$4B,$0B,$72
	db $00,$78,$0C,$13,$4B,$09,$72,$00,$78,$1A,$11,$4B,$09,$72,$00,$78
	db $14,$14,$4B,$0B,$72,$00,$79,$14,$08,$0B,$0B,$64,$00,$79,$0A,$0B
	db $0B,$09,$64,$00,$79,$17,$06,$0B,$09,$64,$00,$79,$17,$0A,$0B,$09
	db $64,$00,$79,$04,$17,$0B,$0B,$64,$00,$7A,$12,$0C,$2A,$0B,$7D,$00
	db $7A,$0A,$04,$2A,$09,$7D,$00,$7A,$0F,$0A,$2A,$09,$7D,$00,$7A,$0D
	db $07,$2A,$0B,$7D,$00,$7A,$06,$09,$2A,$0B,$7D,$00,$8D,$46,$04,$A6
	db $11,$26,$00,$8E,$48,$04,$A6,$11,$26,$00,$8F,$51,$0C,$A6,$13,$26
	db $00,$90,$59,$05,$A6,$13,$26,$FF,$17,$17,$0F,$82,$66,$20,$88,$16
	db $00,$70,$10,$03,$8A,$09,$6A,$00,$70,$0D,$07,$8A,$09,$6A,$00,$70
	db $0F,$11,$8A,$0B,$6A,$00,$70,$05,$09,$8A,$0B,$6A,$00,$71,$0A,$08
	db $8C,$09,$70,$00,$71,$0C,$08,$8C,$09,$70,$00,$71,$0A,$11,$8C,$0B
	db $70,$00,$71,$04,$0A,$8C,$0B,$70,$00,$72,$0B,$09,$6B,$09,$77,$00
	db $72,$0D,$09,$6B,$09,$77,$00,$72,$07,$0C,$6B,$0B,$77,$00,$72,$06
	db $0D,$6B,$0B,$77,$00,$73,$0B,$07,$0C,$09,$7C,$00,$73,$0E,$08,$0C
	db $09,$7C,$00,$73,$07,$0D,$0C,$0B,$7C,$00,$73,$04,$09,$0C,$0B,$7C
	db $BC,$13,$44,$08,$A6,$13,$24,$00,$91,$46,$0C,$A6,$13,$26,$00,$92
	db $4B,$08,$A6,$11,$26,$00,$93,$4D,$08,$A6,$11,$26,$FF,$17,$17,$1A
	db $82,$66,$20,$88,$16,$00,$74,$19,$2B,$6C,$09,$70,$00,$74,$08,$22
	db $6C,$0B,$70,$00,$74,$0C,$37,$6C,$0B,$70,$00,$75,$09,$1C,$4B,$0B
	db $72,$00,$75,$08,$31,$4B,$0B,$72,$00,$75,$1B,$32,$4B,$09,$72,$00
	db $76,$03,$1D,$0C,$0B,$7C,$00,$76,$14,$38,$0C,$09,$7C,$00,$76,$0F
	db $22,$0C,$0B,$7C,$00,$77,$03,$26,$2A,$0B,$7D,$00,$77,$10,$23,$2A
	db $0B,$7D,$00,$77,$14,$30,$2A,$0B,$7D,$00,$5C,$4D,$25,$8C,$1B,$28
	db $00,$5D,$4E,$23,$8C,$1B,$28,$00,$5E,$50,$22,$8C,$1B,$28,$00,$5F
	db $51,$20,$8C,$1B,$28,$C5,$1C,$54,$2F,$A6,$13,$24,$00,$94,$44,$27
	db $A6,$13,$26,$00,$95,$44,$29,$A6,$13,$26,$00,$96,$45,$33,$A6,$13
	db $26,$FF,$17,$17,$33,$82,$66,$20,$88,$16,$00,$65,$29,$2C,$2C,$0B
	db $6D,$00,$65,$22,$32,$2C,$0B,$6D,$00,$65,$24,$32,$2C,$0B,$6D,$00
	db $65,$38,$24,$2C,$09,$6D,$00,$66,$26,$2F,$8A,$0B,$6A,$00,$66,$21
	db $31,$8A,$0B,$6A,$00,$66,$25,$31,$8A,$0B,$6A,$00,$66,$34,$23,$8A
	db $09,$6A,$00,$67,$23,$31,$6B,$0B,$77,$00,$67,$20,$32,$6B,$0B,$77
	db $00,$67,$35,$32,$6B,$0B,$77,$00,$67,$35,$1F,$6B,$09,$77,$00,$68
	db $23,$33,$4A,$0B,$7D,$00,$68,$26,$32,$4A,$0B,$7D,$00,$68,$20,$1E
	db $4A,$0B,$7D,$00,$68,$30,$1E,$4A,$09,$7D,$00,$97,$72,$23,$A6,$11
	db $26,$00,$98,$61,$32,$A6,$13,$26,$00,$99,$63,$34,$A6,$13,$26,$00
	db $9A,$65,$32,$A6,$13,$26,$FF,$17,$17,$0F,$80,$06,$00,$08,$16,$00
	db $69,$18,$3E,$8A,$0B,$6A,$00,$6A,$19,$04,$8C,$0B,$70,$00,$6B,$1A
	db $0B,$4B,$0B,$72,$00,$6C,$1B,$10,$0C,$0B,$7C,$00,$9B,$4C,$13,$A6
	db $11,$26,$00,$9C,$4C,$14,$A6,$11,$26,$00,$9D,$4C,$18,$A6,$11,$26
	db $00,$9E,$4C,$19,$A6,$11,$26,$FF,$17,$17,$1B,$82,$66,$20,$88,$16
	db $FE,$94,$23,$0E,$04,$03,$30,$08,$4E,$21,$0D,$6E,$03,$2C,$08,$4E
	db $21,$0E,$72,$03,$2C,$08,$4E,$22,$0D,$70,$03,$2C,$08,$4E,$22,$0E
	db $73,$03,$2C,$03,$61,$5F,$0E,$8A,$1B,$29,$03,$60,$20,$0E,$FA,$3B
	db $28,$00,$7B,$32,$0E,$2B,$0B,$64,$00,$7B,$28,$07,$2B,$0B,$64,$00
	db $7C,$36,$1A,$4A,$0B,$7D,$00,$7C,$2B,$05,$4A,$0B,$7D,$BD,$14,$60
	db $0C,$A6,$13,$24,$00,$9F,$60,$02,$A6,$13,$26,$00,$A0,$79,$19,$A6
	db $13,$26,$FF,$17,$17,$1B,$82,$20,$00,$08,$16,$00,$A1,$58,$06,$A6
	db $13,$26,$00,$A2,$58,$07,$A6,$13,$26,$FF,$0C,$0C,$1C,$00,$1B,$60
	db $69,$D7,$FE,$95,$0C,$CD,$04,$03,$50,$FE,$96,$09,$DA,$21,$03,$40
	db $FE,$97,$0A,$0A,$6B,$0B,$68,$00,$A3,$5A,$1B,$A6,$13,$26,$00,$A4
	db $5A,$28,$A6,$13,$26,$FF,$07,$07,$1C,$01,$74,$20,$AD,$18,$FE,$98
	db $2B,$2A,$21,$03,$40,$FE,$99,$2B,$2A,$41,$03,$30,$3A,$4F,$2A,$2A
	db $16,$07,$28,$00,$7F,$0A,$0A,$6B,$0B,$68,$00,$7F,$17,$0F,$6B,$0B
	db $68,$00,$7F,$3A,$1E,$6B,$0B,$68,$00,$7F,$34,$17,$6B,$0B,$68,$00
	db $7F,$32,$23,$6B,$0B,$68,$00,$7F,$28,$23,$6B,$0B,$68,$00,$7F,$2F
	db $34,$6B,$0B,$68,$00,$7F,$35,$23,$6B,$0B,$68,$00,$80,$20,$0F,$8C
	db $0B,$6E,$00,$80,$2D,$0F,$8C,$0B,$6E,$00,$80,$2B,$24,$8C,$0B,$6E
	db $00,$80,$0A,$07,$8C,$0B,$6E,$00,$80,$30,$08,$8C,$0B,$6E,$00,$80
	db $38,$1F,$8C,$0B,$6E,$00,$80,$25,$34,$8C,$0B,$6E,$BE,$15,$7A,$1B
	db $A6,$13,$24,$00,$A5,$44,$07,$A6,$13,$26,$00,$A6,$68,$07,$A6,$13
	db $26,$00,$A7,$63,$34,$A6,$13,$26,$FF,$0D,$0D,$1D,$00,$07,$0B,$0D
	db $19,$28,$81,$16,$12,$0B,$0A,$68,$28,$81,$15,$15,$0B,$0A,$68,$28
	db $81,$1A,$1A,$0B,$0A,$68,$28,$82,$12,$08,$4C,$0A,$6E,$28,$82,$14
	db $14,$4C,$0A,$6E,$28,$82,$17,$1E,$4C,$08,$6E,$28,$83,$15,$0F,$4A
	db $0A,$61,$28,$83,$0B,$19,$4A,$0A,$61,$28,$83,$07,$19,$4A,$0C,$61
	db $28,$83,$12,$05,$4A,$0A,$61,$28,$83,$0F,$13,$4A,$0A,$61,$28,$83
	db $12,$1C,$4A,$0A,$61,$00,$A8,$4A,$05,$A6,$12,$26,$00,$A9,$55,$05
	db $A6,$12,$26,$00,$AA,$4F,$11,$A6,$12,$26,$00,$AB,$52,$19,$A6,$12
	db $26,$00,$62,$4D,$1B,$86,$9C,$28,$00,$63,$54,$19,$86,$9C,$28,$00
	db $64,$58,$10,$86,$9C,$28,$00,$65,$4E,$06,$86,$9C,$28,$00,$66,$45
	db $10,$86,$9C,$28,$00,$67,$46,$19,$86,$9C,$28,$FF,$0D,$0D,$1D,$00
	db $47,$6C,$2D,$19,$28,$84,$33,$25,$4A,$0A,$61,$28,$84,$2E,$33,$4A
	db $0A,$61,$28,$84,$30,$2E,$4A,$0A,$61,$28,$85,$34,$2A,$2B,$0A,$73
	db $28,$85,$37,$35,$2B,$0A,$73,$28,$85,$30,$36,$2B,$0A,$73,$28,$85
	db $2A,$28,$2B,$0C,$73,$28,$85,$29,$37,$2B,$0A,$73,$28,$85,$2B,$3A
	db $2B,$0A,$73,$28,$86,$37,$37,$6C,$0A,$63,$28,$86,$31,$38,$6C,$0A
	db $63,$28,$86,$30,$28,$6C,$0C,$63,$28,$86,$31,$2C,$6C,$0C,$63,$28
	db $86,$35,$24,$6C,$0C,$63,$BF,$16,$6B,$3B,$A6,$12,$24,$00,$AC,$69
	db $39,$A6,$12,$26,$00,$AD,$77,$39,$A6,$12,$26,$00,$AE,$77,$24,$A6
	db $14,$26,$00,$68,$6F,$24,$86,$9A,$28,$00,$69,$6B,$27,$86,$9C,$28
	db $00,$6A,$70,$2B,$86,$9C,$28,$00,$6B,$69,$24,$86,$9A,$28,$FF,$0E
	db $0E,$1D,$00,$07,$0C,$0D,$19,$28,$87,$10,$30,$6C,$0A,$63,$28,$87
	db $0F,$2D,$6C,$0A,$63,$28,$87,$07,$2A,$6C,$0A,$63,$28,$87,$08,$33
	db $6C,$0A,$63,$28,$87,$08,$37,$6C,$0A,$63,$28,$87,$0B,$2C,$6C,$0A
	db $63,$00,$AF,$4A,$29,$A6,$12,$26,$00,$B0,$4A,$2A,$A6,$12,$26,$FF
	db $0E,$0E,$1D,$00,$47,$6D,$2D,$19,$28,$88,$29,$37,$2B,$0A,$73,$28
	db $88,$33,$38,$2B,$0A,$73,$28,$88,$3A,$2D,$2B,$0A,$73,$28,$88,$32
	db $20,$2B,$0A,$73,$28,$89,$26,$23,$6C,$0C,$63,$28,$89,$32,$22,$6C
	db $0A,$63,$28,$89,$39,$2B,$6C,$0A,$63,$28,$89,$3A,$23,$6C,$0A,$63
	db $28,$8A,$1A,$34,$6B,$0A,$65,$28,$8A,$38,$39,$6B,$0C,$65,$28,$8A
	db $3B,$36,$6B,$0C,$65,$28,$8A,$3D,$31,$6B,$0C,$65,$28,$8A,$2C,$23
	db $6B,$0C,$65,$28,$8A,$36,$2C,$6B,$0C,$65,$28,$8A,$36,$30,$6B,$0C
	db $65,$28,$8A,$3B,$25,$6B,$0A,$65,$00,$B1,$72,$2B,$A6,$12,$26,$00
	db $B2,$75,$29,$A6,$12,$26,$00,$B3,$72,$30,$A6,$14,$26,$00,$B4,$7C
	db $26,$A6,$12,$26,$00,$6C,$6C,$29,$86,$9C,$28,$00,$6D,$76,$26,$86
	db $9C,$28,$FF,$0D,$0D,$1D,$00,$07,$0D,$0D,$19,$28,$8B,$29,$04,$6B
	db $0A,$65,$28,$8B,$2C,$04,$6B,$0A,$65,$28,$8B,$27,$0A,$6B,$0C,$65
	db $28,$8B,$2B,$10,$6B,$0C,$65,$28,$8B,$36,$0B,$6B,$0C,$65,$28,$8B
	db $37,$0D,$6B,$0C,$65,$28,$8B,$39,$0E,$6B,$0C,$65,$28,$8B,$39,$10
	db $6B,$0C,$65,$28,$8B,$38,$12,$6B,$0C,$65,$28,$8B,$38,$16,$6B,$0C
	db $65,$28,$8B,$32,$13,$6B,$0C,$65,$28,$8B,$33,$14,$6B,$0C,$65,$00
	db $B5,$68,$10,$A6,$14,$26,$00,$B6,$6E,$0F,$A6,$14,$26,$FF,$0E,$0E
	db $1E,$00,$47,$6E,$2D,$19,$28,$8C,$13,$06,$4B,$0C,$65,$28,$8C,$09
	db $0F,$4B,$0C,$65,$28,$8C,$12,$0F,$4B,$0E,$65,$28,$8D,$07,$0F,$2C
	db $0A,$62,$28,$8D,$16,$17,$2C,$0A,$62,$28,$8D,$1D,$11,$2C,$0C,$62
	db $28,$8D,$1B,$13,$2C,$0C,$62,$28,$8D,$0E,$06,$2C,$0C,$62,$28,$8D
	db $0B,$14,$2C,$0C,$62,$28,$8D,$0B,$0C,$2C,$0E,$62,$28,$8E,$16,$04
	db $0B,$0A,$66,$28,$8E,$0D,$17,$0B,$0A,$66,$28,$8E,$1A,$16,$0B,$0A
	db $66,$28,$8E,$0B,$08,$0B,$0C,$66,$28,$8E,$16,$0F,$0B,$0C,$66,$28
	db $8E,$0C,$09,$0B,$0E,$66,$00,$B7,$4F,$08,$A6,$16,$26,$00,$B8,$50
	db $08,$A6,$16,$26,$00,$B9,$5B,$15,$A6,$14,$26,$00,$BA,$5D,$13,$A6
	db $14,$26,$00,$6E,$55,$10,$86,$9C,$28,$00,$6F,$5C,$12,$86,$9C,$28
	db $FF,$0D,$0D,$1E,$00,$07,$0E,$0D,$19,$28,$8F,$0A,$2B,$2C,$0C,$62
	db $28,$8F,$09,$32,$2C,$0C,$62,$28,$8F,$10,$34,$2C,$0A,$62,$28,$8F
	db $08,$34,$2C,$0A,$62,$28,$8F,$12,$28,$2C,$0A,$62,$28,$8F,$0A,$38
	db $2C,$0A,$62,$28,$8F,$18,$37,$2C,$0A,$62,$28,$8F,$08,$3A,$2C,$0A
	db $62,$00,$BB,$4B,$2B,$A6,$14,$26,$00,$BC,$49,$38,$A6,$12,$26,$FF
	db $0E,$0E,$1F,$00,$47,$6F,$2D,$19,$7B,$50,$25,$0E,$16,$04,$2C,$28
	db $51,$28,$0E,$2D,$04,$7F,$28,$90,$2D,$08,$4B,$0A,$66,$28,$90,$30
	db $07,$4B,$0A,$66,$28,$90,$34,$09,$4B,$0A,$66,$28,$90,$38,$09,$4B
	db $0A,$66,$28,$90,$34,$0C,$4B,$0A,$66,$28,$90,$34,$10,$4B,$0A,$66
	db $28,$90,$2E,$0C,$4B,$0A,$66,$00,$BD,$6B,$05,$A6,$12,$26,$00,$BE
	db $6B,$07,$A6,$12,$26,$00,$BF,$79,$0C,$A6,$12,$26,$00,$C0,$79,$0F
	db $A6,$12,$26,$00,$70,$6A,$14,$86,$9A,$28,$FF,$0F,$0F,$1F,$00,$00
	db $6F,$AD,$19,$FE,$9B,$0A,$4A,$01,$01,$30,$FF,$1F,$1F,$02,$01,$20
	db $00,$0E,$1A,$C8,$52,$35,$A9,$26,$03,$40,$C8,$1B,$36,$29,$29,$23
	db $44,$00,$C1,$68,$29,$A6,$13,$26,$FF,$1B,$1B,$02,$01,$20,$00,$AE
	db $1B,$00,$C2,$54,$0A,$A6,$13,$26,$FF,$10,$10,$20,$00,$04,$60,$89
	db $1C,$2A,$54,$17,$22,$6B,$03,$7E,$00,$92,$27,$1C,$0B,$0B,$66,$00
	db $92,$2D,$38,$0B,$0B,$66,$00,$93,$33,$23,$4B,$0B,$69,$00,$93,$1F
	db $1F,$4B,$0B,$69,$00,$93,$14,$28,$4B,$0B,$69,$00,$93,$0A,$25,$4B
	db $0B,$69,$00,$94,$29,$2A,$2C,$0B,$70,$00,$94,$1C,$28,$2C,$0B,$70
	db $00,$94,$07,$2C,$2C,$0B,$70,$00,$95,$22,$13,$2C,$0B,$70,$00,$95
	db $22,$33,$2C,$0B,$70,$C0,$17,$46,$2B,$A6,$13,$24,$00,$C3,$60,$33
	db $A6,$13,$26,$00,$C4,$60,$13,$A6,$13,$26,$00,$71,$4D,$27,$86,$9B
	db $28,$00,$72,$53,$1F,$86,$9B,$28,$00,$73,$5B,$18,$86,$9B,$28,$00
	db $74,$55,$18,$86,$9B,$28,$00,$75,$63,$2E,$86,$9B,$28,$00,$76,$63
	db $33,$86,$9B,$28,$00,$77,$70,$14,$86,$9B,$28,$FF,$04,$04,$21,$30
	db $00,$60,$72,$1D,$00,$55,$0D,$87,$41,$03,$68,$00,$56,$24,$8B,$41
	db $03,$6C,$2B,$57,$15,$90,$42,$03,$64,$2B,$58,$19,$88,$40,$03,$74
	db $2B,$59,$1D,$91,$40,$05,$70,$00,$78,$5A,$12,$86,$1D,$2D,$2B,$5A
	db $5B,$52,$86,$05,$2D,$2A,$5A,$5B,$12,$8B,$05,$2D,$00,$7A,$62,$15
	db $86,$1D,$2D,$2B,$7B,$63,$55,$86,$1D,$2D,$2A,$7C,$63,$15,$8B,$1D
	db $2D,$00,$7D,$50,$06,$66,$9B,$28,$00,$7E,$50,$0E,$66,$9B,$28,$00
	db $7F,$5E,$13,$66,$9D,$28,$00,$80,$5E,$1A,$66,$9D,$28,$00,$81,$5E
	db $12,$A6,$1F,$2A,$3D,$82,$43,$15,$19,$3B,$2B,$3D,$83,$44,$15,$19
	db $3B,$2B,$3D,$84,$45,$15,$19,$3B,$2B,$3D,$85,$46,$15,$19,$3B,$2B
	db $3D,$86,$47,$15,$19,$3B,$2B,$3D,$87,$48,$15,$19,$3B,$2B,$FF,$1E
	db $1E,$22,$01,$60,$40,$B2,$1D,$FE,$9C,$14,$09,$21,$03,$30,$68,$5B
	db $98,$42,$2A,$03,$30,$00,$5C,$93,$89,$4A,$03,$50,$3F,$5D,$98,$83
	db $6A,$03,$54,$FE,$9D,$1B,$08,$04,$03,$40,$2A,$88,$57,$1E,$8D,$1F
	db $29,$2A,$89,$57,$1F,$8E,$1F,$29,$2A,$8A,$58,$1E,$8F,$1F,$29,$2A
	db $8B,$58,$1F,$90,$1F,$29,$2A,$8C,$97,$21,$85,$1F,$29,$2A,$8D,$99
	db $20,$84,$1F,$29,$2A,$8E,$5A,$1F,$91,$1F,$29,$2A,$8F,$9A,$21,$85
	db $1F,$29,$2B,$90,$57,$1E,$9F,$1F,$29,$2B,$91,$97,$1F,$80,$1F,$29
	db $2B,$92,$98,$1E,$81,$1F,$29,$2B,$93,$98,$1F,$82,$1F,$29,$2B,$94
	db $97,$21,$87,$1F,$29,$2B,$95,$99,$20,$86,$1F,$29,$2B,$96,$9A,$1F
	db $83,$1F,$29,$2B,$97,$9A,$21,$87,$1F,$29,$00,$C5,$5A,$1A,$A6,$13
	db $26,$FF,$1E,$1E,$23,$01,$60,$40,$B2,$1D,$59,$5E,$B9,$5D,$4A,$03
	db $30,$59,$5F,$B6,$9C,$6A,$03,$2C,$7E,$60,$95,$B4,$2A,$03,$40,$FE
	db $A8,$15,$73,$04,$03,$50,$6B,$61,$B6,$60,$0C,$03,$50,$00,$62,$05
	db $71,$65,$03,$60,$2A,$63,$09,$71,$62,$03,$64,$2A,$64,$04,$86,$60
	db $03,$74,$2A,$65,$04,$84,$60,$03,$70,$00,$66,$07,$95,$61,$03,$68
	db $00,$67,$07,$9C,$61,$03,$6C,$00,$68,$96,$B8,$6B,$03,$64,$00,$68
	db $17,$38,$16,$03,$28,$00,$69,$97,$AF,$6A,$03,$68,$00,$C6,$76,$22
	db $A6,$13,$26,$00,$C7,$77,$22,$A6,$13,$26,$00,$C8,$55,$26,$A6,$13
	db $26,$00,$C9,$55,$28,$A6,$13,$26,$FF,$1A,$1A,$24,$00,$08,$0B,$09
	db $1F,$40,$6B,$86,$2F,$72,$01,$2C,$40,$6B,$86,$30,$73,$01,$2C,$40
	db $6B,$87,$2F,$74,$01,$2C,$40,$6B,$87,$30,$75,$01,$2C,$3E,$6A,$94
	db $F4,$0A,$04,$30,$00,$97,$0B,$2D,$2C,$0A,$67,$00,$97,$0B,$32,$2C
	db $0A,$67,$00,$97,$0E,$2D,$2C,$0A,$67,$00,$97,$0E,$32,$2C,$0A,$67
	db $00,$97,$11,$2F,$2C,$0A,$67,$00,$97,$11,$30,$2C,$0A,$67,$00,$98
	db $0B,$27,$4B,$0A,$6F,$00,$98,$0F,$37,$4B,$0A,$6F,$00,$98,$0D,$2F
	db $4B,$0A,$6F,$00,$98,$0D,$30,$4B,$0A,$6F,$00,$CA,$4A,$26,$A6,$12
	db $26,$00,$CB,$4A,$27,$A6,$12,$26,$00,$CC,$4A,$28,$A6,$12,$26,$00
	db $CD,$50,$2A,$A6,$12,$26,$00,$99,$59,$2C,$86,$9C,$28,$FF,$1A,$1A
	db $25,$00,$08,$0C,$09,$1F,$41,$6B,$86,$0F,$92,$01,$2C,$41,$6B,$86
	db $10,$93,$01,$2C,$41,$6B,$87,$0F,$94,$01,$2C,$41,$6B,$87,$10,$95
	db $01,$2C,$00,$B1,$0E,$07,$2B,$0A,$76,$00,$B1,$0F,$0B,$2B,$0A,$76
	db $00,$B1,$0F,$14,$2B,$0A,$76,$00,$B1,$16,$14,$2B,$0A,$76,$00,$B1
	db $1A,$11,$2B,$0A,$76,$00,$B2,$13,$09,$6B,$0A,$77,$00,$B2,$08,$0B
	db $6B,$0A,$77,$00,$B2,$0B,$14,$6B,$0A,$77,$00,$B2,$16,$16,$6B,$0A
	db $77,$00,$B2,$1A,$0F,$6B,$0A,$77,$00,$B3,$06,$0C,$4B,$0C,$7E,$00
	db $B3,$08,$15,$4B,$0A,$7E,$00,$B3,$10,$14,$4B,$0A,$7E,$00,$B3,$18
	db $0C,$4B,$0A,$7E,$00,$CE,$4D,$17,$A6,$12,$26,$00,$CF,$4D,$19,$A6
	db $12,$26,$FF,$19,$19,$26,$00,$08,$0D,$09,$1F,$42,$6B,$86,$0F,$52
	db $01,$2C,$42,$6B,$86,$10,$53,$01,$2C,$42,$6B,$87,$0F,$54,$01,$2C
	db $42,$6B,$87,$10,$55,$01,$2C,$00,$9B,$0C,$0A,$2B,$0A,$6F,$00,$9B
	db $15,$18,$2B,$0A,$6F,$00,$9B,$10,$14,$2B,$0A,$6F,$00,$9B,$0E,$11
	db $2B,$0C,$6F,$00,$9C,$0C,$05,$0B,$0A,$6B,$00,$9C,$15,$0B,$0B,$0A
	db $6B,$00,$9C,$10,$18,$0B,$0A,$6B,$00,$9C,$10,$19,$0B,$0A,$6B,$00
	db $9D,$12,$05,$6D,$0A,$7F,$00,$9D,$15,$16,$6D,$0A,$7F,$00,$9D,$10
	db $17,$6D,$0A,$7F,$00,$9D,$10,$1A,$6D,$0A,$7F,$00,$D0,$4F,$18,$A6
	db $12,$26,$00,$D1,$4F,$1A,$A6,$12,$26,$00,$D2,$59,$0D,$A6,$14,$26
	db $00,$9B,$49,$14,$86,$9A,$28,$00,$DB,$51,$10,$86,$9C,$28,$00,$DC
	db $58,$0F,$86,$9C,$28,$FF,$19,$19,$25,$00,$08,$0E,$09,$1F,$43,$6B
	db $86,$2F,$92,$01,$2C,$43,$6B,$86,$30,$93,$01,$2C,$43,$6B,$87,$2F
	db $94,$01,$2C,$43,$6B,$87,$30,$95,$01,$2C,$00,$AD,$16,$2A,$6B,$0A
	db $77,$00,$AD,$0B,$34,$6B,$0A,$77,$00,$AD,$0B,$2F,$6B,$0C,$77,$00
	db $AD,$0B,$30,$6B,$0C,$77,$00,$AD,$0E,$2F,$6B,$0A,$77,$00,$AE,$0A
	db $2B,$6D,$0A,$7F,$00,$AE,$16,$34,$6D,$0A,$7F,$00,$AE,$0F,$39,$6D
	db $0A,$7F,$00,$AE,$10,$3A,$6D,$0A,$7F,$00,$AE,$11,$3B,$6D,$0A,$7F
	db $00,$AC,$12,$2C,$6C,$0A,$71,$00,$AC,$17,$36,$6C,$0A,$71,$00,$AC
	db $0F,$3A,$6C,$0A,$71,$00,$AC,$10,$3B,$6C,$0A,$71,$C1,$18,$4F,$3B
	db $A6,$12,$24,$00,$D3,$49,$2E,$A6,$14,$26,$00,$D4,$49,$31,$A6,$14
	db $26,$FF,$19,$19,$27,$00,$08,$0F,$09,$1F,$44,$6B,$A6,$0F,$72,$01
	db $2C,$44,$6B,$A6,$10,$73,$01,$2C,$44,$6B,$A7,$0F,$74,$01,$2C,$44
	db $6B,$A7,$10,$75,$01,$2C,$00,$A1,$00,$00,$8C,$08,$71,$00,$A1,$2F
	db $13,$8C,$0A,$71,$00,$A1,$2D,$0F,$8C,$0A,$71,$00,$A1,$2E,$16,$8C
	db $0C,$71,$00,$A1,$31,$0E,$8C,$0C,$71,$00,$A2,$29,$0B,$4B,$0C,$7E
	db $00,$A2,$29,$14,$4B,$0C,$7E,$00,$A2,$39,$13,$4B,$0A,$7E,$00,$A2
	db $2D,$10,$4B,$0A,$7E,$00,$A0,$33,$06,$0C,$0A,$67,$00,$A0,$35,$13
	db $0C,$0A,$67,$00,$A0,$30,$18,$0C,$0A,$67,$00,$A0,$31,$1A,$0C,$0C
	db $67,$00,$A0,$31,$11,$0C,$0C,$67,$00,$D5,$6D,$18,$A6,$12,$26,$00
	db $D6,$74,$17,$A6,$12,$26,$FF,$19,$19,$27,$00,$08,$10,$09,$1F,$45
	db $6B,$A6,$2F,$72,$01,$2C,$45,$6B,$A6,$30,$73,$01,$2C,$45,$6B,$A7
	db $2F,$74,$01,$2C,$45,$6B,$A7,$30,$75,$01,$2C,$00,$A8,$2C,$35,$8C
	db $0C,$71,$00,$A8,$33,$31,$8C,$0C,$71,$00,$A8,$33,$27,$8C,$0C,$71
	db $00,$A8,$29,$2B,$8C,$0A,$71,$00,$A8,$32,$30,$8C,$0A,$71,$00,$A8
	db $39,$2D,$8C,$0A,$71,$00,$A9,$33,$34,$2B,$0C,$76,$00,$A9,$2F,$38
	db $2B,$0A,$76,$00,$A9,$33,$2D,$2B,$0C,$76,$00,$A9,$30,$2B,$2B,$0A
	db $76,$00,$A9,$29,$2D,$2B,$0A,$76,$00,$A9,$29,$32,$2B,$0A,$76,$00
	db $A9,$32,$33,$2B,$0A,$76,$00,$A9,$39,$32,$2B,$0A,$76,$C2,$19,$78
	db $2B,$A6,$12,$24,$00,$D7,$79,$34,$A6,$12,$26,$FF,$1A,$1A,$28,$00
	db $49,$31,$C9,$1F,$46,$6B,$A6,$0F,$52,$05,$2C,$46,$6B,$A6,$10,$53
	db $05,$2C,$46,$6B,$A7,$0F,$54,$05,$2C,$46,$6B,$A7,$10,$55,$05,$2C
	db $05,$A0,$64,$0E,$8A,$1E,$29,$05,$9F,$25,$0E,$FA,$3E,$5C,$E5,$FE
	db $67,$10,$66,$9E,$28,$00,$A5,$2B,$0A,$0C,$0C,$71,$00,$A5,$2C,$12
	db $0C,$0C,$71,$00,$A5,$2D,$17,$0C,$0A,$71,$00,$A5,$3A,$0D,$0C,$0A
	db $71,$00,$A6,$34,$0D,$0D,$0A,$7F,$00,$A6,$2C,$0E,$0D,$0C,$7F,$00
	db $A6,$2B,$15,$0D,$0C,$7F,$00,$A7,$2D,$08,$2B,$0A,$7E,$00,$A7,$31
	db $10,$2B,$0C,$7E,$00,$A7,$2B,$19,$2B,$0A,$7E,$00,$A7,$32,$14,$2B
	db $0A,$7E,$C3,$1A,$65,$11,$A6,$16,$24,$00,$9C,$6D,$06,$66,$9A,$28
	db $00,$9D,$73,$07,$66,$9A,$28,$00,$9E,$6E,$10,$66,$9E,$28,$FF,$1A
	db $1A,$27,$00,$08,$00,$09,$1F,$00,$9A,$25,$2B,$0C,$0A,$67,$00,$9A
	db $2E,$2B,$0C,$0A,$67,$00,$9A,$39,$2B,$0C,$0A,$67,$FF,$1A,$1A,$26
	db $00,$08,$00,$09,$1F,$00,$9F,$25,$2B,$2B,$0A,$6F,$00,$9F,$2E,$2B
	db $2B,$0A,$6F,$00,$9F,$39,$2B,$2B,$0A,$6F,$FF,$1A,$1A,$26,$00,$08
	db $00,$09,$1F,$00,$A4,$25,$2B,$0B,$0A,$6B,$00,$A4,$2E,$2B,$0B,$0A
	db $6B,$00,$A4,$39,$2B,$0B,$0A,$6B,$FF,$1A,$1A,$28,$00,$08,$00,$09
	db $1F,$00,$B0,$25,$2B,$2B,$0A,$7E,$00,$B0,$2E,$2B,$2B,$0A,$7E,$00
	db $B0,$39,$2B,$2B,$0A,$7E,$FF,$1A,$1A,$28,$00,$08,$00,$09,$1F,$00
	db $AB,$25,$2B,$0D,$0A,$7F,$00,$AB,$2E,$2B,$0D,$0A,$7F,$00,$AB,$39
	db $2B,$0D,$0A,$7F,$FF,$1F,$1F,$02,$01,$60,$40,$2E,$20,$CA,$72,$2B
	db $52,$26,$03,$40,$CA,$1B,$2C,$12,$29,$23,$44,$00,$D8,$65,$22,$A6
	db $13,$26,$FF,$1C,$1C,$29,$01,$60,$40,$4E,$21,$FE,$9E,$10,$10,$01
	db $03,$30,$FE,$9F,$10,$10,$21,$03,$40,$1A,$73,$05,$CF,$67,$03,$50
	db $56,$A1,$02,$8F,$67,$19,$50,$FF,$91,$11,$2A,$64,$6A,$20,$E6,$22
	db $57,$74,$2A,$10,$16,$03,$2C,$FE,$7E,$A7,$18,$0A,$01,$30,$58,$B5
	db $19,$0D,$2B,$09,$76,$58,$B5,$19,$14,$2B,$09,$76,$58,$B5,$38,$0F
	db $2B,$09,$76,$58,$B5,$37,$10,$2B,$09,$76,$58,$B5,$38,$11,$2B,$09
	db $76,$58,$B6,$0E,$17,$6D,$09,$7F,$58,$B6,$22,$10,$6D,$09,$7F,$58
	db $B6,$33,$0C,$6D,$09,$7F,$58,$B6,$33,$14,$6D,$09,$7F,$58,$B6,$38
	db $10,$6D,$09,$7F,$58,$B7,$10,$0F,$4B,$09,$7E,$58,$B7,$1B,$13,$4B
	db $09,$7E,$58,$B7,$10,$11,$4B,$09,$7E,$58,$B7,$28,$10,$4B,$0B,$7E
	db $58,$B7,$39,$10,$4B,$09,$7E,$00,$D9,$4D,$0D,$A6,$11,$26,$00,$DA
	db $5D,$0E,$A6,$11,$26,$00,$DB,$7A,$10,$A6,$11,$26,$00,$A2,$5C,$13
	db $9A,$59,$28,$00,$A3,$5F,$10,$9A,$59,$28,$00,$A4,$60,$10,$9A,$59
	db $28,$FF,$12,$12,$2B,$04,$2B,$81,$66,$23,$58,$B8,$1E,$11,$2B,$09
	db $76,$58,$B8,$1F,$09,$2B,$09,$76,$58,$B8,$1F,$18,$2B,$09,$76,$58
	db $BA,$08,$09,$4D,$09,$7F,$58,$BA,$22,$11,$4D,$09,$7F,$58,$BA,$2E
	db $0F,$4D,$09,$7F,$58,$B9,$20,$11,$4B,$09,$77,$58,$B9,$2E,$11,$4B
	db $09,$77,$58,$B9,$11,$07,$4B,$09,$77,$58,$B9,$11,$18,$4B,$09,$77
	db $58,$B9,$2B,$08,$4B,$09,$77,$58,$B9,$2E,$0C,$4B,$09,$77,$58,$B9
	db $2E,$14,$4B,$09,$77,$58,$B9,$2B,$18,$4B,$09,$77,$00,$DC,$47,$09
	db $A6,$11,$26,$00,$DD,$52,$10,$A6,$11,$26,$00,$DE,$64,$11,$A6,$11
	db $26,$00,$A5,$47,$08,$86,$99,$28,$00,$A6,$53,$08,$86,$99,$28,$00
	db $A7,$51,$11,$86,$99,$28,$00,$A8,$54,$18,$86,$99,$28,$FF,$12,$12
	db $2A,$64,$2B,$02,$06,$23,$58,$BB,$08,$33,$6B,$09,$77,$58,$BB,$27
	db $2A,$6B,$09,$77,$58,$BB,$27,$36,$6B,$09,$77,$58,$BB,$2B,$27,$6B
	db $09,$77,$58,$BC,$08,$2D,$6B,$09,$77,$58,$BC,$2E,$30,$6B,$09,$77
	db $58,$BC,$36,$2D,$6B,$09,$77,$58,$BC,$36,$33,$6B,$09,$77,$58,$BD
	db $11,$27,$4B,$09,$7E,$58,$BD,$1B,$2A,$4B,$09,$7E,$58,$BD,$1B,$36
	db $4B,$09,$7E,$58,$BD,$13,$30,$4B,$09,$7E,$58,$BD,$1F,$27,$4B,$09
	db $7E,$58,$BD,$33,$2D,$4B,$09,$7E,$58,$BD,$33,$33,$4B,$09,$7E,$58
	db $BD,$2B,$39,$4B,$09,$7E,$00,$DF,$53,$2C,$A6,$11,$26,$00,$E0,$55
	db $2C,$A6,$11,$26,$00,$E1,$6C,$2C,$A6,$11,$26,$00,$E2,$6C,$34,$A6
	db $11,$26,$00,$A9,$54,$28,$9A,$59,$28,$00,$AA,$54,$29,$9A,$59,$28
	db $FF,$12,$12,$2C,$64,$20,$81,$65,$23,$58,$75,$BA,$10,$4A,$01,$50
	db $FE,$A0,$33,$90,$21,$00,$30,$FE,$A1,$39,$CF,$04,$00,$40,$00,$76
	db $AA,$8C,$4A,$03,$68,$00,$45,$AA,$94,$4A,$03,$68,$C4,$1B,$73,$0B
	db $A6,$11,$24,$00,$E4,$47,$09,$A6,$11,$26,$00,$E5,$52,$10,$A6,$11
	db $26,$00,$E6,$64,$11,$A6,$11,$26,$00,$AB,$47,$08,$86,$99,$28,$00
	db $AC,$53,$08,$86,$99,$28,$00,$AD,$51,$11,$86,$99,$28,$00,$AE,$54
	db $18,$86,$99,$28,$FF,$22,$22,$FF,$00,$00,$00,$0C,$24,$FF,$23,$23
	db $2D,$05,$32,$0E,$0C,$24,$0F,$77,$04,$19,$6E,$03,$2C,$0F,$77,$04
	db $1A,$6F,$03,$2C,$0F,$77,$05,$19,$74,$03,$2C,$0F,$77,$05,$1A,$75
	db $03,$2C,$00,$C2,$26,$15,$0A,$0B,$6A,$00,$C2,$26,$19,$0A,$0B,$6A
	db $00,$C3,$1C,$0E,$4B,$0B,$7A,$00,$C3,$16,$27,$4B,$0B,$7A,$00,$C4
	db $08,$1F,$2C,$0B,$7B,$00,$C4,$0E,$0B,$2C,$0B,$7B,$00,$E7,$4F,$0F
	db $A6,$13,$26,$00,$E8,$5D,$0A,$A6,$13,$26,$00,$E9,$51,$27,$A6,$13
	db $26,$00,$EA,$5F,$26,$A6,$13,$26,$00,$AF,$4B,$12,$86,$9B,$28,$00
	db $B0,$4B,$19,$86,$9B,$28,$00,$B1,$50,$1B,$86,$9B,$28,$00,$B2,$5F
	db $1D,$86,$9B,$28,$00,$B3,$63,$1C,$86,$9B,$28,$00,$B4,$64,$21,$86
	db $9B,$28,$FF,$24,$24,$2E,$82,$26,$0F,$0C,$24,$10,$78,$08,$17,$6E
	db $03,$2C,$10,$78,$08,$18,$72,$03,$2C,$10,$78,$09,$17,$70,$03,$2C
	db $10,$78,$09,$18,$73,$03,$2C,$00,$C6,$1D,$0B,$2B,$0B,$74,$00,$C6
	db $1F,$19,$2B,$0B,$74,$00,$C7,$13,$26,$0C,$0B,$7C,$00,$C7,$0F,$12
	db $0C,$0B,$7C,$00,$C8,$16,$1A,$4A,$0B,$7D,$00,$C8,$15,$16,$4A,$0B
	db $7D,$00,$EB,$55,$19,$A6,$13,$26,$00,$EC,$55,$1A,$A6,$13,$26,$00
	db $ED,$60,$19,$A6,$13,$26,$00,$EE,$60,$1A,$A6,$13,$26,$00,$B5,$49
	db $0F,$86,$9B,$28,$00,$B6,$58,$15,$86,$9B,$28,$00,$B7,$61,$0B,$86
	db $9B,$28,$00,$B8,$5F,$12,$86,$9B,$28,$00,$B9,$60,$25,$86,$9B,$28
	db $FF,$25,$25,$2F,$00,$48,$70,$4C,$24,$11,$79,$12,$17,$6E,$03,$2C
	db $11,$79,$12,$18,$6F,$03,$2C,$11,$79,$13,$17,$74,$03,$2C,$11,$79
	db $13,$18,$75,$03,$2C,$00,$CA,$1B,$16,$2B,$09,$74,$00,$CA,$1B,$1A
	db $2B,$09,$74,$00,$CA,$22,$23,$2B,$0B,$74,$00,$CA,$0C,$0C,$2B,$09
	db $74,$00,$CA,$0B,$25,$2B,$0B,$74,$00,$CB,$0B,$12,$0D,$09,$7F,$00
	db $CB,$19,$29,$0D,$09,$7F,$00,$CB,$1A,$20,$0D,$0B,$7F,$00,$CB,$12
	db $1E,$0D,$09,$7F,$00,$CB,$0A,$0F,$0D,$0B,$7F,$00,$CC,$0B,$1B,$4B
	db $09,$7E,$00,$CC,$1E,$09,$4B,$0B,$7E,$00,$CC,$15,$0B,$4B,$0B,$7E
	db $00,$CC,$15,$1E,$4B,$09,$7E,$00,$CC,$14,$15,$4B,$0B,$7E,$00,$EF
	db $4E,$07,$A6,$13,$26,$00,$F0,$5B,$29,$A6,$11,$26,$FF,$26,$26,$2F
	db $00,$08,$11,$0C,$24,$FF,$26,$26,$32,$0E,$20,$00,$0C,$24,$FE,$A6
	db $0F,$0F,$01,$04,$30,$00,$A7,$4D,$0F,$26,$1C,$28,$00,$A7,$4E,$4F
	db $26,$1C,$28,$FE,$C5,$43,$05,$78,$19,$2C,$FE,$C6,$43,$19,$78,$19
	db $2C,$FE,$C7,$57,$05,$78,$19,$2C,$FE,$C8,$57,$19,$78,$19,$2C,$19
	db $C9,$44,$4F,$A0,$18,$5C,$19,$CA,$44,$50,$A2,$18,$5C,$19,$CB,$45
	db $50,$A3,$18,$5C,$19,$CC,$45,$4F,$A1,$18,$5C,$39,$CD,$44,$0F,$A0
	db $38,$5C,$39,$CE,$44,$10,$A2,$38,$5C,$39,$CF,$45,$10,$A3,$38,$5C
	db $39,$D0,$45,$0F,$A1,$38,$5C,$00,$F2,$4E,$05,$46,$12,$24,$00,$F3
	db $46,$12,$46,$12,$24,$00,$F4,$46,$0D,$46,$12,$24,$00,$F5,$4E,$19
	db $46,$12,$24,$FF,$27,$27,$30,$A0,$00,$60,$CC,$24,$FE,$A2,$0D,$8E
	db $26,$03,$40,$FE,$1B,$0E,$0E,$29,$23,$44,$FE,$A3,$0F,$0E,$01,$03
	db $30,$00,$7A,$8D,$0D,$6E,$03,$2C,$00,$7A,$8D,$0E,$6F,$03,$2C,$00
	db $7A,$8E,$0D,$70,$03,$2C,$00,$7A,$8E,$0E,$71,$03,$2C,$FE,$A9,$4D
	db $0E,$8A,$03,$29,$00,$D2,$4A,$0D,$BB,$19,$5C,$00,$D3,$4A,$0E,$BC
	db $19,$5C,$00,$D4,$4B,$0E,$BE,$19,$5C,$00,$D5,$4B,$0D,$BD,$19,$5C
	db $FF,$00,$00,$FF,$7F,$08,$65,$6B,$69,$73,$66,$92,$00,$3D,$02,$FD
	db $02,$00,$00,$FF,$7F,$0B,$28,$73,$4E,$B2,$01,$E7,$1C,$CE,$39,$58
	db $02,$00,$00,$A5,$14,$BD,$73,$B5,$56,$8C,$31,$BC,$01,$DB,$02,$00
	db $00,$00,$00,$C5,$20,$5D,$22,$96,$01,$0E,$01,$38,$7F,$B5,$7E,$AE
	db $51,$00,$00,$A5,$14,$17,$5B,$1D,$03,$52,$42,$AD,$31,$B6,$01,$5C
	db $01,$00,$00,$84,$10,$5D,$22,$5F,$03,$37,$01,$F7,$5E,$0E,$6E,$BD
	db $7B,$00,$00,$C5,$20,$BD,$3E,$77,$5F,$7C,$43,$1B,$0F,$09,$73,$2C
	db $72,$00,$00,$84,$10,$5D,$22,$D6,$7E,$7F,$03,$F7,$5E,$31,$46,$AD
	db $35,$00,$00,$C5,$20,$BD,$3E,$7F,$03,$7D,$05,$37,$01,$EE,$3E,$49
	db $36,$00,$00,$C5,$20,$5D,$22,$39,$67,$31,$46,$3B,$0F,$90,$1D,$F3
	db $29,$00,$00,$C5,$20,$5D,$22,$39,$67,$31,$46,$0E,$62,$72,$01,$D6
	db $01,$00,$00,$C5,$20,$BD,$3E,$15,$11,$94,$52,$3B,$03,$5D,$06,$2C
	db $62,$00,$00,$C5,$20,$BD,$3E,$57,$02,$96,$5A,$3B,$03,$DE,$06,$7B
	db $6F,$00,$00,$C6,$18,$5A,$6B,$52,$4A,$AD,$35,$29,$25,$F7,$5E,$00
	db $00,$00,$00,$C5,$20,$FF,$7F,$5A,$6B,$CC,$45,$37,$73,$14,$6B,$4F
	db $56,$00,$00,$D6,$5A,$FB,$02,$CE,$39,$4A,$29,$F8,$01,$69,$32,$D1
	db $7E,$00,$00,$4E,$37,$D3,$01,$DB,$02,$39,$77,$70,$7E,$76,$14,$6B
	db $2D,$00,$00,$BA,$02,$93,$01,$17,$02,$18,$63,$52,$42,$10,$3E,$6B
	db $2D,$00,$00,$7B,$6B,$F7,$76,$AC,$45,$73,$4E,$37,$00,$FD,$01,$3D
	db $03,$00,$00,$19,$00,$9D,$02,$58,$62,$B2,$2A,$0E,$2A,$95,$59,$29
	db $25,$00,$00,$FE,$7F,$5E,$3F,$57,$2A,$D3,$19,$4F,$09,$EA,$00,$A8
	db $00,$00,$00,$FE,$7F,$AE,$52,$2A,$42,$A5,$31,$22,$21,$A0,$10,$20
	db $14,$00,$00,$FE,$7F,$9E,$62,$B7,$45,$12,$31,$8E,$20,$29,$14,$05
	db $00,$00,$00,$FE,$7F,$6E,$33,$69,$1A,$E4,$09,$62,$01,$E0,$00,$80
	db $00,$00,$00,$FF,$7F,$B3,$66,$2F,$56,$AB,$45,$27,$35,$A3,$24,$20
	db $14,$00,$00,$53,$33,$A6,$16,$A3,$11,$01,$0D,$2F,$1D,$27,$00,$00
	db $00,$00,$00,$FF,$7F,$9C,$73,$39,$67,$F5,$7F,$33,$73,$F1,$6A,$AF
	db $62,$00,$00,$7B,$6F,$52,$4A,$AD,$35,$4A,$29,$E7,$1C,$14,$46,$4E
	db $29,$00,$00,$CC,$10,$16,$3A,$92,$29,$2F,$1D,$8A,$08,$27,$00,$00
	db $00,$00,$00,$B8,$5E,$B3,$39,$4E,$29,$0C,$1D,$FF,$7F,$A6,$1C,$39
	db $67,$00,$00,$B8,$5E,$B3,$39,$4E,$29,$0C,$1D,$E8,$20,$A6,$1C,$64
	db $10,$00,$00,$53,$33,$A6,$16,$A3,$11,$01,$0D,$B8,$5E,$B3,$39,$4E
	db $29,$00,$00,$D1,$41,$D2,$39,$6F,$2D,$0C,$1D,$E8,$20,$A6,$1C,$00
	db $00,$00,$00,$7F,$63,$36,$36,$1A,$00,$08,$00,$B2,$25,$0D,$11,$00
	db $00,$00,$00,$D6,$5A,$10,$42,$AD,$35,$4A,$29,$80,$01,$A5,$14,$00
	db $00,$00,$00,$FD,$52,$58,$3A,$D5,$1D,$30,$21,$80,$01,$E7,$1C,$00
	db $00,$00,$00,$FF,$7B,$D7,$5A,$53,$4A,$CF,$39,$4B,$29,$C7,$18,$00
	db $00,$00,$00,$FF,$7F,$BF,$4F,$98,$2A,$14,$22,$6F,$0D,$C6,$18,$00
	db $00,$00,$00,$FF,$7F,$16,$7F,$2F,$62,$8A,$45,$25,$2D,$C6,$18,$00
	db $00,$00,$00,$FF,$7F,$DB,$7E,$F4,$61,$4F,$45,$EA,$2C,$C6,$18,$00
	db $00,$00,$00,$FF,$7F,$D1,$53,$EA,$36,$E8,$15,$43,$0D,$C6,$18,$00
	db $00,$00,$00,$BD,$77,$16,$7F,$DC,$7E,$BF,$4F,$D1,$53,$19,$7F,$80
	db $01,$00,$00,$0B,$47,$87,$36,$E2,$21,$FF,$7F,$D6,$19,$C6,$18,$00
	db $00,$00,$00,$A5,$14,$34,$3E,$92,$35,$2D,$25,$EB,$18,$AF,$35,$4C
	db $21,$00,$00,$52,$4A,$8C,$31,$29,$25,$90,$19,$EE,$04,$A5,$14,$00
	db $00,$00,$00,$5B,$67,$32,$42,$8D,$2D,$2A,$21,$C7,$14,$4A,$29,$00
	db $00,$00,$00,$B8,$52,$12,$3E,$D0,$35,$4C,$25,$0A,$21,$A7,$14,$44
	db $08,$00,$00,$4A,$29,$3F,$4B,$DD,$3E,$D4,$1D,$E7,$1C,$A5,$14,$00
	db $00,$00,$00,$32,$3D,$AE,$2C,$4A,$29,$4B,$55,$09,$4D,$54,$26,$00
	db $00,$00,$00,$DD,$7F,$74,$73,$11,$67,$4F,$46,$6D,$25,$EA,$49,$00
	db $00,$00,$00,$A0,$02,$20,$02,$A0,$01,$E0,$00,$6D,$25,$84,$10,$00
	db $00,$00,$00,$33,$6F,$AF,$62,$2B,$4E,$A7,$3D,$04,$29,$FD,$7F,$D8
	db $77,$00,$00,$9C,$73,$94,$52,$10,$42,$8C,$31,$08,$21,$00,$00,$79
	db $51,$00,$00,$D7,$5A,$32,$46,$CF,$39,$6C,$2D,$2A,$25,$E8,$1C,$79
	db $51,$00,$00,$8C,$59,$0A,$59,$8E,$5A,$C8,$41,$04,$29,$83,$14,$8E
	db $5E,$00,$00,$DF,$77,$7F,$3E,$F8,$0D,$50,$01,$ED,$04,$FF,$4E,$79
	db $51,$00,$00,$BC,$7F,$D5,$72,$0F,$5E,$49,$45,$A4,$30,$20,$20,$00
	db $00,$00,$00,$FF,$7F,$F5,$6E,$AB,$49,$48,$3D,$E5,$30,$82,$24,$00
	db $00,$00,$38,$00,$2F,$C0,$1D,$C0,$18,$35,$2A,$70,$19,$EC,$0C,$C7
	db $18,$00,$38,$FF,$7F,$20,$7F,$60,$24,$D9,$3E,$90,$15,$E7,$1C,$00
	db $00,$00,$38,$D6,$5A,$30,$3A,$8C,$29,$28,$19,$A3,$10,$00,$00,$DE
	db $7B,$00,$38,$5F,$01,$16,$00,$FF,$7F,$B4,$5A,$CF,$3D,$29,$2D,$A7
	db $18,$00,$38,$94,$7B,$60,$7F,$C0,$79,$00,$68,$00,$00,$9A,$16,$3F
	db $7D,$00,$38,$9D,$73,$B0,$4A,$EA,$31,$87,$25,$C6,$18,$9C,$4D,$F7
	db $38,$00,$38,$FF,$7F,$39,$67,$73,$4E

; pc should equal $07DBFC

pullpc







pushpc
org pctosnes($03f7c3)

; DATA:  ($07F7C3)
Data07f7c3:
	db $35,$7E,$0E,$23,$08,$1F,$16,$1F,$22,$19,$29,$13,$2E,$15,$37,$0F
	db $33,$0D,$2D,$09,$24,$10,$1F,$10,$1A,$17,$1A,$13,$1A,$0E,$0F,$0C
	db $09,$0C,$10,$08,$1F,$0A,$2E,$29,$33,$28,$19,$2A,$0E,$28,$12,$26
	db $0E,$1E,$0E,$1A,$1C,$21,$1F,$1D,$24,$13,$30,$11,$37,$0B,$28,$18
	db $2D,$0E,$2D,$06,$34,$18,$1F,$15,$1F,$1B,$1C,$1B,$15,$0C,$09,$08
	db $0F,$10,$18,$08,$19,$05,$1D,$1E,$1F,$1F,$26,$1F,$28,$27,$28,$29
	db $35,$23,$3B,$28,$3C,$24,$35,$1E,$31,$1E,$1C,$27,$21,$2A,$31,$1C
	db $1C,$28,$2A,$25

; pc should equal $07F837

; end of bank, fill
padbyte $FF
pad $07FFFF

; TODO: did last byte fill?
;pad $088000

pullpc

