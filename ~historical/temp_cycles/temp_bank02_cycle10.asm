; ===========================================================================
; FFMQ Bank $02 - Cycle 10: Advanced Button Processing and System Control
; Complex Menu State Management, Sound System Integration, and Input Validation
; ===========================================================================

;----------------------------------------------------------------------------
; Advanced Controller State Processing and Menu Navigation
; Sophisticated button state analysis with controller validation
;----------------------------------------------------------------------------
CODE_02A5CF:
                       PHD                                  ;02A5CF|0B      |      ; Push direct page
                       JSR.W CODE_028F22                    ;02A5D0|20228F  |028F22; Read controller state
                       LDA.B $18                            ;02A5D3|A518    |001098; Read system state
                       XBA                                  ;02A5D5|EB      |      ; Swap bytes
                       LDA.B $38                            ;02A5D6|A538    |0010B8; Read controller config
                       PLD                                  ;02A5D8|2B      |      ; Restore direct page
                       AND.B #$40                           ;02A5D9|2940    |      ; Test special button bit
                       BEQ CODE_02A5FE                      ;02A5DB|F021    |02A5FE; Branch if not pressed
                       XBA                                  ;02A5DD|EB      |      ; Swap back
                       BEQ CODE_02A5FE                      ;02A5DE|F01E    |02A5FE; Branch if zero
                       LDA.B #$20                           ;02A5E0|A920    |      ; Set command ID
                       STA.W $10D0                          ;02A5E2|8DD010  |0210D0; Store command
                       LDA.B #$15                           ;02A5E5|A915    |      ; Set command type
                       STA.W $10D2                          ;02A5E7|8DD210  |0210D2; Store command type
                       LDA.B $CE                            ;02A5EA|A5CE    |0004CE; Read controller state
                       AND.B #$80                           ;02A5EC|2980    |      ; Test high bit
                       BNE CODE_02A5F6                      ;02A5EE|D006    |02A5F6; Branch if set
                       LDA.B $CE                            ;02A5F0|A5CE    |0004CE; Reload state
                       STA.W $10D1                          ;02A5F2|8DD110  |0210D1; Store parameter
                       RTS                                  ;02A5F5|60      |      ; Return
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Extended Controller State Handler
CODE_02A5F6:
                       LDA.B $CE                            ;02A5F6|A5CE    |0004CE; Read controller state
                       STA.W $10D1                          ;02A5F8|8DD110  |0210D1; Store parameter
                       STA.B $39                            ;02A5FB|8539    |000439; Store in system register
                       RTS                                  ;02A5FD|60      |      ; Return
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Alternative Input Processing Path
CODE_02A5FE:
                       LDA.B #$10                           ;02A5FE|A910    |      ; Set test value
                       JSL.L CODE_00DA65                    ;02A600|2265DA00|00DA65; Call system validation
                       INC A                                ;02A604|1A      |      ; Increment for test
                       DEC A                                ;02A605|3A      |      ; Decrement back
                       BEQ CODE_02A620                      ;02A606|F018    |02A620; Branch if zero
                       LDA.B #$30                           ;02A608|A930    |      ; Set alternate command
                       STA.W $10D0                          ;02A60A|8DD010  |0210D0; Store command
                       LDA.B #$10                           ;02A60D|A910    |      ; Set alternate type
                       STA.W $10D2                          ;02A60F|8DD210  |0210D2; Store type
                       LDA.B $CE                            ;02A612|A5CE    |0004CE; Read controller state
                       CMP.B #$80                           ;02A614|C980    |      ; Compare to threshold
                       BNE CODE_02A61A                      ;02A616|D002    |02A61A; Branch if different
                       db $A9,$01                           ;02A618|        |      ; LDA #$01 instruction
                                                            ;      |        |      ;

CODE_02A61A:
                       STA.W $10D1                          ;02A61A|8DD110  |0210D1; Store final parameter
                       STA.B $39                            ;02A61D|8539    |000439; Store in system register
                       RTS                                  ;02A61F|60      |      ; Return
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Complex Input State Resolution
CODE_02A620:
                       LDA.B $8B                            ;02A620|A58B    |00048B; Read game state
                       CMP.B #$02                           ;02A622|C902    |      ; Compare to mode 2
                       BCS CODE_02A636                      ;02A624|B010    |02A636; Branch if greater/equal
                       db $A9,$00,$EB,$A5,$CE,$0A,$AA,$A9,$EF,$35,$C4,$95,$C4,$4C,$B4,$A2;02A626|        |      ;
                                                            ;      |        |      ;

