; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 2, Part 4)
; Complex Character Processing and Graphics Coordination
; ==============================================================================

; ==============================================================================
; Advanced Character Data Processing System
; Complex sprite validation and coordinate transformation
; ==============================================================================

CODE_01A6F2:
                       STZ.W $1948                        ;01A6F2|9C4819  |001948;
                       JSR.W CODE_01B078                   ;01A6F5|2078B0  |01B078;
                       BCC CODE_01A6FC                     ;01A6F8|9002    |01A6FC;
                       SEC                                 ;01A6FA|38      |      ;
                       RTS                                 ;01A6FB|60      |      ;

; ==============================================================================
; Character Sprite Initialization
; Sets up complete character data structures with coordinate processing
; ==============================================================================

CODE_01A6FC:
                       SEP #$20                           ;01A6FC|E220    |      ;
                       REP #$10                           ;01A6FE|C210    |      ;
                       LDX.W $1939                        ;01A700|AE3919  |001939;
                       STZ.B $00,X                        ;01A703|7400    |001A72;
                       LDA.W $193B                        ;01A705|AD3B19  |00193B;
                       STA.B $19,X                        ;01A708|9519    |001A8B;
                       INC.W $1935                        ;01A70A|EE3519  |001935;
                       LDA.W $1935                        ;01A70D|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A710|20DD90  |0190DD;
                       STA.B $0F,X                        ;01A713|950F    |001A81;
                       INC.W $1935                        ;01A715|EE3519  |001935;
                       LDA.W $1935                        ;01A718|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A71B|20DD90  |0190DD;
                       STA.W $193F                        ;01A71E|8D3F19  |00193F;
                       AND.B #$3F                         ;01A721|293F    |      ;
                       STA.B $0C,X                        ;01A723|950C    |001A7E;
                       INC.W $1935                        ;01A725|EE3519  |001935;
                       LDA.W $1935                        ;01A728|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A72B|20DD90  |0190DD;
                       STA.W $192B                        ;01A72E|8D2B19  |00192B;
                       AND.B #$3F                         ;01A731|293F    |      ;
                       STA.B $0B,X                        ;01A733|950B    |001A7D;
                       LDA.W $192B                        ;01A735|AD2B19  |00192B;
                       AND.B #$C0                         ;01A738|29C0    |      ;
                       LSR A                               ;01A73A|4A      |      ;
                       LSR A                               ;01A73B|4A      |      ;
                       PHA                                 ;01A73C|48      |      ;
                       LDA.W $1948                        ;01A73D|AD4819  |001948;
                       BEQ CODE_01A74A                     ;01A740|F008    |01A74A;
                       PLA                                 ;01A742|68      |      ;
                       CLC                                 ;01A743|18      |      ;
                       ADC.B #$10                         ;01A744|6910    |      ;
                       AND.B #$30                         ;01A746|2930    |      ;
                       BRA CODE_01A74B                     ;01A748|8001    |01A74B;

CODE_01A74A:
                       PLA                                 ;01A74A|68      |      ;

