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
; Address: $008247 (Original: AddressOriginalCode)
; Called during boot sequence to safely initialize hardware
; ============================================================================
InitializeHardware:
	sep #$30                        ; 8-bit A, X, Y
	stz.W SNES_NMITIMEN             ; Disable NMI and IRQ ($4200 = $00)
	lda.B #$80                      ; Force blank bit
	sta.W SNES_INIDISP              ; Force screen blank ($2100 = $80)
	rts

; ============================================================================
; DMA Transfer to VRAM - Mode 5 Channel
; ============================================================================
; Address: $008385 (Original: PatternCodeDmaTransferVram)
; Performs DMA transfer from RAM to VRAM using channel 5
; Uses parameters stored in RAM to configure the transfer
; ============================================================================
DMA_TransferToVRAM_Ch5:
; Setup DMA channel 5 parameters
	ldx.W #$1801                    ; DMA params: $18 = VRAM write, $01 = increment mode
	stx.B SNES_DMA5PARAM-$4300      ; $4350 = DMA5 control

; Source address from RAM parameters
	ldx.W $01f6                     ; Load source address (low/mid bytes)
	stx.B SNES_DMA5ADDRL-$4300      ; $4352-$4353 = source address
	lda.B #$7f                      ; Source bank = $7f (work RAM)
	sta.B SNES_DMA5ADDRH-$4300      ; $4354 = source bank

; Transfer size
	ldx.W $01f4                     ; Load transfer size
	stx.B SNES_DMA5CNTL-$4300       ; $4355-$4356 = transfer count

; Destination VRAM address
	ldx.W $01f8                     ; Load VRAM destination
	stx.W SNES_VMADDL               ; $2116-$2117 = VRAM address

; Configure VRAM increment mode
	lda.B #$84                      ; Increment after $2119 write, by 128
	sta.W SNES_VMAINC               ; $2115 = VRAM increment mode

; Execute DMA transfer
	lda.B #$20                      ; Enable DMA channel 5 (bit 5)
	sta.W SNES_MDMAEN               ; $420b = start DMA
	rts

; ============================================================================
; DMA Transfer for Palette Data
; ============================================================================
; Address: $0083a8 (Original: AddressA8OriginalCode)
; Transfers palette data to CGRAM using DMA channel 5
; ============================================================================
DMA_TransferPalette:
; Check if palette DMA is requested
	lda.B #$80                      ; Check bit 7
	and.W $00d2                     ; Test flag byte
	beq .noPaletteDMA               ; Skip if not set

; Setup for palette transfer
	lda.B #$80                      ; Standard increment
	sta.W SNES_VMAINC               ; $2115 = increment mode

; Configure DMA channel 5
	ldx.W #$1801                    ; VRAM write mode
	stx.B SNES_DMA5PARAM-$4300      ; DMA5 control

; Source address from parameters
	ldx.W $01ed                     ; Palette data source (low/mid)
	stx.B SNES_DMA5ADDRL-$4300      ; Set source address
	lda.W $01ef                     ; Source bank
	sta.B SNES_DMA5ADDRH-$4300      ; Set source bank

; Transfer size
	ldx.W $01eb                     ; Palette data size
	stx.B SNES_DMA5CNTL-$4300       ; Set transfer count

; Destination address
	ldx.W $0048                     ; VRAM destination from RAM
	stx.W SNES_VMADDL               ; Set VRAM address

; Execute transfer
	lda.B #$20                      ; Enable channel 5
	sta.W SNES_MDMAEN               ; Start DMA

	.noPaletteDMA:
; Additional processing...
	rts

; ============================================================================
; DMA Transfer for Tile Data
; ============================================================================
; Address: $0083e8 (Original: AddressE8OriginalCode)
; Transfers tile graphics data to VRAM
; ============================================================================
DMA_TransferTileData:
; Clear tile transfer flag
	lda.B #$02                      ; Bit 1
	trb.W $00d4                     ; Clear in flag byte