; Advanced Button Mask Processing
CODE_02A636:
                       LDA.B #$EF                           ;02A636|A9EF    |      ; Set button mask
                                                            ;      |        |      ;

; Universal Button Masking System
CODE_02A638:
                       AND.B $C8                            ;02A638|25C8    |0004C8; Apply mask to controller 3
                       STA.B $C8                            ;02A63A|85C8    |0004C8; Store masked result
                       AND.B $CA                            ;02A63C|25CA    |0004CA; Apply to controller 4
                       STA.B $CA                            ;02A63E|85CA    |0004CA; Store result
                       AND.B $CC                            ;02A640|25CC    |0004CC; Apply to additional input
                       STA.B $CC                            ;02A642|85CC    |0004CC; Store result
                       JMP.W CODE_02A39A                    ;02A644|4C9AA3  |02A39A; Jump to input handler
                                                            ;      |        |      ;
                                                            ;      |        |      ;

;----------------------------------------------------------------------------
; Comprehensive Menu System Processing
; Advanced menu navigation with sound integration
;----------------------------------------------------------------------------
CODE_02A647:
                       SEP #$20                             ;02A647|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02A649|C210    |      ; 16-bit index
                       LDA.B $8B                            ;02A64B|A58B    |00048B; Read game state
                       CMP.B #$02                           ;02A64D|C902    |      ; Test for menu mode
                       BCC CODE_02A654                      ;02A64F|9003    |02A654; Branch if less than
                       JMP.W CODE_02A9A1                    ;02A651|4CA1A9  |02A9A1; Jump to advanced handler
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Standard Menu Processing Path
CODE_02A654:
                       PHD                                  ;02A654|0B      |      ; Push direct page
                       JSR.W CODE_028F22                    ;02A655|20228F  |028F22; Read controller state
                       LDA.B $21                            ;02A658|A521    |001021; Read button state
                       PLD                                  ;02A65A|2B      |      ; Restore direct page
                       AND.B #$08                           ;02A65B|2908    |      ; Test select button
                       BEQ CODE_02A6C7                      ;02A65D|F068    |02A6C7; Branch if not pressed
                       PHD                                  ;02A65F|0B      |      ; Push direct page
                       JSR.W CODE_028F22                    ;02A660|20228F  |028F22; Read full controller state
                       LDA.B $38                            ;02A663|A538    |001038; Read state flags
                       AND.B #$0F                           ;02A665|290F    |      ; Mask low nibble
                       ORA.B $39                            ;02A667|0539    |001039; Combine with state
                       STA.W $04A0                          ;02A669|8DA004  |0204A0; Store combined state
                       PLD                                  ;02A66C|2B      |      ; Restore direct page
                       LDA.B $A0                            ;02A66D|A5A0    |0004A0; Read state
                       BEQ CODE_02A67F                      ;02A66F|F00E    |02A67F; Branch if zero
                       LDA.B #$02                           ;02A671|A902    |      ; Set sound effect ID
                       STA.W $00A8                          ;02A673|8DA800  |0200A8; Store sound parameter
                       JSL.L CODE_009783                    ;02A676|22839700|009783; Call sound system
                       LDA.W $00A9                          ;02A67A|ADA900  |0200A9; Read sound result
                       BNE CODE_02A682                      ;02A67D|D003    |02A682; Branch if sound active
                                                            ;      |        |      ;

CODE_02A67F:
                       JMP.W CODE_02A881                    ;02A67F|4C81A8  |02A881; Jump to standard handler
                                                            ;      |        |      ;
                                                            ;      |        |      ;

