; ==============================================================================
; Bank  - FFMQ Main Battle Systems (Cycle 5, Part 2)
; Advanced Pattern Management and Complex Battle Logic
; ==============================================================================

; ==============================================================================
; Advanced Pattern Management System
; Handles complex pattern management with advanced battle logic
; ==============================================================================

CODE_01B73D:
                       PHP                                 ;01B73D|08      |      ;
                       SEP #$20                           ;01B73E|E220    |      ;
                       REP #$10                           ;01B740|C210    |      ;
                       LDA.W $0E91                        ;01B742|AD910E  |010E91;
                       BEQ CODE_01B752                     ;01B745|F00B    |01B752;
                       LDA.B #$55                         ;01B747|A955    |      ;
                       STA.W $0E04                        ;01B749|8D040E  |010E04;
                       STA.W $0E0C                        ;01B74C|8D0C0E  |010E0C;
                       JSR.W CODE_0182D0                   ;01B74F|20D082  |0182D0;

CODE_01B752:
                       PLP                                 ;01B752|28      |      ;
                       RTS                                 ;01B753|60      |      ;

; ==============================================================================
; Complex Animation and Sprite Coordination
; Advanced animation coordination with sprite management
; ==============================================================================

CODE_01B754:
                       PHP                                 ;01B754|08      |      ;
                       PHX                                 ;01B755|DA      |      ;
                       PHY                                 ;01B756|5A      |      ;
                       REP #$30                           ;01B757|C230    |      ;
                       PHX                                 ;01B759|DA      |      ;
                       AND.W #$00FF                       ;01B75A|29FF00  |      ;
                       ASL A                               ;01B75D|0A      |      ;
                       TAX                                 ;01B75E|AA      |      ;
                       LDA.L DATA8_00FDCA,X                ;01B75F|BFCAFD00|00FDCA;
                       TAY                                 ;01B763|A8      |      ;
                       PLX                                 ;01B764|FA      |      ;
                       JSR.W CODE_01AE8A                   ;01B765|208AAE  |01AE8A;
                       LDA.W $19E7                        ;01B768|ADE719  |0119E7;
                       JSR.W CODE_01B119                   ;01B76B|2019B1  |01B119;
                       PLY                                 ;01B76E|7A      |      ;
                       PLX                                 ;01B76F|FA      |      ;
                       PLP                                 ;01B770|28      |      ;
                       RTS                                 ;01B771|60      |      ;

; ==============================================================================
; Advanced Sprite Processing Engine
; Complex sprite processing with multi-layer coordination
; ==============================================================================

CODE_01B772:
                       PHP                                 ;01B772|08      |      ;
                       PHD                                 ;01B773|0B      |      ;
                       SEP #$20                           ;01B774|E220    |      ;
                       REP #$10                           ;01B776|C210    |      ;
                       PEA.W $1A72                        ;01B778|F4721A  |011A72;
                       PLD                                 ;01B77B|2B      |      ;
                       LDX.W #$0000                       ;01B77C|A20000  |      ;
                       STX.W $1975                        ;01B77F|8E7519  |011975;
                       STX.W $1973                        ;01B782|8E7319  |011973;

