








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
	tcd					; set direct page => $2100, so direct mode writes are to the registers
	%setAto8bit()

	; 
	; TODO: address translation in vram write, 8bit mode. lda #$84 / sta $15. tile data or map data?
	ldx #$1801			; $01 means write 2 bytes each time
						; $18 means destination is $2118 VRAM register  
	stx $4350			; write dma control and destination registers

	; setup source => $07:8030
	ldx #$8030
	stx $4352				; set source address offset => $8030
	lda #$07
	sta $4354				; set source address bank => $07

	ldx #$1000
	stx $4355			; set DMA transfer size to $1000 bytes
	ldx #$3000
	stx $16				; set vram destination address => $3000
	lda #$84			; $84 means increment address on write high byte, translation = 8bit, increment address by 1 word
	sta $15				; set video port control [VMAIN]
	lda #$20
	sta $420b			; start DMA transfer on channel 5

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
	ldx !MENU_COLOR_LOW
	ldy !MENU_COLOR_HIGH
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






pushpc
org $0183be

; ROUTINE: Copy Tilemap from WRAM to VRAM ($0183be)
;		copy two sections from WRAM to VRAM through DMA (channel 0)
;		each section can have 4 copys
; parameters:
;		@var_1a4c => if $01 then call second copy routine    TODO: verify
;		ram $19fa - $1a12 => parameters for first copy
;		ram $1a13 - $1a2b => parameters for second copy
CopyTilemapFromWRAMToVRAM:
	jsr CopyTilemapFromWRAMToVRAM_1

	; skip second copy if @var_1a4c = $01
	lda $1a4c			; load @var_1a4c
	dec
	bne .Exit

	jsr CopyTilemapFromWRAMToVRAM_2

	.Exit
		rts					; exit routine

; pc should equal $0183cb

pullpc

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

pullpc

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
	ldx #$0000		; setup X as a counter starting at $0000
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
		rts				; exit routine

; pc should equal $018435

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
org $01f977

; ROUTINE:  ($01f977)
; parameters:
;		@var_192d
; XY => 16bit

Routine01f977:

	php					; save processor status
	%setAto8bit()
	ldx #$0000			; clear X
	ldy $192d			; Y => @var_192d
	jsr $f99f
	plp					; restore processor status
	rts				; exit routine

; pc should equal $01f985

pullpc

pushpc
org $01f985

; ROUTINE:  ($01f985)
;		
; parameters:
;		@var_0e89 => 
;		@var_19b4 => 
;		@var_19d7 => 
;		@var_1a52 => 
; A => 8bit, XY => 16bit
; TODO: name this routine!!!!!!
Routine01f985:

	; get offset into jump table $01f9fb[]
	lda $19d7			; load @var_19d7
	asl a
	%setAto16bit()
	and #$0006
	tax					; x => (lower 2 bits of @var_19d7) * 2

	lda $0e89			; load @var_0e89
	%setAto8bit()
	clc
	adc $88c4,x
	xba
	clc
	adc $88c5,x
	xba
	tay					; Y=> 

	; continue into the following routine



; pc should equal $01f9fa

pullpc





pushpc
org $01fa0b
; ROUTINE:  ($01fa0b)
;		in jump table Jumpf9fb[]
; parameters:
;		@var_1924 => 
;		!ram_1a31 => 
;		!ram_1a33 => 
; A => 8bit, XY => 16bit
; TODO: name this routine!!!
Routine01fa0b:

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

		; increment !ram_1a31 then subtract @var_1924 if that would be positive
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

	jsr CalculateTilemapVramDestinationAddress

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




pushpc
org $01fb49

; ROUTINE:  ($01fb49)
;		in jump table Jumpfa03[]
; parameters:
;		
; A => 8bit, XY => 16bit
; TODO: name this routine!!!

Routine01fb49:
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
		cmp $1924			; if @var_1924 > A then skip ahead
		bcc .Skip
		sec
		sbc !ram_1924		; A => A - !ram_1924
		.Skip
		sta !ram_1a31		; !ram_1a31 => A
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

	jsr CalculateTilemapVramDestinationAddress

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
pushpc
org $01fbef