CODE_01A74B:
                       STA.B $0E,X                        ;01A74B|950E    |001A80;
                       INC.W $1935                        ;01A74D|EE3519  |001935;
                       LDA.W $1935                        ;01A750|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A753|20DD90  |0190DD;
                       STA.W $192B                        ;01A756|8D2B19  |00192B;
                       AND.B #$E0                         ;01A759|29E0    |      ;
                       LSR A                               ;01A75B|4A      |      ;
                       LSR A                               ;01A75C|4A      |      ;
                       LSR A                               ;01A75D|4A      |      ;
                       LSR A                               ;01A75E|4A      |      ;
                       STA.B $02,X                        ;01A75F|9502    |001A74;
                       STA.B $04,X                        ;01A761|9504    |001A76;
                       STA.B $06,X                        ;01A763|9506    |001A78;
                       STA.B $08,X                        ;01A765|9508    |001A7A;
                       LDA.B #$00                         ;01A767|A900    |      ;
                       XBA                                 ;01A769|EB      |      ;
                       LDA.W $192B                        ;01A76A|AD2B19  |00192B;
                       AND.B #$1F                         ;01A76D|291F    |      ;
                       STA.W $192B                        ;01A76F|8D2B19  |00192B;
                       LDA.W $193F                        ;01A772|AD3F19  |00193F;
                       AND.B #$C0                         ;01A775|29C0    |      ;
                       LSR A                               ;01A777|4A      |      ;
                       ORA.W $192B                        ;01A778|0D2B19  |00192B;
                       ASL A                               ;01A77B|0A      |      ;
                       PHX                                 ;01A77C|DA      |      ;
                       TAX                                 ;01A77D|AA      |      ;
                       LDA.L DATA8_0B87E4,X                ;01A77E|BFE4870B|0B87E4;
                       STA.W $192B                        ;01A782|8D2B19  |00192B;
                       LDA.L DATA8_0B87E5,X                ;01A785|BFE5870B|0B87E5;
                       STA.W $192C                        ;01A789|8D2C19  |00192C;
                       PLX                                 ;01A78C|FA      |      ;
                       LDA.W $192C                        ;01A78D|AD2C19  |00192C;
                       STA.B $18,X                        ;01A790|9518    |001A8A;
                       LDA.W $192B                        ;01A792|AD2B19  |00192B;
                       AND.B #$C0                         ;01A795|29C0    |      ;
                       ORA.B $0E,X                        ;01A797|150E    |001A80;
                       STA.B $0E,X                        ;01A799|950E    |001A80;
                       LDA.W $192B                        ;01A79B|AD2B19  |00192B;
                       AND.B #$3F                         ;01A79E|293F    |      ;
                       STA.B $10,X                        ;01A7A0|9510    |001A82;
                       INC.W $1935                        ;01A7A2|EE3519  |001935;
                       LDA.W $1935                        ;01A7A5|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A7A8|20DD90  |0190DD;
                       STA.W $192B                        ;01A7AB|8D2B19  |00192B;
                       AND.B #$F8                         ;01A7AE|29F8    |      ;
                       LSR A                               ;01A7B0|4A      |      ;
                       LSR A                               ;01A7B1|4A      |      ;
                       LSR A                               ;01A7B2|4A      |      ;
                       ORA.B $0D,X                        ;01A7B3|150D    |001A7F;
                       STA.B $0D,X                        ;01A7B5|950D    |001A7F;
                       LDA.W $192B                        ;01A7B7|AD2B19  |00192B;
                       AND.B #$07                         ;01A7BA|2907    |      ;
                       ORA.B $0E,X                        ;01A7BC|150E    |001A80;
                       STA.B $0E,X                        ;01A7BE|950E    |001A80;
                       INC.W $1935                        ;01A7C0|EE3519  |001935;
                       LDA.W $1935                        ;01A7C3|AD3519  |001935;
                       JSR.W CODE_0190DD                   ;01A7C6|20DD90  |0190DD;
                       INC.W $1935                        ;01A7C9|EE3519  |001935;
                       STA.W $192B                        ;01A7CC|8D2B19  |00192B;
                       AND.B #$80                         ;01A7CF|2980    |      ;
                       LSR A                               ;01A7D1|4A      |      ;
                       LSR A                               ;01A7D2|4A      |      ;
                       ORA.B $0D,X                        ;01A7D3|150D    |001A7F;
                       STA.B $0D,X                        ;01A7D5|950D    |001A7F;
                       PHP                                 ;01A7D7|08      |      ;
                       REP #$30                           ;01A7D8|C230    |      ;
                       LDA.W $192B                        ;01A7DA|AD2B19  |00192B;
                       AND.W #$007F                       ;01A7DD|297F00  |      ;
                       ASL A                               ;01A7E0|0A      |      ;
                       ASL A                               ;01A7E1|0A      |      ;
                       STA.B $11,X                        ;01A7E2|9511    |001A83;
                       ORA.B $01,X                        ;01A7E4|1501    |001A73;
                       STA.B $01,X                        ;01A7E6|9501    |001A73;
                       PLP                                 ;01A7E8|28      |      ;
                       PHX                                 ;01A7E9|DA      |      ;
                       PHY                                 ;01A7EA|5A      |      ;
                       TXY                                 ;01A7EB|9B      |      ;
                       LDA.W $193B                        ;01A7EC|AD3B19  |00193B;
                       JSR.W CODE_01E1D3                   ;01A7EF|20D3E1  |01E1D3;
                       PHY                                 ;01A7F2|5A      |      ;
                       TXY                                 ;01A7F3|9B      |      ;
                       PLX                                 ;01A7F4|FA      |      ;
                       LDA.W $0F28,Y                      ;01A7F5|B9280F  |000F28;
                       BEQ CODE_01A804                     ;01A7F8|F00A    |01A804;
                       LDA.W $0F2A,Y                      ;01A7FA|B92A0F  |000F2A;
                       STA.B $0B,X                        ;01A7FD|950B    |001A7D;
                       LDA.W $0F2B,Y                      ;01A7FF|B92B0F  |000F2B;
                       STA.B $0C,X                        ;01A802|950C    |001A7E;