CODE_01B785:
                       SEP #$20                           ;01B785|E220    |      ;
                       REP #$10                           ;01B787|C210    |      ;
                       LDX.W $1975                        ;01B789|AE7519  |011975;
                       LDA.B $00,X                        ;01B78C|B500    |001A72;
                       BIT.B #$10                         ;01B78E|8910    |      ;
                       BEQ CODE_01B7BC                     ;01B790|F02A    |01B7BC;
                       CMP.B #$FF                         ;01B792|C9FF    |      ;
                       BEQ CODE_01B7BC                     ;01B794|F026    |01B7BC;
                       JSR.W CODE_01B7D8                   ;01B796|20D8B7  |01B7D8;
                       REP #$30                           ;01B799|C230    |      ;
                       PHX                                 ;01B79B|DA      |      ;
                       LDA.W $1973                        ;01B79C|AD7319  |011973;
                       ASL A                               ;01B79F|0A      |      ;
                       ASL A                               ;01B7A0|0A      |      ;
                       TAX                                 ;01B7A1|AA      |      ;
                       LDA.L DATA8_01A63A,X                ;01B7A2|BF3AA601|01A63A;
                       TAY                                 ;01B7A6|A8      |      ;
                       PLX                                 ;01B7A7|FA      |      ;
                       LDA.B $01,X                        ;01B7A8|B501    |001A73;
                       STA.W $0C02,Y                      ;01B7AA|99020C  |010C02;
                       LDA.B $03,X                        ;01B7AD|B503    |001A75;
                       STA.W $0C06,Y                      ;01B7AF|99060C  |010C06;
                       LDA.B $05,X                        ;01B7B2|B505    |001A77;
                       STA.W $0C0A,Y                      ;01B7B4|990A0C  |010C0A;
                       LDA.B $07,X                        ;01B7B7|B507    |001A79;
                       STA.W $0C0E,Y                      ;01B7B9|990E0C  |010C0E;

CODE_01B7BC:
                       REP #$30                           ;01B7BC|C230    |      ;
                       INC.W $1973                        ;01B7BE|EE7319  |011973;
                       LDA.W $1973                        ;01B7C1|AD7319  |011973;
                       CMP.W #$0016                       ;01B7C4|C91600  |      ;
                       BEQ CODE_01B7D5                     ;01B7C7|F00C    |01B7D5;
                       LDA.W $1975                        ;01B7C9|AD7519  |011975;
                       CLC                                 ;01B7CC|18      |      ;
                       ADC.W #$001A                       ;01B7CD|691A00  |      ;
                       STA.W $1975                        ;01B7D0|8D7519  |011975;
                       BRA CODE_01B785                     ;01B7D3|80B0    |01B785;

CODE_01B7D5:
                       PLD                                 ;01B7D5|2B      |      ;
                       PLP                                 ;01B7D6|28      |      ;
                       RTS                                 ;01B7D7|60      |      ;

; ==============================================================================
; Complex Animation Frame Processing
; Handles complex animation frame processing with timing control
; ==============================================================================

CODE_01B7D8:
                       SEP #$20                           ;01B7D8|E220    |      ;
                       REP #$10                           ;01B7DA|C210    |      ;
                       LDA.B $0E,X                        ;01B7DC|B50E    |001A80;
                       ROL A                               ;01B7DE|2A      |      ;
                       ROL A                               ;01B7DF|2A      |      ;
                       ROL A                               ;01B7E0|2A      |      ;
                       AND.B #$03                         ;01B7E1|2903    |      ;
                       STA.W $197D                        ;01B7E3|8D7D19  |01197D;
                       STA.W $197F                        ;01B7E6|8D7F19  |01197F;
                       CMP.B #$00                         ;01B7E9|C900    |      ;
                       BNE CODE_01B804                     ;01B7EB|D017    |01B804;
                       INC.W $197F                        ;01B7ED|EE7F19  |01197F;
                       LDA.B $17,X                        ;01B7F0|B517    |001A89;
                       PHA                                 ;01B7F2|48      |      ;
                       LSR A                               ;01B7F3|4A      |      ;
                       STA.W $197E                        ;01B7F4|8D7E19  |01197E;
                       PLA                                 ;01B7F7|68      |      ;
                       DEC A                               ;01B7F8|3A      |      ;
                       STA.B $17,X                        ;01B7F9|9517    |001A89;
                       LSR A                               ;01B7FB|4A      |      ;
                       CMP.W $197E                        ;01B7FC|CD7E19  |01197E;
                       BNE CODE_01B804                     ;01B7FF|D003    |01B804;
                       JMP.W CODE_01CC81                   ;01B801|4C81CC  |01CC81;

