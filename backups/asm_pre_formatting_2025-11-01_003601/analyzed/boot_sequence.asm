; ============================================================================
; FFMQ Boot Sequence Analysis
; ============================================================================
; Analyzed from Diztinguish disassembly bank_00.asm
; Original addresses: $008000-$0080FF
; 
; This file contains the enhanced analysis of the game's boot sequence
; with meaningful labels, detailed comments, and cross-references.
; ============================================================================

; Entry point after SNES reset vector
; This is the first code executed when the game starts
BootEntry:                          ; Original: CODE_008000
    CLC                             ; Clear carry flag
    XCE                             ; Switch to native 65816 mode (not emulation)
    JSR.W InitializeHardware        ; Initialize SNES hardware registers
    JSL.L InitializeGameState       ; Initialize game state ($0D8000)
    
    ; Initialize boot flags
    LDA.B #$00
    STA.L $7E3667                   ; Boot flag 1 = 0
    DEC A                           ; A = $FF
    STA.L $7E3668                   ; Boot flag 2 = $FF
    BRA ContinueBootSequence
    
; Alternative entry point (NMI/Reset handler?)
AlternateEntry:                     ; Original: CODE_008016
    JSR.W InitializeHardware
    LDA.B #$F0
    STA.L $000600                   ; Set interrupt vector?
    JSL.L InitializeInterrupts      ; Setup interrupts ($0D8004)
    
ContinueBootSequence:               ; Original: CODE_008023
    REP #$30                        ; Set A and X/Y to 16-bit mode
    LDX.W #$1FFF                    ; Stack pointer = $1FFF (top of RAM)
    TXS                             ; Transfer X to Stack pointer
    JSR.W ClearMemory               ; Clear work RAM
    
    ; Check for specific hardware flag
    LDA.W #$0040                    ; Bit 6 flag
    AND.W $00DA                     ; Check flag in zero page
    BNE SkipDMAFill                 ; If set, skip DMA fill
    
    ; Perform DMA fill operation
    JSL.L MenuSystemInit            ; Initialize menu system ($0C8080)
    BRA SetupComplete
    
; Third entry point for warm boot
WarmBootEntry:                      ; Original: CODE_00803A
    JSR.W InitializeHardware
    LDA.B #$F0
    STA.L $000600                   ; Interrupt vector
    JSL.L InitializeInterrupts      ; Setup interrupts
    REP #$30                        ; 16-bit mode
    LDX.W #$1FFF                    ; Reset stack
    TXS
    
SetupComplete:                      ; Original: CODE_00804D
    JSR.W ClearMemory               ; Clear RAM again
    SEP #$20                        ; 8-bit accumulator
    
    ; Setup DMA to clear screen
    LDX.W #$1809                    ; DMA parameters: A->B, auto-increment
    STX.W SNES_DMA0PARAM            ; DMA channel 0 control
    LDX.W #$8252                    ; Source address low/mid
    STX.W SNES_DMA0ADDRL            ; DMA source address
    LDA.B #$00                      ; Source bank
    STA.W SNES_DMA0ADDRH            ; DMA source bank
    LDX.W #$0000                    ; Transfer size = 64KB
    STX.W SNES_DMA0CNTL             ; DMA transfer size
    LDA.B #$01                      ; Enable channel 0
    STA.W SNES_MDMAEN               ; Start DMA transfer
    
SkipDMAFill:                        ; Original: CODE_00806E
    JSL.L $00011F                   ; Call unknown routine (BIOS?)
    REP #$30                        ; 16-bit mode
    LDA.W #$0000
    TCD                             ; Set direct page to $0000
    SEP #$20                        ; 8-bit accumulator
    
    ; Enable interrupts
    LDA.W $0112                     ; Load saved interrupt flags
    STA.W SNES_NMITIMEN             ; Enable NMI/IRQ
    CLI                             ; Clear interrupt disable flag
    
    ; Initialize game brightness
    LDA.B #$0F                      ; Full brightness
    STA.W $00AA                     ; Store brightness value
    
    ; Main initialization sequence
    JSL.L WaitForVBlank             ; Wait for vertical blank ($0C8000)
    JSL.L WaitForVBlank             ; Wait again for safety
    
    ; Check save data
    LDA.L $7E3665                   ; Check save data flag
    BNE LoadSaveData                ; If save exists, load it
    
    ; Check for continue data
    LDA.L $700000                   ; SRAM slot 1
    ORA.L $70038C                   ; SRAM slot 2
    ORA.L $700718                   ; SRAM slot 3
    BEQ StartNewGame                ; If all empty, new game
    
    ; Continue from save
    JSL.L ContinueGame              ; Load continue data ($00B950)
    BRA EnterMainLoop
    
LoadSaveData:                       ; Original: CODE_0080A8
    JSR.W LoadSaveGameData
    BRA MainGameLoop
    
StartNewGame:                       ; Original: CODE_0080AD
    JSR.W InitializeNewGame
    
EnterMainLoop:                      ; Original: CODE_0080B0
    ; Clear various flags
    LDA.B #$80
    TRB.W $00DE                     ; Clear bit 7 of flags
    LDA.B #$E0
    TRB.W $0111                     ; Clear bits 5-7
    
    JSL.L WaitForVBlank
    
    ; Setup color math
    LDA.B #$E0                      ; Color math: all layers
    STA.W SNES_COLDATA              ; Set color data
    LDX.W #$0000
    STX.W SNES_CGSWSEL              ; Clear color window
    
    ; Reset scroll positions
    STZ.W SNES_BG1VOFS              ; BG1 vertical scroll = 0
    STZ.W SNES_BG1VOFS              ; Write twice for 16-bit
    
MainGameLoop:                       ; Original: CODE_0080DC
    ; Main game loop continues...
    ; [Additional code would be analyzed here]
    
; ============================================================================
; Subroutines
; ============================================================================

InitializeHardware:                 ; Original: CODE_008247
    ; Initialize all SNES hardware registers
    ; [Implementation at $008247 in bank_00.asm]
    RTS
    
ClearMemory:                        ; Original: CODE_0081F0
    ; Clear work RAM ($7E0000-$7FFFFF)
    ; [Implementation at $0081F0 in bank_00.asm]
    RTS
    
LoadSaveGameData:                   ; Original: CODE_008166
    ; Load save game from SRAM
    ; [Implementation at $008166 in bank_00.asm]
    RTS
    
InitializeNewGame:                  ; Original: CODE_008117
    ; Initialize new game state
    ; [Implementation at $008117 in bank_00.asm]
    RTS

; ============================================================================
; External Routines Referenced
; ============================================================================
; $0D8000 - InitializeGameState - Initialize main game state variables
; $0D8004 - InitializeInterrupts - Setup NMI/IRQ handlers
; $0C8080 - MenuSystemInit - Initialize menu system
; $0C8000 - WaitForVBlank - Wait for vertical blank
; $00B950 - ContinueGame - Load continue data
; ============================================================================

; ============================================================================
; RAM Variables Referenced
; ============================================================================
; $7E3665 - Save data present flag
; $7E3667 - Boot flag 1
; $7E3668 - Boot flag 2
; $000600 - Interrupt vector storage
; $0112   - Saved interrupt enable flags
; $00AA   - Screen brightness value
; $00DA   - Hardware configuration flags
; $00DE   - General flags byte 1
; $0111   - General flags byte 2
;
; SRAM Locations:
; $700000 - Save slot 1 data
; $70038C - Save slot 2 data
; $700718 - Save slot 3 data
; ============================================================================