CODE_01A804:
                       PLY                                 ;01A804|7A      |      ;
                       PLX                                 ;01A805|FA      |      ;
                       CLC                                 ;01A806|18      |      ;
                       RTS                                 ;01A807|60      |      ;

; ==============================================================================
; Dynamic Sprite Creation System
; Creates new sprite entries dynamically during battle
; ==============================================================================

CODE_01A808:
                       PHP                                 ;01A808|08      |      ;
                       SEP #$20                           ;01A809|E220    |      ;
                       REP #$10                           ;01A80B|C210    |      ;
                       STZ.W $1948                        ;01A80D|9C4819  |011948;
                       PHP                                 ;01A810|08      |      ;
                       PEA.W $1A72                        ;01A811|F4721A  |011A72;
                       PLD                                 ;01A814|2B      |      ;
                       PHY                                 ;01A815|5A      |      ;
                       JSR.W CODE_01A6FC                   ;01A816|20FCA6  |01A6FC;
                       JSR.W CODE_01A988                   ;01A819|2088A9  |01A988;
                       PLY                                 ;01A81C|7A      |      ;
                       LDA.W #$EB00                       ;01A81D|A900EB  |      ;
                       TYA                                 ;01A820|98      |      ;
                       ASL A                               ;01A821|0A      |      ;
                       ASL A                               ;01A822|0A      |      ;
                       TAY                                 ;01A823|A8      |      ;
                       STY.W $193B                        ;01A824|8C3B19  |01193B;
                       JSR.W CODE_01AA3B                   ;01A827|203BAA  |01AA3B;
                       PLP                                 ;01A82A|28      |      ;
                       LDX.W $1939                        ;01A82B|AE3919  |011939;
                       LDA.B #$02                         ;01A82E|A902    |      ;
                       STA.W $1A72,X                      ;01A830|9D721A  |011A72;
                       PLP                                 ;01A833|28      |      ;
                       RTS                                 ;01A834|60      |      ;

; ==============================================================================
; DMA Transfer Setup and Initialization
; Configures SNES DMA channels for graphics transfer
; ==============================================================================

                       db $E2,$20,$C2,$10,$A9,$80,$8D,$15,$21,$A2,$00,$69,$8E,$16,$21,$A9 ; 01A835
                       db $01,$8D,$00,$43,$A9,$18,$8D,$01,$43,$A2,$00,$00,$8E,$02,$43,$A9 ; 01A845
                       db $7F,$8D,$04,$43,$A2,$00,$2E,$8E,$05,$43,$A9,$01,$8D,$0B,$42,$60 ; 01A855

; ==============================================================================
; Character Graphics Loader and Processor
; Complex character sprite loading with bank coordination
; ==============================================================================