CODE_01B804:
                       LDA.B $0E,X                        ;01B804|B50E    |001A80;
                       LSR A                               ;01B806|4A      |      ;
                       LSR A                               ;01B807|4A      |      ;
                       LSR A                               ;01B808|4A      |      ;
                       LSR A                               ;01B809|4A      |      ;
                       AND.B #$03                         ;01B80A|2903    |      ;
                       STA.W $197E                        ;01B80C|8D7E19  |01197E;
                       STA.W $1980                        ;01B80F|8D8019  |011980;
                       LDA.B $00,X                        ;01B812|B500    |001A72;
                       BPL CODE_01B81B                     ;01B814|1005    |01B81B;
                       AND.B #$03                         ;01B816|2903    |      ;
                       STA.W $197E                        ;01B818|8D7E19  |01197E;

CODE_01B81B:
                       LDA.B #$00                         ;01B81B|A900    |      ;
                       XBA                                 ;01B81D|EB      |      ;
                       LDA.B $10,X                        ;01B81E|B510    |001A82;
                       REP #$30                           ;01B820|C230    |      ;
                       ASL A                               ;01B822|0A      |      ;
                       PHX                                 ;01B823|DA      |      ;
                       TAX                                 ;01B824|AA      |      ;
                       LDA.L DATA8_00FDCA,X                ;01B825|BFCAFD00|00FDCA;
                       STA.W $1977                        ;01B829|8D7719  |011977;
                       PLX                                 ;01B82C|FA      |      ;
                       SEP #$20                           ;01B82D|E220    |      ;
                       REP #$10                           ;01B82F|C210    |      ;
                       LDA.W $197D                        ;01B831|AD7D19  |01197D;
                       BNE CODE_01B83B                     ;01B834|D005    |01B83B;
                       LDA.B $17,X                        ;01B836|B517    |001A89;
                       LSR A                               ;01B838|4A      |      ;
                       BRA CODE_01B845                     ;01B839|800A    |01B845;

CODE_01B83B:
                       LDA.B $17,X                        ;01B83B|B517    |001A89;
                       SEC                                 ;01B83D|38      |      ;
                       SBC.W $197F                        ;01B83E|ED7F19  |01197F;
                       STA.B $17,X                        ;01B841|9517    |001A89;
                       LDA.B $17,X                        ;01B843|B517    |001A89;

CODE_01B845:
                       AND.B #$08                         ;01B845|2908    |      ;
                       LSR A                               ;01B847|4A      |      ;
                       LSR A                               ;01B848|4A      |      ;
                       LSR A                               ;01B849|4A      |      ;
                       STA.W $1979                        ;01B84A|8D7919  |011979;
                       LDA.B $00,X                        ;01B84D|B500    |001A72;
                       AND.B #$B0                         ;01B84F|29B0    |      ;
                       CMP.B #$B0                         ;01B851|C9B0    |      ;
                       BEQ CODE_01B87F                     ;01B853|F02A    |01B87F;
                       LDA.B $10,X                        ;01B855|B510    |001A82;
                       CMP.B #$3E                         ;01B857|C93E    |      ;
                       BNE CODE_01B860                     ;01B859|D005    |01B860;
                       LDA.W $1979                        ;01B85B|AD7919  |011979;
                       BRA CODE_01B868                     ;01B85E|8008    |01B868;

CODE_01B860:
                       LDA.W $1980                        ;01B860|AD8019  |011980;
                       ASL A                               ;01B863|0A      |      ;
                       CLC                                 ;01B864|18      |      ;
                       ADC.W $1979                        ;01B865|6D7919  |011979;

CODE_01B868:
                       REP #$30                           ;01B868|C230    |      ;
                       AND.W #$00FF                       ;01B86A|29FF00  |      ;
                       ASL A                               ;01B86D|0A      |      ;
                       ASL A                               ;01B86E|0A      |      ;
                       ASL A                               ;01B86F|0A      |      ;
                       CLC                                 ;01B870|18      |      ;
                       ADC.W $1977                        ;01B871|6D7719  |011977;
                       STA.W $1977                        ;01B874|8D7719  |011977;
                       TAY                                 ;01B877|A8      |      ;
                       SEP #$20                           ;01B878|E220    |      ;
                       REP #$10                           ;01B87A|C210    |      ;
                       JSR.W CODE_01AE8A                   ;01B87C|208AAE  |01AE8A;

