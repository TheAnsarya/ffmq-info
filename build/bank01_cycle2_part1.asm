; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 2, Part 1)
; Advanced Battle Animation and Sprite Management Systems
; ==============================================================================

; ==============================================================================
; Advanced Sprite Position Calculation with Screen Clipping
; Complex sprite coordinate processing with boundary checks and multi-sprite handling
; ==============================================================================

CODE_01A0E5:
                       SEC                                  ;01A0E5|38      |      ;
                       SBC.B $00                          ;01A0E6|E500    |001A62;
                       AND.W #$03FF                       ;01A0E8|29FF03  |      ;
                       STA.B $23,X                        ;01A0EB|9523    |001A85;
                       LDA.B $25,X                        ;01A0ED|B525    |001A87;
                       SEC                                  ;01A0EF|38      |      ;
                       SBC.B $02                          ;01A0F0|E502    |001A64;
                       AND.W #$03FF                       ;01A0F2|29FF03  |      ;
                       STA.B $25,X                        ;01A0F5|9525    |001A87;
                       SEP #$20                           ;01A0F7|E220    |      ;
                       LDA.B $1E,X                        ;01A0F9|B51E    |001A80;
                       EOR.W $19B4                        ;01A0FB|4DB419  |0119B4;
                       BIT.B #$08                         ;01A0FE|8908    |      ;
                       BEQ CODE_01A105                     ;01A100|F003    |01A105;
                       JMP.W CODE_01A186                   ;01A102|4C86A1  |01A186;

CODE_01A105:
                       LDA.B #$00                         ;01A105|A900    |      ;
                       XBA                                 ;01A107|EB      |      ;
                       LDA.B $19,X                        ;01A108|B519    |001A7B;
                       BPL CODE_01A10F                     ;01A10A|1003    |01A10F;
                       db $EB,$3A,$EB                   ;01A10C|        |      ;

CODE_01A10F:
                       REP #$20                           ;01A10F|C220    |      ;
                       CLC                                 ;01A111|18      |      ;
                       ADC.B $23,X                        ;01A112|7523    |001A85;
                       STA.B $0A                          ;01A114|850A    |001A6C;
                       LDA.W #$0000                       ;01A116|A90000  |      ;
                       SEP #$20                           ;01A119|E220    |      ;
                       LDA.B $1A,X                        ;01A11B|B51A    |001A7C;
                       BPL CODE_01A122                     ;01A11D|1003    |01A122;
                       db $EB,$3A,$EB                   ;01A11F|        |      ;

CODE_01A122:
                       REP #$20                           ;01A122|C220    |      ;
                       CLC                                 ;01A124|18      |      ;
                       ADC.B $25,X                        ;01A125|7525    |001A87;
                       STA.B $0C                          ;01A127|850C    |001A6E;
                       REP #$20                           ;01A129|C220    |      ;
                       LDX.B $04                          ;01A12B|A604    |001A66;
                       LDY.W DATA8_01A63C,X                ;01A12D|BC3CA6  |01A63C;
                       LDA.W DATA8_01A63A,X                ;01A130|BD3AA6  |01A63A;
                       TAX                                 ;01A133|AA      |      ;
                       LDA.B $0C                          ;01A134|A50C    |001A6E;
                       CMP.W #$00E8                       ;01A136|C9E800  |      ;
                       BCC CODE_01A140                     ;01A139|9005    |01A140;
                       CMP.W #$03F8                       ;01A13B|C9F803  |      ;
                       BCC CODE_01A191                     ;01A13E|9051    |01A191;

; ==============================================================================
; Multi-Sprite OAM Setup with Complex Boundary Testing
; Handles 4-sprite large character display with screen clipping and priority
; ==============================================================================

