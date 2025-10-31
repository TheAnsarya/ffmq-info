; ===========================================================================
; FFMQ Bank $02 - Cycle 9: Game State Validation and Controller Systems
; Advanced Input Processing, Sound Effect Management, and Validation Logic
; ===========================================================================

;----------------------------------------------------------------------------
; RTS Return System
;----------------------------------------------------------------------------
RTS                                  ;02A271|60      |      ;
                                                            ;      |        |      ;
                                                            ;      |        |      ;

;----------------------------------------------------------------------------
; System Initialization Data Tables
;----------------------------------------------------------------------------
DATA8_02A272:
                       db $07                               ;02A272|        |      ;
                                                            ;      |        |      ;

; Configuration Parameter Array for System Setup
DATA8_02A273:
                       db $17,$27,$37,$47,$57               ;02A273|        |      ;
                                                            ;      |        |      ;

; System State Default Value
DATA8_02A278:
                       db $00                               ;02A278|        |      ;
                                                            ;      |        |      ;

; Audio Waveform Pattern Data for Sound Effects
; Complex 16-bit sound synthesis parameters
DATA8_02A279:
                       db $00,$08,$21,$52,$4A,$F7,$5E,$9C,$73,$9C,$73,$F7,$5E,$52,$4A,$08;02A279|        |      ;
                       db $21,$00,$00                       ;02A289|        |      ;
                                                            ;      |        |      ;

