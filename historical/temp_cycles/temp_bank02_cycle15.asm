; Final Fantasy Mystic Quest - Bank $02 Cycle 15
; Complex System Coordination and Advanced Processing Engine
; From lines 7700-8200 of Bank $02 source (500+ lines)

; Memory Row Calculation and Address Management
; Advanced row offset calculation with sophisticated memory addressing
CODE_02D664:
                       LDA.B #$02                           ;02D664|A902    |      ; Set row increment value

CODE_02D666:
                       REP #$30                             ;02D666|C230    |      ; 16-bit mode
                       CLC                                  ;02D668|18      |      ; Clear carry
                       ADC.B $72                            ;02D669|6572    |000A72; Add to memory base
                       STA.B $72                            ;02D66B|8572    |000A72; Store updated memory address
                       PLP                                  ;02D66D|28      |      ; Restore processor status
                       RTS                                  ;02D66E|60      |      ; Return

; Advanced Graphics Data Processing Engine
; Complex graphics data transfer with multi-bank coordination
CODE_02D66F:
                       PHY                                  ;02D66F|5A      |      ; Save Y register
                       PHP                                  ;02D670|08      |      ; Save processor status
                       PHB                                  ;02D671|8B      |      ; Save data bank
                       SEP #$20                             ;02D672|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02D674|C210    |      ; 16-bit index
                       LDA.B #$7E                           ;02D676|A97E    |      ; Bank $7E
                       STA.W $2183                          ;02D678|8D8321  |022183; Set WRAM bank
                       LDX.B $70                            ;02D67B|A670    |000A70; Load memory offset
                       STX.W $2181                          ;02D67D|8E8121  |022181; Set WRAM address
                       LDA.B $15                            ;02D680|A515    |000A15; Load graphics bank
                       PHA                                  ;02D682|48      |      ; Save bank
                       PLB                                  ;02D683|AB      |      ; Set as data bank
                       LDX.B $69                            ;02D684|A669    |000A69; Load graphics pointer
                       LDY.W #$0010                         ;02D686|A01000  |      ; 16-byte transfer count

; Graphics Data Transfer Loop 1
; First phase graphics data transfer (16 bytes)
CODE_02D689:
                       LDA.B ($69)                          ;02D689|B269    |000A69; Load graphics byte
                       SEP #$20                             ;02D68B|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02D68D|C210    |      ; 16-bit index
                       STA.W $2180                          ;02D68F|8D8021  |092180; Write to WRAM
                       REP #$30                             ;02D692|C230    |      ; 16-bit mode
                       INC.B $69                            ;02D694|E669    |000A69; Next graphics byte
                       DEY                                  ;02D696|88      |      ; Decrement counter
                       BNE CODE_02D689                      ;02D697|D0F0    |02D689; Continue transfer loop
                       LDY.W #$0008                         ;02D699|A00800  |      ; 8-byte transfer count

; Graphics Data Transfer Loop 2
; Second phase graphics data transfer with special processing
CODE_02D69C:
                       LDA.B ($69)                          ;02D69C|B269    |000A69; Load graphics byte
                       SEP #$20                             ;02D69E|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02D6A0|C210    |      ; 16-bit index
                       STA.W $2180                          ;02D6A2|8D8021  |092180; Write to WRAM
                       STZ.W $2180                          ;02D6A5|9C8021  |092180; Write zero byte
                       REP #$30                             ;02D6A8|C230    |      ; 16-bit mode
                       INC.B $69                            ;02D6AA|E669    |000A69; Next graphics byte
                       DEY                                  ;02D6AC|88      |      ; Decrement counter
                       BNE CODE_02D69C                      ;02D6AD|D0ED    |02D69C; Continue transfer loop
                       PLB                                  ;02D6AF|AB      |      ; Restore data bank
                       PLP                                  ;02D6B0|28      |      ; Restore processor status
                       PLY                                  ;02D6B1|7A      |      ; Restore Y register
                       RTS                                  ;02D6B2|60      |      ; Return

; Memory Clearing Engine
; High-speed memory clearing with SNES register optimization
CODE_02D6B3:
                       PHP                                  ;02D6B3|08      |      ; Save processor status
                       PHD                                  ;02D6B4|0B      |      ; Save direct page
                       SEP #$20                             ;02D6B5|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02D6B7|C210    |      ; 16-bit index
                       PEA.W $2100                          ;02D6B9|F40021  |022100; Set direct page to $2100
                       PLD                                  ;02D6BC|2B      |      ; Load new direct page
                       LDA.B #$00                           ;02D6BD|A900    |      ; Clear value
                       STA.B SNES_WMADDH-$2100              ;02D6BF|8583    |002183; Set WRAM bank to 0
                       LDX.W $0A70                          ;02D6C1|AE700A  |020A70; Load memory address
                       STX.B SNES_WMADDL-$2100              ;02D6C4|8681    |002181; Set WRAM address
                       LDA.B #$20                           ;02D6C6|A920    |      ; Clear 32 bytes

; Memory Clear Loop
CODE_02D6C8:
                       STZ.B SNES_WMDATA-$2100              ;02D6C8|6480    |002180; Write zero to WRAM
                       DEC A                                ;02D6CA|3A      |      ; Decrement counter
                       BNE CODE_02D6C8                      ;02D6CB|D0FB    |02D6C8; Continue clear loop
                       PLD                                  ;02D6CD|2B      |      ; Restore direct page
                       PLP                                  ;02D6CE|28      |      ; Restore processor status
                       RTS                                  ;02D6CF|60      |      ; Return