;----------------------------------------------------------------------------
; Advanced Sound Integration and System State Management
; Complex audio-visual coordination system
;----------------------------------------------------------------------------
CODE_02A682:
                       PHD                                  ;02A682|0B      |      ; Push direct page
                       JSR.W CODE_028F22                    ;02A683|20228F  |028F22; Read system state
                       LDA.B $38                            ;02A686|A538    |001038; Read state byte 1
                       XBA                                  ;02A688|EB      |      ; Swap to high byte
                       LDA.B $39                            ;02A689|A539    |001039; Read state byte 2
                       REP #$30                             ;02A68B|C230    |      ; 16-bit mode
                       LDX.W #$FFFF                         ;02A68D|A2FFFF  |      ; Set index marker
                       PLD                                  ;02A690|2B      |      ; Restore direct page
                       ASL A                                ;02A691|0A      |      ; Shift left
                       ASL A                                ;02A692|0A      |      ; Shift left
                       ASL A                                ;02A693|0A      |      ; Shift left
                       ASL A                                ;02A694|0A      |      ; Shift left (multiply by 16)
                       SEP #$20                             ;02A695|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02A697|C210    |      ; 16-bit index
                       STA.B $A8                            ;02A699|85A8    |0004A8; Store high calculation
                       XBA                                  ;02A69B|EB      |      ; Swap bytes
                       STA.B $A7                            ;02A69C|85A7    |0004A7; Store low calculation
                       LDA.B #$08                           ;02A69E|A908    |      ; Set sound ID
                       STA.W $00A8                          ;02A6A0|8DA800  |0200A8; Store sound parameter
                       JSL.L CODE_009783                    ;02A6A3|22839700|009783; Call sound system
                       LDA.W $00A9                          ;02A6A7|ADA900  |0200A9; Read sound state
                       STA.B $A9                            ;02A6AA|85A9    |0004A9; Store local copy
                                                            ;      |        |      ;

; Sound Processing Loop with State Management
CODE_02A6AC:
                       LDA.B $A9                            ;02A6AC|A5A9    |0004A9; Read sound state
                       PHA                                  ;02A6AE|48      |      ; Save state
                       INC A                                ;02A6AF|1A      |      ; Increment
                       AND.B #$07                           ;02A6B0|2907    |      ; Mask to 8 states
                       STA.B $A9                            ;02A6B2|85A9    |0004A9; Store new state
                       PLA                                  ;02A6B4|68      |      ; Restore original
                       TAX                                  ;02A6B5|AA      |      ; Transfer to index
                       PHD                                  ;02A6B6|0B      |      ; Push direct page
                       PEA.W $04A7                          ;02A6B7|F4A704  |0204A7; Push calculation address
                       PLD                                  ;02A6BA|2B      |      ; Load new direct page
                       JSL.L CODE_00975A                    ;02A6BB|225A9700|00975A; Call calculation system
                       PLD                                  ;02A6BF|2B      |      ; Restore direct page
                       INC A                                ;02A6C0|1A      |      ; Test result
                       DEC A                                ;02A6C1|3A      |      ; Restore value
                       BEQ CODE_02A6AC                      ;02A6C2|F0E8    |02A6AC; Loop if zero
                       JMP.W CODE_02A8C6                    ;02A6C4|4CC6A8  |02A8C6; Jump to completion handler
                                                            ;      |        |      ;
                                                            ;      |        |      ;

;----------------------------------------------------------------------------
; Multi-Player Controller Coordination System
; Handles up to 4 controllers with priority resolution
;----------------------------------------------------------------------------
CODE_02A6C7:
                       LDA.B #$02                           ;02A6C7|A902    |      ; Set initial priority
                       STA.B $A4                            ;02A6C9|85A4    |0004A4; Store priority base
                       LDX.W #$0403                         ;02A6CB|A20304  |      ; Set controller indices
                       STX.B $A5                            ;02A6CE|86A5    |0004A5; Store index pair
                       LDA.W $1121                          ;02A6D0|AD2111  |021121; Read controller 1 extended
                       BMI CODE_02A6D8                      ;02A6D3|3003    |02A6D8; Branch if negative
                       LDA.W $1110                          ;02A6D5|AD1011  |021110; Read controller 1 standard
                                                            ;      |        |      ;