;----------------------------------------------------------------------------
; Game State Processing and Input Handler
; Primary game loop controller management system
;----------------------------------------------------------------------------
CODE_02A28C:
                       PEA.W $0400                          ;02A28C|F40004  |020400; Set direct page to $0400
                       PLD                                  ;02A28F|2B      |      ;
                       SEP #$20                             ;02A290|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02A292|C210    |      ; 16-bit index
                       LDA.B $17                            ;02A294|A517    |000417; Check system interrupt flag
                       AND.B #$80                           ;02A296|2980    |      ; Test high bit for pause state
                       BEQ CODE_02A29B                      ;02A298|F001    |02A29B; Continue if not paused
                       RTS                                  ;02A29A|60      |      ; Exit if paused
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Primary Input State Machine Processor
CODE_02A29B:
                       STZ.B $D0                            ;02A29B|64D0    |0004D0; Clear status flag
                       LDA.B $8B                            ;02A29D|A58B    |00048B; Check game state mode
                       CMP.B #$01                           ;02A29F|C901    |      ; Test for mode 1 (menu/interface)
                       BEQ CODE_02A2A6                      ;02A2A1|F003    |02A2A6; Branch to menu handler
                       JMP.W CODE_02A373                    ;02A2A3|4C73A3  |02A373; Jump to game mode handler
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Menu Interface Controller Processing
CODE_02A2A6:
                       LDX.W #$04C4                         ;02A2A6|A2C404  |      ; Load controller data pointer
                       STX.B $92                            ;02A2A9|8692    |000492; Store data pointer
                       STZ.B $8B                            ;02A2AB|648B    |00048B; Reset game state
                       LDA.B #$01                           ;02A2AD|A901    |      ; Set controller count
                       STA.B $8C                            ;02A2AF|858C    |00048C; Store controller count
                       JSR.W CODE_02A40C                    ;02A2B1|200CA4  |02A40C; Process controller input
                       REP #$30                             ;02A2B4|C230    |      ; 16-bit mode
                       LDA.B $C4                            ;02A2B6|A5C4    |0004C4; Read controller 1 state
                       ORA.B $C6                            ;02A2B8|05C6    |0004C6; Combine with controller 2
                       BNE CODE_02A2C6                      ;02A2BA|D00A    |02A2C6; Branch if input detected
                       SEP #$20                             ;02A2BC|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02A2BE|C210    |      ; 16-bit index
                       LDA.B $D0                            ;02A2C0|A5D0    |0004D0; Check idle counter
                       DEC A                                ;02A2C2|3A      |      ; Decrement idle time
                       BEQ UNREACH_02A32E                   ;02A2C3|F069    |02A32E; Branch to idle handler
                       RTS                                  ;02A2C5|60      |      ; Return if no input
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Input Detected Processing Branch
CODE_02A2C6:
                       SEP #$20                             ;02A2C6|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02A2C8|C210    |      ; 16-bit index
                       LDA.B #$FF                           ;02A2CA|A9FF    |      ; Set active input flag
                       STA.B $D0                            ;02A2CC|85D0    |0004D0; Store active flag
                       LDA.B #$01                           ;02A2CE|A901    |      ; Set input processing mode
                       STA.B $8B                            ;02A2D0|858B    |00048B; Update game state
                       STZ.B $CE                            ;02A2D2|64CE    |0004CE; Clear direction state
                       REP #$30                             ;02A2D4|C230    |      ; 16-bit mode
                       LDA.B $C4                            ;02A2D6|A5C4    |0004C4; Read controller 1
                       BIT.W #$0100                         ;02A2D8|890001  |      ; Test for special button
                       BEQ CODE_02A2E0                      ;02A2DB|F003    |02A2E0; Branch if normal input
                       JMP.W CODE_02A501                    ;02A2DD|4C01A5  |02A501; Handle special button
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Standard Input Direction Processing
CODE_02A2E0:
                       AND.W #$00E0                         ;02A2E0|29E000  |      ; Mask direction bits
                       BEQ CODE_02A2E8                      ;02A2E3|F003    |02A2E8; Branch if no direction
                       JMP.W CODE_02A528                    ;02A2E5|4C28A5  |02A528; Process directional input
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Button Press Analysis System
CODE_02A2E8:
                       LDA.B $C6                            ;02A2E8|A5C6    |0004C6; Read controller 2
                       ORA.B $C4                            ;02A2EA|05C4    |0004C4; Combine with controller 1
                       AND.W #$0010                         ;02A2EC|291000  |      ; Test for action button
                       BEQ CODE_02A318                      ;02A2EF|F027    |02A318; Branch if no action button
                       LDA.B $C6                            ;02A2F1|A5C6    |0004C6; Read controller 2 again
                       AND.B $C4                            ;02A2F3|25C4    |0004C4; Check simultaneous press
                       AND.W #$0010                         ;02A2F5|291000  |      ; Verify action button
                       BEQ CODE_02A309                      ;02A2F8|F00F    |02A309; Branch if not simultaneous
                       LDA.W $10A5                          ;02A2FA|ADA510  |0210A5; Check timing parameter
                       CMP.W #$0032                         ;02A2FD|C93200  |      ; Compare to threshold
                       BCC CODE_02A309                      ;02A300|9007    |02A309; Branch if below threshold
                       LDA.W #$0080                         ;02A302|A98000  |      ; Set rapid-fire mode
                       STA.B $CE                            ;02A305|85CE    |0004CE; Store rapid-fire flag
                       BRA CODE_02A315                      ;02A307|800C    |02A315; Continue processing
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Controller Precedence Logic
CODE_02A309:
                       LDA.B $C6                            ;02A309|A5C6    |0004C6; Read controller 2
                       CMP.B $C4                            ;02A30B|C5C4    |0004C4; Compare to controller 1
                       BCC CODE_02A315                      ;02A30D|9006    |02A315; Branch if C2 < C1
                       SEP #$20                             ;02A30F|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02A311|C210    |      ; 16-bit index
                       INC.B $CE                            ;02A313|E6CE    |0004CE; Increment controller flag
                                                            ;      |        |      ;

CODE_02A315:
                       JMP.W CODE_02A5AA                    ;02A315|4CAAA5  |02A5AA; Jump to action handler
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Alternative Button Processing Path
CODE_02A318:
                       LDA.B $C6                            ;02A318|A5C6    |0004C6; Read controller 2
                       ORA.B $C4                            ;02A31A|05C4    |0004C4; Combine with controller 1
                       AND.W #$0027                         ;02A31C|292700  |      ; Test for secondary buttons
                       LDA.B $C6                            ;02A31F|A5C6    |0004C6; Read controller 2 again
                       CMP.B $C4                            ;02A321|C5C4    |0004C4; Compare controllers
                       BCC CODE_02A32B                      ;02A323|9006    |02A32B; Branch if C2 < C1
                       SEP #$20                             ;02A325|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02A327|C210    |      ; 16-bit index
                       INC.B $CE                            ;02A329|E6CE    |0004CE; Increment controller flag
                                                            ;      |        |      ;