; Advanced Position Calculation Engine
; Complex position and coordinate calculation system
CODE_02D6D0:
                       PHP                                  ;02D6D0|08      |      ; Save processor status
                       SEP #$30                             ;02D6D1|E230    |      ; 8-bit mode
                       LDX.B $83                            ;02D6D3|A683    |000A83; Load state index
                       LDA.B #$0D                           ;02D6D5|A90D    |      ; Base calculation value
                       SEC                                  ;02D6D7|38      |      ; Set carry
                       SBC.B $19                            ;02D6D8|E519    |000A19; Subtract position parameter
                       INC A                                ;02D6DA|1A      |      ; Increment result
                       LDY.W $0A0A,X                        ;02D6DB|BC0A0A  |020A0A; Load position flags
                       BEQ CODE_02D6E6                      ;02D6DE|F006    |02D6E6; Branch if zero
                       LDY.W $0A07,X                        ;02D6E0|BC070A  |020A07; Load alternate flags
                       BNE CODE_02D6E6                      ;02D6E3|D001    |02D6E6; Branch if not zero
                       DEC A                                ;02D6E5|3A      |      ; Decrement if special case

CODE_02D6E6:
                       STA.B $17                            ;02D6E6|8517    |000A17; Store calculated position
                       PHX                                  ;02D6E8|DA      |      ; Save X register
                       CLC                                  ;02D6E9|18      |      ; Clear carry
                       LDA.B $00                            ;02D6EA|A500    |000A00; Load base value
                       ADC.B $00                            ;02D6EC|6500    |000A00; Double the value
                       ADC.B $00                            ;02D6EE|6500    |000A00; Triple the value
                       DEC A                                ;02D6F0|3A      |      ; Adjust by -1
                       DEC A                                ;02D6F1|3A      |      ; Adjust by -2
                       DEC A                                ;02D6F2|3A      |      ; Adjust by -3
                       ADC.B $01,S                          ;02D6F3|6301    |000001; Add stack value
                       TAX                                  ;02D6F5|AA      |      ; Transfer to X
                       LDA.B $18                            ;02D6F6|A518    |000A18; Load height parameter
                       LSR A                                ;02D6F8|4A      |      ; Divide by 2
                       PHA                                  ;02D6F9|48      |      ; Save half height
                       LDA.W DATA8_02D72B,X                 ;02D6FA|BD2BD7  |02D72B; Load position data
                       SEC                                  ;02D6FD|38      |      ; Set carry
                       SBC.B $01,S                          ;02D6FE|E301    |000001; Subtract half height
                       STA.B $16                            ;02D700|8516    |000A16; Store adjusted position
                       PLA                                  ;02D702|68      |      ; Restore half height
                       PLX                                  ;02D703|FA      |      ; Restore X register
                       JSR.W CODE_02D734                    ;02D704|2034D7  |02D734; Call position processor

; Advanced Position Coordinate Processing
                       REP #$20                             ;02D707|C220    |      ; 16-bit accumulator
                       SEP #$10                             ;02D709|E210    |      ; 8-bit index
                       LDA.B $17                            ;02D70B|A517    |000A17; Load position value
                       AND.W #$00FF                         ;02D70D|29FF00  |      ; Mask to 8-bit
                       ASL A                                ;02D710|0A      |      ; Multiply by 2
                       ASL A                                ;02D711|0A      |      ; Multiply by 4
                       ASL A                                ;02D712|0A      |      ; Multiply by 8
                       ASL A                                ;02D713|0A      |      ; Multiply by 16
                       ASL A                                ;02D714|0A      |      ; Multiply by 32
                       SEP #$30                             ;02D715|E230    |      ; 8-bit mode
                       CLC                                  ;02D717|18      |      ; Clear carry
                       ADC.B $16                            ;02D718|6516    |000A16; Add adjusted position
                       XBA                                  ;02D71A|EB      |      ; Exchange bytes
                       ADC.B #$00                           ;02D71B|6900    |      ; Add carry to high byte
                       XBA                                  ;02D71D|EB      |      ; Exchange bytes back
                       REP #$20                             ;02D71E|C220    |      ; 16-bit accumulator
                       SEP #$10                             ;02D720|E210    |      ; 8-bit index
                       ASL A                                ;02D722|0A      |      ; Multiply by 2
                       CLC                                  ;02D723|18      |      ; Clear carry
                       ADC.W #$A800                         ;02D724|6900A8  |      ; Add base address
                       STA.B $72                            ;02D727|8572    |000A72; Store final address
                       PLP                                  ;02D729|28      |      ; Restore processor status
                       RTS                                  ;02D72A|60      |      ; Return

; Position Data Table
; Position offset values for coordinate calculations
DATA8_02D72B:
                       db $10                               ;02D72B; Position offset 1
                       db $00,$00                           ;02D72C; Position offsets 2-3
                       db $0B,$15                           ;02D72E; Position offsets 4-5
                       db $00                               ;02D730; Position offset 6
                       db $06,$10,$1A                       ;02D731; Position offsets 7-9

