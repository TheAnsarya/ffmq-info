; Bank $02 Cycle 17: Complex Graphics Rendering and Multi-Bank Coordination Engine
; Advanced graphics data processing with multi-bank memory coordination
; Complex DMA transfer systems and sprite data management
; Sophisticated pattern rendering with bit manipulation and data transformation
; Advanced tile processing and graphics buffer management
; Complex memory addressing and bank switching operations
; High-performance graphics rendering with optimized data transfer

; Advanced Graphics Data Processing Engine
; Complex multi-bank data transfer and coordination system
CODE_02E021:
                       PHP                                  ; Save processor status
                       REP #$30                             ; 16-bit mode
                       LDX.W #$E04F                         ; Graphics configuration table
                       LDY.W #$0A8A                         ; Target memory address
                       LDA.W #$0006                         ; Transfer 7 bytes
                       MVN $02,$02                          ; Block move within bank
                       SEP #$20                             ; 8-bit accumulator
                       REP #$10                             ; 16-bit index
                       LDY.W #$0010                         ; Loop count (16 iterations)
                       LDX.W $0A9D                          ; Load graphics base address

; Graphics Data Processing Loop
; High-speed graphics data extraction and transformation
CODE_02E03A:
                       LDA.L UNREACH_0CF425,X               ; Load graphics byte from bank $0C
                       INX                                  ; Next graphics byte
                       JSR.W CODE_02E056                    ; Call graphics processor
                       DEY                                  ; Decrement loop counter
                       BNE CODE_02E03A                      ; Continue processing loop
                       LDA.W $0A9F                          ; Load special graphics flag
                       AND.B #$0F                           ; Mask lower 4 bits
                       JSR.W CODE_02E056                    ; Process special graphics data
                       PLP                                  ; Restore processor status
                       RTS                                  ; Return to caller

; Graphics Configuration Data Table
; Complex graphics setup parameters
DATA8_02E04F:
                       db $0C,$00,$00,$00,$A0,$5D,$06       ; Graphics configuration parameters

; Advanced Graphics Processing and Calculation Engine
; Complex graphics data transformation with mathematical operations
CODE_02E056:
                       PHX                                  ; Save X register
                       PHY                                  ; Save Y register
                       PHP                                  ; Save processor status
                       SEP #$20                             ; 8-bit accumulator
                       REP #$10                             ; 16-bit index
                       STA.W $4202                          ; Set multiplicand
                       LDA.B #$06                           ; Set multiplier (6)
                       JSL.L CODE_00971E                    ; Call multiplication routine
                       LDX.W $4216                          ; Load multiplication result
                       LDY.W #$0004                         ; Process 4 data segments

; Graphics Data Segment Processing Loop
CODE_02E06C:
                       SEP #$20                             ; 8-bit accumulator
                       REP #$10                             ; 16-bit index
                       LDA.L DATA8_0CEF85,X                 ; Load graphics data segment
                       INX                                  ; Next data byte
                       STA.W $4202                          ; Set new multiplicand
                       LDA.B #$18                           ; Set multiplier (24)
                       JSL.L CODE_00971E                    ; Call multiplication routine
                       REP #$30                             ; 16-bit mode
                       LDA.W $4216                          ; Load calculation result
                       CLC                                  ; Clear carry
                       ADC.W #$D785                         ; Add graphics base offset
                       STA.W $0A8B                          ; Store graphics address
                       JSL.L CODE_02E1C3                    ; Call graphics renderer
                       DEY                                  ; Decrement segment counter
                       BNE CODE_02E06C                      ; Continue segment processing
                       PLP                                  ; Restore processor status
                       PLY                                  ; Restore Y register
                       PLX                                  ; Restore X register
                       RTS                                  ; Return to caller

; Complex Graphics Buffer Management Engine
; Advanced graphics buffer operations with multi-bank coordination
CODE_02E095:
                       PHP                                  ; Save processor status
                       PHB                                  ; Save data bank
                       PHD                                  ; Save direct page
                       REP #$30                             ; 16-bit mode
                       PEA.W $0A00                          ; Set direct page to $0A00
                       PLD                                  ; Load new direct page
                       LDA.W #$00C0                         ; Graphics buffer offset 1
                       CLC                                  ; Clear carry
                       ADC.W #$C040                         ; Add graphics base address
                       TAY                                  ; Set as destination
                       LDA.W $0AA0                          ; Load graphics parameter
                       AND.W #$00FF                         ; Mask to 8-bit
                       ASL A                                ; Multiply by 2
                       ASL A                                ; Multiply by 4
                       ASL A                                ; Multiply by 8
                       ASL A                                ; Multiply by 16
                       ADC.W #$F285                         ; Add graphics data base
                       TAX                                  ; Set as source
                       LDA.W #$000F                         ; Transfer 16 bytes
                       MVN $7E,$0C                          ; Block move (bank $0C to WRAM)

