; ============================================================================
; SNES Hardware Register Definitions
; ============================================================================
; Complete SNES hardware register map for use with asar assembler
; Extracted from Diztinguish disassembly for FFMQ project
; ============================================================================

; PPU Registers ($2100-$213F)
!SNES_INIDISP = $2100     ; Screen Display Register
!SNES_OBJSEL = $2101      ; Object Size and Character Address
!SNES_OAMADDL = $2102     ; OAM Address (lower 8 bits)
!SNES_OAMADDH = $2103     ; OAM Address (upper bit) and Priority
!SNES_OAMDATA = $2104     ; OAM Data Write
!SNES_BGMODE = $2105      ; BG Mode and Character Size
!SNES_MOSAIC = $2106      ; Mosaic
!SNES_BG1SC = $2107       ; BG1 Tilemap Address and Size
!SNES_BG2SC = $2108       ; BG2 Tilemap Address and Size
!SNES_BG3SC = $2109       ; BG3 Tilemap Address and Size
!SNES_BG4SC = $210A       ; BG4 Tilemap Address and Size
!SNES_BG12NBA = $210B     ; BG1 & BG2 Character Address
!SNES_BG34NBA = $210C     ; BG3 & BG4 Character Address
!SNES_BG1HOFS = $210D     ; BG1 Horizontal Scroll
!SNES_BG1VOFS = $210E     ; BG1 Vertical Scroll
!SNES_BG2HOFS = $210F     ; BG2 Horizontal Scroll
!SNES_BG2VOFS = $2110     ; BG2 Vertical Scroll
!SNES_BG3HOFS = $2111     ; BG3 Horizontal Scroll
!SNES_BG3VOFS = $2112     ; BG3 Vertical Scroll
!SNES_BG4HOFS = $2113     ; BG4 Horizontal Scroll
!SNES_BG4VOFS = $2114     ; BG4 Vertical Scroll
!SNES_VMAINC = $2115      ; Video Port Control
!SNES_VMADDL = $2116      ; VRAM Address (lower 8 bits)
!SNES_VMADDH = $2117      ; VRAM Address (upper 8 bits)
!SNES_VMDATAL = $2118     ; VRAM Data Write (lower 8 bits)
!SNES_VMDATAH = $2119     ; VRAM Data Write (upper 8 bits)
!SNES_M7SEL = $211A       ; Mode 7 Settings
!SNES_M7A = $211B         ; Mode 7 Matrix A
!SNES_M7B = $211C         ; Mode 7 Matrix B
!SNES_M7C = $211D         ; Mode 7 Matrix C
!SNES_M7D = $211E         ; Mode 7 Matrix D
!SNES_M7X = $211F         ; Mode 7 Center X
!SNES_M7Y = $2120         ; Mode 7 Center Y
!SNES_CGADD = $2121       ; CGRAM Address
!SNES_CGDATA = $2122      ; CGRAM Data Write
!SNES_W12SEL = $2123      ; Window Mask Settings (BG1 & BG2)
!SNES_W34SEL = $2124      ; Window Mask Settings (BG3 & BG4)
!SNES_WOBJSEL = $2125     ; Window Mask Settings (OBJ & Color)
!SNES_WH0 = $2126         ; Window 1 Left Position
!SNES_WH1 = $2127         ; Window 1 Right Position
!SNES_WH2 = $2128         ; Window 2 Left Position
!SNES_WH3 = $2129         ; Window 2 Right Position
!SNES_WBGLOG = $212A      ; Window Mask Logic (BG)
!SNES_WOBJLOG = $212B     ; Window Mask Logic (OBJ & Color)
!SNES_TM = $212C          ; Main Screen Designation
!SNES_TS = $212D          ; Sub Screen Designation
!SNES_TMW = $212E         ; Window Mask Designation (Main Screen)
!SNES_TSW = $212F         ; Window Mask Designation (Sub Screen)
!SNES_CGSWSEL = $2130     ; Color Math Control Register A
!SNES_CGADSUB = $2131     ; Color Math Control Register B
!SNES_COLDATA = $2132     ; Color Math Sub Screen Backdrop Color
!SNES_SETINI = $2133      ; Screen Mode/Video Select

