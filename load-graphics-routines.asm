






pushpc
org $008ec4

; ROUTINE: Copy tiles to VRAM (00:8ddf)
;		loops Y times, writing one tile to VRAM each time
;			copies $10 bytes to vram, then copies $8 bytes as the low byte using the same high byte loaded from $00f0-$00f1
;			so if data for last $8 bytes is = $AA $BB $CC... and $00f0 = $5500, then the second part would write as $55AA $55BB $55CC...
; parameters:
;		databank => source address bank
;		X => source address offset
;		Y => number of times to loop
;		$00f0 => high byte (which is at $00f1) will be used as high byte for second half of copies
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
		while !counter < 8
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

; ROUTINE: Copy $4 colors to CGRAM (008fb4)
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
; (for certain maps, like first map "Level Forest") TODO: what all calls this?
; A is 8bit
; TODO: better label
; TODO: more comment/code cleanup, reduce noise
CopyTileDataToWRAM:
	phb					; save program bank to stack
	%setDatabankA(05)

	; setup destination address (WRAM)
	ldx #$d274
	stx $2181			; set destination offset to $d274
	lda #$7f
	sta $2183			; set destination bank to $7F

	; copy $8 blocks of $400 bytes: either copy $20 tiles or clear bytes
	ldx #$0000			; loop counter
	.Loop {
		lda $191a,x			; get value from $191a+x (lowram) TODO: trace this ram value
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
			; TODO: What the hell is happening here?
			xba					; swap the high and low bytes of A (save lower byte for later use)
			stz $211b			; clear $211b-211c (multiplication registers [M7A] and [M7B])
									; mpy* = 01 00 00 ($000001)
			lda #$03				; set A to $3
			sta $211b			; copy A to [M7A]
									; mpy* = 00 03 00 ($000300)
			xba					; swap the high and low bytes of A (bring back the byte from earlier)
			sta $211c			; copy A to [M7B]
			%setAto16bit()
			lda #$8c80			; set A to $8c80
			clc
			adc $2134			; add the multiplication result at $2134-2135 ([MPYL] and [MPYM]) to A
									; so mpy* contains an offset
			tay					; copy A to Y
			%setAto8bit()

			; copy $20 tiles to WRAM
			phx					; save loop counter
			ldx #$0020			; loop counter
			.LoopB
				jsr $e90c			; jump to the "Copy one tile to WRAM" routine
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
	stx $2181

	; 
	ldx #$0000			; loop counter
	.LoopC {
		lda $191a,x			; get value from $191a+x (lowram) TODO: trace this ram value
		phx					; save loop counter

01fdd9 sta $211b
01fddc stz $211b
01fddf lda #$10
01fde1 sta $211c
01fde4 ldy $2134

		ldx #$0010			; loop counter
		.LoopD {
01fdea lda $f280,y
01fded and #$07
01fdef sta $2180
01fdf2 lda $f280,y
01fdf5 and #$70
01fdf7 lsr a
01fdf8 lsr a
01fdf9 lsr a
01fdfa lsr a
01fdfb sta $2180
01fdfe iny
			dex				; increment counter
			bne .LoopD
		}

		plx				; restore loop counter
		inx				; increment counter
		cpx #$0008		; loop until counter = $8
		bne .LoopC
	}

	plb				; restore program bank
	rts				; exit routine

; pc should equal $01fe0b

pullpc

















