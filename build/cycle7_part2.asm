;===============================================================================
; WRAM Buffer Management & Screen Setup (CODE_00C4DB - CODE_00C7DD)
;===============================================================================
; This section manages WRAM buffers at $7F5000-$7F5700 for battle menus
; and handles screen initialization for various game modes
;===============================================================================

; CODE_00C4DB - already a stub, implementing now
CODE_00C4DB:
    JSR.W CODE_00C561              ; Clear WRAM buffer 1 ($7F5000)
    JSR.W CODE_00C576              ; Clear WRAM buffer 2 ($7F51B7)  
    JSR.W CODE_00C58B              ; Clear WRAM buffer 3 ($7F536E)
    JSR.W CODE_00C5A0              ; Clear WRAM buffer 4 ($7F551E)
    JSR.W CODE_00C604              ; Jump to CODE_00C5B5 (WRAM $7E3000)
    LDX.W #$C51B                   ; Source data pointer
    LDY.W #$5000                   ; Dest: WRAM $7F5000
    LDA.W #$0006                   ; 7 bytes
    MVN $7F,$00                    ; Block move Bank $00 ? $7F
    LDY.W #$4360                   ; Dest: DMA channel 6
    LDA.W #$0007                   ; 8 bytes
    MVN $00,$00                    ; Block move within Bank $00
    LDY.W #$5367                   ; Dest: WRAM $7F5367
    LDA.W #$0006                   ; 7 bytes
    MVN $7F,$00                    ; Block move Bank $00 ? $7F
    LDY.W #$4370                   ; Dest: DMA channel 7
    LDA.W #$0007                   ; 8 bytes
    MVN $00,$00                    ; Block move within Bank $00
    SEP #$20                       ; 8-bit accumulator
    LDA.B #$C0                     ; Bits 6-7
    TSB.W $0111                    ; Set bits in $0111
    REP #$30                       ; 16-bit A/X/Y
    RTS

DATA_00C51B:
    db $FF,$07,$50,$D9,$05,$51,$00,$42,$0E,$00,$50,$7F,$07,$50,$7F,$FF
    db $6E,$53,$D9,$6C,$54,$00,$42,$10,$67,$53,$7F,$6E,$53,$7F

; Helper - Unknown purpose  
CODE_00C539:
    PEA.W $007F                    ; Push $007F
    PLB                            ; Pull to data bank
    LDY.W #$5016                   ; WRAM address
    JSR.W CODE_00C54B              ; Call fill routine
    LDY.W #$537D                   ; WRAM address
    JSR.W CODE_00C54B              ; Call fill routine
    PLB                            ; Restore data bank
    RTS

CODE_00C54B:
    LDX.W #$000D                   ; 13 iterations
    CLC                            ; Clear carry

CODE_00C54F:
    SEP #$20                       ; 8-bit accumulator
    LDA.B #$00                     ; Value 0
    JSR.W CODE_0099EA              ; Write to WRAM
    REP #$30                       ; 16-bit A/X/Y
    TYA                            ; Y to A
    ADC.W #$0020                   ; Add $20 (32 bytes)
    TAY                            ; Back to Y
    DEX                            ; Decrement counter
    BNE CODE_00C54F                ; Loop if not zero
    RTS

;-------------------------------------------------------------------------------
; WRAM Buffer Clear Routines
;-------------------------------------------------------------------------------
CODE_00C561:
    LDA.W #$0000                   ; Clear value
    STA.L $7F5007                  ; Write to $7F5007
    LDX.W #$5007                   ; Source
    LDY.W #$5009                   ; Dest
    LDA.W #$01AD                   ; 430 bytes
    MVN $7F,$7F                    ; Fill $7F5007-$7F51B5 with 0
    BRA CODE_00C5F5                ; Continue

CODE_00C576:
    LDA.W #$0100                   ; Value $0100
    STA.L $7F51B7                  ; Write to $7F51B7
    LDX.W #$51B7                   ; Source
    LDY.W #$51B9                   ; Dest
    LDA.W #$01AD                   ; 430 bytes
    MVN $7F,$7F                    ; Fill $7F51B7-$7F5365 with $0100
    BRA CODE_00C5F5                ; Continue

CODE_00C58B:
    LDA.W #$0000                   ; Clear value
    STA.L $7F536E                  ; Write to $7F536E
    LDX.W #$536E                   ; Source
    LDY.W #$5370                   ; Dest
    LDA.W #$01AD                   ; 430 bytes
    MVN $7F,$7F                    ; Fill $7F536E-$7F551C with 0
    BRA CODE_00C5CF                ; Continue