; Setup VRAM increment
	lda.B #$80                      ; Standard increment
	sta.W $2115                     ; VRAM increment register

; Configure DMA channel 5 for tile data
	ldx.W #$2200                    ; Different DMA mode for tiles
	stx.B SNES_DMA5PARAM-$4300      ; DMA5 control

; Source bank for tile data
	lda.B #$07                      ; Bank $07 (ROM data)
	sta.B SNES_DMA5ADDRH-$4300      ; Source bank

; Tile-specific transfer setup
	lda.B #$a8                      ; Tile mode parameter
	ldx.W $0064                     ; Tile data index
	jsr.W SetupTileTransfer         ; Call tile setup routine ($008504)

; Prepare for transfer
	rep #$30                        ; 16-bit mode
	ldx.W #$ff00                    ; Clear mask
	stx.W $00f0                     ; Store mask

; Check transfer mode
	ldx.W $0062                     ; Check transfer type
	lda.W #$6080                    ; Base VRAM address
	cpx.W #$0001                    ; Is it mode 1?
	beq .mode1Transfer              ; Branch if mode 1

; Standard transfer
	jsr.W ExecuteStandardTransfer   ; $008520
	rtl

	.mode1Transfer:
; Special mode 1 transfer
	phk
	plb                             ; Set data bank to current program bank
	sta.W SNES_VMADDL               ; Set VRAM address
	ldx.W #$f0c1                    ; Special transfer data
	ldy.W #$0004                    ; Size parameter
	jmp.W ExecuteSpecialTransfer               ; Execute special transfer

; ============================================================================
; Helper: Setup Tile Transfer Parameters
; ============================================================================
; Address: $008504 (Original: TransferPaletteSet)
; Input: A = mode, X = tile index
; Sets up DMA parameters for tile data transfer
; ============================================================================
SetupTileTransfer:
; [Implementation would analyze actual routine]
; Calculates source address and size based on tile index
; Sets up DMA channel 5 registers appropriately
	rts

; ============================================================================
; Helper: Execute Standard Transfer
; ============================================================================
; Address: $008520 (Original: TransferTilemapRegion)
; Executes a standard DMA transfer to VRAM
; ============================================================================
ExecuteStandardTransfer:
; [Implementation would analyze actual routine]
; Performs the configured DMA operation
	rts

; ============================================================================
; RAM Variables Used by DMA Routines
; ============================================================================
; $00d2 - DMA request flags byte 1
;   Bit 7: Palette DMA requested
;   Bit 6: Reserved
;   Bit 5: Tile transfer pending
;   Bit 4: VRAM transfer mode
; $00d4 - DMA request flags byte 2
;   Bit 7: Tile DMA requested
;   Bit 1: Tile transfer flag
;   Bit 0: General transfer flag
; $00d8 - Additional DMA flags
;   Bit 7: Special transfer mode
;   Bit 1: Palette mode flag
; $00dd - VRAM transfer flags
;   Bit 6: Transfer pending
; $00e2 - Callback flags
;   Bit 6: Callback pending
; $00f0 - Transfer mask word
; $0048 - VRAM destination address (word)
; $0062 - Transfer mode type (word)
; $0064 - Tile data index (word)
; $01eb - Palette data size (word)
; $01ed - Palette source address low/mid (word)
; $01ef - Palette source bank (byte)
; $01f4 - General transfer size (word)
; $01f6 - General source address (word)
; $01f8 - General VRAM destination (word)
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
;    - Source: RAM buffer at $7exxxx
;    - Dest: CGRAM via $2122
;    - Size: Usually 32 bytes (16 colors) or 512 bytes (full palette)
;
; 4. Tilemap Transfer:
;    - Copy tilemap data to VRAM
;    - Source: RAM tilemap buffer
;    - Dest: BG1/BG2/BG3 tilemap areas
;    - Mode: Word transfers
; ============================================================================
