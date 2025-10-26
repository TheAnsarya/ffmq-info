; SNES Hardware Registers
; Complete memory-mapped I/O definitions for SNES development
; Syntax: asar compatible (use !define for defines)

; PPU Registers ($2100-$213F)
!INIDISP     = $2100       ; Screen Display Register
!OBSEL       = $2101       ; Object Size and Character Size Register
!OAMADDL     = $2102       ; OAM Address Registers (Low)
!OAMADDH     = $2103       ; OAM Address Registers (High)
!OAMDATA     = $2104       ; OAM Data Write Register
!BGMODE      = $2105       ; BG Mode and Character Size Register
!MOSAIC      = $2106       ; Mosaic Register
!BG1SC       = $2107       ; BG Tilemap Address Registers (BG1)
!BG2SC       = $2108       ; BG Tilemap Address Registers (BG2)
!BG3SC       = $2109       ; BG Tilemap Address Registers (BG3)
!BG4SC       = $210A       ; BG Tilemap Address Registers (BG4)
!BG12NBA     = $210B       ; BG Character Address Registers (BG1&2)
!BG34NBA     = $210C       ; BG Character Address Registers (BG3&4)
!BG1HOFS     = $210D       ; BG Scroll Registers (BG1)
!BG1VOFS     = $210E       ; BG Scroll Registers (BG1)
!BG2HOFS     = $210F       ; BG Scroll Registers (BG2)
!BG2VOFS     = $2110       ; BG Scroll Registers (BG2)
!BG3HOFS     = $2111       ; BG Scroll Registers (BG3)
!BG3VOFS     = $2112       ; BG Scroll Registers (BG3)
!BG4HOFS     = $2113       ; BG Scroll Registers (BG4)
!BG4VOFS     = $2114       ; BG Scroll Registers (BG4)
!VMAIN       = $2115       ; Video Port Control Register
!VMADDL      = $2116       ; VRAM Address Registers (Low)
!VMADDH      = $2117       ; VRAM Address Registers (High)
!VMDATAL     = $2118       ; VRAM Data Write Registers (Low)
!VMDATAH     = $2119       ; VRAM Data Write Registers (High)
!M7SEL = $211A       ; Mode 7 Settings Register
!M7A = $211B       ; Mode 7 Matrix Registers
!M7B = $211C       ; Mode 7 Matrix Registers
!M7C = $211D       ; Mode 7 Matrix Registers
!M7D = $211E       ; Mode 7 Matrix Registers
!M7X = $211F       ; Mode 7 Center Registers
!M7Y = $2120       ; Mode 7 Center Registers
!CGADD = $2121       ; CGRAM Address Register
!CGDATA = $2122       ; CGRAM Data Write Register
!W12SEL = $2123       ; Window Mask Settings Registers
!W34SEL = $2124       ; Window Mask Settings Registers
!WOBJSEL = $2125       ; Window Mask Settings Registers
!WH0 = $2126       ; Window Position Registers
!WH1 = $2127       ; Window Position Registers
!WH2 = $2128       ; Window Position Registers
!WH3 = $2129       ; Window Position Registers
!WBGLOG = $212A       ; Window Mask Logic Registers (BG)
!WOBJLOG = $212B       ; Window Mask Logic Registers (OBJ)
!TM = $212C       ; Screen Destination Registers
!TS = $212D       ; Screen Destination Registers
!TMW = $212E       ; Window Mask Destination Registers
!TSW = $212F       ; Window Mask Destination Registers
!CGWSEL = $2130       ; Color Math Registers
!CGADSUB = $2131       ; Color Math Registers
!COLDATA = $2132       ; Color Math Registers
!SETINI = $2133       ; Screen Mode Select Register

; PPU Read Registers ($2134-$213F)
!MPYL = $2134       ; Multiplication Result Registers
!MPYM = $2135       ; Multiplication Result Registers
!MPYH = $2136       ; Multiplication Result Registers
!SLHV = $2137       ; Software Latch Register
!OAMDATAREAD = $2138       ; OAM Data Read Register
!VMDATALREAD = $2139       ; VRAM Data Read Register (Low)
!VMDATAHREAD = $213A       ; VRAM Data Read Register (High)
!CGDATAREAD = $213B       ; CGRAM Data Read Register
!OPHCT = $213C       ; Horizontal Scanline Location
!OPVCT = $213D       ; Vertical Scanline Location
!STAT77 = $213E       ; PPU Status Register
!STAT78 = $213F       ; PPU Status Register