; Advanced Data Transfer and State Management Engine
; Complex state processing with multi-bank data coordination
CODE_02D734:
                       PHX                                  ;02D734|DA      |      ; Save X register
                       PHP                                  ;02D735|08      |      ; Save processor status
                       REP #$30                             ;02D736|C230    |      ; 16-bit mode
                       LDA.B $83                            ;02D738|A583    |000A83; Load state index
                       AND.W #$00FF                         ;02D73A|29FF00  |      ; Mask to 8-bit
                       ASL A                                ;02D73D|0A      |      ; Multiply by 2
                       ASL A                                ;02D73E|0A      |      ; Multiply by 4
                       ADC.W #$0A2D                         ;02D73F|692D0A  |      ; Add base address
                       TAY                                  ;02D742|A8      |      ; Transfer to Y
                       LDX.W #$0A16                         ;02D743|A2160A  |      ; Source address
                       LDA.W #$0003                         ;02D746|A90300  |      ; Transfer 4 bytes
                       MVN $02,$02                          ;02D749|540202  |      ; Block move within bank
                       LDA.B $18                            ;02D74C|A518    |000A18; Load height parameter
                       LDX.W #$0000                         ;02D74E|A20000  |      ; Initialize index

; Height Parameter Search Loop
CODE_02D751:
                       CMP.W DATA8_02D77A,X                 ;02D751|DD7AD7  |02D77A; Compare with height table
                       BEQ CODE_02D75A                      ;02D754|F004    |02D75A; Branch if match found
                       INX                                  ;02D756|E8      |      ; Increment index
                       INX                                  ;02D757|E8      |      ; Increment index (word values)
                       BRA CODE_02D751                      ;02D758|80F7    |02D751; Continue search

CODE_02D75A:
                       TXA                                  ;02D75A|8A      |      ; Transfer index to A
                       SEP #$30                             ;02D75B|E230    |      ; 8-bit mode
                       LSR A                                ;02D75D|4A      |      ; Divide by 2 (word to byte index)
                       LDX.B $83                            ;02D75E|A683    |000A83; Load state index
                       STA.B $22,X                          ;02D760|9522    |000A22; Store height index
                       LDA.B $02                            ;02D762|A502    |000A02; Load current state
                       CMP.B #$50                           ;02D764|C950    |      ; Check for special state
                       BNE CODE_02D777                      ;02D766|D00F    |02D777; Branch if not special

; Special State Processing
                       db $A5,$07,$D0,$0B,$A5,$2D,$18,$69,$08,$85,$2D,$A9,$0C,$85,$2F;02D768

CODE_02D777:
                       PLP                                  ;02D777|28      |      ; Restore processor status
                       PLX                                  ;02D778|FA      |      ; Restore X register
                       RTS                                  ;02D779|60      |      ; Return

; Height Data Table
; Height values for position calculations
DATA8_02D77A:
                       db $06,$06,$08,$08,$0A,$0A           ;02D77A; Height values 1-6
                       db $0A,$08,$1C,$0A                   ;02D780; Height values 7-10

; State Processing and Data Bank Management Engine
; Advanced state processing with sophisticated bank coordination
CODE_02D784:
                       PHA                                  ;02D784|48      |      ; Save accumulator
                       PHX                                  ;02D785|DA      |      ; Save X register
                       PHP                                  ;02D786|08      |      ; Save processor status
                       SEP #$20                             ;02D787|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02D789|C210    |      ; 16-bit index
                       PHK                                  ;02D78B|4B      |      ; Push program bank
                       PLB                                  ;02D78C|AB      |      ; Set as data bank
                       LDX.W #$0000                         ;02D78D|A20000  |      ; Initialize search index

; State Data Search Loop
CODE_02D790:
                       LDA.W DATA8_02D7D3,X                 ;02D790|BDD3D7  |02D7D3; Load state threshold
                       CMP.B $20                            ;02D793|C520    |000A20; Compare with current state
                       BPL CODE_02D7A5                      ;02D795|100E    |02D7A5; Branch if threshold reached
                       REP #$30                             ;02D797|C230    |      ; 16-bit mode
                       TXA                                  ;02D799|8A      |      ; Transfer index to A
                       CLC                                  ;02D79A|18      |      ; Clear carry
                       ADC.W #$0009                         ;02D79B|690900  |      ; Add 9 bytes (record size)
                       TAX                                  ;02D79E|AA      |      ; Transfer back to X
                       SEP #$20                             ;02D79F|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02D7A1|C210    |      ; 16-bit index
                       BRA CODE_02D790                      ;02D7A3|80EB    |02D790; Continue search

; State Data Processing
CODE_02D7A5:
                       REP #$30                             ;02D7A5|C230    |      ; 16-bit mode
                       INX                                  ;02D7A7|E8      |      ; Next byte (skip threshold)
                       TXA                                  ;02D7A8|8A      |      ; Transfer index to A
                       CLC                                  ;02D7A9|18      |      ; Clear carry
                       ADC.W #$D7D3                         ;02D7AA|69D3D7  |      ; Add base address
                       TAX                                  ;02D7AD|AA      |      ; Source address
                       LDY.W #$0A15                         ;02D7AE|A0150A  |      ; Destination address
                       LDA.W #$0007                         ;02D7B1|A90700  |      ; Transfer 8 bytes
                       MVN $02,$02                          ;02D7B4|540202  |      ; Block move within bank