CODE_02A32B:
                       JMP.W CODE_02A528                    ;02A32B|4C28A5  |02A528; Jump to input handler
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Idle State Handler (Unreachable Code Section)
; Complex idle processing for power management
UNREACH_02A32E:
                       db $E2,$20,$C2,$10,$A9,$65,$8D,$A8,$00,$22,$83,$97,$00,$AD,$A0,$10;02A32E|        |      ;
                       db $29,$0F,$3A,$AA,$BD,$6B,$A3,$CD,$A9,$00,$90,$01,$60,$AD,$2F,$10;02A33E|        |      ;
                       db $29,$02,$F0,$0B,$A9,$11,$8D,$D0,$10,$A9,$30,$0C,$20,$10,$60,$AD;02A34E|        |      ;
                       db $2F,$10,$29,$02,$D0,$01,$60,$A9,$01,$8D,$D0,$10,$60,$5A,$50,$46;02A35E|        |022910;
                       db $3C,$5A,$50,$46,$3C               ;02A36E|        |00505A;
                                                            ;      |        |      ;

;----------------------------------------------------------------------------
; Game Mode Input Processing System
; Handles in-game controller input and character movement
;----------------------------------------------------------------------------
CODE_02A373:
                       LDA.B #$65                           ;02A373|A965    |      ; Load sound effect ID
                       STA.W $00A8                          ;02A375|8DA800  |0200A8; Store sound parameter
                       JSL.L CODE_009783                    ;02A378|22839700|009783; Call sound processing
                       LDA.W $00A9                          ;02A37C|ADA900  |0200A9; Read sound result
                       CMP.B #$32                           ;02A37F|C932    |      ; Compare to threshold
                       BCC CODE_02A384                      ;02A381|9001    |02A384; Continue if below threshold
                       RTS                                  ;02A383|60      |      ; Exit if sound busy
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Multi-Controller Input Processing Setup
CODE_02A384:
                       LDA.B $8B                            ;02A384|A58B    |00048B; Save current game state
                       PHA                                  ;02A386|48      |      ; Push to stack
                       LDX.W #$04C8                         ;02A387|A2C804  |      ; Load controller buffer pointer
                       STX.B $92                            ;02A38A|8692    |000492; Store buffer pointer
                       LDA.B #$02                           ;02A38C|A902    |      ; Set to controller mode 2
                       STA.B $8B                            ;02A38E|858B    |00048B; Update game state
                       LDA.B #$04                           ;02A390|A904    |      ; Set 4-controller mode
                       STA.B $8C                            ;02A392|858C    |00048C; Store controller count
                       JSR.W CODE_02A40C                    ;02A394|200CA4  |02A40C; Process all controllers
                       PLA                                  ;02A397|68      |      ; Restore game state
                       STA.B $8B                            ;02A398|858B    |00048B; Restore state
                                                            ;      |        |      ;