; ROUTINE:  ($01fbef)
;		in jump table Jumpfa03[]
; parameters:
;		!ram_1a31
;		!ram_1a32
;		!ram_1a33
;		!ram_1925
; A => 8bit, XY => 16bit
; TODO: name this routine!!!

Routine01fbef:
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

	jsr CalculateTilemapVramDestinationAddress

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
pushpc
org $01fc8e

; ROUTINE:  ($01fc8e)
; parameters:
;		A => 
;		Y => 
;		@var_1924 => 
;		@var_1a2f => 
;		@var_1a34 => 
;		$7f8000[] => 
;		$7fcef4[] => 
;		$7ff274[] => 
; returns:
;		ram $1a3d[] => 8 bytes
; A => 8bit, XY => 16bit
; TODO: name this routine!!!!!!!!!!

Routine01fc8e:
	sta $1a3a			; @var_1a3a => A

	; multiply Y.high * @var_1924
	%setAto16bit()
	tya					; A => Y
	%setAto8bit()
	xba					; A => Y.high
	sta $4202			; WRMPYA => A
	lda $1924
	sta $4203			; WRMPYB => @var_1924

	xba					; A => Y.low
	%setAto16bit()
	and #$003f			; lower 6 bits
	clc
	adc $4216			; A => A + multiplication result
	clc
	adc $1a2f			; A => A + @var_1a2f
	tax					; X => A

	lda #$0000
	%setAto8bit()
	lda $7f8000,x		; A => $7f8000[X]
	eor $1a3a			; A => A xor @var_1a3a
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
	sta $1a35			; @var_1a35 => $7fcef4[x]
	lda $7fcef6,x
	sta $1a37			; @var_1a35[2] => $7fcef4[x+2]
	%setAto8bit()

	tyx					; X => Y
	lda $7fd0f4,x
	sta $1a39			; @var_1a39 => $7fcef4[x]
	sta $1a3c			; @var_1a3c => $7fcef4[x]
	bpl .Skip2

	and #$70			; bits 4-6
	lsr a
	lsr a				; A => A / 4
	sta $1a3b			; @var_1a3b => A

	.Skip2
	%setXYto8bit()

	ldx #$00			; loop offset
	txy					; loop counter
	.Loop {
		lda $1a35,y
		sta $1a3d,x			; @var_1a35[Y]
		phx					; save X
		tax					; X => @var_1a35[Y]

		; move bit 1 to bit 6 and clear other bits TODO: WRONG
		lsr $1a3c			; A => A / 2
		ror a
		ror a				; rotate right 2
		and #$40			; bit 6
		xba					; save for later

		lda $1a39			; load @var_1a39
		bmi .Skip3			; skip if negative

		lda $7ff274,x
		asl a
		asl a
		sta $1a3b			; @var_1a3b => $7ff274[X] * 4

		.Skip3
		xba					; swap in saved byte
		plx					; restore X

		ora $1a34			; OR in @var_1a34
		ora $1a3b			; OR in @var_1a3b
		sta $1a3e,x			; @var_1a3d[][X+1] => A

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

pushpc
org $01fd24
; ROUTINE: Calculate tilemap vram destination address ($01fd24)
;		A => !ram_19bf * $40 + ($4000 or $4400 based on bit 4 of !ram_19bd)
; parameters:
;		!ram_19bf => this * $40 is the base address
;		!ram_19bd => bit 4 determines which offset to use
; returns:
;		A => vram destination address
CalculateTilemapVramDestinationAddress:
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
	adc.w CalculateTilemapVramDestinationAddress_Offset,x			; A += $fd4c[X], $fd4c is directly after this routine TODO: make sure label results in correct instructions
	clc
	adc $4216			; A += !ram_19bf * $40
	rts					; exit routine

; pc should equal $01fd4c
pullpc
pushpc
org pctosnes($00fd4c)

; DATA: word is offset used above ($01fd4c)
;		bit 4 of !ram_19bd determines which offset to use
CalculateTilemapVramDestinationAddress_Offset:
db $00,$40,$00,$44

; pc should equal $01fd50

pullpc

pushpc
org $01fd50

; ROUTINE:  ($01fd50)
;		Y.high => (Y.high < 0) ? (Y.high + @var_1925) : (Y.high - @var_1925)
;		Y.low => (Y.low < 0) ? (Y.low + @var_1924) : (Y.low - @var_1924)
; parameters:
;		Y => 
;		@var_1925 => 
;		@var_1924 => 
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
		adc $1925			; A => A + @var_1925
		bra .SetLow

	.PositiveHigh
		cmp $1925
		bcc .SetLow
		sec
		sbc $1925			; A => A - @var_1925

	.SetLow
		xba					; get Y.low
		bpl .PositiveLow

	.NegativeLow
		clc
		adc $1924			; A => A + @var_1924
		bra .End

	.PositiveLow
		cmp $1924
		bcc .End
		sec
		sbc $1924			; A => A - @var_1924

	.End
		tay				; Y => A
		rts				; exit routine

; pc should equal $01fd7b

pullpc

pushpc
org $01fd7b

; ROUTINE: Copy tile data to WRAM ($01fd7b)
;		Copies two sets of tiles into WRAM
;			1. destination => $7f:d274-‭$7f:f273‬ in $400 byte chunks
;				when @var_control is negative, the chunk is all $00
;				else, copy tiles from source address offset => $05:8c80 + ($0300 * @var_control)
;			2. destination => $7f:f274-$7f:f373 in $20 byte chunks
;				source address offset => $05:f280 + (@var_control * $10)
;				bottom 3 bits of each source nibble (low then high) becomes output byte
;					so $42 => $02 $04
;					and $CA => $02 $04
;				TODO: are these tiles?
;		(for certain maps, like first map "Level Forest") TODO: what all calls this?
; parameters:
;		ram $191a-1921 => values for @var_control
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
		lda $191a,x			; variable: @var_control, get value from $191a+x (lowram) TODO: trace this ram value
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
			xba					; save @var_control
			stz $211b
			lda #$03
			sta $211b			; set [M7A] = $0300
			xba					; swap @var_control back in
			sta $211c			; set [M7B] = @var_control

			%setAto16bit()
			lda #$8c80			; source address base (label DataTiles)
			clc
			adc $2134			; source address offset => $8c80 + ($0300 * @var_control)
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
		lda $191a,x			; variable: @var_control, get value from $191a+x (lowram) TODO: trace this ram value
		phx					; save loop counter

		; determine source address offset
		sta $211b
		stz $211b			; set [M7A] = $00(@var_control)
		lda #$10
		sta $211c			; set [M7B] = $10
		ldy $2134			; source address offset => @var_control * $10

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
org $01ffc1

; ROUTINE:  ($01ffc1)
;		
; parameters:
;		@var_0e89
;		@var_0e8a
; A => 8bit, XY => 16bit
; TODO: Name this routine!!!!!!!!!

Routine01ffc1:


	;
	lda $0e89			; load @var_0e89
	sec
	sbc #$08
	sta $192d			; @var_192d => @var_0e89 - $8

	; 
	lda $0e8a			; load @var_0e8a
	sec
	sbc #$06
	sta $192e			; @var_192e => @var_0e8a - $6

	; 
	ldx #$000f
	stx !ram_19bf			; !ram_19bf => $000f

	ldx #$0000			; loop counter
	stx !ram_19bd			; clear !ram_19bd

	.Loop {
		phx					; save counter
		jsr $f977
		jsr CopyTilemapFromWRAMToVRAM
		inc $192e			; increment @var_192e

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








pushpc
org $0b8149

; ROUTINE:  ($0b:8149)
;
; A is 8bit, XY is 16bit
; TODO: rename!!!!!!!!
Routine0b8149:
	; setup variables
	stz $19f6			; @var_19f6 => $00
	lda #$80
	sta $19a5			; @var_19a5 => $80
	lda #$01
	sta $1a45			; @var_1a45 => $01
	ldx $19f1			; load @var_19f1
	stx $0e89			; @var_0e89 => @var_19f1
	lda $19f0			; load @var_19f0
	sta $0e91			; @var_0e91 => @var_19f0
	bne .IsZero			; if @var_19f0 is $0000

	lda #$f2
	jsl TRBWithMaskFromTable97fbTo0ea8		; set @var_0ec6 => 

	stz $1a5b			; @var_1a5b => $00

	lda $0e88			; load @var_0e88
	%setAto16bit()
	and #$00ff			; ignore upper byte

	asl a
	tax
	lda Data07f7c3,x
	sta $0e89			; @var_0e89 => 
	%setAto8bit()
	lda #$f3
	jsl ANDFromTable97fbAnd0ea8ToA
	bne .IsZero 
	lda #$02
	sta $0e8b			; @var_0e89 => $02

	; clear $0ec8-$0ee7 and $0f28-$0f47
	ldx #$0000
	lda #$20			; loop counter
	.Loop {
		stz $0ec8,x			; @var_0ec8[x] => $00
		stz $0f28,x			; @var_0f28[x] => $00
		inx					; increment destination offset
		dec					; decrement counter
		bne .Loop
	}

	; clear $0ee8-$0f17
	lda #$30			; loop counter
	.LoopB {
		stz $0ec8,x			; @var_0ec8[x] => $00
		inx					; increment destination offset
		dec					; decrement counter
		bne .LoopB
	}

	.IsZero

	; 
	lda $0e91			; load @var_0e91
	%setAto16bit()
	and #$00ff			; ignore upper byte
	asl a
	tax					; source offset => @var_0e91 * 2
	lda Data07af3b,x
	tax					; source offset => Data07af3b[@var_0e91 * 2]
	%setAto8bit()
	stx $19b5			; @var_19b5 => source offset

	; 
	ldy #$0000			; loop counter
	.LoopC {
		lda Data07b013,x	; 
		sta $1910,y			; @var_1910[y] => Data07b013[x]
		inx					; increment source offset
		iny					; increment counter
		cpy #$0007			; loop until counter = $7
		bne .LoopC
	}

	; determine source address offset
	; @var_1911 is source address index
	lda #$0a
	sta $211b
	stz $211b			; set [M7A] => $000a
	lda $1911
	sta $211c			; set [M7B] => @var_1911
	ldx $2134
	stx $19b7			; source address offset => @var_1911 * $0a

	; copy $a bytes into @var_1918[]
	ldy #$0000			; loop counter
	.LoopD {
		lda.l DataTilesets,x
		sta $1918,y			; @var_1918[y] => DataTilesets[x]
		inx					; increment source offset
		iny					; increment counter
		cpy #$000a			; loop until counter = $a
		bne .LoopD
	}

	ldx #$ffff			; default @var_19b9 value is $FFFF
	lda $1912
	cmp #$ff
	beq .Skip			; skip ahead if @var_1912 is $FF

	%setAto16bit()
	and #$00ff			; ignore upper byte
	asl a				; A => A * 2
	tax					; source address offset => @var_1912 * 2
	lda.l Data0b8892,x
	tax
	%setAto8bit()

	.Skip
	stx $19b9			; @var_19b9 => X

	lda $1916			; load @var_1916
	and #$e0			; bits 5-7
	lsr a
	lsr a				; A => A / 8
	lsr a
	sta $1a55			; @var_1a55 => A

	lda $1915			; load @var_1915
	and #$e0			; bits 5-7
	ora $1a55			; combine with other 3 bits
	lsr a
	lsr a				; A => A / 4
	sta $1a55			; @var_1a55 => byte made of: two 0 bits, top three bits of @var_1915, top three bits of @var_1916

	rtl					; exit routine

; pc should equal $0b8223

pullpc







pushpc
org $0b8892		; pctosnes($058892)

; DATA:  ($0b8892)
Data0b8892:



; pc should equal $

pullpc



pushpc
org $01f9fb		; pctosnes($00f9fb)

; DATA: Jump table for .... ($01f9fb)
Jumpf9fb:
	db $0B,$FA			; 
	db $AE,$FA			; 
	db $0B,$FA			; 
	db $AE,$FA			; 

; pc should equal $01fa03

pullpc
pushpc
org $01fa03 ; pctosnes($00fa03)
; DATA: Jump table for .... ($01fa03)
Jumpfa03:

	db $49,$FB			; 
	db $EF,$FB			; 
	db $49,$FB			; 
	db $EF,$FB			; 

; pc should equal $01fa0b

pullpc





pushpc
org $0b8cd9		; pctosnes($058CD9)

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
org $07af3b		; pctosnes($03af3b)

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
org $07F7C3		; pctosnes($03f7c3)

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

