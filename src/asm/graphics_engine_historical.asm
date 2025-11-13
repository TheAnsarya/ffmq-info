


;--------------------------------------------------------------------
;						BANK $00
;--------------------------------------------------------------------









;--------------------------------------------------------------------
	pushpc
	org $008504


; ROUTINE: Copy 8 Colors from $d8e4 ($008504)
;		copies $8 colors ($10 bytes)
;		data starts at $d8e4
; parameters:
;		A => starting color index
;		X => source address offset
; directpage should be $4300
; dma control $4350 should be set
; dma destination $4351 should be set
; dma databank $4354 should be set
Copy8ColorsFromD8E4:
	sta $2121			; starting color index => A
	ldy #$0010
	sty $55				; dma transfer size => $10
	%setAXYto16bit()
	txa
	and #$00ff
	clc
	adc #$d8e4
	sta $52				; source address => X.low + $d8e4
	%setAto8bit()
	lda #$20
	sta $420b			; start dma on channel 5
	rts					; exit routine


; pc should equal $008520
	pullpc
;--------------------------------------------------------------------















;--------------------------------------------------------------------
	pushpc
	org $008c1b


; ROUTINE: DecompressAddress ($008c1b)
;		expands the address stored in A.low
; parameters:
;		A => compressed address
; returns:
;		X => ((bits 3-5 of A) * 2) + (bits 0-2 of A)
;			so values can be: $00 to $77 (with bit 3 always 0)
;		A => decompressed address
;			(((X * 2) + X) * 16) + $8000 (bottom 4 bits always 0)
;			so values can be: $8000 to $9650
; TODO: maybe rename when other address expanders are found or we figure out what this is for
DecompressAddress:
	php					; save processor status
	%setAXYto16bit()

	and #$00ff			; discard high byte
	pha					; save A
	and #$0038			; bits 3-5
	asl a				; A => A * 2
	tax					; X => A
	pla					; restore A

; using stack as a variable
; X is (bits 3-5 of A) * 2
	and #$0007			; bits 0-2
	phx					; stack => X
	adc $01,s			; A += stack, is ((bits 3-5) * 2) + (bits 0-2)
	sta $01,s			; stack => A
	asl a				; A => A * 2
	adc $01,s			; A += stack
	asl a
	asl a
	asl a
	asl a				; A => A * 16
	adc #$8000			; A += $8000
	plx					; X => stack

	plp					; restore processor status
	rts					; exit routine


; pc should equal $008c3d
	pullpc
;--------------------------------------------------------------------
	pushpc
	org $008c3d


; ROUTINE:  ($008c3d)
Routine008c3d:
	php				; save processor status to stack
	%setAXYto8bit()
	ldx !ram_1031
	008c43 cpx #$ff
	008c45 beq $8c81

	008c47 lda #$02
	008c49 and !flags_d8
	008c4c beq $8c83

	008c4e lda $049800,x
	008c52 adc #$0a
	008c54 xba
	008c55 txa
	008c56 and #$38
	008c58 asl a
	008c59 pha
	008c5a txa
	008c5b and #$07
	008c5d ora $01,s
	008c5f plx
	008c60 asl a
	%setAXYto16bit()
	008c63 sta $7f075a
	008c67 inc
	008c68 sta $7f075c
	008c6c adc #$000f
	008c6f sta $7f079a
	008c73 inc
	008c74 sta $7f079c
	008c78 sep #$20			; set A => 8bit
	008c7a ldx #$17da
	008c7d lda #$7f
	008c7f bra $8c9c


	008c83 lda $049800,x
	008c87 asl a
	008c88 asl a
	008c89 sta !color_data_source_offset
	008c8c rep #$10			; set X,Y => 16bit
	008c8e lda !ram_1031
	008c91 jsr DecompressAddressUnlessFF
	008c94 stx $00f2
	008c97 ldx #$2d1a
	008c9a lda #$7e
	008c9c pha
	008c9d lda #$04
	008c9f and $00da
	008ca2 beq $8cc5

	008ca4 lda $0014
	008ca7 dec
	008ca8 beq $8cc5

	008caa lda #$10
	008cac and $00da
	008caf bne $8cbb

	008cbb plb
	008cbc lda $0001,x
	008cbf and #$e3
	008cc1 ora #$9c
	008cc3 bra $8ccd

	008cc5 plb
	008cc6 lda $0001,x
	008cc9 and #$e3
	008ccb ora #$88
	008ccd xba
	008cce lda !ram_1031_long
	008cd2 cmp #$29
	008cd4 bcc $8d11

	008cd6 cmp #$2c
	008cd8 beq $8d11

	008cda lda $0001,x
	008cdd and #$63
	008cdf ora #$08
	008ce1 sta $0001,x
	008ce4 sta $0003,x
	008ce7 lda $001030
	008ceb ldy #$ffff
	008cee sec
	008cef iny
	008cf0 sbc #$0a
	008cf2 bcs $8cef

	008cf4 adc #$8a
	008cf6 sta $0002,x
	008cf9 cpy #$0000
	008cfc beq $8d06

	008cfe tya
	008cff adc #$7f
	008d01 sta $0000,x
	008d04 bra $8d20

	008d11 xba
	008d12 sta $0001,x
	008d15 sta $0003,x
	008d18 lda #$45
	008d1a sta $0000,x
	008d1d sta $0002,x
	008d20 phk
	008d21 plb
	008d22 lda #$80
	008d24 tsb $00d4
	008d27 plp
	008d28 rts				; exit routine


; pc should equal $008d29
	pullpc
;--------------------------------------------------------------------






;--------------------------------------------------------------------
	pushpc
	org $008d8a


; ROUTINE:  ($008d8a)
; parameters:
;		A => compressed address
;			if $ff then return $ffff
; returns:
;		X => decompressed address
;			$ffff when A is $ff
DecompressAddressUnlessFF:
	cmp #$ff
	beq .IsFF

	.NotFF
	jsr DecompressAddress
	tax
	rts				; exit routine
	.IsFF
	ldx #$ffff
	rts				; exit routine


; pc should equal $008d97
	pullpc
;--------------------------------------------------------------------






;--------------------------------------------------------------------
	pushpc
	org $008ddf


; ROUTINE: Copy tiles to VRAM ($008ddf)
;		loops Y times, writing one tile to VRAM each time
;			copies $10 bytes to vram, then copies $8 bytes as the low byte using the same high byte loaded from $00f0-$00f1
;			so if data for last $8 bytes is = $aa $bb $cc... and $00f0 = $5500, then the second part would write as $55aa $55bb $55cc...
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
;--------------------------------------------------------------------












;--------------------------------------------------------------------
	pushpc
	org $008ec4


; ROUTINE: LoadTilesAndColors ($008ec4)
;		loads tiles from $078030 ($038030 in file)
;			viewable in 2bpp, 2 dimensional, 32 blocks wide in TileMolester
;			the 8bit address translation causes this output
; TODO: what are we actually loading? overworld? city? title?
;		text and menu outline and stuff and part of title screen
; TODO: finish code/comment cleanup
; TODO: Better label name
LoadTilesAndColors:
	php					; save processor status to stack
	phd					; save direct page to stack
	%setAXYto16bit()
	lda #$2100
	tcd					; direct page => $2100, so direct mode writes are to the registers
	%setAto8bit()

	ldx #$1801			; dma control => $01, write 2 bytes each time
	stx $4350			; dma destination => $18, VRAM
	ldx #$8030
	stx $4352			; source offset => $8030
	lda #$07
	sta $4354			; source bank => $07

	ldx #$1000
	stx $4355			; dma transfer size => $1000
	ldx #$3000
	stx $16				; vram destination address => $6000
	lda #$84			; $84 means increment address on write high byte, translation = 8bit, increment address by 1 word
	sta $15				; set video port control [VMAIN]
	lda #$20
	sta $420b			; start dma transfer on channel 5

; load $100 tiles from $048000 (in file: $020000) ($18 bytes each) to vram address $2000 ($20 bytes each)
	lda #$80			; $80 means increment destination address by 1 word (2 bytes) on write
	sta $15				; set video port control [VMAIN]
	%setAXYto16bit()
	lda #$ff00
	sta $00f0			; set high byte for second half of tile => $ff
	ldx #$2000
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
	ldx !menu_color
	ldy !menu_color_high
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
;--------------------------------------------------------------------
	pushpc
	org $008fb4


