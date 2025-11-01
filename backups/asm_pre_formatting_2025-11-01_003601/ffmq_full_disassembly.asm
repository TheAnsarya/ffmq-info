; ==============================================================================
; Final Fantasy Mystic Quest (SNES) - Complete Disassembly
; ==============================================================================
; 
; THIS IS A REAL REBUILD - NOT A PATCHED ROM!
; 
; Build Strategy:
; - Start from NOTHING (no ROM copying!)
; - Build entire ROM from disassembled code
; - Fill all graphics/data from extracted assets
; - Result: 100% assembled from source
;
; Current Status:
; - Code: Being disassembled and commented
; - Graphics: Extracted, needs incbin integration
; - Palettes: Extracted, needs data integration  
; - Text: Extracted, needs assembly data structures
; - Maps: Not yet extracted
; - Audio: Not yet extracted
;
; Real Progress: ~5% (honest assessment)
; - We have the code skeleton from Diztinguish
; - Graphics/palettes extracted but not integrated into build
; - Text extracted but not integrated
; - Most code is uncommented raw disassembly
;
; ==============================================================================

arch 65816
lorom

;===============================================================================
; SNES Header (Required for valid ROM)
;===============================================================================

org $00FFC0
    db "FFMQ DISASSEMBLY    "  ; ROM name (21 bytes)
    
org $00FFD5
    db $20          ; Map mode ($20 = LoROM)
    
org $00FFD6  
    db $00          ; Cartridge type (ROM only)
    
org $00FFD7
    db $09          ; ROM size (512KB = 2^9)
    
org $00FFD8
    db $00          ; RAM size (none)
    
org $00FFD9
    db $01          ; Country code (USA)
    
org $00FFDA
    db $33          ; Publisher code
    
org $00FFDB
    db $00          ; Version number
    
org $00FFDC
    dw $0000        ; Checksum complement (calculated by asar)
    
org $00FFDE
    dw $0000        ; Checksum (calculated by asar)

;===============================================================================
; Interrupt Vectors (Native Mode)
;===============================================================================

org $00FFE4
    dw $0000        ; COP vector
    dw $0000        ; BRK vector
    dw $0000        ; ABORT vector
    dw CODE_008000  ; NMI vector
    dw $0000        ; RESET (unused in native mode)
    dw $0000        ; IRQ vector

;===============================================================================
; Interrupt Vectors (Emulation Mode)  
;===============================================================================

org $00FFF4
    dw $0000        ; COP vector
    dw $0000        ; Reserved
    dw $0000        ; ABORT vector
    dw CODE_008000  ; NMI vector
    dw CODE_008000  ; RESET vector (boot entry point!)
    dw $0000        ; IRQ/BRK vector

;===============================================================================
; SNES Register Definitions
;===============================================================================

incsrc "../include/snes_registers.inc"

;===============================================================================
; RAM Variable Definitions  
;===============================================================================

; TODO: Include RAM map once converted from Diztinguish labels
; incsrc "../include/ram_variables.inc"

;===============================================================================
; Bank $00 - Main Game Engine
;===============================================================================

org $008000

CODE_008000:
    ; ===========================================================================
    ; Boot Sequence - SNES Initialization
    ; ===========================================================================
    ; This is the entry point when the SNES powers on or resets.
    ; First instruction executed after the RESET vector is triggered.
    ; 
    ; Purpose:
    ;   - Switch from 6502 emulation mode to native 65816 mode
    ;   - Initialize hardware registers
    ;   - Set up memory banks and stack
    ;   - Start game initialization
    ;
    ; Technical Details:
    ;   CLC + XCE = Clear carry, then exchange carry with emulation flag
    ;   This switches the CPU from 6502 emulation (power-on default)
    ;   to native 65816 mode, enabling 16-bit registers and extended addressing
    ;
    ; Register State After:
    ;   - CPU in native mode (65816)
    ;   - All registers uninitialized (will be set up by called routines)
    ;   - Stack pointer uninitialized (will be set to $1FFF)
    ; ===========================================================================
    
    CLC                     ; Clear carry flag
    XCE                     ; Exchange carry with emulation flag
                            ; → CPU now in native 65816 mode
    
    JSR.W CODE_008247       ; Initialize hardware registers
    JSL.L CODE_0D8000       ; Initialize subsystem (Bank $0D)
    
    ; ===========================================================================
    ; Initialize Save Game State
    ; ===========================================================================
    ; Sets up flags that indicate whether a save file exists and its state
    ; ===========================================================================
    
    LDA.B #$00              ; A = 0
    STA.L $7E3667           ; Clear save file state flag 1
    DEC A                   ; A = $FF (-1)
    STA.L $7E3668           ; Set save file state flag 2 to $FF
    BRA CODE_008023         ; Skip to main initialization
    
CODE_008016:
    ; ===========================================================================
    ; Secondary Boot Path (called from somewhere else)
    ; ===========================================================================
    
    JSR.W CODE_008247       ; Initialize hardware registers
    LDA.B #$F0              ; A = $F0
    STA.L $000600           ; Store to low RAM (hardware mirror area)
    JSL.L CODE_0D8004       ; Initialize subsystem variant
    