CODE_01A140:
                       LDA.B $0A                          ;01A140|A50A    |001A6C;
                       CMP.W #$00F8                       ;01A142|C9F800  |      ;
                       BCC CODE_01A15E                     ;01A145|9017    |01A15E;
                       CMP.W #$0100                       ;01A147|C90001  |      ;
                       BCC CODE_01A1A8                     ;01A14A|905C    |01A1A8;
                       CMP.W #$03F0                       ;01A14C|C9F003  |      ;
                       BCC CODE_01A191                     ;01A14F|9040    |01A191;
                       CMP.W #$03F8                       ;01A151|C9F803  |      ;
                       BCC CODE_01A1D3                     ;01A154|907D    |01A1D3;
                       CMP.W #$0400                       ;01A156|C90004  |      ;
                       BCS CODE_01A15E                     ;01A159|B003    |01A15E;
                       JMP.W CODE_01A1FF                   ;01A15B|4CFFA1  |01A1FF;

; ==============================================================================
; Standard 4-Sprite OAM Configuration
; Sets up normal sprite display with 16x16 tile arrangement
; ==============================================================================

CODE_01A15E:
                       SEP #$20                           ;01A15E|E220    |      ;
                       STA.W $0C00,X                      ;01A160|9D000C  |010C00;
                       STA.W $0C08,X                      ;01A163|9D080C  |010C08;
                       CLC                                 ;01A166|18      |      ;
                       ADC.B #$08                         ;01A167|6908    |      ;
                       STA.W $0C04,X                      ;01A169|9D040C  |010C04;
                       STA.W $0C0C,X                      ;01A16C|9D0C0C  |010C0C;
                       LDA.B $0C                          ;01A16F|A50C    |001A6E;
                       STA.W $0C01,X                      ;01A171|9D010C  |010C01;
                       STA.W $0C05,X                      ;01A174|9D050C  |010C05;
                       CLC                                 ;01A177|18      |      ;
                       ADC.B #$08                         ;01A178|6908    |      ;
                       STA.W $0C09,X                      ;01A17A|9D090C  |010C09;
                       STA.W $0C0D,X                      ;01A17D|9D0D0C  |010C0D;
                       LDA.B #$00                         ;01A180|A900    |      ;
                       STA.W $0C00,Y                      ;01A182|99000C  |010C00;
                       RTS                                 ;01A185|60      |      ;

; ==============================================================================
; Off-Screen Sprite Handling
; Hides sprites that are completely outside visible screen area
; ==============================================================================

CODE_01A186:
                       REP #$20                           ;01A186|C220    |      ;
                       LDX.B $04                          ;01A188|A604    |001A66;
                       LDY.W DATA8_01A63C,X                ;01A18A|BC3CA6  |01A63C;
                       LDA.W DATA8_01A63A,X                ;01A18D|BD3AA6  |01A63A;
                       TAX                                 ;01A190|AA      |      ;

CODE_01A191:
                       LDA.W #$E080                       ;01A191|A980E0  |      ;
                       STA.W $0C00,X                      ;01A194|9D000C  |010C00;
                       STA.W $0C04,X                      ;01A197|9D040C  |010C04;
                       STA.W $0C08,X                      ;01A19A|9D080C  |010C08;
                       STA.W $0C0C,X                      ;01A19D|9D0C0C  |010C0C;
                       SEP #$20                           ;01A1A0|E220    |      ;
                       LDA.B #$55                         ;01A1A2|A955    |      ;
                       STA.W $0C00,Y                      ;01A1A4|99000C  |010C00;
                       RTS                                 ;01A1A7|60      |      ;

; ==============================================================================
; Right Edge Clipping Configuration
; Handles sprites partially visible on right edge of screen
; ==============================================================================