; PPU Read Registers ($2134-$213F)
!SNES_MPYL = $2134        ; Multiplication Result (lower 8 bits)
!SNES_MPYM = $2135        ; Multiplication Result (middle 8 bits)
!SNES_MPYH = $2136        ; Multiplication Result (upper 8 bits)
!SNES_SLHV = $2137        ; Software Latch for H/V Counter
!SNES_ROAMDATA = $2138    ; OAM Data Read
!SNES_RVMDATAL = $2139    ; VRAM Data Read (lower 8 bits)
!SNES_RVMDATAH = $213A    ; VRAM Data Read (upper 8 bits)
!SNES_RCGDATA = $213B     ; CGRAM Data Read
!SNES_OPHCT = $213C       ; Horizontal Scanline Location
!SNES_OPVCT = $213D       ; Vertical Scanline Location
!SNES_STAT77 = $213E      ; PPU Status Flag and Version
!SNES_STAT78 = $213F      ; PPU Status Flag and Version

; APU Registers ($2140-$2143)
!SNES_APUIO0 = $2140      ; APU I/O Port 0
!SNES_APUIO1 = $2141      ; APU I/O Port 1
!SNES_APUIO2 = $2142      ; APU I/O Port 2
!SNES_APUIO3 = $2143      ; APU I/O Port 3

; WRAM Registers ($2180-$2183)
!SNES_WMDATA = $2180      ; WRAM Data Read/Write
!SNES_WMADDL = $2181      ; WRAM Address (lower 8 bits)
!SNES_WMADDM = $2182      ; WRAM Address (middle 8 bits)
!SNES_WMADDH = $2183      ; WRAM Address (upper bit)

; Controller Registers ($4016-$4017)
!SNES_JOY1 = $4016        ; Controller Port 1
!SNES_JOY2 = $4017        ; Controller Port 2

; CPU Registers ($4200-$421F)
!SNES_NMITIMEN = $4200    ; Interrupt Enable Flags
!SNES_WRIO = $4201        ; I/O Port Write
!SNES_WRMPYA = $4202      ; Multiplicand A
!SNES_WRMPYB = $4203      ; Multiplicand B
!SNES_WRDIVL = $4204      ; Dividend (lower 8 bits)
!SNES_WRDIVH = $4205      ; Dividend (upper 8 bits)
!SNES_WRDIVB = $4206      ; Divisor
!SNES_HTIMEL = $4207      ; H Timer (lower 8 bits)
!SNES_HTIMEH = $4208      ; H Timer (upper 8 bits)
!SNES_VTIMEL = $4209      ; V Timer (lower 8 bits)
!SNES_VTIMEH = $420A      ; V Timer (upper 8 bits)
!SNES_MDMAEN = $420B      ; DMA Enable
!SNES_HDMAEN = $420C      ; HDMA Enable
!SNES_MEMSEL = $420D      ; ROM Access Speed
!SNES_RDNMI = $4210       ; NMI Flag and CPU Version
!SNES_TIMEUP = $4211      ; IRQ Flag
!SNES_HVBJOY = $4212      ; PPU Status
!SNES_RDIO = $4213        ; I/O Port Read
!SNES_RDDIVL = $4214      ; Division Result (lower 8 bits)
!SNES_RDDIVH = $4215      ; Division Result (upper 8 bits)
!SNES_RDMPYL = $4216      ; Multiplication or Divide Remainder (lower 8 bits)
!SNES_RDMPYH = $4217      ; Multiplication or Divide Remainder (upper 8 bits)
!SNES_CNTRL1L = $4218     ; Controller 1 Data (lower 8 bits)
!SNES_CNTRL1H = $4219     ; Controller 1 Data (upper 8 bits)
!SNES_CNTRL2L = $421A     ; Controller 2 Data (lower 8 bits)
!SNES_CNTRL2H = $421B     ; Controller 2 Data (upper 8 bits)
!SNES_CNTRL3L = $421C     ; Controller 3 Data (lower 8 bits)
!SNES_CNTRL3H = $421D     ; Controller 3 Data (upper 8 bits)
!SNES_CNTRL4L = $421E     ; Controller 4 Data (lower 8 bits)
!SNES_CNTRL4H = $421F     ; Controller 4 Data (upper 8 bits)

