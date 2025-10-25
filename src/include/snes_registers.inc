; SNES Hardware Registers
; Complete memory-mapped I/O definitions for SNES development

; PPU Registers ($2100-$213F)
.define INIDISP     $2100       ; Screen Display Register
.define OBSEL       $2101       ; Object Size and Character Size Register
.define OAMADDL     $2102       ; OAM Address Registers (Low)
.define OAMADDH     $2103       ; OAM Address Registers (High)
.define OAMDATA     $2104       ; OAM Data Write Register
.define BGMODE      $2105       ; BG Mode and Character Size Register
.define MOSAIC      $2106       ; Mosaic Register
.define BG1SC       $2107       ; BG Tilemap Address Registers (BG1)
.define BG2SC       $2108       ; BG Tilemap Address Registers (BG2)
.define BG3SC       $2109       ; BG Tilemap Address Registers (BG3)
.define BG4SC       $210A       ; BG Tilemap Address Registers (BG4)
.define BG12NBA     $210B       ; BG Character Address Registers (BG1&2)
.define BG34NBA     $210C       ; BG Character Address Registers (BG3&4)
.define BG1HOFS     $210D       ; BG Scroll Registers (BG1)
.define BG1VOFS     $210E       ; BG Scroll Registers (BG1)
.define BG2HOFS     $210F       ; BG Scroll Registers (BG2)
.define BG2VOFS     $2110       ; BG Scroll Registers (BG2)
.define BG3HOFS     $2111       ; BG Scroll Registers (BG3)
.define BG3VOFS     $2112       ; BG Scroll Registers (BG3)
.define BG4HOFS     $2113       ; BG Scroll Registers (BG4)
.define BG4VOFS     $2114       ; BG Scroll Registers (BG4)
.define VMAIN       $2115       ; Video Port Control Register
.define VMADDL      $2116       ; VRAM Address Registers (Low)
.define VMADDH      $2117       ; VRAM Address Registers (High)
.define VMDATAL     $2118       ; VRAM Data Write Registers (Low)
.define VMDATAH     $2119       ; VRAM Data Write Registers (High)
.define M7SEL       $211A       ; Mode 7 Settings Register
.define M7A         $211B       ; Mode 7 Matrix Registers
.define M7B         $211C       ; Mode 7 Matrix Registers
.define M7C         $211D       ; Mode 7 Matrix Registers
.define M7D         $211E       ; Mode 7 Matrix Registers
.define M7X         $211F       ; Mode 7 Center Registers
.define M7Y         $2120       ; Mode 7 Center Registers
.define CGADD       $2121       ; CGRAM Address Register
.define CGDATA      $2122       ; CGRAM Data Write Register
.define W12SEL      $2123       ; Window Mask Settings Registers
.define W34SEL      $2124       ; Window Mask Settings Registers
.define WOBJSEL     $2125       ; Window Mask Settings Registers
.define WH0         $2126       ; Window Position Registers
.define WH1         $2127       ; Window Position Registers
.define WH2         $2128       ; Window Position Registers
.define WH3         $2129       ; Window Position Registers
.define WBGLOG      $212A       ; Window Mask Logic Registers (BG)
.define WOBJLOG     $212B       ; Window Mask Logic Registers (OBJ)
.define TM          $212C       ; Screen Destination Registers
.define TS          $212D       ; Screen Destination Registers
.define TMW         $212E       ; Window Mask Destination Registers
.define TSW         $212F       ; Window Mask Destination Registers
.define CGWSEL      $2130       ; Color Math Registers
.define CGADSUB     $2131       ; Color Math Registers
.define COLDATA     $2132       ; Color Math Registers
.define SETINI      $2133       ; Screen Mode Select Register

; PPU Read Registers ($2134-$213F)
.define MPYL        $2134       ; Multiplication Result Registers
.define MPYM        $2135       ; Multiplication Result Registers
.define MPYH        $2136       ; Multiplication Result Registers
.define SLHV        $2137       ; Software Latch Register
.define OAMDATAREAD $2138       ; OAM Data Read Register
.define VMDATALREAD $2139       ; VRAM Data Read Register (Low)
.define VMDATAHREAD $213A       ; VRAM Data Read Register (High)
.define CGDATAREAD  $213B       ; CGRAM Data Read Register
.define OPHCT       $213C       ; Horizontal Scanline Location
.define OPVCT       $213D       ; Vertical Scanline Location
.define STAT77      $213E       ; PPU Status Register
.define STAT78      $213F       ; PPU Status Register