CODE_01A1A8:
                       SEP #$20                           ;01A1A8|E220    |      ;
                       STA.W $0C00,X                      ;01A1AA|9D000C  |010C00;
                       STA.W $0C08,X                      ;01A1AD|9D080C  |010C08;
                       LDA.B #$80                         ;01A1B0|A980    |      ;
                       STA.W $0C04,X                      ;01A1B2|9D040C  |010C04;
                       STA.W $0C0C,X                      ;01A1B5|9D0C0C  |010C0C;
                       LDA.B $0C                          ;01A1B8|A50C    |001A6E;
                       STA.W $0C01,X                      ;01A1BA|9D010C  |010C01;
                       CLC                                 ;01A1BD|18      |      ;
                       ADC.B #$08                         ;01A1BE|6908    |      ;
                       STA.W $0C09,X                      ;01A1C0|9D090C  |010C09;
                       LDA.B #$E0                         ;01A1C3|A9E0    |      ;
                       STA.W $0C05,X                      ;01A1C5|9D050C  |010C05;
                       STA.W $0C0D,X                      ;01A1C8|9D0D0C  |010C0D;
                       SEP #$20                           ;01A1CB|E220    |      ;
                       LDA.B #$44                         ;01A1CD|A944    |      ;
                       STA.W $0C00,Y                      ;01A1CF|99000C  |010C00;
                       RTS                                 ;01A1D2|60      |      ;

; ==============================================================================
; Left Edge Clipping Configuration
; Handles sprites partially visible on left edge of screen
; ==============================================================================

CODE_01A1D3:
                       SEP #$20                           ;01A1D3|E220    |      ;
                       CLC                                 ;01A1D5|18      |      ;
                       ADC.B #$08                         ;01A1D6|6908    |      ;
                       STA.W $0C04,X                      ;01A1D8|9D040C  |010C04;
                       STA.W $0C0C,X                      ;01A1DB|9D0C0C  |010C0C;
                       LDA.B #$80                         ;01A1DE|A980    |      ;
                       STA.W $0C00,X                      ;01A1E0|9D000C  |010C00;
                       STA.W $0C08,X                      ;01A1E3|9D080C  |010C08;
                       LDA.B $0C                          ;01A1E6|A50C    |001A6E;
                       STA.W $0C05,X                      ;01A1E8|9D050C  |010C05;
                       CLC                                 ;01A1EB|18      |      ;
                       ADC.B #$08                         ;01A1EC|6908    |      ;
                       STA.W $0C0D,X                      ;01A1EE|9D0D0C  |010C0D;
                       LDA.B #$E0                         ;01A1F1|A9E0    |      ;
                       STA.W $0C01,X                      ;01A1F3|9D010C  |010C01;
                       STA.W $0C09,X                      ;01A1F6|9D090C  |010C09;
                       LDA.B #$55                         ;01A1F9|A955    |      ;
                       STA.W $0C00,Y                      ;01A1FB|99000C  |010C00;
                       RTS                                 ;01A1FE|60      |      ;

; ==============================================================================
; Full Visibility Sprite Setup (Screen Wrap)
; Handles sprites fully visible including wraparound positioning
; ==============================================================================

CODE_01A1FF:
                       SEP #$20                           ;01A1FF|E220    |      ;
                       STA.W $0C00,X                      ;01A201|9D000C  |010C00;
                       STA.W $0C08,X                      ;01A204|9D080C  |010C08;
                       CLC                                 ;01A207|18      |      ;
                       ADC.B #$08                         ;01A208|6908    |      ;
                       STA.W $0C04,X                      ;01A20A|9D040C  |010C04;
                       STA.W $0C0C,X                      ;01A20D|9D0C0C  |010C0C;
                       LDA.B $0C                          ;01A210|A50C    |001A6E;
                       STA.W $0C01,X                      ;01A212|9D010C  |010C01;
                       STA.W $0C05,X                      ;01A215|9D050C  |010C05;
                       CLC                                 ;01A218|18      |      ;
                       ADC.B #$08                         ;01A219|6908    |      ;
                       STA.W $0C09,X                      ;01A21B|9D090C  |010C09;
                       STA.W $0C0D,X                      ;01A21E|9D0D0C  |010C0D;
                       LDA.B #$11                         ;01A221|A911    |      ;
                       STA.W $0C00,Y                      ;01A223|99000C  |010C00;
                       RTS                                 ;01A226|60      |      ;