; Second Graphics Buffer Operation
                       LDA.W #$00E0                         ; Graphics buffer offset 2
                       CLC                                  ; Clear carry
                       ADC.W #$C040                         ; Add graphics base address
                       TAY                                  ; Set as destination
                       LDA.W $0A9F                          ; Load secondary graphics parameter
                       AND.W #$00F0                         ; Mask upper 4 bits
                       CLC                                  ; Clear carry
                       ADC.W #$F285                         ; Add graphics data base
                       TAX                                  ; Set as source
                       LDA.W #$000F                         ; Transfer 16 bytes
                       MVN $7E,$0C                          ; Block move (bank $0C to WRAM)
                       SEP #$20                             ; 8-bit accumulator
                       REP #$10                             ; 16-bit index
                       PLD                                  ; Restore direct page
                       PLB                                  ; Restore data bank
                       PLP                                  ; Restore processor status
                       RTS                                  ; Return to caller

; Advanced Display Coordination and DMA Engine
; Complex display list processing with DMA optimization
CODE_02E0DB:
                       PHA                                  ; Save accumulator
                       PHX                                  ; Save X register
                       PHY                                  ; Save Y register
                       PHP                                  ; Save processor status
                       SEP #$20                             ; 8-bit accumulator
                       REP #$10                             ; 16-bit index
                       LDX.W #$E180                         ; Display configuration table
                       LDY.W #$0A8A                         ; Target address
                       LDA.B #$00                           ; Clear high byte
                       XBA                                  ; Exchange bytes
                       LDA.B #$06                           ; Transfer 6 bytes
                       MVN $02,$02                          ; Block move within bank
                       LDY.W #$0000                         ; Initialize display index

; Display List Processing Loop
CODE_02E0F4:
                       LDX.W DATA8_02E187,Y                 ; Load display list entry
                       STX.B $8B                            ; Store as graphics address
                       LDA.B #$04                           ; Process 4 display elements

; Display Element Processing Loop
CODE_02E0FB:
                       JSL.L CODE_02E1C3                    ; Call display renderer
                       DEC A                                ; Decrement element counter
                       BNE CODE_02E0FB                      ; Continue element processing
                       INY                                  ; Next display list entry
                       INY                                  ; (16-bit increment)
                       CPY.W #$003C                         ; Check display list limit
                       BNE CODE_02E0F4                      ; Continue display processing

; Advanced Display Synchronization
                       LDA.B #$04                           ; Set sync counter
                       STA.B $E4                            ; Store sync value

; VBlank Synchronization Loop
CODE_02E10D:
                       LDA.B $E4                            ; Load sync counter
                       BNE CODE_02E10D                      ; Wait for VBlank

; Special Graphics Mode Processing
                       LDA.B #$06                           ; Set graphics mode
                       STA.B $90                            ; Store graphics mode
                       LDX.W #$7800                         ; Graphics buffer address
                       STX.B $8E                            ; Store buffer address
                       LDA.B #$09                           ; Set bank parameter
                       STA.B $8A                            ; Store bank value
                       LDX.W #$FB9D                         ; Special graphics data
                       STX.B $8B                            ; Store data address
                       LDA.B #$2B                           ; Process 43 elements

; Special Graphics Processing Loop
CODE_02E125:
                       JSL.L CODE_02E1C3                    ; Call special renderer
                       DEC A                                ; Decrement counter
                       BNE CODE_02E125                      ; Continue processing

; Secondary Graphics Mode Setup
                       LDX.W #$F420                         ; Secondary graphics data
                       STX.B $8B                            ; Store data address
                       LDA.B #$04                           ; Set bank parameter
                       STA.B $8A                            ; Store bank value
                       LDA.B #$10                           ; Process 16 elements

; Secondary Graphics Processing Loop
CODE_02E137:
                       JSL.L CODE_02E1C3                    ; Call secondary renderer
                       DEC A                                ; Decrement counter
                       BNE CODE_02E137                      ; Continue processing