; APU Registers ($2140-$217F)
.define APUIO0      $2140       ; APU I/O Registers
.define APUIO1      $2141       ; APU I/O Registers
.define APUIO2      $2142       ; APU I/O Registers
.define APUIO3      $2143       ; APU I/O Registers

; WRAM Registers ($2180-$2183)
.define WMDATA      $2180       ; WRAM Data Register
.define WMADDL      $2181       ; WRAM Address Registers
.define WMADDM      $2182       ; WRAM Address Registers
.define WMADDH      $2183       ; WRAM Address Registers

; Joypad Registers ($4016-$4017)
.define JOYSER0     $4016       ; Old Style Joypad Registers
.define JOYSER1     $4017       ; Old Style Joypad Registers

; Interrupt Registers ($4200-$421F)
.define NMITIMEN    $4200       ; Interrupt Enable Register
.define WRIO        $4201       ; IO Port Write Register
.define WRMPYA      $4202       ; Multiplicand Registers
.define WRMPYB      $4203       ; Multiplicand Registers
.define WRDIVL      $4204       ; Dividend Registers
.define WRDIVH      $4205       ; Dividend Registers
.define WRDIVB      $4206       ; Divisor Register
.define HTIMEL      $4207       ; Horizontal Timer Registers
.define HTIMEH      $4208       ; Horizontal Timer Registers
.define VTIMEL      $4209       ; Vertical Timer Registers
.define VTIMEH      $420A       ; Vertical Timer Registers
.define MDMAEN      $420B       ; DMA Enable Register
.define HDMAEN      $420C       ; HDMA Enable Register
.define MEMSEL      $420D       ; ROM Speed Register

; Multiplication/Division Result Registers ($4214-$4217)
.define RDDIVL      $4214       ; Quotient Registers
.define RDDIVH      $4215       ; Quotient Registers
.define RDMPYL      $4216       ; Product/Remainder Registers
.define RDMPYH      $4217       ; Product/Remainder Registers

; Joypad Input Registers ($4218-$421F)
.define JOY1L       $4218       ; Joypad Input Registers
.define JOY1H       $4219       ; Joypad Input Registers
.define JOY2L       $421A       ; Joypad Input Registers
.define JOY2H       $421B       ; Joypad Input Registers
.define JOY3L       $421C       ; Joypad Input Registers
.define JOY3H       $421D       ; Joypad Input Registers
.define JOY4L       $421E       ; Joypad Input Registers
.define JOY4H       $421F       ; Joypad Input Registers

; DMA Registers ($4300-$437F) - Channel 0
.define DMA0_DMAP   $4300       ; DMA Control Register
.define DMA0_BBAD   $4301       ; DMA Destination Register
.define DMA0_A1T0L  $4302       ; DMA Source Address Registers
.define DMA0_A1T0H  $4303       ; DMA Source Address Registers
.define DMA0_A1B0   $4304       ; DMA Source Address Registers
.define DMA0_DAS0L  $4305       ; DMA Size Registers
.define DMA0_DAS0H  $4306       ; DMA Size Registers
.define DMA0_DSAB0  $4307       ; HDMA Indirect Address Register
.define DMA0_A2A0L  $4308       ; HDMA Mid Frame Table Registers
.define DMA0_A2A0H  $4309       ; HDMA Mid Frame Table Registers
.define DMA0_NTLR0  $430A       ; HDMA Line Counter Register

; Additional DMA channels follow the same pattern (+$10 per channel)
; DMA1: $4310-$431F, DMA2: $4320-$432F, etc.

; Joypad Button Constants
.define JOY_B       $8000
.define JOY_Y       $4000
.define JOY_SELECT  $2000
.define JOY_START   $1000
.define JOY_UP      $0800
.define JOY_DOWN    $0400
.define JOY_LEFT    $0200
.define JOY_RIGHT   $0100
.define JOY_A       $0080
.define JOY_X       $0040
.define JOY_L       $0020
.define JOY_R       $0010