; APU Registers ($2140-$217F)
!APUIO0 = $2140       ; APU I/O Registers
!APUIO1 = $2141       ; APU I/O Registers
!APUIO2 = $2142       ; APU I/O Registers
!APUIO3 = $2143       ; APU I/O Registers

; WRAM Registers ($2180-$2183)
!WMDATA = $2180       ; WRAM Data Register
!WMADDL = $2181       ; WRAM Address Registers
!WMADDM = $2182       ; WRAM Address Registers
!WMADDH = $2183       ; WRAM Address Registers

; Joypad Registers ($4016-$4017)
!JOYSER0 = $4016       ; Old Style Joypad Registers
!JOYSER1 = $4017       ; Old Style Joypad Registers

; Interrupt Registers ($4200-$421F)
!NMITIMEN = $4200       ; Interrupt Enable Register
!WRIO = $4201       ; IO Port Write Register
!WRMPYA = $4202       ; Multiplicand Registers
!WRMPYB = $4203       ; Multiplicand Registers
!WRDIVL = $4204       ; Dividend Registers
!WRDIVH = $4205       ; Dividend Registers
!WRDIVB = $4206       ; Divisor Register
!HTIMEL = $4207       ; Horizontal Timer Registers
!HTIMEH = $4208       ; Horizontal Timer Registers
!VTIMEL = $4209       ; Vertical Timer Registers
!VTIMEH = $420A       ; Vertical Timer Registers
!MDMAEN = $420B       ; DMA Enable Register
!HDMAEN = $420C       ; HDMA Enable Register
!MEMSEL = $420D       ; ROM Speed Register

; Multiplication/Division Result Registers ($4214-$4217)
!RDDIVL = $4214       ; Quotient Registers
!RDDIVH = $4215       ; Quotient Registers
!RDMPYL = $4216       ; Product/Remainder Registers
!RDMPYH = $4217       ; Product/Remainder Registers

; Joypad Input Registers ($4218-$421F)
!JOY1L = $4218       ; Joypad Input Registers
!JOY1H = $4219       ; Joypad Input Registers
!JOY2L = $421A       ; Joypad Input Registers
!JOY2H = $421B       ; Joypad Input Registers
!JOY3L = $421C       ; Joypad Input Registers
!JOY3H = $421D       ; Joypad Input Registers
!JOY4L = $421E       ; Joypad Input Registers
!JOY4H = $421F       ; Joypad Input Registers

; DMA Registers ($4300-$437F) - Channel 0
!DMA0_DMAP = $4300       ; DMA Control Register
!DMA0_BBAD = $4301       ; DMA Destination Register
!DMA0_A1T0L = $4302       ; DMA Source Address Registers
!DMA0_A1T0H = $4303       ; DMA Source Address Registers
!DMA0_A1B0 = $4304       ; DMA Source Address Registers
!DMA0_DAS0L = $4305       ; DMA Size Registers
!DMA0_DAS0H = $4306       ; DMA Size Registers
!DMA0_DSAB0 = $4307       ; HDMA Indirect Address Register
!DMA0_A2A0L = $4308       ; HDMA Mid Frame Table Registers
!DMA0_A2A0H = $4309       ; HDMA Mid Frame Table Registers
!DMA0_NTLR0 = $430A       ; HDMA Line Counter Register

; Additional DMA channels follow the same pattern (+$10 per channel)
; DMA1: $4310-$431F, DMA2: $4320-$432F, etc.

; Joypad Button Constants
!JOY_B = $8000
!JOY_Y = $4000
!JOY_SELECT = $2000
!JOY_START = $1000
!JOY_UP = $0800
!JOY_DOWN = $0400
!JOY_LEFT = $0200
!JOY_RIGHT = $0100
!JOY_A = $0080
!JOY_X = $0040
!JOY_L = $0020
!JOY_R = $0010