; Tertiary Graphics Mode Setup
                       LDA.B #$05                           ; Set tertiary bank
                       STA.B $8A                            ; Store bank value
                       LDX.W #$B470                         ; Tertiary graphics data
                       STX.B $8B                            ; Store data address
                       LDA.B #$04                           ; Process 4 elements

; Tertiary Graphics Processing Loop
CODE_02E149:
                       JSL.L CODE_02E1C3                    ; Call tertiary renderer
                       DEC A                                ; Decrement counter
                       BNE CODE_02E149                      ; Continue processing

; Final Graphics Operations
                       LDX.W #$CC88                         ; Final graphics data 1
                       STX.B $8B                            ; Store data address
                       JSL.L CODE_02E1C3                    ; Call renderer
                       LDX.W #$CDA8                         ; Final graphics data 2
                       STX.B $8B                            ; Store data address
                       JSL.L CODE_02E1C3                    ; Call renderer
                       LDX.W #$CE08                         ; Final graphics data 3
                       STX.B $8B                            ; Store data address
                       JSL.L CODE_02E1C3                    ; Call renderer
                       LDA.B #$02                           ; Clear mode flag
                       TRB.B $90                            ; Test and reset bit
                       JSL.L CODE_02E1C3                    ; Call final renderer
                       LDA.B #$08                           ; Set final sync
                       STA.B $E4                            ; Store sync value

; Final Synchronization Loop
CODE_02E177:
                       LDA.B $E4                            ; Load sync counter
                       BNE CODE_02E177                      ; Wait for completion
                       PLP                                  ; Restore processor status
                       PLY                                  ; Restore Y register
                       PLX                                  ; Restore X register
                       PLA                                  ; Restore accumulator
                       RTS                                  ; Return to caller

; Display Configuration Data Table
DATA8_02E180:
                       db $04,$20,$9A,$00,$00,$78,$06       ; Display configuration parameters

; Display List Data Table
; Complex display address mapping for advanced graphics rendering
DATA8_02E187:
                       db $20,$9A,$80,$9A,$E0,$9A,$40,$9B,$80,$CD,$C0,$CF,$A0,$9B,$00,$9C
                       db $60,$9C,$C0,$9C,$E0,$D9,$C0,$D8,$20,$9D,$80,$9D,$E0,$9D,$40,$9E
                       db $80,$DC,$60,$DB,$A0,$9E,$00,$9F,$60,$9F,$C0,$9F,$60,$DE,$40,$DD
                       db $20,$A0,$80,$A0,$E0,$A0,$40,$A1,$C0,$E1,$A0,$E0

; Advanced Graphics Rendering Engine with Multi-System Coordination
; Complex graphics rendering with bank switching and DMA optimization
CODE_02E1C3:
                       PHD                                  ; Save direct page
                       PHA                                  ; Save accumulator
                       PHX                                  ; Save X register
                       PHY                                  ; Save Y register
                       PHP                                  ; Save processor status
                       SEP #$20                             ; 8-bit accumulator
                       REP #$10                             ; 16-bit index
                       PEA.W $2100                          ; Set direct page to PPU
                       PLD                                  ; Load PPU direct page
                       PHB                                  ; Save data bank
                       LDA.W $0A8A                          ; Load source bank
                       LDY.W $0A8B                          ; Load source address
                       PHA                                  ; Save bank
                       PLB                                  ; Set as data bank
                       LDA.B #$04                           ; Check mode flag
                       TRB.W $0A90                          ; Test and reset bit
                       BEQ CODE_02E1EA                      ; Branch if clear

; WRAM Address Setup
                       LDA.W $0A8D                          ; Load WRAM bank
                       STA.B SNES_WMADDH-$2100              ; Set WRAM bank register
                       LDX.W $0A8E                          ; Load WRAM address
                       STX.B SNES_WMADDL-$2100              ; Set WRAM address registers

; Graphics Mode Detection and Processing
CODE_02E1EA:
                       LDA.W $0A90                          ; Load graphics mode flags
                       BIT.B #$02                           ; Test mode bit 2
                       BNE CODE_02E1F6                      ; Branch if set
                       JSR.W CODE_02E34E                    ; Call clear mode renderer
                       BRA CODE_02E219                      ; Continue to next phase

; Advanced Mode Processing
CODE_02E1F6:
                       BIT.B #$08                           ; Test mode bit 8
                       BEQ CODE_02E1FF                      ; Branch if clear
                       JSR.W CODE_02E3E4                    ; Call bit pattern renderer
                       BRA CODE_02E202                      ; Continue processing