; Mathematical Processing and Bank Coordination
                       SEP #$20                             ;02D7B7|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02D7B9|C210    |      ; 16-bit index
                       LDA.B $20                            ;02D7BB|A520    |000A20; Load state parameter
                       STA.W $4202                          ;02D7BD|8D0242  |024202; Set multiplicand
                       LDA.B #$05                           ;02D7C0|A905    |      ; Set multiplier
                       JSL.L CODE_00971E                    ;02D7C2|221E9700|00971E; Call multiplication routine
                       LDX.W $4216                          ;02D7C6|AE1642  |024216; Load multiplication result
                       LDA.L DATA8_098462,X                 ;02D7C9|BF628409|098462; Load bank data
                       STA.B $15                            ;02D7CD|8515    |000A15; Store bank value
                       PLP                                  ;02D7CF|28      |      ; Restore processor status
                       PLX                                  ;02D7D0|FA      |      ; Restore X register
                       PLA                                  ;02D7D1|68      |      ; Restore accumulator
                       RTS                                  ;02D7D2|60      |      ; Return

; State Data Table
; Complex state configuration data with thresholds and parameters
DATA8_02D7D3:
                       db $37,$09,$00,$00,$06,$06,$24,$00,$01,$3F,$0A,$00,$00,$08,$08,$40;02D7D3
                       db $00,$02,$41                       ;02D7E3
                       db $0B,$00,$00,$0A,$0A,$64,$00,$03   ;02D7E6
                       db $49,$0A,$00,$00,$08,$08,$40,$00,$02,$4F,$0B,$00,$00,$0A,$0A,$64;02D7EE
                       db $00,$03                           ;02D7FE
                       db $50,$0B,$00,$00,$1C,$0A,$18,$01,$03,$FF;02D800

; Advanced Graphics and Entity Coordination Engine
; Complex entity processing with multi-bank graphics coordination
CODE_02D80A:
                       PHX                                  ;02D80A|DA      |      ; Save X register
                       PHB                                  ;02D80B|8B      |      ; Save data bank
                       PHP                                  ;02D80C|08      |      ; Save processor status
                       SEP #$30                             ;02D80D|E230    |      ; 8-bit mode
                       LDX.B $83                            ;02D80F|A683    |000A83; Load state index
                       LDA.B $02,X                          ;02D811|B502    |000A02; Load entity state
                       STA.B $20                            ;02D813|8520    |000A20; Store for processing
                       SEP #$20                             ;02D815|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02D817|C210    |      ; 16-bit index
                       STA.W $4202                          ;02D819|8D0242  |024202; Set multiplicand
                       LDA.B #$05                           ;02D81C|A905    |      ; Set multiplier (5)
                       JSL.L CODE_00971E                    ;02D81E|221E9700|00971E; Call multiplication routine
                       LDX.W $4216                          ;02D822|AE1642  |024216; Load result address

; Multi-Bank Data Retrieval
                       LDA.L DATA8_098460,X                 ;02D825|BF608409|098460; Load graphics bank 1
                       STA.B $69                            ;02D829|8569    |000A69; Store bank 1
                       LDA.L DATA8_098461,X                 ;02D82B|BF618409|098461; Load graphics bank 2
                       STA.B $6A                            ;02D82F|856A    |000A6A; Store bank 2
                       LDA.L DATA8_098462,X                 ;02D831|BF628409|098462; Load graphics bank 3
                       STA.B $6B                            ;02D835|856B    |000A6B; Store bank 3
                       PHB                                  ;02D837|8B      |      ; Save current bank
                       LDA.L DATA8_098464,X                 ;02D838|BF648409|098464; Load special flag
                       CMP.B #$FF                           ;02D83C|C9FF    |      ; Check for special value
                       BEQ UNREACH_02D89B                   ;02D83E|F05B    |02D89B; Branch to special handling

; Advanced Graphics Block Transfer System
                       PHA                                  ;02D840|48      |      ; Save graphics parameter
                       LDA.L DATA8_098463,X                 ;02D841|BF638409|098463; Load graphics offset
                       PHA                                  ;02D845|48      |      ; Save offset
                       REP #$30                             ;02D846|C230    |      ; 16-bit mode
                       LDA.B $83                            ;02D848|A583    |000A83; Load state index
                       AND.W #$00FF                         ;02D84A|29FF00  |      ; Mask to 8-bit
                       ASL A                                ;02D84D|0A      |      ; Multiply by 2
                       ASL A                                ;02D84E|0A      |      ; Multiply by 4
                       ASL A                                ;02D84F|0A      |      ; Multiply by 8
                       ASL A                                ;02D850|0A      |      ; Multiply by 16
                       ASL A                                ;02D851|0A      |      ; Multiply by 32
                       ASL A                                ;02D852|0A      |      ; Multiply by 64
                       CLC                                  ;02D853|18      |      ; Clear carry
                       ADC.W #$C040                         ;02D854|6940C0  |      ; Add base graphics address
                       TAY                                  ;02D857|A8      |      ; Set as destination

; First Graphics Block Transfer
                       SEP #$20                             ;02D858|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02D85A|C210    |      ; 16-bit index
                       PLA                                  ;02D85C|68      |      ; Restore graphics offset
                       REP #$30                             ;02D85D|C230    |      ; 16-bit mode
                       AND.W #$00FF                         ;02D85F|29FF00  |      ; Mask to 8-bit
                       ASL A                                ;02D862|0A      |      ; Multiply by 2
                       ASL A                                ;02D863|0A      |      ; Multiply by 4
                       ASL A                                ;02D864|0A      |      ; Multiply by 8
                       ASL A                                ;02D865|0A      |      ; Multiply by 16
                       CLC                                  ;02D866|18      |      ; Clear carry
                       ADC.W #$8000                         ;02D867|690080  |      ; Add graphics base
                       TAX                                  ;02D86A|AA      |      ; Set as source
                       LDA.W #$000F                         ;02D86B|A90F00  |      ; Transfer 16 bytes
                       MVN $7E,$09                          ;02D86E|547E09  |      ; Block move (bank $09 to $7E)