CODE_01A865:
                       PHB                                 ;01A865|8B      |      ;
                       PHD                                 ;01A866|0B      |      ;
                       PEA.W $192B                        ;01A867|F42B19  |00192B;
                       PLD                                 ;01A86A|2B      |      ;
                       SEP #$20                           ;01A86B|E220    |      ;
                       REP #$10                           ;01A86D|C210    |      ;
                       STA.B $00                          ;01A86F|8500    |00192B;
                       BIT.B #$80                         ;01A871|8980    |      ;
                       BNE CODE_01A89D                     ;01A873|D028    |01A89D;
                       REP #$30                           ;01A875|C230    |      ;
                       AND.W #$007F                       ;01A877|297F00  |      ;
                       ASL A                               ;01A87A|0A      |      ;
                       ASL A                               ;01A87B|0A      |      ;
                       ASL A                               ;01A87C|0A      |      ;
                       ASL A                               ;01A87D|0A      |      ;
                       ASL A                               ;01A87E|0A      |      ;
                       ASL A                               ;01A87F|0A      |      ;
                       ASL A                               ;01A880|0A      |      ;
                       LDX.B $00                          ;01A881|A600    |00192B;
                       PHX                                 ;01A883|DA      |      ;
                       STA.B $00                          ;01A884|8500    |00192B;
                       ASL A                               ;01A886|0A      |      ;
                       CLC                                 ;01A887|18      |      ;
                       ADC.B $00                          ;01A888|6500    |00192B;
                       PLX                                 ;01A88A|FA      |      ;
                       STX.B $00                          ;01A88B|8600    |00192B;
                       CLC                                 ;01A88D|18      |      ;
                       ADC.W #$9A20                       ;01A88E|69209A  |      ;
                       STA.B $02                          ;01A891|8502    |00192D;
                       SEP #$20                           ;01A893|E220    |      ;
                       REP #$10                           ;01A895|C210    |      ;
                       LDA.B #$10                         ;01A897|A910    |      ;
                       STA.B $08                          ;01A899|8508    |001933;
                       BRA CODE_01A8BB                     ;01A89B|801E    |01A8BB;

; ==============================================================================
; Alternate Graphics Loading Path
; Handles compressed or special format character graphics
; ==============================================================================

CODE_01A89D:
                       REP #$30                           ;01A89D|C230    |      ;
                       AND.W #$007F                       ;01A89F|297F00  |      ;
                       ASL A                               ;01A8A2|0A      |      ;
                       ASL A                               ;01A8A3|0A      |      ;
                       ASL A                               ;01A8A4|0A      |      ;
                       ASL A                               ;01A8A5|0A      |      ;
                       ASL A                               ;01A8A6|0A      |      ;
                       STA.B $02                          ;01A8A7|8502    |00192D;
                       ASL A                               ;01A8A9|0A      |      ;
                       CLC                                 ;01A8AA|18      |      ;
                       ADC.B $02                          ;01A8AB|6502    |00192D;
                       CLC                                 ;01A8AD|18      |      ;
                       ADC.W #$D7A0                       ;01A8AE|69A0D7  |      ;
                       STA.B $02                          ;01A8B1|8502    |00192D;
                       SEP #$20                           ;01A8B3|E220    |      ;
                       REP #$10                           ;01A8B5|C210    |      ;
                       LDA.B #$08                         ;01A8B7|A908    |      ;
                       STA.B $08                          ;01A8B9|8508    |001933;

; ==============================================================================
; Graphics Data Transfer Coordination
; Main transfer loop with memory management and format handling
; ==============================================================================

CODE_01A8BB:
                       SEP #$20                           ;01A8BB|E220    |      ;
                       REP #$10                           ;01A8BD|C210    |      ;
                       LDA.B #$04                         ;01A8BF|A904    |      ;
                       STA.B $06                          ;01A8C1|8506    |001931;
                       LDA.B #$7F                         ;01A8C3|A97F    |      ;
                       STA.B $07                          ;01A8C5|8507    |001932;
                       LDA.B #$00                         ;01A8C7|A900    |      ;
                       XBA                                 ;01A8C9|EB      |      ;
                       LDA.B $0C                          ;01A8CA|A50C    |001937;
                       ASL A                               ;01A8CC|0A      |      ;
                       TAX                                 ;01A8CD|AA      |      ;
                       REP #$30                           ;01A8CE|C230    |      ;
                       LDA.L DATA8_01A5E0,X                ;01A8D0|BFE0A501|01A5E0;
                       STA.B $04                          ;01A8D4|8504    |00192F;

; ==============================================================================
; Iterative Graphics Transfer Loop
; Processes multiple graphics blocks with address management
; ==============================================================================