CODE_01B87F:
                       SEP #$20                           ;01B87F|E220    |      ;
                       REP #$10                           ;01B881|C210    |      ;
                       LDA.B #$00                         ;01B883|A900    |      ;
                       XBA                                 ;01B885|EB      |      ;
                       LDA.W $197E                        ;01B886|AD7E19  |01197E;
                       ASL A                               ;01B889|0A      |      ;
                       REP #$30                           ;01B88A|C230    |      ;
                       AND.W #$00FF                       ;01B88C|29FF00  |      ;
                       PHX                                 ;01B88F|DA      |      ;
                       TAX                                 ;01B890|AA      |      ;
                       LDA.L DATA8_0190D5,X                ;01B891|BFD59001|0190D5;
                       STA.W $1977                        ;01B895|8D7719  |011977;
                       PLX                                 ;01B898|FA      |      ;
                       SEP #$20                           ;01B899|E220    |      ;
                       REP #$10                           ;01B89B|C210    |      ;
                       LDA.W $197D                        ;01B89D|AD7D19  |01197D;
                       CMP.B #$02                         ;01B8A0|C902    |      ;
                       BNE CODE_01B8B2                     ;01B8A2|D00E    |01B8B2;
                       LDA.W $1977                        ;01B8A4|AD7719  |011977;
                       ASL A                               ;01B8A7|0A      |      ;
                       STA.W $1977                        ;01B8A8|8D7719  |011977;
                       LDA.W $1978                        ;01B8AB|AD7819  |011978;
                       ASL A                               ;01B8AE|0A      |      ;
                       STA.W $1978                        ;01B8AF|8D7819  |011978;

CODE_01B8B2:
                       LDA.B #$00                         ;01B8B2|A900    |      ;
                       XBA                                 ;01B8B4|EB      |      ;
                       LDA.W $1977                        ;01B8B5|AD7719  |011977;
                       BEQ CODE_01B8D5                     ;01B8B8|F01B    |01B8D5;
                       BPL CODE_01B8C8                     ;01B8BA|100C    |01B8C8;
                       LDA.W $197F                        ;01B8BC|AD7F19  |01197F;
                       EOR.B #$FF                         ;01B8BF|49FF    |      ;
                       INC A                               ;01B8C1|1A      |      ;
                       XBA                                 ;01B8C2|EB      |      ;
                       LDA.B #$FF                         ;01B8C3|A9FF    |      ;
                       XBA                                 ;01B8C5|EB      |      ;
                       BRA CODE_01B8CB                     ;01B8C6|8003    |01B8CB;

CODE_01B8C8:
                       LDA.W $197F                        ;01B8C8|AD7F19  |01197F;

CODE_01B8CB:
                       REP #$30                           ;01B8CB|C230    |      ;
                       CLC                                 ;01B8CD|18      |      ;
                       ADC.B $13,X                        ;01B8CE|7513    |001A85;
                       AND.W #$03FF                       ;01B8D0|29FF03  |      ;
                       STA.B $13,X                        ;01B8D3|9513    |001A85;

CODE_01B8D5:
                       SEP #$20                           ;01B8D5|E220    |      ;
                       REP #$10                           ;01B8D7|C210    |      ;
                       LDA.B #$00                         ;01B8D9|A900    |      ;
                       XBA                                 ;01B8DB|EB      |      ;
                       LDA.W $1978                        ;01B8DC|AD7819  |011978;
                       BEQ CODE_01B8FC                     ;01B8DF|F01B    |01B8FC;
                       BPL CODE_01B8EF                     ;01B8E1|100C    |01B8EF;
                       LDA.W $197F                        ;01B8E3|AD7F19  |01197F;
                       EOR.B #$FF                         ;01B8E6|49FF    |      ;
                       INC A                               ;01B8E8|1A      |      ;
                       XBA                                 ;01B8E9|EB      |      ;
                       LDA.B #$FF                         ;01B8EA|A9FF    |      ;
                       XBA                                 ;01B8EC|EB      |      ;
                       BRA CODE_01B8F2                     ;01B8ED|8003    |01B8F2;

