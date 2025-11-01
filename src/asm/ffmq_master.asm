; ==============================================================================
; Final Fantasy Mystic Quest (SNES) - Complete Rebuild
; ==============================================================================
; Build from complete disassembly - all 16 banks
; Achieves 100% byte-perfect match with original ROM
; ==============================================================================

arch 65816
lorom

; ==============================================================================
; Include Hardware Register Definitions
; ==============================================================================

incsrc "../include/snes_registers.inc"

; Define DMA5 registers (DMA5 = DMA0 + $50)
!DMA5_DMAP  = $4350
!DMA5_A1T0L = $4352
!DMA5_A1B0  = $4354
!DMA5_DAS0L = $4355

; Additional register aliases used by bank files
!SNES_INIDISP   = !INIDISP
!SNES_OBSEL     = !OBSEL
!SNES_OAMADDL   = !OAMADDL
!SNES_OAMADDH   = !OAMADDH
!SNES_BG1VOFS   = !BG1VOFS
!SNES_BG2VOFS   = !BG2VOFS
!SNES_VMDATAL   = !VMDATAL
!SNES_CGSWSEL   = !CGWSEL
!SNES_COLDATA   = !COLDATA
!SNES_TM        = !TM
!SNES_NMITIMEN  = !NMITIMEN
!SNES_DMA0PARAM = !DMA0_DMAP
!SNES_DMA0ADDRL = !DMA0_A1T0L
!SNES_DMA0ADDRH = !DMA0_A1B0
!SNES_DMA0CNTL  = !DMA0_DAS0L
!SNES_DMA5PARAM = !DMA5_DMAP
!SNES_DMA5ADDRL = !DMA5_A1T0L
!SNES_DMA5ADDRH = !DMA5_A1B0
!SNES_DMA5CNTL  = !DMA5_DAS0L
!SNES_MDMAEN    = !MDMAEN

; ==============================================================================
; Include All Banks (Complete Disassembly)
; ==============================================================================

incsrc "bank_00_documented.asm"    ; Main engine, core systems
incsrc "bank_01_documented.asm"    ; Event handlers, game logic
incsrc "bank_02_documented.asm"    ; Extended logic, AI
incsrc "bank_03_documented.asm"    ; Additional systems
incsrc "bank_04_documented.asm"    ; Graphics data (sprites)
incsrc "bank_05_documented.asm"    ; Graphics data (tilemaps)
incsrc "bank_06_documented.asm"    ; Graphics data (animations)
incsrc "bank_07_documented.asm"    ; Graphics data (palettes)
incsrc "bank_08_documented.asm"    ; Graphics data (tilemap layouts)
incsrc "bank_09_documented.asm"    ; Graphics data (sprite graphics)
incsrc "bank_0a_documented.asm"    ; Graphics data (animation sequences)
incsrc "bank_0b_documented.asm"    ; Battle graphics code
incsrc "bank_0c_documented.asm"    ; Display management code
incsrc "bank_0d_documented.asm"    ; Extended display code
incsrc "bank_0e_documented.asm"    ; Battle/display code
incsrc "bank_0f_documented.asm"    ; Audio data (SPC700)

; ==============================================================================
; END OF ROM
; ==============================================================================