CODE_02A6D8:
                       STA.B $A7                            ;02A6D8|85A7    |0004A7; Store controller 1 data
                       LDA.W $11A1                          ;02A6DA|ADA111  |0211A1; Read controller 2 extended
                       BMI CODE_02A6E2                      ;02A6DD|3003    |02A6E2; Branch if negative
                       LDA.W $1190                          ;02A6DF|AD9011  |021190; Read controller 2 standard
                                                            ;      |        |      ;

CODE_02A6E2:
                       STA.B $A8                            ;02A6E2|85A8    |0004A8; Store controller 2 data
                       LDA.W $1221                          ;02A6E4|AD2112  |021221; Read controller 3 extended
                       BMI CODE_02A6EC                      ;02A6E7|3003    |02A6EC; Branch if negative
                       LDA.W $1210                          ;02A6E9|AD1012  |021210; Read controller 3 standard
                                                            ;      |        |      ;

CODE_02A6EC:
                       STA.B $A9                            ;02A6EC|85A9    |0004A9; Store controller 3 data
                       LDY.W #$0003                         ;02A6EE|A00300  |      ; Set loop counter
                       LDX.W #$0001                         ;02A6F1|A20100  |      ; Set comparison index
                                                            ;      |        |      ;

; Controller Priority Sorting Algorithm
CODE_02A6F4:
                       LDA.B $A7,X                          ;02A6F4|B5A7    |0004A7; Read controller data
                       CMP.B $A8,X                          ;02A6F6|D5A8    |0004A8; Compare with next controller
                       BCC CODE_02A70E                      ;02A6F8|9014    |02A70E; Skip swap if in order
                       LDA.B $A7,X                          ;02A6FA|B5A7    |0004A7; Load first value
                       PHA                                  ;02A6FC|48      |      ; Save on stack
                       LDA.B $A8,X                          ;02A6FD|B5A8    |0004A8; Load second value
                       STA.B $A7,X                          ;02A6FF|95A7    |0004A7; Store in first position
                       PLA                                  ;02A701|68      |      ; Restore first value
                       STA.B $A8,X                          ;02A702|95A8    |0004A8; Store in second position
                       LDA.B $A4,X                          ;02A704|B5A4    |0004A4; Load first priority
                       PHA                                  ;02A706|48      |      ; Save on stack
                       LDA.B $A5,X                          ;02A707|B5A5    |0004A5; Load second priority
                       STA.B $A4,X                          ;02A709|95A4    |0004A4; Store in first position
                       PLA                                  ;02A70B|68      |      ; Restore first priority
                       STA.B $A5,X                          ;02A70C|95A5    |0004A5; Store in second position
                                                            ;      |        |      ;

CODE_02A70E:
                       REP #$30                             ;02A70E|C230    |      ; 16-bit mode
                       TXA                                  ;02A710|8A      |      ; Transfer index
                       EOR.W #$0001                         ;02A711|490100  |      ; Toggle index bit
                       TAX                                  ;02A714|AA      |      ; Transfer back
                       SEP #$20                             ;02A715|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02A717|C210    |      ; 16-bit index
                       DEY                                  ;02A719|88      |      ; Decrement counter
                       BPL CODE_02A6F4                      ;02A71A|10D8    |02A6F4; Continue if more to sort
                       LDY.W #$04A4                         ;02A71C|A0A404  |      ; Set data pointer
                       LDA.B #$00                           ;02A71F|A900    |      ; Clear accumulator
                       XBA                                  ;02A721|EB      |      ; Clear high byte
                       LDA.B $B3                            ;02A722|A5B3    |0004B3; Read controller count
                       TAX                                  ;02A724|AA      |      ; Transfer to index
                                                            ;      |        |      ;