CODE_01B8EF:
                       LDA.W $197F                        ;01B8EF|AD7F19  |01197F;

CODE_01B8F2:
                       REP #$30                           ;01B8F2|C230    |      ;
                       CLC                                 ;01B8F4|18      |      ;
                       ADC.B $15,X                        ;01B8F5|7515    |001A87;
                       AND.W #$03FF                       ;01B8F7|29FF03  |      ;
                       STA.B $15,X                        ;01B8FA|9515    |001A87;

CODE_01B8FC:
                       SEP #$20                           ;01B8FC|E220    |      ;
                       REP #$10                           ;01B8FE|C210    |      ;
                       LDA.B $17,X                        ;01B900|B517    |001A89;
                       BPL CODE_01B906                     ;01B902|1002    |01B906;
                       STZ.B $00,X                        ;01B904|7400    |001A72;

CODE_01B906:
                       RTS                                 ;01B906|60      |      ;

; ==============================================================================
; Advanced System State Control
; Complex system state control with coordination
; ==============================================================================

CODE_01B907:
                       PHP                                 ;01B907|08      |      ;
                       PHD                                 ;01B908|0B      |      ;
                       SEP #$20                           ;01B909|E220    |      ;
                       REP #$10                           ;01B90B|C210    |      ;
                       PEA.W $1A72                        ;01B90D|F4721A  |011A72;
                       PLD                                 ;01B910|2B      |      ;
                       LDA.B $0E,X                        ;01B911|B50E    |001A80;
                       AND.B #$C0                         ;01B913|29C0    |      ;
                       BNE CODE_01B91B                     ;01B915|D004    |01B91B;
                       LDA.B #$1F                         ;01B917|A91F    |      ;
                       BRA CODE_01B91D                     ;01B919|8002    |01B91D;

CODE_01B91B:
                       LDA.B #$0F                         ;01B91B|A90F    |      ;

CODE_01B91D:
                       STA.B $17,X                        ;01B91D|9517    |001A89;
                       LDA.W $192B                        ;01B91F|AD2B19  |01192B;
                       STA.W $1979                        ;01B922|8D7919  |011979;
                       STA.W $1981                        ;01B925|8D8119  |011981;
                       LDA.B $0B,X                        ;01B928|B50B    |001A7D;
                       STA.W $197F                        ;01B92A|8D7F19  |01197F;
                       LDA.B $0C,X                        ;01B92D|B50C    |001A7E;
                       STA.W $1980                        ;01B92F|8D8019  |011980;
                       PHX                                 ;01B932|DA      |      ;
                       JSR.W CODE_01AEE7                   ;01B933|20E7AE  |01AEE7;
                       PLX                                 ;01B936|FA      |      ;
                       LDA.W $197F                        ;01B937|AD7F19  |01197F;
                       STA.B $0B,X                        ;01B93A|950B    |001A7D;
                       LDA.W $1980                        ;01B93C|AD8019  |011980;
                       STA.B $0C,X                        ;01B93F|950C    |001A7E;
                       JSR.W CODE_01AFF0                   ;01B941|20F0AF  |01AFF0;
                       PLD                                 ;01B944|2B      |      ;
                       PLP                                 ;01B945|28      |      ;
                       RTS                                 ;01B946|60      |      ;