; DMA Channel 0 Registers ($4300-$430A)
!SNES_DMA0PARAM = $4300   ; DMA Control
!SNES_DMA0REG = $4301     ; DMA Destination
!SNES_DMA0ADDRL = $4302   ; DMA Source Address (lower 8 bits)
!SNES_DMA0ADDRM = $4303   ; DMA Source Address (middle 8 bits)
!SNES_DMA0ADDRH = $4304   ; DMA Source Address (upper 8 bits / bank)
!SNES_DMA0CNTL = $4305    ; DMA Size/HDMA Indirect Address (lower 8 bits)
!SNES_DMA0CNTH = $4306    ; DMA Size/HDMA Indirect Address (upper 8 bits)
!SNES_HDMA0BANK = $4307   ; HDMA Indirect Address Bank
!SNES_DMA0IDXL = $4308    ; HDMA Table Address (lower 8 bits)
!SNES_DMA0IDXH = $4309    ; HDMA Table Address (upper 8 bits)
!SNES_HDMA0LINES = $430A  ; HDMA Line Counter

; DMA Channel 1 Registers ($4310-$431A)
!SNES_DMA1PARAM = $4310
!SNES_DMA1REG = $4311
!SNES_DMA1ADDRL = $4312
!SNES_DMA1ADDRM = $4313
!SNES_DMA1ADDRH = $4314
!SNES_DMA1CNTL = $4315
!SNES_DMA1CNTH = $4316
!SNES_HDMA1BANK = $4317
!SNES_DMA1IDXL = $4318
!SNES_DMA1IDXH = $4319
!SNES_HDMA1LINES = $431A

; DMA Channel 2 Registers ($4320-$432A)
!SNES_DMA2PARAM = $4320
!SNES_DMA2REG = $4321
!SNES_DMA2ADDRL = $4322
!SNES_DMA2ADDRM = $4323
!SNES_DMA2ADDRH = $4324
!SNES_DMA2CNTL = $4325
!SNES_DMA2CNTH = $4326
!SNES_HDMA2BANK = $4327
!SNES_DMA2IDXL = $4328
!SNES_DMA2IDXH = $4329
!SNES_HDMA2LINES = $432A

; DMA Channel 3 Registers ($4330-$433A)
!SNES_DMA3PARAM = $4330
!SNES_DMA3REG = $4331
!SNES_DMA3ADDRL = $4332
!SNES_DMA3ADDRM = $4333
!SNES_DMA3ADDRH = $4334
!SNES_DMA3CNTL = $4335
!SNES_DMA3CNTH = $4336
!SNES_HDMA3BANK = $4337
!SNES_DMA3IDXL = $4338
!SNES_DMA3IDXH = $4339
!SNES_HDMA3LINES = $433A

; DMA Channel 4 Registers ($4340-$434A)
!SNES_DMA4PARAM = $4340
!SNES_DMA4REG = $4341
!SNES_DMA4ADDRL = $4342
!SNES_DMA4ADDRM = $4343
!SNES_DMA4ADDRH = $4344
!SNES_DMA4CNTL = $4345
!SNES_DMA4CNTH = $4346
!SNES_HDMA4BANK = $4347
!SNES_DMA4IDXL = $4348
!SNES_DMA4IDXH = $4349
!SNES_HDMA4LINES = $434A

; DMA Channel 5 Registers ($4350-$435A)
!SNES_DMA5PARAM = $4350
!SNES_DMA5REG = $4351
!SNES_DMA5ADDRL = $4352
!SNES_DMA5ADDRM = $4353
!SNES_DMA5ADDRH = $4354
!SNES_DMA5CNTL = $4355
!SNES_DMA5CNTH = $4356
!SNES_HDMA5BANK = $4357
!SNES_DMA5IDXL = $4358
!SNES_DMA5IDXH = $4359
!SNES_HDMA5LINES = $435A

; DMA Channel 6 Registers ($4360-$436A)
!SNES_DMA6PARAM = $4360
!SNES_DMA6REG = $4361
!SNES_DMA6ADDRL = $4362
!SNES_DMA6ADDRM = $4363
!SNES_DMA6ADDRH = $4364
!SNES_DMA6CNTL = $4365
!SNES_DMA6CNTH = $4366
!SNES_HDMA6BANK = $4367
!SNES_DMA6IDXL = $4368
!SNES_DMA6IDXH = $4369
!SNES_HDMA6LINES = $436A

; DMA Channel 7 Registers ($4370-$437A)
!SNES_DMA7PARAM = $4370
!SNES_DMA7REG = $4371
!SNES_DMA7ADDRL = $4372
!SNES_DMA7ADDRM = $4373
!SNES_DMA7ADDRH = $4374
!SNES_DMA7CNTL = $4375
!SNES_DMA7CNTH = $4376
!SNES_HDMA7BANK = $4377
!SNES_DMA7IDXL = $4378
!SNES_DMA7IDXH = $4379
!SNES_HDMA7LINES = $437A