CODE_008023:
    ; ===========================================================================
    ; Stack and Memory Setup
    ; ===========================================================================
    ; Sets up the stack pointer and prepares the system for game execution
    ; ===========================================================================
    
    REP #$30                ; Set A and X/Y to 16-bit mode
    LDX.W #$1FFF            ; X = $1FFF
    TXS                     ; Set stack pointer to $1FFF (top of RAM bank $00)
    
    JSR.W CODE_0081F0       ; Initialize more hardware (details TBD)
    
    ; ===========================================================================
    ; Check Controller State 
    ; ===========================================================================
    ; Checks if specific button combination is held (diagnostic mode?)
    ; ===========================================================================
    
    LDA.W #$0040            ; A = $0040 (bit 6 = some button?)
    AND.W $00DA             ; Mask with controller input at $00DA
    BNE CODE_00806E         ; If button pressed, skip to alternate path
    
    JSL.L CODE_0C8080       ; Call routine in bank $0C
    BRA CODE_00804D         ; Continue to main setup

CODE_00803A:
    ; ===========================================================================
    ; Another Entry Point (possibly soft reset?)
    ; ===========================================================================
    
    JSR.W CODE_008247       ; Initialize hardware registers
    LDA.B #$F0              ; A = $F0  
    STA.L $000600           ; Store to hardware mirror
    JSL.L CODE_0D8004       ; Initialize subsystem
    
    REP #$30                ; 16-bit A, X, Y
    LDX.W #$1FFF            ; Reset stack pointer
    TXS
    
CODE_00804D:
    ; ===========================================================================
    ; DMA Setup for Initial Data Transfer
    ; ===========================================================================
    ; Uses DMA channel 0 to transfer data to hardware registers
    ; This is a fast way to initialize multiple registers at once
    ; ===========================================================================
    
    JSR.W CODE_0081F0       ; Hardware init
    
    SEP #$20                ; 8-bit A, 16-bit X/Y
    
    ; Configure DMA Channel 0
    LDX.W #$1809            ; DMA parameters
    STX.W SNES_DMA0PARAM    ; $4300: DMA control + target register
    
    LDX.W #$8252            ; Source address (low/mid bytes)
    STX.W SNES_DMA0ADDRL    ; $4302-4303: Source address low/mid
    
    LDA.B #$00              ; Source bank = $00
    STA.W SNES_DMA0ADDRH    ; $4304: Source address bank
    
    LDX.W #$0000            ; Transfer size = $0000 (means $10000 = 64KB!)
    STX.W SNES_DMA0CNTL     ; $4305-4306: Transfer size
    
    LDA.B #$01              ; Enable DMA channel 0
    STA.W SNES_MDMAEN       ; $420B: DMA enable register

CODE_00806E:
    ; ===========================================================================
    ; Main Game Initialization Continues
    ; ===========================================================================
    
    JSL.L $00011F           ; Call routine (bank $00, address $011F)
    
    REP #$30                ; 16-bit A, X, Y
    LDA.W #$0000            ; A = 0
    TCD                     ; Set direct page to $0000
    
    SEP #$20                ; 8-bit A
    
    ; Enable interrupts (NMI/IRQ)
    LDA.W $0112             ; Load interrupt enable flags
    STA.W SNES_NMITIMEN     ; $4200: Enable NMI/IRQ
    CLI                     ; Clear interrupt disable flag
    
    ; Set screen brightness
    LDA.B #$0F              ; Full brightness
    STA.W $00AA             ; Store to game variable
    
    ; Call initialization routine twice (why?)
    JSL.L CODE_0C8000       ; Bank $0C initialization
    JSL.L CODE_0C8000       ; Called again (loading screens? fade?)
    
    ; Check save file state
    LDA.L $7E3665           ; Load save state flag
    BNE CODE_0080A8         ; If not zero, handle differently
    
    ; Check if save data exists in SRAM
    LDA.L $700000           ; SRAM byte 1
    ORA.L $70038C           ; OR with SRAM byte 2
    ORA.L $700718           ; OR with SRAM byte 3
    BEQ CODE_0080AD         ; If all zero, no save exists
    
    ; Save data exists - load it
    JSL.L CODE_00B950       ; Load save game
    BRA CODE_0080B0         ; Continue

CODE_0080A8:
    ; Handle different save state
    JSR.W CODE_008166       ; Call routine
    BRA CODE_0080DC         ; Skip to different path

CODE_0080AD:
    ; No save data - start new game
    JSR.W CODE_008117       ; New game initialization

CODE_0080B0:
    ; ===========================================================================
    ; Graphics Setup - Screen Initialization
    ; ===========================================================================
    
    LDA.B #$80              ; Bit 7
    TRB.W $00DE             ; Test and reset bit in game flag
    
    LDA.B #$E0              ; Bits 5-7
    TRB.W $0111             ; Test and reset bits
    
    JSL.L CODE_0C8000       ; Call init routine
    
    ; Set color math to subtract mode
    LDA.B #$E0              ; Color math control
    STA.W SNES_COLDATA      ; $2132: Color math settings
    
    ; Reset windowing and color effects
    LDX.W #$0000
    STX.W SNES_CGSWSEL      ; $2130: Window mask + color math enable
    
    ; Reset BG1 vertical scroll
    STZ.W SNES_BG1VOFS      ; $210E: BG1 V-scroll low byte
    STZ.W SNES_BG1VOFS      ; $210E: BG1 V-scroll high byte

; ===========================================================================
; TODO: Continue disassembling and commenting the rest of bank_00.asm
; ===========================================================================
; This is where the REAL work begins:
; - Analyze each routine's purpose
; - Document inputs, outputs, side effects
; - Give meaningful labels to CODE_XXXXXX  
; - Integrate extracted data (graphics, text, etc.)
; ===========================================================================

; For now, include the rest of the uncommented disassembly
; This will be progressively replaced with documented code

; Placeholder: Include remaining bank_00 code
; (In real implementation, we'd convert and comment all 14,018 lines)