CODE_01A8D6:
                       SEP #$20                           ;01A8D6|E220    |      ;
                       REP #$10                           ;01A8D8|C210    |      ;
                       JSR.W CODE_01A901                   ;01A8DA|2001A9  |01A901;
                       LDA.B $08                          ;01A8DD|A508    |001933;
                       DEC A                               ;01A8DF|3A      |      ;
                       STA.B $08                          ;01A8E0|8508    |001933;
                       BEQ CODE_01A8FE                     ;01A8E2|F01A    |01A8FE;
                       PHA                                 ;01A8E4|48      |      ;
                       REP #$30                           ;01A8E5|C230    |      ;
                       LDA.B $02                          ;01A8E7|A502    |00192D;
                       CLC                                 ;01A8E9|18      |      ;
                       ADC.W #$0018                       ;01A8EA|691800  |      ;
                       STA.B $02                          ;01A8ED|8502    |00192D;
                       LDA.B $04                          ;01A8EF|A504    |00192F;
                       CLC                                 ;01A8F1|18      |      ;
                       ADC.W #$0020                       ;01A8F2|692000  |      ;
                       STA.B $04                          ;01A8F5|8504    |00192F;
                       SEP #$20                           ;01A8F7|E220    |      ;
                       REP #$10                           ;01A8F9|C210    |      ;
                       PLA                                 ;01A8FB|68      |      ;
                       BRA CODE_01A8D6                     ;01A8FC|80D8    |01A8D6;

CODE_01A8FE:
                       PLD                                 ;01A8FE|2B      |      ;
                       PLB                                 ;01A8FF|AB      |      ;
                       RTS                                 ;01A900|60      |      ;

; ==============================================================================
; Low-Level Graphics Transfer Engine
; Direct memory transfer with bank coordination and timing
; ==============================================================================

CODE_01A901:
                       PHB                                 ;01A901|8B      |      ;
                       PHY                                 ;01A902|5A      |      ;
                       PHP                                 ;01A903|08      |      ;
                       PHD                                 ;01A904|0B      |      ;
                       PEA.W $192B                        ;01A905|F42B19  |00192B;
                       PLD                                 ;01A908|2B      |      ;
                       REP #$30                           ;01A909|C230    |      ;
                       PHB                                 ;01A90B|8B      |      ;
                       LDX.B $02                          ;01A90C|A602    |00192D;
                       LDY.B $04                          ;01A90E|A404    |00192F;
                       LDA.W #$000F                       ;01A910|A90F00  |      ;
                       MVN $7F,$04                       ;01A913|547F04  |      ;
                       PLB                                 ;01A916|AB      |      ;
                       SEP #$20                           ;01A917|E220    |      ;
                       REP #$10                           ;01A919|C210    |      ;
                       LDA.B #$08                         ;01A91B|A908    |      ;
                       STA.B $01                          ;01A91D|8501    |00192C;

; ==============================================================================
; Byte-Level Transfer with Bank Switching
; Processes individual bytes with complex bank management
; ==============================================================================

CODE_01A91F:
                       PHB                                 ;01A91F|8B      |      ;
                       LDA.B $06                          ;01A920|A506    |001931;
                       PHA                                 ;01A922|48      |      ;
                       PLB                                 ;01A923|AB      |      ;
                       LDA.W $0000,X                      ;01A924|BD0000  |040000;
                       INX                                 ;01A927|E8      |      ;
                       PHA                                 ;01A928|48      |      ;
                       LDA.B $07                          ;01A929|A507    |001932;
                       PHA                                 ;01A92B|48      |      ;
                       PLB                                 ;01A92C|AB      |      ;
                       PLA                                 ;01A92D|68      |      ;
                       XBA                                 ;01A92E|EB      |      ;
                       LDA.B #$00                         ;01A92F|A900    |      ;
                       XBA                                 ;01A931|EB      |      ;
                       REP #$30                           ;01A932|C230    |      ;
                       STA.W $0000,Y                      ;01A934|990000  |7F0000;
                       INY                                 ;01A937|C8      |      ;
                       INY                                 ;01A938|C8      |      ;
                       SEP #$20                           ;01A939|E220    |      ;
                       REP #$10                           ;01A93B|C210    |      ;
                       PLB                                 ;01A93D|AB      |      ;
                       DEC.B $01                          ;01A93E|C601    |00192C;
                       BNE CODE_01A91F                     ;01A940|D0DD    |01A91F;
                       PLD                                 ;01A942|2B      |      ;
                       PLP                                 ;01A943|28      |      ;
                       PLY                                 ;01A944|7A      |      ;
                       PLB                                 ;01A945|AB      |      ;
                       RTS                                 ;01A946|60      |      ;