; Multi-Controller Input Validation Loop
CODE_02A39A:
                       REP #$30                             ;02A39A|C230    |      ; 16-bit mode
                       LDA.B $C8                            ;02A39C|A5C8    |0004C8; Read controller 3
                       ORA.B $CA                            ;02A39E|05CA    |0004CA; Combine with controller 4
                       ORA.B $CC                            ;02A3A0|05CC    |0004CC; Combine with additional input
                       BNE CODE_02A3A9                      ;02A3A2|D005    |02A3A9; Branch if input detected
                       SEP #$20                             ;02A3A4|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02A3A6|C210    |      ; 16-bit index
                       RTS                                  ;02A3A8|60      |      ; Return if no input
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Extended Controller Input Processing
CODE_02A3A9:
                       SEP #$20                             ;02A3A9|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02A3AB|C210    |      ; 16-bit index
                       LDA.B #$FF                           ;02A3AD|A9FF    |      ; Set active input flag
                       STA.B $D0                            ;02A3AF|85D0    |0004D0; Store active flag
                       REP #$30                             ;02A3B1|C230    |      ; 16-bit mode
                       LDA.B $C8                            ;02A3B3|A5C8    |0004C8; Read controller 3
                       ORA.B $CA                            ;02A3B5|05CA    |0004CA; Combine with controller 4
                       ORA.B $CC                            ;02A3B7|05CC    |0004CC; Combine with additional
                       AND.W #$0060                         ;02A3B9|296000  |      ; Test shoulder buttons
                       BEQ CODE_02A3C4                      ;02A3BC|F006    |02A3C4; Branch if no shoulders
                       JSR.W CODE_02A3E4                    ;02A3BE|20E4A3  |02A3E4; Process shoulder input
                       JMP.W CODE_02A528                    ;02A3C1|4C28A5  |02A528; Jump to input handler
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Standard Button Processing for Extended Controllers
CODE_02A3C4:
                       LDA.B $C8                            ;02A3C4|A5C8    |0004C8; Read controller 3
                       ORA.B $CA                            ;02A3C6|05CA    |0004CA; Combine with controller 4
                       ORA.B $CC                            ;02A3C8|05CC    |0004CC; Combine additional
                       AND.W #$0010                         ;02A3CA|291000  |      ; Test action button
                       BEQ CODE_02A3D2                      ;02A3CD|F003    |02A3D2; Branch if no action
                       JMP.W CODE_02A5AA                    ;02A3CF|4CAAA5  |02A5AA; Jump to action handler
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Alternative Input Processing Path
CODE_02A3D2:
                       LDA.B $C8                            ;02A3D2|A5C8    |0004C8; Read controller 3
                       ORA.B $CA                            ;02A3D4|05CA    |0004CA; Combine with controller 4
                       ORA.B $CC                            ;02A3D6|05CC    |0004CC; Combine additional
                       AND.W #$0027                         ;02A3D8|292700  |      ; Test secondary buttons
                       BNE CODE_02A3DE                      ;02A3DB|D001    |02A3DE; Branch if buttons pressed
                       db $60                               ;02A3DD|        |      ; RTS instruction
                                                            ;      |        |      ;

CODE_02A3DE:
                       JSR.W CODE_02A3E4                    ;02A3DE|20E4A3  |02A3E4; Process button input
                       JMP.W CODE_02A528                    ;02A3E1|4C28A5  |02A528; Jump to input handler
                                                            ;      |        |      ;
                                                            ;      |        |      ;

;----------------------------------------------------------------------------
; Extended Controller Priority Resolution System
; Determines which controller has input precedence
;----------------------------------------------------------------------------
CODE_02A3E4:
                       LDA.W #$0002                         ;02A3E4|A90200  |      ; Set initial priority value
                       STA.B $CE                            ;02A3E7|85CE    |0004CE; Store priority
                       LDA.W #$0003                         ;02A3E9|A90300  |      ; Set comparison base
                       STA.B $A0                            ;02A3EC|85A0    |0004A0; Store base value
                       LDA.B $C8                            ;02A3EE|A5C8    |0004C8; Read controller 3
                       STA.B $A2                            ;02A3F0|85A2    |0004A2; Store for comparison
                       CMP.B $CA                            ;02A3F2|C5CA    |0004CA; Compare to controller 4
                       BCS CODE_02A3FE                      ;02A3F4|B008    |02A3FE; Branch if C3 >= C4
                       LDA.B $A0                            ;02A3F6|A5A0    |0004A0; Load base value
                       STA.B $CE                            ;02A3F8|85CE    |0004CE; Update priority
                       LDA.B $CA                            ;02A3FA|A5CA    |0004CA; Load controller 4
                       STA.B $A2                            ;02A3FC|85A2    |0004A2; Store for comparison
                                                            ;      |        |      ;