; Second Graphics Block Transfer
                       TYA                                  ;02D871|98      |      ; Transfer destination to A
                       CLC                                  ;02D872|18      |      ; Clear carry
                       ADC.W #$0010                         ;02D873|691000  |      ; Add 16 bytes offset
                       TAY                                  ;02D876|A8      |      ; Set new destination
                       SEP #$20                             ;02D877|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02D879|C210    |      ; 16-bit index
                       PLA                                  ;02D87B|68      |      ; Restore second parameter
                       REP #$30                             ;02D87C|C230    |      ; 16-bit mode
                       AND.W #$00FF                         ;02D87E|29FF00  |      ; Mask to 8-bit
                       ASL A                                ;02D881|0A      |      ; Multiply by 2
                       ASL A                                ;02D882|0A      |      ; Multiply by 4
                       ASL A                                ;02D883|0A      |      ; Multiply by 8
                       ASL A                                ;02D884|0A      |      ; Multiply by 16
                       CLC                                  ;02D885|18      |      ; Clear carry
                       ADC.W #$8000                         ;02D886|690080  |      ; Add graphics base
                       TAX                                  ;02D889|AA      |      ; Set as source
                       LDA.W #$000F                         ;02D88A|A90F00  |      ; Transfer 16 bytes
                       MVN $7E,$09                          ;02D88D|547E09  |      ; Block move (bank $09 to $7E)
                       PLB                                  ;02D890|AB      |      ; Restore data bank

; Graphics Processing Completion
                       JSR.W CODE_02D910                    ;02D891|2010D9  |02D910; Call graphics processor
                       JSR.W CODE_02D994                    ;02D894|2094D9  |02D994; Call data coordinator
                       PLP                                  ;02D897|28      |      ; Restore processor status
                       PLB                                  ;02D898|AB      |      ; Restore data bank
                       PLX                                  ;02D899|FA      |      ; Restore X register
                       RTS                                  ;02D89A|60      |      ; Return

; Unreachable Special Case Handler
UNREACH_02D89B:
                       db $E2,$30,$A6,$83,$B5,$07,$C9,$03,$D0,$01,$3A,$18,$69,$29,$48,$A9;02D89B
                       db $28,$48,$80,$97                   ;02D8AB

; Entity Parameter Processing Engine
; Advanced entity parameter lookup and processing
CODE_02D8AF:
                       PHX                                  ;02D8AF|DA      |      ; Save X register
                       PHA                                  ;02D8B0|48      |      ; Save accumulator
                       PHP                                  ;02D8B1|08      |      ; Save processor status
                       SEP #$30                             ;02D8B2|E230    |      ; 8-bit mode
                       LDX.B $20                            ;02D8B4|A620    |000A20; Load entity parameter
                       LDA.W DATA8_02D8BF,X                 ;02D8B6|BDBFD8  |02D8BF; Load entity data from table
                       STA.B $78                            ;02D8B9|8578    |000A78; Store entity data
                       PLP                                  ;02D8BB|28      |      ; Restore processor status
                       PLA                                  ;02D8BC|68      |      ; Restore accumulator
                       PLX                                  ;02D8BD|FA      |      ; Restore X register
                       RTS                                  ;02D8BE|60      |      ; Return

; Entity Parameter Table
; Complex entity parameter mapping table
DATA8_02D8BF:
                       db $00,$00,$00,$01,$01,$01,$02,$02   ;02D8BF; Entity parameters 0-7
                       db $02                               ;02D8C7; Entity parameter 8
                       db $03,$03                           ;02D8C8; Entity parameters 9-10
                       db $03                               ;02D8CA; Entity parameter 11
                       db $04,$04,$04,$05,$05               ;02D8CB; Entity parameters 12-16
                       db $05                               ;02D8D0; Entity parameter 17
                       db $06,$06                           ;02D8D1; Entity parameters 18-19
                       db $06                               ;02D8D3; Entity parameter 20
                       db $07,$07                           ;02D8D4; Entity parameters 21-22
                       db $07                               ;02D8D6; Entity parameter 23
                       db $08,$08,$09                       ;02D8D7; Entity parameters 24-26
                       db $09                               ;02D8DA; Entity parameter 27
                       db $0A,$0A,$0B                       ;02D8DB; Entity parameters 28-30
                       db $0B                               ;02D8DE; Entity parameter 31
                       db $0C,$0C,$0D,$0D,$0E,$0E,$0F       ;02D8DF; Entity parameters 32-38
                       db $0F                               ;02D8E6; Entity parameter 39
                       db $10                               ;02D8E7; Entity parameter 40
                       db $10                               ;02D8E8; Entity parameter 41
                       db $11                               ;02D8E9; Entity parameter 42
                       db $11                               ;02D8EA; Entity parameter 43
                       db $12,$12,$13,$13,$14               ;02D8EB; Entity parameters 44-48
                       db $14                               ;02D8F0; Entity parameter 49
                       db $15,$15,$16                       ;02D8F1; Entity parameters 50-52
                       db $16                               ;02D8F4; Entity parameter 53
                       db $17                               ;02D8F5; Entity parameter 54
                       db $17                               ;02D8F6; Entity parameter 55
                       db $18,$19,$1A,$1B,$1C,$1D           ;02D8F7; Entity parameters 56-61
                       db $1F,$1E,$20,$21                   ;02D8FD; Entity parameters 62-65
                       db $18,$19,$1A,$1B,$1C,$1D           ;02D901; Entity parameters 66-71
                       db $1F,$1E                           ;02D907; Entity parameters 72-73
                       db $20,$21,$22                       ;02D909; Entity parameters 74-76
                       db $22,$23,$23,$24                   ;02D90C; Entity parameters 77-80