; Standard Mode Processing
CODE_02E1FF:
                       JSR.W CODE_02E454                    ; Call standard renderer

; Final Processing Phase
CODE_02E202:
                       LDA.W $0A90                          ; Load graphics mode flags
                       BIT.B #$10                           ; Test mode bit 16
                       BEQ CODE_02E219                      ; Branch if clear
                       LDA.W $0A8D                          ; Load WRAM bank
                       LDY.W $0A8E                          ; Load WRAM address
                       CLC                                  ; Clear carry
                       AND.B #$01                           ; Mask bank bit
                       ADC.B #$7E                           ; Add WRAM base bank
                       PHA                                  ; Save bank
                       PLB                                  ; Set as data bank
                       JSR.W CODE_02E475                    ; Call WRAM processor

; Address Update and Cleanup
CODE_02E219:
                       PLB                                  ; Restore data bank
                       REP #$20                             ; 16-bit accumulator
                       LDA.W $0A8E                          ; Load current address
                       CLC                                  ; Clear carry
                       ADC.W #$0020                         ; Add 32 bytes offset
                       STA.W $0A8E                          ; Store updated address
                       LDA.W $0A8B                          ; Load graphics address
                       CLC                                  ; Clear carry
                       ADC.W #$0018                         ; Add 24 bytes offset
                       STA.W $0A8B                          ; Store updated address
                       PLP                                  ; Restore processor status
                       PLY                                  ; Restore Y register
                       PLX                                  ; Restore X register
                       PLA                                  ; Restore accumulator
                       PLD                                  ; Restore direct page
                       RTL                                  ; Return to caller

; Bit Manipulation Table for Graphics Processing
; Complex bit pattern lookup table for efficient graphics transformation
DATA8_02E236:
                       db $00,$80,$40,$C0,$20,$A0,$60,$E0,$10,$90,$50,$D0,$30,$B0,$70,$F0
                       db $08,$88,$48,$C8,$28,$A8,$68,$E8,$18,$98,$58,$D8,$38,$B8,$78,$F8
                       db $04,$84,$44,$C4,$24,$A4,$64,$E4,$14,$94,$54,$D4,$34,$B4,$74,$F4
                       db $0C,$8C,$4C,$CC,$2C,$AC,$6C,$EC,$1C,$9C,$5C,$DC,$3C,$BC,$7C,$FC
                       db $02,$82,$42,$C2,$22,$A2,$62,$E2,$12,$92,$52,$D2,$32,$B2,$72,$F2
                       db $0A,$8A,$4A,$CA,$2A,$AA,$6A,$EA,$1A,$9A,$5A,$DA,$3A,$BA,$7A,$FA
                       db $06,$86,$46,$C6,$26,$A6,$66,$E6,$16,$96,$56,$D6,$36,$B6,$76,$F6
                       db $0E,$8E,$4E,$CE,$2E,$AE,$6E,$EE,$1E,$9E,$5E,$DE,$3E,$BE,$7E,$FE
                       db $01,$81,$41,$C1,$21,$A1,$61,$E1,$11,$91,$51,$D1,$31,$B1,$71,$F1
                       db $09,$89,$49,$C9,$29,$A9,$69,$E9,$19,$99,$59,$D9,$39,$B9,$79,$F9
                       db $05,$85,$45,$C5,$25,$A5,$65,$E5,$15,$95,$55,$D5,$35,$B5,$75,$F5
                       db $0D,$8D,$4D,$CD,$2D,$AD,$6D,$ED,$1D,$9D,$5D,$DD,$3D,$BD,$7D,$FD
                       db $03,$83,$43,$C3,$23,$A3,$63,$E3,$13,$93,$53,$D3,$33,$B3,$73,$F3
                       db $0B,$8B,$4B,$CB,$2B,$AB,$6B,$EB,$1B,$9B,$5B,$DB,$3B,$BB,$7B,$FB
                       db $07,$87,$47,$C7,$27,$A7,$67,$E7,$17,$97,$57,$D7,$37,$B7,$77,$F7
                       db $0F,$8F,$4F,$CF,$2F,$AF,$6F,$EF,$1F,$9F,$5F,$DF,$3F,$BF,$7F,$FF