CODE_02A3FE:
                       INC.B $A0                            ;02A3FE|E6A0    |0004A0; Increment comparison value
                       LDA.B $A2                            ;02A400|A5A2    |0004A2; Load current highest
                       CMP.B $CC                            ;02A402|C5CC    |0004CC; Compare to additional input
                       BCC CODE_02A407                      ;02A404|9001    |02A407; Branch if less than
                       RTS                                  ;02A406|60      |      ; Return if no change
                                                            ;      |        |      ;
                                                            ;      |        |      ;

CODE_02A407:
                       LDA.B $A0                            ;02A407|A5A0    |0004A0; Load updated value
                       STA.B $CE                            ;02A409|85CE    |0004CE; Set final priority
                       RTS                                  ;02A40B|60      |      ; Return
                                                            ;      |        |      ;
                                                            ;      |        |      ;

;----------------------------------------------------------------------------
; Universal Controller Input Reader System
; Reads and processes input from multiple controllers
;----------------------------------------------------------------------------
CODE_02A40C:
                       LDX.B $92                            ;02A40C|A692    |000492; Load controller buffer pointer
                                                            ;      |        |      ;

; Controller Reading Main Loop
CODE_02A40E:
                       REP #$30                             ;02A40E|C230    |      ; 16-bit mode
                       LDA.W #$0000                         ;02A410|A90000  |      ; Clear accumulator
                       STA.W $0000,X                        ;02A413|9D0000  |020000; Clear buffer entry
                       SEP #$20                             ;02A416|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02A418|C210    |      ; 16-bit index
                       PHD                                  ;02A41A|0B      |      ; Push direct page
                       JSR.W CODE_028F22                    ;02A41B|20228F  |028F22; Read controller hardware
                       LDA.B $10                            ;02A41E|A510    |001210; Check controller presence
                       INC A                                ;02A420|1A      |      ; Test for valid controller
                       BEQ CODE_02A441                      ;02A421|F01E    |02A441; Skip if no controller
                       LDA.B $21                            ;02A423|A521    |001221; Read button state
                       AND.B #$C0                           ;02A425|29C0    |      ; Mask shoulder buttons
                       BNE CODE_02A430                      ;02A427|D007    |02A430; Branch if shoulders pressed
                       LDA.B $2F                            ;02A429|A52F    |00112F; Read trigger state
                       AND.B #$02                           ;02A42B|2902    |      ; Test trigger bit
                       STA.W $0000,X                        ;02A42D|9D0000  |020000; Store trigger state
                                                            ;      |        |      ;

CODE_02A430:
                       LDA.B $2E                            ;02A430|A52E    |00122E; Read controller config
                       AND.B #$02                           ;02A432|2902    |      ; Test configuration bit
                       BNE CODE_02A43A                      ;02A434|D004    |02A43A; Branch if configured
                       LDA.B #$FF                           ;02A436|A9FF    |      ; Set full button mask
                       BRA CODE_02A43C                      ;02A438|8002    |02A43C; Continue
                                                            ;      |        |      ;
                                                            ;      |        |      ;

CODE_02A43A:
                       LDA.B #$7F                           ;02A43A|A97F    |      ; Set partial button mask
                                                            ;      |        |      ;

CODE_02A43C:
                       AND.B $21                            ;02A43C|2521    |001221; Apply mask to buttons
                       STA.W $0001,X                        ;02A43E|9D0100  |020001; Store masked buttons
                                                            ;      |        |      ;

; Controller Data Processing
CODE_02A441:
                       REP #$30                             ;02A441|C230    |      ; 16-bit mode
                       LDA.W $0000,X                        ;02A443|BD0000  |020000; Load controller data
                       JSR.W CODE_02A46B                    ;02A446|206BA4  |02A46B; Process button mapping
                       STA.W $0000,X                        ;02A449|9D0000  |020000; Store processed data
                       SEP #$20                             ;02A44C|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02A44E|C210    |      ; 16-bit index
                       LDA.W $048B                          ;02A450|AD8B04  |02048B; Check game mode
                       CMP.B #$02                           ;02A453|C902    |      ; Compare to mode 2
                       BCC CODE_02A45F                      ;02A455|9008    |02A45F; Branch if less than
                       LDA.B #$FE                           ;02A457|A9FE    |      ; Clear bit 0 mask
                       AND.W $0001,X                        ;02A459|3D0100  |020001; Apply to controller data
                       STA.W $0001,X                        ;02A45C|9D0100  |020001; Store result
                                                            ;      |        |      ;