; Controller Validation and Processing Loop
CODE_02A725:
                       LDA.W $0000,Y                        ;02A725|B90000  |020000; Read controller data
                       STA.B $8D                            ;02A728|858D    |00048D; Store for processing
                       LDA.B $75                            ;02A72A|A575    |000475; Read system parameter
                       PHD                                  ;02A72C|0B      |      ; Push direct page
                       PEA.W $0F18                          ;02A72D|F4180F  |020F18; Push validation address
                       PLD                                  ;02A730|2B      |      ; Load validation page
                       JSL.L CODE_00975A                    ;02A731|225A9700|00975A; Call validation system
                       PLD                                  ;02A735|2B      |      ; Restore direct page
                       INC A                                ;02A736|1A      |      ; Test result
                       DEC A                                ;02A737|3A      |      ; Restore value
                       BEQ CODE_02A743                      ;02A738|F009    |02A743; Skip if validation failed
                       PHD                                  ;02A73A|0B      |      ; Push direct page
                       JSR.W CODE_028F2F                    ;02A73B|202F8F  |028F2F; Read controller details
                       LDA.B $56                            ;02A73E|A556    |0011D6; Read controller status
                       PLD                                  ;02A740|2B      |      ; Restore direct page
                       BNE CODE_02A74A                      ;02A741|D007    |02A74A; Branch if controller active
                                                            ;      |        |      ;

CODE_02A743:
                       INY                                  ;02A743|C8      |      ; Next controller
                       DEX                                  ;02A744|CA      |      ; Decrement counter
                       BNE CODE_02A725                      ;02A745|D0DE    |02A725; Continue if more controllers
                       JMP.W CODE_02A85E                    ;02A747|4C5EA8  |02A85E; Jump to completion
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; Active Controller Processing
CODE_02A74A:
                       STA.B $A7                            ;02A74A|85A7    |0004A7; Store controller status
                       STZ.B $38                            ;02A74C|6438    |000438; Clear system flag
                       STZ.W $10D0                          ;02A74E|9CD010  |0210D0; Clear command register
                       LDA.W $10B1                          ;02A751|ADB110  |0210B1; Read system parameter
                       STA.B $3A                            ;02A754|853A    |00043A; Store parameter
                       STA.W $10D2                          ;02A756|8DD210  |0210D2; Store in command type
                       JSR.W CODE_028B0F                    ;02A759|200F8B  |028B0F; Process system state
                       LDA.B $DB                            ;02A75C|A5DB    |0004DB; Read processing result
                       AND.B $A7                            ;02A75E|25A7    |0004A7; Mask with controller status
                       AND.B #$07                           ;02A760|2907    |      ; Mask to direction bits
                       BEQ CODE_02A78A                      ;02A762|F026    |02A78A; Branch if no direction
                       LDA.B $3A                            ;02A764|A53A    |00043A; Read parameter
                       CMP.B #$2D                           ;02A766|C92D    |      ; Compare to value
                       BEQ CODE_02A770                      ;02A768|F006    |02A770; Branch if match
                       CMP.B #$2E                           ;02A76A|C92E    |      ; Compare to alternate
                       BEQ CODE_02A770                      ;02A76C|F002    |02A770; Branch if match
                       db $80,$05                           ;02A76E|        |02A775; BRA instruction
                                                            ;      |        |      ;

; Special Parameter Processing
CODE_02A770:
                       LDA.W $10B0                          ;02A770|ADB010  |0210B0; Read system state
                       BEQ CODE_02A78A                      ;02A773|F015    |02A78A; Branch if zero
                       STZ.W $10D0                          ;02A775|9CD010  |0210D0; Clear command
                       LDA.B $E0                            ;02A778|A5E0    |0004E0; Read error state
                       AND.B #$02                           ;02A77A|2902    |      ; Test error bit
                       BEQ CODE_02A784                      ;02A77C|F006    |02A784; Branch if no error
                                                            ;      |        |      ;

CODE_02A77E:
                       LDA.B #$81                           ;02A77E|A981    |      ; Set error flag
                       STA.W $10D1                          ;02A780|8DD110  |0210D1; Store error state
                       RTS                                  ;02A783|60      |      ; Return with error
                                                            ;      |        |      ;
                                                            ;      |        |      ;

CODE_02A784:
                       LDA.B $8D                            ;02A784|A58D    |00048D; Read processed value
                       STA.W $10D1                          ;02A786|8DD110  |0210D1; Store as parameter
                       RTS                                  ;02A789|60      |      ; Return success
                                                            ;      |        |      ;
                                                            ;      |        |      ;

; ===========================================================================
; End of Bank $02 Cycle 10: Advanced Button Processing and System Control
; Complex menu state management with sophisticated controller coordination
; ===========================================================================