; Memory Clear Processing Engine
; High-speed memory clearing with optimized WRAM operations
CODE_02E34E:
                       PHP                                  ; Save processor status
                       SEP #$20                             ; 8-bit accumulator
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 1
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 2
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 3
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 4
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 5
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 6
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 7
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 8
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 9
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 10
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 11
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 12
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 13
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 14
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 15
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 16
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 17
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 18
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 19
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 20
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 21
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 22
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 23
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 24
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 25
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 26
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 27
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 28
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 29
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 30
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 31
                       STZ.B SNES_WMDATA-$2100              ; Clear WRAM data 32
                       PLP                                  ; Restore processor status
                       RTS                                  ; Return to caller

; Advanced Bit Pattern Rendering Engine
; Complex bit pattern processing with lookup table transformation
CODE_02E3E4:
                       PHX                                  ; Save X register
                       PEA.W $2100                          ; Set direct page to PPU
                       PLD                                  ; Load PPU direct page
                       LDA.B #$00                           ; Clear accumulator
                       XBA                                  ; Exchange bytes
                       LDX.W #$0010                         ; Process 16 bytes

; First Pattern Processing Loop
CODE_02E3EF:
                       PHX                                  ; Save loop counter
                       LDA.W $0000,Y                        ; Load pattern byte
                       INY                                  ; Next source byte
                       TAX                                  ; Transfer to index
                       LDA.L DATA8_02E236,X                 ; Load transformed pattern
                       STA.B SNES_WMDATA-$2100              ; Write to WRAM
                       PLX                                  ; Restore loop counter
                       DEX                                  ; Decrement counter
                       BNE CODE_02E3EF                      ; Continue first loop
                       LDX.W #$0008                         ; Process 8 more bytes

; Second Pattern Processing Loop
CODE_02E402:
                       PHX                                  ; Save loop counter
                       LDA.W $0000,Y                        ; Load pattern byte
                       INY                                  ; Next source byte
                       TAX                                  ; Transfer to index
                       LDA.L DATA8_02E236,X                 ; Load transformed pattern
                       STA.B SNES_WMDATA-$2100              ; Write to WRAM
                       STZ.B SNES_WMDATA-$2100              ; Write zero padding
                       PLX                                  ; Restore loop counter
                       DEX                                  ; Decrement counter
                       BNE CODE_02E402                      ; Continue second loop
                       PLX                                  ; Restore X register
                       RTS                                  ; Return to caller

; Standard Graphics Rendering Engine
; High-performance standard graphics processing with direct WRAM access
CODE_02E454:
                       PHX                                  ; Save X register
                       PEA.W $2100                          ; Set direct page to PPU
                       PLD                                  ; Load PPU direct page
                       LDX.W #$0010                         ; Process 16 bytes

; Standard Graphics Loop
CODE_02E45C:
                       LDA.W $0000,Y                        ; Load graphics byte
                       INY                                  ; Next source byte
                       STA.B SNES_WMDATA-$2100              ; Write to WRAM
                       DEX                                  ; Decrement counter
                       BNE CODE_02E45C                      ; Continue standard loop
                       LDX.W #$0008                         ; Process 8 more bytes

; Standard Graphics Padding Loop
CODE_02E468:
                       LDA.W $0000,Y                        ; Load graphics byte
                       INY                                  ; Next source byte
                       STA.B SNES_WMDATA-$2100              ; Write to WRAM
                       STZ.B SNES_WMDATA-$2100              ; Write zero padding
                       DEX                                  ; Decrement counter
                       BNE CODE_02E468                      ; Continue padding loop
                       PLX                                  ; Restore X register
                       RTS                                  ; Return to caller

; WRAM Graphics Combination Engine
; Advanced graphics compositing with logical OR operations
CODE_02E475:
                       PHX                                  ; Save X register
                       LDX.W #$0008                         ; Process 8 combinations

; Graphics Combination Loop
CODE_02E479:
                       LDA.W $0000,Y                        ; Load source graphics 1
                       ORA.W $0010,Y                        ; OR with graphics 2
                       INY                                  ; Next source byte
                       ORA.W $0000,Y                        ; OR with graphics 3
                       STA.W $0010,Y                        ; Store combined result
                       INY                                  ; Next destination byte
                       DEX                                  ; Decrement counter
                       BNE CODE_02E479                      ; Continue combination
                       PLX                                  ; Restore X register
                       RTS                                  ; Return to caller

; **CYCLE 17 COMPLETION MARKER - Advanced Graphics Rendering and Multi-Bank Coordination Engine Complete**
