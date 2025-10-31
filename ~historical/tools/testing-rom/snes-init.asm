; Source: http://en.wikibooks.org/wiki/Super_NES_Programming

Init:
	sep #$30			; X,Y,A are 8 bit numbers
	lda #$8F			; screen off, full brightness
	sta !INIDISP		; brightness + screen enable register
	stz !OBSEL			; Sprite register (size + address in VRAM)
	stz !OAMADDL		; Sprite registers (address of sprite memory [OAM])
	stz !OAMADDH		; ""                       ""
	stz !BGMODE			; Mode 0, = Graphic mode register
	stz !MOSAIC			; noplanes, no mosaic, = Mosaic register
	stz !BG1SC			; Plane 0 map VRAM location
	stz !BG2SC			; Plane 1 map VRAM location
	stz !BG3SC			; Plane 2 map VRAM location
	stz !BG3SC			; Plane 3 map VRAM location
	stz !BG12NBA		; Plane 0+1 Tile data location
	stz !BG34NBA		; Plane 2+3 Tile data location
	stz !BG1HOFS		; Plane 0 scroll x (first 8 bits)
	stz !BG1HOFS		; Plane 0 scroll x (last 3 bits) #$0 - #$07ff
	lda #$FF			; The top pixel drawn on the screen isn't the top one in the tilemap, it's the one above that.
	sta !BG1VOFS		; Plane 0 scroll y (first 8 bits)
	sta !BG2VOFS		; Plane 1 scroll y (first 8 bits)
	sta !HVBJOY			; Plane 2 scroll y (first 8 bits)
	sta !BG4VOFS		; Plane 3 scroll y (first 8 bits)
	lda #$07			; Since this could get quite annoying, it's better to edit the scrolling registers to fix this.
	sta !BG1VOFS		; Plane 0 scroll y (last 3 bits) #$0 - #$07ff
	sta !BG2VOFS		; Plane 1 scroll y (last 3 bits) #$0 - #$07ff
	sta !HVBJOY			; Plane 2 scroll y (last 3 bits) #$0 - #$07ff
	sta !BG4VOFS		; Plane 3 scroll y (last 3 bits) #$0 - #$07ff
	stz !BG2HOFS		; Plane 1 scroll x (first 8 bits)
	stz !BG2HOFS		; Plane 1 scroll x (last 3 bits) #$0 - #$07ff
	stz !BG3HOFS		; Plane 2 scroll x (first 8 bits)
	stz !BG3HOFS		; Plane 2 scroll x (last 3 bits) #$0 - #$07ff
	stz !BG4HOFS		; Plane 3 scroll x (first 8 bits)
	stz !BG4HOFS		; Plane 3 scroll x (last 3 bits) #$0 - #$07ff
	lda #$80			; increase VRAM address after writing to $2119
	sta !VMAIN			; VRAM address increment register
	stz !VMADDL			; VRAM address low
	stz !VMADDH			; VRAM address high
	stz !M7SEL			; Initial Mode 7 setting register
	stz !M7A			; Mode 7 matrix parameter A register (low)
	lda #$01
	sta !M7A			; Mode 7 matrix parameter A register (high)
	stz !M7B			; Mode 7 matrix parameter B register (low)
	stz !M7B			; Mode 7 matrix parameter B register (high)
	stz !M7C			; Mode 7 matrix parameter C register (low)
	stz !M7C			; Mode 7 matrix parameter C register (high)
	stz !M7D			; Mode 7 matrix parameter D register (low)
	sta !M7D			; Mode 7 matrix parameter D register (high)
	stz !M7X			; Mode 7 center position X register (low)
	stz !M7X			; Mode 7 center position X register (high)
	stz !M7Y			; Mode 7 center position Y register (low)
	stz !M7Y			; Mode 7 center position Y register (high)
	stz !CGADD			; Color number register ($0-ff)
	stz !W12SEL			; BG1 & BG2 Window mask setting register
	stz !W34SEL			; BG3 & BG4 Window mask setting register
	stz !WOBJSEL		; OBJ & Color Window mask setting register
	stz !WH0			; Window 1 left position register
	stz !WH1			; Window 2 left position register
	stz !WH2			; Window 3 left position register
	stz !WH3			; Window 4 left position register
	stz !WBGLOG			; BG1, BG2, BG3, BG4 Window Logic register
	stz !WOBJLOG		; OBJ, Color Window Logic Register (or,and,xor,xnor)
	sta !TM				; Main Screen designation (planes, sprites enable)
	stz !TS				; Sub Screen designation
	stz !TMW			; Window mask for Main Screen
	stz !TSW			; Window mask for Sub Screen
	lda #$30
	sta !CGWSEL			; Color addition & screen addition init setting
	stz !CGADSUB		; Add/Sub sub designation for screen, sprite, color
	lda #$E0
	sta !COLDATA		; color data for addition/subtraction
	stz !SETINI			; Screen setting (interlace x,y/enable SFX data)
	stz !NMITIMEN		; Enable V-blank, interrupt, Joypad register
	lda #$FF
	sta !WRIO			; Programmable I/O port
	stz !WRMPYA			; Multiplicand A
	stz !WRMPYB			; Multiplier B
	stz !WRDIVL			; Multiplier C
	stz !WRDIVH			; Multiplicand C
	stz !WRDIVB			; Divisor B
	stz !HTIMEL			; Horizontal Count Timer
	stz !HTIMEH			; Horizontal Count Timer MSB (most significant bit)
	stz !VTIMEL			; Vertical Count Timer
	stz !VTIMEH			; Vertical Count Timer MSB
	stz !MDMAEN			; General DMA enable (bits 0-7)
	stz !HDMAEN			; Horizontal DMA (HDMA) enable (bits 0-7)
	stz !MEMSEL			; Access cycle designation (slow/fast rom)
	cli					; Enable interrupts
	rts
