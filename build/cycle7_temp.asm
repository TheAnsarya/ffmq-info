
DATA_00C3D8:
    db $C3,$95,$03

;-------------------------------------------------------------------------------
; Menu Scrolling System (CODE_00C3DB - CODE_00C439)
;-------------------------------------------------------------------------------
CODE_00C3DB:
    LDA.W #$0305                   ; Menu mode $0305
    STA.B $03                      ; Store in $03
    LDX.W #$FFF0                   ; Position offset (-16)
    STX.B $8E                      ; Set position
    BRA CODE_00C439                ; Jump to menu display

CODE_00C3E7:
    LDA.W #$CF30                   ; Button mask
    JSR.W CODE_00B930              ; Poll input
    BIT.W #$0300                   ; Test Y/X buttons
    BNE CODE_00C407                ; If pressed, process
    BIT.W #$0C00                   ; Test L/R buttons
    BNE CODE_00C439                ; If pressed, refresh
    BIT.W #$8000                   ; Test A button
    BEQ CODE_00C3E7                ; If not pressed, loop
    JSR.W CODE_00B91C              ; Update sprite
    STZ.B $8E                      ; Clear position
    LDX.W #$C444                   ; Menu data
    JMP.W CODE_009BC4              ; Show menu

CODE_00C407:
    SEP #$20                       ; 8-bit accumulator
    LDA.B $01                      ; Load menu option
    CMP.B #$04                     ; Check if option 4
    BEQ CODE_00C423                ; If yes, scroll down
    LDA.B $04                      ; Load scroll position
    CMP.B #$03                     ; Check if at top
    BEQ CODE_00C437                ; If yes, can't scroll up
    DEC.B $04                      ; Decrement scroll
    LDA.B $02                      ; Load current index
    SBC.B #$02                     ; Subtract 2
    BCS CODE_00C41F                ; If no underflow, continue
    LDA.B #$00                     ; Clamp to 0

CODE_00C41F:
    STA.B $02                      ; Store new index
    BRA CODE_00C437                ; Continue

CODE_00C423:
    LDA.B $04                      ; Load scroll position
    CMP.B #$04                     ; Check if at bottom
    BEQ CODE_00C437                ; If yes, can't scroll down
    INC.B $04                      ; Increment scroll
    LDA.B $02                      ; Load current index
    ADC.B #$02                     ; Add 2
    CMP.B #$04                     ; Check if >= 4
    BNE CODE_00C435                ; If not, continue
    LDA.B #$03                     ; Clamp to 3

CODE_00C435:
    STA.B $02                      ; Store new index

CODE_00C437:
    REP #$30                       ; 16-bit A/X/Y

CODE_00C439:
    LDX.W #$C441                   ; Menu data
    JSR.W CODE_009BC4              ; Update menu
    BRA CODE_00C3E7                ; Loop

DATA_00C441:
    db $8E,$90,$03

DATA_00C444:
    db $47,$91,$03

;-------------------------------------------------------------------------------
; Another Menu Scrolling System (CODE_00C447 - CODE_00C494)
;-------------------------------------------------------------------------------
CODE_00C447:
    LDA.W #$0305                   ; Menu mode $0305
    STA.B $03                      ; Store in $03
    LDX.W #$FFF0                   ; Position offset (-16)
    STX.B $8E                      ; Set position
    BRA CODE_00C494                ; Jump to menu display

CODE_00C453:
    LDA.W #$CF30                   ; Button mask
    JSR.W CODE_00B930              ; Poll input
    BIT.W #$0300                   ; Test Y/X buttons
    BNE CODE_00C473                ; If pressed, process
    BIT.W #$0C00                   ; Test L/R buttons
    BNE CODE_00C494                ; If pressed, refresh
    BIT.W #$8000                   ; Test A button
    BEQ CODE_00C453                ; If not pressed, loop
    JSR.W CODE_00B91C              ; Update sprite
    STZ.B $8E                      ; Clear position
    LDX.W #$C49F                   ; Menu data
    JMP.W CODE_009BC4              ; Show menu

CODE_00C473:
    SEP #$20                       ; 8-bit accumulator
    LDA.B $01                      ; Load menu option
    CMP.B #$04                     ; Check if option 4
    BEQ CODE_00C488                ; If yes, scroll to bottom
    LDA.B #$03                     ; Load 3
    CMP.B $04                      ; Compare with scroll position
    BEQ CODE_00C492                ; If equal, done
    STA.B $04                      ; Store 3
    DEC A                          ; Decrement to 2
    STA.B $02                      ; Store index
    BRA CODE_00C492                ; Continue

CODE_00C488:
    LDA.B #$01                     ; Load 1
    CMP.B $04                      ; Compare with scroll position
    BEQ CODE_00C492                ; If equal, done
    STA.B $04                      ; Store 1
    STZ.B $02                      ; Clear index

CODE_00C492:
    REP #$30                       ; 16-bit A/X/Y

CODE_00C494:
    LDX.W #$C49C                   ; Menu data
    JSR.W CODE_009BC4              ; Update menu
    BRA CODE_00C453                ; Loop

DATA_00C49C:
    db $E3,$91,$03

DATA_00C49F:
    db $47,$91,$03

;-------------------------------------------------------------------------------
; Wait Loop with Input Polling (CODE_00C4A2 - CODE_00C4D7)
;-------------------------------------------------------------------------------
CODE_00C4A2:
    LDX.W #$FFF0                   ; Position offset (-16)
    STX.B $8E                      ; Set position

CODE_00C4A7:
    JSL.L CODE_0096A0              ; Call external routine
    LDA.W #$0080                   ; Bit 7 mask
    AND.W $00D9                    ; Test flag
    BEQ CODE_00C4C1                ; If clear, continue
    db $A9,$80,$00,$1C,$D9,$00,$A2,$D8,$C4,$20,$C4,$9B,$80,$E6  ; Data/unreachable

CODE_00C4C1:
    LDA.B $07                      ; Load input result
    AND.W #$BFCF                   ; Mask buttons
    BEQ CODE_00C4A7                ; If no button, loop
    AND.W #$8000                   ; Test A button
    BNE CODE_00C4D2                ; If pressed, confirm
    JSR.W CODE_00B912              ; Update sprite mode
    BRA CODE_00C4A7                ; Loop

CODE_00C4D2:
    JSR.W CODE_00B91C              ; Update sprite
    STZ.B $8E                      ; Clear position
    RTS

DATA_00C4D8:
    db $D1,$9C,$03
