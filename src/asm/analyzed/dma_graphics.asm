; ============================================================================
; FFMQ DMA and Graphics Transfer Analysis
; ============================================================================
; Analyzed from Diztinguish disassembly bank_00.asm
; Addresses: $008247-$008500+
;
; This file contains detailed analysis of the DMA transfer routines used
; for graphics, palettes, and VRAM operations.
; ============================================================================

; ============================================================================
; Hardware Initialize - Disable Screen and Interrupts
; ============================================================================
; Address: $008247 (Original: CODE_008247)
; Called during boot sequence to safely initialize hardware
; ============================================================================
InitializeHardware:
    SEP #$30                        ; 8-bit A, X, Y
    STZ.W SNES_NMITIMEN             ; Disable NMI and IRQ ($4200 = $00)
    LDA.B #$80                      ; Force blank bit
    STA.W SNES_INIDISP              ; Force screen blank ($2100 = $80)
    RTS

; ============================================================================
; DMA Transfer to VRAM - Mode 5 Channel
; ============================================================================
; Address: $008385 (Original: CODE_008385)
; Performs DMA transfer from RAM to VRAM using channel 5
; Uses parameters stored in RAM to configure the transfer
; ============================================================================
DMA_TransferToVRAM_Ch5:
    ; Setup DMA channel 5 parameters
    LDX.W #$1801                    ; DMA params: $18 = VRAM write, $01 = increment mode
    STX.B SNES_DMA5PARAM-$4300      ; $4350 = DMA5 control
    
    ; Source address from RAM parameters
    LDX.W $01F6                     ; Load source address (low/mid bytes)
    STX.B SNES_DMA5ADDRL-$4300      ; $4352-$4353 = source address
    LDA.B #$7F                      ; Source bank = $7F (work RAM)
    STA.B SNES_DMA5ADDRH-$4300      ; $4354 = source bank
    
    ; Transfer size
    LDX.W $01F4                     ; Load transfer size
    STX.B SNES_DMA5CNTL-$4300       ; $4355-$4356 = transfer count
    
    ; Destination VRAM address
    LDX.W $01F8                     ; Load VRAM destination
    STX.W SNES_VMADDL               ; $2116-$2117 = VRAM address
    
    ; Configure VRAM increment mode
    LDA.B #$84                      ; Increment after $2119 write, by 128
    STA.W SNES_VMAINC               ; $2115 = VRAM increment mode
    
    ; Execute DMA transfer
    LDA.B #$20                      ; Enable DMA channel 5 (bit 5)
    STA.W SNES_MDMAEN               ; $420B = start DMA
    RTS

; ============================================================================
; DMA Transfer for Palette Data
; ============================================================================
; Address: $0083A8 (Original: CODE_0083A8)
; Transfers palette data to CGRAM using DMA channel 5
; ============================================================================
DMA_TransferPalette:
    ; Check if palette DMA is requested
    LDA.B #$80                      ; Check bit 7
    AND.W $00D2                     ; Test flag byte
    BEQ .noPaletteDMA               ; Skip if not set
    
    ; Setup for palette transfer
    LDA.B #$80                      ; Standard increment
    STA.W SNES_VMAINC               ; $2115 = increment mode
    
    ; Configure DMA channel 5
    LDX.W #$1801                    ; VRAM write mode
    STX.B SNES_DMA5PARAM-$4300      ; DMA5 control
    
    ; Source address from parameters
    LDX.W $01ED                     ; Palette data source (low/mid)
    STX.B SNES_DMA5ADDRL-$4300      ; Set source address
    LDA.W $01EF                     ; Source bank
    STA.B SNES_DMA5ADDRH-$4300      ; Set source bank
    
    ; Transfer size
    LDX.W $01EB                     ; Palette data size
    STX.B SNES_DMA5CNTL-$4300       ; Set transfer count
    
    ; Destination address
    LDX.W $0048                     ; VRAM destination from RAM
    STX.W SNES_VMADDL               ; Set VRAM address
    
    ; Execute transfer
    LDA.B #$20                      ; Enable channel 5
    STA.W SNES_MDMAEN               ; Start DMA
    
.noPaletteDMA:
    ; Additional processing...
    RTS