; Advanced Graphics Processing Coordination Engine
; Complex graphics processing with sophisticated calculation systems
CODE_02D910:
                       PHP                                  ;02D910|08      |      ; Save processor status
                       PHB                                  ;02D911|8B      |      ; Save data bank
                       PHK                                  ;02D912|4B      |      ; Push program bank
                       PLB                                  ;02D913|AB      |      ; Set as data bank
                       REP #$30                             ;02D914|C230    |      ; 16-bit mode
                       JSR.W CODE_02D8AF                    ;02D916|20AFD8  |02D8AF; Call entity parameter processor
                       LDX.W #$0000                         ;02D919|A20000  |      ; Initialize search index
                       LDA.B $78                            ;02D91C|A578    |000A78; Load entity parameter
                       AND.W #$00FF                         ;02D91E|29FF00  |      ; Mask to 8-bit

; Graphics Parameter Search Loop
CODE_02D921:
                       CMP.W DATA8_02D96E,X                 ;02D921|DD6ED9  |02D96E; Compare with threshold table
                       BMI CODE_02D930                      ;02D924|300A    |02D930; Branch if below threshold
                       PHA                                  ;02D926|48      |      ; Save parameter
                       TXA                                  ;02D927|8A      |      ; Transfer index to A
                       CLC                                  ;02D928|18      |      ; Clear carry
                       ADC.W #$000A                         ;02D929|690A00  |      ; Add 10 bytes (record size)
                       TAX                                  ;02D92C|AA      |      ; Transfer back to X
                       PLA                                  ;02D92D|68      |      ; Restore parameter
                       BRA CODE_02D921                      ;02D92E|80F1    |02D921; Continue search

; Graphics Calculation Processing
CODE_02D930:
                       SEC                                  ;02D930|38      |      ; Set carry
                       SBC.W DATA8_02D96C,X                 ;02D931|FD6CD9  |02D96C; Subtract base value
                       SEP #$20                             ;02D934|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02D936|C210    |      ; 16-bit index
                       STA.W $4202                          ;02D938|8D0242  |024202; Set multiplicand
                       REP #$30                             ;02D93B|C230    |      ; 16-bit mode
                       LDA.W DATA8_02D972,X                 ;02D93D|BD72D9  |02D972; Load multiplier data
                       STA.W $0A79                          ;02D940|8D790A  |020A79; Store multiplier
                       SEP #$20                             ;02D943|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02D945|C210    |      ; 16-bit index
                       STA.W $4203                          ;02D947|8D0342  |024203; Set multiplier
                       NOP                                  ;02D94A|EA      |      ; Wait for multiplication
                       NOP                                  ;02D94B|EA      |      ; Wait for multiplication
                       NOP                                  ;02D94C|EA      |      ; Wait for multiplication
                       NOP                                  ;02D94D|EA      |      ; Wait for multiplication

; Second Stage Graphics Calculation
                       LDA.W $4216                          ;02D94E|AD1642  |024216; Load multiplication result
                       STA.W $4202                          ;02D951|8D0242  |024202; Set new multiplicand
                       LDA.W DATA8_02D974,X                 ;02D954|BD74D9  |02D974; Load second multiplier
                       STA.W $4203                          ;02D957|8D0342  |024203; Set second multiplier
                       NOP                                  ;02D95A|EA      |      ; Wait for multiplication
                       NOP                                  ;02D95B|EA      |      ; Wait for multiplication
                       NOP                                  ;02D95C|EA      |      ; Wait for multiplication
                       NOP                                  ;02D95D|EA      |      ; Wait for multiplication
                       REP #$30                             ;02D95E|C230    |      ; 16-bit mode
                       LDA.W DATA8_02D970,X                 ;02D960|BD70D9  |02D970; Load base offset
                       CLC                                  ;02D963|18      |      ; Clear carry
                       ADC.W $4216                          ;02D964|6D1642  |024216; Add calculation result
                       STA.B $6B                            ;02D967|856B    |000A6B; Store final result
                       PLB                                  ;02D969|AB      |      ; Restore data bank
                       PLP                                  ;02D96A|28      |      ; Restore processor status
                       RTS                                  ;02D96B|60      |      ; Return

; Graphics Calculation Data Tables
DATA8_02D96C:
                       db $00,$00                           ;02D96C; Base calculation values

DATA8_02D96E:
                       db $18,$00                           ;02D96E; Threshold values

DATA8_02D970:
                       db $00,$00                           ;02D970; Base offset values

DATA8_02D972:
                       db $05,$00                           ;02D972; Multiplier values

DATA8_02D974:
                       db $02                               ;02D974; Second multiplier
                       db $00                               ;02D975; Padding
                       db $18,$00,$20,$00,$F0,$00,$08,$00,$03;02D976; Graphics parameter table 1
                       db $00                               ;02D97F
                       db $20,$00,$24,$00,$B0,$01,$0D,$00,$04;02D980; Graphics parameter table 2
                       db $00,$24,$00,$25,$00,$80,$02,$23,$00,$04,$00;02D989; Graphics parameter table 3