CODE_02A45F:
                       INX                                  ;02A45F|E8      |      ; Advance to next controller
                       INX                                  ;02A460|E8      |      ; (2 bytes per entry)
                       PLD                                  ;02A461|2B      |      ; Restore direct page
                       INC.B $8B                            ;02A462|E68B    |00048B; Increment controller index
                       LDA.B $8C                            ;02A464|A58C    |00048C; Load controller count
                       CMP.B $8B                            ;02A466|C58B    |00048B; Compare to current index
                       BCS CODE_02A40E                      ;02A468|B0A4    |02A40E; Loop if more controllers
                       RTS                                  ;02A46A|60      |      ; Return when done
                                                            ;      |        |      ;
                                                            ;      |        |      ;

;----------------------------------------------------------------------------
; Button Mapping and Bit Manipulation System
; Converts raw controller input to game-specific format
;----------------------------------------------------------------------------
CODE_02A46B:
                       PHA                                  ;02A46B|48      |      ; Save input
                       PHA                                  ;02A46C|48      |      ; Save again for processing
                       AND.W #$000A                         ;02A46D|290A00  |      ; Mask specific bits
                       ASL A                                ;02A470|0A      |      ; Shift left
                       ASL A                                ;02A471|0A      |      ; Shift left
                       ASL A                                ;02A472|0A      |      ; Shift left (multiply by 8)
                       STA.W $04A0                          ;02A473|8DA004  |0204A0; Store shifted value
                       PLA                                  ;02A476|68      |      ; Restore input
                       AND.W #$0F00                         ;02A477|29000F  |      ; Mask high nibble
                       LSR A                                ;02A47A|4A      |      ; Shift right
                       LSR A                                ;02A47B|4A      |      ; Shift right
                       LSR A                                ;02A47C|4A      |      ; Shift right
                       LSR A                                ;02A47D|4A      |      ; Shift right
                       LSR A                                ;02A47E|4A      |      ; Shift right
                       LSR A                                ;02A47F|4A      |      ; Shift right
                       LSR A                                ;02A480|4A      |      ; Shift right
                       LSR A                                ;02A481|4A      |      ; Shift right (divide by 256)
                       ORA.W $04A0                          ;02A482|0DA004  |0204A0; Combine with shifted value
                       STA.W $04A0                          ;02A485|8DA004  |0204A0; Store combined result
                       PLA                                  ;02A488|68      |      ; Restore original input
                       AND.W #$F000                         ;02A489|2900F0  |      ; Mask upper nibble
                       LSR A                                ;02A48C|4A      |      ; Shift right
                       LSR A                                ;02A48D|4A      |      ; Shift right
                       LSR A                                ;02A48E|4A      |      ; Shift right
                       LSR A                                ;02A48F|4A      |      ; Shift right
                       LSR A                                ;02A490|4A      |      ; Shift right
                       LSR A                                ;02A491|4A      |      ; Shift right
                       LSR A                                ;02A492|4A      |      ; Shift right (divide by 128)
                       ORA.W $04A0                          ;02A493|0DA004  |0204A0; Final combination
                       RTS                                  ;02A496|60      |      ; Return processed value
                                                            ;      |        |      ;
                                                            ;      |        |      ;

;----------------------------------------------------------------------------
; Advanced Controller Response Time Analysis
; Measures controller response and determines optimal settings
;----------------------------------------------------------------------------
CODE_02A497:
                       REP #$30                             ;02A497|C230    |      ; 16-bit mode
                       LDA.W #$0002                         ;02A499|A90200  |      ; Initialize measurement
                       STA.B $A0                            ;02A49C|85A0    |0004A0; Store initial value
                       STA.B $8D                            ;02A49E|858D    |00048D; Store counter
                       PHD                                  ;02A4A0|0B      |      ; Push direct page
                                                            ;      |        |      ;