; ============================================================================
; DMA Transfer for Tile Data
; ============================================================================
; Address: $0083E8 (Original: CODE_0083E8)
; Transfers tile graphics data to VRAM
; ============================================================================
DMA_TransferTileData:
    ; Clear tile transfer flag
    LDA.B #$02                      ; Bit 1
    TRB.W $00D4                     ; Clear in flag byte
    
    ; Setup VRAM increment
    LDA.B #$80                      ; Standard increment
    STA.W $2115                     ; VRAM increment register
    
    ; Configure DMA channel 5 for tile data
    LDX.W #$2200                    ; Different DMA mode for tiles
    STX.B SNES_DMA5PARAM-$4300      ; DMA5 control
    
    ; Source bank for tile data
    LDA.B #$07                      ; Bank $07 (ROM data)
    STA.B SNES_DMA5ADDRH-$4300      ; Source bank
    
    ; Tile-specific transfer setup
    LDA.B #$A8                      ; Tile mode parameter
    LDX.W $0064                     ; Tile data index
    JSR.W SetupTileTransfer         ; Call tile setup routine ($008504)
    
    ; Prepare for transfer
    REP #$30                        ; 16-bit mode
    LDX.W #$FF00                    ; Clear mask
    STX.W $00F0                     ; Store mask
    
    ; Check transfer mode
    LDX.W $0062                     ; Check transfer type
    LDA.W #$6080                    ; Base VRAM address
    CPX.W #$0001                    ; Is it mode 1?
    BEQ .mode1Transfer              ; Branch if mode 1
    
    ; Standard transfer
    JSR.W ExecuteStandardTransfer   ; $008520
    RTL
    
.mode1Transfer:
    ; Special mode 1 transfer
    PHK
    PLB                             ; Set data bank to current program bank
    STA.W SNES_VMADDL               ; Set VRAM address
    LDX.W #$F0C1                    ; Special transfer data
    LDY.W #$0004                    ; Size parameter
    JMP.W CODE_008DDF               ; Execute special transfer
    
; ============================================================================
; Helper: Setup Tile Transfer Parameters
; ============================================================================
; Address: $008504 (Original: CODE_008504)
; Input: A = mode, X = tile index
; Sets up DMA parameters for tile data transfer
; ============================================================================
SetupTileTransfer:
    ; [Implementation would analyze actual routine]
    ; Calculates source address and size based on tile index
    ; Sets up DMA channel 5 registers appropriately
    RTS

; ============================================================================
; Helper: Execute Standard Transfer
; ============================================================================
; Address: $008520 (Original: CODE_008520)
; Executes a standard DMA transfer to VRAM
; ============================================================================
ExecuteStandardTransfer:
    ; [Implementation would analyze actual routine]
    ; Performs the configured DMA operation
    RTS

; ============================================================================
; RAM Variables Used by DMA Routines
; ============================================================================
; $00D2 - DMA request flags byte 1
;   Bit 7: Palette DMA requested
;   Bit 6: Reserved
;   Bit 5: Tile transfer pending
;   Bit 4: VRAM transfer mode
; $00D4 - DMA request flags byte 2
;   Bit 7: Tile DMA requested
;   Bit 1: Tile transfer flag
;   Bit 0: General transfer flag
; $00D8 - Additional DMA flags
;   Bit 7: Special transfer mode
;   Bit 1: Palette mode flag
; $00DD - VRAM transfer flags
;   Bit 6: Transfer pending
; $00E2 - Callback flags
;   Bit 6: Callback pending
; $00F0 - Transfer mask word
; $0048 - VRAM destination address (word)
; $0062 - Transfer mode type (word)
; $0064 - Tile data index (word)
; $01EB - Palette data size (word)
; $01ED - Palette source address low/mid (word)
; $01EF - Palette source bank (byte)
; $01F4 - General transfer size (word)
; $01F6 - General source address (word)
; $01F8 - General VRAM destination (word)
; ============================================================================

; ============================================================================
; DMA Transfer Patterns
; ============================================================================
; The game uses several DMA patterns:
;
; 1. VRAM Fill (boot sequence):
;    - Fill VRAM with pattern (usually $00)
;    - Used to clear screen on boot
;    - Mode: Single byte source, auto-increment dest
;
; 2. Tile Transfer:
;    - Copy tile graphics from ROM/RAM to VRAM
;    - Source: Usually bank $04-$07 ROM data
;    - Dest: Character VRAM area
;    - Size: Multiples of 16 bytes (1 tile = 32 bytes for 4BPP)
;
; 3. Palette Transfer:
;    - Copy palette data to CGRAM
;    - Source: RAM buffer at $7Exxxx
;    - Dest: CGRAM via $2122
;    - Size: Usually 32 bytes (16 colors) or 512 bytes (full palette)
;
; 4. Tilemap Transfer:
;    - Copy tilemap data to VRAM
;    - Source: RAM tilemap buffer
;    - Dest: BG1/BG2/BG3 tilemap areas
;    - Mode: Word transfers
; ============================================================================