; Advanced Data Coordination and Processing Engine
; Complex data processing with multi-bank coordination and calculation
CODE_02D994:
                       PHP                                  ;02D994|08      |      ; Save processor status
                       PHB                                  ;02D995|8B      |      ; Save data bank
                       SEP #$20                             ;02D996|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02D998|C210    |      ; 16-bit index
                       LDA.B #$0A                           ;02D99A|A90A    |      ; Bank $0A
                       PHA                                  ;02D99C|48      |      ; Save bank
                       PLB                                  ;02D99D|AB      |      ; Set as data bank
                       LDA.B #$00                           ;02D99E|A900    |      ; Clear register
                       PHA                                  ;02D9A0|48      |      ; Save on stack
                       LDA.B $83                            ;02D9A1|A583    |000A83; Load state index
                       ASL A                                ;02D9A3|0A      |      ; Multiply by 2
                       ASL A                                ;02D9A4|0A      |      ; Multiply by 4
                       ASL A                                ;02D9A5|0A      |      ; Multiply by 8
                       REP #$30                             ;02D9A6|C230    |      ; 16-bit mode
                       AND.W #$00FF                         ;02D9A8|29FF00  |      ; Mask to 8-bit
                       ADC.W #$0A39                         ;02D9AB|69390A  |      ; Add base address
                       TAY                                  ;02D9AE|A8      |      ; Transfer to Y

; Data Structure Setup
                       LDA.B $69                            ;02D9AF|A569    |000A69; Load graphics data 1
                       STA.W $0000,Y                        ;02D9B1|990000  |0A0000; Store at base offset
                       PHY                                  ;02D9B4|5A      |      ; Save Y position
                       LDA.B $6B                            ;02D9B5|A56B    |000A6B; Load graphics data 2
                       STA.W $0018,Y                        ;02D9B7|991800  |0A0018; Store at offset +24
                       PHA                                  ;02D9BA|48      |      ; Save data
                       CLC                                  ;02D9BB|18      |      ; Clear carry
                       ADC.B $79                            ;02D9BC|6579    |000A79; Add calculation value
                       STA.W $001A,Y                        ;02D9BE|991A00  |0A001A; Store at offset +26
                       CLC                                  ;02D9C1|18      |      ; Clear carry
                       ADC.B $79                            ;02D9C2|6579    |000A79; Add calculation value
                       STA.W $001C,Y                        ;02D9C4|991C00  |0A001C; Store at offset +28
                       CLC                                  ;02D9C7|18      |      ; Clear carry
                       ADC.B $79                            ;02D9C8|6579    |000A79; Add calculation value
                       STA.W $001E,Y                        ;02D9CA|991E00  |0A001E; Store at offset +30
                       PLX                                  ;02D9CD|FA      |      ; Restore data to X
                       SEP #$20                             ;02D9CE|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02D9D0|C210    |      ; 16-bit index

; Complex Data Processing Loop
CODE_02D9D2:
                       LDA.B $79                            ;02D9D2|A579    |000A79; Load processing count
                       PHA                                  ;02D9D4|48      |      ; Save count
                       LDA.B #$00                           ;02D9D5|A900    |      ; Clear accumulator
                       XBA                                  ;02D9D7|EB      |      ; Exchange bytes

; Data Byte Processing Loop
CODE_02D9D8:
                       LDA.L DATA8_0A8000,X                 ;02D9D8|BF00800A|0A8000; Load data byte
                       INX                                  ;02D9DC|E8      |      ; Next byte
                       LDY.W #$0008                         ;02D9DD|A00800  |      ; 8 bits per byte

; Bit Processing Loop
CODE_02D9E0:
                       ASL A                                ;02D9E0|0A      |      ; Shift bit left
                       XBA                                  ;02D9E1|EB      |      ; Exchange accumulator bytes
                       ADC.B #$00                           ;02D9E2|6900    |      ; Add carry
                       XBA                                  ;02D9E4|EB      |      ; Exchange bytes back
                       DEY                                  ;02D9E5|88      |      ; Decrement bit counter
                       BNE CODE_02D9E0                      ;02D9E6|D0F8    |02D9E0; Continue bit processing
                       PLA                                  ;02D9E8|68      |      ; Restore processing count
                       DEC A                                ;02D9E9|3A      |      ; Decrement count
                       BEQ CODE_02D9EF                      ;02D9EA|F003    |02D9EF; Branch if done
                       PHA                                  ;02D9EC|48      |      ; Save count
                       BRA CODE_02D9D8                      ;02D9ED|80E9    |02D9D8; Continue processing