; Response Time Measurement Loop
CODE_02A4A1:
                       JSR.W CODE_028F2F                    ;02A4A1|202F8F  |028F2F; Read controller state
                       LDA.B $21                            ;02A4A4|A521    |001221; Check button state
                       AND.W #$0080                         ;02A4A6|298000  |      ; Test specific button
                       BEQ CODE_02A4B3                      ;02A4A9|F008    |02A4B3; Exit loop if released
                       INC.W $04A0                          ;02A4AB|EEA004  |0204A0; Increment measurement
                       INC.W $048D                          ;02A4AE|EE8D04  |02048D; Increment counter
                       BRA CODE_02A4A1                      ;02A4B1|80EE    |02A4A1; Continue measuring
                                                            ;      |        |      ;
                                                            ;      |        |      ;

CODE_02A4B3:
                       LDA.B $14                            ;02A4B3|A514    |001214; Read timing value
                       STA.W $04A2                          ;02A4B5|8DA204  |0204A2; Store timing reference
                                                            ;      |        |      ;

; Timing Optimization Loop
CODE_02A4B8:
                       INC.W $048D                          ;02A4B8|EE8D04  |02048D; Increment counter
                       LDA.W #$0005                         ;02A4BB|A90500  |      ; Set loop limit
                       CMP.W $048D                          ;02A4BE|CD8D04  |02048D; Compare to counter
                       BEQ CODE_02A4DF                      ;02A4C1|F01C    |02A4DF; Exit if limit reached
                       JSR.W CODE_028F2F                    ;02A4C3|202F8F  |028F2F; Read controller again
                       LDA.B $21                            ;02A4C6|A521    |001221; Check button state
                       AND.W #$0080                         ;02A4C8|298000  |      ; Test button
                       BNE CODE_02A4B8                      ;02A4CB|D0EB    |02A4B8; Continue if pressed
                       LDA.B $14                            ;02A4CD|A514    |001214; Read current timing
                       CMP.W $04A2                          ;02A4CF|CDA204  |0204A2; Compare to reference
                       BCS CODE_02A4B8                      ;02A4D2|B0E4    |02A4B8; Continue if not improved
                       STA.W $04A2                          ;02A4D4|8DA204  |0204A2; Store new best time
                       LDA.W $048D                          ;02A4D7|AD8D04  |02048D; Load counter
                       STA.W $04A0                          ;02A4DA|8DA004  |0204A0; Store optimal value
                       BRA CODE_02A4B8                      ;02A4DD|80D9    |02A4B8; Continue optimization
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Timing Result Processing
CODE_02A4DF:
                       SEP #$20                             ;02A4DF|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02A4E1|C210    |      ; 16-bit index
                       JSR.W CODE_028F22                    ;02A4E3|20228F  |028F22; Read final controller state
                       LDA.B $21                            ;02A4E6|A521    |001221; Check button state
                       AND.B #$08                           ;02A4E8|2908    |      ; Test specific bit
                       BEQ CODE_02A4FA                      ;02A4EA|F00E    |02A4FA; Branch if not set
                       LDA.B #$05                           ;02A4EC|A905    |      ; Set sound effect ID
                       STA.W $00A8                          ;02A4EE|8DA800  |0200A8; Store sound parameter
                       JSL.L CODE_009783                    ;02A4F1|22839700|009783; Call sound system
                       LDA.W $00A9                          ;02A4F5|ADA900  |0200A9; Get sound result
                       BRA CODE_02A4FD                      ;02A4F8|8003    |02A4FD; Continue
                                                            ;      |        |      ;
                                                            ;      |        |      ;

CODE_02A4FA:
                       LDA.W $04A0                          ;02A4FA|ADA004  |0204A0; Load optimal value
                                                            ;      |        |      ;

CODE_02A4FD:
                       STA.B $51                            ;02A4FD|8551    |001251; Store final result
                       PLD                                  ;02A4FF|2B      |      ; Restore direct page
                       RTS                                  ;02A500|60      |      ; Return
                                                            ;      |        |      ;
                                                            ;      |        |      ;