; ==============================================================================
; Sound Effect System Initialization
; Complex audio channel management with battle sound coordination
; ==============================================================================

CODE_01A227:
                       PHP                                 ;01A227|08      |      ;
                       SEP #$20                           ;01A228|E220    |      ;
                       REP #$10                           ;01A22A|C210    |      ;
                       LDX.W #$FFFF                       ;01A22C|A2FFFF  |      ;
                       STX.W $19DE                        ;01A22F|8EDE19  |0119DE;
                       STX.W $19E0                        ;01A232|8EE019  |0119E0;
                       LDA.W $1914                        ;01A235|AD1419  |011914;
                       BIT.B #$20                         ;01A238|8920    |      ;
                       BEQ CODE_01A267                     ;01A23A|F02B    |01A267;
                       LDA.B #$00                         ;01A23C|A900    |      ;
                       XBA                                 ;01A23E|EB      |      ;
                       LDA.W $1913                        ;01A23F|AD1319  |011913;
                       AND.B #$0F                         ;01A242|290F    |      ;
                       ASL A                               ;01A244|0A      |      ;
                       TAX                                 ;01A245|AA      |      ;
                       LDA.L UNREACH_0CD666,X              ;01A246|BF66D60C|0CD666;
                       PHX                                 ;01A24A|DA      |      ;
                       ASL A                               ;01A24B|0A      |      ;
                       TAX                                 ;01A24C|AA      |      ;
                       REP #$30                           ;01A24D|C230    |      ;
                       LDA.L DATA8_0CD686,X                ;01A24F|BF86D60C|0CD686;
                       STA.W $19DE                        ;01A253|8DDE19  |0119DE;
                       PLX                                 ;01A256|FA      |      ;
                       LDA.L UNREACH_0CD667,X              ;01A257|BF67D60C|0CD667;
                       AND.W #$000F                       ;01A25B|290F00  |      ;
                       ASL A                               ;01A25E|0A      |      ;
                       TAX                                 ;01A25F|AA      |      ;
                       LDA.L DATA8_0CD727,X                ;01A260|BF27D70C|0CD727;
                       STA.W $19E0                        ;01A264|8DE019  |0119E0;

; ==============================================================================
; Sound Channel Buffer Initialization
; Clears all audio memory buffers for battle sound effects
; ==============================================================================

CODE_01A267:
                       REP #$30                           ;01A267|C230    |      ;
                       LDA.W #$0000                       ;01A269|A90000  |      ;
                       STA.L $7FCED8                      ;01A26C|8FD8CE7F|7FCED8;
                       STA.L $7FCEDA                      ;01A270|8FDACE7F|7FCEDA;
                       STA.L $7FCEDC                      ;01A274|8FDCCE7F|7FCEDC;
                       STA.L $7FCEDE                      ;01A278|8FDECE7F|7FCEDE;
                       STA.L $7FCEE0                      ;01A27C|8FE0CE7F|7FCEE0;
                       STA.L $7FCEE2                      ;01A280|8FE2CE7F|7FCEE2;
                       STA.L $7FCEE4                      ;01A284|8FE4CE7F|7FCEE4;
                       STA.L $7FCEE6                      ;01A288|8FE6CE7F|7FCEE6;
                       STA.L $7FCEE8                      ;01A28C|8FE8CE7F|7FCEE8;
                       STA.L $7FCEEA                      ;01A290|8FEACE7F|7FCEEA;
                       STA.L $7FCEEC                      ;01A294|8FECCE7F|7FCEEC;
                       STA.L $7FCEEE                      ;01A298|8FEECE7F|7FCEEE;
                       STA.L $7FCEF0                      ;01A29C|8FF0CE7F|7FCEF0;
                       STA.L $7FCEF2                      ;01A2A0|8FF2CE7F|7FCEF2;
                       PLP                                 ;01A2A4|28      |      ;
                       RTS                                 ;01A2A5|60      |      ;