CODE_00C5A0:
    LDA.W #$0100                   ; Value $0100
    STA.L $7F551E                  ; Write to $7F551E
    LDX.W #$551E                   ; Source
    LDY.W #$5520                   ; Dest
    LDA.W #$01AD                   ; 430 bytes
    MVN $7F,$7F                    ; Fill $7F551E-$7F56CC with $0100
    BRA CODE_00C5CF                ; Continue

CODE_00C5B5:
    LDA.W #$0000                   ; Clear value
    STA.L $7E3007                  ; Write to $7E3007
    LDX.W #$3007                   ; Source
    LDY.W #$3009                   ; Dest
    LDA.W #$01AD                   ; 430 bytes
    MVN $7E,$7E                    ; Fill $7E3007-$7E31B5 with 0
    LDA.W #$0120                   ; Value $0120
    STA.W $31B5                    ; Store at $7E31B5
    RTS

CODE_00C5CF:
    TYA                            ; Y to A
    SEC                            ; Set carry
    SBC.W #$0042                   ; Subtract $42
    TAY                            ; Back to Y
    LDX.W #$C5E7                   ; Data pointer
    LDA.L $000EC6                  ; Load battle speed flag
    AND.W #$0080                   ; Test bit 7
    BEQ CODE_00C5E4                ; If clear, use first data
    db $A2,$F0,$C5                 ; LDX #$C5F0 (alternate data)

CODE_00C5E4:
    JMP.W CODE_00C75B              ; Jump to sprite setup

DATA_00C5E7:
    db $0C,$20,$06,$24,$06,$26,$08,$28,$00
    db $18,$20,$08,$28,$00

CODE_00C5F5:
    TYA                            ; Y to A
    SEC                            ; Set carry
    SBC.W #$0042                   ; Subtract $42
    TAY                            ; Back to Y
    LDX.W #$C601                   ; Data pointer
    JMP.W CODE_00C75B              ; Jump to sprite setup

DATA_00C601:
    db $20,$28,$00

CODE_00C604:
    JMP.W CODE_00C5B5              ; Jump to WRAM clear

;-------------------------------------------------------------------------------
; Screen Setup Routines
;-------------------------------------------------------------------------------
CODE_00C607:
    JSR.W CODE_00C5B5              ; Clear WRAM $7E3000
    LDA.W #$0060                   ; Value $60
    LDX.W #$3025                   ; Address $7E3025
    JSR.W CODE_00C65A              ; Fill 8 words
    LDX.W #$3035                   ; Address $7E3035
    BRA CODE_00C62C                ; Continue

CODE_00C618:
    JSR.W CODE_00C561              ; Clear WRAM buffer 1
    LDA.W #$0030                   ; Value $30
    LDX.W #$50F5                   ; Address $7F50F5
    BRA CODE_00C62C                ; Continue

CODE_00C623:
    JSR.W CODE_00C576              ; Clear WRAM buffer 2
    LDA.W #$0030                   ; Value $30
    LDX.W #$52A5                   ; Address $7F52A5

CODE_00C62C:
    JSR.W CODE_00C65A              ; Fill 8 words
    SEC                            ; Set carry

CODE_00C630:
    STA.W $0010,X                  ; Store at X+$10
    STA.W $0012,X                  ; Store at X+$12
    STA.W $0014,X                  ; Store at X+$14
    STA.W $0016,X                  ; Store at X+$16
    STA.W $0018,X                  ; Store at X+$18
    STA.W $001A,X                  ; Store at X+$1A
    STA.W $001C,X                  ; Store at X+$1C
    STA.W $001E,X                  ; Store at X+$1E
    TAY                            ; Transfer to Y
    REP #$30                       ; 16-bit A/X/Y
    TXA                            ; X to A
    ADC.W #$000F                   ; Add 15
    TAX                            ; Back to X
    SEP #$20                       ; 8-bit accumulator
    TYA                            ; Y to A
    SBC.B #$07                     ; Subtract 7
    BNE CODE_00C630                ; Loop if not zero
    REP #$30                       ; 16-bit A/X/Y
    RTS

CODE_00C65A:
    SEP #$20                       ; 8-bit accumulator
    STA.W $0000,X                  ; Store at X+0
    STA.W $0002,X                  ; Store at X+2
    STA.W $0004,X                  ; Store at X+4
    STA.W $0006,X                  ; Store at X+6
    STA.W $0008,X                  ; Store at X+8
    STA.W $000A,X                  ; Store at X+10
    STA.W $000C,X                  ; Store at X+12
    STA.W $000E,X                  ; Store at X+14
    RTS