; Final Calculation Processing
CODE_02D9EF:
                       XBA                                  ;02D9EF|EB      |      ; Exchange bytes
                       STA.W $4202                          ;02D9F0|8D0242  |0A4202; Set multiplicand
                       LDA.B #$18                           ;02D9F3|A918    |      ; Set multiplier (24)
                       STA.W $4203                          ;02D9F5|8D0342  |0A4203; Set multiplier
                       REP #$30                             ;02D9F8|C230    |      ; 16-bit mode
                       PLY                                  ;02D9FA|7A      |      ; Restore Y position
                       LDA.W $0000,Y                        ;02D9FB|B90000  |0A0000; Load base value
                       CLC                                  ;02D9FE|18      |      ; Clear carry
                       ADC.W $4216                          ;02D9FF|6D1642  |0A4216; Add multiplication result
                       STA.W $0002,Y                        ;02DA02|990200  |0A0002; Store final result
                       INY                                  ;02DA05|C8      |      ; Next Y position
                       INY                                  ;02DA06|C8      |      ; Next Y position (word)
                       SEP #$20                             ;02DA07|E220    |      ; 8-bit accumulator
                       REP #$10                             ;02DA09|C210    |      ; 16-bit index
                       PLA                                  ;02DA0B|68      |      ; Restore loop counter
                       INC A                                ;02DA0C|1A      |      ; Increment counter
                       CMP.B #$03                           ;02DA0D|C903    |      ; Check limit (3)
                       BPL CODE_02DA15                      ;02DA0F|1004    |02DA15; Exit if done
                       PHA                                  ;02DA11|48      |      ; Save counter
                       PHY                                  ;02DA12|5A      |      ; Save Y position
                       BRA CODE_02D9D2                      ;02DA13|80BD    |02D9D2; Continue processing

CODE_02DA15:
                       PLB                                  ;02DA15|AB      |      ; Restore data bank
                       PLP                                  ;02DA16|28      |      ; Restore processor status
                       RTS                                  ;02DA17|60      |      ; Return

; Advanced Display Processing and Color Management Engine
; Complex display processing with sophisticated color effects and timing
CODE_02DA18:
                       PHD                                  ;02DA18|0B      |      ; Save direct page
                       PEA.W $2100                          ;02DA19|F40021  |022100; Set direct page to $2100
                       PLD                                  ;02DA1C|2B      |      ; Load new direct page
                       STZ.W $0A7E                          ;02DA1D|9C7E0A  |020A7E; Clear display flag
                       LDA.B #$1D                           ;02DA20|A91D    |      ; Main screen enable
                       STA.B SNES_TM-$2100                  ;02DA22|852C    |00212C; Set main screen
                       STZ.B SNES_TS-$2100                  ;02DA24|642D    |00212D; Clear sub screen
                       STZ.B SNES_CGSWSEL-$2100             ;02DA26|6430    |002130; Clear color window
                       LDX.W #$0000                         ;02DA28|A20000  |      ; Initialize index
                       LDA.B #$A1                           ;02DA2B|A9A1    |      ; Color math settings
                       STA.B SNES_CGADSUB-$2100             ;02DA2D|8531    |002131; Set color math

; Color Effect Processing Loop 1
CODE_02DA2F:
                       LDA.W DATA8_02DA7D,X                 ;02DA2F|BD7DDA  |02DA7D; Load color data
                       BEQ CODE_02DA49                      ;02DA32|F015    |02DA49; Exit if zero
                       INX                                  ;02DA34|E8      |      ; Next color
                       STA.B SNES_COLDATA-$2100             ;02DA35|8532    |002132; Set color data
                       JSL.L CODE_0C8000                    ;02DA37|2200800C|0C8000; Wait timing routine
                       JSL.L CODE_0C8000                    ;02DA3B|2200800C|0C8000; Wait timing routine
                       JSL.L CODE_0C8000                    ;02DA3F|2200800C|0C8000; Wait timing routine
                       JSL.L CODE_0C8000                    ;02DA43|2200800C|0C8000; Wait timing routine
                       BRA CODE_02DA2F                      ;02DA47|80E6    |02DA2F; Continue color loop

; Color Effect Processing Phase 2
CODE_02DA49:
                       LDA.B #$1F                           ;02DA49|A91F    |      ; Full screen enable
                       STA.B SNES_TM-$2100                  ;02DA4B|852C    |00212C; Set main screen
                       LDA.B #$22                           ;02DA4D|A922    |      ; Alternate color math
                       STA.B SNES_CGADSUB-$2100             ;02DA4F|8531    |002131; Set color math
                       LDX.W #$0000                         ;02DA51|A20000  |      ; Reset index

; Color Effect Processing Loop 2
CODE_02DA54:
                       LDA.W DATA8_02DA7D,X                 ;02DA54|BD7DDA  |02DA7D; Load color data
                       BEQ CODE_02DA72                      ;02DA57|F019    |02DA72; Exit if zero
                       INX                                  ;02DA59|E8      |      ; Next color
                       STA.B SNES_COLDATA-$2100             ;02DA5A|8532    |002132; Set color data
                       JSL.L CODE_0C8000                    ;02DA5C|2200800C|0C8000; Wait timing routine
                       JSL.L CODE_0C8000                    ;02DA60|2200800C|0C8000; Wait timing routine
                       JSL.L CODE_0C8000                    ;02DA64|2200800C|0C8000; Wait timing routine
                       JSL.L CODE_0C8000                    ;02DA68|2200800C|0C8000; Wait timing routine
                       JSL.L CODE_0C8000                    ;02DA6C|2200800C|0C8000; Wait timing routine
                       BRA CODE_02DA54                      ;02DA70|80E2    |02DA54; Continue color loop

; Display Processing Completion
CODE_02DA72:
                       STZ.W $0A84                          ;02DA72|9C840A  |020A84; Clear processing flag
                       STZ.B SNES_CGSWSEL-$2100             ;02DA75|6430    |002130; Clear color window
                       STZ.B SNES_CGADSUB-$2100             ;02DA77|6431    |002131; Clear color math

; **CYCLE 15 COMPLETION MARKER - 4,851 lines documented**