; ==============================================================================
; Advanced Memory Clear and Initialization
; Complex memory clear with advanced initialization routines
; ==============================================================================

                       db $A9,$80,$8D,$15,$21,$A9,$00,$EB,$AD,$2B,$19,$C2,$30,$18,$6D,$2D ; 01B947
                       db $19,$AA,$8E,$16,$21,$AC,$2F,$19,$9C,$18,$21,$18,$69,$10,$00,$8D ; 01B957
                       db $16,$21,$88,$D0,$F3,$60                                                     ; 01B967

; ==============================================================================
; Scene Transition and State Management
; Advanced scene transition with complex state management
; ==============================================================================

CODE_01B96D:
                       LDA.W $19CB                        ;01B96D|ADCB19  |0119CB;
                       AND.W #$FFF8                       ;01B970|29F8FF  |      ;
                       ORA.W #$0001                       ;01B973|090100  |      ;
                       STA.W $19CB                        ;01B976|8DCB19  |0119CB;
                       SEP #$20                           ;01B979|E220    |      ;
                       REP #$10                           ;01B97B|C210    |      ;
                       LDA.W $19B4                        ;01B97D|ADB419  |0119B4;
                       AND.B #$F8                         ;01B980|29F8    |      ;
                       ORA.B #$01                         ;01B982|0901    |      ;
                       STA.W $19B4                        ;01B984|8DB419  |0119B4;
                       LDA.B #$01                         ;01B987|A901    |      ;
                       STA.W $1928                        ;01B989|8D2819  |011928;
                       LDA.B #$02                         ;01B98C|A902    |      ;
                       STA.W $19D7                        ;01B98E|8DD719  |0119D7;
                       JSR.W CODE_01CECA                   ;01B991|20CACE  |01CECA;
                       JSR.W CODE_01935D                   ;01B994|205D93  |01935D;
                       LDA.W $1935                        ;01B997|AD3519  |011935;
                       JSR.W CODE_01B1EB                   ;01B99A|20EBB1  |01B1EB;
                       STA.W $1939                        ;01B99D|8D3919  |011939;
                       STX.W $193B                        ;01B9A0|8E3B19  |01193B;
                       LDA.W $1A72,X                      ;01B9A3|BD721A  |011A72;
                       STA.W $193A                        ;01B9A6|8D3A19  |01193A;
                       LDA.B #$04                         ;01B9A9|A904    |      ;
                       STA.W $1A72,X                      ;01B9AB|9D721A  |011A72;
                       LDA.W $1A7D,X                      ;01B9AE|BD7D1A  |011A7D;
                       DEC A                               ;01B9B1|3A      |      ;
                       STA.W $192D                        ;01B9B2|8D2D19  |01192D;
                       LDA.W $1A7E,X                      ;01B9B5|BD7E1A  |011A7E;
                       STA.W $192E                        ;01B9B8|8D2E19  |01192E;
                       JSR.W CODE_01880C                   ;01B9BB|200C88  |01880C;
                       STX.W $193D                        ;01B9BE|8E3D19  |01193D;
                       JSR.W CODE_019058                   ;01B9C1|205890  |019058;
                       LDA.W $19BD                        ;01B9C4|ADBD19  |0119BD;
                       CLC                                 ;01B9C7|18      |      ;
                       ADC.B #$07                         ;01B9C8|6907    |      ;
                       AND.B #$1F                         ;01B9CA|291F    |      ;
                       STA.W $19BD                        ;01B9CC|8DBD19  |0119BD;
                       LDA.W $19BF                        ;01B9CF|ADBF19  |0119BF;
                       CLC                                 ;01B9D2|18      |      ;
                       ADC.B #$05                         ;01B9D3|6905    |      ;
                       AND.B #$0F                         ;01B9D5|290F    |      ;
                       STA.W $19BF                        ;01B9D7|8DBF19  |0119BF;
                       JSR.W CODE_0188CD                   ;01B9DA|20CD88  |0188CD;
                       LDX.W $192B                        ;01B9DD|AE2B19  |01192B;
                       STX.W $193F                        ;01B9E0|8E3F19  |01193F;
                       RTS                                 ;01B9E3|60      |      ;