; ROUTINE: Copy $4 colors to CGRAM ($008fb4)
; parameters:
;		A => the starting color index
;		X => source address offset
; direct page => $2100, so the writes are to registers
; AXY => 8bit
Copy4ColorsToCGRAM:
	sta $21				; set CGRAM address $2121

; write 8 bytes to CGRAM
	!counter = 0
	while !counter < 8
	lda $8000+!counter,x
	sta $22

	!counter #= !counter+1
	endif

	rts					; exit routine


; pc should equal $008fdf
	pullpc
;--------------------------------------------------------------------








;--------------------------------------------------------------------
	pushpc
	org $00c56b


; ROUTINE: Clear 417/$1a1 bytes at Y ($00c56b)
;		fills $0d*$20 bytes ($1a0) with $00, starting at Y
;		clears one additional byte, so $1a1 or 417 bytes are cleared
;		the extra byte seems like an error
; parameters:
;		Y => destination offset
Clear417BytesAtY:
	ldx #$000d				; loop counter
	clc
	.Loop {
; fill $21 bytes with $00
; NOTE: this fills $21 bytes at a time but the counter advances by $20 bytes, not $21
; NOTE: this might be a programming mistake!
	%setAto8bit()
	lda #$00
	jsr FillWithA_x11
	%setAXYto16bit()

	tya
	adc #$0020
	tay					; Y += $20

	dex					; decrement counter
	bne .Loop			; loop until counter = 0
	}

	rts					; exit routine


; pc should equal $00c581
	pullpc
;--------------------------------------------------------------------







;--------------------------------------------------------------------
;						BANK $01
;--------------------------------------------------------------------




;--------------------------------------------------------------------
	pushpc
	org $018336


; ROUTINE:  ($018336)
Routine018336:
	php					; save processor status
	phb					; save databank
	phk
	plb					; databank => program bank
	%setAto8bit()
	%setXYto16bit()

	lda !ram_19a5
	bmi .Exit

	018343 jsr $8e06
	018346 jsr WriteRamFrom195F

	lda #$00
	xba					; clear A.high
	lda !ram_1a46
	asl a
	tax					; X => !ram_1a46 * 2
	jsr ($835a,x)		; TODO: rename jump table
	stz !ram_1a46		; clear !ram_1a46

	.Exit
	plb					; restore databank
	plp					; restore processor status
	rtl					; exit routine


; pc should equal $018360
	pullpc
;--------------------------------------------------------------------










;--------------------------------------------------------------------
	pushpc
	org $01836c


; ROUTINE: LoadFromDataColors839e ($01836c)
;		DataColors839e => $20 bytes in $4 byte chunks
;			byte 0 => color index
;			bytes 1-2 => source address
;			byte 3 => dma transfer size
; A => 8bit, XY => 16bit
LoadFromDataColors839e:
	ldx #$0000			; clear X
	txa
	xba					; clear A.high
	.Loop {
	lda $839e,x
	sta $2121			; color index => $839e[X]
	ldy #$2200			; dma control => $00, auto increment, write twice
	sty $4300			; dma destination => $22, CGRAM
	ldy $839f,x
	sty $4302			; source offset => $839f[X]
	lda #$7f
	sta $4304			; source bank => $7f
	lda $83a1,x
	tay
	sty $4305			; dma transfer size => $83a1[X]
	lda #$01
	sta $420b			; start dma transfer on channel 0

	inx
	inx
	inx
	inx					; counter += 4
	cpx #$0020			; loop until counter = $20
	bne .Loop
	}

	rts					; exit routine


; pc should equal $01839e
	pullpc
;--------------------------------------------------------------------
	pushpc
	org $01839e


; DATA: DataColors839e ($01839e)
;		$01839e-$0183bd ($20 bytes)
;		$20 bytes in $4 byte chunks
;			byte 0 => color index
;			bytes 1-2 => source address
;			byte 3 => dma transfer size
DataColors839e:
	db $80			; color index
	dw $c488		; source address
	db $10			; size

	db $90			; color index
	dw $c4a8		; source address
	db $10			; size

	db $a0			; color index
	dw $c4c8		; source address
	db $10			; size

	db $b0			; color index
	dw $c4e8		; source address
	db $20			; size

	db $c0			; color index
	dw $c508		; source address
	db $10			; size

	db $d0			; color index
	dw $c528		; source address
	db $10			; size

	db $e0			; color index
	dw $c548		; source address
	db $10			; size

	db $f0			; color index
	dw $c568		; source address
	db $10			; size


; pc should equal $0183be
	pullpc
;--------------------------------------------------------------------
	pushpc
	org $0183be


; ROUTINE: Copy Tilemap from WRAM to VRAM ($0183be)
;		copy two sections from WRAM to VRAM through DMA (channel 0)
;		each section can have 4 copys
; parameters:
;		!copy_routine_selector => if $01 then call second copy routine    TODO: verify
;		ram $19fa - $1a12 => parameters for first copy
;		ram $1a13 - $1a2b => parameters for second copy
CopyTilemapFromWRAMToVRAM:
	jsr CopyTilemapFromWRAMToVRAM_1

; skip second copy if !ram_1a4c !+= $01
	lda !ram_1a4c
	dec
	bne .Exit

	jsr CopyTilemapFromWRAMToVRAM_2

	.Exit
	rts					; exit routine


; pc should equal $0183cb
	pullpc;--------------------------------------------------------------------
	pushpc
	org $0183cb


; ROUTINE: Copy Tilemap from WRAM to VRAM ($0183cb)
;		copy from WRAM to VRAM through DMA (channel 0) up to 4 times options at $19fa
; parameters:
;		$19fa => 1 byte, VMAIN flags, !tilemap_vram_control
;		$19fb-$1a02 => 8 bytes, 2-byte pairs, 4 of them, each is destination address in VRAM, !tilemap_vram_destination_addresses
;		$1a03-$1a0a => 8 bytes, 2-byte pairs, 4 of them, each is source address offset, !tilemap_wram_source_addresses
;		$1a0b-$1a12 => 8 bytes, 2-byte pairs, 4 of them, each is DMA transfer size in bytes, !tilemap_dma_transfer_sizes
; A => 8bit, XY => 16bit
CopyTilemapFromWRAMToVRAM_1:
	ldx #$0000			; loop counter
; setup and run dma transfer up to 4 times {
	.Loop {
	ldy !tilemap_dma_transfer_sizes,x
	beq .Exit			; exit when y = $0000 (no bytes to transfer)
	sty $4305			; DMA transfer size => !tilemap_dma_transfer_sizes[X]
	ldy #$1801			; $18 means destination is VRAM register $2118, $01 means write 2 bytes each time
	sty $4300			; write dma control and destination registers

; setup source address
	ldy !tilemap_wram_source_addresses,x
	sty $4302			; source offset => !tilemap_wram_source_addresses[X]
	lda #$00
	sta $4304			; source bank => $00

; destination setup
	ldy !tilemap_vram_destination_addresses,x
	sty $2116			; VRAM destination address => !tilemap_vram_destination_addresses[X]
	lda !tilemap_vram_control
	sta $2115			; VMAIN control
	lda #$01
	sta $420b			; start dma transfer on channel 0

	inx
	inx					; counter += 2
	cpx #$0008			; loop until counter = 8
	bne .Loop
	}

	.Exit
	rts				; exit routine


; pc should equal $018400
	pullpc;--------------------------------------------------------------------
	pushpc
	org $018400


; ROUTINE:  ($018400)
;		copy from WRAM to VRAM through DMA (channel 0) up to 4 times, options at $1a13
; parameters:
;		$1a13 => 1 byte, VMAIN flags, !tilemap_vram_control_2
;		$1a14-$1a1b => 8 bytes, 2-byte pairs, 4 of them, each is destination address in VRAM, !tilemap_vram_destination_addresses_2
;		$1a1c-$1a23 => 8 bytes, 2-byte pairs, 4 of them, each is source address offset, !tilemap_wram_source_addresses_2
;		$1a24-$1a2b => 8 bytes, 2-byte pairs, 4 of them, each is DMA transfer size in bytes, !tilemap_dma_transfer_sizes_2
; A => 8bit, XY => 16bit
CopyTilemapFromWRAMToVRAM_2:
	ldx #$0000			; setup X as a counter starting at $0000
; start of loop - setup and run dma transfer up to 4 times {
	.Loop {
	ldy !tilemap_dma_transfer_sizes_2,x
	beq .Exit			; exit when y = $0000 (no bytes to transfer)
	sty $4305			; DMA transfer size => !tilemap_dma_transfer_sizes_2[X]
	ldy #$1801			; $18 means destination is VRAM register $2118, $01 means write 2 bytes each time
	sty $4300			; write dma control and destination registers

; setup source address
	ldy !tilemap_wram_source_addresses_2,x
	sty $4302			; source offset => !tilemap_wram_source_addresses_2[X]
	lda #$00
	sta $4304			; source bank => $00

; destination setup
	ldy !tilemap_vram_destination_addresses_2,x
	sty $2116			; VRAM destination address => !tilemap_vram_destination_addresses_2[X]
	lda !tilemap_vram_control_2
	sta $2115			; VMAIN control
	lda #$01
	sta $420b			; start dma transfer on channel 0

	inx
	inx					; counter += 2
	cpx #$0008			; loop until counter = 8
	bne .Loop
	}

	.Exit
	rts					; exit routine


; pc should equal $018435
	pullpc;--------------------------------------------------------------------
	pushpc
	org $018435


; ROUTINE: Copy Wram 7FD274 To Vram ($018435)
;		Copy $2000 bytes from WRAM $7fd274 to VRAM $0000 through DMA (channel 0)
; A => 8bit, XY => 16bit
CopyWram7FD274ToVram:
	ldx #$0000
	stx $2116			; destination address => $0000
	lda #$80
	sta $2115			; vram control => $80, auto increment by 1 word on write high
	ldx #$1801			; dma control => $01, write 2 bytes each time
	stx $4300			; dma destination => $18, VRAM
	ldx #$d274
	stx $4302			; source offset => $d274
	lda #$7f
	sta $4304			; source bank => $7f
	ldx #$2000
	stx $4305			; dma transfer size => $2000
	lda #$01
	sta $420b			; start DMA transfer on channel 0
	rts					; exit routine


; pc should equal $01845d
	pullpc;--------------------------------------------------------------------
	pushpc
	org $01845d


; ROUTINE: Copy 64 colors from c588 ($01845d)
;		Copy $40 colors ($80 bytes) from WRAM $7fc588[X] to CGRAM
; parameters:
;		X => source offset
; A => 8bit, XY => 16bit
Copy64ColorsFrom7FC588:
	ldx #$c588			; X => $c588, source offset start
	lda #$00			; loop counter => $00, also color index
	.Loop {
	pha					; save counter
	sta $2121			; color index => A
	ldy #$2200			; dma control => $00, auto increment, write twice
	sty $4300			; dma destination => $22, CGRAM
	stx $4302			; source offset => X
	lda #$7f
	sta $4304			; source bank => $7f
	ldy #$0010
	sty $4305			; dma transfer size => $10
	lda #$01
	sta $420b			; start dma transfer on channel 0

; X += $10
	%setAto16bit()
	txa
	clc
	adc #$0010
	tax
	%setAto8bit()

	pla					; restore counter
	clc
	adc #$10			; counter += $10
	cmp #$80			; loop until counter = $80
	bne .Loop
	}
	rts					; exit routine


; pc should equal $018492
	pullpc;--------------------------------------------------------------------
	pushpc
	org $018492


; ROUTINE: Copy wram 7f0000 to vram ($018492)
;		Copy $2e00 bytes from WRAM $7f0000 to VRAM $6900 through DMA (channel 0)
; A => 8bit, XY => 16bit
CopyWram7F0000ToVram:
	ldx #$6900
	stx $2116			; destination address => $6900
	lda #$80
	sta $2115			; vram control => $80, auto increment by 1 word on write high
	ldx #$1801			; dma control => $01, write 2 bytes each time
	stx $4300			; dma destination => $18, VRAM
	stz $4302			; source offset => $0000
	ldx #$7f00			;
	stx $4303			; source bank => $7f
	ldx #$2e00
	stx $4305			; dma transfer size => $2e00
	lda #$01
	sta $420b			; start dma transfer on channel 0
	rts					; exit routine


; pc should equal $0184b8
	pullpc
;--------------------------------------------------------------------
	pushpc
	org $0184b8


; ROUTINE:  ($0184b8)
;		copy $0c00 bytes from WRAM $7f4000 to VRAM $6100 through DMA (channel 0)
; A => 8bit, XY => 16bit
CopyWram7F4000ToVram:
	ldx #$6100
	stx $2116			; destination address => $6100
	lda #$80
	sta $2115			; vram control => $80, auto increment by 1 word on write high
	ldx #$1801			; dma control => $01, write 2 bytes each time
	stx $4300			; dma destination => $18, VRAM
	ldx #$4000
	stx $4302			; source offset => $4000
	lda #$7f
	sta $4304			; source bank => $7f
	ldx #$0c00
	stx $4305			; dma transfer size => $0c00
	lda #$01
	sta $420b			; start dma transfer on channel 0
	rts					; exit routine


; pc should equal $0184e0
	pullpc
;--------------------------------------------------------------------











;--------------------------------------------------------------------
	pushpc
	org $01914c


; ROUTINE:  ($01914c)
Routine01914c:
	01914c jsr $8b75		; jump to the "Clear bits in 2 byte value at $008e using mask of $4030" routine
	jsl Routine0b8149
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
	0191aa stx !ram_195f
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

	0191ea lda !ram_0111
	0191ed pha
	0191ee stz !ram_0111
	0191f1 stz $420c
	0191f4 jsl $0b841d
	0191f8 jsr CopyWram7FD274ToVram
	0191fb jsr Copy64ColorsFrom7FC588
	0191fe jsr CopyWram7F0000ToVram
	019201 jsr CopyWram7F4000ToVram
	019204 jsr LoadFromDataColors839e
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
	019229 ldx #$2502
	01922c stx $19ee
	01922f jsl $01b24b
	019233 pla
	019234 sta !ram_0111
	019237 stz !ram_1a46
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
	019258 stz !ram_19a5
	01925b jsr $8b82
	01925e lda $0e91
	019261 beq .Exit

	019263 jsl $009aec

	.Exit
	rts				; exit routine


; pc should equal $019268
	pullpc
;--------------------------------------------------------------------









;--------------------------------------------------------------------
	pushpc
	org $019739


; ROUTINE: WriteRamFrom195F ($019739)
;		!ram_195f => destination address
;		!ram_195f+2 =>
;		!ram_195f+4 =>
;		!ram_195f+6 =>
;		!ram_195f+8 =>
WriteRamFrom195F:
	php					; save processor status
	phd					; save databank

	ldx !ram_195f
	cpx #$ffff			; exit when !ram_195f = $ffff
	beq .Exit

	lda #$80
	sta $2115			; vram control => $80, auto increment by 1 word on write high
	pea !ram_195f
	pld					; databank => !ram_195f
	%setAXYto16bit()
	lda $00
	sta $2116			; destination address => !ram_195f
	lda $02
	sta $2118			; write !ram_195f+2
	lda $04
	sta $2118			; write !ram_195f+4
	lda $00				; A => !ram_195f
	clc
	adc #$0020
	sta $2116			; destination address => A + $20
	lda $06
	sta $2118			; write !ram_195f+6
	lda $08
	sta $2118			; write !ram_195f+8
	lda #$ffff
	sta $00				; !ram_195f => $ffff

	.Exit
	pld					; restore databank
	plp					; restore processor status
	rts					; exit routine


; pc should equal $019778
	pullpc
;--------------------------------------------------------------------










;--------------------------------------------------------------------
	pushpc
	org $01c839


Routine01c839:
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
;--------------------------------------------------------------------











;--------------------------------------------------------------------
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
;--------------------------------------------------------------------








;--------------------------------------------------------------------
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
;--------------------------------------------------------------------









;--------------------------------------------------------------------
	pushpc
	org $01f849


; ROUTINE:  ($01f849)
; parameters:
;		ram $19f7 =>
; TODO: name this routine!!!

Routine01f849:
	%setAto8bit()
	01f84b inc $19f7
	01f84e jsr $82cf
	01f851 ldx $1900
	01f854 stx $1904
	01f857 ldx $1902
	01f85a stx $1906
	01f85d lda #$07
	01f85f sta $1a4c
	01f862 jsr $f8a5
	ldx #$0000			; loop counter
	.Loop {
	phx					; save counter
	%setAto16bit()
	01f86b lda $f891,x
	01f86e sta $1a14
	01f871 clc
	01f872 adc #$0400
	01f875 sta $1a16
	%setAto8bit()
	01f87a jsr $f8da

	plx					; restore counter
	inx
	inx					; counter += 2
	cpx #$0014			; loop until counter = $14
	bne .Loop
	}

	01f885 stz $1a4c
	01f888 lda #$15
	01f88a sta $1a4e
	01f88d stz $1a4f
	01f890 rts				; exit routine


; pc should equal $01f891
	pullpc
;--------------------------------------------------------------------












;--------------------------------------------------------------------
	pushpc
	org $01f977


; ROUTINE:  ($01f977)
; parameters:
;		!tilemap_x_offset
; XY => 16bit
Routine01f977:
	php					; save processor status
	%setAto8bit()
	ldx #$0000			; clear X
	ldy $192d			; Y => !tilemap_x_offset
	jsr $f99f
	plp					; restore processor status
	rts				; exit routine


; pc should equal $01f985
	pullpc
;--------------------------------------------------------------------
	pushpc
	org $01f985


; ROUTINE:  ($01f985)
;
; parameters:
;		!player_map_x =>
;		!graphics_mode_flags =>
;		!graphics_index =>
;		!graphics_param =>
; A => 8bit, XY => 16bit
; TODO: name this routine!!!!!!
Routine01f985:

; get offset into JumpTableTilemapCopySetup[]
	lda $19d7			; load !graphics_index
	asl a
	%setAto16bit()
	and #$0006
	tax					; x => (lower 2 bits of !graphics_index) * 2

	lda $0e89			; load !player_map_x
	%setAto8bit()
	clc
	adc $88c4,x
	xba
	clc
	adc $88c5,x
	xba
	tay					; Y=>

; continue into the following routine

; ROUTINE:  ($01f99f)
; parameters:
;		X => offset into JumpTableTilemapCopySetup[] and JumpTableTilemapCopySetup_2[]
;		Y =>
;

Routine01f985_Entry:
	01f99f jsr $fd50
	01f9a2 sty !ram_1a31
	01f9a5 sty !ram_1a2d

	ldy #$0000
	sty $1a2f			; clear !dma_offset

	lda !ram_19b4
	asl a
	asl a
	asl a
	asl a
	and #$80
	sta !ram_1a33			; !ram_1a33 => (bit 3 of !graphics_mode_flags = 1) ? $80 : $00

	lda $1a52
	sta !ram_1a34			; !ram_1a34 => !graphics_param

	phx					; save X
	jsr (JumpTableTilemapCopySetup,x)
	plx					; restore X

	01f9c5 lda $1a4c
	01f9c8 dec
	01f9c9 bne $f9fa
	01f9cb lda !ram_1a2d
	01f9ce clc
	01f9cf adc $1a56
	01f9d2 sta !ram_1a31
	01f9d5 lda $1a2e
	01f9d8 clc
	01f9d9 adc $1a57
	01f9dc sta $1a32
	01f9df ldy !ram_1a31

	01f9e2 jsr $fd50

	01f9e5 sty !ram_1a31
	01f9e8 ldy $1a4a
	01f9eb sty $1a2f
	01f9ee stz !ram_1a33
	01f9f1 lda $1a53
	01f9f4 sta !ram_1a34
	jsr (JumpTableTilemapCopySetup_2,x)
	rts					; exit routine


; pc should equal $01f9fb
	pullpc
;--------------------------------------------------------------------
	pushpc
	org $01f9fb		; pctosnes($00f9fb)


; DATA: Jump table for setting up tilemap data for writing one line ($01f9fb)
JumpTableTilemapCopySetup:
	dw TilemapCopySetup
	dw TilemapCopySetupVertical
	dw TilemapCopySetup
	dw TilemapCopySetupVertical
;	db $0b,$fa
;	db $ae,$fa
;	db $0b,$fa
;	db $ae,$fa


; pc should equal $01fa03
	pullpc
;--------------------------------------------------------------------
	pushpc
	org $01fa03 ; pctosnes($00fa03)


; DATA: Jump table for setting up tilemap data for writing one line ($01fa03)
JumpTableTilemapCopySetup_2:
	dw TilemapCopySetup_2
	dw TilemapCopySetupVertical_2
	dw TilemapCopySetup_2
	dw TilemapCopySetupVertical_2
;	db $49,$fb
;	db $ef,$fb
;	db $49,$fb
;	db $ef,$fb


; pc should equal $01fa0b
	pullpc
;--------------------------------------------------------------------
	pushpc
	org $01fa0b


; ROUTINE:  ($01fa0b)
;		in JumpTableTilemapCopySetup[]
;		source order: $8000,02,80,82
; parameters:
;		!ram_1924 =>
;		!ram_1a31 =>
;		!ram_1a33 =>
; A => 8bit, XY => 16bit
; TODO: name this routine!!!
TilemapCopySetup:
	ldy #$0000			; loop counter
	.Loop {
	phy					; save Y
	ldy !ram_1a31		; Y => !ram_1a31
	lda !ram_1a33		; A => !ram_1a33
	jsr $fc8e			; get values for $1a3d[0..7]
	ply					; restore Y

; copy $1a3d[0..3] to $0800[Y] and $1a3d[4..7] to $0880[Y]
	%setAto16bit()
	lda !ram_1a3d
	sta !tilemap_wram_source_start,y
	lda !ram_1a3d+2
	sta !tilemap_wram_source_start+2,y
	lda !ram_1a3d+4
	sta !tilemap_wram_source_start+$80,y
	lda !ram_1a3d+6
	sta !tilemap_wram_source_start+$82,y
	%setAto8bit()

; counter += 4
	iny
	iny
	iny
	iny

; increment !ram_1a31 then subtract !ram_1924 if that would be positive
	lda !ram_1a31			; A => !ram_1a31
	inc					; A += 1
	cmp !ram_1924			; if !ram_1924 > A then skip ahead
	bcc .Skip
	sec
	sbc !ram_1924			; A => A - !ram_1924
	.Skip
	sta !ram_1a31			; !ram_1a31 => A

	cpy #$0044			; loop until counter = $44
	bne .Loop
	}

	lda #$80			; $80 means increment destination address by 1 word (2 bytes) on write of high byte
	sta !tilemap_vram_control
	%setAto16bit()
	lda !ram_19bd
	eor #$ffff
	and #$000f
	inc
	asl a
	asl a								; A => ((inversed bits 0-3 of !ram_19bd) + 1) * 4
	sta !tilemap_dma_transfer_sizes
	sta !tilemap_dma_transfer_sizes+2
	lda #$0044
	sec
	sbc !tilemap_dma_transfer_sizes
	sta !tilemap_dma_transfer_sizes+4
	sta !tilemap_dma_transfer_sizes+6
	lda #!tilemap_wram_source_start
	sta !tilemap_wram_source_addresses
	clc
	adc !tilemap_dma_transfer_sizes
	sta !tilemap_wram_source_addresses+4
	lda #!tilemap_wram_source_start+$80
	sta !tilemap_wram_source_addresses+2
	clc
	adc !tilemap_dma_transfer_sizes+2
	sta !tilemap_wram_source_addresses+6

	jsr CalculateTilemapVramDestination

	sta !tilemap_vram_destination_addresses
	clc
	adc #$0020
	sta !tilemap_vram_destination_addresses+2
	eor #$0400
	and #$47c0
	sta !tilemap_vram_destination_addresses+4
	clc
	adc #$0020
	sta !tilemap_vram_destination_addresses+6
	%setAto8bit()
	rts					; exit routine

; pc should equal $01faae


	pullpc
;--------------------------------------------------------------------
	pushpc
	org $01faae


; ROUTINE:  ($01faae)
;		in JumpTableTilemapCopySetup[]
;		source order: $8000,80,02,82
; parameters:
;
; A => 8bit, XY => 16bit
; TODO: name this routine!!!
TilemapCopySetupVertical:
	ldy #$0000			; loop counter
	.Loop {
	phy					; save Y
	ldy !ram_1a31		; Y => !ram_1a31
	lda !ram_1a33		; A => !ram_1a33
	jsr $fc8e			; get values for $1a3d[0..7]
	ply					; restore Y

	%setAto16bit()
	lda !ram_1a3d
	sta !tilemap_wram_source_start,y
	lda !ram_1a3d+2
	sta !tilemap_wram_source_start+$80,y
	lda !ram_1a3d+4
	sta !tilemap_wram_source_start+2,y
	lda !ram_1a3d+6
	sta !tilemap_wram_source_start+$82,y
	%setAto8bit()

; counter += 4
	iny
	iny
	iny
	iny

; increment !ram_1a32 then subtract !ram_1925 if that would be positive
	lda !ram_1a32		; A => !ram_1a32
	inc					; A += 1
	cmp !ram_1925			; if !ram_1925 > A then skip ahead
	bcc .Skip
	sec
	sbc !ram_1925			; A => A - !ram_1925
	.Skip
	sta !ram_1a32			; !ram_1a32 => A

	cpy #$0040			; loop until counter = $40
	bne .Loop
	}

	lda #$81			; $81 means increment destination address by $20 words ($40 bytes) on write of high byte
	sta !tilemap_vram_control
	%setAto16bit()
	lda $19bf
	eor #$ffff
	and #$000f
	inc
	asl a
	asl a								; A => ((inversed bits 0-3 of !ram_19bf) + 1) * 4
	sta !tilemap_dma_transfer_sizes
	sta !tilemap_dma_transfer_sizes+2
	lda #$0040
	sec
	sbc !tilemap_dma_transfer_sizes
	sta !tilemap_dma_transfer_sizes+4
	sta !tilemap_dma_transfer_sizes+6
	lda #!tilemap_wram_source_start
	sta !tilemap_wram_source_addresses
	clc
	adc !tilemap_dma_transfer_sizes
	sta !tilemap_wram_source_addresses+4
	lda #!tilemap_wram_source_start+$80
	sta !tilemap_wram_source_addresses+2
	clc
	adc !tilemap_dma_transfer_sizes+2
	sta !tilemap_wram_source_addresses+6

	jsr CalculateTilemapVramDestination

	sta !tilemap_vram_destination_addresses
	inc
	sta !tilemap_vram_destination_addresses+2
	dec
	and #$441e					; TODO: what does this mask do
	sta !tilemap_vram_destination_addresses+4
	inc
	sta !tilemap_vram_destination_addresses+6
	%setAto8bit()
	rts					; exit routine


; pc should equal $01fb49
	pullpc
;--------------------------------------------------------------------
	pushpc
	org $01fb49


; ROUTINE:  ($01fb49)
;		in JumpTableTilemapCopySetup_2[]
;		source order: $9000,02,80,82
; parameters:
;
; A => 8bit, XY => 16bit
; TODO: name this routine!!!
TilemapCopySetup_2:
	ldy #$0000			; loop counter
	.Loop {
	phy					; save Y
	ldy !ram_1a31		; Y => !ram_1a31
	lda !ram_1a33		; A => !ram_1a33
	jsr $fc8e			; get values for $1a3d[0..7]
	ply					; restore Y

; copy $1a3d[0..3] to $0900[Y] and $1a3d[4..7] to $0980[Y]
	%setAto16bit()
	lda !ram_1a3d
	sta !tilemap_wram_source_start_2,y
	lda !ram_1a3d+2
	sta !tilemap_wram_source_start_2+2,y
	lda !ram_1a3d+4
	sta !tilemap_wram_source_start_2+$80,y
	lda !ram_1a3d+6
	sta !tilemap_wram_source_start_2+$82,y
	%setAto8bit()

; counter += 4
	iny
	iny
	iny
	iny

	lda !ram_1a31		; A => !ram_1a31
	inc					; A += 1
	cmp !ram_1924			; if !ram_1924 > A then skip ahead
	bcc .Skip
	sec
	sbc !ram_1924			; A => A - !ram_1924
	.Skip
	sta !ram_1a31			; !ram_1a31 => A
	cpy #$0044			; loop until counter = $44
	bne .Loop
	}

	lda #$80			; $80 means increment destination address by 1 word (2 bytes) on write of high byte
	sta !tilemap_vram_control_2
	%setAto16bit()
	lda !ram_19bd
	eor #$ffff
	and #$000f
	inc
	asl a
	asl a								; A => ((inversed bits 0-3 of !ram_19bd) + 1) * 4
	sta !tilemap_dma_transfer_sizes_2
	sta !tilemap_dma_transfer_sizes_2+2
	lda #$0044
	sec
	sbc !tilemap_dma_transfer_sizes_2
	sta !tilemap_dma_transfer_sizes_2+4
	sta !tilemap_dma_transfer_sizes_2+6
	lda #!tilemap_wram_source_start_2
	sta !tilemap_wram_source_addresses_2
	clc
	adc !tilemap_dma_transfer_sizes_2
	sta !tilemap_wram_source_addresses_2+4
	lda #!tilemap_wram_source_start_2+$80
	sta !tilemap_wram_source_addresses_2+2
	clc
	adc !tilemap_dma_transfer_sizes_2+2
	sta !tilemap_wram_source_addresses_2+6

	jsr CalculateTilemapVramDestination

	ora #$0800
	sta !tilemap_vram_destination_addresses_2
	clc
	adc #$0020
	sta !tilemap_vram_destination_addresses_2+2
	eor #$0400
	and #$4fc0
	sta !tilemap_vram_destination_addresses_2+4
	clc
	adc #$0020
	sta !tilemap_vram_destination_addresses_2+6
	%setAto8bit()
	rts				; exit routine


; pc should equal $01fbef
	pullpc
;--------------------------------------------------------------------
	pushpc
	org $01fbef


; ROUTINE:  ($01fbef)
;		in JumpTableTilemapCopySetup_2[]
;		source order: $9000,80,02,82
; parameters:
;		!ram_1a31
;		!ram_1a32
;		!ram_1a33
;		!ram_1925
; A => 8bit, XY => 16bit
; TODO: name this routine!!!
TilemapCopySetupVertical_2:
	ldy #$0000			; loop counter
	.Loop {
	phy					; save Y
	ldy !ram_1a31		; Y => !ram_1a31
	lda !ram_1a33		; A => !ram_1a33
	jsr $fc8e			; get values for $1a3d[0..7]
	ply					; restore Y

; copy $1a3d[0..3] to $0900[Y] and $1a3d[4..7] to $0980[Y] TODO: fix comment
	%setAto16bit()
	lda !ram_1a3d
	sta !tilemap_wram_source_start_2,y
	lda !ram_1a3d+2
	sta !tilemap_wram_source_start_2+$80,y
	lda !ram_1a3d+4
	sta !tilemap_wram_source_start_2+2,y
	lda !ram_1a3d+6
	sta !tilemap_wram_source_start_2+$82,y
	%setAto8bit()

; counter += 4
	iny
	iny
	iny
	iny

; increment !ram_1a32 then subtract !ram_1925 if that would be positive
	lda !ram_1a32		; A => !ram_1a32
	inc					; A += 1
	cmp !ram_1925			; if !ram_1925 > A then skip ahead
	bcc .Skip
	sec
	sbc !ram_1925			; A => A - !ram_1925
	.Skip
	sta !ram_1a32			; !ram_1a32 => A

	cpy #$0040			; loop until counter = $40
	bne .Loop
	}

	lda #$81			; $81 means increment destination address by $20 words ($40 bytes) on write of high byte
	sta !tilemap_vram_control_2
	%setAto16bit()
	lda !ram_19bf
	eor #$ffff
	and #$000f
	inc
	asl a
	asl a								; A => ((inversed bits 0-3 of !ram_19bf) + 1) * 4
	sta !tilemap_dma_transfer_sizes_2
	sta !tilemap_dma_transfer_sizes_2+2
	lda #$0040
	sec
	sbc !tilemap_dma_transfer_sizes_2
	sta !tilemap_dma_transfer_sizes_2+4
	sta !tilemap_dma_transfer_sizes_2+6
	lda #!tilemap_wram_source_start_2
	sta !tilemap_wram_source_addresses_2
	clc
	adc !tilemap_dma_transfer_sizes_2
	sta !tilemap_wram_source_addresses_2+4
	lda #!tilemap_wram_source_start_2+$80
	sta !tilemap_wram_source_addresses_2+2
	clc
	adc !tilemap_dma_transfer_sizes_2+2
	sta !tilemap_wram_source_addresses_2+6

	jsr CalculateTilemapVramDestination

	ora #$0800
	sta !tilemap_vram_destination_addresses_2
	inc
	sta !tilemap_vram_destination_addresses_2+2
	dec
	and #$4c1e					; TODO: what does this mask do
	clc
	sta !tilemap_vram_destination_addresses_2+4
	inc
	sta !tilemap_vram_destination_addresses_2+6
	%setAto8bit()
	rts					; exit routine


; pc should equal $01fc8e
	pullpc
;--------------------------------------------------------------------
	pushpc
	org $01fc8e


; ROUTINE:  ($01fc8e)
; parameters:
;		A =>
;		Y =>
;		!ram_1924 =>
;		!dma_offset =>
;		!ram_1a34 =>
;		$7f8000[] =>
;		$7fcef4[] =>
;		$7ff274[] =>
; returns:
;		ram $1a3d[] => 8 bytes
; A => 8bit, XY => 16bit
; TODO: name this routine!!!!!!!!!!
Routine01fc8e:
	sta $1a3a			; !temp_accumulator => A

; multiply Y.high * !ram_1924
	%setAto16bit()
	tya					; A => Y
	%setAto8bit()
	xba					; A => Y.high
	sta $4202			; WRMPYA => A
	lda !ram_1924
	sta $4203			; WRMPYB => !ram_1924

	xba					; A => Y.low
	%setAto16bit()
	and #$003f			; lower 6 bits
	clc
	adc $4216			; A => A + multiplication result
	clc
	adc $1a2f			; A => A + !dma_offset
	tax					; X => A

	lda #$0000
	%setAto8bit()
	lda $7f8000,x		; A => $7f8000[X]
	eor $1a3a			; A => A xor !temp_accumulator
	bpl .Skip
	lda #$80			; if result < 0, use $80

	.Skip
	%setAto16bit()
	and #$007f			; lower 7 bits
	tay					; Y => A
	asl a
	asl a				; A => A * 4
	tax					; X => A
	lda $7fcef4,x
	sta $1a35			; !tile_data_temp_1 => $7fcef4[x]
	lda $7fcef6,x
	sta $1a37			; !tile_data_temp_1[2] => $7fcef4[x+2]
	%setAto8bit()

	tyx					; X => Y
	lda $7fd0f4,x
	sta $1a39			; !tile_lookup_value => $7fcef4[x]
	sta $1a3c			; !tile_data_copy => $7fcef4[x]
	bpl .Skip2

	and #$70			; bits 4-6
	lsr a
	lsr a				; A => A / 4
	sta $1a3b			; !tile_calc_result => A

	.Skip2
	%setXYto8bit()

	ldx #$00			; loop offset
	txy					; loop counter
	.Loop {
	lda $1a35,y
	sta $1a3d,x			; !tile_data_temp_1[Y]
	phx					; save X
	tax					; X => !tile_data_temp_1[Y]

; move bit 1 to bit 6 and clear other bits TODO: WRONG
	lsr $1a3c			; A => A / 2
	ror a
	ror a				; rotate right 2
	and #$40			; bit 6
	xba					; save for later

	lda $1a39			; load !tile_lookup_value
	bmi .Skip3			; skip if negative

	lda $7ff274,x
	asl a
	asl a
	sta $1a3b			; !tile_calc_result => $7ff274[X] * 4

	.Skip3
	xba					; swap in saved byte
	plx					; restore X

	ora !ram_1a34		; OR in !ram_1a34
	ora $1a3b			; OR in !tile_calc_result
	sta $1a3e,x			; !tile_data_array[][X+1] => A

	inx
	inx					; loop offset += 2
	iny					; increment loop
	cpy #$04			; loop until counter = $4
	bne .Loop
	}

	%setXYto16bit()
	rts					; exit routine


; pc should equal $01fd24
	pullpc
;--------------------------------------------------------------------
	pushpc
	org $01fd24


; ROUTINE: Calculate tilemap vram destination address ($01fd24)
;		A => !ram_19bf * $40 + ($4000 or $4400 based on bit 4 of !ram_19bd)
; parameters:
;		!ram_19bf => this * $40 is the base address
;		!ram_19bd => bit 4 determines which offset to use
; returns:
;		A => vram destination address
CalculateTilemapVramDestination:
	%setAto8bit()
	ldx #$0000			; X => $00
	lda !ram_19bf
	sta $4202			; WRMPYA => !ram_19bf
	lda #$40
	sta $4203			; WRMPYB => $40

	lda !ram_19bd		; A => !ram_19bd
	bit #$10
	beq .Skip			; if bit 4 = 0, then don't add 2
	inx
	inx					; X += 2
	.Skip

	asl a				; A => A * 2
	%setAto16bit()
	and #$001e			; bits 1-4
	clc
	adc.w DataCalculateTilemapVramDestination_Offset,x			; A += $fd4c[X], $fd4c is directly after this routine TODO: make sure label results in correct instructions
	clc
	adc $4216			; A += !ram_19bf * $40
	rts					; exit routine


; pc should equal $01fd4c
	pullpc;--------------------------------------------------------------------
	pushpc
	org pctosnes($00fd4c)


; DATA: word is offset used above ($01fd4c)
;		bit 4 of !ram_19bd determines which offset to use
DataCalculateTilemapVramDestination_Offset:
	db $00,$40,$00,$44


; pc should equal $01fd50
	pullpc
;--------------------------------------------------------------------
	pushpc
	org $01fd50


; ROUTINE:  ($01fd50)
;		Y.high => (Y.high < 0) ? (Y.high + !ram_1925) : (Y.high - !ram_1925)
;		Y.low => (Y.low < 0) ? (Y.low + !ram_1924) : (Y.low - !ram_1924)
; parameters:
;		Y =>
;		!ram_1924 =>
;		!ram_1925 =>
; returns:
;		Y =>
; TODO: Name this routine!!!!!!!!!
Routine01fd50:

	%setAto16bit()
	tya					; A => Y
	%setAto8bit()

	.SetHigh
	xba					; get Y.high
	bpl .PositiveHigh

	.NegativeHigh
	clc
	adc !ram_1925			; A => A + !ram_1925
	bra .SetLow

	.PositiveHigh
	cmp !ram_1925
	bcc .SetLow
	sec
	sbc !ram_1925			; A => A - !ram_1925

	.SetLow
	xba					; get Y.low
	bpl .PositiveLow

	.NegativeLow
	clc
	adc !ram_1924			; A => A + !ram_1924
	bra .End

	.PositiveLow
	cmp !ram_1924
	bcc .End
	sec
	sbc !ram_1924			; A => A - !ram_1924

	.End
	tay				; Y => A
	rts				; exit routine


; pc should equal $01fd7b
	pullpc
;--------------------------------------------------------------------
	pushpc
	org $01fd7b


; ROUTINE: Copy tile data to WRAM ($01fd7b)
;		Copies two sets of tiles into WRAM
;			1. destination => $7f:d274-‭$7f:f273‬ in $400 byte chunks
;				when map_chunk_control is negative, the chunk is all $00
;				else, copy tiles from source address offset => $05:8c80 + ($0300 * map_chunk_control)
;			2. destination => $7f:f274-$7f:f373 in $20 byte chunks
;				source address offset => $05:f280 + (map_chunk_control * $10)
;				bottom 3 bits of each source nibble (low then high) becomes output byte
;					so $42 => $02 $04
;					and $ca => $02 $04
;				TODO: are these tiles?
;		(for certain maps, like first map "Level Forest") TODO: what all calls this?
; parameters:
;		ram $191a-1921 => values for map_chunk_control
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
	lda $191a,x			; variable: map_chunk_control, get value from $191a+x (lowram) TODO: trace this ram value
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
	xba					; save map_chunk_control
	stz $211b
	lda #$03
	sta $211b			; set [M7A] = $0300
	xba					; swap map_chunk_control back in
	sta $211c			; set [M7B] = map_chunk_control

	%setAto16bit()
	lda #$8c80			; source address base (label DataTiles)
	clc
	adc $2134			; source address offset => $8c80 + ($0300 * map_chunk_control)
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
	lda $191a,x			; variable: map_chunk_control, get value from $191a+x (lowram) TODO: trace this ram value
	phx					; save loop counter

; determine source address offset
	sta $211b
	stz $211b			; set [M7A] = $00(map_chunk_control)
	lda #$10
	sta $211c			; set [M7B] = $10
	ldy $2134			; source address offset => map_chunk_control * $10

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
	pullpc;--------------------------------------------------------------------









;--------------------------------------------------------------------
	pushpc
	org $01ffc1


; ROUTINE:  ($01ffc1)
;
; parameters:
;		!player_map_x
;		!player_map_y
; A => 8bit, XY => 16bit
; TODO: Name this routine!!!!!!!!!

Routine01ffc1:
;
	lda $0e89			; load !player_map_x
	sec
	sbc #$08
	sta $192d			; !tilemap_x_offset => !player_map_x - $8

;
	lda $0e8a			; load !player_map_y
	sec
	sbc #$06
	sta $192e			; !tilemap_y_offset => !player_map_y - $6

;
	ldx #$000f
	stx !ram_19bf			; !ram_19bf => $000f

	ldx #$0000			; loop counter
	stx !ram_19bd			; clear !ram_19bd

	.Loop {
	phx					; save counter
	01ffe0 jsr $f977
	jsr CopyTilemapFromWRAMToVRAM
	inc $192e			; increment !tilemap_y_offset

	plx					; restore counter
	stx !ram_19bf			; !ram_19bf => counter
	inx					; increment counter
	cpx #$000d			; loop until counter = $d
	bne .Loop
	}

	ldx #$0000
	stx !ram_19bf			; clear !ram_19bf

	rts					; exit routine


; pc should equal $01fffa
	pullpc
;--------------------------------------------------------------------











;--------------------------------------------------------------------
;						BANK $02
;--------------------------------------------------------------------








;--------------------------------------------------------------------
	pushpc
	org $02e34e


; ROUTINE: Write32ZerosToWram ($02e34e)
; $2181-$2183 should be set to wram destination address
Write32ZerosToWram:
	php					; save processor status
	%setAto8bit()

	!counter = 0
	while !counter < $20
	stz $80

	!counter #= !counter+1
	endif

	plp					; restore processor status
	rts					; exit routine


; pc should equal $02e393
	pullpc
;--------------------------------------------------------------------








;--------------------------------------------------------------------
;						BANK $07
;--------------------------------------------------------------------




;--------------------------------------------------------------------
	pushpc
	org $07af3b		; pctosnes($03af3b)


; DATA:  ($07af3b)
;		table of 16bit offset pointers into $07b013[]
; TODO: what is this?
; TODO: does it actually consist of all $200 bytes?
; TODO: another table starts at $07b013, so cut off data there?
Data07af3b:
	db $00,$00,$00,$00,$09,$00,$09,$00,$09,$00,$09,$00,$12,$00,$68,$00
	db $0b,$01,$29,$01,$7f,$01,$c7,$01,$d7,$01,$34,$02,$b4,$02,$3b,$03
	db $83,$03,$b6,$03,$0c,$04,$2a,$04,$aa,$04,$4d,$05,$d4,$05,$46,$06
	db $5d,$06,$90,$06,$ca,$06,$ef,$06,$37,$07,$d3,$07,$61,$08,$b7,$08
	db $1b,$09,$47,$09,$c7,$09,$63,$0a,$06,$0b,$a9,$0b,$4c,$0c,$e1,$0c
	db $3e,$0d,$3e,$0d,$63,$0d,$a4,$0d,$bb,$0d,$e7,$0d,$05,$0e,$38,$0e
	db $79,$0e,$9e,$0e,$25,$0f,$ba,$0f,$5d,$10,$ac,$10,$d1,$10,$4a,$11
	db $ca,$11,$12,$12,$a7,$12,$4a,$13,$d8,$13,$6d,$14,$02,$15,$97,$15
	db $d8,$15,$43,$16,$5a,$16,$86,$16,$29,$17,$cc,$17,$6f,$18,$b0,$18
	db $53,$19,$be,$19,$61,$1a,$b0,$1a,$1b,$1b,$2b,$1b,$49,$1b,$59,$1b
	db $fc,$1b,$9f,$1c,$42,$1d,$c9,$1d,$5e,$1e,$f3,$1e,$96,$1f,$32,$20
	db $c7,$20,$5c,$21,$ff,$21,$1d,$22,$3b,$22,$59,$22,$77,$22,$95,$22
	db $b3,$22,$d8,$22,$82,$23,$1e,$24,$c1,$24,$25,$25,$2e,$25,$c3,$25
	db $51,$26,$ed,$26,$f6,$26,$84,$27


; pc should equal $07b013
	pullpc
;--------------------------------------------------------------------








;--------------------------------------------------------------------
	pushpc
	org $07f7c3		; pctosnes($03f7c3)

; DATA:  ($07f7c3)
Data07f7c3:
	db $35,$7e,$0e,$23,$08,$1f,$16,$1f,$22,$19,$29,$13,$2e,$15,$37,$0f
	db $33,$0d,$2d,$09,$24,$10,$1f,$10,$1a,$17,$1a,$13,$1a,$0e,$0f,$0c
	db $09,$0c,$10,$08,$1f,$0a,$2e,$29,$33,$28,$19,$2a,$0e,$28,$12,$26
	db $0e,$1e,$0e,$1a,$1c,$21,$1f,$1d,$24,$13,$30,$11,$37,$0b,$28,$18
	db $2d,$0e,$2d,$06,$34,$18,$1f,$15,$1f,$1b,$1c,$1b,$15,$0c,$09,$08
	db $0f,$10,$18,$08,$19,$05,$1d,$1e,$1f,$1f,$26,$1f,$28,$27,$28,$29
	db $35,$23,$3b,$28,$3c,$24,$35,$1e,$31,$1e,$1c,$27,$21,$2a,$31,$1c
	db $1c,$28,$2a,$25

; pc should equal $07f837

; end of bank, fill
	padbyte $ff
	pad $07ffff

; TODO: did last byte fill?
;pad $088000

	pullpc
;--------------------------------------------------------------------









;--------------------------------------------------------------------
;						BANK $0b
;--------------------------------------------------------------------





;--------------------------------------------------------------------
	pushpc
	org $0b8149

; ROUTINE:  ($0b8149)
;
; A is 8bit, XY is 16bit
; TODO: rename!!!!!!!!
Routine0b8149:
; setup variables
	stz $19f6			; !map_param_zero => $00
	lda #$80
	sta !ram_19a5			; @var_19a5 => $80
	lda #$01
	sta $1a45			; !graphics_init_flag => $01
	ldx $19f1			; load !map_param_2
	stx $0e89			; !player_map_x => !map_param_2
	lda $19f0			; load !map_param_1
	sta $0e91			; !tilemap_counter => !map_param_1
	bne .IsZero			; if !map_param_1 is $0000

	lda #$f2
	jsl TRBWithBitMaskTo0ea8		; set !dma_control_flags =>

	stz $1a5b			; !temp_zero_flag => $00

	lda !context_param			; load graphics context parameter
	%setAto16bit()
	and #$00ff			; ignore upper byte

	asl a
	tax
	lda Data07f7c3,x
	sta $0e89			; !player_map_x =>
	%setAto8bit()
	lda #$f3
	jsl ANDBitMaskAnd0ea8ToA
	bne .IsZero
	lda #$02
	sta $0e8b			; !player_map_x => $02

; clear $0ec8-$0ee7 and $0f28-$0f47
	ldx #$0000
	lda #$20			; loop counter
	.Loop {
	stz $0ec8,x			; !dma_channel_array[x] => $00
	stz $0f28,x			; !vram_transfer_array[x] => $00
	inx					; increment destination offset
	dec					; decrement counter
	bne .Loop
	}

; clear $0ee8-$0f17
	lda #$30			; loop counter
	.LoopB {
	stz $0ec8,x			; !dma_channel_array[x] => $00
	inx					; increment destination offset
	dec					; decrement counter
	bne .LoopB
	}

	.IsZero

;
	lda $0e91			; load !tilemap_counter
	%setAto16bit()
	and #$00ff			; ignore upper byte
	asl a
	tax					; source offset => !tilemap_counter * 2
	lda Data07af3b,x
	tax					; source offset => Data07af3b[!tilemap_counter * 2]
	%setAto8bit()
	stx $19b5			; !data_source_offset => source offset

;
	ldy #$0000			; loop counter
	.LoopC {
	lda Data07b013,x	;
	sta $1910,y			; !graphics_table_data[y] => Data07b013[x]
	inx					; increment source offset
	iny					; increment counter
	cpy #$0007			; loop until counter = $7
	bne .LoopC
	}

; determine source address offset
; !source_address_index is source address index
	lda #$0a
	sta $211b
	stz $211b			; set [M7A] => $000a
	lda $1911
	sta $211c			; set [M7B] => !source_address_index
	ldx $2134
	stx $19b7			; source address offset => !source_address_index * $0a

; copy $a bytes into !tileset_copy_buffer[]
	ldy #$0000			; loop counter
	.LoopD {
	lda.l DataTilesets,x
	sta $1918,y			; !tileset_copy_buffer[y] => DataTilesets[x]
	inx					; increment source offset
	iny					; increment counter
	cpy #$000a			; loop until counter = $a
	bne .LoopD
	}

	ldx #$ffff			; default !source_pointer value is $ffff
	lda $1912
	cmp #$ff
	beq .Skip			; skip ahead if !source_offset_index is $ff

	%setAto16bit()
	and #$00ff			; ignore upper byte
	asl a				; A => A * 2
	tax					; source address offset => !source_offset_index * 2
	lda.l Data0b8892,x
	tax
	%setAto8bit()

	.Skip
	stx $19b9			; !source_pointer => X

	lda $1916			; load !graphics_param_2
	and #$e0			; bits 5-7
	lsr a
	lsr a				; A => A / 8
	lsr a
	sta $1a55			; !packed_graphics_flags => A

	lda $1915			; load !graphics_param_1
	and #$e0			; bits 5-7
	ora $1a55			; combine with other 3 bits
	lsr a
	lsr a				; A => A / 4
	sta $1a55			; !packed_graphics_flags => byte made of: two 0 bits, top three bits of !graphics_param_1, top three bits of !graphics_param_2

	rtl					; exit routine


; pc should equal $0b8223
	pullpc
;--------------------------------------------------------------------






;--------------------------------------------------------------------
	pushpc
	org $0b8892		; pctosnes($058892)


; DATA:  ($0b8892)
Data0b8892:

; TODO: get the data


; pc should equal $
	pullpc
;--------------------------------------------------------------------









;--------------------------------------------------------------------
	pushpc
	org $0b8cd9		; pctosnes($058cd9)


; DATA:  ($0b8cd9)
;		accessed in $a byte chunks
;		bytes $00-$01 are ??? TODO: what are these
;		bytes $2-$9 of each are indexes into tile graphics data (label = DataTiles)
;			values $00-$21 are indexes, $ff means clear section
;		ends up in $1918-$1921
DataTilesets:
	db $b0,$16,$1e,$1f,$20,$21,$ff,$ff,$ff,$ff
	db $b0,$17,$1e,$1f,$20,$21,$ff,$ff,$ff,$ff
	db $52,$11,$00,$01,$02,$03,$04,$05,$06,$07
	db $73,$01,$00,$01,$02,$03,$04,$05,$06,$07
	db $94,$04,$08,$09,$0a,$0b,$0c,$05,$06,$07
	db $52,$03,$00,$01,$02,$03,$04,$05,$06,$07
	db $75,$19,$08,$09,$0a,$0b,$0c,$1c,$15,$07
	db $f1,$11,$00,$01,$02,$09,$06,$07,$11,$13
	db $f6,$0a,$18,$1b,$1c,$1d,$04,$07,$ff,$ff
	db $fd,$0b,$08,$09,$0a,$03,$04,$18,$12,$13
	db $be,$07,$08,$09,$0a,$0b,$0c,$0d,$04,$1d
	db $6e,$07,$08,$09,$0a,$0b,$0c,$0d,$04,$1d
	db $74,$07,$08,$09,$0a,$0b,$0c,$0d,$15,$07
	db $f9,$09,$1a,$1b,$0a,$10,$0c,$ff,$ff,$ff
	db $f9,$09,$1a,$1b,$0a,$10,$0c,$ff,$ff,$ff
	db $51,$0e,$00,$01,$02,$09,$06,$07,$11,$13
	db $fe,$07,$08,$09,$0a,$0b,$0c,$0d,$15,$07
	db $df,$08,$18,$19,$1a,$11,$04,$ff,$ff,$07
	db $ff,$08,$18,$19,$1a,$11,$04,$ff,$ff,$07
	db $f5,$06,$16,$17,$18,$01,$07,$ff,$ff,$ff
	db $f6,$0a,$18,$1b,$1c,$1d,$04,$07,$ff,$ff
	db $b6,$0a,$18,$1b,$1c,$1d,$04,$07,$ff,$ff
	db $7d,$0b,$08,$09,$0a,$03,$04,$18,$12,$13
	db $f7,$0c,$18,$1d,$02,$03,$04,$12,$13,$07
	db $77,$0c,$18,$1d,$02,$03,$04,$12,$13,$07
	db $f8,$0d,$04,$06,$14,$15,$11,$18,$1d,$07
	db $f8,$0d,$04,$06,$14,$15,$11,$18,$1d,$07
	db $fb,$14,$13,$01,$02,$03,$04,$06,$18,$09
	db $51,$0e,$00,$01,$02,$09,$06,$07,$11,$13
	db $5a,$0f,$00,$01,$02,$18,$04,$13,$06,$07
	db $fc,$05,$0e,$0f,$10,$11,$15,$05,$ff,$ff
	db $fb,$12,$13,$01,$02,$03,$04,$06,$18,$11
	db $ec,$05,$0e,$0f,$10,$11,$15,$05,$ff,$ff
	db $f7,$13,$16,$18,$02,$03,$04,$ff,$13,$07
	db $f8,$0d,$04,$06,$14,$15,$11,$18,$1d,$07
	db $a6,$0a,$18,$1b,$1c,$1d,$04,$07,$ff,$ff
	db $a7,$0c,$18,$1d,$02,$03,$04,$12,$13,$07
	db $a8,$0d,$04,$06,$14,$15,$11,$18,$1d,$07
	db $58,$10,$04,$06,$14,$15,$11,$18,$1d,$07
	db $5d,$10,$0d,$06,$14,$15,$1b,$18,$1d,$07
	db $54,$04,$08,$09,$0a,$0b,$0c,$05,$06,$07
	db $5d,$10,$0d,$06,$14,$15,$1b,$18,$1d,$07
	db $5e,$07,$08,$09,$0a,$0b,$0c,$0d,$04,$1d
	db $51,$0e,$00,$01,$02,$09,$06,$07,$11,$13


; pc should equal $0b8e91
	pullpc
;--------------------------------------------------------------------











;--------------------------------------------------------------------
;						BANK $0c
;--------------------------------------------------------------------











;--------------------------------------------------------------------
	pushpc
	org $0c8948


; ROUTINE: Clear OAM ($0c8948)
;		fills all $220 bytes of OAM from $000c00+ on DMA channel 5
;		sets data bank to $0c
;		A becomes 8bit
; known uses:
;		fill OAM with $55 - moves all sprites small and to the left of the screen (can't see any sprites)
; XY => 16bit
ClearOAM:
	%setAto8bit()
	ldx #$0000
	stx $2102			; destination => $0000
	ldx #$0400			; dma control => $00, auto increment, write same address twice
	stx $4350			; destination => $04, OAM data register [OAMDATA]

	ldx #$0c00
	stx $4352			; source offset => $0c00
	lda #$00
	sta $4354			; source bank => $00
	ldx #$0220
	stx $4355			; dma transfer size => $220 (all of OAM will be written)
	lda #$20
	sta $420b			; start DMA transfer on channel 5
	phk
	plb					; databank => program bank, $0c
	rts					; exit routine


; pc should equal $0c896f
	pullpc
;--------------------------------------------------------------------

